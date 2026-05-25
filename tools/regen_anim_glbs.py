#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Bulk-regenerate animation GLBs under ``<pipeline-root>/animations``.

This is the same entrypoint as ``mercs2_anim_pipeline.py`` (shared CLI), kept as a
stable script name for docs and Make targets.

Examples::

    ./.venv/bin/python tools/regen_anim_glbs.py --pipeline-root ./output --filter all
    ./.venv/bin/python tools/regen_anim_glbs.py --pipeline-root ./output --validation-only
    ./.venv/bin/python tools/regen_anim_glbs.py --pipeline-root ./output --filter all --write-validation
"""

from __future__ import annotations

import sys
from pathlib import Path

_TOOLS = Path(__file__).resolve().parent
if str(_TOOLS) not in sys.path:
    sys.path.insert(0, str(_TOOLS))

from mercs2_anim_pipeline import main  # noqa: E402

if __name__ == "__main__":
    raise SystemExit(main())
