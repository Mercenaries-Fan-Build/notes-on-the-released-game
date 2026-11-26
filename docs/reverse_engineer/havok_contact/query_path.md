---
status: current
evidence: proven
---

# From two overlapping bodies to the stream of (convex, triangle) pairs (pc-v10)

Read of 2026-11-25. Kept beside this page: `n1/mopp/mopp_vm.md` with the emulator `n1/mopp/pcvm.py`, and
`n1/wpmesh/wpmesh16.md`. The other `n1/` files named below (listings, capture reads, function extracts) were working
files and are not kept.

Scope: opening Speed Boat body `0x1EBB8000` (list of 12 convex hulls + 1 MOPP) against the terrain cell body
`0x1EC16A00` (list → 1 MOPP → `WpMeshShape16`). What decides which child pairs are tested each step and in what order.

Sources (all read this run): exe `game-files/canonical/dumps/mercs2_unpacked.exe` sha256 `8c179a99…bc7ba`
(`n1/exe_sha.txt`); Ghidra export `output/_ghidra_exports/pc-v10.functions.jsonl` (extracts in `n1/fns/`); objdump
listings in `n1/dis_*.txt`; capture `…/20261103_new-game-first-mission-start.dmp` via `mercs2_probe dump-read`
(`n1/cap_*.txt`). Two sub-reads are written up in full beside this file and summarised here:
`n1/mopp/mopp_vm.md` (MOPP query VM + comparison with `mopp.rs`) and `n1/wpmesh/wpmesh16.md` (WpMeshShape16).

Grades: **P** PROVEN this run (address / command given). **I** INFERRED. **S** SPECULATIVE. **HK** = recalled Havok
5.5 naming, never a fact about this binary. Names like "hkpAgent3ProcessInput" are HK labels on layouts that are P.

---

## 0. Corrections to the starting map (`havok_contact/README.md`)

| README claim | Finding | Grade |
|---|---|---|
| `FUN_008C61A0` is "the agent-nn machine" | It is the **agent2** bv-tree agent's process (timer "LtBvTree"/"StQueryTree"/"StNarrowPhase"; children made through the agent2 table +0x9A0, called via child vtable +0x18). Not on this pair's path. | P |
| (nn machine not located) | The per-entry nn driver is **`FUN_00909CA0`** (SecuROM split at 0x909CA6 → resumes 0x909CAC, `splices.tsv` line 2028, "moved"), called by the MT narrowphase job `FUN_008FDA80`. `FUN_009094C0` has no callers; `FUN_0090A200` is the ST path (`FUN_008F3F10`). | P |
| welding code not located | `FUN_0090AED0` (2029 B, timer "TtConflicts") is called from the 1-n child machine tail at 0x90CED3 when welding is enabled; calls agent3 slots +0x0C/+0x10/+0x14 and `FUN_00941F10`. Role = potential-contact conflict/welding pass. | P (call, label) / I (role) |
| MOPP query VM not located | slot 11 `FUN_00A12380` / slot 10 `FUN_00A12800` → `FUN_00A49960` → recursive `FUN_00A48E10` (see §4.3). | P |
| capture: MOPP code at shape+0x08 | shape+0x08 is userData; `hkpMoppCode` is at +0x10 (0x291DA620), data at +0x14 (0x291DA650). | P (`mopp/mopp_vm.md`) |

---

## 1. Broadphase pair → agent entry (creation, lifetime, AABBs)

### 1.1 Creation chain — P
1. Broadphase "new overlap" listener `FUN_008F70A0` (MT sim, this = listener, `[this+4]` = sim): for pair
   {handleA, handleB} → collidable = handle + (int8)handle[+5]; entity = collidable + (int8)coll[+0x10].
   - If `sim[+0x68] != 0` **and** neither motion type byte (entity+0xD8) == 7 (FIXED) **and** islands differ
     (entity+0xB8): pair is appended to the deferred list at sim+0x6C and nothing else happens now.
   - Else: `v = disp[0x1BB0 + qualA*10 + qualB]` (qual = u16 collidable+0x1A); if v == 0 no agent; else
     `input[+0x10] = disp[0x1C30 + v*0x40]` (quality info[v−1]+0x10, "continuous" flag) and
     **`FUN_008EB300(collA, collB, input)`**. Terrain is FIXED → immediate path for the boat pair.
   - `FUN_008FAC00` is the same without the deferral (other listener).
2. `FUN_008EB300` (SecuROM split at 0x8EB31B; splice-emulate shows VM reads `[esi+0xD8]` = A's motion type, then
   resumes 0x8EB321/0x8EB347): island merge if both non-fixed and islands differ (0x6B1200); picks the island
   whose agent track to use (0x8EB347–0x8EB368: island+0x20 u16 == 0xFFFF test); then
   `FUN_00909000(collA, collB, input, &agentType, &flip)`; if flip: swap A/B (0x8EB385–0x8EB390); contact-mgr factory
   `disp[+0xC + 4*(8*respA + respB)]` (resp = int8 entity+0x80) → `factory->vtbl[+0xC](A, B, input)`; then
   **`FUN_009090C0(island+0x58, collA, collB, agentType, input, mgr)`**.
3. `FUN_00909000` (no Ghidra function; `n1/dis_909000.txt`):
   ```
   tA = collA.shape.type; tB = collB.shape.type
   tbl = (input[+0x10] != 0) ? disp+0x12B0 : disp+0x0EB0            ; 909022
   t = tbl[tA*32 + tB]
   flip = (agent3[t].u32[+0x40] == 2)                                 ; 909044 (agent3 rec = disp+0x16B0+t*0x50)
   if t == 1: flip = (agent2[ disp[0x1A0 + tA*32 + tB] ].isFlipped byte (disp+0x9B0+idx*0x14) != 0)   ; 90904F
   *outFlip = flip
   *outType = flip ? tbl[tB*32 + tA] : t
   ```
   Boat (type 10) vs terrain (type 10): t = 9, agent3[9]+0x40 = 0 (`cap_agent3_recs.txt`, rec at 0x2021F2B0) → no flip.
4. `FUN_009090C0` (agent entry, 0x80 bytes from 0x200-byte sectors via `FUN_00908EE0`):
   ```
   e[+0x08] = mgr; e[+0x10] = collA; e[+0x14] = collB
   e.u16[+4] = collA.collisionEntries.size; e.u16[+6] = collB.collisionEntries.size
   push {e, collB} onto collA+0x4C; push {e, collA} onto collB+0x4C         ; hkArray<{entry, partner}>
   e[+0x0C] = disp[0x1BB0 + qualA*10 + qualB]       (byte; quality index v)
   input[+0x60] = disp + 0x1C20 + v*0x40            (quality info ptr)
   e[+1] = agentType
   if agent3[t].slot10 (disp+0x16D8+t*0x50) == 0: e[0] = 2; data = e+0x20
   else: e[0] = 4; e.f32[+0x18] = *(f32*)0xB12A50 (= −1.0); e[+0x20..+0x2F] = 0; data = e+0x30
   agent3[t].create (slot0, disp+0x16B0)(&{collA, collB, input, mgr}, e, data)
   e[+3] = 0x80
   ```
   Live entry 0x1EB17E00 (`cap_entry.txt`): `02 09 b1 80`, +4 = 0/0, +8 = mgr 0x1EB7EF80, +0xC = 1, +0x10 = boat
   collidable 0x1EBB8010, +0x14 = terrain collidable 0x1EC16A10, +0x20 = agent data. P. (byte +2 = 0xB1 is not
   initialised by `FUN_009090C0`; meaning NOT DETERMINED.)
5. agent3 #9 create = `FUN_00925540`: data[0..2] = {0, 0, 0x80000000} (an empty hkArray of sector pointers,
   "not owned" flag) then `FUN_0090AC80(data)`; returns data+0x10. P.

### 1.2 Lifetime — P
- Destroyed when the broadphase reports the overlap ended: `FUN_008F7170` (same MT deferral test, list sim+0xA8)
  → `FUN_00908DA0(collA, collB)` (find entry) → `FUN_008EB3E0` → `FUN_00909A20(island+0x58, entry, …)` + mgr
  vtbl +0x24. Also on entity removal: `FUN_008EB480` → `FUN_008EB3E0`.
- Child entries inside an agent (see §3.5, §4.4) are destroyed when their key pair is no longer produced by the
  per-step sweep/query (merge "pair > entry" branch → agent3 slot1 destroy, disp+0x16B4).

### 1.3 Per-step drive of one entry — P
`FUN_008FDA80` (job "TtNarrowPhase") walks the island's 0x80-byte entries; per entry:
`input+0x60 = disp+0x1C20+e.q*0x40`; `input+0x10 = info[+0x10]`; output reset; `FUN_00909CA0(e, input, output, mgr)`;
if output got points → `mgr->vtbl[+0x18](collA, collB, input, output)`.
`FUN_00909CA0` (`dis_909cac.txt`), command byte e[0]:
- **2** (0x90A06F, our entry): build input3 on stack:
  ```
  in3.bodyA = e.collA; in3.bodyB = e.collB; in3.input = input; in3.mgr = e.mgr
  mA = bodyA.motion (hkMotionState*), mB = bodyB.motion
  fA = input.deltaTime(+0x58) * mA[+0x5C]          ; 90A0E8.. (motionState com1.w)
  fB = input.deltaTime * mB[+0x5C]
  dA[k] = mA[+0x40+4k] - mA[+0x50+4k]  (k=0..3)    ; com0 - com1
  dB[k] = mB[+0x50+4k] - mB[+0x40+4k]
  lin[k] = f32( f32(dA[k]*fA) + dB[k]*fB )          ; k = 0..3, stored to in3+0x60
  lin.w = fA*mA[+0x9C]*mA[+0xA0] + fB*mB[+0x9C]*mB[+0xA0]   ; overwrites lane 3 (deltaAngle.w · objectRadius)
  in3.aTb = FUN_008933D0(mA, mB)  -> in3+0x10 (4×vec4)
  in3[+0x54] = 0
  agent3[e[1]].process (disp+0x16DC)(&in3, e, e+0x20, NULL, output)
  ```
- **4/5** (TIM entries, not ours at top level): same input3, plus separating-plane early-out (same code as §4.4).
- **6**: `e[+0x20]->vtbl[+0x18](collA, collB, input, output)` (agent2 wrapped).

### 1.4 The AABB each body presents — P (numbers) / I (writer)
- Broadphase space: `input+0x20` offsetLow, `+0x30` offsetHigh, `+0x40` scale (captured: (4096, 1000, 4096, 0),
  (4096, 1000, 4096, 0), (262128, 1073676.375, 262128, 0)); clamp max 2147352576.0 (0xCDF690..9C), min 0.0 (0xB132F0..FC).
- **Boat**: collidable boundingVolumeData is valid (min.x 0x24EF5C40 ≤ max.x 0x25178E00) and carries 13 cached
  child `hkAabbUint32` (0x1EBBCA00, `cap_terr_coll.txt`), indexed by child key, sortIndex byte (+0x1F) = rank of
  min.x. Checked numerically (`n1/aabbchk.py` → `aabbchk.txt`): every cached child AABB equals the child's
  `aabbCenter ± |R|·aabbHalfExtents` at the captured body transform, widened by **0.1 on every side** (y lane exact
  to 1e-6; x/z within 5e-4). halfExtents exclude the 0.05 convex radius (child 0 vertex half-range = 0.42260 = halfExt.y),
  and the convex getAabb adds the radius itself (§4.2a), so widening = radius 0.05 + a tolerance argument of
  **0.05 = 0.5·tolerance** (P for the sum and for getAabb; the 0.05 argument is P only numerically, since the
  writer's call was not found). Expansion bytes (+0x0C..0x0F, +0x1C..0x1E) are nonzero
  (swept motion) but unused when the quality flag is 0 (§3.2). P.
  Writer: `FUN_008C8D40` (6769 B) writes exactly this record format (sortIndex, expansion bytes with shift, quantise
  through the same input+0x20/+0x30/+0x40); no static caller or pointer to it exists in the image
  (`findptr1.txt`, grep of `hk_text.asm`), so the call path is NOT DETERMINED. I.
- **Terrain**: boundingVolumeData invalid (min.x = 1 > max.x = 0, `cap_terr_coll2.txt`) → its child AABBs are
  recomputed each step inside the collection agent with the **full** tolerance (§3.2). P.
- No AABB on this pair's path carries a swept/velocity expansion, because quality info[0]+0x10 = 0 (`input+0x10`,
  written by the job); every branch keyed on it is listed as "untaken" below. P. **But** the linear and angular
  motion still matter: `linearTimInfo` (§1.3) drives the separating-plane cull of every triangle child (§4.4,
  `dist = sep.w − (sep·lin + lin.w)`), so the port must compute it exactly.

### 1.5 hkpProcessCollisionInput (world master 0x20017E80 = world+0x6C; the job uses a copy) — P
| Off | Use (evidence) | Captured |
|---|---|---|
| +0x00 | dispatcher | 0x2021D930 |
| +0x04 | tolerance (926AF9, 90CC78, 907FD2) | 0.1 |
| +0x08 | shape-collection filter = filter+0x0C (vtbl 0xB6CB5C) (90D18E, 90C4xx) | 0x1FFFF70C |
| +0x0C | NOT DETERMINED (equals world+0x78) | 0x2001FFF0 |
| +0x10 | quality "continuous" flag copied per entry (8FDA80) | 0 |
| +0x14..+0x1C | NOT DETERMINED | 0x297C7244, 0x1693884C, −1 |
| +0x20/+0x30/+0x40 | aabb32 offsetLow / offsetHigh / scale | above |
| +0x50 | stepInfo {start, end, dt, invDt} | 56.93137, 56.94798, 0.01661, 60.1938 |
| +0x60 | quality info ptr (= disp+0x1C60 = info[0]) | 0x2021F590 |
| +0x64 | NOT DETERMINED | 0x20007990 |

Process input (stack, built in §1.3): +0 bodyA, +4 bodyB, +8 input, +0xC mgr, +0x10 aTb (64 B), +0x50 dist (TIM),
+0x54 = 0, +0x60 linearTimInfo. FUN_00927710/FUN_009089A0 add `in3[+0x54]` to the agent-data pointer (always 0 here).

---

## 2. Order of everything below, in one view — P
```
boat×terrain entry (cmd 2, agent3 #9 FUN_00927710)
  └ child pairs (keyA, 0) for every boat child whose AABB overlaps terrain child 0, keyA ascending
     ├ filtered pairs → NULL child entries (kept, cmd 0)
     └ (11,0): convex hull 11 vs terrain MOPP → agent3 #3 FUN_009089A0 (cmd 2)
          └ MOPP keys (triangles) overlapping hull AABB, sorted ascending unsigned
             └ each key passing the filter → agent3 #10 FUN_00901510 (cmd 4 = TIM entry)   [N2]
```
Captured cache (`cap_sector0.txt`, `cap_bv_sector0.txt`): sector 0x1EB17C00 holds NULL entries (0,0)…(10,0), the
#3 entry for (11,0), NULL (12,0), END (−1,−1). The #3 agent's own sector 0x1EB17400 holds only END: no triangle
children at capture time. Running the PC MOPP VM emulation (`mopp/pcvm.py`) on the hull-11 box AABB in terrain space
(`n1/q11.py` → `q11.txt`) returns 0 keys even with 10 m padding: consistent. P.

---

## 3. List-vs-list: agent3 #9 process `FUN_00927710` (args: in3, entry, data, sepNormal(NULL), output)

### 3.1 Branch selection — P
`bvA = (disp.altType[typeA] >> 9) & 1` (bit 9 = BV_TREE; masks at disp+0x110, `cap_disp_alt.txt`: list 0x500,
MOPP 0xA00, triangle-collection 0x400100). Both bodies are lists → neither is a bv-tree → **"enumerate both"
branch** (decomp lines 562–579; asm 0x928600–0x928740). The tree-query branch (≥1 bv-tree, `FUN_00907EF0` + hit-list
conversion "StConvertHitlist", "StSortHitList" `FUN_00928B00`) is untaken for this pair.

### 3.2 Child AABB lists `FUN_00926900(body, container, out)`, EAX = input — P (`dis_926900.txt`)
Called for A, then (if nA ≠ 0) for B; each buffer is `n*0x20 + 0x90` bytes from the TLS stack.
Out record (0x20): `u32 min[3], u32 key, u32 max[3], u32 w`.
```
cont = (qualityInfo[+0x10] != 0)
if body.parent == 0 && &body.bvd && bvd.childShapeAabbs != 0 && bvd.min.x <=u bvd.max.x:     ; 92690F..926951
    n = 0; k = container.getFirstKey()                         ; vtbl+8
    while k != -1:
        idx = (n < 256) ? src.sortIndex(+0x1F) : n             ; 926973 (jge)
        dst = out + idx*0x20
        if cont: dst.min = src.min - (expMin << shift); dst.max = src.max + (expMax << shift)   ; untaken
        else:    copy 32 bytes (FUN_008F4550)
        n++; dst.key = k; src += 0x20; k = container.getNextKey(k)   ; vtbl+0xC
    if n >= 256 || cont: goto SORT                             ; 926A22
    return n                                                   ; boat: 13, already sorted by min.x
else:
    k = getFirstKey()
    while k != -1:
        if container.isChildEnabled(k):                        ; vtbl+0x18 (list: enabledChildren bit, keys ≥256 → 1)
            s = container.getChildShape(k, buf)               ; vtbl+0x14
            s.getAabb(body.motion /*hkTransform*/, input.tolerance /*FULL*/, &a)   ; 926AF9 fld [edi+4]
            if cont: swept expansion (926B23..92725B)          ; untaken
            (a running union min/max is updated, 92725C..92735B; not consumed on this path — I)
            for c in 0..3: m = f32(a.min[c] + offLow[c]); m = f32(scale[c]*m)    ; 92735B..9273BA
                           m = (2147352576 <= m) ? 2147352576 : m              ; test ah,0x41 / je
                           m = (0.0 > m or m == 0 or NaN) ? 0.0 : m            ; test ah,5 / jnp
                           out.min[c] = fistp(f32(m))   (round-to-nearest under the thread's RC)
            same for max with offHigh: M = f32(offHigh[c] + a.max[c]); f32(M*scale[c]); clamps; fistp
            out[n].key = k (overwrites min.w); n++
        k = getNextKey(k)
SORT: if n > 1: FUN_00928B00(out, 0, n-1)                       ; SecuROM split 0x928B2E (runs in .text after)
return n
```
Terrain: 1 child → no sort. The sort comparator of `FUN_00928B00` was not read (not needed for n ≤ 1): NOT DETERMINED.
After both lists, 4 sentinel records with `min.x = 0xFFFFFFFF` are appended to each (decomp 605–622).

### 3.3 One-axis sweep `FUN_009427D0(L1, n1, L2, n2, outPairs, 0xFFF, &overflow)` — P (`dis_9427d0.txt`)
Called with L1 = A's list, L2 = B's list (0x928811; the other order only when the queried side is B, tree branch).
Lists sorted by min.x. Output pairs `{u32 keyL1, u32 keyL2}`.
```
a = L1, b = L2
loop:
  if a.min.x >u b.min.x:                                    ; 9427F5 jbe → else-branch
      if a.min.x <u b.max.x:                                ; 942804 jae skips
          for c = a, a+1, a+2, a+3, then next group of 4 while (c4.min.x <u b.max.x):   ; 942997 jb
              ov(c) = ((b.max.y - c.min.y) | (b.max.z - c.min.z) | (c.max.y - b.min.y) | (c.max.z - b.min.z)) & 0x80000000
              emit (c.key, b.key) if ov(c) == 0 and (c is first of group OR c.min.x <=u b.max.x)   ; 94290A ja / 942935 / 942961
          (if all four ov != 0, nothing; out of room → overflow++)
      b++, n2--
  else:  symmetric with roles swapped, emitting (a.key, c.key); a++, n1--
until the decremented count <= 0
return count of pairs
```
Note the x test is strict for the first element of each group of four (`<u`) and non-strict (`<=u`) for the
other three (P, 942804/942997 vs 94290A/942935/942961). y/z overlap is inclusive (signed difference ≥ 0).

### 3.4 Pair sort — P
`FUN_00928CE0(pairs, 0, n-1)`: in-place quicksort, ascending **lexicographic (word0, word1), unsigned**
(928D0A jb / 928D10 jae). Then `pairs[n] = (−1, −1)`. With unique pairs the result is the total order (keyA, keyB).

### 3.5 Merge with the child-entry cache and dispatch `FUN_0090CF30(data, data+in3[0x54], in3, contA, contB, pairs, output)` — P (`dis_90cf30.txt`)
Agent data = hkArray of sector pointers; a sector = {u32 usedBytes, pad to 0x10, entries…}, new sectors filled
up to usedBytes + nextSize < 0x1A1. Child entry (hkpAgent1nMachine HK):
`+0 cmd u8, +1 agentType u8, +2 numContactPoints u8, +3 size u8, +4 keyA, +8 keyB`, then cmd 2/3 data at +0x10;
cmd 4/5: +0x0C time f32, +0x10 sepNormal vec4, data at +0x20; cmd 0 = NULL (size 0x10); cmd 1 = END.
Child input3 = 0x70-byte copy of in3 with bodyA → `{shape=contA.getChildShape(keyA), keyA, A.motion, parent=A}`,
bodyB → `{contB.getChildShape(keyB), keyB, B.motion, parent=B}`; getChildShape re-done only when the key changes.
```
for each pair p = (kA=edi=word0, kB=esi=word1) in order, against old entry e (stream order):
  if (kB == e.keyB && kA == e.keyA): copy e to new sector, process(e)           ; 90D09E..90D107
  elif kB >u e.keyB || (kB == e.keyB && kA >u e.keyA):                          ; 90D10F ja / 90D115 jbe
      agent3[e.type].destroy (slot1, +0x16B4)(e, data, mgr, output.?); old e dropped (pair re-tested next)
  else:  (new pair)
      ok = filter(+0x0C).vtbl[0](&r, input, A, B, contA, contB, kA, kB)        ; 90D1A8 → game FUN_006AF0D0
      if !ok: new e = {0,0,0,0x10, kA, kB}                                      ; NULL entry, kept
      else:
          t = tbl[typeA_child*32 + typeB_child]  (tbl = input+0x10 ? 0x12B0 : 0xEB0); e.type = t; e[2] = 0
          flip = agent3[t].+0x40 == 2 (then FUN_0090C140 builds a flipped input3)
          if agent3[t].slot10 == 0: e.cmd = 2 + flip; data = e+0x10
          else: e.cmd = 4 + flip; e.time = −1.0 (0xB12A50); e.sep = 0; data = e+0x20
          e.size = agent3[t].create(input3', e, data) - e
      process(new e)
process(e): cmd 2 → e.size = agent3[t].process(&childIn3, e, e+0x10, NULL, output) − e
            cmd 3 → flipped input; after the call every new contact point is mirrored (pos += n*dist, n = −n) (90D3xx)
            cmd 4/5 → TIM test as in §4.4 then process with sepNormal = e+0x10
            cmd 6 → e[+0x10]->vtbl[+0x18](childA, childB, input, output)
```
Note (P): the sort (§3.4) orders by keyA first, the merge comparator orders by **keyB first**. They agree only when
B contributes one key (our case: terrain list has one child, key 0 → harmless for the boat). With several B keys,
whenever the pair set changes between steps the merge can take the "destroy" branch for entries that still
overlap and re-create them (losing their manifold cache); a port must copy both comparators literally. (I: consequence.)

### 3.6 Collision filter for child pairs — P (`dis_filter.txt`)
`FUN_006AF0D0` (collection×collection, 8 args, `ret 0x20`): `iA = contA.getCollisionFilterInfo(kA)`,
`iB = contB.getCollisionFilterInfo(kB)` (vtbl +0x10), result = `FUN_006AF040(this−0xC, a = iB, b = iA)`:
```
FUN_006AF040(filter, a (ECX), b):
  if ((b ^ a) & 0xFFFF0000) == 0 && (b & 0xFFFF0000) != 0: return false
  sb = (b >> 5) & 31; sa = (a >> 5) & 31
  if sb != 0 && sa != 0 && sb != sa: return false
  return (filter.u32[0x34 + 4*(b & 31)] & (1 << (a & 31))) != 0
```
Boat child infos: 0x00B7001D (layer 29) for children 0–10 and 12, 0x00B7001C (layer 28) for child 11; terrain list
child 0 info 0x00050001 (layer 1). Only (11, 0) passes; that is exactly the captured cache (§2). P.

---

## 4. Convex vs MOPP: agent3 #3 process `FUN_009089A0`

### 4.1 Process — P
```
bTa = inverse(in3.aTb)                                ; FUN_008931E0(in3+0x10) -> local
n = FUN_00907EF0(bodyA, bodyB, &bTa, &in3.linTim(+0x60), input, cachedAabb = NULL, keys (0x4010 B TLS), 0x1000)
cont = FUN_00907EC0(bodyB) = bodyB.shape.getContainer()   ; MOPP vtbl+0x14 = FUN_00A0CC90 → child(+0x34).getContainer()
FUN_0090C290(data, data+in3[0x54], in3, cont, (n < 0) ? NULL : keys, output)
return data + 0x10
```
agent3 #3 slot10 = 0 → the (hull, MOPP) child entry is cmd 2 (no plane early-out at this level).

### 4.2 Query AABB `FUN_00907EF0` (split 0x907EF6 → resumes 0x907EFC) — P (`dis_907ef0.txt`, `dis_90890f.txt`)
```
linB = R_B^T · linTim.xyz  (x = (m0·lx + m1·ly) + m2·lz, columns of bodyB.motion), w = 0     ; 907EFC..907F8A
if qualityInfo[+0x10] == 0:                                    ; 907F27 / je 908460  ← TAKEN
    tol = f32(input.tolerance * 0.5)                           ; 908460..908476 (double 0.5 @0xBEA940)
    bodyA.shape.getAabb(&bTa, tol, &aabb)                      ; vtbl+0x1C (convex in MOPP-local space)
else: swept/radius expansion 907F94..90845B                    ; untaken
(cachedAabb == NULL → skip the reuse test 9084E1..)            ; untaken
n = bodyB.shape.vtbl[+0x28](&aabb, keys, max)                  ; MOPP slot 10 FUN_00A12800
if n >= max: n = input.filter.vtbl[+8](input, A, B, B.shape, &aabb, keys, max); n = min(n, max-1)   ; overflow only
if n > 1: FUN_008BEC50(keys, 0, n-1)                           ; unsigned ascending quicksort, no dedupe
keys[n] = 0xFFFFFFFF; return n
```
So the key order seen downstream is **ascending unsigned key order**, independent of the VM's traversal order.
`DAT_00E74809` gates the same sort in the agent2 path only.

**4.2a Convex getAabb** (`hkpConvexVerticesShape` vtbl 0xB578FC slot 7 = `0x8BB7C0`, `dis_8bb7c0.txt`,
`dis_8bbe50.txt`) — P:
```
t2 = f32(this.radius(+0x10) + tol)
FUN_008BBE50(T, &aabbHalfExtents(+0x20), &aabbCenter(+0x30), t2, out):
  for i in 0..2: c_i[k] = f32(T.col_i[k] * he[i])  (4 lanes);  c_i = f32(|c_i|)
  c2[k] = f32(c2[k] + t2);  e[k] = f32( f32(c1[k] + c0[k]) + c2[k] )      ; 8BBFC8..8BC051
  ctr.x = f32( ((T0*cx + T4*cy) + T8*cz) + T.t.x ), likewise y (T1,T5,T9), z (T2,T6,T10)   ; 8BC098..
  out.min = ctr − e, out.max = ctr + e   (tail after 0x8BC0EF not printed here — I)
```
So the MOPP query box (with tol = f32(0.1·0.5) = 0.05) is the hull's rotated box in MOPP-local space widened by
**0.05 + 0.05 = 0.1**; `n1/q11.py` with exactly ±0.1 returns 0 keys, matching the empty child sector. P.

### 4.3 MOPP AABB query VM — P (full write-up `n1/mopp/mopp_vm.md`; emulator `n1/mopp/pcvm.py`)
- Slot 10 `FUN_00A12800` clamps the query to `codeInfoCopy` (shape+0x20): `ext = f32(2^24 / cic.w)`;
  `min = (cic <= q.min) ? q.min : cic`, `max = (q.max <= cic+ext) ? q.max : cic+ext`; output array = caller buffer
  with capacity|0x80000000; calls `FUN_00A49960(vm, &clamped, &array)`; returns the array size.
- `FUN_00A49960`: `qmin.k = fistp(f32(f32(min.k − code.off.k) * code.w)) − 1`, `qmax.k = … + 1` (code.info at
  hkpMoppCode+0x10); root `L = qmin >> 16`, `H = (qmax >> 16) + 1`; chunk mask = (data[0] == 0x0D) ? −1 : 0.
- `FUN_00A48E10`: recursive, signed int32 compares, DFS pre-order, inline/"lo" child first; opcodes 0x01–0x04
  rescale, 0x05–0x07 jumps, 0x09–0x0B primitive offset, 0x0C/0x0D chunk, 0x10–0x12/0x20–0x25 axis splits,
  0x13–0x1C diagonal splits, 0x26–0x2B cuts, 0x30–0x53 terminals `key = (mask & chunk<<8) | (prim + v)` with **no
  re-indexing**; 0x60–0x6B properties. One-time licence gate `FUN_00A3EA60(4)` @0xA48E1C (fails → no keys).
- No SecuROM splices in 0xA1xxxx–0xA4xxxx.

### 4.4 Per-key child machine `FUN_0090C290` (Ghidra function starts 0x90C29B; tail split 0x90CCEA → resumes 0x90CCF0) — P (`dis_90c290.txt`)
- Welding hook first: `if output[+0x3080] == 0 && cont.isWeldingEnabled() (vtbl+0x1C)`: output[+0x3080] =
  stack potential-contact buffer; at the end, if potentials were recorded (ptr > base+0x408):
  `FUN_0090AED0(&in3', cont, output)` ("TtConflicts"); output[+0x3080] restored. WpMeshShape16 has welding enabled
  (byte shape+0x14 = 0 → slot 7 `0x41BC30` returns 1).
- Child input3 = 0x70-byte copy of in3; bodyA unchanged (the hull cdBody from §3.5); bodyB replaced by
  `{shape = cont.getChildShape(key, 0x400-byte stack buffer), key, motion = MOPP cdBody.motion, parent = MOPP cdBody}`.
- Merge keys (ascending unsigned, −1 terminated) with old entries (entry key at **+8**, +4 = 0xFFFFFFFF):
  equal → process; `key <u e.key` → new; else → destroy old (slot1 +0x16B4).
- New key: `ok = filter(+0x0C).vtbl[+4](&r, input, bodyA, bodyB(MOPP cdBody), cont, key)` → game `FUN_006AF110`:
  `iB = cont.getCollisionFilterInfo(key)` (WpMesh slot 4 `0x811D30` returns 0); `iA` = walk bodyA's parent chain:
  the first ancestor whose shape type has altType bit 0x100 (collection) or 0x200 (bv-tree) supplies
  `container.getCollisionFilterInfo(child.key)` (for the hull: boat list child 11 → 0x00B7001C); bit 0x100000 →
  root collidable info (+0x1C); bit 0x200000 → accept; no ancestor → root info. Then `FUN_006AF040(a = iB, b = iA)`.
  Triangle info 0 (layer 0) vs hull layer 28: captured `table[28]` (filter+0x34+28·4 = 0x1FFFF7A4) = 0x108124FF,
  bit 0 set → accepted. Collection level (§3.6): `table[28]` bit 1 set (hull 11 vs terrain layer 1 accepted),
  `table[29]` = 0x0AB49301 bit 1 clear (all other boat children rejected) (`n1/cap_filter_table.txt`). P.
  Rejected → NULL entry `{0,0,0,0x10, −1, key}`.
- Accepted: `t = tbl[typeA*32 + 4]`; (7, 4) → agent3 #10 (`disp.txt`); agent3[10].+0x40 = 0 (no flip);
  agent3[10].slot10 = 0x9013E0 ≠ 0 → **cmd 4 (TIM)**: e.time(+0xC) = −1.0, sep(+0x10..+0x1F) = 0, data at +0x20;
  size = agent3[10].create (`0x901380`)(&in3', e, e+0x20) − e.
- Process of a cmd-4 child (0x90CAEB–0x90CCDB), `ti` = the job's input:
  ```
  if e.time == ti.startTime(+0x50)  (fucompp, test ah,0x44/jnp)  -> PLANE
  elif ti.endTime(+0x54) <= e.time  (test ah,0x41/jnp)           -> PLANE
  elif qualityInfo[+0x10] == 0:                                   ; taken when stale
      e.time = ti.endTime
      d = f32(qualityInfo.f32[+0x14] * 0.10000000149)  (double @0xB57F98; info[0]+0x14 = −5e19 → −5e18)
      e.sep = (0, 0, 0, d); in3'.dist(+0x50) = d
      goto CALL
  else: FUN_0090C1A0 (TIM input) + agent3[t].slot10 (sep-normal update), then PLANE     ; untaken
  PLANE: e.time = ti.endTime
      dist = f32( e.sep.w − f32( ((e.sep.y*lin.y) + (e.sep.x*lin.x)) + (e.sep.z*lin.z) + lin.w ) )   ; lin = in3'+0x60
      if !(ti.tolerance > dist) && !NaN:     ; i.e. dist >= tolerance  (fcomp, test ah,0x41 / jp)
          e.sep.w = dist
          if e.numContactPoints(+2) != 0: agent3[t].slot2 (+0x16B8)(e, e+0x20, mgr, output[+4])
          skip (no narrowphase)
      else: CALL
  CALL: e.size = agent3[t].process (FUN_00901510)(&in3', e, e+0x20, &e.sep, output) − e
  ```
  The separating plane written into e.sep by `FUN_00901510` is therefore what culls triangles on later steps (N2).

---

## 5. Shape key → triangle (`WpMeshShape16`, vtbl 0xBD23E0, container vtbl 0xBD2404) — P (`n1/wpmesh/wpmesh16.md`)
- Key = `(subpart << 24) | tri`; getFirstKey (`0x6D5640`, a folded no-op whose pc-v11 counterpart 0x6AEF90 is
  `return 0` — I for pc-v10) returns 0; getNextKey `0x7255B0`: tri+1 < sub.numTriangles (signed) → key+1, else next
  subpart (sp+1 < count) → (sp+1) << 24, else −1. getNumChildShapes `0x725590` = Σ sub.numTriangles.
- Object: +0x18 radius (0.01), +0x1C subpart array (stride 0x30), +0x20 count, +0x28 shared u16×3 vertex pool.
  Subpart: +0 origin vec4, +0x10 scale vec4, +0x20 triangle records {u16 i0, i1, i2, w}, +0x24 numTriangles,
  +0x28/+0x2C extremal-vertex list used by getAabb.
- getChildShape `0x725600` (thiscall key, buffer; `ret 8`): sp = key >> 24 (unchecked), tri = key & 0xFFFFFF (if
  tri >= numTriangles falls back to triangle 0 of the first non-empty subpart); vertex = `f32(origin + f32(scale *
  (float)(u16)q))` per lane (SSE, unsigned convert); A, B, C = i0, i1, i2 (no alternate flip); builds an
  hkpTriangleShape in the buffer: vtbl 0xB57B34, type 4, radius = shape radius, weldingInfo 0, weldingType 6,
  extrusion (0, −w, 0, 0) with isExtruded = (e·e > 0) — **every captured terrain triangle has w = 10** (4308/4308).
- getCollisionFilterInfo `0x811D30` returns 0; no per-triangle material.
- getAabb `0x725BA0` adds only `tol` (not radius, not extrusion).
- Differences from our `havok.rs`: drops the +6 word (extrusion), uses subpart 0's frame for all subparts, finds the
  pool by scan instead of shape+0x28; dequantisation formula otherwise bit-identical on 4 checked keys.

---

## 6. Our `mopp.rs` vs the PC VM — P (`n1/mopp/mopp_vm.md`, Rust harness `n1/mopp/rustq/`, 3,504 queries on the captured terrain MOPP)
`query_aabb` is a real query (float world-box walk, eps 1e-4). Same DFS order whenever the sets agree; all-space
gives the identical 4,308-key sequence. Same sequence on 2,613 queries, strict superset on 835, **misses PC keys on 56**.
Differences: (1) cut opcodes 0x26–0x28 lower bound (PC keeps `H >= b1`, ours prunes) — cause of all misses;
(2) no pruning on diagonal splits 0x13–0x1C; (3) float compares vs PC's ±1-widened integers, `1/w` vs `*w`;
(4) no clamp to codeInfoCopy (a query ~1 m outside the frame: PC 3 keys, ours 0); (5) 0x0C/0x0D unsupported (doc
calls them invalid on PC — false); (6) key formula lacks the chunk term (same when data[0] ≠ 0x0D); (7) invalid
opcode ends the branch (PC re-dispatches). Because the agent sorts keys (§4.2), only the result **set** matters for
pair order; the port should still use the integer machine.

---

## 7. Interface handed to N2 (`FUN_00901510`, agent3 #10) — P
Call: `process(in3*, entry*, data = entry+0x20, sepNormal = entry+0x10, output*)`, returns end of its agent data
(size byte = return − entry). Agent3 #10 record (disp.txt, disp+0x16B0+10·0x50): slot0 create `0x901380`
(in3*, entry*, entry+0x20); slot1 destroy `0x901360` (+0x16B4); slot2 `0x901310` (+0x16B8, called when the plane
test culls and numContactPoints ≠ 0); slots 3–5 `0x901250`, `0x901290`, `0x9012D0`; slots 6–9 = 0;
slot10 `0x9013E0` (+0x28, sep-normal update, continuous path only; its non-zero value is what makes the entry cmd 4);
slot11 `0x901510` process (+0x2C).
`in3`:
| Off | Content for (hull, triangle) |
|---|---|
| +0x00 bodyA | cdBody {shape = hkpConvexVerticesShape child 11, key 11, motion = boat motionState (body+0xE0), parent = boat collidable 0x1EBB8010} (built in `FUN_0090CF30`) |
| +0x04 bodyB | cdBody {shape = hkpTriangleShape in a 0x400 stack buffer (§5), key = triangle key, motion = terrain motionState, parent = cdBody{MOPP 0x291DA5E0, key 0, terrain motion, parent = terrain collidable 0x1EC16A10}} |
| +0x08 | hkpProcessCollisionInput (§1.5) |
| +0x0C | contact mgr 0x1EB7EF80 (from the top entry) |
| +0x10 | aTb = `FUN_008933D0(mA, mB)` (below), unchanged through the children |
| +0x50 | dist (−5e18 on a stale reset; else as left) |
| +0x60 | linearTimInfo (§1.3) |
Triangle vertices are in the terrain body's frame (MOPP/list/mesh add no transform).

Transforms (hkTransform = 3 rotation columns at +0/+0x10/+0x20, translation +0x30; `dis_8933d0.txt`,
`dis_8931e0.txt`) — P:
```
FUN_008933D0(out=ECX, A, B):            ; out = A^-1 · B  (maps B-local → A-local)
  for j = 2, 1, 0:  b = B.col_j
     out.col_j.x = (A0*b.x + A1*b.y) + A2*b.z        ; A0..A2 = A.col0
     out.col_j.y = (A5*b.y + A4*b.x) + A6*b.z        ; A.col1
     out.col_j.z = (A8*b.x + A9*b.y) + A10*b.z       ; A.col2
     out.col_j.w = 0
  d = f32(B.t − A.t) (x, y, z)
  out.t.x = (A0*d.x + A1*d.y) + A2*d.z;  out.t.y = (A5*d.y + A4*d.x) + A6*d.z;  out.t.z = (A8*d.x + A9*d.y) + A10*d.z;  out.t.w = 0
  (x87: products and sums in extended precision, one f32 rounding at each store)
FUN_008931E0(out=ECX, in):               ; rigid inverse, used for bTa in §4.1
  out.rot = FUN_00893AD0(in)  (transpose — not read, I)
  n = (−in.t.x, −in.t.y, −in.t.z) (each stored f32)
  out.t.k = ((out.R[4+k]*n.y + out.R[k]*n.x) + out.R[8+k]*n.z)  (R[k] = col0[k], R[4+k] = col1[k], R[8+k] = col2[k]); out.t.w = 0
```
With A = boat motionState and B = terrain motionState (from the top entry), aTb = boat⁻¹ · terrain. Output points go to `output`
(+0 write pointer, +0x3080 potential-contacts/welding pointer); welding resolution `FUN_0090AED0` runs after all
keys of one hull (§4.4). Contact points of a flipped (cmd 3/5) child are mirrored by the caller, not by N2.

---

## 8. NOT DETERMINED (and what was tried)
1. Who calls `FUN_008C8D40` (the cached child-AABB writer): no pointer to it in the image, no `call`; reached via a
   SecuROM path or computed call. Its numeric effect is pinned from the capture (§1.4).
2. x/z residual of 5e-4 in the cached-AABB check (§1.4): pose used (t0/t1, pre/post integrate) not determined.
3. `FUN_00928B00` comparator (AABB-list sort, split at 0x928B2E, body 0x928B34..0x928CDx in .text): not needed for
   n ≤ 1; not read.
4. hkpProcessCollisionInput +0x0C, +0x14..+0x1C, +0x64 meaning.
5. Entry byte +2 = 0xB1 on the top entry (not written by `FUN_009090C0`).
6. x87 precision control of the thread running these paths (MOPP report: RC = nearest on all threads, PC = 53 on 27
   threads, 24 on one); affects fistp of broadphase quantisation and the f32-vs-extended intermediates noted above.
7. `FUN_0090AED0` / `FUN_00941F10` internals (welding/conflicts) — located, not decoded (N2/N3).
8. The tree-query branch of `FUN_00927710`, all continuous/TIM-expansion branches: located, untaken, not decoded.
10. Not read: `FUN_00893AD0` (rotation transpose used by the inverse), the min/max store tail of `FUN_008BBE50`
    after 0x8BC0EF, and the getAabb of the MOPP shape (slot 7 `0xA12520`) used for the terrain child list.
9. pc-v10 getFirstKey `0x6D5640` is `jmp 0x6FCD20C0` (outside the image, not captured); "returns 0" rests on the
   pc-v11 counterpart and on key 0 being the first key in every capture structure.
