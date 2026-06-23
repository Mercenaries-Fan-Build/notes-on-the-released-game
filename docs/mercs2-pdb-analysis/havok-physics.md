# Havok Physics (havok-physics)

Third-party Havok physics/animation middleware (`hk*` / `hkp*` / `hka*` / `hkb*` / `hkx*` / `hkFx*`) as linked into Mercenaries 2.

**Provenance:** All symbols/strings below are recovered from the Xbox 360 preview executable `Mercs2_Xenon_P.exe` (Jul 11 2008, a PowerPC devkit "Profile" build of *Mercenaries 2: World in Flames*). Full decompressed PE at `output/jul08_prototype/mercs2_xenon_p.pe_full.bin`. This is symbol/string evidence (RTTI names, reflection class strings, embedded source paths, assert text), **not** a real `.pdb`. Pandemic's in-house engine is "Pangea" (`Pg*`); Havok is the third-party physics/animation library.

## Overview

Havok is the rigid-body dynamics, collision, constraint, ragdoll, vehicle, and animation middleware embedded in the game. Its presence is overwhelming: the inventory file lists ~918 `hk*`-prefixed reflection/type symbols in `.rdata`, and the RTTI table (`mercs2_xenon_p.rtti_classes.txt`) contains hundreds of `.?AVhkp...@@` / `.?AVhka...@@` class records. The full Havok class set is pulled in via the header string `#include <Common/Compat/hkHavokAllClasses.h>` (strings line 12242).

The middleware version is recorded as **`Havok-5.5.0-r1`** — this is the value emitted next to the reflection `VersionString` machinery (`const hkStaticClassNameRegistry %s(Classes, ClassVersion, VersionString);` immediately followed by `Havok-5.5.0-r1`, strings lines 12276-12277) and is the version cited by the packfile up-to-date check (`Did you call hkVersionUtil::updateToCurrentVersion() or did it fail?` then `Havok-5.5.0-r1`, lines 12224-12225). The many other `Havok-x.y.z` strings (e.g. `Havok-3.1.0`, `Havok-4.6.1-r1`, `Havok-5.1.0-r1`, lines 8026-11767) are the `hkVersionRegistry` list of *prior* versions the loader can up-convert from, not the build version — `5.5.0-r1` is the build version, the older strings are the up-conversion targets.

The Pangea side wraps Havok behind `oPgHavokManager` / `PgHavokManager::Update` and `PgPhysicsActor` (strings lines 15, 49, 19); those are Pangea symbols and are documented under the `physics-game` system — this doc covers the Havok library proper.

## Source files

No Havok `.cpp/.h` paths appear in `mercs2_xenon_p.source_paths.txt` (that file holds only Lua, Pal, Pangea, PimpLib, and Xenon-XTL paths). Havok was linked as a third-party library without local debug source paths.

However, Havok's own internal (relative) build paths survive as embedded literals in the strings dump (library-internal, not the game's tree):

- `.\World\hkpWorld.cpp` (line 12007)
- `8..\Havok\Source\Common/Base/Memory/Memory/Malloc/hkMallocMemory.h` (line 85)
- `.\Collide\Mopp\Machine\hkpMoppAabbCastVirtualMachine.cpp` (line 12160)
- `.\Dynamics\World\Simulation\Continuous\hkpContinuousSimulation.cpp` (line 12179)
- `.\Collide\ShapeUtils\ShapeShrinker\hkpShapeShrinker.cpp` (line 12194)
- `.\Constraint\Bilateral\hkpConstraintUtils.cpp` (line 12196)
- `.\Collide\ShapeUtils\CollapseTransform\hkpTransformCollapseUtil.cpp` (line 12212)
- `.\Packfile\hkPackfileReader.cpp` (line 12221)
- `.\Util\hkObjectInspector.cpp` (line 12235)

## Key classes

Demangled RTTI class names (from `mercs2_xenon_p.rtti_classes.txt`) that belong to this system. `.?AV<Name>@@` → `class <Name>`; `.?AU` → `struct`; `@`-separated namespaces reversed to `::`.

Dynamics / world:
- `class hkpWorld`, `class hkpWorldObject`, `struct hkpWorldCinfo`, `class hkpWorldMaintenanceMgr`, `class hkpDefaultWorldMaintenanceMgr`, `class hkpWorldDeletionListener`
- `class hkpSimulation`, `class hkpContinuousSimulation`, `class hkpMultiThreadedSimulation`, `class hkpSimulationIsland`
- `class hkpEntity`, `class hkpRigidBody`, `class hkpMotion` and motions (`hkpBoxMotion`, `hkpSphereMotion`, `hkpFixedRigidMotion`, `hkpKeyframedRigidMotion`, `hkpCharacterMotion`, `hkpStabilizedBoxMotion`, `hkpStabilizedSphereMotion`, `hkpThinBoxMotion`, `hkpMaxSizeMotion`)
- `class hkpPhysicsSystem`, `class hkpPhysicsSystemWithContacts`, `class hkpPhysicsData`

Collision — shapes:
- `class hkpShape`, `class hkpConvexShape`, `class hkpBoxShape`, `class hkpSphereShape`, `class hkpCapsuleShape`, `class hkpCylinderShape`, `class hkpTriangleShape`, `class hkpConvexVerticesShape`, `class hkpConvexTransformShape`, `class hkpConvexTranslateShape`
- `class hkpMeshShape`, `class hkpFastMeshShape`, `class hkpSimpleMeshShape`, `class hkpStorageMeshShape`, `class hkpExtendedMeshShape`, `class hkpStorageExtendedMeshShape` (with `struct MeshSubpartStorage@hkpStorageExtendedMeshShape`, `struct ShapeSubpartStorage@hkpStorageExtendedMeshShape`)
- `class hkpListShape`, `class hkpConvexListShape`, `class hkpMultiSphereShape`, `class hkpMultiRayShape`, `class hkpPlaneShape`, `class hkpTransformShape`, `class hkpSphereRepShape`
- Height fields: `class hkpHeightFieldShape`, `class hkpSampledHeightFieldShape`, `class hkpStorageSampledHeightFieldShape`, `class hkpTriSampledHeightFieldBvTreeShape`, `class hkpTriSampledHeightFieldCollection`
- MOPP: `class hkpMoppBvTreeShape`, `class hkMoppBvTreeShapeBase`, `class hkpMoppCode`, `class hkpMoppModifier`, `class hkpRemoveTerminalsMoppModifier`

Collision — agents / dispatch / broadphase / filters:
- `class hkpCollisionAgent`, `class hkpCollisionDispatcher`, plus concrete agents `hkpBoxBoxAgent`, `hkpGskBaseAgent`, `hkpGskfAgent`, `hkpPredGskfAgent`, `hkpBvTreeAgent`, `hkpBvTreeStreamAgent`, `hkpListAgent`, `hkpConvexListAgent`, `hkpMoppAgent`, `hkpShapeCollectionAgent`, `hkpTransformAgent`, `hkpHeightFieldAgent`, `hkpSphereTriangleAgent`, `hkpCapsuleTriangleAgent`, `hkpMultiSphereTriangleAgent`, `hkpIterativeLinearCastAgent`, `hkpNullAgent`
- `class hkpSymmetricAgent<...>` / `class hkpSymmetricAgentLinearCast<...>` template instantiations (RTTI lines 26-52)
- Broadphase: `class hkp3AxisSweep`, `class hkpBroadPhase`, `class hkpBroadPhaseBorder`, listeners `hkpBroadPhaseListener`, `hkpBroadPhaseBorderListener`, `hkpEntityEntityBroadPhaseListener`, `hkpPhantomBroadPhaseListener`; multithreaded nested listeners `MtBroadPhaseBorderListener@hkpMultiThreadedSimulation`, `MtEntityEntityBroadPhaseListener@hkpMultiThreadedSimulation`, `MtPhantomBroadPhaseListener@hkpMultiThreadedSimulation`
- Filters: `class hkpCollisionFilter`, `hkpGroupFilter`, `hkpGroupCollisionFilter`, `hkpPairwiseCollisionFilter`, `hkpConstrainedSystemFilter`, `hkpDisableEntityCollisionFilter`, `hkpConvexListFilter`, `hkpDefaultConvexListFilter`, `hkpRayCollidableFilter`, `hkpShapeCollectionFilter`, `hkpCollisionFilterList`, `hkpNullCollisionFilter`
- Phantoms: `class hkpPhantom`, `hkpAabbPhantom`, `hkpShapePhantom`, `hkpSimpleShapePhantom`, `hkpCachingShapePhantom`, `hkpPhantomAgent`; phantom listeners `hkpPhantomListener`, `hkpPhantomOverlapListener`
- Collectors: `hkpAllCdPointCollector`, `hkpClosestCdPointCollector`, `hkpCdPointCollector`, `hkpCdBodyPairCollector`, `hkpFlagCdBodyPairCollector`, `hkpSimpleClosestContactCollector`, `hkpRayHitCollector`, `hkpBroadPhaseCastCollector`
- Casters: `class hkpWorldRayCaster`, `hkpWorldLinearCaster`, `hkpSimpleWorldRayCaster`

Constraints:
- `class hkpConstraintData`, `hkpConstraintInstance`, `hkpConstraintMotor`, `hkpConstraintOwner`, `hkpDeferredConstraintOwner`, `hkpConstraintChainData`, `hkpConstraintChainInstance`, `hkpConstraintChainInstanceAction`
- Concrete data types `hkpBallAndSocketConstraintData`, `hkpHingeConstraintData`, `hkpLimitedHingeConstraintData`, `hkpHingeLimitsData`, `hkpPrismaticConstraintData`, `hkpRagdollConstraintData`, `hkpRagdollLimitsData`, `hkpBreakableConstraintData`, `hkpGenericConstraintData`, `hkpBallSocketChainData`, `hkpPositionConstraintMotor`, `hkpLimitedForceConstraintMotor`, `hkpSimpleContactConstraintData`

Contact managers: `class hkpContactMgr`, `hkpContactMgrFactory`, `hkpNullContactMgr`, `hkpNullContactMgrFactory`, `hkpDynamicsContactMgr`, `hkpSimpleConstraintContactMgr`, `hkpReportContactMgr`, `hkpMapPointsToSubShapeContactMgr`; nested `Factory@hkpReportContactMgr`, `Factory@hkpSimpleConstraintContactMgr`.

Character / ragdoll / actions: `class hkpCharacterProxy`, `hkpCharacterContext`, `hkpCharacterStateManager`, `hkpCharacterState`, `hkpCharacterStateInAir`, `hkpCharacterStateJumping`, `hkpCharacterStateOnGround`; `class hkaRagdollInstance`; `class hkpAction`, `hkpUnaryAction`.

ToI / resource mgmt: `class hkpToiResourceMgr`, `hkpDefaultToiResourceMgr`.

Animation (`hka*`): `class hkaSkeletalAnimation`, `hkaInterleavedSkeletalAnimation`, `hkaDeltaCompressedSkeletalAnimation`, `hkaSplineSkeletalAnimation`, `hkaWaveletSkeletalAnimation`, `hkaAnimatedSkeleton`, `hkaAnimationControl`, `hkaDefaultAnimationControl`, `hkaAnimationControlListener`, `hkaSkeletonMapper`, `hkaFootPlacementIkSolver`, `hkaChunkCache`, `hkaDefaultChunkCache`, `hkaMultithreadedChunkCache`, `hkaAnimatedReferenceFrame`, `hkaDefaultAnimatedReferenceFrame`.

Serialization / reflection / streams: `class hkXmlParser` (nested `struct Characters`, `struct Node`, `struct StartElement`, `struct EndElement`), `hkXmlObjectReader`, `hkXmlObjectWriter`, `hkXmlPackfileReader`, `hkXmlPackfileWriter`, `hkXmlPackfileUpdateTracker`, `hkPackfileReader`, `hkPackfileWriter`, `hkBinaryPackfileWriter`, `hkPackfileData`, `hkPlatformObjectWriter`, `hkObjectCopier`, `hkObjectReader`, `hkObjectWriter`, `hkResource`, `hkLoader`; registries `hkVersionRegistry`, `hkClassNameRegistry`, `hkDefaultClassNameRegistry`, `hkStaticClassNameRegistry`, `hkDynamicClassNameRegistry`, `hkChainedClassNameRegistry`, `hkRenamedClassNameRegistry`, `hkBindingClassNameRegistry`, `hkBuiltinTypeRegistry`, `hkDefaultBuiltinTypeRegistry`, `hkTypeInfoRegistry`, `hkVtableClassRegistry`; `struct StringPool@hkRelocationInfo`; `struct NameFromAddress@hkXmlObjectWriter`; `ConvertListener@hkpHavokSnapshot`. Streams/IO: `hkIstream`, `hkOstream`, `hkOArchive`, `hkStreamReader`, `hkStreamWriter`, `hkBufferedStreamReader/Writer`, `hkMemoryStreamReader`, `hkStdioStreamReader/Writer`, `hkArrayStreamWriter`, `hkCrc32StreamWriter`, `hkSubStreamWriter`, `hkOffsetOnlyStreamWriter`, `hkSocket`, `hkBsdSocket`, `hkNativeFileSystem`, `hkFileSystem`.

Base / memory / debug: `class hkBaseObject`, `hkReferencedObject`, `hkMemory`, `hkPoolMemory`, `hkThreadMemory`, `hkError`, `hkDefaultError`, `hkErrStream`, `hkTraceStream`, `hkDebugDisplay`, `hkStackTracer`, `hkStatisticsCollectorClassListener`; singletons via `class hkSingleton<...>` over `hkError`, `hkFileSystem`, `hkDebugDisplay`, `hkVersionRegistry`, `hkVtableClassRegistry`, `hkBuiltinTypeRegistry`, `hkTypeInfoRegistry`, `hkDefaultClassNameRegistry`, `hkTraceStream`, `hkDummySingleton`, `hkStatisticsCollectorClassListener` (RTTI lines 15-25).

## Symbols by area

All offsets/sections below are copy-exact from `output/jul08_prototype/inventory/havok-physics.txt` (all `.rdata`). These are reflection/type-name string symbols (the build's RTTI/reflection metadata), with two code-symbol exceptions noted.

### Base types, containers, math, reflection
| Symbol | Offset |
|---|---|
| hkBaseObject | 0x00542cc |
| hkReferencedObject | 0x0056158 |
| hkClass / hkClassMember / hkClassEnum / hkClassEnumItem | 0x004940c / 0x00493fc / 0x00493f0 / 0x00493e0 |
| hkArray / hkSimpleArray / hkInplaceArray / hkHomogeneousArray | 0x0056324 / 0x0056314 / 0x0056494 / 0x00564b8 |
| hkVector4 / hkQuaternion / hkMatrix3 / hkMatrix4 / hkTransform / hkQsTransform / hkRotation | 0x0056410 / 0x005641c / 0x005642c / 0x0056454 / 0x0056460 / 0x0056444 / 0x0056438 |
| hkReal / hkBool / hkInt8…hkUint64 / hkUlong / hkFlags / hkVariant | 0x0056408 / 0x00563ac / 0x00563bc…0x00563fc / 0x00564d8 / 0x00564e0 / 0x00564cc |
| hkBitField / hkMultiThreadCheck / hkSweptTransform | 0x00635b0 / 0x00635bc / 0x00635d0 |

These are the Havok reflection primitives (`hkClass`/`hkClassMember`/`hkClassEnum`) and the math/container POD types. They exist as named reflection entries because the build ships the Havok type registry.

### Monitor stream / statistics
| Symbol | Offset |
|---|---|
| hkMonitorStreamStringMapStringMap | 0x00635e4 |
| hkMonitorStreamStringMap | 0x0063608 |
| hkMonitorStreamFrameInfo | 0x0063668 |

The runtime profiling/monitor-stream subsystem; backs the `St*`/`Lt*`/`Tt*` timer labels listed under Notable strings.

### Dynamics: world, simulation, motion, entities
| Symbol | Offset |
|---|---|
| hkpWorld | 0x0064f84 |
| hkpWorldCinfo / hkpWorldObject | 0x006518c / 0x006519c |
| hkWorldMemoryAvailableWatchDog / hkWorldMemoryWatchDog | 0x00651ac / 0x0074a3c |
| hkpSimulation | 0x0065224 |
| hkpContinuousSimulation | 0x009be20 |
| hkpEntity / hkpRigidBody | 0x0064ca8 / 0x0064ce8 |
| hkpMotion (+ Box/Character/FixedRigid/Keyframed/MaxSize/Sphere/StabilizedBox/StabilizedSphere/ThinBox) | 0x0064e24 … 0x0064ed8 |
| hkpRigidBodyDeactivator / hkpSpatialRigidBodyDeactivator / hkpFakeRigidBodyDeactivator / hkpEntityDeactivator | 0x0064cf8 / 0x0064d38 / 0x0064ccc / 0x0064cb4 |
| hkpPhysicsSystem / hkpPhysicsSystemWithContacts | 0x0064f70 / 0x0065448 |
| hkWorld::stepBeginSt | 0x0001734 |

`hkWorld::stepBeginSt` (0x0001734) is a code-symbol string (a function/marker name, not a reflection type) — it names the per-step begin marker. `hkpContinuousSimulation` (0x009be20) sits in the agent-table region near `hkBvTreeAgent3`/`hkpCollectionCollectionAgent3`, consistent with the continuous-sim/ToI path.

### Collision: shapes
| Symbol | Offset |
|---|---|
| hkpShape / hkpConvexShape / hkpShapeCollection / hkpShapeContainer | 0x0063c20 / 0x0063efc / 0x0063c58 / 0x0063c2c |
| hkpBoxShape / hkpSphereShape / hkpCapsuleShape / hkpCylinderShape / hkpTriangleShape | 0x0063f0c / 0x0063fc8 / 0x0063f18 / 0x0063fb4 / 0x0063fec |
| hkpConvexVerticesShape / hkpPackedConvexVerticesShape | 0x0063f9c / 0x006b6f0 |
| hkpMeshShape / hkpFastMeshShape / hkpStorageMeshShape / hkpSimpleMeshShape | 0x0064050 / 0x0064018 / 0x0064098 / 0x0063e10 |
| hkpExtendedMeshShape / hkpStorageExtendedMeshShape | 0x0063da4 / 0x0063e84 |
| hkpListShape / hkpConvexListShape / hkpMultiSphereShape / hkpMultiRayShape | 0x0063dd4 / 0x0064178 / 0x0064060 / 0x00641a0 |
| hkpMoppBvTreeShape / hkMoppBvTreeShapeBase / hkpMoppCode / hkpMoppModifier(=hkMoppModifier) | 0x0063ec8 / 0x0063eb0 / 0x00652c0 / 0x007edf8 |
| hkpHeightFieldShape / hkpSampledHeightFieldShape / hkpTriSampledHeightFieldBvTreeShape | 0x00640ac / 0x00640e4 / 0x0064124 |

(Note: the inventory contains a parallel set of `hk*Shape` names without the `p` — e.g. `hkBoxShape` 0x0073a28, `hkMeshShape` 0x0073c10 — these are the *renamed-class* registry aliases used by versioning, mapping legacy un-prefixed names to current `hkp*` classes. Both forms exist in the inventory; the alias purpose is inferred.)

### Collision: agents, broadphase, filters, casters
| Symbol | Offset |
|---|---|
| hkpCollidable / hkpLinkedCollidable | 0x0063b14 / 0x0065248 |
| hkpCollidableBoundingVolumeData | 0x0063af4 |
| hkpBroadPhaseHandle / hkpTypedBroadPhaseHandle | 0x006525c / 0x0063b24 |
| hkpAgent1nSector / hkBvTreeAgent3 / hkListAgent3 / hkConvexListAgent3 / hkpCollectionCollectionAgent3 | 0x0065234 / 0x009ba18 / 0x009bd24 / 0x009bd3c / 0x009bd70 |
| hkpCollisionFilter / hkpGroupFilter / hkpPairwiseCollisionFilter / hkpConstrainedSystemFilter | 0x0063b68 / 0x0063be0 / 0x00653a0 / 0x006535c |
| hkpDisableEntityCollisionFilter / hkpGroupCollisionFilter / hkpCollisionFilterList / hkpNullCollisionFilter | 0x0065410 / 0x0065430 / 0x0063bf0 / 0x0063c08 |
| hkpRayShapeCollectionFilter / hkpShapeCollectionFilter / hkpRayCollidableFilter / hkpConvexListFilter | 0x00641e0 / 0x0063ba8 / 0x0063b90 / 0x0063b7c |
| hkpWeldingUtility(=hkWeldingUtility) | 0x0064214 / 0x0073ee4 |
| hkpCollisionDispatcher::debugPrintTable | 0x0099574 |
| hkpContactMgrFactory | 0x009a150 |

`hkpCollisionDispatcher::debugPrintTable` (0x0099574) and `hkpContactMgrFactory` (0x009a150) are code/runtime symbols (not reflection POD names), evidencing the agent-dispatch table and contact-manager factory at runtime.

### Phantoms
| Symbol | Offset |
|---|---|
| hkpPhantom / hkpShapePhantom / hkpSimpleShapePhantom / hkpCachingShapePhantom / hkpAabbPhantom | 0x0064f14 / 0x0064f20 / 0x0064f58 / 0x0064efc / 0x0064eec |
| hkShapePhantom::setTransform / hkShapePhantom::setPosition | 0x00020c8 / 0x00020e8 |

`hkShapePhantom::setTransform`/`setPosition` (0x00020c8/0x00020e8) are method-name code symbols.

### Constraints, motors, chains
| Symbol | Offset |
|---|---|
| hkpConstraintAtom / hkpBridgeConstraintAtom / hkpBridgeAtoms | 0x0064228 / 0x006423c / 0x0064254 |
| hkpSimpleContactConstraintAtom / hkpBallSocketConstraintAtom / hkpStiffSpringConstraintAtom | 0x0064264 / 0x0064284 / 0x00642a0 |
| hkp2dAngConstraintAtom / hkpAngLimitConstraintAtom / hkpTwistLimitConstraintAtom / hkpConeLimitConstraintAtom | 0x00643a0 / 0x00643d0 / 0x00643ec / 0x0064420 |
| hkpConstraintData / hkpConstraintInstance | 0x0064654 / 0x0064680 |
| hkpBallAndSocketConstraintData / hkpHingeConstraintData / hkpLimitedHingeConstraintData | 0x00646bc / 0x00646f8 / 0x0064734 |
| hkpRagdollConstraintData / hkpRagdollLimitsData | 0x0064854 / 0x0064a5c |
| hkpPrismaticConstraintData / hkpWheelConstraintData / hkpPointToPlaneConstraintData / hkpStiffSpringConstraintData | 0x0064818 / 0x00648d0 / 0x00647d8 / 0x0064894 |
| hkpBreakableConstraintData / hkpMalleableConstraintData / hkpGenericConstraintData | 0x0064928 / 0x0064b20 / 0x0064ab4 |
| hkpConstraintMotor / hkpPositionConstraintMotor / hkpVelocityConstraintMotor / hkpSpringDamperConstraintMotor / hkpLimitedForceConstraintMotor | 0x0064b3c / 0x0064bb0 / 0x0064bec / 0x0064bcc / 0x0064b50 |
| hkpConstraintChainData / hkpBallSocketChainData / hkpPoweredChainData / hkpPoweredChainMapper | 0x0064944 / 0x00649c4 / 0x0064a2c / 0x00653f8 |
| hkConstraintInfo / hkConstraintType | 0x0084338 / 0x0090e34 |

### Actions
| Symbol | Offset |
|---|---|
| hkpAction / hkpUnaryAction / hkpBinaryAction / hkpArrayAction | 0x00645ec / 0x0064618 / 0x0064608 / 0x00645f8 |
| hkpSpringAction / hkpDashpotAction / hkpAngularDashpotAction / hkpMotorAction / hkpReorientAction / hkpMouseSpringAction | 0x0065334 / 0x00652e4 / 0x00652cc / 0x00652f8 / 0x0065320 / 0x0065308 |

### Ragdoll / IK / keyframe utilities
| Symbol | Offset |
|---|---|
| hkpRagdollMotorConstraintAtom | 0x0064478 |
| hkaRagdollInstance(=hkRagdollInstance) | 0x0061ed8 / 0x007367c |
| hkaKeyFrameHierarchyUtility / hkaKeyFrameHierarchyUtilityControlData | 0x0061ebc / 0x0061e94 |
| hkpRagdollConstraintDataAtoms / hkpRagdollLimitsDataAtoms | 0x0064834 / 0x0064a40 |

### Vehicle
| Symbol | Offset |
|---|---|
| hkpVehicleInstance / hkpVehicleData | 0x0065668 / 0x006563c |
| hkpVehicleDefaultEngine / hkpVehicleDefaultTransmission / hkpVehicleDefaultBrake / hkpVehicleDefaultSteering | 0x006579c / 0x006592c / 0x00656f4 / 0x0065858 |
| hkpVehicleDefaultSuspension / hkpVehicleSuspension | 0x00658f8 / 0x00658a4 |
| hkpVehicleDefaultAerodynamics / hkpVehicleAerodynamics | 0x0065694 / 0x006567c |
| hkpVehicleFrictionDescription / hkpVehicleFrictionStatus | 0x00657e4 / 0x0065828 |
| hkpVehicleDefaultAnalogDriverInput / hkpVehicleDriverInput | 0x0065764 / 0x0065728 |
| hkpVehicleVelocityDamper / hkpVehicleDefaultVelocityDamper | 0x0065974 / 0x0065990 |
| hkpVehicleRaycastWheelCollide / hkpVehicleWheelCollide / hkpRejectRayChassisListener | 0x00659e4 / 0x00659b0 / 0x00659c8 |
| hkpTyremarksInfo / hkpTyremarkPoint / hkpTyremarksWheel | 0x00565f0 / 0x0065948… (hkpTyremarkPoint 0x006594c) / 0x0065960 |

The vehicle subsystem is fully present — engine/transmission/brake/steering/suspension/aerodynamics/friction/driver-input/velocity-damper plus raycast wheel collision and tyremarks. This is the Havok vehicle SDK driving the game's cars/bikes/tanks/boats/helis (cf. Pangea actions `CarAction`/`BikeAction`/`TankAction`/`HeliAction`/`BoatAction`/`WaterAction`, strings lines 39-101).

### Serialization / packfile / XML
| Symbol | Offset |
|---|---|
| hkPackfileHeader / hkPackfileSectionHeader | 0x0063a80 / 0x0063a94 |
| hkRootLevelContainer / hkRootLevelContainerNamedVariant | 0x0063ad0 / 0x0063aac |
| hkVersioningExceptionsArray / hkVersioningExceptionsArrayVersioningException | 0x007eddc / 0x007edac |
| hkPhysicsData / hkpPhysicsData | 0x0074d3c / 0x0065570 |
| hkpSerializedAgentNnEntry / hkpSerializedTrack1nInfo / hkpSerializedSubTrack1nInfo | 0x0065500 / 0x0065468 / 0x0065484 |
| hkpDisplayBindingData / hkpRigidBodyDisplayBinding / hkpPhysicsSystemDisplayBinding | 0x0065558 / 0x006551c / 0x0065538 |

### hkx scene/mesh/material/attribute layer
| Symbol | Offset |
|---|---|
| hkxScene / hkxNode / hkxMesh / hkxMeshSection | 0x0063a50 / 0x0063840 / 0x0063900 / 0x0063908 |
| hkxVertexBuffer / hkxVertexFormat / hkxIndexBuffer | 0x0063918 / 0x0063928 / 0x00638d8 |
| hkxMaterial / hkxMaterialEffect / hkxTextureFile / hkxTextureInplace | 0x0063880 / 0x006388c / 0x00638a0 / 0x00638b0 |
| hkxSkinBinding / hkxAttributeHolder / hkxEnvironment | 0x0063a70 / 0x0063758 / 0x0063818 |

The `hkx*` set is Havok's content/scene-export representation (meshes, materials, vertex formats, skin bindings) — present because the game ships Havok-exported physics/animation assets.

### Animation + behavior (hka* / hkb*)
The inventory also contains the full `hka*` skeletal-animation compression set (`hkaSkeleton`, `hkaSkeletalAnimation`, `hkaInterleavedSkeletalAnimation`, `hkaDeltaCompressedSkeletalAnimation`, `hkaSplineSkeletalAnimation`, `hkaWaveletSkeletalAnimation`, `hkaSkeletonMapper`, `hkaBoneAttachment`, `hkaAnimationBinding` — e.g. 0x0053938…0x0061e58) and a very large `hkb*` behavior-graph set (`hkbBehaviorGraph` 0x0061f90, `hkbCharacter` 0x0061fd8, `hkbStateMachine` 0x0062b38, `hkbClipGenerator` 0x00622d0, `hkbFootIkModifier` 0x00624cc, `hkbHandIkModifier` 0x0062524, `hkbPoweredRagdollModifier` 0x0062648, `hkbRagdollDriverModifier` 0x0062664, etc.). These overlap heavily with the **animation-skeleton** system doc and are catalogued there; this doc treats them as Havok-Animation/Behavior provenance only.

## Notable strings

Version / packfile (line numbers from `mercs2_xenon_p.pe_full_strings.txt`):
- `Havok-5.5.0-r1` (12225, 12277) — build version (the `VersionString` for the static class registry / packfile up-to-date check)
- `** Havok libs built with version [` (12010) … `], used with code built with [` (12008) … `]. **` (12009) — lib/code version mismatch report
- `Loaded data contains version ` (12222) … ` but the current version is ` (12223) … `. Did you call hkVersionUtil::updateToCurrentVersion() or did it fail?` (12224)
- `Packfile contents are not up to date` / `Packfile file format is too old` / `Packfile data source needs to be 4 byte aligned` / `Missing packfile magic header. Is this from a binary file?` (12226-12233)
- `Trying to process a binary file with a different endian than this platform.` (12231) / `... different pointer size ...` (12232) / `... different padding optimization ...` (12230) / `... different empty base class optimization ...` (12229) — cross-platform packfile guards
- XML packfile tokens `<?xml` / `<hkpackfile` / `<hksection` (12220, 12219, 12218)
- Reflection codegen template: `#include <Common/Compat/hkHavokAllClasses.h>`, `namespace hkHavok%sClasses`, `extern const char VersionString[];`, `const hkStaticClassNameRegistry %s(Classes, ClassVersion, VersionString);` (12242-12276)

Asserts / data-validation:
- `Trying to assign a NULL shape to a dynamic rigid body. You can skip this assert and the game will work fine but this is a data problem so please fix it.` (144) with `The model is [%s] and the rigid body is on node idx %i(%s)` (145) — a Pangea-side wrapper assert tying Havok bodies to model nodes
- `Unknown command - This mopp data has been corrupted (check for memory trashing), or an hkpMoppBvTreeShape has been pointed at invalid mopp data.` (12159) — MOPP VM corruption guard
- `hkpShapeShrinker has attempted to shrink a hkpConvexVerticesShape too far ...` / `... hkpBoxShape ...` / `... hkpCylinderShape ...` (12192-12195)
- `Unsupported type of constraint in prepareSystemForRagdoll()` (12197) / `This type of constraint does not have motors` (12198) / `Pivot of child rigid body (A) is expected to be aligned with the constraint at setup time.` (12199) / `Only limited hinges and ragdoll constraints can be powered.` (12200) / `" to a powered constraint.` (12201) / `Cannot convert constraint "` (12202)
- `Toi event queue full, consider using HK_COLLIDABLE_QUALITY_DEBRIS for some objects or increase hkpWorldCinfo::m_sizeOfToiEventQueue` (12180) — names the tunable `hkpWorldCinfo::m_sizeOfToiEventQueue`
- `Not implemented for hkMallocMemory. Doing nothing.` / `... Forwarding to OS.` (86-87)
- `Pointer is null` / `Unknown class member found during write of data.` (12234, 12236)

Welding tunables/enums: `WeldingType` (9209), `disableWelding` (9325), `enableDeprecatedWelding` (10900) — reflection field names for `hkpWeldingUtility` welding configuration.

Monitor-stream timer labels (lines ~11990-12210) — these are the profiling markers emitted via `hkMonitorStream*`. Examples: `Broadphase`, `Collide`, `Stnarrowphase`, `StcollectionFilter`, `St3AxisSweep`, `StCalcAabbs`, `StIntegrate`, `LtIntegrate`, `TtNarrowPhase`, `TtCollide`, `TtTOIs`, `TtPenetration`, `LthkpWorld::getClosestPoints`, `LthkpWorld::getPenetrations`, `TthkpAabbPhantom::linearCast`, `TtWaitForExport`, plus the world-substep names `.\World\hkpWorld.cpp` references. The `St`/`Lt`/`Tt` prefixes likely denote start-timer / list / total timer categories.

Memory tunable (config block): `HavokPoolMemoryEnable 0` (1966, 2003) and the comment `// Large enough for Havok pages` (1986) in the `[x360_memory]` / `[ps3_memory]` config sections — Havok pool-memory toggle / small-block sizing.

Pangea↔Havok integration markers (Pangea symbols, cited for provenance): `oPgHavokManager` (15), `PgHavokManager::Update` (49), `HavokWorldUpdate` (48), `HavokDeltaStep` (46), `HavokIntegrateJob` (42), `HavokMessages` (44), `ReadHavokDataNew` (103), `AddHavokPAKDataNew` (141), `ModelRemoveHavokPAK` (2433), `HavokModel::Setup` (130), `Sanity Check Havok` (693), `Dump Havok Timers` (699), `MultipleHavokSteps: On/Off` (554-555), `havok data` (7337).

## PC decompilation cross-reference

The Xbox symbols above name classes; the PC retail build is anonymous (`FUN_xxxxxxxx`) but holds the logic. The pairing resolver (`output/jul08_prototype/pairing/resolved_havok-physics.txt`) bridges them two ways into the PC retail decomp `output/_ghidra/all_functions_decomp.txt`: **vtable** matches (high confidence — Ghidra recovered the RTTI vtable label `Class::vftable`, so a function that writes it is that class's constructor/vtable-setter) and **string** matches (medium/low — the function references the same embedded class-name string, usually inside a reflection serializer or version-check, not a 1:1 method).

This is one of the densest systems in the pairing output: ~95 vtable-resolved Havok classes and ~30 string-anchored functions. The table below lists the highest-value resolutions; the full per-class list (all constructor candidates) lives in the resolved file.

| Symbol / class | PC function | Bridge | Role |
|---|---|---|---|
| `hkpWorld` | `FUN_008d8340` | vtable | constructor (sets `hkpWorld::vftable`, zeroes world transforms) |
| `hkpRigidBody` | `FUN_008d4be0` | vtable | constructor (sets `hkpRigidBody::vftable`, chains entity init) |
| `hkpSimulation` | `FUN_008f2320` | vtable | constructor (sets `hkpSimulation::vftable`) |
| `hkpPhysicsSystem` | `FUN_008e4df0` | vtable | constructor (sets `hkpPhysicsSystem::vftable`) |
| `hkpPhysicsData` | `FUN_00953780` | vtable | constructor / data-container setup |
| `hkpEntity` | `FUN_008ddb00` | vtable | constructor |
| `hkpBoxShape` / `hkpSphereShape` / `hkpCapsuleShape` | `FUN_008a86c0` / `FUN_008a92b0` / `FUN_008a9d00` | vtable | shape constructors |
| `hkpMoppBvTreeShape` / `hkMoppBvTreeShapeBase` | `FUN_00a0cc30` / `FUN_00a0cbd0` | vtable | MOPP shape constructors |
| `hkpConstraintInstance` | `FUN_008e4980` | vtable | constructor |
| `hkpHingeConstraintData` / `hkpRagdollConstraintData` | `FUN_008e5d80` / `FUN_008e2950` | vtable | constraint-data constructors |
| `hkaRagdollInstance` | `FUN_0088c000` | vtable | constructor |
| `hkpRigidBody` | `FUN_008dd8a0` | string | reflection serializer (writes `Entity`/`hkpRigidBody`/listener arrays) |
| `hkpMoppCode` | `FUN_00a4af90` | string | reflection serializer for MOPP code blob |
| `hkClass` (+ `hkClassEnum`) | `FUN_006ad910` | string | version up-converter (references `Havok-4.0.0-b1`, `__classindex__`) |
| `hkRootLevelContainer` | `FUN_0089de50` | string | container walker (iterates named variants) |
| `hkpWorld` | `FUN_008d7b80` | string | world-side routine referencing the `hkpWorld` name string |
| `hkbRigidBodyRagdollModifier` | `FUN_00ac249c` | string | low confidence — fn sits among CRT heap/`__sbh_*` callers; likely a generic-string false positive |

**Confidence:** the vtable rows are high — each FUN_ literally assigns the named `::vftable`. The string rows are medium where the string is class-distinctive and read inside a recognizable serializer/version path; `FUN_00ac249c` is flagged low because its callers are CRT allocator internals, so the string anchor is probably incidental.

### Annotated excerpts

`FUN_008d8340` — `hkpWorld` constructor (vtable, high):
```c
*(undefined2 *)((int)param_1 + 6) = 1;
*param_1 = hkpWorld::vftable;          // <- vtable proves the class
param_1[0xc] = 0x80000000;             // gravity / AABB transform rows
param_1[0xf] = 0x80000000;             // 0x80000000 = hkVector4 -0.0 padding,
param_1[0x12] = 0x80000000;            //   repeated for each 4-float row
```
The body is almost entirely `{0,0,0x80000000}` triples — the canonical Havok pattern for initializing a run of `hkVector4`/`hkTransform` rows (the `0x80000000` is the unused `w` lane set to `-0.0`). It confirms both the class and that this is the ctor, not a method.

`FUN_008d4be0` — `hkpRigidBody` constructor (vtable, high):
```c
*param_1 = hkpRigidBody::vftable;
FUN_008de450();                        // chained base/entity init
```
Tiny thunk that stamps the rigid-body vtable then delegates to the shared entity setup — a typical thin derived-class ctor.

`FUN_008dd8a0` — `hkpRigidBody` reflection serializer (string, medium):
```c
(**(code **)(*param_2 + 4))(s_Entity_00b59420,2,param_1);
(**(code **)(*param_2 + 4))(s_hkpRigidBody_00b35d48,2,param_1);   // <- the anchor string
(**(code **)(*param_2 + 8))(s_CollisionListnr_00b59410,4,...);
(**(code **)(*param_2 + 8))(s_EntityListeners_00b593e8,4,...);
```
`param_2` is a writer/visitor vtable; the function feeds it field names (`Entity`, `hkpRigidBody`, `CollisionListnr`, `EntityListeners`, `SavedMotion`). This is the rigid-body's reflection/serialization descriptor, which is why it references the class-name string — not a 1:1 method, exactly the "registry/loader" pattern the bridge warns about.

## Cross-references

- `docs/mercs2-pdb-analysis/physics-game.md` — Pangea's game-side physics wrappers (`PgHavokManager`, `PgPhysicsActor`, `oPgHavokManager`) that drive this Havok layer.
- `docs/mercs2-pdb-analysis/animation-skeleton.md` — the `hka*` (skeletal animation/compression/IK) and `hkb*` (behavior graph, foot/hand IK, powered ragdoll) symbols overlap with this system; catalogued there.
- `docs/mercs2-pdb-analysis/vehicles.md` — the game's vehicle gameplay layer that consumes the `hkpVehicle*` SDK documented here.
- `docs/mercs2-pdb-analysis/jobs-threading.md` — the `HavokIntegrateJob` / `hkpMultiThreadedSimulation` / PIMP job system that runs the physics step on worker threads.
- `docs/mercs2-pdb-analysis/pangea-engine-core.md` — base engine, memory (`HavokPoolMemoryEnable`), and reflection plumbing.

Existing project docs that overlap: `docs/reverse_engineer/comprehensive_engine_understanding.md`, `docs/skeleton_status.md`, `docs/character_systems_plan.md` (ragdoll/character), and `docs/coordinate_systems.md`.

## Evidence & confidence

- **Symbol count:** ~918 lines in `output/jul08_prototype/inventory/havok-physics.txt`, all in section `.rdata` (reflection/type-name strings). RTTI corroboration: hundreds of `.?AVhk*@@` / `.?AUhk*@@` records across `mercs2_xenon_p.rtti_classes.txt` (lines 1-324 cited above).
- **Sections:** exclusively `.rdata` in the inventory. A handful of cited symbols are code/runtime symbols rather than reflection POD names: `hkWorld::stepBeginSt` (0x0001734), `hkShapePhantom::setTransform/setPosition` (0x00020c8/0x00020e8), `hkpCollisionDispatcher::debugPrintTable` (0x0099574), `hkpContactMgrFactory` (0x009a150), `hkAnimation::samplePose` (0x00421e0).
- **Directly backed by a symbol/string:** every offset, class name, source path, assert, and tunable name above was grepped/read from the shared evidence files. The Havok build version is `Havok-5.5.0-r1` (lib's `VersionString`). The full Havok class set is included via `hkHavokAllClasses.h`. Subsystems present: base/memory/reflection, math, dynamics (`hkpWorld`/`hkpRigidBody`/simulation incl. continuous + multithreaded), collision (shapes, agents, broadphase `hkp3AxisSweep`, MOPP, filters, phantoms, collectors, ray/linear casters), constraints + motors + chains, actions, ragdoll/IK, vehicle SDK, serialization (binary + XML packfile, version registry, display bindings), and the `hkx*` scene/asset layer.
- **Inferences:** that the older `Havok-x.y.z` strings are up-conversion targets rather than the build version; that the un-prefixed `hk*Shape` aliases are renamed-class registry entries; the `St`/`Lt`/`Tt` timer-prefix meanings; that the vehicle SDK backs the game's drivable vehicles; that the `hkx*` layer corresponds to shipped Havok-exported assets. The exact runtime call graph and per-field struct layouts are not recoverable from symbols/strings alone — purpose of individual reflection-only entries beyond their name is "unclear from symbols alone" where not otherwise stated.
