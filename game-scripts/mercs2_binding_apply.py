"""Apply Game→UE binding manifest in the UE5 Editor.

Reads ``output/ue5_import/ue_game_binding.json`` (see ``tools/build_ue_game_binding.py``).
"""

from __future__ import annotations

import os
from typing import Any

import unreal

import mercs2_binding_manifest_io as manifest_io
import mercs2_data_layers as m2dl
import mercs2_visibility_runtime as vis

_LOG = "[Mercs2Bindings]"
_last_report: dict[str, Any] = {}


def _log(msg: str) -> None:
    unreal.log(f"{_LOG} {msg}")


def _warn(msg: str) -> None:
    unreal.log_warning(f"{_LOG} {msg}")


def _env_skip(name: str) -> bool:
    return os.environ.get(name, "").strip().lower() in ("1", "true", "yes")


def _env_int(name: str, default: int) -> int:
    raw = os.environ.get(name, "").strip()
    if raw.isdigit():
        return int(raw)
    return default


def load_manifest(path: Any = None, *, force_reload: bool = False) -> dict[str, Any] | None:
    from pathlib import Path

    p = Path(path) if path is not None else None
    return manifest_io.load_manifest(p, force_reload=force_reload)


def report() -> dict[str, Any]:
    return dict(_last_report)


def apply_visibility_preset(manifest: dict[str, Any] | None = None) -> dict[str, int]:
    """Apply default vz_state Data Layer preset from manifest."""
    m = manifest or load_manifest()
    preset = manifest_io.visibility_preset_name(m)
    prefix = os.environ.get("MERCS2_VZ_PREFIX", "VZ").strip() or "VZ"
    stats = vis.apply_visibility_preset(preset, prefix=prefix)  # type: ignore[arg-type]
    _log(f"visibility preset {preset!r}: {stats}")
    return stats


def apply_water(manifest: dict[str, Any] | None = None) -> bool:
    """Configure ocean from manifest water section (delegates to setup_water)."""
    import setup_water

    m = manifest or load_manifest()
    water = (m or {}).get("water") if m else None
    if not isinstance(water, dict):
        _warn("no water section in manifest — run make ue-bind-manifest")
        return False
    setup_water.apply_water_binding(water)
    changed, restart = setup_water.enable_water_plugin()
    if restart:
        _warn("Water plugin enabled — restart editor and re-run apply_world_bindings")
        return False
    ocean = setup_water.configure_ocean()
    setup_water.log_ocean_footprint(ocean)
    return ocean is not None


def apply_lights(manifest: dict[str, Any] | None = None) -> dict[str, int]:
    """Spawn or update PointLights from manifest light rows."""
    import populate_world as pw

    m = manifest or load_manifest()
    lights = (m or {}).get("lights") if m else None
    stats = {"placed": 0, "updated": 0, "skipped": 0, "failed": 0}
    if not isinstance(lights, list):
        _warn("no lights[] in manifest")
        return stats

    cap = _env_int("MERCS2_BINDINGS_LIGHT_MAX", 0)
    import mercs2_actor_utils as actor_utils

    label_index = actor_utils.ActorLabelIndex.build()

    for i, row in enumerate(lights):
        if cap > 0 and i >= cap:
            break
        if not isinstance(row, dict):
            continue
        pos = row.get("position") or {}
        placement = {
            "entity_id": row.get("entity_id"),
            "entity_name": row.get("entity_name"),
            "position_x": pos.get("x", 0.0),
            "position_y": pos.get("y", 0.0),
            "position_z": pos.get("z", 0.0),
            "ecs": {
                "LightObject": {
                    "r": (row.get("ue") or {}).get("color_rgb", [1, 1, 1])[0],
                    "g": (row.get("ue") or {}).get("color_rgb", [1, 1, 1])[1],
                    "b": (row.get("ue") or {}).get("color_rgb", [1, 1, 1])[2],
                    "intensity": (row.get("ue") or {}).get("intensity", 5000.0),
                    "attenuation_radius": (row.get("ue") or {}).get("radius_m", 10.0),
                }
            },
        }
        label = pw._sanitize_actor_label(  # noqa: SLF001
            str(row.get("entity_name") or row.get("entity_id") or f"Light_{i}")
        )
        existed = pw.actor_exists(label, label_index)
        actor = pw.place_light_from_placement(
            placement,
            label,
            "Mercs2/Lights",
            None,
            editor_hidden=False,
            label_index=label_index,
        )
        if actor is None:
            stats["failed"] += 1
        elif existed:
            stats["updated"] += 1
        else:
            stats["placed"] += 1
    _log(f"lights: {stats}")
    return stats


def apply_hibernation(manifest: dict[str, Any] | None = None) -> dict[str, int]:
    """Set MinDrawDistance on actors matching hibernation manifest rows (best-effort)."""
    if _env_skip("MERCS2_BINDINGS_SKIP_HIBERNATION"):
        return {"skipped": 1}

    import populate_world as pw

    m = manifest or load_manifest()
    rows = (m or {}).get("hibernation") if m else None
    stats = {"updated": 0, "missing": 0, "no_mesh": 0}
    if not isinstance(rows, list):
        return stats

    cap = _env_int("MERCS2_BINDINGS_HIBERNATION_MAX", 500)
    for i, row in enumerate(rows):
        if i >= cap:
            break
        if not isinstance(row, dict):
            continue
        min_cm = float(row.get("min_draw_distance_cm", 0.0))
        if min_cm <= 0:
            continue
        label = pw._sanitize_actor_label(  # noqa: SLF001
            str(row.get("entity_name") or row.get("entity_id") or "")
        )
        if not label:
            continue
        actor = pw.find_actor_by_label(label)
        if actor is None:
            stats["missing"] += 1
            continue
        mesh_comps = actor.get_components_by_class(unreal.StaticMeshComponent)
        if not mesh_comps:
            stats["no_mesh"] += 1
            continue
        for comp in mesh_comps:
            try:
                comp.set_editor_property("min_draw_distance", min_cm)
                stats["updated"] += 1
            except Exception:
                pass
    _log(f"hibernation: {stats}")
    return stats


def _game_point_to_ue_vec(pt: dict[str, Any]) -> unreal.Vector | None:
    import populate_world as pw

    if not isinstance(pt, dict):
        return None
    try:
        return pw.game_to_ue(float(pt["x"]), float(pt["y"]), float(pt["z"]))
    except (KeyError, TypeError, ValueError):
        return None


def _add_spline_component(actor: unreal.Actor, spline_class: type) -> object | None:
    """Attach a spline to *actor* (UE 5.7 Python lacks add_component_by_class on bare Actor)."""
    if actor is None or spline_class is None:
        return None
    try:
        comp = actor.add_component_by_class(
            spline_class, False, unreal.Transform(), False
        )
        if comp is not None:
            return comp
    except Exception:
        pass
    try:
        comp = unreal.new_object(spline_class, outer=actor)
        if comp is not None:
            actor.add_instance_component(comp)
            try:
                comp.register_component()
            except Exception:
                pass
            return comp
    except Exception:
        pass
    try:
        add_fn = getattr(unreal.EditorLevelLibrary, "add_instance_component", None)
        if add_fn is not None:
            comp = unreal.new_object(spline_class, outer=actor)
            add_fn(actor, comp)
            return comp
    except Exception:
        pass
    return None


def _spawn_debug_spline_actor(
    mid: unreal.Vector, ea: unreal.Vector, eb: unreal.Vector
) -> object | None:
    """Spawn an actor with a world-space spline between *ea* and *eb*."""
    spline_class = getattr(unreal, "SplineComponent", None)
    if spline_class is None:
        return None
    actor_class = (
        getattr(unreal, "EmptyActor", None)
        or getattr(unreal, "Actor", None)
        or unreal.StaticMeshActor
    )
    actor = None
    try:
        sub = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
        actor = sub.spawn_actor_from_class(
            actor_class.static_class(), mid, unreal.Rotator()
        )
    except Exception:
        pass
    if actor is None:
        try:
            actor = unreal.EditorLevelLibrary.spawn_actor_from_class(
                actor_class, mid, unreal.Rotator()
            )
        except Exception:
            return None
    spline = _add_spline_component(actor, spline_class)
    if spline is None:
        return None
    coord = getattr(unreal, "SplineCoordinateSpace", None)
    space = coord.WORLD if coord is not None else None
    try:
        if space is not None:
            spline.set_spline_points([ea, eb], space)
        else:
            spline.set_spline_points([ea, eb])
    except Exception:
        return None
    return actor


def apply_road_splines(manifest: dict[str, Any] | None = None) -> dict[str, int]:
    """Spawn debug spline actors for road graph edges (visual only)."""
    if _env_skip("MERCS2_BINDINGS_SKIP_ROADS"):
        return {"skipped": 1}

    m = manifest or load_manifest()
    edges = (m or {}).get("road_edges") if m else None
    stats = {"spawned": 0, "failed": 0}
    if not isinstance(edges, list) or not edges:
        _log("no road_edges in manifest")
        return stats

    cap = _env_int("MERCS2_BINDINGS_ROAD_MAX", 200)
    if getattr(unreal, "SplineComponent", None) is None:
        _warn("SplineComponent not available")
        return stats

    for i, edge in enumerate(edges):
        if i >= cap:
            break
        if not isinstance(edge, dict):
            continue
        ea = _game_point_to_ue_vec(edge.get("endpoint_a") or {})
        eb = _game_point_to_ue_vec(edge.get("endpoint_b") or {})
        if ea is None or eb is None:
            stats["failed"] += 1
            continue
        mid = unreal.Vector(
            (ea.x + eb.x) * 0.5,
            (ea.y + eb.y) * 0.5,
            (ea.z + eb.z) * 0.5,
        )
        actor = _spawn_debug_spline_actor(mid, ea, eb)
        if actor is None:
            stats["failed"] += 1
            continue
        label = f"RoadSpline_{edge.get('id', i)}"
        try:
            actor.set_actor_label(label[:120])
            actor.set_folder_path("Mercs2/Roads/Debug")
        except Exception:
            pass
        stats["spawned"] += 1
    _log(f"road splines: {stats}")
    return stats


def apply_destruction_pairs(manifest: dict[str, Any] | None = None) -> dict[str, int]:
    """Place hidden TargetPoint markers for destruction pairs (debug / layer wiring)."""
    if _env_skip("MERCS2_BINDINGS_SKIP_DESTRUCTION"):
        return {"skipped": 1}

    import populate_world as pw

    m = manifest or load_manifest()
    pairs = (m or {}).get("destruction_pairs") if m else None
    stats = {"spawned": 0, "skipped": 0}
    if not isinstance(pairs, list):
        return stats

    cap = _env_int("MERCS2_BINDINGS_DESTRUCTION_MAX", 100)
    rubble_layer_label = "VZ_Destroyed"
    rubble_layer = m2dl.get_data_layer_by_label(rubble_layer_label)

    for i, pair in enumerate(pairs):
        if i >= cap:
            break
        if not isinstance(pair, dict):
            continue
        name_b = str(pair.get("entity_b_name") or pair.get("entity_b_key") or f"pair_{i}")
        ent_b = pair.get("entity_b") if isinstance(pair.get("entity_b"), dict) else {}
        pos = ent_b.get("position")
        if not isinstance(pos, dict):
            stats["skipped"] += 1
            continue
        loc = pw.placement_to_ue_location({"position": pos})
        label = pw._sanitize_actor_label(f"DestPair_{name_b}")  # noqa: SLF001
        if pw.actor_exists(label):
            stats["skipped"] += 1
            continue
        actor = pw._spawn_actor_at(unreal.TargetPoint, loc, unreal.Rotator())  # noqa: SLF001
        if actor is None:
            stats["skipped"] += 1
            continue
        try:
            actor.set_actor_label(label[:120])
            actor.set_folder_path("Mercs2/Destruction/Debug")
            actor.set_is_temporarily_hidden_in_editor(True)
        except Exception:
            pass
        if rubble_layer is not None:
            m2dl.add_actor_to_data_layer_if_any(actor, rubble_layer)
        stats["spawned"] += 1
    _log(f"destruction pair markers: {stats}")
    return stats


def apply_all(manifest: dict[str, Any] | None = None) -> dict[str, Any]:
    """Run all binding applicators; continue on partial failure."""
    global _last_report
    m = manifest or load_manifest()
    if m is None:
        _warn(
            "binding manifest not found — run: make ue-bind-manifest OUTPUT=./output"
        )
        _last_report = {"ok": False, "error": "manifest_missing"}
        return _last_report

    _log(f"Applying manifest schema_version={m.get('schema_version')}")
    results: dict[str, Any] = {"ok": True, "steps": {}}
    for name, fn in (
        ("visibility", apply_visibility_preset),
        ("water", apply_water),
        ("lights", apply_lights),
        ("hibernation", apply_hibernation),
        ("roads", apply_road_splines),
        ("destruction", apply_destruction_pairs),
    ):
        try:
            results["steps"][name] = fn(m)
        except Exception as exc:
            _warn(f"{name} failed: {exc}")
            results["steps"][name] = {"error": str(exc)}
            results["ok"] = False
    _last_report = results
    return results
