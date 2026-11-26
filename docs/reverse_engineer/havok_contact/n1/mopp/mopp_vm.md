# pc-v10 MOPP AABB-query VM (hkpMoppBvTreeShape::queryAabb) — decoded

Exe: `game-files/canonical/dumps/mercs2_unpacked.exe`, sha256 `8c179a99…7ba` (verified this run).
All asm from `objdump -d --x86-asm-syntax=intel` into this folder: `a12380.asm`, `a49960.asm`, `a48e10.asm`.
Jump tables decoded by `tables.py` -> `tables.txt`. Emulator `pcvm.py`, port of ours `ours.py`, runs `run.py`/`run2.py`.
Grades: P = PROVEN this run, I = INFERRED, S = SPECULATIVE. "recall" = my Havok memory, at best I.

## 1. Call chain (all P)

| # | VA | role | evidence |
|---|---|---|---|
| 0 | vtable `0xB6C588` slot 11 (+0x2C) = `0xA12380` | queryAabb(aabb, hkArray<shapeKey>* out) | vtable bytes read from exe (`vt.txt`) |
| 1 | `FUN_00A12380` (thiscall, ecx=shape, ret 8) | clamp query to shape's `codeInfoCopy` frame, build VM object on stack (`lea ecx,[esp+0x40]`), call #2 | `a12380.asm` |
| 2 | `FUN_00A49960` (thiscall, ecx=VM obj; args code*, aabb*, out*; ret 0xC) | quantize query, build root state, call #3 | `a49960.asm`, call @`0xA49AC3` |
| 3 | `FUN_00A48E10` (thiscall, ecx=VM obj; args state*, pc*, chunkId; ret 0xC) | the recursive VM; self-calls @`0xA49025`, `0xA4909E`, `0xA49121` | `a48e10.asm` |
| - | `FUN_00A3EA60(4)` | one-time gate at VM entry (`0xA48E1C..0xA48E3F`, cached in byte `0xE78B7C`): Havok keycode/"Prime" component check (strings `CLIENT.PhAn.Pandemic_CentralTechAndTools` @0xBA8848, "The following component is not enabled in Havok Prime" @0xB6D914). If it returns 0 the VM returns with NO keys. | `a3ea60.asm`, `strs.txt` |

- Other entries into the same VM: slot 10 `0xA12800` (fixed-capacity output buffer variant, same clamp, `cap = param|0x80000000`) and wrapper `0xA43B50` both call `0xA49960`; slot 9 `0xA12350` calls `0xA495C0` (a different setup) which also calls `0xA48E10` (Ghidra callers list; `callers_a495c0.txt`). P.
- SecuROM: none. `pc-v10.splices.tsv` has 0 rows with a site in `0x00A1xxxx–0x00A4xxxx` (`splice_a1_a4.txt`), and all three bodies are plain contiguous code (no `jmp [0x24…]`). P.
- Assert string for unknown opcode: `.\Collide\Mopp\Machine\hkpMoppObbVirtualMachine.cpp` line 0x1C2 (=450), id `0x1298FEDD` (`0xA49404..0xA49413`, `tables.txt`). So this is Havok's `hkpMoppObbVirtualMachine` used in its AABB-query mode. P (file name); "queryAabb is implemented by the OBB machine" = I (recall, consistent with string).

## 2. Faithful pseudocode

### 2.1 Object layouts used (P from the asm + capture)
- shape (`hkpMoppBvTreeShape`): `+0x10 code*` (read @`0xA12498`), `+0x20..+0x2C codeInfoCopy` float4 (offset.xyz, w).
- `hkpMoppCode`: `+0x10..+0x18 info.offset.xyz`, `+0x1C info.w` (ints per world unit), `+0x20 m_data ptr` (read @`0xA491F9`, `0xA49A9F`).
- out `hkArray<u32>`: `+0 data`, `+4 size`, `+8 capacityAndFlags` (`& 0x3FFFFFFF` @`0xA49490`); grow = `call 0x88CF20(arr, 4)` @`0xA4949F` when size==cap.
- VM object (`ecx` in #2/#3, 0x40 B on stack of #1): `+0x00 out*`, `+0x10/14/18 qmax.xyz (int)`, `+0x20/24/28 qmin.xyz (int)`, `+0x30 code*`, `+0x34 chunkMask`.
- State (16 dwords; caller's pointer, copied to a 0x40-B local `[esp+0x20]` in #3 on first write): `+0x00/04/08 H.xyz`, `+0x10/14/18 L.xyz`, `+0x20/24/28 off.xyz`, `+0x2C primOffset`, `+0x30 shift`, `+0x34 prop0`. (+0x0C, +0x1C, +0x38, +0x3C unused by this VM.)

⚠ Capture correction (P): in `20261103_new-game-first-mission-start.dmp` the shape at `0x291DA5E0` reads `+0x08 = 0x291EF894` (userData, not a code object — `code.txt` shows `aa aa aa aa…`), `+0x10 = 0x291DA620` (the `hkpMoppCode`, vtable `0xB6F718`), `+0x14 = 0x291DA650` (moppData), `+0x18 = 0xC9AF`. The code object holds info `(-200.00998, -109.37285, -200.00998, 41613.285)` (bits `8e0248c3 e6bedac2 8e0248c3 498d2247`), data ptr `0x291DA650`, size `0xC9AF`, buildType `1`; data[0] = `0x28` → chunkMask = 0 (`code2.txt`). The brief's "code 0x291EF894, moppData 0x291DA620" is one field off.

### 2.2 FUN_00A12380 — clamp (P)
```
ext   = f32( 16777216.0 /  shape.cic.w )            // fdivr qword [0xB6D490]=2^24 (double) @A12392, fstp dword @A12398
lim.k = f32( shape.cic.k + ext )   k=x,y,z,w        // @A1239C..A123C2 (w lane: ext + cic.w, unused downstream)
// min: fcompp st0=aabb.min.k, st1=cic.k; test ah,5; jp -> take aabb   (@A123CB..A123D9 and 3 copies)
cmin.k = (aabb.min.k < cic.k) ? cic.k : aabb.min.k  // NaN -> aabb.min.k (unordered sets C0|C2|C3 -> jp taken)
// max: fcomp st0=aabb.max.k vs st1=lim.k; test ah,0x41; je -> keep lim  (@A12437..A12445 and 3 copies)
cmax.k = (aabb.max.k > lim.k) ? lim.k : aabb.max.k  // NaN -> aabb.max.k
FUN_00A49960(vm=&stackobj, code=shape+0x10, &{cmin,cmax}, out)
```
No check that cmin <= cmax: an inverted/outside query still runs (see §4).

### 2.3 FUN_00A49960 — quantize + root state (P)
```
vm.out = out; vm.code = code                                     // A4996F, A49974
w = code.info.w   (fld [eax+0x1c] -> f32)                         // A49977
for k in x,y,z:
   t     = f32( (cmin.k - code.info.off.k) * w )   // fld f32; fsub dword; fmul dword; fstp dword (A49986..A49990)
   vm.qmin.k = fistp(t) - 1                        // fistp = current x87 RC (RC=0 nearest-even, see §2.6); add esi,-1
   t     = f32( (cmax.k - code.info.off.k) * w )
   vm.qmax.k = fistp(t) + 1                        // add esi,+1
// root state  (movsx word [vm+0x12] == qmax.x >> 16 arithmetic)
S.H.k   = (vm.qmax.k >> 16) + 1                    // A49A5B..A49A62, A49A6E..A49A78, z: sar edx,0x10; add 1 @A49A83
S.L.k   =  vm.qmin.k >> 16                         // movsx word [vm+0x22/26/2a] @A49A4F, A49A66, A49A7C
S.off = 0,0,0; S.prim = 0; S.shift = 0; S.prop0 = 0             // A49A93..A49AB9
vm.chunkMask = (code.data[0] == 0x0D) ? 0xFFFFFFFF : 0           // cmp byte [eax],0xd; setne; sub 1 @A49AA4..A49AC0
FUN_00A48E10(vm, &S, code.data, chunkId = 0)
```
Port requirements for edge inputs (P from x86 semantics of the instructions; NOT modelled by `pcvm.py`, which is valid only for in-range finite inputs):
- The clamp bounds min only from below and max only from above, so a min far above the frame, a max far below it, or any NaN reaches `fistp` unclamped. `fistp` of NaN, ±inf, or |t| ≥ 2^31 (|x−off| > ~51.6 km at w = 41613) stores the integer-indefinite `0x80000000`; then `−1`/`+1` wrap in 32 bits (`0x80000000 − 1 = 0x7FFFFFFF`).
- All state arithmetic is 32-bit wrapping (`add`, `sub`, `shl`), shifts are `sar` with count `& 31` (REANCHOR with `shift > 16` gives count `(16−shift)&31`), key add `S.prim + v` wraps.

Root `>>16` is a constant: the root byte operand sits in bits 16..23 of a 2^24-wide integer frame (`ext = 2^24 / w` in §2.2). Confirms `ROOT_SHIFT = 16`. P.

### 2.4 FUN_00A48E10 — the VM (P; every compare re-read from objdump; all compares are SIGNED 32-bit int)
Dispatch @`0xA48E50`: `op = *pc; if op > 0x6B -> INVALID; jmp [0xA494C0 + 4*byte[0xA49548+op]]`. Opcode→handler map in `tables.txt`.
`return` below = `0xA494B7` (or the identical epilogues @A49001/A49056) — ends THIS invocation (subtree done).
`recurse(p)` = `FUN_00A48E10(vm, S_current, p, chunkId_current)`; afterwards the caller continues with ITS state and chunkId.
State writes are copy-on-write into this invocation's local (`rep movsd` 16 dwords @A492CE/A49302/A49348/A493C5); 0x01–0x04 rebuild the local wholesale.

```
loop:
 op = byte[pc]
 0x00:            return                                                    // table idx 0 -> A494B7
 0x01..0x04 (A49203):  n = op
      noff.k = (pc[1+k] + S.off.k) << n            // shl edx/eax, cl (cl = op)
      ns     = S.shift + n                         // A49224..A49227
      sh     = 16 - ns                             // mov ecx,0x10; sub (A4922B..A49238); sar uses sh & 31
      Loc.L.k = (vm.qmin.k >> sh) - noff.k         // sar, sub  (A49240..A49265)
      Loc.H.k = (vm.qmax.k >> sh) - noff.k + 1     // (A4926D..A492A2)
      Loc.off = noff; Loc.shift = ns; Loc.prim = S.prim; Loc.prop0 = S.prop0
      S = &Loc; pc += 4
 0x05 (A491A3): pc += 2 + pc[1]
 0x06 (A491B1): pc += 3 + BE16(pc+1)
 0x07 (A491C8): pc += 4 + BE24(pc+1)
 0x09 (A492B9): S.prim += pc[1];        pc += 2     // add [esp+0x4c]
 0x0A (A492E4): S.prim += BE16(pc+1);   pc += 3
 0x0B (A49318): S.prim  = BE32(pc+1);   pc += 5     // mov (set)
 0x0C (A491E8): chunkId = BE16(pc+1) (ah=pc[1], al=pc[2]); pc = code.data + (chunkId << 9)   // stored to [ebp+0x10]
 0x0D (A49356): pc += 5                              // no other effect in this VM
 0x10..0x12 axis a=op-0x10 (A49033):  b1=pc[1], b2=pc[2], b3=pc[3]; pc += 4
      if S.H.a > b2:                    // cmp [esi+4*op-0x40],eax(b2); jg A4905F
           pc += b3                     // offset child
           if S.L.a >= b1: goto loop    // jge A48E50  (offset child only)
           recurse(pc - b3); goto loop  // inline child FIRST, then offset child
      if S.L.a < b1: goto loop          // cmp edx(L),[b1]; jl -> inline child only
      return
 0x13..0x1C diagonal (A48E6A..A48FED -> common tail A48FF0): compute (Hc, Lc, R, T), pc += 4
      if Hc > R  (cmp ecx,[esp+0x10]; jg A4900A):
           if Lc < T (jl A4901D): recurse(pc); pc += pc_old[3]; goto loop   // inline first, then offset
           pc += pc_old[3]; goto loop                                        // offset only
      if Lc < T (cmp eax,edx; jl A48E50): goto loop                         // inline only
      return
      op   Hc                    Lc                    R              T
      13   H.z+H.y               L.z+L.y               2*b2           2*b1
      14   H.y-L.z               L.y-H.z               2*b2-255       2*b1-255
      15   H.z+H.x               L.z+L.x               2*b2           2*b1
      16   H.x-L.z               L.x-H.z               2*b2-255       2*b1-255
      17   H.y+H.x               L.y+L.x               2*b2           2*b1
      18   H.x-L.y               L.x-H.y               2*b2-255       2*b1-255
      19   H.z+H.y+H.x           L.z+L.y+L.x           3*b2           3*b1
      1A   H.y-L.z+H.x           L.y-H.z+L.x           3*(b2-0x55)    3*(b1-0x55)
      1B   H.z-L.y+H.x           L.z-H.y+L.x           3*(b2-0x55)    3*(b1-0x55)
      1C   H.x-L.z-L.y           L.x-H.z-H.y           3*(b2-0xAA)    3*(b1-0xAA)
      (b1=pc[1], b2=pc[2]; 255 = `lea r,[r+r-0xff]`; handlers A48E6A/8B/B6/D6/F00/F20/F44/F6C/F97/FC2)
 0x20..0x22 axis a=op-0x20 (A49071): v=pc[1]; pc += 3
      if S.H.a <= v: goto loop           // jle -> inline child only
      pc += pc_old[2]                    // offset child
      if S.L.a > v: goto loop            // jg  -> offset child only
      recurse(pc - pc_old[2]); goto loop // inline first, then offset
 0x23..0x25 axis a=op-0x23 (A490A8): b1=pc[1], b2=pc[2], lo=BE16(pc+3), ro=BE16(pc+5); pc += 7
      if S.H.a > b2:                     // cmp [esi+4*op-0x8c],edx(b2); jg A490F2
           if S.L.a >= b1: pc += ro; goto loop          // jge
           recurse(pc + lo); pc += ro; goto loop        // "lo" child FIRST, then "ro" child
      if S.L.a >= b1: return             // jge A494B7
      pc += lo; goto loop
 0x26..0x28 CUT axis a=op-0x26 (A4912B):
      if S.H.a <  pc[1]: return          // cmp [esi+4*op-0x98],eax; jl
      if S.L.a >= pc[2]: return          // cmp [esi+4*op-0x88],edx; jge
      pc += 3
 0x29..0x2B CUT24 axis a=op-0x29 (A49155):   NOTE compares the VM's GLOBAL ints (edi), not the state
      if vm.qmax.a <  BE24(pc+1): return // cmp [edi+4*op-0x94],eax; jl
      if vm.qmin.a >  BE24(pc+4): return // cmp [edi+4*op-0x84],eax; jg
      pc += 7
 0x30..0x4F: v = op - 0x30  (A49478: add ecx,-0x30)     | 0x50: v=pc[1] | 0x51: BE16 | 0x52: BE24 | 0x53: BE32
      key = (vm.chunkMask & (chunkId << 8)) | (S.prim + v)     // A4947B..A49495 (32-bit add, then OR)
      // NO re-indexing: the handler reads only vm+0x34, vm+0x00, S+0x2C and the operand. No
      // hkpMoppCodeReindexedTerminal table (or any other memory) is consulted.
      out.push(key)  (grow via 0x88CF20 if size==cap)          // A49497..A494B5
      return                                                    // a terminal ends the subtree
 0x60..0x63 (A4935E): store pc[1]   ; pc += 2
 0x64..0x67 (A4936E): store BE16    ; pc += 3
 0x68..0x6B (A49387): store BE32    ; pc += 5
      store goes to local [esp + 4*op - k] = Loc+0x34 for 0x60/0x64/0x68 (prop0), Loc+0x38.. for the others;
      then (A493B0) prop0 is saved, state copied to local if not yet local, prop0 restored. Only prop0 survives a
      copy. Neither prop0 nor the others are read by terminals in this VM -> no effect on keys.
 INVALID (08, 0E, 0F, 1D–1F, 2C–2F, 54–5F, >6B): hkError report (vtable [0xDFE784]+0xC, type 3) then
      `jmp 0xA48E50` with pc UNCHANGED (A49425) -> re-dispatches the same byte (loops unless the error handler aborts).
```

Inequality reading (I — algebra from the integer code above; the integer code is what to port):
with `r(x) = fistp(f32((x-off)*w))`, current cell size `2^k` (`k = 16 - shift`), absolute node origin `O = off<<k`:
- axis split: inline child iff `r(min) <= O + b1·2^k`; offset child iff `r(max) >= O + b2·2^k - 1`.
- CUT 0x26–0x28: keep iff `r(max) + 1 >= O + (b1-1)·2^k` and `r(min) <= O + b2·2^k` — the lower plane is effectively ONE CELL lower than `b1`.
- CUT24: keep iff `r(max) >= v1 - 1` and `r(min) <= v2 + 1`.

### 2.5 Key order (P)
Depth-first, pre-order. At every two-child split the child at `pc_after_header` (0x10–0x22, "inline") or at `pc_after_header + BE16(+3)` (0x23–0x25) is completely enumerated by the recursive call BEFORE the offset child, which then continues in the same invocation. A terminal returns. Keys are appended (the VM never clears `out.size`).

★ What the agent actually consumes (P): the MOPP agent `FUN_008C61A0` (rtti `hkpBvTreeAgent`/`hkpMoppAgent`) calls slot 11 and then, when byte `DAT_00E74809 == 0`, sorts the key array ASCENDING with `FUN_008BEC50(keys, 0, n−1)` @`0x8C709B` (only if `n > 1`) before merging it with its cached child-agent list. `FUN_008BEC50` is an in-place recursive quicksort, UNSIGNED compares (`jae`/`jb` @`0x8BEC73`/`0x8BEC7B`/`0x8BEC80`/`0x8BEC88`), middle pivot `a[(lo+hi)>>1]`, no dedupe (`sort_8bec50.asm`). `DAT_00E74809` = `0x00` in the capture (`flag_e74809.txt`); its only readers in 0x880000–0xA40000 are `0x8C5A78` and `0x8C6D69` (`flag_refs.txt`). The flag-set path (`!= 0`) uses the VM order unsorted. Same sort-after-query in `FUN_008C5830` and the stream agent `FUN_008BD8A0` (@`0x8BE611`). So with the flag at 0 the order a port must match downstream is the SORTED order; the DFS order matters only for the flag≠0 path or for code that reads the array before the sort. Recall (I): the flag is Havok's `hkpBvTreeAgent::m_useFastUpdate`.

### 2.6 Floating-point mode (P for the capture, I for the query thread)
Minidump thread contexts (`fpucw.py` → `fpucw.txt`): 27 of 28 threads have x87 CW `0x027F` (PC=53-bit, RC=nearest), one thread (tid 11456) has `0x007F` (PC=24-bit, RC=nearest) — that it is the D3D9 device thread is SPECULATIVE (recall: D3D9 CreateDevice without FPU_PRESERVE sets PC=24). Which thread runs queryAabb is NOT DETERMINED. RC is nearest-even on every thread → `fistp` = round-half-even (P for the capture). Effect of PC on the quantizer: `f32(f32(x-off)*w)` (PC=24) vs `f32((x-off)*w in double)` (PC=53) changed a quantized bound in 13,156 of 20,000 random queries but changed the returned key sequence in 0 of them (`prec.py` → `prec.txt`).

## 3. Comparison with ours (`crates/mercs2_formats/src/mopp.rs` @ `74ae0baa`, `docs/reverse_engineer/mopp_bytecode_format.md`)

Ours has a real AABB query (`query_aabb` / `query_aabb_shift`, mopp.rs:855–1078), not only a FindAll enumerator (`decode`, mopp.rs:95–253). It is a float-box walk (node box reconstructed in world space, f64 planes, `eps = max(1.5*scale, 1e-4)` slop), not the PC integer machine.

Measured on the REAL Rust code: scratch crate `rustq/` (path dependency on the worktree's `mercs2_formats`, target dir inside scratch, no repo file changed; mopp.rs is unmodified vs HEAD `74ae0baa` per `git status`) runs `mopp::query_aabb` with `MoppInfo{offset, scale: 1.0/lane3}` exactly as `extract_mopp_with_info` builds it (`rustcmp.py` → `rustcmp.txt`, 3,504 queries): Rust == `ours.py` on 3,504/3,504; Rust == PC sequence 2,613; Rust strict superset 835; **Rust misses a PC key in 56** (the 55 below + the outside-frame case); Rust order filtered to PC's keys == PC order 3,448 (= 3,504 − 56). All-space: 4,308 keys, same sequence as PC. P.

Measured with `ours.py` (port, identical outputs to the Rust on every query above) on the captured terrain MOPP (51,631 B; `run.py`, `run2.py`, `outside.py`):
- All-space query: PC and ours return the IDENTICAL 4,308-key sequence (first keys `0,13,14,1,33,42,49,50,51,2,3,43,…`; keys span `0…0x02000217`). P.
- 3,500 random queries (`run2_out.txt`): same sequence 2,612; ours a strict superset 833; ours MISSES keys the PC returns in 55. Whenever ours is a superset, ours filtered to PC's keys equals PC's order (3,445 order-ok = 3,500 − 55). P.
- Every miss traced (`diag*.py`) to a CUT 0x26–0x28 whose lower operand `b1` equals the query's top cell + 1: PC keeps (`H >= b1`), ours prunes (`qmax < plane(b1) - eps`). Examples: `28 01 a5` @41068 (Hz=1, b1=1), `26 0a 29` @6919 (Hx=10, b1=10). P.
- Query 1 m outside the frame (x ∈ [−205,−201], frame min −200.01): PC returns 3 keys, ours 0 (same CUT cause plus the §2.2 clamp/−1 widening). P.

Differences, each P unless marked:
1. CUT 0x26–0x28 lower bound: PC is one cell looser (§2.4). Ours misses keys → not a superset of PC. (bug for parity)
2. Diagonal splits 0x13–0x1C: PC prunes with the table in §2.4; ours visits both children unpruned (mopp.rs:978–985; doc "Open"). Source of most over-inclusion (this MOPP has 1,744 diagonal splits: 13×31, 14×5, 15×1345, 16×303, 17×26, 18×6, 19×17, 1A×4, 1B×6, 1C×1 — `ophist.txt`).
3. Quantization: PC quantizes the QUERY once (f32 math, RNE `fistp`, `−1` on min / `+1` on max, then `>>k` arithmetic and `+1` on H) and compares integers. Ours dequantizes PLANES to world floats and compares with `eps`. Ours uses `1/w` (`extract_mopp_with_info`, mopp.rs:338–339); PC multiplies by `w` directly.
4. Split tests: PC inline iff `L < b1`, offset iff `H > b2` (strict, on the ±1-widened ints); ours `qmin <= Lmax+eps`, `qmax >= Rmin-eps`. 0x20–0x22: PC inline iff `H <= v` or `L <= v`, offset iff `H > v`; ours uses planes `v+1`/`v` with eps.
5. CUT24 0x29–0x2B: PC compares the global full-resolution ints `vm.qmin/qmax` (±1 widened); ours compares world floats with eps (looser: eps 1e-4 m ≈ 4.2 ints here).
6. Clamp (§2.2): absent in ours. With the clamp, an out-of-frame or inverted query can still return keys in PC.
7. 0x0C: PC handles it in this VM (jump to `data + BE16·512`, sets chunkId, which is inherited by recursions only). Ours: `query_aabb` has no 0x0C (falls to `_ => break`); `decode` handles it only via `decode_chunked`. The doc's "0x0C PS3 only, INVALID on PC" is FALSE for this PC VM.
8. 0x0D: PC skips 5 bytes, and `data[0]==0x0D` turns on `chunkMask` so keys get `| (chunkId<<8)`. Ours treats 0x0D as invalid (decode error; query stops the branch). Doc lists 0x0D as INVALID — false for this VM.
9. REANCHOR 0x01–0x04: ours `origin += b<<shift; shift -= n` (saturating) is the same geometry as PC's `off=(off+b)<<n; shift+=n` (I, algebra; all-space and 2,612 identical results support it). PC has no saturation: `16-shift < 0` would shift by `(16-shift)&31`.
10. Invalid opcode: PC re-dispatches the same byte after the error report; ours ends the branch.
11. Properties 0x60–0x6B: no effect on keys in both. 
12. Terminal key: PC `(mask & chunk<<8) | (prim + v)`; ours `kb + v`. Equal when `data[0] != 0x0D` (the captured MOPP).
13. Order: same DFS (inline/"lo" child first); ours achieves it with push-right/continue-left. Equal whenever the sets agree.
14. Entry gate `FUN_00A3EA60(4)` (Havok keycode) — ours has none (not needed; I: passes in the shipped game since collision works).

What a faithful port needs: replace the float-box walk with the integer machine of §2.2–2.4 (state H/L/off/prim/shift, VM globals qmin/qmax, chunkId, chunkMask) — it is smaller than ours and needs no eps. `pcvm.py` here is a working reference implementation of it.

## 4. Worked run (P, `run_out.txt`, `outside.txt`) — captured terrain MOPP, query in shape-local frame
- `[10,−120,10]–[12,300,12]` → PC `[1065, 977, 1001, 1118, 1059, 1078, 1066, 1067, 1069, 1073, 1071]` (ours identical).
- `[0,−200,0]–[0.5,400,0.5]` → PC `[723, 892, 983, 989, 966, 1060]`; ours 16 keys `[734,735,722,723,954,955,959,960,982,892,983,989,966,1060,1061,1065]`.
- `[100,−120,−150]–[101,300,−149]` → PC `[33554463, 33554510, 33554544]` (`0x0200001F…`); ours 6.
- `[0,−120,0]–[5,300,5]` → PC 9 `[723,892,983,989,966,1060,1061,1065,977]`; ours 17.
- inverted `[5,…,0]–[0,…,5]` → PC `[1061,1065,977]`; ours 8.

## Not determined
- The emulator was NOT run against the binary bytes (no x86 emulator available: `import unicorn` fails, `unicorn_check.txt`). Its correctness rests on the handler-by-handler transcription above plus agreement with an independent implementation (ours) on 2,613 queries and traced, explained divergences on the rest.
- Who writes `DAT_00E74809` (only its value at capture time, 0, is known).
- Which thread (x87 PC=24 or PC=53) runs the query (§2.6); results were insensitive in 20,000 trials.
- Whether any PC-shipped MOPP starts with 0x0D or contains 0x0C (the captured one does not: FindAll histogram has neither).
- Semantics of properties 1–3 (written to scratch, unread here).
