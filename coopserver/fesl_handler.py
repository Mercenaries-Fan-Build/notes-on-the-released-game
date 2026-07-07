"""FESL / Theater connection handler (async I/O adapter over the emulator).

Reads framed messages, drives the stateful emulator (emu_fesl / emu_theater),
writes replies (and cross-session EGRQ/EGEG routing), runs the FESL heartbeat,
and captures every message to the inspector sink.

A connection is FESL (lowercase 4CC service tags) or Theater (uppercase 4CC),
decided by `kind` from protocol_detect. FESL owns a Session (created at login);
Theater binds to that Session via the USER message's LKEY.
"""
from __future__ import annotations

import asyncio

from emu_fesl import handle_fesl_txn
from emu_state import STATE, Session
from emu_theater import drop_user_from_lobby, handle_theater
from fesl import encode_frame, read_frame
from protocol_detect import BufferedConn
from sink import sink

FESL_REQUEST_FLAG = 0x40000000   # set on client requests; clear on client responses


def _peer_ip(peer: str) -> str:
    return peer.rsplit(":", 1)[0] if ":" in peer else peer


async def _send(writer, frame) -> int:
    type4, msg_id, fields = frame
    data = encode_frame(type4, msg_id, fields)
    writer.write(data)
    await writer.drain()
    return len(data)


async def _heartbeat(session: Session) -> None:
    """Ping + MemCheck every 120s on the FESL connection (keeps it warm)."""
    import random
    try:
        while True:
            await asyncio.sleep(120)
            w = session.fesl_writer
            if w is None:
                return
            await _send(w, ("fsys", 0, {"TXN": "Ping"}))
            await _send(w, ("fsys", 0x80000000, {"TXN": "MemCheck",
                        "salt": random.getrandbits(32), "type": 0, "memcheck": []}))
    except (asyncio.CancelledError, ConnectionResetError, BrokenPipeError):
        return
    except Exception:  # noqa: BLE001
        return


async def _capture(kind, peer, port, type4, msg_id, kv, raw, note, resp):
    await sink.emit({
        "protocol": "theater" if kind == "theater" else "fesl",
        "direction": "inbound", "peer_addr": peer, "server_port": port,
        "fesl_type": type4, "fesl_txn": kv.get("TXN") or kv.get("TID"),
        "fesl_id": msg_id, "params": kv,
        "body_text": raw.decode("latin-1", "replace") if raw else None,
        "body_hex": raw.hex() if raw else None, "body_len": len(raw) if raw else 0,
        "response_summary": resp, "notes": note,
    })


async def _fesl_loop(conn, peer, port, writer):
    session = Session(client_ip=_peer_ip(peer))
    session.fesl_writer = writer
    try:
        while True:
            frame = await read_frame(conn)
            if frame is None:
                return
            type4, msg_id, kv, raw = frame
            is_request = bool(msg_id & FESL_REQUEST_FLAG)
            if not is_request:
                await _capture("fesl", peer, port, type4, msg_id, kv, raw, "client-response", None)
                continue
            replies = handle_fesl_txn(session, type4, msg_id, kv)
            nbytes = 0
            for fr in replies:
                nbytes += await _send(writer, fr)
            if type4 == "fsys" and kv.get("TXN") == "Hello" and session.heartbeat_task is None:
                session.heartbeat_task = asyncio.create_task(_heartbeat(session))
            resp = f"{len(replies)} reply frame(s), {nbytes}B" if replies else None
            await _capture("fesl", peer, port, type4, msg_id, kv, raw, "handled", resp)
    finally:
        if session.heartbeat_task:
            session.heartbeat_task.cancel()


async def _theater_loop(conn, peer, port, writer):
    ctx = {"session": None, "peer_ip": _peer_ip(peer), "writer": writer}
    try:
        while True:
            frame = await read_frame(conn)
            if frame is None:
                return
            type4, msg_id, kv, raw = frame
            replies, side = handle_theater(ctx, type4, kv)
            nbytes = 0
            for fr in replies:
                nbytes += await _send(writer, fr)
            routed = []
            for other_writer, fr in side:
                try:
                    await _send(other_writer, fr)
                    routed.append(fr[0])
                except Exception:  # noqa: BLE001 — peer socket may be gone
                    pass
            resp = f"{len(replies)} reply(s), {nbytes}B" + (f" +routed {routed}" if routed else "")
            await _capture("theater", peer, port, type4, msg_id, kv, raw, "handled", resp or None)
    finally:
        sess = ctx["session"]
        if sess and sess.user:
            note = drop_user_from_lobby(sess.user)
            if note:
                print(f"[emu] cleanup: {note}")


async def handle_fesl(conn: BufferedConn, peer: str, port: int, kind: str = "fesl") -> None:
    writer = getattr(conn, "writer", None)
    if writer is None:
        return
    if kind == "theater":
        await _theater_loop(conn, peer, port, writer)
    else:
        await _fesl_loop(conn, peer, port, writer)
