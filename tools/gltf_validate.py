#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Lightweight regression check: submesh OBJ counts vs exported glTF accessors."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

from pygltflib import GLTF2


def _parse_obj_counts(path: Path) -> tuple[int, int] | None:
    pos = 0
    faces = 0
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        if line.startswith("v ") and not line.startswith("vn") and not line.startswith("vt"):
            pos += 1
        elif line.startswith("f "):
            parts = line.split()[1:]
            if len(parts) >= 3:
                faces += 1
    if not faces:
        return None
    return pos, faces


def _accessor_count(gltf: GLTF2, acc_idx: int | None) -> int | None:
    if acc_idx is None:
        return None
    return int(gltf.accessors[acc_idx].count)


def _validate(review_dir: Path, gltf_path: Path) -> list[str]:
    errs: list[str] = []
    sub_dir = review_dir / "submeshes"
    idx_path = sub_dir / "index.json"
    if not idx_path.is_file():
        errs.append(f"missing {idx_path}")
        return errs
    if not gltf_path.is_file():
        errs.append(f"missing {gltf_path}")
        return errs

    entries: list[dict[str, Any]] = json.loads(idx_path.read_text(encoding="utf-8"))
    gltf = GLTF2.load_json(str(gltf_path))
    bin_path = gltf_path.with_suffix(".bin")
    if not bin_path.is_file():
        errs.append(f"missing {bin_path}")

    mesh_idx = 0
    for i, ent in enumerate(entries):
        obj_name = str(ent.get("file", f"{i:04d}.obj"))
        op = sub_dir / obj_name
        if not op.is_file():
            continue
        parsed = _parse_obj_counts(op)
        if parsed is None:
            continue
        v_obj, f_obj = parsed
        if mesh_idx >= len(gltf.meshes):
            errs.append(f"glTF has fewer meshes than submesh OBJs (stopped at mesh {mesh_idx})")
            break
        prim = gltf.meshes[mesh_idx].primitives[0]
        pos_acc = prim.attributes.POSITION
        idx_acc = prim.indices
        v_gltf = _accessor_count(gltf, pos_acc)
        tri_gltf = None
        if idx_acc is not None:
            ic = _accessor_count(gltf, idx_acc)
            tri_gltf = ic // 3 if ic is not None else None
        if v_gltf is not None and v_gltf != v_obj:
            errs.append(f"{obj_name}: position count glTF={v_gltf} obj={v_obj}")
        if tri_gltf is not None and tri_gltf != f_obj:
            errs.append(f"{obj_name}: triangle count glTF={tri_gltf} obj={f_obj}")
        tang_idx = ent.get("tangents")
        if isinstance(tang_idx, list) and len(tang_idx) != v_obj:
            errs.append(f"{obj_name}: index.json tangents length {len(tang_idx)} != obj verts {v_obj}")
        mesh_idx += 1

    if mesh_idx != len(gltf.meshes):
        errs.append(f"glTF mesh count {len(gltf.meshes)} != exported submesh count {mesh_idx}")
    return errs


def main() -> int:
    ap = argparse.ArgumentParser(description="Validate mesh_scene.gltf vs submeshes/*.obj")
    ap.add_argument("--review-dir", type=Path, required=True)
    ap.add_argument(
        "--gltf",
        type=Path,
        default=None,
        help="Path to .gltf (default: <review-dir>/mesh_scene.gltf)",
    )
    args = ap.parse_args()
    rd = args.review_dir.resolve()
    gltf_p = (args.gltf or rd / "mesh_scene.gltf").resolve()
    errs = _validate(rd, gltf_p)
    if errs:
        for e in errs:
            print(e)
        return 1
    print(f"OK {gltf_p.name} matches submeshes under {rd / 'submeshes'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
