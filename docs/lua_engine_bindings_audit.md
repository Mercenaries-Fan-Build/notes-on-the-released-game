---
status: superseded
evidence: inferred
verified_on: 2026-07-21
witness: "Mechanically re-checked 227 binding rows from §3 against a full offline walk of the luaL_Reg tables in game-files/Mercenaries2 (1).exe (53,482,288 B). 194/227 names exist in some table; 33 exist in NO table. Only 130/227 (57%) also had the correct namespace. Namespace truth taken from the engine's own {name, luaL_Reg*} registry at VA 0x00DFD478 (31 rows). 5 of 5 checked namespaces (Save, Localization, Boundary, NetClient, Lobby) do not exist. Function-VA claims: 24 of 30 exact matches, 4 off-by-one-row, 2 correct-but-duplicated. Call-site counts from the 370 decompiled scripts in docs/mercs2-luacd/."
superseded_by: [docs/lua_engine_bindings_audit_deep_dive.md]
---

# Lua Engine Bindings Audit — Mercenaries 2: World in Flames (PC)

> **Date:** 2026-05-19
> **Status:** Complete. Comprehensive inventory from all available evidence sources.

> # ⚠ CORRECTION (2026-07-21) — READ BEFORE USING THIS DOCUMENT
>
> This audit's **function names are mostly real**, but its **namespace attribution is
> unreliable and its "Namespace Inventory" (§2) is wrong**. The labels `CERTAIN` and
> `CONFIRMED` throughout §3 were assigned from string-offset proximity, not from
> resolving the `luaL_Reg` row — so a name that exists *somewhere* in `.rdata` was
> graded the same as one whose table row was actually read.
>
> **Measured pass rate: of 227 rows sampled across §3, 194 name a binding that really
> exists, but only 130 (57%) also put it in the right namespace. 33 name nothing at all.**
>
> ## The five namespaces in §2 that do not exist
>
> `Save`, `Localization`, `Boundary`, `NetClient`, and `Lobby` are **not Lua
> namespaces**. There is no `luaL_Reg` table for any of them, and across the 370
> decompiled scripts in `docs/mercs2-luacd/` there are **zero** `Save.*`,
> `Localization.*`, `Boundary.*`, `NetClient.*` or `Lobby.*` call sites. §2 built them
> out of clusters of related **strings** in `.rdata`; the `0x007B8AC4 area` /
> `0x007D1D00 area` / `0x007BA118 area` addresses in that column are string-literal
> addresses, not table bases. Their functions are real but live elsewhere:
>
> | §2 claims | Reality |
> |---|---|
> | `Boundary` namespace, table `0x00799078` | No such namespace. `AddBoundary`…`IsInWarningZone` are in **`Player`** (`0x00B98FC0`); `GetBoundaryRadius`, `IsPointInBoundary`, `GetWarningRadius`, `GetTetherDiameter*` are in **`Pg`** (`0x00B99328`); `SetBoundaryEffect` is in **`Graphics`**. `0x00799078` is *inside* the Player array, ~entry 23 — not a base. |
> | `Save` namespace, `0x007B8AC4 area` | No such namespace. `SetLuaSaveVersion`, `RequestAutosave`, `IsAutosaveEnabled`, `SetAutosaveEnabled`, `ForceNextAutosave` are in **`Sys`**; `SaveGame`/`LoadGame` are in **`Pg`**. `SaveData`, `LoadSingleton`, `SaveSingleton`, `ResetSingleton`, `InitialSaveData`, `ClientRestorePreSaveCash`, `ClientReimburseForSave` are **in no table at all**. |
> | `Localization` namespace, `0x007BA118 area` | No such namespace. `AddStringDb`, `ClearStringDb`, `GetLanguage` are in **`Sys`**; `GetLocalizedName` is in **`Object`**; `GetLanguageName`/`GetLanguageNum` are in **`Gui`**. |
> | `NetClient` namespace, `0x007D1D00 area` | No such namespace and **none of the 10 listed names is in any table**. The replication entry points are the 44 **`Net.SendEvent_*`** rows inside `Net` (`0x00B998D0`) — e.g. `Net.SendEvent_AddMarkerObjective`, 14 call sites. |
> | `Lobby` namespace, `0x007BBCF8 area` | No such namespace; `LobbyServerAdded/Updated/Removed` are **in no table**. They are event-name strings. |
> | `Music` namespace | Not a namespace — the dynamic-music functions are rows inside **`Sound`** (`0x00B98C98`). |
> | `Atmosphere` namespace | Not top-level — it is a **sub-table of `Graphics`**. See the §3.7 correction. |
> | `DLC/Online` namespace, `0x007D9588 area` | Not a namespace. `IsDLC`, `DlcMapId`, `addLeaderboardEntry`, `removeLeaderboardEntries` have **no `luaL_Reg` row** — strings only. |
>
> ## Namespaces §2 misses entirely
>
> §2 lists 24 namespaces. There are **31**, and the biggest omissions matter a lot:
> **`Pg`** (80 bindings, **1,448 call sites** — the single most-used game namespace),
> **`_GuiInternal`** (114 bindings, 266 sites), **`Net`** (92 — §2 says "12+"),
> **`Object`** (87 — §2 says "15+"), **`Player`** (107 — §2 says "12+"),
> **`Vehicle`** (40, 276 sites), **`Human`** (30), **`Junk`** (24),
> **`math`** (17), **`Camera`** (14), **`Airstrike`** (12), **`ObjectState`** (9),
> **`Animation`** (6), **`Report`** (5), **`Movie`** (4), **`Table`** (2),
> **`String`** (1), **`Disguise`** (1), **`FactionZone`** (1), **`ObjectFilter`** (16).
>
> ## Where the truth lives
>
> The engine keeps a static registry of `{const char* name, luaL_Reg* table}` at VA
> **`0x00DFD478`** — 31 rows, 12-byte stride, terminated by a zero row at
> `0x00DFD5EC`. It is the authoritative namespace→table map; nothing becomes a Lua
> namespace without a row there. Totals: **31 namespaces, 1,081 registered bindings,
> 61 of them no-op stubs**. The corrected per-namespace table is in
> [`lua_engine_bindings_audit_deep_dive.md`](lua_engine_bindings_audit_deep_dive.md),
> which supersedes this document for inventory purposes.
>
> ## 61 registered bindings are no-ops
>
> A `CONFIRMED` row here means at most "the name is registered". It does **not** mean
> the function does anything. **61 of the 1,081** rows point at the shared stub
> `0x006D5640` = `xor eax,eax; ret` (see `docs/lua_capi_comprehensive_audit.md`).
> All 6 of `Debug` is stubbed — including `Debug.Printf`, which this doc's §4.2 ranks
> as a hook target and which the scripts call **1,612 times** into a no-op. Also
> stubbed: 18 of 66 `Ai`, 15 of 24 `Junk`, 9 of 88 `Sound`, 3 of 75 `Graphics`.
> Individually noted below where this doc marks them CONFIRMED.
> **Evidence sources:**
> - `MERCENAR.EXE` (cracked, 53,482,288 bytes) — `.rdata` string analysis
> - `docs/exe_analysis_agent_a.md` — Full EXE reverse-engineering
> - `docs/exe_analysis_agent_b.md` — Independent EXE reverse-engineering
> - `docs/exe_cross_validation.md` — Cross-validated findings
> - `docs/dlc_loader_cross_reference.md` — DLC system analysis
> - `docs/dlc_extras_activation_research.md` — Extras/online research
> - `docs/teknogods_coop_research.md` — Network API analysis
> - `docs/plugin_framework_plan_a.md` — Registration table RE
> - `docs/plugin_framework_plan_c.md` — Working hook targets
> - `tools/dlc_enable_asi/dlc_enable.c` — Verified runtime hooks
> - Embedded bootstrap Lua source (verbatim from EXE offset `0x007B4EE2`)
> - DLC contract script patterns (from disassembled Xbox 360 Lua)

---

## Table of Contents

1. [Overview](#1-overview)
2. [Namespace Inventory](#2-namespace-inventory)
3. [Categorized Binding Reference](#3-categorized-binding-reference)
4. [Hookability Assessment](#4-hookability-assessment)
5. [Evidence Levels](#5-evidence-levels)
6. [Technical Context](#6-technical-context)
7. [Appendix: SendEvent Functions](#appendix-a-sendevent-functions-c--lua)
8. [Appendix: Event Listener Types](#appendix-b-event-listener-types)
9. [Appendix: Global Functions & Tables](#appendix-c-global-functions--tables)

---

## 1. Overview

### Engine Facts

| Property | Value | Confidence |
|----------|-------|------------|
| Lua version | 5.1.2 | CERTAIN (string at `0x007925B8`) |
| Number type | `float` (4 bytes) | CERTAIN (bytecode headers) |
| Source path | `D:\Projects\Mercs2_PC\mercs2\Lua-5.1.2\src\` | CERTAIN |
| Binding mechanism | `luaL_register` with `{name, func}` pairs in `.rdata` | CERTAIN |
| Registration tables location | VA `0x00798770`–`0x00799200` | CERTAIN |
| Estimated total bindings | 800–1300+ functions across ~30 namespaces | CERTAIN (range) |

> **CORRECTION (2026-07-21)** — the "Registration tables location" row is wrong twice over.
> **(a)** Those are **file offsets, not VAs**. `.rdata` maps at VA `0x00B05000` from raw
> `0x00705000`, so `VA = file_offset + 0x400000`; the tables begin at VA **`0x00B98770`**.
> **(b)** The range is **incomplete** — game tables run to file `0x0079A9A8` (VA
> `0x00B9A9A8`). Stopping at `0x00799200` truncates the **`Player`** table mid-array and
> misses `Pg`, `Object`, `Net`, `Gui`, `_GuiInternal`, `Graphics`, `Ai`, `Camera`,
> `LTILibName`, `Human`, `Junk` and more — roughly two-thirds of the API.
> The "800–1300+ / ~30 namespaces" estimate, by contrast, **holds**: the measured
> figure is **1,081 bindings across 31 namespaces**.
| Pool: ObjectScript | 2,048 slots | CERTAIN |
| GC threshold | 256 (embedded config) | CERTAIN |

### How Bindings Work

The engine registers C++ functions into named Lua tables using standard Lua 5.1
`luaL_register()`. Each namespace's binding table is a contiguous array of
`{const char* name, lua_CFunction func}` pairs (8 bytes each, two 32-bit pointers)
in the `.rdata` section, terminated by `{NULL, NULL}`. The string pointers point to
NUL-terminated ASCII names in `.rdata`; the function pointers point into `.text`.

---

## 2. Namespace Inventory

### Summary Table

| Namespace | Function Count | Evidence Level | Registration Table VA (approx) |
|-----------|---------------|----------------|-------------------------------|
| **_SYS** | 6 | CERTAIN | Inline (bootstrap at `0x007B4EE2`) |
| **Sys** | 20+ | CERTAIN | Near `0x007987F8` |
| **Net** | 12+ | CERTAIN | Near `0x00799078` |
| **Object** | 15+ | CERTAIN | Scanned from namespace strings |
| **Player** | 12+ | CERTAIN | In registration range |
| **Gui** | 15+ | CERTAIN | In registration range |
| **Ai** | 8+ | CONFIRMED | In registration range |
| **Atmosphere** | 6+ | CONFIRMED | In registration range |
| **Graphics** | 7+ | CONFIRMED | In registration range |
| **Sound** | 30+ | CERTAIN | 88 functions per Agent B |
| **VO** | 12+ | CERTAIN | Priority constants at `0x007BA92B` |
| **Weapon** | 6+ | CONFIRMED | In registration range |
| **Event** | 4 | CERTAIN | At `0x007987F8` |
| **Faction/Pursuit** | 5+ | CONFIRMED | Near `0x007B98EC` |
| **Debug** | 5+ | CONFIRMED | In registration range |
| **Boundary** | 20+ | CERTAIN | At `0x00799078` |
| **NetClient** | 8+ | CONFIRMED | At `0x007D1D00` area |
| **Save** | 12+ | CERTAIN | At `0x007B8AC4` area |
| **Localization** | 5+ | CERTAIN | At `0x007BA118` area |
| **Marker** (alias) | 13 | CERTAIN | Bootstrap code aliasing `Gui._Marker*` |
| **Music** (dynamic) | 15+ | CONFIRMED | In Sound table area |
| **Precache/LTI** | 3+ | CONFIRMED | At `0x007B6A0C` area |
| **DLC/Online** | 4+ | CERTAIN | At `0x007D9588` area |
| **Lobby** | 6+ | CERTAIN | At `0x007BBCF8` area |

> **CORRECTION (2026-07-21) — this whole table is RETRACTED.** Not one
> "Registration Table VA" in the right-hand column is a table base except `Event` @
> `0x007987F8` (file) = VA `0x00B987F8`. `Sys` is **not** near `0x007987F8` (that is
> `Event`); it is at VA `0x00B98A78` with **64** entries. `Net` and `Boundary` are
> **not** at `0x00799078` (that address is interior to the `Player` array); `Net` is
> at VA `0x00B998D0` with **92** entries. The remaining "`0x007Bxxxx` area" /
> "`0x007Dxxxx` area" values are addresses of **string literals**, not tables.
> Replace this table with the registry-derived inventory in
> [`lua_engine_bindings_audit_deep_dive.md`](lua_engine_bindings_audit_deep_dive.md) §1.4.
> The one solidly correct claim here is **`Sound` = 88**, which matches exactly.

---

## 3. Categorized Binding Reference

### 3.1 System / Core (`_SYS.*` and `Sys.*`)

#### `_SYS` — Internal Module System (C++ side)

| Function | EXE Offset | Args (inferred) | Returns | Evidence |
|----------|-----------|-----------------|---------|----------|
| `_SYS._IMPORT` | `0x007B453C` | `(env, module_name)` | loaded module | CERTAIN (bootstrap) |
| `_SYS._INHERIT` | `0x007B4ED4` | `(env, module_name)` | nil | CERTAIN (bootstrap) |
| `_SYS._DYNAMIC_IMPORT` | `0x007B4EC4` | `(env, module, callback, data)` | handle? | CERTAIN (bootstrap) |
| `_SYS._DYNAMIC_REMOVE` | (implicit) | `(env, module)` | nil | CERTAIN (bootstrap) |
| `_SYS._GETFENV` | `0x007B4E98` | `(level)` | env table | CERTAIN (bootstrap) |
| `_SYS._MODULEINDEX` | (implicit) | metatable `__index` | value | CERTAIN (bootstrap) |

#### `Sys` — System Utilities

| Function | String Offset | Evidence | Notes |
|----------|--------------|----------|-------|
| `IsDemoMode` | `0x007BA268` | CERTAIN — disassembled at VA `0x005E5670` | Reads flag at `0x01175F59` |
| `IsDLC` | `0x007D9594` | CERTAIN — hooked in ASI plugin | Per-session boolean |
| `IsOnlineConnected` | `0x007D9594` | CERTAIN — hooked in ASI plugin | Checks EA FESL connection |
| `GetPlatform` | (registered) | CONFIRMED | Returns platform string |
| `GetLanguage` | (registered) → VA `0x005E6420` | CERTAIN | Returns language string |
| `SetMasterScriptName` | `0x007BA6FC` | CERTAIN | Sets DLC/mission entry point |
| `GetMasterScriptName` | `0x007BA710` | CERTAIN | Gets current master script |
| `SetTimeScale` | (registered) | CONFIRMED | Float multiplier |
| `RequestGameState` | (registered) | CONFIRMED | State machine request |
| `LoadAsset` | `0x007B8D9C` | CERTAIN | Loads asset by name/hash |
| `UnloadAsset` | `0x007B8D90` | CERTAIN | Unloads asset |
| `ReloadAsset` | `0x007B8D84` | CERTAIN | Reloads asset |
| `AssetExists` | `0x007B8DA8` | CERTAIN | Boolean check |
| `LoadLayer` | `0x007B8DCC` | CERTAIN | Loads streaming layer |
| `UnloadLayer` | `0x007B8DC0` | CERTAIN | Unloads streaming layer |
| `ReloadLayer` | `0x007B8DB4` | CERTAIN | Reloads layer |
| `IsStaticLayer` | `0x007B8E20` | CERTAIN | Boolean check |
| `SetAssetRequestMax` | (near `0x7BA6FC`) | CONFIRMED | Streaming budget |
| `GetCharacterTemplate` | (near `0x7BA6FC`) | CONFIRMED | Character system |
| `LoadScript` | `0x007B6878` | CERTAIN | Load Lua script by name |
| `IsLoadingOrStreaming` | `0x007BA3C4` | CERTAIN | Loading state query |
| `ChangeShellState` | `0x007B6A68` | CONFIRMED | UI state machine |
| `SetStreamBlockDumping` | `0x007B9C04` | CERTAIN | Debug: dump block loading |
| `DlcMapId` | `0x007D9588` | CERTAIN | Which DLC map is active |

> **CORRECTION (2026-07-21) — 12 of these 24 rows are NOT in `Sys`.**
> Verified against the `Sys` table at VA `0x00B98A78` (64 entries). Scripts call
> `Sys.*` 178 times and `Pg.*` **1,448** times; the asset/layer API this doc puts under
> `Sys` is the single most-used part of the engine API and it is **`Pg`**:
>
> | Row | Claimed | **Actual namespace / table** | Fn VA |
> |---|---|---|---|
> | `LoadAsset` | Sys | **`Pg`** `0x00B99328` | `0x005D54C0` |
> | `UnloadAsset` | Sys | **`Pg`** | `0x005D5500` |
> | `ReloadAsset` | Sys | **`Pg`** | `0x005D5540` |
> | `AssetExists` | Sys | **`Pg`** | `0x005D53E0` |
> | `LoadLayer` | Sys | **`Pg`** | `0x005D4C80` (`Sys.LoadLayer` = 0 call sites) |
> | `UnloadLayer` | Sys | **`Pg`** | `0x005D4E40` |
> | `ReloadLayer` | Sys | **`Pg`** | `0x005D4F90` |
> | `IsStaticLayer` | Sys | **`Pg`** | `0x005D4BF0` |
> | `IsOnlineConnected` | Sys | **`Net`** `0x00B998D0` | `0x005CAD10` |
> | `ChangeShellState` | Sys | **`LTILibName`** `0x00B99C78` | `0x005C3740` |
> | `SetStreamBlockDumping` | Sys | **`Sound`** `0x00B98C98` | `0x005E3010` |
> | `LoadScript` | Sys | **`Junk`** `0x00B99E28` | **`0x006D5640` = no-op stub**, 0 call sites |
>
> `IsDLC` and `DlcMapId` are **not bindings at all** — no `luaL_Reg` row anywhere
> (strings only). Confirmed correct and in `Sys`: `IsDemoMode` (`0x005E5670`),
> `GetPlatform`, `GetLanguage` (`0x005E6420`), `SetMasterScriptName` (`0x005E5120`),
> `GetMasterScriptName` (`0x005E5050`), `SetTimeScale` (`0x005E4E70`),
> `RequestGameState` (`0x005E4AF0`), `SetAssetRequestMax`, `GetCharacterTemplate`,
> `IsLoadingOrStreaming` (`0x005E4D40`).

### 3.2 Network / Online (`Net.*`)

| Function | String Offset | Evidence | Notes |
|----------|--------------|----------|-------|
| `IsMultiplayer` | `0x007B8130` | CERTAIN | Boolean |
| `IsCoopMultiplayer` | `0x007B95D4` | CERTAIN | Boolean |
| `IsServer` | (registered) | CERTAIN | Boolean |
| `IsClient` | (registered) | CERTAIN | Boolean |
| `IsLobby` | `0x007B80F8` | CERTAIN | Boolean |
| `IsDedicated` | (registered) | CONFIRMED | Boolean |
| `IsOnlineConnected` | (registered) | CERTAIN | EA server check |
| `IsMatchmakingInternet` | (registered) | CERTAIN — hooked in ASI | Boolean |
| `IsMatchmakingLan` | (inferred) | INFERRED | Likely exists |
| `ConnectToServer` | (registered) | CERTAIN | Triggers connection |
| `StartServer` | (registered) | CERTAIN | Starts hosting |
| `EnterLobby` | `0x007B8000` | CERTAIN | Enter lobby UI |
| `EnterFriendsLobby` | `0x007B7FB4` | CERTAIN | Friends lobby |
| `ExitFriendsLobby` | `0x007B7FA0` | CERTAIN | Leave friends lobby |
| `AutoLobby` | `0x007B80C8` | CERTAIN | Auto-join lobby |
| `QuitGame` | (registered) | CONFIRMED | Exit to desktop |

#### `NetClient*` — Network Replication Functions

| Function | String Offset | Evidence |
|----------|--------------|----------|
| `NetClientAddBoundary` | `0x007D1D20` | CERTAIN |
| `NetClientRemoveBoundary` | `0x007D1D08` | CERTAIN |
| `NetClientShowMovie` | (registered) | CONFIRMED |
| `NetClientHideMovie` | (registered) | CONFIRMED |
| `NetClientFactionSetValue` | (registered) | CONFIRMED |
| `NetClientFactionStartPursuit` | (registered) | CONFIRMED |
| `NetClientSetObjectiveTraySlot` | (registered) | CONFIRMED |
| `NetClientClearObjectiveTraySlot` | (registered) | CONFIRMED |
| `NetSynchImportModule` | `0x007D1830` | CERTAIN |
| `SynchNetImportModule` | `0x007D1D90` | CERTAIN |

#### `Lobby` — Lobby Events/Callbacks

| Function | String Offset | Evidence |
|----------|--------------|----------|
| `LobbyServerAdded` | `0x007BBCF8` | CERTAIN |
| `LobbyServerUpdated` | `0x007BBD48` | CERTAIN |
| `LobbyServerRemoved` | `0x007BBD5C` | CERTAIN |

> **CORRECTION (2026-07-21)** — the `Net` rows above are essentially right (13/15 verified
> in the `Net` table at VA `0x00B998D0`), with two exceptions: **`IsCoopMultiplayer` is in
> `Player`**, not `Net` (`0x005DD830`), and **`IsMatchmakingLan` does not exist** in any
> table. Confirmed `Net` fn VAs: `IsMultiplayer` `0x005C66C0`, `IsServer` `0x005C6810`
> (210 call sites), `IsClient` `0x005C67D0`, `IsLobby` `0x005C6790`,
> `IsMatchmakingInternet` `0x005CACC0`, `ConnectToServer` `0x005C6AA0`,
> `StartServer` `0x005C6C40`, `EnterLobby` `0x005C69E0`, `QuitGame` `0x005C6D90`.
>
> **The `NetClient*` and `Lobby` sub-tables above are RETRACTED IN FULL.** All 13 names
> are absent from every `luaL_Reg` table and have zero call sites; the `0x007D1D20` /
> `0x007BBCF8` offsets are string literals. The real network-replication surface is the
> **44 `Net.SendEvent_*` bindings inside the `Net` table** (Appendix A lists their names
> correctly; it is only wrong that they are "NOT directly callable from Lua" — scripts
> call e.g. `Net.SendEvent_AddMarkerObjective(...)` 14 times).

### 3.3 Entity / Object (`Object.*`)

| Function | String Offset | Evidence | Notes |
|----------|--------------|----------|-------|
| `GetPosition` | (registered) | CONFIRMED | Returns x, y, z |
| `SetHealth` | (registered) | CONFIRMED | Float 0–1 |
| `GetHealth` | (registered) | CONFIRMED | Float 0–1 |
| `Kill` | (registered) | CONFIRMED | Instant death |
| `Remove` | (registered) | CONFIRMED | Delete entity |
| `IsAlive` | (registered) | CONFIRMED | Boolean |
| `IsValid` | (registered) | CONFIRMED | GUID validity check |
| `SetVisible` | (registered) | CONFIRMED | Show/hide |
| `PlayAnimation` | (registered) | CONFIRMED | Trigger anim |
| `GetModelName` | (registered) | CONFIRMED | Returns string |
| `SetName` | (registered) | CONFIRMED | Set entity name |
| `ApplyImpulse` | (registered) | CONFIRMED | Physics impulse |
| `SetMass` | (registered) | CONFIRMED | Physics mass |
| `OutsideBoundary` | `0x007B85B4` | CERTAIN | Event check |
| `InsideBoundary` | `0x007B85C4` | CERTAIN | Event check |
| `GetLocalizedName` | `0x007B8614` | CERTAIN | Localized entity name |

### 3.4 Player (`Player.*`)

| Function | String Offset | Evidence | Notes |
|----------|--------------|----------|-------|
| `AddBoundary` | `0x007B96A4` | CERTAIN | Add boundary region |
| `RemoveBoundary` | `0x007B9694` | CERTAIN | Remove boundary |
| `RemoveAllBoundary` | `0x007B9680` | CERTAIN | Clear all |
| `SetBoundaryCallback` | `0x007B9658` | CERTAIN | Event callback |
| `SpawnPlayer` | (registered) | CONFIRMED | Respawn player |
| `GetCash` | (registered) | CONFIRMED | Returns int |
| `SetCash` | (registered) | CONFIRMED | Set money |
| `AddFuel` | (registered) | CONFIRMED | Add fuel |
| `GetFuel` | (registered) | CONFIRMED | Get fuel |
| `SetInputEnabled` | (registered) | CONFIRMED | Enable/disable input |
| `SetCinematicMode` | (registered) | CONFIRMED | Cinematic camera |
| `GetCamera` | (registered) | CONFIRMED | Camera handle |
| `TeleportCamera` | (registered) | CONFIRMED | Move camera |
| `GetGuid` | (inferred from scripts) | INFERRED | Player entity GUID |

### 3.5 UI / HUD (`Gui.*`)

| Function | Evidence | Notes |
|----------|----------|-------|
| `CreateFlashWidget` | CONFIRMED | Create Scaleform widget |
| `PlayFlash` | CONFIRMED | Play Flash animation |
| `CallFlashScriptFunction` | CONFIRMED | Call ActionScript function |
| `CreateTextWidget` | CONFIRMED | Text display |
| `CreateImageWidget` | CONFIRMED | Image display |
| `SetWidgetVisible` | CONFIRMED | Show/hide widget |
| `MinimapCreate` | CONFIRMED | Create minimap |
| `AddObjective` | CONFIRMED | HUD objective |
| `SetFlashSwfFile` | CONFIRMED | Load SWF file |
| `SetFlashCallback` | CONFIRMED | Register Lua callback from Flash |
| `_MarkerAddOld` | CERTAIN | Legacy marker add |
| `_MarkerAdd` | CERTAIN | Blip marker add |
| `_MarkerAddTripwire` | CERTAIN | Tripwire marker |
| `_MarkerAddDisc` | CERTAIN | Disc marker |
| `_MarkerAdd3D` | CERTAIN (Agent B) | 3D marker |
| `_MarkerRemove` | CERTAIN | Remove marker |
| `_MarkerSetBlipLimit` | CERTAIN | Grouped blip limit |
| `_MarkerSetLocation` | CERTAIN | Set marker position |
| `_MarkerSetColor` | CERTAIN | Set marker color |
| `_MarkerSetFollowGuid` | CERTAIN | Attach marker to entity |
| `_MarkerSetScale` | CERTAIN | Set marker size |
| `_MarkerPulse` | CERTAIN | Start pulse animation |
| `_MarkerHaltPulse` | CERTAIN | Stop pulse |

> **CORRECTION (2026-07-21) — `Gui` is two namespaces, and the widget API is in the other one.**
> The engine registers **`Gui`** (VA `0x00B9A398`, 38 entries) *and* **`_GuiInternal`**
> (VA `0x00B99FF8`, 114 entries) as separate globals. All 9 widget/Flash rows above are
> in **`_GuiInternal`**, not `Gui`: `CreateFlashWidget` `0x005BA680`, `PlayFlash`
> `0x005BAAB0`, `CallFlashScriptFunction` `0x005BB170`, `CreateTextWidget` `0x005B7D40`,
> `CreateImageWidget` `0x005B7070`, `SetWidgetVisible` `0x005B5850`, `MinimapCreate`
> `0x005B8CB0`, `SetFlashSwfFile` `0x005BA720`, `SetFlashCallback` `0x005BAF90`.
> Scripts call `_GuiInternal.*` **266** times vs `Gui.*` 59 times — a mod hooking
> `Gui.CreateFlashWidget` would hook nothing.
>
> The 13 `_Marker*` rows **are** correctly in `Gui` (`_MarkerAdd` `0x005B3300`,
> `_MarkerAdd3D` `0x005B3AE0`, `_MarkerRemove` `0x005B4110`, …), and the `Marker`
> Lua-side alias is real: scripts call `Marker.*` 51 times (`Marker.AddBlip` ×11) while
> `Gui._MarkerAdd` is never called directly. **`AddObjective` is a no-op stub**
> (`0x006D5640`, 0 call sites) — HUD objectives go through `Net.SendEvent_AddObjective`.

### 3.6 AI / Behavior (`Ai.*`)

| Function | Evidence | Notes |
|----------|----------|-------|
| `Goal` | CONFIRMED | Define AI goal |
| `DefaultGoal` | CONFIRMED | Set default goal |
| `Squad` | CONFIRMED | Squad management |
| `Role` | CONFIRMED | AI role assignment |
| `Plan` | CONFIRMED | Create AI plan |
| `PlanSetGoal` | CONFIRMED | Set goal for plan |
| `SetPerceivability` | CONFIRMED | Stealth system |
| `Deploy` | CONFIRMED | Deploy units |
| `EveryoneOut` | CONFIRMED | Force vehicle exit |

### 3.7 Atmosphere / Environment (`Atmosphere.*`)

| Function | Evidence | Notes |
|----------|----------|-------|
| `SetSky` | CONFIRMED | Skybox |
| `SetTime` | CONFIRMED | Time of day (float) |
| `SetTimeSpeed` | CONFIRMED | Day/night speed |
| `SetLightIntensity` | CONFIRMED | Global light |
| `SetAmbientColor` | CONFIRMED | Ambient color |
| `SetRainDensity` | CONFIRMED | Weather |

> **CORRECTION (2026-07-21) — `Atmosphere` is NOT a top-level namespace.**
> It is a marker-delimited **sub-table of `Graphics`** (the rows `{"Atmosphere",
> 0xFFFFFFFF}` … `{"Atmosphere", 0xFFFFFFFE}` inside the `Graphics` array at VA
> `0x00B9A4D0`). The Lua-visible names are **`Graphics.Atmosphere.*`**. Across the 370
> decompiled scripts there are **0** occurrences of a top-level `Atmosphere.` and 15+ of
> `Graphics.Atmosphere.` — e.g. `Graphics.Atmosphere.SetValue("fAtmosphereForce", 0)`,
> `Graphics.Atmosphere.SetColorValue("uiAmbientColor", 128,128,128,255)`.
>
> Of the 6 functions listed: `SetTime` `0x005B1750`, `SetTimeSpeed` `0x005B17C0`,
> `SetLightIntensity` `0x005B1830`, `SetAmbientColor` `0x005B19E0`, `SetRainDensity`
> `0x005B2660` all exist under `Graphics.Atmosphere`. **`SetSky` is a no-op stub**
> (`0x006D5640`). The sub-table actually has **37** entries — the workhorses are the
> string-keyed generic setters `SetValue` / `SetColorValue` / `SetIntValue` and their
> getters, which this doc omits entirely.

### 3.8 Graphics (`Graphics.*`)

| Function | Evidence | Notes |
|----------|----------|-------|
| `SetBoundaryEffect` | `0x007B55DC` | CERTAIN — visual boundary effect |
| `ReloadShaders` | CONFIRMED | Force shader recompile |
| `SetGamma` | CONFIRMED | Display gamma |
| `ScreenShot` | CONFIRMED | Capture frame |
| `Bloom` | CONFIRMED | Post-process bloom |
| `MotionBlur` | CONFIRMED | Motion blur toggle |
| `Monochrome` | CONFIRMED | Grayscale effect |

> **CORRECTION (2026-07-21) — `Bloom`, `MotionBlur` and `Monochrome` are not functions.**
> They are **sub-table marker rows**: their `func` slot holds the sentinels
> `0xFFFFFFFF` (open) / `0xFFFFFFFE` (close), not a `.text` address. Calling
> `Graphics.Bloom()` is not a thing; they are tables. Real usage:
> `Graphics.Bloom.SetMultiplier`, `Graphics.Bloom.SetThreshold`,
> `Graphics.Bloom.SetBlurRadius`, `Graphics.MotionBlur.SetVelocityMultiplier`,
> `Graphics.Monochrome.SetGradient`.
>
> True shape of `Graphics` (VA `0x00B9A4D0`): 95 physical rows = **75 functions +
> 20 marker rows**, comprising 11 top-level functions (`ScreenShot` `0x005B0060`,
> `ReloadShaders` `0x005B03A0`, `SetGamma` `0x005B03B0`, `SetBoundaryEffect`
> `0x005B2B20`, `SetNumFrameSync`, `Set/GetScreenRatio`, `Set/GetShadowBaseDistance`,
> `InitTinyGeometry`, `ShowTinyGeometryObject`) plus 10 sub-tables:
> `Camera`(7), `Atmosphere`(37), `Bloom`(7), `MotionBlur`(1), `Contrast`(2),
> `Monochrome`(1), `Grainy`(1), `AA`(1), `Effect`(4), `FuelTrail`(3).
> Note `Graphics.Camera` is distinct from the separate top-level `Camera` namespace
> (VA `0x00B9A7D8`, 14 fns, 26 call sites).

### 3.9 Audio (`Sound.*`)

The Sound module has **88 registered functions** per Agent B's analysis. Key functions:

| Function | C++ VA | Evidence | Notes |
|----------|--------|----------|-------|
| `LoadBank` | (registered) | CONFIRMED | Load audio bank |
| `LoadSoundBank` | `0x005E2630` | CERTAIN | Load sound bank |
| `LoadWaveBank` | `0x005E26D0` | CERTAIN | Load wave bank |
| `UnloadBank` | (registered) | CONFIRMED | Unload bank |
| `CueSound` | `0x005E0FF0` | CERTAIN | Play a sound |
| `StopSound` | `0x005E10F0` | CERTAIN | Stop a sound |
| `PauseSound` | `0x005E11F0` | CERTAIN | Pause sound |
| `SetMasterVolume` | (registered) | CONFIRMED | Global volume |
| `SetCategoryVolume` | `0x005E12F0` | CERTAIN | Per-category volume |
| `SetCategoryPitch` | (registered) | CONFIRMED | Category pitch |
| `SetReverb` | (registered) | CONFIRMED | Reverb settings |
| `DefineReverbPreset` | (registered) | CONFIRMED | Reverb preset |
| `SetLowPassFilter` | (registered) | CONFIRMED | Audio filter |
| `CueAmbience` | (registered) | CONFIRMED | Ambient audio start |
| `StopAmbience` | (registered) | CONFIRMED | Ambient audio stop |
| `SilenceAmbience` | (registered) | CONFIRMED | Fade ambient |
| `RequestAmbienceBank` | (registered) | CONFIRMED | Streaming request |
| `OpenStreamFile` | `0x007B9A10` | CERTAIN | Open audio stream |
| `CloseStreamFile` | `0x007B9A00` | CERTAIN | Close audio stream |

#### Dynamic Music Subsystem

| Function | Evidence | Notes |
|----------|----------|-------|
| `SetDynamicMusic` | `0x005E16E0` — CERTAIN | Enable dynamic music |
| `SetFactionMusic` | CONFIRMED | Set faction theme |
| `AddFactionMusic` | CONFIRMED | Add faction cue |
| `LockFactionMusic` | CONFIRMED | Lock current faction |
| `SetActionLevelsMusic` | CONFIRMED | Action intensity |
| `LockActionLevelMusic` | CONFIRMED | Lock action level |
| `TransitionMusic` | `0x005E1600` — CERTAIN | Music transition |
| `BindMusicCue` | CONFIRMED | Bind cue to state |
| `AddMusicState` | CONFIRMED | Add music state |
| `AddMusicTransition` | CONFIRMED | Transition rule |
| `SetSourceMusic` | CONFIRMED | Source music |
| `SetSourceEnterMusic` | CONFIRMED | Enter region cue |
| `SetSourceExitMusic` | CONFIRMED | Exit region cue |
| `ActivateFactionRegionMusic` | CONFIRMED | Region-faction cue |
| `SetHijackMusic` | CONFIRMED | Override music |

> **CORRECTION (2026-07-21)** — `Sound` is one of the best sections in this document.
> The namespace is real (VA `0x00B98C98`), the **88** count is exact, and 6 of 7 VA
> claims verify: `LoadSoundBank` `0x005E2630` ✓, `CueSound` `0x005E0FF0` ✓ (91 call
> sites), `StopSound` `0x005E10F0` ✓, `PauseSound` `0x005E11F0` ✓, `SetCategoryVolume`
> `0x005E12F0` ✓, `SetDynamicMusic` `0x005E16E0` ✓, `TransitionMusic` `0x005E1600` ✓.
> One miss: **`LoadWaveBank` is `0x005E26B0`, not `0x005E26D0`**. `OpenStreamFile`
> `0x005E4020` and `CloseStreamFile` `0x005E40D0` are in `Sound` as claimed (the
> `0x007B9A10`/`0x007B9A00` values are string addresses). **"Music" is not a separate
> namespace** — the dynamic-music functions are rows inside `Sound`
> (e.g. `Sound.AddMusicTransition` `0x005E2110`, 66 call sites). 9 of the 88 `Sound`
> rows are no-op stubs.

### 3.10 Voice-Over (`VO.*`)

| Function / Field | Evidence | Notes |
|-----------------|----------|-------|
| `VO.PRIORITY_SCRIPTED_BRIEFING = 1` | CERTAIN (`0x007BA92B`) | Priority constant |
| `VO.PRIORITY_SCRIPTED_CONTRACT = 2` | CERTAIN | Priority constant |
| `VO.PRIORITY_SCRIPTED_BOUNDTIES = 3` | CERTAIN | Priority constant |
| `VO.PRIORITY_SCRIPTED_FREEPLAY = 4` | CERTAIN | Priority constant |
| `AddSequence` | `0x005EA3C0` — CERTAIN | Add VO sequence |
| `RemoveSequence` | `0x005EA470` — CERTAIN | Remove sequence |
| `Cue` | `0x005E9DE0` — CERTAIN | Play VO |
| `CueWithoutSubtitles` | `0x005E9F40` — CERTAIN | Play VO, no subs |
| `Cancel` | CONFIRMED | Cancel VO |
| `CancelAll` | CONFIRMED | Cancel all VO |
| `Pause` | CONFIRMED | Pause VO |
| `PauseAll` | CONFIRMED | Pause all VO |
| `Unpause` | CONFIRMED | Resume VO |
| `UnpauseAll` | CONFIRMED | Resume all VO |
| `SetCinematicMode` | `0x005EA310` — CERTAIN | VO cinematic mode |

### 3.11 Weapon / Combat (`Weapon.*`)

| Function | Evidence | Notes |
|----------|----------|-------|
| `GetClipAmmo` | CONFIRMED | Current magazine |
| `SetClipAmmo` | CONFIRMED | Set magazine |
| `GetReserveAmmo` | CONFIRMED | Reserve ammo |
| `SetReserveAmmo` | CONFIRMED | Set reserve |
| `IsDesignator` | CONFIRMED | Laser designator check |
| `IsPrimary` | CONFIRMED | Primary weapon check |

### 3.12 Event System (`Event.*`)

| Function | C++ VA | Evidence | Notes |
|----------|--------|----------|-------|
| `Event.Create` | `0x005F69F0` | CERTAIN (disassembled) | `push 0; call 0x005F6660` |
| `Event.CreatePersistent` | `0x005F6A00` | CERTAIN (disassembled) | `push 1; call 0x005F6660` |
| `Event.Delete` | `0x005F6A10` | CERTAIN | Delete event handle |
| `Event.Post` | `0x005F6A90` | CERTAIN | Fire/dispatch event |

### 3.13 Contract / Mission

| Function | String Offset | Evidence | Notes |
|----------|--------------|----------|-------|
| `ContractActivated` | `0x007B8AB0` | CERTAIN | Contract starts |
| `ContractCompleted` | `0x007B8A88` | CERTAIN | Contract done |
| `ContractCancelled` | `0x007B8A9C` | CERTAIN | Contract cancelled |
| `Completed` | `0x007B98EC` | CERTAIN | In Faction/Pursuit table |
| `Failed` | `0x007B98E4` | CERTAIN | In Faction/Pursuit table |

### 3.14 Boundary System (Player/Object)

| Function | String Offset | C++ VA | Evidence |
|----------|--------------|--------|----------|
| `AddBoundary` | `0x007B96A4` | `0x005DC900` | CERTAIN |
| `RemoveBoundary` | `0x007B9694` | `0x005DCA30` | CERTAIN |
| `RemoveAllBoundary` | `0x007B9680` | `0x005DCB30` | CERTAIN |
| `SetBoundaryCallback` | `0x007B9658` | `0x005DCE90` | CERTAIN |
| `GetBoundaryRadius` | `0x007B8B48` | (registered) | CERTAIN |
| `SetBoundaryRadius` | `0x007B8B5C` | (registered) | CERTAIN |
| `IsPointInBoundary` | `0x007B8B84` | (registered) | CERTAIN |
| `GetLineRegionPoints` | `0x007B8B70` | (registered) | CERTAIN |
| `IsPositionOutBoundary` | `0x007B9640` | `0x005DD040` | CERTAIN |
| `IsBoundaryDeath` | `0x007B9630` | `0x005DD040` | CERTAIN |
| `SetOutBoundary` | `0x007B96D0` | `0x005DC160` | CERTAIN |
| `GetOutBoundary` | `0x007B96C0` | `0x005DC720` | CERTAIN |
| `GetAllBoundaryGuid` | `0x007B966C` | `0x005DCC60` | CERTAIN |
| `IsInWarningZone` | `0x007B96B0` | `0x005DC810` | CERTAIN |
| `GetWarningRadius` | `0x007B8B20` | (registered) | CERTAIN |
| `SetWarningRadius` | `0x007B8B34` | (registered) | CERTAIN |
| `GetTetherDiameterStart` | `0x007B8B08` | (registered) | CERTAIN |
| `GetTetherDiameterEnd` | `0x007B8AF0` | (registered) | CERTAIN |
| `SetBoundaryEffect` | `0x007B55DC` | (registered) | CERTAIN |

> **CORRECTION (2026-07-21)** — there is **no `Boundary` namespace** (0 call sites). These
> 19 functions are split across three real namespaces, and **4 of the 10 "C++ VA" claims
> are off by one table row** — a classic symptom of anchoring on a string address and
> stepping the wrong way:
>
> | Function | Real namespace | Claimed VA | **Actual `luaL_Reg` func VA** |
> |---|---|---|---|
> | `SetBoundaryCallback` | `Player` | `0x005DCE90` | **`0x005DCD60`** |
> | `IsPositionOutBoundary` | `Player` | `0x005DD040` | **`0x005DCE90`** ← the VA wrongly given to `SetBoundaryCallback` |
> | `IsBoundaryDeath` | `Player` | `0x005DD040` | `0x005DD040` ✓ |
> | `GetAllBoundaryGuid` | `Player` | `0x005DCC60` | **`0x005DCC20`** |
>
> (The doc assigning `0x005DD040` to *both* `IsPositionOutBoundary` and
> `IsBoundaryDeath` was the tell — they are distinct functions.)
>
> Verified correct, all in **`Player`** (VA `0x00B98FC0`): `AddBoundary` `0x005DC900`,
> `RemoveBoundary` `0x005DCA30`, `RemoveAllBoundary` `0x005DCB30`, `SetOutBoundary`
> `0x005DC160`, `GetOutBoundary` `0x005DC720`, `IsInWarningZone` `0x005DC810`.
> In **`Pg`** (VA `0x00B99328`), not Player: `GetBoundaryRadius` `0x005D7920`,
> `SetBoundaryRadius` `0x005D78B0`, `IsPointInBoundary` `0x005D6D60`,
> `GetLineRegionPoints` `0x005D7160`, `GetWarningRadius` `0x005D79E0`,
> `SetWarningRadius` `0x005D7970`, `GetTetherDiameterStart` `0x005D7A30`,
> `GetTetherDiameterEnd` `0x005D7A80`. In **`Graphics`**: `SetBoundaryEffect`
> `0x005B2B20`.

### 3.15 Save / Load

| Function | Offset | Evidence | Notes |
|----------|--------|----------|-------|
| `SaveGame` | `0x007B8AC4` | CERTAIN | Trigger save |
| `SaveComplete` | `0x007B44FC` | CERTAIN | Save done event |
| `LoadGame` | (registered) | CONFIRMED | Load save |
| `SaveData` | (registered) | CONFIRMED | Write data |
| `LoadSingleton` | (registered) | CONFIRMED | Load singleton state |
| `SaveSingleton` | (registered) | CONFIRMED | Save singleton state |
| `ResetSingleton` | (registered) | CONFIRMED | Reset singleton |
| `SetLuaSaveVersion` | `0x005E6120` | CERTAIN | Set save format version |
| `InitialSaveData` | (registered) | CONFIRMED | Initialize save |
| `Autosave` / `RequestAutosave` | `0x005E61F0` | CERTAIN | Request autosave |
| `IsAutosaveEnabled` | `0x005E65E0` | CERTAIN | Query |
| `SetAutosaveEnabled` | `0x005E6610` | CERTAIN | Set |
| `ForceNextAutosave` | `0x005E6670` | CERTAIN | Force next |
| `ClientRestorePreSaveCash` | (registered) | CONFIRMED | Co-op save |
| `ClientReimburseForSave` | (registered) | CONFIRMED | Co-op save |
| `saveGameSlot` | `0x007BC190` | CERTAIN | Slot management |
| `addSaveGame` | `0x007BC1A0` | CERTAIN | Add entry |
| `clearSaveGames` | `0x007BC6C4` | CERTAIN | Clear all |
| `saveProfile` | `0x007BC628` | CERTAIN | Save profile |

> **CORRECTION (2026-07-21)** — no `Save` namespace. The 5 autosave/version functions are
> in **`Sys`** and their VAs are all correct (`SetLuaSaveVersion` `0x005E6120`,
> `RequestAutosave` `0x005E61F0`, `IsAutosaveEnabled` `0x005E65E0`, `SetAutosaveEnabled`
> `0x005E6610`, `ForceNextAutosave` `0x005E6670`). `SaveGame` `0x005D7CB0` and `LoadGame`
> `0x005D7D30` are in **`Pg`**. **Seven rows name nothing at all** — `SaveData`,
> `LoadSingleton`, `SaveSingleton`, `ResetSingleton`, `InitialSaveData`,
> `ClientRestorePreSaveCash`, `ClientReimburseForSave` are absent from every `luaL_Reg`
> table; the four lowercase `saveGameSlot` / `addSaveGame` / `clearSaveGames` /
> `saveProfile` are likewise string-only (Scaleform/shell identifiers, not bindings).

### 3.16 Localization

| Function | Offset/VA | Evidence |
|----------|----------|----------|
| `AddStringDb` | `0x007BA128` → VA `0x005E6180` | CERTAIN |
| `ClearStringDb` | `0x007BA118` → VA `0x005E61E0` | CERTAIN |
| `GetLocalizedName` | `0x007B8614` | CERTAIN |
| `GetLanguage` | (registered) → VA `0x005E6420` | CERTAIN |
| `GetLanguageName` | `0x007B5750` | CERTAIN |
| `GetLanguageNum` | `0x007B5740` | CERTAIN |

> **CORRECTION (2026-07-21)** — no `Localization` namespace (0 call sites). All six exist,
> spread across three namespaces: **`Sys`** — `AddStringDb` `0x005E6180` ✓,
> `ClearStringDb` `0x005E61E0` ✓, `GetLanguage` `0x005E6420` ✓ (the three VA claims here
> are exactly right); **`Object`** — `GetLocalizedName` `0x005CC250`; **`Gui`** —
> `GetLanguageName` `0x005B4BC0`, `GetLanguageNum` `0x005B4B80`.

### 3.17 Debug / Development

| Function | Evidence | Notes |
|----------|----------|-------|
| `Printf` | CONFIRMED | Debug print |
| `LogError` | CONFIRMED | Error log |
| `LogWarning` | CONFIRMED | Warning log |
| `LogInfo` | CONFIRMED | Info log |
| `GetCallstack` | CONFIRMED | Stack trace |
| `DebugStateMachine` | CONFIRMED | SM debug |
| `PrintStateMachine` | CONFIRMED | SM dump |
| `LTIGetPrecacheBypass` | `0x007BA384` | CERTAIN |

> **CORRECTION (2026-07-21) — the entire `Debug` namespace is stubbed.**
> `Debug` is real (VA `0x00B98828`) and has exactly the **6** entries listed, but
> **all 6 point at `0x006D5640` = `xor eax,eax; ret`**. `Debug.Printf` is called
> **1,612 times** by the shipped scripts and does nothing — this is why `pmc_bb`
> MinHooks the stub itself to recover the log stream (see
> `memory/pmc-bb-native-lua-logging.md`). `DebugStateMachine` and `PrintStateMachine`
> are **not** in `Debug` — they are in **`ObjectState`** (VA `0x00B995B0`), and also
> stubbed. `LTIGetPrecacheBypass` is in **`Sys`** (`0x005E4F70`) and is *not* a stub.

### 3.18 DLC / Online Subsystem

| Function | String Offset | Evidence |
|----------|--------------|----------|
| `IsDLC` | `0x007D9594` | CERTAIN — hooked |
| `DlcMapId` | `0x007D9588` | CERTAIN |
| `addLeaderboardEntry` | `0x007D01B4` | CERTAIN |
| `removeLeaderboardEntries` | `0x007D0120` | CERTAIN |
| `LeaderboardScore` | `0x007BD50C` | CERTAIN |
| `ScriptName` | `0x007CA54C` | CERTAIN |

### 3.19 Precache / LTI System

| Function/Event | Offset | Evidence |
|---------------|--------|----------|
| `LTIPrecacheSmokeDone` | `0x007B6A0C` | CERTAIN |
| `LTIPrecacheDone` | `0x007B6A24` | CERTAIN |
| `LTIGetPrecacheBypass` | `0x007BA384` | CERTAIN |

---

## 4. Hookability Assessment

### 4.1 Hook Technique: Scan-and-Patch (Plan C Pattern)

All `luaL_Reg`-registered functions can be hooked using the proven pattern:
1. Find the string in `.rdata`
2. Find the cross-reference (luaL_Reg entry) that stores its VA
3. Read/overwrite the adjacent function pointer
4. VirtualProtect for write access

This works for **every function listed above**. The existing `dlc_enable.asi`
demonstrates this with three live hooks.

### 4.2 Priority Hook Targets for Modding

| Target | Category | Call Frequency | Modding Value | Difficulty |
|--------|----------|---------------|---------------|------------|
| `Atmosphere.SetTime` | Environment | On-demand | HIGH — "permanent daytime" mod | Easy |
| `Player.GetCash` / `SetCash` | Player | On-demand | HIGH — economy mods | Easy |
| `Object.GetHealth` / `SetHealth` | Entity | Frequent (per-frame for HUD) | HIGH — god mode, damage mods | Easy |
| `Sound.SetMasterVolume` | Audio | On-demand | MEDIUM — volume presets | Easy |
| `Sys.SetTimeScale` | System | On-demand | HIGH — slow-mo mods | Easy |
| `Sys.LoadLayer` / `UnloadLayer` | Streaming | On-demand | HIGH — layer control | Easy |
| `Sys.SetMasterScriptName` | DLC | Once at boot | HIGH — custom campaigns | Easy |
| `import` (global Lua) | Scripting | Frequent | VERY HIGH — script override | Medium |
| `Event.Post` | Events | Frequent | HIGH — event bus mods | Medium |
| `Ai.Goal` / `Ai.Plan` | AI | On-demand | HIGH — AI behavior mods | Medium |
| `Gui.CreateFlashWidget` | UI | On-demand | HIGH — custom HUD | Hard |
| `Gui.CallFlashScriptFunction` | UI | Frequent | HIGH — UI interception | Hard |
| `Net.ConnectToServer` | Network | On-demand | MEDIUM — server redirect | Medium |

> **CORRECTION (2026-07-21) — 6 of these 13 hook targets are wrong or useless.**
> This table is the most actionable part of the document, so the errors are the most
> costly. Corrected targets:
>
> | Listed target | Problem | **Use instead** |
> |---|---|---|
> | `Atmosphere.SetTime` | No such global. | **`Graphics.Atmosphere.SetTime`** `0x005B1750`; for a daylight mod the real lever is `Graphics.Atmosphere.SetValue`/`SetColorValue` (string-keyed), `0x005B1200` / `0x005B1430`. |
> | `Sys.LoadLayer` / `UnloadLayer` | Wrong namespace. | **`Pg.LoadLayer`** `0x005D4C80` / **`Pg.UnloadLayer`** `0x005D4E40`. |
> | `Gui.CreateFlashWidget` | Wrong namespace. | **`_GuiInternal.CreateFlashWidget`** `0x005BA680`. |
> | `Gui.CallFlashScriptFunction` | Wrong namespace. | **`_GuiInternal.CallFlashScriptFunction`** `0x005BB170`. |
> | `Ai.Plan` / `Ai.PlanSetGoal` | Both are **no-op stubs** (`0x006D5640`), 0 call sites. | For AI behaviour hook **`Ai.Goal`** `0x005A70B0` (120 call sites) or `Ai.Squad` `0x005A7580`. |
> | `Event.Post` | Real (`0x005F6A90`) but only 3 call sites. | **`Event.Create`** `0x005F69F0` (557 sites) / **`Event.Delete`** `0x005F6A10` (513 sites) carry the traffic. |
>
> Verified-good as listed: `Player.GetCash` `0x005DF440` / `SetCash` `0x005DF480`,
> `Object.GetHealth` `0x005CBDB0` / `SetHealth` `0x005CBEE0`, `Sys.SetTimeScale`
> `0x005E4E70`, `Sys.SetMasterScriptName` `0x005E5120`, `Net.ConnectToServer`
> `0x005C6AA0`, `Sound.SetMasterVolume`.
>
> Also note §4.1's claim that the `.rdata` func-pointer swap "works for **every**
> function listed above" is **false in practice on the retail PC build**: the EXE is
> SecuROM-protected and writing a `luaL_Reg` `.func` slot trips anti-tamper and crashes
> early init. `.text` MinHook detours are tolerated; `.rdata` pointer swaps are not.
> See `memory/pmc-bb-native-lua-logging.md` (confirmed live, 2026-06-08).

### 4.3 Per-Namespace Hookability Summary

| Namespace | Hookable? | Safety | Call Pattern |
|-----------|-----------|--------|-------------|
| `_SYS` | Yes but risky | LOW — module system is fragile | Per-import() |
| `Sys` | Yes | HIGH | On-demand |
| `Net` | Yes | HIGH | On-demand |
| `Object` | Yes | MEDIUM — some may be per-frame | Mixed |
| `Player` | Yes | HIGH | On-demand |
| `Gui` | Yes | MEDIUM — Scaleform integration complex | Event-driven |
| `Ai` | Yes | MEDIUM — state machine side effects | On-demand |
| `Atmosphere` | Yes | HIGH | On-demand |
| `Graphics` | Yes | HIGH | On-demand |
| `Sound` | Yes | HIGH | On-demand |
| `VO` | Yes | HIGH | On-demand |
| `Weapon` | Yes | HIGH | On-demand |
| `Event` | Yes | MEDIUM — core dispatch, race conditions | Frequent |
| `Boundary` | Yes | HIGH | On-demand |
| `Save` | Yes | MEDIUM — save corruption risk | On-demand |
| `Debug` | Yes | HIGH | On-demand |

---

## 5. Evidence Levels

### CERTAIN — Direct binary verification

These are confirmed by:
- Verbatim string presence in the EXE `.rdata` section with exact file offsets
- Disassembled C++ code showing the function's behavior
- Working runtime hooks (ASI plugin proves the binding exists and is callable)
- Embedded Lua source code extracted verbatim from the EXE

**Functions with CERTAIN evidence:** ~120+ (all items with specific offsets above)

### CONFIRMED — Multiple corroborating sources

These are confirmed by:
- Named in the EXE analysis docs by two independent agents
- Referenced in embedded Lua code snippets (bootstrap, Marker initialization)
- Present in disassembled DLC contract script patterns
- String found in `.rdata` but exact offset not individually documented

**Functions with CONFIRMED evidence:** ~80+ (the registration table range is verified, individual entries inferred from naming patterns and cross-references)

### INFERRED — Logical deduction from context

These are inferred from:
- Similar functions existing (if `GetCash` exists, `SetCash` likely does)
- Game behavior requiring the binding (players can teleport, so a teleport function exists)
- References in game scripts (call sites in extracted bytecode strings)

**Functions with INFERRED evidence:** ~20

> **CORRECTION (2026-07-21) — the CERTAIN/CONFIRMED grades do not mean what §5 says.**
> §5 defines CERTAIN as including "verbatim string presence in the EXE `.rdata` section
> with exact file offsets". **String presence is not evidence of a binding.** `IsDLC`,
> `DlcMapId`, `LobbyServerAdded`, all 8 `NetClient*` names, and 7 `Save` names are
> present as strings and are **not bound to anything** — the deep-dive companion makes
> the same point at its §2.3. A row is only confirmed once the `{name_ptr, func_ptr}`
> pair has been read and `func_ptr` resolved into `.text`.
>
> Measured over a 227-row sample of §3: **194 names exist in some `luaL_Reg` table
> (85%), 33 exist in none (15%), and only 130 (57%) also carry the correct namespace.**
> Of 30 rows that gave an explicit C++ function VA, 24 matched exactly, 4 were off by
> one table row, and 2 duplicated one VA across two functions.
>
> **Sections that verified clean** (namespace and membership both correct):
> §3.3 `Object` (16/16, VA `0x00B99608`, 87 entries), §3.4 `Player` (12/13 — only
> `SpawnPlayer` is really `Pg`), §3.6 `Ai` (9/9, VA `0x00B9A938` — but `Plan` and
> `PlanSetGoal` are stubs), §3.11 `Weapon` (6/6, VA `0x00B98860`), §3.12 `Event`
> (4/4 with **all four VAs exact**: `0x005F69F0`/`0x005F6A00`/`0x005F6A10`/`0x005F6A90`;
> the `push 0` / `push 1` → `call 0x005F6660` disassembly claim reproduces byte-for-byte
> at `0x005F69F6`), §3.10 `VO` (11/11, VA `0x00B988B0`, all 5 VAs exact), and
> Appendix C's `_SYS` bootstrap set (6/6, VA `0x00B9A854`).

### NOT FOUND — Expected but unconfirmed

| Expected Function | Why Expected | Status |
|------------------|-------------|--------|
| `SpawnObject` / `CreateObject` | Game spawns entities at runtime | String not yet located |
| `GetVelocity` / `SetVelocity` | Vehicles have physics | String not yet located |
| Vehicle-specific namespace | Vehicles are major gameplay feature | May be in Object.* instead |
| `Faction.SetValue` / `Faction.GetValue` | Faction reputation system | NetClient version exists |

> **CORRECTION (2026-07-21)** — three of these four resolve:
> - **`GetVelocity` EXISTS** — `Object.GetVelocity` `0x005CC700`, 5 call sites. (`SetVelocity` genuinely does not exist.)
> - **"Vehicle-specific namespace"** — **`Vehicle` is a real namespace**, VA `0x00B98918`, **40 bindings**, 276 call sites (`Vehicle.GetDriver` `0x005E7030` ×112). It is not folded into `Object.*`. This doc omits it entirely.
> - **`Faction.*`** — there is no `Faction` namespace, but **`FactionZone`** (VA `0x00B98FA4`, 1 entry) and **`Report`** (VA `0x00B98F64`, 5 entries, 8 call sites) exist; the reputation surface reached from Lua is `Net.SendEvent_*` plus `Report.*`.
> - `SpawnObject` / `CreateObject` — correctly NOT FOUND; spawning is **`Pg.Spawn`** `0x005D5D20` (103 call sites).

---

## 6. Technical Context

### 6.0 Verified Lua C API VAs — Critical Functions

> **IMPORTANT — VA CORRECTIONS (2026-05-20)**
>
> Earlier reverse-engineering passes incorrectly identified two VAs. These
> corrections have been verified across 10+ independent call sites in the
> binary. All future ASI plugins and hook code must use the corrected addresses.
>
> | Wrong VA | Was claimed to be | Actually is |
> |----------|-------------------|-------------|
> | **0x0085F050** | `luaL_loadbuffer` | **`luaL_typerror`** (error raiser) |
> | **0x00868AD0** | `lua_pcall` | **`luaD_pcall`** (internal, not public API) |

#### Definitive VA Table

| Function | VA | Type | LTCG Calling Convention |
|----------|-----|------|------------------------|
| **`luaL_loadbuffer`** | **0x00860240** | Public API | EAX=name, EDX=L, stack=[buff, sz]; caller cleans 8 bytes |
| **`lua_pcall`** | **0x0085DF50** | Public API | EAX=L, ECX=errfunc, EDI=nresults, stack=[nargs]; caller cleans 4 bytes |
| `luaD_pcall` | 0x00868AD0 | Internal | EAX=L, EDX=ef, stack=[func_ptr, ud, old_top]; caller cleans 12 bytes |
| `luaL_typerror` | 0x0085F050 | Public API | EAX=L, EDI=narg, stack=[expected_type_name] |
| `luaL_argerror` | 0x0085EF70 | Public API | — |
| `luaD_call` | 0x008688D0 | Internal | — |
| `luaL_checklstring` | 0x0085D860 | Public API | — |
| `f_call` | 0x0085DF30 | Static | Callback used internally by `lua_pcall` for `luaD_pcall` |
| Type name table | 0x00B920D4 | Data | Array of Lua type name strings |

#### cdecl Wrappers (standard `int f(lua_State* L)`)

| Function | VA | Notes |
|----------|-----|-------|
| `luaB_loadstring` | 0x00860FC0 | Wraps `luaL_loadbuffer` (0x00860240) |
| `luaB_pcall` | 0x008615F0 | Calls `luaD_pcall` (0x00868AD0) directly, NOT `lua_pcall` |

#### Call Site Examples

**`luaL_loadbuffer`** — from `luaB_loadstring` at 0x00861043:
```asm
mov eax, ebx       ; eax = chunkname (name)
push ecx           ; push sz
push ebp           ; push buff
mov edx, esi       ; edx = L
call 0x00860240    ; luaL_loadbuffer
add esp, 8         ; caller cleans 2 stack args
```

**`lua_pcall`** — canonical pattern (10+ callers):
```asm
push <nargs>       ; 6A xx or register push
xor ecx, ecx      ; errfunc = 0
xor edi, edi       ; nresults = 0 (or "or edi, -1" for LUA_MULTRET)
mov eax, esi       ; eax = L
call 0x0085DF50    ; lua_pcall
```

### 6.1 Lua State Layout (Lua 5.1.2 + float)

```c
// lua_State memory layout (verified from hook code)
// Offset +0x08: StkId top (pointer to TValue*)
//
// TValue layout (float Lua build):
//   Offset +0x00: Value union (4 bytes — float, int, pointer)
//   Offset +0x04: int tt (type tag)
//   Total: 8 bytes per TValue
//
// Type tags:
//   LUA_TNIL     = 0
//   LUA_TBOOLEAN = 1
//   LUA_TNUMBER  = 3
//   LUA_TSTRING  = 4
//   LUA_TTABLE   = 5
//   LUA_TFUNCTION = 6
```

### 6.2 Registration Table Format

```c
// Each namespace has a contiguous array in .rdata:
typedef struct {
    const char* name;       // 4 bytes: VA pointing to NUL-terminated string
    lua_CFunction func;     // 4 bytes: VA pointing into .text
} luaL_Reg;                 // 8 bytes total per entry

// Array terminated by {NULL, NULL}
// Known table ranges:
//   VA 0x00798770 – 0x00799200  (main registration area)
//   Event table: 0x007987F8
//   Net/Boundary table: 0x00799078
//   Sound table: (within main range)
```

### 6.3 Script Module Pattern (from DLC contracts)

Every game script follows this pattern:

```lua
inherit("MrxTaskContract")    -- Base class inheritance
import("MrxUtil")             -- Utility library
import("MrxObjectiveHelper")  -- Objective system

function LoadAssets(self)
    MrxLayerManager.Add(tLayers, callback, {self})
end

function Activated(self)
    MrxTaskContract.Activated(self)   -- MUST call parent
    self:_CreateEvent(Event.TimerRelative, {5}, callback, {self})
end

function Cancel(self)
    MrxTaskContract.Cancel(self)
end
```

This shows the Lua script APIs at work: `inherit()`, `import()`, `Event.*`,
and the MrxTaskContract base class providing `Activated`, `Cancel`, `Cleanup`,
`Complete`, `Fail` lifecycle methods.

### 6.4 Embedded Widget Access Pattern

```lua
-- At EXE offset 0x007BBA10:
if _MODULES and _MODULES.mrxgui then
    local s = _MODULES.mrxgui.GetWidgetByName("Shell")
    if s and s.CustomData.oFlash then
        return s.CustomData.oFlash.BasicData.uId
    end
end
```

This reveals: `_MODULES.mrxgui.GetWidgetByName()` is a Lua-side API for
accessing Scaleform Flash widgets. The `CustomData.oFlash.BasicData.uId`
path shows the widget object structure.

---

## Appendix A: SendEvent Functions (C++ → Lua)

These 44 functions dispatch events from C++ into the Lua event system. They are
NOT directly callable from Lua but represent events that Lua scripts can listen for:

```
SendEvent_AddObjective              SendEvent_RemoveObjective
SendEvent_AddRadarObjective         SendEvent_RemoveRadarObjective
SendEvent_AddMarkerObjective        SendEvent_RemoveMarkerObjective
SendEvent_AddPdaObjective           SendEvent_RemovePdaObjective
SendEvent_TeleportPlayer            SendEvent_TeleportPlayerToHardPoint
SendEvent_Fanfare                   SendEvent_CloseFanfare
SendEvent_ObjectiveMessage          SendEvent_Support
SendEvent_AddSupportItem            SendEvent_RemoveSupportItem
SendEvent_RecruitsUnlocked          SendEvent_RevivePlayer
SendEvent_ShowMovie                 SendEvent_HideMovie
SendEvent_ShowMessage               SendEvent_TextFanfare
SendEvent_CardFanfare               SendEvent_HVTFanfare
SendEvent_UnlockFanfare             SendEvent_BatchUnlockFanfare
SendEvent_ForceClientTether         SendEvent_PursuitMessage
SendEvent_AddHqPdaBlip              SendEvent_RemoveHqPdaBlip
SendEvent_AddPmcPdaBlip             SendEvent_RemovePmcPdaBlip
SendEvent_AddPDAMission             SendEvent_RemovePDAMission
SendEvent_JoinPOForceRequest        SendEvent_EnableHeroWeapons
SendEvent_AddDangerousBuilding      SendEvent_RemoveDangerousBuilding
SendEvent_SetOccupiedDangerousBuilding  SendEvent_AddRandomDangerousBuilding
SendEvent_RequestPosition           SendEvent_SetObjectiveTraySlotText
SendEvent_SetObjectiveTraySlotImage SendEvent_ClearObjectiveTraySlot
```

---

## Appendix B: Event Listener Types

These are the typed event categories that scripts can register listeners for
using `self:_CreateEvent(EventType, params, callback, data)`:

| Event Type | Category | Notes |
|------------|----------|-------|
| `Event` | Generic | Base event type |
| `WeaponEvent` | Combat | Weapon-related triggers |
| `ScriptEvent` | Scripting | Script-to-script communication |
| `HumanAnimationNearlyCompleted` | Animation | Near-end callback |
| `HumanActionComplete` | Animation | Action finished |
| `AirstrikeDeliveryReady` | Support | Airstrike available |
| `GameStateChange` | System | Game state machine |
| `TimerRelative` | Timer | Relative delay (seconds) |
| `GuiGameTimer` | UI/Timer | Game timer display |
| `GuiVehicleDisguiseUpdate` | UI | Vehicle disguise HUD |
| `GuiVehicleNameUpdate` | UI | Vehicle name display |
| `GuiPlayerReceiveDamage` | UI | Damage indicator |
| `GuiGameStateChange` | UI | UI state sync |
| `GuiSeatMenuEnter` | UI | Vehicle seat menu |
| `GuiSupportMenuEnter` | UI | Support menu |
| `GuiWeaponEquippedUpdate` | UI | Weapon HUD |
| `GuiAnimateUpdate` | UI | Animation display |
| `GuiPauseStateChange` | UI | Pause menu |
| `GuiReticleUpdate` | UI | Crosshair update |
| `GuiVehicleHealthUpdate` | UI | Vehicle health HUD |
| `GuiHealthUpdate` | UI | Player health HUD |
| `GuiMinimapUpdate` | UI | Minimap refresh |
| `GuiAmmoUpdate` | UI | Ammo counter |
| `GuiUpdate` | UI | General UI refresh |
| `ObjectIsVisible` | Entity | Visibility change |
| `ObjectPhysicsEvent` | Entity | Physics collision/trigger |
| `ObjectIsGrounded` | Entity | Ground contact |
| `ObjectIsReady` | Entity | Initialization complete |
| `ObjectHibernation` | Entity | Sleep/wake |
| `ObjectTowed` | Entity | Being towed |
| `ObjectWinched` | Entity | Being winched |
| `ObjectInSeat` | Entity | Entered vehicle seat |
| `Boundary` | Spatial | Boundary event |
| `ObjectProximity` | Spatial | Distance trigger |
| `ObjectHealthLessThan` | Entity | Health threshold |
| `ObjectHealth` | Entity | Health change |

---

## Appendix C: Global Functions & Tables

These are registered at the global (`_G`) level, not in namespaces:

| Global | Type | Evidence | Purpose |
|--------|------|----------|---------|
| `import(module)` | function | CERTAIN (bootstrap) | Synchronous module load |
| `dynamic_import(module, cb, data)` | function | CERTAIN (bootstrap) | Async module load |
| `inherit(module)` | function | CERTAIN (bootstrap) | Prototype inheritance |
| `dynamic_remove(module)` | function | CERTAIN (bootstrap) | Unload module |
| `_G._MODULES` | table | CERTAIN (bootstrap) | Module registry |
| `_MODULESMETATABLE` | table | CERTAIN (bootstrap) | Module lazy-load meta |
| `_G.Marker` | table | CERTAIN (embedded code) | Marker API (aliases Gui._Marker*) |
| `dofile` | function | `0x007B4558` — CERTAIN | Standard Lua |
| `loadfile` | function | `0x007B4560` — CERTAIN | Standard Lua |
| `loadstring` | function | `0x007E8D44` — CERTAIN | Standard Lua |

### MrxTaskContract Lifecycle (from script patterns)

Contracts provide these overridable methods:

| Method | When Called | Must Call Parent? |
|--------|------------|-------------------|
| `LoadAssets(self)` | Before activation, load VZ layers | No |
| `Activated(self)` | Contract starts | YES |
| `Cancel(self)` | Contract cancelled by player/engine | YES |
| `Cleanup(self)` | After completion/cancel | Optional |
| `Complete(self)` / `:Complete()` | Fires `ContractCompleted` | N/A (triggers C++) |
| `Fail(self)` / `:Fail()` | Fires contract failure | N/A (triggers C++) |
| `SetupActivationCriteria` | Define start conditions | No |
| `SetupCancellationCriteria` | Define cancel conditions | No |

### Module/Library Scripts (from string harvest)

These scripts are `import()`-able modules available in the game's WAD:

| Module Name | Purpose |
|-------------|---------|
| `MrxTaskContract` | Contract base class |
| `MrxTaskContractOutpost` | Outpost contract variant |
| `MrxUtil` | Utility functions |
| `MrxObjectiveHelper` | Objective management |
| `MrxLayerManager` | VZ layer control |
| `MrxPmc` | PMC base systems |
| `MrxTutorial` | Tutorial framework |
| `WifPmcGarage` | PMC garage |
| `MrxFaction` | Faction reputation |

---

## Summary

### What We Know For Sure

- **~200+ functions** have CERTAIN evidence (exact EXE offsets, disassembly, or working hooks)
- **~100+ additional functions** have CONFIRMED evidence (named in multiple RE reports)
- **All functions** use the same `luaL_Reg` registration mechanism and can be hooked identically

> **CORRECTION (2026-07-21)** — the third bullet is false twice. **(a)** Not all
> functions are `luaL_Reg` rows: 33 of 227 sampled names here are strings with no
> registration row. **(b)** They cannot "be hooked identically" — 61 registered
> bindings point at a shared no-op stub (hooking their slot changes nothing about game
> behaviour), and on the retail SecuROM build `.rdata` func-pointer swaps trip
> anti-tamper. See the §4.2 correction.
>
> Replace the first two bullets with the measured figure: **1,081 registered bindings
> across 31 namespaces, 714 of which have at least one call site in the 370 decompiled
> scripts under `docs/mercs2-luacd/`.**

### What We Don't Know

- The exact boundaries between namespace tables (which functions belong to which table)
- ~500+ functions that likely exist in the 800–1300 range but haven't been individually named in docs
- Whether some functions are registered in sub-tables rather than top-level namespaces
- The exact signatures (argument counts/types) for most functions — only call patterns from scripts give hints
- Whether there are `luaL_Reg` tables outside the `0x00798770–0x00799200` range

### Next Steps

1. ~~**Full table dump**: Write a script that walks the `.rdata` section from `0x00798770` to `0x00799200`, reading all `{string_ptr, func_ptr}` pairs until `{NULL, NULL}` terminators, and producing a complete function list with namespace attribution~~
   **DONE (2026-07-21).** Result: **1,081 bindings / 31 namespaces / 61 no-op stubs**.
   Two notes for whoever re-runs it: scan to file `0x0079A9A8`, not `0x00799200`; and
   do **not** derive namespace attribution by guessing from the function names —
   read the engine's registry of `{const char* name, luaL_Reg* table}` at VA
   **`0x00DFD478`** (31 rows, 12-byte stride, zero row at `0x00DFD5EC`). Skip rows whose
   `func` is `0xFFFFFFFF`/`0xFFFFFFFE` (sub-table open/close markers) and flag rows
   pointing at `0x006D5640` as stubs. Corrected inventory:
   [`lua_engine_bindings_audit_deep_dive.md`](lua_engine_bindings_audit_deep_dive.md).
2. **Lua bytecode decompilation**: Decompile the 114 scripts in `scripts_vz` to recover full call-site evidence for every binding
3. **Runtime enumeration**: Use `lua_enum.asi` — see [`lua_runtime_enumeration.md`](lua_runtime_enumeration.md) — to iterate `_G` via `lua_next()` and dump `scripts/lua_bindings_runtime.{txt,json}`
