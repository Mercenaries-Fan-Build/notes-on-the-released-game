"""Mercenaries 2 Recreation — Full World Populate

UE 5.7 Editor Python script that places 62k+ static world meshes and ECS-
sourced point lights into the level from extracted placement data.

Reads:
    output/placements/layers_static.json   — 62k+ always-visible placements
    output/placements/vz_state/all_vz_state.json — ~3500 conditional overlays

Run AFTER import_world.py (meshes must already be imported).

Usage:
    Edit → Run Python Script → select this file
    or from Editor console:
        unreal.PythonScriptLibrary.execute_python_script(
            "/path/to/mercenaries-game/game-scripts/populate_world.py")
"""
from __future__ import annotations

import json
import math
import os
import re
import sys
from collections import Counter
from typing import TYPE_CHECKING, Literal

import unreal

if TYPE_CHECKING:
    from typing import Optional

_SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
if _SCRIPT_DIR not in sys.path:
    sys.path.insert(0, _SCRIPT_DIR)
import mercs2_data_layers as m2dl

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

REPO_ROOT: str = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
CONTENT_BASE = "/Game/Mercs2"
DL_ASSET_PACKAGE_DIR = f"{CONTENT_BASE}/DataLayers/World"

CATEGORY_FOLDERS: dict[str, str] = {
    "building": "Buildings",
    "maracaibo": "Maracaibo",
    "vehicle": "Vehicles",
    "road": "Roads",
    "environment": "Environment",
    "world_layer": "WorldLayers",
    "other": "Other",
}

GAME_TO_UE = 100.0

DEDUP_CELL_SIZE_UE = 50.0

WORLD_MIN_X, WORLD_MAX_X = -3900.0, 3850.0
WORLD_MIN_Z, WORLD_MAX_Z = -3900.0, 3850.0
WORLD_MIN_Y, WORLD_MAX_Y = -150.0, 450.0

WALL_HEIGHT_UE = 50000.0
WALL_THICKNESS_UE = 500.0

QUAT_NON_YAW_WARN_THRESHOLD = 0.08

LOG_PREFIX = "[Mercs2World]"

# ---------------------------------------------------------------------------
# Skip patterns — entities with no mesh representation
# ---------------------------------------------------------------------------

_SKIP_PATTERNS = re.compile(
    r"particle|munitions\s*spawner|waypoint|trigger|fow_|ai_?collision|blocker|spawn_?point",
    re.IGNORECASE,
)

# lrterrain_rXX_cYY — 400 tile placements; geometry is merged into one low_res_terrain mesh at origin.
_LR_TERRAIN_TILE_RE = re.compile(r"^lrterrain_r\d+_c\d+$", re.IGNORECASE)


def _is_lrterrain_tile_entity(entity_name: str) -> bool:
    if not entity_name:
        return False
    return bool(_LR_TERRAIN_TILE_RE.match(entity_name.strip().lstrip("_")))


# ---------------------------------------------------------------------------
# Mesh-discovery helpers
# ---------------------------------------------------------------------------

_GENERIC_PATH_SEGMENTS: frozenset[str] = frozenset({
    "staticmeshes", "skeletalmeshes", "materials", "textures",
    "mesh_scene", "meshes", "buildings", "vehicles", "roads",
    "environment", "maracaibo", "other", "worldlayers", "pmcbase",
    "game", "mercs2", "content",
})

_GENERIC_SEGMENT_RE = re.compile(
    r"^(mesh_scene|staticmeshes|skeletalmeshes|materials|textures)(_auto\d+)?$",
    re.IGNORECASE,
)

_BLOCK_FOLDER_RE = re.compile(
    r"^(?:a_)?\d+_blocks__vz__(.+?)(?:_p\d{3}_q\d+)?(?:_block)?$",
    re.IGNORECASE,
)

# ---------------------------------------------------------------------------
# vz_state source pattern
# ---------------------------------------------------------------------------

_VZ_STATE_SRC_RE = re.compile(
    r"^(\d+)_blocks__VZ__vz_state_(.+?)_P(\d{3})_Q(\d+)",
    re.IGNORECASE,
)

# ---------------------------------------------------------------------------
# Module-level warning-once flags
# ---------------------------------------------------------------------------

_warned_quat_non_yaw: bool = False

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------


def _log(msg: str) -> None:
    unreal.log(f"{LOG_PREFIX} {msg}")


def _warn(msg: str) -> None:
    unreal.log_warning(f"{LOG_PREFIX} {msg}")


def _err(msg: str) -> None:
    unreal.log_error(f"{LOG_PREFIX} {msg}")


# ---------------------------------------------------------------------------
# JSON loader
# ---------------------------------------------------------------------------


def _load_json_placements(path: str) -> list[dict]:
    """Load placement JSON — handles both raw list and dict-with-"placements"-key."""
    if not os.path.isfile(path):
        _err(f"Placement file not found: {path}")
        return []
    with open(path, "r", encoding="utf-8") as fh:
        data = json.load(fh)
    if isinstance(data, list):
        return data
    if isinstance(data, dict):
        return data.get("placements", [])
    return []


# ---------------------------------------------------------------------------
# Name sanitisation
# ---------------------------------------------------------------------------


def sanitize_name(name: str) -> str:
    """Produce a safe UE asset/actor name from an arbitrary string."""
    out = name.replace(" ", "_").replace("-", "_").replace(".", "_")
    out = re.sub(r"[^A-Za-z0-9_]", "", out)
    if out and out[0].isdigit():
        out = f"A_{out}"
    return out[:120]


# ---------------------------------------------------------------------------
# Visibility classification
# ---------------------------------------------------------------------------


def classify_visibility(p: dict) -> Literal["visible", "hidden", "skip"]:
    """Determine whether a placement should be visible, hidden, or skipped."""
    entity = p.get("entity_name") or ""
    if _SKIP_PATTERNS.search(entity):
        return "skip"

    source = p.get("source", "")
    if not source or source == "layers_static":
        return "visible"

    src_lower = source.lower()
    if "pristine" in src_lower:
        return "visible"
    if any(tag in src_lower for tag in (
        "ruined", "destroyed", "rubble",
        "staging", "combat", "defenses",
        "act1", "act2", "act3",
    )):
        return "hidden"

    return "hidden"


# ---------------------------------------------------------------------------
# Mesh canonical-name helpers
# ---------------------------------------------------------------------------


def _canonical_from_path(mesh_path: str) -> str:
    """Extract a canonical descriptor from a UE asset path.

    Walks path segments in reverse, skips generic/empty ones, and tries to
    extract the meaningful descriptor from a block-folder segment.  Falls back
    to stripping ``_auto\\d+$`` from the leaf.
    """
    parts = mesh_path.replace("\\", "/").split("/")
    for seg in reversed(parts):
        if not seg:
            continue
        seg_lower = seg.lower()
        if seg_lower in _GENERIC_PATH_SEGMENTS:
            continue
        if _GENERIC_SEGMENT_RE.match(seg):
            continue
        m = _BLOCK_FOLDER_RE.match(seg)
        if m:
            return m.group(1).lower()
        return re.sub(r"_auto\d+$", "", seg, flags=re.IGNORECASE).lower()
    return mesh_path.rsplit("/", 1)[-1].lower()


# ---------------------------------------------------------------------------
# Mesh lookup building & resolution
# ---------------------------------------------------------------------------


def get_imported_meshes(*categories: str) -> list[str]:
    """Scan ``/Game/Mercs2/Meshes/{folder}`` for StaticMesh assets.

    Uses the asset registry (same approach as ``populate_pmc_base``) so nested
    Interchange output paths are found reliably.
    """
    ar = unreal.AssetRegistryHelpers.get_asset_registry()
    seen: set[str] = set()
    results: list[str] = []

    if categories:
        scan_roots = [
            f"{CONTENT_BASE}/Meshes/{CATEGORY_FOLDERS.get(cat, cat)}"
            for cat in categories
        ]
    else:
        scan_roots = [f"{CONTENT_BASE}/Meshes"]

    for scan_path in scan_roots:
        try:
            assets = ar.get_assets_by_path(scan_path, recursive=True)
        except Exception:
            continue
        for asset_data in assets:
            if asset_data.asset_class_path.asset_name != "StaticMesh":
                continue
            path = str(asset_data.package_name)
            if path in seen:
                continue
            seen.add(path)
            results.append(path)

    if results:
        return results

    # Fallback for older projects / registry refresh lag
    eal = unreal.EditorAssetLibrary
    for scan_path in scan_roots:
        if not eal.does_directory_exist(scan_path):
            continue
        for asset_path in eal.list_assets(scan_path, recursive=True, include_folder=False):
            obj = eal.load_asset(str(asset_path))
            if obj is not None and isinstance(obj, unreal.StaticMesh):
                p = str(asset_path)
                if p not in seen:
                    seen.add(p)
                    results.append(p)
    return results


def build_mesh_lookup(all_meshes: list[str]) -> dict[str, str]:
    """Map canonical name → asset path (first occurrence wins)."""
    lookup: dict[str, str] = {}
    for path in all_meshes:
        canon = _canonical_from_path(path)
        if canon not in lookup:
            lookup[canon] = path
    return lookup


def _entity_name_variants(entity_name: str) -> list[str]:
    """Yield normalized entity-name keys to match imported block stems."""
    cleaned = entity_name.lower().strip()
    cleaned = re.sub(r"\s+0x[0-9a-fA-F]+$", "", cleaned).strip()
    variants: list[str] = []
    seen: set[str] = set()

    def add(v: str) -> None:
        v = v.strip().lstrip("_")
        if v and v not in seen:
            seen.add(v)
            variants.append(v)

    add(cleaned)
    add(cleaned.replace(" ", "_"))
    # Common game prefab prefixes (Name component) vs FFCS block stems
    for prefix in (
        "global_", "jungle_", "maracaibo_", "city_", "outskirt_", "oil_",
        "pmc_", "civ_", "ch_", "al_", "pr_", "vz_",
    ):
        if cleaned.startswith(prefix):
            add(cleaned[len(prefix):])
    if "_env_" in cleaned:
        add(cleaned.replace("_env_", "_"))
    return variants


def resolve_mesh(
    entity_name: str,
    mesh_lookup: dict[str, str],
    all_meshes: list[str],
) -> str | None:
    """Resolve an entity_name to an imported mesh asset path.

    Placement ``entity_name`` values are usually **game prefab** names
    (e.g. ``_jungle_env_plantlarge04``), not FFCS block stems. Only a small
    subset match imported GLBs (vehicles, buildings, terrain). Most world props
    live inside **c3XXXX** cell geometry and are not imported by ``import_world``.

    Only exact canonical matches (after ``_entity_name_variants``) are accepted.
    Fuzzy substring/token matching previously stacked hundreds of unrelated
    props onto one building mesh at the same spawn point.
    """
    del all_meshes  # kept for call-site compatibility
    if not entity_name:
        return None

    for variant in _entity_name_variants(entity_name):
        if variant in mesh_lookup:
            return mesh_lookup[variant]
    return None


def _log_import_vs_placement_gap(
    placements: list[dict],
    mesh_lookup: dict[str, str],
    all_meshes: list[str],
) -> None:
    """Explain why most placements will not spawn meshes (one-time diagnostic)."""
    if not placements:
        return

    would_mesh = 0
    would_light = 0
    would_skip = 0
    for p in placements:
        entity = p.get("entity_name") or ""
        if p.get("ecs", {}).get("LightObject"):
            would_light += 1
            continue
        if classify_visibility(p) == "skip":
            would_skip += 1
            continue
        if _is_lrterrain_tile_entity(entity):
            continue
        if resolve_mesh(entity, mesh_lookup, all_meshes):
            would_mesh += 1

    _log(
        f"Placement analysis: {len(placements)} records — "
        f"~{would_light} lights, ~{would_mesh} match imported meshes, "
        f"~{len(placements) - would_light - would_mesh - would_skip} props with no imported mesh"
    )
    _log(
        f"Imported StaticMesh assets: {len(all_meshes)} "
        f"({len(mesh_lookup)} canonical names). "
        "import_world only imports mesh_scene.glb blocks (~vehicles/buildings/terrain), "
        "not c3XXXX world-cell props."
    )
    if would_mesh < 100 and len(all_meshes) < 300:
        _warn(
            "Very few placements match imported meshes. Entity names in layers_static "
            "are game prefab IDs; most geometry lives in c3 cell blocks (mesh_scene.gltf). "
            "Expect lights + terrain + a handful of buildings/vehicles until prop/cell import exists."
        )
    if "low_res_terrain" not in mesh_lookup:
        _warn(
            "low_res_terrain not in mesh lookup — run make extract-terrain, "
            "import_world (MERCS2_FORCE_TERRAIN=1 if needed), then populate again."
        )


# ---------------------------------------------------------------------------
# Coordinate conversion
# ---------------------------------------------------------------------------


def game_to_ue(x: float, y: float, z: float) -> unreal.Vector:
    """Game Y-up → UE Z-up, metres → centimetres."""
    return unreal.Vector(x * GAME_TO_UE, z * GAME_TO_UE, y * GAME_TO_UE)


def placement_to_ue_location(p: dict) -> unreal.Vector:
    """Placement record → UE world location (metres → cm, Y-up → Z-up)."""
    pos = p.get("position")
    if isinstance(pos, dict):
        return game_to_ue(
            float(pos.get("x", 0.0)),
            float(pos.get("y", 0.0)),
            float(pos.get("z", 0.0)),
        )
    return game_to_ue(
        float(p.get("position_x", 0.0)),
        float(p.get("position_y", 0.0)),
        float(p.get("position_z", 0.0)),
    )


def _spawn_actor_at(
    actor_class: type,
    loc: unreal.Vector,
    rot: unreal.Rotator,
) -> unreal.Actor | None:
    """Spawn an actor and force its world transform.

    UE 5.7 often logs ``Attempting to add actor …`` at a fixed editor/cursor
    location while ignoring the ``location`` argument passed here. Always call
    ``set_actor_location`` / ``set_actor_rotation`` after spawn so placements
    use extracted game coordinates.
    """
    cls = actor_class.static_class()
    actor: unreal.Actor | None = None
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
    """Extract yaw rotation from a placement record and return a Rotator."""
    global _warned_quat_non_yaw

    if "rotation_y_deg" in p:
        return unreal.Rotator(0.0, float(p["rotation_y_deg"]), 0.0)

    if "rotation_y_rad" in p:
        return unreal.Rotator(0.0, math.degrees(float(p["rotation_y_rad"])), 0.0)

    if "rot_sin" in p and "rot_cos" in p:
        yaw_rad = math.atan2(float(p["rot_sin"]), float(p["rot_cos"]))
        return unreal.Rotator(0.0, math.degrees(yaw_rad), 0.0)

    if "rotation_y_sin" in p:
        s = float(p["rotation_y_sin"])
        c = float(p.get("rotation_y_cos", math.sqrt(max(0.0, 1.0 - s * s))))
        yaw_rad = math.atan2(s, c)
        return unreal.Rotator(0.0, math.degrees(yaw_rad), 0.0)

    qx = float(p.get("rotation_quat_x", 0.0))
    qz = float(p.get("rotation_quat_z", 0.0))
    qy = float(p.get("rotation_quat_y", 0.0))
    qw = float(p.get("rotation_quat_w", 1.0))

    if (abs(qx) > QUAT_NON_YAW_WARN_THRESHOLD or abs(qz) > QUAT_NON_YAW_WARN_THRESHOLD):
        if not _warned_quat_non_yaw:
            _warn(
                f"Non-trivial quaternion pitch/roll detected "
                f"(qx={qx:.3f}, qz={qz:.3f}) — only yaw extracted"
            )
            _warned_quat_non_yaw = True

    yaw_rad = math.atan2(2.0 * (qw * qy - qx * qz), 1.0 - 2.0 * (qx * qx + qy * qy))
    return unreal.Rotator(0.0, math.degrees(yaw_rad), 0.0)


# ---------------------------------------------------------------------------
# Spatial deduplication
# ---------------------------------------------------------------------------


class SpatialDedup:
    """Cell-based spatial deduplication to avoid stacking actors."""

    def __init__(self, cell_size: float = DEDUP_CELL_SIZE_UE) -> None:
        self._cell_size = cell_size
        self._occupied: set[tuple[int, int, int]] = set()

    def try_occupy(self, loc: unreal.Vector) -> bool:
        """Return True if the cell is newly occupied, False if already taken."""
        cx = int(loc.x // self._cell_size)
        cy = int(loc.y // self._cell_size)
        cz = int(loc.z // self._cell_size)
        key = (cx, cy, cz)
        if key in self._occupied:
            return False
        self._occupied.add(key)
        return True


# ---------------------------------------------------------------------------
# Actor helpers
# ---------------------------------------------------------------------------


def find_actor_by_label(label: str) -> unreal.Actor | None:
    """Search the current level for an actor with the given label."""
    for actor in m2dl.iter_all_level_actors():
        if actor.get_actor_label() == label:
            return actor
    return None


def actor_exists(label: str) -> bool:
    return find_actor_by_label(label) is not None


def _add_actor_to_data_layer_if_any(
    actor: unreal.Actor,
    data_layer: unreal.DataLayerInstance | None,
) -> None:
    m2dl.add_actor_to_data_layer_if_any(actor, data_layer)


# ---------------------------------------------------------------------------
# Mesh placement
# ---------------------------------------------------------------------------


def place_mesh(
    mesh_path: str,
    loc: unreal.Vector,
    rot: unreal.Rotator,
    scale: unreal.Vector,
    label: str,
    folder: str,
    data_layer: unreal.DataLayerInstance | None,
    editor_hidden: bool = False,
) -> unreal.StaticMeshActor | None:
    """Spawn a StaticMeshActor, configure it, and return it."""
    actor = _spawn_actor_at(unreal.StaticMeshActor, loc, rot)
    if actor is None:
        return None

    mesh = unreal.EditorAssetLibrary.load_asset(mesh_path)
    if mesh is not None:
        actor.static_mesh_component.set_static_mesh(mesh)

    actor.set_actor_location(loc, False, False)
    actor.set_actor_rotation(rot, False)
    actor.set_actor_scale3d(scale)
    actor.set_actor_label(label)
    actor.set_folder_path(folder)

    if editor_hidden:
        actor.set_is_temporarily_hidden_in_editor(True)

    _add_actor_to_data_layer_if_any(actor, data_layer)
    return actor


# ---------------------------------------------------------------------------
# Light helpers
# ---------------------------------------------------------------------------


def _point_light_color_from_ecs(r: float, g: float, b: float) -> unreal.Color:
    """Convert 0-1 float RGB to uint8 sRGB ``unreal.Color``.

    UE 5.7 PointLightComponent.light_color requires Color (uint8), NOT
    LinearColor.
    """
    return unreal.Color(
        r=max(0, min(255, int(r * 255.0))),
        g=max(0, min(255, int(g * 255.0))),
        b=max(0, min(255, int(b * 255.0))),
        a=255,
    )


def place_light_from_placement(
    p: dict,
    label: str,
    folder: str,
    data_layer: unreal.DataLayerInstance | None,
    editor_hidden: bool = False,
) -> unreal.PointLight | None:
    """Spawn a PointLight from an ECS LightObject record."""
    ecs = p.get("ecs", {})
    light_data = ecs.get("LightObject", {})
    if not light_data:
        return None

    loc = placement_to_ue_location(p)
    rot = unreal.Rotator()

    actor = _spawn_actor_at(unreal.PointLight, loc, rot)
    if actor is None:
        return None

    comp = actor.point_light_component

    comp.set_editor_property("mobility", unreal.ComponentMobility.MOVABLE)

    r = float(light_data.get("r", 1.0))
    g = float(light_data.get("g", 1.0))
    b = float(light_data.get("b", 1.0))
    comp.set_editor_property("light_color", _point_light_color_from_ecs(r, g, b))

    intensity = float(light_data.get("intensity", 5000.0))
    comp.set_editor_property("intensity", intensity)

    radius = float(light_data.get("attenuation_radius", 10.0))
    comp.set_editor_property("attenuation_radius", radius * GAME_TO_UE)

    actor.set_actor_label(label)
    actor.set_folder_path(folder)

    if editor_hidden:
        actor.set_is_temporarily_hidden_in_editor(True)

    _add_actor_to_data_layer_if_any(actor, data_layer)
    return actor


# ---------------------------------------------------------------------------
# Lighting & atmosphere setup
# ---------------------------------------------------------------------------


def setup_lighting() -> None:
    """Create or find the main scene lighting actors (Sun, Atmosphere, Fog, Sky)."""
    _log("Setting up scene lighting ...")

    # --- Sun (Directional Light) — must exist before atmosphere for sun disc ---
    sun = find_actor_by_label("Sun_Tropical")
    if sun is None:
        sun = unreal.EditorLevelLibrary.spawn_actor_from_class(
            unreal.DirectionalLight,
            unreal.Vector(0.0, 0.0, 50000.0),
            unreal.Rotator(168.0, -59.0, 0.0),
        )
        if sun is not None:
            sun.set_actor_label("Sun_Tropical")
            sun.set_folder_path("Lighting")
            comp = sun.get_component_by_class(unreal.DirectionalLightComponent)
            if comp is not None:
                comp.set_editor_property("mobility", unreal.ComponentMobility.MOVABLE)
                comp.set_editor_property("intensity", 22.0)
                comp.set_editor_property("atmosphere_sun_light", True)
                comp.set_editor_property("atmosphere_sun_light_index", 0)
                comp.set_editor_property("cast_shadows", True)
                comp.set_editor_property("use_temperature", True)
                comp.set_editor_property("temperature", 5500.0)
            _log("  Created Sun_Tropical")
    else:
        _log("  Sun_Tropical already exists")

    # --- SkyAtmosphere — needs to exist before SkyLight captures ---
    atmo = find_actor_by_label("Atmosphere_World")
    if atmo is None:
        atmo = unreal.EditorLevelLibrary.spawn_actor_from_class(
            unreal.SkyAtmosphere,
            unreal.Vector(0.0, 0.0, 0.0),
            unreal.Rotator(),
        )
        if atmo is not None:
            atmo.set_actor_label("Atmosphere_World")
            atmo.set_folder_path("Lighting")
            _log("  Created Atmosphere_World")
    else:
        _log("  Atmosphere_World already exists")

    # --- ExponentialHeightFog — gives ambient scattering and haze ---
    fog = find_actor_by_label("HeightFog_World")
    if fog is None:
        fog = unreal.EditorLevelLibrary.spawn_actor_from_class(
            unreal.ExponentialHeightFog,
            unreal.Vector(0.0, 0.0, 3000.0),
            unreal.Rotator(),
        )
        if fog is not None:
            fog.set_actor_label("HeightFog_World")
            fog.set_folder_path("Lighting")
            fog_comp = fog.get_component_by_class(unreal.ExponentialHeightFogComponent)
            if fog_comp is not None:
                fog_comp.set_editor_property("fog_density", 0.02)
            _log("  Created HeightFog_World")
    else:
        _log("  HeightFog_World already exists")

    # --- SkyLight — last so it captures atmosphere + fog ---
    sky = find_actor_by_label("SkyLight_World")
    if sky is None:
        sky = unreal.EditorLevelLibrary.spawn_actor_from_class(
            unreal.SkyLight,
            unreal.Vector(0.0, 0.0, 50000.0),
            unreal.Rotator(),
        )
        if sky is not None:
            sky.set_actor_label("SkyLight_World")
            sky.set_folder_path("Lighting")
            comp = sky.get_component_by_class(unreal.SkyLightComponent)
            if comp is not None:
                comp.set_editor_property("mobility", unreal.ComponentMobility.MOVABLE)
                comp.set_editor_property(
                    "source_type",
                    unreal.SkyLightSourceType.SLS_CAPTURED_SCENE,
                )
                comp.set_editor_property("real_time_capture", True)
                comp.set_editor_property("lower_hemisphere_is_black", False)
                comp.set_editor_property("intensity", 1.0)
                try:
                    comp.recapture_sky()
                except Exception:
                    pass
            _log("  Created SkyLight_World")
    else:
        _log("  SkyLight_World already exists")


# ---------------------------------------------------------------------------
# Boundary walls
# ---------------------------------------------------------------------------


def _spawn_blocking_wall(
    label: str,
    center: unreal.Vector,
    extent: unreal.Vector,
    base_world_layer: unreal.DataLayerInstance | None,
) -> None:
    """Spawn an invisible blocking-volume wall using /Engine/BasicShapes/Cube."""
    if actor_exists(label):
        return

    rot = unreal.Rotator()
    actor = _spawn_actor_at(unreal.StaticMeshActor, center, rot)
    if actor is None:
        _warn(f"Failed to spawn wall: {label}")
        return

    actor.set_actor_location(center, False, False)

    cube = unreal.EditorAssetLibrary.load_asset("/Engine/BasicShapes/Cube")
    if cube is not None:
        actor.static_mesh_component.set_static_mesh(cube)

    actor.set_actor_scale3d(extent)
    actor.set_actor_label(label)
    actor.set_folder_path("World/Boundaries")

    actor.static_mesh_component.set_editor_property("visible", False)
    actor.static_mesh_component.set_collision_profile_name("BlockAll")

    _add_actor_to_data_layer_if_any(actor, base_world_layer)
    _log(f"  Wall: {label}")


def create_boundary_walls(base_world_layer: unreal.DataLayerInstance | None) -> None:
    """Create N/S/E/W invisible blocking walls at world bounds."""
    _log("Creating boundary walls ...")

    cx = (WORLD_MIN_X + WORLD_MAX_X) * 0.5 * GAME_TO_UE
    cz = (WORLD_MIN_Z + WORLD_MAX_Z) * 0.5 * GAME_TO_UE
    cy_center = (WORLD_MIN_Y + WORLD_MAX_Y) * 0.5 * GAME_TO_UE

    width_x = (WORLD_MAX_X - WORLD_MIN_X) * GAME_TO_UE
    width_z = (WORLD_MAX_Z - WORLD_MIN_Z) * GAME_TO_UE

    north_z = WORLD_MAX_Z * GAME_TO_UE
    south_z = WORLD_MIN_Z * GAME_TO_UE
    east_x = WORLD_MAX_X * GAME_TO_UE
    west_x = WORLD_MIN_X * GAME_TO_UE

    scale_wall_height = WALL_HEIGHT_UE / 100.0
    scale_thick = WALL_THICKNESS_UE / 100.0

    _spawn_blocking_wall(
        "Wall_North",
        unreal.Vector(cx, north_z, cy_center),
        unreal.Vector(width_x / 100.0, scale_thick, scale_wall_height),
        base_world_layer,
    )
    _spawn_blocking_wall(
        "Wall_South",
        unreal.Vector(cx, south_z, cy_center),
        unreal.Vector(width_x / 100.0, scale_thick, scale_wall_height),
        base_world_layer,
    )
    _spawn_blocking_wall(
        "Wall_East",
        unreal.Vector(east_x, cz, cy_center),
        unreal.Vector(scale_thick, width_z / 100.0, scale_wall_height),
        base_world_layer,
    )
    _spawn_blocking_wall(
        "Wall_West",
        unreal.Vector(west_x, cz, cy_center),
        unreal.Vector(scale_thick, width_z / 100.0, scale_wall_height),
        base_world_layer,
    )


# ---------------------------------------------------------------------------
# vz_state Data-Layer helpers
# ---------------------------------------------------------------------------


def _vz_parent_label_from_source_lower(source_lower: str) -> str:
    """Map a lowercase vz_state source name to its parent Data Layer label."""
    if "pristine" in source_lower:
        return "VZ_Pristine"
    if any(t in source_lower for t in ("destroyed", "ruined", "rubble")):
        return "VZ_Destroyed"
    if any(t in source_lower for t in ("staging", "defenses")):
        return "VZ_Staging"
    if any(t in source_lower for t in ("combat", "act1", "act2", "act3", "mission")):
        return "VZ_Mission"
    return "VZ_Other"


def _vz_child_data_layer_label(source: str) -> tuple[str, str]:
    """Return ``(parent_label, child_label)`` for a vz_state source string."""
    src_lower = source.lower()
    parent = _vz_parent_label_from_source_lower(src_lower)

    m = _VZ_STATE_SRC_RE.match(source)
    if m:
        child = f"VZ_{m.group(2)}"
    else:
        child = f"VZ_{sanitize_name(source)}"

    return parent, child


def _build_vz_source_data_layers(
    vz_sources: set[str],
) -> dict[str, unreal.DataLayerInstance | None]:
    """Create parent + child DataLayerInstances for each unique vz_state source.

    Returns a dict mapping source string → DataLayerInstance (or None on
    failure).
    """
    parent_cache: dict[str, unreal.DataLayerInstance | None] = {}
    result: dict[str, unreal.DataLayerInstance | None] = {}

    for source in sorted(vz_sources):
        parent_label, child_label = _vz_child_data_layer_label(source)

        if parent_label not in parent_cache:
            parent_cache[parent_label] = m2dl.get_or_create_data_layer_instance(
                parent_label,
                asset_package_dir=DL_ASSET_PACKAGE_DIR,
            )

        parent = parent_cache[parent_label]
        layer = m2dl.get_or_create_data_layer_instance(
            child_label,
            parent=parent,
            asset_package_dir=DL_ASSET_PACKAGE_DIR,
        )
        result[source] = layer

    _log(f"Created {len(result)} vz_state data layers under {len(parent_cache)} parents")
    return result


def _apply_vz_data_layer_initial_states(
    vz_source_to_layer: dict[str, unreal.DataLayerInstance | None],
    vz_placements: list[dict],
) -> None:
    """Set initial loaded_in_editor + visibility for each vz_state data layer.

    Pristine layers are loaded; everything else starts unloaded.
    """
    sub = m2dl.data_layer_editor_subsystem()

    applied: set[str] = set()
    for p in vz_placements:
        source = p.get("source", "")
        if source in applied or source not in vz_source_to_layer:
            continue
        layer = vz_source_to_layer[source]
        if layer is None:
            continue

        src_lower = source.lower()
        is_pristine = "pristine" in src_lower

        try:
            sub.set_data_layer_is_loaded_in_editor(layer, is_pristine)
        except Exception:
            pass
        try:
            state = (
                unreal.DataLayerRuntimeState.ACTIVATED
                if is_pristine
                else unreal.DataLayerRuntimeState.UNLOADED
            )
            sub.set_data_layer_runtime_state(layer, state)
        except Exception:
            pass

        applied.add(source)


# ---------------------------------------------------------------------------
# Per-placement folder / data-layer routing
# ---------------------------------------------------------------------------


def _ue_folder_for_placement(p: dict) -> str:
    """Return the Outliner folder path for a placement record."""
    source = p.get("source", "")
    if not source or source == "layers_static":
        return "World/Base"

    src_lower = source.lower()
    parent = _vz_parent_label_from_source_lower(src_lower)

    m = _VZ_STATE_SRC_RE.match(source)
    child = m.group(2) if m else sanitize_name(source)

    return f"World/{parent}/{child}"


def _data_layer_for_placement(
    p: dict,
    base_world: unreal.DataLayerInstance | None,
    vz_source_to_layer: dict[str, unreal.DataLayerInstance | None],
) -> unreal.DataLayerInstance | None:
    """Return the appropriate data layer for a placement record."""
    source = p.get("source", "")
    if not source or source == "layers_static":
        return base_world
    return vz_source_to_layer.get(source)


# ---------------------------------------------------------------------------
# Main placement loop
# ---------------------------------------------------------------------------


def populate_placements(
    all_placements: list[dict],
    mesh_lookup: dict[str, str],
    all_meshes: list[str],
    *,
    merged_terrain_mesh: str | None = None,
) -> dict:
    """Place all meshes and lights into the level. Returns stats dict.

    When *merged_terrain_mesh* is set (imported ``low_res_terrain`` StaticMesh path),
    one actor is spawned at the world origin and every ``lrterrain_r*_c*`` tile
    placement is skipped (tile transforms are baked into the merged mesh).
    """
    _log(f"Populating {len(all_placements)} placements ...")

    # --- Data layers ---
    base_world = m2dl.get_or_create_data_layer_instance(
        "Mercs2_BaseWorld",
        asset_package_dir=DL_ASSET_PACKAGE_DIR,
    )

    vz_sources: set[str] = set()
    for p in all_placements:
        src = p.get("source", "")
        if src and src != "layers_static":
            vz_sources.add(src)

    vz_source_to_layer = _build_vz_source_data_layers(vz_sources)
    _apply_vz_data_layer_initial_states(
        vz_source_to_layer,
        [p for p in all_placements if p.get("source", "") != "layers_static"],
    )

    # --- Stats ---
    mesh_placed = 0
    lights_placed = 0
    skip_no_mesh = 0
    skip_vis = 0
    skip_dedup = 0
    skip_terrain_tile = 0
    terrain_merged_placed = 0
    terrain_skipping_active = False
    by_mesh: Counter[str] = Counter()
    by_vis: Counter[str] = Counter()
    sample_mesh_logs = 0

    dedup = SpatialDedup()
    total = len(all_placements)

    if merged_terrain_mesh:
        loc0 = game_to_ue(0.0, 0.0, 0.0)
        t_actor = place_mesh(
            merged_terrain_mesh,
            loc0,
            unreal.Rotator(0.0, 0.0, 0.0),
            unreal.Vector(1.0, 1.0, 1.0),
            "Mercs2_LowResTerrain",
            "Terrain",
            base_world,
            False,
        )
        if t_actor is not None:
            terrain_merged_placed = 1
            mesh_placed += 1
            by_mesh[merged_terrain_mesh] += 1
            terrain_skipping_active = True
            _log(
                f"Placed merged low_res_terrain at origin (world-space mesh; "
                f"re-run make extract-terrain + import if tiles were stacked) → {merged_terrain_mesh}"
            )
        else:
            _warn("Merged low_res_terrain actor spawn failed — import mesh_scene.glb via import_world first")

    for idx, p in enumerate(all_placements):
        if idx > 0 and idx % 5000 == 0:
            _log(
                f"  Progress: {idx}/{total} — "
                f"meshes={mesh_placed}, lights={lights_placed}, "
                f"skipped(vis={skip_vis}, mesh={skip_no_mesh}, dedup={skip_dedup})"
            )

        vis = classify_visibility(p)
        by_vis[vis] += 1
        if vis == "skip":
            skip_vis += 1
            continue

        editor_hidden = vis == "hidden"
        folder = _ue_folder_for_placement(p)
        data_layer = _data_layer_for_placement(p, base_world, vz_source_to_layer)

        loc = placement_to_ue_location(p)

        entity_name = p.get("entity_name") or ""
        entity_id = p.get("entity_id") or ""
        label = sanitize_name(f"{entity_name}_{entity_id}")

        if terrain_skipping_active and _is_lrterrain_tile_entity(entity_name):
            skip_terrain_tile += 1
            continue

        # --- ECS Light ---
        ecs = p.get("ecs", {})
        if ecs.get("LightObject"):
            if not dedup.try_occupy(loc):
                skip_dedup += 1
                continue
            light = place_light_from_placement(
                p, label, folder, data_layer, editor_hidden,
            )
            if light is not None:
                lights_placed += 1
            continue

        # --- Mesh ---
        mesh_path = resolve_mesh(entity_name, mesh_lookup, all_meshes)
        if mesh_path is None:
            skip_no_mesh += 1
            continue

        if not dedup.try_occupy(loc):
            skip_dedup += 1
            continue

        rot = placement_to_rotator(p)
        actor = place_mesh(
            mesh_path, loc, rot,
            unreal.Vector(1.0, 1.0, 1.0),
            label, folder, data_layer, editor_hidden,
        )
        if actor is not None:
            mesh_placed += 1
            by_mesh[mesh_path] += 1
            if sample_mesh_logs < 5:
                pos = p.get("position", {})
                if isinstance(pos, dict):
                    _log(
                        f"  Mesh sample: {entity_name[:48]} → "
                        f"game=({pos.get('x', 0):.1f}, {pos.get('y', 0):.1f}, {pos.get('z', 0):.1f}) "
                        f"ue=({loc.x:.0f}, {loc.y:.0f}, {loc.z:.0f})"
                    )
                sample_mesh_logs += 1

    stats = {
        "total": total,
        "mesh_placed": mesh_placed,
        "lights_placed": lights_placed,
        "skip_vis": skip_vis,
        "skip_no_mesh": skip_no_mesh,
        "skip_dedup": skip_dedup,
        "skip_terrain_tile": skip_terrain_tile,
        "terrain_merged_placed": terrain_merged_placed,
        "by_mesh": by_mesh,
        "by_vis": by_vis,
    }
    return stats


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------


def run() -> None:
    """Populate the full Mercenaries 2 world — main entry point."""
    _log("=" * 60)
    _log("Mercenaries 2 Recreation — Full World Populate")
    _log("=" * 60)

    world = m2dl.ensure_mercs2_editor_world_ready(log_title="Mercs2World")
    if world is None:
        return

    # --- Base world data layer ---
    base_world = m2dl.get_or_create_data_layer_instance(
        "Mercs2_BaseWorld",
        asset_package_dir=DL_ASSET_PACKAGE_DIR,
    )
    if base_world is not None:
        sub = m2dl.data_layer_editor_subsystem()
        try:
            sub.set_data_layer_is_loaded_in_editor(base_world, True)
        except Exception:
            pass
        try:
            sub.set_data_layer_runtime_state(
                base_world, unreal.DataLayerRuntimeState.ACTIVATED,
            )
        except Exception:
            pass
        _log("Base world data layer: Mercs2_BaseWorld (loaded + visible)")

    # --- Lighting ---
    setup_lighting()

    # --- Boundary walls ---
    create_boundary_walls(base_world)

    # --- Gather imported meshes ---
    _log("Scanning imported meshes ...")
    all_categories = list(CATEGORY_FOLDERS.keys())
    all_meshes = get_imported_meshes(*all_categories)
    _log(f"Found {len(all_meshes)} imported StaticMesh assets")

    mesh_lookup = build_mesh_lookup(all_meshes)
    sample_keys = list(mesh_lookup.keys())[:8]
    _log(f"Sample canonical names: {sample_keys}")

    # --- Load placements ---
    static_path = os.path.join(REPO_ROOT, "output", "placements", "layers_static.json")
    static_placements = _load_json_placements(static_path)
    _log(f"Loaded {len(static_placements)} layers_static placements")

    vz_path = os.path.join(REPO_ROOT, "output", "placements", "vz_state", "all_vz_state.json")
    vz_placements = _load_json_placements(vz_path)
    _log(f"Loaded {len(vz_placements)} vz_state placements")

    # Tag sources for routing
    for p in static_placements:
        p.setdefault("source", "layers_static")
    for p in vz_placements:
        p.setdefault("source", p.get("source", "vz_state"))

    all_placements = static_placements + vz_placements
    _log(f"Total placements to process: {len(all_placements)}")

    _log_import_vs_placement_gap(all_placements, mesh_lookup, all_meshes)

    merged_terrain = mesh_lookup.get("low_res_terrain")
    if merged_terrain:
        _log(f"Merged terrain mesh available — will skip lrterrain_r*_c* tiles ({merged_terrain})")
    else:
        _log("No merged low_res_terrain in project — run `make extract-terrain` then import_world")

    # --- Populate ---
    stats = populate_placements(
        all_placements, mesh_lookup, all_meshes,
        merged_terrain_mesh=merged_terrain,
    )

    # --- Summary ---
    _log("=" * 60)
    _log("Populate complete")
    _log(f"  Meshes placed:   {stats['mesh_placed']}")
    _log(f"  Lights placed:   {stats['lights_placed']}")
    _log(f"  Skipped (vis):   {stats['skip_vis']}")
    _log(f"  Skipped (mesh):  {stats['skip_no_mesh']}")
    _log(f"  Skipped (dedup): {stats['skip_dedup']}")
    _log(f"  Skipped (terrain tiles, merged mesh): {stats['skip_terrain_tile']}")
    if stats["mesh_placed"] < 50 and stats["lights_placed"] > 500:
        _warn(
            "Level is mostly lights because placement entity_name values do not map to "
            "the ~100–230 mesh_scene.glb imports. This is expected until c3 prop/cell "
            "geometry is imported or an entity→mesh table is built."
        )
    _log(f"  Visibility breakdown: {dict(stats['by_vis'])}")

    top_meshes = stats["by_mesh"].most_common(10)
    if top_meshes:
        _log("  Top 10 meshes by placement count:")
        for mesh_path, count in top_meshes:
            _log(f"    {count:>5d}  {mesh_path}")
    _log("=" * 60)


if __name__ == "__main__":
    run()
