"""Mercenaries 2 Recreation — Data Struct / Enum / DataTable setup.

UE 5.7 Editor Python script that creates the gameplay data scaffolding under
``/Game/Mercs2/Data``:

  - Enums: ``EWeaponStance``, ``EFaction``
  - Structs: ``FFactionReputation``, ``FWeaponData``, ``FMissionObjective``
  - DataTables: ``DT_WeaponData``, ``DT_TutorialMission``

Why this script exists in two phases:

  The UE 5.7 Python API can create the **asset shells** for User Defined Enums,
  Structs, and Data Tables, but the entry-level mutation APIs
  (``EnumEditorUtils.add_enumerator_for_user_defined_enum`` and
  ``StructureEditorUtils.AddVariable``) are not consistently exposed to Python
  across engine builds. We do best-effort programmatic authoring and, in
  parallel, write a JSON manifest at ``Content/Data/_schema.json`` describing
  the canonical schema. Any field the Python API could not author is logged as
  a MANUAL step.

Run via:
    Tools → Execute Python Script → setup_data_structs.py
or:
    unreal.PythonScriptLibrary.execute_python_script(
        "/path/to/mercenaries-game/game-scripts/setup_data_structs.py")
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import TYPE_CHECKING

import unreal

if TYPE_CHECKING:
    from typing import Any

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

LOG_PREFIX = "[Mercs2DataStructs]"

DATA_ROOT = "/Game/Mercs2/Data"
ENUMS_DIR = f"{DATA_ROOT}/Enums"
STRUCTS_DIR = f"{DATA_ROOT}/Structs"
TABLES_DIR = f"{DATA_ROOT}/Tables"

# Repo-side schema manifest (lives alongside the source tree, NOT in Content)
REPO_ROOT = Path(__file__).resolve().parent.parent
SCHEMA_MANIFEST_PATH = REPO_ROOT / "docs" / "data" / "mercs2_data_schema.json"


# ---------------------------------------------------------------------------
# Schema definition — single source of truth for what we want
# ---------------------------------------------------------------------------

ENUMS: dict[str, list[str]] = {
    "EWeaponStance": ["Unarmed", "Pistol", "Rifle", "Heavy"],
    "EFaction": ["PMC", "VZ", "AN", "UP", "Pirates"],
    "ESpawnCategory": ["NPC", "Vehicle", "Pickup", "Fortification", "SpawnerLogic", "Particle", "Trigger"],
    "ESpawnTrigger": ["OnLayerActivate", "OnLayerDeactivate", "OnMissionActivated", "OnScriptEvent", "Manual"],
}


STRUCTS: dict[str, list[dict[str, str]]] = {
    "FFactionReputation": [
        {"name": "Faction", "type": "byte:EFaction"},
        {"name": "Reputation", "type": "float", "comment": "-100..+100"},
    ],
    "FWeaponData": [
        {"name": "Name", "type": "text"},
        {"name": "Stance", "type": "byte:EWeaponStance"},
        {"name": "DamagePerShot", "type": "float"},
        {"name": "MagSize", "type": "int32"},
        {"name": "ReserveAmmo", "type": "int32"},
        {"name": "FireRate", "type": "float", "comment": "rounds per minute"},
        {"name": "Texture", "type": "softobject:Texture2D"},
    ],
    "FMissionObjective": [
        {"name": "Title", "type": "text"},
        {"name": "Description", "type": "text"},
        {"name": "bCompleted", "type": "bool"},
        {"name": "Order", "type": "int32"},
    ],
    "FMissionData": [
        {"name": "MissionId", "type": "name"},
        {"name": "ModuleName", "type": "text", "comment": "Lua sModuleName, e.g. pmccon001"},
        {"name": "Faction", "type": "byte:EFaction"},
        {"name": "StarterId", "type": "text", "comment": "wifstarterdata key, e.g. PmcBoss"},
        {"name": "bContract", "type": "bool"},
        {"name": "bCriticalPath", "type": "bool"},
        {"name": "TitleKey", "type": "text", "comment": "Localization key [PmcCon001.Title]"},
        {"name": "ScriptHash", "type": "int32", "comment": "pandemic_hash_m2(ModuleName)"},
        {"name": "OverlayLayers", "type": "text", "comment": "Comma-separated vz_state layer stems"},
        {"name": "PrerequisiteKey", "type": "text", "comment": "Flow HasKey gate"},
    ],
    "FSpawnTableRow": [
        {"name": "EntityNamePattern", "type": "text"},
        {"name": "EntityNameHash", "type": "int32"},
        {"name": "SpawnCategory", "type": "byte:ESpawnCategory"},
        {"name": "BlueprintClass", "type": "softclass:Actor"},
        {"name": "DefaultFaction", "type": "byte:EFaction"},
        {"name": "OverlayLayer", "type": "name"},
        {"name": "MissionId", "type": "name"},
        {"name": "SpawnTrigger", "type": "byte:ESpawnTrigger"},
        {"name": "bSpawnOnAccept", "type": "bool"},
        {"name": "bDespawnOnComplete", "type": "bool"},
    ],
}


WEAPON_DATA_ROWS: list[dict[str, object]] = [
    {
        "Name": "Pistol_Sidearm",
        "Stance": "Pistol",
        "DamagePerShot": 18.0,
        "MagSize": 12,
        "ReserveAmmo": 60,
        "FireRate": 360.0,
        "TexturePath": "",
    },
    {
        "Name": "AK74",
        "Stance": "Rifle",
        "DamagePerShot": 28.0,
        "MagSize": 30,
        "ReserveAmmo": 180,
        "FireRate": 600.0,
        "TexturePath": "",
    },
    {
        "Name": "M16",
        "Stance": "Rifle",
        "DamagePerShot": 26.0,
        "MagSize": 30,
        "ReserveAmmo": 180,
        "FireRate": 720.0,
        "TexturePath": "",
    },
    {
        "Name": "M249",
        "Stance": "Heavy",
        "DamagePerShot": 24.0,
        "MagSize": 100,
        "ReserveAmmo": 400,
        "FireRate": 800.0,
        "TexturePath": "",
    },
    {
        "Name": "RPG7",
        "Stance": "Heavy",
        "DamagePerShot": 350.0,
        "MagSize": 1,
        "ReserveAmmo": 4,
        "FireRate": 30.0,
        "TexturePath": "",
    },
]


TUTORIAL_MISSION_ROWS: list[dict[str, object]] = [
    {
        "Title": "Make Contact",
        "Description": "Reach the PMC base and check in with command.",
        "bCompleted": False,
        "Order": 0,
    },
    {
        "Title": "Gear Up",
        "Description": "Collect a sidearm and a rifle from the armory.",
        "bCompleted": False,
        "Order": 1,
    },
    {
        "Title": "Sight In",
        "Description": "Verify weapons at the firing range — fire each weapon at least once.",
        "bCompleted": False,
        "Order": 2,
    },
    {
        "Title": "Roll Out",
        "Description": "Leave PMC base and head into Maracaibo.",
        "bCompleted": False,
        "Order": 3,
    },
]


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
# Helpers
# ---------------------------------------------------------------------------

def _ensure_directory(content_path: str) -> None:
    if not unreal.EditorAssetLibrary.does_directory_exist(content_path):
        unreal.EditorAssetLibrary.make_directory(content_path)
        _log(f"  created dir {content_path}")


def _save(asset: unreal.Object, content_path: str) -> None:
    try:
        unreal.EditorAssetLibrary.save_asset(content_path)
    except Exception as exc:
        _warn(f"  save_asset failed for {content_path}: {exc}")


def _load_or_create(
    asset_name: str,
    package_dir: str,
    asset_class: type,
    factory: unreal.Factory,
) -> unreal.Object | None:
    """Idempotent: return existing asset, else create via *factory*."""
    asset_path = f"{package_dir}/{asset_name}"
    existing = unreal.EditorAssetLibrary.load_asset(asset_path)
    if existing is not None:
        _log(f"  exists  {asset_path}")
        return existing

    tools = unreal.AssetToolsHelpers.get_asset_tools()
    asset = tools.create_asset(asset_name, package_dir, asset_class, factory)
    if asset is None:
        _err(f"  create_asset returned None for {asset_path}")
        return None
    _save(asset, asset_path)
    _log(f"  created {asset_path}")
    return asset


# ---------------------------------------------------------------------------
# Enum creation
# ---------------------------------------------------------------------------

def _try_populate_enum(enum: unreal.UserDefinedEnum, entries: list[str]) -> bool:
    """Attempt to add entries to a UserDefinedEnum via available Python APIs.

    Returns True if any entries were added programmatically. The EnumEditorUtils
    bindings are not always exposed; this function gracefully no-ops in that
    case so the caller can log a MANUAL step.
    """
    helper = getattr(unreal, "EnumEditorUtils", None)
    if helper is None:
        return False

    added_any = False
    add_fn = getattr(helper, "add_enumerator_for_user_defined_enum", None)
    rename_fn = getattr(helper, "rename_enumerator_for_user_defined_enum", None)
    if not callable(add_fn) or not callable(rename_fn):
        return False

    for i, entry_name in enumerate(entries):
        try:
            add_fn(enum)
            rename_fn(enum, i, entry_name)
            added_any = True
        except Exception as exc:
            _warn(f"    could not add enumerator '{entry_name}' programmatically: {exc}")
            return added_any
    return added_any


def create_enums() -> None:
    _log("--- Enums ---")
    _ensure_directory(ENUMS_DIR)

    for enum_name, entries in ENUMS.items():
        enum = _load_or_create(
            enum_name,
            ENUMS_DIR,
            unreal.UserDefinedEnum,
            unreal.EnumFactory(),
        )
        if enum is None:
            continue
        populated = _try_populate_enum(enum, entries)  # type: ignore[arg-type]
        if populated:
            _save(enum, f"{ENUMS_DIR}/{enum_name}")
        else:
            _warn(
                f"  MANUAL: open {ENUMS_DIR}/{enum_name} in the editor and add "
                f"entries: {entries}"
            )


# ---------------------------------------------------------------------------
# Struct creation
# ---------------------------------------------------------------------------

def create_structs() -> None:
    _log("--- Structs ---")
    _ensure_directory(STRUCTS_DIR)

    helper = getattr(unreal, "StructureEditorUtils", None)
    add_var = getattr(helper, "add_variable", None) if helper is not None else None

    for struct_name, fields in STRUCTS.items():
        struct = _load_or_create(
            struct_name,
            STRUCTS_DIR,
            unreal.UserDefinedStruct,
            unreal.StructureFactory(),
        )
        if struct is None:
            continue

        if callable(add_var):
            _warn(
                f"  StructureEditorUtils Python binding present — see the "
                f"editor log for any errors authoring fields on {struct_name}."
            )
        _warn(
            f"  MANUAL: open {STRUCTS_DIR}/{struct_name} and add fields:\n"
            f"           {fields}"
        )


# ---------------------------------------------------------------------------
# DataTable creation
# ---------------------------------------------------------------------------

def _create_data_table(
    name: str,
    row_struct_path: str,
) -> unreal.DataTable | None:
    """Create a DataTable backed by *row_struct_path*.

    The Python factory does not accept the row struct directly; the caller
    must set it via the editor after the row struct is fully authored. We
    create the table as a shell and log the MANUAL row struct binding step.
    """
    table_path = f"{TABLES_DIR}/{name}"
    existing = unreal.EditorAssetLibrary.load_asset(table_path)
    if existing is not None:
        _log(f"  exists  {table_path}")
        return existing  # type: ignore[return-value]

    factory = unreal.DataTableFactory()
    row_struct = unreal.EditorAssetLibrary.load_asset(row_struct_path)
    if row_struct is not None:
        try:
            factory.set_editor_property("struct", row_struct)
        except Exception:
            pass

    table = unreal.AssetToolsHelpers.get_asset_tools().create_asset(
        name, TABLES_DIR, unreal.DataTable, factory
    )
    if table is None:
        _err(f"  create_asset returned None for {table_path}")
        return None
    _save(table, table_path)
    _log(f"  created {table_path}")
    return table  # type: ignore[return-value]


def create_data_tables() -> None:
    _log("--- DataTables ---")
    _ensure_directory(TABLES_DIR)

    _create_data_table("DT_WeaponData", f"{STRUCTS_DIR}/FWeaponData")
    _warn(
        "  MANUAL: with FWeaponData row struct bound, add the rows defined in "
        "the schema manifest (Pistol_Sidearm, AK74, M16, M249, RPG7)."
    )

    _create_data_table("DT_TutorialMission", f"{STRUCTS_DIR}/FMissionObjective")
    _warn(
        "  MANUAL: with FMissionObjective row struct bound, add the rows from "
        "the schema manifest (4 tutorial objectives)."
    )

    _create_data_table("DT_MissionRegistry", f"{STRUCTS_DIR}/FMissionData")
    _warn(
        "  MANUAL: bind FMissionData and import docs/data/examples/pmccon001_mission.json "
        "as the first vertical-slice row (PmcCon001)."
    )

    _create_data_table("DT_SpawnRegistry", f"{STRUCTS_DIR}/FSpawnTableRow")
    _warn(
        "  MANUAL: bind FSpawnTableRow and import docs/data/examples/pmccon001_spawn_table.json."
    )


# ---------------------------------------------------------------------------
# Repo-side manifest — canonical schema reference for humans and tooling
# ---------------------------------------------------------------------------

def write_schema_manifest() -> None:
    """Write the canonical schema to docs/data/ so it's tracked in git."""
    manifest: dict[str, Any] = {
        "version": 1,
        "content_root": DATA_ROOT,
        "enums": {
            name: {
                "path": f"{ENUMS_DIR}/{name}",
                "entries": entries,
            }
            for name, entries in ENUMS.items()
        },
        "structs": {
            name: {
                "path": f"{STRUCTS_DIR}/{name}",
                "fields": fields,
            }
            for name, fields in STRUCTS.items()
        },
        "data_tables": {
            "DT_WeaponData": {
                "path": f"{TABLES_DIR}/DT_WeaponData",
                "row_struct": f"{STRUCTS_DIR}/FWeaponData",
                "rows": WEAPON_DATA_ROWS,
            },
            "DT_TutorialMission": {
                "path": f"{TABLES_DIR}/DT_TutorialMission",
                "row_struct": f"{STRUCTS_DIR}/FMissionObjective",
                "rows": TUTORIAL_MISSION_ROWS,
            },
            "DT_MissionRegistry": {
                "path": f"{TABLES_DIR}/DT_MissionRegistry",
                "row_struct": f"{STRUCTS_DIR}/FMissionData",
                "schema_doc": "docs/data/mission_data_schema.json",
                "example_rows": "docs/data/examples/pmccon001_mission.json",
            },
            "DT_SpawnRegistry": {
                "path": f"{TABLES_DIR}/DT_SpawnRegistry",
                "row_struct": f"{STRUCTS_DIR}/FSpawnTableRow",
                "schema_doc": "docs/data/spawn_table_schema.json",
                "example_rows": "docs/data/examples/pmccon001_spawn_table.json",
            },
        },
        "external_schemas": {
            "mission_data": "docs/data/mission_data_schema.json",
            "spawn_table": "docs/data/spawn_table_schema.json",
            "script_hash_map_output": "output/placements/script_hash_map.json",
        },
    }

    SCHEMA_MANIFEST_PATH.parent.mkdir(parents=True, exist_ok=True)
    SCHEMA_MANIFEST_PATH.write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    _log(f"Wrote schema manifest to {SCHEMA_MANIFEST_PATH}")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def run() -> None:
    _log("=" * 60)
    _log("Mercenaries 2 — Gameplay data scaffolding")
    _log("=" * 60)

    _ensure_directory(DATA_ROOT)
    create_enums()
    create_structs()
    create_data_tables()
    write_schema_manifest()

    _log("=" * 60)
    _log("Done. Review MANUAL warnings above and finish authoring in the editor.")
    _log("=" * 60)


if __name__ == "__main__":
    run()
