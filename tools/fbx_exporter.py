#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
FBX export mirroring tools/gltf_exporter.py (stretch goal).

The Autodesk FBX SDK is not bundled with this repo. When ``fbx`` is importable, extend this
module to read ``submeshes/index.json`` + OBJs and emit ``mesh_scene.fbx``.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path


def main() -> int:
    ap = argparse.ArgumentParser(description="FBX export (stub — requires Autodesk FBX SDK)")
    ap.add_argument("--review-dir", type=Path, required=True)
    ap.add_argument("--out", type=Path, required=True)
    args = ap.parse_args()
    try:
        import fbx  # type: ignore  # noqa: F401
    except ImportError:
        print(
            "fbx_exporter: Autodesk FBX Python SDK not installed; "
            "use glTF (tools/gltf_exporter.py) or install the SDK.",
            file=sys.stderr,
        )
        return 2
    print("fbx_exporter: SDK present but exporter not implemented yet.", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
