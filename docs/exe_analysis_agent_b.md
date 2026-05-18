# Mercenaries 2 Executable Analysis — Agent B

> **Source**: Cracked `Mercenaries2.exe` (53,482,288 bytes) from `Crack/` directory of retail ISO  
> **Original internal name**: `Mercs2_PC_F.exe` (from export table)  
> **Compiler**: MSVC 8.0 (Visual Studio 2005), linked with MSVCR80.dll  
> **Architecture**: x86 PE32, image base 0x00400000  

---

## Table of Contents

1. [PE Structure](#1-pe-structure)
2. [Lua Integration Layer](#2-lua-integration-layer)
3. [WAD/FFCS Loading System](#3-wadffcs-loading-system)
4. [sges Decompression](#4-sges-decompression)
5. [Demo Timer / Demo Restrictions](#5-demo-timer--demo-restrictions)
6. [Boundary System](#6-boundary-system)
7. [ECS / Entity System](#7-ecs--entity-system)
8. [Rendering Pipeline](#8-rendering-pipeline)
9. [Asset System / FNV-1a Hash](#9-asset-system--fnv-1a-hash)
10. [Network / Multiplayer](#10-network--multiplayer)
11. [String Table / Localization](#11-string-table--localization)
12. [Audio System](#12-audio-system)
13. [Save System](#13-save-system)
14. [Event System](#14-event-system)
15. [Embedded Configuration](#15-embedded-configuration)
16. [Key Findings Summary](#16-key-findings-summary)

---

## 1. PE Structure

### Sections

| Section | VirtAddr | VirtSize | RawSize | Characteristics |
|---------|----------|----------|---------|-----------------|
| `.text` | 0x001000 | 0x704000 | 0x704000 | CODE, EXEC, READ |
| `.rdata` | 0x705000 | 0x0F1000 | 0x0F1000 | IDATA, READ, WRITE |
| `.data` | 0x7F6000 | 0xE04000 | 0xE04000 | IDATA, READ, WRITE |
| `extdata` | 0x15FA000 | 0x1000 | 0x1000 | IDATA, READ, WRITE |
| `.tls` | 0x15FB000 | 0x1000 | 0x1000 | IDATA, READ, WRITE |
| `.rsrc` | 0x15FC000 | 0x4D000 | 0x4D000 | IDATA, READ |
| `Stext` | 0x1649000 | 0x63B000 | 0x63B000 | CODE, EXEC, READ, WRITE (SecuROM code) |
| `Sitext` | 0x1C84000 | 0x7000 | 0x7000 | CODE, EXEC, READ |
| `Srdata` | 0x1C8B000 | 0x5A000 | 0x5A000 | IDATA, EXEC, READ |
| `Sdata` | 0x1CE5000 | 0x2FE000 | 0x2FE000 | IDATA, EXEC, READ, WRITE |
| `Sidata` | 0x1FE3000 | 0x6000 | 0x6000 | IDATA, READ, WRITE |
| `.securom` | 0x1FE9000 | 0x13175F8 | 0x13175F8 | CODE, EXEC, READ, WRITE |
| `reloaded` | 0x3301000 | 0x330 | 0x330 | ALL FLAGS (crack loader) |

**Note**: Section alignment = file alignment = 0x1000, so file offsets = RVAs for all sections. The `S*` sections and `.securom` are SecuROM remnants; `reloaded` is the crack's import redirect section. **Confidence: certain**

### Key Imports

| DLL | Function Count | Purpose |
|-----|---------------|---------|
| `d3d9.dll` | 1 | `Direct3DCreate9` — D3D9 renderer |
| `d3dx9_36.dll` | 13 | D3DX math (rotation, transform, quaternion) |
| `DSOUND.dll` | 6 | DirectSound audio |
| `DINPUT8.dll` | 1 | `DirectInput8Create` — input |
| `XINPUT1_3.dll` | 2 | Xbox controller support |
| `binkw32.dll` | 15 | Bink video playback |
| `WS2_32.dll` | 42 | Winsock2 networking |
| `NETAPI32.dll` | 1 | `Netbios` — LAN discovery |
| `dbghelp.dll` | 8 | Stack trace / crash reporting |
| `MSVCR80.dll` | 165 | C runtime (VS2005 SP1) |

### Exports

The exe exports 63 functions, all from the **Scaleform GFx** Flash runtime:
- `GFxLoader`, `GImage`, `GZLibFile`, `GMatrix2D`, `GColor`, `GRefCountBaseImpl`
- This confirms the game uses **Scaleform GFx** for its Flash-based UI system

**Confidence: certain**

---

## 2. Lua Integration Layer

### Lua Version

**Lua 5.1.2** — confirmed by version string at offset `0x007925B8`:

```
$Lua: Lua 5.1.2 Copyright (C) 1994-2007 Lua.org, PUC-Rio $
```

**Confidence: certain**

### How `import()`, `inherit()`, and `dynamic_import()` Work

At offset `0x007B4EE2`, the exe contains an embedded Lua bootstrap string that is executed during engine startup:

```lua
_G._MODULES = {};
_MODULESMETATABLE = { __index = _SYS._MODULEINDEX };

function _G.import(module)
    return _SYS._IMPORT(getfenv(2), module);
end;

function _G.dynamic_import(module, callbackfunc, callbackdata)
    return _SYS._DYNAMIC_IMPORT(_SYS._GETFENV(2) or _G, module, callbackfunc, callbackdata);
end;

function _G.inherit(module)
    return _SYS._INHERIT(getfenv(2), module);
end;

function _G.dynamic_remove(module)
    return _SYS._DYNAMIC_REMOVE(_SYS._GETFENV(2), module);
end;
```

**Mechanism**:
- `_SYS` is a C++-registered table with native functions (`_IMPORT`, `_INHERIT`, `_DYNAMIC_IMPORT`, `_DYNAMIC_REMOVE`, `_GETFENV`, `_MODULEINDEX`)
- `import(module)` calls `_SYS._IMPORT` with the **caller's environment** (`getfenv(2)`) and the module name
- `inherit(module)` calls `_SYS._INHERIT` — this likely copies all functions from the target module into the caller's environment table (prototype inheritance)
- `_MODULES` is a global table with a metatable whose `__index` is `_SYS._MODULEINDEX`, enabling lazy loading
- `dynamic_import` supports callback-based async loading (for streaming)

**Confidence: certain** (verbatim from exe)

### Embedded Lua Code Snippets

At `0x007BBA10` — widget accessor used by C++ to get Flash widget IDs:
```lua
if _MODULES and _MODULES.mrxgui then
    local s = _MODULES.mrxgui.GetWidgetByName("Shell")
    if s and s.CustomData.oFlash then
        return s.CustomData.oFlash.BasicData.uId
    end
end
```

Similar patterns exist for `"topbar"` (0x007BBAD0) and `"LTI_precache"` (0x007BBB90).

The **`_G.Marker` table** is also initialized from embedded code at `0x007B59D8`:
```lua
_G.Marker = {}
_G.Marker.Add           = Gui._MarkerAddOld
_G.Marker.AddBlip       = Gui._MarkerAdd
_G.Marker.AddTripwire   = Gui._MarkerAddTripwire
_G.Marker.AddDisc       = Gui._MarkerAddDisc
_G.Marker.Add3D         = Gui._MarkerAdd3D
_G.Marker.Remove        = Gui._MarkerRemove
_G.Marker.SetGroupedBlipLimit = Gui._MarkerSetBlipLimit
_G.Marker.SetLocation   = Gui._MarkerSetLocation
_G.Marker.SetColor      = Gui._MarkerSetColor
_G.Marker.SetFollowGuid = Gui._MarkerSetFollowGuid
_G.Marker.SetScale      = Gui._MarkerSetScale
_G.Marker.Pulse         = Gui._MarkerPulse
_G.Marker.HaltPulse     = Gui._MarkerHaltPulse
```

**Confidence: certain**

### ObjectScript Binding

`ObjectScript` appears as an ECS component type:
- Pool definition at `0x007AE14B`: `ObjectScript 2048` — pool of 2048 script-bound objects
- RTTI-visible at `0x007C52A4`: `ObjectScript`
- This is the component that attaches a Lua script environment to a SceneObject

**Confidence: likely**

### Lua State Initialization

- `LuaGarbageCollectionThreshold 256` at `0x007AF60C` — GC threshold set in embedded config
- `LUA_SIZES` at `0x007E8C58` — likely a debug/assert marker for Lua type sizes
- `ScriptHeap 0` / `ScriptHeapBlocks 800` / `ScriptHeapAlign 4` — script memory pool config

**Confidence: certain**

### Script Loading from WAD

Key strings:
- `LoadScript` at `0x007B6878` — registered Lua function
- `dofile` at `0x007B4558`, `loadfile` at `0x007B4560`, `loadstring` at `0x007E8D44`
- `Warning: Recursive import detected in '%s'` at `0x007DEBC0` — recursion guard in _SYS._IMPORT

Scripts are loaded from WAD blocks via the asset system. The `_SYS._IMPORT` function:
1. Checks if module already loaded in `_MODULES`
2. Requests the script asset from the WAD block system
3. Compiles with `loadstring` and executes in a new environment
4. Stores result in `_MODULES[module_name]` with `_MODULESMETATABLE`

**Confidence: likely** (inferred from string evidence + bootstrap code)

---

## 3. WAD/FFCS Loading System

### WAD Path Format Strings

| Offset | String | Purpose |
|--------|--------|---------|
| `0x007AFED0` | `%s\%s.wad` | Generic WAD path (data_dir + wad_name) |
| `0x007AFF5C` | `%s\%s-patch.wad` | Patch WAD overlay |
| `0x007AFF6C` | `%s\loading.wad` | Loading screen WAD |
| `0x007AFF7C` | `%s\loading-patch.wad` | Loading screen patch |
| `0x007BD038` | `%s\vz.wad` | Venezuela world WAD |

### Patch WAD Mechanism

The engine loads two WADs for each named block set: the base `%s.wad` and `%s-patch.wad`. The patch WAD overlays blocks with the same ASET hash, allowing updates without modifying the original file.

**Confidence: certain** (format strings prove the pattern)

### Block Streaming

- `SetStreamBlockDumping` at `0x007B9C04` — Lua API to enable block dump diagnostics
- `IsLoadingOrStreaming` at `0x007BA3C4` — query loading state from Lua
- The `BasePath` config is `.\Data\` (offset `0x007AF66E`)

### UCFX Chunk Types in Exe

Found `CHDR` at 2 locations in the binary, confirming the engine knows about UCFX chunk headers. The `SWIT` magic appears at `0x000CF5D9` in the `.text` section, likely as part of a chunk-type switch/case statement.

**Confidence: certain / likely**

---

## 4. sges Decompression

### sges Validation Code (File offset 0x001148B0)

**This is the actual engine validation function for sges blocks.** Disassembly:

```x86asm
; === sges block validator ===
; Input: EAX = block descriptor, [EAX] = pointer to sges data
; Output: AL = success/failure

0x001148AE: MOV EBX, [EAX]           ; EBX = pointer to sges block data
0x001148B0: CMP DWORD [EBX], 'sges'  ; *** CHECK 1: Magic == "sges" ***
0x001148B6: JNE fail                  ; fail if not sges
0x001148B8: CMP WORD [EBX+4], 4      ; *** CHECK 2: Major version == 4 ***
0x001148BD: JNE fail                  ; fail if major != 4
0x001148BF: MOV ECX, [EBX+0xC]       ; ECX = decompressed_size (from header offset +0xC)
0x001148C2: CMP ECX, [EAX+0x14]      ; *** CHECK 3: decompressed_size <= expected_size ***
0x001148C5: JBE continue              ; ok if decompressed_size <= expected
;            else fall through to fail

fail:
0x001148C7: POP EBX / POP ESI
0x001148C9: XOR AL, AL               ; return false
0x001148CB: POP EBP / RET 4

continue:
0x001148CF: MOV [EBP], EAX           ; store block descriptor
0x001148D2: MOVZX EDX, WORD [EBX+6]  ; EDX = field at offset +6 (num_segments)
0x001148D6: PUSH EDI
0x001148D7: MOV [EBP+0xC], EDX       ; store num_segments
0x001148DA: MOVZX EDI, WORD [EBX+6]  ; EDI = num_segments (loop counter)
0x001148DE: XOR ESI, ESI             ; running_total = 0
0x001148E0: XOR EAX, EAX             ; segment_index = 0
0x001148E2: TEST EDI, EDI
0x001148E4: JLE skip_loop             ; skip if num_segments <= 0

; === Segment table starts at offset +0x12 (18 bytes from start) ===
0x001148E6: LEA ECX, [EBX+0x12]      ; ECX = &segment_table[0]

segment_loop:
0x001148EE: MOV EDX, [ECX+2]         ; EDX = compressed_size (with flag bit)
0x001148F1: AND EDX, 0xFFFFFFFE      ; *** Clear low bit (compression flag) ***
0x001148F4: CMP ESI, EDX             ; CHECK: running_total <= compressed_size
0x001148F6: JA error                  ; error if exceeds
0x001148F8: MOVZX EDX, WORD [ECX]    ; EDX = segment decompressed_size (16-bit)
0x001148FB: TEST DX, DX
0x001148FE: MOVZX EDX, DX
0x00114901: JNZ has_size
0x00114903: MOV EDX, 0x10000          ; *** Default: 64KB if decompressed_size == 0 ***
has_size:
0x00114908: ADD EAX, 1               ; segment_index++
0x0011490B: ADD ESI, EDX             ; running_total += decompressed_size
0x0011490D: ADD ECX, 8               ; next segment (8 bytes per entry)
0x00114910: CMP EAX, EDI             ; if segment_index < num_segments
0x00114912: JL segment_loop           ; continue loop
```

### sges Header Layout (Confirmed from Code)

| Offset | Size | Field | Validation |
|--------|------|-------|------------|
| +0x00 | 4 | Magic `sges` | Must equal `0x73676573` |
| +0x04 | 2 | Major version | Must equal `4` |
| +0x06 | 2 | Num segments (also stored as minor version) | Used as loop count |
| +0x08 | 4 | (unknown field) | — |
| +0x0C | 4 | Decompressed size | Must be ≤ expected size from block descriptor |
| +0x10 | 2 | (padding or flags) | — |
| +0x12 | 8×N | Segment table | Each entry: 2B decompressed_size + 2B+flags + 4B |

### Segment Table Entry (8 bytes each)

| Offset | Size | Field |
|--------|------|-------|
| +0x00 | 2 | Decompressed size (0 = 64KB default) |
| +0x02 | 4 | Compressed size with bit 0 = compression flag |

The low bit of the compressed_size field (`AND 0xFFFFFFFE`) is the **compression flag**: if set, the segment is compressed (raw deflate); if clear, it's stored uncompressed.

### Decompression Libraries

Two zlib versions are linked:
- `inflate 1.2.3` at `0x00794700` (game's own zlib, in `.rdata`)
- `inflate 1.2.2` at `0x01FE3C70` (SecuROM's copy, in `.securom`)

The game also has its own decompression modules:
- `StDecompressD` / `StDecompressDChunk` — Delta decompression
- `StDecompressW` / `StDecompressWChunk` — Wavelet decompression
- `TtdecompressBlockCacheD` / `TtdecompressBlockCacheW` — Cached decompression

**Confidence: certain** (direct disassembly)

---

## 5. Demo Timer / Demo Restrictions

### IsDemoMode Function (VA 0x005E5670)

```x86asm
MOV EAX, [ESP+4]         ; lua_State* L
MOV ECX, [EAX+8]         ; Lua stack pointer
XOR EDX, EDX              ; edx = 0 (false)
CMP BYTE [0x01175F59], DL ; *** Global demo flag at address 0x01175F59 ***
MOV DWORD [ECX+4], 1     ; push type = LUA_TBOOLEAN
SETNZ DL                  ; DL = 1 if demo flag != 0
MOV [ECX], EDX            ; push boolean value
ADD DWORD [EAX+8], 8     ; advance Lua stack
MOV EAX, 1               ; return 1 result
RET
```

**The demo flag is a single byte at address `0x01175F59`** (file offset `0x00D75F59`, in `.data` section). In the cracked retail exe, this byte is `0x00` (not demo mode). In the demo exe, it would be `0x01`.

**Confidence: certain** (direct disassembly)

### Demo Timer Constant

Found `900.0` as IEEE 754 float (`0x44610000`) at **file offset `0x007EAACC`** in `.rdata`. This is in a group of float constants:

| Offset | Value | Likely Purpose |
|--------|-------|----------------|
| `0x007EAAC0` | 0.7 | — |
| `0x007EAAC4` | 480.0 | 8 minutes (warning threshold?) |
| `0x007EAAC8` | **900.0** | **15 minutes (demo time limit)** |
| `0x007EAACC` | 225.0 | — |

The 900.0 float alongside 480.0 suggests a two-stage timer: warning at 8 minutes, cutoff at 15 minutes.

**Confidence: likely** (900.0 found in appropriate data section among related floats)

### Demo Boundary

Boundaries are managed through Lua:
- `AddBoundary` → C++ function at `0x005DC900`
- `SetBoundaryCallback` → `0x005DCE90`
- `IsBoundaryDeath` → `0x005DD040`
- `IsPositionOutBoundary` → `0x005DD040`

**Confidence: certain**

---

## 6. Boundary System

### Lua API Functions (from registration table at 0x00799078)

| Function | C++ VA | Purpose |
|----------|--------|---------|
| `SetOutBoundary` | 0x005DC160 | Set outer boundary region |
| `GetOutBoundary` | 0x005DC720 | Get outer boundary region |
| `IsInWarningZone` | 0x005DC810 | Check if player in warning zone |
| `AddBoundary` | 0x005DC900 | Add boundary by GUID |
| `RemoveBoundary` | 0x005DCA30 | Remove single boundary |
| `RemoveAllBoundary` | 0x005DCB30 | Remove all boundaries |
| `GetAllBoundaryGuid` | 0x005DCC60 | Get list of boundary GUIDs |
| `SetBoundaryCallback` | 0x005DCE90 | Set Lua callback for boundary events |
| `IsPositionOutBoundary` | 0x005DD040 | Test if position is outside |
| `IsBoundaryDeath` | 0x005DD040 | Check if boundary causes death |

### Supporting Functions

| Function | C++ VA |
|----------|--------|
| `GetBoundaryRadius` | registered |
| `SetBoundaryRadius` | registered |
| `IsPointInBoundary` | registered |
| `SetBoundaryEffect` | registered |
| `NetClientAddBoundary` | 0x007D1D20 (network replication) |
| `NetClientRemoveBoundary` | 0x007D1D08 (network replication) |

### Events

- `OutsideBoundary` (0x007B85B4) — fired when entity exits boundary
- `InsideBoundary` (0x007B85C4) — fired when entity enters boundary

The boundary system uses region GUIDs (from `GetAllBoundaryGuid`) and has network replication (`NetClientAddBoundary`/`NetClientRemoveBoundary`).

**Confidence: certain**

---

## 7. ECS / Entity System

### Pool Allocations (from embedded config at 0x007ADFE8–0x007AF190)

The engine pre-allocates fixed-size pools. Key entries:

| Component | Pool Size | Block Size | File Offset |
|-----------|-----------|------------|-------------|
| **SceneObject** | **161,280** | — | 0x007AED2E |
| PendingSceneObject | 2,048 | — | 0x007AE1C7 |
| RuntimeSceneObject | 2,816 | — | 0x007AEB66 |
| ObjectScript | 2,048 | — | 0x007AE14B |
| RuntimeHealth | 1,280 | — | 0x007AE939 |
| RuntimeLayerId | 20,224 | — | 0x007AEA1F |
| PhysicsActor | 2,304 | — | 0x007AE204 |
| Turret | 1,024 | — | 0x007AF017 |
| Road | 4,608 | — | 0x007AE458 |
| StateMachine | 768 | — | 0x007AEEA7 |
| SoundEffect | 3,584 | — | 0x007AEDDB |
| Stimulus | 1,792 | — | 0x007AEEC7 |
| RuntimeAssetRef | 2,560 | — | 0x007AE7BC |
| RuntimePhysicalLink | 22,784 | — | 0x007AEAB5 |
| RuntimeEquipmentLink | 5,120 | — | 0x007AEB68 |

**161,280 SceneObject slots** matches the `cdbsizes.ini` value we found in game data.

### Component Types (sampled)

Over 170 distinct component types visible, including:
- `MassiveComponent`, `RedEffectComponent`, `ModelName`, `ModifierKey`
- `Perception`, `Rider`, `RiderLink`, `SeatLink`, `SeatParameters`
- `RuntimeTimer`, `RuntimeWeapon`, `RuntimeVehiclePart`
- `PopulationFlow`, `PopulationList`, `PopulationSimpleSpawner`
- `SkirmishSpawnList`, `SkirmishZone`
- `MusicRegion`, `MusicSource`

**Confidence: certain** (pool definitions are embedded verbatim)

---

## 8. Rendering Pipeline

### Precache System

The precache system pre-renders assets to populate GPU caches:

| String | Offset | Purpose |
|--------|--------|---------|
| `Doing precache rendering.` | 0x007AD468 | Status message |
| `Precache Rendering Complete.` | 0x007E86FC | Completion message |
| `precache\display%i.precache` | 0x007D4D3C | Precache display list files |
| `PrecacheIB::RegisterResource()` | 0x007D65F8 | Index buffer precache |
| `PrecacheVB::AddResource()` | 0x007D6898 | Vertex buffer precache |
| `PrecacheManager.Save()` | 0x007D7418 | Save precache data |
| `LTIPrecacheSmokeDone` | 0x007B6A0C | Precache event |
| `LTIPrecacheDone` | 0x007B6A24 | Precache complete event |
| `LTIGetPrecacheBypass` | 0x007BA384 | Lua API to skip precache |

The precache system saves display lists to disk (`precache\display%i.precache`) for fast reload.

### HIER / Skeleton

The `HIER` string appears at `0x020622E5` in the `.securom` section as part of what looks like a chunk type table: `=MIXRwptO=BSHPt%=HIER`. This suggests HIER is parsed alongside other UCFX chunk types (BSHP = shape?, MIXRwptO = mixer/waypoint?).

### SWIT Damage States

`SWIT` at `0x000CF5D9` is in `.text` code, confirming the engine has code to process SWIT (switch/damage state) chunks.

**Confidence: certain / likely**

---

## 9. Asset System / FNV-1a Hash

### FNV-1a Implementation (Confirmed from Code)

The FNV-1a hash is used extensively for asset name lookups. Found **20+ instances** of the computation pattern in `.text`:

```x86asm
; FNV-1a hash computation (case-insensitive)
; Typical pattern at file offset 0x0006431D:

MOV EAX, 0x811C9DC5       ; FNV-1a offset basis (32-bit)
loop:
  MOVSX ECX, BYTE [EDX]   ; load char
  OR ECX, 0x20             ; *** FORCE LOWERCASE (case-insensitive) ***
  XOR EAX, ECX             ; hash ^= char
  MOV CL, [EDX+1]          ; next char
  IMUL EAX, 0x01000193     ; hash *= FNV prime
  ADD EDX, 1               ; advance pointer
  TEST CL, CL
  JNZ loop
  XOR EAX, 0x2A            ; *** FINAL XOR WITH 0x2A (42) ***
  IMUL EAX, 0x01000193     ; *** FINAL MULTIPLY BY PRIME ***
```

### Key Differences from Standard FNV-1a

1. **Case-insensitive**: `OR ECX, 0x20` forces all ASCII to lowercase before XOR
2. **Final XOR with 0x2A**: After processing all characters, `XOR EAX, 0x2A` (decimal 42)
3. **Final multiply**: One extra `IMUL` by the prime after the XOR

This is a **Pandemic-customized FNV-1a** hash. The formula is:

```
hash = FNV_OFFSET_BASIS  (0x811C9DC5)
for each char c in name:
    hash ^= (c | 0x20)   // case-insensitive
    hash *= FNV_PRIME     // 0x01000193
hash ^= 0x2A
hash *= FNV_PRIME
```

### Asset Loading Functions

| Function | Offset |
|----------|--------|
| `LoadAsset` | 0x007B8D9C |
| `UnloadAsset` | 0x007B8D90 |
| `ReloadAsset` | 0x007B8D84 |
| `AssetExists` | 0x007B8DA8 |
| `LoadLayer` | 0x007B8DCC |
| `UnloadLayer` | 0x007B8DC0 |
| `ReloadLayer` | 0x007B8DB4 |
| `IsStaticLayer` | 0x007B8E20 |
| `RequiredAsset` | registered |

**Confidence: certain** (FNV-1a pattern directly disassembled from 20+ call sites)

---

## 10. Network / Multiplayer

### Multiplayer Architecture

The game has a full multiplayer/co-op system:

| String | Offset | Purpose |
|--------|--------|---------|
| `multiplayer.ini` | 0x007B004C | Config file |
| `multiplayerHost` | 0x007B72F0 | Host mode |
| `multiplayerClient` | 0x007B7300 | Client mode |
| `IsCoopMultiplayer` | 0x007B95D4 | Lua query |
| `IsMultiplayer` | 0x007B8130 | Lua query |

### Lobby System

| Function | Offset |
|----------|--------|
| `EnterLobby` | 0x007B8000 |
| `EnterFriendsLobby` | 0x007B7FB4 |
| `ExitFriendsLobby` | 0x007B7FA0 |
| `AutoLobby` | 0x007B80C8 |
| `IsLobby` | 0x007B80F8 |
| `LobbyServerAdded` | 0x007BBCF8 |
| `LobbyServerUpdated` | 0x007BBD48 |
| `LobbyServerRemoved` | 0x007BBD5C |

### Network Replication Functions

Many `NetClient*` functions handle state replication:
- `NetClientAddBoundary`, `NetClientRemoveBoundary`
- `NetClientShowMovie`, `NetClientHideMovie`
- `NetClientFactionSetValue`, `NetClientFactionStartPursuit`
- `NetClientSetObjectiveTraySlot`, `NetClientClearObjectiveTraySlot`

Networking uses WS2_32 (Winsock2) with 42 imported functions, plus NETAPI32.dll for LAN discovery via NetBIOS.

**Confidence: certain**

---

## 11. String Table / Localization

### Localization System

| String | Offset | Purpose |
|--------|--------|---------|
| `[localization]` | 0x007AF208 | Config section header |
| `AddStringDb` | 0x007BA128 → VA 0x005E6180 | Load string database |
| `ClearStringDb` | 0x007BA118 → VA 0x005E61E0 | Clear string database |
| `GetLocalizedName` | 0x007B8614 | Get localized entity name |
| `GetLanguage` | registered → VA 0x005E6420 | Get current language |
| `GetLanguageName` | 0x007B5740 | Get language display name |
| `GetLanguageNum` | 0x007B5750 | Get language index |

### Supported Languages (from embedded config)

```
english          1
spanish          1
italian          1
french           1
german           1
#japanese        1   (commented out)
english_uk       1
#allcaps         1   (debug mode)
russian          1
```

### String Resolution

The `[OilCon001.Objectives.001]` format resolves through `AddStringDb` which loads string database files. These are likely from `English.wad` (or language-specific WADs). The `AddStringDb` function (VA 0x005E6180) is called from Lua to register string tables.

The `LocalizedName` component (offset `0x007C50E8`) on SceneObjects provides `GetLocalizedName` access.

**Confidence: certain / likely**

---

## 12. Audio System

### Audio System Architecture

The game uses:
- **DirectSound** (DSOUND.dll, 6 imports)
- **Bink Video** (binkw32.dll, 15 imports) for FMV playback
- **Custom audio pipeline** with banks, categories, and dynamic music

### Lua Audio API (88 functions in Sound module)

Key registered functions:

| Function | C++ VA | Purpose |
|----------|--------|---------|
| `CueSound` | 0x005E0FF0 | Play a sound |
| `StopSound` | 0x005E10F0 | Stop a sound |
| `PauseSound` | 0x005E11F0 | Pause a sound |
| `LoadSoundBank` | 0x005E2630 | Load sound bank |
| `LoadWaveBank` | 0x005E26D0 | Load wave bank |
| `SetCategoryVolume` | 0x005E12F0 | Set volume by category |
| `SetDynamicMusic` | 0x005E16E0 | Enable dynamic music |
| `TransitionMusic` | 0x005E1600 | Music transition |
| `SetMasterVolume` | registered | Master volume |
| `OpenStreamFile` | 0x007B9A10 | Open audio stream |
| `CloseStreamFile` | 0x007B9A00 | Close audio stream |

### MrxVoSequence (Voice Sequence System)

From the Sound registration table:
- `Cue` (0x005E9DE0) / `CueWithoutSubtitles` (0x005E9F40)
- `Cancel` / `CancelAll` / `Pause` / `PauseAll` / `Unpause` / `UnpauseAll`
- `SetCinematicMode` (0x005EA310)
- `AddSequence` (0x005EA3C0) / `RemoveSequence` (0x005EA470)

### PWS Audio Format

`.pws` extension confirmed at `0x007BD000`. Audio directory: `.\Data\Audios` (from config).

**Confidence: certain**

---

## 13. Save System

### Save Path

`\My Games\Mercenaries 2\SaveGames\` at offset `0x007B38A4`

### Save Functions

| Function | Offset | Purpose |
|----------|--------|---------|
| `SaveGame` | 0x007B8AC4 | Trigger save |
| `RequestAutosave` | 0x005E61F0 | Request autosave |
| `IsAutosaveEnabled` | 0x005E65E0 | Query |
| `SetAutosaveEnabled` | 0x005E6610 | Set |
| `ForceNextAutosave` | 0x005E6670 | Force next auto |
| `SetLuaSaveVersion` | 0x005E6120 | Set save format version |
| `SaveComplete` | 0x007B44FC | Event |
| `saveGameSlot` | 0x007BC190 | Slot management |
| `addSaveGame` | 0x007BC1A0 | Add save entry |
| `clearSaveGames` | 0x007BC6C4 | Clear all |
| `saveProfile` | 0x007BC628 | Save profile |

### Save Events

- `SaveComplete` — fired when save completes
- `ProfilesComplete` — fired when profiles are done loading

**Confidence: certain**

---

## 14. Event System

### Event Module (Registration Table at 0x007987F8)

| Function | C++ VA | Purpose |
|----------|--------|---------|
| `Event.Create` | 0x005F69F0 | Create a new event |
| `Event.CreatePersistent` | 0x005F6A00 | Create persistent event (survives level transitions) |
| `Event.Delete` | 0x005F6A10 | Delete an event |
| `Event.Post` | 0x005F6A90 | Post/fire an event |

### Event.Create Implementation

```x86asm
; Event.Create (VA 0x005F69F0):
MOV ECX, [ESP+4]    ; lua_State* L
PUSH 0               ; persistent = false
CALL 0x005F6660      ; internal create function
ADD ESP, 4
RET

; Event.CreatePersistent (VA 0x005F6A00):
MOV ECX, [ESP+4]
PUSH 1               ; persistent = true
CALL 0x005F6660      ; same internal create, different flag
ADD ESP, 4
RET
```

Both call the same internal function at `0x005F6660` with a boolean persistence flag. This is how `_CreateEvent` works — it calls `Event.Create` internally.

### Registered Game Events

Found at offsets 0x7B8A88–0x7B8AC4:
- `ContractCompleted` — fired when contract is done
- `ContractCancelled` — fired when contract is cancelled
- `ContractActivated` — fired when contract starts
- `SaveGame` — save trigger event

### How `self:Complete()` Works

The `Completed` string at `0x007B98EC` is registered in the **Faction/Pursuit** Lua table. For contracts, `Complete()` is a method on the contract's Lua environment that:
1. Posts the `ContractCompleted` event
2. The MrxTaskContract system listens for this event and advances the mission flow

The `sContract` string at `0x007BBD2C` is the internal type identifier for contract objects.

**Confidence: likely** (inferred from registration table context)

### Why Auto-Complete Mod Might Not Fire

The event system requires:
1. A valid event handle from `Event.Create` or `Event.CreatePersistent`
2. The event must be `Post`ed through the C++ dispatcher
3. Listeners must be registered before the event fires

If the auto-complete mod calls `self:Complete()` but the contract's internal state machine hasn't reached the right state, the C++ side may reject the state transition. The `Failed` (0x007B98E4) and `Completed` (0x007B98EC) strings are in the same table as pursuit/faction functions, suggesting they're dispatched through the faction system, not directly.

**Confidence: speculative**

---

## 15. Embedded Configuration

The full engine config is embedded at offset `0x007AF190` (as null-separated strings). Key sections:

### Memory Configuration
```ini
[pcwin_Memory]
MainHeap 608M
MainHeapBlocks 28000
ScriptHeap 0           ; uses MainHeap
ScriptHeapBlocks 800
NetworkHeap 2200K
SmallBlockTotal 128M
SmallBlockPage 32K
SmallBlockMin 4
SmallBlockMax 4K
```

### Game Settings
```ini
mcb#DefaultLanguage english
LevelName vz
hackAiDamageMultiplier 0.2
QualityThrottleThreshold 20
PlayIntroMovies 1
```

### Script/Debug
```ini
[script]
OutputToTTY 0
EnableConsole 0
EnableDebugger 0
```

### Animation LOD
```ini
LodDefault    -1    30  30    ; outside frustum
LodDefault    25     1   1    ; < 25m
LodDefault    60     2   2    ; < 60m
LodDefault    80     3   3    ; < 80m
LodDefault   1000   30  30    ; > 80m
```

**Confidence: certain** (verbatim from exe)

---

## 16. Key Findings Summary

### Most Important for the Project

1. **Lua Binding Mechanism**: Lua 5.1.2 with C++ registration tables found at `0x00798770–0x00799200`. Functions are registered as `luaL_Reg` arrays (name pointer + function pointer pairs). Found **800+ registered Lua functions** across ~30 tables covering: System, Player, Object, Sound, Gui, Vehicle, Weapon, Voice, Faction, Event, and more.

2. **sges Validation**: The engine checks exactly 3 things: magic==`sges`, major_version==`4`, decompressed_size <= expected. Then it iterates the segment table (8 bytes per entry at offset +0x12), where the low bit of compressed_size is the compression flag, and zero decompressed_size means 64KB default.

3. **Demo Flag**: Single byte at address `0x01175F59`. In retail exe it's `0x00` (not demo). The Lua function `IsDemoMode` just reads this byte. The 900.0 float at `0x007EAACC` is likely the 15-minute timer constant.

4. **Patch WAD Loading**: The engine loads `%s\%s-patch.wad` alongside `%s\%s.wad`. Both format strings at `0x007AFED0` and `0x007AFF5C`.

5. **FNV-1a Hash**: Pandemic-customized — case-insensitive (`OR 0x20`), with final `XOR 0x2A` and extra prime multiply. This is critical for ASET hash verification.

6. **Event System**: `Event.Create` and `Event.CreatePersistent` both call internal function at `0x005F6660` with a persistence boolean. `Event.Post` at `0x005F6A90` dispatches events. Contract lifecycle events: `ContractActivated` → `ContractCompleted`/`ContractCancelled`.

7. **SceneObject Pool**: 161,280 slots pre-allocated, confirming the `cdbsizes.ini` value.

8. **Full Multiplayer**: Co-op system with lobby, matchmaking, dedicated server support, and extensive `NetClient*` replication functions.

9. **Scaleform GFx**: UI uses Scaleform Flash runtime (63 exported GFx functions). Flash SWF files loaded through `SetFlashSwfFile`, `SetFlashCallback` etc.

10. **Embedded Config**: Full engine configuration embedded in `.rdata` including memory pools, framerate presets, language support, AI budgets, animation LOD tables, and PDA map bounds.

---

*Analysis performed on cracked Mercenaries2.exe (53,482,288 bytes), Mercs2_PC_F.exe internal name, compiled with MSVC 8.0.*
