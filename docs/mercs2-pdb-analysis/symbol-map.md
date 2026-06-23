# Cross-build symbol map (Xbox RTTI class -> PC retail constructor)

High-confidence vtable-bridge resolutions: each Xbox RTTI class name matched to the PC-retail
function(s) that assign its `Class::vftable` (i.e. its constructor / vtable-setter) in
`output/_ghidra/all_functions_decomp.txt`. These can be applied as labels in Ghidra.

**204 of 287 RTTI classes resolved.** Per-system string-anchored counts are in each system doc's "PC decompilation cross-reference" section.

| Xbox RTTI class | PC constructor / vtable-setter function(s) |
|---|---|
| `ValidatedClassNameRegistry` | `FUN_0095b400` |
| `hkArrayStreamWriter` | `FUN_0088e590`, `FUN_0088e820` |
| `hkBaseObject` | `FUN_00407b00`, `FUN_00424db0`, `FUN_0043d800`, `FUN_006373e0`, `FUN_006aca00`, `FUN_006ad070` … |
| `hkBinaryPackfileWriter` | `FUN_0095d640`, `FUN_0095d6b0` |
| `hkBindingClassNameRegistry` | `FUN_009626a0`, `FUN_00962750` |
| `hkBsdSocket` | `FUN_0089c790`, `FUN_0089c7b0` |
| `hkBufferedStreamReader` | `FUN_00899410`, `FUN_00899450` |
| `hkBufferedStreamWriter` | `FUN_0088f630`, `FUN_0088f710` |
| `hkChainedClassNameRegistry` | `FUN_0095c9c0` |
| `hkCrc32StreamWriter` | `FUN_0089b8c0` |
| `hkDebugDisplay` | `FUN_0096a880`, `FUN_0096a950` |
| `hkDefaultBuiltinTypeRegistry` | `FUN_00956ab0` |
| `hkDefaultError` | `FUN_00413310`, `FUN_00586ec0` |
| `hkDisplayGeometry` | `FUN_00969340`, `FUN_0096b3e0` |
| `hkDynamicClassNameRegistry` | `FUN_0095b400`, `FUN_0095c9c0` |
| `hkHeightFieldRayForwardingCollector` | `FUN_008af94b` |
| `hkIstream` | `FUN_00895b20`, `FUN_00896050`, `FUN_00896250` |
| `hkLineNumberStreamReader` | `FUN_00a08ea0`, `FUN_00a08ed0` |
| `hkLoader` | `FUN_00956640` |
| `hkMemory` | `FUN_00890190`, `FUN_00890230` |
| `hkMemoryStreamReader` | `FUN_0089bb70`, `FUN_0089bbe0` |
| `hkMoppBvTreeShapeBase` | `FUN_00a0cbd0`, `FUN_00a124b0` |
| `hkNativeFileSystem` | `FUN_00891230` |
| `hkOArchive` | `FUN_0089b1f0`, `FUN_0089b260` |
| `hkObjectCopier` | `FUN_00960160` |
| `hkOffsetOnlyStreamWriter` | `FUN_00a08fc0` |
| `hkOstream` | `FUN_0088e3e0`, `FUN_0088e440`, `FUN_0088e4c0`, `FUN_0088e510` |
| `hkPackfileData` | `FUN_0095c600`, `FUN_0095c650` |
| `hkPackfileObjectUpdateTracker` | `FUN_006aca00` |
| `hkPackfileReader` | `FUN_00956230` |
| `hkPackfileWriter` | `FUN_00962ee0`, `FUN_00962fe0` |
| `hkPlatformObjectWriter` | `FUN_00964db0` |
| `hkPoolMemory` | `FUN_008928f0`, `FUN_00892c30` |
| `hkReferencedObject` | `FUN_008982a0` |
| `hkRenamedClassNameRegistry` | `FUN_0095a9f0`, `FUN_0095aa60`, `FUN_0095b920` |
| `hkSocket` | `FUN_008998d0` |
| `hkStackTracer` | `FUN_0088f170`, `FUN_0088f280` |
| `hkStaticClassNameRegistry` | `FUN_0095c300`, `FUN_0095c330` |
| `hkStatisticsCollectorClassListener` | `FUN_0089be40` |
| `hkStdioStreamReader` | `FUN_00899550`, `FUN_00899590` |
| `hkStdioStreamWriter` | `FUN_00899720`, `FUN_00899760`, `FUN_008997a0` |
| `hkSubStreamWriter` | `FUN_0095e5b0` |
| `hkThreadMemory` | `FUN_0088c730`, `FUN_0088ce70` |
| `hkVersionRegistry` | `FUN_0095b500` |
| `hkXmlObjectReader` | `FUN_00966e60` |
| `hkXmlObjectWriter` | `FUN_00963e10` |
| `hkXmlPackfileReader` | `FUN_0095ec80`, `FUN_0095ee40` |
| `hkXmlPackfileUpdateTracker` | `FUN_0095ee40` |
| `hkXmlPackfileWriter` | `FUN_0095d170` |
| `hkXmlParser` | `FUN_00965830`, `FUN_00965890` |
| `hkaAnimatedSkeleton` | `FUN_00884190`, `FUN_008841d0` |
| `hkaAnimationControlListener` | `FUN_00883680`, `FUN_00884190`, `FUN_008841d0` |
| `hkaDefaultAnimatedReferenceFrame` | `FUN_009ef460`, `FUN_009f39e0`, `FUN_009f3e60` |
| `hkaDefaultChunkCache` | `FUN_00887ef0`, `FUN_00888160` |
| `hkaDeltaCompressedSkeletalAnimation` | `FUN_009ef3f0`, `FUN_009f2980` |
| `hkaFootPlacementIkSolver` | `FUN_009ef650` |
| `hkaInterleavedSkeletalAnimation` | `FUN_009ef240` |
| `hkaMultithreadedChunkCache` | `FUN_00886c60`, `FUN_00886cf0` |
| `hkaRagdollInstance` | `FUN_0088c000`, `FUN_0088c0a0`, `FUN_0088c180` |
| `hkaSkeletalAnimation` | `FUN_009f8b10` |
| `hkaSkeletonMapper` | `FUN_0087c540`, `FUN_0087d500`, `FUN_009ef4d0` |
| `hkaSplineSkeletalAnimation` | `FUN_009ef610`, `FUN_009f8b10`, `FUN_009f9dc0` |
| `hkaWaveletSkeletalAnimation` | `FUN_009ef540`, `FUN_009f54b0` |
| `hkp3AxisSweep` | `FUN_009347e0`, `FUN_00935670` |
| `hkpAabbPhantom` | `FUN_008defa0` |
| `hkpAllCdPointCollector` | `FUN_00424130`, `FUN_0042c2a0`, `FUN_0042c320`, `FUN_00950010`, `FUN_009518e0`, `FUN_009519e0` |
| `hkpBallAndSocketConstraintData` | `FUN_008e5f30` |
| `hkpBallSocketChainData` | `FUN_008e8dd0`, `FUN_008e8e30`, `FUN_008e8e60` |
| `hkpBoxMotion` | `FUN_008ddc10`, `FUN_008f6030` |
| `hkpBoxShape` | `FUN_008a86c0`, `FUN_00a0cb70` |
| `hkpBreakableConstraintData` | `FUN_008e4390`, `FUN_008e4410`, `FUN_008e4440` |
| `hkpBroadPhase` | `FUN_00907c60`, `FUN_00907d90` |
| `hkpBroadPhaseBorder` | `FUN_008fa620`, `FUN_008fa770` |
| `hkpBroadPhaseBorderListener` | `FUN_008d8c70` |
| `hkpBroadPhaseCastCollector` | `FUN_00416e50`, `FUN_008dc660` |
| `hkpBroadPhaseListener` | `FUN_008cd670`, `FUN_008cd6a0`, `FUN_008cd770`, `FUN_008cdb90`, `FUN_008d8c70`, `FUN_008dc680` … |
| `hkpBvAgent` | `FUN_008bfe70` |
| `hkpBvShape` | `FUN_00a0cea0`, `FUN_00a12b60` |
| `hkpBvTreeAgent` | `FUN_008c57b0`, `FUN_008c7fa0` |
| `hkpBvTreeStreamAgent` | `FUN_008bd800`, `FUN_008befd0` |
| `hkpCachingShapePhantom` | `FUN_008e7d60`, `FUN_008e7da0` |
| `hkpCapsuleShape` | `FUN_008a9d00`, `FUN_00a0ca70` |
| `hkpCdBodyPairCollector` | `FUN_008aa8d0`, `FUN_008c0aa0` |
| `hkpCdPointCollector` | `FUN_00424130`, `FUN_0042aff0`, `FUN_0042c320`, `FUN_008aa880`, `FUN_008c0af0`, `FUN_009518e0` |
| `hkpCharacterContext` | `FUN_0094d2e0`, `FUN_0094d340` |
| `hkpCharacterMotion` | `FUN_008d5e50`, `FUN_008ddc10` |
| `hkpCharacterProxy` | `FUN_0094f2c0`, `FUN_0094f350` |
| `hkpCharacterStateInAir` | `FUN_0094d7b0` |
| `hkpCharacterStateJumping` | `FUN_00951ef0` |
| `hkpCharacterStateManager` | `FUN_00951c20`, `FUN_00951c60` |
| `hkpCharacterStateOnGround` | `FUN_0094ce90` |
| `hkpClosestCdPointCollector` | `FUN_008d07a0` |
| `hkpCollidableCollidableFilter` | `FUN_006aee30`, `FUN_006aef10`, `FUN_00a16220` |
| `hkpCollisionDispatcher` | `FUN_008c4de0`, `FUN_008c4ef0` |
| `hkpCollisionFilterList` | `FUN_00a0d6a0`, `FUN_00a0d6e0`, `FUN_00a16120`, `FUN_00a16220`, `FUN_00a162d0` |
| `hkpConstraintChainInstance` | `FUN_008e92e0`, `FUN_008e9360` |
| `hkpConstraintChainInstanceAction` | `FUN_008e92e0` |
| `hkpConstraintInstance` | `FUN_008e4980`, `FUN_008e49f0`, `FUN_00a432e0` |
| `hkpConstraintMotor` | `FUN_008df750` |
| `hkpConstraintOwner` | `FUN_008e7aa0`, `FUN_008e7b50`, `FUN_008e7da0` |
| `hkpContinuousSimulation` | `FUN_0092c4d0`, `FUN_0092c560` |
| `hkpConvexListShape` | `FUN_00a0c910`, `FUN_00a0c970`, `FUN_00a0cd70` |
| `hkpConvexPieceMeshShape` | `FUN_00a0d3d0`, `FUN_00a140e0` |
| `hkpConvexPieceShape` | `FUN_00a17210` |
| `hkpConvexPieceStreamData` | `FUN_00a437e0` |
| `hkpConvexTransformShape` | `FUN_008cc480`, `FUN_00a0d7f0` |
| `hkpConvexTranslateShape` | `FUN_008cbaf0`, `FUN_00a0cfd0` |
| `hkpConvexVerticesConnectivity` | `FUN_00a0d200` |
| `hkpConvexVerticesShape` | `FUN_008bbaf0`, `FUN_008bbdb0`, `FUN_00a0cd20` |
| `hkpCylinderShape` | `FUN_008c2f20`, `FUN_008c2fc0` |
| `hkpDefaultConvexListFilter` | `FUN_008d8c70`, `FUN_00a0d450` |
| `hkpDefaultToiResourceMgr` | `FUN_00942bf0` |
| `hkpDefaultWorldMaintenanceMgr` | `FUN_008fa310` |
| `hkpDeferredConstraintOwner` | `FUN_008fda80` |
| `hkpEntity` | `FUN_008ddb00`, `FUN_008ddc10`, `FUN_008de450` |
| `hkpEntityEntityBroadPhaseListener` | `FUN_008fabd0` |
| `hkpEntityListener` | `FUN_004022e0`, `FUN_00402820`, `FUN_0041c530`, `FUN_0041e4f0`, `FUN_0043d1b0`, `FUN_00446460` … |
| `hkpExtendedMeshShape` | `FUN_00a113c0`, `FUN_00a11480`, `FUN_00a116f0`, `FUN_00a117d0` |
| `hkpFastMeshShape` | `FUN_00a0cd90`, `FUN_00a0cdc0` |
| `hkpFixedRigidMotion` | `FUN_008ddc10` |
| `hkpFlagCdBodyPairCollector` | `FUN_008bff50`, `FUN_008c0400`, `FUN_008c0580`, `FUN_008c06e0`, `FUN_008c0860`, `FUN_008d07a0` … |
| `hkpGenericConstraintData` | `FUN_008e62e0`, `FUN_008e6320` |
| `hkpGroupFilter` | `FUN_00a0d080`, `FUN_00a0d0c0` |
| `hkpGskfAgent` | `FUN_008ce1a0` |
| `hkpHeightFieldAgent` | `FUN_008aefc0`, `FUN_008b0060` |
| `hkpHingeConstraintData` | `FUN_008e5d80` |
| `hkpKeyframedRigidMotion` | `FUN_008ddc10`, `FUN_008f4740`, `FUN_00a43330` |
| `hkpLimitedForceConstraintMotor` | `FUN_008df750` |
| `hkpLimitedHingeConstraintData` | `FUN_008dfc30`, `FUN_008dff50` |
| `hkpListAgent` | `FUN_008aea60` |
| `hkpListShape` | `FUN_008cb570`, `FUN_008cb5a0` |
| `hkpMapPointsToSubShapeContactMgr` | `FUN_008d0d00`, `FUN_00925840` |
| `hkpMaxSizeMotion` | `FUN_006b2140`, `FUN_008d5960`, `FUN_008ddb00`, `FUN_008ddc10`, `FUN_00a43360` |
| `hkpMeshShape` | `FUN_00a0e060`, `FUN_00a0e0c0` |
| `hkpMoppAgent` | `FUN_008c82a0` |
| `hkpMoppBvTreeShape` | `FUN_00a0cc30`, `FUN_00a124b0` |
| `hkpMoppCode` | `FUN_00a439c0`, `FUN_00a439d0` |
| `hkpMoppModifier` | `FUN_00a0ca80`, `FUN_00a12080`, `FUN_00a122b0` |
| `hkpMotion` | `FUN_008df590` |
| `hkpMultiRayConvexAgent` | `FUN_008bcc30` |
| `hkpMultiRayShape` | `FUN_00a0cf20`, `FUN_00a12e00` |
| `hkpMultiSphereAgent` | `FUN_008c1a90` |
| `hkpMultiSphereShape` | `FUN_00a0d010` |
| `hkpMultiThreadedSimulation` | `FUN_008f75e0`, `FUN_008f7930` |
| `hkpNullAgent` | `FUN_008d2260` |
| `hkpNullBroadPhaseListener` | `FUN_008cd6a0` |
| `hkpNullCollisionFilter` | `FUN_008d8c70`, `FUN_008dc490`, `FUN_00a09020`, `FUN_00a0d310`, `FUN_00a0d350` |
| `hkpNullContactMgr` | `FUN_008d6420` |
| `hkpNullContactMgrFactory` | `FUN_008d6420` |
| `hkpPhantom` | `FUN_008df2c0`, `FUN_008f9f00` |
| `hkpPhantomAgent` | `FUN_008ae450` |
| `hkpPhantomBroadPhaseListener` | `FUN_008d8c70` |
| `hkpPhantomListener` | `FUN_0094d9d0`, `FUN_0094f2c0`, `FUN_0094f350` |
| `hkpPhantomOverlapListener` | `FUN_008fa5e0`, `FUN_008fa620`, `FUN_008fa770` |
| `hkpPhysicsData` | `FUN_00953780`, `FUN_00953a30`, `FUN_00953b40` |
| `hkpPhysicsSystem` | `FUN_008e4df0`, `FUN_008e4e40`, `FUN_00a43180` |
| `hkpPhysicsSystemWithContacts` | `FUN_00953a60`, `FUN_00955860` |
| `hkpPlaneShape` | `FUN_00a0d530` |
| `hkpPositionConstraintMotor` | `FUN_008df700`, `FUN_008df750` |
| `hkpPredGskfAgent` | `FUN_008d0b90`, `FUN_008d1260`, `FUN_008d1390` |
| `hkpPrismaticConstraintData` | `FUN_008e0540`, `FUN_008e05c0` |
| `hkpRagdollConstraintData` | `FUN_008e2950`, `FUN_008e2a00` |
| `hkpRagdollLimitsData` | `FUN_008e9940` |
| `hkpRayCollidableFilter` | `FUN_006aee50`, `FUN_006aef10`, `FUN_00a16220` |
| `hkpRayHitCollector` | `FUN_00416d40`, `FUN_008afec0` |
| `hkpRayShapeCollectionFilter` | `FUN_006aee90`, `FUN_006aef10`, `FUN_00a16220` |
| `hkpRemoveTerminalsMoppModifier` | `FUN_00a0cae0`, `FUN_00a12080`, `FUN_00a122b0` |
| `hkpReportContactMgr` | `FUN_008f95c0` |
| `hkpRigidBody` | `FUN_008d4be0`, `FUN_008d5570`, `FUN_00a42b00`, `FUN_00a42b20` |
| `hkpSampledHeightFieldShape` | `FUN_00a0e3d0` |
| `hkpSerializedAgentNnEntry` | `FUN_00955a90` |
| `hkpShapeCollectionFilter` | `FUN_006aee70`, `FUN_006aef10`, `FUN_00a16220` |
| `hkpShapeContainer` | `FUN_007251c0`, `FUN_00725360`, `FUN_00725480`, `FUN_00725500`, `FUN_008bf670`, `FUN_008cb570` … |
| `hkpShapePhantom` | `FUN_008e7930` |
| `hkpSimpleClosestContactCollector` | `FUN_008c00f0`, `FUN_008c0290`, `FUN_008cf2e0`, `FUN_008d0a60` |
| `hkpSimpleConstraintContactMgr` | `FUN_008d4640`, `FUN_008d46e0` |
| `hkpSimpleContactConstraintData` | `FUN_008d4a40`, `FUN_008dd3c0` |
| `hkpSimpleMeshShape` | `FUN_00a0d590` |
| `hkpSimpleShapePhantom` | `FUN_008e8700`, `FUN_008e8740` |
| `hkpSimulation` | `FUN_008f2320`, `FUN_00a42ae0` |
| `hkpSimulationIsland` | `FUN_008eb900`, `FUN_008ebc30` |
| `hkpSingleShapeContainer` | `FUN_008cbaf0`, `FUN_008cbd80`, `FUN_008cc480`, `FUN_008ccfa0`, `FUN_008cd08c`, `FUN_008cd610` … |
| `hkpSphereMotion` | `FUN_008d5df0`, `FUN_008ddc10` |
| `hkpSphereShape` | `FUN_008a92b0`, `FUN_00a0d7a0` |
| `hkpStabilizedBoxMotion` | `FUN_008ddc10`, `FUN_008f5fb0` |
| `hkpStabilizedSphereMotion` | `FUN_008d5e20`, `FUN_008ddc10` |
| `hkpStorageExtendedMeshShape` | `FUN_00a0a360`, `FUN_00a0a4c0`, `FUN_00a0af80` |
| `hkpStorageMeshShape` | `FUN_00a0b650`, `FUN_00a0bc00`, `FUN_00a0bc80` |
| `hkpStorageSampledHeightFieldShape` | `FUN_00a09b80`, `FUN_00a09cb0`, `FUN_00a0a2f0` |
| `hkpSymmetricAgentFlipBodyCollector` | `FUN_008acf30`, `FUN_008ad180`, `FUN_008adf00`, `FUN_008ae080`, `FUN_008aecd0`, `FUN_008b05e0` … |
| `hkpSymmetricAgentFlipCastCollector` | `FUN_008aa780`, `FUN_008acfb0`, `FUN_008ad380`, `FUN_008adf80`, `FUN_008ae280`, `FUN_008aee70` … |
| `hkpSymmetricAgentFlipCollector` | `FUN_008acf70`, `FUN_008ad1c0`, `FUN_008adf40`, `FUN_008ae0c0`, `FUN_008aec90`, `FUN_008b0620` … |
| `hkpThinBoxMotion` | `FUN_008ddc10`, `FUN_008f5fe0` |
| `hkpTransformAgent` | `FUN_008ad5b0`, `FUN_008adc00` |
| `hkpTransformShape` | `FUN_008cd08c`, `FUN_00a0d120` |
| `hkpTriSampledHeightFieldBvTreeShape` | `FUN_00a0d4a0` |
| `hkpTriSampledHeightFieldCollection` | `FUN_008bf670`, `FUN_00a0d2f0` |
| `hkpTriangleShape` | `FUN_00725600`, `FUN_008bf6e0`, `FUN_00a0d1c0`, `FUN_00a0ddd0`, `FUN_00a10b70`, `FUN_00a129c0` … |
| `hkpUnaryAction` | `FUN_008e83e0` |
| `hkpWorld` | `FUN_008d8340`, `FUN_008d8470`, `FUN_008d8c70` |
| `hkpWorldCinfo` | `FUN_008e2da0`, `FUN_008e2f50` |
| `hkpWorldDeletionListener` | `FUN_008fa600`, `FUN_008fa620`, `FUN_008fa770` |
| `hkpWorldObject` | `FUN_008dca40`, `FUN_008dcb90` |
| `hkpWorldRayCaster` | `FUN_00415670`, `FUN_008d6330` |