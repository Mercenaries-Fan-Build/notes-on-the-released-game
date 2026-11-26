> SUPERSEDED IN PART by `../s2_step_integrate_spec.md` §3.3: §7's 8EE2D0 side is now transcribed from disassembly. The x87 precision in force is 53-bit on the main thread (spec §6.2).

# FUN_008EC5B0: single-object integrator (pc-v10), port-ready transcription

Source of truth: `objdump -d --x86-asm-syntax=intel` of 0x8EC5B0–0x8EDCDA (`s2/dis_8ec5b0.txt`, 1664 lines). Helpers come from
`s2/dis_h_*.txt`. Constants are read from the exe file (`s2/consts_8ec5b0.txt`, `consts_8ec5b0_b.txt`). The .data constants were
re-read from the capture (`cap_bf65a0.txt`, `cap_cdca20.txt`) and are identical there.

The bit-exact replay against the captured boat is `s2/replay_8ec5b0.py` → `replay_8ec5b0.txt`.

Grades: P = PROVEN this run, I = INFERRED, S = SPECULATIVE. Havok field names come from the reflection tables (`classes_needed.txt`),
except where marked "recall".

## 0. Signature and frame

`int __cdecl FUN_008EC5B0(solverInfo* si, hkStepInfo* step, hkVector4* gAccPerStep, hkpEntity** ents, int n, int motionOffset)` — P.
- The argument order comes from the call at 0x900386 in `FUN_009001B0`: (world+0x1A0, world+0x190, world+0x1C0, island+0x48,
  island+0x4C, 0xD0).
- `gAccPerStep` is world+0x1C0 = solverInfo+0x20. It is written by `FUN_008F72C0` as gravity·stepInfo.dt (all 4 lanes).
- Per body, `m = ents[i] + motionOffset` (0x8EC5DE–0x8EC5E3). All offsets below are relative to m, the hkpMotion; ms = m+0x10 is the
  hkMotionState.
- The body loop runs i = 0..n−1 (counter at [esp+0x7C], 0x8ED CBB–0x8EDCC4).
- Arithmetic is **x87** throughout. The exceptions are the quaternion multiply, the normalize and the R^T·v helper, which are
  **SSE scalar** (single precision).
- Persistent FPU stack at the loop head: {0, 0, 1} from `fld1; fldz; fldz` at 0x8EC5D8. The paths consume these 1.0/0.0 values as
  their "1" and "0". The values are exact, so the port can use literals.

## 1. Dispatch on motion type (m+0x08) — P (jump table at 0x8EDCDC = {0x8ED256, 0x8EDCBB, 0x8EC5FD, 0x8ED176})

| type | entry | does |
|---|---|---|
| 0–5 (incl. **4 BOX_INERTIA**, the boat) | 0x8ED138 (`ja` default) | gravity → damping → common integrate (§3) → deactivation (§4) |
| 6 KEYFRAMED | 0x8ED256 | pops two stack slots; **no gravity, no damping**; common integrate + deactivation |
| 7 FIXED | 0x8EDCBB | skipped entirely; also does **not** take part in the return-value minimum |
| 8 THIN_BOX_INERTIA | 0x8EC5FD | its own inlined copy (§5) |
| 9 CHARACTER | 0x8ED176 | damping only (no gravity) → common integrate + deactivation |

- There is no inertia handling on the box path. Box, sphere and stabilized types share exactly the same code — P.

## 2. Gravity and damping (box path) — P

```
// 0x8ED138..0x8ED170: gravity, all 4 lanes, x87, stored as float each
v[k] = f32(gAccPerStep[k] + v[k])            k = 0..3      (v = m+0xD0 linearVelocity)
// 0x8ED176..0x8ED254: damping
dt = step->deltaTime (step+8)
lf = f32(1.0 - (linearDamping(m+0xB4) * dt))  // the product is NOT rounded to float before the subtract
if (!(lf < 0)) {} else lf = 0                 // fcom with 0, test ah,5 / jp: lf<0 -> 0; NaN keeps NaN
v[k] = f32(lf * v[k])                         k = 0..3 (w included)
af = f32(1.0 - (angularDamping(m+0xB8) * dt))
af = (af < 0) ? 0 : af                        // same compare pattern
w[k] = f32(af * w[k])                         k = 0..3      (w = m+0xE0 angularVelocity)
```

- Boat: lf = 1 exactly, so linear damping 0 has no effect.
- af = f32(1 − 0.8·dt); for dt = 0.016613 that is 0.98671.
- Gravity is added **before** damping, so the gravity increment is also damped.

## 3. Common integrate (0x8ED25A..0x8ED948; box, keyframed and character) — P

### 3.1 Finiteness guard (0x8ED25A–0x8ED568)

For each lane k = x, y, z, w (bits 8, 4, 2, 1):
- `okAbs_v[k]` = |v[k]| < 1e6. The compare is `fcom`/`test ah,0x41`, so it is strict, and false for NaN.
- `okAbs_w[k]` = |w[k]| < 1e6. The compare is `fcomp`/`test ah,5` against the same constants (0xCDCA20..2C), strict, false for NaN.
- `okNaN_v[k]` = (v[k] == v[k]) and `okNaN_w[k]` = (w[k] == w[k]). Each uses `fucompp` of a value with itself; `test ah,0x44`;
  `jnp`/`jp`.

```
mask = okNaN_w & okNaN_v & (okAbs_w & okAbs_v)
if ((mask & 0xE) != 0xE)                 // only x,y,z decide; the w bit is ignored
    v = w = (1.0, 0.0, 0.0, 0.0)         // floats at 0xBF65A0..AC (.data; same value in capture)
```

**The "unreachable blocks" Ghidra removed are real code, reachable only for NaN** — P:
- 0x8ED43D, 0x8ED4B4 (`mov [esp+0x10],0`), 0x8ED45D/0x8ED477/0x8ED491, 0x8ED4D1, 0x8ED4E8 and 0x8ED4FF (`xor reg,reg`) are the
  "x != x" branches of the self-compares.
- The thin-box copies are 0x8EC99B, 0x8ECA12, 0x8ECA2F, 0x8ECA46 and 0x8ECA5D.
- Ghidra folds `x == x` to true, so it drops them. A port must keep them: a NaN lane resets both velocities to (1,0,0,0).

### 3.2 Swept transform, linear part (0x8ED56B–0x8ED684)

```
com0 = com1                                   // ms+0x40 <- ms+0x50 (4 floats, fld/fstp copies)
com0.w = step->startTime (step+0)
L  = f32((v.x*v.x + v.y*v.y) + v.z*v.z)       // x87: vx²+vy² summed first (faddp order), one rounding at the store
mL = UF8[m+0xBC]                              // float table 0xB13380
if (L > mL*mL) {                              // strict; mL*mL not rounded to float; L <= m² or NaN -> no clamp
    s  = f32(_CIsqrt(L))                      // 0x9EE730 -> MSVCR80 _CIsqrt (export callee list)
    k  = f32(f32(1.0 / s) * mL)
    v[k'] = f32(k * v[k'])  k' = 0..3         // the STORED linear velocity is clamped
}
dtf = f32(dt)
com1[k] = f32(v[k]*dtf + com1[k])  k = 0..3   // fmul then fadd on the x87 stack, single rounding at the store
com1.w = step->invDeltaTime (step+0xC)        // overwrites the w just computed
```

### 3.3 Rotation (0x8ED687–0x8ED890)

```
rot0 = rot1                                   // ms+0x60 <- ms+0x70; a local copy q = rot1 is kept
hdt = f32(dt * 0.5)                           // double 0.5 at 0xBEA940
a.x = f32(hdt*w.x); a.y = f32(hdt*w.y); a.z = f32(hdt*w.z)
qq  = f32((a.x*a.x + a.y*a.y) + a.z*a.z)
x   = f32(qq * 0.40528471201320165)           // double at 0xB59C20 = 4/pi^2;  x = (theta/pi)^2, theta = |w|*dt
lim = f32(UF8[m+0xBD] * dt)
if (lim > 0.89999997615814209 /*double 0xB59C18, strict*/) lim = 0.9f /*0xB596B4*/
l2  = f32(lim*lim)
if (l2 < x) {                                 // strict (fcomp, test ah,1)
    s = f32(_CIsqrt(x)); k = f32(f32(1.0/s) * lim)
    w[0..3] = f32(k*w[i])                     // the STORED angular velocity is scaled
    a.x = f32(a.x*k); a.y = f32(k*a.y); a.z = f32(k*a.z)
    x = l2                                    // x is replaced by lim², not recomputed
}
x2  = f32(x*x)
a.w = f32(((1.0 - 0.8229479789733887*x) - 0.1305290013551712*x2) - x2*(0.04440800100564957*x))
                                              // doubles at 0xB59C10, 0xB59C08, 0xB59C00; one rounding at the store
q   = a (x) q          // 0x423F80, SSE, see §6.1: Hamilton product p*q with p = a
normalize(q)           // 0x423EB0, SSE, see §6.2
deltaAngle.xyz = f32(a+a) per lane, .w = f32(a.w + a.w) then overwritten:
deltaAngle.w = f32(f32(_CIsqrt(x)) * 3.1415927410125732)   // double 0xB59660 = (double)(float)pi
rot1 = q                                      // ms+0x70
```

- The angular velocity bound on this path is effectively |ω| ≤ π·UF8[maxAng]: since θ = |ω|·dt, the condition x > lim² means
  θ > π·lim. With lim < 0.9 and the boat's UF8 = 9.551, the bound is 30.0 rad/s — P (arithmetic); I (that this is the intent).
- There is **no** later clamp of ω against UF8[maxAng] itself on this path. That differs from 8EE2D0 (§7).

### 3.4 Transform rebuild (0x8ED893–0x8ED943)

```
R = quatToMatrix(rot1)                        // 0x88D070, writes ms+0x00..0x2C (3 columns, w = 0); see §6.3
c = comLocal (ms+0x80)
t.x = f32(com1.x - f32((R10*c.y + c.x*R00) + R20*c.z))   // Rij = column i, row j: ms+0x10*i + 4*j
t.y = f32(com1.y - f32((R11*c.y + R01*c.x) + R21*c.z))
t.z = f32(com1.z - f32((R12*c.y + R02*c.x) + R22*c.z))
t.w = f32(com1.w - 0.0)    // double 0.0 at 0xBEA968; so transform.translation.w == invDt (P in capture)
```

## 4. Deactivation bookkeeping (0x8ED94C–0x8EDCB9; every path except FIXED) — P

```
c = u8(m+0x09) + 1 (32-bit); m+0x09 = u8(c)
if (c & 3) goto done
if (c & 0xF) idx = 0
else if (c == 0x100) { m+0x09 = 0xFF; goto done }   // 0xFF = never deactivate (it stays 0xFF)
else { m+0x09 = 0; idx = 1 }
rr = f32(objectRadius m+0xB0); if (rr > 1.0) rr = 1.0   // fcom / test ah,0x41: strict > 1
W  = f32((w.y*w.y + w.x*w.x) + w.z*w.z)
V  = f32((v.y*v.y + v.x*v.x) + v.z*v.z)
e  = f32((rr*rr)*W + V)                 // rr*rr unrounded
p  = refPos[idx].w (m+0xFC+16*idx); refPos[idx].w = (e >= p || e is NaN) ? e : p    // running max of "energy"
d  = refPos[idx].xyz - com1.xyz (m+0xF0+16*idx minus m+0x60), each f32
D  = f32((d.x*d.x + d.y*d.y) + d.z*d.z)
info = si + 0x64 + 0x1C*u8(m+0xBE)      // deactivationClass
if (info.maxDistSqrd[idx] (info+0x10+4*idx) < D)  goto reset        // strict; NaN -> falls to rotation test
r  = u32 m+0x110+4*idx;  rq[i] = f32(i32(byte_i(r) - 128) * 0.008593750186264515)   // double 0xB59BF0 (=(double)(float)(1.1/128))
                                        // lane w: fimul, i.e. c * int, same value
mr = float_from_bits(i16(info+0x18+2*idx) << 16)                     // hkHalf
Q  = f32(((dq0*dq0 + dq1*dq1) + dq2*dq2) + dq3*dq3),  dq = f32(rq - rot1) per lane (rot1 = m+0x80)
if (mr < Q) goto reset                  // strict; mr >= Q or NaN -> "inactive"
inactive: lo = u8(m+0x0A+2*idx) & 0x7F
          u16(m+0x0A+2*idx) = ((lo - (lo>>6)) + 1) | (((u8(si+0x125+idx) << 7) | lo) << 7)
          goto done                     // the count saturates at 64; bits 7..13 = previous count; bit 14+ = select flag
reset:    lo = u8(m+0x0A+2*idx) & 0x7F
          u16(m+0x0A+2*idx) = ((u8(si+0x125+idx) << 7) | lo) << 7    // count = 0
          refPos[idx] = (com1.x, com1.y, com1.z, 0.0)
          u32(m+0x110+4*idx) = packQuat(rot1)    // 0xA06EA0, §6.4
done:     f = max(u8(m+0x0C)&0x7F, u8(m+0x0A)&0x7F);  result = min(result, f)    // result starts 0x7FFFFFFF
```

Return value: `result`, the minimum over the non-fixed bodies of max(count[0], count[1]). `FUN_009001B0` clears job-data +8 when
it is < 6 (0x9003xx; the caller's side is read by the parent).

The capture shows count[0] = 5, count[1] = 0, so it returns 5 — P. The u16 values are 0x0205 and 0x4080 (`cap_motion.txt`).

Class-2 record in the capture, at si+0x64+0x38 = 0x20007A3C: (11.111, 12.346, 0.968, 0.05, maxDistSqrd {0.0004, 0.0064},
maxRotSqrd halves {0x3ACF → 0.0015793, 0x3983 → 0.00024986}) — P (`cap_solverinfo.txt`, `deact_class2.txt`). The first four
names are recall (I).

## 5. THIN_BOX_INERTIA path (type 8, 0x8EC5FD–0x8ED136), brief — P

This path is not used by the boat. Its sequence:
1. The same gravity and damping.
2. Then L = R·( (R^T·ω) ∘ (1/invInertia) ), using 0x41BC80 (SSE R^T·v, w = 0), x87 `fdivr` reciprocals of m+0xC0..CC, and 0x88EB30
   (x87 R·v). L is the angular momentum in world space.
3. The same finiteness guard (§3.1).
4. The same swept/rotation/transform code (§3.2–3.4).
5. Then ω = R'·(invInertia ∘ (R'^T·L)) with the **new** rotation, which conserves angular momentum.
6. Then **post-integration clamps**:
   - if UF8[maxLin]² < |v|² (strict), or |v|² is NaN, scale v by f32(f32(1/sqrt)·UF8[maxLin]); then, if |v|² was NaN,
     v = (1,0,0,0) (0x8ED054);
   - the same for ω against UF8[maxAng]², with the NaN reset at 0x8ED110.
   - Those two blocks are the remaining "unreachable" ones (reachable only for NaN).
7. Then deactivation (§4).

## 6. Helpers — P

### 6.1 0x423F80 quat multiply (SSE scalar, thiscall out = ecx, args p = [ebp+8], q = [ebp+0xC]): out = p ⊗ q

```
out.x = p.x*q.w + (q.x*p.w + (q.z*p.y - q.y*p.z))
out.y = p.y*q.w + (q.y*p.w + (q.x*p.z - p.x*q.z))
out.z = p.z*q.w + (q.z*p.w + (p.x*q.y - q.x*p.y))
out.w = q.w*p.w - ((p.z*q.z + p.y*q.y) + p.x*q.x)
```

Every operation is single-precision SSE; the parentheses show the exact order.

### 6.2 0x423EB0 normalize (thiscall, in place)

```
n = ((x*x + y*y) + z*z) + w*w                 // SSE f32
if (n == 0) s = 0                             // ucomiss; equal & ordered -> s = 0 -> q becomes 0
else s = f32(1.0 / sqrt_x87(n))               // 0x401740: fld dword; fsqrt (result left on the x87 stack); fld1; fdivrp; fstp dword
q[i] = f32(q[i]*s)  (SSE)
```

A NaN n takes the sqrt branch.

### 6.3 0x88D070 rotation from quaternion (x87, thiscall out = ecx = ms, arg q)

```
X=f32(qx+qx) Y=f32(qy+qy) Z=f32(qz+qz)
xx=f32(qx*X) xy=f32(qx*Y) xz=f32(qx*Z) yy=f32(qy*Y) yz=f32(qy*Z) zz=f32(qz*Z) wx=f32(qw*X) wy=f32(qw*Y) wz=f32(qw*Z)
col0 = ( f32(1-(zz+yy)), f32(xy+wz), f32(xz-wy), 0 )
col1 = ( f32(xy-wz), f32(1-(zz+xx)), f32(wx+yz), 0 )
col2 = ( f32(xz+wy), f32(yz-wx), f32(1-(xx+yy)), 0 )
```

In the three diagonal entries the inner sum (zz+yy, zz+xx, xx+yy) is **not** rounded to float.

### 6.4 0xA06EA0 packQuat (x87)

```
vi = f32( f32(q_i * 116.36363220214844 /*0xB6BA70, double*/) + 196736.5 /*0xB6BA68, double*/ )
packed = byte0 (bits(vx)>>6)&0xFF | byte1 (bits(vy)>>6)&0xFF | byte2 (bits(vz)>>6)&0xFF | byte3 (bits(vw)>>6)&0xFF
```

The inverse is (byte − 128)·0.00859375 (§4). Round-trip test: (0,0,0,1) → 0xF4808080 → (0,0,0,0.99688) (`consts_8ec5b0_b.txt`).

0x41BC80 is out = (dot(col0,v), dot(col1,v), dot(col2,v), 0), computed in SSE as (c.z*v.z + c.y*v.y) + c.x*v.x.

0x88EB30 is out = R·v in x87, in the §3.4 order, with w = 0. Both are used by the thin box only.

## 7. Comparison with the solver-path integrator FUN_008EE2D0 (from the parent's scratch decomp, not re-read here)

**Matches:**
- com0 = com1 with com0.w = start, and com1.w = invDt;
- the linear clamp before position integration (strict |v|² > UF8²);
- the half-dt angle vector;
- 4/π², the lim = min(UF8[maxAng]·dt, 0.9) bound, the same cubic for a.w, the multiply and normalize, and deltaAngle = (2a, π·sqrt(x));
- the matrix rebuild with t.w = com1.w − 0;
- the same deactivation block.

**Differs (I, pending the parent's disassembly of 8EE2D0):**
- 8EE2D0 integrates the **solver accumulator** velocities (acc+0x40/+0x50), copies acc+0x10/+0x20 into the motion's velocities,
  and only then applies a **post** clamp of v and ω against UF8 (9.551 rad/s for ω).
- 8EC5B0 integrates and clamps the motion's own velocities, with no post clamp. So on this path ω is bounded only by π·UF8 ≈ 30.0 rad/s.
- 8EC5B0 applies gravity (world+0x1C0) and the (1 − c·dt) damping itself. 8EE2D0 shows neither.
- The finiteness guard is the same idea, but 8EC5B0 also resets on NaN (the blocks Ghidra dropped).

## 8. Capture check (boat afloat; island 0x1EE39500 +0xC = 0, so this path is the one that ran) — P

`replay_8ec5b0.py` takes the captured com0, rot0, stepInfo, post-damping v and ω, rot1 and comLocal. It recomputes com1, rot1,
deltaAngle, R and t.

- With model **ext53** (each x87 operation rounded to double, float only at `fstp dword`), **all 26 checks are bit-exact**: com0.w,
  com1.w, t.w, com1.xyz, rot1.xyzw, deltaAngle.xyzw, R[9] and t.xyz.
- With model **f32** (every operation rounded to float), rot1 y/z/w are off by 1 ulp.
- So the x87 precision control is **not 24-bit** at integration time; 53- or 64-bit cannot be separated by this test.
- The stored v and ω are exactly the ones integrated, so nothing modified them between this integrate and the capture.

## 9. NOT DETERMINED

1. x87 precision control: 53-bit vs 64-bit. The replay excludes 24-bit only. Next: read CONTEXT.FloatSave.ControlWord from the
   minidump thread list.
2. Which of the two velocity-reset vectors (1,0,0,0) Havok intended. The value is proven (.data and capture); the name (recall:
   "HK_QUADREAL_1000") is I.
3. Damping was not replayed against the capture: the pre-damping ω of the last step is not in the capture.
4. Thin-box path (§5): transcribed at block level only, not lane by lane.
5. The role of 9001B0's `< 6` consumer, and the island fields, are left to the parent.
