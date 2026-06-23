# coopserver — Modkit network capture / coop-service host

A standalone asyncio service that **emulates the EA online endpoints Mercenaries 2
reaches for and logs every request the game makes** — like httpbin. It is the
first step toward Modkit being a one-stop host for the game's online services.

The game's online code (both the **main menu** in `shell.wad` and **in-game** in
`vz.wad`) tries to talk to dead EA hosts over several protocols:

| Protocol | Where | Port (default) | Handler |
|----------|-------|----------------|---------|
| HTTP     | ad-serving (`madserver.net`) + generic HTTP client | 80 | `http_handler.py` |
| HTTPS    | `messaging.ea.com` etc. | 443 | `http_handler.py` (over TLS) |
| FESL     | `fesl.ea.com` auth (binary frames over TLS) | 18300 | `fesl_handler.py` |
| Theater  | matchmaking 4CC frames | 18840 | `fesl_handler.py` |
| UDP/raw  | peer mesh / UPnP-SSDP | 1900, ... | `raw_handler.py` |

## What it does

1. Listens on the EA ports (the Winsock ASI redirector preserves the destination
   port and only rewrites the IP, so port → protocol is stable).
2. Auto-detects the application protocol per connection (`protocol_detect.py`).
3. **Captures the full request** — method/path/query/headers/body for HTTP;
   type/id/TXN/key=values + raw payload for FESL/Theater.
4. Sends a **best-effort stub reply** so the handshake advances and the *next*
   request appears. Stub templates live in `responders/fesl_templates.py`; any
   transaction with no template is still captured with `notes="unhandled"`.
5. Fans every event to a **JSONL file** (`$COOP_CAPTURE_DIR/capture-*.jsonl`,
   the source of truth) and **POSTs it to the webapp** (`/api/network-captures`)
   so it shows up in the viewer's Network Captures page.

## Run

Via docker-compose (recommended — see repo root `docker-compose.yml`):

```sh
docker compose up coopserver
```

Standalone:

```sh
pip install -r requirements.txt
COOP_CAPTURE_DIR=./captures MODKIT_API_URL=http://localhost:8000 \
COOP_CERT_FILE=./certs/server.crt COOP_KEY_FILE=./certs/server.key \
  ./entrypoint.sh
```

## Configuration (env vars)

| Var | Default | Meaning |
|-----|---------|---------|
| `MODKIT_API_URL` | `http://api:8000` | webapp base URL for ingest (empty disables) |
| `COOP_CAPTURE_DIR` | `/data/captures` | JSONL output dir |
| `COOP_BIND_HOST` | `0.0.0.0` | bind address |
| `COOP_TLS_PORTS` | `443 18300` | TLS listener ports |
| `COOP_PLAIN_PORTS` | `80 18840` | plaintext listener ports |
| `COOP_UDP_PORTS` | `1900` | UDP logger ports |
| `COOP_ADVERTISE_HOST` | `127.0.0.1` | IP we hand back as theater/messaging host |
| `COOP_THEATER_PORT` | `18840` | port we advertise for theater |

## Test

```sh
# HTTP capture
curl -X POST 'http://localhost:80/adsrv/4/openSession?game=mercs2' -d 'a=1&b=2'

# FESL capture + handshake advance
python tests/fesl_client.py 127.0.0.1 18300
```

Then browse `GET http://localhost:8000/api/network-captures` or the viewer's
**Network Captures** page, or `tail -f captures/capture-*.jsonl`.
