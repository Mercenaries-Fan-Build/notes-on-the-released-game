"""Mercenaries 2 Recreation — Water (ocean) setup.

UE 5.7 Editor Python script that:

  1. Enables the engine ``Water`` plugin in the .uproject (JSON-patch, not
     a blind rewrite).
  2. Spawns a ``WaterBodyOcean`` actor at the level origin sized to enclose
     the Maracaibo terrain bbox, so the ocean horizon clips cleanly against
     the coast.
  3. Configures the ocean for Z-only mode (no ``WaterZone`` required during
     testing).
  4. Logs the spawned ocean's footprint and the resulting above-water
     terrain area as a sanity check.

The Water plugin requires an editor restart to load its classes the first
time it is enabled. If ``unreal.WaterBodyOcean`` isn't yet exposed, this
script writes the plugin entry, logs a restart-required warning, and exits
without trying to spawn the ocean. Re-run after restart to finish the job.

Run via:
    Tools -> Execute Python Script -> setup_water.py
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import TYPE_CHECKING, Iterable

import unreal

if TYPE_CHECKING:
    from typing import Any


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

LOG_PREFIX = "[Mercs2Water]"

REPO_ROOT = Path(__file__).resolve().parent.parent
UPROJECT_PATH = REPO_ROOT / "UnrealEngineGame" / "UnrealEngineGame.uproject"

WATER_PLUGIN_NAME = "Water"

# World bounds — see AGENTS.md (terrain bbox in UE-space). World is meters
# in source, but UE imports glTF as cm, so multiply by 100 for the ocean
# spline polygon.
WORLD_BBOX_HALF_M = 4000.0          # terrain bbox half-extent (X/Z)
OCEAN_HALF_M = 5000.0               # ocean spline polygon half-extent (X/Z)
WORLD_MIN_Y_M = -167.75             # terrain min elevation
WORLD_MAX_Y_M = 435.75              # terrain max elevation
SEA_LEVEL_UE = -2500.0              # UE Z height for ocean surface (empirical)
GLB_M_TO_UE_CM = 1.0               # glTF imports at 1:1 metre scale

WATER_FOLDER = "Water"

OCEAN_LABEL = "Ocean_Maracaibo"

# Ocean tuning
MAX_WAVE_HEIGHT_M = 1.0


# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

def _log(msg: str) -> None:
    unreal.log(f"{LOG_PREFIX} {msg}")


def _warn(msg: str) -> None:
    unreal.log_warning(f"{LOG_PREFIX} {msg}")


def _err(msg: str) -> None:
    unreal.log_error(f"{LOG_PREFIX} {msg}")


# ---------------------------------------------------------------------------
# .uproject plugin enable
# ---------------------------------------------------------------------------

def enable_water_plugin() -> tuple[bool, bool]:
    """Ensure the ``Water`` plugin is enabled in the .uproject.

    Returns ``(was_changed, restart_required)``. ``restart_required`` is
    True iff we just enabled the plugin AND the Water classes aren't yet
    available in the running editor.
    """
    if not UPROJECT_PATH.is_file():
        _err(f"  .uproject not found at {UPROJECT_PATH}")
        return (False, False)

    raw = UPROJECT_PATH.read_text(encoding="utf-8")
    try:
        data = json.loads(raw)
    except json.JSONDecodeError as exc:
        _err(f"  .uproject is not valid JSON: {exc}")
        return (False, False)

    # Preserve tab indentation if the existing file uses tabs (the seed
    # .uproject does).
    indent: int | str = 4
    for line in raw.splitlines():
        stripped = line.lstrip()
        if not stripped or stripped == line:
            continue
        if line.startswith("\t"):
            indent = "\t"
        break

    plugins = data.setdefault("Plugins", [])
    if not isinstance(plugins, list):
        _err("  .uproject Plugins entry is not an array")
        return (False, False)

    existing = next(
        (p for p in plugins if isinstance(p, dict) and p.get("Name") == WATER_PLUGIN_NAME),
        None,
    )
    changed = False
    if existing is None:
        plugins.append({"Name": WATER_PLUGIN_NAME, "Enabled": True})
        changed = True
        _log(f"  added Plugins entry for {WATER_PLUGIN_NAME}")
    elif existing.get("Enabled") is not True:
        existing["Enabled"] = True
        changed = True
        _log(f"  flipped Enabled=True on existing {WATER_PLUGIN_NAME} entry")
    else:
        _log(f"  {WATER_PLUGIN_NAME} plugin already enabled in .uproject")

    if changed:
        UPROJECT_PATH.write_text(
            json.dumps(data, indent=indent) + "\n", encoding="utf-8"
        )
        _log(f"  wrote {UPROJECT_PATH}")

    classes_available = hasattr(unreal, "WaterBodyOcean")
    restart_required = changed and not classes_available
    if restart_required:
        _warn(
            "  Water plugin was just enabled but its Python classes are not "
            "yet loaded. Restart the editor and re-run setup_water.py to "
            "finish the ocean setup."
        )
    return (changed, restart_required)


# ---------------------------------------------------------------------------
# Actor discovery helpers
# ---------------------------------------------------------------------------

def _all_level_actors() -> list[unreal.Actor]:
    try:
        sub = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
        actors = sub.get_all_level_actors()
        if actors:
            return list(actors)
    except Exception:
        pass
    try:
        return list(unreal.EditorLevelLibrary.get_all_level_actors())
    except Exception:
        return []


def _find_by_label_or_class(
    labels: Iterable[str], actor_class: type
) -> unreal.Actor | None:
    wanted = {c.lower() for c in labels}
    fallback: unreal.Actor | None = None
    for actor in _all_level_actors():
        if not isinstance(actor, actor_class):
            continue
        try:
            label = actor.get_actor_label()
        except Exception:
            label = ""
        if label and label.lower() in wanted:
            return actor
        if fallback is None:
            fallback = actor
    return fallback


def _spawn_actor(
    actor_class: type, location: unreal.Vector, rotation: unreal.Rotator
) -> unreal.Actor | None:
    try:
        sub = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
        return sub.spawn_actor_from_class(actor_class.static_class(), location, rotation)
    except Exception:
        try:
            return unreal.EditorLevelLibrary.spawn_actor_from_class(
                actor_class, location, rotation
            )
        except Exception as exc:
            _err(f"  spawn_actor_from_class({actor_class.__name__}) failed: {exc}")
            return None


# ---------------------------------------------------------------------------
# Ocean spline configuration
# ---------------------------------------------------------------------------

def _ocean_spline_points_cm() -> list[unreal.Vector]:
    """Square polygon centered on the origin, in UE world space (cm)."""
    half = OCEAN_HALF_M * GLB_M_TO_UE_CM
    z = SEA_LEVEL_UE
    return [
        unreal.Vector(-half, -half, z),
        unreal.Vector( half, -half, z),
        unreal.Vector( half,  half, z),
        unreal.Vector(-half,  half, z),
    ]


def _configure_ocean_spline(ocean: unreal.Actor) -> None:
    """Push a 4-point square spline polygon into the ocean actor.

    The spline component name varies across Water plugin versions; we look
    it up via class.
    """
    spline_class = getattr(unreal, "WaterSplineComponent", None) or getattr(
        unreal, "SplineComponent", None
    )
    if spline_class is None:
        _warn("  no Spline component class exposed; skipping spline shape")
        return

    spline = ocean.get_component_by_class(spline_class)
    if spline is None:
        _warn("  ocean has no spline component; skipping spline shape")
        return

    points = _ocean_spline_points_cm()
    coord_space = getattr(unreal, "SplineCoordinateSpace", None)
    space = (
        coord_space.WORLD if coord_space is not None else None
    )
    try:
        if space is not None:
            spline.set_spline_points(points, space)
        else:
            spline.set_spline_points(points)
        _log(f"  set ocean spline to 4-corner square at +/-{OCEAN_HALF_M} m")
    except Exception as exc:
        _warn(
            f"  set_spline_points failed: {exc}. MANUAL: open "
            f"{OCEAN_LABEL} and shape the spline to roughly +/-{OCEAN_HALF_M} m."
        )


# ---------------------------------------------------------------------------
# Ocean spawn + tune
# ---------------------------------------------------------------------------

def configure_ocean() -> unreal.Actor | None:
    cls = getattr(unreal, "WaterBodyOcean", None)
    if cls is None:
        _warn(
            "  unreal.WaterBodyOcean not exposed. Either the Water plugin "
            "isn't loaded yet (restart required) or the engine build doesn't "
            "ship Water. Skipping ocean spawn."
        )
        return None

    _log("--- WaterBodyOcean ---")
    ocean = _find_by_label_or_class((OCEAN_LABEL,), cls)
    if ocean is None:
        ocean = _spawn_actor(
            cls,
            unreal.Vector(0.0, 0.0, SEA_LEVEL_UE),
            unreal.Rotator(),
        )
        if ocean is None:
            _err("  could not spawn WaterBodyOcean")
            return None
        _log("  spawned WaterBodyOcean")
    else:
        _log(f"  reusing existing ocean: {ocean.get_actor_label()}")

    try:
        ocean.set_actor_label(OCEAN_LABEL)
    except Exception:
        pass
    try:
        ocean.set_folder_path(WATER_FOLDER)
    except Exception:
        pass
    try:
        ocean.set_actor_location(
            unreal.Vector(0.0, 0.0, SEA_LEVEL_UE), False, False
        )
    except Exception:
        pass

    _configure_ocean_spline(ocean)

    body_comp_class = getattr(unreal, "WaterBodyOceanComponent", None) or getattr(
        unreal, "WaterBodyComponent", None
    )
    body_comp = (
        ocean.get_component_by_class(body_comp_class)
        if body_comp_class is not None
        else None
    )
    if body_comp is not None:
        # Z-only mode -> renders without a WaterZone for editor testing.
        for prop, value in (
            ("b_always_update_water_mesh", True),
            ("always_update_water_mesh", True),
            ("max_wave_height", MAX_WAVE_HEIGHT_M * GLB_M_TO_UE_CM),
        ):
            try:
                body_comp.set_editor_property(prop, value)
            except Exception:
                pass

        wave_type = getattr(unreal, "WaterWaveSpectrumType", None)
        if wave_type is not None:
            phillips = getattr(wave_type, "PHILLIPS", None) or getattr(
                wave_type, "PHILLIPSSPECTRUM", None
            )
            if phillips is not None:
                try:
                    body_comp.set_editor_property("wave_spectrum_type", phillips)
                except Exception:
                    pass

        _log("  configured ocean body component (Z-only, Phillips spectrum, 1 m waves)")
    else:
        _warn(
            "  WaterBody component class not exposed; MANUAL: open "
            f"{OCEAN_LABEL} and set bAlwaysUpdateWaterMesh = True, "
            "WaveSpectrumType = Phillips, MaxWaveHeight = 100."
        )

    return ocean


# ---------------------------------------------------------------------------
# Sanity logging
# ---------------------------------------------------------------------------

def _log_ocean_footprint(ocean: unreal.Actor | None) -> None:
    if ocean is None:
        return
    half = OCEAN_HALF_M
    terrain_half = WORLD_BBOX_HALF_M
    above_water_area_m2 = (2.0 * terrain_half) ** 2  # crude: full terrain bbox area
    _log("--- Footprint sanity ---")
    _log(
        f"  Ocean spline polygon : {2*half:.0f} m x {2*half:.0f} m, "
        f"Z = {SEA_LEVEL_UE:.1f} UE"
    )
    _log(
        f"  Terrain bbox         : {2*terrain_half:.0f} m x {2*terrain_half:.0f} m, "
        f"Y in [{WORLD_MIN_Y_M:+.2f}, {WORLD_MAX_Y_M:+.2f}] m"
    )
    _log(
        f"  Coast clip margin    : {(half - terrain_half):.0f} m on each side"
    )
    _log(
        f"  Above-water terrain ~: {above_water_area_m2/1e6:.2f} km^2 "
        "(upper bound = full terrain footprint above sea level)"
    )


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def run() -> None:
    _log("=" * 70)
    _log("Mercenaries 2 — Water (ocean) setup")
    _log("=" * 70)

    _log("--- Plugin ---")
    _changed, restart_required = enable_water_plugin()
    if restart_required:
        _warn("Stopping after plugin enable. Restart UE and re-run setup_water.py.")
        return

    ocean = configure_ocean()
    _log_ocean_footprint(ocean)

    try:
        unreal.get_editor_subsystem(unreal.LevelEditorSubsystem).save_current_level()
        _log("Saved current level.")
    except Exception:
        try:
            unreal.EditorLevelLibrary.save_current_level()
            _log("Saved current level.")
        except Exception as exc:
            _warn(f"save_current_level failed: {exc}")

    _log("=" * 70)
    _log("Done. Run setup_weather_system.py next.")
    _log("=" * 70)


if __name__ == "__main__":
    run()
