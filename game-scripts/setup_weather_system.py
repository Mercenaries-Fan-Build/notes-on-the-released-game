"""Mercenaries 2 Recreation — Weather state machine scaffold.

UE 5.7 Editor Python script that scaffolds a runtime weather system without
authoring its event graph. After this script runs the user must finish:

  - The ``BP_WeatherController`` event graph (lerp logic + write-backs).
  - A Niagara rain emitter asset.
  - A debug input binding to cycle states.

Created assets:

  /Game/Data/EWeatherState              — enum  { Clear, Cloudy, Rainy, Stormy }
  /Game/Data/FWeatherStateParams        — per-state tunable struct
  /Game/Data/DT_WeatherStates           — data table with 4 rows
  /Game/World/BP_WeatherController      — Actor blueprint with vars + Niagara comp

Spawned actors:

  PP_Weather_Global   PostProcessVolume (unbounded, default settings)
  WeatherController   instance of BP_WeatherController in the level, with its
                      component references auto-filled where possible.

Run via:
    Tools -> Execute Python Script -> setup_weather_system.py
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import TYPE_CHECKING, Iterable

import unreal

if TYPE_CHECKING:
    from typing import Any


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

LOG_PREFIX = "[Mercs2Weather]"

REPO_ROOT = Path(__file__).resolve().parent.parent
SCHEMA_MANIFEST_PATH = REPO_ROOT / "docs" / "data" / "mercs2_weather_schema.json"

DATA_DIR = "/Game/Data"
WORLD_DIR = "/Game/World"

ENUM_NAME = "EWeatherState"
ENUM_PATH = f"{DATA_DIR}/{ENUM_NAME}"

STRUCT_NAME = "FWeatherStateParams"
STRUCT_PATH = f"{DATA_DIR}/{STRUCT_NAME}"

DT_NAME = "DT_WeatherStates"
DT_PATH = f"{DATA_DIR}/{DT_NAME}"

BP_NAME = "BP_WeatherController"
BP_PATH = f"{WORLD_DIR}/{BP_NAME}"

PP_LABEL = "PP_Weather_Global"
WEATHER_CONTROLLER_LABEL = "WeatherController"

WEATHER_FOLDER = "Weather"

# Candidate labels reused from setup_atmosphere.py (must stay in sync).
FOG_LABELS = ("HeightFog_World",)
CLOUD_LABELS = ("VolumetricCloud_World", "VolumetricClouds")
SUN_LABELS = ("AtmosphericLight_World", "Sun_Tropical", "DirectionalLight_World")


# ---------------------------------------------------------------------------
# Schema definitions — single source of truth
# ---------------------------------------------------------------------------

ENUM_ENTRIES: list[str] = ["Clear", "Cloudy", "Rainy", "Stormy"]


STRUCT_FIELDS: list[dict[str, str]] = [
    {"name": "FogDensity", "type": "float"},
    {"name": "FogInscatteringColor", "type": "LinearColor"},
    {"name": "CloudCoverageFactor", "type": "float", "comment": "0..1 cloud density scalar"},
    {"name": "SunIntensity", "type": "float"},
    {"name": "SunTemperature", "type": "float", "comment": "Kelvin"},
    {"name": "RainEmissionRate", "type": "float", "comment": "particles per second"},
    {"name": "WindSpeed", "type": "float", "comment": "m/s"},
    {"name": "PostProcessExposure", "type": "float", "comment": "EV"},
    {"name": "PostProcessSaturation", "type": "float", "comment": "0..2"},
]


WEATHER_ROWS: list[dict[str, object]] = [
    {
        "RowName": "Clear",
        "FogDensity": 0.020,
        "FogInscatteringColor": {"R": 0.88, "G": 0.80, "B": 0.62, "A": 1.0},
        "CloudCoverageFactor": 0.10,
        "SunIntensity": 8.0,
        "SunTemperature": 5800.0,
        "RainEmissionRate": 0.0,
        "WindSpeed": 1.0,
        "PostProcessExposure": 0.0,
        "PostProcessSaturation": 1.05,
    },
    {
        "RowName": "Cloudy",
        "FogDensity": 0.040,
        "FogInscatteringColor": {"R": 0.72, "G": 0.70, "B": 0.62, "A": 1.0},
        "CloudCoverageFactor": 0.55,
        "SunIntensity": 5.0,
        "SunTemperature": 6200.0,
        "RainEmissionRate": 0.0,
        "WindSpeed": 3.0,
        "PostProcessExposure": -0.3,
        "PostProcessSaturation": 0.95,
    },
    {
        "RowName": "Rainy",
        "FogDensity": 0.060,
        "FogInscatteringColor": {"R": 0.55, "G": 0.58, "B": 0.62, "A": 1.0},
        "CloudCoverageFactor": 0.85,
        "SunIntensity": 2.5,
        "SunTemperature": 6500.0,
        "RainEmissionRate": 1500.0,
        "WindSpeed": 6.0,
        "PostProcessExposure": -0.6,
        "PostProcessSaturation": 0.85,
    },
    {
        "RowName": "Stormy",
        "FogDensity": 0.080,
        "FogInscatteringColor": {"R": 0.32, "G": 0.36, "B": 0.42, "A": 1.0},
        "CloudCoverageFactor": 1.0,
        "SunIntensity": 1.0,
        "SunTemperature": 7000.0,
        "RainEmissionRate": 4000.0,
        "WindSpeed": 12.0,
        "PostProcessExposure": -1.0,
        "PostProcessSaturation": 0.75,
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
# Generic helpers
# ---------------------------------------------------------------------------

def _ensure_directory(content_path: str) -> None:
    if not unreal.EditorAssetLibrary.does_directory_exist(content_path):
        unreal.EditorAssetLibrary.make_directory(content_path)
        _log(f"  created dir {content_path}")


def _save(asset_path: str) -> None:
    try:
        unreal.EditorAssetLibrary.save_asset(asset_path)
    except Exception as exc:
        _warn(f"  save_asset failed for {asset_path}: {exc}")


def _load_or_create(
    asset_name: str,
    package_dir: str,
    asset_class: type,
    factory: unreal.Factory,
) -> unreal.Object | None:
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
    _save(asset_path)
    _log(f"  created {asset_path}")
    return asset


def _all_level_actors() -> list[unreal.Actor]:
    try:
        sub = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
        actors = sub.get_all_level_actors()
        if actors:
            return list(actors)
    except Exception:
        pass
    try:
        return list(unreal.EditorLevelLibrary.get_all_level_actors())
    except Exception:
        return []


def _find_actor_by_labels(labels: Iterable[str]) -> unreal.Actor | None:
    wanted = {c.lower() for c in labels}
    for actor in _all_level_actors():
        try:
            label = actor.get_actor_label()
        except Exception:
            continue
        if label and label.lower() in wanted:
            return actor
    return None


def _find_actor_by_class(actor_class: type) -> unreal.Actor | None:
    for actor in _all_level_actors():
        if isinstance(actor, actor_class):
            return actor
    return None


def _spawn_actor(
    actor_class: type, location: unreal.Vector, rotation: unreal.Rotator
) -> unreal.Actor | None:
    try:
        sub = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
        return sub.spawn_actor_from_class(actor_class.static_class(), location, rotation)
    except Exception:
        try:
            return unreal.EditorLevelLibrary.spawn_actor_from_class(
                actor_class, location, rotation
            )
        except Exception as exc:
            _err(f"  spawn_actor_from_class({actor_class.__name__}) failed: {exc}")
            return None


# ---------------------------------------------------------------------------
# Enum creation
# ---------------------------------------------------------------------------

def create_weather_enum() -> unreal.UserDefinedEnum | None:
    _log("--- EWeatherState ---")
    _ensure_directory(DATA_DIR)
    enum = _load_or_create(
        ENUM_NAME, DATA_DIR, unreal.UserDefinedEnum, unreal.EnumFactory()
    )
    if enum is None:
        return None

    helper = getattr(unreal, "EnumEditorUtils", None)
    add_fn = getattr(helper, "add_enumerator_for_user_defined_enum", None) if helper else None
    rename_fn = getattr(helper, "rename_enumerator_for_user_defined_enum", None) if helper else None
    if not (callable(add_fn) and callable(rename_fn)):
        _warn(
            f"  MANUAL: open {ENUM_PATH} and add entries: {ENUM_ENTRIES} "
            "(EnumEditorUtils Python binding unavailable in this engine build)."
        )
        return enum  # type: ignore[return-value]

    added_any = False
    for i, entry in enumerate(ENUM_ENTRIES):
        try:
            add_fn(enum)
            rename_fn(enum, i, entry)
            added_any = True
        except Exception as exc:
            _warn(f"    could not add enumerator '{entry}': {exc}")
            _warn(
                f"  MANUAL: open {ENUM_PATH} and finish entries: {ENUM_ENTRIES}"
            )
            break

    if added_any:
        _save(ENUM_PATH)
    return enum  # type: ignore[return-value]


# ---------------------------------------------------------------------------
# Struct creation
# ---------------------------------------------------------------------------

def create_weather_struct() -> unreal.UserDefinedStruct | None:
    _log("--- FWeatherStateParams ---")
    _ensure_directory(DATA_DIR)
    struct = _load_or_create(
        STRUCT_NAME, DATA_DIR, unreal.UserDefinedStruct, unreal.StructureFactory()
    )
    if struct is None:
        return None
    _warn(
        f"  MANUAL: open {STRUCT_PATH} and add fields (Python "
        "StructureEditorUtils bindings are not reliably exposed):"
    )
    for f in STRUCT_FIELDS:
        comment = f" — {f['comment']}" if "comment" in f else ""
        _warn(f"    {f['name']:<24} {f['type']}{comment}")
    return struct  # type: ignore[return-value]


# ---------------------------------------------------------------------------
# DataTable creation
# ---------------------------------------------------------------------------

def create_weather_data_table() -> unreal.DataTable | None:
    _log("--- DT_WeatherStates ---")
    _ensure_directory(DATA_DIR)

    existing = unreal.EditorAssetLibrary.load_asset(DT_PATH)
    if existing is not None:
        _log(f"  exists  {DT_PATH}")
        return existing  # type: ignore[return-value]

    factory = unreal.DataTableFactory()
    row_struct = unreal.EditorAssetLibrary.load_asset(STRUCT_PATH)
    if row_struct is not None:
        try:
            factory.set_editor_property("struct", row_struct)
        except Exception:
            pass
    else:
        _warn(
            f"  row struct {STRUCT_PATH} not loadable yet — DT will be created "
            "without a bound struct; bind it manually once the struct has its fields."
        )

    table = unreal.AssetToolsHelpers.get_asset_tools().create_asset(
        DT_NAME, DATA_DIR, unreal.DataTable, factory
    )
    if table is None:
        _err(f"  create_asset returned None for {DT_PATH}")
        return None
    _save(DT_PATH)
    _log(f"  created {DT_PATH}")
    _warn(
        f"  MANUAL: once {STRUCT_PATH} has its fields, open {DT_PATH} and add "
        f"rows for: {[r['RowName'] for r in WEATHER_ROWS]}. Row data is in "
        f"{SCHEMA_MANIFEST_PATH.relative_to(REPO_ROOT)}."
    )
    return table  # type: ignore[return-value]


# ---------------------------------------------------------------------------
# BP_WeatherController
# ---------------------------------------------------------------------------

def create_weather_controller_blueprint() -> unreal.Blueprint | None:
    _log("--- BP_WeatherController ---")
    _ensure_directory(WORLD_DIR)

    existing = unreal.EditorAssetLibrary.load_asset(BP_PATH)
    if existing is not None:
        _log(f"  exists  {BP_PATH}")
        bp = existing  # type: ignore[assignment]
    else:
        factory = unreal.BlueprintFactory()
        factory.set_editor_property("parent_class", unreal.Actor)
        bp = unreal.AssetToolsHelpers.get_asset_tools().create_asset(
            BP_NAME, WORLD_DIR, unreal.Blueprint, factory
        )
        if bp is None:
            _err(f"  create_asset returned None for {BP_PATH}")
            return None
        _save(BP_PATH)
        _log(f"  created {BP_PATH}")

    _attach_rain_niagara_component(bp)  # type: ignore[arg-type]
    _save(BP_PATH)
    return bp  # type: ignore[return-value]


def _attach_rain_niagara_component(bp: unreal.Blueprint) -> None:
    """Attach a placeholder NiagaraComponent named 'RainEmitter'."""
    niagara_cls = getattr(unreal, "NiagaraComponent", None)
    if niagara_cls is None:
        _warn(
            "  unreal.NiagaraComponent not exposed; MANUAL: add a "
            "NiagaraComponent named 'RainEmitter' to BP_WeatherController."
        )
        return

    sub = unreal.get_engine_subsystem(unreal.SubobjectDataSubsystem)
    if sub is None:
        _warn(
            "  SubobjectDataSubsystem unavailable; MANUAL: add a "
            "NiagaraComponent named 'RainEmitter' to BP_WeatherController."
        )
        return

    try:
        handles = sub.k2_gather_subobject_data_for_blueprint(bp)
    except Exception as exc:
        _warn(f"  could not gather subobjects: {exc}")
        return

    root_handle = handles[0] if handles else None
    if root_handle is None:
        _warn("  no root subobject on BP_WeatherController")
        return

    # Detect existing RainEmitter to keep this idempotent.
    for h in handles:
        try:
            data = sub.k2_find_subobject_data_from_handle(h)
            obj = data.get_object() if data else None
        except Exception:
            obj = None
        if obj is None:
            continue
        try:
            if isinstance(obj, niagara_cls) and obj.get_name().lower().startswith("rainemitter"):
                _log("  RainEmitter NiagaraComponent already present")
                return
        except Exception:
            pass

    params = unreal.AddNewSubobjectParams()
    params.parent_handle = root_handle
    params.new_class = niagara_cls
    params.blueprint_context = bp
    try:
        handle, fail_reason = sub.add_new_subobject(params)
    except Exception as exc:
        _warn(f"  add_new_subobject RainEmitter crashed: {exc}")
        return
    if not handle.is_valid():
        _warn(f"  add_new_subobject RainEmitter failed: {fail_reason}")
        return
    try:
        sub.rename_subobject(handle, unreal.Text("RainEmitter"))
    except Exception:
        pass

    try:
        comp_obj = sub.k2_find_subobject_data_from_handle(handle).get_object()
        comp = niagara_cls.cast(comp_obj) if comp_obj else None
    except Exception:
        comp = None
    if comp is not None:
        for prop, val in (
            ("auto_activate", False),
            ("b_auto_activate", False),
        ):
            try:
                comp.set_editor_property(prop, val)
            except Exception:
                pass
    _log("  added RainEmitter NiagaraComponent (un-activated, placeholder)")


_BP_VARIABLE_SPEC = """
BP_WeatherController — variables to add (Class Defaults / Variables panel):

  CurrentState         EWeatherState   default = Clear           (Instance Editable)
  TargetState          EWeatherState   default = Clear           (Instance Editable)
  TransitionDuration   float           default = 5.0             (Instance Editable)
  TransitionAlpha      float           default = 0.0             (not exposed)

  FogActor             Soft Object Reference -> ExponentialHeightFogActor
  CloudActor           Soft Object Reference -> VolumetricCloudActor
  SunActor             Soft Object Reference -> DirectionalLight
  PostProcessActor     Soft Object Reference -> PostProcessVolume

  WeatherTable         DataTable Reference -> DT_WeatherStates
  CurrentParams        FWeatherStateParams (live blended snapshot)
  TargetParams         FWeatherStateParams (target state row, refreshed on TargetState change)
"""


_BP_GRAPH_SPEC = """
BP_WeatherController — event graph (manual):

  BeginPlay:
    1. Resolve WeatherTable (DT_WeatherStates) and cache row references.
    2. Read CurrentState, set CurrentParams = row(CurrentState).
    3. TargetState = CurrentState; TargetParams = CurrentParams; TransitionAlpha = 1.0.
    4. Apply CurrentParams to all referenced actors immediately (call ApplyParams).

  On TargetState change (or external SetTargetState):
    - TargetParams = row(TargetState); TransitionAlpha = 0.

  Tick (delta):
    if TransitionAlpha < 1.0:
      TransitionAlpha = clamp(TransitionAlpha + delta / TransitionDuration, 0, 1)
      CurrentParams = lerp(<previous CurrentParams snapshot>, TargetParams, TransitionAlpha)
      ApplyParams(CurrentParams)
      if TransitionAlpha >= 1.0: CurrentState = TargetState

  ApplyParams(p):
    FogActor.FogComponent.FogDensity = p.FogDensity
    FogActor.FogComponent.FogInscatteringColor = p.FogInscatteringColor
    CloudActor.CloudComponent.set_density_scale(p.CloudCoverageFactor)  (or set the cloud material parameter)
    SunActor.LightComponent.Intensity = p.SunIntensity
    SunActor.LightComponent.Temperature = p.SunTemperature
    PostProcessActor.Settings.AutoExposureBias = p.PostProcessExposure
    PostProcessActor.Settings.ColorSaturation = vector_one * p.PostProcessSaturation
    RainEmitter.SetVariableFloat('SpawnRate', p.RainEmissionRate)
    Wind: pass p.WindSpeed into your WindDirectionalSource (added in a later pass).
"""


# ---------------------------------------------------------------------------
# PostProcessVolume in the level
# ---------------------------------------------------------------------------

def ensure_post_process_volume() -> unreal.PostProcessVolume | None:
    _log("--- PP_Weather_Global ---")
    existing = _find_actor_by_labels((PP_LABEL,))
    if existing is not None and isinstance(existing, unreal.PostProcessVolume):
        _log("  exists")
        return existing

    actor = _spawn_actor(
        unreal.PostProcessVolume, unreal.Vector(0.0, 0.0, 0.0), unreal.Rotator()
    )
    if actor is None:
        _err("  could not spawn PostProcessVolume")
        return None
    try:
        actor.set_actor_label(PP_LABEL)
        actor.set_folder_path(WEATHER_FOLDER)
    except Exception:
        pass

    try:
        actor.set_editor_property("unbound", True)
    except Exception:
        try:
            actor.set_editor_property("b_unbound", True)
        except Exception as exc:
            _warn(f"  could not set unbound=True: {exc}")
    _log("  spawned PP_Weather_Global (unbounded)")
    return actor  # type: ignore[return-value]


# ---------------------------------------------------------------------------
# Spawn BP_WeatherController instance + auto-fill references
# ---------------------------------------------------------------------------

def _find_actor_for_role(
    candidate_labels: Iterable[str], actor_class: type
) -> unreal.Actor | None:
    actor = _find_actor_by_labels(candidate_labels)
    if actor is not None and isinstance(actor, actor_class):
        return actor
    return _find_actor_by_class(actor_class)


def spawn_weather_controller_instance(
    bp: unreal.Blueprint | None,
    pp_volume: unreal.PostProcessVolume | None,
    dt: unreal.DataTable | None,
) -> unreal.Actor | None:
    _log("--- WeatherController (instance) ---")
    if bp is None:
        _warn("  BP_WeatherController missing; skipping level placement")
        return None

    existing = _find_actor_by_labels((WEATHER_CONTROLLER_LABEL,))
    if existing is not None:
        _log("  exists")
        actor = existing
    else:
        generated_class = bp.get_editor_property("generated_class")
        if generated_class is None:
            _err("  BP_WeatherController has no generated class yet (compile it?)")
            return None
        actor = _spawn_actor(
            generated_class, unreal.Vector(0.0, 0.0, 0.0), unreal.Rotator()
        )
        if actor is None:
            _err("  could not spawn BP_WeatherController instance")
            return None
        try:
            actor.set_actor_label(WEATHER_CONTROLLER_LABEL)
            actor.set_folder_path(WEATHER_FOLDER)
        except Exception:
            pass
        _log("  spawned WeatherController in level")

    fog_actor = _find_actor_for_role(FOG_LABELS, unreal.ExponentialHeightFog)
    cloud_class = getattr(unreal, "VolumetricCloud", None)
    cloud_actor = (
        _find_actor_for_role(CLOUD_LABELS, cloud_class) if cloud_class else None
    )
    sun_actor = _find_actor_for_role(SUN_LABELS, unreal.DirectionalLight)

    role_map: list[tuple[str, unreal.Object | None]] = [
        ("FogActor", fog_actor),
        ("CloudActor", cloud_actor),
        ("SunActor", sun_actor),
        ("PostProcessActor", pp_volume),
        ("WeatherTable", dt),
    ]

    set_any = False
    for prop_name, value in role_map:
        if value is None:
            _warn(
                f"  could not auto-fill {prop_name}; MANUAL: set it on "
                f"WeatherController in the Details panel."
            )
            continue
        try:
            actor.set_editor_property(prop_name, value)
            set_any = True
            _log(f"  set {prop_name} -> {value.get_name() if hasattr(value, 'get_name') else value}")
        except Exception as exc:
            _warn(
                f"  could not auto-fill {prop_name} ({exc}); MANUAL: set it on "
                f"WeatherController in the Details panel."
            )

    if not set_any:
        _warn(
            "  no component references were auto-filled — likely because the "
            "BP_WeatherController variables haven't been added yet. Re-run "
            "after adding the variables listed in the manual checklist."
        )
    return actor


# ---------------------------------------------------------------------------
# Repo-side schema manifest
# ---------------------------------------------------------------------------

def write_weather_schema_manifest() -> None:
    manifest: dict[str, Any] = {
        "version": 1,
        "enum": {"path": ENUM_PATH, "entries": ENUM_ENTRIES},
        "struct": {"path": STRUCT_PATH, "fields": STRUCT_FIELDS},
        "data_table": {
            "path": DT_PATH,
            "row_struct": STRUCT_PATH,
            "rows": WEATHER_ROWS,
        },
        "blueprint": {"path": BP_PATH, "parent": "Actor"},
        "level_actors": {
            "PostProcessVolume": PP_LABEL,
            "WeatherController": WEATHER_CONTROLLER_LABEL,
        },
    }
    SCHEMA_MANIFEST_PATH.parent.mkdir(parents=True, exist_ok=True)
    SCHEMA_MANIFEST_PATH.write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    _log(f"Wrote schema manifest to {SCHEMA_MANIFEST_PATH}")


# ---------------------------------------------------------------------------
# Manual follow-up summary
# ---------------------------------------------------------------------------

_MANUAL_CHECKLIST = """
Weather system — manual follow-up checklist:

  1. EWeatherState: confirm entries {Clear, Cloudy, Rainy, Stormy} are present.
  2. FWeatherStateParams: add the 9 fields listed above (see warnings).
  3. DT_WeatherStates: bind row struct = FWeatherStateParams, then add the
     4 rows (Clear, Cloudy, Rainy, Stormy) using values from the schema
     manifest at docs/data/mercs2_weather_schema.json.
  4. BP_WeatherController:
       a. Add the variables listed under '_BP_VARIABLE_SPEC'.
       b. Author the event graph per '_BP_GRAPH_SPEC' (BeginPlay + Tick + ApplyParams).
       c. Compile and Save.
  5. WeatherController instance: open Details, verify FogActor / CloudActor /
     SunActor / PostProcessActor / WeatherTable references are filled in.
     Any 'auto-fill failed' warnings above point to references you must set.
  6. Create or import a Niagara rain emitter (e.g. NS_Rain) and assign it to
     RainEmitter on BP_WeatherController. Suggested params:
        SpawnRate variable (float) wired to FWeatherStateParams.RainEmissionRate
        Emission box: 20 m x 20 m around the camera, top-down spawn
        Particle: streak, gravity scale 1.0, lifetime ~ 1s
  7. Add an Input Action IA_DebugWeatherCycle bound to F8 (one-shot Pressed).
     In BP_PlayerController or a debug BP, on IA_DebugWeatherCycle:
        WeatherController.TargetState = (CurrentState + 1) % 4
     -> verifies the lerp path end-to-end.
"""


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def run() -> None:
    _log("=" * 70)
    _log("Mercenaries 2 — Weather state machine scaffold")
    _log("=" * 70)

    create_weather_enum()
    create_weather_struct()
    dt = create_weather_data_table()
    bp = create_weather_controller_blueprint()
    pp = ensure_post_process_volume()
    spawn_weather_controller_instance(bp, pp, dt)
    write_weather_schema_manifest()

    _log("--- Manual follow-up ---")
    for line in _BP_VARIABLE_SPEC.strip().splitlines():
        _warn(line)
    for line in _BP_GRAPH_SPEC.strip().splitlines():
        _warn(line)
    for line in _MANUAL_CHECKLIST.strip().splitlines():
        _warn(line)

    try:
        unreal.EditorLevelLibrary.save_current_level()
        _log("Saved current level.")
    except Exception as exc:
        _warn(f"save_current_level failed: {exc}")

    _log("=" * 70)
    _log("Done. Finish the BP_WeatherController event graph in the editor.")
    _log("=" * 70)


if __name__ == "__main__":
    run()
