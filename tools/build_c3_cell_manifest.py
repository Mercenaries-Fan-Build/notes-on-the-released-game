#!/usr/bin/env python3
"""Build a JSON manifest of c3 world-cell review folders with mesh geometry.

Used to plan import/populate and to verify grid decode before running UE scripts.

Example::

    .venv/bin/python3 tools/build_c3_cell_manifest.py \\
        --review-root output/extracted/review/batch_vz \\
        --out output/placements/c3_cell_manifest.json \\
        --min-vertices 50
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

_TOOLS = Path(__file__).resolve().parent
if str(_TOOLS) not in sys.path:
    sys.path.insert(0, str(_TOOLS))

import c3_cell_grid as grid

_C3_STEM_RE = re.compile(r"blocks__vz__c3(\d{4})", re.IGNORECASE)


def main() -> int:
    ap = argparse.ArgumentParser(description="Harvest c3 cell mesh review metadata")
    ap.add_argument("--review-root", type=Path, required=True)
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--min-vertices", type=int, default=50)
    args = ap.parse_args()

    root: Path = args.review_root
    if not root.is_dir():
        print(f"Not a directory: {root}", file=sys.stderr)
        return 1

    entries: list[dict] = []
    for block_dir in sorted(root.iterdir()):
        if not block_dir.is_dir():
            continue
        m = _C3_STEM_RE.search(block_dir.name)
        if not m:
            continue
        meta_path = block_dir / "mesh.meta.json"
        verts = 0
        if meta_path.is_file():
            meta = json.loads(meta_path.read_text(encoding="utf-8"))
            verts = int(meta.get("vertices", 0))
        if verts < args.min_vertices:
            continue
        cell_id = int(m.group(1))
        xyz = grid.cell_id_to_world_xyz(cell_id)
        has_glb = (block_dir / "mesh_scene.glb").is_file()
        has_gltf = (block_dir / "mesh_scene.gltf").is_file()
        entries.append(
            {
                "stem": block_dir.name,
                "cell_id": cell_id,
                "position": {"x": xyz[0], "y": xyz[1], "z": xyz[2]},
                "vertices": verts,
                "has_glb": has_glb,
                "has_gltf": has_gltf,
            }
        )

    args.out.parent.mkdir(parents=True, exist_ok=True)
    doc = {
        "review_root": str(root.resolve()),
        "min_vertices": args.min_vertices,
        "cell_count": len(entries),
        "cells": entries,
    }
    args.out.write_text(json.dumps(doc, indent=2), encoding="utf-8")
    print(f"Wrote {len(entries)} cells → {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
