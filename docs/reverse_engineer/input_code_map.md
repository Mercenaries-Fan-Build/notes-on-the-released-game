# Input — Xbox↔PC code map

**Scope:** scoreboard **row 18 (Input)** — the device-read path (keyboard / mouse / gamepad), the
Win32 message pump, the per-frame action-state poll, the action→device-state resolver, and the
`Mercs2.ini` action-binding surface (`[Actions1]`/`[Actions2]`/`[Mouse]`/`[Controller (XBOX 360 For
Windows)]`) that our engine already parses. This marries the **Xbox 360 devkit (Jul-08 Profile
build)** platform surface to the **PC retail decompilation** (`Mercenaries2.exe`, unpacked image, base
`0x00400000`).

**This row is asymmetric by construction — like the diagnostics map (row 32).** The scoreboard says
the **Xbox side is XDK module-level only (no per-function list recoverable)**, and that is exactly what
the evidence shows: Xbox input is the XDK **XInput-over-XAM** service reached through `xam.xex`
(`imports-exports.md` §1b: `xam.xex`, 220 import records) with **no decompiled input-read body** under
an input name. So this document is honestly **PC-anchored**: the PC DirectInput8 device path is
recovered first-hand and cited; the Xbox side is stated at module level and married by role. Where the
PC body can't be pinned to a name (the keyboard-`[Actions1]` ini reader), the row says so.

**Sources.** Xbox oracle: [`docs/mercs2-pdb-analysis/imports-exports.md`](../mercs2-pdb-analysis/imports-exports.md)
(XDK static libs incl. D3D9I/XINPUT era + the `xam.xex` dynamic import that carries `XamInput*`) +
[`camera.md`](../mercs2-pdb-analysis/camera.md) / [`gui-hud.md`](../mercs2-pdb-analysis/gui-hud.md)
(input consumers — no DirectInput/XInput per-fn strings survive on either side). PC: the 27k-fn Ghidra
decomp of the unpacked exe (function bodies read first-hand and cited as `ghidra/FUN_xxxx`), the
scheduler/streaming maps [`scheduler_tick_code_map.md`](scheduler_tick_code_map.md) /
[`world_streaming_code_map.md`](world_streaming_code_map.md) (the `RunFrame`→`FUN_004c9740` per-system
pump the input tick hangs off), the config-loader anchor in
[`shadow_code_map.md`](shadow_code_map.md) §6 (`Mercs2.ini` loader family) and
[`docs/data/scaleform_gfx_function_map.json`](../data/scaleform_gfx_function_map.json) (the
ExternalInterface KB/M-remap screen drivers). Config ground truth:
[`docs/game_config/Mercs2.ini`](../game_config/Mercs2.ini). Our-engine reconciliation: memory
[[input-system-mercs2ini-gilrs]] (the built data-driven 25-action set), [[shadow-pc-absolute-mouse-input]]
(the raw-input oddity + look/aim pattern), and `docs/modernization/engine_support_inventory.md` row 18.

**Method / honesty model.** Same discipline as the sibling maps. The PC DirectInput path is
**code-fact** (device create/poll/acquire read with quoted bodies, DirectInput8 vtable offsets and the
`DIERR_INPUTLOST` retry are unmistakable). Xbox is **module-fact** (XDK/`xam.xex`, no body). Confidence:
**H** can't-coincide fingerprint (read body / DI vtable+error-code idiom / string-anchored) · **M** one
strong structural signal / role-married · **L/open** positional / name-stripped → confirm-live. SecuROM
is **not** a blocker ([[securom-decompiled-not-a-blocker]]) — the input bodies read live in the unpacked
image.

---

## 0. Result in one line

**PC input is DirectInput8, fully in the clear; there is no XInput and no WM_INPUT/raw-input path.** The
device is created once (`DirectInput8Create → CreateDevice → SetDataFormat → SetCooperativeLevel
(FGND|NONEXCL) → SetProperty(BUFFERSIZE) → Acquire`, `FUN_0082ba90`), polled every frame in buffered +
immediate mode with a `DIERR_INPUTLOST` re-acquire loop (`FUN_0082aae0`/`FUN_0082aa60`/`FUN_0082ba00`),
and the per-frame input tick (`FUN_004fc0c0`, called from the `RunFrame` layer-4 pump `FUN_004c9740`)
walks the action-binding table, resolving each bound input-code to a live "is-down" bit via the big
resolver `FUN_0082ab60` and running a pressed/held/released state machine. The Win32 message pump
`FUN_006315f0` handles **only** window/quit messages (input never arrives through `WndProc`). The
`Mercs2.ini` **controller** binding names (`"Left Stick - Left"`, `"Button N"`, `"DPAD Up"`) are matched
to internal indices in the Scaleform options/remap dispatcher `FUN_005c37e0` (string table
`PTR_s_Left_Stick___Left_00cf2560`); the **keyboard-`[Actions1]`** name→code reader is in the
`Mercs2.ini` loader family but is **name-stripped/unlocated** → confirm-live. **Xbox = XDK XInput via
`xam.xex`, module-level only** — no per-fn marriage, and that asymmetry is the honest finding. Our
engine's **row 18 is ✅** — the data-driven 25-action set (`mercs2_engine::input`, KB/mouse + gilrs) is
already built; the remaining seam is the streaming loop's **hardcoded free-fly keys**.

---

## 0.5 Master marriage table (the whole row at a glance)

"Xbox" is the platform-surface fact (module-level; a bare service name means no decompiled body). A PC
`FUN_` is read first-hand unless noted.

| Role | Xbox (module-level) | PC addr | Married by | Conf |
|---|---|---|---|---|
| **Win32 message pump** (window/quit only) | (XDK `XGetVideoMode`/dispatch; N/A on console) | **`FUN_006315f0`** | `PeekMessageA`→`TranslateMessage`/`DispatchMessageA`, break on WM_QUIT `0x12` → `DAT_01175fff`/`DAT_01176020` | H |
| **Input subsystem alloc + init** | XDK input init (`xam.xex`) | **`FUN_004fc1e0`** | allocs `0x498`-B input-state obj → `*(app+0x810)`; zeroes KB buffer `+0xa2` & event ring `+0xe2`; calls device-create | H |
| **DirectInput device create/configure** | `XamInputGetState` era — **no DI on console** | **`FUN_0082ba90`** | `DirectInput8Create` (guard `DAT_01176345`) → `IDirectInput8* DAT_011763e0`; `CreateDevice`(vt+0xc); `SetDataFormat`(vt+0x2c,`DAT_00b91af4`); `SetCooperativeLevel`(vt+0x34, arg `6`=FGND\|NONEXCL, HWND `DAT_011763e4`); `SetProperty`(vt+0x18, DIPROP_BUFFERSIZE=16) | H |
| **Device poll (buffered + immediate)** | `XamInputGetState` | **`FUN_0082aae0`** | `GetDeviceData`(vt+0x28, obj sz `0x14`) → on fail re-acquire → `GetDeviceState`(vt+0x24, `0x100`, `+0xa2`) → `FUN_0082ba00` drain | H |
| **Acquire / re-acquire helper** | (implicit in XamInput) | **`FUN_0082aa60`** | `GetKeyboardState` (toggle keys `+0x494/495/496`) + `Acquire`(vt+0x1c) retried ×3 while result `== 0x8007001E` (**DIERR_INPUTLOST**) | H |
| **Buffered-event ring builder** | (XInput packet delta) | **`FUN_0082ba00`** | walks `DIDEVICEOBJECTDATA` (stride `0x14`), `&0x80`→down, into 0x40-slot ring (`+0xe2` head/`+0xe3`/`+0xe4`) | H |
| **Per-frame input tick** (action state machine) | XDK per-frame input read | **`FUN_004fc0c0`** (from `FUN_004c9740` RunFrame pump) | walks action table `DAT_00b9bd40`(enable) ∥ `DAT_00d6c278`(state, stride 8); per entry `FUN_0082ab60`→pressed→edge/hold bits `1/2/4`; hold-time `[PTR_PTR_01175d34+0x20]*DAT_00dfddc8` | H |
| **Input-code → is-down resolver** | (per-device state array) | **`FUN_0082ab60`** | 1428-B switch over the internal code space → indexes decoded state array (`in_EAX+0x289…+0x35a`); KB `0x09–0x100`, mouse `0x180–0x600`, combos `0xe00/0xe80`, **gamepad `0xf00–0xf1a`** | H |
| **Controller binding-name → index** (remap UI) | XDK button enum | **`FUN_005c37e0`** (ExternalInterface options dispatcher) | string-matches `PTR_s_Left_Stick___Left_00cf2560` (53 names = the `[Controller]` ini vocabulary) → joystick index switch | H (name table) / M (role) |
| **`Mercs2.ini` config loader family** | (per-title config) | `FUN_00753280` (`[Render]` loader, shadow map §6) + siblings | string-anchored cvar loader; the **`[Actions1/2]`/`[Mouse]` reader is the name-stripped sibling** | M / open |
| **KB/M remap screen drivers** (Scaleform) | (console remap UI) | `FUN_005c1900`/`FUN_005c1ed0`/`FUN_005c2970`/`FUN_005c2cb0` | `Invoke("LTIInputKMSetActionName"/"LTIInputKMKeyMap",…)` on the options movie (`scaleform_gfx_function_map.json`) | M |
| **Gamepad backend** | **XInput via `xam.xex`** (`XamInputGetState`/`GetCapabilities`, rumble `SetState`) | **DirectInput8 joystick** (sibling device of `FUN_0082ba90`; `[Controller]` "Button N" = DI enumeration) | absence of any XInput import in the PC decomp + DI button-index remap | M |
| Rumble / joystick tunables | XInput vibration + `[Joystick]` | `[Joystick] Rumble/Invert/Sensitivity` (ini) → tick | ini ground truth; native apply confirm-live | M |

---

## 1. Where input sits in the frame (tick integration)

Confirmed first-hand against the scheduler/streaming maps: the per-frame input read is a member of the
**layer-4 per-system call list** `FUN_004c9740` (the same dual-role pump that drives streaming, world
map §1), *not* the window message pump.

```
FUN_00631670  WinMain
  ├─ FUN_006315f0  Win32 message pump  (PeekMessageA/Translate/Dispatch; WM_QUIT 0x12 → quit)  §2.0
  └─(each loop)→ FUN_00630ef0  RunFrame
        5. FUN_004c14f0  MASTER UPDATE
             └─ FUN_004c15e0  5-layer app stack 0→4
                  layer 4 → … → FUN_004c9740  per-system pump
                       ├─ FUN_004fc0c0   INPUT TICK  (poll device + update action states)  §3
                       ├─ FUN_00872d30   Stream_Manager_Update            (world map §2)
                       └─ FUN_00502510   PgSysPopulation::Update          (population map)
```

**The message pump does no gameplay input.** `FUN_006315f0` only pumps window messages and latches
`WM_QUIT`; DirectInput reads the device directly in `FUN_004fc0c0`. There is **no `WM_INPUT`
registration and no `WndProc` key handling** anywhere in the path — consistent with our own tooling
finding that OS-level raw input / `GetAsyncKeyState` / LL-hooks are dead on this title and the *game's
own* `IDirectInputDevice8::GetDeviceState` is the only live source ([[shadow-pc-absolute-mouse-input]]
context; the freecam RE landed on hooking exactly this call).

---

## 2. The PC DirectInput8 device path (H — read first-hand)

### 2.1 Create + configure — `FUN_0082ba90`

```c
if (DAT_01176345 == '\0') {                 // one-time DI object create
    GetModuleHandleA(NULL);
    if (DirectInput8Create() >= 0) DAT_01176345 = 1;   // -> IDirectInput8* DAT_011763e0
}
iVar2 = (**(IDI8+0xc))();                    // IDirectInput8::CreateDevice   -> device *(this+4)
if (ok) iVar2 = (**(dev+0x2c))(&DAT_00b91af4);          // SetDataFormat  (DIDATAFORMAT DAT_00b91af4)
if (ok) iVar2 = (**(dev+0x34))(dev, DAT_011763e4);      // SetCooperativeLevel (arg 6 = FGND|NONEXCL, HWND)
if (ok) { uStack_38=0x14; piStack_34=0x10; puStack_30=0; // DIPROPHEADER
          iVar2 = (**(dev+0x18))(dev, 1, &uStack_38); }  // SetProperty(DIPROP_BUFFERSIZE=16)
if (ok) FUN_0082aa60();                                  // Acquire
```

DirectInput8 vtable offsets are unambiguous: `0x0c` CreateDevice, `0x18` SetProperty, `0x1c` Acquire,
`0x24` GetDeviceState, `0x28` GetDeviceData, `0x2c` SetDataFormat, `0x34` SetCooperativeLevel. The
`SetCooperativeLevel` arg `6` = `DISCL_FOREGROUND|DISCL_NONEXCLUSIVE` (windowed, cooperative — matches
the retail non-exclusive grab). Buffer size 16 = the buffered-input queue. **This is the keyboard
device**; the mouse device is a byte-for-byte sibling create (its exact site is not separately pinned →
confirm-live), and the state object carries both (KB 256-buffer `+0xa2`, mouse-button bytes decoded by
`FUN_0082ab60` at `+0x2c6…+0x2e0`).

### 2.2 Poll — `FUN_0082aae0` + acquire `FUN_0082aa60` + drain `FUN_0082ba00`

```c
// FUN_0082aae0 (per poll):
*this = 0x20;
n = (**(dev+0x28))(dev, 0x14, this+2);        // GetDeviceData (buffered, DIDEVICEOBJECTDATA=0x14)
while (n != 0) {                              // n!=0 => lost/error
    if (FUN_0082aa60() != 0) break;          //   re-acquire; give up after retries
    n = (**(dev+0x28))(dev, 0x14, this+2);
}
memset(this+0xa2, 0, 0x100);
(**(dev+0x24))(dev, 0x100, this+0xa2);        // GetDeviceState (immediate 256-byte KB state)
FUN_0082ba00(this);                            // fold buffered events into the ring
```

`FUN_0082aa60` is the re-acquire helper: it snapshots a few toggles via `GetKeyboardState`
(`+0x494/0x495/0x496`) then calls `Acquire` (vt+0x1c) up to 3× while the HRESULT is
**`0x8007001E` = `DIERR_INPUTLOST`** — the textbook DirectInput re-acquire idiom, which is what fixes the
marriage at **H**. `FUN_0082ba00` walks the returned `DIDEVICEOBJECTDATA` records (stride `0x14`, key
down = `&0x80`) into a 0x40-slot event ring (`+0xe2` head / `+0xe3` / `+0xe4`).

---

## 3. Action state machine + input-code resolver (H)

### 3.1 Per-frame tick — `FUN_004fc0c0`

Called from `FUN_004c9740` (the RunFrame layer-4 pump, §1). It walks the parallel arrays
`DAT_00b9bd40` (per-action enable) ∥ `DAT_00d6c278` (per-action 8-byte state), and for each enabled
entry evaluates the bound input via `FUN_0082ab60` and advances a **pressed/held/released** state
machine (state bits `1/2/4` in the record's flag byte; the record's `+4` dword accumulates a hold time
scaled from the frame dt `[PTR_PTR_01175d34+0x20] * DAT_00dfddc8`). After the walk it polls the device
(`FUN_0082aae0`) and drains the buffered ring `DAT_00d6ca78+0x388/0x38c/0x390/0x394`. This is the engine
analog of our `Input::held(action)` / edge tracking.

### 3.2 Input-code → is-down — `FUN_0082ab60` (the binding decode)

The 1428-byte resolver takes an **internal input-code** (the value a bound `[Actions*]`/`[Controller]`
entry maps to) and returns the current down-state by indexing the decoded state array in the input
object (`in_EAX + 0x289 … + 0x35a`). The code space is the whole device set:

- **Keyboard** `0x09,0x0a,0x20–0x100` (letters carry two cases, e.g. `0x57/0x77 → +0x299` = the `W`
  bit; `0x20 → +0x2c1` = space; `0x2c/0x3c → +699` etc.) — the `[Actions1/2]` keys.
- **Mouse** `0x180` (`+0x2c5`), `0x200/0x280/0x300/0x380/0x400` (buttons → `+0x2c6…+0x2ca`),
  `0x480/0x500/0x580/0x600` (wheel/extra → `+0x2cb/0x2cc/0x2df/0x2e0`) — `MOUSE1/2/3`, `MWHEEL`.
- **Combos** `0xe00` = `+0x324 || +0x2a4` (a chorded bind).
- **Gamepad** `0xf00–0xf1a` (→ `+0x2b2 … +0x33d`) — the 27 controller inputs (sticks/dpad/buttons)
  that the `[Controller (XBOX 360 For Windows)]` section binds.

So the chain is **`Mercs2.ini` binding → internal input-code → `FUN_0082ab60` → decoded device bit →
`FUN_004fc0c0` state machine → gameplay**. This is the exact same shape as our engine's `Action` →
binding-set → `held()`.

---

## 4. The `Mercs2.ini` binding surface (marries to our engine's parser)

`Mercs2.ini` (retail, verbatim in `docs/game_config/`) carries the binding sections our engine already
consumes:

- **`[Actions1]` / `[Actions2]`** — primary + alternate KB/mouse binds for the full action set
  (`Forward=W`, `PrimaryAttack=MOUSE1`, `PrimarySwitch=TAB`, `SecondaryAttack=MOUSE2`, `Jump=SPACE`,
  `Sprint=LSHIFT`, `Walk=LCTRL`, `PDA=M`, `Binoculars=B`, look `I/K/J/L`, select `1/2/4`, alt
  `PrimarySwitch=MWHEEL`/`MeleeAttack=MOUSE3`/arrows). These key-name strings (`MOUSE1`, `MWHEEL`,
  `SPACE`, `LSHIFT`, `TAB`, `NULL`) are parsed into the internal codes `FUN_0082ab60` consumes.
- **`[Mouse]`** — `Sensitivity` + `InvertY` (look scaling).
- **`[Controller (XBOX 360 For Windows)]`** + `[Wireless Controller]` — gamepad binds using the
  DirectInput enumeration (`Button 1..12`, `Left/Right Stick - Dir`, `DPAD Dir`, `Other Left Stick -
  L/R` = triggers).

**Where the controller vocabulary is decoded on PC.** `FUN_005c37e0` (the large Scaleform
ExternalInterface options/shell dispatcher) contains the controller-remap branch: it copies the bound
string and compares it against the 53-entry name table **`PTR_s_Left_Stick___Left_00cf2560`** (`"Left
Stick - Left"`, `"DPAD Up"`, `"Button N"`, …), mapping each display name to an internal joystick index
via a `switch` (name-index → button/axis number). This is the runtime side of the same `[Controller]`
vocabulary our engine's `input.rs` parses, and it confirms **PC gamepad = DirectInput joystick, not
XInput** (the button indices are the DI enumeration; there is no `XInput*` import in the PC decomp). The
KB/M remap **screen** is driven by the sibling ExternalInterface functions
`FUN_005c1900/…/FUN_005c2cb0` invoking `LTIInputKMSetActionName`/`LTIInputKMKeyMap` on the options movie
(`scaleform_gfx_function_map.json`; UI catalog in `docs/ui/main_menu_structure.md` §"Input Options LTI
Functions").

**Honest gap — the keyboard `[Actions1]` file reader.** The authoritative `Mercs2.ini` loader family is
string-anchored for `[Render]` (`FUN_00753280`, shadow map §6, → `DAT_00dfc34x/36x` cvars); the sibling
that reads `[Actions1/2]`/`[Mouse]` into the binding table is in the same family but its section strings
are **not distinctly recovered** → **unlocated by name / confirm-live** (§6). What it *produces* — the
`DAT_00b9bd40`/`DAT_00d6c278` action table `FUN_004fc0c0` walks — is fully in the clear.

---

## 5. Mouse look, sensitivity, and the Shadow-PC oddity

Mouse buttons/wheel resolve through `FUN_0082ab60` (§3.2). Relative-axis **look** comes from the mouse
DI device's `X/Y` deltas (immediate/buffered), scaled by `[Mouse] Sensitivity` and negated per
`[Mouse] InvertY`, then fed to the camera/aim consumers (`camera.md` per-frame update). The exact PC
delta-accumulate site is a mouse-device sibling of §2 and is **confirm-live** (name-stripped like the
rest of the runtime).

This is the subsystem behind the **Shadow-PC absolute-mouse oddity** ([[shadow-pc-absolute-mouse-input]]):
on a streamed desktop the OS delivers **absolute** coordinates, so raw-delta look degenerates. Our
engine's fix — prefer raw deltas, **auto-latch** to a `CursorMoved`+recentre fallback (Confined, never
Locked) when the stream proves absolute — is the modern replacement for this native DI mouse-look path,
not a port of it.

---

## 6. Confirm-live inventory (x32dbg, read-only while PAUSED — [[x32dbg-mcp-no-resume]])

1. **Mouse DI device create** — break `DirectInput8Create` / `IDirectInput8::CreateDevice` (vt+0xc) and
   capture the second device's `DIDATAFORMAT` (expect `c_dfDIMouse2`) + its `GetDeviceState` buffer to
   pin the mouse-look delta site (sibling of `FUN_0082ba90`).
2. **Keyboard `[Actions1]` reader** — HW-read bp on the action table `DAT_00b9bd40`/`DAT_00d6c278` at
   load time to catch the `Mercs2.ini` loader (sibling of `FUN_00753280`) that fills it; recover the
   key-name→code map (`MOUSE1`,`MWHEEL`,`SPACE`,`LSHIFT`→codes).
3. **Gamepad DI joystick** — confirm the `[Controller]` "Button N" path binds an `IDirectInputDevice8`
   joystick (`c_dfDIJoystick2`), not XInput: break the remap match in `FUN_005c37e0` against
   `PTR_s_Left_Stick___Left_00cf2560` with a pad connected, and check for any `xinput*.dll` module (none
   expected).
4. **`FUN_0082ab60` code map** — break it during gameplay and log `param_1` for each action to fully
   resolve the internal-code ↔ `[Actions*]`/`[Controller]` entry mapping (esp. the `0xe00/0xe80` combos
   and the `0xf00–0xf1a` gamepad block).
5. **Re-acquire path** — force focus loss and confirm `FUN_0082aae0`/`FUN_0082aa60` walk the
   `DIERR_INPUTLOST 0x8007001E` retry and re-`Acquire` (validates the H marriage live).
6. **Rumble apply** — trace `[Joystick] Rumble` from ini to the native force-feedback/vibration commit
   to pin the output half (the DI `IDirectInputDevice8::CreateEffect` or XInput `SetState` site).

---

## 7. Reconciliation with `mercs2_engine` (scoreboard row 18 = ✅)

**Status: ✅ — the data-driven input layer is already built and is a faithful, portable analog of the
retail path.** (`engine_support_inventory.md` row 18; [[input-system-mercs2ini-gilrs]].)

- **What the engine has:** `mercs2_engine::input` — a generic action/binding layer configured by the
  **retail `Mercs2.ini` format**, covering the full **25-action set** (Forward…Start), KB + mouse
  (winit) and **gamepad via `gilrs`** (pure Rust; Linux/SteamOS evdev, Windows XInput+DInput, Steam
  Deck). It parses `[Actions1]`+`[Actions2]` (primary+alternate), `[Mouse]` (Sensitivity/InvertY), and
  `[Controller (XBOX 360 For Windows)]` (`Button N` = the same DI enumeration `FUN_005c37e0` decodes),
  and exposes `held(action)` / `kb_held(action)` / analog `move_vec()` / `look_delta(dt)`. This is a
  clean superset of the native chain **binding → code → is-down → state machine** (§3).
- **Faithful-impl notes this map hands the engine:** the retail device model is **DirectInput8,
  non-exclusive foreground, buffered+immediate, with a `DIERR_INPUTLOST` re-acquire loop** (§2) and
  **no WndProc/WM_INPUT input** (§1). Mouse look is DI relative-axis scaled by `[Mouse]`
  Sensitivity/InvertY (§5). The engine's winit+gilrs backend already satisfies these behaviours on
  modern OSes and additionally solves the Shadow-PC absolute-input case the native DI path never handled
  (§5).
- **The remaining seam (the one honest gap in row 18):** the **world-streaming loop's hardcoded free-fly
  keys** (WASD/`I J K L`/arrows in `world.rs`) still bypass the action layer. Route the streaming/free
  camera through the same `Action` set (`Forward`/`LookLeft`/… + `move_vec`/`look_delta`) so *all*
  look/aim/movement flows through one data-driven binding surface, matching the native single-table
  design (`FUN_004fc0c0` walks one action table for everything).
- **Do NOT** reach for XInput or a `WndProc`/raw-input reader to "match" the game — the retail title uses
  neither; DirectInput8 (KB/mouse + joystick) is the whole PC surface, and the Xbox side is XDK
  XInput-over-`xam.xex` with no per-fn body to mirror.
