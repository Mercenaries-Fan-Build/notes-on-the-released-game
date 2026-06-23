# Vehicles

Vehicle simulation and tuning — the per-class drive models (car/bike/heli/tank/boat/water), their Havok-backed physics actors, and the large set of designer-facing tuning parameters (engine, gears, steering, springs, wheels, brakes, turrets, donut/wheelie tricks).

Provenance: All symbols and strings below were extracted from the recovered Xbox 360 preview executable `Mercs2_Xenon_P.exe` (Mercenaries 2: World in Flames, Jul 11 2008 devkit "Profile" build, PowerPC). This is string/symbol evidence from the binary, not a real `.pdb`. Build source tree was `d:\projects\ReleaseLine\Mercs2\`; the in-house engine is "Pangea" (`Pg*`), physics is Havok (`hk*`/`hkp*`). Offsets are PE offsets as they appear in `output/jul08_prototype/inventory/vehicles.txt`.

## Overview

This subsystem covers how drivable vehicles move and how their handling is authored. Three layers are visible in the symbols:

1. **Action/control classes** — `*Action` and `Tt*Action` symbols (`BikeAction`, `HeliAction`, `TankAction`, `CarAction`, `BoatAction`, `TtCarAction`, `TtHeliAction`, `TtBoatAction`, `TtTankAction`, `TtWaterAction`) that drive a vehicle each frame, plus per-control verbs (`CarTurn`, `CarAccelerate`, `HeliElevate`, `BoatTurn`, `TurretAim`, etc.).
2. **Physics actors** — `CarPhysicsV2`, `TankPhysics`, `BoatPhysics` (with `Activate`/`Deactivate` methods) and the pool-presize sibling classes `_CarWheel`, `_HelicopterPhysics`, `_HelicopterPhysicsAi`, `_JetPhysics`, `_PropPhysics`. These are the rigid-body simulation objects each action drives.
3. **Tuning parameters** — a very large set of named float/int fields grouped under printed section headers (`GEARS AND ENGINE`, `STEERING`, `Springs`, `FRONT WHEEL`/`REAR WHEEL`, `MOTOR CYCLE`, `Drag and damp`, `Body behavior`). These are the richest tunable surface in the binary; they appear as space-padded reflection field-name strings (e.g. `EngineTorque                `, `GearRatio1                 `).

The `Tt*` prefix dominates a separate large cluster (`TtRayCast`, `TtSimulate`, `TtCollide`, `TtNarrowPhase`, `TtBroadphase`, `Tt*Cb` callbacks, `Ttrc*` ray-cast shapes). These are a Havok integration/threading layer that the `Tt*Action` vehicle classes are built on top of (inferred from the shared naming — see Evidence).

The only vehicle-relevant build source path present is `PgAiActHeli.cpp` (helicopter AI action).

## Source files

From `output/jul08_prototype/mercs2_xenon_p.source_paths.txt` (verbatim):

```
d:\projects\ReleaseLine\Mercs2\Pangea\Src\PgAiActHeli.cpp
```

Asserts/line markers referencing it (from the strings file):

```
d:\projects\ReleaseLine\Mercs2\Pangea\Src\PgAiActHeli.cpp(1079)
d:\projects\ReleaseLine\Mercs2\Pangea\Src\PgAiActHeli.cpp(1192)
```

No other vehicle-specific source path survives in the recovered table (no Car/Tank/Boat/Bike `.cpp` paths are present).

## Key classes

The recovered RTTI list (`mercs2_xenon_p.rtti_classes.txt`) contains **no** `.?AV`/`.?AU` mangled names for the vehicle action/physics classes — the vehicle class identifiers above appear only as plain `.rdata` symbol/string names, not as RTTI type descriptors. The only RTTI classes adjacent to this system are Havok base types that the vehicle physics actors build on:

- `.?AVhkpAction@@` -> `class hkpAction`
- `.?AVhkpUnaryAction@@` -> `class hkpUnaryAction`
- `.?AVhkpConstraintChainInstanceAction@@` -> `class hkpConstraintChainInstanceAction`
- `.?AVhkpPhysicsData@@` -> `class hkpPhysicsData`
- `.?AVhkpPhysicsSystem@@` -> `class hkpPhysicsSystem`
- `.?AVhkpPhysicsSystemWithContacts@@` -> `class hkpPhysicsSystemWithContacts`

These RTTI strings exist verbatim; the link to vehicle classes specifically is inferred from the shared `Tt*`/physics naming.

## Symbols by area

### Per-class vehicle action classes

| Offset | Section | Symbol |
|---|---|---|
| 0x0000e00 | .rdata | BikeAction |
| 0x0000e0c | .rdata | HeliAction |
| 0x0000e18 | .rdata | TankAction |
| 0x0000e24 | .rdata | CarAction |
| 0x00016e4 | .rdata | BoatAction |
| 0x00050a0 | .rdata | TtBoatAction |
| 0x0005184 | .rdata | TtCarAction |
| 0x000524c | .rdata | TtHeliAction |
| 0x00052ec | .rdata | TtTankAction |
| 0x00053d0 | .rdata | TtWaterAction |
| 0x00022d0 | .rdata | TtPgGravityScalerAction |

These are the per-vehicle-type simulation/action classes. The plain `*Action` names and the `Tt*Action` names co-exist; `TtWaterAction` adds a water/boat buoyancy path on top of `TtBoatAction`. `TtPgGravityScalerAction` is a gravity-tuning action. The strings `Tweaking is not available for this vehicle` and `Tweaking is not available for this object` indicate a live in-game tuning UI gates these. (Roles inferred from the names.)

### Control verbs (input -> action)

| Offset | Section | Symbol |
|---|---|---|
| 0x0023034 | .rdata | CarTurn |
| 0x002303c | .rdata | CarAccelerate |
| 0x002304c | .rdata | CarHandbrake |
| 0x002305c | .rdata | CarBrake |
| 0x0023068 | .rdata | CarClearControls |
| 0x002307c | .rdata | HeliClearControl |
| 0x0023090 | .rdata | HeliElevate |
| 0x002309c | .rdata | HeliTurn |
| 0x00230a8 | .rdata | HeliStrafe |
| 0x00230b4 | .rdata | HeliAccel |
| 0x00230c4 | .rdata | BoatTurn |
| 0x00230d0 | .rdata | BoatAccelerate |
| 0x00230e0 | .rdata | BoatClearControls |

Control-channel names, one set per drivable type. The control-type set is also reflected by the `*Ctrl` enum-ish symbols `BoatCtrl` (0x0013c18), `CarCtrl` (0x0013c24), `HeliCtrl` (0x0013c40), and `TurretControl` (0x0013c08).

### Turret control

| Offset | Section | Symbol |
|---|---|---|
| 0x0013c08 | .rdata | TurretControl |
| 0x0023188 | .rdata | TurretPoint |
| 0x0023194 | .rdata | TurretAim |
| 0x00231a0 | .rdata | TurretEnable |
| 0x00231b0 | .rdata | TurretDisable |
| 0x003248c | .rdata | TurretCoupling |
| 0x003acec | .rdata | TurretAxisEnum |
| 0x003b108 | .rdata | TurretCouplingTypeEnum |
| 0x003b170 | .rdata | TurretControlTypeEnum |
| 0x003ba60 | .rdata | TurretName |

Mounted-weapon aiming. The enum symbols (`TurretAxisEnum`, `TurretCouplingTypeEnum`, `TurretControlTypeEnum`) are the authored configuration choices for how a turret is hooked to its mount. The dedicated tank-turret action class appears in strings as `(TtPgTankTurretAction`. Turret/mount semantics are read from the names.

### Physics actors

| Offset | Section | Symbol |
|---|---|---|
| 0x004032c | .rdata | CarPhysicsV2 |
| 0x0040360 | .rdata | TankPhysics |
| 0x004103c | .rdata | CarPhysicsV2::Activate |
| 0x0041020 | .rdata | CarPhysicsV2::Deactivate |
| 0x0040ec4 | .rdata | BoatPhysics::Activate |
| 0x0040eac | .rdata | BoatPhysics::Deactivate |

Sibling physics/pool classes appear in the resident-pool presize log strings (not in the inventory's `.rdata` slice but present in the strings file as ` _Class size align ` reflection-size lines):

```
 _BoatPhysics 160 32
 _CarPhysicsV2 768
 _CarWheel 2304
 _HelicopterPhysics 160 32
 _HelicopterPhysicsAi 160 32
 _JetPhysics 8 8
 _PropPhysics 768
 _TankPhysics 128 64
```

The numbers are object size (and alignment, where present) used to presize the instance allocator. `CarPhysicsV2` ("V2") implies a prior car-physics implementation was replaced.

### Tuning parameters

These are the system's main payload. They appear as space-padded reflection field-name strings under printed section headers; the matching short symbols also appear in the inventory `.rdata`. Representative inventory symbols (offset/section verbatim):

Engine & torque curve:
| Offset | Symbol |
|---|---|
| 0x003d5ac | EngineTorque |
| 0x003d598 | EngineReverseTorque |
| 0x003d588 | EngineInertia |
| 0x003d574 | EngineTorqueRatio0 |
| 0x003d560 | EngineTorqueRatio1 |
| 0x003d54c | EngineTorqueRatio2 |
| 0x003d538 | EngineTorqueRatio3 |
| 0x003d524 | EngineTorquePos1 |
| 0x003d510 | EngineTorquePos2 |
| 0x00028cc | EngineTorqueMultiAtCollision |
| 0x003dfd0 | EngineOffsetY |

Gears:
| Offset | Symbol |
|---|---|
| 0x003dcd0 | GearRatioPrimary |
| 0x003dcbc | GearRatioReverse |
| 0x003dcb0..0x003dc80 | GearRatio1..GearRatio5 |
| 0x003dc74 | GearMaxRPM |
| 0x003dc68 | GearMinRPM |
| 0x003dc5c | GearOptRPM |
| 0x003dc4c | GearUpshiftRPM |
| 0x003dc38 | GearDownshiftRPM |
| 0x003dc2c | GearSlipRPM |
| 0x003dbbc..0x003db6c | GearTorqueMulti1..GearTorqueMulti5 |
| 0x003dbd0 | GearTorqueMultiReverse |

Steering:
| Offset | Symbol |
|---|---|
| 0x003df40 | SteerSpeed |
| 0x003df4c | SteeringInertia |
| 0x003d5cc | SteerInertia |
| 0x00002794 | SteerNoInputInertia |
| 0x003e03c | SteerInertiaNoInput |
| 0x003df5c | SteerDiffSignInertia |
| 0x003df74 | SteerMaxVisualAngle |
| 0x003df88 | SteerMaxAngle |

Springs / suspension:
| Offset | Symbol |
|---|---|
| 0x003e020 | SpringStrength |
| 0x003e030 | SpringDamp |
| 0x003ee40 | SpringDampening |
| 0x003dfe0 | SpringCmpLength |
| 0x003dff0 | SpringExpLength |
| 0x003d388 | SpringWaterSmoothing |
| 0x003d458 / 0x003d470 | SpringHiSpeedStrength / SpringLoSpeedStrength |
| 0x003d428 / 0x003d440 | SpringHiSpeedDampening / SpringLoSpeedDampening |
| 0x00002a5c / 0x00002acc | SpringHiSpeedStartOffset / SpringLoSpeedStartOffset |
| 0x003d488 / 0x003d4a0 | SpringHiSpeedEndOffset / SpringLoSpeedEndOffset |

Wheels / brakes:
| Offset | Symbol |
|---|---|
| 0x003b498 | WheelRadius |
| 0x003b758 | WheelAxleEnum |
| 0x003a238 | WheelBurnout |
| 0x003d624 | BrakeDrag |

Bike (motorcycle) handling:
| Offset | Symbol |
|---|---|
| 0x003d98c | BikeAirControlPitch |
| 0x003d9a0 | BikeAirControlYaw |
| 0x003d9b4 / 0x003d9c8 / 0x003d9dc | BikeExtraDampYaw / BikeExtraDampPitch / BikeExtraDampRoll |
| 0x003da38 | BikeWheeliePitch |
| 0x003da1c | BikeWheeliePitchStrengthUp |
| 0x000031f8 | BikeWheeliePitchStrengthDown |
| 0x000031d8 | BikeWheeliePitchHiSpeedRatio |
| 0x003d9f0 | BikeWheelieSideDamp |
| 0x003da04 | BikeWheelieSteerAbility |
| 0x003da4c | BikeRollStabilityStrength |
| 0x003da68 | BikeRollAngleFromInput |
| 0x003da80 / 0x003da98 | BikeRollAngleAtHiSpeed / BikeRollAngleAtLoSpeed |
| 0x003dab0 | BikeRollAngVelForMaxRoll |

Tricks / misc tuning:
| Offset | Symbol |
|---|---|
| 0x003db50 | DonutBoost |
| 0x003db5c | DonutSidePower |
| 0x003d7cc / 0x003d7dc | CarryJogSpeed / CarryWalkSpeed |
| 0x003d964 | CarMaxSlope |
| 0x003aa88 | CarMonsterTruck |

(Offsets/symbols are copied from inventory; the grouping and captions follow the field names.)

### Vehicle definition / parts / ammo / health

| Offset | Symbol |
|---|---|
| 0x003e464 | VehicleName |
| 0x003e470 | VehicleClass |
| 0x003268c | VehiclePart |
| 0x0039dec | VehiclePartType |
| 0x003b244 | VehicleAmmo |
| 0x003b250 | VehicleHealth |
| 0x002af6c | VehicleDisguise |
| 0x00313ec | VehicleDisguiseScale |
| 0x0002df20 | vehicleSinking |
| 0x003f4c8 | VehicleSpawnList |
| 0x003f4ec | VehiclesOnScreen |

Plus named breakable/skin part identifiers (e.g. `veh_armored_tank_turret`, `veh_armored_heli_rotor`, `veh_motorcycle_wheels`, `veh_civ_lrg_*`, `veh_boat_sml/med/lrg`) at 0x003a404–0x003a600 — these name model sub-parts for damage/disguise. `VehicleDisguise`/`VehicleDisguiseScale` support the disguise-vehicle gameplay; `vehicleSinking` is the boat/water destruction path.

### AI driving states (.data)

A block of `.data` symbols holds per-class AI behavior state names:

| Offset range | Symbols |
|---|---|
| 0x0c485b8–0x0c48918 | BoatStop, BoatMove, BoatAttack, BoatIdle |
| 0x0c48a50–0x0c49120 | CarStop, CarDriveRoads, CarMove, CarPassengerIdle, CarIdle, CarAttack, CarPursue |
| 0x0c49258–0x0c49a38 | HeliMove, HeliIdle, HeliDepart, HeliDeliver, HeliPickup, HeliAttack |
| 0x0c4c410–0x0c4c770 | TankMove, TankAttack, TankIdle, TankDriveRoads |
| 0x0c4c8a8–0x0c4c9c8 | TurretAttack, TurretIdle |

These are AI driving/combat states (note `CarDriveRoads`, `TankDriveRoads`, `HeliPickup`/`HeliDeliver`/`HeliDepart`). The matching source file `PgAiActHeli.cpp` confirms the heli set is AI-action code; the "AI state" reading is supported by that source path and the AI markers `Panic!`, `Dodge!`, `DriveOff!`.

### Havok integration / collision layer (Tt*)

A large cluster of `Tt*` symbols sits under this system: ray casts (`TtRayCast`, `TtRayCastGroup`, `TtRayCstCached`, `TtrcBox`, `TtrcTriangle`, `TtrcCylinder`, `TtSphereSphere`, `TtCapsuleTri`, `TtHeightField`, `TtMopp`…), simulation/threading (`TtSimulate`, `TtCollide`, `TtNarrowPhase`, `TtNarrowPhaseTOI`, `TtBroadphase`, `TtBuildJacTask`, `TtPostSimCb`, `TtWaitForSolverCallbacks`), and Havok callback registrars (`TtactAddCb`, `TtentAddCb`, `TtcpAddCb`, `TtworldDelCb`, …). Representative offsets: `TtRayCast` 0x00988a0, `TtSimulate` 0x009b438, `TtCollide` 0x009b50c, `TtNarrowPhase` 0x009b41c, `TtBroadphase` 0x009b808. Two symbols are explicitly Havok-method-named: `TthkpShapeCollection::getAabb` (0x0099cb4-region) and `TthkpAabbPhantom::linearCast` (0x009ac60). This is the physics/collision substrate the `Tt*Action` vehicle classes run on, read from the shared `Tt`/`hkp` naming and the `Tt*Action` membership in this same inventory.

## Notable strings

Printed section headers for the tuning UI (each groups the fields that follow):

```
GEARS AND ENGINE
STEERING
Engine and braking
Springs
FRONT WHEEL
REAR WHEEL
Wheel and suspension
MOTOR CYCLE
Drag and damp
Body behavior
ADVANCED DO NOT TOUCH
```

Additional tuning field names present as strings but **not** in the inventory `.rdata` slice (extra evidence of the breadth of the tunable set):

```
HandBrakeMomentumKeep / HandBrakeAntiSideDrag / HandBrakeSteerBoost / HandBrakeInertia / HandBrakeBoost
TorqueFactorAtMaxRPM / TorqueFactorAtMinRPM / ClutchDelayTime / RearToFrontTorqueDistrib / ReverseMaxSpeed
FrontWheelRadius / RearWheelRadius / FrontWheelSuspStrength / RearWheelSuspStrength / FrontWheelSuspDamp / RearWheelSuspDamp
FrontWheelSuspExpLength / RearWheelSuspExpLength / FrontWheelSuspCmpLength / RearWheelSuspCmpLength
FrontBrake / RearBrake / FrontBrakeFriction / RearBrakeFriction / FrontEmergencyBrake / RearEmergencyBrake
FrontWheelFrictionFwd / RearWheelFrictionFwd / FrontWheelFrictionSide / RearWheelFrictionSide
FrontRev180FrictionMulti / RearRev180FrictionMulti
HiSpeedGrip / HiSpeedSteerLoss / HighSpeedSteerLoss / HighSpeedSteerLossBrakeMulti / HighSpeedSteerLossNoThrottleMulti
LowSpeedLimit / LowSpeedSteering / LowSpeedSteerBoost / LowSpeedSteerSpeed / NoSpeedSteering / AirControlSteering
SuspSteerSwayAmp / ExtraInvisibleSuspension / GravityFactor / LinearDampening / AngDampeningX/Y/Z / Mass / CenterOfMassOffset
InertiaTensorX (def:2.0) / InertiaTensorY (def:1.0) / InertiaTensorZ (def:1.5)
```

Boat/water-specific tuning fields (strings):

```
WakeOffset / WakeSize / WakeLifeTime / WakeSpeed / WakeRate
OutOfWaterGravityFactorUp / OutOfWaterGravityFactorDown
PitchUpSpeed / PitchDownInertia / PitchFromAcceleration / RollInertia / RollFromTurning
HullFriction / ShallowDepth / ShallowLinDamp / ShallowAngDamp / ShallowT / InWaterT / WaterDepth
WaterDragFwd / WaterDragSide / WaterDragUp / VisRudderMaxAngle / VisRudderInertia
MaxSpeed / MaxSpeedReverse / CollisionStabilization
```

Helicopter flight tuning fields (strings):

```
MaxElevationSpeed / MaxFwdSpeed / MaxRightSpeed / FwdSpeedAcc / RightSpeedAcc / MaxYawSpeed / MaxRollFwd / MaxRollSide
RollAccel / PitchAccel / MaxPitch / YawAcc / YawDamp / HiSpeedYawLoss / LowSpeedYawSpeed / BankYawAmplification
MaxRollBank / BankSpeedLimit / FwdSpeedNoInputInertia
```

Debug/HUD format strings and asserts:

```
Speed (kph):%4.0f
0-100kph time: %.2f
%.2f (American speed %.2f)
RPM        : %.2f
Handbrake  : %.2f
Steer Input: %.2f
[Steer:%5.2f Acc:%.2f Brk:%.2f(e%.2f)]
DONUT!!
Tank Pitch: %.3f
Real InertiaTensorX/Y/Z %.3f
No wheels at the front axle found!
No wheels at the rear axle found!
No Hardpoint Transform: %s(%X)
Tweaking is not available for this vehicle
Tweaking is not available for this object
```

Wheel hardpoint names (model attach points):

```
hp_wheel_fl  hp_wheel_fr  hp_wheel_rl  hp_wheel_rr  hp_wheel_ml  hp_wheel_mr
```

Card/fanfare and spawn-related strings: `CardFanfareCommence`, `CardFanfareSetParameters`, `SendEvent_CardFanfare`, `RuntimeVehiclePart` (presize ` RuntimeVehiclePart 320 64 `, ` VehiclePart 4096 `).

(All strings above are present verbatim in `mercs2_xenon_p.pe_full_strings.txt`. Their grouping under the printed headers follows the order in which they appear in that file; the literal headers themselves are printed strings.)

## PC decompilation cross-reference

These map this system's Xbox symbols to functions in the PC retail decompilation (`output/_ghidra/all_functions_decomp.txt`), via the resolver output in `output/jul08_prototype/pairing/resolved_vehicles.txt`.

There are **no vtable-resolved classes** for this system: the resolver's `# vtable-resolved` section is empty, which is consistent with the RTTI finding above (the vehicle action/physics classes carry no recovered `.?AV` vtables, so no Class::vftable constructor could be matched). Everything below is **string-anchored** (medium/low confidence). The vehicle-specific anchors that resolve cleanly are the **reflection enum/field registrars** — small functions that name an enum or field and register its members. The much larger `Tt*` cluster also resolves, but those are the shared Havok physics/collision layer (registry-loaders referencing many strings), not vehicle methods per se.

| Symbol / class | PC function | Bridge | Role |
|---|---|---|---|
| VehicleDisguiseScale | FUN_006413f0 | string | reflection field-descriptor registrar (tags descriptor with `s_VehicleDisguiseScale`) |
| VehiclePartType | FUN_00665200 | string | enum registrar (names `s_VehiclePartType`, registers members) |
| WheelAxleEnum | FUN_006599c0 | string | enum registrar (names `s_WheelAxleEnum`, member `s_RearAxle`) |
| TurretControlTypeEnum | FUN_0065efb0 | string | enum registrar (names `s_TurretControlTypeEnum`) |
| TurretCouplingTypeEnum | FUN_0065f0c0 | string | enum registrar (names `s_TurretCouplingTypeEnum`) |
| CarMaxSlope | FUN_00658f60 | string | large field-init function; references `s_CarMaxSlope`/`s_MaxSlopeEnum` among many tuning defaults |
| TurretAxisEnum / TurretControlTypeEnum / TurretCouplingTypeEnum / VehiclePartType | FUN_0064ac50 | string | big reflection/enum-registry **dispatcher** (16,897 B); references these four turret/part enum-name strings (among many non-vehicle enums) — a registry, not a 1:1 method |
| Tt* Havok layer (TtSimulate, TtCollide, TtNarrowPhase, Ttrc*, Tt*Cb …) | many (see resolved_vehicles.txt) | string | shared Havok physics/collision substrate; multi-function clusters per symbol |

Confidence: the per-enum registrars (FUN_00665200, FUN_006599c0, FUN_0065efb0, FUN_0065f0c0, FUN_006413f0) are **medium** — each references a single, distinctive vehicle enum/field name string. FUN_0064ac50 is a **registry dispatcher**, not a specific method (it references the four turret/part enum strings, alongside many non-vehicle enums — but **not** WheelAxleEnum), so treat it as "where these enums are registered." The `Tt*` mappings are **low-to-medium** and belong to the physics doc more than here.

### Annotated excerpts

**FUN_006413f0 — `VehicleDisguiseScale` reflection field-descriptor registrar.** Builds a field descriptor struct, wires the engine's `CopyFromStream` reader and the 0x9e3779b9 (golden-ratio) hash seed used throughout the reflection system, then tags it with the field name:

```c
_DAT_017bd5d8 = &PTR_CopyFromStream_00bbf9f0;   // stream reader for this field
_DAT_017bd604 = 0x9e3779b9;                     // reflection name-hash seed
FUN_0064a770();
_DAT_017bd614 = s_VehicleDisguiseScale_00bc5098; // field name -> descriptor
```

This shows `VehicleDisguiseScale` is a stream-loaded reflection field (consistent with the tuning-parameter model in this doc), not a hand-coded method.

**FUN_006599c0 — `WheelAxleEnum` enum registrar.** Calls a member-add helper once per enum value, then names the enum and one member:

```c
FUN_00656210();                          // (x4: one call per axle enum member)
pcStack_24 = s_RearAxle_00bc8b24;        // member name
pcStack_28 = s_WheelAxleEnum_00bc8b30;   // enum name
FUN_00656720();
FUN_00649180(&PTR_PTR_00df7488,param_1,0,pcStack_28,&pcStack_28); // commit to registry
```

The same shape appears for `VehiclePartType` (FUN_00665200, `s_VehiclePartType`) and `TurretControlTypeEnum` (FUN_0065efb0, `s_TurretControlTypeEnum`) — confirming the Xbox enum symbols correspond to engine-registered reflection enums in the PC build.

**FUN_0064ac50 — reflection/enum-registry dispatcher.** A 16,897-byte function whose body references four vehicle turret/part enum-name strings (`s_TurretAxisEnum_00bc6788`, `s_TurretControlTypeEnum_00bc62ec`, `s_TurretCouplingTypeEnum_00bc6354`, `s_VehiclePartType_00bc7690`, plus many non-vehicle enums). It is *not* a per-enum method but the central registry where these enums are wired into the reflection system, which is why the resolver mapped those turret/part enum symbols onto this single address. Note `WheelAxleEnum`/`s_RearAxle` are **not** registered here — they resolve to FUN_006599c0 only (see above).

## Cross-references

- `docs/mercs2-pdb-analysis/physics.md` (inferred filename) — the Havok `Tt*`/`hkp*` substrate (`TtSimulate`, `TtCollide`, `hkpAction`, `hkpPhysicsSystem`) underlying the vehicle physics actors.
- `docs/mercs2-pdb-analysis/ai.md` (inferred filename) — the `.data` AI driving states (`CarDriveRoads`, `HeliPickup`, `TankAttack`) and `PgAiActHeli.cpp`.
- `docs/mercs2-pdb-analysis/weapons.md` (inferred filename) — `VehicleAmmo`, `TurretControl`/`TurretAim`, and `(TtPgTankTurretAction`; weapon source `PgWeaponProjectile.cpp` is in the source-path table.
- Existing project docs: `docs/mercs2-ecs/` and `docs/ecs_components.md` document the runtime ECS component registry; `VehiclePart`/`RuntimeVehiclePart`/`VehicleHealth`/`VehicleAmmo` here are the vehicle-side counterparts (component/part names) of that registry.

## Evidence & confidence

- **Source:** `output/jul08_prototype/inventory/vehicles.txt` (289 lines), plus grep-confirmed strings in `mercs2_xenon_p.pe_full_strings.txt`, RTTI in `mercs2_xenon_p.rtti_classes.txt`, and source paths in `mercs2_xenon_p.source_paths.txt`.
- **Sections:** the overwhelming majority of cited symbols are in `.rdata`; the AI driving-state block (`BoatStop` … `TurretIdle`) is in `.data`.
- **Verbatim evidence:** every symbol name, offset, source path, RTTI string, and quoted string above exists verbatim in the named evidence files. The physics-actor class set (`CarPhysicsV2`, `TankPhysics`, `BoatPhysics`, `_CarWheel`, `_HelicopterPhysics`, `_HelicopterPhysicsAi`, `_JetPhysics`, `_PropPhysics`) is confirmed by both `.rdata` symbols and the presize-log size strings. The tuning-field set and its printed section headers are confirmed strings.
- **What is inferred (not proven by a single symbol):** that the `Tt*` cluster is the Havok integration layer the `Tt*Action` vehicle classes are built on; that `CarPhysicsV2` superseded an earlier car-physics class; that the `.data` `*Move`/`*Attack`/`*Idle` names are AI states (supported but not proven by `PgAiActHeli.cpp` and the `Panic!`/`Dodge!` markers); that turret enums configure mount coupling; and all per-field semantic captions. No `.?AV` RTTI survives for the vehicle classes, so their inheritance is not recoverable from RTTI alone.
- No vehicle behavior was traced through disassembly here; this document is a symbol/string inventory, not a control-flow analysis.
