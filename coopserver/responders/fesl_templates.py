"""FESL / Theater stub responses, ported from loganw234/Mercenaries2 server.py
(the proven Mercenaries 2 FESL emulator) so the game completes login and reports
itself online. Responses use nested dict/list values; fesl.build_payload flattens
them into FESL dotted keys.

A responder is keyed by (type, TXN), receives the parsed request key=value map,
and returns the reply field dict (or None to stay silent).
"""
from __future__ import annotations

import base64
import os
from typing import Callable, Optional

from config import config

Responder = Callable[[dict], Optional[dict]]

# curTime is sent quoted, inside the game's spoofed-clock era (2008-2024 cert window).
CUR_TIME = '"Jan-01-2012 12:00:00 UTC"'
MESSENGER_PORT = 13505  # advertised only


def _gen_lkey() -> str:
    return base64.urlsafe_b64encode(os.urandom(20)).rstrip(b"=").decode("ascii") + "."


def _entitlement_block() -> list:
    return [{"gameFeatureId": 6014, "status": 0, "message": "",
             "entitlementExpirationDate": "", "entitlementExpirationDays": -1}]


# ---- fsys ----------------------------------------------------------------

def _hello(req: dict) -> dict:
    return {
        "TXN": "Hello",
        "activityTimeoutSecs": 0,
        "curTime": CUR_TIME,
        "messengerIp": config.advertise_host,
        "messengerPort": MESSENGER_PORT,
        "theaterIp": config.advertise_host,
        "theaterPort": config.theater_port,
        "domainPartition.domain": "eagames",
        "domainPartition.subDomain": "MERCS2",
    }


def _get_ping_sites(req: dict) -> dict:
    ip = config.advertise_host
    return {
        "TXN": "GetPingSites",
        "minPingSitesToPing": 0,
        "pingSite": [
            {"addr": ip, "name": "eu-ip", "type": 0},
            {"addr": ip, "name": "ec-ip", "type": 0},
            {"addr": ip, "name": "wc-ip", "type": 0},
        ],
    }


# ---- acct ----------------------------------------------------------------

def _login(req: dict) -> dict:
    # Accept any credentials. NuLogin keys the name on nuid; Login on name.
    name = req.get("nuid") or req.get("name") or "Player@ea.com"
    return {
        "TXN": req.get("TXN", "NuLogin"),
        "displayName": name,
        "userId": 1000,
        "profileId": 1000,
        "lkey": _gen_lkey(),
        "entitledGameFeatureWrappers": _entitlement_block(),
    }


def _get_personas(req: dict) -> dict:
    return {"TXN": "NuGetPersonas", "personas": []}


def _login_persona(req: dict) -> dict:
    return {"TXN": "NuLoginPersona", "lkey": _gen_lkey(), "profileId": 1000, "userId": 1000}


def _telemetry_token(req: dict) -> dict:
    return {"TXN": "GetTelemetryToken", "enabled": "CA,MX,PR,US,VI",
            "disabled": "", "filters": "", "telemetryToken": ""}


# ---- subs ----------------------------------------------------------------

def _entitlement_by_bundle(req: dict) -> dict:
    return {
        "TXN": "GetEntitlementByBundle",
        "pricingOptionId": "REG-PC-MERCENARIES2-UNLOCK-1",
        "name": '"Mercenaries 2 UNLOCK 1 PC"',
        "description": '"Mercenaries 2 UNLOCK 1 PC"',
        "type": 1,
        "entitlementStatus": 0,
        "entitlementStatusDesc": "ACTIVE",
        "entitlementSuspendDate": "",
    }


RESPONDERS: dict[tuple[str, str], Responder] = {
    ("fsys", "Hello"): _hello,
    ("fsys", "GetPingSites"): _get_ping_sites,
    ("acct", "NuLogin"): _login,
    ("acct", "Login"): _login,
    ("acct", "NuGetPersonas"): _get_personas,
    ("acct", "NuLoginPersona"): _login_persona,
    ("acct", "GetTelemetryToken"): _telemetry_token,
    ("subs", "GetEntitlementByBundle"): _entitlement_by_bundle,
}

# TXNs the server should NOT reply to (client responses / fire-and-forget).
SILENT: set[tuple[str, str]] = {
    ("fsys", "MemCheck"), ("fsys", "Goodbye"), ("fsys", "Ping"),
    ("acct", "NuEntitleGame"),
}

# Whole-service fallbacks (any TXN of this type), applied after the exact map.
SERVICE_FALLBACKS: dict[str, Responder] = {
    "subs": _entitlement_by_bundle,
    "recp": lambda r: {"TXN": r.get("TXN", ""), "result": 0},
    "rank": lambda r: {"TXN": r.get("TXN", ""), "result": 0},
}


def respond(type4: str, fields: dict) -> tuple[Optional[dict], str]:
    """Return (reply_fields, note). reply_fields is None for silent/unknown TXNs."""
    txn = fields.get("TXN", "")
    if (type4, txn) in SILENT:
        return None, "silent"
    fn = RESPONDERS.get((type4, txn))
    if fn:
        return fn(fields), "handled"
    fb = SERVICE_FALLBACKS.get(type4)
    if fb:
        return fb(fields), "handled-fallback"
    if type4.isupper():  # Theater 4CC — generic ACK
        return ({"TXN": txn} if txn else {}), "handled-theater-generic"
    return None, "unhandled"
