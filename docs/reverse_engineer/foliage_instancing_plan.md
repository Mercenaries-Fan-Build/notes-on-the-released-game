---
name: foliage_instancing_plan
description: Implementation-grade plan to convert Mercs2's per-object vegetation draws into GPU-instanced batches (retail exe + reimpl), with the full decomp address map. Grounded in a 4-agent decomp sweep 2026-08-01.
status: current
evidence: proven+inferred (per-item tagged; GPU-state values are confirm-live)
date: 2026-08-01
---

# Foliage / tree GPU-instancing — plan + decomp map

**Primary goal — eliminate tree pop-in; give the world real depth.** The player must never watch a
tree spawn from nothing. Every tree stays represented *in place* to the horizon (as a cheap
instanced imposter), and gains detail smoothly (mesh↔imposter crossfade) on approach — never a snap.
**Density like Just Cause 2 is the secondary payoff**, and GPU instancing is the shared *enabler*
for both: you cannot hold a horizon full of resident trees until the per-draw cost collapses.

Mechanism: replace Pangea's per-object tree draws with GPU-instanced batches. Two delivery targets:
(A) the retail D3D9 exe via hook/patch, (B) the Rust/wgpu reimpl (the north star). This doc is the
shared design + the recovered address map.

### 0.0 Why trees pop today, and the fix (the headline)

**Cause (PROVEN — refined by the Phase-1 tree dig 2026-08-01).** Two DIFFERENT vegetation layers with
DIFFERENT pop mechanisms — do not conflate them:
- **Understory** (plants/hedges/bushes, individually placed) pops via per-object **hibernation** —
  `HibernationControl.dist0`, retail median **231 m**.
- **Canopy trees** (the pop the user reports) are **per-cell bundled models inside the c3 quad-tree
  streaming cells** — no per-instance records exist. They pop with their **cell's quad-tree LOD tier**:
  the veg-bearing c3 cells stream at a **shorter LOD ring** than the terrain cells, driven by the
  memory-budget pump (`FUN_008739e0`/`FUN_00873cf0`) + the 1024-slot foliage-cell LRU (`FUN_006b9300`),
  NOT by `dist0`.

Either way the bug is a **residency mismatch**: camera **view distance is already >800 m** (stock +
the crowd_fog_couple hook), so the player sees terrain far past where trees/understory are resident →
they materialize inside view. **View distance is NOT the lever** (already far enough); the lever is
vegetation **residency**. The engine *has* an anti-pop primitive — `RenderFadingTrees` (`FUN_00468bb0`)
maintains a per-instance fade accumulator (`renderNode+0x1D0`) for a mesh↔imposter crossfade — but a
crossfade can only fade what is resident; beyond the veg-cell LOD ring the cell is streamed out and
there is nothing to fade from.

**★ Key enabler the dig surfaced:** the **imposter LOD tiers already exist per cell** (the
`_P000`→`_P001`→`_P002`→`_P003` mesh↔imposter quad-tree chain). So a resident imposter horizon is
mostly a matter of keeping the **coarse veg-cell tiers resident to the ~800 m terrain horizon** — data
that already ships — rather than authoring a new imposter layer. That makes a **cheaper first win**
possible (extend veg-cell streaming distance / budget) BEFORE the full instancing rewrite; instancing
is still needed to make a dense near tier affordable.

**Fix — a residency + LOD ladder:**
1. Keep the **coarse per-cell imposter tiers (`_P002`/`_P003`) resident to the horizon** — extend the
   veg-cell streaming distance + memory budget so a tree's cell is never fully streamed out in view.
2. **Near cells promote to the full mesh tier (`_P000`)** via the existing mesh↔imposter crossfade.
3. **Instance the near tier** so the dense full-mesh cells are affordable (the draw-call win, §5/§6).

Instancing (§2, §5, §6) is the enabler for step 1; the crossfade (§0 item 2, Phase 4) is the anti-pop
mechanism; residency (Phase 5) keeps it all on screen.

Provenance: a 4-thread decomp fan-out on 2026-08-01 over the unpacked SecuROM image
(`output/_ghidra/securom_dump/mercs2_unpacked.exe`, base 0x400000), the PC decomp
(`output/_ghidra/mercs2_unpacked.exe_decomp.txt`), the Xenon build
(`output/_ghidra_x360/xenon_decomp_named.c`, base 0x82000000) and console `shaders.bin`
reflection. **Nothing is behind SecuROM** — all thunk bodies are readable in the unpacked image.
Every address below is first-hand from a decomp body unless tagged INFERRED or confirm-live.

---

## 0. Corrected problem statement (what actually limits density)

The 4-agent sweep overturned the naive framing. Three findings reshape the target:

1. **The far field is already batched.** The engine ships two batched foliage submission forms
   on *both* platforms: `PgMeshTiny*` constant-indexed instancing (`ObjectIDScaleArray[id]` +
   `objectData.LocalToWorld[id]`) and `PgBillboardTree*` billboard clouds. Distant sparseness is
   therefore **authored placement density**, not a per-draw wall — pure data (add placements).
2. **The cost is the near modeled trees.** `FUN_00468bb0` (`RenderFadingTrees`) dispatches a
   per-object virtual `Render` for each near tree → one-or-more `DrawIndexedPrimitive` each. This
   caps how dense the *close-up* field can be. This is what instancing fixes.
3. **The billboard path already "instances" by brute force.** It re-draws a shared unit-quad grid
   once per instance, re-uploading 11 VS constants (c0–c10) each time (§5). Converting that loop to
   a hardware-instanced draw is the core move, and the `SetStreamSourceFreq` opcode to do it is
   **already wired** in the render interpreter (§2).

There is **no** dedicated grass system — JC2-style ground cover is *new content* (author grass-card
models, place them) riding the same instanced path, not an engine feature to intercept.

The "lost Xenon vfetch/MEMEXPORT path" hypothesis is **disproven**: the only vfetch/MemExport
strings on 360 are the on-target SSM shader *compiler*; the vegetation shader family is byte-identical
`vs_3_0` on both builds. So instancing here is a genuine *improvement* over what shipped, not a
restoration.

---

## 1. Render architecture as found (PROVEN)

The renderer is a **deferred command-packet queue feeding a display-list bytecode VM with a single
draw choke point.** This is the spine everything else hangs off:

```
FUN_00631670 WinMain → FUN_00630ef0 RunFrame → FUN_0085a9e0 (per-viewport loop)
  → FUN_00466d40  per-viewport scene-pass driver (2679 B)
       ├─ FUN_004a6590  collect/classify (distance tier + frustum) → scene+0x1430 visible list
       ├─ FUN_00468bb0  RenderFadingTrees  (per-object fade gate + vtbl+0x14 draw dispatch)
       ├─ FUN_00468e40  Render / RenderZPass   → FUN_004a3e40 tree draw loop
       └─ FUN_00468ca0  RenderShadow           → FUN_004a3db0 tree shadow loop
  draw fns fill DAT_011647xx "current state" globals, then:
  → FUN_008546a0  pack 0x58-byte command packet into ring DAT_00ff4700 (2 buckets × 0x2000)
       ├─ FUN_008548f0 sort-key by material class    (packet byte +0x44 = DAT_0116474c)
       └─ FUN_008549a0 bucket-sort
  → FUN_00854b38  queue CONSUMER (executes packets) — applies SetRenderState/SetTexture per
                   material-class bucket  ← the GPU-state seam (confirm-live)
  → FUN_00751790 → FUN_007518b0  RenderList_Replay (bytecode interpreter, switch on opcode):
       case 2    → FUN_007512f0 → device vtbl+0x148 = DrawIndexedPrimitive   ← THE ONLY DIP IMAGE-WIDE
       case 3    → FUN_00751330 → device vtbl+0x144 = DrawPrimitive
       case 0x13 → FUN_007513f0 → device vtbl+0x198 = SetStreamSourceFreq    ← HW-instancing, already wired
       (+ SetStreamSource / SetVertexShader / SetVertexDeclaration / SetIndices / SetTexture / …)
```

- **Device pointer:** `*(int**)(DAT_01176288 + 0x5bc)` (IDirect3DDevice9, COM vtable; offset =
  index×4). Also cached at PgLtiRenderer `PTR_PTR_00dfc2fc + 0x2d28`. Every wrapper guards
  `if (DAT_01176288==0)`.
- **`FUN_007512f0` is the ONLY `DrawIndexedPrimitive` call site image-wide** (device+0x148 has
  exactly one occurrence; one caller). Every indexed draw — trees included — funnels through it.
  Plain `.text`, not SecuROM. This is the hook/verify anchor.
- **The `vtbl+0x14` "apply shader-state" hook is a no-op stub on PC** (`FUN_00848e20` = bare
  `return;`) — state is fully deferred to the packet executor.

---

## 2. The instancing capability is already present (PROVEN)

D3D9 hardware instancing (`SetStreamSourceFreq`, device+0x198 = vtbl index 102) is reachable through
**existing** wrappers — no new import, no renderer surgery:

- `FUN_00752a50` — per-stream bind: `SetStreamSourceFreq(stream, divider)` → `SetStreamSource` →
  `SetVertexDeclaration` (device+0x15c). Callers `FUN_00856500`, `FUN_00856760`.
- `FUN_007513f0` — display-list **opcode 0x13** that issues `SetStreamSourceFreq`.

INFERRED: the divider is currently a uniform `1` (models carry no instance data), so the capability
is dormant. **Confirm-live:** break `FUN_00752a50` / opcode 0x13 and read the live divider.

Vertex-declaration path to add a per-instance stream element: build `FUN_0074d6d0` → create
`FUN_00856360` → store handle → bind via device+0x15c (`FUN_00752b30` is the resource bind/build,
12 callers; `CreateVertexDeclaration` = device+0x158).

---

## 3. The tree shader table (PROVEN)

`PgBillboardTree*` shaders are **not** in the normal shader registry (`FUN_0084f130`) — they live in
a data-driven table in `.data` at **VA 0x0143b460–0x0143bd28** (strings file-off 0x103b46b). Four
records; each `{+0x00 class-vtable 0x00bac858, +0x04 name-hash, +0x08 program handle, +0x0b inline
.sho name}`:

| Record | .sho | name-hash | draw fn | pass | material-class `DAT_0116474c` |
|---|---|---|---|---|---|
| 0x0143b460 | `PgBillboardTreeVP/FP` | 0xbeb91b79 | FUN_004a2070 | color, main | (default/opaque) |
| 0x0143b6a0 | `PgBillboardTreeVP_fade/FP_fade` | 0x7f4a5a6a | FUN_004a22a0 | color, LOD-fade | 8 (alpha-blend) |
| 0x0143b9d0 | `PgBillboardTreeShadowVP` | 0x5ff6de01 | FUN_004a1af0 | shadow | 0 |
| 0x0143bc10 | `PgBillboardTreeZPassVP` | 0x71984612 | FUN_004a1d10/1ed0 | z-prepass | 3 |

Also present in the exe (the *other* batched path, from the Xenon cross-check): `PgMeshTiny`,
`PgMeshTinyVP`, `PgMeshTinyShadowVP`, `ObjectIDScaleArray`, `objectData.LocalToWorld` — a
constant-indexed instanced mesh batch (per-vertex object id → `ObjectIDScaleArray[id]` scale/fade +
`LocalToWorld[id]` transform). This is the engine's own instancing template.

---

## 4. Instance sourcing — DECIDED: drive from our placement DB (Option B)

### 4.0 ⚠ Phase-1 CORRECTION (2026-08-01, measured): the trees are NOT in the placement DB

The `veg-census` (`mercs2_probe veg-census`, classifier `mercs2_formats::veg`) over `layers_static`
found **9,637 vegetation placements (15.5% of 62,143 named), but they are the UNDERSTORY** — plant
6532, hedge 1441, bush 872, grass 743, fern 27, and only **22 individual trees, ZERO palms/canopy in
bulk**. The actual tree canopy is a **separate system**: `TreeFoliage 32` + `RuntimeFoliageModel 8`
ECS pools (cdbsizes.ini) — pools far too small to be per-instance, and **not parsed by any tooling,
not in the ECS registry docs.** INFERRED: trees are **scatter-generated / per-cell**, not individually
authored Transform records (which is how a 2008 game placed a forest without 62k tree records, and why
they hibernate/pop as zones stream). Prior memory flagged this: "Trees = a separate foliage system."

**Consequence — instance sourcing splits by layer:**
- **Understory (plants/hedges/bushes)** → the placement DB works NOW. 8,788/9,637 (91%) resolve to a
  model via name-hash across 49 resolvable species. Tag-set: `output/foliage/veg_tagset.json`
  (per-species hash/class/count/resolves). These are Phase-2-ready.
- Note: grass came back as 662 "species" for 743 placements, mostly non-resolving — likely `tt_*`
  terrain-texture / decal names swept in; filter grass to `resolves:true` before use.

### 4.0.1 Tree source RESOLVED (Phase-1 dig 2026-08-01): per-cell c3 models

`TreeFoliage 0x2A8A1456` / `RuntimeFoliageModel 0x0BECB01B` are **runtime render working-set** ECS
components (class-B, 32-byte, pools = active foliage zones / loaded model templates) — **NOT a storage
format.** Their hashes appear in **ZERO WAD blocks** (`find-ref` over all 11,370). PROVEN: the trees
are **veg MODELS (chunk `0x5B724250`) bundled inside the c3 quad-tree streaming cells** (`blocks\VZ\
c3XXXX_*`, the 4-level `_P000`..`_P003` LOD pyramid). `world_translation = [0,0,0]`; **position is
implicit from the cell grid ID.** `find-placement` recovers ~1900 understory but **≈0 tree/palm/canopy**
placements → confirms trees are cell-placed, not per-instance authored. Tree models carry `SKIN` (wind
sway), a destruction state machine (`CHDR/CEXE/SWIT/STAT/NODE` — **trees are destructible**), `PHY2`
Havok collision, and multiple `MESH/PRMG` LODs.

Runtime: foliage-cell pool `FUN_00401860(&DAT_014e16c0, 0x14, 0x400)` (1024 cells, 20 B:
`{species_idx, stream_handle, 3×key}`, LRU); pump `FUN_006b9300`; the species render batch
`DAT_01175a30` (stride 0x710) holds a **runtime instance table at `+0x708` (stride 28 B: xyz +
entity-id)**, populated as cells enter view (`FUN_004a2ce0` add / `FUN_004a32f0` remove) — i.e. the
engine is ALREADY collecting per-cell instances into species batches; our job is to instance the draw.

**Rust parse target — `mercs2_formats::tree_foliage` (buildable from disk today):**
1. Cell world pos from grid ID: `cell = XXXX−1; cx = cell%100; cz = cell/100; world_xz =
   (-3900 + cx*77.5, -3900 + cz*77.5)` (reuse `mercs2_c3_grid` / `world_terrain_loader`; Y from cell
   terrainmesh).
2. Enumerate the cell's bundled models (chunk `0x5B724250`) via the existing block entry-table + model
   reader; keep those whose name-hash is a vegetation species (join `veg_tagset.json` + discovered
   names, incl. `_imposter`/canopy/palm/tree hashes).
3. Emit one instance per veg model per cell at the cell world position (rot identity/cell-aligned,
   scale from model). This reproduces the engine's own placement unit.
4. (finer, INFERRED) if a per-cell model is a multi-tree **cluster** (e.g. 1.27 MB `largecanopy01`,
   15 `SEGM`), de-batch its `PRMG`/`SEGM` destruction-segment centroids (via model `HIER`) → per-sub-tree
   `{pos, rot}`. A small `treesmall01` is a single tree.

Residuals (verification, not blockers): single-tree vs cluster per cell; `stream_handle→cell block`
resolution (break `FUN_006b97e0`); live `DAT_00e90734` species count to validate step 3.

### 4.1 Runtime list (holds for both layers once trees are located)

At runtime trees are **not** a clean array — they are self-selected out of a mixed per-frame,
per-viewport renderable list by a `0xffff` shader-slot sentinel, and only each tree's **translation**
(`renderNode+0x84`) is statically locatable; the full rotation/scale matrix lives inside the draw
vcall and is unpinned.

We own better data than the engine exposes:
- **62,624 `layers_static` + 37,867 `vz_state` placement records**, each a 42-byte Transform =
  position + **unit quaternion** + a stable u32 entity key, fully parsed by
  `mercs2_formats::placement`. Mesh resolves by `pandemic_hash_m2(base_name)`.
- Per-instance residency: `HibernationControl` 10-byte record `{key, dist0, dist1, dist2, dist3,
  flag}`; `dist0` = hibernation distance (retail median 231 m), `dist1..3` = LOD-tier distances.

**Decision: build the per-instance transform buffer offline from our placement DB**, mirror the
engine's own cull math (documented below), and use the engine's transient list only as a *live
oracle* to validate. Rationale: Option B depends on nothing that is still OPEN, whereas hooking the
runtime list hits the unlocated per-instance matrix. Half of it already exists in
`mercs2_core::streaming` (per-entity hibernate/wake by `dist0`).

Cull math to mirror (all PROVEN):
- `FUN_00858150` distance/LOD classify: `D3DXVec3TransformCoord(pos)` by view → `sqrt(x²+y²+z²)` →
  tier `0 cull / 1 partial / 2 full`.
- `FUN_00857a90` AABB wrapper → `FUN_00857c00` 8-corner-vs-frustum-planes test.
- Camera: `PTR_PTR_00dfc2f8 + vp*0xE80` (view @+0xab0, proj @+0xaf0, view-proj @+0xb70, world pos
  @+0xb20).

---

## 5. Render-state replay spec (Phase 2)

The tree-batch object: stride **0x710**, array base `DAT_01175a30`, count `DAT_00e90734`. One batch =
one species with N instances. Key fields: `+0x6b0` instance count, `+0x6f8` color/tint vec4, `+0x700`
VB/prim handle, `+0x704` prim count, `+0x708` world-pos ptr, `+0x6e4/+0x6e8` imposter-atlas tile dims.

**Vertex layout (PROVEN):** tree geometry is a shared unit-quad grid in dynamic ring buffers
(`DAT_00e90710/714` stride 20 color, `DAT_00e90718` stride 16 shadow/z). Decls (via `FUN_00752b30`):
- stride 16: `{POSITION FLOAT4 @0}` — shadow & z.
- stride 20: `{POSITION FLOAT4 @0}, {TEXCOORD0 FLOAT1 @16}` — color.
- **No per-vertex normal/color/wind.** All per-instance data is in VS constants c0–c10.

**The 11 VS constants (c0–c10), built per-instance by `FUN_004a24a0`** — this is what moves to a
per-instance stream:
- c0/c1 = camera-relative billboard origin (`batch+0x30/+0x38/+0x140/…`, minus camera-Z bias
  `_DAT_01175c44`).
- c2 = imposter-atlas params: tile dims (`inst+0x6e4/6e8`) + reciprocals for UV scaling.
- c3–c10 = per-instance billboard basis/corner vectors (`inst+0x654/658/65c` orientation,
  `+0x684/688/68c` corner extents), indexed `param_4*0x10`.
- Per-frame view/view-proj matrix snapshot via `FUN_00835e80` (0x40-byte copy of
  `PTR_PTR_00dfc2f8+idx*0xe80+0x10`).

**Replay checklist (draw one batch, N instances):**
- PER-FRAME: view/view-proj matrix + camera pos/Z.
- PER-BATCH: select pass→record (§3); bind VS=handle2 / PS=handle1; bind diffuse+imposter-atlas
  textures & samplers *(slots/filters confirm-live)*; set material-class render bucket
  (`DAT_0116474c`: opaque alpha-tested cutout for main/z/shadow, class-8 alpha-blend for LOD-fade);
  PS constant c0 = `batch+0x6f8` tint (color passes); bind VB+decl (stride 16 or 20).
- PER-INSTANCE (loop N): build c0–c10; `SetVertexShaderConstantF(0, …, 11)`; `DrawIndexedPrimitive`.

**Instancing rewrite:** move c0–c10 out of VS constants into a **stream-1 per-instance layout**
(origin xyzw + atlas params + 8 basis/corner vectors), rewrite `PgBillboardTreeVP` to read them
per-instance, set `SetStreamSourceFreq(0, INDEXEDDATA|N)` / `(1, INSTANCEDATA|1)`, issue one DIP.
Preserve the stride-16/20 base decl, the alpha-tested-cutout material class, and the class-8 fade
bucket — or trees render invisible / mislit.

---

## 6. Two implementation routes

| Route | Basis | Batch ceiling | Verdict |
|---|---|---|---|
| **Reuse** the shipped `PgMeshTiny` constant-indexed path (`ObjectIDScaleArray`+`LocalToWorld[]`) | mirror the engine's own design | ~50–60 obj/draw (SM3.0 256 VS const regs) | good first proof; low risk; ceiling too low for JC2 density |
| **Modernize**: stream-1 per-instance data + `SetStreamSourceFreq` (opcode 0x13 already present) | true HW instancing | thousands/draw | the real target |

Recommended: prove the pipeline with the reuse route (it validates state-replay against the engine's
own working shaders), then lift the ceiling with the modernize route.

---

## 6.5 Performance model — why trees are not crowds (and the residual risks)

**Motivating concern (user):** bumping crowd density made the game unusable until the render path was
modified. Does tree instancing hit the same wall? **No — the crowd wall is CPU simulation, which
trees don't have.**

- **Crowd cost = per-entity SIMULATION** (render-thread CPU): AI state machines + `Perception` +
  `StateMachine` + `Health` (shared `Ai 1024` pool), `_HumanPhysics`/Havok, **`Road_SnapNearest`
  `FUN_004fe660` O(N)**, road-graph rebuild `FUN_004fd9f0`, `sqrt` physics sweep `FUN_0040cbb0`. GPU
  offload cannot touch any of it — that is why crowds stayed slow. (See
  [[entity-density-config-plus-laa-patch]].)
- **Tree cost = pure DRAW SUBMISSION.** No AI/physics/perception/road/state. Today each near tree =
  1+ `DrawIndexedPrimitive` + `SetVertexShaderConstantF` (11 constants via `FUN_004a24a0`). ~10k trees
  ≈ 10k DIPs + ~110k constant uploads on the single D3D9 render thread — the textbook **draw-call-bound**
  workload. Instanced → a handful of DIPs with transforms in a GPU stream. Instancing attacks exactly
  the tree bottleneck; it could not attack the crowd (sim) bottleneck.

**Residual tree costs + mitigations (be honest):**
1. **Residency bookkeeping (the pop-in phase's real risk).** Promoting 30k trees to full resident
   `SceneObject`/hibernation entities re-introduces a mild echo of the crowd per-entity cost.
   **Mitigation (central to the design): the resident far layer is a LIGHT imposter — a row in an
   instance buffer, NOT a full ECS entity with a hibernation record.** Only near trees get the full
   entity. This is why the goal is "resident imposter horizon," not "make every tree resident."
2. **Fill-rate / overdraw** from many alpha-test billboards → alpha-TEST cutout (cheap) not alpha-blend;
   atlas the imposters; keep the blend crossfade band narrow.
3. **Instance-buffer build** = flat O(N) distance/frustum arithmetic (`FUN_00858150` math), parallel,
   far below per-tree DIP+driver overhead.

**Consequence for the plan:** Phase 0 must **measure** the current tree DIP count + render-thread time
(baseline to beat), and the design commits to light imposters for the resident far layer.

## 7. Vegetation tagging (Phase 1) — taxonomy settled

Classify on the **descriptor token, never the region prefix** (`jungle_env_*` sweeps in
`jungle_env_rock02`). Positive tokens: `tree* palmtree* plant* bush* shrub vine* canopy* leaves
hedge* fern foliage grass* lawngrass flower branch* trunk`. Exclude `*fakeshadow*` (shadow decals),
`*decal*`, `*_rock*`, `commercial_grassymedian_*` (road median). `_imposter`/`_imposter_dm` variants
ARE in-set (carry the mesh↔billboard crossfade). Route: runtime hash-set of
`pandemic_hash_m2(base_name)` over positive names (self-contained, reversible) — default over the
per-placement flag route.

---

## 8. Phased plan (each gated on a proof)

0. **Confirm-live the spine.** Break `FUN_007512f0` with foliage on screen; confirm tree draws funnel
   through it. Read live `SetStreamSourceFreq` divider. Map the `FUN_00854b38` executor's
   class→`SetRenderState`/`SetTexture` (no corpus map exists — promote to a doc). **Also MEASURE the
   baseline:** count tree DIPs/frame + render-thread time at a dense viewpoint (the number to beat —
   see §6.5). *Gate: callstack shows trees at the one DIP + a render-state table + a baseline DIP/ms
   number.*
1. **Vegetation hash-set** from the name registry; coverage report vs 62k placements. *Gate: no
   rocks/buildings in-set.*
2. **Minimal instanced draw** — one species, N instances, one DIP, correct via the §5 replay spec.
   *Gate: PIX capture shows one instanced DIP; trees correct.*
3. **Hook the real pass** — suppress native per-tree emission for tagged veg, redirect to instanced
   path, match state. *Gate: in-game parity, frame time flat/better.*
4. **LOD + imposter crossfade in-shader (anti-pop mechanism)** — per-instance fade (from `dist1..3`
   / the `obj[0x74]` accumulator) → shader dither/blend for the mesh↔imposter transition.
   *Gate: approaching a tree gains detail with no snap.*
5. **Resident imposter horizon (eliminate pop-in — the primary goal)** — keep a cheap instanced
   `PgBillboardTree` imposter of every tagged tree resident to the horizon: push `dist0` (and the
   streaming byte-budget `[mgr+0x4c350/4c358]`) out to **match the existing ~800 m view distance** for
   the imposter tier so the entity never streams fully out in view, while the full-mesh tier stays
   short-range. (Target is fixed by the existing view distance — not a new number to invent.) Trees never appear from
   nothing; they only sharpen on approach. Then (secondary) add placements via the vz_state writer +
   pool bumps (cdbsizes.ini) for JC2-style density. *Gate: fly/drive across the map — no tree
   spawns from nothing; frame rate held.*

---

## 9. Open items requiring x32dbg (confirm-live)

- Tree draws physically reach `FUN_007512f0` (vs an unseen packet consumer) — strong default, verify.
- Live `SetStreamSourceFreq` divider value (§2).
- Exact `SetTexture` slot indices + sampler states for the tree pass (§5).
- Concrete `ALPHAREF`/`ALPHAFUNC`/`CULLMODE`/`ZFUNC`/fog per material-class bucket (§5).
- The `FUN_00854b38` packet-executor class→state mapping — **no existing corpus map; document it.**

## 10. Address appendix

| Symbol | Addr | Role |
|---|---|---|
| FUN_00466d40 | 0x00466d40 | per-viewport scene-pass driver |
| FUN_004a6590 | 0x004a6590 | collect/classify (visible list → scene+0x1430) |
| FUN_00468bb0 | 0x00468bb0 | RenderFadingTrees — per-object fade gate + draw dispatch |
| FUN_00468e40 / FUN_00468ca0 | — | Render/RenderZPass / RenderShadow |
| FUN_004a3e40 / FUN_004a3db0 | — | tree color/z loop / tree shadow loop |
| FUN_004a2070 / 004a22a0 / 004a1af0 / 004a1d10 / 004a1ed0 | — | per-pass tree draw fns |
| FUN_004a24a0 | 0x004a24a0 | build 11 per-instance VS constants c0–c10 |
| FUN_00835e80 | 0x00835e80 | view/view-proj matrix snapshot (0x40 B) |
| FUN_008546a0 | 0x008546a0 | pack 0x58 B command packet → ring |
| FUN_008548f0 / FUN_008549a0 | — | packet sort-key / bucket-sort |
| FUN_00854b38 | 0x00854b38 | packet queue consumer (GPU-state seam) |
| FUN_00751790 → FUN_007518b0 | — | display-list walk → bytecode interpreter |
| FUN_007512f0 | 0x007512f0 | **DrawIndexedPrimitive** (device+0x148) — sole DIP site |
| FUN_00751330 / FUN_007513f0 | — | DrawPrimitive (+0x144) / SetStreamSourceFreq (+0x198, opcode 0x13) |
| FUN_00752a50 | 0x00752a50 | stream bind incl. SetStreamSourceFreq |
| FUN_00752b30 / FUN_0074d6d0 / FUN_00856360 | — | vertex-decl bind / build / create |
| FUN_00858150 / FUN_00857a90 / FUN_00857c00 | — | distance classify / AABB / frustum |
| Device ptr | *(DAT_01176288+0x5bc) | IDirect3DDevice9 |
| Shader table | 0x0143b460 | PgBillboardTree 4-record data-driven table |
| Tree-batch array | DAT_01175a30 (stride 0x710, count DAT_00e90734) | one batch = one species |
| Geometry rings | DAT_00e90710/714 (stride 20), DAT_00e90718 (stride 16) | shared quad grid |
| Veg-quality bit | (*(DAT_01176288+0x5e4) >> 4) & 1 | tree/veg quality gate |
