"""FESL / Theater binary frame codec.

FESL wire format (also used, with uppercase 4CC tags, by Theater):

    offset  size  field
    0x00    4     type   (ASCII: "fsys","acct","subs","thtr", or "CONN" etc.)
    0x04    4     id     (32-bit big-endian; high bits encode packet kind)
    0x08    4     length (32-bit big-endian; TOTAL packet size incl. 12B header)
    0x0C    N     payload — "key=value\n" pairs, NUL-terminated

Some EA variants put the payload length (excluding header) in the length field.
We handle both: if the declared length looks like it excludes the header we read
that many payload bytes; otherwise we subtract the 12-byte header.
"""
from __future__ import annotations

import struct

HEADER_LEN = 12


def _quote(v) -> str:
    # FESL escapes '=' in values as %3d (matches loganw234/Mercenaries2 server.py).
    return str(v).replace("=", "%3d")


def _unquote(v: str) -> str:
    return v.replace("%3d", "=")


def _flatten(name, obj) -> dict:
    """Flatten nested dicts/lists into FESL dotted keys, e.g.
    {'entitledGameFeatureWrappers':[{'gameFeatureId':6014}]} ->
    {'entitledGameFeatureWrappers.[]':1,'entitledGameFeatureWrappers.0.gameFeatureId':6014}.
    Lists emit a '<name>.[]'=len marker. Ported from Logan's server.py."""
    out: dict = {}
    if isinstance(obj, dict):
        for k, sub in obj.items():
            key = f"{name}.{k}" if name else k
            out.update(_flatten(key, sub))
    elif isinstance(obj, (list, tuple)):
        out = {f"{name}.[]": len(obj)}
        for i, e in enumerate(obj):
            out.update(_flatten(f"{name}.{i}", e))
    else:
        out = {name: obj}
    return out


def parse_kv(payload: bytes) -> dict[str, str]:
    text = payload.split(b"\x00", 1)[0].decode("latin-1", "replace")
    out: dict[str, str] = {}
    for line in text.split("\n"):
        line = line.strip()
        if not line or "=" not in line:
            continue
        k, v = line.split("=", 1)
        out[k] = _unquote(v)
    return out


def build_payload(fields: dict) -> bytes:
    flat = _flatten(None, fields)
    s = "\n".join(f"{k}={_quote(v)}" for k, v in flat.items()) + "\x00"
    return s.encode("latin-1")


def encode_frame(type4: str, msg_id: int, fields: dict[str, str]) -> bytes:
    payload = build_payload(fields)
    total = HEADER_LEN + len(payload)
    tag = type4.encode("latin-1")[:4].ljust(4, b" ")
    return tag + struct.pack(">II", msg_id & 0xFFFFFFFF, total) + payload


async def read_frame(conn) -> tuple[str, int, dict[str, str], bytes] | None:
    """Read one frame from a BufferedConn. Returns (type, id, kv, raw_payload)
    or None on EOF."""
    import asyncio

    try:
        header = await conn.readexactly(HEADER_LEN)
    except asyncio.IncompleteReadError:
        return None
    type4 = header[0:4].decode("latin-1", "replace").rstrip()
    msg_id, length = struct.unpack(">II", header[4:12])

    if length >= HEADER_LEN:
        payload_len = length - HEADER_LEN
    else:
        payload_len = length
    # Guard against absurd / garbage lengths.
    payload_len = max(0, min(payload_len, 1 << 20))

    try:
        payload = await conn.readexactly(payload_len) if payload_len else b""
    except asyncio.IncompleteReadError as exc:
        payload = exc.partial
    return type4, msg_id, parse_kv(payload), payload
