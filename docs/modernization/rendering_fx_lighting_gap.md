# Rendering / FX / Lighting — faithful-implementation gap map

**Purpose:** the honest, exhaustive catalog of what the Pangea (Mercs2) presentation stack does vs what
`mercs2_engine` implements today, so we implement *everything* per the reversed description instead of
discovering the gap piecemeal. Cross-referenced to `docs/ucfx_tag_registry.md` (chunk formats),
`docs/mercs2-pdb-analysis/rendering-shaders.md` (pipeline), `docs/mercs2-ecs/05_presentation_audio_fx.md`
(components), and `docs/ghidra_knowledge_inventory.md` (handlers). Compiled 2026-07-04.

Status legend: ✅ done · 🟡 partial · ❌ not started.

## Where we are today (baseline)
`shader.wgsl` = textured + tangent-space normal map + **one fixed directional light** (`L=(0.4,0.7,-0.5)`,
ambient 0.35) + placeholder exponential fog. A **single forward pass**, no z-prepass, no shadow pass, no
reflection pass, no post. `LoadedModel.clips` empty (props don't animate). No lights, particles, decals,
sky, or water code in the engine at all.

## The subsystems

### A. Geometry / mesh — 🟡 mostly done
- ✅ GEOM/PRMG/STRM/`decl`/`data`/`info`/IBUF/PRMT/POFF, HIER + SEGM (skeleton + bone bind), INDX.
  (`mesh.rs::build_indexed_state`, `model_cubeize`, `skeleton.rs`.)
- ❌ `MESH`/`TINY` LOD imposters (0x471900 / 0x471a01) — we always draw top LOD; no distance LOD swap.
- ❌ `PHY2` Havok collision (0x4a845f) — we built our own capsule controller instead (acceptable).
- ⚠ SEGM byte-3 semantics: we treat it as a `state_mask` bitmask; registry calls it `group`. Reconcile
  against the SEGM consumer decomp before trusting it for anything beyond the current heuristic.

### B. Materials / shading — 🟡 partial
- ✅ MTRL diffuse (slot 0) + normal (slot 2). Alpha-tested cutout. Hi-res texture streaming
  (`extract_texture_hires`) + NAME labelling.
- ❌ **Specular / gloss (slot 1, the `_sm` maps)** — dropped. Every interior material has one.
- ❌ Detail maps / slots 3-9 (MTRL is a fixed 10-slot array, reg line 354).
- ❌ Per-material **shader permutations** (`_pl`/`_sl`/`_pl_sl` = point-light / shadow-light variants;
  `AmbientWind`/`Ruin`/`Morph`/`Tiny` mesh-shader variants). We have one übershader.
- ❌ No real BRDF (fixed `ambient + 0.9·NdL`); no HDR-space lighting.

### C. Lighting — ❌ not started (1 fake directional)
- ❌ **`LightObject`** ECS (0x97e8ee92, `FUN_006622e0`; 0x34 bytes = id + color + 9 floats:
  color rgb, intensity, radius/attenuation, cone, …). Placed dynamic **point/spot lights** — the
  interior is lit by these (the villa's `global_portablelight` etc.). Read from `layers_static` /
  `vz_state` placements and the interior blocks. *"Low effort, high visual impact"* (per ue5 mapping).
- ❌ **`LightAnimation`** (0xbd5349f7 — 10 floats + int) flicker/pulse; **`ColorAnimation`**,
  **`ScaleAnimation`**.
- ❌ Sun/directional day-night (`PgSun`), ambient/GI approximation.
- ❌ Multi-light accumulation (forward+ or deferred) — the `_pl_sl` permutations imply per-light passes.
- ❌ `BlobShadow` ECS (0x40349618) cheap projected blob shadows under characters/props.

### D. Shadows — ❌ not started
- ❌ Depth `ShadowBuffer` + per-mesh-type shadow VPs (`PgMeshShadowVP`, `PgSkinShadowVP`,
  `PgRoadShadowVP`, `PgBillboardTreeShadowVP`); `ShadowBounds`/`GetShadowBaseDistance`.
- ❌ `BlobShadow` (cheap fallback).

### E. Particles / FX — ❌ not started (the biggest gap)
Mercs2 is explosion/smoke/fire-heavy; the Lua drives emitters constantly (`ObjectState.StartEmitter/
StopEmitter`, `global_particle_*` templates). None of this exists in-engine.
- ❌ **`fxdict`/DICT** (`FUN_00491320`): 630×20B effect-parameter records (name_hash + 4 floats/flags),
  the effect param namespace. (reg §7.)
- ❌ **Effect template** cluster: `EFCT` header, `EMTR` emitter, `EMIT` timing, `ATRB` attributes,
  `FRCE` forces (gravity/drag/vortex hash→reader), `COLR` 200B gradient palette (age-sampled), `TEXT`
  texture refs, `PTYP` flags, `POFF` offset, `TRFM` matrix. (reg §7, loader 0x492AF0.)
- ❌ **ECS spawners**: `ParticleEmitter` (0xe595ab2f, `FUN_00661190`), `RedEffectComponent`
  (0x60a13e3e), `EffectTemplate` (0xabaa1f3c), `EffectAiOccluder`.
- ❌ **Runtime**: hardpoint-attached emitters (`hp_fx_*` nodes), billboard/soft particles, additive
  blending, `Ribbon` (0x059b95b9) trails/tracers, `Render3DParticles-FX` pass.

### F. Sky / atmosphere / post — ❌ not started (fog placeholder)
- ❌ `PgSky`/`PgSun`/`PgCloud` sky+atmosphere; ❌ HDR tone-map + `PgBloomCombiner` bloom;
  ❌ reflection pass; ❌ water (scoped separately, see `water-and-swimming-scope`).

### G. Decals — ❌ not started
- ❌ Projected decals (bullet holes, scorch, `global_decal_super_concrete` seen in the hall MTRL).
  Job-parallel decal render per the pipeline doc.

### H. Animation playback — 🟡 partial
- ✅ Character skeletal (Mattias wavelet decode, 168/168 tests; hand/head solved).
- ❌ **Prop/object clips** — `TRCK`/`VALU`/`KEYS`/`MANM` parsed+validated but NOT loaded into
  `LoadedModel.clips`; interior props/doors/machines don't animate.
- ❌ `BoneCtrlLocalRotation` / continuous controllers (rotor spin etc.), `LightAnimation` curves.

### I. Render architecture — 🟡 single-pass
- Game: `PgScene::Render` per viewport, passes **z → color → shadow → reflection**, job-parallel;
  Renderable lifecycle (`AddRenderable`/`RenderableUpdate`/hibernation), `Model::Render`/`RenderZPass`/
  `RenderShadow`. We do one forward color pass. Multi-pass + z-prepass is the prerequisite for shadows,
  decals, and correct transparency ordering (particles/water).

### J. ECS behaviour graph — ❌ not started
- `STAT`/`SWIT`/`CHDR`/`CEXE`/`NODE` (`ECS_PlacementParse` 0x4cf340) = destruction/variant **state
  machine** (e.g. the villa's `CollapseState`). A runtime gameplay feature (buildings collapse), not a
  render filter — do NOT gate draw groups on it.

## Suggested order (visual impact ÷ effort)
1. **Dynamic point lights from `LightObject`** — the interior reads flat/dark without them; high impact,
   moderate effort (parse the ECS component, forward-accumulate N nearest lights). Add specular (slot 1)
   alongside — cheap.
2. **Multi-pass architecture (z-prepass + a color pass that consumes the light list)** — enables 3-5.
3. **Particles/FX** — largest system; start with `fxdict` + a single billboard emitter honouring
   `ObjectState.StartEmitter`, then forces/gradients/ribbons.
4. **Shadows** (blob first, then shadow-buffer).
5. **Sky/atmosphere + HDR/bloom post**.
6. **Decals**, **prop anim clips**, **LOD imposters**, then the **ECS destruction** state machine.

Everything here is "implement per their description"; this file is the checklist. Update status as we go.
