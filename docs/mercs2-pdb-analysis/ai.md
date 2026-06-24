# AI

Scope: enemy/NPC artificial intelligence — perception, behavior/goal planning, squads, cover, threat/alert, aiming, pedestrians, and AI-driven vehicle/helicopter control.

Provenance: symbol/string evidence recovered from the Xbox 360 devkit "Profile" build `Mercs2_Xenon_P.exe` (Mercenaries 2: World in Flames, Jul 11 2008 preview, PowerPC). Build tree on the dev machine was `d:\projects\ReleaseLine\Mercs2\`. The engine is Pandemic's in-house "Pangea" (`Pg*`). This is recovered string/symbol evidence, not a real `.pdb`.

## Overview

The AI subsystem lives in Pangea's `PgAi*` source family (see Source files). The recovered symbols and strings describe an agent architecture built around:

- A **perception/stimulus** layer (`PgAiPercept.cpp`, "Stimuli", "Memes", "Percept", "Perception") that feeds a memory/threat model.
- A **context / behavior / goal-and-role planning** layer (`PgAiContext.cpp`, "Behaviors", "Plan", "Goal", "Role", "PathFind", "Failed planning!") that selects actions.
- A **cover system** (`PgAiCoverManager.cpp`, `Cover*` symbols, "MCoverFinder", cover-state strings).
- A scripting/command **interface** (`PgAiInterface.cpp`) exposing goals/actions to Lua (`Ai.Goal({ ... })`, action verbs).
- AI-driven **vehicle/helicopter** actuation (`PgAiActHeli.cpp`, "DriveOff!", "Unable To Exit!", heli/boat/car control verbs).
- Ambient **pedestrian/living-world** agents (`AIPedestrian::Messages`, sidewalk/pedestrian strings).

Many of the cited symbols are `.rdata` string literals used as debug-menu labels, enum names, tunable/parameter keys, and component/class type names rather than code labels — that is the nature of this evidence, given their `.rdata` section and surrounding debug-menu text.

## Source files

From `mercs2_xenon_p.source_paths.txt` (verbatim), the files belonging to this system:

```
d:\projects\ReleaseLine\Mercs2\Pangea\Src\PgAiActHeli.cpp
d:\projects\ReleaseLine\Mercs2\Pangea\Src\PgAiContext.cpp
d:\projects\ReleaseLine\Mercs2\Pangea\Src\PgAiCoverManager.cpp
d:\projects\ReleaseLine\Mercs2\Pangea\Src\PgAiInterface.cpp
d:\projects\ReleaseLine\Mercs2\Pangea\Src\PgAiPercept.cpp
```

Assert/source-line references confirming these files are live in the binary (from the strings dump), e.g.:
`PgAiActHeli.cpp(1079)`, `PgAiActHeli.cpp(1192)`, `PgAiContext.cpp(6362/6374/6551/6562)`, `PgAiCoverManager.cpp(808/809/956/957/1083/1084/1194/1195)`, `PgAiInterface.cpp(1910/1920)`, `PgAiPercept.cpp(635/648)`.

## Key classes

No `PgAi*` / behavior / squad / cover RTTI class names appear in `mercs2_xenon_p.rtti_classes.txt` — that file is dominated by Havok (`hk*`/`hkp*`) and XML-parser classes. The only AI-related demangle-style token in the symbol evidence is:

- `AIPedestrian::Messages` (offset `0x00249f4`, `.rdata`) — a C++ scoped name string for an `AIPedestrian` class's message/enum table. The class itself is not in the RTTI list, so this string is the only evidence for it.

So: no demangled RTTI classes can be claimed for this system beyond `AIPedestrian` (string-only).

## Symbols by area

All offsets and section names below are copy-exact from `inventory/ai.txt`.

### Behavior / skill / feature flags (the `Ai*` component family)

| Offset | Section | Symbol |
|---|---|---|
| 0x0031380 | .rdata | AiBehavior |
| 0x0031194 | .rdata | AiSkill |
| 0x0031dbc | .rdata | AiUnUsable |
| 0x003119c | .rdata | AiPatrol |
| 0x003ac2c | .rdata | AiPatrolModeEnum |
| 0x003ac10 | .rdata | AiPriorityEnum |
| 0x00324bc | .rdata | AiHintNode |
| 0x003b278 | .rdata | AiHintEnum |
| 0x00324ac | .rdata | CoverHintOffset |

These appear as named component/feature tags in a budget table (strings dump shows e.g. ` AiBehavior 512 `, ` AiPatrol 768 `, ` AiSkill 256 128 `, ` AiUnUsable 8 8 `, ` AiHintNode 128 64 `, ` CoverHintOffset 1536 256 `, plus a top-level ` Ai 1024 ` entry). The trailing numbers are per-type instance budgets/counts. `AiPriorityEnum`/`AiPatrolModeEnum`/`AiHintEnum` are enum type names (a "Toggle AiPriority" debug menu item exists). `AiUnUsable` pairs with the "UnUse" / failure strings ("targetdead", "cantenter", "targettoofar", "targethostile").

### Perception / stimulus / threat

| Offset | Section | Symbol |
|---|---|---|
| 0x002311c | .rdata | AimedScan |
| 0x003e634 | .rdata | ThreatRange |

`PgAiPercept.cpp` is the source. Supporting strings: "Percept", "Perception", "Stimuli: %d", "Memes processed: %d", "Updates: %d", "Type: %d, Threat: %f, Power: %f, Count: %d, Value: %f". Debug-menu toggles: "Percept Raycasts", "Show Percept", "Show Perception", "Show Threat", "Stimulus Counters/Locator/Msgs/Show Stimulus", "ShoutEnemy Propagation". `AimedScan` / "aimedscan" is a perception action verb. Disguise/awareness strings ("Breaking Disguise", "Investigating Disguise", "Show Player Awareness", "Toggle Forced PlayerPercept") indicate a player-detectability model.

### Context / behavior planning (goals, roles, plans)

`PgAiContext.cpp` is the source (the largest, asserts near line 6300–6562). No dedicated inventory symbols, but the strings dump gives the action/goal verb set used by the planner: "moveto", "takecover", "attack", "patrol", "guard", "investigate", "flee_from_pos", "follow", "pathmove", "pilot", "go_home", "deliver", "pickup", "converse", "drive", "stand", "observe", "react", "report", "change_feeling", "triggeralarm", "walkthesidewalks". Combat/turret/weapon state strings live here too: "Suppressing"/"Not Suppressing", "Aggro Delayed: %.1f", "Bursting", "Charge", "Lockon: No Lock", "TUR_*" (turret states), "WPN_*" (weapon states), "Weapon: %s has no WeaponHint". Debug labels: "- Behaviors", "- Plan", "- Goal", "- Role", "- Context", "- Curiosity", "- Memory", "Failed planning!", "PathFind".

### Cover

| Offset | Section | Symbol |
|---|---|---|
| 0x0013aac | .rdata | CoverEvent |
| 0x003b2b8 | .rdata | CoverTypeEnum |
| 0x003b2d8 | .rdata | CoverRatingEnum |
| 0x003cdd8 | .rdata | CoverRange |
| 0x003ce08 | .rdata | CoverPosition |
| 0x003ce18 | .rdata | CoverFireTimer |
| 0x00324ac | .rdata | CoverHintOffset |
| 0x00324bc | .rdata | AiHintNode |

`PgAiCoverManager.cpp` is the source. The class/finder string "MCoverFinder" and a rich cover-state vocabulary appear in the dump: "TakeCoverFromTarget", "GoingToCover", "AtCover", "LowCover", "ShootingFromCover", "StepInFromCover", "StepOutFromCover", "DiveFromCover", "LostCover", "Prone", "Crouch", plus cover-slot states "kKneelAtCover", "kPopup", "kShoot", "kWaitForPopup", and rating states "BLOCKED"/"ACTIVE"/"INACTIVE". `CoverAnimEnum`, `CoverAnimation`, `CoverFireTimer`, "Coverage", and the cover-query debug line "- CoverQuery: Last / Worst -" reinforce this. Debug toggles: "Toggle CoverFinder", "Show CoverHint", "Show AI HintNodes".

### Squad

| Offset | Section | Symbol |
|---|---|---|
| 0x00264b0 | .rdata | SquadGuid |
| 0x003d1c0 | .rdata | SquadName |
| 0x003ead4 | .rdata | SquadCap |
| 0x00323d0 | .rdata | SquadUnitLink |
| 0x00323e0 | .rdata | SquadSource |

A squad/group layer: ` Squad 16 16 `, ` SquadSource 16 16 `, ` SquadUnitLink 16 16 ` appear as budgeted component types. `SquadGuid`/`SquadName`/`SquadCap` are squad identity/capacity fields. "Show SquadName" is a debug toggle and `SquadName` appears in the per-AI state line `%sState: %8s Grp: %9s   Type: %8s   Squad: '%s' 0x%08x`.

### Aiming / aim-assist

| Offset | Section | Symbol |
|---|---|---|
| 0x0023104 | .rdata | AimEnable |
| 0x0023110 | .rdata | AimDisable |
| 0x002311c | .rdata | AimedScan |
| 0x003eea0 | .rdata | AimAssist |
| 0x003eeac | .rdata | AimDisruptScale |
| 0x00b86e4 | .rdata | AimMovementNodes |
| 0x00b86f8 | .rdata | AimReferenceNodes |
| 0x00b8720 | .rdata | AimNodes_SweepLow |
| 0x00b8734 | .rdata | AimNodes_SweepMid |
| 0x00b8748 | .rdata | AimNodes_SweepHigh |
| 0x00b875c | .rdata | AimNodes_StaticSweep |
| 0x00b8774 | .rdata | AimNodes |

`AimEnable`/`AimDisable`/`AimedScan` (and the "AimEnable(look)" / "TurretAim" / "TurretPoint" / "TurretEnable" action verbs) are AI aim controls. `AimAssist` / `AimDisruptScale` are tunables (format strings "AimAssist: %.2f", "AimAssist Category: %s", "AimDisruptScale     (modifer)"). The `AimNodes_*` / `AimMovementNodes` / `AimReferenceNodes` group (offsets clustered at `0x00b86e4`–`0x00b8774`) name aim-pose node sets used to drive aim sweeps ("LandMovementNode AimUpdate"). Note: the extensive `AimPitch*`/`AimYaw*`/`AimCam*`/`AimTgt*` parameter strings are player aim-camera tunables, not in this inventory; treat them as adjacent, not AI-owned.

### Pedestrians / living world

| Offset | Section | Symbol |
|---|---|---|
| 0x00249f4 | .rdata | AIPedestrian::Messages |
| 0x0011c3c | .rdata | AiWalkTheSideWalks |
| 0x0031404 | .rdata | AiWaterZone |
| 0x003b268 | .rdata | AiWaterZoneEnum |
| 0x0011c30 | .rdata | AiDropZone |
| 0x0011c20 | .rdata | AiMouseDebug |

`AIPedestrian::Messages` plus pedestrian message strings "(JustWalk", "(StopAndChat", "(StopAndIdle", "(WatchPanic", "(DoIt", "8WalkTheSidewalks", "PathFollower", "SetSidewalkSpawning" describe ambient crowd AI. `AiWaterZone`/`AiWaterZoneEnum` and `AiDropZone` (heli drop zones; "TestDropZone", "HeliDropZoneInfo", "Toggle DropZone Debug") are spatial AI zones. `AiMouseDebug` / `AiWalkTheSideWalks` are debug toggles (they appear in a toggle list alongside "AiDropZone").

### AI-driven vehicles / helicopter

| Offset | Section | Symbol |
|---|---|---|
| 0x00311a8 | .rdata | AiHelicopter |
| 0x00311b8 | .rdata | AiDriving |
| 0x003af24 | .rdata | AirVehicle |
| 0x003d5bc | .rdata | AirCtrlSteering |
| 0x002d7d8 | .rdata | AirstrikeDeliveryReady |

`PgAiActHeli.cpp` is the source. ` AiHelicopter 256 128 ` and ` AiDriving 256 ` are budgeted AI-actuation components. The actuation verb set (from the dump): "HeliElevate", "HeliTurn", "HeliStrafe", "HeliAccel", "HeliClearControl", "HeliTakeoff"/"HeliLand", "CarAccelerate", "CarBrake", "CarHandbrake", "CarTurn", "BoatTurn", "BoatAccelerate", plus failure strings "Unable To Exit!", "No Hardpoint Transform: %s(%X)", "DriveOff!", "Panic!". (`AirVehicle`/`AirCtrlSteering`/`AirstrikeDeliveryReady` are air-vehicle/airstrike tokens that fall in this inventory; their exact AI ownership vs. vehicle subsystem is unclear from symbols alone.)

## Notable strings

Verbatim from `mercs2_xenon_p.pe_full_strings.txt`:

- Planner failure / pathing: `Failed planning!`, `PathFind`, `Can't Engage`, `Retreat Reponse` (sic).
- Per-AI debug state line: `%sState: %8s Grp: %9s   Type: %8s   Squad: '%s' 0x%08x`.
- Threat/stimulus telemetry: `Type: %d, Threat: %f, Power: %f, Count: %d, Value: %f`; `Memes processed: %d`; `Stimuli: %d`; `Updates: %d`.
- Cover query header: `- CoverQuery: Last / Worst -`.
- Weapon/turret states: `WPN_IDLE`/`WPN_AIMING`/`WPN_CHARGING`/`WPN_BURSTING`; `TUR_IDLE`/`TUR_NOWEAPON`/`TUR_TRACKING`/`TUR_TARGET_TOOFAR`/`TUR_TARGET_TOOCLOSE`/`TUR_READY_TO_FIRE`/`TUR_FIRING`/`TUR_RELOADING`/`TUR_CANTSHOOT`.
- Cover states: `GoingToCover`, `AtCover`, `LowCover`, `ShootingFromCover`, `StepInFromCover`, `StepOutFromCover`, `DiveFromCover`, `LostCover`, `TakeCoverFromTarget`, `kKneelAtCover`, `kPopup`, `kShoot`, `kWaitForPopup`.
- Suppression / aggro: `Suppressing`, `Not Suppressing`, `Aggro Delayed: %.1f`, `Anchor: %.1f`, `Weapon: %s has no WeaponHint`.
- Goal/action verbs (planner vocabulary): `moveto`, `takecover`, `attack`, `patrol`, `guard`, `investigate`, `flee_from_pos`, `follow`, `pathmove`, `pilot`, `go_home`, `deliver`, `pickup`, `converse`, `drive`, `stand`, `observe`, `react`, `report`, `triggeralarm`, `change_feeling`, `walkthesidewalks`, `aimedscan`, `helitakeoff`, `heliland`, `enter`, `move_within_boundary`, `aquire` (sic).
- AI behavior-restriction flags (from a flag block): `NoExitVehicle`, `NoFollow`, `NoGrenades`, `NoTurret`, `NoVehicle`, `NoCover`, `NoReport`, `NoCapture`, `NoHorn`, `NoAlarm`, `NoProne`, `NoCrouch`, `Pacifist`, `Zombie`.
- Failure/UnUse reasons: `targetdead`, `cantenter`, `targettoofar`, `targethostile`, `UnUse`.
- Pedestrian messages: `(JustWalk`, `(StopAndChat`, `(StopAndIdle`, `(WatchPanic`, `(DoIt`, `WalkTheSidewalks`, `PathFollower`.
- Infraction/relation enums (perception of player wrongdoing): `DamagePerson`, `DamageObject`, `DestroyPerson`, `DestroyObject`, `Trespassing`, `SpecialEvent`.
- Lua-facing goal help (from `PgAiInterface`): `Ai.Goal({ AIGuid=guidWithAi, Goal='goalName', ... })`, with usage text for `Follow`, `MoveTo`, `Pickup`, `Idle`, `MoveWithinBoundary`, `Attack`, `Enter`, `Exit`, `PathMove`, `HeliLand`, `HeliTakeoff`, `Guard` ("In developement." sic).
- Debug-menu AI labels: `AI Stats`, `AI Locator`, `AI Debug`, `AI Cover Flush`, `AI Take Cover`, `Show Combat State`, `Show NavPath`, `Show Memes`, `Show Curiosity`, `Show Distraction`, `Show Emotion`, `Toggle AiPriority`, `Tog MindKiller`, `Show Subject Data`.

CAUTION (verified, to avoid a wrong claim): the strings `AlertLowThreshold`, `AlertMediumThreshold`, `AlertHighThreshold`, `AlertThresholdMargin`, `AlertTime`, `ParanoiaLevel`, `NumHistoryEntries` appear inside `[x360_memory]` / `[ps3_memory]` config blocks with values like `50M`/`40M`/`30M` — these are **memory-pool** alert thresholds (megabytes), NOT AI alertness tunables. They are not part of this subsystem.

## Cross-references

- `docs/mercs2-pdb-analysis/weapons-combat.md` — turret/weapon-firing states (`TUR_*`, `WPN_*`), suppression, `WeaponHint`.
- `docs/mercs2-pdb-analysis/vehicles.md` — AI vehicle/heli/boat actuation overlaps `PgAiActHeli.cpp` (car/heli/boat control verbs).
- `docs/mercs2-pdb-analysis/animation-skeleton.md` — cover/aim pose states ("LandMovementNode AimUpdate", `AimNodes_*`, prone/crouch animation transitions).
- `docs/mercs2-pdb-analysis/pangea-engine-core.md` — `PgGameSystem`, component budgets, the per-type budget table that lists `Ai*`/`Squad*`/`Cover*`.
- `docs/mercs2-pdb-analysis/world-streaming.md` — AI hibernation / "AI Hibernated" / "AI Pedestrians" object counts tie into streaming/LOD.
- `docs/mercs2-pdb-analysis/audio-pal.md` — chatter/shout propagation ("ShoutEnemy Propagation", "Show Triggered Chatter") couples perception to VO.
- Existing project ECS docs: `docs/ecs_components.md` and `docs/mercs2-ecs/` (native component registry) — many `Ai*`/`Squad*`/`Cover*`/`Perception`/`Stimulus` names here are ECS component types.

## Evidence & confidence

- Symbol count: 44 lines in `inventory/ai.txt` (43 distinct symbols after the header-less last line). All cited symbols are in `.rdata`.
- Source files: 5 `PgAi*.cpp` files (verbatim from `source_paths.txt`), all confirmed live by embedded assert/source-line strings.
- RTTI: no `PgAi*`/behavior/squad/cover classes in `rtti_classes.txt` (Havok-dominated); the only scoped-name string is `AIPedestrian::Messages`.

Directly attested in the evidence: the `Ai*`, `Squad*`, `Cover*`, `Aim*`, `Threat*` symbols at the offsets tabled above; the five `PgAi*.cpp` source paths and their assert line numbers; and the goal/action verb set, cover/turret/weapon state strings, and behavior-restriction flags listed under Notable strings.

What is read off that evidence rather than directly proven:
- The layered architecture (perception → context/plan → cover/aim → actuation) is grouped from the source files and string vocabulary, not a single proof point.
- `AIPedestrian` is taken to be a C++ class from the `AIPedestrian::Messages` string alone (no RTTI entry).
- The trailing numbers in the budget table (` AiBehavior 512 `, etc.) read as per-type instance budgets/counts.
- Ownership of `AirVehicle`/`AirCtrlSteering`/`AirstrikeDeliveryReady`/`AiMouseDebug` is uncertain from symbols alone.
- The player-detectability/disguise model is read off the "Breaking Disguise"/"Show Player Awareness" strings.

## PC decompilation cross-reference

These map this system's Xbox `Ai*`/`Cover*` strings to functions in the PC retail decomp (`output/_ghidra/all_functions_decomp.txt`). The pairing produced **string-anchored matches only — no vtable bridge** for AI (no `PgAi*` RTTI vtables survived on either side), so confidence here is medium at best: a function is cited only where it actually references the named string in the PC build (verified by grep). Two distinct PC patterns resolved:

1. **Component-type registration functions** — one per `Ai*` component, each building a streaming/reflection descriptor (golden-ratio hash `0x9e3779b9`, default budget `0x100`, a `CopyFromStream` vtable, a shared `&PTR_FUN_00bc5ff8`, a `FUN_0064a770()` register call) and finally storing the type-name string. These correspond directly to the budgeted component types in the "Symbols by area" tables. Confidence: medium-high (each ends with its own distinctive type-name string).
2. **Schema / enum field-setup functions** — small functions that register a type's field defaults and enum columns by name (`FUN_00656720(<EnumName>, <default>)`). The `*Enum` symbols all also appear in one large master registry, `FUN_0064ac50`, which references every AI/Cover enum string and is the system-wide reflection registrar, **not** a per-enum method. Confidence: medium for the small per-type setups, low for `FUN_0064ac50` (it touches everything).

| Symbol / class | PC function | Bridge | Role |
|---|---|---|---|
| `AiSkill` | `FUN_0063f430` | string | component-type registration (descriptor setup) |
| `AiPatrol` | `FUN_0063f4e0` | string | component-type registration |
| `AiHelicopter` | `FUN_0063f590` | string | component-type registration |
| `AiDriving` | `FUN_0063f640` | string | component-type registration |
| `AiBehavior` | `FUN_00640b90` | string | component-type registration |
| `AiWaterZone` | `FUN_00641560` | string | component-type registration |
| `AiUnUsable` | `FUN_006481f0` | string | component-type registration |
| `AiPatrolModeEnum` / `AiPriorityEnum` | `FUN_0065ce20` | string | field/enum-default setup (registers both enums) |
| `CoverTypeEnum` / `CoverRatingEnum` | `FUN_0065c180` | string | cover field/enum-schema setup |
| `AiHintEnum` | `FUN_0065c400` | string | field/enum setup |
| `AiWaterZoneEnum` | `FUN_0065c520` | string | field/enum setup |
| all `*Enum` above | `FUN_0064ac50` | string | system-wide reflection registrar (references every enum string; not 1:1) |

### Annotated excerpts

**`FUN_0063f640` — the `AiDriving` component-type registration.** Representative of the whole `Ai*` family; only the descriptor offsets and the final string differ between siblings:

```c
_DAT_017bc908 = &PTR_CopyFromStream_00bbe4b8;   // per-type stream-read vtable
_DAT_017bc92c = 8;                              // field-block size for AiDriving
_DAT_017bc934 = 0x9e3779b9;                     // golden-ratio hash seed (type-id mix)
_DAT_017bc930 = &PTR_FUN_00bc5ff8;              // shared descriptor vtable
FUN_0064a770();                                 // register this descriptor
_DAT_017bc944 = s_AiDriving_00bc4d2c;           // <- type name, anchors the match
```

The shared `0x9e3779b9` seed, the `0x100` budget fields, and `FUN_0064a770()` are identical across `FUN_0063f430/4e0/590/640`, `FUN_00640b90`, `FUN_00641560`, `FUN_006481f0` — confirming a single registration template instantiated per component type.

**`FUN_0065ce20` — schema setup that registers the two patrol/priority enums by name:**

```c
FUN_00656720(s_AiPatrolModeEnum_00bc6844,&DAT_00bc6834);  // enum column + default
FUN_00656720(s_AiPriorityEnum_00bc6864,&DAT_00bc6858);
```

This shows `AiPatrolModeEnum` and `AiPriorityEnum` are two columns of one component's schema (consistent with the resolver mapping both symbols to this same function), each given a default value pointer.

**`FUN_0064ac50` (16,897 bytes) — the master reflection registrar.** It references every AI/Cover enum string in sequence, e.g. `thunk_FUN_004935d1(s_CoverRatingEnum_...)`, `..._CoverTypeEnum_...`, `..._AiHintEnum_...`, `..._AiWaterZoneEnum_...`, `..._AiPatrolModeEnum_...`, `..._AiPriorityEnum_...`. Because it touches all of them it is the global type/enum registrar (the reason every `*Enum` symbol resolved to it), not a method for any one enum — cite it as the registrar, not as evidence for an individual enum.

## How it works (decompiled)

Grounded in the Xbox PowerPC decomp `output/_ghidra_x360/xenon_decomp_named.c`. Every VA below was confirmed present with the quoted snippet. The Xbox named set has the *actual* AI command/dispatch bodies (the PC cross-ref above only resolved the reflection registrars), so this section adds runtime behavior the doc didn't have.

### `PgSysAi @8240b548` — the AI system is two lazily-allocated sub-objects

The doc names `PgSysAi` from a string but had no body. The Xbox body shows it lazily creates two AI sub-systems and caches their handles in the owning PgSystem struct at fixed offsets:

```c
==== PgSysAi @8240b548  size=120 ====
void PgSysAi(int param_1) {
  if (*(int *)(param_1 + 0x3cdc) == 0) {                 // sub-system A not yet made
    uVar1 = FUN_822ed8c0(0xffffffff830f9828,0xffffffff82024128);
    *(undefined4 *)(param_1 + 0x3cdc) = uVar1;
  }
  if (*(int *)(param_1 + 0x3ce0) == 0) {                 // sub-system B
    uVar1 = FUN_822073b8(0xffffffff831b1370,0xffffffff82024128);
    *(undefined4 *)(param_1 + 0x3ce0) = uVar1;
  }
}
```

Its caller `FUN_8240b5c0` first allocates a third AI object (`FUN_82902840(0x468)` → a 0x468-byte struct) into `param_1+0x3ce4`, resets `DAT_837fd284`/`+0x3df8`, then calls `PgSysAi`. So the AI host lives inside `PgSystem` at `+0x3ce4` (main, 0x468 B), `+0x3cdc`, `+0x3ce0`. This is the Xbox-side ground truth for the `PgSysAi` symbol; the per-frame AI tick is elsewhere.

### `DirectAction @823daea0` — the AI "do this action now" message path

`DirectAction(entityGuid, actionHash)` is the core that several AI debug/script commands use. It builds a 3-word message `{guid, actionHash, 0}`, posts it locally, and — if hosting a multiplayer session — replicates it:

```c
==== DirectAction @823daea0 ====
  local_50 = (undefined4)param_1;  local_4c = param_2;  local_48 = 0;   // {guid, actionHash, 0}
  FUN_8222dbf0(0xffffffff83187008,&local_50);                          // post the AI message
  if (DAT_837e5b00 != '\0') { FUN_823d9090(0x...82022ff8, DAT_82c4d054); }  // debug-log if enabled
  iVar1 = FUN_82590e28();                                              // session player count
  if ((1 < iVar1) && (FUN_8256e168())) {                              // hosting MP?
    ... FUN_82581230(DAT_83815b50, auStack_40);                        // replicate to clients
  }
```

So AI actions are a single-message bus with optional network replication; `DAT_837e5b00` is the AI-debug-log gate (the same flag-block as the `BoxCollect`/nav debug toggles).

### `AimedScan` / `AimEnable` / `AimDisable` — AI aim commands use *hashed* action IDs

These three (listed under "Aiming / aim-assist") are confirmed as AI aim-control commands, and they reveal that AI actions are addressed by 32-bit hashes:

```c
==== AimedScan @823dcbe8 ====
  if (param_2 == '\0') { uVar1 = 0x3a054530; } else { uVar1 = 0x53ac2c09; }   // two action hashes
  if (DAT_837e5b00 != '\0') { FUN_823d9090(0x...8202311c, DAT_82c4d048); }     // debug log
  DirectAction(param_1, uVar1);                                                // dispatch via the bus

==== AimEnable @823dcaa8 ====
  local_1c = 3;  local_18 = DAT_83d186c0; ...                  // build a typed message
  if (param_2 == '\0') { local_c = 1; ... } else { local_c = 2; ... }  // 1 = enable, 2 = disable mode
  FUN_822fa0e8(0xffffffff83180bb0,&local_20);                  // post it
```

`AimedScan` toggles between hashes `0x3a054530` and `0x53ac2c09` (the off/on "aimedscan" action, matching the `aimedscan` planner verb in Notable strings) and dispatches through `DirectAction`. `AimEnable`/`AimDisable` use a parallel message (`FUN_822fa0e8`) with an explicit mode byte (`1`=enable, `2`=disable, `0`=off). This confirms the doc's "AI aim controls" reading with code.

### `PathFind @823f5438` — this named function is a debug-render color, NOT pathfinding

Important: the named function `PathFind` is **not** the pathfinding algorithm. Its body registers a debug-draw color into a 256-entry name/color table — it is the "`- Pathfind`" AI-debug visualizer entry:

```c
==== PathFind @823f5438 ====
  uVar1 = FUN_8290ba80(0x...82023424);  FUN_82902f90(uVar1, 0x...82023424);  // resolve a debug name
  iVar2 = FUN_8290bc68(uVar1, 0x...83cb28f4, 0x100);                          // 256-slot table
  *(ulonglong *)(&DAT_83cb20f4 + iVar2 * 8) = CONCAT44(0xff00d7ff, ...);      // color 0xff00d7ff
  DAT_83cb20e8 = DAT_83cb20e8 + 1;                                            // bump count
```

`0xff00d7ff` is an ARGB debug color. The doc's Notable-strings list already (correctly) treats `PathFind` as a planner-failure/debug string; this confirms the *function* of that name is the debug-color registrar, so no behavioral pathfinding claim should be hung on it.

## Corrections & open questions

- **`PgSysAi` is a multi-object host (new fact):** `@8240b548` lazily allocates two sub-systems (`+0x3cdc`,`+0x3ce0`); its caller adds a 0x468-byte main AI object at `+0x3ce4`. The doc only had the string.
- **`PathFind` ≠ pathfinding (correction):** the named function `PathFind @823f5438` is a debug-color registrar (`0xff00d7ff`), not the navigation routine. Any reader assuming "`PathFind` = the A*/navmesh function" is wrong; the real nav code is unnamed in this build. The doc's string-level treatment was fine — this just nails the function.
- **AI actions are a hashed message bus (new fact):** `DirectAction @823daea0` posts `{guid, actionHash, 0}` and replicates it when `FUN_82590e28() > 1` (hosting MP). AI commands are addressed by 32-bit hashes (`AimedScan` uses `0x3a054530`/`0x53ac2c09`). This upgrades the doc's "goal/action verbs go through a planner" from string inference to a code-shown dispatch path.
- **`DAT_837e5b00` is the AI-debug gate:** the same flag toggled by the `BoxCollect`/nav debug-menu items (see `debug-cheat-menu.md`) gates the `FUN_823d9090` debug logging inside `DirectAction`/`AimedScan`/`AimEnable`. So the AI debug toggles really do change AI runtime logging.
- **`MindKiller` is owned by AI, surfaced in the debug menu:** its menu label reflects `FUN_8240a108()` (an AI-side state), per `debug-cheat-menu.md`. What `MindKiller` disables in the sim (likely the whole AI "mind"/decision tick) is **unverified** — only that it's an AI kill-switch the menu mirrors.
- **Still strings-only (could not verify in code):** the planner goal vocabulary (`moveto`/`takecover`/`attack`/…), cover state machine (`GoingToCover`/`AtCover`/…), squad and stimulus/threat scoring — these have no decompiled bodies under named symbols in the Xbox set; the doc's readings of them remain inference (correctly flagged there). The `AlertLow/Medium/HighThreshold` CAUTION in the doc (those are memory-pool MB thresholds, not AI alertness) is **confirmed correct** — they sit in `[x360_memory]` config, not AI code.
- **Open:** which two sub-systems `PgSysAi` creates (perception vs. actuation? squad vs. individual?) — the constructor args (`0x830f9828`, `0x831b1370`) aren't symbolized.
