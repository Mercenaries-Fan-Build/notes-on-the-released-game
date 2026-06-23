"""FESL / Theater connection handler.

Reads framed messages off the connection, captures each (type, id, TXN, full
key=value map + raw payload hex), then sends a best-effort stub reply from
responders.fesl_templates so the handshake advances and the next request shows
up. Unhandled transactions are still captured (notes="unhandled").
"""
from __future__ import annotations

from fesl import encode_frame, read_frame
from protocol_detect import BufferedConn
from responders.fesl_templates import respond
from sink import sink


async def handle_fesl(conn: BufferedConn, peer: str, port: int, kind: str = "fesl") -> None:
    writer = getattr(conn, "writer", None)
    while True:
        frame = await read_frame(conn)
        if frame is None:
            return
        type4, msg_id, kv, raw_payload = frame

        reply_fields, note = respond(type4, kv)

        resp_summary = None
        if reply_fields is not None and writer is not None:
            reply = encode_frame(type4, msg_id, reply_fields)
            writer.write(reply)
            await writer.drain()
            resp_summary = f"{type4}/{reply_fields.get('TXN','')} ({len(reply)}B)"

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
