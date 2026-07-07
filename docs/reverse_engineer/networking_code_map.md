# Networking (row 28) — the co-op / online layer: Xbox↔PC code map

**Scope:** the complete networking subsystem of Mercenaries 2 — the **game-side Net\* replication/RPC
layer**, the **session / matchmaking / transport** stack (`CNetworkManager`, peer-mesh GameManager,
Winsock2 + NETAPI32), and the **FESL / EA online-services** auth stack (statically-linked OpenSSL TLS,
the baked CA key, the content-version handshake). This is scoreboard **row 28** — the **final map,
completing the 32-row engine scoreboard**. It marries the **Xbox 360 devkit "Profile" build**
(`Mercs2_Xenon_P.exe`, Jul-11-2008 preview, PowerPC, base `0x82000000`) symbol ground truth to the
**PC retail decompilation** (`Mercenaries2.exe`, SecuROM-unpacked image, base `0x00400000`,
`output/_ghidra/mercs2_unpacked.exe_decomp.txt`, 27,104 fns).

This is the companion to [`event_bus_code_map.md`](event_bus_code_map.md) (Keystone B) — the event/RPC
bus **whose wire branch IS this networking layer**; that map recovered the router/dispatch and flagged
the remote branch, which this map follows into the packet path. It also consolidates
[`faction_reputation_code_map.md`](faction_reputation_code_map.md) §8 (the `Net*Faction*` set) and
cross-references [`world_streaming_code_map.md`](world_streaming_code_map.md) (`NetSafeLoadAssets`/
`NetSafeAreBriefingAssetsLoaded` tie networking to streaming).

**Sources.**
- Xbox oracle: [`../mercs2-pdb-analysis/networking.md`](../mercs2-pdb-analysis/networking.md) — the
  3-layer structure, §A–§G Net\* categories / NetSafe\* / NetClient\* / session symbols, and the
  **decompiled receive-side packet decoder `NetEventCallback @825d3ce8`** + `SynchNetImportModule
  @825ce918` (both read first-hand in the Xbox decomp).
- Community/coop research: [`../teknogods_coop_research.md`](../teknogods_coop_research.md) — the FESL /
  Massive / peer-mesh 3-layer stack + the string inventory.
- Lua surface: [`../lua_engine_bindings_audit.md`](../lua_engine_bindings_audit.md) §3.2 (`Net.*`) +
  NetClient\* string offsets; [`../exe_analysis_agent_b.md`](../exe_analysis_agent_b.md) §"Network
  Replication" (WS2_32 42-fn import + NETAPI32 NetBIOS); [`../mercs2-luacd/03_contracts_jobs.md`](../mercs2-luacd/03_contracts_jobs.md)
  §3.6 (`NETEVENT_*` / `Net.SendCustomEvent` / `NetEventCallback` co-op sync pattern).
- The **most deeply-reversed slice** — the working online restore — is memory:
  [[mercs2-online-restore-and-patch-architecture]], [[fesl-bversion-builder]], [[fesl-ca-key-patch-required]].
- Pangea alignment gap: [`../modernization/pangea_engine_alignment.md`](../modernization/pangea_engine_alignment.md)
  §"Keystone B" (the wire protocol flagged "not known" — the gap this map closes).
- PC bodies read first-hand from the 27k-fn decomp, cited `ghidra/FUN_xxxx`.

**Method / honesty model.** Same discipline as the sibling maps. Confidence: **H** = body read +
can't-coincide fingerprint (shared event-hash across builds, or matching constants/role) · **M** = one
strong structural signal · **L/open** = positional / binding-table-only VA / confirm-live. A bare Xbox
`.rdata` offset means only the *name string* is located (code body unlocated) and the marriage is
PC-anchored. "Married by" = the concrete signal. Every address is cited and verified in corpus.

**★ CRITICAL — SecuROM is NOT a blocker** ([[securom-decompiled-not-a-blocker]]). The wire router's
**remote branch** is behind SecuROM indirect islands, but they are **classified and followed**, not
walled:
- **Split-thunk → real `.text` body:** the FESL builder `FUN_008445d0` and the socket/session code are
  plaintext in `.text` and read directly below.
- **VM residue → read live in the unpacked image:** the marshal core `FUN_005a0cc0` indirects through
  `thunk_FUN_02ee0000` / `thunk_FUN_02935000` / `thunk_FUN_024f28e0`, and the remote-dispatch islands
  `FUN_007002d0 → (*_DAT_0244fb3c)()` / `FUN_0059ddb0 → (*_DAT_0245dc0c)()` are runtime-unpacked
  jumptables. These are read live (paused) in the SecuROM-unpacked image, not statically.
- **Plain decomp-coverage gaps:** the OpenSSL TLS client + Winsock wrappers sit in the unpacked
  high-address region (`0x01dxxxxx`–`0x01exxxxx`) and are fully in the clear once dumped.

No `thunk_FUN_02xxxxxx` in this system is a "SecuROM wall."

---

## 0. Result in one line

**Networking is fully mapped across all three layers, and the wire keystone is closed by the
online-restore mod.** The receive-side packet format is recovered first-hand from the Xbox decoder
(`NetEventCallback @825d3ce8`: 32-bit name-hash + typed-TLV, ≤7 args, category nibble at `+8`); the PC
**send/marshal core is `FUN_005a0cc0`** with the local-vs-wire decision virtualized into the SecuROM
islands `FUN_007002d0`/`FUN_0059ddb0` (read live); the replication categories register through
`NetCategoryInfo FUN_00644510`; the join-time Lua-module pull is `NetSynchImportModule`/`SynchNetImportModule`;
the transport is `CNetworkManager` (`FUN_009dff40`/`FUN_009e010a`) + a Havok `hkBsdSock` Winsock-2.2
peer mesh; and the **FESL auth is a solved, working reference** — B-version builder `FUN_008445d0`
(ver ^ `0x6B3C35EB`), CA-key at `.rdata 0x768378`, terminated by tlsterm (SSLv3/RC4). **The one honest
open item — the exact on-wire byte encoding of the marshalled packet on the PC leg — is confirm-live,
but the mod stack has the whole handshake working end-to-end.** The Massive ad-net + Xbox LIVE/XLSP are
dead services (replace-don't-port); the Net\* replication payloads are the game layer to reimplement.

---

## 1. Three-layer architecture

```
┌──────────────────────────────────────────────────────────────────────────────────────┐
│  LAYER 1 — GAME-SIDE Net* REPLICATION / RPC  (the reimpl target "G")                    │
│                                                                                        │
│   Lua mission scripts:  Net.IsServer()/IsClient()  gate every host-authoritative op    │
│     Net.SendCustomEvent("<Channel>", NETEVENT_id, {args})   ── per-mission RPC         │
│     Net.SendEvent_* (44 dispatchers)                        ── engine→client fanout    │
│           │                                                                            │
│           ▼   marshal onto the SHARED event bus (Keystone B)                           │
│     frame = allocate → reserve N 8-byte slots (cap 2048) → build/dispatch → finalize   │
│           PC:  FUN_0059dd70 (reset) → FUN_005a0cc0 (marshal core)                       │
│           │                                                                            │
│      ┌────┴──── local-vs-wire branch (category nibble / IsServer) ───┐                 │
│      ▼ LOCAL                                                          ▼ REMOTE          │
│   run local subscribers                     SecuROM-virtualized serialize:             │
│   (event_bus_code_map §1)                   FUN_007002d0→(*_DAT_0244fb3c)()            │
│                                             FUN_0059ddb0→(*_DAT_0245dc0c)()            │
│   packet = {u32 name-hash}{header: cat<<4 | argc<<1}{typed-TLV args ≤7}                │
│   receive: NetEventCallback  (Xbox @825d3ce8) → SynchNetImportModule gate → re-drive   │
│   categories: NetPrimaryCategory + NetSubCat{FriendOrFoe,IsImportant,Inventory,        │
│               SeatLink,PoweredGate,NodeHealth,Health}  ← registrar NetCategoryInfo      │
│               FUN_00644510                                                             │
│   join-time state: NetSynchImportModule / NetPull  (pull host's Lua module state)      │
└───────────────────────────────────────────┬────────────────────────────────────────────┘
                                             │ rides on
┌───────────────────────────────────────────▼────────────────────────────────────────────┐
│  LAYER 2 — SESSION / MATCHMAKING / TRANSPORT   (dead services → replace "M")            │
│                                                                                        │
│   CNetworkManager  (FUN_009e010a alloc, FUN_009dff40 GetServerPortU16)                  │
│   PlayNowOptions matchmaking config parser  FUN_009ba4b0 (SessionType/HostSetupTimeout) │
│   Peer-mesh GameManager  ("GM: Peer Mesh connection sent to host for player %d")        │
│      host election / property broadcast / join-complete                                │
│   Transport sockets:                                                                    │
│      • Havok hkBsdSock  — WSAStartup(2.2) FUN_0089c710; connect FUN_009cf970;           │
│        accept FUN_009cfa10  (peer-mesh game data, Winsock2)                             │
│      • NETAPI32 Netbios() — GMLAN broadcast discovery (present, gated off on PC)        │
│      • GameSpy Voice — UDP FUN_00846f40 (bind :0xd753)                                  │
│   Massive ad-net  (CMassiveSocket, locate.madserver.net, /adsrv/4/*)  — dead, unrelated │
└───────────────────────────────────────────┬────────────────────────────────────────────┘
                                             │ authenticated by
┌───────────────────────────────────────────▼────────────────────────────────────────────┐
│  LAYER 3 — FESL / EA ONLINE SERVICES   (dead service, but RESTORED locally)             │
│                                                                                        │
│   fesl.ea.com : feslPort   — EA Plasma auth (fsys/acct/subs TXNs, key=value payload)    │
│   TLS client:  statically-linked OpenSSL 0.9.8d (28 Sep 2006), unpacked @0x01dxxxxx     │
│      — validates server cert vs a CA key baked at .rdata 0x768378 (NOT WinVerifyTrust)  │
│      — negotiates SSLv3 + RC4 (03 00; cipher 0x0005 RC4-SHA / 0x0004 RC4-MD5)           │
│   content-version handshake:  B-version "mercs2-pc_ver_%d"  FUN_008445d0                 │
│      versionInt = FUN_006c8cd0 → globalA/B ^ 0x6B3C35EB  (default 0xECE78C8C)           │
│   WORKING RESTORE:  mod (DNS redirect + clock-spoof + CA-key patch) → tlsterm (SSLv3/   │
│      RC4 terminator, genuine EA cert) → mercs2_server.py (FESL+Theater+GameSpy)          │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 0.5 Master marriage table (whole system at a glance)

| Role | Xbox symbol / addr | PC addr | Married by | Conf |
|---|---|---|---|---|
| **Receive-side packet decoder** (rebuild event from packed record) | `NetEventCallback @825d3ce8` (read) | `NetEventCallback` (rdata `0x0047180`; registered cfunc, PC body confirm-live) | Xbox body read first-hand: hdr `+8` = `cat<<4 \| argc<<1&7`, 4-type TLV, ≤7 args (§2) | H (Xbox) / open (PC body) |
| **Send/marshal core** | `FUN_82420690` router (stub) + `FUN_8256eb28` finalize | **`FUN_005a0cc0`** (232 B, `__thiscall`) | read body: gated by `thunk_FUN_02ee0000`; the frame-buffer `+8/+0xc` capacity math is byte-identical to the Xbox marshal; 60+ callers = every `Net*`/`Gui*` sender (§2) | H (PC body) / M (Xbox pin) |
| **Frame reset/rewind** | `FUN_8241d458` allocate | **`FUN_0059dd70`** | paired with `FUN_005a0cc0` at every send site (`FUN_006f4f80`) | H |
| **Remote-dispatch island A** | (in `FUN_82420690`) | **`FUN_007002d0 → (*_DAT_0244fb3c)()`** | 21-B jumptable thunk; SecuROM VM residue → read live; called by NetSafe senders (§2) | M (live) |
| **Remote-dispatch island B** | (in `FUN_82420690`) | **`FUN_0059ddb0 → (*_DAT_0245dc0c)()`** | 16-B jumptable thunk; SecuROM VM residue → read live; called by `Event.*`/`Net*` finalize sites | M (live) |
| **NetSafe sender exemplar** (pins PC frame to Xbox bus) | `NetSafeAreBriefingAssetsLoaded @825ce830` (hash `0x51ee8f14`) | **`FUN_006f4f80`** (536 B) | read body: builds event hash **`0x51ee8f14`** on `PTR_PTR_01175f30+0x18`, marshals ≤5 args via `FUN_0059dd70`+`FUN_005a0cc0` — **identical event hash across both builds** (§2) | H |
| **Category / stream-type registrar** | `NetCategoryInfo @829f3778` (static-init stub) | **`FUN_00644510`** (159 B) | read body: installs `CopyFromStream_00bc1f40`, seed `0x9e3779b9`, pool `0x100`, names `s_NetCategoryInfo_00bc56a4` (§3) | H |
| Replication categories (data) | `NetPrimaryCategory`+`NetSubCat*` (rdata `0x003fd4c`–`0x003fde0`) | (data table behind `FUN_00644510`) | Xbox `.rdata` name set; friend/foe, importance, inventory, seat-link, powered-gate, node/health (§3) | H (names) |
| **Join-time module pull** | `SynchNetImportModule @825ce918` (read) | `SynchNetImportModule` (rdata `0x0046e4c`; str `0x007D1D90`) | Xbox body read: module-hash `0x762c8f61` gate, emits pull event when record `+0x40` empty (§4) | H (Xbox) |
| Module-pull applier + boundary appliers | `NetSynchImportModule`/`NetPull`/`NetClientAddBoundary`/`RemoveBoundary` | str `0x007D1830` / rdata `0x0045b28` / str `0x007D1D20` / `0x007D1D08` | bindings-audit CERTAIN string offsets; cfunc bodies binding-table-only (§4) | M (VA) |
| **CNetworkManager alloc + address array** | `ServerAddressArray` (rdata `0x00a50fc`) | **`FUN_009e010a`** | read: `malloc(0xa8)`; `DAT_00e75e40 = FUN_009e0b5b("ServerAddressArray")`; refcount bump (§5) | H |
| Server-port accessor | `NetworkManager::GetServerPortU16` (rdata `0x00a4e1c`) | **`FUN_009dff40`** | locked read; returns `0xffff` on lock fail (§5) | H |
| **Matchmaking config parser** | `SessionType`/`HostSetupTimeoutSeconds` (rdata `0x0106ae0`/`0x0106bf0`) | **`FUN_009ba4b0`** (+ helper `FUN_009be370`) | read: `PlayNowOptions::InitFromString`; parses SessionType/GameProtocolVersion/PoolPlayer_* (§5) | H |
| Peer-mesh session sockets (Winsock2) | GameManager (`GM:` strings `0x00762dfc`+) | connect **`FUN_009cf970`** · accept **`FUN_009cfa10`** · WSAStartup(2.2) **`FUN_0089c710`** | read bodies: `connect()`/`accept()` on SOCKET obj+0x18; Havok `hkBsdSock` init string (§5) | H |
| LAN discovery (present, gated) | `GMLAN: Cannot open broadcast socket!` (`0x00763ad4`); `NETAPI32→Netbios()` | (NETAPI32 import) | exe_analysis_agent_b §Network Replication; string-anchored (§5) | M |
| **FESL B-version builder** | (PC-only path) | **`FUN_008445d0`** | read: `_snprintf(player+0x164,0x3f,"%s_ver_%d","mercs2-pc",verInt)` ([[fesl-bversion-builder]]) (§6) | H |
| FESL version compute | (PC-only) | **`FUN_006c8cd0`** | globalA `[0x017C0DF8]`/B `[0x01175C68]` ^ `0x6B3C35EB`; default `0xECE78C8C`; region-keyed (§6) | H |
| **FESL TLS cert-validation CA key** | (PC-only) | `.rdata` **`0x768378`** (128 B) | proven live: patch off → handshake RESET; on → `handshake OK (SSLv3, cipher=0x0005)` ([[fesl-ca-key-patch-required]]) (§6/§7) | H |
| FESL TLS client stack | (PC-only) | statically-linked **OpenSSL 0.9.8d** @`0x01dxxxxx`–`0x01exxxxx` | file strings `.\ssl\s3_both.c`/`s3_pkt.c`/`s3_lib.c`; `"OpenSSL 0.9.8d 28 Sep 2006"`; WSOCK32 loader `FUN_01e67e2e` (§7) | H |
| Massive ad-net transport (dead, unrelated) | `CMassiveSocket` (`0x007696a8`) | (Massive request/zone graph) | teknogods §3.3; in-game advertising SDK, NOT co-op (§8) | H (role) |
| Xbox LIVE / XLSP / System-Link (dead, Xbox-only) | `Xb360Session`/`GameManager`/`XSession*`/`XNet*` | — (PC has no LIVE path) | networking.md §"LIVE/System Link"; Xbox-only (§8) | H (Xbox) |
| `Net*Faction*` replication | `xPgSysNetFactionRelations` (rdata `0x00444f3`)+`NetClientFaction*` | unlocated (Lua `Net.SendCustomEvent("MrxFactionManager",…)`) | faction map §8; PC cfunc bodies open | open |

---

## 2. The wire packet path — the keystone

### 2.1 Receive side — `NetEventCallback` (Xbox body read first-hand)

The on-wire packet format is **recovered directly** from the Xbox receive decoder — the one place the
serialized record is unpacked field-by-field. `NetEventCallback @825d3ce8` takes a packed event record
and rebuilds an engine event:

```c
undefined8 NetEventCallback(undefined4 *param_1) {          // Xbox @825d3ce8
  cVar2 = SynchNetImportModule(DAT_838b25e0,*param_1);      // (a) module-hash gate — pull if unsynced
  if (cVar2 == '\0') return 0;
  FUN_8241d458(auStack_20);                                  // (b) allocate event frame (shared bus)
  FUN_822ef440(auStack_20,*(byte*)(param_1+8) >> 4);         // (c) push CATEGORY nibble = hdr>>4
  if ((*(byte*)(param_1+8) & 0xe) != 0) {
    uVar3 = 0;
    do {
      switch(*(undefined1*)((int)param_1 + uVar3 + 4)) {     //     per-arg TYPE TAG
      case 0: uVar1 = FUN_82587150(param_1+uVar3+3); FUN_822ed780(...); break; // string/guid
      case 1: FUN_822ef440(auStack_20, param_1[uVar3+3]); break;               // int
      case 2: FUN_823d8fe8((double)(float)param_1[uVar3+3], ...); break;       // float
      case 3: FUN_82315658(auStack_20, param_1[uVar3+3]); }                    // handle/guid
      uVar3 = uVar3 + 1 & 0xff;
    } while (uVar3 < (*(byte*)(param_1+8) >> 1 & 7));         //     ARGC = hdr>>1 & 7  (cap 7)
  }
  FUN_8241e940(auStack_20, *(byte*)(param_1+8) >> 1 & 7);
  FUN_82420690(auStack_20, *param_1, ...82047180, 2,0,1,0);  // (d) dispatch: (frame, EVENT_HASH, "NetEventCallback")
  FUN_8256eb28(auStack_20);
  return 1;
}
```

**On-wire packet format (recovered):**

| Field | Bytes | Meaning |
|---|---|---|
| `record[0..3]` | u32 | **event name-hash** (`*param_1`) — FNV-style m2 hash of the event name |
| `record[+4 .. +7]` | 4× u8 | per-arg **type tags** (0=string/guid, 1=int, 2=float, 3=handle/guid) |
| `record[+8]` | u8 | **header**: `>>4` = target/category nibble; `>>1 & 7` = **argument count (max 7)**; bit0 spare |
| `record[+0xc …]` | argc× u32 | argument payload words (interpreted by the type tag) |

So an event is a **32-bit name-hash + a typed-TLV stream capped at 7 args** — the identical shape the
event bus uses in memory (Keystone B: 4 arg types, argc≤7, 2048-slot frame cap). The receive path
re-enters the **same shared bus** (`FUN_8241d458`/`FUN_82420690`/`FUN_8256eb28`) that GUI/AI/audio use,
so an inbound packet re-drives the **local** subscriber handlers exactly as a local `Event.Post` would —
this is how a replicated `NetClient*` op or a `Net.SendCustomEvent` fires the joining client's Lua
`NetEventCallback(nEventId, tArgs)`. On PC, `NetEventCallback` (rdata `0x0047180`) is a registered
cfunc; its PC body is the inbound counterpart of the marshal core (§2.2) and is a confirm-live item —
the Xbox body above is the authority for the format.

### 2.2 Send side — the marshal core `FUN_005a0cc0` (PC body read; wire branch virtualized)

Every PC sender (`Net*`, `Gui*`, `Event.Post`) funnels through **`FUN_005a0cc0`** (232 B, `__thiscall`,
60+ callers). Read first-hand:

```c
uint __thiscall FUN_005a0cc0(int param_1, uint *param_2, int param_3, undefined4 param_4) {
  cVar1 = thunk_FUN_02ee0000(param_2);           // ← SecuROM VM residue: the local-vs-wire predicate
  if (cVar1 == '\0') {                            //   LOCAL branch: buffer has room?
    uVar2 = *param_2;
    if (param_3 <= *(int*)(uVar2+8) - *(int*)(uVar2+0xc) >> 3) { FUN_0085d680(); ... }
  } else {                                        //   REMOTE / serialize branch:
    if ((0 < *(int*)(*param_2+8) - *(int*)(*param_2+0xc) >> 3) && (param_1 != 0)) {
      if (FUN_004efb00() && (iVar3 = FUN_0085d5d0(), iVar3 != 0)) {
        FUN_0085db20();
        if (... (*(undefined4**)(*param_2+8))[-1] != 0) {
          thunk_FUN_02935000();                   // ← SecuROM VM residue: encode step
          return thunk_FUN_024f28e0(param_2, param_4);   // ← SecuROM VM residue: emit step
        }
      }
    }
    ... FUN_0085d680();                            //   fallback local append (param_3+2 slots)
  }
  return uVar2 & 0xffffff00;
}
```

The `param_2+8`/`param_2+0xc` capacity arithmetic (`(end-cursor)>>3` = free 8-byte slots) is byte-for-byte
the Xbox marshal's slot-reservation math (`FUN_82878c50`, cap `0x801`). **The local-vs-wire decision and
the actual byte encoding are the three `thunk_FUN_02xxxxxx` calls** — SecuROM-virtualized:
- `thunk_FUN_02ee0000(param_2)` — the routing **predicate** (returns 0 → local, nonzero → serialize).
  The category nibble / `Net.IsServer` state is the likely input (Xbox pushes the nibble as the first
  frame arg via `hdr>>4`).
- `thunk_FUN_02935000()` — the **encode** step (build the packet body).
- `thunk_FUN_024f28e0(param_2, param_4)` — the **emit** step (hand the packet to the transport).

These indirect through runtime-unpacked code and **must be read live** in the SecuROM-unpacked image
(x32dbg, paused). This is the exact wall Xbox saw (`FUN_82420690` collapsed to a `FUN_829167xx` stub) —
relocated to the packer, not gone. **Confirm-live recipe in §9.**

### 2.3 The remote-dispatch islands — `FUN_007002d0` / `FUN_0059ddb0`

Two tiny jumptable thunks are the second half of the wire branch (from the event_bus map):

```c
void FUN_007002d0(void) { (*_DAT_0244fb3c)(); }   // 21 B; "Could not recover jumptable" — SecuROM
void FUN_0059ddb0(void) { (*_DAT_0245dc0c)(); }   // 16 B; ditto
```

`FUN_007002d0` is called by the NetSafe senders (its 12+ callers include `FUN_006f4f80`, `FUN_006f5310`,
`FUN_006fefe0`, `FUN_006ff300` — the `0x006fxxxx` NetSafe cluster); `FUN_0059ddb0` is called by the
`Event.*` and finalize sites (`FUN_005f6660` = `Event.Create`, `FUN_005ce900`/`FUN_005ceba0` = NetSafe
queries). Both dispatch through `_DAT_0244fb3c`/`_DAT_0245dc0c` — function pointers populated at unpack
time. They are the PC form of the Xbox `FUN_82420690` router core.

### 2.4 The bridge anchor — `FUN_006f4f80` (H, read; pins PC↔Xbox)

The one sender that **proves the PC frame context is the same bus as Xbox**: `FUN_006f4f80` (536 B)
builds an event with the **identical hash `0x51ee8f14`** (`NetSafeAreBriefingAssetsLoaded` — same m2 hash
of the same name on both builds), on `PTR_PTR_01175f30+0x18` (the PC frame buffer = Xbox
`DAT_837fe3a0+0x18`), marshals ≤5 args, and drives `FUN_007002d0()` → `FUN_0059dd70()` → `FUN_005a0cc0`.
Reading it confirms the whole PC send chain: **gate (`FUN_007002d0`) → reset frame (`FUN_0059dd70`) →
marshal (`FUN_005a0cc0`)** with the category/reliable flags as the `param_3`/`param_4` args.

---

## 3. Replication categories — `NetCategoryInfo FUN_00644510` (H, read)

Which per-object properties are network-synced is a **stream-type descriptor** registered like every
other ECS component descriptor. `FUN_00644510` (159 B, one-shot init) read first-hand:

```c
void FUN_00644510(void) {
  PTR_DAT_017bebbc._0_2_ = 0xffff; PTR_DAT_017bebbc._2_2_ = 0xffff;
  _DAT_017bebc4 = 0x100;                              // pool size 0x100
  _DAT_017bebcc = 3;
  PTR_PTR_017bebb8 = &PTR_CopyFromStream_00bc1f40;    // WAD stream-deserialize vtable
  _DAT_017bebdc = 2; _DAT_017bebde = 8;               // stride/type descriptor
  _DAT_017bebe0 = 0x100;
  _DAT_017bebe4 = 0x9e3779b9;                         // golden-ratio hash seed
  _DAT_017bebf8 = 0x100;
  PTR_PTR_017bebd0 = &PTR_LAB_00bc5ff8;               // shared component method vtable
  FUN_0064a770();                                     // shared descriptor registrar
  PTR_s_NetCategoryInfo_017bebf4 = s_NetCategoryInfo_00bc56a4;  // names it "NetCategoryInfo"
}
```

This is the **exact registrar template** the faction-descriptor pass documented (`FUN_00641340` etc.):
`CopyFromStream` vtable + `0x9e3779b9` seed + `0x100` pool + shared `FUN_0064a770`. It registers the
descriptor that backs the Xbox category set (all `.rdata` names, `networking.md` §A):

| Category | Xbox `.rdata` | Synced property |
|---|---|---|
| `NetPrimaryCategory` | `0x003fde0` | the primary replication class of the object |
| `NetSubCatFriendOrFoe` | `0x003fd4c` | faction/hostility relation |
| `NetSubCatIsImportant` | `0x003fd64` | "important object" flag (prioritized sync) |
| `NetSubCatInventory` | `0x003fd7c` | held items / weapons |
| `NetSubCatSeatLink` | `0x003fd90` | vehicle-seat occupancy linkage |
| `NetSubCatPoweredGate` | `0x003fda4` | powered gate/door state |
| `NetSubCatNodeHealth` | `0x003fdbc` | destructible node health |
| `NetSubCatHealth` | `0x003fdd0` | actor health |

`NetCommand`/`NetNotify` (rdata `0x0013a1c`/`0x0013a28`) are the two channel tokens these ride, sitting
among the gameplay event-token strings (`Weapon Events`, `Grapple Events`, `NodeState`, `Trigger`).
Per-object property sync is dispatched by the category descriptor's `CopyFromStream` at the granularity
of these sub-cats — i.e. an object's `NetSubCatHealth`/`NetSubCatInventory`/… are serialized as separate
typed sub-streams, not one monolithic snapshot.

---

## 4. Join-time module pull — `NetSynchImportModule` / `NetPull` (H Xbox / M PC)

When a client joins mid-session it must receive the host's **Lua module state** (the assembled world /
mission script tables). This is the "join-time module pull." The Xbox body is read first-hand:

```c
undefined8 SynchNetImportModule(undefined8 param_1, undefined8 param_2) {  // Xbox @825ce918
  iVar1 = FUN_8241bb78(0x762c8f61);                     // hash → the import-module registry record
  if ((iVar1 != 0) && (0 < *(int*)(iVar1 + 0x40))) {    // registry exists & populated
    iVar1 = FUN_8241bb78(param_2);                       // is THIS module (param_2 hash) already synced?
    if ((iVar1 != 0) && (0 < *(int*)(iVar1 + 0x40))) return 1;   // yes → deliver
    FUN_82315658(auStack_20, param_2);                   // no → push module hash as arg
    FUN_82420690(auStack_20, 0x762c8f61, ...82047110, 1,0,1,0);  // emit NetSynchImportModule pull event
  }
}
```

`FUN_8241bb78(hash)` is the **name-hash → module record** lookup (`+0x40` = entry count). Because
`NetEventCallback` calls `SynchNetImportModule` **first** (§2.1 line (a)), any inbound event for a
not-yet-synced module **triggers a module pull before the event is delivered** — the client requests the
host's module state, the host ships it, and only then does the queued event fire. This is the mechanism
that ties into the scripting host's module system (import/inherit): the pulled module is the host's
authoritative script-table snapshot for that channel (e.g. `"MrxFactionManager"`, `"MrxBriefing"`,
`"WifPmcInterior"` — the channels the Lua `Net.SendCustomEvent(...)` calls name).

PC anchors (bindings-audit CERTAIN, cfunc bodies binding-table-only):

| Symbol | PC string offset | Xbox rdata | Role |
|---|---|---|---|
| `NetSynchImportModule` | `0x007D1830` | `0x0046e4c` | the pull **request** cfunc (Lua-facing) |
| `SynchNetImportModule` | `0x007D1D90` | — | the gate above (checks + emits pull) |
| `NetPull` | — | `0x0045b28` | the low-level module-state pull primitive |
| `NetInitializeClientFactionRelations` | — | `0x0046ea4` | re-drives the relation matrix on join (faction map §8) |

The Lua co-op pattern this serves (luacd §3.6): `OnPlayerJoined` / `mpPlayerLeft` handlers resend
startup state to late joiners (`pmccon001.lua:115`), each mission defining its own `NETEVENT_*` enum +
`NetEventCallback(nEventId, tArgs)`.

---

## 5. Session / transport — `CNetworkManager` + peer mesh (H, read)

### 5.1 CNetworkManager (server address/port array)

```c
FUN_009e010a:  pvVar1 = malloc(0xa8);                                 // the manager object
               DAT_00e75e40 = FUN_009e0b5b(s_ServerAddressArray_...); // named lock/array
               _DAT_00e75e44 = _DAT_00e75e44 + 1;                     // refcount bump ("Incrementing Server Array references")
FUN_009dff40:  // GetServerPortU16 — locked read from the array; returns 0xffff on lock-acquire fail
```

These name the `CNetworkManager` accessors (`NetworkManager::GetServerAddressU32`/`GetServerPortU16`/
`GetServerHostName`, Xbox rdata `0x00a4cd8`+) for the reference-counted, locked server-address table.
This is the transport-address layer the whole session stack reads.

### 5.2 Matchmaking config — `FUN_009ba4b0` (PlayNowOptions::InitFromString)

The text-format matchmaking config parser (read first-hand): reads keys and dispatches each through a
vtable on the options object — `SessionType` (`FindServer`/`AssignHost`/`ResetServer`/`ListServers`),
`HostSetupTimeoutSeconds` (gated to AssignHost/ResetServer), `GameProtocolVersion`, `DebugThreshold`,
`PoolPlayer_MaxPlayers`/`PoolPlayer_PlayerCountThresholds`, and the `Filter`/`IntegerPreference`/
`StringPreference`/`VotingMethod`(Lottery/Plurality) matchmaking grammar. `FUN_009be370` is the small
config-key helper its callers use.

### 5.3 Peer-mesh sockets (Winsock2) — host election + game data

The actual game data uses a **peer mesh** (not client-server) over Winsock2, wrapped by Havok's BSD
socket layer (`System.Io.Socket.Bsd.hkBsdSock`):

```c
FUN_0089c710:  WSAStartup(0x202, &wsadata);        // Winsock 2.2; logs "Windows WSAStartup failed" via hkBsdSock
FUN_009cf970:  connect(sock@obj+0x18, name, len);  // AF_INET (family 2) TCP connect; WSASetEvent on success
FUN_009cfa10:  accept(sock@obj+0x18, ...);          // server/host listen-accept
```

Host election + property broadcast are the GameManager `GM:` strings (peer mesh connection to host,
join-complete, connection established/lost, host-property update). PC replaces the Xbox LIVE/XLSP session
with this Winsock peer mesh + the FESL/Massive locate services. GDC 2008 (Fiedler) confirms the model:
**both peers simulate physics-driven destruction locally with periodic corrections** — the reason the
replication categories (§3) sync node/health/importance rather than full transforms.

### 5.4 LAN + voice (present, secondary)

- **NETAPI32 `Netbios()`** + `GMLAN: Cannot open broadcast socket!` (`0x00763ad4`) + `BroadcastInternal`/
  `BroadcastInternalReliable`/`SendToHostInternal` — LAN discovery code **exists but is gated off on the
  PC retail build** (co-op was internet-only). exe_analysis_agent_b confirms WS2_32 (42 imported fns) +
  NETAPI32.
- **GameSpy Voice** — `FUN_00846f40` (`GVInitialize`): a UDP socket (`socket(AF_INET, SOCK_DGRAM,
  IPPROTO_UDP)`) bound to port `htons(0xd753)` for voice chat. Separate from the game-data mesh.

---

## 6. FESL / EA online-services + the online-restore consolidation (H — the working reference)

**This is the deepest-recovered slice of the whole system**, because the online-restore work drove it
live end-to-end. It is the working reference for how Layer 3 authenticates a session.

### 6.1 The content-version handshake — `FUN_008445d0` (B-version builder)

```c
FUN_008445d0:  _snprintf(player+0x164, 0x3f, "%s_ver_%d", "mercs2-pc", versionInt);  // fmt @0xbe2da4
```
`versionInt` is computed in **`FUN_006c8cd0`** (SecuROM-encrypted on the 17 MB retail images, plaintext
in the 53 MB de-SecuROM'd builds; read live on the unpacked image):
- `A = [0x017C0DF8]` (region-keyed override), `B = [0x01175C68]` (cmdline override, key hash `0xea7dfc85`).
- chosen global `^ 0x6B3C35EB`; **default `0xECE78C8C` = signed `-320369524`** → `"mercs2-pc_ver_-320369524"`.
- If `global == 0x6B3C35EB` → `versionInt = 1`.
- The version is **region-keyed**: the base installer writes `HKLM\…\EA Games\Mercenaries 2 World in
  Flames\Region = mercenaries2_<sku>`; the game reads it → transform → override A → different region =
  **different version stamp = region-segregated matchmaking**. Theater filters `filter_version` on exact
  equality (`FUN_00983d30`); our `mercs2_server.py` ignores it, so mismatches don't block on our server.
See [[fesl-bversion-builder]] for the full formula (cracked from PPC builds: `((seed ^ 0x811C9DC5) *
0x01000193) ^ K`, base seed `0x15F119BE`, retail `K=0x12D`).

### 6.2 The FESL handshake flow (from the working restore)

`fsys Hello → MemCheck(server-push) → acct Login (auto-creates account) → GetPingSites → subs
GetEntitlementByBundle(REG-PC-MERCENARIES2-UNLOCK-1) → rank GetRankedStats → Theater CONN/USER/LLST/CGAM`.
FESL frames are `{4-byte type}{u32 BE id}{u32 BE length}{key=value\n payload}`. The B-version token
`mercs2-pc_ver_-320369524` is logged as `game_version`, never rejected.

### 6.3 The working restore stack (the reference implementation)

- **mod** `multiplayer_restore.asi` — `gethostbyname` DNS redirect → `127.0.0.1` + clock-spoof (2012,
  for the expired cert) + **CA-key patch** (§7).
- **tlsterm** `tlsterm/tlsterm_native.py` — pure-Python **tlslite-ng SSLv3/RC4** terminator with the
  genuine EA `fesl.cer` (`TLS_RSA_WITH_RC4_128_SHA`), listens `:18710` → forwards plaintext `:28710`.
- **server** `tools/mercs2_server.py` — py3 FESL + Theater + GameSpy.
- Proven 2026-06-28: game logs in, connects to Theater, hosts a co-op lobby (CGAM). Branch
  `feat/fesl-online-stack`. See [[mercs2-online-restore-and-patch-architecture]].
- **Patch delivery is NOT network** — `vz-patch.wad` is a local on-disk overlay (loader `FUN_004bfaf0`);
  the EA-Plasma content-download schema is compiled-in but dormant.

---

## 7. TLS / secure transport — can we move off SSLv3? (evidence-first feasibility)

**Question:** the restore stack terminates **SSLv3/RC4** (tlsterm). Can the game↔proxy leg be upgraded
to **TLS 1.2/1.3**?

### 7.1 What TLS library + version the game's client uses

The game's FESL TLS client is a **statically-linked OpenSSL 0.9.8d (28 Sep 2006)** — not SChannel, not a
custom EA/Massive stack. Evidence:
- Version string `"lhash part of OpenSSL 0.9.8d 28 Sep 2006"` + `.\rsa_import.c` (teknogods §OpenSSL).
- The SSL3 state machine is in the SecuROM-**unpacked** high-address region (`0x01dxxxxx`–`0x01exxxxx`),
  with the original OpenSSL source-file path strings intact: `.\ssl\s3_both.c` (`FUN_01e1c78f`),
  `.\ssl\s3_pkt.c` (`FUN_01e1d9bb`), `.\ssl\s3_lib.c` (`FUN_01e1cc3c`) — i.e. the `ssl3_*` functions.
- The BIO socket layer dynamically loads **WSOCK32.dll** (`FUN_01e67e2e`: `send`/`recv`/`connect`/
  `gethostbyname`), and reads `SSL_CERT_FILE`/`SSL_CERT_DIR`/`/usr/local/ssl/certs` — canonical OpenSSL.
- Live-captured ClientHello (`docs/coop_capture_server.md`): **record/client version `03 00` = SSL 3.0**;
  cipher suites **`0x0005` RC4_128_SHA, `0x0004` RC4_128_MD5**. Endpoint `mercs2-pc.fesl.ea.com:18710`.

**The ceiling is the library, not tlsterm's preference.** OpenSSL **0.9.8** supports **only SSLv3 and
TLS 1.0**. TLS 1.1/1.2 did not exist until OpenSSL **1.0.1** (2012); TLS 1.3 until **1.1.1** (2018).
There is **no TLS 1.2/1.3 code in the binary to enable** — the `ssl3_*`/`s23_*` state machine physically
cannot produce a TLS 1.2 `ClientHello` (no SHA-256 PRF, no AEAD/GCM, no `supported_versions` extension,
no modern cipher records). And it advertises `03 00` (SSLv3), so it is even below its own TLS-1.0
capability — consistent with the client being built on `SSLv3_client_method` (or an `SSLv23` method
that then negotiates down). Either way the **game leg is architecturally SSLv3/TLS-1.0-bound**.

### 7.2 Where the CA key + version are checked

The cert-validation reads a **CA public key baked into `.rdata` at `0x768378`** (128 bytes) — the
statically-linked OpenSSL validates the server chain against **this** key, **not** `WinVerifyTrust`.
Proven live ([[fesl-ca-key-patch-required]]): `ca_key_patch=0` → the game **RESETs** every handshake
(ConnectionReset 10054 right after the server Certificate); `ca_key_patch=1` → `handshake OK (SSLv3,
cipher=0x0005)` and the real `fsys Hello (165B)` flows. The protocol-version / cipher selection is **not
a single patchable constant** — it is the OpenSSL 0.9.8 method-table + cipher-list machinery spread
across `ssl3_*`; there is no "SSLv3-vs-TLS1.2" byte to flip because the TLS≥1.1 code isn't present.

### 7.3 The two legs

tlsterm is a **termination proxy**, so the two legs are independent:
- **(a) proxy↔upstream (server) leg** — already free to be **any modern TLS today**. tlsterm speaks
  plaintext to `mercs2_server.py`; if that hop ever crossed a network you'd wrap it in TLS 1.3 trivially.
  This is purely tlsterm's/our choice and needs **zero game changes**.
- **(b) game↔proxy leg** — bound to what the game's OpenSSL 0.9.8 offers: **SSLv3/RC4** (max TLS 1.0).
  Upgrading this requires making the game negotiate ≥TLS 1.2, which the linked library cannot do.

### 7.4 Feasibility verdict + concrete path

**Upgrading the game↔proxy leg to TLS 1.2/1.3 is (iii) infeasible by a constant/cipher patch, and
reduces to (ii) a full client-stack replacement** — because the modern-TLS code simply does not exist in
the 0.9.8d that ships in the exe. Concretely:
- **Not (i):** there is no version/cipher constant to patch — 0.9.8d has no TLS 1.2 record layer, PRF, or
  AEAD ciphers. Flipping a "version" byte produces an invalid ClientHello, not a TLS 1.2 one.
- **(ii) is the only real upgrade path: detour the OpenSSL entry points.** Because the SSL client is
  self-contained (its `SSL_connect`/`SSL_read`/`SSL_write`/BIO calls live at fixed VAs in the unpacked
  image, and it loads Winsock via WSOCK32 by name), a **DLL-shim / MinHook detour** can intercept those
  calls and route the FESL socket through a modern TLS library (SChannel, or a bundled rustls/OpenSSL-3).
  This is viable in principle — the same detour discipline the mods already use.
- **For the CURRENT centralized-ish restore, upgrading buys nothing** — the game↔proxy leg is
  **loopback** (`127.0.0.1` → tlsterm), so SSLv3/RC4 never touches the wire (zero exposure) — *if* you
  accept a tlsterm proxy in front of every server and a CA pin deciding who may host. **But that
  architecture does not decentralize** (§7.5).

### 7.5 Decentralized peer hosting — why it MUST be both (the real goal)

The point of moving off SSLv3 is **not** wire-security — it is **decentralized, player-hosted lobbies
with no embedded "trusted" cert**. That goal needs **two** things at once; neither alone suffices:

1. **Accept-any / self-signed cert** — removes the central trust anchor. Today the restore patches the
   128-B CA at `0x768378` to a *community* CA's public key, so every host still needs a cert signed by
   whoever holds that one authority's private key → centralized. Making the game accept a **self-signed**
   cert (or trust-on-first-use) means **any player hosts with their own cert, no blessed CA**.
2. **Modern TLS (1.2/1.3)** — **mandatory**, because **SSLv3 is removed from every current TLS
   library** (OpenSSL dropped it in **1.1.0 / 2016**; it needs `enable-ssl3` on the **EOL 1.0.2** to even
   build; SChannel/rustls/Go/BoringSSL refuse it outright). So a decentralized "anyone just runs a
   server" experience **cannot** require the game to speak SSLv3 — that forces every host to ship a
   bespoke legacy-SSLv3 terminator (`tlsterm`), which is precisely the fragile central artifact
   decentralization is trying to delete. For hosts to use **stock modern TLS tooling**, the game itself
   must speak TLS 1.2/1.3.

**So it has to be both — and one detour delivers both.** Since the in-exe OpenSSL 0.9.8d can produce
neither modern TLS nor a flexible trust policy, the fix is a **DLL-shim / MinHook detour that replaces
the game's OpenSSL *client API surface*** (`SSL_connect`/`SSL_read`/`SSL_write` + the WSOCK32 BIO — all
at fixed VAs in the unpacked `0x01dxxxxx`–`0x01exxxxx` OpenSSL blob, the same region as `s3_lib.c`
`FUN_01e1cc3c` and BIO loader `FUN_01e67e2e`) with a **modern TLS client** (rustls / SChannel /
OpenSSL-3) configured for **TLS 1.2/1.3 + accept-self-signed (TOFU)**. The game's ancient OpenSSL never
does a handshake — the shim does, with a current library, against the host's real server. This single
change **deletes both `tlsterm` AND the `0x768378` CA-key patch**, and lets any player host a stock
modern FESL server with a self-signed cert; clients connect directly.

**Corrected bottom line:** the "keep SSLv3 on loopback, no game changes" answer is right only for the
*current centralized restore* (game → tlsterm → one server) — it does **not** decentralize. **For
player-hosted lobbies with no embedded trusted cert, you must do BOTH — modern TLS and self-signed
trust — because SSLv3 no longer exists in any shippable TLS stack**, so you cannot lean on a legacy
terminator per host. The one change that delivers both is the **detour-replace-the-OpenSSL-client-API
shim** (§7.5), which also removes the `tlsterm` + CA-pin dependencies. (Once the modernization engine
replaces the exe entirely, the point is moot — the new client uses a modern TLS stack natively.)
**Concrete next step:** pin the game's `SSL_connect`/`SSL_read`/`SSL_write`/BIO entry VAs in the
`0x01dxxxxx`–`0x01exxxxx` blob (the detour targets) — confirm-live.

### 7.6 Detour targets — located (2026-07-06, confidence H on files, M on exact wrappers)

The statically-linked **OpenSSL 0.9.8** is fully decompiled in the unpacked image; `.\ssl\*.c` path
literals survive in `ERR_put_error` (`FUN_01de56d8`) calls, so every source file is identifiable:

| OpenSSL unit | Located function(s) | Role for the detour |
|---|---|---|
| `ssl_lib.c` | `SSL_CTX_new` = `FUN_01e18279` (@`.\ssl\ssl_lib.c:0xfd`); `SSL_clear` = `FUN_01e1811c` | object/ctx setup; `SSL_new`/`SSL_connect`/`SSL_read`/`SSL_write` public wrappers live in this same band — **the primary hook surface** |
| `s3_clnt.c` | `ssl3_connect` = the fn containing call site `0x01e1a3ad`; client-key-exch state `FUN_01e19b1d` (states `0x1170`–`0x1173`); server-key parse `FUN_01e19413` | the SSLv3 client handshake state machine — what the shim *replaces* |
| `s3_lib.c` | `ssl3_ctrl` = `FUN_01e1cc3c` | per-conn options |
| `ssl_cert.c` | verify-index alloc `FUN_01e1b411` ("SSL for verify callback"); cert dup/verify `FUN_01e1b79a` (`ssl_client`/`ssl_server`) | **cert-trust decision** — where CA-pin (`0x768378`) enforcement lands |
| `ssl_rsa.c` | `FUN_01e18a86`, `FUN_01e188a0` (via `SSL_CTX` setter `FUN_01e19b1d`) | RSA key install |
| BIO/socket | WSOCK32 loader `FUN_01e67e2e` (`s3_pkt.c`/`bio` region) | the transport BIO under `SSL_read/write` |

**Detour strategy (delivers BOTH modern TLS + self-signed in one shim):** MinHook the **public
`ssl_lib.c` wrappers** (`SSL_connect`/`SSL_read`/`SSL_write`/`SSL_shutdown`) — NOT the internal state
machine. The replacement runs a modern TLS client (rustls / SChannel / OpenSSL-3) over the same
socket fd the game's BIO already owns, negotiating **TLS 1.2/1.3** with an **accept-self-signed / TOFU**
verifier, and hands plaintext FESL bytes back to the game exactly as `ssl3_read_bytes` would. The
game's 0.9.8 handshake code (`ssl3_connect` and all of `s3_clnt.c`) is never entered, so neither the
SSLv3 lock nor the `0x768378` CA pin is in the path.

### 7.7 ✅ Detour target RESOLVED — SSLv3_client_method table (verified 2026-07-06)

**The single cleanest detour point is the `SSLv3_client_method` `SSL_METHOD` table** — patch three
function pointers in place and every `SSL_connect`/`SSL_read`/`SSL_write` call (which all dispatch
through `s->method->…`) reroutes to a modern-TLS shim, with **no wrapper hunt and no code patching**.

**Canonical shipping target = `output/_ghidra/securom_dump/mercs2_nodrm_v3.exe`** (the DRM-free rebuild;
SecuROM fully removed). Static PE parse confirms it shares the **corpus layout** — corpus
`SSL_CTX_new @ 0x01e18279` is byte-identical (`push ebx/esi/edi; push 0xFD; mov esi,0x020BA3F4; push
esi; push 0x108` = `FUN_01de61f1(0x108,".\ssl\ssl_lib.c",0xFD)`). So **§7.6's corpus VAs are directly
valid for `nodrm_v3`** (image base `0x400000`; OpenSSL code in `Stext` `0x01a49000–0x02084000`; OpenSSL
rodata in `Srdata`; the client method table in the **writable** `Sdata` `0x020e5000–0x023e3000`).

| SSL_METHOD field (offset) | VA in `nodrm_v3` | function | patch site (table+off) |
|---|---|---|---|
| table base (`SSLv3_client_method`) | **`0x0237ee88`** | returned by `SSLv3_client_method()` @ `~0x01e1a73f` (`mov eax,0x0237ee88; ret`) | — |
| `+0x10` ssl_accept | `0x01e17f75` | `ssl_undefined_function` (stub) → proves this is the **client** table | (leave) |
| `+0x14` ssl_connect | `0x01e1a09b` | `ssl3_connect` (contains corpus call site `0x01e1a3ad`) | **`0x0237ee9c`** |
| `+0x18` ssl_read | `0x01e1cfb0` | `ssl3_read` | **`0x0237eea0`** |
| `+0x20` ssl_write | `0x01e1ce94` | `ssl3_write` | **`0x0237eea8`** |
| `+0x24` ssl_shutdown | `0x01e1cda1` | `ssl3_shutdown` | (`0x0237eeac`, optional) |

**Detour install (boot-time shim, before first `SSL_CTX_new`):** overwrite the three DWORDs at
`0x0237ee9c` / `0x0237eea0` / `0x0237eea8` with the shim's `connect`/`read`/`write` thunks. `Sdata` is
`EW` on disk; **live-verified 2026-07-06 the page reads `PAGE_EXECUTE_WRITECOPY` (0x80)** — a plain
write succeeds via copy-on-write, so a `VirtualProtect→RWX` is optional (defensive only, to make the
patch explicit / dodge COW surprises), not required.

*Live confirmation (no-DRM image reloaded in x32dbg, 2026-07-06):* `0x01e18279` = `SSL_CTX_new`
prologue; `SSLv3_client_method()` @ `0x01e1a73f` = `mov eax,0x0237ee88; ret`; the table at `0x0237ee88`
reads `00 03 00 00 | … | 75 7f e1 01 (accept-stub) | 9b a0 e1 01 (connect) | b0 cf e1 01 (read) | … | 94
ce e1 01 (write) | a1 cd e1 01 (shutdown)` — byte-for-byte the static scan. Detour fully validated on the
shipping binary. The shim runs a modern TLS client
(rustls / SChannel / OpenSSL-3) over the socket fd the game's BIO already owns, doing **TLS 1.2/1.3 +
accept-self-signed (TOFU)** — delivering *both* halves of the goal at one struct, and deleting `tlsterm`
and the `0x768378` CA pin from the path. (Two other `version==0x300` tables exist — `0x0234d2f0` with
`Sdata`-relocated pointers, and `0x02380240` — neither is the client method the game's FESL `SSL_CTX`
uses; `SSLv3_client_method` `0x0237ee88` is the one, confirmed by its two live references.)

**Per-build caveat (the live-debug detour was a red herring):** the *running* process this session was a
**different** build, `mercenaries2.patched.uncracked.exe`, whose `.text`/`Stext` layout diverges from
the corpus (`0x01e18279` there is unrelated code; the BP never tripped). Corpus/`nodrm_v3` VAs are **not**
valid for `patched.uncracked`. **Ship and target `nodrm_v3`** (or re-run `tools/…/sslscan` — the
`version==0x300` + fn-pointer-block scan — against whatever exe a build uses; only the `Srdata` string
pool, e.g. `.\ssl\s3_clnt.c`, is a cross-build anchor).

---

## 8. Honest boundaries — dead services vs game layer

| Component | Status | Disposition |
|---|---|---|
| **Massive ad-net** (`CMassiveSocket`, `locate.madserver.net`, `/adsrv/4/*`, HMAC) | dead service; also an **in-game advertising SDK**, not co-op transport | **replace-don't-port ("M")**; irrelevant to co-op |
| **Xbox LIVE / XLSP / System Link** (`Xb360Session`, `XSession*`, `XNet*`, `XTitleServerCreateEnumerator`) | dead + **Xbox-only** (no PC path) | drop; PC uses FESL + Winsock peer mesh |
| **FESL / EA Plasma** (`fesl.ea.com`, Theater, GameSpy) | dead service, but **RESTORED locally** (§6) | swap transport for the local server stack |
| **GameSpy Voice** (`GVInitialize`) | dead voice service | drop or replace |
| **Net\* replication payloads** (§2–§4) | **the game logic** — the RPC/replication semantics | **reimplement ("G")** — this is the reuse target |

The scoreboard-relevant split: **Layers 2/3 are transports to replace; Layer 1 (Net\*) is the game
behaviour to reimplement** on the recovered Keystone-B bus.

---

## 9. Confirm-live inventory (x32dbg, read-only while PAUSED — [[x32dbg-mcp-no-resume]])

**The wire packet capture (the keystone open item):**
1. bp `FUN_005a0cc0` (`0x005a0cc0`) during a co-op `Net.SendCustomEvent`; step into `thunk_FUN_02ee0000`
   in the unpacked image and read its return (0 = local, nonzero = wire) + the input it tests (expect the
   category nibble / `IsServer` flag). This is the **local-vs-wire predicate**.
2. From the wire branch, step into `thunk_FUN_02935000` (encode) then `thunk_FUN_024f28e0` (emit); dump
   the buffer `*param_2` **before** the emit to capture the on-wire byte layout, and confirm it matches
   the Xbox record shape (§2.1: `{u32 hash}{4 type tags}{hdr}{argc words}`).
3. bp `FUN_007002d0`/`FUN_0059ddb0` and read `_DAT_0244fb3c`/`_DAT_0245dc0c` (the unpacked router fn
   pointers) to name the final dispatch target; hardware-bp the Havok `send`/`WSASend` (via `FUN_0089c710`
   socket obj+0x18) to catch the packet leaving the process → **the on-wire capture**.

**Receive side:**
4. bp the PC `NetEventCallback` cfunc (rdata `0x0047180`) on an inbound packet during a join; confirm it
   calls `SynchNetImportModule` first and re-drives the local bus (`FUN_005a0cc0` inbound counterpart).

**Join-time module pull:**
5. During a mid-session join, bp `SynchNetImportModule` (str `0x007D1D90`) + the module registry lookup;
   read the `0x762c8f61` registry record `+0x40` count and watch the pull event for the requested module
   hash (e.g. `hash("MrxFactionManager")`).

**FESL/TLS (already proven, re-confirmable):**
6. bp `FUN_008445d0` at login; read `player+0x164` for the B-version string + the `FUN_006c8cd0` globals
   (`0x017C0DF8`/`0x01175C68`) and the `^0x6B3C35EB` result.
7. bp the OpenSSL `ssl3_*` client entry (`FUN_01e1d9bb` region) to read the negotiated version/cipher
   live and confirm the `03 00` / `0x0005` ceiling; inspect `.rdata 0x768378` for the active CA key.

---

## 10. Reconciliation with `mercs2_engine` (row 28 = ❌ in-engine)

**Status: ❌ — there is no networking layer in the modernization engine today**, and there is no plan to
port the dead EA services. Two separate things stand in for row 28:
1. **The online-restore mod** (mod + tlsterm + `mercs2_server.py`) is the **working reference** for the
   *original exe's* online path — it is a mod on the retail binary, not engine code. It stays as the
   authentic-binary co-op solution.
2. **The reimplementation target** is **Layer 1 only — the Net\* replication/RPC layer on Keystone-B**,
   with the transport swapped for modern sockets:
   - Build the replication semantics on `mercs2_core::event` (the recovered 32-bit-hash + typed-TLV bus,
     ≤7 args): `Net.IsServer/IsClient`, `SendCustomEvent(channel, id, args)`, the `Net.SendEvent_*`
     fanout, and the `NetEventCallback` receive→re-drive path (§2).
   - Implement the **category descriptors** (`NetPrimaryCategory` + the 8 `NetSubCat*`) as the
     property-sync selector (§3), so only the right per-object properties replicate (health, inventory,
     seat-link, node health, importance) — the physics-driven-destruction model wants exactly this
     granularity (GDC 2008).
   - Implement the **join-time module pull** (`NetSynchImportModule`) against the engine's Lua module
     system — a joining client requests the host's authoritative script-table snapshot per channel (§4).
   - Implement **host-authoritative gating** (`NetSafe*`) and **client mirrors** (`NetClient*`) as the
     server-only-emits / client-only-applies split the Lua already encodes (`if Net.IsServer() then
     Net.SendEvent_*` ... clients reconstruct via `SetClient*Data`).
   - **Transport:** modern UDP/TCP (or QUIC) peer mesh — NOT the SSLv3/OpenSSL-0.9.8 stack. FESL/Theater
     auth is replaced wholesale (the modernization engine has no EA dependency). TLS, where used, is
     modern by construction (§7.4).
   - **Do NOT** port Massive, Xbox LIVE/XLSP, GameSpy Voice, or the region-keyed content-version gate —
     all dead (§8).

---

## 11. Provenance

- PC decomp: `output/_ghidra/mercs2_unpacked.exe_decomp.txt` (SecuROM-unpacked, base `0x400000`). Bodies
  read first-hand: `FUN_005a0cc0` (marshal core), `FUN_007002d0`/`FUN_0059ddb0` (remote islands),
  `FUN_006f4f80` (NetSafe bridge sender), `FUN_00644510` (NetCategoryInfo registrar), `FUN_009e010a`/
  `FUN_009dff40` (CNetworkManager), `FUN_009ba4b0` (matchmaking parser), `FUN_009cf970`/`FUN_009cfa10`/
  `FUN_0089c710` (peer-mesh sockets), `FUN_00846f40` (GameSpy Voice), `FUN_01e67e2e` (WSOCK32 loader),
  `FUN_01e1c78f`/`FUN_01e1d9bb`/`FUN_01e1cc3c` (OpenSSL ssl3), `FUN_008445d0` (FESL B-version).
- Xbox ground truth: `docs/mercs2-pdb-analysis/networking.md` — `NetEventCallback @825d3ce8`,
  `SynchNetImportModule @825ce918`, `NetSafeAreBriefingAssetsLoaded @825ce830` (read first-hand in
  `xenon_decomp_named.c`, base `0x82000000`), + §A–§G `.rdata` symbol inventory.
- Working restore (deepest slice): memory [[mercs2-online-restore-and-patch-architecture]],
  [[fesl-bversion-builder]], [[fesl-ca-key-patch-required]]; `tlsterm/tlsterm_native.py`,
  `tools/mercs2_server.py`, `docs/coop_capture_server.md`, `docs/online_restore_and_patch_delivery.md`.
- Community research: `docs/teknogods_coop_research.md` (3-layer stack + string inventory),
  `docs/exe_analysis_agent_b.md` §Network Replication (WS2_32/NETAPI32).
- Lua surface: `docs/lua_engine_bindings_audit.md` §3.2 (`Net.*` VAs) + NetClient\* string offsets;
  `docs/mercs2-luacd/03_contracts_jobs.md` §3.6; `docs/ui/main_menu_structure.md` §7 (`Net` table
  `0x00BB8154`).
- Cross-refs: `event_bus_code_map.md` (Keystone B — the shared bus + router), `faction_reputation_code_map.md`
  §8 (`Net*Faction*`), `world_streaming_code_map.md` (NetSafe→streaming),
  `docs/modernization/pangea_engine_alignment.md` §Keystone B (the wire-protocol gap).

## Appendix A — the Net.* Lua surface

Table name `"Net"` at `0x00BB8154`. Role/query cfuncs (bindings-audit §3.2, CERTAIN unless noted):

| Lua | PC string off | Role |
|---|---|---|
| `Net.IsMultiplayer` | `0x007B8130` | MP active |
| `Net.IsCoopMultiplayer` | `0x007B95D4` | co-op active |
| `Net.IsServer` / `Net.IsClient` | (registered) | host/client role gate (every replicated op checks this) |
| `Net.IsLobby` | `0x007B80F8` | in lobby |
| `Net.IsDedicated` | (registered) | dedicated server |
| `Net.IsOnlineConnected` / `IsPlatformConnected` / `IsConnectedToInternet` | share cfunc `0x005CAD10` | EA/online status |
| `Net.IsMatchmakingInternet` | (registered, ASI-hooked) | internet matchmaking |
| `Net.ConnectToServer` / `Net.StartServer` | (registered) | connect / host |
| `Net.EnterLobby` / `EnterFriendsLobby` / `ExitFriendsLobby` / `AutoLobby` | `0x007B8000`/`0x007B7FB4`/`0x007B7FA0`/`0x007B80C8` | lobby nav |
| `Net.QuitGame` | (registered) | network quit |

RPC / replication senders (the wire surface):

| Lua | Role |
|---|---|
| `Net.SendCustomEvent(channel, id, {args})` | per-mission RPC on a named channel → receiver's `NetEventCallback(id, tArgs)` |
| `Net.SendEvent_*` (44 dispatchers, ~`0x007998D0` region) | engine→client fanout: objectives, markers, fanfare, movie, support, revive, PDA blips, boundaries, tether, etc. |
| `Net.SetLoadingScreen` / `Net.SetBriefingStarters` / `Net.SetPursuitReportingState` | host-authoritative state pushes |
| `NETEVENT_*` constants | per-mission integer event ids (mission scripts define their own enums) |

`Lobby.*` events (`LobbyServerAdded` `0x007BBCF8` / `Updated` `0x007BBD48` / `Removed` `0x007BBD5C`) are
the server-list update callbacks.
