#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Decode ``ASET`` chunk rows from extracted ``ffcs_vz/aset.bin``.

Each row is **16 bytes** (``len(aset.bin) / meta`` from ``manifest.json``).

**Verified:** field ``u32_0`` matches many keys in ``texture_index.json`` (asset hash / streaming key).

Other fields remain **unverified** — exported as raw hex for correlation work.
"""

from __future__ import annotations

import argparse
import json
import struct
from pathlib import Path


def main() -> int:
    ap = argparse.ArgumentParser(description="Decode vz.wad ASET chunk into JSON graph hints")
    ap.add_argument(
        "--aset",
        type=Path,
        default=Path("output/extracted/ffcs_vz/aset.bin"),
    )
    ap.add_argument(
        "--texture-index",
        type=Path,
        default=Path("output/extracted/texture_index.json"),
    )
    ap.add_argument(
        "--out",
        type=Path,
        default=Path("output/block_dependency_graph.json"),
    )
    args = ap.parse_args()

    if not args.aset.is_file():
        print(f"error: missing {args.aset}")
        return 1

    raw = args.aset.read_bytes()
    if len(raw) % 16 != 0:
        print(f"error: ASET size {len(raw)} not multiple of 16")
        return 1

    tex_keys: set[str] = set()
    if args.texture_index.is_file():
        tex_keys = set(json.loads(args.texture_index.read_text(encoding="utf-8")).keys())

    rows_out: list[dict[str, object]] = []
    hits_tex = 0
    n = len(raw) // 16
    for i in range(n):
        o = i * 16
        u0, u1, u2, u3 = struct.unpack_from("<IIII", raw, o)
        h0 = f"0x{u0:08x}"
        row: dict[str, object] = {
            "row_index": i,
            "u32_0": h0,
            "u32_1": f"0x{u1:08x}",
            "u32_2": f"0x{u2:08x}",
            "u32_3": u3,
            "texture_index_hit": h0 in tex_keys,
        }
        if row["texture_index_hit"]:
            hits_tex += 1
        rows_out.append(row)

    doc: dict[str, object] = {
        "source": str(args.aset),
        "row_count": n,
        "row_stride_bytes": 16,
        "texture_index_hits_on_u32_0": hits_tex,
        "note": "u32_0 correlates with texture streaming keys; u32_1/u32_2/u32_3 semantics unverified",
        "rows": rows_out,
    }
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(doc, indent=2), encoding="utf-8")
    print(f"Wrote {args.out} ({n} rows, {hits_tex} texture_index hits on u32_0)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
