#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Spawn a grid of arrow-shaped actors at known game-space yaw angles.

Run in UE5 Editor via: Tools → Execute Python Script
Requires a cone or arrow static mesh in the project (uses Engine default cone).

The grid places 8 actors at yaws 0°, 45°, 90°, 135°, 180°, 225°, 270°, 315°
near the PMC HQ area. Compare the arrow directions in UE viewport against
expected cardinal directions to determine if the yaw sign is correct.

Expected results (game convention: +yaw = clockwise from +X looking down +Y):
  0°   → facing +X (east in game)
  90°  → facing +Z (north in game)  → should face +Y in UE (north in UE)
  180° → facing -X (west in game)
  270° → facing -Z (south in game)  → should face -Y in UE (south in UE)
"""
from __future__ import annotations

import math
import sys
from pathlib import Path

_SCRIPTS_DIR = Path(__file__).resolve().parent
if str(_SCRIPTS_DIR) not in sys.path:
    sys.path.insert(0, str(_SCRIPTS_DIR))

import unreal

GAME_TO_UE = 100.0

TEST_YAWS_DEG = [0, 45, 90, 135, 180, 225, 270, 315]

PMC_GAME_X = 2647.0
PMC_GAME_Y = 10.0
PMC_GAME_Z = -951.0

SPACING_M = 50.0

FOLDER = "RotationTestGrid"


def game_to_ue(x: float, y: float, z: float) -> unreal.Vector:
    return unreal.Vector(x * GAME_TO_UE, z * GAME_TO_UE, y * GAME_TO_UE)


def _find_or_create_cone_mesh() -> unreal.StaticMesh:
    """Use Engine's default cone as a directional indicator."""
    mesh_path = "/Engine/BasicShapes/Cone.Cone"
    mesh = unreal.EditorAssetLibrary.load_asset(mesh_path)
    if mesh is None:
        mesh_path = "/Engine/BasicShapes/Cylinder.Cylinder"
        mesh = unreal.EditorAssetLibrary.load_asset(mesh_path)
    return mesh


def main() -> None:
    world = unreal.EditorLevelLibrary.get_editor_world()
    if world is None:
        unreal.log_error("[RotTest] No editor world")
        return

    mesh = _find_or_create_cone_mesh()
    if mesh is None:
        unreal.log_error("[RotTest] Cannot load cone/cylinder mesh")
        return

    editor_subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)

    for i, yaw_deg in enumerate(TEST_YAWS_DEG):
        offset_x = i * SPACING_M
        game_x = PMC_GAME_X + offset_x
        game_y = PMC_GAME_Y + 30.0
        game_z = PMC_GAME_Z

        loc = game_to_ue(game_x, game_y, game_z)

        # Apply yaw directly (current code path — no sign change)
        rot_current = unreal.Rotator(roll=0.0, pitch=0.0, yaw=float(yaw_deg))
        # Apply with negated yaw (proposed fix hypothesis)
        rot_negated = unreal.Rotator(roll=0.0, pitch=0.0, yaw=-float(yaw_deg))

        label_current = f"RotTest_{yaw_deg:03d}deg_current"
        label_negated = f"RotTest_{yaw_deg:03d}deg_negated"

        # Current convention
        actor1 = editor_subsystem.spawn_actor_from_class(
            unreal.StaticMeshActor, loc, rot_current
        )
        if actor1:
            actor1.set_actor_label(label_current)
            actor1.static_mesh_component.set_static_mesh(mesh)
            actor1.set_actor_scale3d(unreal.Vector(0.5, 0.5, 1.5))
            actor1.set_folder_path(FOLDER + "/Current")

        # Negated convention (offset in Z/height to distinguish)
        loc_neg = unreal.Vector(loc.x, loc.y, loc.z + 200.0)
        actor2 = editor_subsystem.spawn_actor_from_class(
            unreal.StaticMeshActor, loc_neg, rot_negated
        )
        if actor2:
            actor2.set_actor_label(label_negated)
            actor2.static_mesh_component.set_static_mesh(mesh)
            actor2.set_actor_scale3d(unreal.Vector(0.5, 0.5, 1.5))
            actor2.set_folder_path(FOLDER + "/Negated")

        unreal.log(
            f"[RotTest] Spawned {yaw_deg}° at game ({game_x:.0f}, {game_y:.0f}, {game_z:.0f})"
        )

    unreal.log(
        f"[RotTest] Done. Two rows of cones in '{FOLDER}/' folder. "
        "Top row = current convention, bottom row = negated. "
        "Compare cone tip directions to expected cardinals."
    )


main()
