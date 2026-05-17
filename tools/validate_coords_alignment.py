#!/usr/bin/env python3
"""Sanity-check game LH placement vs glTF RH export convention.

After ``gltf_exporter`` negates Z for glTF, a placement at game (x, y, z) should
match imported mesh space when UE applies its RH→LH Z-up import (same as
``game_to_ue``: UE X = 100·x, UE Y = 100·z, UE Z = 100·y).

Run: .venv/bin/python3 tools/validate_coords_alignment.py
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

_REPO = Path(__file__).resolve().parents[1]
if str(_REPO / "tools") not in sys.path:
    sys.path.insert(0, str(_REPO / "tools"))

from mercs2_coords import lh_yup_position  # noqa: E402

GAME_TO_UE = 100.0


def game_to_ue(x: float, y: float, z: float) -> tuple[float, float, float]:
    return (x * GAME_TO_UE, z * GAME_TO_UE, y * GAME_TO_UE)


def placement_to_gltf_rh_then_ue(x: float, y: float, z: float) -> tuple[float, float, float]:
    """Placement if it went through the same RH export as meshes, then UE import."""
    gx, gy, gz = lh_yup_position(x, y, z)
    return game_to_ue(gx, gy, gz)


def main() -> int:
  # PMC HQ sample from pmc_base.json
    pmc_path = _REPO / "output" / "placements" / "pmc_base.json"
    if pmc_path.is_file():
        data = json.loads(pmc_path.read_text(encoding="utf-8"))
        recs = data if isinstance(data, list) else data.get("placements", [])
        hq = next(
            (r for r in recs if "bld_hq" in str(r.get("entity_name", "")).lower()),
            None,
        )
        if hq and isinstance(hq.get("position"), dict):
            pos = hq["position"]
            x, y, z = float(pos["x"]), float(pos["y"]), float(pos["z"])
            ue_place = game_to_ue(x, y, z)
            rh = lh_yup_position(x, y, z)
            print(f"PMC HQ entity game: ({x:.1f}, {y:.1f}, {z:.1f})")
            print(f"  populate game_to_ue → UE cm: ({ue_place[0]:.0f}, {ue_place[1]:.0f}, {ue_place[2]:.0f})")
            print(f"  glTF RH position (z negated): ({rh[0]:.1f}, {rh[1]:.1f}, {rh[2]:.1f})")
            print(
                "  Expected: imported hero GLB origin at same UE location as placement "
                "after re-import with fixed GLBs."
            )
    else:
        print(f"No {pmc_path} — run extract-placements first for live samples.")

    print("\nConvention summary:")
    print("  Game / placements: LH Y-up (x, y, z)")
    print("  glTF export: (x, y, -z) RH Y-up")
    print("  game_to_ue: UE (100*x, 100*z, 100*y)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
