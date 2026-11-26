# Boat flotation port spec — pc-v10 (`_BoatPhysics` actor, vtable 0xBA9340)

Image: `game-files/canonical/dumps/mercs2_unpacked.exe`, sha256
`8c179a99d7fad88bab288826db19a579b53512801d8e0d1c1a761bbc30ebc7ba` (re-hashed this run, `sha.txt`).
Disassembler: `/usr/bin/objdump` (LLVM), Intel syntax, VA addressing (`--start-address`). Data read with
`xxd`/`od -t f4` at file offset = VA − 0x400000. Ghidra export used only as a guide; every formula below
was confirmed in the disassembly unless graded otherwise.

Grades: **P** = PROVEN (instructions/bytes read this run), **I** = INFERRED, **S** = SPECULATIVE,
**ND** = NOT DETERMINED.

Listings kept in this directory (all relied on):
`d_446930.txt` (hull setup), `d_446bd0.txt` (pre-step), `d_447260.txt` (applyAction + 0x447300),
`d_447650.txt` (patch sampler), `d_4477a0.txt` (springs), `d_448210.txt` (drag/gravity/righting),
`d_4465e0.txt` (record→actor copy), `d_435660.txt` (actor alloc/ctor), `d_6584a0.txt` (field loader),
`d_480440.txt` + `d_48044c.txt` + `d_24b9e30.txt` + `d_4803a0.txt` (water query + SecuROM island + sibling),
`d_481710.txt` (watermap bilinear), `d_714d90.txt` (smoother), `d_8df470.txt` (getMass),
`d_motion_8df3c0.txt`, `d_motion_8f6350.txt` (Havok motion vtable bodies), `vt_boxmotion.txt`,
`vt_spheremotion.txt`, `d_4464d0.txt` (contact listener), `vt_listener.txt`, `vt_boat.txt`,
`d_405d00.txt`, `d_944ab0.txt`, `g_944ab0.txt`, `d_88a860.txt`, `d_8231d0.txt`, `g_misc.txt`
(Ghidra decomps of 405d00/4423a0/446460/481710/8231d0/825370/8d4c30/944920), `d_447350_thrust.txt`,
`d_447f00_steer.txt` (only for the state offsets they write), constants `consts.txt`, `consts2.txt`,
`defs.txt`, `sintable.txt`, `c_bf65a0.txt`, `c_beab40.txt`, `c_beab60.txt`, strings `str_bc7c00.txt`.

Notation: `actor` = boat action object (ECX/ESI in the functions), `body` = `[actor+0x18]`
(hkpRigidBody), `motion` = `body+0xD0`. Body fields used (P, read as offsets; Havok names I):
`body+0xE0/0xF0/0x100` = rotation columns col0/col1/col2 (local X/Y/Z axes in world), `body+0x110` =
origin position, `body+0x130` = centre of mass in world, `body+0x150` = rotation quaternion,
`body+0x19C` = inverse mass, `body+0x1A0` = linear velocity v, `body+0x1B0` = angular velocity ω (world),
`body+0x10` = shape pointer, `body+0x84` = material friction.

All constants used (data VA: bytes → value), P (`consts.txt`, `consts2.txt`):
| VA | bytes | value | use |
|---|---|---|---|
| 0xB977F8 | 17 b7 d1 38 | 1e-4 | epsilons |
| 0xB9B664 | 00 00 80 3f | 1.0 | |
| 0xBA8734 | 66 66 66 40 | 3.6 | m/s → km/h |
| 0xBEAAE8 | 00 00 c8 c2 | −100.0 | spring "no water" height sentinel |
| 0xBBC7EC | 00 00 80 3e | 0.25 | ¼ average; grounded drag; righting dt |
| 0xBEAA78 | 56 55 85 41 | 16.6667 | smoother big-dt guard |
| 0xBCD278 | 89 88 88 3c | 1/60 | smoother sub-step |
| 0xBEAA70 | ff ff 6f 42 | 60.0 | smoother fraction |
| 0xB92B3C | ac c5 27 37 | 1e-5 | smoother convergence factor |
| 0xBEAA74 | 72 f9 7f 3f | 0.9999 | smoother big-dt k test |
| 0xBEB440 | 3b 76 c6 2e | 9.025e-11 | (0.95·1e-5)² inlined threshold |
| 0xBEAE30 | d0 cc 4c 3d | 0.05 | inlined in-water gain (1−k, k=0.95) |
| 0xDFDB5C | 00 00 80 bf | −1.0 | inward sign |
| 0xBEA9A8 | 00 00 00 46 | 8192.0 | sine table size |
| 0xD69BA4, 0xD69AC0 | db 0f c9 40 | 6.283185 (2π) | .data, value as dumped |
| 0xBBB99C | 00 00 00 3f | 0.5 | |
| 0xBEAA2C | 00 00 00 80 | −0.0 | negation idiom `−0 − x` |
| 0xBEAA50 | ff ff 7f ff | −FLT_MAX | "no height" sentinel |
| 0xB92870 | 00 00 c8 42 | 100.0 | query point drop |
| 0xB9C650 | 00 00 c0 3f | 1.5 | airborne fade start |
| 0xBEB43C | ab aa aa 3e | 1/3 | airborne fade rate |
| 0xB9854C | cd cc 4c 3e | 0.2 | contact/no-contact time gate |
| 0xBB3E44 | 66 66 66 3f | 0.9 | stabilisation decay k |
| 0xB9B690 | 00 00 00 00 | 0.0 | |
| 0xBEB438 | cd cc 1c 41 | 9.8 | extra-gravity g |
| 0xB9B700 | 00 00 a0 40 | 5.0 | righting gains |
| 0xB9C174 | 00 00 20 41 | 10.0 | righting max angular accel |
| 0xBEA9AC | ff ff 7f 7f | FLT_MAX | righting max distance |
| 0xBEAB40 | ee ff 7f 7f | 3.40282e38 | AccelerationInfo ctor default |
| 0xBEAB60 | (f64) 2.0 | 2.0 | quaternion → angle-error scale |
| 0xDFDDC8 | 00 00 7a 44 | 1000.0 | listener no-contact timer initial |
| 0xB98748 | cd cc 4c 3d | 0.05 | wave amplitude loop cut-off |
| 0xD6AF10 | 00 00 00 00 | 0.0 | .data: water query "above surface" tolerance (as dumped) |
| 0xBF65A0 | identity 4×4 | — | identity transform for local AABB |
| 0xCF2900 | — | T[i] = sin(2πi/8192): T[0]=0, T[2048]=1, T[6144]=−1 | sine table (`sintable.txt`) |

---

## A. Record → actor field map

Method (P): loader `FUN_006584a0` calls float reader `0x656320` with EDX = name string and the
default in `[esp]`; the returned XMM0 is stored by the next block into the stack record. One 4-byte
argument slot sits on the stack during the float run, so `[esp+0x14+4k]` = record + 4k (record base is
`[esp+0x10]` when `0x64a600` is called at 0x658b5c). Vector reader `0x656610`, int reader `0x656210`,
enum reader `0x656720` (strings 0xBC6074 "False", 0xBC6084 "BoolEnum"). Names read at the EDX VAs
(`str_bc7c00.txt`, base 0xBC7C00). The record→actor copy is `FUN_004465e0` (EAX = record, EDI = actor),
called from the actor allocator `FUN_00435660` (0x435715) after it writes vtable 0xBA9340 (0x435703) with
EAX = `[component+0x38]` (0x4356ad). Defaults: bytes at the default VAs (`defs.txt`).

All 65 fields (record offsets P; actor offsets P from 0x4465e0–0x44687c):

| Field | rec | actor | default |
|---|---|---|---|
| Mass | 0x00 | — (not copied) | 500 (0xD2D820) |
| MaxSpeed (km/h) | 0x04 | 0x28 | 40 |
| MaxSpeedReverse | 0x08 | 0x2C | 10 |
| Steering | 0x0C | 0x30 | 2 |
| WaterDragSide | 0x10 | 0x38 | 2 |
| WaterDragFwd | 0x14 | 0x34 | 0.5 |
| WaterDragUp | 0x18 | 0x3C | 1 |
| AngDampYaw | 0x1C | 0x5C | 0.5 |
| OutOfWaterGravityFactorUp | 0x20 | 0xE4 | 1 |
| OutOfWaterGravityFactorDown | 0x24 | 0xE8 | 1 |
| EngineTorqueMultiAtCollision | 0x28 | 0xEC | 1 |
| HullFriction | 0x2C | 0xF0 → body+0x84 | 0.3 (0xB9B688) |
| AngDampRoll | 0x30 | 0x54 | 0 |
| AngDampPitch | 0x34 | 0x58 | 0 |
| BrakeDrag | 0x38 | 0x40 | 0 |
| NoSpeedSteering | 0x3C | 0x44 | 0 |
| LowSpeedSteering | 0x40 | 0x48 | 0 |
| LowSpeedLimit (km/h) | 0x44 | 0x4C | 10 |
| HighSpeedSteerLoss | 0x48 | 0x50 | 0 |
| SteerInertia | 0x4C | 0x94 | 0 |
| SteerNoInputInertia | 0x50 | 0x98 | 0 |
| AirCtrlSteering | 0x54 | 0xB8 | 0 |
| EngineTorque | 0x58 | 0x14C | 100 |
| EngineReverseTorque | 0x5C | 0x150 | 10 |
| EngineInertia | 0x60 | 0x148 | 0.975 (0xDFDDE0) |
| EngineTorqueRatio0 | 0x64 | 0x12C | 0.4 (0xBA8724) |
| EngineTorqueRatio1 | 0x68 | 0x134 | 1 |
| EngineTorqueRatio2 | 0x6C | 0x13C | 0.9 |
| EngineTorqueRatio3 | 0x70 | 0x144 | 0.15 (0xB9C328) |
| EngineTorquePos1 | 0x74 | 0x130 | 0.25 |
| EngineTorquePos2 | 0x78 | 0x138 | 0.5 |
| RollFromTurning (rad) | 0x7C | 0x60 | 0 |
| RollInertia | 0x80 | 0x68 | 0.95 (0xDFDDC4) |
| PitchFromAcceleration (rad) | 0x84 | 0x64 | 0 |
| PitchUpSpeed (1/s) | 0x88 | 0x6C | 0.25 |
| PitchDownInertia | 0x8C | 0x70 | 0.95 |
| SpringLoSpeedStartOffset | 0x90 | 0x74 | 1 |
| SpringLoSpeedEndOffset | 0x94 | 0x78 | 0 |
| SpringHiSpeedStartOffset | 0x98 | 0x7C | 1 |
| SpringHiSpeedEndOffset | 0x9C | 0x80 | 0 |
| SpringLoSpeedStrength | 0xA0 | 0x84 | 5 |
| SpringHiSpeedStrength | 0xA4 | 0x88 | 5 |
| SpringLoSpeedDampening | 0xA8 | 0x8C | 1 |
| SpringHiSpeedDampening | 0xAC | 0x90 | 1 |
| HandBrakeInertia | 0xB0 | 0x9C | 0 |
| HandBrakeSteerBoost | 0xB4 | 0xA0 | 0 |
| HandBrakeAntiSideDrag | 0xB8 | 0xA4 | 0 |
| HandBrakeMomentumKeep | 0xBC | 0xA8 | 0 |
| ShallowDepth (m) | 0xC0 | 0xBC | 0 |
| ShallowLinDamp | 0xC4 | 0xC0 | 0 |
| ShallowAngDamp (asked as `fShallowAngDamp`, 0xBC80BC) | 0xC8 | 0xC4 | 0 |
| SpringWaterSmoothing | 0xCC | 0xC8 | 0.9 |
| CollisionStabilization | 0xD0 | 0xCC | 1 |
| CenterOfMassOffset (vec3) | 0xD4–0xDC | 0xD0–0xD8 | (0,0,0) reader default 0 |
| VisRudderBone (int) | 0xE0 | 0xAC | 0 |
| VisRudderMaxAngle | 0xE4 | 0xB0 | 0 |
| VisRudderInertia | 0xE8 | 0xB4 | 0 |
| WakeOffset (vec3) | 0xEC–0xF4 | — | — |
| WakeRate | 0xF8 | — | 0.05 |
| WakeSpeed | 0xFC | — | 15 (0xB977CC) |
| WakeLifeTime | 0x100 | — | 1 |
| WakeSize | 0x104 | — | 0.5 |
| NumSamplesPerSpringX (int) | 0x108 | 0xDC | 1 |
| NumSamplesPerSpringZ (int) | 0x10C | 0xE0 | 1 |
| FlipOnLandEnable (BoolEnum) | 0x110 | byte 0xF4 = (value ≠ 0) | "False" |

Grades: names, record offsets, actor offsets P. "km/h", "rad", "1/s" units are from how the code uses
them (sections C–D), P where stated there. Defaults P as bytes; the vector/int/enum reader defaults are
P only as the pushed immediates (`push 0` / `push 1`).

Actor state the floating code owns (all P; initial values from 0x4465e0/0x446887–0x4468e6):
| actor | meaning | init |
|---|---|---|
| 0xF8, 0xFC, 0x100, 0x104 | owner inputs (0xF8 read as forward throttle by thrust 0x447483; 0x104 = handbrake input, 0x447503) — names I | 0 |
| 0x108 | smoothed steer (written by steer 0x44801c) | 0 |
| 0x10C | smoothed handbrake: = input when input > state, else smoother(k=HandBrakeInertia) (0x4474fb–0x447543) | 0 |
| 0x110 | roll state (pre-step) | 0 |
| 0x114 | pitch state (pre-step) | 0 |
| 0x118 | collision-stabilisation gain (drag) | 0 |
| 0x154 | smoothed in-water factor W | 1.0 |
| 0x158 | rudder angle (steer) | 0 |
| 0x15C | ground height under body (or −FLT_MAX) | — |
| 0x160 | water height under body (or −FLT_MAX) | — |
| 0x164 | submerged fraction of world AABB height (no reader found in the boat functions; consumer ND) | — |
| 0x168 | reversing flag (thrust) | 0 |
| 0x16C + 0x34·i, i=0..3 | spring records (B) | see B |
| 0x23C | contact listener (0x1C bytes) | built by 0x446460 |
| 0x240 | righting timer (F) | 0 |

---

## B. Hull setup `FUN_00446930` (whole function, 0x446930–0x446bcc, P)

Called once from `FUN_004465e0` (0x446882), ESI = actor, EDI = body.

1. **AABB**: `shape = [body+0x10]`; calls shape vtable slot 7 (`[vt+0x1C]`, 0x446944–0x446955) with
   args (transform = 0xBF65A0 = identity (P, `c_bf65a0.txt`), tolerance = 0.0 (fldz → pushed slot),
   out = local stack). So the box is the collision shape's AABB **in body-local space, no margin
   added by this call** (P for identity/0.0; "slot 7 = hkpShape::getAabb" I from the argument
   signature). Out layout: min = (mnx, mny, mnz) at [esp+0x20..0x28], max at [esp+0x30..0x38].
2. **Spring records** at actor+0x16C, stride **0x34**, 4 records. Layout (P from the writes here and
   the reads in C):

| rec off | type | content |
|---|---|---|
| +0x00 | f32 | smoothed water height (springs) — init −100 (0x4468a8) |
| +0x04 | u8 | "water found under patch" flag (pre-step) — init 0 |
| +0x08 | f32 | raw max water height over the patch (pre-step) — init −100 |
| +0x0C | f32 | roll coefficient |
| +0x10 | f32 | pitch coefficient |
| +0x14..+0x1C | vec3 | local attach point at low speed **A** |
| +0x20..+0x28 | vec3 | local attach point at high speed **B** |
| +0x2C | f32 | inward sign along local X (sx) |
| +0x30 | f32 | inward sign along local Z (sz) |

   Corners (P, 0x446957–0x446a61): with Ylo = SpringLoSpeedStartOffset (actor+0x74),
   Yhi = SpringHiSpeedStartOffset (actor+0x7C):

| i | rec | A | B | sx | sz | I: which corner (if +Z fwd, +X right) |
|---|---|---|---|---|---|---|
| 0 | 0x16C | (mnx, Ylo, mxz) | (mnx, Yhi, mxz) | +1 | −1 | front-left |
| 1 | 0x1A0 | (mxx, Ylo, mxz) | (mxx, Yhi, mxz) | −1 | −1 | front-right |
| 2 | 0x1D4 | (mnx, Ylo, mnz) | (mnx, Yhi, mnz) | +1 | +1 | rear-left |
| 3 | 0x208 | (mxx, Ylo, mnz) | (mxx, Yhi, mnz) | −1 | +1 | rear-right |

   The attach **Y is the StartOffset value itself** (body-local, measured from the body origin), not
   AABB-relative. X/Z are the exact AABB corners, no inset.
3. **Roll / pitch coefficients** (P, 0x446a67–0x446b6c): idx(θ) = trunc(θ·8192/2π + 0.5) & 0x1FFF,
   T = sine table 0xCF2900.
   - rollCoef = ±0.5·(mxx − mnx)·sin(RollFromTurning): rec0, rec2 = +; rec1, rec3 = − (negated via −0.0).
   - pitchCoef = (mxz − mnz)·sin(PitchFromAcceleration) for rec0, rec1 (the max-Z pair); 0 for rec2, rec3.
4. **Centre of mass**: local CoM = ((mnx+mxx)/2 + CoMOffset.x, (mny+mxy)/2 + CoMOffset.y,
   (mnz+mxz)/2 + CoMOffset.z, 0) passed to `FUN_008d5290` (0x446b74–0x446bc3). `8d5290` calls
   motion vtable +0x2C (body `0x8df3c0` → `0x896a40(arg, motion+0x10)`) then `0x8d4d10`
   (P for the calls). That this is hkpRigidBody::setCenterOfMassLocal (CoM moves; inertia not
   recomputed) is I.
5. After the call (in 0x4465e0): all four recs get flag 0, +0x00 = +0x08 = −100 (0x446887–0x4468b3);
   W (0x154) = 1.0; 0x108, 0x10C, 0x158, 0x240 = 0; listener built if 0x23C == 0; `FUN_008d4c30(body,
   HullFriction)` writes **body+0x84 = HullFriction** (P, `g_misc.txt` + call 0x446920). "body+0x84 =
   hkpMaterial friction" I.

`NumSamplesPerSpringX/Z` are not used here; they are used by the pre-step (C.1).

---

## C. Water sampling (pre-step `FUN_00446bd0`) and springs `FUN_004477a0`

### C.0 Speed ratios (two different ones — P)
- Pre-step: `kmh = |v|·3.6`; `a = min(kmh / LowSpeedLimit, 1)`; `s2 = min(kmh / MaxSpeed, 1)`
  (0x446cd1–0x446d53; |v| = total speed via sqrt `0x401740`).
- Springs: `t = clamp((v·col2)·3.6 / MaxSpeed, 0, 1)` if MaxSpeed > 1e-4 else 0 — **forward speed
  along local +Z** (0x4478c4–0x447937).

### C.1 Pre-step `FUN_00446bd0(dt, doWater)` (vtable slot 9 at 0xBA9364; caller and the value of the
byte arg ND — it is a virtual call). Whole function read (P):
1. **Pitch state** (actor+0x114): target = actor+0xF8 · (1 − actor+0x10C). If target ≥ state:
   state = min(target, state + PitchUpSpeed·dt) (rate-limited); else state = Smooth(state → target,
   k = PitchDownInertia, dt). (0x446d59–0x446dc9)
2. **Roll state** (actor+0x110): state = Smooth(state → actor+0x108 · (1 − HighSpeedSteerLoss·s2) · a,
   k = RollInertia, dt). (0x446dc9–0x446e16)
3. If `doWater == 0` return. (0x446e12)
4. **Ground** under body: `FUN_004423a0(pos.x, pos.z, &h, &n)`; actor+0x15C = h if it returned true,
   else −FLT_MAX (0x446e24–0x446e65). `4423a0` looks up a 20×20 cell table (0xE793A0) and calls
   `0x442100(x, z, &h, &normal)` per cell — a terrain height query (I; the per-cell routine not read).
5. **Water** under body: point (pos.x, pos.y − 100, pos.z); `WaterQuery(point, &actor+0x160, flag=1)`;
   on false actor+0x160 = −FLT_MAX (0x446e6d–0x446eb6).
6. **Submerged fraction**: world AABB (shape slot 7 with transform = &body+0xE0, tolerance 0);
   actor+0x164 = 1 − clamp((maxY − water)/(maxY − minY), 0, 1) (0x446eba–0x446f21).
7. Patch extents: `width = |A1 − A0|`, `length = |A0 − A2|` (record A points, 0x446f29–0x446fdc) =
   AABB X extent and Z extent.
8. Per spring i (0x447010–0x447250):
   - local p = A·(1 − s2) + B·s2 (note: **s2 = total-speed ratio**, unlike C.2); W = M·p
     (`D3DXVec3TransformCoord`, M rows = col0, col1, col2, pos).
   - stepX = col0 · (0.5·width·sx)/(nX − 1) if nX > 1 (else unused); stepZ = col2 · (0.5·length·sz)/(nZ − 1)
     if nZ > 1. nX = actor+0xDC, nZ = actor+0xE0.
   - `FUN_00447650(origin = (W.x, W.y − 100, W.z), stepX, stepZ, nX, nZ, &rec+0x08)`; result byte →
     rec+0x04.
   So each spring samples an nX × nZ grid from its corner inward to the hull's centre lines (half the
   width, half the length), 100 m below the corner.
9. `FUN_00447650` (P, whole): out = −FLT_MAX; for i < nX, j < nZ: q = origin + i·stepX + j·stepZ;
   if `WaterQuery(q, &h, flag=1)` → out = max(out, h). Returns (out ≠ −FLT_MAX). So rec+0x08 = highest
   water surface over the patch; rec+0x04 = "water exists under the patch". Because the probe is 100 m
   down, this is true whenever water exists there, regardless of whether the hull touches it.

### C.2 Water height query `FUN_00480440(point in ESI, out in EDI, byte flag)` (P except where noted)
- 0x480440–0x480446: `push ebp; mov ebp,esp; and esp,-8; jmp [0x244fcd8]` → 0x24B9E30 (SecuROM VM
  entry `push 0x24b9e3a; call 0x1aaff10`, `d_24b9e30.txt`). The continuation at 0x48044C tests ECX ≠ 0,
  so the 6 stolen bytes set ECX. The sibling query `FUN_004803a0` starts with `mov ecx,[0xD6AF84]`
  (6 bytes, `d_4803a0.txt`) and then has the identical body. ⇒ ECX = watermap object `[0xD6AF84]` (I,
  strong). In the dump [0xD6AF84] = 0 and [0xD6AF80] = 0 (dump taken with no level loaded — I).
- Body: `FUN_00481710(map=ECX, point=EAX, out)` (static map, P `d_481710.txt`):
  fx = (x − map[+0x30])/map[+0x28], fz = (z − map[+0x38])/map[+0x28]; i = clamp(trunc(fx), 0, W−1),
  i1 = clamp(i+1), same for j with H (W = map[+0x1C], H = map[+0x18]); heights f32 `map[+0x3C]`, wet
  bytes `map[+0x40]`, row-major `j·W + i`. **Returns false iff all four wet bytes are 0** (test is
  `≠ 0`, not `== 255`). Else h = bilinear: lerp(lerp(h00,h10,φx), lerp(h01,h11,φx), φz) with
  φ = f − floor(f) (`0x407840` → CRT `floor` per Ghidra name).
- If point.y > h + [0xD6AF10] → return false (0xD6AF10 = 0.0 in the dump; .data).
- If water object [0xD6AF80] ≠ 0 (P): sum of global sine waves from table 0xD6AD80, records of
  0x14 bytes {kx, kz, ?, A, ω}: h += A·T[(trunc((kx·x + kz·z − ω·t)·8192/2π + 0.5) − 2048) & 0x1FFF]
  = A·sin(φ − π/2) = **−A·cos(kx·x + kz·z − ω·t)**, t = water[+0xCA0]. The first record is always
  applied; the loop continues while the next record's A > 0.05 (0xB98748), up to 20 records
  (0x48048e–0x48052f). The table is all zero in the dump (runtime-filled; values ND).
- If flag == 0, adds `FUN_00481ca0(...)` (not read). **The boat always passes flag = 1**, so it never
  takes that term.
- *out = h; returns (point.y ≤ h).
- No water ⇒ returns false and does not write *out (callers then use their own sentinel).

### C.3 Springs `FUN_004477a0(actor, dt)` (whole function, 0x4477a0–0x447ef7, P)
Interpolated parameters (by forward ratio t from C.0):
- K = SpringLoSpeedStrength·(1−t) + SpringHiSpeedStrength·t
- D = SpringLoSpeedDampening·(1−t) + SpringHiSpeedDampening·t
- L = max(LoStart − LoEnd, 0)·(1−t) + max(HiStart − HiEnd, 0)·t   (actor 0x74−0x78, 0x7C−0x80)

Per spring i (0x4479ee–0x447cf0):
1. p = A·(1−t) + B·t (**forward-speed t here**); W = M·p (world).
2. springEndY = W.y − L·col1.y (only the Y component of the local up axis).
3. Q (application point) = COM_world + col0·p.x + col2·p.z — the corner's X/Z **about the centre of
   mass, with no Y offset** (0x447a92–0x447b04).
4. If rec flag (+0x04) == 0: rec+0x00 = −100; impulse = 0; skip.
5. Water smoothing: if rec+0x00 == −100 (first frame after water found): rec+0x00 = raw (rec+0x08);
   else rec+0x00 = Smooth(rec+0x00 → raw, k = SpringWaterSmoothing, dt) (0x447b13–0x447b6d).
6. c = rec+0x00 + rollCoef·rollState(0x110) + pitchCoef·pitchState(0x114) − springEndY
   (0x447b72–0x447b98). Roll/pitch act by raising/lowering the per-corner water target.
7. f = (L > 1e-4) ? clamp(c/L, 0, 1) : 0    (fraction of spring length submerged).
8. v_py = v.y + ω.z·r.x − ω.x·r.z, r = Q − COM (vertical velocity of point Q) (0x447bd6–0x447c25).
9. **J = max(0, m·dt·(max(K·c, 0) − D·f·v_py))**, m = getMass() = (invMass == 0 ? 0 : 1/invMass)
   (`FUN_008df470`, 0x447c51–0x447c77). Operand order: `fld spring; fsub damp` → spring − damp.
10. impulse_i = (0, J, 0) (world up only); sumF += f.

Law in plain terms: per-spring upward acceleration-equivalent = K·c − D·f·v_py, K in 1/s² (it is
multiplied by mass and dt to make an impulse), D in 1/s, never pulling down. No gravity term, no clamp
on c above L (only f saturates). With four equally compressed springs and W = 1, equilibrium needs
4·K·c = g_world ⇒ **c_rest = g_world/(4K)** — I (requires the world gravity value, ND, and equal
compression).

After the loop (P):
11. In-water target = (0.25·sumF > 0 && water(0x160) > ground(0x15C)) ? 1 : 0.
    W(0x154) = Smooth(W → target, k = 0.95, dt) — the smoother inlined with (1−k) = 0.05 and
    threshold 9.025e-11 (0x447cf6–0x447dbb).
12. ωy_saved = body ω.y (0x447dc3) — read **after** the first loop, before applying.
13. For each spring: activate body (`FUN_008dda50`, I = hkpEntity::activate), then
    **motion vtable +0x4C = applyPointImpulse(impulse_i · W, Q_i)** (0x447de6–0x447e78).
14. ω' = (ω.x, ωy_saved, ω.z) (current ω after impulses, Y replaced); activate;
    **motion vtable +0x44 = setAngularVelocity(ω')** (0x447e86–0x447eef). ⇒ the spring impulses never
    change the **world-Y** angular velocity (yaw rate).

Motion vtable slots (P, bodies read in hkpBoxMotion vtable 0xB5921C, found via RTTI
`.?AVhkpBoxMotion@@` → COL 0xBEEF08 → vtable[−1] at 0xB59218; same slots in hkpSphereMotion 0xB58A4C):
+0x40 0x8df4d0 writes motion+0xD0 (= linear velocity) → setLinearVelocity; +0x44 0x8df500 writes
motion+0xE0 (angular velocity) → setAngularVelocity; +0x48 0x8df530 v += imp·invMass →
applyLinearImpulse; +0x4C 0x8f6480 v += imp·invMass, ω += R·(I⁻¹_local ∘ Rᵀ((p − COM) × imp)) →
applyPointImpulse; +0x50 0x8f6670 ω += R·(I⁻¹_local ∘ Rᵀ·imp) → applyAngularImpulse.

### C.4 In-water / out-of-water state summary
`InWaterT` and `WaterDepth` are **not** fields of the PC `_BoatPhysics` record (not among the 65 names
the loader asks for). The PC equivalents are: W (actor+0x154, C.3 step 11), ground/water heights
(0x15C/0x160), per-spring flags, and the contact listener timers (D.1). `ShallowDepth` is used in D.3.

---

## D. Drag `FUN_00448210(actor in EAX, dt)` (whole function, 0x448210–0x448fdc, P)

Local frame components: vx = v·col0, vy = v·col1, vz = v·col2; ωx = ω·col0, ωy = ω·col1, ωz = ω·col2
(0x4483d5–0x44853d). a = min(|v|·3.6/LowSpeedLimit, 1) (0x4483a8–0x4483f3).

### D.1 Contact listener (actor+0x23C) — P
Object 0x1C bytes from `FUN_00446460` (vtables 0xBAA310 / 0xBAA324). Slot 0 `0x4464d0` does
`++[+0x18]`, slot 2 `0x4464e0` does `--[+0x18]` (contact point added/removed — slot names I). applyAction
0x44727f–0x4472b4: if count > 0 {+0x14 += dt; +0x10 = 0} else {+0x14 = 0; +0x10 += dt}. +0x10 starts at
1000.0 (0xDFDDC8). So +0x14 = time in contact, +0x10 = time without contact.

### D.2 Collision stabilisation (anti-roll) — P (0x448513–0x44869c)
- gAir = 1 − clamp((noContactTime − 1.5)/3, 0, 1).
- If (W > 0.5 && noContactTime > 0.2) || contactTime > 0.2: s = Smooth(s → 0, k = 0.9, dt);
  else s = min(CollisionStabilization · gAir · a, 1). s = actor+0x118.
- ω ← ω − col2·(ωz·s); **setAngularVelocity** (slot +0x44). Not ×dt: s is a per-step fraction of the
  roll rate (rate about local Z) removed.

### D.3 Shallow water and grounded drag — P (0x44869e–0x44887d)
- shallow = (ShallowDepth > 1e-4) ? 1 − clamp((water − ground)/ShallowDepth, 0, 1) : 0.
  Note: if water = −FLT_MAX (no water) the ratio is negative → shallow = 1.
- shallowDamp = ShallowLinDamp · shallow · a.
- hull = (contactCount > 0 && ground > water) ? 0.25·a : 0   (0x448701–0x448748).
- **applyLinearImpulse(−m·dt·(hull + shallowDamp)·v)** (0x448759–0x44883b).
- **applyAngularImpulse(−ShallowAngDamp·m·shallow·a·dt·ω)** where ω is the post-D.2 value
  (0x448759–0x44887d); ShallowAngDamp is always 0 on PC (loader name mismatch) so this is a no-op.

### D.4 Water drag — P (0x44887f–0x4489f0)
- S = col0·(WaterDragSide·vx); S' = (S.x·(1 − h), S.y, S.z·(1 − h)), h = HandBrakeAntiSideDrag ·
  actor+0x10C · a (y is left untouched: the code multiplies h by 0.0 for y).
- Dv = S' + col2·(WaterDragFwd·vz) + col1·(WaterDragUp·vy).
- **applyLinearImpulse(−m·W·dt·Dv)**. ⇒ explicit Euler `v_axis −= k_axis·v_axis·W·dt` per local axis;
  linear in v, scaled by W (not by a submerged fraction), no exponential.
- HandBrakeMomentumKeep (0x4489f2–0x448ab5): impulse (M·col2.x, 0, M·col2.z),
  M = |S'|·HandBrakeMomentumKeep·m·actor+0x10C·dt·W → applyLinearImpulse.

### D.5 Angular water damping — P (0x448ab7–0x448be4)
A = col2·(AngDampRoll·ωz) + col0·(AngDampPitch·ωx) + col1·(AngDampYaw·ωy).
**applyAngularImpulse(−m·W·dt·A)**. The impulse is scaled by **mass**, then multiplied by the inverse
inertia inside applyAngularImpulse: Δω = −W·dt·m·I⁻¹·A. So the effective damping rate depends on m/I.
Axis binding (P): Roll ↔ local Z, Pitch ↔ local X, Yaw ↔ local Y.

### D.6 BrakeDrag, HullFriction
- BrakeDrag (actor+0x40) is used in the thrust function, not here: `FUN_00447350` 0x44744e
  `BrakeDrag·W·m·dt` then applyLinearImpulse at 0x4474f9 (P for those instructions; the rest of that
  formula is the boat-drive reader's).
- HullFriction only goes to body+0x84 at setup (B.5).
- CollisionStabilization: D.2.

---

## E. Gravity — P (0x448be6–0x448c71)
- G = (v.y > 0) ? OutOfWaterGravityFactorUp : OutOfWaterGravityFactorDown (world v.y).
- **applyLinearImpulse((0, −9.8·m·dt·(1 − W)·(G − 1), 0))**, 9.8 = 0xBEB438 (cd cc 1c 41).
  x87: `fld1; fld st0; fsub W; fld G; fsubrp st(2),st` (bytes de e2 = FSUBRP: st2 = st0 − st2 = G − 1);
  `fmulp; fmulp; fmul dt; fmul 9.8; fchs`.
- Interpretation: an explicit extra force on top of the world gravity, faded in by (1 − W). In water
  (W = 1) the extra is 0, i.e. effective gravity factor 1. The body's own gravity factor field is not
  touched by any boat function read here.
- World gravity value: not read by these functions — ND.

---

## F. Self-righting — P (0x448c73–0x448fd3)
1. Timer actor+0x240: if col1.y < 0.5 (local up more than 60° from world up) → timer = 0.5; else
   timer = max(timer − dt, 0).
2. Gate: skip when (listener ≠ null && contactCount ≠ 0 && FlipOnLandEnable == 0). Then run only if
   timer > 1e-4. ⇒ it acts **at once** when tipped and keeps acting for 0.5 s after the up axis comes
   back above 0.5; touching anything blocks it unless FlipOnLandEnable.
3. Target orientation: `FUN_00825370(out, fwd = col2)` builds right = normalize(Y × fwd),
   up = fwd × right, rows (right, up, fwd) — a level frame with the boat's heading (I from Ghidra decomp,
   `g_misc.txt`; the normalise helper `0x401630` not read). `FUN_008231d0` turns it into quaternion q_t
   (trace method; reading the 4×4 as Havok columns col0 = right, col1 = up, col2 = fwd; I).
4. Keyframe struct (at P+0x12C): position (0,0,0,0), orientation q_t, linear velocity = current v,
   angular velocity = ω_t = col0·ωx + col1·ωy (current ω with the local-Z (roll) component removed).
5. Gains struct (built by `FUN_00944920`, then overwritten): linearPositionFactor (1,1,1,·),
   angularPositionFactor (5,5,5,0), linearVelocityFactor (1,1,1,·), angularVelocityFactor (5,5,5,0),
   maxLinearAccel 0, maxAngularAccel 10, maxDistance FLT_MAX (field roles I by matching Havok's
   AccelerationInfo layout; the values P).
6. `FUN_00405d00(kf, 0.25, body)` (P): invDt = 1/0.25 = 4; angularPositionFactor ← normalize ×
   min(|f|, invDt − 1e-4) = 2.3093 each; angularVelocityFactor ← normalize × (invDt − 1e-4) = 2.3093
   each; then `FUN_00944ab0(kf, gains, dt=0.25, invDt=4, body)`.
7. `FUN_00944ab0` (P, `d_944ab0.txt`): r = q_t ⊗ conj(q_body) (`0x88a860`, P), e = 2·r.xyz, negated if
   r.w < 0. Δω = angPosFactor∘e + angVelFactor∘(ω_t − ω)·0.25; if |Δω| > 10·0.25 = 2.5 → scale to 2.5.
   Δv = linPosFactor∘(0 − pos) + linVelFactor∘0·0.25, clamped to |Δv| ≤ 0·0.25 = 0 ⇒ Δv = 0.
   setAngularVelocity(ω + Δω); setLinearVelocity(v). (invDt is not used inside 0x944ab0.)
   Net per physics step: **Δω = 2.3093·e − 0.577·ωz·col2, |Δω| ≤ 2.5 rad/s**, a velocity change
   applied directly (no torque, no teleport). The 0.25 is a constant, not the step dt.

---

## G. Body mass and inertia
- Every force here uses m = 1/invMass from the Havok motion (motion+0xCC, `FUN_008df470`) (P).
  The record `Mass` (rec+0x00) is not copied into the actor (P: absent from 0x4465e0).
- Body creation and how the inertia tensor is made: ND (not in the functions read; the actor receives an
  existing body from `0x5857e0` in 0x4356bd). Hull setup moves the CoM (B.4) — I that inertia is not
  recomputed then.
- Motion type (box / sphere / stabilised): ND. Slot semantics are the same in both vtables checked.

## H. Step time
- applyAction `FUN_00447260(stepInfo)`: dt = `[stepInfo+8]` (0x447275) (P; "hkStepInfo::m_deltaTime" I).
  If dt < 1e-4 nothing runs, including the listener timers (0x44727a).
- Springs and drag take dt as an argument and use it in every impulse (P).
- The smoother `FUN_00714d90(k, dt, cur, target)` (P, whole): if dt > 16.667: return k > 0.9999 ? cur :
  target. Else repeat while dt > 1/60: if (target − x)² < (k·1e-5)² return target;
  x += (target − x)(1 − k); dt −= 1/60. Then f = dt·60; return x·(1 − f) + (x + (target − x)(1 − k))·f.
  So the smoothing rates are per 1/60 s regardless of the physics step (P).
- Self-righting uses a fixed 0.25 s in place of dt (F.6).

## I. Axes — P
- Forward = local **+Z** (col2): the springs' speed ratio uses v·col2 (0x447900), WaterDragFwd multiplies
  vz = v·col2 (0x4488d9), AngDampRoll multiplies ωz (rotation about col2) (0x448ab7), the stabiliser
  removes the col2 component of ω (0x44861a), and the righting target keeps col2 as heading.
- Up = local **+Y** (col1): spring end = W.y − L·col1.y; WaterDragUp uses vy = v·col1; tip test col1.y.
- Side = local **X** (col0): WaterDragSide multiplies vx; roll coefficients split on AABB X.
- Corner naming (front-left etc.) assumes +X = right in the left-handed Y-up frame (I); the code itself
  is symmetric, only the signs in B.2/B.3 matter.

---

## NOT DETERMINED / risks
1. ECX for the water query is set inside the SecuROM island; `[0xD6AF84]` is inferred from the sibling
   `FUN_004803a0` (same 6-byte slot, same body). Confirm live.
2. Watermap object field values (+0x28 cell, +0x30/+0x38 origin, +0x18/+0x1C dims) are runtime; the
   dump has the pointer = 0. Origin convention (corner vs centred) ND from this image.
3. Global wave table 0xD6AD80 and water object 0xD6AF80 are zero in the dump; wave parameters, and
   whether waves are on in normal play, ND. Tolerance 0xD6AF10 (.data) = 0.0 as dumped only.
4. Pre-step caller and the `doWater` byte: ND (virtual slot 9). If it is false on some frames, the
   spring flags/raw heights keep their last values.
5. Ground query `0x442100` (per-cell terrain height) not read; the "terrain" reading is I.
6. World gravity value and the body's gravity factor: ND. c_rest = g/(4K) is I.
7. Body creation, motion type, inertia: ND (G).
8. Shape slot 7 = getAabb and its margin behaviour are I (Havok signature); the call args are P.
9. Righting target-frame builder `0x825370` and `0x8231d0` read from the Ghidra decomp, not fully
   re-traced in disassembly (their role is I; the gains, clamps and keyframe math in 0x405d00/0x944ab0
   are P).
10. actor+0x164 (AABB submerged fraction) has no consumer in the boat functions; who reads it is ND.
11. Inputs 0xF8/0xFC/0x100/0x104 naming is I (boat-drive reader owns these).

## Disagreements with the existing notes
1. Memory note "rest depth g/(4K)": the law is now read (C.3): J = max(0, m·dt·(max(K·c,0) − D·f·v_py)),
   upward only, ×W. g/(4K) holds only as an inference for equal compression and unknown world g.
2. Memory note "Self-righting starts 0.5 s after tipping": wrong. It starts as soon as col1.y < 0.5 and
   continues 0.5 s after recovery (timer held at 0.5 while tipped). It is a soft-keyframe angular-velocity
   change, not a torque, and is blocked by any contact unless FlipOnLandEnable.
3. Memory note "Not copied into the actor: ... VisRudderBone": wrong — rec+0xE0 (VisRudderBone) is
   copied to actor+0xAC (0x446770). Mass and the five Wake* are indeed not copied.
4. Memory note "Drag fields are 1/s": true for WaterDrag* (linear, ×m·dt). The AngDamp* fields are
   applied as mass-scaled angular impulses, so their effective rate is AngDamp·m/I, not 1/s.
5. Prompt/notes list `InWaterT`, `WaterDepth` (and water_code_map §5 lists `ShallowT`, `InWaterT`,
   `WaterDepth`) as boat fields: the PC loader `FUN_006584a0` does not ask for them (they appear only in
   the Xbox strings, `docs/mercs2-pdb-analysis/vehicles.md`).
6. `water_code_map.md` §4 "FUN_00480440 return semantics = confirm-live": the continuation is in the dump
   (0x48044C): it returns a **height** in *out and `true` iff the point is at or below it; false when no
   wet cell is among the four around the point, or the point is above the surface + tolerance.
7. `mercs2_water::watermap` samples nearest-cell with wet == 255; retail bilinear-interpolates the
   four surrounding heights and calls the point water if **any** of the four wet bytes is non-zero.
8. `vehicle_code_map.json` "tuning field NAMES stripped on PC" and `ctor: FUN_004465e0`: names are
   present; 0x4465e0 is the record→actor copy (+ hull setup), the allocator/ctor that writes the vtable is
   0x435660 (the notes' "activate").
9. `docs/mercs2-ecs/03_controllers_physics.md` (Buoyancy component as the boat flotation): the boat does
   not touch a Buoyancy component in any function read here; its flotation in this code is the springs.
   Whether a Buoyancy component is also attached to boat templates is ND.
