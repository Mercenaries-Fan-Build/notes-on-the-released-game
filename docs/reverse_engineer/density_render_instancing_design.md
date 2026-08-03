---
name: density_render_instancing_design
description: Render/GPU design for a surgical D3D9/SM3.0 instancing upgrade to Mercs2 (Pangea) — collapse the engine's own repeated draws into hardware-instanced DIPs so vegetation + crowd density stop causing draw-call collapse. No engine rewrite; asm/Rust splices at named seams. Companion to foliage_instancing_plan.md.
status: current
evidence: proven (spine + capability) + inferred (batch design) + needs-live (state tuples, counts)
date: 2026-08-02
supersedes: none — extends docs/reverse_engineer/foliage_instancing_plan.md from veg-only to props+crowds+veg
---

# Massive-density render upgrade — surgical D3D9 instancing design (RENDER/GPU half)

**Scope.** The render/GPU seam only. Two peer designs run in parallel and own the other halves:
the **optimization expert** owns per-frame CPU cost (submission O(N), the crowd *simulation* wall),
and the **runtime/systems architect** owns residency/streaming (keeping instanced rows on-screen).
The interfaces I need from each are in §10. This doc is the render architecture, the exact seam
addresses, the shader-crux solution + fallback, the prop/veg/crowd split, the dgVoodoo interplay,
staged milestones, and the honest per-item risk. Every address is first-hand from the decomp
(`output/_ghidra/securom_dump/mercs2_unpacked.exe`, base 0x400000) unless tagged INFERRED /
NEEDS-LIVE. The render spine itself is already fully mapped in `foliage_instancing_plan.md §1–2`;
that map is the substrate and is taken as PROVEN here.

---

## 0. One-paragraph recommendation

Do **not** try to instance at the single DIP choke (`FUN_007512f0`) or inside the hot bytecode
interpreter — that is where the per-object transform has already been *flattened into
`SetVertexShaderConstantF` opcodes* and is expensive to re-gather, and it is the hottest function
image-wide (hooking it has wedged the game before). Instead instance at a **hybrid two-tier seam**:

- **Tier A — source-side, per draw-class (veg first, then static props).** Redirect the *submission*
  functions that already hold a **structured instance list** (the veg species batch `DAT_01175a30`
  at `+0x708`; our own placement DB for props) into one hardware-instanced emit each. This is where
  we control the transform representation. LOW risk, cold-ish call sites.
- **Tier B — sink-side coalescer (generic safety net for props).** Extend the *existing*
  material-class sort so identical-state draws become adjacent runs, then a coalescing pass in the
  packet consumer `FUN_00854b38` merges each run of "same (VB,IB,decl,VS,PS,renderstate), differs
  only in the world-matrix constant" into `[SetStreamSourceFreq; one instanced DIP]`. This is the
  literal "make the engine's own repeated draws collapse" ask, and the sort that clusters the runs
  **already exists** (`FUN_008548f0` by `DAT_0116474c`).

The **shader crux** (constant → per-instance stream, only `vs_3_0` bytecode ships) is solved by a
**mechanical bytecode splice**: add four `dcl_texcoord` inputs for the per-instance matrix rows and
redirect the transform's constant reads to those inputs — leading with the case where the constant
is already a pre-combined `WorldViewProj` (a pure register-index swap, *no new math*). Delivered
**additively** (new `.sho` variants or a d3d9 shader-replacement shim — never overwriting a shipped
shader, per the no-destructive mandate). **dgVoodoo2** is the backend that raises the collapse
ceiling for free and is the natural delivery surface for the patched shaders, but it cannot instance
for us — the native seam still does the batching. **Crowds are deliberately deprioritized**: their
wall is CPU simulation, not draw submission; skinned instancing is the hardest and least rewarding
piece and is replaced here by *instanced billboard imposters for distant peds* only.

---

## 1. What the target actually is (draw-class census)

The "draw-call collapse" is three different populations with three different economics. Instancing
helps them in inverse order to their difficulty:

| Class | Count | Geometry | Transform delivery | Shader family | Instancing verdict |
|---|---|---|---|---|---|
| **Static props** | ~62k `SceneObject` (`0xb6185886`) | rigid, per-model VB/IB, tri-strips | **VS constant** (per-object `SetVertexShaderConstantF`) | `PgMeshVP` / `PgMeshVPAmbientWind` (+few perms) | **BIGGEST + EASIEST win. Start here.** |
| **Vegetation** | 9.6k understory placements + per-cell canopy | shared unit-quad grid (billboard) + tiny-mesh + near full-mesh | VS constants c0–c10 (`FUN_004a24a0`), or `ObjectIDScaleArray[]`/`LocalToWorld[]` | `PgBillboardTree*` (4-record data table @0x0143b460) + `PgMeshTiny*` | **Second. Fully specced in foliage_instancing_plan.md.** |
| **Crowds** | `Ai 1024`(→2048) pool | skinned, per-group palettes | VS constant + bone palette upload (`FUN_00479d90`) | `PgSkin*` | **Hardest, least benefit — DEFER. Wall is sim, not draws (see §4).** |

**Why props win most (INFERRED, NEEDS-LIVE to size).** 62k rigid objects funnel through the one DIP
site, each preceded by a `SetVertexShaderConstantF` of its world matrix. But they share a **very
small set of distinct draw *states*** — the batching key is `(VB, IB, decl, VS, PS,
material-class byte +0x44)`, and the VS side is dominated by the two `PgMeshVP` permutations
(the wind bit is `(*(DAT_01176288+0x5e4) >> 2) & 1`, selected at registration in `FUN_0084f130`).
Many props reuse the same model (fences, lampposts, crates) → the same VB/IB. So a large fraction
of the 62k collapses onto a handful of `(state)` runs, each of which becomes ONE instanced DIP.
**The dominant-state histogram is the single most important number to measure live** (§9, milestone
M0) — it sets the achievable draw-call reduction and tells us how many shaders §2 must patch.

---

## 2. THE SHADER CRUX — transform: constant → per-instance stream

**The problem (PROVEN).** Every instanceable class delivers its per-object world transform as a
**vertex-shader constant** via `SetVertexShaderConstantF` (`FUN_00748e00`, device+0x178, interpreter
opcode at 0x751c71). Hardware instancing requires the bound VS to read the transform from a
**per-instance vertex stream** (stream 1, `SetStreamSourceFreq(1, INSTANCEDATA|1)`) instead. Only
compiled `vs_3_0` bytecode ships — no HLSL. So the transform read has to be redirected *inside the
compiled shader*.

### 2.1 Recommended: mechanical `vs_3_0` bytecode splice (lead case = pure register swap)

`vs_3_0` DXBC is fully documented and locally editable. The transform in a Pangea VS is one of two
forms; both are a small, mechanical edit:

- **Case A — the constant is a pre-combined `WorldViewProj`** (World baked with view-proj CPU-side
  per object; the common 2008 pattern). The shader body is essentially
  `dp4 oPos.{x,y,z,w}, v0, c[N..N+3]` (or `m4x4 oPos, v0, c[N]`). **The edit is a pure
  register-index swap:** declare four instance inputs `dcl_texcoord4..7 v5..v8`, change the four
  `c[N..N+3]` operands in the transform to `v5..v8`, and bump the input-usage count in the version
  token. **No new math, no new constants.** The per-instance WVP is computed by our instance-buffer
  builder (cheap, parallel, CPU) and streamed. This is the **lowest-risk shader edit** and we lead
  with it.

- **Case B — the constant is a separate `World` (+ shared `ViewProj` constant).** Stream the
  per-instance `World` (4 inputs), keep `ViewProj` as a shared constant, and add `mul World*ViewProj`
  in-shader (≈4 extra instructions; `vs_3_0` caps at 512 — vast headroom). Preferred when the shader
  also transforms **normals/tangents by World** for lighting (normal-mapped props): stream `World`
  once, reuse for position and normal. Watch the `vs_3_0` **16-input limit** (v0–v15): a
  normal-mapped static prop is pos+uv+normal+tangent (4) + WVP-or-World (4) + World-for-normals (4)
  = up to 12 — fits. Skinned adds blendweights+blendindices (+2) and does **not** fit cleanly →
  another reason to defer crowds (§4).

**Which register holds the transform** is recoverable offline, not by guessing: the `.sho` blobs
carry a `vs_3_0` constant table (the 344 `*.updb` debug DBs name the registers, e.g.
`WorldViewProj`), and for the veg path `FUN_004a24a0` already documents c0–c10. Estimate: the set of
VS that dominate props+veg is **< ~20 shaders** (the `PgMeshVP` perms + the 4 `PgBillboardTree` +
`PgMeshTiny*`), not hundreds. Patching ~20 shaders is tractable.

**Watch the decl types when adding stream elements.** Reuse the engine's own declaration builder
(`FUN_0074d6d0` build / `FUN_00856360` create device+0x158 / `FUN_00752b30` bind). The instance
matrix rows should be `D3DDECLTYPE_FLOAT4`; do **not** reuse the `DEC3N` 10-10-10-2 packing the
engine uses for tangents/normals (that packing already cost a session — see
`dec3n-tangent-layout-bug`). Preserve the base decl (stride 16/20 for veg; the model's own for
props) and *append* stream-1 elements.

### 2.2 Delivery — ADDITIVE, two routes

Per the **no-destructive-replacements** mandate, patched shaders ship as **new** programs, never
overwriting a shipped `.sho`:

- **Route 1 — new `.sho` variants + registration.** Emit the patched blob as an additive shader,
  register it beside the original. Static props register through `FUN_0084f130`
  (`register(name, name.sho, lod)`); veg is *not* in that registry — its four programs live in the
  data table at **0x0143b460** (`{class-vtable, name-hash, program handle, inline .sho name}`), so
  for veg we redirect the **program handle** field of the record for the tagged pass to our instanced
  program. Select our variant for tagged draw-classes only; everything else keeps stock.
- **Route 2 — d3d9 shader-replacement shim (3DMigoto-style).** A thin D3D9 wrapper (the ecosystem is
  already reviewed in `docs/external_tools_review.md §5`) hashes each `CreateVertexShader` blob and
  substitutes our patched bytecode by hash at load. This **decouples the shader crux from exe
  surgery entirely** and composes with dgVoodoo (shim in front, dgVoodoo behind). Attractive because
  it needs no registry/table patching and is trivially reversible. Recommended as the *iteration*
  vehicle; Route 1 can be the shipped form once a shader is proven.

### 2.3 Fallback — the engine's own constant-indexed instancing (`PgMeshTiny`)

If a given VS resists bytecode patching, the engine **already ships a working instanced shader we did
not have to author**: `PgMeshTiny`/`PgMeshTinyVP` reads `ObjectIDScaleArray[id]` (scale/fade) and
`objectData.LocalToWorld[id]` (transform) indexed by a per-vertex object id (foliage plan §3, §6).
This is *constant-indexed* instancing: no stream-freq, no new decl, no shader authoring — fill the
`LocalToWorld[]` constant array and draw N copies of the base mesh with per-vertex ids. Ceiling is
**~50–60 instances/draw** (SM3.0 has 256 vs float4 constant registers; 4 per matrix). That is a
50–60× draw-call cut with **zero shader risk** — the correct first proof and the guaranteed floor.
The stream-freq route (§2.1, thousands/draw) is the ceiling-lifter layered on top.

---

## 3. The instancing seam (Q1) — where the collapse happens

### 3.1 Why source-side for the transform, sink-side for the mechanics

The render spine is `submission → pack 0x58B packets (FUN_008546a0) → sort by material class
(FUN_008548f0/9a0, key = packet+0x44 = DAT_0116474c) → consumer FUN_00854b38 (applies
SetRenderState/SetTexture per bucket) → interpreter FUN_007518b0 → the one DIP FUN_007512f0`.

- **At submission**, the per-instance transform is still a **structured array** (veg species batch
  instance table `+0x708`, stride 28 = xyz+entity-id; or our placement DB). Cheap to turn into an
  instance buffer.
- **By the interpreter**, that transform is a **`SetVertexShaderConstantF` opcode** interleaved in
  the bytecode. To instance there you must parse the constant-set opcodes back into a matrix array
  per run — doable but fragile, and it fights the hottest code in the frame.

So: **own the transform representation at submission (Tier A); do the mechanical
`SetStreamSourceFreq`+DIP emission using the sink-side path, unchanged (Tier B).**

### 3.2 Tier A — source-side redirect (veg, then props)

- **Veg:** hook `FUN_00468bb0 RenderFadingTrees` / the per-pass draw fns `FUN_004a2070` (main),
  `FUN_004a22a0` (LOD-fade), `FUN_004a1af0` (shadow), `FUN_004a1d10/1ed0` (z). Replace the
  per-instance `build c0–c10 (FUN_004a24a0) → SetVertexShaderConstantF → DIP` loop with:
  fill a stream-1 instance buffer from the species batch, `SetStreamSourceFreq`, one DIP. This is
  foliage-plan Phase 2/3 verbatim; this doc just places it in the shared seam taxonomy.
- **Props:** we do **not** have a clean per-frame prop-instance list inside the engine (props emit
  individually). Two options: (i) build the prop instance list **offline from our placement DB**
  (mirroring the engine cull math `FUN_00858150` dist/LOD, `FUN_00857a90`/`FUN_00857c00` AABB/frustum,
  camera at `PTR_PTR_00dfc2f8 + vp*0xE80`), same Option-B decision the foliage plan already made; or
  (ii) let **Tier B** harvest the prop transforms from the live packet stream (below). Recommend
  **Tier B for props** first — it needs no offline placement mirror and catches *whatever* the engine
  actually submits, then Tier A/offline as an optimization if the harvest proves costly.

### 3.3 Tier B — sink-side coalescer (the generic "collapse the engine's own draws")

The enabling fact: **packets are already sorted by material class** (`FUN_008548f0`), so
identical-state draws are already *adjacent* by the time the consumer `FUN_00854b38` walks them. The
design:

1. **Extend the sort key** from `material-class (packet+0x44)` to the full tuple
   `(material-class, VB, IB, decl, VS, PS)` so a "run" in the consumer is a set of draws that differ
   **only** in their world-matrix constant. (Sort is cold relative to per-primitive work; touching
   the comparator is safe.)
2. **In the consumer**, detect a run of length ≥ threshold (e.g. ≥8). For the run, read each packet's
   world-matrix constant payload, gather them into a **per-frame instance ring we own** (never touch
   the engine ring `DAT_00ff4700`), then rewrite the run's replay as
   `[SetStreamSourceFreq(0, INDEXEDDATA|N); SetStreamSourceFreq(1, INSTANCEDATA|1); one instanced DIP]`
   bound to the §2 instanced variant of that run's VS. Runs below threshold replay natively unchanged
   (fail-open).
3. The instanced DIP still issues **through the untouched `FUN_007512f0`** — we don't hook the choke,
   we just feed it one call instead of N.

Compare (a) intercept-and-batch vs (b) Rust-replaced consumer: **do (b) for the consumer body** — a
Rust-compiled replacement of `FUN_00854b38` (delivered as an ASI, the proven `crowd_fog_couple.asi`
pattern) is cleaner and safer than in-place asm-splicing a coalescer into a 2008 C++ function, and
the consumer is per-bucket (warm), not per-primitive (hot). Keep (a) — a minimal trampoline — only
for the small submission hooks in Tier A.

---

## 4. Prop vs veg vs crowd strategy (Q3)

- **Static props — do first, expect the most.** Rigid single matrix, few VS, heavy VB reuse. Tier B
  coalescer + §2.1 Case-A shader (pure register swap). Highest draw-call reduction per unit risk.
- **Vegetation — do second.** Already fully specced (foliage plan). Billboard/tiny/near-mesh; the
  §2.3 `PgMeshTiny` fallback is literally the engine's own veg instancer. Instancing is the *enabler*
  for the resident-imposter horizon that kills tree pop-in (the primary user-visible goal).
- **Crowds — deprioritize; imposters only.** Two hard truths:
  1. **The crowd wall is CPU simulation, not draw submission** (foliage plan §6.5, corroborated by
     `entity-density-config-plus-laa-patch` + `render_distance_and_density_levers`): per-entity AI /
     `Perception` / `StateMachine` / `_HumanPhysics`+Havok, O(N) `Road_SnapNearest` (`FUN_004fe660`),
     road-graph rebuild (`FUN_004fd9f0`), `sqrt` physics sweep (`FUN_0040cbb0`). **GPU instancing
     cannot touch any of it** — that is the optimization expert's problem (§10).
  2. **Skinned instancing is the hardest render case.** Each instance needs its own bone palette;
     palettes are **per-draw-group palette-relative** (`INFO(56)` range table, uploaded by
     `FUN_00479d90` — see `blendindices-per-group-palette`), so instances at *different animation
     frames* cannot share a constant palette. SM3.0 has no structured buffers; per-instance palettes
     would need vertex-texture-fetch (`texldl`, a per-instance bone-matrix texture) — real work for a
     population whose actual bottleneck is elsewhere.
  - **What we DO for crowds (render side):** distant peds → **instanced billboard imposters** on the
    same `PgBillboardTree`-style path (§2, veg pipeline). This gives crowd *visual density at
    distance* for free once veg instancing exists, sidesteps skinned instancing entirely, and is the
    only crowd render work worth doing until the sim wall is addressed.

---

## 5. How dgVoodoo2 changes the calculus (Q4)

- **It raises the collapse ceiling for free.** D3D9→D3D11/12 lowers per-DIP driver/runtime CPU cost
  and modernizes GPU scheduling, so the engine tolerates **more raw DIPs before collapse**. The
  *first* usable density win may be "run under dgVoodoo + push residency/density (systems architect)
  with **props-only** native instancing" — no full veg/crowd work needed for *moderate* density.
- **It does not remove the wall.** The O(N) submission cost *inside the exe* — pack `FUN_008546a0`,
  sort, and the interpreter walking N DIP opcodes on the single render thread — is **upstream of
  dgVoodoo** and unchanged by it. For JC2-class horizon density you still need native instancing to
  cut the *submission count*, not just the per-draw cost. (PROVEN by architecture: dgVoodoo sees the
  API stream after the engine has already paid to build it.)
- **Can we instance *at* the dgVoodoo layer? No.** dgVoodoo is closed and faithfully translates D3D9
  semantics; it will not auto-merge distinct DIPs (each carries a different constant, and it can't
  know they're instanceable). A 3DMigoto-style D3D9 shim *could* coalesce at the API layer, but it
  hits the same "transform is buried in a constant-set call" problem as the interpreter seam **and**
  is blind to the material-class sort. So: **instance natively at the engine submission seam** (where
  the instance list is structured); **use dgVoodoo as the backend** (free per-draw win + modern GPU)
  and as the **delivery surface for the patched shaders** (via the §2.2 Route-2 shim in front of it).
- **Net effect on aggressiveness:** dgVoodoo lets us ship **Milestone M2 (props) alone** as a real
  improvement and defer the deepest veg/crowd work — it de-risks staging, it does not replace the
  native seam.

---

## 6. Surgical footprint (Q5) — exact grafts and how it stays stable

Ranked coldest→hottest (hook cold, never hot):

| Graft | Address | Temp | Mechanism | Purpose |
|---|---|---|---|---|
| Veg draw redirect | `FUN_00468bb0`, `FUN_004a2070/22a0/1af0/1d10/1ed0` | per-species/frame (cold) | trampoline detour | Tier A veg instanced emit |
| Sort-key extension | `FUN_008548f0` comparator | per-frame sort (cold) | small splice | cluster instanceable runs |
| Consumer coalescer | `FUN_00854b38` | per-bucket (warm) | **Rust-replaced body (ASI)** | Tier B collapse runs → 1 DIP |
| Vertex-decl for stream-1 | `FUN_0074d6d0`/`FUN_00856360`/`FUN_00752b30` | setup (cold) | call existing builders | append per-instance elements |
| Stream-freq emit | `FUN_00752a50` / opcode 0x13 `FUN_007513f0` | per instanced DIP (warm) | **use as-is** (already wired) | HW instancing, no new import |
| Shader delivery | table `0x0143b460` (veg) / `FUN_0084f130` (props) / d3d9 shim | load-time (cold) | additive register / shim | bind §2 instanced VS |
| DIP choke | `FUN_007512f0` | per-primitive (**hottest**) | **READ-ONLY anchor; never hook** | verify + issue the coalesced DIP through it unchanged |

**Stability rules (learned the hard way — see `x32dbg-mcp-pitfalls`, the past hot-path wedges):**
1. **Never** put a hook or conditional breakpoint on `FUN_007512f0` or inside `FUN_007518b0`'s
   per-opcode loop — a conditional bp on a hot per-frame fn kills x32dbg *and* the game.
2. Hook only **cold/warm** call sites (per-species, per-bucket, per-frame), never per-primitive.
3. **Additive buffers only.** Our instance ring is ours; do not resize or reinterpret the engine ring
   `DAT_00ff4700` (2 buckets × 0x2000) or the 0x58B packet layout.
4. **Preserve the material-class bucket + decl exactly.** Wrong class → trees/props render invisible
   or mislit (foliage plan §5 warns explicitly): keep opaque alpha-tested cutout for main/z/shadow,
   class-8 alpha-blend for LOD-fade; keep the stride-16/20 base decl for veg.
5. **Feature-flag by draw-class tag, fail-open.** Any run we don't confidently recognize replays
   natively unchanged. Env-tunable like `crowd_fog_couple` (`CROWD_FOG_DIST`).
6. **Deliver as an ASI** (32-bit, the proven `crowd_fog_couple.asi` MinGW pattern) so it composes
   with the LAA patch, dgVoodoo, and is reversible by deleting one file.

---

## 7. Staged milestones (each independently verifiable)

Each gate is an **exit condition measured with a tool**, never an eyeballed frame (per the
verification-discipline mandate). Verify instanced draws with a PIX/RenderDoc capture (D3D9, or D3D11
under dgVoodoo).

- **M0 — Baseline + dominant-state histogram (NEEDS-LIVE).** With a dense viewpoint loaded: capture
  DIP count/frame and render-thread ms; group DIPs by `(VB,IB,decl,VS,PS,material-class)` to get the
  dominant-state histogram (§1). Confirm props/veg draws funnel through `FUN_007512f0`; read the live
  `SetStreamSourceFreq` divider (`FUN_00752a50`). *Gate: a DIP/ms number to beat + a run-length
  histogram + the count of VS §2 must patch.*
- **M1 — Fallback proof (constant-indexed, zero shader risk).** One prop model, N copies, via the
  engine's own `PgMeshTiny` `LocalToWorld[]` path (§2.3). *Gate: PIX shows ~N/50 DIPs; props render
  correct.* This validates state-replay against a *working* engine shader before touching bytecode.
- **M2 — First stream-freq instanced DIP (the shader crux, Case A).** Bytecode-patch ONE dominant
  prop VS to read WVP from stream-1 (§2.1 Case A), deliver via the d3d9 shim (Route 2), and issue one
  instanced DIP for one prop run. *Gate: PIX shows a single `SetStreamSourceFreq`+instanced DIP;
  transforms correct; identical pixels to the native run.*
- **M3 — Tier B prop coalescer live.** Rust-replaced `FUN_00854b38` + extended sort key; all
  qualifying prop runs collapse. *Gate: in-game parity, DIP count down by the M0-predicted factor,
  frame time flat/better, no visual regression.*
- **M4 — Veg instanced (adopt foliage-plan Phase 2/3 under this seam).** *Gate: dense forest
  viewpoint holds frame rate; PIX shows per-species instanced DIPs.*
- **M5 — Density + residency (needs the systems architect).** Push residency so instanced rows stay
  on-screen (resident imposter horizon → no tree pop-in) and raise placement density. *Gate: drive
  across the map — nothing spawns from nothing; frame rate held under raised density.*
- **M6 (optional) — Distant-crowd imposters.** Instanced billboard peds at range on the veg path.
  *Gate: visible crowd density at distance with no new per-entity sim cost.*

M2 is the pivotal risk gate. If Case-A bytecode patching a real shader proves intractable, M1's
fallback + dgVoodoo still delivers a large, shippable prop win — the program does not stall.

---

## 8. Risk register (honest, per item)

| Risk | Likelihood | Impact | Mitigation / fallback |
|---|---|---|---|
| Prop transform constant is **not** a clean WVP (Case B, or interleaved with other constants) | Medium | Medium | §2.1 Case B (stream World, mul in-shader); worst case §2.3 constant-indexed fallback (no shader edit) |
| `vs_3_0` **16-input limit** blown (normal-mapped + skinned) | Low for props, High for skinned | Medium | props fit (≤12); skinned is deferred anyway (§4) |
| Coalescer harvests wrong constant / wrong world matrix from a packet | Medium | High (garbled props) | threshold + strict state-tuple match + fail-open native replay; validate against native run pixels at M2 |
| Hooking `FUN_00854b38` destabilizes the frame (it's warm) | Medium | High (wedge) | Rust-replace the *whole* body (not an in-line splice); it's per-bucket not per-primitive; feature-flag off = stock |
| Wrong material-class/decl → invisible or mislit | Medium | High | copy the exact bucket+decl from the native path; foliage plan §5 checklist |
| dgVoodoo + shim + ASI interaction (shader shim vs D3D9→11 translation) | Medium | Medium | prove shim alone on D3D9 first (M2), then stack dgVoodoo; both reversible independently |
| Instanced geometry references a **streamed-out** VB/IB (dangling) | Medium | High (hang, cf. dangling-LOD-rung livelock) | systems architect guarantees residency of referenced geometry before emit (§10); `aset_refcheck`-style gate |
| Per-frame instance-buffer build adds CPU cost that eats the win | Low | Medium | O(N) flat cull math, parallel, far below per-DIP driver cost (foliage §6.5); optimization expert budgets it (§10) |
| SM3.0 constant-indexed fallback ceiling (~50–60) too low for JC2 density | Certain (by design) | Low | it's the floor/first-proof only; stream-freq route lifts to thousands |

---

## 9. Live-confirm checklist (x32dbg — user drives, read-only, PAUSED)

Everything here is INFERRED-strong from the decomp but must be confirmed on the running game before
committing a seam. **No resume; no conditional bp on hot fns** (`x32dbg-mcp-no-resume`,
`x32dbg-mcp-pitfalls`).

1. Prop + veg draws physically reach `FUN_007512f0` (vs an unseen consumer) — read the call stack at
   the choke with foliage/props on screen.
2. Live `SetStreamSourceFreq` divider at `FUN_00752a50` / opcode 0x13 (confirm it's the dormant `1`).
3. **The dominant-state histogram (M0)** — the run-length distribution of adjacent same-state packets
   in `FUN_00854b38`. This sizes the whole win.
4. Which constant register(s) hold the prop world matrix, and whether it's WVP (Case A) or World
   (Case B) — read the `SetVertexShaderConstantF` start-register + payload for a known prop; cross-
   check the `.sho`/`.updb` constant table.
5. Exact `SetTexture` slots + sampler states + `ALPHAREF`/`ALPHAFUNC`/`CULLMODE`/`ZFUNC`/fog per
   material-class bucket applied by `FUN_00854b38` — **no corpus map of this executor exists; produce
   one** (also a foliage-plan open item).
6. VS-input count headroom for the dominant prop shader (confirm ≤12 used).

---

## 10. Interfaces I need from the other two architects

**From the runtime/systems architect (residency/streaming):**
- A **stable per-frame, per-draw-class instance list** in a known memory layout my instance-buffer
  builder consumes: `{ world-matrix (or pos+quat+scale), LOD tier, fade accumulator, params }` per
  instance. For veg this can be the existing species batch (`DAT_01175a30 +0x708`); for props I need
  either the live-harvested set (Tier B) or an offline placement-DB mirror — please own whichever.
- **A residency guarantee:** any geometry (VB/IB) referenced by an emitted instance is resident
  before the instanced DIP issues — a dangling reference here is the same failure mode as the
  dangling-LOD-rung livelock (549 GB buffer request → hang). I will gate emit on a residency flag you
  set.
- The **resident-imposter-horizon** work (dist0/stream-out/budget `[mgr+0x4c350/4c358]`) that keeps
  instanced rows on-screen — my instancing is the *enabler*, your residency is what makes it visible.

**From the optimization expert (CPU / sim):**
- A **per-frame budget** for the instance-buffer build (O(N) cull arithmetic) and for the Tier B
  coalescer pass, with confirmation both complete within the render-thread frame.
- Ownership of the **crowd simulation wall** — road snap `FUN_004fe660`, road-graph `FUN_004fd9f0`,
  physics sweep `FUN_0040cbb0`, Havok. Instancing provably cannot touch these; crowd *density* is
  gated by them, not by my draw path.
- The **visible set** from the engine cull (`FUN_00858150` dist/LOD, `FUN_00857a90`/`FUN_00857c00`
  frustum) if you already compute it — so I instance only visible rows and don't duplicate the cull.

---

## 11. Address appendix (render/GPU seam)

| Symbol | Addr | Role | Evidence |
|---|---|---|---|
| `FUN_007512f0` | 0x007512f0 | **the only** `DrawIndexedPrimitive` (device+0x148) — verify anchor, never hook | PROVEN |
| `FUN_007518b0` | 0x007518b0 | display-list bytecode interpreter (opcode switch) | PROVEN |
| `FUN_007513f0` | 0x007513f0 | opcode 0x13 → `SetStreamSourceFreq` (device+0x198) — HW instancing, already wired | PROVEN |
| `FUN_00752a50` | 0x00752a50 | stream bind incl. `SetStreamSourceFreq` | PROVEN |
| `FUN_00748e00` | @0x751c71 | `SetVertexShaderConstantF` (device+0x178) — the transform-delivery call | PROVEN |
| `FUN_008546a0` | 0x008546a0 | pack 0x58B command packet → ring `DAT_00ff4700` | PROVEN |
| `FUN_008548f0` / `FUN_008549a0` | — | packet **sort by material class** (key = packet+0x44 = `DAT_0116474c`) / bucket-sort — **extend this sort key** | PROVEN |
| `FUN_00854b38` | 0x00854b38 | packet **consumer** (GPU-state seam) — **Rust-replace for Tier B coalescer** | PROVEN |
| `FUN_0074d6d0` / `FUN_00856360` / `FUN_00752b30` | — | vertex-decl build / create (device+0x158) / bind (device+0x15c) — append stream-1 elements | PROVEN |
| `FUN_00468bb0` | 0x00468bb0 | `RenderFadingTrees` — Tier A veg hook | PROVEN |
| `FUN_004a2070/22a0/1af0/1d10/1ed0` | — | per-pass veg draw fns | PROVEN |
| `FUN_004a24a0` | 0x004a24a0 | build 11 per-instance VS constants c0–c10 (tree path) | PROVEN |
| `FUN_00858150` / `FUN_00857a90` / `FUN_00857c00` | — | dist/LOD classify / AABB / frustum (cull math to mirror) | PROVEN |
| `FUN_0084f130` | 0x0084f130 | static-shader registry `register(name,name.sho,lod)` — additive prop-shader delivery | PROVEN |
| PgBillboardTree table | 0x0143b460 | 4-record veg shader data table (redirect program handle) | PROVEN |
| `PgMeshTiny*` / `ObjectIDScaleArray` / `objectData.LocalToWorld[]` | — | engine's own constant-indexed instancer (§2.3 fallback) | PROVEN |
| Device ptr | `*(DAT_01176288+0x5bc)` | IDirect3DDevice9 | PROVEN |
| View-proj | `PTR_PTR_00dfc2f8 + vp*0xE80 + 0xb70` | (view +0xab0, proj +0xaf0, world pos +0xb20) | PROVEN |
| Wind-perm bit | `(*(DAT_01176288+0x5e4) >> 2) & 1` | `PgMeshVP` vs `PgMeshVPAmbientWind` selection | PROVEN |
| Tree-batch array | `DAT_01175a30` (stride 0x710, count `DAT_00e90734`) | one batch = one species; instance table +0x708 | PROVEN |

## 12. Cross-references
- `docs/reverse_engineer/foliage_instancing_plan.md` — the veg-specific plan + full spine map (the substrate).
- `docs/reverse_engineer/render_core_code_map.md`, `lighting_code_map.md`, `prop_lod_imposter_code_map.md` — render code maps.
- `docs/reverse_engineer/render_distance_and_density_levers.md` + memory `crowd-fog-couple-asi`, `entity-density-config-plus-laa-patch` — the density levers already applied (LAA, 2× pools, fog couple).
- `docs/modernization/material_shader_spec.md`, `skinning_animation_spec.md`, memory `blendindices-per-group-palette` — material/skin/palette semantics (the skinned-instancing barrier).
- `docs/external_tools_review.md §5` — D3D9/rendering tools (3DMigoto shim, PIX/RenderDoc).
