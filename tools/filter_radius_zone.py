#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Build a radius-zone package: placements, asset list, and zone manifest for UE populate."""

from __future__ import annotations

import argparse
import json
import math
import re
import sys
from pathlib import Path
from typing import Any

_REPO = Path(__file__).resolve().parents[1]
if str(_REPO / "tools") not in sys.path:
    sys.path.insert(0, str(_REPO / "tools"))

from c3_cell_grid import (  # noqa: E402
    CELL_ID_BASE,
    CELL_SIZE_X,
    CELL_SIZE_Z,
    GRID_COLS,
    WORLD_MIN_X,
    WORLD_MIN_Z,
    cell_id_to_world_xyz,
    is_c3_block_stem,
    parse_cell_ids_from_stem,
)

_STEM_RE = re.compile(r"(\d+_blocks__VZ__[^\s/]+\.block)", re.IGNORECASE)
_HERO_STEM_RE = re.compile(
    r"(pmcoutpost_[a-z0-9_]+|resident[_-]pmcoutpost[a-z0-9_]*)",
    re.IGNORECASE,
)
_BLD_TOKEN_RE = re.compile(r"bld_[a-z0-9_]+", re.IGNORECASE)


def _load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def _write_json(path: Path, obj: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(obj, indent=2), encoding="utf-8")


def _placement_xyz(p: dict) -> tuple[float, float, float] | None:
    pos = p.get("position")
    if isinstance(pos, dict):
        try:
            return float(pos["x"]), float(pos["y"]), float(pos["z"])
        except (KeyError, TypeError, ValueError):
            return None
    if "position_x" in p:
        return (
            float(p.get("position_x", 0.0)),
            float(p.get("position_y", 0.0)),
            float(p.get("position_z", 0.0)),
        )
    return None


def _in_zone(
    p: dict,
    cx: float,
    cy: float,
    cz: float,
    radius: float,
    y_half: float,
) -> bool:
    xyz = _placement_xyz(p)
    if xyz is None:
        return False
    x, y, z = xyz
    if math.hypot(x - cx, z - cz) > radius:
        return False
    if abs(y - cy) > y_half:
        return False
    return True


def _stem_from_source(source: str) -> str | None:
    if not source:
        return None
    m = _STEM_RE.search(source.replace("\\", "/"))
    return m.group(1).lower() if m else None


def _canonical_stem(stem: str) -> str:
    s = stem.lower().replace(".block", "")
    return re.sub(r"^\d+_blocks__vz__", "", s)


def _hero_canon_from_stem(stem: str) -> str | None:
    m = _HERO_STEM_RE.search(stem)
    if not m:
        return None
    raw = m.group(1).lower()
    bld = _BLD_TOKEN_RE.search(raw)
    if bld:
        canon = raw.split("_p")[0] if "_p" in raw else raw
        if canon in ("pmcoutpost_bld", "pmcoutpost") or canon.endswith("_bld"):
            return None
        return canon
    canon = re.sub(r"_p\d+_q\d+$", "", raw)
    if canon in ("pmcoutpost_bld", "pmcoutpost"):
        return None
    return canon


def _find_anchor(
    placements: list[dict],
    *,
    entity_id: str | None,
    entity_name: str | None,
) -> tuple[dict, float, float, float]:
    if entity_id:
        for p in placements:
            if str(p.get("entity_id", "")).lower() == entity_id.lower():
                xyz = _placement_xyz(p)
                if xyz:
                    return p, xyz[0], xyz[1], xyz[2]
    if entity_name:
        name_l = entity_name.lower().lstrip("_")
        for p in placements:
            en = (p.get("entity_name") or "").lower().lstrip("_")
            if en == name_l:
                xyz = _placement_xyz(p)
                if xyz:
                    return p, xyz[0], xyz[1], xyz[2]
    raise SystemExit(
        f"error: anchor not found (entity_id={entity_id!r}, entity_name={entity_name!r})"
    )


def _merge_placements(
    layers_static: list[dict],
    vz_state: list[dict],
    cx: float,
    cy: float,
    cz: float,
    radius: float,
    y_half: float,
) -> list[dict]:
    """Dedupe by entity_id; prefer layers_static (named) over vz_state."""
    by_id: dict[str, dict] = {}
    order: list[str] = []

    def _add(p: dict, block_type: str) -> None:
        if not _in_zone(p, cx, cy, cz, radius, y_half):
            return
        eid = str(p.get("entity_id", ""))
        if not eid:
            return
        q = dict(p)
        q.setdefault("block_type", block_type)
        if eid not in by_id:
            order.append(eid)
            by_id[eid] = q
            return
        prev = by_id[eid]
        if not prev.get("entity_name") and q.get("entity_name"):
            by_id[eid] = q

    for p in layers_static:
        _add(p, "layers_static")
    for p in vz_state:
        _add(p, "vz_state")

    return [by_id[eid] for eid in order]


def _c3_cell_ids_near(cx: float, cz: float, radius: float) -> list[int]:
    """Cell IDs whose centre lies within *radius* plus one cell half-width."""
    margin = max(CELL_SIZE_X, CELL_SIZE_Z) * 0.6
    limit = radius + margin
    out: list[int] = []
    for cell_id in range(CELL_ID_BASE, CELL_ID_BASE + GRID_COLS * GRID_COLS):
        x, _, z = cell_id_to_world_xyz(cell_id)
        if math.hypot(x - cx, z - cz) <= limit:
            out.append(cell_id)
    return out


def _asset_matches_zone(
    stem: str,
    source_stems: set[str],
    hero_canons: set[str],
    cell_ids: set[int],
) -> bool:
    stem_l = stem.lower()
    can = _canonical_stem(stem_l)
    if stem_l in source_stems or can in source_stems:
        return True
    for cid in cell_ids:
        tag = f"c3{cid - CELL_ID_BASE:04d}"
        if tag in stem_l:
            return True
    if is_c3_block_stem(stem_l):
        for cid in parse_cell_ids_from_stem(stem_l):
            if cid in cell_ids:
                return True
    hc = _hero_canon_from_stem(stem_l)
    if hc and hc in hero_canons:
        return True
    for hero in hero_canons:
        if hero in can or hero in stem_l:
            return True
    return False


def _hero_canons_from_placements(placements: list[dict]) -> set[str]:
    sys_path = str(_REPO / "game-scripts")
    if sys_path not in sys.path:
        sys.path.insert(0, sys_path)
    from mercs2_hero_placement import entity_matches_hero_canonical

    known: set[str] = set()
    for p in placements:
        ent = (p.get("entity_name") or "").lower().lstrip("_")
        if not ent:
            continue
        m = _HERO_STEM_RE.search(ent)
        if m:
            known.add(m.group(1).lower())
        bld = _BLD_TOKEN_RE.search(ent)
        if bld and "pmcoutpost" in ent:
            known.add(ent.split("_p")[0] if "_p" in ent else ent)

    canons: set[str] = set()
    for p in placements:
        ent = p.get("entity_name") or ""
        for c in sorted(known, key=len, reverse=True):
            if entity_matches_hero_canonical(ent, c):
                canons.add(c)
    return {c for c in canons if c not in ("pmcoutpost_bld", "pmcoutpost")}


def _find_c3_cell_review_dirs(
    cell_ids: set[int],
    review_root: Path,
) -> list[str]:
    """Find review block directory paths for c3 cell IDs.

    Returns paths relative to ``review_root`` for cells that exist on disk.
    Cell IDs are full IDs (e.g. 33883 = 30000 + stem_number).
    """
    batch = review_root / "batch_vz"
    if not batch.is_dir():
        return []

    import re as _re

    target_tags: set[str] = set()
    for cid in cell_ids:
        tag = f"c3{cid - 30000:04d}"
        target_tags.add(tag)

    found: list[str] = []
    for d in sorted(batch.iterdir()):
        if not d.is_dir():
            continue
        dl = d.name.lower()
        for tag in target_tags:
            if tag in dl and "_p000_" in dl:
                idx = d / "submeshes" / "index.json"
                if idx.is_file():
                    found.append(f"batch_vz/{d.name}")
                break
    return found


def main() -> int:
    ap = argparse.ArgumentParser(description="Filter placements + assets to a radius zone")
    ap.add_argument("--anchor-entity-id", default="0x000a3b30")
    ap.add_argument("--anchor-entity-name", default="_pmcoutpost_bld_pool")
    ap.add_argument("--radius", type=float, default=200.0)
    ap.add_argument(
        "--y-half",
        type=float,
        default=None,
        help="Vertical half-extent (default: same as --radius)",
    )
    ap.add_argument("--zone-id", default="pool_200m")
    ap.add_argument("--output", type=Path, default=Path("output"))
    ap.add_argument(
        "--layers-static",
        type=Path,
        default=None,
        help="Default: OUTPUT/placements/layers_static.json",
    )
    ap.add_argument(
        "--vz-state",
        type=Path,
        default=None,
        help="Default: OUTPUT/placements/vz_state/all_vz_state.json",
    )
    ap.add_argument(
        "--manifest",
        type=Path,
        default=None,
        help="Default: OUTPUT/ue5_import/metadata/manifest.json",
    )
    ap.add_argument(
        "--review-root",
        type=Path,
        default=None,
        help="Extraction review root (default: OUTPUT/extracted/review). "
        "Used to locate c3 cell review directories.",
    )
    args = ap.parse_args()

    y_half = args.y_half if args.y_half is not None else args.radius
    out_root = args.output / "radius_zones" / args.zone_id
    layers_path = args.layers_static or (args.output / "placements/layers_static.json")
    vz_path = args.vz_state or (args.output / "placements/vz_state/all_vz_state.json")
    manifest_path = args.manifest or (args.output / "ue5_import/metadata/manifest.json")

    for p, label in ((layers_path, "layers_static"), (manifest_path, "manifest")):
        if not p.is_file():
            print(f"error: missing {label}: {p}", file=sys.stderr)
            return 1

    ls_doc = _load_json(layers_path)
    ls_pl = ls_doc if isinstance(ls_doc, list) else ls_doc.get("placements", [])

    vz_pl: list[dict] = []
    if vz_path.is_file():
        vz_doc = _load_json(vz_path)
        vz_pl = vz_doc if isinstance(vz_doc, list) else vz_doc.get("placements", [])

    anchor_rec, cx, cy, cz = _find_anchor(
        ls_pl + vz_pl,
        entity_id=args.anchor_entity_id,
        entity_name=args.anchor_entity_name,
    )

    merged = _merge_placements(ls_pl, vz_pl, cx, cy, cz, args.radius, y_half)
    source_stems = {_stem_from_source(str(p.get("source", ""))) for p in merged}
    source_stems.discard(None)

    cell_ids = set(_c3_cell_ids_near(cx, cz, args.radius))
    hero_canons = _hero_canons_from_placements(merged)

    manifest = _load_json(manifest_path)
    assets_in = manifest.get("assets", [])
    out_assets: list[dict[str, Any]] = []
    for a in assets_in:
        if a.get("pack") != "batch_vz":
            continue
        stem = a.get("stem", "")
        if _asset_matches_zone(stem, source_stems, hero_canons, cell_ids):
            out_assets.append(a)

    for a in out_assets:
        hc = _hero_canon_from_stem(a.get("stem", ""))
        if hc:
            hero_canons.add(hc)

    vz_sources = sorted(
        {
            str(p.get("source"))
            for p in merged
            if p.get("source") and "layers_static" not in str(p.get("source")).lower()
        }
    )
    streaming = {
        "groups": [
            {
                "group_id": f"{args.zone_id}_base",
                "description": "layers_static in radius zone — visible",
                "default_visible": True,
            },
            {
                "group_id": f"{args.zone_id}_vz_overlays",
                "description": "vz_state sources in zone — mission overlays hidden by default",
                "default_visible": False,
                "sources": vz_sources,
            },
        ],
        "bbox_game_units": {
            "min": {"x": cx - args.radius, "y": cy - y_half, "z": cz - args.radius},
            "max": {"x": cx + args.radius, "y": cy + y_half, "z": cz + args.radius},
        },
    }

    placements_path = out_root / "placements.json"
    asset_list_path = out_root / "asset_list.json"
    streaming_path = out_root / "streaming_groups.json"
    zone_path = out_root / "zone.json"

    _write_json(placements_path, merged)
    _write_json(
        asset_list_path,
        {
            "description": f"Radius zone {args.zone_id} — assets overlapping {args.radius}m cylinder",
            "zone_id": args.zone_id,
            "asset_count": len(out_assets),
            "assets": out_assets,
        },
    )
    _write_json(streaming_path, streaming)

    col_i = int((cx - WORLD_MIN_X) / CELL_SIZE_X)
    row_i = int((cz - WORLD_MIN_Z) / CELL_SIZE_Z)
    primary_cell = CELL_ID_BASE + row_i * GRID_COLS + col_i

    review_root = (args.review_root or (args.output / "extracted/review")).resolve()
    c3_review_dirs = _find_c3_cell_review_dirs(cell_ids, review_root)

    # Also find review dirs for hero/compound blocks listed in out_assets
    hero_review_dirs: list[str] = []
    batch = review_root / "batch_vz"
    if batch.is_dir():
        for a in out_assets:
            stem = a.get("stem", "")
            if not stem:
                continue
            candidate = batch / stem
            idx = candidate / "submeshes" / "index.json"
            if candidate.is_dir() and idx.is_file():
                hero_review_dirs.append(f"batch_vz/{stem}")

    zone_doc = {
        "zone_id": args.zone_id,
        "description": f"{args.radius}m cylinder around {args.anchor_entity_name}",
        "anchor_entity_id": args.anchor_entity_id,
        "anchor_entity_name": anchor_rec.get("entity_name") or args.anchor_entity_name,
        "anchor_position": {"x": cx, "y": cy, "z": cz},
        "radius_m": args.radius,
        "y_half_extent_m": y_half,
        "placement_count": len(merged),
        "asset_count": len(out_assets),
        "hero_canonicals": sorted(hero_canons),
        "c3_cell_ids": sorted(cell_ids),
        "primary_cell_id": primary_cell,
        "c3_review_dirs": c3_review_dirs,
        "hero_review_dirs": hero_review_dirs,
        "paths": {
            "placements": str(placements_path.relative_to(args.output)),
            "asset_list": str(asset_list_path.relative_to(args.output)),
            "streaming_groups": str(streaming_path.relative_to(args.output)),
        },
        "ue_mesh_root": "/Game/Mercs2/Meshes/RadiusZones/" + args.zone_id.replace("-", "_"),
        "ue_data_layer_dir": "/Game/Mercs2/DataLayers/RadiusZones",
    }
    _write_json(zone_path, zone_doc)

    print(
        f"Wrote zone {args.zone_id}: {len(merged)} placements, {len(out_assets)} assets, "
        f"{len(cell_ids)} c3 cells, {len(hero_canons)} hero meshes, "
        f"{len(c3_review_dirs)} c3 review dirs, {len(hero_review_dirs)} hero review dirs → {out_root}",
        flush=True,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
