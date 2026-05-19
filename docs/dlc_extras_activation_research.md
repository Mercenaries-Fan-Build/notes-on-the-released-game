# DLC / Extras Menu Activation Research

> **Goal:** Enable the "Extras" menu DLC content without EA's defunct online servers.
> **Date:** 2026-05-18
> **Status:** Research complete. Ranked approaches with implementation plan.

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Community Tools Survey](#2-community-tools-survey)
3. [Extras Menu Technical Analysis](#3-extras-menu-technical-analysis)
4. [EA Online / Network Architecture](#4-ea-online--network-architecture)
5. [Ranked Approaches](#5-ranked-approaches)
6. [Recommended Implementation Plan](#6-recommended-implementation-plan)
7. [Open Questions](#7-open-questions)

---

## 1. Executive Summary

**The "Extras" menu problem is NOT an EA server authentication problem — it is a DLC
script bootstrap problem.** The key finding from this research:

- The **"Blow It Up Again" DLC was never released on PC**. It was PS3/Xbox 360 only.
- The PC build's "Extras" menu likely refers to the **Total Payback** free update
  (costumes, cheats, characters) and/or a planned PC DLC storefront that was cancelled.
- The `vz-patch.wad` DLC port is **already loading at the asset level** — the engine
  finds the blocks. But the DLC **contracts are not registered** because there is no
  Lua-level bootstrap script triggering `import("dlccon001")` etc.
- The community server emulator (TeknoGods) solves **multiplayer co-op**, not DLC activation.
- **No existing community tool addresses DLC/Extras activation on PC.**

The solution path is: write a DLC master script, compile it, inject it into the
patch WAD, and either override the `vz` master script or use `SetMasterScriptName`.

---

## 2. Community Tools Survey

### 2.1 TeknoGods Server Emulator (PC Co-op)

| Property | Value |
|----------|-------|
| **What it does** | Emulates EA's multiplayer matchmaking server for LAN/online co-op |
| **Components** | `mercs2server.exe` (server emulator) + `mloader.exe` (launcher) + `mercs2.ini` config |
| **How it works** | Runs a local server process that mimics EA's lobby/matchmaking; game connects to LAN IP instead of EA servers |
| **Downloads** | [MEGA](https://mega.nz/file/d7kGWCRA#8uF-5jRXcRqLPKhUt5mwCYMa4nucpEOv8smkXXuoO-c), [OneDrive](https://1drv.ms/u/s!AhcITBYw9UykiGIB9lhKVpA9nj2C?e=l9Z6sV) |
| **Status** | Working (confirmed Dec 2023, Windows 10/11) |
| **Solves DLC?** | **No** — only enables multiplayer co-op |
| **Source** | [GameFAQs thread](https://gamefaqs.gamespot.com/boards/938444-mercenaries-2-world-in-flames/80633902) |

**Setup:** Extract to game directory, run `mercs2server.exe`, edit `mercs2.ini` for username, create shortcut to `mloader.exe <IP>`. Host runs both server + launcher; clients just use launcher pointed at host IP.

### 2.2 Arcadia (EA Plasma Emulator)

| Property | Value |
|----------|-------|
| **What it does** | Open-source server emulator for EA's FESL (Frontend Services Layer) / Plasma backend |
| **Source** | [github.com/valters-tomsons/arcadia](https://github.com/valters-tomsons/arcadia) |
| **Language** | C# (.NET) |
| **Mercs 2 support** | Listed: "Online (no leaderboards)" — **PS3 only** (`mercs2-ps3.fesl.ea.com`) |
| **PC support** | **Not implemented** — domain mappings only target PS3 FESL endpoints |
| **Solves DLC?** | **No** — focuses on authentication/matchmaking, not content entitlements |

Arcadia is the most technically sophisticated project but targets PlayStation 3 network services. The PC version of Mercs 2 does not use FESL — it uses a simpler peer-mesh architecture with `CNetworkManager` / `CMassiveSocket`.

### 2.3 PCGamingWiki

| Finding | Detail |
|---------|--------|
| Server emulator | Links to TeknoGods (same as §2.1) |
| DLC note | "The Total Payback DLC, and Blow It Up Again DLC Pack were **not released for PC**" |
| Resolution changer | Community tool for widescreen |
| Patch 1.1 | Available via community files |

### 2.4 ModDB / Mod Engine

| Finding | Detail |
|---------|--------|
| Mods available | ~20 via Mod Engine; 1 major mod (Venezuela Edition, PS2 only) |
| DLC/Extras mods | **None found** for PC |
| Trainers | Several (+1 to +14 option trainers) at GameCopyWorld |

### 2.5 Other Approaches Investigated

| Tool/Method | Result |
|-------------|--------|
| GameRanger | No Mercenaries 2 support found |
| Radmin VPN | Not specific to Mercs 2; generic LAN tunnel |
| Hamachi | Not specific to Mercs 2; generic LAN tunnel |
| NexusMods | No Mercenaries 2 page |
| Reddit/Steam | No DLC unlock solutions found |
| DNS redirect / hosts | Would help for server emulation, not DLC entitlement |

**Bottom line: No existing community tool enables DLC/Extras content on PC.**

---

## 3. Extras Menu Technical Analysis

### 3.1 What Is the "Extras" Menu?

The Extras menu is part of the Scaleform GFx shell UI. The UI system uses:

- **Scaleform GFx** — Flash/ActionScript-based UI middleware (63 exported GFx classes)
- **Shell widget** — accessed via `_MODULES.mrxgui.GetWidgetByName("Shell")` in embedded Lua
- **Flash SWF files** — loaded from `shell.wad` blocks (particularly `scaleform_shell_P000_Q3.block` and `ui_shell_P000_Q3.block`)

The shell Lua code communicates with Scaleform via `Gui.CallFlashScriptFunction` and `Gui.CreateFlashWidget`.

### 3.2 DLC Content That Was Planned for PC

Evidence from the EXE binary that DLC infrastructure exists in the PC build:

| String/Function | EXE Offset | Purpose |
|----------------|-----------|---------|
| `IsDLC` | `0x7D9594` | Boolean flag: is DLC content active? |
| `DlcMapId` | `0x7D9588` | Which DLC map is loaded |
| `SetMasterScriptName` | `0x7BA6FC` | Set the DLC's master Lua entry point |
| `GetMasterScriptName` | `0x7BA710` | Query current master script |
| `%s\%s-patch.wad` | `0x7AFF5C` | Patch WAD loading format |
| `IsOnlineConnected` | (in Net API) | Check EA online connection |
| `IsMatchmakingInternet` | (in Net API) | Check internet matchmaking |

And from `GL.ini`:
```ini
[GameLauncherConfig]
Domain=eadm
SubDomain=eadm
PartitionKey=online_content
GUID=mercenaries2
ContentString=mercenaries2
```

### 3.3 The Extras Menu Flow (Reconstructed)

Based on the binary analysis, the likely flow is:

```
1. User clicks "Extras" in main menu (Scaleform shell)
2. Shell Lua script calls IsOnlineConnected()
3. If false → show "Connect to EA online" prompt (dead servers)
4. If true → query PartitionKey="online_content" from eadm domain
5. Server responds with list of entitled DLC content IDs
6. Shell displays purchasable/unlocked DLC items
7. For each owned DLC: engine calls SetMasterScriptName(DLC_script_name)
8. DLC master script's ScriptInit() registers contracts
```

**The critical gate is step 2-3:** `IsOnlineConnected()` returns false because EA's
servers are offline. The Scaleform shell script prevents any DLC from loading.

### 3.4 What Gets Checked

| Check | Mechanism | Can We Bypass? |
|-------|-----------|----------------|
| EA online connectivity | `IsOnlineConnected()` Lua function → C++ `CNetworkManager` → WS2_32 socket to `eadm` domain | Yes (multiple approaches) |
| Content entitlement | `PartitionKey=online_content` → HTTP/custom protocol to EA servers | Yes (server emulation or skip) |
| DLC flag per-session | `IsDLC` / `DlcMapId` in multiplayer session struct | Yes (set via Lua) |

### 3.5 What Is NOT Checked

- **SecuROM does NOT gate DLC** — DRM only protects the EXE
- **`vz.bin` does NOT gate DLC** — static build token, content-independent
- **FFCS CSUM does NOT gate DLC** — per-block integrity, not entitlement
- **No registry key stores entitlement** — `SettingsSerializer` is for display/audio prefs only
- **Save files don't store DLC entitlement** — DLC flag is session-level, not persisted

---

## 4. EA Online / Network Architecture

### 4.1 Network Stack in the EXE

| Component | Evidence |
|-----------|---------|
| **Winsock2 (WS2_32.dll)** | 42 imported functions — full TCP/UDP networking |
| **Legacy Winsock (WSOCK32.dll)** | 6 functions — backward compatibility |
| **NetBIOS (NETAPI32.dll)** | 1 function (`Netbios`) — LAN discovery |
| **OpenSSL 0.9.8d** | `lhash part of OpenSSL 0.9.8d 28 Sep 2006` — SSL/TLS for EA server auth |
| **GameSpy Voice** | `GVInitialize: Failed to create socket` — GameSpy SDK for voice chat |
| **CNetworkManager** | Core networking class at `0x00769104` |
| **CMassiveSocket** | "Massive" branded socket at `0x007696A8` |

### 4.2 Network Lua API

```
IsMultiplayer, IsCoopMultiplayer, IsServer, IsClient, IsLobby,
IsDedicated, ConnectToServer, StartServer, EnterLobby,
ExitFriendsLobby, IsOnlineConnected, IsMatchmakingInternet
```

### 4.3 Lobby System

The lobby system handles server discovery and join:
- `LobbyServerAdded` / `LobbyServerUpdated` / `LobbyServerRemoved` — callbacks
- `AutoLobby` — automatic lobby join
- `EnterFriendsLobby` — friends-list join (requires EA online)

### 4.4 EA Online Domains

From the EXE and `GL.ini`:
- **`eadm`** — EA Download Manager domain/subdomain
- **`online_content`** — PartitionKey for content entitlement queries
- **`mercs2-ps3.fesl.ea.com`** — PS3 FESL endpoint (in Arcadia; PC likely similar)

---

## 5. Ranked Approaches

### Approach 1: Lua Script Injection via Patch WAD (RECOMMENDED)

**Difficulty:** Medium | **Completeness:** High | **Risk:** Low

**Concept:** Skip the Extras menu entirely. Inject a DLC master script into `vz-patch.wad`
that auto-imports all DLC contracts at world load time.

**Steps:**
1. Write a Lua DLC master script: `dlc_master.lua`
   ```lua
   inherit("MrxTaskContract")
   function ScriptInit()
       import("dlccon001")  -- Merc Blitz
       import("dlccon002")  -- Arms Race
       import("dlccon003")  -- Urban Rampage
       import("dlccon004")  -- Death Race
   end
   ```
2. Compile with custom Lua 5.1 (float) compiler
3. Wrap in UCFX container with BINN chunk + CSUM trailer
4. Add to `vz-patch.wad` with correct ASET hash
5. Override the `vz` master script to chain-load DLC, OR
6. Modify the existing `vz` script to call `import("dlc_master")`

**Why this works:** The patch WAD mechanism is already proven working. Asset overlay
is automatic (last-opened-wins). The DLC contract Lua scripts are already in the
patch WAD from the Xbox 360 port — they just need a bootstrap trigger.

**Remaining gap:** Xbox 360 Lua bytecode is big-endian and needs byte-swapping
(or decompile + recompile for PC). This is tracked as a gap in `dlc_pc_port_status.md`.

### Approach 2: EXE Binary Patch — NOP the `IsOnlineConnected` Check

**Difficulty:** Medium | **Completeness:** Medium | **Risk:** Medium

**Concept:** Patch `IsOnlineConnected()` to always return `true`, allowing the Extras
menu to proceed. Then either emulate or skip the entitlement server.

**Steps:**
1. Find `IsOnlineConnected` C++ implementation (VA likely near `0x005E*` based on
   other Lua function patterns)
2. Patch it to always push `true` to the Lua stack:
   ```asm
   MOV EAX, [ESP+4]      ; lua_State* L
   MOV ECX, [EAX+8]      ; stack pointer
   MOV DWORD [ECX+4], 1  ; type = LUA_TBOOLEAN
   MOV DWORD [ECX], 1    ; value = true
   ADD DWORD [EAX+8], 8  ; advance stack
   MOV EAX, 1            ; return 1 result
   RET
   ```
3. This makes the shell think we're online
4. If the Extras menu then tries to contact EA servers (HTTP/custom protocol), it
   will time out or fail → need a stub server or additional patches

**Pros:** Directly addresses the gate. Proven pattern (like `IsDemoMode` patch).
**Cons:** Only half the solution — still needs entitlement response. EXE modification
requires updating the SecuROM bypass or using a separate patcher. Fragile.

### Approach 3: DLL Proxy Hook (dinput8.dll / Inline Hooks)

**Difficulty:** Medium-Hard | **Completeness:** High | **Risk:** Medium

**Concept:** Use the existing Ultimate ASI Loader (`dinput8.dll`) infrastructure to
load a custom ASI plugin that hooks network functions.

**Steps:**
1. Write an ASI plugin (C/C++ DLL) that:
   - Hooks `IsOnlineConnected` Lua binding → return true
   - Hooks Winsock `connect()` / `send()` for EA domain traffic → return success
   - Optionally hooks `SetMasterScriptName` to inject DLC script name
2. Load via the ASI Loader already documented in `docs/asi_loader_setup.md`

**Pros:** Non-destructive (no EXE modification). Can intercept at multiple levels.
Reusable framework for future mods.
**Cons:** Requires C/C++ development. Must reverse-engineer the exact hook points.
More complex than Lua-only approach.

### Approach 4: DNS Redirect + Minimal HTTP Responder

**Difficulty:** Medium | **Completeness:** Low | **Risk:** Low

**Concept:** Redirect EA domains via hosts file to a local HTTP server that returns
"entitled" responses.

**Steps:**
1. Add to Windows `hosts` file:
   ```
   127.0.0.1  eadm.ea.com
   127.0.0.1  mercs2-pc.fesl.ea.com
   ```
2. Run a minimal Python HTTP server that responds to entitlement queries
3. Handle SSL/TLS (game uses OpenSSL 0.9.8d — may need self-signed cert)

**Pros:** Simple concept. No game file modifications.
**Cons:** Unknown protocol format. SSL certificate pinning may block. May not be
enough — the game may use custom binary protocols, not HTTP. `IsOnlineConnected`
may check socket connectivity before attempting HTTP.

### Approach 5: Save File / Registry Editing

**Difficulty:** Low | **Completeness:** None for DLC |

**Concept:** Check if DLC entitlement is persisted anywhere.

**Finding:** DLC state is NOT persisted. From the EXE analysis:
- `IsDLC` is a per-session boolean in the multiplayer session struct
- No registry key stores DLC entitlement
- Save files store gameplay state, not entitlement
- `SettingsSerializer` only handles display/audio preferences

**Verdict:** **Not viable.** DLC entitlement is session-level, checked live.

### Approach 6: Full Server Emulation

**Difficulty:** Very Hard | **Completeness:** Complete | **Risk:** High

**Concept:** Build a full EA online server emulator for PC Mercs 2.

**Steps:**
1. Reverse-engineer the EA online protocol (packet capture + EXE analysis)
2. Implement authentication, entitlement, matchmaking
3. Handle SSL with custom certificates
4. Deploy as a local or community server

**Pros:** Most complete solution. Enables multiplayer + DLC + leaderboards.
**Cons:** Enormous effort. Unknown protocol. Arcadia (PS3) took years and still
doesn't support PC. The TeknoGods emulator exists but is closed-source.

---

## 6. Recommended Implementation Plan

### Phase 1: DLC Contract Activation via Lua (Approach 1)

This is the most practical path. The `vz-patch.wad` already loads DLC asset blocks.
The missing piece is Lua-level contract registration.

**Step 1: Fix Xbox 360 Lua bytecode endianness**

The DLC's `dlccon001`–`dlccon004` Lua scripts are big-endian bytecode. Options:
- **A.** Decompile BE bytecode with modified unluac → recompile with LE Lua 5.1 float compiler
- **B.** Write a bytecode endian-swapper (flip header flag, swap instruction u32s, swap float constants)

Option A is more reliable. The custom Lua 5.1 float compiler is already built (`tools/lua51-mercs2/luac`).

**Step 2: Create DLC master script**

Write `dlc01.lua` (matching the Xbox 360 `package.cfg` `scriptname DLC01`):

```lua
-- DLC01 master script — Blow It Up Again
-- Registers DLC contracts with the game engine

function ScriptInit()
    -- Import each DLC contract
    import("dlccon001")   -- Merc Blitz
    import("dlccon002")   -- Arms Race
    import("dlccon003")   -- Urban Rampage
    import("dlccon004")   -- Death Race
end
```

**Step 3: Trigger DLC script loading**

Three sub-options:

**3a. Override the `vz` master script (cleanest)**
- Decompile the existing `vz` script (38 KB, largest in `scripts_vz`)
- Add `import("dlc01")` to its initialization sequence
- Recompile and inject into `vz-patch.wad` (patch WAD overrides base)

**3b. Use `SetMasterScriptName` from an ASI plugin**
- Write a small ASI plugin that calls the game's Lua API:
  `Sys.SetMasterScriptName("dlc01")`
- This is the most non-invasive approach but requires C++ code

**3c. Hook into the shell Lua to bypass Extras menu**
- Instead of fixing the Extras menu, make DLC contracts auto-activate
- DLC missions appear in the PDA alongside regular contracts

### Phase 2: Fix Remaining Byte-Swap Gaps

From `docs/dlc_pc_port_status.md`, these gaps must be closed for DLC to render:

| Gap | Priority | Effort |
|-----|----------|--------|
| STRM vertex data byte-swap | Critical | Medium (per-format f16/f32/u8 swap) |
| COMP placement byte-swap | Critical | Low (42-byte record fields, well-understood) |
| Lua bytecode byte-swap | Critical | Medium (decompile+recompile is safest) |
| Texture tile de-swizzle | Important | Medium (Xbox 360 GPU-specific tiling) |
| Havok data byte-swap | Nice-to-have | Hard (class-aware) |

### Phase 3: (Optional) Fix the Extras Menu UI

If you want the Extras menu to actually work (not just auto-load DLC):

1. **Patch `IsOnlineConnected`** in the EXE to return true (Approach 2)
2. **Intercept the entitlement check** — either via DNS redirect or DLL hook
3. **Modify the shell Scaleform SWF** to skip online checks (requires SWF decompilation)

This is lower priority since auto-loading DLC via Lua is functionally equivalent.

---

## 7. Open Questions

| # | Question | Impact |
|---|----------|--------|
| 1 | What exact Lua code does the Extras menu shell execute? | Determines if we need to patch it or can skip it entirely |
| 2 | Does the `vz` master script already attempt to load DLC modules? | If yes, the gap is only the byte-swap; if no, we need the bootstrap |
| 3 | What protocol does `IsOnlineConnected` actually check? | DNS? TCP connect? HTTP? Determines feasibility of Approach 4 |
| 4 | Are the `dlctest_*.pws` audio files in the retail PC data directory the same as the Xbox 360 DLC audio? | If yes, audio is already present; if no, need to extract from DLC RAR |
| 5 | Does `SetMasterScriptName` work when called mid-session? | If yes, can trigger DLC from an ASI plugin at any time |
| 6 | What is the `IsMatchmakingInternet` flag used for? | May need to be patched alongside `IsOnlineConnected` |
| 7 | Can the TeknoGods server emulator's network layer be reverse-engineered? | Would reveal the exact protocol for a more complete solution |

---

## Related Documentation

- [`docs/dlc_loader_cross_reference.md`](dlc_loader_cross_reference.md) — DLC loader mechanism across platforms
- [`docs/dlc_pc_port_status.md`](dlc_pc_port_status.md) — DLC porting tool status and gaps
- [`docs/modding_deep_dive.md`](modding_deep_dive.md) — Hash systems, Lua format, modding feasibility
- [`docs/exe_analysis_agent_a.md`](exe_analysis_agent_a.md) — EXE binary analysis (network, Lua, Scaleform)
- [`docs/exe_analysis_agent_b.md`](exe_analysis_agent_b.md) — EXE binary analysis (events, save system)
- [`docs/asi_loader_setup.md`](asi_loader_setup.md) — ASI Loader infrastructure for DLL plugins
- [`docs/ui_blocks_inventory.md`](ui_blocks_inventory.md) — Shell/UI block inventory
- [`docs/xbox360_dlc_analysis.md`](xbox360_dlc_analysis.md) — Xbox 360 DLC archive analysis
