---
status: current
evidence: graded per claim (P proven / I inferred / G gap)
---

# Mercs2 PC multiplayer menu: friends path, shell flow, owning the menu, Lua↔ASI

Grades: **P** = read this run (cited), **I** = inferred, **G** = gap. Exe = `output/_ghidra/securom_dump/mercs2_unpacked.exe`
(VAs). Decomp = `output/_ghidra/mercs2_unpacked.exe_decomp.txt` (line numbers given as `decomp:N`). Lua =
`docs/mercs2-luacd/src/shell/*.lua`. Raw disassembly with `/usr/bin/objdump`; byte scans with small Python
scripts (scratchpad).

## 0. Corrections to existing docs (read first)

- **No `lobby.swf`.** The shell loads one movie, `shell.gfx` (`mrxguishell.lua:197-199`, `:260`, `:499`). No Lua in
  `docs/mercs2-luacd` or `-xbox` mentions `lobby.swf`/`lobby.gfx` (P, grep). `teknogods_menu_crossref.md` §"Code Path"
  (`Gui.SetFlashSwfFile("lobby.swf")`, `ChangeShellState("joinGame")`, `→ FESL asso`) is unsupported. P.
- **No `ChangeShellState("joinGame"/"onlineError")` in Lua.** `LTILibName.ChangeShellState` takes a boolean
  (`mrxmultipagemenu.lua:31,99,112`). `joinGame`, `onlineError`, `_lobby`, `_joingame` etc. are **AS2 frame/clip
  names inside SHELL.gfx** (strings in the inflated movie). P.
- **`Net.EnterFriendsLobby` → "FESL asso"** (teknogods doc) is unproven; see §1.
- `docs/ui/shell_menu_lua_anatomy.md`'s "the SWF dispatches `Enter.Lobby`": PC `SHELL.gfx` contains **0** occurrences of
  `Enter.Lobby`/`Exit.Lobby` (P, byte search of inflated `output/gfx_movies/shell/SHELL.gfx`). Lua registers handlers for
  them (`mrxguishell.lua:514-515`) but the PC movie never fires them (I: unless built dynamically; no `Enter.` + `Lobby`
  concatenation found — not exhaustively checked, G).

## 1. Friends path

### 1.1 The Lua side (P)

| Flash event (FSCommand in SHELL.gfx) | Lua handler | Net call |
|---|---|---|
| `friendsLobbyEntered` | `_EnterFriendsLobbyFlashCallback` `mrxguishell.lua:645` | `Net.EnterFriendsLobby()` `:648` |
| `friendsLobbyExited` | `_ExitFriendsLobbyFlashCallback` `:657` | `Net.ExitFriendsLobby()` `:664`, then `Net.Stop()` if not internet and not online-connected `:665-666` |
| `joinFriendsGame` (arg = name) | `_JoinFriendsGameFlashCallback` `:695` | `Net.ConnectToServer(sName, "")` `:699` (return value ignored; shell not closed) |

All three FSCommand strings exist in PC SHELL.gfx (`FSCommand:friendsLobbyEntered/Exited`, `FSCommand:joinFriendsGame`),
plus friends UI vars `joingameFilterFriends`, `joingameFriendsOnlyVar`, `joingamefriend:`, `friendInvite`,
`joingameInviteArray`, `onlineViewInvitations`, `"You have received an invite. Would you like to go view it?"` (P).

### 1.2 The bindings (P, decomp:233905-234146; table dumped from `.rdata 0xB998D0`)

Every `Net.*` lobby binding builds a 0xD0-byte command and posts it to the **208-byte broadcast ring**
`FUN_004BDE40` (256 slots, `DAT_0125D3E0`, count `DAT_0125D3B8`, subscriber mask `DAT_0125D3BC`; same ring documented
in `mission_contract_flow_code_map.md` §3.3). Command word 0 = kind:

| Binding | VA | kind | Notes |
|---|---|---|---|
| `EnterLobby` | 0x5C69E0 | 0 | |
| `ResetServerList` | 0x5C6A40 | 1 | |
| `ConnectToServer(name, addr)` | 0x5C6AA0 | 2 | name strncpy 63; if `DAT_017C0BC8 != 1` parses addr as `%d.%d.%d.%d:%d` (fmt `0xBB8164`) or `%d.%d.%d.%d` + default port `DAT_017C0DD8`; flag byte = parsed. In internet mode the addr is **ignored** (connect by name). |
| `StartServer(host, level, script)` | 0x5C6C40 | via `FUN_006B3560(level, script, host, 1)` | |
| `Stop` | 0x5C6D30 | 4 | |
| `EnterFriendsLobby` | 0x5C6910 | **0x29 if `DAT_017C0BC8 == 1`, else 0** | i.e. on LAN it is identical to `EnterLobby` |
| `ExitFriendsLobby` | 0x5C6980 | 0x2A | unconditional |

`DAT_017C0BC8 == 1` is the internet-matchmaking mode: `Net.IsMatchmakingInternet` (0x5CACC0) =
`[0xDFBD74] != 0 && [0x17C0BC8] == 1` (P, disassembly); static default 1 (`FUN_006B3010`, decomp:360326).

### 1.3 Who consumes kind 0x29 / 0x23 — G

The ring's **drain** (copy-out per subscriber) is not in `.text`: the only code reading `0x125D3E0`/`0x126A3E0` outside the
writer is at **`0x24651D0`** in the `.securom` partition (P, byte scan + disasm: `imul esi,0xD0`, `rep movsd ecx=0x34`,
per-slot mask clear). No direct call/jmp/abs ref to `0x24651D0` exists (P) — it is reached through a SecuROM thunk.
Subscribers claim bits through `FUN_006B4BB0` (callers `FUN_006B4250`, `FUN_006C18F0`, `FUN_006C23E0`, `FUN_006C7F90`,
`FUN_006CEBC0`) — which of them switches on kinds 0x23/0x29/0x2A was **not** found (G). (`case 0x29/0x2a` in
`FUN_00615A10` decomp:274963 is a *dialog-id* switch, unrelated; `FUN_006FD400` is a different event space.)

### 1.4 The asso builders have no static caller (P)

- `0x981CD0` Add / `0x981D60` Delete / `0x981DF0` Get / `0x981E80` Count are **not Ghidra functions** and are referenced
  only from a vtable: `.rdata 0xB5FBDC..0xB5FBE8` = slots **+0x1C/+0x20/+0x24/+0x28** of the vtable at **`0xB5FBC0`**,
  installed at `0x977A98` (the FESL connection object; `0xB5FBAC` is the `"fesl.ea.com"` string just before). P.
- Reply callbacks: `0x9B06C0` (Get, in vtable `0xB640F0`), `0x9B1150` (Add; pushed at `0x9B1662/16CA/16F8`), `0x9B1200`
  (Delete; `0x9B1816/1876`) — all inside a self-contained association/"friends" module `0x9AE000–0x9B2000` whose
  vtables are `~0xB640AC` and `0xB64100`. **No function in that module has a caller outside it** except a string helper
  (`FUN_009AE6A0` ← achievement code). P. So the module is entered only through vtables; the game-side issuer is
  not statically visible (G).

### 1.5 Can a player add a friend in the shipped PC UI? — UI exists, wire path G

- SHELL.gfx emits **`FSCommand:onlineLTIFindFriend`** (P). The native FSCommand router `FUN_0060DE80` hashes the command
  (`pandemic_hash_m2`, `FUN_00824270`) and falls through to `FUN_00614540`, which handles **`0x275F16F0` =
  m2("onlineLTIFindFriend")**: posts **kind 0x23 + the AS argument (≤63 chars)** to the same 208-byte ring
  (decomp:273804+, local listing line 130-134). P.
- Also native there: `onlineLeaderboardsFriends` → kind 0x4B; `onlineQuickmatch` → 0x2E; `onlineDisconnect` → 0x28;
  `onlineExistingAccountNamePass` → 0x1B; `onlineLoginAccountPass` → 0x1D; `onlineCreateAccountNamePass` → 0x1E;
  `onlineTOSAllowEA` → 0x22; `onlineLTIRegisterGame` → 0x21; `onlineRefreshLobby` → kind 'P' (0x50) on the **third**
  ring `FUN_004BDDA0`; `onlineLobbyDetails` → reads session `FUN_006C95E0(name)` and invokes AS. P (hash matches in
  `.text` listed in scratch `fshits.txt`).
- `onlineViewInvites`, `friendsLobbyEntered/Exited`, `joinFriendsGame`, `joinGame`, `quickmatchJoinGame`,
  `optimatchJoinGame` hashes appear nowhere in `.text` → handled only by Lua (`SetFlashEventHandler`) or dropped. P.
- Whether kind 0x23 ends in FESL `asso AddAssociations`, Messenger `RADD`, or nothing: **G**.

**Cheapest way to close §1 (no debugger):** our ASI already terminates FESL. Log every inbound TXN in the local FESL
terminator and walk SHELL.gfx's friends screens (Find Friend, friends lobby, View Invites). If `asso` TXNs appear, they
are the answer; if a Messenger connect (TCP 13505, `0x96DDA0`) is attempted instead, that is the answer. Alternative
(x32dbg, user-driven): one-shot BP on the `0x981CD0`/`0x981DF0` bodies and on `0x96DDA0`.

## 2. Multiplayer shell flow in Lua (P unless marked)

- One widget "Shell" (`mrxguishelllayout.lua:7-36`), handlers `LobbyServerAdded/Updated/Removed` →
  `HandleServerAdd/Update/Remove` (`:23-26`), `ControllerInput`, `GuiInitialization`, `GuiGameStateChange`.
- Flash setup: `HandleInitializationEvent` creates `FlashWidget`, `SetSwfFile("shell.gfx", CompleteFlashSetup)`
  (`mrxguishell.lua:253-276`); `CompleteFlashSetup` registers `newGame, Enter.Lobby, Exit.Lobby, joinGame,
  onlineQuickmatch, onlineOptimatchSearch, quickmatchJoinGame, optimatchJoinGame, friendsLobbyEntered,
  friendsLobbyExited, joinFriendsGame, startMovie, stopMovie` (`:511-525`). `LTIChoseOnline` → native
  `LTILibName.LTIChoseOnline` (`:275`, `:933-935`).
- Server list (LAN path): engine events → `HandleServerAdd` builds `{uKey,sName,nStatus,sMap,sContract,bFriendlyFire}`
  and calls AS `addServer(id,name,status,map,contract,ff)` (`:360-399`); `removeServer` (`:413`).
  `_RepopulateServerList` 0.2 s after Enter/EnterFriends lobby **only when not internet** (`:625-628`, `:650-653`).
- Internet list: **no Lua involvement**; `onlineRefreshLobby`/`onlineLobbyDetails` are native (§1.5); the
  pnow-vs-GLST choice is made natively (I; Lua never names either).
- Host: `_NewGame` → `Net.StartServer(Net.GetHostName(), Sys.GetLevelName(), Sys.GetMasterScriptName())` when
  `IsMatchmakingInternet() and IsPlatformConnected()`, else `Sys.StartSingleplayer` (`:593-604`). Also
  `shellbootstrap.lua:95-97` (AutoServer).
- Join: `_JoinGameFlashCallback(index)` → `Net.ConnectToServer(tData.sName, tData.sIPAddress)` (`:670-693`).
  **Bug (I):** `HandleServerAdd` never stores `sIPAddress` (`:375-382`), so `:685` concatenates nil → Lua error before
  the connect; same in the Xbox decompile. Quick/Optimatch: `ConnectToServer(sServerName, "online")` (`:710-734`).
  Friends: `ConnectToServer(sName, "")` (`:699`). AutoClient: `Net.ConnectToServer()` (`shellbootstrap.lua:88-90`).
- Every `Net.*` call in shell Lua: `IsMatchmakingInternet`, `IsPlatformConnected`, `StartServer`, `GetHostName`
  (`:598-599`); `EnterLobby` (`:623`); `IsOnlineConnected`, `Stop` (`:640-641`, `:665-666`); `EnterFriendsLobby` (`:648`);
  `ExitFriendsLobby` (`:664`); `ConnectToServer` (`:688,699,714,727`); `shellbootstrap.lua:88-97` `AutoClient`,
  `ConnectToServer`, `AutoLobby`, `EnterLobby`, `AutoServer`, `StartServer`, `GetHostName`; `mrxguibase.lua:120,134`
  `IsMultiplayer`; `mrxmusic.lua`/`mrxguicinematic.lua` in-game `IsServer/IsClient/SendCustomEvent/SendEvent_*`.
- Full `Net` table (79 rows) dumped from `0xB998D0` (scratch `nettbl.txt`). Note aliases: `IsPlatformConnected`,
  `IsConnectedToInternet`, `IsOnlineConnected` all = `0x5CAD10` (returns `[0x17C0BBF]`); `IsOnlineEnabled` =
  `IsMatchmakingInternet` = `0x5CACC0`; `IsDedicated/AutoLobby/AutoClient` = `0x5C6850` (always false). P.
- SHELL.gfx's account/TOS/login/DLC/leaderboard screens are all native-routed (§1.5), so the online UI is mostly
  **AS ↔ native**, with Lua only for host/join/lobby-enter.

## 3. Owning the menu — feasibility

### What exists

| Mechanism | State | Evidence |
|---|---|---|
| `shell-patch.wad` overlay mounts above `shell.wad` | P (code), engine name `%s-patch.wad` | `manifest_format.md:126` (`FUN_004BFDA0`, `0x004C12DD`); last-wins proven in-game for stringdb (`wad-mount-order-last-wins` memory) |
| qm Lua injection into **shell** scripts | **Only for sound**: qm links an append onto shell `mrxsound` + mints `qm_shell_modloader` into `blocks\Shell\resident_P000_Q3.block` | `link.rs:130` `SHELL_SCRIPT_BLOCKS`, `:1359-1381`; `manifest_format.md:1277-1296`. `patch_lua` itself resolves only `SCRIPT_BLOCKS` (vz) (`link.rs:122-126`). Live front-end proof: G |
| `import` finds a script by name hash, any block | P (doc) | `manifest_format.md:1293-1295` (`_SYS._IMPORT 0x5AE2D0`) |
| `add_movie`/`add_ui` (cfx_pack mint + FlashWidget trampoline) | vz-only routing; `add_ui` hooks `wifpmcinterior` | `gfx_menu_replay_scoping.md` §1.3, §5.2 |
| Same-hash replacement of `SHELL.gfx` in shell-patch | Unproven for cfx_pack | `gfx_menu_replay_scoping.md` §5.3 (open question #3) |
| Editing SHELL.gfx (397 KB, AVM1) | No round-trip editor; gfxforge emits small movies only | same doc §1.4, §0 |
| Pure-Lua menus in shell Lua | **Present in the shell scripts**: `MrxMultiPageMenu` (paged option list → `MrxGui.DisplayDialogBox`), `MrxGuiDialogBox`, `MrxGuiNumericBox` (digit entry) | `mrxmultipagemenu.lua:44-118`, `mrxgui_shellonly.lua:255`, `mrxguinumericbox.lua:16`. Used by `OpenSkipToMissionDialog`/`OpenInstallDialog` (`mrxguishell.lua:138-195`), which retail gates off (`Sys.IsFinalConfig`, `Junk.IsInstallable`) → render in front end G; `DisplayDialogBox` in gameplay is retail-visible (briefing menus, `mrxbriefing.lua:742`) |
| Ess.UI (AS2 runtime movie `ess_ui.gfx` + lists/menus/panels/**typed text input**) | Live-tested in gameplay (Ess dev loop); front end G | `/Volumes/Projects/mercs2-lua-essentials/src/42_ui_engine.lua`, `48_ui_input.lua`, `49_ui_menu.lua` |

### What a new submenu needs, smallest first

1. **No new button, Lua-only (smallest; I).** Re-purpose an FSCommand the PC movie already fires but that has no live
   meaning for us, e.g. `friendsLobbyEntered` (§1.1): append to `mrxguishell` a replacement
   `_EnterFriendsLobbyFlashCallback` that opens a `MrxMultiPageMenu` ("Room key", "Friends", "Server") and a
   `MrxGuiNumericBox` for a numeric room key. Needs: (a) a qm `patch_lua` route for **shell** scripts (the link code
   already handles the shell block for `mrxsound`; extending `patch_lua` target resolution to `SHELL_SCRIPT_BLOCKS` is
   the missing piece), (b) handlers re-registered after `CompleteFlashSetup` (it re-registers on every shell open,
   `:511-525`, so the append must wrap `CompleteFlashSetup`, not just redefine the callback — I), (c) live check that
   `DisplayDialogBox` draws over the Scaleform shell (G).
2. **Relabel an existing entry** via `English-patch.wad`/shell stringdb (proven route) if the label is stringdb-driven
   — `shell_menu_lua_anatomy.md` Phase-1 spike, result G.
3. **Additive overlay movie** (`add_ui`-style FlashWidget over the shell, e.g. Ess.UI's runtime) — needs the shell route
   for `add_movie` + a shell trampoline (not built); gives free text input. G for front end.
4. **Real new main-menu button** = edit SHELL.gfx (AVM1, 304 sprites) or same-hash replacement in shell-patch — highest
   effort; no editor; cfx_pack override in shell-patch unproven.

## 4. Lua → ASI seams

| Seam | What it gives | Evidence |
|---|---|---|
| **lua-bridge (Wally) `luaL_register` call** | ASI registers whole namespaces: `Loader` (`Printf, WsSend, IsKeyDown, PopKeyEvents, SaveVar, LoadVar, GetLoadPhase, LoadFile…`) and `Tcp.Send` | `/Volumes/Projects/Merc2-Mods-Exp/mods/lua-bridge-DEV/lua_bridge_DEV.c:3601-3637` (`RegisterLoaderLib`), `:1720` + `:2873-2890` (`Tcp`). Custom ABI: **ECX = L, EAX = libname, push table**; RVAs `luaL_register` 0x45F720 (v1.1) / 0x45F500 (cracked) at `:141-161`. P (code); Ess uses `Loader.*` live (12 sites, `ws4` plan) |
| lua-bridge chunk executor | run Lua from native (`luaB_loadstring` + `luaB_pcall`, `LuaDoStringEx`) | `mercs2-sdk/.claude/plans/ws4-sdk-lua-and-hooks.md:205-213` (cites bridge `:814-1084`) |
| Lua-state capture | bridge hooks `luaB_type` / no-op stub `0x6D5640` / `CreateTextWidget`, `LooksLikeLuaState` | ws4 plan `:205-208`. Whether it captures the **shell** VM: G |
| Pinned C-API VAs | `luaL_loadbuffer 0x860240`, `lua_pcall 0x85DF50`, `lua_pushcclosure 0x85DA90` (register-arg ABIs) | ws4 plan `:224` |
| m2 SDK stack readers | `m2_lua_nargs/arg_string/arg_type/arg_number/arg_bool` (float `lua_Number`, TValue 8 B, top +0x08, base +0x0C) | `/Volumes/Projects/mercs2-sdk/m2/m2_luastack.h:17-49`. No registration API yet (ws4 is plan-only) |
| pmc_bb | native Lua print capture; loads ASIs via `LoadLibraryA` | memory `pmc-bb-native-lua-logging`; ws4 `:226-229` |
| In-exe | `_GuiInternal.CallFlashScriptFunction` returns AS results to Lua | `lti_movie_pda_validation.md` M8 |

**Recommended shape (I):** the multiplayer ASI registers its own namespace (e.g. `MP.GetRoomKey()`,
`MP.Friends()`, `MP.ServerStatus()`, `MP.Join(key)`) with the same `luaL_register` call the bridge uses, from a hook
that sees a live `lua_State` — or depends on the SDK once ws4 lands, to avoid a third hook-race on the stub. The
data path to the Flash list is then Lua → `CallActionScriptCallback`, or a Lua dialog list.

## 5. Gaps to close, in order

1. Which code consumes ring kinds 0x23/0x29/0x2A (FESL asso vs Messenger) — answer by logging TXNs at our FESL
   terminator while using SHELL.gfx friends screens (§1.5).
2. Does `MrxMultiPageMenu`/`DisplayDialogBox` render over the Scaleform shell (one `patch_lua` test).
3. Does lua-bridge capture the shell `lua_State` (check `Loader.Printf` from a shell append).
4. Extend qm `patch_lua` target resolution to `SHELL_SCRIPT_BLOCKS` (code exists for `mrxsound`).

## 6. The script host, its Lua states, and where an ASI registers a namespace

Exe = `mercs2_unpacked.exe` / `mercs2_nodrm_v3.exe` (identical here); the v1.1 dump
(`genuine_patched_unpacked.exe`) carries the same code at other VAs (second column). Every site is located
at run time by an exact-unique byte signature (`shipments/multiplayer-restored/client/src/lua/signature.rs`,
tests over all three images).

| Site | VA | v1.1 | What it is | Grade |
|---|---|---|---|---|
| script host singleton | `0x014A5DA0` | `0x014A4DA0` | static ctor `0x005A1677` stores vtable `0x00BB4670` and publishes the host in `DAT_01175F30`; it is the first entry of the system list `0x00D28668` | P (disasm + `.data` refs) |
| host init (vtable `+0x14`) | `0x005A1760` | `0x005A1750` | `__thiscall`: only if `[host+0xC42]==0`: set it, `L = lua_open()` (`FUN_00865920`) into `+0x10` and `+0x14`, then `call 0x005A2C40` | P |
| host shutdown (vtable `+0x18`) | `0x005A1830` | — | clears `+0xC42`, `lua_close(+0x10)` (`FUN_00865A70`) | P (decomp) |
| namespace walker | `0x005A2C40` | `0x005A2C30` | `__stdcall(host)`, `ret 4`: pushes the three `_SYS` closures, then for each row of the 31-row registry `0x00DFD478` calls the per-row registrar (`0x005A2FD0` → `jmp [0x02458A68]` → `0x02471B40`, which handles the open/close marker rows) and runs the row's boot chunk (`luaL_loadbuffer` `0x00860240` + `lua_pcall` `0x0085DF50`); sets top = base before returning | P |
| `luaL_register` | `0x0085F500` | `0x0085F720` | register ABI `ECX=L, EAX=libname`, `luaL_Reg*` pushed, caller pops; references `"name conflict for module"` | P (v1.1 VA matches lua-bridge's table) |
| `luaS_newlstr` | `0x0086A2B0` | `0x0086A4D0` | cdecl `(L, str, len)` → `TString*` (len `+0xC`, chars `+0x10`) | P (called that way by `luaI_openlib`'s `setfield`) |
| `luaG_errormsg` | `0x0085EEA0` | `0x0085F0C0` | `EAX=L`; runs `L->errfunc` (`+0x60`) then `luaD_throw(L,2)` = `longjmp` (`FUN_00868010`); `error()` `0x00860480` ends in it | P |

Consequences:

- **One host, one `lua_State` at a time** (P): the host is a static singleton and init/shutdown create and
  close the state. Whether the state is closed and recreated between the front end and gameplay depends on
  the system loop's refcounts (`FUN_004C0730`) — not established here (G); `manifest.rs` `LoadSession`
  documents a VM per level swap (I). It does not matter for registration: every state the host ever creates
  passes through the walker before any script of it runs.
- **Registration point** (P for the code path, in-game G): detour the walker; after the original returns,
  `luaL_register(L=[host+0x10], "Mp", table)` and pop the table. The multiplayer ASI does exactly this
  (`client/src/lua/win.rs`). The ASI also checks `[host+0xC42]` after hooking: a state created before the
  hook would lack `Mp`, which is a fatal start-up error, not a silent miss.
- **Binding ABI** (P): engine cfuncs are cdecl with `L` at `[esp+4]` (`Net.IsOnlineConnected` `0x005CAD10`);
  `TValue` is 8 bytes (`float` `lua_Number`), top `+0x08`, base `+0x0C`.

### 6.1 The shell side

`patch_lua` with `session: front_end` (qm, `manifest_format.md` § "`patch_lua` in the front end") appends to
`shell.wad`'s copy of a script. The Multiplayer submenu (`shipments/multiplayer-restored/src/mp_menu.lua`)
replaces `mrxguishell`'s global `_EnterFriendsLobbyFlashCallback`; `CompleteFlashSetup` binds the
`friendsLobbyEntered` FSCommand to that global by name each time `shell.gfx` loads (`mrxguishell.lua:521`),
so the event opens the menu; its "Back" calls the retail handler (§1.1). Rendering of `MrxMultiPageMenu` /
`MrxGuiNumericBox` over the hidden Scaleform shell: in-game G (§5 item 2 still open).

### 6.2 In-game check (user-driven)

> **Delivery on hold (2026-10-10).** Step 1's shell-patch route used a `patch_lua` `session: front_end`
> manifest field that was never approved and has been reverted. The menu Lua is not shipped until its
> delivery route is decided; steps 2 and 7 (ASI-side `Mp` registration) still apply.

1. Build and deploy the Shipment (`qm build shipments/multiplayer-restored --corpus <corpus> --game <dir>`): it
   places `scripts/multiplayer_restored.asi` + `.ini` and writes `multiplayer-restored.shell-patch.wad`, which
   deploys into `data/shell-patch.wad`. sha256 every file before and after deploying.
2. Start the game. `scripts/multiplayer_restored.log` must show, in order: `lua signature <site> -> 0x…` for
   the six sites, `lua script host at 0x…`, `Lua detour installed: ScriptHostRegisterNamespaces at …`,
   `script host had not yet created a Lua state at hook time; …`, and, once the front end is up,
   `registered Lua namespace Mp (GetRoomKey, SetRoomKey) on lua_State 0x… (script-host state #1)`. A message
   box naming a site or "created its Lua state before the multiplayer ASI could hook it" is the hard failure.
3. Main menu → the online/multiplayer entry → the friends lobby. Expected: the Scaleform shell hides and a
   dialog titled "Multiplayer" lists "Room key: Public" (or the ini key) and "Back"; the log shows
   `Lua Mp.GetRoomKey() -> nil`.
4. "Room key: …" → "Enter a 7-digit key" → set digits with up/down, move with left/right, Accept. Expected:
   back at "Multiplayer" with "Room key: 0012345"; log `Lua Mp.SetRoomKey("0012345") -> true`.
5. "Room key: …" → "Clear (public games only)" → log `Lua Mp.SetRoomKey(nil) -> true`, label "Public".
6. "Back" (or the cancel button) → the shell reappears and retail's friends-lobby handler runs (the shell's
   own friends lobby behaves as before; with pmc_bb logging, `Entered friends lobby`).
7. Start a game and return to the menu: every new state logs a further `registered Lua namespace Mp …
   (script-host state #N)`.
