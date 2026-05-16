# Character Systems Plan

This document captures the design and architecture for the playable character,
camera, input, and HUD pass introduced by the `setup_player_character.py`,
`setup_player_controller.py`, `setup_basic_hud.py`, and `setup_data_structs.py`
Editor Python scripts. It also lays out the scope deferred to a later
combat-logic pass.

## Run order to a playable build

Run these `game-scripts/` scripts in this order via UE5 Editor
**Tools → Execute Python Script**. After step 5 the level is configured;
step 6 is a read-only pass/fail report.

1. `setup_data_structs.py` — creates `EWeaponStance` / `EFaction` enums,
   `FFactionReputation` / `FWeaponData` / `FMissionObjective` structs, and
   `DT_WeaponData` / `DT_TutorialMission` data table shells under
   `/Game/Mercs2/Data`.
2. `setup_player_character.py` — stages `MattiasNilssonExport/` into
   `Content/Characters/MattiasNilsson/`, then authors `BP_Mattias`
   (Character) and `ABP_Mattias` (AnimBlueprint shell) under
   `/Game/Characters/Mattias`, with mesh, spring-arm + camera, and
   `CharacterMovement` defaults.
3. `setup_player_controller.py` — creates Enhanced Input actions and
   `IMC_Default`, `BP_PlayerController`, `BP_GameMode` (DefaultPawn =
   `BP_Mattias`, PlayerController = `BP_PlayerController`), and writes the
   GameMode override into the open level's `WorldSettings`.
4. `setup_basic_hud.py` — builds the `WBP_HUDRoot` and `WBP_PauseMenu` UMG
   widget trees under `/Game/UI/HUD`.
5. `setup_terrain_collision.py` — flips the merged `Mercs2_LowResTerrain`
   static mesh to `UseComplexAsSimple` and sets the actor's
   `StaticMeshComponent` to the `BlockAll` profile so the player walks on
   the actual mesh surface.
6. `setup_player_start.py` — picks a coastal landmark (parque_central /
   pmc / airport / dock / barrancas / fortin) within the 0–50 m elevation
   band, line-traces from +600 m down to find the terrain surface, and
   spawns or moves a single `PlayerStart` to that location facing the map
   centre.
7. `verify_player_setup.py` — read-only smoke test. Prints a pass/fail
   table and writes `output/player_setup_verification.json`.

Prerequisite (one-time): run `import_world.py` and `populate_world.py`
first so the merged terrain actor `Mercs2_LowResTerrain` exists in the
level. Re-running the setup scripts is safe — every step is idempotent.

### Manual editor follow-ups (Python-unreachable in 5.7)

UE 5.7's Editor Python API can't author Anim Graph state machines, write
into Blueprint event graphs, mutate Input Mapping Context entries, or wire
UMG bindings. After running the scripts above, the following must be done
by hand. `verify_player_setup.py` re-emits this list with the same
numbering.

1. **`ABP_Mattias` Anim Graph** — build the locomotion state machine
   (Idle/Walk/Run/Sprint blend driven by `Speed`; `Direction` fan-blend to
   forward/forward-left/left/backward-left/.../forward-right takes;
   per-`WeaponStance` switch with Unarmed / Pistol / Rifle / Heavy
   variants; Jump/Falling overlay; Death oneshot keyed off
   `DeathDirection`).
2. **`ABP_Mattias` Event Graph** — on `Update Animation`, read the owning
   Pawn each tick and copy `Speed = Velocity.Size2D`,
   `Direction = CalculateDirection(Velocity, Rotation)`, and the
   `bIs*` / `WeaponStance` state into the AnimBP variables.
3. **`BP_Mattias` variables** — add `Health` (float, 100), `MaxHealth`
   (float, 100), `bIsSprinting` (bool), `WeaponStance` (`EWeaponStance`),
   `FactionReputation` (`Map<EFaction, float>`).
4. **`BP_Mattias` mesh transform sanity-check** — confirm the
   `SkeletalMeshComponent` is offset by ≈-90 cm Z and rotated -90° yaw so
   feet sit on the capsule base; tweak in the Components panel if the
   character intersects the floor or floats.
5. **`BP_PlayerController` variable** — add `DefaultMappingContext`
   (`InputMappingContext`) defaulted to `/Game/Input/IMC_Default`.
6. **`BP_PlayerController` BeginPlay** — get the Enhanced Input Local
   Player Subsystem from this controller, `AddMappingContext(DefaultMappingContext, 0)`,
   then `Create Widget(WBP_HUDRoot)` → `AddToViewport`.
7. **`BP_PlayerController` action callbacks** — bind
   `IA_Move/Look/Jump/Sprint/Crouch/Aim/Interact/Fire/SwitchWeapon/OpenPDA`
   and forward to the possessed pawn (cast to `BP_Mattias`). Crouch is
   toggle-on-press.
8. **`IMC_Default` key chords** — open the IMC asset and add `IA_Move ←
   W/A/S/D` (with the Negate / Swizzle modifiers documented in
   `setup_player_controller.py`), `IA_Look ← Mouse XY 2D-Axis`,
   `IA_Jump ← SpaceBar`, `IA_Sprint ← LeftShift`,
   `IA_Crouch ← LeftControl` (Pressed trigger), `IA_Interact ← E`,
   `IA_Aim ← RightMouseButton`, `IA_Fire ← LeftMouseButton`,
   `IA_SwitchWeapon ← Q + MouseWheelAxis`, `IA_OpenPDA ← Tab`.
9. **`WBP_HUDRoot` bindings** — `HealthBar.Percent ← Health/MaxHealth`,
   `AmmoText.Text ← format CurrentMag/ReserveAmmo`,
   `WeaponNameText.Text ← CurrentWeapon.Name`,
   `ObjectiveText.Text ← CurrentObjective summary`,
   `Crosshair.Visibility ← bIsAiming ? Visible : Hidden`,
   `FactionBar_<Faction>.Percent ← (FactionReputation[<Faction>]+100)/200`.
10. **`WBP_PauseMenu` button handlers** — Resume → `SetPaused(false)` +
    `RemoveFromParent` + `InputMode=GameOnly`; Save / Load / Settings →
    stub log; Quit → `QuitGame`. From `BP_PlayerController` on ESC:
    `Create Widget(WBP_PauseMenu)` + `AddToViewport` + `SetPaused(true)` +
    `InputMode=UIOnly` + `ShowMouseCursor`.

After those ten manual items: press Play, walk onto the terrain, jump,
crouch-toggle, sprint, and the HUD shows live health.

## Asset provenance

The Mattias rig and animation set are imported from `MattiasNilssonExport/`
(pre-wired bundle) — the loose `.uasset` files under `MattiasNilsson/Animations/`
are kept only as a fallback if the Export bundle is missing a take. The Export
folder contains `.uasset` files saved against the internal package path
`/Game/Characters/MattiasNilsson/...`, so `setup_player_character.py` copies
the bundle verbatim into `UnrealEngineGame/Content/Characters/MattiasNilsson/`
to preserve the existing cross-references between skeleton, mesh, materials,
animations, and blend spaces. The Animation Blueprint and Character Blueprint
are authored on top, in a separate `/Game/Characters/Mattias/` namespace, so
the imported source assets and the project-authored gameplay assets are easy
to tell apart.

## Current scope (this pass)

What the four setup scripts deliver, end to end:

- **Player character** — `BP_Mattias` (derives from `ACharacter`), with the
  Mattias skeletal mesh, `ABP_Mattias` Animation Blueprint shell, a third-person
  spring-arm + camera rig (target arm length 300 cm, socket Z offset 60 cm),
  and `UCharacterMovementComponent` defaults tuned for the desired
  walk / run / sprint / crouch speeds and a 600 cm/s jump.
- **Animation Blueprint scaffolding** — `ABP_Mattias` is created and bound to
  the Mattias skeleton. The state machine (locomotion blend space, stance,
  weapon stance, jump/falling overlay, death one-shot) is described in detail
  in the script's manual-steps log because UE 5.7's Python API cannot author
  Anim Graph nodes. The blend space assets shipped in `MattiasNilssonExport/`
  (`MattiasNilsson_BS`, `Maattias_Rifle_BS`, `Crouching_BS`) are reused.
- **Enhanced Input** — `IA_Move`, `IA_Look`, `IA_Jump`, `IA_Sprint`,
  `IA_Crouch`, `IA_Interact`, `IA_Aim`, `IA_Fire`, `IA_SwitchWeapon`,
  `IA_OpenPDA` under `/Game/Input/Actions`, with a single
  `IMC_Default` mapping context at `/Game/Input/IMC_Default`. Key bindings
  are logged for manual entry because the IMC entry mutation API is not
  exposed to Python in 5.7.
- **Player controller + GameMode** — `BP_PlayerController` and `BP_GameMode`
  under `/Game/Characters/Mattias/`. GameMode is wired with the BP_Mattias
  default pawn and BP_PlayerController, then assigned to the currently
  open level via `AWorldSettings::DefaultGameMode` (no `DefaultEngine.ini`
  edits).
- **HUD** — `WBP_HUDRoot` (bottom-left vertical health bar, bottom-right
  ammo/weapon block, top-left minimap placeholder, top-right per-faction
  reputation bars, bottom-center objective tracker, hidden-by-default
  centered crosshair) and `WBP_PauseMenu` (Resume, Save, Load, Settings,
  Quit) — both under `/Game/UI/HUD/`. The widget *tree* is created by
  Python; bindings and click handlers are listed as manual follow-ups.
- **Gameplay data** — `EWeaponStance`, `EFaction` enums; `FFactionReputation`,
  `FWeaponData`, `FMissionObjective` structs; `DT_WeaponData` and
  `DT_TutorialMission` data table shells. The canonical schema is also
  written to `docs/data/mercs2_data_schema.json` for the row contents so
  the editor steps and tests can reference a single source of truth.

### Crouch: toggle vs. hold — chosen behavior

Crouch is **toggle on press** rather than hold. Rationale:

1. The full set of crouched locomotion takes in the Mattias bundle
   (`walk_crouching_*`, `idle_crouching*`, `crouched_sneaking_*`) implies the
   stance is intended to be sustained — toggle matches that pacing.
2. The original Mercenaries series used hold-to-crouch on console pads, but
   on PC most players prefer a toggle because Ctrl is already a movement-
   bearing finger; toggling frees up the modifier for sprint chord plays.
3. Toggle simplifies the AnimBP — `bIsCrouching` is a single bool driven by
   the controller, with no per-frame chord polling.

## Architecture

| System | Where it lives | Notes |
|--------|----------------|-------|
| Character traversal | `BP_Mattias` (`ACharacter` subclass) | mesh, camera, movement |
| Locomotion driving | `ABP_Mattias` (`UAnimInstance` subclass) | reads `Speed`, `Direction`, `WeaponStance`, `bIsCrouching`, `bIsFalling`, `bIsDead`, `DeathDirection` from the owning pawn each tick |
| Input routing | `BP_PlayerController` | adds IMC on `BeginPlay`, dispatches actions to the possessed pawn |
| Game rules | `BP_GameMode` | sets default pawn + PC; later: respawn, level state |
| HUD | `WBP_HUDRoot` | spawned by PC, reads pawn state via binding |
| Pause | `WBP_PauseMenu` | spawned on demand by PC |
| Data schema | `/Game/Mercs2/Data/{Enums,Structs,Tables}` | mirrored by `docs/data/mercs2_data_schema.json` |

### Where the C++ port lives when we move off Blueprints

The systems below are mature enough to graduate from Blueprint to a small
gameplay module (call it `Mercs2Game`) when combat work begins:

- `APlayerCharacter` — the C++ base for `BP_Mattias`. Owns the
  `CharacterMovement` tuning, health, weapon stance, faction-reputation map,
  and dispatches `OnDeath`, `OnHealthChanged`, `OnWeaponStanceChanged`
  multicast delegates so the HUD and AI can react without polling.
- `AMercs2PlayerController` — adds the IMC and handles UI mode toggling
  (pause, PDA, contract overlay).
- `UFactionSubsystem` (UWorldSubsystem) — owns global reputation state and
  emits `OnReputationChanged(EFaction, float old, float now)` events; AI
  and world spawners subscribe.
- `AWeaponBase` — root weapon actor with virtual `Fire()`, `Reload()`,
  `OnAimDownSights()`. `UWeaponData` data asset (or `FWeaponData` row)
  feeds initial stats.
- `UInventoryComponent` — held weapons, current slot, swap policy.

Blueprint stays on top of each of these (for designer-tunable defaults, FX
hookup, and per-weapon overrides), but the deterministic logic lives in C++
so save-load and net replication don't get fragile.

### Data flow

```
PlayerController -- Enhanced Input -->  BP_Mattias (Character)
                                            |
                  reads each tick           v
WBP_HUDRoot  <----------- Health, Ammo, WeaponStance, Faction map
                                            |
              UAnimInstance tick            v
ABP_Mattias  ----------- Speed, Direction, bIsCrouching, bIsFalling, ...
```

The HUD never reads `PlayerController` directly — every value the HUD shows
comes off the controlled pawn. That keeps the HUD usable when the player
gets ejected from a vehicle, hijacks a soldier, or spectates after death.

## Deferred scope

### Combat

- Hit-scan and projectile weapons, including the long-range mortar /
  airstrike abilities that are central to the Mercenaries fantasy.
- Damage pipeline through `UGameplayStatics::ApplyPointDamage` /
  `ApplyRadialDamage`, with surface and faction modifiers.
- Reload, fire-mode toggle, melee, throwables (frags, smoke, satchel).
- AnimMontage hookup for fire, reload, draw, holster, melee — montages get
  loaded from the existing `Pistol_Montage` asset and authored equivalents
  for rifle and heavy.

**Estimate:** ~2 weeks for the basic firing/damage loop, another ~2 weeks
for the special-weapon variants (RPG, sniper, mortar/airstrike beacons).

### Vehicles

- Mercenaries' vehicle hijack pivots on a stealth-distance check + a
  per-vehicle context animation that pulls the driver out. Plan:
  - `AVehicleBase` actor with a `UHijackComponent` exposing a query API.
  - Driver NPC owns a `UHijackTarget` component, posing the hijack handles
    (front-left, rear, top).
  - Player input `IA_Interact` near a vehicle plays the appropriate
    pull-driver montage on both actors, then possesses the vehicle.
- Three driving feel tiers: civilian (light), military light (jeep / tank
  IFV), military heavy (tank / chopper). Each is its own `UMovementComponent`.

**Estimate:** ~3 weeks for the core hijack + drive loop on one vehicle
class; +1 week per additional tier.

### Faction reputation simulation

- Reputation per faction is the world's main agency lever in Mercenaries.
  Plan:
  - `UFactionSubsystem` (mentioned above) owns `TMap<EFaction, float>`
    reputation, range -100..+100.
  - Per-faction `URepEffectAsset` describes a threshold curve (hostile <
    -50, neutral -50..+50, allied > +50) and the consequences at each
    band: spawn tables for street patrols, vendor availability,
    safe-house access, contract eligibility.
  - World spawners and AI subscribe to `OnReputationChanged`; rebuild
    their spawn pools when the band changes.
  - Reputation deltas come from `UDamageEvent`, contract completion, and
    explicit script triggers.

**Estimate:** ~1.5 weeks for the subsystem + persistence; spawn-table
reactions land later as part of the world-state pass.

### Mission state machine + contract / supply-drop loop

- Mercenaries' macro loop is contract → execute → bonus payout → spend at
  the PMC base on weapon / vehicle / airstrike drops. Plan:
  - `UMissionSubsystem` (UWorldSubsystem) tracks the active main objective
    and any side contracts.
  - `UContractAsset` (UPrimaryDataAsset) — fields: title, description,
    issuing faction, target type, reward (cash + rep deltas), required
    items.
  - `WBP_ContractBoard` — list view of available contracts, gated by
    reputation.
  - `WBP_SupplyDropMenu` — purchase by category (light vehicle, tank,
    chopper, weapons crate, airstrike). Triggers a `USupplyDropManager`
    which spawns the drop with a `AAirdropMarker` + descending crate
    actor.
  - `UMissionObjectiveState` ties to the existing `FMissionObjective`
    struct rows so the HUD tracker can render any active contract without
    being mission-specific.

**Estimate:** ~2 weeks for the mission/contract data layer + UI, +1 week
for the airstrike-call gameplay verb.

### Save / load

- `USaveGame`-derived `UMercs2SaveGame` with sections for: player health,
  weapon stance, inventory, faction reputation, mission progress, world
  destruction state (which `vz_state_destroyed` overlays are active), and
  visited locations.
- `USaveLoadSubsystem` handles file I/O, async load on title screen, and
  autosave on contract completion / safe-house entry.
- Destruction overlay save: store the set of destroyed `vz_state` source
  names; on load, swap the corresponding `layers_static` actors out for
  their `_destroyed`/`_ruined` overlays (this is already supported by the
  populate scripts — we just need to drive the toggle from the save).

**Estimate:** ~1.5 weeks.

### Multiplayer / co-op

- Co-op is core to Mercenaries 2 PC, so plan early replication discipline:
  - `APlayerCharacter` movement, health, and weapon stance replicated.
  - Faction reputation replicated as a `FFastArraySerializer` of
    `FFactionReputation` entries, server-authoritative.
  - HUD reads from local pawn only — no controller-side state.
  - Mission state replicated via `UMissionSubsystem` on the server with
    `Net Multicast` events for "objective complete" feedback.
- Defer matchmaking / Steam integration until single-player is stable.

**Estimate:** ~3 weeks to get two-player co-op walking and seeing each
other; another ~2 weeks for synchronized contract / world state.

## M2-specific design notes

### Faction reputation effects on world spawns

The world is already populated by `populate_world.py` from the
`layers_static` + `vz_state` overlays we extracted from the retail data. The
populate script already places state overlays (pristine / destroyed /
ruined / staging) as hidden actors that the runtime can toggle. The
faction subsystem hooks into this by:

1. Mapping each `vz_state` source name to one or more `(EFaction, float
   threshold)` rules (e.g., the VZ militia outpost variants become visible
   only when VZ reputation < -50).
2. On reputation band change, the world subsystem queries the relevant
   overlay actors (already tagged with their source name during populate)
   and toggles `bHidden` accordingly.
3. Street patrol spawners (also placed during populate as ECS `LightObject`
   adjacent entities) subscribe directly and rebuild their pool.

This avoids any re-import or re-populate work — the heavy lifting is
already done by the existing pipeline.

### Contract UI and supply drop loop

The PDA UI (`IA_OpenPDA` → Tab) is the player-facing surface for the macro
loop. Three top-level tabs:

- **Map** — full-screen world map with mission markers, safe houses,
  faction outposts. Reuses the minimap placeholder texture path so both
  views share a single source.
- **Contracts** — list of available contracts filtered by reputation
  band. Each entry shows reward, target faction, and current rep delta
  expected on completion.
- **Supply Drop** — purchasable vehicles, weapons crates, airstrikes.
  Spending money here is the primary outlet that keeps cash from being
  a hoard resource.

The supply-drop placement actor follows a simple pattern: player picks an
item and a target location on the world map, the manager spawns a
`AAirdropMarker` that descends from outside the streaming region and lands
the requested actor with a one-shot impact effect. The plane fly-over is
visual flavor — the actual spawn is just a position + class.

### Vehicle hijack

The vehicle hijack gameplay verb is a defining M2 moment. Mechanically:

1. Player approaches an occupied vehicle.
2. `IA_Interact` triggers an attempt — succeeds if (a) the driver's
   awareness is below a threshold (sneak vs. open-combat hijack pose), and
   (b) the player is on the correct side of the vehicle.
3. Both actors play synchronized montages: driver gets yanked, player
   slides in. We can use the existing `Grab_Rifle_From_Behind_Shoulder_Anim`
   take as a stand-in for the rifle-equipped variant and author the
   unarmed/pistol variants later.
4. After the montage, ownership transfers and the player possesses the
   vehicle.

### Destruction and ragdoll

Mercenaries' destruction tech is what made the original feel special. UE5
gets a lot of it for free with Chaos:

- **Buildings** — pre-fractured via Chaos Geometry Collection on the
  authored sub-meshes from `populate_world`. Damage threshold tied to
  weapon class so a sidearm can't level a building but an RPG round (or
  enough sustained hits) can. Already supported by the existing destroyed
  / ruined overlay system — the fracture is the *animation* between
  pristine and destroyed.
- **Vehicles** — per-vehicle health, with a damage-state texture swap and
  a final pre-fractured wreck mesh on death. Same overlay pattern.
- **NPCs** — `URagdollComponent` switches the skeletal mesh to physics on
  death and freezes the AnimBP. The Mattias `_PhysicsAsset` ships with
  the rig, so the player ragdoll comes for free; the AI characters will
  need their own physics assets authored alongside their skeletal
  meshes.

The above is intentionally light — the combat-pass will fill in the
specifics. The goal of this doc is to make sure the foundations laid in
the four setup scripts are pointing in the right direction.

## Atmosphere / Water / Weather

A trio of editor scripts in `game-scripts/` lays the world-feel
foundation: a tropical sky, an ocean covering the world bounds, and a
state-machine-driven weather controller. They slot into the project
setup chain right after `populate_world.py` (which spawns the atmosphere
actors in the first place):

```
setup_project.py
import_world.py
populate_world.py            # spawns AtmosphericLight_World, HeightFog_World, SkyAtmosphere_World, SkyLight_World
setup_atmosphere.py          # tunes the above for tropical Maracaibo
setup_water.py               # enables Water plugin, spawns Ocean_Maracaibo
setup_weather_system.py      # creates EWeatherState / FWeatherStateParams / DT_WeatherStates / BP_WeatherController + PP_Weather_Global
setup_player_character.py
setup_player_controller.py
setup_basic_hud.py
setup_data_structs.py
setup_player_start.py
setup_terrain_collision.py
```

### What's automated (this pass)

`setup_atmosphere.py`:

- Locates `HeightFog_World`, `SkyAtmosphere_World`, `AtmosphericLight_World`
  (with fallbacks to the names `populate_world.py` uses) and tunes them
  for a tropical Maracaibo look:
  warm-haze ExponentialHeightFog with volumetric fog enabled, the
  documented SkyAtmosphere defaults confirmed, a `VolumetricCloud` actor
  spawned with a 3 km base / 6 km thick cumulus layer, and the
  DirectionalLight pinned to 8 lux at 5800 K with the real-sun angular
  size.
- Spawns a `VolumetricCloud` actor if none exists and assigns the engine
  default `m_SimpleVolumetricCloud` material.

`setup_water.py`:

- Patches `UnrealEngineGame/UnrealEngineGame.uproject` to enable the
  engine `Water` plugin (preserving the original tab indentation).
- After restart, spawns a `WaterBodyOcean` named `Ocean_Maracaibo`
  centered on the origin with a ~10 km square spline polygon
  (≈1 km of clip-margin beyond the terrain bbox), sea level at Z=0,
  Phillips wave spectrum, 1 m max wave height, and `bAlwaysUpdateWaterMesh`
  set so testing works without authoring a `WaterZone` first.

`setup_weather_system.py`:

- Creates the `EWeatherState` enum (`Clear`, `Cloudy`, `Rainy`, `Stormy`),
  the `FWeatherStateParams` struct shell, and the `DT_WeatherStates`
  data-table shell, all under `/Game/Data/`.
- Creates `BP_WeatherController` (parent `Actor`) under `/Game/World/`
  with a `RainEmitter` `NiagaraComponent` attached but un-activated.
- Spawns an unbounded `PP_Weather_Global` `PostProcessVolume` and a
  `WeatherController` instance, auto-filling the controller's
  `FogActor` / `CloudActor` / `SunActor` / `PostProcessActor` /
  `WeatherTable` references where the matching level actors exist.
- Writes a repo-side schema manifest at
  `docs/data/mercs2_weather_schema.json` listing the canonical enum
  entries, struct fields, and per-state row values for human reference
  and tooling.

### What's manual

The Python editor API in 5.7 cannot author UserDefinedStruct fields,
DataTable row contents, or Blueprint event graphs. The scripts log
explicit MANUAL warnings for each, but at a glance you must finish:

1. **`FWeatherStateParams` fields** — add the nine fields in the order
   listed in `setup_weather_system._BP_VARIABLE_SPEC` / the schema
   manifest.
2. **`DT_WeatherStates` rows** — bind the row struct, then enter the four
   rows (`Clear`, `Cloudy`, `Rainy`, `Stormy`) using values from
   `docs/data/mercs2_weather_schema.json`.
3. **`BP_WeatherController` variables** (`CurrentState`, `TargetState`,
   `TransitionDuration`, `TransitionAlpha`, the four actor soft-refs,
   plus `WeatherTable`, `CurrentParams`, `TargetParams`).
4. **`BP_WeatherController` event graph**: on `BeginPlay` read the
   `DT_WeatherStates` row for `CurrentState`, apply it immediately to
   the referenced actors, and on each tick lerp `CurrentParams` toward
   `TargetParams` over `TransitionDuration` seconds, writing back the
   blended values to fog / clouds / sun / PP / Niagara rain on every
   tick.
5. **Niagara rain emitter** — author or import a stock rain emitter
   (`NS_Rain`) with a float `SpawnRate` user parameter wired to
   `FWeatherStateParams.RainEmissionRate`, and assign it to the
   controller's `RainEmitter` component.
6. **Debug input** — add `IA_DebugWeatherCycle` bound to `F8` in
   `IMC_Default` and, in `BP_PlayerController`, on press call
   `WeatherController.TargetState = (CurrentState + 1) % 4` to verify
   the lerp path end-to-end.

### Tunable parameters and where they live

All per-state knobs are rows in `DT_WeatherStates` (asset path
`/Game/Data/DT_WeatherStates`, schema mirror at
`docs/data/mercs2_weather_schema.json`):

| Field | Meaning |
|-------|---------|
| `FogDensity` | drives `ExponentialHeightFogComponent.FogDensity` |
| `FogInscatteringColor` | drives `FogInscatteringColor` (warm vs gray-cool) |
| `CloudCoverageFactor` | 0..1 scalar pushed into the cloud material density |
| `SunIntensity` | DirectionalLight intensity (lux) |
| `SunTemperature` | DirectionalLight temperature (Kelvin) |
| `RainEmissionRate` | Niagara rain `SpawnRate` user parameter |
| `WindSpeed` | drives a later-pass `WindDirectionalSource` |
| `PostProcessExposure` | `AutoExposureBias` on `PP_Weather_Global` |
| `PostProcessSaturation` | `ColorSaturation` scalar on `PP_Weather_Global` |

The static (non-state) knobs live in the scripts themselves:

- Tropical light angle, sky atmosphere defaults, volumetric cloud
  altitude/thickness, fog volumetric distance — in
  `setup_atmosphere.py`.
- Ocean polygon size, sea-level Z, wave height, wave spectrum — in
  `setup_water.py` (`OCEAN_HALF_M`, `SEA_LEVEL_M`,
  `MAX_WAVE_HEIGHT_M`).

### Future work

- **Time-of-day cycle** — add a separate `BP_TimeOfDayController` that
  drives `AtmosphericLight_World`'s rotation on an in-game clock; the
  weather controller can sample its angle to bias `SunIntensity`
  multiplicatively rather than absolutely.
- **Hourly weather rolls** — drive `TargetState` from a weighted random
  table that respects the previous state (Clear → Cloudy more likely
  than Clear → Stormy), with a brief stable window after each
  transition.
- **Per-mission weather overrides** — let a mission script call
  `WeatherController.PushOverride(state, durationSeconds)` so set-piece
  missions (a stormy nighttime convoy intercept) can override the
  ambient roll temporarily, then pop back to the rolled state.
- **Weather-influenced gameplay** — rain reduces enemy AI vision range
  and player audio occlusion, wets the terrain BRDF (set a
  material parameter collection `MPC_Weather` consumed by terrain and
  vehicle materials), and increases wind shake on the camera. Stormy
  state adds a low-frequency rumble and biases the sky to a darker
  multiscatter color.
- **Coastline blend** — once `setup_water` lands, follow up with a
  shoreline-tinted material on the terrain GLB's near-shore samples so
  the ocean clip line doesn't pop at the horizon.
