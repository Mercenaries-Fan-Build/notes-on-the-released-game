# Mercenaries 2 PC v1.0 particle sim: units and operators

Grades: **PROVEN** = read this run (instruction, byte, or dump number); **INFERRED** = reasoned from proven
parts, not exercised; **SPECULATIVE** = guess. Addresses are `pc-v10`. Disassembly of code Ghidra has no
function for was read with capstone over `game-files/memory-dumps/ada55455_disc/pmc/image.bin`.
Dump numbers come from `updated-chris-exports/20261021_chris-jacobs-{flying-winch,mid-mission}.dmp`.

## 0. What was found that the docs did not have

- **The integrator is `FUN_00876840`** (5,812 bytes). Chain: job `FUN_008780d0` → `FUN_00878060` →
  `FUN_00877f10` (cull + per-particle loop) → `FUN_00876840`.
- **`FUN_00724570` (job `FUN_00724c20`) builds the render copy.** The docs called the `0x724xxx` jobs
  AnimCpu candidates; `FUN_00489dd0` registers them with the FX jobs and they are particle jobs.
- **`PTYP` bit 0 is NOT additive.** It is velocity alignment (`FUN_00494740`, `0x00494802`).
- **Additive vs alpha is the SIGN of the COLR binary16**, and its magnitude is an HDR colour multiplier
  (`PgFXVP`, §9).
- **The dumps hold live particles**: 5,352 in flying-winch, 2,493 in mid-mission, plus their emitters, instances
  and forces. Numbers below were read out of them.
- **Six unresolved hashes crack**: `forcegravity[var]`, `forcewind[var]`, `forcedrag[var]`. Context proves
  them (slot read by that force's arm). Not added to the rainbow files: this task is read-only.

## 1. Field table

Slot = offset in the 0x210 runtime emitter. Attribute slot layout: `+0 value, +4 curve index, +8 flag nibble,
+0xC var, +0x10 var's flag bit 7, +0x11 var==0` (`FUN_00493150`, `FUN_004934f0`, `FUN_00493550`).

| Field (hash) | Slot | Unit | Operator, when | Grade | Evidence |
|---|---|---|---|---|---|
| `rate` / `ratevar` | `+0xC0` | particles per second | `accum += (max(rate+ratevar(1-2u),0)·+0x7F0 + moved·+0x7F4)·density·dt`, each update, at emitter time | PROVEN | `FUN_0048f4f0`; 16 steady live emitters: N ≈ instances·rate·mean life within 5% (2,147 vs 2,153; 253 vs 253; 89 vs 89). 7 others are 10–30% low; their instances vary in start time, cause not checked |
| `life` / `lifevar` | `+0x110` | seconds | at spawn, emitter time, clamped ≥ 0; stored `+0x24` | PROVEN | `0x0048C81B`; live life 30.0, age 26.19 at effect clock 26.84 |
| `speed` / `speedvar` | `+0xD4` | m/s | at spawn, emitter time, multiplies direction | PROVEN | `0x0048FF37`, `0x0048FFF0`; live speed 1.59–2.41 for speed 2 under gravity/drag |
| `spread` / `spreadvar` | `+0xE8` | degrees, cone half-angle | per emitter per update; `×0.0174533`; θ uniform in `[0,spread)`, φ uniform in `[0,2π)` | PROVEN (deg), INFERRED (distribution, decomp only) | `0x0048FD1F`; `FUN_00488890` |
| `emissiondir` | effect `+0x94` bit 0 | 0 vs non-zero | non-zero on any emitter: identity rotation for the whole effect; 1 and 2 are the same | PROVEN | `0x00492C12`, `FUN_0048f4f0` |
| `inheritvel` / var | `+0xFC` | percent | `v += instVel·iv·0.01`, at spawn | PROVEN | `0x0048FF9A`–`0x0048FFC6`, `0.01` at `0xB97EEC` |
| `size` / `sizevar` | `+0x124` | metres, full quad edge | render time; 100-sample curve at `99·age01` lerped, plus `var(1-2r/255)` | PROVEN op; INFERRED metres (§11) | `FUN_00490d90` resampled arm, `PgFXVP` |
| `mass` / `massvar` | `+0x160` | kg-like | at each step; `m = v + var·U` | PROVEN | §6 |
| `scale` `0xEEE1A341` | `+0x1F0` | sim updates per flipbook frame | `wrap = byte(scale·n)` at `+0x204`; `frame = counter/scale` | PROVEN | `0x00493020`, `0x004947A2`; live 3·30=90, counter 0–89 |
| `0xC3592BB7` | `+0x1EC` | material index | index into `0xD2AE50`: 0,1,2 = `PgFXVP`, 3 = `PgFXVPR` refraction | PROVEN | `0x004942D4`, `0x00493BFE`, table read from dump |
| `name` `0x1DE5C824` | `+0x1F4` | hash | stored | PROVEN | `0x00492C58` |
| `forcegravity`/var `0xC558C9D8`/`0xD80DF37F` | `+0x1C4` | factor on gravity | per particle, per step | PROVEN | `0x00876E98`, §5 |
| `forcedrag`/var `0x6CF0BE14`/`0xBE968D3B` | `+0x19C` | factor on drag | per step | PROVEN | `0x00877020`, §5 |
| `forcewind`/var `0xB3DBB6C0`/`0x4C49B137` | `+0x1B0` | factor on wind and blasts | per step | PROVEN | `0x00876F2D`, `0x00877D35` |
| `0x10831673`/`0xB6197EFE` (name unknown) | `+0x174` | factor on attractor | per step | PROVEN | `0x008773DD`, `0x00877223` |
| `0x720F22F8`/`0x4712719F` (name unknown) | `+0x188` | factor on vortex | per step | PROVEN | `0x0087780E`, `0x00877A21` |
| `0x497A1895`/`0x1792B524` | `+0x138` | spin, degrees per second | `angle = rot0 + age_seconds·spin` | PROVEN | `0x007246C8` |
| `0x35ACBAB7`/`0x1B878602` | `+0x14C` | start angle, degrees | as above; both read at t=0, so a curve gives its first sample only | PROVEN | `0x00724620`, `0x0072464C` `fldz` |
| `0x2F68CD8F` (drag extra) | force `+0x8C` | metres, radius | `drag = ampl·r²·π` | PROVEN | `0x00492353`, `FUN_0048a820`; live 2.356 = 75·0.1²·π |
| Force `ampl` | force `+0x80` | see §5 | at emitter time each frame | PROVEN | `FUN_0048a820` |
| Force `rotx..z` | `+0xE0..` | degrees | `×0.0174533` | PROVEN | `0x0048AA0C` |
| TRFM `rot*` | `+0x74,+0x80,+0x8C` | degrees | `×0.0174533` | PROVEN | `0x0049175D`, `0x00491780`, `0x004917A0` |
| TRFM `pos*` / `scl*` | `+0x50..`, `+0x98..` | metres / factor | evaluated each update | PROVEN | `FUN_004916f0` |

`effect_container_format.md` §3's "handler" column: `0x4935C0` loads a curve into the table at effect `+0x20`
(emitter time), `0x4935E0` into `+0x60` (stream, age), `0x493620` into `+0x40` (particle-age linear, empty in
retail: EFCT words 5 and 6 are 0), `0x493600` and `0x493640` load the var. PROVEN (`hall.asm`, `ldr2.asm`).

No unit conversion on load: effect `0x02D849BD` bytes (`rate` 187.5, `speed` 9 ± 2, `life` 1.9 ± 0.2, `spread`
10 ± 2, `ampl` 9) equal the runtime slots. PROVEN.

## 2. Time

- `dt` = `(previous frame + this frame)/2`, seconds. `FUN_0048e550`: `+0x90`, `+0x94`, `ctx+0xB0`
  (`ctx = mgr+0xD2950`, `mgr = 0x01583440`). PROVEN: live 0.0232480, 0.0194803, 0.0213641.
- Variable step, not fixed. Live dt 0.0160–0.0232 s in gameplay, 0.005 s in the PMC captures. No clamp found on the
  path read. PROVEN for the values; INFERRED for "no clamp": `FUN_004c9740`'s source of `uStack_8` was not traced.
- Emitter clock `+0x7F8 += dt`, at the end of `FUN_0048f900`, even when the emitter is idle. PROVEN.
- Age: `+0x18 += dt`, in `FUN_00876840`. PROVEN live: `age01·life = age − dt` to 1e-6 over thousands of particles,
  and minimum age equals dt, so a new particle gets one step the frame it spawns.

## 3. Curves

`AKEY` time has two meanings by table:

| Table | Evaluator | x | Between keys | Past the ends |
|---|---|---|---|---|
| linear, effect `+0x20`: rate, speed, spread, inheritvel, life, FRCE, TRFM | `FUN_00490960` (+ variance), `FUN_00490ab0` (no variance) | `seconds × 60` (`0xD2D898` = 60.0; every xref is a read) | linear | holds first / last key |
| resampled, effect `+0x60`: size, spin, rot0 | `FUN_00490d90` | index `99·age01` | linear between samples | index capped 99 |

- Loader resample (`FUN_00493150`, flag bit 8): 100 samples at key time 0, 1, … 99; clamps both ends. So keys are
  percent of life. PROVEN.
- Retail times 0–100 on a linear table are **frames at 60 Hz: 1.67 s, then the last key holds**. There is no loop
  in any evaluator. PROVEN.
- Linear lookup: first key with `time > x`; `i == 0` lerps from `(0, keys[0].value)`. PROVEN (`0x004909F0`).
- One key: that value. Zero keys: 0. PROVEN.
- `FUN_00490960`: `value + var·(1 − 2u)`, `u` from LCG `0xDFCBB8`, re-rolled each call. PROVEN.
- Flag nibble: `b7<<3 | b10<<2 | b8<<1 | b9`. Bit 10 = has curve, bit 8 = resampled. Bits 7 and 9 have no reader in
  any function read this run. INFERRED authoring-only.

**Per-particle random:** one byte `r` (`+0x20`), set at spawn, drives every per-particle variance: size, mass and all
five force factors, spin, rot0. `U = 2·(0.5 − r/255)`. So they correlate. PROVEN (`0x00876981`, `0x0048C868`).

## 4. Effect end

- Duration `+0x7FC` comes from the template's `RedEffectComponent`, not the effect: if `+0x18 != 0`,
  `+0x10 + (1−2u)·+0x14`, else 0 (`FUN_00488d70`). Effect bytes hold no duration. PROVEN.
- `FUN_0048f4f0`: `dur>0 && t>=dur` stops emission; the instance dies once no particle touched it. `dur<=0`: it dies
  when `t > 3.0` (`0xBA8990`) and no particle is alive. PROVEN. Live: `dur` 0 at t 26.8, `dur` 10 at t 0.33.
- So there is no looping flag: an effect emits as long as its held-last `rate` is above 0, and a burst is a `rate`
  curve that ends at 0.
- `+0x7F0`: 1.0 at spawn, then `FUN_00675e50` copies a runtime component field each entity update. Multiplies rate.
  1.0 in every live instance read. PROVEN.
- `+0x7F4` = per-metre rate from `RedEffectComponent +8`. `moved = min(|Δpos|, dt·200)`. PROVEN (`0xB984A8` = 200,
  `FUN_00401740` is `fsqrt`).
- `density` `0xD2AE6C` = `quality·0.5·0.8 + 0.2`, clamped 0–1: 0.2, 0.6, 1.0. Live 1.0. PROVEN. Use 1.0.
- Caps: 2,000 per update per emitter (doc), 15,000 live globally (`FUN_0082d040`; buffers 720,000 = 15,000·0x30). PROVEN.

## 5. Forces

Runtime record at instance `+0x20 + i·0xC0`, rebuilt per frame by `FUN_0048a820` at emitter time. Force count is
`+0x804 & 0xF`. In order: `ampl +0xA8, range +0xAC, decay +0xB0, radial +0xB4, local +0xB8 (byte, value != 0),
type +0xA4, pos +0x80, dir +0x8C, local→world +0x00, world→local +0x40`.

`S` below is the emitter factor at the particle: `value + var·U`. All are accumulated into `F`, then divided by mass
at integration. PROVEN unless noted.

| Kind | Operator | Live |
|---|---|---|
| gravity, 1 | `F += (0,−1,0)·ampl·forcegravity·m`. So `a = −ampl·forcegravity` m/s², **mass cancels**. FRCE direction ignored. | slope −2.0043 vs −2.0 (r² 0.994), −8.98 vs −9.0; **mass 2.0** emitter: −4.34 and −4.23 vs −4.5 with a small drag, not −2.25 |
| wind, 0 | **FRCE values ignored**: `w = *(0xE7ADFC)+0x104`, `ampl = |(wx,wz)|·speed·100`, dir its unit XZ. `F += dir·ampl·forcewind`; `windSum += sqrt(ampl)` | global (0.958, 0.287), 0.003 → ampl 0.3, dir matches |
| drag, 2 | `ampl_eff = ampl·r²·π`. `c += ampl_eff·forcedrag`. Quadratic, applied at integration | 2.356, 0.314, 0.0314 = 75, 10, 1 · 0.01 · π; slope 2.39 vs 2.356 (r² 0.003, weak) |
| attractor, 3, `local` | `d = x − pos`, `r=|d|`. Skip if `range < r`. `a' = ampl·falloff`. `F += d·(S·a')/(r³+1)`. Positive repels | not exercised |
| attractor, `local` = 0 | `F += d·(S·ampl)/(r²+1)`; no range or decay | not exercised |
| vortex, 4, `local` | Skip if `range < r`. In force space: `x', v'`. `W = (a',0,0)`, `R = normalize(0, x'.y, x'.x)·radial·5`. `F += S·L2W(W × v' + R)` (rotation only). The `x'.x` in Z is what the code does | not exercised |
| vortex, `local` = 0 | `F += (d × v + normalize(d)·radial)·S·ampl/(r³+1)` | not exercised |

- `falloff`: `t=r/range`; `decay >= 0`: `pow(1−t, decay)`; else `pow(t, −decay)` (`0x008771C0`, `__libm_sse2_pow`).
- The softening is **1.0**, not an epsilon (`0xBEA990`).
- Force space: `R(rotx,y,z)·T(posx,y,z)·R(instance)·T(instance)`. PROVEN by decomp; live `pos` = instance position.
- Blast spheres (`+0x804` bits 4–7), only for effects with a wind force: up to 4 from `FUN_004b0d30`.
  `F += d·s(1−r/R)·forcewind/(r³+1)`. Skip in the Workshop.

## 6. Integration

Semi-implicit Euler with a linearised drag denominator. `dt` per update, no substeps. PROVEN (`0x00877D87`–`0x00877EDA`).

```rust
// Per frame, per instance: forces rebuilt; emitter clock t in seconds.
// 1. accumulate
accum += (eval(rate, t).max(0.0) * emit_scale + moved * per_metre) * density * dt;
n = min(trunc(accum), 2000); // and 15000 total live
// 2. spawn, for each emitter
spread = eval(spread, t) * 0.0174533;
m = trfm_matrix(t) * instance_matrix;            // §7
for i in 0..n {
    rec = shape[rand % count];                   // uniform: float 0 (area) is not a weight
    (p, normal) = point_on_triangle(rec);
    u = rand01();
    x = transform_coord(p, m) - delta_pos * u;   // smear along last frame's motion
    dir = normalize(transform_normal(normal, m));
    if dir.length_squared() < 0.99 { dir = (0, 1, 0) }
    life = eval(life, t).max(0.0);
    v = perturb(dir, spread) * eval(speed, t) + inst_vel * eval(inheritvel, t) * 0.01;
    r = (lcg >> 16) as u8;
    frame = r; age = 0.0;
}
accum = (accum - spawned).max(0.0);
t += dt;

// 3. step every particle
if age > life { swap_remove; continue }          // tested before the step
a01 = age / life;
U = 2.0 * (0.5 - r as f32 / 255.0);
mass = m_value + m_var * U;
F = 0; c = 0; wind_sum = 0;
for f in forces { apply §5 }
if wind_sum > 0.0 { c *= wind_sum }
speed = |v|;
if mass < c * dt * speed { c = mass / (speed * dt) }
F -= v * c * speed;
v += F * ((dt / mass) / (1.0 + c * dt / mass));
age += dt;
frame = (frame + (dt > 0.0) as u32) % wrap;      // wrap = (scale * n_frames) as u8
x += v * dt;                                     // new v
```

- `perturb`: axis ⟂ dir; rotate dir by θ uniform in `[0,spread)`, then about dir by φ uniform in `[0,2π)`.
  INFERRED from the decomp of `FUN_00488890`; half-angle sine table 8192 entries.
- `inst_vel`: `Δpos/dt`, 0 on the first update. Above 200 m/s the code stores `unit·200/dt`; decomp only.

## 7. Emitter placement

`world = p · S(sclx,y,z) · R(q) · T(posx,y,z) · R(instance) · T(instance)` (D3D row vectors). `FUN_004916f0`,
`0x0048FDBF`. PROVEN.

`q` (`FUN_00823370`) = `qx ⊗ qy ⊗ qz` Hamilton, args rotx, roty, rotz, proven from the arithmetic. In row-vector
terms that rotates about Z, then Y, then X. INFERRED from that product.

Channels are evaluated without variance at emitter time. TRFM scale moves positions and bends directions; it does not
scale particle size. The 64-byte TRFM body (`+0x10`) has no reader on this path. `emissiondir != 0`: instance rotation
is identity. PROVEN.

## 8. Colour

- `FUN_00493660`, key index `99·min(age01,1)`, lerp to next (capped 99), 8-bit fraction `trunc(f·255)`, `(c1−c0)·f>>8`.
  Order B, G, R, A = `D3DCOLOR`, which agrees with the live test. PROVEN.
- The binary16 is **not** lerped: taken from the floor key. It goes to vertex `+0x1C`. PROVEN.

## 9. Vertex and shader

Decl (`0x02470B10`): `+0` half4 rect, `+8` colour, `+0xC` float4 pos.xyz + size, `+0x1C` half2, `+0x20` ubyte4
(corner, unused, sin byte, cos byte). `+0x1E` = view depth; `PgFXVP` does not read it. PROVEN.

`PgFXVP` (`shaderforge disasm`, record 346):

```text
D      = right·c.x + up·c.y           c in (±0.5, ±0.5)
offset = D·cosθ + (D × forward)·sinθ  sin,cos = byte/127 − 1
pos    = v0.xyz + offset·size         so a quad edge is `size`
colour = rgb · |h16|, alpha unchanged
o1.w   = h16 < 0 ? 0 : 1              inscatter also ×o1.w
```

`PgFXFP` (344): `rgb = tex·colour·atten + inscatter`, clamped 1e-5–30000; `oC0.rgb = rgb·a`; `oC0.a = a·o1.w`.

**So `h16 < 0` writes alpha 0: additive under premultiplied blending, `h16 > 0` is premultiplied alpha.** Shader
PROVEN; the blend factors `(ONE, INVSRCALPHA)` are INFERRED (§11).

Census, all 820 COLR bodies: every body is one sign: 638 positive, 182 negative. PROVEN. Magnitudes reach at least 96.
Corroboration, `global_explosion_c4`: fire −20 (orange), smoke +1.0 (dark grey), −5; god-ray −1.

## 10. Frames, rotation, PTYP

| `PTYP` | Runtime | Meaning | Grade |
|---|---|---|---|
| bit 1 clear | `+0x206`=0 | frame = 100-rect slot `trunc(99·age01)`, capped 99: `n` frames across the life | PROVEN `0x00500F26` |
| bit 1 set | `+0x206`=1 | flipbook: rect `counter/scale`. Advances one per **sim update**, so speed follows frame rate. Start phase is random | PROVEN `0x00500F0A`, `0x0048C86B` |
| bit 0 clear | `+0x205`=0 | rotation from `angle` (§1) | PROVEN |
| bit 0 set | `+0x205`=1 | rotation replaced by screen-projected velocity | PROVEN `0x00494802` |

- `angle`: `trunc`, wrapped through a table at `0xE900A8` by degree: `(127.5(1+sin), 127.5(1+cos))`. PROVEN: entries at
  0°, 90°, 180°, 270° read.
- Velocity align: `R'`, `U'` = camera right and −up rotated 45° about forward (`FUN_00493d50`). `Cx=R'·v`, `Cy=U'·v`,
  `L=√(Cx²+Cy²)`. `L>0`: `sin=Cy/L`, `cos=Cx/L`. `L=0` keeps `angle`. PROVEN for the bytes; the 45° direction comes from
  `FUN_008234c0`, decomp only.

## 11. Unpinned, and the read that settles each

| Item | Live read |
|---|---|
| Blend factors. Material dwords at `0x01439F70+0x10C` (`0x0F, 2, 7, 5, 7, 4, 0, 7, 6, 1`) are undecoded | Single-shot BP `0x00493C48` while a fire draws; read device `D3DRS_SRCBLEND`, `DESTBLEND`, `BLENDOP`, `ALPHABLENDENABLE`, or PIX |
| `right`/`up` unit length, so `size` = metres. `view+0xAF0` was identity at index 0 in the dump | Same BP: read `c12..c14`, or `[esi+0xAE0]` at `0x00493B79` |
| Velocity-align 45° sign | Same BP: read `[ebx+0x22C..0x240]` beside the camera matrix |
| Spawn modes other than 0. Live instance mode 6, effect `0x59A24324`, `rate` 0 with curve, used `FUN_004989d0`/`FUN_00498fb0` | Static: read those; live: BP on `FUN_004989d0` |
| `block+8 != 0`: dt forced to 1/30 (`0xBEAB14`), skipped by `FUN_00724570`. 0 in every block read | Static: `FUN_0048c4c0`, `FUN_004904d0` |
| ATRB bits 7, 9; var's `+0x10` byte | Static: HW read watch on `+0xD0` during a load, or a wider grep |
| Names of `0x10831673`, `0x720F22F8`, spin, rot0, `0xC3592BB7`, `0x2F68CD8F` | Name search; about 1,300 candidates failed. Pattern `force*` suggests the attractor and vortex pair |
| `dt` source and any clamp above `FUN_0048e550` | Read `FUN_004c9740`'s `uStack_8` |
| Merge of per-thread `alive` flags into `0x0140A5F8` | Static: find the merge; assumed after the sim job |
| Attractor and vortex numerically | Forward-simulate one particle across two captures of the same frame pair (none exist); or BP `0x00877C7D` once |

Job order, rate → grant → spawn → sim → render list, is INFERRED from the handlers plus age min = dt. The chain enqueuers
`FUN_0082c190`–`FUN_0082cbc0` were not read.

## 12. Effect on existing code and docs (not changed)

- `particles.rs`: `from_effect` blend from `PTYP` bit 0 is wrong; use the COLR sign. Its drag (`v *= 1 − drag·dt`) is the
  wrong law. Wind from FRCE is wrong. `gravity` magnitude ignores `forcegravity`.
- `effect_container_format.md`: §2 "how the renderer indexes the slots" is answered; `PTYP` meaning; §6 binary16; `scale`,
  §5.2 names and §7 force parameters (body values are load-time only for `FUN_0048a820`'s fields).
- `particle_fx_code_map.md` §6, §7 and `pimp_job_system_code_map.md` (the `0x724xxx` trio).
