---
status: current
evidence: proven (static) unless a row says otherwise
supersedes: docs/reverse_engineer/tls_modernization_detour_handoff.md (TLS hook target)
---

# Multiplayer rewrite — client network stack, as the exe implements it

Reference for the `shipments/multiplayer-restored/` client ASI and the `src/multiplayer-server/` Rust server.
Per-message field catalogue (every TXN / 4CC, request and reply fields, Wally `server.py` disagreements):
[`multiplayer_txn_catalogue.md`](multiplayer_txn_catalogue.md).
Every row cites the client code it was read from. Grades: **P** = proven by reading the decomp / bytes,
**I** = inferred, **G** = gap (not found).

Sources: `output/_ghidra/mercs2_unpacked.exe_decomp.txt`, raw bytes of
`output/_ghidra/securom_dump/mercs2_nodrm_v3.exe` / `mercs2_unpacked.exe`. In `.rdata`, **VA = file offset +
0x400000** (P: the CA key the old restore patches at "RVA 0x768378" is VA `0xb68378`). Addresses below are
VAs for the nodrm_v3 / unpacked image; other builds need their own tables.

Not live-verified (owner chose to proceed on the static evidence, 2026-10-10). The check, if a hook misbehaves:
one-shot breakpoints on `0x009da500` (ProtoSSLUpdate, expected to hit at login) and `0x01e1a09b` (OpenSSL
`ssl3_connect`, expected NOT to hit).

---

## 1. The stack

```
FESL / Theater / Messenger service code   (TXN builders, handlers)
        │  TagField text  (§3)
ProtoAries   12-byte frame layer  (§2)       'pari'  0x9cd2e0–0x9cdab0
        │
ProtoSSL     TLS (SSLv3) or plain TCP (§4)   'pssl'  0x9d7ff0–0x9daa30
        │
DirtySock socket layer                       'dsoc'  0x9cf730–0x9cfcc0
```

Gameplay UDP is a separate stack: game sockets on virtual ports → ProtoTunnel → one UDP socket (§6).
GameSpy Voice is a third, raw UDP path (§7).

**The OpenSSL 0.9.8d in the image is not on this path** (P): `SSL_CTX_new` (`FUN_01e18279`) has no callers;
the OpenSSL code sits in SecuROM sections. The SSL_METHOD detour in
`tls_modernization_detour_handoff.md` therefore does not touch FESL.

## 2. Frame layer (ProtoAries)

| Item | Value | Evidence |
|---|---|---|
| Header | `kind` BE32 (4CC bytes in order), `id` BE32, `length` BE32 | P `FUN_009cd880` |
| `length` | total frame size **including** the 12-byte header (`payload + 0xC`; +8 only with the off-by-default `?tic`/`@tic` ticket cipher) | P `FUN_009cd880`, `FUN_009dacc0` |
| Receive check | `length < 12` or `> buffer` → connection closed, no resync | P `FUN_009cd3f0` |
| Client payload | TagField text + 1 NUL (`size = strlen + 1`) | P `FUN_00970400` |
| Receive buffer | `ProtoAriesCreate(bufsize + 0x80)`; Theater/Messenger bufsize `0x1fa0` → max 8224 B | P create; I which thunk feeds it |
| FESL max frame | `fragmentSize + 0x80`; client reports `fragmentSize` in `fsys Hello` | I; **G** default value |
| Synthetic events | kind=id=`0xFFFFFFFF` connected; id `0xFEFEFEFE` disconnected | P `FUN_009cd3f0`, `FUN_009773e0` |

## 3. TagField payload

| Rule | Evidence |
|---|---|
| Field = `key=value\n`; the last one too | P `FUN_009cc820`, `DAT_00cdec50` |
| Re-setting a key removes it and appends at end | P `FUN_009cc000` |
| String with `' '` or `','` is wrapped in `"…"` | P `FUN_009cc820` |
| Escaped as `%xx` lowercase: 0x00–0x1F, `"`, `%`, `=`, 0x7F; everything else raw (incl. 0x80–0xFF) | P table `0xb67348` (dumped), hex `0xb67448` |
| Integers signed decimal; 64-bit via `%I64d`; binary `$` + hex | P `FUN_009cc370`, `FUN_009cc630` |
| Key lookup: case-insensitive (fold `0xb67558`, ASCII a–z only); at buffer start or after a byte `< 0x21`; must be followed by `=`; first match wins; a byte `< 0x21` right before a candidate `=` aborts the lookup | P `FUN_009cc1e0` |
| Value read: leading `"` → to next `"`; else to first space; always stops at `< 0x20`; `%%` → `%`; `%XX` hex (table `0xb67458`) | P `FUN_009cc4e0` |
| Integer read: `-`/`+`, `$` = hex | P `FUN_009cc470` |
| Lists `name.[]=N` + `name.<i>.field`; `{…}` is literal key text (`props.{games}.[]`) | P format strings `0xb5f5a8` ff. |

**Consequence:** a server value with a space must be quoted, or the client truncates it at the space.

## 4. ProtoSSL — the TLS hook surface

All entries are ordinary `.text` cdecl bodies, not SecuROM thunks (P: no references from SecuROM sections,
normal prologues; first 0x40 bytes identical in nodrm_v3 and unpacked).

| VA | Role | Signature / behaviour | Evidence |
|---|---|---|---|
| `0x9d9910` | Create | `ref* ()`; 0x128-byte ref | P |
| `0x9d9950` | Destroy | `(ref)` | P |
| `0x9d9980` | Accept | `ref* (lref, secure, addr, *addrlen)`; 0 if secure | P |
| `0x9d9a00` | Connect | `int (ref, secure, name, ip, port)`; 0 or −9 | P (`add esp,0x14` @`0x9cd572`) |
| `0x9d9b80` | Disconnect | `0 (ref)` | P |
| `0x9da500` | Update | DNS → connect → handshake state machine, record pump | P |
| `0x9da8c0` | Send | `int (ref, buf, len)`; len<0 = strlen | P |
| `0x9da960` | Recv | `int (ref, buf, len)` | P |
| `0x9daa30` | Stat | `int (ref, sel, buf, len)` | P |
| `0x9d8070` | Reset (internal) | ref in EAX, secure in EBX | P |

**SocketConnect (`0x9cf970`) has exactly one caller, ProtoSSLUpdate** (P) — every outbound TCP connection the
game makes goes through ProtoSSLConnect.

**Ref layout (0x128 B):** `+0x00` SocketT*, `+0x04` async DNS job, `+0x08` memgroup, `+0x0c` hostname (≤255,
`:port` suffix overrides port), `+0x10c` sockaddr (port `+0x10e` BE, ip `+0x110` BE), `+0x11c` **state**,
`+0x120` closed flag, `+0x124` secure block (NULL = plain). (P)

**States:** 1 DNS, 2 connect, 3 connecting, 0x14–0x1a handshake, **0x1e secure connected**, **0x1f plain
connected**, ≥0x1000 failure (0x1001 DNS, 0x1002 connect, 0x1003 cert, 0x1004 handshake). (P)

**Return-code contract a replacement must keep** (P):
- Send: 0x1e → 0 if a record is in flight, else `min(len, 16000)`; 0x1f → raw socket send; other → −1.
- Recv: 0x1e → decrypted bytes, 0 if none, −1 if closed; 0x1f → raw recv (−1 on close); other → −1.
  Writes a NUL at `buf[n]` when `n < len`.
- Stat `'stat'`: −1 if state ≥ 0x1000; 0 while connecting/handshaking; 1 when 0x1e/0x1f. `'sock'`, `'peer'`,
  `'conn'`, `'bind'`, `'prot'` forward to the socket layer.
- Socket layer maps WSAEWOULDBLOCK / **WSAECONNRESET** / ERROR_IO_PENDING → 0; orderly close (`recv()==0`) → −1.
- ProtoAries: Stat < 0 → disconnect; > 0 → connected event; Send/Recv < 0 → destroy ref, disconnected event.

**Who connects how** (P for the `secure` argument; I for the Theater/Messenger labels, from the 4CCs each
module registers):

| Service | Connect site | secure | Default port |
|---|---|---|---|
| FESL | `0x973697` | `!(obj->vfn+0x48())`, normally 1; name literal `"fesl.ea.com"` | from config (18710 per captures) |
| Theater | `0x96def0` | **0** (plain) | 14300 (`0x37dc`) if server gives < 1 |
| Messenger | `0x96dda0` | **0** (plain) | 13505 (`0x34c1`) |

**Certificate checks** (P, disassembly `0x9d8b10–0x9d9907`): leaf certificate only; **exact, case-sensitive
compare of the Connect name against the subject CN** (no wildcards); issuer matched against the CA table at
`0xb684f8` (OTG3, modulus `0xb68378`, e=3; RSA Data Security "Secure Server CA", e=65537); RSA signature with
MD5/SHA-1. **No validity-date check** — the old 2012 clock spoof is not explained by ProtoSSL (G: whatever
needed it, if anything).

**Record limits:** send payload capped at 16000; the receive record length is **not** checked against the
0x4000 buffer (P `0x9da290`) — a peer sending a larger record overflows the client.

## 5. FESL and Theater above the frame

**FESL id word** (P, vtable `0xb5faec`, `0x976690`): `id = tid&0xFFFFFF | 0x80000000 | (multipart ? 0x30000000)
| (request ? 0x40000000)`. tid counts from 1 per connection (`FUN_00985480`). Receive reads only the tid and
bit 29. tid 0 → service dispatch (`FUN_009863a0`).

**FESL multipart** (P): client → server when text > `fragmentSize`: base64 (standard alphabet, `0xb67798`) of the
whole text, pieces of `min(rem, fragmentSize − 0x20)`, id `0xF0000000|tid`, kv `size=<b64 len>` + `data=`
(`FUN_0097ccb0`). Server → client: multipart bit set; first part carries `decodedSize=`; every part `data=`;
each part's `data` length a multiple of 4 with padding only at its end (`FUN_00975f80`, `FUN_009cd060`).
Separate service-level paging `chnk`/`GetNextChunk` exists (`FUN_00977fd0`); only used when the client sends
`chunkSize=` (I).

**Theater id word** (P, vtable `0xb5ec94`, encoder slot `+0x18` = `0x970600`, disassembled 2026-10-11 — not in the
Ghidra decomp): `id = flag ? 0x40000000 : 0`, the flag passed per send. Live 2026-10-11: CONN USER LLST GLST GDAT CGAM
EGAM EGRS PENT arrive with `0x40000000`; UGAM (with `TID`) and the answer to a server PING push arrive with `0`. Which
sender passes which flag: G (the sender is behind SecuROM split-thunks). On server frames **id = error code** (0 = OK). Transaction id is the kv `TID`, appended last. No multipart. Messenger uses kv `ID`.

**Timers** (P): TCP connect timeout 16000 ms → −201; inactivity timeout = Hello-reply `activityTimeoutSecs` ×1000
(0/absent → 240000 ms) → −206; **any inbound frame resets it**.

**Hello reply fields read** (P `FUN_00972560`): `theaterIp/Port`, `messengerIp/Port`, `addressRemapping`
(≤0x400 B; G: no consumer found), `activityTimeoutSecs`, `curTime`.

**TXN set: pre-"Nu" Plasma** (P — no `Nu*` strings in the exe). Services: `fsys acct subs asso rank pres pnow
recp thtr fltr msgr fpla fdbk xmsg fcms club gsum achi`. acct includes `Login`, `AddAccount`, `GetCountryList`,
`GetTos`, `SuggestScreenNames`, `UpdatePassword`, `SendPassword`, `LookupUserInfo`, `GetTelemetryToken`,
`GameSpyPreAuth`; fsys `Hello Ping Goodbye Suicide MemCheck GetPingSites GetNextChunk ExpireAllChunks`.
Errors: int `errorCode`, `localizedMessage`, `errorContainer.%d.fieldName/.fieldError`. Code→UI string map
`FUN_006caf20` (101, 102, 103, 120, 250, −165, −221 → stringdb hashes; G: which TXN, hash names).
G: which TXNs the login/create screens actually send.

**CGAM request keys** (P `FUN_00980a60`): LID, RESERVE-HOST, NAME, PORT, HTTYPE, TYPE, QLEN,
DISABLE-AUTO-DEQUEUE, HXFR, INT-IP, INT-PORT, MAX-PLAYERS, B-maxObservers, B-numObservers, PASSWORD (only when
set), UGID, SECRET, B-U-*, B-version, RESERVE-IDS, RESERVE-TIMEOUT, JOIN, RT. Reply (`FUN_0097b9b0`):
MAX-PLAYERS, SECRET, UGID, JOIN, **EKEY**.

**Peer-address fields** (P): EGRQ (to host, `FUN_0097c000`): `IP PORT R-INT-IP R-INT-PORT` + identity fields;
EGEG (to joiner, `FUN_0097c420`/`FUN_00981490`): `I P INT-IP INT-PORT HUID PL PID TICKET UGID EKEY`. IPs parsed
with `%d.%d.%d.%d` — numeric only. `PL=xbox` copies external over internal.

**No private/password game option in the UI** (P): shell Lua calls `Net.StartServer(Net.GetHostName(), level,
script)` only (`docs/mercs2-luacd/src/shell/mrxguishell.lua:599`). A friends path exists
(`Net.EnterFriendsLobby`, `joinFriendsGame`).

## 6. ProtoTunnel — gameplay UDP

| Item | Value | Evidence |
|---|---|---|
| Socket | one UDP socket bound `0.0.0.0:10000`; on failure retries port 0 | P `FUN_00844770` (`push 0x2710`), `FUN_009d1f90`, `0x99086e` |
| Virtual ports | 6000–6003; game sockets connect to the tunnel id (`0x01000000+n`) as if it were an IPv4 | P `FUN_00990580`, `FUN_009d1230`, `FUN_00993d00` |
| Encryption | RC4 keyed by the Theater `EKEY` (16 chars, default `"E_KEY"`); ports 6001/6002 + control encrypted, 6000/6003 plain | P wire code; I EKEY→key plumbing |
| Wire | BE16 RC4 offset; N × BE16 `len<<4 | portIndex`; index 7 = control `00 clientId(BE32) active`; payloads | P `FUN_009d0b90`, `FUN_009d0fe0` |
| Peer address | Theater ext (`I/P`, `IP/PORT`) and int (`INT-IP/INT-PORT`) pairs; falls back ext↔int on timeout and NOTs the key | P `FUN_00999130`; G which is tried first |
| Inbound | accepted if src == configured peer; else an inactive tunnel whose key decrypts a control packet with the right clientId **rebinds to the observed source** (NAT learning); once active, other sources dropped | P `FUN_009d1af0` |

**Consequence for the relay** (I, design): give both pairs the same `127.0.0.N:port`; the relay forwards
ProtoTunnel datagrams opaquely (they are RC4-encrypted and carry the clientId inside); no payload rewriting.

## 7. GameSpy Voice

UDP `0.0.0.0:55123`, sends to `inet_addr(peer):55123`, outside ProtoTunnel (P `FUN_00846f40`). Peer string
from `FUN_0096c000` over an address object obtained via `peer->vt[0x38]()->vt[0x24]()` (P); that it is the
Theater-supplied pair is I. Must be redirected by the ASI separately from the tunnel.

## 8. Other endpoints

| Endpoint | Path | Evidence |
|---|---|---|
| `fesl.ea.com` (`0xb5fbac`); `mercs2-pc.fesl.ea.com` assembled from `.fesl` + `.ea.com` | ProtoSSL Connect name | P string + connect site; live captures |
| `locate.madserver.net` (`0xb6882c`) | Massive ad SDK, runtime `getaddrinfo` (`FUN_009e2d61`) with `gethostbyname` fallback | P |
| SSDP `239.255.255.250:1900` | ProtoUPnP `FUN_009d6990` | P |
| SecuROM activation hosts | SecuROM sections | P strings; I owner |
| GameSpy servers | **none** — no gamespy/gpcm/natneg/master hostnames in the exe | P whole-file search |

## 9. Corrections to earlier docs

- `tls_modernization_detour_handoff.md`, `networking_code_map.md` §7.7: the SSL_METHOD table at `0x0237ee88`
  belongs to the SecuROM-section OpenSSL, not FESL. Hook ProtoSSL (§4).
- `networking_code_map.md`: `0x00762dfc`, `0x00763ad4`, `0x007B8000` are file offsets; VAs are `+0x400000`.
  `FUN_009cf970`/`FUN_009cfa10` are DirtySock socket functions, not Havok. `CNetworkManager` /
  `ServerAddressArray` (`FUN_009e010a`) belong to the Massive SDK (I).
- `FUN_009cdab0` is ProtoAries Connect, not ProtoSSL Connect.
- `coopserver/fesl.py`'s "length may exclude the header" fallback has no basis in the client (§2).

## 10. Join-deny reasons

The game keeps a denial reason as **one integer**. Read 2026-10-10 from the decomp and the exe bytes
(`%d` = `"%d"` at `0xbbc178`; `0x%x` at `0xba8ad8`; LAN strings `f` at `0xbb23e4`, `c` at `0xbb23c4`).

| Where | What it does | Grade |
|---|---|---|
| EGEG parser `FUN_00981490` (caller `FUN_009a7730`) | `REASON` first char `c`→2, `f`→0, `h`→10, `q`→9, `r`→1, `t`→5; anything else `sscanf("%d")` into the same int. **No `w` case** here. | P |
| QENT parser `FUN_00974090` (caller `FUN_0099da90`) | same map plus `w`→3 | P |
| EGEG handler `FUN_009a7730` | empty `TICKET` = denial: stores the error 4CC (`'jden'`) and the reason int (matchmaker `+0x20c` / `+0x210`), state 4 | P |
| state-4 dispatch (`switch(+0x208)`, decomp near line 852300) | `FUN_0098eee0('jden')` → −605 (`-0x25d`); listeners get `(−605, reason)` via `FUN_009c48d0` → vtable `+4` | P |
| `FUN_009ad330` / `FUN_009abea0` | next layer maps −605 → −804 (`-0x324`) and broadcasts `(…, reason, −804)` to its listeners (`FUN_009c49d0`, vtable `+4`) | P |
| UI text per reason | not traced past `FUN_009ad330`'s broadcast; no shell/resident Lua references a join-failure reason or −804 (grep of `docs/mercs2-luacd/src`) | G |
| EGRS builder `FUN_0097b380` (no static caller; vtable) | `LID GID ALLOWED PID`; `REASON` = `sprintf("%d", reason)` **only when `ALLOWED`=0** | P |
| Host auto-gate `FUN_0098fc80` | returns 2 "Denying participant %s (id = %i) because game is closed" (`0xb62170`), 6 "…observer… because game doesn't support observers" (`0xb62200`), 7 "…observer… because game has no available observer slots" (`0xb621b0`), else 0 | P |
| Gate → EGRS | `FUN_009a7a90` (`0x9a7ab5` call, `0x9a7af1` `push ebp` = gate result) passes the gate's return to the Theater client's vtable `+0x5c` with the PID; that slot being the EGRS-deny sender is I (it is the only `REASON`-int path and `FUN_0097b380` has no static caller) | P/I |
| LAN EGAM `FUN_0099efe0` | its own refusals: state 1 → `'ngam'`; 2 → `'jden'` `REASON=f`; 3 → `'jden'` `REASON=c` | P |
| LAN host relay `FUN_009a0e80` → joiner `FUN_0099cae0` | reads the host's EGRS `REASON` as an integer and sends the joiner `'jden'` with `REASON` = that integer (`FUN_00975800`), i.e. verbatim | P |

Meanings: 2 = closed (P: gate string, and `c`→2). 0/`f` = full (I: the letter, and it is the LAN emulator's
other server-side EGAM refusal beside `c`; which LAN condition produces state 2 was not traced). 6/7 = observer
reasons (P), not reachable for players. 1/`r`, 5/`t`, 9/`q`, 10/`h`, 3/`w` = G (letters only).

**How the rewrite uses them** (`mp_api::ws::JoinDenyReason`, `shipments/multiplayer-restored/client/src/theater.rs`):

| Denial | API | `REASON` to the joiner's game |
|---|---|---|
| host's game answered EGRS `ALLOWED=0` | `host_denied { code }` (the EGRS integer; a non-integer `REASON` fails the connection) | `code` as an integer, as the LAN relay does |
| host ASI: second joiner, no relay mesh | `mesh_unsupported` | `f` (closest: full for this ASI) |
| host closed/left while the request was pending | `game_removed` (server-generated) | `c` (no evidenced code; closest: closed) |
| `games_join` → no free slot | error `game_full` | EGAM `'jden'` `REASON=f` |
| `games_join` → closed to joins | error `game_closed` | EGAM `'jden'` `REASON=c` |
| `games_join` → no such (visible) game | error `not_found` | EGAM `'ngam'` |
