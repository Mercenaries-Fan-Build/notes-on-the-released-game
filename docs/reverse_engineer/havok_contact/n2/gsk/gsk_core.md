# GSK closest-point core `FUN_00912130` and its callees (pc-v10), port-ready scalar description

Binary: the restored copy `n2/mercs2_n2patched2.exe`. File offsets come from the PE section
table (`gsk/peread.py`, `.text` raw 0x1000 at VA 0x401000, so offset = VA − 0x400000; `.rdata`
raw 0x705000 at VA 0xB05000, so again offset = VA − 0x400000).

Grades:
- **PROVEN**: read this run from bytes, an objdump listing, or a mechanical trace. The source is cited.
- **INFERRED**: reasoned from proven facts, or recalled. Recalled Havok knowledge is always marked
  "(recall)".
- **SPECULATIVE**: a guess.
- **NOT DETERMINED**: unknown; the attempts are listed in §12.

The penetration-depth subtree under 0x941e10 was traced by a forked agent. It is summarised in §9.3,
and its full description is in `gsk/pd/pd_subtree.md`.

---

## 0. Method and artefacts (all paths under `gsk/`)

| artefact | what |
|---|---|
| `core_912130.s`, `core_raw.s` | objdump of 0x912130–0x91396f (Intel syntax), without and with raw bytes. The older `dis/d_912130.s` stopped at 0x912c6f. |
| `d_90e200.s`, `d_90e640.s`, `d_90e010.s`, `d_90f7d0.s`, `d_9219b0.s`, `d_910030.s`, `d_9118d0.s`, `d_9ee730.s`, `d_9ee850.s`, `d_90fe80.s`, `d_476d31.s` | callee listings. `raw_<va>.s` are the same with raw bytes. |
| `out1/_functions.tsv`, `out1/d_*.c` | Ghidra 12.1.4 headless `-noanalysis` on a new project `gsk/gproj`, script `scripts/GskDecomp.java` (N2Decomp plus body ranges), depth 3. Used for structure only. |
| `x87sym.py` (+ fork's two-pass `pd/x87sym_pd.py`), `batch.py`, `jobs_*.txt` | Symbolic x87 tracer. It emits SSA temps `tN`, versions stores as `[addr]@storeVA`, invalidates register-keyed memory on register writes, decodes `fcom…/fnstsw/test ah,m/jcc` into the outcome set {lt, eq, gt, un} that takes the jump, and models callee-popped args with `--pop`. |
| `tr/core_full.txt`, `tr/c_*.txt`, `tr/f_<va>.txt` | traces of the core and of each callee |
| `consts.txt`, `const_*.txt` | constants and tables read with `peread.py` |
| `splice_membership.txt` | SecuROM splice sites checked against every closure body range |
| `fsubdiv_summary.txt` | raw encodings of every register-form `fsub`/`fdiv` in the closure |

**x87 operand semantics.** These are PROVEN from bytes, with the semantics taken from the Intel SDM
opcode tables (recall, corroborated below). LLVM's Intel-syntax mnemonics match the SDM for every
form that occurs (`fsubdiv_summary.txt`):

| bytes | printed | semantics |
|---|---|---|
| `d8 e1` | `fsub st, st(1)` | st0 = st0 − st1 |
| `d8 e9` | `fsubr st, st(1)` | st0 = st1 − st0 |
| `de e1..e5` | `fsubrp st(i), st` | st(i) = st0 − st(i); pop |
| `de e9/ea` | `fsubp st(i), st` | st(i) = st(i) − st0; pop |
| `de f1/f2` | `fdivrp st(i), st` | st(i) = st0 / st(i); pop |
| `de f9` | `fdivp st(i), st` | st(i) = st(i) / st0; pop |

Two corroborations:
- `fld1; fdivrp st(1)` (0x912e92, 0x91382b) then yields 1/x, which is what the normalisations need.
- `fsubr st,st(1); fdivp st(1)` at 0x90fc42/0x90fc4b yields g0/(g0−g1), an interpolation parameter.

**fcom decoding** (PROVEN mechanically by `x87sym.outcomes()`):
- ah bits: lt → C0 (0x01), eq → C3 (0x40), gt → 0, unordered → C0|C2|C3 (0x45).
- `je`/`jne` test ZF of `ah & mask`; `jp`/`jnp` test the parity of `ah & mask`.
- Every comparison below is written as the predicate that holds on the path taken, with NaN stated.

**Notation in the pseudocode:**
- `f32(x)`: a value written with `fst/fstp dword`, i.e. rounded to binary32.
- Arithmetic without `f32()` is an x87 register intermediate. Its rounding is set by the run-time
  precision-control word, which is NOT DETERMINED (§10).
- `copy4(dst, src)`: four `fld dword` + `fstp dword` lane copies (see §10 for the NaN-bit caveat).
- Dot products and cross products are written with the exact association and operand order of the
  listing. Additions are commutative in IEEE, so only the association matters for them;
  subtractions are written in their exact order.

---

## 1. Mechanical checks

- **SecuROM splices** (PROVEN, `splice_membership.txt`). Every site in
  `output/_exemap_exports/pc-v10.splices.tsv` was tested against every body range in
  `out1/_functions.tsv` and against 0x912130–0x91396f. Three sites fall inside, and all three are
  APPLIED in `n2/patch2.txt`:
  - 0x912136 `sub esp,0x204`
  - 0x912935 `mov dword [esp+0x20],1`
  - 0x90e646 `sub esp,0x9c`

  No skipped "complex gadget" site lies in this closure. The fork ran the same check for the
  0x941e10 subtree and found no site.
- **Patched vs original bytes** (PROVEN, `cmp_all.txt` → `diff_runs.txt` → `diff_vs_applied.txt`).
  All 66 differing byte runs lie inside the 65 APPLIED sites of `patch2.txt`; one site splits into
  two runs because a byte happens to match. Inside this closure the differences are exactly the
  three sites above.
- **x87 vs SSE** (PROVEN, `sse_grep.txt`, a grep of `xmm|movss|mulps|cvt|fldcw|fnstcw|fninit` over
  the core and every callee listing):
  - zero hits; all arithmetic in 0x912130, 0x90e200, 0x90e640, 0x90e010, 0x90f7d0, 0x9219b0,
    0x9118d0 and 0x910030 is x87.
  - No function in the closure sets the FPU control word.
  - The fork found that the only SSE function in the 0x941e10 subtree is 0x41bc80 (scalar f32).
- **0x9ee730** (PROVEN, `d_9ee730.s`) is `jmp dword [0xB053AC]`. The fork resolved that IAT slot to
  MSVCR80 `_CIsqrt` (`pd/import_b053ac.txt`). Callers leave the argument in st0 and the result is
  st0. INFERRED (recall): `_CIsqrt` executes `fsqrt`, so its rounding also follows the precision
  control.
- **0x90fe80's out-of-range chunk [0x476d31, 0x476d3b]** (PROVEN, `d_476d31.s`). It is
  `mov edi,[0x245D664]; jmp 0x90feb7`, a two-instruction hop that 0x90fe80 reaches by
  `jmp 0x476d31` at 0x90feb2. `[0x245D664]` = 1 in the patched copy, the original exe, and the
  capture (`const_245d664.txt`). 0x90fe80 is the caller's simplex write-back and is outside the
  core closure; it was not traced further.

### 1.1 Calling conventions

All PROVEN from the listings unless marked otherwise.

| fn | convention | args | return |
|---|---|---|---|
| 0x912130 core | thiscall ecx = GSK; `ret 0x10` (0x9138d9) | shapeA, shapeB, aTb (4×4 f32, columns c0,c1,c2,t), out (4 f32) | eax: 0 normally, 4 on the clamp path (§3.9). In 0x913a08–0x913a1c the caller does not test eax (0x913a08 tests GSK+0x14). The rest of 0x913970 was not traced; there is an unexamined `cmp [esp+0x20],eax` at 0x913aac. |
| shape vtable +0x30 (support) | thiscall, 2 args (dir*, out*), callee pops 8 | | INFERRED: after the call the core reads `−n` at the same [esp+0x50] where it was stored before the two pushes (0x912a47 → 0x912ab6), so the callee must pop 8. |
| 0x90f7d0 | thiscall; `ret 0x18` | seg*, tri*, &segDim, &triDim, `bool` (byte built in place by `push ecx; mov ecx,esp; mov [ecx],dl`), sign ±8 | 0 / 1 / 2 |
| 0x90e200 | thiscall; `ret 0xc` | P*, T* (3 verts), flag (0 or ±8) | region code |
| 0x90e640 | ecx = P*, edx = T* (4 verts), one stack f32 `sign`; plain `ret`; caller `add esp,4` (0x912466, 0x912731) | | index or −1 |
| 0x90e010 | cdecl (P*, s*), plus **edx = T*** left by 0x90e640 (0x90e640 never writes edx: `edx_90e640.txt`, `mov/lea/pop edx` none); caller `add esp,8` (0x90eaa6) | | index or −1 |
| 0x9219b0 | cdecl, 5 args; caller `add esp,0x14` (0x9123ae, 0x911fbb) | P0*, d1*, Q0*, d2*, out* (9 f32) | flag bits |
| 0x9118d0 | thiscall; `ret 0xc` (0x912002) | shapeA, shapeB, aTb | void |
| 0x910030 | thiscall, no args; plain `ret` | | void |
| 0x941e10 | cdecl, 9 args; caller `add esp,0x24` (0x911d0f) | shapeA, shapeB, aTb, eps f32, Averts*, Braw*, M*, count, out* | 0 / 1 / 2 (fork) |

---

## 2. GSK object layout (`this`, 16-byte aligned stack object of 0x913970)

Caller evidence (PROVEN, `dis/d_913970.s`): with X = esp after `push ebx/esi/edi`, the core is
called with `lea ecx,[esp+0x30]` after 4 pushes, i.e. this = X+0x20.

| off | type | meaning | evidence |
|---|---|---|---|
| +0x000 | i32 | dimA (simplex size on A) | caller 0x913993 = cache byte +8; core reads `[esi]` throughout |
| +0x004 | i32 | dimB | caller 0x91399b = cache byte +9 |
| +0x008 | i32 | maxA | caller 0x9139a4 = byte +0xA & 0xF; core 0x912a21, 0x91359e |
| +0x00C | i32 | maxB | caller 0x9139b4 = byte +0xA >> 4; core 0x913298 |
| +0x010 | i32 | selects the clamp exit instead of the penetration fallback | caller 0x9139b8 = 0. Nothing in the closure writes it (the grep `objwrites.txt` and the traces), so for 0x913970 it is always 0 and the 0x9138dc path is dead. |
| +0x014 | i32 | "simplex changed" flag | caller 0x9139c0 = 0. Writers: core 0x912960 (`or` with Δsize), 0x912c04, 0x91327f, 0x913581, 0x913783 (=1); 0x90e200 0x90e607 (=1); 0x9118d0 0x911ff6 (=1). The caller tests it at 0x913a08, then calls 0x90fe80. |
| +0x020..0x05F | f32[4][4] | A[0..3], A-space simplex vertices; w = vertex-id bits | caller 0x9139ab (shapeA vtable+0x34 fills them). The w lane holds ids: 0x9118d0 compares `bits(w) & 0xC0FFFFFF` (0x911d24…). |
| +0x060..0x09F | f32[4][4] | "A companion" array. Moved only by the generic copy code that, for B, moves the raw array (the array pointer + 0x40). | The caller never fills it (only +0x20 and +0xE0, 0x9139ab/0x9139da). The core never reads +0x60..0x9F into arithmetic (`core_field_grep.txt`; copies at 0x913215 through edi+0x40/0x50). INFERRED: dead mirror; a port may keep it as copies. |
| +0x0A0..0x0DF | f32[4][4] | B[0..3] transformed into A space; w = 0 | prologue 0x9121d9 loop, 0x913500, 0x911e8f |
| +0x0E0..0x11F | f32[4][4] | Braw[0..3], B-space vertices; w = id bits | caller 0x9139da (shapeB vtable+0x34) |
| +0x120..0x12C | f32[4] | n = (x,y,z,w): unnormalised direction inside the loop, normalised at exit | Exit writes: 0x913844…; +0x12C gets the distance at 0x9138cd. |
| +0x130..0x150 | f32[9] | out of 0x9219b0: +0x130 point on seg A (4), +0x140 = that point − point on seg B (4), +0x150 squared distance | 0x912330, 0x911f4e. The core never reads it back (`core_field_grep.txt`). |
| +0x160..0x16C | f32[4] | 0x90e200 region weights (d0,d1,d2,0) | written 0x90e437–0x90e453, swapped 0x90e5e7–0x90e601; read by 0x90f7d0 (0x90fb75–0x90fb9d, 0x90fd36…) |
| +0x170 | i32 | dimB at the time the last normal was produced | 0x913261; read 0x9122de/0x9122fa (`== 2`) |
| +0x174 | i32 | one-iteration block: 8 blocks the A support, −8 blocks the B support | reset to 0 at 0x9122b9 on every outer iteration; set by 0x90f7d0 at 0x90fce1 (= its sign arg); tested at 0x912a2a/0x9135a7 (==8) and 0x9132a1 (==−8) |

**Fields uninitialised at entry** (PROVEN: the caller listing 0x913970–0x913a03 writes only
+0x00..+0x14 and, through vtable+0x34, the +0x20 and +0xE0 arrays; there are no other stores
before the call):
- n (+0x120..+0x12C), the weights W (+0x160..+0x16C), lastB (+0x170) and blk (+0x174).
- blk is reset at every outer iteration, so it is harmless.
- After FAIL, POST reads n before writing it, but the only use is the TERMINATE branch, which
  ignores it.

Which reads can see garbage (INFERRED by enumerating the case exits in §3):
- lastB is read only at dims (2,3)/(3,2).
- n and W are read only by 0x90f7d0's `prev2 == false` path.
- Within one call, every route into (2,3) or (3,2) passes through a NORMAL first, which writes
  lastB and n.
- Where `prev2` is false, the previous NORMAL dimB was 1 or 3, and those NORMALs come from
  PT_TRI, TRI_PT or 0x90f7d0 calls, all of which run 0x90e200 and so write W.
- Hence the only route that reads uninitialised lastB, n and W is a call that **enters** with
  cache dims (2,3) or (3,2).
- The core never exits with those dims. FINISH is reached only after a case ending in
  (1,1)/(1,2)/(2,1)/(1,3)/(3,1)/(2,2). The 0x9118d0 path reduces any sum above 4 via 0x910030
  (0x911f1c–0x911f28) to (3,1), (1,3) or (2,2).
- Whether the cache can still hold (2,3)/(3,2), through 0x90fe80's write-back or the cache's
  initial value, is NOT DETERMINED (§12).
- A port has to choose initial values for this case.

Core stack locals (PROVEN):

| local | meaning |
|---|---|
| [esp+0x28] | `iter`, 0 then +1 per outer iteration |
| [esp+0x2c] | `eps` (f32) |
| [esp+0x14] | dimA+dimB at the start of the outer iteration |
| [esp+0x20] | first the "no new normal" flag, then `eL` |
| [esp+0x1c] | `iter & 1` |
| [esp+0x40..0x8c] | aTb copy: t at 0x40, c2 at 0x50, c0 at 0x70, c1 at 0x80. Only the prologue loop reads it; 0x9135c4 later overwrites 0x70..0x7c with −n. |

---

## 3. FUN_00912130, the core (x87; PROVEN from `core_912130.s`, `tr/core_full.txt`, `tr/c_*.txt`)

### 3.1 Prologue: B into A space (0x912141–0x912269)

```
// c0=aTb[0..3], c1=aTb[4..7], c2=aTb[8..11], t=aTb[12..15]
for i = dimB-1 down to 0:          // ecx=dimB-1; body: ecx-=1; ...; test ecx; jge  (0x9121dc/0x9121e6/0x912263)
    x=f32 Braw[i].x; y=Braw[i].y; z=Braw[i].z      // re-stored to locals, values unchanged
    B[i].x = f32(((y*c1.x + x*c0.x) + z*c2.x) + t.x)
    B[i].y = f32(((y*c1.y + x*c0.y) + z*c2.y) + t.y)
    B[i].z = f32(((y*c1.z + x*c0.z) + z*c2.z) + t.z)
    B[i].w = 0.0
iter = 0
eps  = f32 [0xB5A3B8]   // 0x2EDBE6FF = 1.000000013351432e-10, fld dword (0x91227b)
```

If dimB = 0 the loop still runs once, with index −1 (PROVEN from the loop shape). INFERRED: the
caller never passes 0.

### 3.2 Outer loop head and dispatch (0x912290–0x9122d7, re-dispatch 0x91291e–0x91292f)

```
OUTER:
    eps  = f32(eps + eps)           // doubled BEFORE first use: 2e-10, 4e-10, ...
    iter = iter + 1
    sum0 = dimA + dimB
    this.blk(+0x174) = 0
DISPATCH:
    idx = ((dimA*8) | dimB) - 9     // OR, not add (0x9122ad)
    if (u32)idx > 24: goto FAIL     // ja 0x912935
    goto CASE[ tbl_91394C[idx] ]    // jmp [4*b + 0x913920]
```

`tbl_91394C` (u8[25], PROVEN `consts.txt`):
`0,1,2,3,10,10,10,10,4,5,6,10,10,10,10,10,7,8,10,10,10,10,10,10,9`.

| idx | (dimA,dimB) | byte | target | case |
|---|---|---|---|---|
| 0 | (1,1) | 0 | 0x913230 | PT_PT |
| 1 | (1,2) | 1 | 0x912d71 | PT_SEG (A point, B segment) |
| 2 | (1,3) | 2 | 0x9124cc | PT_TRI (A point, B triangle) |
| 3 | (1,4) | 3 | 0x912457 | PT_TET (A point, B tetra) |
| 8 | (2,1) | 4 | 0x912fed | SEG_PT |
| 9 | (2,2) | 5 | 0x91232d | SEG_SEG |
| 10 | (2,3) | 6 | 0x9122de | SEG_TRI |
| 16 | (3,1) | 7 | 0x91275f | TRI_PT |
| 17 | (3,2) | 8 | 0x9122fa | TRI_SEG |
| 24 | (4,1) | 9 | 0x91271e | TET_PT |
| every other idx 0..24 | | 10 | 0x912935 | FAIL |

Dword table 0x913920 (PROVEN): `[0x913230, 0x912d71, 0x9124cc, 0x912457, 0x912fed, 0x91232d,
0x9122de, 0x91275f, 0x9122fa, 0x91271e, 0x912935]`.

The case blocks end in one of three ways:
- **NORMAL** (0x91325e): a new n was written. Sets `this.lastB(+0x170) = dimB`, `nonew = 0`, then POST.
- **FAIL** (0x912935): sets `nonew = 1` (the restored splice), then POST.
- **REDISPATCH** (0x91291e): the simplex was reduced; goes back to DISPATCH without doubling eps.

Every reduction lowers dimA+dimB, so the DISPATCH loop terminates (INFERRED from the case code).

### 3.3 Cases with no callee (all f32 rounding points shown)

**PT_PT (0x913230):**
```
n = (f32(A0.x-B0.x), f32(A0.y-B0.y), f32(A0.z-B0.z), f32(A0.w-B0.w))   // w lane too
goto NORMAL
```

**PT_SEG (0x912d71).** Point a = A0, segment b0 = B0, b1 = B1.
```
e  = f32(b1-b0) (xyz);  u1 = f32(b1-a);  u0 = f32(b0-a)
dot0 = f32((u0.x*e.x + u0.y*e.y) + u0.z*e.z)
dot1 = f32((u1.x*e.x + u1.y*e.y) + u1.z*e.z)
f1 = (dot1 < 0) ? 8 : 0          // strict; NaN -> 0   (0x912e3b-0x912e4d)
f0 = (dot0 < 0) ? 8 : 0
if f1 == f0:                      // vertex region
    if f1 != 0: copy4(B[0],B[1]); copy4(Braw[0],Braw[1])   // 0x912f85
    dimB -= 1; goto PT_PT
L   = f32((e.x*e.x + e.y*e.y) + e.z*e.z)
inv = f32(1.0 / f32(_CIsqrt(L)))   // no zero test here
e   = (f32(inv*e.x), f32(e.y*inv), f32(inv*e.z))
c   = ( f32(u0.z*u1.y - u0.y*u1.z),
        f32(u1.z*u0.x - u0.z*u1.x),
        f32(u1.x*u0.y - u0.x*u1.y) )            // = u1 x u0
n   = ( f32(c.z*e.y - c.y*e.z),
        f32(e.z*c.x - c.z*e.x),
        f32(e.x*c.y - c.x*e.y), +0.0 )          // = e x c ;  n.w from fldz (0x912f74)
goto NORMAL
```

**SEG_PT (0x912fed).** Segment a0 = A0, a1 = A1; point b = B0. This mirrors PT_SEG, with these
differences:
```
e = f32(a1-a0); u1 = f32(a1-b); u0 = f32(a0-b)
dot0, dot1, f0, f1 as above
if f1 == f0:
    if f1 != 0: copy4(A[0],A[1]); copy4(Acomp[0],Acomp[1])   // +0x60 <- +0x70 (0x9131fe)
    dimA -= 1; goto PT_PT
normalise e exactly as above (0x9130f9-0x913132)
c = (f32(u0.z*u1.y - u0.y*u1.z), f32(u1.z*u0.x - u0.z*u1.x), f32(u1.x*u0.y - u0.x*u1.y))
n = ( f32(c.y*e.z - c.z*e.y),
      f32(c.z*e.x - e.z*c.x),
      f32(e.y*c.x - c.y*e.x), +0.0 )            // = c x e  (opposite of PT_SEG)
goto NORMAL
```

### 3.4 Cases that call the classifiers

Tables (PROVEN `consts.txt`):
- `tbl560` = i8[16] at 0xB5A560: `[-1,-1,2,-1,1,-1,-8,-1,0,-1,-7,-1,-6,-1,-1,-1]`.
- `tbl570` = i8 at 0xB5A570: `[2,0,1]`.
- `tbl572` = i8 at 0xB5A572: `[1,2,0]`. It overlaps `tbl570`; bytes 0xB5A570.. are 02 00 01 02 00.

**PT_TET (0x912457):**
```
r = FUN_90e640(P=A0, T=B, sign=+1.0f)          // fld1
if r < 0: goto FAIL
dimB -= 1; copy4(B[r],B[3]); copy4(Braw[r],Braw[3])
fall into PT_TRI
```

**PT_TRI (0x9124cc):**
```
code = FUN_90e200(this, P=A0, T=B, +8)
if code == 0xE: goto NORMAL                    // n written by 0x90e200
k = tbl560[code]
if k < 0:                                       // 0x912d09: edge region
    j = k+8; if j > 3: j = 1                    // (k = -1 -> j = 1)
    dimB -= 1; copy4(B[j],B[2]); copy4(Braw[j],Braw[2])
    goto PT_SEG                                  // falls into 0x912d71
c1 = tbl570[k]; c2 = tbl572[k]
u  = f32(A0 - B[k]);  e1 = f32(B[c1]-B[k]);  e2 = f32(B[c2]-B[k])   (xyz)
dimB = 2
d1 = f32((e1.x*u.x + e1.y*u.y) + e1.z*u.z)
if !(d1 < 0):                                   // d1 >= 0 or NaN  (0x9126bf)
    copy4(B[c2],B[2]); copy4(Braw[c2],Braw[2]); goto REDISPATCH
copy4(B[c1],B[2]); copy4(Braw[c1],Braw[2])
d2 = f32((u.x*e2.x + u.y*e2.y) + u.z*e2.z)     // operands still held in registers
if !(d2 < 0): goto REDISPATCH
j = (c2 == 2) ? c1 : c2
dimB = 1; copy4(B[j],B[1]); copy4(Braw[j],Braw[1]); goto REDISPATCH
```

**TET_PT (0x91271e)** and **TRI_PT (0x91275f)** are the same with the roles swapped:
- P = B0 and T = A.
- 0x90e640 gets `sign = f32 [0xB12A50] = −1.0`; 0x90e200 gets flag −8.
- Only A arrays are copied; there is no companion copy (0x912748, 0x91287c, 0x912907, 0x9128e1,
  0x912fcd).
- The edge-region path goes to SEG_PT (0x912fed).
- In the vertex path `u = f32(B0 − A[k])`, `e1 = f32(A[c1] − A[k])`, `e2 = f32(A[c2] − A[k])`.

**SEG_SEG (0x91232d):**
```
dA = f32(A1-A0) (4 lanes);  dB = f32(B1-B0) (4 lanes)
r = FUN_9219b0(&A0, &dA, &B0, &dB, &this.+0x130)
if r == 0:                                      // 0x912c10
    n = ( f32(dB.z*dA.y - dB.y*dA.z),
          f32(dA.z*dB.x - dB.z*dA.x),
          f32(dA.x*dB.y - dB.x*dA.y), +0.0 )    // = dA x dB
    w0 = f32(A0-B0) (xyz)
    s  = f32((n.y*w0.y + n.x*w0.x) + n.z*w0.z)
    if !(s < 0): goto NORMAL                    // s >= 0 or NaN keeps n
    n = (f32(-n.x), f32(-n.y), f32(-n.z), -(+0.0) = -0.0); goto NORMAL
if r & 1: copy4(A[0],A[1])
if r & 1 or r & 2: dimA = 1                    // 0x9123da
if r & 4: copy4(B[0],B[1]); copy4(Braw[0],Braw[1]); dimB = 1
elif r & 8: dimB = 1
goto REDISPATCH
```

**SEG_TRI (0x9122de) / TRI_SEG (0x9122fa):**
```
prev2 = (this.lastB(+0x170) == 2)
SEG_TRI: r = FUN_90f7d0(this, seg=A, tri=B, &dimA, &dimB, prev2, +8)
TRI_SEG: r = FUN_90f7d0(this, seg=B, tri=A, &dimB, &dimA, prev2, -8)
if r == 1: goto FAIL
if r == 2: goto SEG_SEG            // directly to 0x91232d, no re-dispatch
goto NORMAL                        // r == 0 (or anything else)
```

When 0x90f7d0 returns 0 from its `prev2 == false` path (0x90fcea), it has **not** written n,
because its 0x90e200 calls pass flag 0. NORMAL then proceeds with the n of the previous iteration
(PROVEN by control flow, §5).

### 3.5 POST: bookkeeping and termination tests (0x91293d–0x912a31)

```
POST:
  L  = f32((n.x*n.x + n.y*n.y) + n.z*n.z)            // 0x912974
  this.chg(+0x14) |= (dimA - sum0) + dimB
  w0 = f32(A0-B0) (xyz)
  d  = f32((n.y*w0.y + n.x*w0.x) + n.z*w0.z)          // 0x9129c8
  if nonew != 0: goto TERMINATE
  eLr = L * eps                                       // register, NOT rounded yet
  ad  = f32(|d|)                                      // exact
  if (d*ad) <= eLr  (ordered lt or eq):  goto TERMINATE   // 0x9129f0 fcomp; jnp
  if eps > L        (ordered, strict):   goto TERMINATE   // 0x9129fd fcomp; je
  eL  = f32(eLr)                                      // 0x912a10
  odd = iter & 1
  if odd and dimA != maxA and blk != 8:   if TRY_A(): goto OUTER
  if dimB != maxB and blk != -8:          if TRY_B(): goto OUTER
  if !odd and dimA != maxA and blk != 8:  if TRY_A(): goto OUTER
  goto FINISH
```

- `d*ad <= eLr` is the test `d·|d| ≤ eps·|n|²`. Every d < 0 satisfies it, and so does any d with
  d² ≤ eps·|n|². The two sides are unrounded register products (§10).
- NaN in n fails both termination tests and continues. Both supports then reject (below), so the
  path ends in FINISH.
- No iteration counter is compared anywhere: `iter` is only used for `& 1` (PROVEN; there are no
  other reads of [esp+0x28]). The loop ends through the tests above, through maxA/maxB, or because
  eps grows past L. Since eps doubles from 2e-10, it reaches the order of 1 after about 33
  iterations (INFERRED arithmetic).

### 3.6 TRY_A (0x912a37 for odd iterations; 0x9135b4 for even)

```
dir = (f32(-n.x), f32(-n.y), f32(-n.z), f32(-n.w))
shapeA->vtbl[0x30](&dir, &A[dimA])              // support of A along -n, A space
v = A[dimA]
qA(P): w = f32(v - P) (xyz)
       dt = f32((w.x*dir.x + w.y*dir.y) + w.z*dir.z)
       return f32(dt * f32(|dt|))
if !(eL < qA(A0)):        reject                // strict; NaN rejects   (0x912b04, jp)
if dimA == 3: if qA(A2) < eL:  reject           // NaN passes            (0x912b84, jnp)
if dimA == 2 or dimA == 3: if qA(A1) < eL: reject
dimA += 1; this.chg = 1; accept (goto OUTER)    // dimA not in {2,3}: accepted after the A0 test alone
```

### 3.7 TRY_B (0x9132ae)

The direction is +n rotated into B space (`Rᵀn`); the operands are f32 copies of n:
```
dB.x = f32((c0.y*n.y + n.x*c0.x) + c0.z*n.z)
dB.y = f32((n.x*c1.x + c1.y*n.y) + n.z*c1.z)
dB.z = f32((n.y*c2.y + n.x*c2.x) + n.z*c2.z)
dB.w = 0.0
shapeB->vtbl[0x30](&dB, &Braw[dimB])            // B-space support
v = Braw[dimB]
qB(P): w = f32(v - Braw[P]) (xyz)
       dt = f32((w.x*dB.x + dB.y*w.y) + dB.z*w.z)
       return f32(dt * f32(|dt|))
if !(eL < qB(0)): reject
if dimB == 3: if qB(2) < eL: reject
if dimB in {2,3}: if qB(1) < eL: reject
// accept (0x913500)
B[dimB].x = f32(((x*c0.x + y*c1.x) + z*c2.x) + t.x)       // x,y,z = f32 copies of v
B[dimB].y = f32(((c1.y*y + x*c0.y) + z*c2.y) + t.y)
B[dimB].z = f32(((x*c0.z + y*c1.z) + z*c2.z) + t.z)
B[dimB].w = 0.0
dimB += 1; this.chg = 1; goto OUTER
```

The direction is read from the aTb pointer itself (`[ebp+0x10]`), not from the stack copy.

### 3.8 FINISH (0x9137bc): normalise and output

```
w0 = f32(A0-B0) (xyz)
L  = f32((n.x*n.x + n.y*n.y) + n.z*n.z)
s  = (L == 0.0 ordered-equal) ? 0.0 : f32(1.0 / f32(_CIsqrt(L)))    // fucom; test ah,0x44; jnp (0x913815)
n  = (f32(s*n.x), f32(s*n.y), f32(s*n.z), f32(s*n.w))               // into this.n
out[0..3] = n
dist = f32((n.y*w0.y + w0.x*n.x) + n.z*w0.z)
out[3] = dist; this.n.w(+0x12C) = dist
return 0
```

`dist` is computed from the current A0/B0 and not from any solver distance. That includes the
0x9118d0 path, whose EPA distance (out9+0x20) is discarded (§9.1).

### 3.9 TERMINATE (0x913795)

```
if this.+0x10 != 0:          // dead for caller 0x913970 (§2)
    if dimA + dimB > 4:
        if dimA > dimB: dimA = 3; dimB = 1    else: dimA = 1; dimB = 3
    return 4                 // no out write, no normalisation
FUN_9118d0(this, shapeA, shapeB, aTb)
goto FINISH
```

---

## 4. FUN_0090e200: triangle/point region classifier (x87; `tr/f_90e200.txt`, `d_90e200.s`)

```
fn classify(this, P, T, flag) -> i32:
  e0 = f32(T2-T1); e1 = f32(T0-T2); e2 = f32(T1-T0)          (xyz)
  N  = ( f32(e1.z*e0.y - e1.y*e0.z),
         f32(e0.z*e1.x - e1.z*e0.x),
         f32(e1.y*e0.x - e0.y*e1.x) )                       // = e0 x e1
  p1 = f32(P-T1); p2 = f32(P-T2); p0 = f32(P-T0)
  c0 = ( f32(p1.y*e0.z - p1.z*e0.y), f32(p1.z*e0.x - e0.z*p1.x), f32(e0.y*p1.x - e0.x*p1.y) )  // p1 x e0
  c1 = ( f32(p2.y*e1.z - p2.z*e1.y), f32(p2.z*e1.x - e1.z*p2.x), f32(p2.x*e1.y - p2.y*e1.x) )  // p2 x e1
  c2 = ( f32(p0.y*e2.z - p0.z*e2.y), f32(p0.z*e2.x - e2.z*p0.x), f32(e2.y*p0.x - p0.y*e2.x) )  // p0 x e2
  d0 = f32((c0.x*N.x + c0.y*N.y) + c0.z*N.z)
  d1 = f32((c1.x*N.x + c1.y*N.y) + c1.z*N.z)
  d2 = f32((c2.x*N.x + c2.y*N.y) + c2.z*N.z)
  this.+0x160..0x16C = (d0, d1, d2, 0.0)
  code = ((d0<0)?8:0 | (d1<0)?4:0 | (d2<0)?2:0) & 0xE      // all strict, NaN -> bit clear
  if flag == 0: return code                                  // n untouched
  this.n = (N.x, N.y, N.z, 0.0)                             // written for every code when flag != 0
  if code != 0xE: return code
  w = f32(this.A0 - this.B0) (xyz)                          // the GSK's own A0/B0, not P
  s = f32((w.x*N.x + w.y*N.y) + w.z*N.z)
  if !(s < 0): return 0xE                                   // s >= 0 or NaN
  this.n = (f32(-N.x), f32(-N.y), f32(-N.z), f32[0xBEAA2C] = -0.0)
  swap16(T[0], T[1])            // T0 saved with integer movs; both writes go through fld/fstp dword
  swap16(T[4], T[5])            // companion array at T+0x40 / T+0x50
  swap(this.+0x160, this.+0x164)
  this.chg(+0x14) = 1
  return 0xE
```

The sign of `flag` (±8) is not used; only `flag == 0` is tested (0x90e49a is the only read).
INFERRED: `code` bit 8/4/2 means "P is outside edge 0/1/2", and 0xE means inside the triangle's
prism.

---

## 5. FUN_0090f7d0: segment vs triangle (x87; `tr/f_90f7d0.txt`, `d_90f7d0.s`)

Args: S (seg verts), T (tri verts), &segDim, &triDim, prev2 (byte), sign (±8).
Locals use L = esp after the prologue (`sub esp,0xc4` and 3 pushes).

```
if prev2 != 0:                                         // 0x90f7e9
  e1 = f32(T1-T2) (4 lanes); e0 = f32(T0-T2) (4 lanes)
  N  = ( f32(e0.z*e1.y - e0.y*e1.z), f32(e1.z*e0.x - e0.z*e1.x), f32(e1.x*e0.y - e0.x*e1.y) )   // e1 x e0
  q0 = f32(S0-T0); q1 = f32(S1-T0)
  h0 = f32((q0.y*N.y + N.x*q0.x) + q0.z*N.z)
  h1 = f32((N.y*q1.y + N.x*q1.x) + N.z*q1.z)
  if ((h0<0)?8:0) != ((h1<0)?8:0):                     // strict
      t  = f32(h0 / (h0 - h1));  s_ = f32(1.0 - t)
      P  = ( f32(S0.x*s_ + t*S1.x), f32(S1.y*t + S0.y*s_),
             f32(S1.z*t + s_*S0.z), f32(t*S1.w + S0.w*s_) )
      if classify(this, &P, T, 0) == 0xE: return 1     // crossing inside the triangle
      goto EDGES
  if f32(|h1|) < f32(|h0|):                            // strict (0x90f9d3)
      swap16(S[0],S[1]); swap16(S[4],S[5])             // seg companion at S+0x40/+0x50
  if classify(this, S0, T, 8) == 0xE:                  // writes this.n
      *segDim -= 1; return 0
EDGES:                                                 // 0x90fa9d
  dS = f32(S1-S0) (4 lanes)
  FUN_9219b0(S0, &dS, T2, &e1, bufA)                   // edge T2->T1
  FUN_9219b0(S0, &dS, T2, &e0, bufB)                   // edge T2->T0
  k = (bufB[8] < bufA[8]) ? 1 : 0                      // strict on squared distance; NaN -> 0
  copy4(T[k], T[2]); copy4(Tcomp[k], Tcomp[2])         // T+0x40+16k <- T+0x60
  *triDim -= 1; return 2
else:                                                  // 0x90fb67
  W  = this.+0x160..0x16C                              // weights from the previous classify call, copied as ints
  r1 = f32(S1-T0); g1 = f32((n.y*r1.y + r1.x*n.x) + n.z*r1.z)   // n = this.n (previous normal)
  r0 = f32(S0-T0); g0 = f32((n.y*r0.y + r0.x*n.x) + n.z*r0.z)
  if f32(g0*g1) < f32[0xB11AD0] (= 0.0, strict):
      t  = f32(g0 / (g0 - g1)); s_ = f32(1.0 - t)
      P  = ( f32(S0.x*s_ + S1.x*t), f32(S1.y*t + S0.y*s_),
             f32(S1.z*t + s_*S0.z), f32(s_*S0.w + t*S1.w) )
      if classify(this, &P, T, 0) == 0xE: return 1
  code = classify(this, S1, T, 0)                      // now this.+0x160 = w0,w1,w2 of S1
  if code == 0xE:
      *segDim -= 1; copy4(S[0],S[1]); this.blk(+0x174) = sign; copy4(Scomp[0],Scomp[1])
      return 0                                          // n NOT written in this path
  switch code:
    6:   DROP_T0
    0xA: DROP_T1
    0xC: DROP_T2
    8:   a=f32(w1-W1); b=f32(w2-W2); if (a*W2) > (W1*b) (strict): DROP_T2 else DROP_T1
    4:   a=f32(w2-W2); b=f32(w0-W0); if (a*W0) > (W2*b):           DROP_T0 else DROP_T2
    2:   a=f32(w0-W0); b=f32(w1-W1); if (a*W1) > (W0*b):           DROP_T1 else DROP_T0
    else (0): DROP_T0
  DROP_T0 (0x90fdb2): copy4(T[0],T[2]); copy4(Tcomp[0],Tcomp[2]); *triDim -= 1; return 2
  DROP_T1 (0x90fe37): copy4(T[1],T[2]); copy4(Tcomp[1],Tcomp[2]); *triDim -= 1; return 2
  DROP_T2 (0x90fde1): *triDim -= 1; return 2
```

- In the `b = f32(w2 − W2)` steps the subtraction is `fsubr [mem]`, i.e. `mem − st0` =
  new − saved. In the `a = …` steps it is `fsubp st(2)` = new − saved. PROVEN at 0x90fd42, 0x90fd56,
  0x90fd85, 0x90fd99, 0x90fe06, 0x90fe1a.
- The `(a*X) > (Y*b)` products are register-held (`fmulp`) and compared unrounded (`fcompp`).
- The "drop" comments name the triangle slot that is overwritten by T[2] (or removed, for T2).

---

## 6. FUN_0090e640 (tetra reducer) and FUN_0090e010 (x87; `tr/f_90e640.txt`, `tr/f_90e010.txt`)

```
fn tet(P /*ecx*/, T /*edx*/, sign /*f32 stack*/) -> i32:
  a=f32(T2-T1); b=f32(T0-T2); c=f32(T1-T0); d=f32(T3-T0); e=f32(T3-T1); f=f32(T3-T2)   (xyz)
  n0 = ( f32(e.z*a.y - e.y*a.z), f32(a.z*e.x - e.z*a.x), f32(a.x*e.y - e.x*a.y) )  // a x e : face T1T2T3
  n1 = ( f32(f.z*b.y - f.y*b.z), f32(b.z*f.x - f.z*b.x), f32(b.x*f.y - f.x*b.y) )  // b x f : face T2T0T3
  n2 = ( f32(d.z*c.y - d.y*c.z), f32(c.z*d.x - d.z*c.x), f32(c.x*d.y - d.x*c.y) )  // c x d : face T0T1T3
  r  = ( f32(f32(P.x-T3.x)*sign), f32(f32(P.y-T3.y)*sign), f32(sign*f32(P.z-T3.z)) )
  s0 = f32((n0.x*r.x + n0.y*r.y) + n0.z*r.z)
  s1 = f32((n1.x*r.x + n1.y*r.y) + n1.z*r.z)
  s2 = f32((r.x*n2.x + r.y*n2.y) + r.z*n2.z);   s3 = 0.0
  for i in 0..2:
     q_i = f32(s_i * f32(|s_i|))
     L_i = f32((n_i.x*n_i.x + n_i.y*n_i.y) + n_i.z*n_i.z)
     w_i = (L_i == 0.0) ? f32[0xBEAB40] : f32(q_i / L_i)   // fucom; jnp on eq
  // arg-max (0x90e9cb-0x90ea48): ties and NaN go to the later index
  idx=1, mx=w1, mn=w0;  if w1 < w0 (strict): idx=0, mx=w0, mn=w1
  if !(w2 < mx): second=mx, mx=w2, idx=2
  elif !(w2 < mn): second=w2
  else: second=mn
  if f32[0xB5A398] > mx (strict):  return -1            // mx < 1e-6
  if second * f64[0xB5A390] < mx (strict): return idx    // 1.1 as double, register product
  return FUN_90e010(P, copy(s0,s1,s2,s3), edx=T)
```

Constants (PROVEN, `const_90e640.txt`):
- `[0xBEAB40]` f32 bits 0x7F7FFFEE = 3.4028200e38. This is not exactly FLT_MAX (0x7F7FFFFF).
- `[0xB5A398]` f32 0x358637BE = 1.0000001112e-06.
- `[0xB5A390]` f64 0x3FF19999A0000000 = 1.100000023841858, i.e. (double)1.1f.

```
fn tet_fallback(P, s[4] /*copy*/, T /*edx*/) -> i32:
  for i in 0..3:
     j = tbl572[i] (1,2,0);  k = tbl570[i] (2,0,1)
     if s[j] < 0 or isnan(s[j]): continue          // "0.0 > s" or unordered skips
     if s[k] < 0 or isnan(s[k]): continue
     u = f32(T[j]-T[i]); v = f32(T[k]-T[i]); p = f32(P-T[i]); w = f32(T3-T[i])   (xyz)
     A1 = f32((w.x*v.x + w.y*v.y) + w.z*v.z)
     A2 = f32((p.x*u.x + p.y*u.y) + p.z*u.z)
     B1 = f32((v.x*p.x + v.y*p.y) + p.z*v.z)
     B2 = f32((w.x*u.x + w.y*u.y) + w.z*u.z)
     det = f32(A1*A2 - B1*B2)                       // both products in registers
     if !(det < 0): s[j] = -1.0f  else: s[k] = -1.0f   // f32[0xB12A50]
  if s[0] > 0: return 0                            // strict, ordered
  if s[1] > 0: return 1
  if s[2] > 0: return 2
  return -1
```

INFERRED role: when the clear winner test is inconclusive, the fallback disambiguates which face of
the tetra the point lies outside of. The caller drops the returned vertex and replaces it with
T[3].

---

## 7. FUN_009219b0: segment/segment closest points (x87; `tr/f_9219b0.txt`, listing 0x921a6c–0x921c86 hand-checked)

```
fn segseg(P0, d1, Q0, d2, out) -> i32:
  r = f32(Q0-P0) (xyz)
  b = f32((d1.x*d2.x + d1.y*d2.y) + d1.z*d2.z)
  c = f32((d1.x*r.x + r.y*d1.y) + d1.z*r.z)
  f = f32((r.x*d2.x + r.y*d2.y) + r.z*d2.z)
  a = f32((d1.x*d1.x + d1.y*d1.y) + d1.z*d1.z)
  e = f32((d2.x*d2.x + d2.y*d2.y) + d2.z*d2.z)
  ea = e*a; bb = b*b                               // registers
  D  = f32(|f32(ea - bb)|)
  sN = f32(e*c - f*b)
  if !(sN*D < D*D):          s = 1.0; code = 1    // ordered >=   (0x921abe, test ah,1)
  elif sN <= 0 (ordered):    s = 0.0; code = 2    // 0x921ae0
  else:                                            // sN > 0 or NaN
     T = f32((ea + bb) * f64[0xB57010])            // 2^-20 = 9.5367431640625e-07 (double)
     if T < D (strict):      s = f32(sN / D); code = 0
     else:                   s = 1.0; code = 1     // near-parallel
  tN = f32(s*b - f)
  if !(tN < e) (ordered >=):  t = 1.0; code = 4; RECOMPUTE_S
  elif tN <= 0 (ordered):     t = 0.0; code = 8; RECOMPUTE_S
  else:                       t = f32(tN / e)      // code unchanged
  RECOMPUTE_S:   sN2 = f32(b*t + c)
                 if sN2 <= 0 (ordered):       s = 0.0;           code |= 2
                 elif !(a > sN2) (ordered):   s = 1.0;           code |= 1
                 else:                        s = f32(sN2 / a)
  out[0..3] = (f32(d1.x*s + P0.x), f32(s*d1.y + P0.y), f32(d1.z*s + P0.z), f32(s*d1.w + P0.w))
  Q         = (f32(d2.x*t + Q0.x), f32(t*d2.y + Q0.y), f32(d2.z*t + Q0.z), f32(t*d2.w + Q0.w))
  out[4..7] = f32(out[0..3] - Q)
  out[8]    = f32((out[4]*out[4] + out[5]*out[5]) + out[6]*out[6])
  return code
```

- `code = 4` and `code = 8` **overwrite** the s-phase bits (`mov ebx,4` / `mov ebx,8`), and the
  s recompute then ORs bits 2 or 1 back in (PROVEN 0x921b1d, 0x921b71, 0x921ba1, 0x921bbf).
- The bits as the core uses them: 1 = A end 1 (s=1), 2 = A end 0 (s=0), 4 = B end 1 (t=1),
  8 = B end 0 (t=0).
- INFERRED: this is Ericson-style segment/segment, with r = Q0 − P0 so the signs of c and f are
  flipped relative to the textbook.

---

## 8. Helpers used only for precision bookkeeping

- `_CIsqrt` (0x9ee730): argument and result in st0. Every use in the closure stores its result
  with `fstp dword` before using it (0x912e8a, 0x913106, 0x913821).
- `0x9ee850` is `_alloca_probe` (fork); it does no arithmetic.

---

## 9. Penetration fallback

### 9.1 FUN_009118d0 (x87; `tr/f_9118d0.txt`, `d_9118d0.s`, decomp `out1/d_009118d0.c` for the padding structure)

```
fn penetration(this, shapeA, shapeB, aTb):
  count = 4
  if dimB >= 3:
      if dimB == 3:
          if dimA <= 1: count = 3
          else: copy4(A[3],A[1]); copy4(Braw[3],Braw[0]); copy4(B[3],B[0])
      else: copy4(A[3],A[0])                                   // dimB == 4
      copy4(A[1],A[0]); copy4(A[2],A[0])
  else:
      if dimA < 3: count = 1
      else:
          if dimA == 3:
              if dimB <= 1: count = 3
              else: copy4(A[3],A[0]); copy4(Braw[3],Braw[1]); copy4(B[3],B[1])
          else: copy4(Braw[3],Braw[0]); copy4(B[3],B[0])       // dimA == 4
          copy4(Braw[1],Braw[0]); copy4(B[1],B[0]); copy4(Braw[2],Braw[0]); copy4(B[2],B[0])
  for i < count: M[i] = f32(A[i] - B[i]) (4 lanes, w included)   // 0x911bb0 x4-unrolled + remainder
  ret = FUN_941e10(shapeA, shapeB, aTb, f32[0xB43C58]=9.99999975e-05, &A[0], &Braw[0], M, count, out9)
  if count == 1 or ret == 1:
      dimA = 1; dimB = 1                         // 0x911fc0: B[0] (A space) NOT recomputed
  else:
      dimA = 3; dimB = 3
      id(v) = bits(v.w) & 0xC0FFFFFF
      if id(A1)==id(A2) or id(A0)==id(A2): dimA = 2
      if id(A0)==id(A1): dimA -= 1; copy4(A[0], A[dimA])
      if id(Braw1)==id(Braw2) or id(Braw0)==id(Braw2): dimB -= 1
      if dimB >= 2 and id(Braw0)==id(Braw1): dimB -= 1; copy4(Braw[0], Braw[dimB])
      for i = dimB-1 down to 0:                  // 0x911e8f; matrix copied as ints, c0.z held in st0
          B[i] = ( f32(((y*c1.x + x*c0.x) + z*c2.x) + t.x),
                   f32(((c1.y*y + c0.y*x) + c2.y*z) + t.y),
                   f32(((y*c1.z + x*c0.z) + z*c2.z) + t.z), 0.0 )     // x,y,z from Braw[i]
      if dimA + dimB > 4: FUN_910030(this)
      if dimA == 2 and dimB == 2:
          dA = f32(A1-A0); dB = f32(B1-B0) (4 lanes)
          FUN_9219b0(&A0, &dA, &B0, &dB, &this.+0x130)   // return ignored
  this.n = out9[0..3]                            // 0x911fcd (pop interleaved, offsets checked)
  this.chg = 1
```

- The 0x941e10 subtree writes A[0..2] and Braw[0..2]. 0x940bc0 copies the final face's A/Braw
  into them; the 0x944270 fallback writes A[0] and Braw[0] (fork, `pd/pd_subtree.md` §6, §8).
- **Retail behaviour worth gating.** On the `count == 1 || ret == 1` path, the jumps at
  0x911d15/0x911d1e skip the transform loop at 0x911e04–0x911f12 (PROVEN). So B[0] (+0xA0) is not
  refreshed, and FINISH computes `dist = n·(A0 − B0)` with whatever B[0] holds. Whether Braw[0] has
  changed by then depends on how 0x941e10 exited (PROVEN by grep, `pd_check.txt`, `pd_check2.txt`):
  - `ret == 1` (fallback 0x944270): Braw[0] **is** rewritten (0x944798–0x9447bf store through
    `[ebp+0x18]` = Braw), so B0 is stale. PROVEN.
  - `count == 1` with ret 0 or 2, when 0x940bc0 runs (0x941df3): it rewrites A/Braw[0..2]
    (0x940c91–0x940cbf through ctx+0x60/+0x64), so B0 is stale. PROVEN.
  - `count == 1` through 0x941c50's early `return res` (0x941c89 → 0x941df8, skips 0x940bc0): only
    0x940980 appends at index `count` (0x9409ad/0x9409c9), so B0 is stale only if the append
    targets index 0. That depends on 0x940f50's case path (`pd/epa_growth.md`).
- The fallback's own distance (out9+0x20) is never read by the core.

### 9.2 FUN_00910030: reduce to at most 4 points (x87; `tr/f_910030.txt`, `d_910030.s`)

```
if dimB == 3:
    for i in 0..dimA-1:
        if classify(this, &A[i], B, 0) == 0xE: copy4(A[0], A[i]); dimA = 1; return
if dimA == 3:
    for j in 0..dimB-1:
        if classify(this, &B[j], A, 0) == 0xE: copy4(Braw[0],Braw[j]); copy4(B[0],B[j]); dimB = 1; return
best = f32[0xBEAB40]; bi = 0; bj = 0
nA = (dimA == 3) ? 3 : 1;  nB = (dimB == 3) ? 3 : 1
for i in 0..nA-1:
  for j in 0..nB-1:
    dA = f32(A[tbl572[i]] - A[i]) (4 lanes);  dB = f32(B[tbl572[j]] - B[j]) (4 lanes)
    FUN_9219b0(&A[i], &dA, &B[j], &dB, buf)
    if best > buf[8] (strict, ordered): best = buf[8]; bi = i; bj = j
if nA == 3: dimA -= 1; copy4(A[tbl570[bi]], A[dimA])
if nB == 3: dimB -= 1; copy4(Braw[tbl570[bj]], Braw[dimB]); copy4(B[tbl570[bj]], B[dimB])
```

- With nA = 1 (dimA ≠ 3) the edge used is A[1] − A[0] (tbl572[0] = 1). INFERRED: this is only
  meaningful for dimA = 2. Reaching here needs dimA + dimB > 4 after the dedupe, so dims are
  (3,3), (3,2) or (2,3).
- The A companion array is not touched here.

### 9.3 FUN_00941e10 subtree (summary of `gsk/pd/pd_subtree.md` plus three follow-up transcriptions)

The full port-ready pseudocode is split across four files. Each was walked against its listing,
and each overrides the mechanical traces where it says so.

| file | covers |
|---|---|
| `gsk/pd/pd_subtree.md` | entry, driver, layouts, leaves 0x940820/0x940980/0x9407b0/0x9409f0/0x940bc0/0x41bc80/0x9426a0 |
| `gsk/pd/epa_growth.md` | 0x940f50 growth paths 0x9414dd–0x941761 and 0x941766–0x941839, 0x940e40, 0x42c800 |
| `gsk/pd/epa_horizon.md` | 0x942630, 0x942570, 0x943660, 0x943730, 0x943b30, 0x944040 |
| `gsk/pd/epa_fallback.md` | 0x944270, 0x944090, 0x9223c0, the 0x941c50 perturbation block |

Settled in this run:
- 0x9434e0 face plane (PROVEN, `tr/pd_9434e0.txt`):
  - `n = (f32(q.z*p.y − q.y*p.z), f32(p.z*q.x − q.z*p.x), f32(p.x*q.y − q.x*p.y))`, where
    `p = f32(v0−v1)` and `q = f32(v1−v2)`.
  - `s = (L==0) ? 0 : f32(1/f32(_CIsqrt(L)))`, then `n = f32(n*s)` and `n.w = f32(s*f64 0.0)`.
  - `d = f32((n.y*v0.y + n.x*v0.x) + n.z*v0.z)`.
- 0x944270's axis loop runs 3 times (PROVEN: 0x944294 `mov [esp+0x18],3`; 0x944315 `sub`; 0x94431a `jne`).

Corrections the follow-ups made to `pd_subtree.md`; the follow-up files take precedence:
- `[0xBEAB40]` = 0x7F7FFFEE and `[0xB11AD8]` = 0xFF7FFFEE. Neither is ±FLT_MAX.
- vrec+0x30 is the horizon-link pointer.
- 0x943660 returns only 0 or 2.
- 0x943b30's `cmp edi,3` counts the edges of one face.
- There is no x87 depth 6 across the calls in 0x944270.
- The `[esp+0x1c]` w-lane addend at 0x941db6 is a never-written local lane. ctx t.w is read only
  at 0x9412b1 (`dir.w = −t.w`), and from there it can reach `this.n.w` via 0x911fec.

The core's own result does not depend on the EPA distance: FINISH recomputes `dist` from A0/B0
(§3.8). That makes moot the budget-exit out.dist = −3.4e38 that `epa_horizon.md` reports as INFERRED.

Earlier fork summary:

PROVEN by the fork:
- **Entry.** 0x941e10 builds a ctx (aTb copy, eps×4, eps², shapes, vertex arrays, count) and calls
  the driver 0x941c50. If the driver returns 3, it runs the direction-sampling fallback 0x944270 and
  returns 1. Otherwise it returns the driver's 0 or 2.
- **Driver 0x941c50.**
  - 0x940f50 repairs or grows the initial simplex.
  - The EPA loop repeats: 0x9426a0 picks the minimum-d face, 0x940820 gets the Minkowski support,
    0x9409f0 expands the polytope.
  - The polytope is capped at 55 vertices; reaching the cap returns 2.
  - 0x940bc0 extracts the result over up to 10 faces, using barycentrics from 0x9223c0.
  - Retries: attempt 1 keeps only M[0]. Attempts 2–19 nudge the translation with an LCG
    (0x9407b0). Attempt 20 returns 3.
- **out9 layout:** normal (4 floats), point on A (4 floats), distance (f32) at +0x20.
- **Monitor records:** `TlsGetValue` rdtsc timing records only, with no arithmetic effect.
- **Fully traced arithmetic:** 0x940820, 0x940980, 0x9407b0, 0x9409f0, 0x940bc0, 0x41bc80 (SSE) and
  0x9426a0. Everything else in the subtree is described at the role level only (see §12).

---

## 10. Precision: where register precision matters (INFERRED analysis of PROVEN sites)

The x87 precision-control (PC) field in effect when this code runs is **NOT DETERMINED**. Nothing
in the closure sets it.

INFERRED (recall):
- D3D9 sets 24-bit PC on the device-creating thread unless `D3DCREATE_FPU_PRESERVE` is passed.
- The MSVC CRT default for new threads is 53-bit.
- Which thread runs this code is not known.

What the PC can and cannot affect:
1. **One operation on f32 operands, then a `fstp dword`** (e.g. `f32(A0.x − B0.x)`,
   `f32(dt*f32(|dt|))`, `f32(1/f32(sqrt))`). The result is the correctly rounded f32 under any PC,
   because double rounding through 53 or 64 bits is innocuous for + − × ÷ √ when p′ ≥ 2p+2
   (INFERRED, recall of Figueroa's result). Exponent-range differences (x87 registers keep a 15-bit
   exponent even under PC=24) matter only near overflow or underflow.
2. **Chains held in registers before one store.** These depend on PC: every 3-term dot product,
   every `a*b − c*d` cross term, the prologue and accept transforms, `f32(e*c − f*b)`,
   `f32(A1*A2 − B1*B2)` and `f32(ea − bb)`.
3. **Comparisons of unrounded register values.** These also depend on PC:
   - 0x9129f0: `d·|d|` vs `L·eps`
   - 0x90ea6b: `second·1.1` (f64 constant) vs `max`
   - 0x921abe: `sN·D` vs `D·D`
   - 0x90fd66, 0x90fda9, 0x90fe2a: the `(a·W) > (W·b)` tests
   - 0x90fb04: compares two f32 values (exact)
   - The support acceptance tests (0x912b04 etc.) compare two f32 values and are exact.

Port recipe:
- Model "register" arithmetic as a type parameter. PC=24 means f32 operations; PC=53 means f64
  operations rounded to f32 only at the `f32()` points; PC=64 needs 80-bit emulation.
- Pick the PC by gating against captures.

**w-lane vertex ids.** Every vertex move is `fld dword`/`fstp dword` (`copy4`), and the core also
computes with w lanes: n.w = f32(A0.w − B0.w) in PT_PT, −n.w goes into the A support direction,
and M[i].w is built in 0x9118d0.
- INFERRED (SDM recall): `fld` of a signalling-NaN bit pattern raises #IA (masked) and stores back
  the quieted pattern. Every other f32 bit pattern, denormals included, survives the copy unchanged.
- Recommendation: a Rust port copies raw bits for `copy4` unless a capture shows quieting. The
  dedupe masks `bits & 0xC0FFFFFF` and so reads the bits as integers.

---

## 11. Constants and tables used by this closure (PROVEN, `consts.txt`, `const_*.txt`; type = operand size of the loading instruction)

| addr | type | bits | value | used at |
|---|---|---|---|---|
| 0xB5A3B8 | f32 | 0x2EDBE6FF | 1.000000013351432e-10 | 0x91227b (eps₀) |
| 0xB12A50 | f32 | 0xBF800000 | −1.0 | 0x91271e (TET_PT sign), 0x90e198/0x90e19d |
| 0xBEAA2C | f32 | 0x80000000 | −0.0 | 0x90e53b (n.w on flip) |
| 0xBEAB40 | f32 | 0x7F7FFFEE | 3.4028200e+38 | 0x90e92e, 0x9100a5 |
| 0xB5A398 | f32 | 0x358637BE | 1.0000001112e-06 | 0x90ea4a |
| 0xB5A390 | f64 | 0x3FF19999A0000000 | 1.100000023841858 | 0x90ea65 |
| 0xB57010 | f64 | 0x3EB0000000000000 | 9.5367431640625e-07 (2⁻²⁰) | 0x921b34 |
| 0xB11AD0 | f32 | 0x00000000 | 0.0 | 0x90fc35 |
| 0xB43C58 | f32 | 0x38D1B717 | 9.99999975e-05 | 0x911cdb (eps to 0x941e10; fork) |
| 0x245D664 | u32 | 1 | 1 | 0x476d31 (0x90fe80 only) |
| 0xB5A560 | i8[16] | | −1,−1,2,−1,1,−1,−8,−1,0,−1,−7,−1,−6,−1,−1,−1 | 0x9124e0, 0x912773 |
| 0xB5A570 | i8[3] | | 2,0,1 | 0x9124ef, 0x912782, 0x90e02d, 0x910296, 0x9102d3 |
| 0xB5A572 | i8[3] | | 1,2,0 | 0x9124f8, 0x91278b, 0x90e023, 0x910103, 0x91013a |
| 0x91394C | u8[25] | | §3.2 | 0x9122d0 |
| 0x913920 | u32[11] | | §3.2 | 0x9122d7 |

---

## 12. NOT DETERMINED (and what was tried)

1. **x87 precision-control word at run time** (§10).
   - Tried: corpus searches "x87 FPU control word precision D3DCREATE_FPU_PRESERVE" and
     "IDirect3D9 CreateDevice BehaviorFlags call site" (no relevant hit); the memory
     `crossover-sampler-corrupts-x87.md` (about x87 stack corruption, not PC); a grep for
     `fldcw/fnstcw/fninit` in every closure listing (none).
   - Not tried: locating the CreateDevice call and its behaviour flags, and reading the control
     word on the physics thread in a capture.
2. **Whether shapeA/shapeB `vtable+0x30` ignore the direction's w lane, and what they return in
   w.** The callee is virtual; the convex-hull and triangle implementations were not traced.
   Callee-pops-8 is INFERRED from the caller's stack use.
3. **fld/fstp treatment of id bit patterns that are signalling NaNs.** INFERRED from the SDM, not
   run.
4. **Remaining open items in the 0x941e10 subtree.** Every function in it now has pseudocode
   (§9.3). Still open:
   - The run-time content of the stale stack lane added to t.w at 0x941db6 (attempt 2 onward), and
     whether it changes any number. It reaches only case-0 `dir.w` and `out.n.w`.
   - The stale vrec+0x30 copied by 0x42c800.
   - The best record of 0x944090 if no candidate ever passes `best.val < val`.
   - The run-time .data values at 0xBF65A0–0xBF65DC.
   - Whether 0x943730 can be called with cnt == 0.
   - Which cap exit (face budget or 55 vertices) fires first.
   - Tried: per-function store and reference greps, listed in those files.
7. **Cache dims (2,3)/(3,2) at entry**, the only route that reads the uninitialised lastB, n and
   W (§2). Not tried: tracing 0x90fe80's write-back and the cache initialisation.
8. **Shape support (vtable+0x30) implementations.** Not located or traced. This leaves open which
   lanes they read (w, and the −0.0 lanes) and how many bytes they write.
5. **0x90fe80** (the caller's write-back) is out of scope and was not traced, beyond identifying
   its 0x476d31 hop.
6. **dimB = 0 or dimA = 0 entry.** The prologue would transform index −1 and the dispatch would go
   to FAIL (idx < 0 as u32 > 24). Whether the caller can pass 0 was not checked.
