# AI (perception / behavior / planner) — PC code map

**Scope:** the **core agent AI** — the `PgAi*` framework the inventory (§5.2) flagged as the one
un-clustered system: perception/stimulus → context/goal planner → cover FSM → aim → actuation, plus the
`Ai*`/`Perception`/`Stimulus`/`Squad` reflection component families, the AI-action message bus, and the
`Ai.*` Lua order surface. Scoreboard **row 23**.

**This map does NOT re-cover** the three AI-adjacent slices that already have their own maps — it
cross-links them:
- AI **vehicle driving** + road graph → [`road_graph_ai_driving_code_map.md`](road_graph_ai_driving_code_map.md)
- **population / spawners** (SkirmishSpawnList, living-world, traffic density) → [`population_spawner_code_map.md`](population_spawner_code_map.md)
- **faction / reputation** (infractions → attitude → pursuit) → [`faction_reputation_code_map.md`](faction_reputation_code_map.md)

**Binary:** unpacked SecuROM image `output/_ghidra/securom_dump/mercs2_unpacked.exe`, base `0x400000`;
PC bodies from `output/_ghidra/all_functions_decomp.txt`. **Xbox oracle:**
[`ai.md`](../mercs2-pdb-analysis/ai.md) (PowerPC devkit "Profile" build, `PgAi*.cpp`), with the ECS
census [`02_ai_perception_population.md`](../mercs2-ecs/02_ai_perception_population.md) and the Lua
surface [`06_ai_world_entities.md`](../mercs2-luacd/06_ai_world_entities.md) / §3.6 of
[`lua_engine_bindings_audit.md`](../lua_engine_bindings_audit.md).

---

## 0. Boundary — what is code, what is data, what is gone

| Layer | State | Confidence |
|---|---|---|
| **Runtime spine** — AI system host, action message bus, MP replicate, aim commands, per-entity perception record | **PC bodies read first-hand + Xbox twins** | **H** |
| **Component families** — 25 `Ai*`/`Perception`/`Stimulus`/`Squad`/population descriptors | registrars + strides + hashes recovered both builds | **H** |
| **Reflection registrar** — master enum/type registry | `FUN_0064ac50` (16,897 B) recovered | **H** |
| **Planner goal selection, cover FSM, squad tactics, threat scoring** | **no named native body on EITHER build**; verbs are 32-bit **hashes** dispatched through the bus, the string vocabulary lives in Lua/data | **strings/data only** |
| **Pathfinding / navmesh** | **unrecovered** — no named routine (Xbox `PathFind` is a debug-color registrar, not nav) | **absent** |

The load-bearing finding: **Mercs 2's AI "brain" is not a compiled decision tree — it is a data/Lua
goal vocabulary dispatched over a hash-addressed action bus.** The engine supplies the *mechanism*
(host, bus, perception records, component pools, replication); the *behaviour* (which goals, cover
states, restriction flags) is authored content. That is why no planner body clusters in either binary.

---

## 1. Architecture (from the `PgAi*` source family)

Five `PgAi*.cpp` files (verbatim in `mercs2_xenon_p.source_paths.txt`) describe a five-stage agent:

```
PgAiPercept.cpp    perception / stimulus / threat  → memory + threat model
PgAiContext.cpp    context / goal + role planner    → selects an action  (largest file, asserts ~L6300)
PgAiCoverManager.cpp  cover finder + cover FSM      → MCoverFinder, GoingToCover/AtCover/…
PgAiInterface.cpp  Lua command surface              → Ai.Goal({ … }) verbs
PgAiActHeli.cpp    actuation (heli/car/boat)        → HeliLand/CarTurn/… → vehicle command rings
```
No `PgAi*` RTTI class survives on either build (the RTTI tables are Havok/XML-dominated); the only
scoped-name string is `AIPedestrian::Messages`. So the marriage is **string- and structure-anchored,
not vtable-anchored** — medium confidence on the per-function pairings, high on the runtime spine
(which is proven by struct-offset identity, below).

---

## 2. Runtime spine — PC ↔ Xbox (the net-new recovery)

### 2.1 AI system host — `FUN_00590380` ↔ `PgSysAi @8240b548`

The PC merges the Xbox `PgSysAi` + its caller `FUN_8240b5c0` into one host/init that hangs three AI
objects off the global `PgSystem` at the **same fixed offsets** as Xbox — the proof of the pairing:

```c
// FUN_00590380  (PC)              ⇔  PgSysAi @8240b548 + caller FUN_8240b5c0 (Xbox)
iVar1 = *(param_1 + 0x3ce4);       *(param_1 + 0x3df8) = 0;
if (iVar1 == 0) {                  // main AI object (0x468 bytes)
    iVar1 = FUN_0084ac20(0x468,1); // ⇔ Xbox FUN_82902840(0x468)
    uVar2 = FUN_00582b60();        // 0x468-obj ctor (sole caller = this)
    *(param_1 + 0x3ce4) = uVar2;
}
if (*(param_1 + 0x3cdc) == 0) { *(param_1+0x3cdc) = FUN_004b2370(); }  // AI sub-system A
if (*(param_1 + 0x3ce0) == 0) { *(param_1+0x3ce0) = FUN_004f4190(); }  // AI sub-system B
```

| Role | PC VA | Xbox VA |
|---|---|---|
| AI host / init | **`FUN_00590380`** | `PgSysAi @8240b548` + `FUN_8240b5c0` |
| AI host teardown | `FUN_00590410` (frees +0x3cdc/+0x3ce0/+0x3ce4) | (Xbox dtor) |
| 0x468 main-AI-object ctor | `FUN_00582b60` (sole caller = host) | `FUN_82902840` alloc target |
| **AI sub-system A** creator | `FUN_004b2370` | `FUN_822ed8c0(0x830f9828,…)` |
| **AI sub-system B** creator | `FUN_004f4190` | `FUN_822073b8(0x831b1370,…)` |
| PgSystem host singleton | **`DAT_01175e54`** (`*(DAT_01175e54 + 0x3ce4)` = the AI record array base) | — |

> **Resolves a standing Xbox open question.** `ai.md` could not name *which two* sub-systems `PgSysAi`
> creates (constructor args unsymbolized). The PC gives their creators by VA: **`FUN_004b2370`** (A) and
> **`FUN_004f4190`** (B). Identifying what each *is* (perception vs actuation? squad vs individual?)
> remains open, but they are now addressable.

### 2.2 The AI action bus — `DirectAction` and the 1024-slot ring

AI commands are a **single hash-addressed message bus** with optional MP replication — the "do this
action now" path several script/debug commands funnel through:

| Role | PC VA | Xbox VA | Note |
|---|---|---|---|
| **`DirectAction(guid, actionHash)`** | **`FUN_0056aa70`** | `DirectAction @823daea0` | local-post, then replicate if hosting |
| bus post primitive (local enqueue) | `FUN_00423d10` | `FUN_8222dbf0` (bus `0x83187008`) | enqueues `{guid,hash,0}` |
| player count (MP-host gate) | `FUN_006cdac0` | `FUN_82590e28` | active slots, max 2 |
| replicate to clients | `FUN_006bb960` | `FUN_82581230` | 13-B thunk → wire marshal |

The **local enqueue** primitive is the home of the famous "`Ai 1024`" budget number:

```c
// FUN_00423d10  — the AI-action ring
EnterCriticalSection(&DAT_0124aef8);
if (DAT_012476a8 < 0x400) {                         // 1024-slot cap  ← "Ai 1024"
    *(&DAT_012476f0 + DAT_012476a8*0xc) = {guid,hash,0};   // 0xc-byte entry
    DAT_012476a8++;
}
```

> **Correction — "Ai 1024" is NOT a reflected component.** No registrar references a bare `"Ai"`
> string on either build (string pool packs `WeaponScatter`→`AiSkill` with no gap; the ECS manifest
> has no plain `Ai`). The `Ai 1024` budget in the Xbox pool table is **this 1024-entry action ring**
> (`DAT_012476f0`, cap `0x400`, 12-byte `{guid,hash,0}` records under CS `DAT_0124aef8`), not a
> per-entity component pool. Every real AI component *does* have its own registrar (§4).

### 2.3 Aim commands are hashed — `AimedScan` ↔ `FUN_0054c6e0`

Confirms actions are addressed by 32-bit hash and dispatched through `DirectAction`:

```c
// FUN_0054c6e0  ⇔  AimedScan @823dcbe8
FUN_0056aa70( (-(uint)(fVar3 < 0.0) & 0x19a6e6d9) + 0x3a054530 );
//   off = 0x3a054530 ,  on = 0x3a054530 + 0x19a6e6d9 = 0x53ac2c09   (branchless toggle)
```
The two hashes `0x3a054530`/`0x53ac2c09` are the off/on `aimedscan` action — matching the `aimedscan`
planner verb string. `AimEnable`/`AimDisable` use a parallel typed message with a mode byte
(1=enable / 2=disable / 0=off).

### 2.4 Per-entity perception update + the AI record

The closest thing to a per-entity "think" step is **perception-record maintenance** (not a full
planner loop — that stays data/hash-driven):

| Role | PC VA | Note |
|---|---|---|
| per-entity perception update | `FUN_00600240` (driver `FUN_005fa950`) | finds the entity's record in the `+0x3ce4` array (else allocs via `FUN_00582c40`), updates via `FUN_00600790`/`FUN_00600f80` |
| AI record accessor | `FUN_0058d520` | `return *(host+0x3ce4) + idx*0x19;` → records are **0x19 dwords = 0x64 B**, ≤ 8 entries |
| perception debug overlay | `FUN_005aa8f0` | exposes record fields: `[0x13]` TotalObservers, `+0x4e` TotalAware, `[0x14]` HostileObservers, `+0x52` HostileAware, `[0x15]` Attackers |

The **goal/plan selection** body is not exposed under a named symbol; systems tick behind the layer-4
`Update(+0xc)` vtable slot (see [`scheduler_tick_code_map.md`](scheduler_tick_code_map.md)) and the
decision is hash/data-driven.

### 2.5 `PathFind` is NOT pathfinding (correction, carried from Xbox)

The named function `PathFind @823f5438` (Xbox) is a **debug-draw colour registrar** (writes ARGB
`0xff00d7ff` into a 256-slot name/colour table) — the "`- Pathfind`" AI-debug visualiser entry, **not**
the navigation routine. The real nav/navmesh code is **unnamed on both builds** (§8).

---

## 3. Reflection component families

Every real AI component has a **two-function registration** (the Keystone-A pattern, see
[`ecs_reflection_registry_code_map.md`](ecs_reflection_registry_code_map.md)):
1. a **descriptor-builder** (`ai.md` PC cross-ref: the `0063fxxx`/`00640xxx`/`00641xxx`/`006481xx`
   family) that fills the 0x50-B streaming descriptor (`&PTR_CopyFromStream_*`, seed `0x9e3779b9`,
   budget field, name) and tail-calls the shared registrar `FUN_0064a770`; and
2. a **schema/field function** (`ecs/02` census: the `0065xxxx`/`0066xxxx` family) that sets the field
   defaults, stride, and enum columns.

The table below is the authoritative census (schema function + stride + hash). The seven known
descriptor-builder twins are listed underneath.

| Component | m2 hash | schema fn (PC) | stride | pool | meaning |
|---|---|---|---|---|---|
| **Core AI / behavior** | | | | | |
| AiBehavior | `0xdecd8889` | `FUN_0065b5e0` | 0x30 | `512` | 12 boolean "what may this AI do" toggles (all default False) — the `No*`/`Pacifist`/`Zombie` flag block |
| AiSkill | `0xeba09b1a` | `FUN_0065cd80` | 0x04 | | AI competence float (default **10.0**) |
| AiPatrol | `0xb0ca290d` | `FUN_0065ce20` | 0x18 | `768` | patrol mode (`Loop`/`Bounce`) + scheduling priority |
| AiDriving | `0x67ab955c` | `FUN_0065d090` | 0x08 | `256` | vehicle-AI driving tuning (2 floats) → [driving map](road_graph_ai_driving_code_map.md) |
| AiHelicopter | `0x78eb1adc` | `FUN_0065cf30` | 0x24 | `256 128` | heli-AI flight envelope (9 floats) → [driving map](road_graph_ai_driving_code_map.md) |
| AiWaterZone | `0xdf6533de` | `FUN_0065c520` | 0x04 | | water-zone AI type enum |
| MeleeCombatant | `0xbf438e92` | `FUN_00661d80` | 0x28 | | melee combat tuning (10 floats) |
| ChatterSet | `0x949a1e44` | `FUN_0065bdc0` | 0x04 | | radio-chatter / VO set id |
| AiUnUsable | `0x4a548962` | `FUN_006481f0` (runtime) | 0x01 | `8 8` | marker: entity not usable by AI (dead/disabled) |
| **Perception / stimulus / threat** | | | | | |
| Perception | `0x3f6ab8f0` | `FUN_0065b8f0` | 0x14 | | sight/awareness: 3 unit multipliers + **range 120** + mode |
| Stimulus | `0x06408d71` | `FUN_0065b9e0` | 0x0c | | perception stimulus: strength/radius **100**, falloff **40** |
| StimulusModifier | `0xb9388f0a` | `FUN_0065ba90` | 0x18 | | scales an incoming Stimulus (×2.0; falloffs 0.3/1.2/0.8) |
| Target | `0xaff6b246` | `FUN_0065bba0` | 0x04 | | targetable flag (BoolEnum, default True) |
| **Squad** | | | | | |
| Squad | `0x9788c501` | `FUN_0065d140` | 0x04 | `16 16`, max **50** | squad capacity (default `0x32`=50) |
| **Suspicion (faction-facing)** | | | | | |
| Suspect | `0x1afc276c` | `FUN_006482b0` (runtime) | 0x20 | | per-faction suspicion/wanted state (8 factions × 1 dword) → [faction map](faction_reputation_code_map.md) |
| **Population / travel** (owned by → [population map](population_spawner_code_map.md)) | | | | | |
| PopulationDensity | `0x6fa2f9d4` | `FUN_00660980` | 0x1c | | crowd/vehicle density + TrafficControl enum |
| PopulationDynamicRoad | `0xffc5baa5` | `FUN_00660b20` | 0x0c | | dynamic road (Overpass/Wall) |
| PopulationFlow | `0x322750ec` | `FUN_00660eb0` | 0x0c | | traffic flow (StopSign/TrafficLight) |
| SkirmishZone | `0xfc5923af` | `FUN_0065be50` | 0x08 | | skirmish zone (float + int) |
| SkirmishSpawnList | `0xafba5846` | `FUN_0065bf00` | 0x18 | | skirmish spawn-list (6 slot ints) |
| SocialUse | `0x7e6bf93d` | `FUN_0065bce0` | 0x10 | | social-prop "need" use point (NeedType + 3 floats) |
| RtPopHint | `0x036dc9cb` | runtime @299650 | 0x01 | | runtime population hint flag |
| RtPopMembership | `0x8c8e5490` | runtime @299683 | 0x14 | | which runtime population group an NPC is in |
| RtLivingWorld | `0x115b2b5c` | runtime @300122 | 0x10 | | living-world runtime state (server) |
| RuntimeTravelGroup | `0x5f187fa4` | `FUN_00645d70` (runtime) | 0x08 | | runtime traveling-NPC group |

**Descriptor-builder twins** (`ai.md` PC cross-ref — the paired step-1 functions):
`AiSkill FUN_0063f430`, `AiPatrol FUN_0063f4e0`, `AiHelicopter FUN_0063f590`, `AiDriving FUN_0063f640`,
`AiBehavior FUN_00640b90`, `AiWaterZone FUN_00641560`, `AiUnUsable FUN_006481f0`. Each ends with its
own `_DAT = s_Ai<Name>_00bcXXXX` type-name store; the shared `0x9e3779b9` seed / `0x100` budget /
`FUN_0064a770()` register call are identical across them (one template per type).

**Master reflection registrar:** **`FUN_0064ac50`** (16,897 B) — references *every* AI/Cover/population
enum string in sequence (`s_AiHintEnum`, `s_AiWaterZoneEnum`, `s_AiPatrolModeEnum`, `s_AiPriorityEnum`,
`s_CoverTypeEnum`, …). It is the system-wide enum/type registrar, **not** a per-enum method.

---

## 4. Enums & tunables

**Enums** (`.rdata` type-name tables): `AiPatrolModeEnum` {`Loop`,`Bounce`} · `AiPriorityEnum`
{`Low`…`High`} · `AiHintEnum` {`Movement`,`MovementPortal`,`FirePoint`,`CowerPoint`} · `AiWaterZoneEnum`
· `NeedTypeEnum` {`SHADE`,`CONTACT`,`ACTIVITY`,`TRASH`,`EXIT`} · `TrafficControlEnum`
{`Default`,`NoTraffic`,`NoVehicles`,`NoPeds`,`BanFaction`,`SingleFaction`} · `DynamicRoadTypeEnum`
{`Overpass`,`Wall`} · `FlowControlTypeEnum` {`StopSign`,`TrafficLight`} · `BoolEnum` {False,True}.
`CoverType`/`CoverRating`/`CoverAnim` enums exist in `.rdata` (`s_CoverTypeEnum_00bc61a4`,
`s_CoverRatingEnum_00bc6158`, `s_CoverAnimEnum_00bc6184`) but no Cover *component* registers here.

**Headline tunables:** AiSkill **10** · Squad max **50** · Perception range **120** · Stimulus
strength **100** / falloff **40** · StimulusModifier ×**2.0** · AiHelicopter envelope
`10/80/20/30/20/5/1/0/20` · SocialUse `5/30/5` · Target default **True**. (Note: `AlertLow/Medium/High
Threshold` etc. are **memory-pool MB sizes** in `[x360_memory]`, **NOT** AI alertness — confirmed
caution from `ai.md`.)

---

## 5. Planner / cover / squad = data + Lua (hash-dispatched)

The planner **verb vocabulary** and **cover state machine** have **no compiled body under a named
symbol on either build** — they are dispatched by hash through `DirectAction` (§2.2/§2.3) and authored
in Lua/data. For completeness, the vocabulary (strings-only evidence, from `ai.md`):

- **Goal/action verbs:** `moveto, takecover, attack, patrol, guard, investigate, flee_from_pos, follow,
  pathmove, pilot, go_home, deliver, pickup, converse, drive, stand, observe, react, report,
  change_feeling, triggeralarm, walkthesidewalks, aimedscan, helitakeoff, heliland, enter,
  move_within_boundary, aquire`(sic).
- **Cover FSM:** `GoingToCover, AtCover, LowCover, ShootingFromCover, StepInFromCover, StepOutFromCover,
  DiveFromCover, LostCover, TakeCoverFromTarget` + slot states `kKneelAtCover/kPopup/kShoot/kWaitForPopup`;
  finder `MCoverFinder`.
- **Behavior-restriction flags** (the `AiBehavior` bool block): `NoExitVehicle, NoFollow, NoGrenades,
  NoTurret, NoVehicle, NoCover, NoReport, NoCapture, NoHorn, NoAlarm, NoProne, NoCrouch, Pacifist, Zombie`.
- **Turret/weapon states** (owned by [`weapons_combat_code_map.md`](weapons_combat_code_map.md)):
  `WPN_IDLE/AIMING/CHARGING/BURSTING`, `TUR_IDLE/NOWEAPON/TRACKING/TARGET_TOOFAR/…/FIRING/RELOADING`.

### Lua order surface (`Ai.*`, via `PgAiInterface`)

The game issues AI orders from Lua; these cfuncs post to the bus / set component fields. Canonical set
(from the Lua corpus + bindings audit): **`Ai.Goal`** `{AIGuid, Goal='moveto'|'attack'|'follow'|
'pathmove'|'heliland'|'enter'|…, Target, Priority, Force, Haste, Callback}` · `Ai.Role` (Idle/Follow/
Passenger …) · `Ai.Squad` (`AddUnits`/`AddCommand`/`RemoveSquad`) · `Ai.Deploy` · `Ai.Plan`/`PlanSetGoal`
· `Ai.SetState` (`Pacifist`,`Zombie`,…) · `Ai.SetPerceivability`/`LivingWorld` (stealth) ·
`Ai.Set/GetFeeling`, `Ai.Set/GetRelation`, **`Ai.AddInfraction`** (→ [faction map](faction_reputation_code_map.md))
· `Ai.Anchor`/`SetHaste`/`RemoveGoal`/`EveryoneOut` · `Ai.TweakAttachedSpawners*` (→ [population map](population_spawner_code_map.md)).
The `mrxai`/`mrxfollow` resident modules wrap every order in the object-hibernation awake-gate.

---

## 6. Cross-references

| For… | See |
|---|---|
| AI **vehicle driving**, road/lane graph, `AiDriving`/`AiHelicopter` actuation | [`road_graph_ai_driving_code_map.md`](road_graph_ai_driving_code_map.md) |
| **spawners / population / living-world / traffic** density, skirmish spawn-lists | [`population_spawner_code_map.md`](population_spawner_code_map.md) |
| **infractions → attitude → pursuit** (`Ai.AddInfraction`/`SetRelation`, `Suspect`) | [`faction_reputation_code_map.md`](faction_reputation_code_map.md) |
| the **message bus** local-vs-wire branch, event dispatch | [`event_bus_code_map.md`](event_bus_code_map.md), [`networking_code_map.md`](networking_code_map.md) |
| layer-4 **system tick** the AI update rides | [`scheduler_tick_code_map.md`](scheduler_tick_code_map.md) |
| cover/aim **animation** pose selection (clip picker) | [`animation_code_map.md`](animation_code_map.md) |
| **turret/weapon** firing states referenced by combat AI | [`weapons_combat_code_map.md`](weapons_combat_code_map.md) |
| the two-function **registration** pattern (descriptor + schema) | [`ecs_reflection_registry_code_map.md`](ecs_reflection_registry_code_map.md) |

---

## 7. Honest boundaries & open items (confirm-live / next-pass)

1. **Pathfinding / navmesh — unrecovered.** No named nav routine on either build; `PathFind` is a debug
   colour registrar. The nav layer is the single biggest gap for a faithful reimpl.
2. **Planner goal-selection body not isolated.** Decision is hash/data-driven behind the layer-4
   `Update(+0xc)` vtable; no single "think" body clusters. Verbs/cover states are strings-only in native.
3. **Which two sub-systems `PgSysAi` creates** — now addressable by VA (`FUN_004b2370` / `FUN_004f4190`)
   but their *roles* (perception vs actuation? squad vs individual?) are unproven.
4. **Local-vs-wire replication routing** for `DirectAction` stays behind SecuROM virtualization; the
   replicate call site `FUN_006bb960` is recovered, the wire-marshal core is confirm-live
   ([`event_bus_code_map.md §4`](event_bus_code_map.md)).
5. **`MindKiller`** is an AI kill-switch mirrored in the (stripped-on-PC) debug menu (`FUN_8240a108`
   Xbox); what it disables in the sim is unverified.

---

## 8. Reimpl disposition (`mercs2_core`/`mercs2_engine` vs `mercs2_game`/`mercs2_script`)

**Engine (reusable framework):** the AI **host** (`FUN_00590380` analog — an AI system object hung off
the sim spine), the **hash-addressed action bus** with a bounded ring + MP replicate (`FUN_0056aa70`/
`FUN_00423d10`), the **per-entity perception record** (0x64-B, observer/threat counters), and the
**component pools** (all 25 descriptors via the existing Keystone-A registrar). None of this needs the
original planner — it is mechanism.

**Game/script (authored behaviour):** the goal vocabulary, cover FSM, restriction flags, squad tactics,
pedestrian chatter, and the `Ai.*` order surface — all data/Lua, dispatched by hash. A reimpl supplies
its own planner behind the same bus + component contract; it does **not** need to recover a compiled
decision tree that never existed as such.

**Row 23 status:** framework spine ✅ recovered (this map) + driving sub-graph ✅
([driving map](road_graph_ai_driving_code_map.md)); **planner behaviour ❌** (data/Lua, reimpl target);
**navmesh ❌** (unrecovered). Engine today = `Ai.Enable` no-op.
