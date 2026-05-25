#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Unit tests for the rotation conversion helpers in mercs2_coords.py."""
from __future__ import annotations

import math
import sys
from pathlib import Path

_TOOLS_DIR = Path(__file__).resolve().parent
if str(_TOOLS_DIR) not in sys.path:
    sys.path.insert(0, str(_TOOLS_DIR))

from mercs2_coords import game_yaw_to_ue_yaw_deg, game_quat_to_ue_rotator_deg


def _approx(a: float, b: float, tol: float = 0.1) -> bool:
    return abs(a - b) < tol


def test_yaw_identity() -> None:
    """0 rad game yaw → 0 deg UE yaw."""
    assert game_yaw_to_ue_yaw_deg(0.0) == 0.0


def test_yaw_90_deg() -> None:
    """π/2 rad game yaw → -90 deg UE yaw (sign negated)."""
    result = game_yaw_to_ue_yaw_deg(math.pi / 2)
    assert _approx(result, -90.0), f"Expected -90.0, got {result}"


def test_yaw_negative() -> None:
    """-π/4 rad game yaw → +45 deg UE yaw (sign negated)."""
    result = game_yaw_to_ue_yaw_deg(-math.pi / 4)
    assert _approx(result, 45.0), f"Expected 45.0, got {result}"


def test_yaw_full_circle() -> None:
    """2π rad game yaw → -360 deg UE yaw (sign negated)."""
    result = game_yaw_to_ue_yaw_deg(2 * math.pi)
    assert _approx(result, -360.0), f"Expected -360.0, got {result}"


def test_quat_identity() -> None:
    """Identity quaternion → (0, 0, 0) rotator."""
    pitch, yaw, roll = game_quat_to_ue_rotator_deg(0.0, 0.0, 0.0, 1.0)
    assert _approx(pitch, 0.0) and _approx(yaw, 0.0) and _approx(roll, 0.0), \
        f"Expected (0,0,0), got ({pitch},{yaw},{roll})"


def test_quat_yaw_only_90() -> None:
    """Game quat for 90° yaw around Y → UE yaw ≈ -90° (sign negated)."""
    angle = math.pi / 2
    qw = math.cos(angle / 2)
    qy = math.sin(angle / 2)
    pitch, yaw, roll = game_quat_to_ue_rotator_deg(0.0, qy, 0.0, qw)
    assert _approx(pitch, 0.0), f"pitch={pitch}"
    assert _approx(yaw, -90.0, tol=0.5), f"yaw={yaw}"
    assert _approx(roll, 0.0), f"roll={roll}"


def test_quat_yaw_only_minus45() -> None:
    """Game quat for -45° yaw around Y → UE yaw ≈ +45° (sign negated)."""
    angle = -math.pi / 4
    qw = math.cos(angle / 2)
    qy = math.sin(angle / 2)
    pitch, yaw, roll = game_quat_to_ue_rotator_deg(0.0, qy, 0.0, qw)
    assert _approx(pitch, 0.0), f"pitch={pitch}"
    assert _approx(yaw, 45.0, tol=0.5), f"yaw={yaw}"
    assert _approx(roll, 0.0), f"roll={roll}"


def test_quat_pitch_90() -> None:
    """Game quat for 90° around X (pitch in game) → non-zero pitch in UE."""
    angle = math.pi / 2
    qw = math.cos(angle / 2)
    qx = math.sin(angle / 2)
    pitch, yaw, roll = game_quat_to_ue_rotator_deg(qx, 0.0, 0.0, qw)
    # X rotation in game → roll in UE (X axis stays, but it becomes the forward axis)
    assert abs(pitch) + abs(roll) > 40.0, \
        f"Expected non-trivial pitch/roll, got pitch={pitch}, roll={roll}"


def test_quat_round_trip_yaw() -> None:
    """Round-trip: game yaw via sin/cos → via quaternion should give same UE result."""
    for deg in [0, 30, 45, 90, 135, 180, -30, -90, -135]:
        rad = math.radians(deg)
        # Via yaw helper
        ue_yaw_direct = game_yaw_to_ue_yaw_deg(rad)
        # Via quaternion
        qw = math.cos(rad / 2)
        qy = math.sin(rad / 2)
        _, ue_yaw_quat, _ = game_quat_to_ue_rotator_deg(0.0, qy, 0.0, qw)
        assert _approx(ue_yaw_direct, ue_yaw_quat, tol=0.5), \
            f"deg={deg}: direct={ue_yaw_direct:.1f} vs quat={ue_yaw_quat:.1f}"


def main() -> int:
    tests = [
        test_yaw_identity,
        test_yaw_90_deg,
        test_yaw_negative,
        test_yaw_full_circle,
        test_quat_identity,
        test_quat_yaw_only_90,
        test_quat_yaw_only_minus45,
        test_quat_pitch_90,
        test_quat_round_trip_yaw,
    ]
    passed = 0
    failed = 0
    for t in tests:
        try:
            t()
            print(f"  PASS: {t.__name__}")
            passed += 1
        except AssertionError as e:
            print(f"  FAIL: {t.__name__} — {e}")
            failed += 1
        except Exception as e:
            print(f"  ERROR: {t.__name__} — {e}")
            failed += 1

    print(f"\n{passed} passed, {failed} failed")
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
