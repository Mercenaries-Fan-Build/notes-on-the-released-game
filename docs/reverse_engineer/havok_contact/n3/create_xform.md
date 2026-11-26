# N3/create — vertex-buffer transforms, GSK-cache create helpers, FUN_0090BE70 (pc-v10)

Sources (all in this folder): listings `d_901510.s`, `d_92a270.s`, `d_92ab20.s`, `d_92a8f0.s`, `d_901380.s`,
`d_918580.s` (objdump Intel, from `n2/mercs2_n2patched2.exe`, sha256 359c996a…, `sha.txt`), `d_90be70_orig.s` (from
the original `mercs2_unpacked.exe`, sha256 8c179a99…). Tracer runs `tr_*.txt` (`n2/gsk/x87sym.py`). Bytes check
`bytes.txt`, splice gadget `gadget_54efb2.s`.
Mnemonic semantics: LLVM prints the SDM names (`de e1` = `fsubrp st(1),st` = st1 := st0 − st1; N2 `fsubdiv_summary.txt`).
Precision: register ops at the FPU precision (53-bit per the port rule, observed FCW 0x027F per N2 §9 — INFERRED for
the step itself); every product here is of two f32 values, so it is exact; only sums round in-register; f32 rounding
happens only at the `fstp/fst dword` listed.

Notation: `T` = 16 f32 at a transform pointer, column-major: `T[0..2]` = R col0 (x,y,z), `T[4..6]` = col1,
`T[8..10]` = col2, `T[12..14]` = translation. `X(v) = f32( ((v.y*T[4] + v.x*T[0]) + v.z*T[8]) + T[12] )`,
`Y(v) = f32( ((v.y*T[5] + v.x*T[1]) + v.z*T[9]) + T[13] )`, `Z(v) = f32( ((v.y*T[6] + v.x*T[2]) + v.z*T[10]) + T[14] )`.
(Operand order inside one add is irrelevant — IEEE add is commutative; association is what the port must keep.)

## A. Manifold-refresh vertex buffer — PROVEN (hand trace + tracer agree)

### A.1 FUN_00901510 (buffer base = esp+0x60 after the prologue; ebx = arg0 = process input; esi = arg2+0xC = manifold)
- 0x9016A2–0x9016FB, in this order: `tol = f32[[arg0+8]+4]` → buf+0x118 (fstp 0x9016AD); `rA = f32[[[arg0]]+0x10]`
  → buf+0x110 (0x9016C7); `rB = f32[[[arg0+4]]+0x10]` → buf+0x114 (0x9016D5);
  `s = f32((rA + tol) + rB)` (fld 0x9016DC, fadd 0x9016E3, fadd 0x9016EA, **single** fstp 0x9016F1 to a temp);
  `sq = f32(s*s)` (reload s, `fmul st0,st0`, fstp 0x9016FB) → buf+0x11C. `tr_901510_pre.txt`.
- +0x100 normal: 4 f32 copied by fld/fstp (0x901702–0x90172A) from arg3 (`[ebp+0x14]`), whose w was overwritten at
  0x901695 by `f32[arg0+0x50]` on the refresh path (st1 after the `fcomp` at 0x90167B).
- A vertices: `shapeA->vt[0x34](ids = man + 4 + 8*man.np, n = man.nA, out = buf)` (thiscall, 0x901731–0x90173C;
  shapeA = [cdBodyA], cdBodyA = [arg0]). Transform = 16 dwords at `[cdBodyA+8]`, copied by integer moves
  (0x901742–0x9017B9). Loop 0x9017CD–0x901850: i = nA−1 down to 0 (do-while, `sub ecx,1; test; jge`), in place:
  load x, y, z of buf[i] (f32 round trip, exact), then stores in this order:
  `buf[i].x = X` (0x901814), `buf[i].y = Y` (0x901831), `buf[i].z = Z` (0x901848), `buf[i].w = +0.0f`
  (`fst` of the `fldz` from 0x901745, at 0x90184D).
- B vertices: `shapeB->vt[0x34](ids + 2*nA, man.nB, buf + 16*nA)` (0x901856–0x901880). Transform = `[cdBodyB+8]`,
  cdBodyB = [arg0+4] (0x901882–0x901903). Loop 0x901914–0x901995: i = nB−1 down to 0, same X, Y, Z formulas
  (0x90195B, 0x901976, 0x90198D), then `w = +0.0f` via `fldz; fstp` (0x901990/0x901992).
- Then `FUN_00916360(man, buf, 0, arg4, [arg0+0xC])` (0x9019A5–0x9019AF).
- Loop guard: both loops are entered only when `man.np != 0` (0x901698), not on nA/nB; a do-while with nA = 0 would
  write buf[−1]. INFERRED: nA, nB ≥ 1 whenever np ≥ 1 (each point references ≥1 vertex of each body).

### A.2 FUN_0092A270 (buffer base = esp+0xB0; esi = arg0; ebx = arg4 = manifold)
- Same values and order: tol 0x92A3ED (+0x118), rA 0x92A3FF (+0x110), rB 0x92A40D (+0x114), `s` one fstp 0x92A429,
  `sq` 0x92A433 (+0x11C).
- +0x100 normal = fld/fstp copy (0x92A43A–0x92A45F) of the 16 bytes at esp+0x70, which were integer-copied from
  arg5 (`[ebp+0x1C]`) at 0x92A30E–0x92A32C **and** passed by address to `shapeB->vt[0x38]` at 0x92A341–0x92A379 when
  `shapeB+0xC == 4` — so on that path the buffer normal is whatever that call left (INFERRED: it may modify it).
- Gate: this whole block (tol/rA/rB/sq, normal copy, both conversions and loops, the FUN_00916360 call at 0x92A705)
  runs only when `man.np > idx`, idx = byte returned by `FUN_00914800(man, cache)` (0x92A3AE; `cmp edi,ecx; jle
  0x92A714` at 0x92A3C8–0x92A3D2). Given that, the `test al,al; je 0x92A6F2` at 0x92A466 (np == 0) is never taken.
  A port must gate on `np > idx`, not `np != 0`.
- A/B conversions and loops 0x92A46C–0x92A6E5. Transforms `[cdBodyA+8]`
  (0x92A48E–0x92A492) and `[cdBodyB+8]` (0x92A5D6–0x92A5DA). Stores 0x92A567/0x92A584/0x92A59B/`fst` w 0x92A5A0 (A),
  0x92A6AB/0x92A6C6/0x92A6DD/`fldz;fstp` 0x92A6E2 (B). **Identical association to FUN_00901510 in all six loops**
  (`tr_901510_A/B.txt`, `tr_92a270_A/B.txt`).

## B. Create: FUN_00901380 → FUN_0092AB20 / FUN_0092A8F0 — PROVEN unless graded

### B.0 FUN_00901380 (cdecl, `ret`) — 0x901380–0x9013D7
Args (a0 = agent/process struct, a1, a2 = cache). Calls `helper(this = a2; shapeA = [[a0]], shapeB = [[a0+4]],
T = a0+0x10)`; helper is thiscall, `ret 0xC`. Choice: `shapeB+0xC == 4` → 0x92AB20 else 0x92A8F0. After: `byte a1[2] = 0`;
`cache[+0xB] &= 0xEF`; `dword cache[+0xC] = 0` (manifold nA, nB, np, pad); returns
`cache + (((b[+0xC] + 4*b[+0xE] + b[+0xD])*2 + 0x1F) & ~0xF)` = **cache + 0x10** (those bytes were just zeroed).
T maps B-local points into A-local space — INFERRED, evidence: (a) FUN_00901510 transforms `vt[0x34]` output by
`[cdBody+8]` to build world-space vertices, so `vt[0x34]` returns body-local coordinates, and here T·b0 is subtracted
from shapeA's `vt[0x34]` output; (b) the corpus decomp of FUN_008CE990 builds the same third argument from
`FUN_008933D0(cdA+8, cdB+8)`. All "A-local"/"B-local" labels below inherit this grade (the arithmetic is PROVEN).

### B.1 FUN_0092AB20 (triangle B) — 0x92AB20–0x92AE0F; this = cache (edi)
1. If `byte shapeB[+0x17] != 0`: tail-call `0x92A8F0(shapeA, shapeB, T)` same this; return. (Recall, INFERRED:
   +0x17 = hkpTriangleShape::m_isExtruded.)
2. `ids[1..3] = 0, 1, 2` (u16 at +2/+4/+6).
3. `v_k = (X,Y,Z)(tri_k)` with T, tri_k = f32x3 at shapeB+0x20+0x10*k, loop k = 2,1,0 (0x92ABEA–0x92AC6E), stored to
   O+0x70+16k (O = esp after prologue), w = +0.0f (`fst` 0x92AC6B). Same association as A (`tr_92ab20_loop.txt`).
4. Edges, stores in order (0x92AC79–0x92ACE2): `e0.x = f32(v1.x−v0.x)`, e0.y, e0.z (O+0x30..38);
   `e1.x = f32(v2.x−v1.x)`, e1.y, e1.z (O+0x20..28).
5. `n = e0 × e1` (0x92ACE6–0x92AD2E): `n.x = f32(e0.y*e1.z − e0.z*e1.y)`, `n.y = f32(e0.z*e1.x − e1.z*e0.x)`,
   `n.z = f32(e0.x*e1.y − e1.x*e0.y)`, `n.w = +0.0f` (O+0x10..1C). Each = one in-register subtraction of two exact
   products, one f32 rounding.
6. `a0 = shapeA->vt[0x34](&ids[1] (= id 0), 1, out O+0x30)` (0x92AD32): A's vertex id 0, A-local.
7. `d = f32(a0 − v0)` per lane x,y,z (0x92AD34–0x92AD54);
   `dot = f32((d.y*n.y + n.x*d.x) + d.z*n.z)` (0x92AD58–0x92AD74).
8. Sign: all four lanes of n `^= (bits(dot) & 0x80000000)` (0x92AD8C–0x92ADBE): n is negated (incl. w → −0.0) when dot
   has its sign bit set (dot < 0 or −0.0). Result n' satisfies n'·(a0 − v0) ≥ 0.
9. `shapeA->vt[0x30](dir = &n' (A-local), out = O+0xA0)` (0x92ADD6) — direction **not** negated, no transform.
10. `ids[0] = u16 at out+0xC` (support vertex w-lane low 16 bits; 0x92ADD8). `dimA = 1`, `dimB = 3`.
    `cA = shapeA->vt[0x24]()`; `+0xA = ((cA > 3 ? 0xF : cA) & 0xF) | 0x30`; `+0xB = 0`.

### B.2 FUN_0092A8F0 (generic / extruded) — 0x92A8F0–0x92AB18; this = cache; L = esp after `push edi`
The SecuROM splice at 0x92A914 (`jmp [0x024555A0]`) executes the gadget 0x54EFB2 `mov dword [esp+0x18],0; jmp
0x92A91C` (N2 resolve + `gadget_54efb2.s`), i.e. the id word at L+0xC = 0.
1. `a0 = shapeA->vt[0x34](&id0, 1, L+0x40)`; `b0 = shapeB->vt[0x34](&id0, 1, L+0x50)` (vertex id 0 of each, local).
2. `p = (X,Y,Z)(b0)` with T (0x92A937–0x92A9A3) → L+0x20..28 (association as above; no w store).
3. `dA = f32(p − a0)` x,y,z; `dA.w = f32(0 − a0.w)` (0x92A9A7–0x92A9D3) → L+0x10.
4. `sA = shapeA->vt[0x30](dir = &dA (A-local), out L+0x30)` (0x92A9DD).
5. `e = f32(p − sA)` x,y,z, `e.w = f32(0 − sA.w)` (0x92A9DF–0x92AA15) → L+0x10.
6. `f.x = f32((e.x*T[0] + e.y*T[1]) + e.z*T[2])`, `f.y = f32((e.x*T[4] + e.y*T[5]) + e.z*T[6])`,
   `f.z = f32((e.x*T[8] + e.y*T[9]) + e.z*T[10])` (Rᵀ·e, 0x92AA19–0x92AA7B), then `fchs` each (exact negation)
   and `f.w = f32[0xBEAA2C] = −0.0` (bytes 00000080). So `dB = −Rᵀ(p − sA)`, B-local.
7. `sB = shapeB->vt[0x30](&dB, out L+0x60)` (0x92AAA7).
8. `ids[0] = u16 sA+0xC`, `ids[1] = u16 sB+0xC`, `ids[2] = ids[3] = 0`, `dimA = dimB = 1`;
   `cA = shapeA->vt[0x24]()`, `cB = shapeB->vt[0x24]()`; low nibble of +0xA = (cA>3?0xF:cA), high = (cB>3?0xF:cB);
   `+0xB = 0`.

## C. FUN_0090BE70 — PROVEN (`d_90be70_orig.s`, call sites `g_be70_sites.txt`)
`__thiscall dst(ecx) ← src([esp+4])`, `ret 4`, returns eax = dst. Copies 0x24 bytes: 8 f32 by `fld/fstp` (+0..+0x1C:
position xyzw, normal xyzw of a contact entry, the layout written at 0x92A716–0x92A761) and the u32 at +0x20 (the
contact-point id) by integer move. No arithmetic. Numbers are unchanged except that an x87 `fld m32` of a signalling
NaN stores back as the quiet NaN (INFERRED, SDM recall).
Sites in FUN_00918580 (cdecl, 10 args, arg7 = base of this manifold's 0x30-stride contact entries, arg6 = the new one):
- 0x918681 (addContactPoint returned 0xFFFF): `entry[k] ← entry[3]` (src arg7+0x90), then return 6 (caller
  0x92A8A5 pulls the write pointer back 0x30): swap-remove.
- 0x9186A9: `new.id = id; entry[k] ← new` (src arg6); caller 0x92A8B3 then points at entry[k].

## Corrections to N2 `convex_triangle.md`
1. §2.5 / §11-2: transform order is `((v.y*R1 + v.x*R0) + v.z*R2) + t` per lane, not `((t + z·R2) + x·R0) + y·R1`.
2. §2.5: `sq = f32(s²)`, `s = f32((rA + tol) + rB)` with **no** f32 rounding of `rA + tol` (one fstp at 0x9016F1).
3. §2.5: in FUN_0092A270 the +0x100 normal is the arg5 copy that may have passed through `shapeB->vt[0x38]`.
4. §2.3: create writes `+0xB = 0` (whole byte), and 0x901380 zeroes the whole manifold dword +0xC; maxB is fixed 3 on the triangle path.
5. §5.4 / §11-7: FUN_0090BE70 is a 0x24-byte contact-entry copy (thiscall). Listing: dst = ecx in both calls;
   src = `[esp+0x38]+0x90` = arg7 + 0x90 (push at 0x91867E) and `[esp+0x34]` = arg6 (push at 0x9186A8). Neither a
   "4" nor a return address is passed.
6. §11-6 closed by B.1/B.2.
7. §2.3 "maxB 0xF = extruded triangles via 0x92A8F0": now PROVEN for hkpTriangleShape (vtable 0xB57B34, N2
   `vt_tricoll.txt`): its vt[0x24] = 0x8AAA30 returns `3*(byte[this+0x17] + 1)` (`d_8aaa30.s`), i.e. 3 or 6; 6 > 3 → 0xF.
   The same byte +0x17 is the 0x92AB20 tail-call test.

## Provenance and tracer caveats
- `bytecmp.py` → `bytecmp.txt`: every analysed range of the patched exe equals `mercs2_unpacked.exe` except
  0x92A276–0x92A27B and 0x92A914–0x92A91B (the two applied one-instruction gadgets). The 0x92A914 gadget body was read
  from the original exe (`gadget_54efb2.s`); 0x92A276 is `sub esp,0x1C4` (N2 `resolve_region.txt`, gadget 0x50A0B2).
- `tr_92a8f0.txt`: S = L+0x74 (the tracer does not model `and esp,-0x10`).
- `tr_92ab20_post.txt` / `tr_92a8f0.txt`: loads right after a call (0x92AD34–0x92AD54, 0x92A9DF–0x92AA15) carry stale
  pre-call labels such as `[S+0x30]@92ac92`; those slots hold the callee outputs (a0, sA) as written above.
