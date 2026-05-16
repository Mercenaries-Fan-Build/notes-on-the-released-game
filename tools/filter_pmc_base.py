#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Filter manifests + placements to the PMC base testbed subset."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any


def _load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def _write_json(path: Path, obj: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(obj, indent=2), encoding="utf-8")


def _canonical_vz_stem(stem: str) -> str:
    s = stem.lower().replace(".block", "")
    return re.sub(r"^\d+_blocks__vz__", "", s)


def _in_bbox(p: dict, bbox: dict[str, dict[str, float]]) -> bool:
    pos = p.get("position") or {}
    try:
        x = float(pos["x"])
        y = float(pos["y"])
        z = float(pos["z"])
    except (KeyError, TypeError, ValueError):
        return False
    lo = bbox["min"]
    hi = bbox["max"]
    return lo["x"] <= x <= hi["x"] and lo["y"] <= y <= hi["y"] and lo["z"] <= z <= hi["z"]


def _asset_matches_stems(stem: str, stems: set[str]) -> bool:
    can = _canonical_vz_stem(stem)
    if can in stems:
        return True
    for s in stems:
        if len(s) < 8:
            continue
        if s in can or can in s:
            return True
    return False


def main() -> int:
    ap = argparse.ArgumentParser(description="Build PMC base asset list + placements + streaming groups")
    ap.add_argument("--pmc-set", type=Path, default=Path("output/pmc_base_block_set.json"))
    ap.add_argument("--manifest", type=Path, default=Path("output/ue5_import/metadata/manifest.json"))
    ap.add_argument("--layers-static", type=Path, default=Path("output/placements/layers_static.json"))
    ap.add_argument("--vz-state", type=Path, default=Path("output/placements/vz_state/all_vz_state.json"))
    ap.add_argument("--out-assets", type=Path, default=Path("output/pmc_base_asset_list.json"))
    ap.add_argument("--out-placements", type=Path, default=Path("output/placements/pmc_base.json"))
    ap.add_argument("--out-streaming", type=Path, default=Path("output/pmc_base_streaming_groups.json"))
    args = ap.parse_args()

    pmc = _load_json(args.pmc_set)
    stems: set[str] = {s.lower() for s in pmc.get("block_stems", [])}
    bbox = pmc.get("bbox_game_units") or {}

    manifest = _load_json(args.manifest)
    assets_in = manifest.get("assets", [])
    out_assets: list[dict[str, Any]] = []
    for a in assets_in:
        if a.get("pack") != "batch_vz":
            continue
        stem = a.get("stem", "")
        if _asset_matches_stems(stem, stems):
            out_assets.append(a)

    ls_doc = _load_json(args.layers_static)
    ls_pl = ls_doc if isinstance(ls_doc, list) else ls_doc.get("placements", [])
    vz_doc = _load_json(args.vz_state)
    vz_pl = vz_doc if isinstance(vz_doc, list) else vz_doc.get("placements", [])

    name_pat = re.compile(r"pmcoutpost|vz_state_pmc|pmc_interior|pmcinterior|pmccon\d", re.I)

    out_ls: list[dict] = []
    for p in ls_pl:
        if bbox and _in_bbox(p, bbox):
            out_ls.append(p)
            continue
        en = p.get("entity_name") or ""
        if name_pat.search(en):
            out_ls.append(p)

    out_vz: list[dict] = []
    for p in vz_pl:
        src = (p.get("source") or "").lower()
        if "pmc" in src:
            out_vz.append(p)

    merged: list[dict] = []
    for p in out_ls:
        q = dict(p)
        q.setdefault("block_type", "layers_static")
        merged.append(q)
    for p in out_vz:
        q = dict(p)
        q.setdefault("block_type", "vz_state")
        merged.append(q)

    interior_sources = sorted(
        {p.get("source") for p in out_vz if "pmcinterior" in (p.get("source") or "").lower()},
    )
    groups = [
        {
            "group_id": "pmc_world_base",
            "description": "HQ bbox + PMC-named layers_static; default visible",
            "default_visible": True,
        },
        {
            "group_id": "pmc_interior_variants",
            "description": "vz_state_pmcinterior_* — default hidden in editor",
            "default_visible": False,
            "vz_state_sources": [s for s in interior_sources if s],
        },
    ]

    _write_json(
        args.out_assets,
        {
            "description": "PMC base subset from pmc_base_block_set + ue5_import manifest",
            "asset_count": len(out_assets),
            "assets": out_assets,
        },
    )
    _write_json(args.out_placements, merged)
    _write_json(args.out_streaming, {"groups": groups, "bbox_game_units": bbox})

    print(
        f"Wrote {args.out_assets} ({len(out_assets)} assets), "
        f"{args.out_placements} ({len(merged)} placements), {args.out_streaming}",
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
