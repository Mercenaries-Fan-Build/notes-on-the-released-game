# Scoreboard #5 — sky / atmosphere / HDR post: PC code map

**Scope:** the PC-side sky+atmosphere+cloud rendering and the HDR + post-process chain in
`Mercenaries2.exe` (unpacked image, base 0x400000). Reversed to bind the Xbox PDB names
([rendering-shaders.md](../mercs2-pdb-analysis/rendering-shaders.md) §post-process) to PC addresses.
Companion JSON `docs/data/sky_decal_water_code_map.json`; the **data model** was already reversed in
`mercs2_formats::atmosphere` + `mercs2_engine::post` — this doc is the engine C that implements it.

## 0. Boundary

Setup (shader registration, RT creation, the `Graphics.Atmosphere.*` Lua setters, the tunable KVP
store, the atmosphere state struct) is statically recovered = high/med confidence. The per-frame
**sky/sun draw** and the **post-chain dispatch** reach through the render-view vtable / FNV
shader-handle resolve (the retail stripped-marker pattern) → recorded with the vtable/handle site and
marked confirm-live. Source paths `PgCloudsWin32.cpp` (@0xbab460) survive and pin the cloud code.

## 1. Atmosphere state + scatter model

Analytic Rayleigh/Mie sky driven by a **live atmosphere params struct** at
`*(int*)(PTR_PTR_00e7adfc + 0x104)` (`PTR_PTR_00e7adfc` = the atmosphere manager singleton). Setters
write floats immediately or stage into a mirror block `DAT_017ba9d0..017baa94` for interpolation.
Confirmed field offsets (match `atmosphere.rs::ScatterParams` exactly):

| field | struct off | staging global |
|---|---|---|
| Time / TimeSpeed | +0x10 / +0x14 | 017ba9d0 / 017ba9d4 |
| LightIntensity | +0xe0 | 017baa60 |
| LightModifier / Turbinity | +0x124 | 017baa84 |
| HenyeyGreensteinConst (Mie g) | +0x120 | 017baa80 |
| InscatteringMultiplier | +0x128 | 017baa88 |
| ExtinctionMultiplier | +0x12c | 017baa8c |
| BetaRayMultiplier (Rayleigh) | +0x130 | 017baa90 |
| BetaMieMultiplier (Mie) | +0x134 | 017baa94 |
| AmbientColor / AmbientCube(6×) / RimColor | — | 017ba9f0 / 017baa08.. / 017baa70 |

`"AtmosphereBase 160 32"` (@0xbad69a) is the reflection class (size 160, align 32). **Correction to
expectation:** its fields (ScatterHGg, Scatter*Multiplier, AtmosphereLimit/Force, HazeLimit/Force,
Gradient0..2_*, Water0..2_*) are consumed as a **data table**, not by a discrete ~159 B registrar —
so they don't tokenize into any decompiled body.

## 2. Graphics.Atmosphere Lua setters → C impls (recovered)

Binding table **@0xb9a570** (8-byte `{name_ptr, fn_ptr}`; `0xffffffff` = namespace-open,
`0xfffffffe` = close; nests `Bloom` and `MotionBlur` sub-namespaces). Complete map:

| API | PC addr | API | PC addr |
|---|---|---|---|
| Begin / End | 0x5b16d0 / 0x5b16f0 | SetTime / SetTimeSpeed | 0x5b1750 / 0x5b17c0 |
| SetLightIntensity / SetLightModifier | 0x5b1830 / 0x5b18a0 | SetLightAngle | 0x5b1970 |
| SetAmbientColor / SetAmbientCube | 0x5b19e0 / 0x5b1a80 | SetRimColor / SetTurbinity | 0x5b1b20 / 0x5b1b70 |
| SetInscatteringMultiplier | 0x5b1be0 | SetExtinctionMultiplier | 0x5b1c50 |
| SetBetaRayMultiplier | 0x5b1cc0 | SetBetaMieMultiplier | 0x5b1d30 |
| SetHenyeyGreensteinConst | 0x5b1da0 | SetAtmosphere / SetHaze | 0x5b1e10 / 0x5b1ed0 |
| SetWindDirection | 0x5b1f90 | SetSky | 0x6d5640 (other TU → confirm-live) |
| SetValue / SetColorValue | 0x5b1200 / 0x5b1430 | GetValue / GetColorValue / SetIntValue | 0x5b1150 / 0x5b12a0 / 0x5b15f0 |
| Bloom.SetBlurRadius / SetThreshold / SetMultiplier / SetAmount | 0x5b2090 / 0x5b20e0 / 0x5b2130 / 0x5b2180 | Bloom.SetTargetLuminance / SetAdaptiveLuminancePercent / …Scale | 0x5b21f0 / 0x5b2260 / 0x5b22d0 |

**Named-value apply `FUN_004eee90`**: FNV-1a (via `Hash_String FUN_00824270`) of the key → binary
search → writes one of ~80 global floats in `DAT_00df5b74..DAT_00df66e0` — the `fBloom*`/`Scatter*`
KVP store that `SetValue`/`SetColorValue` address by name (the `fBloom*` literal names live in this
reflection schema, not inline).

## 3. Clouds (PgCloudsWin32.cpp)

PgClouds object, vtable @0xbab5b4 (7 slots): `[0]dtor [1]FUN_0047dab0 [2]FUN_0047efc0 [3]FUN_0047de00
[4]CreateRT=FUN_0047d710 [5]ReleaseRT=FUN_0047da10 [6]Render=FUN_0047e7f0`.
- **`FUN_0047d710`** creates two RTs: **mCloudSurfRT** 512×512 A8R8G8B8 (tex `+0x6b4`/surf `+0x6b8`),
  **mCloudOutRT** half-res R32F (tex `+0x6c0`/surf `+0x6c4`) — the cloud density/composite target.
- **`FUN_0047e7f0`** (= PgFxCloud::BeginRender/UpdateRender, Xbox 0x14f20/0x14f08): builds cloud
  constant buffers at `DAT_00ff46c8` and **reads the live atmosphere struct** (`+0x20/+0x28/+0x40/
  +0x70/+0x7c` = colors/sun/scatter) — the atmosphere→cloud composite. Init `FUN_0047d430`; quad
  sub-object `FUN_0047c980` (billboards cQuad0..5); subsystem init `FUN_0047f2f0`.

## 4. Sky/sun shader registration + draw

PgAtmosphereVP, PgCloudRenderVP1/FP1/VP2/FP2, PgCloudGenFP1, PgSkyVP, PgSunVP, PgSkyFP,
PgSkyReflectFP, PgSunFP all register in the shared registry **`FUN_0084f130`** via
`FUN_0085ac90(name, name.sho, 0)` (consecutive block, dump lines 640927–640946); resolve by FNV
handle at draw. The discrete sky/sun draw (binds PgSkyVP/FP + PgSunVP/FP at the far plane) is
handle-resolved/vtable-gated → confirm-live.

## 5. HDR + post-process chain

All post runs as a fullscreen-quad command list built by the driver **`FUN_0074f8d0`** (one quad per
stage via emitter `FUN_00853710`). Scene renders into **MainColor HDR RT, D3DFMT 0x71 =
A16B16G16R16F**. Stage order:

1. **Bloom blur pyramid** (4 levels /2../16): downsample(bright) → separable gaussian blur H → blur V
   (ping-pong `+0x22a0/+0x22b0`).
2. **HDR flare** sun-occlusion query (`FUN_0074edd0`, D3DXVec4Transform sun→screen).
3. **Downsample-to-luminance** 64×64 (mat `+0x1720`).
4. **Log-luminance chain** 16→4→1 (mats `+0x18b0/+0x1bd0`).
5. **Adaptive-luminance feedback** (mat `+0x1d60`, dual-tex: current `+0x22e4` + prev `+0x22c4`,
   exp-average weighted by frame dt `DAT_01175a90`).
6. **Bloom combine** half-res (mat `+0x2080`).
7. **Tonemap + composite** full-res (mat `+0x1ef0`, vtable `PTR_PTR_0127c6b0`; main color + bloom +
   adaptive-lum + atmosphere/scatter consts; `__libm_sse2_pow` gamma) → swapchain. Then luminance
   history swap + 1×1 CPU readback (`FUN_0074eb60`).

**RT creators** (renderer singleton `PTR_PTR_00dfc2fc`): `FUN_00749f70` (MainColor HDR 0x71,
FrontColor, BackDepth, DepthBuffer, half-res Downsample) + `FUN_0074dc90` (BlurH/V[4] pyramid,
BloomCombiner, DownSample[3], Luminance, AdaptiveLuminance, **PrevAdaptiveLumTex/Surf + 1×1
g_pAdaptiveDest `DAT_0117629c`** = the exposure history); release `FUN_0074e920`.

**Adaptive-exposure loop** (steps 3-5 + `FUN_0074eb60` StretchRect history swap + 1×1 CPU readback):
exactly what `atmosphere.rs::exposure()` approximates (`fBloomAdaptiveLuminanceScale/Percent`,
`fBloomTargetLuminance`).

## 6. ScreenEffect layer (rain / underwater / shimmer)

The 7 ScreenEffect slots (Speed/Density/DirX/DirY/Texture/Color/Type, default `SCREEN_EFFECT_ADDITIVE`)
live in the AtmosphereBase reflection class, parsed by **`FUN_00663890`**. Applied by the
screen-space renderable **`FUN_0046d290`** (builds a 64×64 procedural "ShimmerTex_%X" distortion map,
vtable `PTR_FUN_00baae74`, refs WaterGradiant/underwater), owned/emitted by `FUN_00466670` in the
PgFX path — i.e. **atmosphere/Lua-driven, not a fixed post pass**.

## 7. Two firm PC-vs-Xbox differences

- **Motion blur / velocity is absent on PC.** No `PgVelocityFP`/`PgMotionBlurFP` strings exist in the
  PC image (only the `MotionBlur` ini flag → `DAT_00dfc363`); those shaders are Xbox-only.
- `PgAntiAliasingFP` is registered but has no dedicated AA quad in `FUN_0074f8d0` — likely folded into
  the composite, unconfirmed.

## 8. Confirm-live inventory

- `SetSky` (0x6d5640) and `Begin` (0x5b16d0) bodies are in a separate TU / SecuROM island.
- The discrete sky/sun draw + the final cloud-composite blend site (samples mCloudOutRT back) —
  handle-resolved; break on the resolved shader handle.
- The post-material shader→slot resolve (which fn binds PgToneMappingFP/etc. into `+0x1ef0` etc.) sits
  in the `FUN_007492d0` ctor chain, not pinned to one function.
- `FUN_0074f8d0` / `FUN_0074eb60` have `callers=[]` (per-frame vtable dispatch) — the dispatch edge.

The Rust `mercs2_engine` sky+HDR path (scoreboard 🟡) is a faithful approximation; this map gives the
exact scatter field offsets, the setter→C bindings, the cloud R32F composite, and the 7-stage post
order to match against the original.
