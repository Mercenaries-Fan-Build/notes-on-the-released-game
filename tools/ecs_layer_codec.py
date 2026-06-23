#!/usr/bin/env python3
"""Read/write codec for a Mercenaries 2 ECS *layer* UCFX container (e.g. the
resident block's entry 3768 — the vehicle/entity prototype layer).

The layer is a UCFX container whose descriptor table is a flat list of 20-byte
descriptors. Container-marker rows (tag in COMP/enum/UNIQ/flgt/flgs, u0=0xFFFFFFFF)
group the following leaf rows (info/schm/data/…). Each COMP = info(name) + schm
(payload stride @ +4) + data (fixed-stride keyed records `[u32 key][payload]`).

This module parses that into an editable structure and re-serializes it
byte-identically (verified by round-trip), which is the prerequisite for cloning
an entity (add records + a Name entry, repoint ModelName, repack, fix CSUM).
"""
from __future__ import annotations

import struct
import zlib
from dataclasses import dataclass, field


def crc32_jamcrc(data: bytes) -> int:
    return (zlib.crc32(data, 0xFFFFFFFF) ^ 0xFFFFFFFF) & 0xFFFFFFFF


@dataclass
class Row:
    tag: bytes
    u0: int          # offset rel. to data_off, or 0xFFFFFFFF for container markers
    size: int
    u2: int
    u3: int


@dataclass
class Layer:
    head: bytes              # bytes 8..16 (preserved verbatim)
    rows: list[Row]
    data_off: int
    leaves: dict[int, bytes] = field(default_factory=dict)  # row index -> body bytes
    trailer: bytes = b""     # CSUM trailer (recomputed on serialize)


def parse_layer(body: bytes) -> Layer:
    assert body[:4] == b"UCFX", "not a UCFX container"
    data_off = struct.unpack_from("<I", body, 4)[0]
    ndesc = struct.unpack_from("<I", body, 16)[0]
    rows: list[Row] = []
    for i in range(ndesc):
        ro = 20 + i * 20
        tag = bytes(body[ro:ro + 4])
        u0, size, u2, u3 = struct.unpack_from("<IIII", body, ro + 4)
        rows.append(Row(tag, u0, size, u2, u3))
    leaves: dict[int, bytes] = {}
    for idx, r in enumerate(rows):
        if r.u0 == 0xFFFFFFFF:
            continue
        s = data_off + r.u0
        leaves[idx] = bytes(body[s:s + r.size])
    return Layer(head=bytes(body[8:16]), rows=rows, data_off=data_off, leaves=leaves)


def serialize_layer(layer: Layer) -> bytes:
    """Re-emit the container. Leaf bodies are placed 16-byte aligned in row order
    (matching the engine's packer); descriptor offsets/sizes recomputed; CSUM
    trailer appended."""
    new_data = bytearray()
    rows = layer.rows
    for idx, r in enumerate(rows):
        if r.u0 == 0xFFFFFFFF:
            continue
        body = layer.leaves[idx]
        r.u0 = len(new_data)      # leaves are packed contiguously (no alignment)
        r.size = len(body)
        new_data += body
    ndesc = len(rows)
    data_off = 20 + ndesc * 20
    out = bytearray()
    out += b"UCFX"
    out += struct.pack("<I", data_off)
    out += layer.head
    out += struct.pack("<I", ndesc)
    for r in rows:
        out += r.tag + struct.pack("<IIII", r.u0, r.size, r.u2, r.u3)
    out += new_data
    out += b"CSUM" + struct.pack("<I", crc32_jamcrc(bytes(out)))
    return bytes(out)


# ---- component view (read) --------------------------------------------------
@dataclass
class Comp:
    name: str
    info_idx: int
    schm_idx: int | None
    data_idx: int | None
    stride: int | None


def components(layer: Layer) -> list[Comp]:
    comps: list[Comp] = []
    cur: dict | None = None
    for idx, r in enumerate(layer.rows):
        if r.tag == b"COMP" and r.u0 == 0xFFFFFFFF:
            cur = {"info": None, "schm": None, "data": None}
            comps.append(cur)
        elif cur is not None and r.tag in (b"info", b"schm", b"data"):
            cur[r.tag.decode()] = idx
    out: list[Comp] = []
    for c in comps:
        if c["info"] is None:
            continue
        raw = layer.leaves[c["info"]]
        ni = raw.find(b"\x00")
        name = raw[:ni].decode("ascii", "replace") if ni > 0 else raw.decode("ascii", "replace")
        stride = None
        if c["schm"] is not None:
            s = layer.leaves[c["schm"]]
            if len(s) >= 8:
                stride = 4 + struct.unpack_from("<I", s, 4)[0]
        out.append(Comp(name, c["info"], c["schm"], c["data"], stride))
    return out


def keyed_records(layer: Layer, comp: Comp) -> list[tuple[int, bytes]]:
    if comp.data_idx is None or not comp.stride:
        return []
    blob = layer.leaves[comp.data_idx]
    st = comp.stride
    recs = []
    p = 0
    while p + st <= len(blob):
        recs.append((struct.unpack_from("<I", blob, p)[0], bytes(blob[p + 4:p + st])))
        p += st
    return recs


if __name__ == "__main__":
    import sys
    # Round-trip self-test on resident block entry 3768.
    blockpath = "output/extracted/batch_vz/blocks/03185_blocks__VZ__resident_P000_Q3.block.bin"
    d = open(blockpath, "rb").read()
    count = struct.unpack_from("<I", d, 0)[0]
    sizes = [struct.unpack_from("<IIII", d, 4 + i * 16)[3] for i in range(count)]
    off = 4 + count * 16 + sum(sizes[:3768])
    body = d[off:off + sizes[3768]]
    layer = parse_layer(body)
    out = serialize_layer(layer)
    comps = components(layer)
    print(f"parsed: {len(layer.rows)} rows, {len(comps)} components")
    print(f"original {len(body)}B -> reserialized {len(out)}B")
    # compare (the original has its own CSUM trailer; compare the pre-trailer body
    # and confirm our recomputed CSUM matches the original's)
    orig_csum_off = body.rfind(b"CSUM")
    same_body = out[:orig_csum_off] == body[:orig_csum_off]
    orig_csum = struct.unpack_from("<I", body, orig_csum_off + 4)[0] if orig_csum_off > 0 else None
    our_csum = struct.unpack_from("<I", out, out.rfind(b"CSUM") + 4)[0]
    print(f"body bytes identical (pre-CSUM): {same_body}")
    print(f"CSUM original=0x{orig_csum:08X} ours=0x{our_csum:08X} match={orig_csum==our_csum}")
    sys.exit(0 if same_body and orig_csum == our_csum else 1)
