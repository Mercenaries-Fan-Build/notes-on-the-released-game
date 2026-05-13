#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Filter the full ue5_import manifest down to the Maracaibo demo subset.
Outputs maracaibo_asset_list.json with categorized assets for UE5 import.
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any

MARACAIBO_PATTERNS = [
    r"mar_city", r"mar_outskirt", r"mar_industrial", r"mar_village",
    r"mar_altagracia", r"mar_roads", r"mar_big_lineregion",
    r"maracaibo_bld", r"oc_depot", r"oil_fuel_mar",
]

BUILDING_PATTERNS = [
    r"city_bld_", r"commercial_bld_", r"white_bld_", r"caracas_bld_",
    r"bld_corner", r"bld_wall", r"bld_segment", r"bld_strip",
    r"bld_apartment", r"bld_storefront", r"bld_skyscraper",
    r"bld_firestation", r"bld_supermarket",
]

VEHICLE_PATTERNS = [
    r"civ_veh_", r"pmc_veh_", r"oc_veh_", r"al_veh_", r"ch_veh_",
    r"vz_veh_", r"global_veh_",
    r"veh_motorcycle", r"veh_semi", r"veh_helicopter",
    r"monstertruck", r"mattiaschopper",
]

ROAD_PATTERNS = [
    r"road\d+", r"sidewalk_road", r"whiteroads", r"jungleroad",
    r"outskirtroad", r"residentialroad", r"commercialroad",
]

ENVIRONMENT_PATTERNS = [
    r"terrain", r"tree_", r"palm_", r"bush_", r"fence_",
    r"sign_", r"lamp_", r"light_", r"prop_",
]

WORLD_LAYER_PATTERNS = [
    r"vz_state_mar_", r"vz_state_oc_", r"vz_state_car_city",
    r"vz_state_oil_fuel_mar",
]

MIN_VERTICES = 8


def categorize(stem: str) -> str | None:
    s = stem.lower()
    for p in WORLD_LAYER_PATTERNS:
        if re.search(p, s):
            return "world_layer"
    for p in MARACAIBO_PATTERNS:
        if re.search(p, s):
            return "maracaibo"
    for p in BUILDING_PATTERNS:
        if re.search(p, s):
            return "building"
    for p in VEHICLE_PATTERNS:
        if re.search(p, s):
            return "vehicle"
    for p in ROAD_PATTERNS:
        if re.search(p, s):
            return "road"
    for p in ENVIRONMENT_PATTERNS:
        if re.search(p, s):
            return "environment"
    return None


def load_mesh_meta(review_root: Path, pack: str, stem: str) -> dict[str, Any]:
    for candidate in [
        review_root / pack / stem / "mesh.meta.json",
    ]:
        if candidate.is_file():
            return json.loads(candidate.read_text(encoding="utf-8"))
    return {}


def main() -> int:
    ap = argparse.ArgumentParser(description="Filter assets for Maracaibo demo")
    ap.add_argument("--manifest", type=Path, required=True, help="ue5_import/metadata/manifest.json")
    ap.add_argument("--review-root", type=Path, help="extracted/review/ root (for mesh.meta.json)")
    ap.add_argument("--min-verts", type=int, default=MIN_VERTICES, help="Minimum vertex count to include")
    ap.add_argument("--out", type=Path, required=True, help="Output maracaibo_asset_list.json")
    args = ap.parse_args()

    manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
    assets = manifest.get("assets", [])

    review_root = args.review_root
    if review_root is None:
        pr = Path(manifest.get("pipeline_root", "."))
        for cand in [pr / "extracted" / "review", pr / "review"]:
            if cand.is_dir():
                review_root = cand
                break

    results: dict[str, list[dict[str, Any]]] = {
        "world_layer": [],
        "maracaibo": [],
        "building": [],
        "vehicle": [],
        "road": [],
        "environment": [],
    }
    skipped_low_verts = 0

    for a in assets:
        stem = a.get("stem", "")
        cat = categorize(stem)
        if cat is None:
            continue

        meta = {}
        if review_root:
            meta = load_mesh_meta(review_root, a.get("pack", ""), stem)

        verts = meta.get("vertices", 0)
        if verts < args.min_verts and cat not in ("world_layer",):
            skipped_low_verts += 1
            continue

        entry = {
            **a,
            "category": cat,
            "vertices": verts,
            "faces": meta.get("faces", 0),
            "topology": meta.get("topology", "unknown"),
        }
        results[cat].append(entry)

    for cat in results:
        results[cat].sort(key=lambda x: -x.get("vertices", 0))

    total = sum(len(v) for v in results.values())
    summary = {
        "total_filtered": total,
        "skipped_low_verts": skipped_low_verts,
        "min_verts_threshold": args.min_verts,
        "by_category": {k: len(v) for k, v in results.items()},
        "assets": results,
    }

    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(f"Filtered {total} Maracaibo assets (skipped {skipped_low_verts} low-vert)")
    for cat, items in results.items():
        if items:
            print(f"  {cat}: {len(items)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
