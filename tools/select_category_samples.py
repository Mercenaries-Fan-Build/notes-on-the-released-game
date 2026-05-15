#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Pick one representative mesh per category from the UE5 export bundle.

Use this to build a tiny "broad coverage" subset (one taxi, one tank, one boat,
one apartment, one civilian, ...) for visual inspection or a UE5 import smoke
test, without dragging in all ~11k stage-2 assets.

Inputs (defaults assume the layout produced by tools/ue5_export.py):
  --bundle      output/ue5_import        master bundle root
  --review-root output/extracted/review  stage-2 review root (for mesh.meta.json)
  --categories  tools/categories.json    optional override (same schema as
                                          DEFAULT_CATEGORIES below)

Outputs:
  --out         output/ue5_import/category_samples.json  (always)
  --samples-bundle output/ue5_import_samples           (optional copy of
                                                          only the picked
                                                          assets, plus a
                                                          fresh master
                                                          manifest.json
                                                          ready for the UE5
                                                          import path)
  --viewer-base http://localhost:5173    optional; prefixes the deep-link
                                          URLs in the JSON

Selection per leaf category:
  - asset must have real geometry (vertices > 0 in mesh.meta.json)
  - rank by (vertices desc, mesh_group_count desc, has_mesh_scene_gltf desc)
  - --top N overrides the default of 1 pick per leaf
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
from pathlib import Path
from typing import Any


DEFAULT_CATEGORIES: list[tuple[str, list[str]]] = [
    # vehicles -- specific land vehicles first so "taxi" wins over generic "car"
    ("vehicle/land/taxi",         [r"\btaxi\b", r"_taxi(_|$)"]),
    ("vehicle/land/monstertruck", [r"monstertruck"]),
    ("vehicle/land/semi",         [r"_veh_semi(_|$)", r"\bsemi[_-]?truck"]),
    ("vehicle/land/van",          [r"_veh_van(_|$)", r"\bvan_", r"_van(_|$)"]),
    ("vehicle/land/truck",        [r"_veh_truck(_|$)", r"\btruck", r"pickup"]),
    ("vehicle/land/motorcycle",   [r"motorcycle", r"_veh_motorcycle", r"_veh_bike", r"\bbike(_|$)"]),
    ("vehicle/land/car",          [r"_veh_car(_|$)", r"civ_veh_car", r"sedan", r"compact", r"_veh_jeep"]),
    ("vehicle/armor/tank",        [r"_veh_tank(_|$)", r"\btank\b", r"abrams", r"_t72", r"_t80"]),
    ("vehicle/armor/apc",         [r"_veh_apc(_|$)", r"\bapc\b", r"\bbtr", r"_veh_ifv"]),
    ("vehicle/armor/mounted",     [r"mounted_weapon", r"\bturret", r"_veh_aaa"]),
    ("vehicle/air/helicopter",    [r"_veh_heli", r"helicopter", r"mattiaschopper", r"chopper", r"_veh_huey"]),
    ("vehicle/air/airplane",      [r"\bairplane", r"_veh_plane", r"_veh_jet", r"_aircraft"]),
    ("vehicle/water/boat",        [r"_veh_boat", r"\bboat_", r"boat_markv"]),
    ("vehicle/water/ship",        [r"\bship\b", r"freighter", r"barge", r"_veh_ship"]),
    ("vehicle/misc",              [r"_veh_", r"\bveh_"]),

    # characters / NPCs
    ("character/boss",            [r"mattias\b", r"\bfiona\b", r"\bewan\b", r"\bjp_", r"\bjen_",
                                   r"\brosa\b", r"\bboss_", r"\bcommander_"]),
    ("character/human/pmc",       [r"pmc_hum", r"_hum_pmc"]),
    ("character/human/civ",       [r"civ_hum", r"_hum_civ"]),
    ("character/human/al",        [r"al_hum",  r"_hum_al"]),
    ("character/human/ch",        [r"ch_hum",  r"_hum_ch"]),
    ("character/human/oc",        [r"oc_hum",  r"_hum_oc"]),
    ("character/human/gur",       [r"gur_hum", r"_hum_gur"]),
    ("character/human/pir",       [r"pir_hum", r"_hum_pir"]),
    ("character/human/misc",      [r"_hum_", r"\bhum_"]),

    # buildings -- specific shapes first, generic "_bld_" last
    ("building/skyscraper",       [r"skyscraper"]),
    ("building/apartment",        [r"apartment", r"_bld_apartment"]),
    ("building/storefront",       [r"storefront", r"_bld_storefront", r"supermarket"]),
    ("building/firestation",      [r"firestation"]),
    ("building/house",            [r"\bhouse\b", r"_house(_|$)", r"residential_bld"]),
    ("building/outpost",          [r"pmcoutpost_bld", r"oc_depot", r"_outpost_bld"]),
    ("building/industrial",       [r"industrial_bld", r"factory_bld", r"warehouse_bld",
                                   r"refinery", r"oil_fuel"]),
    ("building/commercial",       [r"commercial_bld", r"_bld_corner", r"_bld_strip"]),
    ("building/segment",          [r"_bld_wall", r"_bld_segment", r"_bld_section",
                                   r"_bld_facade", r"_bld_roof"]),
    ("building/misc",              [r"_bld_", r"\bbld_", r"_bld(_|$)",
                                    r"caracas_bld", r"merida_bld", r"mar_bld", r"maracaibo_bld"]),

    # props
    ("prop/barrier",              [r"concretebarrier", r"\bfence_", r"_fence(_|$)", r"\bbarrier"]),
    ("prop/lamp_sign",            [r"\blamp_", r"\bsign_", r"_streetlight", r"trafficlight"]),
    ("prop/vegetation",           [r"\btree_", r"\bpalm_", r"\bbush_", r"_vegetation"]),
    ("prop/container",            [r"_barrel", r"\bcrate_", r"_container(_|$)", r"_dumpster"]),
    ("prop/misc",                 [r"\bprop_"]),

    # weapons
    ("weapon",                    [r"\bwpn_", r"_wpn_", r"\bweapon", r"_rifle", r"_pistol"]),

    # world / terrain / roads
    ("road",                      [r"\broad\d", r"_road(_|$)", r"sidewalk_road",
                                   r"whiteroads", r"jungleroad", r"\broads?\b"]),
    ("terrain/heightfield",       [r"\bterrain", r"_heightfield"]),
    ("world/vz_state",            [r"\bvz_state"]),
    ("world/layer",               [r"layers_static", r"\bvz_layer", r"_lineregion"]),

    # ui / fonts / loaders -- usually no geometry, but kept so they are not "unknown"
    ("ui/font",                   [r"_font\b", r"font_glyphs", r"\bui_"]),
    ("ui/loader",                 [r"lti_precache", r"\bps3saveassets"]),
    ("ui/localization",           [r"^(english|french|german|italian|spanish|japanese|russian)$",
                                   r"^(english|french|german|italian|spanish|japanese|russian)_"]),
]


def _compile_categories(cat_table: list[tuple[str, list[str]]]) -> list[tuple[str, list[re.Pattern[str]]]]:
    return [(name, [re.compile(p, re.IGNORECASE) for p in pats]) for name, pats in cat_table]


def _strip_block_stem(stem: str) -> str:
    s = stem
    if s.lower().endswith(".block"):
        s = s[:-6]
    s = re.sub(r"_P\d+_Q\d+$", "", s, flags=re.I)
    s = re.sub(r"^\d+_", "", s)
    s = re.sub(r"(?i)^blocks__", "", s)
    s = s.replace("__", "_")
    return s


def categorize(stem: str, label_hint: str | None, compiled: list[tuple[str, list[re.Pattern[str]]]]) -> str:
    """Return the first matching leaf category, or 'unknown' if nothing fits."""
    s_clean = _strip_block_stem(stem or "").lower()
    candidates = [s_clean]
    if label_hint:
        candidates.append(label_hint.lower())
    for name, regs in compiled:
        for c in candidates:
            if not c:
                continue
            for r in regs:
                if r.search(c):
                    return name
    return "unknown"


def _load_master_manifest(bundle: Path) -> dict[str, Any]:
    p = bundle / "metadata" / "manifest.json"
    if not p.is_file():
        raise SystemExit(f"error: master manifest missing at {p} (run `make ue5-bundle` first)")
    return json.loads(p.read_text(encoding="utf-8"))


def _load_per_asset(bundle: Path, entry: dict[str, Any]) -> dict[str, Any]:
    bdir = bundle / str(entry["bundle_dir"])
    p = bdir / "manifest.json"
    if not p.is_file():
        return {}
    try:
        return json.loads(p.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}


def _review_dir(review_root: Path, pack: str, stem: str) -> Path:
    return review_root / pack / stem


def _load_mesh_meta(review_dir: Path) -> dict[str, Any]:
    p = review_dir / "mesh.meta.json"
    if not p.is_file():
        return {}
    try:
        return json.loads(p.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}


def _viewer_url(viewer_base: str | None, pack: str, stem: str, has_manifest: bool, has_gltf: bool) -> str | None:
    """Match viewer/vite-plugin-review-assets.js URL scheme."""
    if not viewer_base:
        return None
    base = viewer_base.rstrip("/")
    seg = lambda *xs: "/".join(re.sub(r"[^A-Za-z0-9._-]", lambda m: f"%{ord(m.group(0)):02X}", x) for x in xs)
    if has_manifest:
        return f"{base}/?manifest=/__review__/{seg(pack, stem, 'submeshes', 'index.json')}"
    if has_gltf:
        return f"{base}/?gltf=/__review__/{seg(pack, stem, 'mesh.gltf')}"
    return f"{base}/?obj=/__review__/{seg(pack, stem, 'mesh.obj')}"


def _score(meta: dict[str, Any], has_gltf: bool) -> tuple[int, int, int]:
    """Larger is better. (vertices, mesh_group_count, has_mesh_scene_gltf)."""
    return (int(meta.get("vertices") or 0),
            int(meta.get("mesh_group_count") or 0),
            1 if has_gltf else 0)


def collect(bundle: Path, review_root: Path, compiled, viewer_base: str | None) -> dict[str, list[dict[str, Any]]]:
    master = _load_master_manifest(bundle)
    buckets: dict[str, list[dict[str, Any]]] = {}

    for entry in master.get("assets", []):
        per = _load_per_asset(bundle, entry)
        if not per:
            continue
        stem = str(per.get("stem", ""))
        pack = str(per.get("pack", ""))
        label_hint = per.get("label_hint")
        cat = categorize(stem, label_hint, compiled)

        rdir = _review_dir(review_root, pack, stem)
        meta = _load_mesh_meta(rdir)
        verts = int(meta.get("vertices") or 0)
        has_gltf = (rdir / "mesh_scene.gltf").is_file()
        has_manifest = (rdir / "submeshes" / "index.json").is_file()

        if verts <= 0:
            buckets.setdefault(cat, [])
            continue

        buckets.setdefault(cat, []).append({
            "id": entry.get("id"),
            "pack": pack,
            "stem": stem,
            "label_hint": label_hint,
            "ue_folder": entry.get("ue_folder") or per.get("ue_folder"),
            "bundle_dir": str(entry.get("bundle_dir")),
            "review_dir": str(rdir),
            "vertices": verts,
            "faces": int(meta.get("faces") or 0),
            "mesh_group_count": int(meta.get("mesh_group_count") or 0),
            "transparent_count": int(meta.get("transparent_count") or 0),
            "topology": meta.get("topology"),
            "has_mesh_scene_gltf": has_gltf,
            "has_submesh_manifest": has_manifest,
            "viewer_url": _viewer_url(viewer_base, pack, stem, has_manifest, has_gltf),
            "_score": _score(meta, has_gltf),
        })

    for cat, items in buckets.items():
        items.sort(key=lambda e: e["_score"], reverse=True)
        for it in items:
            it.pop("_score", None)
    return buckets


def write_samples_bundle(bundle: Path, samples_out: Path, picks: list[dict[str, Any]], master_meta: dict[str, Any]) -> int:
    """Copy only the picked assets/<id>/ folders into samples_out and write a master manifest."""
    if samples_out.exists():
        shutil.rmtree(samples_out)
    (samples_out / "assets").mkdir(parents=True, exist_ok=True)
    (samples_out / "metadata").mkdir(parents=True, exist_ok=True)

    copied: list[dict[str, Any]] = []
    for pick in picks:
        src = bundle / str(pick["bundle_dir"])
        if not src.is_dir():
            continue
        dst = samples_out / "assets" / src.name
        shutil.copytree(src, dst)
        copied.append({
            "id": pick["id"],
            "bundle_dir": f"assets/{src.name}",
            "manifest": "manifest.json",
            "ue_folder": pick["ue_folder"],
            "category": pick["category"],
        })

    master = {
        "pipeline_root": master_meta.get("pipeline_root"),
        "layout": "bundled",
        "asset_count": len(copied),
        "assets": copied,
        "variant_registry_path": master_meta.get("variant_registry_path"),
        "save_knowledge_path": master_meta.get("save_knowledge_path"),
        "source_bundle": str(bundle.resolve()),
        "selection": "category_samples",
    }
    (samples_out / "metadata" / "manifest.json").write_text(json.dumps(master, indent=2), encoding="utf-8")

    for support in ("import_assets.py", "ue5_material_import.py"):
        src = bundle / support
        if src.is_file():
            shutil.copy2(src, samples_out / support)

    return len(copied)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--bundle", type=Path, default=Path("output/ue5_import"),
                    help="UE5 export bundle root (contains metadata/manifest.json)")
    ap.add_argument("--review-root", type=Path, default=Path("output/extracted/review"),
                    help="Stage-2 review root (contains batch_*/<stem>/mesh.meta.json)")
    ap.add_argument("--categories", type=Path,
                    help="Optional JSON file with [[name, [regexes]], ...] overriding the defaults")
    ap.add_argument("--out", type=Path,
                    help="Output JSON path (default: <bundle>/category_samples.json)")
    ap.add_argument("--top", type=int, default=1,
                    help="Picks per leaf category (default: 1 — one representative per kind)")
    ap.add_argument("--viewer-base", default="http://localhost:5173",
                    help="Origin for viewer deep-links (set empty string to omit)")
    ap.add_argument("--samples-bundle", type=Path,
                    help="Optional: copy picked assets into this folder as a reduced UE5 bundle")
    ap.add_argument("--quiet", action="store_true")
    args = ap.parse_args()

    cat_table: list[tuple[str, list[str]]]
    if args.categories and args.categories.is_file():
        raw = json.loads(args.categories.read_text(encoding="utf-8"))
        if not isinstance(raw, list):
            raise SystemExit("error: --categories file must be a list of [name, [regex,...]] pairs")
        cat_table = [(str(name), [str(p) for p in pats]) for name, pats in raw]
    else:
        cat_table = DEFAULT_CATEGORIES
    compiled = _compile_categories(cat_table)

    viewer_base = args.viewer_base or None
    buckets = collect(args.bundle.resolve(), args.review_root.resolve(), compiled, viewer_base)
    master_meta = _load_master_manifest(args.bundle.resolve())

    summary_categories: list[dict[str, Any]] = []
    flat_picks: list[dict[str, Any]] = []
    for name, _ in cat_table + [("unknown", [])]:
        items = buckets.get(name, [])
        picks = items[: max(1, args.top)] if items else []
        for p in picks:
            p2 = dict(p)
            p2["category"] = name
            flat_picks.append(p2)
        summary_categories.append({
            "category": name,
            "with_geometry": len(items),
            "picks": picks,
        })

    summary = {
        "bundle": str(args.bundle.resolve()),
        "review_root": str(args.review_root.resolve()),
        "viewer_base": viewer_base,
        "top_per_category": args.top,
        "total_picks": len(flat_picks),
        "categories": summary_categories,
    }

    out_path = args.out or (args.bundle / "category_samples.json")
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(summary, indent=2), encoding="utf-8")

    if not args.quiet:
        print(f"Wrote {out_path} ({len(flat_picks)} picks across {sum(1 for c in summary_categories if c['picks'])} categories)")
        for c in summary_categories:
            if c["picks"]:
                first = c["picks"][0]
                hint = first.get("label_hint") or first["stem"]
                print(f"  {c['category']:32}  {first['vertices']:>9d}v  {hint}")
            elif c["with_geometry"] == 0:
                # show empty leaves only when something interesting (i.e. matched) was empty
                continue

    if args.samples_bundle:
        n = write_samples_bundle(args.bundle.resolve(), args.samples_bundle.resolve(), flat_picks, master_meta)
        if not args.quiet:
            print(f"Wrote samples bundle: {n} assets → {args.samples_bundle}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
