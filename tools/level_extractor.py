#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Heuristic level / placement hints from Mercenaries 2 blobs (UCFX vz blocks)."""

from __future__ import annotations

import argparse
import json
import math
import struct
from pathlib import Path


def valid_vec3(x: float, y: float, z: float) -> bool:
    if not all(math.isfinite(v) for v in (x, y, z)):
        return False
    if max(abs(x), abs(y), abs(z)) > 2e7:
        return False
    return True


def scan_float4x4(data: bytes, stride_align: int = 4) -> list[dict[str, object]]:
    """Find 64-byte windows that look like row-major 4x4 transforms (last row 0,0,0,1 approx)."""
    hits = []
    i = 0
    while i + 64 <= len(data):
        try:
            M = struct.unpack_from("<16f", data, i)
        except struct.error:
            i += stride_align
            continue
        # bottom row often [0,0,0,1] or [*,*,*,1]
        if abs(M[15] - 1.0) < 0.02 and abs(M[12]) + abs(M[13]) + abs(M[14]) < 1e7:
            hits.append({"offset": i, "row_major_4x4": list(M)})
        i += stride_align
        if len(hits) >= 500:
            break
    return hits


def scan_precache_dir(root: Path) -> list[dict[str, object]]:
    """If directory contains *.precache files, record paths."""
    out = []
    if not root.is_dir():
        return out
    for p in sorted(root.rglob("*.precache")):
        out.append({"precache": str(p.relative_to(root) if root in p.parents else p)})
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description="Mercenaries 2 level / matrix heuristic extractor")
    ap.add_argument("blob", nargs="?", type=Path, help="Single decompressed blob (.bin)")
    ap.add_argument("--precache-root", type=Path, help="Folder tree containing *.precache (optional)")
    ap.add_argument("--out", type=Path, required=True)
    args = ap.parse_args()

    doc: dict[str, object] = {}
    if args.blob and args.blob.is_file():
        data = args.blob.read_bytes()
        doc["blob"] = str(args.blob)
        doc["matrix_candidates"] = scan_float4x4(data)
    if args.precache_root:
        doc["precache_files"] = scan_precache_dir(args.precache_root)

    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(doc, indent=2), encoding="utf-8")
    print(f"Wrote {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
