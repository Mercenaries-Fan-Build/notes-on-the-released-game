"""Catch-all DNS server.

Answers EVERY A query with the Modkit IP (and NODATA for AAAA so clients fall
back to IPv4), so all of the game's hostname lookups — fesl.ea.com,
messaging.ea.com, locate.madserver.net, or anything else — resolve to us. Point
the game machine's DNS at this host (or run on the same box and set DNS to
127.0.0.1). Works regardless of how the game resolves names (static ws2_32,
dynamic GetProcAddress, or the SecuROM-unpacked path), because every resolver
ultimately asks the OS, which asks this server.

Every query is also captured (protocol="dns"), so you can SEE exactly what the
game asks for even if the follow-up connection lands on a port we don't yet parse.
"""
from __future__ import annotations

import asyncio
import socket
import struct

from config import config
from sink import sink

TYPE_A = 1
TYPE_AAAA = 28
_QTYPE_NAMES = {1: "A", 2: "NS", 5: "CNAME", 12: "PTR", 15: "MX", 16: "TXT",
                28: "AAAA", 33: "SRV", 255: "ANY"}


def _parse_question(data: bytes) -> tuple[str, int, int]:
    """Return (qname, qtype, qend_offset). Raises on malformed input."""
    pos = 12  # skip header
    labels = []
    while True:
        if pos >= len(data):
            raise ValueError("truncated qname")
        length = data[pos]
        pos += 1
        if length == 0:
            break
        if length & 0xC0:  # compression pointer in a question — unexpected
            raise ValueError("compressed qname in question")
        labels.append(data[pos:pos + length].decode("latin-1", "replace"))
        pos += length
    qtype, _qclass = struct.unpack(">HH", data[pos:pos + 4])
    pos += 4
    return ".".join(labels), qtype, pos


def _build_response(query: bytes, qend: int, qtype: int, ip: str) -> bytes:
    txn_id = query[:2]
    # flags: response, recursion desired (echo) + recursion available
    flags = b"\x81\x80"
    question = query[12:qend]
    answer = b""
    ancount = 0
    if qtype in (TYPE_A, 255):
        answer = (
            b"\xc0\x0c"                       # name -> pointer to qname at 0x0c
            + struct.pack(">HHI", TYPE_A, 1, 60)  # type A, class IN, TTL 60
            + struct.pack(">H", 4)            # RDLENGTH
            + socket.inet_aton(ip)            # RDATA
        )
        ancount = 1
    header = txn_id + flags + struct.pack(">HHHH", 1, ancount, 0, 0)
    return header + question + answer


class DNSProtocol(asyncio.DatagramProtocol):
    def __init__(self, port: int, resolve_ip: str) -> None:
        self.port = port
        self.resolve_ip = resolve_ip
        self.transport: asyncio.DatagramTransport | None = None

    def connection_made(self, transport) -> None:
        self.transport = transport

    def datagram_received(self, data: bytes, addr) -> None:
        peer = f"{addr[0]}:{addr[1]}"
        try:
            qname, qtype, qend = _parse_question(data)
        except Exception:  # noqa: BLE001 — log raw and move on
            asyncio.create_task(sink.emit({
                "protocol": "dns", "direction": "inbound", "peer_addr": peer,
                "server_port": self.port, "body_hex": data.hex(),
                "body_len": len(data), "notes": "dns-unparsed",
            }))
            return

        resp = _build_response(data, qend, qtype, self.resolve_ip)
        if self.transport:
            self.transport.sendto(resp, addr)

        qt = _QTYPE_NAMES.get(qtype, str(qtype))
        answered = self.resolve_ip if qtype in (TYPE_A, 255) else "(NODATA)"
        asyncio.create_task(sink.emit({
            "protocol": "dns",
            "direction": "inbound",
            "peer_addr": peer,
            "server_port": self.port,
            "host": qname,
            "method": qt,                       # reuse method col for query type
            "params": {"qname": qname, "qtype": qt, "answer": answered},
            "body_len": len(data),
            "response_summary": f"{qt} {qname} -> {answered}",
            "notes": "dns-query",
        }))
