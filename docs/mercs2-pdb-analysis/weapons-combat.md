# Weapons & Combat

Scope: weapons, ammo/magazines, projectiles, homing missiles & lock-on, scatter/aim/reticle, damage, and explosions/blast.

Provenance: All evidence below comes from the recovered Xbox 360 preview executable `Mercs2_Xenon_P.exe` (Mercenaries 2: World in Flames, Jul 11 2008 "Profile" devkit build, PowerPC; decompressed PE at `output/jul08_prototype/mercs2_xenon_p.pe_full.bin`). The engine is Pandemic's in-house "Pangea" (`Pg*`) engine; physics is Havok (`hk*`/`hkp*`). This is symbol/string evidence, not a real `.pdb`. Symbols are cited verbatim from `output/jul08_prototype/inventory/weapons-combat.txt` and strings/source-paths from the shared evidence files.

## Overview

The weapons-combat subsystem is implemented around a `PgWeaponSystem` / `WeaponSystem` driver (string `PgWeaponSystem`, `WeaponSystem` at line 3027) that updates per-frame "Runtime" state objects (`RuntimeWeapon`, `RuntimeProjectile`, `RuntimeWeaponProjectile`, etc.) and processes firing, projectile flight, homing/lock-on, damage application, and explosions. The one build source-path in this system is `PgWeaponProjectile.cpp`, and an assert in it (`PgWeaponProjectile.cpp(863)`) confirms projectile code lives there.

The architecture is data-driven via the engine's component/ECS descriptor registry: the descriptor dump (lines ~1640–1911) lists component classes with pool sizes such as `WeaponProjectileBase 384 128`, `WeaponBarrel 512`, `WeaponScatter 256`, `HomingWeapon 128 64`, `ProjectilePhysics 128 128`, and runtime counterparts `RuntimeWeapon 192 64`, `RuntimeProjectile 512 128`, `RuntimeWeaponProjectile 160 32` (the two trailing numbers are pool allocation counts/grow sizes, consistent with the sibling ECS-component docs). Static (design-time) component classes describe a weapon's barrels, scatter, scope, UI/reticle, ammo, and recoil; the `Runtime*` classes hold the live per-instance firing state.

The internal class label `RuntimeWeapon` has a debug-dump format (lines 2917–2936) exposing the live struct layout, including `Thrown:` and `Projectile:` sub-states. This is the clearest single piece of evidence for how a weapon's runtime state is organized (see Notable strings).

## Source files

From `output/jul08_prototype/mercs2_xenon_p.source_paths.txt` (verbatim):

```
d:\projects\ReleaseLine\Mercs2\Pangea\Src\PgWeaponProjectile.cpp
```

(That is the only source path that belongs unambiguously to this system. Sound/AI source paths such as `PgGameSystem.cpp` exist but are not weapons-specific.)

## Key classes

No weapons-combat C++ class appears in `mercs2_xenon_p.rtti_classes.txt` — that file contains only Havok (`hk*`/`hkp*`) RTTI names. The `Pg*`/`Runtime*` weapon types in this system are exposed as **debug name strings and component descriptors**, not as RTTI `.?AV`/`.?AU` entries, so there are no demangled class names to list here. Weapon classes were likely compiled without RTTI, or their RTTI did not survive into the recovered table.

The class-like names that DO appear (as descriptor/label strings, not RTTI) include: `PgWeaponSystem`, `RuntimeWeapon`, `RuntimeProjectile`, `RuntimeWeaponProjectile`, `RuntimeHomingProjectile`, `RuntimeHomingWeapon`, `RuntimeHomingTarget`, `WeaponProjectileBase`, `HomingWeapon`, `HomingProjectile`, `HomingTarget`, `ProjectilePhysics`.

## Symbols by area

Offsets and sections below are copied from `inventory/weapons-combat.txt`. All are in `.rdata`.

### Weapon system & runtime core
| Offset | Symbol |
| --- | --- |
| 0x0021a18 | WeaponSystem |
| 0x00218b4 | WeaponCoupling |
| 0x003116c | WeaponProjectileBase |
| 0x0031138 | WeaponEffects |
| 0x0031148 | WeaponRecoilVehicle |
| 0x003115c | WeaponBarrel |
| 0x0031184 | WeaponScatter |
| 0x00311c4 | WeaponThrown |
| 0x00311d4 | WeaponTrigger |
| 0x00311f0 | WeaponScope |
| 0x002d790 | WeaponEvent |

These are the weapon-side component/marker symbols. `WeaponSystem`/`WeaponCoupling` drive firing; `WeaponProjectileBase` is the base projectile-weapon component; `WeaponBarrel`/`WeaponScatter`/`WeaponScope`/`WeaponThrown`/`WeaponTrigger` are the per-aspect components (barrel/hardpoints, spread, scoping, thrown, trigger behavior). `WeaponEffects`/`WeaponRecoilVehicle` cover muzzle/recoil effects (the latter vehicle-specific). The descriptor dump confirms pool sizes for most of these (`WeaponProjectileBase 384 128`, `WeaponBarrel 512`, `WeaponScatter 256`, `WeaponCoupling 512`, `WeaponScope 16 16`, `WeaponThrown 16 16`, `WeaponTrigger 16 16`, `WeaponEffects 384 128`, `WeaponRecoilVehicle 64 64`).

### Projectiles
| Offset | Symbol |
| --- | --- |
| 0x0013ca8 | ProjectileCollision |
| 0x0021764 | ProjectileCreate |
| 0x0021738 | ProjectileInstantiate |
| 0x0021750 | ProjectileDestroy |
| 0x0021724 | ProjectileCacheGet |
| 0x00216d8 | ProjectileSetup |
| 0x00216c8 | ProjectileReset |
| 0x0021700 | ProjectileConfig |
| 0x003121c | ProjectilePhysics |

The projectile lifecycle: create/instantiate (with a pooled cache — `ProjectileCacheGet`), configure/setup/reset, run `ProjectilePhysics`, and detect `ProjectileCollision`, then destroy. The related (string-only) profiling labels `UpdateProjectiles`, `Update::Raycast`, `Update::Gravity`, `Update::FlightNoise`, `Update::Movement`, `UpdateRay::ProcessCast`, `UpdateRay::CheckWater` (lines 2986–2997) show the per-tick update is broken into ray-cast, gravity, flight-noise, movement and water-check phases.

### Homing / lock-on
| Offset | Symbol |
| --- | --- |
| 0x00316c8 | HomingWeapon |
| 0x00316d8 | HomingProjectile |
| 0x00316ec | HomingTarget |
| 0x0021590 | HomingWeapon::GuiEvent |
| 0x00215a8 | HomingWeapon::ProcessCast |
| 0x0021610 | HomingCacheTargets |
| 0x0021624 | HomingCacheProjectiles |
| 0x002163c | HomingCacheWeapons |
| 0x0021650 | HomingUpdateProjectiles |
| 0x0021668 | HomingUpdateGuided |
| 0x002167c | HomingUpdateWeaponAi |
| 0x0021694 | HomingUpdateWeapons |
| 0x0021da8 | HomingLaunched |
| 0x0021db8 | HomingLockClear |
| 0x0021de0 | HomingLockUpdate |
| 0x0021df4 | HomingLockStart |

A complete lock-on/homing pipeline: cache targets/projectiles/weapons, update guided projectiles and weapon AI, manage the lock state machine (`HomingLockStart` → `HomingLockUpdate` → `HomingLockClear`), and fire (`HomingLaunched`). `HomingWeapon::GuiEvent` and `HomingWeapon::ProcessCast` are member labels for the homing weapon. String-only siblings include `SetupHomingGets`, `SendHomingGuiEvent`, `EvalTargets`, `CacheTargetValues`, `SpawnHomingProjectile`, and `RuntimeHomingProjectile::Update` (lines 2959–2974, 4117).

### Aim & reticle
| Offset | Symbol |
| --- | --- |
| 0x00215e4 | WeaponAim |
| 0x00311e4 | WeaponUI |
| 0x003121c (see above) | (ProjectilePhysics) |

`WeaponAim` plus the homing/projectile aim updates; `WeaponUI` is the reticle/HUD weapon component (descriptor `WeaponUI 384 128`). Reticle behavior is also surfaced through the enum/field strings `WeaponUIReticleTypeEnum`, `WeaponUIReticleHealthTypeEnum`, `WeaponUIScopeTypeEnum` (lines 5932–5937) and the runtime reticle markers `FireFromReticle`, `GetReticlePosition`, `GetTargetUnderReticle`, `StingerReticleUpdate`, `PlayerReticleUpdate` (string-only).

### Ammo & magazines
| Offset | Symbol |
| --- | --- |
| 0x003ba20 | AmmoValue |
| 0x003ba2c | AmmoGuid |
| 0x003e974 | AmmoTemplate |
| 0x002d928 | ExplosivesStoredAmmo |
| 0x002d940 | ExplosivesCurrentAmmo |
| 0x00712a0 | ClipGeneratorFlags |

Ammo identity/value (`AmmoValue`, `AmmoGuid`), the design template (`AmmoTemplate`), and explosives-ammo counters. The tunable field strings `iClipSize`, `iRoundsPerReload`, `iBulletsPerShot`, `MaxAmmoReserve`, `MaxAmmoReserveModifier`, `iMultipleMagazines`, `FirstMagazine`, `RateOfFire`, `iTracerRound`, `iHideMagazineOnFire`, `PrimaryClipSize`/`PrimaryStoredAmmo`/`PrimaryCurrentAmmo` (lines 4873–4875, 6866–6876) describe the ammo/magazine parameters. Note: `ClipGeneratorFlags` (0x00712a0) is most likely the Havok animation `hkbClipGenerator` "Clip" feature (it sits beside `hkbClipGenerator`/`hkbClipTrigger`/`relativeToEndOfClip`, lines 10079–11156), **not** a weapon magazine — flagged as ambiguous.

### Reload
| Offset | Symbol |
| --- | --- |
| 0x002883c | ReloadAll |
| 0x002a908 | ReloadAsset |
| 0x002a938 | ReloadLayer |

Reload markers. `ReloadAsset`/`ReloadLayer`/`ReloadAll` read as asset/layer hot-reload rather than weapon magazine reload; the magazine reload state is exposed instead via the `RuntimeWeapon::Thrown` dump fields `bReloading`/`bNeedReload`/`bDroppedMagazine` (line 2920–2921) and `iRoundsPerReload`.

### Damage
| Offset | Symbol |
| --- | --- |
| 0x0022d38 | DamagePerson |
| 0x0022d48 | DamageObject |
| 0x00315a4 | DamageKey |
| 0x0032600 | DamageChunks |
| 0x003b3d8 | DamagePassthrough |
| 0x003bbb4 | DamagePassThrough |
| 0x003bba0 | DamageThreshhold |
| 0x003f728 | DamageThresh |
| 0x003ed34 | DamageMinimum |
| 0x003ed6c | DamageDropoff |
| 0x003ed58 | DamageDropoffStart |
| 0x003ed44 | DamageDropoffStop |
| 0x003ef78 | DamageJitterModifier |
| 0x003f57c | DamageRadius |
| 0x003fd3c | DamageModifier |
| 0x003a210 | DamageKeyEnum |

Damage application (`DamagePerson`/`DamageObject`), the damage-material key (`DamageKey`/`DamageKeyEnum`), debris/chunking (`DamageChunks`), pass-through behavior (two casings: `DamagePassthrough` and `DamagePassThrough`; likely a component name vs. a field), and the range/falloff curve (`DamageMinimum`, `DamageDropoffStart`/`Stop`, `DamageRadius`, plus `MaxDamage`/`MinDamage` strings at lines 7136–7137). String-only damage internals: `ApplyDamage`, `ApplyDamageToNodeHealth`, `ApplyDamageToPrimaryHealth`, `TickDamage`/`RtTickDamage`, `RtDamageFlags`, `RuntimeLastDamageApplied`, `HeadShot`, `OnDamage`, `NetworkDamageException` (lines 3015–3024, 5490–5589, 5766).

### Explosions / blast
| Offset | Symbol |
| --- | --- |
| 0x0031128 | ExplosionFudge |
| 0x003a248 | ExplosionLarge |
| 0x0039fd0 | ExplosiveDetailEnum |

Plus the string-only explosion pipeline: `UpdateExplosions`, `PhysicsCreateExplosion`, `ProcessExplosionCast`, `ApplyExplosion`, `ApplyExplosionToPrimary`, `ApplyExplosionToBodies`, `ExpToObj`, `CollectExplosionCollector`/`UpdateExplosionCollector`/`ReturnExplosionCollector`/`GetExplosionCollector` (lines 2939–2958). `ExplosionFudge` has a descriptor (`ExplosionFudge 256 64`) and `Explosive 96 32` is the explosive component. The debug-menu strings `Grenade Explosion`, `Tiny Explosion`, `VS Explosion`, `Small Explosion`, `Large Explosion`, `Huge Explosion`, `Display Explosion Debug` (lines 665–679) confirm an explosion-size taxonomy and an in-game debug visualizer.

### Bullets, scatter & projectile typing (enums)
| Offset | Symbol |
| --- | --- |
| 0x003a264 | BulletAM |
| 0x003a270 | BulletLarge |
| 0x003ac84 | WeaponProjectileTypeEnum |
| 0x003ac50 | WeaponProjectileSpecialCaseTypeEnum |
| 0x003ab98 | WeaponUIReticleHealthTypeEnum |
| 0x003abd0 | WeaponUIScopeTypeEnum |
| 0x003abf0 | WeaponUIReticleTypeEnum |
| 0x003b13c | WeaponCouplingTypeEnum |
| 0x003a010 | HomingTypeEnum |

`BulletAM`/`BulletLarge` are damage/sound-key bullet classes (they appear in the `DamageKeyEnum` value list, line 5780–5781). The enums define projectile fire type, special-case type, reticle/scope types, weapon coupling, and homing type (values listed in Notable strings).

### Other / weapon naming & hints
| Offset | Symbol |
| --- | --- |
| 0x003bab4 | WeaponName |
| 0x0031648 | WeaponHint |
| 0x003bba0 | DamageThreshhold |

`WeaponName` (plus string-only `PrimaryWeaponName`, `SlaveWeaponName`); `WeaponHint` is an AI/targeting hint component (descriptor `WeaponHint 384 128`); the assert `Weapon: %s has no WeaponHint` (line 3122) shows it is required for some weapons.

## Notable strings

`RuntimeWeapon` debug-dump format (live struct layout — strongest evidence for runtime state), lines 2917–2936:
```
    struct RuntimeWeapon:
      model              %s
      vAimTarget         %.3f,%.3f,%.3f
      vAimDirection      %.3f,%.3f,%.3f
      iOwner             0x%08x
      iPlayer            0x%08x
      iLastAmmo          0x%08x
      iReserveAmmo       %d
      eType              %d (0=projectile, 1=thrown, 2=trigger)
      eSpecialCase       %d (0=none, 1=grapple, 2=flare, 3=laser)
      bTriggerIsDown=%s   bAimTargetModified=%s
     RuntimeWeapon::Projectile:
      iParentWeapon    0x%08x
      fFireDelay       %.3f
      iClipAmmo        %d
      bReloading=%s     bWaitingForAim=%s bTriggerDown=%s
      bFireSingle=%s    bNeedReload=%s    bDroppedMagazine=%s
     RuntimeWeapon::Thrown:
      fVelocity       %.3f
      bThrowing=%s     bHolding=%s
```

Equip/inventory dump (line 3035–3047): `bSwitchingPrimary=%s eWeaponVisibility=%s bEquipping=%s bLocked=%s`, `iWeaponInUse`, `iEquippedPrimaryGuid`, `iEquippedSecondaryGuid`, `iEquippedVehicleWeaponGuid`, `iLastEquippedPrimaryGuid`, `iLastEquippedSecondaryGuid`, `iEquipmentWaitingForPickupGuid`, `iAmmoProp`, `uiCurrentEquipAction`.

Asserts / error markers:
- `d:\projects\ReleaseLine\Mercs2\Pangea\Src\PgWeaponProjectile.cpp(863)` (line 3066) — projectile assert.
- `Weapon: %s has no WeaponHint` (line 3122).
- `<runtime weapon not found for guid 0x%08x>` (line 3034).
- `GrabGrenade(failed)` / `GrabGrenade` (lines 3242–3243); `NoGrenades` (lines 3276, 6810).

Enum value sets (lines ~5738–6038):
- `WeaponProjectileTypeEnum`: `Automatic`, `SemiAutomatic`, `Burst` (lines 5944–5947).
- `WeaponProjectileSpecialCaseTypeEnum`: `Grapple`, `Flare` (… and Bounce/Laser context) (lines 5940–5942).
- `WeaponCouplingTypeEnum`: `LinkedFire`, `AlternateFire` (lines 6023–6025).
- `WeaponUIScopeTypeEnum`: `Sniper` (line 5935–5936).
- `WeaponUIReticleHealthTypeEnum`: `Curved`, `Straight_bottom` (lines 5932–5934); runtime variants `curved`, `straight (bottom)`, `Homing`, `Laser` (lines 4934–4938).
- `HomingTypeEnum`: `Guided`, `Radar` (lines 5742–5744).
- `FireAngleEnum`: `FIREANGLE_WIDE`/`_MEDIUM`/`_NARROW` (lines 5745–5748).
- `DamageKeyEnum`: `Explosion`, `BulletLarge`, `BulletAM`, `RocketLarge`, `ExplosionLarge`, `WheelBurnout`, `BunkerBuster` (lines 5775–5782).
- `ExplosiveDetailEnum`: `Random`, `Center` (lines 5738–5741).

Tunable / parameter field names (lines ~6855–7197) — design-time weapon stats:
- Ammo/fire: `iClipSize`, `iRoundsPerReload`, `iBulletsPerShot`, `MaxAmmoReserve`, `MaxAmmoReserveModifier`, `RateOfFire`, `iTracerRound`, `iHideMagazineOnFire`, `iMultipleMagazines`, `FirstMagazine`, `AmmoTemplate`, `FireType`, `SpecialCaseType`.
- Scatter/aim: `ScatterPerShot`, `ScatterMax`, `ScatterMin`, `ScatterAimModeMax`, `ScatterAimModeMin`, `CenterBias`, `LowSkillScatter`, `RifleSkill`, `MaxAimAngle`, `MaxAimAngleAi`, `PhysicalRecoil`, `FakeUIMultiplier`.
- Barrel/effects: `MuzzleFlashTemplate`, `MuzzleFlashHardpoint`, `ShellTemplate`, `ShellEjectHardpoint`, `ControllerName`.
- Reticle/scope: `ReticleType`, `ReticleHealthType`, `ReticleTexture`, `ScopeType`, `StartingZoom`, `ZoomMultiplier`, `MaxZoomLevel`, `MinZoomLevel`; runtime fields `nStingerReticleHeight`, `nStingerReticleWidth`, `bReticleCrosshair`, `uReticleTexture`, `sReticleType`, `sReticleHealthType`, `nMaxLockOnRadius`, `uNewCurrentGunGuid`, `uNewCurrentExplosive` (lines 4927–4940).
- Homing: `LockOnTime`, `LockOnMaxDistance`, `LockOnMaxAngle`, `LockOnMinWeight`, `DetonationDistance`, `TurnSpeed`, `uTargetHardpoint`, `Velocity`, `Accel`, `AccelTime`, `MaxAge`, `MaxForce`, `MinForceFalloff`, `Detail` (lines 6920–6934).
- Thrown/grenade: `bCook`, `GravityScale`, `ThrowAngle`, `VelocityAtHighestPitch`/`MiddlePitch`/`LowestPitch`, `ReticlePitchHighest`/`Middle`/`Lowest` (lines 6899–6907); `ThrowGrenade`, `RayCastGrenade` markers (lines 3094, 5723).
- Damage: `DamageMinimum`, `DamageDropoffStart`, `DamageDropoffStop`, `DamageRadius`, `DamageModifier`, `DamageJitterModifier`, `MaxDamage`, `MinDamage`, `HeroMultiplier`, `BrawnModifier`, `FiredFromWeapon`, `UseWeaponTransform`, `SingleShotWeapon`, `ChargeTime` (lines 6937–7142).
- Trigger/scope flags: `TriggerTemplate`, `TriggerName`, `bBroadcast`, `bContinuous`.

HUD/ammo UI strings: `GuiShowAmmoCounter`, `bShowGun`, `bShowExplosive`, `GuiWeaponEquippedUpdate`, `GuiReticleUpdate` (lines 7432–7434, 4833–4836). Cheat: `CheatInfiniteAmmo` (line 5613). Debug HUD: `Timescale: %2.2f  Weapon aim: %s  Position: %s` (line 7454).

Material/asset key strings tied to projectile/weapon damage (lines 5801–5874): `wpn_rocket`, `wpn_rifle`, `wpn_pistol`, `wpn_grenade`, `wpn_emplacedgun`, `wpn_designator`, `wpn_clip`, `wpn_c4`; `projectile_grapple`, `projectile_rocket`, `projectile_bullet_rifle`, `projectile_bullet_heavymg`. (These `wpn_*` blocks match the project's weapon-definition WAD-block notes — see Cross-references.)

## Cross-references

- `docs/mercs2-pdb-analysis/havok-physics.md` and `docs/mercs2-pdb-analysis/physics-game.md` — projectile flight, explosion casts (`ProcessExplosionCast`, `PhysicsCreateExplosion`) and `ProjectilePhysics` use Havok (`hkp*` agents/raycast). All RTTI classes referenced by this system live there.
- `docs/mercs2-pdb-analysis/vehicles.md` — `WeaponRecoilVehicle`, `VehicleAmmo`, `iEquippedVehicleWeaponGuid`, manned/emplaced weapons (`MannedWeaponNode`, `UseHeavyWeapon`, `wpn_emplacedgun`).
- `docs/mercs2-pdb-analysis/pangea-engine-core.md` — `PgWeaponSystem` runs within the Pangea game-system/ECS update loop; the descriptor table (component pool sizes) is the ECS registry.
- `docs/mercs2-pdb-analysis/rendering-shaders.md` — `WeaponEffects`, `MuzzleFlashTemplate`, tracer/shell effects, reticle textures.
- Project ECS docs `docs/ecs_components.md` and `docs/mercs2-ecs/` — the WAD-side counterparts of these weapon component classes.
- Weapon-stat WAD blocks: the project memory note "weapon-definitions-wpn-blocks" documents that editable weapon stats live in `wpn_<name>_P000_Q3.block` blocks; the field names above (`iClipSize`, `ScatterPerShot`, `Velocity`, `DamageRadius`, etc.) are the human-readable labels for those reflection blobs.
- `docs/mercs2-luacd/` — Lua-side weapon/store wrappers; the engine fields here are the native backing of the Lua `all_weapons` stubs.

## PC decompilation cross-reference

These map this system's Xbox symbols to functions in the PC retail decomp (`output/_ghidra/all_functions_decomp.txt`). The resolver in `output/jul08_prototype/pairing/resolved_weapons-combat.txt` found **no** vtable-resolved classes for this system (weapon classes were compiled without surviving RTTI vtables, consistent with the "no RTTI" note above), so every match below is **string-anchored**. Confidence: a distinctive class-name string registered by a descriptor constructor = high; an enum/state string referenced inside a dispatcher = medium; a string shared by many functions = low.

The dominant pattern: each weapon component class has a tiny (~159-byte) **descriptor registrar** that fills a global descriptor struct — a `CopyFromStream` vtable pointer, the `0x9e3779b9` golden-ratio hash seed, pool size `0x100`, a record stride, and the class-name string — then calls the shared registrar `FUN_0064a770`. These are the PC-side equivalents of the Xbox component descriptors (`WeaponProjectileBase 384 128`, etc.).

| Symbol / class | PC function | Bridge | Role |
| --- | --- | --- | --- |
| WeaponProjectileBase | FUN_0063f390 | string | descriptor registrar (stride 0x28, name `s_WeaponProjectileBase`) |
| HomingWeapon | FUN_0063dc50 | string | descriptor registrar (stride 0x18, name `s_HomingWeapon`) |
| HomingProjectile | FUN_006438f0 | string | descriptor registrar |
| HomingTarget | FUN_00643990 | string | descriptor registrar |
| ProjectilePhysics | FUN_0063fc00 | string | descriptor registrar |
| WeaponBarrel | FUN_0063f2e0 | string | descriptor registrar |
| WeaponScatter | FUN_0063db10 | string | descriptor registrar |
| WeaponScope | FUN_0063fab0 | string | descriptor registrar |
| WeaponThrown | FUN_0063f8c0 | string | descriptor registrar |
| WeaponTrigger | FUN_0063f960 | string | descriptor registrar |
| WeaponUI | FUN_0063fa00 | string | descriptor registrar |
| WeaponEffects | FUN_0063dbb0 | string | descriptor registrar |
| WeaponRecoilVehicle | FUN_0063f230 | string | descriptor registrar |
| WeaponHint | FUN_00643280 | string | descriptor registrar |
| DamageKey | FUN_006429a0 | string | descriptor registrar (stride 0x4, name `s_DamageKey`) |
| ExplosionFudge | FUN_0063f180 | string | descriptor registrar |
| HomingLockStart / Update | FUN_0052dce0 | string | homing lock-state handler (emits LockClear/Start/Update events) |
| HomingLaunched / HomingLockClear | FUN_0052d120 | string | homing fire/launch path (emits HomingLaunched, HomingLockClear) |
| HomingLockClear (clear path) | FUN_0052e4b0, FUN_0052dce0 | string | lock-clear handlers |
| DamageObject / DamagePerson | FUN_005e0720 | string | damage-event field reader (DamagePerson/DamageObject/Hijack/Trespassing) |
| *…TypeEnum (all of them) | FUN_0064ac50 | string | global enum-table registry (low confidence: shared) |
| Enum value-list builders | FUN_006616c0, FUN_0065d6e0, FUN_0065d930, FUN_0065ca70, FUN_0065d4f0, FUN_0065f030 | string | per-enum value/name table builders (low) |

### Annotated excerpts

**FUN_0063dc50 — `HomingWeapon` descriptor registrar (the template for all weapon component registrars):**
```c
void FUN_0063dc50(void) {
  _DAT_017be618 = &PTR_CopyFromStream_00bc15e0;  // component (de)serializer vtable
  _DAT_017be63c = 0x18;                          // record stride (0x18 bytes)
  _DAT_017be644 = 0x9e3779b9;                    // golden-ratio hash seed
  _DAT_017be658 = 0x100;                         // pool size
  FUN_0064a770();                                // shared "register descriptor" call
  _DAT_017be654 = s_HomingWeapon_00bc54fc;       // class name string
}
```
Every weapon component (`WeaponProjectileBase` FUN_0063f390 stride 0x28, `DamageKey` FUN_006429a0 stride 0x4, etc.) is byte-for-byte this shape with a different stride and name. This confirms the Xbox component-descriptor table is built on the PC by ~16 of these one-shot registrars, each named by its class string. **High confidence** (the name string is unique to the class).

**FUN_0052dce0 — homing lock-state handler (medium confidence):**
```c
pcVar6 = s_HomingLockClear_00bb39c4;   // selected by lock-state branch
pcVar6 = s_HomingLockStart_00bb3a10;
pcVar6 = s_HomingLockUpdate_00bb39fc;
...
FUN_0052f0d0(s_HomingLockClear_00bb39c4, *(undefined4 *)(param_2 + 4), ...);  // fire event
```
This is the `HomingLockStart -> HomingLockUpdate -> HomingLockClear` state machine described in the Homing/lock-on section: it picks the event name by current lock state and dispatches it via `FUN_0052f0d0`. Its sibling FUN_0052d120 emits `HomingLaunched` on the actual missile launch.

**FUN_005e0720 — damage-event field reader (medium confidence):**
```c
FUN_0059f470(local_1c, s_DamagePerson_00bb3d48, &fStack_24);
FUN_0059f470(local_1c, s_DestroyPerson_00bb3d68, &fStack_24);
FUN_0059f470(local_1c, s_DamageObject_00bb3d58, &fStack_24);
FUN_0059f470(local_1c, s_DestroyObject_00bb3d78, &fStack_24);
FUN_0059f470(local_1c, s_Hijack_00bb3d88, &fStack_24);
```
It walks a small array (`puVar2`) of paired `{score,flags}` values and writes them out keyed by event name — `DamagePerson`, `DamageObject`, plus the wider reputation set (`Hijack`, `Trespassing`, `SpecialEvent`). This is the serializer for the damage/notoriety scoring block, not the per-hit damage applier (`ApplyDamage`, which is string-only and not resolved here).

**FUN_0064ac50 — global enum registry (low confidence, shared):**
This 16,897-byte function builds every reflection enum in the game by allocating a table, filling `{namehash, value}` pairs via `FUN_00824270`, and registering it by name (`thunk_FUN_004935d1`). It references this system's enum names — `WeaponProjectileTypeEnum`, `WeaponCouplingTypeEnum`, `WeaponUIReticleTypeEnum`, `HomingTypeEnum`, `ExplosiveDetailEnum`, `DamageKeyEnum` — but it is the engine-wide enum loader, not a weapons function. The per-enum value builders (`FUN_006616c0` etc.) populate individual value/name lists. Cite these only as "where the weapon enums are registered," not as weapon logic.

## Evidence & confidence

- **Count:** 77 symbols in `inventory/weapons-combat.txt`, all in `.rdata`. This doc cites all 77 inventory symbols by exact offset, plus ~120 additional confirming strings (descriptors, format strings, enum values, tunable field names) grepped from `mercs2_xenon_p.pe_full_strings.txt`, and 1 source path.
- **Verification:** Every cited inventory symbol/offset was read directly from the inventory file; a sample (`HomingWeapon::GuiEvent` 0x0021590, `WeaponProjectileBase` 0x003116c, `WeaponProjectileTypeEnum` 0x003ac84, `ClipGeneratorFlags` 0x00712a0, `AmmoValue` 0x003ba20, `DamagePerson` 0x0022d38) was re-grepped to confirm exact offset/text. The source path and every quoted string were grepped/read from the shared evidence files before writing.

What the evidence directly establishes: all 77 `.rdata` symbols exist at the cited offsets; `PgWeaponProjectile.cpp` is the system's build source file (assert at line 863); the `RuntimeWeapon` debug dump, equip dump, enum value lists, and tunable field names are present verbatim as quoted; and no weapons-combat class appears in the RTTI table (only Havok classes do).

A few interpretive points worth flagging: the trailing numeric pairs in the descriptor dump are read as pool counts/grow sizes. `ReloadAsset`/`ReloadLayer`/`ReloadAll` are asset hot-reload rather than magazine reload (magazine reload is the `RuntimeWeapon` `bReloading`/`iRoundsPerReload` path). `ClipGeneratorFlags` (0x00712a0) is most likely the Havok `hkbClipGenerator` animation feature, not a weapon magazine, and is treated as ambiguous. The `DamagePassthrough` (component) vs `DamagePassThrough` (field) split and the exact field-to-component mapping of individual tunables are reconstructed from naming rather than layout symbols, and the purpose of some single symbols (e.g. `ExplosionFudge`, `WeaponBarrel` internals) is not fully determinable from symbols alone.
