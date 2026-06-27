"""Catch-all HTTP handler — the httpbin part.

Accepts ANY method on ANY path, captures the full request (method, path, parsed
query, all headers, raw + parsed body), then returns a benign response so the
game's HTTP client / ad SDK keeps going. Known ad-serving endpoints get a
slightly more specific stub.
"""
from __future__ import annotations

import json
from urllib.parse import parse_qs, urlsplit

from protocol_detect import BufferedConn
from sink import sink


def _flatten_qs(qs: dict[str, list[str]]) -> dict[str, str]:
    return {k: v[0] if len(v) == 1 else v for k, v in qs.items()}


def _stub_for(path: str) -> tuple[int, str, bytes]:
    """(status_code, content_type, body) for a given path."""
    p = path.lower()
    if "/adsrv/" in p and "opensession" in p:
        # Massive Inc. ad SDK — minimal "session opened" XML.
        return 200, "text/xml", b'<?xml version="1.0"?><adresponse status="ok"/>'
    if "/adsrv/" in p and "closesession" in p:
        return 200, "text/xml", b'<?xml version="1.0"?><adresponse status="ok"/>'
    # Default httpbin-style: echo a small JSON ack.
    return 200, "application/json", b'{"modkit":"ok"}'


async def handle_http(conn: BufferedConn, peer: str, port: int) -> None:
    while True:
        request_line = (await conn.readline()).decode("latin-1", "replace").strip()
        if not request_line:
            return  # EOF / empty
        parts = request_line.split(" ")
        method = parts[0] if parts else ""
        target = parts[1] if len(parts) > 1 else "/"

        # Headers
        headers: dict[str, str] = {}
        while True:
            line = (await conn.readline()).decode("latin-1", "replace")
            if line in ("\r\n", "\n", ""):
                break
            if ":" in line:
                k, v = line.split(":", 1)
                headers[k.strip()] = v.strip()

        # Body
        body = b""
        clen = headers.get("Content-Length") or headers.get("content-length")
        if clen and clen.isdigit():
            body = await _read_body(conn, int(clen))

        split = urlsplit(target)
        params = _flatten_qs(parse_qs(split.query, keep_blank_values=True))
        # Merge urlencoded form bodies into params too.
        ctype = headers.get("Content-Type", headers.get("content-type", "")).lower()
        if body and "application/x-www-form-urlencoded" in ctype:
            params.update(_flatten_qs(parse_qs(body.decode("latin-1", "replace"), keep_blank_values=True)))

        status, resp_ctype, resp_body = _stub_for(split.path)

        await sink.emit({
            "protocol": "http" if port != 443 else "https",
            "direction": "inbound",
            "peer_addr": peer,
            "server_port": port,
            "host": headers.get("Host") or headers.get("host"),
            "method": method,
            "path": split.path + (("?" + split.query) if split.query else ""),
            "headers": headers,
            "params": params,
            "body_text": body.decode("latin-1", "replace") if body else None,
            "body_hex": body.hex() if body else None,
            "body_len": len(body),
            "response_summary": f"{status} {resp_ctype} ({len(resp_body)}B)",
            "notes": None,
        })

        out = (
            f"HTTP/1.1 {status} OK\r\n"
            f"Content-Type: {resp_ctype}\r\n"
            f"Content-Length: {len(resp_body)}\r\n"
            f"Connection: close\r\n"
            f"\r\n"
        ).encode("latin-1") + resp_body
        await _write(conn, out)
        return  # Connection: close — one request per connection.


async def _read_body(conn: BufferedConn, n: int) -> bytes:
    import asyncio
    try:
        return await conn.readexactly(n)
    except asyncio.IncompleteReadError as exc:
        return exc.partial


async def _write(conn: BufferedConn, data: bytes) -> None:
    writer = getattr(conn, "writer", None)
    if writer is not None:
        writer.write(data)
        await writer.drain()
