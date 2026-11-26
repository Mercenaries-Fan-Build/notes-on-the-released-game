> SUPERSEDED IN PART by `../s2_step_integrate_spec.md`: item 9's reset vector at 0xBF65A0 is (1,0,0,0), not (0,0,0,1) (spec §0.5). Item 8: the 9.551 rad/s post-clamp exists only on the solver path `8EE2D0`; on the afloat path `8EC5B0` ω is bounded only by the angle limit, about 30 rad/s (spec §3.4). Items 5–7 are resolved in spec §3.

# Part 4: hkpBoxMotion virtuals (vtable 0x00B5921C), the boat action's motion calls, and the Rust diff

Grades: **P** = PROVEN (read this run, address given), **I** = INFERRED, **S** = SPECULATIVE, **HK** = Havok
naming recalled from memory, used only as a label. Exe: `mercs2_unpacked.exe` sha256 `8c179a99…bc7ba`.
Evidence files: `s2/fm/dis_8f6xxx.txt`, `s2/fm/dis_8dfxxx.txt`, `s2/fm/dis_8945f0.txt`, `s2/fm/dis_894770.txt`,
`s2/fm/dis_893ad0.txt`, `s2/fm/dis_412710.txt`, `s2/fm/dis_447260.txt`, decomps `s2/ghidra/out/decomp1.txt`
(scratch, lines 2675–3405) and `s2/fm/fn_*.txt` (export). Motion offsets are from the start of the motion
(entity + 0xD0). The motion layout used (hkpMotion reflection, P): +0x08 type, +0x09 deactivationIntegrateCounter,
+0x0A/+0x0C deactivationNumInactiveFrames[2], +0x10 motionState = {+0x10 rotation col0, +0x20 col1, +0x30 col2,
+0x40 translation, +0x50 com0, +0x60 com1, +0x70 rot0, +0x80 rot1, +0x90 comLocal, +0xA0 deltaAngle,
+0xB0 objectRadius, +0xB4 linearDamping, +0xB8 angularDamping, +0xBC maxLinVel u8, +0xBD maxAngVel u8,
+0xBE deactivationClass}, +0xC0 inertiaAndMassInv (invIx, invIy, invIz, invMass at +0xCC), +0xD0 linearVelocity,
+0xE0 angularVelocity. Rotation storage is column-major: col k at +0x10+0x10k (P from the products below:
R·x = col0·x.x + col1·x.y + col2·x.z).

## 4.0 Structural facts (P)

- Base hkpMotion vtable 0xB58B94 (written by the base ctor `0x8DF590`, 0x8DF59F) has `0x9EE286` (purecall) in
  slots 5–10 and 19–23 (`s2/fm/vt_actor.txt`). These slots are per-motion-type. Slots 11–18 and 24 are base
  implementations shared by box (0xB5921C) and fixed (0xB592EC) motions.
- The box ctor `0x8F6030` calls the base ctor, writes vtable 0xB5921C (0x8F6048), sets inertiaAndMassInv =
  (1,1,1,1) and type byte = 4 (0x8F6068).
- **No box-motion slot activates the body or calls non-motion code.** Activation (`FUN_008DDA50`,
  hkpEntity::activate HK) is called by the *caller* before each call (boat code, §4.2). Only three slots call
  another virtual: slot 3 → slot 4, slot 21 → slot 19, slot 23 → slot 20.
- **All of these slots are x87 code** (fld/fmul/fadd, no SSE). Values are rounded to f32 only where stored
  (`fstp dword`); inside one expression the products and partial sums stay in x87 registers, so their precision is
  the x87 precision-control setting (not read here; the parent reads the capture's FloatSave ControlWord).
  The boat's own code (`0x447260` and callees) and `FUN_00412710` are **SSE scalar** (movss/mulss), i.e. true f32.

## 4.1 The 25 slots

| Slot (offset) | VA | Role from code | Name (HK label) |
|---|---|---|---|
| 0 (+0x00) | 0x8DE5C0 | sets hkBaseObject vtable, frees if flag&1 | scalar deleting dtor |
| 1, 2 | 0x88C5B0, 0x88C600 | shared by all hkReferencedObject classes; not read | hkReferencedObject virtuals |
| 3 (+0x0C) | 0x8F6010 | `this->vt[+0x10](f32(1/m))` (0x8F6016–0x8F6029) | setMass |
| 4 (+0x10) | 0x8DF4A0 | `+0xCC = arg` | setMassInv |
| 5 (+0x14) | 0x8F6070 | out 3×4 = 0, diag = (1/+0xC0, 1/+0xC4, 1/+0xC8) | getInertiaLocal |
| 6 (+0x18) | 0x8F62D0 | same diag D, then `0x894770(out, R)` = R·(D·Rᵀ) | getInertiaWorld |
| 7 (+0x1C) | 0x8F60F0 | `+0xC0..C8 = 1/M[0][0], 1/M[1][1], 1/M[2][2]` (reads offsets 0, 0x14, 0x28); +0xCC kept | setInertiaLocal |
| 8 (+0x20) | 0x8F61C0 | `+0xC0..C8 = M diag` copy; +0xCC kept | setInertiaInvLocal |
| 9 (+0x24) | 0x8F6150 | out = diag(+0xC0, +0xC4, +0xC8), rest 0 | getInertiaInvLocal |
| 10 (+0x28) | 0x8F6210 | A = (col0·invIx, col1·invIy, col2·invIz) (4 lanes each), out = `0x8945F0(A, R)` = A·Rᵀ | getInertiaInvWorld |
| 11 (+0x2C) | 0x8DF3C0 → `0x896A40(c, ms)` | Δ = c − comLocal; comLocal = c; com0.xyz += R·Δ; com1.xyz += R·Δ (decomp; I for operand order) | setCenterOfMassInLocal |
| 12 (+0x30) | 0x8DF3E0 → `0x897F30(p, ms)` | deltaAngle = 0; translation = p; com0.xyz = p + R·comLocal (w kept); com1 = com0 with w = 0; rot0 = rot1 (decomp, I) | setPosition |
| 13 (+0x34) | 0x8DF400 → `0x898060` → `0x897CA0(translation, q, ms)` | rotation only | setRotation |
| 14 (+0x38) | 0x8DF420 → `0x897CA0(p, q, ms)` | deltaAngle = 0; rot0 = rot1 = q; R = matrix(q) (`0x88D070`); translation = p; com0 = p + R·comLocal (w kept); com1 = com0, com1.w = 0 (decomp, I) | setPositionAndRotation |
| 15 (+0x3C) | 0x8DF440 → `0x897DF0(T, ms)` | deltaAngle = 0; q from T; rot0 = rot1 = q; com0 = T.t + T.R·comLocal; com1 = com0, w = 0 (decomp, I) | setTransform |
| 16 (+0x40) | 0x8DF4D0 | `+0xD0..DC = v` (4 floats) | setLinearVelocity |
| 17 (+0x44) | 0x8DF500 | `+0xE0..EC = ω` (4 floats) | setAngularVelocity |
| 18 (+0x48) | 0x8DF530 | `v_i = J_i·invM + v_i`, i = x,y,z,w | applyLinearImpulse |
| 19 (+0x4C) | 0x8F6480 | linear as slot 18, then ω += R·(invI ∘ (Rᵀ·((p − com1) × J))) | applyPointImpulse(J, p) |
| 20 (+0x50) | 0x8F6670 | ω += R·(invI ∘ (Rᵀ·J)) | applyAngularImpulse(J) |
| 21 (+0x54) | 0x8F63E0 | `J = f32(dt·f)` (4 lanes), then `vt[+0x4C](J, p)` | applyForce(dt, f, p) |
| 22 (+0x58) | 0x8F6350 | `t = f32(dt·f)`, `v_i = invM·t_i + v_i` (4 lanes) | applyForce(dt, f) |
| 23 (+0x5C) | 0x8F6430 | `J = f32(dt·τ)`, then `vt[+0x50](J)` | applyTorque(dt, τ) |
| 24 (+0x60) | 0x8DF680 | copies motionState (`0x6B2590`), +0xD0..EC and byte +0x09 into the arg motion | getMotionStateAndVelocitiesAndDeactivationType |

Overload order note: slot 21 has 3 args (`ret 0xC`, 0x8F6427) and slot 22 has 2 (`ret 0x8`, 0x8F63DB). P.

**getProjectedPointVelocity is not a box-motion virtual** (no slot computes v + ω×r). The point-velocity code
the contact path uses is **`FUN_00412710(p, out)` on the entity** (called twice by addContactPoint `0x8D3DA0`,
lines 80–81 of its decomp; 21 callers). P from `s2/fm/dis_412710.txt` (SSE scalar):

```
r = p.xyz − com1.xyz              // entity+0x130..0x138 = motion+0x60
out.x = ω.y·r.z − ω.z·r.y + v.x   // 0x412764–0x41277B then + v (decomp line order)
out.y = ω.z·r.x − ω.x·r.z + v.y   // xmm1 = ω.z·r.x − ω.x·r.z (0x412752–0x412760)
out.z = ω.x·r.y − ω.y·r.x + v.z   // 0x412790–0x412798
out.w = v.w
```
(each product and difference is f32; the "+ v" adds come from the decomp, I for their exact instruction order).

### 4.1.1 Exact arithmetic of the slots the boat and solver use (P, x87 order from the listings)

Notation: `x87(e)` means e is evaluated on the x87 stack and rounded to f32 only at the store.

- **slot 18 applyLinearImpulse (0x8DF530):** `m = f32 load +0xCC`; for i in x,y,z,w:
  `v_i = f32( x87(J_i·m + v_i) )`. The product is **not** rounded before the add.
- **slot 22 applyForce(dt,f) (0x8F6350):** `t_i = f32(f_i·dt)` (stored to stack, 0x8F6367–0x8F6380);
  `v_i = f32( x87(m·t_i + v_i) )` (0x8F638E–0x8F63D2).
- **slot 19 applyPointImpulse(J, p) (0x8F6480):**
  1. linear exactly as slot 18 (0x8F648C–0x8F64DE).
  2. `r_k = f32(p_k − com1_k)`, k = x,y,z (0x8F64E4–0x8F64FD).
  3. `c = r × J`, each component one x87 expression then f32:
     `c.x = r.y·J.z − r.z·J.y`, `c.y = r.z·J.x − r.x·J.z`, `c.z = r.x·J.y − r.y·J.x` (0x8F6501–0x8F653F).
  4. `l_k = f32( (col_k.y·c.y + col_k.x·c.x) + col_k.z·c.z )` for k = 0,1,2 (Rᵀ·c; 0x8F6543–0x8F659A;
     the first two terms are summed first, then the z term).
  5. `l_k = f32(invI_k · l_k)` (0x8F659E–0x8F65C4).
  6. `w.x = f32((col1.x·l.y + col0.x·l.x) + col2.x·l.z)`, `w.y = f32((col1.y·l.y + col0.y·l.x) + col2.y·l.z)`,
     `w.z = f32((col1.z·l.y + col0.z·l.x) + col2.z·l.z)` (R·l; 0x8F65C8–0x8F661F).
  7. `ω_k = f32(w_k + ω_k)`; `ω.w = f32(ω.w + (double)0.0)` (0xBEA968 is the double 0.0; 0x8F6623–0x8F665F).
- **slot 20 applyAngularImpulse(J) (0x8F6670):** J.x, J.y, J.z are first copied through f32 stack slots; then
  steps 4–7 of slot 19 with c = J (same grouping: `(col_k.y·J.y + col_k.x·J.x) + col_k.z·J.z`). P.
- **World-space inverse inertia** is therefore never formed as a matrix on these paths: it is applied as
  R·diag(invI)·Rᵀ·x with R = the motion's 3×3 rotation columns (motion+0x10/0x20/0x30, built from rot1 by
  `0x88D070` at the end of the integrator), i.e. **I⁻¹_world = R·diag(+0xC0,+0xC4,+0xC8)·Rᵀ**. The explicit
  matrix form (slot 10) is A·Rᵀ with A's column k = col_k·invI_k (0x8F6219–0x8F62B8, then 0x8945F0 which
  transposes R (`0x893AD0`) and multiplies). P.
- **Inertia values of the boat** (capture, README §1.1): invI = (1.4259e-5, 1.4071e-5, 1.9357e-4), invMass 1.25e-4.

## 4.2 What the boat action calls (P)

- The boat actor `0x1F232400` has vtable 0xBA9340 (capture, `s2/fm/cap_actor.txt`); slot 3 of 0xBA9340 =
  **0x447260** (`s2/fm/vt_actor.txt`). The body's action array (body+0x1F8 → 0x2001A8C0, size 1) holds
  0x1F232400 (`s2/fm/cap_actions.txt`, `cap_body1f8.txt`). Actor +0x08 = world 0x20007800, +0x0C = island
  0x1EE39500, +0x18 = entity 0x1EBB8000.
- `applyAction(stepInfo)` 0x447260: `dt = stepInfo.deltaTime (+8)`; **if 1e-4 (0xB977F8) > dt, return**
  (`comiss; ja`, 0x44727A). Else: contact timers (listener+0x10/+0x14, SSE), then 0x447350 (thrust),
  0x447F00 (steering), 0x4477A0 (springs), 0x448210 (drag) with dt (0x4472B9–0x4472EE).
- Every motion call goes through `entity+0xD0`'s vtable and is preceded by `FUN_008DDA50` (activate). Mass is read
  by `FUN_008DF470` = getMass: `invM == 0 ? 0 : f32(1/invM)` (0x8DF470–0x8DF49D, x87 `fucom` with `jp`).

| Caller | Slot | Use (boat specs: `drive_spec.md` §0.2, `float_spec.md` §C.3, §D) |
|---|---|---|
| 0x447350 thrust | +0x48 applyLinearImpulse | drive and brake impulses (lines 66, 92 of its decomp) |
| 0x447F00 steering | +0x50 applyAngularImpulse | yaw impulse (line 102) |
| 0x4477A0 springs | +0x4C applyPointImpulse ×4, then +0x44 setAngularVelocity | buoyancy at 4 points, then ω.y restored to its value before the loop (lines 192–213) |
| 0x448210 drag | +0x44 setAngularVelocity, +0x48 ×5, +0x50 ×2 | anti-roll, shallow/grounded drag, water drag, handbrake keep, angular damping, extra gravity (lines 201–307) |
| 0x448210 → 0x944AB0 self-righting | setAngularVelocity, setLinearVelocity | `float_spec.md` §F.7 (not re-read here) |

The boat never calls slots 21–23 (applyForce/applyTorque): it builds impulses itself as m·dt·(…). P for the four
callees listed (all `code **` calls enumerated in `s2/fm/boat_calls.txt`).

## 4.3 Differences between `boat.rs` (`Hull`, `Boat::step`, `integrate`) and the exe

Rust file: `/Volumes/Projects/mercenaries-game/tools/wad_simulator/.claude/worktrees/game-parity/crates/mercs2_vehicle/src/boat.rs`.

Impulses (`Hull`):
1. `linear_impulse` does `linvel += impulse / mass` (boat.rs:66). The exe multiplies by the stored f32
   invMass (1.25e-4 = f32(1/8000)): `v += J·invM`. Division vs multiply by a rounded reciprocal differ in
   the last bit. The exe also updates the w lane. P.
2. `angular_impulse` rotates with the quaternion (`rotation * (inv_inertia * (rotation.inverse() * impulse))`,
   boat.rs:72). The exe uses the 3×3 column matrix stored in the motion (built from rot1 by `0x88D070` in the
   previous integration) with the grouping in §4.1.1. Same math, different rounding. P.
3. `point_impulse` uses `com` = `origin + rotation * self.com` computed by the caller (boat.rs:296). The exe uses
   motion com1 (+0x60), which the integrator advanced directly (no round trip through origin). P for the exe
   side; the difference in value is I (rounding only, if self.com equals comLocal).
4. Rust impulses are f32 SSE (glam). The exe slots are x87 with unrounded intermediates (§4.0). P.

Body integration (`Boat::integrate`, boat.rs:485–491) versus the exe integrators:
5. **Which integrator.** The exe integrates the boat with `FUN_008EC5B0` when its island has no constraints
   and with `FUN_008EE2D0` (from solver accumulators) when it does (parent's §3; I here). Rust has one path.
6. **Gravity.** Rust: `linvel.y += -9·dt` (boat.rs:486). Exe single-object path: `v += world+0x1C0`
   (= f32(g·dt), 4 lanes, written by stepBegin) before damping (decomp1.txt 577–580 for the thin-box case; the
   box case is the parent fork's). Exe solver path: gravity enters the solve as g·dt/4 per iteration (world
   +0x1B0), not in the integrator. Rust uses raw dt; the exe's dt is stepInfo.deltaTime
   = f32(f32(psi + dt) − psi) (parent §2). I for the per-iteration split (parent's part).
7. **Damping.** Rust: `angvel *= max(1 − 0.8·dt, 0)` (boat.rs:487), no linear damping. Exe single-object path:
   `v *= max(1 − dt·linearDamping, 0)` and `ω *= max(1 − angularDamping·dt, 0)` (decomp1.txt 581–600; same
   form; linearDamping is 0 so v is multiplied by 1.0). Exe solver path: no damping in `8EE2D0`; it is applied
   when the accumulators are built (`FUN_008EDCF0`, parent's part). Rust hard-codes 0.8 (boat.rs:136) instead
   of reading motion+0xB8.
8. **Velocity caps.** Rust has none. Exe: |v| ≤ maxLinearVelocity = table[0x79] = 136.2 m/s and
   |ω| ≤ maxAngularVelocity = table[0x51] = 9.551 rad/s (0xB13564, 0xB134C4), applied twice (before the move and
   after, decomp1.txt 679–690, 776–793 / 356–374), plus a per-step angle cap: |ω·dt/2|-based test against
   min(maxAng·dt, 0.9) (0xB59C18 double 0.9 compare, 0xB596B4 f32 0.9 store; decomp1.txt 711–713). P for the
   constants; exact formula is the parent's transcription.
9. **Non-finite guard.** Exe resets v and ω to the constant at 0xBF65A0 = (0, 0, 0, 1.0) when any |component| ≥
   1e6 (0xCDCA20..28) or is NaN (decomp1.txt 611–673). Rust has none. P for the constants (exe bytes; the .data
   copies in the capture are not checked here).
10. **Rotation step.** Rust: `q' = normalize(from_scaled_axis(ω·dt) * q)` (exact half-angle sin/cos).
    Exe: `dq = (ω·dt/2, w)` with w a cubic polynomial in x = |ω·dt/2|²·0.40528 (double constants 0xB59C10
    0.82295, 0xB59C08 0.13053, 0xB59C00 0.044408, 0xB59C20 0.405285); `q' = dq ⊗ rot0` (`FUN_00423F80`:
    out = p1⊗p2 Hamilton, p1 = dq, so premultiplied, same composition order as Rust) then
    normalised by `FUN_00423EB0` (`q·1/sqrt(|q|²)`, 0 if |q|² == 0). Results differ at O(θ³) and in rounding.
    P for the helper formulas and constant values; the exact w expression is the parent's transcription.
11. **Position.** Both move the centre of mass: exe `com1.xyz += dt·v` (with com0 = old com1, com0.w = t_start,
    com1.w = invDt), translation = com1 − R(rot1)·comLocal. Rust: `com = origin + R·self.com + v·dt`,
    `origin = com − R'·self.com` (same form). Rust keeps no swept transform (com0/rot0), no deltaAngle and no
    time stamps, which the exe's narrowphase and AABB code read (parent's §5). P exe side (decomp1.txt 674–760).
12. **Centre of mass and inertia values.** Rust `com` = box centre + CenterOfMassOffset (boat.rs:212);
    exe comLocal = (0, 0.82666, −0.0265) (README §1.1). `from_shape` inertia is 2–12 % off the exe's
    (boat.rs:234–237 says so); `captured()` uses the exe values (boat.rs:761).
13. **Deactivation.** The exe updates the deactivation counters and reference position/orientation each step
    (decomp1.txt 375–447 for 8EE2D0). Rust has none.
14. **Contacts.** Rust resolves contacts inside the same step after its move (`rest_on_ground`, `hit_solids`,
    boat.rs:399–400) with its own impulses (`stop_at`, `HullFriction`) and moves `origin` directly. The exe never
    moves the body outside the integrator: contacts from the collide after step N−1's integration are solved in
    step N's solve (tau 0.9 / damp 1.1, 4 iterations, μ = sqrt(0.3·1.0)), then integrated. Rust's contact count
    feeds the next step's timers like the exe's listener count does (I).
15. **The dt gate.** The exe skips only applyAction when dt < 1e-4 (0x44727A); Havok still integrates.
    `Boat::step` returns before integrating as well (boat.rs:381–383). P.
16. **Order inside the step** matches: pre-step (exe `FUN_00446BD0`, actor slot 9, run from `FUN_00416AD0`
    before stepBegin) → applyAction (timers, thrust, steering, springs, drag) → integrate. P for the exe order
    (0x4472B9–0x4472EE; `FUN_00413F90`), boat.rs:384–398.

## 4.4 NOT DETERMINED

- Slots 1 and 2 (`0x88C5B0`, `0x88C600`): not read; they are not motion-specific.
- Slots 11–15: roles are from the export decomp only (I); their x87 order was not transcribed (the boat and the
  step do not call them).
- The x87 precision-control word in force during the step (decides whether the unrounded products in §4.1.1
  matter). Not read here; the capture's thread FloatSave holds it.
- Whether `FUN_00412710`'s final "+ v" adds follow the decomp order: only the cross-product part was read in
  the disassembly listing (0x412716–0x41279C).
