# Export `FUN_00A3CE20` (si, elemTemp, schemas, accumulators): exact x87 transcription

Exe pc-v10 `game-files/canonical/dumps/mercs2_unpacked.exe`. Disassembly:
`objdump -d --x86-asm-syntax=intel --start-address=0xa3ce20 --stop-address=0xa3e9b0` → `tx/exp_dis.txt`.
Constants: `xxd` → `tx/exp_consts.txt`. Caller: `tx/exp_fd040.txt`, thunk `tx/exp_thunk.txt`.
Labels: P = read in the asm this run (address given); I = inferred; ND = not determined.

## 0. Entry, call site, arguments, return

- Thunk `0xA3EA20: e9 fb e3 ff ff  jmp 0xA3CE20` (P).
- Call site `FUN_008FD040` 0x8FD6DE–0x8FD6E9: `push ebx(=accumulators); push esi(=schemas); push ecx(=[esp+0x2c] = elemTemp);
  push ebx(=[ebp+0xc] = si); call 0xA3EA20` (P). Same values the solver got at 0x8FD677–0x8FD67B
  (`push edx(elemTemp), ebx(acc), esi(schemas), eax(si); call 0xA2F840`). The export call is guarded by
  `cmp [esp+0x30],1; jne` at 0x8FD6D7, where [esp+0x30] holds the solver's return value stored at 0x8FD68A (P; the
  push at 0x8FD689 shifts the offset by 4).
- Args in the export (after `push ebp; mov ebp,esp; and esp,-16; sub esp,0x3e4; push ebx; push esi; push edi`):
  `[ebp+8]` = si, `[ebp+0xc]` = elemTemp (float*), `[ebp+0x10]` = schemas, `[ebp+0x14]` = accumulators (P 0xA3CE2C–0xA3CEE5).
- Exit 0xA3E985–0xA3E99F: `u32 schemas[0] = breachCount` ([esp+0x11c]); four x87 pops (`fstp st(2)`, `fstp st(0)`×3)
  empty the FPU stack; `ret` (no immediate: cdecl). eax at `ret` = schemas pointer (`mov eax,[ebp+0x10]` 0xA3E98E) — the
  caller overwrites eax at 0x8FD6F1 without reading it, so the function is effectively **void** (P).
- x87 throughout: 1569 instructions in 0xA3CE20–0xA3E99F, **1151** with an x87 opcode byte (D8–DF), **0** referencing xmm
  (script `tx/exp_count.py`, output `tx/exp_count.txt`) (P). Calls inside: only `0x8FD7A0` from opcode 0x18 (not contact).

Register roles across the walk (P): `esi` = schema read pointer; `ecx` = elemTemp pointer (live in the register; the
`[esp+0x14]` copies are scratch); `edx` = current properties pointer (spilled to `[esp+0x18]`); `ebx` = accA, `edi` = accB.

## 1. Constants and locals (prologue 0xA3CE2C–0xA3CEC2) — P

Final-frame offsets (after the three pushes; the stores at 0xA3CE42 / 0xA3CE58 were made with 2 / 3 pushes done, so
`[esp+0x48]` at 0xA3CE42 is final `[esp+0x4c]`).

```
kN  = f32( si[0x50] * si[0x10C] )            // fld dword si+0x50 (dampDivTau); fmul dword si+0x10C (deltaTime); fstp [esp+0x4c]   0xA3CE2F–0xA3CE42
kF  = f32( si[0x58] * si[0x10C] )            // fld dword si+0x58 (dampDivFrictionTau); fmul dword si+0x10C; fstp [esp+0x188]    0xA3CE46–0xA3CE58
T4  = f32( f64(int32 si[0x114]) * si[0x10C] ) // fild dword si+0x114 (numSteps, int32); fmul dword si+0x10C; fstp [esp+0x1dc]  0xA3CE63–0xA3CE89
DT  = si[0x10C]                              // fld/fstp dword → [esp+0x14c] (exact copy)                                       0xA3CE90–0xA3CE99
```
Each product is of two f32 (or an int32) and fits 53 bits exactly, so each is a single rounding to f32.

Integer locals: `[esp+0x18]` props = 0, `[esp+0x38]` stride = 0, `[esp+0x11c]` breachCount = 0, `[esp+0x18c]` hdrC = 0,
`[esp+0x48]` accA = 0 (ebx), `[esp+0x44]` accB = 0 (edi), `[esp+0x118]` logPtr = schemas + 0x10, `[esp+0x14]` = elemTemp.

**Persistent x87 stack** during the whole walk (loaded 0xA3CEA7–0xA3CEBC):
`st0 = C = qword [0xBEA9F0] = 0x3FF8000000000000 = 1.5`, `st1 = DT`, `st2 = T4`, `st3 = kF`. Confirmed by the re-load at
0xA3E140–0xA3E15B (fld C, DT, T4, kF) followed by `fxch st3; fxch st1; fxch st2; fxch st1` at 0xA3CEC4, which restores the
same order. kN is **not** on the stack; it is read from `[esp+0x4c]`. C and DT are not used by opcodes 0x0F–0x16 (I: they
belong to other opcodes). Every contact handler returns to the dispatcher with this 4-deep stack intact (P, traced below).

## 2. Schema walk

Dispatcher 0xA3CECC: `al = byte [esi]; [esp+0x37] = al; eax = movsx(al); if (unsigned)eax > 0x1C: goto 0xA3CECC`
(the `ja` re-reads the same byte: an endless loop on a bad opcode, P); else `jmp [0xA3E9A0 + 4*eax]`.

Jump table 0xA3E9A0 (29 dwords, P): 0→0xA3E985, 1→0xA3CEE1, 2→0xA3E546, 3→0xA3CF5C, 4→0xA3CECC, 5→0xA3D2C4,
6/7→0xA3D2BB, 8→0xA3D462, 9→0xA3D445, A→0xA3D7F8, B→0xA3D60A, C→0xA3D611, D→0xA3D708, E→0xA3D6EB,
**0x0F/0x10→0xA3D25F, 0x11/0x12→0xA3D266, 0x13/0x14→0xA3CF7A, 0x15→0xA3D978, 0x16→0xA3DC7D**, 0x17→0xA3E160,
0x18→0xA3E068, 0x19→0xA3CECC, 0x1A→0xA3E168, 0x1B→0xA3E368, 0x1C→0xA3E54E.

### Opcode 0 — end (0xA3E985) — P
`u32 [schemas] = breachCount` (always written, also when 0, so it overwrites the first header's first dword); pop the 4
x87 values; return.

### Opcode 1 — header (0xA3CEE1–0xA3CF57) — P
```
stride  = u8 [esi+1]                     -> [esp+0x38] (zero-extended dword)
props   = u32 [esi+8]                    -> edx, [esp+0x18]      // &properties[0]
accA    = accumulators + (u16 [esi+4] << 7) -> [esp+0x48] -> ebx
accB    = accumulators + (u16 [esi+6] << 7) -> [esp+0x44] -> edi
hdrC    = u32 [esi+0xC]                  -> [esp+0x18c]          // per spec §6.1 = q+0x48 (the constraint instance)
esi += 0x10
if props == 0:                                                   // 0xA3CF0F jne; skip loop 0xA3CF1E–0xA3CF49
    al = byte [esi]
    while (signed)al > 4 and (signed)al < 0x19:
        ecx += 4 * DAT_00CE0444[al]      // elemTemp floats
        esi += DAT_00CE0424[al]          // record size
        al = byte [esi]
    [esp+0x14] = ecx
ebx = accA; edi = accB; edx = props; goto dispatch
```
So a header with a null properties pointer skips its records without writing anything, but still consumes their elemTemp
floats.

Tables (file bytes, P): `DAT_00CE0424` record size: 0–3 = 0x10, 4 = 0xFF, 5 = 0x30, 6–8 = 0x40, 9 = 0x50, A = 0x40,
B = 0x20, C/D = 0x30, E = 0x40, 0x0F–0x12 = 0x30, 0x13–0x15 = 0x70, 0x16 = 0x90, 0x17/0x18 = 0x20, 0x19–0x1C = 0xFF.
`DAT_00CE0444` elemTemp floats: 0–4 = 0xFF, 5–7 = 1, 8 = 2, 9 = 3, A–C = 1, D = 2, E = 3, **0x0F–0x12 = 1, 0x13/0x14 = 2,
0x15 = 3, 0x16 = 4**, 0x17/0x18 = 0, 0x19–0x1C = 0xFF. The contact handlers advance esi/ecx by literal constants that
equal these table entries (below).

### Opcode 2 — goto (0xA3E546) — P
`esi += u32 [esi+4]` (byte offset added to the record's own address); no other state changes.

### Opcode 3 — property skip (0xA3CF5C) — P (not named in the spec's contact path; listed for the stride handling)
`props += u8 [esi+4] * (int16)[esp+0x38] (stride); esi += 0x10`.

### Property pointer advance in the row handlers — P
`edx += stride` (dword `[esp+0x38]`) once per contact row: 0x0F/0x11 one row (0xA3D431), 0x13 two rows (0xA3D218,
0xA3D24D). 0x15/0x16 do not touch props or edx (0x16 borrows edx for the export pointer and restores it from
`[esp+0x18]` at 0xA3E05F).

## 3. Common row sub-expression `Jsum(row)` — P

For a row whose record floats are `l[0..2]` (linear), `a[0..2]` (angular A), `b[0..2]` (angular B), with
`A = ebx`, `B = edi`, the code computes per lane k ∈ {x,y,z} (index i = 0,1,2):

```
dl_k  = f32( A[0x40+4i] - B[0x40+4i] )          // fld A; fsub B (A − B)
pa_k  = f32( a[i] * A[0x50+4i] )                // angular A × A.sumAng
pb_k  = f32( b[i] * B[0x50+4i] )                // angular B × B.sumAng
pl_k  = f32( l[i] * dl_k )                      // l[0] is the record's tagged first float as stored (fld dword [rec])
s_k   = f32( pb_k + pa_k )                      // fld pb; fadd pa
t_k   = f32( pl_k + s_k )                       // fld pl; fadd t
Jsum  = f32( (t_y + t_x) + t_z )                // fld t_y; fadd t_x; fadd t_z; fstp — the inner y+x is NOT rounded to f32
```
Products and two-operand adds of f32 values are commutative and single-rounded, so the fld/fmul operand order (which varies
between lanes, e.g. `fld A50; fmul rec` vs `fld rec; fmul A50`) does not change bits; only the association above matters.
The rolling row of 0x16 has no linear part: `t_k = s_k` (§4.5).

`solverData`-type term for a row, unless noted otherwise:
```
r   = f32( rhs * k )                 // k = kN (contacts) or kF (friction); stored to a dword local
p   = f32( Jsum * T4 )               // fld Jsum; fmul st, st(T4); fstp [esp+0x10]
v   = f32( r - p )                   // fld r ... fsub dword [esp+0x10]  (r − p)
```

## 4. Opcode handlers

### 4.1 0x0F / 0x10 single contact (0xA3D25F → 0xA3D2CF–0xA3D440) — P
```
rec = esi; esi += 0x30
row: l = rec[0..2], a = rec[4..6] (+0x10), b = rec[8..10] (+0x20), rhs = rec[3] (+0xC)
  lanes: pa 0xA3D2CF–0xA3D2EF ([esp+0xb0..b8]); dl 0xA3D2F6–0xA3D316 ([esp+0x1f0..]); pb 0xA3D31D–0xA3D33D ([esp+0x300..]);
         pl 0xA3D344–0xA3D36F; s 0xA3D376–0xA3D3AE; t 0xA3D3B5–0xA3D3ED
r = f32(rec[3] * kN)                        // fld [eax+0xc]; fmul dword [esp+0x4c]; fstp [esp+0x10]   0xA3D3F4–0xA3D3FB
props.impulse(+0) = elem[0]                 // fld [ecx]; fstp [edx]                                    0xA3D3FF–0xA3D401
Jsum = f32((t_y + t_x) + t_z)               // 0xA3D407–0xA3D41C
p = f32(Jsum * T4)                          // fmul st, st(4): stack [Jsum, r, C, DT, T4, kF]          0xA3D420–0xA3D426
props.solverData(+4) = f32(r - p)           // fsub dword [esp+0x10]; fstp [edx+4]                     0xA3D42A–0xA3D42E
edx += stride; ecx += 4
```

### 4.2 0x11 / 0x12 single contact with maxImpulse (0xA3D266–0xA3D2B9, then the 0x0F body at 0xA3D2CB) — P
```
rec = esi; esi += 0x30
t = f32( rec[0xB] * qword[0xB5AB50] )       // fld dword [eax+0x2c]; fmul qword; fstp [esp+0x10]; fld [esp+0x10]
                                            // qword 0xB5AB50 = 0x3FEFAE1480000000 = 0.9900000095367431640625 (= f32(0.99) widened)
fcompp  (st0 = t, st1 = elem[0]); fnstsw ax; test ah,5; jp skip     // 0xA3D282–0xA3D289
   ah&5: t > elem → 0 (PF=1, skip); t == elem → 0 (skip); unordered → 5 (PF=1, skip); t < elem → 1 (PF=0, log)
if t < elem[0] (ordered, strict):           // breach
    e = logPtr; logPtr += 0x10; breachCount += 1
    u32 e[0] = 0; u32 e[1] = hdrC; u32 e[2] = props (edx, the current row's properties); e[3] untouched
then the 0x0F row body (§4.1) with the same rec, elem[0], props; edx += stride; ecx += 4
```
The log is written into the schema buffer itself, from schemas+0x10 upward, 16 bytes per breach, and `schemas[0]` gets the
count at the end (P). That the write pointer stays behind the read pointer is I (each breach consumes ≥ 0x30 schema bytes
and writes 0x10; across a goto into a later buffer the log continues linearly in the first buffer — bound ND).

### 4.3 0x13 / 0x14 contact pair (0xA3CF7A–0xA3D25A) — P
```
rec = esi; esi += 0x70
row0: l = rec[0..2], a = rec[4..6], b = rec[8..10], rhs0 = rec[3]
  pa [esp+0x90..98] 0xA3CF7C–0xA3CF9F; dl [esp+0x210..] ; pb [esp+0x360..] ; pl ; s ; t  (0xA3CFA6–0xA3D09D)
r0 = f32(rec[3] * kN)      // fld rec3; fld kN; fld st0; fmulp st(2) (DE CA: st2 = rec3·kN); fxch; fstp [esp+0x10]
                           // leaves kN on the stack: [kN, C, DT, T4, kF]                               0xA3D0A4–0xA3D0B1
row1: l = rec[0xC..0xE] (+0x30, clean n1.x), a = rec[0x10..0x12] (+0x40), b = rec[0x14..0x16] (+0x50), rhs1 = rec[0xF]
  pa [esp+0xe0..] ; dl [esp+0x190..] ; pb [esp+0x280..] ; pl ; s ; t   (0xA3D0B5–0xA3D1D4)
r1 = f32(kN * rec[0xF])    // fmul dword [eax+0x3c] on the kN still in st0; fstp [esp+0x1c]              0xA3D1DB–0xA3D1E2
props0.impulse = elem[0]                                                     // 0xA3D1E6–0xA3D1E8
Jsum0 = f32((t0_y + t0_x) + t0_z); p0 = f32(Jsum0 * T4) (fmul st,st(4)); props0.solverData = f32(r0 - p0)   // 0xA3D1EA–0xA3D215
edx += stride
props1.impulse = elem[1]                                                     // 0xA3D21A–0xA3D21D
Jsum1 = f32((t1_y + t1_x) + t1_z); p1 = f32(Jsum1 * T4) (fmul st,st(4)); props1.solverData = f32(r1 - p1)   // 0xA3D21F–0xA3D24A
edx += stride; ecx += 8
```

### 4.4 0x15 2-D friction (0xA3D978–0xA3DC78) — P
```
s = elem[2] -> [esp+0x24]                      // fld [ecx+8]; fstp                                   0xA3D978–0xA3D97D
rec = esi; esi += 0x70
row0: l = rec[0..2], a = rec[4..6], b = rec[8..10]; pa [esp+0x80..88], dl [esp+0x120..], pb [esp+0x260..]   0xA3D985–0xA3DAA6
r0 = f32(rec[3] * kF)                          // fmul st, st(4): stack [rec3, C, DT, T4, kF] → [esp+0x1c]   0xA3DAAD–0xA3DAB2
row1: l = rec[0xC..0xE], a = rec[0x10..0x12], b = rec[0x14..0x16]; pa [esp+0xa0..], dl [esp+0x1a0..], pb [esp+0x270..]  0xA3DAB6–0xA3DBDC
ecx += 0xC
X = u32 rec[0x1A] (+0x68)                      // export pointer (= atom+0x18 per spec §6.6)
r1 = f32(rec[0xF] * kF)                        // fmul st, st(4) → [esp+0x40]                         0xA3DBE3–0xA3DBEB
X[0] = elem[0]                                 // [ecx-0xc]                                            0xA3DBF6–0xA3DBF9
Jsum0 = f32((t0_y + t0_x) + t0_z); p0 = f32(Jsum0*T4) (st(4)); v0 = f32(r0 - p0)                    // 0xA3DBFB–0xA3DC26
X[1] = f32(v0 * s)                             // fld v0; fld s; fld st0; fmulp st(2) (st2 = v0·s); fxch; fstp [eax+4]
                                               // leaves s on the stack: [s, C, DT, T4, kF]              0xA3DC2A–0xA3DC38
X[2] = elem[1]                                 // via [esp+0x3c]                                       0xA3DBEF–0xA3DC3F
Jsum1 = f32((t1_y + t1_x) + t1_z); p1 = f32(Jsum1*T4) (fmul st,st(5)); v1 = f32(r1 - p1)            // 0xA3DC42–0xA3DC6D
X[3] = f32(s * v1)                             // fmul dword [esp+0x10] on s; fstp [eax+0xc]           0xA3DC71–0xA3DC75
```
props and edx untouched; ecx advanced by 3 floats.

### 4.5 0x16 2-D friction + rolling (0xA3DC7D–0xA3E063) — P
```
s = elem[3] -> [esp+0x24]                      // fld [ecx+0xc]                                       0xA3DC7D–0xA3DC82
X = u32 rec[0x23] (+0x8c) -> edx               // export pointer                                       0xA3DC86
rec = esi; esi += 0x90
row0: l = rec[0..2], a = rec[4..6], b = rec[8..10]; pa [esp+0xc0..], dl [esp+0x1c0..], pb [esp+0x290..]     0xA3DC8C–0xA3DDB0
row1: l = rec[0xC..0xE], a = rec[0x10..0x12], b = rec[0x14..0x16]; pa [esp+0x100..], dl [esp+0x1e0..], pb [esp+0x2b0..]  0xA3DDB7–0xA3DED6
r1 = f32(rec[0xF] * kF)  -> [esp+0x3c]         // fmul st, st(4)                                       0xA3DEDD–0xA3DEE2
row2 (rolling, angular only): a = rec[0x18..0x1A] (+0x60), b = rec[0x1C..0x1E] (+0x70)
   pa_k = f32(a·A.sumAng) [esp+0x200..208]; pb_k = f32(b·B.sumAng) [esp+0x2d0..2d8]; t2_k = f32(pb_k + pa_k)  0xA3DEE6–0xA3DF6C
rhs2 = rec[0x1F] (+0x7c) -> [esp+0x40] (raw, not yet scaled)                                         // 0xA3DF73–0xA3DF76
r0 = f32(rec[3] * kF)                          // fmul st, st(4) → [esp+0x10]                         0xA3DF7A–0xA3DF7F
Jsum0 = f32((t0_y + t0_x) + t0_z); p0 = f32(Jsum0*T4) (st(4)); v0 = f32(r0 - p0)                    // 0xA3DF83–0xA3DFAE
w0 = f32(v0 * s)                               // fld v0; fld s; fld st0; fmulp st(2); fxch; fstp [esp+0x10]; s stays on the stack
ecx += 0x10
X[0] = elem[0]; X[1] = w0; X[2] = elem[1]      // 0xA3DFCB–0xA3DFE2
Jsum1 = f32((t1_y + t1_x) + t1_z); p1 = f32(Jsum1*T4) (fmul st,st(5)); v1 = f32(r1 - p1)            // 0xA3DFE5–0xA3E010
X[3] = f32(v1 * s)                             // fmul st, st(1)                                       0xA3E014–0xA3E01A
X[4] = elem[2]                                 // [ecx-8]                                              0xA3E01D–0xA3E020
rolling (stack [.., s, C, DT, T4, kF]):
   q2 = rhs2 * kF                              // fld [esp+0x40]; fmul st, st(5)  — NOT stored (53-bit)  0xA3E023–0xA3E027
   Jsum2 = f32((t2_y + t2_x) + t2_z)           // fld 0x204; fadd 0x200; fadd 0x208; fstp               0xA3E029–0xA3E03E
   p2 = Jsum2 * T4                             // fld Jsum2; fmul st, st(5) — NOT stored (53-bit)       0xA3E042–0xA3E046
   v2 = f32(q2 - p2)                           // DE E9 fsubp st(1): st1 = q2 − p2; fstp [esp+0x10]     0xA3E048–0xA3E04A
   u2 = f32(v2 * s)                            // fld v2; fmul st, st(1); fstp [esp+0x10]              0xA3E04E–0xA3E054
   X[5] = f32(s * u2)                          // fmul dword [esp+0x10] on s; fstp [edx+0x14]          0xA3E058–0xA3E05C
edx = [esp+0x18] (props restored)
```
The rolling term is multiplied by s twice, with an f32 store between the two multiplies (P). Rows 0/1 are multiplied once.

### Stack accounting (P)
Every contact handler leaves `[C, DT, T4, kF]`: 0x13 parks kN then consumes it at 0xA3D1DB; 0x15/0x16 park s and consume
it with the final `fmul dword [esp+0x10]`. The `st(4)`/`st(5)` operands above were checked against this depth at each use.

## 5. Corrections and additions to the spec (§8, §1.9)

1. **0x16 rolling term precision (addition):** `rhs2·kF` and `Jsum2·T4` are left unrounded on the x87 stack and combined by
   `fsubp` (0xA3E027–0xA3E04A); only the difference is stored to f32. Every other row (0x0F/0x11/0x13/0x15 and 0x16 rows 0–1)
   stores both `rhs·k` and `Jsum·T4` as f32 before subtracting. A port that rounds the rolling products differs in the last bit.
2. **0.99 constant:** qword 0xB5AB50 = 0x3FEFAE1480000000 = 0.9900000095367431640625 (f32(0.99) widened, not f64 0.99), and the
   product `row[0xB]·0.99` is stored to f32 before the compare (0xA3D27A). Breach is strict `t < elem`, ordered (NaN → no log).
3. **Opcode aliases:** 0x10, 0x12, 0x14 share the 0x0F, 0x11, 0x13 handlers; 0x12 logs breaches like 0x11.
4. **Breach log layout:** 16-byte entries from schemas+0x10: `{u32 0, u32 header[+0xC], u32 &props_i, untouched}`;
   `u32 schemas[0] = count` is written unconditionally at opcode 0.
5. **Header with props == 0** skips its records (signed opcode 5..0x18) through the size/elem tables without writing.
6. **Export runs only when the solver returned 1** (`FUN_008FD040` 0x8FD6D7) — I: assumes `call [0xB0511C]` (likely
   TlsGetValue, stdcall) pops its pushed argument; the import name was not read.
7. x87 count: 1151 instructions with an x87 opcode byte in 0xA3CE20–0xA3E99F by my count, no `9b` (wait-prefixed) forms
   (spec: 1152; ND which instruction the spec counted extra). 0 SSE either way.
9. **Slot isolation (P, grep of `exp_dis.txt` into `tx/exp_slots.txt`):** kN `[esp+0x4c]`, kF `[esp+0x188]`, T4 `[esp+0x1dc]`,
   DT `[esp+0x14c]` are written only in the prologue (and read elsewhere); breachCount `[esp+0x11c]` and logPtr
   `[esp+0x118]` are written only in the prologue and the 0x11/0x12 breach path (0xA3D299/0xA3D2A1). So `schemas[0]` counts
   maxImpulse breaches only; no other opcode logs.
8. Persistent stack also holds qword 1.5 (0xBEA9F0) and DT, unused by the contact opcodes.

## 6. ND
- Whether the breach log can overrun live schema data across a goto (bound not determined; needs FD040's buffer sizing).
- The 1151 vs 1152 x87-count difference (method).
- Use of C = 1.5 and DT (opcodes outside the contact path; not traced).
