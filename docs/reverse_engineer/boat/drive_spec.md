# Boat drive model (pc-v10): input, engine, thrust, steering. Port spec

Image: `game-files/canonical/dumps/mercs2_unpacked.exe`, sha256 `8c179a99d7fad88bab288826db19a579b53512801d8e0d1c1a761bbc30ebc7ba`
(re-hashed this run). File offset = VA − 0x400000. Disassembler: `/usr/bin/objdump -d --x86-asm-syntax=intel`
(llvm-objdump; the symbol labels it prints are bogus nearest-export names, so ignore them). Ghidra decomp was used only to
find callers. All reads are this run unless marked otherwise.

Grades: **P** = PROVEN (I read the instructions or bytes this run), **I** = INFERRED, **S** = SPECULATIVE.

Listings in this directory (`/private/tmp/claude-501/-Volumes-Projects-mercenaries-game/d08a21c0-8307-469b-be20-8c9b42a8712a/scratchpad/boat-drive/`):
`dis_6584a0_loader.txt`, `loader_table.txt` (built by `scripts/loader_table.py`), `dis_435660.txt` (activate),
`dis_4465e0.txt` (ctor), `dis_435790.txt` (command handler), `dis_447260.txt` (applyAction + 0x447300),
`dis_446bd0.txt` (pre-step), `dis_447350.txt` (thrust), `dis_4464f0.txt` (engine curve), `dis_447f00.txt` (steer),
`dis_714d90.txt` (smoother), `dis_446930.txt` (hull setup), `dis_region_446000_449000.txt` (springs, drag, the 0x23c
listener), `dis_region_434000_437000.txt` (owner methods), `dis_hk_8df460.txt` / `dis_hk_8f6340.txt` / `dis_hk_8f6760.txt` /
`dis_hk_8dda50.txt` (Havok motion), `dis_4036f0_physloop.txt` / `dis_403860_physloop2.txt` / `dis_413f90_physstep.txt` /
`slot9_candidates.txt` (step loop and pre-step dispatch), `vtbl_*.txt`, `consts*.txt`, `annotate_names.txt`.

---

## 0. Shared primitives

### 0.1 Smoother `FUN_00714d90` (P, `dis_714d90.txt`)
Register/stack convention: `xmm0` = k, `xmm2` = dt, `[esp+4]` = current x, `[esp+8]` = target T, result in `xmm0`.
```
eps = k * 1e-5                                   // 0xB92B3C = 1e-5
if dt > 16.666668 (0xBEAA78):  return (k > 0.9999 (0xBEAA74)) ? x : T
while dt > 1/60 (0xBCD278):
    d = T - x
    if eps*eps > d*d: return T                   // converged
    x = x + d*(1-k);  dt -= 1/60
f = dt * 59.999996 (0xBEAA70)                     // remaining fraction of a 1/60 step, in (0,1]
return f*(x + (T-x)*(1-k)) + (1-f)*x
```
So each full 1/60 s step does `x += (T − x)(1 − k)`. The remainder is a linear blend of one more step.
The same algorithm is inlined at 0x447d2f–0x447dbb with gain 0.05 (0xBEAE30, so k = 0.95) and eps² = 9.025e-11 (0xBEB440).
That cross-check confirms the reading.

### 0.2 Havok calls (P for bodies; slot names from RTTI rows in `pc-v10.annotate.jsonl`, `annotate_names.txt`)
`body = actor+0x18` (hkpUnaryAction entity). `motion = body+0xD0`. hkpBoxMotion vtable 0xB5921C (`vtbl_hkpBoxMotion_b5921c.txt`):
| call | what the body does (read) | meaning |
|---|---|---|
| `0x8DF470` (non-virtual) | `invM = motion+0xCC; return invM==0 ? 0 : 1/invM` | getMass (P) |
| slot 18 `+0x48` → 0x8DF530 | `motion+0xD0.. += imp * invM` (linear velocity) | applyLinearImpulse (P) |
| slot 19 `+0x4C` → 0x8F6480 | 2 args, adds to linear and angular velocity | applyPointImpulse (P shape) |
| slot 20 `+0x50` → 0x8F6670 | 1 arg: `ω(motion+0xE0..) += R·diag(I⁻¹ local @+0xC0..C8)·Rᵀ·imp` | applyAngularImpulse (P) |
| `0x8DDA50` (on body) | checks world, motion type 7, … | activate / wake (I) |
Body fields read: rotation columns `body+0xE0` (col0 = local +X), `+0xF0` (col1 = local +Y), `+0x100` (col2 = local +Z),
position `+0x110`, linear velocity `+0x1A0`, angular velocity `+0x1B0`.

### 0.3 Speed terms used below
- `v` = body linear velocity (m/s). `speedKmh = |v|·3.6` (3D magnitude; 3.6 = 0xBA8734 `66 66 66 40`) (P: 0x446d06/0x446d0b, 0x447f7f/0x447f84).
- `fwdKmh = (v · col2)·3.6`, signed (P: 0x447386–0x4473b5).
- `a = min(speedKmh / LowSpeedLimit, 1)`, `sM = min(speedKmh / MaxSpeed, 1)`. There is no lower clamp, but both are ≥ 0 (P: 0x446d29–0x446d53, 0x448042–0x448068).

---

## A. Record → actor field map

**Loader `FUN_006584a0`** (P, `dis_6584a0_loader.txt`): one call per field. `edx` = name string VA; the default comes from
`fld [const]` / `fld1` / `fldz` into `[esp]` for floats, or `push imm` for int/vec3/enum. Readers: `0x656320` float,
`0x656610` vec3 (returns a pointer), `0x656210` int, `0x656720` enum(type "BoolEnum" 0xBC6084, default "False" 0xBC6074).
Each result is stored to consecutive stack slots. The block passed to commit `0x64A600` is `lea ecx,[esp+0x10]` at 0x658b58.
That makes field i land at record offset = (store slot − 0x14 relative to the arg slot). The offsets were computed by tracking
every `push`/`add esp` (`scripts/loader_table.py` + hand check of the vec3/int/enum tail). Total = 0x114 = the
`_BoatPhysics` stream size (vehicle_code_map §2). Name match is by string pointer (P).

**Ctor `FUN_004465E0`** (P, `dis_4465e0.txt`): called from activate `FUN_00435660` at 0x435715 with `edi` = new actor
(alloc 0x244 at 0x4356dc, vtable 0xBA9340 written at 0x435703) and `eax` = record pointer (returned by `0x5857E0` with
`ecx = 0x17BC1D8`, the boat class descriptor). Each field is copied one by one (`fld [eax+r]; fstp [edi+a]`); the record is
not block-copied.

| # | Field (string VA) | rec off | actor off | default (const VA = bytes) |
|---|---|---|---|---|
| 0 | Mass (0xBC7CA4) | 0x000 | not copied | 500.0 (0xD2D820 `00 00 fa 43`) |
| 1 | MaxSpeed | 0x004 | 0x028 | 40.0 (0xB9B724) |
| 2 | MaxSpeedReverse | 0x008 | 0x02C | 10.0 (0xB9C174) |
| 3 | Steering | 0x00C | 0x030 | 2.0 (0xB92874) |
| 4 | WaterDragSide | 0x010 | 0x038 | 2.0 |
| 5 | WaterDragFwd | 0x014 | 0x034 | 0.5 (0xBBB99C) |
| 6 | WaterDragUp | 0x018 | 0x03C | 1.0 |
| 7 | AngDampYaw | 0x01C | 0x05C | 0.5 |
| 8 | OutOfWaterGravityFactorUp | 0x020 | 0x0E4 | 1.0 |
| 9 | OutOfWaterGravityFactorDown | 0x024 | 0x0E8 | 1.0 |
| 10 | EngineTorqueMultiAtCollision | 0x028 | 0x0EC | 1.0 |
| 11 | HullFriction | 0x02C | 0x0F0 | 0.3 (0xB9B688) |
| 12 | AngDampRoll | 0x030 | 0x054 | 0 |
| 13 | AngDampPitch | 0x034 | 0x058 | 0 |
| 14 | BrakeDrag | 0x038 | 0x040 | 0 |
| 15 | NoSpeedSteering | 0x03C | 0x044 | 0 |
| 16 | LowSpeedSteering | 0x040 | 0x048 | 0 |
| 17 | LowSpeedLimit | 0x044 | 0x04C | 10.0 |
| 18 | HighSpeedSteerLoss | 0x048 | 0x050 | 0 |
| 19 | SteerInertia | 0x04C | 0x094 | 0 |
| 20 | SteerNoInputInertia | 0x050 | 0x098 | 0 |
| 21 | AirCtrlSteering | 0x054 | 0x0B8 | 0 |
| 22 | EngineTorque | 0x058 | 0x14C | 100.0 (0xB92870) |
| 23 | EngineReverseTorque | 0x05C | 0x150 | 10.0 |
| 24 | EngineInertia | 0x060 | 0x148 | 0.975 (0xDFDDE0 `9a 99 79 3f`) |
| 25 | EngineTorqueRatio0 | 0x064 | 0x12C | 0.4 (0xBA8724) |
| 26 | EngineTorqueRatio1 | 0x068 | 0x134 | 1.0 |
| 27 | EngineTorqueRatio2 | 0x06C | 0x13C | 0.9 (0xBB3E44) |
| 28 | EngineTorqueRatio3 | 0x070 | 0x144 | 0.15 (0xB9C328) |
| 29 | EngineTorquePos1 | 0x074 | 0x130 | 0.25 (0xBBC7EC) |
| 30 | EngineTorquePos2 | 0x078 | 0x138 | 0.5 |
| 31 | RollFromTurning | 0x07C | 0x060 | 0 |
| 32 | RollInertia | 0x080 | 0x068 | 0.95 (0xDFDDC4) |
| 33 | PitchFromAcceleration | 0x084 | 0x064 | 0 |
| 34 | PitchUpSpeed | 0x088 | 0x06C | 0.25 |
| 35 | PitchDownInertia | 0x08C | 0x070 | 0.95 |
| 36 | SpringLoSpeedStartOffset | 0x090 | 0x074 | 1.0 |
| 37 | SpringLoSpeedEndOffset | 0x094 | 0x078 | 0 |
| 38 | SpringHiSpeedStartOffset | 0x098 | 0x07C | 1.0 |
| 39 | SpringHiSpeedEndOffset | 0x09C | 0x080 | 0 |
| 40 | SpringLoSpeedStrength | 0x0A0 | 0x084 | 5.0 (0xB9B700) |
| 41 | SpringHiSpeedStrength | 0x0A4 | 0x088 | 5.0 |
| 42 | SpringLoSpeedDampening | 0x0A8 | 0x08C | 1.0 |
| 43 | SpringHiSpeedDampening | 0x0AC | 0x090 | 1.0 |
| 44 | HandBrakeInertia | 0x0B0 | 0x09C | 0 |
| 45 | HandBrakeSteerBoost | 0x0B4 | 0x0A0 | 0 |
| 46 | HandBrakeAntiSideDrag | 0x0B8 | 0x0A4 | 0 |
| 47 | HandBrakeMomentumKeep | 0x0BC | 0x0A8 | 0 |
| 48 | ShallowDepth | 0x0C0 | 0x0BC | 0 |
| 49 | ShallowLinDamp | 0x0C4 | 0x0C0 | 0 |
| 50 | fShallowAngDamp (0xBC80BC) | 0x0C8 | 0x0C4 | 0 |
| 51 | SpringWaterSmoothing | 0x0CC | 0x0C8 | 0.9 |
| 52 | CollisionStabilization | 0x0D0 | 0x0CC | 1.0 |
| 53 | CenterOfMassOffset (vec3) | 0x0D4–0x0DC | 0x0D0–0x0D8 | `push 0` → (0,0,0) (I) |
| 54 | VisRudderBone (int, `mov` copy) | 0x0E0 | 0x0AC | 0 |
| 55 | VisRudderMaxAngle | 0x0E4 | 0x0B0 | 0 |
| 56 | VisRudderInertia | 0x0E8 | 0x0B4 | 0 |
| 57 | WakeOffset (vec3) | 0x0EC–0x0F4 | not copied | (0,0,0) (I) |
| 58 | WakeRate | 0x0F8 | not copied | 0.05 (0xB98748) |
| 59 | WakeSpeed | 0x0FC | not copied | 15.0 (0xB977CC) |
| 60 | WakeLifeTime | 0x100 | not copied | 1.0 |
| 61 | WakeSize | 0x104 | not copied | 0.5 |
| 62 | NumSamplesPerSpringX (int) | 0x108 | 0x0DC | 1 |
| 63 | NumSamplesPerSpringZ (int) | 0x10C | 0x0E0 | 1 |
| 64 | FlipOnLandEnable (BoolEnum) | 0x110 | 0x0F4 (byte = value≠0) | "False" |

Three of the defaults (0xD2D820, 0xDFDDE0, 0xDFDDC4) sit in `.data`. They were read from the dump and are probably never
written, but that is not checked (I).

**Ctor-initialised runtime fields** (P, 0x4465e0–0x4468e6): `+0xF8,+0xFC,+0x100,+0x104,+0x110,+0x114,+0x118 = 0`;
`+0x168 = 0` (byte); engine-curve table `+0x128 = 0.0` (xmm0 is still 0 at 0x44682e), `+0x140 = 1.0` (0xB9B664);
`+0x154 = 1.0`; `+0x108,+0x10C,+0x158,+0x240 = 0`; four spring records from +0x170 (stride 0x34) get two −100.0 floats
(0xBEAAE8) and a cleared byte; `+0x23C` = new contact listener (§B.4); hull setup `0x446930` (springs, plus
`setCenterOfMassLocal` = AABB centre + CenterOfMassOffset at 0x446b74–0x446bc3); `0x8D4C30(HullFriction)` on the body (I: set friction).
Activate also zeroes `+0x1C,+0x20,+0x24,+0x23C` and links the node at `+0x1C` into a list (0x4356fa–0x43573e).

---

## B. Input path

### B.1 Owner command handler `FUN_00435790` (P, `dis_435790.txt`)
It is in the boat owner vtable. Owner ctor `0x435460` writes vtable 0xBA9200 (0x435493). `0x435790` is the entry at 0xBA9334
(slot 77, `+0x134`), and activate `0x435660` is the entry at 0xBA9324 (slot 73). Owner `+0x140` = the boat actor (written
at 0x43570f). The record is `[ebp+8]`: `+4` = id, `+8` = float payload. **Every write lands directly in the actor
(`[owner+0x140] + off`). The payload is stored verbatim (`fld [edi+8]; fstp [...]`), with no negation, no `1−v` and no clamp.**

| command id | write | VA |
|---|---|---|
| `0x7D3B632C` | actor+0x0F8 = payload (**throttle**) | 0x43597a–0x435983 |
| `0x0490757F` | actor+0x0FC = payload (**brake / reverse**) | 0x43593e–0x435947 |
| `0x3483DBF1` | actor+0x100 = payload (**turn**) | 0x435813–0x43581c |
| `0x37086E0A` | actor+0x104 = payload (**handbrake**) | 0x435955–0x43595e |
| `0x6C5F1491` | actor+0xF8, +0xFC, +0x100, +0x104 = 0 (ClearControls) | 0x435991–0x4359c1 |
| `0x262E1E47` | position ping: reads render object `[owner+0x4c]→+0x38` (+0x150..0x15C, +0x110..0x118 + 3.0 (0xBA8990)), calls 0x8D5BA0 / 0x8D5B70; no drive state | 0x43582a–0x435931 |
| any id with payload ≠ 0 | wakes the body: `0x8DD630(body)` test, then `0x8DDA50` | 0x4357ae–0x4357da |

The roles "brake/reverse" and "handbrake" come from how §D/§E use +0xFC and +0x104 (P for the use, I for the name).
Owner getters (P): slot 53 `0x435360` returns +0xF8; slot 78 `0x435390` returns +0xFC; slot 79 (`+0x13C`) `0x4353C0`
returns `−0.0 − actor+0x158` (minus the rudder angle).

### B.2 How the inputs reach the drive code
There is no copy step. The applyAction functions read actor+0xF8/+0xFC/+0x100/+0x104 directly (P).
Actor offsets:
- raw throttle `+0xF8`; raw brake/reverse `+0xFC`; raw turn `+0x100`; raw handbrake `+0x104`
- smoothed engine state `e` = `+0x11C` (§D.2); smoothed steer state `s` = `+0x108` (§E.1); smoothed handbrake `hb` = `+0x10C` (§D.3)
- roll state `+0x110`, pitch state `+0x114` (§C); rudder angle `+0x158` (§E.4); in-water factor `W` = `+0x154` (§B.3)
- reversing flag `+0x168` (byte, §D.1).

### B.3 In-water factor W = actor+0x154 (P, springs `FUN_004477A0`, 0x447cf6–0x447dbb; spring internals are the other agent's)
`W_target = 1` if `0.25·Σ_springs q_i > 0` **and** `water_h(+0x160) > ground_h(+0x15C)`; otherwise 0. Here `q_i` is the
per-spring clamped-01 value accumulated in `[esp+0x20]` (0x447c90–0x447cae; 0 for a spring with no water sample).
W is smoothed with the §0.1 algorithm at gain 0.05 per 1/60 s (k = 0.95). Ctor value 1.0. The springs run **after** thrust
and steering in applyAction, so thrust and steering use the previous step's W (P, order in 0x447260).

### B.4 Contact listener at actor+0x23C (P)
Built by `0x446460`: 0x1C bytes, vtables 0xBAA310 (+0) and 0xBAA324 (+4), registered on the body through `0x8DD9E0` / `0x8DDDD0`.
`+0x10 = 1000.0` (0xDFDDC8), `+0x14 = 0`, `+0x18 = 0`. Vtable 0xBAA310 slot 0 = `0x4464D0` (`++[+0x18]`), slot 2 =
`0x4464E0` (`--[+0x18]`) (`vtbl_contactlistener_baa310.txt`). Following the Havok 5.5 hkpCollisionListener order, these
are contactPointAdded/Removed (I), so `+0x18` counts live contact points against any body, terrain included (I).
applyAction 0x44727f–0x4472b4 (P): `if count>0 { +0x14 += dt; +0x10 = 0 } else { +0x14 = 0; +0x10 += dt }`.
So `+0x10` = time since the last contact and `+0x14` = time in contact.

---

## C. Pre-step `FUN_00446BD0` (actor vtable slot 9, entry 0xBA9364) (P, `dis_446bd0.txt`)

**This function does not smooth the engine or steering.** The engine is smoothed in the curve function (§D.2), the steer
state and rudder in §E, the handbrake in §D.3. Arguments: `[ebp+8]` = dt (float), `[ebp+0xC]` = bool `full`; `ret 8`.

**When it runs** (I for the dispatch, P for the bodies): physics stepper `0x4036F0` → per substep `i` → `0x413F90(world)`.
That loads dt from `[0x117502C]` and calls `0x416AD0(dt, i)` at 0x41405e, then steps `[world+0x23C]` with the same dt
(0x8D6180 at 0x41407c). `0x416AD0` walks the list at `world+0x24C`, node `+8` = action, and calls `[vtbl+0x24](dt, i==0)`
(0x416ad7–0x416b0c). The node layout matches the actor's `+0x1C` node built at 0x43572d. So the pre-step runs **once per
physics substep, before the Havok step**, and `full` is true only on the first substep of the frame (`esi` = 0 at 0x4037db,
incremented at 0x403983).

Steps, in order:
1. `speedKmh`, `a`, `sM` as §0.3 (0x446cd1–0x446d53).
2. **Pitch state** `p = +0x114`. Target `Tp = (1 − hb(+0x10C))·throttle(+0xF8)` (0x446d61–0x446d6c):
   - if `Tp ≥ p`: `p = min(Tp, p + PitchUpSpeed(+0x6C)·dt)` (linear rise, 0x446d85–0x446d9b)
   - else: `p = smooth(p → Tp, k = PitchDownInertia(+0x70), dt)` (0x446d9d–0x446db9)
   - store +0x114 (0x446dd4).
3. **Roll state** `r = +0x110`: `r = smooth(r → (1 − HighSpeedSteerLoss(+0x50)·sM)·s(+0x108)·a, k = RollInertia(+0x68), dt)`
   (0x446dc9–0x446e16). It uses the steer state from the previous applyAction.
   RollFromTurning (+0x60) and PitchFromAcceleration (+0x64) are **not** read here. Hull setup `0x446930` turns them into
   per-spring coefficients through the sine table 0xCF2900 (index = angle·8192/2π + 0.5, masked 0x1FFF; 0x446a67–0x446b1c),
   and the springs then multiply those coefficients by `r` and `p` (0x447b72–0x447b93). That part belongs to the other agent.
4. If `full == 0`, return (0x446e12–0x446e1e).
5. (full only) ground height `+0x15C` from `0x4423A0` (−FLT_MAX 0xBEAA50 if the query fails); water height `+0x160` from
   waterline query `0x480440` at (pos.x, pos.y − 100, pos.z) (−FLT_MAX if it fails); `+0x164` = 1 − clamp01((aabbMax.y −
   water)/(aabbMax.y − aabbMin.y)) from the shape's world AABB (0x446ebe–0x446f21; P for the arithmetic, I that the two
   operands are max.y and min.y); then per-spring sampling for the 4 records at +0x16C (0x446ffb–0x447250, other agent).

Visual rudder: §E.4. Out-of-water timers: none here; the only timers are the contact timers in §B.4.

---

## D. Thrust `FUN_00447350` (`esi` = actor, `[ebp+8]` = dt; whole function 0x447350–0x447641) (P, `dis_447350.txt`)

### D.1 Reversing flag and speed ratio
```
fwd   = col2 (body+0x100..0x108)                       // local +Z, world space
up_y  = body+0xF4  (col1.y)
fwdKmh = (v·fwd)·3.6
revThresh = min(MaxSpeedReverse(+0x2C)·0.25, 10.0)      // 0xBBC7EC = 0.25, 0xB9C174 = 10
reversing(+0x168) = fwdKmh < −revThresh                 // fresh each step, no hysteresis (0x4473f0–0x44740f)
ratio = fwdKmh / (reversing ? −MaxSpeedReverse : MaxSpeed(+0x28));   ratio = min(ratio, 1)   // no lower clamp
```
(−0.0 at 0xBEAA2C is used for the negations.)

### D.2 Brake impulse (before the capsize gate) (0x447441–0x4474f9)
```
B = getMass · BrakeDrag(+0x40) · W(+0x154) · dt
if fwdKmh² > 4.0 (0xB97744):                           // |fwdKmh| > 2 km/h
    m = reversing ? +throttle(+0xF8)·B : −brake(+0xFC)·B
    wake body; applyLinearImpulse( m·(fwd.x, fwd.y, fwd.z, 0) )     // full 3D forward
```
Because the impulse includes mass, Δv = BrakeDrag·W·dt·input, independent of mass. BrakeDrag is a deceleration in m/s².

### D.3 Handbrake state hb = +0x10C (0x4474fb–0x447543)
`if raw(+0x104) > hb: hb = raw` (instant rise); `else hb = smooth(hb → raw, k = HandBrakeInertia(+0x9C), dt)`.

### D.4 Capsize gate (0x44754b–0x447553)
`if 0 > up_y: return`. No engine update and no thrust while upside down.

### D.5 Engine state and curve `FUN_004464F0` (`ecx` = actor+0x11C, args (u, ratio), `xmm2` = dt) (P, `dis_4464f0.txt`)
```
u = throttle(+0xF8) − brake(+0xFC)                     // fld [f8]; fsub [fc]  (0x447559–0x447564)
e(+0x11C) = clamp(smooth(e → u, k = EngineInertia(+0x148), dt), −1, 1)   // −1 = 0xDFDB5C
// piecewise-linear curve over ratio; table (pos,val): (+0x128=0,+0x12C R0) (+0x130 P1,+0x134 R1) (+0x138 P2,+0x13C R2) (+0x140=1,+0x144 R3)
i = 1 if ratio < P1; 2 if ratio < P2; else 3           // loop 0x446546–0x446562 (the last segment is never tested)
t = (ratio − pos[i−1]) / (pos[i] − pos[i−1])           // not clamped: ratio < 0 extrapolates segment 1
curve = (1−t)·val[i−1] + t·val[i]
torque = (e > 0) ? EngineTorque(+0x14C) : EngineReverseTorque(+0x150)   // picked by the sign of e, not by the reversing flag
out(+0x120) = |e| · curve · torque · 200.0             // 0xB984A8 = 43 48 00 00 → 200.0
+0x124 = ratio
```

### D.6 Speed cap and thrust impulse (0x447587–0x44763a)
```
if ratio >= 1 and u·fwdKmh >= 0: return               // cut only when pushing with the motion
collMul = (contact.+0x10 < 0.125 (0xBA904C)) ? EngineTorqueMultiAtCollision(+0xEC) : 1.0
S = out(+0x120) · collMul · (1 − hb) · W(+0x154) · u · dt
wake body; applyLinearImpulse( (S·fwd.x, 0, S·fwd.z, 0) )
```
- **Direction**: local +Z with Y zeroed and **not renormalised**, so thrust scales with the horizontal length of the forward
  vector (cos pitch) (P: 0x44759a `xorps xmm3`, stored into y at 0x447617).
- **Application**: linear impulse through the centre of mass (slot 18). It adds no torque. There is no point and no stern offset.
- **Mass**: none. Δv = S/mass, so heavier boats accelerate less. dt is multiplied explicitly, so this is a force `S/dt` (N).
- The sign comes from `u`. The magnitude carries `|e|·|u|`, which approaches u² at steady state.
- AirCtrl* fields are **not** read in thrust. There is no depth or submerged-fraction factor apart from W.

---

## E. Steering `FUN_00447F00` (`esi` = actor, `[ebp+8]` = dt; whole function 0x447f00–0x448204) (P, `dis_447f00.txt`)

### E.1 Steer state
```
stopThresh = min(MaxSpeedReverse·0.25, 10)            // the same threshold as reversing (0x447f06–0x447f2d)
dir = reversing(+0x168) ? −1 : +1                      // the flag thrust set this step
if 0 > up_y: return                                    // capsize gate (0x447fac–0x447fba)
k = (turn² < 1e-4 (0xB977F8)) ? SteerNoInputInertia(+0x98) : SteerInertia(+0x94)
s(+0x108) = smooth(s → turn(+0x100)·dir, k, dt)        // steering inverts when reversing (0x447fc0–0x44801c)
```

### E.2 Gain
```
stopped = speedKmh < stopThresh ? 1 : 0                // 3D |v|
eP = max(e(+0x11C), 0)
G = Steering(+0x30)·(1 − HighSpeedSteerLoss(+0x50)·sM)·a                        // not clamped: can go negative
  + LowSpeedSteering(+0x48)·eP·throttle(+0xF8)·(1 − hb)·(1 − a)
  + NoSpeedSteering(+0x44)·stopped
  + HandBrakeSteerBoost(+0xA0)·e·e·a·hb
```
(0x44802d–0x4480fe; the sum is formed at 0x448146–0x448158 in the order HB + Steering + LowSpeed + NoSpeed.)

### E.3 Application
```
air = (contact.count(+0x18) == 0) ? AirCtrlSteering(+0xB8)·0.1 : 0       // 0.1 = 0xB92B58
mix = W + (1 − W)·air                                                     // 0x448104–0x448137
Y = G · s · getMass · mix · 10.0 · dt                                     // 10.0 = 0xB9C174
wake body; applyAngularImpulse( (0·dt, Y, 0·dt, 0) )                     // world +Y axis, slot 20 (0x448172–0x4481b8)
```
- Axis: **world up** (0,1,0), not hull up.
- Scaled by **mass** (not inertia) and by dt; Δω = I_world⁻¹·(0,Y,0), so it depends on the hull's inertia tensor.
- In water W≈1, so mix ≈ 1. Airborne with no contacts and W→0, so mix → 0.1·AirCtrlSteering. Aground (contacts and W→0) gives no steering.
- The handbrake terms here are only HandBrakeSteerBoost and the (1−hb) factor on LowSpeedSteering. HandBrakeAntiSideDrag and
  HandBrakeMomentumKeep are in drag `FUN_00448210` (P, other agent's function, read only for these two terms):
  - AntiSideDrag: the side-drag vector `WaterDragSide·(v·col0)·col0` has its **x and z** scaled by `1 − HandBrakeAntiSideDrag·hb·a`
    (y unchanged; 0x44887f–0x4488fb). It is then applied with the other drags as `−mass·W·dt·Σ` (0x44897a–0x4489f0).
  - MomentumKeep: `K = |sideDragVec(after AntiSideDrag)|·HandBrakeMomentumKeep·mass·hb·dt·W`, applied as
    `applyLinearImpulse((K·col2.x, 0, K·col2.z, 0))`, always toward +forward (0x4489f2–0x448ab5).

### E.4 Visual rudder (0x4481ba–0x4481f7)
`+0x158 = smooth(+0x158 → VisRudderMaxAngle(+0xB0)·turn(+0x100)·dir, k = VisRudderInertia(+0xB4), dt)`. It uses the raw turn,
not `s`. The owner's slot 79 (`+0x13C`, `0x4353C0`) returns `−(+0x158)`. vehicle_code_map §1.4 says the boat/heli ring pump
`FUN_00540370` calls `vt+0x13C` for steering read-back, so that is the probable consumer (I; I did not read 0x540370).

---

## F. Step time
- applyAction `0x447260`: `dt = stepInfo+8` (`[ecx+8]` at 0x447275). If `dt < 1e-4` (0xB977F8), everything is skipped (0x44727d).
  Each sub-function receives dt as a stack float (P).
- Substeps (P, 0x4036f0–0x403990): for frame time `T ≥ 0.001` (0xB929D8) and byte `[0xD02172]≠0` (0x01 in the dump):
  `N = clamp(trunc(floor(T·59.999996 + 0.99)), 1, 3)` (0x407840 calls `floor` 0xA73A62, named from the import thunk in the
  annotate export; 0x9EE780 = cvttsd2si). If the byte is 0, N = 1. Substep dt = T/N → `[0x117502C]` (0x4037b6). So dt ≈ 1/60
  down to 20 fps, and larger than 1/60 below that.
- That stepInfo dt equals `[0x117502C]` is I: the same value is passed to `0x8D6180(world, dt)` right after the pre-step.
- Nothing in thrust or steering assumes 1/60. Every impulse is multiplied by dt explicitly, and every smoother integrates
  dt in 1/60 steps (§0.1). The only fixed-step quantities are the smoother's k values, which are defined per 1/60 s.

---

## G. Axes and signs
- Forward = body rotation column 2 = local **+Z** (thrust 0x447366–0x447376, drag uses `WaterDragFwd` with col2) (P).
  Side = col0 = local +X (`WaterDragSide` with col0, 0x4483ff–0x448429) (P). Up = col1 = local +Y (capsize gate on col1.y) (P).
- Positive `s·G` gives a positive angular impulse about world +Y (P). Under the standard rotation formula that Havok's
  integrator uses, +ω_y carries +Z toward +X (I; Havok's integrator was not read). +X is the boat's **left**: the Speed
  Boat's node `hp_seat_fl` `0xD721FC8C` is at (0.65, 0, −2.00) and `hp_seat_fr` `0xD6EBE292`, the driver's, at
  (−0.65, 0, −2.00) (P, `mercs2_probe hier --model 0xB1EB099F`), and retail's projection puts +X on the left of the
  screen when looking along +Z (viewport `+0xB30`, `m00` = −1.92). So **positive turn yaws left**, which is also what
  the driver's animation says: a Turn value over 0.1 posts `SteerLeft45`
  ([`rider_animation`](../rider_animation/README.md) §3.2).
- Turn payload sign at the producer (player stick or AI) is **NOT DETERMINED**: the producer of `0x3483DBF1` was not read.
  The boat handler stores it raw; the car and tank handlers negate it (memory note; not re-read here).
- When reversing, `s` and the rudder target are multiplied by −1, so the same stick input yaws the other way when going astern (P).

---

## NOT DETERMINED / risks
1. Sign of the turn payload at its producers (player input map, AI states, Lua); `0x538D20` call sites were not read.
2. That the stepInfo dt passed to applyAction equals the substep dt `[0x117502C]` (I).
3. Names for `0x8DDA50` (activate), `0x8DD9E0` / `0x8DDDD0` (listener registration) and the listener slot roles are I. Their
   behaviour (++/-- count) is P.
4. `+0x164` operand identities (AABB max.y/min.y) are I; `+0x15C` = ground height and `+0x160` = water height are I from
   use (0x447300 compares them; the springs gate W on water > ground).
5. `q_i` in the W target is the springs' per-spring value; it is defined in the other agent's spec.
6. `.data` defaults and constants (0xD2D820, 0xDFDDE0, 0xDFDDC4, 0xDFDDC8, 0xD02172, 0xBCD278, 0xD69BA4) were read from the
   dump; whether anything writes them at runtime was not checked.
7. `+0x240` (zeroed in the ctor) and owner slot 25 `0x4359E0` (reads `e` = +0x11C, probably engine audio) were not followed.

## Where my read disagrees with the existing notes
- **vehicle_code_map.md §1.1 / §1.4 / §1.5, and command.rs**: the boat handler is `0x435790`, not `0x441900`. It writes
  **actor** +0xF8 throttle, +0xFC brake/reverse (`0x0490757F`), +0x100 turn, +0x104 handbrake (`0x37086E0A`), stored
  **verbatim**; it is not "+0x28 / +0x2C as 1.0−v". Clear zeroes all four, `0x262E1E47` is handled, and a nonzero payload
  wakes the body. command.rs `handle_command_boat` is wrong on the 1−v transform and is missing the two channels. Its heli
  branch cites `0x435790`; the heli handler is `0x4396C0` (vtable entry 0xBA9854), and I did not verify its offsets.
- **vehicle_code_map.md §3 row A**: "ctor copies the 0x114 boat block" → it remaps field by field (table §A).
  "4 wake-emitter subrecords @+0x168" → +0x168 is the reversing byte and the spring records start at +0x16C.
  "in/out-water timer @+0x23c" → +0x23C points to a contact-point listener (§B.4).
- **vehicle_code_map.md §4 Boat**: "in/out-water timers (+0x23c)" → contact timers. The in-water quantity is W = +0x154 (§B.3).
- **Memory note (tank-boat-heli-plane)**: "no thrust once the ratio reaches 1" → only when `(throttle−brake)·fwdKmh ≥ 0`.
  "Mass never enters" holds for thrust, but brake and steering impulses are multiplied by mass. In the steering-gain formula
  the LowSpeedSteering term uses `max(e,0)` and has a `(1−hb)` factor; "stopped" means `speedKmh < min(MSR/4,10)`; the
  steer state target is `turn·(reversing ? −1 : 1)`. "Not copied: … VisRudderBone" is wrong: it is copied to +0xAC
  (0x446770). "Rudder consumer not found": owner slot 79 returns −rudder (§E.4).
- **Task anchors**: the pre-step does not smooth the engine or steering (§C). Thrust direction is horizontal-projected forward,
  not full forward (§D.6).
- **water_code_map.md §5** lists `InWaterT`, `WaterDepth` and `ShallowT` as boat tunables. The PC `_BoatPhysics` loader asks
  for none of these names (65 fields, §A).
