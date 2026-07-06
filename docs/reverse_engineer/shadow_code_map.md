# Mercenaries 2 — shadow subsystem: PC code map

**Scope:** the PC-side shadow rendering code in `Mercenaries2.exe`, reversed from the unpacked
SecuROM image (`output/_ghidra/securom_dump/mercs2_unpacked.exe`, base 0x400000) via a multi-agent
fan-out. Companion: [particle_fx_code_map.md](particle_fx_code_map.md). Machine-readable table:
**`docs/data/particle_fx_shadow_code_map.json`**. Binds the Xbox PDB shadow symbols
([rendering-shaders.md](../mercs2-pdb-analysis/rendering-shaders.md) §Shadows) to PC addresses.

## 0. The honest boundary

Better anchoring than the Xbox PDB gave us: the **retail PC exe carries the source path
`D:\Projects\Mercs2_PC\mercs2\LTI\Src\PgLtiRendererShadowPc.cpp`** and the shadow-surface creation
log strings, so the render-target setup is pinned exactly. But — as with PgFX — the **per-frame
shadow pass (begin/collect/draw/sample) is vtable-dispatched** and reaches the shadow-map struct
offsets only through a register-held `this`; the profiler markers (`PgScene::RenderShadowPass`,
`CollectShadowCasters`) are stripped. So RT setup, shader registry, selection taxonomy, caster
collection, and config are **high/med confidence**; the per-frame pass driver and the concrete
`Model::RenderShadow` bodies are **confirm-live (x32dbg)** with exact break points below.

## 1. Shadow render targets (`FUN_00755d90`, PgLtiRendererShadowPc.cpp)

The **sole** function referencing the .cpp path string (`0xbd61f4`). It reads adapter caps from the
RenderSystem singleton `DAT_01176288` and calls the D3D9 device (renderer `this+0x2d28`) to build a
**1024×4096** shadow-map atlas:

| Surface | renderer slot | device method | format |
|---|---|---|---|
| `_ShadowMapCombined` (RT) | +0x4404 | CreateRenderTarget (vtbl idx 28, +0x70) | 0x17 ARGB8888, → 0x16 RGB565 fallback |
| `_ShadowMapColorTex` | +0x43fc | CreateTexture (idx 23, +0x5c), Usage=1 RT | ARGB8888 |
| `_ShadowMapColorSurf` | +0x4400 | GetSurfaceLevel (idx 18, +0x48) | — |
| `_ShadowMapDepthTex` | +0x43f4 | CreateTexture (+0x5c), Usage=2 DS | `'DF24'` (0x34324644) fetch-4, → 0x4b D24S8 |
| `_ShadowMapDepthSurf` | +0x43f8 | GetSurfaceLevel / CreateDepthStencilSurface (idx 29, +0x74) | D24S8 |

- **RGB565 fallback:** if no adapter mode has format 0x17 + caps bit 0x800 → logs "Shadow Color
  Format changed to ARGB8888 (RGB565 wasn't supported!)" and uses 0x16.
- **Depth path gated on `DAT_01176288+0x5e8`:** 0 → readable `DF24` depth texture (with D24S8
  depth-stencil-surface fallback); nonzero → 0x4b depth texture directly.
- **Atlas layout:** rects at renderer +0x4408..+0x4444 split the combined RT into **four
  vertically-stacked 1024×1024 slices** (y-tops 0 / 0x400 / 0x800 / 0xc00) — the 4 shadow
  cascades/splits. (Whether these are CSM cascades or per-light-view splits is confirm-live: read the
  pass's viewport-set.)

## 2. RT lifecycle & the vtable caller

`FUN_00755d90` has `callers=[]` because it is **vtable slot 18 (+0x48)** of the `PgLtiRenderer(Win32)`
vtable `0x00bd3940` (the pointer `0x00755d90` occurs exactly once in the image, at VA `0x00bd3988` =
vtable+0x48). The proven creation flow:

```
RenderSystem::ApplySettings  FUN_0074c7ac   (device create/reset)
  → renderer ctor            FUN_007492d0
    → bind device (+0x2d28)  FUN_00749060
      → CreateRenderTargets  FUN_00749f70   (PgLtiRendererPc.cpp — main color/depth/downsample RTs)
        → last stmt (**(this+0x48))()  =  FUN_00755d90   (the shadow atlas)
```

Teardown mirror: `OnDeviceLost FUN_0074cfa0 → ReleaseRenderTargets FUN_0074a640` (clears the same
+0x43f4..+0x4404 slots). Reset recreate: `FUN_0074cec0 → FUN_00754e90`. The owning object is the
**PgLtiRenderer singleton** (global `PTR_PTR_00dfc2fc`, vtable `0x00bd3940`, size ≥0x5ec: device
+0x2d28, blob-shadow VBs +0x3e90..+0x3eb0, shadow slots +0x43f4..+0x4444). `DAT_01176288` is the
separate **RenderSystem / Dx9_State** config singleton (+0x5bc device, +0x5e0 adapter-mode list,
+0x5e4 feature bits, +0x5e8 depth-format flag).

## 3. Shadow shaders — caster VP vs receiver FP

All registered in the shared registry `FUN_0084f130` (name → FNV-1a → u16 handle; see the FX map §4).

**Casters** (render mesh depth into the shadow atlas):

| Mesh/material condition | caster VP | +suffix variants |
|---|---|---|
| Rigid static mesh | `PgMeshShadowVP` | Tex / Morph / MorphTex / AmbientWind / TexAmbientWind |
| Full multi-bone skin | `PgSkinShadowVP` | Tex / Morph / MorphTex / AmbientWind / TexAmbientWind |
| Single-matrix (1-bone) skin | `PgSkin1ShadowVP` | Tex / Morph / MorphTex / AmbientWind / TexAmbientWind |
| LOD imposter ("tiny" far mesh) | `PgMeshTinyShadowVP` | Tex; **_Ruin / _RuinTex** |
| Road decal strip | `PgRoadShadowVP` | — |
| Vegetation billboard tree | `PgBillboardTreeShadowVP` | *(data-table bound, not in registry)* |
| Terrain heightfield | `PgLtiTerrainShadowVP` | — |
| Cheap blob fallback | `PgBlobShadowVP` | — |

**Receivers** (main pass, sample the shadow map): `PgShadowFP` (base) / `PgShadowFP_Z` (depth-only) /
`PgShadowTextureAlphaFP` (alpha-tested foliage/fence) / `_ZA` (depth+alpha) / `_ZABB` (depth+alpha+
billboard) / `PgBlobShadowFP`.

**Selection is name-hash indirected, not offset-dispatched:** a material/mesh resolves the right VP
name → u16 at load and caches it; draw code binds the cached u16. This is why grep finds no
render-side references to the VP name strings.

- **AmbientWind quality gate (verified):** every `*AmbientWind*` VP is registered under
  `if ((DAT_01176288+0x5e4 >> 2) & 1)`. Bit clear → the AmbientWind name aliases the plain `.sho`
  (e.g. `PgMeshAmbientWindShadowVP → PgMeshShadowVP.sho`); bit set → the real `…AmbientWind.sho`.
  So `DAT_01176288+0x5e4` bit 2 = the ambient-wind vegetation quality toggle.
- **FP suffixes:** `_Z` depth-only, `_ZA` depth+alpha-test, `_ZABB` depth+alpha+billboard.
- **`_Ruin` destruction linkage:** the `_Ruin`/`_RuinTex` variants exist only in the Tiny (LOD
  imposter) family — when an entity's destruction/vz_state overlay marks it ruined, its far imposter
  casts with `PgMeshTinyShadowVP_Ruin` (ties to the destruction COMP + vz_state overlay from the
  world-LOD/destruction scope).

## 4. Caster collection, distance/LOD, bounds

- **`FUN_00466d40`** = scene render-list builder / best `CollectShadowCasters` candidate. Holds the
  render-time shadow gate `if (DAT_0117507f==0 && DAT_00dfc360!=0)` (EnableShadows), walks a phase-4
  renderable iterator (`thunk_FUN_024bbd20(4,…)`), and per-caster runs distance-classify + frustum
  cull before enqueueing shadow packets into the `DAT_018c5620` command arrays.
- **`FUN_00858150`** = per-caster distance/LOD classifier (`D3DXVec3TransformCoord` + magnitude → 0/1/2):
  2 = full in-range (skip frustum), 1 = partial (run cull), 0 = cull. **This is the shadow LOD /
  base-distance decision point** (the `SetShadowBaseDistance` threshold it compares against is a float
  near `DAT_01176288`, not yet bound — confirm-live).
- **`FUN_00857c00`** = frustum/plane-cull test = candidate `ShadowBounds` visibility test.

## 5. BlobShadow (cheap fallback)

- **`FUN_00642fb0`** = `BlobShadow` ECS reflection registrar (component 0x40349618, stride 0x24,
  CopyFromStream `0xbc0e10`, descriptor @0x017be208). The separate `"BlobShadow 1280"` alloc-tag is
  the runtime blob manager's 1280-B pool.
- Blob geometry: the front/back vertex buffers `BlobShadowFrontVB`/`BackVB` live at renderer
  +0x3e90..+0x3eb0; shaders `PgBlobShadowVP`/`FP` registered at `FUN_0084f130` lines 912-913.
- **Runtime blob-projection render is not statically reachable** — `BlobShadowFrontVB`, `ShadowK`
  (the darkness constant), `"BlobShadow 1280"` appear as *no* code token in the decomp; they reach
  code via the reflection registry / shader-hash tables / vtables. **Confirm-live:** break on the
  `PgBlobShadowVP/FP` shader-set or the blob VB creation, then walk the caller.

## 6. Configuration / cvars / quality

- **`FUN_00753280`** = `Mercs2.ini [Render]` loader — the authoritative live-global map:
  `EnableShadows → DAT_00dfc360` (def 1), `ParticleDetailLevel → DAT_00dfc362` (0–2, def 2),
  `ModelDetailLevel → DAT_00dfc361`, `ShaderLevel → DAT_00dfc345/346`, `ViewDistance → DAT_00dfc348`,
  `MotionBlur → DAT_00dfc363`.
- **`FUN_005c37e0`** = advanced-video menu — pending toggles `advvideoEnableShadowsVar → DAT_00df6740`,
  `advvideoTreeShadowsVar → DAT_00df6741`, `advvideoModelShadowsVar → DAT_00df6742` (each
  `= stricmp(arg,"On")==0`).
- **`FUN_005c1240`** = apply/commit — widget code `0x29` copies pending `DAT_00df6740` → live
  `DAT_00dfc360`. Flow: **menu toggle → pending `df674x` → live `dfc36x` → render gate in `FUN_00466d40`.**

## 7. Real-vs-Blob selection (the shadow LOD decision)

1. **Global gate:** `DAT_0117507f==0 && DAT_00dfc360(EnableShadows)!=0` — else no depth-map shadow
   work at all.
2. **Per-caster:** `FUN_00858150` distance-classifies (0/1/2) + `FUN_00857c00` frustum-culls; the
   class decides whether the caster renders into the depth atlas. The blob path is the cheap fallback
   for casters that skip/fail the depth path. Exact numeric threshold (= `SetShadowBaseDistance`
   storage) is confirm-live.

## 8. Confirm-live inventory (x32dbg break points)

| Target (Xbox PDB name) | how to bind on PC |
|---|---|
| Per-frame shadow-pass driver (`PgScene::RenderShadowPass`) | HW read/write BP on `renderer+0x4400`/`+0x4404`; capture the `this`/vtable that binds the atlas as RT |
| `Model::RenderShadow` / `TerrainMeshRenderable::RenderShadow` (concrete bodies) | BP inside `FUN_00755d90` or on `SetRenderTarget(shadow)`, walk the renderable iteration, record each renderable's RenderShadow vtable slot target |
| `CollectShadowCasters` (confirm `FUN_00466d40`) | BP the phase-4 iterator; verify it enqueues shadow packets |
| BlobShadow projection + `ShadowK` | BP the `PgBlobShadowVP/FP` set or blob VB build |
| `SetShadowBaseDistance` storage | BP the float `FUN_00858150` compares distance against |
| `DAT_01176288+0x5e8` depth-format branch | observe which GPUs take DF24 vs D24S8 |

## 9. Faithful-reimpl note

The Rust engine already implements a directional depth shadow map with PCF (`mercs2_engine::scene`
shadow pass) — a modern single-cascade take. This map shows the original is a **4-tile atlas**
(cascades/splits) with per-mesh-type caster VPs, an alpha-tested receiver path for foliage, a
distance-LOD gate, and a BlobShadow cheap fallback — the gap between the current single-cascade PCF
and faithful behaviour, per [rendering_fx_lighting_gap.md](../modernization/rendering_fx_lighting_gap.md) §D.
