"""Mercenaries 2 Recreation — Player Character setup (Mattias Nilsson).

UE 5.7 Editor Python script that:

  1. Stages the pre-wired Mattias asset bundle from ``MattiasNilssonExport/``
     into the UE project's Content folder at the path the .uasset packages
     were saved against (``Content/Characters/MattiasNilsson/...``). This
     preserves the cross-references between skeleton, mesh, materials,
     animations, and blend spaces.
  2. Forces an asset registry rescan so the staged assets become loadable.
  3. Creates the **authored** project assets:
       - ``/Game/Characters/Mattias/ABP_Mattias`` (Animation Blueprint stub)
       - ``/Game/Characters/Mattias/BP_Mattias``  (Character Blueprint)
     with sensible CharacterMovement defaults and component scaffolding.
  4. Logs MANUAL follow-up steps for the parts the Python API cannot reach
     (Anim Graph state machines, exposed BP variable graphs, etc.).

Provenance: the rig + animations come from the ``MattiasNilssonExport/``
pre-bundled set. We do NOT re-import the loose .uasset files under
``MattiasNilsson/Animations/`` — those are kept as a fallback only.

Idempotent: re-running skips any files / assets that already exist.

Run via:
    Tools → Execute Python Script → setup_player_character.py
"""

from __future__ import annotations

import shutil
from pathlib import Path
from typing import TYPE_CHECKING

import unreal

if TYPE_CHECKING:
    from typing import Any


# ---------------------------------------------------------------------------
# UE 5.7 compatibility helpers
# ---------------------------------------------------------------------------

def _load_bp_class(bp_path: str) -> unreal.Class | None:
    """Load the generated UClass from a Blueprint asset path."""
    asset_name = bp_path.rsplit("/", 1)[-1]
    class_path = f"{bp_path}.{asset_name}_C"
    try:
        cls = unreal.load_object(None, class_path)
        if cls is not None:
            return cls
    except Exception:
        pass
    bp = unreal.EditorAssetLibrary.load_asset(bp_path)
    if bp is None:
        return None
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


def _set_skinned_asset(mesh_comp: unreal.SkeletalMeshComponent, sk_mesh: unreal.Object) -> bool:
    """UE 5.7+ compatible setter for SkeletalMeshComponent's mesh asset."""
    for setter in ("set_skinned_asset", "set_skeletal_mesh"):
        fn = getattr(mesh_comp, setter, None)
        if callable(fn):
            try:
                fn(sk_mesh)
                return True
            except Exception:
                pass
    for prop in ("skeletal_mesh_asset", "skeletal_mesh"):
        try:
            mesh_comp.set_editor_property(prop, sk_mesh)
            return True
        except Exception:
            pass
    return False


# ---------------------------------------------------------------------------
# Paths & constants
# ---------------------------------------------------------------------------

LOG_PREFIX = "[Mercs2Character]"

REPO_ROOT = Path(__file__).resolve().parent.parent
EXPORT_BUNDLE = REPO_ROOT / "MattiasNilssonExport"

# Staging target — must match the package paths embedded in the .uassets,
# which are /Game/Characters/MattiasNilsson/...
UE_PROJECT_ROOT = REPO_ROOT / "UnrealEngineGame"
UE_CONTENT_ROOT = UE_PROJECT_ROOT / "Content"
STAGED_BUNDLE = UE_CONTENT_ROOT / "Characters" / "MattiasNilsson"

# Internal /Game paths the bundle resolves to once staged
GAME_BUNDLE_ROOT = "/Game/Characters/MattiasNilsson"
GAME_SKELETON_PATH = f"{GAME_BUNDLE_ROOT}/Textures/mattias-main-export_Skeleton"
GAME_MESH_PATH = f"{GAME_BUNDLE_ROOT}/Textures/mattias-main-export"
GAME_PHYSICS_ASSET_PATH = f"{GAME_BUNDLE_ROOT}/Textures/mattias-main-export_PhysicsAsset"

# Authored project assets (what populate / gameplay code refers to)
AUTHORED_DIR = "/Game/Characters/Mattias"
ABP_PATH = f"{AUTHORED_DIR}/ABP_Mattias"
BP_PATH = f"{AUTHORED_DIR}/BP_Mattias"

# CharacterMovement tuning — M2-style traversal (UE units = cm)
WALK_SPEED = 250.0
RUN_SPEED = 600.0
SPRINT_SPEED = 900.0
CROUCH_SPEED = 150.0
JUMP_Z_VELOCITY = 600.0

# Camera tuning
SPRING_ARM_LENGTH = 300.0
SPRING_ARM_SOCKET_OFFSET_Z = 60.0  # ~1m above shoulder of a 180cm character


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
# Stage 1 — Copy the pre-wired bundle into Content/
# ---------------------------------------------------------------------------

_UASSET_SUFFIXES = (".uasset", ".umap")


def _copy_bundle_into_content() -> tuple[int, int]:
    """Copy ``MattiasNilssonExport/`` → ``Content/Characters/MattiasNilsson/``.

    Returns ``(copied, skipped)``. Only files with .uasset/.umap suffixes are
    copied; loose .fbx files in ``Unarmed/`` are kept in the repo as source
    references and are not staged.
    """
    if not EXPORT_BUNDLE.is_dir():
        _err(f"Source bundle missing: {EXPORT_BUNDLE}")
        return (0, 0)

    if not UE_CONTENT_ROOT.is_dir():
        _err(f"UE Content folder missing: {UE_CONTENT_ROOT}")
        return (0, 0)

    STAGED_BUNDLE.mkdir(parents=True, exist_ok=True)

    copied = 0
    skipped = 0
    for src in EXPORT_BUNDLE.rglob("*"):
        if not src.is_file():
            continue
        if not src.suffix.lower() in _UASSET_SUFFIXES:
            continue

        rel = src.relative_to(EXPORT_BUNDLE)
        dst = STAGED_BUNDLE / rel
        if dst.exists():
            skipped += 1
            continue

        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
        copied += 1

    _log(f"Bundle stage: copied {copied}, skipped {skipped} already-staged files")
    return (copied, skipped)


def _rescan_asset_registry() -> None:
    """Force the asset registry to pick up newly staged .uasset files."""
    ar = unreal.AssetRegistryHelpers.get_asset_registry()
    try:
        ar.scan_paths_synchronous([GAME_BUNDLE_ROOT], force_rescan=True)
    except TypeError:
        ar.scan_paths_synchronous([GAME_BUNDLE_ROOT], True)
    _log(f"Asset registry rescan complete for {GAME_BUNDLE_ROOT}")


def _verify_bundle_loaded() -> bool:
    """Confirm the core skeleton/mesh assets resolve after staging."""
    ok = True
    for path in (GAME_SKELETON_PATH, GAME_MESH_PATH):
        if unreal.EditorAssetLibrary.does_asset_exist(path):
            _log(f"  resolved {path}")
        else:
            _err(f"  MISSING after stage+rescan: {path}")
            ok = False
    return ok


# ---------------------------------------------------------------------------
# Stage 2 — Animation Blueprint stub
# ---------------------------------------------------------------------------

def _ensure_authored_dir() -> None:
    if not unreal.EditorAssetLibrary.does_directory_exist(AUTHORED_DIR):
        unreal.EditorAssetLibrary.make_directory(AUTHORED_DIR)
        _log(f"created authored dir {AUTHORED_DIR}")


def _create_animation_blueprint() -> unreal.AnimBlueprint | None:
    """Create ABP_Mattias bound to the staged skeleton.

    Python cannot author Anim Graph state machines, so this only creates the
    asset shell with the correct target skeleton. The state-machine wiring is
    listed as a MANUAL follow-up step in the run summary.
    """
    if unreal.EditorAssetLibrary.does_asset_exist(ABP_PATH):
        _log(f"exists {ABP_PATH}")
        return unreal.EditorAssetLibrary.load_asset(ABP_PATH)  # type: ignore[return-value]

    skeleton = unreal.EditorAssetLibrary.load_asset(GAME_SKELETON_PATH)
    if skeleton is None:
        _err(f"Cannot create AnimBP — skeleton missing at {GAME_SKELETON_PATH}")
        return None

    factory = unreal.AnimBlueprintFactory()
    factory.set_editor_property("target_skeleton", skeleton)
    factory.set_editor_property("parent_class", unreal.AnimInstance)

    tools = unreal.AssetToolsHelpers.get_asset_tools()
    abp = tools.create_asset(
        "ABP_Mattias", AUTHORED_DIR, unreal.AnimBlueprint, factory
    )
    if abp is None:
        _err(f"create_asset returned None for {ABP_PATH}")
        return None

    unreal.EditorAssetLibrary.save_asset(ABP_PATH)
    _log(f"created {ABP_PATH}")
    return abp  # type: ignore[return-value]


# ---------------------------------------------------------------------------
# Stage 3 — Character Blueprint
# ---------------------------------------------------------------------------

def _compile_blueprint(bp: unreal.Blueprint) -> None:
    lib = getattr(unreal, "BlueprintEditorLibrary", None)
    if lib is None:
        return
    for fn_name in ("compile_blueprint", "recompile_blueprint"):
        fn = getattr(lib, fn_name, None)
        if fn is None:
            continue
        try:
            fn(bp)
            return
        except Exception as exc:
            _warn(f"  {fn_name} failed: {exc}")
            return


def _create_character_blueprint() -> unreal.Blueprint | None:
    """Create BP_Mattias deriving from Character with sensible defaults."""
    if unreal.EditorAssetLibrary.does_asset_exist(BP_PATH):
        _log(f"exists {BP_PATH}")
        bp = unreal.EditorAssetLibrary.load_asset(BP_PATH)  # type: ignore[assignment]
        _configure_character_cdo(bp)  # type: ignore[arg-type]
        _compile_blueprint(bp)  # type: ignore[arg-type]
        unreal.EditorAssetLibrary.save_asset(BP_PATH)
        return bp  # type: ignore[return-value]

    factory = unreal.BlueprintFactory()
    factory.set_editor_property("parent_class", unreal.Character)

    tools = unreal.AssetToolsHelpers.get_asset_tools()
    bp = tools.create_asset("BP_Mattias", AUTHORED_DIR, unreal.Blueprint, factory)
    if bp is None:
        _err(f"create_asset returned None for {BP_PATH}")
        return None

    _configure_character_cdo(bp)  # type: ignore[arg-type]
    _attach_camera_components(bp)  # type: ignore[arg-type]
    _compile_blueprint(bp)  # type: ignore[arg-type]

    unreal.EditorAssetLibrary.save_asset(BP_PATH)
    _log(f"created {BP_PATH}")
    return bp  # type: ignore[return-value]


def _configure_character_cdo(bp: unreal.Blueprint) -> None:
    """Apply CharacterMovement, Mesh, and ABP defaults to the CDO."""
    bp_class = _load_bp_class(BP_PATH)
    if bp_class is None:
        _warn("Could not resolve BP_Mattias generated class for CDO access")
        return

    try:
        cdo = unreal.get_default_object(bp_class)
    except Exception as exc:
        _warn(f"Could not access generated CDO: {exc}")
        return

    mesh = getattr(cdo, "mesh", None)
    if mesh is not None:
        sk_mesh = unreal.EditorAssetLibrary.load_asset(GAME_MESH_PATH)
        if sk_mesh is not None:
            if not _set_skinned_asset(mesh, sk_mesh):
                _warn("  could not assign skeletal mesh to character mesh component")
        abp_class = _load_bp_class(ABP_PATH)
        if abp_class is not None:
            assigned = False
            set_anim_fn = getattr(mesh, "set_anim_instance_class", None)
            if callable(set_anim_fn):
                try:
                    set_anim_fn(abp_class)
                    assigned = True
                except Exception:
                    pass
            if not assigned:
                for prop in (
                    "anim_class",
                    "anim_blueprint_generated_class",
                    "animation_mode",
                ):
                    try:
                        mesh.set_editor_property(prop, abp_class)
                        assigned = True
                        break
                    except Exception:
                        pass
            if not assigned:
                _warn("  could not set AnimClass on mesh component — set manually in BP_Mattias")
        try:
            mesh.set_relative_location(unreal.Vector(0.0, 0.0, -90.0))
            mesh.set_relative_rotation(unreal.Rotator(roll=-90.0, pitch=0.0, yaw=0.0))
        except Exception:
            pass

    movement = getattr(cdo, "character_movement", None)
    if movement is None:
        movement = cdo.get_editor_property("character_movement")
    if movement is not None:
        for prop_name, value in (
            ("max_walk_speed", RUN_SPEED),
            ("max_walk_speed_crouched", CROUCH_SPEED),
            ("jump_z_velocity", JUMP_Z_VELOCITY),
            ("air_control", 0.35),
            ("can_ever_crouch", True),
            ("braking_deceleration_walking", 1024.0),
        ):
            try:
                movement.set_editor_property(prop_name, value)
            except Exception as exc:
                _warn(f"  CharacterMovement.{prop_name} = {value!r} failed: {exc}")

    capsule = getattr(cdo, "capsule_component", None)
    if capsule is not None:
        try:
            capsule.set_capsule_size(34.0, 90.0)
        except Exception:
            pass


def _attach_camera_components(bp: unreal.Blueprint) -> None:
    """Attach SpringArm + Camera to BP_Mattias via SubobjectDataSubsystem.

    The SubobjectDataSubsystem is the UE 5.x supported path for editing a
    Blueprint's component tree from Python. Falls back to a logged MANUAL
    step on engine builds where the subsystem isn't accessible.
    """
    sub = unreal.get_engine_subsystem(unreal.SubobjectDataSubsystem)
    if sub is None:
        _warn(
            "  MANUAL: SubobjectDataSubsystem unavailable. Open BP_Mattias and "
            "add a SpringArm + Camera by hand (target arm length 300, "
            "socket offset Z = 60, use_pawn_control_rotation = True)."
        )
        return

    try:
        handles = sub.k2_gather_subobject_data_for_blueprint(bp)
    except Exception as exc:
        _warn(f"  could not gather subobjects: {exc}")
        return

    root_handle = handles[0] if handles else None
    if root_handle is None:
        _warn("  no root subobject found on BP_Mattias")
        return

    def _add_component(
        component_class: type,
        parent_handle: unreal.SubobjectDataHandle,
        new_name: str,
    ) -> unreal.SubobjectDataHandle | None:
        params = unreal.AddNewSubobjectParams()
        params.parent_handle = parent_handle
        params.new_class = component_class
        params.blueprint_context = bp
        try:
            handle, fail_reason = sub.add_new_subobject(params)
        except Exception as exc:
            _warn(f"  add_new_subobject {new_name} crashed: {exc}")
            return None
        if not handle.is_valid():
            _warn(f"  add_new_subobject {new_name} failed: {fail_reason}")
            return None
        try:
            sub.rename_subobject(handle, unreal.Text(new_name))
        except Exception:
            pass
        return handle

    spring_arm_handle = _add_component(
        unreal.SpringArmComponent, root_handle, "SpringArm"
    )
    if spring_arm_handle is None:
        return

    spring_arm_obj = sub.k2_find_subobject_data_from_handle(
        spring_arm_handle
    ).get_object()
    spring_arm = unreal.SpringArmComponent.cast(spring_arm_obj) if spring_arm_obj else None
    if spring_arm is not None:
        for prop, val in (
            ("target_arm_length", SPRING_ARM_LENGTH),
            ("socket_offset", unreal.Vector(0.0, 0.0, SPRING_ARM_SOCKET_OFFSET_Z)),
            ("use_pawn_control_rotation", True),
            ("b_enable_camera_lag", True),
            ("camera_lag_speed", 12.0),
        ):
            try:
                spring_arm.set_editor_property(prop, val)
            except Exception as exc:
                _warn(f"  SpringArm.{prop} failed: {exc}")

    cam_handle = _add_component(
        unreal.CameraComponent, spring_arm_handle, "FollowCamera"
    )
    if cam_handle is None:
        return
    cam_obj = sub.k2_find_subobject_data_from_handle(cam_handle).get_object()
    camera = unreal.CameraComponent.cast(cam_obj) if cam_obj else None
    if camera is not None:
        try:
            camera.set_editor_property("use_pawn_control_rotation", False)
            camera.set_editor_property("field_of_view", 85.0)
        except Exception:
            pass


# ---------------------------------------------------------------------------
# Manual-follow-up summary
# ---------------------------------------------------------------------------

ABP_MANUAL_STEPS = """
ABP_Mattias — manual wiring required (Anim Graph state machines):

  Variables to expose on the AnimBP:
    Speed              float
    Direction          float       (-180..+180, atan2 of velocity vs forward)
    bIsCrouching       bool
    bIsFalling         bool
    WeaponStance       EWeaponStance
    bIsDead            bool
    DeathDirection     int / enum  (0=front, 1=back, 2=right, 3=headshot)

  Top-level Anim Graph composition (outer → inner):
    1. Death oneshot:  if bIsDead -> "Death" cached pose selected by
       DeathDirection from death_from_the_front / death_from_the_back /
       death_from_right / death_from_back_headshot / death_crouching_headshot_front
    2. Else: Jump/Fall layer
       - if bIsFalling rising  -> jump_up
       - if bIsFalling falling -> falling_idle / jump_loop
       - on landing            -> jump_down (or hard_landing if vertical
         velocity > 800)
    3. Else: WeaponStance switch (Unarmed / Rifle / Pistol / Heavy):
       - Unarmed   -> Locomotion SM using top-level locomotion takes
                      (idle, walking, running, run_forward_left/right, etc.)
       - Rifle     -> Locomotion SM using Animations/Rifle_Animations/*
                      (walk_forward, walk_left, run_forward, sprint_forward, ...)
       - Pistol    -> Locomotion SM using Animations/Pistol_animations/*
                      (pistol_walk, pistol_run, pistol_strafe, ...)
       - Heavy     -> reuse Rifle for now
    4. Locomotion SM (per weapon stance): driven by Speed (idle/walk/run/sprint
       thresholds at 0/175/600/900) and Direction (-180..+180 fan blend to
       _forward_left/_left/_backward_left/_backward/_backward_right/_right/
       _forward_right takes).
    5. Stance overlay: if bIsCrouching, blend in Animations/idle_crouching or
       Animations/walk_crouching_* takes (use the existing Crouching_BS
       BlendSpace at /Game/Characters/MattiasNilsson/BlendSpaces/Crouching_BS).

  Notes:
    - The MattiasNilsson_BS and Maattias_Rifle_BS BlendSpaces in
      /Game/Characters/MattiasNilsson/BlendSpaces/ are already authored and
      can be plugged straight into the Locomotion SMs for Unarmed and Rifle.
    - Variables that source from BP_Mattias should be set in the Event Graph
      "Update Animation" event, reading the Owning Pawn each tick.
"""


BP_MANUAL_STEPS = """
BP_Mattias — manual variables / wiring required:

  Add these BP variables (Defaults tab):
    Health                float    = 100.0
    MaxHealth             float    = 100.0
    bIsSprinting          bool     = false
    WeaponStance          EWeaponStance = Unarmed
    FactionReputation     Map<EFaction, float>
        defaults: { PMC: 0, VZ: 0, AN: 0, UP: 0, Pirates: 0 }

  Override CharacterMovement.MaxWalkSpeed at runtime:
    - On IA_Sprint Pressed   -> set MaxWalkSpeed = 900
    - On IA_Sprint Released  -> set MaxWalkSpeed = 600 (default run)
    - On Crouch begin        -> Character.Crouch() (uses crouched 150 speed)
    - On Crouch end          -> Character.UnCrouch()

  Input bindings (added in setup_player_controller.py):
    - IA_Move    -> AddMovementInput (forward / right vectors from camera yaw)
    - IA_Look    -> AddControllerYawInput / AddControllerPitchInput
    - IA_Jump    -> Jump / StopJumping
    - IA_Sprint  -> toggle bIsSprinting + MaxWalkSpeed
    - IA_Crouch  -> toggle Crouch (TOGGLE behavior — see plan doc)

  The mesh, camera, spring arm, and CharacterMovement defaults were configured
  by this script; verify visually (open BP_Mattias) and tweak the mesh -90Z
  offset if the capsule alignment is off.
"""


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def run() -> None:
    _log("=" * 70)
    _log("Mercenaries 2 — Player Character setup (Mattias Nilsson)")
    _log("=" * 70)

    _log("--- Stage 1: copy MattiasNilssonExport bundle into Content ---")
    _copy_bundle_into_content()
    _rescan_asset_registry()
    if not _verify_bundle_loaded():
        _err(
            "Aborting — required Mattias rig assets did not resolve after "
            "staging. Check that MattiasNilssonExport/ contains "
            "mattias-main-export*.uasset under Textures/."
        )
        return

    _log("--- Stage 2: create authored assets ---")
    _ensure_authored_dir()
    abp = _create_animation_blueprint()
    bp = _create_character_blueprint()

    if abp is None or bp is None:
        _err("One or more authored assets failed to create — see log above.")
        return

    _log("--- Manual follow-up ---")
    for line in ABP_MANUAL_STEPS.strip().splitlines():
        _warn(line)
    for line in BP_MANUAL_STEPS.strip().splitlines():
        _warn(line)

    _log("=" * 70)
    _log("Done. Run setup_player_controller.py next.")
    _log("=" * 70)


if __name__ == "__main__":
    run()
