# DLC Arena Loading Analysis — "Blow It Up Again" Level Transition Problem

> **Date:** 2026-05-23
> **Status:** Research / architectural analysis (no code changes)
> **Problem:** DLC challenge missions expect dedicated arenas (Caicara / Speed City) but currently run in the existing Venezuela world

---

## Table of Contents

1. [Problem Statement](#1-problem-statement)
2. [What the DLC Missions Expect](#2-what-the-dlc-missions-expect)
3. [DLC Arena Assets in vz-patch.wad](#3-dlc-arena-assets-in-vz-patchwad)
4. [How Vanilla Level Transitions Work](#4-how-vanilla-level-transitions-work)
5. [Feasibility Assessment of Approaches](#5-feasibility-assessment-of-approaches)
6. [Recommended Approach](#6-recommended-approach)
7. [Quick Wins for Partial Functionality](#7-quick-wins-for-partial-functionality)
8. [Open Questions](#8-open-questions)

---

## 1. Problem Statement

### 1.1 The Core Issue

The "Blow It Up Again" DLC consists of 4 challenge missions that were designed to run in **standalone arenas** — dedicated terrain, placement, and layer blocks entirely separate from the main Venezuela map. On Xbox 360, the engine performed a full level transition: it unloaded the Venezuela world, loaded the DLC's own terrain/layers/spawns, and ran the mission in that isolated arena.

When we port the DLC to PC and activate contracts via the ASI bootstrap, the following happens:

```
1. Player accepts DlcCon001 (Merc Blitz) from Fiona at PMC HQ
2. Contract script loads successfully (dynamic_import resolves from patch WAD)
3. dlccon001 script calls Activated() → attempts to reference:
   - DLC-specific spawn points (don't exist in Venezuela layers_static)
   - DLC-specific locations (dlc01_commonlocations)
   - DLC terrain (dlc01_terrain / dlc01_lowresterrain)
   - DLC state layers (dlc01_state_dlccon001, dlc01_state_missionhub)
4. Objectives fail to initialize — spawn points not found, locations nil
5. Mission stuck: no crash, but can't progress
```

### 1.2 Evidence from Game Logs

```
[01:41:35.556] [dlc_enable] [lua]  =-=  DlcCon001               nil
[01:41:35.572] [dlc_enable] [lua]  =-= NOT A WAGER!
...
[01:41:45.533] [dlc_enable] [lua] Dynamically imported module dlccon001
```

The `nil` after `DlcCon001` suggests the mission's expected world state is absent. The script loads but cannot find its world references.

### 1.3 Architecture Mismatch

| Aspect | Xbox 360 Original | Current PC Port |
|--------|-------------------|-----------------|
| Level context | DLC arena (standalone map) | Venezuela freeplay world |
| Terrain | `dlc01_terrain` / `dlc01_lowresterrain` | Venezuela terrain (20×20 tiles) |
| Placements | `dlc01_base`, `dlc01_commonlocations` | Venezuela `layers_static` (62k entities) |
| State layers | `dlc01_state_*` (spawns, pathfinding, atmofx) | Venezuela `vz_state_*` |
| Active script context | `DLC01` as master script | `vz` as master script |
| IsDLC flag | `true` (set by engine) | `false` (never set) |
| DlcMapId | Non-zero (identifies arena) | 0 (Venezuela) |

---

## 2. What the DLC Missions Expect

### 2.1 The 4 DLC Contracts

| Contract | Arena | Mission Type | Key References |
|----------|-------|--------------|----------------|
| **DlcCon001** (Merc Blitz) | Caicara | Combat challenge | `dlc01_state_dlccon001` spawn waves |
| **DlcCon002** (Arms Race) | Speed City (roads) | Racing/combat | `dlc01_dlccon002_roads`, `dlc01_speedcity_roads` |
| **DlcCon003** (Urban Rampage) | Caicara | Destruction challenge | `dlc01_state_dlccon003_spawns/pathfinding/atmofx` |
| **DlcCon004a** (Death Race) | Speed City | Racing | `dlc01_dlccon004_roads`, `dlc01_speedcity` |

### 2.2 World References Each Contract Needs

Based on the block inventory and vanilla contract patterns, each DLC contract expects:

**Terrain/geometry:**
- `dlc01_terrain_P000_Q3` — arena terrain mesh
- `dlc01_lowresterrain_P000_Q3` — low-res terrain grid
- `dlc01_caicara_P000_Q3` — Caicara city geometry
- `dlc01_caicara_foliage_P000_Q3` — foliage
- `dlc01_caicara_scrub_P000_Q3` — scrub vegetation
- `dlc01_caicara_roads_P000_Q3` — road geometry
- `dlc01_speedcity_P000_Q3` — Speed City geometry
- `dlc01_speedcity_roads_P000_Q3` — race track roads

**Placement/layer data:**
- `dlc01_base_P000_Q3` — base placements (entities always present in arena)
- `dlc01_commonlocations_P000_Q3` — named locations (spawn points, markers)
- `dlc01_state_missionhub_P000_Q3` — mission hub state
- `dlc01_state_dlccon003_spawns_P000_Q3` — DlcCon003 enemy spawn data
- `dlc01_state_dlccon003_P000_Q3` — DlcCon003 mission state
- `dlc01_state_dlccon003_pathfinding_P000_Q3` — AI pathfinding
- `dlc01_state_dlccon003_atmofx_P000_Q3` — atmosphere effects

**Mission-specific content:**
- `dlc01_dlccon001_P000_Q3` — DlcCon001 specific assets
- `dlc01_dlccon002_roads_P000_Q3` — DlcCon002 race track
- `dlc01_dlccon004_P000_Q3` — DlcCon004 specific assets
- `dlc01_dlccon004_roads_P000_Q3` — DlcCon004 race track
- 37× `c30XXX_P000_Q3` — cutscene/contract art assets

### 2.3 Contract Script Expectations (by analogy with vanilla)

From `contract_analysis_oil_vza.md`, vanilla contracts expect:

1. **Named locations** (string keys resolved by engine): spawn points, objective markers, boundaries
2. **VZ state layers** via `MrxLayerManager.MarkForAddition/Removal`
3. **Entity templates** referenced in `CreateChild({ sTemplate = "..." })`
4. **Named actors** via `Utility_GetActor("entity_name")`
5. **Position vectors** referenced by location name

DLC contracts follow the same pattern but their locations/entities live in the DLC arena blocks (`dlc01_base`, `dlc01_commonlocations`), NOT in Venezuela's `layers_static`.

### 2.4 The `IsDLC` / `DlcMapId` System

The engine has dedicated infrastructure for DLC level management:

| Field | VA | Purpose |
|-------|-----|---------|
| `IsDLC` | `0x7D9594` | Boolean: is session running DLC content? |
| `DlcMapId` | `0x7D9588` | Integer: which DLC map is active |
| `SetMasterScriptName` | `0x7BA6FC` | Set the DLC master script name |
| `GetMasterScriptName` | `0x7BA710` | Query current master script |

These are registered as Lua-callable functions, meaning the DLC master script is expected to set `IsDLC=true` and `DlcMapId=N` to tell the engine which arena to load.

---

## 3. DLC Arena Assets in vz-patch.wad

### 3.1 What's Currently Ported

`tools/dlc_port.py` converts **all 2,196 blocks** from the Xbox 360 DLC `DLC01.doh` into the PC `vz-patch.wad`. This includes:

| Category | Blocks | Status |
|----------|--------|--------|
| Terrain (`dlc01_terrain`, `dlc01_lowresterrain`) | 2 | Ported (geometry likely needs vertex byte-swap) |
| Caicara geometry (`dlc01_caicara*`) | 4 | Ported (vertex byte-swap needed) |
| Speed City geometry (`dlc01_speedcity*`) | 2 | Ported (vertex byte-swap needed) |
| Road geometry | 4 | Ported (vertex byte-swap needed) |
| Base placements (`dlc01_base`) | 1 | Ported (COMP placement byte-swap needed) |
| Common locations (`dlc01_commonlocations`) | 1 | Ported (COMP byte-swap needed) |
| State overlays (`dlc01_state_*`) | 5 | Ported (COMP byte-swap needed) |
| DLC contract assets | 4 | Ported |
| c3XXXX cutscene blocks | 37 | Ported (texture/mesh blocks) |
| Total | ~57+ named blocks | All 2,196 in WAD |

### 3.2 What's Still Broken (Byte-Swap Gaps)

From the comprehensive engine doc and DLC activation checklist:

| Data type | Format | Status | Impact |
|-----------|--------|--------|--------|
| STRM vertex data | Mixed f16/f32/u8 | **NOT swapped** | Arena geometry is garbage |
| COMP placement records | 42-byte with f32 fields | **NOT swapped** | Spawn points have wrong positions |
| Lua bytecode (BINN) | Lua 5.1 instructions/constants | **Swapped** (done in ucfx_be_to_le) | Scripts load correctly |
| Texture pixel data | DDS/DXT | **NOT de-swizzled** | Textures appear corrupted |
| UCFX headers | Magic + u32 fields | **Swapped** | Container structure parses |

### 3.3 Critical Gap: Layer Loading Mechanism

Even with correct byte-swapping, the engine needs to know **when** and **how** to load the DLC arena layers. Currently:

- `layers_static` = Venezuela's 62k entities (always loaded for the `vz` map)
- `vz_state_*` overlays = Venezuela state variants

The DLC's equivalent (`dlc01_base`, `dlc01_commonlocations`, `dlc01_state_*`) are in the WAD's ASET registry but **no code path loads them**. The engine only loads layers that are:
1. Referenced by the map's `layers_static` equivalent
2. Activated via `MrxLayerManager.MarkForAddition(layer_name)` from scripts
3. Part of the active map's terrain system

---

## 4. How Vanilla Level Transitions Work

### 4.1 Engine Architecture (from Mercs 1 Source)

From `RsLuaMission.cpp` and `RsMain.cpp`:

```cpp
// Master script loading
void RsLuaMission::SetMainMasterScriptName(const char* szScriptName)
{
    _uiMainMasterScriptNameHash = PblHash(szScriptName);
}

// Level start sequence
if (_uiMainMasterScriptNameHash != 0) {
    _MainMasterRsLuaState.OpenScript(_uiMainMasterScriptNameHash);
    _MainMasterRsLuaState.InvokeLuaFunction("ScriptInit");
}
```

### 4.2 The Venezuela Map Loading Sequence

```
1. Engine boots → reads config → master script name = "vz"
2. Opens vz.wad → processes INDX/DATA/ASET/PTHS
3. Opens vz-patch.wad (if exists) → overlays ASET
4. Loads terrain system: searches for low_res_terrain block → 20×20 tile grid
5. Loads layers_static: 62k base entity placements
6. Loads master script (pandemic_hash_m2("vz")) → ScriptInit()
7. ScriptInit → wifmissionflow → SetFlowData → Refresh cycle
8. Player enters freeplay
```

### 4.3 How Xbox 360 DLC Level Transition Worked

Based on `package.cfg` + `SetMasterScriptName` + `IsDLC`/`DlcMapId`:

```
1. Player selects DLC from Extras menu
2. Engine calls SetMasterScriptName("DLC01")
3. IsDLC = true, DlcMapId = (arena ID)
4. Engine performs level transition:
   a. Unloads current map (Venezuela terrain, layers, scripts)
   b. Searches WADs for DLC-specific blocks:
      - dlc01_terrain → new terrain system
      - dlc01_base → new layers_static equivalent  
      - dlc01_lowresterrain → new terrain grid
   c. Loads new master script: pandemic_hash_m2("dlc01") → ScriptInit()
5. DLC01 master script:
   a. Imports dlccon001..dlccon004a
   b. Registers missions in tMissionData  
   c. Sets up DLC-specific flow (all missions available immediately)
6. Player spawns in DLC arena (mission hub)
7. Accepts a challenge → contract Activated() has valid world references
```

### 4.4 The Missing Piece: Level Transition Trigger

The PC build has `SetMasterScriptName` registered as a Lua API function, and the `%s\%s-patch.wad` loading is automatic. But **there is no known mechanism to trigger a full level unload/reload from Lua**. The missing pieces:

1. What C++ function handles the level transition? (Not found in binary analysis)
2. Is it triggered by `SetMasterScriptName` alone, or does a separate `LoadLevel`/`TransitionLevel` call exist?
3. Does the terrain system automatically pick up `dlc01_terrain` when `DlcMapId` is set?

From Mercs 1: `Utility_ReadLevelFile()` loads level data. This is likely evolved in Mercs 2 but we haven't found the equivalent.

---

## 5. Feasibility Assessment of Approaches

### Approach A: Full Level Transition (Original DLC Behavior)

**Concept:** Replicate the Xbox 360 behavior — trigger a full level switch from Venezuela to the DLC arena.

**What's needed:**
1. Find or reverse-engineer the level transition mechanism in the PC EXE
2. Call `Sys.SetMasterScriptName("DLC01")` + trigger level reload
3. Ensure the engine correctly loads `dlc01_terrain` and `dlc01_base` as the new map
4. DLC master script runs in isolation (own terrain, own spawns, own layers)

**Feasibility: MEDIUM-LOW (3/10 confidence)**

| Pro | Con |
|-----|-----|
| Faithfully reproduces original behavior | Level transition mechanism not yet reverse-engineered |
| DLC scripts run unmodified | May require hooking into EXE at undiscovered function |
| Clean separation from Venezuela | `IsDLC`/`DlcMapId` C++ handlers unknown |
| Terrain system auto-picks up DLC terrain | Could cause crashes if partially implemented |
| | Return to Venezuela after mission unclear |

**Effort estimate:** 2-4 weeks of binary reverse engineering + testing

**Key unknowns:**
- Does `SetMasterScriptName` alone trigger a level reload?
- What manages the `dlc01_terrain` → terrain system handoff?
- How does the player return to Venezuela after completing a DLC mission?

### Approach B: Layer Overlay (Load DLC Layers into Venezuela)

**Concept:** Don't switch levels. Instead, load the DLC arena's placements as additional layers overlaid onto the existing Venezuela map, positioned in an empty region.

**What's needed:**
1. Fix COMP placement byte-swap (so DLC entity positions are correct)
2. Determine DLC arena's coordinate space — does it overlap Venezuela or use a separate region?
3. Load `dlc01_base` and `dlc01_commonlocations` via `MrxLayerManager.MarkForAddition`
4. Load `dlc01_terrain` geometry into the world
5. Teleport player to DLC arena region when mission starts
6. Teleport back to Venezuela when mission ends

**Feasibility: MEDIUM (5/10 confidence)**

| Pro | Con |
|-----|-----|
| No binary reverse engineering needed | DLC arena coordinates may overlap with Venezuela |
| Uses existing layer loading mechanisms | Terrain system designed for one terrain at a time |
| Lua-only implementation possible | Venezuela entities still active (performance) |
| Incremental — can test early | May confuse AI pathfinding |
| | Fog of war / minimap issues |

**Effort estimate:** 1-2 weeks (after byte-swap fixes)

**Critical question:** Do the DLC arena coordinates overlap with Venezuela? If the DLC arena uses coordinates like (0,0,0)-(500,0,500) and Venezuela occupies (-3900,0,-3900)-(3900,0,3900), there might be overlap at the center. We need to check the DLC's `dlc01_base` placement coordinates.

### Approach C: Script Adaptation (Rewrite DLC to Use Venezuela)

**Concept:** Rewrite the DLC contract scripts to work within the existing Venezuela map — use existing spawn points, locations, and terrain.

**What's needed:**
1. Decompile DLC contract bytecodes (unluac)
2. Identify all world references (locations, spawn points, templates)
3. Map each DLC reference to an equivalent Venezuela entity
4. Rewrite and recompile the contract scripts
5. Choose a region of Venezuela to serve as each "arena"

**Feasibility: HIGH (8/10 confidence, but significant creative work)**

| Pro | Con |
|-----|-----|
| No binary RE needed | Completely different experience from original DLC |
| No terrain/layer loading issues | Must find suitable Venezuela areas for each mission |
| Uses only proven mechanisms | Significant script rewriting effort |
| Guaranteed to work with current pipeline | Loses unique DLC arena aesthetics |
| Can test immediately | DlcCon002/004a races need designed road layouts |

**Effort estimate:** 1-3 weeks (depends on mission complexity)

**Major concern:** The DLC missions are **challenge arenas** with purpose-built terrain. A "Death Race" in the Venezuela open world would be a fundamentally different (and likely worse) experience than a purpose-built race track.

### Approach D: Hybrid — Remote Loading with Teleport

**Concept:** Load DLC terrain/layers into a far corner of the Venezuela world (outside the normal play area) and teleport the player there for DLC missions.

**What's needed:**
1. Fix COMP placement byte-swap for DLC layers
2. Offset all DLC coordinates by a large constant (e.g., X+10000, Z+10000) to place them outside Venezuela
3. Load DLC layers via `MrxLayerManager` when player accepts a DLC mission
4. Teleport player to offset coordinates
5. After mission: remove DLC layers, teleport back

**Feasibility: MEDIUM-HIGH (6/10 confidence)**

| Pro | Con |
|-----|-----|
| DLC assets render in their original form | Coordinate offset needed (transform all DLC placements) |
| No binary RE needed | Terrain system may not support two terrain grids |
| Lua-level implementation | Far-from-origin coordinates may cause floating-point issues |
| Clean separation from Venezuela gameplay | Loading 2,196 DLC blocks mid-game may hitch |
| | AI/streaming systems may not handle far coordinates |

**Effort estimate:** 2-3 weeks

**Key risk:** The engine's terrain system (`low_res_terrain`) is a 20×20 grid. Adding a second terrain grid at offset coordinates may not be supported. The streaming system (c3 spatial cells) is also grid-based and may not stream blocks at extreme offsets.

### Approach E: SetMasterScriptName + DLC Flag (Minimal Engine Cooperation)

**Concept:** Set `IsDLC=true` and `DlcMapId` via Lua, then call `SetMasterScriptName("DLC01")` to trigger whatever level transition the engine supports. Accept that this might be incomplete but test what happens.

**What's needed:**
1. Call `Sys.SetMasterScriptName("DLC01")` from the ASI bootstrap
2. Set `IsDLC` to true and `DlcMapId` to a value
3. Observe engine behavior — does it attempt a level transition?
4. If partial: supplement with manual layer loading

**Feasibility: MEDIUM (5/10 confidence — but very low effort to test)**

| Pro | Con |
|-----|-----|
| Uses engine's own DLC infrastructure | May do nothing (PC DLC never shipped) |
| Almost zero implementation effort to test | May crash if code paths are stubbed/incomplete |
| If it works, it's the correct solution | Unknown what `DlcMapId` values are valid |
| Proves or disproves engine capability quickly | May require return-path implementation |

**Effort estimate:** 1-2 days to test, 1-2 weeks if it partially works and needs supplementation

---

## 6. Recommended Approach

### 6.1 Phased Strategy (Risk-Adjusted)

**Phase 1: Test engine DLC support (1-2 days) — Approach E**

Before investing weeks in workarounds, test whether the PC engine's built-in DLC infrastructure works:

```lua
-- In ASI bootstrap, after tMissionData registration:
if Sys and Sys.SetMasterScriptName then
    Sys.SetMasterScriptName("DLC01")
    print("[dlc_enable] SetMasterScriptName('DLC01') called")
end
```

Also test setting IsDLC/DlcMapId if they're accessible from Lua. Record what happens:
- Does the engine attempt to load `dlc01_terrain`?
- Does it call `ScriptInit()` on the DLC01 script?
- Does it unload Venezuela?
- Does it crash?

**Phase 2: Fix byte-swap gaps (1 week) — Required for all approaches**

Regardless of which approach works, the DLC assets need correct byte-swapping:

1. **STRM vertex data** — implement per-format f16/f32/u8 swap in `ucfx_be_to_le.py`
2. **COMP placement records** — swap f32 position + quaternion fields
3. **Texture de-swizzle** — Xbox 360 GPU tiling reversal

This unblocks geometry rendering and correct entity placement for any approach.

**Phase 3: Based on Phase 1 results**

| Phase 1 Result | Next Step |
|----------------|-----------|
| Engine performs full level transition | **Done!** Fix remaining byte-swap issues, test thoroughly |
| Engine partially transitions (loads script, no terrain) | **Approach D** — supplement with manual layer/terrain loading |
| Engine does nothing / crashes | **Approach C** — script adaptation with Venezuela fallback |
| Engine does nothing but doesn't crash | **Approach B/D** — layer overlay or remote loading |

### 6.2 Why This Order

1. **Lowest risk first:** Testing `SetMasterScriptName` costs almost nothing
2. **Byte-swap is required regardless:** Every approach needs correct DLC data
3. **Fallback path is proven:** Script adaptation (Approach C) is guaranteed to work, just more effort
4. **Progressive enhancement:** Each phase adds functionality without regressing

### 6.3 Long-Term Vision

The ideal end state is **full level transition** (Approach A/E) because:
- Faithfully reproduces the original DLC experience
- DLC scripts run unmodified
- Clean separation from base game
- Sets precedent for future DLC/mod map support

But this depends on engine cooperation we haven't yet verified.

---

## 7. Quick Wins for Partial Functionality

### 7.1 Immediate (Today)

1. **Test `SetMasterScriptName`**: Add 3 lines to the ASI's Lua injection to call it and observe behavior. Zero risk.

2. **Log DLC contract world references**: After `dynamic_import("dlccon001")`, log what the script tries to access. Add error handlers around `Utility_GetActor`, `MrxLayerManager` calls to catch nil references. This maps out exactly what's missing.

3. **Check DLC arena coordinate space**: Decompress `dlc01_base` (after COMP byte-swap), parse placement records, and examine XYZ coordinates. If they're in a range like (0-500, 0-100, 0-500), they're clearly separate from Venezuela (-3900 to +3900).

### 7.2 Short-Term (This Week)

4. **Implement COMP byte-swap for DLC blocks**: The placement format is well-understood (42-byte records, documented in `docs/placement_data_format.md`). Swap the f32 fields in `ucfx_be_to_le.py`.

5. **Try MrxLayerManager approach**: Even without correct geometry, try loading `dlc01_commonlocations` and `dlc01_base` via Lua to see if the engine processes the placement data. If entities spawn (even at garbage positions), it proves the mechanism works.

6. **Decompile DLC contracts**: Run `unluac` on the byte-swapped DLC contract bytecodes to see their exact world references and flow.

### 7.3 Medium-Term (1-2 Weeks)

7. **Stub contract for testing**: Write a minimal DlcCon001 replacement that:
   - Inherits `MrxTaskContract`
   - Uses Venezuela spawn points (from existing `layers_static`)
   - Creates a simple destroy objective
   - Verifies the full contract lifecycle works

   This proves the mission registration → accept → activate → complete pipeline works independently of the arena loading problem.

8. **STRM vertex byte-swap**: Required for DLC geometry to render. Medium effort but well-understood problem.

---

## 8. Open Questions

### Critical (blocks all approaches)

| # | Question | How to Answer |
|---|----------|---------------|
| 1 | What happens when `SetMasterScriptName("DLC01")` is called mid-session? | Test in game with ASI |
| 2 | Do DLC arena coordinates overlap with Venezuela? | Parse `dlc01_base` COMP after byte-swap |
| 3 | Does the engine have a level-reload function callable from Lua? | Ghidra analysis of functions near `SetMasterScriptName` |

### Important (affects approach selection)

| # | Question | How to Answer |
|---|----------|---------------|
| 4 | Can `MrxLayerManager.MarkForAddition` load DLC-named layers from the patch WAD? | Test in game after COMP byte-swap |
| 5 | Does the terrain system support loading `dlc01_terrain` alongside `low_res_terrain`? | Ghidra analysis of terrain loader |
| 6 | What does `IsDLC()` check for internally? | Ghidra disassembly of its C++ implementation |
| 7 | Can the c3 streaming system handle blocks named `blocks\dlc01\*` or only `blocks\vz\*`? | Ghidra analysis of block path filtering |

### Nice to have

| # | Question | How to Answer |
|---|----------|---------------|
| 8 | What were the exact DLC arena boundaries? | Parse DLC terrain mesh extents |
| 9 | Did the DLC arena reuse any Venezuela assets? | Cross-reference ASET hashes between base WAD and DLC |
| 10 | How did the Xbox 360 handle returning from DLC to the main game? | `package.cfg` analysis / further RE |

---

## Appendix A: DLC Block Inventory (Full)

From `docs/xbox360_dlc_analysis.md`, all 57 named DLC block paths:

```
blocks\dlc01\dlc01_terrain_P000_Q3.block
blocks\dlc01\dlc01_caicara_foliage_P000_Q3.block
blocks\dlc01\dlc01_dlccon004_P000_Q3.block
blocks\dlc01\dlc01_base_P000_Q3.block
blocks\dlc01\dlc01_state_dlccon003_spawns_P000_Q3.block
blocks\dlc01\dlc01_commonlocations_P000_Q3.block
blocks\dlc01\dlc01_dlccon002_roads_P000_Q3.block
blocks\dlc01\dlc01_speedcity_roads_P000_Q3.block
blocks\dlc01\dlc01_speedcity_P000_Q3.block
blocks\dlc01\dlc01_caicara_scrub_P000_Q3.block
blocks\dlc01\dlc01_dlccon001_P000_Q3.block
blocks\dlc01\dlc01_lowresterrain_P000_Q3.block
blocks\dlc01\dlc01_state_dlccon003_P000_Q3.block
blocks\dlc01\dlc01_dlccon002_race_P000_Q3.block
blocks\dlc01\dlc01_caicara_P000_Q3.block
blocks\dlc01\dlc01_state_dlccon003_pathfinding_P000_Q3.block
blocks\dlc01\dlc01_state_missionhub_P000_Q3.block
blocks\dlc01\dlc01_state_dlccon003_atmofx_P000_Q3.block
blocks\dlc01\dlc01_dlccon004_roads_P000_Q3.block
blocks\dlc01\dlc01_caicara_roads_P000_Q3.block
blocks\dlc01\c30061_P000_Q3.block
blocks\dlc01\c30062_P000_Q3.block
blocks\dlc01\c30085_P000_Q3.block
blocks\dlc01\c30092_P000_Q3.block
blocks\dlc01\c30094_P000_Q3.block
... (37 c3XXXX blocks total)
```

## Appendix B: Comparison with Vanilla Layer Loading

### How vanilla contracts load their layers

```lua
-- In OilCon001.Activated():
MrxLayerManager.MarkForAddition("vz_state_mar_industrial_act1")
MrxLayerManager.MarkForRemoval("vz_state_mar_industrial_pristine")
```

This works because `vz_state_mar_industrial_act1` exists as a named UCFX block in `vz.wad`'s ASET with type_hash `0xE6B81A54` (layer).

### What DLC contracts would call

```lua
-- In DlcCon001.Activated() (hypothetical):
MrxLayerManager.MarkForAddition("dlc01_state_dlccon001")
MrxLayerManager.MarkForAddition("dlc01_base")
```

These blocks exist in `vz-patch.wad`'s ASET. The question is whether `MrxLayerManager` resolves layer names through the WAD overlay system (which it should, given last-opened-wins semantics).

## Appendix C: Engine DLC APIs Summary

| API | VA | Lua signature | Purpose |
|-----|-----|---------------|---------|
| `SetMasterScriptName` | `0x7BA6FC` | `Sys.SetMasterScriptName(name)` | Set DLC master script |
| `GetMasterScriptName` | `0x7BA710` | `Sys.GetMasterScriptName()` | Query current master script |
| `IsDLC` | `0x7D9594` | `IsDLC()` | Check if session is DLC |
| `DlcMapId` | `0x7D9588` | `DlcMapId()` or field access | Get active DLC map ID |
| `addLeaderboardEntry` | `0x7D01B4` | `addLeaderboardEntry(...)` | Register DLC leaderboard |

## Appendix D: Decision Tree

```
                    Test SetMasterScriptName("DLC01")
                           /              \
                    Engine reacts        Engine ignores
                      /       \                 |
             Full transition  Partial       Test MrxLayerManager
                   |           |           loading DLC layers
              DONE!         Need to              /          \
                            supplement       Works         Doesn't work
                                |              |                |
                         Approach D:      Approach D:      Approach C:
                         Hybrid          Remote loading   Script rewrite
                         (assist engine)  + teleport      (Venezuela fallback)
```

---

*This analysis should be updated after Phase 1 testing results are available. The Phase 1 test (calling `SetMasterScriptName`) is the single most important experiment — it either proves the engine handles DLC levels natively (in which case we're nearly done) or eliminates that path entirely (forcing us to workarounds).*
