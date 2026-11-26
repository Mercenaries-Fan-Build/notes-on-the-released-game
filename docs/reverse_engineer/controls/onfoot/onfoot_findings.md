# pc-v10 on-foot movement input (original game)

Exe: `game-files/canonical/dumps/mercs2_unpacked.exe` (memory image, offset = VA - 0x400000).
Capture: `game-files/memory-dumps/updated-chris-exports/20261103_new-game-first-mission-start.dmp` (hero 0x40004E98 in the boat).
Working files: this folder (`d_69c1.txt`, `d_69d4.txt` = FUN_0069C100 disassembly; `fn_*.txt` = decomp extracts; `dr_*.txt` = capture reads; `se_*.txt` = splice-emulate runs).
Grades: PROVEN = read in disassembly/bytes/capture this run; INFERRED = reasoned, unchecked; NOT DETERMINED = gap.

## 0. Correction to the brief

- PROVEN: the on-foot mapper is **FUN_0069C100** (vtable 0xBCE550 slot 3, ctor FUN_0069F650), not FUN_00697790.
  - Player control states are objects in a list at player+0x4. Their vtables are 0xBCE788 (on foot) and 0xBCE838 (vehicle).
  - On-foot state: enter FUN_006AA5B0 (vt+0x10) builds the human camera (0xAA0 bytes, FUN_0071AA60) at +0x10, a ragdoll camera (vtable 0xBCE500) at +0x14, and the 0x69C100 mapper at +0x18.
  - Vehicle state: enter FUN_006AABC0 (vt+0x10) calls the factory FUN_006AB040. That factory is its only caller (0x6AABE3). So base vtable 0xBCDCC8 (update FUN_00697790) is the vehicle fallback when the ridden entity has no Controller* component. It is not used on foot.
  - Transitions: FUN_006AA7C0 (on foot to vehicle, event kinds 2/3) and FUN_006AAD10 (back to on foot when the ridden entity is gone or changes).

## 1. Who writes the input record (priority 2)

Record = player+0x38. Pad = [rec+8] = player+0x40 (PROVEN, capture: player 0x1F768000, +0x20 = 0x40004E98, +0x40 = 0x014A3840).

Pads: 4 static pads of 0x80 bytes at 0x014A3840. Previous-frame copies are at 0x014A3A40.

Per frame, FUN_004FB270 (called from the RunFrame pump at 0x4C9752) does this for each pad (PROVEN):
1. Copy the pad to the previous-frame copy, then zero bytes 0..0x19.
2. Gamepad: FUN_00829130 fills bytes 1..25 from the device.
   - XInput branch: per-axis **dead zone**. Byte b = |thumb| >> 7. If b < dz the byte is 0, else (b - dz)/(255 - dz)*255, then times dev+0x33C, clamped to 255.
   - dz = dev+0x344 = **0x28 (40/255)**, set in the device ctors at 0x828646 and 0x8289D2.
   - The same rule covers every axis in both branches: FUN_00828080 for the XInput sticks other than LX, and FUN_00828C40/D80/EB0 for the dev+0x358 < 0 (ctor default) branch.
   - No writer of dev+0x33C was found in 0x4F0000..0x500000 or 0x820000..0x830000; its source is NOT DETERMINED. If it is a sensitivity, it scales the stick bytes and so shifts gait selection.
   - Triggers count only above 0x10. Buttons give 0 or 0xFF.
   - Stick codes 0..7 = LX-, LX+, LY-, LY+, RX-, RX+, RY-, RY+.
3. Keyboard and mouse: if 0x14A36FC is set, FUN_004FA570 runs. 0x14A36FC = 1 in the capture.
   - Mouse: pad+0x40/+0x44 = mouse dx/dy (dy **negated when [Mouse] InvertY = 0**), pad+0x54 = sensitivity (0.18 live = 9*0.02), pad+0x48..0x4F = buttons, pad+0x50 = wheel.
   - Actions: zeroes pad+0x58.. For each action k and each of the two bind slots ([Actions1]/[Actions2]), the code in 0x14A3700 + 8k (+4) is tested. Codes 1..0xFE are DIK keys via FUN_0082AB60. Codes 0x100..0x107 are mouse buttons. 0x108/0x109/0x10A = wheel up/down/any.
   - Then **pad+0x58+k = 0xFF while held**, and **pad[T[k]] |= pad+0x58+k**, with T = dword table 0xB9BCB0.
   - So a keyboard key writes the analog stick byte at full value 255 (digital). Gamepad and keyboard are OR-combined per byte.
4. pad[0] = 0xFF.
5. FUN_004FB090 builds the bit masks: bit i is set when byte i > 0x80. Then +0x28 = held, +0x20 = pressed (new this frame), +0x30 = released.

Button queries, PROVEN by splice-emulate with one pad mask set at a time (`se_btn.txt`):
- 0x4BDFB0 = held (pad+0x28).
- FUN_004B85E0 = pressed (pad+0x20).
- FUN_004B8620 = released (pad+0x30).
- All three also require the rec+0x10/+0x14 mask bit.

Table T (ini action k → pad index = Lua `Joystick` enum), PROVEN (0xB9BCB0). The order is proven by the live DIK codes in 0x14A3700 (W=0x11, S=0x1F, A=0x1E, D=0x20, MOUSE1=0x100, TAB+MWHEEL, R, MOUSE2+G, V, F+MOUSE3, E, SPACE=0x39, C, B, M, I, K, J, L, 1+UP, 2+DOWN, 4+RIGHT, LCTRL=0x1D, LSHIFT=0x2A):

| k | action | pad index | k | action | pad index |
|---|---|---|---|---|---|
| 0 | Forward | 11 (L_STICK_U) | 12 | Crouch | 17 (ALT1_1) |
| 1 | Backward | 12 (L_STICK_D) | 13 | Binoculars | 22 (ALT2_3) |
| 2 | MoveLeft | 9 (L_STICK_L) | 14 | PDA | 24 (SYS2) |
| 3 | MoveRight | 10 (L_STICK_R) | 15 | LookUp | 15 |
| 4 | PrimaryAttack | 20 | 16 | LookDown | 16 |
| 5 | PrimarySwitch | 21 | 17 | LookLeft | 13 |
| 6 | Reload | 7 | 18 | LookRight | 14 |
| 7 | SecondaryAttack | 18 | 19 | Up | 1 |
| 8 | SecondarySwitch | 3 | 20 | Down | 2 |
| 9 | MeleeAttack | 8 | 21 | Right | 4 |
| 10 | Use | 5 | 22 | **Walk** | **25** |
| 11 | Jump | 6 | 23 | **Sprint** | **19 (ALT1_3)** |
| | | | 24 | (Start) | 23 |

Actions 25..34 are menu actions, used when mouse+0x18 is set.

Ini parsing (PROVEN, FUN_004FB6B0 called from FUN_004FADC0):
- Keys: `sprintf("Actions%i", n)`, names from table 0xD1E440 (24 entries), `GetPrivateProfileStringA`. The value is matched with `_stricmp` against the key-name table 0xD1E640 (0x10B names), and the index is stored at obj+0xEA0+n*4+8k. Unknown names give 0.
- FUN_004FB890 removes duplicate bindings.
- FUN_004FBD40 reads the controller sections (section name at obj+0x294+i*0x390) against the name table 0xCF2560 ("Left Stick - Left", ...). It writes the per-pad index byte at obj+0x3D0.

Masks and enables (PROVEN):
- FUN_006A0710 (player tick) sets rec+0x10 = the state's vt+0x3C mask minus bits claimed by earlier states, and rec+0x14 = 0.
- On-foot mask = **0x027FFFFE** (bits 1..22 + 25 = Walk; no Start/PDA). Vehicle mask = 0x007FFFFE.
- FUN_006AA740 then clears bits 6,7,8,17,18,20,21,22 when player+0x463 (in-PMC, per player_code_map) is set. That disables Jump, Reload, Melee, Crouch, SecondaryAttack, PrimaryAttack, PrimarySwitch and Binoculars. It then calls mapper vt+0xC(handle = player+0x20, rec, dt, 0).

## 2. On-foot move computation (FUN_0069C100), PROVEN unless marked

- X = (pad9 - pad10)/255 = MoveLeft - MoveRight. Y = (pad11 - pad12)/255 = Forward - Backward (FUN_005EDC40 at 0x69C733/0x69C746).
- **Walk** (held(25), 0x69C758): **Y *= 0.4** (0xBA8724). X is not scaled.
- Basis: viewport slot = FUN_006A38C0() → 0x014A3EE0 (emulated).
  - The matrix at slot+0x10+[slot]*0x70 is the camera world matrix. Capture: rows right (0.777,0,-0.630), up, look (0.610,-0.247,0.753), pos (-1735.7,-31.1,2058.0).
  - FUN_008244D0/FUN_008231D0/FUN_00824960 give the look vector (row 2). Checked numerically with the exe formulas (`qcheck.txt`).
  - FUN_005211A0(out, up=(0,1,0), pos=0) with fwd = (look.x, 0, look.z): row0 = normalize(up x f) = (fz, 0, -fx), row2 = f.
- `move = D3DXVec3TransformNormal((X,0,Y), M) = X*(fz,0,-fx) + Y*(fx,0,fz)`. So movement is **camera-relative on the flattened view look vector**.
  - PROVEN: MoveLeft moves along **+camera row0** flattened (live row0 (0.777,0,-0.630) equals (fz,0,-fx)). Forward moves along camera row2 flattened.
  - INFERRED: row0 is screen-LEFT. Chain: mouse-right and right-stick-right both give dyaw < 0 (camera findings), the pose uses D3DXMatrixRotationY (forward = (sin y, 0, cos y)), so screen-right = -row0. That equals our `fwd x Y`.
- Only if [humrec+0x1C]+0x21 != 0 (humrec = 0xDF9990 record; +4 = posture hash: Upright 0x12C07B18, Crouched 0xC8886020, InVehicle 0x5E2CD838, Swim 0x614DB965; +8 = state hash: Idle 0xB4DA003B, Dead 0x5B50C577, Jump*/Fall). Every name was checked with `pandemic_hash.py --m2`.
- Overrides:
  - Scripted move-to: PhysicsActor+0x2F4 targets +0x2FC. If dist² < 0.25 the move is 0, else normalize(target - pos).
  - Move lock: mapper+0x26 with timer +0x28 (0.25 s after a crouch start).
- `m2 = |move|²`. If 0 or NaN the move is 0. **If 0 < m2 < 0.0625 the move becomes normalize(move)*0.25** (minimum magnitude 0.25; no further dead zone).
- Posts go through FUN_004BDEE0 into the ring at 0x01241260 (records 0x01241288, 0x18 bytes {handle, kind, vec3, dword}; per-subscriber byte 0x01247288).
  - Consumer chain: FUN_00406F20 pop → FUN_00404930 (RunFrame) → **FUN_00426D90** on the hero's PhysicsActor (container 0x17BF888).
  - Kind 1 = move → PA+0x140, **clamped to length 1**.
  - Kind 2 = facing → PA+0x14C, normalized. It is camera look when PA+0x170 == 5, else the move direction when |move|² > 0.01.
  - Kind 3 = RTHuman+0x3C low 2 bits (stance).
  - Kind 4 → PA+0x15C. Kind 5 → **PA+0x15D (sprint)**. Kind 6 → PA+0x235. Kind 8 → PA+0x24C = 0.
- Mouse and stick look records (0x418C4926/0x81DBD775 mouse, 0x4BD465C7/0x574220AC stick) go to the camera ring 0x011C2B68. **The mouse path has no mask test** (0x69C44B..0x69C4D5).
- InVehicle posture: if |X| > 0.5 or |Y| > 0.5, FUN_004239F0(kind 0x10), then return (meaning NOT DETERMINED).

## 3. Sprint, walk, gait, jump, crouch

Sprint (0x69D350, PROVEN):
- Condition: pressed(19) or held(19), humrec+8 == Idle, and none of 0x14/0x12/0x11 pressed or held (PrimaryAttack, SecondaryAttack, Crouch).
- Effect: posts kind 5 and kind 3 (stance 0) every frame.
- FUN_0042B9C0 clears PA+0x15D unless all three hold:
  - |move| > 0.5 (|move|² > 0.25) or |PA+0x1D4| > 1e-4;
  - ([PA+0x1C8] - PA+0x1C4)/3000 > 1;
  - stance bits == 0.
- So sprint is hold-to-sprint. The 3000-tick timer source and units are NOT DETERMINED.

Gait (FUN_00427B80(|move|, PA+0x15D), PROVEN):
- 0 if |m| <= t0. 1 if PA+0x19D. **4 (sprint)** if the sprint flag is set and s2 < s3. 1 if |m| < t1. 3 if |m| >= t2. Otherwise 2.
- FUN_0042BB50 sets the thresholds: t0 = s0/2, t1 = (s0+s1)/2, t2 = (s1+s2)/2, t3 = (s2+s3)/2, with s_i = data speed / max (PA+0x258).
- Live hero (PROVEN values): PA+0x258 = 10.0, s = 0.15/0.45/0.55/1.0, t = 0.075/0.30/0.50/0.775. That is 1.5/4.5/5.5/10 **if PA+0x258 is in m/s** (INFERRED).
- Second set (PA+0x170 == 4 or 5): PA+0x25C = 5.0, s = 0.2/0.4/0.6/1.0, t = 0.1/0.3/0.5/0.8. Live PA+0x170 = 0 (+0x174 = 4). The meaning of 4/5 is NOT DETERMINED.
- Two more branches in FUN_00427B80 (PROVEN; meanings NOT DETERMINED):
  - [PA+0x2DC]+0x18 == 1 and PA+0x170 not 4/5: the gait is only 0 or 1, and the out-flag is set when |m| >= t2.
  - RTHuman+0x3C & 0x400: the gait is 0/1/2 only.
- INFERRED: gait i drives the body toward s_i*max. NOT DETERMINED: the data record (param of FUN_0042BB50, set by FUN_004255C0) and the gait-to-velocity code (FUN_0042A2F0 not read).
- Keyboard result: W gives |m| = 1, gait 3. Ctrl+W gives 0.4, gait 2. Strafing with Ctrl is not slowed.

Jump (0x69D458, PROVEN):
- pressed(6), gated by _HumanPhysics+0x7C - 0.25 > PA+0x17C and a >1.0 s timer when FUN_004244E0 is true.
- Event "**JumpMoving**" (0x4BB71A5F) if |move|² > 0.5625 (|move| > 0.75), else "**JumpStationary**" (0x5CBC3867), via FUN_00423D10.

Crouch is **hold-to-crouch** (0x69DF4F/0x69E092, PROVEN):
- Upright, not firing, Crouch(17) pressed or held: event "**Crouch**" (0xE861BC73), camera msg 0xF30A4095, kind 3 (2) if player+0x464, and a move lock of 0.25 s.
- Crouched and Crouch neither pressed nor held: event "**Stand**" (0xAB3B572B). The same happens while held if mapper+9 is set and Fire is held.
- This is the hold behaviour as far as FUN_0069C100 shows.
  - FUN_0069EEA0 (end call, takes mapper+8) is not a crouch toggle; it is an effect spawn (0xB210730E).
  - FUN_0069E7A0 (0x69DE23) handles SecondaryAttack (bit 18) during the Jump*/Fall states.
  - The relocated FUN_0069E6B0 (0x69D6A8) is not read.

## 4. Player.SetInputEnabled (priority 3), PROVEN

FUN_005DC270 writes player+0x244 = arg2 and player+0x245 = arg3, or arg2 when arg3 is absent (0x5DC364/0x5DC36A). The ctor default is 1/1 (0x6A0020).

Readers:
- **+0x244**, FUN_006A0710 0x6A0713: when 0, the claimed mask starts at all ones, so every state's mapper gets rec+0x10 = rec+0x14 = 0.
  - All stick and button reads return 0: move, stick look, jump, crouch, sprint.
  - **Mouse look still posts** (no mask test).
- **+0x244**, FUN_006A0770 0x6A089E: same for the states' vt+8 pass.
- **+0x244**, FUN_0069BE60 0x69BE80 (on-foot vt+8 via 0x6AA7A0, the use/enter target query): returns 0.
- **+0x245**, FUN_006A0770 0x6A07FC: only when byte 0xCFB963 != 0 (= config hash 0xD07F8898 value == 0, 0x4C3B45; name NOT DETERMINED). It sets rec mask = 1<<24 and, on pressed(24 = PDA), posts the "TogglePDA" event.
  - When 0xCFB963 == 0, the on-foot mapper toggles the PDA itself on pressed(pad index 3 = SecondarySwitch: V / DPAD Left) (0x69C3B8).

## 5. Divergences in our code (game-parity worktree)

1. `crates/mercs2_engine/src/input.rs:418-429` `move_vec`:
   - No Walk (exe: Y*0.4 while held(25)).
   - No 0.25 minimum magnitude.
   - Keyboard and stick are added; the exe ORs per byte, which is max.
2. `input.rs:367-377`: the stick dead zone is |v| < 0.15 with no rescale. Exe: per axis 40/255 then rescaled to full range (`retail_inputs` at :298 already has the exe rule).
3. `crates/mercs2_player/src/locomotion.rs:40-41,179-182`: binary walk 2.2 / run 6.5 m/s on Sprint. Exe:
   - magnitude gaits with sprint as a separate gait; 1.5/4.5/5.5/10 m/s if PA+0x258 is in m/s (live data);
   - sprint only if |move| > 0.5, Upright, state Idle, and not firing/secondary/crouching;
   - plain W runs (gait 3), not walks.
4. `crates/mercs2_game/src/world.rs:2565`: jump on held. Exe: pressed edge, JumpMoving when |m| > 0.75 else JumpStationary, gated.
5. world.rs on-foot block: no crouch. Exe: hold-to-crouch with a 0.25 s move lock; Crouch blocks sprint.
6. `world.rs:2436-2442`: stick look stays live with input disabled. Exe: +0x244 = 0 masks stick look and leaves mouse look live. The PDA gate (+0x245) is not modelled.
7. `world.rs:2542-2544` basis (tp_yaw flattened, right = screen_right). Exe: MoveRight goes along -row0 = (-fz,0,fx) of the rendered camera matrix. Ours: `camera.rs:165` screen_right = f x Y = (-fz,0,fx), so the sign matches. That tp_yaw equals the rendered camera's yaw is INFERRED.
