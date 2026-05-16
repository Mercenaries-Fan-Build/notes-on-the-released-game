"""Mercenaries 2 Recreation — Project Setup Script

Run this FIRST in the UE 5.7 Editor (Edit → Run Python Script) to:
  1. Verify required plugins are enabled (and log instructions if not).
  2. Create or open the main Mercs2World map.
  3. Create the expected Content directory structure for the import pipeline.

Prerequisites:
  - Unreal Engine 5.7 with Editor Python enabled.
  - PythonScriptPlugin must already be active (otherwise this script can't run).
"""
from __future__ import annotations

import unreal


LOG_PREFIX = "[Mercs2Setup]"

REQUIRED_PLUGINS = [
    ("PythonScriptPlugin", "Required to run Editor Python scripts (this script)."),
    ("DataLayerEditor", "Required for World Partition Data Layers."),
    ("InterchangeEditor", "Required for glTF/GLB import via Interchange."),
    ("InterchangeImport", "Required for glTF/GLB import via Interchange."),
]

CONTENT_DIRECTORIES = [
    "/Game/Mercs2/Meshes/Buildings",
    "/Game/Mercs2/Meshes/Vehicles",
    "/Game/Mercs2/Meshes/Roads",
    "/Game/Mercs2/Meshes/Environment",
    "/Game/Mercs2/Meshes/Maracaibo",
    "/Game/Mercs2/Meshes/WorldLayers",
    "/Game/Mercs2/Meshes/Other",
    "/Game/Mercs2/Meshes/PMCBase",
    "/Game/Mercs2/DataLayers/World",
    "/Game/Mercs2/DataLayers/PMC",
    "/Game/Mercs2/Maps",
    "/Game/Mercs2/DataTables",
]


def _log(msg: str) -> None:
    unreal.log(f"{LOG_PREFIX} {msg}")


def _warn(msg: str) -> None:
    unreal.log_warning(f"{LOG_PREFIX} {msg}")


def ensure_plugins() -> None:
    """Check that required plugins are enabled and log guidance for any that are missing."""
    _log("--- Checking required plugins ---")

    enabled = set(unreal.PluginBlueprintLibrary.get_enabled_plugin_names())

    missing: list[tuple[str, str]] = []
    for plugin_name, reason in REQUIRED_PLUGINS:
        if plugin_name in enabled:
            _log(f"  OK  {plugin_name}")
        else:
            _warn(f"  MISSING  {plugin_name} — {reason}")
            missing.append((plugin_name, reason))

    if missing:
        _warn(
            "Some plugins are not enabled. Add the following to your .uproject "
            "\"Plugins\" array and restart the editor:"
        )
        for plugin_name, _ in missing:
            _warn(f'    {{ "Name": "{plugin_name}", "Enabled": true }}')
    else:
        _log("All required plugins are loaded.")


def create_or_open_map(map_path: str = "/Game/Mercs2/Maps/Mercs2World") -> None:
    """Create a new World Partition level at *map_path*, or open it if it exists."""
    _log("--- Setting up map ---")

    level_sub = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)

    if unreal.EditorAssetLibrary.does_asset_exist(map_path):
        _log(f"Map already exists — opening {map_path}")
        level_sub.load_level(map_path)
    else:
        _log(f"Creating new World Partition level at {map_path}")
        level_sub.new_level(map_path, is_partitioned_world=True)
        level_sub.save_current_level()
        _log("  Saved with World Partition enabled.")

    _log(f"Active map: {map_path}")


def setup_content_directories() -> None:
    """Create the expected Content sub-directory tree for the import pipeline."""
    _log("--- Creating content directories ---")

    for directory in CONTENT_DIRECTORIES:
        if unreal.EditorAssetLibrary.does_directory_exist(directory):
            _log(f"  exists  {directory}")
        else:
            unreal.EditorAssetLibrary.make_directory(directory)
            _log(f"  created {directory}")


def run() -> None:
    """Main entry point — call all setup steps in order."""
    _log("=" * 60)
    _log("Mercenaries 2 Recreation — Project Setup")
    _log("=" * 60)

    ensure_plugins()
    setup_content_directories()
    create_or_open_map()

    _log("=" * 60)
    _log("Setup complete. You can now run the import scripts.")
    _log("=" * 60)


if __name__ == "__main__":
    run()
