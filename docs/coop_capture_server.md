# Modkit Coop / Network Capture Server

> **Goal:** make Modkit a one-stop host for Mercenaries 2's (dead) online
> services. **First build = a capture/echo server, like httpbin:** it logs every
> network request the game makes — full params, headers and body — and answers
> just enough to advance the handshake so the *next* request is revealed.
> Coverage spans both the **main menu** (`shell.wad` Lua) and **in-game**
> (`vz.wad`) traffic.
> **Status:** capture-first build. Co-op session emulation is the next build.

---

## How it fits together

```
┌────────────────────┐   1. resolve/connect      ┌──────────────────────────┐
│  Mercenaries2.exe   │ ────────────────────────▶ │ winsock_redirect.asi       │
│  (shell.wad +       │   gethostbyname/connect    │ (IAT hooks in-process)     │
│   vz.wad net code)  │ ◀──────────────────────── │ rewrites EA host/IP →       │
└────────────────────┘   redirected to Modkit IP   │ Modkit, port preserved      │
          │                                         └──────────────┬───────────┘
          │ TCP/TLS/UDP to Modkit (EA ports)                       │ writes
          ▼                                                        ▼
┌────────────────────────────────────────────┐        scripts/winsock_redirect.log
│ coopserver (docker service)                  │
│  :80 HTTP  :443 HTTPS  :18300 FESL/TLS        │   per-connection protocol
│  :18840 Theater  :1900/udp  raw fallback      │   auto-detect + capture + stub
└───────────────┬───────────────────┬──────────┘
                │ JSONL              │ POST /api/network-captures
                ▼                    ▼
   ./output/captures/*.jsonl   webapp (FastAPI+Postgres) ──▶ viewer "Network Captures"
```

Two pieces ship:

1. **`coopserver/`** — a standalone asyncio service (docker-compose service
   `coopserver`) that listens on the EA ports, auto-detects the protocol per
   connection, **captures the full request**, and sends a best-effort stub reply.
   See `coopserver/README.md` for internals and config.
2. **`tools/winsock_redirect_asi/`** — an ASI plugin that redirects the game's
   EA traffic to the Modkit host by hooking the Winsock import table. Catches
   both hostname lookups and hardcoded IPs.

Captures are visible three ways: the live console log (`docker compose logs -f
coopserver`), the JSONL dump (`./output/captures/capture-*.jsonl`), and the
viewer's **Network Captures** page (`/network-captures`).

---

## Quick start

### 1. Run the capture server

```sh
docker compose up -d db api coopserver
```

This starts Postgres, the webapp (which runs `alembic upgrade head`, creating the
`network_captures` table), and the capture server on ports 80/443/18300/18840/1900.

> If port 80/443 is already taken on the Modkit host, remap in `docker-compose.yml`
> (`"8080:80"`) **and** set the matching port in the redirector — but note the
> game expects the real ports, so prefer freeing 80/443 on the host.

### 2. Point the game at Modkit

**Most robust — catch-all DNS** (force ALL the game's name lookups to Modkit,
regardless of how it resolves: static ws2_32, dynamic `GetProcAddress`, or the
SecuROM-unpacked path). coopserver runs a DNS server on `:53/udp` that answers
**every** A query with `COOP_DNS_RESOLVE_IP` and logs each lookup (so you see
exactly what the game requests).

1. Set `COOP_DNS_RESOLVE_IP` in `docker-compose.yml` to the Modkit host IP
   (use `127.0.0.1` if the game runs on the same box as Docker; the LAN IP if
   it's a different machine — and set it the same as `COOP_ADVERTISE_HOST`).
2. On the **game machine**, set the network adapter's DNS server to the Modkit
   host (or `127.0.0.1` if same box), then `ipconfig /flushdns`.
3. Launch the game. Every hostname it looks up now resolves to Modkit and shows
   up as a `dns` capture; the follow-up TCP/TLS connection is auto-detected and
   captured too.

> This is a hosts-file on steroids — it wildcards *all* names, which the hosts
> file can't. It's the recommended path; the ASI below is complementary (it also
> catches connections to *hardcoded IPs*, which DNS can't).

**Complementary — the Winsock redirect ASI** (catches hardcoded IPs too):

```sh
# Build the plugin (needs MinGW: apt install gcc-mingw-w64-i686 / brew install mingw-w64)
make winsock-redirect-asi OUTPUT=./output
```

Copy into the game (alongside the ASI Loader `dinput8.dll` — see
`docs/asi_loader_setup.md`):

```
Mercenaries 2 World in Flames/
├── dinput8.dll                 (Ultimate ASI Loader)
├── scripts/
│   ├── global.ini
│   ├── cruise.asi              (SecuROM spoof)
│   ├── winsock_redirect.asi    (← this plugin)
│   └── winsock_redirect.ini    (← set modkit_ip)
```

Edit `scripts/winsock_redirect.ini`:

```ini
[redirect]
modkit_ip=192.168.1.50    ; the machine running coopserver
redirect_private=0        ; 1 to also redirect LAN/loopback
```

Set `COOP_ADVERTISE_HOST` in `docker-compose.yml` to the same IP so the FESL
stub hands the game a reachable theater/messaging address.

**Fallback — hosts file** (DNS-only; misses hardcoded IPs). On the game machine,
`C:\Windows\System32\drivers\etc\hosts`:

```
192.168.1.50  fesl.ea.com
192.168.1.50  messaging.ea.com
192.168.1.50  locate.madserver.net
```

(The coopserver's self-signed cert already lists these SANs.)

### 3. Watch the traffic

```sh
docker compose logs -f coopserver           # live console feed
tail -f output/captures/capture-*.jsonl     # raw httpbin-style dump
```

…or open the viewer and go to **Network Captures**. Launch the game; requests
appear at the **title screen** (shell.wad: FESL handshake + ad-serving HTTP) and
again **in-game** (vz.wad). Cross-check `scripts/winsock_redirect.log` for the
exact hosts/ports the game hit — this reveals the **real FESL port**, which you
can then pin via `COOP_TLS_PORTS`.

---

## What gets captured

| Protocol | Fields captured | Stub reply |
|----------|-----------------|-----------|
| HTTP/HTTPS | method, path, query params, all headers, body (text+hex), form fields | `200` (ad endpoints get a minimal `<adresponse>`); default JSON ack |
| FESL | type (`fsys`/`acct`/`subs`/…), msg id, `TXN`, every `key=value`, raw payload | template per `(type,TXN)`; `subs`/entitlements → "ACTIVE"; unknowns logged `unhandled` |
| Theater | 4CC type, `TXN`, key=values | generic ACK |
| TCP/UDP | peer, port, raw hexdump | none (log only) |

Stub responses live in `coopserver/responders/fesl_templates.py` — when the log
shows `unhandled` transactions, add a template there and they'll start advancing.

---

## Verify the server without the game

```sh
# HTTP catch-all
curl -X POST 'http://localhost/adsrv/4/openSession?game=mercs2' -d 'a=1&b=2'

# FESL over TLS — sends Hello + an entitlement query + an unknown txn
python coopserver/tests/fesl_client.py 127.0.0.1 18300
```

Then check `GET http://localhost:8000/api/network-captures` or the viewer page.

---

## The FESL connection uses SSLv3 + RC4 (legacy-TLS terminator required)

Confirmed from a live capture of the game's ClientHello on `:18710`:

```
record/client version = 03 00   → SSL 3.0
cipher suites: 0x0005 RC4_128_SHA, 0x0004 RC4_128_MD5
```

Modern OpenSSL (what coopserver's Python links) has **SSLv3, RC4 and MD5-ciphers
all removed**, so coopserver cannot terminate this handshake directly. The
`tlsterm` docker service solves it: stunnel built against **OpenSSL 1.0.2**
(`enable-ssl3 enable-weak-ssl-ciphers`) accepts the SSLv3/RC4 handshake on
`:18710`, decrypts, and forwards **plaintext FESL** to `coopserver:18710` (which
captures it and replies; stunnel re-encrypts the reply). coopserver itself never
speaks SSLv3. Real endpoint observed: `mercs2-pc.fesl.ea.com:18710`.

```
game --SSLv3/RC4--> tlsterm(:18710) --plaintext--> coopserver(:18710) --capture+reply-->
                         ^------------------ re-encrypt -------------------------/
```

`docker compose up -d` builds and runs `tlsterm` automatically. The first build
compiles OpenSSL 1.0.2 + stunnel from source (needs network at build time).

## Hardcoded hosts in the EXE (what the game reaches for)

Confirmed by string + Ghidra analysis of `Mercenaries2.exe`:

| Host | Purpose |
|------|---------|
| `fesl.ea.com` | FESL auth/entitlements (also `fesl-dev`, `fesl-alpha` env variants) |
| `messaging.ea.com` (`@messaging.ea.com`) | EA messaging / IM (XMPP-style JID domain) |
| `locate.madserver.net` | Massive Inc. ad-serving (`/adsrv/4/openSession`) |

Note the real FESL endpoint is **assembled**, not stored whole: the game builds
`<service>.fesl[.<env>].ea.com` → `mercs2-pc.fesl.ea.com:18710` (matching the live
capture above). The standalone `fesl.ea.com` literal sits on a different call path.

> **RESOLVED 2026-07-27 — there is no override config to find.** The
> `FeslHostOverride` / `MessengerHostOverride` / `TheaterHostOverride` (+ port)
> strings are **EA-Plasma config-dump format strings with zero xrefs anywhere in
> the image** — that logging path was compiled out of retail, so the game never
> logs them at startup and **nothing populates them from a config, ini, env var,
> or command line.** `multiplayer.ini` is likewise a dead end: its two xrefs feed
> `FindFirstFileA`/`FindClose` (an existence probe, not a parser). So there is no
> cleaner in-binary redirect than hooking — DNS/Winsock hooking remains correct.
>
> Full endpoint address map, in-place length limits, and the fixed-width-copy
> constraint that blocks a data-only patch:
> [`reverse_engineer/networking_code_map.md`](reverse_engineer/networking_code_map.md) §6.4.

## Winsock is imported BY ORDINAL (important for the ASI)

The game imports `connect` (ws2_32 ordinal **4**) and `gethostbyname` (ordinal
**52**) **by ordinal, not by name**, and uses classic blocking sockets
(no `getaddrinfo`/`WSAConnect`). The redirector therefore hooks the IAT **by
ordinal**. If `winsock_redirect.log` shows `0 IAT slots hooked` (can happen on the
SecuROM-unpacked "cracked" EXE whose import directory may be rebuilt), fall back to
inline-patching the `ws2_32.dll` exports directly, or use the `FeslHostOverride`
config path above.

## Notes & limits (first build)

- **Capture-first:** stub replies only aim to *advance* the handshake so we see
  downstream requests. They do **not** yet emulate a full co-op session.
- **Exact FESL port** is configurable in-game and not certain; the redirector
  preserves the destination port and coopserver auto-detects protocol, so it
  works regardless — and the ASI log tells you the real port to pin.
- **TLS:** the game's ancient OpenSSL (0.9.8d) is expected to accept the
  self-signed cert. If it rejects it, set `redirect_private`/port options to send
  that port to a plaintext listener instead, or capture pre-TLS via the ASI log.

## Related

- `coopserver/README.md` — service internals & env vars
- `docs/teknogods_coop_research.md` — network architecture, FESL packet format
- `docs/ui/online_bonus_checking.md` — FESL services/TXNs, theater 4CCs
- `docs/asi_loader_setup.md` — ASI Loader infrastructure
