# Physics (Havok) — PC code map

**Scope:** the Havok 5.5.0-r1 physics runtime in retail PC `Mercenaries2.exe` and the Pangea
`PgPhysicsActor*` bridge that drives it — the `hkpWorld` object + broadphase, the collision-shape
family (box/sphere/capsule/MOPP/mesh/heightfield), the `hkpCharacterProxy` character controller and
its state machine, constraints (ragdoll + the grapple/winch tow layer), the `hkpUnaryAction` vehicle
actors, and the shared raycast/query API. Scoreboard **row 22**. Binds the Xbox-PDB symbol names
([`havok-physics.md`](../mercs2-pdb-analysis/havok-physics.md),
[`physics-game.md`](../mercs2-pdb-analysis/physics-game.md),
[`symbol-map.md`](../mercs2-pdb-analysis/symbol-map.md)) to concrete PC addresses.

Sibling maps: [`vehicle_code_map.md`](vehicle_code_map.md) (the nine actor classes + the custom
drive model — **not redone here**), [`world_streaming_code_map.md`](world_streaming_code_map.md)
(terrain GUID map, hibernation), [`asset_formats_code_map.md`](asset_formats_code_map.md) §7 (the
PHY2 Havok packfile on disk). Modernization spec: [`physics_havok_spec.md`](../modernization/physics_havok_spec.md).

**Binary:** unpacked SecuROM image `output/_ghidra/securom_dump/mercs2_unpacked.exe`, base `0x400000`.
Bodies read from `output/_ghidra/mercs2_unpacked.exe_decomp.txt` / `all_functions_decomp.txt`.

## 0. Boundary, method, and why this map is HIGH confidence

Three things make this the highest-confidence code map in the set:

1. **Havok ships RTTI on BOTH builds.** Unlike `Pg*` (RTTI-stripped on retail), every `hk*`/`hkp*`
   class writes its named `Class::vftable` in its constructor, and Ghidra recovered those vtable
   labels. So the Xbox-RTTI → PC-ctor pairing in `symbol-map.md` is **vtable-proven, not
   string-guessed** — **204 of 287 RTTI classes resolved**, the near-entirety Havok. A function that
   stamps `hkpCharacterProxy::vftable` *is* the character-proxy constructor. This map inherits that
   certainty for the shape/world/constraint/character surface.

2. **The Pangea bridge is the only stripped part** — the `PgPhysicsActor*` family carries no `Pg*`
   RTTI (only `.rdata` typename strings), exactly as on Xbox. Those rows are string-anchored
   (medium) or recovered structurally from the actor activate/add path (§5). The split is explicit
   per row.

3. **SecuROM is not a blocker** ([[securom-decompiled-not-a-blocker]]). The physics cluster
   `0x008a0000–0x00a50000` is fully unpacked in the dump; the only SecuROM-island calls in physics
   are TLS-heap allocs (`FUN_0088cb70`) and a couple of island-merge thunks (`thunk_FUN_032b0000`,
   `thunk_FUN_024bb890`) — noted where they appear, resolvable live.

**Confidence legend:** H = vtable-proven ctor or fully-read body; M = string-anchored or partially
read; L = inferred. "Married by" = vtable / string / structural / body.

### One-line result

The retail engine embeds the **complete Havok 5.5 dynamics + collision + constraint + character
stack**, recoverable class-for-class; on-foot movement is a real **`hkpCharacterProxy` swept-capsule
controller with a 5-state machine** (OnGround/InAir/Jumping + two game states), static world collision
is **MOPP + `WpMeshShape16`**, the shared query layer is **`hkpWorld::getClosestPoints` /
`getPenetrations` / `hkpWorldRayCaster`**, and grapple/winch/ragdoll are **`hkpConstraint*` tows** —
**but the per-frame integrator (`hkpWorld::step`) is VMX128/SSE and does not decode in either build**
(⚠ RE-CHECK 2026-07-06: on PC the "does not decode" for float-heavy functions was often a Ghidra
false-`noreturn` on the x87 `sqrt`/`abs` helpers that truncated the body at its first sqrt — clearing
it recovered the whole vehicle drive model; `hkpWorld::step` should be re-decompiled under that fix
before being called undecoded — see [`vehicle_code_map.md`] §0 + `RecoverSecuromCode.java`),
so there is a numeric oracle only for *outputs*, not the solver. This map = the row-22 reimpl target
(engine today has a terrain-heightmap capsule and nothing else — §7).

---

## 1. World, simulation, broadphase (the physics spine)

| Xbox RTTI class | PC ctor / fn | Married by | Role | Conf |
|---|---|---|---|---|
| `hkpWorld` | **`FUN_008d8340`** (+ `FUN_008d8470`, `FUN_008d8c70`) | vtable | world ctor; body is the canonical `{0,0,0x80000000}` `hkVector4` init run (gravity/AABB rows). `FUN_008d8c70` is the multi-listener/null-filter setup variant | H |
| `hkpWorldCinfo` | `FUN_008e2da0`, `FUN_008e2f50` | vtable | world create-info (gravity, broadphase size, `m_sizeOfToiEventQueue`, collision tolerance) | H |
| `hkpSimulation` | `FUN_008f2320` | vtable | base single-threaded simulation | H |
| `hkpContinuousSimulation` | `FUN_0092c4d0`, `FUN_0092c560` | vtable | continuous/ToI simulation (the shipped sim class) | H |
| `hkpMultiThreadedSimulation` | `FUN_008f75e0`, `FUN_008f7930` | vtable | MT simulation — the PIMP-driven path (`HavokIntegrateJob`) | H |
| `hkpSimulationIsland` | `FUN_008eb900`, `FUN_008ebc30` | vtable | per-island container; island link/merge helper `FUN_008eb8c0` | H |
| `hkpWorld::addAction` / addEntity-to-island | **`FUN_008dae30`** | body | registers an action/entity: calls `param->getEntities` (vtable+0x10), pushes the action ptr into each entity's action-list (`entity+0x1f8` growable array via `FUN_00894830`), links/merges the entities' simulation islands (`FUN_008eb8c0` + island-merge `thunk_FUN_032b0000`). Called from **every** actor activate (§5) | H |
| `hkpWorld` deferred-op processor | **`FUN_008f8af0`** (2375 B) | body | the post-step **pending-operation command queue**: a switch over op-codes 8–0x14 = addEntity/removeEntity, addAction/removeAction, addConstraint/removeConstraint, addPhantom/removePhantom, updateFilter. This is how add/remove during the step are deferred to a safe point | H |
| `hkpBroadPhase` | `FUN_00907c60`, `FUN_00907d90` | vtable | broadphase base | H |
| `hkp3AxisSweep` | `FUN_009347e0`, `FUN_00935670` | vtable | the concrete sweep-and-prune broadphase | H |
| `hkpBroadPhaseBorder` | `FUN_008fa620`, `FUN_008fa770` | vtable | world-edge border (keep-in-bounds; cf. vehicle actor D) | H |
| broadphase update ST / MT | `0x008f3a55` / `0x0092cb25` | string (`LtBroadPhase`, rdtsc+TLS markers) | per-frame broadphase update, single- vs multi-thread | M |
| `hkpCollisionDispatcher` | `FUN_008c4de0`, `FUN_008c4ef0` | vtable | builds the agent dispatch table | H |

**The per-frame step itself is UNLOCATED as decoded code** (§6): the integrator math is VMX128/SSE;
neither build names a `hkpWorld::step`/`integrate`. On PC the MT sim (`FUN_008f75e0`) is reached via
the Pimp job pool ([`pimp_job_system_code_map`](pimp_job_system_code_map.md)), and the deferred-op
queue `FUN_008f8af0` runs at the step boundary. `PgHavokManager::Update` (the wrapper that calls the
step) is **not** a named/decoded body on either build — consistent Xbox↔PC.

---

## 2. Collision shapes (static world + colliders)

| Xbox RTTI class | PC ctor | Married by | Notes | Conf |
|---|---|---|---|---|
| `hkpBoxShape` | `FUN_008a86c0` (`FUN_00a0cb70`) | vtable | half-extents | H |
| `hkpSphereShape` | `FUN_008a92b0` (`FUN_00a0d7a0`) | vtable | | H |
| **`hkpCapsuleShape`** | **`FUN_008a9d00`** (`FUN_00a0ca70`) | vtable | **the character-controller capsule** — the char builder allocs 7 of these (§4) | H |
| `hkpCylinderShape` | `FUN_008c2f20`, `FUN_008c2fc0` | vtable | | H |
| `hkpConvexVerticesShape` | `FUN_008bbaf0`, `FUN_008bbdb0` (`FUN_00a0cd20`) | vtable | destructible break-piece hulls (PHY2 `hull[i]`; fully decoded on disk — `physics_havok_spec` §1.4) | H |
| **`hkpMoppBvTreeShape`** | **`FUN_00a0cc30`** | vtable | **static non-convex world collision** (BV-tree over a child mesh) | H |
| `hkMoppBvTreeShapeBase` | `FUN_00a0cbd0`, `FUN_00a124b0` | vtable | base; runtime layout `+0x34` = mopp-code size, `+0x10` = mopp-info ptr (Xbox `TtrcMopp`) | H |
| `hkpMoppCode` | `FUN_00a439c0`, `FUN_00a439d0` | vtable | the MOPP bytecode blob (u8 array — must not be u32-swapped, [[phy2-havok-chunk-not-u32]]) | H |
| `hkpMeshShape` / `Fast` / `Storage` / `ExtendedMesh` | `FUN_00a0e060` / `FUN_00a0cd90` / `FUN_00a0b650` / `FUN_00a113c0` | vtable | triangle-mesh collision family (`WpMeshShape16` = the Pandemic 16-bit-indexed variant on disk) | H |
| `hkpSampledHeightFieldShape` | **`FUN_00a0e3d0`** | vtable | **terrain heightfield collision** | H |
| `hkpStorageSampledHeightFieldShape` | `FUN_00a09b80`, `FUN_00a09cb0`, `FUN_00a0a2f0` | vtable | stored heightfield samples | H |
| `hkpTriSampledHeightFieldBvTreeShape` / `Collection` | `FUN_00a0d4a0` / `FUN_008bf670` | vtable | BV-tree wrapper over the heightfield (the terrain-query shape) | H |
| `hkpHeightFieldAgent` | `FUN_008aefc0`, `FUN_008b0060` | vtable | narrowphase agent for heightfield contacts | H |
| `hkpListShape` / `ConvexList` / `MultiSphere` / `ConvexTransform` / `ConvexTranslate` / `Transform` / `Plane` | `FUN_008cb570` / `FUN_00a0c910` / `FUN_00a0d010` / `FUN_008cc480` / `FUN_008cbaf0` / `FUN_008cd08c` / `FUN_00a0d530` | vtable | compound/transform shape set | H |
| shape-type enum → string | **`FUN_008bfb60`** | body | `switch(id)` returning `HK_SHAPE_BOX/SPHERE/CAPSULE/MOPP/SAMPLED_HEIGHT_FIELD/…` (0x00–0x20). Used by agent-dispatch debug (`FUN_008c4150`, "GAgent handling types") | H |
| MOPP raycast VM | (Xbox `TtrcMopp` @`829b7c58`) | body | ray/shape-cast against MOPP; PC entry through the caster (§3) | M |

> **Correction to [`world_streaming_code_map.md`]:** `FUN_008bfb60` is the **shape-enum→string
> table**, not the "Havok sampled-heightfield" query. The actual terrain-collision shape is
> `hkpSampledHeightFieldShape` `FUN_00a0e3d0` + its tri-sampled BV-tree wrapper `FUN_00a0d4a0`; the
> narrowphase is `hkpHeightFieldAgent` `FUN_008aefc0`.

**Disk → shape:** the streamed world geometry becomes Havok shapes via the **PHY2 chunk = a Havok 5.5
packfile** ([`asset_formats_code_map`](asset_formats_code_map.md) §7, [[phy2-havok-chunk-not-u32]]):
`[u32 header][magic-searched packfile][trailing collision-wrapper]`. The packfile's `__classnames__`
resolves classes **by ASCII name** (why a blind u32 swap AV'd the loader). Break-piece hulls decode
fully; MOPP/`WpMeshShape16` are recognised but their internal tree/index layout is the on-disk work
item, not runtime code.

---

## 3. Raycast / query API (the shared layer for AI, camera, weapons, terrain)

| Xbox symbol / class | PC fn | Married by | Role | Conf |
|---|---|---|---|---|
| `LthkpWorld::getClosestPoints` | **`FUN_008db880`** | string+body | broad→narrow closest-points query (§8 excerpt) | H |
| `LthkpWorld::getPenetrations` | **`FUN_008dba60`** | string+body | penetration query — same shape, early-out on first hit (`param_4+4` flag) | H |
| `hkpWorldRayCaster` | `FUN_00415670`, `FUN_008d6330` | vtable | world raycast object (`CastRay`) | H |
| `hkpRayHitCollector` | `FUN_00416d40`, `FUN_008afec0` | vtable | ray-hit collector | H |
| `hkpClosestCdPointCollector` | `FUN_008d07a0` | vtable | closest-contact collector | H |
| `hkpAllCdPointCollector` / `hkpCdPointCollector` | `FUN_00424130` / `FUN_008aa880` | vtable | all-points / base collector | H |
| `hkHeightFieldRayForwardingCollector` | `FUN_008af94b` | vtable | terrain raycast forwarding | H |
| `CastRay` / `CastRayShape{Box,Sphere,Capsule,Cylinder}` / `CastRayGroup` (game API) | — | — | Pangea wrapper over the casters; budget-limited (`Too many CastRay calls %i/%i`); delayed/off-frame worker `_CastRayWorkerMT` | M (Xbox-named, PC bodies not isolated) |

Both `getClosestPoints`/`getPenetrations` open **`Stbroadphase` → `Stnarrowphase`** profiler scopes
(TLS ring-buffer, `rdtsc`), gather candidate pairs against an `hkpAabbPhantom` (`param_1+0x54`
vtable+0x40 = `calcAabb`/`getOverlappingPairs`), then for each non-self pair run the collision-filter
`isCollisionEnabled` (`world+0x70` filter, vtable+4) and dispatch the per-pair agent via a jump table
(`param_3 + 0x9a8 + shapeType*0x14`). This is the query surface AI-LOS, the 5-camera collision cast
(stride 0x620, `physics-game` §"How it works"), weapon hit-tests, and terrain floor-probes all share.

---

## 4. Character controller — `hkpCharacterProxy` + state machine (on-foot movement)

This is the single biggest recovery vs the Xbox docs: the on-foot controller is **fully decoded**.

| Xbox RTTI class | PC ctor | Married by | Notes | Conf |
|---|---|---|---|---|
| **`hkpCharacterProxy`** | **`FUN_0094f2c0`** (`FUN_0094f350`) | vtable | proxy ctor — stamps `hkpCharacterProxy::vftable` **plus** `hkpEntityListener::vftable` (`+2`) and `hkpPhantomListener::vftable` (`+3`); inits four `{0,0,0x80000000}` `hkVector4` slots; delegates to init `FUN_0094dd30` | H |
| proxy init / setCinfo | `FUN_0094dd30` | body | copies the char cinfo: shape phantom `@+0x30`, up-vector normalize `@+0x40..0x4c`, `maxSlopeCosine` via `_CIcos` `@+0xa4`, keep-distance/contact arrays; subscribes phantom overlap listener (`0x1300` tag) | H |
| `hkpCharacterContext` | **`FUN_0094d2e0`** (`FUN_0094d340`) | vtable | ties the proxy to the state machine; ctor arg = initial state id (2) | H |
| `hkpCharacterStateManager` | **`FUN_00951c20`** (`FUN_00951c60`) | vtable | registers states by id; `FUN_00951cb0` = registerState(id) | H |
| `hkpCharacterStateOnGround` | **`FUN_0094ce90`** | vtable | state 2; reads tunable globals `_DAT_00b5af50`/`_DAT_00b11f50`/`_DAT_00b58a1c` (gravity/friction/slope) | H |
| `hkpCharacterStateInAir` | **`FUN_0094d7b0`** | vtable | state 3; setters `FUN_0094d780`/`FUN_0094d760` (air control / gravity) | H |
| `hkpCharacterStateJumping` | **`FUN_00951ef0`** | vtable | state 1; jump-height setter `FUN_00951ed0` | H |
| game states 5, 6 (Climbing / Ladder-Flying) | vtables `PTR_FUN_00ba8f3c`, `PTR_FUN_00ba8f5c` | structural | two extra `hkpCharacterState`-derived states the game adds (built inline in the char builder, ids 5 & 6) | M |
| `hkpCachingShapePhantom` | `FUN_008e7d60`, `FUN_008e7da0` | vtable | the proxy's query phantom (built from the primary capsule) | H |

**Game-side builder `FUN_004255c0` (`HumanPhysics::Activate`, 3512 B, caller `FUN_0066a2c0`)** — the
concrete character-controller assembly, read end-to-end:
1. Allocates **7 `hkpCapsuleShape`** (`FUN_008a9d00`) into `this[0xae..0xb3]` — a primary standing
   capsule (radius from `FUN_005857e0` cinfo `[1]`, scaled by `DAT_00b92874`) plus crouch/step/probe
   variants; caps clamped by `DAT_00b92b58`.
2. Builds an `hkpCachingShapePhantom` (`FUN_008e7d60`) from the primary capsule → `this[0xad]`.
3. Builds the **game character-proxy subclass** via `FUN_004241c0` (allocates 0xf0, calls the Havok
   proxy ctor `FUN_0094f2c0`, then overrides vtable slots with game vtables `PTR_FUN_00ba8ee0/ef4/f08`
   — the Pangea `PgPhysicsActorHuman` wrapper) → `this[0xac]`.
4. Builds the **state machine**: manager `FUN_00951c20`, then registers OnGround `FUN_0094ce90` (id
   defaulted), InAir `FUN_0094d7b0` (id 2… via `FUN_00951cb0`), Jumping `FUN_00951ef0` (id 1), and
   the two game states (ids 5, 6); creates `hkpCharacterContext` `FUN_0094d2e0(mgr, 2)` → `this[0xb6]`.
5. Registers the actor into the ECS/hibernation (`FUN_00649c00`/`FUN_0064a090` name-registry) at the
   tail; computes an initial up-vector from the spawn quaternion.

So on-foot Mercs2 movement = **swept-capsule proxy + slope/step limits + a jump/air/ground/climb state
machine**, exactly the shape our engine's terrain-heightmap capsule must grow into (§7).

---

## 5. The `PgPhysicsActor` bridge + `hkpUnaryAction` actors

**Base action:** `hkpUnaryAction` dtor `FUN_008e83e0`, base ctor **`FUN_008e83a0(body, userData)`**
(vtable slot 0 dtor, 1/2 = `hkReferencedObject` addRef/release `0x88c5b0`/`0x88c600`, **slot 3 =
applyAction(stepInfo)**). All nine vehicle actors derive from it — **see
[`vehicle_code_map.md`](vehicle_code_map.md) §3 for the full table and the drive math** (Car
`FUN_0044db60`, Boat `FUN_00447260`, Heli `FUN_00453760`, Tank `FUN_00454d80`, + boundary/CCD/
gravity-scaler/yaw-servo/buoyancy). Not redone here.

**Actor Activate/add — one shared shape (structural, READ):** the per-class activators are the
`PgPhysicsActor*` ↔ Havok bridge. Car `FUN_00437080`, Boat `FUN_00435660`, Heli `FUN_00439540`, and
the yaw-servo build `FUN_00510ff0` (from `FUN_00512e90`) all do:

```
gate on FUN_004332f0(owner)            // world present / not hibernated
alloc size from FUN_0088cb70(sz, 0x29) // TLS physics heap (0x29)
FUN_008e83a0(chassisBody, 0)           // hkpUnaryAction base ctor
*actor = &PTR_FUN_00baaXXX             // per-class actor vtable (baa360 car, ba9340 boat, ba9858 heli, baa4c4 servo)
per-class ctor (FUN_00449460 car / FUN_004465e0 boat / FUN_00439850 heli)
link actor into chassisBody+0xc        // the body's action list
if (body+0x34 world && world+8) FUN_008dae30(actor)   // hkpWorld::addAction (§1)
```

Deactivate zeroes `entity+0x140`/`+0x158` and releases (lazy create/destroy tied to
streaming-hibernation). This is the concrete `PgPhysicsActor` = *(Pangea entity ↔ hkpRigidBody +
hkpUnaryAction)* binding; the actor `userData`/`m_entity` (`+0x18`) is the chassis rigid body.

**Ragdoll bridge:** `RagdollController` stream-class registrar **`FUN_00648130`** (string-anchored) —
writes `{CopyFromStream vtbl PTR_FUN_00bc4468, stride 0x100, count 8, 0x9e3779b9 seed, name ptr}`,
identical registrar shape to the physics-actor descriptors in [`vehicle_code_map`](vehicle_code_map.md)
§2. This registers `RagdollController` as a stream-loaded ECS component; the ragdoll itself is
`hkaRagdollInstance` (`FUN_0088c000`) + `hkpRagdollConstraintData` (§6). Death/impact swaps the human
from the character proxy (§4) to the ragdoll instance (`ragdollToAnimationSkeletonMapper`,
`removeRagdollFromWorld` per `physics-game` §Ragdoll).

**PC-side note (Xbox↔PC):** `PgPhysicsActor*` carries **no RTTI on retail** (same as Xbox — only
`.rdata` typename strings `PgPhysicsActorHuman/Car/Ragdoll/Winch/…`). The bridge internals
(`PgHavokManager::Update`, `UpdatePgPhysicsActor`, the droplet system) are **not decoded** in either
build; the recovered surface is the actor-add path above + the ECS registrars.

---

## 6. Constraints — ragdoll, and the grapple/winch tow

| Xbox RTTI class | PC ctor | Married by | Notes | Conf |
|---|---|---|---|---|
| `hkpConstraintInstance` | `FUN_008e4980`, `FUN_008e49f0` | vtable | the runtime constraint (binds bodyA/bodyB + data) | H |
| `hkpConstraintData` (motor base) | `FUN_008df750` | vtable | shared motor/position ctor | H |
| `hkpBallAndSocketConstraintData` | `FUN_008e5f30` | vtable | point-to-point (grapple/winch tether candidate) | H |
| `hkpHingeConstraintData` | `FUN_008e5d80` | vtable | | H |
| `hkpLimitedHingeConstraintData` | `FUN_008dfc30`, `FUN_008dff50` | vtable | powered-hinge base for ragdoll prep | H |
| `hkpRagdollConstraintData` | `FUN_008e2950`, `FUN_008e2a00` | vtable | the ragdoll joint | H |
| `hkpRagdollLimitsData` | `FUN_008e9940` | vtable | cone/twist limits | H |
| `hkpPrismaticConstraintData` | `FUN_008e0540`, `FUN_008e05c0` | vtable | sliding (winch cable extend candidate) | H |
| `hkpBreakableConstraintData` | `FUN_008e4390`, `FUN_008e4410` | vtable | destruction break-away | H |
| `hkpGenericConstraintData` | `FUN_008e62e0`, `FUN_008e6320` | vtable | | H |
| `hkpStiffSpringConstraintData` (motor) | `FUN_008df700`/`FUN_008df750` | vtable | spring tether (grapple rope candidate) | H |
| `hkaRagdollInstance` | `FUN_0088c000`, `FUN_0088c0a0` | vtable | the skeletal ragdoll | H |
| ragdoll powered-constraint builder | **`FUN_009463a0`** | body | `prepareSystemForRagdoll` — per bone builds a **hinge (0xe0)** or **ragdoll (0x140)** constraint; emits the asserts `"Cannot convert constraint … to a powered constraint."` / `"Only limited hinges and ragdoll constraints can be powered."` (`hkpConstraintUtils.cpp`) | H |
| constraint pivot query | `FUN_00945f30` | body | reads pivotA/pivotB per constraint type; assert `"Unsupported type of constraint in prepareSystemForRagdoll()"` | H |

**Grapple hook + winch (game constraint layer).** The game-side `ConstraintLink` /
`RuntimeConstraintLink` layer (descriptor `ConstraintLink 32 32`) mirrors the Havok set via a
`CONSTRAINT_TYPE_*` enum (BALLANDSOCKET/HINGE/LIMITEDHINGE/RAGDOLL/STIFFSPRING/PRISMATIC/PULLEY/
BREAKABLE/…) with `Create Constraints`/`BreakAllConstraints`/`EnableConstraint`/`DisableConstraint`
lifecycle. The **grapple** (`PgSysGrapplingHook`, `GrappleParameters 64 64`, projectile
`eSpecialCase 1`) and **winch** (`PgPhysicsActorWinch`, `Winch 160 32`, ECS `Winch` component
`FUN_006393c0` stride 0x2c ≈ cable length + max tension + spring/damp + attach offsets;
`AttachCargoToWinch`/`DetachCargoFromWinch`/`ObjectWinched`/`WinchBone`) are **constraint-driven tows**
built through this layer onto the Havok constraint ctors above.

> **OPEN / unlocated:** the exact PC bodies that *create* the grapple and winch constraints are **not
> isolated** — the `PgSysGrapplingHook`/`GrapplingHookMessages`/`UpdatePgPhysicsActorWinch` symbols
> resolve to **registrar/profiler-zone stubs on both builds** (`physics-game` §"How it works"), not
> the tow logic. The tow is *provably* one of the constraint ctors above (ball-socket or
> stiff-spring tether + prismatic reel); pinning which requires the confirm-live break (§9). The
> `Winch` component's 44-byte tuning layout is UNKNOWN (`03_controllers_physics.md`).

---

## 7. Reconciliation with `mercs2_engine` (row 22 = ❌ sim)

Per [`engine_support_inventory.md`](../modernization/engine_support_inventory.md), row 22 Physics is
**absent as simulation**. The engine today has a **terrain-heightmap capsule sampler only** (a
kinematic ground-follow probe, [[world-terrain-loader]] / [[world-streaming-spec]]) — no rigid
bodies, no broadphase, no character-proxy state machine, no constraints, no raycast/query layer, no
actors. This map is the reimpl target. Mapping (per [`physics_havok_spec.md`], recommendation =
**adopt `rapier3d`, driven by extracted collision data**, do NOT reimplement the HK550 solver):

- **World + broadphase** (§1) → rapier `PhysicsPipeline` + `BroadPhase`; the deferred-op queue
  `FUN_008f8af0` → rapier's command/island bookkeeping. The **step is not a numeric oracle** (VMX
  undecoded) — gate on observable outputs only.
- **Shapes** (§2) → rapier `Collider` (convex hull / trimesh / capsule / heightfield). PHY2 hulls
  decode today; MOPP → recover source triangles / use `WpMeshShape16`, let rapier rebuild its BVH.
- **Character controller** (§4) → rapier `KinematicCharacterController` (swept capsule) + a ported
  OnGround/InAir/Jumping/Climb state machine. `FUN_004255c0` is the authored parameter source
  (capsule radii, slope cosine `+0xa4`, step height).
- **Query layer** (§3) → rapier `query_pipeline` ray/shape casts; 1:1 with `getClosestPoints`/
  `getPenetrations`/`CastRay`. Capture original hit points via x32dbg on `FUN_008db880` for the gate.
- **Actors + constraints** (§5–6) → rapier rigid bodies + joints; grapple/winch = rapier
  spring/prismatic joints (built last). Vehicle actors → the custom raycast controller from the
  vehicle map (not a physics-lib vehicle).

---

## 8. Annotated excerpts

**`FUN_0094f2c0` — `hkpCharacterProxy` ctor (vtable, H):**
```c
*(undefined2 *)((int)param_1 + 6) = 1;
param_1[2] = hkpEntityListener::vftable;   // proxy is an entity listener
param_1[3] = hkpPhantomListener::vftable;  // ... and a phantom listener
*param_1     = hkpCharacterProxy::vftable;  // <- proves the class
param_1[0x1f] = 0x80000000; param_1[0x22] = 0x80000000;  // hkVector4 -0.0 w-lanes
param_1[0x25] = 0x80000000; param_1[0x28] = 0x80000000;
FUN_0094dd30(param_2);                      // setCinfo: capsule@+0x30, up@+0x40, maxSlopeCos@+0xa4
```

**`FUN_008db880` — `hkpWorld::getClosestPoints` (string+body, H):**
```c
*puVar1   = s_LthkpWorld__getClosestPoints_00b59178;  // TLS profiler scope
puVar1[3] = s_Stbroadphase_00b59080;                  // broadphase stage
... (**(code**)(*(int*)*param2 + 0x1c))(...)          // shape calcAabb
... (**(code**)(*world+0x54 vt + 0x40))(&pairs)       // AabbPhantom: gather overlaps
*puVar1 = s_Stnarrowphase_00b59168;                   // narrowphase stage
for each pair p != self:
  if (world_filter->isCollisionEnabled(self,p) && p.shape)   // world+0x70 filter vt+4
     (*(param3 + 0x9a8 + shapeType*0x14))(self,p,param3,cb); // per-pair agent dispatch
```
`getPenetrations` `FUN_008dba60` is byte-identical bar the scope string and an early-out
(`if (*(char*)(param_4+4)) break;`) on the first penetrating pair.

**`FUN_008dae30` — `hkpWorld::addAction` (body, H):**
```c
(**(code**)(*param_2 + 0x10))(&collidables);        // action->getEntities()
for each entity e in collidables:
   grow e+0x1f8 action-array (FUN_00894830) ; push param_2   // register action on entity
   merge e's simulation island (FUN_008eb8c0 / thunk_FUN_032b0000 if different islands)
FUN_008e9e90(world, param_2);                        // fire entity-add listeners (TtactAddCb)
```

**`FUN_00648130` — `RagdollController` stream-class registrar (string, H):**
```c
PTR_PTR_017c0508 = &PTR_CopyFromStream_00bc4468;   // stream-copy vtable
_DAT_017c0534    = 0x9e3779b9;                     // golden-ratio type seed
_DAT_017c0530    = 0x100;                           // pool stride
FUN_0064a770();                                     // commit descriptor
PTR_s_RagdollController_017c0544 = s_RagdollController_00bc5eb0;  // <- anchor
```

---

## 9. Confirm-live plan (x32dbg, paused, read-only — never resume)

1. **Character step:** bp the proxy integrate (vtable slot on `this[0xac]` built by `FUN_004255c0`);
   while the USER walks/jumps, read `hkpCharacterContext` `this[0xb6]` current-state id → confirms the
   OnGround↔InAir↔Jumping↔Climb transitions and pins state ids 5/6.
2. **Query oracle:** bp `FUN_008db880` / `FUN_008d6330` (`hkpWorldRayCaster`) and `CastRay`; capture
   origin/dir/hit-point/normal while AI/camera/weapon fire — the golden set for the rapier gate.
3. **Grapple/winch:** fire the grapple / winch a cargo, bp the constraint ctors `FUN_008e5f30`
   (ball-socket) / `FUN_008df700` (stiff-spring) / `FUN_008e0540` (prismatic) → **which one** the tow
   uses + its bodyA/bodyB/pivots; dump the 44-byte `Winch` component. This closes the §6 OPEN.
4. **World step / PgHavokManager::Update:** bp `FUN_008dae30` (addAction) and `FUN_008f8af0`
   (deferred-op queue) to catch the frame boundary, then step out to find the (SecuROM/Pimp-dispatched)
   `hkpWorld::step` call site — the VMX integrator, reported not to decode statically (⚠ but
   re-decompile it under the noreturn-on-sqrt fix first — §1 — before treating that as settled).

## 10. Open / unlocated

- **The per-frame integrator (`hkpWorld::step`/`integrate`)** — VMX128/SSE, **undecoded in both
  builds**. No numeric oracle for solver internals; gate on outputs (§7).
- **`PgHavokManager::Update` / `UpdatePgPhysicsActor` / droplet system** — not decoded on either
  build (registrar/profiler stubs only). The `PgPhysicsSystemDroplet` fluid model is inference.
- **Grapple/winch constraint-create bodies** — provably constraint-driven (§6), specific ctor +
  `Winch` 44-byte layout = confirm-live (§9).
- **On-disk MOPP tree + `WpMeshShape16` index layout, `hkpRigidBody` mass/inertia/friction/
  restitution fields** — recognised but not byte-decoded (`physics_havok_spec` §5); extraction work,
  not runtime code.
- **`hkpWorldCinfo` defaults** (`m_sizeOfToiEventQueue`, gravity) — string-named, initialized in
  VMX-heavy setup; read live.

## 11. Provenance

- PC decomp: `output/_ghidra/mercs2_unpacked.exe_decomp.txt` / `all_functions_decomp.txt`
  (SecuROM-unpacked, base 0x400000). Bodies read inline: `FUN_0094f2c0`, `FUN_0094dd30`, `FUN_0094ce90`,
  `FUN_004255c0`, `FUN_008db880`, `FUN_008dba60`, `FUN_008dae30`, `FUN_008f8af0`, `FUN_008bfb60`,
  `FUN_00648130`, `FUN_009463a0`, `FUN_00945f30`, actor activators `FUN_00437080`/`FUN_00435660`/
  `FUN_00439540`/`FUN_00510ff0`.
- Xbox ground truth + RTTI→PC pairing: `docs/mercs2-pdb-analysis/{havok-physics,physics-game,symbol-map}.md`
  (204/287 RTTI classes vtable-resolved).
- Cross-refs: [`vehicle_code_map.md`](vehicle_code_map.md) §3 (actors/drive), [`world_streaming_code_map.md`],
  [`asset_formats_code_map.md`](asset_formats_code_map.md) §7 (PHY2), [`physics_havok_spec.md`](../modernization/physics_havok_spec.md),
  memory [[phy2-havok-chunk-not-u32]].
- Confidence stated per row (H = vtable-proven/body-read; M = string/partial; L = inferred).
