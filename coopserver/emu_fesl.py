"""FESL transaction logic — the stateful auth/session flow.

Python-3 port of the hardened community server's `handle_fesl_message`. Pure
function: given the authenticated `session` and a parsed request, returns the
list of reply frames as `(type4, id_field, fields)` tuples. The async I/O
adapter (fesl_handler.py) encodes + writes them, drives capture, and starts the
heartbeat on Hello.

FESL reply framing (proven): the 4-byte "id" field of a response is
`0x80000000 | (request_id & 0xFF)`; server-initiated pushes carry their own id
(MemCheck 0x80000000, Ping 0). This mirrors the reference exactly.
"""
from __future__ import annotations

import base64
import random

from config import config
from emu_state import (
    STATE, TELEMETRY_RAW, entitlement_block, gen_lkey, to_ea_mapping,
)

MESSENGER_PORT = 13505      # advertised only
CUR_TIME = '"Jan-01-2012 12:00:00 UTC"'   # inside the spoofed-clock cert window

Frame = tuple[str, int, dict]


def _resp_id(req_id: int) -> int:
    return 0x80000000 | (req_id & 0xFF)


def _pnow_filters(data: dict) -> list:
    """Custom-search predicates from a pnow Start: pairs
    players.0.props.{filter-X}=v + {filterToGame-X}=field -> ('B-'+field, v)."""
    fpre = "players.0.props.{filter-"
    mpre = "players.0.props.{filterToGame-"
    filters = []
    for k, v in data.items():
        if k.startswith(fpre) and k.endswith("}"):
            name = k[len(fpre):-1]
            game_field = data.get(mpre + name + "}")
            if game_field:
                filters.append(("B-" + game_field, v))
    return filters


def game_matches(game, filters) -> bool:
    for field, want in filters:
        have = game.info.get(field)
        if have is None or str(have) != str(want):
            return False
    return True


def handle_fesl_txn(session, type4: str, req_id: int, kv: dict) -> list[Frame]:
    txn = kv.get("TXN", "")
    ip = config.advertise_host
    rid = _resp_id(req_id)
    reply: dict = {"TXN": txn}
    out: list[Frame] = [(type4, rid, reply)]

    if type4 == "fsys":
        if txn == "Hello":
            reply.update({
                "activityTimeoutSecs": 0, "curTime": CUR_TIME,
                "messengerIp": ip, "messengerPort": MESSENGER_PORT,
                "theaterIp": ip, "theaterPort": config.theater_port,
                "domainPartition.domain": "eagames", "domainPartition.subDomain": "MERCS2",
            })
            out.append(("fsys", 0x80000000, {
                "TXN": "MemCheck", "salt": random.getrandbits(32),
                "type": 0, "memcheck": []}))
        elif txn in ("MemCheck", "Goodbye", "Ping"):
            out = []
        elif txn == "GetPingSites":
            reply.update({"minPingSitesToPing": 0, "pingSite": [
                {"addr": ip, "name": "eu-ip", "type": 0},
                {"addr": ip, "name": "ec-ip", "type": 0},
                {"addr": ip, "name": "wc-ip", "type": 0}]})

    elif type4 == "acct":
        if txn in ("NuLogin", "Login"):
            name = kv.get("name", "Player") if txn == "Login" else kv.get("nuid", "Player@ea.com")
            session.user = STATE.get_or_create(name)
            session.user.session = session
            session.lkey = gen_lkey()
            STATE.register_session(session.lkey, session)
            session.user.known_ips.add(session.client_ip)
            session.user.stats["logins"] += 1
            STATE.save_database()
            reply.update({"displayName": session.user.name, "userId": session.user.id,
                          "profileId": session.user.id, "lkey": session.lkey,
                          "entitledGameFeatureWrappers": entitlement_block()})
        elif txn == "NuGetPersonas":
            reply["personas"] = list(session.user.personas) if session.user else []
        elif txn == "NuAddPersona":
            if session.user:
                session.user.personas.append(kv.get("name", ""))
                STATE.save_database()
        elif txn == "NuLoginPersona":
            name = kv.get("name", "Player")
            session.user = STATE.get_or_create(name)
            session.user.session = session
            session.lkey = gen_lkey()
            STATE.register_session(session.lkey, session)
            reply.update({"lkey": session.lkey, "profileId": session.user.id,
                          "userId": session.user.id})
        elif txn == "NuEntitleGame":
            out = []
        elif txn == "GetTelemetryToken":
            reply.update({"enabled": "CA,MX,PR,US,VI", "disabled": "", "filters": "",
                          "telemetryToken": base64.b64encode(TELEMETRY_RAW).decode("ascii")})
        elif txn == "GameSpyPreAuth":
            reply["challenge"] = "gnbzlxhv"
            reply["ticket"] = ("CCUBnHUPERml+OVgejfpuXqQS9VmzKBnBalrwEnQ8HBNvxOl/8qpukAzGCJ1HzT"
                               "undOT8w6gFXNtNk4bDJnd0xtgw==")
            out.append(("fsys", 0, {"TXN": "Ping"}))
        elif txn == "LookupUserInfo":
            user = STATE.find_user(kv.get("userInfo.0.userId"))
            if user:
                reply["userInfo"] = [{"userName": user.name, "userId": user.id, "namespace": "MAIN"}]

    elif type4 == "subs":
        if txn == "GetEntitlementByBundle":
            reply.update({"pricingOptionId": "REG-PC-MERCENARIES2-UNLOCK-1",
                "name": '"Mercenaries 2 UNLOCK 1 PC"', "description": '"Mercenaries 2 UNLOCK 1 PC"',
                "type": 1, "entitlementStatus": 0, "entitlementStatusDesc": "ACTIVE",
                "entitlementSuspendDate": ""})

    elif type4 == "pnow":
        if txn == "Start":
            gid = 605
            partition = kv.get("partition.partition", "/eagames/MERCS2")
            reply.update({"id.id": gid, "id.partition": partition})
            filters = _pnow_filters(kv)
            session.pnow_filters = filters
            matching = [g.id for g in list(STATE.games.values()) if game_matches(g, filters)]
            out.append(("pnow", 0x80000000, {
                "TXN": "Status", "id.id": gid, "id.partition": partition,
                "sessionState": "COMPLETE",
                "props": to_ea_mapping({"availableServerCount": len(matching),
                                        "games": matching, "resultType": "LIST"})}))

    elif type4 == "rank":
        if txn == "UpdateStats":
            owner = session.user
            if owner is not None:
                try:
                    num_users = int(kv.get("u.[]", 0))
                    for u_idx in range(num_users):
                        up = f"u.{u_idx}."
                        num_stats = int(kv.get(up + "s.[]", 0))
                        for s_idx in range(num_stats):
                            sp = up + f"s.{s_idx}."
                            key = kv.get(sp + "k")
                            val = kv.get(sp + "v")
                            if key and val is not None:
                                owner.stats[key] = str(val)
                    STATE.save_database()
                except Exception:  # noqa: BLE001
                    pass
        elif txn == "GetRankedStats":
            name = session.user.name if session.user else "Player"
            stats_list = []
            try:
                num_keys = int(kv.get("keys.[]", 0))
                for i in range(num_keys):
                    req_key = kv.get(f"keys.{i}")
                    if req_key:
                        val = session.user.stats.get(req_key, "0.0000") if session.user else "0.0000"
                        stats_list.append({"key": req_key, "rank": 4390, "text": name, "value": val})
            except Exception:  # noqa: BLE001
                pass
            if not stats_list:
                stats_list = [{"key": "vz", "rank": 4390, "text": name, "value": "0.0000"}]
            reply["stats"] = stats_list

    return out
