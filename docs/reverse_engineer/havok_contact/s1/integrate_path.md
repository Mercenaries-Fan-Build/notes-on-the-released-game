# Solver-path integration: FUN_008EDCF0, FUN_008EE2D0 (type 4), FUN_008FD040, hkpFixedRigidMotion (pc-v10)

Exe `game-files/canonical/dumps/mercs2_unpacked.exe`. Disassembly (objdump, Intel) in this folder:
`ip_dcf0.txt` (0x8EDCF0–0x8EE2D0), `ip_e2d0.txt` (0x8EE2D0–0x8EF520), `ip_d040.txt` (0x8FD040–0x8FD800),
`ip_c5b0.txt` / `ip_c5b0_head.txt` (FUN_008EC5B0), `ip_3ad0.txt`, `ip_eb30.txt`, `ip_8f4740.txt`, `ip_8df590.txt`,
`ip_8ddc80.txt`, `ip_vt1.txt`, `ip_9001b0.txt`. Mechanical instruction diffs against FUN_008EC5B0 (`ip_norm.py`):
`ip_cmp_guard.txt`, `ip_cmp_integ.txt`, `ip_cmp_deact.txt`. Constants: `ip_consts.txt`, `ip_consts2.txt`,
`ip_constdec.txt`. Splice emulation: `ip_emu_scan2.txt`, `ip_emu_8fd13d.txt`, `ip_emu_8ef484.txt`. Capture reads
(winch capture `20261021_chris-jacobs-flying-winch.dmp`): `ip_cap1.txt`, `ip_cap2.txt`, `ip_cap3.txt`.

Notation as in the brief: `f32(e)` = e evaluated on the x87 stack (f64 in the port) and stored as a dword; `x87(e)` =
an intermediate that is not stored. `m` = entity+0xD0 (the motion), `a` = the accumulator record (0x80 bytes).
`R[c][r]` = motion rotation column c, row r = `m+0x10+0x10c+4r`. All grades are P unless marked.

## Constants (read this run, `ip_consts.txt`, `ip_constdec.txt`)

| VA | Load | Bits | Value | Use |
|---|---|---|---|---|
| 0xCDCA20/24/28/2C | dword | 0x49742400 ×4 | 1.0e6 | finiteness bound, one per lane |
| 0xBF65A0..AC | dword ×4 | 0x3F800000, 0, 0, 0 | (1,0,0,0) | velocity reset |
| 0xBEA940 | qword | 0x3FE0000000000000 | 0.5 | half step |
| 0xBEA968 | qword | 0 | 0.0 | translation.w |
| 0xB59C20 | qword | 0x3FD9F02F49EA9737 | 0.40528471201320165 | 4/π² |
| 0xB59C18 | qword | 0x3FECCCCCC0000000 | 0.8999999761581421 | angle-limit cap (compare) |
| 0xB596B4 | dword | 0x3F666666 | 0.9f | angle-limit cap (value) |
| 0xB59C10 / 08 / 00 | qword | 0x3FEA559700000000 / 0x3FC0B52CA0000000 / 0x3FA6BCA540000000 | C1 0.8229479789733887 / C2 0.1305290013551712 / C3 0.04440800100564957 | quaternion w cubic |
| 0xB59660 | qword | 0x400921FB60000000 | 3.1415927410125732 | deltaAngle.w |
| 0xB59BF0 | qword | 0x3F819999A0000000 | 0.008593750186264515 | packed-quaternion unpack |
| 0xBEAA68 | qword | 0x3E80000000000000 | 2⁻²³ (FLT_EPSILON) | goto-header float (FD040) |
| 0xB13380 + 4·i | dword | table | hkUFloat8 decode | maxLin / maxAng |

`0x9EE730` (the square root every path calls) is `jmp [0xB053AC]`, an import thunk (`ip_sqrt.txt`). Its body is not in
the image. FUN_008EC5B0 calls the same thunk, and integrate.rs reproduces that function bit-exact with f64 sqrt, so the
port treats it as x87 `fsqrt` at 53 bits (I, carried from the 8EC5B0 replay; not re-proven here).

---

## 1. FUN_008EDCF0(stepInfo, ents, n, 0xD0, acc) — accumulator build (cdecl)

Arguments: `[ebp+8]` stepInfo (+0 start, +8 dt), `[ebp+0xC]` ents (pointer array), `[ebp+0x10]` n, `[ebp+0x14]` 0xD0
(motion offset), `[ebp+0x18]` acc (FD040 passes &acc[1]). Locals: `[esp+0x14]` = loop counter n−1, `[esp+0x10]` /
`[esp+0x18]` / `[esp+0x1C]` f32 temporaries. In the loop esi = a+0x68, edi = m, ecx = a.

**Entry and the persistent constants (0x8EDCF9–0x8EDD18).** If n−1 < 0, it returns acc (0x8EE296). Otherwise it pushes
fld1, fldz, fldz, fld1, so the stack at the loop top is st0..st3 = (1, 0, 0, 1). Every path restores that shape before
0x8EDF63. The constants are all exact (0.0, 1.0), so the shuffling has no numeric effect.

**Jump table 0x8EE2A0 (motion type byte m+0x08, `ja` past 9 → 0x8EDF63):**

| Type | Target | Path |
|---|---|---|
| 0, 4, 5, 8 | 0x8EDD36 | box / dynamic |
| 1 | 0x8EDF63 | nothing written; acc and esi advance |
| 2, 3 | 0x8EDF97 | type byte 0, sphere path |
| 9 | 0x8EDF92 | type byte 2, then the sphere path |
| 6 | 0x8EE1EE | keyframed |
| 7 | 0x8EE18D | fixed |

### 1.1 Box path 0x8EDD36–0x8EDF61

```
0x8EDD39  fstp st0                                   // stack (0, 0, 1)
0x8EDD3B  dt  = f32(stepInfo+8)                        // [esp+0x10], exact copy
0x8EDD42  lf  = f32(1.0 − x87(m+0xB4 linearDamping · dt))   // fmulp st2 (de ca) then fsubrp st2 (de e2): 1 − (linD·dt)
0x8EDD5A  fld lf; fcom st(3) (= 0.0); fnstsw; test ah,5; jp keep
          // jp taken (keep lf) when C0=C2=0 (lf > 0 or lf == 0) or unordered (C0=C2=1: NaN is kept)
          // not taken only when lf < 0: lf := 0.0 (fst of the 0.0 at 0x8EDD6B)
0x8EDD77  v[k] = f32(lf · m[0xD0+4k]), k = 0..3      // stored back to m+0xD0..0xDC; the w lane is included
0x8EDDB5  af  = f32(1.0 − x87(m+0xB8 angularDamping · dt))  // fmulp st2, then fsubrp st1 (de e1): st0 − st1 = 1 − angD·dt
0x8EDDC9  fcom st(1) (= 0.0); test ah,5; jp keep    // same rule: af < 0 → 0.0, NaN kept
0x8EDDE1  ω[k] = f32(af · m[0xE0+4k]), k = 0..3      // stored back to m+0xE0..0xEC; w included
          // x87 stack is empty from here to the call
0x8EDE1F  FUN_00893AD0(ecx = a+0x50, push m+0x10)     // transpose, §1.2
0x8EDE27  byte a+0x00 = 0                             // type: dynamic
0x8EDE2A  a+0x30..0x3C = m+0xC0..0xCC (fld/fstp)      // invInertia x,y,z, invMass
0x8EDE51  a+0x10..0x1C = m+0xD0..0xDC (fld/fstp)      // the damped linear velocity, 4 lanes
0x8EDE75  frac = f32(x87(stepInfo+0 start − m+0x5C com0.w) · m+0x6C com1.w)   // fsub then fmul, no store between
0x8EDE81  omf  = f32(1.0 − frac)                      // fld1; fld st0; fsubrp st2 (de e2): 1 − frac; frac reloaded as f32
          // the extra 1.0 stays on the stack through the COM block
0x8EDE93  a+0x40 = f32(m+0x50·omf + m+0x60·frac)        // x lane: com0.x·omf + com1.x·frac
0x8EDEAA  a+0x44 = f32(m+0x54·omf + m+0x64·frac)
0x8EDEB9  a+0x48 = f32(m+0x58·omf + m+0x68·frac)
0x8EDEC8  a+0x4C = f32(omf·m+0x5C + frac·m+0x6C)        // w lane: com0.w·omf + com1.w·frac
          // products are not rounded; one add; stores f32. Operand order differs only by commutation.
0x8EDED7  wx = m+0xE0, wy = m+0xE4, wz = m+0xE8         // f32 copies [esp+0x18], [esp+0x10], [esp+0x1C]
0x8EDEF5  a+0x20 = f32((a+0x60 · wy + a+0x50 · wx) + a+0x70 · wz)
0x8EDF1D  a+0x24 = f32((a+0x64 · wy + a+0x54 · wx) + a+0x74 · wz)
0x8EDF33  a+0x28 = f32((a+0x68 · wy + a+0x58 · wx) + a+0x78 · wz)
0x8EDF46  a+0x2C = 0.0                                 // fldz; fst
0x8EDF4D  byte a+0x01 = 0
0x8EDF51  dword a+0x04 = u32(u8 m+0xBE)                // deactivation class, movzx then mov
```

The association of a+0x20..0x28 is "(y-term + x-term) + z-term" in all three lanes. Since IEEE addition commutes, this is
bit-identical to `(x-term + y-term) + z-term`. With the transpose of §1.2, a+0x20 = Rᵀ·ω: lane j = (R[j]·ω), the dot product
of motion column j with ω.

Bytes a+0x02, a+0x03 and dwords a+0x08, a+0x0C are not written (P: no store in 0x8EDD36–0x8EDF61).

### 1.2 FUN_00893AD0(ecx = dst, [esp+4] = src) — transpose (`ip_3ad0.txt`, 0x893AD0–0x893B13, ret 4)

The copies are fld/fstp, so they are exact:

| dst | src |
|---|---|
| +0x00 | +0x00 |
| +0x04 | +0x10 |
| +0x08 | +0x20 |
| +0x10 | +0x04 |
| +0x14 | +0x14 |
| +0x18 | +0x24 |
| +0x20 | +0x08 |
| +0x24 | +0x18 |
| +0x28 | +0x28 |

dst +0x0C, +0x1C and +0x2C are 0.0. The source w lanes are not read.

Result: a+0x50+0x10j+4i = R[i][j] (= m+0x10+0x10i+4j). So column j of the accumulator matrix is row j of R, i.e.
acc+0x50/+0x60/+0x70 = Rᵀ. The w lanes a+0x5C, a+0x6C and a+0x7C are 0.

### 1.3 Loop advance and return (0x8EDF63–0x8EDF91, 0x8EE296)

On every iteration (all types, including type 1): `ents += 4`, `acc += 0x80`, `esi += 0x80`, counter −1, and the result is
stored back to `[ebp+0x18]`. At the end it pops the 4 constants and returns **eax = acc + 0x80·n**, the record after the
last one. For n == 0 it returns acc unchanged. FD040 writes the end marker there: **one byte, 3**, at 0x8FD318.

### 1.4 Types 7 (fixed), 6 (keyframed) and 1 when passed

- **Type 7, 0x8EE18D–0x8EE1E9:**
  - byte a+0 = 1, byte a+1 = 1;
  - 0.0 to a+0x10..0x1C, a+0x20..0x2C, a+0x30..0x3C, a+0x40..0x4C and **all of a+0x50..0x7C**, so the matrix is all zero,
    not identity;
  - a+0x04 (class) is **not written**. Motion velocities are not touched and nothing is damped.
- **Type 6, 0x8EE1EE–0x8EE291:**
  - byte a+0 = 1, a+1 = 1;
  - a+0x30..0x3C = 0;
  - a+0x40..0x4C = com1 (m+0x60..0x6C);
  - a+0x20..0x2C = m+0xE0..0xEC (world ω, not rotated);
  - a+0x10..0x1C = m+0xD0..0xDC;
  - a+0x50..0x7C = 0, then 1.0 at a+0x50, a+0x64 and a+0x78 (identity);
  - class not written; no damping.
- **Type 1, 0x8EDF63:** the record is left as it was (not written at all). FD040 still assigns that entity solverData =
  (k+1)·0x80, so the solver would read a stale record (I: consequence, not exercised).

**Does FD040 pass fixed bodies?** It passes the island's own entity list: FUN_009001B0 0x900400–0x90041D pushes
`[esp+0x24]`/`[esp+0x1C]`, which are island+0x48 / +0x4C on the 8EC5B0 path at 0x90036C. In the winch capture the boat
island 0x1C8A6A00 has +0x48 → inline array {0x1DF9D000 (boat)} and +0x4C = 1 (`ip_cap1.txt`). The terrain 0x1E45C800
(type 7) is not in it, and its +0x90 solverData = 0, so the constraint's B side indexes **acc[0]**, the fixed accumulator
FD040 writes itself (P, capture). That fixed bodies are never members of an active island is the Havok design (I). The
type-7 path above is therefore not reached for the boat.

---

## 2. FUN_008EE2D0(si, step, acc1, ents, n, 0xD0) — solver-path integrator, type 4

Arguments, read from use:
- `[ebp+8]` si: +0x64 class records, +0x125 select flags;
- `[ebp+0xC]` step: +0 start, +8 dt, +0xC invDt;
- `[ebp+0x10]` acc1 = ebx, which advances 0x80 per entity at 0x8EF3F5;
- `[ebp+0x14]` ents, `[ebp+0x18]` n, `[ebp+0x1C]` 0xD0.

FD040 calls it at 0x8FD702 with (si = `[ebp+0xC]`, step = `[ebp+8]`, &acc[1], ents, n, 0xD0).

**Prologue and splice.** 0x8EE2D0 `push ebp; mov ebp,esp; and esp,−0x10`, then 0x8EE2D6 `jmp [0x2454F6C]`.
`mercs2_probe splice-emulate exe 0x8EE2D6 --steps 3000` runs the VM, enters game code at 0x513BF1 and continues at
0x8EE2DC (`ip_emu_8ee2d6.txt`, `ip_emu_scan2.txt`). 0x513BF1 is `sub esp, 0x124; jmp 0x8EE2DC` (`ip_gadget.txt`).
**So the stolen instruction is `sub esp, 0x124`, and the body continues at 0x8EE2DC (P).**

```
0x8EE2E4  result [esp+0x7C] = 0x7FFFFFFF; if n−1 < 0: return 0x7FFFFFFF (0x8EF40A, eax untouched)
0x8EE2FB  fld1                  // loop-top 1.0; the loop re-enters at 0x8EE2FD with one 1.0 on the stack
0x8EE300  esi = m = ents[i] + 0xD0; jump table 0x8EF414 on u8 m+0x08 (ja 9 → 0x8EEDA3)
```

Jump table 0x8EF414 (bytes read this run):

| Types | Target | Path |
|---|---|---|
| 0, 8 | 0x8EE319 | |
| 1, 7 | 0x8EEDA3 | skip to the post-clamps |
| 2, 9 | 0x8EE60B | |
| 3 | 0x8EE512 | |
| **4** | **0x8EE3C2** | box |
| 5 | 0x8EE497 | |
| 6 | 0x8EE55B | |

This matches the spec.

### 2.1 Type 4 velocities (0x8EE3C2–0x8EE492)

```
0x8EE3C2  fstp st0                                  // pops the loop-top 1.0; stack empty
0x8EE3C4  m+0xD0..0xDC = a+0x10..0x1C (fld/fstp, 4 lanes)          // stored v = solver's linear velocity
0x8EE3F4  aa = (a+0x20, a+0x24, a+0x28) copied to f32 temporaries ([esp+0x18], [esp+0x10], [esp+0x1C]
          relative to the frame before the two pushes at 0x8EE3D6/0x8EE3DD)
          eax = m+0x10 (R)
0x8EE409  m+0xE0 = f32((R[0][0]·aa.x + R[1][0]·aa.y) + R[2][0]·aa.z)
0x8EE437  m+0xE4 = f32((R[1][1]·aa.y + R[0][1]·aa.x) + R[2][1]·aa.z)
0x8EE450  m+0xE8 = f32((R[0][2]·aa.x + R[1][2]·aa.y) + R[2][2]·aa.z)
0x8EE469  m+0xEC = 0.0
```

The three groupings the spec gives are in the asm exactly as written. Every lane is (x-term ⊕ y-term) ⊕ z-term
up to commutation of the first add, so all three are bit-identical to
**ω_k = f32((R[0][k]·aa.x + R[1][k]·aa.y) + R[2][k]·aa.z)**. That is R·aa with R as the motion's start-of-step rotation (m+0x10
before this step's rebuild). The products are not rounded.

```
0x8EE471  pl = a+0x40..0x4C (fld/fstp, 4 lanes) → local [esp+0x20..0x2C]
0x8EE48D  pa = FUN_0088EB30(ecx = &local[esp+0x30], R = m+0x10, v = a+0x50)  → local [esp+0x30..0x3C]
```

**FUN_0088EB30 (`ip_eb30.txt`, 0x88EB30–0x88EBAB, thiscall, ret 8).** Args `[esp+4]` = R (eax at 0x88EB46) and `[esp+8]` = v.

```
v.x → [esp], v.y → [esp+0x10] (the arg slot), v.z → [esp+4]   // f32 copies; v.w (a+0x5C) is not read
out.x = f32((R[0][0]·v.x + R[1][0]·v.y) + R[2][0]·v.z)      // 0x88EB4E–0x88EB75
out.y = f32((R[1][1]·v.y + R[0][1]·v.x) + R[2][1]·v.z)      // 0x88EB77–0x88EB8A
out.z = f32((R[0][2]·v.x + R[1][2]·v.y) + R[2][2]·v.z)      // 0x88EB8D–0x88EBA0
out.w = 0.0                                                // 0x88EBA3
```

This is instruction for instruction the same sequence as the inline ω block above (and the same as integrate.rs's
`rotated_com_local` grouping). So pa_k = f32((R[0][k]·v.x + R[1][k]·v.y) + R[2][k]·v.z).

### 2.2 Finiteness guard (0x8EE68D–0x8EE991) on the local pl and pa

All eight lanes are tested, but only x, y, z count:

- **|lane| < 1e6.** For each of pl.x..pl.w and pa.x..pa.w: |lane| = f32(fabs) (exact) is compared with the dword at
  0xCDCA20+4k.
  - pl lanes: C at st0, |pl| at st1; `fcom/fcompp; test ah,0x41; je/jne` → bit set iff C > |pl| (strict; NaN fails).
  - pa lanes: |pa| at st0, C at st1; `fcompp; test ah,5; jnp` → bit set iff |pa| < C (strict; NaN fails).
  - The bits are x = 8, y = 4, z = 2, w = 1. mask_pl → `[esp+0x10]`, mask_pa & mask_pl → `[esp+0x1C]`.
- **lane == lane.** `fld x; fld st0; fucompp` (or `fucomp st(2)` for pa.x); `test ah,0x44; jnp/jp` → bit set iff not NaN.
  Same bit values: nan_pl and nan_pa.
- **Decision (0x8EE932):** `eax = nan_pa & nan_pl & abs_mask; and eax, 0xE; cmp al, 0xE; je ok`.
  - The w-lane bit (1) is computed but masked off.
  - **ok ⇔ for x, y, z of pl and of pa: |lane| < 1e6 and lane is not NaN.**
- **Fail (0x8EE945–0x8EE991):** local pl = local pa = (1, 0, 0, 0) from 0xBF65A0 (all 4 lanes of each).
  - **The stored v (m+0xD0) and ω (m+0xE0) are not touched by the guard.**
  - On exit the stack holds (pl.x, pl.y, pl.z) in both paths, reloaded from the f32 locals.

### 2.3 Linear move (0x8EE993–0x8EEA9C)

```
0x8EE993  m+0x50..0x5C com0 = m+0x60..0x6C com1 (fld/fstp); then m+0x5C com0.w = step+0 start
0x8EE9BA  L = f32((pl.x·pl.x + pl.y·pl.y) + pl.z·pl.z)          // stack copies of the f32 locals
0x8EE9D6  mL = UF8[u8 m+0xBC]
0x8EE9E1  fld L; fld st1; fmulp st2 → x87(mL·mL) (not rounded); fcom; test ah,0x41; jne skip
          // clamp iff L > mL·mL (C0=C3=0); equal, less and unordered skip
clamp 0x8EE9F0–0x8EEA5A:
          s = f32(sqrt(L))                          // 0x9EE730
          k = f32(f32(1/s) · mL)                    // fld1; fdivrp st1 (de f1) = 1/s, f32, ·UF8, f32
          pl[j] = f32(k·pl[j]), j = 0..3            // all four lanes of the LOCAL pl; the stored v is unchanged
0x8EEA60  dtf = f32(step+8)
          com1[j] = f32(pl[j]·dtf + com1[j]), j = 0..2       // fmulp then faddp with the f32 com1 lane
          m+0x6C = f32(dtf·pl.w + com1.w), then overwritten: com1.w = step+0xC invDt
```

### 2.4 Rotation (0x8EEA9F–0x8EED9E)

```
0x8EEA9F  q (local [esp+0x50..0x5C]) = rot1 m+0x80..0x8C (integer copy)
          rot0 m+0x70..0x7C = fld/fstp of q
0x8EEAE4  hdt = f32(step+8 · 0.5 /*qword 0xBEA940*/)
          ax = f32(hdt·pa.x); ay = f32(pa.y·hdt); az = f32(hdt·pa.z)     // → [esp+0x40], [0x44], [0x48]
0x8EEB11  x = f32(f32((ax·ax + ay·ay) + az·az) · 0.40528471201320165 /*qword*/)   // → [esp+0x1C]
0x8EEB3F  lim = f32(UF8[u8 m+0xBD] · step+8)
          fcom qword 0xB59C18; test ah,0x41; jne keep
          // replace iff lim > 0.8999999761581421 (strict; NaN keeps): lim := dword 0xB596B4 (0.9f)
0x8EEB66  lim → [esp+0x18]; l2 = f32(lim·lim)
0x8EEB74  fld x; fld l2; fcomp st1; test ah,1; jne limit
          // limit taken iff C0: l2 < x, or unordered
no limit 0x8EEB85–0x8EEBB3 (stack: x):
          x2 = f32(x·x)
          aw = f32(x87(((1 − C1·x) − C2·x2) − x2·(C3·x)))
          // 1 − C1x: fsubrp st1 (de e1) with a fresh fld1 (0x8EEB95)
          // −C2x2: fsubp st2 (de ea) = st2 − st0
          // −x2·(C3x): fmul C3 then fmulp st2, fsubrp st1 (de e1) = st0 − st1 = T − x2·C3x
limit 0x8EEBB8–0x8EEC5B:
          s = f32(sqrt(x)); fld1 (0x8EEBC5); f32(1/s) via fdivrp st2 (de f2); k = f32(f32(1/s) · lim)
          pa[j] = f32(k·pa[j]), j = 0..3            // LOCAL pa incl. w; dead afterwards
          ax = f32(ax·k); ay = f32(ay·k); az = f32(k·az)
          x = l2 (reloaded as f32)
          x2 = f32(x·x); aw = same cubic
          // the 1.0 in (1 − C1x) is the one pushed at 0x8EEBC5 (fsubp st2 at 0x8EEC41)
0x8EEC5D  local a = (ax, ay, az, aw) at [esp+0x40..0x4C]
          FUN_00423F80(ecx = &q, push &q, push &a)           // q = a ⊗ q, the same call shape as 8EC5B0 0x8ED7E2–0x8ED7EC
          FUN_00423EB0(ecx = &q)                             // normalize (SSE), as integrate.rs `normalize`
0x8EEC79  m+0xA0 = f32(ax+ax); m+0xA4 = f32(ay+ay); m+0xA8 = f32(az+az); m+0xAC = f32(aw+aw)
0x8EECA9  m+0xAC = f32(f32(sqrt(x)) · 3.1415927410125732 /*qword 0xB59660*/)
0x8EECCC  rot1 m+0x80..0x8C = q (fld/fstp)
0x8EECE8  FUN_0088D070(ecx = m+0x10, push m+0x80)           // R from rot1 (as integrate.rs quat_to_matrix)
0x8EECED  c = comLocal m+0x90, 0x94, 0x98 → f32 slots ([esp+0x18], [esp+0x10], [esp+0x1C])
          rx = f32((R[1][0]·c.y + R[0][0]·c.x) + R[2][0]·c.z)
          ry = f32((R[1][1]·c.y + R[0][1]·c.x) + R[2][1]·c.z)
          rz = f32((R[0][2]·c.x + R[1][2]·c.y) + R[2][2]·c.z)
0x8EED6E  m+0x40 = f32(com1.x − rx); m+0x44 = f32(com1.y − ry); m+0x48 = f32(com1.z − rz)
          m+0x4C = f32(com1.w − 0.0 /*qword 0xBEA968*/)
0x8EEDA1  fld1                                                // re-push for the shared tail
```

### 2.5 Post-clamps on the stored velocities (0x8EEDA3–0x8EF06B)

These run for every type: types 1/7 jump straight to 0x8EEDA3 with the loop-top 1.0 still on the stack. Type 8 first runs
0x8EEDAD–0x8EEE4F (not transcribed; not the box).

```
0x8EEE51  V = f32((v.x² + v.y²) + v.z²)  over m+0xD0..0xD8   // the asm adds (vy² + vx²): same bits
          W = f32((ω.x² + ω.y²) + ω.z²)  over m+0xE0..0xE8
          mA2 = f32(UF8[m+0xBD]²)  → [esp+0x14]
          mL2 = f32(UF8[m+0xBC]²)  → [esp+0x1C]      // squares rounded to f32 before the compare
0x8EEECD  fld mL2; fcomp st1 (V); test ah,5; jnp clampV
          // jnp taken iff exactly C0: mL2 < V
          // otherwise (mL2 ≥ V, or unordered) → 0x8EEEDA: fld V; fld V; fucompp; test ah,0x44;
          //   jnp 0x8EEF9B (V not NaN: no clamp) — V NaN falls into clampV
clampV 0x8EEEEB:
          fstp st1                               // drops the 1.0 under V
          s = f32(sqrt(V)); k = f32(f32(1/s) · UF8[m+0xBC])   // fld1 at 0x8EEF01, fdivrp st2 (de f2)
          m+0xD0 = f32(v.x·k); m+0xD4 = f32(k·v.y); m+0xD8 = f32(k·v.z); m+0xDC = f32(k·v.w)   // 4 lanes
0x8EEF5A  NaN self-test of V: fld V; fld st0; fucompp; test ah,0x44; jnp done
          // V NaN → 0x8EEF69: m+0xD0..0xDC = (1, 0, 0, 0) from 0xBF65A0
          // both paths end at 0x8EEF9D with one 1.0 on the stack
0x8EEF9D  the same for ω:
          fld W; fld mA2; fcomp st1; test ah,5; jnp clampW (mA2 < W)
          else self-test W, NaN → clampW, else 0x8EF06B fstp st0
clampW 0x8EEFBF: k = f32(f32(1/f32(sqrt W)) · UF8[m+0xBD]); m+0xE0..0xEC = f32(k·ω[j]), 4 lanes
          then the NaN self-test of W → m+0xE0..0xEC = (1, 0, 0, 0) (0x8EF039)
```

**Ghidra drops two branches here:**
- the V-NaN entry into the clamp (0x8EEEDA–0x8EEEE5), and the W-NaN entry (0x8EEFAE–0x8EEFB9);
- the resets 0x8EEF69 and 0x8EF039.

They are reachable only for a NaN squared length. For such a V, the clamp makes v NaN and then the reset writes
(1,0,0,0). The port must keep them.

### 2.6 Deactivation (0x8EF06D–0x8EF3CD) and result (0x8EF3CF–0x8EF410)

Compared instruction by instruction with FUN_008EC5B0 0x8ED94C–0x8EDCB9 (`ip_cmp_deact.txt`). The only differences are:
- register allocation (ebx ↔ edx, ecx ↔ eax);
- stack-slot offsets;
- 8EC5B0 reads ω through ebx = m+0xE0 (set at 0x8ED260, unchanged up to 0x8ED9A2), while 8EE2D0 reads m+0xE0 directly;
- the order in which the f32 lanes of d and dq are pushed (8EC5B0: x, y, z(, w); 8EE2D0: y, x, z(, w)). The tree is the
  same, (d_a² + d_b²) + d_z² (+ d_w²), with only the first add's operands swapped. IEEE add commutes, so it is **bit-identical**;
- the unpack of the packed orientation: 8EC5B0 stores all four unpacked lanes and then subtracts; 8EE2D0 interleaves. Each
  lane is the same f32(f32(int·S) − rot1) (P).

Every compare, mask, branch sense, constant and store matches. **So integrate.rs `update_deactivation` /
`sample_deactivation` (counter +0x09, the 0x100 → 0xFF case, idx 0/1, energy, refPos.w max, distance and rotation tests,
the u16 count arithmetic, refPos = (com1, 0), refOri = FUN_00A06EA0(rot1)) is exactly this code.**

The 1.0 on the stack enters the sample as the comparand for the radius min (0x8EF0AE). It is consumed there, and 0x8EF3CD
re-pushes it. The non-sampling exits (0x8EF079, 0x8EF092) go to 0x8EF3CF with the 1.0 still present.

Result: `r = max(u8 m+0x0A & 0x7F, u8 m+0x0C & 0x7F)` (`cmp ecx,eax; jle`). If result ≥ r, result = r (i.e.
result = min(result, r)). Then ents += 4, ebx += 0x80, loop. At the end it pops the 1.0 and returns **eax = result**
(0x7FFFFFFF for n = 0), the same as 8EC5B0.

### 2.7 Differences from FUN_008EC5B0's common integrate (0x8ED25A–0x8ED943 = integrate.rs `integrate_motion`)

These come from the mechanical diffs `ip_cmp_guard.txt` and `ip_cmp_integ.txt`. The only differences are the ones
§3.4's table lists. In detail:
1. **The guard tests pl/pa (locals), not the stored v/ω.** On failure it resets the locals only. Same 0xE mask, same
   strict / NaN semantics.
2. **The linear clamp scales the local pl** (4 lanes), not m+0xD0. It uses the same f32(f32(1/s)·mL) and the same strict
   L > x87(mL²). The sequence differs in one instruction: fld1; fdivrp st1 instead of fld1; fld st0; fdivrp st2. The value is
   the same 1/s.
3. **com1 += pl·dt**: 8EE2D0 forms pl.x·dt, 8EC5B0 forms dt·v.x (commutes).
4. **The angle source is pa**, not ω. The limit branch scales pa (dead) where 8EC5B0 scales the stored ω. The no-limit
   branch is inlined in 8EE2D0 where 8EC5B0 jumps to a shared tail (0x8ED7DA). The formulas are identical, and so are the
   x² sum order (commuted first add) and the quaternion product call shape.
5. **The post-clamps of §2.5 exist only in 8EE2D0.**
6. **The stored velocities come from the accumulator:** v = acc+0x10 copied, ω = R_start · acc+0x20. 8EC5B0 instead has
   gravity + damping on the stored values.

Nothing else differs: the rotation, deltaAngle, R rebuild, translation and deactivation are the same arithmetic.

**Persistent fld1 (correction of detail).** The loop-top 1.0 (0x8EE2FB, and re-entry at 0x8EE2FD) is popped or consumed on
entry to every typed path:
- types 0/8 use it as the dividend of 1/invI and 1/invMass (0x8EE322–0x8EE372);
- the others pop it (`fstp st0`).

It is re-pushed at 0x8EEDA1 for the shared tail and at 0x8EF3CD after a sample. The 1.0 consumed by the a.w cubic at
0x8EEC41 is the local fld1 of 0x8EEBC5; the no-limit branch uses its own fld1 at 0x8EEB95. Every one of these is exactly
1.0, so this has no numeric effect.

---

## 3. FUN_008FD040(stepInfo, si, q, island, ents, n) — StSolver_1Cpu, entry to the 0x8FD717 AABB call

Arguments (cdecl), from the caller FUN_009001B0 0x900400–0x90041D and from use:
- `[ebp+8]` stepInfo (world+0x190): passed as stepInfo to 8EDCF0 and 8EE2D0;
- `[ebp+0xC]` si (= stepInfo+0x10, world+0x1A0);
- `[ebp+0x10]` q (job+0x80);
- `[ebp+0x14]` island;
- `[ebp+0x18]` ents (island+0x48);
- `[ebp+0x1C]` n (island+0x4C).

That X = world+0x190 is I, through the 8EC5B0 call at 0x90036C–0x900386, which pushes (X+0x10, X, X+0x30, …).

### 3.1 Buffer (0x8FD04C–0x8FD25D)

```
accBytes   = n·0x80 + 0x90               // [esp+0x40]; = (n+1)·0x80 records + 0x10 (room for the end byte)
schemaSize = island+0x0C + 0x10          // [esp+0x48]
elemSize   = 4·island+0x14 + 8           // [esp+0x24]
total      = accBytes + schemaSize + elemSize
```

The thread's stack allocator is reached through `TlsGetValue([0xDFE750])` (`[0xB0511C]`):
- total is clamped to (alloc+0x2C − alloc+0x20 − 0x10);
- it bump-allocates (total+0x10)&~0xF at alloc+0x20, or calls alloc vtbl+0x14 if that overflows;
- base → `[esp+0x38]`.

Layout: acc = base (ebx), schemas = base + accBytes (`[esp+0x3C]`), elemTemp = schemas + schemaSize (`[esp+0x2C]`), and
schema limit `[esp+0x18]` = elemTemp. If elemTemp + elemSize ≤ base + total, it goes to **0x8FD262**: the normal case, and
the boat's.

**The split path (buffer too small), structure only (I for the exact sizing).**
- If even the schemas would start past the end (0x8FD217), the whole layout is re-allocated as a second block
  (`[esp+0x34]`) and laid out again.
- If only elemTemp does not fit (0x8FD1D2), elemTemp is allocated separately.
- Otherwise (0x8FD12D–0x8FD1CD):
  - the first buffer keeps the schemas up to limit = end − (island+0x08 + 0x10);
  - a second block of (island+0x0C − room + island+0x08 + 0x10 + elemSize) is allocated;
  - `[esp+0x28]` = its start (the goto target), and elemTemp follows the second schema region.
- The SecuROM splice at **0x8FD13D** (`jmp [0x244FF60]`) is in this path. splice-emulate enters game code at 0x4C0C8B, a
  gadget that decodes a pointer, executes `mov edx, [0xDFE750]` (the TLS index) and jumps to 0x8FD143 (`ip_emu_8fd13d.txt`:
  read [0xDFE750] at eip 0x4C0C9C; `ip_gadget2.txt`). **Stolen instruction: `mov edx, dword ptr [0xDFE750]`; continuation
  0x8FD143 (P).**

`[esp+0x28]` is 0 unless the split path ran (0x8FD07D). `[esp+0x34]` (second block, freed at the end) is 0 unless an extra
block was allocated (0x8FD079).

### 3.2 Fixed accumulator 0 (0x8FD262–0x8FD2C1)

```
byte acc+0x00 = 1;  byte acc+0x01 = 1
acc+0x10 .. acc+0x7C (all 28 dwords) = 0.0      // fldz; fst ×27; fstp
```

**Not written:** bytes +0x02/+0x03 and dwords +0x04/+0x08/+0x0C. The class at +0x04 is stale. The matrix is all zeros, not
identity.

### 3.3 solverData (0x8FD2C4–0x8FD2F0)

`for k in 0..n−1: if ents[k]+0x90 != 0x80·(k+1) then ents[k]+0x90 = 0x80·(k+1)` (conditional store). Capture: boat +0x90 =
0x80, terrain (not in the island) +0x90 = 0 → acc[0] (`ip_cap1.txt`, `ip_cap2.txt`).

### 3.4 Build (0x8FD2F7–0x8FD336)

```
end = FUN_008EDCF0(stepInfo, ents, n, 0xD0, acc+0x80)     // 0x8FD310; acc+0x80 also saved at [esp+0x4C]
byte *end = 3                                              // 0x8FD318
for i in 0..island+0x14−1: elemTemp[i] = 0.0 (dword)       // 0x8FD320–0x8FD336, skipped if ≤ 0
```

island+0x14 is the count of solver elemTemp floats. The buffer reserves 4·island+0x14 + 8 bytes for it.
- Capture: island+0x08 = 0xE0, +0x0C = 0xC0, +0x10 = 3, +0x14 = 4, for one contact point (`ip_cap1.txt`).
- 0x8FD6A5 reports island+0x10 to the monitor stream as "MiNumJacobians" (string at 0xB5A018).
- That +0x08/+0x0C/+0x10/+0x14 are hkpConstraintInfo {maxSizeOfSchema, sizeOfSchemas, numSolverResults,
  numSolverElemTemps} is I (Havok names; the uses above are P).

### 3.5 Per-entity master walk (0x8FD338–0x8FD538)

```
w      = [esp+0x18] = schemas                // write pointer, passed by address to the builders
limit  = [esp+0x1C] = elemTemp start (or the split limit)
deferred = local hkArray {data=[esp+0x50]→inline [esp+0x5C], size=[esp+0x54]=0, capFlags=[esp+0x58]=0x80000100}
for e in ents[0..n):                                         // [esp+0x24] iterator, [esp+0x30] end
  for r in e+0x98 .. e+0x98 + 0x30·u16(e+0x9C):              // constraintsMaster only, records of 0x30
    if (u8 r+0x12 & 5):                                     // 0x8FD3A3
        inst = r+0;  q+0x48 = inst;  q+0x4C = r+0x1C (runtime)
        A = inst+0x14; B = inst+0x18                        // entities from the INSTANCE
        q+0x30 = acc + A+0x90;  q+0x34 = acc + B+0x90
        q+0x38 = [A+0x18];      q+0x3C = [B+0x18]           // cdBody motion pointer; = entity+0xE0 in the capture
        if (r+0x12 & 1): FUN_008DCF30(inst+0x0C (data), q, [data+0x28])   // 0x8FD3FB; capture: data+0x28 = the atom
        if (r+0x12 & 4): data->vtbl[+0x28](q)  (thiscall, ecx = data)     // 0x8FD418
    if (u8 r+0x13 >= 3):                                    // 0x8FD41E, unsigned
        deferred.push(r)   (grow via FUN_0088CF20(&deferred, 4) when size == cap & 0x3FFFFFFF)
        continue
    BUILD(r)                                                // 0x8FD457–0x8FD515
```

**BUILD(r)** (the same code in the deferred loop 0x8FD551–0x8FD62B):

```
if (w >= limit):                                   // jb skips; "buffer full"
    dword [w] = f32(f32_at(w) + 2^-23 /*qword 0xBEAA68*/)   // fld [w]; fadd; fstp [w]  (I: artifact of a header union)
    dword [w+4] = goto_target([esp+0x28]) − w
    byte  [w]   = 2                                // goto opcode
    w = goto_target; limit = 0xFFFFFFFF            // at most one goto
A = r+4; B = r+8                                   // entities from the INTERNAL record
q+0x30 = acc + A+0x90;  q+0x34 = acc + B+0x90
q+0x38 = A+0xE0;        q+0x3C = B+0xE0            // lea
q+0x48 = r+0 (instance); q+0x4C = r+0x1C (runtime)
q+0x50 = u16(A+0x90 >> 7);  q+0x54 = u16(B+0x90 >> 7)
q+0x58 = q+0x4C (runtime)
atom = r+0x0C
if (u16 *atom == 0x16): FUN_00A209B0(atom, q, writeHeader, &w)       // 0x8FD4FE
else:                   FUN_00A1C940(atom, u16 r+0x10 atomsSize, q, &w)   // 0x8FD510
```

- **writeHeader** is pushed as a dword whose low byte is set to 1 (`mov byte [esp+0x4C],1` / `[esp+0x34]`); its upper 3
  bytes are stale stack.
  - A209B0 tests only the byte (`cmp byte [ebp+0x10],0` at 0xA20A23).
  - When nonzero it emits the 16-byte header record (type 1) before the rows (0xA20A48–0xA20A7F).
  - So **every constraint gets its own header**.
- **Which q fields each path sets:**
  - the flags & 5 block sets q+0x30/34/38/3C/48/4C only;
  - BUILD sets all nine (+0x30, +0x34, +0x38, +0x3C, +0x48, +0x4C, +0x50, +0x54, +0x58);
  - so the deferred pass and the +0x28 callback see q+0x50/54/58 from the previous constraint.
- **Order per record:** the flags & 5 block always runs first, whatever the priority. The priority test is after it.

**Deferred records** (0x8FD541–0x8FD631) are built after all entities, in insertion order, by BUILD.

```
dword [w] = 0                                     // 0x8FD634: end opcode (4 zero bytes)
if (deferred.capFlags bit31 clear): FUN_0088CBD0(alloc, data, 4·(cap & 0x3FFFFFFF), 0x17)   // heap storage only
```

**Once or per entity?** Only constraintsMaster (+0x98/+0x9C) is walked. The slave list (+0xA0/+0xA4) is never read, and
there is no visited check or dedupe anywhere in 0x8FD380–0x8FD62B (P). In the capture:
- the boat's master list = {internal 0x1CBE9E30} (count 1);
- the terrain's master count = 0 and its +0xA4 = 13 (slave entries) (`ip_cap1.txt`, `ip_cap2.txt`).

A constraint is therefore built once, from the one entity that owns it as master. That each constraint is in exactly one
master list is the Havok invariant (I).

### 3.6 Solve, export, integrate (0x8FD66C–0x8FD787)

```
r = FUN_00A2F840(si, schemas, acc, elemTemp)                     // 0x8FD67B → [esp+0x30]
monitor: "MiNumJacobians" = (float)island+0x10; "MiNumEntities" = (float)n   // no effect on numbers
if (r == 1):                                                     // 0x8FD6D7 cmp …,1; jne → skip ALL below
    FUN_00A3EA20(si, elemTemp, schemas, acc)                     // 0x8FD6E9; 0xA3EA20 = `jmp 0xA3CE20` (the export thunk)
    res = FUN_008EE2D0(si, stepInfo, acc+0x80, ents, n, 0xD0)     // 0x8FD702
    FUN_008EF520(*(*(ents[0]+8) + 0x6C) /* world→collisionInput */, ents, n)   // 0x8FD717
    if (dword schemas[0] != 0):                                  // 0x8FD71C
        FUN_008EAFC0(island+0x18 /* world */, schemas+0x10, schemas[0])        // 0x8FD735
    [esp+0x44] = res
free [esp+0x34] (if nonzero) and the main block [esp+0x38] back to the stack allocator (0x8FD73D–0x8FD785)
return [esp+0x44]                                                // initialised 0 at 0x8FD075
```

- **If the solver does not return 1, FD040 does no export, no integration and no AABB update, and returns 0.**
- schemas[0] / schemas+0x10 are the breach count and list that the export writes at the end (contact_solve.md §8: I;
  A3CE20 not read here).
- island+0x18 = 0x20007800 in the winch capture, the world pointer (P value; identity I).

---

## 4. hkpFixedRigidMotion (type 7, vtable 0xB592EC)

A whole-file byte search for `EC 92 B5 00` finds exactly two sites (`ip_vt_refs.txt`).

**(a) The constructor FUN_008EF470** (thiscall, this = ecx, args (position, rotation), `ret 8`).
- Its vtable store is stolen by the splice at 0x8EF484 (`jmp [0x2455144]`).
- The gadget is **0x5484C8: `mov dword [esi], 0xB592EC; jmp 0x8EF48A`** (`ip_vt1.txt`).
- splice-emulate from 0x8EF484 returns into 0x8EF48A–0x8EF491 (`ip_emu_8ef484.txt`).
- Callers (rel32 scan, `ip_callers.txt`): 0x8D5037, 0x8D55C5, 0x6B238F.

```
FUN_008F4740(this, pos, rot)                // keyframed ctor, 0x8F4740–0x8F4790
    FUN_008DF590(this, pos, rot, 0)         // hkpMotion ctor, 0x8DF590–0x8DF675, wantDeactivation = 0 (push 0)
        word +0x06 = 1; vtable = 0xB58B94
        +0xD0..0xDC linearVelocity = 0.0; +0xE0..0xEC angularVelocity = 0.0
        FUN_00A071D0(ecx = this+0x10, pos, rot)      // motion state (not read)
        +0xB4 linearDamping = 0.0; +0xB8 angularDamping = 0.0
        byte +0x08 type = 0
        byte +0x09 = (arg4 != 0) ? (trunc(pos.x) & 0xF) : 0xFF   // fistp with RC = truncate; here 0xFF
        u16 +0x0A = 0; u16 +0x0C = 0                 // inactive-frame counts
        +0xF0..0xFC = 0.0; +0x100..0x10C = 0.0       // deactivationRefPosition[0..1]
        +0x110 = 0; +0x114 = 0                       // deactivationRefOrientation[0..1]
    vtable = 0xB58C04 (keyframed)
    dword +0x118 = 0; u16 +0x11C = 0
    +0xC0..0xCC inertiaAndMassInv = 0.0
    byte +0x08 type = 6
vtable = 0xB592EC                            // gadget 0x5484C8
byte +0x08 type = 7                          // 0x8EF48A
return this
```

The constructor does not write +0xB0 objectRadius, +0xBC maxLin, +0xBD maxAng, +0xBE class or +0xBF.

**(b) 0x8DDD68, inside FUN_008DDC10** (an entity constructor taking one argument).
- It writes the entity vtable 0xB5942C and empty constraint arrays, sets +0xD0 vtable = 0xB58C74, and then, if its
  argument is nonzero, switches on the motion type +0xD8. The jump table at 0x8DDDA4 covers types 2..9:

| Type | Vtable |
|---|---|
| 2 | 0xB58A4C |
| 3 | 0xB58AB4 |
| 4 | 0xB5921C |
| 5 | 0xB59284 |
| 6 | 0xB58C04 |
| **7** | **0xB592EC** |
| 8 | 0xB59364 |
| 9 | 0xB58B1C |

- Each case writes only the vtable and word +0x06 = bx (1). Every other motion field is left as it was.
- Callers: 0xA42B11, 0xA42B33, 0xA4326E, 0xA43293.
- That this is the finish-loading constructor of a serialized body (fields come from packfile data) is I.

**The winch terrain motion** (entity 0x1E45C800 + 0xD0, `ip_cap1.txt`) has:
- vtable 0xB592EC, word +6 = 1, type 7;
- **+0x09 = 0x0F**, +0x0A = 0x0000, **+0x0C = 0x8000**;
- invMass/inertia +0xC0..0xCC = 0, v = ω = 0;
- radius 311.27, angularDamping 0.8, +0xBC/BD/BE/BF = 0x79/0x51/0x01/0xFF.

Constructor (a) would leave +0x09 = 0xFF and +0x0C = 0. So this motion was not built by (a) alone (or was changed after it).
Path (b) with serialized fields fits it (I).

For the integrators the counter is not used: a type-7 motion is not passed to them for the boat island (§1.4).

---

## Corrections to the spec

1. **contact_solve.md §1.6 and step_and_integrate.md §3.1: "FD040 0x8FD127–0x8FD157 zeroes 0x80 bytes and sets type 1,
   flag 1".**
   - The fixed accumulator is written at **0x8FD262–0x8FD2C1**. It sets byte+0 = 1 and byte+1 = 1, and stores 0.0 into
     +0x10..+0x7C only.
   - **+0x02..+0x0F (including the class dword +0x04) are not written.** The matrix is zero, not identity.
   - 0x8FD127–0x8FD157 is the split-allocation path.
2. **contact_solve.md §1.6 "entity solverData … (0x8FD15F)", "Header indices … (0x8FD228)", and §1.8 "(0x8FD222–0x8FD230)".**
   The addresses are wrong:
   - solverData is stored conditionally at 0x8FD2D6–0x8FD2DE;
   - the q fields are written at 0x8FD3A9–0x8FD3E7 (the flags path) and 0x8FD483–0x8FD4DD / 0x8FD584–0x8FD5DD (BUILD);
   - the indices `>>7` at 0x8FD4C2 / 0x8FD4D4.
3. **contact_solve.md §1.8 and §5 "if r.flags & 5: set q.accA/B, q+0x38/0x3C, q+0x48/0x4C".** That block takes the entities
   from **instance+0x14/+0x18**, not from the internal record. q+0x38/+0x3C there are **[entity+0x18]** (the cdBody motion
   pointer), not lea entity+0xE0; they are equal in the capture. It does not set +0x50/+0x54/+0x58.
4. **contact_solve.md §3 and §5.** The deferred new-point pass is called as **FUN_008DCF30(instance+0x0C data, q,
   data+0x28)**. In the capture, data (mgr+0x14 = 0x1C8A6C94) +0x28 = 0x1C8A6200 = the atom.
5. **contact_solve.md §5.** The export, 8EE2D0, 8EF520 and the impulse-limit call all sit **inside `if (A2F840(...) == 1)`**.
   Otherwise FD040 returns 0 and does not integrate.
   - The export call is 0xA3EA20 (`jmp 0xA3CE20`).
   - The impulse-limit call is FUN_008EAFC0(island+0x18, schemas+0x10, schemas[0]).
   - The writeHeader argument is a byte 1 (upper bytes stale).
6. **step_and_integrate.md §3.3: "the persistent 1.0 … the a.w formula consumes it (0x8EEC41)".**
   - For type 4 the loop-top 1.0 is popped at 0x8EE3C2.
   - The 1.0 used at 0x8EEC41 is pushed at 0x8EEBC5 in the limit branch; the no-limit branch pushes its own at 0x8EEB95.
   - No value changes.
7. **step_and_integrate.md §3.3** gives three different groupings for ω = R·aa. They are as written, but they are
   bit-identical to the one tree (x ⊕ y) ⊕ z, because only the first add is commuted. The same holds for pa (FUN_0088EB30)
   and for the transform's R·comLocal.
8. **step_and_integrate.md §3.3 guard.** The w lanes of pl and pa are tested and then masked off (`and eax,0xE` at
   0x8EE93E). The reset writes the local pl/pa only.
9. **step_and_integrate.md §3.1** omits two facts:
   - the type-7 accumulator gets a+0x04 unwritten and an all-zero matrix, while type 6 gets the identity diagonal;
   - the type-1 record is left entirely unwritten.

## NOT DETERMINED

- The body of the sqrt import behind 0x9EE730 (`jmp [0xB053AC]`): not in the image. The port uses x87 fsqrt (I, from
  8EC5B0's bit-exact replay).
- The exact byte sizing of FD040's split-allocation path 0x8FD12D–0x8FD25D. The structure was read; the sizes are I. It
  does not run for the boat (the buffer fits).
- What bytes 1..3 of a goto header hold: they are f32(old + 2⁻²³)'s upper bytes. Whether the solver reads them was not
  checked (contact_solve.md §1.9 says opcode byte + offset +4).
- Type 8's angular-momentum block (0x8EEDAD–0x8EEE4F) and the type 0/2/3/5/6/9 velocity paths of 8EE2D0: not transcribed
  (not the box).
- How the winch terrain's motion got +0x09 = 0x0F and +0x0C = 0x8000 (constructor (a) gives 0xFF / 0): path (b) or a later
  writer was not traced.
