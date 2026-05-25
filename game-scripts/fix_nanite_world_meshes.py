"""Disable Nanite on all Mercs2 imported StaticMeshes (fixes Nanite root-page crash).

Run this after import_world if the editor crashes with::

    Cannot allocate more root pages 49152/49152

Usage (Editor Python)::

    py "/path/to/mercenaries-game/game-scripts/fix_nanite_world_meshes.py"
"""

from __future__ import annotations

import os
import sys

import unreal

_SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
if _SCRIPT_DIR not in sys.path:
    sys.path.insert(0, _SCRIPT_DIR)

import mercs2_mesh_utils as mesh_utils

CONTENT_MESHES = "/Game/Mercs2/Meshes"
LOG_PREFIX = "[Mercs2FixNanite]"


def _log(msg: str) -> None:
    unreal.log(f"{LOG_PREFIX} {msg}")


def run() -> bool:
    _log("Disabling Nanite on imported StaticMeshes under /Game/Mercs2/Meshes ...")
    scanned, changed = mesh_utils.bulk_disable_nanite_under(
        CONTENT_MESHES, save=True,
    )
    _log(f"Done — scanned {scanned}, disabled Nanite on {changed} meshes")
    _log("Save All, restart the editor if it was unstable, then re-open the level.")
    return True


if __name__ == "__main__":
    run()
