# Online multiplayer restoration + patch-delivery investigation

Session 2026-06-28. Two outcomes: (1) Mercenaries 2 PC online multiplayer
restored **end-to-end on a stock Windows host** (no Docker/WSL/VM); (2) a
triple-verified answer to "does the game download a `vz-patch.wad`?".

## 1. Online multiplayer — restored

The game logs in, connects to Theater, and hosts a co-op lobby against a fully
local stack:

```
game --SSLv3/RC4--> tlsterm(:18710) --plaintext--> mercs2_server(:28710 FESL)
                                                    + Theater :18715, GameSpy :27900
```

- **Client:** `multiplayer_restore.asi` (ported to the mercs2-qol-mods SDK).
  Hooks: `gethostbyname` DNS redirect, `WinVerifyTrust` blindfold, clock-spoof to
  2012, and the **FESL CA-key patch** (`.rdata` RVA `0x768378`). The CA-key patch
  is **required**: the FESL TLS uses a statically-linked OpenSSL that validates
  the server cert against a CA key baked into the EXE (not `WinVerifyTrust`); on
  the cracked EXE that key isn't EA's, so even the genuine cert fails without it.
  Verified live: patch off → every handshake resets; on → completes.
- **Legacy TLS:** `tlsterm/tlsterm_native.py` — pure-Python (**tlslite-ng**)
  SSLv3 + RC4 terminator using the genuine EA `fesl.cer` (negotiates
  `TLS_RSA_WITH_RC4_128_SHA`). Replaces the Docker stunnel/OpenSSL-1.0.2 sidecar.
  **Key bug fixed:** `socket.create_connection(timeout=5)` leaves a 5 s timeout on
  the *upstream* socket, so the tunnel tore down every idle FESL session at ~5 s —
  before the game ever sent `NuLogin`. Fix: `up.settimeout(None)`.
- **Server:** `tools/mercs2_server.py` — Python-3 port of
  loganw234/Mercenaries2 `server.py` (FESL + Theater + GameSpy + UDP relay),
  served plaintext behind tlsterm. `coopserver/` was also made FESL-complete.

Use **Login** (any username/password — the server auto-creates the account), not
Create. Observed flow: `fsys Hello → MemCheck(server push) → acct Login →
GetPingSites → subs GetEntitlementByBundle(REG-PC-MERCENARIES2-UNLOCK-1) → rank
GetRankedStats → Theater CONN/USER/LLST/CGAM`. The client advertises content
version `B-version=mercs2-pc_ver_-320369524` and leaks its MAC address, a
plaintext password, and its LAN IP.

## 2. Patch delivery — there is no network patch download

Confirmed three independent ways (a double-blind 3-investigator RE panel +
adversarial cross-check; live network capture; static inspection of the
**unpacked** image in x32dbg):

- **The real patch mechanism is a local on-disk WAD overlay.** Boot loader
  `FUN_004bfaf0` mounts `<stem>-patch.wad` (`vz-patch.wad`, `english-patch.wad`,
  `loading-patch.wad`) over the base WADs **if present** on disk. Missing base WAD
  → fatal exit; missing `-patch.wad` → silently tolerated. This is how the
  official 1.1 patch and DLC ship content — and the vector for our WAD/DLC work:
  drop a `vz-patch.wad` next to `vz.wad` and it loads, no network.
- **The EA-Plasma `fcms`/`online_content` content-download path is compiled in but
  dormant.** The schema strings (`online_content` @`0xB5D2EC`, `fcms` @`0xB5D2FC`,
  `DOWNLOAD_URL` @`0xB5D37C`, …) are present in the live unpacked image but are
  referenced **only by reflection data tables** (`0xCDDCxx`) — never by any
  `.text` request-builder. And the game never issues a content query in any
  reachable online flow (login / entitlement / matchmaking / menus), even when
  fully online + entitled + every host resolving locally + the server offering a
  `DOWNLOAD_URL`. Linked-but-uninvoked SDK code. This reconciles the panel's one
  divergence: the schema is real (vs "it's just the Massive ad SDK"), but no
  reachable code path exercises it.
- **`patch.ea.com`** is not a string in the binary; it's a runtime DNS prefetch
  by an EA-SDK/DRM component that never connects (and bypasses the mod's
  `gethostbyname` hook).

## Caveat on the live debugger

In this x32dbg + MCP setup, **do not resume/run the process** — it breaks the
bridge. Inspection here was strictly read-only on a paused target (memory reads,
string detection, reference search of the unpacked image).
