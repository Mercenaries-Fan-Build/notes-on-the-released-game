---
status: current
evidence: proven
---

# Havok 5.5 contact solve in pc-v10: contact points → impulses on the body

Read of 2026-11-25. Scope: one dynamic rigid body (box-inertia motion, mass 8000, the Speed Boat class) against one fixed
body, discrete PSI contact. Everything between "the narrowphase hands the contact manager a contact point" and "the solver
hands the integrator a velocity accumulator". Narrowphase (N1, N2) and step driver / integrator / velocity clamps (S2) are
out of scope except for the interface on both sides.

Sources:
- exe `game-files/canonical/dumps/mercs2_unpacked.exe` (pc-v10, file offset = VA − 0x400000);
- Ghidra export `output/_ghidra_exports/pc-v10.functions.jsonl`;
- captures `game-files/memory-dumps/updated-chris-exports/20261103_new-game-first-mission-start.dmp` ("first-mission") and
  `20261021_chris-jacobs-flying-winch.dmp` ("winch").

The `s1/` files this page names (decomp extracts, objdump listings, capture reads) were working files and are not kept;
`objdump -d` of the image and `mercs2_probe dump-read` of the captures give them again. Every listing is
named after the address it covers (`s1/dis_a209b0.txt`, `s1/dis_solver.txt` = 0xA262F0–0xA36000, `s1/dis_cmgr.txt` =
0x8D3A70–0x8D4900, `s1/dis_8dcf30_tail.txt`, …).

Grades: **P** PROVEN (verified this run: instruction address, capture read, or command). **I** INFERRED (reasoned, not
checked). **S** SPECULATIVE. **HK** recalled Havok knowledge, used only for names, never as a fact about this binary.

---

## 0. Two facts that govern every formula below

### 0.1 This code is x87, not SSE — P

The contact manager, the deferred new-point pass, the Jacobian builder `FUN_00A209B0` and the solver `FUN_00A2F840` are
x87 stack code (`fld`/`fmul`/`fstp dword`). See `s1/dis_a209b0.txt`, `s1/dis_solver.txt`, `s1/dis_cmgr.txt`. The brief's
"scalarised SSE" does not apply to these functions.

x87 precision control was read from every thread CONTEXT in the first-mission capture (`s1/fpu_cw.txt`, script inline in
the session):
- 27 threads, including the main thread 15824: FPU CW = **0x027F** (53-bit precision, round-to-nearest);
- the render thread 11456: 0x007F (24-bit, the D3D9 default).

**Port rule (P for the code, I for the thread):**
- every x87 arithmetic op is an **f64** op;
- every `fstp dword` / `fst dword` rounds to **f32**;
- loads from `dword` memory are exact; `qword` constants are f64.

In the pseudocode, `f32(…)` marks a store to memory (a spill). Anything inside one `f32(…)` stays on the x87 stack.

Which thread runs the island solve is **NOT DETERMINED** (the CW was read at the pause, not during a step). It matters
only if that thread is the render thread. `_CIsqrt` (import via `0x9EE730 → [0xB053AC]`) is x87 `fsqrt` under the same CW
(I). `fistp` uses RC=0: round-half-to-even (P from CW).

### 0.2 For the boat, the README's impulse seed does not run where the README says — P

`FUN_008D3DA0` (addContactPoint) seeds `props.impulse` only when **both** entities have collisionListeners count
(u16 entity+0x1F4) == 0 and restitution == 0 (`cmp word [..+0x1f4],0; ja 0x8d403f` at 0x8D3FDA / 0x8D3FE4).

The boat has one listener (count 1 at +0x1F4: first-mission body 0x1EBB8000; winch body 0x1DF9D000, `s1/winch_boat.txt`).
So for the boat:
1. addContactPoint takes the branch at 0x8D403F instead. It posts a callback request:
   `output.constraintOwner->vtable[+0x14](mgr+0x38, 1)`.
2. The seed is applied later, in the deferred new-point pass (§3), with the velocities current at Jacobian-build time.
3. That seed carries an extra `(1+e)` factor and also writes `props.solverData` and `props.dataA` (§3).

The README's formula `−0.2·v_rel·n/(invMassA+invMassB+1e-10)` is correct only for listener-free pairs.

---

## 1. Data layouts

### 1.1 `hkpSimpleConstraintContactMgr` (0x80 bytes; ctor `FUN_008D4640`, vtable 0xB589D4) — P

Layout from the ctor at 0x8D4640–0x8D46D1 plus the first-mission capture of mgr 0x1EB7EF80 (`s1/cap_mgr.txt`):

| Off | Field | Evidence / value |
|---|---|---|
| +0x00 | vtable 0xB589D4 | ctor 0x8D4666 |
| +0x04 | u16 memSize 0x80, +0x06 u16 refcount 1 | capture |
| +0x08 | 0 | ctor 0x8D465F |
| +0x0C | world | ctor 0x8D469D (capture 0x20007800) |
| +0x10 | u16 **reservedContactPoints** | ctor zeroes; `FUN_008D3A70` adds (8-bit add, 0x8D3A9A) |
| +0x12 | u16 **skipProcessCallbacks** (countdown) | §2.5 |
| +0x14 | embedded `hkpSimpleContactConstraintData`, vtable 0xB58998 | ctor `FUN_008DD3C0(this+0x14, …)` |
| +0x20 | idMgr hkArray<u8> data (id → point index, 0xFF = free) | `FUN_008D4260` / `FUN_008D4280` |
| +0x24 / +0x28 | idMgr size / capacity\|flags (capture 0, 0x80000008) | capture |
| +0x38 | constraintData.m_constraint = &mgr+0x44 | capture 0x1EB7EFC4 |
| +0x3C | **atom** pointer (hkpSimpleContactConstraintAtom, separately allocated) | every slot |
| +0x40 | atom byte size (copy of atom.sizeOfAllAtoms) | `FUN_008DCE10` 0x8DCF0F |
| +0x44 | embedded `hkpConstraintInstance` (0x2C; vtable 0xB5971C in capture) | ctor `FUN_008E4980(this+0x44,1)` |
| +0x50 | instance.data = &mgr+0x14 | ctor 0x8D4697 |
| +0x58 / +0x5C | instance.entities[0] = **A**, [1] = **B** | ctor 0x8D4684 / 0x8D469A |
| +0x60 | instance.priority (u8) = qualityInfo[table[qA][qB]].u16 at +0x58 | ctor 0x8D46A0–0x8D46C6 (boat/terrain = 1 PSI, README §1.4) |
| +0x6C | instance.internal → the 0x30-byte constraint-internal record (§1.3) | winch capture |

First-mission, boat: A = 0x1EBB8000 (boat), B = 0x1EC16A00 (terrain cell), internal = 0 (no points, not in the solver).

### 1.2 Contact manager vtable 0xB589D4 — P (pointers `s1/consts_a.txt`; bodies `s1/dis_cmgr.txt`)

| Slot | Address | Role (evidence) |
|---|---|---|
| 0 | 0x402640 | scalar deleting dtor (thunk) |
| 1 | `0x8D45D0` | calcContentStatistics (string table 0xB58988/0xB5897C) |
| 2 | 0x88C600 | (not read; shared helper) |
| 3 | `0x8D3DA0` | **addContactPoint** (§2.2) |
| 4 | `0x8D3A70` | **reserveContactPoints**(int n) (§2.1) |
| 5 | `0x8D4180` | **removeContactPoint**(id, constraintOwner) (§2.4) |
| 6 | `0x8D42F0` | **processContact**(cdA, cdB, input, processOutput) (§2.5) |
| 7 | `0x8D3CA0` | **addToi** (ToI event; calls props setup with maxPoints 7 and fires the ToI callback; not used for PSI boat contact, README §1.4) |
| 8 | `0x8D3B40` | **removeToi** (fires removed callbacks with id 0xFFFF) |
| 9 | 0x4027E0 | (not read) |
| 10 | `0x8D4280` | getContactPointProperties(id) |
| 11 | `0x8D4260` | getContactPoint(id) |
| 12 | `0x8D42E0` | getAllContactPointIds → `0x8D49F0` |
| 13 | 0x6D5640 | (not read; type query) |
| 14 / 15 | `0x8D3AB0` / `0x8D3AC0` | forward to constraintData vtable +0x30 / +0x34 |

The slot names are HK; the behaviour in each row is P from the listed body. Also: dtor body `0x8D46E0` (removes the
constraint from the world if points remain, then destroys the data), constraint-data dtor `0x8D4A40`, and the
"create agent mgr" factory `0x8D4740` (allocates 0x80, calls the ctor).

### 1.3 Constraint-internal record (0x30 bytes; island master list) — P

Read by `FUN_008FD040` at 0x8FD188 onward (`s1/fns/fn_008fd040.txt` lines 188–247) and by the deferred pass (0x8DD3A4).

| Off | Field |
|---|---|
| +0x00 | constraint instance |
| +0x04 / +0x08 | entity A / entity B |
| +0x0C | atoms pointer (→ the contact atom for a contact constraint) |
| +0x10 | u16 atoms size |
| +0x12 | u8 **callback request flags**: bit0 = new-contact-point pass (§3), bit2 = data vtable +0x28 callback |
| +0x13 | u8 priority (< 3 → built in the PSI pass) |
| +0x1C | runtime pointer |

Winch capture, boat mgr 0x1C8A6C80: internal 0x1CBE9E30, flags +0x12 = 0, priority 1 (`s1/atoms_winch.txt`).

### 1.4 `hkpSimpleContactConstraintAtom` (reflected size 0x30 header) — P

Header from the reflection (`s1/classes_s1.txt`, class 0xE783DC). Body layout from the accessors `0x8D4260` / `0x8D4280`
and the allocator `0x8DCE10`.

| Off | Field | Boat (first-mission 0x1EB7EF00) |
|---|---|---|
| +0x00 | u16 type = 0x16 TYPE_CONTACT | 0x16 |
| +0x02 | u16 sizeOfAllAtoms | 0x70 |
| +0x04 | u16 **numContactPoints** | 0 |
| +0x06 | u16 **numReservedContactPoints** (capacity) | 1 |
| +0x08 / +0x09 | u8 numUserDatasForBodyA / B | 0 / 0 |
| +0x0A | u8 contactPointPropertiesStriding | 0x14 |
| +0x0C | u16 **maxNumContactPoints** | 256 |
| +0x10 | info.flags u16: bit2 = rolling radius must be recomputed (set by alloc 0x8DCE1A and by remove 0x8D4161 `or 5`; cleared in §6.6); bit0 set by remove (reader not found) | 0 |
| +0x12 | info.index u16 = **friction axis index** into the identity table 0xBF65A0 (0..2; 3 = none yet) | 3 |
| +0x14 | info.data[0] f32 = **rolling radius** (cached) | 0 |
| +0x18..+0x2C | info.data[1..6] = friction **solver results**: (λt0, rhs0, λt1, rhs1, λroll, rhsRoll) — §8 | 0 |
| +0x30 + 32·i | **hkContactPoint[i]** {position.xyzw, separatingNormal.xyz, distance} | — |
| +0x30 + 32·numReserved + stride·i | **properties[i]** (§1.5) | — |

Point records are 32 bytes:

| Off | Field |
|---|---|
| +0x00 | position xyz, w (w = whatever the narrowphase wrote; winch shows small values) |
| +0x10 | normal xyz |
| +0x1C | distance |

The Jacobian builder reads position at +0x00..+0x08, normal at +0x10..+0x18 and distance at +0x1C (0xA20AB1–0xA20AC4;
pointer `ecx = atom+0x48`). The normal sense is "relative velocity (vA − vB)·n > 0 separates" for the A/B of the
constraint instance (§6.2, I from the sign of every row).

### 1.5 Contact point properties (stride 0x14 + 4·(udA+udB)) — P

| Off | Type | Field | Written by |
|---|---|---|---|
| +0x00 | f32 | **impulseApplied** (normal impulse summed over the last solve; seed on creation) | alloc 0 (0x8DCE5C); seed §2.2/§3; export §8 |
| +0x04 | f32 | **solverData** (position-error memory) | alloc 0 (0x8DCE63); seed §3; export §8; read by the rhs §6.3 |
| +0x08 | u32 | userData = 0 | addContactPoint 0x8D3ED4 |
| +0x0C | u8 | friction, **hkUFloat8 index** into the table at 0xB13380 | `FUN_008D47F0` via the encoder `FUN_0043D080` |
| +0x0D | u8 | restitution × 128 (`fistp`) | `FUN_008D47F0` 0x8D486A |
| +0x0E | u8 | maxImpulse, hkUFloat8 index, 0 = unlimited | `FUN_008D47F0` 0x8D4871 writes 0 |
| +0x0F | u8 | flags: bit0 = new (cleared by §3), bit1 = paired with the previous point | alloc 0x8DCE68 / 0x8DCE79; §3 0x8DD377; remove 0x8D40E7 |
| +0x10 | f32 | **dataA** (penetration memory, clamped ≤ −FLT_EPSILON by §6.3) | non-listener addContactPoint 0x8D4030; §3; §6.3 |
| +0x14.. | u32[] | per-body user datas | `FUN_008D47F0` tail |

**Correction to README §2:** friction is stored as a byte index, not a float. The decoded friction is
`DAT_00B13380[byte]`.

### 1.6 Velocity accumulator (0x80 bytes) — layout used here; building it is S2's (`FUN_008EDCF0`)

Accumulator 0 of every island buffer is the **fixed accumulator**: `FUN_008FD040` 0x8FD127–0x8FD157 zeroes 0x80 bytes and
sets type 1, flag 1. Each entity's solverData (entity+0x90) is set to (k+1)·0x80 (0x8FD15F). Header indices are
solverData >> 7 (0x8FD228).

| Off | Field | Used by |
|---|---|---|
| +0x00 | u8 type: 0 dynamic, 1 fixed/keyframed-as-fixed, 2 (motion type 9), 3 = end marker | solver prologue / second loop |
| +0x01 | u8 matrixIsIdentity (fixed and keyframed: 1; dynamic: 0) | Jacobian builder (skip the rotation) |
| +0x04 | u32 deactivation class (motion +0xBE = entity +0x18E) | second loop index; integer store `mov [esi-0x64], ecx` at 0x8EDF5A / 0x8EE185 (P) |
| +0x10 | linear velocity xyzw (damped by S2's builder) | solver |
| +0x20 | angular velocity in the "core" frame (built as M·ω) | solver |
| +0x30 | invInertia xyz (diagonal, core frame), invMass w | builder + solver |
| +0x40 | COM at step start; **reused by the solver as Σ-linear-velocity** (zeroed in the prologue) | builder / solver / export |
| +0x50..+0x7C | 3×3 core-from-world rotation, columns at +0x50 / +0x60 / +0x70; **+0x50..+0x5F reused as Σ-angular-velocity** | builder / solver / export |

The rotation is applied as `out_i = c50[i]·x + c60[i]·y + c70[i]·z` (0xA20B86–0xA20BDC; the add order is in §6.2).

### 1.7 solverInfo (world+0x1A0) and stepInfo (world+0x190) — P (setter `FUN_008D5F80`, `FUN_008F72C0`; capture `s1/cap_si.txt`)

| si off | Field | Captured value (hex) |
|---|---|---|
| +0x00 | one | 1.0 |
| +0x04 | tau | 0.9 (0x3F666666) |
| +0x08 | damping | 1.1 (0x3F8CCCCD) |
| +0x0C | frictionTau | 0.45 |
| +0x10 | globalAccelerationPerSubStep | (0, −0.037384, 0, 0) |
| +0x20 | globalAccelerationPerStep | (0, −0.149518, 0, 0) |
| +0x30 | integrateVelocityFactor ×4 | 0.818182 (0x3F51745C) |
| +0x40 | invIntegrateVelocityFactor ×4 | 1.222222 (0x3F9C71C8) |
| +0x50 | dampDivTau | 1.222222 |
| +0x54 | tauDivDamp | 0.818182 |
| +0x58 | dampDivFrictionTau | 2.444444 |
| +0x5C | frictionTauDivDamp | 0.409091 (0x3ED1745C) |
| +0x64 + 0x1C·k | deactivation record k (7 f32) | class 2 = {11.1111, 12.3457, 0.968, 0.05, 0.0004, 0.0064, 0.00025} |
| +0x10C | deltaTime (substep) | 0.0041533 (0x3B881800) |
| +0x110 | invDeltaTime | 240.775 (0x4370C674) |
| +0x114 | numSteps (int) = solver iterations | 4 |
| +0x118 | numMicroSteps (int) | 1 |
| +0x11C | invNumMicroSteps | 1.0 |
| +0x120 | invNumSteps | 0.25 |

stepInfo: +0 startTime, +4 endTime, +8 deltaTime 0.016613, +0xC invDeltaTime 60.1938.

### 1.8 Constraint query-in `q` (job+0x80) — P (setter `FUN_008F4590` = 0x8F4590–0x8F4609, called from `FUN_00900A00` 0x900A6C with `ecx = job+0x80`)

| q off | Value |
|---|---|
| +0x00 | si.deltaTime |
| +0x04 | si.invNumMicroSteps · si.deltaTime |
| +0x08 | si.invDeltaTime |
| +0x0C | step.deltaTime (frame) |
| +0x10 | step.invDeltaTime |
| +0x14 | si.invNumSteps |
| +0x18 | **frictionMaxFactor** = si.invNumSteps · si.invNumMicroSteps (0.25) |
| +0x1C | **rhsFactor** = si.tauDivDamp · si.invDeltaTime |
| +0x20 | **virtMassFactor** = si.damping (1.1) |
| +0x24 | **frictionRhsFactor** = si.frictionTauDivDamp · si.invDeltaTime |
| +0x40 / +0x44 | si.tau / si.damping |

Per constraint, `FUN_008FD040` sets (0x8FD222–0x8FD230):

| q off | Value |
|---|---|
| +0x30 / +0x34 | accA / accB pointers |
| +0x38 / +0x3C | entityA+0xE0 / entityB+0xE0 |
| +0x48 | internal[0] = the instance |
| +0x4C / +0x58 | runtime |
| +0x50 / +0x54 | accumulator indices A / B |

All `q` products are single f32 multiplies of f32 inputs; operand order does not change the bits. The values are P (code)
× P (captured inputs).

### 1.9 Solver schema stream (written by `FUN_00A209B0`, read by `FUN_00A2F840` and `FUN_00A3CE20`) — P

The opcode is the byte at record+0. For row records that byte overlaps the low mantissa byte of `lin.x`: see §6.1.

Record types used by this path:
- `0x01` header (16 B);
- `0x02` goto (16 B, +4 = byte offset; written by `FD040` when a buffer fills);
- `0x00` end;
- `0x0F` single contact (48 B);
- `0x11` single contact with maxImpulse (48 B);
- `0x13` contact pair (48 + 64 = 112 B);
- `0x15` 2-D friction (112 B);
- `0x16` 2-D friction + rolling (144 B).

The elemTemp floats consumed per opcode come from the table `DAT_00CE0444` (file bytes in `s1/consts_b.txt`):

| Opcode | elemTemp floats |
|---|---|
| 0x0F / 0x10 / 0x11 / 0x12 | 1 |
| 0x13 / 0x14 | 2 |
| 0x15 | 3 |
| 0x16 | 4 |

Full solver jump table 0xA362F0 (`s1/jt.txt`):

| Opcode | Case address |
|---|---|
| 0 | 0xA35430 |
| 1 | 0xA2F9D3 |
| 2 | 0xA35372 |
| 3 | 0xA2F9E8 |
| 4 | 0xA3542F |
| 5 | 0xA33426 |
| 6 | 0xA3378E |
| 7 | 0xA3423F |
| 8 | 0xA33E87 |
| 9 | 0xA347B0 |
| 0xA | 0xA34F0F |
| 0xB | 0xA33214 |
| 0xC | 0xA327F3 |
| 0xD | 0xA32593 |
| 0xE | 0xA32D78 |
| **0xF / 0x10** | **0xA30AD1** |
| **0x11 / 0x12** | **0xA30E20** |
| **0x13 / 0x14** | **0xA2F9FE** |
| **0x15** | **0xA31E85** |
| **0x16** | **0xA31590** |
| 0x17 | 0xA35262 (mass-changer write) |
| 0x18 | 0xA35299 |
| 0x19 | 0xA3542F |
| 0x1A | 0xA3537A → `FUN_00A262F0` |
| 0x1B | 0xA353B3 → `FUN_00A269D0` |
| 0x1C | 0xA353F1 → `FUN_00A28F30` |

The contact path uses only the bold rows plus 0 / 1 / 2. **The leaf solvers `FUN_00A262F0`, `FUN_00A269D0` and
`FUN_00A28F30` are joint rows and are not used.** P from the A209B0 writes, the jump table and the case bodies.

### 1.10 Constants — width from the instruction, value from the exe (`s1/consts_a.txt`, `consts_b.txt`, `consts_c.txt`)

| VA | Load | Value | Use |
|---|---|---|---|
| 0xBEAA68 | qword | 1.1920929e-7 (FLT_EPSILON) | K += eps; opcode-byte add (§6.1) |
| 0xCE0404 | dword | 1.0 | rhs: A = 1.0·frameDt |
| 0xCE0408 | dword | 0.05 | rhs: B = −0.05·dataA |
| 0xBEAABC | dword | −1.1920929e-7 | dataA clamp |
| 0xB5AB50 | qword | 0.99 | pair coupling factor; maxImpulse breach test |
| 0xB59D28 | qword | 0.9999 | friction-normal choice |
| 0xB57F98 | qword | 0.1 | friction-normal choice; axis re-pick |
| 0xB59C18 | qword | 0.9 | degenerate-normal test |
| 0xBEA968 | qword | 0.0 | placeholder product |
| 0xBEAB0C | dword | 1e-6 | rolling radius minimum |
| 0xB6D6C0 | qword | 1e6 | velocity sanity bound |
| 0xB58938 | qword | 1/128 | restitution decode |
| 0xB58958 | qword | −0.2 | seed factor |
| 0xB58960 | qword | 1e-10 | seed denominator eps |
| 0xB59210 | qword | −1.3 | seed solverData factor |
| 0xB58FD0 | dword | 0.3 | restitution threshold |
| 0xBEB7B8 | qword | 128.0 | restitution encode |
| 0xB13380 | dword[256] | hkUFloat8 table (0, 0.01, 0.02, …) | friction / maxImpulse |
| 0xBF65A0 | dword[16] | identity (1,0,0,0) (0,1,0,0) (0,0,1,0) (0,0,0,1) (runtime read `s1/cap_bf65a0.txt`) | friction axes; NaN reset |
| 0xB132F0 | dword[4] | 0 | fixed-body "gravity" in the second loop |

---

## 2. Contact manager functions

### 2.1 reserveContactPoints `FUN_008D3A70` — P

```
reserve(n:int) -> int:
  if atom.numContactPoints + n + mgr.reserved > atom.maxNumContactPoints - 2: return 1      // 0x8D3A8C (signed jle)
  mgr.reserved = u16(u8(u8(mgr.reserved) + u8(n)))                                         // 8-bit add 0x8D3A9A
  return 0
```

### 2.2 addContactPoint `FUN_008D3DA0` (cdA, cdB, input, output, gskCache, cp) — P (asm 0x8D3DA0–0x8D405F)

```
if atom.numContactPoints + mgr.reserved > atom.maxNumContactPoints - 2: return 0xFFFF       // 0x8D3DC5 jg
if atom.numContactPoints == 0: output.constraintOwner->vtable[+0xC](&mgr.instance)          // add constraint to island
id, cpDst, props = allocateContactPoint(&mgr.data, output.constraintOwner)                  // FUN_008DCE10, §2.3
cpDst[0..7] = cp[0..7]                                                                      // 32 bytes, exact copy
X = setupProperties(cdA, cdB, 10000, props)                                                 // FUN_008D47F0, §2.6; returns entity(cdA)
Y = mgr.A ^ mgr.B ^ X                                                                       // the other entity
vX = X.pointVelocity(cp.pos); vY = Y.pointVelocity(cp.pos)                                  // FUN_00412710 (S2 / not read)
d = f32(vX - vY) per component                                                              // 0x8D3E76–0x8D3EA9
projVel = f32( (n.y*d.y + n.x*d.x) + n.z*d.z )                                              // 0x8D3EAD–0x8D3EC6
props.impulse = 0; props.userData = 0                                                       // 0x8D3ECC / 0x8D3ED4
event = {cdA, cdB, type=1, ?, cp, gskCache, props, projVel, status=0, mgr, input, output, id, delay=0}
world.fireContactPointAdded(event)                                                          // FUN_008EA570
if X.listeners  != 0: X.fireContactPointAdded(event)                                        // FUN_008F4D80
if Y.listeners  != 0: Y.fireContactPointAdded(event)
if event.status == 1: this->removeContactPoint(id, output.constraintOwner); return 0xFFFF   // 0x8D3F7A
mgr.skipProcessCallbacks = event.delay                                                      // 0x8D3FAF
e = f32( f64(u8 props.restitution) * (1/128) )                                              // 0x8D3FBB–0x8D3FC5
if e == 0 and X.listeners == 0 and Y.listeners == 0:                                        // 0x8D3FCD–0x8D3FEC
   k = f32( 1 / ( f64(f32(Y.invMass + X.invMass)) + 1e-10 ) )                               // 0x8D3FEE–0x8D4011
   props.impulse  = f32( (k * -0.2) * projVel )                                             // 0x8D4015–0x8D4023
   props.solverData = 0.0                                                                   // 0x8D4029 (the 0.0 left on the stack)
   props.dataA    = cp.distance                                                             // 0x8D4030
   return id
else:
   output.constraintOwner->vtable[+0x14](mgr+0x38, 1)                                       // callback request bit0, 0x8D403F
   return id
```

For the boat this is the `else` branch (§0.2). Then `props.dataA` keeps the allocator's value. The allocator does not write
+0x10, so the deferred pass (§3) supplies it. I: the slot is reused memory until then.

### 2.3 allocateContactPoint `FUN_008DCE10` (on mgr+0x14) — P

```
atom.info.flags |= 4                                                                        // rolling radius dirty
n = atom.numContactPoints
atom = growAtom(atom)    // FUN_008F51E0: may reallocate; numContactPoints becomes n+1 (I: the counter write is inside it, not read)
cp    = atom + 0x30 + 32*n
props = atom + 0x30 + 32*atom.numReserved + stride*n
props.impulse = 0.0; props.solverData = 0.0; props.flags = 1
if n > 0 and (prevProps.flags & 2) == 0 and prevProps.maxImpulse == 0: props.flags = 3      // pair with the previous point
id = idMgr.newId(n)                                                                         // FUN_008DD460 (not read)
```

So points pair as (0,1), (2,3), …. A point after a maxImpulse point, or after an already-paired point, starts a new pair.

### 2.4 removeContactPoint `FUN_008D4180` (id, owner) and the atom-level removal `FUN_008D4070` / `FUN_008D4930` — P

```
idx = idTable[id]; props = (idx == 0xFF) ? null : properties[idx]
world.fireContactPointRemoved; A/B entity listeners fireContactPointRemoved                // FUN_008EA6D0 / FUN_008F4EE0
remaining = data.removePoint(id):                                                           // FUN_008D4070
    idx = idTable[id]; idTable[id] = 0xFF
    shiftDown(atom, idx)        // FUN_008D4930: numContactPoints--, points idx+1.. and their properties move down by one (order kept)
    properties[idx].flags &= ~2 // the point that slid into idx loses its pair bit (0x8D40E7)
    atom = shrinkAtom(atom, 1)  // FUN_008F5280
    idTable entries > idx are decremented (FUN_008D47C0)
    atom.info.flags |= 5
    return numContactPoints_before - 1
if remaining == 0: owner->vtable[+0x10](&mgr.instance)                                      // constraint leaves the island
```

### 2.5 processContact `FUN_008D42F0` (cdA, cdB, input, output) — P

```
if mgr.skipProcessCallbacks == 0:
    delay = min(entity(cdA).processContactCallbackDelay(+0x96), entity(cdB).…)             // u16 compare 0x8D4344
    build event (point pointers looked up by id), fire world (FUN_008EA780) and entity (FUN_008F4F90) process callbacks
    mgr.skipProcessCallbacks = delay
else:
    mgr.skipProcessCallbacks -= 1
// processOutput layout (0x8D440A–0x8D4448): +0x00 = end pointer, entries start at +0x10, 0x30 bytes each:
//   entry+0x00 hkContactPoint (32 B), entry+0x20 u32 contactPointId
for each entry e in [output+0x10, *output):
    atom.cp[idTable[e.id]] = e.point                                                        // 32-byte copy, 4× unrolled loop 0x8D4443
```

Properties are **not** touched by processContact. Persistence across steps is therefore:
- impulse, solverData, dataA, friction byte, flags;
- atom.info (axis, radius, friction results).

Only position / normal / distance are refreshed from the narrowphase. The boat's +0x96 is 0 (README §6), so its process
callbacks fire every step.

### 2.6 setupProperties `FUN_008D47F0` — P (asm `s1/dis_cmgr.txt` 0x8D47F0–0x8D492A)

```
mu   = f32( sqrt( f64(f32(fB * fA)) ) )         // fld [B+0x84]; fmul [A+0x84]; fstp; fld; _CIsqrt; fstp
props.friction = ufloat8_encode(mu)            // FUN_0043D080
r    = f32( sqrt( f64(f32(rB * rA)) ) )
props.restitution = u8( fistp( f64(f32(r * 128.0)) ) )   // f32 store, then reload and fistp, RC nearest-even
props.maxImpulse = 0
copy per-body user datas into props+0x14..
return entity(cdA)                              // walks cdA's parent chain to the root
```

**hkUFloat8 encoder `FUN_0043D080` — P.** Its first instruction is SecuROM-spliced (0x43D08B). `mercs2_probe splice-emulate`
shows the stolen instruction is `cmp edi, dword [0xB13580]` (gadget 0x50CCBD, then back to 0x43D091; `s1/emu_43d08b.txt`,
`s1/dis_50ccbd.txt`).

```
encode(x):   // integer compares on the f32 bit pattern (valid for x >= +0)
  if bits(x) <= bits(T[128]): lo=0, hi=128 else lo=128, hi=256
  repeat 6: mid=(lo+hi)/2; if bits(x) > bits(T[mid]) lo=mid else hi=mid
  mid=(lo+hi)/2; return (bits(x) > bits(T[mid])) ? mid+1 : mid      // u8 store
```

Checks:
- Boat (0.3) on terrain (1.0): sqrt(f32 0.3) = 0.5477226 encodes to byte **38**, which decodes to **μ = 0.549** (T[37] = 0.514).
- This is PROVEN against the winch capture: the boat point's friction byte is 38 (`s1/atoms_winch.txt`).
- encode(0) = 1 (0.01): winch mgr 0x1C8ACF00 has friction 0 × 1.0 and stores byte 1. P.

---

## 3. Deferred new-point pass `FUN_008DCF30` — the seed that applies to the boat — P

Entry 0x8DCF30 is SecuROM-spliced at 0x8DCF36. Splice-emulate shows the stolen instruction is `sub esp,0xF4` and the
continuation is 0x8DCF3C (`s1/emu_8dcf36.txt`, `s1/dis_50ccbd.txt`). The body 0x8DCF3C–0x8DD3B1 is intact `.text`
(`s1/dis_8dce10.txt` 0x8DCF3C–, `s1/dis_8dcf30_tail.txt`).

It is called by `FUN_008FD040` (0x8FD202) for each internal record with flags & 1. It runs **before** the Jacobian build,
with `q.accA` / `q.accB` already set.

```
for i = numContactPoints-1 down to 0:
  if props[i].flags & 1 == 0: continue
  rA = f32(cp.pos - accA.COM(+0x40)); rB = f32(cp.pos - accB.COM)          // accumulators, but COM still valid here
  vA = f32(f32(A.angVel x rA) + A.linVel)   // entity +0x1B0 / +0x1A0 (motion velocities, already damped by S2's FUN_008EDCF0)
  vB = same for B
  d  = f32(vA - vB) per component
  projVel = f32( (d.y*n.y + d.x*n.x) + d.z*n.z )                            // 0x8DD14B–0x8DD163
  fire world contactPointConfirmed (FUN_008EA620) and entity listeners (FUN_008F4E30) for A and B
  e = f32(f64(u8 restitution) * (1/128))
  restingVel = world.contactRestingVelocity (+0x200)     // chain [x+0x6C]+0x64 → world+0x190 (stepInfo) +0x70; capture FLT_MAX
  if not( -restingVel <= projVel ) and e > 0.3f:         // 0x8DD1DB–0x8DD200
       restitution branch: FUN_008FB200(...) (not read), optional FUN_008EAFC0, props.impulse = 0, props.dataA = cp.distance
  else:                                                   // seed, 0x8DD317–0x8DD374
       s  = f32(B.invMass + A.invMass)                                      // entity +0x19C
       k  = f32( 1 / (f64(s) + 1e-10) )
       props.impulse    = f32( ((k * -0.2) * projVel) * (1 + e) )           // (1+e) on the stack, f64
       w  = f32( (e*projVel) * q.subStepDeltaTime )                         // no store between the two products (0x8DD354–0x8DD358)
       w  = f32( w * -1.3 )
       props.solverData = w
       props.dataA      = f32( w + cp.distance )
  props.flags &= ~1                                                          // 0x8DD377
internal.flags(+0x12) &= ~1                                                  // 0x8DD3A7
```

- With `contactRestingVelocity = FLT_MAX`, `-restingVel <= projVel` holds for every finite projVel. So the restitution
  branch is never taken in this world. P (value read in both captures, `s1/consts_c.txt`). Independently, e = 0 fails
  `e > 0.3`.
- For the boat (e = 0):
  - `impulse = (k·−0.2)·projVel`;
  - `solverData = ±0.0` (sign of projVel; it is a product with e = 0);
  - `dataA = distance`.
- Winch check: the boat point there has flags 0 (bit0 cleared by this pass), consistent. P.

---

## 4. Callbacks, as far as they change numbers

### 4.1 Boat entity listener (vtable 0xBAA310) — P (`s1/boatlst_vt.txt`, `s1/dis_43d1b0.txt`)

| Slot | Address | Behaviour |
|---|---|---|
| 0 added | 0x4464D0 | `count(+0x18)++` |
| 1 confirmed | 0x848E30 | `ret 4` (no-op) |
| 2 removed | 0x4464E0 | `count--` |
| 3 process | 0x848E30 | no-op |
| 4 / 5 | 0x43D1B0 and 0x440B40 (a this−4 thunk to it) | destructor: restores the base vtables, calls 0x8DD570 |

None of these writes a contact point, property or event field. This closes README ND#9.

The listener's numeric effect is only that its presence (+0x1F4 ≠ 0) diverts the seed to §3.

### 4.2 World collision listener 0x202947E0 (vtable 0xBA8904) at world+0x174 — present in both captures

Slots:

| Slot | Address | Role |
|---|---|---|
| 0 | 0x411530 | added |
| 1 | 0x4117C0 → 0x412190 | confirmed |
| 2 | 0x4117D0 | removed: counter++ |
| 3 | 0x4117E0 | process: counter += points |

Slot 0 can **reject** a point by setting event.status (+0x20) = 1. addContactPoint then removes the point (0x8D3F7A).

- **Route 1.** If event+0x08 == 0 and event+0x1C (projVel) >= 0.0: reject. Not reachable for PSI adds: addContactPoint
  sets event+0x08 = 1 (0x8D3E8D). P.
- **Route 2.** If both entities have a nonzero property 0x2001, slot 0 records the event and calls the predicate 0x411360
  twice, with the entities swapped. A true result sets status = 1.
  - The property lookup is `0x407BC0`: entity+0x74 array, +0x78 count, 16-byte entries {key, pad, u64 value at +8};
    a missing key returns 0.
  - Boat and terrain each carry **only** key 0x2001, holding a game-object pointer: P, both captures, `s1/props_ent.txt`.
- **The predicate.** 0x411360 is a SecuROM splice. `splice-emulate` (`s1/emu_411360.txt`) routes it through the gadget
  0x4DDA60, which calls 0x411260 and then 0x4111F0 (`s1/dis_4dda60.txt`, `s1/dis_4111c0.txt`).
  - `0x411260` needs (−0 − projVel) > 0, then entity properties 0x2003 / 0x2004 > 0 (and reads 0x2007).
  - `0x4111F0` needs (−0 − projVel) > 0.25 and (entity filterInfo & 0x1F) == 10.
  - For boat vs terrain both are false: no 0x2003 / 0x2004 on either entity, and the filter layers are 0 (boat 0x00B70000)
    and 1 (terrain 0x00050001). **So no boat–terrain point is rejected.**
  - Grade: I. The predicate's argument identity (entity, not cdBody) is read from register use, not traced end to end.
  - This is the game's crashable-object pass-through (properties 0x2003 / 0x2004 / 0x2007, layer 10). It matters for
    props, not terrain.
- **When not rejected,** slot 0 calls 0x411FC0. Its direct stores are stack-relative only (`s1/listener_writes.txt`); its
  callees were not followed: I.
- **Slot 1 (0x412190).** It writes event+0x14 = 0.0 only when neither body is fixed or keyframed (motion type 7 or 6). The
  terrain is type 7, so it does nothing for boat–terrain.
  - In the confirmed-event layout built by §3, +0x14 is a float already 0.0. Projected velocity is at +0x18 and is the
    value the seed reads (0x8DD144 / 0x8DD163 / 0x8DD1D4, stack offsets corrected for the two pushes).
  - So slot 1 cannot change the seed. P.

### 4.3 Contact impulse limit — I

The export (§8) records maxImpulse breaches. `FD040` fires them via `FUN_008EAFC0` when the count is nonzero. The boat's
maxImpulse is 0, so this never fires. The world's contactImpulseLimitBreached array is empty in both captures.

---

## 5. Island driver for this case: `FUN_008FD040` (StSolver_1Cpu) — P for the code; I for the path choice

`FUN_009001B0` chooses the path. If island+0x0C == 0: single-object integrate. Else it computes
`m = max(island+0x4C, island+0x1C)`:
- if `m >= job[1]+0xE8`: MT jobs (`FUN_008FF4F0` / `FUN_008FEEC0` build, then `FUN_008FE9C0` / `FUN_008FEC40` solve);
- else: `FUN_008FD040(stepInfo=world+0x190, si=world+0x1A0, q=job+0x80, island, entities, n)`.

Winch boat island 0x1C8A6A00 has +0x1C = 1 and +0x4C = 1. world.simulation (0x20007400) +0xE8 = 70.

`job[1]` is the simulation: the call site 0x8F705E of `FUN_00900A00` passes `esi` as that argument, and `[esi+0xC]` is
pushed as the world (0x8F7046). The other call site, 0x8F6C85, was not decoded: its listing is misaligned.

So for the boat 1 < 70, and the island takes **`FD040`**. P for site 0x8F705E. On this path the MT export question
(`A36380`) does not arise.

`FUN_008FEEC0` (the MT build) calls the same `FUN_00A209B0` for type-0x16 atoms (decomp lines 75–77). In the MT solve
tasks (export callee lists):
- `FUN_008FEC40` calls `FUN_00A2F840`: P.
- `FUN_008FE9C0` (StSolverExport) calls **`FUN_00A36380`**, not `A3CE20`.

Whether `A36380` is arithmetically identical to `A3CE20` is NOT DETERMINED. It matters only if the boat's island takes
the MT path.

```
FD040:
  acc[0] = fixed accumulator (zero, type 1, identity 1)
  entity solverData = (k+1)*0x80
  FUN_008EDCF0(stepInfo, entities, n, 0xD0, &acc[1]) -> end; *end = 3     // S2: damping + accumulator build
  elemTemp[0 .. island+0x14) = 0
  for each entity, for each internal record r in entity.constraintsMaster (+0x98, count u16 +0x9C):
     if r.flags & 5: set q.accA/B, q+0x38/0x3C, q+0x48/0x4C
         if r.flags & 1: deferredNewPointPass (§3)
         if r.flags & 4: data->vtable[+0x28](q)
     if r.priority < 3: set q fields (§1.8); type 0x16 ? A209B0(atom, q, 1, &w) : A1C940(…)
     else: defer to a list built after
  *w = 0 (end)
  if A2F840(si, schemas, accumulators, elemTemp) == 1:
     A3CE20(si, elemTemp, schemas, accumulators)          // export §8 (called through thunk_FUN_00a3ce20)
     FUN_008EE2D0(...), FUN_008EF520(...)                 // S2: write back / integrate
     if schemas[0] != 0: FUN_008EAFC0(...)                // impulse-limit callbacks
```

For a root atom of type 0x16 the path never enters `FUN_00A1C940`: `FD040` 0x8FD232 and `FEEC0` both branch on
`*atom == 0x16`. `A1C940` reaches `A209B0` only through modifier atoms 0x17–0x1A, and the boat has none
(instance.constraintModifiers = 0, capture). P.

---

## 6. Jacobian build `FUN_00A209B0`(atom, q, writeHeader, &w) — P (decomp `s1/fns/fn_00a209b0.txt`, asm `s1/dis_a209b0.txt`)

Notation: `A` = accA = q+0x30, `B` = accB = q+0x34, `n` = numContactPoints, `invN = f32(1/f64(n))` (0xA20A03–0xA20A32).

### 6.1 Header and the opcode byte

```
if writeHeader:                                     // 0xA20A48–0xA20A7F
  w[0] = f32(w[0] + FLT_EPSILON); byte w[0] = 0x01; byte w[1] = atom.stride
  u16 w[4] = q.idxA; u16 w[6] = q.idxB; w[8] = &properties[0]; w[0xC] = q+0x48
  w += 16
```

Every opcode assignment does the same two steps on the record's first float, whatever it currently holds (including an
earlier tag):

```
tag(rec, op):  rec[0] = f32(f64(rec[0]) + FLT_EPSILON); byte rec[0] = op
```

The chain per record type (P, asm addresses given):

| Record | Tagging chain | Evidence |
|---|---|---|
| 0x0F | `rec[0] = f32(n.x)`; tag 0x0F | 0xA20F07–0xA20F1B |
| 0x11 | tag 0x0F, then tag 0x11 (a second ε-add on the 0x0F-tagged value) | 0xA20F29–0xA20F33 |
| 0x13, first row | the earlier record already holds tag 0x0F (or 0x11) and is re-tagged 0x13 (one more ε-add) | 0xA21170–0xA21180 |
| 0x13, second row | `n1.x` is stored clean: no tag, no ε | — |
| 0x15 | `rec[0] = d0.x`; tag 0x15 | decomp 505–506 |
| 0x16 | tag 0x15, then tag 0x16 | decomp 505–506, then 581–582 |

The solver multiplies by `rec[0]` as stored. So `lin.x` carries one or two ε-adds and the opcode in its low byte. That
changes Jv bit-for-bit for every record type except the second row of a pair.

### 6.2 Per contact point i (loop 0xA20A98–0xA211A6)

Pointers: `c = atom+0x30+32i` (pos `c[0..2]`, n `c[4..6]`, dist `c[7]`); `p` = properties[i].

```
row[0..2] = n ; row[3] = dist (overwritten below)
rA = f32(pos - A.COM) ; rB = f32(pos - B.COM)                                 // 0xA20AC7–0xA20B0E
xA = (f32(rA.y*n.z - rA.z*n.y), f32(n.x*rA.z - rA.x*n.z), f32(n.y*rA.x - rA.y*n.x))    // r×n; product order as in asm 0xA20B15–0xA20B60
angA = A.identity ? xA : M_A·xA                                                // M·v: out = f32((c60*y + c50*x) + c70*z) per row (0xA20B86–)
xB = (f32(rB.z*n.y - rB.y*n.z), f32(rB.x*n.z - n.x*rB.z), f32(n.x*rB.y - rB.x*n.y))    // n×rB = −(rB×n)
angB = B.identity ? xB : M_B·xB
row[7] = 0 ; row[0xB] = 0
sA_j = f32(A.invI_j * f32(angA_j*angA_j)); sB_j = f32(B.invI_j * f32(angB_j*angB_j))   // 0xA20CC0–0xA20D3A
s_j  = f32(sB_j + sA_j)
m    = f32(B.invMass + A.invMass)
K    = f32( f32( ((s_x + s_y) + s_z) + m ) + FLT_EPSILON )                     // 0xA20D6C–0xA20D86
row[0xB] = K
row[7]   = f32( q.virtMassFactor / K )                                        // fdivr 0xA20D93
sumFric  = f32(T[p.friction] + sumFric)
sumImp   = f32(p.impulse + sumImp)
```

The fixed accumulator gives `invI = 0` and `invMass = 0`. With COM = 0, `rB` is the world position, but every B term is
multiplied by zero. Its velocity stays 0 in the solver: P (arithmetic) / I (signed zeros).

### 6.3 Right-hand side (0xA20DC0–0xA20EA4; stack trace done instruction by instruction)

```
t = p.dataA
D = f32(dist - t)
E = f32(-p.solverData - D)
Aq = f32(1.0f * q.frameDeltaTime)            // dword 0xCE0404 · q+0x0C
Bq = f32(-(0.05f) * t)                        // dword 0xCE0408, fchs, fmul
L  = (Aq <= Bq) ? Aq : Bq                     // fcom, test ah,0x41 (ties pick Aq); L is a stored f32
M  = f32(t + L) ; N = f32(D - L)
if ((L + L) + Aq < E):                        // f64 on the stack, strict
    M = f32(M - E) ; N = f32(E + N)
p.dataA = (M < -1.1920929e-7f) ? M : -1.1920929e-7f      // strict <; ties keep the constant
row[3]  = f32(-N * q.rhsFactor)
```

Winch check (P): the boat point stores `dataA = −1.19209e-7` (clamped) and `solverData = −6.66e-7`, consistent with this
clamp and with §8.

### 6.4 Row emission per point

```
sum pos  += pos   (f32 each, order x,y,z)
sum nrm  += (n.x, n.y, n.z, dist)
if (p.flags & 2) == 0:                         // single
   opcode 0x0F; if p.maxImpulse != 0: opcode 0x11, row[0xB] = T[p.maxImpulse]
   w += 48
else:                                          // pair with the previous row (prev = w - 48)
   c  = f32( (Σ coupling terms) * 0.99 )       // qword 0xB5AB50, 0xA2111F
        coupling = B.invMass·n·n' + A.invMass·n·n' + B.invI·angB·angB' + A.invI·angA·angA' (x then y then z);
                   exact add tree as decomp lines 260–268 (asm 0xA20F4C–0xA21120)
   f  = f32( q.virtMassFactor / f32(prevK*K - c*c) )
   prev.row[0xB] = f32(f*K) ; row[0xB] = f32(f*prevK) ; row[0xC] = f32(-c*f)
   prev opcode := 0x13 (with the FLT_EPSILON add of §6.1 on prev.row[0]); w += 64
```

Pair record (112 B), as floats from the record start:

| Floats | Content |
|---|---|
| [0..3] | n0, rhs0 |
| [4..6] | angA0 |
| [7] | effMass0 = q20/K0 |
| [8..10] | angB0 |
| [0xB] | inv00 = f·K1 |
| [0xC..0xF] | n1, rhs1 |
| [0x10..0x12] | angA1 |
| [0x13] | effMass1 |
| [0x14..0x16] | angB1 |
| [0x17] | inv11 = f·K0 |
| [0x18] | inv01 = −c·f |
| [0x19..0x1B] | unused |

### 6.5 Friction frame (after the loop; 0xA211AC–0xA21588)

```
base = f32( (sumFric*sumImp) * invN )             // product kept on the stack (0xA211AE–0xA211C9); note the order
if not (0 < base): return   (no friction rows; w unchanged)            // 0xA211D2
S   = f32((Σn.x² + Σn.y²) + Σn.z²)  [x87 tree in asm 0xA211E4–0xA21200]
iN2 = f32(invN*invN)
if (S * iN2) <= 0.9999:                          // f64 product, not stored (0xA2120C–0xA21224)
    if S <= 0.1: nf = cp[0].normal (incl. w); if f32(|nf|²) < 0.9: nf = (0,1,0,0), base = 0
    else:        inv = (S == 0) ? 0 : f32(1/f32(sqrt(S))); nf = f32(inv*Σn) (incl. w)
else: nf = cp[0].normal (incl. w)
e  = I[atom.info.index]                          // identity table 0xBF65A0
t  = e × nf  (per asm 0xA21395–0xA213C7)
if f32(|t|²) <= 0.1:                             // re-pick the axis: index of the smallest |nf| component
    axis = (|y|<=|x|) ? ((|z|<=|y|) ? 2 : 1) : ((|z|<=|x|) ? 2 : 0)
    atom.info.index = axis; atom.data[+0x1C] = 0; atom.data[+0x24] = 0     // reset friction rhs memory
    t = I[axis] × nf
inv = (|t|² == 0) ? 0 : f32(1/f32(sqrt(|t|²))) ; t = f32(t*inv)
d0 = nf × t   (row 0 axis) ; d1 = t   (row 1 axis)
centre = f32(sum pos * invN)
```

### 6.6 2-D friction record (opcode 0x15, 112 B) and rolling (opcode 0x16, 144 B)

For each friction row j (j = 0 uses d0, j = 1 uses d1) the angular parts are built exactly as in §6.2, with r = centre −
COM and K_j the same sum. Order of K for the friction rows is decomp lines 415–421 / 474–480 (asm not re-traced).

| Floats | Content |
|---|---|
| [0..2] | d0 |
| [3] | rhs0 = f32(atom+0x1C · q.frictionRhsFactor) |
| [4..6] / [8..10] | angA0 / angB0 |
| [7] | q20/K0 |
| [0xB] | inv00 = f32(f·K1) |
| [0xC..0xE] | d1 |
| [0xF] | rhs1 = f32(atom+0x24 · q.frictionRhsFactor) |
| [0x10..0x12] / [0x14..0x16] | angA1 / angB1 |
| [0x13] | q20/K1 |
| [0x17] | inv11 = f32(f·K0) |
| [0x18] | inv01 = f32(−c·f), with c = J0·M⁻¹·J1 (**no 0.99 factor here**) and f = q20/(K0·K1 − c²) |
| [0x19] | **maxImpulse = f32(q.frictionMaxFactor · base)** |
| [0x1A] | export pointer = atom+0x18 |
| [0x1B] | unused |

Opcode 0x15 is set on [0] via §6.1; w += 0x70.

Friction is **2-D, one shared bound**: `|λ| ≤ maxImpulse` on the per-iteration impulse vector (§7.6), with
`maxImpulse = f32(0.25 · base)` and `base = f32((Σμ_i·Σ impulse_i)·invN)`. The impulses summed are the stored
`props.impulse` values: the previous solve's total, or the seed for a new point. The bound therefore uses the **previous
step's summed normal impulse**, not the current iteration's.

**Rolling (opcode 0x16)** is emitted only when n > 1 (0xA21E48–):
- If info.flags & 4, recompute the radius: `atom.data[0] = f32(invN · Σ_i f32(sqrt(f32(|pos_i − centre|²))))`
  (loop 0xA21E87–0xA21F09, i ascending; the sum is stored after each add).
  - If radius < 1e-6 (dword): stop and leave the 0x15 record; bit 4 stays set.
  - Else clear bit 4. The radius is **cached** until a point is added or removed.
- Then `[0x18..0x1A] = M_A·nf` (A.identity: nf), `[0x1C..0x1E] = M_B·(−nf)`.
- `[0x1B] = f32( f32(q20 / K2) · f32(1/radius) )`, with `K2 = Σ invI·ang²` (both bodies) + FLT_EPSILON, no mass terms
  (decomp 567–575).
- `[0x1F] = atom+0x2C · q.frictionRhsFactor`, `[0x20] = inv01`, `[0x21] = maxImpulse`, `[0x22] = radius`,
  `[0x23] = atom+0x18`.
- Opcode 0x16; w += 0x90.

Winch check (P): the radius formula reproduces stored atom+0x14 = 0.432764 (computed 0.432760) for mgr 0x1C8ACF00, and
2.850250 (computed 2.850215) for 0x1C9A1A00. The small difference is consistent with caching at an earlier pose. A
single-point manifold keeps info.flags bit 2 set (boat mgr 0x1C8A6C80: flags 5, n = 1), as the code predicts.

---

## 7. Solver `FUN_00A2F840`(si, schemas, accumulators, elemTemp) — P (decomp `s1/fns/fn_00a2f840.txt`, asm `s1/dis_solver.txt`)

### 7.1 Structure

```
if !DAT_00E77F84: DAT_00E77F84 = FUN_00A3EA60(0); if still 0: return 0     // one-time capability check
prologue, every accumulator (switch 0xA362E0):
   type 0: acc+0x40..+0x5F = 0 ; acc.linVel += si.globalAccelerationPerSubStep   (x,y,z,w; 4 separate f32 adds)
   type 1/2: acc+0x40..+0x5F = 0
   type 3: stop
invIVF = f32(si.invNumSteps * si.invIntegrateVelocityFactor.x)     // local_dc8
for iter = 0 .. si.numSteps-1:                     // 4
   firstMicro = 1.0
   for micro = si.numMicroSteps .. 1:              // 1
       walk the schema stream once (§7.2–7.6); firstMicro = 0.0
   last = (iter == si.numSteps - 1)
   second loop over accumulators (jump table 0xA36364, the "loop at 0xA3547E"), §7.7
return 1
```

There is **no warm start** of normal or friction impulses. elemTemp is zeroed by `FD040` before every solve. Information
carried across steps is only:
- `props.impulse` (bounds friction);
- `props.solverData` / `dataA` (rhs memory);
- `atom.data` rhs (friction drift).

### 7.2 Walk and headers

- opcode 1: `accA = acc + 0x80·u16[+4]`, `accB = acc + 0x80·u16[+6]`, rec += 16.
- opcode 2: rec += i32[+4].
- opcode 0: end of the walk.
- Others: §7.3–7.6.

The 0x0F / 0x11 / 0x13 cases loop internally while the next opcode is the same (0xA30E0F `cmp al,0xF`).

### 7.3 Single contact 0x0F (asm 0xA30AD1–0xA30E1B, traced) — P

```
dl_j = f32(A.lin_j - B.lin_j)
aA_j = f32(A.ang_j * row.angA_j) ; aB_j = f32(B.ang_j * row.angB_j)
dl_x = f32(row.lin.x * dl_x) ; dl_y = f32(dl_y * row.lin.y) ; dl_z = f32(dl_z * row.lin.z)
s_j  = f32(aB_j + aA_j) ; s_j = f32(s_j + dl_j)
Jv   = f32((s_y + s_x) + s_z)
delta = f32(row.rhs - Jv)
if not (delta < 0):                           // apply when delta >= 0 (and on NaN)
    lam = f32(delta * row.effMass)            // row[7]
    tA = f32(lam*A.invI_xyz), mA = f32(lam*A.invMass); tB, mB likewise
    A.lin_j = f32(A.lin_j + f32(row.lin_j * mA))   (x,y: lin first; z: product first — order as asm 0xA30CF0–0xA30D14)
    B.lin_j = f32(B.lin_j - f32(row.lin_j * mB))
    A.ang_j = f32(f32(tA_j * row.angA_j) + A.ang_j) ; B.ang_j = f32(f32(tB_j * row.angB_j) + B.ang_j)
    elem[0] = f32(lam + elem[0])
elem += 1
```

The normal impulse is **one-sided per iteration**: an increment is applied only when positive and is never taken back.
The accumulated impulse is the sum of positive increments. There is no clamp on the accumulated value.

### 7.4 Single contact with maxImpulse 0x11 (0xA30E20) — decomp-level P

As 0x0F, plus after computing lam: `if row[0xB] < lam + elem[0]: lam = row[0xB] − elem[0]`. Not used by the boat
(maxImpulse 0).

### 7.5 Contact pair 0x13 (0xA2F9FE) — decomp-level P (asm not re-traced)

```
d0 = rhs0 - J0v ; d1 = rhs1 - J1v                  (each as in §7.3)
l0 = d1*inv01 + d0*inv00 ; l1 = d0*inv01 + inv11*d1
if l0 <= 0:
    l1s = effMass1*d1
    if l1s > 0: apply l1s on row 1; elem[1] += l1s
    else:       goto ONLY0
elif l1 <= 0:
ONLY0: l0s = d0*effMass0; if l0s > 0: apply l0s on row 0; elem[0] += l0s
else: apply l0 on row 0, then l1 on row 1 (row 0's velocity change applied first); elem[0] += l0; elem[1] += l1
elem += 2; rec += 112; repeat while the next opcode is 0x13
```

### 7.6 Friction 0x15 (0xA31E85) and 0x16 (0xA31590) — bound semantics P from asm 0xA320F9–0xA321DF and 0xA318B6–0xA319D9

```
0x15:
  d0 = rhs0 - J0v ; d1 = rhs1 - J1v
  l0 = f32(inv00*d0 + d1*inv01) ; l1 = f32(d1*inv11 + d0*inv01)
  S  = f32(l1*l1 + l0*l0) ; mx2 = f32(max*max)
  if not (mx2 < S): elem[2] = 1.0
  else: sc = f32(sqrt(f32(mx2 / S))); l0 = f32(sc*l0); l1 = f32(sc*l1); elem[2] = sc
  apply l0 on row 0, then l1 on row 1 (signed, no sign test); elem[0] += l0; elem[1] += l1
  elem += 3; rec += 112
0x16: as 0x15 with a third, angular row:
  d2 = rhs2 - (angA_r·A.ang + angB_r·B.ang) ; l2 = f32(row[0x1B]*d2)
  S  = f32((l0*l0 + l1*l1) + l2*l2)
  if not (mx2 < S): elem[3] = 1.0
  else: sc = f32( f32(1/f32(sqrt(S))) * max ); scale l0, l1, l2; elem[3] = sc
  apply l0, l1; then p2 = f32(radius*l2) applied as an angular-only impulse:
     A.ang += f32(angA_r * p2 * A.invI), B.ang likewise
  elem[0] += l0; elem[1] += l1; elem[2] += p2; elem += 4; rec += 144
```

- The friction bound is on the **impulse of this iteration**: there is no accumulated friction impulse to project.
- It is a 2-D (or 3-D with rolling) disc of radius `max = 0.25·μ̄·Σλn(previous)`.
- The 0x15 and 0x16 scale formulas differ (`sqrt(max²/S)` vs `max/sqrt(S)`): P, two different instruction sequences.

### 7.7 Second loop per iteration (decomp 2458–2910; jump table 0xA36364) — decomp-level P, thresholds' compare senses checked in asm 0xA35F0B–0xA35FFD

The prologue's gravity add is the **first** of the four per-step gravity increments. The other three come from the
non-last branch below. Each is `globalAccelerationPerSubStep` (README's "4 × g·dt/4": P).

```
for each accumulator a (until type 3):
  type 0 (dynamic):
     rec = si + 0x64 + 0x1C*a.deactClass
     if any |a.lin_j| >= 1e6 or |a.ang_j| >= 1e6 or NaN (j=x,y,z): a.lin = a.ang = (1,0,0,0)   // table 0xBF65A0
     m_j = f32(rec[1]*|a.ang_j| + |a.lin_j|*rec[0])
     if all m_j <= si.one(1.0):
         if all m_j <= rec[3]: a.lin = a.ang = 0
         else:                 a.lin *= rec[2] ; a.ang *= rec[2]      (all 4 lanes)
     dl = a.lin - a.sumLin ; da = a.ang - a.sumAng                   // sum = acc+0x40 / +0x50
     a.sumLin += si.integrateVelocityFactor * dl ; a.sumAng += … * da   (per lane)
     if last: a.sumLin *= invIVF ; a.sumAng *= invIVF ; a.lin = dl ; a.ang = da
     else:    a.lin = (a.sumLin + dl) + g ; a.ang = a.sumAng + da
  type 2: the same sanity and threshold test, then as type 1.
  type 1: the same blend with g = 0 (table 0xB132F0).
```

For the boat (class 2): rec = {11.1111, 12.3457, 0.968, 0.05}.
- When every axis has `12.35·|ω_j| + 11.11·|v_j| ≤ 1`, the accumulator velocity is multiplied by 0.968 **every
  iteration**.
- When every axis is ≤ 0.05, it is zeroed.

This is applied to the stored (velocity + running sum) value. P (code, captured values).

Algebraic check (I, by expansion with no constraints, s₀ = 0, u = the motion velocity before the prologue):
- after 4 iterations `a.lin = u + 4g`;
- `a.sumLin = u + 2.5g` (the mean of the 4 substep velocities).

The scheme stores velocity + f·Σ during the solve. Constraint impulses see that mixed value.

---

## 8. Export `FUN_00A3CE20` (si, elemTemp, schemas, accumulators) — decomp-level P (`s1/fns/fn_00a3ce20.txt`)

The export is x87 as well: 1152 x87 instructions and 0 scalar-SSE instructions in 0xA3CE20–0xA3E9A0
(`s1/dis_a3ce20.txt`). So the §0.1 rule holds. Its add trees were taken from the decomp, not traced: I for the exact bits.

Constants:
- `kN = f32(si.dampDivTau * si.deltaTime)`;
- `kF = f32(si.dampDivFrictionTau * si.deltaTime)`;
- `T4 = f32(f64(si.numSteps) * si.deltaTime)`.

Here `Jsum(row)` = the row's Jacobian dotted with (A.sumLin − B.sumLin, A.sumAng, B.sumAng), i.e. the **final** sum
values after §7.7's last scaling. The add tree is decomp lines 810–813.

| Opcode | Writes |
|---|---|
| 0x0F / 0x11 / 0x13 | `props.impulse = elem[k]` and `props.solverData = rhs·kN − Jsum·T4` for each row; for 0x11, a breach (`row[0xB]·0.99 < elem`) is logged into the schema buffer and the count is written at `schemas[0]` at the end |
| 0x15 | at atom+0x18: `{elem0, elem2·(rhs0·kF − Jsum0·T4), elem1, elem2·(rhs1·kF − Jsum1·T4)}` |
| 0x16 | at atom+0x18: `{elem0, s·(row0), elem1, (row1)·s, elem2, s·(rhs2·kF − Jsum2·T4)·s}` with s = elem3 (the last iteration's scale; the rolling term really is multiplied by s twice, decomp 536–538) |

Next step, `rhs_friction = stored · q.frictionRhsFactor` (§6.6) and `E = −solverData − D` (§6.3). This feedback is the
position correction: there is no separate position pass.

Winch boat point (mgr 0x1C8A6C80, `s1/atoms_winch.txt`, P):
- impulse 242.712;
- friction (λt0, rhs0, λt1, rhs1) = (39.02, 3.63e-6, −79.11, −8.03e-6);
- |λt| = 88.2 ≤ μ·λn = 0.549 × 242.7 = 133.3.

This is only a loose plausibility check. The bound was built from the **previous** step's normal impulse, which this
capture does not hold, so it does not test the 0.25 factor.

---

## 9. Interfaces

### 9.1 What S1 needs from the narrowphase (N1/N2), per PSI step

1. For each new manifold point: optionally `reserveContactPoints(k)` (slot 4), then
   `addContactPoint(cdA, cdB, input, output, gskCache, cp)` (slot 3).
   - `cp` = 32 bytes `{pos.xyzw, n.xyz, distance}`.
   - The normal must be such that (v(cdA) − v(cdB))·n > 0 is separating: addContactPoint takes entity(cdA) as "X" for
     projVel.
   - The solver uses the instance's A/B. Whether the agent always passes cdA = mgr.A was not checked: **I**.
   - `output.constraintOwner` must accept vtable +0xC (add constraint), +0x10 (remove), +0x14 (callback request).
   - The id returned must be kept by the agent.
2. For each surviving point: the refreshed `cp` with its id in the process output, then `processContact` (slot 6) once
   per pair per step. The output layout is:
   - +0x00 = end pointer;
   - 0x30-byte entries from +0x10, each {hkContactPoint at +0, u32 id at +0x20}.
3. For each dropped point: `removeContactPoint(id, owner)` (slot 5). If `remaining == 0`, the constraint leaves the island.
4. Quality / priority: PSI (1); ToI slots 7/8 unused for this pair.

### 9.2 What S1 hands to the integrator (S2)

The accumulator array after `A2F840` returns 1 and `A3CE20` has run:
- `acc+0x10` linear velocity (true velocity at step end);
- `acc+0x20` angular velocity in the core frame;
- `acc+0x40` Σ-linear (= mean substep velocity, scaled by invIVF);
- `acc+0x50` Σ-angular.

`acc+0x40..0x5F` no longer hold COM / rotation. The S2 consumers are `FUN_008EE2D0` (write back) and `FUN_008EF520`
(integrate). How they use the sums is S2's.

S1 requires from S2's `FUN_008EDCF0`:
- type, identity flag, deactivation class (int at +4);
- linVel and angVel (damped by `max(0, 1 − dt·damping)`, and **written back into the motion**: decomp lines 31–46);
- invInertia and invMass at +0x30;
- step-start COM at +0x40 and the core-from-world rotation at +0x50.

The deferred pass (§3) reads the **motion** velocities (entity +0x1A0 / +0x1B0) after that damping.

---

## 10. Gate data (answer to "does any capture hold a manager with points")

`s1/scanmgr.py` scanned all five captures for vtable 0xB589D4 (`s1/scanmgr.txt`):

| Capture | Managers | With points |
|---|---|---|
| first-mission | 3 | 0 |
| **winch** | 269 | **20** |
| mid-mission | 96 | 1 |
| clean-load | 86 | 0 |
| mattias | 344 | 0 |

**Gate: winch, mgr 0x1C8A6C80** (decoded in `s1/atoms_winch.txt`, `s1/winch_boat.txt`).
- Body A 0x1DF9D000:
  - mass 8000 (invMass 1.25e-4), motion type 4 box inertia, quality 3;
  - allowedPenetrationDepth 0.1, friction 0.3, angular damping 0.8, deactivation class 2;
  - **boat listener vtable 0xBAA310**.
- Body B 0x1E45C800: fixed (type 7), friction 1.0, at (2600, 0, −1000).
- One point:
  - pos (2523.605, −37.093, −804.466), n (−0.18920, 0.93219, 0.30859), distance 1.5e-5;
  - impulse 242.712, solverData −6.66e-7, dataA −1.19209e-7, friction byte 38, flags 0;
  - atom flags 5, axis 0; friction results as in §8.

Caveat: this body's shape is a 5-child list (children types 7, 11, 7, 7, 7) and its invInertia (1.64e-5, 1.64e-5,
1.58e-4) differs from the opening Speed Boat's 13-child list (1.43e-5, 1.41e-5, 1.94e-4). **It is a boat-class body on a
different model. The model hash was not resolved.** Its inputs (velocities, transform) are in the same capture, so one
step's Jacobian and export can be checked offline. The solve itself needs the pre-step state, which a single capture does
not hold: I.

Other usable gates in the same capture (fixed A, dynamic B; 3–4 points with pairs):
- 0x1C8AA800 (new points, listener-free path, seed 0 at rest);
- 0x1C8ACF00 (zero-friction material → byte 1);
- 0x1C9A1A00 (impulses 337 / 0 / 385 / 62 on pairs).

---

## 11. Boat-case numbers (first-mission world)

Material and point properties:
- μ byte 38 → 0.549; e = 0; maxImpulse 0;
- maxNumContactPoints 256; stride 0x14.

Allowed penetration:
- allowedPenetrationDepth 0.1 is **not read by any function in this path**: the rhs (§6.3) uses
  frameDt · 1.0 and 0.05·dataA, not the collidable's allowedPenetrationDepth.
- Where 0.1 is used is NOT DETERMINED. It is presumably the narrowphase or ToI (HK); not checked.

Solver quantities:
- q: rhsFactor = f32(0.818182 · 240.775) = 196.998 (I: product computed, not read);
- virtMassFactor 1.1; frictionRhsFactor = f32(0.409091 · 240.775) = 98.4989 (I); frictionMaxFactor 0.25;
- iterations 4; microsteps 1; invIVF = f32(0.25 · 1.222222) = 0.305556 (I).

---

## 12. NOT DETERMINED (what was tried)

1. World listener (§4.2): the predicate 0x411360 was resolved by splice emulation to 0x411260 || 0x4111F0, and both are
   false for boat–terrain (I).
   - Still open: the callees of 0x411FC0 (their stores were not followed).
   - Still open: the predicate argument identity (I). Next: trace the arguments at 0x411756 / 0x411773.
2. Which thread runs the island solve (x87 CW 0x27F vs 0x7F). Tried: CONTEXT read of all threads at the pause. Next: a
   capture paused inside `FUN_00A2F840`, or a CW read in the profiler.
3. The second `FUN_00900A00` call site (0x8F6C85) is not decoded. The MT export `FUN_00A36380` vs `A3CE20` is open, but
   it is only relevant for islands with ≥ 70 constraints or entities; the boat takes `FD040` (§5).
4. `FUN_008FB200` (restitution branch): not read. Unreachable in this world (resting velocity FLT_MAX); needed only if
   another world sets it.
5. Bit 0 of atom.info.flags (set on removal): no reader found in this path.
6. `FUN_008DD460` (id allocation policy) and `FUN_008F51E0` / `FUN_008F5280` (atom grow / shrink, where numContactPoints
   is incremented): not read.
7. Exact x87 add trees for the friction-row K sums, the pair coupling c, the export dot products, and the second-loop
   blend. Given here at decomp level. §6.2 K, §6.3 rhs, §7.3 and the §7.6 bound/scale were traced in asm.
8. The narrowphase's A/B order relative to mgr.A / mgr.B when it calls addContactPoint (normal sense).
9. allowedPenetrationDepth consumer (§11).
10. The winch gate body's model identity.
