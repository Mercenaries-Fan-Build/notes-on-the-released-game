# Mercenaries 2 — PgFX particle / effect subsystem: PC code map

**Scope:** the PC-side code for the particle/effect (PgFX) subsystem in `Mercenaries2.exe`, reversed
from the unpacked SecuROM image (`output/_ghidra/securom_dump/mercs2_unpacked.exe`, base 0x400000) via
a multi-agent fan-out. Companion: [shadow_code_map.md](shadow_code_map.md). Machine-readable table
(addr, subsystem, stage, role, confidence, evidence): **`docs/data/particle_fx_shadow_code_map.json`**.

This complements what we already had: the binary formats in [fxdict_format.md](../fxdict_format.md),
the ECS component schemas in [docs/mercs2-ecs/05_presentation_audio_fx.md](../mercs2-ecs/05_presentation_audio_fx.md),
and the Xbox PDB symbol names in [rendering-shaders.md](../mercs2-pdb-analysis/rendering-shaders.md).
This doc binds those to **PC addresses**.

## 0. The honest boundary (read this first)

PgFX is **not** a vendored contiguous library (unlike Scaleform GFx) — it is Pandemic engine code
woven through the ECS reflection system and the LTI renderer. Two consequences shape what is and
isn't in this map:

1. **The retail PC build strips the `PgFX`/`PgScene` profiler-marker strings.** `PgFX` appears *zero*
   times as a code literal in the 27k-function decomp; every Xbox PDB marker (`PgFX::Render3DParticles`,
   `EmitParticles`, `CountParticles`, `FxPreSimulate`, `FxVisibility`, `FxSpuParticleGen`,
   `FxShaderTask`, `PgScene::Render vpid`) is absent. So the **per-frame emit / simulate / draw pass
   has no string anchor** on PC.
2. **The runtime is vtable-dispatched.** Effect components load and render through per-class reflection
   vtables whose slot targets live in `.data`; the static callgraph cannot see those edges.

Therefore this map is **high-confidence for everything statically anchored** — reflection registration,
the binary-format parsers, the shader registry, the memory pools — and marks the **runtime
sim/render functions with their exact vtable address + slot and a `confirm-live (x32dbg)` flag**
rather than guessing a caller. This mirrors how the GFx map handled SecuROM-relocated bodies.

## 1. Bootstrap & memory

`FUN_0048a170` (**PgFX subsystem init**) fires async ASET requests via `thunk_FUN_0248d520`: the
**`vfx` atlas** (`asset 0x89E211AF`) and **`particle_mask`** (`asset 0x07B71436`), both texture type
`0xF011157A`, and the **fxdict** singleton (`asset 0x86BF6C5B`, type `0xFA46D8A8`); after the pools,
the fxdict again and the **effect** table (`asset 0xD2E54786`, type `0x5608BD5A`). PROVEN by the
decomp. The atlas and the fxdict are documented in fxdict_format.md §3.2, §3.4. It also
allocates 3× the FX runtime pool via `FUN_004937d0` (0x1DD90 bytes: 40000/15000-entry particle
arrays + two 720000-byte double buffers). Both binary loaders have `callers=[]` because they are
the **type-registered load callbacks** invoked through the asset-system vtable.

## 2. Reflection / ECS component family

FX types are ordinary ECS reflection classes, registered through the engine's standard 3-layer
mechanism (fully corroborates docs/mercs2-ecs/05):

- **Class registrar** (~159 B each, run from the CRT static-init table): zero-inits a 0x50-byte
  descriptor in `.data`, sets the shared `CopyFromStream` vtable ptr, the per-instance **stride**
  (`desc+0x24`), the golden-ratio hash seed `0x9E3779B9` (`desc+0x28`, present in all 232 classes),
  and the class-name ptr; then tail-calls **`FUN_0064a770`** which appends the descriptor into the
  global reflection-class array `PTR_PTR_00edbec8[DAT_01176058]` and assigns the class id. This is
  the wire into the ECS registry.
- **Field/deserialize template** (`0x65c000–0x66ffff`, reached only via the CopyFromStream vtable):
  reads fields in stream order through shared primitives (`FUN_00656210` int, `FUN_00656320` float,
  `FUN_00656610` vec3/rgb, `FUN_00656720` enum-by-name, `FUN_00656890` ref).
- **Two master init tables** from bootstrap `FUN_0064aa70`: **`FUN_0064ac50`** (16.9 KB) builds 65
  enum tables (incl. `ParticleKeyEnum`, `MaterialTypeEnum`, `EmissionShapeEnum`, `EmissionControlEnum`);
  **`FUN_0064ee60`** (23 KB) registers every class's deserialize fn-ptr into a hash-keyed dispatch.

The FX component family:

| Component | m2 hash | ECS stride | PC registrar | schema/load fn | kind |
|---|---|---|---|---|---|
| ParticleEmitter | 0xE595AB2F | 0x10 | FUN_00642690 | FUN_00661190 | authored |
| RedEffectComponent | 0x60A13E3E | 0x38 | FUN_00643330 | FUN_00662b20 | authored |
| EffectTemplate | 0xABAA1F3C | 0x04 | FUN_006433f0 | FUN_00662d40 | authored (template ref) |
| EffectAiOccluder | 0x20E89C9D | 0x04 | FUN_006434b0 | FUN_00662e50 | authored |
| Ribbon | 0x059B95B9 | 0x2C | FUN_00643e00 | FUN_00664dd0 | authored |
| RtRedEffect | 0x9B2DAF6F | 0x20 | FUN_00646920 | — | **runtime instance** |
| RtVFX | 0x757B2069 | 0x10 | FUN_006469e0 | — | **runtime instance** |
| RtRibbon | 0x9AB86EB3 | 0x20 | FUN_00648430 | — | **runtime instance** |

**Two "size" numbers, resolved:** `desc+0x24` is the **ECS per-instance stride** (above). The
descriptor strings at `0xbadbf9–0xbae695` ("ParticleEmitter 8 8", "ParticleKey 6144",
"MaterialEmitter 1024", "RedEffectComponent 768", "Ribbon 32 32", "RtRedEffect 8 8") are a
**separate PgFX memory-pool budget table** (pool name + byte budget). `ParticleKey` (6144),
`MaterialEmitter` (1024), `ParticleMass`, `RedEffectTweak` have **no** ECS registrar — they are
sub-structures/pools inside the Red-effect particle system, not reflected components.

**Authored vs runtime split:** the `Rt*` classes (RtRedEffect / RtVFX / RtRibbon) are the *runtime
instances* spawned from authored templates (RedEffectComponent / ParticleEmitter / Ribbon) — they
carry no authored schema and are what the render pass iterates.

## 3. Binary-format loaders

**fxdict → `FUN_00491320`** parses two UCFX chunks: `INFO` (`u32 entry_count` → obj+0x1c; allocates
`count*0x20`), then `DICT`, reading 5 dwords per record (**20 B disk stride**) and expanding each to a
**32 B runtime record**: `+0x00 key, +0x10 u, +0x14 = (1.0 − v − h), +0x18 w, +0x1c h` (the `1.0`
is `DAT_00B9B664`). The record `{key, u, v, w, h}` is a sprite rectangle of the `vfx` atlas, `v`
measured from the bottom, and `+0x14` is its top edge measured from the top
([fxdict_format.md](../fxdict_format.md) §3.2). Lookup is `FUN_00491510`: a binary search on
`+0x00` with a signed compare, returning `rec+0x10`, and a static `(0, 0, 1, 1)` — the whole atlas —
for a key it misses. PROVEN by the decomp.

**effect → `FUN_00491920` (block driver) → `FUN_00492af0` (per-emitter)**. The driver reads the
`EFCT` header (u16 counts; sub-count gates a `count*0x140` alloc at effect+0x8c; emitter pool
`count*0x210` at +0x84 init by `FUN_00492870`), then walks the chunk linked-list dispatching by tag:

| Tag | Hash | Handler | Writes |
|---|---|---|---|
| EFCT | header | 00491920 | effect+0x80/+0x84/+0x88/+0x8c/+0x90/+0x94 |
| EMTR | 0x52544D45 | 00491920 | count→+0x90, alloc→+0x98; 0x34-B sub-records |
| FRCE | 0x45435246 | 00491920 (+FUN_00477c60) | force mode→emitter+0x128; params +0x104..+0x13c |
| PTYP | 0x50595450 | 00491920 | flag bits emitter+0x205/+0x206; recurses; +0x210 stride |
| EMIT | 0x54494D45 | FUN_0048cc30 → FUN_00493150 | emitter data @ effect+0x20; ANIM/AKEY key curves |
| ATRB | 0x42525441 | FUN_00492af0 | param-hash → scalar setters; emitter+0x1EC/+0x1F0 |
| TEXT | 0x54584554 | FUN_00492af0 → FUN_004911a0 | 16-B descriptor → effect stream table; f16 pack |
| COLR | 0x524C4F43 | FUN_00492af0 | copies exactly 800 B = 100 keys × `{u8×4 colour, binary16, u16 0}`; reserves 200 stream-table words (`*desc = 200`); stream index → emitter+0x1D8 ([effect_container_format.md](../effect_container_format.md) §6) |

GEOM/TRFM/AKEY are consumed inside the EMIT path, not as top-level tags.

**The `+0x60` crash array (matches spatial_hash_crash_analysis.md):** the effect object holds a
stream/descriptor table `[+0x60]`=16-B descriptor base, `[+0x64]`=data, `[+0x70]`=next index,
`[+0x74]`=running offset, `[+0x6C]`=capacity, sized from the EFCT sub-component count. COLR/TEXT
append `[+0x70]*0x10 + [+0x60]`. If the EFCT header count words are read as u16 instead of
byteswapped as u32, the count zeroes → NULL `[+0x60]` alloc → `mov edx,[edi+0x70]; add edx,[edi+0x60];
mov [edx+0x4],ecx` faults at **0x00493102** (the COLR branch). This is the exact byteswap contract in
fxdict_format.md §4.

**Where effects land:** the fxdict **singleton** (searchable param dict) + 314 **EffectTemplate
runtime objects** (type 0x5608BD5A, class 0xABAA1F3C), each holding the parsed emitter pool (+0x84)
and stream table (+0x60), referenced at sim/render time by the global FX pool from `FUN_004937d0`.

## 4. Shader binding

The single shader registry **`FUN_0084f130`** (12.9 KB) registers ~700 shaders via
**`FUN_0085ac90(name, "*.sho", light_class)`**, which mints a handle = **FNV-1a(name)**
(`FUN_00824270 → FUN_0082427f`, prime `0x1000193`, case-fold `|0x20`, final `^0x2a`) and inserts
it into the global shader pool anchored at `DAT_01977a38` (name→u16 allocator `FUN_0085abd0`; the
u16 lands at `rec+2` and is the draw-time binding). `light_class` ∈ {0 base, 1 `_pl`, 2 `_sl`,
3 `_pl_sl`}. At draw time a material resolves a shader by `FUN_0085aff0 → FUN_0085abd0` (~120+ call
sites = the material bind points).

**The PgFX shaders are not in this registry.** `PgFXVP/FP/VPR/FPR` and the `PgBillboardTree*` family
have **zero references** from code in the decomp; their strings sit at `0xbac264`, with copies at
`0x0143xxxx` in material descriptors (below). `PgRibbonVP`/`PgRibbonFP` **are** in the registry but
alias generic shaders: `PgRibbonVP → Pg3DVP.sho`, `PgRibbonFP → PgDiffuseFP.sho`.

**The PgFX shaders exist on PC**, as records 343–346 of `shader3.bin`. PROVEN by the store and the
disassembly:

- **`PgFXFP`, record 344** (`ps_3_0`, `diffuseMap` at `s0`): `texld r0, v0, s0`, `mul r0, r0, v1`
  (× the vertex colour), then `mul oC0.xyz, r0.w, r0` and `mul oC0.w, r0.w, v0.w`. The texture is
  sampled with straight alpha and the shader writes `rgb × a`.
- **`PgFXVP`, record 346** (`vs_3_0`): `mova a0.x, v1.x` (`BLENDINDICES`) and
  `mad o1.xy, c21[a0.x], v3.zwzw, v3` — the texel coordinate is `rect.xy + corner × rect.zw`, the
  rectangle in `TEXCOORD0` (`v3`) and the corner one of `c21..c24` = (0, 0), (0, 1), (1, 1), (1, 0).

**Four materials draw particles.** Three bind the `vfx` atlas (`0x89E211AF`) at texture slot 0 with
`PgFXFP.sho` (handle `0xBF`; the descriptor bytes at `0x0143A1A0` carry both); one, the refraction material,
binds `particle_mask` (`0x07B71436`) with `PgFXFPR`. The atlas is the one texture particles sample:
no effect field names a texture, and no `MTRL` in `vz.wad` names `0x89E211AF`
(`mercs2_formats/tests/fxdict_atlas_retail.rs`). PROVEN by the 2026-10 analysis of the descriptors
and the retail data.

## 5. Ribbon / tracer runtime

Authored **Ribbon** (0x2C, schema `FUN_00664dd0`: 4 int ids + 6 floats width/lifetime/uv-scroll +
1 BoolEnum) sits on an entity → the effect system spawns an **RtRibbon** runtime instance (0x20,
registrar `FUN_00648430`) that accumulates per-frame trail/segment history (pool "16 16") → a render
system builds a triangle-strip ribbon from the segment history and draws it with the
`PgRibbonVP`/`PgRibbonFP` handles (= `Pg3DVP.sho`/`PgDiffuseFP.sho`). **RtRedEffect** is the sibling
runtime tracer instance of RedEffectComponent. The segment-emit + geometry-build + draw function is
reached only through the RtRibbon class vtable `PTR_00bc45a8` — **confirm-live**.

## 6. Runtime render / emit / simulate — confirm-live inventory

These have no PC string anchor and are vtable-gated. Recorded with the exact vtable to break on:

| Xbox PDB name | reached via | confirm-live break |
|---|---|---|
| ParticleEmitter EmitParticles / integrate (pos/vel/gravity/drag) | `PTR_CopyFromStream_00bc0730` (ParticleEmitter) | HW-bp the vtable render/update slot after a save loads |
| Render3DParticles draw + blend/depth | RtRedEffect vtable `0xbc34e8`, RtVFX vtable `0xbc3538` | break the RtRedEffect/RtVFX Render slot during a live effect |
| RtRibbon segment-emit + ribbon draw | RtRibbon vtable `0xbc45a8` | break the RtRibbon render slot; observe segment feed |
| FxSpuParticleGen / FxShaderTask / FxVisibility (job-parallel split) | no PC string | unverifiable statically; check for a job dispatch at the emit site |

**The billboard builder is `FUN_00494740`** (called from `FUN_00494130`). It writes one particle as
four `0x24`-byte vertices (`0x90` bytes) and adds 6 to the u16 at `[+0x1D70C] + 2`. Each vertex starts with the
8 bytes `thunk_FUN_024EEBB0` returns for the emitter's stream at an index from the particle's age byte
(`+0x21`) — the frame's rectangle as four binary16 (INFERRED: the stream entry `FUN_004911a0` wrote,
[effect_container_format.md](../effect_container_format.md) §2) — and carries the corner index 0–3
in byte `+0x20`, which `PgFXVP` reads as `BLENDINDICES` to pick the corner (§4). PROVEN by the
decomp for the layout and the corner byte.

`FUN_00661190` (the candidate "ParticleEmitter update") is confirmed to be the **schema-builder**
callback (defines reflected fields), *not* the runtime integrator.

## 7. Faithful-reimpl note

The engine's own runtime is CPU billboard particles (additive/alpha, colour-over-life gradient from
COLR, gravity/drag from FRCE) driven by authored EffectTemplates — which is exactly the model the
Rust engine's `mercs2_engine::particles` already implements from the parsed `fxdict`/effect chunks
(see [rendering_fx_lighting_gap.md](../modernization/rendering_fx_lighting_gap.md) §E). This map
confirms the data path feeding it and pins the confirm-live break points needed to validate the
sim/emit numbers against the original.
