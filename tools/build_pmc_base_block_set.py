#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Build `output/pmc_base_block_set.json` — PMC testbed block inventory + bbox.

Uses retail `ffcs_vz/paths.txt` and optional `layers_static` placement JSON.
See plan: PMC base streaming pipeline (Phase 0).
"""

from __future__ import annotations

import argparse
import json
import math
from pathlib import Path


def _load_placements(path: Path) -> list[dict]:
    if not path.is_file():
        return []
    data = json.loads(path.read_text(encoding="utf-8"))
    if isinstance(data, list):
        return data
    return list(data.get("placements", []))


def _hq_anchor(placements: list[dict]) -> tuple[float, float, float] | None:
    """Prefer `_pmcoutpost_bld_hq_stitch` anchor (verified in retail JSON)."""
    for p in placements:
        en = (p.get("entity_name") or "").lower()
        if "pmcoutpost" in en and "hq_stitch" in en:
            pos = p.get("position") or {}
            return float(pos["x"]), float(pos["y"]), float(pos["z"])
    return None


def _bbox_from_cylinder(
    placements: list[dict],
    cx: float,
    cy: float,
    cz: float,
    radius: float,
    y_half: float,
) -> dict[str, dict[str, float]]:
    xs: list[float] = []
    ys: list[float] = []
    zs: list[float] = []
    for p in placements:
        pos = p.get("position") or {}
        px = float(pos.get("x", 0.0))
        py = float(pos.get("y", 0.0))
        pz = float(pos.get("z", 0.0))
        if math.hypot(px - cx, pz - cz) > radius:
            continue
        if abs(py - cy) > y_half:
            continue
        xs.append(px)
        ys.append(py)
        zs.append(pz)
    if not xs:
        return {
            "min": {"x": cx - radius, "y": cy - y_half, "z": cz - radius},
            "max": {"x": cx + radius, "y": cy + y_half, "z": cz + radius},
        }
    return {
        "min": {"x": min(xs), "y": min(ys), "z": min(zs)},
        "max": {"x": max(xs), "y": max(ys), "z": max(zs)},
    }


def _path_matches_pmc(line: str) -> bool:
    s = line.replace("\\", "/").lower()
    patterns = (
        "pmcoutpost",
        "vz_state_pmc",
        "pmc_interior",
        "pmcinterior",
        "resident-pmcoutpost",
        "pmccon",
        "_pmc_",
        "/pmc/",
    )
    return any(p in s for p in patterns)


def _stem_from_path(line: str) -> str:
    s = line.replace("\\", "/")
    base = s.rsplit("/", 1)[-1]
    return base.replace(".block", "").strip()


def main() -> int:
    ap = argparse.ArgumentParser(description="Build PMC base block set JSON")
    ap.add_argument(
        "--ffcs-paths",
        type=Path,
        default=Path("output/extracted/ffcs_vz/paths.txt"),
        help="Retail ffcs_vz paths.txt",
    )
    ap.add_argument(
        "--layers-static",
        type=Path,
        default=Path("output/placements/layers_static.json"),
        help="layers_static placements JSON (optional)",
    )
    ap.add_argument(
        "--out",
        type=Path,
        default=Path("output/pmc_base_block_set.json"),
    )
    ap.add_argument("--cylinder-radius", type=float, default=450.0)
    ap.add_argument("--cylinder-y-half", type=float, default=120.0)
    args = ap.parse_args()

    if not args.ffcs_paths.is_file():
        print(f"error: missing {args.ffcs_paths}", flush=True)
        return 1

    paths_raw = args.ffcs_paths.read_text(encoding="utf-8", errors="replace").splitlines()
    path_hits = [ln for ln in paths_raw if _path_matches_pmc(ln)]
    stems = sorted({_stem_from_path(ln) for ln in path_hits})

    placements = _load_placements(args.layers_static)
    anchor = _hq_anchor(placements)
    if anchor is None:
        print("error: could not find _pmcoutpost_bld_hq_stitch in placements data", flush=True)
        return 1
    cx, cy, cz = anchor
    bbox = _bbox_from_cylinder(placements, cx, cy, cz, args.cylinder_radius, args.cylinder_y_half)

    sub_blocks: set[int] = set()
    for p in placements:
        pos = p.get("position") or {}
        px = float(pos.get("x", 0.0))
        py = float(pos.get("y", 0.0))
        pz = float(pos.get("z", 0.0))
        if math.hypot(px - cx, pz - cz) > args.cylinder_radius:
            continue
        if abs(py - cy) > args.cylinder_y_half:
            continue
        sb = p.get("sub_block")
        if isinstance(sb, int):
            sub_blocks.add(sb)

    # Always include global layers used by PMC streaming / scripts
    extra_stems = {
        "layers_static_P000_Q3",
        "vz_base_P000_Q3",
        "scripts_vz_P000_Q3",
    }
    stems_set = set(stems) | extra_stems

    doc = {
        "description": "PMC base testbed — path stems + HQ-centered bbox + layers_static sub_blocks",
        "anchor_entity": "_pmcoutpost_bld_hq_stitch",
        "anchor_position": {"x": cx, "y": cy, "z": cz},
        "cylinder": {
            "radius_game_units": args.cylinder_radius,
            "y_half_extent": args.cylinder_y_half,
        },
        "bbox_game_units": bbox,
        "paths_txt": str(args.ffcs_paths),
        "path_line_count_pmc_related": len(path_hits),
        "block_stems": sorted(stems_set),
        "layers_static_sub_blocks_in_bbox": sorted(sub_blocks),
    }
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(doc, indent=2), encoding="utf-8")
    print(f"Wrote {args.out} ({len(doc['block_stems'])} stems, {len(sub_blocks)} sub_blocks)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
