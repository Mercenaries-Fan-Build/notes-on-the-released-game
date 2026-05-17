"""Mercenaries 2 coordinate conventions (game extract → glTF / UE).

Coordinate Systems
==================

Game (D3D9, LH Y-up):  X = East–West, Y = height, Z = North–South
glTF (Y-up):           X = East–West, Y = height, Z = North–South (game coords written directly)
UE5 (LH Z-up):         X = East–West, Y = North–South, Z = height

Position transforms
-------------------
  Mesh export:   (x, y, z)_game → (x, y, z)_gltf  (written directly, no Z-negate)
  UE importer:   glTF Y-up → UE Z-up (swaps Y↔Z): UE = (x, z, y)
  Placements:    (x, y, z)_game → UE (100·x, 100·z, 100·y) via game_to_ue
  Both paths produce the same UE coordinates.

Rotation transforms
-------------------
  Binary record stores a UNIT QUATERNION (qx, qy, qz, qw) at offsets +0x14..+0x20.
  For pure Y-axis rotation: qy = sin(yaw/2), qw = cos(yaw/2).
  UE yaw = -(2 * atan2(qy, qw)) in degrees.
  (Verified: qx²+qy²+qz²+qw² ≈ 1.0 across 62k records.)

  Game yaw: rotation around game +Y (up), positive = clockwise looking down.
  UE yaw:   rotation around UE +Z (up), positive = counter-clockwise.
  The sign is NEGATED: game_yaw_deg → -game_yaw_deg for UE.
  Empirically verified against 4 landmarks (PMC HQ, pool, estate walls).

  Full quaternion decomposition preserves pitch and roll for tilted entities
  (tires, rocks, telephone poles — ~16% of records have non-trivial qx/qz).

Terrain atlas (vz_lrterrain.png, 2048×2048)
--------------------------------------------
  Pixel (0, 0) = game (x=-4000, z=-4000) = far southwest
  Pixel (0, 2047) = game (x=+4000, z=-4000) = far southeast
  Pixel (2047, 0) = game (x=-4000, z=+4000) = far northwest
  Pixel (2047, 2047) = game (x=+4000, z=+4000) = far northeast

  Image top (row 0) = south (low Z), image bottom (row 2047) = north (high Z).
  Image left (col 0) = west (low X), image right (col 2047) = east (high X).
  Verified by Pearson correlation of placement density vs atlas luma (r=+0.28
  for original orientation; all rotations/flips score lower).

  UV synthesis in terrain_extractor:
    u = (x + 4000) / 8000
    v = 1 - (z + 4000) / 8000   (V-flip for glTF v=0-bottom convention)

DEPRECATED FUNCTIONS
--------------------
  lh_yup_position, lh_yup_normal, flip_triangle_winding, convert_*_lh_to_gltf,
  lh_yup_rot3x3_row, lh_yup_translation, convert_tangents_meta_lh_to_gltf:
  These applied Z-negate and winding flips that are NO LONGER part of the pipeline.
  Retained for validate_coords_alignment.py only.  Do NOT use in new code.
"""

from __future__ import annotations

import math
from typing import Sequence


def lh_yup_position(x: float, y: float, z: float) -> tuple[float, float, float]:
    """DEPRECATED: Z-negate is no longer applied in the export pipeline.

    Meshes are now written directly in game LH coordinates; UE Interchange
    handles the Y-up→Z-up basis change on import.  Retained only for
    validate_coords_alignment.py diagnostic comparisons.
    """
    return (float(x), float(y), -float(z))


def lh_yup_normal(nx: float, ny: float, nz: float) -> tuple[float, float, float]:
    """DEPRECATED: see lh_yup_position."""
    return (float(nx), float(ny), -float(nz))


def lh_yup_tangent_xyzw(
    tx: float,
    ty: float,
    tz: float,
    w: float,
) -> tuple[float, float, float, float]:
    """DEPRECATED: see lh_yup_position."""
    return (float(tx), float(ty), -float(tz), -float(w))


def flip_triangle_winding(
    face: tuple[int, int, int],
) -> tuple[int, int, int]:
    """DEPRECATED: winding flip is no longer applied in the export pipeline."""
    a, b, c = face
    return (a, c, b)


def lh_yup_rot3x3_row(
    rot: Sequence[Sequence[float]],
) -> list[list[float]]:
    """DEPRECATED: Z-reflect rotation is no longer applied in the export pipeline."""
    if len(rot) < 3:
        return [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]]
    # S * R * S with S = diag(1, 1, -1)
    result: list[list[float]] = [[0.0] * 3 for _ in range(3)]
    for i in range(3):
        for j in range(3):
            si = -1.0 if i == 2 else 1.0
            sj = -1.0 if j == 2 else 1.0
            result[i][j] = si * float(rot[i][j]) * sj
    return result


def lh_yup_translation(
    tx: float,
    ty: float,
    tz: float,
) -> tuple[float, float, float]:
    """DEPRECATED: see lh_yup_position."""
    return (float(tx), float(ty), -float(tz))


def convert_positions_lh_to_gltf(
    positions: list[tuple[float, float, float]],
) -> list[tuple[float, float, float]]:
    """DEPRECATED: no longer used — meshes written directly in game LH coords."""
    return [lh_yup_position(*p) for p in positions]


def convert_normals_lh_to_gltf(
    normals: list[tuple[float, float, float]],
) -> list[tuple[float, float, float]]:
    """DEPRECATED: no longer used — meshes written directly in game LH coords."""
    return [lh_yup_normal(*n) for n in normals]


def convert_faces_lh_to_gltf(
    faces: list[tuple[int, int, int]],
) -> list[tuple[int, int, int]]:
    """DEPRECATED: no longer used — meshes written directly in game LH coords."""
    return [flip_triangle_winding(f) for f in faces]


def convert_uvs_d3d_to_gltf(
    uvs: list[tuple[float, float]],
) -> list[tuple[float, float]]:
    """D3D9 V=0-top → glTF V=0-bottom."""
    return [(u, 1.0 - v) for u, v in uvs]


def convert_tangents_meta_lh_to_gltf(
    tangents: list[tuple[float, float, float, float]],
) -> list[tuple[float, float, float, float]]:
    """DEPRECATED: no longer used — meshes written directly in game LH coords."""
    return [lh_yup_tangent_xyzw(*t) for t in tangents]


# ---------------------------------------------------------------------------
# Rotation: game LH Y-up → UE LH Z-up
# ---------------------------------------------------------------------------

def game_yaw_to_ue_yaw_deg(game_yaw_rad: float) -> float:
    """Convert a game-space yaw (radians, around +Y) to UE yaw (degrees, around +Z).

    Sign is negated: the game's positive yaw (around +Y) is clockwise when viewed
    from above, while UE's positive yaw (around +Z) is counter-clockwise from above.
    Verified against PMC HQ, pool (-135°), and estate wall landmarks.
    """
    return -math.degrees(game_yaw_rad)


def game_quat_to_ue_rotator_deg(
    qx: float, qy: float, qz: float, qw: float,
) -> tuple[float, float, float]:
    """Convert a game-space quaternion (LH Y-up) to UE (pitch, yaw, roll) in degrees.

    Game axes: X right, Y up, Z forward.
    UE axes:   X right (forward), Y right, Z up.  Basis swap: (x,y,z)→(x,z,y).

    The quaternion components swap correspondingly:
      game (qx, qy, qz, qw) → UE (qx, qz, qy, qw)

    Decompose into Euler (pitch, yaw, roll) using UE's ZYX convention.
    Yaw is negated (game CW+ vs UE CCW+ when viewed from above).
    """
    # Swap Y and Z components to move from Y-up to Z-up quaternion basis
    ue_qx = qx
    ue_qy = qz
    ue_qz = qy
    ue_qw = qw

    # Decompose quaternion → Euler (pitch=X, yaw=Z, roll=Y) in UE convention
    # Using the standard aerospace ZYX decomposition for UE's Rotator(pitch, yaw, roll)
    sinr_cosp = 2.0 * (ue_qw * ue_qx + ue_qy * ue_qz)
    cosr_cosp = 1.0 - 2.0 * (ue_qx * ue_qx + ue_qy * ue_qy)
    roll_rad = math.atan2(sinr_cosp, cosr_cosp)

    sinp = 2.0 * (ue_qw * ue_qy - ue_qz * ue_qx)
    if abs(sinp) >= 1.0:
        pitch_rad = math.copysign(math.pi / 2.0, sinp)
    else:
        pitch_rad = math.asin(sinp)

    siny_cosp = 2.0 * (ue_qw * ue_qz + ue_qx * ue_qy)
    cosy_cosp = 1.0 - 2.0 * (ue_qy * ue_qy + ue_qz * ue_qz)
    yaw_rad = math.atan2(siny_cosp, cosy_cosp)

    return (math.degrees(pitch_rad), -math.degrees(yaw_rad), math.degrees(roll_rad))
