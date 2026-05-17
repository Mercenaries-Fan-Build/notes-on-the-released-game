#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Regenerate mesh_scene.glb for ALL assets in the ue5_import manifest.

Usage:
    python tools/regen_all_glbs.py --pipeline-root ./output
    python tools/regen_all_glbs.py --pipeline-root ./output --force
    python tools/regen_all_glbs.py --pipeline-root ./output --jobs 8

Reads ``<pipeline-root>/ue5_import/metadata/manifest.json``, locates each
asset's review directory, and calls ``gltf_exporter.export_review_to_gltf``
for every block that has a ``submeshes/index.json``.
"""
from __future__ import annotations

import argparse
import json
import sys
import time
from concurrent.futures import ProcessPoolExecutor, as_completed
from pathlib import Path


def _export_one(review_dir: str, out_glb: str, glb_root_scale: float) -> str | None:
    """Worker function for parallel export. Returns error message or None."""
    import sys as _sys
    from pathlib import Path as _Path

    tools_dir = str(_Path(__file__).resolve().parent)
    if tools_dir not in _sys.path:
        _sys.path.insert(0, tools_dir)

    from gltf_exporter import export_review_to_gltf

    try:
        export_review_to_gltf(
            _Path(review_dir), _Path(out_glb), output_format="glb", glb_root_scale=glb_root_scale
        )
        return None
    except Exception as e:
        return str(e)


def main() -> int:
    ap = argparse.ArgumentParser(description="Regen mesh_scene.glb for all manifest assets")
    ap.add_argument("--pipeline-root", type=Path, required=True)
    ap.add_argument("--dry-run", action="store_true", help="Print what would be done")
    ap.add_argument("--force", action="store_true", help="Regenerate even if GLB already exists")
    ap.add_argument("--jobs", "-j", type=int, default=1, help="Parallel workers (default: 1)")
    ap.add_argument(
        "--glb-root-scale",
        type=float,
        default=1.0,
        help="Uniform glTF root scale (default: 1)",
    )
    args = ap.parse_args()

    manifest_path = args.pipeline_root / "ue5_import" / "metadata" / "manifest.json"
    if not manifest_path.is_file():
        print(f"error: missing {manifest_path} — run: make ue5-bundle", file=sys.stderr)
        return 1

    data = json.loads(manifest_path.read_text(encoding="utf-8"))
    assets = data.get("assets", [])
    review_root = args.pipeline_root / "extracted" / "review"

    work_items: list[tuple[Path, Path]] = []
    skipped_no_mesh = 0
    skipped_exists = 0

    for item in assets:
        pack = item.get("pack", "")
        stem = item.get("stem", "")
        review_dir = review_root / pack / stem
        submeshes = review_dir / "submeshes" / "index.json"

        if not submeshes.is_file():
            skipped_no_mesh += 1
            continue

        out_glb = review_dir / "mesh_scene.glb"
        if out_glb.is_file() and not args.force:
            skipped_exists += 1
            continue

        work_items.append((review_dir, out_glb))

    total_assets = len(assets)
    to_process = len(work_items)

    print(f"Manifest: {total_assets} assets")
    print(f"  {skipped_no_mesh} skipped (no submeshes/index.json)")
    print(f"  {skipped_exists} skipped (GLB exists, use --force to redo)")
    print(f"  {to_process} to generate")

    if args.dry_run:
        for review_dir, out_glb in work_items[:20]:
            print(f"  [dry-run] {review_dir.name}")
        if to_process > 20:
            print(f"  ... and {to_process - 20} more")
        return 0

    if to_process == 0:
        print("Nothing to do.")
        return 0

    written = 0
    errors = 0
    t0 = time.time()

    if args.jobs <= 1:
        tools_dir = str(Path(__file__).resolve().parent)
        if tools_dir not in sys.path:
            sys.path.insert(0, tools_dir)
        from gltf_exporter import export_review_to_gltf

        for i, (review_dir, out_glb) in enumerate(work_items, 1):
            try:
                export_review_to_gltf(
                    review_dir, out_glb, output_format="glb", glb_root_scale=args.glb_root_scale
                )
                written += 1
                if written % 50 == 0 or written == to_process:
                    elapsed = time.time() - t0
                    rate = written / elapsed if elapsed > 0 else 0
                    print(f"  [{written}/{to_process}] {rate:.1f}/s — {review_dir.name}")
            except Exception as e:
                print(f"  FAILED {review_dir.name}: {e}", file=sys.stderr)
                errors += 1
    else:
        with ProcessPoolExecutor(max_workers=args.jobs) as pool:
            futures = {
                pool.submit(
                    _export_one, str(review_dir), str(out_glb), args.glb_root_scale
                ): review_dir
                for review_dir, out_glb in work_items
            }
            for future in as_completed(futures):
                review_dir = futures[future]
                err = future.result()
                if err is None:
                    written += 1
                    if written % 50 == 0 or written == to_process:
                        elapsed = time.time() - t0
                        rate = written / elapsed if elapsed > 0 else 0
                        print(f"  [{written}/{to_process}] {rate:.1f}/s — {review_dir.name}")
                else:
                    print(f"  FAILED {review_dir.name}: {err}", file=sys.stderr)
                    errors += 1

    elapsed = time.time() - t0
    print(f"\nDone in {elapsed:.1f}s: {written} written, {errors} errors, "
          f"{skipped_no_mesh} no-mesh, {skipped_exists} already-exist")
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
