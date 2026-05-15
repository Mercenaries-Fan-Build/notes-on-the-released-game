#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Regenerate mesh_scene.glb for assets in maracaibo_asset_list.json.

Usage:
    python tools/regen_maracaibo_glbs.py --pipeline-root ./output

Reads ``<pipeline-root>/maracaibo_asset_list.json``, locates each asset's
review directory, and calls ``gltf_exporter.export_review_to_gltf`` in GLB
mode (embedded textures; root scale defaults to 1, see ``--glb-root-scale``).
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


def main() -> int:
    ap = argparse.ArgumentParser(description="Regen mesh_scene.glb for Maracaibo subset")
    ap.add_argument("--pipeline-root", type=Path, required=True)
    ap.add_argument("--dry-run", action="store_true", help="Print what would be done without writing")
    ap.add_argument(
        "--glb-root-scale",
        type=float,
        default=1.0,
        help="Uniform glTF root scale for GLB only (default: 1). Passed to gltf_exporter.",
    )
    args = ap.parse_args()

    asset_list = args.pipeline_root / "maracaibo_asset_list.json"
    if not asset_list.is_file():
        print(f"error: missing {asset_list} -- run: make filter-maracaibo", file=sys.stderr)
        return 1

    data = json.loads(asset_list.read_text(encoding="utf-8"))
    review_root = args.pipeline_root / "extracted" / "review"

    from gltf_exporter import export_review_to_gltf

    total = 0
    written = 0
    skipped = 0
    errors = 0

    for _cat, items in data.get("assets", {}).items():
        for item in items:
            total += 1
            pack = item.get("pack", "")
            stem = item.get("stem", "")
            review_dir = review_root / pack / stem
            submeshes = review_dir / "submeshes" / "index.json"

            if not submeshes.is_file():
                skipped += 1
                continue

            out_glb = review_dir / "mesh_scene.glb"
            if args.dry_run:
                print(f"  [dry-run] {review_dir} -> {out_glb}")
                written += 1
                continue

            try:
                export_review_to_gltf(
                    review_dir, out_glb, output_format="glb", glb_root_scale=args.glb_root_scale
                )
                written += 1
                print(f"  [{written}/{total}] {stem}")
            except Exception as e:
                print(f"  FAILED {stem}: {e}", file=sys.stderr)
                errors += 1

    print(f"Done: {written} written, {skipped} skipped (no submeshes), {errors} errors out of {total}")
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
