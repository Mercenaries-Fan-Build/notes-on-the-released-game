# Oil + VZA Contract Script Analysis

> **Source:** Lua 5.1 bytecode constant-pool extraction from `analysis/cross_platform/scripts_vz_comparison/`
> **Platforms:** PC Retail, PC Demo, Xbox 360 (BE bytecode byte-swapped before parse)
> **Date:** 2026-05-22
> **Purpose:** Document vanilla Oil/VZA contract patterns for porting `DlcCon*` DLC contracts

---

## Methodology

1. Parsed all `oilcon*.luac`, `vzacon001.luac`, and `oiljob{004,008,011}.luac` from three platform trees.
2. Used Merc-format Lua header (`\x1bLuaQ`, 12-byte header, 4-byte float numbers) — **not** stock `\x1bLua` + version `0x51`.
3. Xbox 360 files: BE→LE swap via `ucfx_be_to_le._swap_lua51_bytecode()` before proto walk.
4. Cross-referenced PC Retail infrastructure: `wifmissiondata`, `wifmissionflow`, `wifstarterdata`, `wifbriefingdata`, `wifhqdata`.
5. Raw scan JSON: `analysis/cross_platform/contract_oil_vza_scan.json`

Related docs: [`vanilla_mission_lifecycle_analysis.md`](vanilla_mission_lifecycle_analysis.md), [`dlc_extras_activation_research.md`](dlc_extras_activation_research.md)

---

## Per-Script Summary Table (PC Retail)

| Script | Size | Strings | Inherit | Lifecycle | Explicit `import()` | Key objective modules | VZ layers / staging |
|--------|------|---------|---------|-----------|---------------------|----------------------|---------------------|
| **oilcon001** | 87,130 | 688 | `MrxTaskContract` | LoadAssets, Activated, Cancel, Cleanup, Complete | `MrxSubtitle` | Deliver, Destroy, Action, Protect | `vz_state_mar_industrial_act1`, `vz_state_mar_industrial_pristine` |
| **oilcon002** | 67,552 | 569 | `MrxTaskContract` | LoadAssets, Activated, Cancel, Cleanup, Complete | `MrxSubtitle` | Destroy, Deliver, EnterVehicle | (via `Vz_State_OilCon002` in mission data) |
| **oilcon003** | 17,077 | 166 | `MrxTaskContract` | Activated, Cancel, Cleanup, Complete | `MrxFactionManager` | Action, Deliver | — |
| **oilcon005** | 7,521 | 131 | `MrxTaskContract` | LoadAssets, Activated, Cancel, Cleanup, Complete | `MrxTaskRace` | Deliver (+ race child) | `VZ_state_OilCon005`, `_staging`, `_Bonus` |
| **oilcon020** | 35,017 | 307 | `MrxTaskContract` | Activated, Cancel, Cleanup, Complete | `MrxSubtitle` | EnterVehicle, Deliver, Action | `Vz_State_OilCon020`, deliverables layer |
| **oilcon021** | 22,302 | 225 | `MrxTaskContract` | Activated, Cancel, Cleanup, Complete | `MrxSubtitle` | Action, Deliver | — |
| **oilcon050** | 2,088 | 44 | `MrxTaskContractOutpost` | Activated only | `MrxVoSequence` | (outpost capture) | `Vz_State_OilCon050_Tg`, OilJob001 staging/pristine/defenses |
| **oilcon051** | 921 | 26 | `MrxTaskContractOutpost` | — | — | (outpost capture) | `Vz_State_OilCon051_Tg`, OilJob002 layers |
| **oilcon052** | 921 | 26 | `MrxTaskContractOutpost` | — | — | (outpost capture) | `Vz_State_OilCon052_Tg`, OilJob005 layers |
| **vzacon001** | 49,361 | 422 | `MrxTaskContract` | LoadAssets, Activated, Cancel, Cleanup, Complete | `MrxGuiManager` | Deliver, Destroy | `vz_state_VzaCon001_Pristine`, `vz_state_vzacon001_ruined` |
| **oiljob004** | 438 | 7 | `MrxTaskJobDestroyType` | Activated | — | (destroy-type job) | — |
| **oiljob008** | 4,681 | 88 | `MrxTaskJobDestroySet` | LoadAssets, Activated, Cleanup | — | (destroy-set job) | Multiple `Vz_State_OilJob008_*` pristine/staging/defenses/destroyed |
| **oiljob011** | 3,127 | 56 | `MrxTaskJobVerifySet` | LoadAssets, Activated | — | (verify-set job) | 5× target staging/pristine pairs |

**Outpost contracts (050–052)** are thin wrappers around capture-point outposts (`OilJob001/002/005_Outpost`) with VO on 050 only. They inherit `MrxTaskContractOutpost`, not `MrxTaskContract`.

**Jobs (004/008/011)** inherit job base classes (`MrxTaskJobDestroyType/Set/VerifySet`), not contract bases. Milestone keys appear in `wifmissiondata` (`OilJob004_Milestone1`…`4`, etc.).

---

## Common Contract Lifecycle Pattern

Vanilla contract modules follow this load-time and runtime pattern:

```
┌─────────────────────────────────────────────────────────────┐
│ LOAD TIME (module evaluated when import()'d or referenced)   │
├─────────────────────────────────────────────────────────────┤
│ inherit("MrxTaskContract")     ← registers prototype chain   │
│ import("MrxSubtitle")          ← optional; 1+ helper mods   │
│ function LoadAssets(self) ...  ← preload assets, set layers  │
│ function Activated(self) ...   ← MUST call parent Activated│
│ function Cancel(self) ...                                      │
│ function Cleanup(self) ...                                     │
│ function Complete(self) ...    ← or MissionComplete wrapper  │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│ RUNTIME (engine task tree after UnlockMission + accept)      │
├─────────────────────────────────────────────────────────────┤
│ CreateChild({ sModuleName="MrxTaskObjective*", ... })       │
│ self:_CreateEvent(Event.TimerRelative|ObjectProximity|...)    │
│ self:Complete() when final objective done                    │
└─────────────────────────────────────────────────────────────┘
```

### ScriptInit pattern

**Contract scripts do NOT define `ScriptInit`.** That entry point belongs to master/data modules (`wifmissionflow`, `dlc01`, etc.).

At contract load time the only registration hook in the bytecode constant pool is:

```lua
inherit("MrxTaskContract")   -- or MrxTaskContractOutpost / MrxTaskJob*
import("HelperModule")       -- 0–1 explicit calls; more modules referenced as globals
```

`UnlockMission`, `tMissionData`, and `MrxMissionFlow` appear in **infrastructure scripts**, not in contract modules.

### Mission registration hooks (where they live)

| Hook | Present in contracts? | Where it appears |
|------|----------------------|------------------|
| `inherit("MrxTaskContract")` | **Yes** — all Oil/VZA contracts | Top of each `oilcon*` / `vzacon001` |
| `import(...)` | Partial — 0–1 explicit imports; many `Mrx*` used as globals | Contract scripts |
| `UnlockMission(name)` | **No** | `wifmissionflow.luac` flow bindings |
| `tMissionData` | **No** | `wifmissiondata.luac` |
| `MrxMissionFlow` | **No** (subclass is `WifMissionFlow`) | `wifmissionflow.luac` |
| `dynamic_import` | **No** in Oil/VZA vanilla set | DLC bootstrap research only |
| `CreateChild` / `_CreateEvent` | **Yes** | All full contracts |

---

## OilCon001 Deep Dive

### Inheritance and imports

```lua
inherit("MrxTaskContract")
import("MrxSubtitle")
```

Additional `Mrx*` modules referenced in the constant pool (likely engine globals or lazy-resolved):

`MrxApcDrop`, `MrxCopterDrop`, `MrxFactionManager`, `MrxLayerManager`, `MrxMissionBoundary`, `MrxMusic`, `MrxSupportData`, `MrxUtil`, `MrxVoSequence`

### Lifecycle methods

| Method | Role |
|--------|------|
| `LoadAssets` | Preload VO/briefing assets; mark VZ layers |
| `Activated` | Spawn exec, APC waves, objectives; parent `MrxTaskContract.Activated(self)` |
| `Cancel` | Tear down events/objectives |
| `Cleanup` | Restore layers, despawn entities |
| `Complete` | Final completion (via objective callbacks → `self:Complete()`) |

Internal objective labels: `Obj_GotoRefinery`, `Obj_RescueExec`, `Obj_TalkToExec`, `Obj_Site2_Goto/Defend/Complete`, `Obj_Site3_Goto/Defend`.

### Objectives (CreateChild modules)

| Module | Usage |
|--------|-------|
| `MrxTaskObjectiveDeliver` | Go-to / deliver / seat objectives |
| `MrxTaskObjectiveDestroy` | Destroy targets |
| `MrxTaskObjectiveAction` | Context-action (talk) objectives |
| `MrxTaskObjectiveProtect` | Defend/wave objectives |

### Events

`Boundary`, `TimerRelative`, `ObjectProximity`, `ObjectInSeat`, `Event.CreatePersistent` (PC debug paths)

### Key entity / layer references

- **Exec VO:** `OilExec-In-Mission-Contract-Oil01-*`, `oc001_exec`
- **Locations:** `refinery_office02/03`, `mar_industrial_gate_north`, `_ocoutpost_wallgate`
- **VZ state:** `Vz_State_OilCon001`, `Vz_State_OilCon001_part1`
- **Layers (script-managed):** `vz_state_mar_industrial_act1`, `vz_state_mar_industrial_pristine`
- **Starter spawn ref:** `Starter_Oil0_Start1`
- **Briefing VO bank:** `OCMerc-Briefing-Contract-Oil01-66/68`

### StringDB keys (sample)

`[OilCon001.Objectives.001]` … `[OilCon001.Objectives.attackwaves]`, `[OilCon001.Terms.Cancel01/03]`, `[ContextAction.Talk]`

---

## OilCon001 in tMissionData (wifmissiondata.luac)

The mission registry uses a **compact encoding** after the first template entry (`AllCon001` carries explicit field names). Later missions store `(missionId, sStarter, …)` tuples inline.

### Observed OilCon001 entry

```
OilCon001  →  OilStarter0  →  (next mission OilCon002)
```

| Field | Inferred value | Evidence |
|-------|---------------|----------|
| **Key** | `"OilCon001"` | Mission table key @ string index 170 |
| **sModuleName** | `"OilCon001"` | Default: module name = mission ID (same pattern as AllCon001 template) |
| **sFactionId** | `"Oil"` | Name prefix + `GetMissionFaction` convention; no explicit `"Oil"` adjacent (unlike GurCon001 which stores `"Gur","Vza"`) |
| **sStarter** | `"OilStarter0"` | Immediately follows mission ID in constant pool |
| **bContract** | `true` (implicit) | `IsMissionAContract` infers from `*Con*` name pattern |
| **bCriticalPathMission** | Not set | Only on template missions like AllCon001 |
| **sTitle** | *(none in missiondata)* | No `[OilCon001.Title]` in wifmissiondata; title likely from string DB elsewhere |
| **tLayers** | *(not inline)* | Layer refs live in script (`vz_state_mar_industrial_*`) and flow (`vz_state_oilcon001_post`) |
| **tMilestones** | *(none)* | Unlike OilCon003/005 which have `_MilestoneN` keys |

### OilStarter0 companion (wifstarterdata.luac)

```
OilStarter0 → [SO0.Name] → OilHq → "OC Boss (phone)" → … → OilHq interior chain
```

- **HQ:** `OilHq` (from wifhqdata: `icon_oc_HQ_mc`, `[poi.oilhq]`, atmosphere `oil`)
- **Visible name:** `[SO0.Name]`
- **Boss phone starter** with Marlowe VO bank

### Briefing companion (wifbriefingdata.luac)

```
OilCon001 → vo_oilCon001 → OilCon001_briefing.gfx
```

DLC contracts need matching briefing entries **or** must suppress briefing via mission flags.

### Flow unlock (wifmissionflow.luac)

OilCon001 is **not** available at game start. Unlock chain:

```
Start → VzaCon001 → PmcCon001 → OilCon020/021 → …
OilCon050 (prereq: HasKey("OilCon050"))
  fConseq: UnlockMission("OilCon001") + UnlockMission("OilCon051")
           + layer swap mar_altagracia act1→act2
OilCon001_GurCon001 binding → UnlockMission("PmcCon002") when both complete
Post-complete: vz_state_oilcon001_post layer transition
               + ReporterNeutral.MissionVO.Oil01
```

---

## VzaCon001 Summary

Opening tutorial contract; largest VZA script (49 KB).

| Aspect | Detail |
|--------|--------|
| Inherit | `MrxTaskContract` |
| Import | `MrxGuiManager` (tutorial UI overlays) |
| Lifecycle | Full: LoadAssets, Activated, Cancel, Cleanup, Complete |
| Objectives | Deliver + Destroy child tasks |
| Layers | `vz_state_VzaCon001_Pristine`, `vz_state_vzacon001_ruined` |
| Tutorial strings | `[Tutorial.EnterExit]`, `[Tutorial.Melee]`, `[Tutorial.Shoot]`, PDA/support prompts |
| tMissionData | `VzaCon001` → `VzaCon001_Start1` → **`bPlayerVisibleMission`** (hidden from PDA until unlocked) |
| Flow | `Start` binding → `UnlockMission("VzaCon001")` (no prereq) |

---

## Related Job Scripts

| Script | Base class | wifmissiondata milestones | Notes |
|--------|-----------|---------------------------|-------|
| **oiljob004** | `MrxTaskJobDestroyType` | Milestone1–4 | Minimal (438 B); destroy-type template |
| **oiljob008** | `MrxTaskJobDestroySet` | Milestone1–5 | Heavy VZ layer staging for multi-site destroys |
| **oiljob011** | `MrxTaskJobVerifySet` | Milestone1–10 | 5 verify targets + staging/pristine per target; unlocked alongside OilCon002 from OilCon021 path |

---

## PC vs Xbox 360 String Pool Differences

After BE byte-swap, **7 of 13 scripts differ** — but differences are **debug/printf strings and platform-specific tutorial text**, not mission logic identifiers.

| Script | PC size | Xbox size | PC-only strings (category) | Xbox-only |
|--------|---------|-----------|------------------------------|-----------|
| oilcon001 | 87,130 | 58,463 | APC wave debug, `Printf`/`Debug`, stagnation timer logs | — |
| oilcon002 | 67,552 | 42,292 | Checkpoint save debug, delivery timer banners | — |
| oilcon003 | 17,077 | 11,712 | Pursuit debug strings | — |
| oilcon005 | 7,521 | 4,999 | Cleanup debug prints | — |
| oilcon020 | 35,017 | 23,425 | Truck-spotting debug | — |
| oilcon021 | 22,302 | 15,595 | Mock/debug VO triggers | — |
| vzacon001 | 49,361 | 34,111 | Achievement/minigame debug banners | Generic `[Tutorial.*]` (no PC shell suffix) |

**Conclusion:** Core mission strings (objective keys, entity names, layer names, Mrx module names) are **identical** across PC and Xbox after endianness normalization. Xbox builds strip verbose debug instrumentation.

Scripts with **identical** string pools PC↔Xbox: oilcon050, oilcon051, oilcon052, oiljob004, oiljob008, oiljob011.

---

## PC Retail vs PC Demo Differences

| Script | Identical? | Notes |
|--------|-----------|-------|
| oilcon001 | **Yes** (87,130 B, same strings) | Demo timer/string mods live in patch WAD, not in these extracted retail/demo trees |
| oilcon002 | **No** | Demo adds tutorial PDA strings; retail has checkpoint/timer debug |
| oiljob008 | **No** | Retail has full VZ layer set; demo truncated |
| oiljob011 | **No** | Retail has all 5 target + vz_state refs; demo missing several |
| vzacon001 | **No** | Retail uses `[SHELL.PCShell.Tutorial_*_PC]`; demo uses generic `[Tutorial.*]` |
| All others | **Yes** | Same size and string pool |

---

## Actionable Notes for Porting DlcCon* Contracts

1. **Use the same inherit target** as complexity dictates:
   - Full storyline contract → `inherit("MrxTaskContract")`
   - Outpost capture → `inherit("MrxTaskContractOutpost")`
   - Side job → `MrxTaskJobDestroyType/Set/VerifySet`

2. **Do NOT add `ScriptInit` to DLC contracts.** Registration belongs in a bootstrap master (`dlc01`) that:
   - Extends or replaces `tMissionData` entries (or calls `SetMissionData`)
   - Calls `UnlockMission("DlcCon00N")` from flow bindings or directly after prerequisites

3. **Each DlcCon needs companion data rows:**
   | Data file | Required fields |
   |-----------|----------------|
   | `wifmissiondata` | mission key, `sStarter` (e.g. `PmcBoss` for Fiona), optional `sTitle`, `tMilestones`, `tStartLocations` |
   | `wifstarterdata` | Starter must already exist or be added |
   | `wifbriefingdata` | `vo_dlcCon00N`, `DlcCon00N_briefing.gfx` — or set `bSkipInitialNotifications` |
   | `wifhqdata` | HQ via starter's `sHqName` |
   | `wifmissionflow` | Flow binding with `fPrereq`/`fConseq` → `UnlockMission` |

4. **Bytecode format for PC injection:**
   - Header: `\x1bLuaQ\x00\x01\x04\x04\x04\x04\x00` (LE, 4-byte floats)
   - Xbox-sourced scripts: run through `ucfx_be_to_le._swap_lua51_bytecode()` before inserting into PC WAD

5. **Minimal viable contract structure** (from oiljob004 / oilcon050):
   ```lua
   inherit("MrxTaskContract")
   function Activated(self)
       MrxTaskContract.Activated(self)
       -- setup + self:Complete() or CreateChild objectives
   end
   ```

6. **Layer management:** Full contracts call `MrxLayerManager.MarkForAddition/Removal` in Activated/Cleanup. Match vz_state naming convention (`vz_state_*_pristine/staging/ruined`).

7. **Endianness is the only Xbox port blocker** for logic; debug string stripping is optional. Recompile from source with Merc `luac` is safest for new DLC scripts.

8. **Avoid modifying retail `oilcon001`** in patch WAD unless intentional — demo bisect showed string mods cause hangs. Register DLC via appended `scripts_vz` entries + `dlc01` bootstrap instead.

---

## Quick Reference: Oil Mission Unlock DAG (from wifmissionflow)

```
Start → VzaCon001
  → PmcCon001
    → OilCon020, OilCon021
      → OilCon002 + OilJob011
    → OilCon050
      → OilCon001 + OilCon051
        → (with GurCon001) → PmcCon002
      → OilCon052 (parallel outpost chain via OilStarter2)
```

See [`vanilla_mission_lifecycle_analysis.md`](vanilla_mission_lifecycle_analysis.md) §3.4 for full binding graph.
