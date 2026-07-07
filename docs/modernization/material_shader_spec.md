# Material / Shader Spec — Textured, Lit Characters

**Status:** Reimplementation spec (research-derived; not engine code)
**Date:** 2026-06-30
**Consumers:** the native 64-bit Rust/`wgpu` reimplementation (`docs/modernization/00_charter.md`),
Phase 1 ("first triangle from real data") → character rendering.

**Goal:** move character models from untextured point clouds to **tangent-space
normal-mapped, diffuse-lit** meshes, faithful enough to read as the real characters.

## Provenance (what is proven vs inferred)

- **MTRL byte layout** — decompile-verified from `Mtrl_Parse` = `FUN_00858790`
  (`output/_ghidra/all_functions_decomp.txt:641924`), corroborated by
  `tools/ucfx_mesh_codec.py::parse_mtrl` and retail-oracle scans (~59k materials).
  Cited byte offsets are **into the material runtime struct** (`param_1`) and,
  separately, **into the on-disk MTRL chunk body**.
- **Vertex decl (DECL64) + tangent** — `tools/wad_simulator/crates/mercs2_formats/src/model_inject.rs`
  (`DECL64`, lines 37–46; `synth_tangents`, `encode_strm`), plus memory
  `dec3n-tangent-layout-bug` (NORMAL=HEND3N 11-11-10, TANGENT=DEC3N 10-10-10-2).
- **Texture formats** — `texsize.rs::dxt_format` (DXT1 = 8 B/block, DXT5 = 16 B/block).
- **Shader semantics (numeric)** — the actual pixel/vertex ALU is Xbox VMX128 micro-code
  (`.sho`/`.updb`, `docs/mercs2-pdb-analysis/rendering-shaders.md`) and does **not**
  decode; the character surface model below is **reconstructed** from the MTRL inputs
  the engine parses (diffuse+spec+normal slots, spec-power/IOR/fresnel preamble) and the
  `PgSkin*`/normal-map shader family names. Treat the exact BRDF constants as tunable.

---

## 1. MTRL chunk → texture-slot binding

### 1a. On-disk MTRL chunk body (what the mesh reader must parse)

A container's `MTRL` chunk holds a **packed array of material records** (one per
sub-mesh material; PRMT `material_index` selects which). Each record:

```
offset  size          field
 0      104 (26×u32)   PREAMBLE — color/emissive/specular float params (see 1c)
104     u16            flags        (material-type bits; low 16)
106     u16            tex_count    (1..=10; number of texture-hash slots)
108     tex_count×u32  texture asset hashes  (slot order: diffuse, specular, normal, …)
...     rest           trailing float props (specular_power @ prop[16], spec_intensity @ prop[17])
```

- **Inter-record stride = `116 + tex_count*4`** for >99.5% of records
  (`104` preamble + `4` flag/count word + `tex_count*4` hashes + `8` trailing).
  A rare tail carries extra trailing floats — recover by scanning forward to the next
  plausible `[u16 flags | u16 count]` word (count high-byte 0, low-byte 1..10).
- **`tex_count` is the reliable record-boundary signature** (BE-safe: high byte 0,
  low byte 1..10). `flags` is NOT bounded < 0x200 — real materials reach ~0x418.
- **CAUTION (converter, not renderer):** a blanket u32 byteswap transposes the
  `[flags|count]` u16 pair → engine reads `count=128` and walks param-floats as hashes.
  The Rust converter's `convert_mtrl` array-walker fixes this (memory
  `mtrl-flags-count-transposition`). The reimpl reads **already-LE** data, so this is
  only a concern if reading Xbox-endian assets directly.

### 1b. Runtime material struct (how `Mtrl_Parse` binds it — the semantics)

`FUN_00858790(material* p1, stream* p2)` (`__stdcall`, `ret 8`) deserializes the record:

- Reads the 104-byte preamble as float vectors (color/emissive/specular; see 1c).
- `flags` (u16) → `FUN_0084ee70` (pure bit-permute, 0 stream bytes) → `p1+0x50`.
- `tex_count` (u16) → `p1+0xA2`.
- Loop `i in 0..tex_count`, **hard-capped at 10** (`if 9 < i goto done`):
  - raw hash → `p1 + 0x144 + i*4` (parallel raw-hash array).
  - a **12-byte lazy-handle record** at `p1 + 0xAC + i*12` = `{ asset_hash:u32,
    type_hash=0xF011157A, resolved_ptr:u32 }`. `0xF011157A` is `TEXTURE_TYPE_HASH` —
    each slot is a deferred **texture** asset reference resolved by the streaming system.
  - unused slots (i..10) are zero-filled.
- If `flags & 0x200`: binds one extra **environment/dynamic** texture at `p1+0xA4`
  from a global registry (`FUN_008242b0(0x100)`), not from the record.

**Slot semantics (index → role):** slot 0 = **diffuse (albedo)**, slot 1 = **specular /
gloss**, slot 2 = **normal map**, slots 3+ = extra maps (detail/env/mask). This ordering
is the project's working convention (`material_probe.py`, `tools/ucfx_mesh_codec.py`
docstring). Characters are typically `tex_count = 3` (diffuse+spec+normal). The extra
`flags&0x200` slot is a cube/env map. **For the minimal renderer, bind slots 0–2.**

### 1c. Preamble float params (offsets into the runtime struct, `p1`)

`Mtrl_Parse` reads 26 u32/f32 and computes a fresnel/spec-highlight setup:

| Runtime off | Meaning (reconstructed) |
|---|---|
| `p1+0x00..0x1F` | 4 float4 vectors — diffuse color, emissive, spec color, params |
| `p1+0x54` | **IOR** (index of refraction), clamped ≥ `DAT_00b977f8` |
| `p1+0x2c` | `(IOR-1)/(IOR+1)` → **Fresnel F0** (Schlick base reflectance) |
| `p1+0x5c`,`+0x6c`,`+0x74` | spec-lobe params → feed highlight math |
| `p1+0x84..0x9c` | derived spec-highlight coefficients (two lobes) |
| on-disk prop[16], prop[17] | **specular_power** (gloss exponent), **specular_intensity** |

The minimal renderer can ignore the two-lobe derivation and use `specular_power` +
`specular_intensity` + a Schlick-Fresnel `F0` directly (see §3).

---

## 2. Character surface shader model

The character shader family is **`PgSkin*` / normal-mapped** (skinned VP + normal-map
FP; `docs/mercs2-pdb-analysis/rendering-shaders.md`). Reconstructed surface model:

```
N_tan   = 2*sample(normal_map, uv).rgb - 1        // tangent-space normal (DXT5 or DXT1)
TBN     = [ T | B | N ]   (per-vertex, world space; B = cross(N,T)*tangent.w)
N_world = normalize( TBN * N_tan )
albedo  = sample(diffuse, uv).rgb  * material_color.rgb
spec_ms = sample(specular, uv)     // rgb = spec color/mask, optionally a = gloss

L       = normalize(-light_dir)    // single key directional light
NdotL   = max(dot(N_world, L), 0)
diffuse = albedo * NdotL * light_color + albedo * ambient

// Blinn-Phong spec with material spec-power (gloss) and Fresnel F0
H       = normalize(L + V)
spec    = spec_ms.rgb * spec_intensity * pow(max(dot(N_world,H),0), spec_power)
F       = F0 + (1-F0)*pow(1-max(dot(N_world,V),0), 5)   // Schlick fresnel/rim
color   = diffuse + spec*light_color + F*rim_tint       // (rim term optional)
```

Notes / fidelity:
- **Tangent-space normal mapping is the load-bearing effect** — getting the TBN right
  (from the DEC3N tangent) is what makes the character read as lit/detailed rather than
  flat (memory `dec3n-tangent-layout-bug`: wrong tangent → ~125° error → "mangled").
- The real engine adds shadow-buffer shadows, env/cube reflection (`flags&0x200`), rim,
  and HDR tonemap. **All optional for faithful-enough.** Start with diffuse+normal+one
  directional light; add spec + fresnel next; env/shadows last.
- Vertex COLOR (bgra8) is usually white for characters — multiply in if present.

---

## 3. Minimal `wgpu` implementation spec

### 3a. Vertex attributes the mesh reader must extract (DECL64, stride 40)

Decode from the stride-40 STRM body (`model_inject.rs` DECL64). All half-floats are LE
IEEE-754 f16. **Decode NORMAL/TANGENT already-LE from PC assets; do NOT re-apply the
DEC3N bit-unpack** — that unpack (11-11-10 for normal, 10-10-10-2 for tangent) is an
**Xbox→PC converter** step; converted PC assets store NORMAL/TANGENT as f16x4 in the
stream. The reader just reads f16x4.

| Attr | Byte off | On-disk type | Decode → wgpu attribute |
|---|---|---|---|
| POSITION     | +0  | f16×4 (x,y,z,w=1) | `Float32x3` (drop w) |
| TEXCOORD0    | +8  | f16×2 (u,v)       | `Float32x2` |
| COLOR        | +12 | bgra8 (0xFFFFFFFF) | `Unorm8x4` (or skip) |
| BLENDINDICES | +16 | u8×4              | `Uint8x4` (skinning; ignore for rigid) |
| BLENDWEIGHT  | +20 | u8×4n             | `Unorm8x4` (skinning) |
| NORMAL       | +24 | f16×4 (nx,ny,nz,1) | `Float32x3` (drop w) |
| TANGENT      | +32 | f16×4 (tx,ty,tz,sign) | `Float32x4` (keep w = handedness sign) |

The renderer's minimal vertex is **`{ pos:vec3, uv:vec2, normal:vec3, tangent:vec4 }`**
(add joints/weights when skinning lands). Bitangent = `cross(normal, tangent.xyz) *
tangent.w`. If a source mesh lacks tangents, synthesize them (Lengyel + Gram-Schmidt,
`model_inject.rs::synth_tangents`).

Indices: STRM/IBUF is a **triangle STRIP** (u16); convert to a list or draw as
`PrimitiveTopology::TriangleStrip` (winding: odd triangles reversed — see
`strip_to_tris`).

### 3b. Bind-group layout

```
Group 0 — frame/camera uniform (view_proj, camera_pos)         // std, not detailed here
Group 1 — light uniform:
  @binding(0) uniform Light { dir:vec3, _p0:f32,
                              color:vec3, _p1:f32,
                              ambient:vec3, _p2:f32 }           // 48 B, std140-aligned
Group 2 — material (per draw / per sub-mesh):
  @binding(0) uniform Mtrl  { base_color:vec4, spec_intensity:f32,
                              spec_power:f32, f0:f32, _pad:f32 }
  @binding(1) texture_2d<f32> t_diffuse   // slot 0, DXT1/DXT5 (Bc1/Bc3 in wgpu)
  @binding(2) texture_2d<f32> t_specular  // slot 1
  @binding(3) texture_2d<f32> t_normal    // slot 2
  @binding(4) sampler s_linear            // repeat, linear+mip
```

Texture upload: DXT1 → `TextureFormat::Bc1RgbaUnorm(Srgb)`, DXT5 →
`Bc3RgbaUnorm(Srgb)`. Diffuse = sRGB; **normal + specular = linear** (`Bc*Unorm`, not
Srgb). Upload the full mip chain (`texsize::dxt_mip_count`, down to 4×4). If a slot hash
is 0/unresolved, bind a 1×1 default (white diffuse, `(0.5,0.5,1)` normal, black spec).

### 3c. WGSL (minimal, normal-mapped diffuse + optional spec/fresnel)

```wgsl
struct Camera { view_proj: mat4x4<f32>, cam_pos: vec3<f32> };
struct Light  { dir: vec3<f32>, _p0: f32, color: vec3<f32>, _p1: f32,
                ambient: vec3<f32>, _p2: f32 };
struct Mtrl   { base_color: vec4<f32>, spec_intensity: f32, spec_power: f32,
                f0: f32, _pad: f32 };

@group(0) @binding(0) var<uniform> cam: Camera;
@group(1) @binding(0) var<uniform> light: Light;
@group(2) @binding(0) var<uniform> mtrl: Mtrl;
@group(2) @binding(1) var t_diffuse:  texture_2d<f32>;
@group(2) @binding(2) var t_specular: texture_2d<f32>;
@group(2) @binding(3) var t_normal:   texture_2d<f32>;
@group(2) @binding(4) var s_linear:   sampler;

struct VsIn  { @location(0) pos: vec3<f32>, @location(1) uv: vec2<f32>,
               @location(2) normal: vec3<f32>, @location(3) tangent: vec4<f32> };
struct VsOut { @builtin(position) clip: vec4<f32>,
               @location(0) uv: vec2<f32>, @location(1) wpos: vec3<f32>,
               @location(2) n: vec3<f32>, @location(3) t: vec3<f32>, @location(4) b: vec3<f32> };

@vertex
fn vs(in: VsIn) -> VsOut {
    // NOTE: for skinned characters, blend pos/normal/tangent by bone matrices here first.
    var o: VsOut;
    let wpos = in.pos;                       // model==world for the minimal path
    o.clip = cam.view_proj * vec4<f32>(wpos, 1.0);
    o.wpos = wpos;
    o.uv   = in.uv;
    o.n    = normalize(in.normal);
    o.t    = normalize(in.tangent.xyz);
    o.b    = cross(o.n, o.t) * in.tangent.w; // handedness from tangent.w
    return o;
}

@fragment
fn fs(in: VsOut) -> @location(0) vec4<f32> {
    let n_tan = textureSample(t_normal, s_linear, in.uv).xyz * 2.0 - 1.0;
    let tbn   = mat3x3<f32>(normalize(in.t), normalize(in.b), normalize(in.n));
    let N     = normalize(tbn * n_tan);

    let albedo = textureSample(t_diffuse, s_linear, in.uv).rgb * mtrl.base_color.rgb;
    let spec_s = textureSample(t_specular, s_linear, in.uv).rgb;

    let L = normalize(-light.dir);
    let V = normalize(cam.cam_pos - in.wpos);
    let H = normalize(L + V);
    let ndl = max(dot(N, L), 0.0);

    let diffuse = albedo * (ndl * light.color + light.ambient);
    let spec    = spec_s * (mtrl.spec_intensity *
                            pow(max(dot(N, H), 0.0), max(mtrl.spec_power, 1.0)));
    let fres    = mtrl.f0 + (1.0 - mtrl.f0) * pow(1.0 - max(dot(N, V), 0.0), 5.0);
    let color   = diffuse + spec * light.color + fres * spec_s * light.color;
    return vec4<f32>(color, mtrl.base_color.a);
}
```

Uniform mapping from the parsed material: `base_color` ← preamble diffuse vector (default
white); `spec_intensity` ← MTRL prop[17]; `spec_power` ← MTRL prop[16] (clamp ≥1);
`f0` ← `(IOR-1)/(IOR+1)` (or a constant ~0.04 if IOR unavailable).

### 3d. Bring-up order (each an oracle-gated step)

1. Diffuse only (slot 0), flat lighting → confirms UV + texture upload + strip winding.
2. Add directional `NdotL` using vertex normal → confirms normal decode.
3. Add normal map + TBN (slot 2) → confirms tangent decode (the `dec3n` correctness gate).
4. Add spec + fresnel (slot 1 + preamble) → material completeness.
5. Later: skinning (BLENDINDICES/WEIGHT + bone matrices), shadows, env/cube (`flags&0x200`), HDR.

---

## Cross-references

- `tools/wad_simulator/crates/mercs2_formats/src/model_inject.rs` — DECL64, f16, strip, `synth_tangents`, `encode_strm`.
- `tools/wad_simulator/crates/mercs2_formats/src/texsize.rs` — DXT1/DXT5 block sizes + mip counts.
- `output/_ghidra/all_functions_decomp.txt:641924` — `Mtrl_Parse` `FUN_00858790`.
- `tools/ucfx_mesh_codec.py::parse_mtrl`, `tools/material_probe.py` — MTRL parse + slot naming.
- `docs/mercs2-pdb-analysis/rendering-shaders.md` — `PgSkin*`/normal-map shader family, pass structure.
- Memory: `dec3n-tangent-layout-bug`, `mtrl-flags-count-transposition`,
  `fun-858790-mtrl-parse-stdcall`, `xbox-pc-vertex-decl-mapping`,
  `worldload-0x84dd5b-texhandle-corruption`.
