"""Mercenaries 2 Recreation - PlayerStart placement on the merged terrain.

UE 5.7 Editor Python script that picks a sensible spawn location on top of
the merged ``Mercs2_LowResTerrain`` actor and spawns or moves a single
``APlayerStart`` to that location, oriented to face the map centre.

Strategy:

  1. Find the ``Mercs2_LowResTerrain`` ``StaticMeshActor`` in the open level
     (placed at the world origin by ``populate_world.py``). Fail loud if it
     can't be located.
  2. Read placements from ``output/placements/layers_static.json`` and look
     for a coastal landmark by ``entity_name`` with elevation Y in the
     [-20, 80] m band.  If none found, use the PMC base area coordinates.
  3. Convert the chosen game-space (Y-up, metres) coordinate to UE world
     space (Z-up, centimetres) using the same convention as ``populate_world``
     (``game_to_ue(x, y, z) -> Vector(x*100, z*100, y*100)``).
  4. Line trace from +600 m above to -300 m below at the chosen XY to find
     the actual terrain Z, then add 200 cm of ground clearance.
     **Errors out** if the trace misses — run ``setup_terrain_collision.py``
     first (``setup_all.py`` does this automatically).
  5. Spawn or move a ``APlayerStart`` actor (only one) and set rotation so
     the spawn faces the world origin.

Idempotent: re-running moves the existing PlayerStart instead of creating
a duplicate.

Run via:
    Tools -> Execute Python Script -> setup_player_start.py
"""

from __future__ import annotations

import json
import math
from pathlib import Path
from typing import TYPE_CHECKING

import unreal

if TYPE_CHECKING:
    from typing import Any


LOG_PREFIX = "[Mercs2PlayerStart]"

REPO_ROOT = Path(__file__).resolve().parent.parent
LAYERS_STATIC_JSON = REPO_ROOT / "output" / "placements" / "layers_static.json"

GAME_TO_UE = 100.0  # metres -> centimetres (matches populate_world.py)

TERRAIN_LABEL_HINTS: tuple[str, ...] = (
    "Mercs2_LowResTerrain",
    "LowResTerrain",
    "low_res_terrain",
)
TERRAIN_ASSET_HINT = "low_res_terrain"

LANDMARK_PATTERNS: tuple[str, ...] = (
    "barrancas",
    "parque_central",
    "pmc_base",
    "pmc_hq",
    "airport",
    "fortin",
    "dock",
    "helipad",
    "gas_station",
    "bridge",
    "warehouse",
    "tower",
)

ELEVATION_BAND_MIN_M = -20.0
ELEVATION_BAND_MAX_M = 80.0

TRACE_START_Z_CM = 60_000.0
TRACE_END_Z_CM = -30_000.0
GROUND_CLEARANCE_CM = 200.0

PMC_GAME_X = 2647.0
PMC_GAME_Y = 10.0
PMC_GAME_Z = -951.0


def _log(msg: str) -> None:
    unreal.log(f"{LOG_PREFIX} {msg}")


def _warn(msg: str) -> None:
    unreal.log_warning(f"{LOG_PREFIX} {msg}")


def _err(msg: str) -> None:
    unreal.log_error(f"{LOG_PREFIX} {msg}")


def _game_to_ue(x_m: float, y_m: float, z_m: float) -> unreal.Vector:
    """Game (Y-up, metres) -> UE (Z-up, cm). Matches populate_world.game_to_ue."""
    return unreal.Vector(x_m * GAME_TO_UE, z_m * GAME_TO_UE, y_m * GAME_TO_UE)


def _get_editor_world() -> unreal.World | None:
    try:
        sub = unreal.get_editor_subsystem(unreal.UnrealEditorSubsystem)
        if sub is not None:
            world = sub.get_editor_world()
            if world is not None:
                return world
    except Exception:
        pass
    try:
        return unreal.EditorLevelLibrary.get_editor_world()
    except Exception as exc:
        _err(f"Cannot resolve editor world: {exc}")
        return None


def _all_level_actors() -> list[unreal.Actor]:
    try:
        sub = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
        if sub is not None:
            return list(sub.get_all_level_actors())
    except Exception:
        pass
    try:
        return list(unreal.EditorLevelLibrary.get_all_level_actors())
    except Exception as exc:
        _err(f"Cannot enumerate level actors: {exc}")
        return []


def _find_terrain_actor() -> unreal.StaticMeshActor | None:
    """Locate the merged terrain actor by label or static mesh asset name."""
    actors = _all_level_actors()
    for actor in actors:
        if not isinstance(actor, unreal.StaticMeshActor):
            continue
        try:
            label = actor.get_actor_label() or ""
        except Exception:
            label = ""
        name = actor.get_name() if hasattr(actor, "get_name") else ""
        for hint in TERRAIN_LABEL_HINTS:
            if hint.lower() in label.lower() or hint.lower() in name.lower():
                return actor

    for actor in actors:
        if not isinstance(actor, unreal.StaticMeshActor):
            continue
        try:
            comp = actor.static_mesh_component
            mesh = comp.get_editor_property("static_mesh") if comp else None
        except Exception:
            mesh = None
        if mesh is None:
            continue
        try:
            asset_path = mesh.get_path_name() or ""
        except Exception:
            asset_path = ""
        if TERRAIN_ASSET_HINT in asset_path.lower():
            return actor
    return None


def _load_landmark_placements() -> list[dict]:
    if not LAYERS_STATIC_JSON.is_file():
        _warn(f"layers_static.json not found at {LAYERS_STATIC_JSON} - skipping landmark search")
        return []
    try:
        data = json.loads(LAYERS_STATIC_JSON.read_text(encoding="utf-8"))
    except Exception as exc:
        _warn(f"could not parse layers_static.json: {exc}")
        return []
    placements = data.get("placements") if isinstance(data, dict) else None
    return placements if isinstance(placements, list) else []


def _pick_landmark_spawn(placements: list[dict]) -> tuple[str, float, float, float] | None:
    """Return (landmark_name, game_x, game_y, game_z) for the first viable landmark."""
    for pattern in LANDMARK_PATTERNS:
        for p in placements:
            name = (p.get("entity_name") or "").lower()
            if pattern not in name:
                continue
            pos = p.get("position") or {}
            try:
                gx = float(pos.get("x", 0.0))
                gy = float(pos.get("y", 0.0))
                gz = float(pos.get("z", 0.0))
            except (TypeError, ValueError):
                continue
            if not (ELEVATION_BAND_MIN_M <= gy <= ELEVATION_BAND_MAX_M):
                continue
            return (p.get("entity_name") or pattern, gx, gy, gz)
    return None


def _trace_terrain_z(
    world: unreal.World,
    ue_x_cm: float,
    ue_y_cm: float,
) -> float | None:
    """Single line trace from +600 m to -300 m at (X, Y); returns hit Z (cm)."""
    start = unreal.Vector(ue_x_cm, ue_y_cm, TRACE_START_Z_CM)
    end = unreal.Vector(ue_x_cm, ue_y_cm, TRACE_END_Z_CM)
    try:
        hit_result = unreal.SystemLibrary.line_trace_single(
            world,
            start,
            end,
            unreal.TraceTypeQuery.TRACE_TYPE_QUERY1,  # WorldStatic
            False,
            [],
            unreal.DrawDebugTrace.NONE,
            True,
        )
    except Exception as exc:
        _err(f"line_trace_single raised: {exc}")
        return None

    out_hit = None
    if isinstance(hit_result, tuple) and len(hit_result) >= 2:
        ok, out_hit = hit_result[0], hit_result[1]
        if not ok:
            return None
    elif isinstance(hit_result, bool):
        return None
    else:
        out_hit = hit_result

    if out_hit is None:
        return None
    try:
        loc = out_hit.get_editor_property("location") if hasattr(out_hit, "get_editor_property") else out_hit.location
        return float(loc.z)
    except Exception:
        try:
            return float(out_hit.location.z)
        except Exception:
            return None


def _terrain_bounds(
    terrain: unreal.StaticMeshActor,
) -> tuple[unreal.Vector, unreal.Vector] | None:
    """Return (origin, extent) for *terrain* across UE 5.7 Python API variants."""
    try:
        result = terrain.get_actor_bounds(False, False)
        if isinstance(result, tuple) and len(result) >= 2:
            return result[0], result[1]
    except TypeError:
        pass
    except Exception:
        pass
    try:
        origin = unreal.Vector()
        extent = unreal.Vector()
        terrain.get_actor_bounds(False, origin, extent)
        return origin, extent
    except TypeError:
        pass
    except Exception:
        pass
    try:
        comp = terrain.static_mesh_component
        if comp is not None:
            origin, extent, _sphere = unreal.SystemLibrary.get_component_bounds(comp)
            return origin, extent
    except Exception:
        pass
    return None


def _dump_collision_diagnostics(terrain: unreal.StaticMeshActor) -> None:
    """Log detailed collision info to help diagnose why the line trace missed."""
    _err("--- COLLISION DIAGNOSTICS ---")

    bounds = _terrain_bounds(terrain)
    if bounds is not None:
        origin, extent = bounds
        _err(
            f"  terrain bbox: origin=({origin.x:.1f}, {origin.y:.1f}, {origin.z:.1f}), "
            f"extent=({extent.x:.1f}, {extent.y:.1f}, {extent.z:.1f})"
        )
        _err(f"  terrain Z range: {origin.z - extent.z:.1f} to {origin.z + extent.z:.1f}")
    else:
        _err("  could not read terrain bounds")

    try:
        comp = terrain.static_mesh_component
        if comp is not None:
            try:
                profile = comp.get_collision_profile_name()
                _err(f"  collision profile: {profile}")
            except Exception:
                _err("  collision profile: <could not read>")
            try:
                enabled = comp.get_collision_enabled()
                _err(f"  collision enabled: {enabled}")
            except Exception:
                _err("  collision enabled: <could not read>")
            try:
                mesh = comp.get_editor_property("static_mesh")
                if mesh is not None:
                    try:
                        flag = mesh.get_editor_property("collision_trace_flag")
                        _err(f"  collision_trace_flag: {flag}")
                    except Exception:
                        _err("  collision_trace_flag: <could not read>")
            except Exception:
                pass
    except Exception as exc:
        _err(f"  could not inspect component: {exc}")

    _err("--- END DIAGNOSTICS ---")
    _err(
        "The line trace could not find the terrain surface. This usually means "
        "setup_terrain_collision.py has not run yet, or the collision settings "
        "did not take effect. In setup_all.py, terrain_collision runs before "
        "player_start — if you're running scripts manually, run "
        "setup_terrain_collision.py first, then re-run this script."
    )


def _find_existing_player_start(actors: list[unreal.Actor]) -> unreal.PlayerStart | None:
    for actor in actors:
        if isinstance(actor, unreal.PlayerStart):
            return actor
    return None


def _spawn_player_start(
    world: unreal.World, location: unreal.Vector, rotation: unreal.Rotator
) -> unreal.PlayerStart | None:
    try:
        sub = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
        if sub is not None:
            actor = sub.spawn_actor_from_class(unreal.PlayerStart, location, rotation)
            return actor  # type: ignore[return-value]
    except Exception as exc:
        _warn(f"EditorActorSubsystem.spawn_actor_from_class failed: {exc}")
    try:
        actor = unreal.EditorLevelLibrary.spawn_actor_from_class(
            unreal.PlayerStart, location, rotation
        )
        return actor  # type: ignore[return-value]
    except Exception as exc:
        _err(f"spawn_actor_from_class fallback failed: {exc}")
        return None


def _save_current_level() -> None:
    try:
        sub = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
        if sub is not None and hasattr(sub, "save_current_level"):
            sub.save_current_level()
            return
    except Exception:
        pass
    try:
        unreal.EditorLevelLibrary.save_current_level()
    except Exception:
        pass


def run() -> None:
    _log("=" * 70)
    _log("Mercenaries 2 - PlayerStart placement on Mercs2_LowResTerrain")
    _log("=" * 70)

    world = _get_editor_world()
    if world is None:
        _err("No editor world is open. Open the level and re-run.")
        return

    terrain = _find_terrain_actor()
    if terrain is None:
        _err(
            "Could not locate the Mercs2_LowResTerrain StaticMeshActor in the "
            "open level. Run import_world.py + populate_world.py first, or "
            "rename the existing terrain actor's label to contain "
            "'Mercs2_LowResTerrain' / 'LowResTerrain' / 'low_res_terrain'."
        )
        return
    try:
        terrain_label = terrain.get_actor_label()
    except Exception:
        terrain_label = terrain.get_name()
    _log(f"Found terrain actor: {terrain_label}")

    placements = _load_landmark_placements()
    pick = _pick_landmark_spawn(placements)
    if pick is not None:
        landmark_name, gx, gy, gz = pick
        _log(f"  landmark match: '{landmark_name}' at game ({gx:.1f}, {gy:.2f}, {gz:.1f})")
    else:
        landmark_name = "PMC base area"
        gx, gy, gz = PMC_GAME_X, PMC_GAME_Y, PMC_GAME_Z
        _log(f"  no landmark matched; using PMC base area ({gx:.1f}, {gy:.2f}, {gz:.1f})")

    ue_xyz = _game_to_ue(gx, gy, gz)
    ue_x_cm, ue_y_cm = ue_xyz.x, ue_xyz.y
    _log(f"  UE XY: ({ue_x_cm:.1f}, {ue_y_cm:.1f})")

    hit_z_cm = _trace_terrain_z(world, ue_x_cm, ue_y_cm)
    if hit_z_cm is None:
        _err(
            f"Line trace from Z={TRACE_START_Z_CM:.0f} to Z={TRACE_END_Z_CM:.0f} "
            f"at UE ({ue_x_cm:.1f}, {ue_y_cm:.1f}) did not hit any surface."
        )
        _dump_collision_diagnostics(terrain)
        return

    spawn_z_cm = hit_z_cm + GROUND_CLEARANCE_CM
    _log(f"  line trace hit terrain at Z={hit_z_cm:.1f}, spawn Z={spawn_z_cm:.1f}")

    spawn_loc = unreal.Vector(ue_x_cm, ue_y_cm, spawn_z_cm)

    yaw_to_origin_deg = math.degrees(math.atan2(-ue_y_cm, -ue_x_cm))
    spawn_rot = unreal.Rotator(roll=0.0, pitch=0.0, yaw=yaw_to_origin_deg)

    actors = _all_level_actors()
    existing = _find_existing_player_start(actors)
    if existing is not None:
        try:
            existing.set_actor_location(spawn_loc, False, False)
            existing.set_actor_rotation(spawn_rot, False)
            _log(f"Moved existing PlayerStart '{existing.get_actor_label()}'")
        except Exception as exc:
            _err(f"Could not move existing PlayerStart: {exc}")
            return
        ps_actor = existing
    else:
        ps_actor = _spawn_player_start(world, spawn_loc, spawn_rot)
        if ps_actor is None:
            _err("Spawning PlayerStart failed — aborting.")
            return
        try:
            ps_actor.set_actor_label("PlayerStart_Mattias")
        except Exception:
            pass
        _log("Spawned new PlayerStart_Mattias")

    _save_current_level()

    _log(
        f"Spawn: '{landmark_name}'; "
        f"game ({gx:.1f}, {gy:.2f}, {gz:.1f}) m; "
        f"UE ({spawn_loc.x:.1f}, {spawn_loc.y:.1f}, {spawn_loc.z:.1f}); "
        f"trace Z={hit_z_cm:.1f}; yaw={yaw_to_origin_deg:.1f} deg"
    )
    _log("=" * 70)
    _log("Done.")
    _log("=" * 70)


if __name__ == "__main__":
    run()
