# FUN_00A209B0, friction tail: 0xA211AC to the function's end (0xA221F0)

Source: asm `objdump -d --x86-asm-syntax=intel` of `game-files/canonical/dumps/mercs2_unpacked.exe` (pc-v10), saved in
`tx/fric_pro.txt` (0xA209B0–0xA20AA0), `tx/fric_loop.txt` (0xA20AA0–0xA211B0) and `tx/fric_dis.txt` (0xA211A0–0xA22200).
Constants: `tx/fric_consts.txt` (xxd). Every x87 stack state below was traced instruction by instruction. The code is x87
throughout. There is no SSE in this range (P).

Notation: `f32(e)` = e evaluated on the x87 stack (53-bit) and stored as a dword. A product or sum written without `f32`
stays on the stack in extended form. `st=[a, b, c]` lists st0 first. `eps` = qword FLT_EPSILON = 2^-23 (exact).
Confidence: P = read in the asm this run (address given), I = inferred, ND = not determined.

## 0. Function signature, registers and stack slots used by this range

`void FUN_00A209B0(atom* [ebp+8], q* [ebp+0xC], char writeHeader [ebp+0x10], float** w [ebp+0x14])`. The return type is
void (Ghidra decomp signature; eax at the four `ret`s is a leftover: rec+0x90, &w, n, fnstsw value). P.

Registers kept across the range (P, prologue 0xA20A15–0xA20A2B): `esi` = the write cursor (starts at `*w`, +0x10 after
the header), `edi` = accA = `[q+0x30]`, `ebx` = accB = `[q+0x34]`. `edx`/`eax` are reloaded with atom / q at 0xA21231,
0xA21372, 0xA2152D (atom) and 0xA21552, 0xA21F69 (q).

Slots filled before 0xA211AC (the loop agent transcribes how; the meaning here is P from the prologue 0xA209BF–0xA20A39
and the loop's stores):

| Slot | Meaning | Set by |
|---|---|---|
| `[esp+0xFC]` | invN = f32(1/f64(n)) (`fild n; fld1; fdivrp` de f1 = st1 = 1/n) | 0xA20A03–0xA20A32 |
| `[esp+0xF8]` | sumFric = running f32(T[p.friction] + sumFric), T = dword table 0xB13380 | 0xA20D9A–0xA20DA8 |
| `[esp+0x88]` | sumImp = running f32(p.impulse + sumImp) (p.impulse = props+0x00, `[edx-0xC]`) | 0xA20DAF–0xA20DB9 |
| `[esp+0xC0/C4/C8]` | Σpos x, y, z (f32 running sums, `f32(sum + pos)`) | 0xA20EA7–0xA20ED3 |
| `[esp+0x70/74/78/7C]` | Σn x, y, z and Σdistance (w) (f32 running sums) | 0xA20EDA–0xA20F01 |
| `[esp+0x5C]` | scratch (q20 copy / rhs temps) | loop |

All of these start at +0.0 (fldz/fst at 0xA209BF–0xA209FC). P.

x87 stack on arrival at 0xA211AC: `st=[Z, eps]` with Z = +0.0 (the prologue's fldz, never modified in the loop; both the
0x0F/0x11 path and the pair path leave `[Z, eps]` at 0xA21186). P (stack traced through the loop body; the pair path
drops eps at 0xA20F4C and reloads it at 0xA21173–0xA21184).

## 1. base and the `0 < base` test (0xA211AC–0xA211DE)

```
0xA211AC  fstp st(1)                         st=[0]                      (eps dropped)
0xA211AE  base = f32( (sumFric * sumImp) * invN )                       // fld [F8]; fmul [88]; fld [FC]; fld st0;
                                                                         // fmulp st2 -> (sF*sI)*invN; fstp [88]
          [esp+0x88] = base                                              // sumImp slot now holds base
          st=[0, invN]
0xA211D2  fcom dword [esp+0x88]  (0 vs base); fnstsw; test ah,5; jp 0xA221E1
```
P. `sF*sI` is not rounded to f32 before the `*invN`. Compare decode: jp is taken when the C0, C2 parity is even:
0 > base (no bits), 0 == base (C3 only, masked out), unordered (C0 = C2 = 1). **Friction continues only when 0 < base,
ordered.** NaN base exits. Exit 0xA221E1: pops both, `*w = esi` (the cursor after the contact rows), return (§7).

## 2. Friction normal nf (0xA211E4–0xA21370)

```
0xA211E4  S   = f32( (Σn.x*Σn.x + Σn.y*Σn.y) + Σn.z*Σn.z )   // faddp st2 = x²+y², then + z²; fstp [0xC]; reload
          [esp+0x28] = S
0xA2120C  iN2 = f32( invN*invN )                              // fmulp st3 on the stack copy of invN; fstp [0xC]
0xA2121E  P   = S * iN2                                       // extended, NOT stored
0xA21224  fcomp qword [0xB59D28] (P vs 0.9999); test ah,0x41; jne 0xA21265
```
P. jne is taken when P < c, P == c or unordered, so:

- **P > 0.9999 (ordered)** → branch A (0xA21231): nf = cp[0].normal, see below.
- **P ≤ 0.9999 or NaN** → 0xA21265: `fcomp qword [0xB57F98]` (S vs 0.1); test ah,0x41; jne 0xA212E5.
  - **S > 0.1 (ordered)** → branch B (0xA21272), normalise the sum.
  - **S ≤ 0.1 or NaN** → branch C (0xA212E5), cp[0].normal with a length test.

Branch A (0xA21231–0xA21260), P:
```
nf = (atom+0x40, atom+0x44, atom+0x48, atom+0x4C)   // cp[0].normal.xyz and cp[0].distance as w
stored to [esp+0x70..0x7C]; st=[nf.x, nf.y, nf.z, 0]; jmp 0xA21375
```

Branch B (0xA21272–0xA212E0), P:
```
fucom: S vs 0 (S reloaded from [0xC]); test ah,0x44; jnp 0xA212A4      // jnp taken iff S == 0 (ordered)
S != 0 or NaN: inv = f32( 1.0 / f32(sqrt(S)) )      // call _CIsqrt 0x9EE730; fstp [0xC]; fld; fld1; fdivrp (de f1 = 1/x)
S == 0:        inv = +0.0                           // fst [0x58] of the stack 0 (unreachable here since S > 0.1)
[esp+0x58] = inv
nf.x = f32(inv*Σn.x); nf.y = f32(inv*Σn.y); nf.z = f32(inv*Σn.z); nf.w = f32(inv*Σdist)   // written back to [0x70..0x7C]
st=[nf.x, nf.y, nf.z, 0] (reloaded from memory); jmp 0xA21372
```
No length test after the normalisation (P).

Branch C (0xA212E5–0xA21370), P:
```
nf = cp[0].normal xyz + cp[0].distance (w), stored to [0x70..0x7C]
L2 = f32( (nf.x*nf.x + nf.y*nf.y) + nf.z*nf.z )     // 0xA21318–0xA21330: faddp st4 = x²+y², + z²
fcomp qword [0xB59C18] (L2 vs 0.9); test ah,5; jp 0xA2136E
L2 < 0.9 (strict, ordered):   (0xA21341)
     base = +0.0 ([esp+0x88])
     nf = (0, 1, 0, 0)  (x, z, w = +0.0 from the stack zero; y = fld1)
L2 >= 0.9 or NaN: keep cp[0].normal (stack fxch only)
st=[nf.x, nf.y, nf.z, 0]
```
In the degenerate case base = 0 but the code does **not** return: the friction record is still built and gets
maxImpulse = f32(q.frictionMaxFactor · 0) (§5). P.

`_CIsqrt` (0x9EE730 = `jmp [0xB053AC]`, Ghidra: thunk to `MSVCR80.DLL!_CIsqrt`): takes st0, returns st0 (P from the stack
use). That it is a plain `fsqrt` at the current 53-bit precision control is I (CRT body not read).

At 0xA21375 every branch has `st=[nf.x, nf.y, nf.z, 0]`, `edx = atom`, and nf in `[esp+0x70..0x7C]`. P.

## 3. Friction axis t (0xA21375–0xA21584)

```
e = I[atom.info.index]            // movzx [atom+0x12]; shl 4; + 0xBF65A0; e.xyz -> [esp+0x30..0x38] (dword copies)
t.x = f32( e.y*nf.z - e.z*nf.y )  // 0xA21395–0xA213A5 (fsubp de e9: st1 - st0)
t.y = f32( e.z*nf.x - e.x*nf.z )  // 0xA213A9–0xA213B7
t.z = f32( e.x*nf.y - e.y*nf.x )  // 0xA213BB–0xA213C7 (fsubrp de e1: st0 - st1 = e.x*nf.y - e.y*nf.x)
t -> [esp+0x10/0x14/0x18]
T2 = f32( (t.x*t.x + t.y*t.y) + t.z*t.z )   // 0xA213CB–0xA213E7, same tree as S
fcomp qword [0xB57F98] (T2 vs 0.1); test ah,0x41; je 0xA214E5
```
t = e × nf. P. je is taken only when T2 > 0.1, ordered: **re-pick when T2 ≤ 0.1 or NaN.**

The identity table 0xBF65A0 holds (1,0,0,0) (0,1,0,0) (0,0,1,0) in the file bytes (xxd 0x7F65A0–0x7F65CF). P. Index 3
(the alloc's "none yet" value, spec §1.4) reads row 3 = (0,0,0,1) (file bytes 0x7F65D0). e.xyz = 0 then gives
t = 0, T2 = 0, so a re-pick follows. P.

Re-pick (0xA21400–0xA214E3), P:
```
ax = |nf.x|, ay = |nf.y|, az = |nf.z|   (fabs, each stored dword [0x90/0x94/0x98])
fcom: ay vs ax; test ah,0x41; jne    -> taken when ay <= ax or unordered
  ay <= ax (or NaN): fcompp az vs ay; je (az > ay, ordered) -> axis 1; else (az <= ay or NaN) -> axis 2
  ay >  ax:          fcompp az vs ax; jne (az <= ax or NaN) -> axis 2; else (az > ax) -> axis 0
u16 atom+0x12 = axis
atom+0x1C = +0.0 ; atom+0x24 = +0.0     // fst of the stack zero, 0xA21488 / 0xA2148E (friction rhs memories 0 and 1)
e = I[axis]; t = e × nf with the same three formulas and operand order (0xA214AD–0xA214DF)
```
So the axis is the index of the smallest |nf| component, ties going to the higher index. T2 is not re-tested after the
re-pick. atom+0x2C (rolling memory) is NOT reset. P.

Normalisation (0xA214E7–0xA21584), P:
```
T2' = f32( (t.x² + t.y²) + t.z² )               // recomputed in both paths
fucom T2' vs 0; test ah,0x44; jnp                // jnp taken iff T2' == 0 (ordered)
T2' != 0 or NaN: inv = f32( 1.0 / f32(sqrt(T2')) )   // _CIsqrt, fstp, fld1, fdivrp
T2' == 0:        inv = +0.0
[esp+0x58] = inv
t.x = f32(t.x*inv); t.y = f32(t.y*inv); t.z = f32(t.z*inv)      // [0x10/0x14/0x18]
t.w = f32(inv * 0.0)    // fmul qword [0xBEA968] = 0.0; [esp+0x1C]; +0 for finite inv
[esp+0xF8] = esi        // the record base; the sumFric slot is reused (0xA21559)
```
After 0xA21584: `st=[nf.x, nf.z, nf.y]`.

d0 = nf × t (0xA21588–0xA215BC), P:
```
d0.x = f32( t.z*nf.y - t.y*nf.z )     // fsubp de ea: st2 = st2 - st0
d0.y = f32( t.x*nf.z - t.z*nf.x )
d0.z = f32( t.y*nf.x - t.x*nf.y )
d0 -> [esp+0x30/0x34/0x38]  (d0.w is not computed)
d1 = t   (normalised t; t.y, t.z also stay on the stack: st=[t.y, t.z, nf.x, nf.z, nf.y])
```

Centre (0xA215C0–0xA215F2), P:
```
c.x = f32(Σpos.x * invN); c.y = f32(Σpos.y * invN); c.z = f32(invN * Σpos.z)   // written back to [0xC0/0xC4/0xC8]
```

## 4. Friction rows (record base R = esi; 0xA215F9–0xA21E38)

`q20 = [q+0x20]` (virtMassFactor) copied to `[esp+0x28]` at 0xA215F9 and again at 0xA218F0. P.

### Row 0 (d0)
```
R[0..2] = d0 (R[0] = d0.x, untagged for now; R[1] via fst, so d0.y also sits on the stack); R[3] = +0.0 (temp)
rA = (f32(c.x - A.COM.x), f32(c.y - A.COM.y), f32(c.z - A.COM.z))    // [edi+0x40..0x48] -> [0x90..0x98]
rB = (f32(c.x - B.COM.x), ...)                                       // [ebx+0x40..0x48] -> [0xD0..0xD8]
xA = rA × d0:  ( f32(rA.y*d0.z - rA.z*d0.y), f32(d0.x*rA.z - rA.x*d0.z), f32(rA.x*d0.y - d0.x*rA.y) )  // 0xA2167F–0xA216D1
angA0 = A.identity ? xA : M_A·xA                                       // byte [edi+1]
   M·v row k: f32( (c60[k]*v.y + c50[k]*v.x) + c70[k]*v.z )          // 0xA216EB–0xA2173A, k = x (+0), y (+4), z (+8)
R[4..6] = angA0; R[7] = +0.0 (temp)
xB = d0 × rB:  ( f32(rB.z*d0.y - rB.y*d0.z), f32(rB.x*d0.z - d0.x*rB.z), f32(d0.x*rB.y - rB.x*d0.y) )  // 0xA21748–0xA21798
angB0 = B.identity ? xB : M_B·xB  (same row formula with ebx)
R[8..10] = angB0; R[0xB] = +0.0 (temp)
```
P. xB = −(rB × d0), the same sign convention as the contact rows (§6.2).

K0 (0xA2180B–0xA218E4), P:
```
qA_j = f32(angA0_j*angA0_j); qB_j = f32(angB0_j*angB0_j)
sA_j = f32(A.invI_j * qA_j)  ([edi+0x30+4j]); sB_j = f32(qB_j * B.invI_j)  ([ebx+0x30+4j])
s_j  = f32(sB_j + sA_j)
m    = f32(B.invMass + A.invMass)      // [ebx+0x3C] + [edi+0x3C]
K0'  = f32( ((s_y + s_x) + s_z) + m )  // fld [0x34]; fadd [0x30]; fadd [0x38]; fadd [0x3C]
K0   = f32( K0' + eps )                // fadd qword 0xBEAA68
R[0xB] = K0 (temp, overwritten by inv00)
R[7]   = f32( q20 / K0 )               // fdivr dword [0x28]: st0 = m32/st0
R[3]   = f32( atom+0x1C * q+0x24 )     // rhs0 = memory0 · frictionRhsFactor (0xA218E7)
```
(s_y + s_x) and (s_x + s_y) give the same bits; only the order of the third and fourth adds matters.

### Row 1 (d1 = t)
```
R[0xC] = t.x; R[0xD] = t.y; R[0xE] = t.z; R[0xF] = t.w (temp, overwritten by rhs1)     // 0xA218F7–0xA2190A
rA, rB recomputed with the same formulas (same values)                               // 0xA2190D–0xA2196B
xA1 = rA × t:  ( f32(rA.y*t.z - rA.z*t.y), f32(t.x*rA.z - rA.x*t.z), f32(rA.x*t.y - t.x*rA.y) )   // 0xA21972–0xA219BA
R[0x10..0x12] = A.identity ? xA1 : M_A·xA1 ; R[0x13] = +0.0 (temp)
xB1 = t × rB:  ( f32(rB.z*t.y - rB.y*t.z), f32(t.z*rB.x - t.x*rB.z), f32(t.x*rB.y - t.y*rB.x) )   // 0xA21A31–0xA21A77
R[0x14..0x16] = B.identity ? xB1 : M_B·xB1 ; R[0x17] = +0.0 (temp)
```
The B rotation at 0xA21A91–0xA21ADE keeps the operands on the stack. Its row formula is the same
`f32((c60[k]*v.y + c50[k]*v.x) + c70[k]*v.z)` (row y: `(c64*v.y + c54*v.x) + c74*v.z`, row z: `(c68*v.y + c58*v.x) + c78*v.z`).
P.

K1 (0xA21AEC–0xA21BCE), P: the same as K0, except the first add is `(s_x + s_y)` (fld [0x10]; fadd [0x14]), which gives the same bits:
```
K1 = f32( f32( ((s_x + s_y) + s_z) + m ) + eps )
R[0x17] = K1 (temp); R[0x13] = f32(q20 / K1); R[0xF] = f32( atom+0x24 * q+0x24 )    // rhs1
```

### Coupling c (0xA21BD1–0xA21D93), no 0.99 factor, P
```
dd_j  = f32( d1_j * d0_j )            // R[0xC+j] * R[j] (R[0] still the untagged d0.x)
pA_j  = f32( angA0_j * angA1_j )      // R[4+j]*R[0x10+j]
pB_j  = f32( angB0_j * angB1_j )      // x: R[8]*R[0x14]; y,z: R[0x15]*R[9], R[0x16]*R[0xA]
mA = A.invMass, mB = B.invMass
LA_j = f32(mA*dd_j); LB_j = f32(mB*dd_j)
aA_j = f32(A.invI_j * pA_j); aB_j = f32(pB_j * B.invI_j)
lin_j = f32(LB_j + LA_j); ang_j = f32(aB_j + aA_j)
tot_j = f32(lin_j + ang_j)
c     = f32( (tot_x + tot_y) + tot_z )      // [esp+0xC]
```
There is no multiply by 0.99. `grep -c b5ab50 tx/fric_dis.txt` (0xA211A0–0xA22200) returns 0; the only use is
0xA2111F in the pair path (`tx/fric_grep099.txt`). P.

### 2×2 inverse (0xA21D97–0xA21E21), P
```
K0 = R[0xB] (temp), K1 = R[0x17] (temp)
f     = f32( q20 / ( K0*K1 - c*c ) )      // K0*K1 and c*c and the difference stay extended: fmul; fmulp; fsubrp (de e1); fdivr dword [q+0x20]
R[0xB]  = inv00 = f32( f*K1 )
R[0x17] = inv11 = f32( f*K0 )
inv01   = f32( (-c) * f )                  // fchs c, then fmulp
maxImp  = f32( q+0x18 * base )             // frictionMaxFactor · base ([esp+0x88] reused)
R[0x18] = inv01; R[0x19] = maxImp; R[0x1A] = (u32) atom+0x18   // export pointer
```
The denominator is not rounded to f32 (P). The determinant is not checked for zero.

### Opcode 0x15 and the cursor (0xA21D58, 0xA21E24–0xA21E38), P
```
esi += 0x70
R[0] = f32( R[0] + eps ); byte R[0] = 0x15
if n <= 1 (signed jle on `cmp n,1`): *w = esi (R+0x70); return       // 0xA221CD
```
R[0x1B] is never written in the 0x15 path, so it keeps whatever the buffer held. P.

### Record 0x15 (112 B), float index → content
| [i] | Content |
|---|---|
| 0 | f32(d0.x + eps) with low byte = 0x15 |
| 1, 2 | d0.y, d0.z |
| 3 | rhs0 = f32(atom+0x1C · q+0x24) |
| 4–6 | angA0 |
| 7 | f32(q20/K0) |
| 8–10 | angB0 |
| 0xB | inv00 = f32(f·K1) |
| 0xC–0xE | d1 = t |
| 0xF | rhs1 = f32(atom+0x24 · q+0x24) |
| 0x10–0x12 | angA1 |
| 0x13 | f32(q20/K1) |
| 0x14–0x16 | angB1 |
| 0x17 | inv11 = f32(f·K0) |
| 0x18 | inv01 = f32(−c·f) |
| 0x19 | maxImpulse = f32(q+0x18 · base) |
| 0x1A | pointer atom+0x18 |
| 0x1B | not written |

## 5. Rolling (n > 1; 0xA21E3E–0xA221B2)

`st=[eps, nf.x, nf.z, nf.y]` at 0xA21E3E. `ecx` = R+0x60. `[esp+0x5C]` = atom+0x18. P.

```
if (byte atom+0x10 & 4) == 0: goto USE_CACHED (0xA21F60)        // info.flags bit 2 (mask 4)
// recompute the radius (0xA21E48–0xA21F4A)
atom+0x14 = +0.0
for i = 0 .. n-1 (counter n-1 down to 0, jns; pointer atom+0x38 + 32i = &cp[i].pos.z):
    d = ( f32(pos.x - c.x), f32(pos.y - c.y), f32(pos.z - c.z) )       // pos - centre
    r2 = f32( (d.y*d.y + d.x*d.x) + d.z*d.z )                         // 0xA21EB9–0xA21EDC
    rt = f32( sqrt(r2) )                                              // _CIsqrt
    atom+0x14 = f32( rt + atom+0x14 )                                 // the running sum lives in atom+0x14
radius = f32( invN * atom+0x14 ); atom+0x14 = radius                  // 0xA21F24–0xA21F36
fcomp dword [0xBEAB0C] (radius vs 1e-6); test ah,5; jnp 0xA221BB
   radius < 1e-6 (strict, ordered): *w = esi (R+0x70, the 0x15 record stands); return.   Flag bit 2 stays set and
                                    atom+0x14 keeps the small radius.
   radius >= 1e-6 or NaN: atom+0x10 &= 0xFFFB (clear bit 2); fld eps  (st=[eps, nf.x, nf.z, nf.y])
   (0xA21F50 re-tests bit 2 and jumps back to 0xA21E51 when it is set. Right after the `and`, that jump is never taken.)
USE_CACHED (0xA21F60):
inv_r = f32( 1.0 / atom+0x14 )        // fld radius; fld1; fdivrp (de f1)   [esp+0x28]
[esp+0xC] = q20
```
P. (d.y² + d.x²) gives the same bits as (d.x² + d.y²).

Rolling rows (0xA21F79–0xA2208A), P:
```
R[0x18..0x1A] = A.identity ? nf.xyz : M_A·nf     // row k: f32((c60[k]*nf.y + c50[k]*nf.x) + c70[k]*nf.z)
R[0x1B] = nf.w (A identity) or +0.0 (A not identity)   -- temp, overwritten below
B identity:     R[0x1C..0x1E] = (-nf.x, -nf.y, -nf.z)   (fchs each);  R[0x1F] = -nf.w (temp)
B not identity: v = (-nf.x, -nf.y, -nf.z) (fchs BEFORE the multiply, stored [0xB0..0xB8])
                R[0x1C..0x1E] = M_B·v, row k: f32((c60[k]*v.y + c50[k]*v.x) + c70[k]*v.z);  R[0x1F] = +0.0 (temp)
```
Negation is exact and round-to-nearest is symmetric, so M_B·(−nf) gives the same bits as −(M_B·nf). I.

K2 and the rest (0xA2208D–0xA221B2), P:
```
qA_j = f32(R[0x18+j]²); qB_j = f32(R[0x1C+j]²)
sA_j = f32(A.invI_j*qA_j); sB_j = f32(qB_j*B.invI_j); s_j = f32(sB_j + sA_j)
K2' = f32( (s_y + s_x) + s_z )          // no mass terms
K2  = f32( K2' + eps )                  // fadd st,st(2): eps is the qword value still on the stack
R[0x1B] = f32( f32(q20 / K2) * inv_r )   // fdiv dword [0xC] = q20/K2 -> fstp; fld; fmul [0x28] -> fstp   (VERIFIED)
R[0x1F] = f32( atom+0x2C * q+0x24 )      // rhsRoll, through [esp+0xF8] = R (+0x7C)
R[0x20] = inv01; R[0x21] = maxImp; R[0x22] = atom+0x14 (radius); R[0x23] = (u32) atom+0x18
R[0] = f32( eps + R[0] ); byte R[0] = 0x16     // second ε-add on top of the 0x15-tagged value
*w = R + 0x90; return
```

### Record 0x16 (144 B), float index → content
| [i] | Content |
|---|---|
| 0 | f32(f32(d0.x+eps)\|0x15-byte + eps) with low byte = 0x16 |
| 1–0x17 | as in 0x15 |
| 0x18–0x1A | rolling angA = M_A·nf (A identity: nf). This overwrites the 0x15 inv01 / maxImp / pointer |
| 0x1B | f32(f32(q20/K2)·f32(1/radius)) |
| 0x1C–0x1E | rolling angB = M_B·(−nf) (B identity: −nf) |
| 0x1F | rhsRoll = f32(atom+0x2C · q+0x24) |
| 0x20 | inv01 |
| 0x21 | maxImpulse |
| 0x22 | radius (atom+0x14) |
| 0x23 | pointer atom+0x18 |

## 6. Constants used in this range

| VA | Load | Bits | Value | Use |
|---|---|---|---|---|
| 0xBEAA68 | qword | 0x3E80000000000000 | 2^-23 = 1.1920928955078125e-7 | K0/K1/K2 + eps; opcode ε-adds |
| 0xB59D28 | qword | 0x3FEFFF2E40000000 | 0.99989998340606689453125 (= f32(0.9999) widened) | P = S·iN2 test |
| 0xB57F98 | qword | 0x3FB99999A0000000 | 0.100000001490116119384765625 (= f32(0.1)) | S test, T2 re-pick test |
| 0xB59C18 | qword | 0x3FECCCCCC0000000 | 0.89999997615814208984375 (= f32(0.9)) | L2 degenerate test |
| 0xBEA968 | qword | 0 | 0.0 | t.w = inv·0.0 |
| 0xBEAB0C | dword | 0x358637BD | 9.99999997e-7 (f32 1e-6) | radius minimum |
| 0xBF65A0 | dword[12+] | (1,0,0,0)(0,1,0,0)(0,0,1,0) | identity rows | friction axis e |
| `fld1` | — | — | 1.0 | 1/sqrt, 1/radius, degenerate nf.y |

The qwords 0.9999 / 0.1 / 0.9 are f32 values widened to f64, not the nearest doubles. A port must compare against these
exact f64 values. P (xxd 0x759D28 / 0x757F98 / 0x759C18).

## 7. Writes to *w (the schema cursor) and exits

`*w` is read once at 0xA20A15 and written only at the four exits (no other store goes through `[ebp+0x14]`, P):

| Exit | Condition | *w = |
|---|---|---|
| 0xA221E1 | not (0 < base) (incl. NaN) | esi after the contact rows (header + contact records). No friction record. |
| 0xA221CD | n ≤ 1 | R + 0x70 (0x15 record) |
| 0xA221BB | n > 1, flag bit 2 set, recomputed radius < 1e-6 | R + 0x70 (0x15 record) |
| 0xA221B2 | otherwise | R + 0x90 (0x16 record) |

Atom writes in this range: +0x12 (axis, re-pick only), +0x1C and +0x24 (= +0.0, re-pick only), +0x14 (radius sum and
radius, recompute only), +0x10 (bit 2 cleared). P.

## 8. Corrections to the spec (contact_solve.md), where the spec disagrees with the asm

1. §6.4 (pair) and, implicitly, §6.6: the 2×2 denominator is **not** rounded to f32. `f = f32(q20 / (K0·K1 − c²))` keeps
   K0·K1, c² and their difference extended. Friction path: 0xA21DA8–0xA21DBF. Pair path: 0xA21129–0xA2114D, with no store
   between `fsubrp st(4)` (de e4) and `fdivrp st(3)` (de f3). So §6.4's `f32(prevK*K - c*c)` is wrong. The pair range
   belongs to the loop agent and was read here only to trace the stack.
2. §6.6 rolling: "bit 4 stays set / clear bit 4" should read **bit 2 (mask 0x4)** (`test byte [atom+0x10],4` at
   0xA21E3E; `and word [atom+0x10],0xFFFB` at 0xA21F4A).
3. §1.10 / §6.5: the decimals "0.9999 / 0.1 / 0.9" are not the compared values. The qwords are f32 values widened to
   f64: 0x3FEFFF2E40000000, 0x3FB99999A0000000, 0x3FECCCCCC0000000 (§6). A port that uses the nearest doubles flips at
   the boundary.
4. §6.5 "(no friction rows; w unchanged)" is ambiguous. `*w` **is** written on that exit, set to the cursor after the
   contact rows (0xA221E1–0xA221E9). The function writes `*w` only at its four exits.

## 8a. Additions and confirmations (not disagreements)

- The 0.9999 compare uses the unstored extended product S·iN2 (0xA2121E–0xA21224).
- NaN routing:
  - a NaN P goes to the 0.1 test;
  - a NaN S goes to branch C;
  - a NaN L2 keeps cp[0].normal;
  - a NaN T2 re-picks;
  - "ay vs ax" unordered counts as ay ≤ ax, and an unordered second compare gives axis 2.
- Degenerate branch: base = 0 still emits the friction record, with maxImpulse = f32(q18·0) (0xA21341).
- Coupling c: the exact tree is in §4, with per-lane f32 products and R[0] read before its ε/opcode tag. There is no 0.99
  factor; the grep is cited in §4.
- Rolling: `[0x1B] = f32(f32(q20/K2)·f32(1/radius))` is confirmed. K2 = f32(f32((s_y + s_x) + s_z) + eps). In 0x16,
  [0x18..0x1A] (0x15's inv01 / maxImp / pointer) are overwritten by rolling angA, and those three move to [0x20], [0x21],
  [0x23]. On the < 1e-6 exit, atom+0x14 already holds the small radius (fst 0xA21F36).

## 9. ND

- The `_CIsqrt` body (MSVCR80) was not read. This is non-blocking (I): every sqrt input here (S, T2', r2) is a stored
  f32, and every result is stored straight to f32. A correctly rounded f64 or extended sqrt, rounded to f32, equals the
  correctly rounded f32 sqrt (double rounding is harmless when p ≥ 2q+2). So the port's f64 sqrt then f32 matches bit for
  bit whether the CRT uses `fsqrt` at PC=53 or `sqrtsd`. Only NaN payloads could differ.
- (Settled) Row 3 of 0xBF65A0 is (0,0,0,1) in the file bytes (xxd 0x7F65D0), so index 3 gives e.xyz = 0, t = 0,
  T2 = 0 and a re-pick (the T2 compare 0 ≤ 0.1). P.
- Whether n = 0 can reach this range depends on the loop (do-while entry at 0xA20A90). It is the loop agent's to settle.
  If it can, invN = +inf and base = 0·inf = NaN, which exits at 0xA211DE. I.
