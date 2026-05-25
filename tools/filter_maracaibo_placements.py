#!/usr/bin/env python3
"""
Filter extracted placements to the Maracaibo demo area.

layers_static: positions only — include records inside the geographic bbox.

vz_state: filenames encode region/mission. Require BOTH a Maracaibo-related
source keyword AND position inside the bbox (no bbox-only inclusion for
non-Maracaibo missions — avoids Caracas / jungle leaks).

Usage:
    python3 tools/filter_maracaibo_placements.py \
        --layers-static output/placements/layers_static.json \
        --vz-state-dir  output/placements/vz_state/ \
        --out            output/placements/maracaibo_placements.json

BBox defaults are tighter than the old ±2000 box; override with --x-min etc.
"""

from __future__ import annotations

import argparse
import json
import os
import sys

# Tighter defaults than ±2000 (still tunable via CLI / placement preview export).
MARACAIBO_BBOX_DEFAULT = {
    "x_min": -1200.0,
    "x_max": 1400.0,
    "z_min": -1100.0,
    "z_max": 600.0,
    "y_min": -200.0,
    "y_max": 500.0,
}

MARACAIBO_SOURCE_KEYWORDS = [
    "mar_city",
    "mar_outskirt",
    "mar_industrial",
    "mar_village",
    "mar_altagracia",
    "mar_roads",
    "mar_big_lineregion",
    "maracaibo",
    "oc_depot",
    "oil_fuel_mar",
]


def is_in_bbox(pos: dict, bbox: dict) -> bool:
    x, y, z = pos.get("x", 0), pos.get("y", 0), pos.get("z", 0)
    return (
        bbox["x_min"] <= x <= bbox["x_max"]
        and bbox["z_min"] <= z <= bbox["z_max"]
        and bbox["y_min"] <= y <= bbox["y_max"]
    )


def source_matches_maracaibo(source: str) -> bool:
    if not source:
        return False
    src_lower = source.lower()
    return any(kw in src_lower for kw in MARACAIBO_SOURCE_KEYWORDS)


def load_placements_file(filepath: str) -> list[dict]:
    with open(filepath) as f:
        data = json.load(f)
    if isinstance(data, list):
        return data
    if isinstance(data, dict):
        return data.get("placements", [])
    return []


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Filter placements to the Maracaibo demo area",
    )
    parser.add_argument(
        "--layers-static",
        help="Path to layers_static.json placements file",
    )
    parser.add_argument(
        "--vz-state-dir",
        help="Path to directory of per-file vz_state placement JSONs",
    )
    parser.add_argument(
        "--out",
        "-o",
        required=True,
        help="Output JSON path for filtered Maracaibo placements",
    )
    parser.add_argument("--x-min", type=float, default=MARACAIBO_BBOX_DEFAULT["x_min"])
    parser.add_argument("--x-max", type=float, default=MARACAIBO_BBOX_DEFAULT["x_max"])
    parser.add_argument("--z-min", type=float, default=MARACAIBO_BBOX_DEFAULT["z_min"])
    parser.add_argument("--z-max", type=float, default=MARACAIBO_BBOX_DEFAULT["z_max"])
    parser.add_argument("--y-min", type=float, default=MARACAIBO_BBOX_DEFAULT["y_min"])
    parser.add_argument("--y-max", type=float, default=MARACAIBO_BBOX_DEFAULT["y_max"])
    args = parser.parse_args()

    bbox = {
        "x_min": args.x_min,
        "x_max": args.x_max,
        "z_min": args.z_min,
        "z_max": args.z_max,
        "y_min": args.y_min,
        "y_max": args.y_max,
    }

    all_placements: list[dict] = []

    if args.layers_static and os.path.isfile(args.layers_static):
        ls_placements = load_placements_file(args.layers_static)
        print(f"  layers_static: loaded {len(ls_placements)} placements", file=sys.stderr)
        all_placements.extend(ls_placements)
    elif args.layers_static:
        print(f"  WARNING: layers_static not found: {args.layers_static}", file=sys.stderr)

    if args.vz_state_dir and os.path.isdir(args.vz_state_dir):
        vz_count = 0
        for fname in sorted(os.listdir(args.vz_state_dir)):
            if not fname.endswith(".json"):
                continue
            fpath = os.path.join(args.vz_state_dir, fname)
            placements = load_placements_file(fpath)
            all_placements.extend(placements)
            vz_count += len(placements)
        print(f"  vz_state: loaded {vz_count} placements from {args.vz_state_dir}", file=sys.stderr)
    elif args.vz_state_dir:
        print(f"  WARNING: vz_state dir not found: {args.vz_state_dir}", file=sys.stderr)

    print(f"  Total input placements: {len(all_placements)}", file=sys.stderr)

    filtered: list[dict] = []
    ls_in_bbox = 0
    vz_strict = 0
    for p in all_placements:
        pos = p.get("position", {})
        in_bbox = is_in_bbox(pos, bbox)
        src = p.get("source", "")
        mar_src = source_matches_maracaibo(src)
        bt = p.get("block_type", "")

        include = False
        if bt == "layers_static":
            if in_bbox:
                include = True
                ls_in_bbox += 1
        elif bt == "vz_state":
            # Strict: Maracaibo-related file AND inside bbox.
            if mar_src and in_bbox:
                include = True
                vz_strict += 1
        else:
            if in_bbox and mar_src:
                include = True

        if include:
            filtered.append(p)

    result = {
        "total_placements": len(filtered),
        "layers_static_in_bbox": ls_in_bbox,
        "vz_state_maracaibo_source_and_bbox": vz_strict,
        "bbox": bbox,
        "placements": filtered,
    }

    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    with open(args.out, "w") as f:
        json.dump(result, f, indent=2, ensure_ascii=False)

    print(
        f"  Wrote {len(filtered)} Maracaibo placements to {args.out} "
        f"(layers_static bbox: {ls_in_bbox}, vz_state strict: {vz_strict})",
        file=sys.stderr,
    )


if __name__ == "__main__":
    main()
