# China + Universal Alliance Contract Script Analysis

> **Date:** 2026-05-22  
> **Scope:** `chicon*`, `allcon*`, `chijob*`, `alljob*` bytecode across PC Retail, PC Demo, and Xbox 360  
> **Method:** Merc LuaQ string-constant extraction via proto-tree walk (`tools/lua_bytecode_scan.py` header validation + custom Merc 7-byte header parser). Xbox 360 chunks BE-swapped with `tools/ucfx_be_to_le._swap_lua51_bytecode` before parse.

---

## Summary

China (Chi) and Universal Alliance (All) contracts follow the same Mrx task framework as other factions. **Mission unlock/flow hooks live in `wifmissionflow.luac` / `wifmissiondata.luac`, not in individual contract scripts.** Contract bytecode defines objectives, vz_state layer toggles, VO, and Mrx task types.

| Finding | Detail |
|---------|--------|
| **PC Retail vs Demo (contracts)** | All 21 analyzed contract/job `.luac` files are **byte-identical** between PC Retail and PC Demo |
| **PC Retail vs Xbox 360 (contracts)** | Same string pools; Xbox files ~15–37% smaller (stripped debug/locvar metadata). Functional constants match after BE swap |
| **Missing scripts** | `chicon052.luac`, `allcon051.luac` — **not present on any platform** (numbering gap; 050/052/053 exist) |
| **ScriptInit / UnlockMission** | Absent from all contract scripts; present in **`wifmissionflow`** (`UnlockMission`, `MrxMissionFlow`, `RefreshUiDisplay`) |
| **dynamic_import** | Not found in any Chi/All contract or wif flow script |
| **Demo mission gating** | Demo `wifmissionflow` is **49 KB vs 67 KB retail** — 41 Chi/All flow nodes absent (incl. `ChiCon009`, `AllCon003_HVT`, `ChiCon003_HVT`, jobs 002/020) |

---

## Methodology

### Tool chain

1. **`lua_bytecode_scan.py --file *.luac`** — confirms `\x1bLuaQ` signature present; stock header validator reports `0 header-valid` because Merc uses a **7-byte custom header** (no LUAC test number):

   ```
   \x1bLuaQ \x00\x01\x04\x04\x04\x04\x00
            ver fmt int size_t instr number integral
   ```

2. **Custom proto-tree walker** — reads string constants from aligned `K[]` tables across nested protos (source, locvars, upvalues, constants).

3. **Xbox 360** — endianness byte at header+1 is `0x00` (BE). Apply `_swap_lua51_bytecode()` then parse as LE.

4. **Fallback** — `extract_strings_from_bytecode()` ASCII scan when proto walk fails (not needed for PC Retail after header fix).

### Evidence locations

```
analysis/cross_platform/scripts_vz_comparison/
├── PC Retail/bytecode/
├── PC Demo/bytecode/
└── Xbox 360/bytecode/
```

---

## Common Patterns

### 1. Registration / class hierarchy

| Script tier | `inherit` | `import` | Base class (string constant) | Notes |
|-------------|-----------|----------|--------------------------------|-------|
| **Main contracts** (001–009, 008) | ✓ | ✓ | `MrxTaskContract` | Full mission logic; multiple `MrxTaskObjective*` types |
| **Outpost contracts** (050–053) | ✓ | — | `MrxTaskContractOutpost` | Thin wrappers; also reference `Vza` for world activation |
| **Jobs — verify set** (job002) | ✓ | ✓ | `MrxTaskJobVerifySet` | Multi-target verify job |
| **Jobs — destroy set** (job020) | ✓ | partial | `MrxTaskJobDestroySet` | Multi-structure destroy job |
| **Jobs — destroy type** (job003) | ✓ | — | `MrxTaskJobDestroyType` | Minimal 435-byte stub |

**No `ScriptInit` function** appears in contract string pools. Scripts register when the engine `import()`s them (triggered from mission flow, not self-init).

### 2. Mission flow hooks (in `wifmissionflow`, not contracts)

Retail `wifmissionflow.luac` string evidence:

| Hook | Present |
|------|---------|
| `UnlockMission` | ✓ |
| `MrxMissionFlow` | ✓ |
| `RefreshUiDisplay` | ✓ |
| `WifMissionFlow` | ✓ |
| `inherit` | ✓ |
| `import` | ✓ |
| `ScriptInit` | ✗ |
| `dynamic_import` | ✗ |
| `tMissionData` | ✗ (in `wifmissiondata` instead) |

Mission IDs in flow data use **PascalCase** (`ChiCon009`, `AllCon003`) matching UI/briefing names; script filenames are lowercase (`chicon009.luac`).

### 3. vz_state layer conventions

Contracts reference overlay layers with inconsistent casing (engine accepts all):

- `vz_state_*` — lowercase (most common in newer scripts)
- `Vz_state_*` / `Vz_State_*` — mixed case (older assets, wifmissiondata)
- `VZ_state_*` — AllCon008 only

**Suffix patterns:**

| Suffix | Role |
|--------|------|
| `_Pristine` | Default visible world state |
| `_Staging` / `_staging` | Pre-mission entity placement (hidden until mission start) |
| `_Defenses` / `_Hostiles` | Combat-ready overlay |
| `_Destroyed` / `_ruined` | Post-mission destruction state |
| `_Captured` | Outpost captured by player faction |
| `_Tg` / `c_Tg` | Outpost trigger geometry layers (050–053) |

### 4. Shared Mrx services (typical imports via string constants)

| Module | Used by |
|--------|---------|
| `MrxTaskContract` / `MrxTaskContractOutpost` | All contracts |
| `MrxLayerManager` | chicon001/002/008/009, allcon001/002/003/008, chijob002/020 |
| `MrxFactionManager` | chicon001/003/008, allcon002/003 |
| `MrxVoSequence` | Nearly all scripts |
| `MrxMusic`, `MrxSubtitle`, `MrxSupportData` | Most main contracts |
| `MrxTimer`, `MrxAchievements` | Race/time contracts (008, 009) |
| `MrxCinematic` | chicon003, allcon003 (joint invasion intro) |

### 5. Cross-faction coupling

| Script | Cross-faction reference |
|--------|---------------------------|
| `chicon002` | Oil Company HQ (`OilHq`, `vz_state_staging_oilhq`, `vz_state_OC_Depot*`) — China vs OC territory fight |
| `chicon003` | `AllJob001_02_Outpost`, faction tokens `All`, `Chi`, `Pmc` |
| `allcon003` | Faction tokens `All`, `Chi`, `Pmc`; shared layer `vz_state_allcon003_invasion` |
| `wifmissiondata` | `vz_state_AllCon003_and_ChiCon003_Pristine` — **joint All+Chi mission** |
| `wifmissionflow` | `AllCon001_ChiCon001`, `AllCon050_ChiCon050` — paired unlock nodes |

---

## Per-Script Reference (PC Retail)

### China contracts (`chicon*`)

| Script | Size | Type | import | Mrx base | Objective types | vz_state layers (key) | HQ / starter |
|--------|------|------|--------|----------|-----------------|----------------------|--------------|
| **chicon001** | 13,548 | Contract | ✓✓ | MrxTaskContract | Deliver, Destroy, Release | `vz_state_chicon001`, `Vz_state_ChiCon001_Pristine`, `vz_state_cumana_act1ALL_N`, `vz_state_cumana_act1all_staging` | — |
| **chicon002** | 19,296 | Contract | ✓✓ | MrxTaskContract | Destroy | 17 layers: bridge/depot/HQ pristine→destroyed/hostiles, OC depot, Maracaibo city, traffic | `CP_HQ_P1/P2`, `SetHqRespawn`, `_HQDestroyedVO`, `_HQHealthBar`, `_HQSpottedBoundary` |
| **chicon003** | 7,201 | Contract | ✓✓ | MrxTaskContract | Destroy, Verify | *(none in script — layers in wifmissiondata)* | — |
| **chicon008** | 9,247 | Contract | ✓✓ | MrxTaskContract | Deliver, Destroy, **Race** | `vz_state_cumana_act1CHI` | — |
| **chicon009** | 11,838 | Contract | ✓✓ | MrxTaskContract | Deliver, EnterVehicle | `vz_state_cumana_act1ALL_S` | — |
| **chicon050** | 1,133 | Outpost | inherit | MrxTaskContractOutpost | — | `Vz_State_ChiCon050_Tg`, ChiJob001_01 Captured/Defenses/Pristine/Staging | `Vza` |
| **chicon051** | 1,344 | Outpost | inherit | MrxTaskContractOutpost | — | ChiJob001_02 outpost layers | `Vza` |
| **chicon052** | — | — | — | **MISSING** | — | — | — |
| **chicon053** | 1,331 | Outpost | inherit | MrxTaskContractOutpost | — | ChiJob001_04 outpost layers | `Vza` |

**chicon001** also references custom rescue module `MrxChiCon001Rescue`, skirmish spawns (`ChineseSkirmish2–4`), and localized keys `[ChiCon001.Objectives.*]`, `[ChiCon001.Terms.Cancel*]`.

**chicon009** — ambulance/vehicle delivery contract; uses `MrxTaskObjectiveEnterVehicle`, `ChiCon009_ZBD2000` entity label.

### Universal Alliance contracts (`allcon*`)

| Script | Size | Type | import | Mrx base | Objective types | vz_state layers (key) | HQ / starter |
|--------|------|------|--------|----------|-----------------|----------------------|--------------|
| **allcon001** | 14,633 | Contract | ✓✓ | MrxTaskContract | Destroy, Extract, Release | `Vz_State_AllCon001`, `vz_state_Margarita_precrash`, Margarita crash sequence | — |
| **allcon002** | 41,328 | Contract | ✓✓ | MrxTaskContract | Destroy | AllCon002 boats/MLRS/officers, Caracas city/shanty act1, staging_all_HQ | — |
| **allcon003** | 5,786 | Contract | ✓✓ | MrxTaskContract | Destroy, Verify | `vz_state_allcon003_invasion` | — |
| **allcon008** | 7,876 | Contract | ✓✓ | MrxTaskContract | Deliver, **Race** | `VZ_state_AllCon008`, `VZ_state_AllCon008_staging` | — |
| **allcon050** | 1,344 | Outpost | inherit | MrxTaskContractOutpost | — | AllJob001_01 outpost layers | `Vza` |
| **allcon051** | — | — | — | **MISSING** | — | — | — |
| **allcon052** | 1,134 | Outpost | inherit | MrxTaskContractOutpost | — | AllJob001_03 outpost layers | `Vza` |
| **allcon053** | 1,133 | Outpost | inherit | MrxTaskContractOutpost | — | AllJob001_04 outpost layers | `Vza` |

**allcon002** is the largest Chi/All script (41 KB) — multi-phase destroy contract with extensive debug strings and `Net.SendCustomEvent` usage.

### China jobs (`chijob*`)

| Script | Size | Mrx base | vz_state layers | Notes |
|--------|------|----------|-----------------|-------|
| **chijob002** | 3,700 | MrxTaskJobVerifySet | 30 layers (ChiJob002_01–05, ChiJob010_01–05, ChiJob009_B) | 5-target verify job; `tSaveData` locvar |
| **chijob003** | 436 | MrxTaskJobDestroyType | — | Minimal stub |
| **chijob020** | 3,846 | MrxTaskJobDestroySet | 33 ChiJob005 A–G + ChiJob009_A layers | Multi-site destroy job |

### Universal Alliance jobs (`alljob*`)

| Script | Size | Mrx base | vz_state layers | Notes |
|--------|------|----------|-----------------|-------|
| **alljob002** | 4,612 | MrxTaskJobVerifySet | 29 AllJob002_01–05 layers | Mirror of chijob002 pattern |
| **alljob003** | 435 | MrxTaskJobDestroyType | — | Minimal stub (mirror chijob003) |
| **alljob020** | 6,714 | MrxTaskJobDestroySet | 60 AllJob005 + ChiJob006 layers | Cross-faction destroy set |

---

## wifmissiondata / wifmissionflow Cross-Reference

### ChiCon009

| File | Binding strings |
|------|-----------------|
| **wifmissiondata** | `ChiCon009`, `ChiCon009_Milestone1/2/3` |
| **wifmissionflow** | `ChiCon009` |
| **chicon009.luac** | Mission logic; layer `vz_state_cumana_act1ALL_S` |

Demo `wifmissionflow` has **no `ChiCon009` node** — contract bytecode exists in Demo WAD but flow never unlocks it.

### AllCon003 (+ paired ChiCon003)

| File | Binding strings |
|------|-----------------|
| **wifmissiondata** | `AllCon003`, `Vz_State_AllCon003`, `vz_state_AllCon003_Pristine`, `vz_state_AllCon003_and_ChiCon003_Pristine`, `ChiCon003`, `Vz_State_ChiCon003`, `vz_state_ChiCon003_Pristine` |
| **wifmissionflow** | `AllCon003`, `AllCon003_HVT`, `ChiCon003`, `ChiCon003_HVT` |
| **allcon003.luac** | Invasion logic; `vz_state_allcon003_invasion`; factions `All`, `Chi`, `Pmc` |
| **chicon003.luac** | HVT verify/destroy; cinematic; no vz layers in script body |

**Joint mission:** AllCon003 and ChiCon003 share pristine layer `vz_state_AllCon003_and_ChiCon003_Pristine` in mission data — single world-state overlay for the cooperative invasion contract pair.

### Other notable flow edges

| Flow node | Meaning |
|-----------|---------|
| `AllCon001_ChiCon001` | Paired unlock: completing AllCon001 path unlocks ChiCon001 (or vice versa) |
| `AllCon050_ChiCon050` | Outpost pair linkage |
| `BioChina` | Faction bio/unlock fanfare hook for China faction |
| `ChiJob010_Target_01..05` | Job targets referenced in flow (job script file is `chijob002`) |

---

## Platform Comparison

### Contract bytecode (chicon* / allcon* / jobs)

| Comparison | Result |
|------------|--------|
| **PC Retail vs PC Demo** | **100% identical** (all 21 present files, verified string pools) |
| **PC Retail vs Xbox 360** | Same mission strings; Xbox ~171–15,329 bytes smaller per file |
| **Xbox-only diffs** | None in mission logic strings |
| **Retail-only vs Xbox** | Debug/locvar metadata: `@source:`, `@locvar:self`, `@locvar:tSaveData`, verbose `Debug.Printf` format strings |

Example size deltas (Retail − Xbox):

| Script | Retail | Xbox | Δ |
|--------|--------|------|---|
| chicon001 | 13,548 | 9,276 | −4,272 |
| allcon002 | 41,328 | 25,999 | −15,329 |
| chicon050 | 1,133 | 962 | −171 |

### wifmissionflow / wifmissiondata

| File | PC Retail | PC Demo | Xbox 360 |
|------|-----------|---------|----------|
| **wifmissionflow** | 67,605 B / 1,512 strings | 49,606 B / 1,105 strings | 51,449 B / 1,512 strings |
| **wifmissiondata** | 24,605 B / 413 strings | 24,704 B / 415 strings | 16,700 B / 413 strings |

**Demo wifmissionflow** removes 89 retail-only nodes including:

- `ChiCon009`, `ChiCon003_HVT`, `AllCon003_HVT`
- `ChiCon051`, `ChiCon053`, `AllCon052`, `AllCon053`
- All `ChiJob002`, `ChiJob020`, `AllJob002`, `AllJob003`, `AllJob020` target nodes
- `AllCon001_ChiCon001`, `AllCon050_ChiCon050` paired unlocks

Demo adds: `DEMO_BOUNDARY`, `GurConDemoBoundary`, `ShowDemoOutroAndQuitToShell`, `vz_state_demo_base`.

**Xbox wifmissionflow** matches retail string count (1,512) including `ChiCon009`, `AllCon003_HVT`. Xbox `wifmissiondata` is smaller (16.7 KB) but same string count — likely stripped debug symbols.

---

## DLC Porting Implications

### 1. Contract scripts are self-contained — flow is the gate

DLC contract bytecode (`dlccon001`–`004`) should follow the same pattern:

- `inherit("MrxTaskContract")` + mission logic
- **No `ScriptInit` needed** in the contract file itself
- Registration requires **`wifmissionflow` node + `UnlockMission` edge** (or bootstrap `import("dlccon00N")` from `dlc01` master script)

### 2. Do not patch individual Chi/All contracts for DLC

China and Alliance contracts are already present and identical in PC Retail/Demo WADs. DLC activation work targets:

- `dlc01` master script chain-load
- `wifmissionflow` unlock graph (if DLC missions need progression hooks)
- Xbox-origin DLC bytecode **BE→LE swap** before PC load (same as existing `ucfx_be_to_le` pipeline)

### 3. vz_state layers must ship with contracts

Each contract references specific overlay layers (see tables above). DLC port must include:

- Matching `vz_state_*` block files in `vz-patch.wad`
- Layer names **case-sensitive** — preserve exact strings from bytecode (`Vz_State_*` vs `vz_state_*`)

### 4. Outpost contracts (050–053) need `Vza`

Outpost scripts are thin `MrxTaskContractOutpost` wrappers that also call **`Vza`** (world-zone activator). Missing `Vza` module or trigger layers (`*_Tg`, `*c_Tg`) breaks outpost capture missions.

### 5. Joint missions (AllCon003 / ChiCon003)

Porting one requires the other's pristine overlay:

```
vz_state_AllCon003_and_ChiCon003_Pristine
```

Both scripts and wifmissiondata entries must stay synchronized.

### 6. Demo vs Retail patch strategy

If testing against Demo install:

- Contract `.luac` files work unchanged (identical to retail)
- **`wifmissionflow` in Demo lacks late-game Chi/All nodes** — use Retail `scripts_vz` block for flow testing, or patch Demo flow separately
- Demo-specific nodes (`DEMO_BOUNDARY`) must not be accidentally removed

### 7. Missing chicon052 / allcon051

No bytecode exists on any platform — do not allocate ASET slots or flow nodes for these IDs. Outpost numbering jumps 050→052 (China) and 050→052 (All).

### 8. Recommended verification commands

```bash
# Header scan (expect 1 LuaQ offset, 0 stock-valid — Merc custom header)
.venv/bin/python3 tools/lua_bytecode_scan.py \
  --file analysis/cross_platform/scripts_vz_comparison/PC\ Retail/bytecode/chicon009.luac

# Full scripts_vz string harvest (all 114 scripts)
make extract-placements OUTPUT=./output   # populates pmc_lua_string_harvest.json
```

---

## Appendix: ScriptInit / Registration Model

```
Engine boot
  └─ vz master script (ScriptInit)
       └─ wifmissionflow (WifMissionFlow : inherit)
            ├─ tMissionData from wifmissiondata
            ├─ UnlockMission("ChiCon009")  ──► import("chicon009") at runtime
            └─ MrxMissionFlow.Refresh / RefreshUiDisplay
                 └─ chicon009.luac loads
                      inherit("MrxTaskContract")
                      ──► objectives, layers, VO execute
```

Contract scripts **never call `UnlockMission` themselves** — they are leaf modules loaded on demand when flow unlocks their PascalCase mission ID.

---

## Files Analyzed

| Category | Count | Platforms |
|----------|-------|-----------|
| China contracts | 8 present / 9 requested | PC Retail, PC Demo, Xbox 360 |
| All contracts | 8 present / 9 requested | PC Retail, PC Demo, Xbox 360 |
| China jobs | 3 | PC Retail, PC Demo, Xbox 360 |
| All jobs | 3 | PC Retail, PC Demo, Xbox 360 |
| Flow data | 2 (`wifmissiondata`, `wifmissionflow`) | PC Retail, PC Demo, Xbox 360 |
| **Missing** | `chicon052`, `allcon051` | all platforms |
