"""Mercenaries 2 Recreation — Master setup orchestrator.

Runs every ``setup_*.py`` child script in dependency order. Each child is
idempotent (safe to re-run); this script simply invokes them and continues
on failure so you get a full status report in one pass.

Default order:
  1. setup_project          — plugins, folders, Mercs2World map (no WP)
  2. setup_data_structs     — enums, structs, data tables (incl. mission/spawn DTs)
  3. setup_player_character — Mattias mesh / anim assets
  4. setup_player_controller — Enhanced Input, GameMode BP
  5. setup_basic_hud        — HUD widgets
  6. setup_audio_import     — /Game/Mercs2/Audio/... directory scaffold (no WAV import)
  7. setup_weather_system   — weather enums / BP scaffold
  8. import_world           — GLB mesh import (slow; skippable)
  9. populate_world         — place meshes + terrain (skippable)
 9b. apply_world_bindings   — manifest-driven water/lights/hibernation/roads (skippable)
 10. toggle_vz_visibility   — vz_state Data Layer preset (skippable; needs step 9)
 10b. import_mission_data    — DT_MissionRegistry + DT_SpawnRegistry (optional)
 10c. mission_layer_activator — mission vz_state layers (optional; needs 9–10)
 11. setup_terrain_collision
 12. setup_player_start
 13. setup_water
 14. setup_atmosphere
 15. verify_player_setup    — read-only smoke test (skippable)

Not in this pipeline (run manually when needed):
  - setup_rotation_test_grid.py — yaw diagnostic grid near PMC HQ
  - apply_world_bindings.py — same as step 9b (run alone after make ue-bind-manifest)
  - mercs2_visibility_runtime.py — library imported by toggle_vz_visibility
  - import_mission_data.py / mission_layer_activator.py — mission DT import + layer toggle
  - populate_pmc_base.py / import_pmc_base.py — PMC base testbed workflow
  - fix_*.py — post-setup repairs (Nanite, WP streaming, map errors, etc.)

Environment variables (optional):
  MERCS2_SETUP_SKIP_IMPORT=1        Skip import_world (step 8)
  MERCS2_SETUP_SKIP_POPULATE=1      Skip populate_world (step 9)
  MERCS2_SETUP_SKIP_BINDINGS=1      Skip apply_world_bindings (step 9b)
  MERCS2_SETUP_SKIP_VZ_VISIBILITY=1 Skip toggle_vz_visibility (step 10)
  MERCS2_BINDING_MANIFEST=...       Override ue_game_binding.json path
  MERCS2_SETUP_SKIP_VERIFY=1        Skip verify_player_setup (step 15)
  MERCS2_SETUP_SKIP_WORLD=1         Skip import + populate (steps 8–9)
  MERCS2_FORCE_IMPORT=1             Re-import all GLBs (not skipped when folders exist)
  MERCS2_AUTO_FORCE_IMPORT=0        Disable auto force when /Meshes/WorldCells is empty
  MERCS2_SETUP_STOP_ON_ERROR=1      Abort remaining steps after first failure
  MERCS2_IMPORT_LIMIT=N             Pass limit to import_world.run_import(N)
  MERCS2_IMPORT_WORLD_CELLS=0       Opt out of c3 world-cell GLB import (~2.2k meshes; default ON)
  MERCS2_POPULATE_WORLD_CELLS=0     Opt out of placing c3 cell actors at grid origins (default ON)
  MERCS2_WORLD_CELLS_MAX=N          Cap cell actors when populating (0 = unlimited)
  MERCS2_VZ_PRESET=...              Preset for step 10 (default act1_default)
  MERCS2_VZ_PREFIX=VZ|PMC           Data layer prefix for step 10 (default VZ)
  MERCS2_VZ_SMOKE=1                 Step 10: count layers only, no toggles
  MERCS2_SETUP_IMPORT_MISSION=1     Run import_mission_data after step 2
  MERCS2_MISSION_ID=PmcCon001       Run import (if needed) + mission_layer_activator after step 10
  MERCS2_MISSION_LAYERS=first       Activator: only first layer (baby-step slice)
  MERCS2_SETUP_SKIP_MISSION=1       Skip steps 10b–10c even when MERCS2_MISSION_ID is set

Run via:
    Tools → Execute Python Script → setup_all.py

``rebuild_world.py`` is a thin wrapper that calls ``run()`` here.
"""

from __future__ import annotations

import os
import sys
import traceback
from collections.abc import Callable
from dataclasses import dataclass
from typing import Any

import unreal

_SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
if _SCRIPT_DIR not in sys.path:
    sys.path.insert(0, _SCRIPT_DIR)

import importlib

import mercs2_c3_grid
import mercs2_data_layers as m2dl
import import_world
import populate_world
import setup_atmosphere
import setup_audio_import
import setup_basic_hud
import setup_data_structs
import setup_player_character
import setup_player_controller
import setup_player_start
import setup_project
import setup_terrain_collision
import setup_water
import setup_weather_system
import toggle_vz_visibility
import verify_player_setup
import apply_world_bindings
import mercs2_actor_utils
import mercs2_binding_apply
import mercs2_binding_manifest_io

import import_mission_data
import mission_layer_activator


LOG_PREFIX = "[Mercs2SetupAll]"


def _log(msg: str) -> None:
    unreal.log(f"{LOG_PREFIX} {msg}")


def _warn(msg: str) -> None:
    unreal.log_warning(f"{LOG_PREFIX} {msg}")


def _err(msg: str) -> None:
    unreal.log_error(f"{LOG_PREFIX} {msg}")


def _env_flag(name: str) -> bool:
    return os.environ.get(name, "").strip().lower() in ("1", "true", "yes")


@dataclass(frozen=True)
class SetupStep:
    """One idempotent setup phase."""

    step_id: str
    title: str
    run_fn: Callable[[], Any]
    skip_env: str | None = None


def _apply_full_world_defaults() -> None:
    """Default to full Venezuela import (c3 city cells + standalone meshes).

    ``import_world`` / ``populate_world`` do not use ``maracaibo_asset_list.json``;
    that file is only for the Maracaibo demo subset (``regen-maracaibo-glbs``).
    Set ``MERCS2_IMPORT_WORLD_CELLS=0`` and/or ``MERCS2_POPULATE_WORLD_CELLS=0``
    before running to skip ~2.2k c3 cell meshes (lighter editor session).
    """
    if os.environ.get("MERCS2_IMPORT_WORLD_CELLS", "").strip() == "":
        os.environ["MERCS2_IMPORT_WORLD_CELLS"] = "1"
    if os.environ.get("MERCS2_POPULATE_WORLD_CELLS", "").strip() == "":
        os.environ["MERCS2_POPULATE_WORLD_CELLS"] = "1"


def _run_import() -> None:
    _apply_full_world_defaults()
    limit_raw = os.environ.get("MERCS2_IMPORT_LIMIT", "").strip()
    limit = int(limit_raw) if limit_raw.isdigit() else None
    import_world.run_import(limit=limit)


def _run_populate_world() -> None:
    _apply_full_world_defaults()
    populate_world.run()


def _mission_id() -> str:
    return os.environ.get("MERCS2_MISSION_ID", "").strip()


def _should_run_mission_import() -> bool:
    if _env_flag("MERCS2_SETUP_SKIP_MISSION"):
        return False
    return _env_flag("MERCS2_SETUP_IMPORT_MISSION") or bool(_mission_id())


def _should_run_mission_activator() -> bool:
    if _env_flag("MERCS2_SETUP_SKIP_MISSION"):
        return False
    return bool(_mission_id())


def _run_mission_import() -> None:
    if not _should_run_mission_import():
        return
    import_mission_data.run()


def _run_mission_activator() -> None:
    if not _should_run_mission_activator():
        return
    mission_layer_activator.run()


def _build_steps() -> list[SetupStep]:
    skip_world = _env_flag("MERCS2_SETUP_SKIP_WORLD")
    return [
        SetupStep("project", "Project (map + folders)", setup_project.run),
        SetupStep("data_structs", "Data structs / enums / tables", setup_data_structs.run),
        SetupStep(
            "player_character",
            "Player character assets",
            setup_player_character.run,
        ),
        SetupStep(
            "player_controller",
            "Player controller + input",
            setup_player_controller.run,
        ),
        SetupStep("basic_hud", "HUD widgets", setup_basic_hud.run),
        SetupStep(
            "audio_import",
            "Audio import directories",
            setup_audio_import.run,
        ),
        SetupStep("weather", "Weather system scaffold", setup_weather_system.run),
        SetupStep(
            "import_world",
            "Import world meshes (GLB)",
            _run_import,
            skip_env="MERCS2_SETUP_SKIP_IMPORT" if not skip_world else "MERCS2_SETUP_SKIP_WORLD",
        ),
        SetupStep(
            "populate_world",
            "Populate world placements",
            _run_populate_world,
            skip_env="MERCS2_SETUP_SKIP_POPULATE" if not skip_world else "MERCS2_SETUP_SKIP_WORLD",
        ),
        SetupStep(
            "apply_bindings",
            "Apply Game→UE binding manifest",
            apply_world_bindings.run,
            skip_env="MERCS2_SETUP_SKIP_BINDINGS",
        ),
        SetupStep(
            "vz_visibility",
            "vz_state Data Layer visibility preset",
            toggle_vz_visibility.run,
            skip_env="MERCS2_SETUP_SKIP_VZ_VISIBILITY",
        ),
        SetupStep(
            "import_mission",
            "Import mission/spawn DataTables",
            _run_mission_import,
        ),
        SetupStep(
            "mission_layers",
            "Activate mission vz_state Data Layers",
            _run_mission_activator,
        ),
        SetupStep(
            "terrain_collision",
            "Terrain collision",
            setup_terrain_collision.run,
        ),
        SetupStep("player_start", "PlayerStart placement", setup_player_start.run),
        SetupStep("water", "Ocean / water body", setup_water.run),
        SetupStep("atmosphere", "Atmosphere / lighting", setup_atmosphere.run),
        SetupStep(
            "verify",
            "Verify player setup (read-only)",
            verify_player_setup.run,
            skip_env="MERCS2_SETUP_SKIP_VERIFY",
        ),
    ]


def _should_skip(step: SetupStep) -> bool:
    if step.skip_env and _env_flag(step.skip_env):
        return True
    return False


def _reload_child_modules() -> None:
    """Pick up on-disk script edits without restarting the editor."""
    modules = (
        mercs2_c3_grid,
        m2dl,
        import_world,
        populate_world,
        setup_atmosphere,
        setup_audio_import,
        setup_basic_hud,
        setup_data_structs,
        setup_player_character,
        setup_player_controller,
        setup_player_start,
        setup_project,
        setup_terrain_collision,
        setup_water,
        setup_weather_system,
        toggle_vz_visibility,
        verify_player_setup,
        apply_world_bindings,
        mercs2_actor_utils,
        mercs2_binding_apply,
        mercs2_binding_manifest_io,
        import_mission_data,
        mission_layer_activator,
    )
    for mod in modules:
        importlib.reload(mod)


def run() -> dict[str, str]:
    """Run all setup steps. Returns step_id → 'ok' | 'skipped' | 'failed'."""
    _reload_child_modules()
    _log("=" * 70)
    _log("Mercenaries 2 — Full setup (all child scripts)")
    _log("=" * 70)
    _apply_full_world_defaults()
    try:
        import mercs2_binding_manifest_io as _bm

        if _bm.load_manifest() is None and not _env_flag("MERCS2_SETUP_SKIP_BINDINGS"):
            _warn(
                "ue_game_binding.json not found — run: make ue-bind-manifest OUTPUT=./output "
                "(bindings step will no-op partially; populate uses legacy visibility)"
            )
    except Exception:
        pass
    if _env_flag("MERCS2_IMPORT_WORLD_CELLS"):
        _log(
            "Full world: c3 city-cell import enabled (~2.2k meshes). "
            "Set MERCS2_IMPORT_WORLD_CELLS=0 to skip."
        )

    stop_on_error = _env_flag("MERCS2_SETUP_STOP_ON_ERROR")
    results: dict[str, str] = {}
    steps = _build_steps()

    for index, step in enumerate(steps, start=1):
        if _should_skip(step):
            _log(f"[{index}/{len(steps)}] SKIP  {step.title} ({step.skip_env})")
            results[step.step_id] = "skipped"
            continue
        if step.step_id == "import_mission" and not _should_run_mission_import():
            _log(f"[{index}/{len(steps)}] SKIP  {step.title} (no MERCS2_MISSION_ID / IMPORT)")
            results[step.step_id] = "skipped"
            continue
        if step.step_id == "mission_layers" and not _should_run_mission_activator():
            _log(f"[{index}/{len(steps)}] SKIP  {step.title} (MERCS2_MISSION_ID unset)")
            results[step.step_id] = "skipped"
            continue

        _log(f"[{index}/{len(steps)}] START {step.title}")
        try:
            result = step.run_fn()
            if result is False:
                results[step.step_id] = "failed"
                _err(f"[{index}/{len(steps)}] FAIL  {step.title} (returned False)")
                if stop_on_error:
                    _warn("MERCS2_SETUP_STOP_ON_ERROR=1 — aborting remaining steps")
                    break
                continue
            results[step.step_id] = "ok"
            _log(f"[{index}/{len(steps)}] OK    {step.title}")
        except Exception as exc:
            results[step.step_id] = "failed"
            _err(f"[{index}/{len(steps)}] FAIL  {step.title}: {exc}")
            _err(traceback.format_exc())
            if stop_on_error:
                _warn("MERCS2_SETUP_STOP_ON_ERROR=1 — aborting remaining steps")
                break

    if m2dl.save_dirty_level_packages():
        _log("Saved all dirty packages.")
    else:
        _warn("Could not auto-save — use File → Save All before Play.")

    ok = sum(1 for v in results.values() if v == "ok")
    skipped = sum(1 for v in results.values() if v == "skipped")
    failed = sum(1 for v in results.values() if v == "failed")
    _log("=" * 70)
    _log(f"Setup complete — {ok} ok, {skipped} skipped, {failed} failed")
    for step_id, status in results.items():
        _log(f"  {step_id:20s} {status}")
    _log("=" * 70)

    return results


if __name__ == "__main__":
    run()
