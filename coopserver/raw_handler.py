"""Fallback loggers for protocols we don't (yet) parse: raw TCP streams and UDP
datagrams (peer mesh, UPnP/SSDP, anything unexpected). We just hexdump and log."""
from __future__ import annotations

import asyncio

from protocol_detect import BufferedConn
from sink import sink


async def handle_raw(conn: BufferedConn, peer: str, port: int, note: str = "raw") -> None:
    chunks = bytearray()
    # Drain up to a sane cap so a chatty peer can't grow memory unbounded.
    while len(chunks) < (1 << 16):
        try:
            data = await asyncio.wait_for(conn.read(4096), timeout=2.0)
        except asyncio.TimeoutError:
            break
        if not data:
            break
        chunks += data
    body = bytes(chunks)
    await sink.emit({
        "protocol": "tcp",
        "direction": "inbound",
        "peer_addr": peer,
        "server_port": port,
        "body_text": body.decode("latin-1", "replace") if body else None,
        "body_hex": body.hex() if body else None,
        "body_len": len(body),
        "notes": note,
    })


class UDPLogger(asyncio.DatagramProtocol):
    def __init__(self, port: int) -> None:
        self.port = port

    def datagram_received(self, data: bytes, addr) -> None:
        peer = f"{addr[0]}:{addr[1]}"
        asyncio.create_task(sink.emit({
            "protocol": "udp",
            "direction": "inbound",
            "peer_addr": peer,
            "server_port": self.port,
            "body_text": data.decode("latin-1", "replace") if data else None,
            "body_hex": data.hex() if data else None,
            "body_len": len(data),
            "notes": "udp-datagram",
        }))
