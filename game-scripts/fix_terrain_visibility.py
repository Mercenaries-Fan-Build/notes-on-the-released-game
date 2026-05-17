"""Mercenaries 2 Recreation — Fix Terrain & Mesh Visibility in PIE

UE 5.7 Editor Python script that diagnoses and fixes actors disappearing
when pressing Play (PIE) despite being visible in the editor.

Addresses several common culprits:
  - Distance culling (LDMaxDrawDistance)
  - LOD forced reduction (ForcedLodModel)
  - Never-distance-cull flag
  - Bounds scale too small for large meshes (frustum cull false-positives)
  - bHiddenInGame flag
  - HLOD layer replacing actors at runtime with nothing (if HLOD not built)
  - World Partition streaming distance settings
  - Data Layer runtime state (UNLOADED layers hide actors in PIE)

Run from UE Editor via:
    Edit → Run Python Script → select this file
or:
    py "/path/to/mercenaries-game/game-scripts/fix_terrain_visibility.py"
"""
from __future__ import annotations

import os
import re
import sys

import unreal

_SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
if _SCRIPT_DIR not in sys.path:
    sys.path.insert(0, _SCRIPT_DIR)
import mercs2_data_layers as m2dl

LOG_PREFIX = "[Mercs2VisFix]"

TERRAIN_LABEL_RE = re.compile(r"terrain|lowresterrain|low_res_terrain", re.IGNORECASE)

LARGE_MESH_BOUNDS_SCALE = 10.0
TERRAIN_BOUNDS_SCALE = 100.0


def _log(msg: str) -> None:
    unreal.log(f"{LOG_PREFIX} {msg}")


def _warn(msg: str) -> None:
    unreal.log_warning(f"{LOG_PREFIX} {msg}")


def _err(msg: str) -> None:
    unreal.log_error(f"{LOG_PREFIX} {msg}")


def _is_terrain_actor(actor: unreal.StaticMeshActor) -> bool:
    label = actor.get_actor_label()
    return bool(TERRAIN_LABEL_RE.search(label))


def fix_static_mesh_actor(actor: unreal.StaticMeshActor, *, is_terrain: bool) -> dict:
    """Apply visibility fixes to a single StaticMeshActor. Returns a dict of changes made."""
    changes: dict[str, str] = {}
    label = actor.get_actor_label()
    comp = actor.static_mesh_component

    # 1. Disable distance culling (0 = infinite draw distance)
    try:
        old_val = comp.get_editor_property("ld_max_draw_distance")
        if old_val != 0.0:
            comp.set_editor_property("ld_max_draw_distance", 0.0)
            changes["ld_max_draw_distance"] = f"{old_val} → 0"
    except Exception as exc:
        _warn(f"  {label}: ld_max_draw_distance failed: {exc}")

    # 2. Disable LOD forced reduction (0 = use all LODs, no forced LOD)
    try:
        old_val = comp.get_editor_property("forced_lod_model")
        if old_val != 0:
            comp.set_editor_property("forced_lod_model", 0)
            changes["forced_lod_model"] = f"{old_val} → 0"
    except Exception as exc:
        _warn(f"  {label}: forced_lod_model failed: {exc}")

    # 3. Set bNeverDistanceCull = True
    try:
        old_val = actor.get_editor_property("never_distance_cull")
        if not old_val:
            actor.set_editor_property("never_distance_cull", True)
            changes["never_distance_cull"] = "False → True"
    except Exception:
        try:
            old_val = comp.get_editor_property("never_distance_cull")
            if not old_val:
                comp.set_editor_property("never_distance_cull", True)
                changes["never_distance_cull"] = "False → True"
        except Exception as exc:
            _warn(f"  {label}: never_distance_cull not available: {exc}")

    # 4. Disable lightmap resolution override
    try:
        old_val = comp.get_editor_property("override_light_map_res")
        if old_val:
            comp.set_editor_property("override_light_map_res", False)
            changes["override_light_map_res"] = "True → False"
    except Exception:
        pass

    # 5. Bounds scale — prevent frustum culling on large meshes
    target_bounds = TERRAIN_BOUNDS_SCALE if is_terrain else LARGE_MESH_BOUNDS_SCALE
    try:
        old_val = comp.get_editor_property("bounds_scale")
        if old_val < target_bounds:
            comp.set_editor_property("bounds_scale", target_bounds)
            changes["bounds_scale"] = f"{old_val} → {target_bounds}"
    except Exception as exc:
        _warn(f"  {label}: bounds_scale failed: {exc}")

    # 6. Ensure actor is not hidden in game
    try:
        if actor.hidden:
            actor.set_actor_hidden_in_game(False)
            changes["hidden_in_game"] = "True → False"
    except Exception:
        pass
    try:
        if actor.get_editor_property("hidden"):
            actor.set_editor_property("hidden", False)
            changes["hidden_property"] = "True → False"
    except Exception:
        pass

    # 7. Ensure the root component is visible
    try:
        root = actor.root_component
        if root is not None:
            vis = root.get_editor_property("visible")
            if not vis:
                root.set_editor_property("visible", True)
                changes["root_visible"] = "False → True"
    except Exception:
        pass

    # 8. Ensure static mesh component itself is visible
    try:
        vis = comp.get_editor_property("visible")
        if not vis:
            comp.set_editor_property("visible", True)
            changes["comp_visible"] = "False → True"
    except Exception:
        pass

    # 9. Disable detail mode culling (set to High so it renders at all detail levels)
    try:
        comp.set_editor_property("detail_mode", unreal.DetailMode.HIGH)
    except Exception:
        pass

    return changes


def fix_data_layer_runtime_states() -> int:
    """Ensure all Data Layer instances are ACTIVATED for PIE.

    UNLOADED data layers cause all assigned actors to disappear in PIE even
    though they're visible in the editor. This is the single most likely
    cause of "visible in editor, gone in Play" for this project.
    """
    fixed = 0
    try:
        sub = m2dl.data_layer_editor_subsystem()
    except Exception:
        _warn("DataLayerEditorSubsystem not available — skipping data layer check")
        return 0

    for actor in m2dl.iter_all_level_actors():
        class_name = actor.get_class().get_name()
        if class_name != "WorldDataLayers":
            continue

        _log("Found WorldDataLayers actor — checking runtime states ...")
        try:
            all_layers = sub.get_all_data_layers()
        except Exception:
            try:
                all_layers = sub.get_all_data_layer_instances()
            except Exception:
                _warn("Cannot enumerate data layers")
                return 0

        for layer in all_layers:
            try:
                layer_label = str(layer.get_data_layer_short_name())
            except Exception:
                layer_label = str(layer)

            try:
                current_state = sub.get_data_layer_runtime_state(layer)
                if current_state != unreal.DataLayerRuntimeState.ACTIVATED:
                    sub.set_data_layer_runtime_state(
                        layer, unreal.DataLayerRuntimeState.ACTIVATED,
                    )
                    _log(f"  Data Layer '{layer_label}': {current_state} → ACTIVATED")
                    fixed += 1
            except Exception:
                pass

            try:
                loaded = sub.get_data_layer_is_loaded_in_editor(layer)
                if not loaded:
                    sub.set_data_layer_is_loaded_in_editor(layer, True)
                    _log(f"  Data Layer '{layer_label}': loaded_in_editor → True")
                    fixed += 1
            except Exception:
                pass

        break

    return fixed


def check_world_settings() -> None:
    """Log World Settings properties relevant to actor visibility in PIE."""
    world = m2dl.get_editor_world()
    if world is None:
        _warn("Cannot get editor world for World Settings check")
        return

    _log("--- World Settings Diagnostics ---")

    try:
        ws = world.get_world_settings()
        if ws is None:
            _warn("  WorldSettings is None")
            return

        # HLOD layer check
        for prop_name in (
            "default_hlod_layer",
            "hlod_setup_asset",
            "world_partition_default_hlod_layer",
        ):
            try:
                val = ws.get_editor_property(prop_name)
                if val is not None:
                    _warn(
                        f"  {prop_name} is SET ({val}). If HLODs are not built, "
                        f"this can cause actors to disappear at runtime. "
                        f"Consider clearing it or building HLODs."
                    )
                    try:
                        ws.set_editor_property(prop_name, None)
                        _log(f"  Cleared {prop_name} → None")
                    except Exception:
                        _warn(f"  Could not clear {prop_name} — do this manually in World Settings")
                else:
                    _log(f"  {prop_name}: None (OK)")
            except Exception:
                pass

        # Kill cam / visibility distance overrides
        for prop_name in (
            "kill_z",
            "world_to_meters",
            "enable_world_bounds_checks",
        ):
            try:
                val = ws.get_editor_property(prop_name)
                _log(f"  {prop_name}: {val}")
            except Exception:
                pass

        # Check if World Partition streaming distances are set
        try:
            wp = world.get_world_partition()
            if wp is not None:
                _log("  World Partition: present")
                try:
                    runtime_hash = wp.get_editor_property("runtime_hash")
                    _log(f"  Runtime hash: {runtime_hash}")
                except Exception:
                    pass
            else:
                _log("  World Partition: not present")
        except Exception:
            pass

    except Exception as exc:
        _warn(f"  WorldSettings check failed: {exc}")


def fix_all_actors_spatial_loading() -> int:
    """Disable is_spatially_loaded on all actors to prevent streaming cull."""
    fixed = 0
    for actor in m2dl.iter_all_level_actors():
        try:
            if actor.get_editor_property("is_spatially_loaded"):
                actor.set_editor_property("is_spatially_loaded", False)
                fixed += 1
        except Exception:
            pass
    return fixed


def run() -> None:
    """Main entry point — fix visibility on all StaticMeshActors and diagnose world settings."""
    _log("=" * 60)
    _log("Mercenaries 2 Recreation — Terrain & Mesh Visibility Fix")
    _log("=" * 60)

    world = m2dl.get_editor_world()
    if world is None:
        _err("No editor world — open a level first")
        return

    all_actors = m2dl.iter_all_level_actors()
    static_mesh_actors = [a for a in all_actors if isinstance(a, unreal.StaticMeshActor)]
    _log(f"Found {len(static_mesh_actors)} StaticMeshActors in level")

    terrain_count = 0
    other_count = 0
    total_changes = 0

    for actor in static_mesh_actors:
        is_terrain = _is_terrain_actor(actor)
        changes = fix_static_mesh_actor(actor, is_terrain=is_terrain)

        if changes:
            label = actor.get_actor_label()
            if is_terrain:
                terrain_count += 1
                _log(f"  TERRAIN '{label}': {changes}")
            else:
                other_count += 1
                if other_count <= 5:
                    _log(f"  Mesh '{label}': {changes}")
            total_changes += len(changes)

    _log(f"Fixed {terrain_count} terrain actors, {other_count} other mesh actors "
         f"({total_changes} total property changes)")

    # Fix Data Layer runtime states (most likely culprit)
    _log("")
    _log("-" * 40)
    _log("Step 2: Data Layer runtime states")
    _log("-" * 40)
    dl_fixed = fix_data_layer_runtime_states()
    if dl_fixed > 0:
        _warn(
            f"Fixed {dl_fixed} data layer state(s). DATA LAYERS WERE LIKELY THE CAUSE: "
            f"UNLOADED data layers hide all assigned actors in PIE even though "
            f"they appear in the editor viewport."
        )
    else:
        _log("All data layers already ACTIVATED / loaded.")

    # Disable spatial loading on all actors
    _log("")
    _log("-" * 40)
    _log("Step 3: Disable spatial loading")
    _log("-" * 40)
    sp_fixed = fix_all_actors_spatial_loading()
    _log(f"Disabled is_spatially_loaded on {sp_fixed} actors")

    # World settings diagnostics
    _log("")
    _log("-" * 40)
    _log("Step 4: World Settings diagnostics")
    _log("-" * 40)
    check_world_settings()

    # Summary
    _log("")
    _log("=" * 60)
    _log("Visibility fix complete")
    _log("")
    _log("MOST LIKELY CULPRITS (in order):")
    _log("  1. Data Layer runtime state = UNLOADED")
    _log("     → Actors assigned to an UNLOADED data layer are visible in")
    _log("       the editor but completely hidden during PIE. This script")
    _log("       sets all layers to ACTIVATED.")
    _log("  2. Default HLOD Layer set but HLODs not built")
    _log("     → World Settings > Default HLOD Layer causes UE to replace")
    _log("       actors with HLOD representations. If HLODs were never")
    _log("       built, actors vanish. This script clears the setting.")
    _log("  3. World Partition streaming (is_spatially_loaded=True)")
    _log("     → Large actors outside the streaming radius get unloaded.")
    _log("       This script disables spatial loading on all actors.")
    _log("  4. Distance culling (LDMaxDrawDistance)")
    _log("     → Non-zero values cull the mesh beyond that distance.")
    _log("       This script sets it to 0 (infinite).")
    _log("  5. Bounds scale too small for huge meshes")
    _log("     → Frustum culling uses the mesh bounds. A ±3900m terrain")
    _log("       mesh with default BoundsScale=1.0 can be incorrectly")
    _log("       culled. This script increases it to 100.0 for terrain.")
    _log("")
    _log("Press Play again to verify the fix.")
    _log("=" * 60)


if __name__ == "__main__":
    run()
