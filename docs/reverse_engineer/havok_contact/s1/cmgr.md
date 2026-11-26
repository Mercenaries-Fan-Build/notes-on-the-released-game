# hkpSimpleConstraintContactMgr and contact-atom bookkeeping (pc-v10): exact transcription

Source: `mercs2_unpacked.exe` (pc-v10). Asm in `tx/cmgr/`:
- `d_8d3a70.txt`: 0x8D3A70–0x8D4A60 (manager methods)
- `d_8dce10.txt`: alloc
- `d_8dd3c0.txt`: data ctor, newId
- `d_8f51e0.txt`: grow and shrink
- `d_0x8F5040.txt`: atom create and copy
- `d_43d080.txt` and `d_43d11f.txt`: hkUFloat8 encoder
- `d_0x88CF20.txt`: hkArray grow
- `d_0x6AF380.txt`: constraint-info add and sub
- `d_0x8E0B80.txt`: atom fix-up
- `d_0x412710.txt` and `d_41277f.txt`: point velocity
- `d_0x8E4980.txt`: instance ctor and setPriority
- `d_0x6B0270.txt`: world remove

Emulations: `cmgr/emu_*.txt`. Captures: `cmgr/cap*.txt`, from the winch capture `20261021_chris-jacobs-flying-winch.dmp`.

Labels:
- **P**: read in asm this run (the address is given).
- **I**: inferred.
- **ND**: not determined.

Calling conventions are from the `ret n` and the caller's stack cleanup. thiscall means `ecx` = this.

Notation:
- `mgr`: the hkpSimpleConstraintContactMgr.
- `data = mgr+0x14`: the embedded hkpSimpleContactConstraintData.
- `atom = [mgr+0x3C]` (= `[data+0x28]`).
- `T(id) = idTable[id]` (u8), with `idTable = [mgr+0x20]` (= `[data+0xC]`).
- `n = atom.numContactPoints`.
- `R = atom.numReservedContactPoints` (capacity).
- `S = atom.contactPointPropertiesStriding`.
- Addresses: `cp[i] = atom + 0x30 + 32·i` and `props[i] = atom + 0x30 + 32·R + S·i`.
- Index arithmetic uses `movsx` of the 16-bit index and `movzx` of S. Indices are always ≤ 0xFF, so the arithmetic is plain.

**Copies of 32-byte contact points are x87 `fld dword`/`fstp dword` pairs, not integer moves.** This applies in addContactPoint, processContact, shiftDown and atom copy. A port copying bits is exact for every finite value, ±inf, denormal and quiet NaN. A **signalling NaN would come out quieted (bit 22 set)** (I, Intel SDM `fld m32` behaviour). Properties are always copied with integer `mov`/`rep movsd` (exact).

---

## 1. Object layouts (as written by the code in this file)

### 1.1 Manager (0x80 bytes)

Allocated by the factory (§6.3), so its memory is **not zeroed**. The capture shows allocator garbage in unwritten bytes, e.g. mgr 0x1C8ACF00 +0x30..+0x37 = `6b 70 69 6c 65 5f 6d 69`.

| Off | Size | Field | Writer (P) |
|---|---|---|---|
| +0x00 | 4 | vtable 0xB589D4 | ctor 0x8D4666; dtor 0x8D46E6, then 0xB11B68 at 0x8D472A |
| +0x04 | u16 | memSize 0x80 | factory 0x8D4774 |
| +0x06 | u16 | refcount 1 | ctor 0x8D4659 |
| +0x08 | 4 | 0 | ctor 0x8D465F |
| +0x0C | 4 | world | ctor 0x8D469D |
| +0x10 | u16 | reservedContactPoints | ctor 0 (0x8D468B); reserve (§2.1) |
| +0x12 | u16 | skipProcessCallbacks | ctor 0 (0x8D4687); add (§2.2) 0x8D3FAF; process (§2.6) 0x8D4406 |
| +0x14 | 0x30 | **data**: hkpSimpleContactConstraintData | data ctor (§6.2) |
| +0x14 | 4 | data.vtable 0xB58998 | 0x8DD3D4 |
| +0x18 | u16 | data.memSize = 0 | mgr ctor 0x8D468F (after the data ctor) |
| +0x1A | u16 | data.refcount 1 | 0x8DD3CE |
| +0x1C | 4 | data+0x08 = 0 | 0x8DD3DC |
| +0x20 | 4 | idMgr data pointer (initially &mgr+0x2C) | 0x8DD3E2; hkArray grow 0x88CFAF |
| +0x24 | 4 | idMgr size = 0 | 0x8DD3E9; newId 0x8DD49E |
| +0x28 | 4 | idMgr capacity\|flags = 0x80000008 | 0x8DD3EC; grow 0x88CFB1 |
| +0x2C | 8 | idMgr **inline buffer** (8 × u8) | never initialised; written by newId while inline |
| +0x34 | 4 | data+0x20: **never written** by any function here | — (capture: garbage) |
| +0x38 | 4 | data+0x24 = constraint = &mgr+0x44 | 0x8DD3F3 |
| +0x3C | 4 | data+0x28 = atom | 0x8DD423; alloc 0x8DCE36; remove 0x8D4104 |
| +0x40 | 4 | data+0x2C = u32(atom.sizeOfAllAtoms) | 0x8DD450; alloc 0x8DCF0F (only if the atom moved); remove 0x8D415E (only if moved) |
| +0x44 | 0x2C | hkpConstraintInstance | instance ctor `FUN_008E4980` (§6.1) |
| +0x44 | 4 | instance.vtable 0xB5971C | 0x8E498E |
| +0x48 | u16 | instance.memSize = 0 | mgr ctor 0x8D4693 |
| +0x4A | u16 | instance.refcount 1 | 0x8E4988 |
| +0x4C | 4 | instance.owner (island) = 0 | 0x8E4994 |
| +0x50 | 4 | instance.data = &mgr+0x14 | mgr ctor 0x8D4697 |
| +0x54 | 4 | instance.modifiers = 0 | 0x8E4997 |
| +0x58 | 4 | instance.entities[0] = A | 0x8D4684 |
| +0x5C | 4 | instance.entities[1] = B | 0x8D469A |
| +0x60 | u8 | instance.priority | 0x8E499A, then 0x8E49B4 (§6.1) |
| +0x61 | u8 | instance+0x1D = 0 | 0x8E499D |
| +0x62 | 2 | never written | — (boat capture `23 45`) |
| +0x64 / +0x68 / +0x6C | 4 each | instance+0x20 / +0x24 / **+0x28 internal** = 0 | 0x8E49A0 / A3 / A6 |
| +0x70..+0x7F | — | never written by the ctor chain | — |

Instance field names (owner, data, modifiers, entities, priority, internal) are the HK 5.5 layout. The offsets are P; the names are I.

### 1.2 Atom (hkpSimpleContactConstraintAtom)

Created by `FUN_008F5040` (§5.1). The heap block is not zeroed; only the fields listed are written.

| Off | Size | Field | Create value (0x8F5040) |
|---|---|---|---|
| +0x00 | u16 | type | 0x16 (0x8F50C1) |
| +0x02 | u16 | sizeOfAllAtoms | `((S+0x20)·cap + 0x3F) & ~0xF` (0x8F505F–0x8F5069, 0x8F5094) |
| +0x04 | u16 | numContactPoints | 0 (0x8F50C6) |
| +0x06 | u16 | numReservedContactPoints | cap (0x8F508C) |
| +0x08 / +0x09 | u8 | numUserDatasForBodyA / B | udA / udB (0x8F5084 / 0x8F509D) |
| +0x0A | u8 | stride S = `4·(udA+udB) + 0x14` (low byte) | 0x8F5098 |
| +0x0B | u8 | never written | — (capture 0x1E) |
| +0x0C | u16 | maxNumContactPoints | arg (0x8F5090) |
| +0x0E | u16 | never written | — |
| +0x10 | u16 | info.flags | 0 (0x8F50A0) |
| +0x12 | u16 | info.index | 3 (0x8F50A4) |
| +0x14..+0x2C | 7 × u32 | info.data[0..6] | 0 (0x8F50AB–0x8F50BD) |
| +0x30.. | — | cp[0..cap), then props[0..cap) | not initialised at create |

### 1.3 Properties record (stride S)

| Off | Field |
|---|---|
| +0x00 | impulse (f32) |
| +0x04 | solverData (f32) |
| +0x08 | u32 written 0 by add |
| +0x0C | friction (hkUFloat8 index) |
| +0x0D | restitution (u8) |
| +0x0E | maxImpulse (u8) |
| +0x0F | flags |
| +0x10 | dataA (f32) |
| +0x14.. | user datas (u32 each) |

**The whole record is zeroed when a point is allocated (§5.2).**

### 1.4 Entity fields read here

All P (read here):

| Off | Field |
|---|---|
| +0x2A | u16 quality type (I: hkpTypedBroadPhaseHandle.objectQualityType of the collidable at +0x10) |
| +0x84 | friction f32 |
| +0x88 | restitution f32 |
| +0x96 | u16 processContactCallbackDelay |
| +0xBD | u8 numUserDatasInContactPointProperties |
| +0x130/+0x134/+0x138 | centre of mass (read by 0x412710) |
| +0x19C | invMass f32 (I: w of the motion's inertiaAndMassInv at +0x190) |
| +0x1A0..+0x1AC | linear velocity (xyz, w) |
| +0x1B0..+0x1B8 | angular velocity |
| +0x1F4 | u16 contact-listener count (I: size of the small array whose pointer is at +0x1F0) |

Collidable: `entity(cd) = cd + s8[cd+0x10]`; `cd.parent = [cd+0xC]`; `cd.shapeKey = [cd+4]` (P for the offsets).

Winch capture values (P, `cmgr/cap_ent.txt`):
- +0x80 (the material responseType byte) = 1 in all four entities read.
- Friction +0x84: 0.3 (0x1D995600, 0x1DF9D000), 1.0 (0x1E45C800), 0.0 (0x1E560000).
- Restitution +0x88 = 0 in all four.

---

## 2. Manager methods (vtable 0xB589D4)

### 2.1 reserveContactPoints `0x8D3A70` (thiscall; arg `[esp+4]` = int k; `ret 4`) → eax

```
0x8D3A70-8D3A8C  t = i32(atom.n) + k + i32(mgr.reserved(+0x10, u16))
                 if t > i32(atom.maxNum(+0xC)) - 2   (signed: jle 0x8D3A90 skips the fail)
                     return 1
0x8D3A9A-8D3AA3  mgr.reserved(+0x10, u16) = u16( u8( u8(mgr.reserved) + u8(k) ) )   // 8-bit add, high byte becomes 0
                 return 0
```

Writes: only `[mgr+0x10]` u16. P.

### 2.2 addContactPoint `0x8D3DA0`

Signature: thiscall, ebp frame with `and esp,-16`; `ret 0x18`.

Arguments:

| Slot | Argument |
|---|---|
| ebp+8 | cdA |
| ebp+0xC | cdB |
| ebp+0x10 | input |
| ebp+0x14 | output (owner = `[output+4]`) |
| ebp+0x18 | gskCache |
| ebp+0x1C | cp (32-byte point) |

Locals (L = esp after `sub esp,0x84; push ebx,esi,edi`):

| Local | Holds |
|---|---|
| L+0x10 | props* |
| L+0x14 | X, later reused as f32 scratch |
| L+0x18 | id (u32) |
| L+0x1C | cpDst*, later projVel (f32) |
| L+0x20..+0x28 | d |
| L+0x30..+0x3C | vX (16 B) |
| L+0x40..+0x4C | vY |
| L+0x5C..+0x8F | event |

Registers: edi = mgr, esi = cp, ebx = Y.

```
0x8D3DB1-8D3DC7  if i32(mgr.reserved) + i32(atom.n) > i32(atom.maxNum) - 2  (signed jg)  -> return 0xFFFF   (0x8D3F96: `or ax,0xffff`; upper eax undefined)
0x8D3DCD-8D3DE0  if atom.n == 0:  owner->vtbl[+0x0C](&mgr+0x44)               // thiscall ecx=owner; add constraint to the island
0x8D3DE2-8D3DF6  id = allocateContactPoint(data, owner, &cpDst, &props)          // 0x8DCE10, §3.1 (args pushed: &L+0x10, &L+0x1C, owner)
0x8D3E00-8D3E06  L+0x18 = u32(u16 id)
0x8D3DFE-8D3E37  cpDst[0..7] = cp[0..7]   (x87 fld/fstp dword ×8, in order +0x00 .. +0x1C)
0x8D3E3A-8D3E4B  X = setupProperties(cdA, cdB, 10000, props)                      // 0x8D47F0, §4.1 (thiscall mgr; ret 0x10)
0x8D3E50-8D3E62  Y = [mgr+0x5C] ^ [mgr+0x58] ^ X;   L+0x14 = X
0x8D3E56-8D3E64  X->pointVelocity(&cp->pos, &vX=L+0x30)                           // 0x412710 thiscall ecx=X, args (cp, out); §7
0x8D3E69-8D3E71  Y->pointVelocity(&cp->pos, &vY=L+0x40)
0x8D3E76-8D3E89  d.x = f32(vX.x - vY.x)           // fld [L+0x30]; fsub [L+0x40]; fstp [L+0x20]
0x8D3E95-8D3E9D  d.y = f32(vX.y - vY.y)           // [L+0x34]-[L+0x44] -> [L+0x24]
0x8D3EA1-8D3EA9  d.z = f32(vX.z - vY.z)           // [L+0x38]-[L+0x48] -> [L+0x28]
0x8D3EAD-8D3EC6  projVel = f32( ((cp.n.y*d.y) + (cp.n.x*d.x)) + (cp.n.z*d.z) )   // n at [cp+0x10/+0x14/+0x18] of the INPUT cp; products and sums on the x87 (53-bit); one f32 rounding at 0x8D3EC6 -> L+0x1C
0x8D3ECA-8D3ECC  props.impulse(+0x00) = +0.0      // fldz; fstp
0x8D3ED2-8D3ED4  props(+0x08) = 0 (u32)
     event (base E = L+0x5C), written 0x8D3E85-0x8D3F2E:
       E+0x00 = cdA        (0x8D3E85)        E+0x04 = cdB      (0x8D3EDA)
       E+0x08 = 1 (type)   (0x8D3E8D)        E+0x0C  NOT WRITTEN (ND; I: m_callbackFiredFrom, filled per listener)
       E+0x10 = cp (input pointer) (0x8D3F23)  E+0x14 = gskCache (0x8D3EF4)
       E+0x18 = props      (0x8D3EED)        E+0x1C = projVel f32 (0x8D3EE9, f32->f32 exact)
       E+0x20 = 0 status   (0x8D3EFB)        E+0x24 = mgr      (0x8D3F27)
       E+0x28 = input      (0x8D3F15)        E+0x2C = output   (0x8D3F0B)
       E+0x30 = u16 id     (0x8D3F2E)        E+0x32 = u16 delay = 0 (0x8D3EFF)
0x8D3F21-8D3F36  FUN_008EA570(world=[mgr+0xC], &E)                                // world listeners first
0x8D3F3B-8D3F52  if u16 X[+0x1F4] != 0:  FUN_008F4D80(X, &E)                      // then X = entity of cdA (from setupProperties)
0x8D3F5E-8D3F6E  if u16 Y[+0x1F4] != 0:  FUN_008F4D80(Y, &E)                      // then Y
0x8D3F7A-8D3F94  if u32 E.status == 1:  mgr->vtbl[+0x14](id, owner)  (= removeContactPoint, §2.4);  return 0xFFFF
0x8D3FA3-8D3FAF  mgr.skipProcessCallbacks(+0x12) = E.delay (u16, as listeners left it)
0x8D3FB3-8D3FC5  e = f32( f64(i32 props.restitution(+0x0D, u8)) * qword[0xB58938] )   // 0x3F80000000000000 = 2^-7 = 0.0078125; exact
0x8D3FC9-8D3FD8  fld e; fldz; fucom st(1) (0.0 vs e); fnstsw; fstp st(1) (stack keeps the 0.0); test ah,0x44; jp 0x8D403F
                 -> jp taken when (C3,C2) = (0,0) "≠" or (1,1) "unordered"; falls through only when e == 0.0
0x8D3FDA-8D3FE2  if u16 X[+0x1F4] > 0 (ja) -> 0x8D403F
0x8D3FE4-8D3FEC  if u16 Y[+0x1F4] > 0 (ja) -> 0x8D403F
  seed (no-listener, e == 0):
0x8D3FEE-8D3FFF  s = f32( Y.invMass[+0x19C] + X.invMass[+0x19C] )                 // fld Y; fadd X
0x8D4003-8D4011  k = f32( 1.0 / ( f64(s) + qword[0xB58960] ) )                    // 0x3DDB7CDFE0000000 = 1.000000013351432e-10; bytes `de f1` FDIVRP st(1): st1 = st0/st1 = 1/(s+c)
0x8D4015-8D4023  props.impulse(+0x00) = f32( (f64(k) * qword[0xB58958]) * f64(projVel) )   // 0xBFC99999A0000000 = -0.20000000298023224; two x87 roundings, then f32
0x8D4025-8D4029  props.solverData(+0x04) = +0.0                                   // the fldz left on the stack
0x8D402C-8D4033  props.dataA(+0x10) = cp.distance([cp+0x1C])                      // fld/fstp of the INPUT cp
                 return id (ax, from L+0x18 at 0x8D3FF4)
  callback request (else):
0x8D403F-8D4052  fstp st(0); owner->vtbl[+0x14]([mgr+0x38] = &mgr+0x44, 1)        // thiscall ecx=owner
0x8D4054         return id
```

Notes (P unless marked):
- `reserved` is not consumed by add.
- X is the entity whose collidable is cdA, as setupProperties returns it (§4.1). Y is "the other" one, by XOR of the instance's A and B.
- The seed path leaves props flags bit0 (new) set forever: the deferred pass is not requested. The capture agrees. Mgr 0x1C8AA800 has listener-free bodies (both `+0x1F4 = 0`) and restitution 0, and all three of its points still carry flags 1/3/1. Mgr 0x1C8ACF00 has a listener on B (`0x1E560000+0x1F4 = 1`), and its points carry flags 0/2/0/2 (`cmgr/cap_atoms.txt`).

### 2.3 Accessors

**getContactPoint `0x8D4260`** (thiscall; `[esp+4]` = u16 id; `ret 4`). P:
- Returns `atom + 0x30 + 32·T(id)`.
- There is **no 0xFF check**: a freed id gives `cp[255]`.

**getContactPointProperties `0x8D4280`** (thiscall; `ret 4`). P:
- Returns 0 when `T(id) == 0xFF` (0x8D428C).
- Otherwise returns `atom + 0x30 + 32·R + S·T(id)` (0x8D4299–0x8D42AF).

**getAllContactPointIds `0x8D42E0` → `0x8D49F0`** (this = idMgr = mgr+0x20; arg = hkArray<u16>*). P:
- `for i = 0 .. size-1 ascending: if T(i) != 0xFF: out.push(u16 i)`.
- When `size == cap & 0x3FFFFFFF` it grows first through `0x88CF20(out, 2)`.

### 2.4 removeContactPoint `0x8D4180`

Signature: thiscall; `[esp+4]` = u16 id, `[esp+8]` = owner; `ret 8`. Returns void: eax is whatever the last call left, and callers ignore it.

```
0x8D4180-8D41BF  idx = T(id); p = (idx == 0xFF) ? 0 : props[idx]   (computed on the current atom)
     event (base E = L+0x10, L = esp after sub 0x1c + 4 pushes), 0x8D41C3-0x8D41EA:
       E+0x00 u16 = id      E+0x04 = p      E+0x08 = A = [mgr+0x58]      E+0x0C = B = [mgr+0x5C]
       E+0x10 NOT WRITTEN (ND; I: callbackFiredFrom)                     E+0x14 = mgr      E+0x18 = owner
0x8D41D9-8D41EE  FUN_008EA6D0(world, &E)                                 // world first
0x8D41F6-8D4206  if u16 A[+0x1F4] != 0: FUN_008F4EE0(A, &E)            // then A, then B (instance order, not cd order)
0x8D420E-8D421E  if u16 B[+0x1F4] != 0: FUN_008F4EE0(B, &E)
0x8D4226-8D4232  remaining = data.removePoint(owner, id)                 // 0x8D4070 (§3.2), thiscall ecx = mgr+0x14
0x8D4237-8D4246  if remaining == 0: owner->vtbl[+0x10](&mgr+0x44)       // the constraint leaves the island
```

### 2.5 addToi `0x8D3CA0` and removeToi `0x8D3B40`

Read only as far as the shared bookkeeping goes. P:
- addToi calls `setupProperties(cdA?, cdB?, 7, props)` at 0x8D3CBC, with maxNum 7 (it clamps the user-data count, §4.1).
- removeToi builds a removed event with id 0xFFFF.

Both are not on the PSI path.

### 2.6 processContact `0x8D42F0`

Signature: thiscall. With L = esp after `sub 0x420` and 4 pushes:

| Slot | Argument |
|---|---|
| L+0x434 | cdA |
| L+0x438 | cdB |
| L+0x43C | input (not read) |
| L+0x440 | output |

`ret 0x10`. Returns void (eax not meaningful).

```
0x8D42F9-8D430E  c = mgr.skip(+0x12, u16)
                 if c != 0:  mgr.skip = u16(c - 1)   (0x8D4406)           -> no callbacks
                 else:
0x8D4322-8D4354      eA = cdA + s8[cdA+0x10];  eB = cdB + s8[cdB+0x10]      // NO parent walk (unlike setupProperties)
                     delay = (u16 eA[+0x96] < u16 eB[+0x96]) ? eA[+0x96] : eB[+0x96]   // `cmp ax,cx; jb` = unsigned min
     event (base E = L+0x1C):
       E+0x00 = cdA, E+0x04 = cdB, E+0x08 NOT WRITTEN (ND), E+0x0C = output,
       E+0x10 + 4·j = props* (NOT cp*) of output entry j, or 0 if T(entry.id) == 0xFF   (0x8D4376-0x8D43B7; props address as in §2.3)
       E+0x410 = mgr  (0x8D4369)
0x8D43B9-8D43C2      FUN_008EA780(world, &E)
0x8D43CE-8D43DE      if u16 eA[+0x1F4] != 0: FUN_008F4F90(eA, &E)
0x8D43EA-8D43FA      if u16 eB[+0x1F4] != 0: FUN_008F4F90(eB, &E)
0x8D4402-8D4406      mgr.skip(+0x12) = delay       // the value computed before the callbacks; the event has no delay field
   copy (always, both branches), 0x8D440A-0x8D45B4:
     output layout: [output+0] = end pointer; entries from output+0x10, 0x30 bytes each: {hkContactPoint 32 B, u32 id at +0x20}
     for each entry e in order:  cp[ T(u32 e.id) ] = e.point       // x87 fld/fstp ×8; no 0xFF check; duplicate ids: last wins
```

The copy loop is unrolled by 4: count = `(end-start+0x2F)/0x30`; 4-wide while `esi < end-0x90` (signed `jl`), then 1-wide while `esi < end` (unsigned `jb`). That is equivalent to a plain in-order loop for user-space pointers (I). Properties are not touched by processContact (P).

Capture (P, `cmgr/cap.txt`):
- Mgr 0x1C8AA800 has skip = 0xFFB1, and both its entities have `+0x96 = 0xFFFF` (`cap_ent.txt`). I: 78 decrements since the last fire.
- Mgr 0x1C8ACF00 has skip = 0, and its B has `+0x96 = 0`.

---

## 3. Constraint-data level (this = data = mgr+0x14)

### 3.1 allocateContactPoint `0x8DCE10`

Signature: thiscall. Arguments: `[esp+4]` = owner, `[esp+8]` = &cpOut, `[esp+0xC]` = &propsOut. `ret 0xC`. Returns eax = id from newId.

```
0x8DCE17-8DCE1A  atom.info.flags(+0x10, u16) |= 4
0x8DCE21         n = atom.n   (before);  old = atom   (saved at L+0x10)
0x8DCE28-8DCE36  atom = grow(atom)        // 0x8F51E0 cdecl (§5.2); data.atom(+0x28 = mgr+0x3C) = atom (always written)
                                          // grow sets atom.n = n+1 and zeroes all S bytes of props[n]
0x8DCE34-8DCE63  cpP = cp[n];  pr = props[n];  pr.impulse(+0) = +0.0 (fst); pr.solverData(+4) = +0.0 (fstp)
0x8DCE68         pr.flags(+0xF) = 1
0x8DCE66-8DCE79  if n > 0 (signed) and (props[n-1].flags & 2) == 0 and props[n-1].maxImpulse(+0xE) == 0:  pr.flags = 3
                 // props[n-1] is addressed as pr - S
0x8DCE7D-8DCE87  *cpOut = cpP;  *propsOut = pr
  solver-memory accounting (info on the stack at L+0x14..+0x20):
0x8DCE89-8DCEA3  m = n+1:  info.maxSizeOfSchema = 0x70·(m>>1) + 0x30·(m&1) + 0xA0
0x8DCEA7-8DCED3  info.sizeOfSchemas      = (n == 1 ? 0x20 : 0) + ((m&1) ? 0x30 : 0x40)
                 info.numSolverResults   = (n == 1 ? 1 : 0) + 1
                 info.numSolverElemTemps = (n == 1 ? 1 : 0) + 1
0x8DCED7-8DCEE8  owner->addConstraintInfo(constraint = data+0x24 value, &info)    // 0x6AF380 thiscall ecx=owner (§3.4); acts only if constraint.internal != 0
0x8DCEED-8DCF0F  if atom != old:  FUN_008E0B80(constraint, old, atom, atom.sizeOfAllAtoms)  (§3.5);  data+0x2C = u32 atom.sizeOfAllAtoms
0x8DCF12-8DCF16  return idMgr.newId(n)    // 0x8DD460 thiscall ecx = data+0xC, arg = point index n
```

Points pair as (0,1), (2,3), …. A point after a maxImpulse point, or after an already-paired point, starts a new pair (P).

### 3.2 removePoint `0x8D4070`

Signature: thiscall on data. `[esp+4]` = owner, `[esp+8]` = u16 id. `ret 8`. Returns eax.

```
0x8D4073-8D408A  idx = T(id) (u8, zero-extended);  T(id) = 0xFF
0x8D4087-8D40A5  a0 = atom;  n = a0.n (before);  saved a0 in the id arg slot
0x8D4094-8D40C9  dSchemas = (n == 2 ? 0x20 : 0) + ((n & 1) ? 0x30 : 0x40)
                 dResults = (n == 2 ? 1 : 0) + 1;   dTemps = (n == 2 ? 1 : 0) + 1
0x8D40CD-8D40CF  shiftDown(a0, idx)                              // 0x8D4930 cdecl (§3.3)
0x8D40D4-8D40E7  a0.props[idx].flags(+0xF) &= 0xFD               // on the OLD atom, R and S of a0; also when idx == n-1 (that slot is now past the end)
0x8D40F0-8D4104  atom = shrink(a0, 1); data.atom = atom          // 0x8F5280 cdecl (§5.3)
0x8D4100-8D4107  idMgr.decrementAbove(idx)                       // 0x8D47C0 (§3.6)
0x8D410C-8D4135  if constraint.internal([data+0x24]+0x28) != 0:  // inline subtract, no max update
                    owner+0x0C -= dSchemas;  owner+0x10 -= dResults;  owner+0x14 -= dTemps      (u32)
                    internal+0x16 -= dResults; internal+0x18 -= dTemps; internal+0x14 -= dSchemas (u16)
0x8D4139-8D415E  if atom != a0:  FUN_008E0B80(constraint, a0, atom, atom.sizeOfAllAtoms);  data+0x2C = u32 atom.sizeOfAllAtoms
0x8D4161         atom.info.flags(+0x10) |= 5                     // on the current (possibly new) atom
0x8D4166-8D416D  return n - 1
```

### 3.3 shiftDown `0x8D4930` (cdecl `(atom, idx)`)

```
0x8D4939-8D4965  atom.n = n-1  (u16, written first)
0x8D4963-8D4975  if idx >= n-1 (signed): return
0x8D4977-8D49E6  for i = idx .. n-2:
                    cp[i]    = cp[i+1]        (x87 fld/fstp ×8)
                    props[i] = props[i+1]     (S>>2 dwords, integer mov; skipped if S>>2 <= 0)
```

The slot n-1 keeps stale contents (P).

### 3.4 owner->addConstraintInfo `0x6AF380` and its inverse `0x6AF400`

Both thiscall, ecx = owner (island); `ret 8`. Arguments: (constraint, &info). info = {max, schemas, results, temps}. Both are no-ops if `constraint+0x28` (internal) == 0. P.

```
0x6AF392-6AF3A8  owner+0x08 = max( max(owner+0x08, info.max), info.schemas )     (signed compares)
0x6AF3AB-6AF3BA  owner+0x0C += info.schemas; owner+0x10 += info.results; owner+0x14 += info.temps
0x6AF3BD-6AF3DA  internal+0x18 = u16(internal+0x18 + info.temps); internal+0x16 += u16 info.results; internal+0x14 = u16(internal+0x14 + info.schemas)
0x6AF3DE-6AF3F0  owner+0x08 = max(owner+0x08, u16 internal+0x14)
```

The inverse 0x6AF400 subtracts the same fields and leaves owner+0x08 alone. 0x8D4070 inlines that subtraction.

Names: owner+8..+0x14 = hkpConstraintInfo {maxSizeOfSchema, sizeOfSchemas, numSolverResults, numSolverElemTemps}; internal +0x14/+0x16/+0x18 the per-constraint copies (I, HK 5.5).

### 3.5 FUN_008E0B80 (cdecl `(constraint, oldAtom, newAtom, u16 size)`): atom-pointer fix-up

```
0x8E0B85-8E0BA4  if constraint+0x10 (modifiers) == 0:
                    if internal: internal+0x0C = newAtom; internal+0x10 = u16 size
0x8E0BA5-8E0BC4  elif modifiers == oldAtom:
                    constraint+0x10 = newAtom; if internal: internal+0x0C = newAtom, internal+0x10 = size
0x8E0BC6-8E0BE5  else: walk m = modifiers; while [m+0x14] != oldAtom: m = [m+0x14];  [m+0x14] = newAtom; u16 [m+0x12] = size
```

P. The contact constraints in the captures have modifiers = 0.

### 3.6 decrementAbove `0x8D47C0` (thiscall ecx = idMgr; arg = idx; `ret 4`)

```
for i = size-1 down to 0:  if T(i) != 0xFF and i32(T(i)) > idx (signed jle skip):  T(i) -= 1
```

P (0x8D47C1–0x8D47E9).

### 3.7 newId `0x8DD460`: the id allocator (thiscall ecx = idMgr = data+0xC = mgr+0x20; arg = point index k; `ret 4`)

```
0x8DD463-8DD479  for j = size-1 down to 0:            // highest free id first
                     if T(j) == 0xFF:  T(j) = u8 k;  return j          (0x8DD4AC; table size unchanged)
0x8DD47B-8DD48F  if size == (capFlags & 0x3FFFFFFF):  hkArrayGrow(idMgr, 1)   // 0x88CF20 cdecl (arr, elemSize)
0x8DD492-8DD4A8  T(size) = u8 k;  size += 1;  return size-1
```

The table **never shrinks**. Its size equals the peak number of simultaneously live ids. An append happens only when no entry is 0xFF, which means all `size` ids are live (P, from the loop).

**hkArrayGrow `0x88CF20(arr, elemSize)`** (P):
- newCap = (size != 0) ? 2·size : 1. Called only when size == cap, so in practice newCap = 2·cap.
- Allocates newCap·elemSize bytes (tag 0x17).
- Copies size·elemSize bytes (0x9EE832).
- Frees the old block only if capFlags ≥ 0 (bit31 DONT_DEALLOCATE clear).
- data = new; capFlags = (old & 0x40000000) | newCap.

From the inline state 0x80000008: cap 8 → 0x10 (bit31 dropped) → 0x20 → …. **The inline buffer at mgr+0x2C is left as it was at the moment of growth**: grow copies out of it and nothing writes it again.

---

## 4. Properties setup and the hkUFloat8 encoder

### 4.1 setupProperties `0x8D47F0`

Signature: thiscall mgr. Arguments (after `push ecx` + 4 pushes):

| Slot | Argument |
|---|---|
| esp+0x18 | cdA |
| esp+0x1C | cdB |
| esp+0x20 | maxNum (10000 from add, 7 from addToi) |
| esp+0x24 | props |

`ret 0x10`. Registers: ebx = B = `[mgr+0x5C]`, ebp = A = `[mgr+0x58]`, esi = mgr.

```
0x8D47FC-8D480D  t  = f32( B.friction[+0x84] * A.friction[+0x84] )          // fld B; fmul A; fstp; fld
0x8D4811-8D4816  mu = f32( _CIsqrt(f64 t) )                                    // 0x9EE730 = thunk to MSVCR80!_CIsqrt (corpus ghidra/pc-v10/0x009ee730); x87 st0 in/out
0x8D481A-8D4826  (fld/fstp of mu: f32 -> f32, exact)
0x8D4822-8D482E  encodeUFloat8(this = &props.friction(+0x0C), &mu)             // 0x43D080 thiscall, §4.2
0x8D4833-8D4843  t2 = f32( B.restitution[+0x88] * A.restitution[+0x88] )       // stored in the props ARG slot [esp+0x24]; edi keeps props
0x8D4847-8D484C  r  = f32( _CIsqrt(f64 t2) )
0x8D4850-8D485A  r128 = f32( f64(r) * qword[0xBEB7B8] )                         // 0x4060000000000000 = 128.0 (exact scaling)
0x8D485E-8D486A  props.restitution(+0x0D) = low byte of fistp_i32(r128)          // rounding by the current FPU RC (I: round-to-nearest-even, not read here)
0x8D4871         props.maxImpulse(+0x0E) = 0
0x8D486D-8D4887  root = cdA; while root.parent(+0xC) != 0: root = root.parent
0x8D4889-8D489D  E = root + s8[root+0x10];  udA = atom.udA(+8);  udB = atom.udB(+9)
0x8D48A7, 8D4923 if udA + udB == 0: return E
0x8D48A9-8D48BF  if E == A: (cA, cB) = (cdA, cdB); ret = E
                 else:      (cA, cB) = (cdB, cdA); ret = B      // [esp+0x24] = ebx
0x8D48C3-8D48D3  nA = min(udA, maxNum)  (signed: `cmp eax,ebp; jl`);  nB = min(udB, maxNum - nA)
0x8D48D7-8D48F4  i = 0; c = cA; while c != 0 and i < nA:  props[+0x14 + 4·i] = c.shapeKey([c+4]); c = c.parent; i++
0x8D48F6-8D4915  j = 0; c = cB; while c != 0 and j < nB:  props[+0x14 + 4·nA + 4·j] = c.shapeKey; c = c.parent; j++
0x8D4917         return ret
```

- **The user datas are the shapeKeys of the leaf collidable and its parents, leaf first: body A's chain, then body B's (P).**
- numUserDatasForBodyA/B come from the atom (+8/+9). The atom took them from entity A/B `+0xBD` at construction (§6.2).
- Slots past the available chain length keep the zero from the allocation (§5.2).
- Sqrt: `_CIsqrt` (MSVCR80) could not be read (DLL not in the tree). I: it is `fsqrt` at the current 53-bit precision, plus the CRT's domain checks. Then `f32(sqrt53(t))` equals the correctly rounded f32 sqrt: double rounding of sqrt through 53 bits is innocuous for a 24-bit target.

### 4.2 encodeUFloat8 `0x43D080`

Signature: thiscall, ecx = destination byte; `[esp+4]` = &f32; `ret 4`. Compares the **f32 bit pattern as a signed i32** (`jle`) against the table T = 0xB13380 (u32[257] pointers; T[256] is never read).

```
0x43D089         x = i32 bits(*arg)
0x43D08B         jmp [0x245511C]  — SecuROM splice. Emulated this run (mercs2_probe splice-emulate, cmgr/emu_43d08b_*.txt):
                 the only access is `read [0x00B13580] 4B at 0x0050CCBD`; the gadget at 0x50CCBD is `cmp edi,[ecx]; pop ecx; jmp 0x43D091`
                 (s1/dis_50ccbd.txt). So the stolen instruction is cmp x, T[128] — matches the spec.
0x43D091-43D0A4  if x <= T[128] (signed): lo=&T[0], hi=&T[128]  else lo=&T[128], hi=&T[256]
0x43D0A9-43D11F  6×: mid = (hi>>1)+(lo>>1) (pointer halves = element midpoint); if x > T[mid] (signed): lo = mid else hi = mid
0x43D121-43D12E  mid = (hi>>1)+(lo>>1); if x > T[mid]: mid += 1
0x43D131-43D13A  *dest = u8( (mid - &T[0]) / 4 )        // index 256 wraps to byte 0
```

Emulated results (P, this run):

| Input bits | Value | Byte |
|---|---|---|
| 0x3F0C378C | f32 sqrt(f32 0.3) | **0x26 = 38** |
| 0x00000000 | 0.0 | 1 |
| 0xBF800000 | −1.0 | 1 |
| 0x52000000 | 1.37e11 > T[255] | **0** (wrap) |

Table values (P, `cmgr/tbl.txt`): T[0] = 0.0, T[1] = 0.01, T[2] = 0.02, T[3] = 0.03, T[128] = 216.8, T[255] = 0x49742420 = 1000002.0.

---

## 5. Atom storage functions

### 5.1 create `0x8F5040` (cdecl `(cap, udA, udB, maxNum)`) → atom

P (0x8F5040–0x8F50CB):
- `S = 4·(udA+udB) + 0x14`
- `size = ((S+0x20)·cap + 0x3F) & ~0xF`
- Allocates `size` bytes (thread allocator from TLS `[0xDFE750]`, `0x88CB70(size, 4)`).
- Writes the fields in §1.2.

### 5.2 grow `0x8F51E0` (cdecl `(atom)`) → atom

```
0x8F51E6-8F51F5  n = atom.n;  if n < R: in place (ecx = atom)
                 else:
0x8F51F7-8F520D     newCap = 2·max(n, 2);  if newCap >= maxNum: newCap = maxNum
0x8F520F-8F521B     new = create(newCap, udA, udB, maxNum)
0x8F5222-8F5224     copy(new, atom)                       // 0x8F50D0, §5.4
0x8F5229-8F5242     free(atom, size = atom.sizeOfAllAtoms, tag 4)   // 0x88CBD0
0x8F5249-8F5250  atom'.n = n + 1
0x8F5254-8F5277  zero S>>2 dwords at atom'.props[n]       // rep stosd; ALL of the new point's properties are 0
                 return atom'
```

So capacity runs 1 → 4 → 8 → 16 → … → maxNum. The cp record is not cleared.

### 5.3 shrink `0x8F5280` (cdecl `(atom, k)`) → atom

```
0x8F5285-8F5295  if 2·(atom.n + k) > R: return atom          (signed jg)
0x8F5297-8F52D1  new = create(R >> 1, udA, udB, maxNum); copy(new, atom); free(atom, atom.sizeOfAllAtoms, 4); return new
```

With k = 1 after shiftDown: capacity halves when `2·(n'+1) <= R`.

### 5.4 copy `0x8F50D0` (cdecl `(dst, src)`)

P:
- `dst[+0x10..+0x2F] = src[...]`: 8 dwords, `rep movsd`; the info block is exact.
- `dst.n = src.n`.
- For i < src.n: `dst.cp[i] = src.cp[i]` (x87 ×8) and `dst.props[i] = src.props[i]` (S>>2 dwords integer).

---

## 6. Construction

### 6.1 Instance ctor `0x8E4980` (thiscall; arg = u8 priority; `ret 4`) and setPriority `0x8E49B0`

- Ctor writes: +6 = 1, +0 = 0xB5971C, +8 = 0, +0x10 = 0, +0x1C = priority byte, +0x1D = 0, +0x20/+0x24/+0x28 = 0 (P).
- setPriority: +0x1C = al; if internal(+0x28) != 0: internal+0x13 = al (P).

### 6.2 Data ctor `0x8DD3C0` (thiscall this = data; args (constraint, entA, entB); `ret 0xC`)

```
0x8DD3CE-8DD3F3  data+6=1; data+0=0xB58998; data+8=0; data+0xC=&data+0x18; data+0x10=0; data+0x14=0x80000008; data+0x24=constraint
0x8DD3F6-8DD416  udB = u8 entB[+0xBD]; udA = u8 entA[+0xBD];  S = 4·(udA+udB)+0x14;  maxNum = u16( 0x1400 / S )   (signed idiv)
0x8DD419-8DD423  atom = create(cap = 1, udA, udB, maxNum);  data+0x28 = atom
0x8DD426-8DD442  atom+0x10 = 0 (u16); atom+0x12 = 3 (u16); atom+0x14..+0x2C = 0     (repeats create's writes)
0x8DD445-8DD450  data+0x2C = u32 atom.sizeOfAllAtoms
```

Results:
- **Initial atom:** type 0x16, numReserved 1, n 0, flags 0, index 3, data 0.
- **maxNumContactPoints = 5120 / S**. That is 256 for S = 0x14 (no user datas), which is where the captured 256 comes from.
- sizeOfAllAtoms = `(0x34 + 0x3F) & ~0xF = 0x70` for S = 0x14.

### 6.3 Manager ctor `0x8D4640` (thiscall; args (world, entA, entB); `ret 0xC`) and factory `0x8D4740`

```
0x8D464E-8D466C  mgr+6=1; mgr+8=0; mgr+0=0xB589D4;  dataCtor(mgr+0x14; &mgr+0x44, entA, entB)
0x8D4671-8D4675  instanceCtor(&mgr+0x44, priority = 1)
0x8D467A-8D469D  +0x58 = entA; +0x12 = 0; +0x10 = 0; +0x18 = 0; +0x48 = 0; +0x50 = &mgr+0x14; +0x5C = entB; +0x0C = world
0x8D46A0-8D46C6  disp = [world+0x74];  q = s8 [disp + 0x1BB0 + 10·u16 entA[+0x2A] + u16 entB[+0x2A]]
                 setPriority(&mgr+0x44, u16 [disp + 0x1C58 + 0x40·q])        // stored as a byte
                 return mgr
```

Factory `0x8D4740` (thiscall this = factory; args (cdA, cdB, third arg not read); `ret 0xC`). P:
- eA = cdA + s8[cdA+0x10], eB = cdB + s8[cdB+0x10].
- Allocates 0x80 bytes (`0x88CB70(0x80, 0x22)`); mgr+4 = 0x80.
- Calls `ctor(world = [factory+8], eA, eB)`.
- **It reads nothing else.** No responseType (entity+0x80) and no material are read here. What selects this factory for a pair is ND: it is outside these functions (I: the dispatcher's agent/response tables).

### 6.4 Manager dtor `0x8D46E0`: as far as island membership goes

Signature: thiscall, no args, plain `ret`. Returns void.

```
0x8D46E3-8D4702  vtable = 0xB589D4; if atom.n != 0:  FUN_006B0270(world, &mgr+0x44, 1)
0x8D4705-8D472A  +0x58 = 0; +0x5C = 0; +0x50 = 0; instanceDtor(&mgr+0x44) (0x8E49F0); dataDtor(mgr+0x14) (0x8D4A40); vtable = 0xB11B68
```

`FUN_006B0270`, P up to the splice:
- `island = instance.owner(+8)`; `island+0x25 = (island+0x25 & 0xFD) | 1`.
- Then `jmp [0x244FD9C]` at 0x6B0289 (SecuROM). Emulation (`cmgr/emu_6b0289.txt`) shows the stolen code reads `[world+0x84]` and continues at 0x6B02B8: `world+0x84 = 1`, optional `FUN_008EA4C0` when the fire flag is set and `world+0x118 != 0`, then `FUN_008E0BF0(instance)`.

`FUN_008E0BF0` (asm 0x8E0BF0–0x8E0C3C):
- Sets the same island+0x25 bits.
- If internal != 0, subtracts internal's u16 (+0x14 schemas, +0x16 results, +0x18 temps) from island +0xC/+0x10/+0x14 and from internal itself.
- `island+0x1C -= 1`.
- Then a second splice `jmp [0x244FB6C]` at 0x8E0C3C. In emulation it writes `instance.owner = 0` (eip 0x4B6586) and returns into 0x8E0C43. There it swap-removes the constraint from the master entity's constraint list (`entity+0xA0` pointer / `+0xA4` count, slot index `internal+0x22`).

From 0x8E0C3C onward the transcription is **I** (emulated with sentinel memory, not traced against real state). The rest of 0x6B0270 (from 0x6B02E5) is not transcribed.

---

## 7. Point velocity `0x412710` (thiscall ecx = entity; args (pos*, out*); `ret 8`): SSE, plain f32

```
r = (p.x - e[0x130], p.y - e[0x134], p.z - e[0x138])               // each subss
w = (e[0x1B0], e[0x1B4], e[0x1B8]);  v = (e[0x1A0], e[0x1A4], e[0x1A8])
out.x = v.x + (w.y·r.z - w.z·r.y)
out.y = v.y + (w.z·r.x - w.x·r.z)
out.z = v.z + (w.x·r.y - w.y·r.x)
out.w = e[0x1AC]                                                    // x87 fld/fstp copy at 0x4127CF
```

Each `mulss`/`subss`/`addss` is rounded to f32 (0x412716–0x4127CA). addContactPoint calls it for X then Y with `pos = cp` (the input point's +0/+4/+8). The outputs go to L+0x30 and L+0x40.

---

## 8. Id-allocator check against the winch capture (`cmgr/cap.txt`, `cmgr/cap_atoms.txt`)

The transcription (§3.2, §3.6, §3.7, §5.2, §5.3) produces each captured state. P for the captured bytes; the sequences are I (one producing sequence each, plus the conditions every sequence must meet).

### 8.1 Mgr 0x1C8ACF00

Captured state:
- Inline table at +0x2C = `01 00 02 03`, size 4, capFlags 0x80000008. Inline bytes 4..7 are allocator garbage, never written.
- Atom 0x1E663000: n 4, R 4, flags 1.
- Props flags 0, 2, 0, 2.

Required:
- At least one removal. Without one, newId only appends, so T(i) = i.
- id1's point must precede id0's.

Sequence:

| Step | Table | R |
|---|---|---|
| add (id 0) | [0] | 1 |
| add (id 1) | [0, 1] | grows to 4 |
| remove id 0 | [FF, 0]; flags of the slid point &= ~2 | shrinks to 2, since 2·(1+1) ≤ 4 |
| add, n = 1 (highest free id is 0) | [1, 0] | in place, 1 < 2 |
| add, n = 2 | [1, 0, 2] | grows to 4 |
| add, n = 3 | [1, 0, 2, 3] | 4 |

Result: R = 4 ✓, flags |= 5 from the remove (bit0 ✓), pair flags 1/3/1/3 ✓. Bit0 is later cleared by the deferred pass, which runs because B has a listener; the captured 0/2/0/2 matches.

### 8.2 Mgr 0x1C8AA800

Captured state:
- Heap table 0x1CB097E0: size 20, capFlags 0x20, T = FF×17, then 17→2, 18→1, 19→0.
- The stale inline buffer at +0x2C holds `00 01 02 03 04 05 06 07`.
- Atom 0x1EA55B00: n 3, R 4.
- Props flags 1, 3, 1.

Required:
- **Peak of exactly 20 simultaneous points.** Size 20 needs 20 appends, and each append happens only when all ids are live.
- At the 9th append the table was exactly [0..7]: the stale inline copy shows it.
- The survivors in atom order are id19, id18, id17. Each was handed out as the highest free id when it was added, so id19 was added first.

Simplest sequence:

| Step | Table | Capacity |
|---|---|---|
| 20 adds in order | T(i) = i | 8 → 16 → 32; R 1→4→8→16→32 |
| remove all 20 (the constraint leaves the island at 0) | all FF | R shrinks back to 1 |
| add (gets id 19, idx 0) | | |
| add (id 18, idx 1) | | R → 4 |
| add (id 17, idx 2) | | |

Result: R = 4 ✓, flags 1/3/1 ✓. Bit0 stays set because both bodies are listener-free with restitution 0, so the seed path runs (§2.2). Reaching 0 is not strictly required. Any order works that frees ids 17–19 and every lower-indexed survivor, with 19, 18, 17 re-allocated in that order.

### 8.3 Boat mgr 0x1C8A6C80

Captured state:
- Table `00`, size 1, inline.
- Atom 0x1C8A6200: n 1, R 1, flags 5.

Required:
- **Never more than 1 live point** (size 1).

Sequence: one add. Flags bit0 = 1 suggests at least one add/remove cycle before it, since remove does `|= 5` and alloc does `|= 4`. I: no other bit0 writer is in these functions. The sequence is then add, remove, add.

The props hold dataA = 0xB4000000 = −FLT_EPSILON and friction byte 38.

Observation for the S1 owner: the boat atom has info.flags bit2 set (5) even though its constraint is in the island (internal 0x1CBE9E30). The other two atoms have bit2 clear. Either the §6.6 clear is conditional, or no Jacobian build has run since the boat's last alloc/remove. Not checked.

---

## 9. Corrections to the spec (contact_solve.md)

1. **§2.2 note ("props.dataA keeps the allocator's value … reused memory") is wrong.** grow `0x8F51E0` zeroes all S bytes of the new point's properties (rep stosd at 0x8F5266–0x8F5277). This happens on both the in-place and the reallocated path. dataA, the user datas, friction, restitution and maxImpulse are 0 before setupProperties and the callbacks.
2. §2.3 "numContactPoints becomes n+1 (I …)" is now P: 0x8F5250. Also:
   - Capacity policy: `min(2·max(n,2), maxNum)`.
   - alloc also posts solver memory to the owner through `0x6AF380` (§3.1), which §2.3 omits.
   - alloc fixes the atom pointers through `0x8E0B80` when the atom moved, also omitted.
3. §2.4 is missing several steps:
   - The owner/internal solver-memory subtraction (0x8D410C–0x8D4135).
   - The atom-pointer fix-up and the `mgr+0x40` update.
   - The shrink rule `2·(n'+1) ≤ R → R/2`.
   - The pair-bit clear runs on the **old** atom before shrink, and also when the removed point was the last.
   - Removed-event listener order is world, then instance A, then instance B (not cd order).
4. §2.5: the process event carries **properties pointers** (256 slots at event+0x10), not point pointers (0x8D438C–0x8D43A2). Also:
   - The entities come from `cd + s8[cd+0x10]` with no parent walk.
   - The cp copy does not check 0xFF.
5. §2.2: the callback request passes the **value** at `mgr+0x38` (= &mgr+0x44, the instance), not mgr+0x38 (0x8D4049). The event field at +0x0C is never written (ND).
6. §2.6: restitution is at entity **+0x88**.
   - The return value is `entity(root of cdA)` when there are no user datas. Otherwise it is A when that entity is A, else **B**.
   - The user datas are the collidable-chain **shapeKeys** (`[cd+4]`), leaf first, A's chain then B's, clamped by the maxNum argument (10000 or 7).
   - The encoder wraps to **byte 0** for x > T[255] (emulated).
7. §1.4 / §1.1: maxNumContactPoints = `u16(0x1400 / S)` (data ctor 0x8DD40E), which is 256 for S = 0x14. The initial numReserved is 1, and the initial info.index is 3.
   - `mgr+0x34` and `mgr+0x62` are never written.
   - Clarification, not an error: the priority's exact address is `u16[disp+0x1C58+0x40·q]` with `q = s8[disp+0x1BB0+10·qA+qB]`, where qA and qB are u16 at entity+0x2A of A and B. This equals the spec's "qualityInfo[q] +0x58" if the info array starts at disp+0x1C00. The spec's field offset (+0x58) is larger than the 0x40 stride, so its naming is unclear. Use the exact formula.

## 10. ND list

- Event field E+0x0C in addContactPoint, E+0x10 in removeContactPoint, and E+0x08 in processContact. The manager never writes them. I: filled by the listener-dispatch helpers 0x8F4D80 / 0x8F4EE0 / 0x8EA*, which were not read.
- The bodies of the listener-dispatch functions 0x8EA570, 0x8EA6D0, 0x8EA780, 0x8F4D80, 0x8F4EE0 and 0x8F4F90, and whether any listener changes `E.delay` or `E.status`. Not read.
- The internals of `_CIsqrt` (MSVCR80, not in the tree), and the FPU control word (RC) in force at the restitution `fistp`.
- What chooses factory 0x8D4740 for a pair.
- Owner vtable +0x0C / +0x10 / +0x14 bodies. Not read here.
- The dtor path after the SecuROM splices at 0x6B0289 and 0x8E0C3C: emulated with sentinels only (I).
