# Simplex growth paths of FUN_00940f50, FUN_00940e40 and FUN_0042c800 (pc-v10), port-ready

Binary: `n2/mercs2_n2patched2.exe`. Notation and x87 operand semantics are those of `gsk/gsk_core.md` §0:
- `f32(x)` marks an `fst/fstp dword`, which rounds to binary32.
- Unwrapped arithmetic stays in an x87 register. Its significand precision is set by the
  precision-control word, which is NOT DETERMINED (gsk_core §10, pd_subtree §10.2).

Grades:
- **PROVEN** means read this run from the listing or a mechanical trace, cited by VA or file:line.
- **INFERRED** means reasoned from proven facts, or recalled. Recalled facts are marked "(recall)".
- **SPECULATIVE** means a guess.

## 0. Sources, frames and method

**Listings:**
- `pd/f_940f50_full.s`: lines 411–627 hold 0x9414dd–0x941761, lines 628–702 hold 0x941766–0x941839.
- `pd/f_940e40.s`, `pd/f_42c800.s`, `pd/f_940820.s`, `pd/f_940980.s`.

**Traces:**
- `tr/pd_940f50_full.txt` (lines 220–370) and `tr/pd_940e40.txt`, both pre-existing.
- New traces from this run, each with an explicit entry stack:
  - `tr/epa1_seg.txt`: `x87sym_pd.py f_940f50_full.s 0x9414dd 0x941766 --entry Z --pop 941704=16 --pop 941721=16 --pop 941744=4 --pop 94175a=4`
  - `tr/epa1_tri.txt`: `... 0x941766 0x94183e --entry NX,NZ,NY,Z --pop 94180f=16 --pop 941832=4`
  - `tr/epa1_seg_sqrtjoin.txt`: `... 0x941611 0x94163e --entry Q,Z,UY,UZ,UX`, which isolates the sqrt predecessor of the 0x94164a join.
  - `tr/epa1_tri_sqrtjoin.txt`: `... 0x941796 0x9417c1 --entry Q,NX,NZ,NY,Z`, which isolates the sqrt predecessor of the 0x9417cb join.

**Frame of 0x940f50.**
- `F` = esp after the three pushes at 0x940f5c/0x940f5d/0x940f69, and every `F+x` below is
  relative to it. ebp is the entry esp − 4, before `and esp,-0x10`. `[ebp+8]` = out, `[ebp+0xc]` = &res.
- In `tr/pd_940f50_full.txt`, `S−k` = `F + (0x1b4 − k)`. For example `[esp+0x14]` = `S−0x1a0`
  (0x941219 STORE) and `[esp+0x50]` = `S−0x164` (0x9414ef STORE).
- In the `tr/epa1_*` traces, `S` = `F`.

**Frame of 0x940e40.** `G` = esp after the pushes of ebx/esi/edi at 0x940e49/0x940e4a/0x940e50.
In `tr/pd_940e40.txt`, `S−k` = `G + (0x84 − k)`.

**Hand-correction rule.** The tracer names memory by linear order, so every join and every
indexed store below was re-walked by hand from the listing. Where a trace line is wrong, §1.4
says so. Every other arithmetic line agrees with the traces.

**ctx fields used** (layout PROVEN in pd_subtree §3): `+0x40` eps.x, `+0x50` eps2 = f32(eps·eps),
`+0x68` M* (the GJK points `p_i = M[i]`, 16-byte stride), `+0x6c` count. The A* (`+0x60`) and
Braw* (`+0x64`) arrays are written only through 0x940980.

**vrec** (0x40 bytes): `+0x00` M (4 f32), `+0x10` supportA (4 f32), `+0x20` supportB (4 f32),
`+0x30` int flag.

## 1. Segment growth: 0x9414dd–0x941761 (case 2, segment not degenerate)

### 1.1 Entry (PROVEN)

- The only predecessor is `jne 0x9414dd` at 0x94122b. `tr/epa1_preds.txt` lists every jump to
  these targets in the whole listing.
- The branch is taken when `fcompp` of `eps2` against `L2 = f32((e.y² + e.x²) + e.z²)` (0x941219)
  gives lt or un. The test is `test ah,1; jne`. So the entry condition is
  `eps2 < L2 || unordered(eps2, L2)`.
  - L2 is built from `p0 − p1` exactly as `e` is built below, 3 lanes, at 0x9411cb–0x941217.
- x87 stack at entry: `{Z}`, with Z = +0.0 from an `fldz`. Hand walk 0x9411cb–0x941224; it
  agrees with `tr/pd_940f50_full.txt:220`.
- `ctx.count == 2` on entry. It is set at 0x9411c8, or reached through jump-table slot 2, or
  through the `fldz; jmp 0x9411cb` at 0x9414c0 and 0x9414d6 after 0x940980 has incremented it.
  Table check: `pd/epa_growth_consts.txt`, where 0x941c3c holds 0x9411cb.
- Case 1 (0x941247) is entered with count == 1 in all three ways:
  - jump-table slot 1 (0x941245);
  - `mov [esi+0x6c],1` at 0x941240;
  - case 0's 0x940980 append (0→1, count set to 0 at 0x941282 or table slot 0), followed by
    `jmp 0x941247` at 0x941379.

  The append at 0x9414bb or 0x9414d1 therefore leaves count == 2. This is PROVEN from those VAs.

### 1.2 Pseudocode (all PROVEN unless marked; VA of each store given)

```
ebx = 2                                              ; 0x9414e2 (level marker, see pd_subtree §6)
p0 = ctx.M[0]; p1 = ctx.M[1]                         ; edi = [esi+0x68]
e.x = f32(p0.x - p1.x)   -> F+0x50                   ; 0x9414ef
e.y = f32(p0.y - p1.y)   -> F+0x54                   ; 0x9414f9
e.z = f32(p0.z - p1.z)   -> F+0x58                   ; 0x941503
e.w = f32(p0.w - p1.w)   -> F+0x5c                   ; 0x94150d  (DEAD: never read; see 1.5)
ax = f32(|e.x|) -> F+0x14 ; ay = f32(|e.y|) -> F+0xa8 ; az = f32(|e.z|) -> F+0x4c
                                                     ; 0x941519/0x941521, 0x94152d/0x941535, 0x941544/0x94154c
                                                     ; fabs then store, so every one is exact

; --- axis selection, 0x941550..0x941582 ---
if ax > ay:                 ; fcomp ax vs ay (0x94155b), test ah,0x41; jne 0x94156f NOT taken only on gt
    big = 0 ; small = 1 ; m = ay      ; 0x941564 stores ay into F+0x14, ecx=0, edx=1
else:                       ; lt, eq, un
    big = 1 ; small = 0 ; m = ax      ; ecx=1 (0x9414ec), edx=0 (0x9414ea); F+0x14 keeps ax
if m > az:                  ; fcompp m vs az (0x941579), test ah,0x41; je 0x941584 taken only on gt
    k = small               ; edx unchanged
else:                       ; lt, eq, un
    k = 2                   ; 0x941582 mov edx,ebx (=2)
; ecx = big, edx = k  (they are never equal: big is in {0,1}, k is in {other of 0/1, 2})

; --- raw perpendicular u, 0x941584..0x9415a4 ---
u = (+0.0, +0.0, +0.0, +0.0)      -> F+0x20..0x2c    ; fst Z at 0x941586/0x94158a/0x94158e/0x941592
u[big] = e[k]                                        ; 0x941596 fld [F+0x50+4*edx] / 0x94159a fstp [F+0x20+4*ecx]
u[k]   = -e[big]                                     ; 0x94159e fld [F+0x50+4*ecx]; fchs; 0x9415a4 fstp [F+0x20+4*edx]

; --- c = e x u_raw (u NOT yet normalised), 0x9415a8..0x9415e2 ---
c.x = f32( e.y*u.z - u.y*e.z )    -> F+0x60          ; 0x9415bc  (e.y,e.z: registers loaded from F+0x54/F+0x58)
c.y = f32( e.z*u.x - u.z*e.x )    -> F+0x64          ; 0x9415d0
c.z = f32( e.x*u.y - e.y*u.x )    -> F+0x68          ; 0x9415e2  (e.y re-read from memory F+0x54 at 0x9415d8)
                                                     ; each one is (product1 - product2) in registers, then one f32 store

; --- normalise u, 0x9415e6..0x941670 ---
q1 = f32( (u.y*u.y + u.x*u.x) + u.z*u.z )  -> F+0x1c ; 0x9415fc
if q1 == 0.0:               ; fucom q1 vs Z (0x941606), test ah,0x44; jnp 0x94163e taken only on eq
    s1 = 0.0                ; 0x941640 fst Z into F+0x14
else:                       ; lt, gt, un  (NaN takes the sqrt path)
    r  = f32( _CIsqrt(q1) )          -> F+0x1c       ; call 0x9ee730, 0x94161e
    s1 = f32( 1.0 / r )              -> F+0x14       ; fld1; fdivrp st(1),st = st0/st1 = 1/r; 0x94162a
u.x = f32(u.x*s1)  -> F+0x20      ; 0x941654
u.y = f32(u.y*s1)  -> F+0x24      ; 0x94165e
u.z = f32(u.z*s1)  -> F+0x28      ; 0x941668
u.w = f32(s1 * u.w_mem)  -> F+0x2c ; 0x94166c fmul dword [F+0x2c] (= f32 +0.0 from 0x941586), 0x941670

; --- normalise c, 0x941674..0x941700 ---
q2 = f32( (c.y*c.y + c.x*c.x) + c.z*c.z )  -> F+0x1c ; 0x941690
if q2 == 0.0:   s2 = 0.0                             ; jnp 0x9416ba taken only on eq (0x9416a3); 0x9416bc stores Z
else:           s2 = f32( 1.0 / f32(_CIsqrt(q2)) )   ; 0x9416ac, 0x9416b6, 0x9416bc
c.x = f32(s2*c.x)                 -> F+0x60          ; 0x9416df
c.y = f32(c.y*s2)                 -> F+0x64          ; 0x9416ec
c.z = f32(c.z*s2)                 -> F+0x68          ; 0x9416f6
c.w = f32(s2 * f64[0xbea968])     -> F+0x6c          ; 0x9416fa fmul QWORD (+0.0), 0x941700

; --- two support probes, both relative to p0 ---
FUN_940e40(dir=&u (F+0x20), ref=&ctx.M[0], vrec=V1 (F+0x170), &d1 (F+0xac))   ; call 0x941704
FUN_940e40(dir=&c (F+0x60), ref=&ctx.M[0], vrec=V2 (F+0x130), &d2 (F+0x7c))   ; call 0x941721
if d2 >= d1 or unordered:   ; fcompp d2 vs d1 (0x941731), test ah,0x05; jp 0x941750 taken on eq/gt/un
    FUN_940980(V2)          ; 0x94175a
else:                       ; lt (d2 < d1, ordered)
    FUN_940980(V1)          ; 0x941744
push fldz; goto 0x9410cc    ; case 3 body (0x941749/0x94175f fldz; 0x94174b/0x941761 jmp). count is now 3
                            ; (via 0x940980); ebx = 2
```

### 1.3 Call arguments (PROVEN by hand esp arithmetic; the callee pops 0x10, `ret 0x10` at 0x940f3a/0x940f48)

| call | push order (first → last) | resulting args (arg1 = last push) |
|---|---|---|
| 0x941704 | `edx=lea[esp+0xac]` with esp=F → F+0xac; `eax=lea[esp+0x174]` with esp=F−4 → F+0x170; `edi`=ctx.M; `ecx=lea[esp+0x2c]` with esp=F−0xc → F+0x20 | dir=u F+0x20, ref=M[0], vrec=F+0x170, dist=F+0xac |
| 0x941721 | `edx=lea[esp+0x7c]` with esp=F → F+0x7c; `eax=lea[esp+0x134]` with esp=F−4 → F+0x130; `ecx`=ctx.M (reloaded at 0x941709); `edx=lea[esp+0x6c]` with esp=F−0xc → F+0x60 | dir=c F+0x60, ref=M[0], vrec=F+0x130, dist=F+0x7c |
| 0x941744 / 0x94175a | `lea [esp+0x170]` / `lea [esp+0x130]` with esp=F | 0x940980(vrec), `ret 4` |

The stores that fill u and c happen between the pushes. Their esp-relative offsets were adjusted:
for example 0x9416df `fstp [esp+0x6c]` runs at esp=F−0xc, so it writes F+0x60, and 0x941700
`fstp [esp+0x7c]` runs at esp=F−0x10, so it writes F+0x6c. The clean trace `tr/epa1_seg.txt:88-95`
agrees.

### 1.4 Corrections to the mechanical traces (PROVEN by hand walk)

- **Indexed stores.** `tr/epa1_seg.txt:35-51` and `tr/pd_940f50_full.txt:255-272` name u's
  lanes `@941592/@94158e/@94158a/@941586`, which are the +0.0 stores. The stores at 0x94159a and
  0x9415a4 (`[esp+4*ecx+0x20]`, `[esp+4*edx+0x20]`) overwrite two of those lanes first.
  - The c and q1 lines must therefore use the u of §1.2.
  - The loads at 0x9415a8, 0x9415b0, 0x9415c0, 0x9415e6–0x9415ea go to memory or are fld copies
    of those reloads. All of them follow the indexed stores.
- **Join at 0x941571.** The value compared with az is F+0x14. On the 0x94156f edge it is ax
  (store 0x941521); on the fall-through it is ay (store 0x941564). The traces name only @941564.
- **Join at 0x94164a.** The traces carry `s1 = f32(Z)` (store 0x941640) into the u scaling. The
  sqrt predecessor stores `f32(1/r)` at 0x94162a (`tr/epa1_seg_sqrtjoin.txt:4`).
  - Both predecessors reach 0x94164a with the stack `{Z, u.x, u.z, u.y}`.
  - Sqrt edge: reloads at 0x94162e–0x94163a (`epa1_seg_sqrtjoin.txt:6`). Eq edge: fxch chain at
    0x94163e–0x941648. Both checked by hand.
  - So 0x94164a reloads s1 from F+0x14 on both edges.
- **Join at 0x9416bc.** Same situation for s2. The stack is `{s2}` on both edges; the eq edge
  carries Z.

### 1.5 Exits, ctx writes, dead values (PROVEN)

- There is no return from this range: both edges go to case 3 at 0x9410cc.
- No write reaches out (`[ebp+8]`) or res (`[ebp+0xc]`).
- The only ctx writes are those of 0x940980 (§4).
- `e.w` (F+0x5c, 0x94150d) is dead within the range. The only reads of the e array are indexed
  with `edx ≤ 2` or `ecx ≤ 1`, or direct reads of F+0x50/0x54/0x58. A grep of the full listing
  for `[esp + 0x5c]` finds only the stores at 0x94150d and 0x94191d (`pd/epa1_preds.txt`).

### 1.6 What the selection means (INFERRED)

- k (= edx) is the lane that receives `−e[big]`; it is not the zero lane. The lane left at +0.0
  is `z_lane = 3 − big − k`.
  - When k=2, z_lane is `small`. When k=small, z_lane is 2.
  - Either way, z_lane is the smallest-magnitude axis under the tie and NaN rules below. So u uses
    the two largest components of e, and `u·e = e[big]e[k] − e[k]e[big] = 0`.
  - Example: e=(0.5, 0.1, 1) gives big=0, k=2, so u=(1, 0, −0.5) and z_lane=1.
- Tie and NaN table, from the branch outcomes above:
  - `ax == ay` gives big=1 (y), small=0.
  - `min == az` gives k=2, so z_lane = small.
  - NaN in ax gives big=1, m=ax=NaN, k=2, so z_lane=0.
  - NaN only in ay gives big=1, small=0, m=ax, and an ordinary `ax > az` test.
  - NaN only in az gives k=2, so z_lane = small.
- The q1==0 and q2==0 branches cannot be reached for finite inputs that satisfy the entry
  condition. Reasoning:
  - u holds the two largest |e| components, so `|u| ≥ |e|/√3`. With `|e|² > eps2 ≈ 1e-8`,
    `q1 ≳ 3e-9`.
  - `|c| = |e||u|`, so `q2 ≳ 3e-17`, which is far above the f32 underflow threshold.
  - This is INFERRED. Keep the branches in a port anyway.

## 2. Triangle growth: 0x941766–0x941839 (case 3, triangle not degenerate)

### 2.1 Entry (PROVEN)

- The only predecessor is `jp 0x941766` at 0x9411af (`pd/epa1_preds.txt`).
- The branch is taken when `fucomp q vs Z` gives lt, gt or un (`test ah,0x44; jp`), where
  `q = f32((n.y² + n.x²) + n.z²)` (0x9411a0). So the entry condition is `q != 0.0 || isnan(q)`.
- n is case 3's cross product (hand walk 0x9410cc–0x941176, agreeing with
  `tr/pd_940f50_full.txt:63-93`):
  ```
  a = f32(p0 - p1) (F+0xf0..f8)    b = f32(p1 - p2) (F+0x100..108)     ; 3 lanes each
  n.x = f32(a.y*b.z - a.z*b.y)  F+0x30 (0x941148)   ; fsubrp: (b.z*a.y) - (b.y*a.z)
  n.y = f32(a.z*b.x - a.x*b.z)  F+0x34 (0x941168)   ; (a.z*b.x) - (b.z*a.x)
  n.z = f32(a.x*b.y - a.y*b.x)  F+0x38 (0x941172)   ; (a.x*b.y) - (b.x*a.y)
  n.w = +0.0                    F+0x3c (0x941176 fst Z)
  ```
- x87 stack at entry: `{n.x, n.z, n.y, Z}`. These are fld copies of F+0x30/0x38/0x34 from
  0x94117a–0x94118a, and match `tr/pd_940f50_full.txt:334`.
- ctx.count == 3 here: case 3 is reached through table slot 3, or 0x9410c5, or the two
  segment-growth edges.

### 2.2 Pseudocode

```
ebx = 3                                              ; 0x941768
q' = f32( (n.y*n.y + n.x*n.x) + n.z*n.z )  -> F+0x1c ; 0x941781 (register copies of n)
if q' == 0.0:               ; fucom q' vs Z (0x94178b), test ah,0x44; jnp 0x9417c1 taken only on eq
    s = 0.0                 ; 0x9417c5 stores Z into F+0x14
else:                       ; lt, gt, un
    s = f32( 1.0 / f32(_CIsqrt(q')) )  -> F+0x14     ; 0x94179e call, 0x9417a3, fld1/fdivrp 0x9417ad, 0x9417af
n.x = f32(n.x*s)  -> F+0x30       ; 0x9417e5
n.y = f32(n.y*s)  -> F+0x34       ; 0x9417f7
n.z = f32(n.z*s)  -> F+0x38       ; 0x941801
n.w = f32(s * f64[0xbea968])  -> F+0x3c   ; 0x941805 fmul QWORD +0.0, 0x94180b
FUN_940e40(dir=&n (F+0x30), ref=&ctx.M[0], vrec=V (F+0x170), &d (F+0x18))     ; call 0x94180f
if eps.x > d:               ; fld d; fld [esi+0x40]; fcompp (0x94181b): eps.x vs d; test ah,0x41; je taken only on gt
    goto 0x941ae5           ; "touching" exit; it reads n from F+0x30..0x3c (0x941af1..0x941b06). Not in this scope
else:                       ; lt, eq, un
    FUN_940980(V)           ; 0x941832 (lea [esp+0x170] at esp=F, 0x941828); count 3 -> 4
    push fldz; goto 0x940f79   ; case 4 body (0x941837, 0x941839)
```

### 2.3 Arguments of the call at 0x94180f (PROVEN, hand esp arithmetic)

The pushes, in order:
1. `edx = lea[esp+0x18]` with esp=F gives F+0x18.
2. `eax = lea[esp+0x174]` with esp=F−4 gives F+0x170.
3. `ecx` = ctx.M (0x9417cf).
4. `edx = lea[esp+0x3c]` with esp=F−0xc gives F+0x30.

The interleaved n stores (`[esp+0x38]` with esp=F−8, `[esp+0x44]/[esp+0x48]/[esp+0x4c]` with
esp=F−0x10) all land on F+0x30..0x3c. That agrees with `tr/epa1_tri.txt:21-29`.

### 2.4 Trace corrections and the join at 0x9417cb (PROVEN by hand)

- `tr/epa1_tri.txt:19-28` and `tr/pd_940f50_full.txt:353-363` use `s = f32(Z)` (store 0x9417c5).
  On the sqrt edge, s is the store at 0x9417af (`tr/epa1_tri_sqrtjoin.txt:4`).
- Both edges reach 0x9417cb with the stack `{n.x, n.y, n.z}`.
  - Sqrt edge: reloads of F+0x38, 0x34, 0x30 at 0x9417b3–0x9417bb.
  - Eq edge: 0x9417c1 `fstp st0`, `fxch st3`, `fstp [F+0x14]` (stores Z), `fxch st2`.
- On the eq edge, n.x/n.y/n.z are the register values from entry. Those are fld copies of the
  same f32 slots, so they have identical bits.

### 2.5 Reachability (INFERRED)

`q'` is the same expression on the same operands as the entry test's q, with the same association
(compare 0x94117a–0x9411a0 with 0x941766–0x941781). So under one control word `q' == q`, and the
`q' == 0` branch cannot be reached from the entry condition `q != 0`. If q is NaN, the code takes
the sqrt path.

### 2.6 Exits and ctx writes (PROVEN)

- There are two exits: to 0x941ae5 when `eps.x > d`, and to case 4 after the append.
- No out or res write happens inside this range; out is written by 0x941ae5.
- Note the threshold. It is eps.x (`[esi+0x40]`, the f32 eps), not eps2.

## 3. FUN_00940e40(dir, ref, vrec, &dist): best of ±dir support (PROVEN, `f_940e40.s`, `tr/pd_940e40.txt`)

thiscall with ecx = ctx (saved in ebx at 0x940e62), `ret 0x10`. The args are read through ebp:
`[ebp+8]` dir (esi), `[ebp+0xc]` ref (eax), `[ebp+0x10]` vrec (edi), `[ebp+0x14]` &dist.
The three call sites, all in 0x940f50, are 0x941704, 0x941721 and 0x94180f
(`pd/epa1_callers.txt`, a grep of every `pd/f_*.s`).

```
nd.x = f32(-dir.x) G+0x20 (0x940e57); nd.y G+0x24 (0x940e64); nd.z G+0x28 (0x940e6d); nd.w G+0x2c (0x940e76)
                                     ; fchs then store: exact negation (NaN: sign flipped)
FUN_940820(ctx, dir, L)              ; L = local vrec at G+0x40. Push order eax=G+0x40 (lea at esp=G), then esi. Call 0x940e7a
FUN_940820(ctx, &nd, vrec)           ; push edi(vrec), then lea[esp+0x24] at esp=G-4 = G+0x20. Call 0x940e8a
w  = f32(L.M - ref)    (x,y,z)  -> G+0x30..0x38      ; 0x940e98, 0x940ea3, 0x940eae
d1 = f32( (dir.y*w.y + dir.x*w.x) + dir.z*w.z ) -> G+0x18   ; 0x940eb2..0x940eca
w' = f32(vrec.M - ref) (x,y,z)  -> G+0x30..0x38      ; 0x940ed2, 0x940edc, 0x940ee6 (overwrites w)
d2 = f32( (w'.y*nd.y + w'.x*nd.x) + w'.z*nd.z ) -> G+0x1c   ; 0x940eea..0x940f06
; compare: fld d1; fld d2; fcom st(1) => d2 vs d1 (0x940f12); fstp st(1) leaves {d2}
if d2 > d1 or unordered:             ; test ah,0x41; jp 0x940f3d taken on gt (ah&0x41=0) and un (0x41)
    *dist = d2                       ; 0x940f41 fstp (exact; d2 is already f32). vrec keeps the -dir support
else:                                ; lt, eq: a tie keeps +dir
    FUN_42c800(this=vrec, src=L)     ; 0x940f26 (ecx=edi, push G+0x40)
    *dist = d1                       ; 0x940f2b/0x940f32
return                               ; eax is not a defined return value. It holds &dist on the +dir path
                                     ; (0x940f2f) and is unchanged on the -dir path. No caller reads it:
                                     ; after 0x941704 eax is overwritten by the lea at 0x941711; after
                                     ; 0x941721 and 0x94180f the next instructions are fld at 0x941726 and 0x941814
```

- **Lanes.** Only lanes x, y, z enter the dots. The w lane of `dir` is negated into nd.w, and that
  is what 0x940820 consumes as the direction.
- **Negated dot (INFERRED).** Because nd = −dir exactly, and round-to-nearest is sign-symmetric,
  `d2 == −f32((w'.y·dir.y + w'.x·dir.x) + w'.z·dir.z)` bit for bit, except for the sign of a zero
  result. So d2 measures `(s₋ − ref)·(−dir)`, and the function keeps the support that lies
  farther along its own probe direction. Mark this INFERRED (recall of IEEE sign symmetry).
- **ref.** Every caller passes ref = M[0] (p0).
- **The vrec+0x30 flag is copied from uninitialised stack.** This is PROVEN.
  - 0x940820 writes only `[edi+0..0xc]` itself (0x940949–0x940968). Its two shape-support calls
    receive `edi+0x10` and `edi+0x20` (0x94083c, 0x94085d).
  - L+0x30 = G+0x70 is never written in 0x940e40.
  - So on the +dir path, `vrec.flag` = stale stack content. On the −dir path, vrec.flag keeps
    whatever the caller had there.
  - Proven harmless within what was checked: 0x940980 reads only `src+0x00..0x2c` (§4), and the
    0x940f50 listing has no esp-relative access to F+0x150..0x1af apart from the `lea`s of
    F+0x130/F+0x170 (`pd/epa1_vrecflag_grep.txt`).
  - NOT DETERMINED: whether shapeA/shapeB `support` writes more than 16 bytes at its output.
    That would overrun into +0x20 or +0x30 of the vrec. The virtual bodies were not read.

## 4. FUN_0042c800 and FUN_00940980 (the data moves this scope triggers)

**0x42c800(this=dst in ecx, src)**, `ret 4` (PROVEN, `f_42c800.s`):
- `dst[i] = src[i]` for the dwords i = 0..11, as `fld dword` / `fstp dword` pairs (0x42c806–0x42c849).
- The 13th dword (+0x30) is copied with an integer `mov` (0x42c84c/0x42c84f), so it is bit-exact.
- It copies exactly 0x34 bytes; vrec +0x34..0x3f is not copied.
- INFERRED (SDM recall): an f32 signalling-NaN payload is quieted by the fld/fstp round trip.
  Every other f32 value, denormals included, round-trips exactly. Same caveat as pd_subtree §10.5.

**0x940980(ctx, vrec)**, `ret 4` (PROVEN, `f_940980.s`):
- With `k = ctx.count`, copy `ctx.M[k] = vrec[0x00..0x0c]`, `ctx.A[k] = vrec[0x10..0x1c]` and
  `ctx.B[k] = vrec[0x20..0x2c]`.
- Each copy is 4 lanes of fld/fstp dword. The arrays use a 16-byte stride (`shl esi,4`).
- Then `ctx.count = k+1` (0x94099b, 0x9409e5). vrec+0x30 is not read.

## 5. Constants (PROVEN, `pd/epa_growth_consts.txt`)

| addr | operand size | value | used at |
|---|---|---|---|
| 0xbea968 (.rdata) | f64 (`fmul qword`) | +0.0 (bytes 00×8) | 0x9416fa (c.w), 0x941805 (n.w) |
| 0x941c34 | u32[5] jump table | 0x94128b, 0x941245, 0x9411cb, 0x9410cc, 0x940f79 for count 0..4 | 0x940f72 |
| `fldz`, `fld1` | immediates | +0.0, 1.0 | Z, the reciprocal |
| `[F+0x2c]` | f32 memory | +0.0 (stored at 0x941586) | u.w multiplier at 0x94166c (this is not the f64 constant) |

The ctx thresholds `eps2` (+0x50) and `eps.x` (+0x40) are runtime values, set by 0x941e10 from
f32 `[0xb43c58]` = 9.99999975e-05 (pd_subtree §2).

## 6. Precision guidance for a Rust port (INFERRED: analysis of the PROVEN sites; theorem recall)

- **Exact, or correctly rounded binary32, whatever the precision-control word.** Recall: double
  rounding is harmless for +, −, ×, ÷ and sqrt when p' ≥ 2p+2, and 53 and 64 are both ≥ 50.
  These operations are:
  - every single-operation f32 store: lane differences `f32(a−b)`, scalings `f32(x·s)`,
    `f32(1/r)`, `f32(sqrt q)` (assuming `_CIsqrt` is a bare `fsqrt`, recall, unchecked)
  - fabs and fchs
  - all comparisons, because every compare in scope compares f32 values loaded from memory
- **Depend on the control word.** These are expressions of several operations held in registers
  before one f32 store:
  - the cross products `a·b − c·d` (c, n)
  - the squared norms (q1, q2, q, q')
  - the dots d1 and d2 in 0x940e40

  How to reproduce each setting:
  - PC = 24 bits: f32 arithmetic per operation. The only difference is that the x87 keeps an
    extended exponent range, so f32 overflow or underflow of an intermediate can differ.
  - PC = 53 bits: f64 arithmetic, then one f32 rounding, reproduces it exactly for f32 inputs.
  - PC = 64 bits: needs 80-bit emulation.
- **Association (PROVEN above):**
  - Norms: `(y² + x²) + z²`, with the y term first in the sum.
  - Dots in 0x940e40: `(y·y' + x·x') + z·z'`.
  - Cross product components: `first product − second product`, exactly as written in §1.2 and
    §2.1. In IEEE the order of the factors inside a product does not matter.

## 7. NOT DETERMINED

1. **The x87 precision-control word at run time.** Nothing in 0x940e40, 0x42c800, 0x940980 or
   0x940f50 sets it: pd_subtree §1 grep, no `fldcw`. It decides the rounding of the expressions
   listed in §6. Tried: the static grep only.
2. **What `_CIsqrt` (MSVCR80, IAT 0xb053ac) does beyond `fsqrt`**, such as argument checks or
   errno. Not read, because the DLL body is outside this binary.
3. **The size of shape `support` output writes** (vtable +0x30 of shapeA and shapeB), and so
   whether vrec +0x1c/+0x2c are fully written and +0x30 left alone. Tried: only the call sites
   at 0x940841/0x9408c9. The virtual implementations were not located.
4. **Content of the stale `vrec+0x30` flag** copied by 0x42c800 (L+0x30 = G+0x70 of 0x940e40).
   It is runtime stack garbage. No reader was found in 0x940f50 or 0x940980. Readers after
   0x940f50 returns were not checked, though the vrecs are 0x940f50 locals, so INFERRED none.
