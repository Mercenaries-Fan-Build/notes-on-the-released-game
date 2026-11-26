---
status: current
evidence: mixed (graded per claim)
---

# N4: shape supports, the 1n TIM machine around each triangle entry, entry creation, hull getAabb (pc-v10)

Read on 2026-11-25. Scope: the opening Speed Boat hull (`hkpConvexVerticesShape`, 127 vertices, radius 0.05) against
`WpMeshShape16` terrain triangles (radius 0.01, extruded by (0, −10, 0, 0)), discrete (PSI) path only.

Working folder: `/private/tmp/claude-501/-Volumes-Projects-mercenaries-game/d08a21c0-8307-469b-be20-8c9b42a8712a/scratchpad/havok_port/n4/`.
Every script and output named below is in `n4/gate/` unless a path is given. Exe sha256 8c179a99…bc7ba (`n4/exe_sha.txt`).
Listings are `objdump -d --x86-asm-syntax=intel` of the original exe (file offset = VA − 0x400000), or N1/N3 listings
re-read this run where cited.

Grades: **P** proven this run (address, command or output file). **I** inferred. **S** speculative. **HK** recalled
Havok 5.5 knowledge (at best I; used only as a label). **ND** not determined.

Notation as in `manifold_arithmetic.md`: `f32(x)` = one `fstp/fst dword` (round to binary32); everything else is an x87
register value (PC 53, contact_solve.md §0); operand order and association are the binary's. Compare outcomes are
decoded from `fnstsw; test ah,m; jcc` with ah lt=0x01, eq=0x40, gt=0, un=0x45.

## 0. How the results were checked (method) — P

1. **Port transcriptions** in Python on the exact-rational x87 model `x87.py` (copied from N3): `sup.py` (supports),
   `aabb.py:get_aabb`, `create.py:create_port`/`create_ab20`, `lintim.py`.
2. **A second, independent method:** `x86mini.py`, a small interpreter that executes the objdump listing text itself
   (integer + x87 instructions, x87 exact rationals at PC 53, f32 rounding at each dword store, `call` into other loaded
   listings, any instruction form it does not implement raises). Memory = an overlay for writes, backed by the capture
   (heap) and the exe file (code, vtables, tables). The listing interpreter shares only the arithmetic primitives with
   the transcriptions, not the control flow, operand order or compare decoding.
3. **Captures:** winch `20261021_chris-jacobs-flying-winch.dmp` (sub-entry 0x1E35C270, hull 0x29C70DA0, mesh 0x29655400,
   boat motion 0x1DF9D0E0, terrain motion 0x1E45C8E0) and first mission `20261103_new-game-first-mission-start.dmp`
   (boat body 0x1EBB8000, list 0x1EB93480 → child array 0x1ED44E00; **child 11 = hull 0x296676E0, 127 vertices, 32
   blocks, rotatedVertices 0x29667740** (`walkboat2.txt`)).

| Gate | Cases | Result | File |
|---|---|---|---|
| Hull support 0x8BAF00 and triangle support 0x8AB120, transcription vs listing, captured hulls (winch 177 v; boat children 11, 10, 8, 7, 0, 2) and 400 synthetic triangles, 162/15 directions each | 7134 | 0 mismatches, exit 0 | `cmp_sup.txt` (re-run after interpreter changes: `cmp_sup3.txt`) |
| All 15 lane masks of the hull dispatch exercised | — | every mask 1..15 hit | `cov_mask.txt` |
| Exhaustive ties vs the closed-form rules (§1.3): every weak ordering of one block (256), ties with the initial best (81), two-block ties (1536); triangle: every {1,2,3}³ dot pattern × extrusion dot ∈ {−1, −0, +0, +1} | 1873 + 108 | 0 mismatches, exit 0 | `ties.txt` |
| convertVertexIds 0x8BB230 / 0x8AB260, n = 1..9, random ids incl. padding ids and triangle ids 3..5 | 540 | 0 mismatches | `ties.txt` |
| getAabb 0x8BB7C0 + 0x8BBE50, captured and random transforms, tol ∈ {0.05, 0.1, 0, 0.025} | 300 | 0 mismatches, exit 0 | `aabb.txt` |
| Entry create 0x901380 → 0x92AB20 → 0x92A8F0 (+ supports, convertVertexIds, vtable +0x24), winch triangle with captured and start-of-step aTb, 40 random | 43 | 0 mismatches, exit 0 | `create.txt` |
| GSK replay (N3's `gategsk.py`) with the exe supports, at the **start-of-step** transform, then the 1n plane test on the captured `linearTimInfo` | 4 words | **sep.x, sep.y, sep.z and sep.w all bit-exact** at PC 53 and 64; not at PC 24 | `gategsk_prev_pc53.txt`, `_pc64`, `_pc24` |

---

## 1. Support functions (vtable +0x30)

### 1.1 Vtables and helpers — P (`n4/vt.txt`: `rd.py b578fc:I:16 b57b34:I:16 cdb250:I:6 cdb224:f:6`)

| Class (vtable) | +0x1C | +0x24 | +0x30 support | +0x34 convertVertexIds | +0x38 |
|---|---|---|---|---|---|
| hkpConvexVerticesShape 0xB578FC | getAabb 0x8BB7C0 | 0x8BACB0 = `return [this+0x4C]` (numVertices) | **0x8BAF00** | 0x8BB230 | 0x8A8EB0 |
| hkpTriangleShape 0xB57B34 | 0x8AAC10 | 0x8AAA30 = `3*(byte[this+0x17]+1)` | **0x8AB120** | 0x8AB260 | weld 0x8AB520 |

Both supports are `thiscall(this; const f32* dir, f32* out)`, `ret 8` (0x8BB1F3, 0x8AB254). Both read only dir.x/y/z
(the w lane is never loaded) and write out = (x, y, z, w) with **out.w = bits(id | 0x3F000000)** (0x8BB1D4/0x8BB1E8,
0x8AB246/0x8AB24C). This closes `gsk_core.md` ND items 2 and 8.

Hull fields used: +0x40 rotatedVertices (blocks of 48 bytes: X[4] at +0, Y[4] at +0x10, Z[4] at +0x20), +0x44 block
count, +0x4C numVertices (only through +0x24). P (0x8BAF0F, 0x8BAF29; capture headers `walkboat2.txt`).

### 1.2 Hull support `0x8BAF00` — P

```
best = f32 [0xB11AD8]            // bits 0xFF7FFFEE = -3.40282e38 (not -FLT_MAX); 4 lanes, all equal (0x8BAF09..24)
id   = 0                         // edx = 0 (0x8BAF2C); returned unchanged if no lane ever beats best
if 4*nBlocks <= 0: goto OUT      // 0x8BAF3C jle (then reads block 0 of rotatedVertices)
d = (dir.x, dir.y, dir.z)        // re-stored f32 (exact)
for b = 0 .. nBlocks-1:          // ascending; esi = 4b+3, loop while 4(b+1) < 4*nBlocks (0x8BB1A9 jl)
    for k = 0..3:  px[k] = f32(d.x * X[k])                  // 0x8BAF79..0x8BAF98
    for k = 0..3:  py[k] = f32(Y[k] * d.y)                  // 0x8BAF9C..0x8BAFBB
    for k = 0..3:  s[k]  = f32(py[k] + px[k])               // 0x8BAFBF..0x8BAFEB
    for k = 0..3:  pz[k] = f32(Z[k] * d.z)                  // 0x8BAFEF..0x8BB00D
    for k = 0..3:  dot[k] = f32(pz[k] + s[k])               // 0x8BB011..0x8BB03D
    mask = 8*(dot0 > best) | 4*(dot1 > best) | 2*(dot2 > best) | 1*(dot3 > best)
                                 // each: fcom dot_k, best; test ah,0x41 -> bit set only on "gt" (strict; NaN never sets)
    if mask == 0: continue       // 0x8BB0B8
    lane = select(mask, dot)     // jump table 0x8BB1F8 (n4/tbl.txt), below
    best = dot[lane]  (broadcast to the 4 lanes; exact)     // 0x8BB0EF..0x8BB103
    id   = 4*b + lane
OUT: out = (X[id&3], Y[id&3], Z[id&3]) of block id>>2;  out.w = bits(id | 0x3F000000)   // 0x8BB1BB..0x8BB1EB
```

`select` (jump table `[0x8bb0ca, 0x8bb0e7, 0x8bb0de, 0x8bb10c, 0x8bb0d3, 0x8bb10c, 0x8bb10c, 0x8bb152, 0x8bb0ca, 0x8bb10c,
0x8bb10c, 0x8bb138]`, masks > 11 → 0x8BB10C):
- single lane (mask 8, 4, 2, 1): that lane.
- mask 7 (lanes 1,2,3): path B. mask 11 (lanes 0,2,3): path A. Every other multi-lane mask: `d0 > d1` (fcom; test 0x41;
  jne) → path A, else (≤ or unordered) → path B (0x8BB10C).
- **path A** (lanes 0,2,3): if `!(d2 < d0)` (test 5; jp: ≥ or unordered) → lane = `!(d3 < d2)` ? 3 : 2 (0x8BB144);
  else lane = `!(d3 < d0)` ? 3 : 0 (0x8BB12A).
- **path B** (lanes 1,2,3): if `!(d2 < d1)` → lane = `(d2 > d3)` ? 2 : 3 (0x8BB17C, test 0x41/jne); else lane =
  `(d1 > d3)` ? 1 : 3 (0x8BB163).

### 1.3 Tie-breaking rules (closed form, gated exhaustively, `ties.txt`) — P

- **Hull:** scan blocks in ascending order; a block updates only if its maximum dot is **strictly greater** than the running
  best; then the winner is the **highest lane** of that block attaining the block maximum. So: across blocks the
  **earliest** block wins a tie, inside a block the **highest lane** wins. Initial best = f32 0xFF7FFFEE, id 0 if nothing
  beats it.
- **Padding lanes are part of the result.** In every captured hull the unused lanes of the last block are copies of the
  last real vertex (`cov_sup.txt`, 7/7 hulls), so they win ties against it by the rule above and the support returns
  **ids ≥ numVertices** (42 of 1134 sampled directions; for the 127-vertex boat hull, vertex 126 is reported as id 127).
  convertVertexIds (§1.5) accepts these ids. They enter the GSK cache and the manifold id tables, and 0x914800 matches
  points by id, so a port must keep the padded block layout and must not clamp or remap ids.
- **Triangle:** equal dots resolve with priority **1, then 2, then 0** (below).
- NaN: by the decoded jumps, an unordered lane never sets a mask bit; inside the multi-lane selection unordered takes the
  "≥" branch at `test 5/jp` and the "≤" branch at `test 0x41/jne`. P by decode, not exercised (the interpreter refuses NaN
  loads).

### 1.4 Triangle support `0x8AB120` (triangle: +0x20/+0x30/+0x40 vertices, +0x50 extrusion) — P

```
D0 = f32((v0.y*d.y + v0.x*d.x) + v0.z*d.z)     // 0x8AB142..0x8AB16B
D1 = f32((v1.y*d.y + v1.x*d.x) + v1.z*d.z)     // 0x8AB16F..0x8AB182
D2 = f32((v2.y*d.y + v2.x*d.x) + v2.z*d.z)     // 0x8AB186..0x8AB199
i = (D1 < D2) ? 2 : 1                          // fcom D1,D2; test 5; jp -> 1 on >=, unordered (0x8AB1A5)
if best(i) < D0: i = 0                         // fcompp; test 5; jp keeps i on >=, unordered (0x8AB1CA)
out = vertex[i] (4 lanes copied)
E = f32((ext.y*d.y + d.x*ext.x) + ext.z*d.z)   // 0x8AB1F7..0x8AB20C
if E > 0.0 (f32 [0xB11AD0] = 0; strict, NaN no):          // fcomp; test 0x41; jne skips (0x8AB214)
    out = (f32(out.x+ext.x), f32(ext.y+out.y), f32(ext.z+out.z), f32(ext.w+out.w));  i += 3
out.w = bits(i | 0x3F000000)
```
- The extrusion is added from the dot sign alone; `isExtruded` (+0x17) is **not** read. A non-extruded triangle has
  ext = 0 so E = ±0, which never extrudes (`ties.txt` covers −0, +0).
- For terrain (ext = (0, −10, 0, 0)) E = f32(−10·d.y + …): the extruded copy wins whenever d.y < 0.

### 1.5 convertVertexIds — P (gated, `ties.txt`; confirms N3 §4.3)
- Hull 0x8BB230 (`ids*, n, out*`, `ret 0xC`): out[i] = (X, Y, Z)[id&3] of block id>>2 (`sar`), w = bits(id|0x3F000000);
  4-way unrolled then a tail loop; identical results for every n.
- Triangle 0x8AB260: `v = tri.vertex[tab250[id]]` (0xCDB250 = {0,1,2,0,1,2}), `k = f32 tab224[id]` (0xCDB224 =
  {0,0,0,1,1,1}), `x = f32(ext.x*k + v.x)`, `y = f32(k*ext.y + v.y)`, `z = f32(ext.z*k + v.z)`, `w = f32(k*ext.w + v.w)`
  then overwritten by bits(id|0x3F000000). For k = 1 this equals the support's `f32(v + ext)`.

### 1.6 The GSK gate with the exe supports — P (`gategsk4_pc53.txt`, script `gategsk4.py`)
N3's TRY_A/TRY_B brute force was replaced by §1.2/§1.4.
- TRY_A: the exe support returns hull id 0x56 (as N3), qA = 0, rejected.
- TRY_B: all three triangle dots round to the **same f32 0x452C9A13**, so the exe returns **id 1** (N3's unrounded
  brute force picked 2). qB0 < eL, rejected; the outcome and sep bits are unchanged (−2/−1 ulp at the captured
  transform, as N3).
- The remaining ulp gap is explained in §2.6.

---

## 2. The 1n TIM machine around each triangle entry (`FUN_0090C290`, discrete path)

Listing: N1's `n1/dis_90c290.txt` (original exe, re-read this run) plus `n4/d_90cdc0.s` (tail). Frame names: `in3'` =
the 0x70-byte child input copy at esp+0x60 (`+0x50` = esp+0xB0 dist, `+0x60..0x6C` = esp+0xC0..0xCC linearTimInfo),
`ti` = `in3'.input` (= [esp+0x68]), `qi = ti+0x60`, `e` = the sub-entry (ebx).

### 2.1 Where linearTimInfo comes from — P

It is built once per top-level entry by the Nn machine `FUN_00909CA0`, command 2 (0x90A06F..0x90A1BA,
`n1/dis_909cac.txt`), with mA = bodyA motion state (cdBodyA+8), mB = bodyB motion state:
```
dt = f32 ti.stepInfo.deltaTime (+0x58)
dA[k] = f32(mA[+0x40+4k] - mA[+0x50+4k])        k = 0..3     // com0 - com1
dB[k] = f32(mB[+0x50+4k] - mB[+0x40+4k])                       // com1 - com0
fA = f32(mA[+0x5C] * dt)                                       // 0x90A0E8..0x90A0F5 (mA+0x5C = com1.w)
fB = f32(dt * mB[+0x5C])                                       // 0x90A0F9..0x90A0FC
lin[k] = f32(dB[k]*fB + f32(dA[k]*fA))          k = 0..3     // 0x90A100..0x90A18F
lin.w  = f32(((fA*mA[+0x9C])*mA[+0xA0]) + ((fB*mB[+0x9C])*mB[+0xA0]))   // 0x90A196..0x90A1BA, overwrites lane 3
in3+0x54 = 0
```
- Field meaning, P on both captures (`lintim.txt`): mA+0x4C = stepInfo.start (com0.w), mA+0x5C = stepInfo.invDt (com1.w),
  so fA = f32(invDt·dt) = **1.0** in both captures. For the fixed terrain +0x5C = 0, so fB = 0 and dB = 0. +0x9C =
  deltaAngle.w, +0xA0 = objectRadius (S2 layout, `step_and_integrate.md` header, P there).
- So lin.xyz = −(A's centre-of-mass displacement over the step) + B's, and lin.w = |rotation angle|·objectRadius ≥ 0
  (I: names from S2's layout).
- It reaches the triangle loop unchanged:
  - the agent #9 child copy (0x90CF30) and the 1n copy (0x90C2F5..0x90C331) are 0x70-byte copies that include +0x60;
  - `FUN_009089A0` passes `&in3+0x60` to `FUN_00907EF0`, whose stores are all esp-relative (`n4/g907ef0.txt`);
  - no other write was found. P for these three functions; I that no other agent in the chain writes it.
- Captured values (winch): lin = (bits 0x39800000, 0x3B568000, 0xBA000000, w 0x3B85A877). First mission: (0, 0xBB2B4000,
  0, w 0x3C61CF01).

### 2.2 Merge loop (per key) — P except where marked
- Welding hook at entry (0x90C2A8..0x90C2EF): save `output+0x3080`. If it was non-NULL, set it to NULL. If it was NULL and
  `cont->vtbl[+0x1C]()` is true (WpMesh: true, N1), point it at a local buffer P with P[0] = P+0x408 (end of the 12-byte
  potential records), P[1] = P+8 (end of the 4-byte representative list). See §3.
- Keys (ascending unsigned, −1 terminated) are merged with the old stream:
  - `key == e.keyB` (+8): copy e into the new stream, then dispatch (0x90C440);
  - `key <u e.keyB`: new entry (§4);
  - `key >u e.keyB`: `agent3[e.type].slot1` (0x16B4) destroys the old entry (0x90C48B), and the key is compared again.
  - With a NULL key list (query overflow), every old entry is copied and re-dispatched (0x90C3D7).
  - The loop ends when the old sectors are exhausted (0x90CD2B..0x90CD35). The old END entry (keyB 0xFFFFFFFF) matches
    the −1 key and is copied (cmd 1 → 0x90CCDD). I for the END detail.
- A new sector starts when `used + nextOldEntrySize > 0x1A0` (0x90CD5C..0x90CD71). Memory only; it does not change numbers.
- Dispatch is `jmp [0x90CF10 + 4*cmd]` = {0: 0x90CCDD, 1: 0x90CCDD, 2: 0x90C68B, 3: 0x90C6E6, **4: 0x90CAEB**, 5:
  0x90C812, 6: 0x90C64B} (`n4/tbl2.txt`).
- The counter [esp+0x38], incremented on every plane cull, only goes to the monitor stream (`fild` at 0x90CE97). It does
  not affect physics.

### 2.3 Command 4 (our triangle entries), 0x90CAEB..0x90CCDB, in binary order — P

```
if ti.start(+0x50) == e.time(+0xC)              // fucompp; test ah,0x44; jnp -> only ordered-equal  (0x90CAF9)
    goto PLANE
if ti.end(+0x54) <= e.time                      // fcompp; test ah,0x41; jnp -> lt or eq            (0x90CB0C)
    goto PLANE
if qi[+0x10] != 0: goto CONT                    // continuous; not taken for PSI (0x90CB1C)
// RESET (stale entry: new, or a skipped step)
e.time = f32 ti.end                                                  // 0x90CB26
d = f32(qi.f32[+0x14] * f64 0.10000000149011612)                     // [0xB57F98] = 0x3FB99999A0000000
e.sep = (0, 0, 0, d)                                                 // fldz x4, then fst d -> +0x1C
in3'.dist(+0x50) = d                                                 // 0x90CB53 fstp [esp+0xB0]
goto CALL_BODY                                                       // 0x90CB50
PLANE (0x90CC30):
e.time = f32 ti.end
p    = f32(((e.sep.y*lin.y + e.sep.x*lin.x) + e.sep.z*lin.z) + lin.w)     // 0x90CC3D..0x90CC68
dist = f32(e.sep.w - p)                                                   // 0x90CC6C..0x90CC70
if (ti.tolerance(+4) > dist) or unordered:      // fcomp tol,dist; test 0x41; jp (0x90CC82)
    in3'.dist = dist                            // x87 top still = dist; stored by the fstp at 0x90CB53
    goto CALL_BODY                              // e.sep.w is NOT written on this path (the fst at 0x90CB4D precedes the label)
else:                                           // dist >= tol (ordered): the hull is predicted clear
    e.sep.w = dist                                                   // 0x90CC88
    if e.numContactPoints(+2) != 0:
        e.size = agent3[e.type].slot2(e, e+0x20, in3'.mgr, output.constraintOwner(+4)) - e   // 0x901310 removePoints
    // no narrowphase this step
    next entry
CALL_BODY (0x90CB50):
bodyB.shape = cont->getChildShape(key, 0x400-byte stack buffer)  (vtbl +0x14); bodyB.key = key
e.size = agent3[e.type].process(&in3', e, e+0x20, &e.sep, output) - e           // slot +0x16DC = 0x901510
CONT (0x90CBAD, continuous only): FUN_0090C1A0 once per call, then agent slot10 (+0x16D8 = 0x9013E0) rewrites e.sep,
then PLANE.  Off-path for the boat (qi[+0x10] = 0).
```

- For the boat pair the quality is the entry's byte +0xC = 1, so qi = info[0] (winch: entry 0x1DB26600, `winch_q.txt`).
  Values: qi+0x0C = −0.01, +0x10 = 0, +0x14 = bits 0xE02D78EC (−5.0000001e19). **The reset d is bits 0xDE8AC723
  (−4.99999999e18)** (`reset.txt`).
- Note: the world master `collisionInput+0x60` is the last value a job wrote. In the winch capture it points to a quality
  with +0x10 = 1 and +0x14 = −0.5. A port must take qi from each entry's quality byte, never from the master input. P.
- `e.time` holds the step end at which it was last processed. The winch sub-entry has time = 45.74236 = stepInfo.end of
  the captured step (`lintim.txt`). P.
- In steady state the next step's start equals the previous end, so PLANE runs every step.
  - For the captured step this is **P**: the §2.6 chain reproduces sep.w only through the PLANE formula. The
    `end <= time` branch cannot have fired, because time = end(k−1) < end(k). So the `start(k) == end(k−1)`
    ordered-equal f32 test was taken.
  - For every step it stays I (S2's stepInfo construction).
- Radii and tolerance in the TIM test:
  - The plane test uses only `ti.tolerance` (+4, 0.1); no radius appears in 0x90CAEB..0x90CCDB.
  - The radii enter only through sep.w, which 0x913970 writes as `f32(f32(d − rA) − rB)` (N2 §3).
  - The agent's refresh/FULL split uses qi+0x0C (−0.01), not the tolerance (§2.4).
- The `end <= time` branch catches entries whose time
  is ahead of the new step. I: the case is S2's world-time reset at ≥ 63 s (`step_and_integrate.md` §2.2). Whether that
  shift rewrites entry times: ND (not read).

### 2.4 What the agent does with dT1 (= in3'.dist) — P (`n3/create/d_901510.s` 0x901554..0x901698)
```
dT1 = f32 in3.dist
if (qi[+0x0C] < dT1) and !(cache.flags & 0x10):      // fcomp; test 5; jp FULL on >=, unordered (0x901682)
    e.sep.w = dT1                                    // 0x901695, BEFORE the np test: written even when np == 0
    if man.np != 0: refresh (0x916360) on the stored sep (stale xyz, w = dT1)
else: FULL path 0x92A270 -> 0x913970 writes e.sep (xyz and w) through its 3rd argument (0x913A5D..0x913A94),
      before its tolerance test, so also when it returns 1
```

### 2.5 Per-step decision table for one existing triangle entry (discrete) — P (from §2.3/§2.4)

| Condition (in order) | Effect |
|---|---|
| e.time ≠ start and e.time < end (new entry, or a skipped step) | RESET: sep = (0,0,0, 0xDE8AC723), dT1 = that, agent → **FULL** GSK (dT1 ≤ −0.01) |
| PLANE, dist ≥ 0.1 (tol) | sep.w = dist; if np ≠ 0 → **remove all points** (slot2 0x901310, through the manager); skip the agent |
| PLANE, dist < 0.1, dist > −0.01, cache flag 0x10 clear | **refresh only**: sep.w = dist; existing points re-verified and re-emitted; nothing new can appear |
| PLANE, dist ≤ −0.01 (or NaN) | **FULL** GSK: sep rewritten from the GSK; new point possible |

Port consequences (I by the table):
- sep.w is a running predicted distance: each step it falls by `p = sep·lin + lin.w`, and only a full-path step rewrites it
  from geometry.
- After lift-off (dist ≥ 0.1), the GSK runs again only once the accumulated prediction has dropped to −0.01.

### 2.6 Staleness of the stored separating normal — P (closes N3 ND-2 and ND-5)

**Code:**
- Writers of e+0x10..0x1F on the discrete path:
  - 1n create: zero (0x90C5CC..0x90C5D9);
  - 1n RESET: (0,0,0,d);
  - 1n PLANE cull: w only (0x90CC88);
  - agent refresh: w only (0x901695);
  - agent FULL: all four lanes (0x913A5D..0x913A94).
- So sep.xyz is exactly the value of the last FULL step and stays stale through refresh-only steps.

**Numbers:**
- Inputs:
  - `prevxf.py` rebuilds the boat transform from the captured swept transform, with quatToMatrix as in S2's replay.
  - Built from rot1/com1, all 16 words equal the captured transform (`prevxf.txt`).
  - Built from rot0/com0, it gives the start-of-step transform T0.
- Runs:
  - the GSK replay with the exe supports at T0;
  - then the 1n PLANE formula with the captured lin.
- Result (`gategsk_prev_pc53.txt`; PC 64 identical; PC 24 fails by 24 ulp):
  - sep.x be41bbdc, sep.y 3f6ea3f0 and sep.z 3e9dffec match the captured words **bit for bit**;
  - the GSK distance is 0x3814E200 and p = 0.0069331;
  - dist = f32(sep.w − p) = **0xBBE2056A = the captured sep.w**.
  - −0.0069 > −0.01, so that step was refresh-only, which agrees with N3's elimination.
- Grading:
  - "sep.xyz = R(rot0, com0)·n, bit-exact" is P.
  - "T0 is the previous step's collide transform" is I, because the integrator's com1→com0 / rot1→rot0 copies were not
    re-read here. The bit match is strong support for it.

---

## 3. The welding / potential-contact pass inside the triangle loop — P

- 0x90C290 does install a potential-contact buffer for WpMesh triangles (§2.2), so `output+0x3080` is **non-NULL inside
  the triangle loop**. This contradicts N2 §2.6/§4/§5 ("dead for the boat").
- The agent's two appends are live, but they only fill the representative list P[1]:
  - 0x9019BE: the refresh path appends `output.first − 0x30·np`;
  - 0x92A8C0..0x92A8D9: QUEUE appends `out` when `out < output.first`.
- A potential record (P[0]) is written only at 0x92A815..0x92A830. That path needs all of:
  - 0x918580 returned 4;
  - `out.id == 0xFFFF` (0x92A7DD);
  - P non-NULL and entry non-NULL;
  - reserveContactPoints(1) == 0.
- 0x918580 returns 4 with id 0xFFFF only when its flag argument (`collisionInput+0x68 != 0`) is set and `cache.dimB != 3`
  (0x9186B7..0x9186CC).
  - With the flag 0, it calls addContactPoint and returns 5 if that fails (0x9186D3..0x9186FC → 0x9185B0).
  - `collisionInput+0x68` = 0 in both captures (`reset.txt`).
- The conflict pass `FUN_0090AED0` runs only when P[0] > P+0x408 (0x90CEBF..0x90CEC7). Otherwise output+0x3080 is
  restored, and the representative list is discarded (0x90CEEC).
- **So for this pair 0x90AED0 never runs, and the welding hook does not change any number.** Conditional on
  collisionInput+0x68 = 0 (captured; its writer is not read: ND).
- 0x90AED0 itself (decomp `ghidra/pc-v10/0x0090aed0`) uses agent slots +0x16BC/+0x16C0/+0x16C4 and
  `FUN_00941F10`. It is not transcribed, and it is only needed if +0x68 can be nonzero.

---

## 4. Creating a new triangle entry, in run order — P (`create.txt`, 43/43)

1. Filter `FUN_006AF110` (N1 §4.4). If it rejects, the entry is `{cmd 0, type 0, np 0, size 0x10, keyA −1, keyB key}`
   (0x90C620..0x90C630).
2. `bodyB = {getChildShape(key), key}` (0x90C50D..0x90C527). `e.keyA = 0xFFFFFFFF`, `e.keyB = key`.
3. `t = tbl[typeA*32 + typeB]` (tbl = qi+0x10 ? disp+0x12B0 : disp+0xEB0); `e.type = t`; `e[2] = 0` (0x90C54A..0x90C56E).
   There is no flip (agent3[10]+0x40 = 0).
4. Agent3[10] slot10 ≠ 0, so: `e.cmd = 4`, `e.time = f32 [0xB12A50] = −1.0`, `e.sep = (+0, +0, +0, +0)` (0x90C5BD..0x90C5D9).
5. `create = 0x901380(&in3', e, e+0x20)` (cdecl):
   - Triangle type 4 → `0x92AB20`. That function forwards to `0x92A8F0` when `tri+0x17` (isExtruded) ≠ 0 (0x92AB37), which
     is every terrain triangle.
   - `0x92A8F0` (thiscall on the cache, args shapeA, shapeB, aTb = in3'+0x10):
     ```
     A0 = hullConvertIds({0})                       // id 0, w = 0.5
     B0 = triConvertIds({0})                        // vertex 0, unextruded
     p.x = f32(((B0.y*T[4] + B0.x*T[0]) + B0.z*T[8]) + T[12]),  p.y = f32(((T[5]*y + T[1]*x) + T[9]*z) + T[13]),
     p.z = f32(((T[2]*x + T[6]*y) + T[10]*z) + T[14])            // 0x92A937..0x92A9A3
     dA = (f32(p.x-A0.x), f32(p.y-A0.y), f32(p.z-A0.z), f32(0 - A0.w))
     sA = hullSupport(dA)                                          // §1.2
     e  = (f32(p.x-sA.x), f32(p.y-sA.y), f32(p.z-sA.z), f32(0 - sA.w))
     dB = (-f32((T0*e.x + T1*e.y) + T2*e.z), -f32((T4*e.x + T5*e.y) + T6*e.z), -f32((T8*e.x + T9*e.y) + T10*e.z), -0.0)
     sB = triSupport(dB)                                           // §1.4, can return 3..5
     cache.ids = {sA.id, sB.id, 0, 0};  dimA = dimB = 1
     cache[0xA] = min4(numVertices) | min4(3*(isExtruded+1)) << 4  // >3 -> 0xF: 0xFF for the boat on terrain
     cache[0xB] = 0
     ```
   - (Non-extruded triangles take 0x92AB20's own path: ids {support(±triangle normal), 0, 1, 2}, dims (1,3), byte
     maxA|0x30; N3's transcription was gated here too.)
   - Back in 0x901380: `e[2] = 0`, `cache[0xB] &= ~0x10`, the manifold dword (agentData+0xC: nA, nB, np, pad) = 0.
     Return = agentData + 0x10, so `e.size = 0x30` (0x9013AC..0x9013D4).
6. **The same step then processes the new entry** (0x90C5FD → 0x90C634 → dispatch).
   - time −1 is neither start nor ≥ end, so RESET.
   - dT1 = 0xDE8AC723 ≤ −0.01, so FULL GSK (0x92A270) from the created simplex.
   - This creates the first point when the GSK distance is below createContact (N2 §5).
- Winch example: create gives cache `17 00 02 00 00 00 00 00 01 01 ff 00` (ids {0x17; 2}). This is code-equivalence only:
  no capture holds a freshly created cache.

---

## 5. Hull getAabb `0x8BB7C0` and `0x8BBE50` — P (`aabb.txt`, 300/300; closes N1 ND items 8–10 for this function)

```
getAabb(T, tol, out)  [thiscall, ret 0xC]:  t2 = f32(this.radius(+0x10) + tol);  FUN_8BBE50(T, &he(+0x20), &c(+0x30), t2, out)
FUN_8BBE50 (cdecl):
  cA[k] = |f32(T.col0[k] * he.x)|,  cB[k] = |f32(T.col1[k] * he.y)|,  cC[k] = |f32(T.col2[k] * he.z)|      k = 0..3 (w lanes too)
  cC[k] = f32(cC[k] + t2)                       // lane w: f32(t2 + cC.w)
  e[k]  = f32( f32(cB[k] + cA[k]) + cC[k] )
  C.x = f32(((T0*c.x + T4*c.y) + T8*c.z) + T12),  C.y = f32(((T5*c.y + T1*c.x) + T9*c.z) + T13),
  C.z = f32(((T6*c.y + T2*c.x) + T10*c.z) + T14), C.w = 0
  out.max = f32(C + e)   (4 lanes; max.w = f32(e.w + 0))      -> out+0x10..0x1C   (0x8BC100..0x8BC134)
  out.min = f32(C + (-e)) (4 lanes; min.w = f32(0 + -e.w))    -> out+0x00..0x0C   (0x8BC138..0x8BC15C)
```
- With tol = f32(0.1·0.5) = 0.05, this is N1's MOPP query box (§4.2): the hull's rotated box widened by 0.1.
- e.w = t2 when the transform's w lanes are 0, so min.w = −0.1 and max.w = +0.1 (`aabb.txt`). The MOPP slot does not read
  the w lanes (N1).

---

## 6. Corrections to earlier reads

| Doc § | Earlier claim | Correct | Evidence |
|---|---|---|---|
| N1 §4.4, §7 | in3'.dist is set only on the stale reset ("else as left") | On PLANE→CALL, in3'.dist = the plane-test dist (x87 top, stored at 0x90CB53); e.sep.w is **not** written on that path; the agent writes it (0x901695) | §2.3, §2.4 |
| N1 §4.4 | reset d = −5e18 | bits 0xDE8AC723 (−4.99999999e18) = f32(qi+0x14 · f64 0.10000000149) | `reset.txt` |
| N1 §1.3 | `fA = deltaTime * mA[+0x5C]` | fA = **f32**(mA[+0x5C]·dt) is stored before use; mA+0x5C = com1.w = invDt (captured), so fA = 1.0 | 0x90A0F5, `lintim.txt` |
| N1 §4.2a | getAabb store tail not read (I) | min = f32(C + (−e)), max = f32(C + e), 4 lanes | §5 |
| N2 §2.1 | 1n machine "I: same rule" as Nn (reset to −3.40282e38, only time == start skips it) | The 1n machine also goes to PLANE on `end ≤ time`, and resets to f32(qi+0x14·0.1), not to [0xB11AD8]. Nn (0x909E44..0x909E7E) is as N2 says | §2.3, `n1/dis_909cac.txt` |
| N2 §2.6, §4, §5 | output+0x3080 is NULL, so the queue branches are dead for the boat | Inside the triangle loop it is a live local buffer (WpMesh welding enabled); the appends run; only the potential records and 0x90AED0 stay off, because collisionInput+0x68 = 0 | §3 |
| N2 §3 | sep is copied into the entry at 0x92A73F–0x92A758 | Those instructions copy the local sep copy into the **output point** (out+0x10..+0x1C). The entry sep is written directly by 0x913970 through its 3rd argument (0x92A27D/0x92A2CF push ebx = sep) | `n3/create/d_92a270.s` l.12, 34, 389–396; `n2/dis/d_913970.s` l.70–111 |
| N3 §1 TRY_B | brute-force support = triangle vertex 2 | the exe returns **1** (three f32-equal dots, priority 1 > 2 > 0); still rejected | §1.6 |
| N3 §1 / ND-2 | sep.xyz 1–2 ulp off, staleness I | P: bit-exact at the start-of-step transform; refresh never writes xyz | §2.6 |
| N3 ND-3, ND-5 | supports not transcribed; dT1 producer not replayed | transcribed and gated; dT1 replayed bit-exactly | §1, §2.6 |
| gsk_core.md ND 2, 8 | support w-lane handling and implementations unknown | dir.w ignored; out.w = bits(id\|0x3F000000) | §1.1 |
| N1 §4.4 (wording) | "accepted → cmd 4 … size = create(…)" | right; also: the new entry is dispatched in the same step and always takes RESET → FULL | §4 step 6 |

Confirmed unchanged (P this run): N1 §4.4's plane formula and its ≥-tolerance cull with NaN → call; the remove-all through
slot2 when np ≠ 0; N3 §4.2's 0x92A8F0 arithmetic and 0x901380 tail; N3 §4.3 convertVertexIds; N1 §1.3's lin formula and
association.

## 7. NOT DETERMINED

1. Writer of `collisionInput+0x68`. It reads 0 in the world master input of both captures.
   - The narrowphase job works on its own copy of the input. `FUN_008FDA80` decomp lines 89–92 copy only
     cI+0x50..+0x5C (stepInfo) from its argument, so the source of the job copy's +0x68 was not traced.
   - If it can be nonzero, §3's potential records and `FUN_0090AED0` (with `FUN_00941F10`, not transcribed) become live.
2. PC 53 vs 64 is still not separated: every gate here matches at both, and fails at 24.
3. Whether the world-time shift (≥ 63 s) rewrites e.time. Not read; it decides whether `end ≤ time` fires after a
   reset.
4. The integrator copies com1→com0 and rot1→rot0 (needed for "T0 = previous collide transform"): S2 states the rot copy;
   the com copy was not re-read. The bit match supports it (I).
5. The continuous branches (0x90CBAD, 0x90C1A0, slot10 0x9013E0) and command 5 (flipped TIM): located, off-path, not
   transcribed.
6. NaN behaviour of the supports: decoded from the jumps (§1.3), not executed.
