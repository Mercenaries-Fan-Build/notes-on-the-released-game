---
status: current
evidence: proven
---

# Boat body vs static world in Mercenaries 2 (pc-v10): what Havok 5.5 does, read from the binary

## Pages, and what they correct on this one

| Page | What it has |
|---|---|
| [`query_path.md`](query_path.md) | From two overlapping bodies to the (convex, triangle) pairs: agent entries, the list agent, the MOPP query VM, `WpMeshShape16` |
| [`convex_triangle.md`](convex_triangle.md) | One hull against one triangle: the agent `FUN_00901510`, GSK (`n2/gsk/`), the manifold, welding |
| [`manifold_arithmetic.md`](manifold_arithmetic.md) | The agent's arithmetic in binary order: the point refresh `FUN_00916360`, the 4-point reduction `FUN_00917A40`, transforms and create helpers (`n3/`), a bit-exact replay of a captured contact point (`n3/gate/`), the thread and x87 precision of the step; 14 corrections to `convex_triangle.md` |
| [`support_and_tim.md`](support_and_tim.md) | The hull's and the triangle's support functions with their tie rules, the per-triangle predicted-distance machine of `FUN_0090C290` (skip, refresh, full test, remove-all), entry creation, the hull's getAabb; gate scripts in `n4/gate/` (an interpreter that runs the objdump listing); corrections to the three pages above |
| [`contact_solve.md`](contact_solve.md) | Contact manager, contact Jacobians, the solver's contact opcodes, the export |
| [`body_construction.md`](body_construction.md) | From a model's PHY2 to its bodies: the wrapper's node tree and mass records, which shapes a body lists, child and body filter infos, the body cinfo (motion type, the inertia rule, friction, damping, velocity limits, penetration depth), checked against 1,910 captured bodies |
| [`step_and_integrate.md`](step_and_integrate.md) | The order of one step, stepBegin, the two integrators, `hkpBoxMotion` |

Where this page and those disagree, they are right:

- `FUN_008EF520` is the AABB update after integration, not the integrator. The integrators are `FUN_008EC5B0`
  (island without constraints) and `FUN_008EE2D0` (solver path).
- `FUN_008C61A0` is the agent2 bv-tree agent, not the agent-nn machine; the per-entry driver is `FUN_00909CA0`.
- The MOPP query VM is `FUN_00A49960` → `FUN_00A48E10`; the welding pass is `FUN_0090AED0`, a no-op against
  terrain triangles (weld type 6).
- The `−0.2` seed in `FUN_008D3DA0` does not run for the boat (it has a collision listener); its seed is the
  deferred pass in `FUN_008DCF30`. Friction is stored as an hkUFloat8 byte: boat on terrain 0.549.
- The motion, contact and solver code is x87, not SSE.
- The third split body resumes at `0x92A27C`. The cinfo's 0.698 reaches the weld table as its second argument.
- The MOPP shape's `hkpMoppCode` is at `+0x10`, its data at `+0x14` (`+0x08` is userData).
- The boat's contact-listener vtable `0xBAA310` has 5 slots; `0x43D1B0` is its destructor and `0x440B40`
  belongs to the entity-listener vtable. The list shape's getAabb is `0x8C8B20`.

Read of 2026-11-25. Scope: the opening boat (`VzaCon001_StartingBoat`, model `0xB1EB099F`, rigid body `0x1EBB8000`) against the
static world, in pc-v10. Sources: the unpacked exe
`game-files/canonical/dumps/mercs2_unpacked.exe` (sha256 `8c179a99…bc7ba`, checked this run; file offset =
VA − 0x400000), the capture `game-files/memory-dumps/updated-chris-exports/20261103_new-game-first-mission-start.dmp`,
the Ghidra export `output/_ghidra_exports/pc-v10.functions.jsonl` (Ghidra 12.1.4) and
`x360-preview-profile.functions.jsonl`, and the splice table `output/_exemap_exports/pc-v10.splices.tsv`.

Grades: **P** = PROVEN (verified this run, with the address or command). **I** = INFERRED (reasoned, not
checked). **S** = SPECULATIVE. **HK** = recalled from general Havok 5.5 knowledge. HK is never used as a fact
about this binary unless an address backs it.

The `*.txt` files this page names were working outputs and are not kept; each is a read of the image, the
capture or the export at the address given beside it (`mercs2_probe dump-read` for the capture, `objdump -d`
for the image).

## 0. The method that makes the layouts PROVEN: the exe ships Havok's own reflection

The exe carries the Havok 5.5 `hkClass` / `hkClassMember` / `hkClassEnum` tables for 224 classes.
`classes.py` scans for them and writes `classes_all.txt` and `classes_sel.txt`; `enums.py` writes `enums.txt`.
Each member record is 24 bytes: name, class, enum, type, subtype, cArraySize, flags, offset, attributes.
Every field name and offset below comes from these tables, not from recall. Examples:

| Class | hkClass @ | Size | Members @ |
|---|---|---|---|
| hkpWorld | 0xE7809C | 0x310 | 0xB6DE78 (68 members) |
| hkpWorldCinfo | 0xE7805C | 0xD0 | 0xCE0580 (42 members; defaults 0xB6DC00) |
| hkpEntity | 0xE7816C | 0x200 | 0xB6E5F0 |
| hkpRigidBody | 0xE77FDC | 0x200 | (no own members) |
| hkpCollidable | 0xE77B94 | 0x4C | 0xB6CE38 |
| hkpMotion / hkMotionState | 0xE7891C / 0xE791B8 | 0x120 / 0xB0 | 0xCE0DF0 / 0xB91F30 |
| hkpListShape / ChildInfo | 0xE77A34 / 0xE779F4 | 0x70 / 0x10 | 0xB6CC38 / 0xB6CBD8 |
| hkpConvexVerticesShape | 0xE775D4 | 0x60 | 0xB6C690 |
| hkpMaterial | 0xE782EC | 0xC | 0xCE0AC8 |
| hkpGroupFilter | 0xE77984 | 0x100 | 0xB6CAF8 |

The reflected enums are all PROVEN (`enums.txt`): `hkpMaterial::ResponseType`, `hkpMotion::MotionType`,
`hkpWorldCinfo::SolverType`, `SimulationType`, `ContactPointGeneration`, `BroadPhaseBorderBehaviour`,
`hkpCollisionFilter::hkpFilterType`, `hkpConstraintAtom::AtomType` and `hkpConstraintInstance::ConstraintPriority`.
The shape-type enum comes from `FUN_008bfb60`.

---

## 1. The body

### 1.1 The rigid body `0x1EBB8000` (layout = hkpEntity reflection; values from the capture) — P

| Offset | Field (reflected name) | Value | Note |
|---|---|---|---|
| +0x00 | vtable | 0x00B58A2C | hkpRigidBody (same vtable on the terrain body) |
| +0x08 | world | 0x20007800 | |
| +0x10 | collidable.shape | 0x1EB93480 | |
| +0x14 | collidable.shapeKey | 0xFFFFFFFF | |
| +0x18 | collidable.motion | 0x1EBB80E0 | = &motion.motionState |
| +0x20 | collidable.ownerOffset | −16 | |
| +0x24 | broadPhaseHandle.id | 0x56 | |
| +0x28 | broadPhaseHandle.type | 1 = BROAD_PHASE_ENTITY | |
| +0x2A | **objectQualityType** | **3** | see §1.4 |
| +0x2C | **collisionFilterInfo** | **0x00B70000** | system group 183, layer 0, subsystem 0 |
| +0x30..+0x57 | boundingVolumeData | quantized AABB; numChildShapeAabbs 13; childShapeAabbs 0x1EBBCA00 | |
| +0x58 | **allowedPenetrationDepth** | **0.1** | collidable+0x48 (hkpCollidable member table 0xB6CEB0) |
| +0x5C | linkedCollidable.collisionEntries | ptr 0x2001C740, n = 1 | {agentEntry 0x1EB17E00, partner 0x1EC16A10} |
| +0x70 | name | null | |
| +0x74 | properties | 1 entry | |
| +0x80 | material.responseType (int8) | **1 = RESPONSE_SIMPLE_CONTACT** | the word reads as 1.0000001 only because the 3 padding bytes are `00 80 3F`; it is **not** a 1.0 float |
| +0x84 | material.friction | 0.3 | |
| +0x88 | material.restitution | 0.0 | |
| +0x96 | processContactCallbackDelay | 0 | set to 0 by the boat listener ctor `0x446460` |
| +0xB8 | simulationIsland | 0x1EE39500 | |
| +0xC0 | uid | 0x55 | |
| +0xCC | extendedListeners | 0x1FA8A0E0 | |
| +0xD0 | motion (embedded hkpMaxSizeMotion storage), vtable 0x00B5921C | type byte +0xD8 = **4 = MOTION_BOX_INERTIA** | |
| +0xE0 | motionState.transform | rotation rows + translation (−1726.966, −36.357, 2068.791) | |
| +0x120..+0x16F | sweptTransform | com0 (−1726.991, −35.533, 2068.774, w 56.931); com1 (…, w 60.194); rot0/rot1; comLocal (0, 0.82666, −0.0265) | |
| +0x170 | deltaAngle | (0.00059, ?, 0.00204, 0.00212) | |
| +0x180 | objectRadius | 6.49744 | |
| +0x184 | linearDamping | 0 | |
| +0x188 | angularDamping | 0.8 | |
| +0x18C | maxLinearVelocity (hkUFloat8) | byte 0x79 → **136.2 m/s** | table 0xB13380 |
| +0x18D | maxAngularVelocity (hkUFloat8) | byte 0x51 → **9.551 rad/s** | table 0xB13380 |
| +0x18E | deactivationClass | 2 | |
| +0x190 | inertiaAndMassInv | (1.4259e-5, 1.4071e-5, 1.9357e-4, invMass 1.25e-4 = 1/8000) | |
| +0x1A0 | linearVelocity | (0.00179, 0.15737, 0.00219) | |
| +0x1B0 | angularVelocity | (0.0354, −0.0014, 0.1227) | |
| +0x1C0 / +0x1E0 | deactivationRefPosition[2] / RefOrientation[2] | | |
| +0x1E8 | savedMotion | 0 | |
| +0x1F0 | collisionListeners (hkSmallArray) | 1: 0x1EF89880 → listener 0x1F0811A0 (vtable 0x00BAA310, the boat's contact listener) | |
| +0x1F8 | actions (hkSmallArray) | 1: 0x2001A8C0 → the boat actor 0x1F232400 | |

How the hkUFloat8 values are proven: `FUN_008d5790` decodes `body+0x18C` and `+0x18D` through
`DAT_00B13380[byte]`. The table is 256 monotonic floats from 0 to 1,000,002 (`ufloat8.txt`). The clamps that
use it are in `FUN_008ebe80` and `FUN_008ec5b0`, the integrator paths at motion +0xBC/+0xBD. **P**

Commands: `hexd.py`/`dump-read` for `0x1EBB8000:768` (`body.txt`); the layouts are in `classes_sel.txt`.

**Deactivator (asked for): there is none in this layout.** hkpEntity's reflection (17 members, `classes_sel.txt`)
has no deactivator member. Deactivation state is the motion's `deactivationClass` (2), its
`deactivationIntegrateCounter` (+0xD9 = 0x0D) and `deactivationNumInactiveFrames[2]` (+0xDA), plus the world's
per-class `deactivationInfo` (§3). **P**

### 1.2 The shape `0x1EB93480`: a Pandemic subclass of hkpListShape — P

- type +0x0C = 10 = `HK_SHAPE_LIST` (`FUN_008bfb60`).
- The vtable 0x00BA8C44 is written by game code at `0x4182BF`, inside `FUN_00418200`. Havok's own
  `hkpListShape::vftable` is 0x00B58458, written by the ctor `FUN_008CB570`.
- Slots 0–8 of 0xBA8C44 are identical to Havok's list slots. That covers every collision virtual: getAabb
  `0x8C8880`, castRay `0x8C8B20`/`0x8C89B0`, and so on.
- The game adds one extra virtual, slot 9 = `0x4176A0`. Its container vtable 0xBA8C6C is identical to Havok's
  `0xB58434` (`lvt.txt`).
- Layout = hkpListShape (size 0x70):

| Offset | Field | Value |
|---|---|---|
| +0x10 | container vtable | 0xBA8C6C |
| +0x14 | disableWelding | 0 |
| +0x18 | childInfo (ptr, size, capacity) | 0x1ED44E00, 13, 13 |
| +0x30 | aabbHalfExtents | (1.37857, 1.40433, 6.19226, w = 0.05) |
| +0x40 | aabbCenter | (0, 0.82666, −0.0265) |
| +0x50 | enabledChildren[8] | all 0xFFFFFFFF |

Each ChildInfo is `{shape, collisionFilterInfo, shapeSize = 0, numChildShapes = 13}`.

### 1.3 The 13 children — P (`boat_shape_summary.txt`; full vertex and plane lists in `boat_shape.txt`)

- Children 0–11 are `hkpConvexVerticesShape`: vtable 0x00B578FC, type 7, **convex radius +0x10 = 0.05 on every
  one**, connectivity null. Each has userData pointing to a Pandemic record framed by
  0xAAAAAAAA…0xBBBBBBBB and carrying hash 0x255EAB53.
- Child 12 is an `hkpMoppBvTreeShape`: vtable 0x00B6C588, type 11.
  - MOPP code 0x29667620, 15 bytes; codeInfo offset (0.914, 1.048, −3.361).
  - Its child is a Pandemic triangle collection at 0x29667660: vtable 0x00BD23E0, type 22 =
    `HK_SHAPE_TRIANGLE_COLLECTION`, radius +0x18 = 0.01.
  - That is the PHY2 `WpMeshShape16` with 2 triangles and 3 vertices.

| Child | filterInfo (layer) | Vertices / planes | Local AABB min .. max | PHY2 hull |
|---|---|---|---|---|
| 0 | 0x00B7001D (29) | 8 / 11 | (0.663, 1.009, −4.880) .. (1.097, 1.854, −3.433) | 20 |
| 1 | 0x00B7001D (29) | 10 / 13 | (−0.751, 1.795, −4.946) .. (0.751, 1.884, −4.540) | 19 |
| 2 | 0x00B7001D (29) | 6 / 5 | (−1.058, 1.058, −3.351) .. (−0.859, 1.366, −0.620) | 18 |
| 3 | 0x00B7001D (29) | 12 / 12 | (−0.686, 1.063, −0.996) .. (0.686, 1.325, −0.609) | 17 |
| 4 | 0x00B7001D (29) | 22 / 13 | (−1.062, −0.505, −3.313) .. (1.062, 0.482, −1.167) | 16 |
| 5 | 0x00B7001D (29) | 24 / 15 | (−1.319, 0.030, −3.304) .. (−0.690, 1.009, −1.163) | 15 |
| 6 | 0x00B7001D (29) | 25 / 15 | (0.690, 0.030, −3.304) .. (1.319, 1.009, −1.163) | 14 |
| 7 | 0x00B7001D (29) | 51 / 34 | (−1.310, −0.523, −1.445) .. (1.310, 1.009, −0.264) | 13 |
| 8 | 0x00B7001D (29) | 60 / 37 | (−1.327, −0.455, −5.862) .. (1.327, 1.009, −3.170) | 12 |
| 9 | 0x00B7001D (29) | 8 / 11 | (−1.097, 1.009, −4.880) .. (−0.674, 1.854, −3.433) | 11 |
| 10 | 0x00B7001D (29) | 107 / 72 | (−1.303, −0.528, −0.264) .. (1.303, 0.921, 6.116) | 10 |
| **11** | **0x00B7001C (28)** | **127 / 90** | **(−1.329, −0.528, −6.169) .. (1.329, 2.181, 6.116)** | **9 (the whole hull)** |
| 12 | 0x00B7001D (29) | MOPP + 2-triangle mesh | — | MOPP + WpMeshShape16 |

All children sit in body space with no transform shape (the list holds them directly). The list's cached AABB
centre equals the body's centre of mass. **P**

**They are the model's authored PHY2 pieces, byte for byte.** P.
- Commands: `mercs2_probe extract --model 0xB1EB099F boat_model.bin`, then `mercs2_probe phy2-probe
  boat_model.bin` (`phy2.txt`: 21 hulls, 1 MOPP, 1 WpMeshShape16), then `match_hulls.py`.
- For every runtime child 0–11, its rotatedVertices block, its planeEquations block and its 32-byte AABB block
  occur verbatim in the container (`match.txt`; child 11 verts at file offset 20756 = PHY2 hull 9, and so on).
- PHY2 hulls 0–8 (103, 19, 12, 8, 107, 6, 8, 8 and 12 vertices) are **not** in this body's list. Where they are
  used is NOT DETERMINED; a destroyed or alternate set is S.

### 1.4 Quality type, and whether CCD/ToI applies to this body — P

- The rigid-body ctor `FUN_008D5570` (hkpRigidBody(cinfo), stamps `hkpRigidBody::vftable`) sets
  `+0x2A` as follows. If cinfo+0xB3 is 0: a MOTION_FIXED (7) motion gets **1**; otherwise it gets
  `(cinfoMotionType != 6 KEYFRAMED) + 2`, so a keyframed body gets 2 and a dynamic body **3**. If cinfo+0xB3 is
  not 0, that value is stored. The boat has **3**; the terrain cell body `0x1EC16A00` has **1**.
- The 10×10 quality table is at dispatcher +0x1BB0 (dispatcher `0x2021D930`, vtable 0xB581BC; `disp.txt`).
  Its readers use the table value v as follows:
  - `FUN_009090C0` (the agent-entry creator): info = `0x1C20 + v*0x40`, which is info[v−1] of the array at
    +0x1C60.
  - `FUN_008FAC00`: makes no agent when v = 0; otherwise reads info[v−1].
  - `FUN_008D4640` (the hkpSimpleConstraintContactMgr ctor): constraint priority = u16 at `0x1C58 + v*0x40`.
- The boat/terrain entry is **table[3][1] = table[1][3] = 1, so info[0]**:
  - priority u16 = **1 = PRIORITY_PSI** (reflected `hkpConstraintInstance::ConstraintPriority`);
  - the continuous flag at info+0x10 is **0**;
  - the ToI separation fields are −5e19.
  - In `FUN_008C4430` (initCollisionQualityInfo) that +0x10 flag is set to 1 only for the ToI levels
    (`+0x1CB0`, `+0x1CF0`, `+0x1D30`).
- The live agent entry `0x1EB17E00` confirms it: byte +0x0C = 1, and byte +0x01 = agent3 type 9 (§4.2).
- **Conclusion: boat vs terrain is a discrete (PSI) contact. No time-of-impact or continuous collision is used
  for this pair. Fast rams are resolved only by the penetration recovery in the PSI solve.** P.
- The Havok names for qualities 1/2/3 (FIXED/KEYFRAMED/MOVING) are HK. The behaviour above does not depend on
  them.

Quality-info array as captured (`disp.txt`): info[0..5] u16 priorities at +0x38 are 1, 2, 3, 4, 4, 1. info[0]
starts with `0.1, 0.1, −0.005, −0.01`, which are tolerance and separation fields; their exact Havok names are
not resolved.

### 1.5 Collision filter: only the whole-hull child touches the ground — P

- The world filter is at `0x1FFFF700` (world +0x70). Its type +0x20 = 2 = HK_FILTER_GROUP, and it was built as a
  0x100-byte object (`thunk_FUN_03490000` → `FUN_008DC490`, inside `FUN_00413310`).
- Its pair test is **game code**: `FUN_006AF040` (disassembly in `dis_6af040.txt`). For filter infos a and b:
  1. If a and b share a nonzero system group (high 16 bits), they do not collide.
  2. If both subsystem ids (bits 5–9) are nonzero and differ, they do not collide.
  3. Otherwise they collide iff `table[layer b] & (1 << layer a)`, with the table at +0x34.
  - Rule 2 is not Havok's stock `subSystemDontCollideWith` rule.
- The list-child variants pass each **child's** filter info:
  - `FUN_006AF0D0` gets it through `container->getCollisionFilterInfo(key)` (vtable +0x10);
  - `FUN_006AF110` walks the hkpCdBody parent chain.
- The game builds the layer matrix in `FUN_00413310` with inlined enable/disable pairs; `FUN_006AF290` is
  disable-between-masks.
- From the captured table (`layers.txt`, symmetric):
  - layer 1 (terrain) collides with {0, 2, 3, 5, 6, 8, 9, 12, 13, 15, 16, 18, 20, 21, 23, 25, 26, 27, **28**};
  - layer 28 collides with {0–7, 10, 13, 16, 23, 28};
  - layer 29 collides with {0, 8, 9, 12, 15, 18, 20, 21, 23, 25, 27}.
- **So against the terrain (child filterInfo 0x00050001, layer 1), only child 11 (the 127-vertex whole-hull
  convex, radius 0.05) generates contacts.** The 11 detail hulls and the MOPP child (layer 29) are filtered
  out. Against bodies on layers 8, 9, 12, … the detail hulls collide instead.

---

## 2. The world it collides with at that spot

- **The terrain cell.** The boat's only broadphase partner is entity `0x1EC16A00` (from body+0x5C):
  - fixed rigid body (motion type 7, vtable 0x00B592EC), position (−1800, 0, 2200);
  - quality 1, filterInfo 0x00050001;
  - material: response 1, **friction 1.0**, restitution 0;
  - allowedPenetrationDepth FLT_MAX.
- **Its shape** is the same Pandemic list (vtable 0xBA8C44) with 1 child, AABB half extents (200, 49.59, 200).
  The child is an `hkpMoppBvTreeShape` at 0x291DA5E0 (MOPP code 0xC9AF bytes).
- **That MOPP's child** is the Pandemic triangle collection at 0x291E7000 (vtable 0xBD23E0, type 22,
  **radius 0.01**). It has 3 subparts of 0x30 bytes, each with origin (−200, −99.36, −200), quantisation scale
  (0.0061, 0.0015, 0.0061, 1) and a 16-bit vertex/index store; the first has 1379 vertices.
  - This is the in-memory form of `WpMeshShape16`. Its getChildShape and friends are game code at
    `0x725xxx`; the dtor is `FUN_00725500`.
  - Two vtable slots, 0x725590 and 0x7255B0, have no function in the export.
- The contact manager is `0x1EB7EF80`, vtable 0xB589D4 = `hkpSimpleConstraintContactMgr`. **It holds no contact
  points at capture time** (the boat is afloat).
- Rock props near the spot: **NOT DETERMINED**. The capture has the boat touching only the terrain cell in the
  broadphase. A dump taken against a rock is needed; see §5.4.

**Friction and restitution combination — P** (`FUN_008D47F0`, `dis_8d47f0.txt` 0x8D47FC–0x8D486A, called
from addContactPoint `FUN_008D3DA0`):
- friction = **sqrt(fA · fB)** of entity+0x84, stored through `FUN_0043D080` into the contact-point
  properties at +0x0C;
- restitution = **sqrt(rA · rB) · 128** (double 128.0 at 0xBEB7B8), written with fistp into the u8 at +0x0D.
  addContactPoint reads it back × 1/128 (0xB58938).
- When the restitution byte is 0 and neither body has listeners at +500, addContactPoint seeds the point's
  impulse with `−0.2 · v_rel·n / (invMassA + invMassB + 1e-10)` (constants 0xB58958, 0xB58960; body +0x19C =
  invMass).
- Boat (0.3) on terrain (1.0): **μ = 0.5477, e = 0**.

---

## 3. World simulation settings (world `0x20007800`, hkpWorld reflection + ctor `FUN_008D8C70`) — P

How the game builds the world:
- `FUN_00413310`: cinfo ctor `FUN_008E2DA0` (defaults), then `FUN_008E2CA0(6)` = setupSolverInfo
  (**SOLVER_TYPE_4ITERS_HARD**, from the reflected enum), then inline field writes 0x41347B–0x413522
  (`dis_413b.txt`, `dis_413.txt`), then `FUN_008D8C70(cinfo, 0xC544)`.

| Setting | Value | Evidence |
|---|---|---|
| simulationType | **3 = SIMULATION_TYPE_MULTITHREADED** (world +0xDC; sim vtable 0xB59E04 built by `FUN_008F75E0`) | game writes cinfo+0xBD = 3 at 0x4134E4; the ctor's switch on cinfo+0xBD (`fns/fn_008d8c70.txt` decomp lines 600–686: 1 → `FUN_008F2320`, 2 → `FUN_0092C4D0`, 3 → `FUN_008F75E0`; forced to 3 if `DAT_00E74B1C` ≠ 0) |
| gravity | (0, −9, 0) | 0x413516 from 0xBEB564 |
| collisionTolerance | **0.1** (collisionInput +4) | cinfo default 0xB11FD8; ctor `piVar12[1] = cinfo+0x50` |
| solver tau / damp | **0.9 / 1.1** | setupSolverInfo case 6 (0xB596B4, 0xB57FAC); `FUN_008D5F80` setTauAndDamping on world+0x1A0 |
| solverInfo (world +0x1A0) | one 1.0; tau 0.9; damping 1.1; frictionTau 0.45 (0.5·tau, 0xBEA940); dampDivTau 1.2222; tauDivDamp 0.81818; dampDivFrictionTau 2.4444; frictionTauDivDamp 0.40909; integrateVelocityFactor 0.81818 ×4; invIntegrateVelocityFactor 1.2222 ×4 | `FUN_008D5F80` + capture |
| solverIterations | **4** (world +0x2B4); invNumSteps 0.25 (+0x2C0) | cinfo+0x7C |
| solverMicrosteps | 1 (+0x2B8); invMicro 1.0 | cinfo+0x80 |
| per-substep values | globalAccelerationPerSubStep = g·dt/4 = (0, −0.03738, 0); globalAccelerationPerStep = g·dt = (0, −0.14952, 0); substep dt 0.0041533 (+0x2AC); inv 240.78 (+0x2B0) | written by `FUN_008F72C0` each step; capture |
| contactRestingVelocity | FLT_MAX (+0x200) | 0x4134C4 from 0xBEAB40 |
| contactPointGeneration | **2 = CONTACT_POINT_REJECT_MANY** (+0x300) | cinfo default |
| snapCollisionToConvex/ConcaveEdgeThreshold | 0.524 / **0.524** | ctor copies cinfo+0x88 into **both** +0xBC and +0xC0, so the cinfo concave value 0.698 is unused; `FUN_00A09930(0.524, 0.698)` sets the welding globals |
| enableToiWeldRejection | 0 | |
| expectedMaxLinearVelocity / expectedMinPsiDeltaTime | 200 / 1/30 (cinfo defaults; the game does not override them) | 0xB58A1C, 0xBEAB14; passed to `FUN_008C4430` |
| sizeOfToiEventQueue | 250 | |
| toiCollisionResponseRotateNormal | 0.2 | |
| deactivation | wantDeactivation 1 (+0xC5), deactivationReferenceDistance 0.02 (+0xC8); 6 deactivation-class records of 7 words at world+0x204 (raw in `hex1.txt` 0x20007A04–0x20007AA0), computed in the ctor loop from \|g\| | ctor loop `pfVar11 = world + i*7 + 0x81` |
| broadphase | hkp3AxisSweep over (−4096, −1000, −4096)..(4096, 1000, 4096); border behaviour 1 = FIX_ENTITY; query size 1024; update size 512 | |
| islands | wantSimulationIslands 1; minDesiredIslandSize 1 (game: `esi = 1`) | |
| processActionsInSingleThread | 1 | 0x4134EC |
| processToisMultithreaded | 0 | 0x413500 |
| step dt | stepInfo (world +0x190): start 56.931, end 56.948, **dt 0.016613**, inv 60.19 | written by `FUN_008F72C0` from the dt argument |

**How the game steps it** (P for the code read here, I for the job-queue processing):
- Per frame, the game runs N substeps with `N = clamp(floor(T·60 + 0.99), 1, 3)` and dt = T/N (boat
  `drive_spec.md` §F, 0x4036F0–0x403990).
- Each substep, `FUN_00413F90` calls the actor pre-steps (`FUN_00416AD0`), then `FUN_008D61C0`, then
  `FUN_008D6180(dt)`. `FUN_008D6180` → **`FUN_008F72C0`** = the multithreaded `stepBeginSt`. It:
  - opens the "TtSimulate" timer;
  - writes stepInfo, the collision-input stepInfo and the solverInfo substep values;
  - toggles the deactivation frame flags (+0x2C5..0x2C7);
  - fills the job data at world+0x68 and pushes the first island job on the hkJobQueue (`FUN_00A07690`,
    `FUN_00A07830`).
- The jobs are then taken by `TtGetNextJob` (`FUN_00A079C0`/`FUN_00A07F00`). The code map says that is the
  Pimp job pool.
- So, per Havok substep: one physics step of dt, with **4 solver iterations**, each applying gravity g·dt/4.
- Whether the jobs run on more than one thread in practice: NOT DETERMINED. Memory
  `pimp-one-job-worker` says one worker (I).

---

## 4. The step: function inventory and decode quality

**The re-check the code map asked for:** the PC step **does decode** in the current export, which postdates the
false-noreturn repair. Every driver and kernel listed below has a decomp with **no** halt_baddata or bad
instruction. The x87 helpers appear as `_CIsqrt`, and the SSE math is scalarized into readable C. The phase
identities are PROVEN by the Havok monitor-stream labels that each function pushes (`timers_pc.txt`).

The x360-preview-profile build also decodes, with no halt_baddata (`x360_timers.txt`, `x360_q.txt`). But its
kernels are VMX128 `auVar` blobs; for example, the solver `0x829CA890` has 3808 auVar references in 3201 lines.
**PC is the better source.** `corpus_translate` has no x360 translation for the PC solver or narrowphase
kernels, so they would be paired by timer label.

### 4.1 Step drivers (MT simulation, vtable 0xB59E04)

| Function | Bytes / decomp lines | Role (evidence) |
|---|---|---|
| `FUN_008F72C0` | 798 / 131 | stepBeginSt ("TtSimulate"; called by the game through `FUN_008D6180`) |
| `FUN_008F7B60` | 1343 / 224 | MT step finish / inter-island ("TtSimulate", "TtPostCollideCB", "LtInterIsland") |
| `FUN_008FE2E0` | 1102 / 215 | job processing ("TtBroadphase", "TtWaitForSolverCallbacks") |
| `FUN_009001B0` | 1163 / 224 | integrate job: setup + build Jacobians + solve + integrate ("StSetupJobs", "StSolver_1Cpu", "StActions") |
| `FUN_008FD040` | 1722 / 323 | solver driver (calls `FUN_00A1C940`, `FUN_00A2F840`, `FUN_008EF520`) |
| `FUN_008FDA80` | 1757 / 317 | agent-sector (narrowphase) job ("TtNarrowPhase", "TtNarrowPhaseTOI") |
| `FUN_008FD870` | 343 / 74 | post-collide ("StPostCollide") |
| `FUN_008F2970`, `FUN_008F3F10` | 1127, 927 | the single-threaded integrate and collide paths (StIntegrate / TtCollide); not used with simulationType 3 (I) |
| `FUN_0092B250`, `FUN_0092E8F0`, `FUN_0092C9E0`, `FUN_0092D090` | 545, 1303, 299, 689 | continuous / ToI ("TtTOIs", "StSolveToi"/"LtTOI"; `FUN_0092E8F0` calls setTauAndDamping for the ToI solve) — **not used for boat vs terrain** (§1.4) |

### 4.2 Narrowphase for this pair

**Agent dispatch tables** (dispatcher layout from `FUN_008C4DE0`, `FUN_008C3EC0` and the reader in
`FUN_008DB880`; captured values in `disp.txt`):
- agent2 type table at +0x1A0 `[typeA][typeB]`, predictive table at +0x5A0;
- agent2 functions at +0x9A0, stride 0x14: {create, getPenetrations, getClosestPoints, linearCast, isFlipped,
  isPredictive};
- agent3 type tables at +0xEB0 and +0x12B0;
- agent3 functions at +0x16B0, stride 0x50;
- counts: 47 agent2, 15 agent3.

The alternate shape types (`FUN_008BFAA0`, which calls `FUN_008C4C20(type, base)`) collapse list, triangle
collection and extended mesh onto COLLECTION, MOPP onto BV_TREE, and the convex shapes onto CONVEX.

| Pair (shape types) | agent3 index | Process function (last slot) |
|---|---|---|
| LIST (10) vs LIST (10): boat body vs terrain cell | **9** (the live nn entry byte +1 = 9, P) | **`FUN_00927710`** (4843 B; "StNarrow", "StSortHitList", "StConvertHitlist"); collection-vs-collection hit lists; callees `FUN_00926900` (3597), `FUN_0090CF30` (3093), `FUN_009427D0` (944) |
| CONVEX_VERTICES (7) vs MOPP (11) | 3 | `FUN_009089A0` (357, "StNarrow"); queries the MOPP through the shape vtable 0xB6C588 (`0xA12xxx` slots) |
| CONVEX_VERTICES (7) vs TRIANGLE_COLLECTION (22) | 1 | `0x8D2150` (agent3 entry 1: functions `0x8D1FC0`–`0x8D20E0`) |
| CONVEX_VERTICES (7) vs TRIANGLE (4) | **10** | **`FUN_00901510`** (1350 B; create `0x901380`) |

- The agent-nn machine is `FUN_008C61A0` (5192 B, "StNarrowPhase"). Agent entry creation is `FUN_009090C0`.
- The GSK family is labelled "TtGsk"/"StGsk"/"LtGskAgent": `FUN_008B0B00`, `FUN_008CE300`, `FUN_008CE760`,
  `FUN_008CE990`, `FUN_008CEB30`, `FUN_008D0D00`.
- The class names for agent3 indices 9, 3, 1 and 10 (hkpCollectionCollectionAgent3, hkBvTreeAgent3, the agent3
  bridge, the predictive GSK agent3) are HK/I. The table entries and the process addresses are P.

**SecuROM inside the convex-vs-triangle agent — P.** `FUN_00901510` calls three split stubs, all listed in
`pc-v10.splices.tsv`:

| Stub | Prologue, then | Splice-table class |
|---|---|---|
| `FUN_00916360` | `jmp [0x244FC4C]` | terminal |
| `FUN_0091AAC0` | `jmp [0x244FAEC]` | terminal |
| `FUN_0092A270` | `jmp [0x244F78C]` | moved |

- In the capture, the slots hold the `.securom` VM stubs 0x024B96F0, 0x024B63A0 and 0x024B6340 (`slots.txt`).
- `mercs2_probe splice-emulate <exe> <site> --steps 20000` (`splice_emu.txt`) shows execution resuming in
  `.text` right after each jmp, at **0x91636C**, **0x91AACC** and **0x92A27D**. So the VM runs only a stolen
  prologue instruction, and **the real bodies are intact `.text` code**.
- **Ghidra has no function at those continuations, so their decomp is absent from the corpus.** The first body
  runs at least from 0x91636C to past 0x917A09, which is ≥ 5.8 KB.
- These bodies are the convex-vs-triangle manifold core (I: they are the only work `FUN_00901510` calls).
- **Until functions are created there (with `CreateMovedFunctions.java` or by hand) and re-exported, that core is
  undecoded.** It is readable by disassembly today.

### 4.3 Contact manager and constraint (P)

- `hkpSimpleConstraintContactMgr`, vtable 0xB589D4:
  - ctor `FUN_008D4640` (priority from the quality info);
  - addContactPoint `FUN_008D3DA0`;
  - property setup `FUN_008D47F0` (friction and restitution, §2);
  - other slots: `0x8D3A70`, `0x8D4180`, `0x8D42F0`, `0x8D3CA0`, `0x8D3B40`.
- The contact constraint is the reflected `hkpSimpleContactConstraintAtom` (type 22 = TYPE_CONTACT; members
  numContactPoints, maxNumContactPoints, info, … in `classes_sel.txt`).

### 4.4 Jacobian build and solve (P for the structure)

**Build:**
- `FUN_008FF4F0` (3249 B, "TtBuildJacTask") and `FUN_008FEEC0` (396 B, "StBuildJacobians") call **`FUN_00A1C940`**
  (16104 B / 1729 lines). That is the atom-to-Jacobian builder: a switch over `hkpConstraintAtom::AtomType`
  (cases 0x17–0x1B are the contact modifiers).
- Whenever the child atom is **0x16 TYPE_CONTACT**, it calls **`FUN_00A209B0`** (6201 B / 518 lines), the contact
  Jacobian builder. It reads the per-point hkUFloat8 values and has 3 sqrt calls. The call sites are lines
  1550/1617/1646/1700 of the decomp.
- `FUN_00A22xxx`–`FUN_00A24xxx` are the per-atom builders for joints. They are not needed for the boat.

**Solve:**
- `FUN_008FE9C0` / `FUN_008FEC40` ("StSolve", "StSolverExport") call **`FUN_00A2F840`** (27288 B / 2873 lines).
  It is a **schema interpreter**: a byte-opcode `switch` with cases 0–0x1C, run once in the iteration loop and
  once more in a second loop at 0xA3547E.
- Its leaf solvers are `FUN_00A269D0` (5482 B; a 3-row bilateral solve with tau/damp-scaled position error),
  `FUN_00A28F30` (3832 B) and `FUN_00A262F0` (1746 B).

**Integrate:**
- `FUN_008FE830` ("StIntegrateMotions") calls **`FUN_008EF520`** (11367 B / 1148 lines).
- The velocity clamps and deactivation are in `FUN_008EC5B0` (5931 B; **12 "unreachable block" warnings**, so
  partially garbled) and `FUN_008EBE80` (1839 B; 5 warnings).

### 4.5 Size of the minimal set (convex list vs static triangles with friction)

`minset.txt` lists 55 functions located by this run: drivers, nn machine, collection/bvtree/convex-triangle
agents, contact manager, Jacobian builder, solver, integrator, filter and the WpMeshShape16 and MOPP shape
slots. They total **≈ 121 KB of x86 and ≈ 14,700 decomp lines**.

Not included:
- the SecuROM-split narrowphase bodies (≥ 6–10 KB, no decomp yet);
- the MOPP query VM on PC (not located; reached by virtual call; the x360 entry is `TtrcMopp` 0x829B7C58);
- the welding utility (`FUN_00A09930` sets its globals; the code was not located);
- the two missing WpMeshShape16 slots.

Honest total: **≈ 130–150 KB, 16–18 k decomp lines** (I).
- Only some of the 27 KB solver is needed: the contact and friction schema cases. Which opcodes those are was
  not mapped this run.
- About 20–25 % of the set (the deferred-op queue, island and job plumbing) can be replaced by a
  single-threaded loop without changing the numbers. That is I, not checked against MT ordering effects.

---

## 5. The solver model and the two routes

### 5.1 What the code shows, in standard terms

- **Discrete PSI contact for this pair, no CCD** (§1.4) — P.
- **Contacts are generated by the convex-vs-triangle agent against MOPP-culled terrain triangles.**
  - Shapes: one convex hull of radius 0.05 against triangles of radius 0.01.
  - World collision tolerance 0.1; contact-point generation REJECT_MANY.
  - Edge snapping/welding thresholds 0.524 rad (30°).
  - P for the parameters; the algorithm (GSK = GJK on the convex-radius-expanded shapes, manifold cache) is HK.
- **The velocity solve is iterative and impulse-based, driven by a schema of Jacobians.**
  - 4 iterations per step (`solverIterations`), 1 microstep.
  - Gravity is applied in 4 increments of g·dt/4 (`globalAccelerationPerSubStep`).
  - Position error is fed back through **tau = 0.9 and damp = 1.1**, with integrateVelocityFactor = tau/damp =
    0.818. That is a Baumgarte-style stabilisation folded into the velocity solve.
  - Friction uses frictionTau = 0.45.
  - P for the numbers and the schema-interpreter structure. "Sequential impulses / projected Gauss–Seidel" as the
    name of the scheme is HK; the leaf `FUN_00A269D0` is consistent with it (I).
- **Contact material:** μ = sqrt(μA·μB) = 0.548, e = sqrt(eA·eB) quantised to 1/128, here 0 — P. The impulse
  seed is −0.2·v_rel·n·m_eff — P. allowedPenetrationDepth 0.1 on the boat — P; how the solver uses it is HK.
- **Body:** box-inertia motion with invInertia (1.43e-5, 1.41e-5, 1.94e-4) and invMass 1/8000; angular damping
  0.8, linear damping 0; velocity caps 136.2 m/s and 9.55 rad/s — P.

### 5.2 Route A: an off-the-shelf library (for example rapier3d) configured with these constants

**What it can reproduce exactly:**
- the shapes: the 127-vertex hull, radius 0.05 (rapier's round convex, or a hull dilated by 0.05);
- the mass properties and damping;
- the friction and restitution combine rules (custom combine: rapier lets you set a coefficient per pair);
- the filter matrix;
- no CCD;
- the substep and gravity split (dt ≤ 1/60 with N = 1..3);
- the iteration count.

**What it cannot reproduce by configuration:**
- Havok's Baumgarte tau/damp form. Rapier uses its own soft-constraint ERP/CFM; the closest match would be found
  by fitting, not derived.
- The manifold content:
  - GSK closest points with a 0.1 tolerance, against rapier's contact prediction distance;
  - REJECT_MANY point rejection;
  - welding at 0.524 rad;
  - the 4-point manifold reduction.
- Havok's restitution and impulse seeding.
- The solver ordering.

These differences decide how far a hull "climbs" a slope after a deep penetration in one step. They are exactly
the observable that is wrong today. **Rapier would be provably close only for resting and sliding contact; for
a fast ram it is not provable without a gate (I).**

### 5.3 Route B: port the recovered functions

**What it can reproduce:** the exact numbers, given the ≈ 130–150 KB set in §4.5.

**What blocks it today:**
- the SecuROM-split convex-vs-triangle core, which needs function creation and re-export;
- the PC MOPP query VM, not located (but the MOPP format and VM are already decoded on disk: memory
  `mopp-bytecode-format-decoded`, `mercs2_formats::mopp`);
- the welding code, not located;
- `FUN_008EC5B0` is partly garbled.

The MT job plumbing does not need porting: a single-threaded loop calling the same kernels is I-equivalent.

### 5.4 What can be gated, and which observables to pin

**Captures** (`game-files/memory-dumps/updated-chris-exports/`; MANIFEST.md lists them):
- `20261103_new-game-first-mission-start` (this one, boat afloat, **no contact points**: listener count +0x18 = 0,
  time without contact +0x10 = 1021.3);
- `20261021_chris-jacobs-flying-winch`;
- `…mid-mission`;
- `…clean-load-chris-jacobs-7-percent`;
- `…mattias-nilson-jacket-skin`.

Whether any of them holds a vehicle in contact with rock: NOT DETERMINED (not read this run). The method that
works on them offline is the same: read body → collisionEntries → agent entry → contact manager → constraint
atom → contact points.

**A gating capture needs:** the boat pressed against a rock (or beached), with `hkpSimpleConstraintContactMgr`
+0x10 count > 0. From that read the contact points (position, normal, distance), the friction and restitution
bytes, and the impulses applied.

**Observables a test can pin, each computable from the recovered data:**
1. Contacts against terrain come only from hull child 11 (layer 28). The detail hulls never touch terrain.
2. No ToI. The per-substep penetration at top speed (MaxSpeed 120 km/h ≈ 33.3 m/s × 1/60 ≈ 0.56 m) is resolved
   by the PSI solve. The recovery per step is bounded by tau/damp = 0.9/1.1 over 4 iterations.
3. Separation at rest = convex radius 0.05 + triangle radius 0.01 = **0.06 m** surface gap (HK, how the radii
   combine; P, the radii).
4. Tangential behaviour with μ = 0.548 and no bounce (e = 0).
5. Angular response limited by angular damping 0.8 and the 9.55 rad/s cap. Linear speed capped at 136.2 m/s.
6. The game side, §6: within 0.125 s after a contact the engine torque is multiplied by
   EngineTorqueMultiAtCollision. Steering is zero when aground. Collision stabilisation runs.

---

## 6. Game-side contact handling for this boat

- **The listener** (boat `drive_spec.md` §B.4, P there; reconfirmed here):
  - built by `0x446460` from the boat ctor `FUN_004465E0` at 0x446905, and registered with `FUN_008DD9E0` /
    `FUN_008DDDD0`;
  - vtables 0xBAA310 (collision listener) and 0xBAA324 (entity listener);
  - slot 0 `0x4464D0` increments, slot 2 `0x4464E0` decrements the contact count at +0x18;
  - the remaining slots are `0x848E30` (empty), `0x43D1B0` and `0x440B40`. Their roles were not read this run.
  - Captured listener `0x1F0811A0`: body at +0xC, +0x10 = 1021.3 (time without contact), +0x14 = 0, count 0.
  - The ctor sets body processContactCallbackDelay (+0x96) to 0, so contact callbacks run every step.
- **Use in the actor** (`drive_spec.md` lines 276, 313; `float_spec.md` §D.1–D.2):
  - collMul = EngineTorqueMultiAtCollision (+0xEC) when time without contact < 0.125 s (0xBA904C);
  - air steering only when the count is 0;
  - CollisionStabilization anti-roll (+0x118) gated on 0.2 s contact timers;
  - hull drag 0.25·a when in contact and the ground is above the water.
- **Crash or damage data:** the exe has the tunable names `PhysicsPropertyCrashable`, `CrashResistivity`,
  `MinMassForCrashing`, `UseLimitedCollision`, `DisableCollisionAtFallingSpeed` and `DisableImpact` (string
  offsets in `str_coll.txt`, e.g. `UseLimitedCollision` at VA 0xBC7CF8). No decomp references them (`grepfn.py`
  found none), so they are read through data descriptors. **The impulse-to-damage, crash-sound and climb/speed
  limit code is NOT DETERMINED.**
  - Next step: find the descriptor records holding those strings, then their consumers; or use
    `corpus_search` / `mercs2_probe we-template --class PhysicsPropertyCrashable`.
  - The Havok world has a `contactImpulseLimitBreachedListeners` array (world +0x180); its count was not read.

---

## 7. NOT DETERMINED (and what was tried)

1. Where PHY2 hulls 0–8 of model 0xB1EB099F are used. They are not in body 0x1EBB8000's list; no other body
   was searched.
2. Rock props near the boat and their shapes/materials. The capture's only partner is the terrain cell. Needs
   `dump-near` plus walking the broadphase, or a capture at a rock.
3. The Havok names of quality values 1/2/3 and of the quality-info fields. The behaviour is proven; the names
   are HK.
4. Decomp of the SecuROM-split convex-vs-triangle core at 0x91636C, 0x91AACC and 0x92A27C. Splice-emulated,
   not decompiled.
5. The PC MOPP query VM and the welding code addresses.
6. Which solver schema opcodes the contact and friction rows use inside `FUN_00A2F840`.
7. Whether the MT jobs run on more than one thread at runtime.
8. Game collision-damage, crash-sound and climb-limit code (§6).
9. The roles of boat listener slots `0x43D1B0` and `0x440B40`.
10. Whether any existing capture holds an in-contact vehicle manifold for gating.

The corpus index was stale at query time (28 files changed since ingest). No Ghidra bridge was started; all
decomp is from the export, with objdump for the rest.
