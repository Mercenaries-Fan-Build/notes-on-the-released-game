# Animation & Skeleton

Character/object animation: skeletons, poses, keyframe sampling, bone controllers, ragdoll blending, IK, facial animation, and GPU skinning/morph.

Provenance: symbol/string evidence recovered from the Xbox 360 devkit "Profile" build `Mercs2_Xenon_P.exe` (Mercenaries 2: World in Flames, Jul 11 2008 preview, PowerPC). Decompressed PE at `output/jul08_prototype/mercs2_xenon_p.pe_full.bin`. This is string/RTTI evidence, not a real `.pdb`. Offsets are PE file offsets as listed in `output/jul08_prototype/inventory/animation-skeleton.txt`.

## Overview

This subsystem drives skeletal animation for humans, vehicles, and objects in Pandemic's "Pangea" engine, layered on top of the **Havok Animation (hka)** and **Havok Behavior (hkb)** middleware. The pipeline runs from animation data load (`PgAnimation::ReadData`, `FindAnimationData`, `LookupAnimation`) through pose sampling (`Animation::HumanSamplePose`, `Animation::SampleMt`, `setToReferencePose`), bone-controller post-processing (`BoneController`, the `BoneCtrl*` family), ragdoll blending (`extractRagdollPose`, the `animationToRagdollSkeletonMapper` / `ragdollToAnimationSkeletonMapper` mappers), facial animation (FaceFX `Fx*` / `PgFaceFx*`), and finally GPU skinning/morphing (`PgSkin*VP` / `PgMesh*MorphVP` shaders, `BoneMatrixArray`, `rotateBonesForSkinning`).

The multithreaded/job symbols (`Animation::SampleMt`, `AnimCpuSampleJob`, `AnimCpuUpdateJob`, `AnimPreUpdateST`, `AnimPostSampleST`, `AnimUpdateAndSampleBegin`, `PgSysAnimation`) together with the `AnimCpuCapEnabled` tunables point to animation update/sample being split across CPU phases with a per-frame time budget.

The Havok-side classes (`hkaSkeletalAnimation` and its Delta/Spline/Wavelet/Interleaved compression variants, `hkaSkeletonMapper`, `hkaRagdollInstance`, and the large `hkb*` behavior-graph/modifier set) show the engine uses Havok's animation runtime, behavior graphs, IK modifiers, and powered-ragdoll blending.

## Source files

No animation-specific Pandemic source path appears in `output/jul08_prototype/mercs2_xenon_p.source_paths.txt` (it lists only Lua, Pal, Pimp, AI, sound, and Xenon-graphics paths). However, the full strings file contains Havok-middleware source filenames for this system (verbatim):

```
.\Rig\hkaSkeletonUtils.cpp
.\Mapper\hkaSkeletonMapper.cpp
.\Mapper\hkaSkeletonMapperUtils.cpp
.\Utils\hkaRagdollUtils.cpp
```

(These are Havok SDK paths embedded in the binary, not Pandemic project paths; the Pangea animation translation units are not named in `source_paths.txt`.)

## Key classes

Demangled from `output/jul08_prototype/mercs2_xenon_p.rtti_classes.txt` (`.?AV<Name>@@` -> `class <Name>`):

Havok Animation (hka):
- `class hkaAnimatedReferenceFrame`
- `class hkaAnimatedSkeleton`
- `class hkaAnimationControl`
- `class hkaAnimationControlListener`
- `class hkaChunkCache`
- `class hkaDefaultAnimatedReferenceFrame`
- `class hkaDefaultAnimationControl`
- `class hkaDefaultChunkCache`
- `class hkaDeltaCompressedSkeletalAnimation`
- `class hkaFootPlacementIkSolver`
- `class hkaInterleavedSkeletalAnimation`
- `class hkaMultithreadedChunkCache`
- `class hkaRagdollInstance`
- `class hkaSkeletalAnimation`
- `class hkaSkeletonMapper`
- `class hkaSplineSkeletalAnimation`
- `class hkaWaveletSkeletalAnimation`

Havok ragdoll constraint (hkp) — shared with the physics docs:
- `class hkpRagdollConstraintData`
- `class hkpRagdollLimitsData`

(The `hkb*` behavior/modifier names below appear in the strings file but not as `.?AV...@@` RTTI entries, so they are listed under "Symbols by area" rather than here.)

## Symbols by area

### Animation data load & lookup
| Offset | Section | Symbol |
|---|---|---|
| 0x00421c8 | .rdata | `PgAnimation::ReadData` |
| 0x004223c | .rdata | `FindAnimationData` |
| 0x0042644 | .rdata | `LookupAnimation` |
| 0x00631dc | .rdata | `useAnimationData` |
| 0x0053ce4 | .rdata | `AnimationType` |
| 0x0b8a1fc | .data | `PgAnimationTable` |
| 0x0b8a3a0 | .data | `PgAnimationSequenceTable` |
| 0x0b8a3bc | .data | `PgAnimationTransitionTable` |
| 0x0b8a4e0 | .data | `PgAnimation` |

Reads/looks up animation assets and exposes the runtime animation/sequence/transition tables. `RuntimeAnimationParams` (0x00319e0) and `ActionAnimationTable` (0x003e434) configure per-action animation params.

### Pose sampling & update (single- and multi-threaded)
| Offset | Section | Symbol |
|---|---|---|
| 0x00427ac | .rdata | `Animation::HumanSamplePose` |
| 0x00427c8 | .rdata | `Animation::HumanUpdate` |
| 0x00427e0 | .rdata | `Animation::UpdateEvents` |
| 0x004287c | .rdata | `Animation::SampleMt` |
| 0x0042890 | .rdata | `AnimPostSampleST` |
| 0x00428a4 | .rdata | `AnimUpdateAndSampleBegin` |
| 0x00428c0 | .rdata | `AnimPreUpdateST` |
| 0x00428d0 | .rdata | `AnimCpuSampleJob` |
| 0x00428e4 | .rdata | `AnimCpuUpdateJob` |
| 0x00428f8 | .rdata | `PgSysAnimation` |
| 0x004210c | .rdata | `setToReferencePose` |
| — | — | (`ST` = single-thread, `Mt` = multi-thread) |

The animation system (`PgSysAnimation`) runs a pre-update / sample / post-sample pipeline. `Animation::SampleMt` plus the `AnimCpu*Job` symbols indicate sampling is dispatched as CPU jobs. `setToReferencePose` resets a pose to the skeleton reference pose.

### Bone controllers (post-sample skeleton manipulation)
| Offset | Section | Symbol |
|---|---|---|
| 0x004285c | .rdata | `BoneController` |
| 0x0042848 | .rdata | `BoneControllerLod` |
| 0x0031cc0 | .rdata | `BoneControllerRuntime` |
| 0x00321f0 | .rdata | `HumanAnimationControllerNEW` |
| 0x0031c9c | .rdata | `AnimationController` |
| 0x00322b0 | .rdata | `BoneCtrlLookAt` |
| 0x00322c0 | .rdata | `BoneCtrlRotationCopy` |
| 0x00322d8 | .rdata | `BoneCtrlFakeWheel` |
| 0x0032304 | .rdata | `BoneCtrlLocalRotation` |
| 0x003231c | .rdata | `BoneCtrlLocalTranslation` |
| 0x0032338 | .rdata | `BoneCtrlTentacle` |
| 0x003234c | .rdata | `BoneCtrlStrapOn` |
| 0x003235c | .rdata | `BoneCtrlJostle` |
| 0x003236c | .rdata | `BoneCtrlWind` |
| 0x0030fa4 | .rdata | `BoneCtrlPhysicsActor` |
| 0x004115c | .rdata | `Anim_RemoveControllers` |
| 0x0041174 | .rdata | `Anim_AddControllers` |

A family of procedural per-bone modifiers applied after sampling: look-at, rotation copy, local rot/trans, tentacle, "strap-on" (attached props), jostle, wind, and a physics-actor-driven bone. `BoneControllerLod` implies LOD-based controller gating. The corresponding controller "animation" objects appear at 0x003ff7c–0x004019b: `HumanAnimation`, `HVehicleAnimation`, `TurretAnimation`, `LookAtAnimation`, `RotationCopyAnimation`, `hRotationAnimation`, `TentacleAnimation`, `JostleAnimation`, `WindAnimation`, `PPhysicsActorAnimation`.

### Skeletons, poses & bone indices
| Offset | Section | Symbol |
|---|---|---|
| 0x005bfd0 | .rdata | `animatedSkeleton` |
| 0x005e158 | .rdata | `animationSkeleton` |
| 0x005e148 | .rdata | `ragdollSkeleton` |
| 0x005e0ec | .rdata | `mirroredSkeleton` |
| 0x005e16c | .rdata | `mirroredSkeletonInfo` |
| 0x0053e64 | .rdata | `referencePose` |
| 0x005a7fc | .rdata | `bindPose` |
| 0x0071330 | .rdata | `inverseWorldBindPose` |
| 0x005ec5c | .rdata | `numberOfPoses` |
| 0x0088cf8 | .rdata | `lastPose` |
| 0x008a3fc | .rdata | `initialPoseGenerator` |
| 0x00842c0 | .rdata | `matchingPose` |
| 0x00842d0 | .rdata | `matchingPoseControl` |
| 0x005d9ac | .rdata | `rootBoneIndex` |
| 0x005d988 | .rdata | `anotherBoneIndex` |
| 0x005d99c | .rdata | `otherBoneIndex` |
| 0x0062758 | .rdata | `startBoneIndex` |
| 0x0062768 | .rdata | `endBoneIndex` |
| 0x008bbf4 | .rdata | `isFixedOrKeyframed` |
| 0x005d168 | .rdata | `keyframedBones` |
| 0x0092a48 | .rdata | `numberOfBoneTracks` |
| 0x00b8a4e0 (PgAnimation) | — | (see load area) |

Pose/skeleton state plus per-feature bone-index fields (`startBone*`, `endBone*`, `rootBoneIndex`, etc.). `bindPose` / `inverseWorldBindPose` feed skinning; `keyframedBones` / `isFixedOrKeyframed` mark bones driven by keyframes vs physics.

### Skeleton mapping & track→bone binding
| Offset | Section | Symbol |
|---|---|---|
| 0x005e100 | .rdata | `animationToRagdollSkeletonMapper` |
| 0x005e124 | .rdata | `ragdollToAnimationSkeletonMapper` |
| 0x0053c70 | .rdata | `transformTrackToBoneIndices` |
| 0x0068b0c | .rdata | `animationTrackToBoneIndices` |
| 0x006e1e4 | .rdata | `bindingForMirroredAnimation` |
| 0x0070a24 | .rdata | `bindingForUnMirroredAnimation` |
| 0x005e7c4 | .rdata | `unmappedBones` |
| 0x005368c | .rdata | `StunmappedBones` |
| 0x00536c8 | .rdata | `LtMapPose` |
| 0x005e1b0 | .rdata | `ragdollBoneInfo` |
| 0x005e1c0 | .rdata | `animationBoneInfo` |

Maps the animation skeleton to/from the ragdoll skeleton and binds animation tracks to skeleton bone indices, with separate mirrored/un-mirrored bindings for left/right-flipped animation. Matches Havok's `hkaSkeletonMapper` (see `.\Mapper\hkaSkeletonMapper.cpp`).

### Ragdoll blending (animation ↔ physics)
| Offset | Section | Symbol |
|---|---|---|
| 0x005bbc0 | .rdata | `extractRagdollPose` |
| 0x005b63c | .rdata | `ragdollBoneToConstrain` |
| 0x005c1d8 | .rdata | `ragdollBoneLayers` |
| 0x005b988 | .rdata | `directionOfFallRagdollBoneIndex` |
| 0x005b9a8 | .rdata | `velocityRagdollBoneIndex` |
| 0x005bc70 | .rdata | `ragdollRightFootBoneIndex` |
| 0x005bc8c | .rdata | `ragdollLeftFootBoneIndex` |
| 0x005d734 | .rdata | `sensingRagdollBoneIndex` |
| 0x0063418 | .rdata | `senseFromRagdollBone` |
| 0x0063430 | .rdata | `sensorBoneIndex` |
| 0x0063400 | .rdata | `sensorOffsetInBoneSpace` |
| 0x0065a34 | .rdata | `catchFallDirectionRagdollBoneIndex` |
| 0x0068a64 | .rdata | `catchFallDirectionRagdollBone` |
| 0x0065a68 | .rdata | `ragdollBoneUpLS` |
| 0x0065a78 | .rdata | `ragdollBoneRightLS` |
| 0x0065a8c | .rdata | `ragdollBoneForwardLS` |
| 0x0063344 | .rdata | `ragdollBoneIndex` |
| 0x0063330 | .rdata | `animationBoneIndex` |
| 0x005b160 | .rdata | `heldFromSkeleton` |
| 0x005b19c | .rdata | `heldFromPose` |
| 0x005b188 | .rdata | `heldFromPoseSize` |

Blends animation against a Havok ragdoll: extracting the current ragdoll pose, choosing which bone to constrain, and "sense"/"catch-fall" logic (fall-direction, velocity, foot bones) — consistent with Havok's get-up / catch-fall behavior modifiers. Local-space (`*LS`) and bone-space (`*InBoneSpace`) suffixes denote coordinate frames.

### Pose matching, reach & length limits
| Offset | Section | Symbol |
|---|---|---|
| 0x005e1d4 | .rdata | `poseMatchingAnotherBoneIndex` |
| 0x005e1f4 | .rdata | `poseMatchingOtherBoneIndex` |
| 0x005e210 | .rdata | `poseMatchingRootBoneIndex` |
| 0x005ce5c | .rdata | `reachReferenceBoneIdx` |
| 0x005dc64 | .rdata | `referencePoseWeightThreshold` |
| 0x0068aa8 | .rdata | `minBoneLength` |
| 0x0068ab8 | .rdata | `maxBoneLength` |
| 0x0068ac8 | .rdata | `minBoneLengthFraction` |
| 0x0068ae0 | .rdata | `maxBoneLengthFraction` |
| 0x005e838–0x005e85c | .rdata | `endBoneB`, `startBoneB`, `endBoneA`, `startBoneA` |

Supports Havok pose-matching generators and reach/IK length constraints (cf. `hkbPoseMatchingGenerator`, `hkbReachModifier` below).

### Attachment, keyframed physics & "held" props
| Offset | Section | Symbol |
|---|---|---|
| 0x001e488 | .rdata | `SetNodePhysicsModelKeyframed` |
| 0x0000d88 | .rdata | `UpdatePoseAndTransform` |
| 0x0000da0 | .rdata | `UpdateKeyframedPhysicsActors` |
| 0x0013ab8 | .rdata | `MatchCapsuleToPose` |
| 0x005e550 | .rdata | `attacheeBoneIndex` |
| 0x005e564 | .rdata | `attacherBoneIndex` |
| 0x0063228 | .rdata | `finalAnimBoneOrientationMS` |
| 0x0063244 | .rdata | `initialAnimBonePositionMS` |
| 0x0063260 | .rdata | `finalAnimBonePositionMS` |
| 0x0063278 | .rdata | `lastAnimBonePositionMS` |
| 0x006331c | .rdata | `offsetInBoneSpace` |
| 0x00827b8 | .rdata | `lowerBodyBones` |

Drives keyframed (animation-driven) Havok physics actors and attaches bodies to bones (attacher/attachee). `MS` = model-space anim-bone positions/orientations. `MatchCapsuleToPose` keeps the character collision capsule aligned to the animated pose.

### Facial animation (FaceFX)
| Offset | Section | Symbol |
|---|---|---|
| 0x0026668 | .rdata | `PlayFaceAnim` |
| 0x002668c | .rdata | `BindFaceAnimSet` |
| 0x0026678 | .rdata | `UnbindFaceAnimSet` |
| 0x00be70f | .rdata | `PFxBonePoseNode` |
| 0x00be972 | .rdata | `N0FxAnimCurve` |
| 0x0b8a4c4 | .data | `PgFaceFxAnimationSetAsset` |

Plays/binds facial animation via the FaceFX runtime. The strings file additionally lists `FxActor`, `FxActorInstance`, `FxAnim`, `FxAnimSet`, `FxAnimGroup`, `FxFaceGraph`, `FxFaceGraphNode`, `FxBone`, `PFxDeltaNode`, `PFxCurrentTimeNode`, `PFxCombinerNode`, `FaceFXActor`, and `PgFaceFxActorAsset` — the FaceFX face-graph node set wrapped in Pangea assets.

### GUI / sprite / minimap / material "animation" (non-skeletal)
| Offset | Section | Symbol |
|---|---|---|
| 0x0029c40 | .rdata | `PlayAnimation` |
| 0x0029c30 | .rdata | `StopAnimation` |
| 0x0029c18 | .rdata | `StopAnimationChannel` |
| 0x0029c04 | .rdata | `StopAllAnimation` |
| 0x002897c | .rdata | `PlayRawAnimation` |
| 0x002d640 | .rdata | `GuiAnimateUpdate` |
| 0x0027c84 | .rdata | `AnimateSprite` |
| 0x0027c70 | .rdata | `HaltSpriteAnimation` |
| 0x0027f8c | .rdata | `AnimateText` |
| 0x0027f78 | .rdata | `HaltTextAnimation` |
| 0x00280d0 | .rdata | `SetImageClockAnimation` |
| 0x0027e58 | .rdata | `MinimapAnimateObjectiveSonar` |
| 0x0027e78 | .rdata | `MinimapAnimateObjectiveAlpha` |
| 0x0027e98 | .rdata | `MinimapAnimateObjectiveSize` |
| 0x003168c | .rdata | `LightAnimation` |
| 0x00316a8 | .rdata | `ColorAnimation` |
| 0x00316b8 | .rdata | `ScaleAnimation` |
| 0x0040f34 | .rdata | `ScaleAnimation::Deactivate` |
| 0x0040f50 | .rdata | `ScaleAnimation::Activate` |

UI/sprite/text/minimap and light/color/scale "animation" — driven by the same word but distinct from skeletal animation. Included because they share the inventory category; they are property tweens, not bone animation (inferred).

### GPU skinning & morph (vertex shaders)
| Offset | Section | Symbol |
|---|---|---|
| 0x00c501c | .rdata | `BoneMatrixArray` |
| 0x0093840 | .rdata | `rotateBonesForSkinning` |
| 0x00c49fc | .rdata | `PgSkinMorphVP` |
| 0x00c4994 | .rdata | `PgSkinMorphNoColorVP` |
| 0x00c49c8 | .rdata | `PgSkinMorphNoTangentVP` |
| 0x00c4950 | .rdata | `PgSkinMorphNoTangentNoColorVP` |
| 0x00c47a0 | .rdata | `PgSkinRefractMorphVP` |
| 0x00c475c | .rdata | `PgSkinRefractVPMorphNoTangent` |
| 0x00c4d9c | .rdata | `PgMeshMorphVP` |
| 0x00c4d34 | .rdata | `PgMeshMorphNoColorVP` |
| 0x00c4cf0 | .rdata | `PgMeshMorphNoTangentNoColorVP` |
| 0x00c4c5c | .rdata | `PgMeshRefractMorphVP` |
| 0x00c4c18 | .rdata | `PgMeshRefractVPMorphNoTangent` |

The skinned/morph vertex-shader permutation set (`*VP` with `.sho` compiled-shader siblings, e.g. `PgSkinVPMorph.sho`). `BoneMatrixArray` is the per-draw bone-matrix palette; `rotateBonesForSkinning` prepares bone rotations for the skin. The strings file also lists `PgSkinMorphShadowVP` / `PgMeshMorphShadowVP` shadow-pass variants.

### Misc / object & vehicle animation
| Offset | Section | Symbol |
|---|---|---|
| 0x003125c | .rdata | `HumanAnimationSystem` |
| 0x0031274 | .rdata | `HumanAnimationSet` |
| 0x0031288 | .rdata | `VehicleAnimationSet` |
| 0x002d79c | .rdata | `HumanAnimationNearlyCompleted` |
| 0x0013ba4 | .rdata | `AnimationEvent` |
| 0x003240c | .rdata | `AnimationResponse` |
| 0x001e590 / 0x001e584 | .rdata | `StartAnim` / `StopAnim` |
| 0x003f01c | .rdata | `AnimThenDisappear` |
| 0x0032610 | .rdata | `BuildingCollapseAnim` |
| 0x0039fe4 | .rdata | `BuildingCollapseAnimType` |
| 0x003b2c8 | .rdata | `CoverAnimEnum` |
| 0x003ce28 | .rdata | `CoverAnimation` |
| 0x003e434 | .rdata | `ActionAnimationTable` |
| 0x006e120 | .rdata | `drawSkeleton` |
| 0x00fd810 | .rdata | `TtsamplePose` |
| 0x005e2f4 | .rdata | `deletePoseLocal` |
| 0x0042890 | .rdata | `AnimPostSampleST` (see sampling) |

Per-actor animation sets (human/vehicle), animation events/responses, building-collapse and cover animations, and the `drawSkeleton` debug visualizer.

### Named vehicle/object control bones (string constants)
`RotorBlurOffBone` (0x003b3f8), `RotorBlurOnBone` (0x003b40c), `FirstRotorBladeBoneName` (0x003b43c), `RotorHubBoneName` (0x003b45c), `ControlledWheelBone` (0x003b4a4), `ControlledSuspensionBone` (0x003b4b8), `SuspensionStartBone` (0x003b4d4), `LookAtBone` (0x003b4e8), `ControlledBone` (0x003b4f4), `SrcBone`/`DestBone` (0x003b530/0x003b538), `EndBone`/`StartBone` (0x003b614/0x003b61c), `VisPosBone`/`VisRotBone`/`VisYawBone` (0x003b774/780/78c), `SuspBone` (0x003b798), `VisRudderBone` (0x003d378), `WinchBone` (0x003e24c), `DoorBoneName` (0x003cda0), `BoneName` (0x003b8e8), `AnimaitonName` (0x003b984, sic — misspelled in the binary), `BonePitch`/`BoneYaw` (0x003b824/0x003b878), `AnimationScale` (0x003b55c). These are field/config names that map a controller (e.g. fake wheel, look-at, rotor blur) to a specific skeleton bone.

## Notable strings

Havok middleware source files (full strings file):
- `.\Rig\hkaSkeletonUtils.cpp`, `.\Mapper\hkaSkeletonMapper.cpp`, `.\Mapper\hkaSkeletonMapperUtils.cpp`, `.\Utils\hkaRagdollUtils.cpp`
- `hkaSkeletonMapperUtils::createMapping`

Havok animation type names (asset/serialization layer):
- `hkaSkeletalAnimation`, `hkaDeltaCompressedSkeletalAnimation`, `hkaInterleavedSkeletalAnimation`, `hkaSplineSkeletalAnimation`, `hkaWaveletSkeletalAnimation`, `hkaSkeleton`, `hkaBone`, `hkaAnnotationTrack`, `hkaAnnotationTrackAnnotation`, `hkaAnimationBinding`, `hkaBoneAttachment`, `hkaMeshBinding`, `hkaAnimatedReferenceFrame`, `hkaKeyFrameHierarchyUtility`, `hkaKeyFrameHierarchyUtilityControlData`, `hkaRagdollInstance`

Havok Behavior (hkb) generators/modifiers (selected, from strings):
- Generators: `hkbBehaviorGraph`, `hkbClipGenerator`, `hkbBlenderGenerator`, `hkbBinaryBlenderGenerator`, `hkbAdditiveBinaryBlenderGenerator`, `hkbPoseMatchingGenerator`, `hkbReferencePoseGenerator`, `hkbStateMachine`, `hkbAnimatedSkeletonGenerator`
- IK / pose modifiers: `hkbFootIkModifier`, `hkbFootIkControlData`, `hkbFootIkGains`, `hkbHandIkModifier`, `hkbHandIkControlData`, `hkbLookAtModifier`, `hkbReachModifier`, `hkbTwistModifier`, `hkbJigglerModifier`, `hkbGetUpModifier`, `hkbKeyframeBonesModifier`, `hkbMirrorModifier`
- Ragdoll driving: `hkbPoweredRagdollModifier`, `hkbRagdollDriverModifier`, `hkbRagdollForceModifier`, `hkbRigidBodyRagdollModifier`, `hkbCheckRagdollSpeedModifier`, `hkbPoweredRagdollControlData`, `hkbMirroredSkeletonInfo`, `hkbCharacterBoneInfo`
- Ragdoll constraints (hkp): `hkpRagdollConstraintData`, `hkpRagdollLimitsData`, `hkpRagdollMotorConstraintAtom`

FaceFX strings: `FaceFXActor`, `FxActor`, `FxActorInstance`, `FxAnim`, `FxAnimSet`, `FxAnimGroup`, `FxFaceGraph`, `FxFaceGraphNode`, `FxFaceGraphNodeLink`, `FxFaceGraphNodeUserProperty`, `FxBone`, `PFxBonePoseNode`, `PFxDeltaNode`, `PFxCurrentTimeNode`, `PFxCombinerNode`, `N0FxAnimCurve`, `PgFaceFxActorAsset`, `PgFaceFxAnimationSetAsset`.

Profiler / debug labels (full strings region near offset string-index ~7325, "Animation Debug Mode" block) describing the runtime animation node graph:
- `Animation Debug Mode`, `update bone controllers`, `Sample BoneControllers`, `setToReferencePose`, `check CPU cap`, `copy SPU results`, `SamplerNode VerifyAnimPoses`, `SampleMt VerifyAnimPoses`, `calc root translation`, `events`, `track names`, `havok data`, `material animation`, `hkAnimation::samplePose`, `FacialExpression::UpdateAll`, `HeadLookAt::Update`, `GetRandomTimeScale`, `Foot Placement IK`, `Animation::HumanSamplePose`, `BuildModelSpaceTransforms`, `HACKRenormalizeQuats`, `Copying Poses`, `Blending`
- Animation node graph: `AnimationNode Update`, `HandleBasedAnimationSamplerNode Update`, `NodeLandMovement::Setup` / `NodeCivLandMovement::Setup`, `LandMovementNode ResultUpdate/AimUpdate/StateUpdate/StateCalculation/Update`, `AnimationSamplerNode Update/Sample`, `MannedWeaponNode Update/Sample/ctor`, `StrapOn SamplePose/Update/ctor`, `Tentacle SamplePose/Update/ctor`, `HandFixeupNode Update/Sample/ctor` (sic "Fixeup"), `BlendNode Update/Sample/ctor`, `SubtractNode Update`, `ResultNode Update`, `LeanNode Update`, `GlobalSRTFixupNode Update`, `FootPlacementNode Update`, `GrappleNode Update/Sample`, `Track SetBoneWeights`

Config tunables (block0 / config string region):
```
# If AnimCpuCapEnabled is non-zero:
# Honor the maximum milliseconds per frame settings for the Update phase of
# animation, and for the total animation processing.
AnimCpuCapEnabled      0   (PC profile: 1)
AnimCpuCapUpdatePhaseMilliseconds 1.0 / 2.0 / 2.5
AnimCpuCapTotalMilliseconds 4.0
```

Ragdoll LOD / memory-budget config strings: `PhysicsActorRagdoll 128 64`, `RagdollController 128 64`, `# For guys in ragdoll.`, `LodRagdoll` (×4), `BoneCtrl* <n> <m>` budget lines (e.g. `BoneCtrlLookAt 512`, `BoneCtrlPhysicsActor 1024`, `BoneCtrlStrapOn 768`, `HumanAnimationControllerNEW 128 64`, `RuntimeHeadLookAt 128 64`). The numbers appear to be instance-pool sizes.

Human skeleton bone-name constants (block0): `Bone_Head`, `Bone_LForearm`, `Bone_LBicep`, `Bone_RForearm`, `Bone_RBicep`, `Bone_Chest`, `Bone_Spine2`, `Bone_LShin`, `Bone_LThigh`, `Bone_RShin`, `Bone_RThigh`, `Bone_Hips`.

Other notable: `setToReferencePose`, `extractRagdollPose`, `referencePoseWeightThreshold`, `ragdollMotors`, `ragdollName`, `ragdollInstance`, `prevIsFootIkEnabled`, `HACKRenormalizeQuats` (a quaternion-renormalization hack marker), `AnimaitonName` (misspelled field name in the binary).

## PC decompilation cross-reference

These map this system's Xbox symbols to functions in the PC retail decomp (`output/_ghidra/all_functions_decomp.txt`), via `output/jul08_prototype/pairing/resolved_animation-skeleton.txt`. The resolver found **no vtable-resolved classes** for this system (the recovered RTTI vtables did not include the animation/skeleton classes), so every entry below is **string-anchored** (medium-to-low confidence: a function references the same string literal the Xbox symbol named). The functions cluster into two clearly distinct roles, confirmed by reading their bodies:

1. **Asset/type descriptor registrars** (`FUN_0063*`/`FUN_0064*`): each writes a fixed descriptor struct (a `CopyFromStream` vtable pointer, the `0x9e3779b9` golden-ratio hash seed, count/size fields) and stamps its type name — i.e. they register an asset class with the streaming loader.
2. **Havok packfile field-name version-conversion functions** (`FUN_0089*`/`FUN_008a*`): each calls a field-binder (`FUN_0089c0c0`, `FUN_00957240`) to copy a named field from one schema layout to another (old Havok packfile field name → current field name). These are where the `numberOfPoses`, `referencePose`, `*BoneInfo`, `catchFall*RagdollBone*` strings live.

| Symbol / class | PC function | Bridge | Role |
|---|---|---|---|
| `HumanAnimationSystem` | `FUN_0063fee0` | string | descriptor registrar (sets `CopyFromStream` vtable + name) |
| `HumanAnimationSet` | `FUN_0063ff90` | string | descriptor registrar |
| `VehicleAnimationSet` | `FUN_00640040` | string | descriptor registrar |
| `AnimationController` | `FUN_00647640` | string | descriptor registrar |
| `BoneControllerRuntime` | `FUN_006477c0` | string | descriptor registrar |
| `BoneCtrlPhysicsActor` | `FUN_0063e250` | string | descriptor registrar |
| `RuntimeAnimationParams` | `FUN_006457e0` | string | descriptor registrar |
| `ColorAnimation` | `FUN_006436b0` | string | descriptor registrar (UI tween) |
| `LightAnimation` | `FUN_00643560` | string | descriptor registrar (UI tween) |
| `ScaleAnimation` | `FUN_00643760` | string | descriptor registrar (UI tween) |
| `AnimThenDisappear` | `FUN_0065f500` | string | references string |
| `BuildingCollapseAnimType` | `FUN_0064ac50`, `FUN_00663630` | string | references string (enum/handler) |
| `CoverAnimEnum` | `FUN_0064ac50`, `FUN_0065c180` | string | references string (enum/handler) |
| `referencePose` | `FUN_0089d280` | string | skeleton reference-pose builder (field conversion) |
| `numberOfPoses` | `FUN_0089ce90`, `FUN_008a4550` | string | field-name conversion (pose count) |
| `numberOfBoneTracks` | `FUN_0089cd40` | string | field-name conversion (track count) |
| `animationBoneInfo` / `ragdollBoneInfo` | `FUN_008a5dd0` | string | field-name conversion (bone-info arrays) |
| `keyframedBones` | `FUN_008a5ac0` | string | field-name conversion |
| `catchFallDirectionRagdollBone` / `velocityRagdollBoneIndex` | `FUN_008a7280` | string | field-name conversion (catch-fall modifier) |
| `minBoneLengthFraction` / `maxBoneLengthFraction` | `FUN_008a7690` | string | field-name conversion (reach limits) |
| `LtMapPose` / `StunmappedBones` | `FUN_0087c560` | string | skeleton-mapper state/label registry |
| `StReferencePose` | `FUN_008853d0` | string | skeleton-mapper state/label registry |

### Annotated excerpts

**`FUN_0063fee0` — `HumanAnimationSystem` descriptor registrar** (string, medium). Reads a descriptor template and stamps the type name; the shared layout across all the `FUN_0063*`/`FUN_0064*` registrars is the strongest signal here:

```c
  _DAT_017bccc8 = &PTR_CopyFromStream_00bbea58;   // streaming-load vtable
  _DAT_017bccf4 = 0x9e3779b9;                      // golden-ratio hash seed (id table)
  _DAT_017bcce0 = &PTR_FUN_00bc5ff8;
  FUN_0064a770();                                  // common registrar tail
  _DAT_017bcd04 = s_HumanAnimationSystem_00bc4dfc; // <- names this asset class
```

`FUN_0063ff90` (`HumanAnimationSet`) and `FUN_00640040` (`VehicleAnimationSet`) are byte-for-byte the same shape into adjacent globals, differing only in the trailing name string and a couple of count fields — confirming this is a generated per-asset-class registration block, not a method of the class.

**`FUN_0089d280` — reference-pose builder** (string, medium-high; the body is distinctive, not just a string ref). It binds the old `hierarchy`/`bones` field names to the current `parentIndices`/`referencePose` names, then copies a per-bone **0x30-byte transform** (48 bytes = the Havok `hkQsTransform`: translation+rotation+scale) for each bone:

```c
  FUN_00957240(param_1,s_hierarchy_00b43158,param_2,s_parentIndices_00b124b8);
  FUN_0089c0c0(param_1,s_bones_00b124b0);
  FUN_0089c0c0(param_2,s_referencePose_00b124a0);
  ...
  iVar5 = FUN_0088cd90(iVar5 * 0x30,0x3b);   // alloc poseCount * 0x30
  ...
  do {  /* copy 0x30 bytes per bone from source bone+uVar1 into the pose array */
    iVar8 = iVar8 + 0x30;
  } while (iVar5 < piVar3[1]);
```

This confirms `referencePose` is an array of one 48-byte transform per skeleton bone, matching the Havok reference-pose representation described in the "Skeletons, poses & bone indices" section above.

**`FUN_008a7280` — catch-fall ragdoll field conversion** (string, medium). Maps `catchFallDirectionRagdollBone` → `...RagdollBoneIndex` and copies `velocityRagdollBoneIndex`, `handIndex`/`leftHand`, `ragdollShoulderIndex`, `ragdollAnkleIndex`, defaulting several indices to `0xffff` (the same "no bone" sentinel the registrars seed). This is the serialization back-end for the `hkbGetUpModifier`/catch-fall fields documented in the ragdoll-blending section.

> Confidence note: with no vtable bridge, none of these are proven 1:1 methods of the named class. The descriptor registrars are high-confidence as *registrars* (distinctive shared body) but only name the asset; the `FUN_0089*`/`FUN_008a*` field-conversion functions are confirmed to reference the cited strings but are schema-migration helpers, not the runtime sampling/blending code.

## How it works (decompiled)

VAs are from `output/_ghidra_x360/xenon_decomp_named.c` (base `0x82000000`); snippets are copied verbatim. The Xbox decomp does not name the per-frame sampling/blending math (that is VMX128, see the open questions), but it *does* expose two real, distinct mechanisms that the symbol-only doc could only infer: (1) how a `BoneCtrl*` is bound to a skeleton bone, and (2) how the per-action animation config is assembled from named reflection fields.

### `BoneCtrl*` functions are bone-controller factories that bind a controller to a bone index

`BoneCtrlLookAt` @`8251be68` is the constructor/binder for the look-at bone controller. It reads a node, takes the **16-bit bone index** from node`+4`, resolves the controller name, runs the shared bind helper `FUN_82353058`, and stamps the look-at controller vtable:

```c
  iVar3 = FUN_824cf2c0();                 // resolve target node
  uVar1 = *(undefined2 *)(iVar3 + 4);     // bone index (u16) on the node
  uVar2 = FUN_8290ba80(0xffffffff820322b0);  // "BoneCtrlLookAt" name handle
  FUN_82353058(param_1,uVar2,uVar1);      // bind controller→bone
  *param_1 = &PTR_FUN_8203fff8;           // look-at controller vtable
```
`BoneCtrlFakeWheel` @`8251e948` is byte-for-byte the same shape with a different node resolver (`FUN_824cf2e0`) and a different vtable (`PTR_FUN_82040884`). So the whole `BoneCtrl*` family (LookAt/RotationCopy/LocalRotation/StrapOn/Tentacle/Jostle/Wind/FakeWheel — all 108-byte siblings at `8251be68`..`8251e948`) are per-controller factories, each mapping a procedural controller to a specific bone index — confirming the doc's "family of procedural per-bone modifiers" reading, and giving each its own vtable.

### Per-action/object animation config is assembled from named reflection fields

`LookAtBone` @`8250c7a0` builds the look-at *config* by looking up several named fields and handing them to an action constructor:
```c
  local_30 = FUN_82504700(0xffffffff820321a8,0);   // field lookups by name-string addr
  local_2c = FUN_82504700(0xffffffff8203b4f4,0);   // (8203b4f4 = "ControlledBone")
  local_28 = FUN_82504700(0xffffffff8203b4e8,0);   // (8203b4e8 = "LookAtBone")
  local_24 = FUN_82504700(0xffffffff82025ef0,10);
  uVar2 = FUN_824cf2c0();
  FUN_824fbff0(uVar2,param_1,0,uVar1,&local_30);    // construct the action with the config
```
`RotorBlurOffBone` @`8250c5c8` is the same builder for the helicopter rotor-blur controller — it reads rotor-blur fields (`8203b45c`/`8203b43c`/`8203b40c`/`8203b3f8` = the `RotorBlur*Bone`/`FirstRotorBladeBoneName`/`RotorHubBoneName` strings this doc lists) plus two float params via `FUN_825047d0`, then calls the same `FUN_824fbff0`. `EquipRunHumanAction` @`8250d428` follows the identical pattern for a human equip/run action. This is the concrete machinery behind the "named control bones" string table: each name string is a reflection field key consumed by these builders.

### Animation asset classes share the ECS streaming registrar

`AnimationController` @`829f6468` and `HumanAnimationSet` @`829eed28` register through the **same** stream reader `PTR_FUN_82030fa0` used by the physics components (see physics-game.md), confirming animation assets and physics actors live in one ECS/reflection registry:
```c
  // AnimationController
  DAT_83807c2c = &PTR_FUN_820369e8;        // class vtable
  DAT_83807c44 = &PTR_FUN_82030fa0;        // shared CopyFromStream reader
  DAT_83807c68 = "AnimationController";     // class name
```
`HumanAnimationSet` differs only in vtable/name/size args — matching the PC-side "descriptor registrar" finding, now confirmed on Xbox.

### FaceFX objects are factory-constructed

`FxBone` @`828c3f38` is a FaceFX object factory: it allocates 0x18 bytes, lazily creates the `FxNamedObject` runtime class (`FxNamedObject()` → cached in `DAT_83949068`), then constructs via `FUN_828c2e90`. So the `Fx*`/`PFx*` names are live FaceFX runtime classes instantiated at load, not just strings.

## Corrections & open questions

- **CONFIRMED — `BoneCtrl*` are bone→controller binders (was inferred).** Each reads the node's u16 bone index and stamps a distinct controller vtable (`BoneCtrlLookAt`=`PTR_FUN_8203fff8`, `BoneCtrlFakeWheel`=`PTR_FUN_82040884`); VAs above. The doc's "applied after sampling" ordering is still inferred (the bind site doesn't prove call order), but the binding mechanism is code-backed.
- **CONFIRMED — the "named control bones" strings are reflection field keys.** `LookAtBone`/`RotorBlurOffBone`/`EquipRunHumanAction` look them up via `FUN_82504700` and feed an action constructor (VAs above), exactly the model the doc inferred.
- **CONFIRMED — animation assets use the same ECS streaming registrar as physics.** `AnimationController`/`HumanAnimationSet` share `PTR_FUN_82030fa0` with `PhysicsActorRagdoll` et al.
- **CONFIRMED — FaceFX `Fx*` names are instantiated runtime classes.** `FxBone` factory (VA above).
- **CORRECTION — the PC `referencePose` = "0x30-byte transform per bone" claim is supported, and the Xbox side is consistent but unverified.** The PC `FUN_0089d280` shows the `poseCount * 0x30` (48-byte `hkQsTransform`) copy; the Xbox image has no matching named function to re-confirm the stride, so cite the PC VA for that number. (Not a contradiction — just single-build evidence.)
- **UNKNOWN — the actual sample/blend/IK math (`HumanSamplePose`, `SampleMt`, `FootPlacementNode`, `extractRagdollPose`).** None of these appear as named, decoded functions in the Xbox set; the profiler labels (`Sample BoneControllers`, `Foot Placement IK`, `Blending`, `HACKRenormalizeQuats`) are zone strings only. The math is VMX128 and does not decode. The pipeline *ordering* in the Overview remains inferred from the "Animation Debug Mode" label sequence, not from traced control flow.
- **UNKNOWN — ragdoll blend weight / catch-fall thresholds.** The PC field-conversion functions name `referencePoseWeightThreshold`, `catchFall*`, etc., but no decompiled body in either build assigns readable default values to them beyond the `0xffff` "no bone" sentinel.

## Cross-references

- `docs/mercs2-pdb-analysis/havok-physics.md` — Havok runtime; ragdoll constraints (`hkpRagdollConstraintData`, `hkpRagdollLimitsData`, `hkpRagdollMotorConstraintAtom`) and powered-ragdoll modifiers are shared with this system.
- `docs/mercs2-pdb-analysis/physics-game.md` — keyframed physics actors (`UpdateKeyframedPhysicsActors`, `SetNodePhysicsModelKeyframed`, `BoneCtrlPhysicsActor`, `MatchCapsuleToPose`).
- `docs/mercs2-pdb-analysis/rendering-shaders.md` — the `PgSkin*VP` / `PgMesh*MorphVP` skinning/morph vertex shaders and `BoneMatrixArray` overlap with the rendering shader set.
- `docs/mercs2-pdb-analysis/vehicles.md` — vehicle bone controllers/named bones (`ControlledWheelBone`, `SuspBone`, `RotorHubBoneName`, `VisRudderBone`, `WinchBone`, `VehicleAnimationSet`).
- `docs/mercs2-pdb-analysis/pangea-engine-core.md` — `PgSysAnimation` and the Pangea asset/table layer (`PgAnimationTable`, `PgFaceFx*Asset`).
- Existing project docs that overlap: `docs/character_systems_plan.md`, `docs/mercs2-ecs/` (ECS component registry), `docs/format_reference.md`.

## Evidence & confidence

- Symbol count: 223 entries in `output/jul08_prototype/inventory/animation-skeleton.txt` (218 in `.rdata`, 5 in `.data`).
- This doc cites ~140 distinct named symbols from the inventory plus ~70 additional Havok `hka*`/`hkb*`/`hkp*` class names, FaceFX `Fx*` names, and profiler/config strings confirmed by grep in `mercs2_xenon_p.pe_full_strings.txt`, `mercs2_xenon_p.rtti_classes.txt`, and `mercs2_xenon_p.block0_strings.txt`.

Directly evidenced:
- Every cited symbol name, RTTI class, source path, and string literal exists copy-exact in the named evidence file (verified by grep), including the misspellings `AnimaitonName` and `HandFixeupNode` as they appear in the binary.
- 17 `hka*` RTTI classes (incl. `hkaFootPlacementIkSolver`, the four compression variants, `hkaSkeletonMapper`, `hkaRagdollInstance`) and 2 `hkp*` ragdoll-constraint classes are present.
- The four Havok animation source paths and `hkaSkeletonMapperUtils::createMapping` are present.
- `AnimCpuCap*` tunables and the per-bone-controller / ragdoll pool-size config lines are present.

The main interpretive leap is the end-to-end pipeline ordering (load → sample → bone controllers → ragdoll blend → IK → skinning), inferred from the symbol/label names and the "Animation Debug Mode" profiler label order rather than from decompiled control flow. Naming-convention reads (ST/Mt = single/multi-thread, MS/LS = model/local space, `*VP`/`.sho` = vertex-shader/compiled-shader, the numeric config lines = instance-pool sizes) follow the same patterns used elsewhere in the binary. No real `.pdb` exists; class membership and offsets come from string/RTTI tables in the recovered PE, so a few symbols without surrounding code context remain unclear from symbols alone (e.g. `TtsamplePose`, `LtMapPose`, `deletePoseLocal` — though `LtMapPose` is now anchored to `FUN_0087c560` in the PC decomp cross-reference above).
