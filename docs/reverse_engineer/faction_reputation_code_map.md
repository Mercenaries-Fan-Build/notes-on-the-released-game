# Faction / reputation — Xbox↔PC code map

**Scope:** the **faction / reputation / pursuit ("heat") system** — a cross-cutting gameplay
system that has no scoreboard row of its own but whose engine hooks are scattered across AI (row
23), population spawn-lists (row 24), HUD (row 27), and dynamic music (row 21). This is the
consolidation of pieces previously spread across `game-systems.md`, `mrxfactionmanager.lua`, and
`ecs-07` and never married. It covers: the **combat→faction mood bridge** (the native emitter of
the seven infraction-score keys), the **per-faction relation matrix** behind `Ai.Get/SetRelation`,
the **Faction\* ECS descriptors** (id / value / zone), the **pursuit-level ("heat") state + timers**,
the **faction markers / HUD meter**, **faction-locked dynamic music**, and the **`Net*Faction*`
replication set**. It marries the **Xbox 360 devkit (Jul-08 "Profile" build, `Mercs2_Xenon_P.exe`,
PowerPC, base `0x82000000`)** symbol/PDB ground truth to the **PC retail decompilation**
(`Mercenaries2.exe`, unpacked SecuROM image, base `0x00400000`).

This is the gameplay-meta companion to the sibling maps
([`weapons_combat_code_map.md`](weapons_combat_code_map.md) — whose §5.2 established the entry
point this map expands; [`state_machine_destruction_code_map.md`](state_machine_destruction_code_map.md)
— the destruction consumer whose damage events feed the same accumulator; and the streaming spine
[`world_streaming_code_map.md`](world_streaming_code_map.md), whose §4 already mapped the
music-region + faction-region-music cfuncs this map cross-references). It deliberately leaves the
event-bus dispatch internals to [`event_bus_code_map.md`](event_bus_code_map.md) and the music
engine to the audio corpus.

**Sources.** Xbox oracle: [`../mercs2-pdb-analysis/game-systems.md`](../mercs2-pdb-analysis/game-systems.md)
§"Factions / reputation" (the 17-symbol `.rdata` inventory + `GetFactionGuid`/`ApplyCachedFactionRelations`/
`RestrictPursuitFaction`/`xPgSysNetFactionRelations` + the `Net*Faction*` set + the `FactionMarker
1280`/`FactionValue 64 64`/`FactionZone 16 16`/`RtFactionZone 16 16` pool dump) and
[`../mercs2-pdb-analysis/networking.md`](../mercs2-pdb-analysis/networking.md) §G (`HostileAware`/
`HostileObservers`). Data oracle: [`../mercs2-ecs/07_gameplay_state_health_mission.md`](../mercs2-ecs/07_gameplay_state_health_mission.md)
§"Faction\* family" (the PC descriptor hashes/schemas). Lua surface (the attitude math):
[`../mercs2-luacd/src/resident/mrxfactionmanager.lua`](../mercs2-luacd/src/resident/mrxfactionmanager.lua)
+ [`../mercs2-luacd/07_player_core_cheats_managers.md`](../mercs2-luacd/07_player_core_cheats_managers.md)
§"Faction attitudes & price scaling" + [`../mercs2-luacd/05_gui_hud_shell.md`](../mercs2-luacd/05_gui_hud_shell.md)
§2.9 (faction gauge) + [`../mercs2-luacd/08_audio_presentation.md`](../mercs2-luacd/08_audio_presentation.md)
(MrxMusic). Binding layer: [`../lua_engine_bindings_audit.md`](../lua_engine_bindings_audit.md)
(Faction/Pursuit table near `0x007B98EC`; dynamic-music VAs). PC bodies read first-hand from the
27k-fn Ghidra decomp and cited as `ghidra/FUN_xxxx`.

**Method / honesty model.** Same discipline as the sibling maps. PC retail strips the
`FactionManager`/`Pursuit`/`SetRelation` profiler strings, and the whole *attitude math* lives in
Lua (`mrxfactionmanager.lua`), so the native side is a **thin C layer**: (a) a per-faction relation
matrix behind two Lua cfuncs, (b) a combat-infraction accumulator + its serializer, (c) single-field
ECS components, (d) a pursuit-state singleton, (e) HUD-marker + music toggles. The **one native
body read first-hand and pinned by a can't-coincide fingerprint** is the mood bridge `FUN_005e0720`
(§2) — its literal seven infraction-key strings are the **exact** set + order + role the Lua
`Report.GetInfractions`/`FinishedReporting` consumes. The `Ai.*`/`Pg.*Pursuit*` cfunc *bodies* are
**binding-table-only** (the same pattern as the 6 missing Lua binders the streaming/weapons maps
hit) → their VAs come from the `luaL_Reg` walk and **their bodies are recovered by disassembling
that VA** (~~a `DecompileProfileAccessors.java`-style forcing script~~ — obsolete 2026-07-26, see
`ghidra_knowledge_inventory.md` Part F.4), stated honestly per row. Confidence: **H** can't-coincide fingerprint (read body +
matching constants/role) · **M** one strong structural signal · **L/open** positional / binding-only
/ confirm-live.

**CRITICAL — SecuROM is NOT a blocker** ([[securom-decompiled-not-a-blocker]]). Exactly one indirect
touches this system: the infraction accumulator getter `thunk_FUN_024e9930` → `FUN_024e9930` →
`thunk_FUN_02a30028(&PTR_DAT_024e993a)` — the SecuROM **VM dispatcher**. That is **VM-virtualised
residue, read live in the unpacked image**, not a wall: the accumulator struct it returns is the
7×{id,score} array `FUN_005e0720` walks (§2), whose shape is fully recovered from the serializer.
No `thunk_FUN_024xxxxx` here is a "wall".

---

## 0. Result in one line

**The faction system is recovered as a thin native layer under a Lua brain, with one native body
pinned first-hand.** The **combat→faction mood bridge `FUN_005e0720`** (H, read) is the native
emitter that serializes the seven-key infraction accumulator (`DamagePerson`/`DestroyPerson`/
`DamageObject`/`DestroyObject`/`Hijack`/`Trespassing`/`SpecialEvent`) into the structure the Lua
`Report.GetInfractions` reads; `Ai.AddInfraction` is its input side and `Ai.Get/SetRelation` the
relation-matrix accessors that `mrxfactionmanager.lua` weights into `[-100,100]` relations →
`Event.Post("Attitude")` (bus driver `FUN_005f6a90`). The **Faction\* ECS descriptors** are married
on both builds by the standard two-role registrar/consumer pair (`FUN_00641340`+`FUN_0065c0f0` etc.).
The **pursuit "heat" state**, the **faction markers/HUD meter**, and the **faction-locked music** are
each a small set of Lua-facing cfuncs — two of the music VAs already pinned by the streaming map
(`0x5E1CC0`/`0x5E1C40`), the rest binding-table-only (recover via the walk). The Xbox `Net*Faction*`
replication set has names on both builds; PC bodies are unlocated (role certain).

---

## 0.5 Master marriage table (whole system at a glance)

Per-cluster evidence in §2–§8. A bare Xbox `.rdata` offset means the Xbox *code body* is unlocated
(name string only) and the marriage is PC-anchored. "Married by" = the concrete signal.

| Role | Xbox symbol / addr | PC addr | Married by | Conf |
|---|---|---|---|---|
| **Combat→FACTION mood bridge** (serialize 7 infraction scores) | `DamagePerson @8245af18` (Xbox cmd) | **`FUN_005e0720`** (508 B) | read body: emits the literal 7-key set `DamagePerson/DestroyPerson/DamageObject/DestroyObject/Hijack/Trespassing/SpecialEvent` — **exact** match to `mrxfactionmanager.lua:1212-1219` mood weights (§2) | H |
| Per-key emit leaf (name + {score,id}) | — | **`FUN_0059f470`** (130 B) | read body: writes name via `FUN_0085d9f0` then two type-tag-3 words into buf `+8`; only caller `FUN_005e0720` (7×) | H |
| Event/message post primitive | — | **`FUN_0059dbe0`** (15 B) | read body: `if(*ESI>0) FUN_0056f256() else *ESI=-2`; generic dispatch, 30+ callers | H |
| **Infraction accumulator getter** (7×{id,score}) | — | `thunk_FUN_024e9930` → `FUN_024e9930` → `thunk_FUN_02a30028(&PTR_DAT_024e993a)` | VM-virtualised residue — **read live in unpacked image**, shape known from `FUN_005e0720` walk | M (live) |
| **`Ai.AddInfraction(char,faction,amt)`** (mood input) | (Lua binder) | binding-table VA **unlocated** | Lua call site `mrxtaskobjectiveverify.lua` `Ai.AddInfraction(char,uFaction,5)`; feeds the §2 accumulator | M (role) |
| **`Ai.GetRelation(subjGuid,objGuid)`** → int `[-100,100]` | (Lua binder) | binding-table VA **unlocated** | Lua `GetRelation` = `Ai.GetRelation(guidA,guidB)`; reads the per-faction relation matrix | L (VA) |
| **`Ai.SetRelation(subj,obj,rel)`** | (Lua binder) | binding-table VA **unlocated** | Lua `SetRelation`→`Ai.SetRelation`; writes matrix | L (VA) |
| Faction name→GUID resolve | `GetFactionGuid` (rdata `0x0024e60`); assert `Warning: GetFactionGuid(0x%0x) = 0` | — (behind `Pg.GetGuidByName`) | Lua `tFactionData.uGuid = Pg.GetGuidByName(sFactionTemplate)`; matrix keyed by this GUID | M |
| Cached-relations apply (load / net-init) | `ApplyCachedFactionRelations` (rdata `0x0029204`) | — | Xbox name only; role = re-apply a saved/replicated relation set; PC unlocated | open |
| Faction comparison predicates | `SameFaction`/`SingleFaction`/`BanFaction` (rdata `0x001fdf0`/`0x0039e90`/`0x0039ea0`) | — | Xbox name only; friend/foe + faction-restrict queries; PC unlocated | open |
| **FactionMarker** descriptor registrar (faction id, int32) | `FactionMarker` (rdata `0x00313dc`); pool `FactionMarker 1280` | **`FUN_00641340`** (159 B) | read body: stride `4`, seed `0x9e3779b9`, `CopyFromStream_00bbf928`, pool `0x100`, `s_FactionMarker_00bc5078` | H |
| FactionMarker stream-deserialize consumer / schema | — | **`FUN_0065c0f0`** (138 B, hash `0x9b98cb09`) | read body: `FUN_0064a600` → pool `DAT_017bd5a4`, spatial-reg `FUN_00665590` (ecs-07) | H |
| **FactionValue** descriptor (per-entity rep scalar, float) | `FactionValue @829f44f0` (rdata `0x0031438`); pool `64 64` | reg `FUN_00641830` · schema `FUN_0065c7d0` (hash `0x8bfc69d6`) | game-systems.md registrar + ecs-07 schema; stride 4 (1 float) | H |
| **FactionZone** descriptor (faction-owned zone id, int32) | `FactionZone` (rdata `0x0031438`/`0x002ba28`); pool `16 16` | reg `FUN_006414b0` · schema `FUN_0065c490` (hash `0x67267cc1`) | game-systems.md + ecs-07; stride 4 | H |
| **RtFactionZone** runtime state (28 B raw-copy) | — (Xbox pool `RtFactionZone 16 16`) | desc base `0x017c05f8` (hash `0xa67114c7`) | ecs-07 registry (string-anchored); live counterpart of FactionZone | H |
| **Pursuit-level times** setter | `RestrictPursuitFaction` (rdata `0x002a534`) | `Pg.SetPursuitLevelTimes` VA **unlocated** | Lua `Pg.SetPursuitLevelTimes(120,300)` at Setup; sets per-level dwell seconds | L (VA) |
| Pursuit-state read/write cfuncs | (Lua binders) | `Pg.GetPursuitState`/`SetPursuit`/`SetPursuitSeconds`/`LockPursuit`/`ClearPursuitLock`/`SetCustomPursuit` VAs **unlocated** | Lua `IncrementPursuit`/`LockPursuit`/`SetCustomPursuit` call sites; level clamp `0..3` | L (VA) |
| **Faction world-markers** toggles | `EnableFactionMarkers`/`SetFactionMarkerSize`/`SetFactionMarkerVisibleDistance` (rdata `0x00275dc`–`0x002760c`) | binding-table VAs **unlocated** | Xbox names; world-space unit faction blips | L (VA) |
| **HUD faction meter** | `NetClientFactionHideMeter` | Lua `Hud.FactionDisplay` (Scaleform `mrxguihudfactiongauge.lua`) | `AddMeter`/`SetValue`/`StartTimer`/`StartPursuit`/`HideMeter`; levels `{0,25,50,75}`, pursuit `[0x1cab5133]` | H (Lua) |
| **Faction-locked music** | `IsFactionLockedMusic`/`LockFactionMusic`/`SetFactionMusic`/`AddFactionMusic` (rdata `0x002c07c`–`0x002c0b8`) | `ActivateFactionRegionMusic`=`0x005E1CC0`, `SetRootFactionRegionMusic`=`0x005E1C40` (streaming map §4); `TransitionMusic`=`0x005E1600`, `SetDynamicMusic`=`0x005E16E0` | streaming-map cfunc walk + bindings-audit; `RuntimeMusicRegion` desc `FUN_00644fe0` | H / L |
| **Net faction replication** system | `xPgSysNetFactionRelations` (rdata `0x00444f3`) | — | Xbox name; the faction-relation replicator; PC body unlocated | open |
| Net faction ops | `NetInitializeClientFactionRelations`/`NetClientFactionSetValue`/`NetClientFactionStartPursuit`/`NetClientFactionHideMeter` | Lua `Net.*` + `Net.SetPursuitReportingState`; PC cfunc VAs **unlocated** | game-systems.md net list; Lua replication in `mrxfactionmanager.lua` | M (Lua) / open |
| AI hostility awareness (adjacent) | `HostileAware`/`HostileObservers` (networking.md §G); log `HostileAware: %d` | — | Xbox names; replicated friend/foe awareness; PC unlocated | open |
| **Attitude event fire** (relation-level change) | — | Lua `Event.Post("Attitude",…)` → bus `FUN_005f6a90` | `mrxfactionmanager.lua:587` on attitude-level cross; bus driver from event_bus map | H (Lua) |

---

## 1. Where faction state flows (the loop)

```
HOSTILE ACT (weapons/destruction/hijack/trespass):
  per-hit / kill / hijack / zone-enter
      Ai.AddInfraction(playerChar, uFaction, amount)      ← Lua binder → accumulator
         accumulator = 7×{id,score}  [thunk_FUN_024e9930 getter, VM-virtualised]

REPORT TICK (a faction NPC "reports" you — MrxFactionManager.Report):
  native serialize the accumulator:
      FUN_005e0720   emit {score,id} under each of 7 keys via FUN_0059f470
                     → FUN_0059dbe0 post the built infraction message
      ──────────────►  Lua Report.GetInfractions(uGuid)  reads the same 7-key table

  Lua FinishedReporting (mrxfactionmanager.lua:1201):
      nMood = DamageObject*1 + DestroyObject*25 + Trespassing*20 + Hijack*10
            + SpecialEvent[1]*[2] + DestroyPerson*50 + DamagePerson*3      (clamp ≥ -60)
      ChangeRelation(faction,"Pmc", -nMood)

RELATION WRITE:
  SetRelation → Ai.SetRelation(subjGuid, objGuid, nRelation)   [-100,100]
      if attitude LEVEL crossed → Event.Post("Attitude",{subj,obj,oldLabel,newLabel})  → FUN_005f6a90
      Hud.FactionDisplay:SetValue(meter 0..100)   Pda.Database:SetFactionAttitude
      if relation ≤ -100 → IncrementPursuit(faction)

PURSUIT ("heat"):
  Pg.GetPursuitState().Level +1 (max 3) → Pg.SetPursuit(uFaction,nLevel,true)
      Pg.SetPursuitSeconds(uFaction,5,true)   Hud.FactionDisplay:StartPursuit
      dwell per level = Pg.SetPursuitLevelTimes(120,300)

CONSUMERS of attitude/pursuit: shop price scale (GetPriceScale), spawn/report tables,
   HUD meter, PDA, dynamic music lock (LockFactionMusic), pursuit VO, achievements.
```

The whole *policy* is Lua; the native layer is the accumulator + serializer (§2), the relation
matrix accessors (§3), the ECS hooks (§4), and the pursuit/marker/music/net toggles (§5–§8).

---

## 2. The combat→faction mood bridge — `FUN_005e0720` (H, read first-hand)

This is the anchor the weapons map (§5.2) surfaced; read first-hand here. `FUN_005e0720`
(508 B, **`callers=[]`** — invoked through the Lua-binding/vtable table, exactly like the six
binding-table-only binders) fetches the live infraction accumulator and **serializes each of its
seven scores out under its event-name key**:

```c
undefined4 FUN_005e0720(int param_1) {                       // param_1 = the Lua/serialize buffer
  if (0 < (*(int*)(param_1+8) - *(int*)(param_1+0xc) >> 3)   // buffer has room
      && FUN_0059ff50(local_1c) != 0) {                      // open a sub-table
    puVar2 = (undefined4*)thunk_FUN_024e9930();              // the 7×{id,score} accumulator (VM getter)
    if (puVar2 == 0) return 0;
    thunk_FUN_024f0da0(auStack_14, 7);                       // reserve 7 entries
    fStack_24=(float)(int)puVar2[1];  local_20=puVar2[0];  FUN_0059f470(.., s_DamagePerson_00bb3d48,  &fStack_24);
    fStack_24=(float)(int)puVar2[5];  local_20=puVar2[4];  FUN_0059f470(.., s_DestroyPerson_00bb3d68, &fStack_24);
    fStack_24=(float)(int)puVar2[3];  local_20=puVar2[2];  FUN_0059f470(.., s_DamageObject_00bb3d58,  &fStack_24);
    fStack_24=(float)(int)puVar2[7];  local_20=puVar2[6];  FUN_0059f470(.., s_DestroyObject_00bb3d78, &fStack_24);
    fStack_24=(float)(int)puVar2[9];  local_20=puVar2[8];  FUN_0059f470(.., s_Hijack_00bb3d88,        &fStack_24);
    fStack_24=(float)(int)puVar2[0xb];local_20=puVar2[10]; FUN_0059f470(.., s_Trespassing_00bb9940,   &fStack_24);
    fStack_24=(float)(int)puVar2[0xd];local_20=puVar2[0xc];FUN_0059f470(.., s_SpecialEvent_00bb994c,  &fStack_24);
    if (local_1c[0] != 0 && 0 < iStack_18) FUN_0059dbe0();   // post the built infraction message
    return 1;
  }
  ...
}
```

**Why this is H (can't-coincide).** The seven literal key strings, in this order and role, are
**exactly** the seven keys `mrxfactionmanager.lua:1212-1219` reads back from `Report.GetInfractions`
and weights:

```
nMood = DamageObject[2]*1  + DestroyObject[2]*25 + Trespassing[2]*20 + Hijack[2]*10
      + SpecialEvent[1]*SpecialEvent[2] + DestroyPerson[2]*50 + DamagePerson[2]*3   (clamp ≥ -60)
```

Each accumulator slot is a **2-word `{id, score}` pair** (`puVar2[even]` = an owner/faction id or
count, `puVar2[odd]` = the score cast `int→float`), so the native side emits `{score, id}` per key
— which is precisely the `tInfractions.<Key> = { [1]=count/id, [2]=weightable-value }` pair-shape
the Lua indexes with `[2]` (and `[1]` for `SpecialEvent`). So `FUN_005e0720` is the **native
producer of the infractions table**; the mood *weighting* and the `ChangeRelation` write are Lua.

**Leaves (read).**
- `FUN_0059f470` (per-key emit, 130 B): resolves the buffer's write cursor (`param_1+8`), writes the
  key **name** (`FUN_0085d9f0`) then two words `{*param_3 (score), param_3[1] (id)}` each with
  Lua-value **type-tag 3**, bumping the cursor by 8 twice; only caller is `FUN_005e0720` (7×). This
  is a generic name→(float,int) table-append, reused as the faction-score emitter.
- `FUN_0059dbe0` (post, 15 B): the generic "dispatch the built message" primitive
  (`if(*ESI>0) return FUN_0056f256(); else {*ESI=-2; return 1;}`) with 30+ callers across the sim —
  **not** faction-specific; it is the transport, so this is the point where the infraction report
  leaves native code for the Lua/event side.
- `thunk_FUN_024e9930` (accumulator getter): forwards through `FUN_024e9930` →
  `thunk_FUN_02a30028(&PTR_DAT_024e993a)` = the SecuROM VM dispatcher. **This is VM residue read live
  in the unpacked image** — its return is the 7×{id,score} array walked above; not a wall.

**Input side — `Ai.AddInfraction`.** The accumulator is *filled* by the Lua cfunc
`Ai.AddInfraction(uChar, uFaction, nAmount)` (seen live in `mrxtaskobjectiveverify.lua`:
`Ai.AddInfraction(Player.GetPrimaryCharacter(), uFaction, 5)` on a subdue). Hostile acts routed
through the combat/destruction/hijack/trespass paths call it (weapons map §5.2: the damage event
"terminates in this bridge"); its native body is binding-table-only (recover with the `Ai.*` walk).

---

## 3. The relation matrix + `Ai.Get/SetRelation` (M/L — Lua-anchored)

The **per-faction relation matrix** is a native table keyed by faction GUID, read/written by two Lua
cfuncs; all attitude *interpretation* is Lua. From `mrxfactionmanager.lua`:

```lua
function GetRelation(subj, obj)  return Ai.GetRelation(_tFactions[subj].uGuid, _tFactions[obj].uGuid) end
function SetRelation(subj, obj, nRelation, bInit)
   Ai.SetRelation(_tFactions[subj].uGuid, _tFactions[obj].uGuid, nRelation)   -- [-100,100]
   ... Hud.FactionDisplay:SetValue{ nValue = ConvertRelationToMeterValue(...) }   -- [0,100]
   if attitudeLevel changed then Event.Post("Attitude", {subj,obj,oldLabel,newLabel}) end
end
```

- **GUID resolution.** `tFactionData.uGuid = Pg.GetGuidByName(sFactionTemplate)` at `Init` (templates
  `Allied`/`China`/`OC`/`Guerilla`/`Pirate`/`VZ`/`PMC`/`Civ`). The Xbox `GetFactionGuid` (rdata
  `0x0024e60`) + its assert `Warning: GetFactionGuid(0x%0x) = 0` is the native name→GUID path behind
  this; the matrix is indexed by the resolved GUID pair.
- **`Ai.GetRelation`/`Ai.SetRelation`/`Ai.AddInfraction` cfunc VAs — RESOLVED 2026-07-26.** These
  were listed as binding-table-only with the VAs deliberately unasserted. The `luaL_Reg` walk pins
  all of them; no forcing script was needed. **H** — each row is a literal
  `{const char* name, lua_CFunction fn}` pair and each body opens with the standard cfunc prologue
  (`mov ebx, [esp+X]` = `lua_State*`):

  | cfunc | name string | `luaL_Reg` row | body | in Ghidra export? |
  |---|---|---|---|---|
  | `Ai.GetRelation` | `0x00BB471C` | `0x00B9AB00` | **`0x005AACE0`** | yes (`FUN_005aace0`, 226 B) |
  | `Ai.SetRelation` | `0x00BB4710` | `0x00B9AB08` | **`0x005AADD0`** | yes (`FUN_005aadd0`, 275 B) |
  | `Ai.GetFactionGuid` | `0x00BB46F0` | `0x00B9AB18` | **`0x005AB010`** | **no** — disassembles fine |
  | `Ai.AddInfraction` | `0x00BB46E0` | `0x00B9AB20` | **`0x005AB0F0`** | **no** — disassembles fine |
  | `ApplyCachedFactionRelations` | `0x00BB7C60` | `0x00B99AA0` | **`0x005C9210`** | **no** — disassembles fine |

  Three of the five are absent from the Ghidra export and are nonetheless ordinary `.text`
  (`0x005AB0F0` = `83 ec 0c f3 0f 10 05 64 b6 b9 00 …`). That is the whole "binding-only" phenomenon:
  no static caller for Ghidra to walk from. See `ghidra_knowledge_inventory.md` Part F.4.

  Two disambiguations worth recording:
  - **`SetRelation` is registered twice** under different tables — `0x00B987C8 → 0x005F74E0` is
    `ObjectFilter.SetRelation`, `0x00B9AB08 → 0x005AADD0` is `Ai.SetRelation`. A name-only search
    conflates them.
  - The bindings-audit guess that the cluster sits "near `0x007B98EC`" was **wrong** — that region
    holds `Report.*`. The Faction/Pursuit rows are at `0x00B9AB00…0x00B9AB20`.

  Reproduce: find the name string's VA in the image, search for `struct.pack('<I', that_va)` in
  `.rdata`, and read the dword after each match.
- **`ApplyCachedFactionRelations`** (Xbox rdata `0x0029204`) is the "re-apply a saved/replicated
  relation set" entry — the native counterpart of Lua `LoadSingleton`/`NetInitializeClientFactionRelations`
  (which re-drive `SetRelation` for every faction pair on load / client-join). PC body unlocated.
- **Comparison predicates** `SameFaction`/`SingleFaction`/`BanFaction` (Xbox names only) are the
  friend/foe + faction-restrict queries the AI/pursuit side uses; PC bodies unlocated.

**Attitude / price / mood DATA reference** (from `mrxfactionmanager.lua`, the authoritative policy —
this is the reimpl spec):

| Concept | Value | Ref |
|---|---|---|
| Relation range | `[-100, 100]` (`_knRelationMin/Max`) | `:11` |
| Meter range | `[0, 100]` (`_knAttitudeMeterMin/Max`); `meter = 100·(rel+100)/200` | `:9`, `ConvertRelationToMeterValue :632` |
| **Hostile** | rel `[-100, -33)` → **no buy** (`nPrices=nil`), RGB 255/0/0 | `:20` |
| **Neutral** | rel `[-33, 33)` → price **1.5×**, RGB 200/200/200 | `:35` |
| **Friendly** | rel `[33, 100]` → price **1.0×**, RGB 0/127/255 | `:50` |
| Mood weights | DamagePerson×3, DestroyPerson×50, DamageObject×1, DestroyObject×25, Trespassing×20, Hijack×10, +SpecialEvent[1]×[2]; clamp ≥ −60 | `:1212-1219` |
| Civilian-casualty penalty | starts `−5000`; doubles every 20 kills; floor `−1,000,000`; `Event.Post("CollateralDamage")` + `MrxPmc.AddCashQty` | `:815-823` |
| Faction abbrevs → templates | All=Allied, Chi=China, Civ=Civ, Gur=Guerilla, Oil=OC, Pir=Pirate, Pmc=PMC, Vza=VZ | `_tFactions :66` |
| Initial relations | Pir=median(Neutral)=0; Gur/Oil=median(Friendly); All=`GetRelation(Oil,Pmc)`; Chi=`GetRelation(Gur,Pmc)`; self-rel = +100 | `:73,:119,:170,:218,:266` |
| Mutable-attitude gate | only `bDynamic` factions (All/Chi/Gur/Oil/Pir) get a meter + can change vs Pmc; Civ/Pmc/Vza fixed | `CanAttitudeBeMutable :512` |
| Pursuit level dwell times | `Pg.SetPursuitLevelTimes(120, 300)` | `:367` |

`GetPriceScale(subj,obj)` returns the current level's `nPrices` — shops multiply by it. `TestAttitude`
/`GetBribableFactions` gate story + support unlocks on the same levels.

---

## 4. Faction ECS descriptors (H — married on both builds)

Faction state *on an entity* is three single-field components + one runtime blob. Each is registered
by the standard **two-role pair** (descriptor **registrar** fills the global descriptor + calls the
shared `FUN_0064a770`; **consumer/schema** deserializes a record into the pool) — the same split the
streaming map documented for TerrainObject (`FUN_00644260` registrar vs `FUN_0063d590` consumer). The
`game-systems.md` PC-xref names the registrars; `ecs-07` names the schema/consumers.

**Registrar shape read first-hand — `FUN_00641340` (FactionMarker):**
```c
PTR_PTR_017bd588 = &PTR_CopyFromStream_00bbf928;   // WAD stream-deserialize vtable
DAT_017bd5ac = 4;  _DAT_017bd5ae = 8;              // stride 4 (1 int32), type tag 8
DAT_017bd5b4 = 0x9e3779b9;  DAT_017bd5b0 = 0x100;  // golden-ratio seed, pool 0x100
PTR_PTR_017bd5a0 = &PTR_LAB_00bc5ff8;              // shared component method vtable
FUN_0064a770();                                    // shared registrar
PTR_s_FactionMarker_017bd5c4 = s_FactionMarker_00bc5078;   // names it
```
**Consumer shape read first-hand — `FUN_0065c0f0` (FactionMarker deserialize):** resolves via the
component-table vcall, `FUN_0064a600(param_1,&rec)` commits into pool `DAT_017bd5a4`, and on pool
growth spatially registers via `FUN_00665590(param_1, DAT_017bd58c)` — byte-for-byte the shared ECS
consumer template.

| Class | PC hash | PC registrar | PC schema/consumer | Stride | Payload | Xbox pool |
|---|---|---|---|---|---|---|
| **FactionMarker** | `0x9b98cb09` | `FUN_00641340` | `FUN_0065c0f0` | 4 | 1 int32 = **faction id** on the entity | `FactionMarker 1280` |
| **FactionValue** | `0x8bfc69d6` | `FUN_00641830` | `FUN_0065c7d0` | 4 | 1 float = per-entity faction **scalar** (rep/influence/contribution) | `FactionValue 64 64` |
| **FactionZone** | `0x67267cc1` | `FUN_006414b0` | `FUN_0065c490` | 4 | 1 int32 = **faction-owned zone id** | `FactionZone 16 16` |
| **RtFactionZone** | `0xa67114c7` | (base `0x017c05f8`) | raw-copy 0x1c | 0x1c | 28-B runtime faction-zone state (live counterpart of FactionZone) | `RtFactionZone 16 16` |

`game-systems.md` confirms the Xbox side: `FactionValue`/`FactionZone` show in the component-pool
dump and resolve to the byte-identical 159-B registrar template (`CashValue @829f05b0`,
`FactionValue @829f44f0`, `RuntimeObjectiveMarker @829f2c30` cited), so these are **confirmed ECS
components on both builds**. FactionZone is the world-authored trespass trigger the Lua
`FactionZone.Init{TresspasserCallback=…}` + `HandleTressPasser` consume (feeding the `Trespassing`
infraction key of §2).

---

## 5. Pursuit / "heat" (L — Lua-anchored, cfunc bodies binding-only)

Pursuit is a native singleton with a `Level` field (clamped `0..3`) and per-level dwell timers,
driven entirely from `mrxfactionmanager.lua` cfuncs. Xbox marks `RestrictPursuitFaction` (rdata
`0x002a534`) as the "heat" hook; the debug menu exposes `StartPursuit GUR/OC/VZ` + `++PursuitLevel`.

**Lua cfunc surface (native bodies binding-table-only, VAs unlocated):**

| Lua call | Role | Site |
|---|---|---|
| `Pg.SetPursuitLevelTimes(120, 300)` | per-level dwell seconds (L1=120, L2=300) | `Setup :367` |
| `Pg.GetPursuitState()` → `{Level=n,…}` | read current pursuit | `IncrementPursuit :1354` |
| `Pg.SetPursuit(uFaction, nLevel, bNet)` | set level for a faction | `:1358` |
| `Pg.SetPursuitSeconds(uFaction, 5, bNet)` | (re)arm the pursuit timer | `:1359` |
| `Pg.LockPursuit(uGuid, nLevel)` / `Pg.ClearPursuitLock(bNet)` | pin/unpin level | `LockPursuit :1368` / `:1378` |
| `Pg.SetCustomPursuit(uFaction, nDur, tSettings)` / `Pg.ClearCustomPursuit()` | scripted pursuit override | `:1382` / `:1392` |
| `Net.SetPursuitReportingState(uGuid, state, sAbbrev)` | replicate reporter state 0/1/2/3 | `HandleReporter* / FinishedReporting` |

**Escalation logic (Lua):** when `GetRelation(faction,"Pmc") ≤ -100`, `FinishedReporting` calls
`IncrementPursuit` → `Level = min(Level+1, 3)` → `SetPursuit` + `SetPursuitSeconds(5)` +
`Hud.FactionDisplay:StartPursuit{nDuration=5}` + a pursuit VO cue. The native side owns the countdown
(dwell from `SetPursuitLevelTimes`) and the level state; recover the VAs via the `Pg.*` binding-table
walk (same forcing script). `Report.Init`/`Report.SetDelay`/`Report.GetInfractions`/`Report.Completed`
(the reporter FSM feeding §2) live in the same Faction/Pursuit binding cluster near `0x007B98EC`.

---

## 6. Faction markers / HUD meter (L native toggles / H Lua)

Two distinct HUD surfaces:

1. **World-space unit markers** — Xbox `EnableFactionMarkers` / `SetFactionMarkerSize` /
   `SetFactionMarkerVisibleDistance` (rdata `0x00275dc`–`0x002760c`): the floating faction blips over
   units. Native cfunc bodies binding-table-only (VAs unlocated). The Lua uses `Marker.AddBlip` /
   `Marker.Pulse` (reporter blips) + `Hud.Radar:AddObjective`/`AnimateObjectiveSonar` for the
   reporter minimap ping (`mrxfactionmanager.lua` `HandleReporter0`).
2. **The faction mood meter** — Scaleform widget `mrxguihudfactiongauge.lua` (luacd 05 §2.9), driven
   through `Hud.FactionDisplay:` `ConfigureThresholds` / `AddMeter` / `SetValue` / `ChangeValue` /
   `StartTimer` / `StartPursuit` / `HideMeter`. Levels `_tLevels = {0,25,50,75}`, pursuit label
   `_ksPursuit="[0x1cab5133]"`, per-faction icon from `sMarkerTexture` (`HUD_faction_*`). The net path
   `NetClientFactionHideMeter` is the replicated hide. Cross-ref the Scaleform class map
   ([[scaleform-gfx-2048-lib-map]]) — this is a GFx movie, not native draw. The PDA mirror is
   `Pda.Database:SetFactionAttitude`.

Relation → meter conversion is Lua (`ConvertRelationToMeterValue`, §3 table). The threshold labels are
localized `[Generic.Attitudes.<Hostile|Neutral|Friendly>]`.

---

## 7. Faction-locked dynamic music (H two VAs / L rest)

Faction attitude locks the dynamic-music state. Xbox exposes `IsFactionLockedMusic` /
`LockFactionMusic` / `SetFactionMusic` / `AddFactionMusic` (rdata `0x002c07c`–`0x002c0b8`) +
`ActivateFactionRegionMusic` / `SetRootFactionRegionMusic`. Two VAs are **already pinned** by the
streaming map §4 (recovered via the same cfunc walk):

- `ActivateFactionRegionMusic` = **`0x005E1CC0`** (entry `0xB98DA0`)
- `SetRootFactionRegionMusic` = **`0x005E1C40`** (entry `0xB98D90`)
- (adjacent, bindings-audit) `SetDynamicMusic` = `0x005E16E0`, `TransitionMusic` = `0x005E1600`.

The `RuntimeMusicRegion` descriptor is `FUN_00644fe0` (streaming map §4); the music engine itself is
Lua `MrxMusic` (`Sound.AddMusicState`/`AddMusicTransition`/`TransitionMusic`, cue registry
`mu_fac_<faction>_<role>_NN`, faction set `an/oc/gr/ch/pmc`). `LockFactionMusic`/`SetFactionMusic`/
`AddFactionMusic` native VAs are binding-table-only (recover via walk). Cross-ref the audio corpus
(luacd 08) — this map only records the faction→music seam; the music FSM is documented there.

---

## 8. Net replication (open — names on both builds, PC bodies unlocated)

Faction relations, values, pursuit, and meter visibility all replicate. Xbox names (game-systems.md
§Factions net list + networking.md §G):

| Xbox symbol | Role | PC |
|---|---|---|
| `xPgSysNetFactionRelations` (rdata `0x00444f3`) | the faction-relation **replicator system** | unlocated |
| `NetInitializeClientFactionRelations` | push the full relation matrix to a joining client | Lua fn of same name re-drives `SetRelation` per pair (`:456`); native cfunc unlocated |
| `NetClientFactionSetValue` | replicate a single relation/value change | unlocated |
| `NetClientFactionStartPursuit` | replicate pursuit start | pairs with `Pg.SetPursuit(…,true)` net flag |
| `NetClientFactionHideMeter` | replicate meter hide | pairs with `Hud.FactionDisplay:HideMeter` |
| `HostileAware` / `HostileObservers` (networking.md §G; log `HostileAware: %d`) | replicated AI friend/foe awareness (adjacent) | unlocated |

The Lua replication rides `Net.SendCustomEvent("MrxFactionManager", NETEVENT_{SETMUTABLE|CIVKILLINIT|
CIVKILL}, …)` on the `"MrxFactionManager"` channel + `Net.SetPursuitReportingState`, re-applied by
`NetEventCallback` (faction recovered from `String.GetHash` of the abbrev). The generic bus these ride
is the event system (Keystone-B): `Event.Post` = `FUN_005f6a90` (name-hash `FUN_00824270`), see
[`event_bus_code_map.md`](event_bus_code_map.md). Binding the PC `Net*Faction*` cfunc bodies is
confirm-live (§9).

---

## 9. Confirm-live inventory (x32dbg, read-only while PAUSED — [[x32dbg-mcp-no-resume]])

**Mood bridge**
1. bp `FUN_005e0720` head during a report; dump the `thunk_FUN_024e9930` accumulator return (the
   7×{id,score} array) and confirm the even/odd = {id, score} pairing and which id (faction GUID vs
   count) sits at each even slot. Read the VM getter live (`thunk_FUN_02a30028` unpacked).
2. bp `Ai.AddInfraction` (find its VA by the `Ai.*` binding walk first) during a hostile act; confirm
   it writes the accumulator slot matching the act type (e.g. Hijack → `puVar2[8/9]`).

**Relation matrix + cfuncs**
3. ~~Recover the binding-only bodies … with a forcing script over the cluster near `0x007B98EC`~~
   — **done statically 2026-07-26, see §2**: `GetRelation 0x005AACE0`, `SetRelation 0x005AADD0`,
   `GetFactionGuid 0x005AB010`, `AddInfraction 0x005AB0F0`,
   `ApplyCachedFactionRelations 0x005C9210`. What remains live-only is the second half: bp
   `Ai.SetRelation 0x005AADD0` and read the **matrix base + index formula** (GUID pair → slot).

**Pursuit**
4. Break the `Modify Attitude` / `StartPursuit GUR` debug menu items; recover `Pg.SetPursuit`/
   `GetPursuitState`/`SetPursuitLevelTimes`/`LockPursuit` VAs and read the pursuit-state singleton
   layout (Level field + the two dwell timers 120/300).

**Markers / HUD / music**
5. Recover `EnableFactionMarkers`/`SetFactionMarkerSize`/`SetFactionMarkerVisibleDistance` VAs; bp to
   find the world-marker draw list + visible-distance cull.
6. `LockFactionMusic`/`SetFactionMusic`/`AddFactionMusic` VAs via the `Sound.*` binding walk; confirm
   they set the same music-state lock `ActivateFactionRegionMusic 0x5E1CC0` reads.

**Net**
7. bp on the `Net.SendCustomEvent("MrxFactionManager",…)` native path + `xPgSysNetFactionRelations`
   to bind `NetClientFactionSetValue`/`StartPursuit`/`HideMeter` PC VAs during a co-op join.

---

## 10. Reconciliation with `mercs2_engine` (no scoreboard row — this map = the reimpl target)

**Status: ❌ — there is no faction/reputation layer in the engine today.** Faction is not one
scoreboard row; it is a cross-cutting system that touches **row 23 (AI)**, **row 24 (population
spawn-lists)**, **row 27 (HUD)**, and **row 21 (music)**. This map is the faithful-implementation
reference. Direct port targets, in build order:

1. **Relation matrix + accessors** — an `N×N` per-faction relation table (`[-100,100]`) keyed by
   faction GUID, with `get_relation(a,b)` / `set_relation(a,b,r)` and the attitude-level classifier
   (Hostile/Neutral/Friendly from the §3 ranges) + meter conversion. This is the spine everything
   below reads.
2. **Infraction accumulator + mood bridge** — a per-faction 7-key `{DamagePerson, DestroyPerson,
   DamageObject, DestroyObject, Hijack, Trespassing, SpecialEvent}` accumulator that hostile acts add
   to (`add_infraction`, mirror `Ai.AddInfraction`), plus the report-tick that weights it
   (`×3/×50/×1/×25/×10/×20/+SpecialEvent`, clamp ≥ −60) into a `change_relation` — a **direct port of
   the §2 serializer + `mrxfactionmanager.lua:1212` weights** (the PC weighting is Lua, so the engine
   implements the policy, not a native body). The civilian-casualty penalty (`−5000` doubling / floor
   `−1M`) rides the same path.
3. **Faction\* ECS components** — `FactionMarker` (int32 id), `FactionValue` (float scalar),
   `FactionZone` (int32 zone id) + `RtFactionZone` runtime state, loaded from the WAD like every other
   component (strides in §4), so world-authored faction ownership + trespass zones work.
4. **Pursuit state** — a per-faction `Level 0..3` with the `SetPursuitLevelTimes(120,300)` dwell
   countdown + `IncrementPursuit` escalation on `relation ≤ -100` (§5).
5. **HUD faction meter + world markers** — feed a `FactionDisplay`-equivalent (`SetValue` 0..100,
   `StartPursuit`, thresholds `{0,25,50,75}`) and the world-space unit blips
   (`EnableFactionMarkers`/size/visible-distance), consuming the relation table from (1).
6. **Faction→music seam** — on attitude/region change, lock the dynamic-music state
   (`LockFactionMusic`/`ActivateFactionRegionMusic`) — the faithful analog of the audio map's music
   FSM.
7. **Do NOT** re-derive the attitude/price/mood policy — it is fully specified in §3 (from the Lua)
   and is the authoritative reimpl data; the native side is only the accumulator, the matrix, and the
   ECS/HUD/music toggles.

## 11. Provenance

- PC decomp: `output/_ghidra/mercs2_unpacked.exe_decomp.txt` (SecuROM-unpacked, base 0x400000).
  Bodies read first-hand and cited as `ghidra/FUN_xxxx`: `FUN_005e0720` (mood bridge), `FUN_0059f470`
  (per-key emit), `FUN_0059dbe0` (post primitive), `FUN_024e9930` (VM getter thunk), `FUN_00641340`
  (FactionMarker registrar), `FUN_0065c0f0` (FactionMarker consumer).
- Xbox ground truth: `docs/mercs2-pdb-analysis/game-systems.md` §"Factions / reputation" (17-symbol
  rdata inventory + `Net*Faction*` + pool sizes `FactionMarker 1280`/`FactionValue 64 64`/
  `FactionZone 16 16`/`RtFactionZone 16 16`), `docs/mercs2-pdb-analysis/networking.md` §G
  (`HostileAware`/`HostileObservers`).
- Data oracle: `docs/mercs2-ecs/07_gameplay_state_health_mission.md` §"Faction\* family" (PC hashes
  `0x9b98cb09`/`0x8bfc69d6`/`0x67267cc1`/`0xa67114c7` + schemas `FUN_0065c0f0`/`FUN_0065c7d0`/
  `FUN_0065c490`).
- Lua policy: `docs/mercs2-luacd/src/resident/mrxfactionmanager.lua` (attitude ranges, mood weights,
  pursuit, reporter FSM, net replication, civilian penalty) + `docs/mercs2-luacd/07_player_core_cheats_managers.md`
  §"Faction attitudes & price scaling" + `05_gui_hud_shell.md` §2.9 (faction gauge) +
  `08_audio_presentation.md` (MrxMusic).
- Binding + cross-ref: `docs/lua_engine_bindings_audit.md` (Faction/Pursuit cluster `~0x007B98EC`;
  music VAs), `docs/reverse_engineer/event_bus_code_map.md` (`Event.Post FUN_005f6a90`),
  `docs/reverse_engineer/world_streaming_code_map.md` §4 (`ActivateFactionRegionMusic 0x5E1CC0` /
  `SetRootFactionRegionMusic 0x5E1C40` / `RuntimeMusicRegion FUN_00644fe0`),
  `docs/reverse_engineer/weapons_combat_code_map.md` §5.2 (the mood-bridge origin).
- Confidence stated per row; the mood bridge (`FUN_005e0720`) + Faction\* descriptors are H, the
  `Ai.*`/`Pg.*Pursuit*`/marker/music/net cfunc bodies are binding-table-only VAs (recover via the
  documented forcing-script walk, §9), and the `Net*Faction*` + `ApplyCachedFactionRelations` /
  comparison-predicate PC bodies are the honest open items.
