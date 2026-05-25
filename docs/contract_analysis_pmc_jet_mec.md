# PMC / Jet / Mercenary Contract Script Analysis

Bytecode analysis of `pmccon*`, `jetcon*`, `meccon*`, supporting job scripts, and PMC
interior integration files. Used to guide DLC `DlcCon*` registration under Fiona
(`sStarter = "PmcBoss"`).

**Tools:** `.venv/bin/python3 tools/lua_bytecode_scan.py`, `tools/lua_const_dump.py`
**Sources:** `analysis/cross_platform/scripts_vz_comparison/{PC Retail,PC Demo,Xbox 360}/bytecode/`

---

## Executive Summary

| Finding | Detail |
|---------|--------|
| **Contract entry point** | `inherit("MrxTaskContract")` + lifecycle methods (`Activated`, `Complete`, `Cancel`, `Cleanup`) — **not** `ScriptInit()` |
| **ScriptInit lives elsewhere** | `wifmissionflow` master script; contract `.luac` files are lazy-loaded modules |
| **DLC registration path** | `tMissionData["DlcConNNN"]` + `UnlockMission("DlcConNNN")` with `sStarter = "PmcBoss"`, `sFactionId = "Pmc"` |
| **Fiona briefing UI** | `wifpmcinterior` → `_LoadStarters` → `_StartStarter` → `BriefingComplete` → `AcceptMissions`; keyed off `wifstarterdata.PmcBoss` |
| **PC Retail = PC Demo** | All 12 `pmccon*.luac` files are **byte-identical** between Retail and Demo |
| **Xbox 360 bytecode** | Same script names, **different luac header** (integral/endian flags); `lua_const_dump.py` cannot parse without BE→LE swap |
| **PmcCon015 / PmcCon034 in logs** | Normal — race (015) and shooting-gallery (034) minor contracts under alternate PMC starters |

---

## Platform Comparison

| Platform | Parseable | Notes |
|----------|-----------|-------|
| **PC Retail** | Yes | Canonical reference (LE float `lua_Number`, endianness byte `0x01`) |
| **PC Demo** | Yes | Identical MD5 to Retail for every `pmccon*` file |
| **Xbox 360** | No (with current tools) | Header: `\x1bLuaQ\x51\x00\x00` vs PC `\x1bLuaQ\x51\x00\x01`; files ~65% smaller; strings present at different offsets (e.g. `Activated` @1208 vs @1218). Requires BE→LE bytecode swap before PC luac tools work (see bisect row 8 in `analysis/cross_platform/pc_bisect_results.md`) |

`lua_bytecode_scan.py` reports `1 chunk offset(s), 0 header-valid` on all PC files — the `\x1bLuaQ` signature is found but strict header validation fails. String extraction via `lua_const_dump.py` succeeds regardless.

---

## Contract Script Architecture

### Lifecycle (all contracts)

Every analyzed contract follows the same engine pattern documented in
`docs/vanilla_mission_lifecycle_analysis.md` §4:

```
inherit("MrxTaskContract")
import("MrxTaskContract")          -- top-level module string
import("MrxLayerManager")          -- universal
import("MrxVoSequence")            -- VO cues
import("MrxSubtitle")              -- most contracts
... mission-specific imports ...

function Activated(self)           -- spawn layers, create child objectives
function Complete(self)            -- teardown, achievements, VO
function Cancel(self)              -- _SetCancelMessage + Fiona VO
function Cleanup(self)             -- layer restore (when present)
```

**Child objectives** are created via `CreateChild()` with engine modules:
`MrxTaskObjectiveDeliver`, `MrxTaskObjectiveDestroy`, `MrxTaskObjectiveEnterVehicle`,
`MrxTaskObjectiveVerify`, `MrxTaskObjectiveAction`, `MrxTaskRace`.

Callback hooks on objectives: `fOnComplete`, `fOnCancel`, `tOnComplete`, `fOnPartComplete`.

### ScriptInit / Task Tree

| Component | Role |
|-----------|------|
| **`ScriptInit()`** | Called on **master scripts** (`wifmissionflow`, `dlc01`) at world load — registers `tMissionData`, imports flow modules |
| **Contract `.luac`** | Loaded on-demand when mission activates; defines `Activated`/`Complete` only |
| **`UnlockMission(id)`** | Creates task-tree nodes: `{id}`, `{id}Mission`, `{id}Briefing` under `"Missions"` parent; activates starter NPC |
| **`wifmissiondata.luac`** | Static registry: mission ID → `{sModuleName, sFactionId, sStarter, bContract, milestones, vz_states}` |
| **`wifstarterdata.luac`** | Starter NPC configs: briefing actor, VO bank, HQ name, FaceFX set |

Contracts do **not** contain `ScriptInit`, `tMissionData`, or `UnlockMission` strings.
Registration is entirely external (master script or runtime injection).

---

## PMC vs Faction Contract Differences

| Aspect | Faction (e.g. `oilcon001`, `chicon001`) | PMC (`pmccon*`) |
|--------|----------------------------------------|-----------------|
| **Starter** | `OilStarter0`, `ChiStarter0`, etc. | `PmcBoss`, `HelPmcBoss`, `MecPmcBoss`, `JetPmcBoss` |
| **Faction ID** | `"Oil"`, `"Chi"`, `"Gur"`, `"Pir"` | `"Pmc"` |
| **Briefing location** | Faction HQ interior (e.g. `OilHq`) | PMC HQ interior via `wifpmcinterior` |
| **Briefing VO prefix** | `Marlowe-In-Mission-...`, faction boss names | `Fiona-In-Mission-Contract-*` or `Fiona-In-Mission-MinorContract-*` |
| **HQ integration** | `wifhqdata` outpost unlock | `WifPmcInterior`, `WifPmcGarage`, `MrxPmc` (PMC base systems) |
| **Recruit contracts** | N/A at faction HQs | `JetCon001` / `MecCon001` use world `JetBoss` / `MecBoss` starters (not PMC interior) |
| **Special modules** | Faction-specific (e.g. `MrxChiCon001Rescue`) | `MrxShootingGallery` (031–034), `MrxTaskRace` (015–016), `HijackContractManager` (004) |
| **Active contract API** | Rare | `SetActiveContract` / `CancelActiveContract` in `pmccon004` (Solano hijack chain) |
| **Mission flow hook** | Uncommon | `WifMissionFlow` referenced in `pmccon033`, `pmccon034` completion paths |

### Why PmcCon015 and PmcCon034 Appear in Logs

These are **not** main-story Fiona contracts but still PMC-system missions:

- **PmcCon015** — Eva's race tutorial (`sStarter = "MecPmcBoss"`, not `PmcBoss`). Uses
  `MrxTaskRace`, `StartRace`, `sRaceMission = "PmcCon015Race"`. VO lines use
  `Fiona-In-Mission-MinorContract-Pmc16-*` naming (shared minor-contract bank).
- **PmcCon034** — Fiona shooting-gallery challenge (`sStarter = "PmcBoss"`). Uses
  `MrxShootingGallery`, timer/OOB cancel terms, and calls `WifMissionFlow` on complete.
  Shares objective string keys with `PmcCon031`/`032` (`[PmcCon031.Objectives.TakeOut]`, etc.).

Both are registered in `wifmissiondata` with milestone/start-location strings and will
surface in PMC interior briefing lists when unlocked.

---

## Starter → Contract Mapping (`wifmissiondata`)

| Starter | NPC | Contracts / Jobs |
|---------|-----|------------------|
| **`PmcBoss`** | Fiona | `PmcCon001`–`004`, `PmcCon031`–`034` (critical path + shooting gallery) |
| **`HelPmcBoss`** | Ewan | `PmcCon013` (heli challenge) |
| **`MecPmcBoss`** | Eva | `PmcCon015`, `PmcCon016` (race challenges) |
| **`JetPmcBoss`** | Misha | `PmcCon018`, `PmcJob001` |
| **`JetBoss`** | Misha (world) | `JetCon001` (jet pilot recruit — world mission, not PMC interior) |
| **`MecBoss`** | Eva (world) | `MecCon001` (mechanic recruit — world mission) |

### `tMissionData` Field Pattern (inferred from string pool order)

```lua
tMissionData["PmcCon031"] = {
    sModuleName = "PmcCon031",
    sFactionId = "Pmc",
    sStarter = "PmcBoss",
    bPlayerVisibleMission = true,
    bContract = true,
  -- start locations (world spawn points):
    -- "PMCCon031_Start1", "PMCCon031_Start2"
  -- milestones (progression gates):
    -- "PmcCon031_Milestone1"
  -- vz_state layers toggled on activate:
    -- "Vz_State_PmcCon031"
}
```

Main-story PMC contracts (001–004) also reference prerequisite `vz_state_*` layers.
Minor contracts (031–034) include `_Start1/_Start2` + `_Milestone1` triplets.

---

## Per-Script Analysis Tables

### PMC Contracts (`pmccon*`)

| Script | ID | Bytes | Strings | Starter | Type | Task Modules | Key Hooks | vz_state Layers | Fiona VO |
|--------|-----|------:|--------:|---------|------|--------------|-----------|-----------------|----------|
| `pmccon001` | PmcCon001 | 34,490 | 393 | PmcBoss | Main (tutorial) | Deliver, Destroy, EnterVehicle | Activated, Complete, **ActivateMission** | `Vz_State_PmcCon001`, villa waves, hijack tutorial | 14 |
| `pmccon002` | — | 13,380 | 192 | PmcBoss | Main (Blanco/oilrig) | Action, Destroy, Verify | Activated, Complete | `VZ_state_PmcCon002_Blanco` | 9 |
| `pmccon003` | — | 43,811 | 483 | PmcBoss | Main (PMC defense) | Action, Deliver, Destroy, EnterVehicle, Verify | Activated, Complete, ScriptEvent | `vz_State_Pmc_LivedIn`, bunker/Carmona states | 21 |
| `pmccon004` | PmcCon004 | 27,265 | 326 | PmcBoss | Main (Solano/nuke) | Deliver, Destroy, EnterVehicle | Activated, Complete, **SetActiveContract**, **CancelActiveContract** | Solano hijack, bunker base | 6 |
| `pmccon013` | PmcCon013 | 8,283 | 134 | HelPmcBoss | Heli challenge | EnterVehicle, generic Objective | Activated, Complete | `vz_state_PmcCon013_MP` | 0 |
| `pmccon015` | PmcCon015 | 5,830 | 107 | MecPmcBoss | Race (MP/SP) | **MrxTaskRace**, Deliver, Destroy | Activated, Complete, StartRace | `vz_state_PmcCon015_a` | 3 (MinorContract) |
| `pmccon016` | PmcCon016 | 8,488 | 155 | MecPmcBoss | Race (targets) | **MrxTaskRace**, Deliver, Destroy | Activated, Complete, StartRace | `vz_state_PmcCon016_a` | 6 (MinorContract) |
| `pmccon018` | PmcCon018 | 30,755 | 332 | JetPmcBoss | Destruction challenge | Destroy | Activated, Complete, ScriptEvent | `Vz_State_PmcCon018`, `_Veh` | 0 (Misha VO) |
| `pmccon031` | PmcCon031 | 43,362 | 459 | PmcBoss | Shooting gallery (MG) | Deliver, Destroy | Activated, Complete, CompleteVO, ScriptEvent | `Vz_State_PmcCon031` | 33 (MinorContract) |
| `pmccon032` | PmcCon032 | 34,714 | 316 | PmcBoss | Shooting gallery (easy) | Deliver, Destroy | Activated, Complete, CompleteVO, ScriptEvent | `Vz_State_PmcCon032` | 29 (MinorContract) |
| `pmccon033` | PmcCon033 | 35,458 | 303 | PmcBoss | Shooting gallery (portraits) | Deliver, Destroy | Activated, Complete, **WifMissionFlow** | `Vz_State_PmcCon033`, PopUp/PopDown | 27 (MinorContract) |
| `pmccon034` | PmcCon034 | 31,349 | 296 | PmcBoss | Shooting gallery (hard) | Destroy | Activated, Complete, **WifMissionFlow** | `Vz_State_PmcCon034` | 27 (MinorContract) |

**Not present in `scripts_vz`:** `pmccon014`, `pmccon017` (gaps in numbering — no bytecode found).

#### Notable per-script details

**pmccon001** — First PMC mission. Calls `ActivateMission`, manages `tPmcDoors` /
`tPmcEntrances`, uses `PmcInvulnerable`, `VZJeepPursuitRegionActivate`. Objective keys:
`[PmcCon001.Objectives.001]` etc.

**pmccon003** — Imports `WifPmcInterior`, `MrxPmc`, `WifVzBoundary`, `MrxSupportTransit`.
Most PMC-base-integrated main contract after the tutorial arc.

**pmccon004** — Only PMC contract with `SetActiveContract` / `CancelActiveContract`
(hijack chain management). Uses `HijackContractManager`.

**pmccon013** — Heli time trial. Creates network marker objectives
(`SendEvent_AddMarkerObjective`). Reuses cancel term string from PmcCon016
(`[PmcCon016.Terms.Cancel03]` — shared string pool artifact).

**pmccon031–034** — Share `MrxShootingGallery`, `MrxMultiPageMenu`, `MrxTimer`,
`CompleteVO` pattern. Reuse `[PmcCon031.*]` / `[PmcCon032.*]` string keys across siblings.
031–034 registered with `PMCCon0NN_Start1/Start2` + `PmcCon0NN_Milestone1`.

---

### Jet Contract (`jetcon001`)

| Field | Value |
|-------|-------|
| **ID** | `JetCon001` |
| **Starter** | `JetBoss` (world recruit — **not** `JetPmcBoss`) |
| **Faction** | Recruit mission; post-recruit contracts use `JetPmcBoss` |
| **Imports** | `MrxPmc`, `MrxAi`, `MrxSupportData` |
| **Task modules** | `MrxTaskObjective`, `MrxTaskObjectiveDestroy` |
| **Hooks** | Activated, Complete, ScriptEvent, region activate callbacks |
| **vz_states** | `Vz_State_JetCon001`, `_Pristine`, `_CP01`, `_CopterAttack` |
| **VO** | Fiona (12), Mattias/Jennifer/Chris squad, Misha |
| **Flow** | Beach assault → AA site → bunker buster → bunker destroy; calls `SetJetPilotRecruited` |

---

### Mercenary Contract (`meccon001`)

| Field | Value |
|-------|-------|
| **ID** | `MecCon001` |
| **Starter** | `MecBoss` (world recruit) |
| **Imports** | `MrxApcDrop`, `MrxGuiInterface`, `MrxPlayState`, `MrxTutorialManager` |
| **Task modules** | EnterVehicle, Deliver, **MrxTaskRace** |
| **Hooks** | Activated, Complete, ScriptEvent, `MissionComplete`, `TutorialComplete`, `ClientTutorialComplete` |
| **vz_states** | `VZ_State_MecCon001`, `Vz_State_MecJob` |
| **VO** | Eva (primary), Fiona (8), squad |
| **Flow** | Mechanic tutorial: button tray → enter vehicle → drive → set → mine delivery → park |

---

### Job Scripts

| Script | Module Base | Purpose | Key Strings |
|--------|-------------|---------|-------------|
| `pmcjob001` | `MrxTaskJobCollectType` | PMC collect job template | `[PmcJob001.Objectives]`, `[PmcJob001.Title]` |
| `mecjob.luac` | `MrxTaskJob` / `MrxTaskMission` | Mechanic job dispatcher | Deliver objectives, Eva/Fiona VO |
| `mecjob001` | `MecJob` | Single delivery job | `[MecJob001.Objectives.001]`, Fiona job VO |
| `mecjob002` | `MecJob` | Single delivery job | `[MecJob002.Objectives.001]` |
| `mecjob003` | `MecJob` | Delivery with state layer | `Vz_State_MecJob003` |

`PmcJob001` is registered under `JetPmcBoss` (Misha) with 9 milestones — a post-recruit
PMC interior job chain, not a world contract.

---

## wifpmcinterior Integration (Fiona Briefing UI)

### Starter Configuration (`wifstarterdata.luac`)

```lua
-- PmcBoss starter block (string pool order):
PmcBoss → bPmcStarter, bHintSystem, bBribeSystem,
          Global_Job_Briefing_Fiona,   -- FaceFX / briefing actor
          HelPmcBoss, bTransitSystem,
          Global_Job_Briefing_Ewan,
          MecPmcBoss, bGarageSystem, bCustomVehicleShop,
          JetPmcBoss,
          Global_Job_Briefing_Misha
```

PMC faction starter list in `Init()`:
`Pmc = {HelPmcBoss, JetBoss, JetPmcBoss, MecBoss, MecPmcBoss, PmcBoss}`

### Interior Flow (`wifpmcinterior.luac`)

| Phase | Functions / Strings |
|-------|---------------------|
| **Load** | `_LoadInterior` → `_OnInteriorLoad` → `_LoadStarters` → `_StarterLoaded` |
| **Setup** | `_SetupStarters` → `_EnableStarters` → `_SetStarterContextAction/Marker/Chatter` |
| **Briefing locs** | `PmcInterior_StarterFiona_BriefingLoc`, `_Hero1` variant; parallel for Ewan/Eva/Misha |
| **Player interact** | `_StartStarter` → briefing module load → `BriefingComplete` |
| **Mission accept** | `GetOfferedBriefings` → `AcceptMissions` → `GetPendingContract` |
| **Contract check** | `IsContractPending`, `sPendingContract`, `GetMissionStarter` |
| **VO cancel** | `VO.Cancel` on `"PmcBoss"` / `uStarter` (see `docs/lua_call_sites_from_scripts.md`) |
| **References** | Direct string refs to `PmcCon002`, `PmcCon031` in offered-briefing logic |
| **Garage link** | Imports `WifPmcGarage`; `CheckFionaCar`, `IsGarageAlive` |

Fiona's HUD marker: `HUD_PMC_Fiona`. World entity refs:
`_pmcoutpost_interior_recruitheli`, `_recruitmechanic`, `_recruitjet`.

### wifpmcgarage.luac

Garage/helipad/dock spawn system tied to PMC interior exit. Handles Fiona's car
(`CheckFionaCar`, `_OnFionaCarEnter/Death`, `[Garage.StoreFionasCar]`). Loaded by
`wifpmcinterior` — not part of contract activation, but post-briefing deployment.

---

## wifmissiondata Cross-Reference

Key PMC registry strings (PC Retail constant pool indices):

| Index | String | Context |
|------:|--------|---------|
| 221 | `PmcBoss` | Fiona starter key |
| 225–239 | `PmcCon001`–`004` + starts + vz_states | Main story chain |
| 240–255 | `PmcCon031`–`034` + starts + milestones | Shooting gallery pack |
| 256–259 | `PmcCon013`, `HelPmcBoss`, vz_states | Heli challenge |
| 260–268 | `PmcCon015`–`016`, `MecPmcBoss`, milestones | Race challenges |
| 269–277 | `PmcCon018`, `JetPmcBoss`, starts, milestones | Destruction challenge |
| 278–293 | `PmcJob001`–`002`, milestones | PMC jobs |
| 294 | `MecCon001`, `MecBoss` | Mechanic recruit |
| 296 | `JetCon001`, `JetBoss` | Jet recruit |

Mission lookup APIs in `wifmissiondata`: `GetMissionStarter`, `IsMissionAContract`,
`GetMissionTitle`, `GetMissionFaction`, `GetMissionMilestoneData`, `SetMissionData`.

---

## Guidance: Registering `DlcCon*` Under PmcBoss / Fiona

### Minimum Runtime Registration (current ASI / dlc01 approach)

```lua
tMissionData["DlcCon001"] = {
    sModuleName = "DlcCon001",       -- must match ASET hash / scripts_vz entry
    sFactionId  = "Pmc",
    sStarter    = "PmcBoss",         -- Fiona — REQUIRED for PMC interior briefing
    bPlayerVisibleMission = true,
    bContract   = true,
}
UnlockMission("DlcCon001")
```

Repeat for `DlcCon002`, `DlcCon003`, `DlcCon004a` (note: **`DlcCon004a`**, not `DlcCon004`).

**Do not** call `import("dlccon*")` from `dlc01` during world load — contracts load
on-demand when accepted (see `tools/dlc_port.py` comment block). Re-entrant block
loading caused freezes in bisect testing.

### Contract Script Requirements

Each `dlccon*.luac` must:

1. **`inherit("MrxTaskContract")`** at module load
2. Define **`Activated(self)`** calling `MrxTaskContract.Activated(self)`
3. Create objectives via **`CreateChild({sModuleName = "MrxTaskObjective*", ...})`**
4. Use **`[DlcConNNN.Objectives.*]`** / **`[DlcConNNN.Terms.*]`** string keys (localisation)
5. Use **`Fiona-In-Mission-Contract-*`** or **`Fiona-In-Mission-MinorContract-*`** VO banks
6. Toggle **`vz_state_*`** layers via `MrxLayerManager` in `Activated`/`Cleanup`
7. Compile as **LE float luac** for PC (swap Xbox BE bytecode — bisect row 7 freeze)

### Optional but Recommended for Full Fiona UX

| Asset | Purpose | If Missing |
|-------|---------|------------|
| **`wifbriefingdata` entry** | Cinematic briefing (.gfx, VO bank, FaceFX) | May fall back to simple briefing or skip cinematic |
| **Start locations** | `DlcCon001_Start1` world spawn markers | Engine may use default PMC start |
| **Milestones** | `DlcCon001_Milestone1` progression gates | Single-shot unlock still works |
| **`vz_state_*` blocks** | World overlay layers | Contract runs without environmental staging |
| **ASET hash in patch WAD** | Block loader resolution | Contract module not found on accept |

Existing retail briefing entries exist for `PmcCon002`/`PmcCon003` only
(`vo_pmcCon002`, `PmcCon002_briefing.gfx`). DLC contracts likely carry self-contained
briefing logic or need new `wifbriefingdata` rows.

### Starter Selection Decision Tree

```
Is the mission accepted inside PMC HQ with Fiona?
  YES → sStarter = "PmcBoss"
  NO  → Is it a recruit mission in the open world?
          YES → JetBoss / MecBoss
          NO  → Is it a specialist PMC interior challenge?
                  Heli  → HelPmcBoss (Ewan)
                  Race  → MecPmcBoss (Eva)
                  Jet/Destruction → JetPmcBoss (Misha)
```

All four DLC contracts ("Merc Blitz", "Arms Race", "Urban Rampage", "Death Race")
are Fiona PMC contracts → **`PmcBoss` for all**.

### UnlockMission Context Warning

`UnlockMission` is a method on `MrxMissionFlow` (in `wifmissionflow` environment).
Calling it from an ASI-injected chunk may fail if the flow task tree is not initialized.
Preferred call sites (from `docs/vanilla_mission_lifecycle_analysis.md` §9):

- Inside `wifmissionflow` `Refresh()` / `fConseq` callback
- After `import("wifmissionflow")` from a properly env-scoped chunk
- Via ASI hook post-freeplay when `_MODULES.wifmissionflow` is live

### Testing Checklist

1. Register in `tMissionData` with `sStarter = "PmcBoss"` ✓
2. Call `UnlockMission("DlcConNNN")` from valid flow context ✓
3. Enter PMC interior → Fiona starter visible (`_EnableStarter("PmcBoss")`) ✓
4. `GetOfferedBriefings` lists mission ✓
5. Accept → briefing completes → contract module loads from ASET ✓
6. `Activated` fires → objectives appear → `Complete`/`Cancel` teardown ✓

---

## Related Files

| File | Relevance |
|------|-----------|
| `docs/vanilla_mission_lifecycle_analysis.md` | Full UnlockMission / starter / briefing lifecycle |
| `docs/dlc_loader_cross_reference.md` | Contract registration pattern, `dynamic_import` |
| `tools/dlc_port.py` | `_DLC01_REGISTRATION_SOURCE` template |
| `tools/dlc_enable_asi/dlc_enable.c` | Runtime `tMissionData` injection |
| `analysis/cross_platform/pc_bisect_results.md` | BE bytecode freeze, nohook strategy |

---

*Generated from bytecode string/constant analysis, May 2026.*
