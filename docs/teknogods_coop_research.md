# TeknoGods Co-op Emulator & Multiplayer Research

> **Goal:** Evaluate TeknoGods and other community tools for enabling P2P co-op,
> custom server IPs, and potential DLC/EA-service spoofing.
> **Date:** 2026-05-19
> **Status:** Research complete.

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [TeknoGods Technical Analysis](#2-teknogods-technical-analysis)
3. [Mercenaries 2 Network Architecture (from EXE)](#3-mercenaries-2-network-architecture-from-exe)
4. [Other Community Multiplayer Solutions](#4-other-community-multiplayer-solutions)
5. [P2P / Custom Server Feasibility](#5-p2p--custom-server-feasibility)
6. [DLC Activation via Server Spoofing](#6-dlc-activation-via-server-spoofing)
7. [Recommended Path Forward](#7-recommended-path-forward)
8. [Open Questions](#8-open-questions)

---

## 1. Executive Summary

**Key findings:**

- **TeknoGods' Mercenaries 2 server emulator** is a standalone `mercs2server.exe`
  process that runs a local FESL/matchmaking stub, combined with `mloader.exe` which
  launches the game with a target server IP as a command-line argument. It is
  **closed-source** (the specific Mercs 2 tool), but TeknoGods has open-sourced their
  broader `eaEmu` GameSpy/EA protocol reference (GPLv3, Python, on GitHub).

- **The PC game has NO native LAN play.** Co-op was internet-only via EA's servers.
  However, the EXE contains `GMLAN: Cannot open broadcast socket!` and NetBIOS
  imports, proving LAN discovery *code exists* — it was likely disabled or gated behind
  the online authentication layer.

- **The game uses a three-layer network stack:**
  1. **FESL** (`fesl.ea.com`) — EA's Front End Socket Layer for authentication/login
  2. **Massive middleware** (`CMassiveSocket`, `locate.madserver.net`) — session
     management, matchmaking, UPnP, peer mesh topology
  3. **Peer mesh** — actual game data over Winsock2 UDP/TCP with peer-to-peer
     physics sync (confirmed by GDC 2008 talk: "Networked Physics in a Large
     Streaming World")

- **TeknoGods' approach is complementary to, but does NOT enable, DLC activation.**
  Making `IsOnlineConnected()` return true via server spoofing gets past the first
  gate, but DLC entitlements require separate content-server responses that the
  emulator does not provide.

- **The most practical multiplayer path** is to use TeknoGods' emulator for co-op
  (already working) and extend it or build a companion tool for DLC entitlement
  spoofing, OR combine it with the Lua injection approach from
  `dlc_extras_activation_research.md`.

---

## 2. TeknoGods Technical Analysis

### 2.1 Organization Overview

TeknoGods is a community group that creates server emulators and game loaders for
titles whose official servers have shut down. Their public GitHub org
(`github.com/teknogods`) hosts 18 repositories including:

| Repository | Description | Language | Status |
|------------|-------------|----------|--------|
| **OpenParrot** | Open-source arcade/JVS emulator (fork of TeknoParrot) | C++ | Active (325 stars) |
| **TeknoParrotUI** | Arcade emulator UI | C# | Active (306 stars) |
| **TeknoMW3** | Modern Warfare 3 multiplayer loader | C++ | Archived (GPLv3) |
| **eaEmu** | EA/GameSpy protocol emulator (reference) | Python | Archived (GPLv3) |

### 2.2 The Mercenaries 2 Server Emulator Package

| Component | Purpose |
|-----------|---------|
| `mercs2server.exe` | Local server process — emulates EA's FESL authentication and matchmaking responses |
| `mloader.exe` | Game launcher — takes a target IP as command-line argument (`mloader.exe <IP>`) |
| `mercs2.ini` | Config file — username, network settings |
| `instructions.txt` | Setup guide |

**Version:** `M2_server_alpha1` (as labeled in community archives)
**Status:** Confirmed working Dec 2023 on Windows 10/11
**Requirement:** Game must be patched to v1.1; may need MSVC++ 2008 SP1 runtime

### 2.3 How It Works (Inferred from Evidence)

The Mercs 2-specific tool is **closed-source**. However, based on analysis of
TeknoGods' open-source projects (TeknoMW3, eaEmu) and the game's binary strings,
the likely mechanism is:

```
┌─────────────┐      ┌──────────────────┐      ┌─────────────────┐
│  mloader.exe │─────▶│  Mercenaries2.exe │─────▶│ mercs2server.exe│
│  (launcher)  │      │  (game process)   │      │ (local server)  │
└─────────────┘      └──────────────────┘      └─────────────────┘
       │                      │                         │
  Passes IP as          Game tries to              Responds to:
  cmd-line arg          connect to the IP          - FESL auth
  to game EXE           instead of EA servers      - Session setup
                                                   - Matchmaking queries
```

**Step 1: mloader.exe** — Launches `Mercenaries2.exe` with modified startup
parameters. Based on TeknoMW3's open-source loader (which uses `Process.Start` with
command-line arguments + DLL injection), `mloader.exe` likely:
- Starts the game process in suspended state
- Patches the server address in memory (overwriting `fesl.ea.com` and/or
  `locate.madserver.net` with the provided IP)
- OR injects a DLL that hooks Winsock `connect()`/`gethostbyname()` to redirect
  EA domain resolution to the local IP
- Resumes the game process

> **Note (2026-07-27):** the first option is **insufficient on its own** — the FESL
> host the game actually reaches is *assembled* at runtime
> (`<service>.fesl[.<env>].ea.com` → `mercs2-pc.fesl.ea.com`), and the `.fesl` /
> `.ea.com` fragments are copied at **hard-coded widths**, so they cannot be
> overwritten with anything longer. Overwriting the standalone `fesl.ea.com`
> literal only covers a different call path. The hook option is the sound one.
> See [`reverse_engineer/networking_code_map.md`](reverse_engineer/networking_code_map.md) §6.4.

**Step 2: mercs2server.exe** — Listens on the same ports EA's servers used and
responds to the game's network protocol. Based on the FESL protocol format
(TLS-wrapped, key-value pairs with `TXN` transaction types), it likely handles:
- `fsys` — System handshake (protocol version, game ID)
- `acct` — Account login (returns success with spoofed persona)
- `subs` — Subscription/entitlement queries (returns minimal "OK")
- Session creation and join for co-op matchmaking

**Step 3: Peer mesh** — Once authentication succeeds and the session is established,
actual game data flows directly between peers (host and client) over UDP using the
Massive middleware's `CMassiveSocket` peer mesh — the server is no longer in the
data path.

### 2.4 eaEmu (Open Source Reference)

The `eaEmu` repository on GitHub is a Python implementation of EA's GameSpy protocol
stack. Key files:

- `eaEmu/gamespy/gpcm.py` — GameSpy login protocol (GPCM)
- Uses Django ORM for database backend
- Handles authentication tokens, session keys, buddy lists

While `eaEmu` targets GameSpy-era protocols (not FESL directly), the patterns are
instructive. The Mercs 2 EXE contains both GameSpy Voice SDK strings
(`GVInitialize`) and FESL strings, suggesting it uses a hybrid stack.

### 2.5 TeknoMW3 Loader Technique (Open Source, Analogous)

From the TeknoMW3 source code (C#, GPLv3):

1. **Process launch:** `Process.Start(gameExe, commandLineArgs)`
2. **Assembly validation:** MD5 hash check of game EXE
3. **IP resolution:** DNS lookup or direct IPv4 passthrough via `GetIp()`
4. **Mode selection:** LAN, Direct Connect, or Dedicated Server
5. **DLL loading:** The launcher expects a companion `TeknoMW3.dll` in the game
   directory that provides:
   - Custom server browser / matchmaking
   - Patching hooks for the game's online systems
   - Session handling for LAN or dedicated play
   - Config loading

The Mercs 2 `mloader.exe` likely uses the same pattern — a simplified version
since Mercs 2 only needs host/join rather than a full server browser.

---

## 3. Mercenaries 2 Network Architecture (from EXE)

### 3.1 Three-Layer Network Stack

From the binary strings in `Mercenaries2.exe` (confirmed via our EXE analysis and
Falcon Sandbox automated analysis):

| Layer | Component | Domains/Strings | Purpose |
|-------|-----------|-----------------|---------|
| **Auth** | FESL (EA) | `fesl.ea.com`, `feslPort: %d`, `360FeslServiceId` | Login, authentication, entitlements |
| **Session** | Massive middleware | `locate.madserver.net`, `CMassiveSocket`, `CMassiveMemoryManager`, `CMassiveRecord` | Matchmaking, session management, server discovery |
| **Game** | Peer mesh | `GM: Peer Mesh connection sent to host for player %d`, `CNetworkManager` | Physics sync, game state replication |

### 3.2 FESL Integration

The EXE contains EA's FESL client library. Key strings:

```
fesl.ea.com                           — FESL server hostname
feslPort: %d                          — Configurable FESL port
360FeslServiceId: %d (0x%x)           — FESL service identifier
Cannot call Fesl::Debug::Init without first calling Fesl::Allocator::Init
@messaging.ea.com                     — EA messaging service
```

FESL uses TLS-encrypted TCP with a structured packet format:
- 4-byte message type (`fsys`, `acct`, `subs`, etc.)
- 4-byte message ID (big-endian)
- 4-byte packet length (big-endian)
- Key-value payload (`key=value\n` pairs)

### 3.3 Massive Middleware ("madserver")

Pandemic Studios used middleware from **Massive Incorporated** (an in-game
advertising company, NOT Massive Entertainment/Ubisoft). Key evidence:

```
locate.madserver.net                  — Massive Inc. ad/discovery server
CMassiveSocket (0x007696A8)           — Massive-branded socket class
CMassiveMemoryManager::m_pInstance    — Memory manager singleton
CMassiveRecord                        — Data record class
MassiveComponent (32 pool slots)      — ECS component for Massive integration
/adsrv/4/openSession                  — Ad-serving session open
/adsrv/4/closeSession                 — Ad-serving session close
```

This reveals that `CMassiveSocket` and `locate.madserver.net` are from the
**Massive Inc. in-game advertising SDK** (common in 2007–2010 EA titles), NOT a
networking middleware. The actual multiplayer transport is handled by `CNetworkManager`
and the peer mesh system.

### 3.4 Peer Mesh Architecture

The game uses a **peer mesh** topology for gameplay data (not client-server):

```
GM: Peer Mesh connection sent to host for player %d    (0x00762DFC)
GM: Received join complete for player %i.              (0x00763464)
GM: Connection established from %i to %i.
GM: Connection lost from %i to %i.
GM: Error Sending Peer Mesh connection to host for player %d
GM: Received host property update: GM: R=%s, Prog=%s, Pres=%s, I=%s, 
    Participants=[%i of %i], Observers=[%i of %i]
```

Session management strings reveal the matchmaking model:

```
SessionType must be one of: FindServer, AssignHost, ResetServer, or ListServers...
HostSetupTimeoutSeconds is only valid for ResetServer or AssignHost session Types...
ListServer_* is only valid for ListServers sessionType...
Sending Host Property Change Packet
BroadcastInternal: buf encoding error %d
BroadcastInternalReliable: buf encoding error %d
SendToHostInternal: buf encoding error %d
ServerAddressArray
CNetworkManager::SetServerAddress
```

### 3.5 LAN Discovery Code (Disabled)

```
GMLAN: Cannot open broadcast socket!       (0x00763AD4)
NETAPI32.dll → Netbios()                   (LAN discovery import)
```

The `GMLAN` prefix confirms **GameManager LAN** code exists in the binary. It
attempts to open a broadcast socket for LAN game discovery. The presence of this
code plus the NetBIOS import means LAN play was *implemented* but is likely gated
behind the online authentication check (FESL login must succeed before the LAN
codepath becomes available, or it was simply disabled for the PC version).

### 3.6 UPnP / NAT Traversal

The EXE contains full UPnP NAT traversal code:

```
M-SEARCH * HTTP/1.1
Host:239.255.255.250:1900
ST:urn:schemas-upnp-org:device:WANConnectionDevice:1
AddPortMapping / DeletePortMapping
GetSpecificPortMappingEntryResponse
NewInternalPort / NewPortMappingDescription
Failed to create default listening port %d. Attempting random port allocation
0.0.0.0:%i:0#DEFAULTPORT
```

This means the game can automatically configure port forwarding on compatible
routers — important for P2P connections.

### 3.7 Network Lua API

```lua
-- Querying state
Net.IsMultiplayer()
Net.IsCoopMultiplayer()
Net.IsServer()
Net.IsClient()
Net.IsLobby()
Net.IsDedicated()
Net.IsOnlineConnected()
Net.IsMatchmakingInternet()

-- Connection
Net.ConnectToServer()
Net.StartServer()
Net.EnterLobby()
Net.EnterFriendsLobby()
Net.ExitFriendsLobby()
Net.QuitGame()
```

### 3.8 GDC 2008: "Networked Physics in a Large Streaming World"

Glen Fiedler (Pandemic Studios) presented at GDC 2008 on Mercenaries 2's
multiplayer networking. Key points:

- The challenge was synchronizing **physics-driven destruction** across players
  (buildings collapse unpredictably based on physics, not canned animations)
- Traditional approach (send "building destroyed" events) doesn't work when
  debris positions are physics-driven
- Solution: peer mesh with physics state synchronization
- Both players compute physics locally, with periodic corrections

This confirms the **peer-to-peer** model — there is no dedicated game server
in the data path during gameplay.

---

## 4. Other Community Multiplayer Solutions

### 4.1 Summary Table

| Solution | Status | Mercs 2 Support | LAN/P2P? | DLC? |
|----------|--------|-----------------|----------|------|
| **TeknoGods server emulator** | Working (2023) | Yes (PC) | Via local server | No |
| **Arcadia (Plasma emulator)** | Active | PS3 only | N/A | No |
| **GameRanger** | Active | Not listed | P2P tunnel | No |
| **Tunngle** | Defunct (2018) | Was listed | VPN tunnel | No |
| **Hamachi / Radmin VPN** | Active | Generic | VPN tunnel | No |
| **ZeroTier** | Active | Generic | VPN tunnel | No |
| **eaEmu (TeknoGods)** | Archived | GameSpy reference | N/A | No |

### 4.2 Arcadia (PS3 FESL Emulator)

[github.com/valters-tomsons/arcadia](https://github.com/valters-tomsons/arcadia)

- **Language:** C# (.NET)
- **Protocol:** EA Plasma (FESL) authentication and matchmaking
- **Mercs 2 status:** Listed with "Online (no leaderboards)" — **PS3 only**
- **PS3 FESL domain:** `mercs2-ps3.fesl.ea.com=152.53.15.83`
- **Other supported games:** Medal of Honor Airborne, Lord of the Rings Conquest,
  Bad Company 2 (coop only), Battlefield 1943 (tutorial only)

**PC relevance:** Arcadia proves the FESL protocol is well-understood and
implementable. The PS3 and PC FESL implementations share the same wire format —
the difference is the hostname (`mercs2-ps3.fesl.ea.com` vs presumably
`mercs2-pc.fesl.ea.com` or just `fesl.ea.com`). Arcadia's codebase could be
adapted for PC Mercs 2 with:
1. Adding the PC FESL hostname mapping
2. Handling any PC-specific `TXN` (transaction) differences
3. Testing with the actual PC game client

### 4.3 GameRanger

- General-purpose P2P game tunneling service
- Mercenaries 2 is **NOT listed** in their supported games
- Would only work if the game has native LAN play (which it doesn't expose on PC)
- **Not viable** without additional patching

### 4.4 VPN-Based Approaches (Hamachi, Radmin, ZeroTier)

These create virtual LAN networks between remote machines:
- **Only useful if the game has LAN play** — which Mercs 2 PC does not officially expose
- However, with the TeknoGods emulator running, a VPN could allow "LAN-like"
  connectivity between remote machines:
  1. Both players join the same VPN network
  2. Host runs `mercs2server.exe` on their machine
  3. Client's `mloader.exe` points to host's VPN IP
  4. Peer mesh data flows over the VPN tunnel

This is essentially **how TeknoGods co-op already works over the internet** — the
VPN just simplifies NAT traversal.

### 4.5 Port Forwarding

The game has native UPnP support, so for users with compatible routers, port
forwarding may happen automatically. The `mercs2server.exe` presumably listens on
the FESL port (typically 18300 for EA games) and the game's peer mesh uses a
configurable port via `0.0.0.0:%i:0#DEFAULTPORT`.

---

## 5. P2P / Custom Server Feasibility

### 5.1 Does the Game Support LAN Play Natively?

**Technically yes (code exists), practically no (disabled/gated on PC).**

Evidence for LAN code:
- `GMLAN: Cannot open broadcast socket!` — LAN game manager with broadcast discovery
- `NETAPI32.dll → Netbios()` — NetBIOS LAN discovery imported
- `BroadcastInternal` / `BroadcastInternalReliable` — reliable broadcast functions

Evidence against LAN availability:
- PCGamingWiki and OGDB both state: "PC-Version has no LAN-function"
- Co-op was "only playable over the Internet"
- LAN play exists on console versions but was removed/disabled for PC

**Implication:** The LAN code is present but the codepath is gated — likely behind
`IsOnlineConnected()` returning true, or a config flag. If the FESL authentication
succeeds (via TeknoGods), the GMLAN code may become reachable.

### 5.2 What Protocol Does the Game Use?

| Phase | Protocol | Transport |
|-------|----------|-----------|
| Authentication | FESL (TLS over TCP) | TCP port ~18300 |
| Session/matchmaking | Custom (via CNetworkManager) | TCP/UDP |
| Ad serving | HTTP to madserver.net | TCP port 80 |
| UPnP | SSDP + HTTP | UDP 1900 / TCP |
| Game data | Peer mesh (physics sync) | UDP (via CMassiveSocket / Winsock2) |

### 5.3 Is There Direct Connect?

**Not in the UI, but the plumbing exists:**

- `CNetworkManager::SetServerAddress` — C++ function to set a target server IP
- `ConnectToServer` — Lua function that triggers connection
- `Net.StartServer()` — Lua function to start hosting
- `mloader.exe` takes an IP argument, proving the game can be directed to
  connect to an arbitrary IP

TeknoGods' `mloader.exe` IS the "direct connect" solution — it provides the
missing UI for specifying a target IP.

### 5.4 Could TeknoGods' Approach Be Extended for Custom Server IPs?

**Yes — it already supports this.** The `mloader.exe <IP>` pattern is exactly
"custom server IP" functionality. The architecture is:

1. Each host runs `mercs2server.exe` locally
2. Clients run `mloader.exe <host-IP>`
3. The game connects to the specified IP for auth, then establishes a peer mesh

To improve this further:
- A **server list / lobby** could be built on top (a web service that tracks
  active `mercs2server.exe` instances)
- **VPN integration** (ZeroTier/WireGuard) could simplify NAT traversal
- A **GUI launcher** could replace the command-line shortcut with a proper
  server browser + direct-connect dialog

### 5.5 What Would Full Direct IP Connect Require?

If we wanted to bypass `mercs2server.exe` entirely and have pure P2P:

1. **Patch `IsOnlineConnected()`** to return true (bypasses FESL requirement)
2. **Patch or hook `CNetworkManager::SetServerAddress`** to accept a
   command-line or config-file IP
3. **Call `Net.ConnectToServer()`** from Lua with the target IP
4. OR: **Enable the GMLAN broadcast** codepath so LAN discovery works without
   FESL auth, then use any VPN for WAN play

Difficulty: Medium. Requires either EXE patching or an ASI plugin to hook
the network initialization.

---

## 6. DLC Activation via Server Spoofing

### 6.1 Can TeknoGods' Approach Enable DLC?

**Partially, but not directly.**

The DLC gate flow (from `dlc_extras_activation_research.md`):

```
1. User clicks "Extras" in main menu
2. Shell Lua calls IsOnlineConnected()
3. If false → dead end (EA servers offline)
4. If true → query online_content entitlements from EA
5. Server responds with DLC content IDs
6. Shell displays DLC items
7. For owned DLC: SetMasterScriptName(DLC_script)
8. DLC master script registers contracts
```

**What TeknoGods' server emulator likely provides:**
- Step 3: `IsOnlineConnected()` → true (FESL auth succeeds)

**What it likely does NOT provide:**
- Step 4-5: Entitlement query responses (requires implementing the specific
  `online_content` / `PartitionKey` protocol)
- Step 7-8: DLC script loading (game-specific, not a network feature)

### 6.2 Could a Modified TeknoGods Setup Spoof DLC Entitlements?

**Yes, in theory.** If `mercs2server.exe` could be extended to respond to
entitlement queries with "all DLC owned," the Extras menu would populate.
However:

1. The entitlement protocol is unknown (could be FESL `subs` transactions,
   HTTP to a content server, or a custom protocol)
2. `mercs2server.exe` is closed-source, so extending it requires either:
   - Reverse-engineering it and writing a replacement
   - Writing a separate entitlement proxy
   - Using DNS redirect + a custom HTTP responder
3. Even if entitlements return "owned," the DLC Lua scripts still need
   byte-swapping (they're Xbox 360 big-endian bytecode)

### 6.3 Is TeknoGods' Approach Complementary to Lua Injection?

**Yes — they solve different problems:**

| Approach | Solves | Doesn't Solve |
|----------|--------|---------------|
| TeknoGods server emulator | Co-op multiplayer, `IsOnlineConnected()` | DLC content loading, DLC script bootstrap |
| Lua injection (Approach 1) | DLC contract registration, bypasses Extras menu | Co-op multiplayer, online authentication |

**Combined approach:**
1. Use TeknoGods for co-op multiplayer (already working)
2. Use Lua injection for DLC content activation (independent of network state)
3. Optionally: extend the server emulator to also return entitlement data,
   making the Extras menu functional as a bonus

---

## 7. Recommended Path Forward

### For Co-op Multiplayer

**Tier 1: Use TeknoGods as-is (already works)**
- Download the `M2_server_alpha1` package
- Follow setup: extract to game dir, run `mercs2server.exe`, create
  `mloader.exe <IP>` shortcut
- For WAN play, ensure port forwarding or use a VPN (ZeroTier recommended
  for ease of setup)

**Tier 2: Build a friendlier launcher (medium effort)**
- Write a GUI that wraps `mloader.exe` + `mercs2server.exe`
- Add a simple server list (web service or Discord bot integration)
- Bundle with the SecuROM bypass and patch 1.1

**Tier 3: Build a proper server emulator (high effort)**
- Use Arcadia's FESL implementation as a reference
- Implement PC-specific FESL responses
- Add entitlement spoofing for DLC
- Open-source it for the community

### For DLC Activation

**Primary: Lua injection via patch WAD** (independent of multiplayer)
- As detailed in `dlc_extras_activation_research.md` §6
- Does not require server spoofing
- Works in single-player

**Secondary: Server-side entitlement spoofing** (bonus, if building Tier 3 above)
- Extend server emulator to respond to `online_content` queries
- Makes the Extras menu UI functional
- Nice to have but not required if Lua injection works

### For Both Together

The ideal setup would be:
1. **Lua injection** auto-loads DLC contracts at world start (no menu needed)
2. **TeknoGods emulator** enables co-op multiplayer
3. **Custom launcher** bundles both + SecuROM bypass + patch 1.1
4. Players can play DLC missions in co-op

---

## 8. Open Questions

| # | Question | Impact | How to Resolve |
|---|----------|--------|----------------|
| 1 | What ports does `mercs2server.exe` listen on? | Needed for firewall/VPN setup | Run with Wireshark or `netstat` |
| 2 | Does `mloader.exe` inject a DLL or patch memory? | Determines if it conflicts with ASI Loader | Disassemble `mloader.exe` or monitor with Process Monitor |
| 3 | Is the GMLAN broadcast codepath reachable after TeknoGods auth? | If yes, VPN-only play (no server needed) becomes possible | Test with packet capture after connecting via TeknoGods |
| 4 | What FESL transactions does the PC game send? | Required for building a replacement server | Capture TLS traffic with modified cert or MITM the local connection |
| 5 | Does `IsOnlineConnected()` returning true enable the Extras menu? | Determines if server spoofing alone unlocks the DLC UI | Test with TeknoGods emulator running and check Extras menu |
| 6 | Can `mercs2server.exe` and ASI Loader coexist? | Needed for combined co-op + DLC solution | Test both simultaneously |
| 7 | What is the exact entitlement protocol? | Required for DLC spoofing via server | FESL packet capture during Extras menu access |
| 8 | Could Arcadia be adapted for PC Mercs 2 FESL? | Alternative to closed-source TeknoGods server | Compare PC FESL domain and add to Arcadia config |

---

## Appendix A: Key Strings from Mercenaries2.exe (Network-Related)

These strings were confirmed via binary analysis and Falcon Sandbox automated
analysis of the retail executable:

### FESL / EA Online
```
fesl.ea.com
feslPort: %d
360FeslServiceId: %d (0x%x)
Cannot call Fesl::Debug::Init without first calling Fesl::Allocator::Init
@messaging.ea.com
messaging.ea.com
```

### Massive Inc. Advertising SDK
```
locate.madserver.net
CMassiveSocket (0x007696A8)
CMassiveMemoryManager::m_pInstance
ALLOCATION Failed for CMassiveRecord in RecordCreate
ALLOCATION Failed for CMassiveRecord in RecordFind
MassiveComponent (32 pool slots)
/adsrv/4/openSession
/adsrv/4/closeSession
```

### Peer Mesh / Game Manager
```
GM: Peer Mesh connection sent to host for player %d
GM: Error Sending Peer Mesh connection to host for player %d
GM: Received join complete for player %i.
GM: Connection established from %i to %i.
GM: Connection lost from %i to %i.
GM: OnConnectionChangeReceived: Already booted player.
GM: Received host property update: GM: R=%s, Prog=%s, Pres=%s, I=%s,
    Participants=[%i of %i], Observers=[%i of %i]
GMLAN: Cannot open broadcast socket!
```

### Session Management
```
SessionType must be one of: FindServer, AssignHost, ResetServer, or ListServers...
HostSetupTimeoutSeconds is only valid for ResetServer or AssignHost session Types...
ListServer_* is only valid for ListServers sessionType...
Sending Host Property Change Packet
SendToHostInternal: buf encoding error %d
BroadcastInternal: buf encoding error %d
BroadcastInternalReliable: buf encoding error %d
ServerAddressArray
CNetworkManager::SetServerAddress
Denying observer %s (id = %i) because game doesn't support observers
Socket got connection from [%s:%d]
```

### UPnP NAT Traversal
```
M-SEARCH * HTTP/1.1
Host:239.255.255.250:1900
ST:urn:schemas-upnp-org:device:WANConnectionDevice:1
AddPortMapping
DeletePortMapping
GetSpecificPortMappingEntryResponse
NewInternalPort
NewPortMappingDescription
Failed to create default listening port %d. Attempting random port allocation
0.0.0.0:%i:0#DEFAULTPORT
```

### Network Configuration
```
multiplayer.ini
multiplayerHost
multiplayerClient
CNetworkManager (0x00769104)
NetworkHeap 2200K
NetworkQueueOutgoingLength %d
GameNetworkTimeoutMS %d
```

### HTTP Client (for EA services)
```
%s %s HTTP/1.1
Host: %s:%d
Content-Length: %d%s
User-Agent: Custom/1.1
Accept: */*
```

### OpenSSL (for FESL TLS)
```
lhash part of OpenSSL 0.9.8d 28 Sep 2006
Secure Server Certification Authority
.\rsa_import.c
```

### GameSpy Voice SDK
```
GVInitialize: Failed to create socket
```

---

## Appendix B: FESL Protocol Quick Reference

Based on open-source reverse engineering from BF Heroes, BF2142, and Arcadia:

### Packet Format
```
Offset  Size  Field
0x00    4     Type (ASCII: "fsys", "acct", "subs", etc.)
0x04    4     ID (32-bit big-endian)
0x08    4     Packet length (32-bit big-endian)
0x0C    N     Payload (key=value\n pairs)
```

### Common Transaction Types (TXN)
| Type | TXN | Direction | Purpose |
|------|-----|-----------|---------|
| `fsys` | `Hello` | Client→Server | Initial handshake |
| `fsys` | `MemCheck` | Server→Client | Anti-cheat memory check |
| `acct` | `NuLogin` | Client→Server | Login with credentials |
| `acct` | `NuGetPersonas` | Client→Server | Get persona list |
| `acct` | `NuLoginPersona` | Client→Server | Select persona |
| `subs` | `GetEntitlementByBundle` | Client→Server | Check DLC ownership |

### Minimum Viable Server for Mercs 2

To build a replacement for `mercs2server.exe`:
1. Accept TLS connection (self-signed cert; game uses OpenSSL 0.9.8d)
2. Respond to `fsys.Hello` with protocol version
3. Respond to `acct.NuLogin` with success + session token
4. Respond to `acct.NuGetPersonas` with a persona
5. Respond to `acct.NuLoginPersona` with success
6. Respond to any `subs` queries with "entitled"
7. Handle session creation for co-op matchmaking

---

## Related Documentation

- [`docs/dlc_extras_activation_research.md`](dlc_extras_activation_research.md) — DLC activation approaches (primary: Lua injection)
- [`docs/exe_analysis_agent_a.md`](exe_analysis_agent_a.md) — EXE binary analysis (network, Lua, Scaleform)
- [`docs/exe_analysis_agent_b.md`](exe_analysis_agent_b.md) — EXE binary analysis (events, save system)
- [`docs/asi_loader_setup.md`](asi_loader_setup.md) — ASI Loader infrastructure for DLL plugins
- [TeknoGods eaEmu (GitHub)](https://github.com/teknogods/eaEmu) — Open-source EA/GameSpy protocol reference
- [Arcadia (GitHub)](https://github.com/valters-tomsons/arcadia) — Open-source PS3 FESL emulator
- [FESL Protocol Gist](https://gist.github.com/cetteup/c8a47917176477d4c38bb9512a6d3b0e) — FESL login/persona flow
