"""Configuration for the Modkit coop / network-capture server.

All settings come from environment variables (with sensible defaults) so the
service can be driven entirely from docker-compose. Ports are split into:

* TLS ports   — wrapped in our self-signed cert, then app-protocol auto-detected
                (FESL-over-TLS and HTTPS both live here).
* Plain ports — plaintext, app-protocol auto-detected (HTTP, Theater, raw).
* UDP ports   — fire-and-forget datagram loggers (peer mesh / UPnP / SSDP).

Each listener also carries a ``prefer`` hint used only to break ambiguous
protocol classification (e.g. port 80 -> http, the FESL port -> fesl).
"""
from __future__ import annotations

import os
from dataclasses import dataclass, field


def _ports(env: str, default: str) -> list[int]:
    raw = os.environ.get(env, default).strip()
    if not raw:
        return []
    return [int(p) for p in raw.replace(",", " ").split()]


@dataclass
class Config:
    # Where captured events are POSTed (the FastAPI webapp). Empty disables it.
    api_url: str = os.environ.get("MODKIT_API_URL", "http://api:8000")
    # Directory for the raw JSONL dump (source of truth, mounted volume).
    capture_dir: str = os.environ.get("COOP_CAPTURE_DIR", "/data/captures")

    bind_host: str = os.environ.get("COOP_BIND_HOST", "0.0.0.0")

    # Port groups. Defaults mirror the Mercenaries 2 online stack:
    #   80    ad-serving HTTP (madserver.net) + generic HTTP client
    #   28710 FESL auth — PLAINTEXT, fed by tlsterm (which terminates the game's
    #         SSLv3/RC4 or the shim's modern TLS on :18710 and forwards here)
    #   18715 Theater (matchmaking) — plaintext 4CC framing
    #   443   generic HTTPS (messaging.ea.com etc.) — self-signed
    tls_ports: list[int] = field(default_factory=lambda: _ports("COOP_TLS_PORTS", "443"))
    plain_ports: list[int] = field(default_factory=lambda: _ports("COOP_PLAIN_PORTS", "80 28710 18715"))
    udp_ports: list[int] = field(default_factory=lambda: _ports("COOP_UDP_PORTS", "1900"))
    # GameSpy availability responder (UDP): answers the master-server reachability
    # probe with the fixed magic. 0 disables.
    gamespy_port: int = int(os.environ.get("COOP_GAMESPY_PORT", "27900"))

    cert_file: str = os.environ.get("COOP_CERT_FILE", "/app/certs/server.crt")
    key_file: str = os.environ.get("COOP_KEY_FILE", "/app/certs/server.key")

    # Persistent account/profile DB (personas, known IPs, stats). Empty disables.
    profile_db: str = os.environ.get("COOP_PROFILE_DB", "profiles.json")

    # Address we advertise back to the game as the theater/messaging host so it
    # keeps talking to us. Set this to the Modkit machine's reachable IP.
    advertise_host: str = os.environ.get("COOP_ADVERTISE_HOST", "127.0.0.1")
    theater_port: int = int(os.environ.get("COOP_THEATER_PORT", "18715"))

    # Catch-all DNS server: answers every A query with dns_resolve_ip. Point the
    # game machine's DNS here to force ALL the game's name lookups to Modkit.
    # 0 disables the DNS server.
    dns_port: int = int(os.environ.get("COOP_DNS_PORT", "53"))
    dns_resolve_ip: str = os.environ.get("COOP_DNS_RESOLVE_IP", "") \
        or os.environ.get("COOP_ADVERTISE_HOST", "127.0.0.1")

    # Protocol hint per port (host -> "http"/"fesl"). Anything not listed and
    # not on the FESL port defaults to http on plain ports / http on 443.
    def prefer_for(self, port: int) -> str:
        if port in (18300, self.theater_port) or port >= 18000:
            return "fesl"
        return "http"


config = Config()
