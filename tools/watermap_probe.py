#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Probe the Mercenaries 2 ``watermap`` singleton (type_hash ``0x4D7D30C4``).

The watermap lives in the always-loaded ``resident`` block as a single ASET entry.
This tool locates that entry in:

  * a decompressed ``*.block.bin`` (``--block-bin``),
  * ``output/data/block_0464_le.bin`` (partial resident slice, if present),
  * or by decompressing the ``resident`` block from a retail ``vz.wad`` (``--wad``).

It emits a JSON report with UCFX chunk tags, inferred grid dimensions, and float
height-field statistics. Read-only — no WAD writes, no full pipeline.

Usage::

    .venv/Scripts/python tools/watermap_probe.py --wad game-files/pc-game-vz.wad
    .venv/Scripts/python tools/watermap_probe.py --block-bin output/data/block_0464_le.bin
"""

from __future__ import annotations

import argparse
import json
import math
import mmap
import struct
import sys
from pathlib import Path
from typing import Any

_TOOLS = Path(__file__).resolve().parent
if str(_TOOLS) not in sys.path:
    sys.path.insert(0, str(_TOOLS))

from texture_streaming_index import iter_block_entries
from ucfx_mesh_codec import CHUNK_HDR, CONTAINER_SENTINEL, read_chunk_header

WATERMAP_TYPE_HASH = 0x4D7D30C4
LINEREGION_TYPE_HASH = 0x6310807F
DEFAULT_WAD = _TOOLS.parent / "game-files" / "pc-game-vz.wad"
DEFAULT_PARTIAL = _TOOLS.parent / "output" / "data" / "block_0464_le.bin"


def _find_watermap_entry(data: bytes) -> tuple[int, int, int, int] | None:
    for asset_hash, type_hash, body_offset, size in iter_block_entries(data):
        if type_hash == WATERMAP_TYPE_HASH:
            return asset_hash, type_hash, body_offset, size
    return None


def _parse_ucfx_outer(body: bytes) -> dict[str, Any]:
    if len(body) < 20 or body[:4] != b"UCFX":
        return {"error": "not_ucfx", "size": len(body)}
    dao, _u1, _u2, n_chunks = struct.unpack_from("<IIII", body, 4)
    chunks: list[dict[str, Any]] = []
    for i in range(int(n_chunks)):
        cpos = 20 + i * CHUNK_HDR
        if cpos + CHUNK_HDR > len(body):
            break
        tag, cu = read_chunk_header(body, cpos)
        u0, u1, u2, u3 = cu
        rec: dict[str, Any] = {
            "tag": tag.decode("ascii", errors="replace"),
            "rel_off": int(u0),
            "size": int(u1),
            "u2": int(u2),
            "u3": int(u3),
        }
        if u0 != CONTAINER_SENTINEL and u1 > 0:
            pstart = int(dao) + int(u0)
            pend = min(len(body), pstart + int(u1))
            payload = body[pstart:pend]
            rec["payload_size"] = len(payload)
            rec["payload_head_hex"] = payload[:64].hex()
            rec["analysis"] = _analyze_watr_payload(payload)
        chunks.append(rec)
    return {
        "dao": int(dao),
        "n_chunks": int(n_chunks),
        "chunks": chunks,
    }


def _analyze_watr_payload(payload: bytes) -> dict[str, Any]:
    """Summary of ``watr`` layout (full decode: ``watermap_decode.py``)."""
    try:
        from watermap_decode import decode_watr_payload

        full = decode_watr_payload(payload)
        layer0 = full["layers"][0]
        return {
            "size": len(payload),
            "layer_count": full["header"]["layer_count"],
            "grid_width": full["header"]["grid_width"],
            "grid_height": full["header"]["grid_height"],
            "header_floats": list(full["header"]["header_floats"].values()),
            "height_raster": {
                "offset": layer0["offset"],
                "dtype": layer0["dtype"],
                "cells": layer0["cells"],
                "min_m": layer0["min"],
                "max_m": layer0["max"],
                "mean_m": layer0["mean"],
            },
            "trailing_bytes": full["footer"]["size"],
            "decode": "see tools/watermap_decode.py",
        }
    except Exception as exc:
        return {"size": len(payload), "error": str(exc)}


def _lineregion_summary(data: bytes) -> dict[str, Any]:
    entries = [e for e in iter_block_entries(data) if e[1] == LINEREGION_TYPE_HASH]
    sizes: dict[int, int] = {}
    for _ah, _th, _off, sz in entries:
        sizes[int(sz)] = sizes.get(int(sz), 0) + 1
    return {
        "count": len(entries),
        "unique_sizes": sorted(sizes.keys()),
        "size_histogram": {str(k): v for k, v in sorted(sizes.items())},
    }


def _load_resident_from_wad(wad_path: Path) -> tuple[bytes, str]:
    from wad_patcher import find_data_chunk, get_block_boundaries, load_wad_paths
    from sges_decompress import decompress_sges_block

    paths = load_wad_paths(wad_path)
    resident_indices = [
        i for i, p in enumerate(paths)
        if "resident" in p.lower() and "resident2" not in p.lower() and "sound_" not in p.lower()
    ]
    if not resident_indices:
        raise FileNotFoundError(f"no resident block path in {wad_path}")
    idx = resident_indices[0]
    with open(wad_path, "rb") as f:
        mm = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)
        dc = find_data_chunk(wad_path)
        s, e = get_block_boundaries(mm, dc.offset, dc.size)[idx]
        data = decompress_sges_block(mm, s, e)
        mm.close()
    return data, paths[idx]


def probe_block(data: bytes, *, source: str) -> dict[str, Any]:
    wm = _find_watermap_entry(data)
    doc: dict[str, Any] = {
        "version": 1,
        "source": source,
        "block_bytes": len(data),
        "block_entry_count": len(iter_block_entries(data)),
        "watermap_type_hash": f"0x{WATERMAP_TYPE_HASH:08X}",
        "lineregion_type_hash": f"0x{LINEREGION_TYPE_HASH:08X}",
        "lineregion": _lineregion_summary(data),
    }
    if wm is None:
        doc["watermap"] = None
        doc["error"] = "watermap entry not found in block"
        return doc

    asset_hash, _th, body_offset, size = wm
    body = data[body_offset : body_offset + size]
    doc["watermap"] = {
        "asset_hash": f"0x{asset_hash:08X}",
        "body_offset": body_offset,
        "body_size": size,
        "ucfx": _parse_ucfx_outer(body),
    }
    return doc


def main() -> int:
    ap = argparse.ArgumentParser(description="Probe watermap singleton structure")
    ap.add_argument("--block-bin", type=Path, default=None, help="Decompressed resident .block.bin")
    ap.add_argument("--wad", type=Path, default=None, help="Retail FFCS .wad (decompresses resident block only)")
    ap.add_argument("--out", type=Path, default=None, help="JSON report path (default: stdout)")
    args = ap.parse_args()

    if args.block_bin is not None:
        path = args.block_bin.resolve()
        if not path.is_file():
            print(f"error: block not found: {path}", file=sys.stderr)
            return 1
        data = path.read_bytes()
        doc = probe_block(data, source=str(path))
    elif args.wad is not None:
        wad = args.wad.resolve()
        if not wad.is_file():
            print(f"error: wad not found: {wad}", file=sys.stderr)
            return 1
        data, path_str = _load_resident_from_wad(wad)
        doc = probe_block(data, source=f"{wad} :: {path_str}")
    elif DEFAULT_PARTIAL.is_file():
        data = DEFAULT_PARTIAL.read_bytes()
        doc = probe_block(data, source=str(DEFAULT_PARTIAL))
        doc["note"] = "partial resident slice (may have fewer lineregion entries than full resident)"
    elif DEFAULT_WAD.is_file():
        data, path_str = _load_resident_from_wad(DEFAULT_WAD)
        doc = probe_block(data, source=f"{DEFAULT_WAD} :: {path_str}")
    else:
        print(
            "error: no input — pass --block-bin or --wad, or place "
            f"{DEFAULT_PARTIAL} or {DEFAULT_WAD}",
            file=sys.stderr,
        )
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
