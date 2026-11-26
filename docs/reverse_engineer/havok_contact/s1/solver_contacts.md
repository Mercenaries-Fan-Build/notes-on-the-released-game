# FUN_00A2F840: solver structure and the normal-contact cases (0x0F/0x10, 0x11/0x12, 0x13/0x14)

Source: `mercs2_unpacked.exe` (pc-v10). Disassembly made this run:
`objdump -d --x86-asm-syntax=intel --start-address=0xA2F840 --stop-address=0xA362E0` → `tx/sc/dis_solver.txt`;
FUN_00A3EA30/A3EA60 → `tx/sc/dis_a3ea30.txt`. Tables and strings: `xxd` → `tx/sc/jt.txt`, `tx/sc/strs.txt`.
Keycode hash recomputed from the exe bytes with `tx/sc/keyhash.py` → `tx/sc/keyhash.txt`. The two 0x13 body copies were compared mechanically by `tx/sc/cmp13b.py` → `tx/sc/cmp13b.txt`.

Notation:
- `f32(e)`: e is evaluated on the x87 stack at 53-bit precision and stored as a dword.
- `A` = accA (esi), `B` = accB (edi), `rec` = ebx, `elem` = edx.
- Accumulator fields: `+0x10` lin xyz, `+0x20` ang xyz, `+0x30` invI xyz, `+0x3C` invMass.
- P = read in asm this run (address given). I = inferred. ND = not determined.

**Commutativity note (I, IEEE 754).** The rounded result of a single x87 `fadd`/`fmul` of two operands does not depend on operand order. That holds for signed zeros in round-to-nearest, and the NaN choice is symmetric (SDM: larger significand). Operand order is kept below as the code has it, but for bits only these matter:
- subtraction order;
- association of multi-term sums;
- the points where values are stored as f32 (dword).

## 1. Entry, prologue, locals, loops

### 1.1 Frame and arguments (P 0xA2F840–0xA2F8C1)
`push ebp; mov ebp,esp; and esp,-16; sub esp,0xDE4`. The arguments are:

| Address | Argument |
|---|---|
| `[ebp+8]` | si (solverInfo) |
| `[ebp+0xC]` | schema stream |
| `[ebp+0x10]` | accumulators |
| `[ebp+0x14]` | elemTemp |

### 1.2 Licence check, not a capability probe (P)
```
0xA2F84C  if byte[0xE77F84] == 0:
0xA2F858     al = FUN_00A3EA60(0); byte[0xE77F84] = al
0xA2F862     if al == 0: return 0            // 0xA2F86B xor eax,eax; ret
```
FUN_00A3EA60(arg) is the Havok keycode/keyvalue validation (P 0xA3EA60–0xA3ED00):
- `key = dword[0xBA8874]` = 0x59FDC5DA.
- `timed = key>>31` = 0 (0xA3EA66–0xA3EA72).
- The keycode string is at 0xBA8848: `"CLIENT.PhAn.Pandemic_CentralTechAndTools"`.

```
for i = 0..11:                                       // [esp+0xC], loop 0xA3EA80..0xA3EC92 (cmp 0xC, jl)
  secret = dword[0xB6D760 + 4i]
  p = strchr(keycode, '.')       (FUN_00A3EA30, eax=str, arg '.')   if 0 → FAIL      // 0xA3EA9E
  if strstr(p, "Prime") && (arg==1||arg==2): build message (strncat 0x9EE3B0) and report (FUN_0088F440 = hkError) – no effect on the result
  q = strchr(p+1, '.')                                                if 0 → FAIL     // 0xA3EBF5
  s = q + 1
  if timed: (0xA3EC05..) time-window path through FUN_00A42AA0 — not taken for this key (ND: not transcribed)
  else (0xA3EC5C):
     h = 0; if s[0] != 0: do { c = s[1]; h = h*23; s++; h += (int8)c } while c != 0
         // NOTE: s[0] is skipped; the final NUL also contributes one ×23
     if ((h ^ secret) & 0x7FFFFFFF) == key: goto MATCH
FAIL (0xA3EC98): hkError("Havok Physics evaluation key has expired or is invalid..."), return 0
MATCH (0xA3ECE2):
  if (arg==1||arg==2) && (unsigned)(i-6) <= 3: hkError("Product mismatch: Prime..."), return 0
  if arg==4 or i < 10: return 1
  hkError("Product mismatch: FX..."), return 0
```
Computed from the exe bytes (`keyhash.txt`):
- `h` = 0xB7B8F79F.
- i = 1 matches exactly: (h ^ 0x6E453245) & 0x7FFFFFFF = 0x59FDC5DA.

The exact match confirms this reading, including the skipped first character. So FUN_00A3EA60(0) returns 1 deterministically for this exe. The solver returns 0 only if the keycode bytes are changed. **P** (code and computed result).

### 1.3 Prologue over accumulators (P 0xA2F874–0xA2F975; jump table 0xA362E0)
```
g = si[0x10..0x1C] copied as dwords to [esp+0x5E0..0x5EC] (exact), loaded:
x87: fld g.w, fld g.z, fld g.y, fld g.x, fldz   → [0, gx, gy, gz, gw]
a = accumulators; if a == 0xFFFFFFFF skip (cmp/jae, never true in practice)
loop: t = byte a[0]; if t > 3: int3 (0xA2F96B)
  table 0xA362E0 = {0: 0xA2F8FC, 1: 0xA2F8DC, 2: 0xA2F8DC, 3: 0xA2F975}
  type 1/2 (0xA2F8DC): store +0.0 (fst st0) to a+0x4C,+0x48,+0x44,+0x40,+0x5C,+0x58,+0x54,+0x50 ; a += 0x80
  type 0  (0xA2F8FC): the same 8 zero stores (+0x40..+0x5C), then
        a.lin.x = f32(a.lin.x + g.x)    // 0xA2F927 fld [a+0x10]; fadd st,st(2)
        a.lin.y = f32(a.lin.y + g.y)    // 0xA2F935 fadd st,st(3)
        a.lin.z = f32(a.lin.z + g.z)    // 0xA2F943 fadd st,st(4)
        a.lin.w = f32(g.w + a.lin.w)    // 0xA2F951 fld st(4); fadd [a+0x1C]
        a += 0x80; if next type == 0 loop here directly (0xA2F95F), else redispatch
  type 3: exit
```
- Order: x, y, z, w, each one f32 add of two f32 values.
- `si+0x10` is globalAccelerationPerSubStep.
- Types 1 and 2 get no gravity.

### 1.4 Locals before the iterations (P 0xA2F975–0xA2F999)
- The x87 pops leave **one +0.0 resident** at the bottom of the stack (from the `fldz` at 0xA2F8C1): `fstp st(4); fstp st(2); fstp st(0); fstp st(0)`.
- It stays there for the whole solve. Call it Z.
- It is the 0 operand of every contact compare below. The leaf-solver calls preserve it (`fstp st(0)` before the call at 0xA3537E, `fldz` after at 0xA35397).

The locals:

| Local | Value | Address |
|---|---|---|
| `[esp+0x3C]` iter | 0 | 0xA2F980 |
| `[esp+0x38]` invIVF (decomp local_dc8) | `f32(si[0x120] * si[0x40])` = invNumSteps · invIntegrateVelocityFactor.x | 0xA2F98C–0xA2F995 |

If `(int)si[0x114] <= 0`, jump to 0xA35B75 and return 1. There is no walk and no second loop, but the prologue's gravity add has already happened (`jle` uses the flags of `cmp [edx+0x114],0` at 0xA2F975; x87 ops do not change EFLAGS).

### 1.5 Iteration and microstep loops (P)
```
ITER (0xA2F99F):
  [esp+0x16C] firstMicro = 1.0 (fld1/fstp)      ; [esp+0x168] = iter (int)
  [esp+0x34] micro = si[0x118] (numMicroSteps)
  MICRO (0xA2F9C0):                               // do-while
     ebx = schemas; edx = elemTemp; [esp+0x1C] = elemTemp      // elem pointer reset every walk
     if byte[ebx] == 0: goto WALK_END
     goto HEADER (0xA2F9D3)                        // the first record is NOT dispatched: assumed opcode 1
  WALK_END (0xA35430):
     firstMicro = Z (+0.0)   (fst [esp+0x16C])
     if --micro > 0: goto MICRO                    // jg: body runs once even if numMicroSteps <= 0
  last = (iter == si[0x114] - 1)  → byte [esp+0x33]          // 0xA3544A–0xA35461
  SECOND LOOP (0xA35466..), §5
  0xA35B5B: if ++iter < si[0x114]: goto ITER (jl)
  0xA35B75: fstp st(0) (pop Z); return 1
```
- firstMicro (`[esp+0x16C]`) is read only at 0xA32D8C (opcode 0x0E case) and 0xA347C4 (opcode 0x09 case). It is also passed by pointer, as `[esp+0x168]` = {iter, firstMicro}, to the leaf solvers at 0xA35389/0xA353C2/0xA35400. These were found by grepping every `esp + 0x16c]` / `0x168]` in 0xA2F840–0xA362E0 (`tx/sc/g_locals.txt`).
- **No normal-contact case reads it.** P.
- elemTemp slots are not cleared by the solver, so they accumulate across every microstep and iteration. P (no store other than the `+=` writes below).

### 1.6 Schema walk (P 0xA2F9D3–0xA2F9F7, 0xA35372, 0xA35430)
```
HEADER (case 1, 0xA2F9D3): esi = acc + (u16 rec[+4] << 7); edi = acc + (u16 rec[+6] << 7)
                            (rec+1 stride, +8, +0xC are not read here)
SKIP16 (case 3, 0xA2F9E8):  rec += 0x10
DISPATCH (0xA2F9EB): op = movsx byte rec[0]  (signed); if (unsigned)op > 0x1C: int3 (0xA3542F)
                     jmp [0xA362F0 + 4*op]
case 0 → 0xA35430 WALK_END ; case 2 (0xA35372): rec += i32 rec[+4]; goto DISPATCH
```
Header case falls through into SKIP16 (`add ebx,0x10`), then DISPATCH.
- Opcodes ≥ 0x80 are negative after `movsx` and so trap with int3.
- The jump table bytes (`jt.txt`) agree with contact_solve.md §1.9.

### 1.7 elemTemp
- edx is the live pointer and `[esp+0x1C]` is its memory copy.
- Contact cases advance edx and write `[esp+0x1C] = edx` before returning to DISPATCH (0xA30E17, 0xA311A8, 0xA3044D, 0xA31586).
- The advance:
  - 0x0F/0x11: `edx += 4 * byte[0xCE0444 + movsx rec[0]]`, indexed by the **current** record's opcode before the advance (0xA30DF9–0xA30E03, 0xA3118A–0xA31194).
  - 0x13: hardcoded `edx += 8` (0xA30444, 0xA3157D).
- Table 0xCE0444 bytes (P, `strs.txt`):

| Opcodes | Value |
|---|---|
| 0–4 | ff |
| 5,6,7 | 01 |
| 8 | 02 |
| 9 | 03 |
| A,B,C | 01 |
| D | 02 |
| E | 03 |
| F,10,11,12 | 01 |
| 13,14 | 02 |
| 15 | 03 |
| 16 | 04 |
| 17,18 | 00 |
| 19+ | ff |

### 1.8 Tagged first float (P)
The solver multiplies by `rec[0]` exactly as stored. That float carries the opcode in its low byte plus the ε-adds (§6.1 of the spec).

| Case | Jv sites | Linear-apply sites |
|---|---|---|
| 0x0F | 0xA30B48 | 0xA30C98, 0xA30CC4 |
| 0x11 | 0xA30E9E | 0xA31029, 0xA31055 |
| 0x13 row 0, copy 1 | 0xA2FA7A | 0xA2FD4F, 0xA2FD7B, 0xA30110, 0xA3013C |
| 0x13 row 0, copy 2 | 0xA304CC | 0xA307A8, 0xA307D4, 0xA31249, 0xA31275 |

The pair's row 1 uses `rec[0x30]`, which is stored clean.

## 2. Case 0x0F / 0x10 (0xA30AD1–0xA30E1B) — P

`ecx = rec+0x18` (0xA30AD1). Fields:
- lin = rec+0/4/8
- rhs = +0xC
- angA = +0x10/14/18
- effMass = +0x1C
- angB = +0x20/24/28

+0x2C is **not read**. x87 on entry: [Z].
```
0xA30AD4  dl.x = f32(A.lin.x - B.lin.x); dl.y = f32(A.lin.y - B.lin.y); dl.z = f32(A.lin.z - B.lin.z)
0xA30AFB  aA.x = f32(A.ang.x*angA.x); aA.y = f32(A.ang.y*angA.y); aA.z = f32(A.ang.z*angA.z)
0xA30B21  aB.x = f32(B.ang.x*angB.x); aB.y = f32(B.ang.y*angB.y); aB.z = f32(B.ang.z*angB.z)
0xA30B48  dl.x = f32(rec[0]*dl.x);   dl.y = f32(dl.y*rec[4]);   dl.z = f32(dl.z*rec[8])
0xA30B7A  s.x = f32(aB.x+aA.x); s.y = f32(aB.y+aA.y); s.z = f32(aA.z+aB.z)
0xA30BB9  s.x = f32(s.x+dl.x);  s.y = f32(s.y+dl.y);  s.z = f32(s.z+dl.z)
0xA30BF8  Jv    = f32((s.y + s.x) + s.z)        // one 53-bit add chain, single f32 store [esp+0x18]
0xA30C14  delta = f32(rhs - Jv)                 // fld rhs; fsub [esp+0x18]
0xA30C1C  fcom delta vs Z; test ah,0x05; jnp SKIP(0xA30DF7)
          → SKIP only when delta < 0. Apply when delta > 0, == 0 (incl. ±0), or unordered (NaN).
APPLY:
0xA30C2D  lam = f32(delta * effMass)            // [ecx+4] = rec+0x1C; reloaded as f32
0xA30C38  tA.x = f32(lam*A.invI.x); tA.y = f32(A.invI.y*lam); tA.z = f32(A.invI.z*lam); mA = f32(A.invMass*lam)
0xA30C68  tB.x = f32(B.invI.x*lam); tB.y, tB.z likewise; mB = f32(B.invMass*lam)
0xA30C98  pA.x = f32(rec[0]*mA); pA.y = f32(mA*rec[4]); pA.z = f32(mA*rec[8])
0xA30CC4  pB.x = f32(rec[0]*mB); pB.y = f32(mB*rec[4]); pB.z = f32(mB*rec[8])
0xA30CF0  A.lin.x = f32(A.lin.x+pA.x); A.lin.y = f32(A.lin.y+pA.y); A.lin.z = f32(pA.z+A.lin.z)
0xA30D17  B.lin.x = f32(B.lin.x-pB.x); B.lin.y = f32(B.lin.y-pB.y); B.lin.z = f32(B.lin.z-pB.z)
0xA30D3E  tA.j = f32(tA.j*angA.j) (j=x,y,z); tB.j = f32(tB.j*angB.j)
0xA30DA3  A.ang.x = f32(tA.x+A.ang.x); A.ang.y = f32(tA.y+A.ang.y); A.ang.z = f32(A.ang.z+tA.z)
0xA30DCA  B.ang.x = f32(B.ang.x+tB.x); B.ang.y = f32(B.ang.y+tB.y); B.ang.z = f32(B.ang.z+tB.z)
0xA30DF1  elem[0] = f32(lam + elem[0])
SKIP (0xA30DF7): pop delta
0xA30DF9  edx += 4*T[op(rec)] (=1 float); al = byte rec[0x30]; rec += 0x30
0xA30E0F  cmp al,0x0F; je 0xA30AD4 (next record, same body)
0xA30E17  [esp+0x1C] = edx; goto DISPATCH
```
- Every exit leaves x87 = [Z]. The `w` lanes (+0x1C, +0x2C of the accumulator) are untouched.
- The inner loop compares the next opcode byte exactly with 0x0F, so a 0x10 record re-enters through DISPATCH and runs the same body.

## 3. Case 0x11 / 0x12 (0xA30E20–0xA311AC) — P

The Jv part is the same as §2, with different temp slots and operand orders that commute:
- dl = A−B
- aA = angA·A.ang
- aB = angB·B.ang
- dl.x = dl.x·rec[0], dl.y = rec[4]·dl.y, dl.z = rec[8]·dl.z
- s = aB+aA, then s = s+dl
- `Jv = f32((s.x + s.y) + s.z)` (0xA30F47)
- `delta = f32(rhs - Jv)`

The gate is the same (`test ah,5; jnp` at 0xA30F73): skip only when delta < 0.
```
0xA30F7C  lam  = f32(delta * effMass)              → [esp+0x18]
0xA30F83  max  = rec[0x2C]  (float [0xB])          → [esp+0x24]
0xA30F8A  e0   = elem[0]                           → [esp+0x20]
0xA30F94  S    = f32(e0 + lam)                     → [esp+0x18]  (overwrites lam's slot; lam stays on the stack, f32-exact)
0xA30FA8  fcom max vs S ; fstp st(1) ; test ah,0x05 ; jp NOCLAMP(0xA30FC5)
          → NOCLAMP when max > S, max == S, or unordered.  CLAMP only when max < S (ordered).
CLAMP (0xA30FB7): lam = f32(max - e0)              // bytes de e1 = FSUBRP st(1),st: st1 = st0 - st1 = max - e0
NOCLAMP: lam unchanged
0xA30FC9  apply lam exactly as §2 APPLY (same products, same subtraction order B.lin - pB;
          operand orders differ only commutatively)
0xA31182  elem[0] = f32(lam + elem[0])             // elem[0] reloaded from memory (= e0)
0xA3118A  edx += 4*T[op]; next = byte rec[0x30]; rec += 0x30; if next == 0x11 loop to 0xA30E23
0xA311A8  [esp+0x1C] = edx; goto DISPATCH
```
- The clamp is inside the delta ≥ 0 gate.
- There is no sign re-check of the clamped lam.
- After a clamp, `elem[0] = f32(f32(max − e0) + e0)`, which need not equal max bit-for-bit.

## 4. Case 0x13 / 0x14 contact pair (0xA2F9FE–0xA30451; second copy 0xA30457–0xA30ACC + 0xA311B1–0xA3158A) — P

Record layout read (floats from rec):

| Row | Field | Offset |
|---|---|---|
| Row 0 | lin | 0/4/8 |
| Row 0 | rhs0 | 0xC |
| Row 0 | angA0 | 0x10.. |
| Row 0 | effMass0 | 0x1C |
| Row 0 | angB0 | 0x20.. |
| Row 0 | inv00 | 0x2C |
| Row 1 | lin | 0x30/34/38 |
| Row 1 | rhs1 | 0x3C |
| Row 1 | angA1 | 0x40.. |
| Row 1 | effMass1 | 0x4C |
| Row 1 | angB1 | 0x50.. |
| Row 1 | inv11 | 0x5C |
| — | inv01 | 0x60 |

rec+0x64..0x6F is not read. x87 on entry: [Z].

### 4.1 d0, d1 (both computed before any velocity change)
```
0xA2F9FE  row 0: dl=A.lin−B.lin; aA=A.ang·angA0; aB=angB0·B.ang (x), B.ang·angB0 (y,z);
          dl.x=dl.x·rec[0]; dl.y=dl.y·rec[4]; dl.z=rec[8]·dl.z; s=aB+aA; s=s+dl
0xA2FB23  Jv0 = f32((s.x+s.y)+s.z);  d0 = f32(rhs0 − Jv0)  → [esp+0xDC0]
0xA2FB4A  row 1: same with rec+0x30.. (dl.x=dl.x·rec[0x30], dl.y=rec[0x34]·dl.y, dl.z=rec[0x38]·dl.z)
0xA2FC70  Jv1 = f32((s.x+s.y)+s.z);  d1 = f32(rhs1 − Jv1)  → [esp+0xDC4]
```
Each `d` is bit-identical to the 0x0F delta for the same row data. The only difference is that 0x0F adds `(s.y+s.x)` first, and the first add commutes. P (and I for the commutation).

### 4.2 l0, l1 (0xA2FC97–0xA2FCC5)
```
l0 = f32( inv00*d0 + d1*inv01 )     // 0xA2FCA3 fmulp st(2): inv00·d0; 0xA2FCAE d1·inv01; faddp st(3) → one rounding → [esp+0x18]
l1 = f32( inv11*d1 + d0*inv01 )     // 0xA2FCB9 inv11·d1; 0xA2FCC0 d0·inv01; faddp st(1) → [esp+0x20]
```
Both products are exact in 53 bits (f32 × f32). The sum is rounded once to 53 bits, then stored as f32. After this, x87 = [d0, d1, Z].

### 4.3 Branches (exact senses)
```
0xA2FCC9  fcom l0 vs Z; test ah,0x41; jne L0_NOT_POS(0xA30078)   → taken when l0 < 0, l0 == 0, or NaN
          (fall through: l0 > 0)
0xA2FCDC  fcom l1 vs Z; test ah,0x41; jne L1_NOT_POS(0xA30273)   → taken when l1 <= 0 or NaN
          (fall through: l0 > 0 and l1 > 0) → BOTH
L0_NOT_POS (0xA30078):
          l1s = f32(d1 * effMass1)                                 // rec+0x4C
0xA30089  fcom l1s vs Z; test ah,0x41; jp ROW1_ONLY(0xA3027C)       → taken when l1s > 0 OR unordered (NaN)
          (fall through: l1s <= 0, ordered) → ONLY0
L1_NOT_POS (0xA30273): pop to [d0, Z]; goto ONLY0
ONLY0 (0xA30098):
          l0s = f32(d0 * effMass0)                                 // rec+0x1C
0xA300A3  fcom l0s vs Z; test ah,0x41; jne SKIP(0xA30442)          → apply only when l0s > 0 (NaN skips)
          ROW0_ONLY(l0s)
```
NaN outcomes:
- l0 NaN takes the L0_NOT_POS branch.
- l1 NaN (with l0 > 0) takes ONLY0.
- l1s NaN **applies** row 1 with a NaN impulse.
- l0s NaN skips.

### 4.4 Apply paths (velocity-update order)
ROW(k, λ) means the following, with row k fields (k = 0: rec+0.., k = 1: rec+0x30..):
```
tA.j = f32(λ·A.invI.j) (or invI.j·λ), mA = f32(A.invMass·λ); tB.j, mB likewise     // all from the same λ, before any update
pA.x = f32(lin.x·mA); pA.y = f32(mA·lin.y); pA.z = f32(mA·lin.z); pB likewise
A.lin.j = f32(A.lin.j + pA.j)       (j = x, y, z, in that order)
B.lin.j = f32(B.lin.j − pB.j)
tA.j = f32(angA.j · tA.j); tB.j = f32(angB.j · tB.j)
A.ang.j = f32(A.ang.j + tA.j);  B.ang.j = f32(B.ang.j + tB.j)
```
The paths:
- **BOTH** (0xA2FCEF–0xA30073): ROW(0, l0) → `elem[0] = f32(l0 + elem[0])` (0xA2FEA9) → ROW(1, l1) → `elem[1] = f32(l1 + elem[1])` (0xA3006D).
  - Row 0's velocity updates are complete before row 1's products are taken.
  - The products depend only on invI/invMass and λ, so the order affects only the adds.
- **ROW1_ONLY** (0xA3027C–0xA3043D): ROW(1, l1s) → `elem[1] = f32(l1s + elem[1])`. elem[0] is not written.
- **ROW0_ONLY** (0xA300B0–0xA3026C): ROW(0, l0s) → `elem[0] = f32(l0s + elem[0])`. elem[1] is not written.
- **SKIP** (0xA30442): nothing.

All paths end with x87 = [Z].

### 4.5 Advance and the loop (corrects spec §7.2/§7.5 "repeat while 0x13")
```
0xA30444  edx += 8; rec += 0x70; [esp+0x1C] = edx
0xA3044A  if byte rec[0] == 0x13: run COPY 2 (0xA30457) else DISPATCH
COPY 2 = the same body. Its out-of-line branch blocks are 0xA311B1 (L0_NOT_POS), 0xA313AC (L1_NOT_POS),
         0xA313B5 (ROW1_ONLY), 0xA3157B (SKIP); its BOTH path ends 0xA30ACC → 0xA3157D.
0xA3157D  edx += 8; rec += 0x70; [esp+0x1C] = edx
0xA31583  if byte rec[0] == 0x16: fall into the 0x16 case body at 0xA31590; else DISPATCH
```
- The 0x13 run therefore alternates copy 1 → copy 2 → DISPATCH (which re-enters copy 1 for the next 0x13).
- The fall-through into 0x16 is a compiler tail merge. The state is identical to entering through DISPATCH (esi, edi, ebx, edx, `[esp+0x1C]` set, x87 [Z]).
- The numbers are the same as "dispatch every record".
- Copy 2 equals copy 1 instruction for instruction once commutative operand orders and temp-slot addresses are normalised. `cmp13b.py` reports 461 vs 461 canonical ops and 0 differences. This is P for the operations; the branch-target correspondence was checked by hand.

## 5. End of the walk and hand-off to the second loop

- Opcode 0 at DISPATCH (or a first byte of 0 at 0xA2F9C3) goes to WALK_END at 0xA35430 (§1.5).
- After the micro loop ends, the code reaches 0xA35466 with:
  - edx = accumulators (`[ebp+0x10]`), checked against 0xFFFFFFFF;
  - x87 = [Z] only;
  - `byte [esp+0x33]` = last;
  - `[esp+0x38]` = invIVF;
  - `[esp+0x3C]` = iter;
  - `[ebp+8]` = si.
  - esi, edi and ebx hold stale walk values.
- **Second-loop dispatch: 0xA3547E** `jmp [0xA36364 + 4*type]`. Table bytes (P, `jt.txt`): {0: 0xA35B83, 1: 0xA35948, 2: 0xA35485, 3: 0xA35B5B}. Type 3, or edx == 0xFFFFFFFF, goes to 0xA35B5B (iteration increment, §1.5).
- For the other agent: a type > 3 in loop 2 goes to 0xA35B52 → `jb 0xA35472` with the same edx, so it spins (no int3). P.
- Return value: 1 at 0xA35B79 (normal end, also when numSteps ≤ 0); 0 at 0xA2F86B (keycode check failed).

## Corrections to the spec (contact_solve.md)

1. §7.2 / §7.5: the 0x13 case does not loop "while the next opcode is 0x13".
   - There are two unrolled copies (0xA2F9FE, 0xA30457).
   - Copy 1 tests 0x13 (0xA3044A). Copy 2 tests **0x16** (0xA31583) and falls into the 0x16 body.
   - The numbers are the same as dispatching each record.
   - The 0x0F and 0x11 loops test only 0x0F (0xA30E0F) and only 0x11 (0xA311A0).
2. §7.5 NaN/sense:
   - The l1s test is `jp` (0xA30090): row 1 is applied when l1s > 0 **or NaN**.
   - l0 and l1 NaN take the "not positive" branches.
   - The l0s test skips on NaN.
   - l0 and l1 are single-rounding sums of two exact products, stored as f32.
   - Order is `l0 = f32(inv00·d0 + d1·inv01)`, `l1 = f32(inv11·d1 + d0·inv01)`.
3. §7.1: FUN_00A3EA60 is the Havok keycode/keyvalue licence check, not a capability check.
   - For this exe it returns 1 deterministically (table entry 1 matches; non-timed key).
   - Its hash skips the first character of the product string (0xA3EC62).
4. §7.1: the microstep loop is a do-while (0xA35444): one walk even if numMicroSteps ≤ 0. numSteps ≤ 0 returns 1 after the prologue (0xA2F999).
5. §7.2: the first record is not dispatched. A non-zero first byte is treated as a header (0xA2F9C3 → 0xA2F9D3). Opcode 3 is a 16-byte skip record. Opcodes are read with `movsx`, and anything outside 0..0x1C traps (int3).
6. §7.4: the clamp details.
   - Compare `rec[0x2C] < f32(elem0 + lam)` (strict, ordered; NaN does not clamp).
   - Clamped `lam = f32(rec[0x2C] − elem0)`.
   - It all sits inside the delta ≥ 0 gate.
7. §7.3: the "x,y lin first; z product first" add-order note is bit-irrelevant (a single add commutes). Only the Jv association, the subtraction orders and the f32 store points matter.
8. §1.9: the 0x13 elem advance is a hardcoded +8, not the 0xCE0444 table (same value).

## ND
- FUN_00A42AA0 and the timed-key path of FUN_00A3EA60 (0xA3EC05–0xA3EC41): not transcribed. They are not taken for this exe's key (bit31 = 0).
- The meaning of the `{iter, firstMicro}` pair at `[esp+0x168]` inside the leaf solvers FUN_00A262F0/A269D0/A28F30: outside the contact path, not read.
