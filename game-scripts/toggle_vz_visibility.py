"""Editor smoke-test entry point for vz_state Data Layer visibility.

Run AFTER ``populate_world.py`` (or ``populate_radius_zone.py``) so Data Layers
exist on the map. Step 10 of ``setup_all.py`` calls ``run()`` here automatically
unless ``MERCS2_SETUP_SKIP_VZ_VISIBILITY=1``.

Usage (UE Editor → Tools → Execute Python Script)::

    game-scripts/toggle_vz_visibility.py

Environment:
  MERCS2_VZ_PRESET     pristine_only | act1_default | all_hidden | all_visible_editor
                       (default: act1_default)
  MERCS2_VZ_PREFIX     VZ (default) or PMC
  MERCS2_VZ_SMOKE      Set 1 to only count parent layers (no toggles)
"""

from __future__ import annotations

import os
import sys

_SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
if _SCRIPT_DIR not in sys.path:
    sys.path.insert(0, _SCRIPT_DIR)

import mercs2_visibility_runtime as vis


def main() -> None:
    prefix = os.environ.get("MERCS2_VZ_PREFIX", "VZ")
    if os.environ.get("MERCS2_VZ_SMOKE", "").strip() == "1":
        vis.smoke_test_current_map(prefix=prefix)
        return

    preset = os.environ.get("MERCS2_VZ_PRESET", "act1_default")
    vis.apply_visibility_preset(preset, prefix=prefix)


def run() -> None:
    """Entry point for ``setup_all.py`` and other orchestrators."""
    main()


if __name__ == "__main__":
    run()
