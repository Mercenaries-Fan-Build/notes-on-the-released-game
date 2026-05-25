"""Mercenaries 2 Recreation — Map Error Fixer

Utility to fix common map errors after populate scripts run.
Handles duplicate actors, floating geometry, bulk folder deletion,
and actor statistics.

Run from UE Editor via:
    Edit → Run Python Script → select this file
or:
    unreal.PythonScriptLibrary.execute_python_script(
        "/path/to/mercenaries-game/game-scripts/fix_map_errors.py")
"""
from __future__ import annotations

from collections import defaultdict

import unreal


LOG_PREFIX = "[Mercs2MapFix]"

FLOATING_Z_THRESHOLD = -50000.0


def _log(msg: str) -> None:
    unreal.log(f"{LOG_PREFIX} {msg}")


def _warn(msg: str) -> None:
    unreal.log_warning(f"{LOG_PREFIX} {msg}")


def _get_all_actors() -> list[unreal.Actor]:
    """Return every actor in the current editor level via EditorActorSubsystem."""
    return unreal.get_editor_subsystem(unreal.EditorActorSubsystem).get_all_level_actors()


def _actor_folder(actor: unreal.Actor) -> str:
    """Return the Outliner folder path for an actor, or '' if unset."""
    return actor.get_folder_path()


def remove_duplicate_actors() -> int:
    """Find actors with duplicate labels under World/ folders and remove extras.

    Keeps the first actor encountered for each (folder, label) pair.
    Returns the number of removed actors.
    """
    _log("Scanning for duplicate actors...")

    seen: dict[tuple[str, str], unreal.Actor] = {}
    duplicates: list[unreal.Actor] = []

    for actor in _get_all_actors():
        folder = _actor_folder(actor)
        if not folder.startswith("World"):
            continue
        label = actor.get_actor_label()
        key = (folder, label)
        if key in seen:
            duplicates.append(actor)
        else:
            seen[key] = actor

    if not duplicates:
        _log("No duplicate actors found.")
        return 0

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    for actor in duplicates:
        subsystem.destroy_actor(actor)

    _log(f"Removed {len(duplicates)} duplicate actors.")
    return len(duplicates)


def fix_floating_actors(
    threshold: float = FLOATING_Z_THRESHOLD,
    remove: bool = False,
) -> int:
    """Find StaticMeshActors with Z below *threshold*.

    If *remove* is True, destroy them; otherwise just log.
    Returns the number of affected actors.
    """
    _log(f"Scanning for actors below Z={threshold}...")

    flagged: list[unreal.Actor] = []
    for actor in _get_all_actors():
        if not isinstance(actor, unreal.StaticMeshActor):
            continue
        z = actor.get_actor_location().z
        if z < threshold:
            flagged.append(actor)

    if not flagged:
        _log("No floating actors found.")
        return 0

    for actor in flagged:
        loc = actor.get_actor_location()
        label = actor.get_actor_label()
        _warn(f"  {label}  Z={loc.z:.1f}")

    if remove:
        subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
        for actor in flagged:
            subsystem.destroy_actor(actor)
        _log(f"Removed {len(flagged)} floating actors.")
    else:
        _log(
            f"Found {len(flagged)} floating actors (pass remove=True to delete)."
        )

    return len(flagged)


def remove_actors_in_folder(folder_path: str) -> int:
    """Delete all actors in the given Outliner folder.

    Useful for re-running populate on a subset without manual cleanup.
    Returns the number of removed actors.
    """
    _log(f"Removing all actors in folder '{folder_path}'...")

    targets: list[unreal.Actor] = []
    for actor in _get_all_actors():
        actor_folder = _actor_folder(actor)
        if actor_folder == folder_path or actor_folder.startswith(folder_path + "/"):
            targets.append(actor)

    if not targets:
        _log(f"No actors found in '{folder_path}'.")
        return 0

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    for actor in targets:
        subsystem.destroy_actor(actor)

    _log(f"Removed {len(targets)} actors from '{folder_path}'.")
    return len(targets)


def list_actor_stats() -> None:
    """Count actors by class type and by top-level Outliner folder, log summary."""
    _log("Collecting actor statistics...")

    by_class: dict[str, int] = defaultdict(int)
    by_folder: dict[str, int] = defaultdict(int)
    total = 0

    for actor in _get_all_actors():
        total += 1
        class_name = actor.get_class().get_name()
        by_class[class_name] += 1

        folder = _actor_folder(actor)
        top_folder = folder.split("/")[0] if folder else "(no folder)"
        by_folder[top_folder] += 1

    _log(f"Total actors: {total}")

    _log("--- By class ---")
    for class_name, count in sorted(by_class.items(), key=lambda x: -x[1]):
        _log(f"  {count:>6}  {class_name}")

    _log("--- By top-level folder ---")
    for folder, count in sorted(by_folder.items(), key=lambda x: -x[1]):
        _log(f"  {count:>6}  {folder}")


def run() -> None:
    """Run all fixes in order with log banners."""
    _log("=" * 60)
    _log("Mercenaries 2 Recreation — Map Error Fixer")
    _log("=" * 60)

    _log("")
    _log("-" * 40)
    _log("Step 1: Remove duplicate actors")
    _log("-" * 40)
    remove_duplicate_actors()

    _log("")
    _log("-" * 40)
    _log("Step 2: Fix floating actors")
    _log("-" * 40)
    fix_floating_actors(remove=False)

    _log("")
    _log("-" * 40)
    _log("Step 3: Actor statistics")
    _log("-" * 40)
    list_actor_stats()

    _log("")
    _log("=" * 60)
    _log("Map fix pass complete.")
    _log("=" * 60)


if __name__ == "__main__":
    run()
