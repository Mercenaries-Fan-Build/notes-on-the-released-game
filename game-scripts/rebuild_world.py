"""Rebuild Mercenaries 2 world after a clean-slate Content wipe.

Thin wrapper around ``setup_all.py``. Runs the full 15-step setup pipeline
(scaffold, import, populate, vz visibility preset, collision, atmosphere, verify)
unless skipped via environment variables.

See ``setup_all.py`` for step list and MERCS2_SETUP_* / MERCS2_VZ_* flags.

Run via:
    Tools → Execute Python Script → rebuild_world.py
"""

from __future__ import annotations

import os
import sys

_SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
if _SCRIPT_DIR not in sys.path:
    sys.path.insert(0, _SCRIPT_DIR)

import setup_all


if __name__ == "__main__":
    setup_all.run()
