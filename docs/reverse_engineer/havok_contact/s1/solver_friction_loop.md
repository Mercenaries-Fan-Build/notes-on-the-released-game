# FUN_00A2F840: friction cases 0x15 / 0x16 and the per-iteration accumulator loop (pc-v10)

Source: `objdump -d --x86-asm-syntax=intel --start-address=0xA2F840 --stop-address=0xA36400 mercs2_unpacked.exe`
→ `tx/fl_dis_all.txt` (all addresses below are read there unless stated). Constants: `xxd` → `tx/fl_consts.txt`.
Helpers: `tx/fl_dis_9ee730.txt`, `tx/fl_dis_a3bd60.txt`. Jump table 0xA36364 read with `xxd`.

Notation: `f32(e)` = e evaluated on the x87 stack (53-bit precision control), rounded once to f32 at the `fstp/fst dword`.
`fld dword` loads are exact. "unrounded" = an intermediate kept on the x87 stack (port: f64) and not stored.
Operand order inside one add or one multiply does not change the bits (IEEE + and × are commutative); only the
association and the f32 rounding points matter. Operand order is still noted where the code has it.

## 0. Walk registers and the x87 stack (P)

| Item | Where | Evidence |
|---|---|---|
| `ebx` = current record | set from `[ebp+0xC]` (schemas) at 0xA2F9C0 | |
| `esi` / `edi` = accA / accB | header case 0xA2F9D3–0xA2F9E6: `acc + (u16[+4] << 7)`, `acc + (u16[+6] << 7)` | |
| `edx` and `[esp+0x1C]` = elem pointer | `edx = [ebp+0x14]` (elemTemp base) at 0xA2F9C6, stored `[esp+0x1C]` 0xA2F9C9; every path back into the dispatcher 0xA2F9EB / 0xA2F9D3 leaves `edx = [esp+0x1C]` (`tx/fl_disp_jumps.txt`) | P for the 0x0F/0x13/0x15/0x16 paths; I for the rest |
| persistent `Z = 0.0` on x87 st(0) during the walk | prologue 0xA2F8C1 `fldz` … 0xA2F97C–0xA2F98A pops leave exactly one 0.0 | P |
| elem pointer reset per walk | 0xA2F9C6 runs at the top of every walk (iteration × micro step) | P |

Consequence of the last row: `elemTemp` is re-walked from its base on every iteration, so `elem[0]`, `elem[1]` (and
0x16 `elem[2]`) accumulate across all iterations of one solve; `elem[2]` (0x15) / `elem[3]` (0x16) is overwritten each
walk and holds the last walk's scale. P.

## 1. Comparison case: 0x0F at 0xA30AD1 (Jv and rhs − Jv) — P (0xA30AD1–0xA30C18)

```
dl_j = f32(A.lin_j − B.lin_j)           j = x,y,z      0xA30AD4–0xA30AF4   ([esi+0x10..18] − [edi+0x10..18])
aA_j = f32(A.ang_j · row.angA_j)                       0xA30AFB–0xA30B1A   ([esi+0x20..28] · [ebx+0x10..18])
aB_j = f32(B.ang_j · row.angB_j)                       0xA30B21–0xA30B41   ([edi+0x20..28] · [ebx+0x20..28])
dl_j = f32(n_j · dl_j)                                 0xA30B48–0xA30B73   (n = [ebx+0..8])
s_j  = f32(aB_j + aA_j) ; s_j = f32(s_j + dl_j)        0xA30B7A–0xA30BF1
Jv   = f32((s_y + s_x) + s_z)     (s_y+s_x unrounded)  0xA30BFB–0xA30C10
d    = f32(rhs − Jv)              (rhs = [ebx+0xC])    0xA30BF8, 0xA30C14–0xA30C18
```

The friction rows below use exactly this sequence (same rounding points); only the add operand order of the
first Jv add differs (s_x + s_y), which gives the same bits.

## 2. Friction 0x15 at 0xA31E85 (record 112 B) — P

Record fields read (byte offsets from `ebx`; spec §6.6 float index in brackets). `n0`/`n1` are the friction
directions (§6.6 calls them d0/d1; here d0/d1 mean rhs − Jv, as in the task):

| Off | Field | Off | Field |
|---|---|---|---|
| +0x00..+0x08 | n0 [0..2] (byte +0 = opcode, §6.1) | +0x30..+0x38 | n1 [0xC..0xE] |
| +0x0C | rhs0 [3] | +0x3C | rhs1 [0xF] |
| +0x10..+0x18 | angA0 [4..6] | +0x40..+0x48 | angA1 [0x10..0x12] |
| +0x20..+0x28 | angB0 [8..0xA] | +0x50..+0x58 | angB1 [0x14..0x16] |
| +0x2C | inv00 [0xB] | +0x5C | inv11 [0x17] |
| +0x60 | inv01 [0x18] | +0x64 | max [0x19] |

Not read by this case: +0x1C [7], +0x4C [0x13], +0x68 [0x1A], +0x6C [0x1B]. P (every `[ebx+…]` operand in
0xA31E85–0xA3258E listed above).

```
0xA31E85        fstp st(0)                          // pops Z (stack empty for the _CIsqrt / A3BD60 calls)
// row 0, from the velocities at case entry
0xA31E87–EA7    dl_j = f32(A.lin_j − B.lin_j)                          j = x,y,z
0xA31EAE–ECE    aA_j = f32(A.ang_j · angA0_j)
0xA31ED5–EF5    aB_j = f32(angB0_x · B.ang_x), f32(B.ang_y · angB0_y), f32(B.ang_z · angB0_z)
0xA31EFC–F27    dl_x = f32(dl_x · n0_x); dl_y = f32(dl_y · n0_y); dl_z = f32(n0_z · dl_z)
0xA31F2E–FA5    s_j = f32(aB_j + aA_j); s_j = f32(s_j + dl_j)
0xA31FAC–FC4    Jv0 = f32((s_x + s_y) + s_z)                           → [esp+0x14]
0xA31FC8–FCC    d0  = f32(rhs0 − Jv0)                                  → [esp+0xDE0]
// row 1, also from the entry velocities (nothing applied yet)
0xA31FD3–FF3    dl_j = f32(A.lin_j − B.lin_j)
0xA31FFA–201A   aA_j = f32(A.ang_j · angA1_j)
0xA32021–2041   aB_j = f32(B.ang_j · angB1_j)
0xA32048–2074   dl_j = f32(n1_j · dl_j)
0xA3207B–20F2   s_j = f32(aB_j + aA_j); s_j = f32(s_j + dl_j)
0xA320F9–2111   Jv1 = f32((s_y + s_x) + s_z)
0xA32115–2119   d1  = f32(rhs1 − Jv1)                                  → [esp+0xDE4]
// bound
0xA32120–212D   mx2 = f32(max · max)                                   → [esp+0x24]
0xA32131–214F   l0  = f32(inv00·d0 + d1·inv01)     both products unrounded     → [esp+0x18]
0xA32153–215D   l1  = f32(d1·inv11 + d0·inv01)     both products unrounded     → [esp+0x20]
0xA32161–2177   S   = f32(l1·l1 + l0·l0)           products unrounded, l0/l1 the f32 values
0xA3217F–218A   fld mx2; fcom st(1) [= S]; fnstsw; test ah,5; jp 0xA321D4
                // jp taken when parity(ah&5) even: mx2 > S, mx2 == S, or unordered.
                // Falls through only when mx2 < S (ordered).
  scale (mx2 < S):
0xA3218C–2192   q  = f32(mx2 / S)                  // de f1 = FDIVRP st(1),st: st1 = st0/st1 = mx2/S
0xA32196–219F   sc = f32(_CIsqrt(q))               // call 0x9EE730
0xA321A3–21AF   (sc stored/reloaded twice more as f32: no change)
0xA321B3–21B9   l0 = f32(sc · l0)
0xA321BD–21C3   l1 = f32(sc · l1)
0xA321C7        elem[2] = sc                       // [edx+8], edx = [esp+0x1C] reloaded at 0xA321A7
  no scale (mx2 ≥ S or NaN):
0xA321D4–21DA   elem[2] = 1.0                      // fld1; fstp [edx+8]; edx = elem ptr from dispatch
  both arrive at 0xA321DF with stack [l1, l0] (the f32 values)
// apply row 0 with l0
0xA321DF–2213   tA_j = f32(l0 · A.invI_j) (j=x,y,z: [esi+0x30..38]); mA = f32(l0 · A.invMass) ([esi+0x3C])
0xA3220F–2238   tB_j = f32(l0 · B.invI_j);  mB = f32(l0 · B.invMass)
0xA3223F–2264   pA_j = f32(n0_j · mA)
0xA3226B–2290   pB_j = f32(n0_j · mB)
0xA32297–22BB   A.lin_x = f32(pA_x + A.lin_x); A.lin_y = f32(A.lin_y + pA_y); A.lin_z = f32(pA_z + A.lin_z)
0xA322BE–22E2   B.lin_j = f32(B.lin_j − pB_j)
0xA322E5–2311   tA_j = f32(angA0_j · tA_j)
0xA32318–2344   tB_j = f32(angB0_j · tB_j)
0xA3234F–2373   A.ang_x = f32(A.ang_x + tA_x); A.ang_y = f32(tA_y + A.ang_y); A.ang_z = f32(A.ang_z + tA_z)
0xA32376–239A   B.ang_x = f32(B.ang_x + tB_x); B.ang_y = f32(B.ang_y + tB_y); B.ang_z = f32(tB_z + B.ang_z)
0xA3239D–23A3   elem[0] = f32(l0 + elem[0])
// apply row 1 with l1 (same pattern, record +0x30.. fields)
0xA323A5–23FE   tA_j = f32(A.invI_j · l1); mA = f32(A.invMass · l1); tB_j, mB likewise
0xA32405–2458   pA_x = f32(n1_x · mA); pA_y = f32(n1_y · mA); pA_z = f32(mA · n1_z); pB_j likewise
0xA3245F–2483   A.lin_x = f32(A.lin_x + pA_x); A.lin_y = f32(A.lin_y + pA_y); A.lin_z = f32(pA_z + A.lin_z)
0xA32486–24B5   B.lin_j = f32(B.lin_j − pB_j)          (ebx += 0x70 and push ebx happen inside: offsets shift by 4)
0xA324B8–2517   tA_j = f32(angA1_j · tA_j); tB_j = f32(angB1_j · tB_j)
0xA3251E–2569   A.ang_j = f32(A.ang_j + tA_j) (z: tA_z + A.ang_z); B.ang_j = f32(B.ang_j + tB_j) (z: tB_z + B.ang_z)
0xA3256C–256F   elem[1] = f32(l1 + elem[1])
// advance
0xA32493/0xA32499  elem += 3 floats (eax += 0xC → [esp+0x1C])
0xA324A4           rec  += 0x70
0xA32572–2577      FUN_00A3BD60(&local, rec): copies the byte rec[0] into a local and returns &local (tx/fl_dis_a3bd60.txt)
0xA3257C           fldz                                  // Z restored
0xA3257E           edx = elem
0xA32585–258E      if next opcode == 1 → header 0xA2F9D3, else dispatch 0xA2F9EB
```

Notes:
- The sign of l0/l1 is not tested: both are applied as computed. P.
- Elem writes: `elem[0] += l0`, `elem[1] += l1`, `elem[2] = sc or 1.0`. P.
- `_CIsqrt` (0x9EE730 = `jmp [0xB053AC]`, MSVCR80 import per the Ghidra export `ghidra/pc-v10/0x009ee730`): takes st(0),
  returns st(0). Its body is not in this exe. For an f32 input any correctly rounded sqrt (x87 fsqrt at 53-bit, or
  sqrtsd) followed by the f32 store gives `f32(sqrt(q))`. I (CRT body not read).

## 3. Friction + rolling 0x16 at 0xA31590 (record 144 B) — P

Record fields: +0x00..+0x5C as 0x15. Then:

| Off | Field | Off | Field |
|---|---|---|---|
| +0x60..+0x68 | angA_r [0x18..0x1A] | +0x7C | rhs2 [0x1F] |
| +0x6C | k2 = row[0x1B] | +0x80 | inv01 [0x20] |
| +0x70..+0x78 | angB_r [0x1C..0x1E] | +0x84 | max [0x21] |
| +0x88 | radius [0x22] | +0x8C | export ptr (not read) |

Entry: the case keeps Z on the stack (no `fstp st(0)` at entry). A second entry is the tail of the 0x13 case at
0xA3157D–0xA3158A (`edx += 8; ebx += 0x70; if [ebx] == 0x16 fall into 0xA31590`, reached from 0xA30ACC and
0xA313A7). P for the branch; that the tail is the 0x13 case is I (from the jump sources).

```
// three rows, all from the entry velocities
0xA31590–16B0   row 0: dl_j = f32(A.lin_j − B.lin_j); aA_j = f32(A.ang_j·angA0_j); aB_j = f32(B.ang_j·angB0_j);
                dl_x = f32(n0_x·dl_x); dl_y = f32(dl_y·n0_y); dl_z = f32(n0_z·dl_z);
                s_j = f32(aB_j + aA_j); s_j = f32(s_j + dl_j)
0xA316B5–16D5   Jv0 = f32((s_x + s_y) + s_z); d0 = f32(rhs0 − Jv0)            → [esp+0x9F0]
0xA316DC–1822   row 1: same with n1/angA1/angB1 (dl_x = f32(dl_x·n1_x), dl_y = f32(n1_y·dl_y), dl_z = f32(n1_z·dl_z));
                Jv1 = f32((s_x + s_y) + s_z); d1 = f32(rhs1 − Jv1)             → [esp+0x9F4]
0xA31829–18AF   rolling: aA_j = f32(A.ang_j·angAr_j); aB_x = f32(angBr_x·B.ang_x), aB_y = f32(B.ang_y·angBr_y),
                aB_z = f32(B.ang_z·angBr_z); s_j = f32(aB_j + aA_j)            (no linear term)
0xA318B6–18D6   Jv2 = f32((s_x + s_y) + s_z); d2 = f32(rhs2 − Jv2)             → [esp+0x9F8]
0xA318DD–18E7   l2 = f32(k2 · d2)                                              → [esp+0x24]
0xA318EB–190C   l0 = f32(inv00·d0 + d1·inv01)     products unrounded (inv01 = [ebx+0x80])   → [esp+0x20]
0xA31910–191D   l1 = f32(d1·inv11 + d0·inv01)     products unrounded                       → [esp+0x18]
0xA31921–1945   S  = f32((l0·l0 + l1·l1) + l2·l2) products and the partial sum unrounded
0xA31949–1959   mx2 = f32(max · max)              (max = [ebx+0x84])
0xA3195D–1968   fld mx2; fcomp st(1) [= S]; fnstsw; test ah,5; jp 0xA319CE
                // same sense as 0x15: scale only when mx2 < S (ordered); mx2 ≥ S or NaN → no scale
  scale:
0xA3196A–196E   (S left alone on the stack; Z is overwritten here)
0xA31970–1975   r   = f32(_CIsqrt(S))
0xA31981–1987   inv = f32(1.0 / r)                // fld1; de f1 FDIVRP st(1),st: st1 = st0/st1 = 1/r
0xA3198B–1995   sc  = f32(inv · max)
0xA31999–19A7   l0 = f32(l0 · sc)
0xA319AB–19B1   l1 = f32(sc · l1)
0xA319B5–19BB   l2 = f32(l2 · sc)
0xA319BF        elem[3] = sc                      // [ecx+0xC], ecx = edx = [esp+0x1C] (0xA3197D, 0xA31983)
0xA319C2–19CA   push l0, l1, then fldz            // Z re-created
  no scale:
0xA319CE–19D2   elem[3] = 1.0                     // [edx+0xC]
  both arrive at 0xA319D9 with stack [Z, l1, l0]
0xA319D9–19E3   p2 = f32(radius · l2)             (radius = [ebx+0x88]; l2 scaled or not per branch)
// row 0 apply with l0
0xA319E7–1A40   tA_j = f32(l0·A.invI_j); mA = f32(l0·A.invMass); tB_j = f32(l0·B.invI_j); mB = f32(l0·B.invMass)
0xA31A47–1A98   pA_j = f32(n0_j·mA); pB_j = f32(n0_j·mB)
0xA31A9F–1AC3   A.lin_x = f32(pA_x + A.lin_x); A.lin_y = f32(pA_y + A.lin_y); A.lin_z = f32(A.lin_z + pA_z)
0xA31AC6–1AEA   B.lin_j = f32(B.lin_j − pB_j)
0xA31AED–1B4C   tA_x = f32(tA_x·angA0_x); tA_y = f32(angA0_y·tA_y); tA_z = f32(angA0_z·tA_z); tB_j likewise with angB0
0xA31B53–1B9E   A.ang_x = f32(A.ang_x + tA_x); A.ang_y = f32(A.ang_y + tA_y); A.ang_z = f32(tA_z + A.ang_z)
                B.ang_x = f32(tB_x + B.ang_x); B.ang_y = f32(B.ang_y + tB_y); B.ang_z = f32(tB_z + B.ang_z)
0xA31BA1–1BA7   elem[0] = f32(l0 + elem[0])
// row 1 apply with l1
0xA31BA9–1C02   tA_j = f32(A.invI_j·l1); mA = f32(A.invMass·l1); tB_j, mB likewise
0xA31C09–1C54   pA_x = f32(mA·n1_x); pA_y = f32(n1_y·mA); pA_z = f32(mA·n1_z); pB_j likewise
0xA31C5B–1C7F   A.lin_x = f32(pA_x + A.lin_x); A.lin_y = f32(A.lin_y + pA_y); A.lin_z = f32(pA_z + A.lin_z)
0xA31C82–1CA6   B.lin_j = f32(B.lin_j − pB_j)
0xA31CA9–1D08   tA_j = f32(angA1_j·tA_j); tB_j = f32(angB1_j·tB_j)
0xA31D0F–1D5A   A.ang_j = f32(tA_j + A.ang_j); B.ang_j = f32(tB_j + B.ang_j)
0xA31D5D–1D60   elem[1] = f32(l1 + elem[1])
// rolling row: angular only, no linear and no invMass term
0xA31D63–1DA8   uA_j = f32(p2·A.invI_j); uB_j = f32(p2·B.invI_j)          j = x,y,z
0xA31DAF–1E0E   uA_j = f32(angAr_j·uA_j); uB_x = f32(uB_x·angBr_x); uB_y = f32(angBr_y·uB_y); uB_z = f32(angBr_z·uB_z)
0xA31E15–1E6D   A.ang_x = f32(uA_x + A.ang_x); A.ang_y = f32(uA_y + A.ang_y); A.ang_z = f32(A.ang_z + uA_z)
                B.ang_x = f32(uB_x + B.ang_x); B.ang_y = f32(uB_y + B.ang_y); B.ang_z = f32(B.ang_z + uB_z)
0xA31E70–1E73   elem[2] = f32(p2 + elem[2])
// advance
0xA31E1F/0xA31E28  elem += 4 floats (edx += 0x10 → [esp+0x1C])
0xA31E22           rec  += 0x90
0xA31E76–1E80      if next opcode == 1 → 0xA2F9D3 else → 0xA2F9EB        (Z on the stack)
```

Elem writes: `elem[0] += l0`, `elem[1] += l1`, `elem[2] += p2` (radius-scaled), `elem[3] = sc or 1.0`. P.

Scale formulas, verified as two different sequences: 0x15 `sc = f32(sqrt(f32(mx2/S)))` (0xA3218C–0xA3219F);
0x16 `sc = f32(f32(1/f32(sqrt(S))) · max)` (0xA31970–0xA31995). P.

## 4. The second per-iteration loop (0xA35430 → 0xA3547E; jump table 0xA36364) — P

### 4.1 Entry, "last", and exit

```
0xA35430   (opcode 0 = end of the stream)  [esp+0x16C] = Z (firstMicro = 0.0); micro = [esp+0x34] − 1
0xA35444   if micro > 0: walk again (0xA2F9C0)
0xA3544A–5461  last = ([esp+0x3C] == si.numSteps([si+0x114]) − 1)  → byte [esp+0x33]   (iter counter [esp+0x3C],
               set 0 at 0xA2F980, incremented at 0xA35B62)
0xA35466   a = accumulators base [ebp+0x10]            (acc 0, the fixed accumulator, is included)
0xA35472   t = u8 a[+0]; if t > 3 → 0xA35B52 (which re-dispatches the same a: an endless loop; unreachable for valid data)
0xA3547E   jmp [0xA36364 + 4t]:  0 → 0xA35B83, 1 → 0xA35948, 2 → 0xA35485, 3 → 0xA35B5B   (xxd of 0xA36364)
0xA35B5B–5B6F  type 3: iter += 1; if iter < [si+0x114] → 0xA2F99F (next iteration: firstMicro = 1.0, micro =
               [si+0x118], rec = schemas, elem = elemTemp base)
0xA35B75–5B82  else pop Z; return 1
```

x87: every case is entered with [Z] on the stack. Types 1/2 end at 0xA35B24–0xA35B4F with [Z]; type 0 ends with an
empty stack and pushes a new Z at 0xA362C7. P.

Accumulator fields (spec §1.6): lin = a+0x10..0x1C, ang = a+0x20..0x2C, sumLin = a+0x40..0x4C, sumAng = a+0x50..0x5C,
class = u32 a+0x04. Type 0 addresses them through `ecx = a + 0x48` (0xA35B86): ecx−0x38 = +0x10, ecx−0x28 = +0x20,
ecx−0x8 = +0x40, ecx+0x8 = +0x50.

### 4.2 Sanity test, damping test (types 0 and 2; the code is duplicated: type 2 0xA35485–0xA35946, type 0 0xA35B83–0xA36080)

```
rec   = si + 0x64 + 0x1C·class          lea eax,[si + 4·(7·class) + 0x64]   0xA35488–A354A8 / 0xA35B8C–A35BA2
al_j  = |lin_j|, aa_j = |ang_j|          fabs, stored f32 (exact)           j = x,y,z,w (4 lanes)
r0    = rec[0]  (f32)
t_j   = f32(al_j · r0)                                                       j = x,y,z,w
r1    = rec[1]  (f32)
m_j   = f32(r1·aa_j + t_j)               r1·aa_j unrounded, t_j already f32   j = x,y,z,w
one   = f32(si[+0x00])
B     = qword [0xB6D6C0] = 1e6 (bytes 00 00 00 00 80 84 2E 41)
okAbs_j  = (al_j < B) and (aa_j < B)     each by fcom/fcomp + test ah,5|0x41: true only when ordered and strictly less
okNaN_j  = (lin_j == lin_j) and (ang_j == ang_j)    fucompp x,x; test ah,0x44; jp → bit only when ordered
valid  = for j in {x,y,z}: okAbs_j and okNaN_j      // masks ANDed, then `and eax,0xE; cmp al,0xE`: the w bit (1)
                                                    // is computed and dropped
if not valid:                                       // 0xA357A7–A357EC / 0xA35EC3–A35F08
    lin.xyzw = dword[0xBF65A0..AC] = (1,0,0,0); ang.xyzw = (1,0,0,0)     (file bytes 00 00 80 3F, 0, 0, 0)
// m_j is NOT recomputed after the reset: the tests below use m from the pre-reset values
belowOne_j = (m_j <= one)                // ordered only: NaN m → false   (x: fcom one,m; test ah,1;
                                         // y,z,w: fcom m,one; test ah,0x41; jp)
if belowOne_x and belowOne_y and belowOne_z:        // w tested, masked out
    r3 = rec[3] (f32)
    belowR3_j = (m_j <= r3)              // same senses, NaN → false
    if belowR3_x and belowR3_y and belowR3_z:
        lin.xyzw = ang.xyzw = 0.0        // fst Z ×8 (+0.0)
    else:
        r2 = rec[2] (f32)
        ang_j = f32(r2 · ang_j)  j = x,y,z,w ; then lin_j = f32(r2 · lin_j)  j = x,y,z,w
```

Addresses for type 2: |.| 0xA35485–0xA35535; t/m 0xA3553C–0xA355FA; one 0xA35601; abs tests 0xA35607–0xA356BE; NaN
tests 0xA356C0–0xA357A5; reset 0xA357A7–0xA357EC; ≤one 0xA357EF–0xA35864; ≤rec[3] 0xA3586A–0xA358D0; zero
0xA358D2–0xA358EA; scale 0xA358EC–0xA3593E. Type 0: 0xA35B89–0xA35C36, 0xA35C3D–0xA35D03, 0xA35D0A, 0xA35D10–0xA35DC9,
0xA35DCB–0xA35EC1, 0xA35EC3–0xA35F08, 0xA35F0B–0xA35F8B, 0xA35F91–0xA36002, 0xA36004–0xA3601C, 0xA3601E–0xA36076. P.

Type 2 then continues into the type 1 body at 0xA35948 (falls through / `jmp 0xA35948`). Type 1 has no sanity and
no damping test. P.

### 4.3 Blend (type 1/2 at 0xA35948–0xA35B4F; type 0 at 0xA36082–0xA362BE)

```
dl_j = f32(lin_j − sumLin_j)     j = x,y,z,w        0xA35948–A3596F / 0xA36082–A360A8
da_j = f32(ang_j − sumAng_j)     j = x,y,z,w        0xA35973–A35997 / 0xA360AC–A360D0
f    = f32(si[+0x30])            one dword, used for all 8 lanes (reloaded once for the angular half)
sumLin_j = f32(f·dl_j + sumLin_j)    product unrounded    j = x,y,z,w   0xA3599B–A359F1 / 0xA360D4–A3611C
sumAng_j = f32(f·da_j + sumAng_j)    product unrounded    j = x,y,z,w   0xA359F4–A35A32 / 0xA3611F–A36176
if last ([esp+0x33] != 0):                                              0xA35ADA–A35B22 / 0xA36225–A3627B
    sumLin_j = f32(invIVF · sumLin_j) ; sumAng_j = f32(invIVF · sumAng_j)   j = x,y,z,w
    lin_j = dl_j ; ang_j = da_j                                          j = x,y,z,w (the f32 values)
else:                                                                   0xA35A40–A35AD8 / 0xA3617F–A36223
    lin_j = f32( f32(sumLin_j + dl_j) + g_j )   (sumLin_j the new value; inner sum stored f32 first)   j = x,y,z,w
    ang_j = f32(sumAng_j + da_j)                                                                       j = x,y,z,w
stores                                                                  0xA35B24–A35B4F / 0xA3627B–A362BE
```

- `invIVF = f32(si[+0x120] · si[+0x40])` = local [esp+0x38], computed once at 0xA2F98C–0xA2F995. P.
- `g`: type 0 = locals [esp+0x5E0..0x5EC], dword copies of si+0x10..+0x1C (globalAccelerationPerSubStep) made at
  0xA2F874–0xA2F8A5 (0xA361CF–0xA36207). Types 1/2 = dword[0xB132F0..FC] = +0.0 ×4 (file bytes all zero)
  (0xA35A90–0xA35AC4). The add is executed: a −0.0 inner sum becomes +0.0 for types 1/2. P.
- The sum update is `f·dl + sum` (product first), 4 lanes each. P.
- After the stores: type 0 does `fldz` and, if the next accumulator is type 0, jumps straight to 0xA35B89 (no jump
  table); otherwise 0xA35B52 → 0xA35472. Types 1/2 go to 0xA35B52 → 0xA35472. The loop ends at a type-3
  accumulator (0xA35B5B, §4.1). P.

## 5. Corrections to the spec (contact_solve.md)

1. §7.7 `m_j = f32(rec[1]·|ang_j| + |lin_j|·rec[0])`: the lin product is rounded to f32 first:
   `m_j = f32(rec[1]·|ang_j| + f32(|lin_j|·rec[0]))` (0xA35546–0xA355AF, 0xA35C47–0xA35CB8).
2. §7.7: m is computed before the 1e6/NaN reset and is not recomputed after it (0xA3553C vs 0xA357A7; 0xA35C3D vs
   0xA35EC3).
3. §7.7 "all m_j" / "any … (j=x,y,z)": all four lanes are computed and compared, and the w bit is masked out by
   `and eax,0xE` (0xA357A0, 0xA3585F, 0xA358CB, 0xA35EBC, 0xA35F86, 0xA35FFD). The damping and zeroing act on all four
   lanes of lin and ang.
4. §7.7 non-last branch: `lin = f32(f32(sumLin + dl) + g)`, with the inner sum stored as f32 before g is added
   (0xA35A40–0xA35AC4, 0xA3617F–0xA36207). The sum used is the already-updated sum.
5. §7.7 sum update: exactly `f32(f·dl + sum)` with f the single dword si+0x30 for every lane.
6. §7.6 0x16 rolling apply: `A.ang_j = f32(A.ang_j + f32(angAr_j · f32(p2 · A.invI_j)))`, with two separate f32
   roundings, and likewise for B (0xA31D63–0xA31E6D).
7. §7.6: in both cases all rows' rhs − Jv are computed from the velocities at case entry, before any row is applied.
   The spec's "apply l0 on row 0, then l1" order is right for the applies.
8. §7.6 bound-semantics ranges: the compare and scale of 0x15 sit at 0xA32183–0xA321DD and those of 0x16 at
   0xA31961–0xA319D7, inside the ranges the spec cites. The senses agree with the spec (no change).

No other disagreement: the 0x15 and 0x16 scale formulas, `elem[2]` / `elem[3]` = sc or 1.0, l0/l1 association, S
association, the type 2 → type 1 fall-through, the 0xBF65A0 reset, and "last" = iter == si+0x114 − 1 all match.

## 6. ND

- The body of `_CIsqrt` (MSVCR80, not in the exe). The result is `f32(sqrt(x))` for any correctly rounded
  implementation: I.
- Whether every dispatcher entry leaves `edx = [esp+0x1C]` is checked only for the paths listed in §0. That it holds
  for the joint cases (0x1A–0x1C) is I.
- That the 0xA3157D tail belongs to the 0x13 case is I (it is reached from 0xA30ACC and 0xA313A7).

Checks run (P):
- **g locals:** the only writes to `[esp+0x5E0..0x5EC]` in 0xA2F840–0xA36400 are the prologue `mov`s at 0xA2F87D–0xA2F8A5. The only later reads are 0xA361D3–0xA36200 (`tx/fl_g_writes.txt`). The callees in the walk (`_CIsqrt`, A3BD60) do not write that frame slot (A3BD60 writes only its argument byte). So g = si+0x10..+0x1C as at solve entry.
- **Sections** (`objdump -h`, `tx/fl_sections.txt`): .rdata = 0xB05000–0xBF5FFF and .data starts at 0xBF6000. 0xB132F0 (zero table) and 0xB6D6C0 (1e6) are in read-only .rdata. 0xBF65A0 (reset table) is in writable .data. Its file bytes are (1,0,0,0), which matches the runtime read cited in spec §1.10.
