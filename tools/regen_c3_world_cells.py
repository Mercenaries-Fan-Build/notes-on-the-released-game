#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Re-extract c3 world-cell blocks (mesh + mesh_scene.glb) with LOD dedup.

Walks ``<pipeline-root>/extracted/review/batch_vz/`` for c3#### block folders
that already have ``submeshes/index.json``, re-runs ``mesh_extractor.py`` with
``--lod highest-poly-per-xz-footprint`` (default), then emits ``mesh_scene.glb``.

Usage::

    make regen-c3-cells OUTPUT=./output
    # or
    .venv/bin/python3 tools/regen_c3_world_cells.py --pipeline-root ./output --jobs 16

After regen, re-import in UE5 (``MERCS2_FORCE_IMPORT=1`` on import_world / setup_all).
"""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
from concurrent.futures import ProcessPoolExecutor, as_completed
from pathlib import Path

_REPO = Path(__file__).resolve().parent.parent
_TOOLS = _REPO / "tools"

_C3_STEM_RE = re.compile(r"blocks__vz__c3\d{4}", re.IGNORECASE)


def _is_c3_review_stem(stem: str) -> bool:
    lower = stem.lower()
    if _C3_STEM_RE.search(lower):
        return True
    return "__shared__" in lower and re.search(r"c3\d{4}", lower) is not None


def _collect_review_dirs(review_vz: Path) -> list[Path]:
    out: list[Path] = []
    if not review_vz.is_dir():
        return out
    for block_dir in sorted(review_vz.iterdir()):
        if not block_dir.is_dir():
            continue
        if not _is_c3_review_stem(block_dir.name):
            continue
        if not (block_dir / "submeshes" / "index.json").is_file():
            continue
        out.append(block_dir)
    return out


def _regen_one(
    review_dir: str,
    pipeline_root: str,
    python: str,
    mesh_lod: str,
    mesh_format: str,
    texture_index: str,
    glb_root_scale: float,
) -> tuple[str, str]:
    rd = Path(review_dir)
    stem = rd.name
    blob = Path(pipeline_root) / "extracted" / "batch_vz" / "blocks" / f"{stem}.bin"
    if not blob.is_file():
        return stem, f"err: missing blob {blob}"

    mesh_out = rd / f"mesh.{mesh_format}"
    mesh_cmd = [
        python,
        str(_TOOLS / "mesh_extractor.py"),
        str(blob),
        "--out",
        str(mesh_out),
        "--format",
        mesh_format,
        "--indices",
        "--stem",
        stem,
        "--per-submesh-obj",
        "--lod",
        mesh_lod,
    ]
    if texture_index and Path(texture_index).is_file():
        mesh_cmd.extend(["--texture-index", texture_index])

    try:
        proc = subprocess.run(
            mesh_cmd,
            capture_output=True,
            text=True,
            check=False,
        )
        if proc.returncode != 0:
            tail = (proc.stderr or proc.stdout or "").strip().splitlines()
            msg = tail[-1] if tail else f"exit {proc.returncode}"
            return stem, f"err: mesh_extractor: {msg}"
    except OSError as exc:
        return stem, f"err: mesh_extractor: {exc}"

    if not (rd / "submeshes" / "index.json").is_file():
        return stem, "err: no submeshes/index.json after mesh extract"

    gltf_cmd = [
        python,
        str(_TOOLS / "gltf_exporter.py"),
        "--review-dir",
        str(rd),
        "--out",
        str(rd / "mesh_scene.glb"),
        "--stem",
        stem,
        "--format",
        "glb",
        "--glb-root-scale",
        str(glb_root_scale),
    ]
    try:
        proc = subprocess.run(
            gltf_cmd,
            capture_output=True,
            text=True,
            check=False,
        )
        if proc.returncode != 0:
            tail = (proc.stderr or proc.stdout or "").strip().splitlines()
            msg = tail[-1] if tail else f"exit {proc.returncode}"
            return stem, f"err: gltf_exporter: {msg}"
    except OSError as exc:
        return stem, f"err: gltf_exporter: {exc}"

    return stem, "ok"


def main() -> int:
    ap = argparse.ArgumentParser(description="Re-extract c3 world-cell meshes with LOD dedup")
    ap.add_argument("--pipeline-root", type=Path, required=True)
    ap.add_argument(
        "--lod",
        choices=(
            "keep-all",
            "dedupe-bbox",
            "highest-poly-per-bbox",
            "highest-poly-per-xz-footprint",
        ),
        default="highest-poly-per-xz-footprint",
        help="LOD culling for mesh_extractor (default: highest-poly-per-xz-footprint)",
    )
    ap.add_argument("--jobs", type=int, default=max(2, (os.cpu_count() or 4) - 1))
    ap.add_argument("--mesh-format", default="obj")
    ap.add_argument(
        "--texture-index",
        type=Path,
        default=None,
        help="Default: <pipeline-root>/extracted/texture_index.json when present",
    )
    ap.add_argument("--glb-root-scale", type=float, default=1.0)
    ap.add_argument("--limit", type=int, default=0, help="Process only first N cells (0 = all)")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    pipeline_root = args.pipeline_root.resolve()
    review_vz = pipeline_root / "extracted" / "review" / "batch_vz"
    dirs = _collect_review_dirs(review_vz)
    if args.limit > 0:
        dirs = dirs[: args.limit]

    tex_idx = args.texture_index
    if tex_idx is None:
        default_tex = pipeline_root / "extracted" / "texture_index.json"
        tex_idx = default_tex if default_tex.is_file() else None

    python = sys.executable
    print(
        f"Found {len(dirs)} c3 review folders under {review_vz}",
        flush=True,
    )
    print(f"  lod={args.lod} jobs={args.jobs} texture_index={tex_idx or '(none)'}", flush=True)

    if args.dry_run:
        for d in dirs[:15]:
            print(f"  {d.name}")
        if len(dirs) > 15:
            print(f"  ... and {len(dirs) - 15} more")
        return 0

    if not dirs:
        print("error: no c3 review folders with submeshes/index.json", file=sys.stderr)
        return 1

    ok = 0
    err = 0
    err_rows: list[tuple[str, str]] = []
    tex_str = str(tex_idx) if tex_idx else ""

    with ProcessPoolExecutor(max_workers=max(1, args.jobs)) as ex:
        futs = {
            ex.submit(
                _regen_one,
                str(d),
                str(pipeline_root),
                python,
                args.lod,
                args.mesh_format,
                tex_str,
                args.glb_root_scale,
            ): d
            for d in dirs
        }
        done = 0
        for fut in as_completed(futs):
            done += 1
            stem, status = fut.result()
            if status == "ok":
                ok += 1
            else:
                err += 1
                err_rows.append((stem, status))
            if done % 25 == 0 or done == len(dirs):
                print(f"[{done}/{len(dirs)}] ok={ok} err={err}", flush=True)

    print(f"\nFinished: ok={ok} err={err}")
    for stem, status in err_rows[:20]:
        print(f"  ERR {stem}: {status}")
    if len(err_rows) > 20:
        print(f"  ... and {len(err_rows) - 20} more")
    return 0 if err == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
