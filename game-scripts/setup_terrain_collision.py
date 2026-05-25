"""Mercenaries 2 Recreation - Terrain collision configuration.

UE 5.7 Editor Python script that turns the merged ``Mercs2_LowResTerrain``
``StaticMeshActor`` into a collidable surface so the player walks on it.

What this does:

  - Locates the merged terrain actor by label / asset hint (same logic as
    ``setup_player_start.py``).
  - On the underlying ``UStaticMesh`` asset's ``UBodySetup``:
      * ``collision_trace_flag = CTF_USE_COMPLEX_AS_SIMPLE``
        (queries and physics use the per-triangle mesh)
  - On the actor's ``StaticMeshComponent``:
      * ``collision_profile_name = BlockAll``
      * ``collision_enabled = QueryAndPhysics``
  - Saves the modified static mesh asset.

NOTE on cost:

  ``UseComplexAsSimple`` generates per-triangle collision. The merged terrain
  ships ~271 k triangles, so traces are slightly more expensive than a baked
  simple shape. For our scale (one terrain actor, character + projectile
  traces only) this is fine. If profiling later flags it as a hot spot, the
  alternative is to bake a low-poly convex hull (or a heightfield) into
  ``KAggregateGeom``: select the static mesh -> Collision menu ->
  "Auto Convex Collision" with ~32 hulls, then flip ``collision_trace_flag``
  back to ``CTF_USE_DEFAULT``. That trades fidelity (small ledges may
  disappear) for cheaper traces.

Idempotent: re-running just re-applies the same settings.

Run via:
    Tools -> Execute Python Script -> setup_terrain_collision.py
"""

from __future__ import annotations

from typing import TYPE_CHECKING

import unreal

if TYPE_CHECKING:
    from typing import Any


LOG_PREFIX = "[Mercs2TerrainCollision]"

TERRAIN_LABEL_HINTS: tuple[str, ...] = (
    "Mercs2_LowResTerrain",
    "LowResTerrain",
    "low_res_terrain",
)
TERRAIN_ASSET_HINT = "low_res_terrain"
COLLISION_PROFILE = "BlockAll"


def _log(msg: str) -> None:
    unreal.log(f"{LOG_PREFIX} {msg}")


def _warn(msg: str) -> None:
    unreal.log_warning(f"{LOG_PREFIX} {msg}")


def _err(msg: str) -> None:
    unreal.log_error(f"{LOG_PREFIX} {msg}")


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


def _set_static_mesh_collision(static_mesh: unreal.StaticMesh) -> tuple[bool, int]:
    """Configure the underlying UStaticMesh for complex-as-simple collision.

    Returns ``(success, triangle_count)``. ``triangle_count`` is best-effort.
    """
    flag = getattr(unreal.CollisionTraceFlag, "CTF_USE_COMPLEX_AS_SIMPLE", None)
    if flag is None:
        _warn("CollisionTraceFlag.CTF_USE_COMPLEX_AS_SIMPLE not exposed; trying enum lookup")
        try:
            flag = unreal.CollisionTraceFlag.CTF_USE_COMPLEX_AS_SIMPLE  # type: ignore[attr-defined]
        except Exception:
            flag = None

    success = False
    try:
        if flag is not None:
            static_mesh.set_editor_property("collision_trace_flag", flag)
            success = True
    except Exception as exc:
        _warn(f"  could not set static_mesh.collision_trace_flag: {exc}")

    body_setup = None
    try:
        body_setup = static_mesh.get_editor_property("body_setup")
    except Exception:
        pass
    if body_setup is None:
        try:
            body_setup = static_mesh.body_setup  # type: ignore[attr-defined]
        except Exception:
            body_setup = None
    if body_setup is not None and flag is not None:
        try:
            body_setup.set_editor_property("collision_trace_flag", flag)
            success = True
        except Exception as exc:
            _warn(f"  could not set body_setup.collision_trace_flag: {exc}")
    elif body_setup is None:
        _warn("  body_setup not accessible from Python on this StaticMesh")

    tri_count = 0
    try:
        num_lods = static_mesh.get_num_lods()
        for lod in range(num_lods):
            tri_count += int(static_mesh.get_num_triangles(lod) or 0)
            if tri_count:
                break
    except Exception:
        pass

    return success, tri_count


def _set_component_collision(component: unreal.StaticMeshComponent) -> bool:
    success = True
    try:
        component.set_collision_profile_name(COLLISION_PROFILE)
    except Exception as exc:
        _warn(f"  set_collision_profile_name failed: {exc}")
        success = False
    try:
        component.set_collision_enabled(unreal.CollisionEnabled.QUERY_AND_PHYSICS)
    except Exception as exc:
        _warn(f"  set_collision_enabled failed: {exc}")
        success = False
    return success


def run() -> None:
    _log("=" * 70)
    _log("Mercenaries 2 - Terrain collision configuration")
    _log("=" * 70)

    actor = _find_terrain_actor()
    if actor is None:
        _err(
            "Could not locate the Mercs2_LowResTerrain StaticMeshActor. Run "
            "import_world.py + populate_world.py first."
        )
        return

    try:
        comp = actor.static_mesh_component
    except Exception:
        comp = None
    if comp is None:
        _err("Terrain actor has no StaticMeshComponent - aborting.")
        return

    try:
        static_mesh = comp.get_editor_property("static_mesh")
    except Exception as exc:
        _err(f"Could not read static_mesh from component: {exc}")
        return
    if static_mesh is None:
        _err("Terrain actor's StaticMeshComponent has no static_mesh assigned.")
        return

    try:
        asset_path = static_mesh.get_path_name()
    except Exception:
        asset_path = "(unknown)"
    _log(f"Configuring asset: {asset_path}")

    asset_ok, tri_count = _set_static_mesh_collision(static_mesh)
    comp_ok = _set_component_collision(comp)

    if asset_ok:
        try:
            unreal.EditorAssetLibrary.save_loaded_asset(static_mesh)
            _log("  saved static mesh asset")
        except Exception:
            try:
                unreal.EditorAssetLibrary.save_asset(asset_path)
                _log("  saved static mesh asset (by path)")
            except Exception as exc:
                _warn(f"  could not save static mesh asset: {exc}")

    if comp_ok:
        try:
            sub = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
            if sub is not None and hasattr(sub, "save_current_level"):
                sub.save_current_level()
            else:
                unreal.EditorLevelLibrary.save_current_level()
        except Exception:
            pass

    if not (asset_ok and comp_ok):
        _warn(
            "Collision was only partially applied. Open the static mesh asset "
            "and verify Collision Complexity = 'Use Complex Collision As Simple'; "
            "open the actor and verify the StaticMeshComponent's Collision "
            "Preset = 'BlockAll'."
        )

    tri_str = f"{tri_count}" if tri_count else "unknown"
    _log(
        f"Terrain collision configured. Triangle count: {tri_str}. "
        "UseComplexAsSimple: True."
    )
    _log("=" * 70)
    _log("Done. Run setup_player_start.py (or re-run) so the trace can hit the surface.")
    _log("=" * 70)


if __name__ == "__main__":
    run()
