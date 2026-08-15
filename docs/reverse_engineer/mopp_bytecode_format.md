# Havok 5.5 MOPP bytecode format — decoded & proven

**Scope:** the on-disk `hkpMoppCode` MOPP (Memory-Optimized Partial Polytope) bytecode — the compressed
spatial BV-tree that accelerates static-world collision ([`terrain_collision_regeneration.md`](terrain_collision_regeneration.md)).
This is the format a **native Rust MOPP compiler** must emit to regenerate collision for new geometry
without the HCT/DCC toolchain (walled — see memory `mopp-bake-oracle-hct-recipe`). **Status:** decoder
PROVEN; split-plane geometry PROVEN (see "Split geometry"); encoder is **spatially conservative** and
geometry-gated (`query_aabb` no-miss on synthetic + real meshes, FindAll + leaf-box gates on 43 real
`vz.wad` MOPPs). Upgrades the long-standing "recognised, not decoded" note in
[`physics_code_map.md`](physics_code_map.md) §2.

## How it was proven
Decompiled the 14 functions in `hctFilterPhysics.dll` that reference the validator string *"Unknown
command – This mopp data has been corrupted…"* (`.\Collide\Mopp\Machine\hkpMoppObbVirtualMachine.cpp`).
Three independent VM variants — `FUN_10081890` (OBB query), `FUN_100a4630` (early-exit OBB), `FUN_100a59d0`
(KDop) — share **one identical instruction encoding**; that switch statement *is* the instruction set. A
decoder mirroring it (geometry tests stripped, FindAll semantics: visit every node, emit every leaf) walks
the real reference MOPP with **901/901 bytes consumed, 0 errors, 76 distinct contiguous shape-keys [0..76]**
(only key 32 absent). Deliverables archived at `Temp\hunt\mopp\{mopp_decode.rs,decode.py,phys_moppvm.txt,progress.md}`.

## `hkpMoppCode` struct + quantization (PROVEN)
```
hkpMoppCode : hkReferencedObject { CodeInfo m_info; hkArray<hkUint8> m_data; hkInt8 m_buildType; }
CodeInfo m_info = one hkVector4 m_offset = [offset.x, offset.y, offset.z, 1/scale]   // lane 3 = RECIPROCAL
```
- **On-disk layout (PC 32-bit, PROVEN):** for the serialized `hkpMoppCode` object, `m_info` sits at
  `obj+16` (offset.xyz @ `+16/+20/+24`, lane 3 @ `+28`); the `m_data` hkArray follows at `obj+32`
  (`ptr @ +32`, `count @ +36`, `capAndFlags @ +40`); `m_buildType` at `+44`.
- **Dequant:** `world_coord = int_coord * scale + offset`, where **`scale = 1.0 / m_info.lane3`**.
  Measured on retail `vz.wad`, lane 3 holds `~1e6`–`2e6` (e.g. `2 280 380` for a ~30 m cell) — far too
  large to be a world-per-unit step; its reciprocal (`~4.4e-7`) is the sane per-integer-unit scale for a
  ~24-bit frame, and matches the VM's `realCoord = intCoord * this[0x10]` multiply (`this[0x10]` = the
  cached `1/lane3`). *(Earlier note said lane 3 = scale directly — corrected: it is `1/scale`.)*
- Integer coords are hierarchical: `int = (operand << shift) + origin[axis]`. The **root operand shift is
  `0x10 - m_info.p3root`** (VM `FUN_100a59d0` uses `0x10 - param_1[3]`; OBB `FUN_10081890` stores it
  directly in `param_1[5]`). `param_1[3]` is a **signed** int, so the root shift can exceed 16 for
  meshes needing >16 integer bits (a ~30 m cell at `scale ~4.4e-7` needs ~26-bit coords → root shift
  ~18). Each REANCHOR (`0x01–0x04`) does `origin[k] += code[+1+k] << shift; shift -= opcode` — refining a
  child cell to finer resolution. **Coordinate math is NOT needed to recover triangle indices** (the
  decoder ignores it) — but it IS needed for a spatial `query_aabb` and for a spatially-conservative
  encoder; see "Split geometry" below.
- ⚠ `output/_scratch/old_mopp.bin` is only the 901-byte `m_data` buffer (no struct), AND it is the **stale
  u32-scrambled** dump (predates fix `b93e00` by ~4 min). Decode it with `--unreverse` (un-reverse each
  aligned 4-byte word). A MOPP extracted by the *current* `havok.rs` (stores raw u8) decodes with NO unreverse.

## Opcode table (byte → operands → action)
Context carried down each branch: an integer origin/AABB frame, a **shape-key base accumulator**, and a
scale exponent. **Operands are big-endian.** All PROVEN from the VM switch unless marked INFERRED.

| Opcode | Len | Action |
|---|---|---|
| `0x00` | 1 | **RETURN** — end this branch |
| `0x01–0x04` | 4 | REANCHOR + rescale child frame (unary, continue). *coord math INFERRED; length PROVEN* |
| `0x05` | var | JUMP8: `pc += code[+1] + 2` |
| `0x06` | var | JUMP16: `pc += code[+1]*256 + code[+2] + 3` |
| `0x07` | var | JUMP24: `pc += BE16(+1)*256 + code[+3] + 4` |
| `0x08` | — | INVALID |
| `0x09` | 2 | key_base **+=** `code[+1]` |
| `0x0a` | 3 | key_base **+=** `BE16(+1)` |
| `0x0b` | 5 | key_base **=** `BE32(+1)` (absolute set) |
| `0x0c–0x0f` | — | INVALID |
| `0x10–0x12` | 4+ | **SPLIT** axis (op−0x10). `code[+1]`=LEFT.max plane, `code[+2]`=RIGHT.min plane. LEFT child @ `pc+4`, RIGHT @ `pc+4+code[+3]`. *plane geometry PROVEN* |
| `0x13–0x1c` | 4+ | **SPLIT** on 26-DOP diagonal planes. LEFT@+4, RIGHT@+4+code[+3]. *diagonal-plane geometry INFERRED* |
| `0x1d–0x1f` | — | INVALID |
| `0x20–0x22` | 3+ | **SPLIT** (compressed 1-value) axis (op−0x20). `v=code[+1]`: LEFT.max=`(v+1)<<shift`, RIGHT.min=`v<<shift`. LEFT @ `pc+3`, RIGHT @ `pc+3+code[+2]`. *PROVEN* |
| `0x23–0x25` | 7+ | **SPLIT** w/ 16-bit child offsets. `code[+1]`=LEFT.max, `code[+2]`=RIGHT.min. LEFT @ `pc+7+BE16(+3)`, RIGHT @ `pc+7+BE16(+5)`. *PROVEN* |
| `0x26–0x28` | 3 | unary **CUT** axis (op−0x26): box.min[axis]=`code[+1]` plane, box.max[axis]=`code[+2]` plane; continue. **(most frequent byte)** *PROVEN* |
| `0x29–0x2b` | 7 | unary **CUT** (BE24 absolute coords): box.min=`BE24(+1)`, box.max=`BE24(+4)`; continue. *PROVEN* |
| `0x2c–0x2f` | — | INVALID |
| `0x30–0x4f` | 1 | **TERMINAL**: emit key = `key_base + (op−0x30)`, RETURN |
| `0x50` | 2 | TERMINAL: emit `key_base + code[+1]`, RETURN |
| `0x51` | 3 | TERMINAL: emit `key_base + BE16(+1)`, RETURN |
| `0x52` | 4 | TERMINAL: emit `key_base + BE24(+1)`, RETURN |
| `0x53` | 5 | TERMINAL: emit `key_base + BE32(+1)`, RETURN |
| `0x54–0x5f` | — | INVALID |
| `0x60–0x63` | 2 | set property[op−0x60] = `code[+1]`, continue (per-terminal metadata) |
| `0x64–0x67` | 3 | set property = `BE16`, continue |
| `0x68–0x6b` | 5 | set property = `BE32`, continue |
| `0x6c–0xff` | — | INVALID |

**Split child layout:** LEFT child immediately follows the header (inline); RIGHT child at the encoded byte
offset. A split visits both; a terminal / `0x00` ends the branch; CUT / REANCHOR / property ops are unary.

## Split geometry — the plane operands + child-visit rule (PROVEN)
Resolves the earlier "coordinate math INFERRED" note. Ground truth = the VM switch in
`Temp\hunt\mopp\phys_moppvm.txt` (`FUN_10081890` OBB, `FUN_100a59d0` KDop — both agree byte-for-byte).

A MOPP internal node is a **Bounding-Interval-Hierarchy (BIH) split**: two planes on ONE axis, an *inline
(LEFT)* child bounded ABOVE and an *offset (RIGHT)* child bounded BELOW.
- `0x10–0x12`: `Lmax = (code[+1] << shift) + origin[axis]`, `Rmin = (code[+2] << shift) + origin[axis]`
  (both then `* scale + offset` to world). The inline child occupies `[.., Lmax]` on the axis; the offset
  child occupies `[Rmin, ..]`. (KDop: LEFT recursion sets `bound[axis].max = code[+1]`; RIGHT sets
  `bound[axis].min = code[+2]`. OBB: `param_3[axis+4] = code[+1]` for LEFT, a stack temp `= code[+2]`
  becomes RIGHT's min. Identical.)
- `0x20–0x22` compressed: a single `v = code[+1]` → `Lmax = (v+1) << shift`, `Rmin = v << shift` (the two
  planes are one quantum apart — a 1-unit overlap).
- `0x23–0x25`: `code[+1]`/`code[+2]` = `Lmax`/`Rmin` exactly as `0x10–0x12`, with BE16 child offsets.
- CUT `0x26–0x28` sets the running node box **absolutely**: `box.min[axis] = code[+1]`-plane,
  `box.max[axis] = code[+2]`-plane. `0x29–0x2b` uses BE24 **absolute** ints (no `<<shift`, no origin).

**Child-visit rule (the VM's pruning, reduced to an axis-aligned query AABB `[qmin,qmax]`):**
visit the inline child iff `qmin[axis] ≤ Lmax`; visit the offset child iff `qmax[axis] ≥ Rmin`. (The OBB
VM's slab test `FUN_10081890` collapses to exactly this for an axis-aligned query; a CUT prunes the whole
branch when the query is disjoint from the tightened box.) Implemented as `mopp.rs::query_aabb`.

**Conservative encoding (`mopp.rs::encode`).** For each split the inline child's `code[+1]` = its true
max-on-axis rounded UP, and the offset child's `code[+2]` = its true min-on-axis rounded DOWN — so a query
can never miss a boundary triangle. Root operand shift is `8` and the frame divides the widest extent by
`0xFF00` (not `0xFFFF`) so the AABB-max face maps to `int = 0xFF00 = 255<<8`, representable as an upper
bound. REANCHOR is not emitted (encoder stays at root precision; finer bounds would need `0x01–0x04`).

**Gates (all green, `cargo test -p mercs2_formats mopp`):**
- NO-MISS: `query_aabb(encode(mesh))` ⊇ brute-force AABB-overlap set over thousands of random queries, on a
  quad, a box, a 2 k random-tri soup, and 5 real `WpMeshShape16` meshes from `vz.wad` — **zero misses**;
  mean over-inclusion 1.0–4.1× (candidates / true overlaps).
- FindAll equivalence: `query_aabb(all-space)` == `decode()` shape-key multiset on **43 real MOPPs** —
  proves the traversal (REANCHOR / JUMP / CUT / 26-DOP) is byte-correct on Havok's own bytecode.
- Leaf-box reachability: on **2 703 real leaf boxes** across 43 MOPPs, a query at each fully-bounded leaf's
  reconstructed box centre returns that leaf — proves the pruning is nesting-correct (no over-prune).

**Still open:** an *absolute* `query_aabb(realMOPP) ⊇ brute-force-over-source-tris` cross-check is BLOCKED
by frame alignment — a co-located `WpMeshShape16`'s decoded vertices do not sit in the same integer frame
the paired `hkpMoppCode` was baked in (the root CUT extents are geometrically inconsistent with the mesh
AABB under any single uniform scale/shift; likely a `decode_mesh_shape16` vertex-pool fidelity issue, NOT a
`query_aabb` bug — the FindAll + leaf-box gates confirm the walk is correct). The 26-DOP diagonal split
plane geometry (`0x13–0x1c`) is still INFERRED; `query_aabb` visits both children unpruned for those
(conservative), and `encode` never emits them.

## Phase-3 encoder plan (we emit our OWN valid tree, not Havok's exact one)
1. Build any BVH over the triangles (median/SAH, axis-aligned).
2. Per node: quantize the split plane into the current integer frame; emit `0x10–0x12` (axis split, 1-byte
   right offset), or `0x23–0x25` (16-bit) when the left subtree exceeds 255 bytes. Recurse LEFT inline, place
   RIGHT at the recorded offset.
3. Leaves as terminals. **MVP-safe:** `0x0b <BE32 tri_index>` then `0x30` (delta 0) per leaf — trivially
   correct absolute keys; optimize to small deltas + `0x09/0x0a` base bumps later.
4. Optional: tighten node AABBs with CUT ops (`0x26–0x28`) for prune performance — not required for correctness.

### Invariants the emitter MUST honor
- Every byte reached at an instruction boundary must be a valid opcode (avoid all INVALID ranges) — else the
  "corrupted" assert fires and the load-time walk can read OOB.
- Child offsets must land exactly on a subtree's first instruction.
- 1-byte right offsets (`0x10–0x22`) cap the left subtree at 255 bytes; use `0x23–0x25` beyond that; jumps
  `0x05–0x07` similarly bounded.
- Node AABBs must **conservatively enclose** all descendant triangles so runtime overlap queries never miss.
- Emit raw little-endian-on-disk u8 (**no u32 swap** — that scramble is what corrupted `old_mopp.bin`).

## Open (non-blocking for an MVP encoder)
- Exact plane geometry of `0x13–0x1c` (26-DOP diagonal splits) — the MVP avoids them (axis splits only).
- Property (`0x60–0x6b`) semantics — application-defined per-terminal metadata; irrelevant to triangle indices.
- Whether absent key 32 is a degenerate-tri cull vs a sibling-shape key — needs the source `WpMeshShape16` tri count.
- `m_info` scale/offset for the specific `old_mopp.bin` sample (the file is only `m_data`).
