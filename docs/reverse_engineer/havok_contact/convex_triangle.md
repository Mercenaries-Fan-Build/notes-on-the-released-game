---
status: current
evidence: mixed (graded per claim)
---

# N2 — convex hull vs one triangle → contact points (pc-v10, agent3 #10 "PredGskf3")

Port spec for the opening Speed Boat's whole-hull child (127-vertex `hkpConvexVerticesShape`, radius 0.05) against one
terrain triangle (`hkpTriangleShape` built by `WpMeshShape16`, radius 0.01). The read was done on 2026-11-25.

Grades:
- **P** = PROVEN this run, with the address, file or command.
- **I** = INFERRED (reasoned, not checked).
- **S** = SPECULATIVE.
- **HK** = recalled Havok 5.5 knowledge. It is never a fact about this binary; at best it is I.
- **ND** = NOT DETERMINED; §11 lists every one with what was tried.

Companion documents:
- **`n2/gsk/gsk_core.md`** holds the GSK closest-point core `FUN_00912130` and its whole callee tree: object layout,
  switch tables, every case, termination, the penetration/EPA fallback, constants, and precision notes. It was produced
  by a delegated sub-agent under the same house rules, with its own grades. This spec uses it and does not repeat it.
  Its sub-files are `n2/gsk/pd/*.md`.
- `s1_contact_solve_spec.md` is S1's work: the manager internals, the solver, and the scan for gate captures.
- `n1_query_path_spec.md` is N1's work: triangle enumeration, the TIM / nn machine `FUN_00909CA0`, and the collection
  agents.

All paths are under the scratchpad folder
`/private/tmp/claude-501/-Volumes-Projects-mercenaries-game/d08a21c0-8307-469b-be20-8c9b42a8712a/scratchpad/havok_port/`.

---

## 0. How the SecuROM-split bodies were recovered — P

The three bodies `FUN_00901510` calls start with `push ebp; mov ebp,esp; and esp,-16; jmp [slot]`. The SecuROM VM
executes one stolen instruction and jumps back to `.text`.

`n2/resolve_splice.py` (which runs `mercs2_probe splice-emulate <exe> <site> --steps N` and bisects on the first
`.text` address the VM enters) found that each VM exit lands on a `.text` gadget of the form "stolen instruction; jmp
continuation" (`n2/resolve1.txt`, `n2/gadgets.txt`):

| Stub | Site | Gadget | Stolen instruction | Continuation |
|---|---|---|---|---|
| `FUN_00916360` | 0x916366 | 0x460EE6 | `sub esp,0x344` | **0x91636C** |
| `FUN_0091AAC0` | 0x91AAC6 | 0x54B346 | `sub esp,0x4D4` | **0x91AACC** |
| `FUN_0092A270` | 0x92A276 | 0x50A0B2 | `sub esp,0x1C4` | **0x92A27C** (`push ebx`) |

**Correction to the README:** the third body resumes at **0x92A27C**, not 0x92A27D. 0x92A27D is the first *read*,
after `push ebx` (`n2/se_bisect3.txt`: n=2583 stops at eip 0x92A27C).

A `jmp [m32]` (6 bytes) is the same length as `sub esp,imm32` (6 bytes), so each site could be patched in place.

`n2/patch2.py` applied the same method to every splice site in 0x8A0000–0x940000:
- **65 sites restored**, all with a one-instruction gadget (`n2/patch2.txt`).
- **7 sites skipped** because their gadget is obfuscated (pushfd/xchg chains): 0x8D4BF0, 0x8F532D, 0x8F6DD0, 0x8FD13D,
  0x90A85F, 0x90CCEA, 0x91DCCE. None lies in this agent's closure (P for the GSK closure per `gsk_core.md` §1; I for
  the manifold functions, which contain no splice sites by `n2/hk_splices.txt`).

| File | sha256 |
|---|---|
| original `mercs2_unpacked.exe` | 8c179a99…bc7ba (re-checked after the run, unchanged) |
| `n2/mercs2_n2patched2.exe` | 359c996a3064d6ae64fe8ff04272a18f6d4a55f8fb29e7299b8c5674164524dd |

The copy was imported into scratch Ghidra projects `n2/gproj/n2proj2` and `n2proj3` (headless, `-noanalysis`,
`n2/scripts/N2Decomp.java`). The decompilations are `n2/out2/*.c` and `n2/out3/*.c`; the listings are `n2/dis/*.s`.

The `-noanalysis` decomp gets calling conventions and x87 stack values wrong in places (`unaff_*`, ints typed as
floats). **The pseudocode below takes its structure from the decomp. It takes comparisons, operand order and constants
from the listings at the addresses cited.**

Also checked:
- `corpus_translate`: pc-v11 (0x9017E0, 0x916570, 0x91ACD0, 0x92A480) and pc-v10-drmfree carry the **same** 12/22-byte
  split stubs (`n2/ranges.txt`). Neither image gives a whole body.
- Constant in SecuROM data `[0x245D664]` (read by 0x90FE80) = 1, both in the exe bytes and in the capture
  (`n2/cap_245d664.txt`).

---

## 1. Which path the boat-vs-terrain pair takes

1. **Agent table.** Agent3 #10 slots are {create 0x901380, 0x901360, 0x901310, 0x901250, 0x901290, 0x9012D0, –, –, –, –,
   0x9013E0, process 0x901510} (`havok_contact/disp.txt`). Its timer label is `"TtPredGskf3"` (0xB5A1D0, pushed at
   0x901510). **P**
2. **Quality info.** In the PSI narrowphase job `FUN_008FDA80`, the per-entry quality info is
   `info = dispatcher + 0x1C20 + 0x40 * (s8)entry[+0xC]`. It is stored at collisionInput+0x60 (`param_1[0x1c]`, where
   collisionInput = `param_1+4`), and `collisionInput+0x10 = info+0x10` (decomp `n2/fns/fn_008fda80.txt` lines
   145–148). **P**
   - The capture's world collisionInput 0x20017E80 has +0x60 = 0x2021F590 = dispatcher 0x2021D930 + 0x1C60 = info[0]
     (`n2/ci2.txt`). **P**
   - The boat's entry quality byte is 1 (README §1.4), so info[0]. **P**
3. **Continuous flag.** info[0]+0x10 (int) = 0 (`disp.txt` raw word 00000000). So `FUN_00901510` never calls
   `FUN_0091AAC0` for this pair (test `cmp [qi+0x10],0` in decomp line 64 / listing 0x90155E–). **P**
4. **Conclusion.** The pair runs either refresh-only (`FUN_00916360` on the cached manifold) or the full GSK path
   (`FUN_0092A270`). §4 gives the selection.

Quality-info fields this agent reads (layout from `FUN_008C4430` and the capture `disp.txt` info[0]):

| Off | Value (info[0]) | Read at | Use here | Name (HK) |
|---|---|---|---|---|
| +0x04 | 0.1 | 0x92A784 | add-new-point threshold when dimA+dimB == 4 | create4dContact |
| +0x08 | −0.005 | 0x92A789 | add-new-point threshold otherwise | createContact |
| +0x0C | −0.01 | 0x901678 | refresh-only gate | manifoldTimDistance |
| +0x10 | 0 (int) | 0x90155E | continuous / predictive branch | useContinuousPhysics |
| +0x14, +0x18, +0x24, +0x28 | −5e19, −5e19, −1e19, −1e19 | 0x901510 else-branch only | ToI separations (off-path) | min/toi separations |

How +0x08 and +0x0C are computed — **this is REJECT_MANY's whole effect on this agent**:
- `FUN_008C4430(p)` is called from the world ctor at `n2/fns/fn_008d8c70.txt` line 766. **P** (decomp)
- The init struct p:
  - p[0] = |gravity| (`_CIsqrt`, 9);
  - p[1] = tolerance 0.1;
  - p[2] = cinfo+0x64 = expectedMinPsiDeltaTime 1/30;
  - byte +0x19 = (cinfo+0x70 **contactPointGeneration == 2**);
  - byte +0x1A = (contactPointGeneration > 0).
- info[0] fields:
  - +0x00, +0x04 and +0x0C start as tol;
  - **+0x0C (manifoldTim) = f · (−2.0)** (`DAT_00B12080`, f64) when byte +0x19 is set;
  - **+0x08 (createContact) = f · (−1.0)** (`DAT_00BEAA30`, f64) when byte +0x1A is set;
  - where `f = ((p[0] * 0.5) * p[2]) * p[2]` (`DAT_00BEA940` f64 0.5).
- So under REJECT_MANY, createContact = −½·|g|·dt² and manifoldTim = −|g|·dt². With f32 rounding at each step this gives
  bits **0xBBA3D70B** and **0xBC23D70B**, exactly the captured words (`disp.txt` raw). Under ACCEPT_ALWAYS both would
  stay +0.1. **P** (python f32 replay of the decomp order; that x87 at 53-bit rounds the same way is I).

---

## 2. Data layouts

### 2.1 Process input (`param_1` of 0x901510) — P except names

| Off | Field | Evidence |
|---|---|---|
| +0x00 | cdBody A (convex side); `*cdBody` = shape, cdBody+8 = world transform (hkTransform, rotation columns at +0/+0x10/+0x20, translation +0x30), cdBody+0xC = parent cdBody | 0x92A270 (`*param_1` → shape, `[+8]`), 0x901510 parent walk |
| +0x04 | cdBody B (triangle side) | same |
| +0x08 | collisionInput: +0 dispatcher, +4 **tolerance 0.1**, +0x50 stepInfo, +0x60 qualityInfo*, +0x68 u8 flag (=0 in the capture, `n2/ci2.txt`) | 0x9016A2, 0x92A77C, 0x92A7A9 |
| +0x0C | contact manager (`hkpSimpleConstraintContactMgr`) | passed to 0x916360/0x914980/0x918580 |
| +0x10 | aTb = A-from-B transform (hkTransform, 0x40) | 0x92A2A2 `lea edx,[esi+0x10]` → GSK input |
| +0x50 | f32 **distAtT1**: TIM-predicted distance | 0x901554 `fld [ebx+0x50]` |

Who writes input+0x50 (summary of N1's area; read here from `n2/out3/d_00909ca0.c`, the Nn machine `FUN_00909CA0`, for
stream command 4):
- If the entry's stored time ≠ stepInfo.startTime and quality+0x10 == 0: sepNormal = (0,0,0,`DAT_00B11AD8` =
  −3.40282e38). The agent then runs with that distAtT1, so the full GSK path is forced (decomp lines 92–113). **P** for
  the Nn machine.
- Otherwise: `distAtT1 = sep.w − (n·linearTim + angularTerm)`. If distAtT1 ≥ tolerance, the points are removed and the
  agent is not called (decomp lines 133–150). **P** for the Nn machine.
- The 1n machine that drives triangle sub-agents under the bvtree agent is N1's. That it applies the same rule: **I**.

### 2.2 The triangle sub-agent entry (validated on a live capture, §8) — P

Sub-entry in a 1n sector (winch capture 0x1E35C270):

| Off | Size | Field | Value at 0x1E35C270 |
|---|---|---|---|
| +0x00 | u8 | stream command | 4 |
| +0x01 | u8 | agent3 type | 0x0A |
| +0x02 | u8 | **numContactPoints** (written by process at 0x9019FA: `entry[2] = manifold.numPoints`) | 1 |
| +0x03 | u8 | entry size (bytes) | 0x40 |
| +0x04 | u32 | shape key A | 0xFFFFFFFF |
| +0x08 | u32 | shape key B (triangle key) | 0x01000756 |
| +0x0C | f32 | TIM time (I) | 45.742 |
| +0x10 | f32[4] | **separatingNormal** (world n.xyz, w = distance) | (−0.18919, 0.93219, 0.30859, −0.00690) |
| +0x20 | … | **agentData** (cache + manifold, §2.3–2.4) | |

The process function returns `agentData + ((nA + nB + 4*np)*2 + 0x1F & ~0xF)`, the end of the agentData (0x901A20…).
For np = 1, nA = 1 and nB = 3 that is 0x20, which matches the 0x40 entry size. **P**

### 2.3 GSK cache (agentData +0x00, 12 bytes) — P

| Off | Field | Writers |
|---|---|---|
| +0x00 | u16 vertexId[4]: A's dimA ids, then B's dimB ids | create 0x92AB20 / 0x92A8F0; GSK write-back 0x90FE80 (sorts ids descending within A and within B) |
| +0x08 | u8 dimA | same |
| +0x09 | u8 dimB | same |
| +0x0A | u8: low nibble maxA, high nibble maxB. Each is `shape->vtable[0x24]()` (number of support vertices), or 0xF if > 3 | 0x92A8F0 / 0x92AB20 |
| +0x0B | u8 flags: bit 0x10 = "weld forced GSK": set when the triangle weld returns 1, cleared at 0x92A270 entry and by create | 0x92A2…, 0x901380 |

Create (`FUN_00901380`) branches on the triangle's type (P, `n2/out2/d_00901380.c`, `d_0092ab20.c`, `d_0092a8f0.c`):
- **Shape B type == 4 and not extruded (tri+0x17 == 0):** `0x92AB20` gives ids (A support along a direction from the
  triangle, B = 0,1,2), dims (1,3) and maxB = 3, so the byte is `maxA | 0x30`.
- **Extruded, or not a triangle:** `0x92A8F0` gives dims (1,1) with one support vertex each.
- Then `entry[2] = 0`, `flags &= ~0x10`, `manifold.numVertsA = 0`, and the size word is reset.
- The support-direction arithmetic inside the two create helpers was not transcribed (ND-6).

The winch capture's caches hold maxB nibble 0xF on some entries and 3 on others (`n2/winch7.txt`). I: the former are
extruded triangles that went through 0x92A8F0.

### 2.4 GSK manifold (agentData +0x0C) — P (layout from 0x914800 / 0x916360 / 0x918580, confirmed on the capture)

```
+0  u8 nA        number of A vertex ids in the id table
+1  u8 nB        number of B vertex ids
+2  u8 np        number of points, 0..4  (0x918580 tests np == 4)
+3  u8 (unused here, 0)
+4  point[np], 8 bytes each:
      +0 u8 dimA, +1 u8 dimB        (case index = dimB + 4*dimA)
      +2 u16 contactPointId        (0xFFFF = none yet)
      +4 u8 vtx[4]                 per feature vertex: (index into the id table) << 4,
                                   so >>4 = index into the 16-byte vertex buffer, >>3 = byte offset of the u16 id
+4+8*np  u16 ids[nA + nB]          A's ids first, then B's
```

Capture 0x1E35C29C: nA 1, nB 3, np 1. Point {1, 3, id 0, vtx 00 10 20 30}. ids {0x56; 2, 0, 1}. **P**

### 2.5 Vertex buffer used by the manifold refresh (built by the caller of 0x916360) — P (0x9016A2–0x9016FB, 0x92A3F6–)

- `[0x00..0xFF]`: up to 16 world-space vertices (16 bytes, w = 0). The nA vertices from `shapeA->vtable[0x34](ids, nA,
  buf)` are transformed by cdBodyA+8; the nB vertices from shapeB (ids + nA) by cdBodyB+8.
- `+0x100` f32[4] separating normal (world; for refresh-only, the entry's normal with w := distAtT1).
- `+0x110` rA = shapeA+0x10 (0.05).
- `+0x114` rB = shapeB+0x10 (0.01, the triangle's radius copied from the collection at 0x725A98).
- `+0x118` tol = collisionInput+4 (0.1).
- `+0x11C` sq = f32(f32(f32(rA + tol) + rB)²): `fld rA; fadd tol; fadd rB; fstp f32; fld; fmul st0,st0; fstp`
  (0x9016DC–0x9016FB). Note the order: (rA + tol) + rB. **P**
- Transform arithmetic per vertex (x87): `x' = ((t.x + v.z*R[2].x) + v.x*R[0].x) + v.y*R[1].x`, and likewise for y and z.
  This order is from the decomp (0x9017D3–0x901848 / 0x92A51E–0x92A5A3 loops). **I** (not hand-traced on the x87 stack).

### 2.6 Process output (`param_5`) — P (0x92A714–0x92A767, 0x8FDA80 locals)

| Off | Field |
|---|---|
| +0x00 | pointer to the first free point |
| +0x04 | constraint owner |
| +0x10.. | points, stride **0x30**: hkContactPoint {pos.xyzw (w = 0 for new points), sepNormal.xyz, distance (w)} = 32 bytes, then +0x20 u32 contactPointId |
| +0x3080 | potentialContacts* (the welding queue) |

The PSI job `FUN_008FDA80` sets +0x3080 to **NULL** (`local_20 = 0` at frame −0x20 = output+0x3080; decomp line 282).
So for the boat the queue branches below are dead. That N1's collection/bvtree agents do not set it for sub-agents:
**I**. `FUN_00925840` and `FUN_008D16D0/1CE0` memcpy 0x1008 bytes to and from it only when it is non-NULL
(`n2/grep_c20.txt`).

---

## 3. GSK closest point between the hull and the triangle (wrapper `FUN_00913970`) — P (`n2/dis/d_913970.s`)

Input struct G (built at 0x92A2A2–0x92A2D9): {aTb* = input+0x10, worldFromA* = cdBodyA+8, shapeA, shapeB, tol =
collisionInput+4}.

```
gsk.dimA, dimB  = cache[8], cache[9];  gsk.maxA = cache[0xA] & 0xF;  gsk.maxB = cache[0xA] >> 4
gsk.+0x10 = 0;  gsk.+0x14 (changed) = 0                                   // 0x913993–0x9139C0
shapeA->convertVertexIdsToVertices(cache.ids, dimA, gsk.A[])            // vtable+0x34, 0x9139CF
shapeB->convertVertexIdsToVertices(cache.ids + dimA, dimB, gsk.Braw[])  // 0x9139ED
FUN_00912130(gsk, shapeA, shapeB, aTb, &out)                            // out = {n.xyz (A space, unit), d}
                                                                        // see gsk_core.md (always returns 0 here)
if gsk.changed: FUN_0090FE80(gsk, cache)                                // write the simplex back to the cache, ids sorted
dist = f32( f32(d − rA) − rB )                                          // x87: fld d; fsub [A+0x10]; fsub [B+0x10]; fstp (0x913A1C–0x913A31)
sep.xyz = R_A · n   (rotation only, x87, (c0*nx + c1*ny) + c2*nz per row, each stored f32)  // 0x913A35–0x913A88
sep.w = dist
if !(dist < tol): return 1                                              // fcompp + test ah,0x41 at 0x913A9A: return 1 when tol ≤ dist or unordered
// contact position in A space, then to world
if dimA == 1:      s = f32(rB − d);  p = A[0]   + s*n                   // 0x913AB2–0x913AEA
elif dimB == 1:    s = rB;           p = BinA[0] + s*n                  // 0x913AF5–0x913B34 (gsk+0xA0 = B vertex 0 in A space)
else:              s = f32(rB − d);  p = segA  + s*n                    // 0x913B36–0x913B70 (gsk+0x130 = closest point on A's edge, from 0x9219B0)
point.xyz = R_A·p + t_A ;  point.w = (the remaining x87 value; decomp says 0.0)   // 0x913B77–0x913BE0
return 0
```

How the two radii enter (P from the listing above):
- The core works on the **bare** shapes: hull vertices and triangle vertices, with no radius.
- The reported distance is `(d − 0.05) − 0.01`.
- The contact position lies on B's radius-expanded surface: the closest feature point on A, plus `(rB − d)·n` (or
  B's vertex plus `rB·n`).
- n points from B to A (I: from `d = n·(A0 − B0)` in `gsk_core.md` §3.8).

Reading of the edge cases by sign (I): at rest with d = 0.06, dist = 0. Penetration gives dist < 0. Separation beyond
tol + 0.06 = 0.16 gives return 1 (no contact).

The caller writes `out` unconditionally. Then `sep = {sep.xyz, dist}` is copied into the entry's separatingNormal at
0x92A73F–0x92A758 (P).

---

## 4. Process `FUN_00901510` (input, entry, agentData, sepNormal, output) — P (listing `n2/dis/d_901510.s`, decomp `n2/out2/d_00901510.c`)

```
push timer "TtPredGskf3"
dT1  = input+0x50 (f32);   qi = collisionInput+0x60;   cache = agentData;  man = agentData+0xC
if qi[+0x10] != 0:                          // continuous: NOT taken for boat/terrain (§1)
    rp = min(allowedPenetrationDepth of root collidable A (+0x48), of B)      // walks cdBody+0xC to the root
    t1 = min(rp*qi[+0x14], sep.w + qi[+0x18]*rp)      // min idiom at 0x9015B0 (fcom; test ah,0x41)
    if t1 <= dT1: goto REFRESH_TEST                    // decomp line 164; listing 0x90160D not hand-traced (I)
    t2 = min(rp*qi[+0x24], qi[+0x28]*rp + sep.w)
    FUN_0091AAC0(input, rp, t1, t2, agentData, sepNormal, output)  // off-path, ND-5
    goto FULL
REFRESH_TEST:                                            // 0x901678
if (qi[+0xC] < dT1)  [fcomp; test ah,5; jp → FULL: FULL when qi[+0xC] ≥ dT1 or unordered]
   and (cache.flags & 0x10) == 0:                        // 0x90168B
    sep.w = dT1                                          // 0x901695 (sep.xyz unchanged)
    if man.np != 0:
        build the §2.5 buffer (normal = sep incl. new w)
        FUN_00916360(man, buf, first=0, output, contactMgr)          // verify + emit, §5.3
        if man.np != 0 and output+0x3080 != 0:  queue {output.first − 0x30*np}   (dead for the boat)
    goto DONE
FULL:
FUN_0092A270(input, entry, agentData, agentData /*cache*/, man, sepNormal, output)  // §5
DONE:
entry[2] = man.np;  pop timer;  return agentData + align16(...)
```

Boat reading (I): with qi+0xC = −0.01, refresh-only runs whenever the TIM-predicted distance is above −0.01, that is,
unless the hull is predicted to sink more than 1 cm.

Consequence for the port: with np = 0, refresh-only emits nothing. So **a first contact point appears only when one of
these holds:**
- dT1 ≤ −0.01;
- the TIM machine invalidated the normal (§2.1: dT1 = −3.4e38, which happens every step the stored time ≠ step start);
- weld flag 0x10 is set (never, for terrain).

This is retail behaviour; a port must not "fix" it. For triangle sub-agents the dT1 source is the 1n machine (N1's
part), a cross-part dependency.

The other agent3 #10 slots (P, `n2/slots_dec.txt`, `n2/dis/d_9012d0.s`):

| Slot | Address | Behaviour |
|---|---|---|
| [1] | 0x901360 | forwards to [2] (HK: destroy) |
| [2] | 0x901310 | **removePoints**: `FUN_00914980` (mgr +0x14 for every point), entry[2] = 0, returns the data end. The Nn TIM machine calls it (`out3/d_00909ca0.c` line 147, `+0x16B8`) when distAtT1 ≥ tolerance and np ≠ 0: **this is how points leave when the hull lifts off.** `FUN_00925840` also calls it. |
| [3] | 0x901250 | remove the point whose contactPointId == arg, through 0x916300 (manifold only, no manager call) |
| [4] | 0x901290 | write arg into the first point whose id is 0xFFFF (HK: commitPotential) |
| [5] | 0x9012D0 | the point with id == arg gets dims (0,0), so the next verify removes it (HK: createZombie) |
| [10] | 0x9013E0 | sepNormal only. It runs the same GSK, writes the cache back, then `sep.xyz = R_A·n` and `sep.w = d − (rB + rA)`. Note the different rounding from 0x913970's `(d − rA) − rB`. The Nn machine calls it as `+0x16D8` only in the continuous branch (quality+0x10 ≠ 0, `d_00909ca0.c` lines 115–131), so it is **off-path for PSI**. |

---

## 5. Full path `FUN_0092A270` (input, entry, agentData, cache, man, sep, output) — P (`n2/dis/d_92a270.s`; control flow re-checked at the cited addresses)

```
cache.flags &= ~0x10
r = FUN_00913970(G, cache, sep, &pt)                         // §3; writes sep and pt
if r == 1:                                                   // 0x92A2E1: separated beyond tolerance
    if man.np != 0: FUN_00914980(man, contactMgr, output.constraintOwner)   // remove all points (§5.2)
    return
if shapeB.type == 4 (triangle):                              // 0x92A330
    w = shapeB->vtable[0x38](&cache.ids[dimA] /*B's ids*/, &cache.dimB, &pt, worldFromB, shapeA, worldFromA, &sepCopy)
                                                             // = FUN_008AB520, §6; 7 args, thiscall ret 0x1C (0x92A336–0x92A379).
                                                             // Args 1–3 and 6–7 P from the pushes; args 4–5 I (stack-slot reuse)
    if w == 0: FUN_00914980(man, mgr, owner); return         // weld rejects → drop the manifold
    if w == 1: cache.flags |= 0x10                           // forces FULL next step
    // w == 2: accept unchanged.  ALWAYS 2 for WpMeshShape16 triangles (§6)
found = FUN_00914800(man, cache) & 0xFF                      // §5.1; moves the match to slot 0
if found < man.np:                                           // 0x92A3C8 (signed jle → skip)
    if man.np != 0:  build the §2.5 buffer with sep (fresh) and radii
                     FUN_00916360(man, buf, first=found, output, mgr)   // refresh every other point
out = *output.first
out.pos = pt; out.sepNormal = sep (xyz, w = dist)            // 0x92A716–0x92A758
if found:                                                    // the GSK point IS man.point[0]
    out.id = man.point[0].contactPointId; output.first += 0x30; goto QUEUE
// a new candidate point
thr = (cache.dimA + cache.dimB == 4) ? qi[+0x4] : qi[+0x8]   // 0x92A76C–0x92A789 (0.1 or −0.005)
if !(sep.w < thr): goto QUEUE                                // fcompp, test ah,0x41 at 0x92A79A: strict <
k = FUN_00918580(man, cdA, cdB, input?, output, cache, out, prevFirst, mgr,
                 (collisionInput[+0x68] != 0))               // §5.4, 10 args (0x92A7A7–0x92A7CC)
switch k:
  4 (appended):
     if out.id != 0xFFFF: output.first += 0x30               // 0x92A7DD
     elif output+0x3080 == 0 or entry == 0:                  // boat: this branch
         id = mgr->vtable[0xC](cdA, cdB, input, output, cache, out)   // addContactPoint 0x8D3DA0 (0x92A83B–0x92A869)
         out.id = id
         if id == 0xFFFF: FUN_00916300(man, 0)               // undo: remove point 0 from the manifold
         else: man.point[0].contactPointId = id; output.first += 0x30
     else:  if mgr->vtable[0x10](1) == 0 (reserveContactPoints):     // 0x92A805
                queue {out, entry, agentData}; output.first += 0x30
            else FUN_00916300(man, 0)
  5: (rejected; nothing emitted)
  6: output.first −= 0x30                                    // the replaced point's slot is withdrawn
  0..3: (replaced slot k; the new point was added inside 0x918580)
QUEUE: if output+0x3080 != 0 and out < output.first: append out to the representative list   (dead for the boat)
```

Note on `found`: it is the u8 returned by 0x914800 (1 = matched, 0 = not). The listing compares it as a signed int
against np (0x92A3C8). When found = 1, refresh starts at point index 1. **P**

### 5.1 `FUN_00914800` — match the GSK simplex to a manifold point — P (decomp `n2/small_decomps.txt`)

```
for i in 0..np-1:
   if p[i].dimA == cache.dimA and p[i].dimB == cache.dimB and
      the ids at p[i].vtx[0..dimA+dimB-1] equal cache.ids[0..dimA+dimB-1]:
         swap p[i] with p[0];  return 1
if cache.dimA == 1 or cache.dimB == 1:            // vertex-feature cleanup
   for j in 0..np-1:
      if (cache.dimA==1 and p[j].dimA==1 and idOf(p[j].vtx[0])==cache.ids[0]) or
         (cache.dimB==1 and p[j].dimB==1 and idOf(p[j].vtx[p[j].dimA])==cache.ids[cache.dimA]):
           p[j].dimA = p[j].dimB = 0;  break      // invalid: 0x916360 case 0 then removes it
return 0
```

### 5.2 `FUN_00914980` (remove all) / `FUN_00916300` (remove one) / `FUN_009161C0` (compact ids) — P

- **0x914980:** for each point with id ≠ 0xFFFF, call `mgr->vtable[0x14](id, owner)` (removeContactPoint 0x8D4180).
  Then np = nA = nB = 0.
- **0x916300(man, k):** move the last point into slot k, then np--. It then moves the id table down by 8 bytes and
  rebuilds it with the 0x9161C0 logic:
  - mark the vertices still used (2 per point, a 3rd if dimA+dimB > 2, a 4th if == 4);
  - keep only the marked ids, in order;
  - remap every point's vtx bytes;
  - nA := the count kept below the old nA; nB := the rest.
  - It does **not** call the manager.

### 5.3 `FUN_00916360` — verify and emit the cached points — structure P, arithmetic partly I

Arguments: (man, buf §2.5, first, output, mgr). For i = first .. np−1 it dispatches on `e = dimB + 4*dimA` through the
byte table 0x917A30 and the jump table 0x917A10 (bound `cmp eax,0xD; ja` 0x9163BE). Both tables were read from the exe
(P):

| e | dims | Target | Feature |
|---|---|---|---|
| 0–4, 8, 11, 12, >13 | — | 0x917954 | remove |
| 5 | (1,1) | 0x9163D9 | vertex–vertex |
| 6 | (1,2) | 0x9164BC | vertex A – edge B |
| 7 | (1,3) | 0x916796 | vertex A – triangle B |
| 9 | (2,1) | 0x916C83 | edge A – vertex B |
| 10 | (2,2) | 0x916F2C | edge–edge |
| 13 | (3,1) | 0x91736F | face A – vertex B |

Each case computes a point-on-A `P`, a difference `D = A-side point − B-side point`, a normal `N` (n.w is carried), and
a reject flag:

- **(1,1):** reject if `|a − b|² > sq` (`≤ sq` keeps; decomp line 71). Otherwise N = buf.n, P = a, D = a − b.
- **(1,2) / (2,1):** project onto the edge with barycentric weights. The reject at 0x9166D3–0x9166F9 is
  `sq * x < 0.0` (f64 0.0 at 0xBEA968; `fcomp; test ah,5; jnp` → reject when less) or either end-region bit set
  (`test dl,0xC`). Then `t = u/(u+v)` (0x916705 `fadd; fdivp`, stored f32) and `1−t` (`fld1; fsubrp`). N = buf.n.
- **(1,3) / (3,1):**
  - triangle normal = cross of two edges, scaled by `1/sqrt(|c|²)` (or 0 if |c|² == 0), x87 `_CIsqrt` 0x91691B then
    `fdivrp`; N.w = s * 0.0 (`fmul qword [0xBEA968]`);
  - three edge-side tests give bits 8/4/2, and `flags = ~bits & 0xE`, so reject if any side is outside;
  - N is flipped if N·buf.n < 0 (0x91783F path);
  - (3,1) projects the vertex onto the plane for P.
- **(2,2):**
  - closest points of two segments via the cross-product construction (decomp lines 227–293);
  - accept only when the side code is 0xC or 0x3, i.e. the closest points are interior to both segments;
  - N = buf.n.
- **Emit** (common tail 0x91789A–0x917947, P from the listing):
  ```
  d   = f32( N·D )                                   // stored [esp+0x20]
  s   = f32( rB − d )                                // 0x9178AA–0x9178BA
  dist= f32( d − f32(rA + rB) )                      // 0x9178BE–0x9178D2
  if !(dist < tol): REMOVE                           // fcomp, test ah,0x41 at 0x9178E0: keep only when dist < tol
  out.pos = P + s*N (xyz, and w = P.w + s*N.w);  out.n.xyz = N.xyz;  out.w = dist;  out.id = point.id
  output.first += 0x30
  ```
- **REMOVE** (0x917954):
  - if id ≠ 0xFFFF, call `mgr->vtable[0x14](id, output.constraintOwner)`;
  - the last point is copied into slot i, i−− and np−−.
  - After the loop, if anything was removed, the id table is shifted and compacted with `FUN_009161C0` (0x917A04).

Which case arithmetic is hand-verified:
- P: the (1,1) compare, the (1,2) reject idiom, and the emit tail.
- I: the other cases' arithmetic order, taken from `n2/out1/d_00916360.c` (cases 6–13, lines 89–377). A port gate must
  re-trace them in `n2/dis/d_916360.s` (line ranges: case 5 lines 41–~110, case 6 ~111–380, case 7 ~380–750, case 9
  ~750–1010, case 10 ~1010–1200, case 13 ~1200–1490).

### 5.4 `FUN_00918580` — add the new point to the manifold — P (decomp `n2/out2/d_00918580.c`)

Arguments: (man, cdA, cdB, input, output, cache, out, prevFirst, mgr, flag68), where
flag68 = `collisionInput[+0x68] != 0` = 0 in the capture.

For the boat, flag68 does not change the outcome:
- if it were 1, the id would stay 0xFFFF;
- the caller (§5, case 4) would then add the point itself, because output+0x3080 is NULL.

Only the order of manager calls relative to the id-table rebuild would differ (I).

```
if man.np == 4:                                       // manifold full (max 4 points)
    k = FUN_00917A40(...)                             // choose the point to drop among 4 old + 1 new (§5.5)
    if k == 4: return 5                               // the new point is the worst: reject it
    mgr->vtable[0x14](man.point[k].id, owner)         // removeContactPoint
    point[k] := point[0] (or point[0] := point[1..] when k == 0); compact ids (FUN_009161C0)
    id = mgr->vtable[0xC](cdA, cdB, input, output, cache, out)        // addContactPoint
    if id == 0xFFFF: undo the slot, FUN_0090BE70(...); return 6
    out.id = id; FUN_0090BE70(4); (then fill slot 0, below); return k
else:
    if flag68 == 0 or cache.dimB == 3:                // boat: flag68 = 0, so always add now
        id = mgr->vtable[0xC](cdA, cdB, input, output, cache, out); if id == 0xFFFF: return 5
    else id = 0xFFFF                                  // deferred to the caller's queue path
    out.id = id
    shift the id table up 8 bytes; point[np] := point[0]; np++      // the new point goes to slot 0
point[0].dimA, dimB = cache.dimA, cache.dimB; point[0].vtx = 0; point[0].id = id
for each cache vertex: find its id in the table (insert it if absent; A ids before B ids, with nA/nB++), vtx[j] = index << 4
if any A id was inserted: bump the vtx bytes of the other points by 0x10 per insertion
return 4
```

So the newest point always lives in slot 0, and `addContactPoint` is called **from inside the manifold code**, before
the caller's own `out.id == 0xFFFF` test, which then only advances `output.first`. **P** (control flow); the
0x90BE70 role is ND-7.

### 5.5 `FUN_00917A40` — which point to drop when 5 exist — ND for the arithmetic (structure only)

It is register-called (`in_ECX`). It compares distances and areas over the 4 + 1 points, with these constants
(`n2/skel_917a40.txt`; the f64 vs f32 width is by the decomp cast, I):

| Address | Value |
|---|---|
| 0xBEAB40 | f32 3.40282e38 (bits 0x7F7FFFEE) |
| 0xB58BF8 | f64 3.40282e38 |
| 0xB5A3F0 | f64 1.05 |
| 0xB5A3E8 | f64 526.0 |
| 0xB5A3E0 | f32 0.0304617 = (10°)² in rad² |
| 0xB5A3D8 | f64 1e-9 |
| 0xB5A3D0 | f64 0.0304617 |

It returns 0..3 (drop that point) or 4 (drop the new one). The loop fallback returns the first unflagged index, else 0
(decomp lines 233–242). This matters only once a manifold reaches 4 points.

---

## 6. Welding and snapping — P

- `FUN_00A09930(cinfo+0x88, cinfo+0x8C)`: the call at 0x8D8F7D pushes `fld [edi+0x8C]` → arg 2 and `fld [edi+0x88]` →
  arg 1 (0x8D8F6A–0x8D8F7A; edi = cinfo). It fills **31 entries × 24 bytes** at 0xE74810..0xE74AFC (6 f32 each: cos and
  sin pairs computed with `_CIcos`/`_CIsin`). The step is 0xB6BC70 = f64 0.20944 (12°) from −π (0xB59660 f64 π). The
  reflected `hkpWeldingUtility::NumAngles = 31` (`havok_contact/enums.txt`). The ctor then stores cinfo+0x88 into
  world+0xBC **and** +0xC0 (0x8D8F82–).
- **README correction:** the cinfo concave threshold 0.698 is *not* unused. It reaches the weld table as arg 2.
  Only the world+0xC0 copy takes 0.524. This is moot for terrain, below.
- **The only reader by absolute address** is `FUN_008AB520` (decomp grep of `DAT_00e7481x` over the whole export,
  `n2/grep_qi_weld.txt`). `FUN_008F72C0` passes `&DAT_00E74810` into the job data, so a reader through that pointer
  was not excluded (I). `FUN_008AB520` is **slot +0x38
  of `hkpTriangleShape::vftable` 0xB57B34** (the vtable is proven by `FUN_00A0D1C0` returning it; dword dump
  `n2/vt_tricoll.txt`). It is the triangle call in §5: `this` = triangle, 7 args, `ret 0x1C`.
- **First instruction:** `movzx eax,[tri+0x16]; cmp eax,6; je → mov eax,2; ret 0x1C` (0x8AB52E–0x8AB539,
  0x8ABA89–0x8ABA94). Reflected enum `hkpWeldingUtility::WeldingType`: 6 = WELDING_TYPE_NONE.
- **Every terrain triangle is built with weldingType 6 and weldingInfo 0.** `WpMeshShape16` getChildShape `FUN_00725600`
  (container vtable 0xBD2404 slot +0x14) writes `mov word [eax+0x14],dx (0); mov byte [eax+0x16],6` at 0x725AB8/0x725ABC,
  and nothing later in that function rewrites +0x16 (`n2/grep_725600.txt`).
- **Therefore for the boat vs terrain the weld step is a no-op: it returns 2, so the manifold is unchanged and flag 0x10
  is never set.** **P** for this triangle source. That no other agent rewrites tri+0x16 after getChildShape: **I**.
- The snap thresholds 0.524 / 0.698 are therefore **unused** in this pair. Decoding the rest of `FUN_008AB520`
  (0x8AB53F–0x8ABA88, for weld types 0/4/5) is not needed for the boat and was not done (ND-4).
- The other welding mechanism, the `output+0x3080` potential-contact queue, is NULL in the PSI job (§2.6). The
  REJECT_MANY world setting reaches this agent only through the quality-info values in §1 (I).

---

## 7. Interface to the contact manager (`hkpSimpleConstraintContactMgr`, vtable 0xB589D4) — P

Slots are from the dword dump `n2/mgr_vt.txt`; S1 decodes the bodies.

| Slot | Function | Called from (this agent) | Arguments |
|---|---|---|---|
| +0x0C | addContactPoint `0x8D3DA0` | 0x918580 (both branches), 0x92A869 | (cdA, cdB, input /*processInput*/, output, cache /*gskCache*/, out /*hkContactPoint* in output*/) → u16 id or 0xFFFF |
| +0x10 | reserveContactPoints `0x8D3A70` | 0x92A80F (queue path only, dead for the boat) | (1) → 0 ok |
| +0x14 | removeContactPoint `0x8D4180` | 0x914980 (also through slot [2] 0x901310 from the TIM machine), 0x916360 REMOVE, 0x918580 (full manifold) | (id u16 sign-extended, output.constraintOwner) |
| +0x18 / +0x1C / +0x20 | processContact / addToi / removeToi | **not called by this agent** | — |

Per-step order for one triangle sub-agent:
1. Remove calls for points that fail verification, in point order (0x916360).
2. At most one add (the new GSK point).
3. Then the caller (manager slot +0x18, processContact) runs elsewhere, per pair (S1).

Each emitted point is written into the output stream (stride 0x30) **before** `addContactPoint` copies its first 32
bytes (S1 §2.2). Refreshed points are re-emitted with their existing ids each step; that is how positions and distances
are updated (output stream only, no manager call here; I: the manager or solver reads them from the output via S1's
path).

---

## 8. Gate data from a live capture — P

S1 found the only boat-class body with points: the winch capture
`20261021_chris-jacobs-flying-winch.dmp`, manager 0x1C8A6C80, A = 0x1DF9D000, B = terrain 0x1E45C800. Walk
(`n2/winch1..7.txt`):
- body+0x5C → 0x1D56F220[0] = Nn entry 0x1DB26600 (type 9, mgr +8 = 0x1C8A6C80);
- its child-pair entries in sector 0x1D4BF000 include type-3 bvtree entries (`02 03 00 20`) holding tracks (0x1EABAA30,
  …);
- their sector 0x1E35C200 holds five type-0x0A sub-entries (`04 0a np size`).

The one with **np = 1** at **0x1E35C270**:
- sepNormal (−0.18919, 0.93219, 0.30859, w −0.00690). The normal equals S1's manager point normal (−0.18920, 0.93219,
  0.30859) to 5 digits.
- The manager point distance is 1.5e−5, against −0.0069 in sep.w. I: sep.w was overwritten by the refresh path with
  dT1 (§4), not the GSK distance.
- cache ids {0x56; 2, 0, 1}, dims (1,3), byte 0xFF, flags 0;
- manifold {nA 1, nB 3, np 1}, point {1, 3, id 0, vtx 0,0x10,0x20,0x30}, ids {0x56; 2, 0, 1}.

This proves §2.2–2.4 on live data: a vertex-of-hull vs face-of-triangle point, carried by the manifold.

Caveat: this body is a 5-child list on a different model (S1 §10). A per-number gate of the GSK needs the triangle
vertices (from the triangle key 0x01000756 through N1's getChildShape) and the hull vertex 0x56 of the body's convex
child. Both are in the same capture. Running them through §3 and §5.3 and comparing with the stored sep.xyz is the
offline gate; it was not run (ND-8).

The other entries in that sector have np = 0 with live caches: (1,3) at 0x1E35C210 and 0x1E35C240, (2,2) at 0x1E35C2B0.
They are gate inputs for the GSK alone (sep.xyz and w).

---

## 9. Floating-point environment — P (observed), ND (which thread)

- All the arithmetic in this agent is x87. It contains no `fldcw` (`gsk_core.md` §1 for the GSK closure; the
  manifold listings `n2/dis/d_916360.s`, `d_92a270.s` and `d_901510.s` use x87 only, I by inspection).
- The x87 control word of every thread in the first-mission capture was read from the minidump thread contexts
  (`n2/fpucw.py` → `n2/fpucw.txt`):
  - **27 of 28 threads: FCW 0x027F** (53-bit precision, round-to-nearest, all exceptions masked);
  - **one thread (tid 11456): FCW 0x007F, 24-bit precision**, the D3D9 default for the device thread.
  - MXCSR is 0x1F80–0x1FB7.
- **Havok thread.** The Havok monitor-stream TLS index (`DAT_00DFE754` = 25 in the capture) has a non-NULL slot
  (0x1FF10960) **only on tid 15824**, the first thread, at TEB+0xE10+4·25. Every other thread's slot is 0
  (`n2/tlsscan.py` → `n2/tlsscan.txt`). The block it points to is zeroed, so the timer stream was idle.
  - I: Havok's per-thread init ran only on 15824, so the jobs run there. That matches the memory note
    `pimp-one-job-worker`.
  - Its FCW is **0x027F (53-bit)**.
  - I: that it holds that value *during* the narrowphase. The capture shows the thread waiting in ntdll, and no
    `fldcw` exists in this agent's closure, but other code on that thread was not checked.
- Precision changes results wherever a chain is held in registers across operations (`gsk_core.md` §10). The port
  should start at 53-bit precision and confirm with the gate. ND-1 is narrowed, not closed.

---

## 10. Off-path: the continuous branch `FUN_0091AAC0`

It is called only when quality+0x10 ≠ 0 (§4), with
(input, rp = min allowedPenetrationDepth, t1, t2, agentData, sep, output) per the listing 0x901510–0x901665. Its body
(7136 bytes, 0x91AACC–) is decompiled in `n2/out2/d_0091aac0.c`. It was not specified, because the boat/terrain pair
never reaches it (§1). ND-5.

---

## 11. NOT DETERMINED

1. **Physics-thread x87 precision *during* the step.**
   - Tried: the minidump FCW of all 28 threads, the stacks (text only), and the Havok TLS slot. The slot identifies
     tid 15824, FCW 0x027F at capture time (§9).
   - Not proven: that nothing on that thread changes the FCW mid-frame.
   - Next: grep the exe for `fldcw` / `_controlfp` callers on the main loop path, or take a capture mid-step.
2. **Order of `x' = ((t.x + z·R2) + x·R0) + y·R1` in the vertex transforms** (§2.5). Taken from the decomp, not
   hand-traced on the x87 stack (0x9017D3–0x901848).
3. **0x916360 cases 6, 7, 9, 10 and 13**: the arithmetic order is from the decomp. The reject idioms of cases 5/6 and
   the emit tail are hand-checked. Line ranges for re-tracing are in §5.3.
4. **`FUN_008AB520` for weld types other than 6** (0x8AB53F–0x8ABA88). Not needed for terrain; not decoded.
5. **`FUN_0091AAC0`** (continuous, off-path). Decompiled, not specified.
6. **Create helpers `0x92AB20` / `0x92A8F0`**: the initial support direction and vertex choice. The decomp shows a
   support query (vtable +0x30) along a direction from the triangle (`n2/small_decomps.txt`); the arithmetic was not
   transcribed.
7. **`FUN_0090BE70`** (called by 0x918580 with 4 or `retaddr+0x90`): role not read.
8. **Per-number gate run.** The winch sub-entry inputs (§8) were located, but the hull vertex 0x56 and the triangle
   0x01000756 were not extracted and pushed through the pseudocode.
9. **Names of the input/output fields** (distAtT1, potentialContacts, the collisionInput+0x68 flag) are HK. The offsets
   and uses are P.
10. **`FUN_00917A40`** (5-point reduction): arithmetic not transcribed (§5.5).
11. **The `gsk_core.md` list** (its §12): the EPA leftovers, the support-function lanes, and signalling-NaN quieting.
    Its item 7, a cache entering with dims (2,3) or (3,2), is closed here as **I**: the only cache writers found are
    create (1,3)/(1,1) (§2.3) and the 0x90FE80 write-back of the GSK's exit dims, and the core never exits with (2,3)
    or (3,2) (`gsk_core.md`). The search for other writers of cache+8/+9 was not exhaustive.
