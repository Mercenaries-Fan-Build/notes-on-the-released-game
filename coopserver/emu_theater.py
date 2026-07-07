"""Theater transaction logic — lobby lifecycle + host/joiner routing.

Python-3 port of the hardened community server's Theater half. Theater messages
use uppercase 4CC tags (CONN/USER/LLST/GDAT/CGAM/EGAM/EGRS/ECNL/RGAM/UGAM/...).

Returns `(replies, side_sends)`:
  * replies    — frames to send back on THIS connection, `(type4, id, fields)`
  * side_sends — `(writer, (type4, id, fields))` frames routed to the OTHER
                 peer's Theater connection (EGRQ to host, EGEG to joiner).

Theater reply framing: the id field is 0 (matches the reference).
`ctx` = {'session': Session|None, 'peer_ip': str, 'writer': StreamWriter}.
"""
from __future__ import annotations

import threading
import time

from config import config
from emu_fesl import game_matches
from emu_state import (
    STATE, EnterGameRequest, Game, _int, allocate_relay_ports,
)
from relay import threaded_udp_relay

Frame = tuple[str, int, dict]


def _reply(type4: str, tid, extra: dict | None = None) -> Frame:
    fields = {"TID": tid or ""}
    if extra:
        fields.update(extra)
    return (type4, 0, fields)


def _pick_available_game(exclude_user=None, filters=None):
    """A joinable lobby for a Play Now (GID=0) request, newest first, or None."""
    candidates = []
    for g in list(STATE.games.values()):
        if not g.host:
            continue
        if exclude_user is not None and g.host is exclude_user:
            continue
        if filters and not game_matches(g, filters):
            continue
        cap = _int(g.slots, 0)
        if cap and len(g.players) >= cap:
            continue
        candidates.append(g)
    if not candidates:
        return None
    candidates.sort(key=lambda g: g.id, reverse=True)
    return candidates[0]


def drop_user_from_lobby(user):
    """Remove `user` when their Theater connection drops. Host loss tears the
    whole lobby down (co-op is host-authoritative); a joiner just frees a slot.
    Returns a short log string or None."""
    with STATE.lock:
        game = None
        for g in list(STATE.games.values()):
            if g.host is user or user in g.players:
                game = g
                break
        if game is None:
            return None
        if game.host is user:
            STATE.games.pop(game.id, None)
            dropped = len(game.players)
            if dropped:
                return f"host {user.name} left -> lobby {game.id} closed ({dropped} joiner(s) dropped)"
            return f"host {user.name} left -> lobby {game.id} closed"
        while user in game.players:
            game.players.remove(user)
        return f"{user.name} left lobby {game.id} ({len(game.players)} still in)"


def _create_game(ctx, kv):
    sess = ctx["session"]
    g = Game()
    g.id = STATE.generate_game_id()
    g.host = sess.user if sess else None
    g.ipEx = (ctx["peer_ip"], kv.get("PORT"))
    g.ipIn = (kv.get("INT-IP"), kv.get("INT-PORT"))
    g.slots = kv.get("MAX-PLAYERS")
    g.info = {k: v for k, v in kv.items() if k.startswith("B-")}
    STATE.games[g.id] = g
    if g.host:
        g.host.stats["games_hosted"] += 1
        STATE.save_database()
    g.relay_ports = allocate_relay_ports()
    if g.relay_ports[0] and g.relay_ports[1]:
        g.relay_expected_ips = {"host": g.ipEx[0], "joiner": None}
        threading.Thread(target=threaded_udp_relay,
                         args=(g.relay_ports[0], g.relay_ports[1], g.id, g.relay_expected_ips),
                         daemon=True).start()
    else:
        print(f"[emu] relay pool exhausted — lobby {g.id} created without relay")
    return [_reply("CGAM", kv.get("TID"), {
        "EKEY": g.ekey, "GID": g.id, "J": 0, "JOIN": 0, "LID": g.lid,
        "MAX-PLAYERS": g.slots, "SECRET": g.secret, "UGID": g.uid})], []


def _enter_game(ctx, kv):
    joiner = ctx["session"]
    game = STATE.game_by_gid(kv.get("GID")) if "GID" in kv else STATE.find_game(kv.get("USER"))
    if not game or game.host is None:
        return [_reply("EGAM", kv.get("TID"), {})], []
    rq = EnterGameRequest()
    rq.user = joiner.user if joiner else None
    if rq.user is None:
        return [_reply("EGAM", kv.get("TID"), {})], []
    cap = _int(game.slots, 0)
    if cap and rq.user not in game.players and len(game.players) >= cap:
        return [_reply("EGAM", kv.get("TID"), {})], []   # full
    rq.pid = min(len(game.players) + 1, 2)
    rq.ipIn = (kv.get("R-INT-IP"), _int(kv.get("R-INT-PORT", 0)))
    rq.ipEx = (ctx["peer_ip"], kv.get("PORT"))
    game.requests[rq.pid] = rq
    if game.relay_expected_ips is not None:
        game.relay_expected_ips["joiner"] = rq.ipEx[0]

    reply = _reply("EGAM", kv.get("TID"), {"GID": game.id, "LID": game.lid})
    host_port = game.relay_ports[0] if game.relay_ports[0] else rq.ipEx[1]
    rdict = {"PTYPE": "P", "GID": game.id, "IP": config.advertise_host, "PORT": host_port,
             "LID": game.lid, "NAME": rq.user.name, "UID": rq.user.id, "PID": rq.pid,
             "R-INT-IP": rq.ipIn[0], "R-INT-PORT": rq.ipIn[1], "TICKET": rq.id}
    if game.host is not rq.user:
        rdict.update({"R-USER": game.host.name, "R-U-USERID": game.host.id})
    side = []
    host_sess = game.host.session if game.host else None
    if host_sess and host_sess.theater_writer:
        side.append((host_sess.theater_writer, ("EGRQ", 0, rdict)))   # ask host to accept relay routing
    return [reply], side


def _enter_game_response(ctx, kv):
    reply = _reply("EGRS", kv.get("TID"), {})
    game = STATE.game_by_gid(kv.get("GID"))
    if not game or game.host is None:
        return [reply], []
    pid = _int(kv.get("PID", 0))
    rq = game.requests.get(pid)
    if not rq or rq.user is None:
        return [reply], []
    if rq.user not in game.players:
        game.players.append(rq.user)
    rq.user.stats["games_joined"] += 1
    STATE.save_database()
    joiner_port = game.relay_ports[1] if game.relay_ports[1] else game.ipEx[1]
    side = []
    joiner_sess = rq.user.session if rq.user else None
    if joiner_sess and joiner_sess.theater_writer:
        side.append((joiner_sess.theater_writer, ("EGEG", 0, {
            "LID": game.lid, "GID": game.id, "UGID": game.uid, "HUID": game.host.id,
            "I": config.advertise_host, "P": joiner_port, "INT-IP": game.ipIn[0],
            "INT-PORT": game.ipIn[1], "PL": "pc", "PID": pid, "EKEY": game.ekey,
            "TICKET": rq.id})))   # clear joiner to connect to the relay
    return [reply], side


def handle_theater(ctx, type4: str, kv: dict) -> tuple[list[Frame], list]:
    mid = type4
    tid = kv.get("TID")
    reply = _reply(mid, tid)
    out: list[Frame] = [reply]
    side: list = []

    if mid == "CONN":
        reply[2].update({"TIME": int(time.time()), "activityTimeoutSecs": 86400, "PROT": 2})
    elif mid == "USER":
        sess = STATE.get_session(kv.get("LKEY", ""))
        if sess:
            sess.theater_writer = ctx["writer"]
            ctx["session"] = sess
            reply[2]["NAME"] = sess.user.name if sess.user else ""
            if sess.user and ctx["peer_ip"]:
                sess.user.known_ips.add(ctx["peer_ip"])
                STATE.save_database()
        else:
            reply[2]["NAME"] = ""
    elif mid == "LLST":
        reply[2]["NUM-LOBBIES"] = 1
        out.append(("LDAT", 0, {"TID": tid or "", "FAVORITE-GAMES": 0, "FAVORITE-PLAYERS": 0,
            "LID": 257, "LOCALE": "en_US", "MAX-GAMES": 10000, "NAME": "mercs2PC01",
            "NUM-GAMES": len(STATE.games), "PASSING": len(STATE.games)}))
    elif mid == "GDAT":
        game = None
        gid_val = _int(kv.get("GID", 0))
        if gid_val > 0:
            game = STATE.games.get(gid_val)
        elif "USER" in kv:
            game = STATE.find_game(kv["USER"])
        if game is None and "USER" not in kv:
            sess = ctx["session"]
            game = _pick_available_game(sess.user if sess else None,
                                        sess.pnow_filters if sess else None)
        if game and game.host:
            reply[2].update({
                "LID": game.lid, "GID": game.id, "TYPE": "G", "N": "hostname",
                "I": game.ipEx[0], "P": game.ipEx[1], "PL": "PC", "V": "1.0",
                "HN": game.host.name, "HU": game.host.id, "J": "O", "JP": 0,
                "AP": len(game.players), "MP": game.slots, "PW": 0, "QP": 0,
                "INT-IP": game.ipIn[0], "INT-PORT": game.ipIn[1]})
            reply[2].update(game.info)
            out.append(("GDET", 0, {"TID": tid or "", "LID": game.lid, "GID": game.id, "UGID": game.uid}))
            out.append(("PDAT", 0, {"TID": tid or "", "GID": game.id, "LID": game.lid,
                                    "NAME": game.host.name, "UID": game.host.id, "PID": 1}))
        else:
            out = [reply]   # not-found reply (bare GDAT) so the client stops waiting
    elif mid == "CGAM":
        out, side = _create_game(ctx, kv)
    elif mid == "EGAM":
        out, side = _enter_game(ctx, kv)
    elif mid == "EGRS":
        out, side = _enter_game_response(ctx, kv)
    elif mid == "ECNL":
        reply[2].update({"GID": kv.get("GID"), "LID": kv.get("LID")})
        g = STATE.game_by_gid(kv.get("GID"))
        if g:
            sess = ctx["session"]
            u = sess.user if sess else None
            with STATE.lock:
                if u is not None and u in g.players:
                    g.players.remove(u)
    elif mid == "RGAM":
        gid = _int(kv.get("GID"), -1)
        with STATE.lock:
            STATE.games.pop(gid, None)
    elif mid == "PENT":
        reply[2]["PID"] = kv.get("PID")
    elif mid == "PLVT":
        out = []
    elif mid == "UBRA":
        pass
    elif mid == "UGAM":
        g = STATE.game_by_gid(kv.get("GID"))
        if g:
            for k, v in kv.items():
                if k.startswith("B-"):
                    g.info[k] = v
        out = []

    return out, side
