# Exact x87 transcription: deferred new-point pass `FUN_008DCF30` and Jacobian builder `FUN_00A209B0` (entry → 0xA211AC)

Image pc-v10 `mercs2_unpacked.exe`. Listings made this run (scratch, this folder):
`jp_dis_8dcf30.txt` (0x8DCF30–0x8DD3C0), `jp_dis_a209b0.txt` (0xA209B0–0xA211C0), `jp_dis_fd040.txt` (0x8FD040–0x8FD400),
`jp_dis_4ae427.txt`, `jp_consts.txt` / `jp_constvals.txt` (constants), `jp_emu_scan2.txt` (splice emulation), `jp_cap1..3.txt`
(capture reads). Both functions are pure x87 (no SSE). Grades: P = read in asm this run (address given), I = inferred, ND.

Notation: `f32(x)` = value on the x87 stack rounded to f32 by `fstp/fst dword`; everything else on the stack is f64
(CW 0x027F). Loads of dword memory are exact. `S` = esp after the function's three register pushes; every `[S+k]`
below is that function's own frame (stack offsets corrected for in-body pushes where noted).

## 0. Constants used (bytes from `xxd`, `jp_consts.txt`; decimal from `jp_constvals.txt`) — P

| VA | Load width | Bits | Value | Note |
|---|---|---|---|---|
| 0xB58938 | qword | 0x3F80000000000000 | 0.0078125 (1/128) | restitution decode |
| 0xB58FD0 | dword | 0x3E99999A | 0.30000001192092896 | restitution threshold |
| 0xB58960 | qword | 0x3DDB7CDFE0000000 | 1.000000013351432e-10 | **= f64(f32(1e-10))**, not f64 1e-10 |
| 0xB58958 | qword | 0xBFC99999A0000000 | −0.20000000298023224 | **= f64(f32(−0.2))** |
| 0xB59210 | qword | 0xBFF4CCCCC0000000 | −1.2999999523162842 | **= f64(f32(−1.3))** |
| 0xBEAB40 | dword | 0x7F7FFFEE | 3.402820018375656e38 | default maxImpulse in the restitution request (not FLT_MAX 0x7F7FFFFF) |
| 0xBEAA68 | qword | 0x3E80000000000000 | 1.1920928955078125e-7 (2^−23) | FLT_EPSILON |
| 0xCE0404 | dword | 0x3F800000 | 1.0 | rhs |
| 0xCE0408 | dword | 0x3D4CCCCD | 0.05000000074505806 | rhs |
| 0xBEAABC | dword | 0xB4000000 | −1.1920928955078125e-7 | dataA clamp |
| 0xB5AB50 | qword | 0x3FEFAE1480000000 | 0.9900000095367432 | **= f64(f32(0.99))** pair coupling factor |
| 0xB13380 | dword[256] | — | hkUFloat8 table | friction / maxImpulse decode |

All four "qword" factors are f32 values widened to f64 (low 29 mantissa bits zero). A port must use these exact f64 values.

---

## 1. `FUN_008DCF30` — deferred new-point pass

### 1.1 Entry, splice, arguments — P

- 0x8DCF30 `push ebp; mov ebp,esp; and esp,-0x10`; 0x8DCF36 `jmp [0x244FB7C]` (SecuROM). `mercs2_probe splice-emulate <exe>
  0x8DCF36 --steps N` stepped one instruction at a time (`jp_emu_scan2.txt`): step 2726 stops at 0x4AE427, step 2727 at
  0x4AE42D with esp −0xF4, step 2728 at **0x8DCF3C**. The gadget bytes at 0x4AE427 are `81 ec f4 00 00 00` = `sub esp,0xF4`
  then `jmp 0x8DCF3C` (`jp_dis_4ae427.txt`). Body 0x8DCF3C–0x8DD3B1 is plain `.text`, no further SecuROM jumps.
- Frame: S = aligned ebp − 0xF4 − 0xC (pushes ebx 0x8DCF3F, esi 0x8DCF60, edi 0x8DCF67).
- Call site: **`FUN_008FD040` 0x8FD3FB** (not 0x8FD202): `eax=[internal+0]` (instance), `eax=[instance+0xC]` (constraint data
  = mgr+0x14), `ecx=[data+0x28]` (= mgr+0x3C = atom); `push atom; push q; push data; call`. q = `esi` = FD040's `[ebp+0x10]`
  (0x8FD353), with q+0x30/+0x34/+0x48 set just before (0x8FD3AB–0x8FD3D7).

| Arg | Meaning |
|---|---|
| [ebp+0x08] | `data` = hkpSimpleContactConstraintData (mgr+0x14) — only passed on (event +0x20, FB200 arg 1) |
| [ebp+0x0C] | `q` (job+0x80): reads +0x00, +0x30 (accA), +0x34 (accB), +0x48 (instance) |
| [ebp+0x10] | `atom` (hkpSimpleContactConstraintAtom): reads u16 +0x04 n, u16 +0x06 numReserved, u8 +0x0A stride |

Setup (0x8DCF3C–0x8DCF7B): `instance = [q+0x48]`; `A = [instance+0x14]` (esi), `B = [instance+0x18]` (edi);
`props0 = atom + 0x30 + 32·numReserved` → [S+0x18]; `cp0 = atom+0x30` → [S+0x1C]; stride → [S+0x4C]; instance → [S+0x48];
counter = n−1 → [S+0x40]; `js 0x8DD3A4` (n == 0 → skip loop, still clears the internal flag).

Per-point pointers: `ecx = cp`, `ebx = cp+0x18`, `edx = props`. So `[ecx]` pos.x, `[ebx−0x14]` pos.y, `[ebx−0x10]` pos.z,
`[ebx−8]` n.x, `[ebx−4]` n.y, `[ebx]` n.z, `[ebx+4]` distance; props: +0x00 impulse, +0x04 solverData, +0x0C friction byte,
+0x0D restitution byte, +0x0E maxImpulse byte, +0x0F flags, +0x10 dataA.

**Loop order is ascending i = 0 … n−1** (0x8DD383–0x8DD39A: `props += stride`, `cp += 0x20`, `ebx += 0x20`, counter−−, `jns`).
The n−1 counter only counts. P.

Entity fields read (A = esi, B = edi): +0x08 world (0x8DD0E3), +0x10 (address passed as event body pointer), +0x19C invMass,
+0x1A0/+0x1A4/+0x1A8 linear velocity xyz, +0x1B0/+0x1B4/+0x1B8 angular velocity xyz, u16 +0x1F4 listener count (array at
+0x1F0, via FUN_008F4E30 decomp). Names of +0x19C/+0x1A0/+0x1B0 from the spec (I); the offsets are P.
Accumulator fields read: accA/accB +0x40/+0x44/+0x48 only (COM). Accumulator pointers come from **q+0x30 / q+0x34**
(0x8DCF93, 0x8DCFB3), = `[entity+0x90] + ebx` (FD040 0x8FD3C0–0x8FD3D7, P). That `ebx` is the accumulator buffer base
is I: its last write before the loop is `mov ebx,eax` at 0x8FD222, in a stretch of the listing that is misaligned, and the
source was not traced.

### 1.2 Per point (skip when `(props.flags & 1) == 0`, 0x8DCF84) — P

```
// rA                                                                    0x8DCF91–0x8DCFB9
rA.x = f32(pos.x - accA[+0x40]) -> [S+0x50]
rA.y = f32(pos.y - accA[+0x44]) -> [S+0x54]
rA.z = f32(pos.z - accA[+0x48]) -> [S+0x58]
// ω_A × rA, ω = (w0,w1,w2) = A+0x1B0/0x1B4/0x1B8                       0x8DCFBD–0x8DD011
cA.x = f32( (w1*r.z) - (w2*r.y) )   -> [S+0x20]   // fsubrp DE E1: st1 = st0 - st1 with st0 = w1*rz
cA.y = f32( (w2*r.x) - (w0*r.z) )   -> [S+0x24]   // fsubrp DE E2
cA.z = f32( (w0*r.y) - (w1*r.x) )   -> [S+0x28]   // fsubp  DE E9: st1 = st1 - st0
// + linear velocity (fld lin; fadd [cA])                              0x8DD015–0x8DD03B
vA.x = f32(A.lin.x + cA.x) -> [S+0x20]; vA.y = f32(A.lin.y + cA.y) -> [S+0x24]; vA.z = f32(A.lin.z + cA.z) -> [S+0x28]
// rB (accB+0x40..)                                                      0x8DD03F–0x8DD057
rB = f32(pos - accB[+0x40..+0x48]) -> [S+0x70],[S+0x74],[S+0x78]
// ω_B × rB                                                              0x8DD05B–0x8DD0A9
cB.x = f32( (w1*r.z) - (r.y*w2) ) -> [S+0x30]   // fsubp DE EB: st3 = st3 - st0
cB.y = f32( (r.x*w2) - (w0*r.z) ) -> [S+0x34]   // fsubrp DE E2
cB.z = f32( (w0*r.y) - (r.x*w1) ) -> [S+0x38]   // fsubp DE E9
vB.x = f32(B.lin.x + cB.x) -> [S+0x30]          // 0x8DD0B0–0x8DD0D2
vB.y = f32(B.lin.y + cB.y) -> [S+0x34]          // 0x8DD0DD/0x8DD0E6, stored 0x8DD0F5 after one push ([esp+0x38])
vB.z = f32(B.lin.z + cB.z) -> [S+0x38]          // 0x8DD0FA–0x8DD11A (two pushes: [esp+0x40])
```
Each product is a single f64 product of two f32 inputs (exact); only the subtraction rounds, then the f32 store. The products
are formed in the operand orders shown; commutativity makes the bits independent of that order.

```
// d (esp = S-8 here: [esp+0x28] = S+0x20 …)                              0x8DD11E–0x8DD13E
d.x = f32(vA.x - vB.x) -> [S+0x60]; d.y = f32(vA.y - vB.y) -> [S+0x64]; d.z = f32(vA.z - vB.z) -> [S+0x68]
E+0x14 = 0.0f                                                            // 0x8DD142–0x8DD144
projVel = f32( ((d.y*n.y) + (d.x*n.x)) + (d.z*n.z) ) -> E+0x18 (S+0xA4)   // 0x8DD14B–0x8DD163
```

Event struct `E` at S+0x8C (built 0x8DD0AD–0x8DD163):

| E off | Content |
|---|---|
| +0x00 | A+0x10 |
| +0x04 | B+0x10 |
| +0x08 | not written here; the callees write it: FUN_008EA620 sets 0 (world source), FUN_008F4E30 sets the entity (decomp) |
| +0x0C | cp pointer |
| +0x10 | props pointer |
| +0x14 | 0.0f |
| +0x18 | projVel (f32) |
| +0x1C | int 1 |
| +0x20 | `data` (arg 0) |

Listener calls (0x8DD16A–0x8DD1A5):
1. `FUN_008EA620(world = [A+0x08], &E)` (cdecl, 2 args; `add esp,8`). Decomp: sets E+8 = 0, then for k = count(+0x178)−1 … 0
   calls `world+0x174[k]->vtable[+4](&E)` (contactPointConfirmed).
2. if u16 [A+0x1F4] != 0: `FUN_008F4E30(A, &E)`; decomp: E+8 = A, then for k = count−1 … 0 `A+0x1F0[k]->vtable[+4](&E)`.
3. same for B (0x8DD18D).

Tail calls after each dispatch loop (decomp):
- `FUN_008F4E30` ends in `FUN_008F48E0` (eax = the listener array): it compacts the array by removing null entries and
  decrementing the u16 count. It does not touch E, props or cp. P (decomp).
- `FUN_008EA620` ends in `FUN_008E9E00`: `if (count − 1 >= 0) jmp [0x2455D10]`, a SecuROM splice. Its body is ND (it was not
  emulated). I: it is the same compaction for world+0x174, by analogy with 8F48E0.

**The seed reads projVel back from E+0x18 after the listeners** (0x8DD1D4), so a listener that writes E+0x18 changes it. P.
The restitution byte is read from props after the listeners (0x8DD1AC). P.

```
e = f32( f64(int32(u8 props+0x0D)) * 0.0078125 )      // fild dword, fmul qword 0xB58938, fstp 0x8DD1BE–0x8DD1C8 (exact)
pv = E+0x18 (f32 reload)                               // 0x8DD1D4
rv = [[[A+0x08]+0x6C]+0x64]+0x70                      // 0x8DD1B0–0x8DD1BB, fld dword 0x8DD1DB
fld rv; fchs; fcomp st(1)   (compares -rv with pv)     // 0x8DD1DE–0x8DD1E7
test ah,0x41; jne SEED   -> SEED taken when -rv < pv, -rv == pv, or unordered (C0=C3=1)
                         -> i.e. restitution path only when -rv > pv (ordered); NaN pv or NaN rv -> SEED
fld 0.3f; fld e; fcom st(1); test ah,0x41; jne SEED   // 0x8DD1ED–0x8DD200
                         -> SEED when e < 0.3f, e == 0.3f or unordered; restitution only when e > 0.30000001192092896
```
Capture (first-mission, boat A = 0x1EBB8000): [A+8] = 0x20007800; [world+0x6C] = 0x20017E80; [+0x64] = 0x20007990
(= world+0x190); **[0x20007A00] = 0x7F7FFFEE** (3.40282e38). P (`jp_cap1..3.txt`). With that value the restitution path is
reachable only for pv < −3.402820018e38 (pv = −inf, or f32 bits 0xFF7FFFEF … 0xFF7FFFFF) and e > 0.3f, i.e. restitution
byte ≥ 39 (39/128 = 0.3047; 38/128 = 0.2969 fails).

FPU stack entering SEED: `st0 = pv, st1 = e` from both entries (0x8DD315 `fstp st(0)` pops the extra e). P.

### 1.3 SEED (0x8DD317–0x8DD374) — P

```
s   = f32( B.invMass(+0x19C) + A.invMass(+0x19C) )                  // fld [edi+19C]; fadd [esi+19C]; fstp [S+0x14]
k   = f32( 1.0 / ( f64(s) + 1.000000013351432e-10 ) )               // fadd qword; fld1; fld st0; fdivrp DE F2: st2 = st0/st2
// stack now: 1.0, pv, e
t1  = (f64(k) * -0.20000000298023224) * pv                           // fmul qword 0xB58958; fmul st,st(2)  (D8 CA)
ope = 1.0 + e                                                        // fld st(3); faddp st(2)  -> f64, exact
props.impulse   = f32( t1 * ope )                                    // fmulp; fstp [props+0]      0x8DD350–0x8DD352
w0  = f32( (e * pv) * f64(q[+0x00]) )                                // fmulp (e*pv) DE C9; fmul dword [q]; fstp   0x8DD354–0x8DD358
w   = f32( f64(w0) * -1.2999999523162842 )                           // 0x8DD35C–0x8DD366
props.solverData = w                                                 // fst [props+4]  0x8DD36E
props.dataA      = f32( w + dist )                                   // fadd [cp+0x1C]; fstp [props+0x10]  0x8DD371–0x8DD374
```
Association: impulse = ((k·c₋₀.₂)·pv)·(1+e); w0 = (e·pv)·dt with no store between the products. q+0x00 = si.deltaTime (spec §1.8).

### 1.4 Restitution path (0x8DD206–0x8DD313) — P for the code, callee not read

Request struct R at S+0xC0: +0x00..+0x08 n.xyz, +0x0C dist, +0x10 `T[friction byte]` (0xB13380), +0x14 e, +0x18 maxImpulse =
`T[maxImpulse byte]` if the byte ≠ 0 else 0x7F7FFFEE (dword 0xBEAB40), +0x1C pv, +0x20 0.0, +0x24 0.0.
Call `FUN_008FB200(data, cp, &R, A, B, accA, accB, &[S+0xFC])` (8 cdecl args, 0x8DD286–0x8DD2B1). If byte [S+0xE8]
(= R+0x28) ≠ 0: `FUN_008EAFC0([A+8], &{int 1, instance, props, cp} (S+0xB0), 1)` (0x8DD2BE–0x8DD300). Then
`props.impulse = 0.0f`, `props.dataA = dist` (0x8DD303–0x8DD310). **props.solverData is not written on this path** (by this
function). What FB200 computes or writes: ND (not read).

### 1.5 Flag clears — P

- Both paths: `props.flags(+0x0F) &= 0xFE` (0x8DD377).
- After the loop, and also when n == 0: `[[instance+0x28] + 0x12] &= 0xFE` (0x8DD3A0–0x8DD3A7); instance+0x28 = the internal record.

---

## 2. `FUN_00A209B0` entry → 0xA211AC

### 2.1 Arguments and q fields — P

| Arg | Meaning |
|---|---|
| [ebp+0x08] | atom: u16 +0x04 n, u16 +0x06 numReserved, u8 +0x0A stride; points at +0x30 |
| [ebp+0x0C] | q |
| [ebp+0x10] | u8 writeHeader |
| [ebp+0x14] | `&w` (pointer to the schema write pointer; `esi = *w`, 0xA20A18) |

q fields read in this range: +0x0C frame deltaTime (0xA20DF7), +0x1C rhsFactor (0xA20EA1), +0x20 virtMassFactor (0xA20AAA,
0xA2112F), +0x30 accA (edi), +0x34 accB (ebx), +0x48 instance (header), +0x50 idxA, +0x54 idxB (header).
q fields read after 0xA211AC (offsets only, not transcribed here; `eax = [ebp+0xC]` at 0xA21552 and 0xA21F69, with no
write to eax before these uses, from a grep of `jp_dis_a211ac_end.txt`): +0x20 (0xA215F9, 0xA218F0, 0xA21DBF, 0xA21F72),
+0x24 frictionRhsFactor (0xA218EA, 0xA21BCB, 0xA22153), +0x18 frictionMaxFactor (0xA21DEC). The function writes the
pointer back with `*[ebp+0x14] = esi` on its exits (0xA221C2 and the other three ret paths 0xA2217A–0xA221F0).

Accumulator fields: +0x01 u8 identity, +0x30/+0x34/+0x38 invI, +0x3C invMass, +0x40/+0x44/+0x48 COM, +0x50..+0x78 rotation
(c50 = +0x50/54/58, c60 = +0x60/64/68, c70 = +0x70/74/78).

Frame S = aligned ebp − 0x124 − 0xC. No pushes inside the range.

### 2.2 Prologue (0xA209BF–0xA20A46) — P

```
Z = +0.0 (fldz, kept on the x87 stack through the whole loop)
sumPos [S+0xC0,C4,C8] = 0;  sumNrm [S+0x70,74,78,7C] = 0;  sumImp [S+0x88] = 0;  sumFric [S+0xF8] = 0
invN = f32( 1.0 / f64(int32 n) )            // fild; fld1; fdivrp DE F1 (st1 = st0/st1); fstp [S+0xFC]   0xA20A03–0xA20A32
[S+0x8C] = stride; [S+0xAC] = n; props0 = atom + 0x30 + 32*numReserved
eps = qword FLT_EPSILON on the stack: stack = (eps, Z)                                                   0xA20A40
```
No n > 0 test: the loop is entered unconditionally (`jmp 0xA20A98`, 0xA20A90) and tested at the bottom (0xA211A6).
With n == 0 the body would run once and invN = +inf. P (code); whether n == 0 can reach here: ND.

### 2.3 Header (if writeHeader, 0xA20A48–0xA20A7F) — P

```
w[0]  = f32(f64(w[0]) + eps)       // whatever the buffer held
byte w+0 = 0x01; byte w+1 = stride; bytes w+2..3 = left from the f32 above (not written explicitly)
u16 w+4 = low16(q+0x50 idxA); u16 w+6 = low16(q+0x54 idxB); u32 w+8 = props0; u32 w+0xC = [q+0x48] (instance)
w += 16
```

### 2.4 Per-point loop 0xA20A98–0xA211A6 (i ascending) — P

Pointers: `ecx = cp_i + 0x18` (`[ecx−0x18..−0x10]` pos, `[ecx−8..0]` n, `[ecx+4]` dist); `edx = props_i + 0x0C`
(`[edx−0xC]` impulse, `[edx−8]` solverData, `[edx]` friction byte, `[edx+2]` maxImpulse byte, `[edx+3]` flags,
`[edx+4]` dataA); `esi` = record being written. Stack at body entry: (eps, Z) (0xA20A92 `fxch` restores it on re-entry).

```
pair = flags & 2 -> [S+0x28]                                      0xA20A98
[S+0x5C] = q+0x20 (virtMassFactor)                                0xA20AAA
rec[0]=n.x, rec[1]=n.y, rec[2]=n.z, rec[3]=dist                    0xA20AB1–0xA20AC4
rA = f32(pos - accA+0x40) -> [S+0x100,104,108]                    0xA20AC7–0xA20AE7
rB = f32(pos - accB+0x40) -> [S+0x120,124,128]                    0xA20AEE–0xA20B0E
// rA × n                                                          0xA20B15–0xA20B60
xA.x = f32( (n.z*rA.y) - (n.y*rA.z) ) -> [S+0xD0]    // fsubrp DE E1
xA.y = f32( (rA.z*n.x) - (rA.x*n.z) ) -> [S+0xD4]    // fsubp  DE EB: st3 - st0
xA.z = f32( (rA.x*n.y) - (rA.y*n.x) ) -> [S+0xD8]    // fsubp  DE E9
```
A rotation (0xA20B67 `je` on accA+0x01 == 0; identity: rec[4..6] = xA copied, 0xA20B69–0xA20B84):
```
rec[4] = f32( ((c60[0]*xA.y) + (xA.x*c50[0])) + (c70[0]*xA.z) )   0xA20B86–0xA20BB4
rec[5] = f32( ((c64*xA.y) + (c54*xA.x)) + (c74*xA.z) )            0xA20BB7–0xA20BCA   (cXY = accumulator +0xXY)
rec[6] = f32( ((xA.y*c68) + (xA.x*c58)) + (xA.z*c78) )            0xA20BCD–0xA20BE2
```
Every row is: first `c6·y + c5·x` (f64), then `+ c7·z` (f64), then one f32 store.
```
rec[7] = Z (+0.0)                                                 0xA20BE7
// n × rB                                                          0xA20BEA–0xA20C35
xB.x = f32( (n.y*rB.z) - (n.z*rB.y) ) -> [S+0x90]    // fsubrp DE E1
xB.y = f32( (rB.x*n.z) - (rB.z*n.x) ) -> [S+0x94]    // fsubrp DE E2
xB.z = f32( (rB.y*n.x) - (rB.x*n.y) ) -> [S+0x98]    // fsubp  DE E9
rec[8..10] = B.identity ? xB : M_B·xB  (same add tree as A, accB fields; 0xA20C3C–0xA20CB3)
rec[0xB] = Z                                                      0xA20CBD;  [S+0x0C] = &rec[0xB]
```
K and effective mass (0xA20CC0–0xA20D97), all inputs reloaded from the stored f32 rec values:
```
qA_j = f32(rec[4+j]*rec[4+j]); qB_j = f32(rec[8+j]*rec[8+j])
sA_j = f32(accA.invI_j * qA_j);  sB_j = f32(accB.invI_j * qB_j)
s_j  = f32(sB_j + sA_j)
m    = f32(accB.invMass + accA.invMass)
K1   = f32( ((s_0 + s_1) + s_2) + m )                               // fld, fadd, fadd, fadd, fstp 0xA20D6C–0xA20D7C
K    = f32( f64(K1) + eps )                                         // 0xA20D80–0xA20D86
rec[0xB] = K                                                        // fst [eax] 0xA20D8E
rec[7]   = f32( f64(q.virtMassFactor) / K )                         // fdivr dword [S+0x5C] (D8 /7: st0 = m32/st0)
sumFric  = f32( T[friction byte] + sumFric )                        // 0xA20D9A–0xA20DA8
sumImp   = f32( props.impulse + sumImp )                            // 0xA20DAF–0xA20DB9
```
RHS (0xA20DC0–0xA20EA4) — the spec §6.3 trace is **verified** instruction by instruction:
```
t  = props.dataA
D  = f32(dist - t)                                     // fsubp DE EA: st2 = st2 - st0
E  = f32(-solverData - D)                              // fchs; fsubp DE EA
Aq = f32(1.0f * q[+0x0C])
Bq = f32(-0.05f * t)                                   // fld 0.05f; fchs; fmul st,st(2)
fcom (Aq vs Bq); test ah,0x41; jne -> L = Aq when Aq < Bq, Aq == Bq or unordered; else L = Bq.  L -> [S+0x2C]
   (stack after either branch: Aq, D, t, …)
M  = f32(t + L)                                        // faddp DE C4
N  = f32(D - L)                                        // fsubp DE EA
cmp: x = (L + L) + Aq  (f64; fadd st0,st0 = DC C0; faddp)
fcomp x vs E; test ah,0x05; jp skip  -> body runs only when x < E (ordered); equal, greater or NaN skip
   body: M = f32(M - E); N = f32(E + N)
props.dataA = (M < -1.1920929e-7f) ? M : -1.1920929e-7f // fcom; test ah,5; jp -> ties and NaN keep the constant
rec[3] = f32( (-N) * q.rhsFactor(+0x1C) )
```
Sums (0xA20EA7–0xA20F01):
```
sumPos.x = f32(sumPos.x + pos.x); sumPos.y = f32(sumPos.y + pos.y); sumPos.z = f32(sumPos.z + pos.z)
sumNrm.x = f32(sumNrm.x + n.x);   sumNrm.y = f32(n.y + sumNrm.y);   sumNrm.z = f32(n.z + sumNrm.z);   sumNrm.w = f32(dist + sumNrm.w)
```
(each a single f32 add of two f32 values; operand order does not change the bits.)

Branch on pair flag (`cmp [S+0x28],0` at 0xA20E88; `jne 0xA20F4C` at 0xA20F05).

### 2.5 Single (flags & 2 == 0), 0xA20F07–0xA20F47 — P

```
rec[0] = f32( f64(rec[0] = n.x) + eps ); byte rec+0 = 0x0F;  esi += 0x30          // tag #1
if maxImpulse byte != 0:
   rec[0] = f32( f64(rec[0]) + eps ); byte rec+0 = 0x11                          // tag #2, on the 0x0F-patched float
   rec[0xB] = T[maxImpulse byte]                                                 // overwrites K
```
Stack at exit: (Z, eps).

### 2.6 Pair (flags & 2 != 0), 0xA20F4C–0xA21184 — P

`prev = esi − 0x30` (the previous 48-byte record), `cur = esi`. First `fstp st(1)` drops eps (stack: Z).
```
Pn_j = f32(cur[j]   * prev[j])     j=0..2   -> [S+0x110,114,118]   // cur[0] = clean n1.x; prev[0] = tagged n0.x
PA_0 = f32(cur[4]*prev[4]); PA_1 = f32(prev[5]*cur[5]); PA_2 = f32(prev[6]*cur[6])  -> [S+0x10,14,18]
PB_j = f32(cur[8+j] * prev[8+j])                     -> [S+0xE0,E4,E8]
mA = accA.invMass, mB = accB.invMass (copied to [S+0x0C], [S+0x28])
LA_j = f32(mA*Pn_j) -> [S+0x40,44,48];  LB_j = f32(mB*Pn_j) -> [S+0xB0,B4,B8]          0xA20FC7–0xA2101E
IA_j = f32(PA_j * accA.invI_j);  IB_j = f32(PB_j * accB.invI_j)                         0xA21025–0xA21072
Lj   = f32(LB_j + LA_j)                                                                 0xA21079–0xA210A5
Ij   = f32(IB_j + IA_j)                                                                 0xA210A9–0xA210D2
Tj   = f32(Lj + Ij)                                                                     0xA210D6–0xA210F6
csum = f32( (T0 + T1) + T2 )                                                            0xA2110B–0xA21117
c    = f32( f64(csum) * 0.9900000095367432 )         // qword 0xB5AB50 (= f32 0.99 widened)   0xA2111B–0xA21125
pK = prev[0xB] (f32), K = cur[0xB] (f32)             // [esi-0x44], [esi-0x14] after esi += 0x40 (0xA21093)
det = (f64(K)*pK) - (c*c)                            // fmulp DE CA; fmulp DE CD; fsubrp DE E4 — NOT stored, f64
f   = f32( f64(q.virtMassFactor) / det )             // fdivrp DE F3: st3 = st0/st3      0xA2114D–0xA21151
prev[0xB] = f32(f * K)                               // 0xA2115B–0xA2115F
cur[0xB]  = f32(pK * f)                              // 0xA21162–0xA21164
cur[0xC]  = f32( (-c) * f )                          // fchs; fmulp     0xA21167–0xA2116D
prev[0]   = f32( f64(prev[0]) + eps ); byte prev+0 = 0x13      // re-tag, fresh qword eps load 0xA21170–0xA21180
esi = cur + 0x40
```
Stack at exit: (Z, eps) (0xA21184 `fxch`).

Notes (P for the code; consequences I):
- The pair branch never reads the second point's maxImpulse byte (`[edx+2]` is read only at 0xA20F09 on the single path).
- `pK` is whatever prev[0xB] holds: K for a 0x0F predecessor, **`T[maxImpulse]` for a 0x11 predecessor** (2.5 overwrote K).
  The 0x11 record is then re-tagged 0x13 and its maxImpulse lost.
- `prev = esi − 0x30` unconditionally: if two consecutive points both carried flag bit 1, `prev` would point 0x10 into the
  previous pair's 64-byte second row. Whether the producer can emit that: ND.

### 2.7 Loop tail and hand-off at 0xA211AC — P

Tail (0xA21186–0xA211A6): `i = [S+0x58]+1`, `edx += stride` (saved to [S+0x0C]), `ecx += 0x20`, `jl` while i < n.
State handed to the friction part (0xA211AC onward, other agent):

| Where | Content |
|---|---|
| [S+0xF8] | sumFric (f32) |
| [S+0x88] | sumImp (f32) |
| [S+0xFC] | invN (f32) |
| [S+0xC0] [S+0xC4] [S+0xC8] | Σpos x, y, z |
| [S+0x70] [S+0x74] [S+0x78] [S+0x7C] | Σn x, y, z, Σdist |
| [S+0x8C] / [S+0xAC] / [S+0x58] | stride / n / n (loop index) |
| esi | write pointer after the last row record |
| edi / ebx | accA / accB |
| x87 | (Z = +0.0, eps); 0xA211AC `fstp st(1)` leaves (+0.0) |

The first friction instructions (0xA211AE–0xA211BC) are `fld [S+0xF8]; fmul [S+0x88]; fld [S+0xFC]`, i.e. sumFric·sumImp, invN.

### 2.8 Opcode tagging, summary — P

`tag(op)`: reload the record's float 0 from memory (exact), add qword 2^−23 in f64, `fstp dword`, then `mov byte [rec], op`.

| Record | ε-adds on float 0 | Sites |
|---|---|---|
| header 0x01 | 1 (on whatever the buffer held) | 0xA20A4B–0xA20A76 |
| 0x0F | 1 | 0xA20F07–0xA20F1B |
| 0x11 | 2 (second on the 0x0F-byte-patched value) | + 0xA20F29–0xA20F33 |
| 0x13 first row | predecessor's (1 or 2) + 1 | 0xA21170–0xA21180 |
| 0x13 second row | 0 (n1.x clean) | 0xA20AB4 only |

### 2.9 Record layouts as written (float index from the record start) — P

0x0F (48 B): [0] n.x+ε, low byte 0x0F; [1] n.y; [2] n.z; [3] rhs; [4..6] angA; [7] f32(q20/K); [8..10] angB; [0xB] K.
0x11 (48 B): as 0x0F, [0] ε twice and byte 0x11; [0xB] = T[maxImpulse] (K not kept).
0x13 (112 B): [0..0xB] = the predecessor record with [0] re-tagged 0x13 and [0xB] = f32(f·K1); [0xC] n1.x (clean);
[0xD] n1.y; [0xE] n1.z; [0xF] rhs1; [0x10..0x12] angA1; [0x13] f32(q20/K1); [0x14..0x16] angB1; [0x17] f32(pK·f);
[0x18] f32(−c·f); **[0x19..0x1B] not written** (whatever the buffer held).
Every float of the 48-byte part is written each point (rec[7] and rec[0xB] first get +0.0 then the final values).

---

## 3. Corrections to the spec (contact_solve.md)

1. §3: the deferred pass visits points **ascending** (i = 0 … n−1); the n−1 counter only counts (0x8DD383–0x8DD39A).
2. §3 / §5: the call site in `FUN_008FD040` is **0x8FD3FB**, not 0x8FD202. Args are (constraintData = instance+0xC → mgr+0x14,
   q, atom = data+0x28).
3. §1.10 / §3 / §6.4: the qword constants −0.2, 1e−10, −1.3 and 0.99 are **f32 values widened to f64**:
   −0.20000000298023224, 1.000000013351432e−10, −1.2999999523162842, 0.9900000095367432 (bits in §0).
4. §3: the captured contactRestingVelocity (world+0x200) is **0x7F7FFFEE = 3.40282e38**, not FLT_MAX. The conclusion is unchanged:
   the restitution path needs pv < −3.402820018e38 (−inf or f32 bits ≥ 0xFF7FFFEF) and restitution byte ≥ 39.
5. §3: NaN projVel (or NaN resting velocity) takes the **seed** path (`test ah,0x41; jne`, unordered sets C0/C3).
6. §6.4: `f = f32(q20 / det)` with **det not rounded to f32**: `det = K·pK − c·c` stays on the x87 stack (0xA21141–0xA2114D).
7. §6.4: for a pair whose predecessor is a 0x11 record, `prevK` is T[maxImpulse], not K (see 2.6).
8. §6.1: the header's bytes 2–3 are the high bytes of f32(old w[0] + ε); w+0xC holds the **value** [q+0x48] (the instance).
9. §6.2: no n > 0 guard before the first iteration (do-while; 0xA20A90).

## 4. ND

- What `FUN_008FB200` computes on the restitution path, and who writes byte R+0x28 (not read; the path needs pv = −inf here).
- Whether a listener on world+0x174 / entity+0x1F0 writes E+0x18 for the boat case beyond what spec §4 states (not re-read).
- Whether n == 0, three consecutive paired points, or flag bit 1 on point 0 can reach `A209B0`. With bit 1 on point 0,
  `prev = esi − 0x30` lands in the header or in an earlier constraint's record.
- The body of `FUN_008E9E00` (SecuROM splice `jmp [0x2455D10]`, after the world listener loop).
- The origin of FD040's `ebx` (the accumulator base added to entity+0x90).
