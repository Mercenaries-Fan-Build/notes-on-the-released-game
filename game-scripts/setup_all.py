"""Mercenaries 2 Recreation — Master setup orchestrator.

Runs every ``setup_*.py`` child script in dependency order. Each child is
idempotent (safe to re-run); this script simply invokes them and continues
on failure so you get a full status report in one pass.

Default order:
  1. setup_project          — plugins, folders, Mercs2World map (no WP)
  2. setup_data_structs     — enums, structs, data tables
  3. setup_player_character — Mattias mesh / anim assets
  4. setup_player_controller — Enhanced Input, GameMode BP
  5. setup_basic_hud        — HUD widgets
  6. setup_weather_system   — weather enums / BP scaffold
  7. import_world           — GLB mesh import (slow; skippable)
  8. populate_world         — place meshes + terrain (skippable)
  9. setup_terrain_collision
 10. setup_player_start
 11. setup_water
 12. setup_atmosphere
 13. verify_player_setup    — read-only smoke test (skippable)

Environment variables (optional):
  MERCS2_SETUP_SKIP_IMPORT=1      Skip import_world (step 7)
  MERCS2_SETUP_SKIP_POPULATE=1    Skip populate_world (step 8)
  MERCS2_SETUP_SKIP_VERIFY=1      Skip verify_player_setup (step 13)
  MERCS2_SETUP_SKIP_WORLD=1       Skip import + populate (steps 7–8)
  MERCS2_SETUP_STOP_ON_ERROR=1    Abort remaining steps after first failure
  MERCS2_IMPORT_LIMIT=N           Pass limit to import_world.run_import(N)
  MERCS2_IMPORT_WORLD_CELLS=1     Import ~1.3k c3 cell glTFs (off by default — Nanite risk)
  MERCS2_POPULATE_WORLD_CELLS=1   Place world-cell actors (off by default)
  MERCS2_WORLD_CELLS_MAX=N        Cap cell actors when populating (0 = unlimited)

Run via:
    Tools → Execute Python Script → setup_all.py
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

import mercs2_data_layers as m2dl
import import_world
import populate_world
import setup_atmosphere
import setup_basic_hud
import setup_data_structs
import setup_player_character
import setup_player_controller
import setup_player_start
import setup_project
import setup_terrain_collision
import setup_water
import setup_weather_system
import verify_player_setup


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


def _run_import() -> None:
    limit_raw = os.environ.get("MERCS2_IMPORT_LIMIT", "").strip()
    limit = int(limit_raw) if limit_raw.isdigit() else None
    import_world.run_import(limit=limit)


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
            populate_world.run,
            skip_env="MERCS2_SETUP_SKIP_POPULATE" if not skip_world else "MERCS2_SETUP_SKIP_WORLD",
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
        m2dl,
        import_world,
        populate_world,
        setup_atmosphere,
        setup_basic_hud,
        setup_data_structs,
        setup_player_character,
        setup_player_controller,
        setup_player_start,
        setup_project,
        setup_terrain_collision,
        setup_water,
        setup_weather_system,
        verify_player_setup,
    )
    for mod in modules:
        importlib.reload(mod)


def run() -> dict[str, str]:
    """Run all setup steps. Returns step_id → 'ok' | 'skipped' | 'failed'."""
    _reload_child_modules()
    _log("=" * 70)
    _log("Mercenaries 2 — Full setup (all child scripts)")
    _log("=" * 70)

    stop_on_error = _env_flag("MERCS2_SETUP_STOP_ON_ERROR")
    results: dict[str, str] = {}
    steps = _build_steps()

    for index, step in enumerate(steps, start=1):
        if _should_skip(step):
            _log(f"[{index}/{len(steps)}] SKIP  {step.title} ({step.skip_env})")
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
