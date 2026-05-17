"""Shared helper module for UE 5.7 Editor Python — World Partition Data Layers.

Imported by populate_world.py and populate_pmc_base.py to create and manage
Data Layer instances in an Open World / World Partition level.

UE 5.7 quirks handled here:
  - DataLayerInstanceWithAsset does NOT expose ``data_layer_label`` as a
    settable editor property — attempting set_editor_property will crash.
  - sub.get_data_layer_instance(asset) also crashes on
    DataLayerInstanceWithAsset — avoid it entirely.
  - set_parent_data_layer raises "Failed to find property 'data_layer_label'"
    when the subsystem touches the instance internally; parenting is cosmetic
    so we log a warning and continue.

Run from UE Editor via full path:
    unreal.PythonScriptLibrary.execute_python_script(
        "/path/to/mercenaries-game/game-scripts/mercs2_data_layers.py")
"""

from __future__ import annotations

import hashlib
import re
from typing import TYPE_CHECKING

import unreal

if TYPE_CHECKING:
    from typing import Optional

# ---------------------------------------------------------------------------
# Module-level warning-once flags
# ---------------------------------------------------------------------------
_warned_data_layer_parent_skipped: bool = False
_warned_no_world_data_layers: bool = False
_warned_no_data_layer_subsystem: bool = False


# ---------------------------------------------------------------------------
# Subsystem / world accessors
# ---------------------------------------------------------------------------

def data_layer_editor_subsystem() -> Optional[unreal.DataLayerEditorSubsystem]:
    """Return the DataLayerEditorSubsystem singleton, or None if the plugin is off."""
    try:
        return unreal.get_editor_subsystem(unreal.DataLayerEditorSubsystem)
    except Exception:
        return None


def iter_all_level_actors() -> list[unreal.Actor]:
    """Return every actor in the current editor level."""
    merged: list[unreal.Actor] = []
    seen: set[int] = set()

    def _extend(batch: object) -> None:
        try:
            for actor in batch:  # type: ignore[union-attr]
                oid = id(actor)
                if oid in seen:
                    continue
                seen.add(oid)
                merged.append(actor)
        except TypeError:
            pass

    try:
        sub = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
        _extend(sub.get_all_level_actors())
    except Exception:
        pass
    try:
        _extend(unreal.EditorLevelLibrary.get_all_level_actors())
    except Exception:
        pass
    return merged


def get_world_data_layers_actor() -> Optional[unreal.Actor]:
    """Find the WorldDataLayers actor in the level, or None."""
    for actor in iter_all_level_actors():
        if actor.get_class().get_name() == "WorldDataLayers":
            return actor
    return None


def get_editor_world() -> Optional[unreal.World]:
    """Return the current editor world, or None on failure."""
    try:
        return unreal.get_editor_subsystem(unreal.UnrealEditorSubsystem).get_editor_world()
    except Exception:
        pass
    try:
        return unreal.EditorLevelLibrary.get_editor_world()
    except Exception:
        return None


def ensure_mercs2_editor_world_ready(*, log_title: str = "Mercs2") -> Optional[unreal.World]:
    """Check that the editor world supports World Partition + Data Layers.

    Logs actionable guidance if prerequisites are missing. Returns the World
    object or None.
    """
    world = get_editor_world()
    if world is None:
        unreal.log_error(
            f"[{log_title}] Cannot obtain editor world. "
            "Open a level in the editor first."
        )
        return None

    wp = None
    get_wp = getattr(world, "get_world_partition", None)
    if callable(get_wp):
        try:
            wp = get_wp()
        except Exception:
            pass

    if wp is None:
        unreal.log_warning(
            f"[{log_title}] World Partition object not found on this level. "
            "Data Layers require World Partition. If you just created the map, "
            "save it and re-open. Otherwise create an Open World template level "
            "or use Tools → Convert Level to World Partition."
        )

    wdl = get_world_data_layers_actor()
    if wdl is None:
        unreal.log_warning(
            f"[{log_title}] No WorldDataLayers actor found. "
            "Data Layer creation will be unavailable until one exists. "
            "Populate scripts will fall back to editor-only visibility."
        )

    wp_status = "present" if wp else "MISSING"
    wdl_status = "present" if wdl else "MISSING"
    unreal.log(f"[{log_title}] Editor world ready — WP={wp_status}, WorldDataLayers={wdl_status}")
    return world


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

def _safe_set_parent_data_layer(
    sub: unreal.DataLayerEditorSubsystem,
    child: unreal.DataLayerInstance,
    parent: unreal.DataLayerInstance,
) -> None:
    """Attempt to parent *child* under *parent*, swallowing known UE 5.7 crashes.

    UE 5.7 throws "Failed to find property 'data_layer_label'" on
    DataLayerInstanceWithAsset when the subsystem touches the instance
    internally. Parenting is cosmetic; we log ONE warning and continue.
    """
    global _warned_data_layer_parent_skipped
    try:
        sub.set_parent_data_layer(child, parent)
    except Exception as exc:
        if not _warned_data_layer_parent_skipped:
            unreal.log_warning(
                f"[Mercs2DataLayers] set_parent_data_layer skipped — "
                f"UE 5.7 limitation: {exc}"
            )
            _warned_data_layer_parent_skipped = True


def _sanitize_data_layer_asset_name(label: str) -> str:
    """Produce a safe UE asset name from an arbitrary label string.

    - Replace non-alphanumeric characters with ``_``
    - Prefix with ``DL_`` if the result starts with a digit
    - Truncate at 90 characters with a sha256 hash suffix if too long
    """
    sanitized = re.sub(r"[^A-Za-z0-9]", "_", label)
    if sanitized and sanitized[0].isdigit():
        sanitized = f"DL_{sanitized}"
    if len(sanitized) > 90:
        suffix = hashlib.sha256(label.encode()).hexdigest()[:8]
        sanitized = sanitized[:81] + f"_{suffix}"
    return sanitized


# ---------------------------------------------------------------------------
# Asset creation
# ---------------------------------------------------------------------------

def ensure_data_layer_asset(
    asset_name: str,
    package_dir: str,
) -> unreal.DataLayerAsset:
    """Load or create a DataLayerAsset at *package_dir*/*asset_name*.

    Uses DataLayerFactory + AssetTools.create_asset(). Saves via
    EditorAssetLibrary.
    """
    asset_path = f"{package_dir}/{asset_name}"
    existing = unreal.EditorAssetLibrary.load_asset(asset_path)
    if existing is not None:
        return existing  # type: ignore[return-value]

    factory = unreal.DataLayerFactory()
    asset_tools = unreal.AssetToolsHelpers.get_asset_tools()
    asset = asset_tools.create_asset(asset_name, package_dir, unreal.DataLayerAsset, factory)
    if asset is not None:
        unreal.EditorAssetLibrary.save_asset(asset_path)
    return asset  # type: ignore[return-value]


# ---------------------------------------------------------------------------
# Main entry point — get or create a data layer instance
# ---------------------------------------------------------------------------

def get_or_create_data_layer_instance(
    label: str,
    parent: Optional[unreal.DataLayerInstance] = None,
    *,
    asset_package_dir: str = "/Game/DataLayers",
) -> Optional[unreal.DataLayerInstance]:
    """Get or create a DataLayerInstance for *label*.

    CRITICAL constraints (UE 5.7 DataLayerInstanceWithAsset):
      - Do NOT call layer.set_editor_property("data_layer_label", ...)
      - Do NOT call sub.get_data_layer_instance(asset)

    Lookup is via sub.get_data_layer_from_label(). If not found, creates a
    new instance using DataLayerCreationParameters with a backing
    DataLayerAsset.
    """
    global _warned_no_world_data_layers, _warned_no_data_layer_subsystem

    sub = data_layer_editor_subsystem()
    if sub is None:
        if not _warned_no_data_layer_subsystem:
            unreal.log_warning(
                "[Mercs2DataLayers] DataLayerEditorSubsystem unavailable — enable "
                "the DataLayerEditor plugin or ignore data layers on non-WP maps."
            )
            _warned_no_data_layer_subsystem = True
        return None

    asset_name = _sanitize_data_layer_asset_name(label)

    # Try lookup by original label
    layer = sub.get_data_layer_from_label(unreal.Name(label))

    # Also try sanitized name if different (some layers may have been created
    # with the asset name as their label)
    if layer is None and asset_name != label:
        layer = sub.get_data_layer_from_label(unreal.Name(asset_name))

    if layer is not None:
        if parent is not None:
            _safe_set_parent_data_layer(sub, layer, parent)
        return layer

    # Need to create — requires WorldDataLayers actor
    wdl = get_world_data_layers_actor()
    if wdl is None:
        if not _warned_no_world_data_layers:
            unreal.log_warning(
                "[Mercs2DataLayers] No WorldDataLayers actor — "
                "cannot create data layer instances. Add one via "
                "World Settings or convert to World Partition first."
            )
            _warned_no_world_data_layers = True
        return None

    # Ensure backing asset exists
    asset = ensure_data_layer_asset(asset_name, asset_package_dir)
    if asset is None:
        unreal.log_error(
            f"[Mercs2DataLayers] Failed to create DataLayerAsset '{asset_name}' "
            f"in '{asset_package_dir}'"
        )
        return None

    # Build creation parameters
    params = unreal.DataLayerCreationParameters()
    params.set_editor_property("data_layer_asset", asset)
    params.set_editor_property("world_data_layers", wdl)

    layer = sub.create_data_layer_instance(params)
    if layer is None:
        unreal.log_error(
            f"[Mercs2DataLayers] create_data_layer_instance returned None for '{label}'"
        )
        return None

    if parent is not None:
        _safe_set_parent_data_layer(sub, layer, parent)

    return layer


# ---------------------------------------------------------------------------
# Actor assignment
# ---------------------------------------------------------------------------

def add_actor_to_data_layer_if_any(
    actor: unreal.Actor,
    data_layer: Optional[unreal.DataLayerInstance],
) -> None:
    """Add *actor* to *data_layer* if the layer is not None."""
    if data_layer is None:
        return
    sub = data_layer_editor_subsystem()
    if sub is None:
        return
    sub.add_actor_to_data_layer(actor, data_layer)


def set_data_layer_initial_runtime_state(
    layer: Optional[unreal.DataLayerInstance],
    state: unreal.DataLayerRuntimeState,
) -> None:
    """Persist the Data Layer state that PIE/runtime reads (not editor-only overrides)."""
    if layer is None:
        return
    try:
        layer.set_editor_property("initial_runtime_state", state)
    except Exception as exc:
        unreal.log_warning(
            f"[Mercs2DataLayers] Could not set initial_runtime_state on "
            f"'{layer}': {exc}"
        )


def configure_data_layer_for_pie(
    layer: Optional[unreal.DataLayerInstance],
    *,
    activated: bool,
    loaded_in_editor: bool | None = None,
) -> None:
    """Set editor + persisted runtime state so actors on this layer appear in PIE."""
    if layer is None:
        return
    runtime_state = (
        unreal.DataLayerRuntimeState.ACTIVATED
        if activated
        else unreal.DataLayerRuntimeState.UNLOADED
    )
    set_data_layer_initial_runtime_state(layer, runtime_state)
    sub = data_layer_editor_subsystem()
    if sub is None:
        return
    if loaded_in_editor is not None:
        try:
            sub.set_data_layer_is_loaded_in_editor(layer, loaded_in_editor)
        except Exception:
            pass
    try:
        sub.set_data_layer_runtime_state(layer, runtime_state)
    except Exception:
        pass


def world_has_world_partition(world: unreal.World) -> bool:
    """Return True if *world* uses World Partition."""
    get_wp = getattr(world, "get_world_partition", None)
    if not callable(get_wp):
        return False
    try:
        return get_wp() is not None
    except Exception:
        return False


def get_data_layer_by_label(label: str) -> Optional[unreal.DataLayerInstance]:
    """Return an existing Data Layer instance by label, or None."""
    sub = data_layer_editor_subsystem()
    if sub is None:
        return None
    try:
        return sub.get_data_layer_from_label(unreal.Name(label))
    except Exception:
        return None


def _set_runtime_state_on_layer(
    layer: unreal.DataLayerInstance,
    state: unreal.DataLayerRuntimeState,
    *,
    recursive: bool = False,
) -> bool:
    """Set runtime state via DataLayerManager (UE 5.7+) or editor subsystem fallback."""
    try:
        mgr_cls = getattr(unreal, "DataLayerManager", None)
        if mgr_cls is not None:
            mgr = unreal.DataLayerManager.get_data_layer_manager(unreal.EditorLevelLibrary.get_editor_world())
            if mgr is not None:
                fn = getattr(mgr, "set_data_layer_instance_runtime_state", None)
                if callable(fn):
                    return bool(fn(layer, state, recursive))
    except Exception:
        pass
    sub = data_layer_editor_subsystem()
    if sub is None:
        return False
    try:
        sub.set_data_layer_runtime_state(layer, state)
        return True
    except Exception:
        return False


def set_act_parent_states(
    act_states: dict[int, unreal.DataLayerRuntimeState],
    *,
    prefix: str = "VZ",
) -> None:
    """Apply runtime state to VZ_Act1 / VZ_Act2 / VZ_Act3 parent layers (recursive)."""
    for act, state in sorted(act_states.items()):
        label = f"{prefix}_Act{act}"
        layer = get_data_layer_by_label(label)
        if layer is None:
            continue
        set_data_layer_initial_runtime_state(layer, state)
        activated = state == unreal.DataLayerRuntimeState.ACTIVATED
        configure_data_layer_for_pie(
            layer,
            activated=activated,
            loaded_in_editor=activated,
        )
        _set_runtime_state_on_layer(layer, state, recursive=True)


def save_dirty_level_packages() -> bool:
    """Save all dirty packages (level + external actors). Returns True on success."""
    try:
        unreal.EditorLoadingAndSavingUtils.save_dirty_packages(
            save_map_packages=True,
            save_content_packages=True,
        )
        return True
    except Exception as exc:
        unreal.log_warning(f"[Mercs2DataLayers] save_dirty_packages failed: {exc}")
        return False
