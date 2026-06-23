# GUI / HUD

Scope: in-game GUI and HUD — the Lua-facing `Gui*` event/update bus, the minimap, reticles, on-screen markers/blips, the PDA map, screen effects, Scaleform/GFx Flash UI, and movie/widget playback.

Provenance: symbol and string evidence recovered from the Xbox 360 devkit "Profile" build `Mercs2_Xenon_P.exe` (Mercenaries 2: World in Flames, Jul 11 2008 preview, PowerPC). This is NOT a real `.pdb`; all names below are copy-exact from the shared evidence files. Build source tree was `d:\projects\ReleaseLine\Mercs2\`. Pandemic's in-house engine is "Pangea" (`Pg*`). Scaleform GFx is the Flash-based UI middleware.

## Overview

The HUD layer is exposed to gameplay scripts as a flat set of `Gui*` entry points that the engine calls to push state into the on-screen display: health, ammo, reticle, minimap, vehicle name/health/disguise, weapon-equipped, game timer, and pause/game-state changes (`GuiHealthUpdate`, `GuiAmmoUpdate`, `GuiReticleUpdate`, `GuiMinimapUpdate`, `GuiVehicleHealthUpdate`, `GuiGameStateChange`, `GuiPauseStateChange`, `GuiGameTimer`). A general `GuiUpdate` plus mode setters (`GuiSetSupportMenuMode`, `GuiSetDialogBoxMode`) round out the bus. These appear to be a script-callable API surface rather than C++ class methods: they show up as flat `.rdata` symbols and have matching string forms in the strings table.

Underneath, rendering is a Scaleform/GFx Flash pipeline (`PgGui::BeginFrame`, `GUI::Render`, `GuiMarkers::Render`, plus a family of `PgScaleform*` shader programs and `GFx*` loader/parser code). Movie and Flash "widgets" are created and driven from script (`CreateMovieWidget`, `CreateFlashWidget`, `SetMovieFile`, `PlayMovie`). The minimap and PDA map are a separate world-blip system (`Minimap*`, `Pda*`, `*Blip*`, `Marker*`). No GUI/HUD-specific C++ source path or RTTI class survives in the recovered tables (see Evidence & confidence) — the only related source path is the Xenon movie player.

## Source files

From `mercs2_xenon_p.source_paths.txt`, the only path that belongs to (or borders) this system:

- `d:\projects\ReleaseLine\Mercs2\Pangea\Src\Xenon\PgMoviePlayerXenon.cpp` — Xenon movie/cutscene playback (drives the `Movie`/`*Movie*` script API and `.bik` playback; see Notable strings). The string `^<@%s\%s.bik` and the `Movie%1dTexY%1d`/`Movie%1dTexU%1d` texture-plane names live alongside it.

No `PgGui`, `PgHud`, `PgScaleform`, minimap, reticle, or marker `.cpp` source path is present in the recovered source-paths list.

## Key classes

None. The recovered RTTI table (`mercs2_xenon_p.rtti_classes.txt`, 324 classes) contains only Havok (`hk*`/`hkp*`) classes; no `Gui*`, `PgGui`, `PgScaleform`, `GFx*`, minimap, reticle, or marker class has emitted RTTI. The GUI/HUD class names below (`PgGui`, `GuiMarkers`, `GFxSprite`, `GFxLoader`, `GFxTextDocView`, `GFxSwfEvent`) are known only from `Class::Method` debug/log strings, not from RTTI — they are real C++ classes named in their own log/assert text.

## Symbols by area

Offsets are as they appear in `inventory/gui-hud.txt` (PE offset, then section). Strings without an inventory offset are cited by their `mercs2_xenon_p.pe_full_strings.txt` line and live in `.rdata`/data.

### Gui* script/event bus (`.rdata`)

| Offset | Symbol | Note |
|---|---|---|
| 0x002d694 | `GuiHealthUpdate` | push player health to HUD |
| 0x002d6b8 | `GuiAmmoUpdate` | push ammo count |
| 0x002d668 | `GuiReticleUpdate` | reticle state |
| 0x002d6a4 | `GuiMinimapUpdate` | minimap refresh |
| 0x002d67c | `GuiVehicleHealthUpdate` | vehicle health bar |
| 0x002d5bc | `GuiVehicleNameUpdate` | vehicle name plate |
| 0x002d5a0 | `GuiVehicleDisguiseUpdate` | disguise state |
| 0x002d628 | `GuiWeaponEquippedUpdate` | current weapon |
| 0x002d5d4 | `GuiPlayerReceiveDamage` | damage feedback |
| 0x002d5ec | `GuiGameStateChange` | game-state transition |
| 0x002d654 | `GuiPauseStateChange` | pause toggle |
| 0x002d600 | `GuiSeatMenuEnter` | vehicle seat menu |
| 0x002d614 | `GuiSupportMenuEnter` | support/store menu |
| 0x002d874 | `GuiGameTimer` | on-screen timer |
| 0x002d6c8 | `GuiUpdate` | generic per-frame update |
| 0x002f8c0 | `GuiSetSupportMenuMode` | set support-menu mode |
| 0x002f8d8 | `GuiSetDialogBoxMode` | set dialog-box mode |
| 0x0042aa8 | `GuiShowAmmoCounter` | toggle ammo counter |

Related string-only forms not in the inventory subset: `GuiAnimateUpdate` (strings line 4834). `GuiSeatMenuEnter`/`GuiSupportMenuEnter` pair with the bare `SeatMenu`/`SupportMenu` strings (lines 4880/4879).

### GUI / Scaleform render pipeline (string-only)

These are `Class::Method` markers (no inventory offset; from `pe_full_strings.txt`):

- `PgGui::BeginFrame` (line 5343), `GUI::Render` (5340), `GuiMarkers::Render` (5341), `Render::ApplyFilters` (5342), `MyFX::BeginFrame` (5344) — the per-frame GUI render entry points (these are profiler/log scope names).
- Scaleform shader programs (each with a `.sho` compiled twin): `PgScaleformSolidColorFP`, `PgScaleformCxformTexMultiplyFP`, `PgScaleformTextTextureFP`, `PgScaleformStripFP`, `PgScaleformGlyphVP`, `PgScaleformStripVP` (lines 1519–1530). The `Glyph`/`Text`/`Cxform`/`Strip` naming is standard Scaleform GFx draw primitives.
- `Scaleform cache cleanup` (1531), `Show Scaleform Stats` (631), perf counters `Scaleform lines    : %d` / `Scaleform triangles: %d` (5135/5136).
- `gfxExtensions` — inventory `0x00ac2fc .rdata` (and string line 13424); `scaleformgfx` asset tag (line 2460).

### GFx (Flash) loader / parser (string-only)

A full Scaleform GFx loader is linked in (lines ~13188–13897): `GFxLoader`, `GFxSprite`, `GFxFontMap`/`GFxFontLib`, `GFxTextDocView`, `GFxSwfEvent`, `GFxImageLoader`, `GFxResource`, `GFx_DefineBitsJpeg2Loader`, `GFx_InflateWrapper`, etc. Driven from script via `LoadFont` (3929), `LoadTexture` (3931), `SetFlashSwfFile` (3979), `CreateFlashWidget` (3980), `SetPlayerPDAWidget` (3981).

### Minimap (`.rdata`)

| Offset | Symbol |
|---|---|
| 0x0027f68 | `MinimapCreate` |
| 0x0027e14 | `MinimapDelete` |
| 0x0027f58 | `MinimapUpdate` |
| 0x0027eb4 | `MinimapAddObjective` |
| 0x0027e24 | `MinimapRemoveObjective` |
| 0x0027e3c | `MinimapUnanimateObjective` |
| 0x0027f00 | `MinimapSetRange` |
| 0x0027f10 | `MinimapSetRotation` |
| 0x0027f24 | `MinimapSetFocusLocation` |
| 0x0027f3c | `MinimapSetPlayerLocation` |

String-only siblings (not in inventory): `MinimapAnimateObjectiveSonar`, `MinimapAnimateObjectiveAlpha`, `MinimapAnimateObjectiveSize` (strings 3985–3987), `Minimap_Background` (5241), bare `Minimap` (5244).

### PDA map & blips (string-only)

The PDA map is the full-screen tactical map. Script API: `SetPDAMapMode`, `RequestPDAMapModeExit`, `RequestPDAMapModeCancel`, `SetPDAMapModeCallback`, `SetPDAMapModeCancelCallback` (lines 4522–4526), `TogglePDA` (7429), `IsPdaOnSelect` (3928), `RegisterForPdaUpdate` (3952). Blips: `AddBlip`/`UpdateBlip`/`RemoveBlip` (4064–4066), `AddPdaMapBlips`, `UpdatePdaBlip`, `RemovePdaBlip` (3949–3951), `AddPdaBlipToLocalPlayer`/`DeletePdaBlipForLocalPlayer` (7706/7710). Net-replicated PMC/HQ blips: `SendEvent_AddPmcPdaBlip`/`...RemovePmcPdaBlip`/`...AddHqPdaBlip`/`...RemoveHqPdaBlip` (4149–4152) and `NetSafeAddPmcPdaBlip` etc. (7740–7743). The `Pda.Map:AddBlip{ sName = ('test'..i), ` (515) and `Add PDA Map blips` (632) strings are debug/Lua callers. Tunables `PDAMap_Min_Y` / `PDAMap_Max_Y` (2148/2149) and `PDAMapModeEnable` (2131).

### Markers / blips (Lua-bound, `.rdata` + string)

| Offset | Symbol |
|---|---|
| 0x003ba14 | `MarkerModel` |
| 0x0046f7c | `MarkerGetNameByIndex_World` |

The full world-marker Lua binding table is string-only (`Gui._Marker*` → `_G.Marker.*`, strings 3914–3947): `_MarkerAdd`, `_MarkerAdd3D`, `_MarkerAddDisc`, `_MarkerAddTripwire`, `_MarkerAddOld`, `_MarkerRemove`, `_MarkerSetLocation`, `_MarkerSetColor`, `_MarkerSetScale`, `_MarkerSetFollowGuid`, `_MarkerSetBlipLimit`, `_MarkerPulse`, `_MarkerHaltPulse`. Sizing/visibility tunables: `SetPickupMarkerSize`, `SetPickupMarkerVisibleDistance`, `SetVehicleEntranceMarkerSize`, `SetVehicleEntranceMarkerVisibleDistance`, `SetFactionMarkerSize`, `SetFactionMarkerVisibleDistance` (3905–3913). Objective markers: `SendEvent_AddMarkerObjective`/`SendEvent_RemoveMarkerObjective` (4190/4191), `GetAllTargetMarkerPos` (4461). `MarkerTextureName` (6852).

### Reticle / crosshair (`.rdata` tunables + string)

| Offset | Symbol |
|---|---|
| 0x003ebbc | `ReticleType` |
| 0x003ebc8 | `ReticleHealthType` |
| 0x003eb4c | `ReticlePitchHighest` |
| 0x003eb60 | `ReticlePitchMiddle` |
| 0x003eb74 | `ReticlePitchLowest` |

String-only reticle params: `ReticleTexture` (6914), and the weapon-UI field set `uReticleTexture`, `sReticleType`, `sReticleHealthType`, `bReticleCrosshair`, `nStingerReticleWidth`, `nStingerReticleHeight` (4929–4939) with enum decoders `WeaponUIReticleTypeEnum` / `WeaponUIReticleHealthTypeEnum` (5937/5932). Runtime/script: `GetReticlePosition` (3930), `GetTargetUnderReticle` (4521), `FireFromReticle` (2975), `PlayerReticleUpdate` (7535), `StingerReticleUpdate` (3063, missile-lock reticle).

### Screen effects (full-screen post overlays, `.rdata`)

Seven indexed effect slots (`ScreenEffect0*`..`ScreenEffect6*`), each with `Color`, `DirX`, `DirY`, `Density`, `Speed`, and (string-only) `Texture`; plus a global `ScreenEffectType` selector. Representative offsets:

| Offset | Symbol |
|---|---|
| 0x003c41c | `ScreenEffectType` |
| 0x003c448 | `ScreenEffect0Color` |
| 0x003c49c | `ScreenEffect0Density` |
| 0x003c4b4 | `ScreenEffect0Speed` |
| 0x003c474 | `ScreenEffect0DirY` |
| 0x003c488 | `ScreenEffect0DirX` |
| 0x003c0a4 | `ScreenEffect6Color` |
| 0x003c0f8 | `ScreenEffect6Density` |
| 0x003c110 | `ScreenEffect6Speed` |

(All 36 `ScreenEffect[0-6]*` symbols are in the inventory at 0x003c0a4–0x003c4b4; the per-slot `Texture` variants are string-only, lines 6288–6332.) The direction/density/speed/color parameters indicate scrolling-texture overlays (rain/snow/heat). The PC `FUN_00663890` registrar (see PC decompilation cross-reference) builds these seven slots' defaults.

### Movie / Flash widgets (string-only, backed by `PgMoviePlayerXenon.cpp`)

`CreateMovieWidget`, `SetMovieFile`, `PlayMovie`, `PauseMovie`, `StopMovie`, `GetMovieCurrentFrameNumber`, `SetMovieEndCallback` (3953–3958); sprite control `SetSpriteFrame`, `SetSpriteFrameSize`, `SetSpriteTextureSize`, `AnimateSprite`, `HaltSpriteAnimation` (3960–3964); net-replicated movie show/hide `SendEvent_ShowMovie`/`SendEvent_HideMovie` (4172/4171), `NetClientShowMovie`/`NetClientHideMovie`/`NetClientIsMovieRunning`/`NetClientIsMovieHiding` (7753–7756). `.bik` (Bink) playback path `^<@%s\%s.bik` (7796) and YUV plane names `Movie%1dTexY%1d`/`Movie%1dTexU%1d` (7797/7798).

### Screenshot & misc

- `ScreenShot` — inventory `0x0027074 .rdata` (string 3890, under `Graphics`).
- `Toggle HUD` (724), `hudmsg` (7697) — debug HUD message channel.

### GUID utilities (`.rdata` + data)

These resolve object handles used by markers/blips/follow-targets:

| Offset | Symbol | Section |
|---|---|---|
| 0x002c848 | `GuidToString` | .rdata |
| 0x0b8a5b8 | `GuidMap` | .data |

String-only: `StringToGuid` (4694), `Guid: 0x%08x` (1077), `Guid 0x%x is not a path` (4425). `_MarkerSetFollowGuid` ties a marker to a GUID, and marker/blip targeting keys off these GUID helpers.

## Notable strings

GFx loader asserts / error messages (literal text):

- `Error: GFxLoader read failed - no ExporterInfo tag in GFX file header`
- `Error: GFxLoader read failed - incompatible GFX file, version 2.x expected`
- `Error: GFxLoader read failed - file does not start with a SWF header`
- `Error: GFxLoader failed to open '%s', GFxFileOpener not installed`
- `Import error: Font '%s' not found in GFxFontMap or GFxFontLib`
- `Import error: Font '%s' mapped to '%s'%s not found in GFxFontLib`
- `GFxTextDocView::Format() - missing glyph %d. Make sure that SWF file includes character shapes for "%s" font.`
- `GFxSprite::AddDisplayObject(): unknown cid = %d`
- `Error: GFxSwfEvent::Read - EventLength = %d, but read %d`
- `Could not load user image "%s" - GFxImageLoader failed or not specified`
- `Warning: GFxLoader - GFxStream-end tag hit, but not at the end of the file yet; stopping for safety`

Font/movie assets: `gfxfontlib.swf` (13307). Render/profiler scopes: `PgGui::BeginFrame`, `GUI::Render`, `GuiMarkers::Render`, `Render::ApplyFilters`. Perf counters: `Scaleform lines    : %d`, `Scaleform triangles: %d`, `Show Scaleform Stats`, `Scaleform cache cleanup`.

Tunables / parameters (literal names): `ReticleType`, `ReticleHealthType`, `ReticlePitchHighest/Middle/Lowest`, `ReticleTexture`, `bReticleCrosshair`, `nStingerReticleWidth`, `nStingerReticleHeight`; `ScreenEffectType` and per-slot `ScreenEffect[0-6]{Color,DirX,DirY,Density,Speed,Texture}`; marker sizing `Set{Pickup,VehicleEntrance,Faction}Marker{Size,VisibleDistance}`; `_MarkerSetBlipLimit`; `PDAMap_Min_Y`/`PDAMap_Max_Y`; `MinimapSetRange`/`MinimapSetRotation`. Debug toggles: `Toggle HUD`, `Switch PDAMap Mode` (834), `Add PDA Map blips`.

## PC decompilation cross-reference

This maps this system's Xbox `Mercs2_Xenon_P.exe` symbols to functions in the PC retail decomp (`output/_ghidra/all_functions_decomp.txt`). For GUI/HUD the bridge is thin: the resolver (`output/jul08_prototype/pairing/resolved_gui-hud.txt`) found **no vtable resolutions** (consistent with this system having zero emitted RTTI — see Evidence & confidence) and **one string-anchored function**. PC retail is a release build that stripped most of the `Gui*`/`Marker*`/`Pda*` debug strings, so the Scaleform/GFx and Lua-bus symbols do not anchor to named functions.

| Symbol / class | PC function | Bridge | Role |
|---|---|---|---|
| `ScreenEffectType` | `FUN_00663890` | string | tunable/default-table registrar (references `ScreenEffectType` + `SCREEN_EFFECT_ADDITIVE`) |

`FUN_00663890` (size 4451, no callers in the dump — a startup/registration table builder) repeats a config-registration pattern: it loads a value into a local, then calls a setter. `FUN_00656210`/`FUN_00656320` register a plain field and advance; `FUN_00656720(s_ScreenEffectType_00bcb9e8)` registers an **enum-typed** field. The screen-effect block repeats seven times — matching the seven `ScreenEffect0*`..`ScreenEffect6*` slots documented above — each ending in the enum-type registration:

```c
  local_2fc = s_SCREEN_EFFECT_ADDITIVE_00bcb9d0;   // enum value
  FUN_00656720(s_ScreenEffectType_00bcb9e8);        // register "ScreenEffectType" enum field
```

Interspersed constants are the per-slot color/direction/density/speed defaults (e.g. `0xff4c2619`, `0xaa532f19` packed RGBA-ish words, `0x55`/`0xaa`/`0xff` ramps), consistent with the `ScreenEffect[0-6]{Color,DirX,DirY,Density,Speed}` field set. So this is the screen-effect (and adjacent tunable) **schema/default registrar**, not a per-effect method. Confidence: medium — `ScreenEffectType` is a distinctive string and the body corroborates the role, but it is a single anchor with no vtable confirmation.

## Cross-references

- `docs/mercs2-pdb-analysis/rendering-shaders.md` — Scaleform shader programs (`PgScaleform*FP/VP`), `MyFX::BeginFrame`, and the `Render::*` pipeline that the GUI layer renders through.
- `docs/mercs2-pdb-analysis/pangea-engine-core.md` — `Pg*` engine framework hosting `PgGui` and the GUID system (`GuidToString`, `GuidMap`).
- `docs/mercs2-pdb-analysis/world-streaming.md` — minimap/PDA map and markers consume world-object GUIDs (`_MarkerSetFollowGuid`, `MarkerGetNameByIndex_World`).
- `docs/mercs2-pdb-analysis/physics-game.md` / `vehicles.md` — `GuiVehicle*Update`, `GuiSeatMenuEnter`, `GetTargetUnderReticle`, `StingerReticleUpdate` (vehicle/weapon-facing HUD).
- Existing project docs that overlap: `docs/scaleformgfx-cfx-blind-swap` material (memory note on `scaleformgfx` UCFX Minimap/Map assets) and `docs/mercs2-luacd/` (the decompiled base-game Lua that calls `_G.Marker.*`, `Pda.Map:AddBlip`, `Gui.*`).

## Evidence & confidence

- Inventory symbols (copy-exact from `inventory/gui-hud.txt`): 75 lines, all `.rdata` except `GuidMap` (`.data`). Cited offsets above are verbatim from that file.
- Expansion (grep-confirmed in `mercs2_xenon_p.pe_full_strings.txt`): the `Minimap*`, `_Marker*`, `Pda*`/blip, `*Movie*`/widget, `GFx*`, `PgScaleform*`, reticle field, and render-scope strings. Each was grepped before being written.
- Source paths: only `PgMoviePlayerXenon.cpp` is present; no GUI/HUD `.cpp` survives in `source_paths.txt`.
- RTTI: zero GUI/HUD classes in `rtti_classes.txt` (all 324 are Havok). The class names `PgGui`, `GuiMarkers`, `GFxLoader`, `GFxSprite`, `GFxTextDocView`, `GFxSwfEvent` are taken from their own log/assert text, not RTTI.
- PC decomp: only `ScreenEffectType` string-anchors (to `FUN_00663890`); no vtable resolutions, since the system emits no RTTI. See PC decompilation cross-reference.
- Claims not symbol-proven: that the `Gui*` set is a script-callable bus rather than C++ methods; that `ScreenEffect*` slots are scrolling-texture weather/post overlays; that markers/blips key off the GUID helpers; that `PgGui::BeginFrame`/`GUI::Render` are per-frame profiler scopes. Purpose of `MarkerModel` and the exact `ReticlePitch*` semantics are unclear from symbols alone.
- Confidence: HIGH that this subsystem comprises a Scaleform/GFx Flash UI + Lua `Gui*`/`Marker*`/`Pda*` binding layer + minimap + reticle + screen-effect tunables. MODERATE on internal class structure (no RTTI/source to confirm boundaries).
