"""Mercenaries 2 Recreation — PMC Base Populate Script

UE 5.7 Editor Python script that spawns actors for the PMC base subset.
Run AFTER import_pmc_base.py has imported the mesh GLBs.

Data sources:
  - output/placements/pmc_base.json       — placement records
  - output/pmc_base_streaming_groups.json  — streaming groups (default_visible)

Usage:
    Edit → Run Python Script → select this file
or:
    unreal.PythonScriptLibrary.execute_python_script(
        "/path/to/mercenaries-game/game-scripts/populate_pmc_base.py")
"""

from __future__ import annotations

import json
import math
import os
import re
import sys
from typing import TYPE_CHECKING

import unreal

# ---------------------------------------------------------------------------
# Local imports — mercs2_data_layers lives alongside this script
# ---------------------------------------------------------------------------

_SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
if _SCRIPT_DIR not in sys.path:
    sys.path.insert(0, _SCRIPT_DIR)

import importlib as _importlib
import mercs2_actor_utils as actor_utils; _importlib.reload(actor_utils)
import mercs2_data_layers as m2dl; _importlib.reload(m2dl)
import mercs2_mesh_utils as mesh_utils; _importlib.reload(mesh_utils)
import mercs2_vz_taxonomy as vz_tax; _importlib.reload(vz_tax)

_TOOLS_DIR_EARLY = os.path.join(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")), "tools")
if _TOOLS_DIR_EARLY not in sys.path:
    sys.path.insert(0, _TOOLS_DIR_EARLY)
import mercs2_coords as _mercs2_coords_mod; _importlib.reload(_mercs2_coords_mod)
from mercs2_coords import game_yaw_to_ue_yaw_deg, game_quat_to_ue_rotator_deg

if TYPE_CHECKING:
    from typing import Optional

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

REPO_ROOT: str = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

CONTENT_BASE: str = "/Game/Mercs2"
DL_ASSET_PACKAGE_DIR: str = f"{CONTENT_BASE}/DataLayers/PMC"
PMC_MESH_ROOT: str = f"{CONTENT_BASE}/Meshes/PMCBase"

GAME_TO_UE: float = 100.0
DEDUP_CELL_SIZE_UE: float = 50.0

LOG_PREFIX = "[PMCPopulate]"

# ---------------------------------------------------------------------------
# Skip patterns — same as populate_world.py but WITHOUT Light_ (lights are actors)
# ---------------------------------------------------------------------------

_SKIP_PATTERNS: list[re.Pattern[str]] = [
    re.compile(r"particle", re.IGNORECASE),
    re.compile(r"spawner", re.IGNORECASE),
    re.compile(r"trigger", re.IGNORECASE),
    re.compile(r"collision", re.IGNORECASE),
]


def _should_skip(entity_name: str) -> bool:
    """Return True if this entity should not be placed (no mesh representation)."""
    for pat in _SKIP_PATTERNS:
        if pat.search(entity_name):
            return True
    return False


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
# Mesh discovery & resolution
# ---------------------------------------------------------------------------

_GENERIC_PATH_SEGMENTS: set[str] = {
    "Interchange",
    "interchange",
    "Materials",
    "Textures",
    "Animations",
}

_GENERIC_SEGMENT_RE: re.Pattern[str] = re.compile(
    r"^(?:" + "|".join(re.escape(s) for s in _GENERIC_PATH_SEGMENTS) + r")$",
    re.IGNORECASE,
)

_BLOCK_FOLDER_RE: re.Pattern[str] = re.compile(
    r"^(?:\d+_blocks__VZ__)?(.+?)(?:_P\d+_Q\d+)?(?:\.block|_block)?$",
    re.IGNORECASE,
)


def _placement_game_xyz(p: dict) -> tuple[float, float, float]:
    """Read game-space position from placement JSON (dict or legacy flat keys)."""
    pos = p.get("position")
    if isinstance(pos, dict):
        return (
            float(pos.get("x", 0.0)),
            float(pos.get("y", 0.0)),
            float(pos.get("z", 0.0)),
        )
    return (
        float(p.get("position_x", 0.0)),
        float(p.get("position_y", 0.0)),
        float(p.get("position_z", 0.0)),
    )


def _canonical_from_path(mesh_path: str) -> str:
    """Extract a canonical mesh name from a UE content path.

    Skips generic Interchange/Materials segments and extracts the logical
    name from a block folder pattern when present.
    """
    parts = mesh_path.replace("\\", "/").split("/")
    for part in reversed(parts):
        if _GENERIC_SEGMENT_RE.match(part):
            continue
        m = _BLOCK_FOLDER_RE.match(part)
        if m:
            return m.group(1).lower()
        if part and part != "." and part != "..":
            return part.lower()
    return parts[-1].lower() if parts else ""


def get_imported_meshes_pmc() -> list[str]:
    """Scan PMC_MESH_ROOT and return content paths of all StaticMesh assets."""
    ar = unreal.AssetRegistryHelpers.get_asset_registry()
    meshes: list[str] = []

    assets = ar.get_assets_by_path(PMC_MESH_ROOT, recursive=True)
    for asset_data in assets:
        if asset_data.asset_class_path.asset_name == "StaticMesh":
            meshes.append(str(asset_data.package_name))
    return meshes


def build_mesh_lookup(mesh_paths: list[str]) -> dict[str, str]:
    """Build a canonical-name → content-path lookup from discovered meshes."""
    lookup: dict[str, str] = {}
    for path in mesh_paths:
        canon = _canonical_from_path(path)
        if canon not in lookup:
            lookup[canon] = path
    return lookup


def resolve_mesh(
    entity_name: str,
    lookup: dict[str, str],
) -> Optional[str]:
    """Attempt to resolve an entity name to an imported mesh content path."""
    name_lower = entity_name.lower().strip()

    if name_lower in lookup:
        return lookup[name_lower]

    cleaned = re.sub(r"\s+0x[0-9a-fA-F]+$", "", name_lower).strip()
    if cleaned in lookup:
        return lookup[cleaned]

    stripped = re.sub(r"^_+", "", cleaned)
    if stripped in lookup:
        return lookup[stripped]

    for key, path in lookup.items():
        if key in cleaned or cleaned in key:
            return path

    return None


# ---------------------------------------------------------------------------
# Coordinate conversion
# ---------------------------------------------------------------------------

def game_to_ue(x: float, y: float, z: float) -> unreal.Vector:
    """Convert game coordinates (Y-up) to UE coordinates (Z-up).

    Game: X=East/West, Y=Elevation, Z=North/South
    UE:   X=East/West, Y=North/South, Z=Elevation
    """
    return unreal.Vector(x * GAME_TO_UE, z * GAME_TO_UE, y * GAME_TO_UE)


def _spawn_actor_at(
    actor_class: type,
    loc: unreal.Vector,
    rot: unreal.Rotator,
) -> Optional[unreal.Actor]:
    """Spawn and force world transform (see populate_world._spawn_actor_at)."""
    cls = actor_class.static_class()
    actor: Optional[unreal.Actor] = None
    try:
        sub = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
        actor = sub.spawn_actor_from_class(cls, loc, rot)
    except Exception:
        actor = None
    if actor is None:
        actor = unreal.EditorLevelLibrary.spawn_actor_from_class(actor_class, loc, rot)
    if actor is None:
        return None
    actor.set_actor_location(loc, False, False)
    actor.set_actor_rotation(rot, False)
    return actor


def placement_to_rotator(p: dict) -> unreal.Rotator:
    """Convert a placement record's rotation to a UE Rotator (pitch, yaw, roll).

    Priority: full quaternion > rotation_y_rad > rotation_y_sin > legacy rot_sin/rot_cos.
    The binary stores a unit quaternion; qy=sin(yaw/2), qw=cos(yaw/2).
    """
    # Full quaternion (new extraction format with all 4 components)
    if "rotation_quat_w" in p:
        qx = float(p.get("rotation_quat_x", 0.0))
        qy = float(p.get("rotation_quat_y", 0.0))
        qz = float(p.get("rotation_quat_z", 0.0))
        qw = float(p.get("rotation_quat_w", 1.0))
        pitch, yaw, roll = game_quat_to_ue_rotator_deg(qx, qy, qz, qw)
        return unreal.Rotator(roll=roll, pitch=pitch, yaw=yaw)

    # Pre-computed yaw (half-angle aware in newer extractions)
    if "rotation_y_rad" in p:
        yaw_ue = game_yaw_to_ue_yaw_deg(float(p["rotation_y_rad"]))
        return unreal.Rotator(roll=0.0, pitch=0.0, yaw=yaw_ue)

    # vz_state: single sin(yaw)
    if "rotation_y_sin" in p:
        s = float(p["rotation_y_sin"])
        c = float(p.get("rotation_y_cos", math.sqrt(max(0.0, 1.0 - s * s))))
        yaw_rad = math.atan2(s, c)
        yaw_ue = game_yaw_to_ue_yaw_deg(yaw_rad)
        return unreal.Rotator(roll=0.0, pitch=0.0, yaw=yaw_ue)

    # Legacy: rot_sin/rot_cos are quaternion half-angles
    if "rot_sin" in p and "rot_cos" in p:
        yaw_rad = 2.0 * math.atan2(float(p["rot_sin"]), float(p["rot_cos"]))
        yaw_ue = game_yaw_to_ue_yaw_deg(yaw_rad)
        return unreal.Rotator(roll=0.0, pitch=0.0, yaw=yaw_ue)

    # Legacy: rotation_y_deg (old format, potentially rounded)
    if "rotation_y_deg" in p:
        yaw_ue = game_yaw_to_ue_yaw_deg(math.radians(float(p["rotation_y_deg"])))
        return unreal.Rotator(roll=0.0, pitch=0.0, yaw=yaw_ue)

    return unreal.Rotator(roll=0.0, pitch=0.0, yaw=0.0)


# ---------------------------------------------------------------------------
# Visibility classification
# ---------------------------------------------------------------------------

_HIDDEN_CACHE: Optional[set[str]] = None


def _load_streaming_hidden_sources() -> set[str]:
    """Load pmc_base_streaming_groups.json and collect source names where
    default_visible is False."""
    global _HIDDEN_CACHE
    if _HIDDEN_CACHE is not None:
        return _HIDDEN_CACHE

    sg_path = os.path.join(REPO_ROOT, "output", "pmc_base_streaming_groups.json")
    hidden: set[str] = set()

    if os.path.isfile(sg_path):
        try:
            with open(sg_path, "r", encoding="utf-8") as fh:
                groups = json.load(fh)
            if isinstance(groups, list):
                for group in groups:
                    if not group.get("default_visible", True):
                        for src in group.get("sources", []):
                            hidden.add(str(src).lower())
            elif isinstance(groups, dict):
                for _key, group in groups.items():
                    if isinstance(group, dict) and not group.get("default_visible", True):
                        for src in group.get("sources", []):
                            hidden.add(str(src).lower())
            _log(f"Loaded {len(hidden)} hidden sources from streaming groups")
        except Exception as exc:
            _warn(f"Failed to load streaming groups: {exc}")
    else:
        _warn(f"Streaming groups file not found: {sg_path}")

    _HIDDEN_CACHE = hidden
    return hidden


def classify_visibility(p: dict) -> tuple[bool, str]:
    """Classify a placement as (editor_hidden, reason).

    Returns (False, "visible") for always-visible entities.
    """
    source = str(p.get("source", "")).lower()

    if not source or "layers_static" in source:
        return False, "base_world"

    hidden_sources = _load_streaming_hidden_sources()
    if source in hidden_sources:
        return True, "streaming_hidden"

    if "_destroyed" in source or "_ruined" in source:
        return True, "destroyed"
    if "_staging" in source or "_combat" in source or "_defenses" in source:
        return True, "mission"
    if "_pristine" in source:
        return False, "pristine"

    return False, "visible"


# ---------------------------------------------------------------------------
# Actor helpers
# ---------------------------------------------------------------------------

def sanitize_name(name: str) -> str:
    """Replace characters illegal in UE actor/asset names with underscores."""
    s = re.sub(r"[^A-Za-z0-9_]", "_", name)
    s = re.sub(r"_+", "_", s).strip("_")
    if s and s[0].isdigit():
        s = f"M_{s}"
    return s or "Unnamed"


class SpatialDedup:
    """Grid-based spatial deduplication to avoid placing overlapping actors."""

    def __init__(self, cell_size: float = DEDUP_CELL_SIZE_UE) -> None:
        self._cell_size = cell_size
        self._cells: set[tuple[str, int, int, int]] = set()

    def try_place(self, mesh_name: str, loc: unreal.Vector) -> bool:
        """Return True if this (mesh, cell) has not been seen yet."""
        cx = int(loc.x / self._cell_size)
        cy = int(loc.y / self._cell_size)
        cz = int(loc.z / self._cell_size)
        key = (mesh_name, cx, cy, cz)
        if key in self._cells:
            return False
        self._cells.add(key)
        return True

    @property
    def placed_count(self) -> int:
        return len(self._cells)


def place_mesh(
    mesh_path: str,
    loc: unreal.Vector,
    rot: unreal.Rotator,
    scale: unreal.Vector,
    label: str,
    folder: str,
    data_layer: Optional[unreal.DataLayerInstance],
    editor_hidden: bool,
    *,
    label_index: actor_utils.ActorLabelIndex | None = None,
) -> Optional[unreal.Actor]:
    """Spawn or update a StaticMeshActor with a stable Outliner label."""
    actor, _created = actor_utils.place_or_update_static_mesh(
        _spawn_actor_at,
        mesh_path,
        loc,
        rot,
        scale,
        label,
        folder,
        data_layer,
        editor_hidden,
        label_index=label_index,
    )
    return actor


def _point_light_color_from_ecs(r: float, g: float, b: float) -> unreal.Color:
    """Convert ECS LightObject RGB floats (0-1 range) to unreal.Color (0-255)."""
    return unreal.Color(
        r=int(max(0.0, min(1.0, r)) * 255),
        g=int(max(0.0, min(1.0, g)) * 255),
        b=int(max(0.0, min(1.0, b)) * 255),
        a=255,
    )


def place_light_from_placement(
    p: dict,
    label: str,
    folder: str,
    data_layer: Optional[unreal.DataLayerInstance],
    editor_hidden: bool,
    *,
    label_index: actor_utils.ActorLabelIndex | None = None,
) -> Optional[unreal.Actor]:
    """Spawn or update a PointLight from a placement with ecs.LightObject data."""
    ecs = p.get("ecs", {})
    light_obj = ecs.get("LightObject", {})
    if not light_obj and not str(p.get("entity_name", "")).lower().startswith("light_"):
        return None

    x, y, z = _placement_game_xyz(p)
    loc = game_to_ue(x, y, z)

    r = float(light_obj.get("r", light_obj.get("light_color_r", light_obj.get("color_r", 1.0))))
    g = float(light_obj.get("g", light_obj.get("light_color_g", light_obj.get("color_g", 1.0))))
    b = float(light_obj.get("b", light_obj.get("light_color_b", light_obj.get("color_b", 1.0))))
    color = _point_light_color_from_ecs(r, g, b)
    radius = float(
        light_obj.get("light_radius", light_obj.get("radius", light_obj.get("attenuation_radius", 500.0)))
    )
    intensity = float(
        light_obj.get("light_intensity", light_obj.get("intensity", light_obj.get("brightness", 5000.0)))
    )

    actor, _created = actor_utils.place_or_update_point_light(
        _spawn_actor_at,
        loc,
        color,
        intensity,
        radius * GAME_TO_UE,
        label,
        folder,
        data_layer,
        editor_hidden,
        label_index=label_index,
    )
    return actor


def _add_actor_to_data_layer_if_any(
    actor: unreal.Actor,
    data_layer: Optional[unreal.DataLayerInstance],
) -> None:
    """Delegate to m2dl for data layer assignment."""
    m2dl.add_actor_to_data_layer_if_any(actor, data_layer)


def _load_pmc_bbox() -> tuple[float, float, float, float] | None:
    """PMC base bbox from output/pmc_base_streaming_groups.json (game metres)."""
    path = os.path.join(REPO_ROOT, "output", "pmc_base_streaming_groups.json")
    if not os.path.isfile(path):
        return None
    try:
        with open(path, encoding="utf-8") as fh:
            doc = json.load(fh)
        bb = doc.get("bbox_game_units", {})
        lo = bb.get("min", {})
        hi = bb.get("max", {})
        return (
            float(lo.get("x", 0)),
            float(lo.get("z", 0)),
            float(hi.get("x", 0)),
            float(hi.get("z", 0)),
        )
    except Exception:
        return None


def _pmc_bbox_filter(bbox: tuple[float, float, float, float] | None):
    """Return a filter that keeps placements inside the PMC base XZ bbox."""
    if bbox is None:
        return None
    x0, z0, x1, z1 = bbox

    def _inside(p: dict) -> bool:
        xyz = _placement_game_xyz(p)
        if xyz is None:
            return False
        x, _, z = xyz
        return x0 <= x <= x1 and z0 <= z <= z1

    return _inside



# ---------------------------------------------------------------------------
# Data Layers — PMC_ prefix to avoid collision with world layers
# ---------------------------------------------------------------------------

_VZ_STATE_SRC_RE: re.Pattern[str] = re.compile(
    r"vz_state_(.+?)_P\d+_Q\d+",
    re.IGNORECASE,
)


def _pmc_ensure_data_layer_cached(
    label: str,
    cache: dict[str, Optional[unreal.DataLayerInstance]],
    *,
    parent: Optional[unreal.DataLayerInstance] = None,
) -> Optional[unreal.DataLayerInstance]:
    if label not in cache:
        cache[label] = m2dl.get_or_create_data_layer_instance(
            label,
            parent=parent,
            asset_package_dir=DL_ASSET_PACKAGE_DIR,
        )
    return cache[label]


def _build_pmc_vz_source_data_layers(
    vz_sources: set[str],
) -> dict[str, unreal.DataLayerInstance]:
    """Create PMC Act/Region/Overlay data layer hierarchy."""
    layer_cache: dict[str, Optional[unreal.DataLayerInstance]] = {}
    source_to_layer: dict[str, unreal.DataLayerInstance] = {}

    for source in sorted(vz_sources):
        parent_label, region_label, leaf_label = vz_tax.pmc_data_layer_hierarchy(source)
        parent_inst = _pmc_ensure_data_layer_cached(parent_label, layer_cache)
        parent_for_leaf = parent_inst
        if region_label:
            parent_for_leaf = _pmc_ensure_data_layer_cached(
                region_label, layer_cache, parent=parent_inst,
            )
        leaf = _pmc_ensure_data_layer_cached(
            leaf_label, layer_cache, parent=parent_for_leaf,
        )
        if leaf is not None:
            source_to_layer[source] = leaf

    _log(f"Created {len(source_to_layer)} PMC vz_state data layers")
    return source_to_layer


def _apply_pmc_vz_data_layer_initial_states(
    source_to_layer: dict[str, unreal.DataLayerInstance],
) -> None:
    """Set initial states: Act1 + pristine visible; others hidden/unloaded."""
    hidden_sources = _load_streaming_hidden_sources()

    for source, layer in source_to_layer.items():
        info = vz_tax.parse_overlay_source(source)
        activated = vz_tax.initial_runtime_activated(info)
        should_hide = (
            source in hidden_sources
            or not activated
            or info.parent_kind in (
                "destroyed", "staging", "defenses", "act2", "act3", "contract",
            )
        )
        m2dl.configure_data_layer_for_pie(
            layer,
            activated=activated and not should_hide,
            loaded_in_editor=activated,
        )
        sub = m2dl.data_layer_editor_subsystem()
        if sub is not None:
            try:
                sub.set_data_layer_is_initially_visible(layer, not should_hide)
            except Exception:
                pass

    m2dl.set_act_parent_states(
        act_states={
            1: unreal.DataLayerRuntimeState.ACTIVATED,
            2: unreal.DataLayerRuntimeState.UNLOADED,
            3: unreal.DataLayerRuntimeState.UNLOADED,
        },
        prefix="PMC_VZ",
    )


def _data_layer_for_placement(
    p: dict,
    base_world: Optional[unreal.DataLayerInstance],
    vz_source_to_layer: dict[str, unreal.DataLayerInstance],
) -> Optional[unreal.DataLayerInstance]:
    """Pick the right data layer for a placement record."""
    source = str(p.get("source", ""))
    if not source or "layers_static" in source.lower():
        return base_world
    return vz_source_to_layer.get(source)


def _ue_folder_for_placement_pmc(p: dict, vis: str) -> str:
    """Build the UE Outliner folder path for a PMC placement."""
    source = str(p.get("source", ""))

    if not source or "layers_static" in source.lower():
        return "World/PMC/Base"

    info = vz_tax.parse_overlay_source(source)
    if info.act is not None:
        region = info.region or "Other"
        return f"World/PMC/Act{info.act}/{region}/{sanitize_name(info.stem)}"
    group_map = {
        "pristine": "VZ_Pristine",
        "destroyed": "VZ_Destroyed",
        "staging": "VZ_Staging",
        "defenses": "VZ_Defenses",
        "captured": "VZ_Captured",
        "contract": "VZ_Contract",
    }
    group = group_map.get(info.parent_kind, "VZ_Other")
    return f"World/PMC/{group}/{sanitize_name(info.stem)}"


# ---------------------------------------------------------------------------
# Data loading
# ---------------------------------------------------------------------------

def _load_placements() -> list[dict]:
    """Load pmc_base.json placement records."""
    path = os.path.join(REPO_ROOT, "output", "placements", "pmc_base.json")
    if not os.path.isfile(path):
        _err(f"Placement file not found: {path}")
        return []

    with open(path, "r", encoding="utf-8") as fh:
        data = json.load(fh)

    if isinstance(data, dict):
        records = data.get("placements", data.get("records", []))
    elif isinstance(data, list):
        records = data
    else:
        _err("Unexpected pmc_base.json format")
        return []

    _log(f"Loaded {len(records)} placement records")
    return records


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def run() -> None:
    """Populate the PMC base subset in the current editor level."""
    _log("=" * 60)
    _log("PMC Base Populate — starting")
    _log("=" * 60)

    world = m2dl.ensure_mercs2_editor_world_ready(log_title="PMCPopulate")
    if world is None:
        return

    label_index = actor_utils.ActorLabelIndex.build()
    _log(f"Actor label index: {len(label_index)} existing level actors")

    # Load placements
    placements = _load_placements()
    if not placements:
        _err("No placements loaded — aborting")
        return

    # Discover imported meshes
    mesh_paths = get_imported_meshes_pmc()
    if not mesh_paths:
        _warn("No meshes found in PMC_MESH_ROOT — placement will be limited to lights")
    mesh_lookup = build_mesh_lookup(mesh_paths)
    _log(f"Mesh lookup: {len(mesh_lookup)} canonical entries from {len(mesh_paths)} assets")

    # Create base world data layer
    base_world = m2dl.get_or_create_data_layer_instance(
        "PMC_BaseWorld",
        asset_package_dir=DL_ASSET_PACKAGE_DIR,
    )

    # Collect vz_state sources and build data layers
    vz_sources: set[str] = set()
    for p in placements:
        source = str(p.get("source", ""))
        if source and "layers_static" not in source.lower():
            vz_sources.add(source)

    vz_source_to_layer: dict[str, unreal.DataLayerInstance] = {}
    if vz_sources:
        _log(f"Building data layers for {len(vz_sources)} vz_state sources")
        vz_source_to_layer = _build_pmc_vz_source_data_layers(vz_sources)
        _apply_pmc_vz_data_layer_initial_states(vz_source_to_layer)

    # Place entities
    dedup = SpatialDedup()
    placed_mesh = 0
    mesh_reused = 0
    placed_light = 0
    lights_reused = 0
    skipped_no_mesh = 0
    skipped_pattern = 0
    skipped_dedup = 0
    total = len(placements)

    with unreal.ScopedSlowTask(total, "Populating PMC Base...") as task:
        task.make_dialog(True)

        for i, p in enumerate(placements):
            if task.should_cancel():
                _warn(f"Cancelled by user at {i}/{total}")
                break

            task.enter_progress_frame(1, f"({i + 1}/{total})")

            entity_name = str(p.get("entity_name", p.get("name", "")))
            entity_id = str(p.get("entity_id", f"unk_{i}"))

            if _should_skip(entity_name):
                skipped_pattern += 1
                continue

            editor_hidden, vis = classify_visibility(p)
            data_layer = _data_layer_for_placement(p, base_world, vz_source_to_layer)
            folder = _ue_folder_for_placement_pmc(p, vis)

            is_light = entity_name.lower().startswith("light_")
            ecs = p.get("ecs", {})
            has_light_obj = "LightObject" in ecs

            if is_light or has_light_obj:
                label = sanitize_name(entity_name or f"Light_{entity_id}")
                had_light = actor_utils.actor_exists(label, label_index)
                actor = place_light_from_placement(
                    p, label, folder, data_layer, editor_hidden,
                    label_index=label_index,
                )
                if actor is not None:
                    if had_light:
                        lights_reused += 1
                    else:
                        placed_light += 1
                continue

            mesh_path = resolve_mesh(entity_name, mesh_lookup)
            if mesh_path is None:
                skipped_no_mesh += 1
                continue

            x, y, z = _placement_game_xyz(p)
            loc = game_to_ue(x, y, z)
            rot = placement_to_rotator(p)
            scale = unreal.Vector(1.0, 1.0, 1.0)
            label = sanitize_name(entity_name or entity_id)

            canon = _canonical_from_path(mesh_path)
            if not dedup.try_place(canon, loc):
                skipped_dedup += 1
                continue

            had_mesh = actor_utils.actor_exists(label, label_index)
            place_mesh(
                mesh_path, loc, rot, scale, label, folder,
                data_layer, editor_hidden,
                label_index=label_index,
            )
            if had_mesh:
                mesh_reused += 1
            else:
                placed_mesh += 1

    _log("=" * 60)
    _log("PMC Base Populate — summary")
    _log(f"  Mesh actors placed:    {placed_mesh} (updated: {mesh_reused})")
    _log(f"  Light actors placed:   {placed_light} (updated: {lights_reused})")
    _log(f"  Skipped (no mesh):     {skipped_no_mesh}")
    _log(f"  Skipped (pattern):     {skipped_pattern}")
    _log(f"  Skipped (dedup):       {skipped_dedup}")
    _log(f"  Total placements:      {total}")
    _log(f"  Data layers created:   {len(vz_source_to_layer)}")
    _log("=" * 60)


if __name__ == "__main__":
    run()
