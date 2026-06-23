# Lua scripting

Scope: the embedded Lua 5.1.2 scripting VM (C-API + VM internals) and the engine glue ("Sys"/Pangea console + module loader) that hosts game script.

Provenance: All evidence is symbol/string data recovered from the Xbox 360 devkit "Profile" build `Mercs2_Xenon_P.exe` (Mercenaries 2: World in Flames, Jul 11 2008 preview, PowerPC). Decompressed PE at `output/jul08_prototype/mercs2_xenon_p.pe_full.bin`. The dev build tree was `d:\projects\ReleaseLine\Mercs2\`. This is NOT a real `.pdb`; offsets are PE offsets as listed in the inventory.

## Overview

The game statically links **Lua 5.1.2** ("`$Lua: Lua 5.1.2 Copyright (C) 1994-2007 Lua.org, PUC-Rio $`", "`Lua 5.1`"). The recovered inventory for this system is composed almost entirely of compiled-in Lua C source asserts, captured as `FILE [LINE]` strings (e.g. `...\src\lstate.c [49]`), one per `lua_assert`/error site. These map one-to-one to the standard Lua 5.1 reference-implementation source modules — VM state (`lstate.c`), the protected-call / stack engine (`ldo.c`), garbage collector (`lgc.c`), tables (`ltable.c`), string interning (`lstring.c`), function/closure/upvalue objects (`lfunc.c`), buffered I/O (`lzio.c`), allocator wrapper (`lmem.c`), lexer (`llex.c`), parser/code-gen (`lparser.c`), and precompiled-chunk loader (`lundump.c`).

Above the raw VM sits an engine embedding layer — Pandemic's "Pangea" host (per the `Pangea Lua Console` banner): a `Sys.*` C-function table, a Lua-side **module system** (`import`/`dynamic_import`/`inherit`, `_MODULES`, `_SYS`), a developer **console** with an in-VM **debugger** (`console.lua`, breakpoints, `GetCallstack`), and save/version hooks (`SetLuaSaveVersion`, `lastsavegame.lua`). The decompiled game-script corpora live at `docs/mercs2-luacd/` and `docs/mercs2-dlc-luacd/`; this doc covers the *engine/VM* side that runs them.

Note: the inventory's "scripting"-looking opcode strings near offset `0x00cd...` in the strings file (e.g. `Error: Unsupported opcode %02X`, `registerClass`, `Attempt to write read-only property %s.%s`) belong to the **ActionScript/GFx (Scaleform Flash)** VM, not Lua, and are intentionally excluded here.

## Source files

From `mercs2_xenon_p.source_paths.txt`, the files attributable to this system (verbatim):

```
d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\ldo.c
d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\lfunc.c
d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\lgc.c
d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\llex.c
d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\lmem.c
d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\lparser.c
d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\lstate.c
d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\lstring.c
d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\ltable.c
d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\lundump.c
d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\lzio.c
```

(`Lua-5.1.2\src\` confirms the exact stock version; these are the standard Lua reference-implementation core modules.)

## Key classes

None. No RTTI class names in `mercs2_xenon_p.rtti_classes.txt` demangle to a Lua/script type (grep for `lua|script|console` returns no hits). This is consistent with Lua 5.1 being a **C library** — its objects (`lua_State`, `Table`, `Proto`, `Closure`, `TString`, `UpVal`) are C structs with no C++ RTTI. The `Sys.*` host functions are likewise registered as C closures, not C++ classes with vtables.

## Symbols by area

All inventory entries are `.rdata` strings. The two non-path symbols and a representative sample of the per-module asserts (offsets copy-exact from `inventory/lua-scripting.txt`):

### VM state & globals — `lstate.c`
| Offset | Symbol |
|---|---|
| 0x00b32cc | LUA_SIZES |
| 0x00b33d4 | d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\lstate.c [49] |
| 0x00b3410 | d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\lstate.c [44] |
| 0x00b344c | d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\lstate.c [63] |
| 0x00b3488 | d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\lstate.c [62] |
| 0x00b34d8 | d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\lstate.c |
| 0x00b3510 | d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\lstate.c [112] |
| 0x00b354c | d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\lstate.c [111] |
| 0x00b3588 | d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\lstate.c [120] |
| 0x00b35c4 | d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\lstate.c [139] |

`LUA_SIZES` (0x00b32cc) is the stock Lua build-config size string. `lstate.c` holds `lua_State`/`global_State` lifetime (`lua_newstate`/`close_state`); its asserts gate VM creation/teardown integrity.

### Protected calls, stack & coroutines — `ldo.c`
| Offset | Symbol |
|---|---|
| 0x00b40d4 | d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\ldo.c [145] |
| 0x00b4110 | d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\ldo.c [154] |
| 0x00b41cc | d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\ldo.c [512] |

`ldo.c` is the call/return + stack-growth + error-recovery engine (`luaD_call`, `luaD_growstack`, `luaD_pcall`, `resume`). Backed by the runtime strings `stack overflow`, `C stack overflow`, `attempt to yield across metamethod/C-call boundary`, `error in error handling`.

### Garbage collector — `lgc.c`
| Offset | Symbol |
|---|---|
| 0x00b4208 | d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\lgc.c [395] |
| 0x00b4244 | d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\lgc.c [391] |
| 0x00b4280 | d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\lgc.c [440] |

Incremental mark-and-sweep GC. The host exposes a GC tunable in the engine INI (`LuaGarbageCollectionThreshold 256`, see Notable strings) and Lua's own `collectgarbage`/`gcinfo`/`setpause`/`setstepmul`/`step`/`collect`/`restart` controls are present.

### Tables — `ltable.c`
| Offset | Symbol |
|---|---|
| 0x00b44b4 | d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\ltable.c [271] |
| 0x00b44f0 | d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\ltable.c [290] |
| 0x00b453c | d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\ltable.c [365] |
| 0x00b4578 | d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\ltable.c [384] |
| 0x00b45b4 | d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\ltable.c [383] |
| 0x00b45f0 | d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\ltable.c [382] |
| 0x00b4654 | d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\ltable.c [329] |
| 0x00b4690 | d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\ltable.c [320] |

Hybrid array/hash tables. Asserts correspond to the runtime errors `table overflow`, `table index is NaN`, `table index is nil`, `invalid key to 'next'`.

### String interning — `lstring.c`
| Offset | Symbol |
|---|---|
| 0x00b46cc | d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\lstring.c [44] |
| 0x00b4708 | d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\lstring.c [28] |
| 0x00b4744 | d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\lstring.c [56] |
| 0x00b4780 | d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\lstring.c [101] |

Interned-string table (`luaS_newlstr`, resize). Related string: `string length overflow`.

### Functions, closures & upvalues — `lfunc.c`
| Offset | Symbol |
|---|---|
| 0x00b47c0 | ...\lfunc.c [24] |
| 0x00b47fc | ...\lfunc.c [34] |
| 0x00b4838 | ...\lfunc.c [45] |
| 0x00b4874 | ...\lfunc.c [67] |
| 0x00b48b0 | ...\lfunc.c [92] |
| 0x00b48ec | ...\lfunc.c [116] |
| 0x00b4928 | ...\lfunc.c [148] |
| 0x00b4964 | ...\lfunc.c [147] |
| 0x00b49a0 | ...\lfunc.c [146] |
| 0x00b49dc | ...\lfunc.c [145] |
| 0x00b4a18 | ...\lfunc.c [144] |
| 0x00b4a54 | ...\lfunc.c [143] |
| 0x00b4a90 | ...\lfunc.c [142] |
| 0x00b4acc | ...\lfunc.c [155] |

The densest assert cluster (14 sites) — `Proto`/`Closure`/`UpVal` allocation and the upvalue open/close machinery (`luaF_newproto`, `luaF_close`). Related runtime types: `upval`, `proto`, `upvalue`.

### Buffered reader & allocator — `lzio.c`, `lmem.c`
| Offset | Symbol |
|---|---|
| 0x00b4b08 | d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\lzio.c [78] |
| 0x00b4b6c | d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\lmem.c [60] |

`lzio.c` = the `ZIO` streaming reader feeding lexer/loader; `lmem.c` = the `luaM_realloc` allocator wrapper. Related strings: `not enough memory`, `memory allocation error: block too big`.

### Lexer & parser/codegen — `llex.c`, `lparser.c`
| Offset | Symbol |
|---|---|
| 0x00b4ca8 | d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\llex.c [58] |
| 0x00b4d38 | d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\llex.c [147] |
| 0x00b5120 | d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\lparser.c [372] |
| 0x00b5160 | d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\lparser.c [370] |
| 0x00b51a0 | d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\lparser.c [368] |
| 0x00b51e0 | d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\lparser.c [366] |
| 0x00b5220 | d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\lparser.c [364] |
| 0x00b5260 | d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\lparser.c [362] |

Source-text compilation path. The presence of `llex.c`/`lparser.c` proves the build can compile **textual** Lua at runtime (not only precompiled chunks) — consistent with the live console. Related strings: `lexical element too long`, `chunk has too many lines`, `malformed number`, `constant table overflow`, `too many local variables`, `syntax error`. The "compiles textual Lua at runtime" claim is an inference from those modules being present alongside the live console.

### Precompiled-chunk loader — `lundump.c`
| Offset | Symbol |
|---|---|
| 0x00b5434 | d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\lundump.c [92] |
| 0x00b5470 | d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\lundump.c [130] |
| 0x00b54c0 | d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\lundump.c [103] |
| 0x00b5500 | d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\lundump.c [154] |
| 0x00b5540 | d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\lundump.c [144] |
| 0x00b5580 | d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\lundump.c [140] |

`luaU_undump` — loads precompiled bytecode chunks. Backed by `%s: %s in precompiled chunk`, `bad header`, `bad code`, `bad constant`, `bad integer`, `unexpected end`. This is the load path the shipped game uses for WAD-packed bytecode — the "shipped path" part is an inference, but it matches the project's known bytecode pipeline.

## Notable strings

**Version / banner:**
- `$Lua: Lua 5.1.2 Copyright (C) 1994-2007 Lua.org, PUC-Rio $`
- `$Authors: R. Ierusalimschy, L. H. de Figueiredo & W. Celes $`
- `$URL: www.lua.org $`
- `Lua 5.1`, `_VERSION`, `LUA_SIZES`

**Tunable:** `LuaGarbageCollectionThreshold 256` — appears in the engine INI block for `[ps3]` and `[x360]` platform sections, alongside `MainMemoryBlocks`, `FastMemoryBlocks`, `UseSmallBlocks`. Governs the embedded GC trigger threshold.

**Standard-library / base function names** present as C-registration strings: `pcall`, `xpcall`, `loadstring`, `setmetatable`, `getmetatable`, `setfenv`, `getfenv`, `rawget`, `rawset`, `rawequal`, `collectgarbage`, `gcinfo`, `tonumber`, `unpack`, `newproxy`, `pairs`, `ipairs`, `print`, `error`; coroutine ops `create`/`resume`/`yield`/`status`/`running`; string lib `gmatch`/`gfind`/`upper`/`lower`/`match`/`format`/`remove`/`insert`/`foreach`/`foreachi`; metamethod keys `__index`, `__newindex`, `__call`, `__concat`, `__len`, `__add`..`__pow`, `__mode`, `__metatable`, `__tostring`.

**VM runtime error strings:**
- `attempt to %s %s '%s' (a %s value)`, `attempt to %s a %s value`
- `attempt to compare %s with %s`, `attempt to compare two %s values`
- `stack overflow (%s)`, `stack overflow`, `C stack overflow`
- `attempt to yield across metamethod/C-call boundary`, `error in error handling`
- `cannot resume dead coroutine`, `too many results to resume`, `too many arguments to resume`, `Lua function expected`
- `'for' initial value must be a number` / `'for' limit must be a number` / `'for' step must be a number`
- `loop in gettable`, `loop in settable`, `table index is nil`, `table index is NaN`, `table overflow`, `invalid key to 'next'`
- `bad argument #%d to '%s' (%s)`, `%s expected, got %s`, `cannot change a protected metatable`
- precompiled-chunk: `%s: %s in precompiled chunk`, `bad header`, `bad code`, `bad constant`

**Opcode mnemonic table** — the full Lua 5.1 opcode-name list is embedded (for error/debug formatting): `LOADK`, `LOADBOOL`, `LOADNIL`, `GETUPVAL`, `GETGLOBAL`, `GETTABLE`, `SETGLOBAL`, `SETUPVAL`, `SETTABLE`, `NEWTABLE`, `CONCAT`, `TESTSET`, `TAILCALL`, `RETURN`, `FORLOOP`, `FORPREP`, `TFORLOOP`, `SETLIST`, `CLOSE`, `CLOSURE`, `VARARG`.

**Engine embedding / host ("Sys") API:** a Lua-callable C-function table exposing engine services, including:
- `CurrentLuaState`, `SetLuaSaveVersion`, `WriteToConsole`, `ToStringL`, `GuidToString`, `StringToGuid`, `MemUsage`
- `SetMasterScriptName` / `GetMasterScriptName`, `SetLevelName` / `GetLevelName`, `RequestGameState`, `IsLoadingOrStreaming`
- bootstrap glue string: `_tostring = tostring; tostring = Sys.ToStringL; help = Sys.Help; StringToGuid = Sys.StringToGuid;`

**Module system** — a custom `require`-style loader written in Lua and driven by `_SYS` C hooks:
- `_G._MODULES = {};`, `_MODULESMETATABLE = { __index = _SYS._MODULEINDEX };`
- `function _G.import(module) ... return _SYS._IMPORT(getfenv(2), module); end;`
- `function _G.dynamic_import(module, callbackfunc, callbackdata) ... _SYS._DYNAMIC_IMPORT(_SYS._GETFENV(2) or _G, ...)`
- hook names: `_IMPORT`, `_MODULEINDEX`, `_GETFENV`, `_DYNAMIC_IMPORT`, `_DYNAMIC_REMOVE`, `_INHERIT`, `_THIS`, `_MODULESMETATABLE`

**Console + in-VM debugger:** `console.lua`, banner `Welcome to Pangea Lua Console` (assembled from color-coded fragments `Welcome `/`to `/`Pangea `/`Lua `/`Console`), `debugger`, `GetCallstack`, `_MODULES.%s`, `_BREAKPOINTENV`, `OnBreak`/`onbreak`, `Breaking - %s : %d`, `Breaking - %s : %d - %s`, `Breakpoint %d %s`, `Syntax Error: %s`, `Continuing`, `Invalid current session`. Debug-binding glue: `ASSERT = Debug.Assert; print = Debug.Printf` with `LogInfo`/`LogWarning`/`LogError`/`Printf`/`GetCallstack` on a `Debug` table.

**Save/persistence hooks:** `SetLuaSaveVersion`, `lastsavegame.lua`, `%s.lua`, `SaveSingleton`/`LoadSingleton`, `SaveData`/`InitialSaveData`/`LoadGame`/`autosave`.

## PC decompilation cross-reference

This section maps this system's Xbox symbols/strings to functions in the PC retail decomp (`output/_ghidra/all_functions_decomp.txt`). The automated resolver wrote an **empty** `output/jul08_prototype/pairing/resolved_lua-scripting.txt` — no vtable matches and no string matches — which is expected: Lua 5.1 is a C library with **no RTTI classes** to bridge (so there are zero high-confidence vtable resolutions), and the PC release build stripped almost all of the per-module `lstate.c [49]`-style assert strings the Xbox Profile build kept (so the per-module loader/GC/parser functions have no surviving string anchor in the PC decomp).

What *does* survive in the PC retail decomp are a few of the **Lua-source bootstrap chunks** that the engine compiles-and-runs at startup — the module-system glue documented above. These are inlined as readable string constants and let us anchor the host's "run an embedded Lua chunk" path by hand (string bridge, medium confidence — each is a single distinctive multi-word source string):

| Symbol / class | PC function | Bridge | Role |
|---|---|---|---|
| `_G._MODULES = {}; _MODULESMETATABLE = …` (module-system bootstrap) | `FUN_005a2c40` | string | registers C closures, then compiles/runs the module-system bootstrap chunk |
| `if _MODULES and _MODULES.mrxgui_t…` (GUI module guard chunk) | `FUN_0060994e` | string | compiles/runs a guarded Lua chunk that checks a `_MODULES` entry |
| (shared) load-buffer helper | `FUN_00860240` | call-graph | tiny `luaL_loadbuffer`-style helper: takes string ptr + computed length, sets up the call frame |
| (shared) protected-call wrapper | `FUN_0085df50` | call-graph | `pcall`-style frame wrapper used by every bootstrap chunk-runner |

Confidence: the two named string anchors are **medium** (distinctive multi-word source strings, verified to be referenced by the body — not generic); `FUN_00860240`/`FUN_0085df50` are **inferred** from the shared call graph (both bootstrap runners call them), not from a string. No constructor/vtable claims are made because none exist for this system.

Annotated excerpt — `FUN_005a2c40` (module-system bootstrap, decomp lines ~210620–210700):

```c
  FUN_0085da90(FUN_00862100);                 // push a C function (closure) onto the Lua stack
  FUN_008688d0(iVar7,*(int *)(iVar7 + 8) + -8,0);
  FUN_0085da90(&LAB_00863200);                // push another C function
  ...
  pcVar2 = *(char **)((int)&PTR_s__G__MODULES________MODULESMETATA_00dfd480 + iVar7),
  ...
  iVar7 = FUN_00860240(pcVar2,(int)pcVar5 - (int)(pcVar2 + 1));  // load that source chunk (ptr,len)
  if (iVar7 == 0) { iVar7 = FUN_0085df50(0); ... }              // and protected-call it
```

This shows the host registering several C closures (the `_SYS._IMPORT` / `_MODULEINDEX` / `_GETFENV` hooks named in **Module system**) and then `FUN_00860240`→`FUN_0085df50` to compile and run the literal `_G._MODULES = {}; _MODULESMETATABLE = { __index = _SYS._MODULEINDEX };` bootstrap text. It is the PC-retail counterpart of the module-loader glue captured as strings on the Xbox side.

Annotated excerpt — `FUN_0060994e` (GUI module guard, decomp lines ~264818–264844):

```c
  pcVar2 = s_if__MODULES_and__MODULES_mrxgui_t_00bbba10;   // "if _MODULES and _MODULES.mrxgui_t…"
  do { pcVar3 = pcVar2; pcVar2 = pcVar3 + 1; } while (*pcVar3 != '\0');  // strlen
  iVar4 = FUN_00860240(s_if__MODULES_and__MODULES_mrxgui_t_00bbba10, pcVar3 + -0xbbba10);  // load(ptr,len)
  if (iVar4 == 0) { iVar4 = FUN_0085df50(0); ... }          // protected-call
```

Same load→pcall shape, here running a small guard chunk that tests a `_MODULES` entry before use — confirming `FUN_00860240`/`FUN_0085df50` are the generic compile/run helpers the embedding uses for every inline chunk.

## Cross-references

- `docs/mercs2-pdb-analysis/pangea-engine-core.md` — the host engine ("Pangea") that owns `CurrentLuaState` and the `Sys`/`_SYS` bridge.
- `docs/mercs2-pdb-analysis/game-systems.md` — high-level game systems driven from Lua (missions, contracts, support/economy, tutorials).
- `docs/mercs2-pdb-analysis/gui-hud.md` — note the **separate** ActionScript/GFx (Scaleform) VM whose opcode/property strings sit near the Lua strings but are a different scripting engine.
- Decompiled script corpora that run on this VM:
  - `docs/mercs2-luacd/` — full base-game Lua (README + 8 category docs).
  - `docs/mercs2-dlc-luacd/` — DLC Lua.
- Project memory: the bytecode pipeline (`lundump.c` loader) is documented under "Lua bytecode Xbox→PC = disassemble/reassemble" — disassemble/flip-endian/reassemble rather than byte-swap precompiled chunks.

## Evidence & confidence

- **Inventory size:** 58 entries (the file ends without a trailing newline, so `wc -l` reports 57) — 1 named symbol (`LUA_SIZES`) + 1 bare `lstate.c` path with no `[LINE]` (`0x00b34d8`) + 56 `FILE [LINE]` assert strings across 11 Lua modules. All are in `.rdata`.
- **Verification:** the 11 Lua source paths are confirmed verbatim in `mercs2_xenon_p.source_paths.txt`; `LUA_SIZES`, the version banner, the GC tunable, the full standard-library/metamethod/opcode/error-string sets, and the `Sys`/`_SYS`/module/console/debugger glue are all confirmed by grep in `mercs2_xenon_p.pe_full_strings.txt`.
- **Directly attested** (symbol/string exists in evidence): the exact Lua version 5.1.2; the 11 compiled-in core modules and their assert line numbers at the cited offsets; the `LuaGarbageCollectionThreshold 256` tunable; all quoted error/library/opcode/metamethod strings; the `Sys.*` host functions, `_SYS`/`_MODULES` module loader, `console.lua`, `debugger`, breakpoint strings, and save hooks listed above.
- **Inferred** (not directly stated by a symbol): the per-module *responsibilities* (e.g. `ldo.c` = call/stack engine) — these follow from the modules being **stock Lua 5.1** whose roles are documented upstream, matched to adjacent recovered strings; the claim that the host engine is "Pangea" (consistent with `Pangea Lua Console` and project-wide `Pg*` usage); and the routing of WAD-packed bytecode through `lundump.c`.
- **Excluded as not-Lua:** the GFx/ActionScript VM strings (`Error: Unsupported opcode %02X`, `registerClass`, `Attempt to write read-only property %s.%s`, `_currentframe`, etc.) — a separate Scaleform scripting engine.
- **No RTTI classes** belong to this system (Lua is a C library); the `## Key classes` section is intentionally empty.
