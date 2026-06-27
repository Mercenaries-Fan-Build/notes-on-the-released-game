# 03 — Contracts & Jobs

Decompiled Lua mission-content scripts for *Mercenaries 2: World in Flames*. This group covers the
**actual mission scripts** that live alongside the world (`vz/`): faction story contracts (`*con*`),
side jobs (`*job*`), outpost-capture contracts, and the world bootstrap helper `stagingact1`.

Manifest: [`_manifests/03_contracts_jobs.txt`](_manifests/03_contracts_jobs.txt) — 74 scripts.
Source root: `src/vz/<name>.lua`.

> All line numbers below are real and cite the decompiled source. Clickable refs use the
> `[name.lua:LINE](src/vz/name.lua#LLINE)` form.

---

## 1. Overview

### 1.1 How a contract/job script is structured

Every script is a **module that `inherit()`s an engine task base class** and overrides a small set of
lifecycle hooks. The base classes (defined elsewhere in the codebase, *not* in this group) implement
the heavy lifting — objective tracking, reward dispensing, save/restore, PDA display, networking. The
per-mission script only supplies content: which layers to load, which objectives to chain, which VO to
play, and any bespoke scripted set-pieces.

The common lifecycle (seen in full in [pmccon001.lua](src/vz/pmccon001.lua)):

| Hook | Purpose |
|------|---------|
| `inherit("MrxTask…")` | line 1 — pick the base task class (see taxonomy below). |
| `import("Mrx…")` | lines 2-N — pull in helper modules (VO, layers, factions, etc.). |
| module-level locals/tables | named-GUID lists, layer lists, VO tables, net-event id constants. |
| `LoadAssets(self, tSaveData)` | add/remove world **layers** via `MrxLayerManager`, then call `self.AssetsLoaded`. Honors save flags. |
| `Activated(self)` | calls `<Base>.Activated(self)`, wires up events (`self:_CreateEvent(...)`), spawns, sets pursuit, then creates the first objective. |
| objective chain | `self:CreateChild({ sModuleName = "MrxTaskObjective…", … })` — each objective's `tOnComplete`/`fOnComplete` spawns the next one. |
| `Complete` / `Cancel` | optional overrides (restore weapons, grant achievement, fanfare) then call `<Base>.Complete/Cancel(self)`. |
| `Cleanup(self)` | mark layers for removal, undo faction-relation/pursuit/atmosphere changes, then `<Base>.Cleanup(self)`. |

**Objectives** are children created with `self:CreateChild`. The module name selects behavior:
`MrxTaskObjectiveDeliver` (move a target to a location/region), `MrxTaskObjectiveDestroy` (kill N tagged
objects, supports `nQuota`/`sTgtLabelFilter`), `MrxTaskObjectiveEnterVehicle`, etc. Common keys:
`sDspShortDesc` (localized objective text `[Token]`), `vTgtInclude`, `vDestLoc`/`vDestRegion`, `nQuota`,
`bDspBlp` (radar blip), `vVoSeqOnAdd`, `tOnComplete`/`fOnComplete`, `tOnCancel`/`fOnCancel`.

**Layer loads**: world content is streamed in/out via `MrxLayerManager.Add/Remove/MarkForRemoval`. State
layers are named `Vz_State_<Mission>_<Phase>` (Pristine / Staging / Defenses / Captured / Destroyed /
WaveOne / etc.). Cleanup almost always `MarkForRemoval`s everything it added.

**Spawns** use `Pg.Spawn(name,x,y,z)` or `MrxUtil.SpawnObject(template, loc, name)`; AI is steered with
`Ai.Goal({ AIGuid=…, Goal="PathMove"/"MoveTo", Target=…, Priority="hiPri", Haste=… })`.

**Rewards** are handled by the base task class; scripts mostly grant *support items* via
`MrxSupportData.AddFreebie(...)` / `RemoveFreebie(...)` and achievements via
`MrxAchievements.NetGrantAchievement(...)`. Wager/cash payouts are configured in mission metadata
(`WifMissionFlow`/contract data), not hard-coded in these scripts.

### 1.2 Faction taxonomy

Prefixes encode the **issuing faction**:

| Prefix | Faction |
|--------|---------|
| `pmc` | Player's PMC / Mattias (story spine, tutorials, shooting galleries). |
| `gur` | Guerrillas (Ramon Solano's rivals / Universal Petroleum opponents). |
| `chi` | Chinese (PLA). |
| `all` | Allied Nations (UN-style coalition). |
| `oil` | Universal Petroleum (UP). |
| `pir` | Pirates. |
| `mec` | The Mechanic / Garage (vehicle-delivery jobs). |
| `jet` | Jet-pilot recruit line (`jetcon001` only). |
| `vza` | Venezuela (VZ government) — `vzacon001` only. |

`con` = **contract** (named, scripted, often story or "minor contract" set-pieces).
`job` = **job** (procedural/repeatable: destroy-type, collect-type, verify-set, destroy-set, vehicle delivery).

### 1.3 Base-class archetypes (drives the structure of each file)

| Base class | What the script does | Example |
|------------|----------------------|---------|
| `MrxTaskContract` | Full bespoke scripted contract. Long files, custom objective chains, set-pieces. | most `*con0xx` |
| `MrxTaskContractOutpost` | **Config-only.** Just returns `GetOutpostConfig()` (building, capture points, layer set, rival faction, health, rusher quota). Capture-the-outpost gameplay is entirely in the base. | all `*con05x` |
| `MrxTaskJob` / `MecJob` | Vehicle-delivery job. `MecJob` (= `mecjob.lua`) is a project-local base; `mecjob001-003` are thin reskins setting `sVehLabel`/`sVehImg`/`iMinHealth`. | `mecjob*` |
| `MrxTaskJobDestroyType` | "Destroy all of label X" job. Thin: set label filter + hero-only + go. | `gurjob001/006`, `oiljob004`, `pirjob001`, `chijob003`, `alljob003` |
| `MrxTaskJobDestroySet` | Destroy a fixed **set** of named targets (each with pristine/defense/destroyed/staging layers). | `alljob020`, `chijob020`, `gurjob020`, `oiljob008`, `pirjob020` |
| `MrxTaskJobVerifySet` | Photograph/"verify" a set of named targets. | `alljob002`, `chijob002`, `gurjob002`, `oiljob011`, `pirjob012` |
| `MrxTaskJobCollectType` | Collect N items of a label. | `pmcjob001` |
| (none) | `stagingact1` — plain function library, no task class. | `stagingact1` |

---

## 2. Catalog

(74 entries. "type": **con** = contract, **job** = job. Faction from prefix.)

| Script | Faction | Type | Base | Purpose (one line) |
|--------|---------|------|------|--------------------|
| [allcon001](src/vz/allcon001.lua) | all | con | Contract | Allied story contract (multi-objective, support freebies). |
| [allcon002](src/vz/allcon002.lua) | all | con | Contract | Allied story contract (3-objective chain). |
| [allcon003](src/vz/allcon003.lua) | all | con | Contract | Allied verify-then-destroy contract; grants **4× AL_CruiseMissile + 2× Gunship** freebies. |
| [allcon008](src/vz/allcon008.lua) | all | con | Contract | Allied scripted contract. |
| [allcon050](src/vz/allcon050.lua) | all | con | Outpost | Capture Allied outpost (health 6, rusher 1). |
| [allcon052](src/vz/allcon052.lua) | all | con | Outpost | Capture Allied outpost (health 6). |
| [allcon053](src/vz/allcon053.lua) | all | con | Outpost | Capture Allied outpost (health 6). |
| [alljob002](src/vz/alljob002.lua) | all | job | VerifySet | Verify a large set of targets (AllJob002 + AllJob010 reuse); jeep-assault trigger. |
| [alljob003](src/vz/alljob003.lua) | all | job | DestroyType | Destroy all **China**-labelled, hero-only. |
| [alljob020](src/vz/alljob020.lua) | all | job | DestroySet | Destroy a big shared target set (AllJob005/009 + ChiJob006 reuse), range-weighted VO. |
| [chicon001](src/vz/chicon001.lua) | chi | con | Contract | Chinese story contract; grants **ChiCon001_RocketArtillery** freebie. |
| [chicon002](src/vz/chicon002.lua) | chi | con | Contract | Chinese 3-objective contract. |
| [chicon003](src/vz/chicon003.lua) | chi | con | Contract | Chinese verify/destroy contract; grants **4× CH_CruiseMissile**. |
| [chicon008](src/vz/chicon008.lua) | chi | con | Contract | Chinese scripted contract. |
| [chicon009](src/vz/chicon009.lua) | chi | con | Contract | Chinese multi-objective contract (quota 1 sub-objective). |
| [chicon050](src/vz/chicon050.lua) | chi | con | Outpost | Capture Chinese outpost (health 6). |
| [chicon051](src/vz/chicon051.lua) | chi | con | Outpost | Capture Chinese outpost (health 6) + intro VO. |
| [chicon053](src/vz/chicon053.lua) | chi | con | Outpost | Capture Chinese outpost (health 6). |
| [chijob002](src/vz/chijob002.lua) | chi | job | VerifySet | Verify a set of Chinese targets. |
| [chijob003](src/vz/chijob003.lua) | chi | job | DestroyType | Destroy all **Allied**-labelled, hero-only. |
| [chijob020](src/vz/chijob020.lua) | chi | job | DestroySet | Destroy a fixed set of targets. |
| [gurcon001](src/vz/gurcon001.lua) | gur | con | Contract | Guerrilla "destroy castle/tower/bridge/barracks/munitions" multi-objective (munitions quota 3). |
| [gurcon002](src/vz/gurcon002.lua) | gur | con | Contract | Guerrilla contract incl. a **Bonus** objective. |
| [gurcon003](src/vz/gurcon003.lua) | gur | con | Contract | Guerrilla 2-objective contract. |
| [gurcon005](src/vz/gurcon005.lua) | gur | con | Contract | Guerrilla scripted contract (support freebie). |
| [gurcon050](src/vz/gurcon050.lua) | gur | con | Outpost | Capture Guerrilla outpost (health 3). |
| [gurcon052](src/vz/gurcon052.lua) | gur | con | Outpost | Capture Guerrilla outpost (health 4). |
| [gurcon053](src/vz/gurcon053.lua) | gur | con | Outpost | Capture Guerrilla outpost (health 3). |
| [gurjob001](src/vz/gurjob001.lua) | gur | job | DestroyType | Destroy all **Billboard**-labelled, hero-only (weighted complete-VO). |
| [gurjob002](src/vz/gurjob002.lua) | gur | job | VerifySet | Verify a set of Guerrilla targets. |
| [gurjob006](src/vz/gurjob006.lua) | gur | job | DestroyType | Destroy all **OC**-labelled, hero-only. |
| [gurjob020](src/vz/gurjob020.lua) | gur | job | DestroySet | Destroy a fixed set of targets. |
| [jetcon001](src/vz/jetcon001.lua) | jet | con | Contract | Jet-pilot recruit contract; sets `MrxSupportData.SetJetPilotRecruited(true)` (quota-3 objective). |
| [meccon001](src/vz/meccon001.lua) | mec | con | Contract | Mechanic intro contract: enter vehicle → drive around → go to mine → park. |
| [mecjob](src/vz/mecjob.lua) | mec | (base) | Job | **`MecJob` base class** — vehicle-delivery job framework (garage gate logic, deliver objective). |
| [mecjob001](src/vz/mecjob001.lua) | mec | job | MecJob | Deliver an **RTR** (label `rtr`, min health 30); spawns "RTR (crappy)". |
| [mecjob002](src/vz/mecjob002.lua) | mec | job | MecJob | Deliver an **M35** (label `m35`). |
| [mecjob003](src/vz/mecjob003.lua) | mec | job | MecJob | Deliver an **AMX-30** (label `amx30`). |
| [oilcon001](src/vz/oilcon001.lua) | oil | con | Contract | UP contract: go → attack waves → defend (grants OilCon001_Crate freebie). |
| [oilcon002](src/vz/oilcon002.lua) | oil | con | Contract | UP hostage-rescue: hijack → transit → deliver hostage to "Lucky Lady"; net-synced hack + heli teleport. |
| [oilcon003](src/vz/oilcon003.lua) | oil | con | Contract | UP 2-objective contract. |
| [oilcon005](src/vz/oilcon005.lua) | oil | con | Contract | UP scripted contract. |
| [oilcon020](src/vz/oilcon020.lua) | oil | con | Contract | UP 3-objective contract. |
| [oilcon021](src/vz/oilcon021.lua) | oil | con | Contract | UP 2-objective contract. |
| [oilcon050](src/vz/oilcon050.lua) | oil | con | Outpost | Capture UP outpost (health 3) + Fiona outpost-tutorial VO (gated on `GurCon053`). |
| [oilcon051](src/vz/oilcon051.lua) | oil | con | Outpost | Capture UP outpost. |
| [oilcon052](src/vz/oilcon052.lua) | oil | con | Outpost | Capture UP outpost. |
| [oiljob004](src/vz/oiljob004.lua) | oil | job | DestroyType | Destroy all **Guerilla**-labelled, hero-only. |
| [oiljob008](src/vz/oiljob008.lua) | oil | job | DestroySet | Destroy a fixed set of targets. |
| [oiljob011](src/vz/oiljob011.lua) | oil | job | VerifySet | Verify a set of UP targets. |
| [pircon001](src/vz/pircon001.lua) | pir | con | Contract | Pirate scripted contract. |
| [pircon002](src/vz/pircon002.lua) | pir | con | Contract | Pirate contract (shares PirCon003 end objective token). |
| [pircon003](src/vz/pircon003.lua) | pir | con | Contract | Pirate 2-objective contract. |
| [pircon004](src/vz/pircon004.lua) | pir | con | Contract | Pirate 3-objective contract. |
| [pircon051](src/vz/pircon051.lua) | pir | con | Outpost | Capture Pirate outpost. |
| [pircon052](src/vz/pircon052.lua) | pir | con | Outpost | Capture Pirate outpost. |
| [pirjob001](src/vz/pirjob001.lua) | pir | job | DestroyType | Destroy all **VZ**-labelled, hero-only. |
| [pirjob012](src/vz/pirjob012.lua) | pir | job | VerifySet | Verify a set of pirate targets. |
| [pirjob020](src/vz/pirjob020.lua) | pir | job | DestroySet | Destroy a fixed set of targets. |
| [pmccon001](src/vz/pmccon001.lua) | pmc | con | Contract | **Story spine**: go to villa → kill Solano's entourage → hijack the tank (waves, jeep pursuit, gate logic, "Ride the Dragon" achievement). |
| [pmccon002](src/vz/pmccon002.lua) | pmc | con | Contract | PMC contract: office → verify Blanco → destroy oil rig. |
| [pmccon003](src/vz/pmccon003.lua) | pmc | con | Contract | PMC multi-objective story contract (6+ objectives). |
| [pmccon004](src/vz/pmccon004.lua) | pmc | con | Contract | PMC 3-objective contract. |
| [pmccon013](src/vz/pmccon013.lua) | pmc | con | Contract | PMC scripted contract. |
| [pmccon015](src/vz/pmccon015.lua) | pmc | con | Contract | PMC scripted contract. |
| [pmccon016](src/vz/pmccon016.lua) | pmc | con | Contract | PMC multi-objective contract. |
| [pmccon018](src/vz/pmccon018.lua) | pmc | con | Contract | PMC scripted contract. |
| [pmccon031](src/vz/pmccon031.lua) | pmc | con | Contract | **Shooting-gallery** minor contract: MG/RR/GL statue-destroy + fling-car target practice. **`Object.SetInfiniteAmmo`**, timed (240/150/90 s). |
| [pmccon032](src/vz/pmccon032.lua) | pmc | con | Contract | **Shooting-gallery**: sandbags/tower car-destroy course. **`Object.SetInfiniteAmmo`**, timed. |
| [pmccon033](src/vz/pmccon033.lua) | pmc | con | Contract | **Shooting-gallery**: pop-up portrait/painting targets (net-synced targets up/down). **`Object.SetInfiniteAmmo`**. |
| [pmccon034](src/vz/pmccon034.lua) | pmc | con | Contract | **Shooting-gallery**: destroy-stuff + bonus-statue course. **`Object.SetInfiniteAmmo`**, timed. |
| [pmcjob001](src/vz/pmcjob001.lua) | pmc | job | CollectType | Collect **100× SpareParts** (`[PmcJob001.Title]`). |
| [stagingact1](src/vz/stagingact1.lua) | — | helper | (none) | Act-One world bootstrap: starts Guerrilla-base **patrols** (gate/trailer/road/squad/earthmover/moverarm) via hibernation-gated `Ai.Goal` PathMove loops. |
| [vzacon001](src/vz/vzacon001.lua) | vza | con | Contract | Venezuela (VZ) contract: long 9+-objective scripted chain. |

> **`Object.SetInfiniteAmmo`** is used by exactly the four PMC shooting-gallery contracts:
> [pmccon031](src/vz/pmccon031.lua), [pmccon032](src/vz/pmccon032.lua),
> [pmccon033](src/vz/pmccon033.lua), [pmccon034](src/vz/pmccon034.lua). It is toggled on in
> `_SetupP1Weapons`/`SetP2Weapons` and turned **off** again in `Complete`/`Cancel` (e.g.
> [pmccon031.lua:697](src/vz/pmccon031.lua#L697), [pmccon031.lua:891](src/vz/pmccon031.lua#L891)).

---

## 3. Common patterns & API

### 3.1 Lifecycle hooks (always chain to the base)

- **`Activated`** — wire events, then create first objective. Always calls the base first:
  [pmccon001.lua:71](src/vz/pmccon001.lua#L71) `MrxTaskContract.Activated(self)`;
  [alljob002.lua:107](src/vz/alljob002.lua#L107) `MrxTaskJobVerifySet.Activated(self)`.
- **`LoadAssets(self, tSaveData)`** — add layers, honor save flags, then `self.AssetsLoaded`:
  [pmccon001.lua:48](src/vz/pmccon001.lua#L48), [alljob002.lua:32](src/vz/alljob002.lua#L32),
  [mecjob.lua:7](src/vz/mecjob.lua#L7).
- **`Cleanup`** — undo everything, then base cleanup: [pmccon001.lua:837](src/vz/pmccon001.lua#L837)
  (force-exit seats, remove radar objectives, `MarkForRemoval` 7 layers, restore VZ↔PMC relation,
  re-enable reporting, reset atmosphere), then [pmccon001.lua:863](src/vz/pmccon001.lua#L863)
  `MrxTaskContract.Cleanup(self)`.
- **`Complete` / `Cancel`** — optional. Shooting galleries restore weapons + grant achievement
  ([pmccon031.lua:889](src/vz/pmccon031.lua#L889)); `MecJob` plays a fanfare
  ([mecjob.lua:53](src/vz/mecjob.lua#L53), [mecjob.lua:75](src/vz/mecjob.lua#L75)).

### 3.2 Event wiring

`self:_CreateEvent(EventType, {args}, callback, {cbArgs})` (auto-cleaned on task teardown) and the
free-standing `Event.Create(...)` / `Event.CreatePersistent(...)`. Common event types:
`Event.ObjectDeath`, `Event.ObjectHibernation` ("awake"/"hibernated"), `Event.Boundary`
(region enter/exit), `Event.ObjectProximity`, `Event.ObjectInSeat`, `Event.TimerRelative`,
`Event.ObjectHealth`, `Event.ObjectIsVisible`, `Event.ScriptEvent`. Examples:
[pmccon001.lua:72](src/vz/pmccon001.lua#L72) (object death → cancel),
[pmccon001.lua:155](src/vz/pmccon001.lua#L155) (boundary → start jeep pursuit),
[pmccon031.lua:135](src/vz/pmccon031.lua#L135) (health drop → damage VO).

### 3.3 Objective setup

`self:CreateChild({ sModuleName = "MrxTaskObjective…", … })`. Representative:
- **Deliver / go-to**: [pmccon001.lua:271](src/vz/pmccon001.lua#L271) (`MrxTaskObjectiveDeliver`,
  `vDestLoc`/`vDestRegion`, `bXZOnly`).
- **Destroy with quota**: [pmccon001.lua:580](src/vz/pmccon001.lua#L580)
  (`MrxTaskObjectiveDestroy`, `sTgtLabelFilter="VZ"`, `nQuota=10`).
- **Enter vehicle**: [pmccon001.lua:517](src/vz/pmccon001.lua#L517) (`MrxTaskObjectiveEnterVehicle`).
- Chaining: each objective's `tOnComplete = {{ NextFn, {self} }}` (or `fOnComplete = function() … end`).

### 3.4 Faction / pursuit / AI

`MrxFactionManager.SetCustomPursuit / ClearCustomPursuit / DisableReporting / ClearPursuitLock`
([pmccon001.lua:220](src/vz/pmccon001.lua#L220), [pmccon001.lua:231](src/vz/pmccon001.lua#L231));
`Ai.SetRelation`, `Ai.SetLaneActive`, `Ai.Goal{...}`
([pmccon001.lua:633](src/vz/pmccon001.lua#L633), [stagingact1.lua:115](src/vz/stagingact1.lua#L115)).

### 3.5 Reward / support dispensing

Cash/wager is configured in mission metadata (handled by the base task). Scripts dispense **support
items** and **achievements**:
- `MrxSupportData.AddFreebie / RemoveFreebie` — [allcon003.lua:21](src/vz/allcon003.lua#L21),
  [chicon001.lua:89](src/vz/chicon001.lua#L89), [oilcon001.lua:142](src/vz/oilcon001.lua#L142).
- `MrxSupportData.SetJetPilotRecruited` — [jetcon001.lua:31](src/vz/jetcon001.lua#L31).
- `MrxAchievements.NetGrantAchievement` — [pmccon001.lua:506](src/vz/pmccon001.lua#L506)
  ("ACHIEVEMENT_RIDE_DRAGON"), [pmccon031.lua:901](src/vz/pmccon031.lua#L901)
  ("ACHIEVEMENT_GONE_SHOOTIN").

### 3.6 Net synchronization (co-op)

Shared `NETEVENT_*` integer constants + `Net.SendCustomEvent("<MissionId>", id, {args})` dispatched by a
`NetEventCallback(nEventId, tArgs)`. Pattern in [pmccon031.lua:21](src/vz/pmccon031.lua#L21),
[pmccon001.lua:33](src/vz/pmccon001.lua#L33), [pmccon033.lua:19](src/vz/pmccon033.lua#L19),
[oilcon002.lua:27](src/vz/oilcon002.lua#L27). `OnPlayerJoined` resends startup state to late joiners
([pmccon001.lua:115](src/vz/pmccon001.lua#L115)).

### 3.7 Config-only contracts (outpost capture)

The simplest scripts. They only return `GetOutpostConfig()`; all gameplay lives in
`MrxTaskContractOutpost`. Full example: [gurcon050.lua:3](src/vz/gurcon050.lua#L3). Keys:
`sOutpostBldg`, `tCapturePts`, `sStaging/Pristine/Defense/Captured Layer`, `sStagingTgLayer`/
`sCapturedTgLayer` (target-graphics overlay), `sRivalFaction`, `nStartingHealth`, `nRusherQuota`.

---

## 4. Defaults & tunables

### 4.1 Outpost-capture config constants

| Mission(s) | `nStartingHealth` | `nRusherQuota` | rival |
|------------|-------------------|----------------|-------|
| gurcon050, gurcon053, oilcon050 | 3 | 1 | Vza |
| gurcon052 | 4 | 1 | Vza |
| allcon050/052/053, chicon050/051/053 | 6 | 1 | Vza |

(See [gurcon050.lua:17](src/vz/gurcon050.lua#L17), [gurcon052.lua:18](src/vz/gurcon052.lua#L18),
[chicon051.lua:16](src/vz/chicon051.lua#L16), [oilcon050.lua:18](src/vz/oilcon050.lua#L18).)

### 4.2 Shooting-gallery timers (pmccon031, scaled by completions)

[pmccon031.lua:92](src/vz/pmccon031.lua#L92)–[L104](src/vz/pmccon031.lua#L104):

| Completions | Time limit | "Time to beat" |
|-------------|-----------|----------------|
| 0 | 240 s | 4:00 |
| 1 | 150 s | 2:30 |
| ≥2 | 90 s | 1:30 |

Also: `PointDist = 2.5`, `NumCars = 10` ([pmccon031.lua:93](src/vz/pmccon031.lua#L93)); timer
`nStep=0.1`, `nWarning=10` ([pmccon031.lua:116](src/vz/pmccon031.lua#L116)); music speed-up at
`nTimeLimit-25` ([pmccon031.lua:674](src/vz/pmccon031.lua#L674)); a `+5 s` bonus per car hit
([pmccon031.lua:660](src/vz/pmccon031.lua#L660)); 4 missed cars triggers negative VO
([pmccon031.lua:585](src/vz/pmccon031.lua#L585)). Statue quotas are **counted live from surviving
columns** (`nQuota = nQuota + 1` per alive column), see
[pmccon031.lua:275](src/vz/pmccon031.lua#L275).

### 4.3 Job tunables (live in the thin `Activated`)

- `pmcjob001`: quota **100** items, label `SpareParts` ([pmcjob001.lua:9](src/vz/pmcjob001.lua#L9)).
- `mecjob001`: min vehicle health **30**, label `rtr` ([mecjob001.lua:8](src/vz/mecjob001.lua#L8));
  `mecjob002` → `m35`, `mecjob003` → `amx30`.
- DestroyType label filters: China/Allied/Billboard/OC/Guerilla/VZ (see §2 + the grep in §3.5).

### 4.4 Where mission-specific magic numbers live

- Hard-coded **spawn coordinates**: e.g. fling-car positions
  [pmccon031.lua:553](src/vz/pmccon031.lua#L553)–[L563](src/vz/pmccon031.lua#L563).
- Long **named-GUID target arrays** (statues, doors, HVTs): `tStatueTargets`
  [pmccon031.lua:223](src/vz/pmccon031.lua#L223), `tPmcDoors`
  [pmccon001.lua:11](src/vz/pmccon001.lua#L11), HVT_01..05
  [pmccon001.lua:305](src/vz/pmccon001.lua#L305).
- Wave size/quota: `nQuota=10` ([pmccon001.lua:586](src/vz/pmccon001.lua#L586)), munitions quota 3
  ([gurcon001.lua:213](src/vz/gurcon001.lua#L213)).

---

## 5. Notable / unique mechanics

- **pmccon001 — the story showpiece.** Jeep pursuit with a custom pursuit table
  ([pmccon001.lua:166](src/vz/pmccon001.lua#L166)), scripted gate open/close keyed on door hibernation
  ([pmccon001.lua:247](src/vz/pmccon001.lua#L247), [L353](src/vz/pmccon001.lua#L353)), an invisible
  physics collider that gets net-safely shoved out of the way
  ([pmccon001.lua:384](src/vz/pmccon001.lua#L384)), a tank **action-hijack** tutorial granting the
  "Ride the Dragon" achievement ([pmccon001.lua:501](src/vz/pmccon001.lua#L501)), two enemy waves
  ([pmccon001.lua:652](src/vz/pmccon001.lua#L652), [L735](src/vz/pmccon001.lua#L735)) and a scripted
  "flee in terror" finale ([pmccon001.lua:615](src/vz/pmccon001.lua#L615)).
- **Infinite-ammo shooting galleries (pmccon031-034).** Player weapons are stripped, dropped, and
  physically buried 5 units underground (`_MoveWeapons`,
  [pmccon031.lua:723](src/vz/pmccon031.lua#L723)) while `Object.SetInfiniteAmmo(true)` and a gallery HUD
  mode are enabled; restored on Complete/Cancel. Targets are statues counted live, plus a timed
  fling-car phase. pmccon033 additionally pops up/lowers portrait targets over the net
  (`NETEVENT_TARGETSDOWN/UP`, [pmccon033.lua:44](src/vz/pmccon033.lua#L44)).
- **oilcon002 — hostage escort** with a net-synced "hack" mini-objective and teleporting the *Lucky
  Lady* helicopter ([oilcon002.lua:27](src/vz/oilcon002.lua#L27)).
- **Vehicle-delivery jobs (mecjob/mecjob001-003).** Garage-gate state machine
  (player inside/outside region opens/closes the gate, cleans up the delivered car), label-filtered
  `Event.ObjectInSeat`, polaroid HUD image of the wanted vehicle
  ([mecjob.lua:138](src/vz/mecjob.lua#L138), [mecjob.lua:317](src/vz/mecjob.lua#L317)).
- **stagingact1 — patrol bootstrap.** Not a task at all: a library of `…Patrol()` functions that, on
  object dehibernation, kick off looping `Ai.Goal` PathMoves with per-patrol haste constants
  (.1–.5) to populate the Guerrilla base at Act-One start ([stagingact1.lua:5](src/vz/stagingact1.lua#L5)).
- **Freebie-granting contracts.** allcon003 (cruise missiles + gunships), chicon001 (rocket artillery),
  chicon003 (cruise missiles), oilcon001 (crate) hand the player support items for the mission and
  revoke them on cleanup.

---

## 6. Logging & debug markers

Contracts log liberally with `Debug.Printf`, usually prefixed by long banners of `*`/`^`/`$`/`@` to
stand out in the log. A representative sample:

- `"***************Staging Act One is GO GO GO"` — [stagingact1.lua:2](src/vz/stagingact1.lua#L2)
- `"************** PMC 001: INVESTIGATE VILLA FLAG RETRIEVED"` — [pmccon001.lua:94](src/vz/pmccon001.lua#L94)
- `"********************* VZ Jeep Pursuit Region Active! "` — [pmccon001.lua:161](src/vz/pmccon001.lua#L161)
- `"SSSSSSSSSSSSSSSStop stop Pursuit "` — [pmccon001.lua:230](src/vz/pmccon001.lua#L230)
- `"********************* PMCCON001: FLAG SET"` — [pmccon001.lua:304](src/vz/pmccon001.lua#L304)
- `"******************PMC 001: FOR loop about to fire"` — [pmccon001.lua:629](src/vz/pmccon001.lua#L629)
- `"Wave 01 - Member Dead"` / `"Wave 02 - Member Dead"` — [pmccon001.lua:668](src/vz/pmccon001.lua#L668)
- `"got NETEVENT_SETSTARTUPWEAPONS"` / `"got NETEVENT_RETURNWEAPONS"` — [pmccon031.lua:23](src/vz/pmccon031.lua#L23)
- `"nQuota = " .. nQuota` — [pmccon031.lua:278](src/vz/pmccon031.lua#L278)
- `"^^^^^^^^^^^^^^^^^^^^5 statues left"` — [pmccon031.lua:340](src/vz/pmccon031.lua#L340)
- `"$$$$$$$$$$INside Obj_MGStatues_StatueKilled…"` — [pmccon031.lua:345](src/vz/pmccon031.lua#L345)
- `"@@@@@@@@@@ CLEANUP ON "` / `"@@@@@@@@@ REMOVED"` — [mecjob.lua:274](src/vz/mecjob.lua#L274)
- `"----------------- _VehicleDelivered: PLAYER OUTSIDE OF REGION"` — [mecjob.lua:245](src/vz/mecjob.lua#L245)

These are noisy and are the natural grep anchors when tracing a contract in `pmc_blackbox.log`.

---

## 7. Cross-references & future-dev notes

### 7.1 What contracts import (helper modules — documented in other groups)

Common `import(...)`s seen across this group:

| Module | Role |
|--------|------|
| `MrxVoSequence` | sequenced voice-over playback (per-hero variants: mattias/jennifer/chris). |
| `MrxLayerManager` | streamed world layer add/remove/mark-for-removal. |
| `MrxSupportData` | freebies, recruit flags (jet pilot). |
| `MrxFactionManager` | relations, reporting, custom pursuit. |
| `MrxTimer` | gallery countdown timers. |
| `MrxMusic` / `MrxSoundCategories` | special mission music + fades. |
| `MrxAchievements` | net-granted achievements. |
| `MrxUtil` | random table element, spawn helpers, hero-weapon enable. |
| `MrxShootingGallery` | gallery HUD/weapon helpers (pmccon03x). |
| `MrxTutorialManager` | tutorial message popups (action-hijack). |
| `MrxState` / `WifMissionFlow` / `WifBios` | mission-flow keys, dossier/bio entries. |
| `MrxSubtitle`, `MrxCinematic`, `MrxGuiHudMessage`, `MrxGuiPda`, `MrxTransit`, `MrxTaskObjectiveDestroy` | UI / cinematics / transit / objective module pull-ins. |

The **task base classes** (`MrxTaskContract`, `MrxTaskContractOutpost`, `MrxTaskJob*`, `MecJob`) are the
single most important cross-reference — they own rewards, save/restore, PDA, and the capture/destroy/
verify/collect loops. Document them in the "task framework" group; the scripts here are thin content on
top.

### 7.2 How to add a new contract

1. **Pick a base.** Repeatable destroy/verify/collect/outpost → use the thin `MrxTaskJob*` /
   `MrxTaskContractOutpost` form (often <30 lines, see [gurcon050.lua](src/vz/gurcon050.lua),
   [oiljob004.lua](src/vz/oiljob004.lua)). Bespoke scripted → `MrxTaskContract`.
2. **Author layers** named `Vz_State_<Mission>_<Phase>` and load/remove them in `LoadAssets`/`Cleanup`.
3. **Localize** every `sDspShortDesc` / VO id as `[<Mission>.…]` tokens (the scripts only reference
   tokens; the strings live in the localization tables).
4. **Chain objectives** with `CreateChild` + `tOnComplete`/`fOnComplete`; always call the base in
   `Activated`/`Cleanup`.
5. **Net co-op**: if you change player state (weapons, spawns), define `NETEVENT_*` ids, handle them in
   `NetEventCallback`, and re-sync in `OnPlayerJoined`.
6. **Register** the mission with the contract/mission-flow metadata (rewards, wager, prereq keys via
   `WifMissionFlow.HasKey(...)`) — that lives outside these scripts.

### 7.3 Modifying mechanics safely

- Outpost difficulty: just edit `nStartingHealth` / `nRusherQuota` in `GetOutpostConfig`.
- Gallery difficulty: edit the completion-scaled `nTimeLimit` table in `Activated`
  ([pmccon031.lua:92](src/vz/pmccon031.lua#L92)).
- Job target/quota: edit the `_Set*` calls in the job's `Activated` (single line each).
- Beware the hard-coded GUID hashes (`… 0x000c7042`) and world coordinates — they bind to specific
  placed world objects and will break if the level layout changes.
