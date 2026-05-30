"""Shared mission / spawn JSON → UE5 DataTable helpers.

Used by ``import_mission_data.py`` and ``mission_layer_activator.py``.
"""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

import unreal

import mercs2_vz_taxonomy as vz_tax

LOG_PREFIX = "[Mercs2MissionData]"

REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_MISSION_JSON = REPO_ROOT / "docs" / "data" / "examples" / "pmccon001_mission.json"
DEFAULT_SPAWN_JSON = REPO_ROOT / "docs" / "data" / "examples" / "pmccon001_spawn_table.json"

DATA_ROOT = "/Game/Mercs2/Data"
ENUMS_DIR = f"{DATA_ROOT}/Enums"
TABLES_DIR = f"{DATA_ROOT}/Tables"
DT_MISSION = f"{TABLES_DIR}/DT_MissionRegistry"
DT_SPAWN = f"{TABLES_DIR}/DT_SpawnRegistry"
STRUCT_MISSION = f"{DATA_ROOT}/Structs/FMissionData"
STRUCT_SPAWN = f"{DATA_ROOT}/Structs/FSpawnTableRow"

_FACTION_JSON_TO_ENUM: dict[str, str] = {
    "Pmc": "PMC",
    "PMC": "PMC",
    "VZ": "VZ",
    "Vza": "VZ",
    "AN": "AN",
    "Chi": "AN",
    "UP": "UP",
    "Oil": "UP",
    "Pir": "Pirates",
    "Pirates": "Pirates",
    "Neutral": "PMC",
    "All": "PMC",
}


def _log(msg: str) -> None:
    unreal.log(f"{LOG_PREFIX} {msg}")


def _warn(msg: str) -> None:
    unreal.log_warning(f"{LOG_PREFIX} {msg}")


def _err(msg: str) -> None:
    unreal.log_error(f"{LOG_PREFIX} {msg}")


def load_json(path: Path) -> dict[str, Any]:
    text = path.read_text(encoding="utf-8")
    data = json.loads(text)
    if not isinstance(data, dict):
        raise ValueError(f"Expected JSON object in {path}")
    return data


def parse_script_hash(value: object) -> int:
    if isinstance(value, int):
        return value
    if isinstance(value, str):
        s = value.strip()
        if s.lower().startswith("0x"):
            return int(s, 16)
        if s.isdigit():
            return int(s)
    return 0


def _text(value: object) -> unreal.Text:
    return unreal.Text.from_string("" if value is None else str(value))


def _name(value: object) -> unreal.Name:
    return unreal.Name(str(value))


def _soft_class(path: str) -> unreal.SoftClassPath | None:
    path = path.strip()
    if not path:
        return None
    try:
        return unreal.SoftClassPath(path)
    except Exception:
        _warn(f"Invalid SoftClassPath: {path}")
        return None


def enum_byte(enum_asset_path: str, entry_name: str) -> int:
    """Resolve a UserDefinedEnum display name to its underlying byte value."""
    enum_asset = unreal.EditorAssetLibrary.load_asset(enum_asset_path)
    if enum_asset is None:
        _warn(f"Enum asset missing: {enum_asset_path}")
        return 0
    target = entry_name.strip()
    count_fn = getattr(enum_asset, "get_enumerator_count", None)
    name_fn = getattr(enum_asset, "get_display_name_text_by_index", None)
    if not callable(count_fn) or not callable(name_fn):
        return 0
    for index in range(int(count_fn())):
        display = name_fn(index)
        label = display.to_string() if hasattr(display, "to_string") else str(display)
        if label == target:
            return index
    _warn(f"Enum entry '{entry_name}' not found on {enum_asset_path}")
    return 0


def faction_byte(faction_id: str) -> int:
    mapped = _FACTION_JSON_TO_ENUM.get(faction_id.strip(), faction_id.strip())
    return enum_byte(f"{ENUMS_DIR}/EFaction", mapped)


def spawn_category_byte(category: str) -> int:
    return enum_byte(f"{ENUMS_DIR}/ESpawnCategory", category.strip())


def spawn_trigger_byte(trigger: str) -> int:
    return enum_byte(f"{ENUMS_DIR}/ESpawnTrigger", trigger.strip())


def layer_stem_to_overlay_source(layer_stem: str) -> str:
    """Turn mission JSON layer stem into a populate_world-style vz_state *source* string."""
    stem = layer_stem.strip().lower().replace("\\", "/")
    if stem.endswith(".block") or stem.endswith(".block.bin"):
        return stem
    if not stem.startswith("vz_state_"):
        stem = f"vz_state_{stem}"
    if not re.search(r"_p\d{3}_q\d", stem, re.IGNORECASE):
        stem = f"{stem}_p000_q3"
    return f"0_blocks__VZ__{stem}.block"


def leaf_label_for_layer_stem(layer_stem: str, *, prefix: str = "VZ") -> str:
    """UE Data Layer leaf label for a mission ``tLayers`` / ``OverlayLayer`` stem."""
    source = layer_stem_to_overlay_source(layer_stem)
    _, _, leaf = vz_tax.data_layer_hierarchy(source, prefix=prefix)
    return leaf


def contract_parent_label(*, prefix: str = "VZ") -> str:
    return f"{prefix}_Contract"


def mission_overlay_layers_from_entry(entry: dict[str, Any]) -> list[str]:
    """Layer stems to activate for a mission registry / JSON entry."""
    layers = entry.get("tLayers")
    if isinstance(layers, list) and layers:
        return [str(x) for x in layers]
    overlay = entry.get("OverlayLayers")
    if isinstance(overlay, str) and overlay.strip():
        return [s.strip() for s in overlay.split(",") if s.strip()]
    flow = entry.get("ueFlow")
    if isinstance(flow, dict):
        additions = flow.get("layerAdditions")
        if isinstance(additions, list) and additions:
            return [str(x) for x in additions]
    return []


def mission_row_from_json(mission_id: str, entry: dict[str, Any]) -> dict[str, object]:
    """Map pmccon001-style mission JSON to FMissionData field dict."""
    flow = entry.get("ueFlow") if isinstance(entry.get("ueFlow"), dict) else {}
    layers = mission_overlay_layers_from_entry(entry)
    return {
        "MissionId": _name(mission_id),
        "ModuleName": _text(entry.get("sModuleName", "")),
        "Faction": faction_byte(str(entry.get("sFactionId", "Pmc"))),
        "StarterId": _text(entry.get("sStarter", "")),
        "bContract": bool(entry.get("bContract", False)),
        "bCriticalPath": bool(entry.get("bCriticalPathMission", entry.get("bCriticalPath", False))),
        "TitleKey": _text(entry.get("sTitle", "")),
        "ScriptHash": parse_script_hash(entry.get("scriptHash", 0)),
        "OverlayLayers": _text(",".join(layers)),
        "PrerequisiteKey": _text(flow.get("prerequisiteKey", "")),
    }


def spawn_row_from_json(row_name: str, entry: dict[str, Any]) -> dict[str, object]:
    """Map spawn_table JSON row to FSpawnTableRow field dict."""
    faction = str(entry.get("DefaultFaction", "Neutral"))
    return {
        "EntityNamePattern": _text(entry.get("EntityNamePattern", row_name)),
        "EntityNameHash": parse_script_hash(entry.get("EntityNameHash", 0)),
        "SpawnCategory": spawn_category_byte(str(entry.get("SpawnCategory", "NPC"))),
        "BlueprintClass": _soft_class(str(entry.get("BlueprintPath", ""))),
        "DefaultFaction": faction_byte(faction),
        "OverlayLayer": _name(entry.get("OverlayLayer", "")),
        "MissionId": _name(entry.get("MissionId", "")),
        "SpawnTrigger": spawn_trigger_byte(str(entry.get("SpawnTrigger", "Manual"))),
        "bSpawnOnAccept": bool(entry.get("bSpawnOnAccept", False)),
        "bDespawnOnComplete": bool(entry.get("bDespawnOnComplete", False)),
    }


def _table_row_struct(table: unreal.DataTable) -> unreal.ScriptStruct | None:
    row_struct = getattr(table, "row_struct", None)
    if row_struct is not None:
        return row_struct
    try:
        return table.get_row_struct()
    except Exception:
        return None


def _row_names(table: unreal.DataTable) -> set[str]:
    fn = getattr(unreal, "DataTableFunctionLibrary", None)
    if fn is None:
        return set()
    try:
        names = fn.get_data_table_row_names(table)
        return {n.to_string() for n in names}
    except Exception:
        return set()


def upsert_data_table_row(
    table: unreal.DataTable,
    row_name: str,
    field_values: dict[str, object],
) -> bool:
    """Insert or replace one DataTable row via Python struct instance."""
    row_struct = _table_row_struct(table)
    if row_struct is None:
        _err(
            f"{table.get_path_name()} has no row struct — run setup_data_structs.py and "
            f"bind {STRUCT_MISSION} or {STRUCT_SPAWN} in the editor."
        )
        return False

    row_obj = unreal.new_object(row_struct)
    for fname, fval in field_values.items():
        if fval is None:
            continue
        try:
            row_obj.set_editor_property(fname, fval)
        except Exception as exc:
            _warn(f"  {row_name}.{fname}: {exc}")

    existing = _row_names(table)
    if row_name in existing:
        remove_fn = getattr(table, "remove_row", None)
        if callable(remove_fn):
            try:
                remove_fn(row_name)
            except Exception as exc:
                _warn(f"  remove_row({row_name}): {exc}")

    add_fn = getattr(table, "add_row", None)
    if callable(add_fn):
        try:
            add_fn(row_name, row_obj)
            return True
        except Exception as exc:
            _warn(f"  add_row({row_name}): {exc}")

    dt_sub = getattr(unreal, "DataTableEditorSubsystem", None)
    if dt_sub is not None:
        try:
            sub = unreal.get_editor_subsystem(dt_sub)
            add_editor = getattr(sub, "add_row", None)
            if callable(add_editor):
                add_editor(table, row_name, row_obj)
                return True
        except Exception as exc:
            _warn(f"  DataTableEditorSubsystem.add_row: {exc}")

    _warn(
        f"  MANUAL: add row '{row_name}' to {table.get_path_name()} — "
        f"Python could not call add_row (fields: {list(field_values)})"
    )
    return False


def load_mission_table() -> unreal.DataTable | None:
    table = unreal.EditorAssetLibrary.load_asset(DT_MISSION)
    if table is None:
        _err(f"Missing {DT_MISSION} — run setup_data_structs.py first.")
    return table  # type: ignore[return-value]


def load_spawn_table() -> unreal.DataTable | None:
    table = unreal.EditorAssetLibrary.load_asset(DT_SPAWN)
    if table is None:
        _err(f"Missing {DT_SPAWN} — run setup_data_structs.py first.")
    return table  # type: ignore[return-value]


def read_mission_entry(
    mission_id: str,
    *,
    mission_json: Path | None = None,
) -> dict[str, Any] | None:
    """Load mission dict from DT_MissionRegistry row or JSON examples."""
    table = load_mission_table()
    if table is not None and mission_id in _row_names(table):
        fn = getattr(unreal, "DataTableFunctionLibrary", None)
        if fn is not None:
            try:
                row = fn.get_data_table_row_from_name(table, mission_id)
                if row is not None:
                    layers_text = ""
                    try:
                        layers_text = row.overlay_layers.to_string()
                    except Exception:
                        try:
                            layers_text = str(row.get_editor_property("OverlayLayers"))
                        except Exception:
                            pass
                    return {
                        "MissionId": mission_id,
                        "OverlayLayers": layers_text,
                        "tLayers": [s.strip() for s in layers_text.split(",") if s.strip()],
                    }
            except Exception:
                pass

    path = mission_json or DEFAULT_MISSION_JSON
    if not path.is_file():
        _err(f"Mission JSON not found: {path}")
        return None
    data = load_json(path)
    entry = data.get(mission_id)
    if entry is None:
        _err(f"Mission '{mission_id}' not in {path}")
        return None
    return entry  # type: ignore[return-value]
