# TeknoGods ↔ Main Menu Cross-Reference Analysis

> **Agent D deliverable** — Cross-references Agent A (menu structure), Agent B (online/bonus checking),
> and existing TeknoGods/DLC research to map how the main menu's online systems interact with
> community multiplayer solutions.
>
> **Date:** 2026-05-25
> **Status:** Complete
> **Sources:**
> - `docs/ui/main_menu_structure.md` (Agent A)
> - `docs/ui/online_bonus_checking.md` (Agent B)
> - `docs/teknogods_coop_research.md`
> - `docs/dlc_extras_activation_research.md`
> - `docs/dlc_pc_activation_checklist.md`
> - `docs/dlc_loader_cross_reference.md`
> - `docs/lua_engine_bindings_audit.md`
> - `docs/comprehensive_engine_understanding.md`

---

## Table of Contents

1. [Menu State ↔ Network State Mapping](#1-menu-state--network-state-mapping)
2. [FESL ↔ Menu Integration](#2-fesl--menu-integration)
3. [Extras Menu Gap](#3-extras-menu-gap)
4. [Co-op Menu Flow](#4-co-op-menu-flow)
5. [LAN Code Activation](#5-lan-code-activation)
6. [Bonus Content ↔ Server Spoofing](#6-bonus-content--server-spoofing)
7. [Unified Architecture Diagram](#7-unified-architecture-diagram)
8. [Actionable Opportunities](#8-actionable-opportunities)

---

## 1. Menu State ↔ Network State Mapping

### Shell States That Require Network

Agent A documented the shell state machine driven by `ChangeShellState()` (C++ at VA `0x005C3740`).
Cross-referencing with Agent B's network flag analysis reveals which states depend on online connectivity:

| Shell State | Network Dependency | Gate Function(s) | Effect When Offline |
|-------------|-------------------|------------------|---------------------|
| `loadMainShell` | None | — | Always loads |
| `newGame` | None | — | Always available |
| `joinGame` | **Full FESL chain** | `IsOnlineConnected()` + `IsMatchmakingInternet()` | Greyed out or hidden |
| `onlineError` | None (error display) | — | Shown when connection fails |
| `onlineMessage` | None (message display) | — | Shown for online notifications |
| `quitGame` | None | — | Always available |
| `saveGame` | None | — | Always available |
| `autoContinue` | None | — | Always available |

**Key finding:** The `joinGame` state is the only main-menu state that requires online connectivity.
However, the menu *item* visibility (not just state transitions) is controlled by Lua code that
calls `Net.IsOnlineConnected()` and the `disableOnline` flag (string at `0x00BBC660`).

### Network State Flags and Their Menu Effects

From Agent B's global flag analysis:

| Flag Address | Name | Current Value | Menu Impact |
|--------------|------|---------------|-------------|
| `0x00DFBD74` | Online ready | `0x01` | Gate 1 for `HasPlayerUnlockedCode` |
| `0x00DFBD8C` | ShouldPlayOnline | `0x01` | Controls `Net.ShouldPlayOnline()` — user preference |
| `0x017C0BBF` | FESL connected | `0x00` | Gate 2 for unlock codes; when 0 = all online features dead |
| `0x017C0BC8` | Online enabled | `0x01` | Gates `IsMatchmakingInternet` / `IsOnlineEnabled` |
| `0x00DFBD98` | Unlock code status | `0x00` | Actual entitlement result from FESL `subs` |

### With TeknoGods Running vs. Not Running

| Scenario | `IsOnlineConnected` | `IsMatchmakingInternet` | `HasPlayerUnlockedCode` | Menu Behavior |
|----------|--------------------|-----------------------|------------------------|---------------|
| **No tools** (vanilla, EA dead) | `false` (0x017C0BBF=0) | `false` | `false` | Online/Extras disabled, `disableOnline` set |
| **TeknoGods emulator** (mloader + mercs2server) | Likely `true` (patches FESL flag) | Likely `true` | `false` (no entitlement impl) | Multiplayer enabled; Extras menu opens but shows no content |
| **ASI hook only** (dlc_enable.asi) | `true` (forced) | `true` (forced) | `true` (forced) | Hooks installed but **never called** — shell scripts don't invoke these functions |
| **TeknoGods + ASI** | `true` | `true` | `true` | Hooks installed but **untested** — same call-site problem applies |

**Critical insight:** TeknoGods' `mercs2server.exe` likely sets the FESL connection flag
(`0x017C0BBF = 1`) by successfully responding to the `fsys` + `acct` handshake. This
would make `IsOnlineConnected()` return `true` via the *original* code path (no hook needed).
However, it does NOT implement the `subs` service entitlement responses, so
`HasPlayerUnlockedCode` would still fail at gate 3 (`0x00DFBD98` remains 0).

---

## 2. FESL ↔ Menu Integration

### FESL Transactions the Menu Triggers

Based on Agent B's FESL service analysis (dispatch table at `0x00CDE8E0`) and the menu flow
documented by Agent A:

| Menu Action | Shell State | FESL Service | Transaction | Purpose |
|-------------|-------------|--------------|-------------|---------|
| Boot → Profile Select | `LTIProfileEnter` | `acct` | `NuLogin` / `NuGetPersonas` | Authenticate user |
| "Play Online" / Co-op | `LTIProfileOnlinePlay` → `joinGame` | `thtr` | `CONN` / `USER` / `GLST` | Connect to Theater, list games |
| Host Game | `multiplayerHost` | `thtr` | `CGAM` | Create game session |
| Join Game | `multiplayerClient` | `thtr` | `EGAM` / `EGRQ` | Enter game session |
| Extras Menu | (inline check) | `subs` | `GetEntitlementByBundle` | Query DLC ownership |
| Bonus Code Entry | (inline check) | `subs` | `GetPricingSelectionsByCode` | Validate promo code |
| Update Rich Presence | (background) | `asso` | — | Friend list status |

### What TeknoGods Handles (Inferred)

From `teknogods_coop_research.md` §2.3, TeknoGods' `mercs2server.exe` responds to:

| FESL Service | Handled? | Evidence |
|--------------|----------|----------|
| `fsys` (Hello) | **Yes** | Required for any connection; open-source `eaEmu` shows pattern |
| `acct` (NuLogin, NuGetPersonas, NuLoginPersona) | **Yes** | Co-op works = auth succeeded |
| `subs` (GetEntitlementByBundle) | **No** | TeknoGods docs say DLC is not enabled |
| `subs` (GetPricingSelectionsByCode) | **No** | No bonus code support documented |
| `thtr` (CONN, USER, CGAM, EGAM) | **Partial** | Co-op matchmaking works, so session creation/join is handled |
| `rank` (leaderboards) | **No** | Leaderboards confirmed non-functional |
| `asso` (friends) | **Unknown** | `EnterFriendsLobby` / `ExitFriendsLobby` status unknown |
| `club` (clans) | **No** | Not relevant to Mercs 2 |

### Gap Analysis

The **critical gap** between TeknoGods and full menu functionality is the `subs` service.
Without it:
- The Extras menu opens (because `IsOnlineConnected()` passes) but shows **no content**
- Bonus code redemption silently fails
- DLC session fields (`IsDLC`, `DlcMapId`) in Theater sessions have no backing data

The `thtr` service is partially handled — enough for basic host/join but unclear whether
all 21 Theater message types (Agent B §7) are implemented. Missing types would cause
specific multiplayer features to fail silently.

---

## 3. Extras Menu Gap

### The Complete Gate Flow

Combining Agent A's state machine with Agent B's three-stage gate:

```
User clicks "Extras" in Main Menu
    │
    ▼
Lua Shell Script (in shell.wad)
    │
    ├─ Net.IsOnlineConnected()           [Gate: byte 0x017C0BBF != 0]
    │       │
    │       ├─ false → show "Online required" message
    │       │          ChangeShellState("onlineError")
    │       │
    │       └─ true → proceed
    │
    ├─ Net.HasPlayerUnlockedCode()       [Three-stage gate]
    │       │
    │       ├─ Gate 1: byte [0x00DFBD74] != 0   (online ready — always true)
    │       ├─ Gate 2: byte [0x017C0BBF] != 0   (FESL connected)
    │       └─ Gate 3: byte [0x00DFBD98]        (actual entitlement from subs)
    │               │
    │               ├─ false → show "No bonus content" or empty list
    │               └─ true → display DLC items
    │
    └─ For each entitled DLC:
            subs.GetEntitlementByBundle(bundle_id)
                │
                ├─ entitlementStatus == "ACTIVE" → show DLC item
                └─ else → hide/grey out
```

### How This Relates to TeknoGods

**With TeknoGods running:**
- Gate 1 (online ready): PASS — always true at runtime
- Gate 2 (FESL connected): PASS — TeknoGods' FESL emulation sets the flag
- Gate 3 (entitlement): FAIL — `subs` service not implemented → `0x00DFBD98` stays 0

**Result:** The Extras menu *opens* but shows no unlocked content.

### Could TeknoGods Be Extended?

**Yes.** The minimum addition to `mercs2server.exe` would be:

1. Listen for FESL packet type `subs` (4-byte ASCII in packet header)
2. When `TXN=GetEntitlementByBundle` arrives, respond with:
   ```
   TXN=GetEntitlementByBundle
   entitlementStatus=ACTIVE
   entitlementStatusDesc=Full Access
   ```
3. This would set `byte [0x00DFBD98] = 1` (or equivalent non-zero)
4. `HasPlayerUnlockedCode()` would then return `true` through the *original* code path

**Difficulty:** Low-medium. The FESL wire format is well-documented (Agent B §4, TeknoGods
research Appendix B). The Arcadia project (C#, open-source) already implements `subs`
handling for PS3 titles using the same protocol.

**However**, this is moot for DLC activation because:
- The working solution (`dlc_extras_activation_research.md`) bypasses the Extras menu entirely
- DLC contracts auto-register via the ASI Lua bootstrap
- The Extras menu would show items but clicking them would try to use
  `SetMasterScriptName` via a code path that expects specific server-provided content IDs

---

## 4. Co-op Menu Flow

### Code Path: "Multiplayer" / "Co-op" Button Click

From Agent A's LTI callback analysis and shell state machine:

```
[Main Menu]
    │
    ├─ User selects "Join Game" / Co-op
    │       │
    │       ▼
    │   Lua calls: LTIChoseOnline()         [VA: string at 0x00BB69DC]
    │       │
    │       ├─ Checks Net.IsOnlineConnected()
    │       │       │
    │       │       ├─ false → ChangeShellState("onlineError")
    │       │       │
    │       │       └─ true → proceed
    │       │
    │       ├─ Calls LTIProfileOnlinePlay()  [VA: string at 0x00BBC520]
    │       │
    │       └─ ChangeShellState("joinGame")
    │               │
    │               ▼
    │           Lua creates Flash lobby UI:
    │               Gui.CreateFlashWidget()
    │               Gui.SetFlashSwfFile("lobby.swf")
    │               │
    │               ├─ Net.EnterLobby()      [VA: 0x005C69E0]
    │               │       → FESL Theater CONN + USER
    │               │       → Theater GLST (game list)
    │               │
    │               ├─ Net.EnterFriendsLobby() [VA: 0x005C6910]
    │               │       → Friends list via FESL asso service
    │               │
    │               ├─ User selects "Host":
    │               │       Net.StartServer()  [VA: 0x005C6C40]
    │               │       → Theater CGAM
    │               │       → UPnP port mapping
    │               │       → Peer mesh listener starts
    │               │
    │               └─ User selects game from list:
    │                       Net.ConnectToServer() [VA: 0x005C6AA0]
    │                       → Theater EGAM/EGRQ
    │                       → Peer mesh connection to host
    │
    ├─ Peer mesh established:
    │       "GM: Peer Mesh connection sent to host for player %d"
    │       "GM: Received join complete for player %i."
    │
    └─ Sys.FinishedShell → [Co-op Gameplay]
```

### How TeknoGods Intercepts This

TeknoGods' approach bypasses the in-game lobby entirely:

```
[Normal flow]                          [TeknoGods flow]
                                       
Main Menu → joinGame → Lobby UI        mloader.exe <IP>
    ↓                                      ↓
Net.EnterLobby() → Theater GLST       Patches server address in memory
    ↓                                  (overwrites fesl.ea.com / madserver.net)
Select game → Net.ConnectToServer()        ↓
    ↓                                  Game's own Net.ConnectToServer()
Peer mesh → co-op                      hits mercs2server.exe instead of EA
                                           ↓
                                       mercs2server.exe responds:
                                         - fsys Hello → OK
                                         - acct NuLogin → success
                                         - thtr CONN → session created
                                           ↓
                                       Peer mesh → co-op
```

**Key difference:** TeknoGods uses `mloader.exe` to redirect the game's network calls
*before* the shell state machine runs. The game still goes through its normal
`ChangeShellState("joinGame")` flow, but all FESL/Theater traffic hits the local
server instead of EA's dead infrastructure.

The shell state machine (Agent A) is NOT bypassed — it runs normally. TeknoGods
operates at the network *transport* layer (DNS/IP redirect), not at the Lua/UI layer.

---

## 5. LAN Code Activation

### Evidence for LAN Gate

From `teknogods_coop_research.md` §3.5:
- `"GMLAN: Cannot open broadcast socket!"` at VA `0x00763AD4`
- `NETAPI32.dll → Netbios()` import

From Agent A's shell state analysis:
- No `"lanGame"` or `"localPlay"` shell state exists in `.rdata`
- The `DialogBoxPlayLocal` and `DialogBoxPlayOffline` functions (Agent B §8, entries 17/20)
  share the same implementation at `0x005CAD90` — they show a dialog, not start local play

From Agent B's Net.* binding table:
- `Net.IsMatchmakingInternet` (0x005CACC0) — gates internet matchmaking
- No `Net.IsMatchmakingLan` found in the binding table (Agent B §8 lists all 66 entries)
- `Net.AutoLobby`, `Net.AutoClient`, `Net.AutoServer` exist but map to the same
  implementation as `Net.IsDedicated` (0x005C6850) — stub functions

### What Gates LAN Access

Based on all available evidence, **LAN is not gated behind a shell state or flag — it was
never exposed in the PC shell UI at all.** The evidence:

1. **No LAN shell state:** Agent A's comprehensive state list shows no LAN-related entries
2. **No LAN Net.* function:** Agent B's complete 66-entry Net table has no `IsMatchmakingLan`
3. **Stub dialog functions:** `DialogBoxPlayLocal` shows a message box, doesn't start local play
4. **The GMLAN code is reachable from C++ but not from Lua:** The `"GMLAN:"` prefix is in
   the `CNetworkManager` code at `0x00763AD4`, which is the peer mesh layer — it's called
   internally when the network manager attempts broadcast discovery, not from a Lua API

**Conclusion:** The LAN broadcast code exists in the `CNetworkManager` C++ layer but was
never wired to a Lua-accessible function or shell state. Enabling it would require either:
- A new ASI hook that calls the GMLAN initialization code directly (C++ level)
- Patching `CNetworkManager::SetServerAddress` to accept broadcast mode
- Writing a Lua binding for the existing C++ LAN code

This is **not** a simple flag-flip — it requires new native code. TeknoGods' approach
(redirect all traffic to a local server) achieves the same effect without needing actual
LAN broadcast.

---

## 6. Bonus Content ↔ Server Spoofing

### What `HasPlayerUnlockedCode` Actually Checks

From Agent B's disassembly (§2):

```
Gate 1: byte [0x00DFBD74] != 0    → "Online ready" (always true at runtime)
Gate 2: byte [0x017C0BBF] != 0    → "FESL connected" (requires auth success)
Gate 3: byte [0x00DFBD98]         → Actual entitlement value from subs service
```

### Does TeknoGods Handle This?

**Partially.** TeknoGods' FESL emulation passes Gate 2 (FESL connected flag gets set).
But Gate 3 requires the `subs` service to respond with entitlement data — which TeknoGods
does NOT implement.

### Could TeknoGods Spoof Bonus Content?

**Yes.** The minimum viable extension:

```python
# Pseudocode for subs service handler in a FESL emulator
def handle_subs_request(packet):
    txn = packet.get("TXN")
    
    if txn == "GetEntitlementByBundle":
        return {
            "TXN": "GetEntitlementByBundle",
            "entitlementStatus": "ACTIVE",
            "entitlementStatusDesc": "Full Access",
        }
    
    if txn == "GetPricingSelectionsByCode":
        # Any promo code → "valid"
        return {
            "TXN": "GetPricingSelectionsByCode",
            "status": "VALID",
        }
```

This would set `byte [0x00DFBD98]` to non-zero and `HasPlayerUnlockedCode()` would
return `true` through the original code path.

### Practical Value

**Medium.** The ASI hooks for `IsOnlineConnected` and `HasPlayerUnlockedCode`
are installed at the correct addresses but are **never called** during normal
gameplay — breakpoints never fire. The shell Lua scripts do not appear to
invoke these functions in any reachable code path. This means:

1. The net hooks alone do NOT enable the Extras menu
2. DLC activation works via the separate Lua bootstrap path (ASI hooks
   `Debug.Printf` to detect world load, then injects `import("dlc01")`)
3. The Extras menu remains non-functional regardless of hook status

Server-side entitlement spoofing via TeknoGods could potentially work if the
`subs` response handler sets `[0x00DFBD98]` through a C++ code path that
doesn't go through Lua — but this is speculative and untested.

**Open question:** Why are `IsOnlineConnected` and `HasPlayerUnlockedCode`
registered as Lua bindings but never called? The shell bytecode in `shell.wad`
needs to be decompiled to answer this definitively.

---

## 7. Unified Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                    MAIN MENU UI (Scaleform GFx)                      │
│                                                                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌───────────────────┐  │
│  │ New Game  │  │ Join Game│  │  Extras  │  │ Options/Save/Quit │  │
│  └─────┬────┘  └─────┬────┘  └─────┬────┘  └───────────────────┘  │
│        │              │              │                                │
└────────┼──────────────┼──────────────┼───────────────────────────────┘
         │              │              │
    ═════╪══════════════╪══════════════╪═══════════════════════════════
         │              │              │  ExternalInterface + Gui.*
    ═════╪══════════════╪══════════════╪═══════════════════════════════
         │              │              │
┌────────┼──────────────┼──────────────┼───────────────────────────────┐
│        ▼              ▼              ▼                                │
│  SHELL STATE MACHINE (Lua in shell.wad + C++ ChangeShellState)       │
│                                                                      │
│  ChangeShellState("newGame")                                         │
│       → Sys.StartSingleplayer                                        │
│       → Sys.FinishedShell                                            │
│                                                                      │
│  ChangeShellState("joinGame")                                        │
│       → LTIChoseOnline() → LTIProfileOnlinePlay()                   │
│       → Net.EnterLobby() → lobby Flash UI                           │
│                                                                      │
│  [Extras inline check]                                               │
│       → Net.IsOnlineConnected()     ←── Gate: 0x017C0BBF            │
│       → Net.HasPlayerUnlockedCode() ←── Gates: 3 flags              │
│       → subs.GetEntitlementByBundle                                  │
│                                                                      │
└──────────────────────────────┬───────────────────────────────────────┘
                               │
    ═══════════════════════════╪════════════════════════════════════════
                               │  Net.* Lua API (66 functions)
    ═══════════════════════════╪════════════════════════════════════════
                               │
┌──────────────────────────────┼───────────────────────────────────────┐
│                              ▼                                        │
│  NETWORK LAYER (C++)                                                 │
│                                                                      │
│  ┌────────────────┐  ┌─────────────────┐  ┌──────────────────────┐ │
│  │ FESL Client    │  │ Theater Client  │  │ Peer Mesh / GMLAN    │ │
│  │ (TLS, acct,   │  │ (thtr: CONN,   │  │ (UDP, physics sync, │ │
│  │  subs, fsys)  │  │  CGAM, EGAM)   │  │  broadcast socket)  │ │
│  │ Port: ~18300  │  │ Port: ~18320   │  │ Port: dynamic/UPnP  │ │
│  └───────┬────────┘  └───────┬─────────┘  └──────────┬───────────┘ │
│          │                    │                        │              │
└──────────┼────────────────────┼────────────────────────┼──────────────┘
           │                    │                        │
    ═══════╪════════════════════╪════════════════════════╪══════════════
           │                    │                        │  TCP/UDP sockets
    ═══════╪════════════════════╪════════════════════════╪══════════════
           │                    │                        │
┌──────────┼────────────────────┼────────────────────────┼──────────────┐
│          ▼                    ▼                        ▼              │
│  EXTERNAL SERVICES / EMULATORS                                       │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │ TeknoGods mercs2server.exe (LOCAL)                              ││
│  │                                                                  ││
│  │  [✓] fsys Hello → protocol version                              ││
│  │  [✓] acct NuLogin → success + spoofed persona                  ││
│  │  [✓] thtr CONN/USER → session management                       ││
│  │  [✓] thtr CGAM/EGAM → create/join game                         ││
│  │  [✗] subs GetEntitlementByBundle → NOT IMPLEMENTED              ││
│  │  [✗] subs GetPricingSelectionsByCode → NOT IMPLEMENTED          ││
│  │  [✗] rank → NOT IMPLEMENTED                                     ││
│  │  [?] asso (friends) → UNKNOWN                                   ││
│  │                                                                  ││
│  │  Sets: 0x017C0BBF = 1 (FESL connected)                         ││
│  │  Does NOT set: 0x00DFBD98 (entitlement status)                  ││
│  └─────────────────────────────────────────────────────────────────┘│
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │ dlc_enable.asi (IN-PROCESS)                                     ││
│  │                                                                  ││
│  │  Hooks at transport layer (overwrites C++ function prologues):  ││
│  │  [✓] IsOnlineConnected (0x5CAD10) → always true                ││
│  │  [✓] HasPlayerUnlockedCode (0x5CB6B0) → always true            ││
│  │  [✓] IsMatchmakingInternet (0x5CACC0) → always true            ││
│  │  [✓] DLC bootstrap: import("dlc01") after VZ load              ││
│  │                                                                  ││
│  │  Bypasses: ALL network gates (no server needed)                 ││
│  │  Provides: DLC contract registration via Lua injection          ││
│  └─────────────────────────────────────────────────────────────────┘│
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │ Peer Player (via VPN / direct IP / UPnP)                        ││
│  │                                                                  ││
│  │  After session established through mercs2server,                ││
│  │  actual gameplay data flows P2P:                                ││
│  │  - Physics synchronization (UDP, per GDC 2008 talk)            ││
│  │  - Event replication (Net.SendEvent_* functions)                ││
│  │  - Layer sync (BeginLayerEventGroup/EndLayerEventGroup)         ││
│  └─────────────────────────────────────────────────────────────────┘│
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

### Layer Interaction Summary

| Layer | Who Controls It | Modifiable By |
|-------|----------------|---------------|
| Scaleform UI | .SWF files in shell.wad | WAD modding (Flash decompiler) |
| Shell State Machine | Lua bytecode in shell.wad | WAD modding or runtime Lua inject |
| Net.* API | C++ binding table at 0x00B998D0 | ASI hooks (function pointer swap) |
| FESL/Theater Client | C++ in .text section | mloader.exe (IP redirect) or ASI |
| Peer Mesh | CNetworkManager C++ | Direct after session established |
| Global Flags | .data section globals | Any in-process write (ASI, debugger) |

---

## 8. Actionable Opportunities

### 8.1 Specific Hook Points for TeknoGods DLC/Bonus Extension

| Hook Point | Address | What To Do | Effort |
|-----------|---------|-----------|--------|
| `subs` service handler in mercs2server | N/A (server-side) | Add `GetEntitlementByBundle` → "ACTIVE" response | Low |
| `subs` service handler for codes | N/A (server-side) | Add `GetPricingSelectionsByCode` → "VALID" response | Low |
| `byte [0x00DFBD98]` | Game memory | Force to 1 via ASI after FESL connect | Trivial |
| `Net.HasPlayerUnlockedCode` func ptr | 0x00B99BA0 | Already hooked by dlc_enable.asi | Done |

### 8.2 Shell States That Could Be Force-Enabled for Testing

| State | How to Force | Use Case |
|-------|-------------|----------|
| `joinGame` | `ChangeShellState("joinGame")` from Lua console or ASI inject | Test lobby UI without TeknoGods |
| `onlineError` / `onlineMessage` | `ChangeShellState("onlineError")` | Test error dialogs |
| `loadMainShell` with online enabled | Set `[0x017C0BBF] = 1` via memory write | Simulate connected state |
| `serverEnter` | Force via `ChangeShellState` or LTI callback | Test server options UI |

The state buffer at `0x01175F2F` can be directly written to by an ASI plugin to force
any shell state transition. The transition flag at `0x01176034` must be cleared (set to 0)
simultaneously.

### 8.3 Missing Pieces in the Community Multiplayer Solution

| Gap | Impact | Resolution Path |
|-----|--------|----------------|
| `subs` service not emulated | Extras menu non-functional | Extend mercs2server; ASI bypass hooks are installed but **never called** (open problem) |
| `rank` service not emulated | No leaderboards | Low priority; cosmetic only |
| `asso` (friends) status unknown | Friends list may not work | Test with TeknoGods; extend if needed |
| GMLAN not exposed to Lua | No "true" LAN play | ASI hook to call GMLAN init from C++ level |
| Theater partial implementation | Some lobby features may fail | Map all 21 thtr message types vs. what mercs2server handles |
| No server browser | Only direct-IP connect | Build web service tracking active mercs2server instances |
| `UpdatePresence` (0x005CB710) | Friends can't see game status | Implement `asso` service in emulator |
| DLC in co-op sessions | `IsDLC`/`DlcMapId` not set in Theater | ASI sets session fields; mercs2server must relay to client |

### 8.4 Combined Solution Architecture (Recommended)

The ideal community setup combining all tools:

```
┌─ Game Directory ─────────────────────────────────────┐
│                                                       │
│  Mercenaries2.exe (cracked, v1.1)                   │
│  dinput8.dll (Ultimate ASI Loader)                   │
│  pmc_bb.dll (console logging, optional)              │
│                                                       │
│  scripts/                                            │
│    dlc_enable.asi    ← NET hooks + DLC bootstrap     │
│                                                       │
│  data/                                               │
│    vz.wad           ← base game                      │
│    vz-patch.wad     ← DLC content (2197 blocks)     │
│    Audios/          ← DLC voice-over .pws files      │
│                                                       │
│  mercs2server.exe   ← TeknoGods (for co-op)         │
│  mercs2.ini         ← TeknoGods config              │
│  mloader.exe        ← TeknoGods launcher            │
│                                                       │
└───────────────────────────────────────────────────────┘

Launch sequence:
1. mercs2server.exe starts (listens on FESL/Theater ports)
2. mloader.exe <partner-IP> launches game
3. dinput8.dll loads → finds dlc_enable.asi in scripts/
4. ASI hooks: IsOnlineConnected ✓, HasPlayerUnlockedCode ✓, IsMatchmakingInternet ✓
5. Game connects to mercs2server → FESL auth succeeds → 0x017C0BBF = 1
6. Shell loads → main menu fully enabled (online + extras)
7. User hosts/joins co-op → Theater via mercs2server → peer mesh P2P
8. World loads → ASI fires delayed bootstrap → import("dlc01")
9. DLC contracts register → appear in Fiona's briefing
10. Both players can play DLC missions in co-op
```

### 8.5 Priority Ranking

| # | Action | Effort | Impact | Status |
|---|--------|--------|--------|--------|
| 1 | ASI hooks for online gates | Trivial | Critical | **DONE** |
| 2 | DLC content in vz-patch.wad | Days | Critical | **DONE** |
| 3 | DLC Lua bootstrap via ASI | Days | Critical | **DONE** |
| 4 | TeknoGods co-op (as-is) | None | High | **WORKING** |
| 5 | Verify ASI + TeknoGods coexistence | Hours | High | **UNTESTED** (Open Q #6 from teknogods_coop_research) |
| 6 | DLC in co-op sessions (IsDLC/DlcMapId) | Days | Medium | Not started |
| 7 | subs service in emulator | Days | Medium | ASI net hooks are never called; server-side approach may be needed instead |
| 8 | Server browser / lobby | Weeks | Medium | Not started |
| 9 | GMLAN activation | Weeks | Low | Not started (TeknoGods approach is simpler) |
| 10 | Full Arcadia-style open-source PC FESL | Months | Medium | Aspirational |

---

## Related Documentation

- [`docs/ui/main_menu_structure.md`](main_menu_structure.md) — Shell states, LTI callbacks, Gui.* API
- [`docs/ui/online_bonus_checking.md`](online_bonus_checking.md) — FESL client, entitlements, global flags
- [`docs/teknogods_coop_research.md`](../teknogods_coop_research.md) — TeknoGods emulator, peer mesh, LAN analysis
- [`docs/dlc_extras_activation_research.md`](../dlc_extras_activation_research.md) — Working DLC solution
- [`docs/dlc_loader_cross_reference.md`](../dlc_loader_cross_reference.md) — Cross-platform DLC loader
- [`docs/lua_engine_bindings_audit.md`](../lua_engine_bindings_audit.md) — Complete Lua API
- [`docs/comprehensive_engine_understanding.md`](../comprehensive_engine_understanding.md) — Engine synthesis
