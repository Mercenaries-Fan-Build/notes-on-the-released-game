# Penetration-depth fallback: FUN_00944270, FUN_00944090, FUN_009223c0, and the 0x941c50 perturbation block (pc-v10)

Binary: `n2/mercs2_n2patched2.exe`. All listings are `gsk/pd/f_<va>.s` (objdump, Intel syntax).
Grades: **PROVEN** means read this run from the listing bytes or a mechanical trace with the cited
address. **INFERRED** means reasoned from proven facts or recalled. **SPECULATIVE** means a guess.

Notation: the same as `gsk_core.md` §0 (lines 54–61, read this run). The x87 operand semantics
table at `gsk_core.md` lines 36–43 is used as is.
- `f32(x)` is a `fstp/fst dword` store, which rounds to binary32.
- A value written without `f32()` stays in an x87 register. Its precision follows the x87
  precision-control (PC) field, which this subtree never sets (no `fldcw`, `pd_subtree.md` §1).
- Every memory operand in these functions is an f32 load, so it is exact.
- `a·b` with no further rounding means a register product.

Precision rule used below (INFERRED from the standard double-rounding result, Figueroa 1995; the
same as `gsk_core.md` §10 item 1):
- **Single-op, f32 in and out:** one x87 operation (+, −, ×, ÷, √) on two f32-valued operands,
  stored straight to f32, gives the correctly rounded IEEE binary32 result for PC = 24, 53 or 64,
  because 53 ≥ 2·24+2.
  - Caveat: this holds **for results in the f32 normal range**. Even under PC=24 the x87
    registers keep a 15-bit exponent, so a result that is subnormal or overflows in f32 is
    rounded once in the register and again at the store.
- **Chained ops:** chains such as `(a·b + c·d) + e·f` with one final store do depend on PC. These
  are marked **PC-dep** below.

Support-call convention: shape `vtbl+0x30` is thiscall `(dir*, out*)` and the callee pops 8. That
is INFERRED in `gsk_core.md` §1.1 (line 104). It is also consistent here:
- 0x944090 reads sA at `[esp+0x30]` and sB at `[esp+0x40..0x4c]` after the calls. With esp = E−4,
  these are exactly the out buffers E+0x2c and E+0x3c that were pushed before the calls.
- If the callee popped nothing, those reads would land on the −d copy instead.

New artefacts from this run:
- `pd/epa_fallback_consts.txt`: `peread.py` dumps of every constant below.
- `tr/epa3_944270_loop.txt`: the tracer run over the 0x944270 refinement loop body with the
  correct entry stack `--entry S_IN,ZERO`.
- `tr/epa3_944270_exit.txt`: the tracer run over the epilogue.
- `tr/epa3_9223c0_degen.txt`: the tracer run over the degenerate branch of 0x9223c0. Its esp and
  register tracking drifts after the first `ret`, so it is used for the arithmetic shape only.
  The pseudocode below is hand-read from the listing.
- `pd/epa3_sseq.py` → `pd/epa3_sseq.txt`: the step-size sequence.
- `pd/epa3_delta.py` → `pd/epa3_delta.txt`: perturbation deltas under PC = 24/53/64.

---

## 1. Constants (PROVEN, `pd/epa_fallback_consts.txt`; size from the instruction operand)

| addr | size | bits | value | used at |
|---|---|---|---|---|
| 0xb11ad8 | f32 | 0xff7fffee | −3.40282002e38 (**not** −FLT_MAX, which is 0xff7fffff) | 0x94427c, initial best.val |
| 0xbf65a0..0xbf65dc | f32[16] (.data) | identity rows | (1,0,0,0),(0,1,0,0),(0,0,1,0),(0,0,0,1) | rows 0..2 read at 0x9442a0..0x9442c2 |
| 0xb5ab50 | f64 | 0x3fefae1480000000 | 0.9900000095367432 (= f32 0x3f7d70a4 widened) | 0x94432e |
| 0xbea940 | f64 | 0x3fe0000000000000 | 0.5 | 0x944743 |
| 0xb126e0 | f32 | 0x3a83126f | 0.0010000000474974513 | 0x944750 |
| 0xbea968 | f64 | 0 | +0.0 | 0x9444ff (v.w = s·0.0) |
| 0xb58930 | f64 | 0x3f1a36e2e0000000 | 9.999999747378752e-05 (f32-valued) | 0x941d75 |
| 0xb5aa40 | f64 | 0x3f2a36e2e0000000 | 1.9999999494757503e-04 (f32-valued) | 0x941d7b |
| 0xb5aa38 | f64 | 0x3e00000000000000 | 2^-31 | 0x9407ca |

The .data rows are the file values. Their runtime contents were not read (`pd_subtree.md` §10.6).

---

## 2. FUN_00944090: evaluate one candidate direction and keep the best

### Signature (PROVEN)

The convention is custom, a mix of register and stack arguments. The caller cleans the stack
(`add esp,0x10` after two calls at 0x944312; `add esp,0x20` after four at 0x944749).
- `ecx` = shapeA. The caller sets it before every call: 0x9442bb, 0x9442f2, 0x94461f, 0x9446fa,
  0x94471a, 0x944727.
- `edi` = `const float d[4]*`, the direction, read only. 0x944090 never writes `[edi]`.
- `esi` = aTb, 16 floats. Columns c0 = +0x00, c1 = +0x10, c2 = +0x20, translation t = +0x30.
  - In the caller, esi = `[ebp+0x10]` of 0x944270 (0x94428b).
  - That value is 0x941e10's `[ebp+0x10]`, the **original, unperturbed** aTb pointer (0x941e4b,
    pushed at 0x941ec6). It is not ctx.
  - aTb and ctx.T have the same layout, element for element (PROVEN, `f_41de00.s`,
    `f_41f2c0.s`):
    - 0x941e53 calls `0x41de00(ecx=ctx, src=aTb)`.
    - 0x41de00 calls 0x41f2c0. That copies src +0x00..+0x2c to dst +0x00..+0x2c, the same offset
      each time, one `fld dword` / `fstp dword` per float (0x41f2c6..0x41f309).
    - 0x41de00 then copies +0x30..+0x3c the same way (0x41de0e..0x41de26).
    - So 0x944270 sees exactly ctx.T minus the 0x941c50 perturbation. The one caveat is the
      x87-copy quieting of signalling-NaN patterns, per `gsk_core.md` §10.
- `[ebp+0x8]` = shapeB; `[ebp+0xc]` = `best*`.
- esi, edi and ebx are preserved; ebx is saved with push/pop at 0x9440a6/0x94424b. eax, ecx and
  edx are clobbered.

### Pseudocode (PROVEN by hand-reading `f_944090.s` with esp tracked; arithmetic agrees with `tr/pd_944090.txt`)

```
// E = esp after `sub esp,0x4c`
nd   = { f32(-d.x), f32(-d.y), f32(-d.z), f32(-d.w) }        // 0x944099..0x9440cb (fchs, exact)
sA   = shapeA->vtbl[0x30](&nd, &sA)    // thiscall ecx=shapeA, args (dir=E+0x1c, out=E+0x2c), callee pops 8 (0x9440cf)
dB.x = f32( (c0.x*d.x + c0.y*d.y) + c0.z*d.z )               // 0x9440f6..0x944119   PC-dep
dB.y = f32( (c1.x*d.x + c1.y*d.y) + c1.z*d.z )               // 0x94411d..0x944130   PC-dep
dB.z = f32( (c2.x*d.x + c2.y*d.y) + c2.z*d.z )               // 0x944134..0x944145   PC-dep
dB.w = +0.0                                                  // 0x944149 fldz
sB   = shapeB->vtbl[0x30](&dB, &sB)    // ecx=shapeB ([ebp+8]), dir=E+0xc, out=E+0x3c (0x94414f)
pB.x = f32( ((c0.x*sB.x + c1.x*sB.y) + c2.x*sB.z) + t.x )    // 0x944151..0x94417c   PC-dep
pB.y = f32( ((c0.y*sB.x + c1.y*sB.y) + c2.y*sB.z) + t.y )    // 0x944180..0x944196   PC-dep
pB.z = f32( ((c0.z*sB.x + c1.z*sB.y) + c2.z*sB.z) + t.z )    // 0x94419a..0x9441b0   PC-dep
w.x  = f32(sA.x - pB.x); w.y = f32(sA.y - pB.y); w.z = f32(sA.z - pB.z)   // 0x9441b4..0x9441d8
val  = f32( (d.x*w.x + d.y*w.y) + d.z*w.z )                  // 0x9441dc..0x9441f4   PC-dep
if (best.val < val) {            // 0x9441fc fld best+0x2c; fcomp val; test ah,5; jp 0x944250
                                 // jp taken on eq/gt/un, so the update needs STRICT and ORDERED best.val < val
    best+0x20..0x2c = d[0..3]    // 0x944208..0x94421c (d.w written, then overwritten below)
    best+0x00..0x0c = sA[0..3]   // 0x944221..0x944231 (sA.w included)
    best+0x10..0x1c = sB[0..3]   // 0x944236..0x944245 (raw B-space point, sB.w included)
    best+0x2c       = val        // 0x944248
}
```

Facts about the update:
- Grouping is shown with parentheses. Within each pair the two addends commute, so only the
  grouping matters. For each pair, the listing order of the x87 operations shows exactly which
  products are paired.
- Every value written to `best` is an f32 that was loaded from memory, so the copies are exact
  (PROVEN: the x87 stack on the update path holds only f32 loads, 0x9441b4..0x944245).
- On the no-update path, 0x944250..0x94425b pops the six live registers. Nothing is written.

### Best-record layout, 0x30 bytes (PROVEN, from the stores above)

| off | content |
|---|---|
| +0x00 | sA, 4 floats: support of A along −d, in A space |
| +0x10 | sB, 4 floats: support of B along Rᵀd, raw in B space (not transformed) |
| +0x20 | d.xyz, the direction that produced the best value |
| +0x2c | val. This is the d.w slot, so "best.n.w" **is** best.val |

Before the first call, 0x944270 initialises only +0x2c, to −3.40282002e38 (0x94427c/0x944284).
The other 0x2c bytes are uninitialised stack. They become defined on the first strictly-greater
evaluation. A port must reproduce the case where no evaluation ever passes `best.val < val`
(for example every val is NaN or ≤ −3.40282002e38): the outputs are then stale stack data. NOT
DETERMINED what they contain; a faithful port must hard-fail there rather than invent values.

Meaning (INFERRED, by algebra):
- `w` is the Minkowski support M(−d) of A − T(B) along −d, the same construction as 0x940820
  with dir = −d.
- `val = d·M(−d) = −h_{A−B}(−d)`.
- Maximising val minimises the support distance along −d. This matches the EPA output
  convention of 0x940bc0 (`out.n = −face.n`, `out.dist = −face.d`, `out.pt` on A), with
  `out.n = d`.

---

## 3. FUN_00944270: direction-sampling fallback

### Signature (PROVEN)

- cdecl `(shapeA [ebp+8], shapeB [ebp+0xc], aTb [ebp+0x10], Averts [ebp+0x14], Braw [ebp+0x18], out [ebp+0x1c])`.
- The caller cleans the stack with `add esp,0x18` (0x941ece).
- The caller passes 0x941e10's own arguments (0x941eb7..0x941ec8): `Averts = [ebp+0x18]`,
  `Braw = [ebp+0x1c]`, `out = [ebp+0x28]`, `aTb = [ebp+0x10]`, which is the unperturbed caller
  transform.
- There is no return value: eax is not set. 0x941e10 then forces status 1 (0x941ed1).

Frame: G is the esp after `push ebx/esi/edi`. Locals:
- `best` at G+0x90 (0x30 bytes, so best.n = G+0xb0 and best.val = G+0xbc).
- `dir`/c1 at G+0x30, c2 at G+0x80, c3 at G+0x60, c4 at G+0x70.
- u at G+0x20, v at G+0x50, s at G+0x48.
- Scratch at G+0x18, G+0x1c and G+0x4c. G+0x18 is also the phase-1 counter.

### Phase 1: six axis directions (PROVEN, 0x944294..0x94431a)

```
best.val = f32[0xb11ad8]                       // -3.40282002e38
for row in rows 0,1,2 of 0xbf65a0:             // counter [G+0x18]=3, `sub 1; jne` -> exactly 3 passes
    d = row (4 dwords copied with integer moves, w=0)           // 0x9442a0..0x9442ca
    eval(d)                                                       // 0x9442d1
    d = { -d.x, -d.y, -d.z, -d.w } in place (fchs, so +0.0 -> -0.0)  // 0x9442d6..0x944309
    eval(d)                                                       // 0x94430d
```

The order is +X, −X, +Y, −Y, +Z, −Z. The negated rows carry signed zeros, e.g.
(−1, −0, −0, −0). A faithful port must keep the −0.0 lanes; whether a support function can tell
them apart is NOT DETERMINED, because the shape code is outside this subtree.

### Phase 2: refinement loop (PROVEN by hand, `f_944270.s` 0x94431c..0x944763; confirmed by `tr/epa3_944270_loop.txt`)

The stack at the loop join, PROVEN:
- On entry (0x94431c..0x944328) the stack is `{s=f32(1.0), +0.0}`.
- On the back-edge (0x944763 → 0x94432a), the only live value is s, from 0x944756/0x94475e.
  `fldz; fxch` then gives `{s, +0.0}` again.
- The x87 depth is 0 at all four `call 0x944090` sites (trace lines 161, 165, 169, 173) and 0 at
  0x9445c6.
- `pd_subtree.md` §8's "x87 stack depth 6 at the calls" is **refuted**. That trace had kept the
  wrong path at the join.

```
s = f32(1.0)                                         // 0x94431c
do {
    s = f32(s * 0.99000000953674316)                 // 0x94432e/0x94433c  (exact product -> one rounding; PC-independent)
    n = best+0x20..0x2c                              // n.xyz = best direction, n.w = best.val (memory, re-read each pass)

    // --- perpendicular u, 0x944340..0x9443dc ---
    ax = f32(|n.x|); ay = f32(|n.y|); az = f32(|n.z|)        // fabs, exact
    if (ax > ay) { i = 0; k = 1; m = ay }            // 0x94438d fcomp(st0=ax, ay); jne on lt/eq/un -> else-branch
    else         { i = 1; k = 0; m = ax }            //   (tie or NaN -> else)
    j = (m > az) ? k : 2                             // 0x9443ab fcompp(st0=m, az); jne on lt/eq/un keeps j=2
    u = {+0.0, +0.0, +0.0, +0.0}                     // 0x9443b8..0x9443c4 (the +0.0 kept on the stack)
    u[i] = n[j]                                      // 0x9443c8/0x9443cf  (exact copy)
    u[j] = -n[i]                                     // 0x9443d3..0x9443dc (fchs, exact)
    //   {i, j} = indices of the two largest |n| components; i in {0,1}; the smallest component is dropped
    L2 = f32( (u.x*u.x + u.y*u.y) + u.z*u.z )        // 0x9443e0..0x9443fc   PC-dep
    sc = (L2 == 0) ? +0.0                            // 0x944406 fucom; test ah,0x44; jnp -> taken only on eq
                   : f32(1.0 / f32(_CIsqrt(L2)))     // 0x944419..0x94442a (NaN goes this way)
    u.x = f32(sc*u.x); u.y = f32(sc*u.y); u.z = f32(sc*u.z); u.w = f32(sc*u.w)   // 0x94444f..0x944475

    // --- v = n x u, 0x944479..0x9444b1 ---
    v.x = f32(n.y*u.z - n.z*u.y)                     // 0x94448f fsubrp: st0(n.y*u.z) - st1(n.z*u.y)
    v.y = f32(n.z*u.x - n.x*u.z)                     // 0x94449f fsubp: st1(n.z*u.x) - st0(u.z*n.x)
    v.z = f32(n.x*u.y - n.y*u.x)                     // 0x9444af fsubp: st1(u.y*n.x) - st0(n.y*u.x)
                                                     //   (each: two register products, one subtract -> PC-dep)
    // --- scale by s, 0x9444b5..0x944505 ---
    us = { f32(u.x*s), f32(u.y*s), f32(u.z*s), f32(u.w*s) }
    vs = { f32(v.x*s), f32(v.y*s), f32(v.z*s), f32(s*0.0) }  // v.w = s * f64 0.0 (0x9444ff)

    // --- four candidates (memory slot), 0x944509..0x9445c6 ---
    c1 @G+0x30 = { f32(n.x+us.x), f32(n.y+us.y), f32(n.z+us.z), f32(n.w+us.w) }
    c2 @G+0x80 = { f32(n.x-us.x), f32(n.y-us.y), f32(n.z-us.z), f32(n.w-us.w) }
    c3 @G+0x60 = { f32(vs.x+n.x), f32(n.y+vs.y), f32(n.z+vs.z), f32(n.w+vs.w) }
    c4 @G+0x70 = { f32(n.x-vs.x), f32(n.y-vs.y), f32(n.z-vs.z), f32(n.w-vs.w) }
    //   n.w = best.val here (0x944533 loads G+0xbc), so every candidate's w lane carries best.val

    // --- ONE normalisation factor from c1 only, 0x9445ca..0x944614 ---
    L  = f32( (c1.x*c1.x + c1.y*c1.y) + c1.z*c1.z )          // PC-dep
    kk = (L == 0) ? +0.0 : f32(1.0 / f32(_CIsqrt(L)))        // 0x9445f2 fucom; jnp on eq only
    for each lane l in 0..3 of c1, c2, c3, c4:  c[l] = f32(c[l]*kk)   // 0x94461b..0x9446ee (16 stores)

    eval(c1); eval(c2); eval(c3); eval(c4)           // 0x9446f5 (edi=G+0x30), 0x94470d (G+0x80),
                                                     // 0x944722 (G+0x60), 0x94473a (G+0x70)
    s = f32(s * 0.5)                                 // 0x94473f..0x94474c
} while (s > f32 0.001)                              // 0x94475a fcom(st0=s, 0.001f); test ah,0x41; je -> loop on gt only
```

Facts about the loop:
- The candidates are all built **before** any of the four evaluations. An update inside the
  pass does not change the remaining candidates of that pass. The next pass re-reads `n` from
  `best` (PROVEN: all four c's are stored before 0x9446f5, and n is reloaded from G+0xb0..0xbc
  at 0x944340..0x94436e and 0x944509..0x944533).
- `f32(n.x+us.x)` and its siblings are single ops, so they are PC-independent. Each `c*kk` is a
  single op.

**The single `1/|n+s·u|` scale is PROVEN.**
- `kk` is computed from c1's x, y, z only (0x9445ca..0x9445e6).
- It multiplies all 16 lanes of c1, c2, c3 and c4 (0x94461b..0x9446ee).

The single scale is correct in exact arithmetic (INFERRED, algebra):
- `u·n = n[j]·n[i] − n[i]·n[j] = 0`, and |u| = 1 after scaling.
- `v = n×u` is perpendicular to n, with |v| = |n||u|.
- So for |n| = 1, all four candidates have length sqrt(1 + s²).
- The shared scale is therefore an optimisation, not a bug. The four rounded lengths differ only
  by rounding, and a port must reproduce the single kk, not renormalise each candidate.

The w lanes are scaled as well: `c.w = f32(f32(best.val ± 0)·kk)`. Through 0x944090, A's support
receives `−c.w` as its direction w lane. Whether shape support functions read dir.w is NOT
DETERMINED (outside this subtree; INFERRED from recall that Havok `getSupportingVertex` uses
xyz only).

**Termination** (PROVEN arithmetic, `pd/epa3_sseq.txt`):
- Both multipliers are f32-valued, so every product of two 24-bit significands is exact before
  the f32 store, and the sequence does not depend on PC.
- The s values used are:
  - pass 1: 0.99f (0x3f7d70a4)
  - pass 2: 0.49005002 (0x3efae7d6)
  - pass 3: 0x3e786585
  - pass 4: 0x3df5e9a0
  - pass 5: 0x3d737417
  - pass 6: 0x3cf104d9
  - pass 7: 0x3c6e9bd7
  - pass 8: 0x3bec3901
  - pass 9: 0x3b69dc46
  - pass 10: 0.0017663714 (0x3ae78597)
- After pass 10, s = f32(0.0017663714·0.5) = 0.00088318571 (0x3a678597), which is not > 0.001f.
  The loop exits.
- So there are **exactly 10 passes and 40 evaluations**, 46 in total with phase 1, independent of
  the input. No early exit exists.

### Epilogue: outputs (PROVEN, 0x944769..0x9447fc, `tr/epa3_944270_exit.txt`)

```
Averts[0][0..3] = best.sA[0..3]          // 0x944776..0x944795  (only element 0 written)
Braw[0][0..3]   = best.sB[0..3]          // 0x9447a2..0x9447bf  (only element 0 written)
out+0x20 (dist) = best.val               // 0x9447cc
out+0x00..0x08  = best.d.xyz             // 0x9447d6..0x9447e9
out+0x0c (n.w)  = best.val               // 0x9447ec (the val still on the stack)
out+0x10..0x1c  = best.sA[0..3]          // 0x9447f1..0x9447fc (point on A, w lane = sA.w)
```

On this path every output lane is written, so `out` does not depend on ctx.T.t.w (§5).

---

## 4. FUN_009223c0: barycentrics of P on triangle (a, b, c)

### Signature (PROVEN)

- cdecl `(P [ebp+8], a [ebp+0xc], b [ebp+0x10], c [ebp+0x14], out [ebp+0x18])`. There is no
  return value.
- `out[0]`, `out[1]` and `out[2]` are the weights of a, b and c. Only x, y and z of the inputs
  are read.
- esp is constant (e = H−4) from 0x9223cf to the returns, except on path D below, which pops esi
  at 0x92274a before its stores; the offsets there are re-based by +4.
- The tracer's esp in the branch blocks of `tr/pd_9223c0.txt` and `tr/epa3_9223c0_degen.txt`
  drifts. The slot names there are wrong, and the pseudocode below is hand-read.

### Common prefix (PROVEN, 0x9223c9..0x9224aa)

```
u  = { f32(a.x-b.x), f32(a.y-b.y), f32(a.z-b.z) }      // e+0x20..0x28; also kept in registers
v  = { f32(c.x-b.x), f32(c.y-b.y), f32(c.z-b.z) }      // e+0x30..0x38
uu = f32( (u.x*u.x + u.y*u.y) + u.z*u.z )              // e+0x04   PC-dep
vv = f32( (v.x*v.x + v.y*v.y) + v.z*v.z )              // e+0x08   PC-dep (v.z via an exact f64 copy, 0x922445)
uv = f32( (v.y*u.y + v.x*u.x) + v.z*u.z )              // e+0x0c   PC-dep
D  = f32( f32(vv*uu) - f32(uv*uv) )                    // 0x922479..0x922497; e+0x10
if (0 < D)  -> regular                                 // 0x9224a1 fcom(st0=D, 0); jne on lt/eq/un -> degenerate
```

### Regular branch, D > 0 strictly and ordered (PROVEN, 0x9224b0..0x922578; agrees with `tr/pd_9223c0.txt` lines 45–82)

```
inv = f32(1.0 / D)                                     // 0x9224b9
w   = { f32(b.x-P.x), f32(b.y-P.y), f32(b.z-P.z) }      // e+0x20..0x28 (overwrites u's slot; u stays in registers)
uw  = f32( (u.x*w.x + u.y*w.y) + u.z*w.z )             // 0x9224fc   PC-dep
vw  = f32( (v.x*w.x + v.y*w.y) + v.z*w.z )             // 0x922516   PC-dep
s1  = f32( vw*uv - uw*vv )                             // 0x922532 fsubp st3: st3(vw*uv) - st0(uw*vv)
s2  = f32( uw*uv - vw*uu )                             // 0x922542 fsubrp: st0(uv*uw) - st1(vw*uu)
out[0] = f32(s1*inv)                                   // 0x922558
out[1] = f32( ((D - s1) - s2) * inv )                  // 0x92255c..0x92256c   PC-dep (D, s1, s2 are f32 reloads)
out[2] = f32(s2*inv)                                   // 0x922571
```

INFERRED by algebra: this is the least-squares projection of P onto b + αu + βv, with α = s1/D,
β = s2/D, and weights (α, 1−α−β, β).

### Degenerate branch, D ≤ 0 or NaN (PROVEN by hand, 0x922579..0x9227a1)

```
q  = { f32(a.x-c.x), f32(a.y-c.y), f32(a.z-c.z) }      // e+0x20..0x28
qq = f32( (q.x*q.x + q.y*q.y) + q.z*q.z )              // 0x9225b7 -> e+0x0c (OVERWRITES uv's slot)
if (vv > uu || unordered) {                            // 0x9225c3 fcom(st0=vv, uu); test 0x41; jp -> taken on gt/un
    if (qq < vv || unordered) {                        // 0x9226d8 fcom(st0=qq, vv); test ah,1; jne -> lt/un
        // path D: edge b-c (0x922748)
        r = { f32(P.x-b.x), f32(P.y-b.y), f32(P.z-b.z) }
        t = f32( f32((v.x*r.x + v.y*r.y) + v.z*r.z) / vv )     // v.x,v.y from registers, v.z from memory e+0x38
        out = { +0.0, f32(1.0 - t), t }
    } else {
        // path C: edge c-a (0x9226e4)
        r = { f32(P.x-c.x), f32(P.y-c.y), f32(P.z-c.z) }
        t = f32( f32((r.y*q.y + r.x*q.x) + r.z*q.z) / qq )
        out = { t, +0.0, f32(1.0 - t) }
    }
} else {                                               // uu >= vv, ordered
    if (uu > qq || unordered) {                        // 0x9225e0 fcom(st0=uu, qq); test 0x41; jp -> gt/un
        // path B: edge a-b (0x92266d)
        r = { f32(P.x-b.x), f32(P.y-b.y), f32(P.z-b.z) }
        t = f32( f32((u.x*r.x + u.y*r.y) + u.z*r.z) / uu )    // u from registers (exact f32)
        out = { t, f32(1.0 - t), +0.0 }
    } else {
        out[1] = +0.0                                  // 0x9225fa
        if (0 < qq) {                                  // 0x9225fd fcom(st0=0, qq); test ah,5; jp -> taken on eq/gt/un
            // path A: edge c-a (0x922606), same formula as path C
            r = { f32(P.x-c.x), f32(P.y-c.y), f32(P.z-c.z) }
            t = f32( f32((r.y*q.y + r.x*q.x) + r.z*q.z) / qq )
            out[0] = t; out[2] = f32(1.0 - t)
        } else {
            out[0] = +0.0; out[2] = +0.0               // 0x922661..0x922665 (all three weights 0)
        }
    }
}
```

Facts about the degenerate branch:
- Each `t` divides an f32 numerator by an f32 squared length, then stores. That is a single op,
  so it is PC-independent. `1.0 − t` is likewise a single op.
- The numerator sums are PC-dep.
- Only path A tests its divisor against 0.
  - Paths B, C and D divide without a test. Their guards imply a positive divisor only for
    ordered, non-negative squared lengths.
  - Under NaN, the unordered outcomes route to B or D, and the division propagates NaN.

The Ghidra decomp `pd/out2/d_009223c0.c` has the same branch structure and edge choices.

---

## 5. FUN_00941c50 perturbation block, 0x941d49..0x941ddd (PROVEN, `f_941c50.s`)

K is the esp after `push ebx/esi/edi`. It is the same at 0x941d49 on both entry paths, because
0x940f50 is `ret 8` and 0x9409f0 is `ret 0x10`, with balanced pushes. The res slot is K+0xc
(0x941c68/0x941c70). The polytope starts at K+0x20 (0x941ca0, after 3 pushes).

```
ctx.attempt += 1                                   // 0x941d4e
if attempt == 1: ctx.count = 1; goto retry         // 0x941d56/0x941d58
if attempt >= 20: return ebx (= res = 3)           // 0x941d60 cmp 0x14; jge 0x941df8 (ebx loaded at 0x941c82 or 0x941d3c)
ctx.count = 0                                      // 0x941d69
r     = FUN_9407b0(eax = attempt)                  // u = (0x3039 - attempt*0x3e39b193) & 0x7fffffff; r = f32(u*2^-31)
delta = f32( (r - 9.999999747e-05) * 1.999999995e-04 )   // 0x941d75..0x941d81   PC-dep (chain of 2)
[K+0x10] = [K+0x14] = [K+0x18] = delta            // 0x941d89..0x941d91 (one value, three copies)
T.t.x = f32(delta + T.t.x)                         // 0x941d95..0x941d9c, stored back at 0x941dc5
T.t.y = f32(T.t.y + delta)                         // 0x941da0..0x941da7 -> 0x941dcc
T.t.z = f32(T.t.z + delta)                         // 0x941dab..0x941db2 -> 0x941dd3
T.t.w = f32(T.t.w + f32[K+0x1c]); [K+0x1c] = same  // 0x941db6..0x941dbd, stored to ctx+0x3c at 0x941dda
goto retry                                         // 0x941ddd -> 0x941c65 (res re-zeroed at 0x941c70)
```

Facts about the block:
- The run sequence is: one initial run, a retry at attempt 1 with count = 1, then perturbed retries
  at attempts 2..19. That is at most 20 runs of 0x940f50, 18 of them perturbed. The perturbation
  accumulates in ctx.T.
- The deltas are in `pd/epa3_delta.txt`.
  - For attempts 3 and 5, PC = 24 gives a delta 1 ulp lower than PC = 53/64:
    0x38e31efb vs 0x38e31efc, and 0x38eec053 vs 0x38eec054.
  - The other 16 attempts agree under all three PC settings.

**What `[esp+0x1c]` is at 0x941db9** (PROVEN as a data-flow fact; its content is NOT DETERMINED):
- It is K+0x1c, the fourth lane of the 16-byte-aligned local vec4 at K+0x10. The three x, y, z
  lanes are filled with delta at 0x941d89..0x941d91; **the w lane is never filled**.
- No instruction in 0x941c50 writes K+0x1c except 0x941dbd itself. Every `[esp+…]` store in
  `f_941c50.s` was checked: 0x941c70, 0x941cc5, 0x941d06 and 0x941d81..0x941dbd.
- The callee frames lie below K. The callees write only through their pointer arguments: poly at
  K+0x20 and up, res at K+0xc, and out.
  - That callees never write below their pointer arguments is INFERRED, not checked callee by
    callee.
- Consequences:
  - **Attempt 2:** `T.t.w ← f32(T.t.w₀ + g)`, where g is whatever stale stack bytes occupy K+0x1c
    inside 0x941c50's alloca'd frame. These cannot be determined statically and could even be
    NaN or Inf bit patterns.
  - **Attempts 3..19:** `[K+0x1c]` holds the previous new T.t.w, so `T.t.w ← f32(2·T.t.w)`. It
    doubles each attempt.

**Who reads ctx.T.t.w = ctx+0x3c** (PROVEN, grep `pd/epa3_grep_3x.txt` over every subtree
listing for `0x3c]`):
- The only reader is **0x9412b1** in 0x940f50 case 0: `dir.w = −ctx.T.t.w`, stored at the case-0
  local dir+0xc.
  - The other `+0x3c` operands are vrec/array element 3 (0x9423c0), the aTb→ctx copy (0x41de00),
    and face/edge stores (0x943730).
  - 0x940820 adds only t.x, t.y and t.z (0x940908, 0x940922, 0x94093c). The w lane of the
    support difference is `v10.w − 0.0` (0x940962).
  - Case 0's |t|² uses only x, y and z (0x9412bd..0x9412d4).
- If `eps2 >= f32(|t|²)`, dir is replaced by .data row 1, whose w is 0.0 (0x9412ea..0x941317).
- Otherwise dir.w = −T.t.w reaches two places:
  - **(a)** shapeA's support call through 0x940820. The dir pointer is passed unchanged to
    `vtbl+0x30` (0x940840 push edx = `[ebp+8]`).
  - **(b)** `out.n.w` on the separated exit 0x94183e (0x941894/0x94189b `out+0xc ← dir.w`).
    0x94183e is reached only from case 0 (0x941371).
- **out.n.w is consumed by the caller.**
  - 0x9118d0 passes `out9 = esp+0x60` (0x911ce4, pushed first at 0x911ce8).
  - After 0x941e10 returns, it copies `out9[0..3]` into GSK `this.n` (+0x120..+0x12C):
    0x911fcd..0x911ff0, `pd/epa3_9118d0_out9.txt`.
  - The w lane is read at 0x911fec (`[esp+0x68]` after the `pop edi` at 0x911fd1) and stored to
    `this+0x12C` at 0x911ff0.
  - The esp balance between 0x911ce4 and 0x911fcd is taken from `gsk_core.md` §9.1, where the pop
    interleaving is marked as checked. It was not re-derived here.
  - According to `gsk_core.md` §3.8 and §2, the core's FINISH later overwrites `this+0x12C` with
    the distance (0x9138cd). Its TRY_A passes `−n.w` into shapeA's support direction (§3.6).
  - Whether a TRY_A can run between the penetration return and FINISH is the parent's control
    flow, and this run did not determine it.
- Every run after attempt 2 restarts at count = 0, so case 0 runs on every perturbed retry.
- When the driver finally returns 3 and 0x944270 runs, every lane of `out` is overwritten (§3),
  and T.t.w no longer matters for `out`.
- 0x944270 itself uses the unperturbed aTb, not ctx (§2).

---

## 6. Corrections to `pd_subtree.md` §8 and §10

- "best.val = −3.40282e38f": the bits are 0xff7fffee = −3.40282002e38, not −FLT_MAX (PROVEN, §1).
- "x87 stack depth 6 at the calls 0x9446f5–0x94473a": **refuted**; the depth is 0 (PROVEN, §3).
- "loop count 3 INFERRED": now PROVEN (0x944294, 0x944315/0x94431a).
- "candidates n±s·u, n±s·v, all scaled by ONE factor 1/|n+s·u|": PROVEN. In exact arithmetic it is
  equivalent to per-candidate normalisation (§3).
- Additional facts:
  - v is n×u computed from the **normalised** u, before the s scaling.
  - The candidate w lanes carry best.val.
  - The evaluation order is c1, c2, c3, c4 = n+su, n−su, n+sv, n−sv.
- 0x9223c0 is a projection, with the edge choice and tie/NaN rules of §4. The degenerate branch
  overwrites uv's slot with |a−c|² (0x9225b7).

## 7. NOT DETERMINED

1. **Content of K+0x1c on the first perturbation** (attempt 2). It is stale stack data and cannot
   be determined statically. Tried: every store in `f_941c50.s`, and the callee pointer arguments.
   Settling it needs a runtime read.
2. **Whether the garbage-dependent T.t.w ever changes a number.**
   - out.n.w *is* copied into GSK `this.n.w` (0x911fec/0x911ff0, §5).
   - Not determined:
     - (a) whether shape `vtbl+0x30` implementations read dir.w. They are virtual and were not
       traced; this is the same as `gsk_core.md` §12.2.
     - (b) whether `this.n.w` reaches a TRY_A support call before FINISH overwrites it at
       0x9138cd. That is the parent's control flow.
   - Tried: a grep for `+0x3c` over every subtree listing (`pd/epa3_grep_3x.txt`), the case-0
     direction slots (`pd/epa3_grep_dir.txt`), and the 0x9118d0 readback.
3. **x87 precision control at runtime.** It decides every PC-dep line above, and §5's deltas for
   attempts 3 and 5. The subtree contains no `fldcw`.
   - INFERRED (recall): Direct3D 9 `CreateDevice` without `D3DCREATE_FPU_PRESERVE` sets PC = 24
     on the creating thread.
   - Neither the device-creation flags nor the physics thread's control word were checked.
4. **`_CIsqrt` internals** (MSVCR80, IAT 0xb053ac). Its argument and result are in st0, which
   the stack shape at 0x944419/0x9445ff is consistent with; the routine was not disassembled.
   Assuming a plain `fsqrt`, `f32(sqrt)` is correctly rounded for any PC (INFERRED).
5. **Uninitialised best record** if no evaluation passes the strict `best.val < val` test
   (all NaN, or val ≤ −3.40282002e38). The outputs would then be stale stack data.
6. **Signed-zero sensitivity** of the shape support functions to the −0.0 lanes of the negated
   axis rows, and to the +0.0 versus −0.0 lanes of u copied from n. This is outside the subtree.
