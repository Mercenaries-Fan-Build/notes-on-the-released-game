# Mission / contract flow — PC code map

**Scope:** the **mission / contract flow** as retail PC `Mercenaries2.exe` actually implements it —
contract accept / complete / fail, objective tracking, the mission-script lifecycle, the **engine
game-state machine** that every mission transition runs through (`Sys.RequestGameState`), the
**layer/overlay** streaming a mission binds its world content to (`Pg.LoadLayer` / `UnloadLayer` /
`ReloadLayer` / `IsStaticLayer`), the **context-action** hook missions use for interaction, and the
`Pg.Contract*` trio. Plus the complete **`Pg` binding surface** (`luaL_Reg` table `0x00B99328`,
**80 cfuncs**) and the neighbouring **`Junk` table** (`0x00B99E28`, 24 cfuncs).

This is the map for the biggest structural hole in the project: mission/contract has **no scoreboard
row, no crate, and no map** (`docs/modernization/engine_support_inventory.md` §Boot rows K1 call it
out as ⛔ four times; there is no `mercs2_mission` crate in `tools/wad_simulator/crates/`).

**Boundaries with sibling maps** (cited, not re-derived):

| Belongs to | Not here |
|---|---|
| [`world_streaming_pc_code_map`](world_streaming_code_map.md) / [[world-streaming-spec]] | the node/ASET streamer itself; this map only owns the *layer* cfuncs that request it |
| [`scripting_host_binding_code_map.md`](scripting_host_binding_code_map.md) | the Lua host, `luaL_Reg` mechanics, the shared `return-0` stub `0x006D5640` |
| [`player_code_map.md`](player_code_map.md) | the player object/roster, the profile singleton `[0x01176054]` (this map only adds `+0xA86C`) |
| [`faction_reputation_code_map.md`](faction_reputation_code_map.md) | the `Report` namespace (`Report.Init/Completed/Failed/GetInfractions/SetDelay` = **faction infractions**, not mission completion — see §6.3), pursuit cfuncs `Pg.*Pursuit*` |
| [`save_serialize_code_map.md`](save_serialize_code_map.md) | the `.profile` singleton `[0x01176054]`, `ProfileHash`, `saveProfile` — **and the writer of the `+0xC3D` retry flag** (`:143`). ⚠ It does **not** own `[0x01175F30]`: `rg 0x01175F30 docs/reverse_engineer/save_serialize_code_map.md` returns **zero hits**. The save-manager singleton is currently unowned; §6.4 pins it here provisionally. |
| [`event_bus_code_map.md`](event_bus_code_map.md) | the general event bus; §3.3 pins the *specific* ring the state machine uses |
| [`scheduler_tick_code_map.md`](scheduler_tick_code_map.md) / [`input_code_map.md`](input_code_map.md) | the frame chain — §3.5 **closes** it (no longer a reconciliation: the app-stack slot is pinned) |
| [`docs/mercs2-luacd/02_mission_task_framework.md`](../mercs2-luacd/02_mission_task_framework.md) · [`03_contracts_jobs.md`](../mercs2-luacd/03_contracts_jobs.md) | **the whole Lua mission framework** (`MrxTask*`, `MrxMissionFlow`, `MrxState`, objectives, rewards). §7 cites it; it is not repeated. |
| [`docs/ui/main_menu_structure.md`](../ui/main_menu_structure.md) | the shell/menu state strings (`startShell`, `newGame`, …) — a *different* machine from §3 |

**Sources.** PC: the 27k-fn Ghidra decomp `output/_ghidra/mercs2_unpacked.exe_decomp.txt` (unpacked
SecuROM image, base `0x00400000`) **and** first-hand capstone disassembly + `.rdata`/`.data` reads
straight out of `output/_ghidra/securom_dump/mercs2_unpacked.exe` for the ~40 `Pg`/`Sys` cfuncs
Ghidra never got an entry point for. Binding name→VA: the `.rdata` `luaL_Reg` walk (own walk this
pass, cross-checked against `mods/lua_trace_asi/reference/binding_map.json`
[[lua-trace-asi-surface-b-oracle]]). Name hashes computed with `tools/pandemic_hash.py`
(`pandemic_hash_m2`; `tools/fnv.py`'s `m2()` is the same function and agrees on every constant
here) — see the "never invent a hash" discipline [[no-arbitrary-hashes]]. Xbox oracle:
[`docs/mercs2-pdb-analysis/game-systems.md`](../mercs2-pdb-analysis/game-systems.md)
§Missions/contracts/objectives. Script traffic: the `corpus_calls` census carried in
`tools/wad_simulator/crates/mercs2_script/src/bindings/pg.rs`, plus own greps where the crate's key
was wrong (§1, `Junk`).

> ⚠ **Census scope, corrected 2026-07-26.** This line used to say "370 scripts of
> `docs/mercs2-luacd/`". The crate's numbers do **not** reproduce under that key — they reproduce
> under `docs/mercs2-luacd/**` **plus** `docs/mercs2-dlc-luacd/src/**`, i.e. **370 + 39 = 409
> scripts**. Proof by counterexample:
> `rg -oN 'Pg\.GetGuidByName\(' docs/mercs2-luacd/ | wc -l` = **1103**, while
> `rg -oN 'Pg\.GetGuidByName\(' docs/mercs2-luacd/ docs/mercs2-dlc-luacd/src/ | wc -l` = **1240**,
> which is the crate's recorded value exactly. Same for `RemoveContextAction` 26→**32**,
> `AddContextAction` 20→**27**, `UnloadingStaticLayers` 2→**6**, `LoadIsRetry` 6→**10**,
> `ResetSingletonDone` 2→**5**, `LoadAsset` →**36**. Two counting hazards worth knowing:
> `docs/mercs2-dlc-luacd/raw/**` is the register-form decompile (`L0_1 = Pg; L0_1.GetGuidByName`)
> and contributes **zero** `Pg.` matches, so it is excluded by naming accident rather than design;
> and `docs/mercs2-luacd/src/` carries 22 byte-identical duplicate basenames across `shell/` and
> `resident/`, so counts touching those are doubled relative to "distinct scripts".
>
> Consequence for this map's slice: **DLC missions call `Pg.Contract*` zero times**, but **4 of the
> 6** `Pg.UnloadingStaticLayers` calls are DLC — the DLC leans on the static-layer teardown path far
> harder than the base game.

**Method / honesty model.** Same discipline as the sibling maps. Confidence: **H** = read the body
(decomp *or* raw disassembly) with a can't-coincide fingerprint — a cracked hash, a string literal,
a table walk · **M** = one strong structural signal · **L/open** = positional or hash-only →
confirm-live. Every offset states the function it was read from. A cfunc with **no decompiled body
and no disassembly read here** is listed *binding-only*, never guessed.

> **SecuROM note** ([[securom-decompiled-not-a-blocker]]). Two helpers in this map —
> `FUN_0045E440` (layer-record lookup) and `FUN_006B3560` (level-load-request builder) — are short
> **split thunks** that `jmp` through a runtime-resolved slot (`_DAT_02455100`, `_DAT_0244F500`).
> Their *call sites and arguments* are readable and are what this map cites. **The slots are
> resolved in the dump and the deref works** — but it lands on the SecuROM **VM entry**
> (`0x01AAFF10`), not on relocated x86: these two are *virtualised*, which is the hard case the
> memory explicitly carves out. See §9 item 4 for the deref chain and the lift/trace recipes.

> **Image note.** `output/_ghidra/securom_dump/mercs2_unpacked.exe` is a **live memory dump**, which
> is why its runtime-populated tables (`0x01175C80[]`, `0x017BBCCC[]`) have values at all — and also
> why three of its `.text` bytes are `pmc_bb.dll` hot-patches rather than retail (§8). Where a
> *static* body is wanted, `mercs2_nodrm_v2/v3.exe` are the clean images. ⚠ Do **not** substitute
> `genuine_patched_unpacked.exe` — it is a different build.

---

## 0. Result in one line

**The retail engine implements no mission logic at all.** The entire contract/objective/mission
state machine is **Lua** (`MrxTask*` / `MrxMissionFlow`, already mapped in
[`02_mission_task_framework.md`](../mercs2-luacd/02_mission_task_framework.md)); what the C++ side
provides is exactly four things: (1) a **20-state game-state machine** — table `PTR_PTR_01175C80`,
current state `DAT_01175C7C`, entered by `FUN_004C0F10`, pumped by `FUN_004C09C0`, driven from Lua
by `Sys.RequestGameState` `0x005E4AF0`, whose state names are `pandemic_hash_m2` hashes that this
map **cracks (19 of 20)**; (2) **layer load/unload** (`Pg.LoadLayer` `0x005D4C80` etc.) with a
`static`-vs-`dynamic` flag bit and a guard that refuses to unload a static layer outside
`Pg.UnloadingStaticLayers` — **silently, by pushing `nil`**; (3) a **context-action** registration
(`Pg.AddContextAction` `0x005D7630` → `FUN_004B2C60`) with co-op replication; and (4)
`Pg.ContractActivated/Completed/Cancelled`, which are a **write-only breadcrumb** — a single
`strncpy` of the contract name into a `0x40`-byte field at `[0x01176170]+0xF149` with **no static
reader anywhere in `.text`**; `ContractCompleted` and `ContractCancelled` are literally **the same
function** (`0x005D7E40`), so the engine cannot even distinguish success from failure.
`Gui.AddObjective` is the shared **`return-0` stub** `0x006D5640`.

**Naming, resolved:** table `0x00B99328` is **`Pg`**, not `World` (§1).

> ### ⚠ Corrected 2026-07-26 — two headline claims this section used to make
>
> **1. "`Pg.UnloadLayer` on a static layer raises a Lua error."** *(asserted four times: §0.5, §5.2,
> §6.2, §10.6.)* **Wrong.** `FUN_004B2A50` is not `luaL_error` — its entire 0x27-byte body is
> `lua_checkstack(L,1)` then `mov dword [L->top+4], 0` (`LUA_TNIL`) / `add dword [L+8], 8` /
> `mov eax, 1` / `ret`, byte-identical in `mercs2_unpacked.exe` **and** `mercs2_nodrm_v3.exe`. It is
> the out-of-line form of the missing-argument idiom the compiler *inlines* verbatim into
> `Pg.ContractActivated 0x005D7DE3`, `Pg.LoadLayer 0x005D4CBB`, `Pg.IsStaticLayer 0x005D4C23` and
> `Sys.RequestGameState 0x005E4B30`. Retail's static-layer refusal is **silent `nil`**. §10.6 used
> to tell reimplementers to make it loud "instead of the silent world corruption" — that is exactly
> backwards; the silent path *is* retail. Sweep in §5.2, §6.2, §10.6.
>
> **2. "The per-frame system pump is reached only through the state machine's RUN phase, so 'which
> game state am I in' gates the simulation itself."** **Half right.** The *linkage* is proven and
> now stronger than before (§3.5): `FUN_004C9740` and `FUN_004C0EC0` each have exactly one direct
> caller and **zero** occurrences of their literal address in any section of the image, so no
> vtable or function-pointer table can reach them either. But the **game state does not gate it**:
> at `0x004C0B14` the pump does `mov ecx,[0x1175c7c]; cmp ecx,ebx(=0); je 0x4c0b5b`, and
> `0x004C0B5B` still falls into `call 0x4c0ec0` at `0x004C0B6A`. A NULL current state skips only
> the *state's own* `Update`. The real gates are the app-stack layer's phase (`[this+8] == 2`), the
> foreground/`Sleep(100)` predicate at `0x004C0AD6`, and `[0x01175A94] != 1` at `0x004C0B08` — a
> **level-transition handshake**, not a pause flag (§3.5).
>
> Reproduce both: `python -c "from pe import load; print(load('unpacked').dis(0x004B2A50,0x28))"`
> and `…dis(0x004C0AD0,0xC8)` with the `Img` helper described in §11.

---

## 0.5 Master marriage table

| Role | Xbox symbol | PC addr | Married by | Conf |
|---|---|---|---|---|
| **Lua namespace registry** (the arbiter for §1) | — | **`0x00DFD478`**, 31 rows × 12 B, zero row at `0x00DFD5EC` | walked the image; row 0 = `_SYS`/`0x00B9A854`/the `_G._MODULES={}` chunk — matches the scripting-host map exactly | H |
| **`Pg` `luaL_Reg` table** | — | **`0x00B99328`**, 80 entries, 2 stubs | registry row 2 names it `"Pg"`; its post-register chunk is `GetGuidByName = Pg.GetGuidByName; …` | H |
| **`Junk` `luaL_Reg` table** | — | **`0x00B99E28`**, 24 entries, 15 stubs | registry row 19 names it `"Junk"`; 12 `Junk.*` call sites in the Lua corpus | H |
| **Namespace bootstrap** | — | **`FUN_005A2C40`** | reads the registry with a 12-byte stride, `luaL_loadbuffer FUN_00860240` + `lua_pcall FUN_0085DF50` on field `+8` | H |
| **Game-state table** | — | **`PTR_PTR_01175C80`**, 23 slots (`cmp eax,0x17`), 20 filled | ⚠ **runtime-populated**, not statically initialised (`FUN_004C0FF0`, `mov [eax*4 + 0x1175c80], edx` @`0x004C100D`) — all 23 slots read **`0x00000000`** in `mercs2_nodrm_v3.exe`. The *state objects* at `0x00DCBAFC`…`0x00DCBC28` **are** static (byte-identical dump vs disk). Each entry `+4` = an m2 hash, **19 of 20** cracked (§3.1) | H |
| **Current game state** | — | **`DAT_01175C7C`** (`+4` = name hash) | every gate in `Sys.RequestGameState` / `Pg.UnloadLayer` / `Sys.IsLoadingOrStreaming` reads it | H |
| **Enter state** | — | **`FUN_004C0F10`** | linear scan of the 23-slot table for `[1] == hash`, then vtable `+0xC` then `+4`, then broadcast. Hash arrives in **`edx`** (`cmp [ecx+4], edx` @`0x004C0F2B`) — a register arg Ghidra drops; `ret 8` = two stack args | H |
| **Exit state** | — | **`FUN_004C0FA0`** | vtable `+8`, broadcast, null the current pointer | H |
| **State-machine pump** | — | **`FUN_004C09C0`** ← **app-stack layer 4's `vt+0x0C`** (`.rdata:0x00BB046C`) ← `FUN_004C15E0` ← `FUN_004C14F0` ← `FUN_00630EF0` | phase 2 drains requests via `FUN_004C9CF0`, ticks vtable `+0x10`, then `FUN_004C0EC0`. The pump's **only** direct `call` is `0x004C13D8`, which is the *shutdown* path (§3.5) | H |
| **App-stack layer 4 = the game layer** | — | object **`0x00D6C244`**, vtable **`0x00BB0460`**, `[0x00BB046C] = 0x004C09C0` | `FUN_004C15E0` invokes it at `0x004C163C` (`mov edx,[eax+0xC]; call edx`). ⚠ the array `0x017BBCCC[]` is **runtime-populated** by `FUN_004C1170` — all-zero on disk. Layer **3** (`0x00D6C238`, vt `0x00BB0450`, `+0xC = 0x004C00E0`) is the singleton install table | H |
| **Shutdown pump** | — | **`FUN_004C13A0`** ← **one** caller, `0x00631AAF` | ⚠ **not** a per-frame entry. `0x00631AAF` sits *after* the main loop's back-edge (`0x00631A99 je 0x631938`) and after the handle release at `0x00631AA9`. Its body forces layer 4's phase 2→3 (`mov dword [0xd6c24c], 3`) and pumps once with `fldz` (dt = 0.0) on the same object `ecx = 0xd6c244` | H |
| **`enter` / `exit` broadcast tags** | — | **`0x9DA97065`** / **`0xDB41017D`** | `pandemic_hash_m2("enter")` / `("exit")`, both reproduced. Built at `0x004C0F7B` (enter) and `0x004C0A6B`+`0x004C0A9F` (exit), both into `FUN_004C9E70` | H |
| **`Sys.RequestGameState`** | — | **`0x005E4AF0`** | read (disasm): hashed-string arg, two swallow gates, 16-B publish | H |
| **State request ring** | `SendEvent_*` family | publish **`FUN_004BDD10`** / drain **`FUN_004C9CF0`**, storage `DAT_0120F510` (20 × 16 B) | read both; CS-guarded, 8-subscriber bitmask fanout | H |
| **`Pg.ContractActivated`** | `ContractActivated`, `sContract` | **`0x005D7DB0`** | read (disasm): `strncpy([0x01176170]+0xF149, arg, 0x3F)`. ⚠ its **success** path (`0x005D7E2D`) does `mov eax, edi (=1)` with **no Lua push** — see §4.1 | H |
| **`Pg.ContractCompleted` == `Pg.ContractCancelled`** | `ContractCompleted`, `ContractCancelled` | **`0x005D7E40`** — *one* body for both table slots | read (disasm): `strncpy(same field, "" @0x00BA8B09, 0x3F)`; ⚠ `mov eax,1` is the **result count**, and nothing is ever pushed — see §4.2 | H |
| Contract-name field | `sContract` | **`[0x01176170] + 0xF149`**, `0x40` B | zeroed by the ctor `FUN_006C8A20`; **3 refs in all of `.text`**, all writes | H |
| **`Pg.LoadLayer`** | — | **`0x005D4C80`** | read: type-hash `0xE6B81A54` == `m2("layer")`, record `+0x18` bit0/bit2 | H |
| **`Pg.UnloadLayer`** | `UnloadMissionSpiel` (adjacent) | **`0x005D4E40`** | read: **pushes `nil` (`FUN_004B2A50`)** unless `DAT_01175F58` or `rec+0x18 & 1`. ~~`luaL_error`~~ — corrected 2026-07-26, see §0 and §5.2 | H |
| **static-layer-unload gate** | — | **`DAT_01175F58`** | written by `Pg.UnloadingStaticLayers` `0x005D4B50`, read by `GetUnloadingStaticLayers` `0x005D4BA0` | H |
| **`Pg.AddContextAction`** | — | **`0x005D7630`** → **`FUN_004B2C60`** | read both; 128-B name copy, default label hash `0xBA71C11C` == `m2("default")`, net replicate via `FUN_007007C0` | H |
| **`Sys.GetSkipMission` / `SetSkipMission`** | `GetSkipMission`, `SetSkipMission` | **`0x005E54F0`** / **`0x005E5510`**, buffer **`DAT_01175B38`** | read (disasm): push/inline-strcpy on the same address | H |
| **`Sys.IsLoadingOrStreaming`** | — | **`0x005E4D40`** | read: `state ∈ { m2("loading"), m2("waitforstreaming") }` | H |
| **level→mission boot** | — | `Sys.SetLevelName` `DAT_01175AB8` · `SetMasterScriptName` `DAT_01175B78` · `Sys.StartSingleplayer` **`0x005E4C50`** → `FUN_006B3560(&levelName,&scriptName,2,1)` → `FUN_004BDE40` | read all four bodies | H |
| **`Sys.ForceNextAutosave`** | — | **`0x005E6670`** → `[0x01176054] + 0xA86C = 1` | read: writes the **profile singleton** the player map owns | H |
| **`Gui.AddObjective`** | `AddObjective`, `SendEvent_AddObjective` | **`0x006D5640`** = the shared `return-0` **stub** | table walk; the stub VA is the scripting-host map's | H |
| Singleton install table | — | **`FUN_004C00E0`** | assigns ~30 `PTR_PTR_0117xxxx` globals to their static instances, incl. `0x01176170`. ⚠ **zero direct callers**; its one literal-address occurrence image-wide is `.rdata:0x00BB045C` = **app-stack layer 3's `vt+0x0C`**. "Called three times from `FUN_004C15E0`" describes the *effect* (the stepper re-ticks a layer while its phase climbs), not the mechanism | H |
| **`[0x01176170]` role** | Xbox profiler label `PgSysNetOnline` (unbound) | `= 0x014CF228`, **four** vtables (`0x00BCFE84` 74 slots / `0x00BCFEB0` / `0x00BCFFB0` / `0x00BD0040`), size `0xF190` | the **online / multiplayer-services Pangea game system**. Master key gives a **hard negative**: `[0x00BCFE84+0x34] = 0x00848E30`, whose whole body is `C2 04 00 = ret 4` — *not* `B8 <imm32> C3`, so **definitively not an ECS container** (positive control: `Players` vt `0x00BC3FB8+0x34 → 0x00647BA0 = mov eax,0xBC5DAC; ret`). §4.4 | H (role) · open (label string) |
| Contract-name field's host record array | — | **`[0x01176170] + 0x1C8`**, `0x100` × `0xD8` (3 × `0x40`-B names + `0x18` scalars) | ⚠ **not `+0x208`.** The ctor does `lea edi,[esi+0x208]` then `memset(edi-0x40, 0, 0x40)` @`0x006C8B60` — `edi-0x40` is the record base. Arithmetic check: `0x1C8 + 0x100*0xD8 = 0xD9C8`, and the next field is `lea eax,[esi+0xDA65]` @`0x006C8BBE` | H |
| **`DAT_00DFBD77` / `DAT_00DFBD78`** | — | **`Net.IsClient`** (`sessionMode == 1`) / **`Net.IsServer`** (`== 2`) | the engine names them: `Net.IsClient 0x005C67D0` is `mov bl, byte [0xdfbd77]`, `Net.IsServer 0x005C6810` is `mov bl, byte [0xdfbd78]`. §5.1 | H |
| layer-record lookup | — | `FUN_0045E440` / `FUN_0045E3F0` | SecuROM split thunks; role inferred from the `"layer"` type hash + the `+0x18` flag use | M |

---

## 1. `Pg` vs `World` — resolved, from the registry

Two project documents disagreed about `0x00B99328`:
[`scripting_host_binding_code_map.md`](scripting_host_binding_code_map.md) labels it
*"World (Pg layers/regions)"*; [`../lua_engine_bindings_audit_deep_dive.md`](../lua_engine_bindings_audit_deep_dive.md)
labels it `Pg` (at `0x00799328`, the cracked-image address = the same table, −`0x400000`).

**The arbiter is the engine's own namespace registry, `0x00DFD478` in `.data`** (not `.rdata` — the
section table puts `.data` at `0x00BF6000`). It is 31 rows of 12 bytes terminated by a zero row at
`0x00DFD5EC`, and `FUN_005A2C40` walks it with a stride of `0xC`, breaking on `[i*3] == 0`
(`while ((&PTR_DAT_00dfd478)[unaff_retaddr * 3] != 0)`). Each row is:

```c
struct NamespaceReg { const char *name; const luaL_Reg *reg; const char *post_register_lua; };
```

Field `+8`, where non-null, is a **Lua source chunk compiled and run immediately after the table is
registered** — `luaL_loadbuffer FUN_00860240` → `lua_pcall FUN_0085DF50`. Row 0 proves the decode:
`{"_SYS", 0x00B9A854, "\t_G._MODULES = {}; …"}` — exactly the `_SYS` table VA and the bootstrap
chunk the scripting-host map already documented.

**Row 2 is `{"Pg", 0x00B99328, "GetGuidByName = Pg.GetGuidByName; GetAllGuidsByName = Pg.GetAllGuidsByName; Controller = { … }"}`.**
The chunk names the namespace *inside itself*. There is **no `World` row anywhere in the 31**.

> ### Answer: the table at `0x00B99328` is **`Pg`**. `World` is not a namespace in this engine.

Corroboration, three ways: (a) the Lua corpus contains **zero** `World.*` call sites and 1,240
`Pg.GetGuidByName` ones; (b) the registry's `Pg` string pointer `0x00BB9030` is immediately followed
by `"layer"` at `0x00BB9034`, the literal `Pg.LoadLayer` pushes; (c) the deep-dive audit's
`0x00799328` is the same table in the other image. The `World` label originated in the live
Surface-B trace's per-table nickname column, which was assigned by hand, not read from the engine —
the same column also calls `_GuiInternal` (row 12) "Hud".

**The full registry** (name → `luaL_Reg` VA), which is also the definitive namespace inventory:

| # | Name | Table | | # | Name | Table | | # | Name | Table |
|--:|---|---|---|--:|---|---|---|--:|---|---|
| 0 | `_SYS` | `0x00B9A854` | | 11 | `Gui` | `0x00B9A398` | | 22 | `Animation` | `0x00B9A88C` |
| 1 | `Sys` | `0x00B98A78` | | 12 | `_GuiInternal` | `0x00B99FF8` | | 23 | `VO` | `0x00B988B0` |
| **2** | **`Pg`** | **`0x00B99328`** | | 13 | `Graphics` | `0x00B9A4D0` | | 24 | `Weapon` | `0x00B98860` |
| 3 | `Object` | `0x00B99608` | | 14 | `Sound` | `0x00B98C98` | | 25 | `String` | `0x00B98C88` |
| 4 | `Player` | `0x00B98FC0` | | 15 | `ObjectFilter` | `0x00B98770` | | 26 | `Table` | `0x00B98A60` |
| 5 | `Event` | `0x00B987F8` | | 16 | `Net` | `0x00B998D0` | | 27 | `Report` | `0x00B98F64` |
| 6 | `Ai` | `0x00B9A938` | | 17 | `math` | `0x00B99BE8` | | 28 | `Disguise` | `0x00B98F94` |
| 7 | `Human` | `0x00B99EF0` | | 18 | `Camera` | `0x00B9A7D8` | | 29 | `FactionZone` | `0x00B98FA4` |
| 8 | `Debug` | `0x00B98828` | | **19** | **`Junk`** | **`0x00B99E28`** | | 30 | `LTILibName` | `0x00B99C78` |
| 9 | `Vehicle` | `0x00B98918` | | 20 | `ObjectState` | `0x00B995B0` | | | | |
| 10 | `Airstrike` | `0x00B9A8C8` | | 21 | `Movie` | `0x00B99BBC` | | | | |

The registry also settled a **second** mislabel with a real cost: `mercs2_script`'s `pg_world.rs`
used to declare `NAMESPACE = "PgWorld"`, `GLOBAL = "Pg"` for table `0x00B99E28`. **Registry row 19
names it `Junk`**, and the game calls it that:

```
$ rg -oN 'Junk\.[A-Za-z_]+' docs/mercs2-luacd/ docs/mercs2-dlc-luacd/ | sort | uniq -c
   4 Junk.IsInstallable      2 Junk.UseExistingInstall   2 Junk.InstallToHDD
   2 Junk.FormatTime         1 Junk.ToggleAlarm          1 Junk.GetModelBBoxExtents
   1 Junk.DrawPath                                              → 13 sites, 7 distinct names
```

across `alarm.lua`, `mrxguishell.lua`, `mrxstatsmanager.lua`, `mrxtimer.lua`, `meccon001.lua`.
`pg_world.rs` recorded `corpus_calls: 0` for **all 24** entries precisely because the census searched
for `Pg.<name>`. Installing that table as `Pg` was also actively wrong: it would shadow nothing but
would leave `Junk` undefined, and `alarm.lua:58`/`mrxtimer.lua` would fault.

> **✅ Fixed in the repo (2026-07-26).** `pg_world.rs` now declares `NAMESPACE = GLOBAL = "Junk"`
> and the census has been re-run under the correct key: **7 of 24 rows nonzero, 13 call sites**
> total. (An earlier draft of this section said "12 sites / 6 names" — it missed
> `Junk.GetModelBBoxExtents`.) §10.7 is closed.

> Only three `Pg` names carry a `LoadingStaticLayers`-style engine-side flag; nine names in the
> `Junk` table also appear (identically stubbed) as dev commands. Both tables register **globals**;
> neither is a sub-table of the other.

---

## 2. The `Pg` binding surface — all 80, name → VA

`luaL_Reg` table **`0x00B99328`**. **⬤ = Ghidra body (39)** · **○ = binding-only, no static caller
(39)** · **▨ = the shared `return-0` stub `0x006D5640` (2)**. *calls* = `corpus_calls` from
`pg.rs`. Note **`ContractCompleted` and `ContractCancelled` share one function**, and
`FastCollectGroundVehiclesExceptTanks` aliases `FastCollectCars` — two distinct name→one body pairs
in a single table.

| # | Name | VA | | calls | # | Name | VA | | calls |
|--:|---|---|:-:|--:|--:|---|---|:-:|--:|
| 0 | `LoadingStaticLayers` | `0x006D5640` | ▨ | 2 | 40 | `SetBoundaryRadius` | `0x005D78B0` | ○ | 1 |
| 1 | `GetLoadingStaticLayers` | `0x006D5640` | ▨ | 1 | 41 | `GetBoundaryRadius` | `0x005D7920` | ○ | 0 |
| 2 | `IsStaticLayer` | `0x005D4BF0` | ○ | 3 | 42 | `SetWarningRadius` | `0x005D7970` | ○ | 0 |
| 3 | `UnloadingStaticLayers` | `0x005D4B50` | ⬤ | 6 | 43 | `GetWarningRadius` | `0x005D79E0` | ○ | 0 |
| 4 | `GetUnloadingStaticLayers` | `0x005D4BA0` | ○ | 3 | 44 | `GetTetherDiameterStart` | `0x005D7A30` | ○ | 2 |
| 5 | `ResetSingletonDone` | `0x005D4BE0` | ○ | 5 | 45 | `GetTetherDiameterEnd` | `0x005D7A80` | ○ | 0 |
| 6 | `LoadLayer` | `0x005D4C80` | ⬤ | 1 | 46 | `Rumble` | `0x005D8240` | ⬤ | 5 |
| 7 | `UnloadLayer` | `0x005D4E40` | ⬤ | 2 | 47 | `EnableRoad` | `0x005D7AD0` | ⬤ | 0 |
| 8 | `ReloadLayer` | `0x005D4F90` | ⬤ | 1 | 48 | `EnableIntersection` | `0x005D7BD0` | ⬤ | 2 |
| 9 | `AssetExists` | `0x005D53E0` | ⬤ | 1 | 49 | `SaveGame` | `0x005D7CB0` | ○ | 3 |
| 10 | `LoadAsset` | `0x005D54C0` | ⬤ | 36 | 50 | `LoadGame` | `0x005D7D30` | ○ | 2 |
| 11 | `UnloadAsset` | `0x005D5500` | ○ | 31 | **51** | **`ContractActivated`** | **`0x005D7DB0`** | ○ | 1 |
| 12 | `ReloadAsset` | `0x005D5540` | ○ | 0 | **52** | **`ContractCancelled`** | **`0x005D7E40`** | ○ | 1 |
| 13 | `Spawn` | `0x005D5D20` | ⬤ | 130 | **53** | **`ContractCompleted`** | **`0x005D7E40`** | ○ | 1 |
| 14 | `SpawnRelative` | `0x005D58D0` | ⬤ | 0 | 54 | `LoadIsRetry` | `0x005D7E70` | ○ | 10 |
| 15 | `SpawnFromCamera` | `0x005D6010` | ⬤ | 13 | 55 | `GetDistantSpawnPointOnPath` | `0x005D7EA0` | ⬤ | 3 |
| 16 | `GetGuidByName` | `0x005D3220` | ○ | **1240** | 56 | `AchievementIsGranted` | `0x005D8330` | ⬤ | 1 |
| 17 | `GetAllGuidsByName` | `0x005D3350` | ⬤ | 0 | 57 | `AchievementAddCount` | `0x005D8410` | ⬤ | 2 |
| 18 | `GetObjectsInArea` | `0x005D4910` | ○ | 17 | 58 | `LockPursuit` | `0x005D84F0` | ○ | 1 |
| 19 | `GetAwakeObjects` | `0x005D46C0` | ⬤ | 2 | 59 | `ClearPursuitLock` | `0x005D8620` | ○ | 1 |
| 20 | `GetAllLandingZones` | `0x005D34C0` | ○ | 2 | 60 | `SetPursuit` | `0x005D8690` | ○ | 1 |
| 21 | `FastCollectHelicopters` | `0x005D3A60` | ⬤ | 1 | 61 | `SetPursuitSeconds` | `0x005D87D0` | ○ | 1 |
| 22 | `FastCollectJets` | `0x005D3B80` | ⬤ | 0 | 62 | `AdjustPursuitLevel` | `0x005D8910` | ○ | 0 |
| 23 | `FastCollectFlying` | `0x005D3CA0` | ⬤ | 1 | 63 | `AdjustPursuitTimer` | `0x005D8B50` | ○ | 0 |
| 24 | `FastCollectTanks` | `0x005D3DF0` | ⬤ | 3 | 64 | `GetPursuitState` | `0x005D8D40` | ⬤ | 1 |
| 25 | `FastCollectCars` | `0x005D3F10` | ⬤ | 0 | 65 | `RestrictAllPursuit` | `0x005D90F0` | ○ | 0 |
| 26 | `FastCollectGroundVehicles` | `0x005D4030` | ⬤ | 6 | 66 | `RestrictPursuitFaction` | `0x005D9150` | ○ | 0 |
| 27 | `FastCollectGroundVehiclesExceptTanks` | `0x005D3F10` | ⬤ | 0 | 67 | `RestrictPursuitType` | `0x005D9250` | ⬤ | 0 |
| 28 | `FastCollectHumans` | `0x005D4180` | ⬤ | 11 | 68 | `SetMaxPursuitLevel` | `0x005D93C0` | ○ | 0 |
| 29 | `FastCollectBoats` | `0x005D42A0` | ⬤ | 0 | 69 | `SetMaxPursuitTime` | `0x005D9420` | ○ | 0 |
| 30 | `FastCollectUsables` | `0x005D44E0` | ⬤ | 0 | 70 | `SetPursuitLevelTimes` | `0x005D94A0` | ⬤ | 1 |
| 31 | `FastCollectProps` | `0x005D43C0` | ⬤ | 0 | 71 | `ClearPursuitRestrictions` | `0x005D9020` | ⬤ | 1 |
| 32 | `FastCollectBuildings` | `0x005D45A0` | ⬤ | 4 | 72 | `TweakPursuitParam` | `0x005D92E0` | ⬤ | 0 |
| 33 | `SpawnPlayer` | `0x005D6740` | ○ | 0 | 73 | `SetCustomPursuit` | `0x005D9A30` | ⬤ | 3 |
| 34 | `SpawnPlayerAdvanced` | `0x005D6800` | ○ | 0 | 74 | `ClearCustomPursuit` | `0x005D9C10` | ○ | 2 |
| **35** | **`AddContextAction`** | **`0x005D7630`** | ⬤ | 27 | 75 | `StartHeliWaveSpawner` | `0x005DA4D0` | ○ | 1 |
| **36** | **`RemoveContextAction`** | **`0x005D7820`** | ○ | 32 | 76 | `StopHeliWaveSpawner` | `0x005DA790` | ○ | 1 |
| 37 | `FindPointFromCamera` | `0x005D68E0` | ⬤ | 48 | 77 | `SetSkirmishTable` | `0x005D9CC0` | ○ | 0 |
| 38 | `IsPointInBoundary` | `0x005D6D60` | ⬤ | 4 | 78 | `AddSkirmishTemplate` | `0x005DA010` | ○ | 0 |
| 39 | `GetLineRegionPoints` | `0x005D7160` | ⬤ | 2 | 79 | `SetGlobalSkirmishState` | `0x005DA130` | ○ | 0 |

**Shape of the namespace.** `Pg` is not one system — it is five, sharing one table: name-registry
lookup (16–20), spawning (13–15, 33–34), the `FastCollect*` broad-phase queries (21–32), the
**layer/streaming** block (0–12), and **pursuit/skirmish** (58–79, which belongs to
[`faction_reputation_code_map.md`](faction_reputation_code_map.md) and `ai_code_map.md`). The
mission-flow slice this map owns is **0–12, 35–36, 49–54**.

**Traffic.** `GetGuidByName` alone is 1240 call sites — every mission script resolves authored
world objects by name through it, which is why the name registry ([[name-registry-spawn-by-hash]])
is the hard prerequisite for any mission runtime. Then `Spawn` 130, `FindPointFromCamera` 48,
`LoadAsset` 36, `RemoveContextAction` 32, `UnloadAsset` 31, `AddContextAction` 27.

### 2.1 The `Junk` table (`0x00B99E28`, 24)

| # | Name | VA | | # | Name | VA | | # | Name | VA |
|--:|---|---|---|--:|---|---|---|--:|---|---|
| 0 | `SpawnHomingProjectile` | `0x005BF860` ⬤ | | 8 | `InstallToHDD` | `0x006D5640` ▨ | | 16 | `LoadScript` | `0x006D5640` ▨ |
| 1 | `CreateRegion` | `0x005BFB00` ⬤ | | 9 | `UseExistingInstall` | `0x006D5640` ▨ | | 17 | `LoadFunctions` | `0x006D5640` ▨ |
| 2 | `Subdue` | `0x005BFCC0` ⬤ | | 10 | `Search` | `0x006D5640` ▨ | | 18 | `LoadData` | `0x006D5640` ▨ |
| 3 | `GetModelBBoxExtents` | `0x005BFF90` ⬤ | | 11 | `DumpAssets` | `0x006D5640` ▨ | | 19 | `DescribeGuid` | `0x006D5640` ▨ |
| 4 | `SpawnWithModel` | `0x005BFDF0` ⬤ | | 12 | `DumpAssetsDiff` | `0x006D5640` ▨ | | 20 | `SetQGrey` | `0x006D5640` ▨ |
| 5 | `FormatTime` | `0x005C0120` ⬤ | | 13 | `DumpTextures` | `0x006D5640` ▨ | | 21 | `ActivateAlarm` | `0x005C0360` ⬤ |
| 6 | `DrawPath` | `0x006D5640` ▨ | | 14 | `DumpAssetMemory` | `0x006D5640` ▨ | | 22 | `ToggleAlarm` | `0x005C0430` ○ |
| 7 | `IsInstallable` | `0x005C0340` ○ | | 15 | `DumpMemory` | `0x006D5640` ▨ | | 23 | `DumpStats` | `0x006D5640` ▨ |

**15 of 24 are the shared `return-0` stub** — this table is where the shipped build's dev commands
went to die. Two live consequences for the fix-pack/reimpl: `Junk.InstallToHDD` /
`Junk.UseExistingInstall` are **no-ops on PC** (console install-to-HDD), and
`Junk.IsInstallable` `0x005C0340` shares its body with `Sys.NoHud` — a two-name/one-body alias like
the two in `Pg`, so it certainly does not answer "can this be installed".

**And that shared body is now read (H).** `0x005C0340` is the *boolean* twin of `FUN_004B2A50`:

```asm
005C0340  mov  eax,[esp+4] ; mov ecx,[eax+8]   ; ecx = L->top
005C0347  mov  dword [ecx],   0                ; value  = 0
005C034D  mov  dword [ecx+4], 1                ; tt     = 1 = LUA_TBOOLEAN
005C0354  add  dword [eax+8], 8                ; top++
005C0358  mov  eax, 1 ; ret                    ; 1 result
```

**`Junk.IsInstallable()` and `Sys.NoHud()` return a constant `false`.** So
`mrxguishell.lua:322  if Junk.IsInstallable and Junk.IsInstallable() then` is **permanently dead
code** on PC and the install-to-HDD UI branch can never be reached. Only these two rows use
`0x005C0340` across all 1,103 cfuncs — a genuine two-name alias, not a shared stub family.

---

## 3. The game-state machine — the spine every mission transition runs through

### 3.1 The state table (H)

`PTR_PTR_01175C80` is a **23-slot array of state-object pointers, 20 filled**. Each object is
`{ vtable, u32 nameHash, … }`. `FUN_004C0F10` scans it `while (i < 0x17)`.

> ⚠ **Provenance, corrected 2026-07-26.** This section used to say the array is "statically
> initialised in `.data`". It is not — **the array is runtime-populated** by `FUN_004C0FF0`
> (`mov [eax*4 + 0x1175c80], edx` @`0x004C100D`, first-free-slot scan bounded by `cmp eax,0x17`),
> and all 23 slots read **`0x00000000`** in `mercs2_nodrm_v3.exe`. The **state objects themselves**
> (`0x00DCBAFC`…`0x00DCBC28`) *are* static: vtable and hash are byte-identical dump vs disk. This
> matters beyond pedantry — anyone re-deriving from a clean `Mercenaries2.exe` rather than the
> memory dump finds the array empty and concludes the map is wrong. The same correction applies to
> the app-stack array `0x017BBCCC[]` (§3.5). Reproduce: compare `u32(0x01175C80 + i*4)` between
> `mercs2_unpacked.exe` (20 nonzero) and `mercs2_nodrm_v3.exe` (0 nonzero).

Names are `pandemic_hash_m2` (`tools/pandemic_hash.py`); **19 of 20 crack against real words**, and
the cracked set includes several the code itself compares against by constant, which is the
can't-coincide part:

| slot | object | vtable | hash | name | how |
|--:|---|---|---|---|---|
| 0 | `0x00DCBAFC` | `0x00BB00D4` | `0xC8192FE5` | `pause` | m2 ✓ + compared in `FUN_004C0F10`'s neighbourhood |
| 1 | `0x00DCBB10` | `0x00BB00F0` | `0x96FB0F27` | `loading` | m2 ✓ + `Sys.IsLoadingOrStreaming` gate |
| 2 | `0x00DCBB38` | `0x00BB01B4` | `0x7D0B162C` | `unloading` | m2 ✓ + `RequestGameState`/`UnloadLayer` gates |
| 3 | `0x00DCBB24` | `0x00BB01D0` | `0x20BC86EA` | `unloadshell` | m2 ✓ **and** its vtable is adjacent to `unloading`'s — M→H |
| 4 | `0x00DCBB4C` | `0x00BB010C` | `0x05CE7A0C` | `waitforplayer` | m2 ✓ **and** its Update `0x004B9E40` polls a count then requests `waitforstreaming` — behavioural fit. L→**M** |
| 5 | `0x00DCBB54` | `0x00BB0128` | `0x7E289119` | `waitforstreaming` | m2 ✓ + `MrxState` Lua uses the literal |
| 6 | `0x00DCBB68` | `0x00BB0160` | `0x9B7AD367` | `waitfortether` | m2 ✓ + `MrxState` Lua |
| 7 | `0x00DCBB7C` | `0x00BB0144` | `0x53056C27` | **? — still uncracked** | see the slot-7 box below |
| 8 | `0x00DCBB8C` | `0x00BB00B8` | `0x51BFF7B1` | `shell` | m2 ✓ + `RequestGameState` gate |
| 9 | `0x00DCBBA0` | `0x00BB0198` | `0xFDC8B95E` | `reset` | m2 ✓ — M (no code gate) |
| 10 | `0x00DCBBAC` | `0x00BB017C` | `0x6D19FA15` | **`flush`** | m2 ✓ (reproduced) + vtable `0x00BB017C` sits between `waitfortether` and `reset` in `.rdata` order — **H** |
| 11 | `0x00DCBBE0` | `0x00BB01EC` | `0x38929BF7` | **`connecting`** | m2 ✓ (reproduced) + vtable `0x00BB01EC` sits immediately before `lobby` (`0x00BB0208`) and `online` (`0x00BB02B8`) — the multiplayer family in `connecting → lobby → online` order — **H** |
| 12 | `0x00DCBBE8` | `0x00BB0208` | `0x9AC591FB` | `lobby` | m2 ✓ — M |
| 13 | `0x00DCBBF4` | `0x00BB02B8` | `0x72558BE0` | `online` | m2 ✓ — M |
| 14 | `0x00DCBC00` | `0x00BB0368` | `0x57B5E35A` | `ingame` | m2 ✓ + pump special-case |
| 15 | `0x00DCBC08` | `0x00BB0384` | `0xB8CB300C` | `cinematic` | m2 ✓ + Lua literal |
| 16 | `0x00DCBC10` | `0x00BB03BC` | `0xEE0915FC` | `attract` | m2 ✓ + Lua literal |
| 17 | `0x00DCBC18` | `0x00BB03D8` | `0xCE7E5A43` | `exiting` | m2 ✓ + Lua literal |
| 18 | `0x00DCBC20` | `0x00BB03F4` | `0xED87E746` | `lti_precache` | m2 ✓ + Lua literal |
| 19 | `0x00DCBC28` | `0x00BB03A0` | `0xFA62754E` | `pda` | m2 ✓ + Lua literal |

Slots 20–22 are null (`FUN_004C0F10` breaks on the first null, so 20 is the effective cap).

> **Honest note on slot 3.** A bare 32-bit hash match is not evidence ([[aset-name-export]]).
> `unloadshell` is promoted to H only because the table *position* and the *vtable adjacency* to
> `unloading` corroborate it, and because the gate it guards ("while in this state, refuse a request
> for `shell`") is exactly what an "unloading the shell" state would do. Slots 10 and 11 are
> promoted to H on the *same* standard — reproduced `m2` **plus** vtable adjacency to a semantically
> adjacent state. Slot 4 sits at M (hash + behavioural fit, no adjacency argument). **Slot 7 stays
> open.**

All 19 names reproduce with `tools/pandemic_hash.py`:

```
m2("flush")        = 6D19FA15    m2("connecting") = 38929BF7
m2("waitforplayer")= 05CE7A0C    m2("enter")      = 9DA97065
m2("exit")         = DB41017D    m2("unloadshell")= 20BC86EA    m2("default") = BA71C11C
```

**Two of the twenty states have a no-op `Update`.** `connecting` (vt `0x00BB01EC+0x10`) and
`exiting` (vt `0x00BB03D8+0x10`) both point at `0x00848E30`, whose whole body is `C2 04 00 = ret 4`
— the class's shared do-nothing slot. Worth a line for a reimpl (§10).

> ### Slot 7 (`0x53056C27`) — uncracked, and probably vestigial (M)
>
> It survives a very large attack, so record the negative rather than repeating it. What *is*
> established:
>
> - **Behaviour.** Its `Update` `0x004BA7D0` reads in full as
>   `[this+8] += 1; [this+0xC] += [0x00D26394]; if ([this+8] > 0xA) publish{m2("ingame")};
>   if ([this+0xC] > [0x00D28B90]) publish{m2("ingame")}` — a short transitional wait bounded by
>   **both** 10 frames and a float timeout, ending in `ingame`. (The two arms are not exclusive; on
>   the frame where both cross it publishes twice, which the pump absorbs via its
>   `cur[1] != msg.hash` check.) Vtable `0x00BB0144`: `+04` enter `0x004BA660`, `+08` exit
>   `0x004BA710`, `+0C` init-with-args `0x009AB820`, `+10` update `0x004BA7D0`.
> - **The dword appears exactly three times in the whole image** — `.text:0x005339F1`,
>   `.data:0x00D2AD6C`, `.data:0x00DCBB80` (the slot-7 object's own hash field). The single `.text`
>   occurrence is the immediate of `cmp eax, 0x53056C27` at **`0x005339F0`**, inside a compare-tree
>   over `[cur+4]` — **a reader, not a requester.**
> - **⇒ Nothing in `.text` ever requests this state.** A request would need the hash as an
>   immediate fed to `FUN_004BDD10`, and there is no such site. The only remaining entry path is Lua
>   `Sys.RequestGameState("<name>")`, and the corpus holds 14 distinct state literals, none of which
>   hashes to it. **Best reading: slot 7 is declared, comparable, and unreachable in the shipped PC
>   build.** Graded **M** — it is an argument from exhaustive absence over one image, and a
>   `luaL_dostring`/console path would falsify it.
> - **What was ruled out** (so nobody repeats it): ≥52.2 M distinct mined strings hashed across
>   5 dump exes, 14 retail `Mercenaries2*.exe` variants, the Xbox prototype PE, `Saboteur.exe`, both
>   Lua corpora, 416 extracted `.luac`, console string tables and `shell/Loading/vz-patch/English`
>   WADs — no match. Exhaustive meet-in-the-middle covering ~9×10¹⁵ candidates: every string ≤8
>   chars over a 37-char alphabet; 97 prefixes × every tail ≤9; 43 prefixes × every tail ≤10. The
>   `waitfor*` family hypothesis (suggested by the `.rdata` link order, which places this vtable
>   between `waitforstreaming` and `waitfortether`) is **exhaustively excluded** for any tail ≤10
>   letters; `m2("waitforingame") = 0xC6E7837C`, and `"waitforgame"` is excluded despite the
>   `STATE_WAITFORGAME` constant in the Lua corpus. `m2` folds case (`c | 0x20`), so case variants
>   cannot be the gap. **Never invent a name for it** ([[no-arbitrary-hashes]]).
> - **Routes left.** The four 2–2.5 GB WADs (compressed; a probe for `WaitForTether` /
>   `RequestGameState` returned 0 hits in each), the Jul 11 2008 prototype ISO, and the **retail
>   Xbox/PS3 executables** — the last are the only live route and are not in this repo. Runtime
>   alternative: HW-write watchpoint (4 bytes) on `DAT_01175C7C`, boot to a level, read `[cur+4]` at
>   each stop; the state is entered immediately before `ingame`, so it is the last hit before
>   `0x57B5E35A`.

### 3.1a A second, *different* state-hash table — `0x00D2AD38` (new, H structure)

Not previously recorded anywhere in `docs/`. `.text` reaches it twice, and the pair is a
**serialise / deserialise** couple:

```asm
; DECODE — FUN_00706760
007067A3  mov   al, byte [eax+0x20]
007067A6  shr   al, 3                       ; a 5-bit state INDEX packed in the top bits of a byte
007067A9  cmp   al, 0x16 ; jbe              ; bound = 22  ⇒ 23 entries
007067B4  mov   edi, dword [ecx*4 + 0xd2ad38]   ; index -> state-name HASH
007067C6  cmp   eax, 0x57b5e35a             ; …then compared against m2("ingame")

; ENCODE — FUN_00706A20
00706A51  and   byte [ebx+0x20], 0xf8       ; clear bits 3..7
00706B44  cmp   ecx, dword [edx*4 + 0xd2ad38]   ; linear scan for the current state's hash
00706B4F  cmp   al, 0x17 ; jb               ; …over the same 23 entries
00706B58  add al,al ×3 ; or cl,al ; mov [ebx+0x20], cl   ; pack index<<3 back into the byte
```

So `0x00D2AD38` is the **wire encoding of the game state**: a 23-entry index→hash table (`[0]` is
zero; **19 non-zero hashes at indices 1–19**), letting the current state ride in 5 bits of a
replication byte. It is *static* — identical in `mercs2_nodrm_v3.exe`. Its order differs from the
20-slot object table, and it **omits `exiting` and `lti_precache`**.

| idx | 1 | 2 | 3 | 4 | 5 | 6 | **7** | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|
| | `pause` | `loading` | `unloadshell` | `unloading` | `waitforplayer` | `waitforstreaming` | **`0x2D70FE6F`** | `shell` | `reset` | `flush` |

| idx | 11 | 12 | **13** | 14 | 15 | 16 | 17 | 18 | 19 |
|---|---|---|---|---|---|---|---|---|---|
| | `ingame` | `cinematic` | **`0x53056C27`** | `waitfortether` | `pda` | `attract` | `connecting` | `lobby` | `online` |

> **⚠ Open: `0x2D70FE6F` is a 21st state hash with no state object.** It is not in the 20-slot
> table, not in `docs/`, and **not named here — do not invent one.** It is not dead, either: it is
> compared as a live immediate at **`0x004C1716`** (`cmp eax, 0x2D70FE6F`) and **`0x006CD39F`**
> (`cmp esi, 0x2D70FE6F`), in both cases inside the same four-member set
> `{ ingame, pause, 0x2D70FE6F, pda }` — a predicate that answers "false" for those four and "true"
> otherwise. So the engine can *be in* a state that the 20-slot table cannot *enter*. Two readings
> fit and neither is settled: a state registered by a build this one didn't ship, or a
> replication-only pseudo-state. See §9.
>
> Reproduce: `u32(0x00D2AD38 + i*4)` for `i` in `0..22`, and `dis(0x004C170F, 0x20)`.

### 3.2 Transitions

```
FUN_004C0F10(hash, ctx…)                        ENTER
    for i in 0..0x17:  s = PTR_PTR_01175C80[i]
        if !s: break
        if s[1] == hash: goto found
    DAT_01175C7C = NULL                          (unknown state ⇒ no current state!)
found:
    DAT_01175C7C = s
    (*s->vt[0x0C])(ctx…)                        init-with-args
    (*s->vt[0x04])()                            enter
    FUN_004C9E70({ 0, s[1], 0x9DA97065 })        broadcast  ← Event.GameStateChange {name,"enter"}

FUN_004C0FA0()                                   EXIT
    (*DAT_01175C7C->vt[0x08])();  broadcast;  DAT_01175C7C = NULL
    (the pump's own exit path does the same with 0xDB41017D)
```

**Both broadcast tags crack, closing what §9.2 used to hold open (H).**
`pandemic_hash_m2("enter") == 0x9DA97065` and `pandemic_hash_m2("exit") == 0xDB41017D`, both
reproduced with `tools/pandemic_hash.py`. Read first-hand: `FUN_004C0F10` builds
`{0, cur->nameHash, 0x9DA97065}` at `0x004C0F6F`–`0x004C0F7B` and calls `FUN_004C9E70`
(`0x004C0F83`); the pump's exit path loads `edi = 0xDB41017D` at `0x004C0A6B` and builds
`{0, cur->nameHash, edi}` at `0x004C0A97`–`0x004C0A9F` into the same function. **The pair *is* the
`{stateName, "enter"|"exit"}` payload** that surfaces in Lua as `Event.GameStateChange` — the
mechanism `MrxState` uses to release `STATE_WAITFORSTREAMING` / `STATE_WAITFORTETHER`
([`mrxstate.lua:28,45`](../mercs2-luacd/src/resident/mrxstate.lua#L28)). The map previously listed
the enter tag as uncracked and did not record the exit tag at all.

Note the failure mode: **an unrecognised state hash leaves `DAT_01175C7C == NULL`** (`0x004C0F38`:
`xor eax,eax; mov [0x1175C7C],eax`; the found path at `0x004C0F8F` is `mov eax,ecx; jmp 0x4C0F3A`).
A null current state makes `Sys.IsLoadingOrStreaming` return false and the pump skip **the state's
own `Update`**. Nothing errors. A typo'd `Sys.RequestGameState` string is a silent
no-current-state.

⚠ Two corrections to what this paragraph used to claim next. (a) It said a null current state makes
"`Pg.UnloadLayer`'s `unloading` guard pass" — on a **client** it does not *pass*, it **crashes**:
that guard dereferences `[DAT_01175C7C]+4` with no null check (§5.2). (b) It said the pump would
"skip its tick" — only the *state's* tick. The per-system pump `FUN_004C9740` still runs (§3.5).

### 3.3 The request queue (H)

`Sys.RequestGameState` does not transition; it **publishes**. `FUN_004BDD10` pushes a **16-byte**
message into a critical-section-guarded 20-slot ring (`DAT_0120F510`/`DAT_0120F518` interleaved,
`DAT_0120F4E8` = count) with an 8-bit **per-subscriber** pending mask (`DAT_0120F650[i]`) and
per-subscriber counters (`DAT_0120F4F0[]`); `FUN_004C9CF0` drains **for one subscriber** and returns
`bytes/16`. The state pump claims a subscriber bit in its init phase (`DAT_0120F4EC`). This is the
concrete PC implementation of the Xbox `SendEvent_*` family; the sibling
[`event_bus_code_map.md`](event_bus_code_map.md) owns the general bus — what is pinned here is that
the **state-change channel is the 16-byte ring**, and that the sibling 208-byte ring
(`FUN_004BDE40`, 256 slots, `DAT_0125D3E0`, stride `0xD0`) is what `Sys.StartSingleplayer` uses for
the level-boot request.

There are in fact **three** structurally identical `EventQueue<T>` instances, all CS-guarded with
the owner TID stashed and a `!= 0` disable flag. The third is new here:

| publisher | slots | stride | storage | count | subscriber mask | per-sub counters |
|---|--:|--:|---|---|---|---|
| `FUN_004BDD10` (state requests) | 20 | `0x10` | `0x0120F510` | `0x0120F4E8` | `0x0120F4EC` | `0x0120F4F0` |
| `FUN_004BDE40` (level boot) | 256 | `0xD0` | `0x0125D3E0` | `0x0125D3B8` | `0x0125D3BC` | `0x0125D3C0` |
| **`FUN_004BDDA0`** | 256 | `0x120` | `0x0124AF98` | `0x0124AF10` | `0x0124AF14` | — |

Two wording corrections to the paragraph above: `DAT_0120F510`/`DAT_0120F518` are **not
"interleaved"** — that is a plain 16-byte-stride array, and `0x0120F518` is slot 0's second half.
And the drain `FUN_004C9CF0` takes the subscriber index **complemented** (`not eax`), which is why
the pump stores `~idx` at `[this+0x0C]` (`lea edi,[ecx+0xc]` @`0x004C0A42`).

### 3.4 `Sys.RequestGameState` `0x005E4AF0` — read in full (H)

```c
int Sys_RequestGameState(lua_State *L) {          // 0x005E4AF0
    if (!hashed_string_arg(1, &want)) { push_nil(); return 1; }   // FUN_0059FB00 → m2 hash
    if (!hashed_string_arg(2, &sub))  sub = 0;
    cur = DAT_01175C7C;
    if (cur) {
        if (cur[1] == 0x20BC86EA /*unloadshell*/ && want == 0x51BFF7B1 /*shell*/)
            { push_true(); return 1; }            // ★ SWALLOWED — returns true, does nothing
        if (cur[1] == 0x7D0B162C /*unloading*/)
            { push_true(); return 1; }            // ★ SWALLOWED — returns true, does nothing
    }
    …debug-name scratch ("unknown" @0x00BAA58C, level -1)…
    msg = { want, <unwritten>, sub, 0 };           // 16 B
    FUN_004BDD10(&msg);                            // publish
    push_true(); return 1;
}
```

Three facts worth carrying forward:

1. **The Lua-visible argument is a string; the engine hashes it immediately.** *(This headline used
   to read "the argument is a hash, not a string" — overstated, and the kind of headline that gets
   quoted without its paragraph.)* `FUN_0059FB00` fetches a `char*` and hashes it with
   `0x00824270`, which is `pandemic_hash_m2` instruction-for-instruction (`or ecx,0x20` @
   `0x00824283`, `imul 0x1000193`, `xor 0x2A` @ `0x00824298`, `imul 0x1000193`). Every corpus call
   site passes a quoted string. The hash is the **internal** representation, not the API surface.
   The consequence the map cared about is unchanged and correct: state names are
   **case-insensitive** by construction (`m2` folds `| 0x20`), which is why the Lua corpus freely
   mixes `"Shell"`/`"shell"` and `"WaitForTether"`/`"waitfortether"`.
2. **Both refusal paths push `true`.** A Lua caller that checks the return
   (`mrxutil.lua:113 local bSuccess = Sys.RequestGameState("waitfortether")`) cannot tell a
   swallowed request from an accepted one. This is a shipped behaviour, and a **fix-pack candidate**
   if a wedge is ever traced to a request issued during `unloading`.
3. **The unwritten dword is word 1, and no consumer reads it — closed statically (H).** Producer:
   `0x005E4BFB` writes word 0 (`[esp+0x18]`), `0x005E4C03` word 2 (`[esp+0x20]`), `0x005E4C07`
   word 3 (`= 0`); `[esp+0x1C]` is never written. `FUN_004BDD10` copies all 16 bytes verbatim, so
   the residue *does* reach the ring. Consumer: in the whole of `FUN_004C09C0`
   (`0x004C09C0`–`0x004C0C20`) the drained message at `[esp+0x20]` is touched at `0x004C0A7D`
   (word 0), `0x004C0AAE` (word 3 → stack arg 2), `0x004C0AB2` (word 2 → stack arg 1) and
   `0x004C0AB6` (word 0 → **register** arg `edx`). **`[esp+0x24]` does not occur.** Corroboration
   that this is a convention, not a slip: state slot 7's `Update` builds the same message shape at
   `0x004BA802`–`0x004BA80E` and also leaves word 1 unwritten. **There is no shipped
   uninitialised-read.** The old guess ("harmless if the consumer only reads words 0 and 2") was
   right about harmlessness and wrong about the shape — the consumer reads words **0, 2 and 3**.

### 3.5 Where the machine sits in the frame — **closed** (H)

This used to be the map's largest open item (old §9.7) and its one hedge against the sibling maps.
It resolves entirely from static data, and the answer **vindicates both drawings**.

```
FUN_00631670  WinMain
  └─ FUN_00630EF0  RunFrame          (loop back-edge: 0x00631A99 je 0x631938)
       └─ FUN_004C14F0  MASTER UPDATE        (called twice, 0x00630FAC / 0x00630FC2)
            └─ FUN_004C15E0  5-layer app-stack stepper over PTR_PTR_017BBCCC[]
                 └─ layer 4 = 0x00D6C244, vtable 0x00BB0460, +0x0C   ← 0x004C163C: mov edx,[eax+0xC]; call edx
                      └─ FUN_004C09C0   ★ GAME-STATE MACHINE PUMP
                             phase 1 (0x004C0BC2): claim a subscriber bit, phase := 2
                             phase 2 (0x004C0A5A): while (FUN_004C9CF0(&msg))   drain requests
                                       if cur && cur[1] != msg.hash: exit(vt+8), broadcast m2("exit"), cur = NULL
                                       FUN_004C0F10(msg…)                        enter
                                   ── tail of phase 2, reached by falling out of the drain loop ──
                             0x004C0AD6  if (bit3 of [[0x1175cdc]+0x40]
                                          && GetForegroundWindow() != [0x117601c]
                                          && [[0x1175fb0]+0x20] != 0)      goto Sleep(100)
                             0x004C0B08  if ([0x1175a94] == 1)             goto Sleep(100)
                             0x004C0B14  if (cur) { (*cur->vt[0x10])(dt);            tick current state
                                                    if cur[1] == m2("ingame") FUN_004C0C70(); }
                             0x004C0B5B  if ([0x1175a94] != 1) { FUN_004C0EC0(dt) ─> FUN_004C9740   ★ per-system pump
                                                                 FUN_004C0CC0(); }
                             phase 3 (0x004C0A0A): exit(FUN_004C0FA0), phase := 4

  ── and, ONCE, at process exit ──
  0x00631AAF  FUN_004C13A0  ─> forces layer 4's phase 2→3, then pumps it with dt = 0.0
```

**The linkage, under a stronger test than the map used to apply.** Counting *both* direct branches
*and* every occurrence of the literal address in **every section** of the image:

| function | direct branches to it | literal-address occurrences image-wide |
|---|--:|---|
| `FUN_004C9740` (per-system pump) | **1** — `call` @`0x004C0ED6` | **0** |
| `FUN_004C0EC0` | **1** — `call` @`0x004C0B6A` | **0** |
| `FUN_004C09C0` (state pump) | 1 — `call` @`0x004C13D8` | **1** — `.rdata:0x00BB046C` |
| `FUN_004C00E0` (singleton install) | **0** | **1** — `.rdata:0x00BB045C` |
| `FUN_004C14F0` | 2 — `0x00630FAC`, `0x00630FC2` | 0 |

Because `FUN_004C0EC0` and `FUN_004C9740` have **zero** literal-address occurrences anywhere, they
cannot be reached indirectly either: their single static caller is their *only* caller.
`0x00BB046C` is `vtable 0x00BB0460 + 0x0C` — **app-stack layer 4's tick slot**.

> ### ✅ "Layer 4 of the master update" is literally app-stack index 4.
> The sibling maps and this map were describing the same edge from two ends. There was never a
> contradiction to reconcile — the missing link was a **virtual call**, which is this map's own
> trap 3 (a missing static edge may be a virtual call). It lands twice in the same stepper: layer 3
> installs the singletons, layer 4 pumps the game states.

**⚠ Two provenance corrections that would otherwise mislead a re-derivation.**

1. **The array `0x017BBCCC[]` is runtime-populated, not statically initialised.** `FUN_004C1170`
   zero-fills it, then writes the five entries (`0x004C11F9`, `…1211`, `…1229`, `…1241`,
   `…1259`) and sets the stage target `[0x017BBCFC] = count-1 = 4`. In `mercs2_nodrm_v3.exe` all
   slots **and** the count read `0x00000000`; the values exist in `mercs2_unpacked.exe` only
   because that artifact is a live memory image. All five layers share `vt+0x04 = 0x004BE070` and
   `vt+0x08 = 0x004BE090` (a shared base-class no-op); only `vt+0x0C` differs.

   | idx | object | vtable | `vt+0x0C` (tick) | what it is |
   |--:|---|---|---|---|
   | 0 | `0x00D6C22C` | `0x00BB0420` | `0x004BEEA0` | — |
   | 1 | `0x014538B8` | `0x00BB0430` | `0x004BEED0` | — |
   | 2 | `0x0149FDA0` | `0x00BB0440` | `0x004BFAF0` | — |
   | **3** | `0x00D6C238` | `0x00BB0450` | **`0x004C00E0`** | the singleton install table |
   | **4** | `0x00D6C244` | `0x00BB0460` | **`0x004C09C0`** | the game-state pump |

2. **`FUN_004C13A0` is the shutdown pump, not a second per-frame entry.** This map used to draw
   `FUN_00631670 → FUN_004C13A0 → FUN_004C09C0` as *the* frame path. Its **only** caller is
   `0x00631AAF`, which sits *after* the main loop's back-edge (`0x00631A99 je 0x631938`) and after
   the handle release at `0x00631AA9`, three instructions before the enclosing `ret`. Its body:
   `cmp dword [0xd6c24c], 2` (that address is layer-4 object `0xD6C244` **+ 8** = its phase);
   `mov dword [0xd6c24c], 3`; `fldz` (dt = 0.0); `mov ecx, 0xd6c244`; `call 0x4c09c0`. It forces
   the same object into its phase-3 branch once, at process exit.

> ### ⚠ State-gating: what actually gates the simulation
>
> **The old claim — "'which game state am I in' gates the simulation itself" — does not survive.**
> At `0x004C0B14` the pump does `mov ecx,[0x1175c7c]; cmp ecx,ebx(=0); je 0x4c0b5b`. A NULL current
> state skips only the *state's own* `Update`; control lands on `0x004C0B5B`, which still reaches
> `call 0x4c0ec0` at `0x004C0B6A` → `FUN_004C9740`. **The simulation runs with no current state at
> all.** §3.2's "a null current state makes … the pump skip its tick" is true of the *state* tick
> and false of the *system* pump.
>
> The three real gates, in the order the pump tests them:
>
> 1. **The app-stack layer's own phase** must be 2 (`[this+8]`; 1 → init, 3 → exit, other → return).
> 2. **The foreground predicate** at `0x004C0AD6` — bit 3 of `[[0x1175cdc]+0x40]` **and**
>    `GetForegroundWindow()` (IAT `0x00B054BC`) `!= [0x117601c]` **and** `[[0x1175fb0]+0x20] != 0`
>    ⇒ `Sleep(100)` (IAT `0x00B0518C`) and skip everything.
> 3. **`[0x01175A94] != 1`** (`cmp` @`0x004C0B08`, re-tested @`0x004C0B5B`). This is **not** a
>    pause/minimise flag: it is a **level-transition / device-reset handshake** between a game state
>    and `RunFrame`. A state writes `1` (`0x004BBD84`) and returns; `FUN_00630EF0` sees `1` at
>    `0x00630F02`, runs `FUN_004C0730`, clears bit 2 of `[[0x1175cdc]+0x40]`, resets `[+0x3C]`, and
>    writes **`2`** at `0x00630F26`; the state polls for `2` at `0x004BBDA0` / `0x004BC909`. Twelve
>    refs total, eight of them writes, all in `FUN_00630EF0` and the loading/unloading state bodies.
>    The simulation is suspended for its duration — which is the *real* content of the old
>    "background throttle" line, and it is a **separate, third** predicate from the foreground one.

### 3.6 The rest of the `Sys` state/boot surface (read first-hand)

| Binding | VA | Body |
|---|---|---|
| `Sys.RequestGameState` | `0x005E4AF0` | §3.4 |
| `Sys.IsLoadingOrStreaming` | `0x005E4D40` | `cur && (cur[1] == m2("loading") \|\| cur[1] == m2("waitforstreaming"))` → bool. **H** |
| `Sys.StartSingleplayer` | `0x005E4C50` | two arg fetches, then `FUN_006B3560(&DAT_01175AB8 /*level*/, &DAT_01175B78 /*master script*/, 2, 1)` → `FUN_004BDE40` (208-B event). **The level→mission boot request.** |
| `Sys.GetLevelName` / `SetLevelName` | `0x005E4FF0` / `0x005E50B0` | global char buffer **`DAT_01175AB8`** |
| `Sys.GetMasterScriptName` / `SetMasterScriptName` | `0x005E5050` / `0x005E5120` | global char buffer **`DAT_01175B78`** |
| `Sys.GetCharacterTemplate` | `0x005E5190` | global char buffer **`DAT_01175C08`** |
| `Sys.FinishedShell` | `0x005E54C0` | bool `DAT_01175A72 != 0` |
| `Sys.AutoLoad` | `0x005E5490` | bool `DAT_01175C5A != 0` |
| `Sys.GetSkipMission` | `0x005E54F0` | `lua_pushstring(DAT_01175B38)` |
| `Sys.SetSkipMission` | `0x005E5510` | **inline unbounded `strcpy` into `DAT_01175B38`** — a hand-rolled byte loop at `0x005E5562`–`0x005E556C` (`mov cl,[eax]; mov [edx+eax],cl; add eax,1; test cl,cl; jne`) with **no length check** — then `DAT_00D002B9 = (buf[0] == 0)` (`sete dl` @`0x005E557E`, stored `0x005E5588`). It also **pushes `nil`** (`mov dword [eax+4], 0` @`0x005E5577`) and returns 1 result. Dev-only, but a real overflow if ever reachable from data. |
| `Sys.ForceNextAutosave` | `0x005E6670` | `*(u8*)([0x01176054] + 0xA86C) = 1` — writes the **profile/economy singleton** owned by [`player_code_map.md`](player_code_map.md) §4 |
| `Sys.RequestAutosave` | `0x005E61F0` | bool + string args, then `strncpy` (IAT `0x00B052EC`) — body read only to the arg block; **M** |
| `Sys.GetVersion` | `0x005E6680` | `DAT_01175C60` clamped to `[100000, 999999]`, pushed as a float |

`Sys.GetSkipMission`/`SetSkipMission` are the PC counterparts of the Xbox `GetSkipMission` /
`SetSkipMission` symbols — the **dev mission-skip** the PDB documents, still live in retail (7 Lua
call sites), and gated only by `DAT_00D002B9`.

---

## 4. `Pg.Contract*` — the whole engine-side contract surface

Three table slots, **two bodies**.

### 4.1 `Pg.ContractActivated(sMissionName)` — `0x005D7DB0` (H, raw disasm)

```asm
005D7DC9  call  0x59FA40                 ; string arg 1  (FUN_0059FA40)
005D7DD0  jge   0x5D7DF7                 ; got one?
          ...                            ; no  -> push nil, return 1
005D7DF7  mov   eax, [0x01176170]        ; the world/session singleton
005D7E00  push  0x3F
005D7E03  add   eax, 0xF149              ; -> the 0x40-byte contract-name field
005D7E09  call  [0x00B052EC]             ; MSVCR80!strncpy(field, arg, 0x3F)
005D7E14  cmp   byte [0x00DFBD78], 0     ; Net.IsServer  (§5.1)
005D7E1C  mov   eax, [0x01176164]
005D7E21  mov   byte [eax+0x5550], 0     ;   clear two co-op flags — ON THE SERVER ONLY
005D7E27  mov   byte [eax+0x5552], 0
005D7E2D  mov   eax, edi                 ; edi = 1 → nresults = 1, and NOTHING WAS PUSHED
```

> ### ⚠ `mov eax, 1` is the **result count**, not `true`
>
> This map used to annotate it `; return true` here and in §4.2, and §10.4 told reimplementers to
> model it that way. `eax` is the `lua_CFunction` **`nresults`**. The boolean-`true` idiom in this
> same binary is explicit — `mov [top],1; mov [top+4],1; add [L+8],8` *then* `mov eax,1` — visible
> at `Pg.AddContextAction 0x005D77FD`–`0x005D780F` and `Sys.RequestGameState 0x005E4C24`. On
> `ContractActivated` the **only** push in the whole function is on the *failure* path
> (`0x005D7DE3`, a `nil`), so the success path declares one result and pushes none, making Lua lift
> whatever already sits at `L->top - 1`.
>
> **Affected: `ContractActivated` (success path), `ContractCompleted`/`Cancelled`, and
> `Pg.ResetSingletonDone` `0x005D4BE0`** (`mov eax,1; mov [0x1175a7d],al; mov [0x1175a7e],al; ret`
> — zero pushes; §5.2's table used to call it "no args, no return"). Retail never bit because every
> corpus call site discards the result (`mrxtaskcontract.lua:99, :120, :275`;
> `shellbootstrap.lua:122`). For contrast, `Sys.ForceNextAutosave` `0x005E6670` gets it right:
> `xor eax,eax; ret` = 0 results.

### 4.2 `Pg.ContractCompleted()` **==** `Pg.ContractCancelled()` — `0x005D7E40` (H)

```asm
005D7E40  mov   eax, [0x01176170]
005D7E47  je    ...                      ; null-guard
005D7E49  push  0x3F
005D7E4B  add   eax, 0xF149
005D7E50  push  0x00BA8B09               ; "" (verified: the byte at 0x00BA8B09 is 0)
005D7E56  call  [0x00B052EC]             ; strncpy(field, "", 0x3F)
005D7E5F  mov   eax, 1                   ; nresults = 1 — and nothing is pushed on ANY path
005D7E64  ret
```

**Both table entries point at the same address.** The engine therefore has *no representation of
success versus failure*. Everything the game does with that distinction —
`MrxTaskContract.Complete` → `Complete1` → `Complete2` (fanfare, ledger, `nCashOverride`) versus
`Cancel` → `Cancel2` (cancel fanfare, `_SetCancelMessage`) — is entirely Lua
([`mrxtaskcontract.lua:120, 275`](../mercs2-luacd/src/resident/mrxtaskcontract.lua#L120)).

### 4.3 The field is write-only (H)

A scan of the whole `.text` section for displacement `0xF149` returns exactly **three** sites:
`0x005D7E03` (activate), `0x005D7E4B` (complete/cancel), and `0x006C8B28` — which is inside the
singleton's zero-init ctor `FUN_006C8A20` (`memset(this + 0xF149, 0, 0x40)`). **There is no
reader.** Practical consequence: **`Pg.Contract*` is a breadcrumb, not a mechanism.** A reimpl may
implement all three as a single string write and lose nothing.

> ### The positive control that turns this from an argument-from-absence into a contrast (H)
>
> This section used to end on speculation — *"the plausible consumer is an out-of-`.text` one: a
> crash/telemetry dump of the singleton, or the SecuROM-virtualised region."* That was unsupported,
> and it was also **unnecessary**: the map's own §4.4 already recorded that the *sibling* field
> `+0xF0E5` in the same struct — same `0x40` size, same `memset` in the same ctor (`0x006C8BCD`),
> same breadcrumb shape — is printed by the debug overlay. The two observations were never
> connected. `+0xF0E5` is read **in `.text`, by direct displacement, at five sites**:
>
> | site | role |
> |---|---|
> | `0x005C3A6F` | `FUN_005C37E0` (the `Net` state publisher) packs it as a type-4 string arg for the Flash variable `player2Name` (`0x00BB72E4`, verified) |
> | `0x00616F4F` | a second packer of the same shape |
> | `0x006C26A3` / `0x006C2704` | the crash-report path; `0x006C26B7` `strncpy`s it into the crash-report global `0x00EDB1D8` |
> | `0x006C3FF2` | debug overlay `_snprintf(buf, 0x7F, "[0x6ad9b549:%s]", …)` |
>
> **Same struct, same shape, five readers — versus three sites and zero readers for `+0xF149`.**
> The engine's idiom for consuming a field of this shape is the direct-displacement form, and
> `+0xF149` simply never got wired. That is stronger evidence for this section's conclusion than
> the speculation was, and it materially de-risks the §9 confirm-live.
>
> *Still not excludable by any static scan:* a wholesale `memcpy` of the struct into a savegame
> blob or minidump. See §9.

This is exactly what the Xbox PDB implies and no more: `ContractActivated` / `ContractCompleted` /
`ContractCancelled` sit in `.rdata` beside a single field name **`sContract`**
([`game-systems.md`](../mercs2-pdb-analysis/game-systems.md)) — one string, not an object.

### 4.4 The singleton `[0x01176170]` — the **online / multiplayer-services** game system (role H)

Installed by `FUN_004C00E0` (the ~30-entry singleton install table, itself app-stack layer 3's
`Update`) as `&PTR_PTR_014CF228`. Reset by `FUN_006C8A20`.

**Master key applied — hard negative.** `[vtable+0x34]` names a container **only if** the target is
literally `B8 <imm32> C3`. Positive controls first, and they work exactly as documented:

| container | vtable | `[vt+0x34]` | body | name |
|---|---|---|---|---|
| `Players` | `0x00BC3FB8` | `0x00647BA0` | `B8 AC 5D BC 00 C3` = `mov eax, 0xBC5DAC; ret` | ✓ `"Players"` |

For `[0x01176170]`: **`[0x00BCFE84 + 0x34] = 0x00848E30`, whose entire body is `C2 04 00 = ret 4`**
— the class's shared do-nothing slot (it also fills `+0x30`, `+0x40`, `+0x48`…`+0x50`, `+0x94`,
`+0x98`, `+0xA8`…`+0xB4`, `+0xBC`, `+0xC0`, `+0xDC`…`+0x104`). A sweep of all 74 slots finds no
`mov eax,<char*>; ret` name-getter anywhere.

> **This object is not an ECS container.** The master key is genuinely inapplicable, not merely
> untried. RTTI is also dead: `[vtable-4] = 0x005D7325`, a `.text` address, not an
> `RTTICompleteObjectLocator` — and the Xbox side has no Pangea RTTI either
> (`mercs2_xenon_p.rtti_classes.txt` is 324 entries, **all Havok**).

**What it is, on five converging lines.** (1) It is a `PgSys*` game system — vtable `+0x0C`
(`0x006C8CD0`) is `Init`, which calls `FUN_006C8A20` as a *reset* and stores
`[this+0x14C] = FUN_0060CF90()`, already identified in `docs/data/keystone_code_map.json:202` as the
**"PgSys 32-slot ID allocator"**; `+0x10` (`0x006C8D80`) is `Shutdown` and releases it via
`FUN_0060CFC0`. (2) `Init` allocates a `0x7450`-byte **EA online/FESL SDK** object into
`[this+0x144]`, computes the FESL B-version, and installs `this+0x1C` as the SDK's callback
listener — `networking_code_map.md:153` already calls `FUN_006C8CD0` "FESL version compute" without
realising it is this object's `Init`. (3) Its `.rdata` string pool immediately before the vtable
(`0x00BCFCC4`–`0x00BCFE78`) is entirely online/lobby: `connectingToGame`, `hostingDialog`,
`quickMatchNotAvailableInLan`, `optiMatchNotSignedInToLive`, `addLeaderboardEntry`,
`onlineLobbyNotSignedInToLive`, `serverCreationErrorPlayOffline`, `optimatch`, `ViewEATerms`. (4)
`output/jul08_prototype/pairing/string_func_map.json` puts those strings **inside this vtable's own
slots** (`hostingDialog` → `FUN_006C98B0` = `+0x3C`; `optiMatchNot*` → `FUN_006C9F50` = `+0xA0`).
(5) `mercs2_xenon_p.pe_full_strings.txt` carries 16 `PgSysNet*` labels; fifteen are replication
categories that map 1:1 onto the PC category vocabulary at `0x00BD0590+`, and the sixteenth —
**`PgSysNetOnline`** — is the only online-services one and is unmatched in that list.

> ### Verdict: `[0x01176170]` is the **online / multiplayer-services Pangea game system**, Xbox
> label **`PgSysNetOnline`**. Role **H**; the literal label *string* stays **open** (the PC release
> build strips all `PgSys*` labels). Residual alternative `PgSysNetworking` is argued against:
> the transport/peer-mesh layer lives at `0x009Cxxxx` / `0x0084xxxx`.

**Field map** (✓ = verified first-hand this pass):

| offset | meaning | evidence |
|---|---|---|
| `+0x00 / +0x14 / +0x18 / +0x1C` | **four** vtables, not one: `0x00BCFE84` (74 slots) / `0x00BCFEB0` / `0x00BCFFB0` / `0x00BD0040` | `FUN_006C8C60` writes all four at `0x006C8C78`–`0x006C8C96`; the `+0x1C` sub-object is the EA SDK listener |
| `+0x144` / `+0x148` / `+0x14C` | EA online SDK object / registrar handle / **PgSys slot id** | `Init 0x006C8CD0` |
| `+0x154` | gate for "play offline" level start | `Net.DialogBoxPlayOffline 0x005CAD90` |
| **`+0x158`** | **multiplayer session valid** | ✓ `0x005C3A98` (with `Net.IsServer` → Flash `multiplayerHost`) / `0x005C3ADD` (with `Net.IsClient` → Flash `multiplayerClient`) |
| **`+0x1C8`** | `0x100` × `0xD8` **game / server-browser list** (3 × `0x40`-B names + `0x18` of scalars) | ✓ ctor — see the correction below |
| `+0xD9C8` | `0x98`-byte session descriptor | matches the `AddOptimatchResult` emitter `0x006CB930` |
| `+0xDA64` | bool forcing event publication | `0x004BA349`, `0x004BA986`, `0x004BD677` |
| **`+0xF0E5`** | **`player2Name` — the co-op partner's name**, `0x40` B | ✓ `0x005C3A5E`–`0x005C3A76` pushes `[0x1176170]+0xF0E5` as a type-4 string arg for Flash var `0x00BB72E4`, verified to be the literal `"player2Name"` |
| `+0xF148` | byte set to 1 at four sites | ctor |
| `+0xF149` | `sContract`, `0x40` B | §4.3 |
| size | **`0xF190`** (fields to `0xF18C`) | the next static singleton `[0x01176140] = 0x014DE3B8` is exactly `0xF190` above `0x014CF228` |

> ### ⚠ Two corrections this section used to carry
>
> **The record array's base is `+0x1C8`, not `+0x208`.** The ctor does
> `lea edi,[esi+0x208]` (`0x006C8B51`), `mov ebp, 0x100` (`0x006C8B57`), then
> `memset(edi-0x40, 0, 0x40)` at `0x006C8B60` — **`edi-0x40` is the record base**, and `+0x208` is
> merely the *second* name buffer of record 0. Arithmetic proof: `0x1C8 + 0x100*0xD8 = 0xD9C8`, and
> the very next field the ctor touches is `lea eax,[esi+0xDA65]` (`0x006C8BBE`) for a `0x1680`-byte
> block that ends exactly at `+0xF0E5`. Count (`0x100`) and stride (`0xD8`) were right; the base was
> off by `-0x40`.
>
> **`+0xF0E5` is `player2Name`, not a "name string" of unknown kind.** And the debug tag is not a
> class name: the *generic* format `"[0x%08x:%s]"` sits at `0x00BCFE78`, so `"[0x6ad9b549:%s]"` at
> `0x00BCF438` is a constant-folded `[tag:value]` debug line whose `%s` is `player2Name`. That is
> why `0x6AD9B549` resisted cracking — and why it never mattered.

**This makes the write-only finding sharper, not weaker.** `sContract` lives inside the *online
services* system, in the same struct as a server-browser record type that itself carries
name / map / contract fields. `Pg.ContractActivated` writing there, on a struct whose neighbouring
fields are all published to peers and to the crash reporter, reads as **a lobby / server-browser
advertisement that was never wired up on PC** — exactly consistent with
`ContractCompleted == ContractCancelled` and with there being no reader.

---

## 5. Layers — how a mission binds to the world

This is the only part of mission flow the engine really implements, and it is the part that breaks
loudly ([[patch-wad-dangling-lod-rungs]], [[worldload-hang-pending-node-status]]).

### 5.1 `Pg.LoadLayer` `0x005D4C80` (H)

Lua signature, from `mrxlayermanager.lua:224`:

```lua
Pg.LoadLayer(sLayerName, not bStatic, _LayerStatusChange, tCallbackData, bClientNeedsLoadingScreen)
```

Body, in order:

1. `FUN_0059FB00` → **hashed** layer name (arg 1). No arg ⇒ push nil, return.
2. `FUN_0059F6D0` → bool arg 2 (`not bStatic`). **Gate:** if `DAT_00DFBD77` is set **and** arg 2 is
   true, the whole body is skipped and the cfunc returns **0 values** (`nil` in Lua) — a
   *dynamic* layer load is refused in that role.
3. arg 3/4 (callback + data) are shifted down the Lua stack; arg 5 read via `FUN_0059F6D0`.
4. If `DAT_00DFBD78` is set and arg 2: `FUN_006C7390(nameHash, arg5)` — **replicate the load**.

> ### The `DAT_00DFBD77` / `DAT_00DFBD78` pair — **named, statically, H**
>
> This note used to guess: *"`77` = remote/client-ish role, `78` = a session is networked"*, mark
> the names **M**, and defer to a live capture. **All three readings across the project's maps were
> wrong.** The engine names both bytes itself:
>
> | VA | binding | body | meaning |
> |---|---|---|---|
> | `0x005C6710` | `Net.IsEnabled` | `mov bl, byte [0xdfbd74]` | **a session exists** — the meaning this map assigned to `78` |
> | `0x005C6750` | `Net.IsActive` | `mov bl, byte [0xdfbd75]` | — |
> | `0x005C6790` | `Net.IsLobby` | `mov bl, byte [0xdfbd76]` | `sessionMode == 4` |
> | **`0x005C67D0`** | **`Net.IsClient`** | `mov bl, byte [0xdfbd77]` | **`sessionMode == 1`** |
> | **`0x005C6810`** | **`Net.IsServer`** | `mov bl, byte [0xdfbd78]` | **`sessionMode == 2`** |
>
> **Neither byte is ever written through its own address.** A raw byte-pattern search across *every*
> section of *both* `mercs2_unpacked.exe` and `mercs2_nodrm_v3.exe` (`.text`, `.rdata`, `.data`,
> `Stext`…`.securom`, `.rsrc`) for every store-to-absolute-m8 encoding — `C6 05`, all eight `88 xx`,
> `80 0D/25/35`, `FE 05/0D`, all sixteen `0F 9x 05` — returns **zero hits** for either address,
> against 152 and 183 raw 4-byte occurrences respectively. Every reference is `80 3D`/`38 xx`
> (`cmp`) or `8A xx` (`mov reg8, m8`).
>
> The real writer is a **24-byte snapshot republished every tick** by `FUN_006CECF0`, which one-hot
> decodes a single session-mode enum `[session+0x0C]`: `cmp eax,4; sete → 0xDFBD76`;
> `cmp eax,1; sete → 0xDFBD77`; `cmp eax,2; sete → 0xDFBD78`; then publishes bytes `0x00DFBD74`–
> `0x00DFBD8B` with three `movq`s at `0x006CEEBA` / `0x006CEEC8` / `0x006CEED0`. **The three are
> mutually exclusive by construction** — a fact no prior reading captured.
>
> Second, orthogonal fingerprint: at `0x005C3A98`–`0x005C3AEF` the engine drives two Flash variables
> whose names are `.rdata` literals — `+0x158 && [0xdfbd78]` → `0x00BB72F0 = "multiplayerHost"`;
> `+0x158 && [0xdfbd77]` → `0x00BB7300 = "multiplayerClient"`. Both verified. Two can't-coincide
> lines agreeing.
>
> **Every gate in this map re-reads more sharply.** `Pg.LoadLayer` `0x005D4CF7`:
> *a client refuses to load a dynamic layer locally* and waits for replication. `Pg.LoadLayer`
> step 4 (`0x005D4ED4`): *the server replicates the load.* `Pg.UnloadLayer` `0x005D4E49`: *a client
> may only unload during teardown.* `Pg.ContractActivated` `0x005D7E14`: the two byte-clears fire
> **only on the server**. And all eleven `Net.SendEvent_*Objective*` senders gate on
> `IsEnabled && IsServer` — see §6.1.
>
> [`player_code_map.md`](player_code_map.md) has already withdrawn its shutdown/teardown gloss
> (`:497` now records the same two names), so the cross-map disagreement this note used to flag no
> longer exists. §9.10 is closed.
5. `lua_pushstring("layer")` (`s_layer_00BB9034`) + `thunk_FUN_02EF0000` — the async request is
   issued through the SecuROM-adjacent streamer; `thunk_FUN_024E6580(L, 0)` returns the success bool
   that is pushed to Lua.
6. On success: `local_c = 0xE6B81A54` (**`= m2("layer")`, cracked**) → `FUN_0045E440()` returns the
   layer record → `rec[0x18] |= 1` if arg 2 (dynamic), else `rec[0x18] |= 4`.

**The flag bits are the whole static/dynamic model:**

| bit | set when | meaning | who reads it |
|---|---|---|---|
| `rec+0x18 & 1` | `LoadLayer(name, true, …)` | **dynamic** — script-owned, unloadable | `Pg.UnloadLayer`'s guard |
| `rec+0x18 & 4` | `LoadLayer(name, false, …)` | **static** — level-owned | `Pg.IsStaticLayer` |

### 5.2 `Pg.UnloadLayer` `0x005D4E40` — the guard that matters (H)

```c
if (Net.IsClient && cur_state != m2("unloading")) return 0;   // 0 Lua values; §5.1
name = hashed_arg(1);
if (Net.IsServer) thunk_FUN_028B4000(name);                                  // replicate
rec = FUN_0045E440(m2("layer"), name);
if (rec) {
    if (!DAT_01175F58 && !(rec[0x18] & 1))
        { push_nil(); return 1; }      // ★ FUN_004B2A50 — static layer refused, SILENTLY
    lua_pushstring("layer");  return thunk_FUN_024EA380(L);
}
push_nil(); return 1;                  // unknown layer: also nil
```

Verified at `0x005D4F37`–`0x005D4F55`:

```asm
005D4F37  cmp   byte [0x1175f58], 0
005D4F3E  jne   0x5d4f56            ; UnloadingStaticLayers set -> delegate
005D4F40  test  byte [eax+0x18], 1
005D4F44  jne   0x5d4f56            ; bit 0 (dynamic) set        -> delegate
005D4F46  lea   esi, [esp+0x10]
005D4F4A  call  0x4b2a50            ; push nil; return 1         -> refusal
005D4F55  ret
```

> ⚠ **Corrected.** This block used to read `return luaL_error(L)`. It does not — see the §0 box for
> the full body of `FUN_004B2A50`. **Both branches produce `nil`;** the old comment "unknown layer:
> nil, *not an error*" implied a contrast that does not exist. A caller doing
> `if not Pg.UnloadLayer(x) then` cannot tell "no such layer" from "refused because static".
>
> **The `push "layer"; call 0x0085D9F0; call 0x005A0330` sequence at `0x005D4F66` is *not* an error
> raise** either, in case it looks like one: the identical three-instruction sequence appears in
> `Pg.LoadLayer` at `0x005D4DB1` and `Pg.ReloadLayer` at `0x005D5077`, each time immediately before
> the real work. `0x005A0330` has exactly **3 callers, all three of them these layer functions** —
> an error raiser would be called from everywhere. It is the generic
> `LoadAsset`/`UnloadAsset`/`ReloadAsset` delegation, pushing the literal type name `"layer"`.

> ### 🐞 A reachable NULL-deref on a co-op client (fix-pack candidate)
>
> The head gate is `cmp byte [0xdfbd77], 0; je 0x5d4e6c` (`0x005D4E49`) followed **immediately** by
> `mov eax, [0x1175c7c]; cmp dword [eax+4], 0x7d0b162c` (`0x005D4E55`) — **with no null check on
> `eax`**. §3.2 proves an unrecognised `Sys.RequestGameState` string leaves `DAT_01175C7C == NULL`.
> So a **client** calling `Pg.UnloadLayer` while no game state is current dereferences `NULL+4`.
> Reachable, not theoretical. Belongs in `docs/fixpack/bug_register.md`.

`DAT_01175F58` is the **"we are tearing down static layers"** override, and it is script-settable:

| Binding | VA | Body |
|---|---|---|
| `Pg.UnloadingStaticLayers(b)` | `0x005D4B50` | `FUN_0059F6D0(&DAT_01175F58)` — writes the flag; pushes nil if no arg |
| `Pg.GetUnloadingStaticLayers()` | `0x005D4BA0` | pushes `DAT_01175F58 != 0` |
| `Pg.IsStaticLayer(name)` | `0x005D4BF0` | if `DAT_01175F58` is set it **returns 0 values** (`nil` in Lua) — *not* `false`; otherwise `rec = FUN_0045E3F0(name)` and pushes `rec && (rec[0x18] & 4)` via `FUN_004B86E0` (the shared push-bool helper) |
| `Pg.ResetSingletonDone()` | `0x005D4BE0` | 4 instructions: `mov eax,1; mov [0x1175a7d],al; mov [0x1175a7e],al; ret`. No args. ⚠ **it declares 1 result and pushes nothing** — not "no return" as this row used to say (§4.1 box). Called from `shellbootstrap.lua:122`. |
| `Pg.LoadingStaticLayers` / `GetLoadingStaticLayers` | `0x006D5640` | **the `return-0` stub** — the load-side twins of `UnloadingStaticLayers` were cut. `mrxlayermanager` calls them anyway (3 sites) and gets nothing. |

`Pg.ReloadLayer` `0x005D4F90` is the third arm and shares the `FUN_0045E440` + `m2("layer")` shape.

### 5.3 What this means for missions

`MrxMissionFlow.UnlockMission` computes a mission's layers as
**`"Vz_State_" .. sMissionName`** ([`mrxmissionflow.lua:249`](../mercs2-luacd/src/resident/mrxmissionflow.lua#L249)),
and mission scripts add per-phase overlays named `Vz_State_<Mission>_<Phase>` (Pristine / Staging /
Defenses / Captured / Destroyed) via `MrxLayerManager.Add/Remove/MarkForRemoval`
([`03_contracts_jobs.md`](../mercs2-luacd/03_contracts_jobs.md) §1.1). Every one of those goes
through `Pg.LoadLayer(name, true, …)` — **dynamic**, bit 0 — which is precisely why they can be
unloaded at mission end while the level's own static layers cannot. `MrxLayerManager` also
throttles: `_knLayersToProcessCap` in-flight, and it raises/restores `Sys.SetAssetRequestMax` around
a batch ([`mrxlayermanager.lua:203-218`](../mercs2-luacd/src/resident/mrxlayermanager.lua#L203)).

> The engine's own reply channel is the Lua callback `_LayerStatusChange(sRequestType, sLayerName,
> sLayerType, bSuccess)` — `sLayerType` is the `"layer"` string the cfunc pushes at step 5.

---

## 6. Objectives, context actions, and the report system

### 6.1 Objective tracking is **not** in the engine (H)

`Gui.AddObjective` (`Gui` table `0x00B9A398`, slot 0) is **`0x006D5640`** — the shared `return-0`
stub. There is no `Objective` namespace in the 31-row registry.

> ### ⚠ Corrected — the objective `SendEvent_*` family is **not** devkit-only
>
> This section used to say the Xbox PDB's objective inventory "is a **devkit-build surface that
> retail PC does not expose to script**." **The retail `Net` table falsifies that.** Own walk of
> `0x00B998D0` (92 entries, exactly 2 stubs):
>
> | slot | binding | VA | |
> |--:|---|---|---|
> | 29 | `SendEvent_AddObjective` | `0x006D5640` | **STUB** |
> | 30 | `SendEvent_RemoveObjective` | `0x006D5640` | **STUB** |
> | 31 | `SendEvent_AddRadarObjective` | `0x005C7150` | real |
> | 32 | `SendEvent_RemoveRadarObjective` | `0x005C79F0` | real |
> | 33 | `SendEvent_AddMarkerObjective` | `0x005C74B0` | real |
> | 34 | `SendEvent_RemoveMarkerObjective` | `0x005C7BA0` | real |
> | 35 | `SendEvent_AddPdaObjective` | `0x005C77E0` | real |
> | 36 | `SendEvent_RemovePdaObjective` | `0x005C7AC0` | real |
> | 42 | `SendEvent_ObjectiveMessage` | `0x005C8530` | real |
> | 49 | `SendEvent_SetObjectiveTraySlotText` | `0x005C8A90` | real |
> | 50 | `SendEvent_SetObjectiveTraySlotImage` | `0x005C8C20` | real |
> | 51 | `SendEvent_ClearObjectiveTraySlot` | `0x005C8DF0` | real |
>
> **Ten real, two stubbed — and the two stubbed are exactly the *generic* pair.** The accurate
> statement: *the **abstract** objective was cut (`Gui.AddObjective` plus the two generic
> `Net.SendEvent_*Objective` rows are the shared `return-0` stub); the concrete radar / marker /
> PDA / tray objective replication survives in full, including its co-op senders.* The surrounding
> analysis — that there is no engine-side objective **data model** — is unaffected and correct.

> ### 🐞 …and that settles the suspected co-op desync (H)
>
> All eleven real senders open with the same pair. `SendEvent_AddMarkerObjective` `0x005C74B0`:
>
> ```asm
> 005C74B3  cmp byte [0xdfbd74], 0   ; Net.IsEnabled
> 005C74C3  je  0x5c779e             ;   -> early out, do nothing
> 005C74C9  cmp byte [0xdfbd78], 0   ; Net.IsServer
> 005C74D0  je  0x5c779e             ;   -> early out, do nothing
> ```
>
> Combined with §5.1: on a **client**, `Pg.LoadLayer(name, true, …)` is refused outright *and* every
> `Net.SendEvent_*Objective*` is a no-op. A co-op client receives mission layers and objective
> markers **only** by replication from the server. **The single point of failure is `Net.IsServer`,
> and both refusals are silent** — `return 0 values` and an early `ret` respectively, consistent
> with the `FUN_004B2A50` correction in §0. If the wrong peer runs mission Lua it loads no layers,
> emits no objective events, and nothing errors.

What retail PC gives Lua instead:

| Path | Bindings |
|---|---|
| world markers / blips | `Gui._MarkerAdd` `0x005B3300`, `_MarkerAddBlip`/`AddTripwire` `0x005B36C0`, `_MarkerAddDisc` `0x005B38D0`, `_MarkerAdd3D` `0x005B3AE0`, `_MarkerSetLocation/Color/FollowGuid/Scale/Pulse` — aliased into `_G.Marker.*` by the `Gui` row's post-register chunk (§1) |
| minimap objectives | `_GuiInternal.MinimapAddObjective` `0x005B96E0`, `MinimapRemoveObjective` `0x005BA360`, `MinimapAnimateObjective{Size,Alpha,Sonar}` `0x005B9A10/9C80/9E90`, `MinimapUnanimateObjective` `0x005BA1E0` |
| PDA | `_GuiInternal.RegisterForPdaUpdate` `0x005BC730`, `AddPdaMapBlips` `0x005BCE70`, `UpdatePdaBlip` `0x005BCF90`, `RemovePdaBlip` `0x005BD0C0`, `SetPlayerPDAWidget` `0x005BA500` |
| the objective **tray** | pure Lua + Scaleform — [`mrxguihudobjectivetray.lua`](../mercs2-luacd/src/resident/mrxguihudobjectivetray.lua), 3 slots, widgets |

So an "objective" in Mercenaries 2 is a **`MrxTaskObjective` Lua node** that owns a marker handle, a
minimap entry, a PDA line and a tray widget, and whose completion test is a Lua `Event.*`
subscription. The engine never learns what an objective is.

### 6.2 `Pg.AddContextAction` `0x005D7630` → `FUN_004B2C60` (H)

The interaction primitive missions build "talk to X" / "use Y" objectives on
(`MrxTaskObjectiveAction`, `MrxTaskObjectiveAccept`, `MrxTaskObjectiveRelease`; 27 script sites,
32 for `RemoveContextAction`).

Argument order read from the cfunc: `(uGuid, sLabel, nA, nB, nC, nD, sActionName = "default",
bReplicate = true)`. Two details:

- The action-name default is the constant **`0xBA71C11C` = `m2("default")`** (cracked) — i.e. the
  action name is another hashed string, not a display string. `sLabel` is the *display* text and is
  a stringdb token in practice (`"[ContextAction.UseAlarm]"`, `"[ContextAction.Toolbox]"`).
- `FUN_004B2C60` copies the label into a **128-byte** stack buffer, calls `FUN_00532DE0(guid)`, and
  then — only if the replicate flag is set **and** `DAT_00DFBD78` (**`Net.IsServer`**, §5.1) —
  forwards to `FUN_007007C0(PTR_PTR_011761A0, …)`, skipping the forward for guids whose high nibble
  is `4` when a local-player check fails. That is the **co-op context-action replication** path.

> ⚠ **Corrected: the return contract is `true` / `nil`, and it never raises.** This bullet used to
> end *"`Pg.AddContextAction` raises a Lua error (`FUN_004B2A50`) when it returns false"*. Read
> `0x005D77CB`–`0x005D7818`:
>
> ```asm
> 005D77CB  call 0x4b2c60            ; FUN_004B2C60
> 005D77D0  test al, al
> 005D77D3  jne  0x5d77e5
> 005D77D9  call 0x4b2a50            ; FAILURE -> push nil, 1 result
> 005D77E4  ret
> 005D77E5  mov eax,1 ; call 0x85d5d0        ; lua_checkstack
> 005D77FD  mov dword [eax],   1
> 005D7803  mov dword [eax+4], 1     ; tt = LUA_TBOOLEAN, value = 1
> 005D780A  add dword [ebp+8], 8
> 005D780F  mov eax, 1               ; SUCCESS -> boolean true
> ```
>
> `FUN_004B2A50` is the push-`nil` helper, not `luaL_error` (§0). Note this is also the canonical
> **boolean-`true`** idiom, and the contrast that proves §4.1's `mov eax,1`-without-a-push reading.
> `Pg.RemoveContextAction` `0x005D7820` has the same shape: 2 Lua pushes and three `ret` sites all
> with `eax = esi`, i.e. the same `true`/`nil` contract, and it does not raise either.

### 6.3 `Report.*` is faction infractions, not mission reporting — recorded so it isn't misread

The `Report` namespace (`0x00B98F64`, 5 cfuncs) reads as mission-adjacent and is not.
`Report.GetInfractions` `0x005E0720` builds a Lua table keyed by the string literals
**`DamagePerson` / `DestroyPerson` / `DamageObject` / `DestroyObject` / `Hijack` / `Trespassing` /
`SpecialEvent`**, and every one of its 8 Lua call sites is in
[`mrxfactionmanager.lua`](../mercs2-luacd/src/resident/mrxfactionmanager.lua). `Report.Completed(uGuid)`
means *an NPC finished reporting you*, not *a contract completed*. It belongs to
[`faction_reputation_code_map.md`](faction_reputation_code_map.md). Its singleton is
`PTR_PTR_01175E54`, **not** the `[0x01176170]` that holds `sContract`.

### 6.4 Save / retry hooks the mission flow uses

| Binding | VA | Body |
|---|---|---|
| `Pg.SaveGame(sSlot)` | `0x005D7CB0` | `FUN_005A4050([0x01175F30], sSlot)` → bool |
| `Pg.LoadGame(sSlot)` | `0x005D7D30` | `FUN_005A4520([0x01175F30], sSlot)` → bool |
| `Pg.LoadIsRetry()` | `0x005D7E70` | `[0x01175F30] + 0xC3D != 0` → bool. 10 script sites; `mrxpmc.lua:536` and `mrxstatsmanager.lua:108` branch on it. |

`[0x01175F30]` is the save manager. `MrxTaskContract.Activated` takes a checkpoint save, and
`Pg.LoadIsRetry` is how the reloaded mission knows it is a retry rather than a fresh unlock.

> ⚠ **Two attribution errors corrected here.** (1) This paragraph used to say `[0x01175F30]` is
> "owned by [`save_serialize_code_map.md`](save_serialize_code_map.md)". It is not:
> `rg '0x?0?1175F30' docs/reverse_engineer/save_serialize_code_map.md` returns **zero hits**. That
> map owns `[0x01176054]`, the `.profile` singleton. The save-manager singleton is currently
> **unowned** across the corpus; it is pinned here provisionally, and the boundary table at the top
> of this file has been fixed. (2) "`+0xC3D` (the retry flag) is **new here**" was **wrong** —
> `save_serialize_code_map.md:143-144` already prints the **writer**
> (`_stricmp(param_2, "retry" @0x00BB4604); *(bool*)(param_1+0xc3d) = iVar5 == 0;`), which is
> strictly stronger than this map's reader-side read. Bonus, and a testable bridge neither map has
> drawn: that writer is `FUN_005A4520`, the same body this map ascribes to `Pg.LoadGame`, so
> `param_1 == [0x01175F30]`.

---

## 7. The Lua layer above it (cited, not re-derived)

The mission framework is **already fully mapped** in
[`docs/mercs2-luacd/02_mission_task_framework.md`](../mercs2-luacd/02_mission_task_framework.md)
(426 lines: `MrxState` gate, the `MrxTask` tree and its 4-state lifecycle, the whole
`MrxTaskContract`/`MrxTaskJob`/`MrxTaskObjective*` class hierarchy, `MrxMissionFlow`'s
unlock→accept→activate→objectives→complete→reward chain, `MrxRewardData`) and
[`03_contracts_jobs.md`](../mercs2-luacd/03_contracts_jobs.md) (the 74 per-mission scripts and their
hook contract). **That is not repeated here.** What this map adds is the engine anchor under each
step (★ = pinned by this map):

```
MrxMissionFlow.UnlockMission(sMissionName, tSaveData, …)
    tMissionConfig.tLayers = { "Vz_State_"..sMissionName }
    container:Activate()
      MrxTask.LoadAssets → MrxLayerManager.Add(sLayer, bStatic=false)
          ★ Pg.LoadLayer(name, true, cb, data, bClientLoadScreen)   0x005D4C80  → rec[0x18] |= 1
MrxMissionFlow._OnBriefingComplete
    MrxState.Enter(STATE_WAITFORSTREAMING, oMission.Activate, …)
        ★ Sys.RequestGameState("WaitForStreaming")                  0x005E4AF0  → m2 0x7E289119
        Event.Create(Event.GameStateChange, {"WaitForStreaming","exit"}, …)
                                            ↑ ★ FUN_004C0F10's broadcast, tag 0x9DA97065
MrxTaskContract.Activated(self)
    MrxPlayState.Set(_knMission)            (Lua only — engine has no play state)
    ★ Pg.ContractActivated(sMissionName)                            0x005D7DB0  → strncpy breadcrumb
    MrxMusic…, checkpoint save                ★ Pg.SaveGame          0x005D7CB0
objective chain
    self:CreateChild{ sModuleName = "MrxTaskObjectiveDestroy", … }
    ★ Pg.AddContextAction / Gui._MarkerAdd / _GuiInternal.MinimapAddObjective   (no engine objective)
MrxTaskContract.Complete → Complete1 → Complete2      ★ Pg.ContractCompleted   0x005D7E40
MrxTaskContract.Cancel   → Cancel2                    ★ Pg.ContractCancelled   0x005D7E40  ← SAME BODY
Cleanup
    MrxLayerManager.MarkForRemoval           ★ Pg.UnloadLayer       0x005D4E40  (needs rec[0x18]&1)
```

Corpus shape: **52 `*con###.lua` faction-contract scripts** plus jobs/outposts under
`docs/mercs2-luacd/src/vz/` (114 files), against **23 `MrxTask*` framework modules** under
`src/resident/` (this said "~30"; `ls docs/mercs2-luacd/src/resident/ | grep -ci '^mrxtask'` = 23).

> ⚠ **§2 and §7 are computed over different corpora.** §2's traffic numbers include
> `docs/mercs2-dlc-luacd/src/**` (see the Sources note); this section does not. The DLC adds **9
> `dlccon*` contract scripts** and a **second** flow module, `dlc01missionflow.lua`, neither of
> which is analysed here. Relevant asymmetry: DLC missions call `Pg.Contract*` **zero** times but
> account for **4 of the 6** `Pg.UnloadingStaticLayers` calls.

There is no `mrxcontract*` or `mrxmission*.lua` other than
`mrxmissionflow.lua` / `mrxmissionboundary.lua` — the naming the task brief anticipated does not
exist; the base classes are `mrxtaskcontract.lua`, `mrxtaskmission.lua`, `mrxtaskjob.lua`.
Mission *data* is `src/vz/wifmissiondata.lua` + `wifmissionflow.lua` + `wifstarterdata.lua`.

---

## 8. Two-name/one-body aliases and stubs — the reimpl gotcha list

| Pair | Shared VA | Consequence |
|---|---|---|
| `Pg.ContractCompleted` / `Pg.ContractCancelled` | `0x005D7E40` | engine cannot distinguish win from loss |
| `Pg.FastCollectGroundVehiclesExceptTanks` / `Pg.FastCollectCars` | `0x005D3F10` | "except tanks" is literally "cars" |
| `Junk.IsInstallable` / `Sys.NoHud` | `0x005C0340` | both return a **constant `false`** (§2.1) — `mrxguishell.lua:322`'s install-to-HDD branch is permanently dead code |
| `Pg.LoadingStaticLayers`, `Pg.GetLoadingStaticLayers` | `0x006D5640` | cut; the Lua layer manager still calls them |
| `Gui.AddObjective`, `Net.SendEvent_Add/RemoveObjective` | `0x006D5640` | cut — but **only the generic ones**; the 10 concrete `Net.SendEvent_*Objective*` senders are real (§6.1) |
| 15 of 24 `Junk.*` | `0x006D5640` | the dev-command graveyard |

> ### ⚠ Provenance warning on `0x006D5640` — the designated source image is corrupt there
>
> In `mercs2_unpacked.exe` (and `image.bin`) the bytes at `0x006D5640` are `E9 7B CA 5F 6F` =
> `jmp 0x6FCD20C0`, a target **outside the image** — a `pmc_bb.dll` runtime hot-patch captured in
> the memory dump. Ghidra never decompiled it; `FUN_006D5640` appears nowhere in the 42,601-fn
> export. **The true retail body is `33 C0 C3` = `xor eax,eax; ret`**, readable in
> `mercs2_nodrm_v2.exe` and `mercs2_nodrm_v3.exe`. The "shared `return-0` stub" characterisation
> (inherited from [`scripting_host_binding_code_map.md`](scripting_host_binding_code_map.md)) is
> right; the *body* is unreadable in the image both maps cite as their source.
>
> **Exactly three `.text` bytes runs differ** between the dump and `mercs2_nodrm_v3.exe`, all 5-byte
> `E9` jumps to `0x6Fxxxxxx` — so the hook set is bounded, not open-ended:
>
> | VA | dump | nodrm_v3 | what it is |
> |---|---|---|---|
> | `0x005E9DE0` | `E9 1B 7C 6A 6F` | `55 8B EC 83 E4 …` | `VO.Cue` (pmc_bb VO logging) |
> | `0x005E9F40` | `E9 7B 7A 6A 6F` | `55 8B EC 83 E4 …` | `VO.CueWithoutSubtitles` |
> | `0x006D5640` | `E9 7B CA 5F 6F` | `33 C0 C3` | the shared `return-0` stub — **in this map's slice** |
>
> The stub backs **61** of the 1,103 cfunc rows across all 31 namespaces.

---

## 9. Open questions / confirm-live inventory

Read-only while **PAUSED**; the USER drives execution ([[x32dbg-mcp-no-resume]]); never put a
conditional breakpoint on a per-frame function ([[x32dbg-mcp-pitfalls]]) — `FUN_004C09C0` and
`FUN_004C9740` are per-frame. Prefer one-shot breakpoints and HW-write watchpoints.

**Closed since the first pass** (do not re-open these; the evidence is in the section named):
old item **1** is down from four uncracked hashes to one (§3.1) · old **2**, the broadcast tags,
crack **statically** (§3.2) · old **3**, `[0x01176170]`'s **role**, is settled (§4.4) · old **6**,
the unwritten dword, is **never read** (§3.4) · old **7**, the app-stack slot, is **layer 4**
(§3.5) · old **10**, `DFBD77`/`78`, are `Net.IsClient`/`Net.IsServer` (§5.1) · and `[0x01175A94]` /
`[0x01175F58]` both decode statically (§3.5, §5.2). Old **8**, `Pg.RemoveContextAction`, has its
return shape read (§6.2); its internals remain unrecovered but are no longer this map's blocker.

**Five items remain.**

1. **State-name hash `0x53056C27` (slot 7)** — see the boxed exhaustion record in §3.1: ≥52.2 M
   mined strings and ~9×10¹⁵ generated candidates tried, the `waitfor*` family exhaustively
   excluded, `m2` case-folding accounted for. **Do not invent a name.** The only untried static
   route is the **retail Xbox/PS3 executables**, which are not in this repo (the four 2–2.5 GB WADs
   probe clean for `WaitForTether`/`RequestGameState`, and the Jul 11 2008 prototype ISO is also
   untried). *Runtime recipe:* HW-write watchpoint (4 bytes) on `DAT_01175C7C`, boot to a level,
   read `[cur+4]` at each stop — the state is entered immediately before `ingame`, so it is the last
   hit before `0x57B5E35A`. Alternative: one-shot bp on its enter slot `[0x00BB0144 + 4]` and read
   the caller's literals. **Secondary question, cheaper and more interesting:** confirm live that
   slot 7 is never entered at all (§3.1's "vestigial" reading, graded M).
2. **The 21st state hash `0x2D70FE6F`** (§3.1a) — present in the wire-encoding table
   `0x00D2AD38[7]` and compared live at `0x004C1716` / `0x006CD39F`, but with **no state object** in
   the 20-slot table. Uncracked and unnamed. *Recipe:* it shares its predicate set with
   `{ingame, pause, pda}`; break `0x004C1710` and observe which condition makes the compare tree
   hit that arm. Then decide between "state from a build that didn't ship" and "replication-only
   pseudo-state".
3. **The exact label string for `[0x01176170]`** (§4.4) — the **role** is closed on five converging
   lines and the field map is nailed; only the literal symbol is open, because the PC release build
   strips all `PgSys*` labels and there is no Pangea RTTI on either platform. `rainbow_table.json`
   (733k hashes) has no match. *Recipe:* break `Init` `0x006C8CD0` and read the slot index
   `FUN_0060CF90` returns into `[this+0x14C]`, then match it against the PgSys registry's label
   array; or HW-write-watch `+0x1C8` during a lobby refresh and confirm the three `0x40`-B names are
   session / map / contract.
4. **The SecuROM split-thunk bodies** — `FUN_0045E440` / `FUN_0045E3F0` (layer-record lookup),
   `FUN_006B3560` (level-load-request builder), plus `0x0059F990`, `0x005A0330`, `FUN_004C0FF0`'s
   entry, `FUN_006CFF90`. ⚠ **The deref works and is not the blocker** — the slots *are* resolved in
   the dump:
   `FUN_0045E440 = push esi; mov esi,eax; jmp [0x02455100]`, `[0x02455100] = 0x024B98E0 → push
   0x024B98EA; call 0x01AAFF10`; `FUN_006B3560 = push ebx; jmp [0x0244F500]`,
   `[0x0244F500] = 0x024B5600 → push 0x024B560A; call 0x01AAFF10`. **The destination is the SecuROM
   VM entry, not clean x86** — these bodies were *virtualised*, not merely relocated, and
   `0x01AAFF10` is the interpreter ([[securom-decompiled-not-a-blocker]] covers the relocated case,
   not this one). The 42,601-fn export agrees: `FUN_0045e440 size=19`, `FUN_006b3560 size=7` — the
   thunks themselves, no recovered body. *Recipe:* lift with the VM disassembly, or trace-and-dump —
   one-shot bp on `0x0045E440`, HW bp on the return, record the effect on `eax` for a known
   `(typeHash, nameHash)` pair. What the **call sites** prove is already in this map and holds:
   `FUN_006B3560(&DAT_01175AB8, &DAT_01175B78, 2, 1)` at `0x005E4CFD` from `Sys.StartSingleplayer`,
   and `FUN_0045E440`'s three callers are exactly `Pg.LoadLayer 0x005D4E13`,
   `Pg.UnloadLayer 0x005D4F00`, `Pg.ReloadLayer 0x005D5043`, each preceded by
   `mov [esp+0x1c], 0xE6B81A54`.
5. **Does a bulk `memcpy` sweep `[0x01176170]+0xF149`** into a savegame blob or a minidump? (§4.3.)
   The displacement scan is exhaustive and returns three sites, all writes; the sibling field
   `+0xF0E5` is read by direct displacement at five sites, so the direct form is the engine's idiom
   here. A structure-wide copy is unprovable by any static scan. *Recipe:* HW-read watchpoint
   (4 bytes) on the field, then activate and complete a contract and save. If it never trips, the
   write-only conclusion closes.

### 9.A Sibling-map corrections (stated here; those files are not edited by this map)

Tested as claims, not cited as evidence.

| sibling | status |
|---|---|
| [`save_serialize_code_map.md`](save_serialize_code_map.md) | **This map was wrong about it, twice.** It contains **zero** mentions of `0x01175F30`, so it never owned the save-manager singleton; and it *already* prints the `+0xC3D` **writer** at `:143-144`, so §6.4's "new here" was false. Both fixed above. |
| [`scripting_host_binding_code_map.md`](scripting_host_binding_code_map.md) | `:212` still labels `0x00B99328` **"World"** — corrected by §1. The same row carries a **second** defect: it lists `CreateRegion 0x5BFB00` as a `Pg` member; that is slot 1 of the **`Junk`** table (§2.1). Its `0x006D5640` stub ownership is confirmed, with the §8 provenance caveat. |
| [`scheduler_tick_code_map.md`](scheduler_tick_code_map.md) | ✅ **already corrected upstream** (its `:46` now carries a dated note). An earlier draft of this map's worklist said `:41` calls `0x00D6C22C` the app-stack array; that no longer reproduces — the file now says `array @0x017bbccc` and prints the same five-layer table as §3.5. Its `FUN_004C0EC0 → FUN_004C9740` edge (`:117`) independently confirms this map. |
| [`player_code_map.md`](player_code_map.md) | ✅ **already corrected upstream** — `:497` now records `DAT_00DFBD77 = IsClient` / `DAT_00DFBD78 = IsServer`, so the disagreement §5.1 used to flag is gone. Note it also **disclaims** `[0x01176054]`, pointing at `save_serialize_code_map.md`; this map's boundary row was a three-way mis-attribution and has been rewritten. |
| [`input_code_map.md`](input_code_map.md) | consistent — `:93-98` draws `FUN_004C15E0 → layer 4 → FUN_004C9740`, which §3.5 proves correct. |
| [`faction_reputation_code_map.md`](faction_reputation_code_map.md) | **PARTIAL.** Owns `Report` and `Pg.*Pursuit*` behaviourally but records the pursuit cfunc VAs as "unlocated" (`:101-102`) and never pins the `Report` table VA or `[0x01175E54]`. This map supersedes it there and satisfies its `:327` open item. §6.3's ruling-out is confirmed on both sides: `GetInfractions 0x005E0720` pushes exactly the seven literals, its singleton is `[0x01175E54]` (read at `0x005E0670`, `0x005E0793`), and all **8** `Report.` sites are in `mrxfactionmanager.lua`. |
| [`event_bus_code_map.md`](event_bus_code_map.md) | **no corroboration.** Zero hits for `DAT_0120F510`, `FUN_004BDD10`, `FUN_004C9CF0`, `FUN_004BDE40`; it documents an 18-bucket hash subscriber registry with `Event.Post = FUN_005F6A90`. **Whether that registry and the three rings in §3.3 are one bus or two is an open question neither map addresses.** |
| [`02_mission_task_framework.md`](../mercs2-luacd/02_mission_task_framework.md) / [`03_contracts_jobs.md`](../mercs2-luacd/03_contracts_jobs.md) | confirmed, with a gap of this map's own making: §7's "~30 `MrxTask*` modules" is **23**, and §7 ignores the DLC contract corpus (9 `dlccon*` scripts plus a second flow module `dlc01missionflow.lua`) — while §2's traffic numbers **do** include it. §2 and §7 are computed over different corpora; see the Sources note. |

---

## 10. Reconciliation with the Rust reimpl

**There is no `mercs2_mission` crate and no scoreboard row.** `engine_support_inventory.md` records
the hole four times from the *symptom* side (⛔ "Save contract/missions → mission flow … no consumer;
no mission system → no objectives/triggers. World is a diorama"; ⛔ "New Game → char-select → first
mission"; ⛔ "Native combat death → Lua `Event.ObjectDeath`/proximity"; ⛔ "Per-frame Lua event pump →
mission logic"), all under gate **K1 — no persistent mission-Lua host in the game loop**. The row it
does have, `Pg`, is marked 🟡 *"GetGuidByName/Spawn only"*.

What this map says the reimpl must build, in dependency order:

1. **A game-state machine first, not a mission system.** 20 states, hash-keyed, one current state,
   a 16-byte request queue, and — the load-bearing part — **the per-system tick is invoked from
   inside the state pump** (§3.5). Missions do not sequence themselves; they sequence *through*
   `Sys.RequestGameState`. Model the swallow gates faithfully (`unloading`, `unloadshell`+`shell`)
   *including the fact that both return `true`*, or Lua that reads `bSuccess` will behave
   differently from retail. Two of the twenty states (`connecting`, `exiting`) have a **no-op
   `Update`** — don't invent behaviour for them.
2. **Hash the state name, don't compare the string.** `m2` is case-folding; retail Lua relies on it
   (`"Shell"` vs `"shell"`, `"WaitForTether"` vs `"waitfortether"`). A string-equality reimpl
   silently loses transitions.
3. **The mission system itself is Lua.** The correct target is not a Rust mission crate but a
   **persistent Lua host with a per-frame pump** feeding `Event.*` — gate K1. `mercs2_script` +
   `MrxTask*` is the mission system; do not reimplement `MrxMissionFlow` in Rust.
4. **`Pg.Contract*` is three lines of code.** One `[0x40]` string field, `strncpy`-in on activate,
   clear on complete **and** cancel. Do not build a contract object behind it. ⚠ **Corrected:** this
   item used to say to model the three as returning `true`. They do **not** — all three declare one
   result and push nothing (§4.1). The faithful reimpl either returns **no value** or reproduces the
   `nresults=1`-with-empty-stack quirk; every shipped call site discards the result, so returning
   nothing is safe and returning `true` is the one thing retail definitely does not do. Same for
   `Pg.ResetSingletonDone`.
5. **`Gui.AddObjective` must stay a no-op** returning nothing — and so must the two **generic**
   `Net.SendEvent_Add/RemoveObjective`. But the **ten concrete** `Net.SendEvent_*Objective*` senders
   are real and must be built (§6.1): they are how a co-op client ever sees a marker. Objectives
   themselves are marker + minimap + PDA + tray calls issued by Lua; a reimpl that invents an
   objective *data model* will diverge from every shipped mission script.
6. **Layers need the static/dynamic bit and the unload guard.** `rec+0x18` bit 0 = dynamic
   (unloadable), bit 2 = static. ⚠ **Corrected — this item used to be exactly backwards.** It said
   `UnloadLayer` on a static layer is "a **Lua error** … missing this turns a mission-cleanup bug
   into a silent world corruption instead of the loud error retail gives". **Retail *is* the silent
   path**: it pushes `nil` (§0, §5.2). A reimpl built to the old advice would raise where retail
   returns `nil`, and every `if not Pg.UnloadLayer(x) then` in the corpus would take a different
   branch. Reproduce the `nil`. If you want the loud error, that is a *fix-pack* change, deliberately
   made and recorded as a divergence — not a fidelity requirement.
7. ✅ **`pg_world.rs`'s identity is fixed** (§1): `NAMESPACE = GLOBAL = "Junk"`, census re-run —
   **7 of 24 rows nonzero, 13 call sites**. (This item used to ask for the fix and quoted "12 sites",
   which missed `Junk.GetModelBBoxExtents`.) Two of the table's rows, `Junk.IsInstallable` and
   `Sys.NoHud`, must return a **constant `false`** (§2.1).
8. **`Sys.SetSkipMission` is an unbounded `strcpy`.** If the reimpl exposes it, bound it — and note
   that retail's dev mission-skip is still live, which makes it a testing lever for the mission
   silo before the full flow exists. It also pushes `nil` and returns 1.
9. **Gate the simulation on the right three things.** ⚠ **Corrected:** this item used to be filed
   under "state-gate the simulation". The **game state does not gate it** (§3.5). What does:
   (a) the app-stack layer's own phase `== 2`; (b) the foreground predicate — a non-foreground
   window `Sleep(100)`s and skips the entire per-system pump; (c) `[0x01175A94] != 1`, a
   **level-transition/device-reset handshake** with `RunFrame`, not a pause flag. A reimpl that
   ticks unconditionally will diverge on timing-sensitive mission logic (`Event.TimerRelative` is
   used heavily by the contract scripts) — but one that gates on "am I in state X" will diverge the
   *other* way, stalling the sim whenever no state is current.
10. **The mission-relevant co-op contract is server-authoritative and silent** (§5.1, §6.1). On
    `Net.IsClient`, `Pg.LoadLayer(name, true, …)` returns 0 values and every objective sender early-
    outs, with no error on either path. If the reimpl runs mission Lua on the wrong peer it will
    reproduce retail's desync — which is arguably correct fidelity, but it should be a *decision*.
11. **Two tables the reimpl must build at runtime, not bake:** `0x01175C80[]` (the state array,
    populated by `FUN_004C0FF0`) and `0x017BBCCC[]` (the app stack, populated by `FUN_004C1170`).
    Both read all-zero on a clean exe (§3.1, §3.5).

---

## 11. Provenance

- **PC decomp:** `output/_ghidra/mercs2_unpacked.exe_decomp.txt`. Bodies read first-hand this pass:
  `FUN_005A2C40` (namespace bootstrap), `FUN_004C09C0` / `FUN_004C0F10` / `FUN_004C0FA0` /
  `FUN_004C0EC0` / `FUN_004C13A0` / `FUN_004C15E0` / `FUN_004C14F0` / `FUN_00630EF0` (frame + state
  machine), `FUN_004BDD10` / `FUN_004BDE40` / `FUN_004C9CF0` (the event rings), `FUN_004C00E0`
  (singleton install table), `FUN_005D4C80` / `FUN_005D4E40` / `FUN_005D4B50` (layers),
  `FUN_005D7630` / `FUN_004B2C60` (context actions), `FUN_005E4AF0` / `FUN_005E4C50` / `FUN_005E50B0`
  / `FUN_005E5120` / `FUN_005E54F0` (`Sys`), `FUN_005E05D0` / `FUN_005E0720` (`Report`, to rule it
  out), `FUN_006C8A20` (the `[0x01176170]` ctor), `FUN_0045E440` / `FUN_006B3560` (the two split
  thunks).
- **Raw disassembly** (capstone, straight out of `output/_ghidra/securom_dump/mercs2_unpacked.exe`)
  for the cfuncs Ghidra had no entry point for — every one of these was read instruction-by-
  instruction, not inferred: `Pg.ContractActivated` `0x005D7DB0`, `Pg.ContractCompleted`/`Cancelled`
  `0x005D7E40`, `Pg.LoadIsRetry` `0x005D7E70`, `Pg.IsStaticLayer` `0x005D4BF0`,
  `Pg.GetUnloadingStaticLayers` `0x005D4BA0`, `Pg.ResetSingletonDone` `0x005D4BE0`, `Pg.SaveGame`
  `0x005D7CB0`, `Pg.LoadGame` `0x005D7D30`, `Sys.RequestGameState` `0x005E4AF0` (full),
  `Sys.IsLoadingOrStreaming` `0x005E4D40`, `Sys.GetLevelName` `0x005E4FF0`, `Sys.GetMasterScriptName`
  `0x005E5050`, `Sys.GetCharacterTemplate` `0x005E5190`, `Sys.FinishedShell` `0x005E54C0`,
  `Sys.AutoLoad` `0x005E5490`, `Sys.SetSkipMission` `0x005E5510`, `Sys.ForceNextAutosave`
  `0x005E6670`, `Sys.RequestAutosave` `0x005E61F0`, `Sys.GetVersion` `0x005E6680`.
- **Image reads:** the PE section table (`.data` at `0x00BF6000`, `.rdata` at `0x00B05000`), the
  31-row namespace registry at `0x00DFD478`, the `Pg`/`Junk`/`Sys`/`Gui`/`_GuiInternal`/`Event`/
  `ObjectState`/`Report` `luaL_Reg` tables, the 23-slot game-state table at `0x01175C80`, and a
  full-`.text` immediate scan for `0xF149`.
- **Hashes:** `tools/pandemic_hash.py` `pandemic_hash_m2` (`tools/fnv.py` `m2()` agrees).
  Confirmed against code constants:
  `m2("layer") = 0xE6B81A54`, `m2("unloading") = 0x7D0B162C`, `m2("shell") = 0x51BFF7B1`,
  `m2("ingame") = 0x57B5E35A`, `m2("loading") = 0x96FB0F27`, `m2("cinematic") = 0xB8CB300C`,
  `m2("pause") = 0xC8192FE5`, `m2("waitforstreaming") = 0x7E289119`,
  `m2("waitfortether") = 0x9B7AD367`, `m2("default") = 0xBA71C11C`, and — added this pass —
  `m2("enter") = 0x9DA97065`, `m2("exit") = 0xDB41017D`, `m2("flush") = 0x6D19FA15`,
  `m2("connecting") = 0x38929BF7`, `m2("waitforplayer") = 0x05CE7A0C`,
  `m2("unloadshell") = 0x20BC86EA`. Never asserted from a hash alone where a positional or code
  corroboration was available ([[no-arbitrary-hashes]]); `0x53056C27` and `0x2D70FE6F` are left
  **unnamed** rather than guessed.
- **Binding table:** own `.rdata` walk, cross-checked against
  `mods/lua_trace_asi/reference/binding_map.json` (60 tables; entry counts agree: `Pg` 80,
  `Junk` 24).
- **Script traffic:** `corpus_calls` in
  `tools/wad_simulator/crates/mercs2_script/src/bindings/pg.rs` (read-only), plus own greps over
  `docs/mercs2-luacd/src/` for the `Junk.*` and `Sys.*` names the crate mis-keyed.
- **Xbox side:** `docs/mercs2-pdb-analysis/game-systems.md` §Missions/contracts/objectives — used to
  confirm `sContract` and the dev skip. ⚠ It was **also** used to claim the objective `SendEvent_*`
  surface is devkit-only; that inference did not survive a walk of the retail `Net` table and has
  been withdrawn (§6.1). Also: `mercs2_xenon_p.pe_full_strings.txt` (the `PgSysNet*` label set) and
  `output/jul08_prototype/pairing/string_func_map.json` for §4.4.
- **Lua layer:** `docs/mercs2-luacd/02_mission_task_framework.md`, `03_contracts_jobs.md`,
  `src/resident/{mrxstate,mrxtask,mrxtaskcontract,mrxmissionflow,mrxlayermanager,mrxplaystate,mrxguihudobjectivetray}.lua`,
  `src/vz/{pmccon003,pircon003}.lua`.
- Confidence stated per row. **Five documented gaps remain** (§9): the slot-7 hash `0x53056C27`, the
  21st state hash `0x2D70FE6F`, the *label string* for `[0x01176170]` (its role is closed), the
  VM-virtualised split-thunk bodies, and the bulk-copy question on `+0xF149`.

### 11.1 How to re-derive anything in this map

Everything asserted here is reproducible from the two images with capstone and a PE section walker.
The helper used this pass (`Img.read/u32/cstr/dis`, `load('unpacked')` / `load('v3')`) is 50 lines
and parses the section table rather than assuming `raw == RVA`:

| section | VA start | vsize | raw ptr | raw size |
|---|---|---|---|---|
| `.text` | `0x00401000` | `0x00704000` | `0x00001000` | `0x00704000` |
| `.rdata` | `0x00B05000` | `0x000F1000` | `0x00705000` | `0x000F1000` |
| `.data` | `0x00BF6000` | `0x00E04000` | `0x007F6000` | `0x00E04000` |

Image base `0x00400000`. Hashes: `tools/pandemic_hash.py` → `pandemic_hash_m2`. Spot checks that
should pass before trusting anything else: `m2("layer") == 0xE6B81A54`; `u32(0x00BC3FB8+0x34)`
resolves to a body whose bytes are `B8 AC 5D BC 00 C3` and whose `imm32` `cstr`s to `"Players"`
(the master-key positive control); and `read(0x006D5640, 3)` is `E9 7B CA` in the dump but
`33 C0 C3` in `mercs2_nodrm_v3.exe`.
