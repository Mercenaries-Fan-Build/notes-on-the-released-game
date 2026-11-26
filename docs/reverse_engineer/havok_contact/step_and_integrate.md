---
status: current
evidence: proven (graded per claim)
---

# S2: one Havok 5.5 step for the boat's island, and the integrators (pc-v10)

Read of 2026-11-25. Exe `game-files/canonical/dumps/mercs2_unpacked.exe`, sha256 `8c179a99…bc7ba` (checked this run;
file offset = VA − 0x400000). Capture `game-files/memory-dumps/updated-chris-exports/20261103_new-game-first-mission-start.dmp`
(world `0x20007800`, simulation `0x20007400`, boat body `0x1EBB8000`, motion `m = body+0xD0`, island `0x1EE39500`).
Kept beside this page in `s2/`: the three line-level write-ups (`fork_8ec5b0.md`, `fork_motion.md`, `fork_aabb.md`) and
the replay script `replay_8ec5b0.py`. The other files named below (listings, capture reads) were working files and are
not kept; `objdump -d` of the image and `mercs2_probe dump-read` of the capture give them again.

Grades: **P** = PROVEN this run (address, command or capture read given). **I** = INFERRED. **S** = SPECULATIVE.
**recall** = remembered Havok 5.5 knowledge, at best I, used only as a label.

Notation: `m+X` is an offset in the hkpMotion (entity+0xD0+X). Motion layout (hkpMotion / hkMotionState reflection,
`classes_needed.txt`, P): +0x08 type, +0x09 deactivationIntegrateCounter, +0x0A/+0x0C deactivationNumInactiveFrames[2] (u16),
+0x10..+0x3C rotation columns 0..2 (column k at +0x10+0x10k), +0x40 translation, +0x50 com0, +0x60 com1, +0x70 rot0, +0x80 rot1,
+0x90 comLocal, +0xA0 deltaAngle, +0xB0 objectRadius, +0xB4 linearDamping, +0xB8 angularDamping, +0xBC/+0xBD max lin/ang
velocity (hkUFloat8 index), +0xBE deactivationClass, +0xC0 inertiaAndMassInv (invIx, invIy, invIz, invMass), +0xD0 linearVelocity,
+0xE0 angularVelocity, +0xF0/+0x100 deactivationRefPosition[2], +0x110/+0x114 deactivationRefOrientation[2] (packed u32).
`UF8[i]` = f32 table at 0xB13380. `f32(e)` = round to float; `x87(e)` = evaluated on the x87 stack, rounded only at the `fstp dword`.

---

## 0. Corrections to the brief and to the README (all P)

1. **`FUN_008EF520` is not the integrator.** It is the post-integrate AABB update, called as `(collisionInput = *(world+0x6C),
   entities, n)` right after each integrator: 0x90039E in `FUN_009001B0`, 0x8FD717 in `FUN_008FD040`, 0x8FE8B7 in `FUN_008FE830`.
   Its body starts with `tolerance·0.5` and a shape virtual on the transform at entity+0xE0 (decomp `d_008ef520.txt` head). §5.
2. **The integrators are two functions, and the boat uses both:**
   - `FUN_008EC5B0` (single-object path): called by `FUN_009001B0` at 0x900386 (decomp line 117: `if (island+0x0C == 0)`), when the
     island's constraint count is 0.
     The capture's island has +0x0C = 0 (`cap1.txt`), so this produced the captured state. §3.4.
   - `FUN_008EE2D0` (solver path): called from the single-CPU solver `FUN_008FD040` at 0x8FD702 (and from the multi-job
     "StIntegrateMotions" job `FUN_008FE830` at 0x8FE8A6). It is a **SecuROM split**: prologue `push ebp; mov ebp,esp; and esp,-0x10`
     then `jmp [0x2454F6C]` at 0x8EE2D6 (splice table: terminal, target 0x024B9770). Splice emulation (`emu_steps3.txt`) re-enters
     `.text` at **0x8EE2DC** with esp = (aligned ebp) − **0x124**, so the stolen instruction is `sub esp, 0x124`. I patched those 6 bytes
     into a scratch copy (`ghidra/mercs2_s2_patched.exe`) to decompile it; the transcription in §3.3 is from objdump of
     0x8EE2D0–0x8EF410 (`dis_8ee2d0_c.txt`).
3. **The boat listener vtable 0xBAA310 has 5 slots, not 6.** 0xBAA324 starts at 0xBAA310 + 0x14, so `0x440B40` is slot 0 of the
   entity-listener vtable (a this−4 thunk to the destructor `0x43D1B0`). `0x43D1B0` is slot 4, the destructor. Neither is a contact callback. (`fork_aabb.md` B.)
4. **README §1.2 names the wrong getAabb.** `0x8C8B20` (list slot 7, +0x1C) is the list shape's getAabb, the union of its children.
   `0x8C8880` (slot 6) is a size query returning 0x70. (`fork_aabb.md` A.2.)
5. **The velocity-reset constant at 0xBF65A0 is (1, 0, 0, 0)**, i.e. x = 1.0 and w = 0. Both the exe bytes and the capture give this
   (`consts_s2.txt`, `cap_bf65a0.txt`). `fork_motion.md` item 9 says (0, 0, 0, 1); that is wrong.
6. **stepInfo.deltaTime is not the game's dt.** It is dt' = f32(f32(psi + dt) − psi). In the capture, the sim's raw dt
   (+0x1C) is 0x3C88164F = 0.0166122 while world+0x198 is 0x3C881800 = 0.0166130. §2.
7. **The single-CPU solver, not the multi-job path, runs the boat's island.** `FUN_009001B0` (decomp lines 134–138) compares
   max(island+0x4C entities, island+0x1C) against sim+0xE8. The capture has sim+0xE8 = 0x46 = 70 (`cap1.txt` run of sim fields), so an island
   with fewer than 70 takes `FUN_008FD040` ("StSolver_1Cpu"). The jobs `FUN_008FE830` (0xB), `FUN_008FE910` (7), `FUN_008FEAD0` (9) and the other
   solver jobs run only for islands of 70 or more.

---

## 1. Order of one step for the boat island

### 1.1 The answer to the deciding question: the solver uses the previous step's collide — P

Within one step the job chain is **integrate → broadphase → narrowphase → post-collide → finish**. The proof is each job writing
the type of the next one:
- `FUN_008F72C0` pushes job type **0** (`mov word [esp+0x30], di`, di = 0, at 0x8F750A; `FUN_00A07830` at 0x8F7539).
- Type 0 = `FUN_009001B0`, from the dispatcher `FUN_008F6C10`'s switch. It solves and integrates (0x900386/0x90039E, or `FUN_008FD040` at
  0x90041D), and then sets `*job = 0xC` (decomp line 220) and pushes it (`FUN_00A07F00`).
- Type 0xC = `FUN_008FE2E0` (TtBroadphase). It sets `*job = 0xD` with the stepInfo copied in (decomp lines 188–192) and pushes it.
- Type 0xD = `FUN_008FDA80` (TtNarrowPhase). It runs each agent entry (`FUN_00909CA0`, line 113) and then the contact manager's slot 6
  (line 117). If the island has one sector (job+8 == 0) it does the post-collide work inline (lines 171–183). Otherwise it hands off
  to type 0xE = `FUN_008FD870` (StPostCollide).
- `FUN_008F7B60` (finish, called by the game through `FUN_008D6D70` after the jobs) creates agents for new broadphase pairs and
  **collides them on the spot** (`FUN_00909CA0` + mgr vtable +0x18, lines 122–124 of its decomp, "StaddAgt").

So every contact point is generated after this step's integrate and AABB update, at the post-integrate transform. Step N's
solve (inside type 0) reads the contact constraints in entity+0x98 as the narrowphase of step N−1 (or `FUN_008F7B60` of step N−1)
left them. **A port must collide at the end of the step and solve with those points in the next step.**

### 1.2 Single-threaded order for one island holding the boat (what to write)

Per game substep, with the game dt from `FUN_004036F0` (N = clamp(floor(T·60 + 0.99), 1, 3), dt = T/N; boat `drive_spec.md` §F):

| # | What | Function (evidence) | Grade |
|---|---|---|---|
| 1 | Game pre-steps: actor slot +0x24 for every registered component (the boat's is `FUN_00446BD0`, per `fork_motion.md` 4.3 item 16) | `FUN_00416AD0`, called at the head of `FUN_00413F90` | P |
| 2 | Reset the sim job counter: sim+0xEC = 0 | `FUN_008D61C0` → `FUN_008F6B90` | P |
| 3 | stepBegin: write stepInfo, collisionInput.stepInfo and the solverInfo substep fields, then call the maintenance manager (world-time reset at ≥ 63 s, §2.2) | `FUN_008D6180` → `FUN_008F72C0` 0x8F72FD–0x8F749A | P |
| 4 | **Apply actions**: for every active island, each action's vtable +0xC(&world.stepInfo). The boat action is `0x447260`. | `FUN_008F2650` at 0x8F74FB, because world+0xA0 processActionsInSingleThread = 1 (capture `cap1.txt`). `FUN_009001B0` runs its own loop only when +0xA0 == 0. | P |
| 5 | Deactivation frame flags: solverInfo counter and select flags (§2.1) | `FUN_008F72C0` 0x8F753E–0x8F758B | P |
| 6a | **Island without constraints (boat afloat):** gravity + damping + integrate + deactivation counters | `FUN_008EC5B0(world+0x1A0, world+0x190, world+0x1C0, entities, n, 0xD0)` at 0x900386 | P |
| 6b | **Island with constraints (boat in contact):** build accumulators (damping, §3.1) → per-constraint callbacks and Jacobians (`FUN_00A209B0` for atom type 0x16 contact, `FUN_00A1C940` for others) → solve `FUN_00A2F840` (gravity g·dt'/4 per substep, §3.2) → export `thunk_FUN_00A3CE20` → integrate `FUN_008EE2D0` → impulse-limit callbacks `FUN_008EAFC0` if any | `FUN_008FD040` (decomp lines 119–268) | P for the order; the solver internals are S1's |
| 7 | AABB update: per-child and entity bounding volumes, swept by the step's motion | `FUN_008EF520(collisionInput, entities, n)` at 0x90039E (6a) or 0x8FD717 (6b) | P |
| 8 | Island split check every 8 or 4 frames (no effect for one body) | `FUN_008FE740`, if uStack_5c, in `FUN_009001B0` lines 95–116 and 207 | P (structure) |
| 9 | Broadphase: optional island deactivation request; then `FUN_0092CB10` updates the broadphase with each entity's expanded AABB. When the last task finishes, the queued impulse-limit-breached events go to `FUN_008EAFC0` (world+0x180 listeners, "TtimpLimitCb"). | `FUN_008FE2E0` lines 39–44, 80 | P; the deactivation body is VM code (§3.5) |
| 10 | Narrowphase: for each agent entry in the island's sectors, `FUN_00909CA0(entry, processInput, buffer, contactMgr)`. The contact-point added and removed callbacks fire in here (§1.3). Then contactMgr slot 6 (processContact). | `FUN_008FDA80` lines 101–169 | P for the calls; the agent→mgr call path is I |
| 11 | Post-collide: VM stub `thunk_FUN_024B6280(island)`, merge of per-sector stats, execute deferred commands (`FUN_009010F0`, "MinumCmds"), `FUN_008D6400(island)` | inline in `FUN_008FDA80` lines 170–183, or job 0xE `FUN_008FD870` | P (calls) |
| 12 | Finish: re-sort islands, add agents for new pairs and collide them now, remove dead agents, run pending world operations (`thunk_FUN_024BB890` = splice 0x8D6370; emulation shows it writes [ecx+0x80] = 0 and reads [ecx+0x7C]; that ecx is the world, so these are pendingOperationsCount and pendingOperations, is I), **psi += raw dt** (sim+0x18 += sim+0x1C), then world post-collide listeners (`FUN_008EADB0`), then sim vtable +0x18 | `FUN_008F7B60` | P |

**Job plumbing that changes numbers.** For one island the hkJobQueue, the Pimp ring buffer in `FUN_004036F0` and the critical sections
only move work between threads. The values that matter are these:
- the stepInfo copy taken into the job at stepBegin and at broadphase (identical values);
- the job-data struct built by `FUN_00900A00`: world, sim, queue, collisionInput +0x50..+0x6C copied, and
  `FUN_008F4590(solverInfo, stepInfo)`, which builds the constraint query input at job+0x80. That input belongs to S1.
P for the copies. No reordering affects one island (I). Item 4 runs on the thread that calls stepBegin, before any job is queued (P).

### 1.3 Contact-listener callbacks relative to the solve (P for the slot wiring, I for the exact call site)

| Listener slot (0xBAA310) | Boat function | Fired from | Phase |
|---|---|---|---|
| +0x0 contactPointAdded (recall) | `0x4464D0`: count +0x18 += 1 | addContactPoint `FUN_008D3DA0` (contactMgr slot 3) → `FUN_008F4D80` "TtcpAddCb" | narrowphase of step N (item 10), or finish's new-agent collide (item 12) |
| +0x4 confirmed (recall) | `0x848E30` (empty) | `0x8D3BC0`, `0x8F9950`, `0x954E70` | NOT DETERMINED; it does nothing for the boat |
| +0x8 removed (recall) | `0x4464E0`: count −= 1 | contactMgr slots 5 `0x8D4180` and 8 `0x8D3B40` → `FUN_008F4EE0` | narrowphase of step N |
| +0xC process (recall) | `0x848E30` (empty) | contactMgr slot 6 `0x8D42F0`, called at `FUN_008FDA80` line 117 | narrowphase of step N, after each agent |
| +0x10 | destructor `0x43D1B0` | — | — |

All of them fire after step N's solve and integrate. The boat action reads the count in step N+1's item 4. The listener's count
(+0x18) counts points, not bodies (P, slot bodies). The contactMgr slots have no static callers in the export; that the agents reach
slot 3 through the virtual is I.

---

## 2. What `FUN_008F72C0` writes (P, transcribed from `dis_8f72c0.txt`; decomp lines 133–151 mislabel the stack slots)

`this` = simulation (vtable 0xB59E04). W = world = sim+0x0C; SI = W+0x1A0 (solverInfo).

```
sim+0x68 = 1 (byte)
W+0x84 criticalOperationsLockCount += 1;  (*(W+0x7C))+0x1C = 1 (byte)
sim+0x1C = dt                                   // raw game dt (physicsDeltaTime)
t0  = sim+0x18                                  // currentPsiTime
t1  = f32(dt + t0)                              // 0x8F7318–0x8F7325, x87 fadd, stored f32
dt' = f32(t1 - t0)                              // 0x8F7339 fsubrp, stored f32
inv = (dt' == 0) ? 0.0 : f32(1.0 / dt')         // fucom with 0, test ah,0x44, jp
W+0x190..0x19C stepInfo           = {t0, t1, dt', inv}
CI = *(W+0x6C); CI+0x50..0x5C     = {t0, t1, dt', inv}
maintenanceMgr(W+0x4C)->vtbl[+0x14](W, &local{t0,t1,dt',inv})    // FUN_008FA410, may rewrite local and W stepInfo (§2.2)
thunk 0x6B1C80(W)                 // SecuROM VM stub; emulated: two stack reads, no other memory access, returns 0. I: no effect on numbers
FUN_008D6200(); FUN_00A260D0()    // 1-byte `ret` functions
W+0x190..0x19C = local            // copied back after the maintenance call
SI+0x10C (W+0x2AC) substepDt   = f32(SI+0x120 invNumSteps(0.25) * local.dt)
SI+0x110 (W+0x2B0) substepInv  = f32((float)(int)SI+0x114 numSteps(4) * local.inv)   // fild
SI+0x10..0x1C (W+0x1B0) gAccPerSubStep = f32(g_k * substepDt), k = 0..3 (g = W+0x10, all 4 lanes)
SI+0x20..0x2C (W+0x1C0) gAccPerStep    = f32(local.dt * g_k), k = 0..3
jobData(W+0x68): [0] = CI, [1] = &W.stepInfo, [2] = sim, [3] = f32 CI+4 (tolerance), [4] = 0xE74810
if W+0xD0 processToisMultithreaded: *(sim+0x170)+0x10 = 1        // 0 in the capture
if W+0x2C numActiveIslands > 0:
    if W+0xA0: W+0x88 -= 1; FUN_008F2650(sim) /* applyAction on every island action */; W+0x88 += 1
    push job {type 0, ..., count = numActiveIslands} on sim+0x140    // FUN_00A07690, FUN_00A07830
// deactivation frame flags (u8 arithmetic):
c = ++SI+0x127 (W+0x2C7)
if (((c - 4) & 7) == 0)  SI+0x125 ^= 1
if ((c & 7) == 0)        SI+0x125 ^= 2       // the same byte, bit 1
if ((c & 0xF) == 0)    { SI+0x127 = 0; SI+0x126 = 1 - SI+0x126 }
sim+0xF4 = W+0x2C; sim+0xF8 = W+0x38
```

The capture checks the formulas bit for bit (`cap1.txt`):
- world+0x198 == f32(end − start);
- 0x2AC = 0x3B881800 = dt'/4;
- gAccSub.y = −0.0373792648 = f32(−9·dt'/4) and gAccStep.y = −0.149517059;
- collisionInput+0x50 equals the world stepInfo;
- sim+0x18 = 56.947979 = stepInfo.end, because the finish (§1.2 item 12) already advanced psi by the raw dt.

The bytes at +0x2C4..+0x2C7 are 00 00 00 01.

### 2.1 The deactivation flag bytes
SI+0x125 is a 2-bit field. Bit 0 toggles when c ≡ 4 (mod 8) and bit 1 when c ≡ 0 (mod 8). SI+0x126 toggles every 16 steps. The
integrators fold SI+0x125+idx into bits 14 and up of each u16 inactive-frame count (§3.5). The names
"deactivationNumInactiveFramesSelectFlag[2]" and "deactivationIntegrateCounter" are recall. The offsets match the hkpWorldCinfo fields of
those names (`classes_needed.txt`) (I).

### 2.2 World-time reset (maintenance, P: `FUN_008FA410` 0x8FA452–0x8FA468, `FUN_008FA4A0`)

The reset fires iff `63.0 <= stepInfo.start`: `fld start; fld thr; fcompp; test ah,0x41; jp skip`. thr is maint+0xC = 0x427C0000 in the
capture (maint mgr `0x1FFDFF10`, vtable 0xB59F24); unordered skips. On reset, with base = maint+0x8 = 33.0:

```
d = f32(end - start); W.start = 33.0; W.end = f32(d + 33.0); W.dt = d; W.inv = f32(1/d)
shift = f32(W.start - oldStart)
sim+0x14 += shift; sim+0x18 = W.start; if (sim+0x20 != *0xB12A50) sim+0x20 += shift
for each active island, each entity: entity+0x12C (= m+0x5C, com0.w) += shift;  FUN_008EB290(island, oldEnd, W.end, CI)
sim->vtbl[+0x38](shift);  local stepInfo = W stepInfo;  CI+0x50..0x5C = W stepInfo
```

Formulas are from the decomp; the compare is from the disassembly (P). The order of the x87 operations inside the formulas was not
transcribed (I). A port must do this reset, because com0.w and the stepInfo times feed the accumulator build (§3.1) and the AABB sweep.

---

## 3. Integration

### 3.0 Which integrator runs (P)

`FUN_009001B0`:
- island+0x0C == 0 → `FUN_008EC5B0`;
- else, if max(island+0x4C, island+0x1C) < sim+0xE8 (70) → `FUN_008FD040` (→ `FUN_008EE2D0`);
- else → the multi-job path.

The return value r (minimum over bodies of max(inactive count 0, count 1), §3.5) clears job+8 when r < 6 (line 204). The boat switches
from 6a to 6b in the step after its first contact point is added. That the contact constraint enters the island through the post-collide
deferred commands is I (S1/N1).

### 3.1 Accumulator build, solver path: `FUN_008EDCF0(stepInfo, ents, n, 0xD0, acc)` (P, `dis_8edcf0_c.txt`)

The jump table at 0x8EE2A0 sends types 0, 4, 5 and 8 to 0x8EDD36. Type 1 is skipped (writes nothing). Types 2/3 are the sphere path,
6 keyframed, 7 fixed, 9 character. One record is 0x80 bytes; record 0 is the fixed world body, zeroed by `FUN_008FD040`, and entity+0x90
= 0x80·(i+1). For the box:

```
dt = f32(step->dt)
lf = f32(1.0 - x87(linearDamping * dt)); if (lf < 0) lf = 0      // fcom 0, test ah,5 / jp: NaN kept
v[k] = f32(lf * v[k]), k = 0..3                                   // m+0xD0, stored back into the motion
af = f32(1.0 - x87(angularDamping * dt)); if (af < 0) af = 0
w[k] = f32(af * w[k]), k = 0..3                                   // m+0xE0, stored back
acc+0x50/+0x60/+0x70 = transpose(R)        (FUN_00893AD0: rows of R, w = 0)
acc+0x00 = 0 (type byte, dynamic); acc+0x01 = 0; acc+0x04 = u32 deactivationClass
acc+0x30 = m+0xC0..0xCC                    (invIx, invIy, invIz, invMass)
acc+0x10 = v                               (world-space, already damped)
frac = f32((step->start - com0.w) * com1.w);  omf = f32(1 - frac)
acc+0x40[k] = f32(com0[k]*omf + com1[k]*frac), k = 0..3     // COM at the step start (P). That the Jacobian builder reads it is I; StAppGrav zeroes it before the solve.
acc+0x20.x = f32((w.y*acc[0x60].x + w.x*acc[0x50].x) + w.z*acc[0x70].x), .y, .z alike  (= Rᵀ·ω); acc+0x2C = 0
```

So on the solver path **damping is applied before the solve, to the velocity that already holds this step's action impulses, and gravity is
not yet in it.** On the single-object path the order is gravity first, then damping (§3.4).

### 3.2 What the solver hands the integrator (interface to S1)

`FUN_008EE2D0` reads these per-body accumulator fields (P, §3.3):
- acc+0x10 → the new stored linear velocity;
- acc+0x20 → the new angular velocity, in accumulator (body) frame, mapped to world by R;
- acc+0x40 → the linear velocity used to move com1;
- acc+0x50 → the angular velocity used to rotate rot1, in body frame.

The multi-job equivalents of the substep work show what the single-CPU solver `FUN_00A2F840` has to produce. The decomp is coherent, but
that `FUN_00A2F840` inlines the same code is I:
- `FUN_00A27F40` (StAppGrav, per substep): for each dynamic record, acc+0x40..+0x5C = 0, then acc+0x10[k] += solverInfo+0x10[k] (g·dt'/4).
- `FUN_00A28060` (StIntVel, per substep):
  - First a **slow-body velocity reduction** using the class record (si + 0x64 + 0x1C·acc+0x04):
    - per lane: r = th[1]·|ang| + |lin|·th[0];
    - if all three lanes ≤ si[0] (1.0): when all are also ≤ th[3], v = ω = 0; otherwise both are scaled by th[2].
    - The class-2 record is (11.111, 12.346, 0.968, 0.05, …) (`fork_8ec5b0.md` §4).
  - Then sumVel += (vel − sumVel)·si+0x30 (integrateVelocityFactor 0.818).
  - On the last substep, sumVel *= si+0x120 · si+0x40 (invNumSteps · invIntegrateVelocityFactor).
  - The non-last-substep branch also rewrites the velocities. **Not transcribed; S1 must do it.**
  - The step list above is read from the decomp only, not checked against the disassembly.

**The single-CPU solver `FUN_00A2F840` contains the same code inline** (P for the structure, export decomp
`havok_contact/d_a2f840.txt`; arithmetic not transcribed):
- line 2414 and line 2623 index the class record as `si + class·7 + 0x19` (floats), i.e. si+0x64+0x1C·class;
- lines 2502/2506/2713/2717 do the 0xBF65A0 reset;
- lines 2576/2581/2816/2821 use the si+0x30 factor;
- line 884 forms the si+0x120·si+0x40 scale;
- line 2405 is the last-substep test against si+0x114.

**This slow-body reduction exists only on the solver path.** `FUN_008EC5B0` has none (`fork_8ec5b0.md`). A boat resting on rock is
where it shows: velocities ×0.968 or zeroed. The S1 port owns it.

### 3.3 `FUN_008EE2D0(si, step, acc1, ents, n, 0xD0)` — solver-path integrator, box path (P, `dis_8ee2d0_c.txt`)

cdecl, returns int. A persistent 1.0 stays on the x87 stack across the loop (`fld1` at 0x8EE2FB, re-pushed at 0x8EEDA1 and 0x8EF3CD), and
the a.w formula consumes it (0x8EEC41). The jump table at 0x8EF414 maps types:
- 0/8 → 0x8EE319 (inverse-inertia path);
- 2/9 → 0x8EE60B;
- 3 → 0x8EE512;
- **4 → 0x8EE3C2**;
- 5 → 0x8EE497;
- 6 → 0x8EE55B;
- 1/7 → 0x8EEDA3, which skips integration but still runs the post-clamps and deactivation.

```
result = 0x7FFFFFFF
for i in 0..n-1:  m = ents[i] + 0xD0;  a = acc1 + 0x80*i
  // --- type 4 (0x8EE3C4..0x8EE492) ---
  v = a+0x10 (4 lanes, fld/fstp copies)                          -> m+0xD0..DC
  aa = (f32 a+0x20, a+0x24, a+0x28)
  w.x = f32(x87((R00*aa.x + R10*aa.y) + R20*aa.z))               // Rjk = column j (m+0x10+0x10j), row k
  w.y = f32(x87((R11*aa.y + R01*aa.x) + R21*aa.z))
  w.z = f32(x87((R02*aa.x + R12*aa.y) + R22*aa.z));  w.w = 0     -> m+0xE0..EC
  pl  = a+0x40..0x4C (4 lanes)                                    // position-integration linear velocity (local)
  pa  = R·(a+0x50) by FUN_0088EB30 (x87, same grouping as the transform rebuild), pa.w = 0
  // --- finiteness guard (0x8EE68D..0x8EE991), same rules as fork_8ec5b0.md §3.1 but on pl/pa ---
  ok = for x,y,z lanes of pl and pa: |lane| < 1e6 (0xCDCA20.., strict, false for NaN) and lane == lane
  if (!ok) pl = pa = (1, 0, 0, 0)                                  // 0xBF65A0
  // --- swept transform, linear ---
  com0 = com1 (fld/fstp); com0.w = step->start
  L = f32(x87((pl.x*pl.x + pl.y*pl.y) + pl.z*pl.z))
  mL = UF8[m+0xBC]
  if (L > x87(mL*mL)) {                                            // fcom; test ah,0x41; jne skip -> strict, NaN skips
      s = f32(sqrt(L)); k = f32(f32(1/s) * mL); pl[j] = f32(k * pl[j]), j = 0..3   // the LOCAL pl is clamped
  }
  dtf = f32(step->dt)
  com1[j] = f32(x87(pl[j]*dtf + com1[j])), j = 0..3;  com1.w = step->invDt
  // --- rotation ---
  q = rot1 (integer copy); rot0 = rot1 (fld/fstp)
  hdt = f32(step->dt * 0.5)                                        // f64 0.5 at 0xBEA940
  ax = f32(hdt*pa.x); ay = f32(hdt*pa.y); az = f32(hdt*pa.z)
  x  = f32(f32(x87((ax*ax + ay*ay) + az*az)) * 0.40528471201320165)   // f64 0xB59C20 = 4/pi^2
  lim = f32(UF8[m+0xBD] * step->dt)
  if (lim > 0.8999999761581421 /*f64 0xB59C18*/) lim = 0.9f /*f32 0xB596B4*/   // fcom; test ah,0x41; jne -> strict
  l2 = f32(lim*lim)
  if (l2 < x || unordered) {                                       // fcomp; test ah,1; jne -> C0 set (also NaN)
      s = f32(sqrt(x)); k = f32(f32(1/s) * lim)
      pa[j] = f32(k*pa[j]) (dead afterwards);  ax = f32(ax*k); ay = f32(k*ay); az = f32(k*az)
      x = l2
  }
  x2 = f32(x*x)
  aw = f32(x87(((1 - 0.8229479789733887*x) - 0.1305290013551712*x2) - x2*(0.04440800100564957*x)))  // f64 0xB59C10/08/00
  q = (ax, ay, az, aw) ⊗ q        // FUN_00423F80, SSE f32, fork_8ec5b0.md §6.1
  normalize(q)                    // FUN_00423EB0: n = ((x²+y²)+z²)+w² (SSE); n == 0 -> q = 0; else q *= f32(1/x87sqrt(n))
  deltaAngle = (f32(ax+ax), f32(ay+ay), f32(az+az), f32(aw+aw))
  deltaAngle.w = f32(f32(sqrt(x)) * 3.1415927410125732)            // f64 0xB59660
  rot1 = q
  R = quatToMatrix(rot1)          // FUN_0088D070, x87, fork_8ec5b0.md §6.3; writes m+0x10..0x3C, w = 0
  c = comLocal (m+0x90..98, each copied through an f32 slot)
  t.x = f32(com1.x - f32(x87((R10*c.y + R00*c.x) + R20*c.z)))
  t.y = f32(com1.y - f32(x87((R11*c.y + R01*c.x) + R21*c.z)))
  t.z = f32(com1.z - f32(x87((R12*c.y + R02*c.x) + R22*c.z)))
  t.w = f32(com1.w - 0.0 /*f64 0xBEA968*/)                         -> m+0x40..4C
  // --- (type 8 only: angular-momentum re-derivation 0x8EEDAD..0x8EEE4F) ---
  // --- post-clamps on the STORED velocities (0x8EEE51..0x8EF06B) ---
  V = f32(x87((v.y*v.y + v.x*v.x) + v.z*v.z));  W = f32(x87((w.y*w.y + w.x*w.x) + w.z*w.z))
  mA2 = f32(UF8[m+0xBD]^2);  mL2 = f32(UF8[m+0xBC]^2)
  if (mL2 < V || isnan(V)) {     // fcomp; test ah,5; jnp -> clamp when C0 only; unordered falls to a NaN self-test of V
      k = f32(f32(1/f32(sqrt(V))) * UF8[m+0xBC]); v[j] = f32(v[j]*k), j = 0..3
      if (isnan(V)) v = (1,0,0,0)
  }
  same for w with mA2, W, UF8[m+0xBD]                              // the 9.551 rad/s cap
  // --- deactivation bookkeeping (0x8EF06D..0x8EF3CD): identical to fork_8ec5b0.md §4 (§3.5 here) ---
  result = min(result, max(u8(m+0x0C)&0x7F, u8(m+0x0A)&0x7F))
return result
```

Decomp hazards (P): Ghidra's "unreachable blocks" 0x8EE875–0x8EE92C and 0x8EF039/0x8EEF69 are the NaN branches (self-compare and NaN
reset). Ghidra drops them; the port must keep them.

### 3.4 `FUN_008EC5B0` — single-object integrator (boat afloat). Full transcription: `s2/fork_8ec5b0.md` (P, bit-exact replay)

The box path in order:
1. Gravity: v[k] = f32(gAccPerStep[k] + v[k]) on all 4 lanes, with gAccPerStep = world+0x1C0 = f32(g·dt').
2. Damping: v *= max(0, f32(1 − linD·dt)), then ω *= max(0, f32(1 − angD·dt)). The products are not rounded; the w lanes are included.
3. Finiteness guard on the **stored** v and ω, then common integrate:
   - com0 = com1, com0.w = start;
   - linear clamp of the **stored** v when L > UF8[maxLin]² (strict);
   - com1 = f32(v·dtf + com1), com1.w = invDt;
   - rot0 = rot1;
   - the rotation step as in §3.3, but the angle-limit branch scales the **stored** ω;
   - deltaAngle, R, t as in §3.3.
4. **No post-clamps**: |ω| is bounded only by the angle limit (π·UF8[maxAng] ≈ 30.0 rad/s for the boat).
5. Deactivation as in §3.5.

Ghidra's 12 "unreachable blocks" are the NaN branches (P, `fork_8ec5b0.md` §3.1).

**The differences between the two integrators that a port must reproduce (all P):**

| Item | `8EC5B0` (no constraints) | `8EE2D0` (solver) |
|---|---|---|
| Gravity | +g·dt' once, before damping | inside the solve: 4 × f32(g·dt'/4) (§3.2) |
| Damping | after gravity, in the integrator | before the solve, in `8EDCF0` |
| Velocity that moves the body | stored v, ω | solver's acc+0x40 / R·acc+0x50 |
| Stored velocity after the step | the clamped v, ω | acc+0x10, R·acc+0x20, then post-clamped |
| Finiteness guard applies to | stored v, ω | the position velocities |
| Pre-move linear clamp scales | stored v | local position velocity |
| Angle-limit scaling scales | stored ω | local (dead) |
| Post-clamps (136.2 m/s, 9.551 rad/s, rounded squares, NaN → (1,0,0,0)) | none (box path) | yes |
| Slow-body velocity reduction | none | yes (in the solver, §3.2) |

### 3.5 Deactivation, as far as it can stop the body

The per-body counters are the same code in both integrators (P; `fork_8ec5b0.md` §4 is the line-level transcription; this run checked
0x8EF06D–0x8EF3CD against it):
- The counter m+0x09 increments each step. Sample idx 0 runs every 4th step and idx 1 every 16th; 0xFF means never.
- Energy max: refPos[idx].w = max(refPos.w, f32(min(r,1)²·|ω|² + |v|²)).
- Distance test |refPos − com1|² against maxDistSqrd[idx]. Orientation test: |unpack(refOri) − rot1|² against the hkHalf maxRotSqrd[idx]
  from class record si+0x64+0x1C·m+0xBE.
- Inactive → the u16 count increments, saturating at 64. Otherwise the count resets, refPos = (com1, 0) and refOri = pack(rot1)
  (`FUN_00A06EA0`).

The class-2 record values are in `fork_8ec5b0.md` §4. The capture has count[0] = 5 and count[1] = 0.

The island-level stop, `FUN_008FE2E0` lines 39–41 (P for the condition):
- if job+8 ≠ 0 (r ≥ 6), wantDeactivation (W+0xC5 = 1), (island+0x26 & 0xC) ≠ 0 and (island+0x25 & 0xC) == 0, it calls
  `thunk_FUN_024E3FA0(world, island)` = splice 0x6B2050.
- That splice is a **terminal SecuROM stub**: emulation enters `0x6ACBE0` (a lock) and then an import. What it does is NOT DETERMINED; it
  must be read live or by VM tracing.
- The capture's island has +0x25 = 0x00 and +0x26 = 0x05, so the boat island qualifies once r ≥ 6.

### 3.6 `FUN_008EBE80` (named in the brief): the reintegrate path, not reached by the boat

**Callers (P).**
- A whole-file rel32 scan (`reint_refs2.txt`) finds only two calls to 0x8EBE80: 0x8F43FA in `FUN_008F4330` and 0x92E4D9 in `FUN_0092E400`.
- `FUN_0092E400` is slot 12 (+0x30) of the multithreaded sim vtable (pointer at 0xB59E34). `FUN_008F4330` is the same slot of the
  single-threaded sim vtable (pointer at 0xB59C84).
- `FUN_0092E400` re-sweeps the motion states to a time (`FUN_00897520`), calls `8EBE80` and `8EF520`, and then optionally runs the
  broadphase and narrowphase. Its flags are the reflected `hkpWorld::ReintegrationRecollideMode`: 1 = REINTEGRATE,
  2 = RECOLLIDE_BROADPHASE, 4 = RECOLLIDE_NARROWPHASE (`enums.txt`). That makes it reintegrateAndRecollideEntities (I, name).

**The world wrapper (P).** The slot's only world-level entry is `FUN_008D6540`. When the world is locked, it queues deferred operation
0x16, which `FUN_008F8AF0` replays through the same slot +0x30. **`FUN_008D6540` has no reference anywhere in the exe**: no rel32
call or jump, and no absolute pointer (`reint_refs.txt`, `reint_refs2.txt`).

**Conclusion (I).** The boat never reaches `8EBE80` through static code. A call from SecuROM VM code with a computed target cannot be
excluded statically. Not transcribed.

---

## 4. hkpBoxMotion virtuals and the Rust boat (summary; full table and arithmetic in `s2/fork_motion.md`, P unless marked)

- **Vtable 0xB5921C, 25 slots.**
  - 16 setLinearVelocity (+0x40) and 17 setAngularVelocity (+0x44) are 4-lane copies.
  - 18 applyLinearImpulse (+0x48): v_i = f32(x87(J_i·invM + v_i)) on 4 lanes.
  - 19 applyPointImpulse (+0x4C): the linear part as slot 18, then ω += R·(invI ∘ Rᵀ·((p − com1) × J)) with the grouping in
    `fork_motion.md` 4.1.1.
  - 20 applyAngularImpulse (+0x50): ω += R·(invI ∘ Rᵀ·J).
  - 21 applyForce(dt, f, p) (+0x54) forms J = f32(dt·f) and calls slot 19.
  - 22 applyForce(dt, f) (+0x58): v_i = f32(invM·f32(f_i·dt) + v_i).
  - 23 applyTorque (+0x5C) forms J = f32(dt·τ) and calls slot 20.
  - 6 getInertiaWorld (+0x18) = R·D·Rᵀ; 10 getInertiaInvWorld (+0x28) = (R·diag(invI))·Rᵀ.
  - All motion slots are x87.
- **World inverse inertia** is never stored. It is applied as R·diag(m+0xC0..C8)·Rᵀ, with R the 3×3 columns at m+0x10, rebuilt from rot1
  at the end of each integration.
- **getProjectedPointVelocity is not a motion virtual.** The contact path uses `FUN_00412710(p, out)` on the entity:
  v + ω × (p − com1), SSE f32. The order of the final "+ v" adds is I.
- **The boat action `0x447260`** (actor vtable 0xBA9340, slot 3, P in the capture):
  - It returns early if 1e-4 > dt'.
  - It calls slots +0x48, +0x4C (×4 buoyancy), +0x50 and +0x44, plus setLinear/AngularVelocity through the self-righting code
    `0x944AB0`, each after `FUN_008DDA50` (activate).
  - It never uses slots 21–23. Its own arithmetic is SSE f32.
- **`boat.rs` vs the exe** (16 items in `fork_motion.md` 4.3). The ones that change numbers:
  1. One integrator instead of the two in §3.4, with their different gravity/damping order and velocity sources.
  2. No caps: 136.2 m/s, 9.551 rad/s post-clamp (solver path), and the per-step angle limit min(UF8·dt, 0.9) on both paths.
  3. No finiteness guard. Note the reset value is **(1, 0, 0, 0)** (§0.5), not (0, 0, 0, 1).
  4. Exact half-angle `from_scaled_axis` instead of the cubic a.w with x = θ²/π², then dq ⊗ q and renormalise.
  5. Impulses divide by mass instead of multiplying by the stored f32 invMass, and use the quaternion instead of the stored matrix R.
  6. Hard-coded 0.8 damping applied together with gravity on one path. The exe reads m+0xB8 and orders gravity/damping per path.
  7. No swept transform, deltaAngle, time stamps or deactivation state. The AABB sweep, the narrowphase and the island stop read these.
  8. Contacts are resolved inside the same step after the move, with position correction on `origin`. The exe solves step N with the
     manifold from step N−1's post-integrate collide and never moves the body outside the integrator (§1.1).
  9. raw dt instead of dt' (§2). The 1e-4 gate skips the whole Rust step; the exe skips only applyAction.
  10. f32 SSE everywhere, while the exe's integrators and motion slots are x87 at 53-bit precision (§6.2).

---

## 5. After integration: the AABB, and what the narrowphase receives (P unless marked; full detail `s2/fork_aabb.md` A)

`FUN_008EF520(CI, ents, n)`:
- halfTol = f32(tolerance·0.5) = 0.05. The boat has 13 children (entity+0x50), so it takes the child path.
- Per child it computes the current AABB at the post-integrate transform: child getAabb (+0x1C) with halfTol. For a convex-vertices child
  that is `FUN_008BBE50`: ext = Σ|R·he| + radius + halfTol.
- It then builds a swept box:
  - from the start-of-step transform T0 (rot0, com0) and the inverse current transform (`FUN_008CFDA0`; one intermediate transform with
    lever 1/(1 − a²/2) when a = deltaAngle.w < π/8);
  - plus rotation growth e' = min(e + |e|·a, |e|).
- Quantisation: fistp((offset + x)·scale), clamped to [0, 2147352576], with offset CI+0x20/+0x30 = (4096, 1000, 4096) and scale CI+0x40.
- Each hkAabbUint32 child record holds the current box and the swept growth in expansion bytes (truncating shift encoding).
- entity+0x30 holds the union (plus com1). The padding byte +0x1F holds the child's rank by min.x (quicksort `FUN_008F21A0`).

The broadphase (`FUN_0092CB10`, step 9) then takes min − (expMin << shift) and max + (expMax << shift) per entity. If min.x > max.x
it calls `FUN_008EF520` itself first.

**Produced by S2, read by N1/N2 and the broadphase:**
- motionState.transform (m+0x10..0x4C);
- the swept transform (com0 with w = t_start, com1 with w = invDt', rot0, rot1, comLocal);
- deltaAngle (w = angle);
- objectRadius;
- entity+0x30 bounding volume and the 13 child records;
- linear/angular velocity, for the contact manager's point velocity `FUN_00412710` and the impulse seed in `FUN_008D3DA0`;
- stepInfo copies in CI+0x50 and in the narrowphase job.

Capture (`fork_aabb.md` A.5):
- Child 11's current AABB reproduces bit-exactly from the captured post-integrate transform (P).
- The entity record equals child 11's record (P).
- The expansion bytes are **one count larger** than the derived formula gives (0x22/0x8A/0x22 vs 0x21/0x89/0x21): NOT DETERMINED (§8).

---

## 6. Capture consistency checks and precision

### 6.1 Integration replay (P, `replay_8ec5b0.py` → `replay_8ec5b0.txt`, re-run this session: `replay_rerun.txt`, exit 0)
Model: each x87 operation rounded to double, f32 only at the stores. Inputs: the captured com0, rot0, stepInfo, v, ω and comLocal.
All 26 outputs match **bit-exactly**: com0.w = start, com1.w = invDt', t.w, com1.xyz = com0 + v·dt', rot1.xyzw, deltaAngle.xyzw
(xyz = 2a, w = π·sqrt(x)), R[9] (quat → matrix of rot1), and t = com1 − R·comLocal. With every operation rounded to f32, rot1.y/z/w
are 1 ulp off, so the step did not run at 24-bit x87 precision.

### 6.2 FPU state (P, `fpu.py` → `fpu2.txt`, minidump thread contexts)
- The main thread (`___tmainCRTStartup` on its stack, `stacks.txt`) has FCW **0x027F**: precision 53-bit, round to nearest, all
  exceptions masked. Its MXCSR is 0x1FB7: FTZ = 0, DAZ = 0, round to nearest, masked.
- 27 of the 28 threads have FCW 0x027F. One worker, tid 11456 inside `FUN_00876400`, has **0x007F (24-bit)**.
- Which thread ran the captured Havok jobs is NOT DETERMINED. The main thread processes jobs through `FUN_008D61A0` → `FUN_008F6EA0`,
  and a Pimp worker can take them. The replay says the captured step ran at 53- or 64-bit.
- **Port rule (I):** evaluate each x87 expression in f64 and round to f32 at each store; SSE code is f32. A step executed on a
  24-bit thread would differ in the last bit.

### 6.3 Other values checked in the capture (P, `cap1.txt`)
world+0xA0 = 1, +0xC5 = 1, +0xD0 = 0, +0xB8 = 1, +0xA4 = 1; one active island. The island has 1 action, 1 entity, 0 constraints and
agent sector data at +0x58..+0x68 (entry 0x1EB17E00). sim+0xE8 = 70.

---

## 7. Interfaces

**From S1 (solver), into S2:**
- per body, the 0x80-byte accumulator after the solve: acc+0x10 lin vel (world), acc+0x20 ang vel (body = Rᵀ frame), acc+0x40 sum lin vel
  (world), acc+0x50 sum ang vel (body);
- the solve success flag (`FUN_00A2F840` returns 1); `8EE2D0` runs only when it is 1;
- S1 also owns the slow-body reduction and the gravity-per-substep code (§3.2).

**From S2, into S1:**
- damped v and ω in the motion;
- accumulators built by `8EDCF0` (§3.1), including the COM at step start at acc+0x40 and Rᵀ at +0x50/+0x60/+0x70;
- solverInfo substep fields (§2);
- the constraint query input `FUN_008F4590` (S1 to transcribe).

**From S2, into N1/N2:** the list in §5. The collide of step N runs on these values, and its manifold is solved in step N+1.

---

## 7a. Read while porting (objdump of the same image; all P)

- **setPosition `0x897F30` and setPositionAndRotation `0x897CA0`** keep com0.w and set com1.w to 0. (§4's
  "com1 = com0" for slot 14 is the positions only.)
- **Motion constructors `0x8DF590` / `0xA071D0` / `0xA06F60`**: comLocal = 0, objectRadius = 1, the deactivation
  counter `0xFF` (never sampled); `+0xBC..+0xBE` are the caller's to set. The box constructor is `0x8F6030`.
- **Deactivation is switched on by `0x8D52D0`** (type 2): counter = uid & 0xF, then `0x6AF2D0(sel0, sel1,
  frameCounter)` sets bits 14–15 of the two counts. Its one input from outside the motion is the body's uid.
- **World-time reset `0x8FA4A0`**: d = f32(end − start); dt' = d (not recomputed); inv = f32(1/d) with no zero
  guard; each body's com0.w += shift. Psi starts at 0 (simulation constructor `0x8F2320`). The reset also shifts
  simulation `+0x14` / `+0x20`, the island agents' times (`FUN_008EB290` → `0x908CE0`) and calls simulation
  slot `+0x38`.
- **getMass `FUN_008DF470`** returns f32(1 / invMass): 7999.9995 (`0x45F9FFFF`) for the boat, whose stored
  invMass is f32(1/8000). The boat action scales every impulse by it.

## 8. NOT DETERMINED (what was tried)

1. **The body of splice 0x6B2050 (island deactivation).** Emulation reaches a lock and an import, so it is VM code. Next: a live read,
   or a VM trace with real arguments.
2. **AABB expansion bytes one count high.** Tried the shift/sar, |e| and clamp code, `8CFDA0` by emulation, and the lever term. Next:
   emulate `FUN_008EF520` on the captured memory.
3. **`FUN_008CFDA0` branch for a ≥ π/8** (multi-transform). Not transcribed; the boat's a is about 0.002.
4. **Which thread ran the step, and so whether 24-bit precision ever applies.** Thread FCWs were read; the job→thread assignment was
   not. Next: read how the worker `FUN_00876400` dispatches ring job type 6 (`DAT_00D2D9C4` = 6, pushed by `FUN_004036F0`). If type 6 runs
   Havok job processing, physics can run on the 24-bit thread tid 11456.
5. **The exact arithmetic of the slow-body reduction and of the velocity accumulation inside `FUN_00A2F840`.** The structure is P (§3.2);
   the arithmetic belongs to S1.
6. **The agent → contactMgr slot 3/5 call site** and the phase of the confirmed callback (empty for the boat).
7. **Island +0x1C, +0x25, +0x26 field meanings.** Only the tests are known.
8. **The x87 order inside the world-time reset formulas (§2.2).** Decomp only.
9. **Splice 0x6B1C80 in stepBegin.** Emulated as a no-op (I); not traced with a real world pointer.
10. **The solver-path integrator against a capture.** None of the captures read so far has the boat in contact.
    `8EE2D0` is P by transcription only, not by replay.
11. **The fallback allocation path at 0x8FD13D** (SecuROM terminal stub). The normal path skips it (0x8FD108 `jbe` → 0x8FD262, P),
    so it has no effect on the numbers (I).

**Corpus.** `corpus_search` ran late in the run, and its index reports stale (29 files changed). `corpus_xref` was run on
0x8EBE80 and 0x92E400. Two pages claim the per-frame integrator "does not decode in either build": `docs/reverse_engineer/physics_code_map.md`
§10 and `tools/wad_simulator/docs/modernization/physics_havok_spec.md` rationale 2. **This spec supersedes that claim for PC.**
`8EC5B0` decodes from disassembly and replays bit-exact; `8EE2D0` decodes once its SecuROM split is patched.

Sources: the export, objdump, splice emulation and a scratch Ghidra project
(`s2/ghidra/proj`, import of a patched copy, `-noanalysis`) were the sources. No saved project, lock file or Ghidra process was touched.
