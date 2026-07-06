# Scoreboard #1 — render core (geometry / materials / textures / pipeline): PC code map

**Scope:** the PC-side render core in `Mercenaries2.exe` (unpacked SecuROM image
`output/_ghidra/securom_dump/mercs2_unpacked.exe`, base 0x400000) — the frame driver, the
per-viewport scene-pass orchestration, the renderable interface, the material system, the texture
streaming lifecycle, the shader registry, and the D3D9 device / render-target plumbing. Binds the
Xbox-PDB names ([rendering-shaders.md](../mercs2-pdb-analysis/rendering-shaders.md)) to concrete PC
addresses. Companion JSON `docs/data/render_core_lighting_code_map.json`. Sibling lighting map:
[lighting_code_map.md](lighting_code_map.md). Reconciled with the already-mapped frame loop
([scheduler_tick_code_map.md](scheduler_tick_code_map.md)) and job system
([pimp_job_system_code_map.md](pimp_job_system_code_map.md)); overlaps with the shadow map
([shadow_code_map.md](shadow_code_map.md) — shadow atlas) and the sky/HDR map
([sky_post_hdr_code_map.md](sky_post_hdr_code_map.md) — bloom/luminance pyramid) are cross-linked, not
re-derived.

## 0. The honest boundary

Two PC source paths survive and pin this cluster exactly: `D:\Projects\Mercs2_PC\mercs2\LTI\src\...`
(`PgLtiRendererPc.cpp` @0xbd3660, `Dx9_State.h` @0xbab994) and the `Odi...` shader-load path
@0xbe897c. So the **device/RT creation, shader registry, material parse, texture-streaming state
machine, and Mercs2.ini config are statically recovered = HIGH/MED confidence** — formats, struct
offsets, vtable indices, and the ini map are all read from literals in the decomp. But the retail
build strips the `PgScene::Render-*` profiler markers and dispatches every per-frame draw through
vtables reached via a register-held `this`, and the render frame runs as **Pimp jobs** whose per-frame
list producers sit behind SecuROM `.securom` thunks. So the **concrete `Model::Render`/`RenderZPass`/
`RenderShadow` bodies, the phase-list producers (`AddRenderable`/`RenderablePut`), and the GPU
submit** are **confirm-live (x32dbg)** with exact break points in §10. No addresses below are invented;
every FUN_/DAT_ is grep-anchored in the decomp and inference-vs-proof is flagged inline. RTTI is
Havok-only in both builds, so no `Pg*` render class can be named from RTTI.

## 1. Frame driver — a Pimp-job pipeline (statically proven)

The Xbox doc *inferred* "the `Render*Job` triplet + `RenderWait` indicate the render frame runs as
scheduled jobs." The PC decomp **proves it**: `FUN_0046a440` registers **6 render jobtype handlers**
(hash→handler) into the Pimp dispatch table `PTR_LAB_019f904c` / `PTR_DAT_019f9048` at base index
`DAT_0117663c`.

| Xbox symbol | PC binding | Role | Conf |
|---|---|---|---|
| (WinMain loop) | `FUN_00631670` | `while(!DAT_01175fff) FUN_00630ef0()` | high |
| `PgSysRender::RenderFrame` | render-view vtable **+0x14** (`PTR_PTR_00dfc2f8`→`0x017CFAF0`) | RunFrame stage 6 kicks render | high |
| `PgSysRender::SubmitFrame` | render-view vtable **+0x10** | RunFrame stage 9 present | high |
| `PgRendererWin32::EndFrame`/flip | render-view vtable **+0x34** (in `FUN_004f59a0`) | vsync/flip | high |
| `RenderUpdateJob` | `LAB_0046a210` (hash `0xcb414134`) → **`FUN_0046a3c0`** | render worker: sets active scene `view+0x2b94`, calls view vtable **+0x4** (resolve/begin) | high |
| `RenderFrameJob` | `LAB_0046a260` (hash `0x5f2080d1`) → **`FUN_0085a9e0`** | per-viewport scene render loop | high |
| (3 more render jobtypes) | `LAB_0046a2a0`(`0x17d1eda3`), `LAB_0046a2f0`(`0xe4fbf71f`), `LAB_0046a320`(`0x156bbfa2`) | further render/submit/wait jobs (bodies unread) | med |
| `PgRenderer::SubmitToGPU`/`ProcessRender`, `Win32::BeginImmediate`/`EndImmediate` | device behind renderer **+0x2d28** (singleton `PTR_PTR_00dfc2fc`, vtable `0x00bd3940`) | GPU submit/immediate | confirm-live |

**Call chain (RunFrame → scene render):**

```
FUN_00631670 (WinMain)
  └ while(!DAT_01175fff) FUN_00630ef0 (RunFrame, 9-stage; scheduler map §1)
       stage 5: FUN_004c14f0 → FUN_004c15e0     5-layer master TICK 0→4 (sim, not render)
       stage 6: (**(*PTR_PTR_00dfc2f8 + 0x14))()  @0x00630FC7   PgSysRender::RenderFrame → dispatches render jobs
                 ├ LAB_0046a210 (0xcb414134) → FUN_0046a3c0   set view+0x2b94 = active scene; (**(*view+4))() begin/resolve
                 └ LAB_0046a260 (0x5f2080d1) → FUN_0085a9e0   RenderFrameJob: QPC-bracketed per-viewport loop
                        for each viewport (count view+0x2b90, idx view+0x2b92, stride 0xE80):
                          FUN_00858f30(view + idx*0xE80 + 0x10)         per-viewport setup
                          (**(*view+0x2ba0 +4))(0/1/2, idx)            phase callbacks 0=pre 1=mid 2=post
                          if (view[idx*0xE80+0x3c] && view+0x2b94)
                             └ FUN_00466d40(*(view+0x2b94))            ← the per-viewport scene-pass driver (§5)
       stage 8: FUN_004f59a0 → (**(*view+0x34))()   flip/vsync
       stage 9: (**(*view+0x10))()                   SubmitFrame / Present
```

`FUN_0085a9e0` is the time-budgeted per-viewport loop (QPC start/end → `_DAT_01176624`), invoking
`FUN_00466d40` once per active scene. It is the concrete PC realization of the Xbox
`PgScene::Render vpid: %i` per-viewport marker.

## 2. Renderer singleton + D3D9 device + config singleton

**PgLtiRenderer(Win32) singleton** = global `PTR_PTR_00dfc2fc` (aliased `PTR_PTR_00dfc2f8` for the
render-view/resolution fields), vtable **`0x00bd3940`**, confirmed by the dtor `FUN_007490b0`
(`*param_1 = &PTR_FUN_00bd3940`; `DeleteCriticalSection(&DAT_00f7ef28)`). Proven object offsets:

| Offset | Meaning | Evidence |
|---|---|---|
| +0x2b98 / +0x2b9c | backbuffer width / height (from `DAT_00dfc328/32c`) | ctor `FUN_007492d0`; read in `FUN_0074dc90` |
| +0x2bd4 | HDR/bloom RT scale factor (float) | `FUN_0074dc90` |
| +0x2d24 | IDirect3D9 (`= DAT_01176284`) | `FUN_00749060` |
| **+0x2d28** | **IDirect3DDevice9** (`= *(DAT_01176288+0x5bc)`) | `FUN_00749060`; used as `this[0xb4a]` (0xb4a*4) in `FUN_00749f70` and `[PTR_PTR_00dfc2fc+0x2d28]` in `FUN_0085b3f0` |
| +0x2cec/+0x2cf0 | `ColorBufferCopy` tex handle / name-hash | ctor |
| +0x2cf4/+0x2cf8 | `DepthBufferCopy` tex handle / name-hash | ctor |
| +0x3e90..+0x3eb0 | BlobShadow front/back VBs (`ColorBuffer` handle +0x3eb4/+0x3eb8) | ctor / shadow map |
| +0x3ebc | secondary render-context (`FUN_0084eab0` init) | ctor |
| +0x3ec0..+0x3f5c | 4× viewport/scissor rect records (init loop, stride 0x30) | ctor |
| +0x43f4..+0x4444 | shadow-atlas surfaces + cascade rects | `FUN_00755d90` (shadow map §1) |

Vtable `0x00bd3940` slot positively identified: **+0x48 (slot 18) = `FUN_00755d90`** (create shadow
atlas), invoked as the last statement of main-RT creation `FUN_00749f70`. Other slots dispatch
register-indirect → confirm-live.

**Config singleton `DAT_01176288`** = the active **RenderSystem / Dx9_State** object (adapter caps +
device). Siblings: `DAT_01176284` = IDirect3D9, `DAT_01176280` = adapter count, `DAT_0117628c` = the
(re)allocated candidate during ApplySettings. Field map (verified across `FUN_0074c7ac`, `FUN_00749f70`,
`FUN_0074dc90`, `FUN_0084f130`):

| Field | Meaning |
|---|---|
| +0x584 / +0x588 | current mode width / height |
| +0x594 | main depth-format flag — 0 ⇒ reuse backbuffer depth, ≠0 ⇒ create own D24S8 (0x4b) |
| +0x5b4 | refresh rate |
| +0x5b8 | present-immediate flag (`==0x80000000`) |
| **+0x5bc** | IDirect3DDevice9 (every RT creator dereferences this) |
| +0x5e0 | adapter-mode list |
| **+0x5e4** | caps/feature bitfield — **bit2** (`>>2&1`) AmbientWind veg quality · **bit3** extra base-`.sho` set · **bit4** (`>>4`) tree-shadow/veg quality · **bit6** (`&0x40`) ShaderLevel capability (clear ⇒ ShaderLevel forced 0) |
| +0x5e8 | shadow depth-format flag (DF24 vs D24S8; shadow map §1) |

## 3. Device / render-target lifecycle

| Function | Addr | Role |
|---|---|---|
| `RenderSystem::ApplySettings` | **`FUN_0074c7ac`** | device create/reset driver: copies 18 dwords from ini bank `&DAT_00dfc320` into live state; allocs the `0x5ec`-byte Dx9_State via `FUN_0084ac20(0x5ec,1)` → ctor `FUN_00754850`; mode-set `FUN_00755500/380/4b0`; reset `FUN_0074cec0`. Forces `ShaderLevel=0` if caps bit `0x40` clear; sets model-LOD floor `DAT_01175c38 = 2 - clamp(ModelDetailLevel,2)`. |
| renderer ctor | **`FUN_007492d0`** | `FUN_00749060` (bind device) → register `global_defaultcubemap`/`ColorBufferCopy`/`DepthBufferCopy`/`ColorBuffer` handles → **`FUN_0084f130`** (shader registry, §4) → **`FUN_00749f70`** (main RTs) → 4 viewport records → adapter-mode enum (device `vtbl+0x190`). Caller `0x004c00d7`. |
| bind device | **`FUN_00749060`** | `InitializeCriticalSection(&DAT_00f7ef28)`; renderer +0x2d24 = D3D9, **+0x2d28 = `*(DAT_01176288+0x5bc)`** device. |
| **CreateRenderTargets (main)** | **`FUN_00749f70`** | this cluster's color/depth RTs (table below); ends with `(**(this+0x48))()` = shadow atlas. |
| CreateRenderTargets (HDR/bloom) | `FUN_0074dc90` (via `FUN_0074dc10`) | **owned by the sky/HDR map** — blur pyramid, bloom-combiner, luminance chain, 1×1 adaptive-exposure feedback `DAT_0117629c`. See [sky_post_hdr_code_map.md](sky_post_hdr_code_map.md) §5. |
| CreateShadowRenderTargets | `FUN_00755d90` | **owned by the shadow map** — 1024×4096 atlas (4 cascades). See [shadow_code_map.md](shadow_code_map.md) §1. |
| OnDeviceLost / ReleaseRenderTargets | `FUN_0074cfa0` → `FUN_0074a640` | releases +0x43f4..+0x4404 + blob VBs +0x3e90..+0x3eb0 |
| Reset / recreate | `FUN_0074cec0` → `FUN_00754e90` | re-runs the RT create chain |

**Main RTs built by `FUN_00749f70`** (device = `this[0xb4a]`; each logs `CREATED SURFACE/TEXTURE:
<name>`; error path `PgLtiRendererPc.cpp` @0xbd3660 + line #). Formats proven from the literal args
(`0x71`=A16B16G16R16F, `0x73`=R32F, `0x4b`=D24S8):

| RT / surface | device method (vtbl idx) | D3DFMT | notes |
|---|---|---|---|
| `FrontColorBuffer` (`_MAIN_RENDERTARGET`) | GetRenderTarget +0x98 | backbuffer | swapchain RT0 |
| `BackDepth` | GetDepthStencilSurface +0xa0 | backbuffer DS | |
| `MainColor` (tex+surf) | CreateTexture +0x5c, GetSurfaceLevel +0x48 | **0x71 (FP16)** | HDR scene color |
| `BackDepth` (own) | CreateDepthStencilSurface +0x74 | **0x4b (D24S8)** | only if `DAT_01176288+0x594 != 0` |
| `ColorBuffer` (tex+surf) | CreateTexture +0x5c | **0x71 (FP16)** | |
| `DepthBuffer` (tex+surf) | CreateTexture +0x5c, GetSurfaceLevel +0x48 | **0x73 (R32F)** | linear-depth copy |
| `DownsampleColor` | CreateTexture +0x5c (½w×½h) | **0x71 (FP16)** | |
| `DownsampleDepth` | CreateDepthStencilSurface +0x74 (½w×½h) | **0x4b (D24S8)** | |

RT handles land at renderer `this[0xfa4..0xfae]`. Tail loop calls device `vtbl+0x1d8` **1024×** with
`(9,ptr)` — sampler/texture-stage default init (**inferred; confirm-live**).

## 4. Shader registry + `.sho` loader

**`FUN_0084f130`** (12,959 B, sole caller ctor `FUN_007492d0` @0x0074957a) = the global shader
registry: one long run of register calls into pool `DAT_01977a38`.

1. **Base blobs first:** 2–5 `FUN_0085b3f0(&DAT_01977a38)` (the 3rd/4th/5th gated on `DAT_01176288+0x5e4`
   bit2/bit3).
2. **~700 name registrations** via **`FUN_0085ac90(logical_name, name.sho, variant)`**. Families in
   order: PgBlurH/V FP, PgAntiAliasingFP, `PgMesh*VP` (NoTangent/NoColor/Morph/Refract/AmbientWind/Fast),
   `PgSkin1*VP`, `PgSkin*VP`, PgDiffRefract FP, all shadow caster VPs, then (further in) the lit material
   FP family, terrain/road/blob/decal/water/sky/post.

**Insert helper `FUN_0085ac90`** (`__thiscall`, 66 B): `record[1] = FUN_00824270()` (FNV-1a name hash →
registry key), **`record[0x23] = arg4`** (the variant/class index), inline-`strcpy` the name into
`record+0xb`, then a `vtbl+8` call. The variant arg is **the LOD index on Xbox terrain (0–3)** and the
**light-class on PC lit material FPs (0=base / 1=`_pl` / 2=`_sl` / 3=`_pl_sl`)** — see
[lighting_code_map.md](lighting_code_map.md) §4. Draw-time bind resolves name→u16 (`FUN_0085abd0`, u16
at `rec+2`), never offset dispatch — why grep finds no render-side references to the VP name strings.

**`.sho` blob loader `FUN_0085b3f0`** (called 5× for the base sets): builds the path into `+0x6c10`,
opens (`FUN_00827660`/`GetFileSizeEx`), streams 0x8000-byte chunks, and per shader sub-blob dispatches
on a type word — `psVar8[1]==1` ⇒ **`device->CreateVertexShader`** (`[[PTR_PTR_00dfc2fc+0x2d28]]+0x16c`,
idx 91); `psVar8[1]==0` ⇒ **`device->CreatePixelShader`** (`+0x1a8`, idx 106). Error path logs
`Error Loading Shader: %08X` + `%s(%i): %s->%s` with `Odi...` @0xbe897c (lines 0x225/0x235). **Both the
device slot (+0x2d28) and the two D3D create indices are proven.**

**Per-family sub-registrars** (callees of `FUN_0084f130`): water `FUN_00484380`, decal `FUN_02475bc0`
(SecuROM island), shader-table helper `FUN_00852730` (builds the `OcclusionMaterial` default template),
plus family stubs `FUN_005726e0`/`FUN_006188b0`/`FUN_02485980` (**inferred**, unopened).

**PC vs Xbox:** PC ships **precompiled `.sho` blobs** loaded straight into CreateVertex/PixelShader —
there is **no runtime shader compilation** in the PC cluster. The Xbox `SSM*`/`Compile*` micro-code
compiler (XDK `ucode/ssm`) has no PC counterpart; the Xbox analog registry is
`PgTerrainMeshFP4D @0x822db050`.

## 5. Scene pass orchestration — `FUN_00466d40` (2,679 B)

Sole caller `FUN_0085a9e0` @0x0085aa5b (arg = active scene `view+0x2b94`), wrapped in
`EnterCriticalSection(param_1+0x37c)`. This is **the one shared per-viewport scene-pass driver** — the
"Water::Render" (shadow/sky maps, high) and "CollectShadowCasters" (med) labels are two render-actions
routed through it, reconciled here as one driver. It builds command packets into the `DAT_018c5620`
render-list arrays and streams render opcodes into the command buffer `DAT_00ff46c0` (cursor
`DAT_00ff46d4`, packet cap `0x2000` @ `DAT_00ff46f0`; push/pop markers = `FUN_008596c0` op `0x10` /
`FUN_00859790` op `0x11`; terminate `FUN_008546a0(0xffff,…)`).

**Body order (sequence statically proven; some pass *identities* are inference):**

| # | Call | Pass | Conf |
|---|---|---|---|
| 1 | `FUN_00486390(DAT_00d6af80)` | RenderWakeMap (water, if singleton live) | med |
| 2 | `(**(**(scene+4→+0x7e0))+4)(…)` | scene begin / RT setup | med |
| 3 | `FUN_004a6590(param_1+0x430)` | caster/renderable **collect** — classify+cull → `+0x1000` list | high |
| 4 | `FUN_00465630()` | per-view camera/plane param tables (`DAT_017e51e0` 0x70, `DAT_018c1fe0` 0x1b0) | high |
| 5 | `thunk_FUN_024bbd20(2,…)` | phase-2 renderable list fetch | high (edge) / confirm-live (body) |
| 6 | shadow gate (below) | CollectShadowCasters | med |
| 7 | `FUN_00482fa0(DAT_00d6af80+0xa30)` | RenderOcclusion (water clip) | med |
| 8 | `FUN_00468e40(param_1,…)` | renderable main-list draw (LOD-gated `+0x1c` vcall) — z/opaque | med (↔ wRenderZPass) |
| 9 | `while(i<4)`: `FUN_008596c0`/`FUN_00468ca0`/`FUN_00859790` | **shadow-cascade emit ×4** | high (structure) |
| 10 | `FUN_00486fa0()` → `FUN_004677d0` | RenderReflection (water mirror) | high |
| 11 | `FUN_00468bb0(param_1,…)` | RenderFadingTrees (veg fade, tree-quality bit `+0x5e4>>4`) | med (inference) |
| 12 | `(**(*(scene+4))+4)(cam+0xae0)` | main **color** draw (`PgScene::RenderColor`); underwater-ordered by `param_1+0x1c0` | med |
| 12b | `FUN_00487540` / `FUN_00487dd0(DAT_00d6af80)` | water surface pass 1 / 2 | med |
| 13 | `PTR_PTR_01175a10` iterate → obj vtbl +0x40 then +0x14 | mirror / sub-scene render | med |
| 15 | `if(DAT_0117507f!=0)`: `FUN_00853710(…)` w/ blob VB `PTR_PTR_00dfc2fc+0x3e94` | BlobShadow quad emit (fallback) | med |

**Shadow gate (verbatim, statically proven — the CollectShadowCasters body):**

```c
if ((DAT_0117507f == '\0') && (DAT_00dfc360 != '\0')) {       // shadow-suppress==0 && EnableShadows!=0
    iVar11 = thunk_FUN_024bbd20(4, aiStack_8030);              // PHASE-4 = shadow-caster list
    if ((*(byte*)(aiStack_8030[0]+0x12) & 1) == 0) {
        iVar11 = FUN_00858150(aiStack_8030[0]+0xac, ...);     // @0x467067 distance/LOD classify → 0/1/2
        if (iVar11 != 0 && (iVar11 == 2 ||
             FUN_00857c00(iStack_14078, aiStack_8030[0]+0xbc, 0x10, ...))) {  // @0x467084 frustum cull
            aiStack_c030[0] = aiStack_8030[0];                // enqueue caster → drives the 4× loop
        }
    }
}
```

`DAT_00dfc360` = **EnableShadows** (Mercs2.ini, §9); `DAT_0117507f` = shadow-suppress. `FUN_00858150`
(82 B) = distance/LOD classifier (`D3DXVec3TransformCoord`+magnitude → 0 cull / 1 partial / 2 full) =
the `SetShadowBaseDistance` decision point (threshold float near `DAT_01176288`, confirm-live);
`FUN_00857c00` (1,330 B) = frustum/plane cull = `ShadowBounds`. **The `while(i<4)` loop wrapping
`FUN_00468ca0` is one emit per cascade — new corroboration for the shadow map's 4×1024² atlas.**

Xbox `SetRenderTargets` (0xeb830) has **no inline opcode** here; the RT set is the scene-object `+0x7e0`
vtable+4 begin call (step 2) plus the render-view vtable+4 — device-side, behind renderer+0x2d28 →
confirm-live.

## 6. Renderables

The Renderable vtable interface (offsets on each renderable `this`), pinned from the four per-object
iterators inside `FUN_00466d40`:

| vtbl slot | Called in | Semantics | Xbox trio | Conf |
|---|---|---|---|---|
| **+0x14** | `FUN_00468bb0` (veg fade); mirror-scene | draw (veg / sub-scene) | `Render` (partial) | med |
| **+0x18** | `FUN_00468ca0` shadow-cascade emit: `(**(*obj+0x18))(param_1)` | **RenderShadow** | `Model/TerrainMesh::RenderShadow` | med-high |
| **+0x1c** | `FUN_00468e40`: `if(DAT_00beae20 < obj[0x67]) (**(*obj+0x1c))()` (LOD-gated) | main draw | `Render`/`RenderZPass` | med |
| **+0x40** | `FUN_004a6590` collect: `(**(*obj+0x40))()` | select / visibility-notify | (activate) | med |

**Where the list lives:** (1) **phase lists** via SecuROM thunk `thunk_FUN_024bbd20(phase_id, out_buf)`
— phase 2 = general renderables, **phase 4 = shadow casters** — body in the `.securom` rwx region
(`0x023E9000+`), not statically readable → confirm-live; (2) **per-viewport scene arrays** on the scene
object: `+0x2000` source count, `+0x430`/`+0x1000` collect in/out (filtered by `FUN_004a6590` via
`FUN_00858150` classify + frustum), `+0x2434` secondary count drained by `FUN_0046ed10`.

Model-vs-TerrainMesh disambiguation and the z-vs-color split of +0x1c/+0x14 need live tracing (no `Pg*`
RTTI). Xbox `AddRenderable`/`RenderablePut` (0x2186c/0x21714) are the **producer** side of the phase
lists → confirm-live (break the thunk, walk the caller that populated the buffer).
`PgRenderableInitializer::Activate/Deactivate/CanActivate` ↔ registry (de)activation vtable slots
+0x14/+0x18/+0x4 walked by `FUN_004c0730` (registries `DAT_00d28668`/`DAT_00d287a0`, med).
`RenderFadingTrees` (0x16a2c) → best PC candidate **`FUN_00468bb0`** (med): gates on tree-quality bit
`+0x5e4>>4`, maintains per-object fade accumulator `obj[0x74]` vs `view+0x2be4`, vcalls +0x14.
`PgJunk::Render`/`PgModelRenderable::CreateDecal` have no static PC anchor.

## 7. Materials

| Xbox symbol | PC binding | Role | Conf |
|---|---|---|---|
| `ObjectMaterial` | **`FUN_006427f0`** | runtime-type **descriptor initializer** — stamps `s_ObjectMaterial_00bc52e8` at `0x017bded4`, seed `0x9e3779b9` @`0x017bdec4`, pool `0x100`, deserializer `&PTR_CopyFromStream_00bc07d0`, record sizes `+0xbc=4`/`+0xbe=8`; called by bulk registrar `0x00a7b160`. Descriptor block base **`0x017bde98`**. | high |
| `OcclusionMaterial` | **`FUN_00852730`** | shader-table **helper** building the default/occlusion material template (24-dword color table + 7-entry index table into `[EAX+0x2e68/0x2e80]`; FNV-1a of `s_OcclusionMaterial_00be8628` → `[+0x2e88]+0x64`; OR `0x80` into flags `+0xa0`). Called by `FUN_0084f130` @0x008523c2. | high |
| `MaterialKeyTable`/`numMaterials`/`subMaterials`/`MaterialIds` | **`FUN_00858790` (`Mtrl_Parse`)** parses; PRMG→material-index consumed by `FUN_00478120`/`FUN_00478270` | on-disk MTRL = packed array of material records; PRMT 16-B record `{u32 material_index@0,…}` selects. This IS the multi-sub-material layout. | high |
| `MaterialController`/`ControlledMaterial`/`PlayMaterialAnimation`/`MaterialCtrlTankTread` | **unbound** (sibling `FUN_006427f0`-shape descriptor inits, name strings stripped) | material UV/frame animation (tank-tread scroll etc.) | low — needs a live `QuerySymbols`/string-xref pass; not guessed |

**`Mtrl_Parse` reconciliation** (`FUN_00858790`, `__stdcall`, `ret 8`; callers = mesh loaders
`FUN_004a0c40`/`004a8f30`/`004ac8e0`/`004a5230`). Runtime material struct (decomp-verified): 104-B
float preamble; `flags:u16 @+0x50`; **`tex_count:u16 @+0xa2`** (hard-capped 10); raw-hash array
`@+0x144+i*4`; **12-B lazy-handle array `@+0xac+i*12` = `{asset_hash, 0xF011157A (TEXTURE_TYPE_HASH),
resolved_ptr}`**; `flags&0x200` → one extra env texture `@+0xA4` (via `FUN_008242b0(0x100)`);
inter-record stride `116 + tex_count*4`. Slot order 0=diffuse, 1=specular/gloss, 2=normal, 3+=extra.
This is the engine side of the project's `convert_mtrl` walker (memory
[[mtrl-flags-count-transposition]]) and the `0x84DD5B` overrun (count>10). See also
[[fun-858790-mtrl-parse-stdcall]] and `docs/modernization/material_shader_spec.md`.

## 8. Texture streaming

The Xbox names (`LoadTexture`/`ReadTextureBody`/`SwapMipTextures`/…) are stripped, but the lifecycle is
fully mapped from the streaming-buffer chain (all decomp-verified):

| Xbox role | PC binding | What it does | Conf |
|---|---|---|---|
| `LoadTexture` (resource-load FSM) | **`FUN_00874fb0`** (`__fastcall`) | two-phase async loader: open → read 0x48-B header → copy INDX (`FUN_00875140`/`008751d0`) → request body | high |
| `ReadTextureData`/`ReadTextureBody`/`getCompTexLOD3D` (residency LOD select) | **`FUN_00875760`** (`__thiscall`) | counts present LOD levels **backward** from `descriptor+10` (4-entry u16 table, `0xFFFF` sentinel), picks page from `descriptor+4+lods*2`, decodes the 0xC-B page record at `param_1[0x113]+page*0xc` | high (parse) / med (getCompTexLOD3D name-inference) |
| request→node | **`FUN_008759c0`** | `node[6]=src[9]`; `node+0x36 bit2 = dxt flag`; `node+0x5a = type-class`; geometry `node+0x40/44/48` | high |
| `CreateTexture` / alloc+async-read (**buffer-sizing root**) | **`FUN_00875b00`** | `alloc = FUN_0084ac20(node+0x4c,0) → node+0x60`; `FUN_008273f0(PTR_DAT_0117634c, node+0x40, +0x44, +0x48, 1, node+0x60, dxtflag)`. **Dest buffer = `page_count(u24 @page+4) << 15`** (32-KB pages); gate checks only free-list → `0xC0000023` BUFFER_TOO_SMALL if the page descriptor under-claims | high (hand-verified) |
| async-read shim | **`FUN_008273f0`** | tail-calls IO ptr `(*_DAT_0244f9b4)(…)` = NTSTATUS syscall | high |
| `SwapMipTextures` / sub-resource walk | **`FUN_00875cc0` → `FUN_00875d80`** | walks `node+0x60` sub-records (0x10-B, advance `record[+0xc]`), pushes onto completion ring `DAT_0117662c` (returns 3 if full) = the mip-body install/swap-in | high |
| `FreeOldTexture` | **unbound** (teardown `FUN_00826f00`/`FUN_0084acd0` in `FUN_00874fb0`) | — | low |
| stream-job registrar (`Tex_RegisterStreamJobs`) | **`FUN_0046a440`** | registers 6 FourCC handlers into `PTR_LAB_019f904c[]` (base `DAT_0117663c`): `0xcb414134/0x5d9a2c1a/0x5f2080d1/0x17d1eda3/0xe4fbf71f/0x156bbfa2` → `LAB_0046a210/230/260/2a0/2f0/320` — the **same table** as the render jobs in §1 | high |

**externalTextures vs inplaceTextures = the residency split:** the resident ASET block ships only a
coarse mip tail (`inplaceTextures`, fixed budget ~2728 B BC1 / 1360 B BC3); higher mips
(`externalTextures`) are lone `BODY` UCFX chunks in the finer c3-cell LOD blocks of the texture's own
cell subtree (one mip per block). See memory [[texture-high-mip-streaming]],
[[engine-streaming-buffer-sizing-chain]] and `docs/engine_load_path_map.md`. The buffer-sizing livelock
on small/non-square textures (`page_count` must cover the full self-describing sub-record chain) remains
OPEN as a converter fidelity issue.

## 9. Render config — Mercs2.ini `[Render]` (`FUN_00753280`)

`GetPrivateProfileIntA` reader (caller `FUN_00631b10`). Writes the config bank `DAT_00dfc320..0xdfc365`;
`ApplySettings` copies the first 18 dwords into live state. Key→global map (verified):

| `[Render]` key | Global | Default |
|---|---|---|
| **EnableShadows** | **`DAT_00dfc360`** | 1 |
| **ShaderLevel** (per-pixel-light master) | **`DAT_00dfc345`** (+copy `DAT_00dfc346`) | 1 |
| **ModelDetailLevel** | **`DAT_00dfc361`** | clamp <3 |
| **ParticleDetailLevel** | **`DAT_00dfc362`** | clamp <3 |
| **ViewDistance** | **`DAT_00dfc348`** | 100 |
| **MotionBlur** | **`DAT_00dfc363`** | 1 (ini flag only; no PC velocity pass — sky map §7) |
| WaterDetail / SkyDetail | `DAT_00dfc357` / `DAT_00dfc358` | 2 / 2 |
| Gamma / EnableWaterEffects / PresentImmediate | `DAT_00dfc340` / `DAT_00dfc344` / `DAT_00dfc34c` | 0x32 / 0 / 0 |
| width / height / RefreshRate / Widescreen | `DAT_00dfc328` / `32c` / `334` / `339` | 0x400 / 0x300 / 0x3c / 0 |

Advanced-video menu path: `FUN_005c37e0` (pending `DAT_00df6740..2`) → commit `FUN_005c1240` → live
`DAT_00dfc36x` (see shadow map §6).

## 10. Confirm-live inventory (x32dbg, read-only while PAUSED)

| Target (Xbox name) | Site | Break recipe |
|---|---|---|
| `RenderFrame`/`SubmitFrame`/flip | render-view `[0x00DFC2F8]`→`0x017CFAF0` vtbl +0x14/+0x10/+0x34 | BP `0x00630FC7`; step into to capture the concrete render-frame body |
| `RenderFrameJob`/`RenderUpdateJob` bodies | `LAB_0046a260→FUN_0085a9e0`, `LAB_0046a210→FUN_0046a3c0` | BP `0x0085a9e0`/`0x0046a3c0`; confirm pulled by Pimp worker (hash `0x5f2080d1`/`0xcb414134`) |
| `Model::Render`/`RenderZPass` | renderable vtbl +0x1c | BP inside `FUN_00468e40` at the `(**(*obj+0x1c))` site; dump `*obj` per hit |
| `Model/TerrainMesh::RenderShadow` | renderable vtbl +0x18 | BP inside `FUN_00468ca0` at `(**(*obj+0x18))(param_1)`, run inside the shadow gate |
| `SetRenderTargets` / shadow-RT bind | device @renderer+0x2d28; renderer +0x4400/+0x4404 | HW write BP on `PTR_PTR_00dfc2fc+0x4404`; capture the vtable binding the atlas |
| `AddRenderable`/`RenderablePut` + phase producers | `thunk_FUN_024bbd20` (`.securom`) | BP the thunk with `(4,buf)`; on return read `buf[0]`, reverse to the writer |
| `SetShadowBaseDistance` storage | float compared in `FUN_00858150` | BP `0x00858150`; identify the FCOMP operand |
| shader create device slots | `FUN_0085b3f0`; device `[[PTR_PTR_00dfc2fc+0x2d28]]` | validate `+0x16c` CreateVS / `+0x1a8` CreatePS; watch pool `DAT_01977a38` grow |
| `FUN_00749f70` RT formats/dims live | each Create* call | capture width/height/format args + returned surfaces `this[0xfa4..0xfae]`; resolve the 1024× `device+0x1d8` init purpose |
| **Mtrl_Parse** (per-material) | `FUN_00858790` (`__stdcall ret 8`) | ESP+4=out, ESP+8=reader; on exit read `out+0xa2` (tex_count), `out+0xac+i*12` (handles), `out+0x50` (flags) |
| **streaming alloc/read** (buffer-too-small) | `FUN_00875b00` | read alloc `*(u32*)(ESI+0x4c)`; after `node+0x60` fills compute `4 + count*0x10 + Σ(record[+0xc])`; diff = under-claimed bytes; resolve `_DAT_0244f9b4` |

## 11. Faithful-reimpl note

The Rust `mercs2_engine` (scoreboard ✅ core / 🟡 overall) implements a **single forward color pass**
with per-PRMT multi-material draw, BC1/BC3 + hi-mip texture streaming, and baked vertex lighting. This
map fixes the gap to the original: a **Pimp-job frame pipeline** (RenderFrame/SubmitFrame render-view
vtable +0x14/+0x10) feeding **one per-viewport scene driver `FUN_00466d40`** that runs
collect → z/opaque → **4× shadow cascade** → reflection → fading-trees → color → water-surface →
mirror → blob-fallback, into a D3D9 command stream; **precompiled `.sho` shaders** registered
name→hash with light-class/LOD variants; the **`Mtrl_Parse` 10-slot lazy-handle material struct**; and
the **page-based async texture streaming** (32-KB pages, external-vs-inplace mip residency). The
multi-pass architecture (`rendering_fx_lighting_gap.md` §I) and the shadow/HDR sub-passes (owned by the
sibling maps) are the concrete faithful-reimpl surface.
