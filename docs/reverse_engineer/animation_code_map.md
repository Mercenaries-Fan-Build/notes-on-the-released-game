# Animation & Skeleton — Xbox↔PC code map

**Scope:** scoreboard **row 20 (Animation)** — the character/object skeletal-animation runtime in
retail PC `Mercenaries2.exe`: the Havok Animation (**hka**) sampling/skeleton/ragdoll runtime, the
Havok Behavior (**hkb**) controller layer, the data-driven clip picker (ActionTable →
AnimationLookup → clip), bone controllers, IK / ragdoll / catch-fall blend, FaceFX facial
animation, and the GPU-skinning palette. Binds the Xbox-devkit symbol names
([`../mercs2-pdb-analysis/animation-skeleton.md`](../mercs2-pdb-analysis/animation-skeleton.md),
[`symbol-map.md`](../mercs2-pdb-analysis/symbol-map.md)) to concrete PC addresses. Companion JSON
[`../data/animation_code_map.json`](../data/animation_code_map.json). Sample-codec / BLENDINDICES /
HIER / clip-index are **already solved** and consolidated here (see the "Already solved" box, §7),
not re-derived.

**Binary:** unpacked SecuROM image, base `0x00400000`. Bodies read first-hand from
`output/_ghidra/mercs2_unpacked.exe_decomp.txt` (the 27k-fn Ghidra decomp). Xbox base `0x82000000`
(Jul-08 "Profile" devkit).

**Method / honesty model.** Same discipline as the sibling maps
([`vehicle_code_map.md`](vehicle_code_map.md),
[`asset_formats_code_map.md`](asset_formats_code_map.md) §7,
[`world_streaming_code_map.md`](world_streaming_code_map.md)). Every PC address is decomp-verified;
each row states whether the body was **READ** first-hand this pass or **(ref)** cited from prior
work, and whether the marriage is by **RTTI-vftable**, **string**, or **format**. Confidence: **H**
= vftable/format/offset proves it · **M** = role+structure, one strong signal · **L/open** =
positional or confirm-live.

**SecuROM is not a blocker** ([[securom-decompiled-not-a-blocker]]). The whole Havok-animation
library sits in the clean `.text` cluster `0x0087xxxx–0x00a0xxxx` and is **RTTI-named** on PC (§2);
the per-frame sampler is reached through a `.data` vtable (confirm-live), not a SecuROM island. No
split-thunk chase was needed for this row.

### The one structural finding that unblocks this row

The asset-formats map ([`asset_formats_code_map.md`](asset_formats_code_map.md) §7) stated the Xbox
Havok parser bodies are "unlocated by name" and only the field-binder *names* carry the marriage.
For the **runtime** side that is now upgraded: **the PC build retains full MSVC RTTI on the Havok
animation classes.** `hkaSkeletonMapper`, `hkaAnimatedSkeleton`, `hkaRagdollInstance`,
`hkaFootPlacementIkSolver`, `hkaWaveletSkeletalAnimation`, `hkaSplineSkeletalAnimation`,
`hkaDeltaCompressedSkeletalAnimation`, `hkaDefaultAnimatedReferenceFrame`,
`hkaAnimationControlListener`, `hkBaseObject` all appear as named `::vftable` symbols stamped by
their PC constructors — so the runtime hka layer is **directly recoverable by address on PC**, which
the Xbox string-only analysis could not do. (Contrast the *asset/schema* side, where the field
names are stripped and only the descriptor mechanism is shared — that half is unchanged.)

---

## 0. Result in one line

The **hka animation runtime is RTTI-named and pinned on PC** (constructors + type-info thunks in
`0x0087xxxx–0x009fxxxx`), the **hkbGetUp/catch-fall + reference-pose + track-count schema binders**
are the shared `FUN_0089*`/`FUN_008a*` field-conversion family, the **FaceFX face-graph evaluator**
is `FUN_00686ce0` (source path `d:\projects\mercs2_pc\mercs2\fxs…`), the **HumanAnimationSystem /
HumanAnimationSet reflection registrars** are `FUN_0065ade0` / `FUN_0065af90`, and the **clip
picker** (ActionTable `0x6802C321` → AnimationLookup `0xE00B080C` → `ASTO[index]` → clip) is fully
solved and validated end-to-end. **Still opaque:** the per-frame VMX/SSE pose-sample-and-blend math
(vtable-dispatched inside layer 4), the MT job dispatch under the `AnimCpuCap` budget, and the
FaceFX curve-solver numerics — all **confirm-live** (§8) / **open** (§9).

---

## 1. Pipeline (disk clip → posed skeleton → GPU skin palette)

```
animation asset (type 0x18166555)                        clip picker (SOLVED §7):
  = Havok 5.5 packfile (hkaAnimationContainer +            game state
    one hkaWavelet/Interleaved/Delta SkeletalAnimation)      └(ActionTable 0x6802C321)→ Handle
  + Pandemic 'trnm' chunk = track→bone by HIER name-hash     └(AnimationLookup 0xE00B080C
    (the real transformTrackToBoneIndices; animgroup.rs)         + CharacterName=hash(merc))→ idx
                                                               └ ASTO[idx] = clip name-hash
        │ load-time field migration                                    │
        │  FUN_0089d280 referencePose builder (48B hkQsTransform/bone)  │ resolve in animgroup
        │  FUN_0089cd40 numberOfBoneTracks · FUN_0089ce90 numberOfPoses │
        ▼                                                               ▼
  runtime objects (RTTI-named, §2)                              per-frame TICK (layer 4, §3)
    hkaAnimatedSkeleton  ctor FUN_00884190  (@+7 skeleton, +2 ctrl-listener vtbl)
    hkaDefaultAnimationControl (per active clip; holds local time)
        │  Animation::HumanSamplePose / SampleMt  ── vtable-dispatched, VMX/SSE ── OPAQUE (§9)
        ▼
  sampled bone locals (hkQsTransform T·R·S per track)
        │  bone controllers (post-sample, §4):  BoneCtrl* LookAt/RotationCopy/FakeWheel/…
        │  IK (§5):  hkaFootPlacementIkSolver  ctor FUN_009ef650  (setup FUN_00744c20)
        │  ragdoll blend (§5):  hkaRagdollInstance ctor FUN_0088c000 (setup FUN_0043d800)
        │      + hkbGetUp/catch-fall fields  binder FUN_008a7280
        │  FaceFX (§6):  face-graph eval FUN_00686ce0  → per-bone-pose node outputs
        ▼
  BuildModelSpaceTransforms → skinning palette (BoneMatrixArray) → PgSkin*VP / PgMesh*Morph*VP
```

The **track→bone binding is by HIER node name-hash**, not int16 skeleton index: shipped animgroups
carry **no** `hkaSkeleton` object (0/190 blocks) — the binding is the Pandemic `trnm` chunk
(`[u32 track_count][u32 lead][track_count × u32 bone_name_hash]`), verified `track_count ==
numTransformTracks` for every clip ([`../../tools/wad_simulator/crates/mercs2_formats/src/animgroup.rs`](../../tools/wad_simulator/crates/mercs2_formats/src/animgroup.rs);
[[blendindices-per-group-palette]], [[model-hier-bone-naming]]).

---

## 2. Master marriage table (Xbox hka/hkb ↔ PC)

Xbox column: `.rdata` symbol / VA from `animation-skeleton.md` (string/RTTI evidence). PC column:
decomp-verified address. "Married by": **vftable** = the PC ctor stamps the RTTI `::vftable`
(coincidence-proof); **string** = references the same literal; **format** = same on-disk layout;
**anchor** = the SOLVED clip-chain hashes.

| Xbox symbol / class | PC fn / VA | Married by | Conf | Read |
|---|---|---|---|---|
| `hkaAnimatedSkeleton` (runtime posed skeleton) | ctor **`FUN_00884190`** (`hkaAnimatedSkeleton::vftable` + `hkaAnimationControlListener::vftable` @+2; skeleton @+7); dtor `FUN_008841d0`; setup `FUN_0067b320` | vftable | H | READ |
| `hkaRagdollInstance` | ctors **`FUN_0088c000`** / `FUN_0088c0a0`; dtor `FUN_0088c180`; game setup `FUN_0043d800` | vftable | H | READ |
| `hkaSkeletonMapper` (anim↔ragdoll mapper) | dtor `FUN_0087c540`; **`hkaSkeletonMapperUtils::createMapping`** = `FUN_0087c560` (3907 B); type-info thunk `FUN_009ef4d0` | vftable + string (`.\Mapper\hkaSkeletonMapperUtils…`) | H | READ |
| `hkaFootPlacementIkSolver` (foot IK) | ctor **`FUN_009ef650`** (`…::vftable`; copies 0x20-dword control block); setup `FUN_00744c20`; control-data init `FUN_009ef750` | vftable | H | READ |
| `hkaWaveletSkeletalAnimation` | type-info thunk `FUN_009ef540`; scalar-dtor `FUN_009ef550`→`FUN_009f54b0` (obj 0x38) | vftable | H | READ |
| `hkaSplineSkeletalAnimation` | type-info thunk `FUN_009ef610`; scalar-dtor `FUN_009ef620` (obj 0x38) | vftable | H | READ |
| `hkaDeltaCompressedSkeletalAnimation` | (same cluster, `hkaDelta…::vftable`; ctor adjacent `0x009ef4xx`) | vftable | M | ref |
| `hkaDefaultAnimatedReferenceFrame` | type-info thunk `FUN_009ef460` | vftable | H | READ |
| `hkaAnimationControlListener` | 2nd base of `hkaAnimatedSkeleton` (`FUN_00884190` @+2) | vftable | H | READ |
| Havok anim-util `Animation Util/hkaTrackAnalysi…` (DOF stats) | `FUN_009fa860` (Static/Dynamic/Clear position/rotation/scale/float DOFs report) | string | M | READ |
| `referencePose` builder (`hierarchy`→`parentIndices`,`bones`,`referencePose`) | **`FUN_0089d280`** (copies `poseCount × 0x30` = 48B `hkQsTransform`/bone) | string | M-H | ref |
| `numberOfPoses` field conversion | `FUN_0089ce90`, `FUN_008a4550` | string | M | ref |
| `numberOfBoneTracks` field conversion | `FUN_0089cd40` | string | M | ref |
| `animationBoneInfo`/`ragdollBoneInfo` | `FUN_008a5dd0` | string | M | ref |
| `keyframedBones` | `FUN_008a5ac0` | string | M | ref |
| `catchFallDirectionRagdollBone` / `velocityRagdollBoneIndex` (hkbGetUp/catch-fall) | **`FUN_008a7280`** (also `handIndex`/`leftHand`/`ragdollShoulder/AnkleIndex`, defaults `0xffff`) | string | M-H | READ |
| `minBoneLengthFraction`/`maxBoneLengthFraction` (reach/IK limits) | `FUN_008a7690` | string | M | ref |
| field-copy primitives | `FUN_0089c0c0`, `FUN_00957240`, `FUN_0089c1a0`/`c260` (u16/label) | string | H | READ |
| `HumanAnimationSystem` (ECS component schema) | registrar **`FUN_0065ade0`** (3 int + 10 float fields) / desc-registrar `FUN_0063fee0` | string + table | M | READ |
| `HumanAnimationSet` | registrar **`FUN_0065af90`** (2 int) / desc-registrar `FUN_0063ff90` | string + table | M | READ |
| `VehicleAnimationSet` | desc-registrar `FUN_00640040` | string | M | ref |
| `AnimationController` / `BoneControllerRuntime` / `BoneCtrlPhysicsActor` | `FUN_00647640` / `FUN_006477c0` / `FUN_0063e250` | string | M | ref |
| `BoneCtrlLookAt/FakeWheel/…` (per-bone controller factories, Xbox `8251be68…`) | PC controller vtable family (post-sample modifiers; individual PC ctors positional) | string | L/open | — |
| FaceFX face-graph **evaluate/update** (`Fx*`/`PFx*`, `FxActorInstance`) | **`FUN_00686ce0`** (2871 B; walks fg-node list, `(*node+0x18)()` → value array); tick-in `FUN_00686c60` | string (`FxActorInstance.h`, `…mercs2\fxs…`) | M-H | READ |
| clip picker `ActionTable` | `0x6802C321` resident table | anchor (VERIFIED) | H | ref |
| clip picker `AnimationLookup` | `0xE00B080C` (CharacterName=hash(merc); `Animation` idx → `ASTO[idx]`=clip) | anchor (VERIFIED e2e) | H | ref |
| sample codec (Wavelet/Delta/Spline) | `mercs2_formats` decoder (168/168 tests) | solved | H | ref |
| GPU skin shaders `PgSkin*VP`/`PgMesh*Morph*VP`, `BoneMatrixArray`, `rotateBonesForSkinning` | shader-string set (compiled `.sho`); palette upload in render path | string | L/open | — |

---

## 3. The per-frame animation tick (placement + what's opaque)

**Placement.** From [`scheduler_tick_code_map.md`](scheduler_tick_code_map.md): the master tick is a
5-layer stack ticked 0→4 (`FUN_004c14f0 → FUN_004c15e0`); the **game/ECS mode is layer 4**, whose
per-system order (Camera / **Animation** / Vehicle / AI / Population…) is **vtable-dispatched behind
the layer's `Update(+0xc)`** → the exact animation-system slot is a documented **confirm-live** item
(scheduler §8.1). The `AnimCpuCapEnabled`/`…UpdatePhaseMilliseconds`/`…TotalMilliseconds` tunables
(PC profile = enabled) confirm the update+sample runs under a **per-frame millisecond budget** and
is split into `AnimCpuUpdateJob` / `AnimCpuSampleJob` CPU jobs dispatched through the **Pimp worker
pool** ([`pimp_job_system_code_map.md`](pimp_job_system_code_map.md); the `ST`/`Mt` =
single/multi-thread split). The job **dispatch** endpoint is not pinned on PC (jobs post through the
Pimp ring whose spawn site is SecuROM-relocated) → **open (§9)**.

**Runtime object graph (READ).** The per-character animated skeleton is built by
**`FUN_0067b320`** (called from the human/character runtime `FUN_005d0bd0`): it constructs an
`hkaAnimatedSkeleton` (`FUN_00884190`), which is also an `hkaAnimationControlListener` (second base
vtable at obj+8/`param_1[2]`), stores the skeleton pointer at obj+0x1c (`param_1[7]`), and holds the
list of active `hkaDefaultAnimationControl` clips (each carrying its own local clock). The
**sample-and-combine** step (`Animation::HumanSamplePose` / `Animation::SampleMt` →
`hkAnimation::samplePose` → `BuildModelSpaceTransforms` → `HACKRenormalizeQuats`) is invoked through
the animated-skeleton vtable; its body is the **VMX128 (Xbox) / SSE (PC) blend math** that does not
recover as named control flow — **opaque (§9)**, but its *inputs* (clip via §7, track→bone via
`trnm`, reference pose via `FUN_0089d280`) and *output representation* (48B `hkQsTransform` per bone)
are fully pinned.

**Feed to the GPU skin (row 20's render half).** Model-space bone transforms are composed to a
bone-matrix palette (`BoneMatrixArray` / `rotateBonesForSkinning`) and consumed by the skinned/morph
vertex shaders `PgSkinMorphVP` / `PgMeshMorph*VP` (+ `…ShadowVP` shadow-pass variants) — a
**4-influence linear-blend skin**. The palette-upload call site is in the render path (behind the
render-view vtable, [`render_core_code_map.md`](render_core_code_map.md)); the shader **names** are
`.rdata` strings but the upload fn is positional → **L/open**. This is exactly the half the modern
engine already implements (§10).

---

## 4. Bone controllers (post-sample procedural modifiers)

Xbox proved these are **per-bone controller factories** that read a node's u16 bone index and stamp
a distinct controller vtable (`BoneCtrlLookAt`=`PTR_FUN_8203fff8`, `BoneCtrlFakeWheel`=
`PTR_FUN_82040884`; all 108-B siblings `8251be68..8251e948`), and that the "named control bones"
strings (`ControlledBone`, `LookAtBone`, `RotorHubBoneName`, `SuspBone`, …) are **reflection field
keys** consumed by config builders (`LookAtBone`@`8250c7a0`, `RotorBlurOffBone`@`8250c5c8`, all →
action ctor `FUN_824fbff0`) — see `animation-skeleton.md` "How it works". The family: LookAt /
RotationCopy / LocalRotation / LocalTranslation / Tentacle / StrapOn / Jostle / Wind / FakeWheel /
PhysicsActor. On PC the **schema registrars** are pinned (`AnimationController` `FUN_00647640`,
`BoneControllerRuntime` `FUN_006477c0`, `BoneCtrlPhysicsActor` `FUN_0063e250`); the **individual PC
controller ctors/apply methods are vtable-gated and positional** → **open**. `BoneControllerLod`
implies LOD-gated controller evaluation; the pool sizes are config (`BoneCtrlLookAt 512`,
`BoneCtrlPhysicsActor 1024`, `BoneCtrlStrapOn 768`). Apply-order (after sampling, before skinning)
is inferred from the `Animation Debug Mode` label sequence, not traced.

---

## 5. IK, ragdoll, catch-fall (READ)

**Foot IK.** `hkaFootPlacementIkSolver` ctor **`FUN_009ef650`** copies a 0x20-dword control block
from the caller and seeds three identity-ish transform slots (gain/limit block at obj+0x30..+0x3b
from `DAT_00b132f0..fc`); the paired control-data init is `FUN_009ef750`. Setup site
**`FUN_00744c20`** (776 B) constructs the solver — this is the PC of the Xbox `Foot Placement IK` /
`FootPlacementNode` / `hkbFootIkModifier`. `minBoneLength*Fraction` reach limits migrate through
`FUN_008a7690`.

**Ragdoll.** `hkaRagdollInstance` ctors **`FUN_0088c000`** / `FUN_0088c0a0` (base `FUN_0088be90`)
build the bone-index remap array (`param_1[8]`/count `[9]`); dtor `FUN_0088c180` releases the
constraint refs. The **game-side ragdoll setup** is `FUN_0043d800` (2159 B, in the physics-actor
`0x43xxxx` cluster shared with the vehicle/human physics actors —
[`vehicle_code_map.md`](vehicle_code_map.md) §3, `BoneCtrlPhysicsActor` bridges pose↔body). The
anim↔ragdoll pose exchange uses `hkaSkeletonMapper` (`FUN_0087c560` = `createMapping`) with the
`animationToRagdollSkeletonMapper` / `ragdollToAnimationSkeletonMapper` bindings.

**Catch-fall / get-up.** **`FUN_008a7280`** (READ) is the `hkbGetUpModifier`/catch-fall schema
binder: it migrates `catchFallDoneEvent(Id)`, `catchFallDirectionRagdollBone(Index)`,
`velocityRagdollBoneIndex`, `raycastLayer`, `handIndex`/`leftHand`, `handIkTrackIndex`,
`animShoulderIndex`, `ragdollShoulderIndex`, `ragdollAnkleIndex`, defaulting unset bone indices to
`0xffff`. This names the fields; the **runtime blend-weight/threshold math**
(`referencePoseWeightThreshold`, powered-ragdoll motors) is **open (§9)** — no decompiled body
assigns readable defaults beyond the `0xffff` sentinel.

---

## 6. FaceFX (facial animation) (READ)

FaceFX is the third-party FaceFX SDK (`FxActor`/`FxActorInstance`/`FxFaceGraph`/`FxFaceGraphNode`/
`Fx*LinkFn` transfer functions), wrapped in Pangea assets `PgFaceFxActorAsset` (ASET type
**`0x1CF649BB` facefxactor**) + `PgFaceFxAnimationSetAsset` (**`0x665EF13E` facefxanimationset**,
`type_id 5`, 44–46 KB pre-baked dialogue curves). Bind/play verbs on Xbox: `BindFaceAnimSet`,
`UnbindFaceAnimSet`, `PlayFaceAnim`.

**PC evaluator = `FUN_00686ce0`** (2871 B, READ). It is the per-frame **face-graph solve**: it
validates the `FxActorInstance` (`actor != NULL` asserts against `…\FxSDK\Inc\FxActorInstance.h`),
walks the actor's face-graph node list, evaluates each node's output via the vtable call
`(*node + 0x18)()`, writes the results into the instance's value container, then applies the driven
values (bone-pose nodes → per-bone deltas). The tick-advance sibling is `FUN_00686c60`
(accumulates face time at obj+0x84, state-gated on obj+0x64==4). Source path
`d:\projects\mercs2_pc\mercs2\fxs…` confirms a first-party FaceFX integration module. The Lua/asset
binding path is `@ Binding FaceFx` / `@!! No global FaceFx for actor` (game log strings). **Open:**
the FaceFX curve **solver numerics** (the `Fx*LinkFn` transfer-function math inside each node's
`+0x18` evaluate) and the morph-target application are not decoded → **§9**.

---

## 7. Already solved — cite, do not re-derive

> **Sample codec (Wavelet/Delta/Spline).** The clip sample decode **numerically matches a live
> x32dbg capture, 168/168 tests** ([[wavelet-decode-solved-live-capture]]); decoder lives in
> `mercs2_formats` (`animgroup.rs`/`havok.rs`). The retail data is Havok-5.5 packfiles carrying
> `hkaWaveletSkeletalAnimation` (4103), `hkaInterleaved…` (73), `hkaDelta…` (56).
>
> **BLENDINDICES per-group palette.** Joints index the group `INFO(56)` range-table concat, **not**
> the global HIER (`FUN_00479d90`); this was the hand-claw / head-fan fix
> ([[blendindices-per-group-palette]]). Walk-root track carries baked locomotion.
>
> **HIER bone naming.** HIER node hash = `m2(bone name)`, scheme `bone_<part>_<axis>`
> ([[model-hier-bone-naming]]); `trnm` binds tracks to these hashes (§1).
>
> **The data-driven clip picker (the row-20 "controller" / state machine).** VERIFIED e2e
> ([[human-animation-selection-system]], [`../modernization/human_animation_selection.md`](../modernization/human_animation_selection.md)):
> `ActionTable 0x6802C321` (Stance/Action/AimState/Direction/… → Handle) → `AnimationLookup
> 0xE00B080C` (keyed by `CharacterName = pandemic_hash_m2(merc)` + equipment → `Animation` u32
> index) → `ASTO[index]` = clip name-hash → the character's animgroup clip. Chris idle resolves to
> `0xED37BC56`, matching the independent `LtSampleWave` capture. Transition/crossfade graph =
> `0xAB8FE34B`; `Min/MaxTimeScale` = playback-rate range; tool `action_table_probe`. **This is the
> engine's animation state machine** — the native driver assembles the per-character set through the
> `HumanAnimationSet`/`HumanAnimationSystem` components whose PC reflection registrars are `FUN_0065af90`
> / `FUN_0065ade0` (§2); `ASTO` *is* the shipped index→clip map (no runtime reconstruction).
>
> **Mattias locomotion clips** identified via Havok footstep annotations (block 3154 → 12 walk + 21
> run clip hashes; [[mattias-locomotion-clips-identified]]).

---

## 8. Confirm-live inventory (x32dbg, read-only while PAUSED — [[x32dbg-mcp-no-resume]])

1. **Animation slot in layer 4** — bp the layer-4 `Update(+0xc)` vtable walk (`FUN_004c15e0`) and
   step to enumerate the per-system tick order; identify the animation-system `Update` and read its
   position relative to Camera/Vehicle/AI (closes scheduler §8.1 for row 20).
2. **The sampler** — bp `hkaAnimatedSkeleton` vtable sample slot (recover it from an object built by
   `FUN_0067b320`): dump one clip's sampled `hkQsTransform` array pre/post `HACKRenormalizeQuats`;
   confirm the 48B stride and the `trnm` track→bone routing on a live merc pose.
3. **AnimCpuCap budget** — read `AnimCpuCapEnabled`/`…Milliseconds` globals and bp the
   `AnimCpuSampleJob`/`AnimCpuUpdateJob` dispatch to see the Pimp ring post (pins the MT job
   endpoint left open in §9).
4. **Ragdoll blend** — bp `FUN_0043d800` (ragdoll setup) and the `hkaSkeletonMapper::createMapping`
   `FUN_0087c560`; watch the anim↔ragdoll pose exchange and read `referencePoseWeightThreshold`
   live (its default is not in the decomp).
5. **FaceFX solve** — bp `FUN_00686ce0`; on a briefing/cutscene dump the face-graph node value array
   and one `Fx*LinkFn` evaluate (`node+0x18`) to recover the transfer-function form.
6. **Skin palette** — bp the render-path `BoneMatrixArray` upload; confirm 4-influence LBS and the
   `PgSkinMorph*VP` permutation chosen per material.

---

## 9. Open / unlocated (honest)

- **Per-frame sample/blend math** (`HumanSamplePose`/`SampleMt`/`hkAnimation::samplePose`/
  `BuildModelSpaceTransforms`/`HACKRenormalizeQuats`) — vtable-dispatched, VMX128 on Xbox / SSE on
  PC; recovers as float soup, not named control flow. Inputs/outputs pinned (§3); the blend/combine
  arithmetic itself is confirm-live (§8.2), not read.
- **MT job dispatch** — the `AnimCpu*Job` post into the Pimp worker ring; the spawn/enqueue endpoint
  is SecuROM-relocated (like the pimpInit spawn, `pimp_job_system_code_map.md`) → confirm-live.
- **FaceFX curve solver** — the `Fx*LinkFn` transfer-function numerics and morph-target apply inside
  `FUN_00686ce0`'s `node+0x18` vcalls; the driver (`FUN_00686ce0`) is READ, the leaf math is not.
- **IK/ragdoll runtime blend weights** — field *names* migrate through `FUN_008a7280`/`FUN_008a7690`;
  `referencePoseWeightThreshold`, powered-ragdoll motor gains have no readable default in the decomp
  (only the `0xffff` no-bone sentinel).
- **Individual PC BoneCtrl* apply methods** — vtable-gated, positional (the Xbox factory model is
  proven; PC per-controller bodies not individually addressed).
- **Skin-palette upload fn** — shader names are `.rdata` strings; the upload call site is behind the
  render-view vtable (positional).
- **hkaDeltaCompressedSkeletalAnimation ctor** — cited by cluster/vftable, not read this pass.

---

## 10. Reconciliation with `mercs2_engine` (row 20 = 🟡)

The engine implements the **bottom half** of this pipeline and none of the controller/behavior top
half:

- ✅ **Sample + skin.** `mercs2_formats` decodes the Wavelet/Delta/Spline clips (168/168 tests,
  §7); `mercs2_engine` (`pose.rs`/`mesh.rs`/`scene.rs`) composes bone locals and does **4-influence
  LBS GPU skinning** (`SkinPalette`/`bone_matrices`) — the exact `BoneMatrixArray` + `PgSkin*VP`
  role (§3, §9). BLENDINDICES per-group palette + HIER name-hash binding are correct.
- ✅ **Data-driven clip index.** `mercs2_formats::anim_select` resolves the per-character idle
  through `ActionTable → AnimationLookup(CharacterName) → ASTO[index]` (§7); `world.rs` feeds it as
  the player idle. Hardcoded `CLIP_IDLE/WALK/RUN` is gone from the player idle path.
- ❌ **Controllers / behavior state machine.** The engine approximates transitions with a fixed
  blend; it does not yet consume the transition graph `0xAB8FE34B`, the `Looping/Driven/Locomotion`
  flags, `Min/MaxTimeScale`, or the `BoneCtrl*` procedural modifiers (LookAt/StrapOn/FakeWheel/…).
- ❌ **IK.** No foot-placement IK (`hkaFootPlacementIkSolver` / `FUN_009ef650` unported).
- ❌ **Ragdoll / catch-fall.** No ragdoll instance, anim↔ragdoll mapper, or get-up blend.
- ❌ **FaceFX.** No facial animation (`FUN_00686ce0` unported; `facefx*` assets unparsed).

**Net for the reimpl:** the faithful next steps are (1) build `HumanAnimationSet`/
`HumanAnimationSystem` that drive the full ActionTable→AnimationLookup state key each tick (walk/run,
not just idle) + the transition graph for crossfades; (2) a `BoneCtrl*` post-sample modifier pass
(LookAt/StrapOn first); (3) foot IK; (4) ragdoll + catch-fall blend via the mapper; (5) FaceFX
curve→bone-pose evaluation. Sampling, skinning, and the clip index are done — this map pins the
native driver, the RTTI-named Havok runtime, and the honest gaps so none of it is re-surveyed.

## 11. Provenance

- PC decomp: `output/_ghidra/mercs2_unpacked.exe_decomp.txt` (SecuROM-unpacked, base 0x400000).
  Verified inline this pass: `FUN_00884190` (`hkaAnimatedSkeleton::vftable` @L682436), `FUN_0088c000`
  (`hkaRagdollInstance::vftable` @L686238), `FUN_0087c540`/`FUN_0087c560` (`hkaSkeletonMapper`
  @L679258), `FUN_009ef650` (`hkaFootPlacementIkSolver::vftable` @L921833), `FUN_009ef540`/`610`/`460`
  (wavelet/spline/refframe type-info), `FUN_008a7280` (catch-fall binder @L705595), `FUN_00686ce0`
  (FaceFX eval, `FxActorInstance.h` @L337976), `FUN_0065ade0`/`FUN_0065af90` (Human anim
  registrars @L313267/313301), `FUN_009fa860` (hkaTrackAnalysis DOF report).
- Xbox ground truth: [`../mercs2-pdb-analysis/animation-skeleton.md`](../mercs2-pdb-analysis/animation-skeleton.md)
  (223 symbols; hka/hkb/FaceFX class + string tables), [`symbol-map.md`](../mercs2-pdb-analysis/symbol-map.md).
- Solved corpora: [[wavelet-decode-solved-live-capture]], [[human-animation-selection-system]],
  [[blendindices-per-group-palette]], [[model-hier-bone-naming]], [[mattias-locomotion-clips-identified]];
  [`../modernization/human_animation_selection.md`](../modernization/human_animation_selection.md);
  `mercs2_formats::{animgroup,anim_select,havok}`.
- Cross-refs: [`scheduler_tick_code_map.md`](scheduler_tick_code_map.md) (layer-4 tick),
  [`pimp_job_system_code_map.md`](pimp_job_system_code_map.md) (MT jobs),
  [`asset_formats_code_map.md`](asset_formats_code_map.md) §7 (Havok packfile / field binders),
  [`vehicle_code_map.md`](vehicle_code_map.md) (`0x43xxxx` physics-actor cluster / BoneCtrlPhysicsActor),
  [`render_core_code_map.md`](render_core_code_map.md) (skin-palette upload).
- Confidence stated per row; the VMX/SSE sampler, MT dispatch, FaceFX solver, and skin-upload fn are
  the documented confirm-live / open gaps (§8/§9).
