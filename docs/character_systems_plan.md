# Character Systems Plan

This document describes the C++ gameplay module (`Mercs2Game`) that owns the
runtime character, input, HUD, and weather systems for the Mercenaries 2 UE5
recreation. It replaces the earlier Blueprint-only architecture that relied on
Python editor scripts to author event graphs.

## Architecture: C++ Module (`Mercs2Game`)

The module lives at `UnrealEngineGame/Source/Mercs2Game/` and compiles as the
project's primary game module. All gameplay-critical classes are C++ with
`BlueprintReadWrite` / `BlueprintCallable` exposure so designers can still
tune values and extend behavior in the editor.

### Module file layout

```
Source/
├── Mercs2Game.Target.cs
├── Mercs2GameEditor.Target.cs
└── Mercs2Game/
    ├── Mercs2Game.Build.cs          Module build rules
    ├── Mercs2Game.h                 Log category + API macro
    ├── Mercs2Game.cpp               FDefaultGameModuleImpl
    ├── Mercs2Types.h                Enums (EWeaponStance, EFaction, EWeatherState) + structs
    ├── Mercs2GameMode.h/.cpp        AMercs2GameMode (sets default pawn/PC/HUD)
    ├── Mercs2Character.h/.cpp       AMercs2Character (3P camera, movement, input, state)
    ├── Mercs2PlayerController.h/.cpp AMercs2PlayerController (IMC setup, HUD widget, pause)
    ├── Mercs2AnimInstance.h/.cpp     UMercs2AnimInstance (feeds ABP_Mattias variables)
    ├── Mercs2WeatherController.h/.cpp AMercs2WeatherController (lerp-driven weather states)
    └── Mercs2HUD.h/.cpp             AMercs2HUD (minimal AHUD — debug draw only)
```

### Class responsibilities

| Class | Role |
|-------|------|
| `AMercs2GameMode` | Sets `DefaultPawnClass`, `PlayerControllerClass`, `HUDClass` in constructor. No Blueprint needed. |
| `AMercs2Character` | Third-person character with SpringArm+Camera, Enhanced Input bindings, health/stance/sprint state. Loads Mattias mesh via ConstructorHelpers. |
| `AMercs2PlayerController` | Adds `IMC_Default` mapping context on BeginPlay, creates `WBP_HUDRoot` widget, exposes `TogglePauseMenu()`. |
| `UMercs2AnimInstance` | Native `NativeUpdateAnimation` reads Speed, Direction, crouch/falling/sprint/aim/stance from the owning `AMercs2Character`. Parent class for `ABP_Mattias`. |
| `AMercs2WeatherController` | Actor with references to fog/sun/cloud/PP/rain. Lerps between `FWeatherStateParams` states over configurable duration. Console command `mercs2.weather.set`. |
| `AMercs2HUD` | Placeholder AHUD subclass for future debug overlays. The real HUD is UMG-driven from the controller. |

### Data flow

```
Enhanced Input (IMC_Default)
    │
    ▼
AMercs2Character ─── Health, WeaponStance, bIsSprinting, bIsAiming, Velocity
    │                     │
    │ (reads each tick)   │ (reads each tick)
    ▼                     ▼
UMercs2AnimInstance   WBP_HUDRoot (UMG widget, created by PC)
    │
    ▼
ABP_Mattias Anim Graph (state machine drives blend spaces)
```

## Run order to a playable build

### One-time setup (after first compile)

1. **Compile** — open the project in UE5.7, it detects the Source/ folder and
   compiles `Mercs2Game`. Hot-reload works for subsequent changes.

2. **Create Input Action assets** (10 right-clicks in editor):
   - Right-click in Content Browser → Input → Input Action
   - Create under `/Game/Input/Actions/`:
     `IA_Move` (Value Type: Axis2D),
     `IA_Look` (Value Type: Axis2D),
     `IA_Jump` (Digital/Bool),
     `IA_Sprint` (Digital/Bool),
     `IA_Crouch` (Digital/Bool),
     `IA_Aim` (Digital/Bool),
     `IA_Interact` (Digital/Bool),
     `IA_Fire` (Digital/Bool),
     `IA_SwitchWeapon` (Digital/Bool),
     `IA_OpenPDA` (Digital/Bool)
   - Create `/Game/Input/IMC_Default` (Input Mapping Context)
   - Add all actions to IMC with key bindings:
     - `IA_Move` ← W/A/S/D (with Negate-Y + Swizzle modifiers)
     - `IA_Look` ← Mouse XY 2D-Axis
     - `IA_Jump` ← SpaceBar
     - `IA_Sprint` ← LeftShift
     - `IA_Crouch` ← LeftControl (Pressed trigger)
     - `IA_Interact` ← E
     - `IA_Aim` ← RightMouseButton
     - `IA_Fire` ← LeftMouseButton
     - `IA_SwitchWeapon` ← Q
     - `IA_OpenPDA` ← Tab

3. **Set ABP_Mattias parent class** to `UMercs2AnimInstance`:
   - Open `ABP_Mattias` → Class Settings → Parent Class → `Mercs2AnimInstance`
   - The anim graph now has access to `Speed`, `Direction`, `bIsCrouching`,
     `bIsFalling`, `bIsSprinting`, `bIsAiming`, `bIsDead`, `WeaponStance`
     as native variables — use them in blend space players and transitions.

4. **Build the ABP_Mattias Anim Graph** (visual editor only):
   - Locomotion state machine: Idle/Walk/Run/Sprint blend driven by `Speed`
   - Direction fan-blend using existing `MattiasNilsson_BS` / `Maattias_Rifle_BS`
   - Per-`WeaponStance` switch: Unarmed / Pistol / Rifle / Heavy variants
   - Jump/Falling overlay using `bIsFalling`
   - Death one-shot keyed off `bIsDead`

5. **Press Play** — the `GlobalDefaultGameMode` in DefaultEngine.ini points
   to `AMercs2GameMode`, which spawns `AMercs2Character` with the camera rig
   and input bindings active immediately.

### What C++ handles automatically (no manual wiring)

| Previously manual | Now handled by |
|-------------------|----------------|
| BP_Mattias variables (Health, Sprint, Stance) | `AMercs2Character` UPROPERTY members |
| BP_Mattias mesh transform | `AMercs2Character` constructor (ConstructorHelpers) |
| BP_PlayerController BeginPlay (add IMC, create HUD) | `AMercs2PlayerController::BeginPlay()` |
| BP_PlayerController action callbacks | `AMercs2Character::SetupPlayerInputComponent()` |
| ABP_Mattias EventGraph (copy variables) | `UMercs2AnimInstance::NativeUpdateAnimation()` |
| BP_GameMode setup | `AMercs2GameMode` constructor |
| WBP_HUDRoot creation + viewport add | `AMercs2PlayerController::BeginPlay()` |
| WBP_PauseMenu spawn + pause toggle | `AMercs2PlayerController::TogglePauseMenu()` |
| BP_WeatherController tick logic | `AMercs2WeatherController::Tick()` |
| Weather state lerp + component push | `AMercs2WeatherController::ApplyParams()` |

### What still requires manual editor work

1. **Input Action assets** — C++ references them by soft path but can't create
   `.uasset` DataAssets at compile time. 10 assets + 1 IMC, ~2 minutes.
2. **ABP_Mattias Anim Graph** — the state machine (blend spaces, transitions)
   is visual-only. C++ feeds the variables; the graph consumes them.
3. **WBP_HUDRoot bindings** — the widget tree exists; bind its progress bars
   and text blocks to the owning pawn's C++ properties.
4. **WBP_PauseMenu button handlers** — wire Resume/Quit buttons to the
   controller's `TogglePauseMenu()` and `QuitGame`.

### What stays as Python editor scripts

- `import_world.py` / `import_pmc_base.py` — GLB importing (editor-time only)
- `populate_world.py` / `populate_pmc_base.py` — entity placement (editor-time)
- `setup_project.py` — directory creation, plugin verification
- `setup_terrain_collision.py` — one-time collision setup on imported mesh
- `setup_player_start.py` — spawning the PlayerStart actor
- `setup_atmosphere.py` / `setup_water.py` — one-time actor configuration

## Asset provenance

The Mattias rig and animation set are imported from `MattiasNilssonExport/`
(pre-wired bundle) — the loose `.uasset` files under
`MattiasNilsson/Animations/` are kept only as a fallback if the Export bundle
is missing a take. The C++ character class references the skeletal mesh at
`/Game/Characters/MattiasNilsson/MattiasNilsson` via `ConstructorHelpers`.

The Animation Blueprint `ABP_Mattias` (at `/Game/Characters/Mattias/`) is
reparented to `UMercs2AnimInstance` so it inherits all native variables
without any event-graph copy logic.

## Deferred scope

### Combat

- Hit-scan and projectile weapons, including the long-range mortar /
  airstrike abilities that are central to the Mercenaries fantasy.
- Damage pipeline through `UGameplayStatics::ApplyPointDamage` /
  `ApplyRadialDamage`, with surface and faction modifiers.
- Reload, fire-mode toggle, melee, throwables (frags, smoke, satchel).
- AnimMontage hookup for fire, reload, draw, holster, melee.

### Vehicles

- Vehicle hijack system with `UHijackComponent` + context animations.
- Three driving feel tiers: civilian, military light, military heavy.

### Faction reputation simulation

- `UFactionSubsystem` (UWorldSubsystem) owns global reputation state.
- Per-faction threshold curves drive spawn tables and vendor availability.

### Mission state machine + contract / supply-drop loop

- `UMissionSubsystem` tracks active objectives.
- `UContractAsset` (UPrimaryDataAsset) for contract definitions.
- Supply drop purchasing and airdrop actor spawning.

### Save / load

- `USaveGame`-derived `UMercs2SaveGame` with player state, faction rep,
  mission progress, and world destruction state sections.

### Multiplayer / co-op

- Replication discipline already commented in character class.
- `DOREPLIFETIME` macros ready for the MP pass.

## Weather system

`AMercs2WeatherController` is a level-placed actor that interpolates between
four weather states (Clear, Cloudy, Rainy, Stormy). Each state is defined by
`FWeatherStateParams` which drives fog density/color, sun intensity/temp,
cloud coverage, rain rate, wind speed, and post-process exposure/saturation.

Transitions are time-based lerps (default 5 seconds). The controller pushes
blended values to referenced level actors (ExponentialHeightFog,
DirectionalLight, NiagaraComponent for rain, PostProcessVolume) every tick.

Debug: call `CycleWeatherState()` from a bound key or use the console command
`mercs2.weather.set <Clear|Cloudy|Rainy|Stormy>`.

Future: DataTable-driven params (`DT_WeatherStates`), time-of-day cycle,
hourly weather rolls with state-transition weighting, per-mission overrides.
