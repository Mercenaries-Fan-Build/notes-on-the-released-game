"""Mercenaries 2 Recreation — Full World Mesh Import

UE 5.7 Editor Python script that imports ALL mesh GLBs from the extraction
pipeline into the UE project.  Run BEFORE populate_world.py.

After ``make extract-terrain`` (repo Makefile), merged Venezuela ground mesh is
written to
``output/extracted/review/batch_vz/03121_blocks__VZ__low_res_terrain_P000_Q3.block/mesh_scene.glb``
and is discovered automatically like any other ``mesh_scene.glb``.

Usage:
    Edit → Run Python Script → select this file
    or from Editor console:
        unreal.PythonScriptLibrary.execute_python_script(
            "/path/to/mercenaries-game/game-scripts/import_world.py")

    Re-import after ``make extract-terrain`` (existing UE folders are skipped by default):

        MERCS2_FORCE_TERRAIN=1 py ".../import_world.py"

    Re-import everything:

        MERCS2_FORCE_IMPORT=1 py ".../import_world.py"
"""
from __future__ import annotations

import json
import os
import re
import struct
import sys
from typing import TYPE_CHECKING

import unreal

if TYPE_CHECKING:
    from typing import Optional

_SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
if _SCRIPT_DIR not in sys.path:
    sys.path.insert(0, _SCRIPT_DIR)

import mercs2_mesh_utils as mesh_utils

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

REPO_ROOT: str = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
REVIEW_ROOT: str = os.path.join(REPO_ROOT, "output", "extracted", "review")
CONTENT_BASE: str = "/Game/Mercs2"

LOG_PREFIX = "[Mercs2Import]"

_CATEGORY_RULES: list[tuple[str, list[str]]] = [
    ("WorldCells", ["blocks__vz__c3", "__shared__"]),
    ("Vehicles", ["veh_", "helicopter", "boat_", "jetski"]),
    ("Buildings", ["_bld_", "skyscraper", "apartment", "shack", "warehouse"]),
    ("Roads", ["road"]),
    ("Environment", ["terrain", "env_", "rock", "plant", "tree", "palm", "bush", "foliage"]),
    ("Maracaibo", ["maracaibo"]),
]

_MESH_SCENE_GLB = "mesh_scene.glb"
_MESH_SCENE_GLTF = "mesh_scene.gltf"

_LOD_RE = re.compile(r"^\d+_blocks__VZ__(.+?)_(P\d+)_(Q\d+)\.block$")

# ---------------------------------------------------------------------------
# Logging helpers
# ---------------------------------------------------------------------------

def _log(msg: str) -> None:
    unreal.log(f"{LOG_PREFIX} {msg}")


def _warn(msg: str) -> None:
    unreal.log_warning(f"{LOG_PREFIX} {msg}")


def _err(msg: str) -> None:
    unreal.log_error(f"{LOG_PREFIX} {msg}")


# ---------------------------------------------------------------------------
# Categorisation & naming
# ---------------------------------------------------------------------------

def _categorize(mesh_name: str) -> str:
    """Match *mesh_name* (lowercase) against category rules and return the
    target subfolder name, or ``"Other"`` if nothing matches."""
    lower = mesh_name.lower()
    if re.search(r"blocks__vz__c3\d{4}", lower) or (
        "__shared__" in lower and re.search(r"c3\d{4}", lower)
    ):
        return "WorldCells"
    for category, keywords in _CATEGORY_RULES:
        for kw in keywords:
            if kw in lower:
                return category
    return "Other"


def sanitize_name(name: str) -> str:
    """Produce a safe UE asset name from an arbitrary string.

    Replaces spaces, hyphens, and dots with underscores; strips anything that
    isn't alphanumeric or underscore; prefixes ``A_`` when the result starts
    with a digit; truncates to 120 characters.
    """
    out = name.replace(" ", "_").replace("-", "_").replace(".", "_")
    out = re.sub(r"[^A-Za-z0-9_]", "", out)
    if out and out[0].isdigit():
        out = f"A_{out}"
    return out[:120]


def _base_mesh_name(stem: str) -> Optional[str]:
    """Extract the logical mesh name from a block-folder stem.

    Returns group(1) of ``_LOD_RE``, or ``None`` if the stem does not match
    the expected naming convention.
    """
    m = _LOD_RE.match(stem)
    return m.group(1) if m else None


# ---------------------------------------------------------------------------
# GLB bounding-box volume (lightweight, no full parse)
# ---------------------------------------------------------------------------

def _bbox_volume(glb_path: str) -> float:
    """Read the first 256 KB of a GLB, extract the JSON chunk, and compute an
    approximate bounding-box volume from accessor min/max across all mesh
    primitives' POSITION attributes.  Returns 0.0 on any error."""
    try:
        with open(glb_path, "rb") as fh:
            header = fh.read(12)
            if len(header) < 12:
                return 0.0
            magic, version, length = struct.unpack_from("<III", header)
            if magic != 0x46546C67:  # 'glTF'
                return 0.0

            chunk_header = fh.read(8)
            if len(chunk_header) < 8:
                return 0.0
            chunk_len, chunk_type = struct.unpack_from("<II", chunk_header)

            read_len = min(chunk_len, 256 * 1024)
            raw = fh.read(read_len)
            if chunk_type != 0x4E4F534A:  # 'JSON'
                return 0.0

            gltf = json.loads(raw[:chunk_len] if chunk_len <= read_len else raw)

        accessors = gltf.get("accessors", [])
        meshes = gltf.get("meshes", [])

        global_min = [float("inf")] * 3
        global_max = [float("-inf")] * 3

        for mesh in meshes:
            for prim in mesh.get("primitives", []):
                pos_idx = prim.get("attributes", {}).get("POSITION")
                if pos_idx is None or pos_idx >= len(accessors):
                    continue
                acc = accessors[pos_idx]
                a_min = acc.get("min")
                a_max = acc.get("max")
                if not a_min or not a_max or len(a_min) < 3 or len(a_max) < 3:
                    continue
                for i in range(3):
                    if a_min[i] < global_min[i]:
                        global_min[i] = a_min[i]
                    if a_max[i] > global_max[i]:
                        global_max[i] = a_max[i]

        if float("inf") in global_min:
            return 0.0

        dx = global_max[0] - global_min[0]
        dy = global_max[1] - global_min[1]
        dz = global_max[2] - global_min[2]
        return abs(dx * dy * dz)
    except Exception:
        return 0.0


# ---------------------------------------------------------------------------
# Import helpers (Interchange → AssetImportTask fallback)
# ---------------------------------------------------------------------------

def _import_via_interchange(
    source_path: str,
    dest_path: str,
    asset_name: str,
) -> list[unreal.Object]:
    """Import a GLB using the Interchange pipeline (UE 5.7+)."""
    ic = unreal.InterchangeManager.get_interchange_manager_scripted()
    source_data = unreal.InterchangeSourceData()
    source_data.set_filename(source_path)

    params = unreal.ImportAssetParameters()
    params.set_editor_property("is_automated", True)
    params.set_editor_property("replace_existing", True)

    results = ic.import_asset(dest_path, source_data, params)
    return list(results) if results else []


def _import_via_task(
    source_path: str,
    dest_path: str,
    asset_name: str,
) -> list[unreal.Object]:
    """Fallback import using legacy AssetImportTask."""
    task = unreal.AssetImportTask()
    task.set_editor_property("filename", source_path)
    task.set_editor_property("destination_path", dest_path)
    task.set_editor_property("destination_name", asset_name)
    task.set_editor_property("replace_existing", True)
    task.set_editor_property("automated", True)
    task.set_editor_property("save", True)

    unreal.AssetToolsHelpers.get_asset_tools().import_asset_tasks([task])

    objects: list[unreal.Object] = []
    try:
        objects = list(task.get_objects())
    except Exception:
        pass
    if not objects:
        try:
            for p in task.imported_object_paths:
                obj = unreal.EditorAssetLibrary.load_asset(str(p))
                if obj is not None:
                    objects.append(obj)
        except Exception:
            pass
    return objects


def import_glb(
    source_path: str,
    dest_path: str,
    asset_name: str,
) -> Optional[unreal.Object]:
    """Import a single GLB — tries Interchange first, then task-based fallback.

    Returns the first imported object, or ``None``.
    """
    objects: list[unreal.Object] = []
    try:
        objects = _import_via_interchange(source_path, dest_path, asset_name)
    except Exception as exc:
        _warn(f"Interchange failed for {asset_name}: {exc}")

    if not objects:
        try:
            objects = _import_via_task(source_path, dest_path, asset_name)
        except Exception as exc:
            _err(f"Task import also failed for {asset_name}: {exc}")

    return objects[0] if objects else None


def _disable_nanite_in_import_folder(dest_path: str) -> None:
    """Interchange often enables Nanite; turn it off for every StaticMesh imported."""
    if not unreal.EditorAssetLibrary.does_directory_exist(dest_path):
        return
    for asset_path in unreal.EditorAssetLibrary.list_assets(
        dest_path, recursive=True, include_folder=False,
    ):
        obj = unreal.EditorAssetLibrary.load_asset(str(asset_path))
        if isinstance(obj, unreal.StaticMesh):
            mesh_utils.disable_nanite_on_static_mesh(obj)


# ---------------------------------------------------------------------------
# Discovery & deduplication
# ---------------------------------------------------------------------------

def discover_glbs() -> list[dict]:
    """Walk ``REVIEW_ROOT`` two levels deep looking for ``mesh_scene.glb`` / ``.gltf``.

    Returns a list of dicts with keys:
        stem, base, pack, glb, category, vol
    """
    entries: list[dict] = []
    if not os.path.isdir(REVIEW_ROOT):
        _err(f"REVIEW_ROOT does not exist: {REVIEW_ROOT}")
        return entries

    for pack in os.listdir(REVIEW_ROOT):
        pack_dir = os.path.join(REVIEW_ROOT, pack)
        if not os.path.isdir(pack_dir):
            continue
        for stem in os.listdir(pack_dir):
            block_dir = os.path.join(pack_dir, stem)
            if not os.path.isdir(block_dir):
                continue
            glb = os.path.join(block_dir, _MESH_SCENE_GLB)
            if not os.path.isfile(glb):
                glb = os.path.join(block_dir, _MESH_SCENE_GLTF)
            if not os.path.isfile(glb):
                continue

            base = _base_mesh_name(stem) or stem
            category = _categorize(stem)
            vol = _bbox_volume(glb) if glb.endswith(".glb") else 1.0

            entries.append({
                "stem": stem,
                "base": base,
                "pack": pack,
                "glb": glb,
                "category": category,
                "vol": vol,
            })

    _log(f"Discovered {len(entries)} GLBs across {REVIEW_ROOT}")
    return entries


def _import_flags() -> dict[str, bool]:
    """Env vars and ``sys.argv`` flags for re-import control."""
    argv = {a.lower() for a in sys.argv[1:]}
    force_all = (
        os.environ.get("MERCS2_FORCE_IMPORT", "").lower() in ("1", "true", "yes")
        or "--force" in argv
    )
    force_terrain = (
        os.environ.get("MERCS2_FORCE_TERRAIN", "").lower() in ("1", "true", "yes")
        or "--force-terrain" in argv
        or force_all
    )
    import_world_cells = (
        os.environ.get("MERCS2_IMPORT_WORLD_CELLS", "").lower() in ("1", "true", "yes")
        or "--world-cells" in argv
    )
    return {
        "force_all": force_all,
        "force_terrain": force_terrain,
        "import_world_cells": import_world_cells,
    }


def _dest_has_static_mesh(dest_path: str) -> bool:
    """True if *dest_path* already contains at least one imported StaticMesh."""
    if not unreal.EditorAssetLibrary.does_directory_exist(dest_path):
        return False
    for asset_path in unreal.EditorAssetLibrary.list_assets(dest_path, recursive=True):
        obj = unreal.EditorAssetLibrary.load_asset(str(asset_path))
        if obj is not None and isinstance(obj, unreal.StaticMesh):
            return True
    return False


def count_static_meshes_under(content_path: str) -> int:
    """Count imported StaticMesh assets under a Content Browser folder."""
    if not unreal.EditorAssetLibrary.does_directory_exist(content_path):
        return 0
    count = 0
    for asset_path in unreal.EditorAssetLibrary.list_assets(content_path, recursive=True):
        obj = unreal.EditorAssetLibrary.load_asset(str(asset_path))
        if obj is not None and isinstance(obj, unreal.StaticMesh):
            count += 1
    return count


def maybe_enable_force_import() -> bool:
    """Set MERCS2_FORCE_IMPORT when WorldCells content is missing (unless opted out).

    Returns True when force-import was enabled for this process.
    """
    if os.environ.get("MERCS2_FORCE_IMPORT", "").strip().lower() in (
        "1",
        "true",
        "yes",
    ):
        return False
    if os.environ.get("MERCS2_AUTO_FORCE_IMPORT", "").strip().lower() in (
        "0",
        "false",
        "no",
    ):
        return False
    cells_dir = f"{CONTENT_BASE}/Meshes/WorldCells"
    n = count_static_meshes_under(cells_dir)
    if n > 0:
        return False
    os.environ["MERCS2_FORCE_IMPORT"] = "1"
    _log(
        f"No StaticMeshes under {cells_dir} — enabled MERCS2_FORCE_IMPORT for this run. "
        "Set MERCS2_AUTO_FORCE_IMPORT=0 to disable auto force."
    )
    return True


def _import_stamp_path(glb_path: str) -> str:
    return glb_path + ".ue_imported"


def _glb_newer_than_import_stamp(glb_path: str) -> bool:
    """True when the on-disk GLB was updated after the last successful UE import."""
    stamp = _import_stamp_path(glb_path)
    if not os.path.isfile(glb_path) or not os.path.isfile(stamp):
        return bool(os.path.isfile(glb_path))
    return os.path.getmtime(glb_path) > os.path.getmtime(stamp)


def _touch_import_stamp(glb_path: str) -> None:
    try:
        with open(_import_stamp_path(glb_path), "a", encoding="utf-8"):
            pass
        os.utime(_import_stamp_path(glb_path), None)
    except OSError:
        pass


def _should_skip_import(entry: dict, dest_path: str, flags: dict[str, bool]) -> bool:
    if not _dest_has_static_mesh(dest_path):
        return False
    if flags["force_all"]:
        return False
    base = (entry.get("base") or "").lower()
    glb = entry.get("glb", "")
    if "low_res_terrain" in base and _glb_newer_than_import_stamp(glb):
        return False
    if flags["force_terrain"] and "low_res_terrain" in base:
        return False
    return True


def deduplicate_lods(entries: list[dict]) -> list[dict]:
    """Keep only the largest-volume variant per (category, base) pair."""
    best: dict[tuple[str, str], dict] = {}
    for e in entries:
        key = (e["category"], e["base"])
        if key not in best or e["vol"] > best[key]["vol"]:
            best[key] = e
    deduped = list(best.values())
    _log(f"Deduplicated {len(entries)} → {len(deduped)} unique meshes")
    return deduped


# ---------------------------------------------------------------------------
# Main import loop
# ---------------------------------------------------------------------------

def run_import(limit: int | None = None) -> None:
    """Discover, deduplicate, and import all GLBs into the UE project."""
    maybe_enable_force_import()
    flags = _import_flags()
    _log("=" * 60)
    _log("Starting full world mesh import")
    _log("=" * 60)
    if flags["force_all"]:
        _log("MERCS2_FORCE_IMPORT / --force: re-importing all meshes (skip disabled)")
    elif flags["force_terrain"]:
        _log("MERCS2_FORCE_TERRAIN / --force-terrain: re-import low_res_terrain only")

    entries = discover_glbs()
    if not entries:
        _err("No GLBs found — aborting.")
        return

    if not flags["import_world_cells"]:
        before = len(entries)
        entries = [e for e in entries if e.get("category") != "WorldCells"]
        skipped_cells = before - len(entries)
        if skipped_cells:
            _log(
                f"Skipping {skipped_cells} c3 world-cell GLBs (Nanite pool). "
                "Set MERCS2_IMPORT_WORLD_CELLS=1 to import them."
            )

    if any("low_res_terrain" in e["glb"].replace("\\", "/").lower() for e in entries):
        _log("Found merged low_res_terrain mesh_scene.glb (from make extract-terrain)")

    entries = deduplicate_lods(entries)

    # Sort largest first so visually important meshes import first
    entries.sort(key=lambda e: e["vol"], reverse=True)

    if limit is not None:
        entries = entries[:limit]
        _log(f"Limiting import to {limit} meshes")

    imported = 0
    skipped = 0
    failed = 0
    total = len(entries)

    for idx, entry in enumerate(entries):
        asset_name = sanitize_name(entry["stem"])
        category = entry["category"]
        dest_path = f"{CONTENT_BASE}/Meshes/{category}/{asset_name}"

        if _should_skip_import(entry, dest_path, flags):
            skipped += 1
            continue

        glb = entry["glb"]
        if (
            "low_res_terrain" in (entry.get("base") or "").lower()
            and _dest_has_static_mesh(dest_path)
            and _glb_newer_than_import_stamp(glb)
        ):
            _log(f"[{idx + 1}/{total}] Re-importing updated low_res_terrain GLB")

        _log(f"[{idx + 1}/{total}] Importing {asset_name} → {dest_path}")

        obj = import_glb(entry["glb"], dest_path, asset_name)
        if obj is not None:
            _disable_nanite_in_import_folder(dest_path)
            imported += 1
            if "low_res_terrain" in (entry.get("base") or "").lower():
                _touch_import_stamp(entry["glb"])
        else:
            failed += 1
            _warn(f"  No objects returned for {asset_name}")

    _log("=" * 60)
    _log(f"Import complete — {imported} imported, {skipped} skipped, {failed} failed (of {total})")
    if imported == 0 and skipped > 0 and not flags["force_all"]:
        _warn(
            "All meshes were skipped (Content folders already populated). "
            "After pipeline GLB updates or a bad partial import, set MERCS2_FORCE_IMPORT=1 "
            "and restart the editor before re-running setup_all.py."
        )
    _log("=" * 60)


if __name__ == "__main__":
    run_import()
