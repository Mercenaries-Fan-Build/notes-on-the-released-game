#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Validate rotation pipeline: compare current and proposed yaw conversions.

Given a placement JSON, prints game-space yaw vs UE yaw under current logic
and proposed fix, allowing empirical determination of the correct sign.
"""
from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

_REPO_TOOLS = Path(__file__).resolve().parent
if str(_REPO_TOOLS) not in sys.path:
    sys.path.insert(0, str(_REPO_TOOLS))

from mercs2_coords import game_yaw_to_ue_yaw_deg, game_quat_to_ue_rotator_deg


def _current_yaw_deg(p: dict) -> float | None:
    """Reproduce the current populate_world.py logic (yaw only, no sign fix)."""
    if "rotation_y_deg" in p:
        return float(p["rotation_y_deg"])
    if "rotation_y_rad" in p:
        return math.degrees(float(p["rotation_y_rad"]))
    if "rot_sin" in p and "rot_cos" in p:
        return math.degrees(math.atan2(float(p["rot_sin"]), float(p["rot_cos"])))
    if "rotation_y_sin" in p:
        s = float(p["rotation_y_sin"])
        c = float(p.get("rotation_y_cos", math.sqrt(max(0.0, 1.0 - s * s))))
        return math.degrees(math.atan2(s, c))
    qw = float(p.get("rotation_quat_w", 1.0))
    qx = float(p.get("rotation_quat_x", 0.0))
    qy = float(p.get("rotation_quat_y", 0.0))
    qz = float(p.get("rotation_quat_z", 0.0))
    if abs(qx) < 0.001 and abs(qy) < 0.001 and abs(qz) < 0.001:
        return 0.0
    yaw_rad = math.atan2(2.0 * (qw * qy - qx * qz), 1.0 - 2.0 * (qx * qx + qy * qy))
    return math.degrees(yaw_rad)


def _proposed_yaw_deg(p: dict) -> float | None:
    """Proposed fix: route through game_yaw_to_ue_yaw_deg."""
    if "rot_sin" in p and "rot_cos" in p:
        yaw_rad = math.atan2(float(p["rot_sin"]), float(p["rot_cos"]))
        return game_yaw_to_ue_yaw_deg(yaw_rad)
    if "rotation_y_rad" in p:
        return game_yaw_to_ue_yaw_deg(float(p["rotation_y_rad"]))
    if "rotation_y_sin" in p:
        s = float(p["rotation_y_sin"])
        c = float(p.get("rotation_y_cos", math.sqrt(max(0.0, 1.0 - s * s))))
        return game_yaw_to_ue_yaw_deg(math.atan2(s, c))
    return None


def _proposed_full_rotator(p: dict) -> tuple[float, float, float] | None:
    """Full quaternion decomposition via game_quat_to_ue_rotator_deg."""
    qx = float(p.get("rotation_quat_x", 0.0))
    qy = float(p.get("rotation_quat_y", 0.0))
    qz = float(p.get("rotation_quat_z", 0.0))
    qw = float(p.get("rotation_quat_w", 1.0))
    if abs(qx) < 0.001 and abs(qy) < 0.001 and abs(qz) < 0.001 and abs(qw - 1.0) < 0.001:
        return (0.0, 0.0, 0.0)
    return game_quat_to_ue_rotator_deg(qx, qy, qz, qw)


def _direction_label(yaw_deg: float) -> str:
    """Cardinal direction from yaw (0=forward/+X, 90=right/clockwise)."""
    yaw = yaw_deg % 360
    if yaw < 22.5 or yaw >= 337.5:
        return "+X (east)"
    elif yaw < 67.5:
        return "+X+Z (SE)"
    elif yaw < 112.5:
        return "+Z (south)"
    elif yaw < 157.5:
        return "-X+Z (SW)"
    elif yaw < 202.5:
        return "-X (west)"
    elif yaw < 247.5:
        return "-X-Z (NW)"
    elif yaw < 292.5:
        return "-Z (north)"
    else:
        return "+X-Z (NE)"


def main() -> int:
    ap = argparse.ArgumentParser(description="Validate rotation pipeline")
    ap.add_argument("placements_json", type=Path, help="Placement JSON file")
    ap.add_argument("--max", type=int, default=20, help="Max records to print")
    ap.add_argument("--non-zero-only", action="store_true", help="Only show non-identity rotations")
    ap.add_argument("--has-quat", action="store_true", help="Only show records with non-trivial quaternion data")
    args = ap.parse_args()

    data = json.loads(args.placements_json.read_text(encoding="utf-8"))
    placements = data.get("placements", data if isinstance(data, list) else [])

    printed = 0
    for p in placements:
        if args.non_zero_only:
            yaw = _current_yaw_deg(p)
            if yaw is not None and abs(yaw) < 1.0:
                continue
        if args.has_quat:
            qx = abs(float(p.get("rotation_quat_x", 0.0)))
            qz = abs(float(p.get("rotation_quat_z", 0.0)))
            if qx < 0.05 and qz < 0.05:
                continue

        name = p.get("entity_name", "?")
        pos = p.get("position", {})
        current = _current_yaw_deg(p)
        proposed = _proposed_yaw_deg(p)
        full_rot = _proposed_full_rotator(p)

        print(f"--- {name} ---")
        print(f"  pos: ({pos.get('x', 0):.1f}, {pos.get('y', 0):.1f}, {pos.get('z', 0):.1f})")
        if current is not None:
            print(f"  current UE yaw:  {current:+.1f}°  → {_direction_label(current)}")
        if proposed is not None:
            print(f"  proposed UE yaw: {proposed:+.1f}°  → {_direction_label(proposed)}")
        if full_rot is not None:
            pitch, yaw, roll = full_rot
            print(f"  full rotator:    pitch={pitch:+.1f}° yaw={yaw:+.1f}° roll={roll:+.1f}°")
        if current is not None and proposed is not None:
            diff = proposed - current
            if abs(diff) > 0.1:
                print(f"  DELTA: {diff:+.1f}°")
            else:
                print(f"  (same)")
        print()
        printed += 1
        if printed >= args.max:
            break

    print(f"Showed {printed} records (of {len(placements)} total)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
