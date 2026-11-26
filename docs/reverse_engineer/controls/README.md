---
status: current
evidence: proven
---

# Mercenaries 2 (pc-v10) controls: input device → hero, vehicle, camera

Read of 2026-11-25; each claim carries its grade. The camera and on-foot reads are in full in
`camera/camera_findings.md` and `onfoot/onfoot_findings.md`; the `d_*.txt` and other work files named
below were not kept (`objdump -d` of the image at the cited addresses gives them again). Exe: `game-files/canonical/dumps/mercs2_unpacked.exe` (memory image; file
offset = VA − 0x400000 for every section; constants read that way: `0xB9B664`=1.0, `0xBBB99C`=0.5,
`0xDFDB5C`=−1.0, `0xBEAA2C`=−0.0, `0xBAC8BC`=1/255, `0xB92B58`=0.1, `0xBEAC50`=√2, `0xBEA9A8`=8192,
`0xD69AC0`=2π, `0xCF2900` = 8192-entry sine table (`[1]`=sin(2π/8192))). Capture used:
`game-files/memory-dumps/updated-chris-exports/20261103_new-game-first-mission-start.dmp` (hero
`0x40004E98` driving the Speed Boat).

Grades: **PROVEN** = read in disassembly / bytes / capture this run; **INFERRED** = reasoned, not
checked; **SPECULATIVE** = guess, labelled. Supporting work files (all in this folder):
`d_697.txt` (0x696F00–0x69B000 disassembly: all vehicle mappers), `d_437300.txt` (car handler),
`d_436030.txt`, `f1.txt`…`f6.txt` (Ghidra extracts), `camera/camera_findings.md` (camera, sub-agent),
`onfoot/onfoot_findings.md` (on-foot + input record + SetInputEnabled, sub-agent). Sections 2 and 3
summarise the two sub-agent files; their address-level evidence is in those files.

---

## 0. The input record every mapper reads (PROVEN unless marked)

Source: `onfoot/onfoot_findings.md` §1, plus `FUN_005EDC40` read here (`d_5edc.txt`).

- Per player: record `rec` = player+0x38; pad = `[rec+8]` = player+0x40 (live `0x014A3840`, one of 4
  static 0x80-byte pads). Filled every frame by `FUN_004FB270` (RunFrame pump, call 0x4C9752):
  1. zero pad bytes 0..0x19;
  2. gamepad `FUN_00829130`: stick bytes with a **per-axis dead zone 40/255 (dev+0x344 = 0x28),
     rescaled** `(b−40)/(255−40)·255`, × dev+0x33C (source NOT DETERMINED), clamp 255; buttons 0/0xFF;
     triggers count above 0x10;
  3. keyboard/mouse `FUN_004FA570`: `pad[0x58+k] = 0xFF` while ini action k is held, and
     **`pad[T[k]] |= pad[0x58+k]`** (T = dword table `0xB9BCB0`) — a key writes the analog byte at full
     255, OR-combined with the pad (so pad and keyboard combine as max per byte);
     mouse: `pad+0x40/+0x44` = int dx/dy (**dy negated when `[Mouse] InvertY`=0**), `pad+0x54` =
     `[Mouse] Sensitivity`×0.02 (live 0.18 = 9×0.02, `dump-read … 0x14A3840 128`);
  4. `FUN_004FB090`: bit i set when byte i > 0x80 → held `+0x28`, pressed `+0x20`, released `+0x30`.
- `FUN_005EDC40(rec,pos,neg)` = `(pad[pos] − pad[neg]) / 255` (neg = 0x1A → `pad[pos]/255`); 0 unless
  bit pos (and neg) is in the 64-bit mask rec+0x10/+0x14 (0x5EDC40–0x5EDCE6; splice at 0x5EDC61
  emulated: returns 1.0 for pad9=255, pad10=0). **No dead zone or curve here.**
- Button queries (sub-agent, splice-emulated): `0x4BDFB0` = held, `FUN_004B85E0` = pressed,
  `FUN_004B8620` = released; all need the rec mask bit.
- Pad index = Lua `Joystick` enum. Table T (ini action → pad index), PROVEN at `0xB9BCB0` (read twice
  by different methods: sub-agent via live DIK codes; here directly, `tableT.txt` = [11, 12, 9, 10, 20,
  21, 7, 18, 3, 8, 5, 6, 17, 22, 24, 15, 16, 13, 14, 1, 2, 4, 25, 19, 23]):

| action (k) | pad | action (k) | pad | action (k) | pad |
|---|---|---|---|---|---|
| Forward (0) | 11 L_STICK_U | Reload (6) | 7 | Binoculars (13) | 22 |
| Backward (1) | 12 L_STICK_D | SecondaryAttack (7) | 18 | PDA (14) | 24 |
| MoveLeft (2) | 9 L_STICK_L | SecondarySwitch (8) | 3 | LookUp/Down (15/16) | 15/16 |
| MoveRight (3) | 10 L_STICK_R | MeleeAttack (9) | 8 | LookLeft/Right (17/18) | 13/14 |
| PrimaryAttack (4) | 20 | Use (10) | 5 | Up/Down/Right (19–21) | 1/2/4 |
| PrimarySwitch (5) | 21 | Jump (11) | 6 | Walk (22) | 25 |
| | | Crouch (12) | 17 | Sprint (23) | 19 |

- Sign conventions that follow (PROVEN by the formulas): left-stick X used by the mappers is
  `pad9 − pad10` = **positive LEFT**; left-stick Y is read two ways: `axis(0xC,0xB)` = pad12−pad11 =
  **positive BACK** (car/tank mappers) and `axis(0xB,0xC)` = **positive FORWARD** (on-foot mapper).
- Masks: on foot 0x027FFFFE, vehicle 0x007FFFFE; in-PMC (player+0x463) clears Jump, Reload, Melee,
  Crouch, both attacks, PrimarySwitch, Binoculars (`FUN_006AA740`).

### Who maps input for the ridden thing (PROVEN, `d_6ab0.txt`, vtables `vt.txt`)

Vehicle state enter `FUN_006AABC0` → factory `FUN_006AB040` (its only caller, 0x6AABE3) picks by the
ridden entity's component (`FUN_005857E0` with the container):

| component (container) | mapper vtable | slot 2 | per-frame update (slot 3) |
|---|---|---|---|
| ControllerCar `0x17BCF98` | 0xBCDCE8 | `0x698850` (posts ClearControls 0x6C5F1491 to the car ring, then `0x697710`) | **`FUN_006988A0`** |
| ControllerTank `0x17BD038` | 0xBCDC88 | `0x698850` | **`FUN_00699B40`** |
| ControllerHelicopter `0x17BD0D8` | 0xBCDC68 | `0x6994E0` | **`FUN_00699530`** |
| ControllerLW `0x17BD088` | 0xBCDCA8 (ctor 0x6992B0) | `0x697710` | `FUN_006992D0` |
| ControllerBoat `0x17BCFE8` | 0xBCDD08 | `0x698FB0` | **`FUN_00699000`** |
| ControllerLadder `0x17BD128` | 0xBCDD28 (ctor 0x699E70) | `0x69A360` | `FUN_0069A430` |
| none | 0xBCDCC8 (base ctor 0x6971E0) | `0x697710` | `FUN_00697790` |

Every vehicle update tail-calls `FUN_00697790` (common: PDA, look-camera records, camera-mode
messages). The on-foot state uses a different mapper, `FUN_0069C100` (§3). Update args:
`(handle = player+0x20 (the hero), rec, dt, 0)` (sub-agent: `FUN_006AA740`).

---

## 1. Player → vehicle commands

Rings: car/tank `FUN_00538C90` (ring `0x011C0230`), boat `FUN_00538D20` (`0x011C2478`), helicopter
**`0x00538C00`** (SecuROM-relocated thunk; a third ring, consumers include `FUN_004396C0`). Record
`{target = mapper+0x14 (vehicle handle), id, f32 payload, extra}`.

### 1.1 Car — `FUN_006988A0` (PROVEN, `d_697.txt` lines 2312–2799)

Below, `F[k]` = 1.0 if `pad[0x58+k]` (keyboard action k held) else 0; `ax(p,n)` = `FUN_005EDC40`.

| order | id | payload |
|---|---|---|
| 1 | `0x7D3B632C` (throttle) | `max( F[Jump] ? 0 : ax(6,—), F[Forward] )`; then if mapper+0x30 byte set, capped at 0.1 (0x698A7D) |
| 2 | `0x0490757F` (reverse) | `max( F[Reload] ? 0 : ax(7,—), F[Backward] )` |
| 3 | `0x37086E0A` (handbrake) | 1.0 if held(17) (pad 17 = Crouch's pad slot) or `F[Jump]`, else 0 |
| 4 | `0x3483DBF1` (Turn) | `clamp(G_x, −1, 1) + (F[MoveLeft] − F[MoveRight])` — the digital term is added **after** the clamp, no re-clamp |
| 5 | `0x574220AC` (car +0x38) | `clamp(G_y, −1, 1) + F[Forward] − F[Backward] + F[Jump] − F[Crouch]` |
| 6 | `0x35924710` → camera ring | `throttle − reverse` (record h1 = hero) |

Also (before 1): `0x4BD465C7` = 0.5·ax(14,13) and `0x574220AC` = 0.5·ax(15,16) into the camera ring
with h1 = 0 — the car camera drops them (camera §2.1).

- Stick gate (`G`), PROVEN math: `x = ax(9,10)` (left +), `y = ax(12,11)` (back +), `m = √(x²+y²)`,
  `θ = atan2(y, x)` (`__libm_sse2_atan2`, xmm0 = y, xmm1 = x — INFERRED from the CRT convention; it is
  the only order under which the X output uses cos θ and the Y output sin θ of the same θ),
  `G_x = (1−m)·x + √2·m·cos θ` (sin-table index `(8192/2π·θ + 0.5) − 0x800`, i.e. sin(θ−π/2)·(−1)),
  `G_y = (1−m)·y + √2·m·sin θ`. Algebraically `G_x = x·(1 + √2 − m)`: a circle-to-square gate that
  saturates early (x=0.5,y=0 → 0.96; x=0.25 → 0.54).
- What the keyboard produces (INFERRED from §0 OR rule + the formulas): A → pad9=255 → G_x = 1 → Turn
  = 1 + 1 = **2** (handler clamps). W → F[Forward]=1 → throttle 1; pad11=255 makes y = −1, so
  `0x574220AC` = −1 + 1 = 0 (W/S cancel out of that channel; Space/C drive it). Space → pad6=255, but
  F[Jump] suppresses the analog throttle, so **Space = handbrake** (+1 on 0x574220AC). R → pad7 but
  F[Reload] suppresses it. C → pad17 → held(17) → **C is also handbrake** (−1 on 0x574220AC).
- What a gamepad produces (INFERRED, via the retail `[Controller (XBOX 360 For Windows)]` binds):
  throttle = the Jump button (Button 1 = A, digital 0/255), reverse = the Reload button (Button 3 = X),
  handbrake = the Crouch bind (Other Left Stick − Left = left trigger), steer = left stick X. **The left
  stick Y does not drive throttle in a car.** The game's own help table agrees: DLC
  `dlc01_pausescreen.lua` `dlc_car` lists Forward = BUTTON_PAD2_D (6), Reverse = BUTTON_PAD2_L (7),
  TurnLR = BUTTON_L_STICK_L, Handbrake = BUTTON_ALT1_1 (17), Look = right stick (corpus
  `docs/mercs2-dlc-luacd/raw/dlc01/dlc01_pausescreen.lua`).
- mapper+0x30 cap: set at construction from byte `0x017C6654` (0x6AB080); the only reference to that
  byte is that read; live value 0 (`dump-read … 0x17c6654 4`). What writes it: NOT DETERMINED.

### 1.2 Car handler `FUN_00437300` (drive object = actor+0x158; PROVEN `d_437300.txt`)

- **Turn `0x3483DBF1`: `+0x28 = clamp(−0.0 − payload, −1, 1) = −payload`** (0x4374F2: `movss xmm0,
  [0xBEAA2C]` (−0.0); `subss xmm0,[rec+8]`; clamp to [−1.0 `0xDFDB5C`, 1.0]). **It is not
  `1.0 − payload`.** So the drive object holds positive = RIGHT while the record holds positive = LEFT.
  Then, if `actor->vt[0x30]()` is true, `+0x28 = FUN_00436030(+0x28)`:
  `|v| < 0.6 → 0.5·v`; else `sign(v)·(0.3 + 0.7·(|v| − 0.6)·2.5)` (constants 0.36 `0xBEAD7C`, 0.6
  `0xD2D840`, 2.5 `0xBEAD78`, 0.7 `0xDFDDD8`, 0.3 `0xB9B688`; continuous: 0.6→0.3, 1→1). What
  `vt[0x30]` tests: NOT DETERMINED.
- `0x7D3B632C` → `+0x30` if `+0x98 == 0`, else `+0x2C`. `0x0490757F` → `+0x2C` if `+0x98 == 0`, else
  `+0x30`. `0x55B8E0A1` (Lua CarBrake) → `+0x30`. `0x37086E0A` → **`+0x34`** (handbrake). `0x574220AC`
  → `+0x38 = clamp(payload, −1, 1)`. `0x460C5913` (Lua combined axis): `v ≥ −0.01` → (+0x98==0 ?
  {+0x2C=0, +0x30=1.0} : {+0x2C=v, +0x30=0}); `v < −0.01` → (+0x98≠0 ? {+0x2C=0, +0x30=1.0} :
  {+0x2C=−v, +0x30=0}). `0x6C5F1491` zeroes +0x28..+0x38. Any payload with v² > 1e-4 zeroes +0x26C.
  Meaning of +0x2C/+0x30 (accel/brake) and +0x98 (reverse flag) is the vehicle code map's claim —
  INFERRED, not re-read here.

### 1.3 Boat — `FUN_00699000` (PROVEN, `d_697.txt` 2830–3040); handler `FUN_00435790` stores raw

| id | payload | boat actor (via owner+0x140) |
|---|---|---|
| `0x7D3B632C` | `max(F[Jump] ? 0 : ax(6,—), F[Forward])` (no 0.1 cap) | +0xF8 throttle |
| `0x0490757F` | `max(ax(7,—), F[Backward])` (no Reload suppression) | +0xFC brake/reverse |
| `0x3483DBF1` | **`ax(9,10)` raw** — no gate, no digital term, no curve | +0x100 turn (positive = left) |
| `0x37086E0A` | held(17) ? 1 : 0 (no Jump term) | +0x104 handbrake |

Keyboard A/D reach the boat only through the OR rule (pad9/pad10 = 255 → ±1). Boats ride the car
camera (camera §1).

### 1.4 Tank — `FUN_00699B40` (PROVEN arithmetic, `d_697.txt` 3675–3884), car ring

- `G = clamp((1−m)·y + √2·m·sin θ)` with `y = ax(12,11)` (back +), `x = ax(9,10)`.
- `T` (buttons): `−(F[Jump] ? 0 : ax(6,—)) + (F[Reload] ? 0 : ax(7,—))` (no pad pointer: `ax(7,6)`).
- `0x7D3B632C` = `T` if `T² > G²` else `G` — a **signed** drive axis, **negative = forward**.
- `0x3483DBF1` = signed square of x: `x<0 ? −x² : x²` (positive = left).
- `0x35924710` (camera ring, h1 = hero) = `T`.
- If mapper+0x30 ≠ 1: `FUN_00696FC0` clears bit 20 of three input words (meaning NOT DETERMINED).
- Which handler consumes the tank's records (sub-agent note: `FUN_00441900` per our `command.rs`
  comment): NOT DETERMINED this run.

### 1.5 Helicopter — `FUN_00699530` (PROVEN, `d_697.txt` 3254–3593); handler `FUN_004396C0` stores raw

Runs only when the vehicle's PhysicsActor `vt[0xE0]() == 4`.

| id | payload (PROVEN) | heli actor |
|---|---|---|
| `0xE6FA6B1B` | `clamp(ax(6,7) + (−255 if F[Crouch]) + ax(18,17), −1, 1)` — Jump-button up / Reload-button down, pad18 up / pad17 down; the Crouch flag is an un-normalised −255 (saturates) | +0x28 |
| `0x330850A1` | `−G_y` of the left stick via `FUN_00697000` (gated) = **positive forward** | +0x30 |
| `0x11C78A3C` | `−G_x` = **positive right** | +0x34 |
| `0x30FBBF64` | `clamp(mouse_dx·sens·0.25, −1, 1) − G_rx` (right stick gated, `ax(13,14)`; mouse via `pad+0x40`×`pad+0x54`×0.25 `0xBBC7EC`) = positive right | +0x2C |
| `0xB422F25E` | pressed(3) (SecondarySwitch pad) as 0/1 | — |

When a `PhysicsActorWinch` (`0x17BF8D8`) is attached with state ≠ 0/3 and +0x170 == 1, the forward /
right values are replaced by a camera-relative heading term (0x6996FA–0x699843; not decoded).
Meaning of the four words (collective / cyclic / yaw) is INFERRED from the signs only.

---

## 2. Camera (summary of `camera/camera_findings.md`, PROVEN unless marked)

### 2.1 Pipeline
- Look records go through thunk `0x4BDC60` to ring `0x011C2B68` (9 dwords `{h0,h1,id,f32,…}`),
  drained by `FUN_0070F330` (layer-4 tick, arg dt) per viewport slot (`*(0x011761B0)+0x20+i·0x620`;
  active camera `*(slot+0x1E0)`), delivered to `cam->vt[0x18]` when h0 ∈ {0, cam+0x20, cam+0x1C}.
- **`[Joystick] Invert`** is applied here, pitch only: slot+0x610 set → the `0x574220AC` value × −1
  (0x70F3EE). Yaw is never inverted.
- Camera classes: car 0xBD2060 (mode 8, update `FUN_00717A80`, msg `0x717B00`), human 0xBD2100 (mode
  6, `FUN_0071DC40` / `FUN_0071E730`), helicopter 0xBD20B0 (7), tank 0xBD21A8 (0xA), turret 0xBD2200
  (9). **Boats use the car camera** (capture: slot0 camera `0x1FE03020` has vtable 0xBD2060).
- Note: `camera_findings.md` §2 calls `FUN_00697790` the "on-foot mapper"; that label is superseded —
  it is the vehicle common mapper (§0 table). On foot the same ids come from `FUN_0069C100`:
  `0x4BD465C7` = ax(14,13) at 0x69C53C–0x69C564 and `0x574220AC` = ax(15,16) at 0x69C532 (PROVEN push
  order, `d_69c52.txt`).
- Signs (PROVEN with table T): yaw value ax(14,13) = LookRight − LookLeft = **positive RIGHT**; pitch
  value ax(15,16) = LookUp − LookDown = **positive UP**; the cameras turn these into dyaw < 0 for right.
- Look sources while riding: the common mapper `FUN_00697790` posts `0x4BD465C7` = ax(14,13)
  and `0x574220AC` = ax(15,16) at full scale with h1 = hero, plus mouse
  `0x418C4926`/`0x81DBD775` = int dx/dy × pad+0x54. The car camera accepts only h1 == cam+0x6BC (live
  = hero), so the car mapper's own 0.5-scaled copies (h1 = 0, `xor edi,edi` 0x69896E) are dropped.
  Also `0xA4DF446D` (chase ↔ in-vehicle view toggle, pressed(4)), `0xAA535A9F` (look-back while
  held(0x16)), `0x5D4C76BF` (recentre on release(0x16)).

### 2.2 `CameraCarPreset` (80 bytes; ctor `FUN_00715D20` from `FUN_006A59D0`)

| field | meaning | default | live boat |
|---|---|---|---|
| f0 | chase distance at rest | 7.5 | 14.0 |
| f1 | distance at top speed (<0 → f0) | −1 | 13.5 |
| v2 | look-at offset (x,z rotated by heading) | 0 | (0, 1.8, −0.3) |
| f3 | recentre hold, seconds = f3/12 | 3.25 | 6.0 |
| f4 | rest pitch (rad, negative = look down) | −0.25 | −0.25 |
| f5 | yaw follow spring stiffness k | 2.0 | 2.0 |
| f6 | yaw follow damping d (per frame) | 1.0 | 1.0 |
| v7 / f8 | in-vehicle view eye offset / pitch | 0 / 0.1 | (0,2,−0.35) / 0.1 |
| v9 / f10 | in-vehicle look-back eye / pitch | 0 / 0.1 | (0,1.7,−1.5) / 0.1 |
| f11 / f12 | FOV deg at rest / top speed | 55 / 65 | 55 / 65 |
| f13 | top speed, km/h (t = |v|·3.6/f13) | 150 | 100 |

### 2.3 Chase update per frame (`FUN_00716E30`)
1. Recentre timer T: set to `0.5 + f3/12` while yaw stick x² > 0.1 or any mouse motion; otherwise
   x is zeroed and T counts down by dt, but only while XZ speed > 2 m/s or T > 0.5 (parked: the
   camera stays where it was left).
2. Stick smoothing, **per frame, not dt-scaled**: `s = (1−a)·x + a·s`, a = 0.75 (|x|<0.1) else
   0.825 for yaw, 0.75 / 0.85 for pitch.
3. Look deltas: stick `dyaw = −2.0·s_x·dt`, `dpitch = 1.0·s_y·dt`; mouse `dyaw = −mx·0.5°·30dt`,
   `dpitch = my·0.25°·30dt`.
4. Heading spring `FUN_0070D360`: `V = V − d·V + k·wrap(H − Y)`, `Y += V·dt` (d = 1 → first-order lag,
   τ = 1/k = 0.5 s); H = vehicle forward (blended with velocity), or velocity direction after
   reversing for 0.25–1 s; while T > 0 Y snaps to H.
5. Yaw out `= Y + w·wrap(C + dyaw − Y)`, `w = clamp(T/0.5)` — free look fades into the spring over
   0.5 s (sign bookkeeping INFERRED). Look-back held > 0.25 s → heading + π.
6. Pitch `P = clamp(P + dpitch, −1.2, 0.25)`, final `RotX(−(filt + P))`, `filt += 0.05·(vehPitch −
   filt)` per frame, clamp ±(π/2 − 1e−4). Normal recentring does not touch pitch.
7. Pose `RotX·RotY`; eye = target − forward·lerp(f0,f1,t); FOV = lerp(f11,f12,t); target height
   rises at once, eases down (`FUN_00714D90`, f = 0.8 per 1/60 s).

### 2.4 On-foot camera (human cam `FUN_0071DC40`) — partial
- Yaw (rad, wrapped), pitch normalised 0..1. Mouse: `dyaw = −mx·0.75°·30dt·cam+0x760`, `dpitch =
  my·0.75°·30dt·cam+0x760` (+0x760 = 1.0 at ctor). Stick: sign-kept square fed to acceleration-ramp
  blocks (normal / aiming); default constants NOT DETERMINED; scaled by `cam+0x504` (options byte /100,
  INFERRED look-sensitivity slider).
- Ini (PROVEN): `[Mouse] Sensitivity` default 10, clamp 1–20, ×0.02 (retail ini ships 9);
  `[Mouse] InvertY` → negates dy in the pad writer (§0); `[Joystick] Sensitivity` → 0.5 + 0.05·n
  (consumer NOT DETERMINED); `[Joystick] Invert` → pitch negation (§2.1).

---

## 3. On-foot movement (summary of `onfoot/onfoot_findings.md`, PROVEN unless marked)

- Mapper `FUN_0069C100` (vtable 0xBCE550, built by on-foot state enter `FUN_006AA5B0`).
- `X = ax(9,10)` = MoveLeft − MoveRight, `Y = ax(11,12)` = Forward − Backward; **Walk (pad 25, LCTRL)
  held → Y × 0.4** (`0xBA8724`), X not scaled.
- **Camera-relative**: basis from the rendered camera matrix (slot `0x014A3EE0`): f = look row
  flattened & normalised; `move = X·(fz,0,−fx) + Y·f` (D3DXVec3TransformNormal). MoveLeft goes along
  +row0 (live row0 = (fz,0,−fx)).
- `0 < |move|² < 0.0625` → `normalize(move)·0.25` (minimum magnitude 0.25). Zeroed during scripted
  move-to and a 0.25 s lock after crouch start.
- Posted to ring `0x01241260` via `FUN_004BDEE0`, consumed by `FUN_00426D90` on the hero PhysicsActor:
  kind 1 move (clamped to length 1), kind 2 facing, kind 3 stance, kind 5 sprint flag.
- Gait `FUN_00427B80(|m|)`: 0 if ≤ t0; 4 = sprint when the flag is set; 1 if < t1; 3 if ≥ t2; else 2.
  Thresholds = midpoints of data speeds; live hero max 10.0, s = 0.15/0.45/0.55/1.0 → t =
  0.075/0.30/0.50/0.775 (1.5/4.5/5.5/10 m/s if the unit is m/s — INFERRED). **Plain W = gait 3 (run);
  Ctrl+W = 0.4 → gait 2.**
- Sprint (LSHIFT → pad 19): hold; needs state Idle, no PrimaryAttack/SecondaryAttack/Crouch, |move| >
  0.5, standing stance, a >3000-tick timer (source NOT DETERMINED).
- Jump (pad 6): on the **pressed edge**, gated; "JumpMoving" if |move| > 0.75 else "JumpStationary".
- Crouch (pad 17): hold-to-crouch ("Crouch" / "Stand" events), 0.25 s move lock; blocks sprint.
- Ini parsing: `FUN_004FB6B0` reads `[Actions%i]`, names table `0xD1E440`, key names `0xD1E640`
  (`_stricmp`); `FUN_004FBD40` reads controller sections against `0xCF2560`.

## 4. `Player.SetInputEnabled` (PROVEN, sub-agent)

`FUN_005DC270`: player+0x244 = arg1, player+0x245 = arg2 (or arg1 when absent); ctor default 1/1.
- **+0x244 = 0** → `FUN_006A0710` gives every state mapper mask 0: all stick/button reads return 0
  (move, stick look, jump, crouch, sprint, vehicle commands). **Mouse look still flows** (the mouse
  read has no mask test, 0x69C44B–0x69C4D5; the vehicle common mapper posts mouse the same way —
  INFERRED). The use/enter query `FUN_0069BE60` returns 0.
- **+0x245** gates the TogglePDA press (pad 24) only when byte `0xCFB963` ≠ 0 (config hash
  0xD07F8898, name NOT DETERMINED).

---

## 5. Where the native game differs (game-parity worktree, read-only)

Paths relative to `tools/wad_simulator/.claude/worktrees/game-parity/crates/`.

0. **Player car steering is probably mirrored (INFERRED, check first).** `mercs2_game/src/world.rs:2524`
   writes `turn = −mx`, i.e. positive = LEFT (`input.rs:418` `move_vec` x is +right). Our car drive
   (`mercs2_vehicle/src/drive.rs:372` → `lateral_friction` :194-196) turns the steered wheels' side
   axis to `X·cos a + Z·sin a`, so for a > 0 the wheel rolls along `(−sin a, 0, cos a)`, toward −X =
   model RIGHT (model +X is the left: `hp_seat_fl`). So pressing A would steer right. The exe agrees
   that the *drive object* is positive-right (+0x28 = −payload, §1.2) but its player record is
   positive-left. Our tests (`mercs2_vehicle/src/lib.rs:186-300`) only check that opposite signs turn
   opposite ways, not which way. One rule fixes both this and #6: keep `VehicleControls.turn` in the
   drive-object convention (positive right), have `handle_command_car` store `clamp(−payload)` (+ the
   `FUN_00436030` curve), have the world produce the record value (positive left) and post/convert
   it, and keep `Steer::of_turn` fed the record value (`world.rs:2682` reads `c.turn` today, so it
   would then need the negated value). Not run; verify with a drive test before relying on it.
1. **Car throttle comes from the wrong input.** `mercs2_game/src/world.rs:2522-2523` sets
   `accel = my.max(0)`, `brake = (−my).max(0)` from `move_vec()` (left stick Y / W-S). Exe car and boat
   (§1.1, §1.3): throttle = Jump-bound button (pad 6) or W; reverse = Reload-bound button (pad 7) or S;
   left stick Y never drives the car. Tank: one signed axis, stick Y or buttons, whichever is larger.
2. **Car steering has no response shaping.** `world.rs:2524` `turn = −mx` (linear, our dead zone).
   Exe: 40/255 per-axis dead zone with rescale (§0) → circle-to-square gate `x(1+√2−m)` → ±1 digital
   term → handler negation → `FUN_00436030` curve (half slope under 0.6; applied only when the car
   actor's `vt[0x30]()` is true, condition NOT DETERMINED). Boat: raw stick, no gate.
   Tank: signed square.
3. **Ride camera is a free orbit.** `world.rs:2539` `view_with_preset(.., tp_yaw, tp_pitch)`: no
   heading spring (k=2, τ=0.5 s), no recentre timer (f3/12 + 0.5 s blend), no parked-hold, no reverse
   heading, no look-back, pitch clamp [−1.2, 0.6] instead of [−1.2, 0.25] + vehicle-pitch filter, fixed
   FOV 55 instead of 55→65 with speed (camera §5–§7; `mercs2_engine/src/camera.rs:70-77` field meanings
   wrong: "blend 0.1 = f8/f10" (f8/f10 are in-vehicle pitches; blend is 0.5), "far 150 = f13" (f13 is
   top speed km/h), rest pitch −0.1309 vs exe f4 = −0.25; `mercs2_vehicle/src/camera.rs:142-169`
   `chase_pose` rigidly locked to vehicle rotation).
4. **Look input rates/shaping.** `mercs2_engine/src/input.rs:433-437` `look_delta`: linear 2.6 rad/s,
   no smoothing, no `[Joystick] Invert`. Exe car: per-frame smoothed stick, 2.0 rad/s yaw / 1.0 pitch,
   yaw dead zone x²>0.1; exe on foot: accel ramp. Mouse: ours `world.rs:2393` is not dt-scaled and
   uses 0.0008·s/9 rad/px (`input.rs:462-464`); exe `dx·0.02·s·0.75°·30dt` on foot (0.5° yaw / 0.25°
   pitch in vehicles). Our default sensitivity 9 matches the retail ini (the exe's 10 applies only when
   the key is absent; live pad+0x54 = 0.18 = 9·0.02), so it is not a divergence.
5. **On-foot gait.** `mercs2_player/src/locomotion.rs:40-41,179-182`: binary walk 2.2 / run 6.5 m/s on
   Shift. Exe: magnitude gaits (plain W runs, gait 3), Walk key ×0.4 on Y, sprint as its own gait with
   conditions, minimum magnitude 0.25.
6. **Car handler Turn.** `mercs2_vehicle/src/command.rs:181` `ctrl.turn = (1.0 − payload).clamp(−1,1)`
   — wrong; exe `+0x28 = clamp(−payload)` (0x4374F2) then the `FUN_00436030` curve. The handler also
   routes `ACCEL_A`/`ACCELERATE` both to `accel` (exe: +0x2C/+0x30 swapped by +0x98), `HANDBRAKE`
   (0x574220AC) to handbrake (exe: that id is the +0x38 stick-Y channel; the handbrake is 0x37086E0A →
   +0x34, our `AUX5`), and decodes `0x460C5913` with a 0.5 split (exe: −0.01 threshold, §1.2).
7. **Sign of `VehicleControls.turn` (check needed).** `world.rs:2524` writes the record convention
   (positive left) straight into `turn`, which `mercs2_vehicle/src/drive.rs:372` turns into a steer
   angle. Exe's drive object holds the opposite sign (+0x28 = −payload). Whether our drive math expects
   positive-left: NOT DETERMINED (drive.rs lateral_friction not read); `Steer::of_turn(c.turn)`
   (`world.rs:2682`) needs the record convention, as now.
8. **Handbrake input.** `world.rs:2510` handbrake = Jump held. Exe car: held(pad 17 = Crouch/LT) or
   Jump key; boat: pad 17 only.
9. **Keyboard + stick combine.** `input.rs:418-429` `move_vec` adds keyboard and stick and uses
   |v|<0.15 without rescale (`input.rs:367-377`); exe ORs per byte (max) after a 40/255 rescaled dead
   zone (`retail_inputs` at `input.rs:298` already holds the exe rule).
10. **Jump/crouch.** `world.rs:2565` jump on held; exe on pressed edge with Moving/Stationary split.
    No crouch on foot; exe hold-to-crouch.
11. **SetInputEnabled.** `world.rs:2436-2442` stick look stays live when input is disabled; exe masks
    stick look but keeps mouse look; +0x245 PDA gate not modelled.

---

## 6. NOT DETERMINED (and what was tried)

- `actor->vt[0x30]` condition for the car steering curve `FUN_00436030` (not followed).
- Meaning of car drive fields +0x2C / +0x30 / +0x38 / +0x98 beyond the code map's claim; the car
  physics consumer of +0x38 was not read.
- Writer of byte `0x017C6654` (car throttle cap 0.1): image-wide dword search finds only the read at
  0x6AB082; live 0. A register-relative or relocated writer is possible.
- Tank record consumer (`FUN_00441900`?) and sign convention of its drive axis; `FUN_00696FC0` effect.
- Helicopter winch-branch math (0x6996FA–0x699843) and what the four heli words drive.
- Source of gamepad scale dev+0x33C; `[Joystick] Sensitivity` consumer.
- Human camera stick-ramp constants, pitch 0..1 → angle mapping, `HumanCameraModifier` field map.
- Gait → velocity (`FUN_0042A2F0` not read), the speed record behind the gait table, sprint timer.
- ID hash names (`0x3483DBF1`, `0x7D3B632C`, …) — not cracked; none asserted here.
