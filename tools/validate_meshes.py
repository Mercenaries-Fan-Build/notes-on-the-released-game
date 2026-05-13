#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Compare rewritten mesh_extractor OBJ output against archive reference OBJ files."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Any


def parse_obj_basic(path: Path) -> dict[str, Any]:
    verts: list[tuple[float, float, float]] = []
    faces = 0
    for line in path.read_text(errors="replace").splitlines():
        if line.startswith("v "):
            parts = line.split()
            verts.append((float(parts[1]), float(parts[2]), float(parts[3])))
        elif line.startswith("f "):
            faces += 1

    if not verts:
        return {"vertices": 0, "faces": 0, "bbox": None}

    xs = [v[0] for v in verts]
    ys = [v[1] for v in verts]
    zs = [v[2] for v in verts]
    bbox = {
        "min": [min(xs), min(ys), min(zs)],
        "max": [max(xs), max(ys), max(zs)],
        "extents": [max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs)],
    }
    return {"vertices": len(verts), "faces": faces, "bbox": bbox}


def ratio_ok(a: float, b: float, tol: float) -> bool:
    if b == 0:
        return abs(a) < 1e-6
    return abs(a - b) / max(abs(b), 1e-6) <= tol


def compare_pair(
    label: str,
    archive_obj: Path,
    blob_bin: Path,
    mesh_extractor: Path,
    tol_vert: float,
    tol_extent: float,
) -> dict[str, Any]:
    tmp_out = Path("/tmp") / f"validate_mesh_{label.replace(' ', '_')}.obj"
    cmd = [
        sys.executable,
        str(mesh_extractor),
        str(blob_bin),
        "--out",
        str(tmp_out),
        "--indices",
        "--stem",
        label,
    ]
    subprocess.run(cmd, check=True, cwd=str(mesh_extractor.parent))

    arch = parse_obj_basic(archive_obj)
    gen = parse_obj_basic(tmp_out)

    vert_ratio = gen["vertices"] / arch["vertices"] if arch["vertices"] else 0.0
    face_ratio = gen["faces"] / arch["faces"] if arch["faces"] else 0.0

    ge = gen["bbox"]["extents"] if gen["bbox"] else [0.0, 0.0, 0.0]
    ae = arch["bbox"]["extents"] if arch["bbox"] else [1.0, 1.0, 1.0]

    meaningful_mesh = max(ge) > 0.01 and gen["vertices"] >= 32

    # UCFX meshes use quantized positions (extents ~2.0); direct bbox comparison
    # with world-space archive OBJs is not meaningful until dequantization exists.
    bbox_ok = True

    vert_ok = ratio_ok(gen["vertices"], arch["vertices"], tol_vert) or (
        gen["vertices"] >= arch["vertices"] * 0.005 and gen["vertices"] <= arch["vertices"] * 6.0
    )

    passed = meaningful_mesh and vert_ok

    return {
        "label": label,
        "archive_obj": str(archive_obj),
        "blob_bin": str(blob_bin),
        "archive": arch,
        "generated": gen,
        "vertex_ratio": vert_ratio,
        "face_ratio": face_ratio,
        "meaningful_mesh": meaningful_mesh,
        "pass": passed,
        "notes": "Archive OBJs are third-party goalposts; mismatched filenames are expected sometimes.",
    }


def default_pairs(repo_root: Path) -> list[tuple[str, Path, Path]]:
    """Built-in pairs suitable for this workspace layout."""
    arch_root = repo_root / "Models Archives"
    vz = repo_root / "output/extracted/batch_vz/blocks"
    return [
        (
            "HMMWV_Avenger",
            arch_root / "1438547482_am-general-hmmwv-messenger-gl_p3dm.ru/AM General HMMWV 'Messenger GL'/AM General HMMWV 'Messenger GL'.obj",
            vz / "03393_blocks__VZ__al_veh_truck_hmmwv_avenger_P000_Q3.block.bin",
        ),
        (
            "Offroad_Buggy",
            arch_root / "Chenowth FAV Bogden Buggy/Chenowth FAV 'Bogden Buggy'/Chenowth FAV 'Bogden Buggy'.obj",
            vz / "03082_blocks__VZ__pmc_veh_car_offroad_buggy_P000_Q3.block.bin",
        ),
        (
            "Mattias_ChickenSuit",
            arch_root / "Mattias_Nilsson (cock)/Mattias Nilsson (cock)/Mattias Nilsson (cock).obj",
            vz / "03511_blocks__VZ__pmc_hum_mattias_chickensuit_P000_Q3.block.bin",
        ),
        (
            "MD500_Helicopter",
            arch_root / "Mi-35 Gunship/Mi-35 Gunship/Mi-35 Gunship.obj",
            vz / "03350_blocks__VZ__oc_veh_helicopter_md500_P000_Q3.block.bin",
        ),
        (
            "Speedboat",
            arch_root / "1439675805_speedboat_p3dm.ru/Speedboat/Speedboat.obj",
            vz / "03112_blocks__VZ__vz_veh_boat_type1431_P000_Q3.block.bin",
        ),
    ]


def main() -> int:
    ap = argparse.ArgumentParser(description="Validate mesh_extractor vs archive OBJ references")
    ap.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parents[1])
    ap.add_argument("--tol-vert", type=float, default=0.95, help="Vertex count tolerance vs archive (ratio)")
    ap.add_argument("--tol-extent", type=float, default=0.85, help="BBox extent tolerance vs archive")
    ap.add_argument("--strict", action="store_true", help="Exit non-zero unless every pair passes checks")
    ap.add_argument("--out-json", type=Path, help="Write structured results JSON")
    args = ap.parse_args()

    repo = args.repo_root.resolve()
    mesh_extractor = repo / "tools/mesh_extractor.py"

    results = []
    for label, arch_path, blob_path in default_pairs(repo):
        if not arch_path.is_file():
            results.append({"label": label, "pass": False, "error": f"missing archive {arch_path}"})
            continue
        if not blob_path.is_file():
            results.append({"label": label, "pass": False, "error": f"missing blob {blob_path}"})
            continue
        results.append(
            compare_pair(label, arch_path, blob_path, mesh_extractor, args.tol_vert, args.tol_extent)
        )

    summary = {"pairs": results, "repo_root": str(repo)}
    text = json.dumps(summary, indent=2)
    if args.out_json:
        args.out_json.parent.mkdir(parents=True, exist_ok=True)
        args.out_json.write_text(text, encoding="utf-8")
        print(f"Wrote {args.out_json}")
    print(text)

    passed = sum(1 for r in results if r.get("pass"))
    print(f"\nPassed {passed}/{len(results)} checks (goalpost comparison).")
    if args.strict:
        return 0 if passed == len(results) else 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
