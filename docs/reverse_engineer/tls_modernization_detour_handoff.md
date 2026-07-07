# TLS Modernization Detour — Handoff Spec

**Status: RESEARCH COMPLETE, NOT COMMITTED.** The detour *target* is fully reverse-engineered and
live-verified (below). The decision to actually build it is **deferred** — the project owner wants to
reverse the networking protocols above TLS further before committing to a TLS version or a change this
large. **Do not start implementing the shim** until that protocol work is done and the owner green-lights
a target TLS stack. This document is the pick-up point.

Owner note (2026-07-06): *"I personally need to dig further into the networking protocols before I'm
ready to commit to a TLS version or such a large modification."*

Companion docs:
- [networking_code_map.md](networking_code_map.md) — §6 FESL/session restore, **§7 TLS/secure transport
  (§7.5 why-it-must-be-both, §7.6 OpenSSL function map, §7.7 the resolved detour target)**.
- Reproduction tool: [scripts/ssl_method_scan.py](../../scripts/ssl_method_scan.py).
- Memory: `memory/fesl-ca-key-patch-required.md` (CA-pin + decentralization + detour target).

---

## 1. The objective (why this exists)

The goal is **decentralized, player-hosted FESL lobbies with no embedded "trusted" cert** — any player
runs their own lobby server; clients connect without a central CA. That requires **BOTH**, and neither
half alone is sufficient (see §7.5 of the map for the full argument):

1. **Accept self-signed / any cert (TOFU)** — removes the central trust anchor. Today the online-restore
   mod patches the 128-B CA public key at `.rdata 0x768378` to a *community* CA, so every host still needs
   a cert signed by that one authority → still centralized.
2. **Modern TLS 1.2/1.3** — mandatory, because **SSLv3 is removed from every current TLS library**
   (OpenSSL 1.1.0+/2016; SChannel/rustls refuse it). A "anyone just runs a server" model cannot depend on
   the legacy SSLv3 terminator (`tlsterm`) sitting in front of every host.

The game statically links **OpenSSL 0.9.8** and speaks **SSLv3/RC4**, validating the FESL server cert
against the baked-in CA key (NOT `WinVerifyTrust`). It can do neither modern TLS nor flexible trust, so
the fix is to **replace the game's TLS client at the `SSL_METHOD` dispatch table** (§3). One intervention
delivers both halves and deletes `tlsterm` + the CA-key patch from the path.

**Scope boundary:** this changes only the **transport** (the TLS leg). The **FESL/Plasma protocol above
TLS** (packet framing, B-version handshake `^0x6B3C35EB`, Theater, the Net* replication payloads) is
untouched — that is the separate body of work the owner is reversing next (§6 of the map).

---

## 2. Canonical target binary

**`output/_ghidra/securom_dump/mercs2_nodrm_v3.exe`** — the DRM-free rebuild (SecuROM removed). This is
the binary the community should standardize on and the one all addresses below refer to.

- Image base `0x400000`. Shares the **corpus** (`mercs2_unpacked.exe`) layout — verified: corpus
  `SSL_CTX_new @ 0x01e18279` is byte-identical, so every §7.6 corpus VA is valid here.
- OpenSSL **code** in `Stext` (`0x01a49000–0x02084000`), OpenSSL **rodata** in `Srdata`, the SSLv3
  client method **table** in **writable** `Sdata` (`0x020e5000–0x023e3000`).
- ⚠ **Other builds differ.** The `mercenaries2.patched.uncracked.exe` build (used in an earlier live
  session) has a *different* `.text`/`Stext` layout — these VAs do **not** apply there. Only the `Srdata`
  string pool (`.\ssl\s3_clnt.c`) is a cross-build anchor. Re-run `scripts/ssl_method_scan.py <exe>`
  against any other build to re-pin.

---

## 3. THE DETOUR TARGET (verified — this is the deliverable)

**`SSLv3_client_method` `SSL_METHOD` table @ `0x0237ee88`.** All `SSL_connect`/`SSL_read`/`SSL_write`
dispatch through `s->method->…`, so overwriting three function pointers in this one table reroutes the
entire FESL TLS leg — **no code patching, no MinHook, no wrapper hunt.**

| SSL_METHOD field | offset | VA (`nodrm_v3`) | function | **patch site (write here)** |
|---|---|---|---|---|
| version | +0x00 | `0x00000300` | SSLv3 marker | — |
| ssl_accept | +0x10 | `0x01e17f75` | `ssl_undefined_function` (stub) → proves CLIENT table | leave |
| **ssl_connect** | +0x14 | `0x01e1a09b` | `ssl3_connect` (contains corpus call site `0x01e1a3ad`) | **`0x0237ee9c`** |
| **ssl_read** | +0x18 | `0x01e1cfb0` | `ssl3_read` | **`0x0237eea0`** |
| ssl_peek | +0x1c | `0x01e1cfc9` | `ssl3_peek` | (optional) |
| **ssl_write** | +0x20 | `0x01e1ce94` | `ssl3_write` | **`0x0237eea8`** |
| ssl_shutdown | +0x24 | `0x01e1cda1` | `ssl3_shutdown` | (optional, `0x0237eeac`) |

The table is returned by `SSLv3_client_method()` @ `0x01e1a73f` (`mov eax, 0x0237ee88; ret`).

### Live verification (x32dbg, no-DRM image, 2026-07-06)
- `MemoryBase(0x01e18279)` → base `0x1a49000` size `0x63b000` = `Stext` ✓
- `0x01e18279` disasm = `push ebx/esi/edi; push 0xFD; mov esi,0x20BA3F4; push esi` = `SSL_CTX_new` ✓
- `0x01e1a73f` = `mov eax,0x237EE88; ret` = `SSLv3_client_method()` ✓
- Table read @ `0x0237ee88` (40 B): `00030000 b8c8e101 b5c9e101 11c9e101 757fe101 9ba0e101 b0cfe101
  c9cfe101 94cee101 a1cde101` — byte-for-byte the static scan ✓
- `MemoryGetProtect(0x0237ee9c)` = `0x80` = **`PAGE_EXECUTE_WRITECOPY`** → writable via copy-on-write;
  a plain write succeeds. `VirtualProtect→RWX` is **optional** (defensive/explicit), not required.

### Reproduce from the file (no debugger)
```
python scripts/ssl_method_scan.py output/_ghidra/securom_dump/mercs2_nodrm_v3.exe
```
Scans for `version==0x300` + a following block of ≥9 executable-VA pointers; the CLIENT table is the one
whose `ssl_connect` is a real function and `ssl_accept` is the shared stub. (Two other `0x300` tables
exist — `0x0234d2f0` with Sdata-relocated pointers, and `0x02380240`; neither is the client method the
game's FESL `SSL_CTX` uses.)

---

## 4. Proposed shim architecture (design sketch — build only after green-light)

A small DLL loaded before the first `SSL_CTX_new` (e.g. the existing restore ASI, or an import-table
shim). At init it writes three DWORDs into the table:

```
*(void**)0x0237ee9c = &shim_ssl_connect;   // was ssl3_connect
*(void**)0x0237eea0 = &shim_ssl_read;      // was ssl3_read
*(void**)0x0237eea8 = &shim_ssl_write;     // was ssl3_write
// (optionally ssl_shutdown @0x0237eeac, ssl_peek @0x0237eea4)
```
All are `__cdecl`, first arg `SSL *s` (OpenSSL 0.9.8 uses cdecl on Win32; confirm calling convention on
disasm before trusting):
```
int  shim_ssl_connect(SSL *s);                       // return 1 = handshake complete
int  shim_ssl_read (SSL *s, void *buf, int num);     // bytes read, or <=0 + WANT_*
int  shim_ssl_write(SSL *s, const void *buf, int num);
```
The thunk keeps a `SSL* → modern-TLS-session` map. On first `connect`, it pulls the socket **fd** the
game already created (§5, OPEN) and runs a **rustls** (or SChannel / OpenSSL-3) client handshake over it:
TLS 1.2/1.3, `ClientConfig` with a **no-op / TOFU certificate verifier** (`dangerous_configuration`),
no CA. Thereafter `read`/`write` pump plaintext FESL bytes through the rustls session.

Config knobs the shim should expose: min TLS version, verify mode (`none` | `tofu` | `pinned-fingerprint`),
optional pinned SPKI for a semi-trusted community mode.

---

## 5. OPEN QUESTIONS / prerequisites (resolve BEFORE building)

1. **TLS library + version** — owner has NOT committed. Candidates: rustls (clean, static, cross-platform,
   `dangerous_configuration` for TOFU), SChannel (native, no dep, but Windows-coupled), OpenSSL-3. Decide
   min version (1.2 floor vs 1.3-only) and the trust modes to support.
2. **`SSL* → fd` bridge (needs reversing).** The shim must obtain the socket fd for a given `SSL*`. In
   OpenSSL 0.9.8 the game calls `SSL_set_fd`/`BIO_new_socket` before `SSL_connect`; the fd lives at
   `SSL->rbio → BIO->num`. **Pin the `ssl_st.rbio` offset and the `bio_st.num` (fd) offset** in
   `nodrm_v3` (or, simpler, also detour `SSL_set_fd`/`SSL_set_bio` to capture fd keyed by `SSL*`). Not yet
   located — first task for the implementing agent.
3. **Non-blocking semantics (correctness-critical).** The game very likely drives the handshake on a
   **non-blocking** socket, looping on `SSL_connect`/`SSL_read` and checking `SSL_get_error` for
   `SSL_ERROR_WANT_READ/WANT_WRITE`. The shim MUST reproduce those return codes and the BIO retry flags
   exactly, or the game's state machine stalls. Reverse how the game inspects errors after each call
   (find its `SSL_get_error` call sites) and mirror it. This is the biggest correctness risk.
4. **Server side is part of "both".** For a real modern-TLS handshake the **lobby server** must present a
   modern-TLS endpoint too (self-signed). Decide: modern FESL server (replace tlsterm) vs a thin modern-TLS
   reverse-proxy in front of the existing plaintext `mercs2_server`. Either way `tlsterm`/SSLv3 goes away.
5. **Install timing + loader.** Must patch the table before the first `SSL_CTX_new`. Which loader
   (restore ASI? IAT shim? `LoadLibrary` order?) and does anything read the table pointer earlier?
6. **Interaction with the restore stack.** This change makes the `0x768378` CA-key patch and `tlsterm`
   **unnecessary**; confirm the DNS-redirect + clock-spoof pieces still behave (clock-spoof may still be
   needed if any non-TLS date check remains). See `memory/mercs2-online-restore-and-patch-architecture`.
7. **Cross-build coverage.** Only `nodrm_v3` is pinned. If other exes ship, run the scanner per build;
   consider making the shim resolve the table at runtime (scan for `SSLv3_client_method`'s
   `mov eax,imm32; ret` or the `0x300`+pointer-block signature) so one DLL works everywhere.
8. **Reversibility / safety.** Keep the original three pointers so the shim can restore them; gate behind a
   config flag; fail open to the stock SSLv3 path if the modern handshake errors, for A/B testing.

---

## 6. What to reverse next (the owner's stated prerequisite)

Before committing, deepen the **protocol-above-TLS** picture — this is orthogonal to the detour and lives
in [networking_code_map.md](networking_code_map.md):
- §6 FESL/Plasma session flow, B-version handshake (`FUN_008445d0`, `ver ^ 0x6B3C35EB`), Theater/matchmaking.
- §2–§4 the Net* replication/RPC payload semantics (the actual game-logic wire format — the reuse target).
- Confirm exactly what the FESL leg carries end-to-end (auth tokens, session keys) so the modern-TLS
  channel's trust model (TOFU vs pinned) is chosen with the threat model understood.

---

## 7. One-line summary for the next agent

The "modern TLS + no trusted cert" goal reduces to **three 4-byte writes** at `0x0237ee9c / 0x0237eea0 /
0x0237eea8` in `nodrm_v3`, redirecting `ssl_connect/read/write` to a rustls/SChannel shim (TLS 1.2/1.3,
accept-self-signed). Target is fully verified live. **Blocked on:** (a) owner's protocol-reversing +
TLS-stack decision, (b) pinning the `SSL*→fd` bridge, (c) matching OpenSSL's non-blocking `WANT_*`
semantics. Do not implement until (a) is resolved.
