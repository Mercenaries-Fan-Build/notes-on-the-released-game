# EPA horizon walk and new-face construction (pc-v10): 0x942630, 0x942570, 0x943660, 0x943730, 0x943b30, 0x944040

Binary: `n2/mercs2_n2patched2.exe` (restored copy). Listings: `gsk/pd/f_<va>.s`. Traces: `gsk/tr/pd_<va>.txt`.
Notation and x87 semantics: `gsk/gsk_core.md` §0. `f32(x)` = value rounded by an `fst/fstp dword`;
anything else is an x87 register value whose rounding depends on the precision-control word (NOT
DETERMINED, `pd_subtree.md` §10.2). Grades: PROVEN (cited instruction / file:line), INFERRED,
SPECULATIVE, NOT DETERMINED.

Extra artefacts made for this note (all under `gsk/pd/`):
`epa_horizon_consts.txt` (peread of every constant), `epa2_constbits.txt` (bit-level checks of the
constants), `epa2_gap_9439c0.s` / `epa2_gap_944060.s` (raw bytes of the two listing gaps: both are
`8d 49 00 lea ecx,[ecx]` padding that is jumped over, never executed), `epa2_9ee730.s`
(`jmp [0xb053ac]`), `epa2_callers.txt`, `epa2_flagwrites.txt`, `epa2_9423c0_edi.txt`.

---

## 0. Corrections to `pd_subtree.md` §3/§7/§9 (PROVEN, cited below)

1. `[0xbeab40]` is **not FLT_MAX**. Bytes `ee ff 7f 7f` = bits `0x7f7fffee` = 3.402820018375656e38
   (`epa_horizon_consts.txt:4`, `epa2_constbits.txt:6`; FLT_MAX is 0x7f7fffff = 3.4028234663852886e38).
   A port must use `f32::from_bits(0x7f7fffee)`.
2. 0x943660 never tests return code 3. Its compares are `cmp eax,1` (9436a1), `cmp ebp,2` (9436c2),
   `cmp eax,4` (9436c9), `cmp eax,2` (9436ce). Face flag value 3 is written only by 0x943b30 (943b5d).
3. 0x943b30 is not "at most 3 neighbours": `cmp edi,3` (943c60) counts the 3 edges of the current
   face; the face-to-face walk is bounded only by the flag-3 marking (§6).
4. `vrec+0x30` is not just an int flag: 0x943660 stores a half-edge pointer there (9436dd) and
   0x943730 reads and clears it (943982/943985) — it is the horizon "link" of a vertex.
5. `f64[0xb5ab30]` is not a widened f32: it equals bit-exactly `-(f64(f32(1e-5)))²`
   (bits 0xbddb7cdfc28ae400, `epa2_constbits.txt:1-2`). `0xb5aa08` and `0xb59c18` are widened f32
   (`epa2_constbits.txt:7-8`).

## 1. Structures touched (offsets PROVEN by the cited stores/loads)

**poly** (ecx of 0x942630/0x943660/0x943730/0x943b30/0x944040):

| off | type | meaning | writers / readers in scope |
|---|---|---|---|
| +0x00 | f32 | `tol`, visibility tolerance | set to f32[0xb5aa30] by 942655 on every 0x942630 call; raised by 9425f2 |
| +0x04 | f32 | `minv`, min distance over faces found visible | set to f32[0xbeab40] by 942661 on every 0x942630 call; lowered by 9425dd |
| +0x08 | i32 | nv, vertex count | read 9439c3, 944063 |
| +0x0c | i32 | removed-face count (stack top) | ++ 943719; -- 94375f; reset to 0 by 942566 (edi=0, 9423e2) |
| +0x10 | i32 | nf, face slots in use | read 94377b, 9439a4, 944042; written 9437a6; set 4 by 943a2e |
| +0x20+0x40·i | vrec | +0x00 M, +0x10 A, +0x20 B, **+0x30 link** (half-edge*, 0 = none) | |
| +0xde0+4·k | face* | removed-face stack | push 943712; pop 94375d |
| +0xf70+0x50·j | face | | |

Capacities (INFERRED from offset arithmetic + guards, no check in the six functions):
- 55 vrecs exactly fill +0x20..+0xde0 (0x20+0x40·55 = 0xde0); 0x941c50 stops at nv ≥ 55 (941cf4).
- The removed stack +0xde0..+0xf70 holds 0x190/4 = 100 pointers.
- Face budget guard in 0x9409f0 (940b55–940b64, PROVEN): continue only if
  `removed − nf + 100 ≥ cnt` (signed `jge`), i.e. `nf + (cnt − removed) ≤ 100`. It runs after
  0x942630 (so `removed` already includes the faces just removed) and before 0x943730.
- 0x943730's local new-face array at `[esp+0x50]` (after 3 pushes) = aligned-frame +0x44..+0x1d4 =
  0x190 bytes = 100 pointers. `cnt ≤ 100` is implied by the budget guard since `removed ≤ nf`.

**face** (0x50 B): +0x00 n (4 f32), half-edges he0/he1/he2 at +0x10/+0x20/+0x30, each
`{+0 vrec* (origin), +4 next*, +8 twin*, +0xc face*}`, +0x40 d (f32), +0x44 flag (i32).
"vrec = origin vertex" is INFERRED from the consistency of the twin wiring in 0x943730 (§5.3).

**Face flag +0x44 vocabulary** (PROVEN writers):
- 0 unvisited — cleared by 943a54 (faces 0..3, in 0x943a10), by the 0x943730 tail loop
  (9439b0, faces 0..nf−1, only on its two normal exits), and by 0x944040 (944050).
- 1 visible (will be / has been removed) — `rc` of 0x942570 stored by 942673 / 9436a4.
- 2 not visible — same stores.
- 4 conflict — same stores.
- 3 visited by 0x943b30's face walk — 943b5d.

## 2. FUN_00942630 — horizon walk seed (PROVEN, `f_942630.s`, `tr/pd_942630.txt`)

Signature: thiscall `ecx = poly`; args `(face* seed, vrec* v, int* cnt, halfedge** list)`; `ret 0x10`;
eax = status. Arg mapping: ebx=[esp+0x14]=list (942637), ebp=[esp+0x14]=cnt (94263c), edi=face
(942644), vrec loaded at 942663/942678. Only direct caller: 0x9409f0 at 940b35.

Caller evidence for all six functions (`epa2_xrefs_scan.txt`): a byte scan of the whole `.text`
for `E8`/`E9` rel32 to each VA, every 4-byte window of `.text` holding the VA as an absolute
dword, and every aligned dword of `.rdata`/`.data`. Hits are only: 0x942630 ← 940b35;
0x942570 ← 94266b, 94369c; 0x943660 ← 942682, 9436bb; 0x943730 ← 940b86; 0x943b30 ← 940c78;
0x944040 ← 943b3c. No pointer to any of them exists, so no indirect caller through a stored
address (PROVEN for the file bytes; a computed address would not be found by this scan).

```
*list = 0; *cnt = 0                                   ; 942648, 94264e
poly.tol  = f32[0xb5aa30]                             ; 942655   (1.0000000116860974e-07)
poly.minv = f32[0xbeab40]                             ; 942661   (bits 0x7f7fffee)
rc = seed.FUN_942570(v, poly, &poly.minv)             ; 94266b (ecx = seed face)
seed.flag = rc                                        ; 942673
if rc != 1: return 2                                  ; 942676 -> 94268e
return poly.FUN_943660(seed, v, cnt, list)            ; 942682, eax passed through
```
Returns: 0 = walk completed; 2 = seed not visible (rc 2), seed conflict (rc 4), or conflict found
during the walk (0x943660 → 2). 0x9409f0 maps any nonzero to res=3 (940b3a–940b41, PROVEN).
When rc ≠ 1 the seed face is not pushed on the removed stack and its d is unchanged (no store on
that path, PROVEN).

## 3. FUN_00942570 — visibility test of v against one face (PROVEN, `f_942570.s`, `tr/pd_942570.txt`)

Signature: thiscall `ecx = face`; args `(vrec* v, poly* tolp /*reads/writes +0 only*/, f32* minv)`;
`ret 0xc`; eax ∈ {1, 2, 4}. (`[ebp+8]`=v 942579, `[ebp+0xc]`=tolp 9425b6, `[ebp+0x10]`=minv 942584.)

```
v0 = face.he0.vrec                                    ; 94257c  [ecx+0x10]
w.x = f32(v.M.x − v0.M.x)                             ; 94257f-942587
w.y = f32(v.M.y − v0.M.y)                             ; 94258b-942591
w.z = f32(v.M.z − v0.M.z)                             ; 942595-9425a0
dist = f32( (n.y*w.y + n.x*w.x) + n.z*w.z )           ; 9425a4-9425bf, n = face+0/+4/+8
                                                      ;   (fld n.y; fmul w.y; fld n.x; fmul w.x; faddp; fld n.z; fmul w.z; faddp)
code = 1                                              ; 942598
if tol < dist (strict, ordered):                      ; 9425c9 fcomp, test ah,5; jp 9425e1 taken on eq/gt/un
    if minv > dist (strict, ordered):                 ; 9425d4, test ah,0x41; jne 942604 taken on lt/eq/un
        *minv = dist                                  ; 9425dd (stores the reloaded f32, exact)
else:                                                 ; dist <= tol, or dist/tol NaN
    t9 = dist + f64[0xb5aa08]                         ; 9425e1, register value, NOT stored before compare
    if tol < t9 (strict, ordered):                    ; 9425e9, test ah,5; jp 9425fb taken on eq/gt/un
        tol = f32(t9)                                 ; 9425f2
    code = 2                                          ; 9425f4 / 9425fd
if minv <= tol (ordered: lt or eq):                   ; 942606-942616: fld tol; fld minv; fcompp; test ah,0x41; jnp
    return 4                                          ; 942611
return code                                           ; 942618
```
NaN: a NaN `dist` takes the else branch (unordered), t9 is NaN, `tol < t9` is false, tol unchanged,
code 2 (PROVEN from the branch decode). The final `minv <= tol` is false when unordered.

Meaning (INFERRED from the code): 1 = v strictly above the face plane by more than `tol`
("visible"); 2 = not visible, and `tol` is raised to `dist + 1e-7` if that is larger; 4 = the
invariant `minv > tol` is broken — some face already accepted as visible is now within the raised
tolerance, so the visible/not-visible split is inconsistent. Since every 4 aborts the walk (§2, §4),
and on the visible path `minv` only drops to a `dist > tol`, a 4 can only arise on the not-visible
path after `tol` is raised (INFERRED).

Note: `dist` here is the x87 recomputation; 0x9409f0's convergence test uses the SSE distance of
0x41bc80 (`pd_subtree.md` §6), which rounds every product and sum to f32. They are different values.

## 4. FUN_00943660 — recursive depth-first visibility flood (PROVEN, `f_943660.s`, `tr/pd_943660.txt`)

Signature: thiscall `ecx = poly`; args `(face* f, vrec* v, int* cnt, halfedge** list)`; `ret 0x10`;
eax ∈ {0, 2}. Caller: 0x942630 (942682) and itself (9436bb). Precondition: `f.flag == 1` already.

```
ret = 0                                               ; 943669 (ebp)
for i in 0..2:                                        ; counter [esp+0x14], 9436e5-9436f8 (jl)
    h  = f.he[i].twin                                 ; p = f+0x18+0x10*i (94366c, 9436e9); edi = *p
    g  = h.face                                       ; 943686 [edi+0xc]
    fl = g.flag                                       ; 943689
    if fl == 0:                                       ; 94368c/94368e
        fl = g.FUN_942570(v, poly, &poly.minv)        ; 94369c
        g.flag = fl                                   ; 9436a4 (before any recursion)
        if fl == 1:
            ret = poly.FUN_943660(g, v, cnt, list)    ; 9436bb
            if ret == 2: break                        ; 9436c2/9436c5 -> 943701
            continue                                  ; 9436c7
        if fl == 4: ret = 2; break                    ; 9436c9/9436cc -> 9436fc
    if fl == 2:                                       ; 9436ce (both fresh and pre-set flags)
        h.vrec.link = h                               ; 9436d3/9436dd  [[edi]+0x30] = edi
        *cnt += 1                                     ; 9436e0
        *list = h                                     ; 9436e3
    ; pre-set fl == 1, 3 or 4: nothing
f.d = f32[0xbeab40]                                   ; 943705/94370b (bits 0x7f7fffee)
poly.removed[poly.nremoved] = f; poly.nremoved += 1   ; 94370e-943719
return ret
```
- Termination (PROVEN from the flag discipline): a face's flag is set nonzero (9436a4, or 942673
  for the seed) before the recursive call on it, and recursion happens only on a face whose flag was
  0, so each face is entered at most once; depth ≤ number of visible faces ≤ nf ≤ 100 (INFERRED
  bound). The loop always runs to its end unless a 2 is seen.
- Return codes: 0 = this subtree finished without conflict; 2 = a 0x942570 call in this subtree
  returned 4 (directly, 9436fc, or propagated, 9436c5). ebp is only ever 0 or the callee's value,
  which by induction is 0 or 2 (PROVEN).
- Every visited (visible) face is removed even on the abort path: the epilogue at 943701 runs on all
  exits (PROVEN). Removal order is post-order of the DFS.
- Horizon edges recorded = every twin half-edge `h` (owned by a not-visible face g) across an edge of
  a visible face, in DFS order: edges 0,1,2 of each face, recursing into a visible neighbour before
  moving to the next edge. `*list` ends as the **last** recorded horizon edge; `*cnt` is their count.
  `link[h.vrec] = h` (vertex → horizon edge starting there). Two horizon edges starting at the same
  vertex would overwrite the link (PROVEN store semantics; consequence in §5.4 INFERRED).

## 5. FUN_00943730 — build the cone of new faces (PROVEN, `f_943730.s`; trace `tr/pd_943730.txt` only up to its line 119)

Signature: thiscall `ecx = poly`; args `(int cnt, halfedge* h0, vrec* v)`; `ret 0xc`; eax ∈ {0, 2}.
Caller: 0x9409f0 (940b86) with `(cnt, *list, v)` (pushes 940b81–940b83).

### 5.1 Slot allocation (943739–9437a6)
```
k = 0; top = poly.nremoved − 1
if cnt != 0:
    while cnt' > 0 and top >= 0:                      ; 943759 test edx; jl; 943773 test eax; jne
        newf[k++] = poly.removed[top]; poly.nremoved -= 1; top -= 1; cnt' -= 1     ; LIFO pop
    if cnt' > 0:                                      ; 943777
        for r in 0..cnt'−1: newf[k++] = &poly.face[poly.nf + r]                    ; ascending
        poly.nf += cnt'                               ; 9437a6
```
(`cnt'` is a working copy of cnt in eax; `[ebp+8]` keeps cnt.)

### 5.2 Per-edge face construction (9437a9–943993)
```
h = h0                                                ; 9437a9/9437b1 (esi = ebx = h0)
if cnt <= 0: goto tail                                ; 9437b3 (no fldz on this path)
push 0.0 (x87, kept under everything in the loop)     ; 9437b9
for k in 0..cnt−1:
    if h == NULL: pop x87; return 2                   ; 9437bb/9437bd -> 9439f7 (flags/links NOT cleared)
    F  = newf[k];  NF = newf[k+1] if k+1 < cnt else newf[0]       ; 9437c3-9437e1
    F.he0.face = F.he1.face = F.he2.face = F         ; 9437e5-9437eb
    F.he1.next = &F.he2; F.he2.next = &F.he0; F.he0.next = &F.he1  ; 9437f1, 9437f7, 9437fd
    A = h.next.vrec;  B = h.vrec;  C = v              ; 943800-943805, 943809
    F.he0.vrec = A; F.he2.vrec = C; F.he1.vrec = B    ; 943807, 94380c, 94380e
    h.twin = &F.he0;  F.he0.twin = h                  ; 943814, 94381b
    NF.he1.twin = &F.he2;  F.he2.twin = &NF.he1       ; 94381e, 943827
    ; plane (inline copy of 0x9434e0's arithmetic, except the zero case):
    e1 = f32(A.M − B.M) (x,y,z)                       ; 94382a-943842
    e2 = f32(B.M − C.M) (x,y,z)                       ; 943846-94385e
    n.x = f32(e2.z*e1.y − e2.y*e1.z)                  ; 943862-943882 (fsubrp: st0 − st1 = P1 − P2)
    n.y = f32(e1.z*e2.x − e2.z*e1.x)                  ; 943886-94389c
    n.z = f32(e1.x*e2.y − e2.x*e1.y)                  ; 9438a0-9438a6
    L   = f32((n.x*n.x + n.y*n.y) + n.z*n.z)          ; 9438aa-9438c8 (stored f32 n reloaded)
    if L == 0.0 (fucom, ordered eq only):             ; 9438d2/9438db test ah,0x44; jnp 9439f5
        pop x87 ×2; return 2                          ; 9439f5, 9439f8 (flags/links NOT cleared)
    s = f32( 1.0 / f32(_CIsqrt(L)) )                  ; 9438f6-943909 (fld1; fdivrp = 1/q)
    n.x = f32(s*n.x); n.y = f32(s*n.y); n.z = f32(s*n.z)   ; 943917-943935
    n.w = f32(s * f64[0xbea968] /*0.0*/)              ; 943939-94393f
    F.d = f32( (A.M.y*n.y + A.M.x*n.x) + n.z*A.M.z )  ; 943943-943969 (n = the stored f32 values)
    F.n = (n.x, n.y, n.z, n.w)                        ; 94396e-94397a (reloaded f32, exact copies)
    nxt = h.next.vrec;  h = nxt.link;  nxt.link = 0   ; 94397d-943985
tail:
pop x87                                               ; 94399c (loop path only)
for j in 0..poly.nf−1: face[j].flag = 0               ; 9439a2-9439bf (+0xfb4 stride 0x50)
for i in 0..poly.nv−1: vrec[i].link = 0               ; 9439c1-9439df (+0x50 stride 0x40)
return (h0 != h) ? 2 : 0                              ; 9439e1-9439e7: sub; neg; sbb; and 2
```
- Second zero test: 9438e1 re-stores the same f32 L and 9438eb/9438f4 tests the same predicate
  (`L == 0`) on it, so the branch to 943911 (s = 0) is unreachable once 9438db fell through
  (PROVEN). The port has exactly two outcomes: `L == 0.0` → return 2; anything else, NaN included,
  normalises. This differs from 0x9434e0, which continues with scale 0 (`tr/pd_9434e0.txt:42-49`).
- Trace caveat: `tr/pd_943730.txt` lines 120–139 carry s = 0.0 from the dead 943911 path (join at
  943917); the live path above was read from the listing by hand (x87 stack: `[Z]` before 9438cc;
  `[L,Z]` after 9438d6; 9438f6 `fstp st(1)` leaves `[L]`; sqrt; store; `fld1; fdivrp`; store;
  `fldz` at 94390d restores `[Z]`).
- Cross product: n = e1 × e2 = (A−B) × (B−C), i.e. (v0−v1)×(v1−v2) with (v0,v1,v2) = (he0,he1,he2)
  origins; same operand order and association as 0x9434e0 (`tr/pd_9434e0.txt:19-40`, PROVEN by
  comparing t7..t20 in both traces). The d association `(y + x) + z` also matches
  (`tr/pd_9434e0.txt:61-65`; additions commute, association identical).
- Multiplication operand order inside each product is irrelevant (IEEE commutative); subtraction
  order is as written.

### 5.3 Wiring meaning (INFERRED from 5.2)
New face k = (h.next.v, h.v, v) for the k-th horizon edge `h` of the walk h0, link[h0.next.v], ….
he0 runs h.next.v → h.v (reverse of h, and h.twin is set to it), he1 runs h.v → v, he2 runs
v → h.next.v; F.he2 is twinned with NF.he1 (NF's he1 runs h'.v → v with h'.v = h.next.v),
which is consistent only if half-edge `vrec` is the origin vertex. Each new face's 12 half-edge
fields are all rewritten (he1.twin of F is written in the iteration for the previous face, and for
newf[0] in the last iteration), so a reused slot carries no stale pointers. F.flag is not written
in the loop; the tail clears it on both normal exits.

### 5.4 Return codes
- 0: either cnt == 0 (no faces built, nothing popped; INFERRED reachable only if every face was
  visible), or after `cnt` steps the link walk is back at h0.
- 2: a degenerate new face (`L == 0.0`), a missing link (`h == NULL`), or the walk does not close
  after cnt steps. 0x9409f0 maps 2 to res=3 (940b8d–940b92, PROVEN). A horizon that touches itself
  at a vertex (link overwritten, §4) would give one of the last two (INFERRED).

## 6. FUN_00943b30 — next face for the extraction loop (PROVEN, `f_943b30.s`, `tr/pd_943b30.txt`)

Signature: thiscall `ecx = poly`; arg `(face* S)`; `ret 4`; eax = face*. Caller: 0x940bc0 at 940c78,
up to 10 times, each time with the face it got last (940c74–940c85).

```
poly.FUN_944040()                                     ; 943b3c (all flags and links -> 0)
K = f64[0xb5ab30]  (= -(f32(1e-5))², x87 register)    ; 943b41
cur = S; skip = NULL; done = false                    ; 943b47-943b4e
loop:                                                 ; 943b52
    if done: return cur                               ; 943b57 -> 943c88
    cur.flag = 3                                      ; 943b5d
    for i in 0..2:                                    ; 943b64, 943c5a-943c63
        he = &cur.he[i]
        if he == skip: continue                       ; 943b69/943b6b (pointer compare)
        P0 = he.vrec.M;  P1 = he.next.vrec.M          ; 943b71-943b76
        e  = f32(P1 − P0) (x,y,z)                     ; 943b78-943b90
        c.x = f32(e.y*n.z − n.y*e.z)                  ; 943b94-943bac  (n = cur.n; c = e × n)
        c.y = f32(n.x*e.z − e.x*n.z)                  ; 943bb0-943bc1  (fsubp: st(2) − st0)
        c.z = f32(n.y*e.x − n.x*e.y)                  ; 943bc5-943bd0
        q   = f32((c.x*P0.x + c.y*P0.y) + P0.z*c.z)   ; 943bd4-943bec
        sq  = q * f32(|q|)                            ; 943bf0-943bfc, register value (signed square)
        L   = f32((e.x*e.x + e.y*e.y) + e.z*e.z)      ; 943c00-943c14 (e from the f32 stores)
        r   = f32(L * K)                              ; 943c18-943c1e
        if !(r > sq): continue                        ; 943c26 fcompp, test ah,0x41; jne on lt/eq/un
        G = he.twin.face                              ; 943c2f/943c32
        if 0.0 < S.d (strict, ordered):               ; 943c38 fcom [S+0x40]; test ah,5; jp 943c6b on eq/gt/un
            if S.d * f64[0xb59c18] > G.d (strict, ordered): continue   ; 943c45-943c58, jne 943c6b on lt/eq/un
        ; take this edge                              ; 943c6b
        done = (G.flag == 3)                          ; 943c70/943c7a (sete)
        skip = cur.he[i].twin                         ; 943c74 (ecx still = cur)
        cur  = G                                      ; 943c78
        goto loop                                     ; 943c7f/943c82 (edi < 3 here, always jne)
    return cur                                        ; no edge taken: 943c69 -> 943c7f (edi == 3) -> 943c88
```
- `S` in the d test is the face passed in (`[ebp+8]`, 943c35/943c42), not `cur` (PROVEN).
- Edge test meaning (INFERRED): with K = −(1e-5)², `r > sq` ⇔ `q·|q| < −1e-10·|e|²` ⇔ `q < 0` and
  `|q|/|e| > 1e-5` (up to rounding), where `−q/|e| = (e×n)·(0−P0)/|e|` is the signed in-plane
  distance of the origin beyond the edge line. So the walk crosses an edge the origin lies outside
  of by more than 1e-5, into the neighbour, provided the neighbour's d is not below 0.9·S.d (when
  S.d > 0). The first qualifying edge (in order he0, he1, he2) wins; there is no best-edge choice.
- Return: the first face with no qualifying edge, or the first face re-entered (flag already 3).
  It can return S itself (PROVEN path: no edge qualifies on the first face). Termination: every
  entered face gets flag 3 before its edges are scanned, and entering a flag-3 face ends the walk,
  so at most nf faces are entered (PROVEN mechanism; bound INFERRED).
- x87 stack: `[Z=0.0, K]` live across the whole walk (943b41/943b4a), popped at 943c89/943c8c.
- Flags 3 persist after return; the next 0x943b30 call clears them via 0x944040.

## 7. FUN_00944040 — clear flags and links (PROVEN, `f_944040.s`, `epa2_gap_944060.s`)

thiscall `ecx = poly`, no args, plain `ret`.
```
for j in 0..poly.nf−1: face[j].flag = 0               ; 944042-94405f (+0xfb4, stride 0x50)
for i in 0..poly.nv−1: vrec[i].link = 0               ; 944061-94407f (+0x50, stride 0x40)
```
Identical to the 0x943730 tail (9439a2–9439df). Covers removed face slots too (they are < nf).

## 8. State left behind on failure, and what resets it

Failure paths: 0x942630 → 2 (seed not removed if rc ≠ 1; otherwise faces already removed and
flagged); 0x943660 → 2 (faces removed, flags 1/2/4 set, links set); 0x943730 → 2 at 9439f5/9439f7
(faces partly rebuilt, nremoved/nf already changed, flags and links not cleared); 0x943730 → 2 at
9439e7 (flags/links cleared). Every one leads to res=3 in 0x9409f0 (940b41, 940b92), and
0x941c50 then perturbs and reruns 0x940f50 → 0x9423c0 (`pd_subtree.md` §5). The rebuild resets
(PROVEN): nv = 4 (9423cb); vrec[0..3].link = 0 (94241b, 942472, 9424e7, 942555, edi = 0 from
9423e2); nf = 4 (943a2e); face[0..3].flag = 0 (943a54); nremoved = 0 (942566); each new vrec's link
= 0 at allocation (941ccc, 941d18); tol/minv reset at every 0x942630 entry (942655, 942661).
0x9426a0 scans faces 0..nf−1 only (its bound is `[poly+0x10]`, 9426af, PROVEN), so removed slots
stay inside the scan and are excluded only by their d = 3.402820018e38. INFERRED conclusion: no
horizon state survives into the next attempt.

**Two exits that are NOT retries and go straight to extraction** (PROVEN control flow,
`f_941c50.s` 941cf0–941df3): 0x941c50 calls `0x940bc0(&poly, edi, out)` at 941de7–941df3, where
`edi` is the face passed to the last 0x9409f0 call (941d12/941d2a).
- **Budget exit, res = 2** (940b64): reached only after 0x942630 returned 0, so the full walk ran.
  The seed face `edi` and every other visible face already have d = bits 0x7f7fffee and sit on the
  removed stack; flags 1/2 and vrec links are set; the horizon twins still point into removed faces
  because 0x943730 never ran. 0x943b30 clears flags/links (0x944040) but not the d values or the
  twins. With S = the seed, `0.0 < S.d` holds and `S.d·0.9 > G.d` rejects every live neighbour
  (any finite d below 3.06e38), so the walk can only move between removed faces (INFERRED from §6).
  If 0x940bc0 accepts such a face, `out.dist = −face.d = −3.402820018375656e38` (INFERRED, via
  `pd_subtree.md` §6 `out.dist = −face.d`, not re-read here). Flag for the parent: this is the
  value a port must reproduce on that path.
- **Vertex-cap exit, st = 2** (941cf4 `nv ≥ 55` → 941de2): `edi` is the previous step's seed, whose
  0x9409f0 returned 0 (0x943730 succeeded). The seed was the DFS root, pushed last on the removed
  stack (§4 epilogue runs after all recursive calls), so 0x943730 popped it first and rebuilt it as
  new face 0 on h0 (§5.1, LIFO). Extraction therefore starts from new face 0, a live face that is
  not in general the min-d face (mechanism PROVEN; "not the min-d face" INFERRED).
- Which exit fires first near the caps (INFERRED, recall): a closed triangulated polytope with V
  vertices has 2V − 4 faces, which reaches 100 at V = 52, so the face-budget exit is likely to fire
  before nv ≥ 55. Not measured.

## 9. Face index order (decides 0x9426a0's first-minimum tie-break)

PROVEN from §4/§5: (a) visible faces are pushed on the removed stack in DFS post-order;
(b) new faces take removed slots LIFO from the top, then fresh slots nf, nf+1, … ascending;
(c) new face k is built on the k-th edge of the link walk starting at h0 = the **last** horizon
edge recorded by the DFS. A port must reproduce all three to keep face indices, and therefore ties
in the min-d scan, identical.

## 10. Constants (PROVEN, `epa_horizon_consts.txt`; size from the instruction)

| addr | size (instr) | bits | value | use |
|---|---|---|---|---|
| 0xb5aa30 | f32 (`fld dword` 942630) | 0x33d6bf95 | 1.0000000116860974e-07 | initial tol |
| 0xbeab40 | f32 (`fld dword` 942657, 943705) | 0x7f7fffee | 3.402820018375656e38 (not FLT_MAX) | initial minv; removed-face d |
| 0xb5aa08 | f64 (`fadd qword` 9425e1) | 0x3e7ad7f2a0000000 | 1.0000000116860974e-07 (= widened f32 1e-7) | tol raise |
| 0xbea968 | f64 (`fmul qword` 943939) | 0 | +0.0 | n.w = s·0.0 |
| 0xb5ab30 | f64 (`fld qword` 943b41) | 0xbddb7cdfc28ae400 | −9.99999949475751e-11 = −(f64 f32(1e-5))² exactly | edge test |
| 0xb59c18 | f64 (`fmul qword` 943c4b) | 0x3feccccc_c0000000 | 0.8999999761581421 (= widened f32 0.9) | neighbour d ratio |
| 0xb053ac | IAT (`jmp [ ]` 9ee730) | — | MSVCR80 `_CIsqrt` (`pd_subtree.md` §1) | sqrt at 9438f8 |

## 11. Comparisons whose outcome depends on the precision-control word

All other compares in scope compare two f32-stored values (precision-independent). These compare
an unrounded register value:
- 942570: `tol < t9`, t9 = dist + f64 1e-7 (9425e9). The stored tol is then f32(t9).
- 943b30: `r > sq` with sq = q·|q| (943c26; a product of two f32 is exact in 53- or 64-bit
  precision, rounded in 24-bit precision).
- 943b30: `S.d · 0.8999999761581421` vs `G.d` (943c51).
- 943730 / 943b30 / 942570 f32 results computed from register sums/products (n, L, d, dist, q, e×n):
  each is a single f32 rounding of a register expression of ≤ 3 terms, whose value can differ
  from an all-f32 evaluation when the PC word is 53/64-bit (double rounding is possible).

## 12. NOT DETERMINED

1. **x87 precision-control word** — shared with `pd_subtree.md` §10.2. Nothing in these six
   functions executes `fldcw`/`fninit` (`pd/sse_grep.txt`, `pd_subtree.md` §1). Decides §11.
2. **`_CIsqrt` internals** — INFERRED (recall) to be `fsqrt` on st0 under the current PC word; not
   disassembled here (it lives in MSVCR80, outside the exe). Tried: only the IAT slot resolution.
3. **Reachability of cnt == 0 in 0x943730** (every face visible) — the code path is PROVEN, whether
   EPA input can produce it is not; not tested.
4. **Exact role of the 0.9·S.d neighbour gate and of starting from the extraction face in 0x943b30**
   — the arithmetic is PROVEN, the intent (stay on near-closest faces) is INFERRED only.
