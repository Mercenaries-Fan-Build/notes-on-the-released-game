# Main Menu Structure & Option Origins

Analysis of the Mercenaries 2 PC main menu system from binary reverse engineering.

**EXE:** `Mercenaries2.exe` (base 0x00400000, size 0x3302000)
**Key technologies:** Scaleform GFx (Flash UI), Lua 5.1.2, custom widget system

---

## 1. Shell State Machine

### Architecture

The menu system is a **Lua-driven state machine** where:
1. The C++ engine provides `ChangeShellState(state_name)` as a Lua-callable function
2. Lua scripts in `shell.wad` call this function to transition between screens
3. The engine stores the pending state in a static buffer and processes it on the next frame
4. `Sys.FinishedShell` signals that shell loading is complete and gameplay can begin

### ChangeShellState Implementation

| Item | Address | Notes |
|------|---------|-------|
| String `"ChangeShellState"` | `0x00BB6A68` | In .rdata string table |
| C function | `0x005C3740` | LTI callback implementation |
| State buffer | `0x01175F2F` | Static char[] holding pending state name |
| Transition flag | `0x01176034` | Cleared when new state accepted |

**Disassembly of ChangeShellState (0x005C3740):**
```
005C3740  mov ecx, [esp+4]            ; lua_State*
005C3744  push 0x1175F2F              ; dest buffer address
005C3749  call 0x59D730               ; extract string arg → copy to buffer
005C374E  add esp, 4
005C3751  test al, al                 ; extraction succeeded?
005C3753  jnz short 005C375B
005C3755  mov eax, 1                  ; fail: return 1 (Lua error count)
005C375A  ret
005C375B  cmp byte [0x1175F2F], 0     ; buffer already has pending state?
005C3762  jnz short 005C376E          ; if yes, skip (don't overwrite)
005C3764  mov dword [0x1176034], 0    ; clear transition frame counter
005C376E  xor eax, eax                ; return 0
005C3770  ret
```

The function copies the Lua string argument into a fixed buffer. If a state transition is already pending (buffer non-empty), the new request is silently ignored.

### Shell Lifecycle Functions (Sys.* namespace)

| Function | String VA | Func VA | Purpose |
|----------|-----------|---------|---------|
| `Sys.FinishedShell` | `0x00BBA2DC` | `0x005E54C0` | Signal shell complete → enter game |
| `Sys.GetShellCode` | `0x00BBA044` | — | Get current shell state code |
| `Sys.StartSingleplayer` | `0x00BBA0F0` | — | Begin singleplayer game session |
| `Sys.GetForceNewGame` | `0x00BBA030` | — | Check if forced to new game |
| `Sys.PlayIntroMovies` | `0x00BBA148` | — | Play intro movie sequence |
| `Sys.IsFinalConfig` | `0x00BBA0E4` | — | Check if final config step done |
| `Sys.IsDemoMode` | `0x00BBA2C8` | — | Check demo mode flag |
| `Sys.HaveActiveProfile` | `0x00BBA09C` | — | Check if save profile loaded |
| `Sys.AutoLoad` | `0x00BBA2CC` | — | Auto-load last save |
| `Sys.GetLanguage` | `0x00BBA0B8` | — | Get current language string |
| `Sys.RequestGameState` | `0x00BBA218` | — | Request game state transition |

### Shell State Names (found in .rdata)

These strings are arguments to `ChangeShellState()` and represent menu screens/states:

| State String | VA | Purpose |
|-------------|-----|---------|
| `startShell` | `0x00BBC6AC` | Initialize shell, entry point |
| `loadMainShell` | `0x00BB7280` | Load main menu screen |
| `loadPauseMenuVariables` | `0x00BB7290` | Load pause menu variables |
| `newGame` | `0x00BBC5CC` | Start new game flow |
| `joinGame` | `0x00BBC5D4` | Join multiplayer game |
| `quitGame` | `0x00BBC5FC` | Quit game prompt |
| `saveGame` | `0x00BBC5EC` | Save game flow |
| `autoContinue` | `0x00BBC6B8` | Auto-continue from last save |
| `preopComplete` | `0x00BBC5E4` | Pre-operation complete |
| `saveCompleteContinue` | `0x00BBC5A0` | Save complete, continue |
| `overwriteGame` | `0x00BBC5DC` | Overwrite save prompt |
| `onlineError` | `0x00BBC558` | Online error dialog |
| `onlineMessage` | `0x00BBC564` | Online message dialog |
| `onlineErrorClose` | `0x00BBC574` | Close online error |
| `onlineMessageClose` | `0x00BBC588` | Close online message |
| `quitgame_refund` | `0x00BBC5B8` | Quit with refund prompt |
| `clientQuitPrompt` | `0x00BBC618` | Multiplayer client quit |
| `saveProfile` | `0x00BBC608` | Save profile data |

### Menu Flow (inferred from string ordering and callbacks)

```
[Boot] → Sys.PlayIntroMovies → Sys.IsFinalConfig
  ↓
[Press Start] → LTIPressStart → LTIProfileEnter
  ↓
[Profile Select] → ChangeShellState("loadMainShell")
  ↓
[Main Menu] → newGame / joinGame / quitGame / options
  ↓ (newGame)
Sys.StartSingleplayer → Sys.FinishedShell → [Gameplay]
```

---

## 2. Menu Option Origins

### How options are defined

Menu options are **NOT hardcoded in a C++ array**. They originate from **Lua scripts** inside `shell.wad` blocks (specifically precompiled Lua bytecode in `common_P000_Q3.block` or similar). The C++ engine provides:

1. **State transition mechanism** (`ChangeShellState`) — Lua scripts call this to change screens
2. **LTI callbacks** — C functions exposed as Lua globals that handle menu actions
3. **Gui.* widget API** — Lua creates UI widgets (text, images, Flash) programmatically
4. **Gui.CreateFlashWidget / Gui.SetFlashSwfFile** — loads Scaleform .SWF files for rich menus

### Known menu option identifiers (from .rdata strings)

These strings serve as Lua variable/action identifiers for menu items:

| Identifier | VA | Context |
|-----------|-----|---------|
| `newGame` | `0x00BBC5CC` | Main menu "New Game" |
| `joinGame` | `0x00BBC5D4` | Main menu "Join Game" / Co-op |
| `server` | `0x00BBC5DC+` | Server hosting option |
| `quitGame` | `0x00BBC5FC` | Main menu "Quit" |
| `optionsTitle` | `0x00BBC698` | Options menu header |
| `disableLoad` | `0x00BBC640` | Flag to disable Load button |
| `disableManageSaves` | `0x00BBC64C` | Flag to disable save management |
| `disableOnline` | `0x00BBC660` | Flag to disable online features |
| `autoContinue` | `0x00BBC6B8` | "Continue" (auto-load last save) |
| `multiplayerHost` | `0x00BB72E0+` | Host multiplayer match |
| `multiplayerClient` | `0x00BB72F0+` | Join as client |
| `maximumProfiles` | `0x00BB72CC+` | Max profile count |
| `player2Name` | `0x00BB72DC+` | Player 2 name for co-op |
| `FirstRun` | `0x00BB69B4` | First-time launch flag |

### Pause menu states

| State | VA | Purpose |
|-------|-----|---------|
| `pauseOpen` | `0x00BB73B0+` | Open pause menu |
| `pauseSave` | `0x00BB73BC+` | Pause → save game |
| `pauseCancel` | `0x00BB73C8+` | Cancel pause action |

### Options sub-menu states

| State | VA | Category |
|-------|-----|----------|
| `videoEnter` | `0x00BB73D4+` | Enter video options |
| `audioDefaults` | `0x00BB73E4+` | Reset audio to defaults |
| `audioEnter` | `0x00BB73F4+` | Enter audio options |
| `audioApply` | `0x00BB7400+` | Apply audio changes |
| `audioCancel` | `0x00BB740C+` | Cancel audio changes |
| `gameEnter` | `0x00BB7418+` | Enter game options |
| `gameTutorials` | `0x00BB7424+` | Toggle tutorials |
| `gameAutosave` | `0x00BB7434+` | Toggle autosave |
| `gameCancel` | `0x00BB7440+` | Cancel game options |
| `gameApply` | `0x00BB7550+` | Apply game changes |
| `gameAccept` | `0x00BB755C+` | Accept game changes |
| `gameDefaults` | `0x00BB7568+` | Reset game defaults |
| `serverEnter` | `0x00BB7584+` | Enter server options |

---

## 3. Gui.* Lua API (Complete Namespace)

The `Gui` Lua table is registered at runtime. Table name string at `0x00BB5CC4`. Version: `_GuiInternal.nVersion = 2`.

### Widget System (base)

| Function | Purpose |
|----------|---------|
| `CreateWidget` | Create base widget container |
| `DeleteWidget` | Remove widget |
| `SetWidgetLocation` / `GetWidgetLocation` | Position |
| `SetWidgetVisible` / `GetWidgetVisible` | Visibility toggle |
| `SetWidgetColor` / `GetWidgetColor` | RGBA color |
| `SetWidgetSleep` / `GetWidgetSleep` | Sleep/inactive state |
| `ActivateWidget` | Activate for input |
| `PushWidgetToFront` / `PushWidgetToBack` | Z-order |
| `InterpolateWidget` | Animated transitions |
| `SetWidgetAnchoring` / `GetWidgetAnchoring` | Anchor mode |
| `SetWidgetHighlightable` / `GetWidgetHighlightable` | Highlight on focus |
| `SetWidgetFullscreen` | Fullscreen mode |
| `CorrectWidgetForResolution` | Resolution scaling |
| `SetWidgetUseNewRescale` | New rescale mode |
| `SetWidgetUseResolutionCorrection` | Resolution correction |
| `AddWidgetChild` / `RemoveWidgetChild` | Child management |
| `RemoveAllWidgetChildren` | Clear children |
| `GetWidgetChildren` | Enumerate children |
| `SetWidgetViewport` / `GetWidgetViewport` | Viewport rect |
| `SetWidgetUpdateCallback` | Per-frame callback |
| `SetWidgetIgnoresPause` / `GetWidgetIgnoresPause` | Ignore pause |
| `SetWidgetCorrectedLocation` / `GetWidgetCorrectedLocation` | Aspect-corrected pos |
| `GetWidgetDownId` / `GetWidgetHighlightId` | Input navigation |

### Image Widget

| Function | Purpose |
|----------|---------|
| `CreateImageWidget` | Create image display |
| `SetImageTexture` | Set texture asset |
| `SetImageRotation` / `GetImageRotation` | Rotation angle |
| `SetImageTextureCoordinates` / `GetImageTextureCoordinates` | UV rect |
| `SetImageTiling` | Tile mode |
| `SetImageTextureTransience` | Fade transience |
| `SetImageClockAnimation` | Clock-wipe animation |
| `SetImageClockCallback` | Clock completion callback |
| `GetImageClockElapsed` | Clock progress |
| `SetImagePieSliceRender` / `DisableImagePieSliceRender` | Pie chart slice |

### Text Widget

| Function | Purpose |
|----------|---------|
| `CreateTextWidget` | Create text label |
| `SetTextText` / `GetTextText` | Set/get string content |
| `SetTextFont` | Font asset |
| `SetTextWrapping` / `GetTextWrapping` | Word wrap |
| `GetTextWidth` / `GetTextHeight` | Computed dimensions |
| `SetTextJustification` / `GetTextJustification` | Alignment |
| `SetTextScale` / `GetTextScale` | Font scale |
| `SplitText` | Multi-line split |
| `AnimateText` / `HaltTextAnimation` | Text animation |

### Sprite Widget

| Function | Purpose |
|----------|---------|
| `CreateSpriteWidget` | Create animated sprite |
| `SetSpriteTexture` | Sprite sheet texture |
| `SetSpriteTextureSize` | Total sheet size |
| `SetSpriteFrameSize` | Individual frame size |
| `AnimateSprite` / `HaltSpriteAnimation` | Play/stop |
| `SetSpriteFrame` | Set specific frame |

### Flash/Scaleform Widget

| Function | Purpose |
|----------|---------|
| `CreateFlashWidget` | Create Scaleform GFx player |
| `SetFlashSwfFile` | Load .SWF file |
| `PlayFlash` / `PauseFlash` / `RestartFlash` | Playback control |
| `GetFlashPlaySpeed` / `SetFlashPlaySpeed` | Playback speed |
| `SendFlashInput` | Send button/key input to Flash |
| `SendFlashLeftAnalogInput` | Left stick → Flash |
| `SendFlashRightAnalogInput` | Right stick → Flash |
| `SetFlashCallback` | Register C++ callback for Flash events |
| `CallFlashScriptFunction` | Call ActionScript function from Lua |
| `SetFlashPauseMenu` / `RemoveFlashPauseMenu` | Pause menu overlay |
| `SetFlashTesselationAllowed` | Tesselation quality |

### Movie Widget

| Function | Purpose |
|----------|---------|
| `CreateMovieWidget` | Create video player |
| `SetMovieFile` | Set video file |
| `PlayMovie` / `PauseMovie` / `StopMovie` | Playback |
| `SetMovieEndCallback` | End-of-movie callback |
| `GetMovieCurrentFrameNumber` | Current frame |

### Minimap

| Function | Purpose |
|----------|---------|
| `MinimapCreate` / `MinimapDelete` | Create/destroy |
| `MinimapUpdate` | Refresh display |
| `MinimapSetPlayerLocation` | Player position |
| `MinimapSetFocusLocation` | Camera focus |
| `MinimapSetRotation` / `MinimapSetRange` | View params |
| `SetMinimapOwner` / `SetMinimapBorder` / `SetMinimapRadius` | Config |
| `MinimapAddObjective` / `MinimapRemoveObjective` | Objectives |
| `MinimapAnimateObjectiveSize/Alpha/Sonar` | Objective animation |
| `MinimapUnanimateObjective` | Stop animation |

### PDA / Markers

| Function | Purpose |
|----------|---------|
| `AddPdaMapBlips` / `UpdatePdaBlip` / `RemovePdaBlip` | PDA map markers |
| `RegisterForPdaUpdate` | PDA update subscription |
| `SetPlayerPDAWidget` | PDA UI widget |
| `_MarkerAdd` / `_MarkerAddOld` / `_MarkerAdd3D` | World markers |
| `_MarkerAddTripwire` / `_MarkerAddDisc` | Specialized markers |
| `_MarkerRemove` | Remove marker |
| `_MarkerSetLocation` / `_MarkerSetColor` / `_MarkerSetScale` | Marker props |
| `_MarkerSetFollowGuid` | Follow entity |
| `_MarkerSetBlipLimit` | Grouped blip limit |
| `_MarkerPulse` / `_MarkerHaltPulse` | Pulse animation |
| `EnableFactionMarkers` / `SetFactionMarkerSize` | Faction markers |
| `SetFactionMarkerVisibleDistance` | Faction range |
| `SetVehicleEntranceMarkerVisibleDistance` | Vehicle marker range |

### Other Gui Functions

| Function | Purpose |
|----------|---------|
| `AddObjective` | HUD objective display |
| `LoadTexture` | Load texture asset |
| `LoadFont` | Load font asset |
| `GetReticlePosition` | Crosshair screen pos |
| `IsPdaOnSelect` | PDA selection state |
| `IsXboxController` | Controller type check |
| `ControllerInUse` | Any controller active |
| `FindGuiLocation` | Widget location lookup |
| `doneLoadingFlash` | Flash load complete signal |
| `AddBlip` / `UpdateBlip` / `RemoveBlip` | Generic blip system |

### Marker Alias Table (embedded Lua at ~0x00BB5A00)

The EXE contains embedded Lua code that creates `_G.Marker` as an alias table:

```lua
_G.Marker                    = {}
_G.Marker.Add                = Gui._MarkerAddOld
_G.Marker.AddBlip            = Gui._MarkerAdd
_G.Marker.AddTripwire        = Gui._MarkerAddTripwire
_G.Marker.AddDisc            = Gui._MarkerAddDisc
_G.Marker.Add3D              = Gui._MarkerAdd3D
_G.Marker.Remove             = Gui._MarkerRemove
_G.Marker.SetGroupedBlipLimit = Gui._MarkerSetBlipLimit
_G.Marker.SetLocation        = Gui._MarkerSetLocation
_G.Marker.SetColor           = Gui._MarkerSetColor
_G.Marker.SetFollowGuid      = Gui._MarkerSetFollowGuid
_G.Marker.SetScale           = Gui._MarkerSetScale
_G.Marker.Pulse              = Gui._MarkerPulse
_G.Marker.HaltPulse          = Gui._MarkerHaltPulse
```

---

## 4. Scaleform GFx ↔ Engine Integration

### GFx Exports (from mercenaries2.exe symbol table)

The EXE exports 63 Scaleform GFx class methods. The SDK is **GFx 2.0.48** — proven by the
`gfxVersion` ActionScript property returning the literal `"2.0.48"` (FUN_007676d0 in the unpacked
decomp), the loader error string `"incompatible GFX file, version 2.x expected"`, and the AS2-only
built-in class table (Flash 8, `$version` = `"WIN 8,0,0,0"`). (An earlier revision of this doc said
"confirmed GFx 3.x SDK" — wrong: GFx 3.0 shipped in 2009, after this game.)

| Class | Key Methods | Notes |
|-------|-------------|-------|
| `GFxLoader` | `~GFxLoader` (RVA 0x379740) | Flash movie loader/player |
| `GImage` | ctor, copy ctor, dtor (RVA 0x376B50+) | Texture/bitmap handling |
| `GMatrix2D` | Transform, Inverse, Lerp, Swap (RVA 0x35F770+) | 2D transform matrices |
| `GZLibFile` | Read, Seek, GetLength, CopyFromStream (RVA 0x3FD9D0+) | ZLib-compressed SWF loading |
| `GColor` | SetHSV, GetHSV, Blend (RVA 0x406240+) | Color manipulation |
| `GRefCountBaseImpl` | ctor, dtor, SetRefCountMode (RVA 0x35F430+) | Ref-counted base for GFx objects |

### Error Strings

| String | VA | Context |
|--------|-----|---------|
| `"Error: GFxLoader failed to open '%s'\n"` | `0x00BD977E` | SWF file open failure |
| `"Error: GFxLoader failed to open '%s', GFxFileOpener not installed\n"` | `0x00BD97A4` | Missing file opener |

### ActionScript Built-in Classes (string table at ~0xBDD800)

Found in .rdata, these are the ActionScript classes supported by the embedded GFx runtime:

- `ExternalInterface` (VA `0x00BDD844`) — Flash → C++ communication
- `MovieClipLoader` — async SWF loading
- `MovieClip` — display object base
- `TextField` — text input/display
- `Math`, `XML`, `XMLSocket` — standard AS2 classes
- `Stage`, `Selection`, `AsBroadcaster` — event system
- `Array`, `Number`, `Boolean`, `Function` — primitives
- `BitmapData`, `ColorTransform`, `Rectangle`, `Matrix` — rendering
- `TextFormat`, `LoadVars` — text/network

### Flash Display Properties (string table at ~0xBD9B00)

Standard Flash MovieClip/TextField properties handled by GFx:
- `_alpha`, `_currentframe`, `_totalframes`, `_name`, `_target`
- `_xmouse`, `_ymouse`, `_parent`, `_quality`, `_url`
- `blendMode`, `cacheAsBitmap`, `filters`, `tabEnabled`
- `text`, `textColor`, `htmlText`, `autoSize`, `wordWrap`
- `shadowColor`, `shadowStyle`, `shadowDistance`, `shadowAngle`

### Flash Blend Modes (at ~0xBD9900)

`normal`, `multiply`, `screen`, `lighten`, `darken`, `difference`, `subtract`, `invert`, `overlay`, `hardlight`, `erase`

### Integration Flow: Lua → GFx → Lua

```
[Lua Script]                    [C++ Engine]                    [Scaleform GFx]
     |                               |                               |
     |-- Gui.CreateFlashWidget() --->|                               |
     |-- Gui.SetFlashSwfFile(swf) -->|-- GFxLoader::OpenMovie() --->|
     |-- Gui.PlayFlash() ----------->|-- GFxMovieView::Advance() -->|
     |                               |                               |
     |-- Gui.SetFlashCallback(fn) -->|  (registers Lua fn)          |
     |                               |<-- ExternalInterface.call() --|
     |<-- callback(args) ------------|                               |
     |                               |                               |
     |-- Gui.CallFlashScriptFunction(name, args) -->|               |
     |                               |-- Invoke(name, args) ------->|
     |                               |                               |
     |-- Gui.SendFlashInput(btn) --->|-- ProcessInput() ----------->|
```

---

## 5. LTI Callback Functions

The LTI system provides C++ callbacks registered in the Lua global namespace. These are called directly by the shell Lua scripts to perform engine operations.

> **Expansion removed 2026-07-26.** This heading previously read **"LTI (Lua To Interface)"**. That
> expansion has no support in any primary source: 172 `LTI*` strings in the image and not one
> spelling it out, and it is absent from all 67+ shipped `.gfx`, the Xbox PDB corpus
> (`docs/mercs2-pdb-analysis/`) and `Saboteur.exe`. What the binary *does* show is 16 source paths
> under `D:\Projects\Mercs2_PC\mercs2\LTI\Src\` and the namespace `LtiRender::RenderSystem::` — LTI
> is the PC render/platform layer, and the Lua table is literally named `LTILibName`. The acronym is
> **not determinable** from anything we hold; it is left unexpanded rather than guessed.
> See `docs/reverse_engineer/lti_movie_pda_code_map.md`.

### Registration Table

Located at `0x00B99D00` in .rdata. Format: array of `{const char* name, lua_CFunction func}` pairs (8 bytes each), NULL-terminated.

### Shell/Menu LTI Functions

| Function Name | String VA | Func VA | Purpose |
|--------------|-----------|---------|---------|
| `ChangeShellState` | `0x00BB6A68` | `0x005C3740` | Transition shell state |
| `LTIPressStart` | `0x00BB7264` | — | "Press Start" input received |
| `LTIProfileEnter` | `0x00BB6A58` | — | Enter profile selection |
| `LTIProfileExit` | `0x00BB6A4C` | — | Exit profile selection |
| `LTIProfileOnlinePlay` | `0x00BBC520` | — | Start online play from profile |
| `LTIgotoGame` | `0x00BBC510` | — | Transition from shell to game |
| `LTIGetStartButton` | `0x00BB6A7C` | — | Get start button state |
| `LTIPrecacheDone` | `0x00BB6A00` | — | Precache loading complete |
| `LTIPrecacheSmokeDone` | `0x00BB69EC` | — | Smoke precache complete |
| `LTIChoseOnline` | `0x00BB69DC` | — | Online mode selected |
| `LTIPauseItemChanged` | `0x00BB69C4` | — | Pause menu item changed |
| `LTICamera` | `0x00BB69A4` | — | Camera control from menu |
| `LTIAllowFlashMouse` | `0x00BBC59C` | — | Enable Flash mouse input |
| `AdvAccept` | `0x00BB7274` | — | Advertisement accept |
| `FirstRun` | `0x00BB69B4` | — | First-run initialization |

### Video Options LTI Functions

| Function | Purpose |
|----------|---------|
| `LTIVideoAdvanceDefault` | Reset advanced video |
| `LTIVideoAdvanceEnter` | Enter advanced video |
| `LTIVideoSwitchOpt1` | Switch video option |
| `LTIVideoCancel` / `LTIVideoDefault` | Cancel/reset video |
| `LTIVideoApplyChanges` | Apply video settings |
| `LTIVideoGetViewDistance` | Get view distance |
| `LTIVideoSetGamma` | Set gamma value |
| `LTIVideoPrevRefresh` / `LTIVideoNextRefresh` | Cycle refresh rate |
| `LTIVideoPrevRes` / `LTIVideoNextRes` | Cycle resolution |
| `LTIVideoSwitchMode` | Toggle windowed/fullscreen |
| `LTIVideoEnter` | Enter video options |
| `LTIVideoSetResolution2` | Set resolution (v2) |
| `LTIVideoSetRefresh2` | Set refresh (v2) |
| `LTIVideoDetail` | Set detail level |
| `LTIVideoSetVsync` | Set VSync |
| `LTIVideoSetSwitchOpt1..8` | Set toggle options |
| `LTIVideoDisableHighShaders` | Disable high shaders |
| `LTIVideoSetMode` | Set display mode |
| `LTIVideoSetRes` / `LTIVideoSetRefresh` | Set res/refresh |
| `LTIVideoSetVideoViewDistance` | Set view distance |
| `LTISetGraphicDetail` | Set overall quality |
| `LTIvideoSubtitles` | Toggle subtitles |

### Audio Options LTI Functions

| Function | Purpose |
|----------|---------|
| `LTIAudioSFXVolume` | Set SFX volume |
| `LTIAudioMusicVolume` | Set music volume |
| `LTIAudioDialogVolume` | Set dialog volume |
| `LTIAudioInVoiceVolume` | Set voice-in volume |
| `LTIAudioOutVoiceVolume` | Set voice-out volume |

### Input Options LTI Functions

| Function | Purpose |
|----------|---------|
| `LTIInputGeneralRumble` | Toggle rumble |
| `LTIInputGeneralJoySense` | Joystick sensitivity |
| `LTIInputGeneralMouseSense` | Mouse sensitivity |
| `LTIInputGeneralInvertMouse` | Invert mouse |
| `LTIInputGeneralOptions` | General input options |
| `LTIInputGeneralEnter` | Enter input settings |
| `LTIInputJoystickEnter` / `Exit` / `Default` | Joystick config |
| `LTIInputJoystickApplyChanges` / `Cancel` | Joystick apply/cancel |
| `LTIInputJoystickChangeInput` / `ChangePrimary` | Remap |
| `LTIInputKMEnter` / `Exit` / `Default` | Keyboard/mouse config |
| `LTIInputKMApplyChanges` / `CancelInput` | KB/M apply/cancel |
| `LTIInputKMChangeInput` | Remap keyboard |
| `LTIInputSetMouseSense` / `SetJoySense` | Set sensitivity |
| `LTIInputSetInvertJoystick` / `SetInvertMouse` | Invert axis |
| `LTIInputSetRumble` | Set rumble on/off |
| `LTIInputNumberControllers` | Get controller count |
| `LTIInputMaxActionBind` | Max bindable actions |
| `LTIInputKMSetActionName` / `KMKeyMap` | Key mapping |
| `LTIInputKMUpdateTable` | Refresh bindings display |
| `LTIInputControllerNames` | Get controller names |
| `LTIInputJoystickMap` / `JoystickUpdateTable` | Joy mapping |
| `LTIInputSeeButtonsPushed` | Debug: show inputs |
| `LTIJoystickOverBoundResponse` / `LTIOverBoundResponse` | Axis overflow |

### Game Options LTI Functions

| Function | Purpose |
|----------|---------|
| `LTIGameSetAutosave` | Toggle autosave |
| `LTIGameSetTutorial` | Toggle tutorials |
| `LTIGameSensitivity` | Game sensitivity |
| `LTIControlsMouseInvert` | Invert mouse in-game |

### Movie LTI Functions

| Function | Purpose |
|----------|---------|
| `LTIMovieStart` / `LTIMovieStop` | Start/stop movie playback |
| `LTIMoviePause` / `LTIMovieResume` | Pause/resume |

### Multiplayer LTI Functions

| Function | Purpose |
|----------|---------|
| `LTIServerOnline` | Check server online status |
| `LTIServerAccept` | Accept server connection |
| `LTIonlineMsgBox` | Show online message box |

---

## 6. Options Variable Strings

These strings are Lua variable names used to store and display settings values:

### Video Variables
`videoModeVar`, `videoGammaVar`, `videoAntiAliasLevel`, `videoNextAntiAliasLevel`, `videoPrevAntiAliasLevel`, `VSyncOn`, `VSyncOff`, `videoVsyncVar`, `videoVideoDetailVar`, `videoViewDistance`, `videoShaderSetting`

### Advanced Video Variables
`advvideo1Var`, `advvideoSkyDetailVar`, `advvideoWaterDetailVar`, `advvideoEnableShadowsVar`, `advvideoTreeShadowsVar`, `advvideoModelShadowsVar`, `advvideoParticleVar`, `advvideoShaderVar`, `advvideoMotionblurVar`

### Audio Variables
`audioSFXVolumeVar`, `audioMusicVolumeVar`, `audioDialogVolumeVar`, `audioInVoiceVolumeVar`, `audioOutVoiceVolumeVar`

### Controls Variables
`controlsMouseInvertVar`, `controlsMouseSensVar`, `controlsJoySensVar`

### Game Variables
`gameInvertVar`, `gameSensitivityVar`, `gameRumbleVar`, `gameTutorialsVar`, `gameSubtitleVar`, `gameAutoSaveVar`, `serverFriendlyFireVar`

### Rendering Quality Strings
`AntiAliasText`, `Render`, `WaterDetail`, `SkyDetail`, `EnableShadows`, `ModelDetailLevel`, `ParticleDetailLevel`, `EnableWaterEffects`

---

## 7. Net.* Namespace

Table name `"Net"` at `0x00BB8154`.

### Known Functions (from strings at ~0xBB7F50)

| Function | Purpose |
|----------|---------|
| `IsMultiplayer` | Check multiplayer active |
| `IsConnectedToInternet` | Internet connectivity |
| `IsPlatformConnected` | Platform service connected |
| `IsEnabled` / `IsActive` | Network enabled/active |
| `IsLobby` / `IsClient` / `IsServer` | Role check |
| `IsDedicated` | Dedicated server check |
| `IsMatchmakingInternet` | Internet matchmaking |
| `IsOnlineConnected` / `IsOnlineEnabled` | Online status |
| `ShouldPlayOnline` | Online preference |
| `AutoLobby` / `AutoClient` / `AutoServer` | Auto-connect |
| `GetHostName` | Get host name |
| `EnterLobby` | Enter lobby |
| `ResetServerList` | Refresh server list |
| `ConnectToServer` | Connect to server |
| `StartServer` | Host new server |
| `QuitGame` | Network quit |
| `EnterFriendsLobby` / `ExitFriendsLobby` | Friends system |
| `DialogBoxPlayLocal` | Play local dialog |
| `DialogBoxPlayOffline` | Play offline dialog |
| `DialogBoxMustBeSignInToLive` | Xbox Live sign-in prompt |

---

## 8. Configuration / Platform Setup

Found at ~0xBBC700:

| Function/String | Purpose |
|----------------|---------|
| `setPlatform` | Set platform (value: "US", "Europe", "Other") |
| `setRegion` | Set region code |
| `setTerritory` | Set territory ("SP", "IT", "FR", "GR", "RU", "EN") |
| `confirmButtonReversed` | Japanese-style confirm (Circle=confirm) |
| `leftAnalog` / `rightAnalog` | Analog stick config |

---

## 9. Summary: Where Main Menu Options Come From

The main menu options in Mercenaries 2 originate from a **three-layer architecture**:

1. **Lua scripts** (in `shell.wad` blocks as precompiled bytecode):
   - Define menu screens, button layouts, transitions
   - Call `ChangeShellState("newGame")` etc. when player selects options
   - Create widgets via `Gui.CreateTextWidget`, `Gui.CreateFlashWidget`

2. **C++ LTI callbacks** (registered in binding tables at ~0xB99D00):
   - Execute engine-side logic (apply settings, start game, etc.)
   - Return values to Lua (current settings, platform info, etc.)

3. **Scaleform GFx Flash** (.SWF files loaded via `Gui.SetFlashSwfFile`):
   - Provide rich animated menu backgrounds and overlays
   - Communicate back via `ExternalInterface` → `SetFlashCallback`
   - Receive input via `Gui.SendFlashInput`

The menu system is **data-driven through Lua** — the EXE contains no hardcoded menu layout. It provides the infrastructure (widget system, state machine, Scaleform integration) while the actual menu structure lives in the precompiled Lua scripts within `shell.wad`.
