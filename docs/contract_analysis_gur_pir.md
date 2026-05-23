# Guerrilla + Pirate Contract Script Analysis

Bytecode analysis of `gurcon*` / `pircon*` contract scripts and related job scripts across PC Retail, PC Demo, and Xbox 360 extracted `scripts_vz` trees.

**Tools:** `tools/lua_const_dump.py` (primary string/constant dumper), `tools/lua_bytecode_scan.py` (header/chunk validation). Xbox 360 `.luac` files are big-endian and require BE→LE swap before `lua_const_dump.py` can parse them; string analysis below is from PC Retail unless noted.

**Analysis artifact:** `analysis/cross_platform/gur_pir_contract_analysis.json`

---

## Executive Summary

| Contract | Role | Starter (wifmissiondata) | Flow unlock trigger (wifmissionflow) |
|----------|------|---------------------------|--------------------------------------|
| **GurCon005** | Minor UP assassination (4 destroy targets) | **GurStarter2** (Huang @ GurOutpost2) | After GurCon001 fortress arc (`vz_state_gurcon001_fortress_destroyed`); calls **`RequestStarter` + GurStarter4** (Vega) |
| **PirCon004** | Co-op organ delivery / VZ chase | **PirStarter4** (Stoosh @ PirOutpost4) | Unlocked in pirate act flow after **PirCon002 → PirCon003** chain; references **PirJob012** / **PirJob020** targets |

Both contracts live in retail `scripts_vz` (not DLC-only bytecode). They use standard `inherit MrxTaskContract` and do **not** call `UnlockMission`, `Refresh`, or `dynamic_import` internally — unlock is entirely driven by `wifmissionflow` + `wifmissiondata`.

**Missing scripts (all platforms):** `gurcon004`, `gurcon051` — not present in any extracted `scripts_vz` tree; likely cut or never shipped.

---

## Cross-Platform Notes

| Pattern | Detail |
|---------|--------|
| PC Retail vs PC Demo | **Identical bytecode** for same-size files (`gurcon005`, `pircon004` SHA256 match). Demo differs for some scripts: `gurcon001` (+1,233 B, extra tutorial/AI strings), `pirjob020` (−1,080 B, drops PirJob010/011 target groups). |
| Xbox 360 | All scripts present except same gaps as PC. Bytecode ~25–40% smaller due to BE encoding + compiler differences. **String dump fails without endian swap** (header `00 00` vs LE `0a 00` test number). |
| Shared template hash | `gurcon005` shares asset identity hash `0xb2cec5f5` with 10 other minor contracts (`pircon002`, etc.) — simple destroy/delivery template per `docs/modding_deep_dive.md`. |

---

## Mission Flow Integration (GurCon005 / PirCon004)

### wifmissiondata — mission registry

Mission table entries pair each contract with a **starter** (briefing contact):

```
GurCon001  → GurStarter0 (Diaz / GurHq)
GurCon002  → (Gur faction block)
GurCon003  → GurStarter5 (Vargas / GurOutpost5)
GurCon005  → GurStarter2 (Huang / GurOutpost2)   ← PDA contact
GurCon050  → (outpost contract, no starter in string block)
GurCon053  → GurStarter1 (Diaz)

PirCon001  → PirStarter1 (Devilbwoy / PirOutpost1)
PirCon002  → (Pir chain)
PirCon003  → PirStarter3 (Jane / PirOutpost3)
PirCon004  → PirStarter4 (Stoosh / PirOutpost4)  ← PDA contact
PirCon051  → (outpost)
PirCon052  → (outpost)
```

Milestone keys exist for main contracts: `GurCon003_Milestone{1-3}`, `PirCon004_Milestone{1-3}`, etc.

### wifmissionflow — runtime unlock

**GurCon005** appears in the guerrilla act-1 progression block:

```
vz_state_gurcon001_fortress
vz_state_gurcon001_staging
Vz_State_GurCon001
vz_state_gurcon001_fortress_destroyed
→ GurCon005
→ RequestStarter
→ GurStarter4          ← flow requests that exposes Vega as contact
→ GurJob002_* / GurJob012_* targets
```

Layer hooks referenced in flow (not in contract script itself):

- `vz_state_gurcon005_airportdefbase`
- `vz_state_gurcon005_airportdefbase_staging`

**PirCon004** appears after the PirCon002/003 chain:

```
PirCon002
PirJob020
PirCon003
→ PirCon004
→ PirJob012_Target_01 .. _10
→ SetFlowData / GetStarter / AddIntro
```

Cross-faction link: `OilCon001_GurCon001` ties Oil intro to GurCon001 unlock in flow graph.

### In-contract mission flow calls

| API | Gur scripts | Pir scripts |
|-----|-------------|-------------|
| `UnlockMission` | — | — |
| `Refresh` / `RefreshUiDisplay` | — | — |
| `dynamic_import` | — | — |
| `WifMissionFlow` | **gurcon053 only** (`HasKey`, `OilCon050` gate) | — |

Contracts rely on `LoadAssets` / `Activated` lifecycle from `MrxTaskContract` base; unlock is external.

---

## HQ / Outpost / Starter Map

From `wifhqdata.luac` + `wifstarterdata.luac`:

| Key | Template | Parking / notes |
|-----|----------|-----------------|
| **GurHq** | `GurHq_Interior` | `05_gur_hq_parking` |
| **GurOutpost1** | Diaz (GurStarter0/1) | — |
| **GurOutpost2** | Huang (GurStarter2) | GurCon005 briefing contact |
| **GurOutpost4** | Vega (GurStarter4) | Flow `RequestStarter` target for GurCon005 |
| **GurOutpost5** | Vargas (GurStarter5) | GurCon003 contact |
| **PirOutpost1** | Devilbwoy (PirStarter1) | `08_pir_hq_parking` |
| **PirOutpost3** | Jane (PirStarter3) | PirCon003 contact |
| **PirOutpost4** | Stoosh (PirStarter4) | PirCon004 contact; `27_pir_con051_parking` |

Outpost capture contracts bind buildings:

| Contract | Outpost building | Job layer prefix |
|----------|-----------------|------------------|
| gurcon050 | `GurJob003_Outpost` | GurJob003 |
| gurcon052 | `GurJob008_01_Outpost` | GurJob008_01 |
| gurcon053 | `GurJob008_02_Outpost` | GurJob008_02 (+ OilCon050 gate) |
| pircon051 | `PirJob002_02_Outpost` | PirJob002_02 |
| pircon052 | `PirJob002_03_Outpost` | PirJob002_03 |

---

## Per-Script Reference

### Guerrilla Contracts

#### gurcon001 — Destroy VZ beach fortress

| Field | Value |
|-------|-------|
| **Sizes (B)** | Retail 19,862 · Demo 21,095 · Xbox 14,074 |
| **Inherit** | `inherit` → **MrxTaskContract** |
| **Imports** | MrxSubtitle, MrxVoSequence, MrxSupportData, MrxTransit, MrxLayerManager, MrxFactionManager |
| **Objective** | Destroy castle, tower, bridge, barracks, munitions depot |
| **VZ layers** | `Vz_State_GurCon001`, `_staging`, `_pristine`, `_outpost`, `_fortress`, `VZ_State_GurCon001_TG` |
| **HQ/outpost** | `Vz_State_GurCon001_outpost`, `_vzoutpost_bld_barrackbunker` |
| **Cross-platform** | Demo adds `AddFreebie`, extra helo variant strings; Xbox BE (strings not decoded) |
| **DLC note** | **Prerequisite for GurCon005** via fortress_destroyed flow state |

#### gurcon002 — Merida church / building destruction

| Field | Value |
|-------|-------|
| **Sizes (B)** | Retail 37,511 · Demo 37,511 · Xbox 25,351 |
| **Inherit** | MrxTaskContract |
| **Imports** | MrxSubtitle, MrxLayerManager, MrxUtil, MrxTimer, MrxFactionManager |
| **Objective** | Destroy commercial/residential/project buildings; deliver to church; protect church |
| **VZ layers** | `vz_state_gurcon002`, `_pristine`, `_traffic`, `vz_state_merida_act1`, `_helo` |
| **Outpost path** | `Path_ChurchAttack_Outpost` |
| **Cross-platform** | Retail == Demo; Xbox BE |

#### gurcon003 — Medevac race / boat delivery

| Field | Value |
|-------|-------|
| **Sizes (B)** | Retail 20,789 · Demo 20,789 · Xbox 13,460 |
| **Inherit** | MrxTaskContract |
| **Imports** | MrxFactionManager, MrxVoSequence, **MrxTaskRace**, MrxTutorialManager |
| **Objective** | Race gates (`GurCon3_gate_*`), med delivery, boat blocks |
| **VZ layers** | `VZ_State_GurCon003`, `_Med`, `vz_state_staging_pirhq`, city act layers |
| **Cross-platform** | Retail == Demo |

#### gurcon005 — Assassinate UP targets *(game-log contract)*

| Field | Value |
|-------|-------|
| **Sizes (B)** | Retail 2,568 · Demo 2,568 · Xbox 1,891 |
| **Inherit** | MrxTaskContract |
| **Imports** | MrxSubtitle, MrxLayerManager, MrxUtil, MrxSupportData, MrxFactionManager |
| **Title string** | `Assassinate Universal Petroleum Targets` |
| **Objectives** | `[GurCon005.Objectives.005]` — destroy 4 targets |
| **Targets** | `GurCon005_Target01` … `Target04` via **MrxTaskObjectiveDestroy** |
| **VZ layers** | `VZ_state_gurcon005`, `_junglebase`, `_airportdefbase`, `_depot` |
| **VO** | Fiona minor-contract lines Gur05-17/18/20/21 |
| **Mission flow** | Registered under **GurStarter2**; unlocked after GurCon001 fortress destroyed; flow calls **RequestStarter(GurStarter4)** |
| **Cross-platform** | Retail == Demo (identical SHA256); smallest main contract; shared template `0xb2cec5f5` |
| **DLC note** | Already in retail `scripts_vz`. If missing in-game, check flow state `vz_state_gurcon001_fortress_destroyed` and starter unlock — not a missing bytecode problem. |

#### gurcon050 — Outpost capture (GurJob003)

| Field | Value |
|-------|-------|
| **Sizes (B)** | Retail 884 · Demo 884 · Xbox 778 |
| **Inherit** | **MrxTaskContractOutpost** (not MrxTaskContract) |
| **Outpost** | `GurJob003_Outpost`, capture pt `GurJob003_CapturePt1` |
| **Layers** | Staging/pristine/defenses/captured + `Vz_State_GurCon050_Tg` |
| **Rival** | `Vza` |
| **Cross-platform** | Retail == Demo |

#### gurcon052 — Outpost capture (GurJob008_01)

| Field | Value |
|-------|-------|
| **Sizes (B)** | Retail 939 · Demo 939 · Xbox 825 |
| **Inherit** | MrxTaskContractOutpost |
| **Outpost** | `GurJob008_01_Outpost` |
| **Parking** | `18_gur_con052_parking` (wifhqdata) |
| **Cross-platform** | Retail == Demo |

#### gurcon053 — Outpost capture + Oil gate

| Field | Value |
|-------|-------|
| **Sizes (B)** | Retail 2,336 · Demo 2,336 · Xbox 1,878 |
| **Inherit** | MrxTaskContractOutpost |
| **Outpost** | `GurJob008_02_Outpost` |
| **Mission flow** | **`WifMissionFlow:HasKey(OilCon050)`** — requires Oil outpost contract complete |
| **VO** | Fiona outpost lines + `GurCon053_FionaVO_Activate_PreOil/PostOil` |
| **Parking** | `17_gur_con053_parking` |
| **Cross-platform** | Retail == Demo |

---

### Pirate Contracts

#### pircon001 — Jetski race / converge

| Field | Value |
|-------|-------|
| **Sizes (B)** | Retail 10,337 · Demo 10,337 · Xbox 6,653 |
| **Inherit** | MrxTaskContract |
| **Imports** | MrxTaskRace, MrxTaskObjectiveDeliver, MrxLayerManager, MrxMusic |
| **VZ layers** | `VZ_state_PirCon001`, `_staging` |
| **Music** | `mu_mission_pircon001_01` |
| **Cross-platform** | Retail == Demo |

#### pircon002 — Vehicle enter + prop delivery

| Field | Value |
|-------|-------|
| **Sizes (B)** | Retail 17,341 · Demo 17,341 · Xbox 11,680 |
| **Inherit** | MrxTaskContract |
| **Objectives** | Enter vehicle → deliver props → MP end talk |
| **VZ layers** | `vz_State_PirCon002_MP`, `_Deliverables` |
| **Shared strings** | Reuses `[PirCon003.Terms.*]` / `[PirCon003.Objectives.*]` labels |
| **Cross-platform** | Retail == Demo; shared template `0xb2cec5f5` |

#### pircon003 — Vehicle + goods delivery (harder tier)

| Field | Value |
|-------|-------|
| **Sizes (B)** | Retail 25,113 · Demo 25,113 · Xbox 17,386 |
| **Inherit** | MrxTaskContract |
| **Objectives** | Enter vehicle → deliver goods (Hard/Med/Easy tiers) → end talk |
| **VZ layers** | `vz_State_PirCon003_MP`, `_Deliverables` |
| **Cross-platform** | Retail == Demo |

#### pircon004 — Organ delivery / co-op VZ chase *(game-log contract)*

| Field | Value |
|-------|-------|
| **Sizes (B)** | Retail 34,753 · Demo 34,753 · Xbox 20,704 |
| **Inherit** | MrxTaskContract |
| **Imports** | MrxLayerManager, MrxGui, MrxUtil, MrxFactionManager, DangerousBuilding |
| **Title** | `PirCon004: Physics Delivery, Organs for transplant` |
| **Objectives** | (1) Enter `PirCon004_OrganTruck` (2) Deliver to `PirCon004_Dest_Location` (3) Accept delivery talk |
| **Co-op** | `Net.IsServer/IsClient`, `Player.GetSecondaryCharacter`, `PirCon004_Player2Truck`, `VZ_state_PirCon004_Coop` |
| **VZ chase** | `StartPursuit`, `VZChase`, `PirCon004_TruckSpawn`, M35 guntruck driver AI |
| **Organ boxes** | `OrganBox_02`…`34` (+ `_b` coop variants), `_global_containertransplant` spawn |
| **VZ layers** | `VZ_state_PirCon004`, `_Coop` |
| **Mission flow** | Registered under **PirStarter4**; unlocked after PirCon002/003 in flow |
| **Cross-platform** | Retail == Demo (identical SHA256); largest gur/pir contract; heavy Net.* usage |
| **DLC note** | Co-op contract already in retail. Activation failures likely flow/starter state, not missing script. Rebuilt WAD must preserve BE→LE swap for any patched copy. |

#### pircon051 — Outpost capture (PirJob002_02)

| Field | Value |
|-------|-------|
| **Sizes (B)** | Retail 939 · Demo 939 · Xbox 825 |
| **Inherit** | MrxTaskContractOutpost |
| **Outpost** | `PirJob002_02_Outpost` |
| **Extra** | `tDangerousBldgs` (unique vs gur outposts) |
| **Parking** | `27_pir_con051_parking` |

#### pircon052 — Outpost capture (PirJob002_03)

| Field | Value |
|-------|-------|
| **Sizes (B)** | Retail 939 · Demo 939 · Xbox 825 |
| **Inherit** | MrxTaskContractOutpost |
| **Outpost** | `PirJob002_03_Outpost` |
| **Parking** | `28_pir_con052_parking` |

---

### Related Job Scripts

| Script | Base class | Strings | Purpose / notes |
|--------|-----------|---------|-----------------|
| **gurjob001** | MrxTaskJobDestroyType | 19 | Destroy-type job; billboard target; `[GurJob001.Terms.Summary]` |
| **gurjob002** | MrxTaskJobVerifySet | 34 | Verify-kill set; dynamic `GurJob002_*` / `GurJob012_*` targets; `_staging/_pristine/_defense` layers |
| **gurjob006** | MrxTaskJobDestroyType | 8 | Minimal destroy job; faction filter `OC` |
| **gurjob020** | MrxTaskJobDestroySet | ~60 | Multi-site destroy set; `Vz_State_GurJob007_*`, `GurJob011_*` layers |
| **pirjob001** | MrxTaskJobDestroyType | 8 | Minimal destroy job; faction `VZ` |
| **pirjob012** | MrxTaskJobVerifySet | ~80 | 10 verify targets; `Vz_State_PirJob012_01`…`_10` staging/pristine pairs |
| **pirjob020** | MrxTaskJobDestroySet | 78 / 54 | Destroy set; **Retail adds PirJob010/011** targets vs Demo |

Job scripts use `inherit` + `import` but no direct `UnlockMission`. Flow references job targets when unlocking adjacent contracts (e.g., GurCon005 flow lists GurJob002/012 targets; PirCon004 lists PirJob012 targets).

---

## Actionable DLC Notes

1. **GurCon005 / PirCon004 are retail scripts** — they exist in all three platform extractions with correct names in `wifmissiondata` and `wifmissionflow`. A "contract not appearing" bug is almost certainly **flow/starter state**, not absent bytecode.

2. **GurCon005 unlock checklist**
   - Complete **GurCon001** fortress arc → set `vz_state_gurcon001_fortress_destroyed`
   - Flow runs `RequestStarter` for **GurStarter4** (Vega)
   - Contract appears under **GurStarter2** (Huang) in mission data — verify both starters are unlocked
   - Layer assets: `VZ_state_gurcon005_*` (junglebase, airportdefbase, depot)

3. **PirCon004 unlock checklist**
   - Progress **PirCon002 → PirCon003** chain
   - Contact: **PirStarter4** (Stoosh @ PirOutpost4)
   - Co-op path needs Net sync; test with `Net.IsServer` code paths intact
   - Milestones: `PirCon004_Milestone1..3` in wifmissiondata

4. **Outpost DLC contracts (050–053 / 051–052)** use `MrxTaskContractOutpost` — separate from main contracts. GurCon053 gated on **`OilCon050`** via `WifMissionFlow:HasKey`.

5. **Patch WAD / porting:** Xbox bytecode must be endian-swapped (`tools/ucfx_be_to_le.py`) before PC injection. PC Retail and Demo copies are interchangeable for gur/pir contracts.

6. **Missing gurcon004 / gurcon051:** Do not expect these in `scripts_vz`; no extraction path found on any platform.

7. **Hook surface for ASI mod:** If forcing unlock, target `wifmissionflow` `UnlockMission` / `RequestStarter` call sites rather than patching individual contract scripts (contracts have no self-unlock logic).

---

## ScriptInit / Inherit Pattern

All analyzed scripts follow the standard Mercs 2 pattern:

```lua
-- Conceptual (from string constants; no ScriptInit symbol in bytecode)
inherit(MrxTaskContract)   -- or MrxTaskContractOutpost, MrxTaskJobDestroyType, etc.
import("MrxLayerManager")  -- etc.
-- LoadAssets → Activated → objective tree via CreateChild(MrxTaskObjective*)
```

| Pattern | Scripts |
|---------|---------|
| `inherit` + **MrxTaskContract** | gurcon001–003, gurcon005, pircon001–004 |
| `inherit` + **MrxTaskContractOutpost** | gurcon050/052/053, pircon051/052 |
| `inherit` + **MrxTaskJobDestroyType** | gurjob001, gurjob006, pirjob001 |
| `inherit` + **MrxTaskJobVerifySet** | gurjob002, pirjob012 |
| `inherit` + **MrxTaskJobDestroySet** | gurjob020, pirjob020 |

No script defines a `ScriptInit` string constant; initialization is inherited from the MrxTask hierarchy.

---

## File Inventory

| Script | PC Retail | PC Demo | Xbox 360 |
|--------|-----------|---------|----------|
| gurcon001–003, 005 | ✓ | ✓ | ✓ |
| gurcon004, 051 | — | — | — |
| gurcon050, 052, 053 | ✓ | ✓ | ✓ |
| pircon001–004 | ✓ | ✓ | ✓ |
| pircon051, 052 | ✓ | ✓ | ✓ |
| gurjob001/002/006/020 | ✓ | ✓ | ✓ |
| pirjob001/012/020 | ✓ | ✓ | ✓ |
