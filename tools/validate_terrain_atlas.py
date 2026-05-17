#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Diagnose terrain atlas orientation by sampling at known geographic positions.

Known landmarks from the Mercenaries 2 world:
  - Ocean: North (high Z in game coords, ~z=3800)
  - Mountains: South (low Z, ~z=-3800)
  - PMC HQ: Southwest (~x=2647, z=-951 in game coords)
  - Maracaibo city: West-center (~x=-2000, z=0)

The script samples the terrain atlas PNG at UV positions that correspond to these
landmarks under different UV mapping hypotheses, reporting pixel statistics to
determine which mapping is correct.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

_WORLD_MIN_M = -4000.0
_WORLD_SPAN_M = 8000.0


def _game_to_uv_raw(x: float, z: float) -> tuple[float, float]:
    """Raw planar projection: u from X, v from Z."""
    u = (x - _WORLD_MIN_M) / _WORLD_SPAN_M
    v = (z - _WORLD_MIN_M) / _WORLD_SPAN_M
    return u, v


def _sample_region(img, u: float, v: float, radius_px: int = 16) -> dict:
    """Sample a square region around (u, v) and return colour statistics."""
    w, h = img.size
    px = int(u * w)
    py = int(v * h)
    px = max(radius_px, min(w - radius_px - 1, px))
    py = max(radius_px, min(h - radius_px - 1, py))

    r_sum = g_sum = b_sum = 0
    count = 0
    for dy in range(-radius_px, radius_px + 1):
        for dx in range(-radius_px, radius_px + 1):
            pixel = img.getpixel((px + dx, py + dy))
            r_sum += pixel[0]
            g_sum += pixel[1]
            b_sum += pixel[2]
            count += 1
    return {
        "r": r_sum / count,
        "g": g_sum / count,
        "b": b_sum / count,
        "luma": (0.299 * r_sum + 0.587 * g_sum + 0.114 * b_sum) / count,
        "px": px,
        "py": py,
    }


LANDMARKS = {
    "ocean_north": {"game_x": 0.0, "game_z": 3800.0, "expect": "blue/dark (water)"},
    "mountains_south": {"game_x": 0.0, "game_z": -3800.0, "expect": "bright/green (mountains)"},
    "pmc_southwest": {"game_x": 2647.0, "game_z": -951.0, "expect": "land (brown/green structures)"},
    "maracaibo_west": {"game_x": -2000.0, "game_z": 0.0, "expect": "city/roads (grey/tan)"},
    "center": {"game_x": 0.0, "game_z": 0.0, "expect": "inland (green/brown)"},
    "east_ocean": {"game_x": 0.0, "game_z": 3000.0, "expect": "water or coast"},
}

UV_HYPOTHESES = {
    "raw (u=X, v=Z)": lambda x, z: _game_to_uv_raw(x, z),
    "v_flip (u=X, v=1-Z)": lambda x, z: (_game_to_uv_raw(x, z)[0], 1.0 - _game_to_uv_raw(x, z)[1]),
    "u_flip (u=1-X, v=Z)": lambda x, z: (1.0 - _game_to_uv_raw(x, z)[0], _game_to_uv_raw(x, z)[1]),
    "180_rot (u=1-X, v=1-Z)": lambda x, z: (1.0 - _game_to_uv_raw(x, z)[0], 1.0 - _game_to_uv_raw(x, z)[1]),
}


def main() -> int:
    ap = argparse.ArgumentParser(description="Diagnose terrain atlas UV orientation")
    ap.add_argument(
        "atlas_png",
        type=Path,
        help="Path to vz_lrterrain.png (the terrain atlas)",
    )
    ap.add_argument(
        "--output", "-o",
        type=Path,
        default=None,
        help="Write results JSON to this path (default: stdout)",
    )
    args = ap.parse_args()

    if not args.atlas_png.is_file():
        print(f"error: atlas not found: {args.atlas_png}", file=sys.stderr)
        return 1

    from PIL import Image
    img = Image.open(args.atlas_png)
    if img.mode not in ("RGB", "RGBA"):
        img = img.convert("RGB")

    print(f"Atlas: {args.atlas_png} ({img.size[0]}x{img.size[1]})")
    print()

    results: dict[str, dict] = {}

    for hyp_name, uv_func in UV_HYPOTHESES.items():
        print(f"=== Hypothesis: {hyp_name} ===")
        hyp_results: dict[str, dict] = {}
        for lm_name, lm in LANDMARKS.items():
            u, v = uv_func(lm["game_x"], lm["game_z"])
            stats = _sample_region(img, u, v)
            stats["u"] = round(u, 4)
            stats["v"] = round(v, 4)
            stats["expect"] = lm["expect"]
            hyp_results[lm_name] = stats
            is_blue = stats["b"] > stats["r"] * 1.3 and stats["b"] > stats["g"] * 1.1
            is_dark = stats["luma"] < 60
            is_water = is_blue or is_dark
            tag = "WATER" if is_water else "LAND"
            print(
                f"  {lm_name:20s} UV=({u:.3f},{v:.3f}) "
                f"RGB=({stats['r']:.0f},{stats['g']:.0f},{stats['b']:.0f}) "
                f"luma={stats['luma']:.0f} [{tag}] (expect: {lm['expect']})"
            )
        results[hyp_name] = hyp_results
        print()

    # Score each hypothesis
    print("=== Scoring ===")
    for hyp_name, hyp_results in results.items():
        ocean_north = hyp_results["ocean_north"]
        mountains_south = hyp_results["mountains_south"]
        pmc = hyp_results["pmc_southwest"]

        score = 0
        ocean_is_water = ocean_north["luma"] < 60 or (
            ocean_north["b"] > ocean_north["r"] * 1.3
        )
        mountains_is_land = mountains_south["luma"] > 60
        pmc_is_land = pmc["luma"] > 40

        if ocean_is_water:
            score += 1
        if mountains_is_land:
            score += 1
        if pmc_is_land:
            score += 1

        print(f"  {hyp_name:30s}: score={score}/3 "
              f"(ocean={'WATER' if ocean_is_water else 'LAND'}, "
              f"mountains={'LAND' if mountains_is_land else 'WATER'}, "
              f"pmc={'LAND' if pmc_is_land else 'WATER'})")

    if args.output:
        args.output.write_text(json.dumps(results, indent=2), encoding="utf-8")
        print(f"\nWrote detailed results to {args.output}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
