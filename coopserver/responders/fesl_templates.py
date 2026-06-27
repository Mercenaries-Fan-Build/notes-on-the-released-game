"""Best-effort FESL / Theater stub responses.

The first build is capture-first: these responses exist only to *advance* the
handshake far enough that the game reveals its next request (persona list,
entitlement query, theater connect, ...). They are intentionally minimal and
easy to tune as real captures tell us what the client actually wants. Any
transaction with no template here is logged with notes="unhandled" so the gap
is obvious in the viewer.

A responder is keyed by (type, TXN) and receives the parsed key=value map of the
request; it returns the field dict for the reply (or None to stay silent).
"""
from __future__ import annotations

from typing import Callable, Optional

from config import config

# (type, txn) -> builder(request_fields) -> reply_fields | None
Responder = Callable[[dict[str, str]], Optional[dict[str, str]]]


def _hello(req: dict[str, str]) -> dict[str, str]:
    return {
        "TXN": "Hello",
        "domainPartition.domain": "eagames",
        "domainPartition.subDomain": "MERCS2PC",
        "curTime": "Jun-21-2026 00:00:00 UTC",
        "activityTimeoutSecs": "240",
        "messengerIp": config.advertise_host,
        "messengerPort": "0",
        "theaterIp": config.advertise_host,
        "theaterPort": str(config.theater_port),
    }


def _memcheck(req: dict[str, str]) -> dict[str, str]:
    # Anti-cheat memory check — reply that nothing needs checking.
    return {"TXN": "MemCheck", "result": ""}


def _nu_login(req: dict[str, str]) -> dict[str, str]:
    return {
        "TXN": "NuLogin",
        "nuid": req.get("nuid", "player@modkit.local"),
        "lkey": "MODKIT00-0000-0000-0000-000000000000",
        "profileId": "1000",
        "userId": "1000",
    }


def _nu_get_personas(req: dict[str, str]) -> dict[str, str]:
    return {"TXN": "NuGetPersonas", "personas.0": "ModkitPlayer", "personas.[]": "1"}


def _nu_login_persona(req: dict[str, str]) -> dict[str, str]:
    return {
        "TXN": "NuLoginPersona",
        "lkey": "MODKIT00-0000-0000-0000-000000000000",
        "profileId": "1000",
        "userId": "1000",
    }


def _entitled(req: dict[str, str]) -> dict[str, str]:
    # Reply "owned/active" to whatever entitlement/pricing query arrives.
    txn = req.get("TXN", "GetEntitlementByBundle")
    return {
        "TXN": txn,
        "entitlementStatus": "ACTIVE",
        "entitlementStatusDesc": "Active",
        "status": "0",
    }


def _theater_ok(req: dict[str, str]) -> dict[str, str]:
    return {"TXN": req.get("TXN", ""), "result": "0"}


# Explicit (type, txn) handlers.
RESPONDERS: dict[tuple[str, str], Responder] = {
    ("fsys", "Hello"): _hello,
    ("fsys", "MemCheck"): _memcheck,
    ("acct", "NuLogin"): _nu_login,
    ("acct", "Login"): _nu_login,
    ("acct", "NuGetPersonas"): _nu_get_personas,
    ("acct", "NuLoginPersona"): _nu_login_persona,
    ("acct", "GetTelemetryToken"): lambda r: {"TXN": "GetTelemetryToken", "telemetryToken": ""},
}

# Whole-service fallbacks (any TXN of this type) — applied after the exact map.
SERVICE_FALLBACKS: dict[str, Responder] = {
    "subs": _entitled,
    "recp": _entitled,
    "rank": lambda r: {"TXN": r.get("TXN", ""), "result": "0"},
    "thtr": _theater_ok,
}


def respond(type4: str, fields: dict[str, str]) -> tuple[Optional[dict[str, str]], str]:
    """Return (reply_fields, note). reply_fields is None if we have no template."""
    txn = fields.get("TXN", "")
    fn = RESPONDERS.get((type4, txn))
    if fn:
        return fn(fields), "handled"
    fb = SERVICE_FALLBACKS.get(type4)
    if fb:
        return fb(fields), "handled-fallback"
    # Theater 4CC requests (uppercase type) — generic ACK.
    if type4.isupper():
        return {"TXN": txn} if txn else {}, "handled-theater-generic"
    return None, "unhandled"
