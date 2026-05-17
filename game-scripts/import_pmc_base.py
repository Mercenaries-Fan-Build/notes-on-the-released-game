"""Mercenaries 2 Recreation — PMC Base GLB Importer

UE 5.7 Editor Python script that imports PMC base mesh GLBs into
``/Game/Mercs2/Meshes/PMCBase``.  Very similar to the full-world import
workflow but scoped to the subset defined by ``pmc_base_asset_list.json``.

Run from UE Editor via:
    Edit → Run Python Script → select this file
or:
    unreal.PythonScriptLibrary.execute_python_script(
        "/path/to/mercenaries-game/game-scripts/import_pmc_base.py")
"""

from __future__ import annotations

import json
import os
import re
import struct
from typing import TYPE_CHECKING

import unreal

if TYPE_CHECKING:
    from typing import Optional

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
REVIEW_ROOT = os.path.join(REPO_ROOT, "output", "extracted", "review")
CONTENT_BASE = "/Game/Mercs2"
PMC_MESH_ROOT = os.environ.get("MERCS2_MESH_ROOT", f"{CONTENT_BASE}/Meshes/PMCBase")
ASSET_LIST = os.environ.get(
    "MERCS2_ASSET_LIST",
    os.path.join(REPO_ROOT, "output", "pmc_base_asset_list.json"),
)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

_LOD_RE = re.compile(r"_P\d+_Q\d+$", re.IGNORECASE)


def sanitize_name(name: str) -> str:
    """Replace characters illegal in UE asset names with underscores."""
    s = re.sub(r"[^A-Za-z0-9_]", "_", name)
    s = re.sub(r"_+", "_", s).strip("_")
    if s and s[0].isdigit():
        s = f"M_{s}"
    return s or "Unnamed"


def _base_mesh_name(stem: str) -> str:
    """Strip LOD/quality suffixes to get the canonical base mesh name."""
    s = stem
    if s.lower().endswith(".block"):
        s = s[:-6]
    s = _LOD_RE.sub("", s)
    s = re.sub(r"^\d+_", "", s)
    return s


def _bbox_volume(glb_path: str) -> float:
    """Read the GLB binary and compute the bounding-box volume from accessors.

    Returns 0.0 on any failure so the entry can still participate in
    deduplication (it just won't be preferred).
    """
    try:
        with open(glb_path, "rb") as fh:
            magic = fh.read(4)
            if magic != b"glTF":
                return 0.0
            fh.read(8)  # version + length
            chunk_len = struct.unpack("<I", fh.read(4))[0]
            fh.read(4)  # chunk type (JSON)
            raw_json = fh.read(chunk_len)
        doc = json.loads(raw_json)
        accessors = doc.get("accessors", [])
        total_vol = 0.0
        for acc in accessors:
            mn = acc.get("min")
            mx = acc.get("max")
            if mn and mx and len(mn) >= 3 and len(mx) >= 3:
                dx = abs(mx[0] - mn[0])
                dy = abs(mx[1] - mn[1])
                dz = abs(mx[2] - mn[2])
                vol = dx * dy * dz
                if vol > total_vol:
                    total_vol = vol
        return total_vol
    except Exception:
        return 0.0


# ---------------------------------------------------------------------------
# Import via Interchange / fallback to AssetImportTask
# ---------------------------------------------------------------------------

def _import_via_interchange(
    src: str,
    dest_path: str,
    asset_name: str,
) -> bool:
    """Import a GLB using the Interchange pipeline (UE 5.7 preferred)."""
    try:
        ic = unreal.InterchangeManager.get_interchange_manager_scripted()
        source = unreal.InterchangeSourceData()
        source.set_filename(src)
        params = unreal.ImportAssetParameters()
        params.is_automated = True
        params.destination_name = asset_name
        params.replace_existing = True
        result = ic.import_asset(dest_path, source, params)
        return bool(result)
    except Exception:
        return False


def _import_via_task(
    src: str,
    dest_path: str,
    asset_name: str,
) -> bool:
    """Fallback import using AssetImportTask."""
    task = unreal.AssetImportTask()
    task.set_editor_property("filename", src)
    task.set_editor_property("destination_path", dest_path)
    task.set_editor_property("destination_name", asset_name)
    task.set_editor_property("replace_existing", True)
    task.set_editor_property("automated", True)
    task.set_editor_property("save", True)
    unreal.AssetToolsHelpers.get_asset_tools().import_asset_tasks([task])
    return bool(task.get_objects())


def import_glb(
    src: str,
    dest_path: str,
    asset_name: str,
) -> bool:
    """Import a single GLB — tries Interchange first, then AssetImportTask."""
    if _import_via_interchange(src, dest_path, asset_name):
        return True
    unreal.log_warning(
        f"[PMCImport] Interchange failed for {asset_name}, trying AssetImportTask"
    )
    return _import_via_task(src, dest_path, asset_name)


# ---------------------------------------------------------------------------
# Discovery
# ---------------------------------------------------------------------------

def discover_pmc_glbs() -> list[dict[str, object]]:
    """Load ``pmc_base_asset_list.json`` and locate ``mesh_scene.glb`` for each entry.

    Returns a list of dicts: ``{stem, base, glb, vol}``.
    """
    if not os.path.isfile(ASSET_LIST):
        unreal.log_error(f"[PMCImport] Asset list not found: {ASSET_LIST}")
        return []

    with open(ASSET_LIST, "r", encoding="utf-8") as fh:
        data = json.load(fh)

    entries = data.get("assets", data) if isinstance(data, dict) else data
    if not isinstance(entries, list):
        unreal.log_error("[PMCImport] Unexpected asset list format")
        return []

    results: list[dict[str, object]] = []
    for entry in entries:
        if not isinstance(entry, dict):
            continue

        pack = entry.get("pack", "")
        stem = entry.get("stem", "")
        if not stem:
            continue

        block_dir = os.path.join(REVIEW_ROOT, pack, stem) if pack else os.path.join(REVIEW_ROOT, stem)
        glb_path = os.path.join(block_dir, "mesh_scene.glb")
        if not os.path.isfile(glb_path):
            continue

        base = _base_mesh_name(stem)
        vol = _bbox_volume(glb_path)
        results.append({
            "stem": stem,
            "base": base,
            "glb": glb_path,
            "vol": vol,
        })

    unreal.log(f"[PMCImport] Discovered {len(results)} GLBs from {len(entries)} asset list entries")
    return results


# ---------------------------------------------------------------------------
# LOD deduplication
# ---------------------------------------------------------------------------

def deduplicate_lods(entries: list[dict[str, object]]) -> list[dict[str, object]]:
    """Keep only the largest-volume variant per base mesh name."""
    best: dict[str, dict[str, object]] = {}
    for e in entries:
        base = str(e["base"])
        vol = float(e.get("vol") or 0.0)
        prev = best.get(base)
        if prev is None or vol > float(prev.get("vol") or 0.0):
            best[base] = e

    result = list(best.values())
    dropped = len(entries) - len(result)
    if dropped:
        unreal.log(f"[PMCImport] Deduplicated {dropped} LOD variants, {len(result)} unique meshes remain")
    return result


# ---------------------------------------------------------------------------
# Main import
# ---------------------------------------------------------------------------

def run_import(limit: Optional[int] = None) -> None:
    """Discover PMC base GLBs, deduplicate LODs, and import into UE."""
    unreal.log("=" * 60)
    unreal.log("[PMCImport] PMC Base GLB Import — starting")
    unreal.log("=" * 60)

    if not unreal.EditorAssetLibrary.does_directory_exist(PMC_MESH_ROOT):
        unreal.EditorAssetLibrary.make_directory(PMC_MESH_ROOT)

    entries = discover_pmc_glbs()
    if not entries:
        unreal.log_warning("[PMCImport] No GLBs found — nothing to import")
        return

    entries = deduplicate_lods(entries)
    if limit is not None:
        entries = entries[:limit]

    imported = 0
    skipped = 0
    failed = 0

    total = len(entries)
    with unreal.ScopedSlowTask(total, "Importing PMC Base meshes...") as task:
        task.make_dialog(True)
        for i, entry in enumerate(entries):
            if task.should_cancel():
                unreal.log_warning(f"[PMCImport] Cancelled by user at {i}/{total}")
                break

            stem = str(entry["stem"])
            glb = str(entry["glb"])
            asset_name = sanitize_name(_base_mesh_name(stem))
            dest_path = f"{PMC_MESH_ROOT}/{asset_name}"

            task.enter_progress_frame(
                1, f"({i + 1}/{total}) {asset_name}"
            )

            asset_check = f"{dest_path}/{asset_name}"
            if unreal.EditorAssetLibrary.does_asset_exist(asset_check):
                skipped += 1
                continue

            if not unreal.EditorAssetLibrary.does_directory_exist(dest_path):
                unreal.EditorAssetLibrary.make_directory(dest_path)

            if import_glb(glb, dest_path, asset_name):
                imported += 1
                unreal.log(f"[PMCImport] ({i + 1}/{total}) Imported: {asset_name}")
            else:
                failed += 1
                unreal.log_warning(f"[PMCImport] ({i + 1}/{total}) FAILED: {asset_name}")

    unreal.log("=" * 60)
    unreal.log(
        f"[PMCImport] Done — imported {imported}, skipped {skipped} existing, "
        f"failed {failed}, total candidates {total}"
    )
    unreal.log("=" * 60)


if __name__ == "__main__":
    run_import()
