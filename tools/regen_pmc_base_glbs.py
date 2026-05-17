#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Regenerate ``mesh_scene.glb`` for assets listed in ``pmc_base_asset_list.json``."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


def main() -> int:
    ap = argparse.ArgumentParser(description="Regen mesh_scene.glb for PMC base subset")
    ap.add_argument("--pipeline-root", type=Path, required=True)
    ap.add_argument(
        "--asset-list",
        type=Path,
        default=None,
        help="Asset list JSON (default: OUTPUT/pmc_base_asset_list.json)",
    )
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--glb-root-scale", type=float, default=1.0)
    args = ap.parse_args()

    asset_list = args.asset_list or (args.pipeline_root / "pmc_base_asset_list.json")
    if not asset_list.is_file():
        print(f"error: missing {asset_list} — run filter target first", file=sys.stderr)
        return 1

    data = json.loads(asset_list.read_text(encoding="utf-8"))
    review_root = args.pipeline_root / "extracted" / "review"

    from gltf_exporter import export_review_to_gltf

    items = data.get("assets", [])
    total = len(items)
    written = 0
    skipped = 0
    errors = 0

    for item in items:
        pack = item.get("pack", "")
        stem = item.get("stem", "")
        review_dir = review_root / pack / stem
        submeshes = review_dir / "submeshes" / "index.json"
        if not submeshes.is_file():
            skipped += 1
            continue
        out_glb = review_dir / "mesh_scene.glb"
        if args.dry_run:
            print(f"  [dry-run] {review_dir}")
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

    print(f"Done: {written} written, {skipped} skipped, {errors} errors / {total}")
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
