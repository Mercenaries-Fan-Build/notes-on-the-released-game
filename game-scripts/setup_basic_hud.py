"""Mercenaries 2 Recreation — Basic HUD scaffolding.

UE 5.7 Editor Python script that creates the UMG widget assets that make up
the M2-style HUD:

  - ``/Game/UI/HUD/WBP_HUDRoot``   — full-screen overlay with health, ammo,
                                     minimap, faction bars, mission tracker
                                     and aim crosshair.
  - ``/Game/UI/HUD/WBP_PauseMenu`` — Resume / Save / Load / Settings / Quit.

Python in 5.7 can build the widget *tree* (root canvas + child widgets like
Border, TextBlock, ProgressBar, Image) but cannot author Blueprint event
graphs / function bodies. Bindings (e.g. health bar ← Health/MaxHealth) are
left as MANUAL follow-ups, documented in the run summary.

Idempotent: re-running detects existing assets and skips creation. To force
a rebuild, delete the WBPs and re-run.

Run via:
    Tools → Execute Python Script → setup_basic_hud.py
"""

from __future__ import annotations

from typing import TYPE_CHECKING

import unreal

if TYPE_CHECKING:
    from typing import Any

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

LOG_PREFIX = "[Mercs2HUD]"

UI_ROOT = "/Game/UI"
HUD_DIR = f"{UI_ROOT}/HUD"
HUD_PATH = f"{HUD_DIR}/WBP_HUDRoot"
PAUSE_PATH = f"{HUD_DIR}/WBP_PauseMenu"

# M2 visual cues — kept readable rather than ornate.
COLOR_PMC_ORANGE = unreal.LinearColor(1.0, 0.478, 0.0, 1.0)         # #FF7A00
COLOR_PANEL_BG = unreal.LinearColor(0.094, 0.094, 0.094, 0.85)      # #181818 dark
COLOR_TEXT_LIGHT = unreal.LinearColor(0.95, 0.95, 0.95, 1.0)
COLOR_FACTION = {
    "PMC": unreal.LinearColor(1.0, 0.478, 0.0, 1.0),     # orange
    "VZ": unreal.LinearColor(0.85, 0.15, 0.15, 1.0),     # red
    "AN": unreal.LinearColor(0.20, 0.45, 0.85, 1.0),     # blue
    "UP": unreal.LinearColor(0.20, 0.70, 0.30, 1.0),     # green
    "Pirates": unreal.LinearColor(0.05, 0.05, 0.05, 1.0),
}


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
# WidgetBlueprint helpers
# ---------------------------------------------------------------------------

def _create_widget_blueprint(name: str, package_dir: str) -> unreal.WidgetBlueprint | None:
    path = f"{package_dir}/{name}"
    existing = unreal.EditorAssetLibrary.load_asset(path)
    if existing is not None:
        _log(f"  exists  {path}")
        return existing  # type: ignore[return-value]

    factory_cls = getattr(unreal, "WidgetBlueprintFactory", None)
    if factory_cls is None:
        _err("  WidgetBlueprintFactory not available — cannot create UMG widgets")
        return None

    factory = factory_cls()
    try:
        factory.set_editor_property("parent_class", unreal.UserWidget)
    except Exception:
        pass

    tools = unreal.AssetToolsHelpers.get_asset_tools()
    wbp = tools.create_asset(name, package_dir, unreal.WidgetBlueprint, factory)
    if wbp is None:
        _err(f"  create_asset returned None for {path}")
        return None
    _log(f"  created {path}")
    return wbp  # type: ignore[return-value]


def _widget_tree(wbp: unreal.WidgetBlueprint) -> unreal.WidgetTree | None:
    """Return the blueprint widget tree, or None if the UE Python API cannot access it."""
    for prop in ("widget_tree", "WidgetTree"):
        try:
            tree = wbp.get_editor_property(prop)
            if tree is not None:
                return tree  # type: ignore[return-value]
        except Exception:
            pass
        try:
            tree = getattr(wbp, prop)
            if tree is not None:
                return tree  # type: ignore[return-value]
        except Exception:
            pass
    return None


def _can_build_widget_tree(wbp: unreal.WidgetBlueprint) -> bool:
    return _widget_tree(wbp) is not None


def _needs_widget_build(wbp: unreal.WidgetBlueprint) -> bool:
    tree = _widget_tree(wbp)
    if tree is None:
        return False
    try:
        return tree.root_widget is None
    except Exception:
        return False


def _construct(wbp: unreal.WidgetBlueprint, widget_class: type, name: str) -> unreal.Widget | None:
    tree = _widget_tree(wbp)
    if tree is None:
        _warn(f"  widget_tree missing on {wbp.get_name()} — cannot construct {name}")
        return None
    try:
        return tree.construct_widget(widget_class, unreal.Name(name))
    except Exception as exc:
        _warn(f"  construct_widget({widget_class.__name__}, {name}) failed: {exc}")
        return None


def _set_root(wbp: unreal.WidgetBlueprint, root: unreal.Widget) -> None:
    tree = _widget_tree(wbp)
    if tree is None:
        _warn("  widget_tree missing — cannot set root_widget")
        return
    try:
        tree.set_editor_property("root_widget", root)
    except Exception as exc:
        _warn(f"  set root_widget failed: {exc}")


def _add_to_canvas(
    canvas: unreal.CanvasPanel,
    child: unreal.Widget,
    *,
    anchor_min: tuple[float, float],
    anchor_max: tuple[float, float],
    offset: tuple[float, float, float, float],
    alignment: tuple[float, float] = (0.0, 0.0),
) -> None:
    slot = canvas.add_child_to_canvas(child)
    if slot is None:
        _warn(f"  add_child_to_canvas returned None for {child.get_name()}")
        return
    try:
        slot.set_anchors(unreal.Anchors(
            minimum=unreal.Vector2D(anchor_min[0], anchor_min[1]),
            maximum=unreal.Vector2D(anchor_max[0], anchor_max[1]),
        ))
        slot.set_offsets(unreal.Margin(
            left=offset[0], top=offset[1], right=offset[2], bottom=offset[3],
        ))
        slot.set_alignment(unreal.Vector2D(alignment[0], alignment[1]))
    except Exception as exc:
        _warn(f"  canvas slot configuration failed: {exc}")


def _make_panel(name: str, wbp: unreal.WidgetBlueprint, bg: unreal.LinearColor) -> unreal.Border | None:
    border = _construct(wbp, unreal.Border, name)
    if border is None:
        return None
    try:
        border.set_brush_color(bg)
    except Exception:
        pass
    return border  # type: ignore[return-value]


def _make_text(name: str, wbp: unreal.WidgetBlueprint, text: str) -> unreal.TextBlock | None:
    tb = _construct(wbp, unreal.TextBlock, name)
    if tb is None:
        return None
    try:
        tb.set_text(unreal.Text(text))
        tb.set_color_and_opacity(unreal.SlateColor(COLOR_TEXT_LIGHT))
    except Exception:
        pass
    return tb  # type: ignore[return-value]


def _make_progress_bar(
    name: str,
    wbp: unreal.WidgetBlueprint,
    fill: unreal.LinearColor,
    percent: float = 1.0,
) -> unreal.ProgressBar | None:
    pb = _construct(wbp, unreal.ProgressBar, name)
    if pb is None:
        return None
    try:
        pb.set_percent(percent)
        pb.set_fill_color_and_opacity(fill)
    except Exception:
        pass
    return pb  # type: ignore[return-value]


# ---------------------------------------------------------------------------
# WBP_HUDRoot — assemble the in-game HUD
# ---------------------------------------------------------------------------

def _build_hud_root(wbp: unreal.WidgetBlueprint) -> None:
    canvas = _construct(wbp, unreal.CanvasPanel, "Root")
    if canvas is None:
        return
    _set_root(wbp, canvas)
    canvas = canvas  # type: ignore[assignment]

    # --- Bottom-left: vertical health bar ---
    health_panel = _make_panel("HealthPanel", wbp, COLOR_PANEL_BG)
    if health_panel is not None:
        _add_to_canvas(
            canvas,
            health_panel,
            anchor_min=(0.0, 1.0),
            anchor_max=(0.0, 1.0),
            offset=(24.0, -260.0, 40.0, -40.0),
        )
        health_bar = _make_progress_bar("HealthBar", wbp, COLOR_PMC_ORANGE, percent=1.0)
        if health_bar is not None:
            try:
                health_bar.set_editor_property(
                    "bar_fill_type",
                    getattr(unreal, "ProgressBarFillType").TOP_TO_BOTTOM,
                )
            except Exception:
                pass
            try:
                health_panel.set_content(health_bar)
            except Exception as exc:
                _warn(f"  could not set health bar content: {exc}")

    # --- Bottom-right: ammo + weapon name + weapon icon ---
    ammo_panel = _make_panel("AmmoPanel", wbp, COLOR_PANEL_BG)
    if ammo_panel is not None:
        _add_to_canvas(
            canvas,
            ammo_panel,
            anchor_min=(1.0, 1.0),
            anchor_max=(1.0, 1.0),
            offset=(-280.0, -110.0, -24.0, -24.0),
        )
        v_box = _construct(wbp, unreal.VerticalBox, "AmmoVBox")
        if v_box is not None:
            try:
                ammo_panel.set_content(v_box)  # type: ignore[arg-type]
            except Exception:
                pass

            weapon_name = _make_text("WeaponNameText", wbp, "Sidearm")
            ammo_text = _make_text("AmmoText", wbp, "12 / 60")
            for child in (weapon_name, ammo_text):
                if child is None:
                    continue
                try:
                    v_box.add_child(child)  # type: ignore[arg-type]
                except Exception:
                    pass

    # --- Top-left: minimap stub ---
    minimap = _make_panel("MinimapPanel", wbp, COLOR_PANEL_BG)
    if minimap is not None:
        _add_to_canvas(
            canvas,
            minimap,
            anchor_min=(0.0, 0.0),
            anchor_max=(0.0, 0.0),
            offset=(24.0, 24.0, 224.0, 224.0),
        )
        placeholder = _make_text("MinimapPlaceholder", wbp, "MAP")
        if placeholder is not None:
            try:
                minimap.set_content(placeholder)  # type: ignore[arg-type]
            except Exception:
                pass

    # --- Top-right: faction reputation bars ---
    faction_panel = _make_panel("FactionPanel", wbp, COLOR_PANEL_BG)
    if faction_panel is not None:
        _add_to_canvas(
            canvas,
            faction_panel,
            anchor_min=(1.0, 0.0),
            anchor_max=(1.0, 0.0),
            offset=(-220.0, 24.0, -24.0, 152.0),
        )
        f_vbox = _construct(wbp, unreal.VerticalBox, "FactionVBox")
        if f_vbox is not None:
            try:
                faction_panel.set_content(f_vbox)  # type: ignore[arg-type]
            except Exception:
                pass
            for faction, color in COLOR_FACTION.items():
                row = _construct(wbp, unreal.HorizontalBox, f"FactionRow_{faction}")
                label = _make_text(f"FactionLabel_{faction}", wbp, faction)
                bar = _make_progress_bar(f"FactionBar_{faction}", wbp, color, percent=0.5)
                if row is None:
                    continue
                for child in (label, bar):
                    if child is None:
                        continue
                    try:
                        row.add_child(child)  # type: ignore[arg-type]
                    except Exception:
                        pass
                try:
                    f_vbox.add_child(row)  # type: ignore[arg-type]
                except Exception:
                    pass

    # --- Bottom-center: mission objective tracker ---
    obj_panel = _make_panel("ObjectivePanel", wbp, COLOR_PANEL_BG)
    if obj_panel is not None:
        _add_to_canvas(
            canvas,
            obj_panel,
            anchor_min=(0.5, 1.0),
            anchor_max=(0.5, 1.0),
            offset=(-240.0, -130.0, 240.0, -24.0),
            alignment=(0.0, 0.0),
        )
        obj_text = _make_text(
            "ObjectiveText", wbp, "Objective: (none — stub feed from DT_TutorialMission)"
        )
        if obj_text is not None:
            try:
                obj_panel.set_content(obj_text)  # type: ignore[arg-type]
            except Exception:
                pass

    # --- Center: aim crosshair (visibility-bound to bIsAiming) ---
    crosshair = _construct(wbp, unreal.Image, "Crosshair")
    if crosshair is not None:
        _add_to_canvas(
            canvas,
            crosshair,
            anchor_min=(0.5, 0.5),
            anchor_max=(0.5, 0.5),
            offset=(-12.0, -12.0, 12.0, 12.0),
            alignment=(0.0, 0.0),
        )
        try:
            crosshair.set_brush_tint_color(COLOR_PMC_ORANGE)
            crosshair.set_visibility(unreal.SlateVisibility.HIDDEN)
        except Exception:
            pass


def create_hud_root() -> unreal.WidgetBlueprint | None:
    _log("--- WBP_HUDRoot ---")
    wbp = _create_widget_blueprint("WBP_HUDRoot", HUD_DIR)
    if wbp is None:
        return None
    if not _can_build_widget_tree(wbp):
        _warn(
            "  widget_tree not exposed in this UE build — open WBP_HUDRoot in the "
            "UMG designer if the layout is empty."
        )
        return wbp
    if _needs_widget_build(wbp):
        _build_hud_root(wbp)
        unreal.EditorAssetLibrary.save_asset(HUD_PATH)
    return wbp


# ---------------------------------------------------------------------------
# WBP_PauseMenu
# ---------------------------------------------------------------------------

PAUSE_BUTTONS = ["Resume", "Save", "Load", "Settings", "Quit"]


def _build_pause_menu(wbp: unreal.WidgetBlueprint) -> None:
    canvas = _construct(wbp, unreal.CanvasPanel, "Root")
    if canvas is None:
        return
    _set_root(wbp, canvas)

    backdrop = _make_panel(
        "Backdrop",
        wbp,
        unreal.LinearColor(0.0, 0.0, 0.0, 0.75),
    )
    if backdrop is not None:
        _add_to_canvas(
            canvas,
            backdrop,
            anchor_min=(0.0, 0.0),
            anchor_max=(1.0, 1.0),
            offset=(0.0, 0.0, 0.0, 0.0),
        )

    centerpiece = _make_panel("Panel", wbp, COLOR_PANEL_BG)
    if centerpiece is None:
        return
    _add_to_canvas(
        canvas,
        centerpiece,
        anchor_min=(0.5, 0.5),
        anchor_max=(0.5, 0.5),
        offset=(-180.0, -200.0, 180.0, 200.0),
    )

    v_box = _construct(wbp, unreal.VerticalBox, "ButtonsVBox")
    if v_box is None:
        return
    try:
        centerpiece.set_content(v_box)  # type: ignore[arg-type]
    except Exception:
        pass

    title = _make_text("Title", wbp, "PAUSED")
    if title is not None:
        try:
            v_box.add_child(title)  # type: ignore[arg-type]
        except Exception:
            pass

    for label in PAUSE_BUTTONS:
        button = _construct(wbp, unreal.Button, f"Btn_{label}")
        if button is None:
            continue
        text = _make_text(f"BtnLbl_{label}", wbp, label)
        if text is not None:
            try:
                button.add_child(text)  # type: ignore[arg-type]
            except Exception:
                pass
        try:
            v_box.add_child(button)  # type: ignore[arg-type]
        except Exception:
            pass


def create_pause_menu() -> unreal.WidgetBlueprint | None:
    _log("--- WBP_PauseMenu ---")
    wbp = _create_widget_blueprint("WBP_PauseMenu", HUD_DIR)
    if wbp is None:
        return None
    if not _can_build_widget_tree(wbp):
        _warn(
            "  widget_tree not exposed — create WBP_PauseMenu layout manually in UMG "
            "(Resume/Save/Load/Settings/Quit buttons)."
        )
        unreal.EditorAssetLibrary.save_asset(PAUSE_PATH)
        return wbp
    if _needs_widget_build(wbp):
        _build_pause_menu(wbp)
        unreal.EditorAssetLibrary.save_asset(PAUSE_PATH)
    if not unreal.EditorAssetLibrary.does_asset_exist(PAUSE_PATH):
        _err(f"  WBP_PauseMenu was not saved to {PAUSE_PATH}")
        return None
    return wbp


# ---------------------------------------------------------------------------
# Manual follow-up
# ---------------------------------------------------------------------------

HUD_MANUAL_STEPS = """
WBP_HUDRoot — manual bindings required:

  Bindings (Designer tab > select widget > Binding):
    HealthBar.Percent       -> Health / MaxHealth   (from BP_Mattias)
    AmmoText.Text           -> format("{0} / {1}", CurrentMag, ReserveAmmo)
    WeaponNameText.Text     -> CurrentWeapon.Name
    ObjectiveText.Text      -> CurrentObjective.Title + Description
    Crosshair.Visibility    -> bIsAiming ? Visible : Hidden
    FactionBar_<Faction>.Percent -> (FactionReputation[<Faction>] + 100) / 200

  Spawning:
    BP_PlayerController.BeginPlay should Create Widget(WBP_HUDRoot, self)
    and AddToViewport.

WBP_PauseMenu — manual wiring:

  Each button OnClicked:
    Resume   -> SetPaused(false), RemoveFromParent, set Input Mode = GameOnly
    Save     -> log("save stub")
    Load     -> log("load stub")
    Settings -> log("settings stub")
    Quit     -> QuitGame

  Show/hide from BP_PlayerController:
    ESC pressed -> if not paused: Create Widget(WBP_PauseMenu), AddToViewport,
                   SetPaused(true), Input Mode = UIOnly + show mouse.
"""


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def run() -> bool:
    _log("=" * 70)
    _log("Mercenaries 2 — Basic HUD scaffolding")
    _log("=" * 70)

    _ensure_directory(UI_ROOT)
    _ensure_directory(HUD_DIR)

    ok = True
    if create_hud_root() is None:
        _err("WBP_HUDRoot creation failed")
        ok = False
    if create_pause_menu() is None:
        _err("WBP_PauseMenu creation failed")
        ok = False

    _log("--- Manual follow-up ---")
    for line in HUD_MANUAL_STEPS.strip().splitlines():
        _warn(line)

    _log("=" * 70)
    _log("Done." if ok else "Finished with errors — see log above.")
    _log("=" * 70)
    return ok


if __name__ == "__main__":
    run()
