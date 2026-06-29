"""FESL / Theater connection handler.

Reads framed messages off the connection, captures each (type, id, TXN, full
key=value map + raw payload hex), then sends a best-effort stub reply from
responders.fesl_templates so the handshake advances and the next request shows
up. Unhandled transactions are still captured (notes="unhandled").
"""
from __future__ import annotations

import random

from fesl import encode_frame, read_frame
from protocol_detect import BufferedConn
from responders.fesl_templates import respond
from sink import sink

# FESL packet-type lives in the top byte of the 4-byte id field:
#   0xC0xxxxxx = request (client -> server, wants a response)
#   0x80xxxxxx = response (server -> client, reply to that request)
# A response must reuse the request's low-24-bit id but flip the type to 0x80,
# or the client won't match it to its pending request and drops the connection.
FESL_RESPONSE_TYPE = 0x80000000   # server -> client reply to a client request
FESL_REQUEST_TYPE = 0xC0000000    # request (either direction); has the 0x40 flag
FESL_REQUEST_FLAG = 0x40000000    # set on requests, clear on responses
FESL_ID_MASK = 0x00FFFFFF


def _response_id(request_id: int) -> int:
    return (request_id & FESL_ID_MASK) | FESL_RESPONSE_TYPE


async def handle_fesl(conn: BufferedConn, peer: str, port: int, kind: str = "fesl") -> None:
    writer = getattr(conn, "writer", None)
    server_pkt_id = 0  # counter for server-initiated requests (MemCheck, ...)
    while True:
        frame = await read_frame(conn)
        if frame is None:
            return
        type4, msg_id, kv, raw_payload = frame

        # Only auto-reply to client *requests* (0xC0). A frame with the request
        # flag clear (0x80) is the client *responding* to one of our server-
        # initiated requests (e.g. its MemCheck result) — capture it, don't reply,
        # or we'd ping-pong forever.
        is_request = bool(msg_id & FESL_REQUEST_FLAG)
        reply_fields, note = respond(type4, kv) if is_request else (None, "client-response")

        resp_summary = None
        if reply_fields is not None and writer is not None:
            reply = encode_frame(type4, _response_id(msg_id), reply_fields)
            writer.write(reply)
            await writer.drain()
            resp_summary = f"{type4}/{reply_fields.get('TXN','')} ({len(reply)}B)"

            # FESL handshake: right after the Hello response the server sends an
            # unsolicited MemCheck (anti-cheat) with flags 0x80000000, exactly as
            # loganw234/Mercenaries2 server.py does. memcheck:[] => no regions to
            # hash; the client acks and proceeds to acct login. Without it the
            # client waits ~5s and Goodbyes.
            if type4 == "fsys" and kv.get("TXN") == "Hello":
                memcheck = encode_frame(
                    "fsys", 0x80000000,
                    {"TXN": "MemCheck", "salt": random.getrandbits(32),
                     "type": 0, "memcheck": []},
                )
                writer.write(memcheck)
                await writer.drain()
                resp_summary += " + MemCheck(push)"

        await sink.emit({
            "protocol": "theater" if (kind == "theater" or type4.isupper()) else "fesl",
            "direction": "inbound",
            "peer_addr": peer,
            "server_port": port,
            "host": None,
            "method": None,
            "path": None,
            "fesl_type": type4,
            "fesl_txn": kv.get("TXN"),
            "fesl_id": msg_id,
            "headers": None,
            "params": kv,
            "body_text": raw_payload.decode("latin-1", "replace") if raw_payload else None,
            "body_hex": raw_payload.hex() if raw_payload else None,
            "body_len": len(raw_payload),
            "response_summary": resp_summary,
            "notes": note,
        })
