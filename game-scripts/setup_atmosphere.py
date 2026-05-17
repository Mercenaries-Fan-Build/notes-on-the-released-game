"""Mercenaries 2 Recreation — Tropical atmosphere setup.

UE 5.7 Editor Python script that tunes the existing atmosphere actors in
the open level to match a tropical / coastal (northern Venezuela) look:

  - ExponentialHeightFog  -> warm tropical haze + volumetric fog
  - SkyAtmosphere         -> confirm tropical-friendly defaults
  - VolumetricCloud       -> spawn if missing, light cumulus layer
  - DirectionalLight      -> tropical-noon intensity + warm color temp

Discovery rules (idempotent):

  1. Look up actors by display label using a small list of candidate names
     (the level may have been seeded by ``populate_world.setup_lighting``
     using ``Atmosphere_World`` / ``Sun_Tropical`` *or* by an earlier hand
     pass that named them ``SkyAtmosphere_World`` / ``AtmosphericLight_World``).
  2. If no labeled match, fall back to the first actor of the matching class
     in the level.
  3. If still nothing, spawn a new one and label it appropriately.

Run via:
    Tools -> Execute Python Script -> setup_atmosphere.py
"""

from __future__ import annotations

from typing import TYPE_CHECKING, Iterable

import unreal

if TYPE_CHECKING:
    from typing import Any


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

LOG_PREFIX = "[Mercs2Atmosphere]"

LIGHTING_FOLDER = "Lighting"

# Candidate display-label lists used when locating existing actors. First
# match wins; order favors the names introduced by setup scripts.
FOG_LABELS = ("HeightFog_World",)
SKY_ATMO_LABELS = ("SkyAtmosphere_World", "Atmosphere_World")
SUN_LABELS = ("AtmosphericLight_World", "Sun_Tropical", "DirectionalLight_World")
CLOUD_LABELS = ("VolumetricCloud_World", "VolumetricClouds")

# Engine-default volumetric cloud material — works without any project assets.
DEFAULT_CLOUD_MATERIAL_PATH = (
    "/Engine/EngineSky/VolumetricClouds/m_SimpleVolumetricCloud."
    "m_SimpleVolumetricCloud"
)


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
# Actor discovery helpers
# ---------------------------------------------------------------------------

def _all_level_actors() -> list[unreal.Actor]:
    """Return every actor in the current editor world."""
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


def _find_by_label(candidates: Iterable[str]) -> unreal.Actor | None:
    wanted = {c.lower() for c in candidates}
    for actor in _all_level_actors():
        try:
            label = actor.get_actor_label()
        except Exception:
            continue
        if label and label.lower() in wanted:
            return actor
    return None


def _find_by_class(actor_class: type) -> unreal.Actor | None:
    for actor in _all_level_actors():
        if isinstance(actor, actor_class):
            return actor
    return None


def _spawn_actor(
    actor_class: type,
    location: unreal.Vector,
    rotation: unreal.Rotator,
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


def _ensure_actor(
    actor_class: type,
    candidate_labels: Iterable[str],
    default_label: str,
    spawn_location: unreal.Vector | None = None,
    spawn_rotation: unreal.Rotator | None = None,
) -> unreal.Actor | None:
    """Idempotent locate-or-spawn helper.

    Try labels first, then class match, then spawn. Always (re-)apply the
    canonical label + folder.
    """
    actor = _find_by_label(candidate_labels)
    if actor is None:
        actor = _find_by_class(actor_class)
    if actor is None:
        loc = spawn_location if spawn_location is not None else unreal.Vector()
        rot = spawn_rotation if spawn_rotation is not None else unreal.Rotator()
        actor = _spawn_actor(actor_class, loc, rot)
        if actor is None:
            return None
        _log(f"  spawned {actor_class.__name__} as {default_label}")

    try:
        if actor.get_actor_label() != default_label:
            # Don't rename an existing labeled actor unless it's clearly
            # untitled / engine default. Keep user-chosen names intact.
            label = actor.get_actor_label()
            if not label or label.startswith(actor_class.__name__):
                actor.set_actor_label(default_label)
    except Exception:
        pass

    try:
        actor.set_folder_path(LIGHTING_FOLDER)
    except Exception:
        pass

    return actor


def _set_props(component_or_actor: unreal.Object, props: dict[str, Any]) -> None:
    """Best-effort bulk ``set_editor_property`` with per-prop warnings."""
    target_name = type(component_or_actor).__name__
    for key, value in props.items():
        try:
            component_or_actor.set_editor_property(key, value)
        except Exception as exc:
            _warn(f"    {target_name}.{key} = {value!r} failed: {exc}")


# ---------------------------------------------------------------------------
# Sub-step: ExponentialHeightFog
# ---------------------------------------------------------------------------

def configure_height_fog() -> unreal.Actor | None:
    _log("--- ExponentialHeightFog ---")
    fog = _ensure_actor(
        unreal.ExponentialHeightFog,
        FOG_LABELS,
        "HeightFog_World",
        spawn_location=unreal.Vector(0.0, 0.0, 3000.0),
    )
    if fog is None:
        _err("  could not locate or spawn ExponentialHeightFog")
        return None

    comp = fog.get_component_by_class(unreal.ExponentialHeightFogComponent)
    if comp is None:
        _err("  ExponentialHeightFog has no fog component (engine quirk?)")
        return fog

    _set_props(comp, {
        "fog_density": 0.025,
        "fog_height_falloff": 0.2,
        "fog_inscattering_color": unreal.LinearColor(0.86, 0.78, 0.62, 1.0),
        "directional_inscattering_color": unreal.LinearColor(1.0, 0.9, 0.55, 1.0),
        "directional_inscattering_exponent": 4.0,
        "directional_inscattering_start_distance": 1000.0,
        "start_distance": 0.0,
        # Volumetric fog
        "volumetric_fog": True,
        "volumetric_fog_distance": 50000.0,
        "volumetric_fog_scattering_distribution": 0.2,
        "volumetric_fog_extinction_scale": 1.0,
        "volumetric_fog_static_lighting_scattering_intensity": 1.0,
    })

    _log("  configured HeightFog_World (tropical warm haze + volumetric fog)")
    return fog


# ---------------------------------------------------------------------------
# Sub-step: SkyAtmosphere
# ---------------------------------------------------------------------------

def configure_sky_atmosphere() -> unreal.Actor | None:
    _log("--- SkyAtmosphere ---")
    atmo = _ensure_actor(
        unreal.SkyAtmosphere,
        SKY_ATMO_LABELS,
        "SkyAtmosphere_World",
    )
    if atmo is None:
        _err("  could not locate or spawn SkyAtmosphere")
        return None

    comp = atmo.get_component_by_class(unreal.SkyAtmosphereComponent)
    if comp is None:
        _warn("  SkyAtmosphere has no atmosphere component; skipping tuning")
        return atmo

    # Leave Rayleigh/Mie at engine defaults — they already produce a tropical
    # blue sky. Just confirm the documented values are what we expect.
    _set_props(comp, {
        "multi_scattering_factor": 1.0,
        "sky_luminance_factor": unreal.LinearColor(1.0, 1.0, 1.0, 1.0),
    })
    _log("  confirmed SkyAtmosphere defaults (multi-scatter=1.0, sky-lum=1,1,1,1)")
    return atmo


# ---------------------------------------------------------------------------
# Sub-step: VolumetricCloud
# ---------------------------------------------------------------------------

def configure_volumetric_cloud() -> unreal.Actor | None:
    _log("--- VolumetricCloud ---")
    cloud_class = getattr(unreal, "VolumetricCloud", None)
    if cloud_class is None:
        _warn("  unreal.VolumetricCloud not exposed; skipping cloud setup")
        return None

    cloud = _ensure_actor(
        cloud_class,
        CLOUD_LABELS,
        "VolumetricCloud_World",
    )
    if cloud is None:
        _err("  could not locate or spawn VolumetricCloud")
        return None

    comp_class = getattr(unreal, "VolumetricCloudComponent", None)
    comp = cloud.get_component_by_class(comp_class) if comp_class is not None else None
    if comp is None:
        _warn("  VolumetricCloud has no cloud component; skipping tuning")
        return cloud

    _set_props(comp, {
        "layer_bottom_altitude": 3.0,
        "layer_height": 6.0,
        "tracing_start_max_distance": 350.0,
        "tracing_max_distance": 50.0,
    })

    material = unreal.EditorAssetLibrary.load_asset(DEFAULT_CLOUD_MATERIAL_PATH)
    if material is not None:
        try:
            comp.set_editor_property("material", material)
            _log(f"  assigned cloud material {DEFAULT_CLOUD_MATERIAL_PATH}")
        except Exception as exc:
            _warn(f"  could not set cloud material: {exc}")
    else:
        _warn(
            f"  engine default cloud material missing at "
            f"{DEFAULT_CLOUD_MATERIAL_PATH}; leaving whatever is currently set"
        )

    _log("  configured VolumetricCloud_World (3 km base, 6 km thick cumulus layer)")
    return cloud


# ---------------------------------------------------------------------------
# Sub-step: DirectionalLight (sun)
# ---------------------------------------------------------------------------

def configure_directional_light() -> unreal.Actor | None:
    _log("--- DirectionalLight ---")
    sun = _ensure_actor(
        unreal.DirectionalLight,
        SUN_LABELS,
        "AtmosphericLight_World",
        spawn_location=unreal.Vector(0.0, 0.0, 50000.0),
        spawn_rotation=unreal.Rotator(roll=0.0, pitch=168.0, yaw=-59.0),
    )
    if sun is None:
        _err("  could not locate or spawn DirectionalLight")
        return None

    comp = sun.get_component_by_class(unreal.DirectionalLightComponent)
    if comp is None:
        _err("  DirectionalLight has no light component (engine quirk?)")
        return sun

    _set_props(comp, {
        "mobility": unreal.ComponentMobility.MOVABLE,
        "intensity": 8.0,
        "light_source_angle": 0.5357,
        "use_temperature": True,
        "temperature": 5800.0,
        "atmosphere_sun_light": True,
        "atmosphere_sun_light_index": 0,
        "cast_shadows": True,
    })
    _log("  configured AtmosphericLight_World (tropical noon, 5800K, 0.5357 deg sun)")
    return sun


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def run() -> None:
    _log("=" * 70)
    _log("Mercenaries 2 — Tropical atmosphere tune-up")
    _log("=" * 70)

    touched: list[unreal.Actor] = []
    for actor in (
        configure_height_fog(),
        configure_sky_atmosphere(),
        configure_volumetric_cloud(),
        configure_directional_light(),
    ):
        if actor is not None:
            touched.append(actor)

    if touched:
        _log("--- Touched actors ---")
        for a in touched:
            try:
                label = a.get_actor_label()
            except Exception:
                label = "<unlabeled>"
            _log(f"  {type(a).__name__:<28} {label}")

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
    _log("Done. Run setup_water.py next.")
    _log("=" * 70)


if __name__ == "__main__":
    run()
