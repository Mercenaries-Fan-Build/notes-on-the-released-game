# Scripting host + script binding surface — Xbox↔PC code map

**Scope:** scoreboard **rows 16 (Scripting host)** + **17 (Script binding surface)** — the embedded
**Lua 5.1.2** VM host (module system `import`/`inherit`/`dynamic_import`, the `Sys.*`/`_SYS`
bootstrap, console + save hooks) **and** the ~1216-cfunc `luaL_Reg` binding surface across ~53
engine namespaces. This is the two-in-one map for the scripting spine the sibling maps leaned on
(they walked the binding tables ad-hoc — `Ai.TweakAttachedSpawners`, `Pg.Spawn`,
`Object.*Hibernation`, `Sound.*`, `Weapon.*`, `Airstrike.*`, faction cfuncs — but never
consolidated the *host* or the *whole surface*). It does that here.

This marries the **Xbox 360 devkit (Jul-08 Profile build)** symbol/string ground truth to the **PC
retail decompilation** (unpacked SecuROM image `mercs2_unpacked.exe`, base `0x00400000`).

**Sources.** Xbox oracle: [`docs/mercs2-pdb-analysis/lua-scripting.md`](../mercs2-pdb-analysis/lua-scripting.md)
(the host/module-system/console inventory + the honest Xbox-vs-PC asymmetry note). PC: the 27k-fn
Ghidra decomp of the unpacked exe; the recovered binding audits
[`docs/lua_capi_comprehensive_audit.md`](../lua_capi_comprehensive_audit.md) (58 `luaL_Reg`
tables / 1285 named fns, the Lua C-API VAs, the shared `0x006D5640` stub) and
[`docs/lua_engine_bindings_audit.md`](../lua_engine_bindings_audit.md) (namespace inventory,
`_SYS` bootstrap offsets); the live **Surface-B** trace
[`mods/lua_trace_asi/reference/binding_map.json`](../../mods/lua_trace_asi/reference/binding_map.json)
(60 tables / 1357 entries dumped from `.rdata`; 53 game tables / ~1216 fns hooked live). Companion
memory: [[decompiled-lua-corpus]], [[mercs2-script-lua-host]], [[lua-trace-asi-surface-b-oracle]],
[[name-registry-spawn-by-hash]]. Sibling maps that recovered individual cfunc VAs are cited inline.

**Method / honesty model.** Same as the streaming/population maps. Confidence: **H** structural
fingerprint that can't coincide (matching source-string / call-shape / table-VA + role) · **M** role
+ position match, one strong signal · **L** positional/among-siblings only → confirm-live. Every VA
is cited; where a body is Ghidra-`READ` it is marked, where it is inferred it says so, and
binding-table-only cfuncs (name→cfunc slot present but no static caller ⇒ Ghidra never decompiled
the body) are called out as such.

**SecuROM note** ([[securom-decompiled-not-a-blocker]]). The VM host functions
(`FUN_005a2c40`/`FUN_0060994e`/`FUN_00860240`/`FUN_0085df50`) and the base/stdlib openers are in the
**clear** in the unpacked image — none are virtualized. Where a *game* cfunc's terminal commit
routes through a SecuROM VM trampoline (e.g. the `Set*` workers), the cfunc body itself is
decompiled and only the terminal is VM-dispatched → read live in the unpacked image, **not a wall**.

**Honest Xbox-host asymmetry** (lua-scripting.md established this, restated so nobody re-derives it):
the Xbox Profile decomp `xenon_decomp_named.c` carries **zero** Lua source/bootstrap strings and
**zero** Lua C-API symbols as inline literals (`grep` for `lua_State`/`luaL`/`_MODULES`/`_IMPORT`/
`loadstring`/`GETGLOBAL` = 0 hits), and the `{name, C-func}` binding *table* + VM dispatcher are
**not locatable by name/string in that build**. So **every host + binding-surface finding in this
map is PC-anchored.** The Xbox side contributes: the exact VM version (`Lua-5.1.2\src\`), the module
system/console/save string set, and the `float` number type — but not function bodies. The one Xbox
code-grounded fact is the uniform arg-fetch ABI: every `Sys.*` closure pulls args through
`FUN_8241cbf0(args_out, count, &result)` (**261 call sites**), the Xbox twin of the PC
`luaL_check*`/`lua_to*` boundary. This is an asymmetry, not a contradiction.

---

## 0. Result in one line

The **host is fully in the clear on PC**: the module-system bootstrap (`FUN_005a2c40`) registers the
`_SYS` C-closures then compiles-and-runs the `_G._MODULES = {}` bootstrap chunk via the generic
`luaL_loadbuffer FUN_00860240` → `lua_pcall FUN_0085df50` compile/run pair (same pair every inline
chunk uses, e.g. the GUI guard `FUN_0060994e`); the VM is stock **Lua 5.1.2 / float**, and its C-API
entry points are VA-pinned. The **binding surface is fully enumerated**: 60 `.rdata` `luaL_Reg`
tables (53 of them game namespaces, ~1216 cfuncs) with table VAs, counts, and namespace identities
from the live trace — the master row-17 index below. ~120 cfunc **bodies** are VA-recovered across
the sibling maps; the rest are binding-table-only — **recoverable by disassembling the VA from the
`luaL_Reg` row**, not blocked — and ~60+ dev/debug bindings collapse to the shared `return-0` stub
`0x006D5640`.

> **Corrected 2026-07-26.** This sentence used to direct readers to "the
> `DecompileProfileAccessors.java` forcing-script". That is unnecessary, and stating it as the
> route made a whole class of cfuncs look unreachable when they are not: a cfunc referenced only
> from `.rdata` has no static caller, so Ghidra never forms a function there, but the bytes are
> plain `.text`. Since this map is the hub the sibling maps cite for that advice, the correction
> matters most here. Measured 16/16 recovery on the VAs the siblings nominate; see
> `ghidra_knowledge_inventory.md` Part F.4 for the method and the reproduction.

---

## 1. Host (row 16) — VM, module system, bootstrap

### 1.1 The VM: stock Lua 5.1.2, float number type

| Fact | Value | Evidence | Conf |
|---|---|---|---|
| VM version | **Lua 5.1.2** (`$Lua: Lua 5.1.2 …PUC-Rio $`, `Lua-5.1.2\src\`) | Xbox source paths + PC string `0x007925B8` | H |
| Number type | **`float`** (4-byte `lua_Number`) | bytecode headers; TValue = 8 B `{value:4, tt:4}` (hook-verified) | H |
| Build path (PC) | `D:\Projects\Mercs2_PC\mercs2\Lua-5.1.2\src\` | PC `.rdata` | H |
| GC threshold | `LuaGarbageCollectionThreshold 256` | engine INI (`[x360]`/`[ps3]`), embedded config | H |
| Linked core modules | 11 (`ldo/lfunc/lgc/llex/lmem/lparser/lstate/lstring/ltable/lundump/lzio`) | assert strings both builds (Xbox `0x00b32cc`+; PC `0x00BE9330`–`0x00BEA7F4`) | H |
| Bytecode loader | `luaU_undump` (`lundump.c`) — WAD-packed precompiled chunks | Xbox asserts `0x00b5434`–`0x00b5580`; PC `0x00BEA6B8`–`0x00BEA7F4`; **body unlocated by name in both builds** (string/offset only) | M (present) / open (VA) |

**Lua C-API VAs (PC, verified across 10+ call sites; the load-bearing host entry points):**

| C-API function | PC VA | Type / convention | Evidence | Conf |
|---|---|---|---|---|
| `luaL_loadbuffer` | **`0x00860240`** (`FUN_00860240`, **READ**) | Public; LTCG `EAX=name, EDX=L, stack=[buff,sz]`, caller cleans 8 | callers `FUN_0060994e`, `FUN_005a2c40`, `luaB_loadstring 0x861043` | H |
| `lua_pcall` | **`0x0085DF50`** (`FUN_0085df50`) | Public; LTCG `EAX=L, ECX=errfunc, EDI=nresults, stack=[nargs]`, caller cleans 4 | 10+ callers; `f_call 0x0085DF30` is its `luaD_pcall` callback | H |
| `luaD_pcall` | `0x00868AD0` | Internal (NOT the public API — corrects an earlier mis-ID) | — | H |
| `luaD_call` | `0x008688D0` | Internal call dispatcher | string "C stack overflow" | H |
| `luaL_typerror` | `0x0085F050` | Public (NOT `loadbuffer` — corrects an earlier mis-ID) | — | H |
| `luaL_argerror` | `0x0085EF70` | Public | string "bad argument #%d" | H |
| `luaL_checklstring` | `0x0085D860` | Public | — | H |
| `luaG_errormsg` | `0x00867D50` | Internal | "error in error handling" | H |
| `lua_resume` / `lua_yield` | `0x00861AD0` / `0x00861DF0` | Public (coroutines live) | dead-coroutine / yield-boundary strings | H |
| `luaB_loadstring` (cdecl wrapper) | `0x00860FC0` | `loadstring()` binding → calls `0x00860240` | READ | H |
| `luaB_pcall` (cdecl wrapper) | `0x008615F0` | `pcall()` binding → calls `luaD_pcall 0x868AD0` directly | READ | H |

Pseudo-index constants confirm heavy field-based global access: `LUA_REGISTRYINDEX=-10000` (82
refs), `LUA_GLOBALSINDEX=-10002` (77), `LUA_ENVIRONINDEX=-10001` (56) — used as `CMP/MOV imm32`
(register-passed, LTCG), i.e. `lua_getglobal`/`lua_setglobal` are the `lua_getfield`/`lua_setfield`
macros over the globals table, and `luaL_dostring` = `luaL_loadbuffer(0x860240)` ‖
`lua_pcall(0x85DF50)`.

### 1.2 Master host-function table (Xbox↔PC)

Xbox column = the `lua-scripting.md` string/symbol; a bare "string only" means the Xbox *body* is
unlocated by name (the PC-anchored asymmetry above).

| Role | Xbox | PC | Married by | Conf |
|---|---|---|---|---|
| Module-system bootstrap (registers `_SYS` closures, runs `_G._MODULES={}` chunk) | `_G._MODULES = {}; _MODULESMETATABLE…` (string) | **`FUN_005a2c40`** (502 B, **READ**) | distinctive multi-word source string referenced by body + the register→loadbuffer→pcall shape | H |
| Inline-chunk compile helper | (string only) | **`FUN_00860240`** = `luaL_loadbuffer` (**READ**) | call-graph: every bootstrap runner calls it with `(ptr, computed_len)` | H |
| Inline-chunk protected run | (string only) | **`FUN_0085df50`** = `lua_pcall` | call-graph: paired with `FUN_00860240` in every runner | H |
| GUI-module guard chunk runner | `if _MODULES and _MODULES.mrxgui_t…` (string) | **`FUN_0060994e`** (**READ**) | same string-anchored load→pcall shape as bootstrap | H |
| C-closure pusher | (string only) | **`FUN_0085da90`** (`lua_pushcfunction`/`pushcclosure`) | READ: called 3× at head of `FUN_005a2c40` to push `FUN_00862100`/`LAB_00863200`/`FUN_00865570` | H |
| `Sys.CurrentLuaState` (console read/print, NOT the registrar) | `CurrentLuaState @824340a0` (**READ, Xbox**) | in `Sys` table `0x00B98A78` (binding-only) | Xbox body reads 1 arg via `FUN_8241cbf0`, printf-formats it — it is a `Sys.*` *consumer*, not binding machinery | H (role) |
| Uniform arg-fetch ABI (the marshalling boundary) | **`FUN_8241cbf0`** (Xbox, 261 callers) | PC `luaL_check*`/`lua_to*` family (`0x0085F3A0` checknumber ×59, `0x0085F130` checklstring ×32, `0x0085DFC0` pushstring ×32) | every closure pulls params through it; the PC twins are the high-call-count C-API leaves | H / M |
| `luaL_Reg` namespace registrar (`luaL_register`/`luaL_openlib`) | (string only) | **unlocated** — the caller that feeds each of the 60 table VAs | mechanism proven (tables exist in `.rdata`), registrar VA not yet pinned | open |
| Bytecode undump (`luaU_undump`) | asserts `0x00b5434`+ | (present, unlocated by name) | WAD bytecode load path; disasm/flip-endian/reassemble pipeline | open (VA) |

### 1.3 Module system (`import`/`inherit`/`dynamic_import`) — the `_SYS` table

The module loader is **Lua source compiled+run at boot** driven by a 6-entry `_SYS` C-hook table.
The trace pins that table:

- **`_SYS` table `@0x00B9A854`, 6 fns:** `_IMPORT`, `_INHERIT`, `_DYNAMIC_IMPORT`, `_DYNAMIC_REMOVE`,
  `_MODULEINDEX`, `_GETFENV` (+ `_GETFENV(2)` env-capture used by the Lua-side wrappers). Xbox
  bootstrap offsets: `_SYS._IMPORT 0x007B453C`, `_INHERIT 0x007B4ED4`, `_DYNAMIC_IMPORT 0x007B4EC4`,
  `_GETFENV 0x007B4E98`.
- **Lua-side globals** (compiled by the bootstrap chunk): `_G._MODULES = {}`, `_MODULESMETATABLE =
  { __index = _SYS._MODULEINDEX }`, and `import`/`dynamic_import`/`inherit`/`dynamic_remove`
  wrappers that call the `_SYS._*` hooks with `getfenv(2)`/`_SYS._GETFENV(2)`.
- **Semantics** (from the 370-script corpus [[decompiled-lua-corpus]] + the reimpl [[mercs2-script-lua-host]]):
  `import(m)` loads module `m` into the caller's env once (cached in `_MODULES`, lazy via the
  metatable `__index`); `inherit(base)` sets the caller module's `__index → base` (prototype
  chain — every contract does `inherit("MrxTaskContract")`); `dynamic_import(m, cb, data)` is the
  async variant with a completion callback; `dynamic_remove` unloads. Every game script is a module
  that `inherit`s a base class and `import`s helpers (`MrxUtil`, `MrxObjectiveHelper`, …).

### 1.4 Console, debugger, save hooks (host services)

- **`Sys` table `@0x00B98A78` (64 fns)** — the host services: `WriteToConsole` (the real,
  non-stub console write per the diagnostics map), `ToStringL`, `MemUsage`, `StringToGuid`/
  `GuidToString`, `RequestGameState`, `IsLoadingOrStreaming`, `SetMasterScriptName`/`GetMasterScriptName`,
  `SetLevelName`/`GetLevelName`, asset/layer load (`LoadAsset`/`LoadLayer`/…), `SetLuaSaveVersion`.
  Bootstrap glue string: `_tostring = tostring; tostring = Sys.ToStringL; help = Sys.Help;
  StringToGuid = Sys.StringToGuid;`.
- **Console + in-VM debugger:** `console.lua`, banner `Welcome to Pangea Lua Console`, `debugger`,
  `GetCallstack`, `_BREAKPOINTENV`, `OnBreak`/`onbreak`, `Breaking - %s : %d`, `Breakpoint %d %s`.
  Debug glue: `ASSERT = Debug.Assert; print = Debug.Printf` (both stubbed on retail → §3).
- **Save/persistence:** `SetLuaSaveVersion` (`0x005E6120`), `lastsavegame.lua`,
  `SaveSingleton`/`LoadSingleton`, `SaveData`/`InitialSaveData`/`LoadGame`/`autosave` (write-side
  spine = `save_serialize_code_map.md`, driver `FUN_005a4520`).

---

## 2. Binding registration mechanism (row 17 — how the surface is built)

**The format (PC, verified).** Each namespace is a contiguous `.rdata` array of
`luaL_Reg {const char* name; lua_CFunction func;}` — two 32-bit pointers, 8 bytes/entry —
terminated by `{NULL, NULL}`. Name pointers → NUL-terminated ASCII in `.rdata`; func pointers →
`.text`. The engine installs each with stock `luaL_register()`/`luaL_openlib()` into a named global
table. **60 such tables** live in `.rdata` (`0x00B92xxx` stdlib/Scaleform block +
`0x00B98770`–`0x00B9A9A0` engine block + a couple satellites); **~1357 total entries**, of which
**53 tables / ~1216 fns are game engine bindings** (the rest are Lua stdlib + Scaleform AS2
runtime).

**The walk (validated).** For a name string, find the `luaL_Reg` slot pointing at it, read `+4` =
cfunc VA (`file_offset = VA − 0x400000`). The walk reproduces the population map's known
`Ai.TweakAttachedSpawners = 0x5A4C40` and `Pg.Spawn = 0x005D5D20` **exactly** ⇒ the recovered VAs
are trustworthy. The base-library table (`0x00B924B8`, 24 fns) is the reference specimen — every
entry's cfunc prologue is documented (e.g. `assert 0x00861350`, `tonumber 0x008602A0`), and its
`print` slot points at the shared stub `0x006D5640`, proving the mechanism end-to-end.

**Dispatch.** A registered cfunc is a standard `int f(lua_State* L)`; the VM calls it through
`luaD_call 0x008688D0` (or `luaD_precall`), it reads args off the Lua stack via the
`luaL_check*` leaves (§1.1) and pushes results. No per-namespace dispatcher — it is straight
`luaL_Reg` table lookup by the VM's `getglobal(table)` + `getfield(func)`.

**The `0x006D5640` stub family (dev bindings neutered on retail).** VA `0x006D5640` = `33 C0 C3`
(`xor eax,eax; ret` — a `lua_CFunction` returning 0 results), **READ-confirmed**. **~60+** debug/dev
bindings' func-pointers point here on PC, so the *name* registers but the behavior is gone. Known
members: `print`, `Printf`, `LogError`/`LogWarning`/`LogInfo`, `Assert`, `GetCallstack`, `Search`,
`DumpAssets`/`DumpTextures`, `LoadScript`, `LoadData`, `SetTrafficSpawning`/`SetRoadSpawning`/
`SetSidewalkSpawning`/`SetLaneActive`, `SetExclusionZone`, `SetSky`, `Water`, `Talk`, `Feed`,
`Ai.ShowObjectSpawners` (population map §7). This is the retail counterpart of the Xbox Profile
build's fully-wired ~250-item debug menu (diagnostics map): **asymmetric by design** — Xbox keeps
the dev surface, PC collapses it to one stub. Confirming a binding is stubbed = read its
`luaL_Reg +4` and compare to `0x006D5640`.

---

## 3. Master binding-surface index (the row-17 deliverable)

Every game `luaL_Reg` table from the live `.rdata` dump ([[lua-trace-asi-surface-b-oracle]]), with
table VA (unpacked image), fn count, the namespace it installs as, and where cfunc **bodies** have
been VA-recovered (with the sibling map that found them). "Binding-only" = the name→cfunc slot is
known but no static caller ⇒ the body is undecompiled in the Ghidra export — **recover it by
disassembling the VA**, see `ghidra_knowledge_inventory.md` Part F.4. Tables are sorted by VA. The
4 stdlib + ~20 Scaleform AS2 tables in the `0x00B92xxx`–`0x00B93xxx` block are summarized at the
end, not enumerated (they are not the game surface).

> **⚠ Namespace names in this table must come from the registry at `0x00DFD478`, not from a
> nickname.** Corrected 2026-07-26 after the `0x00B99328` row was found mislabelled *"World"* and
> carrying three cfuncs that belong to other namespaces. The registry is 31 rows × 12 bytes
> `{const char* name, luaL_Reg* table, post_register_chunk*}`, terminator `0x00DFD5EC`; walk it and
> the name is read, never inferred. Row 2 is `Pg` → `0x00B99328`. There is no `World` namespace.
>
> The three mis-filed entries, each re-homed by walking the owning table:
>
> | cfunc | was filed under | actually in | table |
> |---|---|---|---|
> | `CreateRegion 0x005BFB00` | "World" `0x00B99328` | **`Junk`** (row 19) | `0x00B99E28` |
> | `GetLineRegion 0x005B0EC0` | "World" `0x00B99328` | **`Graphics`** (row 13) | `0x00B9A4D0` |
> | `ChangeLineRegionSetting 0x005B0D20` | "World" `0x00B99328` | **`Graphics`** (row 13) | `0x00B9A4D0` |
>
> `GetLineRegionPoints 0x005D7160` really is in `Pg` — the four were not a block. A name containing
> "Region" is **not** evidence of which namespace owns it; three different globals carry one.
> This is the same nickname trap recorded in [[lua-trace-asi-surface-b-oracle]]: `binding_map.json`'s
> nickname column is not authoritative and disagrees with the registry in several places.

| Table VA | Namespace | # | Representative fns | Recovered cfunc bodies (source) |
|---|---|---|---|---|
| `0x00B98770` | **Filter/ECS query** | 16 | `Create Copy SetFilter ClearFilter AddObject RemoveObject Eval _GC` | binding-only |
| `0x00B987F8` | **Event** | 4 | `Create CreatePersistent Delete Post` | `Create 0x5F69F0`, `CreatePersistent 0x5F6A00`, `Delete 0x5F6A10`, `Post 0x5F6A90` (bindings audit; via `0x5F6660`) — event_bus map |
| `0x00B98828` | **Debug** | 6 | `Printf LogError LogWarning LogInfo Assert GetCallstack` | **all → stub `0x006D5640`** (`Debug.Printf` ptr `0x00B9882C`); diagnostics map |
| `0x00B98860` | **Weapon** | 9 | `SetClipAmmo GetClipAmmo GetMaxClipAmmo SetReserveAmmo Reload IsPrimary` | descriptors weapons_combat map; cfuncs binding-only |
| `0x00B988B0` | **VO** | 11 | `Cue CueWithoutSubtitles Cancel CancelAll Pause SetCinematicMode` | `Cue 0x5E9DE0`, `CueWithoutSubtitles 0x5E9F40`, `AddSequence 0x5EA3C0`, `RemoveSequence 0x5EA470`, `SetCinematicMode 0x5EA310` — audio map |
| `0x00B98918` | **Vehicle** | 40 | `GetRiders GetDriver GetFromSeat HijackStart Enter Exit` | drive model vehicle map; cfuncs binding-only |
| `0x00B98A78` | **Sys** | 64 | `WriteToConsole ToStringL MemUsage StringToGuid RequestGameState IsLoadingOrStreaming` | `IsDemoMode 0x5E5670`, `GetLanguage 0x5E6420`, `SetLuaSaveVersion 0x5E6120`; `WriteToConsole` real (diagnostics map) |
| `0x00B98C98` | **Sound** | 88 | `CueSound StopSound PauseSound LoadBank TransitionMusic SetDynamicMusic` | `CueSound 0x5E0FF0`, `StopSound 0x5E10F0`, `LoadSoundBank 0x5E2630`, `TransitionMusic 0x5E1600`, `SetDynamicMusic 0x5E16E0` +more — audio map |
| `0x00B98F64` | **Infraction** | 5 | `Init GetInfractions Completed Failed SetDelay` | faction map (mood bridge `FUN_005e0720`) |
| `0x00B98FC0` | **Player** | 107 | `GetCharacter GetControlledObject GetSeat GetCameraXZHeading TeleportCamera SetPDAMapMode` | boundary subset `AddBoundary 0x5DC900`/`RemoveBoundary 0x5DCA30`/… (bindings audit); rest binding-only |
| `0x00B99328` | **`Pg`** (layers/regions) — registry row 2 | 80 | `LoadingStaticLayers IsStaticLayer ResetSingletonDone GetLineRegionPoints` | `IsStaticLayer 0x5D4BF0`, `ResetSingletonDone 0x5D4BE0`, `GetLineRegionPoints 0x5D7160`; `LoadingStaticLayers` → stub `0x6D5640` — world_streaming map |
| `0x00B995B0` | **ObjectState** (script/SM) | 9 | `SendMessage SendDamage SetState GetLinkGuid StartEmitter StopEmitter` | `SetState 0x4D3E10` (indirect jump-table) — state_machine_destruction map |
| `0x00B99608` | **Object** | 87 | `GetParent GetPosition SetPosition SetTransformToObject IsHibernated Kill` | `IsHibernated 0x5CF240`, `GetHibernationDistance 0x5CF420`, `SetHibernationDistance 0x5CF4F0`, `RevertHibernationDistance 0x5CF600` — world_streaming map |
| `0x00B998D0` | **Net** | 92 | `IsMultiplayer IsConnectedToInternet IsLobby IsServer IsClient ConnectToServer` | mercs2 online-restore mod (bindings audit §3.2); cfuncs binding-only |
| `0x00B99BBC` | **(Timer/misc)** | 4 | `Start Stop Pause Resume` | binding-only |
| `0x00B99BE8` | **Math** (extended) | 17 | `abs floor ceil round max min` (game-side; stdlib math is separate) | `abs 0x5C5970`, `floor 0x5C59B0`, `ceil 0x5C59F0`, `max 0x5C5A90`, `min 0x5C5AE0`, `pow 0x5C5BF0` — capi audit |
| `0x00B99C78` | **Lti/Movie/PDA** | 52 | `LTIMovieStart LTIMovieStop LTIVideoEnter LTIPrecacheDone` | binding-only |
| `0x00B99E28` | **Pg** (spawn/world) | 24 | `Spawn SpawnWithModel CreateRegion SpawnHomingProjectile Subdue FormatTime` | `Spawn 0x5D5D20`, `SpawnRelative 0x5D58D0`, `SpawnFromCamera 0x5D6010`, `SpawnPlayer 0x5D6740`, `StartHeliWaveSpawner 0x5DA4D0`, `SetSkirmishTable 0x5D9CC0` — population map |
| `0x00B99EF0` | **Human** | 21 | `DoAction SetState Knockdown SetPreemptiveRagdoll Emote ForceExitSeatNoSnap` | animation clip-picker (human_animation_selection); cfuncs binding-only |
| `0x00B99FA0` | **Human.Inventory** | 9 | `GetPrimaryWeapon GetSecondaryWeapon GetVehicleWeapon DropWeapon SetAllWeapons` | binding-only |
| `0x00B99FF8` | **Hud/Gui/Widget** | 114 | `CreateWidget DeleteWidget SetWidgetLocation SetTextText CreateFlashWidget CallFlashScriptFunction` | Scaleform bridge (scaleform_gfx map); cfuncs binding-only |
| `0x00B9A398` | **Marker/Hud2** | 38 | `AddObjective LoadTexture GetReticlePosition LoadFont _MarkerAdd GetLanguageNum` | `_Marker*` family (bindings audit §3.5); `GetLanguageNum 0x7B5740` (offset) |
| `0x00B9A4D0` | **Graphics** | 11 | `ScreenShot ReloadShaders SetGamma Bloom MotionBlur Monochrome` | sky_post_hdr / render_core maps; cfuncs binding-only |
| `0x00B9A530` | **Camera** (near/far/fov) | 7 | `SetNearFar SetFovParams SetFocusParams RestoreNearFar` | binding-only |
| `0x00B9A578` | **Atmosphere** | 37 | `Begin End SetTime SetTimeSpeed SetLightIntensity SetSky` | setter→C table `@0xb9a570` (sky_post_hdr map) |
| `0x00B9A6B0` | **Bloom/HDR post** | 7 | `SetBlurRadius SetThreshold SetMultiplier SetTargetLuminance SetAdaptiveLuminancePercent` | HDR post driver `FUN_0074f8d0` (sky_post_hdr map) |
| `0x00B9A778` | **Fade/Color** | 4 | `AmbientTop AmbientSides Terrain CameraFade` | binding-only |
| `0x00B9A7A8` | **Fire** | 3 | `Ignite Extinguish Put` | binding-only |
| `0x00B9A7D8` | **Camera2** (yaw/pitch/shake) | 14 | `GetYaw SetYaw GetPitch SetPitch StopBlending Shake` | binding-only |
| `0x00B9A854` | **_SYS** (module system) | 6 | `_IMPORT _INHERIT _DYNAMIC_IMPORT _DYNAMIC_REMOVE _MODULEINDEX _GETFENV` | Xbox offsets `0x7B453C`/`0x7B4ED4`/…; PC bodies binding-only (host §1.3) |
| `0x00B9A88C` | **Face** (FaceFX) | 6 | `BindFaceAnimSet PlayFaceAnim PlayFacialExpression SetUseBriefingLOD` | binding-only |
| `0x00B9A8C8` | **Airstrike/Munitions** | 12 | `SpawnCarpetBombLine SpawnPlaneNew SpawnOrdnance ConeSpawn Flyby FindExitPoint` | weapons_combat map (ordnance surface) |
| `0x00B9A938` | **Ai** | 66 | `Goal DefaultGoal Squad Role Deploy TweakAttachedSpawners SetSpawnList` | `TweakAttachedSpawners 0x5A4C40`, `TweakAttachedSpawnersInGroup 0x5A4D10`, `SetSpawnList 0x5A5180`, `GetSpawnList 0x5A4EA0`, `ResetAllSpawnLists 0x5A5860` — population map; `Set/GetRelation` — faction map |
| `0x00CDF098` | **(sockets)** | 3 | `getaddrinfo getnameinfo freeaddrinfo` | libc/Winsock, not game logic |
| `0x00DFDA70` | **String** | 13 | `charAt charCodeAt concat indexOf lastIndexOf slice` | `GetHash`/hash keying → §4; cfuncs binding-only |

**Totals:** 33 tables above are the game namespaces the trace hooks; combined with the counts they
sum to the ~1216 live-hooked bindings across 53 tables (a few small tables — e.g. per-widget
listener tables — are counted by the trace as game tables but fold into the Hud/Gui surface).

**Stdlib + Scaleform block (not the game surface, summarized).** Base/`_G` `0x00B924B8` (24;
`print`→stub), string `0x00B923A8` (15), table `0x00B92428` (9), coroutine `0x00B92580` (6), plus
~20 Scaleform AS2 runtime tables `0x00B932C8`–`0x00B93BC8` (Date 39, MovieClip drawing 39, Array 13,
geom.Point/Rectangle/Matrix/ColorTransform, TextField, Sound, XML/HTTP …) — these belong to the GFx
2.0.48 ActionScript VM (scaleform_gfx map), a **separate** scripting engine that happens to register
through the same `luaL_Reg` mechanism into the Lua host.

**Two address spaces (reconciliation).** The `0x00B9xxxx` table VAs + `0x005xxxxx`/`0x008xxxxx`
cfunc VAs here are from the **unpacked SecuROM image** (this map's canonical source, matching the
capi audit + the live trace). The earlier `lua_engine_bindings_audit.md` cites `0x0079xxxx`
*string* offsets + a `0x00798770`–`0x00799200` table range from a **different (cracked
`MERCENAR.EXE`) image**; those are `.rdata` string offsets, not cfunc bodies. When they conflict,
prefer the unpacked-image VAs (walk-validated against `Pg.Spawn`/`Ai.TweakAttachedSpawners`).

---

## 4. Name-hash: `String.GetHash` / `pandemic_hash_m2` = `Hash_String FUN_00824270`

Events, handlers, template names, tunables, and the spawn-by-hash registry are all keyed by the
Pandemic **m2** name hash. The PC hasher is **`Hash_String FUN_00824270`** (= `pandemic_hash_m2`,
the PC twin of the Xbox FNV marker `FUN_8290ba80`), with 256-bucket probe **`Hash_Probe
FUN_008242b0`** (diagnostics map). The `String.GetHash` Lua binding (String table `0x00DFDA70`)
funnels into it, and `Sys.StringToGuid`/`GuidToString` are the string↔hash marshalling exposed to
script. Every `Event.Post("name", …)` / `Event.Create(EventType, …)` resolves the string via this
hasher; the name-registry (`0xDF6B88` family) and `Pg.Spawn`'s raw-m2 template argument use the same
hash ([[name-registry-spawn-by-hash]]). Known event hashes cross-checked against it:
`ObjectHibernation`-family, `DamageMsg 0xC6507EE1`, `DestroyMsg 0x1ED7AD78`, spawn event
`0x7962caf5`, `hasCorruptedSave 0x32ff679b`. The 733k-entry rainbow table
([[rainbow-table-pipeline-and-sibling-tooling]]) is the inverse of this function.

---

## 5. Annotated excerpts (read first-hand)

### 5.1 Module-system bootstrap — `FUN_005a2c40` (502 B, READ)

Called once from `FUN_005a1760` (script-host init). It (a) pushes the `_SYS` C-closures onto the
stack and sets them as globals, then (b) for each pending module string, compiles+runs it via the
generic loadbuffer→pcall pair:

```c
iVar7 = *(int *)(param_1 + 0x10);          // iVar7 = lua_State*  (param_1 = host, +0x10 = L)
FUN_0085da90(FUN_00862100);                // push C closure #1  (a _SYS hook)
FUN_008688d0(iVar7,*(int*)(iVar7+8)+-8,0); // luaD_call: set it as a global (top-1)
FUN_0085da90(&LAB_00863200);               // push C closure #2
FUN_008688d0(...);                         //   set global
FUN_0085da90(FUN_00865570);                // push C closure #3
FUN_008688d0(...);                         //   set global
... FUN_0085dcd0() x4 ...                  // push 4 more table/value slots (nil-init _MODULES etc.)
if (PTR_DAT_00dfd478 != 0) {               // walk the pending-module pointer table
  do {
    cVar4 = thunk_FUN_02471b40(*ppuVar8);  // gate: module present/needed?  (SecuROM thunk, benign)
    pcVar2 = *(char**)(&PTR_s__G__MODULES________MODULESMETATA_00dfd480 + iVar7);  // the source chunk
    ...strlen(pcVar2)...
    iVar7 = FUN_00860240(pcVar2, len);     // luaL_loadbuffer(chunk_ptr, len)   [compile]
    if (iVar7 == 0) iVar7 = FUN_0085df50(0); //  lua_pcall(0)                    [run]
  } while (next module);
}
```

The literal chunk at `PTR_s__G__MODULES…_00dfd480` is
`_G._MODULES = {}; _MODULESMETATABLE = { __index = _SYS._MODULEINDEX };` — the module registry +
lazy-index metatable. So the host **registers the `_SYS` C-hooks, then compiles-and-runs the Lua
that builds `_MODULES`/`import`/`inherit` on top of them.** `FUN_00860240` (loadbuffer) and
`FUN_0085df50` (pcall) are the generic compile/run helpers reused for every inline chunk.

### 5.2 GUI-module guard chunk — `FUN_0060994e` (READ)

Same load→pcall shape, running a small guard chunk (`if _MODULES and _MODULES.mrxgui_t…` — the
`_MODULES.mrxgui.GetWidgetByName("Shell")…` widget-access pattern) before touching a module:

```c
pcVar2 = s_if__MODULES_and__MODULES_mrxgui_t_00bbba10;      // the guard source
do { pcVar3 = pcVar2; pcVar2 = pcVar3 + 1; } while (*pcVar3);// strlen
iVar4 = FUN_00860240(s_..._00bbba10, pcVar3 + -0xbbba10);   // luaL_loadbuffer(ptr,len)
if (iVar4 == 0) iVar4 = FUN_0085df50(0);                    // lua_pcall
```

Confirms `FUN_00860240`/`FUN_0085df50` are *the* inline-chunk compile/run pair the embedding uses
everywhere — the host runs Lua source (not just precompiled chunks) at runtime, consistent with the
live console.

### 5.3 `luaL_loadbuffer` — `FUN_00860240` (34 B, READ)

The compile leaf both bootstrap runners call; `in_EAX==0` (empty chunkname) short-circuits, else it
sets up the reader frame and calls the parse/undump driver `FUN_00868cc0(sz)`:

```c
void __fastcall FUN_00860240(name?, sz, buff, chunkname) {   // EAX=name(len token), EDX=L
  if (in_EAX == 0) { FUN_00580088(); return; }               // guard
  puStack_14 = &LAB_00860220;   // ZIO reader thunk (feeds lexer/undump from the buffer)
  uStack_c   = sz;
  FUN_00868cc0(sz);             // luaD_protectedparser / lua_load core → Proto
}
```

### 5.4 The shared dev/debug stub — `0x006D5640` (READ)

```asm
006D5640  33 C0    xor eax, eax     ; nresults = 0
006D5642  C3       ret              ; a lua_CFunction that does nothing
```

~60+ dev/debug binding func-pointers point here on retail (§2). `Debug.Printf`'s slot
(`0x00B9882C`) → `0x006D5640` is the proof specimen.

---

## 6. Confirm-live inventory (x32dbg, read-only while PAUSED — [[x32dbg-mcp-no-resume]])

1. **The `luaL_Reg` registrar VA.** Break where the 60 table VAs are consumed — set a read bp on
   `0x00B98A78` (Sys table) or `0x00B9A854` (`_SYS`) during init; the caller is
   `luaL_register`/`luaL_openlib`. Pins the registrar (open §1.2) and confirms table→global name
   binding.
2. **`luaU_undump` VA.** HW-exec bp on the WAD-bytecode load path (a precompiled chunk load) to pin
   the loader body (present but unlocated by name in both builds); confirms the disasm/flip/reassemble
   pipeline's target.
3. **Binding-only cfunc bodies.** Force-decompile the tables' remaining cfuncs with a
   `DecompileProfileAccessors.java`-style forcing script (the same known TODO across every sibling
   map). Priority: the high-count namespaces Player (107) / Hud (114) / Object (87) / Net (92) /
   World (80) / Ai (66) — this is the bulk of the 1216 whose bodies Ghidra never emitted.
4. **Stub membership.** For any suspect dev binding, read its `luaL_Reg +4` and compare to
   `0x006D5640` to confirm it is neutered vs. live.
5. **`Hash_String FUN_00824270`** — break on entry with a known string (e.g. `"ObjectHibernation"`)
   to read the exact m2 constant and confirm it equals the event-hash table (validates §4 against
   the rainbow table).
6. **Arg-fetch ABI.** Confirm the PC `luaL_check*` leaves (`0x0085F3A0`/`0x0085F130`/`0x0085DFC0`)
   are the twins of Xbox `FUN_8241cbf0` by breaking inside a simple cfunc (`Sys.GetPlatform`) and
   watching the stack reads.

---

## 7. Open / unlocated (honest)

- **Xbox host bodies are unrecoverable in this build** (the asymmetry): the module-system bootstrap,
  binding registration, and VM dispatcher have **no** string/symbol anchor in `xenon_decomp_named.c`.
  All host + surface findings are PC-anchored. The only Xbox code-grounded fact is the
  `FUN_8241cbf0` (261-caller) arg-fetch ABI and `CurrentLuaState @824340a0`.
- **The `luaL_register` registrar VA** (which caller feeds the 60 table VAs) is not yet pinned —
  mechanism proven, VA is a confirm-live item.
- **`luaU_undump` VA** is unlocated by name in *both* builds (present, string/offset only).
- **~1100 cfunc bodies are binding-table-only** (name→cfunc slot known, no static caller ⇒ Ghidra
  emitted no body). ~120 are VA-recovered across the sibling maps (consolidated in §3). The rest
  need the forcing-script.
- **`_SYS._*` hook bodies** (`_IMPORT`/`_INHERIT`/`_MODULEINDEX`/`_GETFENV`/`_DYNAMIC_*`) are
  binding-only on PC — the *semantics* are known from the Lua-side wrappers + the 370-script corpus,
  but the C bodies aren't decompiled.
- **Two-image VA drift** — resolved (§3): use unpacked-image VAs, not the cracked-`MERCENAR.EXE`
  string offsets.

---

## 8. Reconciliation with `mercs2_engine`

**Row 16 (Scripting host) = ✅** — `tools/wad_simulator/crates/mercs2_script` ([[mercs2-script-lua-host]])
already implements a faithful host: **Lua 5.4 (mlua, vendored)** + a measured 5.1→5.4 compat prelude
(`setfenv`/`module`/`loadstring` aliases, `unpack`/`table.getn`/`math.mod`/`string.gfind`) + the
**module system** (`import`/`inherit`/`dynamic_import`, per-module env `__index→_G`, `inherit`
chains `__index→base`, `_MODULES` cache, cyclic-safe register-before-exec) + the **`EngineHost` IoC
seam** (the inversion the original `Sys.*` C-table embodied: dependency points engine→script host).
It runs the **real decompiled `MrxUtil.SpawnActor`** through 15+ real game modules. Divergences to
track, from this map:
- VM version: engine = **5.4** vs base = **5.1.2 / float**. The compat prelude covers the measured
  surface; `float` `lua_Number` (base) vs `double`/`int64` (5.4) matters only where scripts rely on
  float truncation — audit `getfenv` (19 sites) + numeric edge cases as the surface widens.
- The host is trace-gated against **Surface-B** (`binding_map.json`, 53 tables / 1216 fns) — this
  map is the human-readable index of that oracle.

**Row 17 (Script binding surface) = 🟡 thin slice** — the engine's `register_engine` installs a
boot/PMC-spawn slice: real **Debug**, partial **Sys**/**Pg** (`Pg.GetGuidByName`→nil-when-0,
`Pg.Spawn`), partial **Object** (`SetName`/`SetPosition`/`SetYaw`/`GetPosition` + no-op
`SetTransformToObject`/`Attach`/`DisablePhysics`), stub **Ai.Enable**/**Vehicle.EnableTurret**, fake
**Event.Create** — plus an **autostub tracer** (`enable_autostub`) that turns reads of unimplemented
Capitalized tables into logged no-ops (the whole MrxUtil tree needs only 4: Controller, VO,
GuiSetDialogBoxMode, GuiSetSupportMenuMode). **This map is the full surface that slice grows into:**
53 namespaces / ~1216 cfuncs, with the ~120 VA-recovered bodies (§3) as the first faithful
implementations to port and the binding-only bulk as the queue. The priority order for widening
matches the count column: Player/Hud/Object/Net/World/Ai are where the game logic lives.
