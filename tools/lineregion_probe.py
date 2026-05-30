#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Probe ``lineregion`` assets (type_hash ``0x6310807F``) in the resident block.

Each entry is a UCFX container with one ``data`` chunk holding a 2D polygon in
game X/Z metres (Y omitted). Verified on retail PC ``resident_P000_Q3``:

* Header: ``u16 kind`` (always ``2``), ``u16 point_count``, then ``u32 pad``.
* Points: ``point_count × (float x, float z)`` — 8 bytes per vertex.

Read-only — no WAD writes.

Usage::

    .venv/Scripts/python tools/lineregion_probe.py --wad game-files/pc-game-vz.wad
    .venv/Scripts/python tools/lineregion_probe.py --block-bin resident.block.bin -n 20
"""

from __future__ import annotations

import argparse
import json
import struct
import sys
from pathlib import Path
from typing import Any

_TOOLS = Path(__file__).resolve().parent
if str(_TOOLS) not in sys.path:
    sys.path.insert(0, str(_TOOLS))

from texture_streaming_index import iter_block_entries
from ucfx_mesh_codec import read_chunk_header
from watermap_probe import (
    DEFAULT_PARTIAL,
    DEFAULT_WAD,
    LINEREGION_TYPE_HASH,
    _load_resident_from_wad,
)

LINEREGION_KIND_POLYGON_XZ = 2
DATA_HEADER_SIZE = 8


def _lineregion_payload(ucfx_body: bytes) -> bytes:
    if len(ucfx_body) < 20 or ucfx_body[:4] != b"UCFX":
        raise ValueError("not UCFX")
    dao, _, _, n_chunks = struct.unpack_from("<IIII", ucfx_body, 4)
    if int(n_chunks) < 1:
        raise ValueError("no chunks")
    tag, (rel_off, chunk_size, _, _) = read_chunk_header(ucfx_body, 20)
    if tag != b"data":
        raise ValueError(f"expected data chunk, got {tag!r}")
    start = int(dao) + int(rel_off)
    return ucfx_body[start : start + int(chunk_size)]


def decode_lineregion_data(payload: bytes) -> dict[str, Any]:
    if len(payload) < DATA_HEADER_SIZE:
        raise ValueError(f"data chunk too short: {len(payload)}")
    kind, point_count = struct.unpack_from("<HH", payload, 0)
    pad = struct.unpack_from("<I", payload, 4)[0]
    expected = DATA_HEADER_SIZE + int(point_count) * 8
    if expected != len(payload):
        raise ValueError(
            f"size mismatch: header+{point_count}*8={expected} != {len(payload)}"
        )
    points: list[dict[str, float]] = []
    for i in range(int(point_count)):
        x, z = struct.unpack_from("<ff", payload, DATA_HEADER_SIZE + i * 8)
        points.append({"x": round(float(x), 3), "z": round(float(z), 3)})
    xs = [p["x"] for p in points]
    zs = [p["z"] for p in points]
    return {
        "kind": int(kind),
        "point_count": int(point_count),
        "pad_u32": int(pad),
        "points": points,
        "bbox_xz": {
            "min_x": round(min(xs), 3),
            "max_x": round(max(xs), 3),
            "min_z": round(min(zs), 3),
            "max_z": round(max(zs), 3),
        },
    }


def probe_block(
    data: bytes,
    *,
    source: str,
    max_entries: int,
) -> dict[str, Any]:
    entries: list[dict[str, Any]] = []
    errors: list[dict[str, Any]] = []
    for asset_hash, type_hash, body_offset, size in iter_block_entries(data):
        if type_hash != LINEREGION_TYPE_HASH:
            continue
        rec: dict[str, Any] = {
            "asset_hash": f"0x{asset_hash:08X}",
            "body_offset": body_offset,
            "body_size": size,
        }
        try:
            body = data[body_offset : body_offset + size]
            payload = _lineregion_payload(body)
            decoded = decode_lineregion_data(payload)
            rec.update(decoded)
            entries.append(rec)
        except Exception as exc:
            errors.append({**rec, "error": str(exc)})
        if len(entries) + len(errors) >= max_entries:
            break

    all_lr = [e for e in iter_block_entries(data) if e[1] == LINEREGION_TYPE_HASH]
    return {
        "version": 1,
        "source": source,
        "lineregion_type_hash": f"0x{LINEREGION_TYPE_HASH:08X}",
        "total_in_block": len(all_lr),
        "reported_entries": len(entries),
        "errors": errors,
        "entries": entries,
        "format": {
            "chunk": "UCFX → single ``data`` chunk",
            "header": "u16 kind (2=polygon XZ), u16 point_count, u32 zero",
            "vertices": "point_count × (float x, float z) game metres",
            "confirmed": True,
        },
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Probe lineregion polygons in resident")
    ap.add_argument("--block-bin", type=Path, default=None)
    ap.add_argument("--wad", type=Path, default=None)
    ap.add_argument("-n", "--max", type=int, default=10, help="Max entries to decode (default 10)")
    ap.add_argument("--out", type=Path, default=None)
    args = ap.parse_args()

    if args.block_bin is not None:
        path = args.block_bin.resolve()
        data = path.read_bytes()
        doc = probe_block(data, source=str(path), max_entries=args.max)
    elif args.wad is not None:
        wad = args.wad.resolve()
        data, pth = _load_resident_from_wad(wad)
        doc = probe_block(data, source=f"{wad} :: {pth}", max_entries=args.max)
    elif DEFAULT_PARTIAL.is_file():
        data = DEFAULT_PARTIAL.read_bytes()
        doc = probe_block(data, source=str(DEFAULT_PARTIAL), max_entries=args.max)
    elif DEFAULT_WAD.is_file():
        data, pth = _load_resident_from_wad(DEFAULT_WAD)
        doc = probe_block(data, source=f"{DEFAULT_WAD} :: {pth}", max_entries=args.max)
    else:
        print("error: pass --block-bin or --wad", file=sys.stderr)
        return 1

    text = json.dumps(doc, indent=2)
    if args.out is not None:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(text + "\n", encoding="utf-8")
        print(f"Wrote {args.out}", file=sys.stderr)
    else:
        print(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
