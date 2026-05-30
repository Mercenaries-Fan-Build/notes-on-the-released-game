"""Activate vz_state Data Layers for a mission (Editor / PIE smoke test).

Reads overlay layer stems from ``DT_MissionRegistry`` (row ``MissionId``) or
falls back to ``docs/data/examples/pmccon001_mission.json``. Uses
``mercs2_visibility_runtime`` + ``mercs2_vz_taxonomy`` leaf labels created by
``populate_world.py``.

Run **after** ``populate_world.py`` (and ideally ``toggle_vz_visibility.py``).

Environment:
  MERCS2_MISSION_ID       Required mission key, e.g. PmcCon001
  MERCS2_MISSION_LAYERS   all | layer_additions | first  (default: all)
  MERCS2_VZ_PREFIX        Data layer prefix (default VZ)
  MERCS2_MISSION_JSON     Override mission JSON when DT row missing
  MERCS2_ACTIVATE_CONTRACT_PARENT  1 = also activate VZ_Contract parent (default 1)
"""

from __future__ import annotations

import os
import sys
from pathlib import Path
from typing import Literal

import unreal

_SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
if _SCRIPT_DIR not in sys.path:
    sys.path.insert(0, _SCRIPT_DIR)

import mercs2_data_layers as m2dl
import mercs2_mission_data as mdata
import mercs2_visibility_runtime as vis

LOG_PREFIX = "[Mercs2MissionLayers]"

LayerMode = Literal["all", "layer_additions", "first"]


def _log(msg: str) -> None:
    unreal.log(f"{LOG_PREFIX} {msg}")


def _warn(msg: str) -> None:
    unreal.log_warning(f"{LOG_PREFIX} {msg}")


def _layer_mode() -> LayerMode:
    raw = os.environ.get("MERCS2_MISSION_LAYERS", "all").strip().lower()
    if raw in ("all", "layer_additions", "first"):
        return raw  # type: ignore[return-value]
    _warn(f"Unknown MERCS2_MISSION_LAYERS={raw!r} — using 'all'")
    return "all"


def _select_layers(entry: dict[str, object], mode: LayerMode) -> list[str]:
    flow = entry.get("ueFlow")
    flow_dict = flow if isinstance(flow, dict) else {}
    additions = flow_dict.get("layerAdditions")
    addition_list = (
        [str(x) for x in additions] if isinstance(additions, list) else []
    )
    all_layers = mdata.mission_overlay_layers_from_entry(entry)  # type: ignore[arg-type]

    if mode == "first":
        if addition_list:
            return addition_list[:1]
        return all_layers[:1]
    if mode == "layer_additions":
        return addition_list or all_layers[:1]
    return all_layers


def activate_mission_layers(
    mission_id: str,
    *,
    prefix: str | None = None,
    layer_mode: LayerMode | None = None,
    mission_json: Path | None = None,
    activate_contract_parent: bool = True,
) -> dict[str, int]:
    """Activate mission overlay Data Layers. Returns counts."""
    pfx = prefix or os.environ.get("MERCS2_VZ_PREFIX", "VZ").strip() or "VZ"
    mode = layer_mode or _layer_mode()

    if not m2dl.ensure_mercs2_editor_world_ready(log_title="Mercs2Mission"):
        return {"activated": 0, "missing": 0, "failed": 0}

    json_override = None
    env_json = os.environ.get("MERCS2_MISSION_JSON", "").strip()
    if env_json:
        json_override = Path(env_json)
    entry = mdata.read_mission_entry(
        mission_id, mission_json=mission_json or json_override
    )
    if entry is None:
        return {"activated": 0, "missing": 0, "failed": 1}

    layers = _select_layers(entry, mode)
    if not layers:
        _warn(f"No overlay layers for mission {mission_id}")
        return {"activated": 0, "missing": 0, "failed": 0}

    stats = {"activated": 0, "missing": 0, "failed": 0}

    if activate_contract_parent:
        parent_label = mdata.contract_parent_label(prefix=pfx)
        if vis.toggle_data_layer_by_label(parent_label, True, recursive=False):
            stats["activated"] += 1
        else:
            stats["missing"] += 1
            _warn(
                f"Contract parent {parent_label} not found — run populate_world first."
            )

    _log(f"Mission {mission_id} — activating {len(layers)} layer(s) mode={mode}")
    for layer_stem in layers:
        leaf = mdata.leaf_label_for_layer_stem(layer_stem, prefix=pfx)
        if vis.toggle_data_layer_by_label(leaf, True, recursive=False):
            stats["activated"] += 1
            _log(f"  {layer_stem} → {leaf}")
        else:
            stats["missing"] += 1
            _warn(
                f"  missing layer {leaf} (stem {layer_stem}) — "
                "overlay not populated or label mismatch"
            )

    m2dl.save_dirty_level_packages()
    return stats


def run() -> bool:
    mission_id = os.environ.get("MERCS2_MISSION_ID", "").strip()
    if not mission_id:
        _warn("MERCS2_MISSION_ID not set — nothing to activate")
        return False

    activate_parent = os.environ.get(
        "MERCS2_ACTIVATE_CONTRACT_PARENT", "1"
    ).strip().lower() not in ("0", "false", "no")

    _log("=" * 60)
    _log(f"Mission layer activator — {mission_id}")
    _log("=" * 60)

    stats = activate_mission_layers(
        mission_id,
        activate_contract_parent=activate_parent,
    )
    _log(
        f"Done — activated={stats['activated']} missing={stats['missing']} "
        f"failed={stats.get('failed', 0)}"
    )
    _log("=" * 60)
    return stats["activated"] > 0 and stats.get("failed", 0) == 0


if __name__ == "__main__":
    run()
