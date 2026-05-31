"""Decode Mercenaries 2 c3XXXX world streaming cell IDs (CLI/tools entry point).

Canonical implementation: ``game-scripts/mercs2_c3_grid.py`` (UE Editor uses that
copy directly so ``importlib.reload`` always sees fixes).
"""

from __future__ import annotations

import sys
from pathlib import Path

_GAME_SCRIPTS = Path(__file__).resolve().parent.parent / "game-scripts"
if str(_GAME_SCRIPTS) not in sys.path:
    sys.path.insert(0, str(_GAME_SCRIPTS))

from mercs2_c3_grid import *  # noqa: F403
