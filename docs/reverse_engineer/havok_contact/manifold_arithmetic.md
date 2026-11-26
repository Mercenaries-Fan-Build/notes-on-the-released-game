---
status: current
evidence: mixed (graded per claim)
---

# N3: manifold arithmetic of the convex-vs-triangle agent (pc-v10), and a bit-exact gate

This page closes the arithmetic gaps that N2 left in `convex_triangle.md` §11 (items 2, 3, 6, 7, 10, and narrows 1 and 8).
Read on 2026-11-25. Scope: agent3 #10 `FUN_00901510` for the Speed Boat-class hull against `WpMeshShape16`
terrain triangles.

Grades:
- **P**: PROVEN this run, with the instruction address, file or command cited.
- **I**: INFERRED (reasoned, not checked).
- **S**: SPECULATIVE.
- **HK**: recalled Havok knowledge. At best it is I.
- **ND**: NOT DETERMINED (§8).

Notation (same as `gsk_core.md`):
- `f32(x)` is one `fstp`/`fst dword`, i.e. rounding to binary32.
- Everything else is an x87 register value (f64 at PC=53, see §6).
- `a − b` keeps the binary's operand order.
- Sums keep the binary's association. Operand order inside one add is irrelevant, because IEEE add is commutative.
- "lt / eq / gt / un" are the fcom outcomes, decoded from `fnstsw; test ah,m; jcc` with ah lt=0x01, eq=0x40, gt=0, un=0x45.

All paths below are under
`/private/tmp/claude-501/-Volumes-Projects-mercenaries-game/d08a21c0-8307-469b-be20-8c9b42a8712a/scratchpad/havok_port/n3/`.

| Folder | Content |
|---|---|
| `r916/` | `d_916360.s` (patched copy) and `d_916360_orig.s`, which is identical from 0x91636C (`cmp` rc 0, `rm_lst.txt`); per-case tracer runs `t_c5/6/7/9/10/13.txt`, `t_tail.txt`; hand-checked extracts `c6end.txt`, `c7end.txt`, `c7mid.txt`, `c10cmp.txt`, `c10b.txt`, `tail_lst.txt`, `rm_lst.txt`, `raw_916705.txt` |
| `a917/` | `917a40.md`, a delegated transcription of `FUN_00917A40` under the same rules. Summarised in §3. |
| `create/` | `create_xform.md`, a delegated transcription of the transforms, create helpers and `0x90BE70`. Summarised in §4. |
| `thread/` | `thread_fpu.md`, the delegated thread/FCW trace. Summarised in §6. |
| `gate/` | capture reader `mdmp.py` (copied from S1), `x87.py` (exact-rational x87 emulator, PC 24/53/64), `cap.py` (input extraction), `gate7.py` (manifold refresh replay), `gategsk.py` (GSK replay), outputs `gate7_pc*.txt`, `gategsk_pc*.txt`, `gsk_order_*.txt`, `fpucw_winch.txt` |

---

## 1. Headline: the gate matches bit for bit — P

Capture `20261021_chris-jacobs-flying-winch.dmp`. Inputs were reconstructed from the capture (`gate/cap.py`, `g1–g3.txt`):

| Input | Source in the capture |
|---|---|
| sub-entry | 0x1E35C270 (cmd 4, type 0x0A, np 1, size 0x40), key B 0x01000756 |
| hull | list child **2** of boat body 0x1DF9D000. The bvtree entry 0x1D4BF030 has key 2, and its track 0x1E610EC0 points to sector 0x1E35C200. The child is `hkpConvexVerticesShape` 0x29C70DA0: 177 vertices, radius 0.05, rotatedVertices 0x29C70E00. |
| hull vertex id 0x56 | (−3.0127e−7, −0.76256859, −5.4979239) |
| worldFromA | boat motion 0x1DF9D0E0 (= cdBodyA+8) |
| worldFromB | terrain motion 0x1E45C8E0: identity rotation, t = (2600, 0, −1000) |
| triangle | MOPP 0x296239E0 (+0x34) → `WpMeshShape16` 0x29655400, radius 0.01; subpart 1, triangle 1878, indices (5627, 5648, 5605), **extrusionLen 10** |
| triangle dequantisation | `fl(origin + fl(scale·q))` (N1 `wpmesh16.md`) |
| cached simplex | ids {0x56; 2, 0, 1}, dims (1,3), byte 0xFF |
| manifold | {nA 1, nB 3, np 1}, point {1, 3, id 0, vtx 00 10 20 30} |
| contact manager | 0x1C8A6C80, atom 0x1C8A6200; idMgr[0] = 0 → point 0 at atom+0x30 |
| sep (entry+0x10) | bits be41bbdc 3f6ea3f0 3e9dffec bbe2056a |
| tolerance | 0.1 |

**Manifold-refresh replay.** `gate/gate7.py` runs the case-7 path of `FUN_00916360` (§2.4) and its emit tail (§2.8)
on the §4.1 vertex buffer, with buf.n = the entry's sep (refresh-only path, `convex_triangle.md` §4). The result is
compared with the manager's point 0:

| Word | Replay (PC=53) | Capture | |
|---|---|---|---|
| pos.x | 451db9ae | 451db9ae | match |
| pos.y | c2145f6d | c2145f6d | match |
| pos.z | c4491dd5 | c4491dd5 | match |
| pos.w | 00000000 | 00000000 | match |
| n.x | be41bc97 | be41bc97 | match |
| n.y | 3f6ea3e7 | 3f6ea3e7 | match |
| n.z | 3e9dffe5 | 3e9dffe5 | match |
| dist | 377c6000 (1.50427e−5) | 377c6000 | match |

- **All 8 words match** (`gate/gate7_pc53.txt`). The case-7 path computed s0..s2 = (−30.99, −22.86, −14.84), so the
  triangle-inside test passes. s3 = +1.0000001, so there is no flip; the point is kept.
- **Same at PC=64** (`gate7_pc64.txt`).
- **Not at PC=24** (`gate7_pc24.txt`): n.x is off by 1 ulp and dist by 40960 ulp (377d0000). So the step that wrote this
  point did not run at 24-bit precision.
- **The match does not tell the transform association apart** (`gate7_n2order.txt`). N2's order matches too, because the
  terrain rotation is the identity and the hull vertex has x ≈ 0. The association rests on the code reading in §4.1.
- **Which path wrote the point (P, by elimination).** For this state the full GSK path would emit the GSK point
  instead: pos.y = c2145f6b, not c2145f6d (`gategsk_pc53.txt`). So the last step was refresh-only, consistent with
  qi+0xC = −0.01 < dT1 = sep.w = −0.0069.

**GSK replay.** `gate/gategsk.py` runs from the cached simplex:
- aTb = `FUN_008933D0`(TA, TB), as in `query_path.md` §7.
- Prologue, then PT_TRI → `0x90E200` (code 0xE, no flip) → NORMAL → POST.
- TRY_A: support of the hull along −n is vertex 0x56 itself (brute force, margin about 1.0 over the next vertex), so
  qA = 0 and it is rejected.
- TRY_B: the support is a top vertex, with q ≤ 7.7e−10 against eL = 9.4e−7, so it is rejected.
- FINISH, then the `0x913970` tail (sep.xyz = R_A·n, as traced in `gate/t913.txt`).

Result against the entry's sep.xyz:

| Lane | Replay | Capture | |
|---|---|---|---|
| sep.x | be41bbda | be41bbdc | −2 ulp |
| sep.y | 3f6ea3f0 | 3f6ea3f0 | match |
| sep.z | 3e9dffeb | 3e9dffec | −1 ulp |

- PC=53 and PC=64 give the same result.
- All six triangle vertex orders were tried; none matches (`gsk_order_*.txt`).
- sep.w is not comparable: the refresh path overwrote it with dT1.
- **I:** sep.xyz was written by an earlier full-path step, under slightly different transforms (the last step was
  refresh-only, see above). **ND:** this capture cannot prove it.
- TRY_A/TRY_B used a brute-force support, not the exe's support functions `0x8BAF00` / `0x8AB120` (not transcribed).
  The outcome (both reject) holds by the margins above; that the exe's support picks the same vertex is I.

What the capture could not supply: dT1's producer (the 1n TIM machine) state for this step, and the transforms of the
step that last ran the full GSK.

---

## 2. `FUN_00916360` — verify and emit the cached points (body 0x91636C–0x917A0F) — P

The listings agree from 0x91636C onwards (`r916/rm_lst.txt`, cmp rc 0), so the patched and original exe hold the
same body. Every case below was run through `x87sym.py` (`r916/t_*.txt`). The interpolations, compares, flips and
the tail were also traced by hand (extracts listed in the artefact table).

### 2.1 Frame and loop

Arguments: [ebp+8] man, [ebp+0xC] buf (esi), [ebp+0x10] first, [ebp+0x14] output, [ebp+0x18] mgr.

```
if !(first < man.np) (unsigned jae 0x91638A): return
fldz                              // Z = +0.0 sits at the x87 stack bottom for the whole loop (0x916393)
npOrig = np; cnt = np; i = first; p = &man.point[first]; tbl = man+4+8*np
LOOP (0x9163B2):
  outp = *output                  // write pointer, reloaded every iteration
  e = p.dimB + 4*p.dimA; if e > 13: REMOVE
  switch byte[0x917A30+e] -> dword[0x917A10+4*k]   // table bytes 00 07 07 07 07 01 02 03 07 04 05 07 07 06 (raw_916705.txt)
    5 -> C5 (1,1), 6 -> C6 (1,2), 7 -> C7 (1,3), 9 -> C9 (2,1), 10 -> C10 (2,2), 13 -> C13 (3,1), others -> REMOVE
```

Vertex operands are buffer entries: `vtx[j]` is a byte offset into buf (16-byte vertices, w = +0.0 from §4.1).
Every case leaves these values in the frame:

| Slot | Content |
|---|---|
| P [0x30..0x3C] | 4 lanes |
| D [0x40..0x48] | xyz only; D.w is never written or read |
| N [0x50..0x5C] | 4 lanes |
| eax | reject flag |

### 2.2 Case 5, (1,1): a = vtx0, b = vtx1 (0x9163D9–0x9164B7)

```
D = f32(a − b) (xyz)
L = f32((D.x*D.x + D.y*D.y) + D.z*D.z)
reject = (buf.sq < L)                      // fcompp sq vs L; test 5; jp keeps: keep on gt, eq, un. NaN keeps.
P = a (4 lanes); N = buf.n (4 lanes)
```

### 2.3 Case 6, (1,2): a = vtx0, b0 = vtx1, b1 = vtx2 (0x9164BC–0x916791)

```
P = a (4); N = buf.n (4)
e  = f32(b1 − b0);  q1 = f32(b1 − a);  q0 = f32(a − b0)                          (xyz)
c  = ( f32(q1.z*e.y − q1.y*e.z), f32(e.z*q1.x − q1.z*e.x), f32(q1.y*e.x − e.y*q1.x) )   // = e × q1
u  = f32((q1.y*e.y + q1.x*e.x) + q1.z*e.z)
v  = f32((q0.y*e.y + q0.x*e.x) + q0.z*e.z)
C  = f32((c.y*c.y + c.x*c.x) + c.z*c.z)
L  = f32((e.x*e.x + e.y*e.y) + e.z*e.z)
bits = (u < 0 ? 8 : 0) | (v < 0 ? 4 : 0) | (C < 0 ? 2 : 0)          // strict, NaN → 0
reject if (buf.sq * L) < f64 0.0  (register product; f64 [0xBEA968] = 0, bytes checked)   // never true for finite sq, L ≥ 0
reject if bits & 0xC                                                // bit 2 (C < 0) is NOT in the mask
t  = f32(u / (v + u));  s = f32(1.0 − t)                            // de f9 = fdivp st1 = st1/st0; fld1; fsubrp → 1 − t
Q  = ( f32(b0.x*s + t*b1.x), f32(s*b0.y + t*b1.y), f32(t*b1.z + s*b0.z) )
D  = f32(a − Q) (xyz)
```

Notes on case 6:
- **There is no distance test in cases 6 and 9.** The only "distance" compare is `sq·L < 0`, and C enters only
  bit 2, which the `test dl,0xC` ignores (0x9166D3–0x9166F9). Rejection is by region alone.
- **b0 gets weight 1−t and b1 gets t, with t = u/(u+v).** That is the mirror of the geometric projection (I by
  algebra: the projection weight of b0 is u/(u+v)). Q enters only through d = N·(a − Q), so the effect is N·e·(…), and
  it vanishes when N ⟂ e. Port it as written.

### 2.4 Case 7, (1,3): a = vtx0, b0 = vtx1, b1 = vtx2, b2 = vtx3 (0x916796–0x916C7E) — gated in §1

```
P = a (4 lanes)
D = f32(a − b0) (xyz)
u = f32(b2 − b1);  v = f32(b0 − b2);  w = f32(b1 − b0)                          (xyz)
c = ( f32(v.z*u.y − v.y*u.z), f32(u.z*v.x − v.z*u.x), f32(v.y*u.x − u.y*v.x) )   // = u × v
L = f32((c.y*c.y + c.x*c.x) + c.z*c.z)
s = (L == Z ordered-equal) ? f32(+0.0) : f32(1.0 / f32(_CIsqrt(L)))   // fucom; test 44; jnp (0x916906–0x91690F)
N = ( f32(s*c.x), f32(c.y*s), f32(c.z*s), f32(s * f64 0.0) )          // fmul qword [0xBEA968]
k0 = cross(f32(a − b1), u);  k1 = cross(f32(a − b2), v);  k2 = cross(f32(a − b0), w)
     where cross(p, e) = ( f32(p.y*e.z − p.z*e.y), f32(p.z*e.x − e.z*p.x), f32(e.y*p.x − e.x*p.y) )   // = p × e
s_i = f32((k_i.y*N.y + k_i.x*N.x) + k_i.z*N.z)       i = 0,1,2
s3  = f32((n.y*N.y + N.x*n.x) + n.z*N.z)             n = buf.n
bits = (s0<0?8:0) | (s1<0?4:0) | (s2<0?2:0) | (s3<0?1:0)  // each: fcom Z vs s; test 41; jne clears, so set iff s < 0 strictly; NaN clears
if bits & 1: N = (−N.x, −N.y, −N.z, −N.w)            // fchs and fstp; N.w becomes −0.0
reject = (~bits) & 0xE                              // 0x917869: keep only if s0, s1 and s2 are all < 0 strictly
```

- The normal written to the manifold point is the triangle's own unit normal, oriented to agree with buf.n. It is not
  the GSK normal.
- The 0.0 in the `L == 0` test is the fldz-made Z. The sqrt path reloads the operands and rebuilds Z with a fresh
  `fldz` (0x916938–0x916954).

### 2.5 Case 9, (2,1): a0 = vtx0, a1 = vtx1, b = vtx2 (0x916C83–0x916F27)

```
N = buf.n (4)
e = f32(a1 − a0);  q1 = f32(a1 − b);  q0 = f32(b − a0)                           (xyz)
c = ( f32(q1.z*e.y − q1.y*e.z), f32(q1.x*e.z − e.x*q1.z), f32(e.x*q1.y − q1.x*e.y) )    // = e × q1
u = f32((q1.x*e.x + q1.y*e.y) + q1.z*e.z);   v = f32((q0.x*e.x + q0.y*e.y) + q0.z*e.z)
C = f32((c.y*c.y + c.x*c.x) + c.z*c.z);      L = f32((e.x*e.x + e.y*e.y) + e.z*e.z)
bits, sq·L < 0 test, `bits & 0xC` reject: exactly as case 6 (shared reject block 0x916788, eax = 1)
t = f32(u / (v + u));  s = f32(1.0 − t)
P = ( f32(a1.x*s + t*a0.x), f32(s*a1.y + t*a0.y), f32(s*a1.z + t*a0.z), f32(t*a0.w + s*a1.w) )   // geometric weights here
D = f32(P − b) (xyz)
```

### 2.6 Case 10, (2,2): a0, a1 = vtx0, vtx1; b0, b1 = vtx2, vtx3 (0x916F2C–0x91736A)

```
N = buf.n (4)
ea = f32(a1 − a0);  eb = f32(b1 − b0);  r0 = f32(a0 − b0);  r1 = f32(a1 − b1)             (xyz)
n  = ( f32(eb.z*ea.y − eb.y*ea.z), f32(eb.x*ea.z − ea.x*eb.z), f32(ea.x*eb.y − eb.x*ea.y) )   // = ea × eb
ka = ( f32(n.z*ea.y − n.y*ea.z), f32(ea.z*n.x − ea.x*n.z), f32(ea.x*n.y − ea.y*n.x) )       // = ea × n
kb = ( f32(n.z*eb.y − n.y*eb.z), f32(eb.z*n.x − n.z*eb.x), f32(n.y*eb.x − eb.y*n.x) )       // = eb × n
w0 = f32((kb.y*r0.y + r0.x*kb.x) + kb.z*r0.z)
w1 = f32((r0.y*ka.y + r0.x*ka.x) + ka.z*r0.z)
w2 = f32((kb.y*r1.y + kb.x*r1.x) + kb.z*r1.z)
w3 = f32((ka.y*r1.y + ka.x*r1.x) + ka.z*r1.z)
bits = (w0<0?8:0) | (w1<0?4:0) | (w2<0?2:0) | (w3<0?1:0)      // all strict, NaN → 0 (hand-decoded, c10cmp.txt)
if bits != 0xC and bits != 0x3: reject (eax = 1)
tA = f32(w0 / (w0 − w2));  sA = f32(1.0 − tA)                   // fsubrp st2 → w0 − w2; fdivrp st1 → w0/(…)
P  = ( f32(a0.x*sA + a1.x*tA), f32(sA*a0.y + tA*a1.y), f32(a0.z*sA + a1.z*tA), f32(tA*a1.w + sA*a0.w) )
tB = f32(w1 / (w1 − w3));  sB = f32(1.0 − tB)                   // c10b.txt: fsubrp st4, fdivrp st3, fsubp st3
Q  = ( f32(b1.x*tB + sB*b0.x), f32(sB*b0.y + tB*b1.y), f32(tB*b1.z + sB*b0.z) )
D  = f32(P − Q) (xyz)
```

- Only the sign patterns 0xC and 0x3 are accepted. The two other "crossing" patterns, 9 and 6, are rejected.
- I: patterns 9 and 6 cannot occur with n = ea × eb.

### 2.7 Case 13, (3,1): a0, a1, a2 = vtx0..2; b = vtx3 (0x91736F–0x917867)

```
D = f32(a0 − b) (xyz)
u = f32(a2 − a1);  v = f32(a0 − a2);  w = f32(a1 − a0)
c, L, s, N: exactly as case 7 (c = u × v; N.w = f32(s * f64 0.0))
k0 = cross(f32(b − a1), u);  k1 = cross(f32(b − a2), v);  k2 = cross(f32(b − a0), w)    // cross() as in case 7
s0..s2 = f32((k.y*N.y + k.x*N.x) + k.z*N.z);   s3 = f32((n.y*N.y + n.x*N.x) + n.z*N.z)
h = f32((N.x*D.x + D.y*N.y) + D.z*N.z)
P = ( f32(N.x*h + b.x), f32(N.y*h + b.y), f32(N.z*h + b.z), f32(h*N.w + b.w) )   // b projected onto A's face; uses the unflipped N
bits, flip on s3 < 0, reject = (~bits) & 0xE: as case 7
```

### 2.8 Emit tail (0x917876–0x91794A) and REMOVE (0x917954–0x9179A4)

```
if reject: REMOVE
d    = f32((D.y*N.y + N.x*D.x) + D.z*N.z)
sr   = f32(rB − d)                          // fsubp st2: st2 − st0
dist = f32(d − f32(rA + rB))
if !(dist < tol): REMOVE                     // fcomp tol vs dist; test 41; jne: remove on lt, eq, un
out = *output (edx loaded at 0x917872)
out.pos = ( f32(N.x*sr + P.x), f32(N.y*sr + P.y), f32(N.z*sr + P.z), f32(sr*N.w + P.w) )
out.n   = (N.x, N.y, N.z);  out[+0x1C] = N.w, then overwritten by dist
out[+0x20] = u32(zero-extended point.id);  *output += 0x30
REMOVE: if point.id != 0xFFFF: mgr->vtable[0x14](push id zero-extended (movzx), push output[+4])
        // x87: Z is popped before the call and rebuilt with fldz after it (0x917961, 0x917972)
        point[i] = point[cnt−1] (8 bytes); cnt−−; and i and p step back one, so the moved point is checked next
i++; p += 8; if i < cnt: LOOP
if npOrig > cnt: man.np = cnt; copy the id table from the old position (man+4+8*npOrig) down to man+4+8*cnt,
                 ((nA+nB−1)>>1)+1 dwords; FUN_009161C0(edx = man)
```

- pos.w for cases 5, 6, 9 and 10 is `sr·buf.n.w`, which is nonzero: buf.n.w is dT1 or the GSK distance, and P.w = 0.
  This is where the "small w" values S1 saw in manager points come from (I).
- For cases 7 and 13, pos.w = sr·(±0) + 0 = +0. Matched in §1.

---

## 3. `FUN_00917A40` — which of 4 + 1 points to drop — P (full text and evidence: `a917/917a40.md`)

**Interface.**
- The only input is **ECX = arg8 of `FUN_00918580`**. It points to 5 output-stream points of stride 0x30; slot 4 is the
  new point.
- Only these fields are read: pos x, y, z (+0, +4, +8) and dist (+0x1C).
- No manifold bytes are read. There are no calls.
- I (not tied by a write in these functions): arg7 = arg8+0xC0. Reason: 0x918580 reaches 917A40 only when np == 4.
  The full path then refreshed from index 0, so 916360 emitted exactly the 4 old points from prevFirst, and `out` is
  the next slot.

```
sq3(a,b) = f32(((dx*dx + dy*dy) + dz*dz)),  d* = f32(a.* − b.*)
flag[0..4] = 0; BEST = 0; MIN = f32 0x7F7FFFEE; iMax = iMin = 0
D[0] = sq3(pt4, pt0); if D[0] > 0: BEST = D[0]; if D[0] < f64 0x47EFFFFDC0000000: MIN = D[0]
for i = 1..3: D[i] = sq3(pt4, pt_i); if BEST < D[i]: BEST, iMax = D[i], i; if MIN > D[i]: MIN, iMin = D[i], i
DD = f32(pt4.dist − pt[iMin].dist); flag[iMax] = 1; P = pt[iMax]; BEST = f32(BEST * f64 1.0499999523162842)
i2 = 4; for j in 0..3 unflagged: d = sq3(P, pt_j); if BEST < d: BEST, i2 = d, j
        if flag[4]==0 and BEST < sq3(P, pt4): i2 = 4;  flag[i2] = 1
e = f32(P − pt[i2]); BEST = 0; i3 = 0
for j in 0..4 unflagged: v = f32(pt_j − P);
        c = (f32(vy*ez − vz*ey), f32(vz*ex − ez*vx), f32(vx*ey − vy*ex)); a = f32((cx*cx + cy*cy) + cz*cz)
        j==0: if a > 0: BEST = a;   j=1..3: if BEST < a: BEST, i3 = a, j;   j==4: if BEST < a: i3 = 4
flag[i3] = 1; Q = pt[i3]; BEST = 0; i4 = 0
for j in 0..4 unflagged: d = sq3(Q, pt_j); (same j==0 / 1..3 / 4 pattern) → i4;  flag[i4] = 1
if flag[4] or !(DD < 0) or !(MIN < DD*(DD*526.0)): SCAN
RATIO = f32 0x3CF98AE9 (0.030461745); r = 4; nd = pt4.dist
for i in 0..3 (flags ignored):
    q = f32(pt_i.dist − nd); den = f32(f32(q*q) + f64 9.999999717e-10)
    lhs = (i==0) ? f64(0x3CF98AE9 widened) * D[0] : RATIO * D[i]
    if lhs < den: r = i; if i < 3: RATIO = f32(den / (D[i] + f64 9.999999717e-10))
return r
SCAN: return the first e in 0..4 with flag[e] == 0, else 0
```

- Every compare is strict and ordered: NaN never updates, and the first index wins ties.
- The x87 stack carries two values across phases:
  - Z from 0x917A49 seeds phase 3's BEST;
  - Z2 from 0x9181D4 is the comparand in phase 4 and in the DD < 0 gate.

The constants are P from operand sizes, widths and bits (`a917/consts.txt`).

---

## 4. Transforms, create helpers, `FUN_0090BE70` — P (full text: `create/create_xform.md`)

### 4.1 Vertex buffer (0x901510 and 0x92A270, all six loops identical)

- **Per lane** (closes N2 ND-2): `x' = f32(((v.y*T[4] + v.x*T[0]) + v.z*T[8]) + T[12])`, and likewise for y and z with
  T[5]/T[1]/T[9]/T[13] and T[6]/T[2]/T[10]/T[14]. Stores go x, y, z, then **w = +0.0f**.
- **Loops** run i = n−1 down to 0. A's vertices use transform `[cdBodyA+8]`, B's use `[cdBodyB+8]`.
- **Buffer constants:**
  - `s = f32((rA + tol) + rB)`, with **one** fstp at 0x9016F1 (re-checked from bytes: `fld [esp+0x170]; fadd [0x178];
    fadd [0x174]; fstp [0x10]`);
  - `sq = f32(s*s)`.
- **The two callers differ:**
  - `0x92A270` builds the buffer (and calls 0x916360) only when `np > found`, not when `np != 0`. Its +0x100 normal is
    the sep copy that went through `shapeB->vtable[0x38]`.
  - The weld call is a no-op for terrain: type 6 returns 2 (N2 §6).

### 4.2 Create helpers (closes N2 ND-6)

**`0x92AB20`** (triangle, not extruded):
1. ids = {?, 0, 1, 2}. Each `v_k = X(T, tri_k)`, with T = in+0x10 = aTb.
2. e0 = f32(v1 − v0), e1 = f32(v2 − v1).
3. n = e0 × e1, with n.x = f32(e0.y*e1.z − e0.z*e1.y), n.y = f32(e0.z*e1.x − e1.z*e0.x),
   n.z = f32(e0.x*e1.y − e1.x*e0.y), n.w = +0.
4. d = f32(a0 − v0), where a0 = hull vertex id 0. dot = f32((d.y*n.y + n.x*d.x) + d.z*n.z).
5. All 4 lanes of n are XORed with dot's sign bit, giving n'.
6. ids[0] = the u16 id of `shapeA->support(n')`. dims (1,3); +0xA = clamp(cA) | 0x30; +0xB = 0.

**`0x92A8F0`** (generic, and every extruded triangle, which means every captured terrain triangle):
1. a0 = A id 0; p = X(T, B id 0).
2. sA = supportA(f32(p − a0)), with w = f32(0 − a0.w).
3. e = f32(p − sA), with e.w = f32(0 − sA.w).
4. dB = −Rᵀe, where each lane is `f32((e.x*T[4k] + e.y*T[4k+1]) + e.z*T[4k+2])` followed by `fchs`, and w = −0.0.
5. sB = supportB(dB).
6. ids = {sA.id, sB.id, 0, 0}, dims (1,1). The nibbles are each shape's `vtable[0x24]`, clamped to 0xF when > 3.

Supporting facts:
- The triangle's `vtable[0x24]` (0x8AAA30) is 3·(isExtruded + 1). So extruded triangles get maxB 0xF, which matches the
  capture's byte 0xFF.
- `0x901380` zeroes entry[2], clears flag 0x10, and zeroes the whole manifold dword.

### 4.3 Vertex-id conversion (vtable +0x34), used by both the buffer and the GSK — P (`gate/d_8bb230.s`, `gate/d_8ab260.s`, `gate/tritab.txt`)

- **Hull** (`0x8BB230`): vertex = rotatedVertices[id>>2] lane id&3, with x, y, z from the +0, +0x10, +0x20 rows of a
  48-byte block. w = bits(id | 0x3F000000).
- **Triangle** (`0x8AB260`):
  - `v = tri.vertex[tab250[id]]` (4 lanes copied), then `v.x = f32(ext.x*k + v.x)`, `v.y = f32(k*ext.y + v.y)`,
    `v.z = f32(ext.z*k + v.z)` and v.w likewise, with `k = f32 tab224[id]`.
  - w is then overwritten with bits(id | 0x3F000000).
  - The tables are the same in the exe and the capture: tab250 = {0,1,2,0,1,2}, tab224 = {0,0,0,1,1,1}. So ids 3..5 are
    the extruded copies (v + extrusion, with extrusion = (0, −10, 0, 0)).

### 4.4 `FUN_0090BE70` (closes N2 ND-7)

- It is a thiscall copy of a 0x24-byte output point (8 f32 through fld/fstp, then the u32 id); no arithmetic.
- Sites in 0x918580:
  - entry[k] ← arg7+0x90 (swap-remove), then return 6;
  - entry[k] ← arg6, the new point.

### 4.5 GSK write-back `FUN_0090FE80` — P (listing `n2/gsk/d_90fe80.s`), correction to N2 §2.3

The write-back does **not** sort the ids descending. Per body (A from GSK +0x20.w, B from +0xE0.w, low u16):
- dim 1: copy the id.
- dim 2: put the larger id first (swap if id1 > id0, unsigned).
- dim 3: **rotate** (u0, u1, u2) so that the largest id comes first, **keeping the cyclic order**. The four outcomes
  are (u0,u1,u2), (u1,u2,u0) and (u2,u0,u1), selected by the two unsigned compares and the swap count edi. On A's
  side, edi = 1 comes through the `0x476D31` hop: `mov edi,[0x245D664]` = 1.
- Capture check: a triangle written as (0,1,2) becomes **(2,0,1)**, exactly the cached ids at 0x1E35C290. The order
  matters for the port, because the next step's GSK loads the vertices in this order, and classify's rounding depends
  on it (§1 order test).
- dims are copied to cache +8 / +9.

---

## 5. Process-level consequences for the boat (I unless marked)

- Every captured terrain triangle is extruded (N1; here too: extrusionLen 10), so **create always takes `0x92A8F0`**:
  dims (1,1), maxB = 0xF. The GSK then grows the simplex, and TRY_B can return the extruded ids 3..5 (P from 4.3 and
  4.2).
- After a full-path step, the entry's sep keeps the GSK normal, while each manifold point carries its case-specific
  normal: the triangle normal for (1,3) and (3,1), buf.n for the others. The manager therefore holds different normal
  bits from sep. This is P on the capture: be41bc97 vs be41bbdc.

---

## 6. x87 precision during the physics step

- **Thread (P, `thread/thread_fpu.md`).** `FUN_008FD040` and `FUN_008FDA80` run on the Pimp cpu-0 thread, which is the
  WinMain/main-loop thread.
  - Call chain: `FUN_00631670` → `630EF0` → `4C14F0` → `4C15E0` → `[vptr+0xC]` = `4C09C0` → state 2 → `4C0EC0` →
    `4C9740` → `4036F0` → `8D61A0` → `8F6EA0` → `8F6C10`.
  - In `8F6C10`, case 0 → `9001B0` → `8FD040` (0x90041D), and case 0xD/0xF → `8FDA80` (0x8F6DA5).
  - The capture's TLS cpu index is 0 only on tid 15824, and the Havok TLS slots 24/25 are non-NULL only there.
    `8F2E90`/`8F6EA0`/`8F6C10` dereference them without a NULL check, so the worker thread cannot run the step.
- **The "job type 6" route is false for this build (P).** Type 6 is `FUN_004036B0`; it is posted only to cpu 0's ring
  (0x4037CE) and drained by `FUN_008765CF`.
- **FCW-changing code (P).**
  - Every one of the 471 well-formed `fldcw` sites in `.text` is the MSVC truncation idiom, which changes RC only and
    restores it.
  - `_controlfp_s` is used only by Scaleform `FUN_007C9410`, which sets `_PC_64` and restores it, off the Havok path.
  - There is no `fninit`.
  - Not swept: d3d9, MSVCR80 and the SecuROM sections.
  - D3D `CreateDevice` (0x754F30) never passes FPU_PRESERVE (flag value from recall, I). The 24-bit thread (tid 11456
    first-mission, 2816 winch) is the cpu-1 worker / window thread (P), and that it is the device thread is I.
- **Captured FCW.** The main thread has FCW 0x027F (PC 53, RC nearest):
  - first mission: tid 15824 (N2);
  - winch: first thread tid 9748, with 26 threads at 0x027F and one at 0x007F (`gate/fpucw_winch.txt`, P).
- **Gate evidence (P, §1).** The refresh computation that wrote the winch manager point reproduces bit-exactly at
  PC=53 and PC=64 and fails at PC=24. So that narrowphase step ran at PC ≥ 53.
- **Not determined.** PC=53 vs PC=64 is not separated by this gate. Combined with the captured 0x027F on the only
  thread that can run the step, and no PC-changing code on the path in `.text`: **PC = 53 is I (strong), not P.**

---

## 7. Corrections to N2 (`convex_triangle.md`)

| N2 § | N2 says | Correct | Evidence |
|---|---|---|---|
| §2.5 / ND-2 | `((t + z·R2) + x·R0) + y·R1` | `((y·R1 + x·R0) + z·R2) + t` | create §A (P) |
| §2.5 | `sq = f32(f32(f32(rA+tol)+rB)²)` | `f32(s²)`, `s = f32((rA+tol)+rB)`, one fstp | bytes 0x9016DC–0x9016FB (P) |
| §2.3 | 0x90FE80 sorts ids descending | dim 3 rotates so the max id is first, keeping cyclic order; dim 2 puts the max first | §4.5 (P), capture (2,0,1) |
| §2.3 | create clears flag 0x10 | it writes byte +0xB = 0 and zeroes the manifold dword | create B.0 (P) |
| §5.3 (1,1) | reject if > sq | reject if sq < L strictly; NaN keeps | §2.2 (P) |
| §5.3 (1,2)/(2,1) | "reject `sq*x < 0` or end-region bits" | correct as stated, and it means there is **no distance test**; t = u/(u+v) with **mirrored weights in (1,2)** | §2.3 (P) |
| §5.3 (2,2) | "side code 0xC or 0x3" | the 4 sign bits w0..w3 (strict); P = a0 + tA·ea, Q = b0 + tB·eb as in §2.6 | §2.6 (P) |
| §5.3 (1,3)/(3,1) | arithmetic I | §2.4 / §2.7 (P); keep only if all three edge values < 0 | P |
| §5.3 REMOVE | mgr id "sign-extended" | zero-extended (`movzx eax, word`) | 0x917954 (P) |
| §5.4 l.467 | k==0: point[0] := point[1..] | copies only entry[1] over entry[0] | a917 §5 (P) |
| §5.4 / ND-7 | 0x90BE70 called with 4 / retaddr | 0x24-byte copy, src arg7+0x90 or arg6 | create C (P) |
| §5.5 | 1.05, 1e-9 (f64), widths by cast | 1.0499999523162842, 9.999999717e-10 (widened f32 bits), widths from operands | a917 §4 (P) |
| §5 (0x92A270) | refresh when found < np, buffer when np != 0 | the whole buffer build is gated by np > found | create A.2 (P) |
| §9 | Havok thread = tid 15824 (I) | P via code: Pimp cpu 0 = main loop | §6 |

---

## 8. NOT DETERMINED

1. **PC=53 vs PC=64 during the step.**
   - Tried: the replay at both precisions (identical results); the code sweep of `.text`.
   - Next: a gate value whose replay differs between 53 and 64 (for example a long register chain in the GSK or the
     solver), or a capture taken mid-step.
2. **Why the entry's sep.xyz is 1–2 ulp off the GSK replay.**
   - Tried: PC 24/53/64, and all 6 vertex orders.
   - I: it is stale from an earlier full-path step.
   - Needs a capture pair, or a capture whose last step ran the full path.
3. **The shapes' support functions** (`0x8BAF00` hull, `0x8AB120` triangle, vtable +0x30) were not transcribed. The gate
   used brute force; its rejections hold by large margins.
4. **arg7 == arg8 + 0xC0** at the `0x917A40` call is I (§3).
5. **dT1 for triangle sub-agents** comes from the 1n TIM machine (N1's part). It was not replayed; the captured
   sep.w = −0.0069 was used as given.
6. **Code outside `.text`** (d3d9, MSVCR80, SecuROM sections) was not swept for FCW changes.
7. Out of scope (unchanged): `FUN_0091AAC0` and `FUN_008AB520` weld types other than 6.
