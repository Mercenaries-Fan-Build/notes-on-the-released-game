"""Runtime / PIE Data Layer visibility helpers for vz_state overlays.

Thin wrapper around ``mercs2_data_layers`` + ``mercs2_vz_taxonomy`` for toggling
overlay visibility without re-running ``populate_world.py``.

Run from the UE Editor (Tools → Execute Python Script) or the output log::

    import mercs2_visibility_runtime as vis
    vis.apply_visibility_preset("act1_default")
    vis.activate_vz_overlay("00213_blocks__VZ__vz_state_mar_city_act1_P000_Q3.block")

Environment (optional):
  MERCS2_VZ_PREFIX   Data layer prefix (default ``VZ``; use ``PMC`` for PMC base maps)
"""

from __future__ import annotations

import os
from typing import Literal

import unreal

import mercs2_data_layers as m2dl
import mercs2_vz_taxonomy as vz_tax

PresetName = Literal[
    "pristine_only",
    "act1_default",
    "all_hidden",
    "all_visible_editor",
]

_LOG = "[Mercs2Visibility]"


def _prefix() -> str:
    return os.environ.get("MERCS2_VZ_PREFIX", "VZ").strip() or "VZ"


def _runtime_state(activated: bool) -> unreal.DataLayerRuntimeState:
    return (
        unreal.DataLayerRuntimeState.ACTIVATED
        if activated
        else unreal.DataLayerRuntimeState.UNLOADED
    )


def _log(msg: str) -> None:
    unreal.log(f"{_LOG} {msg}")


def _warn(msg: str) -> None:
    unreal.log_warning(f"{_LOG} {msg}")


def toggle_data_layer_by_label(
    label: str,
    activated: bool,
    *,
    recursive: bool = False,
    loaded_in_editor: bool | None = None,
) -> bool:
    """Activate or unload a Data Layer by its UE label."""
    layer = m2dl.get_data_layer_by_label(label)
    if layer is None:
        _warn(f"Data layer not found: {label}")
        return False

    state = _runtime_state(activated)
    m2dl.configure_data_layer_for_pie(
        layer,
        activated=activated,
        loaded_in_editor=activated if loaded_in_editor is None else loaded_in_editor,
    )
    ok = m2dl._set_runtime_state_on_layer(layer, state, recursive=recursive)
    _log(f"{'Activated' if activated else 'Unloaded'} {label} (recursive={recursive})")
    return ok


def activate_vz_overlay(source: str, *, prefix: str | None = None) -> bool:
    """Activate the leaf Data Layer for a vz_state *source* filename."""
    pfx = prefix or _prefix()
    _, _, leaf = vz_tax.data_layer_hierarchy(source, prefix=pfx)
    return toggle_data_layer_by_label(leaf, True, recursive=False)


def deactivate_vz_overlay(source: str, *, prefix: str | None = None) -> bool:
    """Unload the leaf Data Layer for a vz_state *source* filename."""
    pfx = prefix or _prefix()
    _, _, leaf = vz_tax.data_layer_hierarchy(source, prefix=pfx)
    return toggle_data_layer_by_label(leaf, False, recursive=False)


def set_vz_act(act: int, activated: bool, *, prefix: str | None = None) -> bool:
    """Toggle a parent act layer (``VZ_Act1`` … ``VZ_Act3``) recursively."""
    if act not in (1, 2, 3):
        _warn(f"Invalid act {act} — expected 1, 2, or 3")
        return False
    pfx = prefix or _prefix()
    label = f"{pfx}_Act{act}"
    return toggle_data_layer_by_label(label, activated, recursive=True)


def list_vz_parent_layer_labels(*, prefix: str | None = None) -> list[str]:
    """Return the standard parent bucket labels used by populate_world."""
    pfx = prefix or _prefix()
    return [
        f"{pfx}_BaseWorld",
        f"{pfx}_Pristine",
        f"{pfx}_Destroyed",
        f"{pfx}_Staging",
        f"{pfx}_Defenses",
        f"{pfx}_Captured",
        f"{pfx}_Act1",
        f"{pfx}_Act2",
        f"{pfx}_Act3",
        f"{pfx}_Contract",
        f"{pfx}_Other",
    ]


def apply_visibility_preset(
    preset: PresetName,
    *,
    prefix: str | None = None,
) -> dict[str, int]:
    """Apply a canned visibility configuration for PIE smoke tests.

    Presets:
      - ``pristine_only`` — Act1 parent + pristine overlays on; others off
      - ``act1_default`` — same as populate_world initial state
      - ``all_hidden`` — unload all parent buckets recursively
      - ``all_visible_editor`` — activate all parents (editor load; slow)
    """
    pfx = prefix or _prefix()
    stats = {"activated": 0, "unloaded": 0, "missing": 0}

    def _apply_label(label: str, activated: bool, *, recursive: bool = False) -> None:
        layer = m2dl.get_data_layer_by_label(label)
        if layer is None:
            stats["missing"] += 1
            return
        if toggle_data_layer_by_label(label, activated, recursive=recursive):
            if activated:
                stats["activated"] += 1
            else:
                stats["unloaded"] += 1

    if preset == "act1_default":
        m2dl.set_act_parent_states(
            {
                1: unreal.DataLayerRuntimeState.ACTIVATED,
                2: unreal.DataLayerRuntimeState.UNLOADED,
                3: unreal.DataLayerRuntimeState.UNLOADED,
            },
            prefix=pfx,
        )
        _apply_label(f"{pfx}_Pristine", True, recursive=True)
        for kind in ("Destroyed", "Staging", "Defenses", "Captured", "Contract", "Other"):
            _apply_label(f"{pfx}_{kind}", False, recursive=True)
        _log(f"Applied preset act1_default under prefix {pfx}: {stats}")
        return stats

    if preset == "pristine_only":
        _apply_label(f"{pfx}_Act1", True, recursive=True)
        for act in (2, 3):
            _apply_label(f"{pfx}_Act{act}", False, recursive=True)
        _apply_label(f"{pfx}_Pristine", True, recursive=True)
        for kind in ("Destroyed", "Staging", "Defenses", "Captured", "Contract", "Other"):
            _apply_label(f"{pfx}_{kind}", False, recursive=True)
        _log(f"Applied preset pristine_only under prefix {pfx}: {stats}")
        return stats

    if preset == "all_hidden":
        for label in list_vz_parent_layer_labels(prefix=pfx):
            _apply_label(label, False, recursive=True)
        _log(f"Applied preset all_hidden under prefix {pfx}: {stats}")
        return stats

    if preset == "all_visible_editor":
        for label in list_vz_parent_layer_labels(prefix=pfx):
            _apply_label(label, True, recursive=True, loaded_in_editor=True)
        _log(f"Applied preset all_visible_editor under prefix {pfx}: {stats}")
        return stats

    raise ValueError(f"Unknown preset: {preset}")


def smoke_test_current_map(*, prefix: str | None = None) -> dict[str, int]:
    """Quick non-destructive check: count how many parent layers exist."""
    pfx = prefix or _prefix()
    found = 0
    missing = 0
    for label in list_vz_parent_layer_labels(prefix=pfx):
        if m2dl.get_data_layer_by_label(label) is None:
            missing += 1
        else:
            found += 1
    _log(f"Parent layers under {pfx}: {found} found, {missing} missing")
    return {"found": found, "missing": missing}
