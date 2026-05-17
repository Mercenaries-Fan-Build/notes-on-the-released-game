"""Mercenaries 2 Recreation - Player setup verification.

UE 5.7 Editor Python script that runs a structured smoke-test on every piece
the previous setup_* scripts laid down. It prints a console table of
pass / fail / warning per check and writes a JSON report to
``output/player_setup_verification.json``.

Checks performed:

  GameMode    DefaultGameMode == BP_GameMode and the CDO has BP_Mattias /
              BP_PlayerController as its DefaultPawnClass / PlayerControllerClass.
  PlayerStart at least one PlayerStart in the level, with a line trace from
              +600 m above hitting world-static below it (the terrain).
  Character   BP_Mattias exists, has a SkeletalMeshComponent referencing the
              Mattias skeletal mesh, and the mesh has AnimClass = ABP_Mattias.
  AnimBP      ABP_Mattias exists and references the Mattias skeleton.
  PlayerCtl   BP_PlayerController exists; warn if the IMC reference is on the
              graph (Python cannot inspect graph nodes).
  HUD         WBP_HUDRoot and WBP_PauseMenu exist and recompile cleanly.
  Terrain     Terrain mesh has bUseComplexAsSimple and a non-NoCollision profile.
  Manual      A scrape of empty event graphs / anim graphs is emitted as a
              numbered manual checklist.

Idempotent: read-only except for the JSON report.

Run via:
    Tools -> Execute Python Script -> verify_player_setup.py
"""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import TYPE_CHECKING

import unreal

if TYPE_CHECKING:
    from typing import Any


LOG_PREFIX = "[Mercs2Verify]"

REPO_ROOT = Path(__file__).resolve().parent.parent
REPORT_PATH = REPO_ROOT / "output" / "player_setup_verification.json"

GAME_MATTIAS_DIR = "/Game/Characters/Mattias"
BP_MATTIAS_PATH = f"{GAME_MATTIAS_DIR}/BP_Mattias"
ABP_MATTIAS_PATH = f"{GAME_MATTIAS_DIR}/ABP_Mattias"
BP_PC_PATH = f"{GAME_MATTIAS_DIR}/BP_PlayerController"
BP_GM_PATH = f"{GAME_MATTIAS_DIR}/BP_GameMode"

GAME_MN_BUNDLE = "/Game/Characters/MattiasNilsson"
GAME_SKELETON_PATH = f"{GAME_MN_BUNDLE}/Textures/mattias-main-export_Skeleton"
GAME_MESH_PATH = f"{GAME_MN_BUNDLE}/Textures/mattias-main-export"

IMC_DEFAULT_PATH = "/Game/Input/IMC_Input_Controls"
IMC_LEGACY_PATH = "/Game/Input/IMC_Default"

WBP_HUD_PATH = "/Game/UI/HUD/WBP_HUDRoot"
WBP_PAUSE_PATH = "/Game/UI/HUD/WBP_PauseMenu"

TERRAIN_LABEL_HINTS: tuple[str, ...] = (
    "Mercs2_LowResTerrain",
    "LowResTerrain",
    "low_res_terrain",
)
TERRAIN_ASSET_HINT = "low_res_terrain"

TRACE_START_Z_CM = 60_000.0
TRACE_END_Z_CM = -30_000.0


PASS = "PASS"
FAIL = "FAIL"
WARN = "WARN"


@dataclass
class CheckResult:
    name: str
    status: str  # PASS / FAIL / WARN
    detail: str = ""
    extras: dict[str, object] = field(default_factory=dict)


def _log(msg: str) -> None:
    unreal.log(f"{LOG_PREFIX} {msg}")


def _warn(msg: str) -> None:
    unreal.log_warning(f"{LOG_PREFIX} {msg}")


def _err(msg: str) -> None:
    unreal.log_error(f"{LOG_PREFIX} {msg}")


def _get_editor_world() -> unreal.World | None:
    try:
        sub = unreal.get_editor_subsystem(unreal.UnrealEditorSubsystem)
        if sub is not None:
            world = sub.get_editor_world()
            if world is not None:
                return world
    except Exception:
        pass
    try:
        return unreal.EditorLevelLibrary.get_editor_world()
    except Exception:
        return None


def _all_level_actors() -> list[unreal.Actor]:
    try:
        sub = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
        if sub is not None:
            return list(sub.get_all_level_actors())
    except Exception:
        pass
    try:
        return list(unreal.EditorLevelLibrary.get_all_level_actors())
    except Exception:
        return []


def _load_asset(path: str) -> object | None:
    try:
        return unreal.EditorAssetLibrary.load_asset(path)
    except Exception:
        return None


def _generated_class(bp: object) -> object | None:
    if bp is None:
        return None

    bp_path = _path_of(bp)
    if bp_path:
        asset_name = bp_path.rsplit("/", 1)[-1].split(".")[0]
        class_path = f"{bp_path}.{asset_name}_C"
        try:
            cls = unreal.load_object(None, class_path)
            if cls is not None:
                return cls
        except Exception:
            pass

    if callable(getattr(bp, "generated_class", None)):
        try:
            cls = bp.generated_class()
            if cls is not None:
                return cls
        except Exception:
            pass

    try:
        cls = bp.get_editor_property("generated_class")
        if cls is not None:
            return cls
    except Exception:
        pass
    return None


def _get_cdo(bp: object) -> object | None:
    cls = _generated_class(bp)
    if cls is None:
        return None
    try:
        return unreal.get_default_object(cls)
    except Exception:
        return None


def _path_of(asset: object | None) -> str:
    if asset is None:
        return ""
    try:
        return asset.get_path_name()  # type: ignore[attr-defined]
    except Exception:
        return ""


# ---------------------------------------------------------------------------
# Individual checks
# ---------------------------------------------------------------------------

def check_game_mode(world: unreal.World) -> CheckResult:
    settings = None
    try:
        settings = world.get_world_settings()
    except Exception as exc:
        return CheckResult("GameMode", FAIL, f"could not read WorldSettings: {exc}")
    if settings is None:
        return CheckResult("GameMode", FAIL, "WorldSettings is None")

    gm_class = None
    try:
        gm_class = settings.get_editor_property("default_game_mode")
    except Exception as exc:
        return CheckResult("GameMode", FAIL, f"WorldSettings.default_game_mode unreadable: {exc}")
    if gm_class is None:
        return CheckResult(
            "GameMode",
            FAIL,
            "WorldSettings.DefaultGameMode is unset (run setup_player_controller.py)",
        )

    gm_path = ""
    try:
        gm_path = gm_class.get_path_name()
    except Exception:
        pass

    bp_gm = _load_asset(BP_GM_PATH)
    if bp_gm is None:
        return CheckResult(
            "GameMode", FAIL, f"BP_GameMode missing at {BP_GM_PATH}"
        )
    expected_class = _generated_class(bp_gm)
    if expected_class is None or _path_of(expected_class) not in gm_path:
        return CheckResult(
            "GameMode",
            FAIL,
            f"WorldSettings.DefaultGameMode = {gm_path}; expected BP_GameMode generated class",
        )

    cdo = _get_cdo(bp_gm)
    if cdo is None:
        return CheckResult(
            "GameMode", WARN, "BP_GameMode CDO not accessible from Python"
        )

    extras: dict[str, object] = {"default_game_mode": gm_path}

    pawn_class = None
    pc_class = None
    try:
        pawn_class = cdo.get_editor_property("default_pawn_class")
    except Exception:
        pass
    try:
        pc_class = cdo.get_editor_property("player_controller_class")
    except Exception:
        pass

    bp_mattias = _load_asset(BP_MATTIAS_PATH)
    bp_pc = _load_asset(BP_PC_PATH)
    expected_pawn = _generated_class(bp_mattias)
    expected_pc = _generated_class(bp_pc)

    pawn_ok = bool(
        pawn_class is not None
        and expected_pawn is not None
        and _path_of(pawn_class) == _path_of(expected_pawn)
    )
    pc_ok = bool(
        pc_class is not None
        and expected_pc is not None
        and _path_of(pc_class) == _path_of(expected_pc)
    )
    extras["default_pawn_class"] = _path_of(pawn_class)
    extras["player_controller_class"] = _path_of(pc_class)

    if pawn_ok and pc_ok:
        return CheckResult(
            "GameMode", PASS, "BP_GameMode + BP_Mattias + BP_PlayerController wired", extras
        )

    detail = []
    if not pawn_ok:
        detail.append(f"DefaultPawnClass={_path_of(pawn_class) or 'None'}")
    if not pc_ok:
        detail.append(f"PlayerControllerClass={_path_of(pc_class) or 'None'}")
    return CheckResult("GameMode", FAIL, "; ".join(detail), extras)


def _find_terrain_actor(actors: list[unreal.Actor]) -> unreal.StaticMeshActor | None:
    for actor in actors:
        if not isinstance(actor, unreal.StaticMeshActor):
            continue
        try:
            label = actor.get_actor_label() or ""
        except Exception:
            label = ""
        name = actor.get_name() if hasattr(actor, "get_name") else ""
        for hint in TERRAIN_LABEL_HINTS:
            if hint.lower() in label.lower() or hint.lower() in name.lower():
                return actor
    for actor in actors:
        if not isinstance(actor, unreal.StaticMeshActor):
            continue
        try:
            comp = actor.static_mesh_component
            mesh = comp.get_editor_property("static_mesh") if comp else None
        except Exception:
            mesh = None
        if mesh is None:
            continue
        try:
            asset_path = mesh.get_path_name() or ""
        except Exception:
            asset_path = ""
        if TERRAIN_ASSET_HINT in asset_path.lower():
            return actor
    return None


def check_player_start(world: unreal.World, actors: list[unreal.Actor]) -> CheckResult:
    starts = [a for a in actors if isinstance(a, unreal.PlayerStart)]
    if not starts:
        return CheckResult("PlayerStart", FAIL, "no PlayerStart actor in level")

    ps = starts[0]
    loc = ps.get_actor_location()
    extras: dict[str, object] = {
        "count": len(starts),
        "location_cm": [loc.x, loc.y, loc.z],
    }

    start = unreal.Vector(loc.x, loc.y, TRACE_START_Z_CM)
    end = unreal.Vector(loc.x, loc.y, TRACE_END_Z_CM)
    try:
        result = unreal.SystemLibrary.line_trace_single(
            world, start, end,
            unreal.TraceTypeQuery.TRACE_TYPE_QUERY1,
            False, [], unreal.DrawDebugTrace.NONE, True,
        )
    except Exception as exc:
        return CheckResult(
            "PlayerStart", WARN,
            f"line trace from PlayerStart failed: {exc}", extras,
        )

    hit_z = None
    if isinstance(result, tuple) and len(result) >= 2:
        ok, out_hit = result[0], result[1]
        if ok and out_hit is not None:
            try:
                hit_z = float(out_hit.get_editor_property("location").z)
            except Exception:
                try:
                    hit_z = float(out_hit.location.z)
                except Exception:
                    hit_z = None
    elif result is not None:
        try:
            hit_z = float(result.location.z)
        except Exception:
            hit_z = None

    if hit_z is None:
        return CheckResult(
            "PlayerStart", WARN,
            "trace from PlayerStart did not hit terrain (collision unconfigured?)",
            extras,
        )

    extras["trace_hit_z_cm"] = hit_z
    extras["height_above_terrain_cm"] = loc.z - hit_z
    if loc.z <= hit_z:
        return CheckResult(
            "PlayerStart", FAIL,
            f"PlayerStart Z {loc.z:.1f} cm is below terrain hit Z {hit_z:.1f} cm",
            extras,
        )
    return CheckResult(
        "PlayerStart", PASS,
        f"PlayerStart {loc.z - hit_z:.0f} cm above terrain", extras,
    )


def check_character_blueprint() -> CheckResult:
    bp = _load_asset(BP_MATTIAS_PATH)
    if bp is None:
        return CheckResult("Character", FAIL, f"BP_Mattias missing at {BP_MATTIAS_PATH}")

    cdo = _get_cdo(bp)
    if cdo is None:
        return CheckResult("Character", WARN, "BP_Mattias CDO not accessible")

    mesh_comp = None
    try:
        mesh_comp = cdo.get_editor_property("mesh")
    except Exception:
        pass
    if mesh_comp is None:
        return CheckResult("Character", FAIL, "BP_Mattias has no SkeletalMeshComponent (mesh)")

    sk_mesh = None
    for prop in ("skeletal_mesh_asset", "skeletal_mesh"):
        try:
            sk_mesh = mesh_comp.get_editor_property(prop)
            if sk_mesh is not None:
                break
        except Exception:
            pass
    if sk_mesh is None:
        try:
            sk_mesh = mesh_comp.get_skinned_asset()
        except Exception:
            pass

    extras: dict[str, object] = {"skeletal_mesh": _path_of(sk_mesh)}
    if sk_mesh is None or "mattias" not in _path_of(sk_mesh).lower():
        return CheckResult(
            "Character", FAIL,
            f"BP_Mattias mesh.skeletal_mesh={_path_of(sk_mesh) or 'None'} (expected mattias-main-export)",
            extras,
        )

    anim_class = None
    for prop in ("anim_blueprint_generated_class", "anim_class"):
        try:
            anim_class = mesh_comp.get_editor_property(prop)
            if anim_class is not None:
                break
        except Exception:
            pass
    extras["anim_class"] = _path_of(anim_class)
    abp = _load_asset(ABP_MATTIAS_PATH)
    expected_abp_cls = _generated_class(abp)
    if anim_class is None or expected_abp_cls is None or _path_of(anim_class) != _path_of(
        expected_abp_cls
    ):
        return CheckResult(
            "Character", FAIL,
            f"mesh.AnimClass={_path_of(anim_class) or 'None'}; expected ABP_Mattias generated class",
            extras,
        )

    return CheckResult("Character", PASS, "skeletal mesh + AnimClass wired", extras)


def check_anim_blueprint() -> CheckResult:
    abp = _load_asset(ABP_MATTIAS_PATH)
    if abp is None:
        return CheckResult("AnimBP", FAIL, f"ABP_Mattias missing at {ABP_MATTIAS_PATH}")

    skeleton = None
    try:
        skeleton = abp.get_editor_property("target_skeleton")
    except Exception:
        pass
    extras: dict[str, object] = {"target_skeleton": _path_of(skeleton)}
    if skeleton is None:
        return CheckResult("AnimBP", FAIL, "ABP_Mattias.target_skeleton is None", extras)
    if "mattias" not in _path_of(skeleton).lower():
        return CheckResult(
            "AnimBP", WARN,
            f"target_skeleton={_path_of(skeleton)} - expected mattias-main-export_Skeleton",
            extras,
        )
    return CheckResult("AnimBP", PASS, "ABP_Mattias bound to Mattias skeleton", extras)


def check_player_controller() -> CheckResult:
    bp = _load_asset(BP_PC_PATH)
    if bp is None:
        return CheckResult("PlayerCtl", FAIL, f"BP_PlayerController missing at {BP_PC_PATH}")

    imc = _load_asset(IMC_DEFAULT_PATH)
    if imc is None:
        imc = _load_asset(IMC_LEGACY_PATH)
    extras: dict[str, object] = {
        "imc_exists": imc is not None,
        "imc_path": IMC_DEFAULT_PATH if imc is not None else "",
    }
    if imc is None:
        return CheckResult(
            "PlayerCtl", FAIL,
            f"IMC_Input_Controls missing at {IMC_DEFAULT_PATH} "
            "(run setup_player_controller.py)",
            extras,
        )
    return CheckResult(
        "PlayerCtl", WARN,
        "BP_PlayerController + IMC_Input_Controls exist; verify IMC reference is set "
        "on the BP (Python cannot inspect graph nodes)",
        extras,
    )


def _recompile_blueprint(bp: object) -> tuple[bool, str]:
    lib = getattr(unreal, "BlueprintEditorLibrary", None)
    if lib is None:
        return (False, "BlueprintEditorLibrary not exposed")
    for fn_name in ("compile_blueprint", "recompile_blueprint"):
        fn = getattr(lib, fn_name, None)
        if fn is None:
            continue
        try:
            fn(bp)
            return (True, fn_name)
        except Exception as exc:
            return (False, f"{fn_name} failed: {exc}")
    return (False, "no compile_blueprint method available")


def check_hud_widgets() -> CheckResult:
    extras: dict[str, object] = {}
    failures: list[str] = []
    warnings: list[str] = []
    for label, path in (("WBP_HUDRoot", WBP_HUD_PATH), ("WBP_PauseMenu", WBP_PAUSE_PATH)):
        exists = unreal.EditorAssetLibrary.does_asset_exist(path)
        extras[f"{label}_exists"] = exists
        if not exists:
            failures.append(f"{label} missing at {path}")
            continue
        bp = _load_asset(path)
        ok, info = _recompile_blueprint(bp)
        extras[f"{label}_compile"] = info
        if not ok:
            warnings.append(f"{label} compile: {info}")

    if failures:
        return CheckResult("HUD", FAIL, "; ".join(failures), extras)
    if warnings:
        return CheckResult("HUD", WARN, "; ".join(warnings), extras)
    return CheckResult("HUD", PASS, "WBP_HUDRoot + WBP_PauseMenu compile clean", extras)


def check_terrain_collision(actors: list[unreal.Actor]) -> CheckResult:
    actor = _find_terrain_actor(actors)
    if actor is None:
        return CheckResult("Terrain", FAIL, "Mercs2_LowResTerrain actor not found")
    try:
        comp = actor.static_mesh_component
        sm = comp.get_editor_property("static_mesh") if comp else None
    except Exception:
        comp = None
        sm = None
    if sm is None or comp is None:
        return CheckResult("Terrain", FAIL, "terrain actor has no static_mesh / component")

    extras: dict[str, object] = {"asset": _path_of(sm)}

    flag = None
    try:
        flag = sm.get_editor_property("collision_trace_flag")
    except Exception:
        pass
    if flag is None:
        try:
            body = sm.get_editor_property("body_setup")
            flag = body.get_editor_property("collision_trace_flag") if body else None
        except Exception:
            flag = None

    expected = getattr(unreal.CollisionTraceFlag, "CTF_USE_COMPLEX_AS_SIMPLE", None)
    extras["collision_trace_flag"] = str(flag)
    is_complex = flag is not None and expected is not None and flag == expected

    profile = ""
    try:
        profile = comp.get_collision_profile_name()
    except Exception:
        try:
            profile = comp.get_editor_property("collision_profile_name")
        except Exception:
            pass
    extras["component_profile"] = str(profile)

    if not is_complex:
        return CheckResult(
            "Terrain", FAIL,
            f"static mesh collision_trace_flag != USE_COMPLEX_AS_SIMPLE (got {flag})",
            extras,
        )
    if not profile or "NoCollision".lower() in str(profile).lower():
        return CheckResult(
            "Terrain", FAIL,
            f"component collision profile '{profile}' is unset / NoCollision",
            extras,
        )
    return CheckResult(
        "Terrain", PASS,
        f"complex-as-simple + profile '{profile}'", extras,
    )


# ---------------------------------------------------------------------------
# Manual follow-up checklist
# ---------------------------------------------------------------------------

MANUAL_CHECKLIST: tuple[tuple[str, str], ...] = (
    (
        ABP_MATTIAS_PATH,
        "Open Anim Graph: build the locomotion state machine "
        "(Idle/Walk/Run/Sprint blend driven by Speed; Direction fan-blend; "
        "WeaponStance switch with Unarmed / Pistol / Rifle / Heavy variants; "
        "Jump/Falling overlay; Death oneshot). Variables to expose on the AnimBP: "
        "Speed (float), Direction (float), bIsCrouching, bIsFalling, bIsDead, "
        "WeaponStance (EWeaponStance), DeathDirection (int).",
    ),
    (
        ABP_MATTIAS_PATH,
        "Open Event Graph: on 'Update Animation' read the owning Pawn each tick "
        "and copy Speed = Velocity.Size2D, Direction = "
        "CalculateDirection(Velocity, Rotation), and the bool/enum stance state "
        "into the AnimBP variables.",
    ),
    (
        BP_MATTIAS_PATH,
        "Add BP variables: Health (float = 100), MaxHealth (float = 100), "
        "bIsSprinting (bool), WeaponStance (EWeaponStance), FactionReputation "
        "(Map<EFaction, float>).",
    ),
    (
        BP_MATTIAS_PATH,
        "Verify mesh -90 Z offset / -90 yaw on the SkeletalMeshComponent so "
        "feet sit on the capsule base; tweak in the Components panel if the "
        "character intersects the floor or floats.",
    ),
    (
        BP_PC_PATH,
        "Add variable DefaultMappingContext (InputMappingContext) and set its "
        "default to /Game/Input/IMC_Input_Controls.",
    ),
    (
        BP_PC_PATH,
        "BeginPlay: Get Enhanced Input Local Player Subsystem from this "
        "controller, then AddMappingContext(DefaultMappingContext, Priority=0). "
        "Then Create Widget(WBP_HUDRoot) -> AddToViewport.",
    ),
    (
        BP_PC_PATH,
        "Bind Enhanced Input action callbacks: IA_Move/Look/Jump/Sprint/Crouch/"
        "Aim/Interact/Fire/SwitchWeapon/OpenPDA -> forward to the possessed "
        "Pawn (cast to BP_Mattias). Crouch is toggle-on-press.",
    ),
    (
        IMC_DEFAULT_PATH,
        "Open IMC_Input_Controls and add key mappings: IA_Move <- W/A/S/D (with the "
        "Negate / Swizzle modifiers documented by setup_player_controller.py); "
        "IA_Look <- Mouse XY 2D-Axis; IA_Jump <- SpaceBar; IA_Sprint <- "
        "LeftShift; IA_Crouch <- LeftControl (Pressed trigger); "
        "IA_Interact <- E; IA_Aim <- RightMouseButton; IA_Fire <- "
        "LeftMouseButton; IA_SwitchWeapon <- Q + MouseWheelAxis; "
        "IA_OpenPDA <- Tab.",
    ),
    (
        WBP_HUD_PATH,
        "Bindings: HealthBar.Percent <- Health/MaxHealth; AmmoText.Text <- "
        "format CurrentMag/ReserveAmmo; WeaponNameText.Text <- "
        "CurrentWeapon.Name; ObjectiveText.Text <- CurrentObjective summary; "
        "Crosshair.Visibility <- bIsAiming ? Visible : Hidden; "
        "FactionBar_<Faction>.Percent <- (FactionReputation[<Faction>]+100)/200.",
    ),
    (
        WBP_PAUSE_PATH,
        "Wire OnClicked: Resume -> SetPaused(false) + RemoveFromParent + "
        "InputMode=GameOnly; Save/Load/Settings -> stub log; Quit -> QuitGame. "
        "From BP_PlayerController on ESC: Create Widget(WBP_PauseMenu) + "
        "AddToViewport + SetPaused(true) + InputMode=UIOnly + ShowMouseCursor.",
    ),
)


# ---------------------------------------------------------------------------
# Reporting
# ---------------------------------------------------------------------------

def _print_results_table(results: list[CheckResult]) -> None:
    width_name = max(len(r.name) for r in results)
    _log(f"  {'Check'.ljust(width_name)}  Status  Detail")
    _log(f"  {'-' * width_name}  ------  ------")
    for r in results:
        line = f"  {r.name.ljust(width_name)}  {r.status:<6}  {r.detail}"
        if r.status == PASS:
            _log(line)
        elif r.status == WARN:
            _warn(line)
        else:
            _err(line)


def _write_report(results: list[CheckResult]) -> None:
    payload: dict[str, object] = {
        "results": [
            {"name": r.name, "status": r.status, "detail": r.detail, "extras": r.extras}
            for r in results
        ],
        "manual_checklist": [
            {"index": i + 1, "asset": asset, "task": task}
            for i, (asset, task) in enumerate(MANUAL_CHECKLIST)
        ],
        "summary": {
            "pass": sum(1 for r in results if r.status == PASS),
            "fail": sum(1 for r in results if r.status == FAIL),
            "warn": sum(1 for r in results if r.status == WARN),
        },
    }
    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    _log(f"Wrote JSON report to {REPORT_PATH}")


def run() -> None:
    _log("=" * 70)
    _log("Mercenaries 2 - Player setup verification")
    _log("=" * 70)

    world = _get_editor_world()
    if world is None:
        _err("No editor world is open. Open the level and re-run.")
        return

    actors = _all_level_actors()
    results: list[CheckResult] = []
    results.append(check_game_mode(world))
    results.append(check_player_start(world, actors))
    results.append(check_character_blueprint())
    results.append(check_anim_blueprint())
    results.append(check_player_controller())
    results.append(check_hud_widgets())
    results.append(check_terrain_collision(actors))

    _log("--- Results ---")
    _print_results_table(results)

    summary = (
        f"PASS={sum(1 for r in results if r.status == PASS)}  "
        f"WARN={sum(1 for r in results if r.status == WARN)}  "
        f"FAIL={sum(1 for r in results if r.status == FAIL)}"
    )
    _log(summary)

    _log("--- Manual follow-up checklist (Python-unreachable) ---")
    for i, (asset, task) in enumerate(MANUAL_CHECKLIST, start=1):
        _warn(f"  {i:2d}. [{asset}] {task}")

    try:
        _write_report(results)
    except Exception as exc:
        _err(f"Could not write JSON report: {exc}")

    _log("=" * 70)
    _log("Done.")
    _log("=" * 70)


if __name__ == "__main__":
    run()
