# Mercenaries 1 Engine Source Analysis — Mapping to Mercenaries 2

## Executive Summary

The Mercenaries: Playground of Destruction source code (codename "RetroStrike" / "Delta") reveals a **two-layer engine architecture**:

1. **RedEngine** — Core reusable engine (rendering, world management, asset I/O, animation, physics, terrain, effects)
2. **RetroStrike/Rs** — Game-specific logic (actors, AI, missions, Lua scripting, vehicles, combat)

Both layers are C++ with platform-specific implementations for PS2 and Xbox. The engine uses **Lua 5.0.1** for game scripting (Mercs 2 upgraded to **Lua 5.1**). The asset system uses a **hash-based virtual disk** — the direct ancestor of the FFCS/WAD system in Mercs 2.

---

## 1. Engine Subsystem Inventory

### RedEngine Core (`Projects/RedEngine/Source/`)

| Subsystem | Files | Purpose | Likely Mercs 2 Equivalent |
|-----------|-------|---------|--------------------------|
| **RedVirtualDisk** | `RedVirtualDisk.cpp/h`, `RedFileInfo.h` | WAD/asset file I/O, hash-based directory, "last opened wins" priority | FFCS WAD system (evolved significantly) |
| **RedWorld** | `RedWorld.cpp/h` | Entity/Spore system, property data, world file loading | UCFX placement system, layers_static |
| **RedGridCache** | `RedGridCache.cpp/h` | Spatial streaming grid for world sectors | Block streaming grid in Mercs 2 |
| **RedLookUp** | `RedLookUp.cpp/h` | Hash→string reverse lookup table (debugging) | Likely exists but compiled out in retail |
| **RedActor** | `RedActor.cpp/h` | Base entity with rendering component | SceneObject base class |
| **RedModel** | `RedModel.cpp/h` | 3D model loading & rendering | UCFX mesh containers |
| **RedTerrain** | `RedTerrain.cpp/h` | Terrain rendering, height queries | `low_res_terrain` UCFX tiles |
| **RedAnimation** | `RedAnimation.cpp/h` | Animation system core | Havok 5.5 animation in Mercs 2 |
| **RedTexture** | `RedTexture.cpp/h` | Texture management | DDS texture blocks |
| **RedRenderer** | `RedRenderer.cpp/h` | Platform render abstraction | D3D9 renderer in Mercs 2 |
| **RedScene** | `RedScene.cpp/h` | Scene graph management | Scene hierarchy |
| **RedSkeleton** | `RedSkeleton.cpp/h` | Skeletal system | Havok skeletons |
| **RedEffect/EffectSystem** | `RedEffect*.cpp/h` | Particle/effect system | Particle placements |
| **RedLight** | `RedLight.cpp/h` | Dynamic lighting | ECS LightObject entities |
| **RedPhysics/PhysicsModule** | `RedPhysics*.cpp/h` | Physics abstraction layer | Havok physics |
| **RedPath** | `RedPath.cpp/h` | AI pathfinding data | Path network |
| **RedSpace** | `RedSpace.cpp/h` | Spatial partitioning | Spatial manager |
| **RedMemory** | `RedMemory.cpp/h` | Memory management, pools | Custom allocators |
| **RedSoundSystem** | `RedSoundSystem.cpp/h` | Audio abstraction | XACT/sound system |
| **RedWater/WaterOcean** | `RedWater*.cpp/h` | Water rendering | Water planes |
| **RedCanvas** | `RedCanvas.cpp/h` | 2D UI rendering surface | UI system |
| **RedFont** | `RedFont.cpp/h` | Font rendering | Font rendering |
| **Zephyr (Animation)** | `Zephyr*.cpp/h` | Advanced animation blending/joints | Replaced by Havok in Mercs 2 |

### RetroStrike Game Logic (`Projects/RetroStrike/Source/`)

| Subsystem | Key Files | Purpose | Mercs 2 Equivalent |
|-----------|-----------|---------|-------------------|
| **Lua Scripting** | `RsLuaState`, `RsLuaScript`, `RsLuaMission`, `RsLuaEvent`, `RsLuaUserData` | Full Lua binding layer | `_SYS.*` Lua bindings, `import()` system |
| **Mission System** | `RsMissionDataManager`, `RsLuaMission` | Mission data, flow, objectives | `wifmissiondata`, `wifmissionflow` |
| **Actor System** | `RsActor*` (50+ files) | Entities: vehicles, humans, buildings, props | SceneObject hierarchy |
| **AI System** | `RsAi*` (20+ files) | AI behaviors, commands, squads | AI subsystem |
| **Vehicle System** | `RsActorVehicle*` | Cars, tanks, helicopters, airplanes | Vehicle physics |
| **Physics** | `RsHavok*` | Havok 2.2/2.3 integration | Havok 5.5 |
| **Traffic** | `RsTrafficManager` | Traffic spawning, zones | Traffic system |
| **Faction/Diplomacy** | `RsFactionRelation` | Faction attitudes, relations | Faction system |
| **World/Entity Mgmt** | `RsWorld` | Spore system, spawning, hibernation | `layers_static` + `vz_state` |
| **Camera** | `RsCamera*` | Multiple camera modes | Camera system |
| **HUD/UI** | `RsHud`, `RsFrontEnd*`, `RsDesktopDisplay` | In-game UI | WIF (World Interface) system |
| **Briefings** | `RsBriefing` | Mission briefing scenes | Briefing system |
| **Encounters** | `RsEncounter` | Squad encounters, combat areas | Encounter system |
| **Save/Load** | `RsLoadSaveGame*`, `RsScribble` | Persistent state | Save system |
| **Damage** | `RsDamage` | Damage tables, locational | Damage system |
| **Cheats** | `RsCheats` | Debug cheats | Cheat system |

### Platform Layer (Pebble `Projects/Pebble/`)

The `Pbl*` prefix denotes platform-abstraction classes:
- `PblFile`, `PblDiscFile`, `PblStream`, `PblStreamManager` — I/O
- `PblThread` — Threading
- `PblHash`, `PblHashTable` — Hashing (the predecessor to `pandemic_hash_m2`)
- `PblChunk` — Binary chunk reader (the ancestor of UCFX chunk parsing)
- `PblCompress` — LZSS compression (replaced by `sges` deflate in Mercs 2)
- `PblConfig` — Config/INI file reader
- `PblRandom` — Random number generation
- `PblVector`, `PblMatrix`, `PblTransform` — Math types

---

## 2. Lua Binding API — Complete Function Registry

### Lua Version

**Mercenaries 1: Lua 5.0.1** (2003)  
**Mercenaries 2: Lua 5.1** (float build, 2006)

Key differences:
- Lua 5.0 uses `lua_dobuffer()` to execute scripts; Lua 5.1 uses `luaL_loadbuffer()` + `lua_pcall()`
- Lua 5.0 has no `luaL_openlibs()`; individual libs opened via `luaopen_base()`, `luaopen_table()`, etc.
- Lua 5.0 GC uses `lua_setgcthreshold()`; Lua 5.1 uses incremental GC API
- Lua 5.1 adds the `module()` function and `require()` system (Mercs 2's `import()` is custom)

### Registered C Functions (via `kLuaBaseFns[]`)

All functions follow the pattern: `static int FunctionName(lua_State* pLuaState)` — standard Lua C function signature.

#### Debug Functions
| Lua Name | C Function | Purpose |
|----------|-----------|---------|
| `Debug_Assert` | `Debug_Assert` | Trigger assertion |
| `Debug_Break` | `Debug_Break` | Debugger breakpoint |
| `Debug_EnableCallStack` | `Debug_EnableCallStack` | Enable callstack tracing |
| `Debug_EnableDebugMenu` | `Debug_EnableDebugMenu` | Toggle debug menu |
| `Debug_EnableLocationRendering` | `Debug_EnableLocationRendering` | Render location markers |
| `Debug_Printf` | `Debug_Printf` | Print to debug TTY |
| `Debug_PrintEventDiagnostics` | `Debug_PrintEventDiagnostics` | Dump event system state |
| `Debug_PrintMemoryStatistics` | `Debug_PrintMemoryStatistics` | Lua memory usage |

#### UI/HUD Functions
| Lua Name | Purpose |
|----------|---------|
| `Ui_PrintHudMessage` | Display HUD text |
| `Ui_PrintHudMessageById` | Display localized HUD text |
| `Ui_DisplayLeftVideoPortrait` | Show NPC portrait (left) |
| `Ui_DisplayRightVideoPortrait` | Show NPC portrait (right) |
| `Ui_EnableHud` | Toggle HUD visibility |
| `Ui_EnableFlagMode` | Toggle flag mode display |
| `Ui_SetFactionMoodVisible` | Show/hide faction mood |
| `Ui_AddDisplayMarkerActor` | Add map marker on actor |
| `Ui_RemoveDisplayMarkerActor` | Remove actor marker |
| `Ui_AddChallengeMarkerActor` | Challenge map marker |
| `Ui_RemoveChallengeMarkerActor` | Remove challenge marker |
| `Ui_ObjectiveTrayPrint` | Show objective text |
| `Ui_TutorialTrayPrint` | Show tutorial text |
| `Ui_MessageBoxPrint` | Show message box |
| `Ui_MessageBoxClear` | Clear message box |
| `Ui_DisplayDateline` | Show date/location text |

#### Actor/Vehicle Functions
| Lua Name | Purpose |
|----------|---------|
| `ActorVehicle_EnableRotorEffects` | Helicopter rotor FX |
| `ActorVehicle_GetNumPassengers` | Query passenger count |
| `ActorVehicle_GetSeatInfo` | Query seat occupancy |
| `ActorVehicle_GetWinchedActor` | Get winched actor |
| `ActorVehicle_IsExtractionHelicopter` | Check if extraction heli |
| `ActorVehicle_KickoutPassenger` | Eject single passenger |
| `ActorVehicle_KickOutAllPassengers` | Eject all passengers |
| `ActorVehicle_ReceiveRider` | Force actor into vehicle |
| `ActorVehicle_Lock` | Lock/unlock vehicle |
| `ActorVehicle_GetRiderList` | Get all riders |
| `ActorVehicle_SpawnCargo` | Spawn cargo drop |
| `ActorVehicle_TakeFriendlyFire` | Enable/disable FF |

#### AI Command Functions
| Lua Name | Purpose |
|----------|---------|
| `Ai_Deliver` | Order delivery |
| `Ai_IsPassenger` | Check if AI is passenger |
| `Ai_Land` | Order helicopter land |
| `Ai_MoveToPositionAndHeading` | Navigate to point |
| `Ai_PlaceOnClosestTerrain` | Snap to terrain |
| `Ai_Takeoff` | Order takeoff |
| `Ai_SetFaction` | Change AI faction |
| `Ai_GetFaction` | Query AI faction |
| `Ai_SetHostileRange` | Set aggression range |
| `Ai_SetIsHostage` | Mark as hostage |
| `Ai_SetIsAwaitingExtraction` | Mark for extraction |
| `Ai_SetSquad` | Assign to squad |
| `Ai_AddEnemy` | Add specific enemy |
| `Ai_Anchor` / `Ai_Unanchor` | Pin/unpin position |
| `Ai_EnableHornResponse` | React to horn |
| `Ai_SetFactionFavor` | Set faction standing |
| `Ai_Command` | Immediate AI command |
| `Ai_CommandQueue` | Queued AI command |
| `Ai_CommandDefault` | Default behavior |
| `Ai_CommandClear` / `ClearAll` | Cancel commands |
| `Ai_CommandStatus` | Query command status |

#### Faction Functions
| Lua Name | Purpose |
|----------|---------|
| `Faction_GetAttitude` | Get faction attitude |
| `Faction_GetRelation` | Get numerical relation |
| `Faction_SetRelation` | Set relation value |
| `Faction_ModifyRelation` | Adjust relation |
| `Faction_SetMinimumRelation` | Set relation floor |

#### Camera Functions
| Lua Name | Purpose |
|----------|---------|
| `Camera_SetMode` | Change camera mode |
| `Camera_SetPosition` | Set camera pos |
| `Camera_SetInterestPosition` | Set look-at point |
| `Camera_SetInterestActor` | Look at actor |
| `Camera_MoveToPosition` | Smooth camera move |
| `Camera_SetOrbit` / `SetPan` | Orbital/pan mode |
| `Camera_AttachToActor` / `DetachFromActor` | Attach/detach |
| `Camera_SetZoom` | Zoom level |
| `Camera_Shake` | Screen shake |
| `Camera_ScriptPlayAnimation` | Scripted anim |
| `Camera_ScriptDriveActor` | Drive actor cam |
| `Camera_Reset` | Reset camera |

#### Mission/Spawn Functions
| Lua Name | Purpose |
|----------|---------|
| `Mission_EnableAtmosphere` | Toggle atmosphere effects |
| `Mission_EnableGlobalGpsJammer` | Block GPS globally |
| `Mission_GetTime` | Get mission elapsed time |
| `Mission_PlayerRespawn` | Respawn player |
| `Mission_Spawn` | Spawn actor by ODF |
| `Mission_SpawnAirplaneFlyby` | Spawn flyby aircraft |
| `Mission_SpawnAirstrike` | Call in airstrike |
| `Mission_SetupPlayerRespawn` | Set respawn point |

#### Event System Functions
| Lua Name | Purpose |
|----------|---------|
| `Event_ActorHitPointsLessThan` | Watch HP threshold |
| `Event_ActorInBoundary` | Watch boundary enter/exit |
| `Event_ActorInFiremansCarry` | Watch pickup/drop |
| `Event_ActorIsAirborne` | Watch airborne state |
| `Event_ActorIsHostileToward` | Watch hostility |
| `Event_ActorInFocus` | Watch binocular focus |
| `Event_ActorIsSubdued` | Watch subdued state |
| `Event_ActorIsDormant` | Watch dormancy |
| `Event_ActorSold` | Watch chop shop sale |
| `Event_ActorToVectorProximity` | Proximity to point |
| `Event_ActorToLocationProximity` | Proximity to location |
| `Event_ActorToActorProximity` | Proximity to actor |
| `Event_ActorUsed` | Watch actor use |
| `Event_ActorVerified` | Watch verification |
| `Event_ActorCaptured` | Watch capture |
| `Event_CancelEvent` | Cancel existing event |
| `Event_RelativeTimer` | Countdown timer |
| `Event_SkipCinematic` | Wait for skip input |
| `Event_FactionAttitudeChange` | Watch diplomacy change |
| `Event_SquadStatus` | Watch squad health |
| `Event_PlayerEquipsNamedItem` | Watch item equip |
| `Event_PlayerUsesWeapon` | Watch weapon use |

#### Player Functions
| Lua Name | Purpose |
|----------|---------|
| `Player_SetCurrentWeapon` | Force weapon |
| `Player_SetWeaponEnabled` | Enable/disable weapon |
| `Player_RefillWeaponAmmo` | Refill ammo |
| `Player_GetMoney` / `SetMoney` / `AdjustMoney` | Money management |
| `Player_ShowMoney` | Display money popup |
| `Player_DisableControl` / `EnableControl` | Control lock |
| `Player_SpecialAttach` / `SpecialDetach` | Attach to vehicle |
| `Player_SetHumanModel` | Change player model |

#### Objective Functions
| Lua Name | Purpose |
|----------|---------|
| `Objective_SetShortDescription` | Set brief text |
| `Objective_SetLongDescription` | Set full text |
| `Objective_SetType` | Set objective type |
| `Objective_SetTargetActor` | Set target on actor |
| `Objective_SetTargetVector` | Set target at position |
| `Objective_RemoveTarget` / `Remove` | Remove objective |

#### Utility Functions
| Lua Name | Purpose |
|----------|---------|
| `Utility_GetPlayerNationality` | Get chosen character |
| `Utility_CloseThisScript` | Close current script state |
| `Utility_DoesActorExist` | Check actor existence |
| `Utility_GetActor` | Get actor handle by name |
| `Utility_GetActorsInRange` | Spatial query |
| `Utility_GetDistanceBetweenActors` | Distance calc |
| `Utility_GetTerrainHeightAtXZ` | Terrain query |
| `Utility_GetRandomFloat` | Random number |
| `Utility_LoadUtilityScript` | Load another script (Mercs 2's `import()`) |
| `Utility_RunLuaScript` | Execute script by name hash |
| `Utility_ReadLevelFile` | Load level data |
| `Utility_SuspendLoading` / `ResumeLoading` | Pause streaming |
| `Utility_ResetToBaseLayerOnly` | Reset world to base state |
| `Utility_SetCurrentMissionData` | Set active mission |
| `Utility_ReadMissionData` / `WriteMissionData` | Read/write mission data |
| `Utility_SavePlayerData` / `LoadPlayerData` | Persist player state |
| `Utility_WriteStringToScribbleMemory` | Save persistent string |
| `Utility_ReadStringFromScribbleMemory` | Load persistent string |
| `Utility_WriteNumberToScribbleMemory` | Save persistent number |
| `Utility_ReadNumberFromScribbleMemory` | Load persistent number |

#### Audio Functions
| Lua Name | Purpose |
|----------|---------|
| `Audio_PlayVoiceover` | Play VO line |
| `Audio_PlayVoiceoverCB` | Play VO with callback |
| `Audio_StopAllVoiceover` | Stop all VO |
| `Audio_PlayMusic` | Play music track |
| `Audio_PlayFactionMusic` | Play faction-specific music |
| `Audio_StopMusic` | Stop music |
| `Audio_PlaySound` | Play sound effect |
| `Audio_SubmitChatterEvent` | Trigger chatter |

#### Global Variables
| Lua Name | Purpose |
|----------|---------|
| `Global_SetValue` | Set named global |
| `Global_GetValue` | Get named global |

### Actor UserData Methods (`kLuaUserDataRsActorFns[]`)

Actors are exposed as Lua userdata with methods accessible via `:` syntax:

```
actor:IsAlive()     actor:Kill()          actor:GetPosition()
actor:IsDormant()   actor:KillWithMortar() actor:SetPosition(x,y,z)
actor:IsSubdued()   actor:GetHitPoints()  actor:GetYaw() / SetYaw()
actor:Remove()      actor:SetHitPoints()  actor:GetVelocity()
actor:IsInvincible() actor:SetInvincible() actor:IsPlayer()
actor:GetType()     actor:GetRiderType()  actor:IsFacing(actor)
actor:PlayAnimation() actor:StopAnimation() actor:IsAnimating()
actor:EnableCollision() actor:EnableShadow()
actor:AttachToActor() actor:AttachToLocation()
actor:LookAtActor() actor:ResetLookAtActor()
actor:SetModelNodeVisibility()  actor:SetLightState()
actor:ClearPrimaryInventory()   actor:CreateItemInPrimaryInventory()
```

### Global Lua Constants

Set during `Init()`:
- `TRUE` / `FALSE` — boolean constants
- `RS_AFLG_NONE`, `RS_AFLG_LOOP`, `RS_AFLG_DRIVE`, `RS_AFLG_PREEMPT`, `RS_AFLG_HOLD`, `RS_AFLG_NOHEAD` — animation flags
- `GLOBALS` table — shared state between scripts

---

## 3. Asset Loading Pipeline

### Mercs 1 Flow: `PblHash(name)` → Virtual Disk Directory → Sector Read → Chunk Parse

```
1. Script name hashed: uint32 hash = PblHash("scriptname")
2. RsLuaScript::Find(hash) checks the in-memory script resource pool
3. If not found, RedVirtualDisk::RequestAsset(nameHash, typeHash) called
4. VirtualDisk searches libraries in REVERSE order (last opened = highest priority)
5. Within each DiskFile:
   a. TypeDirectory lookup by typeHash (sorted array, binary search)
   b. Within type: FileInfo lookup by nameHash (sorted array, binary search)
   c. Returns: offset + size in the disk file
6. PblStreamManager issues async read at offset for size bytes
7. When ready: data decompressed (LZSS) if compressed
8. Script executed via lua_dobuffer() into the lua_State
9. Engine calls ScriptInit() on the loaded script
```

### Virtual Disk File Format (Mercs 1 `.dsk`)

```
Header:
  uint32 numEntries
  uint32 gridFileOffset

Directory (numEntries × 3 uint32):
  uint32 fileSize
  uint32 nameHash
  uint32 typeHash

File Data:
  [raw file data, back-to-back]

Grid Data:
  [spatial streaming grid entries, marker 0x00FF8040]
```

### Evolution to Mercs 2 FFCS

| Mercs 1 Feature | Mercs 2 Equivalent |
|-----------------|-------------------|
| Single `.dsk` file with flat directory | FFCS `.wad` with INDX/DATA/ASET/PTHS/CSUM chunks |
| `nameHash + typeHash` lookup | `pandemic_hash_m2(name)` → ASET index → block offset |
| Raw data (uncompressed or LZSS) | `sges` deflate compression per block |
| No container format within blocks | UCFX container with typed chunks |
| Grid-based spatial streaming | Grid-based block streaming (similar concept) |
| "Last opened file wins" priority | Same: later WADs override earlier ones |
| Up to 64 stacked disk files | Multiple WADs stacked |

### Script Loading Specifics

```cpp
// Mercs 1: OpenScript loads by hash, decompresses LZSS, runs
bool RsLuaState::OpenScript(uint32 uiScriptNameHash) {
    const RsLuaScript* pScript = RsLuaScript::Find(uiScriptNameHash);
    // LZSS decompress
    LzssDecompress(output, pScript->GetScriptData(), compressedLen);
    // Execute
    lua_dobuffer(_pLuaState, uncompressed, len, NULL);
}

// Then engine calls:
_MainMasterRsLuaState.InvokeLuaFunction("ScriptInit");
```

**Mercs 2 equivalent:**
```
import("scriptname")  →  _SYS._IMPORT("scriptname")
  → pandemic_hash_m2("scriptname")
  → ASET lookup → block load → sges decompress
  → Lua 5.1 bytecode (.luac) → luaL_loadbuffer + lua_pcall
  → ScriptInit() called
```

---

## 4. Mission System Architecture

### Mercs 1 Architecture

#### Data-Driven Mission Definition

`RsMissionDataManager` stores up to 64 missions loaded from config files:

```cpp
class MissionData {
    uint32 _uiNameHash;             // Hash of mission name
    uint32 _uiMissionTitleDbKeyHash; // Localized title key
    uint32 _uiClientNameDbKeyHash;  // Client/faction boss
    float  _fTimeLimitInMinutes;
    float  _fContractFee;           // Cost to accept
    float  _fBonusFee;              // Bonus payout
    uint32 _uiChapterHash;          // Chapter assignment
    uint32 _uiFactionHash;          // Faction assignment
    uint32 _uiMapHash;              // Map requirement
    uint32 _uiMissionNumber;        // Sequence number
    uint32 _uiStatus;               // STATUS_NORMAL or STATUS_COMPLETED
    uint32 _uiType;                 // TYPE_NORMAL or TYPE_ADDON
    // Objectives (up to 4 primary + 4 secondary)
};
```

#### Script Execution Flow

```
1. Engine loads → RsLuaMission::Init()
   - Creates main master lua_State
   - Registers ALL API functions (base + master-only)
   - Creates GLOBALS table

2. RsLuaMission::OpenMissionScripts()
   - Opens master script by name hash
   - Calls ScriptInit() on the master

3. Master script (e.g., "env01_1"):
   - ScriptInit() registers missions, sets up world state
   - Spawns "slave" scripts for individual missions via RsLuaStatePool

4. Mission lifecycle:
   - Utility_SetCurrentMissionData("missionName") → activates mission
   - Mission script runs in slave RsLuaState
   - Events fire callbacks when conditions met
   - MissionContractCancel() / PreemptiveMissionComplete() / MissionRetry(bool)
   
5. Callback on close:
   - Slave scripts set up callback via SetupCallback()
   - When slave closes, master is notified
```

#### Master/Slave Script Pattern

```
RsLuaMission
├── _MainMasterRsLuaState (the hub script - manages all missions)
└── _RsLuaStatePool [5 slots]
    ├── Slave 0 (active mission script)
    ├── Slave 1 (cinematics script: "{name}_cinematics")
    ├── Slave 2 (available for concurrent scripts)
    ├── Slave 3
    └── Slave 4
```

### Mercs 2 Equivalent

| Mercs 1 | Mercs 2 |
|---------|---------|
| `RsMissionDataManager` (C++ config) | `tMissionData` table in `wifmissiondata.lua` |
| `Utility_SetCurrentMissionData("name")` | `UnlockMission("MissionId")` / `ActivateMission()` |
| Master script manages all missions | `wifmissionflow.lua` is the master orchestrator |
| Slave scripts per mission | Individual `*job*.lua` and `*con*.lua` scripts |
| `SetupCallback(luaState, "funcName")` | Callback system via `_SYS` or direct function calls |
| 5-slot RsLuaStatePool | Single Lua state with coroutines/modules |
| Config file defines 64 missions | Lua table defines unlimited missions |
| FACTION enum (4 factions) | String-based factions ("pmc", "oil", "pir", etc.) |
| `PblHash(name)` for identification | `pandemic_hash_m2(name)` |

### Mission State Machine (Mercs 1)

```
NORMAL → [AcceptContract] → ACTIVE → [Complete/Fail] → COMPLETED
                                    → [Cancel] → NORMAL
                                    → [Death] → [Retry?] → ACTIVE / NORMAL
```

Engine-to-script calls:
- `ScriptInit()` — called after script loaded
- `MissionRetry(bool)` — player chose retry/quit
- `MissionContractCancel()` — player cancelled
- `PreemptiveMissionComplete()` — debug force-win
- `DebugSkipToMission(faction, number)` — debug skip

---

## 5. Key Differences: Mercs 1 → Mercs 2

### Asset System

| Aspect | Mercs 1 | Mercs 2 |
|--------|---------|---------|
| Container | Flat `.dsk` with triplet directory | FFCS `.wad` with INDX/DATA/ASET/PTHS/CSUM |
| Compression | LZSS (scripts only) | `sges` raw deflate (all blocks) |
| Block format | Raw data by type hash | UCFX containers with typed chunks |
| Hash function | `PblHash()` | `pandemic_hash_m2()` (different algorithm) |
| Lookup key | `(nameHash, typeHash)` pair | `nameHash` only (ASET maps to block+offset) |
| Streaming | Grid-based spatial | Grid-based + priority streaming |
| Max libraries | 64 (Xbox), 4 (PS2) | Unlimited WAD stacking |

### Scripting

| Aspect | Mercs 1 | Mercs 2 |
|--------|---------|---------|
| Lua version | 5.0.1 | 5.1 (float build) |
| Script format | Source text (LZSS compressed) | Precompiled bytecode (.luac) |
| Libraries | `base`, `table` only | `base`, `table`, `string`, `math` |
| Execution | `lua_dobuffer()` | `luaL_loadbuffer()` + `lua_pcall()` |
| Module loading | `Utility_LoadUtilityScript()` | `import("name")` / `_SYS._IMPORT` |
| Script states | 1 master + 5 slaves (fixed pool) | Likely single state with modules |
| API naming | `Subsystem_Function()` flat | Likely table-based `_SYS.*`, `Actor.*` |
| Events | C++ polling each frame | Likely similar event system |
| Entry point | `ScriptInit()` | `ScriptInit()` (confirmed same) |

### World System

| Aspect | Mercs 1 | Mercs 2 |
|--------|---------|---------|
| Entity model | Spore system (dormant/awake/dead) | COMP-based placements |
| Property storage | Hash-table key/value pairs | Binary record (42 bytes) + components |
| World file | `PblChunk`-based hierarchical | UCFX sub-blocks in layers_static |
| Streaming | Hibernation distance per-entity | Block-level streaming |
| Max entities | 16,384 spores | 62,458 placements (layers_static) |
| Conditional | No visibility layers | `vz_state` overlays (pristine/ruined/staging) |
| Terrain | Single terrain object | Tiled `low_res_terrain` system |

### Physics

| Aspect | Mercs 1 | Mercs 2 |
|--------|---------|---------|
| Engine | Havok 2.2/2.3 | Havok 5.5 |
| Animation | Custom Zephyr system | Havok Animation (interleaved/delta/wavelet) |
| Vehicles | Custom `RsHavokPhysicsCar` | Havok vehicle physics |

---

## 6. Re-Port Implications

### Subsystems That Could Be Largely Reused (with Mercs 2 adaptations)

1. **Lua Binding Framework** — The pattern of registering C functions via `luaL_reg` arrays is identical. A re-port would use the same architecture but register Mercs 2 API functions (`import`, `UnlockMission`, `RequestAirstrike`, etc.)

2. **Event System** — `RsLuaEvent` / `RsLuaEventManager` is a clean, well-structured polling event system. Mercs 2 likely uses something very similar. Could be adapted directly.

3. **Mission State Machine** — The master/slave script pattern and mission lifecycle are a clear foundation for Mercs 2's `wifmissionflow` system.

4. **Faction/Diplomacy** — `RsFactionRelation` with attitude tracking maps directly to Mercs 2's faction system.

5. **Virtual Disk / Asset Resolution** — The "last opened wins" multi-library approach is confirmed identical. Only the file format (FFCS vs flat) and compression (sges vs LZSS) differ.

### Subsystems That Need Significant Reimplementation

1. **FFCS WAD Parser** — Already done in Python (`tools/ffcs_slicer.py`). A C++ re-port would follow the same structure but needs INDX/ASET/PTHS handling.

2. **UCFX Container Parser** — New in Mercs 2. The `PblChunk` reader is the ancestor pattern but UCFX has different magic/header layout.

3. **sges Decompression** — Replace LZSS with raw deflate (`zlib` windowBits -15). Already understood.

4. **Havok 5.5 Animation** — Complete replacement of the Zephyr system. Needs packfile parser + three decompression codecs.

5. **World/Placement System** — Binary 42-byte records replace the PblChunk-based Spore system. Different data model.

6. **Rendering** — D3D9 (Mercs 2 PC) vs Xbox/PS2 (Mercs 1). Complete rewrite needed for any modern port.

7. **Lua 5.1 `import()` System** — The `_SYS._IMPORT` mechanism needs to handle:
   - Hash computation via `pandemic_hash_m2`
   - ASET lookup in WAD
   - Block decompression
   - Bytecode loading (not source text)
   - Module caching (Mercs 1 had none)

### Subsystems That Can Be Stubbed Initially

1. **Audio/Sound** — Return success from all audio calls
2. **Rendering** — Log calls, return placeholder data
3. **Physics** — Return identity transforms, skip collision
4. **Network** — Not needed for single-player
5. **Streaming/Caching** — Load everything synchronously initially
6. **Save/Load** — Stub with in-memory state

### Priority Order for Re-Port

```
Phase 1: Boot → Script Execution
  ├── FFCS parser (done in Python, port to C++)
  ├── sges decompression (done)
  ├── pandemic_hash_m2 (done)
  ├── Lua 5.1 host + bytecode loader
  ├── _SYS._IMPORT / import() implementation
  └── ScriptInit() call chain

Phase 2: World Initialization  
  ├── UCFX parser (done in Python)
  ├── Placement loader (layers_static)
  ├── Basic entity system (spawn/despawn)
  └── vz_state overlay system

Phase 3: Mission System
  ├── wifmissiondata consumer
  ├── wifmissionflow orchestrator
  ├── Event system (adapated from RsLuaEvent)
  ├── Faction relations
  └── NPC/starter registration

Phase 4: Gameplay
  ├── Actor state (HP, position, alive/dead)
  ├── AI command queue
  ├── Vehicle enter/exit
  ├── Damage system
  └── Shop/economy
```

---

## Appendix A: Hash Function Comparison

### Mercs 1: `PblHash()`
Unknown algorithm (not in source headers we have), but outputs `uint32`. Used for:
- Script names
- Asset names
- Asset types
- Actor names
- Property keys
- Mission names

### Mercs 2: `pandemic_hash_m2()`
Known algorithm (reconstructed from binary). Outputs `uint32`. Same use cases.

The hash change means Mercs 1 hash values (e.g., `0x3884598e` = "registry", `0x400f92a5` = "aspade") are **NOT** reusable for Mercs 2 lookups.

---

## Appendix B: Source File Quick Reference

| What you want | Where to look |
|---------------|---------------|
| Asset loading | `RedEngine/Source/RedVirtualDisk.cpp` |
| Entity system | `RedEngine/Source/RedWorld.cpp` |
| Lua API registration | `RetroStrike/Source/RsLuaState.cpp` (lines 97-527) |
| Script loading | `RetroStrike/Source/RsLuaScript.cpp` |
| Script execution | `RetroStrike/Source/RsLuaState.cpp::OpenScript()` |
| Mission lifecycle | `RetroStrike/Source/RsLuaMission.cpp` |
| Mission data | `RetroStrike/Source/RsMissionDataManager.h` |
| Event system | `RetroStrike/Source/RsLuaEvent.h/cpp` |
| Actor base class | `RetroStrike/Source/RsActor.h` |
| World/Spore system | `RetroStrike/Source/RsWorld.cpp` |
| Faction system | `RetroStrike/Source/RsFactionRelation.cpp` |
| AI commands | `RetroStrike/Source/RsAi.cpp` |
| Havok integration | `RetroStrike/Source/RsHavok*.cpp` |
| Platform layer | `Projects/Pebble/Source/*` |
| Lua 5.0.1 headers | `Projects/Lua/Include/lua.h` |
