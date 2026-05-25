# Comprehensive Lua 5.1.2 C API Audit — Mercenaries 2 EXE

**EXE**: `output/patched/Mercenaries2.exe` (53,482,288 bytes)  
**Format**: PE32, i386, ImageBase 0x00400000  
**Lua Version**: 5.1.2, statically linked, float number type  
**Build Path**: `D:\Projects\Mercs2_PC\mercs2\Lua-5.1.2\src\`

---

## Summary

| Metric | Count |
|--------|-------|
| Diagnostic strings found in .rdata | 155 |
| Registration tables (luaL_Reg) | 58 |
| Named functions from registration tables | 1,285 |
| Functions resolved via string cross-refs | 12 |
| LUA_GLOBALSINDEX references in .text | 77 |
| LUA_REGISTRYINDEX references in .text | 82 |
| LUA_ENVIRONINDEX references in .text | 56 |
| Lua source files confirmed linked | 11 (.c files) |
| Game/Custom Lua bindings | 1,224+ |

---

## PE Section Layout

| Section | VA Range | Raw Offset | Size |
|---------|----------|------------|------|
| .text | 0x00401000–0x00B05000 | 0x00001000 | 0x00704000 |
| .rdata | 0x00B05000–0x00BF6000 | 0x00705000 | 0x000F1000 |
| .data | 0x00BF6000–0x019FA000 | 0x007F6000 | 0x00E04000 |
| Stext | 0x01A49000–0x02084000 | 0x01649000 | 0x0063B000 |
| Srdata | 0x0208B000–0x020E5000 | 0x01C8B000 | 0x0005A000 |

---

## Linked Lua Source Files (11 confirmed)

| File | Assert string count | VA range of strings |
|------|--------------------|--------------------|
| ldo.c | 3 lines | 0x00BE9958–0x00BE9A48 |
| lfunc.c | 10 lines | 0x00BE960C–0x00BE9904 |
| lgc.c | 3 lines | 0x00BE9E68–0x00BE9ED8 |
| llex.c | 2 lines | 0x00BEA0F8–0x00BEA168 |
| lmem.c | 1 line | 0x00BEA260 |
| lparser.c | 6 lines | 0x00BEA3BC–0x00BEA4E8 |
| lstate.c | 9 lines | 0x00BE9330–0x00BE951C |
| lstring.c | 4 lines | 0x00BE9D78–0x00BE9E2C |
| ltable.c | 8 lines | 0x00BE9A98–0x00BE9C4C |
| lundump.c | 6 lines | 0x00BEA6B8–0x00BEA7F4 |
| lzio.c | 1 line | 0x00BE9F10 |

**Not found** (likely stripped or inlined): lapi.c, lauxlib.c, lbaselib.c, lcode.c, ldebug.c, liolib.c, loadlib.c, lobject.c, lopcodes.c, loslib.c, lstrlib.c, ltablib.c, ltm.c, lvm.c, luac.c, lua.c  
(These are still linked — their code is present — but assert strings with file paths were compiled out in release mode for these files.)

---

## Key Internal Lua Functions (Resolved via String Cross-References)

| Function | VA | Identifying String |
|----------|-----|-------------------|
| `luaG_errormsg` | **0x00867D50** | "error in error handling" |
| `lua_resume` | **0x00861AD0** | "cannot resume dead coroutine" |
| `lua_yield` | **0x00861DF0** | "attempt to yield across metamethod/C-call boundary" |
| `luaD_call` | **0x008688D0** | "C stack overflow" |
| `luaD_growstack` | **0x00868261** | "stack overflow" |
| `luaH_newkey` | **0x00865E90** | "table index is nil" / "table index is NaN" |
| `luaV_gettable` | **0x00865D60** | "loop in gettable" |
| `luaV_settable` | **0x00865E90** | "loop in settable" |
| `luaL_argerror` | **0x0085EF70** | "bad argument #%d" |
| `luaM_realloc` | **0x00865690** | "not enough memory" |
| `luaO_str2d` / number format | **0x00865B30** | "%.14g" |
| `luaL_newstate` | **0x008656E3** area | "not enough memory" (push ref) |

---

## Verified Lua C API VAs — Critical Functions for Plugin/Hook Development

> **IMPORTANT — VA CORRECTIONS (2026-05-20)**
>
> Earlier analysis incorrectly identified two VAs. These corrections have been
> verified across 10+ independent call sites and must be used by all future
> agents, hooks, and ASI plugins.
>
> | Wrong VA | Was claimed to be | Actually is |
> |----------|-------------------|-------------|
> | **0x0085F050** | `luaL_loadbuffer` | **`luaL_typerror`** (error raiser) |
> | **0x00868AD0** | `lua_pcall` | **`luaD_pcall`** (internal, not public API) |

### Definitive VA Table

| Function | VA | Type | Calling Convention (LTCG) |
|----------|-----|------|--------------------------|
| **`luaL_loadbuffer`** | **0x00860240** | Public API | EAX=name, EDX=L, stack=[buff, sz]; caller cleans 8 bytes (`add esp, 8`) |
| **`lua_pcall`** | **0x0085DF50** | Public API | EAX=L, ECX=errfunc, EDI=nresults, stack=[nargs]; caller cleans 4 bytes (`add esp, 4` or `pop`) |
| `luaD_pcall` | 0x00868AD0 | Internal | EAX=L, EDX=ef, stack=[func_ptr, ud, old_top]; caller cleans 12 bytes |
| `luaL_typerror` | 0x0085F050 | Public API | EAX=L, EDI=narg, stack=[expected_type_name] |
| `luaL_argerror` | 0x0085EF70 | Public API | (see string cross-refs above) |
| `luaD_call` | 0x008688D0 | Internal | (see string cross-refs above) |
| `f_call` | 0x0085DF30 | Static callback | Used internally by `lua_pcall` as the `luaD_pcall` callback |
| `luaL_checklstring` | 0x0085D860 | Public API | — |
| Type name table | 0x00B920D4 | Data | Array of type name strings |

### Verified Wrappers (cdecl `lua_CFunction` — standard `int f(lua_State* L)`)

| Function | VA | Notes |
|----------|-----|-------|
| `luaB_loadstring` | 0x00860FC0 | Calls `luaL_loadbuffer` (0x00860240) internally |
| `luaB_pcall` | 0x008615F0 | Calls `luaD_pcall` (0x00868AD0) directly (NOT via `lua_pcall`) |

### Example Call Sites (for verification)

**`luaL_loadbuffer`** — from `luaB_loadstring` at 0x00861043:
```
mov eax, ebx       ; eax = chunkname (name)
push ecx           ; push sz
push ebp           ; push buff
mov edx, esi       ; edx = L
call 0x00860240    ; luaL_loadbuffer
add esp, 8         ; caller cleans stack (2 stack args × 4 bytes)
```

**`lua_pcall`** — canonical pattern from 10+ callers:
```
push <nargs>       ; 6A xx (immediate) or register push
xor ecx, ecx      ; errfunc = 0
xor edi, edi       ; nresults = 0 (or "or edi, -1" for LUA_MULTRET)
mov eax, esi       ; eax = L
call 0x0085DF50    ; lua_pcall
```

---

## Pseudo-Index Usage

| Constant | Value | Occurrences in .text |
|----------|-------|---------------------|
| `LUA_REGISTRYINDEX` | -10000 (0xFFFFD8F0) | 82 |
| `LUA_GLOBALSINDEX` | -10002 (0xFFFFD8EE) | 77 |
| `LUA_ENVIRONINDEX` | -10001 (0xFFFFD8EF) | 56 |

These are used via `CMP reg, imm32` and `MOV reg, imm32` patterns, NOT `PUSH imm32`.  
This indicates `lua_getfield`/`lua_setfield` and related functions use register-passed indices rather than stack-pushed arguments (consistent with custom calling conventions or inlined code).

---

## Base Library (luaopen_base) — 24 Functions

Table VA: **0x00B924B8**

| Lua Name | C Function VA | Prologue |
|----------|---------------|----------|
| `assert` | 0x00861350 | `56 8B 74 24 08 8B 46 0C` |
| `collectgarbage` | 0x00860B80 | `53 55 56 57 8B 7C 24 14` |
| `dofile` | 0x008612B0 | `53 56 8B 74 24 0C 8B 46` |
| `error` | 0x00860480 | `56 8B 74 24 08 8B 46 0C` |
| `gcinfo` | 0x00860B40 | `56 57 8B 7C 24 0C 8B 77` |
| `getfenv` | 0x00860790 | `56 8B 74 24 08 6A 01 8B` |
| `getmetatable` | 0x00860570 | `56 8B 74 24 08 8B 46 0C` |
| `loadfile` | 0x00861070 | `53 56 8B 74 24 0C 8B 46` |
| `load` | 0x008611B0 | `83 EC 14 53 55 56 8B 74` |
| `loadstring` | 0x00860FC0 | `51 55 56 8B 74 24 10 57` |
| `next` | 0x00860CE0 | `51 55 56 8B 74 24 10 8B` |
| `pcall` | 0x008615F0 | `55 8B EC 83 E4 F8 83 EC` |
| `print` | 0x006D5640 | `33 C0 C3` (STUBBED - returns 0) |
| `rawequal` | 0x00860900 | `56 8B 74 24 08 8B 46 0C` |
| `rawget` | 0x008609B0 | `56 8B 74 24 08 8B 46 0C` |
| `rawset` | 0x00860A70 | `56 8B 74 24 08 8B 46 0C` |
| `select` | 0x00861520 | `53 56 57 8B 7C 24 10 8B` |
| `setfenv` | 0x008607E0 | `55 8B EC 83 E4 F8 51 53` |
| `setmetatable` | 0x008605E0 | `53 56 8B 74 24 0C 8B 46` |
| `tonumber` | 0x008602A0 | `55 8B EC 83 E4 F8 83 EC` |
| `tostring` | 0x008617F0 | `57 8B 7C 24 08 8B 47 0C` |
| `type` | 0x00860C70 | `56 8B 74 24 08 8B 46 0C` |
| `unpack` | 0x00861410 | `83 EC 08 53 8B 5C 24 10` |
| `xpcall` | 0x008616C0 | `55 8B EC 83 E4 F8 83 EC` |

**NOTE**: `print` at 0x006D5640 is a **stub** (`xor eax,eax; ret`) — the game replaces print with its own logging system. `module`, `newproxy`, `ipairs`, `pairs`, `require` are NOT in this table (registered separately or removed).

---

## String Library (luaopen_string) — 15 Functions

Table VA: **0x00B923A8**

| Lua Name | C Function VA |
|----------|---------------|
| `string.byte` | 0x008636A0 |
| `string.char` | 0x00863860 |
| `string.dump` | 0x00863940 |
| `string.find` | 0x008646F0 |
| `string.format` | 0x00865150 |
| `string.gfind` | 0x008649E0 |
| `string.gmatch` | 0x008648B0 |
| `string.gsub` | 0x00864C60 |
| `string.len` | 0x00863220 |
| `string.lower` | 0x00863450 |
| `string.match` | 0x00864710 |
| `string.rep` | 0x008635F0 |
| `string.reverse` | 0x00863390 |
| `string.sub` | 0x00863270 |
| `string.upper` | 0x00863520 |

---

## Table Library (luaopen_table) — 9 Functions

Table VA: **0x00B92428**

| Lua Name | C Function VA |
|----------|---------------|
| `table.concat` | 0x00862790 |
| `table.foreach` | 0x00862260 |
| `table.foreachi` | 0x00862130 |
| `table.getn` | 0x00862480 |
| `table.insert` | 0x00862550 |
| `table.maxn` | 0x00862380 |
| `table.remove` | 0x00862660 |
| `table.setn` | 0x008624E0 |
| `table.sort` | 0x00863110 |

---

## Math Library — 9 Functions (partial, from registration tables)

| Lua Name | C Function VA |
|----------|---------------|
| `math.abs` | 0x005C5970 |
| `math.ceil` | 0x005C59F0 |
| `math.deg` | 0x005C5B70 |
| `math.exp` | 0x005C5BB0 |
| `math.floor` | 0x005C59B0 |
| `math.max` | 0x005C5A90 |
| `math.min` | 0x005C5AE0 |
| `math.pow` | 0x005C5BF0 |
| `math.rad` | 0x005C5B30 |

---

## Coroutine Library (luaopen_coroutine) — 6 Functions

Table VA: **0x00B92580**

| Lua Name | C Function VA |
|----------|---------------|
| `coroutine.create` | 0x00861D00 |
| `coroutine.resume` | 0x00861BA0 |
| `coroutine.running` | 0x00861F30 |
| `coroutine.status` | 0x00861E30 |
| `coroutine.wrap` | 0x00861DC0 |
| `coroutine.yield` | 0x00861DF0 |

---

## High-Frequency C API Functions (Identified by Call Analysis)

These are the most-called functions from all registered Lua library implementations. They represent the core Lua C API:

| VA | Call Count | Likely Function | Evidence |
|----|-----------|----------------|----------|
| 0x0085F3A0 | 59 | `luaL_checkinteger` / `luaL_checknumber` | Called from nearly all math/game funcs |
| 0x0085D860 | 34 | `lua_gettop` or `lua_tonumber` | Called from base+string libs |
| 0x0085DFC0 | 32 | `lua_pushstring` / `lua_pushlstring` | Called after string operations |
| 0x007614C0 | 32 | Game engine: object field accessor | Called from Flash/MovieClip bindings |
| 0x0085F130 | 32 | `lua_tolstring` / `luaL_checklstring` | String extraction |
| 0x00760850 | 44 | Game engine: type check | Called from geometry functions |
| 0x0085F420 | high | `lua_pushvalue` / `lua_settop` | Stack manipulation |
| 0x00865B30 | — | `luaO_str2d` (number format) | Pushes "%.14g" |
| 0x008688D0 | — | `luaD_call` | Pushes "C stack overflow" |

---

## Metamethod Name Table

Located at VA **~0x00BE9328** (contiguous in .rdata):

| Offset | String | TM enum |
|--------|--------|---------|
| 0x00BE9328 | `__index` | TM_INDEX |
| 0x00BE9D48 | `__newindex` | TM_NEWINDEX |
| 0x00BE9D40 | `__gc` | TM_GC |
| 0x00BE8C68 | `__mode` | TM_MODE |
| 0x00BE9D38 | `__eq` | TM_EQ |
| 0x00BE9D30 | `__add` | TM_ADD |
| 0x00BE9D28 | `__sub` | TM_SUB |
| 0x00BE9D20 | `__mul` | TM_MUL |
| 0x00BE9D18 | `__div` | TM_DIV |
| 0x00BE9D10 | `__mod` | TM_MOD |
| 0x00BE9D08 | `__pow` | TM_POW |
| 0x00BE9D00 | `__unm` | TM_UNM |
| 0x00BE9CF8 | `__len` | TM_LEN |
| 0x00BE9CF0 | `__lt` | TM_LT |
| 0x00BE9CE8 | `__le` | TM_LE |
| 0x00BE9CDC | `__concat` | TM_CONCAT |
| 0x00BE9CD4 | `__call` | TM_CALL |
| 0x00BE8EEC | `__tostring` | (non-standard, used by tostring) |
| 0x00BE8DD4 | `__metatable` | (protection tag) |

---

## Game Engine Registration Tables (58 total)

The game registers **1,224+ custom Lua functions** across the following subsystems:

### Major Game Subsystems

| Table VA | Subsystem | Functions |
|----------|-----------|-----------|
| 0x00B98770 | ECS/Filter system (`Create`, `SetFilter`, `Eval`, `_GC`) | 16 |
| 0x00B987F8 | Event system (`Create`, `Post`, `Delete`) | 4 |
| 0x00B98828 | Debug/Logging (`Printf`, `LogError`, `Assert`, `GetCallstack`) | 6 |
| 0x00B98860 | Weapon system (`SetClipAmmo`, `Reload`, `IsPrimary`) | 9 |
| 0x00B988B0 | Dialog/VO system (`Cue`, `Cancel`, `SetCinematicMode`) | 11 |
| 0x00B98918 | Vehicle system (`GetRiders`, `Enter`, `Exit`, `HijackStart`) | 40 |
| 0x00B98A78 | Game core (`RequestGameState`, `Clock`, `Date`, `GetPlatform`) | 64 |
| 0x00B98C98 | Audio system (`CueSound`, `LoadBank`, `TransitionMusic`) | 88 |
| 0x00B98F64 | Infraction system (`Init`, `Completed`, `Failed`) | 5 |
| 0x00B98FC0 | Player system (`GetCharacter`, `TeleportCamera`, `SetPDAMapMode`) | 107 |
| 0x00B99FF8 | Widget/UI system (`CreateWidget`, `SetWidgetLocation`, `SetTextText`) | 114 |
| 0x00B9A398 | Marker/HUD system (`_MarkerAdd`, `LoadTexture`, `GetLanguageNum`) | 38 |
| 0x00B9A938 | AI system (`Goal`, `Squad`, `SetSpawnList`, `Deploy`) | 66 |

### Flash/Scaleform Integration

| Table VA | Flash Class | Functions |
|----------|-------------|-----------|
| 0x00B93400 | Date object | 39 (getDate, setFullYear, etc.) |
| 0x00B93590 | MovieClipLoader | 3 |
| 0x00B935B0 | Selection/TextField | 9 |
| 0x00B93688 | flash.geom.Rectangle | 15 |
| 0x00B93708 | Sound | 12 |
| 0x00B93770 | TextField | 7 |
| 0x00B937B0 | TextField (extended) | 14 |
| 0x00B93830 | flash.geom.Matrix | 13 |
| 0x00B938A0 | flash.geom.ColorTransform | 4 |
| 0x00B938D8 | MovieClip (drawing API) | 39 |
| 0x00B93A48 | Array | 13 |
| 0x00B93B20 | Object.prototype | 8 |
| 0x00B93BC8 | Number constants | 5 |
| 0x00B93328 | XML/HTTP (load, send, decode) | 8 |
| 0x00B93308 | flash.geom.Point (interpolate, distance, polar) | 3 |
| 0x00B932C8 | flash.geom.Point (add, subtract, normalize) | 7 |

---

## Stub Function: 0x006D5640

Many game functions map to a single **stub** at VA **0x006D5640**:
```
33 C0    xor eax, eax
C3       ret
```
This is `return 0` — these are either disabled features, debug-only functions, or platform-specific (Xbox 360 only) that were stripped for PC.

Stubbed functions include: `print`, `Printf`, `LogError`, `LogWarning`, `LogInfo`, `Assert`, `GetCallstack`, `Search`, `DumpAssets`, `DumpTextures`, `LoadScript`, `LoadData`, `SetTrafficSpawning`, `SetSidewalkSpawning`, `SetRoadSpawning`, `SetLaneActive`, `SetExclusionZone`, `SetSky`, `Water`, `Talk`, `Feed`, and ~60 others.

---

## Notes on lua_getglobal / lua_setglobal / luaL_dostring

- **`lua_getglobal(L,s)`** = `lua_getfield(L, LUA_GLOBALSINDEX, s)` — this is a MACRO, not a function
- **`lua_setglobal(L,s)`** = `lua_setfield(L, LUA_GLOBALSINDEX, s)` — also a MACRO
- **`luaL_dostring`** = `luaL_loadstring(L,s) || lua_pcall(L,0,LUA_MULTRET,0)` — MACRO  
  (`luaL_loadstring` calls `luaL_loadbuffer` at **0x00860240**; `lua_pcall` at **0x0085DF50**)

The 77 LUA_GLOBALSINDEX references in .text confirm heavy usage of `lua_getfield`/`lua_setfield` with the globals table.

---

## Key Findings for DLC Plugin Development

1. **`luaB_loadstring`** (cdecl wrapper) at **0x00860FC0** — can execute arbitrary Lua code strings
2. **`luaL_loadbuffer`** at **0x00860240** — the C API entry point for compiling Lua chunks (LTCG convention, see VA table above)
3. **`lua_pcall`** at **0x0085DF50** — the C API protected-call function (LTCG convention, see VA table above)
4. **`luaB_pcall`** (cdecl wrapper) at **0x008615F0** — the `pcall()` Lua-side binding
5. **`lua_resume`** at **0x00861AD0** — coroutine support is live
6. **`lua_yield`** at **0x00861DF0** — coroutine yielding works
7. **`luaL_argerror`** at **0x0085EF70** — argument validation infrastructure
8. **`luaD_call`** at **0x008688D0** — the core call dispatcher
9. **`luaG_errormsg`** at **0x00867D50** — error message formatting
10. **1,224 game bindings** — massive surface area for scripting
11. **Flash/Scaleform** integration — UI is driven through Lua→Flash bridge
12. **ECS/Filter system** — entity queries via `Create`, `SetFilter`, `Eval`
13. **All metamethods present** — full OOP support via metatables

---

## Scripts Used

- `tools/lua_capi_audit.py` — Initial string search + registration table scan
- `tools/lua_capi_audit_v2.py` — Comprehensive sweep with full .rdata table detection
