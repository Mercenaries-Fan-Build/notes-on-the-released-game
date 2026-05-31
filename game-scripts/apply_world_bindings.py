"""Apply Game→UE binding manifest in isolation (Editor).

Run after ``make ue-bind-manifest`` and optionally after ``populate_world.py``.

    Tools → Execute Python Script → apply_world_bindings.py

Environment:
  MERCS2_BINDING_MANIFEST   Override manifest path
  MERCS2_SETUP_SKIP_BINDINGS  (only used from setup_all)
  MERCS2_BINDINGS_SKIP_ROADS / MERCS2_BINDINGS_SKIP_DESTRUCTION / MERCS2_BINDINGS_SKIP_HIBERNATION
  MERCS2_BINDINGS_ROAD_MAX    Cap road spline spawns (default 200)
  MERCS2_BINDINGS_LIGHT_MAX   Cap light apply (0 = unlimited)
"""

from __future__ import annotations

import os
import sys

_SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
if _SCRIPT_DIR not in sys.path:
    sys.path.insert(0, _SCRIPT_DIR)

import importlib

import mercs2_binding_manifest_io
import populate_world

import mercs2_binding_apply as bindings

importlib.reload(mercs2_binding_manifest_io)
importlib.reload(populate_world)
importlib.reload(bindings)


def run() -> dict:
    """Entry for setup_all and Execute Python Script."""
    return bindings.apply_all()


def main() -> None:
    result = run()
    if not result.get("ok", True):
        raise RuntimeError(f"apply_world_bindings failed: {result}")


if __name__ == "__main__":
    main()
