# WpMeshShape16 (pc-v10): from a shape key to an hkpTriangleShape

Sources: exe `game-files/canonical/dumps/mercs2_unpacked.exe` (pc-v10, file offset = VA - 0x400000).
Disassembly: `../wpmesh.asm` (the function at 0x725600 is lines 628-963, 0x725ba0 is lines 970-1124) and `small.asm` (small slot functions).
Capture: `20261103_new-game-first-mission-start.dmp`, read with `mercs2_probe dump-read`, saved as `cap_shape.txt`, `cap_region.txt` and `cap_pool.txt`.
Emulation scripts: `parse.py`, `tri0.py` (output in `tri0_out.txt`) and `normals.py` (output in `normals_out.txt`).
Grades: PROVEN = verified this run. INFERRED = reasoned or recalled, not checked. NOT DETERMINED = still open.

## 1. Runtime layout (offsets from the shape; container `this` = shape+0x10)

| shape off | container off | type | meaning | evidence | capture @0x291E7000 |
|---|---|---|---|---|---|
| +0x00 | - | ptr | shape vtable 0xBD23E0 | 0x725510 writes it | 0x00BD23E0 |
| +0x04 | - | u16 | memSizeAndFlags; the dtor frees `this` with this size | 0x7254eb, 0x72550a | 0 |
| +0x06 | - | u16 | refcount | - | 1 |
| +0x08 | - | u32 | userData | - | 0 |
| +0x0C | - | u32 | shape type | - | 22 |
| +0x10 | +0x00 | ptr | container vtable 0xBD2404 | 0x725516 | 0x00BD2404 |
| +0x14 | +0x04 | u8 | disableWelding. isWeldingEnabled = (byte == 0) | 0x41bc32 | 0 |
| +0x18 | +0x08 | f32 | radius, copied into triangle +0x10 | 0x725a98 | 0x3C23D70A = 0.01 |
| +0x1C | +0x0C | ptr | subpart array (stride 0x30) | 0x725614, 0x725bfb | 0x291E7030 |
| +0x20 | +0x10 | i32 | subpart count (signed compares) | 0x72563c, 0x725bea, 0x7255e2 | 3 |
| +0x24 | +0x14 | u32 | subpart array capacity and flags (dtor: `js` skip free, `&0x3fffffff`) | 0x725549-0x725556 | 0xC0000003 |
| +0x28 | +0x18 | ptr | shared u16x3 vertex pool (6 bytes per vertex), indexed by global vertex index | 0x72591e, 0x725c22 | 0x291EF9B0 |
| +0x2C | - | ? | not read by getChildShape or getAabb. NOT DETERMINED | - | 0 |

All rows PROVEN by the cited instructions and capture bytes, except: the name "userData" for +0x08 is INFERRED (it matches where hkpTriangleShape takes userData), and the type/refcount names at +0x0C and +0x06 are INFERRED (standard hkReferencedObject/hkpShape layout).

**Subpart (0x30 bytes):**

| off | type | meaning | evidence |
|---|---|---|---|
| +0x00 | f32x4 | origin (x, y, z, w) | 0x7259b5 .. 0x7259e4 |
| +0x10 | f32x4 | scale (x, y, z, w) | 0x725952, 0x725999, 0x7259ac, 0x725967 |
| +0x20 | ptr | triangle array, 8 bytes per triangle: {u16 i0, u16 i1, u16 i2, u16 extrusionLen} | 0x725911-0x72592e, 0x725b47 |
| +0x24 | i32 | numTriangles (signed `jl`/`jge`) | 0x725626, 0x7255d0 |
| +0x28 | ptr | u16 vertex-index list used only by getAabb | 0x725c15-0x725c19 |
| +0x2C | i32 | count of that list | 0x725c04, 0x725d70 |

All PROVEN.

**Captured subparts.** All three share origin (-199.99998, -99.36285, -199.99998, 0) and scale (0.0061, 0.00151, 0.0061, 1.0). Hex: origin = c347ffff c2c6b9c7 c347ffff 0, scale = 3bc800c7 3ac65ef1 3bc800c7 3f800000.

| subpart | triangle ptr | numTriangles | AABB list ptr | list count | AABB list |
|---|---|---|---|---|---|
| 0 | 0x291E70C0 | 1379 | 0x291E9BE0 | 6 | [328, 1001, 699, 0, 714, 0] |
| 1 | 0x291E9BF0 | 2393 | 0x291EE6C0 | 6 | [1028, 1003, 1944, 142, 1557, 312] |
| 2 | 0x291EE6D0 | 536 | 0x291EF790 | 6 | [2218, 547, 888, 880, 2199, 212] |

The answer to the caller's caution about 0x291E7050: `c0 70 1e 29` is the triangle ptr (+0x20), `0x563` is numTriangles (+0x24), `0x291E9BE0` is the AABB-list ptr (+0x28) and `6` is the list count (+0x2C). PROVEN.

- **All three subparts index one global pool.** Vertex index ranges are 0..1018, 142..2183 and 210..2301, so the ranges overlap. PROVEN (`tri0_out.txt`).
- **The 6-entry list holds exactly the subpart's extremal vertices,** in the order [maxX, maxY, maxZ, minX, minY, minZ]. The quantised min and max over the list equal the min and max over every vertex the triangles use, for all three subparts. PROVEN on this capture. The code does not depend on the order.
- **Every captured triangle has extrusionLen = 10** (4308 out of 4308). PROVEN.

First triangles:

| subpart | t0 | t1 | t2 |
|---|---|---|---|
| 0 | (0, 1, 2, 10) | (2, 3, 4, 10) | (4, 3, 5, 10) |
| 1 | (142, 1019, 143, 10) | (143, 1019, 144, 10) | - |
| 2 | (212, 213, 2184, 10) | - | - |

First pool vertices: v0 = (0, 38997, 0), v1 = (0, 38861, 655), v2 = (655, 38784, 0).

## 2. getChildShape: container slot 5, 0x725600

Calling convention: `__thiscall`, `this` = container (shape+0x10), arguments (key, buffer), ends with `ret 8`. It returns the buffer pointer in eax (eax = [ebp+0xc] at 0x725a72 and is not changed afterwards). PROVEN.

```
sp  = key >> 24            // shr, logical (0x72560e); NOT bounds-checked against count
tri = key & 0x00FFFFFF     // 0x725617
S   = &subparts[sp]        // [this+0xC] + sp*0x30 (0x72561d/0x725621)
if (!(tri < S.numTriangles)) {      // cmp esi,[..+0x24]; jl 0x725911 (signed, strict)
    // out-of-range fallback (0x72563c..0x72590f): scan i = 0..count-1 in order and copy
    // subpart[i] (all 0x30 bytes) to a stack local; stop at the first one with numTriangles > 0
    // (signed `jg`). S = that copy, tri = 0.
    // If none is found: S = the last copied subpart (or, when count <= 0, the original &subparts[sp]); tri = 0.
}
T    = S.triArray + tri*8                  // 0x725911-0x72591b
pool = [this+0x18]                         // shape+0x28
PA = pool + T.i0*6; PB = pool + T.i1*6; PC = pool + T.i2*6   // u16 movzx; lea x3, x2 -> *6
q  = (float)(int)zero_extend(u16)          // movzx + cvtsi2ss: UNSIGNED u16 -> exact f32
// Dequantise. Each component is fl( origin[k] + fl( scale[k] * q[k] ) ), single precision (SSE mulss then addss):
A.xyz = S.origin.xyz + S.scale.xyz * qA   // A from i0 (0x725938..0x7259f6)
A.w   = S.origin.w + S.scale.w            // no q in w (0x7259e4..0x7259f2)
B     = same with qB  (i1)                // 0x72594f..0x725a47
C     = same with qC  (i2)                // 0x725970..0x725a8e
if (buffer != 0) {                        // 0x725a7d; if 0, eax=0 and it stores to [0x20].. -> access violation
    buf+0x06 (u16) = 1                    // refcount; +0x04 memSizeAndFlags is NOT written
    buf+0x08 = 0                          // userData
    buf+0x0C = 4                          // shape type (every hkpTriangleShape ctor in the exe writes 4)
    buf+0x10 = [this+8]                   // radius = shape+0x18 (0.01 in capture)
    buf+0x00 = 0x00B57B34                 // hkpTriangleShape vtable
    buf+0x14 (u16) = 0                    // weldingInfo
    buf+0x16 (u8)  = 6                    // weldingType
    buf+0x50..0x5C = 0.0f; buf+0x17 = 0
}
buf+0x20 = A(x,y,z,w); buf+0x30 = B; buf+0x40 = C      // 0x725adb..0x725b42
w = T.extrusionLen (u16 at T+6)                         // 0x725b47
e = (w == 0) ? +0.0f : ( [0xBEAA2C] - (float)(int)w )   // [0xBEAA2C] = 0x80000000 = -0.0f, so e = -(float)w
buf+0x17 isExtruded = (e*e > 0.0f)                      // comiss xmm1,xmm4; jbe -> false (strict >)
buf+0x50 extrusion = (0.0f, e, 0.0f, 0.0f)              // 0x725b7f..0x725b8e
```

**Results:**

- **Winding: A, B, C = i0, i1, i2,** with no alternate-triangle flip and no swap. PROVEN at 0x725911-0x725935.
- **The extrusion is along local -Y,** its length is the raw u16 in local units (not scaled by the subpart scale), and it is 10.0 for every captured terrain triangle. PROVEN.
- **Captured triangles face +Y.** (B-A)x(C-A) has .y > 0 for 4267 of 4308 triangles, .y < 0 for 2, and .y == 0 for 39 (degenerate or vertical). So the extrusion points away from the (B-A)x(C-A) normal. PROVEN numerically (`normals_out.txt`).
- **Welding:** weldingInfo is always 0 and weldingType is always 6. INFERRED from Havok recall that 6 = WELDING_TYPE_NONE. Container slot 7 still reports welding enabled (+0x14 byte is 0).
- **Material and filter:** none is attached to the triangle. getCollisionFilterInfo returns 0 for every key (section 3).
- The hkpTriangleShape field names (+0x14 weldingInfo, +0x16 weldingType, +0x17 isExtruded, +0x50 extrusion) are the caller's reflected layout. The stores above match them.

## 3. Other slots

**Container vtable 0xBD2404** (eight slots, 0xBD2404..0xBD2420; 0xBD2424 starts another class's vtable, see below):

- **0 (0x725e40):** `sub ecx,0x10; jmp 0x7254d0`. A thunk to the shape's scalar deleting destructor. PROVEN.
- **1 (0x725590):** getNumChildShapes = sum of subpart.numTriangles. (Caller PROVEN.)
- **2 (0x6d5640):** `jmp 0x6fcd20c0`. getFirstKey; the caller reports the pc-v11 counterpart is `return 0`. Not re-verified here.
- **3 (0x7255b0):** getNextKey. (Caller PROVEN.)
- **4 (0x811d30):** `xor eax,eax; ret 4`. Takes one argument (the key) and returns 0. Calling it getCollisionFilterInfo is INFERRED from the Havok slot order; the behaviour is PROVEN.
- **5 (0x725600):** getChildShape (section 2).
- **6 (0x954180):** `mov eax,1; ret 4`. Takes one argument and returns 1. The behaviour is PROVEN; the name is NOT DETERMINED ("isChildEnabled"-like is SPECULATIVE).
- **7 (0x41bc30):** `return byte[this+4] == 0`. isWeldingEnabled. PROVEN.
- **"8" (0x725ee0) is not part of this vtable.** 0x725ee0 calls 0x725e60, which stores 0xBD2424 into [this] as its own vtable and releases an array of refcounted children ([+8] ptr, [+0xC] count, [+0x10] capacity). So 0xBD2424 is a different class's vtable. That class is probably `WpArray`: the string sits at 0xBD23D8, and 0x725f10 appends with an addref. The vtable boundary is PROVEN; the class name is INFERRED.

**Shape vtable 0xBD23E0** (nine slots, 0xBD23E0..0xBD2400):

- **0 (0x7254d0):** scalar deleting destructor. PROVEN. It calls the dtor 0x725500, which works as follows:
  1. It resets both vtables.
  2. If u16[+4] == 0 (the captured object has 0), it calls TLS-allocator vtbl[1] on [+0x1C] and then zeroes +0x1C, +0x20 and +0x24 (0x72551f-0x725542). What that vtbl[1] call does is NOT DETERMINED.
  3. It runs the hkArray free, which is skipped when capacity bit 31 is set (0x725549-0x72556f).
  4. Finally it frees `this` with size u16[+4] when flag&1.

  memSizeAndFlags = 0 together with capacity 0xC0000003 (DONT_DEALLOCATE) is consistent with the object living in in-place packfile memory. That makes it likely that the extrusion word w = 10 is the on-disk index-array content (INFERRED).
- **1 (0x725e10):** `coll->vtbl[1](coll, "WpMeshShape16" @0xBD23C0, 1, this); coll->vtbl[6](coll)`. This is calcStatistics (begin/end object). It has the same shape as the x360 `TriangleShp`/`ChildShape` functions in the corpus. The calls are PROVEN; the name is INFERRED.
- **2 (0x88c600):** generic; hkpTriangleShape shares it. If arg2 != 0, it calls 0x8988c0(this, arg2, arg1, 0). Name NOT DETERMINED.
- **3 (0x8cc1c0):** hkpShapeCollection::getMaximumProjection. PROVEN by the profiler string at 0xB58540.
- **4 (0x8cc2b0) and 8 (0x8cbe30):** hkpShapeCollection raycast variants. Both push timer tag 0xB58510 "TtrcShpCollect" and iterate getFirstKey/getChildShape. The castRay and castRayWithCollector names are INFERRED.
- **5 (0x8cbdc0):** returns `this ? this+0x10 : 0`, i.e. getContainer. PROVEN.
- **6 (0x725e00):** `mov eax,0x30; ret 8`. Takes two arguments and returns 48. The name is NOT DETERMINED (calcSizeForSpu is recall/SPECULATIVE).
- **7 (0x725ba0):** getAabb (below).

**getAabb (0x725ba0).** Calling convention: thiscall, `this` = shape, arguments (const hkTransform* T [ebp+8], float tol [ebp+0xc], hkAabb* out [ebp+0x10]), ends with `ret 0xC`.

```
out.min = (+FLT_MAX x4) [0xBEA9AC=0x7f7fffff]; out.max = (-FLT_MAX x4) [0xBEAA50=0xff7fffff]
for (s = 0; s < count(+0x20, signed); s++)          // 0x725bea jle; 0x725d86 jl
  S = subparts + s*0x30
  for (j = 0; j < S.listCount(+0x2C, signed); j++)    // 0x725c04 jle; 0x725d70 jl
    q = pool(+0x28)[ S.list(+0x28)[j] ]               // u16 index, then u16x3
    v.xyz = S.origin.xyz + (float)q * S.scale.xyz   // fl(o + fl(q*s)), same rounding as getChildShape
    v.w   = S.origin.w + S.scale.w
    p = transformPos(T, v)  // 0x88ea10, x87: p.c = ((T.col0[c]*x + T.col1[c]*y) + T.col2[c]*z) + T.t[c]; p.w = 0
    for c in 0..3 (incl. w): out.min[c] = (p[c] > out.min[c]) ? out.min[c] : p[c]   // comiss; ja keeps old
                             out.max[c] = (out.max[c] > p[c]) ? out.max[c] : p[c]
out.min.xyz -= tol; out.max.xyz += tol; the w lanes are copied unchanged (fld/fstp)
```

- **Inflation.** getAabb inflates only by `tol`. It adds neither the 0.01 radius nor the extrusion (10 m in the capture). PROVEN: no other inflation instruction exists in 0x725d93-0x725dfc.
- **Column layout.** hkTransform columns are at +0x00, +0x10 and +0x20, with translation at +0x30 (0x88ea2e..0x88ea86). PROVEN.
- **NaN handling.** A NaN component of p replaces the stored value, because an unordered comiss does not take `ja`. PROVEN by the instruction semantics.
- **x87 precision.** The transform runs on the x87 under the process's FPU control word. D3D9 may set 24-bit precision; this is NOT DETERMINED. If it is double or extended, intermediate products are not rounded to f32 before the final `fstp`.

## 4. Triangle key 0 (subpart 0, tri 0) from the capture (`tri0_out.txt`, PROVEN)

The indices are (0, 1, 2), extrusionLen 10, with qA = (0, 38997, 0), qB = (0, 38861, 655), qC = (655, 38784, 0).

| vertex | x | y | z | w | hex |
|---|---|---|---|---|---|
| A | -199.999985 | -40.342854 | -199.999985 | 1.0 | c347ffff c2215f15 c347ffff 3f800000 |
| B | -199.999985 | -40.548683 | -196.002121 | 1.0 | c347ffff c22231da c344008b 3f800000 |
| C | -196.002121 | -40.665218 | -199.999985 | 1.0 | c344008b c222a92f c347ffff 3f800000 |

The other fields are radius 0.01 (0x3c23d70a), weldingInfo 0, weldingType 6, isExtruded 1, extrusion (0, -10, 0, 0).

Keys 0x00000001, 0x01000000 and 0x02000000 were also computed (see `tri0_out.txt`). The havok.rs formula `min[k] + u16 as f32 * scale[k]` is **bit-identical** to the runtime for all four keys. That is expected: multiplication and addition are commutative, both round once in f32, and u16 to f32 is exact.

## 5. Differences: runtime vs mercs2_formats

- **The +6 word is not "material/pad".** At runtime it is the extrusion length (extrusion = (0, -w, 0, 0), isExtruded = w != 0). Retail terrain has w = 10 on every triangle.
  - havok.rs:121 calls it "material/pad" and discards it. `MeshShape` carries no extrusion.
  - `phy2_build.rs` `WpMesh16::index_bytes` (lines 1080-1090) writes 0, so authored meshes are non-extruded. The runtime would treat them as plain triangles; retail terrain cells are 10 m extruded prisms.
  - PROVEN by the code at 0x725b47-0x725b8e and the capture.
- **Per-subpart frame.** The runtime dequantises with each subpart's own origin and scale. `decode_mesh_shape16` (havok.rs:406-408, 449-451) uses subpart 0's min/scale for every subpart. That is equivalent only when every subpart shares the frame, as all three do here and as phy2_build writes them. In general it differs. PROVEN (code reading).
- **Out-of-range keys.** The runtime falls back to triangle 0 of the first non-empty subpart (section 2). Our code has no getChildShape, so nothing needs mirroring unless keys can be out of range. Subpart ids are not bounds-checked.
- **How the vertex pool is found.** The runtime reads the pool pointer directly from shape+0x28 (container+0x18; 0x72591e, 0x725c22). havok.rs finds it by a content scan instead: havok.rs:123-127 is marked "CONFIRM-LIVE: pool base found by scan", and havok.rs:395-399 says the mesh object has no fixup for it.
  - This answers that CONFIRM-LIVE: the live object holds the pool pointer at shape+0x28 (obj+40), filled at load by something outside the packfile fixups, presumably the PHY2 wrapper relocation. The runtime side is PROVEN.
  - Whether on-disk obj+0x28 holds a relocatable body offset (which would let the scan be replaced) is NOT DETERMINED: there is no on-disk chunk for this cell in this run.
  - Corroboration: the subpart array pointer 0x291E7030 = shape+0x30, which matches havok.rs `sp0 = obj+48`. Shape slot 6 returns 0x30, equal to that object size; the name stays SPECULATIVE.
- **Unchanged:** index order (A, B, C = i0, i1, i2), u16 unsigned, 6-byte pool stride, one global pool, and the 8-byte triangle stride all match havok.rs. PROVEN.
- **phy2_build's secondary array (+40/+44) is the getAabb list.** It writes every vertex index, while retail stores 6 extremal ones. Both give the same AABB for that subpart's vertices. phy2_build's description matches the runtime; consistent with 0x725ba0 (PROVEN).
- **The w lane** (origin.w + scale.w = 0 + 1 = 1.0) is written to each vertex's w. havok.rs ignores w, and the triangle algorithms presumably do too (INFERRED, unchecked).

## Gaps (NOT DETERMINED)

- The meaning of shape+0x2C (0 in the capture).
- The names of container slot 6, shape slot 6 and shape slot 2.
- The FPU precision for the getAabb transform.
- Whether the convex-vs-triangle agent honours isExtruded/extrusion (that depends on hkpTriangleShape consumers outside this scope).
