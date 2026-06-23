# Rendering & Shaders

Scope: the Pangea rendering pipeline and shader system — frame submission, scene passes (z/color/shadow/reflection), materials, textures, lighting, shadows, post-process (bloom/atmosphere/clouds/water), decals, particles/FX, and the Xenon shader compiler.

Provenance: all symbols/strings below are recovered from the Jul 11 2008 preview ("Profile") devkit build of `Mercs2_Xenon_P.exe` (PowerPC, Xbox 360), decompressed PE at `output/jul08_prototype/mercs2_xenon_p.pe_full.bin`. This is symbol/string evidence from the binary and from `output/jul08_prototype/shaders_bin_updb_paths.txt`, NOT a real `.pdb`. Pandemic's engine is "Pangea" (`Pg*` classes). Offsets are cited as they appear in `output/jul08_prototype/inventory/rendering-shaders.txt`.

## Overview

This subsystem is the Pangea renderer. The frame driver is `PgSysRender` / `PgRenderer`, which exposes the per-frame stages `PgSysRender::Update` (0x0014cb4), `PgSysRender::RenderFrame` (0x0014c7c), `PgSysRender::SubmitFrame` (0x0014c98) and `PgSysRender::EndFrame` (0x0014c64), with the concrete GPU submit in `PgRenderer::SubmitToGPU` (0x00c51e0) and `PgRenderer::ProcessRender` (0x00c5228). The renderer is split by platform: `PgRendererXenon::EndFrame` (0x00c1cb0) and `PgRendererWin32::EndFrame` (0x00c4edc) / `PgRendererWin32::BeginImmediate` (0x00c5278) / `PgRendererWin32::EndImmediate` (0x00c5298) — a cross-platform renderer abstraction with Xenon and Win32 backends.

Scene-level pass orchestration lives in `PgScene`: `PgScene::RenderColor` (0x0014b7c), `PgScene::RenderShadowPass` (0x0014b2c), `PgScene::RenderReflection` (0x0014afc) plus the unprefixed pass markers `RenderColorPass` (0x0014ab0), `wRenderZPass` (0x0014ac3), `RenderShadowPass` (0x0014b18) and `CollectShadowCasters` (0x0014ba8). The runtime emits per-frame profiling/debug markers such as `PgScene::Render-zpass`, `PgScene::Render-FX`, `PgScene::Render3DParticles-FX`, `PgScene::Render-shadow-collect` and the format string `PgScene::Render vpid: %i` (per-viewport scene render).

Drawable objects are "Renderables": `AddRenderable` (0x002186c), `RenderablePut` (0x0021714), `RenderableUpdate_End` (0x0014d48), and the lifecycle hooks `PgRenderableInitializer::Activate` / `Deactivate` / `CanActivate` (0x0041138 / 0x0041114 / 0x00410ec). Concrete renderables include `Model::Render`/`RenderZPass`/`RenderShadow` (0x0014ef8 / 0x0014ec0 / 0x0014ed4) and `TerrainMeshRenderable::Render`/`RenderZPass`/`RenderShadow` (0x00171e4 / 0x00171c0 / 0x0017194).

Shaders are referenced by name as compiled-shader objects with the `.sho` suffix (e.g. `PgBloomCombinerFP.sho` 0x0015314); the matching debug databases are the 344 `.updb` paths under `d:\projects\ReleaseLine\Mercs2\Pangea\Shaders\Xbox 360\` in `shaders_bin_updb_paths.txt`. The `FP`/`VP` suffixes are pixel (Fragment Program) and vertex programs (inferred from the name pairs). The on-target shader compiler is the Xbox SSM micro-code compiler (`SSM*`, `Compile*` symbols), with a runtime `ReloadShaders` (0x0027034) entry point.

## Source files

From `mercs2_xenon_p.source_paths.txt`, the files belonging to this subsystem are the Xbox 360 graphics shader micro-code compiler / SSM (state-string-manager) toolchain (verbatim):

```
e:\xenon\mar08\core\private\xtl\graphics\xgraphics\ucode\compiler\asm\asm.cpp
e:\xenon\mar08\core\private\xtl\graphics\xgraphics\ucode\compiler\compiler.cpp
e:\xenon\mar08\core\private\xtl\graphics\xgraphics\ucode\compiler\ir\cfg.cpp
e:\xenon\mar08\core\private\xtl\graphics\xgraphics\ucode\compiler\ir\irinst.cpp
e:\xenon\mar08\core\private\xtl\graphics\xgraphics\ucode\compiler\ir\linkageinfo.cpp
e:\xenon\mar08\core\private\xtl\graphics\xgraphics\ucode\compiler\ir\vreginfo.cpp
e:\xenon\mar08\core\private\xtl\graphics\xgraphics\ucode\ssm\inc\Internal_AS.h
e:\xenon\mar08\core\private\xtl\graphics\xgraphics\ucode\ssm\statecompiler\compiledshader.cpp
e:\xenon\mar08\core\private\xtl\graphics\xgraphics\ucode\ssm\statecompiler\compilertossm.cpp
e:\xenon\mar08\core\private\xtl\graphics\xgraphics\ucode\ssm\util\linkedlist.cpp
e:\xenon\mar08\core\private\xtl\graphics\xgraphics\ucode\ssm\util\mempriv.h
```

Note: these are Microsoft Xbox 360 XDK files (`e:\xenon\mar08\...`), not Pandemic's own source tree (`d:\projects\ReleaseLine\Mercs2\Pangea\...`). The game-side Pangea render `.cpp` files are NOT present in `source_paths.txt` (it only lists 48 paths, weighted toward Lua/Pal/AI/sound). Only the XDK shader-compiler/SSM paths are recoverable here for this system.

## Key classes

`mercs2_xenon_p.rtti_classes.txt` contains 324 RTTI names, the overwhelming majority of which are Havok (`hk*`/`hkp*`/`hka*`) classes (5 are non-Havok utility/anonymous-namespace classes: `NearestHitCollector`, `RotateNormalHitCollector`, `PackfileNameFromAddress`, `StringPool` (`@?A0x26f1bb20`), `ValidatedClassNameRegistry`). None of the rendering-shaders `Pg*` classes (`PgRenderer`, `PgScene`, `PgSysRender`, `PgModelRenderable`, etc.) appear in the RTTI table — this subsystem's C++ classes are not RTTI-emitted in this build, so no demangled `Pg*` render class names are available from the RTTI evidence. The class names listed throughout this doc come from `.rdata` symbol strings (function/label names), not from RTTI type descriptors.

## Symbols by area

### Frame driver & platform backends

| Symbol | Offset | Section |
|---|---|---|
| `PgSysRender::Update` | 0x0014cb4 | .rdata |
| `PgSysRender::RenderFrame` | 0x0014c7c | .rdata |
| `PgSysRender::SubmitFrame` | 0x0014c98 | .rdata |
| `PgSysRender::EndFrame` | 0x0014c64 | .rdata |
| `PgRenderer::EndFrame` | 0x00c51bc | .rdata |
| `PgRenderer::SubmitToGPU` | 0x00c51e0 | .rdata |
| `PgRenderer::ProcessRender` | 0x00c5228 | .rdata |
| `PgRendererXenon::EndFrame` | 0x00c1cb0 | .rdata |
| `PgRendererWin32::EndFrame` | 0x00c4edc | .rdata |
| `PgRendererWin32::BeginImmediate` | 0x00c5278 | .rdata |
| `PgRendererWin32::EndImmediate` | 0x00c5298 | .rdata |
| `RenderFrameJob` | 0x0014fe8 | .rdata |
| `RenderSubmitJob` | 0x0014ff8 | .rdata |
| `RenderUpdateJob` | 0x0015008 | .rdata |
| `RenderWait` | 0x0014fd0 | .rdata |

The `Render*Job` triplet plus `RenderWait` indicate the render frame runs as scheduled jobs, tying into the `pimp_job`/`PIMP` job system seen elsewhere in `source_paths.txt`.

### Scene passes & shadow collection

| Symbol | Offset | Section |
|---|---|---|
| `PgScene::RenderColor` | 0x0014b7c | .rdata |
| `PgScene::RenderShadowPass` | 0x0014b2c | .rdata |
| `PgScene::RenderReflection` | 0x0014afc | .rdata |
| `RenderColorPass` | 0x0014ab0 | .rdata |
| `wRenderZPass` | 0x0014ac3 | .rdata |
| `RenderShadowPass` | 0x0014b18 | .rdata |
| `CollectShadowCasters` | 0x0014ba8 | .rdata |
| `RenderColor` | 0x0014eb4 | .rdata |
| `ColorCopySceneRender` | 0x00c1c2c | .rdata |
| `SetRenderTargets` | 0x00eb830 | .rdata |
| `Render::Before` / `Render::Scene` / `Render::After` | 0x00c51f8 / 0x00c5208 / 0x00c5218 | .rdata |

A multi-pass forward/deferred-ish pipeline: z-pass, color pass, shadow pass (with a separate `CollectShadowCasters` gather), and a reflection pass. `SetRenderTargets` is the GPU render-target bind.

### Renderables (models, terrain, junk)

| Symbol | Offset | Section |
|---|---|---|
| `AddRenderable` | 0x002186c | .rdata |
| `RenderablePut` | 0x0021714 | .rdata |
| `RenderableUpdate_End` | 0x0014d48 | .rdata |
| `PgRenderableInitializer::Activate` | 0x0041138 | .rdata |
| `PgRenderableInitializer::Deactivate` | 0x0041114 | .rdata |
| `PgRenderableInitializer::CanActivate` | 0x00410ec | .rdata |
| `Model::Render` | 0x0014ef8 | .rdata |
| `Model::RenderZPass` | 0x0014ec0 | .rdata |
| `Model::RenderShadow` | 0x0014ed4 | .rdata |
| `PgModelRenderable::CreateDecal` | 0x0014f74 | .rdata |
| `TerrainMeshRenderable::Render` | 0x00171e4 | .rdata |
| `TerrainMeshRenderable::RenderZPass` | 0x00171c0 | .rdata |
| `TerrainMeshRenderable::RenderShadow` | 0x001719c | .rdata |
| `PgJunk::Render` | 0x0030878 | .rdata |
| `RenderFadingTrees` | 0x0016a2c | .rdata |

Each renderable type implements the same `Render` / `RenderZPass` / `RenderShadow` trio — a virtual interface shared by Model and TerrainMesh. `RenderFadingTrees` pairs with the `PgBillboardTree*` shaders below.

### Materials & textures

| Symbol | Offset | Section |
|---|---|---|
| `MaterialKeyTable` | 0x00219a8 | .rdata |
| `PgMaterialTable` | 0x0b8a47c | .data |
| `PgMaterialKeyAsset` | 0x0b8a49c | .data |
| `MaterialController` | 0x00427f8 | .rdata |
| `MaterialControllerRuntime` | 0x003220c | .rdata |
| `MaterialCtrlTankTread` | 0x00322ec | .rdata |
| `PlayMaterialAnimation` / `StopMaterialAnimation` | 0x0029bbc / 0x0029ba4 | .rdata |
| `numMaterials` / `subMaterials` | 0x0063c7c / 0x005abc8 | .rdata |
| `MaterialIds` / `MaterialMapping` / `MaterialNode` | 0x00ff7a4 / 0x0032548 / 0x003fd00 | .rdata |
| `OcclusionMaterial` / `ObjectMaterial` / `ControlledMaterial` | 0x00c5264 / 0x0031584 / 0x003b56c | .rdata |
| `PgTexture` | 0x0b8a4ec | .data |
| `CreateTexture` / `LoadTexture` / `FreeOldTexture` | 0x001df4c / 0x0027750 / 0x001df3c | .rdata |
| `ReadTextureData` / `ReadTextureBody` | 0x001df5c / 0x001df6c | .rdata |
| `SetTextureData` / `SetVertexData` | 0x001dfb0 / 0x001dfd0 | .rdata |
| `SwapMipTextures` | 0x00c5194 | .rdata |
| `DumpTextures` | 0x0028b78 | .rdata |
| `externalTextures` / `inplaceTextures` | 0x005a83c / 0x005a850 | .rdata |
| `numTextureChannels` / `TextureType` / `TextureModel` | 0x005a9b8 / 0x005ac2c / 0x003ba04 | .rdata |
| `UnnormalizedTextureCoords` / `UseTextureCache` | 0x00d097c / 0x00d09e0 | .rdata |
| `getCompTexLOD3D` | 0x00d0e64 | .rdata |
| `MaterialIndexStridingType` / `VertexIdEncoding` | 0x005a2e4 / 0x0059e90 | .rdata |

`MaterialKeyTable`/`PgMaterialKeyAsset` plus `numMaterials`/`subMaterials`/`MaterialIds` describe the multi-sub-material model layout. The `Read*`/`Create*`/`FreeOld*`/`SwapMipTextures` set is the texture streaming/lifecycle path; `externalTextures` vs `inplaceTextures` distinguishes streamed vs embedded texture data. This overlaps the project's MTRL/texture WAD work (see Cross-references).

### Decals

| Symbol | Offset | Section |
|---|---|---|
| `PgDecalTable` | 0x0b8a48c | .data |
| `CreateDecals` / `RecreateDecals` | 0x0021778 / 0x001e40c | .rdata |
| `DecalJob` / `DecalsUpdate` / `DecalUnlock` | 0x0016620 / 0x0016610 / 0x0016604 | .rdata |
| `EnableSuperDecal` / `DisableDecal` / `DisableDecals` | 0x001e41c / 0x003cbc4 / 0x003171c | .rdata |
| `DamageShadow` / `ProcessDamageShadowCast` | 0x0021400 / 0x0021410 | .rdata |
| `PgDecalVP` / `PgDecalVP.sho` | 0x0016714 / 0x0016720 | .rdata |
| `PgDecal2FP` / `PgDecal2FP.sho` | 0x0016708 / 0x00166f8 | .rdata |
| `PgDecal2FP_pl` / `PgDecal2FP_sl` / `PgDecal2FP_pl_sl` (+ `.sho`) | 0x00166d4 / 0x00166b0 / 0x0016684 | .rdata |

Decals run as a job (`DecalJob`) with a "super decal" variant. The `_pl` / `_sl` / `_pl_sl` shader suffixes recur across many Pangea pixel shaders, most likely point-light / shadow-/spot-light feature permutations.

### Particles & FX (PgFX)

| Symbol | Offset | Section |
|---|---|---|
| `PgFX::SceneRender` / `PgFX::UpdateRender` / `PgFX::Render3DParticles` | 0x0014d78 / 0x0016260 / 0x0014d60 | .rdata |
| `EmitParticles` / `CountParticles` | 0x0016414 / 0x0016424 | .rdata |
| `FxSpuParticleGen` / `FxPreSimulate` / `FxVisibility` / `FxShaderTask` | 0x00162c4 / 0x00162f4 / 0x00162e4 / 0x00163bc | .rdata |
| `ParticleEmitter` / `ParticleKey` / `ParticleMass` | 0x0031564 / 0x0032564 / 0x003b5b4 | .rdata |
| `ParticleKeyEnum` / `MaterialEmitter` / `MaterialTypeEnum` | 0x003a91c / 0x0032628 / 0x003aaa0 | .rdata |
| `PgFXFP`/`PgFXVP`/`PgFXFPR`/`PgFXVPR` shaders | (`.sho` strings) | — |

`Fx*` task names (SPU/PreSimulate/Visibility/ShaderTask) indicate a job-parallel particle pipeline; `EmitParticles`/`CountParticles` and the `ParticlesPer*` tunables (Notable strings) drive emission.

### FaceFX (facial animation FX)

A distinct cluster of `Fx*` symbols is the FaceFX runtime (third-party facial-animation middleware), separate from PgFX particles:

| Symbol | Offset | Section |
|---|---|---|
| `FxActor` / `FxActorInstance` | 0x00be668 / 0x00be724 | .rdata |
| `FxFaceGraphNode` / `FxFaceGraphNodeLink` / `FxFaceGraphNodeUserProperty` | 0x00be678 / 0x00be904 / 0x00be6bc | .rdata |
| `FxMorphTargetNode` / `FxGenericTargetNode` / `FxGenericTargetProxy` | 0x00bef3c / 0x00beec4 / 0x00bee7c | .rdata |
| `FxBone` / `FxAnim` / `FxObject` / `FxNamedObject` | 0x00be924 / 0x00be780 / 0x00be918 / 0x00be858 | .rdata |
| `Fx*LinkFn` (Null/Linear/Quadratic/Cubic/Sqrt/Negate/Inverse/OneClamp/Constant/Corrective/Custom/ClampedLinear) | 0x00be9c8 … 0x00bea88 | .rdata |

The `FxFaceGraphNode` + `Fx*LinkFn` transfer-function set is the FaceFX face-graph; included here because the names share the `Fx` prefix, but architecturally this is facial animation, not the render pipeline. Cross-reference to a characters/animation system if one exists.

### Shadows

| Symbol | Offset | Section |
|---|---|---|
| `PgShadowFP` / `PgShadowFP.sho` | 0x00c4308 / 0x00c4314 | .rdata |
| `PgShadowTextureAlphaFP` (+`.sho`) | 0x00c42d4 / 0x00c42ec | .rdata |
| `PgBlobShadowFP`/`PgBlobShadowVP` (+`.sho`) | 0x0015848 / 0x001586c | .rdata |
| `PgMeshShadowVP*` family (Tex/Morph/AmbientWind/Tiny/Ruin variants) | 0x00c4368 … 0x00c46c4 | .rdata |
| `PgSkinShadowVP*` family | 0x00c4488 … 0x00c45a4 | .rdata |
| `HPgMeshShadowVP` | 0x0016b7f | .rdata |
| `PgRoadShadowVP` (+`.sho`) | 0x00178c0 / 0x00178d0 | .rdata |
| `PgBillboardTreeShadowVP` / `_modeled` (+`.sho`) | 0x001687c / 0x0016838 | .rdata |
| `ShadowBuffer` / `ShadowBounds` / `UpdateShadowBounds` | 0x00c52ec / 0x0026bc4 / 0x0014fbc | .rdata |
| `GetShadowBaseDistance` / `SetShadowBaseDistance` | 0x0026ff8 / 0x0027010 | .rdata |
| `BlobShadow` / `ShadowK` | 0x003161c / 0x003c048 | .rdata |

Shadow rendering uses per-mesh-type shadow vertex shaders (`PgMeshShadowVP`, `PgSkinShadowVP`, `PgRoadShadowVP`, `PgBillboardTreeShadowVP`) plus a `ShadowBuffer` — a shadow-buffer / depth-shadow technique, corroborated by the `CompileWith*ShadowBuffering` compiler flags. `BlobShadow` is the cheap projected blob shadow.

### Post-process: bloom / HDR / atmosphere / clouds / water / screen FX

| Symbol | Offset | Section |
|---|---|---|
| `PgBloomCombinerFP` (+`.sho`) | 0x0015300 / 0x0015314 | .rdata |
| `PgAtmosphereVP` (+`.sho`) | 0x0015350 / 0x0015360 | .rdata |
| `Atmosphere::BeginFrame` / `SetAtmosphere` / `AtmosphereBase` | 0x0014a84 / 0x0026e1c / 0x0032638 | .rdata |
| `PgCloudGenFP1` / `PgCloudRenderFP1`/`FP2` / `PgCloudRenderVP1`/`VP2` (+`.sho`) | 0x0015c1c … 0x0015cc4 | .rdata |
| `PgFxCloud::BeginRender` / `PgFxCloud::UpdateRender` | 0x0014f20 / 0x0014f08 | .rdata |
| `CloudOut` / `CloudMass` | 0x0015c04 / 0x0015c10 | .rdata |
| `Water::Render` / `RenderReflections` / `RenderOcclusion` / `RenderWakeMap` | 0x0015f1c / 0x0015f00 / 0x0015ee8 / 0x0015ed0 | .rdata |
| `ScreenEffect0Texture` … `ScreenEffect6Texture` | 0x003c45c … 0x003c0b8 | .rdata |

The post-process `.updb` set (`shaders_bin_updb_paths.txt`) also names `PgAdaptiveLuminanceFP`, `PgExpAvgLuminanceFP`, `PgLogLuminanceFP`, `PgToneMappingFP`, `PgHDRFlareFP`, `PgDownSampleFP`/`2`/`3`, `PgBlurHFP`/`PgBlurVFP`, `PgMotionBlurFP`, `PgAntiAliasingFP`, `PgShimmerFP`, `PgRainFP`/`PgRainVP`, `PgCompositeFP`, `PgVelocityFP`, `PgMoonFP`/`PgMoonVP`, `PgSunFP`/`PgSunVP`, `PgSkyFP`/`PgSkyReflectFP`/`PgSkyVP`, `PgUnderwaterFP` — an HDR tone-mapping + bloom + atmosphere/sky/weather post chain (inferred from the shader names).

### Lighting

| Symbol | Offset | Section |
|---|---|---|
| `RenderLights` / `RenderLightBounds` | 0x0026b28 / 0x0026b14 | .rdata |
| `RtLightAnimation` / `RtLightAnimation::Update` | 0x0031bc8 / 0x0017758 | .rdata |
| `RtAmbienceUpdate` / `RtAmbienceCollect` | 0x002f270 / 0x002f284 | .rdata |
| `RtColorAnimation` / `RtAlphaAnimation` / `RtScaleAnimation` | 0x0031bdc / 0x0031c04 / 0x0031bf0 | .rdata |

### Canvas / 2D / GUI / Scaleform render

| Symbol | Offset | Section |
|---|---|---|
| `Canvas::Render` | 0x0014ee8 | .rdata |
| `GUI::Render` / `GuiMarkers::Render` / `Render::ApplyFilters` | 0x0030888 / 0x0030894 / 0x00308a8 | .rdata |
| `PgScaleformTextTextureFP` (+`.sho`) | 0x0017c04 / 0x0017c20 | .rdata |
| `ReticleTexture` / `uReticleTexture` / `MarkerTextureName` / `FactionTexture` | 0x003ebdc / 0x002e0bc / 0x003e7d0 / 0x0043a00 | .rdata |
| `SetImageTexture` / `GetImageTextureCoordinates` / `SetSpriteTexture` | 0x0028174 / 0x0028114 / 0x0027cc0 | .rdata |

The `.updb` list also includes the full Scaleform shader set (`PgScaleformCxformTexMultiplyFP`, `PgScaleformGlyphVP`, `PgScaleformSolidColorFP`, `PgScaleformStripFP`/`VP`, `PgScaleformTextTextureFP`) — Scaleform/GFx UI rendering (inferred; overlaps the project's scaleformgfx CFX notes).

### Shader micro-code compiler (Xbox SSM / ucode)

| Symbol | Offset | Section |
|---|---|---|
| `SSMCompilerData` / `SSMShaderRecycler` / `SSMPostProcessorData` | 0x00ef888 / 0x00ef8a8 / 0x00ef8c8 | .rdata |
| `SSMVertexShaderIL` / `SSMPixelShaderIL` | 0x00ef8ec / 0x00ef900 | .rdata |
| `SSMShaderRecyclingEnable` / `SSMCompilerVFetchMaxSize` | 0x00f0980 / 0x00f09b0 | .rdata |
| `SetVertexShader` / `SetPixelShader` / `SetGeometryShader` | 0x00eb894 / 0x00eb8a4 / 0x00eb880 | .rdata |
| `ReloadShaders` | 0x0027034 | .rdata |
| `D3DCOLORtoUBYTE4` | 0x00d550c | .rdata |

Plus a very large `Compile*` flag/getter family (offsets 0x00f1984–0x00f24f4), e.g. `CompileWithShadowBuffering` (0x00f19f4), `CompileWithBilinearModeShadowBuffering` (0x00f2038), `CompileWith*Fog*` (table/vertex/pixel fog), `CompileWith*PointSprite*`, `CompileWith*TexProjected{Y,Z,W}`, `CompileWithYUVConversion` + the `CompileGetYUVConstantsC00..C33` matrix, `CompileGetLodBias`/`CompileGetLodClampMin`, `CompileGetTexType`/`CompileGetTexClampMode`, `CompileGetMemExportConstant0..3`, `CompileGetBorderColor{R,G,B,A}`, `CompileGetVertexNumFetches`/`CompileGetVertexFetchMask`. These are the Xbox 360 GPU micro-code compiler's per-shader state knobs; they map to the XDK `ucode\compiler` / `ucode\ssm` source files listed above.

### Debug rendering & profiling

`Debug::Render` (0x0011854), `DebugRendering` (0x00012f8), `DebugRenderTimers` (0x00132d4), `RenderTimers` (0x00c57b4), `LogRenderCalls` (0x0026b64), `RenderLanes`/`RenderFCStates`/`RenderSpawnPoints`/`RenderConstraints`/`RenderDelayedCasts` — developer debug-draw overlays (inferred from names).

## Notable strings

Per-frame scene profiling markers / format strings (from `mercs2_xenon_p.pe_full_strings.txt`):
- `PgScene::Render-zpass`
- `PgScene::Render-FX`
- `PgScene::Render3DParticles-FX`
- `PgScene::Render-shadow-collect`
- `PgScene::Render vpid: %i` — per-viewport scene render; `%i` is the viewport id.

Material/texture/asset tables (confirmed in strings): `MaterialKeyTable`, `ReloadShaders`, `PgMaterialTable`, `PgDecalTable`, `PgTexture`.

Bloom / HDR tunables (all `.rdata` parameter-name strings):
`BloomAmount` (0x003c630), `BloomMultiplier` (0x003c63c), `BloomThreshold` (0x003c64c), `BloomBlurRadius` (0x003c65c), `BloomTargetLuminance` (0x003c618), `BloomGrainyOpacity` (0x003c51c), `BloomContastMultiplier` (0x003c530, sic — "Contast"), `BloomContastLimit` (0x003c548, sic), `BloomAdaptiveLuminanceScale`/`Percent`/`Min`/`Max`/`MinKeyScale`/`MaxKeyScale` (0x003c5dc … 0x003c580). Note the misspelling "Contast" is verbatim in the binary.

Atmosphere/particle tunables: `AtmosphereForce` (0x003c8d4), `AtmosphereLimit` (0x003c8e4), `AshParticlesPerSecond` (0x003c504), `ParticlesPerSecond` (0x003f5d8), `ParticlesPerMeter` (0x003fb60), `ParticlesPerSqMeter` (0x003fb4c), `ParticlesPerSqMeterScale` (0x003bc60), `SetParticlesPerSecond` (0x0026de8).

Cloth/particle physics limits (`.rdata`): `maxNumParticles` (0x0070ca4), `maxNumTrianglesPerParticle` (0x0070c54), `maxNumPairsPerParticle` (0x0070c70), `clothParticleSystemInfo` (0x0070eb0), `enableRigidParticleCollisions` (0x0070f2c), `enableParticleParticleCollisions` (0x0070f4c), `duplicateClothVertexMap` (0x0070f8c) — Havok cloth/particle config, adjacent to but feeding render.

Shader compiler tunables: `SSMShaderRecyclingEnable` (0x00f0980), `SSMCompilerVFetchMaxSize` (0x00f09b0), `CompileGetVertexDwordsFetched` (0x00f1a10), `CompileWithMaxSizeVfetches` (0x00f1a30).

Mesh/vertex layout fields: `perVertexVectors` (0x005a914), `perVertexInts` (0x005a93c), `perVertexFloats` (0x005a94c), `numBonesPerVertex` (0x005a9f0), `numTextureChannels` (0x005a9b8), `subMaterials` (0x005abc8), `WpMeshShape16Vertex` (0x00b5d38).

Compiled-shader objects: shader names appear twice — once as the logical name (`PgBloomCombinerFP`) and once with the `.sho` suffix (`PgBloomCombinerFP.sho`), the latter being the on-disk/loaded compiled-shader blob (confirmed by `FUN_0084f130`, which registers each as a `(name, name.sho)` pair — see PC decompilation cross-reference). The matching debug-info databases are the 344 `*.updb` files in `shaders_bin_updb_paths.txt`.

## PC decompilation cross-reference

The entries below map this system's Xbox-symbol names to concrete functions in the PC retail decomp (`output/_ghidra/all_functions_decomp.txt`). The pairing was produced by `output/jul08_prototype/pairing/resolved_rendering-shaders.txt`. For this system there are **no vtable-resolved classes** (Ghidra recovered no `Pg*`/`Rt*` RTTI vftables in the retail build, consistent with the Xbox build emitting no `Pg*` RTTI — see "Key classes"), so every match is **string-anchored**: the PC function embeds the same literal that the Xbox build names. I read and confirmed the highest-value ones below.

| Symbol / class | PC function | Bridge | Role | Confidence |
|---|---|---|---|---|
| (all `Pg*`/`.sho` shader names: PgBlobShadow*, PgCloud*, PgAtmosphereVP, PgBloomCombinerFP, PgMesh*ShadowVP, PgSkin*ShadowVP, PgRoadShadowVP, PgShadowFP, …) | `FUN_0084f130` | string | shader-registry / global shader-table loader | high (one func references the entire shader set) |
| `OcclusionMaterial` | `FUN_00852730` | string | shader-table helper (called by `FUN_0084f130`) | medium |
| `RtLightAnimation` | `FUN_00646b60` | string | runtime-type descriptor initializer | high |
| `RtLightAnimation::Update` | `FUN_00675e50` | string | per-frame light-animation update | medium |
| `ParticleEmitter` | `FUN_00642690` | string | runtime-type descriptor initializer | high |
| `ObjectMaterial` | `FUN_006427f0` | string | runtime-type descriptor initializer | high |
| `MaterialTypeEnum`, `ParticleKeyEnum` | `FUN_0064ac50` | string | bulk enum/type-table registrar (16.9 KB) | medium |
| `RtVFX`, `RtDebris`, `RtRibbon`, `RtJunction`, `RtColorAnimation`, `RtAlphaAnimation`, `RtScaleAnimation`, `RtRedEffect`, `RtTickDamage`, `RtGenericLOD`, `RtTerrainChildren`, `RtFactionZone`, … | `FUN_006469e0`, `FUN_0063da60`, `FUN_00648430`, `FUN_00646860`, `FUN_00646c30`, `FUN_00646db0`, `FUN_00646cf0`, `FUN_00646920`, `FUN_00646aa0`, `FUN_00648680`, `FUN_006485b0`, `FUN_00648370`, … | string | sibling runtime-type descriptor initializers (same pattern as above) | high (1:1 distinctive name) |
| `MaterialIds` | `FUN_00a15d70` | string | references the `MaterialIds` field name | low (generic) |
| `uReticleTexture` | `FUN_005f01f0` | string | references `uReticleTexture` | low (generic) |
| `pixelBounds` | `FUN_007b3a90`, `FUN_007b4130`, `FUN_007b4360` | string | reference `pixelBounds` | low (generic) |

### Annotated excerpts

**`FUN_0084f130` — the global shader registry (string-anchored, high confidence).** This single function is what almost every shader name in `resolved_rendering-shaders.txt` resolves to. It is one long sequence of `register(name, name.sho)` calls — the engine-side of the on-disk `.sho` blobs and the 344 `.updb` databases:

```c
FUN_0085ac90(s_PgBlurHFP_00be34ac,      s_PgBlurHFP_sho_00be349c,      0);
FUN_0085ac90(s_PgAntiAliasingFP_00be34ec, s_PgAntiAliasingFP_sho_00be34d4, 0);
...
if ((*(uint *)(DAT_01176288 + 0x5e4) >> 2 & 1) == 0) { pcVar3 = s_PgMeshVP_sho_00be3500; }
else                                                  { pcVar3 = s_PgMeshVPAmbientWind_sho_00be371c; }
FUN_0085ac90(s_PgMeshAmbientWindVP_00be3734, pcVar3, 0);
```

The `(logical name, compiled .sho name, 0)` triple confirms the doc's earlier inference that each shader exists twice (logical + `.sho`). The branch on a global config bit (`DAT_01176288 + 0x5e4`) selects an AmbientWind variant `.sho` for the same logical name — i.e. shader-permutation selection happens here at registration, driven by a render-feature flag. `FUN_0085ac90` is the shader-table insert; `FUN_00852730` (the `OcclusionMaterial` match) is a helper it calls.

**`FUN_00646b60` — `RtLightAnimation` runtime-type descriptor (string-anchored, high confidence).** Despite arriving via the string bridge, this is not a method: it is a descriptor-record initializer that stamps the type name as its last act:

```c
DAT_017bfc4c = 0xffff;  _DAT_017bfc4e = 0xffff;          // id slots
_DAT_017bfc74 = 0x9e3779b9;                              // golden-ratio hash seed
_DAT_017bfc48 = &PTR_CopyFromStream_00bc35d8;            // stream-deserialize vtable
_DAT_017bfc60 = &PTR_FUN_00bc5ff8;
FUN_0064a770();
_DAT_017bfc84 = s_RtLightAnimation_00bc5bcc;             // type name
```

`ParticleEmitter` (`FUN_00642690`) and `ObjectMaterial` (`FUN_006427f0`) are byte-for-byte the same shape (only the target globals, the per-record byte sizes, the `CopyFromStream` thunk, and the stamped name string differ). So the whole `Rt*` block plus `ParticleEmitter`/`ObjectMaterial` in the table above are the engine's **runtime-type / component registry entries**, each wiring a `CopyFromStream` deserializer and a `0x9e3779b9`-seeded hash to a named type. This is the render/ECS boundary and ties into `docs/mercs2-ecs/`.

**`FUN_0064ac50` — bulk enum/type registrar (string-anchored, medium confidence).** A 16.9 KB function that references both `s_MaterialTypeEnum` and `s_ParticleKeyEnum` (and many more). Per the resolver caveat, a function referencing *many* of a system's strings is a registry/dispatch, not a 1:1 method — this is that function for the material-type and particle-key enums, not a `MaterialTypeEnum` accessor.

## How it works (decompiled)

VAs below are from the **Xbox 360** decompilation `output/_ghidra_x360/xenon_decomp_named.c` (base 0x82000000; RVA = VA − 0x82000000). Grep-confirmed. A reusable fact for this whole cluster: many Pangea functions open a profiler scope via `FUN_82297a68(stack, <color>, <name_RVA>)` where the 2nd arg is an ARGB color (e.g. `0xff646464`) and the 3rd arg is `0xffffffff8201XXXX` = the owning symbol's RVA. That third arg is how the otherwise-unnamed render functions self-identify, and it is what I used to confirm identities below against `inventory/rendering-shaders.txt`.

### The EndFrame chain (platform split is real, and thin)

`PgSysRender__EndFrame @0x8229c070` is the frame-end driver:

```c
void PgSysRender__EndFrame(int param_1) {
  FUN_82297a68(auStack_20,0xffffffffff646464,0xffffffff82014c64);  // 0x14c64 = "PgSysRender::EndFrame"
  FUN_8261e0c8(*(undefined4 *)(PTR_DAT_82d4eccc + 0x2d38));         // profiler push
  if (*(char *)(param_1 + 0x138) != '\0')
    PgScene__EndFrame(*(undefined4 *)(param_1 + 0x134));            // end the active scene
  (**(code **)(*(int *)PTR_DAT_82d4ecc8 + 8))();                    // device vcall +8
  FUN_8261e110(...); FUN_826062a0();                                // profiler pop
}
```

It conditionally ends the scene at `+0x134` (gated by a flag at `+0x138`), then makes a device vcall. The renderer split is confirmed but **the Win32 path is a pure thunk to the base class** — `PgRendererWin32__EndFrame @0x828f28d8` is just:

```c
void PgRendererWin32__EndFrame(undefined8 param_1) {
  FUN_82297a68(...,0xffffffff820c4edc);   // 0xc4edc = "PgRendererWin32::EndFrame"
  PgRenderer__EndFrame(param_1);          // delegate to base
  FUN_826062a0();
}
```

and `PgRenderer__EndFrame @0x828f7310` is where the real GPU end happens — a vcall through the device object at `param_1 + 0x2ba0`, vtable slot `+0xC`:

```c
if (*(int **)(param_1 + 0x2ba0) != (int *)0x0)
  (**(code **)(**(int **)(param_1 + 0x2ba0) + 0xc))();   // device->vtable[3]() = present/end
```

So the "cross-platform renderer abstraction" is real, but for EndFrame the Win32 backend adds nothing — the GPU-specific work is behind the device-object vtable at `[base+0x2ba0]`. (The Xenon `EndFrame` body itself is not in the named set, so I cannot show the Xenon-specific path.)

`PgScene__EndFrame @0x82297f30` does scene teardown (`FUN_82295ea0(param_1 + 0x10)` — the scene's collector list at +0x10) and `PgJunk__EndFrame @0x824c0e88` flushes the "junk"/debris draw lists (7 sub-calls, marker 0x307e0).

### Shader registration is a per-family run-once table (Xbox-confirmed)

`PgTerrainMeshFP4D @0x822db050` is the terrain-mesh **shader-registry function** — the Xbox analog of the PC `FUN_0084f130`. Guarded by `DAT_833a3ca8` (run once), it makes 25 register calls:

```c
if (DAT_833a3ca8 == '\0') {
  FUN_828f37a0(0xffffffff833a3cb4, 0xffffffff82017054, 0xffffffff82017064, 0); // ("PgTerrainMeshVP","PgTerrainMeshVP.sho", lod=0)
  FUN_828f37a0(0xffffffff833a3dd8, 0xffffffff82017028, 0xffffffff8201703c, 0);
  ...
  FUN_828f37a0(0xffffffff833a434c, 0xffffffff82016f54, 0xffffffff82016f68, 1); // lod=1
  FUN_828f37a0(0xffffffff833a4430, 0xffffffff82016f28, 0xffffffff82016f3c, 2); // lod=2
  FUN_828f37a0(0xffffffff833a4514, 0xffffffff82016f10, 0xffffffff82016ef4, 3); // lod=3
  ...
  DAT_833a3ca8 = '\x01';
}
```

Inventory confirms: 0x17054 = `PgTerrainMeshVP`, 0x17064 = `PgTerrainMeshVP.sho`, 0x16c70 = `PgTerrainMeshFP4D`. So each register call is **`(dest_slot, logical_name, name.sho, LOD_index)`** — this proves (a) the doc's `(name, name.sho)` pairing inference *and* (b) that the `1D/2D/3D/4D` suffixes correspond to an explicit numeric LOD argument (the 4th param cycles 0,1,2,3). This is the Xbox-side confirmation of the PC `FUN_0084f130` claim, with the added LOD detail. (`FUN_828f37a0`, the table-insert helper, is only present as a non-returning thunk in this dump, so its insertion logic isn't readable here.)

### Render descriptor/components share the ECS reflection backbone

Render-side runtime types (`RtLightAnimation`, `ParticleEmitter`, `ObjectMaterial`, the `Rt*` family) are registered by the **same** descriptor mechanism as world/audio components: `FUN_824fd430` (descriptor record, vtable `&PTR_FUN_82030f50`, pool 0x100) + `FUN_824fcac8` (field-hash table, seed `0x9e3779b9`, element size) + `&PTR_FUN_82030fa0` (shared stream-deserialize vtable) + `FUN_824fd490` (register/assign id). See world-streaming.md "How it works" for the decompiled helper bodies; `0x9e3779b9` and the deserialize vtable are shared across all 232 such descriptors. This means render components are stream-loaded from the WAD identically to terrain/audio components.

## Corrections & open questions

- **CONFIRMED (was inferred):** the `(logical name, .sho)` shader pairing AND the `FP/VP × LOD` permutation structure — `PgTerrainMeshFP4D @0x822db050` registers each shader as `(name, name.sho, lod)` with an explicit 0–3 LOD index.
- **CONFIRMED (was inferred):** the platform-split renderer. But sharpen it: for EndFrame the **Win32 backend is a no-op thunk** to `PgRenderer__EndFrame @0x828f7310`; the GPU work is a device-object vcall at `[renderer+0x2ba0]→vtable[+0xC]`. The doc's "concrete GPU submit in `PgRenderer::SubmitToGPU`" is plausible but `SubmitToGPU`/`ProcessRender`/`RenderFrame`/`SubmitFrame`/`Update` bodies are **not in the Xbox named set** and their RVAs (0xc51e0, 0xc5228, 0x14c7c, 0x14c98, 0x14cb4) are **not referenced** in any decompiled body, so their internals are unverified here.
- **CORRECTION of provenance:** the existing "PC decompilation cross-reference" `FUN_*` VAs (`FUN_0084f130`, `FUN_00646b60`, …) are **PC retail** addresses, not Xbox. They remain valid cross-build evidence but should be labelled as such; the Xbox shader registry is `PgTerrainMeshFP4D @0x822db050` (and sibling per-family registrars), and the Xbox `RtLightAnimation`/`ParticleEmitter`/`ObjectMaterial` descriptors live at `@0x829fXXXX`.
- **CONFIRMED:** RTTI is Havok-only in the Xbox build too (`output/_ghidra_x360/rtti_vtables.txt` — every `Stream`/`Pg`-prefixed RTTI hit is `hk*`), so no `Pg*` render class can be named from RTTI in either build. The doc's "Key classes: none from RTTI" stands.
- **OPEN / not determinable from this build:** pass ordering (z → color → shadow → reflection), `CollectShadowCasters`, the bloom/HDR post chain, decal-as-job, and the `_pl`/`_sl` suffix meaning (point-light/shadow-light) are **still inferences** — those functions are not named and their symbol RVAs are not referenced in any body I could read. The shadow-buffer technique is supported only by the `CompileWith*ShadowBuffering` flag strings, not by a decompiled body.
- **Vector-math gap (expected):** all the actual pixel/vertex math, blending, and matrix setup is VMX128 and does not decode in this PPC dump; nothing about the shaders' numeric behavior can be recovered from the decompilation. Treat all shader *semantics* (vs registration plumbing) as unverified.

## Cross-references

- `docs/mercs2-pdb-analysis/` — sibling per-system docs (e.g. world/streaming, audio, physics-Havok, animation/characters). The Havok `hk*` classes in the RTTI table belong to the physics doc; the `Fx*`/FaceFX cluster belongs to a characters/animation doc.
- Project docs that overlap this subsystem:
  - `docs/scaleformgfx-cfx-blind-swap.md` and memory note "scaleformgfx CFX blind-swap" — the `PgScaleform*` shaders / UCFX assets documented here.
  - `docs/ecs_components.md` and `docs/mercs2-ecs/` — `ObjectMaterial`, `MaterialController`, particle/atmosphere components on the ECS side.
  - Memory note "World-load 0x84DD5B texture-handle corruption" / "MTRL flags/count transposition" — the `MaterialKeyTable` / `numMaterials` / `subMaterials` / `Read*Texture*` symbols are the engine side of the MTRL/texture WAD-conversion work.
  - `docs/engine_load_path_map.md` and "Engine streaming buffer-sizing chain" memory — `LoadTexture`/`ReadTextureBody`/`SwapMipTextures` feed the texture-streaming path analyzed there.

## Evidence & confidence

- Symbol count: 473 lines in `inventory/rendering-shaders.txt`, almost all `.rdata` (function/label name strings), plus 4 `.data` table symbols: `PgMaterialTable`, `PgDecalTable`, `PgMaterialKeyAsset`, `PgTexture`.
- Supporting evidence: 344 shader `.updb` paths (`shaders_bin_updb_paths.txt`); 11 XDK shader-compiler source paths (`source_paths.txt`).
- Sections present: `.rdata` (overwhelming majority) and `.data` (the 4 global tables).

Directly evidenced:
- The symbol/label strings cited above exist at the cited offsets in the inventory.
- `MaterialKeyTable`, `ReloadShaders`, `PgMaterialTable`, `PgDecalTable`, `PgTexture` and the `PgScene::Render-*` markers exist verbatim in the strings file.
- The renderer is platform-split: distinct `PgRendererXenon::EndFrame` and `PgRendererWin32::*` symbols exist.
- The shader compiler is the Microsoft Xbox 360 XDK `ucode`/`ssm` toolchain (source paths under `e:\xenon\mar08\...`).
- RTTI contains NO `Pg*` render classes (the only `Pg*` hits are Havok `hkpG*`) — the table is Havok plus 5 non-Havok utility classes — so render-class names come from `.rdata` symbols, not RTTI.

Inferred from symbol names (not otherwise proven):
- Pass ordering (z → color → shadow → reflection), the `Render`/`RenderZPass`/`RenderShadow` virtual interface, the `_pl`/`_sl`/`_pl_sl` suffix meaning (point-light/shadow-light permutations), `FP`=pixel / `VP`=vertex program, the HDR tone-map+bloom post chain, `externalTextures` vs `inplaceTextures` semantics, and the job-parallel structure of FX/decal/frame rendering. The `Fx*`/FaceFX cluster is facial-animation middleware grouped here only by name prefix; its true home is a characters/animation system. Exact data-structure layouts and call graphs are not recoverable from symbol/string evidence alone.

Verification: every symbol, offset, source path, and quoted string in this doc was grep-confirmed against the inventory, `shaders_bin_updb_paths.txt`, `source_paths.txt`, `rtti_classes.txt`, and `mercs2_xenon_p.pe_full_strings.txt`.
