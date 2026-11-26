---
status: current
evidence: proven
---

# How pc-v10 builds a Havok rigid body from a model (PHY2 → hkpRigidBody)

Read of 2026-11-25; each claim carries its grade. The capture survey is kept as `b1/survey_notes.md`; the other `b1/`
files named below (listings, per-body tables) were working files and are not kept.

Scope: the PC exe `mercs2_unpacked.exe` (pc-v10; file offset = VA − 0x400000) plus two captures:

- **NG**: `20261103_new-game-first-mission-start.dmp`
- **WI**: `20261021_chris-jacobs-flying-winch.dmp`

Grades:

- **P** = PROVEN this run, with the instruction, function or script named.
- **I** = INFERRED.
- **S** = SPECULATIVE.
- **HK** = recalled Havok 5.5 knowledge, used only for names.

Working files are in `b1/` beside this file. Disassembly is in the `dis_*.txt` files (`objdump -d --x86-asm-syntax=intel`), Ghidra decomp in `fns/`. The capture survey is `b1/caps/` (summary `survey_notes.md`). The check scripts are `verify_cc.py`, `verify2.py` and `layer_slots.py`, with outputs `vcc_*.txt`, `v2_*.txt` and `ls_*.txt`.

## 0. Call chain (P unless marked)

```
owner->CreatePhysics  FUN_00430E90  (virtual, no direct caller; its address is stored at 0xBA9180, 0xBA9328, 0xBA9C18,
  |                                  0xBA9490, 0xBA9710, 0xBAA090, 0xBAA1C8 …, each just before an owner class's vtable;
  |                                  that it is a slot of each owner class's second vtable is I, from adjacency)
  |   args: [ebp+8] entity matrix, [ebp+0xC] -> LAYER RECORD (8 dwords), [ebp+0x10] quality, [ebp+0x14] float MASS,
  |         [ebp+0x1C] EXTRA shape (appended last to the first root's body), …
  |   copies the node-enable bitset from [[owner+0xB0]+0x30] (+0x10 = bit count, +0x14 words)   (0x430F8D–0x430FB7)
  +-> BuildBodies  FUN_0041B0D0  (sub esp,0x38; jmp [0x244FF04] = SecuROM terminal stub; real body .text 0x41B0D9–0x41B1CE)
  |     FUN_0041AF50  allocate the instance's system groups (§2.1)
  |     FUN_0041B040  merge test → req+0x31
  |     builds REQ on stack (§1.2) and calls
  +-> FUN_0041A670(X, matrix, req, extraShape)   (subsystem bits = owner vfunc +0x104, read at 0x41A68F–0x41A69A)
  |     req+0x31 != 0: one call for the whole model;  else: one call per ENABLED root node of X   (§1.1);
  |     extraShape is zeroed after the first call (0x41A7AE), so only the first body gets it
  +-> FUN_0041A7D0 (stub jmp [0x245873C]; at run time the slot holds 0x0246EF80 = moved body in .securom, NG capture)
  |     update-or-build: FUN_00430E30 (find an existing link for the node) → if one exists, re-filter it with FUN_0041ACD0
  |     (writes the list children and body+0x2C; code 0x246EFC9–0x246F09E); else `jmp 0x41A890` (0x246F0F9)  (I for the update branch)
  +-> FUN_0041A890(X, node, matrix, extraShape, subsystemBits)  EAX = req
        (forward at 0x246F0E1–0x246F0F9: param_4 = the stack arg, param_5 = ebp = the vfunc +0x104 value)
        shape  = FUN_00417DD0 (whole model) | FUN_00418000 (subtree) → FUN_00418200 list builder
        filter = FUN_0041ACD0 (children + body)
        body   = FUN_00418320 (cinfo) → hkpRigidBody ctor FUN_008D5570
        link   = FUN_00433B10 (0x68-byte link object, property 0x2001; owner vfunc +0xA8)
        initial velocities, FUN_008DC750 (I: removeReference)
  back in 0x430E90: on link[0]'s body (owner+0x4C/0x50): mass>0 → setMass FUN_008D4BF0 + inertia rescale FUN_00415EB0;
                    mass==0 → FUN_0041D490 (setMotionType(7,1,0) via 0x8D50D0)
```

- `FUN_00417DD0` is the real entry of what Ghidra calls `FUN_00417DDB`. Its first instructions are at 0x417DD0, then `jmp 0x56F216` → `jmp 0x417DDB`. P.
- The export has no caller for `FUN_0041A670`. Its one call site is `0x41B1AC` (jscan). P.

## 1. From PHY2 to the list shape

### 1.1 Runtime objects (offsets P from the code; values from NG)

**X = the per-model physics object.** It is shared by every instance of a model and reached from link+0x44; boat X = 0x1EBA32C0.

| Offset | Field |
|---|---|
| +0x00 | PHY2 body base (0x29665510) |
| +0x04 | u16[17] scratch system-group table |
| +0x28 | first root node |
| +0x2C / +0x30 | array / count of the root nodes: every wrapper node that has a mass record (boat: 6) |
| +0x3C | refcount (incremented per link) |

**Node = wrapper record, 68 B, framed 0xAAAAAAAA … 0xBBBBBBBB.** The wrapper is relocated in place at load.

| Offset | Field |
|---|---|
| +0x04 | local translation |
| +0x10 | local quaternion |
| +0x20 | node hash |
| +0x24 | K = HIER node index; the bit tested in the enable bitset |
| +0x28 | mass record CC (0xCCCCCCCC), or 0 |
| +0x2C | shape record EE (0xEEEEEEEE), or 0 |
| +0x34 | parent |
| +0x38 | first child |
| +0x3C | next sibling |

- K = HIER index is P: boat roots have K3 = 0x255EAB53, K5 = 0x75F1F74D and K6–K9 = 0x243A5276, 0x063C61D3, 0x2C3EDC3C, 0xA641DAE1. These equal the `mercs2_probe hier --model 0xB1EB099F` indices (`hier_boat.txt`).

**CC = mass record** (`rd3.txt`).

| Offset | Field |
|---|---|
| +0x04..+0x24 | full 3×3 inertia, row-major, off-diagonals present |
| +0x28 | centre of mass |
| +0x34 | mass |
| +0x38 | 0.3 (not read by these functions) |
| +0x3C | friction |
| +0x40 | 0.3 (not read) |
| +0x44 | angular damping |
| +0x48 | initial linear velocity |
| +0x54 | initial angular velocity |
| +0x60 | flags; bits 5–8 = system-group slot |

**EE = shape record, 108 B.**

| Offset | Field |
|---|---|
| +0x10 bit0 | pass flag (§1.3) |
| +0x14 | layer-selector flags (§2.2) |
| +0x30 | kind (3 = hull, 4 = MOPP mesh, 0 also seen) |
| +0x64 | hkpShape* (file: the WpArray index) |

### 1.2 REQ (stack struct built at 0x41B149–0x41B1A8)

Consumer offsets are P. The producer arg mapping is P for the offsets listed; the stack arithmetic is in the spec notes.

| Offset | Field |
|---|---|
| +0x00..+0x1F | copy of the 8-dword layer record (from CreatePhysics `[ebp+0xC]`) |
| +0x20 | owner (vfunc +0x104 gives the subsystem bits; +0xA8 adds a link) |
| +0x24 | quality (CreatePhysics `[ebp+0x10]`; 3 → 4 under a condition held in a stolen instruction, 0x41B0E6) |
| +0x28 | enable bitset |
| +0x2C | "stabilized" flag: CreatePhysics passes literal 0 here (0x430FE1 `push 0` = arg2) |
| +0x30 | two-pass flag: arg6, literal 0 from 0x430FD1 |
| +0x31 | merge flag = FUN_0041B040 |

`FUN_0041B040` returns 1 iff all of:
- owner+0x15 ≠ 0;
- every enabled root has CC mass ≠ 0;
- there are ≥ 2 enabled roots.

### 1.3 Shape tree → body shape, in exe order

- **FUN_0041A890** (when req+0x30 = 0, the only value CreatePhysics produces):
  - shape = FUN_00418000(node, I4, bitset, flag 0, extra, list 0), or, when req+0x31 is set, FUN_00417DD0(X, …).
  - extra = CreatePhysics `[ebp+0x1C]` (0x430FC2 → 0x41B168 → FUN_0041A670 arg 4 → param_4). Whether any class passes a non-null extra: NOT DETERMINED.
  - With req+0x30 set: a flag-1 pass builds the body shape and a flag-0 pass builds a second shape, which is stored at link+0x3C and not in the body. I.
- **FUN_00418000(node, parentM, bitset, flag, extra, list)** (0x418000–0x4181FD):
  1. A node with a CC, met while `list` ≠ 0 (any non-top node), returns 0. **A sub-node with its own mass record is not merged; it is a separate root/body.**
  2. Top call: allocate the list. M = identity, so the top node's own transform goes on the body (§3), not the children.
  3. Non-top call: M = local(node quat, translation) × parentM. The local comes from `FUN_0041BE30`, then `FUN_00835E80`, then D3DXMatrixMultiply.
  4. Recurse over the children (+0x38, then +0x3C). Children are appended before the node's own shape (post-order).
  5. If EE ≠ 0 and (EE+0x10 & 1) == flag: addref EE+0x64, then wrap it with `FUN_00417C60(&M, shape)`.
  6. The top call returns `FUN_00418200(flag)` with EAX = extra, ESI = list.
  - **The bitset is not tested here.** Only root nodes are gated by the bitset (FUN_0041A670 and FUN_00417DD0 test `bit[node+0x24]`).
- **FUN_00417DD0(X, M, bitset, flag, extra)**: for each root r in X+0x2C whose K bit is set, M_r = FUN_004177E0(r.parent) × M (SecuROM split, I: parent world matrix) × local(r). Then the same child recursion and own-shape step, then FUN_00418200.
- **FUN_00417C60** wrapper rule (0x417C60–0x417DCE). The identity test is exactly m00 == m11 == m22 == 1.0 and translation == 0; rotation off-diagonals are not tested.

  | Case | Result |
  |---|---|
  | Identity | the shape itself |
  | Convex shape (alternate-type bit 1 at `[[[0x117504C]+0x23C]+0x74]+0x110+4·type`), rotation not identity | hkpConvexTransformShape (0x60 B, `FUN_008CC480`) |
  | Convex shape, translation only | hkpConvexTranslateShape (0x30 B, `FUN_008CBAF0`) |
  | Not convex | hkpTransformShape (0x70 B, `FUN_008CD080`) |

  - The wrapper copies the child's userData (+0x08) and releases the extra child reference.
  - In the captures: 105 of 107 translate shapes carry their node's translation; no hkpTransformShape exists. P.
- **FUN_00418200** list builder (0x418200–0x418316):
  1. Append `extra` when it is non-null and (flag == 0 or count ≠ 0).
  2. count ≥ 2, or count == 1 with a child whose alternate-type bit 9 (BV_TREE: MOPP 11 → 9, `FUN_008BFAA0`) is set: allocate 0xA0 B, call `FUN_008CB4E0(children, n)` (hkpListShape ctor via `FUN_008CBE00(10)`), set vtables 0xBA8C44 / 0xBA8C6C and byte +0x70 = 0, then drop the builder's child references.
  3. Otherwise return the single child, or null.
  - In the captures: a single hull is a bare body shape (710 WI bodies) and a single MOPP is a 1-child list (terrain, statics). P.
- **List vtable slot 9 = `0x4176A0`** (0x4176A0–0x41771E). It is a game-side cached query:
  - if byte +0x70 == 0, it calls this->vfunc +0x1C into +0x80.. and sets +0x70 = 1;
  - it then copies +0x80..+0x90 out.
  - So +0x70 is a cache-valid flag (I: a cached AABB). Havok never calls it (I).

**Boat example (P, NG).**
- The roots are [K3 0x255EAB53, K5, K6, K7, K8, K9]. Only K3 is enabled.
- The list is K3's 13 leaf nodes in sibling order = WpArray 21 … 9 (survey `wraptree.txt`).
- **PHY2 hulls 0–8 are the break_piece subtrees K5–K9.** They become bodies only if their K bits are enabled; that is S for *when* (destruction state).

**Enable / disable** (P for the code path, I for when it runs).
- `enabledChildren` is never changed: all ones in 682 of 682 lists.
- Instead, `FUN_0041ACD0` gives a child whose node bit is clear **layer 24**, which collides only with layer 0.
- In WI the rule holds for 24 of 26 disabled children (boat 2/2, aircraft 22/22, static 0/1, prop 0/1; `v2_winch.txt`). The 2 exceptions are presumably bitset changes made after the build (I).

## 2. Collision filter info

### 2.1 System group (P)

`FUN_0041AF50`, ECX = X, EAX = owner:
1. If owner+0x16 ≠ 0, copy the owner's 17 u16 slots to X+4.
2. Otherwise mark slot 0, slot 1 and every slot (CC+0x60 >> 5) & 15 > 1 used by a root. Each marked slot gets `++u16 [[0x117504C]+0x39C]` (wraps at 0xFFFF → 1). Copy the result to owner+0x16.

Body and children get group = slot[(CC+0x60 >> 5) & 15], which is slot 0 in every capture. The check (group == owner+0x16[idx]) holds:

| Kind | Holds |
|---|---|
| NG, all | 84 / 84 |
| WI statics | 1677 / 1677 |
| WI props | 89 / 94 |
| WI boats, cars, aircraft, terrain | all |

- The exceptions are 5 props with group 0 and the rope, which carries the helicopter's group. Both are post-build changes; where they are made is NOT DETERMINED.
- Two groups per instance explains the odd group numbers and owner+0x18 = group+1.

### 2.2 Layer (P: `FUN_0041ACD0` 0x41ACD0–0x41AE78, layer selector `FUN_0041AE80` = moved body 0x247ECF1–0x247EDAF)

- filterInfo = (group << 16) | (subsystemBits << 5) | layer. The subsystem bits come from owner vfunc +0x104 and are 0 in every capture.
- A null shape gives (group << 16) | (sub << 5).
- A list (alternate bit 10), per child key: if the node bit is clear, layer 24; otherwise sel(node). Each child is written with `FUN_008C8860(key, fi)`.
- The **body** layer is the common child layer when all enabled children agree (24s ignored), else 0.
- With param_5 = 1 (the update path), children already off layer 24 are kept.
- A single shape: node bit clear gives 24; otherwise sel.
- When R+8 < 0, every enabled child (and a single shape) gets layer 0 and sel is not called (0x41AD9F, 0x41AE4F).
- **sel(node)**, with f = EE+0x14, kind = EE+0x30, R = req; any value −1 falls back to R+8:

```
f == 0          -> R+0x08
f & 0x10        -> 0
f & 0x40        -> kind==4 ? R+0x08 : [0x2460574] (=30 in both captures)
f & 0x08        -> kind==4 ? R+0x08 : R+0x18
f & 0x04        -> (f&2) ? ((f&0x20) ? R+0x08 : R+0x0C) : ((f&0x20) ? R+0x00 : R+0x04)
else            -> (f&2) ? ((f&0x20) ? R+0x10 : R+0x14) : 24
```

**Layer records per owner class, reconstructed from the captures** (`v2_*.txt` LAYERTAB; every observed (class, slot) pair maps to one layer, except statics +0x08 = 3 with 3 exceptions at 1, and props +0x08 = 18 or 13 per template):

| Owner (vtable) | +0x00 | +0x04 | +0x08 | +0x10 | +0x14 | +0x18 |
|---|---|---|---|---|---|---|
| boat 0xBA9200 | 29 | – | 8 | 28 | – | – |
| static/building 0xBA9368 | 4 | 7 | 3 (1) | 2 | 5 | 19 |
| dynamic prop 0xBA9C28 | 14 | – | 18 / 13 | 12 | – | – |
| car 0xBA94A0 | – | – | 8 | – | – | – |
| aircraft 0xBA9720 | – | – | 8 | – | – | – |
| terrain 0xBAA0A0 | – | – | 1 | – | – | – |
| rope/hook 0xBAA1D8 | – | – | 27 | – | – | – |

- The boat's hull flags are 0x25 (detail, slot +0, layer 29) and 0x23 (whole hull, slot +0x10, layer 28). The MOPP's are 0x25 with kind 4 (layer 29).
- Which code supplies each class's record (the CreatePhysics `[ebp+0xC]` argument): NOT DETERMINED.
  - Tried: static data scan. The exe's (29,4,22,7,28,1,−1,0) at 0x1286614 and 0x128674C has +8 = 22, which matches no class; it sits inside stride-0x138 shader objects (vtable 0xBAC150) and is a coincidence.
  - Tried: heap scan for 29@+0 & 28@+0x10 (`scan_req.txt`).
  - Not tried: the virtual call sites of the second-vtable slot.
- The EE+0x14 bit names are NOT DETERMINED (exporter flags).

**Layer matrix** (P, world filter 0x1FFFF700, hkpGroupFilter vt 0xB6CB7C; identical in NG and WI; built in `FUN_00413310`, whose pairs were not transcribed). The full matrix is `caps/layers_newgame.txt`. Rules:
1. A shared nonzero group never collides.
2. Differing nonzero subsystems never collide.
3. Otherwise `table[b] & (1<<a)` (README §1.5).

Selected rows:

| Layer | Collides with |
|---|---|
| 1 terrain | {0,2,3,5,6,8,9,12,13,15,16,18,20,21,23,25,26,27,28} |
| 24 disabled | {0} |
| 28 vehicle whole hull | {0–7,10,13,16,23,28} |
| 29 vehicle detail | {0,8,9,12,15,18,20,21,23,25,27} |
| 4 and 7 | {0,23,27,28} |
| 23 | everything except 24 |
| 30 / 31 | {0,23} |

Layer names beyond this use are NOT DETERMINED.

## 3. Body cinfo (`FUN_00418320`, 0x418320–0x418750; EAX = node, CC = node+0x28; no CC → no body)

**Cinfo layout and ctor mapping** (P: ctor `FUN_008D4AD0` defaults, `FUN_008D5570` copies; names HK):

| Offset | Field | Default | Body field |
|---|---|---|---|
| 0x00 | filterInfo | | +0x2C |
| 0x04 | shape | | |
| 0x08 | response (int8) | 1 | +0x80 |
| 0x0A | processContactCallbackDelay | 0xFFFF | +0x96 |
| 0x10 | position | | |
| 0x20 | rotation | | |
| 0x30 | linVel | | |
| 0x40 | angVel | | |
| 0x50 | inertia 3×4 | 0 | |
| 0x80 | com | | |
| 0x90 | mass | | |
| 0x94 | linDamp | 0 | +0x184 |
| 0x98 | angDamp | 0.05 | +0x188 |
| 0x9C | friction | 0.5 | +0x84 |
| 0xA0 | restitution | 0.4 | +0x88 |
| 0xA4 | maxLinVel | 200 | ufloat8 motion+0xBC |
| 0xA8 | maxAngVel | 200 | ufloat8 motion+0xBD |
| 0xAC | allowedPenetrationDepth | −1 | +0x58 |
| 0xB0 | motionType | 1 | |
| 0xB1 | deactivator type | 2 | `FUN_008D52D0` |
| 0xB2 | deactivation class | 2 | motion+0xBE; FIXED → 1 |
| 0xB3 | quality | 0 | +0x2A |
| 0xB4 | autoRemoveLevel | | +0xBC |
| 0xB5 | numUserDatasInCPP | | +0xBD |
| 0xB6 | forceCollideOntoPpu | | +0x21 \|= 1 |

**What the game writes** (P):

| Field | Value |
|---|---|
| position, rotation | from node local(+4, +0x10) × entity matrix: translation from the product, quaternion via `FUN_008231D0` |
| filterInfo, shape | from §2 / §1 |
| com | CC+0x28 |
| mass | CC+0x34 |
| angDamp | max(CC+0x44, 0.8) |
| friction | CC+0x3C |
| restitution | 0 |
| maxLin | 132.0 (0xBEB4C8) |
| maxAng | 3π (9.42478, 0xBEAC24) |
| penetration, linDamp | left at the defaults |
| mass > 0 | motionType = req+0x2C ? 5 : 1, quality = req+0x24 |
| mass ≤ 0 | motionType 7, quality 1 |
| param_1 == 0 (no shape) and mass > 0 | no body (0x418539) |

- Capture cross-check (`vcc_*.txt`):

  | Check | Holds |
  |---|---|
  | friction == CC+0x3C | NG all 84; WI statics 1677/1677, terrain 12/12, boats 2/2, aircraft 2/2, rope 1/1, props 11/94 (the other 83 are 1.0, a post-build setter), cars 0/3 (0.0, post-build) |
  | angDamp == max(CC+0x44, 0.8) | everywhere except the rope hook (0.99) |
  | fixed iff CC mass ≤ 0 | everywhere except WI prop 1e50e800: fixed with CC mass 1974.7, which fits CreatePhysics mass == 0 → `0x41D490` → setMotionType(7) (I) |

**Inertia** (P):
- If CC+4 ≠ FLT_MAX: take the CC tensor (transposed into cinfo; it is symmetric).
- Else: `FUN_0094BAF0(shape, mass, &mp)` (HK: hkpInertiaTensorComputer), then `FUN_0041BD20` copies mp+0x20.
- Then `FUN_00415B00` on cinfo+0x50, for rows R0, R1, R2 with norms L_i = |R_i.xyz| taken before any change:

```
R0: if L0/L1 < 1/15: R0 *= (1/15)/(L0/L1)  else if L0/L2 < 1/15: R0 *= (1/15)/(L0/L2);  R0 *= 16/15
R1: if L1/L0 < 1/15: R1 *= (1/15)/(L1/L0)  else if L1/L2 < 1/15: R1 *= (1/15)/(L1/L2);  R1 *= 16/15
R2: if L2/L0 < 1/15: R2 *= (1/15)/(L2/L0)  else if L2/L1 < 1/15: R2 *= (1/15)/(L2/L1);  R2 *= 16/15
```

- The scale covers all four floats; 1/15 = 0xB9C548 and 16/15 = 0xBEAEB8.
- Motion choice (`FUN_008D4E90`, jump table 0x8D5098):
  - type 1 = DYNAMIC: if min(Ixx,Iyy,Izz) > 0.8·max (double 0xB58B88; min = `0x8835E0`, max = `0x8835B0`), SPHERE (`FUN_008D5DF0`), else BOX (`FUN_008F6030`).
  - The rule holds on 104 of 104 dynamic bodies tested (NG 1, WI 103; `v2_*.txt`).
  - The box motion keeps only the diagonal. That is P by numbers: the off-diagonals of the boat CC are nonzero, yet invInertia = 0.9375/(diag·m/M) to 7 digits (survey §5). The box setInertia slot was not read.
  - The sphere motion stores all three axes = 0.9375 / max_i(I_ii·m/M). That is P by numbers on 16 bodies (survey §5); `0x8D5DF0` was not read.
- **Mass is then overridden** (0x431021–0x431066):
  - for owner link[0]'s body when it is non-fixed and the CreatePhysics mass m ≥ 0: m > 0 → setMass (`FUN_008D4BF0`; box setMassInv `0x8DF4A0` writes only +0xCC);
  - then `FUN_00415EB0`: inertia = CC tensor × (m/M_CC) → FUN_00415B00 → setInertiaLocal `FUN_008D4C50`;
  - m == 0 → `FUN_0041D490` → `0x8D50D0(7,1,0)`.
- **Result: invI_ii = 0.9375 / (CC_ii · m/M_CC)**, exact to 7 digits on 79 of 103 (survey §5). Boat: 60791.5 → 8000.
- **The 2–12 % gap to a hull-derived inertia is the authored CC tensor plus the 16/15 factor.** No 0.05 margin enters this path.
- The shape-computed path (CC+4 == FLT_MAX → `0x94BAF0`) is never taken by a dynamic body in either capture: P, `ccmax.txt`. The FLT_MAX sentinel appears only on massless records (NG 22 of 23 distinct body-linked records, WI 194 of 218); every massive record (NG 1, WI 24) carries a tensor.
- Cars (4500, 5500, 1250) and the hook are set by later code: `FUN_004436B0` (setInertiaLocal 0x443C36 + setMass 0x443C47), `FUN_00443FF0`, `FUN_00449CF0`. Values NOT DETERMINED.

**hkUFloat8 encoder** `FUN_0043D080`:
- Binary search over the 256-entry table 0xB13380, comparing the float bits as int32.
- Result = the first index i with T[i] ≥ x (ceiling).
- The first split, at T[128], is a stolen instruction (I).
- Checks: 132 → 136.2, 3π → 9.551, 200 → 202.8, matching the captures (P).

**Penetration depth** (cinfo −1, non-fixed), P:
- `FUN_008D4D10` gets the shape AABB (identity 0xBF65A0, tolerance 0): extents = max − min; objectRadius = ½|ext| + |centre − comLocal|.
- `FUN_008D4C90`: e = min(ext); pen = e < 0.5 ? 0.2·e (0xB58B80) : 0.1 (0xB11FD8).
- Fixed: FLT_MAX (0xBEAB40).
- Holds on 99 of 99 checked dynamic bodies, using the list/hull cached AABB (`v2_*.txt`).

**Body transform:** node local × entity matrix. The top node's own transform is applied to the body, not to the children. comLocal = CC com, except that the boat hull setup `0x446930` later moves it to the AABB centre + CenterOfMassOffset (boat `float_spec.md` §B).

**Per-kind post-build setters** (call sites P, purpose I):
- setFriction `0x8D4C30` from 0x4341C4 (`FUN_004340A0`, 1.0 — the props' friction 1.0 on layer 18, I), 0x446920 (boat HullFriction) and 0x44DC7C.
- setMass from 0x436FEF, 0x43DDEC, 0x4499BB, 0x5111ED.
- Props' maxLin 57.41, the rope's damping 0.99/0.3 and quality 4: the setter is NOT DETERMINED.

## 4. Fixed world bodies (terrain cells, statics)

- Terrain and statics go through `0x418320`. That is P by value signature: maxLin 136.2 = ceil-encode(132), angDamp clamped to 0.8 from CC 0.3, friction = CC+0x3C, group = owner+0x16 (`vcc_*`, `v2_*`).
- They are fixed, P: CC mass 0, so motion 7, quality 1, deactivation class 1, FLT_MAX penetration.
- Terrain: 1-child list (MOPP), layer 1, friction = CC+0x3C = 1.0 (P).
- One owner (model instance) gives one body per enabled root node with a CC. Buildings have up to 19 fixed bodies per owner in one group (P, survey). Statics are never merged into a shared body (P, census).
- The 124 shapeless fixed static bodies: FUN_0041A890 builds a body when there is a shape or CC mass ≤ 0 (0x41AA0A); FUN_00418320 with no shape and mass ≤ 0 makes one (P for the condition).
- Add to world: inside `FUN_00433B10` (owner vfunc +0xA8, VM thunks 0x24E9E60 / 0x24E60E0). The exact hkpWorld::addEntity site and the removal on stream-out are NOT DETERMINED.

## 5. Listeners and properties

- **Property 0x2001**, the only key on the boat: value = link object (0x68 B, ctor `FUN_0041C530`, vtables 0xBA8CB4 / 0xBA8CC4).

  | Link offset | Field |
  |---|---|
  | +0x34, +0x38 | body |
  | +0x3C | second-pass shape |
  | +0x44 | X |
  | +0x4C | node |

  The link is the body's activation listener and entity listener; the owner array is at +0x4C/+0x50 (P, survey + `rd1.txt`). `FUN_00415EB0` reads it through `FUN_00407BC0(…, 0x2001)` (P).
- Keys 0x2003 (20000.0), 0x2008 (0.02) and 0x2009 (7.0): writer NOT DETERMINED.
- **Boat contact listener** vt 0xBAA310: made by 0x446460 from boat ctor `FUN_004465E0`; it sets pccDelay to 0 (README §6). pccDelay = 0 exactly on bodies that have a collision listener; the default is 0xFFFF (P).

## 5b. Example bodies per kind (P; survey `bodies_*.tsv`, §6 of `caps/survey_notes.md`)

| Kind | Example | Root shape / children | Body fi / child layers | Friction / restitution | Motion, quality | Penetration | maxLin / maxAng | Damping lin / ang |
|---|---|---|---|---|---|---|---|---|
| boat (NG) | 1ebb8000 | Pg list, 13 (12 hulls + MOPP) | 0x00B70000 / 29, 28 | 0.3 / 0 | BOX, 3 | 0.1 | 136.2 / 9.551 | 0 / 0.8 |
| boat (WI) | 1df9d000 | Pg list, 5 | group only / 24, 29, 28, 8, 8 | 0.3 / 0 | BOX, 3 | 0.1 | 136.2 / 9.551 | 0 / 0.8 |
| terrain cell | 1ec16a00 (NG) | Pg list, 1 MOPP | 0x00050001 / 1 | 1.0 / 0 | FIXED, 1 | FLT_MAX | 136.2 / 9.551 | 0 / 0.8 |
| static, two-part | NG ×34 | Pg list, 2 (MOPP + hull) | layer 0 / 4, 5 | 0.3 / 0 | FIXED, 1 | FLT_MAX | 136.2 / 9.551 | 0 / 0.8 |
| static, single | WI ×710 | bare convex | layer 3 | 0.3 / 0 | FIXED, 1 | FLT_MAX | 136.2 / 9.551 | 0 / 0.8 |
| dynamic prop | 1d995600 (WI) | ConvexTranslate | layer 13 | 0.3 / 0 | BOX, 3, 20000 kg | per rule | 57.41 / 9.551 | 0 / 0.8 |
| dynamic prop | WI ×51 | convex | layer 18 | 1.0 / 0 | BOX, 3 | 0.1 or 0.2·min ext | 57.41 / 9.551 | 0 / 0.8 |
| car | 1e560000 (WI) | Pg list, 11 | layer 8 | 0 / 0 | BOX, 3, 4000 kg | 0.1 | 136.2 / 9.551 | 0 / 0.8 |
| aircraft | WI ×2 | Pg list, 26 | layer 8 / 8, 24 | 0.3 / 0 | BOX, 3, 8000 kg | 0.1 | 136.2 / 9.551 | 0 / 0.8 |
| rope segment | WI ×31 | capsule | layer 27 | 0 / 0.4 | SPHERE, 4, 5 kg | 0.012 | 202.8 / 202.8 | 0.3 / 0.3 |
| hook | 1d9b7200 (WI) | convex | layer 27 | 0.3 / 0 | 4, 320 kg | 0.0779 | 136.2 / 9.551 | 0.99 / 0.99 |

- **Human / ragdoll:** neither capture holds a character rigid body; no owner of a character-like class appears in the census (P). The construction path for characters and ragdolls is NOT DETERMINED.

## 6. Corrections to earlier claims

- README §1.3 "hulls 0–8 not used: NOT DETERMINED" → they are the break_piece subtrees K5–K9, not built while those bits are clear (P for the structure).
- Memory `static-mopp-mesh-collision-binding` (SEGM does not bind collision) is consistent: the binding is the wrapper node tree (P).
- Survey "mass comes from elsewhere" → CreatePhysics' float argument; "props ignore CC inertia" holds only for cars and hook (P).
- Ghidra `FUN_00417DDB` is mid-function; the entry is 0x417DD0.

## 7. NOT DETERMINED (with what was tried)

1. Who passes each class's layer record and quality: static scan done; virtual call sites not walked.
2. EE+0x14 bit names, and CC+0x38 / +0x40.
3. The setters for props' maxLin 57.41 and the rope's damping and quality 4; the cars' inertia values.
4. The addEntity and removal sites (VM thunks in `FUN_00433B10`).
5. The condition behind the 3→4 quality promotion (stolen instruction at 0x41B0D3).
6. The pair list in `FUN_00413310` (the matrix is proven from the capture).
7. When destruction flips the bitset and calls the update path.
8. The exact semantics of `FUN_004177E0` (SecuROM split) for non-root parents.
9. The human/ragdoll construction path (no character body in either capture).
10. Whether any class passes a non-null extra shape (CreatePhysics `[ebp+0x1C]`).
