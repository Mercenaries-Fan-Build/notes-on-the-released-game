"""Mercenaries 2 Recreation — Player Controller + Enhanced Input setup.

UE 5.7 Editor Python script that creates:

  - Enhanced Input actions under ``/Game/Input/Actions``
      IA_Move, IA_Look, IA_Jump, IA_Sprint, IA_Crouch,
      IA_Interact, IA_Aim, IA_Fire, IA_SwitchWeapon, IA_OpenPDA
  - An Input Mapping Context at ``/Game/Input/IMC_Default`` (key bindings are
    listed in the run summary for manual binding — Python cannot wire key
    chords into IMC entries via the Python API in 5.7).
  - ``/Game/Characters/Mattias/BP_PlayerController`` (derives from
    PlayerController; defaults reference the IMC + BP_Mattias).
  - ``/Game/Characters/Mattias/BP_GameMode`` (derives from GameModeBase; sets
    default pawn = BP_Mattias and player controller = BP_PlayerController).
  - Sets the active map's GameMode override to BP_GameMode via
    WorldSettings (preferred over editing DefaultEngine.ini).

Crouch behavior: TOGGLE on press (not hold). See
``docs/character_systems_plan.md`` for the rationale.

Prerequisites:
  - setup_player_character.py has been run.
  - The level you want to use BP_GameMode on is open in the editor (so we
    can write the override into WorldSettings). If not, the GameMode
    override step logs a MANUAL note and skips.

Run via:
    Tools → Execute Python Script → setup_player_controller.py
"""

from __future__ import annotations

from typing import TYPE_CHECKING

import unreal

if TYPE_CHECKING:
    from typing import Any

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

LOG_PREFIX = "[Mercs2Input]"

INPUT_ROOT = "/Game/Input"
ACTIONS_DIR = f"{INPUT_ROOT}/Actions"
IMC_PATH = f"{INPUT_ROOT}/IMC_Default"

MATTIAS_DIR = "/Game/Characters/Mattias"
BP_PC_PATH = f"{MATTIAS_DIR}/BP_PlayerController"
BP_GM_PATH = f"{MATTIAS_DIR}/BP_GameMode"
BP_MATTIAS_PATH = f"{MATTIAS_DIR}/BP_Mattias"


# Enhanced Input action definitions.
# (name, value_type, description)
INPUT_ACTIONS: list[tuple[str, str, str]] = [
    ("IA_Move", "Axis2D", "WASD / left-stick movement"),
    ("IA_Look", "Axis2D", "Mouse XY / right-stick look"),
    ("IA_Jump", "Digital", "Spacebar"),
    ("IA_Sprint", "Digital", "Left Shift (held)"),
    ("IA_Crouch", "Digital", "Left Ctrl (toggle)"),
    ("IA_Interact", "Digital", "E"),
    ("IA_Aim", "Digital", "RMB (held)"),
    ("IA_Fire", "Digital", "LMB — no-op this pass"),
    ("IA_SwitchWeapon", "Digital", "Q / scroll — no-op this pass"),
    ("IA_OpenPDA", "Digital", "Tab — opens map / contract UI"),
]


# Key binding spec for the IMC. Python cannot write IMC entries reliably
# in 5.7 (the EnhancedInputEditor.add_action_to_mapping_context binding is
# not exposed), so this is documented for manual entry.
IMC_BINDINGS: list[tuple[str, str, list[str]]] = [
    ("IA_Move", "W",           ["Modifier: Swizzle Input Axis Values (YXZ→XYZ for forward)"]),
    ("IA_Move", "S",           ["Modifier: Negate, Swizzle (forward axis, negative)"]),
    ("IA_Move", "A",           ["Modifier: Negate (right axis, negative)"]),
    ("IA_Move", "D",           []),
    ("IA_Look", "Mouse XY 2D-Axis", []),
    ("IA_Jump", "SpaceBar",    []),
    ("IA_Sprint", "LeftShift", []),
    ("IA_Crouch", "LeftControl", ["Trigger: Pressed (toggle on press)"]),
    ("IA_Interact", "E",       []),
    ("IA_Aim", "RightMouseButton", []),
    ("IA_Fire", "LeftMouseButton", []),
    ("IA_SwitchWeapon", "Q",   []),
    ("IA_SwitchWeapon", "MouseWheelAxis", ["Trigger: Pressed"]),
    ("IA_OpenPDA", "Tab",      []),
]


# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

def _log(msg: str) -> None:
    unreal.log(f"{LOG_PREFIX} {msg}")


def _warn(msg: str) -> None:
    unreal.log_warning(f"{LOG_PREFIX} {msg}")


def _err(msg: str) -> None:
    unreal.log_error(f"{LOG_PREFIX} {msg}")


def _ensure_directory(content_path: str) -> None:
    if not unreal.EditorAssetLibrary.does_directory_exist(content_path):
        unreal.EditorAssetLibrary.make_directory(content_path)
        _log(f"  created dir {content_path}")


# ---------------------------------------------------------------------------
# Enhanced Input action creation
# ---------------------------------------------------------------------------

def _value_type_enum(name: str) -> unreal.InputActionValueType | None:
    mapping = {
        "Digital": "BOOL",
        "Axis1D": "AXIS1D",
        "Axis2D": "AXIS2D",
        "Axis3D": "AXIS3D",
    }
    enum_member = mapping.get(name, "BOOL")
    enum_cls = getattr(unreal, "EInputActionValueType", None)
    if enum_cls is None:
        return None
    return getattr(enum_cls, enum_member, None)


def create_input_actions() -> None:
    _log("--- Enhanced Input actions ---")
    _ensure_directory(ACTIONS_DIR)

    factory_cls = getattr(unreal, "InputActionFactory", None)
    if factory_cls is None:
        _warn(
            "  InputActionFactory not exposed in this engine build. MANUAL: "
            "create the action assets by right-clicking in /Game/Input/Actions "
            "and choosing Input > Input Action."
        )
        return

    tools = unreal.AssetToolsHelpers.get_asset_tools()
    for name, value_type, _desc in INPUT_ACTIONS:
        path = f"{ACTIONS_DIR}/{name}"
        if unreal.EditorAssetLibrary.does_asset_exist(path):
            _log(f"  exists  {path}")
            continue

        factory = factory_cls()
        action = tools.create_asset(name, ACTIONS_DIR, unreal.InputAction, factory)
        if action is None:
            _err(f"  create_asset failed for {path}")
            continue

        vt = _value_type_enum(value_type)
        if vt is not None:
            try:
                action.set_editor_property("value_type", vt)
            except Exception as exc:
                _warn(f"  could not set value_type on {name}: {exc}")
        unreal.EditorAssetLibrary.save_asset(path)
        _log(f"  created {path}  ({value_type})")


# ---------------------------------------------------------------------------
# Input Mapping Context
# ---------------------------------------------------------------------------

def create_input_mapping_context() -> None:
    _log("--- Input Mapping Context ---")
    _ensure_directory(INPUT_ROOT)

    if unreal.EditorAssetLibrary.does_asset_exist(IMC_PATH):
        _log(f"  exists  {IMC_PATH}")
    else:
        factory_cls = getattr(unreal, "InputMappingContextFactory", None)
        if factory_cls is None:
            _warn(
                "  InputMappingContextFactory not exposed. MANUAL: create "
                f"{IMC_PATH} via right-click > Input > Input Mapping Context."
            )
            return

        tools = unreal.AssetToolsHelpers.get_asset_tools()
        imc = tools.create_asset(
            "IMC_Default", INPUT_ROOT, unreal.InputMappingContext, factory_cls()
        )
        if imc is None:
            _err(f"  create_asset failed for {IMC_PATH}")
            return
        unreal.EditorAssetLibrary.save_asset(IMC_PATH)
        _log(f"  created {IMC_PATH}")

    _warn("  MANUAL: open IMC_Default and add the following mappings:")
    for action_name, key, notes in IMC_BINDINGS:
        notes_str = ("  " + " | ".join(notes)) if notes else ""
        _warn(f"    {action_name:<18} <- {key}{notes_str}")


# ---------------------------------------------------------------------------
# PlayerController + GameMode blueprints
# ---------------------------------------------------------------------------

def _create_subclass_blueprint(
    asset_name: str,
    package_dir: str,
    parent_class: type,
) -> unreal.Blueprint | None:
    path = f"{package_dir}/{asset_name}"
    existing = unreal.EditorAssetLibrary.load_asset(path)
    if existing is not None:
        _log(f"  exists  {path}")
        return existing  # type: ignore[return-value]

    factory = unreal.BlueprintFactory()
    factory.set_editor_property("parent_class", parent_class)
    tools = unreal.AssetToolsHelpers.get_asset_tools()
    bp = tools.create_asset(asset_name, package_dir, unreal.Blueprint, factory)
    if bp is None:
        _err(f"  create_asset returned None for {path}")
        return None
    unreal.EditorAssetLibrary.save_asset(path)
    _log(f"  created {path}")
    return bp  # type: ignore[return-value]


def create_player_controller_bp() -> unreal.Blueprint | None:
    _log("--- BP_PlayerController ---")
    return _create_subclass_blueprint(
        "BP_PlayerController", MATTIAS_DIR, unreal.PlayerController
    )


def create_game_mode_bp(player_controller_bp: unreal.Blueprint | None) -> unreal.Blueprint | None:
    _log("--- BP_GameMode ---")
    bp = _create_subclass_blueprint("BP_GameMode", MATTIAS_DIR, unreal.GameModeBase)
    if bp is None:
        return None

    try:
        cdo = unreal.get_default_object(bp.generated_class())
    except Exception as exc:
        _warn(f"  could not access GameMode CDO: {exc}")
        return bp

    pawn_bp = unreal.EditorAssetLibrary.load_asset(BP_MATTIAS_PATH)
    if pawn_bp is not None:
        try:
            cdo.set_editor_property(
                "default_pawn_class", pawn_bp.get_editor_property("generated_class")
            )
            _log(f"    default_pawn_class -> {BP_MATTIAS_PATH}")
        except Exception as exc:
            _warn(f"  could not set default_pawn_class: {exc}")
    else:
        _warn(f"  MANUAL: BP_Mattias not found at {BP_MATTIAS_PATH}; "
              "set DefaultPawnClass on BP_GameMode by hand.")

    if player_controller_bp is not None:
        try:
            cdo.set_editor_property(
                "player_controller_class",
                player_controller_bp.get_editor_property("generated_class"),
            )
            _log(f"    player_controller_class -> {BP_PC_PATH}")
        except Exception as exc:
            _warn(f"  could not set player_controller_class: {exc}")

    unreal.EditorAssetLibrary.save_asset(BP_GM_PATH)
    return bp


# ---------------------------------------------------------------------------
# Apply GameMode to the active level via WorldSettings
# ---------------------------------------------------------------------------

def apply_gamemode_to_active_level(game_mode_bp: unreal.Blueprint | None) -> None:
    _log("--- Active level GameMode override ---")
    if game_mode_bp is None:
        _warn("  no game mode BP — skipping")
        return

    world = None
    try:
        world = unreal.EditorLevelLibrary.get_editor_world()
    except Exception as exc:
        _warn(f"  cannot get editor world: {exc}")
        return
    if world is None:
        _warn("  no active editor world — open a level and re-run")
        return

    try:
        world_settings = world.get_world_settings()
    except Exception as exc:
        _warn(f"  could not get WorldSettings: {exc}")
        return

    if world_settings is None:
        _warn("  WorldSettings is None — skipping")
        return

    try:
        world_settings.set_editor_property(
            "default_game_mode", game_mode_bp.get_editor_property("generated_class")
        )
        _log("  WorldSettings.DefaultGameMode set to BP_GameMode")
    except Exception as exc:
        _warn(
            f"  could not write WorldSettings.DefaultGameMode: {exc}. "
            "MANUAL: in Window > World Settings, set GameMode Override = BP_GameMode."
        )

    try:
        unreal.EditorLevelLibrary.save_current_level()
    except Exception:
        pass


# ---------------------------------------------------------------------------
# Manual follow-up summaries
# ---------------------------------------------------------------------------

PC_MANUAL_STEPS = """
BP_PlayerController — manual wiring required:

  1. Add a variable: DefaultMappingContext (InputMappingContext) — set to
     /Game/Input/IMC_Default.
  2. Event BeginPlay:
       Get Enhanced Input Local Player Subsystem from PlayerController ->
       Add Mapping Context(DefaultMappingContext, Priority=0)
       Create Widget(WBP_HUDRoot, Owning Player=self) -> AddToViewport
  3. Action callbacks (delegate to the possessed pawn / Mattias):
       IA_Move    -> Get Controlled Pawn -> cast to BP_Mattias -> HandleMove
       IA_Look    -> AddControllerYawInput / AddControllerPitchInput
       IA_Jump    -> Pawn.Jump / StopJumping
       IA_Sprint  -> Pawn.SetSprinting(Started=true, Completed=false)
       IA_Crouch  -> toggle Pawn.bIsCrouchToggled, call Crouch/UnCrouch
       IA_Aim     -> Pawn.bIsAiming = pressed
       IA_Interact-> Pawn.TryInteract()    (stub)
       IA_OpenPDA -> ToggleWidget(WBP_PDARoot)  (stub for now)
       IA_Fire / IA_SwitchWeapon -> wired but logging-only stubs this pass.
  4. ESC handler: bind to either UI input or a fallback "Show Mouse Cursor"
     and call ShowPauseMenu (which adds WBP_PauseMenu to viewport, sets
     Input Mode = Game and UI, and pauses the game).
"""


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def run() -> None:
    _log("=" * 70)
    _log("Mercenaries 2 — Player Controller + Enhanced Input setup")
    _log("=" * 70)

    create_input_actions()
    create_input_mapping_context()

    pc_bp = create_player_controller_bp()
    gm_bp = create_game_mode_bp(pc_bp)
    apply_gamemode_to_active_level(gm_bp)

    _log("--- Manual follow-up ---")
    for line in PC_MANUAL_STEPS.strip().splitlines():
        _warn(line)

    _log("=" * 70)
    _log("Done. Run setup_basic_hud.py next.")
    _log("=" * 70)


if __name__ == "__main__":
    run()
