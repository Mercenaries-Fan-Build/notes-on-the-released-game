# Mercenaries 2 Executable Analysis — Agent A Report

**Binary**: `CRACK/MERCENAR.EXE` from retail ISO  
**Size**: 53,482,288 bytes (51.0 MB) — SecuROM-unpacked  
**Original module name**: `Mercs2_PC_F.exe` (from PE export directory)  
**Build path**: `D:\Projects\Mercs2_PC\mercs2\`  
**Compiler**: MSVC (MSVCR80.dll), 32-bit x86  
**Timestamp**: 0x48A370C7 (2008-08-13)

---

## 1. PE Structure

| Section | VA | VSize | Raw Offset | Raw Size | Flags |
|---|---|---|---|---|---|
| `.text` | 0x00001000 | 0x00704000 | 0x00001000 | 0x00704000 | CODE, EXEC, READ |
| `.rdata` | 0x00705000 | 0x000F1000 | 0x00705000 | 0x000F1000 | INIT_DATA, READ, WRITE |
| `.data` | 0x007F6000 | 0x00E04000 | 0x007F6000 | 0x00E04000 | INIT_DATA, READ, WRITE |
| `extdata` | 0x015FA000 | 0x00001000 | 0x015FA000 | 0x00001000 | INIT_DATA, READ, WRITE |
| `.tls` | 0x015FB000 | 0x00001000 | 0x015FB000 | 0x00001000 | INIT_DATA, READ, WRITE |
| `.rsrc` | 0x015FC000 | 0x0004D000 | 0x015FC000 | 0x0004D000 | INIT_DATA, READ |
| `Stext` | 0x01649000 | 0x0063B000 | 0x01649000 | 0x0063B000 | CODE, EXEC, READ, WRITE |
| `Sitext` | 0x01C84000 | 0x00007000 | 0x01C84000 | 0x00007000 | CODE, EXEC, READ |
| `Srdata` | 0x01C8B000 | 0x0005A000 | 0x01C8B000 | 0x0005A000 | INIT_DATA, EXEC, READ |
| `Sdata` | 0x01CE5000 | 0x002FE000 | 0x01CE5000 | 0x002FE000 | INIT_DATA, EXEC, READ, WRITE |
| `Sidata` | 0x01FE3000 | 0x00006000 | 0x01FE3000 | 0x00006000 | INIT_DATA, READ, WRITE |
| `.securom` | 0x01FE9000 | 0x013175F8 | 0x01FE9000 | 0x013175F8 | CODE, EXEC, READ, WRITE |
| `reloaded` | 0x03301000 | 0x00001000 | 0x03301000 | 0x00000330 | ALL |

**Image base**: 0x00400000  
**Entry point**: VA 0x00B04C2E (file offset 0x00704C2E — inside `.text`)  
**Note**: `S*` sections and `.securom` are SecuROM remnants. Game code is in `.text` (7 MB).

### Key DLL Imports

| DLL | Key Functions |
|---|---|
| `d3d9.dll` | `Direct3DCreate9` |
| `d3dx9_36.dll` | Rotation, transform, quaternion math, surface loading, shader constant tables |
| `binkw32.dll` | Bink video playback (15 functions) |
| `DINPUT8.dll` | `DirectInput8Create` |
| `DSOUND.dll` | 6 DirectSound ordinals |
| `XINPUT1_3.dll` | XInput controller support (2 ordinals) |
| `WS2_32.dll` | 42 Winsock2 functions (full networking stack) |
| `WSOCK32.dll` | 6 legacy Winsock functions |
| `dbghelp.dll` | Stack walking, symbol resolution |
| `MSVCR80.dll` | C runtime (165 functions) |

### Exports (63 named functions)

The exe exports **GFx (Scaleform)** API classes: `GImage`, `GMatrix2D`, `GColor`, `GRefCountBaseImpl`, `GZLibFile`, `GFxLoader`. This confirms **Scaleform GFx** is the UI middleware.

---

## 2. Lua Integration Layer

### Engine: Lua 5.1.2

**Confidence**: CERTAIN  
**Evidence**: String `$Lua: Lua 5.1.2 Copyright (C) 1994-2007 Lua.org, PUC-Rio $` at offset `0x007925B8`  
**Source path**: `D:\Projects\Mercs2_PC\mercs2\Lua-5.1.2\src\` (seen in debug paths for `lstate.c`, `lfunc.c`, `ldo.c`, `ltable.c`, `lstring.c`, `lgc.c`, `lzio.c`, `llex.c`, `lmem.c`, `lparser.c`, `lundump.c`)

### Bootstrap Code (Embedded Lua Source)

At offset `0x007B4EE2`, the engine loads an embedded Lua bootstrap script:

```lua
_G._MODULES = {};
_MODULESMETATABLE = { __index = _SYS._MODULEINDEX };

function _G.import(module)
    return _SYS._IMPORT(getfenv(2), module);
end

function _G.dynamic_import(module, callbackfunc, callbackdata)
    return _SYS._DYNAMIC_IMPORT(_SYS._GETFENV(2) or _G, module, callbackfunc, callbackdata);
end

function _G.inherit(module)
    return _SYS._INHERIT(getfenv(2), module);
end

function _G.dynamic_remove(module)
    return _SYS._DYNAMIC_REMOVE(_SYS._GETFENV(2), module);
end
```

### How `import()` Works
- `import("foo")` calls C++ function `_SYS._IMPORT(env, "foo")`
- The C++ side resolves `"foo"` to a WAD block path, loads the Lua script, and executes it in the caller's environment (`getfenv(2)`)
- Modules are tracked in `_G._MODULES` table with a metatable using `_SYS._MODULEINDEX`

### How `inherit()` Works
- `inherit("base_module")` calls `_SYS._INHERIT(env, "base_module")`
- Copies all functions/values from the base module's environment into the caller's environment (prototype inheritance)

### `_SYS` C++ Registered Functions

| Function | Offset | Purpose |
|---|---|---|
| `_SYS._IMPORT` | 0x007B453C | Load and execute a Lua module |
| `_SYS._INHERIT` | 0x007B4ED4 | Copy base module environment |
| `_SYS._DYNAMIC_IMPORT` | 0x007B4EC4 | Async module loading |
| `_SYS._DYNAMIC_REMOVE` | (implicit) | Unload a dynamic module |
| `_SYS._GETFENV` | 0x007B4E98 | Wrapped getfenv |
| `_SYS._MODULEINDEX` | (implicit) | Module lookup metaindex |

### Marker API (Lua→C++ Bridge)

```lua
_G.Marker               = {}
_G.Marker.Add           = Gui._MarkerAddOld
_G.Marker.AddBlip       = Gui._MarkerAdd
_G.Marker.AddTripwire   = Gui._MarkerAddTripwire
_G.Marker.AddDisc       = Gui._MarkerAddDisc
_G.Marker.Remove        = Gui._MarkerRemove
_G.Marker.SetGroupedBlipLimit = Gui._MarkerSetBlipLimit
_G.Marker.SetLocation   = Gui._MarkerSetLocation
_G.Marker.SetColor      = Gui._MarkerSetColor
_G.Marker.SetFollowGuid = Gui._MarkerSetFollowGuid
_G.Marker.SetScale      = Gui._MarkerSetScale
_G.Marker.Pulse         = Gui._MarkerPulse
_G.Marker.HaltPulse     = Gui._MarkerHaltPulse
```

### Memory Configuration

| String | Offset |
|---|---|
| `LuaGarbageCollectionThreshold 256` | 0x007AF60C |
| `ScriptHeap 0` | 0x007AF42E |
| `ScriptHeapBlocks 800` | 0x007AF43C |
| `ScriptHeapAlign 4` | 0x007AF452 |
| `ObjectScript 2048` | 0x007AE14B (pool: 2048 slots) |
| `RuntimeScriptCallback 8 8` | 0x007AEB7F |

### Registered Lua Global Namespaces

All Lua-callable functions are registered in these namespaces (1300+ functions found):

| Namespace | Key Functions |
|---|---|
| **Player** | `AddBoundary`, `RemoveBoundary`, `SetBoundaryCallback`, `SpawnPlayer`, `GetCash`, `SetCash`, `AddFuel`, `GetFuel`, `SetInputEnabled`, `SetCinematicMode`, `GetCamera`, `TeleportCamera` |
| **Object** | `GetPosition`, `SetHealth`, `GetHealth`, `Kill`, `Remove`, `IsAlive`, `IsValid`, `SetVisible`, `PlayAnimation`, `GetModelName`, `SetName`, `ApplyImpulse`, `SetMass` |
| **Gui** | `CreateFlashWidget`, `PlayFlash`, `CallFlashScriptFunction`, `CreateTextWidget`, `CreateImageWidget`, `SetWidgetVisible`, `MinimapCreate`, `AddObjective` |
| **Ai** | `Goal`, `DefaultGoal`, `Squad`, `Role`, `Plan`, `PlanSetGoal`, `SetPerceivability`, `Deploy`, `EveryoneOut` |
| **Atmosphere** | `SetSky`, `SetTime`, `SetTimeSpeed`, `SetLightIntensity`, `SetAmbientColor`, `SetRainDensity` |
| **Graphics** | `SetBoundaryEffect`, `ReloadShaders`, `SetGamma`, `ScreenShot`, `Bloom`, `MotionBlur`, `Monochrome` |
| **Net** | `IsMultiplayer`, `IsServer`, `IsClient`, `IsLobby`, `ConnectToServer`, `StartServer`, `QuitGame` |
| **Sys** | `IsDemoMode`, `GetPlatform`, `GetLanguage`, `SetMasterScriptName`, `GetMasterScriptName`, `SetTimeScale`, `RequestGameState`, `LoadAsset`, `UnloadAsset`, `LoadLayer`, `UnloadLayer` |
| **Sound** | `LoadBank`, `LoadSoundBank`, `LoadWaveBank`, `CueSound`, `StopSound`, `SetMasterVolume`, `SetCategoryVolume` |
| **Debug** | `Printf`, `LogError`, `LogWarning`, `LogInfo`, `GetCallstack` |
| **Weapon** | `GetClipAmmo`, `SetClipAmmo`, `GetReserveAmmo`, `SetReserveAmmo`, `IsDesignator`, `IsPrimary` |

### SendEvent Functions (44 total)

These are the C++ → Lua event dispatch functions:

```
SendEvent_AddObjective, SendEvent_RemoveObjective, SendEvent_AddRadarObjective,
SendEvent_RemoveRadarObjective, SendEvent_AddMarkerObjective, SendEvent_RemoveMarkerObjective,
SendEvent_AddPdaObjective, SendEvent_RemovePdaObjective, SendEvent_TeleportPlayer,
SendEvent_TeleportPlayerToHardPoint, SendEvent_Fanfare, SendEvent_CloseFanfare,
SendEvent_ObjectiveMessage, SendEvent_Support, SendEvent_AddSupportItem,
SendEvent_RemoveSupportItem, SendEvent_RecruitsUnlocked, SendEvent_RevivePlayer,
SendEvent_ShowMovie, SendEvent_HideMovie, SendEvent_ShowMessage,
SendEvent_TextFanfare, SendEvent_CardFanfare, SendEvent_HVTFanfare,
SendEvent_UnlockFanfare, SendEvent_BatchUnlockFanfare, SendEvent_ForceClientTether,
SendEvent_PursuitMessage, SendEvent_AddHqPdaBlip, SendEvent_RemoveHqPdaBlip,
SendEvent_AddPmcPdaBlip, SendEvent_RemovePmcPdaBlip, SendEvent_AddPDAMission,
SendEvent_RemovePDAMission, SendEvent_JoinPOForceRequest, SendEvent_EnableHeroWeapons,
SendEvent_AddDangerousBuilding, SendEvent_RemoveDangerousBuilding,
SendEvent_SetOccupiedDangerousBuilding, SendEvent_AddRandomDangerousBuilding,
SendEvent_RequestPosition, SendEvent_SetObjectiveTraySlotText,
SendEvent_SetObjectiveTraySlotImage, SendEvent_ClearObjectiveTraySlot
```

### Event Listener Types

```
Event, WeaponEvent, ScriptEvent, HumanAnimationNearlyCompleted,
HumanActionComplete, AirstrikeDeliveryReady, GameStateChange,
TimerRelative, GuiGameTimer, GuiVehicleDisguiseUpdate, GuiVehicleNameUpdate,
GuiPlayerReceiveDamage, GuiGameStateChange, GuiSeatMenuEnter,
GuiSupportMenuEnter, GuiWeaponEquippedUpdate, GuiAnimateUpdate,
GuiPauseStateChange, GuiReticleUpdate, GuiVehicleHealthUpdate,
GuiHealthUpdate, GuiMinimapUpdate, GuiAmmoUpdate, GuiUpdate,
ObjectIsVisible, ObjectPhysicsEvent, ObjectIsGrounded, ObjectIsReady,
ObjectHibernation, ObjectTowed, ObjectWinched, ObjectInSeat, Boundary,
ObjectProximity, ObjectHealthLessThan, ObjectHealth
```

### Contract System

- `ContractCompleted` (0x007B8A88) — Lua-callable function
- `ContractCancelled` (0x007B8A9C)
- `ContractActivated` (0x007B8AB0)
- `[contract` prefix (0x007BCCBC) — used in localization key resolution
- `sContract` (0x007BBD2C) — lobby server contract field

The `MrxTaskContract` lifecycle (from string evidence):
1. `ContractActivated` → script begins
2. Script uses `SendEvent_AddObjective` / `SendEvent_AddRadarObjective` etc.
3. `Completed` / `Failed` callbacks (0x007B98EC / 0x007B98E4)
4. `ContractCompleted` / `ContractCancelled` sent back to engine

---

## 3. WAD/FFCS Loading System

### WAD Path Format Strings

| String | Offset | Purpose |
|---|---|---|
| `%s\%s.wad` | 0x007AFED0 | Primary WAD load pattern |
| `%s\%s-patch.wad` | 0x007AFF5C | Patch overlay WAD |
| `%s\loading.wad` | 0x007AFF6C | Loading screen WAD |
| `%s\loading-patch.wad` | 0x007AFF7C | Loading screen patch |
| `%s\vz.wad` | 0x007BD038 | VZ (Venezuela) world data WAD |

**Confidence**: CERTAIN

### WAD Loading Xrefs

| Format string | Xref count | Code location(s) |
|---|---|---|
| `%s\%s.wad` | 2 | VA 0x004BFD0F, 0x004BFE4C |
| `%s\%s-patch.wad` | 2 | VA 0x004BFDBD, 0x004BFF15 |
| `%s\loading.wad` | 1 | VA 0x004BFF9D |
| `%s\vz.wad` | 1 | VA 0x006316FB |

The WAD loading code at VA 0x004BFDxx shows the engine formats the path with `sprintf`, then opens the primary WAD, then immediately tries the `-patch.wad` overlay. The patch WAD is optional — it overlays blocks on top of the base WAD.

### Error Message

`Mercenaries 2: World in Flames is unable to continue due to the missing file: %s.` (0x007AFF00)

### Asset Hash Validation

`INVALID Hash for Asset ID: %d` (0x0076982C) — confirms hash-based asset lookup with validation.  
`HashesAndNames.txt` (0x009289FE) — the engine can load a debug name→hash mapping file.

---

## 4. sges Decompression

### Validation Function

**Location**: File offset 0x00114870 (VA 0x00514870)  
**Confidence**: CERTAIN — contains literal `sges` magic comparison

### Exact Validation Sequence

```
1. Check magic:  cmp dword [ptr], 0x73676573 ('sges')
                  → FAIL if mismatch
2. Check version: cmp word [ptr+4], 4
                  → FAIL if major_version != 4
3. Check size:    mov ecx, [ptr+0xC]         ; decompressed_size from header
                  cmp ecx, [block_entry+0x14] ; expected size from block table
                  → FAIL if decompressed_size > expected_size (jbe = ok)
4. Parse segments: segment_count = word [ptr+6]
                  segment_table starts at ptr+0x12 (NOT ptr+0x10!)
                  each segment entry = 8 bytes
5. Segment loop:
   for each segment:
     compressed_offset = dword [entry+2] & 0xFFFFFFFE  (mask lowest bit = flag)
     decompressed_size = word [entry+0]
     if decompressed_size == 0: use 65536 (0x10000) as default
     accumulate total decompressed size
     advance entry pointer by 8
```

### Critical Details

- **Segment table starts at offset 0x12** from sges header start, NOT 0x10
- **Default segment decompressed size**: 65536 bytes (0x10000) when the field is zero
- **Segment entry size**: 8 bytes per segment
- **Compressed offset mask**: The engine ANDs with `0xFFFFFFFE`, meaning the **lowest bit is a flag** (likely "stored uncompressed" flag)
- **zlib**: The exe contains `deflate 1.2.3` (0x00794648) and `inflate 1.2.3` (0x00794700) — standard zlib 1.2.3

### Havok Block Cache

`TtdecompressBlockCacheD` (0x0076B2D0) and `TtdecompressBlockCacheW` (0x0076B4F0) suggest Havok also uses a decompression cache, separate from the sges system.

---

## 5. FNV-1a Hash (Pandemic Variant)

### Implementation

**Location**: File offset 0x00064327 (VA 0x00464327)  
**Confidence**: CERTAIN — FNV constants matched exactly

### Algorithm (from disassembly)

```c
uint32_t pandemic_fnv1a(const char* str) {
    if (*str == '\0') return 0;
    uint32_t hash = 0x811C9DC5;  // FNV offset basis
    while (*str) {
        char c = *str | 0x20;    // CASE INSENSITIVE (force lowercase)
        hash ^= (uint32_t)c;
        hash *= 0x01000193;      // FNV prime
        str++;
    }
    hash ^= 0x2A;               // XOR with 42
    hash *= 0x01000193;          // Multiply by prime ONE MORE TIME
    return hash;
}
```

### Key Differences from Standard FNV-1a

1. **Case-insensitive**: Every character is OR'd with 0x20 (lowercase ASCII)
2. **Post-processing**: After the main loop, `hash ^= 0x2A; hash *= prime;`
3. **Empty string**: Returns 0 (early exit)
4. Found at **166 locations** in the exe — used pervasively for asset, block, and name lookups

---

## 6. Demo Mode / Timer

### IsDemoMode

**String offset**: 0x007BA268  
**Cross-reference**: 0x00798B50 (in a function pointer table)  
**Confidence**: CERTAIN — `IsDemoMode` is a registered Lua global (in `Sys` namespace)

The demo timer is controlled from Lua, not hardcoded in C++. The `IsDemoMode` function returns a boolean from C++, and the Lua scripts manage the countdown and boundary restrictions.

### Related Demo Strings

- `IsDemoMode` — Lua-callable check
- `Mercenaries2` (0x007BD028) — registered as game name identifier
- No `ShowDemoOutroAndQuitToShell` found as a C++ string — this is likely a Lua function name called via `ChangeShellState` (0x007B6A68)

---

## 7. Boundary System

### Lua API Functions

| Function | Offset | Purpose |
|---|---|---|
| `AddBoundary` | 0x007B96A4 | Add a boundary region |
| `RemoveBoundary` | 0x007B9694 | Remove a specific boundary |
| `RemoveAllBoundary` | 0x007B9680 | Remove all boundaries |
| `SetBoundaryCallback` | 0x007B9658 | Set callback for boundary events |
| `GetBoundaryRadius` | 0x007B8B48 | Get radius |
| `SetBoundaryRadius` | 0x007B8B5C | Set radius |
| `IsPointInBoundary` | 0x007B8B84 | Point containment test |
| `GetLineRegionPoints` | 0x007B8B70 | Get line region geometry |
| `IsPositionOutBoundary` | 0x007B9640 | Check if position is outside |
| `IsBoundaryDeath` | 0x007B9630 | Check if boundary kills player |
| `SetOutBoundary` | 0x007B96D0 | Set "out of boundary" state |
| `GetOutBoundary` | 0x007B96C0 | Get "out of boundary" state |
| `GetAllBoundaryGuid` | 0x007B966C | Get all boundary GUIDs |
| `OutsideBoundary` | 0x007B85B4 | Object outside boundary check |
| `InsideBoundary` | 0x007B85C4 | Object inside boundary check |
| `IsInWarningZone` | 0x007B96B0 | Warning zone check |
| `GetWarningRadius` | 0x007B8B20 | Get warning zone radius |
| `SetWarningRadius` | 0x007B8B34 | Set warning zone radius |
| `GetTetherDiameterStart` | 0x007B8B08 | Tether diameter start |
| `GetTetherDiameterEnd` | 0x007B8AF0 | Tether diameter end |
| `SetBoundaryEffect` | 0x007B55DC | Visual boundary effect |
| `NetClientAddBoundary` | 0x007D1D20 | Network: add boundary on client |
| `NetClientRemoveBoundary` | 0x007D1D08 | Network: remove boundary on client |
| `move_within_boundary` | 0x007B3C10 | AI action type |
| `MoveWithinBoundary:` | 0x0079ACA0 | AI action debug string |

### Boundary event listener: `Boundary` (0x007BAD20)

### ECS Component: `BoundaryData` (0x007C5288)

---

## 8. ECS / Entity System

### SceneObject Pool

`SceneObject 161280` (0x007AED2E) — **161,280 object slots** preallocated.

Format: `ComponentName MaxCount [AlignedBlockSize]`

### Full Component List (from memory pool descriptors at ~0x007AD000)

This is the **complete ECS component registry** — approximately 200 component types. Key ones:

| Component | Pool Size | Notes |
|---|---|---|
| SceneObject | 161280 | Main entity container |
| PendingSceneObject | 2048 | Loading queue |
| RuntimeSceneObject | 2816 | Active runtime state |
| ObjectScript | 2048 | Lua script attachment |
| RuntimeHealth | 1280 | Health component |
| RuntimeNodeHealth | 1280 | Per-node damage |
| RuntimeLayerId | 20224 | Layer assignment |
| RuntimeModelState | 2048 | Model/LOD state |
| RuntimeAssetRef | 2560 | Asset references |
| RuntimeEquipmentLink | 5120 | Weapon/equipment slots |
| RuntimePhysicalLink | 22784 | Physics linkage |
| PhysicsActor | 2304 | Havok physics body |
| StateMachine | 768 | AI state machine |
| SeatLink | 13312 | Vehicle seats |
| Road | 4608 | Road network |
| RoadIntersection | 2304 | Intersection nodes |
| MassiveComponent | 32 | "Massive" engine integration |
| RedEffectComponent | 768 | Pandemic Red Effect system |
| Name | 6912 | Entity names |
| ModelName | 4608 | Model file names |
| Perception | 1280 | AI perception |
| SoundEffect | 3584 | Sound emitters |
| SoundKey | 5632 | Sound triggers |
| VehiclePart | 4096 | Vehicle damage parts |
| Turret | 1024 | Turret components |
| TerrainObject | 1024 | Terrain chunks |
| Usable | 512 | Interactable objects |
| Rider | 1024 | Characters in vehicles |
| RiderLink | 1024 | Rider↔seat links |
| RuntimeWeapon | 192 | Active weapons |
| RuntimeInventory | 320 | Inventory slots |
| RuntimeTurret | 128 | Active turrets |

### RTTI Game Classes

Key game-specific C++ classes (from MSVC RTTI):
- `ValidatedClassNameRegistry` (0x008DD48C)
- `CWinApiException` (0x01FD9944)
- `CCmdLineContextMenu` (SecuROM shell extension)

---

## 9. UCFX Chunk Handlers

Chunk type comparisons found in `.text` section code:

| Chunk | References | Primary Handler VA |
|---|---|---|
| TRFM | 2 | 0x0048CCB6 (transform data) |
| GEOM | 6 | 0x004A842B, 0x004A8FB6 (geometry container) |
| MESH | 2 | 0x00471923 (mesh data) |
| SKIN | 2 | 0x0047192A (skinned mesh) |
| PRMG | 8 | 0x0047817E, 0x004795FE (primitive group) |
| STRM | 10 | 0x004782FD, 0x004A527D (stream/vertex buffer) |
| IBUF | 8 | 0x00478311, 0x004A5286 (index buffer) |
| MTRL | 8 | 0x004A528D, 0x004AC95D (material) |
| BSHP | 4 | 0x0047839E (blend shape) |
| CHDR | 2 | 0x000CF3BD, 0x00254A09 (chunk header) |
| COMP | 1 | 0x002549F1 |
| SEGM | 1 | (segment, via `=SEGMt.=GEOM` at 0x02062276) |
| MIXR | 1 | (via `=MIXRwptO=BSHPt%=HIER` at 0x020622E5) |
| HIER | 1 | (hierarchy, embedded in MIXR handler string) |
| SWIT | 1 | 0x000CF5D9 (switch/damage state) |

The MIXR → BSHP → HIER chain at 0x020622E5 shows the handler dispatches for animation mixing: MIXR contains BSHP (blend shapes) and HIER (skeleton hierarchy).

---

## 10. Rendering / Precache System

### LTI Precache Engine

Source path: `D:\Projects\Mercs2_PC\mercs2\LTI\src\PrecacheMain.cpp` (0x007D4DB4)

The precache system pre-renders GPU resources to disk:

| Component | Source File |
|---|---|
| PrecacheIndexBuffer | PrecacheIndexBuffer.cpp |
| PrecacheVertexBuffer | PrecacheVertexBuffer.cpp |
| PrecachePixelShader | (PrecacheMain.cpp) |
| PrecacheVertexShader | (PrecacheMain.cpp) |
| PrecacheVertexDecl | PrecacheVertexDecl.cpp |
| PrecacheSurface | PrecacheSurface.cpp |
| PrecacheTexture | PrecacheTexture.cpp |
| PrecacheDisplayList | (PrecacheMain.cpp) |
| PrecacheManager | (PrecacheMain.cpp) |

File format: `precache\display%i.precache` and `precache\%s%i.precache`

### GPU Requirements

- `Mercenaries 2: World in Flames requires a Shader 3 capable video card to run.` (0x007D5BD8)
- `requires a video card which supports vertex textures or R2VB to run.` (0x007D5D70)

### Scaleform GFx UI

ActionScript/Flash-based UI via Scaleform. Evidence:
- `CallFlashScriptFunction` (Lua binding)
- `ActionScript Memory leaks in movie '%s', including %d string nodes` (0x007D9658)
- `Warning: Recursive import detected in '%s'` (0x007DEBC0)
- `Import error: GFxResource '%s' is not exported from movie '%s'` (0x007DEBF0)
- `GZLibFile` exported from the exe (Scaleform's zlib wrapper)

---

## 11. Network / Multiplayer

### Architecture

**Full co-op multiplayer code is present** — not just stubs.

| String | Offset | Notes |
|---|---|---|
| `multiplayer.ini` | 0x007B004C | Config file |
| `CNetworkManager` | 0x00769104 | Core network class |
| `CMassiveSocket` | 0x007696A8 | "Massive" branded socket |
| `NetworkHeap 2200K` | 0x007AF465 | 2.2MB network heap |
| `GM: Peer Mesh connection sent to host for player %d` | 0x00762DFC | Peer mesh networking |
| `GM: Received join complete for player %i.` | 0x00763464 | Join protocol |
| `GMLAN: Cannot open broadcast socket!` | 0x00763AD4 | LAN discovery |
| `NetworkQueueOutgoingLength %d` | 0x0075E801 | Queue tuning |
| `GameNetworkTimeoutMS %d` | 0x0075EA01 | Timeout config |

### Lua Network API

`IsMultiplayer`, `IsCoopMultiplayer`, `IsServer`, `IsClient`, `IsLobby`, `IsDedicated`, `ConnectToServer`, `StartServer`, `EnterLobby`, `ExitFriendsLobby`, `IsOnlineConnected`, `IsMatchmakingInternet`

### Sync System

`NetSynchImportModule` (0x007D1830), `SynchNetImportModule` (0x007D1D90) — modules can be network-synchronized.  
`NetClientAddBoundary`, `NetClientRemoveBoundary` — boundaries replicate to clients.

---

## 12. Localization

- `[localization]` (0x007AF208) — INI section header for localization config
- `ClearStringDb` (0x007BA118) / `AddStringDb` (0x007BA128) — Lua functions for managing string databases
- `GetLanguageName`, `GetLanguageNum`, `GetLanguage` — language query functions
- Supported languages: `English`, `French`, `German`, `Italian`, `Japanese`, `Russian`, `Spanish` (all at 0x007BA530-0x007BA574)

String resolution likely uses the `[contract` prefix pattern and the string DB loaded by `AddStringDb`.

---

## 13. Audio System

### PWS Audio

`.pws` file extension at 0x007BD000 — confirmed as the audio container format.

### Audio Lua API

Extensive audio control: `LoadBank`, `LoadSoundBank`, `LoadWaveBank`, `UnloadBank`, `CueSound`, `StopSound`, `PauseSound`, `SetMasterVolume`, `SetCategoryVolume`, `SetCategoryPitch`, `SetReverb`, `DefineReverbPreset`, `SetLowPassFilter`, `CueAmbience`, `StopAmbience`, `SilenceAmbience`, `SetStreamBlockDumping`, `RequestAmbienceBank`

### Dynamic Music System

Full dynamic music engine: `SetDynamicMusic`, `SetFactionMusic`, `AddFactionMusic`, `LockFactionMusic`, `SetActionLevelsMusic`, `LockActionLevelMusic`, `TransitionMusic`, `BindMusicCue`, `AddMusicState`, `AddMusicTransition`, `SetSourceMusic`, `SetSourceEnterMusic`, `SetSourceExitMusic`, `ActivateFactionRegionMusic`, `SetHijackMusic`

### VO System

- `VO.PRIORITY_SCRIPTED_BRIEFING = 1` (0x007BA92B)
- `VO.PRIORITY_SCRIPTED_CONTRACT = 2`
- `VO.PRIORITY_SCRIPTED_BOUNDTIES = 3`
- `VO.PRIORITY_SCRIPTED_FREEPLAY = 4`
- `AddSequence`, `RemoveSequence`, `Cue`, `CueWithoutSubtitles`, `Cancel`, `CancelAll`, `Pause`, `PauseAll`, `Unpause`, `UnpauseAll`

---

## 14. Save System

- Save path: `\My Games\Mercenaries 2\SaveGames\` (0x007B38A4)
- Lua functions: `SaveGame`, `SaveComplete`, `LoadGame`, `SaveData`, `LoadSingleton`, `SaveSingleton`, `ResetSingleton`, `SetLuaSaveVersion`, `InitialSaveData`, `Autosave`, `ClientRestorePreSaveCash`, `ClientReimburseForSave`
- Save states: `saveCompleteContinue`, `preopComplete`, `savepreopnomu`, `savepreopnospace`
- Settings: `SettingsSerializer::Init(): Registry key not found!` (0x007D39D4) — settings stored in Windows registry

---

## 15. Engine Memory Heaps

| Heap | Size | Offset |
|---|---|---|
| `MainHeap` | 608 MB | 0x007AF3F7 |
| `MainHeapBlocks` | 28000 | 0x007AF406 |
| `MainHeapAlign` | 16 | 0x007AF41C |
| `ScriptHeap` | 0 (dynamic) | 0x007AF42E |
| `ScriptHeapBlocks` | 800 | 0x007AF43C |
| `ScriptHeapAlign` | 4 | 0x007AF452 |
| `NetworkHeap` | 2200K (# 700K) | 0x007AF465 |
| `SoundHeap` | 0 (dynamic) | 0x007AF47F |
| `DeviceHeap` | 0 (dynamic) | 0x007AF48C |
| `SystemHeap` | 0 (dynamic) | 0x007AF49A |

---

## 16. Havok Integration

- **Havok Physics**: `Havok Physics evaluation key has expired or is invalid.` (0x0076D810)
- **Havok Animation**: `Havok Animation evaluation key has expired or is invalid.` (0x0076B870)
- **Version**: `** Havok libs built with version [` (0x0075900C)
- Build path: `q:\Build\code\Complete\Source\` (Havok SDK build tree)
- Socket: `.\System\Io\Socket\Bsd\hkBsdSocket.cpp` (0x00714EA4)
- 180+ Havok RTTI classes in the exe (physics shapes, constraints, animation, ragdoll)
- Compression types present: `HK_SPLINE_COMPRESSED_ANIMATION`, `HK_WAVELET_COMPRESSED_ANIMATION`, `HK_DELTA_COMPRESSED_ANIMATION`

---

## 17. Why Auto-Complete Mod Might Not Fire

Based on this analysis, the likely reasons a Lua auto-complete mod doesn't work:

1. **`ContractCompleted` is a C++ function, not a Lua event** — calling `self:Complete()` from Lua triggers the C++ `ContractCompleted` handler, which may require specific engine state (active contract, correct player state)

2. **Event system uses typed dispatchers** — `ProcessEventImmediate` (0x007BC160) and `GetEventListTable` (0x007BC14C) suggest events go through a registration system. The mod may not have the right event listeners registered.

3. **Module environment isolation** — `import()` uses `getfenv(2)` to scope modules. A mod injected at the wrong scope level won't have access to the contract's environment.

4. **Network sync** — `NetSynchImportModule` / `SynchNetImportModule` suggest module imports may need network synchronization even in single-player (the game uses client-server architecture internally).

5. **State machine gating** — `StateMachine` component (768 pool slots) and `DebugStateMachine` / `PrintStateMachine` suggest contracts go through state machine transitions that can't be skipped.

---

## Appendix A: Build Environment

```
Build machine path: D:\Projects\Mercs2_PC\mercs2\
Havok SDK path:     q:\Build\code\Complete\Source\
Original exe name:  Mercs2_PC_F.exe
SecuROM path:       C:\merc2\Mercenaries2.exe (0x01D24900)
Build username:     Administrator (leaked in SecuROM env vars)
```

## Appendix B: Third-Party Libraries

| Library | Version | Evidence |
|---|---|---|
| Lua | 5.1.2 | Copyright string, source paths |
| zlib | 1.2.3 | deflate/inflate version strings |
| Havok Physics | 5.5.x | RTTI, build paths |
| Havok Animation | 5.5.x | RTTI, build paths |
| Scaleform GFx | (unknown ver) | Exported GFx classes, ActionScript strings |
| Bink Video | (via binkw32.dll) | Import table |
| OpenSSL | 0.9.8d | `lhash part of OpenSSL 0.9.8d 28 Sep 2006` |
| EASTL | (unknown ver) | `EASTL hash_set` (0x00762FB4) |
| GameSpy Voice | (via GV*) | `GVInitialize: Failed to create socket` |
| DirectX 9.0c | (d3dx9_36) | Import table |
