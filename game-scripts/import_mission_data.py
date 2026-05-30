"""Import mission registry + spawn table rows from docs/data/examples JSON.

Loads ``pmccon001_mission.json`` into ``DT_MissionRegistry`` and
``pmccon001_spawn_table.json`` into ``DT_SpawnRegistry`` using the struct
field names from ``setup_data_structs.py`` (``FMissionData``, ``FSpawnTableRow``).

Prerequisites:
  1. ``setup_data_structs.py`` — table shells exist
  2. FMissionData / FSpawnTableRow structs authored and bound as row structs
     (Python cannot reliably add struct fields on all UE 5.7 builds)

Run via Tools → Execute Python Script, or as part of ``setup_all.py`` when
``MERCS2_SETUP_IMPORT_MISSION=1`` or ``MERCS2_MISSION_ID`` is set.

Environment:
  MERCS2_MISSION_JSON   Override mission JSON path
  MERCS2_SPAWN_JSON     Override spawn JSON path
  MERCS2_MISSION_ID     Import only this mission row (default: all keys in JSON)
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

import unreal

_SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
if _SCRIPT_DIR not in sys.path:
    sys.path.insert(0, _SCRIPT_DIR)

import mercs2_mission_data as mdata

LOG_PREFIX = "[Mercs2ImportMission]"


def _log(msg: str) -> None:
    unreal.log(f"{LOG_PREFIX} {msg}")


def _warn(msg: str) -> None:
    unreal.log_warning(f"{LOG_PREFIX} {msg}")


def _mission_json_path() -> Path:
    override = os.environ.get("MERCS2_MISSION_JSON", "").strip()
    if override:
        return Path(override)
    return mdata.DEFAULT_MISSION_JSON


def _spawn_json_path() -> Path:
    override = os.environ.get("MERCS2_SPAWN_JSON", "").strip()
    if override:
        return Path(override)
    return mdata.DEFAULT_SPAWN_JSON


def import_mission_registry(*, only_mission_id: str | None = None) -> dict[str, int]:
    path = _mission_json_path()
    if not path.is_file():
        _warn(f"Mission JSON missing: {path}")
        return {"imported": 0, "failed": 0, "skipped": 0}

    table = mdata.load_mission_table()
    if table is None:
        return {"imported": 0, "failed": 0, "skipped": 0}

    data = mdata.load_json(path)
    stats = {"imported": 0, "failed": 0, "skipped": 0}

    for mission_id, entry in data.items():
        if mission_id.startswith("$"):
            continue
        if only_mission_id and mission_id != only_mission_id:
            stats["skipped"] += 1
            continue
        if not isinstance(entry, dict):
            stats["skipped"] += 1
            continue
        fields = mdata.mission_row_from_json(mission_id, entry)
        if mdata.upsert_data_table_row(table, mission_id, fields):
            stats["imported"] += 1
            _log(f"  mission row {mission_id}")
        else:
            stats["failed"] += 1

    unreal.EditorAssetLibrary.save_asset(mdata.DT_MISSION)
    return stats


def import_spawn_registry(*, mission_id_filter: str | None = None) -> dict[str, int]:
    path = _spawn_json_path()
    if not path.is_file():
        _warn(f"Spawn JSON missing: {path}")
        return {"imported": 0, "failed": 0, "skipped": 0}

    table = mdata.load_spawn_table()
    if table is None:
        return {"imported": 0, "failed": 0, "skipped": 0}

    data = mdata.load_json(path)
    stats = {"imported": 0, "failed": 0, "skipped": 0}

    for row_name, entry in data.items():
        if row_name.startswith("$"):
            continue
        if not isinstance(entry, dict):
            stats["skipped"] += 1
            continue
        if mission_id_filter:
            mid = str(entry.get("MissionId", ""))
            if mid and mid != mission_id_filter:
                stats["skipped"] += 1
                continue
        fields = mdata.spawn_row_from_json(row_name, entry)
        if mdata.upsert_data_table_row(table, row_name, fields):
            stats["imported"] += 1
            _log(f"  spawn row {row_name}")
        else:
            stats["failed"] += 1

    unreal.EditorAssetLibrary.save_asset(mdata.DT_SPAWN)
    return stats


def run() -> bool:
    """Entry point for setup_all and direct execution."""
    _log("=" * 60)
    _log("Import mission + spawn DataTable rows")
    _log("=" * 60)

    only = os.environ.get("MERCS2_MISSION_ID", "").strip() or None
    mission_stats = import_mission_registry(only_mission_id=only)
    spawn_stats = import_spawn_registry(mission_id_filter=only)

    _log(
        f"Mission registry: {mission_stats['imported']} ok, "
        f"{mission_stats['failed']} failed, {mission_stats['skipped']} skipped"
    )
    _log(
        f"Spawn registry: {spawn_stats['imported']} ok, "
        f"{spawn_stats['failed']} failed, {spawn_stats['skipped']} skipped"
    )
    _log("=" * 60)

    total_failed = mission_stats["failed"] + spawn_stats["failed"]
    if total_failed:
        _warn(
            "Some rows failed — ensure FMissionData / FSpawnTableRow fields exist "
            "and row structs are bound on the DataTables."
        )
        return False
    return mission_stats["imported"] > 0 or spawn_stats["imported"] > 0


if __name__ == "__main__":
    run()
