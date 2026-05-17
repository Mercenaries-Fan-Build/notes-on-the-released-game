"""Fix World Partition streaming so ALL actors load during Play-In-Editor.

Problem: With World Partition enabled, only ~21 actors load in PIE while
~1222 are visible in the editor. The WP streaming system unloads everything
outside the player's grid cell loading range.

This script applies a multi-pronged fix:

  1. Disable WP streaming on the WorldPartition object (if the property is
     exposed). This makes WP act like a regular persistent level — all actors
     load at runtime without distance-based culling.

  2. Set is_spatially_loaded = False on EVERY actor in the level. This marks
     each actor as "Always Loaded" so it loads regardless of streaming source
     proximity. This is the fallback if approach 1 isn't available.

  3. Set the runtime loading-range console variable to an extremely large
     value as a belt-and-suspenders measure.

  4. Save all dirty packages so the changes persist.

Run via: Tools → Execute Python Script → fix_world_partition_streaming.py
"""

from __future__ import annotations

import os
import sys

import unreal

_SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
if _SCRIPT_DIR not in sys.path:
    sys.path.insert(0, _SCRIPT_DIR)

LOG_PREFIX = "[FixWPStreaming]"


def _log(msg: str) -> None:
    unreal.log(f"{LOG_PREFIX} {msg}")


def _warn(msg: str) -> None:
    unreal.log_warning(f"{LOG_PREFIX} {msg}")


def _err(msg: str) -> None:
    unreal.log_error(f"{LOG_PREFIX} {msg}")


# ---------------------------------------------------------------------------
# Step 1 — Disable streaming on the WorldPartition object
# ---------------------------------------------------------------------------

def _disable_wp_streaming() -> bool:
    """Try to disable World Partition streaming via the WP object.

    In UE 5.x, WorldPartition may expose ``enable_streaming`` as an editor
    property. If the property doesn't exist on this engine version, we fall
    through gracefully.

    Returns True if streaming was successfully disabled.
    """
    _log("Step 1: Attempting to disable World Partition streaming ...")

    world = _get_editor_world()
    if world is None:
        _warn("  Could not obtain editor world")
        return False

    # Access WorldPartition via WorldSettings
    ws = world.get_world_settings()
    if ws is None:
        _warn("  No WorldSettings found")
        return False

    wp = None
    try:
        wp = ws.get_editor_property("world_partition")
    except Exception:
        pass

    if wp is None:
        try:
            get_wp = getattr(world, "get_world_partition", None)
            if callable(get_wp):
                wp = get_wp()
        except Exception:
            pass

    if wp is None:
        _warn("  WorldPartition object not found on this level")
        return False

    _log(f"  WorldPartition object: {wp}")

    # Try to set enable_streaming = False
    disabled = False
    try:
        current = wp.get_editor_property("enable_streaming")
        _log(f"  Current enable_streaming = {current}")
        if current:
            wp.set_editor_property("enable_streaming", False)
            _log("  Set enable_streaming = False")
            disabled = True
        else:
            _log("  Streaming is already disabled")
            disabled = True
    except Exception as exc:
        _warn(f"  enable_streaming property not accessible: {exc}")

    # Also suppress the streaming-disabled warning in viewport
    try:
        ws.set_editor_property("hide_enable_streaming_warning", True)
        _log("  Hid streaming-disabled viewport warning")
    except Exception:
        pass

    return disabled


# ---------------------------------------------------------------------------
# Step 2 — Mark ALL actors as Always Loaded (is_spatially_loaded = False)
# ---------------------------------------------------------------------------

def _mark_all_actors_always_loaded() -> int:
    """Set is_spatially_loaded = False on every actor in the level.

    Returns the number of actors modified.
    """
    _log("Step 2: Marking ALL actors as Always Loaded (is_spatially_loaded = False) ...")

    actors = _get_all_actors()
    _log(f"  Total actors in level: {len(actors)}")

    modified = 0
    already_ok = 0
    errors = 0

    for actor in actors:
        try:
            currently_spatial = actor.get_editor_property("is_spatially_loaded")
        except Exception:
            continue

        if not currently_spatial:
            already_ok += 1
            continue

        try:
            actor.set_editor_property("is_spatially_loaded", False)
            modified += 1
        except Exception:
            errors += 1

    _log(f"  Modified: {modified}  |  Already OK: {already_ok}  |  Errors: {errors}")
    return modified


# ---------------------------------------------------------------------------
# Step 3 — Override runtime loading range via console variable
# ---------------------------------------------------------------------------

def _set_loading_range_override() -> None:
    """Set the WP runtime loading range CVar to an extremely large value.

    The CVar ``wp.Runtime.OverrideRuntimeSpatialHashLoadingRange`` overrides
    the grid's configured loading range at runtime, ensuring all cells within
    this radius are loaded. 1,000,000 UU = 10 km, which covers the entire
    Maracaibo map (±3900 m ≈ ±390,000 UU diagonal ~552,000 UU).
    """
    _log("Step 3: Setting runtime loading-range override CVar ...")

    cvar_name = "wp.Runtime.OverrideRuntimeSpatialHashLoadingRange"
    huge_range = "-grid=0 -range=1000000"

    try:
        unreal.SystemLibrary.execute_console_command(
            None, f"{cvar_name} {huge_range}"
        )
        _log(f"  Executed: {cvar_name} {huge_range}")
    except Exception:
        pass

    # Simpler form — just the range value
    try:
        unreal.SystemLibrary.execute_console_command(
            None, f"{cvar_name} -range=1000000"
        )
    except Exception:
        pass

    # Also try the DefaultEngine.ini approach by writing the CVar
    _write_streaming_cvar_to_config()


def _write_streaming_cvar_to_config() -> None:
    """Append the loading-range override to DefaultEngine.ini so it persists
    across editor restarts and PIE sessions."""
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    config_path = os.path.join(repo_root, "UnrealEngineGame", "Config", "DefaultEngine.ini")

    if not os.path.isfile(config_path):
        _warn(f"  Config not found: {config_path}")
        return

    section = "[/Script/Engine.WorldPartitionRuntimeSpatialHash]"
    loading_range_line = "LoadingRange=1000000.0"
    cell_size_line = "CellSize=100000"

    wp_section = "\n[WorldPartition]\nbEnableStreaming=False\n"

    with open(config_path, "r", encoding="utf-8") as fh:
        content = fh.read()

    changes = []

    if section not in content:
        content += f"\n{section}\n{loading_range_line}\n{cell_size_line}\n"
        changes.append(f"Added {section} with LoadingRange=1000000 and CellSize=100000")
    else:
        after_section = content.split(section, 1)[1].split("[", 1)[0]
        if "LoadingRange" not in after_section:
            content = content.replace(section, f"{section}\n{loading_range_line}")
            changes.append("Added LoadingRange=1000000")
        if "CellSize" not in after_section:
            content = content.replace(section, f"{section}\n{cell_size_line}")
            changes.append("Added CellSize=100000")

    if "[WorldPartition]" not in content:
        content += wp_section
        changes.append("Added [WorldPartition] bEnableStreaming=False")

    if changes:
        with open(config_path, "w", encoding="utf-8") as fh:
            fh.write(content)
        for c in changes:
            _log(f"  Config: {c}")
    else:
        _log("  Config already has streaming settings")


# ---------------------------------------------------------------------------
# Step 4 — Save everything
# ---------------------------------------------------------------------------

def _save_all() -> None:
    """Save the current level and all dirty packages."""
    _log("Step 4: Saving ...")

    try:
        sub = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
        if sub is not None and hasattr(sub, "save_all_dirty_levels"):
            sub.save_all_dirty_levels()
            _log("  Saved all dirty levels")
        elif sub is not None and hasattr(sub, "save_current_level"):
            sub.save_current_level()
            _log("  Saved current level")
    except Exception as exc:
        _warn(f"  Level save via subsystem failed: {exc}")

    try:
        unreal.EditorLoadingAndSavingUtils.save_dirty_packages(
            True,  # save_map_packages
            True,  # save_content_packages
        )
        _log("  Saved all dirty packages")
    except Exception as exc:
        _warn(f"  save_dirty_packages failed: {exc}")


# ---------------------------------------------------------------------------
# Step 5 — Diagnostic report
# ---------------------------------------------------------------------------

def _diagnostic_report() -> None:
    """Log a diagnostic summary of the level's streaming state."""
    _log("Step 5: Diagnostic report ...")

    actors = _get_all_actors()
    spatial_count = 0
    always_loaded_count = 0
    no_prop = 0

    for actor in actors:
        try:
            if actor.get_editor_property("is_spatially_loaded"):
                spatial_count += 1
            else:
                always_loaded_count += 1
        except Exception:
            no_prop += 1

    _log(f"  Total actors: {len(actors)}")
    _log(f"  Always Loaded (is_spatially_loaded=False): {always_loaded_count}")
    _log(f"  Still Spatially Loaded: {spatial_count}")
    _log(f"  No is_spatially_loaded property: {no_prop}")

    if spatial_count > 0:
        _warn(
            f"  {spatial_count} actors are still spatially loaded! "
            "These may not appear in PIE if they are outside the streaming range."
        )

    # Check WorldPartition state
    world = _get_editor_world()
    if world is not None:
        ws = world.get_world_settings()
        if ws is not None:
            wp = None
            try:
                wp = ws.get_editor_property("world_partition")
            except Exception:
                pass
            if wp is not None:
                try:
                    streaming = wp.get_editor_property("enable_streaming")
                    _log(f"  WorldPartition.enable_streaming = {streaming}")
                    if streaming:
                        _warn(
                            "  Streaming is STILL enabled on the WorldPartition object. "
                            "Consider disabling it manually in World Settings → "
                            "World Partition Setup → Enable Streaming."
                        )
                except Exception:
                    _log("  WorldPartition.enable_streaming property not readable")


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _get_editor_world():
    """Return the current editor world."""
    try:
        return unreal.get_editor_subsystem(unreal.UnrealEditorSubsystem).get_editor_world()
    except Exception:
        pass
    try:
        return unreal.EditorLevelLibrary.get_editor_world()
    except Exception:
        return None


def _get_all_actors() -> list:
    """Return all actors in the current editor level."""
    try:
        sub = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
        if sub is not None:
            return list(sub.get_all_level_actors())
    except Exception:
        pass
    try:
        return list(unreal.EditorLevelLibrary.get_all_level_actors())
    except Exception:
        return []


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def run() -> None:
    _log("=" * 70)
    _log("Fix World Partition Streaming — Comprehensive Fix")
    _log("=" * 70)
    _log("")
    _log("This script ensures ALL actors load during Play-In-Editor by:")
    _log("  1. Disabling WP streaming on the WorldPartition object")
    _log("  2. Setting is_spatially_loaded=False on EVERY actor")
    _log("  3. Overriding the runtime loading range via CVar + config")
    _log("  4. Saving all changes")
    _log("  5. Running a diagnostic report")
    _log("")

    streaming_disabled = _disable_wp_streaming()

    modified = _mark_all_actors_always_loaded()

    _set_loading_range_override()

    _save_all()

    _diagnostic_report()

    _log("")
    _log("=" * 70)
    if streaming_disabled:
        _log("SUCCESS: WP streaming disabled + all actors marked Always Loaded.")
        _log("Press Play — all 1200+ actors should now load in PIE.")
    elif modified > 0:
        _log("PARTIAL: All actors marked Always Loaded, but could not disable")
        _log("WP streaming directly. If actors still don't load in PIE:")
        _log("  1. Open World Settings → World Partition Setup")
        _log("  2. Uncheck 'Enable Streaming'")
        _log("  3. Save and try Play again")
    else:
        _log("All actors were already marked Always Loaded.")
        _log("If PIE still only loads ~21 actors:")
        _log("  1. Open World Settings → World Partition Setup")
        _log("  2. Uncheck 'Enable Streaming'")
        _log("  3. Save the level (Ctrl+S) and try Play again")
    _log("=" * 70)


if __name__ == "__main__":
    run()
