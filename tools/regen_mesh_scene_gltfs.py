#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Re-emit every ``mesh_scene.gltf`` under a root using :func:`gltf_exporter.export_review_to_gltf`.

Used after the ``world_translation`` double-transform fix to repair previously
extracted scenes (packs / glasses / eyes / etc. floated when the verts and the
node matrix both carried the HIER offset).
"""

from __future__ import annotations

import argparse
import os
import sys
import traceback
from concurrent.futures import ProcessPoolExecutor, as_completed
from pathlib import Path

_TOOLS = Path(__file__).resolve().parent
if str(_TOOLS) not in sys.path:
    sys.path.insert(0, str(_TOOLS))


def _regen_one(folder: str) -> tuple[str, str]:
    from gltf_exporter import export_review_to_gltf

    fd = Path(folder)
    try:
        out = fd / "mesh_scene.gltf"
        export_review_to_gltf(fd, out, stem=fd.name)
        return (folder, "ok")
    except Exception as e:  # noqa: BLE001
        return (folder, f"err: {e.__class__.__name__}: {e}")


def collect_folders(roots: list[Path]) -> list[Path]:
    out: list[Path] = []
    seen: set[Path] = set()
    for root in roots:
        if not root.is_dir():
            continue
        for p in root.rglob("mesh_scene.gltf"):
            d = p.parent
            if (d / "submeshes" / "index.json").is_file() and d not in seen:
                seen.add(d)
                out.append(d)
    return sorted(out)


def main() -> int:
    ap = argparse.ArgumentParser(description="Regenerate mesh_scene.gltf files in bulk")
    ap.add_argument(
        "--root",
        type=Path,
        action="append",
        required=True,
        help="Root to walk (repeat to add more, e.g. output/extracted/review and output/ue5_import)",
    )
    ap.add_argument("--workers", type=int, default=max(2, (os.cpu_count() or 4) - 1))
    ap.add_argument("--limit", type=int, default=0, help="Only regen the first N folders (0 = all)")
    ap.add_argument("--dry-run", action="store_true", help="List candidate folders and exit")
    args = ap.parse_args()

    folders = collect_folders(args.root)
    if args.limit > 0:
        folders = folders[: args.limit]
    print(f"found {len(folders)} folders with mesh_scene.gltf + submeshes/index.json", flush=True)
    if args.dry_run:
        for f in folders[:20]:
            print(f"  {f}")
        return 0

    ok = 0
    err = 0
    err_rows: list[tuple[str, str]] = []
    with ProcessPoolExecutor(max_workers=args.workers) as ex:
        futs = {ex.submit(_regen_one, str(f)): f for f in folders}
        done = 0
        for fut in as_completed(futs):
            done += 1
            try:
                folder, status = fut.result()
            except Exception as e:  # noqa: BLE001
                folder = str(futs[fut])
                status = f"crash: {e.__class__.__name__}: {e}"
                traceback.print_exc(file=sys.stderr)
            if status == "ok":
                ok += 1
            else:
                err += 1
                err_rows.append((folder, status))
            if done % 50 == 0 or done == len(folders):
                print(f"[{done}/{len(folders)}] ok={ok} err={err}", flush=True)

    print(f"\nfinished: ok={ok} err={err}")
    for folder, status in err_rows[:25]:
        print(f"  ERR {folder}: {status}")
    if len(err_rows) > 25:
        print(f"  ... and {len(err_rows) - 25} more")
    return 0 if err == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
