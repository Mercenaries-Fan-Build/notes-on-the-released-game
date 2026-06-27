"""Per-connection application-protocol detection + a small buffered reader.

The ASI redirector preserves the game's destination *port* and only rewrites the
IP, so a given port maps to a stable protocol. But we still sniff the first bytes
so a misconfigured port can't silently swallow traffic, and so a single TLS port
can carry both FESL-over-TLS and HTTPS.
"""
from __future__ import annotations

import asyncio

HTTP_METHODS = (
    b"GET ", b"POST", b"PUT ", b"HEAD", b"DELE", b"OPTI", b"PATC", b"TRAC",
)


def classify(head: bytes, prefer: str = "http") -> str:
    """Classify the start of a stream as tls / http / fesl / theater / raw."""
    if not head:
        return "empty"
    # TLS record: ContentType=Handshake(0x16), version major 0x03.
    if head[0] == 0x16 and len(head) >= 2 and head[1] == 0x03:
        return "tls"
    # HTTP request line.
    if any(head.startswith(m) for m in HTTP_METHODS) or b" HTTP/" in head[:64]:
        return "http"
    # FESL / Theater: a 4-byte ASCII type tag. Lowercase => FESL service
    # ("fsys"/"acct"/...), uppercase => Theater 4CC ("CONN"/"USER"/...).
    if len(head) >= 4 and all(0x20 <= c < 0x7F for c in head[:4]):
        tag = head[:4]
        if tag.isalpha():
            if tag.islower():
                return "fesl"
            if tag.isupper():
                # HTTP CONNECT vs Theater CONN: HTTP has a space/URL after.
                if tag == b"CONN" and prefer == "http":
                    return "http"
                return "theater"
        # Looks texty but not a clean tag — fall back to the port's preference.
        return prefer
    return "raw"


class BufferedConn:
    """Wraps a prefetched head + an asyncio StreamReader so handlers can do both
    line-oriented (HTTP) and length-prefixed (FESL) reads off one stream."""

    def __init__(self, prebuffer: bytes, reader: asyncio.StreamReader) -> None:
        self._buf = bytearray(prebuffer)
        self._reader = reader
        self.eof = False

    async def _fill(self) -> bool:
        if self.eof:
            return False
        chunk = await self._reader.read(4096)
        if not chunk:
            self.eof = True
            return False
        self._buf += chunk
        return True

    async def readexactly(self, n: int) -> bytes:
        while len(self._buf) < n:
            if not await self._fill():
                data = bytes(self._buf)
                self._buf.clear()
                raise asyncio.IncompleteReadError(data, n)
        data = bytes(self._buf[:n])
        del self._buf[:n]
        return data

    async def readline(self) -> bytes:
        while b"\n" not in self._buf:
            if not await self._fill():
                line = bytes(self._buf)
                self._buf.clear()
                return line
        idx = self._buf.index(b"\n") + 1
        line = bytes(self._buf[:idx])
        del self._buf[:idx]
        return line

    async def read(self, n: int) -> bytes:
        if not self._buf and not self.eof:
            await self._fill()
        data = bytes(self._buf[:n])
        del self._buf[:n]
        return data
