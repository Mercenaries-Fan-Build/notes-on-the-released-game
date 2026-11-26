# pc-v10 camera look input: vehicle chase cam + on-foot cam

Exe: `game-files/canonical/dumps/mercs2_unpacked.exe` (memory image). All disassembly in this folder
(`d_70a_726.txt` = 0x70A000-0x726000, `car_region.txt` = car camera class 0x715D00-0x717E00).
Grades: PROVEN = read this run in disassembly/bytes; INFERRED = reasoned, unchecked; NOT DETERMINED = gap.

## 1. Pipeline (PROVEN)

1. Control mappers post records through `0x4BDC60` into ring `0x011C2B68` (9 dwords:
   `{h0, h1, id, f32 value, 0...}`).
2. **Drain = `FUN_0070F330`** (called from `FUN_004C9740`, layer-4 tick; arg = dt). It pops records with
   `FUN_0070F780` and, for each of the 5 viewport slots (`slot = *(0x011761B0) + 0x20 + i*0x620` =
   0x14A3EE0 + i*0x620), takes the slot's active camera `cam = *(slot+0x1E0)`; if `h0 == 0 ||
   h0 == cam+0x20 || h0 == cam+0x1C` it calls `cam->vt[0x18](rec)` (message handler).
   **Joystick invert lives here**: for id `0x574220AC` (pitch), if byte `slot+0x610` != 0 the value is
   multiplied by -1.0 (`0x70F3EE..0x70F3FC`, constant `0xDFDB5C` = -1.0).
3. Then per slot `FUN_0070AD50(dt)`: `cam+0x504 = slot+0x614`, then `cam->vt[0x10](dt)` (= per-frame
   update, vtable slot 4).
4. Camera classes (vtables of 20 slots; vt+0x2C = mode id, vt+0x38 = name string), PROVEN:

| vtable | mode | name | update (vt+0x10) | msg (vt+0x18) |
|---|---|---|---|---|
| 0xBCE3C0 | 0xF | nullcam | — | 0x713E50 |
| 0xBCE410 | 2 | free eye | 0x717FE0 | 0x7189C0 |
| 0xBCE460 | 4 | binoculars | 0x715430 | 0x715BA0 |
| 0xBCE4B0 | 3 | pda | 0x71F6D0 | 0x71FEC0 |
| 0xBCE500 | 0xB | ragdoll | 0x720360 | 0x720600 |
| **0xBD2060** | **8** | **car** | **0x717A80** | **0x717B00** |
| 0xBD20B0 | 7 | helicopter | 0x719160 | 0x719C10 |
| **0xBD2100** | **6** | **human** | **0x71DC40** | **0x71E730** |
| 0xBD2158 | 0xD | script | 0x720C10 | 0x720990 |
| 0xBD21A8 | 0xA | tank | 0x722060 | 0x7228C0 |
| 0xBD2200 | 9 | turret | 0x723140 | 0x723620 |

Live capture `20261103_new-game-first-mission-start.dmp` (hero driving the Speed Boat): slot0 camera
`0x1FE03020` has vtable **0xBD2060 (car)** — boats use the car camera (PROVEN, `dump-read 0x1FE03020`).
The code map's "mode 3 = on-foot, 4 = vehicle" is wrong: 3 = pda, 4 = binoculars, 6 = human, 8 = car.

## 2. Input messages and their sources

On-foot mapper `FUN_00697790` (also reached by the vehicle mappers' tail call) posts with
`h0 = [this+8+0x14]`, `h1 = arg0 ([ebp+8])` (PROVEN, 0x697B4F-0x697B81):

| id | value (PROVEN) | car cam field | human cam field |
|---|---|---|---|
| 0x4BD465C7 yaw | `(byte14-byte13)/255` (FUN_005EDC40(rec,0xE,0xD)), full scale | +0x614 | +0x610 = -v |
| 0x574220AC pitch | `(byte15-byte16)/255` | +0x610 | +0x614 |
| 0x418C4926 | `(float)int[[rec+8]+0x40] * f[[rec+8]+0x54]` | +0x10 | +0x10 |
| 0x81DBD775 | `(float)int[[rec+8]+0x44] * f[[rec+8]+0x54]` | +0x14 | +0x14 |
| 0xA4DF446D | 1.0 when FUN_004B85E0(rec,4) | +0x618=1 (toggle chase/in-vehicle view) | — |
| 0xAA535A9F | 1.0 while FUN_004BDFB0(rec,0x16) | +0x6C8=1 (look-back held) | — |
| 0x5D4C76BF | 1.0 on FUN_004B8620(rec,0x16) | timer=+0x66C, +0x6C9=1 (recentre) | — |

INFERRED: 0x418C4926/0x81DBD775 are mouse dx/dy times the mouse sensitivity float (the Mouse device ctor
`0x4FD740` stores InvertY at +0x10 and Sensitivity*0.02 at +0x14; `[rec+8]+0x40/+0x44/+0x54` would be
that object's +0x0/+0x4/+0x14 if it sits at `[rec+8]+0x40`). Action indices 4/0x16 are the
FUN_004B85E0/4BDFB0/4B8620 index space; which ini action they are is NOT DETERMINED.

Car mapper `FUN_006988A0` posts `0.5*(byte14-byte13)` / `0.5*(byte15-byte16)` with `h0 = arg0`,
`h1 = 0` (`xor edi,edi` 0x69896E, stored at rec+4 0x698986) (PROVEN). The car camera's handler first
requires `rec[1] == cam+0x6BC` (0x717B00-0x717B0D) and `cam+0x6BC` is the ctor's arg0 = owner handle;
live `cam+0x6BC = 0x40004E98` = the hero (PROVEN). So the car cam **drops the car mapper's 0.5-scaled
records** (h1 = 0) and takes the on-foot mapper's full-scale ones if that mapper's arg0 is the hero
(INFERRED; arg0 identity not checked).

## 3. Ini options (PROVEN, `0x4FD740`, `0x753878`, `0x828A85`, save `0x4FBF26`/`0x4FD930`)

- `[Mouse] InvertY` (default 0) -> mouse+0x10 = (v != 0). Consumer NOT DETERMINED.
- `[Mouse] Sensitivity` (default **10**, clamp 1..20) -> mouse+0x14 = n*0.02 (0.02..0.40).
- `[Joystick] Invert` (default 0) -> byte 0xDFC34D -> `slot+0x610` (`FUN_006366C5` 0x6367C0) -> the
  drain negates the pitch record. Yaw is never inverted.
- `[Joystick] Sensitivity` (default 10, clamp 1..20) -> joy+0x40 = 0.5 + n*0.05 (0.55..1.5). Consumer
  NOT DETERMINED.
- Options byte `opts+0xC4` (0..100) * 0.01 -> `slot+0x614` (ctor default 0.5, `FUN_0070A7B0`) ->
  `cam+0x504` every frame. Only the human cam reads it (`FUN_0071BE30` 0x71BE46: scales its stick-rate
  blocks with +0x9F0 / +0x9F4 when aiming). Live boat value 0.0. INFERRED: the menu look-sensitivity slider.

## 4. CameraCarPreset -> car camera fields (PROVEN: ctor `FUN_00715D20`, called from `FUN_006A59D0` 0x6A65A5)

Preset element `p` (80 bytes); default = `FUN_0065E1D0`; live = boat preset in the capture.

| p+ | field | cam+ | use (PROVEN unless marked) | default | boat (live) |
|---|---|---|---|---|---|
| 0x00 | f0 | 0x670 | chase distance at rest | 7.5 | 14.0 |
| 0x04 | f1 | 0x674 | chase distance at max speed; <0 means = f0 | -1 | 13.5 |
| 0x08 | v2 | 0x684 | look-at offset: x,z rotated by vehicle heading, y uses abs(y) (FUN_00716C30) | (0,0,0) | (0,1.8,-0.3) |
| 0x14 | f3 | 0x668 = f3/12 | recentre hold time before blend (FUN_00717780) | 3.25 (0.27 s) | 6.0 (0.5 s) |
| 0x18 | f4 | 0x664 | rest pitch (rad; negative = look down), the reset target | -0.25 | -0.25 |
| 0x1C | f5 | 0x65C | yaw follow spring stiffness k (1/s) | 2.0 | 2.0 |
| 0x20 | f6 | 0x660 | yaw follow spring damping d (per frame) | 1.0 | 1.0 |
| 0x24 | v7 | 0x690 | eye offset for the in-vehicle view (sub-mode 1, FUN_00716360) | (0,0,0) | (0,2.0,-0.35) |
| 0x30 | f8 | 0x69C | in-vehicle view pitch (RotX) | 0.1 | 0.1 |
| 0x34 | v9 | 0x6A0 | in-vehicle look-back eye offset (used while look-back held) | (0,0,0) | (0,1.7,-1.5) |
| 0x40 | f10 | 0x6AC | in-vehicle look-back pitch (RotX, plus RotY(pi)) | 0.1 | 0.1 |
| 0x44 | f11 | 0x6B0 | FOV deg at rest (FUN_00717D10) | 55 | 55 |
| 0x48 | f12 | 0x6B4 | FOV deg at max speed | 65 | 65 |
| 0x4C | f13 | 0x6B8 | max speed, **km/h** (\|vel\|*3.6/f13), for FOV and distance | 150 | 100 |

Constants the ctor sets: +0x66C = 0.5 (blend time), +0x678 = 2.0 (stick yaw rate), +0x67C = 1.0 (stick
pitch rate), +0x680 = 0.25 (look-back hold threshold). +0x61C sub-mode: 0 = chase, 1 = in-vehicle.

## 5. Car chase update, per frame (`FUN_00716E30`, the order it runs in)

dt = frame time. "Per frame" = not dt-scaled.

1. **Recentre timer T = +0x64C** (`FUN_00717780`). Yaw stick x = +0x614, pitch stick y = +0x610,
   mouse mx = +0x10, my = +0x14.
   - x^2 > 0.1, or \|mx\| or \|my\| > 1e-5: T = 0.5 + f3/12.
   - otherwise x is zeroed, and if vehicle XZ speed > 2.0 m/s or T > 0.5: T = max(T - dt, 0).
     (Below 2 m/s the last 0.5 s never runs out: a stationary camera stays where you left it.)
   - The reset message: T counts down, all inputs are zeroed, +0x6CB = 1.
   - Look-back: holding 0xAA535A9F with x^2 < 0.01 adds dt to +0x6C4 (clamped to 0..1). On release,
     if +0x6C4 > 0.25, +0x6CA = 1, which next frame sets T = 0 (instant recentre).
2. **Stick smoothing** (`FUN_007176D0`, per frame): `sx = (1-a)*x + a*sx` with a = 0.75 if \|x\| < 0.1,
   else 0.825. `sy` is the same with 0.75 / 0.85. Stored in +0x640 / +0x644.
3. **Reverse flag +0x654** (`FUN_00716580`): signed forward speed s (vehicle vt+0x34). s > 2 gives
   +0x654 = 1 (forward). s < -2 for 0.25 s (s < -10) or 1.0 s gives +0x654 = 0 (reverse); steering
   input with square > 0.1 resets that timer.
4. **Look deltas** (`FUN_00717130` 0x7171F2-0x7172B0):
   - mouse: dyaw = -mx * 0.5 deg * (30*dt), dpitch = my * 0.25 deg * (30*dt).
   - stick: dyaw = -2.0*sx*dt, dpitch = 1.0*sy*dt (rad).
5. **Heading follow spring** (`FUN_00716A80` + `FUN_0070D360`). Target H = +0x638 = heading of the
   desired direction (`FUN_00716660`: vehicle forward blended with velocity when +0x654 = 1; velocity
   direction when reversing and \|v\| > 1). State Y = +0x634, V = +0x630, k = +0x628 =
   f5*(1 - 0.15*min(0.5*t,1)), with t = +0x650 a 0..2 s timer that counts up while
   `[vehicle+0x158]+0x40 > 0` (meaning NOT DETERMINED). Damping d = +0x62C = f6. Angles wrap.
   - `V = V - d*V + k*wrap(H - Y)`, then `Y += V*dt`.
   - With d = 1 this is a first-order lag: `Y += k*wrap(H-Y)*dt` (time constant 1/k = 0.5 s).
   - While T > 1e-4 (or look-back is active), Y = H and V = 0 every frame.
6. **Yaw output**: w = clamp(T/0.5, 0, 1), or 0 if +0x6CA. C = the camera's current yaw (from its quat
   +0x34). Then `yaw = wrap(Y) + w*wrap(C + dyaw - wrap(Y))`. w = 1 gives free look; w goes linearly to
   0 over 0.5 s, then the camera rides the spring.
   - INFERRED: the code's sign bookkeeping is `D = dyaw - C' - wrapY` with C' = -camYaw.
   - When look-back is held > 0.25 s, the yaw is the vehicle heading + pi and pitch = f4.
7. **Pitch** (camera field P = +0x620; final angle = the RotX argument):
   - Recentring (+0x6CB set: only after the reset message or a look-back release):
     P = w*P + (1-w)*f4.
   - Otherwise: P = clamp(P + dpitch, -1.2, 0.25).
   - Vehicle pitch filter: `+0x63C = 0.05*vehPitch + 0.95*(+0x63C)` per frame (`FUN_007179C0`).
   - Final: `RotX(clamp(-(+0x63C + P), +-(pi/2 - 1e-4)))`. Positive = look down (D3DX LH).
     Normal yaw recentre does **not** recentre pitch.
8. **Pose**: `M = RotX(pitch) * RotY(yaw)` (thunks 0x96BC88 / 0x96BC8E / 0x96BC94 = D3DXMatrixRotationX /
   RotationY / Multiply, by the FUN_00716360 decomp import names).
   - Target = vehicle position + heading-rotated v2 (`FUN_00716C30`). Height +0x658 rises at once and
     falls via `FUN_00714D90(f = 0.8)`.
   - Distance = lerp(f0, f1, clamp(\|v\|*3.6/f13)) + extra +0x648, which decays to 0 with f = 0.95
     (`FUN_00717040`).
   - Eye = target - forward*distance. FOV = lerp(f11, f12, same t) deg.
   - `FUN_00714D90(cur, target, f, dt)`: steps of 1/60 s, each `cur += (target-cur)*(1-f)`, with the
     fractional remainder interpolated.

## 6. On-foot (human cam, `FUN_0071DC40`)

- Yaw +0x618 (rad, wrapped to [-pi, pi)); pitch +0x61C **normalized 0..1** (clamped). Deltas come from
  `FUN_0071D790` (PROVEN):
  - mouse: dyaw = -mx * 0.75 deg * (30*dt) * (+0x760); dpitch = my * 0.75 deg * (30*dt) * (+0x760).
    +0x760 is 1.0 at ctor; INFERRED: an aim-friction scale.
  - stick: x = -yaw value, y = pitch value. Per axis (yaw, pitch) and per state (normal block
    +0x620/+0x658, aiming block +0x690/+0x6C8 when +0x7DD), the input is squared with its sign kept and
    fed to accel-ramp state blocks (`FUN_0071A910` / `FUN_0071A780`).
    - rate = blk[4]*blk[0]*(+0x760)*dt, plus blk[10]*(1-(1-\|x\|)^2)*ramp^3*dt when the signs agree.
    - ramp = clamp(+0x518/+0x514).
    - Block params are rebuilt each frame by `FUN_0071BE30`, scaled by cam+0x504 (the options slider) *
      +0x9F0 (or +0x9F4 when aiming).
    - Numeric block defaults NOT DETERMINED (element ctor 0x71ADA0 is not in the export; `FUN_0071BC10`
      not read).
- The pitch 0..1 to angle mapping (in `FUN_0071C670` / `FUN_0071D0A0`) is NOT DETERMINED.
  `HumanCameraModifier` -> human cam field mapping is NOT DETERMINED. The 0x38-byte (56-byte) blocks
  match its element size, but no loader was traced.
- Whether on-foot movement is camera-relative: NOT DETERMINED (not traced this run).

## 7. Divergences in our code (game-parity worktree)

1. `crates/mercs2_game/src/world.rs:2539`: the ride camera is `view_with_preset(.., tp_yaw, tp_pitch)`,
   a free orbit. There is no heading follow, recentre, timer, look-back or reverse logic. Exe: §5.
2. `crates/mercs2_engine/src/camera.rs:70-77` CAR preset field meanings are wrong vs §4:
   - `blend_time 0.1 = f8/f10`: wrong. f8/f10 are the in-vehicle view pitches; the blend is 0.5 (+0x66C).
   - `far 150 = f13`: wrong (also the comment at world.rs:2607). f13 is the max speed in km/h.
   - The boom `(0,2.2,6)` stands in for f0/f1 distance plus the v2 target offset.
   - `pitch_offset -0.1309`: exe rest pitch = f4 = -0.25 rad.
   - FOV is fixed 55; exe lerps 55 to 65 with speed.
3. `camera.rs:185-200`: the eye is set at a fixed boom from the focus. Exe: eye = target - forward*distance
   with the yaw/pitch of §5. The exe target height is smoothed (+0x658); ours is not.
4. `world.rs:2403`, `:2437`: pitch clamp [-1.2, 0.6] for every mode. Exe car: P in [-1.2, 0.25] plus
   the vehicle pitch filter, final +-(pi/2 - 1e-4). Exe on foot: normalized 0..1.
5. `crates/mercs2_engine/src/input.rs:433-437` `look_delta`:
   - 2.6 rad/s linear. Exe car: 2.0 rad/s (yaw) / 1.0 (pitch) on per-frame-smoothed input, with a
     x^2 > 0.1 deadzone for yaw.
   - Exe on foot: accel ramp.
   - There is no `[Joystick] Invert` (exe negates stick pitch, §1.2).
6. `input.rs:185`, `:462-464`: default sensitivity is 9; the exe default is 10. Rate is 0.0008*s/9 rad
   per pixel. Exe: dx * 0.02*s, then * (30*dt) * 0.75 deg on foot (0.5 deg yaw / 0.25 deg pitch in
   vehicles). The exe mouse is dt-scaled; ours (`world.rs:2393`) is not.
7. `crates/mercs2_vehicle/src/camera.rs:72-121`: placeholder presets. `chase_pose` (142-169) is rigidly
   attached to `vehicle_rot` (no lag); exe follows heading only, through the spring.
