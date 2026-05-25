"""Mercenaries 2 — populate a filtered radius zone in the editor level.

Run AFTER ``import_radius_zone.py`` (or import_pmc_base with MERCS2_ASSET_LIST set).

Build the zone package first::

    make filter-pool-200m OUTPUT=./output

Then in UE5 (Tools → Execute Python Script)::

    game-scripts/import_radius_zone.py
    game-scripts/populate_radius_zone.py

Environment:
  MERCS2_RADIUS_ZONE   Path to zone.json (default: output/radius_zones/pool_200m/zone.json)
  MERCS2_POPULATE_C3_CELLS  Set 1 to place c3 world-cell meshes listed in zone.json
"""

from __future__ import annotations

import json
import math
import os
import re
import sys
from typing import TYPE_CHECKING, Optional

import unreal

_SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
if _SCRIPT_DIR not in sys.path:
    sys.path.insert(0, _SCRIPT_DIR)

import importlib as _importlib

import mercs2_actor_utils as actor_utils
import mercs2_data_layers as m2dl
import mercs2_radius_zone as rz
import mercs2_vz_taxonomy as vz_tax

_importlib.reload(actor_utils)
_importlib.reload(m2dl)
_importlib.reload(rz)
_importlib.reload(vz_tax)

_REPO_ROOT = os.path.abspath(os.path.join(_SCRIPT_DIR, ".."))
_TOOLS_DIR = os.path.join(_REPO_ROOT, "tools")
if _TOOLS_DIR not in sys.path:
    sys.path.insert(0, _TOOLS_DIR)

import mercs2_coords as _mercs2_coords_mod

_importlib.reload(_mercs2_coords_mod)
from mercs2_coords import game_quat_to_ue_rotator_deg, game_yaw_to_ue_yaw_deg

# Reuse PMC populate helpers (same coordinate + mesh rules).
import populate_pmc_base as pmc

_importlib.reload(pmc)

if TYPE_CHECKING:
    pass

LOG_PREFIX = "[RadiusZone]"

GAME_TO_UE = pmc.GAME_TO_UE
_SKIP_PATTERNS = pmc._SKIP_PATTERNS
_should_skip = pmc._should_skip
_placement_game_xyz = pmc._placement_game_xyz
game_to_ue = pmc.game_to_ue
placement_to_rotator = pmc.placement_to_rotator
classify_visibility = pmc.classify_visibility
sanitize_name = pmc.sanitize_name
SpatialDedup = pmc.SpatialDedup
place_mesh = pmc.place_mesh
place_light_from_placement = pmc.place_light_from_placement
build_mesh_lookup = pmc.build_mesh_lookup
resolve_mesh = pmc.resolve_mesh
_canonical_from_path = pmc._canonical_from_path
_spawn_actor_at = pmc._spawn_actor_at


def _log(msg: str) -> None:
    unreal.log(f"{LOG_PREFIX} {msg}")


def _warn(msg: str) -> None:
    unreal.log_warning(f"{LOG_PREFIX} {msg}")


def _err(msg: str) -> None:
    unreal.log_error(f"{LOG_PREFIX} {msg}")


def _env_truthy(name: str, default: bool = False) -> bool:
    val = os.environ.get(name, "")
    if not val:
        return default
    return val.strip().lower() in ("1", "true", "yes", "on")


def _load_zone() -> dict:
    zpath = rz.zone_json_path()
    if not zpath.is_file():
        _err(f"Zone manifest not found: {zpath}")
        _err("Run: make filter-pool-200m OUTPUT=./output")
        return {}
    return rz.load_zone(zpath)


def _load_submesh_prop_index(zone: dict) -> dict[str, str]:
    """Load submesh_prop_index.json and build a normalized name → GLB path lookup.

    The index maps ``texture_diffuse`` stems to GLB files.  Entity names
    like ``_global_env_rockjungle03`` typically match a texture stem after
    stripping the leading ``_`` and lowercasing.  We build several
    normalised variants for each stem to maximise exact-match coverage.
    """
    submesh_glbs_dir = os.environ.get("MERCS2_SUBMESH_GLBS", "")
    if not submesh_glbs_dir:
        zone_path = rz.zone_json_path()
        submesh_glbs_dir = str(rz.output_root(zone_path) / "submesh_glbs")

    index_path = os.path.join(submesh_glbs_dir, "submesh_prop_index.json")
    if not os.path.isfile(index_path):
        _log(f"No submesh prop index at {index_path} — submesh resolution disabled")
        return {}

    with open(index_path, encoding="utf-8") as fh:
        doc = json.load(fh)

    props = doc.get("props", {})
    lookup: dict[str, str] = {}
    for tex_stem, meta in props.items():
        glb_path = meta.get("glb_path", "")
        if not glb_path or not os.path.isfile(glb_path):
            continue
        ts = tex_stem.lower().strip()
        lookup[ts] = glb_path
        stripped = ts.lstrip("_")
        if stripped != ts:
            lookup[stripped] = glb_path

    _log(f"Submesh prop index: {len(lookup)} entries from {len(props)} props")
    return lookup


def _resolve_mesh_with_submesh(
    entity_name: str,
    mesh_lookup: dict[str, str],
    submesh_lookup: dict[str, str],
) -> str | None:
    """Try standard mesh resolution first, then fall back to submesh prop index.

    No substring/fuzzy matching — only deterministic normalisation.
    """
    result = resolve_mesh(entity_name, mesh_lookup)
    if result is not None:
        return result

    if not submesh_lookup:
        return None

    name = entity_name.lower().strip()
    if name in submesh_lookup:
        return submesh_lookup[name]

    cleaned = re.sub(r"\s+0x[0-9a-fA-F]+$", "", name).strip()
    if cleaned in submesh_lookup:
        return submesh_lookup[cleaned]

    stripped = cleaned.lstrip("_")
    if stripped in submesh_lookup:
        return submesh_lookup[stripped]

    no_prefix = re.sub(r"^(global_|jungle_|outskirt_)", "", stripped)
    if no_prefix != stripped and no_prefix in submesh_lookup:
        return submesh_lookup[no_prefix]

    return None


def _load_zone_placements(zone: dict) -> list[dict]:
    rel = zone.get("paths", {}).get("placements", "")
    if not rel:
        _err("zone.json missing paths.placements")
        return []
    path = rz.resolve_data_path(rel, rz.zone_json_path())
    if not path.is_file():
        _err(f"Placements file not found: {path}")
        return []
    with path.open(encoding="utf-8") as fh:
        data = json.load(fh)
    if isinstance(data, list):
        records = data
    else:
        records = data.get("placements", data.get("records", []))
    _log(f"Loaded {len(records)} zone placements from {path}")
    return records


def _mesh_roots_from_zone(zone: dict) -> list[str]:
    primary = zone.get("ue_mesh_root", "/Game/Mercs2/Meshes/RadiusZones/pool_200m")
    roots = [primary]
    if _env_truthy("MERCS2_RADIUS_USE_WORLD_MESHES", default=True):
        extra = os.environ.get(
            "MERCS2_WORLD_MESH_ROOT",
            "/Game/Mercs2/Meshes/World",
        )
        if extra not in roots:
            roots.append(extra)
    pmc = os.environ.get("MERCS2_PMC_MESH_ROOT", "/Game/Mercs2/Meshes/PMCBase")
    if _env_truthy("MERCS2_RADIUS_USE_PMC_MESHES", default=True) and pmc not in roots:
        roots.append(pmc)
    return roots


def _dl_dir_from_zone(zone: dict) -> str:
    return zone.get("ue_data_layer_dir", "/Game/Mercs2/DataLayers/RadiusZones")


def _get_imported_meshes(mesh_root: str) -> list[str]:
    ar = unreal.AssetRegistryHelpers.get_asset_registry()
    meshes: list[str] = []
    for asset_data in ar.get_assets_by_path(mesh_root, recursive=True):
        if asset_data.asset_class_path.asset_name == "StaticMesh":
            meshes.append(str(asset_data.package_name))
    return meshes


def _load_streaming_hidden_sources(zone: dict) -> set[str]:
    rel = zone.get("paths", {}).get("streaming_groups", "")
    if not rel:
        return set()
    path = rz.resolve_data_path(rel, rz.zone_json_path())
    hidden: set[str] = set()
    if not path.is_file():
        return hidden
    try:
        with path.open(encoding="utf-8") as fh:
            doc = json.load(fh)
        for group in doc.get("groups", []):
            if not group.get("default_visible", True):
                for src in group.get("sources", group.get("vz_state_sources", [])):
                    hidden.add(str(src).lower())
    except Exception as exc:
        _warn(f"streaming_groups load failed: {exc}")
    return hidden


def _classify_visibility_zone(p: dict, hidden_sources: set[str]) -> tuple[bool, str]:
    source = str(p.get("source", "")).lower()
    if not source or "layers_static" in source:
        return False, "base_world"
    if source in hidden_sources:
        return True, "streaming_hidden"
    return classify_visibility(p)


def _data_layer_for_placement(
    p: dict,
    base_world: Optional[unreal.DataLayerInstance],
    vz_source_to_layer: dict[str, unreal.DataLayerInstance],
    zone_id: str,
) -> Optional[unreal.DataLayerInstance]:
    source = str(p.get("source", ""))
    if not source or "layers_static" in source.lower():
        return base_world
    return vz_source_to_layer.get(source)


def _ue_folder_for_placement(p: dict, zone_id: str, vis: str) -> str:
    source = str(p.get("source", ""))
    if not source or "layers_static" in source.lower():
        return f"World/RadiusZones/{zone_id}/Base"
    info = vz_tax.parse_overlay_source(source)
    if info.act is not None:
        region = info.region or "Other"
        return f"World/RadiusZones/{zone_id}/Act{info.act}/{region}/{sanitize_name(info.stem)}"
    return f"World/RadiusZones/{zone_id}/VZ/{sanitize_name(info.stem)}"


def _build_vz_layers(
    vz_sources: set[str],
    dl_dir: str,
    zone_id: str,
) -> dict[str, unreal.DataLayerInstance]:
    layer_cache: dict[str, Optional[unreal.DataLayerInstance]] = {}
    source_to_layer: dict[str, unreal.DataLayerInstance] = {}

    for source in sorted(vz_sources):
        parent_label, region_label, leaf_label = vz_tax.pmc_data_layer_hierarchy(source)
        parent_label = f"RZ_{zone_id}_{parent_label}"
        region_label = f"RZ_{zone_id}_{region_label}" if region_label else None
        leaf_label = f"RZ_{zone_id}_{leaf_label}"

        parent_inst = m2dl.get_or_create_data_layer_instance(
            parent_label, asset_package_dir=dl_dir,
        )
        parent_for_leaf = parent_inst
        if region_label:
            parent_for_leaf = m2dl.get_or_create_data_layer_instance(
                region_label, parent=parent_inst, asset_package_dir=dl_dir,
            )
        leaf = m2dl.get_or_create_data_layer_instance(
            leaf_label, parent=parent_for_leaf, asset_package_dir=dl_dir,
        )
        if leaf is not None:
            source_to_layer[source] = leaf

    _log(f"VZ data layers: {len(source_to_layer)}")
    return source_to_layer



def _populate_c3_cells(
    zone: dict,
    mesh_lookup: dict[str, str],
    base_world: Optional[unreal.DataLayerInstance],
    zone_id: str,
    *,
    label_index: actor_utils.ActorLabelIndex,
) -> int:
    if not _env_truthy("MERCS2_POPULATE_C3_CELLS"):
        _log("c3 cell placement skipped (set MERCS2_POPULATE_C3_CELLS=1 to enable)")
        return 0

    try:
        import c3_cell_grid as c3grid
    except ImportError:
        _warn("c3_cell_grid not found — skip cells")
        return 0

    cell_ids = zone.get("c3_cell_ids", [])
    if not cell_ids:
        return 0

    placed = 0
    seen_cells: set[int] = set()
    for canon, mesh_path in mesh_lookup.items():
        if not c3grid.is_c3_canonical_name(canon):
            continue
        cell_id = c3grid.primary_cell_id_from_stem(canon)
        if cell_id is None or cell_id not in cell_ids:
            continue
        if cell_id in seen_cells:
            continue
        seen_cells.add(cell_id)

        x, y, z = c3grid.cell_id_to_world_xyz(cell_id)
        loc = game_to_ue(x, y, z)
        label = sanitize_name(f"Cell_c3{cell_id - c3grid.CELL_ID_BASE:04d}")
        actor = place_mesh(
            mesh_path, loc, unreal.Rotator(), unreal.Vector(1.0, 1.0, 1.0),
            label, f"World/RadiusZones/{zone_id}/Cells",
            base_world, False, label_index=label_index,
        )
        if actor is not None:
            placed += 1

    _log(f"c3 cells placed: {placed} (zone lists {len(cell_ids)} cell ids)")
    return placed


def run() -> None:
    _log("=" * 60)
    _log("Radius zone populate — starting")
    _log("=" * 60)

    zone = _load_zone()
    if not zone:
        return

    zone_id = str(zone.get("zone_id", "zone"))
    world = m2dl.ensure_mercs2_editor_world_ready(log_title="RadiusZone")
    if world is None:
        return

    placements = _load_zone_placements(zone)
    if not placements:
        return

    mesh_roots = _mesh_roots_from_zone(zone)
    dl_dir = _dl_dir_from_zone(zone)
    mesh_paths: list[str] = []
    for root in mesh_roots:
        mesh_paths.extend(_get_imported_meshes(root))
    if not mesh_paths:
        _warn(
            f"No meshes under {mesh_roots} — run import_radius_zone.py "
            "(and import_world.py for props) first"
        )
    mesh_lookup = build_mesh_lookup(mesh_paths)
    _log(f"Mesh roots: {mesh_roots}")
    _log(f"Mesh lookup: {len(mesh_lookup)} entries from {len(mesh_paths)} assets")

    submesh_lookup = _load_submesh_prop_index(zone)

    label_index = actor_utils.ActorLabelIndex.build()
    hidden_sources = _load_streaming_hidden_sources(zone)

    base_world = m2dl.get_or_create_data_layer_instance(
        f"RZ_{zone_id}_BaseWorld",
        asset_package_dir=dl_dir,
    )

    vz_sources: set[str] = set()
    for p in placements:
        src = str(p.get("source", ""))
        if src and "layers_static" not in src.lower():
            vz_sources.add(src)

    vz_source_to_layer = _build_vz_layers(vz_sources, dl_dir, zone_id) if vz_sources else {}

    dedup = SpatialDedup()

    cells_placed = _populate_c3_cells(
        zone, mesh_lookup, base_world, zone_id, label_index=label_index,
    )

    placed_mesh = 0
    mesh_reused = 0
    placed_light = 0
    skipped_no_mesh = 0
    skipped_pattern = 0
    skipped_dedup = 0
    total = len(placements)

    with unreal.ScopedSlowTask(total, f"Populating radius zone {zone_id}...") as task:
        task.make_dialog(True)
        for i, p in enumerate(placements):
            if task.should_cancel():
                break
            task.enter_progress_frame(1)

            raw_name = p.get("entity_name") or p.get("name") or ""
            if raw_name is None:
                raw_name = ""
            entity_name = str(raw_name).strip()
            entity_id = str(p.get("entity_id", f"unk_{i}"))

            if not entity_name or entity_name.lower() == "none":
                entity_name = entity_id

            if _should_skip(entity_name):
                skipped_pattern += 1
                continue

            editor_hidden, vis = _classify_visibility_zone(p, hidden_sources)
            data_layer = _data_layer_for_placement(
                p, base_world, vz_source_to_layer, zone_id,
            )
            folder = _ue_folder_for_placement(p, zone_id, vis)

            is_light = entity_name.lower().startswith("light_")
            has_light_obj = "LightObject" in (p.get("ecs") or {})

            if is_light or has_light_obj:
                label = sanitize_name(entity_name or f"Light_{entity_id}")
                actor = place_light_from_placement(
                    p, label, folder, data_layer, editor_hidden,
                    label_index=label_index,
                )
                if actor is not None:
                    placed_light += 1
                continue

            mesh_path = _resolve_mesh_with_submesh(
                entity_name, mesh_lookup, submesh_lookup,
            )
            if mesh_path is None:
                skipped_no_mesh += 1
                continue

            x, y, z = _placement_game_xyz(p)
            loc = game_to_ue(x, y, z)
            rot = placement_to_rotator(p)
            label = sanitize_name(f"{entity_name}_{entity_id}" if entity_name != entity_id else entity_id)
            canon = _canonical_from_path(mesh_path)

            if not dedup.try_place(canon, loc):
                skipped_dedup += 1
                continue

            had = actor_utils.actor_exists(label, label_index)
            place_mesh(
                mesh_path, loc, rot, unreal.Vector(1.0, 1.0, 1.0),
                label, folder, data_layer, editor_hidden,
                label_index=label_index,
            )
            if had:
                mesh_reused += 1
            else:
                placed_mesh += 1

    _log("=" * 60)
    _log(f"Zone {zone_id} @ {zone.get('anchor_entity_name')} r={zone.get('radius_m')}m")
    _log(f"  c3 cells:           {cells_placed}")
    _log(f"  Mesh actors:        {placed_mesh} (updated {mesh_reused})")
    _log(f"  Lights:             {placed_light}")
    _log(f"  Skip (no mesh):     {skipped_no_mesh}")
    _log(f"  Skip (pattern):     {skipped_pattern}")
    _log(f"  Skip (dedup):       {skipped_dedup}")
    _log("=" * 60)


if __name__ == "__main__":
    run()
