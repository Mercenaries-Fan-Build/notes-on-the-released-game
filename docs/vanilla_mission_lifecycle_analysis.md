# Vanilla Mission Lifecycle Analysis

> **Source:** Lua 5.1 bytecode constant extraction from PC demo `scripts_vz` block
> **Date:** 2026-05-22
> **Purpose:** Understand exactly how vanilla missions are loaded, registered, and made visible so DLC missions can be activated post-initialization.

---

## 1. Architecture Overview

The mission system has three layers:

```
Layer 1: MrxMissionFlow (engine base class)
  ├── Refresh(), Reset(), SetFlowData(), GetOriginalFlowData()
  ├── UnlockMission(name), DestroyMission(name)
  ├── HasKey(name), AwardKey(name), GetKeyValue(name)
  └── Flow binding system (fPrereq/fConseq pairs)

Layer 2: WifMissionFlow (game subclass, inherits MrxMissionFlow)
  ├── GetOriginalFlowData() — returns the binding table
  ├── Reset() — calls MrxMissionFlow.Reset + SetFlowData(GetOriginalFlowData())
  └── Per-mission helper functions (_AddIntro, _RemoveIntro, _PlayMovie, etc.)

Layer 3: WifMissionData (data module, imported by wifmissionflow)
  ├── tMissionData = { MissionName = { fields... }, ... }
  └── Accessor functions (IsMissionAContract, GetMissionFaction, etc.)
```

---

## 2. tMissionData Structure (from wifmissiondata.luac)

Every mission entry in `tMissionData` has these fields:

### Required Fields

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `sModuleName` | string | Lua module name for the contract script | `"OilCon001"` |
| `sFactionId` | string | Faction code (`All`, `Chi`, `Gur`, `Oil`, `Pir`, `Pmc`, `Vza`) | `"Oil"` |
| `sStarter` | string | Starter NPC ID from wifstarterdata | `"OilStarter0"` |
| `bContract` | bool (implicit) | Absent = job, present = contract | (implicit from name pattern) |

### Optional Fields

| Field | Type | Description |
|-------|------|-------------|
| `bCriticalPathMission` | bool | Main story contract |
| `bPlayerVisibleMission` | bool | Shows in PDA. **Only** set on VzaCon001, OilCon020 (hidden missions) — defaults to visible |
| `bRepeatable` | bool | Can be replayed |
| `nLevels` | number | Multi-level mission (e.g. bounties with 10 levels) |
| `bCompletable` / `bCompleteable` | bool | Whether mission can complete (note: both spellings used) |
| `bSkipInitialNotifications` | bool | Suppress unlock popups |
| `bSuppressPdaDisplay` | bool | Hide from PDA list |
| `nPdaSortOrder` | number | Sort position in PDA |
| `sPdaTexture` | string | PDA icon asset name |
| `sTitle` | string | Localization key for title (e.g. `"[AllCon050.Title]"`) |
| `tLayers` | table | VZ state layers to manage |
| `tMilestones` | table | Milestone definitions (`{nMilestone=N, sKey="..."}`) |
| `tMaterielScale` | table | Faction-specific materiel scaling |
| `tStartLocations` | table | Named start points for the mission |

### Key Observation: bContract is Implicit

`IsMissionAContract(sMissionId)` works by calling `MrxUtil.ExplodeMissionName(sMissionId)` to parse the name pattern, checking `bContract` on the entry, OR inferring from the name itself. The name convention is:
- `*Con*` = Contract (main storyline missions)
- `*Job*` = Job (side activities — bounties, destroy missions, verify missions)

### SetMissionData Function

```lua
function SetMissionData(tNewMissionData)
    tMissionData = tNewMissionData  -- replaces entire table
end
```

This is a **full replacement**, not a merge. The accessor functions (`GetMissionFaction`, `GetMissionStarter`, etc.) all read from `tMissionData[sMissionId]` directly.

---

## 3. WifMissionFlow: The Flow Binding System

### 3.1 GetOriginalFlowData() — The Core

`wifmissionflow.luac` contains a massive function at line 55 with **93 child closures** — this is `GetOriginalFlowData()`. It returns a table of **flow bindings**, each with this structure:

```lua
{
    "BindingName",
    fPrereq = function() ... end,   -- prerequisite check
    fConseq = function() ... end,   -- consequence when prereq becomes true
}
```

The flow system works as a **reactive binding graph**:
1. `SetFlowData(bindings)` registers all bindings with the engine
2. The engine periodically calls `Refresh()` which evaluates each binding's `fPrereq`
3. When a prereq returns true, the corresponding `fConseq` fires
4. `fConseq` typically calls `UnlockMission(name)` and other setup

### 3.2 Flow Binding Examples (from bytecode)

**Start → VzaCon001:**
```lua
fPrereq: function() end  -- always true (empty = no prereq)
fConseq: function()
    UnlockMission("VzaCon001")
    -- setup cheat mode check, state transition
end
```

**VzaCon001 → PmcCon001:**
```lua
fPrereq: function() return HasKey("VzaCon001") end
fConseq: function()
    UnlockMission("PmcCon001")
    MrxSoundBootstrap.SetPmcRadio("ReporterNeutral.MissionVO.VZCon01")
end
```

**OilCon050 → OilCon001 + OilCon051:**
```lua
fPrereq: function() return HasKey("OilCon050") end
fConseq: function()
    _BeginBlockingSequence()
    UnlockMission("OilCon001")
    UnlockMission("OilCon051")
    MrxLayerManager.MarkForRemoval("vz_state_mar_altagracia_act1")
    MrxLayerManager.MarkForAddition("vz_state_mar_altagracia_act2")
    _ChangeOutpostStaging()
    _EndBlockingSequence()
end
```

### 3.3 Reset() Function

```lua
function Reset(bResetMore)
    MrxMissionFlow.Reset()        -- engine-level reset
    SetFlowData(GetOriginalFlowData())  -- re-register all bindings
end
```

**This is critical:** `Reset()` rebuilds the entire flow graph from `GetOriginalFlowData()`. After reset, `Refresh()` re-evaluates all bindings.

### 3.4 Full Binding Chain (mission unlock order)

From the bytecode, the flow DAG is:

```
Start
  └→ VzaCon001
      └→ PmcCon001
          └→ OilCon020 (+ OilCon021)
              └→ OilCon021
                  └→ OilCon002 + OilJob011
              └→ PmcCon002
                  ├→ MecIntro → MecCon001
                  ├→ JetIntro → JetCon001  
                  └→ PmcCon003
                      └→ AllChiIntro → AllCon050 + ChiCon050
                          └→ PmcCon004 (endgame)
              └→ OilCon050 → OilCon001 + OilCon051
                  └→ OilCon001 + GurCon001 → PmcCon002
              └→ GurCon053 → GurCon002 → GurCon003 → GurCon001
              └→ PirIntro → PirCon001
```

---

## 4. OilCon001: Anatomy of a Contract Script

From `oilcon001.luac`, a contract is a Lua module that:

### 4.1 Inheritance
```lua
inherit("MrxTaskContract")  -- inherits base contract behavior
```

### 4.2 Imports
```lua
import("MrxSubtitle")
import("MrxUtil")
import("MrxApcDrop")
import("MrxVoSequence")
import("MrxMissionBoundary")
import("DangerousBuilding")
import("MrxSupportData")
import("MrxCopterDrop")
```

### 4.3 Lifecycle Methods

The module defines these key entry points:
- `LoadAssets` — preload textures, sounds; set up VZ state layers
- `Activated` — mission starts; spawn entities, create objectives
- `Cancel` — player cancels or mission fails
- `Cleanup` — remove spawned entities, restore layers
- `MissionComplete` — fade out exec, call `Complete()`

### 4.4 Objectives (child tasks)

OilCon001 creates child objectives via `CreateChild()`:
```lua
CreateChild({
    sName = "oc001 go to",
    sModuleName = "MrxTaskObjectiveDeliver",  -- engine module
    vDestLoc = "refinery_doc_warehouse01",
    fDist = 120,
    sDspShortDesc = "[OilCon001.Objectives.001]",
    fOnComplete = ...,
    fOnCancel = "_MyCancel",
})
```

### 4.5 What UnlockMission Does Internally

Based on game logs and bytecode analysis, `UnlockMission(name)` does:

1. Looks up `tMissionData[name]` for the mission config
2. Creates a **task tree node** under `"Missions"` parent:
   - Adds `"ChiCon009"` as child of `"Missions"`
   - Adds `"ChiCon009Mission"` as child of `"ChiCon009"` 
   - Adds `"ChiCon009Briefing"` as child of `"ChiCon009"`
3. Resolves the `sStarter` → looks up starter config in wifstarterdata
4. Activates the starter NPC (spawns at HQ, makes interactable)
5. Sets up the HQ outpost (loads data, marks as available)
6. Awards the mission key via `AwardKey(name)`

The log output confirms:
```
Unlocking mission ChiCon009
Adding ChiCon009 as a child of Missions
Adding ChiCon009Mission as a child of ChiCon009
Adding ChiCon009Briefing as a child of ChiCon009
Starter activated!
HQ ChiOutpost4 could not be retrieved
Attempting to unlock HQ ChiOutpost4
Loading data for HQ ChiOutpost4
HQ ChiOutpost4 setup complete
```

---

## 5. Starter System (from wifstarterdata.luac)

Each starter has:
```lua
{
    sPlayerVisibleName = "[SO0.Name]",
    sHqName = "OilHq",
    tActors = {
        {Starter = {sTemplate="OC Boss (phone)", sPosition="Hp_starter"}},
    },
    bBoss = true,
    bFemale = false,
    sVoBankName = "Marlowe",  -- for voice
    tAssetPreload = { wavebank="vo_job_up_Marlowe", ... },
    sFaceFxSet = "OIL_Job_Briefing_Marlowe",
    tCardData = { sFaction="OC", sTitle="...", ... },
}
```

The `Init()` function in wifstarterdata builds a faction→starters lookup:
```lua
_sStarters = {
    All = {AllStarter0..AllStarter4},
    Chi = {ChiStarter0..ChiStarter4},
    Gur = {GurStarter0..GurStarter5},
    Oil = {OilStarter0..OilStarter5},
    Pir = {PirStarter1,PirStarter3,PirStarter4},
    Pmc = {HelPmcBoss, JetBoss, JetPmcBoss, MecBoss, MecPmcBoss, PmcBoss},
}
```

**For DLC:** Using `sStarter = "PmcBoss"` is correct — Fiona is the PMC starter.

---

## 6. HQ System (from wifhqdata.luac)

Each HQ has:
```lua
_tHqConfigs = {
    OilHq = {
        tInterior = { sTemplate = "OilHq_Interior" },
        tPortal = { sEntrance="...", sStart1="...", sStart2="..." },
        sPdaIcon = "icon_oc_HQ_mc",
        sRadarIcon = "MiniMap_Icon_Faction_OC",
        sBlipLabel = "[poi.oilhq]",
        sAtmosphere = "oil",
        sParkingLot = "07_all_hq_parking",
    },
}
```

`UnlockMission` references HQ data through the starter's `sHqName` field.

---

## 7. Briefing System (from wifbriefingdata.luac)

Briefings define per-mission:
```lua
{
    nType = knContact,  -- or knSimple, knRecruit
    tAssetPreload = { soundbank="vo_oilCon001", ... },
    tActors = { ... },
    tPositions = { ... },
    tFaceAnimSets = { ... },
    tCinematic = {
        tAnims = { ... },
        OnTime = ..., OnComplete = ...,
        tFlash = { sFile = "OilCon001_briefing.gfx" },
        tCamera = { bHold = true },
    },
    tDeclineCinematic = { ... },
    tConfirmCinematic = { ... },
}
```

**For DLC:** Without briefing data, the mission will either crash on briefing or use a default. DLC contracts likely need entries in `wifbriefingdata` too, or the scripts handle briefings internally.

---

## 8. dynamic_import — The Key to Runtime Loading

From the EXE bootstrap string (confirmed at offset `0x007B4EE2`):

```lua
function _G.import(module)
    return _SYS._IMPORT(_SYS._GETFENV(2) or _G, module);
end;

function _G.dynamic_import(module, callbackfunc, callbackdata)
    return _SYS._DYNAMIC_IMPORT(_SYS._GETFENV(2) or _G, module, callbackfunc, callbackdata);
end;

function _G.inherit(module)
    return _SYS._INHERIT(_SYS._GETFENV(2) or _G, module);
end;

function _G.dynamic_remove(module)
    return _SYS._DYNAMIC_REMOVE(_SYS._GETFENV(2), module);
end;
```

### Key differences:

| Function | Mechanism | Env | Loading |
|----------|-----------|-----|---------|
| `import(m)` | `_SYS._IMPORT(caller_env, m)` | Caller's fenv | Synchronous, scripts_vz only |
| `dynamic_import(m, cb, data)` | `_SYS._DYNAMIC_IMPORT(caller_env, m, cb, data)` | Caller's fenv | **Async, any loaded WAD block** |
| `inherit(m)` | `_SYS._INHERIT(caller_env, m)` | Caller's fenv | Synchronous, copies exports |

**`dynamic_import` is the only function that can load scripts from non-scripts_vz blocks** (like block 464 where DLC contracts live). The game log confirms it's used: `"Dynamically imported module MrxTask"`.

---

## 9. The Problem and Solution

### 9.1 Current State

1. DLC entries written to `tMissionData` ✓
2. `UnlockMission()` called ✓
3. But `UnlockMission()` **depends on the flow system being in the right state**:
   - It creates task tree nodes using engine C++ APIs
   - It needs the starter manager to have the starter NPC
   - It needs the HQ manager to have the HQ config
   - **Most critically: `UnlockMission` only works when called from within a `fConseq` callback during `Refresh()`** — it's a method on `MrxMissionFlow`, which operates in the wifmissionflow module environment

### 9.2 Why Current UnlockMission Calls Fail

When called from the ASI's injected Lua chunk:
1. `UnlockMission` is found in `_MODULES.wifmissionflow` ✓
2. But when called externally, its `self` context (the task tree, the flow state) may not be set up correctly
3. The function likely uses upvalues or module-local state that require being called within the flow evaluation context
4. Even if the call "succeeds" (no error), it may create task nodes that aren't connected to the active task tree

### 9.3 Recommended Approach: Reset the Flow System

Based on the bytecode analysis, the correct sequence after writing `tMissionData` entries is:

```lua
-- Step 1: Ensure DLC entries exist in tMissionData (already done)
-- This writes to wifmissiondata's module environment

-- Step 2: Inject DLC bindings into GetOriginalFlowData
-- The flow data needs new fPrereq/fConseq pairs for DLC missions

-- Step 3: Call Reset() to rebuild the flow graph
-- WifMissionFlow.Reset() calls:
--   MrxMissionFlow.Reset()  -- clears existing bindings
--   SetFlowData(GetOriginalFlowData())  -- rebuilds with new data

-- Step 4: The next Refresh() cycle will evaluate all bindings
-- DLC missions with satisfied prereqs will auto-unlock
```

### 9.4 Specific Implementation

```lua
-- In the ASI injected Lua chunk:

-- 1. Find the wifmissionflow module environment
local flow_env = nil
local data_env = nil
for k, v in pairs(_MODULES) do
    if v and v.UnlockMission then
        flow_env = v
    end
    if v and v.tMissionData then
        data_env = v
    end
end

-- 2. Register DLC missions in tMissionData
data_env.tMissionData['DlcCon001'] = {
    sModuleName = 'dlccon001',
    sFactionId = 'Pmc',
    sStarter = 'PmcBoss',
    bCriticalPathMission = false,
}
-- ... (repeat for DlcCon002, DlcCon003, DlcCon004a)

-- 3. Option A: Direct UnlockMission with proper env
-- Set our chunk's env to the flow module env so upvalue resolution works
if setfenv then
    setfenv(1, flow_env)
end
for _, name in pairs({'DlcCon001','DlcCon002','DlcCon003','DlcCon004a'}) do
    pcall(UnlockMission, name)
end

-- 3. Option B: Reset the flow system (nuclear option)
-- This replays the entire mission unlock chain
if flow_env.Reset then
    flow_env.Reset(false)  -- bResetMore = false
end

-- 3. Option C: Manually call dynamic_import for each DLC script
-- This loads the contract bytecodes from block 464
for _, name in pairs({'dlccon001','dlccon002','dlccon003','dlccon004a'}) do
    dynamic_import(name)
end
-- Then UnlockMission for each
```

### 9.5 The Best Path Forward

**Option C (dynamic_import) is the most promising** because:

1. It uses the engine's native async loading (`_SYS._DYNAMIC_IMPORT`)
2. It can find scripts in ANY loaded WAD block (including the DLC patch WAD's block 464)
3. The game already uses it (`"Dynamically imported module MrxTask"`)
4. The contract scripts themselves call `inherit("MrxTaskContract")` and set up their own lifecycle hooks — they're self-contained

The sequence should be:

```lua
-- Phase 1: Register in tMissionData (current code, works)
data_env.tMissionData['DlcCon001'] = { ... }

-- Phase 2: Load contract scripts via dynamic_import
-- This executes the script in the caller's env, which registers
-- the module in _MODULES and sets up the contract class
dynamic_import("dlccon001")
dynamic_import("dlccon002")
dynamic_import("dlccon003")
dynamic_import("dlccon004a")

-- Phase 3: Add flow bindings for DLC missions
-- We need to add new fPrereq/fConseq pairs to the flow system
-- The simplest prereq: always true (DLC is always available)
-- Then UnlockMission from within the flow context

-- Phase 4: If flow system is already initialized, trigger
-- either Reset() or directly call UnlockMission from within
-- flow_env scope:
if setfenv then
    local saved = getfenv(1)
    setfenv(1, flow_env)
    for _, name in pairs({'DlcCon001','DlcCon002','DlcCon003','DlcCon004a'}) do
        UnlockMission(name)
    end
    setfenv(1, saved)
end
```

### 9.6 Why Reset() Might Be Dangerous

Calling `Reset()` re-evaluates the **entire** flow graph. Since the player has already progressed, `HasKey()` will return true for completed missions, and the `fConseq` callbacks will fire again. This could:
- Re-play movies
- Re-unlock already-completed missions  
- Trigger layer changes
- Cause blocking sequences

The `IsSkipModeEnabled` check in many `fConseq` functions suggests the game handles this (skip mode bypasses blocking sequences), but it's risky.

### 9.7 Recommended: Surgical UnlockMission in Flow Env

The safest approach combines tMissionData registration with scoped UnlockMission calls:

```lua
-- 1. Register entries
data_env.tMissionData['DlcCon001'] = {
    sModuleName = 'dlccon001',
    sFactionId = 'Pmc',
    sStarter = 'PmcBoss',
    bCriticalPathMission = false,
    nPdaSortOrder = 100,
}

-- 2. dynamic_import the contract scripts (loads from any WAD)
dynamic_import("dlccon001")
-- etc.

-- 3. Call UnlockMission in the flow module's env
-- This ensures UnlockMission has access to all its dependencies
-- (the task tree, starter manager, HQ manager, etc.)
if setfenv then
    local saved = getfenv(1)
    setfenv(1, flow_env)
    UnlockMission("DlcCon001")
    setfenv(1, saved)
end
```

---

## 10. Open Questions

1. **Does `dynamic_import` work for scripts in the patch WAD?** The engine resolves modules by ASET hash from all loaded WADs (confirmed by "last-opened-file wins"). If block 464 has the right ASET entries, `dynamic_import("dlccon001")` should find the script.

2. **What is `UnlockMission`'s exact calling convention?** Is it `self:UnlockMission(name)` (method call with task tree context) or `UnlockMission(name)` (plain function)? The bytecode shows it called as `UnlockMission("VzaCon001")` without self, suggesting it's a plain function in the module environment that accesses engine state through its closure/upvalue chain.

3. **Does the starter manager need pre-registration?** The log shows "Starter activated!" which means `MrxStarterManager` creates the NPC. If the DLC starter (`PmcBoss`) is already active (it's Fiona, always available), this should work. But DLC missions might need their own starters.

4. **Can we call `UnlockMission` outside the Refresh cycle?** The function might only work during `MrxMissionFlow.Refresh()`. If so, we need to inject a binding into the flow data and trigger a refresh.

5. **What does `_SYS._DYNAMIC_IMPORT` need in its env parameter?** If we pass `_G`, the imported module's globals go to `_G`. If we pass the flow env, they go to the flow module's scope. The correct env depends on what the DLC scripts expect.
