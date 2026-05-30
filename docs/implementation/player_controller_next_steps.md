# Player controller — minimal next steps (Blueprint-first)

**Track:** item 15 (movement, weapons, camera)  
**Date:** 2026-05-30  
**Context:** `game-scripts/setup_player_character.py` and `setup_player_controller.py` scaffold assets; `docs/character_systems_plan.md` describes a `Mercs2Game` C++ module that is **not** in this repository yet.

## Goal

Playable third-person Mattias in a test map: move, look, jump, sprint, crouch toggle, camera orbit — with weapon/combat hooks stubbed for later `DT_WeaponData` integration.

## Path A — Blueprint-first (no C++ module, fastest)

Extend existing Python setup scripts only where the UE 5.7 API allows; finish wiring in the editor.

### 1. `setup_player_controller.py` extensions (automatable)

- After creating `BP_PlayerController`, set CDO property `bShowMouseCursor = false` and `DefaultMouseCursor` if exposed.
- Log explicit asset paths for `IA_*` → load in BP via soft references (already listed in `IMC_BINDINGS`).
- Optional: create empty `WBP_HUDRoot` / `WBP_PauseMenu` widget shells via `WidgetBlueprintFactory` if the factory is exposed on the build; otherwise keep MANUAL log.

### 2. Manual Blueprint wiring (one-time, ~30 min)

| Asset | Action |
|-------|--------|
| `IMC_Input_Controls` | Add mappings from `IMC_BINDINGS` in script header |
| `BP_PlayerController` | BeginPlay: Add Mapping Context; possess `BP_Mattias` |
| `BP_Mattias` | Event Graph: IA_Move → `AddMovementInput` (camera-relative); IA_Look → controller yaw/pitch; IA_Jump/Sprint/Crouch as documented in `BP_MANUAL_STEPS` |
| `ABP_Mattias` | Parent class `AnimInstance`; Event Graph Update Animation reads Speed/Direction from pawn |

### 3. Weapon / combat stubs (Blueprint variables only)

On `BP_Mattias`:

```
CurrentWeaponRow   (FWeaponData row name / DataTable row handle)
WeaponStance       (EWeaponStance) — already documented
bIsAiming          bool
Health / MaxHealth float
```

- `IA_Fire` → Print String or `ApplyDamage` to a test actor (no WAD stats yet).
- `IA_SwitchWeapon` → cycle rows in `DT_WeaponData` and set `WeaponStance`.
- `IA_Aim` → reduce `MaxWalkSpeed`, set `bIsAiming` for AnimBP.

### 4. Camera (already scaffolded in Python)

Verify SpringArm on `BP_Mattias`: length 300, socket Z 60, `use_pawn_control_rotation`, camera lag. No extra axis swizzles (game LH → UE via Interchange on meshes only).

## Path B — C++ `Mercs2Game` module (planned, not in repo)

When adding `UnrealEngineGame/Source/Mercs2Game/`, minimum classes to match the Python scaffolds:

| Class | Responsibility |
|-------|----------------|
| `AMercs2Character` | Enhanced Input in `SetupPlayerInputComponent`; health; sprint/crouch; `WeaponStance`; feed `UMercs2AnimInstance` |
| `AMercs2PlayerController` | `AddMappingContext` in `BeginPlay`; create HUD widget |
| `UMercs2AnimInstance` | `NativeUpdateAnimation`: Speed, Direction, flags from character |
| `AMercs2GameMode` | Default pawn + PC classes |

Point `DefaultEngine.ini` `GlobalDefaultGameMode` at `AMercs2GameMode` and retire `BP_GameMode` once parity is reached.

**Minimal C++ input surface** (pseudocode):

```cpp
void AMercs2Character::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent) {
    auto* EIC = Cast<UEnhancedInputComponent>(PlayerInputComponent);
    BindAction(IA_Move, Triggered, this, &AMercs2Character::OnMove);
    BindAction(IA_Look, Triggered, this, &AMercs2Character::OnLook);
    // Jump, Sprint, Crouch, Aim, Fire stubs
}
```

## Python script additions (optional small diffs)

`setup_player_character.py`:

- Export `EWeaponStance` enum asset if `EnumFactory` is available (mirror `setup_data_structs.py`).
- Set `BP_Mattias` parent to `Character` (done) — document that designer should reparent to `Mercs2Character` when C++ lands.

`setup_player_controller.py`:

- After `BP_GameMode` CDO setup, set `PlayerController` `bEnableClickEvents` false.
- Write `docs/implementation/player_controller_next_steps.md` path into run summary (this file).

## Verification checklist

1. Run `setup_player_character.py` then `setup_player_controller.py`.
2. World Settings → GameMode = `BP_GameMode`.
3. PIE: WASD move, mouse look, space jump, shift sprint, ctrl crouch toggle.
4. AnimBP shows locomotion blend changing with speed (after manual ABP graph).
5. No duplicate coordinate swizzles on pawn (placement uses `game_to_ue` only at populate time).

## Dependencies on other tracks

| Track | Dependency |
|-------|------------|
| Road graph (item 5) | None for player controller |
| Combat (item 8) | `DT_WeaponData` populated from WAD before balancing `IA_Fire` |
| Populate | Player start can use `mercs2_hero_placement.py` PMC outpost coords |
