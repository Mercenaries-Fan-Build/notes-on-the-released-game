# 05 — GUI / HUD / Shell Menus

Decompiled-Lua reference for the **MrxGui** front-end: the widget toolkit (`mrxguibase`), the
per-player GUI manager, the public `Hud`/`Pda` interface facade, every in-game HUD component
(ammo, health, radar/minimap, objective tray, support menu, reticle, faction gauge, damage
indicator, vehicle disguise, hijack QTE), the PDA / satellite / garage screens, the dialog /
cinematic / load / pause / tutorial overlays, and the front-end **shell** menu (`shell.gfx`).

Scope = manifest `_manifests/05_gui_hud_shell.txt` (69 scripts across `src/resident/` and
`src/shell/`). Line numbers are from the decompiled sources in `src/<group>/<name>.lua`.

---

## 1. Overview — GUI architecture

### Layer cake

```
  Game code  ──►  Hud.* / Pda.*  (mrxguiinterface.lua — the only public API)
                       │  routes by player, net-syncs from the server
                       ▼
  MrxGuiManager  ──►  per-player layout instances (oHud/oScope/oSatellite/oPda)
                       │  duplicated from "master" layouts, owner-assigned
                       ▼
  MrxGuiBase  ──►  Widget / TextWidget / ImageWidget / FlashWidget / SpriteWidget /
                   MovieWidget / MinimapWidget   (thin Lua wrappers over _GuiInternal.*)
                       │
                       ▼
  _GuiInternal.*  (C++ engine)  +  Scaleform .gfx movies  (minimap.gfx, shell.gfx, topbar, …)
```

* **`mrxgui.lua`** ([resident/mrxgui.lua](src/resident/mrxgui.lua)) is a **facade/alias module**:
  its `Init()` ([mrxgui.lua:384](src/resident/mrxgui.lua#L384)) copies the real implementations
  out of `MrxGuiBase` into the `MrxGui.*` namespace (widget constructors, `AddWidget`,
  `GetWidgetByName`, etc.). It also owns the **global screen-fade** system (two of them: the
  Scaleform `loadingscreen_standalone` "fade-to-black with spinning skull"
  `GlobalFadeToBlack`/`GlobalFadeFromBlack` [mrxgui.lua:86](src/resident/mrxgui.lua#L86), and the
  simple coloured-quad `FadeToColor`/`FadeFromColor`
  [mrxgui.lua:230](src/resident/mrxgui.lua#L230)), plus `AddMessage`, the E3/demo-HUD toggle
  (`SetE3HudMode` [mrxgui.lua:353](src/resident/mrxgui.lua#L353)) and `FindShellWidget`.

* **`mrxguibase.lua`** ([resident/mrxguibase.lua](src/resident/mrxguibase.lua), 1922 lines) is the
  toolkit. Key pieces:
  * **`Widget` base class** ([mrxguibase.lua:390](src/resident/mrxguibase.lua#L390)) with
    `BasicData`/`CustomData`/`EventHandlers`, animation-point system
    (`AddAnimationPoint`/`AnimateToPoint`/`_HandleAnimationComplete`
    [mrxguibase.lua:569](src/resident/mrxguibase.lua#L569)+), colour/translucency/location/anchoring,
    owner (per-player viewport) and children.
  * **Subclasses**: `TextWidget` (920), `ImageWidget` (1080), `FlashWidget` (1202 — Scaleform),
    `SpriteWidget` (1322 — sprite-sheet frames), `MovieWidget` (1365 — Bink FMV),
    `MinimapWidget` (1414).
  * **`WidgetManager`** ([mrxguibase.lua:208](src/resident/mrxguibase.lua#L208)) — registry +
    name/owner indexes (`GetWidgetByName`, `GetWidgetByNameAndOwner`) + event-type index.
  * **`EventManager`** ([mrxguibase.lua:147](src/resident/mrxguibase.lua#L147)) — dispatches
    engine events to widget `EventHandlers`; `ControllerInput` is special-cased through the
    **control-focus queue** (`GetControlFocus`/`ReleaseControlFocus`
    [mrxguibase.lua:33](src/resident/mrxguibase.lua#L33), which also drives
    `SetDialogBoxMode`/`SetSupportMenuMode`).
  * **Layout loader**: `LoadAndAddWidgetFromLayoutFileData`
    ([mrxguibase.lua:1709](src/resident/mrxguibase.lua#L1709)) instantiates a widget tree from a
    declarative `LocalWidgetList` table; `GUIFileLoadedCallback`
    ([mrxguibase.lua:1688](src/resident/mrxguibase.lua#L1688)) and `DuplicateLayout` (1674) make
    the per-player copies.
  * `_tOwnerRequiredEvents` ([mrxguibase.lua:496](src/resident/mrxguibase.lua#L496)) lists the
    engine events that require a player owner: **`GuiAmmoUpdate`, `GuiMinimapUpdate`,
    `GuiHealthUpdate`, `GuiVehicleHealthUpdate`, `GuiReticleUpdate`, `GuiWeaponEquippedUpdate`,
    `GuiSupportMenuEnter`, `GuiPlayerReceiveDamage`, `GuiVehicleNameUpdate`,
    `GuiVehicleDisguiseUpdate`**. This is the canonical list of native per-player HUD events.

* **Layouts vs logic.** The codebase splits every screen into a **`*layout.lua`** (a pure data
  table — widget rectangles, colours, anchors, and `EventHandlerNames` strings) and a logic module
  that defines the handler functions. Layouts share an identical `ReInit()` reload pattern
  (`RemoveWidget` loop + `LoadAndAddWidgetFromLayoutFileData`). Event handlers are bound **two
  ways**: declaratively in the layout (`EventHandlers = { GuiInitialization = Mod.Fn }`) or
  imperatively via `oWidget:SetEventHandler(...)` in the logic module.

* **`MrxGuiManager`** ([resident/mrxguimanager.lua](src/resident/mrxguimanager.lua)) builds the
  four resident layouts once into "master" copies
  (`MrxGuiHudLayout2`, `MrxGuiBinocularsLayout`, `MrxGuiSatelliteLayout`, `MrxGuiPdaLayout`
  [mrxguimanager.lua:9-12](src/resident/mrxguimanager.lua#L9)), then `CreateGui(uPlayerGuid)`
  ([mrxguimanager.lua:4](src/resident/mrxguimanager.lua#L4)) duplicates them per player and assigns
  ownership. It owns the **HUD sleep/visibility stack** (`ToggleHud`
  [mrxguimanager.lua:82](src/resident/mrxguimanager.lua#L82), refcounted via `nHudState`; contexts
  `"briefing"`/`"hijack"`/`"satellite"`/`"scope"` selectively wake specific widgets) and the
  satellite overlay routing (`ToggleSatellite` [mrxguimanager.lua:194](src/resident/mrxguimanager.lua#L194)).
  When the local player's GUI is created it caches `_G.MessageBox / Minimap / ObjectiveTray /
  SubtitleBuffer / MapLabel` ([mrxguimanager.lua:58-64](src/resident/mrxguimanager.lua#L58)).

* **`MrxGuiInterface`** ([resident/mrxguiinterface.lua](src/resident/mrxguiinterface.lua), 1496
  lines) is the **public game-facing API** — it installs `_G.Hud` and `_G.Pda`/`_G.oPda`
  ([mrxguiinterface.lua:12-16](src/resident/mrxguiinterface.lua#L12)). Sub-tables:
  `Hud.Radar` (minimap objectives + line-regions), `Hud.MessageBox`, `Hud.SupportMenu`,
  `Hud.ObjectiveTray`, `Hud.MapLabel`, `Hud.Announcement`/`Hud.FanfareQueue`/`Hud.*Fanfare`,
  `Hud.Cinematic`, `Hud.Tutorial`, `Hud.Satellite`, `Hud.FactionDisplay`; `Pda.Map`, `Pda.Support`,
  `Pda.Database`, `Pda.SubtitleBuffer`. Every method funnels through
  **`_GetWidgetsForPlayers(vPlayers, sName)`** ([mrxguiinterface.lua:1422](src/resident/mrxguiinterface.lua#L1422))
  which resolves a widget name to one-or-all players' instances, and most server methods net-sync
  to clients (`Net.SendEvent_*`). The `NetClient*` functions at the tail
  ([mrxguiinterface.lua:1451](src/resident/mrxguiinterface.lua#L1451)+) are the receiving side.

* **Scaleform / movieclip integration.** `FlashWidget`
  ([mrxguibase.lua:1202](src/resident/mrxguibase.lua#L1202)) wraps a `.gfx`/`.swf` movie:
  `SetSwfFile`, `SetFlashEventHandler` (movie→Lua callbacks),
  `CallActionScriptCallback` (Lua→movie), `SendFlashInput`. Controller input is forwarded into the
  movie by `_HandleInputForFlashWidget` ([mrxguibase.lua:1300](src/resident/mrxguibase.lua#L1300)).
  The known Scaleform assets are listed in §3.

* **Shell vs in-game.** Two near-identical copies of the toolkit exist: `src/resident/` (loaded
  during gameplay) and `src/shell/` (the standalone front-end build). The shell build swaps a few
  modules for lightweight variants (`mrxgui_shellonly.lua`, `mrxguibootstrap_shellonly.lua` — HUD
  functions stubbed) and adds the front-end menu (`mrxguishell.lua` driving **`shell.gfx`**) and
  the paginated-menu helper (`mrxmultipagemenu.lua`). Most other `shell/` files are duplicates of
  their `resident/` counterparts (see §6).

---

## 2. HUD component reference

All HUD components live under `src/resident/` and are children of the per-player `oHud` layout.
Handlers are typically declared in the layout file and read either a `tEvent` table or positional
arguments delivered by the engine event.

### 2.1 Ammo counter — `mrxguihudammocountersnew.lua`
Weapon ammo group: current-clip ammo, clip size ("/N"), reserve/stored ammo, explosives count,
weapon-name label, animated weapon-switch icon assembly, low-ammo red pulse, timed show/fade.
* **Native data fields** (`tEvent.*`): `PrimaryCurrentAmmo`, `PrimaryClipSize`, `PrimaryStoredAmmo`,
  `ExplosivesCurrentAmmo`, `ExplosivesStoredAmmo`
  ([mrxguihudammocountersnew.lua:13-16,77-78,97-98](src/resident/mrxguihudammocountersnew.lua#L13));
  switch events `uNewCurrentGun`/`uNewCurrentGunGuid` (227-232), `uNewCurrentExplosive` (254-255),
  `bShowGun`/`bShowExplosive`/`nTime` (182-195), `bOn` (E3) (269).
* Low-ammo threshold = `PrimaryClipSize/3` (32, 205); posts `"Ammo low"`/`"Ammo not low"` events
  (38, 45). Bound `GuiUpdate` handlers at 214/220/459; the named ammo/switch events are bound in the
  layout. Tunables `_knPulseTime=0.4` (2), `_knRotateTime=0.5` (371), red pulse `216,16,16` (19-21).

### 2.2 Health counter — `mrxguihudhealthcounter.lua`
Numeric health % + depleting health bar (fg/ghost/bg children) + vehicle-armor icon.
* Events: `GuiUpdate`→`HandleUpdateMain` (189), `ShowAllCounters`→`HandleShowHealthEvent` (190).
  The `GuiHealthUpdate` handlers take **positional** `nCurHealth, nMaxHealth, bVehicle`
  (e.g. `HandleHealthChangedEventNew` 43-44, `HandleVehicleEvent` 343-344).
* Vehicle-armor icon swaps texture by `Object.HasLabel` (212): labels `ArmorVehicle`/`ArmorLight`/
  `ArmorMedium`/`ArmorTank` → textures `HUD_vehicle_armor_1..4`
  ([mrxguihudhealthcounter.lua:13-35](src/resident/mrxguihudhealthcounter.lua#L13)); default human
  icon `global_gui_hud02` (6). Tunables: `_knPulsingThreshold=20` (2), `_knVisibleThreshold=100` (3),
  `_knShowTime=2` (1), `_knPulseTime=0.4` (4).
* Debug: `Debug.Printf("<--> HandleHealthChangedEvent")` (257).

### 2.3 Reticle — `mrxguihudreticle.lua`
Base reticle, animated 4-piece spread crosshair, target-health arc, Stinger lock-on reticle
(flashing + targeting sound), laser-designator reticle.
* Events: `GuiReticlePositionChange`→`HandleReticlePositionChange` (81),
  `GuiUpdate`→`HandleCrosshairUpdate` (138) / `HandleStingerReticleUpdate` (317).
* Native fields: **`sReticleType`** (43,46,48 — values `"Homing"`/`"Normal"`/`"None"`/`"Laser"`),
  `uReticleTexture` (50), `bReticleCrosshair` (56), `sReticleHealthType` (59),
  `nMaxLockOnRadius` (390), `nStingerReticleWidth`/`Height` (393); positional color-change args
  `nTargetRelation, nScreenX, nScreenY, nSpreadX, nSpreadY, nHealth, nMaxHealth` (5).
  `Gui.GetReticlePosition(owner)` (21,76,90,140).
* Sound `_ksTargettingSound="ui_HUD_SAM_targeting"` (3); texture
  `global_gui_reticle_stinger_target` (297). Colors enemy `255,0,0` / friendly `0,0,255` (8-19).

### 2.4 Damage indicator — `mrxguihuddamageindicator.lua`
Directional "took damage" fading arcs pointing at the source, centered on the reticle widget.
* **`GuiPlayerReceiveDamage`** handler `HandleReceiveDamageEvent` (re-bound at 78 in E3 toggle);
  per-arc `GuiUpdate`→`HandleUpdateEvent` (41). Positional args `nDamageDirection, nDamageAmount`
  (3); opacity = `min(pow(nDamageAmount,0.5)*100, 255)` (46); rotation uses
  `Player.GetCameraXZHeading(owner)` (42). Locates the reticle by name `"reticle"` (7).

### 2.5 Resource counter — `mrxguihudresourcecounter.lua`
Animated **Money Counter** / **Fuel Counter** (rolling value, rise/fall pulse, shake, open/close
window, magnitude-based sound cues, transaction-reason sub-list).
* `GuiUpdate`→`_HandleCounterUpdateEvent` (103)/`_TopLevelUpdate` (327); externally-bound
  `_HandleShowEvent`/`_HandleSetValueEvent` read `tEvent.nTime`/`uGuid`/`nValue` (399,403,405).
  `MrxPmc.GetFuelCapacity()` (96).
* Widget names `"Money Counter"` (199) / `"Fuel Counter"` (204). Cash sound cues
  `UI_hud_cashUp_large/med/small`, `UI_hud_cashDown_large/med/small` (52-74). Number formatting
  uses localized suffix tokens `_tNumbers` (516-520) + `"[SHELL.Common.Money:%d:%d:%s]"` (510).
  Tunables `_kDefaultTickTime=0.5` (5), `_kPulseTime=0.2` (9).

### 2.6 Melee / context-action prompt — `mrxguihudmelee.lua`
Mostly stubs; live function is `SetContextActionMessage(sText, uPlayer, nPriority)` (21) → widget
**`"Context Action Text"`** (24/26), sound `ui_HUD_Contextual_Action_Alert` (46/60), markup prefix
`"[action] "` (48/63). No `SetEventHandler` calls.

### 2.7 Radar / minimap — `mrxguihudradar.lua`
The minimap. Loads the Scaleform **`minimap.gfx`** (69); draws faction-zone region overlays
(AS callbacks `"AddZone"`/`"RemoveZone"` 99/58), GPS + target markers, a map-label flash, and a
trespass faction icon.
* Events: `SetTargetMarker`→`HandleSetTargetMarker` (73), `SetGPSDest`→`HandleSetGPSDest` (74),
  `ClearGPSDest`→`HandleClearGPSDest` (75). **There is no Lua `GuiMinimapUpdate` handler here** —
  per-frame blip placement is engine→Scaleform; the Lua `GuiMinimapUpdate` path is the generic
  `MinimapWidget` (`MinimapDataUpdateHandler` [mrxguibase.lua:1532](src/resident/mrxguibase.lua#L1532)).
* Marker/icon strings: GPS objective icon **`"MiniMap_Icon_GPS_Marker"`**
  ([mrxguihudradar.lua:143](src/resident/mrxguihudradar.lua#L143)) — note the `MiniMap_Icon_*`
  casing; target-marker name prefix `_sTargetName="Target marker"` (128); GPS objective name
  `_sGPSName="GPS Beacon Marker"` (140); map-label flash name `"maplabeltext"` (203). Trespass
  faction icons `_tIcons` (260-266): `HUD_faction_AN/CH/CV/GR/OC/PR/VZ`. `Pg.GetLineRegionPoints`
  (91). Zone offsets `nXOffset=35`, `nYOffset=40` (94-95).

### 2.8 Objective tray — `mrxguihudobjectivetray.lua`
A 3-slot vertical tray holding text or image objective entries (slot reuse by
`oSlotDisplay.BasicData.type`). No engine events; built by `_HandleInitializationEvent` (137):
`nSlots=3`, spacing `5`, default height `16`, font `"english_18"`.

### 2.9 Faction gauge — `mrxguihudfactiongauge.lua`
A single faction mood/reputation bar (delta overlay, faction icon, mood-name text, countdown timer,
pursuit overlay). Driven by `SetValue`/`ChangeValue`/`StartTimer`/`StartPursuit` API from the
buffer, not engine events (only the internal timer `GuiUpdate`→`_UpdateTimer` 680). Levels
`_tLevels={0,25,50,75}` (10-15) with localized names (16-21) and colors (27-48). Pursuit label
`_ksPursuit="[0x1cab5133]"` (4). Icon texture is supplied by the caller via `SetIcon` (436).
* Developer `Debug.Printf` validation errors at 69/75/80/84/90/93 (e.g.
  `"Faction display level setup error: First threshold is not 0"`).

### 2.10 Faction buffer — `mrxguihudfactionbuffer.lua`
Manager holding up to **2** on-screen gauges (`_knNumSlots=2`, 2), aging them out, and temporarily
hiding the **`"Objective Tray"`** (104/136/169/224) when a gauge occupies the bottom slot. Duplicates
the template gauge per faction; per-frame `GuiUpdate`→`_Update` (31). Faction icon textures are
passed in (`AddFactionGauge`/`SetIcon`), not hardcoded.

### 2.11 Vehicle disguise — `mrxguihudvehicledisguise.lua`
Faction icon + crossed-out icon, a disguise-level bar, and a vehicle-name identifier.
* `GuiUpdate`→`DisguiseUpdate` (160). `GuiVehicleNameUpdate`→`HandleVehicleNameUpdate(oWidget,
  sName, uFaction)` (174); `GuiVehicleDisguiseUpdate`→`HandleDisguiseUpdate(oWidget, nLevel,
  bDisguised)` (222). `Player.GetVehicleDisguise()` (130-133,158).
* **Faction icon textures `_tFactionTextures`** (282-289): `HUD_faction_AN/CH/OC/GR/PR/CV/VZ` **plus
  `HUD_faction_PMC`** (289) — 8 entries (radar's `_tIcons` omits PMC). Fallback icon
  **`"temp_radar_icon_pmc"`** (139,143) — a `temp_`-prefixed placeholder, a likely missing-asset
  candidate in a ported WAD. Disguise states `STATE_DISGUISED/UNDISGUISED/GAINING/LOSING=1..4`
  (54-57); display threshold `<50⇒hide` (78).

### 2.12 Action hijack (QTE) — `mrxguihudactionhijack.lua`
Hijack/minigame button-prompt overlay: button or stick-direction sprite, circular countdown,
spark animation, fail icon, minigame sounds. Switches PC vs Xbox sprite sets via
`Gui.IsXboxController()` (63). Widget name **`"Action Hijack"`** (46). API-driven (`ShowButton`
37, `HideButton` 152, `ShowFail` 173); no `SetEventHandler`.
* Textures: `countdown_circle` (124), `icon_hijack_glow` (127), `icon_fail` (261),
  `icon_sparks_left/right` (271/282); PC button sprites `icon_hijack_button_Y/A/X/B` (321-324) and
  `icon_hijack_joystick_*` (325-329); Xbox set `icon_hijack_xbox_button_*` / `icon_hijack_xbox_joystick_*`
  (333-341); `Use_Melee`/`Use_Reload` (330-331) + `xbox_*` (342-343). All preloaded via
  `Gui.LoadTexture` (292-317).
* Sounds `_ksPressSound`/`_ksErrorSound`/`_ksMashSound`/`_ksRecoverSound` (2-5).
* Debug: `"No data for given action hijack buttons"` (42), `"IsXboxController returned TRUE/FALSE"`
  (64/76), `"Deprecated."` (227/231).

### 2.13 Support menu (radial) — `mrxguihudsupportmenu.lua`
In-world vertical wheel of equipped support items (airstrikes / vehicle drops / supplies); D-pad
scrolls a 5-slot display, trigger fires. **Not opened by `GuiSupportMenuEnter`** — opened via
`GuiGameStateChange` state `"SupportMenu"` Enter/Exit
([mrxguihudsupportmenu.lua:407,1821](src/resident/mrxguihudsupportmenu.lua#L407)) and the PDA equip
flow.
* Events: `ControllerInput`→`HandleInputEvent` (406), `GuiGameStateChange`→`_HandleGameStateChangeEvent`
  (407); many per-phase `GuiUpdate` swaps. D-pad map: `BUTTON_PAD1_U`=scroll-down,
  `BUTTON_PAD1_D`=scroll-up, `BUTTON_PAD2_D`/`BUTTON_ALT2_1`=trigger (1744-1748).
* Native: `MrxPmc.GetFuelQty/GetCashQty/GetFreebieQty/GetSupportQty` (163-181),
  `oSupport:GetFuelCost/GetCashCost/GetSupportName/GetDenialCondition` (162-189). Default item icon
  `HUD_ICON_support_crate` (605/611), atlas `global_gui_hud02` (1978/2013). `_knFrame=0.022222223`
  (6 — master timestep), `nItemSpacing=43` (385). Sounds `ui_HUD_Support_Select/Open_Menu/Close_Menu/Scroll`
  (209/288/326/550).

---

## 3. Defaults & tunables (cross-cutting)

### Scaleform / movieclip assets referenced
| Asset (`.gfx`/`.swf`) | Used by | Line |
|---|---|---|
| `minimap.gfx` | radar/minimap | [mrxguihudradar.lua:69](src/resident/mrxguihudradar.lua#L69) |
| `shell.gfx` (`GetShellGfxFilename`) | front-end shell menu | [shell/mrxguishell.lua:198](src/shell/mrxguishell.lua#L198) |
| `topbar` | PDA main movie | [mrxguipda.lua:1437](src/resident/mrxguipda.lua#L1437) |
| `landingzones` | PDA transit interface | [mrxguipda.lua:812](src/resident/mrxguipda.lua#L812) |
| `garage` | garage screen | [mrxguigarage.lua:7](src/resident/mrxguigarage.lua#L7) |
| `pause_menu` | pause screen | [mrxguipausescreen.lua:357](src/resident/mrxguipausescreen.lua#L357) |
| `dialog_box` | system/online dialog | [mrxguidialogbox.lua:862](src/resident/mrxguidialogbox.lua#L862) |
| `loadingscreen` | load screen | [mrxguiloadscreen.lua:3](src/resident/mrxguiloadscreen.lua#L3) |
| `loadingscreen_standalone` | global fade-to-black | [mrxgui.lua:106](src/resident/mrxgui.lua#L106) |
| `LTI_precache` | precache loading movie | [mrxguiltiprecache.lua:73](src/resident/mrxguiltiprecache.lua#L73) |
| `text_effect` | "classy text" fanfare | [mrxguihudmessage.lua:1075](src/resident/mrxguihudmessage.lua#L1075) |
| `fanfare_contract/mission/wager/support_unlocked/new_contact[/_<faction>_businesscard]` | fanfares | [mrxguihudmessage.lua:22-37](src/resident/mrxguihudmessage.lua#L22) |
| intro movies `EA`, `Pandemic`; idle `attract` | shell bootstrap / attract | [shell/shellbootstrap.lua:5-8](src/shell/shellbootstrap.lua#L5), [mrxguiattractmode.lua:7](src/resident/mrxguiattractmode.lua#L7) |

### Minimap / faction marker names (the "marker not found" warning)
The engine warning **`!!!!!!!!!!! CLIENT WON'T SEE THIS ... Could not find marker <name> in
World/Pda/Radar table`** is emitted from `MrxUtil.MarkerGetIndexByName_World/Pda/Radar`
([resident/mrxutil.lua:944,956,968](src/resident/mrxutil.lua#L944)). These are the net-sync
name→index lookups that `Hud.Radar:AddObjective` calls via
`MrxUtil.MarkerGetIndexByName_Radar(tArgs.sTexture)`
([mrxguiinterface.lua:25](src/resident/mrxguiinterface.lua#L25)). A texture name passed to a
minimap/radar objective that is **not** in the engine's marker table (`tObjRadarMaker` etc.)
returns index 0 and logs the warning — i.e. the marker still draws on the host but won't replicate
to clients. Marker-name literals to audit:

* `MiniMap_Icon_GPS_Marker` (radar GPS icon, [mrxguihudradar.lua:143](src/resident/mrxguihudradar.lua#L143)).
* Faction icon family `HUD_faction_{AN,CH,CV,GR,OC,PR,VZ,PMC}` (radar `_tIcons` 260-266 — 7;
  vehicledisguise `_tFactionTextures` 282-289 — 8 incl. `HUD_faction_PMC`).
* `temp_radar_icon_pmc` placeholder ([mrxguihudvehicledisguise.lua:139](src/resident/mrxguihudvehicledisguise.lua#L139)).
* Target markers use a **dynamic** texture (`tData.texture`), so a missing target texture surfaces
  the same warning at runtime.

### Common layout / coordinate constants
* Reference resolution is **640×480**: `nWidgetSpaceScreenWidth/Height=640/480`
  ([mrxguibase.lua:1791-1792](src/resident/mrxguibase.lua#L1791)); screen scale derived from height.
* World→minimap/PDA offsets `nXOffset=35`, `nZOffset/nYOffset=40` recur in radar
  (94-95) and PDA (442-443, 690-691, 1549-1550).
* Default reticle size `48` ([mrxgui.lua:381](src/resident/mrxgui.lua#L381)).
* Boundary line-region color `0,0,0,160` ([mrxguiinterface.lua:1455-1458](src/resident/mrxguiinterface.lua#L1455)).
* PDA blip cap `_knBlipLimit=5000` ([mrxguipda.lua:43](src/resident/mrxguipda.lua#L43)); attract idle
  `_nTimeToAttractMode=60` ([shell/mrxguishell.lua:5](src/shell/mrxguishell.lua#L5)); multipage menu
  `_knMaxOptionsPerPage=8` ([shell/mrxmultipagemenu.lua:13](src/shell/mrxmultipagemenu.lua#L13)).
* Common pulse timing `_knPulseTime≈0.4` across ammo/health/disguise.

---

## 4. Per-module clickable refs

### Core / toolkit
* [mrxguibase.lua:33 GetControlFocus](src/resident/mrxguibase.lua#L33) ·
  [:147 EventManager](src/resident/mrxguibase.lua#L147) ·
  [:208 WidgetManager](src/resident/mrxguibase.lua#L208) ·
  [:390 Widget](src/resident/mrxguibase.lua#L390) ·
  [:496 _tOwnerRequiredEvents](src/resident/mrxguibase.lua#L496) ·
  [:1202 FlashWidget](src/resident/mrxguibase.lua#L1202) ·
  [:1414 MinimapWidget](src/resident/mrxguibase.lua#L1414) ·
  [:1709 LoadAndAddWidgetFromLayoutFileData](src/resident/mrxguibase.lua#L1709) ·
  [:1896 Init](src/resident/mrxguibase.lua#L1896)
* [mrxgui.lua:86 GlobalFadeToBlack](src/resident/mrxgui.lua#L86) ·
  [:230 FadeToColor](src/resident/mrxgui.lua#L230) ·
  [:353 SetE3HudMode](src/resident/mrxgui.lua#L353) ·
  [:384 Init](src/resident/mrxgui.lua#L384)
* [mrxguimanager.lua:4 CreateGui](src/resident/mrxguimanager.lua#L4) ·
  [:82 ToggleHud](src/resident/mrxguimanager.lua#L82) ·
  [:151 AddWidgetToHud](src/resident/mrxguimanager.lua#L151) ·
  [:194 ToggleSatellite](src/resident/mrxguimanager.lua#L194)
* [mrxguiinterface.lua:19 Hud.Radar:AddObjective](src/resident/mrxguiinterface.lua#L19) ·
  [:374 Hud.SupportMenu](src/resident/mrxguiinterface.lua#L374) ·
  [:1132 Pda:SetSuppressed](src/resident/mrxguiinterface.lua#L1132) ·
  [:1422 _GetWidgetsForPlayers](src/resident/mrxguiinterface.lua#L1422)

### HUD components
* [mrxguihudammocountersnew.lua:343 HandleInitializationEvent](src/resident/mrxguihudammocountersnew.lua#L343)
* [mrxguihudhealthcounter.lua:189 HandleUpdateMain](src/resident/mrxguihudhealthcounter.lua#L189)
* [mrxguihudreticle.lua:81 HandleReticlePositionChange](src/resident/mrxguihudreticle.lua#L81) ·
  [:317 HandleStingerReticleUpdate](src/resident/mrxguihudreticle.lua#L317)
* [mrxguihuddamageindicator.lua:3 HandleReceiveDamageEvent](src/resident/mrxguihuddamageindicator.lua#L3)
* [mrxguihudresourcecounter.lua:103 _HandleCounterUpdateEvent](src/resident/mrxguihudresourcecounter.lua#L103)
* [mrxguihudmelee.lua:21 SetContextActionMessage](src/resident/mrxguihudmelee.lua#L21)
* [mrxguihudradar.lua:143 GPS marker icon](src/resident/mrxguihudradar.lua#L143) ·
  [:259 _tIcons faction table](src/resident/mrxguihudradar.lua#L259)
* [mrxguihudobjectivetray.lua:137 _HandleInitializationEvent](src/resident/mrxguihudobjectivetray.lua#L137)
* [mrxguihudfactiongauge.lua:126 Initialize](src/resident/mrxguihudfactiongauge.lua#L126)
* [mrxguihudfactionbuffer.lua:41 AddFactionGauge](src/resident/mrxguihudfactionbuffer.lua#L41)
* [mrxguihudvehicledisguise.lua:222 HandleDisguiseUpdate](src/resident/mrxguihudvehicledisguise.lua#L222) ·
  [:282 _tFactionTextures](src/resident/mrxguihudvehicledisguise.lua#L282)
* [mrxguihudactionhijack.lua:37 ShowButton](src/resident/mrxguihudactionhijack.lua#L37) ·
  [:321 sprite-texture map](src/resident/mrxguihudactionhijack.lua#L321)
* [mrxguihudsupportmenu.lua:343 HandleInitializationEvent](src/resident/mrxguihudsupportmenu.lua#L343) ·
  [:1733 HandleInputEvent](src/resident/mrxguihudsupportmenu.lua#L1733) ·
  [:1821 _HandleGameStateChangeEvent](src/resident/mrxguihudsupportmenu.lua#L1821)

### Screens
* [mrxguipda.lua:1421 _Initialize](src/resident/mrxguipda.lua#L1421) ·
  [:1530 _FinishLoad](src/resident/mrxguipda.lua#L1530) ·
  [:429 _PopulateMapDisplay](src/resident/mrxguipda.lua#L429) ·
  [:991 _PopulateSupportDisplay](src/resident/mrxguipda.lua#L991)
* [mrxguisatellite.lua:28 SetActivated](src/resident/mrxguisatellite.lua#L28) ·
  [:473 BeginMinigame](src/resident/mrxguisatellite.lua#L473) ·
  [:627 _HandleMinigameInput](src/resident/mrxguisatellite.lua#L627)
* [mrxguigarage.lua:9 Create](src/resident/mrxguigarage.lua#L9) ·
  [:143 _SetupGarageFlash](src/resident/mrxguigarage.lua#L143)
* [mrxguidialogbox.lua:15 DisplayDialogBox](src/resident/mrxguidialogbox.lua#L15) ·
  [:384 DisplayScrollingDialogBox](src/resident/mrxguidialogbox.lua#L384) ·
  [:847 OpenSystemDialogBox](src/resident/mrxguidialogbox.lua#L847)
* [mrxguinumericbox.lua:16 DisplayNumericBox](src/resident/mrxguinumericbox.lua#L16) ·
  [:52 _BuildNumericBox](src/resident/mrxguinumericbox.lua#L52)
* [mrxguicinematic.lua:55 ShowMovie](src/resident/mrxguicinematic.lua#L55) ·
  [:389 BeginSubtitles](src/resident/mrxguicinematic.lua#L389)
* [mrxguiloadscreen.lua:26 HandleStateChangeEvent](src/resident/mrxguiloadscreen.lua#L26) ·
  [:105 InitSaveIcon](src/resident/mrxguiloadscreen.lua#L105)
* [mrxguipausescreen.lua:175 OpenPauseScreen](src/resident/mrxguipausescreen.lua#L175) ·
  [:39 Init (tControlMap)](src/resident/mrxguipausescreen.lua#L39) ·
  [:408 _ConfirmMedEvacEvent](src/resident/mrxguipausescreen.lua#L408)
* [mrxguitutorial.lua:12 DisplayTutorial](src/resident/mrxguitutorial.lua#L12) ·
  [:299 InitInfoImage](src/resident/mrxguitutorial.lua#L299)
* [mrxguihudmessage.lua:325 CommenceFanfare](src/resident/mrxguihudmessage.lua#L325) ·
  [:795 ShowEventFanfare](src/resident/mrxguihudmessage.lua#L795) ·
  [:944 ShowMessage](src/resident/mrxguihudmessage.lua#L944)
* [mrxguibinoculars.lua:7 HandleBinocularsEnter](src/resident/mrxguibinoculars.lua#L7) ·
  [mrxguisniperscope.lua:7 HandleSniperScopeEnter](src/resident/mrxguisniperscope.lua#L7)
* [mrxguitextbuffer.lua:134 AddMessage](src/resident/mrxguitextbuffer.lua#L134) ·
  [:365 HandleTextBufferUpdateEvent](src/resident/mrxguitextbuffer.lua#L365)
* [mrxguiattractmode.lua:10 HandleInit](src/resident/mrxguiattractmode.lua#L10) ·
  [mrxguiltiprecache.lua:6 OpenPrecache](src/resident/mrxguiltiprecache.lua#L6)

### Shell (front-end)
* [shell/mrxguishell.lua:241 HandleInitializationEvent](src/shell/mrxguishell.lua#L241) ·
  [:511 CompleteFlashSetup](src/shell/mrxguishell.lua#L511) ·
  [:763 _LTIFscommand](src/shell/mrxguishell.lua#L763)
* [shell/mrxmultipagemenu.lua:43 AddOption](src/shell/mrxmultipagemenu.lua#L43) ·
  [:55 Display](src/shell/mrxmultipagemenu.lua#L55)
* [shell/shellbootstrap.lua:66 Init](src/shell/shellbootstrap.lua#L66) ·
  [:11 _PlayMovie](src/shell/shellbootstrap.lua#L11)
* [shell/mrxguishellbootstrap.lua:8 Init](src/shell/mrxguishellbootstrap.lua#L8) ·
  [:55 EnterShell](src/shell/mrxguishellbootstrap.lua#L55)

---

## 5. Logging & debug markers

* **Marker-not-found (the known warning)** — `mrxutil.lua` (called from the radar interface):
  `"!!!!!!!!!!! CLIENT WON'T SEE THIS ... Could not find marker <name> in World table"`
  ([:944](src/resident/mrxutil.lua#L944)), `...in Pda table` ([:956](src/resident/mrxutil.lua#L956)),
  `...in Radar table` ([:968](src/resident/mrxutil.lua#L968)).
* **Interface** — `"Cannot remove nil objective"` ([mrxguiinterface.lua:41](src/resident/mrxguiinterface.lua#L41));
  `NetClientFactionSetValue/StartPursuit/HideMeter` prints (1476/1485/1494); `FanfareQueue:
  Commit/Append/Advance/Pending` (571-592); `TextFanfare …` (771).
* **Manager** — `"Failed to set callback, satellite designation will not work."`
  ([mrxguimanager.lua:239](src/resident/mrxguimanager.lua#L239)).
* **Fade system** — a wall of `~~~~ GlobalFadeToBlack/FromBlack` traces plus the recurring
  `"BLACKSCREEN - FadeToColor/FadeFromColor called from …"` strings (mrxgui.lua 87/100/121,
  cinematic 96/184, shell 232/236/574, attract 64).
* **PDA** — heavy `Debug.Printf` instrumentation (`"NetEventCallback!!!"` 19, `"OPEN!!!"` 131,
  `"SETSELECTEDMISSION!!!"` 375, `"ERROR: No PDA found!"` 1865); UI placeholders `"DESIGNER ERROR"`
  (277), `"ERROR: No support denial condition specified."` (1071).
* **Faction gauge** — the six setup-validation errors (mrxguihudfactiongauge.lua 69-93).
* **Action hijack** — `"No data for given action hijack buttons"` (42), Xbox-controller traces
  (64/76), `"Deprecated."` (227/231).
* **Health** — `"<--> HandleHealthChangedEvent"` ([mrxguihudhealthcounter.lua:257](src/resident/mrxguihudhealthcounter.lua#L257)).
* **Satellite** — `"Bad data for satellite targetting minigame, using default data."` ([mrxguisatellite.lua:690](src/resident/mrxguisatellite.lua#L690)).
* **LTI precache** — a dozen `MrxGuiLTIPrecache.lua …` traces (mrxguiltiprecache.lua 8-141).
* **Tutorial / fanfare** — `"Text bounding box outside of the screen, text may be squished."`
  ([mrxguihudmessage.lua:1069](src/resident/mrxguihudmessage.lua#L1069)).

---

## 6. Cross-references & future-dev notes

### Engine event bindings (where each native event is consumed)
| Engine event | Consumer | Payload shape |
|---|---|---|
| `GuiAmmoUpdate` (layout-bound) | ammo counter | `tEvent.Primary*Ammo/ClipSize`, `Explosives*` |
| `GuiHealthUpdate` (positional) | health counter | `nCurHealth, nMaxHealth, bVehicle` |
| `GuiReticleUpdate` / `GuiReticlePositionChange` | reticle | `sReticleType`, `uReticleTexture`, spread/health |
| `GuiPlayerReceiveDamage` | damage indicator | `nDamageDirection, nDamageAmount` |
| `GuiMinimapUpdate` | generic `MinimapWidget` (base) | `FocusX/Y/Z, Rotation` |
| `GuiVehicleNameUpdate` / `GuiVehicleDisguiseUpdate` | vehicle disguise | `sName,uFaction` / `nLevel,bDisguised` |
| `GuiGameStateChange` `"SupportMenu"`/`"Pause"`/`"PDA"` | support menu / pause / pda | `sStateName, sStateAction` |
| `SatelliteStateChange` / `SatelliteProgressUpdate` (from `MrxGuiManager.ToggleSatellite`) | satellite overlay | `bActivate,bAdvanced,bMinigame` / `nX,nY,nZ,nPercent` |
| `E3HudMode` (`bOn`) | ammo/health/damage/radar (strip HUD for demo) | `bOn` |
| `ShowAllCounters`/`GuiShowAmmoCounter` | health/ammo (re-show on unpause) | `nTime` |

### How to add / modify a HUD element
1. Add the widget rectangle + `EventHandlerNames` to the relevant **layout** (`MrxGuiHudLayout2`
   for in-game HUD) so `LoadAndAddWidgetFromLayoutFileData` instantiates it per player.
2. Implement handlers in a logic module; bind owner-scoped engine events from `_tOwnerRequiredEvents`
   via the layout or `oWidget:SetEventHandler`. Owner-required events are silently dropped if the
   widget has no owner — always go through `MrxGuiManager`/the per-player layout, never a bare
   global widget.
3. Expose a game-facing method on `Hud.*`/`Pda.*` in `mrxguiinterface.lua`, route through
   `_GetWidgetsForPlayers`, and (if it should appear on remote clients) add a `Net.SendEvent_*` on
   the server branch + a `NetClient*` receiver.
4. For a **minimap/radar marker**, the texture name passed as `sTexture` must exist in the engine's
   radar marker table or `MarkerGetIndexByName_Radar` returns 0 and clients won't see it (the §5
   warning). When porting/rebuilding the WAD, verify the `HUD_faction_*` family and the
   `MiniMap_Icon_GPS_Marker` / `temp_radar_icon_pmc` assets are present.

### How to add a menu option (front-end / pause)
* Front-end menu items are Scaleform `shell.gfx` ActionScript callbacks registered in
  `mrxguishell.HandleInitializationEvent`/`CompleteFlashSetup`; the `_LTIFscommand` dispatch
  ([shell/mrxguishell.lua:763](src/shell/mrxguishell.lua#L763)) bridges fscommands to `LTILibName.*`
  option setters. List-style menus use `mrxmultipagemenu.lua` (8 options/page, auto Next/Prev).
* Pause menu options live in `pause_menu` SWF; the Lua side wires `LTI*` handlers in
  `_FinishPauseOpen`/`_FinishLoad` ([mrxguipausescreen.lua:190,369](src/resident/mrxguipausescreen.lua#L190))
  and the per-vehicle control legend `tControlMap` ([:42-171](src/resident/mrxguipausescreen.lua#L42)).

### Shell vs resident duplicates
`shell/` is a near-complete duplicate of `resident/`. Files that are duplicates (do not edit one
without the other): `mrxgui`, `mrxguibase`, `mrxguimanager`, `mrxguidialogbox`, `mrxguinumericbox`,
`mrxguicinematic(layout)`, `mrxguiattractmode/layout`, `mrxguiloadscreen/layout`,
`mrxguiltiprecache(layout)`, and the sound modules (`mrxmusic`, `mrxsound`, `mrxsoundbanks`,
`mrxsoundcategories`, `mrxsoundshellbootstrap`). Genuinely shell-specific: `mrxguishell`,
`mrxmultipagemenu`, `shell`, `shellbootstrap`, `mrxshellbootstrap`, `mrxguishellbootstrap`,
`mrxguishelllayout`, `mrxutil_shell`, `mrxgui_shellonly`, `mrxguibootstrap_shellonly`.

### Latent bugs flagged during the read (porting hazards)
* `mrxguitextbuffer.lua` `InstantiateTextBuffer` ([:62](src/resident/mrxguitextbuffer.lua#L62))
  writes `oWidget.CustomData.*` at ~110-111 where the local is named `NewTextBuffer` — a nil/global
  index if that programmatic path is exercised (the event path `HandleInstantiationEventForTextBuffer`
  is fine).
* `MinimapWidget:SetVisible` ([mrxguibase.lua:1452](src/resident/mrxguibase.lua#L1452)) iterates
  children with an undefined `isVisible` (should be `bVisible`), so child widgets are hidden, never
  shown.
