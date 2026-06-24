# physics-game

Game <-> Havok integration bridge: `PgPhysics*` actors, `PgHavokManager`, human/ragdoll physics, raycasts/shapecasts, the grappling hook, winch, fluid "droplets", physics messages, and phantoms.

Provenance: All symbols/strings below are recovered from the Xbox 360 devkit "Profile" build `Mercs2_Xenon_P.exe` (Mercenaries 2: World in Flames, Jul 11 2008 preview, PowerPC). Evidence is from the decompressed PE and its extracted string/RTTI inventories — NOT a real `.pdb`. Pandemic's in-house engine is "Pangea" (`Pg*`); physics middleware is Havok (`hk*`/`hkp*`/`hka*`). Build tree root: `d:\projects\ReleaseLine\Mercs2\`.

## Overview

This subsystem is the **bridge layer** that wraps Havok for the game. It is not Havok itself (those `hk*` classes are catalogued under [havok-physics.md](havok-physics.md)); it is the Pangea code that drives Havok from gameplay. The two anchors are `PgHavokManager` (`oPgHavokManager`, `PgHavokManager::Update`) and the `PgPhysicsActor` family — a per-entity-kind set of physics-actor classes (`PgPhysicsActorHuman`, `PgPhysicsActorCar`, `PgPhysicsActorRagdoll`, `PgPhysicsActorTerrainMesh`, etc.) that own and update the corresponding Havok rigid bodies.

Around that core the symbols show several distinct services, all grounded in named symbols: a **raycast/shapecast API** (`CastRay`, `CastRayShapeBox/Sphere/Capsule/Cylinder`, `CastRayGroup`), **human locomotion physics** (`HumanPhysics`, `BeginHumanPhysicsStep`/`EndHumanPhysicsStep`, `HumanLinearCastJob`, `HumanIntegrateJob`), **ragdolls** (`PgPhysicsActorRagdoll`, `RagdollController`), the **grappling hook** (`PgSysGrapplingHook`, `GrapplingHookMessages`), a **winch** (`PgPhysicsActorWinch`, `AttachCargoToWinch`), a fluid **droplet** system (`Update PgPhysicsSystemDroplet`), a **constraint** layer (`ConstraintLink`, `BreakAllConstraints`), **phantoms** (`PhantomPtrs`, `SetPhantomShape`), and a **message handler** (`PgPhysicsMessageHandler`). Several of these system roles are read from the naming.

## Source files

The `source_paths.txt` list (48 paths) contains **no** physics-specific Pangea `.cpp` (e.g. no `PgPhysics*.cpp` is present). The only physics-relevant source paths recovered are Havok library files surfaced as assert strings (these belong to the Havok middleware, included here only because they are referenced from this bridge):

```
.\Constraint\Bilateral\hkpConstraintUtils.cpp
.\Utils\hkaRagdollUtils.cpp
..\Havok\Source\Common/Base/Memory/Memory/Malloc/hkMallocMemory.h
```

(The `Pangea\Src\Pg*.cpp` source paths that *are* present are for other systems — AI, sound, weapon projectile, game system — not physics.)

## Key classes

The RTTI list (`mercs2_xenon_p.rtti_classes.txt`) contains **only Havok classes**, no demangled `Pg*` physics classes. The `PgPhysics*` names below appear as `.rdata`/`.data` strings (vtable/type names or debug labels), not as `.?AV` RTTI descriptors. Havok classes that this bridge most directly stands on (full Havok class catalogue lives in [havok-physics.md](havok-physics.md)):

- `class hkpWorld` (`.?AVhkpWorld@@`), `class hkpRigidBody` (`.?AVhkpRigidBody@@`), `class hkpEntity` (`.?AVhkpEntity@@`)
- `class hkpWorldRayCaster` (`.?AVhkpWorldRayCaster@@`), `class hkpSimpleWorldRayCaster` (`.?AVhkpSimpleWorldRayCaster@@`), `class hkpWorldLinearCaster` (`.?AVhkpWorldLinearCaster@@`), `class hkpRayHitCollector` (`.?AVhkpRayHitCollector@@`)
- Phantoms: `class hkpPhantom`, `hkpAabbPhantom`, `hkpShapePhantom`, `hkpSimpleShapePhantom`, `hkpCachingShapePhantom`, `hkpPhantomListener`, `hkpPhantomBroadPhaseListener`, `hkpPhantomOverlapListener`
- Ragdoll/constraints: `class hkaRagdollInstance`, `hkpRagdollConstraintData`, `hkpRagdollLimitsData`, `hkpConstraintInstance`, `hkpConstraintData`, `hkpConstraintMotor`, `hkpBreakableConstraintData`, `hkpLimitedHingeConstraintData`, `hkpHingeConstraintData`, `hkpBallAndSocketConstraintData`, `hkpPrismaticConstraintData`
- Character locomotion: `class hkpCharacterProxy`, `hkpCharacterContext`, `hkpCharacterState*` (`InAir`/`Jumping`/`OnGround`), `hkpCharacterStateManager`

## Symbols by area

Offsets are quoted exactly as they appear in the inventory and the block0 string dump. Section is from the inventory where listed; block0-only entries are marked `(block0)`.

### Manager / core actor lifecycle

| Offset | Section | Symbol |
|--------|---------|--------|
| 0x0000eb4 | .rdata | `PgHavokManager::Update` |
| 0x000bdb | (block0) | `oPgHavokManager` |
| 0x0b8a3f4 | .data | `PgHavokData` |
| 0x0000c5c | .rdata | `PgPhysicsActor` |
| 0x0000cb0 | .rdata | `PgPhysicsActor::Init` |
| 0x000d18 | (block0) | `UpdatePgPhysicsActor` |
| 0x000c40 | (block0) | `PostUpdatePhysicsActors` |
| 0x000da0 | (block0) | `UpdateKeyframedPhysicsActors` |
| 0x0011d8 | .rdata | `PgPhysicsMessageHandler` |

The manager (`oPgHavokManager` global, `PgHavokManager::Update`) drives the Havok world step each frame; `PgPhysicsActor::Init`/`UpdatePgPhysicsActor`/`PostUpdatePhysicsActors` are the per-actor lifecycle. `PgHavokData` is a `.data` blob, likely serialized/global Havok state. `PgPhysicsMessageHandler` routes physics events.

### PgPhysicsActor type family

| Offset | Section | Symbol |
|--------|---------|--------|
| 0x0000cc8 | .rdata | `PgPhysicsActorRagdoll` |
| 0x00b608c | .rdata | `PgPhysicsActorProp` |
| 0x00b60a0 | .rdata | `PgPhysicsActorHuman` |
| 0x00b60b4 | .rdata | `PgPhysicsActorCar` |
| 0x00b60c8 | .rdata | `PgPhysicsActorTank` |
| 0x00b60dc | .rdata | `PgPhysicsActorHelicopter` |
| 0x00b60f8 | .rdata | `PgPhysicsActorTerrain` |
| 0x00b6110 | .rdata | `PgPhysicsActorBuilding` |
| 0x00b6128 | .rdata | `PgPhysicsActorPhantom` |
| 0x00b6140 | .rdata | `PgPhysicsActorJet` |
| 0x00b6168 | .rdata | `PgPhysicsActorBoat` |
| 0x00b617c | .rdata | `PgPhysicsActorRoad` |
| 0x00b61a8 | .rdata | `PgPhysicsActorTerrainMesh` |
| 0x00b61c4 | .rdata | `PgPhysicsActorDebris` |
| 0x00b61dc | .rdata | `PgPhysicsActorLowResTerrain` |
| 0x0005028 | .rdata | `PgPhysicsActorWinch` |

A polymorphic physics-actor per entity kind: characters (`Human`, `Ragdoll`), vehicles (`Car`, `Tank`, `Helicopter`, `Jet`, `Boat`), world geometry (`Terrain`, `TerrainMesh`, `LowResTerrain`, `Building`, `Road`), and dynamic objects (`Prop`, `Debris`, `Phantom`, `Winch`). The contiguous `0x00b608c..0x00b61dc` cluster reads as one vtable/typename table. Vehicle actors are detailed in [vehicles.md](vehicles.md).

### Raycasts / shapecasts

| Offset | Section | Symbol |
|--------|---------|--------|
| 0x0001958 | .rdata | `CastRay` |
| 0x0001960 | .rdata | `CastRayShapeCylinder` |
| 0x0001978 | .rdata | `CastRayShapeSphere` |
| 0x000198c | .rdata | `CastRayShapeCapsule` |
| 0x00019a0 | .rdata | `CastRayShapeBox` |
| 0x00019b0 | .rdata | `CastRayGroupSameStart` |
| 0x00019c8 | .rdata | `CastRayGroup` |
| 0x001630 | (block0) | `CastRayInsideBoundingPhantom` |
| 0x001650 | (block0) | `UpdateActionRaycasts` |
| 0x001108 | (block0) | `_CastRayWorkerMT` |
| 0x001138 | (block0) | `DelayedRayCasts` |

A game-side cast API over Havok: single ray (`CastRay`), shape-swept casts against Box/Sphere/Capsule/Cylinder, and batched casts (`CastRayGroup`, `CastRayGroupSameStart`). `CastRayInsideBoundingPhantom` ties casts to phantoms. `_CastRayWorkerMT` (a multithreaded worker) and `DelayedRayCasts`/`ProcessDelayedRaycasts`/`QueueDelayedRaycasts` indicate casts can be queued and processed off-frame. Quota asserts exist (see Notable strings). Related multithreading: [jobs-threading.md](jobs-threading.md).

### Human (player/NPC) physics

| Offset | Section | Symbol |
|--------|---------|--------|
| 0x0000e54 | .rdata | `HumanPhysics` |
| 0x0040e2c | .rdata | `HumanPhysics::Activate` |
| 0x0040e10 | .rdata | `HumanPhysics::Deactivate` |
| 0x000de8 | (block0) | `BeginHumanPhysicsStep` |
| 0x000dd4 | (block0) | `EndHumanPhysicsStep` |
| 0x00020a0 | .rdata | `HumanIntegrateJob` |
| 0x000208c | .rdata | `HumanLinearCastJob` |
| 0x000cfc | (block0) | `UpdatePgPhysicsActorHuman` |

Character-controller-style locomotion: `Begin/EndHumanPhysicsStep` bracket the step; `HumanIntegrateJob` and `HumanLinearCastJob` are the integration and swept-collision jobs, backed by Havok `hkpCharacterProxy`/linear-cast classes. `HumanPhysics::Activate`/`Deactivate` toggle a human's physics presence.

### Ragdoll

| Offset | Section | Symbol |
|--------|---------|--------|
| 0x0000cc8 | .rdata | `PgPhysicsActorRagdoll` |
| 0x0031da8 | .rdata | `RagdollController` |
| 0x0031da8 | .rdata | (string) `RagdollController 128 64` |

Ragdoll physics driven through `PgPhysicsActorRagdoll` + a `RagdollController`. Many supporting field names are present as strings: `ragdollSkeleton`, `ragdollInstance`, `ragdollMotors`, `ragdollBoneInfo`, `ragdollToAnimationSkeletonMapper`, `ragdollLeftFootBoneIndex`/`ragdollRightFootBoneIndex`, `removeRagdollFromWorld`, `LodRagdoll`, `FLAG_RAGDOLL`. Built on Havok `hkaRagdollInstance` / `hkpRagdollConstraintData` / `hkpRagdollLimitsData`. Skeleton/animation mapping detailed in [animation-skeleton.md](animation-skeleton.md).

### Grappling hook

| Offset | Section | Symbol |
|--------|---------|--------|
| 0x0001cac | .rdata | `PgSysGrapplingHook` |
| 0x001cc4 | (block0) | `GrapplingHookMessages` |

A dedicated subsystem (`PgSysGrapplingHook`) with its own message channel. Supporting strings: `Grapple`, `GrappleBullet`, `GrappleParameters`, `GrappleNode Sample`, `GrappleNode Update`, `Grapple Events`, `SetGrappleEnabled`, `DisableGrappleTriggered`, `projectile_grapple`, `Spawn2 "Grapple"`, and HUD context actions `[ContextAction.Grapple]` / `[ContextAction.StopGrapple]`. `eSpecialCase %d (0=none, 1=grapple, 2=flare, 3=laser)` enumerates grapple as a projectile special-case (weapon side: [weapons-combat.md](weapons-combat.md)).

### Winch

| Offset | Section | Symbol |
|--------|---------|--------|
| 0x0005028 | .rdata | `PgPhysicsActorWinch` |
| 0x000ce0 | (block0) | `UpdatePgPhysicsActorWinch` |

Winch / tow physics. Supporting strings: `AttachCargoToWinch`, `DetachCargoFromWinch`, `GetWinchState`/`SetWinchState`, `HasWinch`, `IsWinched`, `IsWinching`, `ObjectWinched`, `WinchBone`, `winch detach`, plus the descriptor strings `Winch 160 32` and `PhysicsActorWinch 16 16`. There is gameplay around it ("Winching Challenge"), apparently cargo/tow.

### Constraints

| Offset | Section | Symbol |
|--------|---------|--------|
| 0x00325f0 | .rdata | `ConstraintLink` |
| 0x00590c0 | .rdata | `ConstraintPriority` |
| 0x00591a4 | .rdata | `ConstraintType` |
| 0x005e888 | .rdata | `ConstraintSource` |
| 0x001868 | (block0) | `Create Constraints` |
| 0x0018c0 | (block0) | `BreakAllConstraints` |

A game-side constraint description layer (`ConstraintLink`/`RuntimeConstraintLink`, with `ConstraintType`/`ConstraintPriority`/`ConstraintSource` attributes), plus a large `CONSTRAINT_TYPE_*` enum (BALLANDSOCKET, HINGE, LIMITEDHINGE, POWEREDHINGE, RAGDOLL, POWEREDRAGDOLL, STIFFSPRING, PRISMATIC, WHEEL, PULLEY, GENERIC, BREAKABLE, MALLEABLE, CONTACT, POINTTOPATH, POINTTOPLANE, ...) that mirrors the Havok constraint set. `Create Constraints` / `BreakAllConstraints` / `EnableConstraint`/`DisableConstraint` are the lifecycle ops.

### Phantoms

| Offset | Section | Symbol |
|--------|---------|--------|
| 0x009a4b4 | .rdata | `PhantomPtrs` |
| 0x004530 | (block0) | `SetPhantomShape` |
| 0x000c6c | (block0) | `_UpdateBoundingPhantom` |

Phantom (trigger/overlap) volumes: `PhantomPtrs` table, `SetPhantomShape`, `_UpdateBoundingPhantom`, `CastRayInsideBoundingPhantom`, plus strings `LtUpdateFilterOnPhantom`, `BROAD_PHASE_PHANTOM`, `HK_SHAPE_PHANTOM_CALLBACK`. Built on Havok `hkpAabbPhantom`/`hkpShapePhantom` and `hkShapePhantom::setPosition`/`setTransform`.

### Fluid "droplet" system

| Offset | Section | Symbol |
|--------|---------|--------|
| 0x000d48 | (block0) | `Update PgPhysicsSystemDroplet` |

A separate `PgPhysicsSystemDroplet` updated each frame, with extensive debug counters (see Notable strings). The naming plus the link/neighbor counters point to a linked-particle/fluid-blob system (inferred — no decompiled body confirms the physics model).

### Collision handling / stabilization / listeners

| Offset | Section | Symbol |
|--------|---------|--------|
| 0x0002658 | .rdata | `CollisionStabilization` |
| 0x002f22c | .rdata | `CollisionHandling` |
| 0x009abc8 | .rdata | `CollisionListnr` |

Collision response plumbing: a stabilization pass (`CollisionStabilization`; cf. Havok `hkpStabilizedBoxMotion`/`hkpStabilizedSphereMotion`), general `CollisionHandling`, and a `CollisionListnr` callback. (`CollisionListnr` also surfaces in the PC decomp as an `hkpEntity` serialized member — see the cross-reference section.)

### Havok step / messaging / data load

| Offset | Section | Symbol |
|--------|---------|--------|
| 0x000e40 | (block0) | `HavokIntegrateJob` |
| 0x000e80 | (block0) | `HavokDeltaStep` |
| 0x000ea0 | (block0) | `HavokWorldUpdate` |
| 0x000e64 | (block0) | `HavokMessages` |
| 0x001704 | (block0) | `ReadHavokDataNew` |
| 0x0019d8 | (block0) | `AddHavokPAKDataNew` |
| 0x0018f4 | (block0) | `HavokModel::Setup` |
| 0x0018a8 | (block0) | `DeletePhysicsObjects` |
| 0x000c98 | (block0) | `_CreateWpPhysicsObjects` |

The world-step pipeline (`HavokDeltaStep` -> `HavokIntegrateJob` -> `HavokWorldUpdate`), an event channel (`HavokMessages`/`HAVOKMESSAGES`), and asset/data ingest (`ReadHavokDataNew`, `AddHavokPAKDataNew`, `HavokModel::Setup`) plus per-object create/delete (`_CreateWpPhysicsObjects`, `DeletePhysicsObjects`, `_WpPhysicsObjectList.Remove`). Job scheduling side: [jobs-threading.md](jobs-threading.md).

## Notable strings

Quota / capacity asserts (raycast budget):
- `Too many CastRay calls %i/%i`
- `Too many CastRayShape calls %i/%i`

Constraint conversion / validation asserts (from `hkpConstraintUtils.cpp` / `hkaRagdollUtils.cpp`):
- `Cannot convert constraint "` ... `" to a powered constraint.`
- `Only limited hinges and ragdoll constraints can be powered.`
- `Couldn't find constraint for bone : `
- `Found more than one constraint between rigid bodies `

Physics-load / island health markers (`%d bodies in one island` = a Havok simulation-island size warning):
- `Physics alert LOW. (%d bodies in one island)`
- `Physics alert MEDIUM. (%d bodies in one island)`
- `Physics alert HIGH. (%d bodies in one island)`

Droplet debug counters:
- `Selected Droplet - Furthest neighbor dist: %.3f`
- `?333Selected Droplet - Num Links: %i`
- `Never used droplets available: %i`
- `Garbage droplets available: %i`
- `NumMovingDroplets: %i`
- `NumStuckDroplets: %i`

Struct descriptor lines (name + sizes, layout/alloc tags; the exact meaning of the two trailing integers is not pinned down):
- ` RagdollController 128 64 `
- ` PhysicsActorRagdoll 128 64 `
- ` Winch 160 32 `
- ` PhysicsActorWinch 16 16 `
- ` GrappleParameters 64 64 `
- ` ConstraintLink 32 32 ` / ` RuntimeConstraintLink 32 32 `

Projectile special-case enum (grapple is value 1):
- `      eSpecialCase       %d (0=none, 1=grapple, 2=flare, 3=laser)`

Havok memory header path referenced from this layer:
- `..\Havok\Source\Common/Base/Memory/Memory/Malloc/hkMallocMemory.h`

Notable field-name strings (ragdoll/raycast tunables): `ragdollBoneLayers`, `ragdollLayer`, `ragdollFrame`, `ragdollAnkleIndex`, `ragdollShoulderIndex`, `raycastLayer`, `raycastInterface`, `raycastDistanceUp`/`raycastDistanceDown`, `floorRaycastLayer`, `iterativeLinearCastMaxIterations`, `iterativeLinearCastEarlyOutDistance`.

## How it works (decompiled)

VAs are from `output/_ghidra_x360/xenon_decomp_named.c` (base `0x82000000`); snippets are copied verbatim. The big caveat this section establishes: most `PgSys*` / `*Messages` symbols in this doc resolve to **registration stubs** (engine-system slots and profiler timer zones), not the per-frame physics logic. The genuine bridge logic that *is* decompiled is the cast path and the ECS-component registrars.

### `PgSys*` names are engine system-slot registrars, not update loops

`PgSysVehicle` @`82373600`, `PgSysTurret` @`82372f20`, `PgSysGrapplingHook` @`8222d338` and `HumanStateMachine` @`823551e0` allocate a slot in the global engine-system bitmask `DAT_830f982c` and park their name + dependency handles:

```c
  // PgSysVehicle: claim a free bit in the 32-system mask, store the name
  if ((DAT_830f982c & uVar3) == 0) {
     DAT_830f982c = DAT_830f982c | uVar3;
     *(char **)(&DAT_830f98b0 + uVar2 * 4) = "PgSysVehicle";
  }
  *(uint *)(param_1 + 0x10) = uVar3;                       // system id back to caller
  uVar1 = FUN_8246cf08(0xffffffff830ff930, ...);           // wire dep: Car controller @830ff930
```
Note `PgSysVehicle` wires the same `830ff930` global the vehicle `CarTurn` verb enqueues into (see vehicles.md), tying the system to the Car controller. `PgSysGrapplingHook` @`8222d338` is the smallest case — it just lazily resolves one dependency handle into `param_1+0x10`. **These are setup, not the per-frame `Update`.** The actual `PgHavokManager::Update` / `UpdatePgPhysicsActor` per-frame bodies are *not* in the named set.

### `UpdateHumans` / `GrapplingHookMessages` are profiler-zone registrars (mislabelled)

`UpdateHumans` @`8236f410` and `GrapplingHookMessages` @`8222dd30` do **not** update humans or route grapple messages — they register a profiler timer zone (name + ARGB color) into the global zone table via the open-addressing insert `FUN_8290bc68` (see havok-physics.md):
```c
  // GrapplingHookMessages
  uVar1 = FUN_8290ba80(0xffffffff82001cc4);
  iVar2 = FUN_8290bc68(uVar1,0xffffffff83cb28f4,0x100);          // hash-insert into zone table
  *(ulonglong *)(&DAT_83cb20f4 + iVar2 * 8) = CONCAT44(0xff000000,uStack_1c); // color black
```
`UpdateHumans` registers a zone colored `0xff4763ff` and several sub-zones. The symbol recovery attached these gameplay names to the functions that merely *reference the name string*. Treat `UpdateHumans`/`GrapplingHookMessages`/`HumanStateMachine` as **zone/slot registrars** unless a body shows otherwise.

### The cast path: `CameraCollisionCastRay` is real ray-setup code

`CameraCollisionCastRay` @`825ea110` (420 B) is genuine bridge logic. It walks **5 camera collision records** at stride `0x620` and writes a 16-float matrix/ray block (`+0x10..+0x4c`) into each, then sets two squared-radius fields:
```c
  lVar2 = FUN_82916f38() + 0x20;  lVar5 = 5;            // 5 cameras
  do {
    iVar4 = FUN_8256eb28(lVar2);  iVar4 = *(int*)(iVar4+4)*0x70 + iVar4;
    *(float *)(iVar4 + 0x10) = (float)dVar6; ... +0x4c  // 16 floats: ray/transform
    lVar2 = lVar2 + 0x620;
  } while (lVar5 != 0);
  *(float *)(iVar4 + 0x1ed8) = fVar1 * fVar1;            // radius² (DAT_82b8a65c²)
```
Its tail then registers a profiler zone (same `DAT_83cb20f4` idiom) — so even a real function carries the registration boilerplate, which is why the registration pattern alone doesn't prove a function is "just" a stub.

### Physics ECS components are registered as streamable classes

The `PgPhysicsActor*` family is wired into the ECS/reflection loader by registrar functions. `PhysicsActorRagdoll` @`829f5490`:
```c
  FUN_824fd430(0xffffffff838071ec,8);
  DAT_838071ec = &PTR_FUN_82036228;                  // component vtable
  DAT_83807204 = &PTR_FUN_82030fa0;                  // shared CopyFromStream reader
  DAT_83807228 = "PhysicsActorRagdoll";              // class name
```
The identical shape registers `PhysicsActorWinch` @`829f5400`, `PhysicsActor` @`829f5370`, and the physics *properties* `PhysicsPropertyGravityScaler` @`829ed328`, `PhysicsPropertyUncrushable` @`829ed298`, `PhysicsPropertyFakeContinuous` @`829ed208` — all share the `PTR_FUN_82030fa0` stream reader, confirming the `PgPhysicsActor*` cluster is one polymorphic, stream-loaded component family (the doc's inference, now code-backed).

## Corrections & open questions

- **CORRECTION — `UpdateHumans` / `GrapplingHookMessages` / `HumanStateMachine` are registrars, not the named logic.** The doc's "Human (player/NPC) physics" and "Grappling hook" sections imply `BeginHumanPhysicsStep`/`HumanIntegrateJob`/`GrapplingHookMessages` carry the runtime behavior. The functions bearing those exact names are profiler-zone / system-slot registrars (VAs + snippets above). The actual human-step and grapple-message dispatch bodies are **not** in the named set.
- **CORRECTION — `PgSysGrapplingHook`/`PgSysVehicle`/`PgSysTurret` are system-slot setup, not `Update`.** They claim a bit in `DAT_830f982c` and store dependency handles; no per-frame work is in these bodies.
- **CONFIRMED — `PgPhysicsActor*` is one polymorphic stream-loaded component family (was inferred "single vtable/type table").** All variants register through the same `PTR_FUN_82030fa0` reader with only the vtable + name differing (VAs above).
- **CONFIRMED — camera collision uses a 5-camera cast record at stride 0x620.** Concrete offsets from `CameraCollisionCastRay` (above); previously the cast API was symbol-only.
- **UNKNOWN — the `PgPhysicsSystemDroplet` physics model.** No decompiled body in the named set implements the droplet/fluid update; the "linked-particle" reading remains inference (only the debug-counter strings exist).
- **UNKNOWN — `Too many CastRay calls %i/%i` budget values and the delayed-raycast queue mechanics.** The assert strings name the quota but the cast-budget constant and the `DelayedRayCasts` processing body are not in the named/decoded set (VMX-truncated worker `_CastRayWorkerMT`).
- **XBOX↔PC NOTE.** The PC cross-ref maps `RagdollController`/`PhantomPtrs`/`CollisionListnr` to Havok serializers; the Xbox side adds the ECS-component registrars (`PhysicsActorRagdoll` etc.) and the system-slot setup, but **neither build exposes the per-frame `PgHavokManager::Update`** as a named, fully-decoded function — consistent across both decompilations.

## Cross-references

- [havok-physics.md](havok-physics.md) — the underlying Havok middleware (`hk*`/`hkp*`/`hka*` classes); this bridge sits on top of it.
- [jobs-threading.md](jobs-threading.md) — `HumanIntegrateJob`, `HumanLinearCastJob`, `HavokIntegrateJob`, `_CastRayWorkerMT`, delayed-raycast queue.
- [animation-skeleton.md](animation-skeleton.md) — ragdoll <-> animation skeleton mapping (`ragdollToAnimationSkeletonMapper`, bone indices).
- [vehicles.md](vehicles.md) — vehicle `PgPhysicsActor*` (Car/Tank/Helicopter/Jet/Boat) and winch/tow gameplay.
- [weapons-combat.md](weapons-combat.md) — `GrappleBullet`/`projectile_grapple` projectile side of the grappling hook.
- Existing project docs that overlap: `docs/ecs_components.md` and `docs/mercs2-ecs/03_controllers_physics.md` (ECS-side physics/controller components); `docs/coordinate_systems.md`.

## PC decompilation cross-reference

These map this system's Xbox symbols to functions in the PC retail decomp (`output/_ghidra/all_functions_decomp.txt`). Coverage here is thin: the resolver found **no** vtable-resolved classes for physics-game (the `Pg*` RTTI vtables were stripped from the release build, consistent with the RTTI section above showing only `hk*` descriptors), and only **3 string-anchored** functions. All three turn out to be Havok reflection/serialization writers (they walk an object's fields and emit `name,type,ptr,count` tuples through a vtable callback), where the anchoring string is a Havok struct *member name* — not a Pangea bridge method. Treat these as low/medium confidence leads into the Havok layer, not as the named Pg* functions.

| Symbol / class | PC function | Bridge | Role |
|----------------|-------------|--------|------|
| `RagdollController` | `FUN_00648130` | string | descriptor/registration init — stores `s_RagdollController_00bc5eb0` into a global record |
| `PhantomPtrs` | `FUN_008d7b80` | string | Havok `hkpWorld` reflection/serialize writer (emits `PhantomPtrs`, `Phantoms`, islands, locks) |
| `CollisionListnr` | `FUN_008dd8a0` | string | Havok `hkpEntity`/`hkpRigidBody` reflection/serialize writer (emits `CollisionListnr`, listener arrays) |

Confidence: all three are **medium-to-low** — single distinctive string each, and `PhantomPtrs`/`CollisionListnr` are generic Havok member names rather than unique Pg* identifiers.

Annotated excerpts:

`FUN_00648130` (`RagdollController`) — a small init/registration routine that fills a global descriptor record and parks the type name into it:

```c
_DAT_017c0508 = &PTR_CopyFromStream_00bc4468;   // stream-copy vtable for this type
_DAT_017c0520 = &PTR_FUN_00bc5ff8;
FUN_0064a770();
_DAT_017c0544 = s_RagdollController_00bc5eb0;    // <- the anchoring "RagdollController" string
```

The `CopyFromStream` pointer plus a 0x9e3779b9 (golden-ratio hash constant) and a name string is the engine's per-type registration shape — this is where `RagdollController` is registered as a streamable type, not the controller's per-frame logic.

`FUN_008d7b80` (`PhantomPtrs`) is a Havok `hkpWorld` serializer. It dispatches through `param_2`'s vtable to emit each member by name:

```c
(**(code **)(*param_2 + 4))(s_hkpWorld_00b35f18,2,param_1);     // this object IS an hkpWorld
...
(**(code **)(*param_2 + 8))                                      // emit the PhantomPtrs array
          (s_PhantomPtrs_00b58f58,4,*(undefined4 *)(param_1 + 0xe4),
           *(int *)(param_1 + 0xe8) * 4,*(int *)(param_1 + 0xec) * 4);
```

So `PhantomPtrs` here is the `hkpWorld` member that holds the phantom pointer table (`param_1+0xe4` = ptr, `+0xe8` = count) — confirming the bridge's phantom volumes live on the world object, but the function itself is Havok-side serialization.

`FUN_008dd8a0` (`CollisionListnr`) is the matching `hkpEntity`/`hkpRigidBody` serializer; it emits the entity's collision-listener and listener arrays the same way (`s_CollisionListnr_00b59410`, `s_EntityListeners_00b593e8`, `s_ActivatonListners_00b593d4`).

## Evidence & confidence

Distinct symbols cited from the evidence files: ~70 (43 inventory entries in `physics-game.txt`, plus block0-string and full-string symbols verified by grep). Sections seen: `.rdata` (the bulk of named symbols), `.data` (`PgHavokData` only), and the `block0` debug-string region (function/marker names with offsets).

Symbols/strings recovered verbatim from the evidence:
- All `PgPhysicsActor*`, `PgHavokManager::Update`, `oPgHavokManager`, `PgHavokData`, `PgPhysicsMessageHandler`.
- The full `CastRay*` API, `HumanPhysics*`, `HumanIntegrateJob`, `HumanLinearCastJob`, `PgPhysicsActorRagdoll`, `RagdollController`, `PgSysGrapplingHook`, `GrapplingHookMessages`, `PgPhysicsActorWinch`, `Update PgPhysicsSystemDroplet`, `ConstraintLink`/`ConstraintType`/`ConstraintPriority`/`ConstraintSource`, `PhantomPtrs`, `CollisionStabilization`/`CollisionHandling`/`CollisionListnr`.
- All quoted asserts/format strings/counters, verbatim.
- RTTI descriptors exist only for the Havok (`hk*`) classes, not for `Pg*` physics classes.

Inferences (not directly proven by a symbol):
- The `PgPhysicsActor*` name cluster being a single vtable/type table.
- The exact role of `PgHavokData` (`.data`), `PgPhysicsMessageHandler`, `CollisionListnr`, and the meaning of the two trailing integers in the ` Name N M ` descriptor strings.
- That `PgPhysicsSystemDroplet` is fluid/linked-particle physics (named "droplet" + link/neighbor counters).
- That winch drives cargo/tow gameplay, and that delayed raycasts run off-frame.
- The job/MT decomposition mapping (`HumanIntegrateJob` etc. as actual Havok jobs) — inferred from naming, threading details belong to [jobs-threading.md](jobs-threading.md).
