> Folded into `../s2_step_integrate_spec.md` §1.3 and §5. In B, slot 6 (processContact) is called statically at `FUN_008FDA80` decomp line 117.

# Fork result: the post-integrate AABB update `FUN_008EF520` and contact-listener timing (pc-v10)

Grades: **P** means PROVEN this run (address, emulation or capture check given). **I** means INFERRED. **S** means SPECULATIVE. "recall" marks Havok knowledge, which is at best I.

Working files are in `s2/`:
- `dis_8ef520.txt`, `dis_8cfda0.txt`, `dis_92cb10.txt`, `dis_8f4d80.txt`: objdump output;
- `aabb_body.txt`: the scratch decomp, used only as a map;
- `cap_aabb.txt`, `cap_listener.txt`, `verify_child11.txt`: capture reads;
- `emu_8cfdb3.txt`, `emu_8f4d8b.txt`: splice emulation;
- `listener_*.txt`, `consts_aabb.txt`.

## A. `FUN_008EF520(collisionInput, entity**, n)`

### A.0 Signature and constants

`FUN_008EF520` takes `param_1` = `*(world+0x6C)` (hkpProcessCollisionInput, capture `0x20017E80`).

Fields of the collision input it reads (P, capture):

| Offset | Field | Capture value |
|---|---|---|
| +0x04 | tolerance | 0.1 |
| +0x20 | aabb32 offset, used for min | (4096, 1000, 4096, 0) |
| +0x30 | offset, used for max | (4096, 1000, 4096, 0); the same values as +0x20 |
| +0x40 | scale | (262128, 1073680.4, 262128, 0) |
| +0x50 | stepInfo copy | (56.9314, 56.948, 0.016613, 60.1938) |

The broadphase at world+0x54 (`0x1FFFFE00`) holds the same offset and scale at +0x80 and +0x90 (P, capture).

Constants (P: the exe and the capture give identical bytes, `consts_aabb.txt`):
- 0.5: f64 at `0xBEA940`;
- quantisation upper clamp: f32×4 at `0xCDF690` = 2147352576.0 (`0x4EFFFC00`);
- quantisation lower clamp: f32×4 at `0xB132F0` = 0.0;
- the list getAabb starts from ±1.7014e38 (`0xB5840C` / `0xB58408`);
- swept-rotation thresholds in `FUN_008CFDA0`: f64 π/8 at `0xB587C0` and π/4 at `0xB587B8`.

### A.1 Prologue (P, from 0x8EF52C to 0x8EF54A)

```
halfTol = (float)(collisionInput->tolerance * 0.5)
```
The multiply is x87 with the f64 constant, stored to f32 at `[esp+0x1C8]`.

For each entity, it reads `n16 = u16 entity+0x50` (`boundingVolumeData.numChildShapeAabbs`) at 0x8EF564. For the boat this is 13, so the **child path** (0x8EF579–0x8F132A) is taken. When n16 = 0, the single-AABB path at 0x8F132A runs instead.

### A.2 The child path, the one the boat takes

1. `container = shape->vtbl[+0x14]()`. For the list shape this is slot 5, `0x8CBDC0` (getContainer, I). Then `out = (hkAabbUint32*) entity+0x54` (`childShapeAabbs`), at 0x8EF579–0x8EF586.
2. `FUN_008CFDA0(&entity->motionState (+0xE0), buf)` fills `buf` at `[esp+0x3A0]`. Its layout is P, from emulation `emu_8cfdb3.txt` and the disassembly in `dis_8cfda0.txt`:

   | buf offset | Contents |
   |---|---|
   | +0x000 | motionState pointer (`mov [ebx],esi` at 0x8CFDB9) |
   | +0x010 | transform[0..]: the intermediate transforms; translation.w holds a lever scale |
   | +0x110 | count of intermediate transforms |
   | +0x120 | **T0**: the transform at the start of the step, built from rot0 and com0 |
   | +0x160 | **T1⁻¹**: the inverse of the current transform at motionState+0x00 (`FUN_008931E0` → `FUN_00893AD0` transposes, translation = −Rᵀ·t) |

   How T0 is built:
   - The interpolation fraction is computed as `(t0 − t0)·invDt`, which is always 0 (0x8CFDC0–0x8CFDCE).
   - So q = normalise(rot0·1 + rot1·0) (0x8CFDE8–0x8CFEB1).
   - R0 = quatToMatrix(q) through `FUN_0088D070`.
   - trans0 = com0 − R0·comLocal (0x8CFEC2–0x8CFFA7). trans0.w = 0 − 0.0 (f64 `0xBEA968`).

   How many intermediate transforms there are, from the angle a = motionState+0x9C (deltaAngle.w):
   - invDt (motionState+0x5C) == 0: count = 0 (0x8CFFAC → 0x8D04E5).
   - a < π/8: count = 1. transform[0] = copy of T0 (`FUN_0041DE00` = rotation copy + translation copy). transform[0].trans.w = 1 / (1 − a·a·0.5). This is at 0x8CFFF7–0x8D0016.
   - a ≥ π/8: the multi-transform branch at 0x8D0027 (a second compare against π/4 at 0x8D0029). It was not transcribed; the boat's a is about 0.002, so it never takes this branch (NOT DETERMINED).
3. The entity accumulators start at the point com1 (entity+0x130):
   - curUnion min = max = com1, at `[esp+0x1A0..0x1BC]`;
   - sweptUnion = a copy of curUnion (`rep movsd`, 8 dwords, at `[esp+0x1D0..]`).
   - This is at 0x8EF5A3–0x8EF621.
4. **Child loop.**
   - `key = container->vtbl[+8]()`, `+0xC` = next, end = −1. If `container->vtbl[+0x18](key)` returns 0, the record is written as {min = 0x7FFFFFFF ×3, everything else 0}.
   - `child = container->vtbl[+0x14](key, tmp)`.
   - `child->vtbl[+0x1C](&motionState.transform, halfTol, &aabb)`. Slot 7 is getAabb (P: the list's slot 7 `0x8C8B20` is the union of each child's +0x1C, decomp `fns/fn_008c8b20.txt`).
   - **Correction to the README:** `0x8C8880` (slot 6) is not getAabb. It loops children calling +0x18(info, 0x100), stores the result into childInfo+8, and returns 0x70 or −1 (calcSizeForSpu-like, I).
   - For hkpConvexVerticesShape (`0x8BB7C0`), getAabb is `FUN_008BBE50(T, aabbHalfExtents(+0x20), aabbCenter(+0x30), radius(+0x10) + halfTol)`:
     ```
     ext.x = |he.y·T[4]| + |he.x·T[0]| + p + |he.z·T[8]|          (order as at 0x8BBE50)
     ext.y = |T[5]·he.y| + |he.x·T[1]| + |T[9]·he.z| + p
     ext.z = |T[6]·he.y| + |T[2]·he.x| + |T[10]·he.z| + p
     ext.w = p
     c = T·center + t
     min = c − ext, max = c + ext
     ```
   - **Current child AABB (P, bit-exact, see A.5):** `aabb = child.getAabb(T1, halfTol)`.
   - Centre and half extent (0x8EF6CB–0x8EF78D):
     ```
     e = (max − min)·0.5    (each lane stored f32, ×0.5 from f64 0xBEA940)
     c = min·0.5 + max·0.5
     ```
   - Candidate centre positions. minC and maxC start at c (`[0x140..]` / `[0x150..]`), then are extended by:
     - `cl = T1⁻¹·c` (from buf+0x160; 0x8EF794–0x8EF885);
     - `c0 = T0·cl` (from buf+0x120; 0x8EF88C–0x8EF929);
     - for each intermediate transform i, with `d = cl − comLocal` and `s = transform[i].trans.w`: `p = s·d + comLocal`, then `pw = R_i·p + t_i` (0x8EFA16–0x8EFC8D).
     - The w lanes of minC/maxC are clamped against 0.
   - Rotation growth (0x8EFCA0–0x8EFD96):
     ```
     L = sqrt(e.x² + e.y² + e.z²)        (x87, stored f32; helper 0x9EE730)
     e_i = e_i + L·a                      (a = motionState+0x9C, all 4 lanes)
     e_i = min(e_i, L)                    (ties keep L)
     ```
   - Swept child AABB (0x8EFD98–0x8EFF45):
     ```
     sMin = min(minC − e, aabb.min)
     sMax = max(maxC + e, aabb.max)
     ```
   - Union into the entity accumulators: curUnion ∪= aabb and sweptUnion ∪= [sMin, sMax] (0x8EFF4C–0x8F0153).
   - **Quantise** (P, the pattern is repeated for every bound, e.g. 0x8F0155–0x8F0901):
     ```
     q = fistp( clampLo0( clampHi( (offset + x)·scale ) ) )
     ```
     - Each product is stored to f32 first.
     - `clampHi`: x = min(x, 2147352576); when equal, the constant is stored.
     - `clampLo`: x = max(x, 0). Unordered (NaN) gives 0, because `test ah,5 / jnp` keeps x only when C0 alone is set.
     - fistp uses the current rounding mode (nearest-even by default; the control word was not read here).
     - min uses the offset at +0x20; max uses the offset at +0x30.
   - **Record** (P, 0x8F0908–0x8F09CB):
     - min[3] and max[3] = the quantised **current** aabb;
     - `dMin = min − q(sMin)` and `dMax = q(sMax) − max`, as int32;
     - `v = OR of all six`; `s = 0`;
     - `while v ≥ 0x800: v >>= 4, s += 4`, then `while v ≥ 0x100: v >>= 1, s += 1` (logical shr, signed compare);
     - `expansionShift(+0xF) = s`; `expansionMin(+0xC..E) = (u8)(dMin >> s)`; `expansionMax(+0x1C..1E) = (u8)(dMax >> s)`. The shift is an arithmetic shift, which **truncates**.
     - Then `out += 0x20` and `key = next`.
5. After the loop:
   - The entity record (`boundingVolumeData` at entity+0x30) gets curUnion quantised into min/max (+0x30 / +0x40), and the expansion from sweptUnion encoded the same way (+0x3C..3F, +0x4C..4E). This is 0x8F09F7 onward; decomp lines 2451–2614 are the map.
   - Then, with `cnt` = the number of keys visited:
     - If `cnt < 0x100`: build {key = childAabb.min.x (u32), index} pairs in the per-thread stack allocator. Sort ascending with `FUN_008F21A0` (recursive Hoare quicksort, unsigned compare, not stable). Write each child's rank into its padding byte +0x1F.
     - Otherwise, write the rank i (0..255) in key order.
   - **P from the capture:** the 13 padding bytes are 7, 3, 5, 12, 6, 4, 9, 8, 1, 2, 11, 0, 10. That is exactly the ascending rank of min.x over the 13 records.

### A.3 The single-AABB path, n16 = 0 (map from decomp lines 1758–2036; not on the boat)

```
aabb = shape.getAabb(T1, halfTol)
k = deltaAngle.w(+0x17C) · objectRadius(+0x180)
sMin = min(aabb.min, max(aabb.min − k, com1 − (r + halfTol)))
sMax = max(aabb.max, min(aabb.max + k, com1 + (r + halfTol)))
d = com0(+0x120) − com1(+0x130)
sMin += min(d, 0)
sMax += max(d, 0)
```
Then the same quantise and encode into entity+0x30. Grade I (decomp only; the disassembly was not transcribed).

### A.4 What the broadphase is handed (P, `FUN_0092CB10` "LtBroadPhase", 0x92CCA6–0x92CDA5)

For each entity of the job:
- It collects `&entity->broadPhaseHandle` (entity+0x24).
- **If `bv.min.x (+0x30) > bv.max.x (+0x40)` (unsigned), it calls `FUN_008EF520(collisionInput, &entity, 1)` here** (0x92CCBB–0x92CCCF). This is how a never-computed or invalidated AABB gets filled.
- The broadphase AABB is the **expanded** box:
  ```
  min_i − (expansionMin_i << shift)
  max_i + (expansionMax_i << shift)
  ```
  as uint32.
- Then `broadPhase(world+0x54)->vtbl[+0x2C](handles, aabbs, n, &newPairs, &delPairs)`. When broadphase+0x10 ≠ 0, the call is bracketed by `0x907C90` / `0x907CA0` (a lock, I).
- The pairs then go to `0x8CD850` and the following calls.

**What part S2 produces for the narrowphase:** motionState.transform and the swept transform (com0/com1/rot0/rot1/deltaAngle, read by the agents, I), plus entity+0x30 (`boundingVolumeData`) and the 13 child records.

The narrowphase reads the per-child records. That they are used for child-pair culling in the collection agents is I.

### A.5 Capture checks (body `0x1EBB8000`, `verify_child11.txt`)

- **Child 11 (the 127-vertex whole hull), current AABB: P, bit-exact on all 6 uint32.**
  - The prediction is `FUN_008BBE50` with motionState.transform, radius 0.05 + halfTol 0.05, then `fistp((4096 + x)·scale)` in f32.
  - It reproduces 0x24EF5C40, 0x3DA0A6C0, 0x603AC500 / 0x25178E00, 0x3DD12980, 0x60686A80.
  - So the AABB in the capture was computed from the **captured post-integrate transform**.
- **Entity record:** the entity+0x30 record is byte-identical to child record 11, including expansions (0x22, 0xA0, 0x22 / 0x22, 0x8A, 0x22) and shift 7. This is consistent with the union in A.2 step 5: child 11 encloses every other child and com1. P for the equality.
- **Expansion bytes: one count too small, NOT DETERMINED.**
  - Predicted: L = 7.74591, a = deltaAngle.w = 0.00212118, so L·a = 0.016431 m = 4307 ints (x, z) and 17642 (y). With `>>7` that gives x 0x21, y_max 0x89, z 0x21.
  - Captured: 0x22, 0x8A, 0x22, which needs ≥ 0.016603 m in x and z and [0.016452, 0.016571) in y_max.
  - The y_max interval and the x interval cannot come from one uniform L·a. So either an input differs from the captured value at the moment of the AABB, or the multi-centre term contributes more than I derived.
  - Tried: reading the shift and sar code (truncation P), the |e| and clamp code, the 8CFDA0 buffer by emulation, and the lever term (d ≈ 0 for child 11).
  - Not tried: emulating `FUN_008EF520` on the captured memory, which would settle it.

## B. Contact-listener slots: who calls them and when

The boat listener object `0x1F0811A0` (P, capture):
- +0 is vtable `0xBAA310`; +4 is vtable `0xBAA324`;
- +0xC is the body; +0x10 = 1021.27 (time without contact); +0x18 is the counter (0).
- It is registered in body+0x1F0 (collisionListeners, size 1).

**Correction to the brief:** the hkpCollisionListener vtable has **5** slots. `0xBAA324` begins at `0xBAA310 + 0x14`, so "slot 5 = 0x440B40" is really slot 0 of the entity-listener vtable. `0x440B40` = `sub ecx,4; jmp 0x43D1B0`, a this-adjust thunk. `0x43D1B0` is the scalar deleting destructor: it unregisters through `FUN_008DD570` / `FUN_008DDEB0` when +0xC ≠ 0, restores the base vtables, and frees if (flag & 1). All P.

| Slot | Boat function | Fired by (label) | Called from (contact mgr 0xB589D4 slot) |
|---|---|---|---|
| +0x0 added | 0x4464D0: `[this+0x18] += 1` | entity: `FUN_008F4D80` "TtcpAddCb" (0xB59A94); world: `FUN_008EA570` | slot 3 `0x8D3DA0` addContactPoint (0x8D3F36 / 0x8D3F52 / 0x8D3F6E); slot 7 `0x8D3CA0` (addToi, I) |
| +0x4 confirmed | 0x848E30 (empty) | `FUN_008F4E30` / `FUN_008EA620` "TtcpConfCb" | `0x8D3BC0`, `0x8F9950`, `0x954E70` (not in this vtable; phase NOT DETERMINED) |
| +0x8 removed | 0x4464E0: `[this+0x18] −= 1` | `FUN_008F4EE0` / `FUN_008EA6D0` "TtcpRemCb" | slot 5 `0x8D4180` removeContactPoint; slot 8 `0x8D3B40`; `0x8F9850` / `0x8F98D0` |
| +0xC process | 0x848E30 (empty) | `FUN_008F4F90` / `FUN_008EA780` "TtcpProcCb" | slot 6 `0x8D42F0` processContact; `0x8F9A60` |
| +0x10 | 0x43D1B0 (destructor) | — | — |

Notes on the table:
- `FUN_008F4D80` has a SecuROM terminal stub at 0x8F4D8B. Emulation (`emu_8f4d8b.txt`) shows the stolen instruction is `lea ebx,[eax+0x1F0]`. The loop then calls `[[listener]+0]` for i = size−1 down to 0. P.
- The world-listener helpers walk world+0x174 / world+0x178; the entity ones walk entity+0x1F0 / u16 +0x1F4. Every helper ends with a compaction call: `0x8E9E00` (world) or `0x8F48E0` (entity). P.
- Before firing, `FUN_008D3DA0` calls the world helper, then the entity helper for each of the two bodies whose u16 +0x1F4 ≠ 0. P (decomp `d_8d3da0.txt`).

**Timing.**
- The contact-manager slots have no static callers; they are reached through the virtual call from the narrowphase agents. That is I: by recall, and by the README's agent map. A direct agent → mgr+0xC call site was not located this run.
- So **added and removed fire inside the narrowphase (job 0xD, `FUN_008FDA80`) of step N**. That is after step N's solve and integrate, and before step N+1's solve (I, from that and the job order the parent has proven).
- The counter at +0x18 counts **points**: one increment per added point and one decrement per removed point (P from the slot bodies).
- The boat action reads it in the next step's stepBegin actions (I).

## NOT DETERMINED
1. The one-count mismatch in the expansion bytes (A.5).
2. The 8CFDA0 branch for a ≥ π/8: the multi-transform case at 0x8D0027 was not transcribed.
3. The exact direct call site from the agents to the mgr slots.
4. The phase of the confirmed callback, from `0x8D3BC0` / `0x954E70`.
5. The x87 control word (rounding of fistp) was not read.
