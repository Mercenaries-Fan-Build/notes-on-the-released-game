# Combat, vehicles, and economy — data gaps (UE5 recreation)

**Track:** item 8 (combat / vehicles / economy)  
**Date:** 2026-05-30  
**Status:** Scaffolding only (`game-scripts/setup_data_structs.py`); no verified WAD tables ingested.

## What exists today

| Area | In repo | Source |
|------|---------|--------|
| Weapon UI schema | `FWeaponData`, `DT_WeaponData` stub rows | `setup_data_structs.py` / `docs/data/mercs2_data_schema.json` |
| Mission objectives stub | `FMissionObjective`, `DT_TutorialMission` | Same |
| Faction enum | `EFaction` | Same |
| Vehicle meshes + Havok animgroups | Extraction pipeline | `vehiclenameanimgroup_*` / `vehicleclassanimgroup_*` blocks |
| Vehicle tokens (names) | Save/Lua harvest | `tools/savefile_parser.py` → `[vehicle.*]` tokens |
| Audio for weapons/vehicles | type_hash **wavebank**, **soundbank**, **sounddb** | `docs/type_hash_registry.md` |
| Lua economy hooks | `Player.GetCash` / `SetCash` | `docs/lua_engine_bindings_audit.md` (binding confirmed, values in scripts) |

## Extract from WAD (required for faithful gameplay)

These are **not** sufficiently represented by placement JSON or ECS merge alone. They live in dedicated blocks or `vz_state` enum tables and need typed parsers + export tools.

### Combat / weapons

| Data | Likely WAD location | Why extract |
|------|---------------------|-------------|
| Per-weapon stats (damage, ROF, mag, spread, range) | Weapon entity blocks + `vz_state` weapon overlays | Replace guessed `DT_WeaponData` rows |
| Projectile types | `WeaponProjectileTypeEnum` in loading/shell vz_state | Match Lua `Fire` / explosive behavior |
| Damage types / armor tables | Engine data blocks (hash-identified) | Vehicle/building damage |
| Ammo pickups / armory spawns | `layers_static` + mission overlays | World interactables |
| Explosion / impact VFX refs | UCFX in weapon/prop blocks | Gameplay feedback |

**Stub OK for now:** tutorial pistol/AK/M249/RPG rows in `DT_WeaponData`; generic `TakeDamage` on a future `Mercs2Character` base class.

### Vehicles

| Data | Likely WAD location | Why extract |
|------|---------------------|-------------|
| Vehicle definition (mass, seats, max speed, damage states) | `pmc_veh_*` / faction vehicle blocks | Physics and enter/exit |
| Havok vehicle skeleton + animgroup | Already partial in anim pipeline | Enter animations, turret poses |
| Weak points / `VehicleWeakPoint` vz_state COMP defs | vz_state schema tables | Combat targeting |
| Spawn / traffic hooks | Road graph + `Ai.SetLaneActive` Lua sites | AI traffic (depends on road graph tool) |
| Faction disguise rules | Tutorial Lua + player state | Stealth driving |

**Stub OK for now:** placeholder `WheeledVehiclePawn` Blueprint per category sample; no damage model.

### Economy / progression

| Data | Likely WAD location | Why extract |
|------|---------------------|-------------|
| Contract payouts | Lua `pmccon###` / briefing blocks | Mission rewards |
| Shop / PDA prices | `scaleform_pdavehiclesicons`, support icons + Lua | Vehicle/support purchases |
| Faction reputation | Lua + save format | `FFactionReputation` defaults |
| Unlock flags | Save profile + mission completion state | Content gating |

**Stub OK for now:** fixed starting cash in GameMode or Character; manual reputation map on `BP_Mattias`.

## Recommended extraction order

1. **Weapon names → hash map** — extend `enumerate_type_hashes` / ASET on weapon blocks; join to `DT_WeaponData` row IDs.
2. **Vehicle catalog JSON** — manifest from block stems + `vehicle_tokens` harvest + seat/entrance ECS where present.
3. **Lua contract economics** — parse `Player.GetCash`, reward literals from decompiled `pmccon*` scripts (no WAD, but verified strings).
4. **vz_state combat overlays** — spawn records in `flgs` already extracted; tie to `type_hash` resolution for entity class.

## UE5 mapping (when data exists)

| Game system | UE5 target |
|-------------|------------|
| Ballistic weapons | `UWeaponData` DataTable + `GameplayAbility` or simple line trace |
| Explosives | `UGameplayEffect` + projectile actor |
| Vehicles | `AWheeledVehiclePawn` + Chaos vehicle template |
| Economy | `UGameInstance` subsystem or `SaveGame` + UMG shop widgets |
| Traffic | Road graph JSON → splines + `MassTraffic` or custom AI path following |

See also `docs/gameplay_data_ue5_mapping.md` (sections 6–8) and `docs/character_systems_plan.md` for player-side weapon stance integration.
