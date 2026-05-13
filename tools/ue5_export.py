#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Bundle extracted review assets for UE5 import.

Default ``--layout bundled`` writes one self-contained folder per asset under ``<out>/assets/<id>/``:
  mesh_scene.gltf, mesh_scene.bin (when present), textures/, collision/, optional submeshes/,
  mesh.meta.json, and manifest.json.

``--layout flat`` keeps the previous single-folder layout (meshes/, textures/, collision/, metadata/).

``tools/savefile_parser.py`` writes full harvested lists (no truncation). ``ue5_export.py`` merges those
strings with tokens from every ``extracted/ffcs_*/paths.txt``, ``variant_registry.json`` grouped keys,
and all ``dialog_fragments.json`` files under ``extracted/review/`` into one set used to enrich
``ue_folder`` and optional ``label_hint`` on each bundle manifest (substring match on the block stem).
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
from pathlib import Path
from typing import Any

_SAVE_HARVEST_LIST_KEYS = (
    "vehicle_tokens",
    "support_tokens",
    "localization_key_like",
    "mission_ids",
    "sys_string_to_guid_hex",
    "vz_layer_strings",
)


def _normalize_label_token(s: str) -> str | None:
    s = (s or "").strip()
    if len(s) <= 2:
        return None
    if len(s) >= 2 and s[0] == '"' and s[-1] == '"':
        s = s[1:-1].strip()
    if s.startswith("[") and s.endswith("]"):
        s = s[1:-1].strip()
    s = re.sub(r"\s+", "_", s)
    s = s.replace(".", "_")
    s = re.sub(r"_+", "_", s).strip("_")
    if len(s) <= 2:
        return None
    return s


def _paths_line_to_stem(line: str) -> str | None:
    line = (line or "").strip().replace("\\", "/")
    if not line or line.startswith("#"):
        return None
    stem = Path(line).stem
    stem = re.sub(r"_P\d+_Q\d+$", "", stem, flags=re.I)
    stem = re.sub(r"^\d+_", "", stem)
    stem = stem.strip("_")
    return stem or None


def _merge_tokens_from_saves_json(path: Path, tokens: set[str]) -> None:
    try:
        raw: Any = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return
    docs = raw if isinstance(raw, list) else [raw]
    for doc in docs:
        if not isinstance(doc, dict):
            continue
        h = doc.get("harvested")
        if isinstance(h, dict):
            for key in _SAVE_HARVEST_LIST_KEYS:
                arr = h.get(key)
                if not isinstance(arr, list):
                    continue
                for x in arr:
                    if isinstance(x, str):
                        n = _normalize_label_token(x)
                        if n:
                            tokens.add(n)
        hdr = doc.get("header")
        if isinstance(hdr, dict):
            rn = hdr.get("reference_name_utf16")
            if isinstance(rn, str) and rn.strip():
                n = _normalize_label_token(re.sub(r"\s+", "_", rn.strip()))
                if n:
                    tokens.add(n)


def collect_label_tokens(pipeline_root: Path, repo_root: Path, vr_data: Any | None) -> set[str]:
    """Union of label tokens from saves, FFCS paths, variant registry, and dialog fragment harvests."""
    tokens: set[str] = set()
    for cand in (
        pipeline_root / "knowledge" / "saves.json",
        repo_root / "output" / "knowledge" / "saves.json",
    ):
        if cand.is_file():
            _merge_tokens_from_saves_json(cand, tokens)

    extr = pipeline_root / "extracted"
    if extr.is_dir():
        for paths_txt in sorted(extr.glob("ffcs_*/paths.txt")):
            try:
                text = paths_txt.read_text(encoding="utf-8", errors="replace")
            except OSError:
                continue
            for raw_line in text.splitlines():
                st = _paths_line_to_stem(raw_line)
                if st and len(st) > 2:
                    tokens.add(st)

    vr = vr_data
    if vr is None:
        for vp in (pipeline_root / "variant_registry.json", repo_root / "output" / "variant_registry.json"):
            if vp.is_file():
                try:
                    vr = json.loads(vp.read_text(encoding="utf-8"))
                    break
                except (OSError, json.JSONDecodeError):
                    vr = None
    if isinstance(vr, dict):
        g = vr.get("grouped_by_base_asset_id")
        if isinstance(g, dict):
            for base_id, stems in g.items():
                if isinstance(base_id, str):
                    bid = _paths_line_to_stem(base_id) or _normalize_label_token(base_id.replace("\\", "/"))
                    if bid and len(bid) > 2:
                        tokens.add(bid)
                if isinstance(stems, list):
                    for st in stems:
                        if isinstance(st, str):
                            t = _paths_line_to_stem(st) or _normalize_label_token(st.replace("\\", "/"))
                            if t and len(t) > 2:
                                tokens.add(t)

    review = extr / "review" if extr.is_dir() else pipeline_root / "review"
    if review.is_dir():
        for dg in review.rglob("dialog_fragments.json"):
            try:
                obj: Any = json.loads(dg.read_text(encoding="utf-8"))
            except (OSError, json.JSONDecodeError):
                continue
            rows = obj if isinstance(obj, list) else [obj]
            for frag in rows:
                if not isinstance(frag, dict):
                    continue
                for key in ("bracket_keys", "generic_keys", "utf16_bracket_keys"):
                    arr = frag.get(key)
                    if not isinstance(arr, list):
                        continue
                    for x in arr:
                        if isinstance(x, str):
                            n = _normalize_label_token(x)
                            if n:
                                tokens.add(n)

    return tokens


def _best_label_token_for_stem(stem: str, tokens: set[str]) -> str | None:
    """Pick the longest label token that appears inside ``stem`` (case-insensitive)."""
    sl = stem.lower()
    best: str | None = None
    best_len = 0
    for t in tokens:
        tl = t.lower()
        if len(tl) < 4:
            continue
        if tl in sl:
            if len(t) > best_len:
                best, best_len = t, len(t)
    return best


def ue_content_folder_name(
    asset_id: str,
    pack: str,
    stem: str,
    *,
    label_tokens: set[str] | None = None,
) -> str:
    """Stable, readable UE folder under ``/Game/Mercs2/``; optional merged label tokens boost legibility."""
    ptag = re.sub(r"(?i)^batch_", "", (pack or "").strip())
    s = (stem or "").strip()
    if s.lower().endswith(".block"):
        s = s[:-6]
    s = re.sub(r"_P\d+_Q\d+$", "", s, flags=re.I)
    s = re.sub(r"^\d+_", "", s)
    s = re.sub(r"(?i)^blocks__", "", s)
    s = s.replace("__", "_")
    s = re.sub(r"[^A-Za-z0-9_]+", "_", s)
    s = re.sub(r"_+", "_", s).strip("_")
    hint = _best_label_token_for_stem(stem, label_tokens) if label_tokens else None
    if hint:
        hn = re.sub(r"[^A-Za-z0-9_]+", "_", hint)
        hn = re.sub(r"_+", "_", hn).strip("_")
        if hn and hn.lower() not in (s or "").lower():
            s = f"{hn}_{s}" if s else hn
        elif hn and not s:
            s = hn
    if ptag and s:
        pl, sl = ptag.lower(), s.lower()
        if not sl.startswith(pl + "_") and sl != pl:
            core = f"{ptag}_{s}"
        else:
            core = s
    elif s:
        core = s
    elif ptag:
        core = ptag
    else:
        core = "Asset"
    if len(core) > 64:
        core = core[:64].rstrip("_")
    short = hashlib.sha1(asset_id.encode("utf-8")).hexdigest()[:6]
    return f"{core}_{short}"

IMPORT_SCRIPT = '''# Mercs2 — open in UE 5.x Editor with Python enabled (Editor Preferences → Python).
# Set BUNDLE to your ue5_import folder (absolute path), then run run_import().
import json
import os
import unreal

BUNDLE_ROOT = r"__BUNDLE_ROOT__"
DEST_ROOT = "/Game/Mercs2"


def run_import(limit=None):
    """limit: import first N assets only (None = all)."""
    body = os.path.join(BUNDLE_ROOT, "ue5_material_import.py")
    if os.path.isfile(body):
        with open(body, "r", encoding="utf-8") as f:
            src = f.read()
        start = src.find("UE_IMPORT_BODY = r\\'\\'\\'")
        if start == -1:
            unreal.log_error("import_assets: could not find UE_IMPORT_BODY in ue5_material_import.py")
            return
        # Fallback: tell user to paste body from ue5_material_import.py Output window
        unreal.log("import_assets: paste Editor script from tools/ue5_material_import.py (run: python3 .../ue5_material_import.py)")
    man = os.path.join(BUNDLE_ROOT, "metadata", "manifest.json")
    with open(man, "r", encoding="utf-8") as f:
        data = json.load(f)
    unreal.log("import_assets stub: " + str(len(data.get("assets", []))) + " assets — use ue5_material_import batch API")


run_import()
'''


def collect_review(pipeline_root: Path) -> list[dict[str, object]]:
    review = pipeline_root / "extracted" / "review"
    if not review.is_dir():
        review = pipeline_root / "review"
    if not review.is_dir():
        return []
    out: list[dict[str, object]] = []
    for pack_dir in sorted(review.iterdir()):
        if not pack_dir.is_dir() or not pack_dir.name.startswith("batch_"):
            continue
        for stem_dir in sorted(pack_dir.iterdir()):
            if not stem_dir.is_dir():
                continue
            rel = f"{pack_dir.name}/{stem_dir.name}"
            stem_path = stem_dir
            obj = next(stem_dir.glob("mesh.obj"), None)
            gltf = next(stem_dir.glob("mesh.gltf"), None)
            scene_gltf = stem_dir / "mesh_scene.gltf"
            has_scene = scene_gltf.is_file()
            dds = None
            td = stem_dir / "textures"
            if td.is_dir():
                for f in sorted(td.glob("*.dds")):
                    dds = f
                    break
                if dds is None:
                    for f in sorted(td.glob("*.png")):
                        dds = f
                        break
            hav = stem_dir / "havok" / "manifest.json"
            submesh_manifest = stem_dir / "submeshes" / "index.json"
            submesh_meta: dict[str, object] | None = None
            if submesh_manifest.is_file():
                try:
                    entries = json.loads(submesh_manifest.read_text(encoding="utf-8"))
                    mat_indices = sorted(
                        {e["material_index"] for e in entries if e.get("material_index") is not None}
                    )
                    transparent_count = sum(1 for e in entries if e.get("transparent"))
                    mesh_groups = sorted(
                        {e["mesh_group_id"] for e in entries if e.get("mesh_group_id") is not None}
                    )
                    submesh_meta = {
                        "submesh_count": len(entries),
                        "material_indices": mat_indices,
                        "transparent_count": transparent_count,
                        "mesh_group_count": len(mesh_groups),
                    }
                except (json.JSONDecodeError, KeyError):
                    pass
            out.append(
                {
                    "id": rel.replace("/", "__"),
                    "pack": pack_dir.name,
                    "stem": stem_dir.name,
                    "stem_path": str(stem_path.resolve()),
                    "mesh_obj": str(obj) if obj else None,
                    "mesh_gltf": str(gltf) if gltf else None,
                    "mesh_scene_gltf": str(scene_gltf) if has_scene else None,
                    "texture_sample": str(dds) if dds else None,
                    "havok_manifest": str(hav) if hav.is_file() else None,
                    "submesh_manifest": str(submesh_manifest) if submesh_manifest.is_file() else None,
                    "submesh_meta": submesh_meta,
                }
            )
    return out


def _write_bundled(
    ue: Path,
    assets: list[dict[str, object]],
    *,
    label_tokens: set[str] | None,
) -> list[dict[str, object]]:
    assets_root = ue / "assets"
    assets_root.mkdir(parents=True, exist_ok=True)
    master_assets: list[dict[str, object]] = []

    for a in assets:
        aid = str(a["id"])
        adir = assets_root / aid
        if adir.exists():
            shutil.rmtree(adir)
        adir.mkdir(parents=True, exist_ok=True)
        tex_d = adir / "textures"
        col_d = adir / "collision"
        tex_d.mkdir(parents=True, exist_ok=True)
        col_d.mkdir(parents=True, exist_ok=True)

        stem_path = Path(str(a["stem_path"]))
        per: dict[str, object] = {"id": aid, "pack": a["pack"], "stem": a["stem"]}

        scene = a.get("mesh_scene_gltf")
        if scene:
            sp = Path(str(scene))
            if sp.is_file():
                shutil.copy2(sp, adir / "mesh_scene.gltf")
                bin_p = sp.with_suffix(".bin")
                if bin_p.is_file():
                    shutil.copy2(bin_p, adir / "mesh_scene.bin")
                per["mesh_scene_gltf"] = "mesh_scene.gltf"
                per["mesh_scene_bin"] = "mesh_scene.bin"

        td = stem_path / "textures"
        if td.is_dir():
            for f in td.iterdir():
                if f.is_file() and f.suffix.lower() in (".png", ".dds", ".tga", ".jpg", ".jpeg"):
                    shutil.copy2(f, tex_d / f.name)
            names = sorted(p.name for p in tex_d.iterdir() if p.is_file())
            if names:
                per["textures"] = names

        hav_dir = stem_path / "havok"
        if hav_dir.is_dir():
            for objf in hav_dir.glob("convex_hull_*.obj"):
                shutil.copy2(objf, col_d / objf.name)
            cnames = sorted(p.name for p in col_d.iterdir() if p.is_file())
            if cnames:
                per["collision_objs"] = cnames

        sub = stem_path / "submeshes"
        if sub.is_dir():
            shutil.copytree(sub, adir / "submeshes")
            per["submesh_dir"] = "submeshes"

        meta_src = stem_path / "mesh.meta.json"
        if meta_src.is_file():
            shutil.copy2(meta_src, adir / "mesh.meta.json")
            per["mesh_meta"] = "mesh.meta.json"

        if a["submesh_meta"]:
            per.update(a["submesh_meta"])

        per["ue_folder"] = ue_content_folder_name(aid, str(a["pack"]), str(a["stem"]), label_tokens=label_tokens)
        if label_tokens:
            hit = _best_label_token_for_stem(str(a["stem"]), label_tokens)
            if hit:
                per["label_hint"] = hit
        (adir / "manifest.json").write_text(json.dumps(per, indent=2), encoding="utf-8")
        master_assets.append(
            {
                "id": aid,
                "bundle_dir": str((assets_root / aid).relative_to(ue)),
                "manifest": "manifest.json",
                "ue_folder": per["ue_folder"],
            }
        )

    return master_assets


def _write_flat(
    ue: Path,
    assets: list[dict[str, object]],
    *,
    label_tokens: set[str] | None,
) -> list[dict[str, object]]:
    meshes = ue / "meshes"
    textures = ue / "textures"
    collision = ue / "collision"
    meta = ue / "metadata"
    variants = ue / "variants"
    for d in (meshes, textures, collision, meta, variants):
        d.mkdir(parents=True, exist_ok=True)

    manifest_assets: list[dict[str, object]] = []
    for a in assets:
        entry: dict[str, object] = {"id": a["id"], "pack": a["pack"], "stem": a["stem"]}
        if a["mesh_obj"]:
            p = Path(str(a["mesh_obj"]))
            dest = meshes / (str(a["id"]) + ".obj")
            shutil.copy2(p, dest)
            entry["mesh_ue_relative"] = str(dest.relative_to(ue))
        if a["mesh_gltf"]:
            p = Path(str(a["mesh_gltf"]))
            dest = meshes / (str(a["id"]) + ".gltf")
            shutil.copy2(p, dest)
            entry["gltf_ue_relative"] = str(dest.relative_to(ue))
        if a.get("mesh_scene_gltf"):
            p = Path(str(a["mesh_scene_gltf"]))
            if p.is_file():
                dest = meshes / (str(a["id"]) + "_scene.gltf")
                shutil.copy2(p, dest)
                entry["mesh_scene_gltf_relative"] = str(dest.relative_to(ue))
                bp = p.with_suffix(".bin")
                if bp.is_file():
                    bdest = dest.with_suffix(".bin")
                    shutil.copy2(bp, bdest)
                    entry["mesh_scene_bin_relative"] = str(bdest.relative_to(ue))
        if a["texture_sample"]:
            p = Path(str(a["texture_sample"]))
            suf = p.suffix.lower() or ".bin"
            dest = textures / (str(a["id"]) + suf)
            shutil.copy2(p, dest)
            entry["texture_ue_relative"] = str(dest.relative_to(ue))
        hav_dir = Path(str(a["havok_manifest"])).parent if a["havok_manifest"] else None
        if hav_dir and hav_dir.is_dir():
            for objf in hav_dir.glob("convex_hull_*.obj"):
                dest = collision / (str(a["id"]) + "_" + objf.name)
                shutil.copy2(objf, dest)
                entry.setdefault("collision_objs", []).append(str(dest.relative_to(ue)))
        if a["submesh_manifest"]:
            src_dir = Path(str(a["submesh_manifest"])).parent
            dest_dir = meshes / str(a["id"]) / "submeshes"
            if src_dir.is_dir():
                if dest_dir.exists():
                    shutil.rmtree(dest_dir)
                shutil.copytree(src_dir, dest_dir)
                entry["submesh_dir"] = str(dest_dir.relative_to(ue))
                entry["submesh_manifest"] = str((dest_dir / "index.json").relative_to(ue))
        if a["submesh_meta"]:
            entry.update(a["submesh_meta"])
        entry["ue_folder"] = ue_content_folder_name(
            str(a["id"]), str(a["pack"]), str(a["stem"]), label_tokens=label_tokens
        )
        if label_tokens:
            hit = _best_label_token_for_stem(str(a["stem"]), label_tokens)
            if hit:
                entry["label_hint"] = hit
        manifest_assets.append(entry)
    return manifest_assets


def main() -> int:
    ap = argparse.ArgumentParser(description="Mercenaries 2 to UE5 export bundle")
    ap.add_argument("--pipeline-root", type=Path, required=True, help="Folder containing extracted/review")
    ap.add_argument("--out", type=Path, required=True, help="Output folder e.g. output/ue5_import")
    ap.add_argument(
        "--layout",
        choices=("bundled", "flat"),
        default="bundled",
        help="bundled: self-contained folder per asset under assets/<id>/ (default). flat: legacy layout.",
    )
    args = ap.parse_args()

    assets = collect_review(args.pipeline_root)
    ue = args.out.resolve()
    ue.mkdir(parents=True, exist_ok=True)

    repo_root = Path(__file__).resolve().parents[1]
    variant_registry: Path | None = None
    vr_data: Any | None = None
    for vp in (Path(args.pipeline_root) / "variant_registry.json", repo_root / "output" / "variant_registry.json"):
        if vp.is_file():
            variant_registry = vp
            try:
                vr_data = json.loads(vp.read_text(encoding="utf-8"))
            except (OSError, json.JSONDecodeError):
                vr_data = None
            break

    know_candidates = [
        Path(args.pipeline_root) / "knowledge" / "saves.json",
        repo_root / "output" / "knowledge" / "saves.json",
    ]
    saves_data = None
    know: Path | None = None
    for cand in know_candidates:
        if cand.is_file():
            know = cand
            saves_data = json.loads(cand.read_text(encoding="utf-8"))
            break

    label_tokens = collect_label_tokens(Path(args.pipeline_root), repo_root, vr_data)

    if args.layout == "bundled":
        manifest_assets = _write_bundled(ue, assets, label_tokens=label_tokens or None)
    else:
        manifest_assets = _write_flat(ue, assets, label_tokens=label_tokens or None)

    meta = ue / "metadata"
    variants = ue / "variants"
    meta.mkdir(parents=True, exist_ok=True)
    variants.mkdir(parents=True, exist_ok=True)

    master = {
        "pipeline_root": str(args.pipeline_root.resolve()),
        "layout": args.layout,
        "asset_count": len(manifest_assets),
        "assets": manifest_assets,
        "variant_registry_path": str(variant_registry) if variant_registry else None,
        "save_knowledge_path": str(know) if know else None,
        "label_tokens_count": len(label_tokens),
    }
    if vr_data is not None:
        (variants / "variant_registry.json").write_text(json.dumps(vr_data, indent=2), encoding="utf-8")
    if saves_data is not None:
        (meta / "save_knowledge.json").write_text(json.dumps(saves_data, indent=2), encoding="utf-8")

    man_path = meta / "manifest.json"
    man_path.write_text(json.dumps(master, indent=2), encoding="utf-8")

    py_path = ue / "import_assets.py"
    py_path.write_text(IMPORT_SCRIPT.replace("__BUNDLE_ROOT__", str(ue.resolve())), encoding="utf-8")

    mat_src = Path(__file__).resolve().parent / "ue5_material_import.py"
    if mat_src.is_file():
        shutil.copy2(mat_src, ue / "ue5_material_import.py")

    print(f"Wrote {len(manifest_assets)} assets -> {ue} ({args.layout})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
