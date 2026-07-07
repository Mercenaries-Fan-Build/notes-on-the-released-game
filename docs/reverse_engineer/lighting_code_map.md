# Scoreboard #2 — lighting: PC code map

**Scope:** the PC-side lighting subsystem in `Mercenaries2.exe` (unpacked SecuROM image
`output/_ghidra/securom_dump/mercs2_unpacked.exe`, base 0x400000) — the placed-light ECS components
(`LightObject`/`LightAnimation`), the runtime light/color/scale/alpha animations (`Rt*`), the
per-pixel-light / spot-light shader permutations (`_pl`/`_sl`/`_pl_sl`/`_li`), the render-side light
accumulation, and the sun/directional/ambient path. Binds the Xbox-PDB names
([rendering-shaders.md](../mercs2-pdb-analysis/rendering-shaders.md) §Lighting) + the ECS registry
([05_presentation_audio_fx.md](../mercs2-ecs/05_presentation_audio_fx.md)) to concrete PC addresses.
Companion JSON `docs/data/render_core_lighting_code_map.json`. Sibling render map:
[render_core_code_map.md](render_core_code_map.md). The atmosphere sun cross-links to
[sky_post_hdr_code_map.md](sky_post_hdr_code_map.md); the `_pl`/`_sl` permutation mechanism is shared
with [decal_code_map.md](decal_code_map.md) §2.

## 0. The honest boundary

The **light data and the shader-permutation registration are fully proven**: the `LightObject` /
`LightAnimation` reflection deserializers and their exact byte layouts are read from the decomp; the
`_pl`/`_sl`/`_pl_sl` light-class is the 4th arg to the shader-insert helper `FUN_0085ac90`, gated by the
`DAT_00dfc345` per-pixel-light master switch — statically proven. But the retail build strips the
`RenderLights`/`RenderLightBounds` markers (they are Xbox `.rdata` strings with **no recoverable PC
function entry**), and the actual per-light **accumulation** (which class binds per draw, how the
nearest N lights load into D3D shader constants, whether the sun lights meshes) is VMX/vtable-gated →
**confirm-live (x32dbg)** with recipes in §7. The per-frame `Rt*Animation` **apply math** is likewise
confirm-live. The shared ECS descriptor backbone (seed `0x9e3779b9` + `CopyFromStream`) is wired on every
light component below — verified, not assumed.

## 1. Light ECS components

### 1.1 LightObject — hash `0x97e8ee92`, schema `FUN_006622e0`, stride 0x34

Descriptor base `0x017beb18`, `CopyFromStream = PTR_00bc1ea0`, stride `0x34`, seed `0x9e3779b9` — the
shared reflection backbone. `FUN_006622e0` reads the stream in field order, allocates a pool slot
(vtable+0x1C), commits via `FUN_0064a600` (memcpy into the `0x9e3779b9`-hashed pool), then back-refs
`FUN_00665590(param_1, PTR_DAT_017beb1c)` (`0x017beb1c` = descbase+0x04, links template↔descriptor).
Stream-read helpers (corroborated across all ECS families): `FUN_00656210(default)` = int32,
`FUN_00656610(&default)` = rgb/vec3 (3 dwords; white default `DAT_00b9b664`=1.0), `FUN_00656320(default)`
= float.

**0x34-byte field-offset table** (13 dwords = 1 int + 3 rgb + 9 floats; matches
`mercs2_formats::placement::LightObject` `PAYLOAD_STRIDE=0x34`; **layout proven**, per-slot float
*semantics* beyond intensity/radius are **inferred** from the UE PointLight port and `placement.rs`):

| Offset | Type | Field | Default | Conf |
|---|---|---|---|---|
| +0x00 | int32 | light type / id (point/spot enum) | 0 | layout proven; semantic inferred |
| +0x04/+0x08/+0x0C | f32×3 | color R / G / B | 0.0 | proven |
| +0x10 | f32 | intensity | 0.0 | inferred (UE `Intensity`; `placement.rs intensity()=params[0]`) |
| +0x14 | f32 | radius / attenuation | 0.0 | inferred (UE `AttenuationRadius`; `radius()=params[1]`) |
| +0x18 | f32 | falloff / atten exp | 0.0 | inferred |
| +0x1C / +0x20 | f32 | cone inner / outer angle | 0.0 | inferred |
| +0x24..+0x30 | f32×4 | params 5–8 (unknown) | 0.0 | unknown → confirm-live |

All 9 floats default to **0.0** in shipping `.rdata`; live values arrive from the level stream. The
on-disk COMP record prefixes a `u32` entity key → 56-byte stride (`parse_light_records`). Registered
into the ECS component table by the bulk builder `FUN_0064ee60` (plants `FUN_006622e0` at the reflection
slot). 1,197 lights extracted from `layers_static`/`vz_state` (the villa `global_portablelight` etc.).

### 1.2 LightAnimation — hash `0xbd5349f7`, schema `FUN_00662ee0`, stride 0x2c

Descriptor base `0x017be488`, `CopyFromStream = PTR_00bc1270`, stride `0x2c`, seed `0x9e3779b9`.
`FUN_00662ee0` reads 10 floats then 1 int; commits `FUN_0064a600`; back-ref `FUN_00665590(param_1,
0x017be48c)` (descbase+0x04). (The Ghidra label `s_ARENT_MISSING_00b7ffec` is a mislabel of that pointer
address, not a real field.)

| Offset | Type | Field | Default |
|---|---|---|---|
| +0x00..+0x24 | f32×10 | keyframe times & values (animation curve) | 0.0 |
| +0x28 | int32 | loop / mode flag | 0 |

Total 0x2c = 44 B. Layout proven; semantic names inferred.

## 2. Rt* runtime animations

Four sibling descriptor registrars, each verified by its **stamped name string** + `CopyFromStream` PTR
(all match the ECS doc exactly; each writes seed `0x9e3779b9` and the shared descriptor pattern). These
are **runtime instances** (computed, not stream-authored — no `FUN_00656xxx` field reads):

| Name (stamped string) | Descriptor | descbase | CopyFromStream | stride | Compute | Apply (per frame) |
|---|---|---|---|---|---|---|
| **RtLightAnimation** (`s_RtLightAnimation_00bc5bcc`) | `FUN_00646b60` | 0x017bfc48 | PTR_00bc35d8 | 0x2c | `FUN_0066d860` | `FUN_006654b0`→`FUN_004a7c70`/`FUN_004a80d0` |
| **RtColorAnimation** (`s_RtColorAnimation_00bc5be0`) | `FUN_00646c30` | 0x017bfc98 | PTR_00bc3628 | 0x10 | `FUN_0066e580` | inline (`out = t*rate + base` → render struct +0x190/+0x198) |
| **RtScaleAnimation** (`s_RtScaleAnimation_00bc5bf4`) | `FUN_00646cf0` | 0x017bfce8 | PTR_00bc3678 | 0x14 | `FUN_0066e4a0` | `FUN_00469140(dt)` |
| **RtAlphaAnimation** (`s_RtAlphaAnimation_00bc5c08`) | `FUN_00646db0` | 0x017bfd38 | PTR_00bc36c8 | 0x14 | — | `FUN_00469200(dt)` |

**`FUN_00675e50` is the master per-frame runtime-animation Update dispatcher** (NOT
RtLightAnimation-specific, correcting the Xbox cross-ref which paired `RtLightAnimation::Update` with a
single body). Signature `void FUN_00675e50(float dt)`, sole caller `FUN_004c9740` @0x4c997d. It sweeps
~30 `Rt*`/effect component pools each frame by their `DAT_017bXXXX` count/stride triples. The
RtLightAnimation block (pool `DAT_017bfc68` = descbase+0x20) self-identifies by FNV-1a-hashing
`s_RtLightAnimation__Update_00bacac4` (seed `0x811c9dc5`, prime `0x1000193`) and dispatches the
per-instance light apply via **`FUN_006654b0`** (hash lookup) → **`FUN_004a7c70`** / **`FUN_004a80d0`** —
the actual light-math apply (**confirm-live**). RtLightAnimation runtime compute `FUN_0066d860` pulls
actor state (`FUN_005857e0` → `FUN_004a7a50`) and commits via `FUN_0064a600` against counter
`DAT_017bfc64`.

## 3. RtAmbience — not located on PC

`RtAmbienceUpdate` (0x2f270) / `RtAmbienceCollect` (0x2f284) exist only as **Xbox `.rdata` name
strings**. **No PC `FUN_` binding found** — a ghidra search returned only CRT noise, and unlike
`RtLightAnimation::Update` there is no inline FNV-hashed name string pointing to an ambient-gather
function. The ambient data itself is the designer-tunable `.rdata` block `AmbientCube0..5` /
`AmbientColor` / `AmbientColorMultiplier` (@0x003c9a8..0x003cab0), modeled in
`mercs2_formats::atmosphere::ambient_cube`. RtAmbience apply is **confirm-live / not-yet-located**
(locate by breaking a per-frame reader of `AmbientCube*` @0x003c9a8 and walking callers).

## 4. Shader light permutations (proven)

The permutation family registers inline in the global shader registry **`FUN_0084f130`** (render map
§4). Every shader is inserted by **`FUN_0085ac90(logical_name, name.sho, light_class)`** whose 3rd arg
**is** the light class (proven: `param_4 → record[0x23]`; name→FNV handle via `FUN_00824270`; insert
into pool `DAT_01977a38`):

**`light_class ∈ {0 = base, 1 = _pl (point), 2 = _sl (spot), 3 = _pl_sl (both)}`** — matches
[particle_fx_code_map.md](particle_fx_code_map.md) §4 and `particle_fx_shadow_code_map.json`.

Registration pattern per lit material FP (verbatim; first occurrence `PgFastFP`):

```c
FUN_0085ac90(s_PgFastFP,        s_PgFastFP_sho,        0);        // base — ALWAYS
if (DAT_00dfc345 != '\0') {                                       // ← per-pixel-light MASTER gate (ShaderLevel)
    FUN_0085ac90(s_PgFastFP_pl,    s_PgFastFP_pl_sho,    1);      // point
    if (DAT_01970a2c == 0) FUN_0085ac90(s_PgFastFP_pl, s_PgFastFP_pl_li_sho, 1);   // _li alternate blob
    FUN_0085ac90(s_PgFastFP_sl,    s_PgFastFP_sl_sho,    2);      // spot
    if (DAT_01970b28 == 0) FUN_0085ac90(s_PgFastFP_sl, s_PgFastFP_sl_li_sho, 2);
    FUN_0085ac90(s_PgFastFP_pl_sl, s_PgFastFP_pl_sl_sho, 3);      // both
    if (DAT_01970c24 == 0) FUN_0085ac90(s_PgFastFP_pl_sl, s_PgFastFP_pl_sl_li_sho, 3);
}
```

This 7-call block repeats for ~40 lit FPs: `PgDiffFP`, `PgDiffEmisFP`, `PgDiffSpecFP`,
`PgDiffSpecNormFP`, `PgDiffSpecReflFP`, `PgDiffSpec{Metal,SSS}*RimFP`, `PgDiff{AmbOcc,EmisAmbOcc,
SpecNormAmbOcc}RimFP`, … .

**Gate taxonomy (proven):**

| Gate | Address | Role |
|---|---|---|
| per-pixel-light master ("ShaderLevel") | `DAT_00dfc345` (bool) | `!=0` → register the whole `_pl`/`_sl`/`_pl_sl` family per FP; `==0` → base only (no dynamic per-pixel lights). Mercs2.ini `ShaderLevel` (render map §9). |
| `_li` alternate selector | per-shader `DAT_019xxxxx` (`01970a2c`, `01970b28`, `01970c24`, …) | `==0` → also register a `_li` `.sho` under the **same** (name, light_class), overriding the plain variant (an alternate compiled blob) |
| AmbientWind / veg VP quality (orthogonal) | `(DAT_01176288+0x5e4 >> 2 & 1)`, bit 3 | selects `*AmbientWind*.sho` VP variants — a VP-side axis, independent of light class |

| Shader / permutation | Register site | Gate | Conf |
|---|---|---|---|
| mesh `PgFastFP` / `_pl`/`_sl`/`_pl_sl` | `FUN_0085ac90` @ `FUN_0084f130` | `DAT_00dfc345` | high |
| mesh `PgDiffSpecNormFP` / `_pl`/`_sl`/`_pl_sl` (+`_li`) | same (`_li` gated `DAT_0196bd34/be30/bf2c`) | `DAT_00dfc345` | high |
| decal `PgDecal2FP` / `_pl`/`_sl`/`_pl_sl`/`_li` | `.sho` descriptor-table rows @0x0103xxxx; helper `FUN_02475bc0`; shared `FUN_0085ac90` | `DAT_00dfc345` | med ([decal_code_map.md](decal_code_map.md) §2) |
| water `PgWaterFP_LI` | water sub-registrar `FUN_00484380` | `_LI` gated `DAT_01286310` | high |

(Note: mesh `_li` = an alternate blob under an existing light-class; water `_LI` = a light-enabled water
variant — both "light" suffixes at different layers.)

## 5. Light accumulation / RenderLights — confirm-live

**Xbox `RenderLights` (0x26b28) / `RenderLightBounds` (0x26b14) do not bind to PC code** — those RVAs are
`.rdata` symbol offsets in the Jul-08 devkit inventory, not function entries; no decompiled PC body
carries the markers (retail-stripped) and the accumulation math is D3D-constant/vtable-gated.

What *is* proven: the placed-light data path (§1.1) and that the **shaders accept point/spot lighting**
(the `_pl`/`_sl`/`_pl_sl` classes, §4). The per-draw selection of *which* class handle binds (base vs
`_pl` vs `_sl` vs `_pl_sl`) is a material-resolve decision at draw — the material resolves a shader by
name→u16 via **`FUN_0085abd0`** (u16 at `rec+2`; ~120+ call sites are the material bind points). **Which
of the 4 class handles it picks, and how the nearest lights load into shader constants, is stripped /
vtable-gated → confirm-live.** (`FUN_0085aff0` is a *sibling* multi-handle resolver but it is the
**post-process** effect object storing 15 shader handles at obj+0x94..+0x104 — do not conflate it with
the mesh per-light bind.)

## 6. Sun / directional / ambient

The directional "sun" lives in the atmosphere params struct at `*(int*)(PTR_PTR_00e7adfc + 0x104)`
(manager singleton `PTR_PTR_00e7adfc`) — fully mapped in [sky_post_hdr_code_map.md](sky_post_hdr_code_map.md)
§1–2, cross-linked not duplicated. Sun fields relevant to shading:

| Field | Setter (PC) | Struct off | Staging global |
|---|---|---|---|
| LightIntensity | `0x5b1830` | +0xe0 | 017baa60 |
| LightModifier | `0x5b18a0` | +0x124 | 017baa84 |
| LightAngle (sun dir) | `0x5b1970` | (angle→dir) | — |
| AmbientColor | `0x5b19e0` | — | 017ba9f0 |
| AmbientCube (6×) | `0x5b1a80` | — | 017baa08.. |
| RimColor | `0x5b1b20` | — | 017baa70 |

Setters write the live struct immediately or **stage into the mirror block `DAT_017ba9d0..017baa94`** for
time-of-day interpolation (`Graphics.Atmosphere.*` Lua binding table @0xb9a570). **Proven read-at-draw
for the sky/cloud path:** the cloud pass `FUN_0047e7f0` reads the live struct (`+0x20/+0x28/+0x40/+0x70/
+0x7c` = colors/sun/scatter) into cloud constant buffers. Whether these same sun/ambient fields bind to
the **mesh** lit-FP constants at draw (vs only sky/clouds) is **confirm-live** — the mesh color pass is
handle-resolved/vtable-gated. The engine's current stand-in is one fixed directional + ~0.35 ambient
(`rendering_fx_lighting_gap.md` §C).

## 7. Confirm-live inventory (x32dbg, read-only while PAUSED; PMC villa / `global_portablelight` resident)

| Target | Site | Break recipe |
|---|---|---|
| LightObject float-slot pinning | `FUN_0064a600` when the committing template is `FUN_006622e0` (or dump pool @descbase `0x017beb18`) on a known-value light | fix params +0x18..+0x30 (falloff / cone / unknowns) and the +0x00 point-vs-spot enum |
| master per-frame `Rt*` Update | `FUN_00675e50` | observe which `Rt*` pools are non-empty + `dt` |
| RtLightAnimation apply (light-math) | `FUN_004a80d0` / `FUN_004a7c70` (via lookup `FUN_006654b0`) | inspect the 0x2c record + the resolved LightObject to pin the light-math |
| RtScale / RtAlpha apply | `FUN_00469140` / `FUN_00469200` | confirm which record floats drive scale vs alpha |
| per-draw light-class shader select | material resolve `FUN_0085abd0` | on a lit interior draw read the resolved u16 at `rec+2` + requested name → which of base/`_pl`/`_sl`/`_pl_sl` |
| light-constant bind / "RenderLights" body | HW-watch the light-list buffer built after `FUN_006622e0` records load | find the color-pass reader that loads D3D light constants — the PC `RenderLights` analog |
| sun → mesh | atmosphere struct `[[PTR_PTR_00e7adfc]+0x104]+0xe0/+0x124` on a paused lit-mesh draw | check whether LightIntensity/Modifier appear in the mesh FP constant registers (vs only sky/cloud CBs @`DAT_00ff46c8`) |
| RtAmbience | per-frame reader of `AmbientCube*` @0x003c9a8 | walk callers to locate the ambient-gather |
| decal `_pl`/`_sl` table walk | decaltable resolver `FUN_004cb1f0` + `0x0103xxxx` `.sho` table | see the decal light-class row selection ([decal_code_map.md](decal_code_map.md) §2/§4) |

## 8. Faithful-reimpl note

The Rust `mercs2_engine` (scoreboard 🟡) already parses `LightObject` (0x97e8ee92) and does up-to-32
forward point lights + a fixed sun + Blinn-Phong spec (`_sm` slot 1). This map gives the exact data and
the missing structure: the **0x34 LightObject layout** (with the light-type enum + cone slots still
confirm-live), **LightAnimation** (0xbd5349f7) flicker/pulse curves + the `Rt{Light,Color,Scale,Alpha}
Animation` runtime dispatcher `FUN_00675e50`, the **`_pl`/`_sl`/`_pl_sl` light-class shader family**
(gated by `DAT_00dfc345` ShaderLevel — the original's forward per-pixel point/spot path, implying
per-light passes rather than one übershader), and the **atmosphere sun/ambient-cube** feed. The point-vs-
spot enum, the cone float semantics, and how N lights load to shader constants per draw are the
confirm-live remainder (§7), per `rendering_fx_lighting_gap.md` §C.
