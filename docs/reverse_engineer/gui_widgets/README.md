---
status: current
evidence: proven
---

# Script-facing GUI widgets and load states: pc-v10 retail semantics

Read 2026-11-25. Image: **pc-v10**. All addresses are VAs in `game-files/canonical/dumps/mercs2_unpacked.exe`
(file offset = VA − 0x400000).

## Grades and method

- **PROVEN** means the instruction(s) were read in that run with
  `objdump -d -M intel --start-address=… --stop-address=…` or from the corpus Ghidra export (`corpus_get ghidra/pc-v10/0x…`).
- **INFERRED** means reasoned from structure or names and not checked instruction by instruction.
- **SPECULATIVE** is flagged where used.
- The live Ghidra bridge for pc-v10 was lock-held by another JVM throughout, so all reads come from objdump plus the corpus exports.
- The run's scratch dumps were not kept; `objdump` at the cited addresses gives them again.

Two sub-reports were folded in:
- **Q3/Q4** come from a text/image read.
- **Q5** comes from a movie read. One addition to it, read after: the Bink quad (`0x0070A3D0` →
  `0x00853940`) is drawn from `(x − 0.5, y − 0.5)`, `width × s` by `height × s` with the whole texture
  on it, where x, y, width and height are the integers `Play` (`0x00621AB0`) took from the widget's
  rect (vtable `+0x20`) and `s` is `[0x00B9C5D8]` = 1.25 for a 1024-wide movie, else 1.0
  (`0x0070A41A`). What the 1.25 is for is INFERRED: 1280/1024, undoing a frame that fills four fifths
  of the texture.

Those sections are marked with their own grades. I did not re-verify every instruction they cite.

The prior doc `docs/reverse_engineer/hud_widget_code_map.md` (2026-11-24) was used as a map. Every claim below that is marked PROVEN was re-read this run. Where this run contradicts that doc, it says so.

Helper semantics used throughout. All are PROVEN by their use in the binders:

| Helper | Meaning |
|---|---|
| `0x5A0000` | read widget id (lightuserdata) |
| `0x59F780` | optional number; returns < 1 when absent |
| `0x59F6D0` | optional bool |
| `0x59FA40` | optional string |
| `0x59FB00` | string → `pandemic_hash_m2` |
| `0x59FD20` | reads a 4-number struct |
| `0x59FB60` | reads a 2-number point |
| `0x5A03B0` | callback ref: function + data table |
| `0x85D5D0` | stack reserve; followed by a push |
| `0x4B2A50` | `lua_error` |

---

## Q1. The widget object and every `_GuiInternal` call

### 1.0 Registry and identity

| Fact | Evidence | Grade |
|---|---|---|
| The `_GuiInternal` luaL_Reg table is at `0x00B99FF8` (114 entries). `Gui` is at `0x00B9A398`. | `output/_exemap_exports/pc-v10.luareg.tsv` rows 7–120 and 121 | PROVEN |
| Widget manager = `*(DAT_01175FB0+0x68)`. Slot array `+0x44`, capacity `+0x4C` (0x80). | prologue of every binder, e.g. `0x5B58A4..0x5B58B6` | PROVEN |
| A widget id is a slot index pushed as lightuserdata. An unknown id returns nil, not an error. | `0x5B5874..0x5B5899` (push type 0 = nil) | PROVEN |
| Type tag is at `+0x10`: 0 base, 1 image, 2 text, 3 minimap, 4 movie, 6 flash, 7 sprite. | doc §3; the draw pass switches on it at `0x61988A..0x6198D4` | PROVEN |

### 1.1 Base widget layout

Only fields that matter for drawing and loading are listed. The base size is `0x130`.

| Off | Field | Writer / reader evidence | Grade |
|---|---|---|---|
| `+0x14` | hovered, byte | written by the hover test vtable +0x44 `0x6270A0` (`0x62714D` set 1, `0x62715C` set 0) | PROVEN (new; the doc said "unnamed") |
| `+0x15` | highlightable | the hover test requires it (`0x6270BE`) | PROVEN |
| `+0x18` | slot id | the hover test copies it to `DAT_01176034` (`0x627148..0x627151`) | PROVEN |
| `+0x1C` | viewport index | draw pass `0x61981F cmp [esi+0x1C], viewport` | PROVEN |
| `+0x20` | visible (own flag) | SetVisible `0x62770C`; draw pass reads it through vtable +0x58 (`0x61982A`) | PROVEN |
| `+0x21` | sleep | read through vtable +0x6C in the draw, update and hover loops (`0x61985B`, `0x619104`) | PROVEN |
| `+0x30..+0x3C` | authored rect `x1,y1,x2,y2` in 640×480 design units | SetRect `0x627392/0x6273A2` | PROVEN |
| `+0x40..+0x4C` | corrected (screen) rect | rescale core output, per doc §3.5; the hover test and Image draw read it through vtable +0x20 | PROVEN (read) |
| `+0x50..+0x5C` | RGBA as floats 0..1 | SetColor `0x627631..0x62765E` | PROVEN |
| `+0x60` | useResolutionCorrection, default 1 | the SetRect child walk gates on it (`0x6273C0`) | PROVEN |
| `+0x62` | ignoresPause | manager tick `0x6190ED`, `0x619132` | PROVEN |
| `+0x63` | active (on the drawable list) | vtable +0x60 sets it, +0x64 reads it; manager tick and ActivateWidget (§1.4) | PROVEN |
| `+0x64` | deactivation pending | ActivateWidget(false) → `0x627D50` with al=1 (`0x618E79..0x618E81`, `0x627D57 mov [esi+0x64],al`); the draw pass skips it (`0x619876`) | PROVEN |
| `+0x65` | activation pending (queued on mgr+0x10) | `0x618E37` | PROVEN |
| `+0x68` | fullscreen mode 0..3 | doc §3.5. The loading screen writes 1 (`0x60B03D`) | PROVEN (write) |
| `+0x6C` / `+0x70` | horizontal / vertical anchor | SetWidgetAnchoring `0x5B5FC3` / `0x5B5FBB` | PROVEN |
| `+0x78/+0x7C` | update-callback ref | tick `0x627207..0x62725E` | PROVEN |
| `+0x80` | interpolating, byte | Interpolate `0x6277B0` sets it; step `0x628251` clears it | PROVEN |
| `+0x84` | interpolation time remaining (s) | `0x6277B0`, step `0x628224..0x628249` | PROVEN |
| `+0x90..+0x9C` | rect velocity per second | `0x6277B0` | PROVEN |
| `+0xA0..+0xAC` | colour velocity per second | `0x6277B0` | PROVEN |
| `+0xB0..+0xBC` | rect delta still to apply | `0x6277B0`, step `0x628372..0x6283CA` | PROVEN |
| `+0xC0..+0xCC` | colour delta still to apply | `0x6277B0`, step `0x628402..0x62844A` | PROVEN |
| `+0xD0` | "maintain dimensions" flag (2-point form) | `0x6277B0`; step `0x628242`, `0x62828A` | PROVEN |
| `+0xD8/+0xDC` | interpolation-complete callback ref | `0x6277B0`; tick `0x6271AF..0x627202` | PROVEN |
| `+0xE0` | "do not update / draw / hover" flag | checked first in tick, draw and hover | PROVEN (role named from its readers) |
| `+0xE4` | update refcount | `0x627CD0 add [esi+0xE4],-1` when an interpolation ends | PROVEN |
| `+0xEC` | parent pointer | doc §3.1; not re-read | INFERRED |
| `+0xF0` | child list head; node `{next, prev, owner@+8}` | walked by SetVisible `0x627706`, SetRect `0x6273AF`, SetColor `0x62766B`, colour-delta `0x62769F` | PROVEN |
| `+0x100` | node for the pending/active queues | `0x618E29..0x618E4F` | PROVEN |
| `+0x118` | node for the update lists mgr+0x20 / +0x30 | `0x61944F..0x619474` | PROVEN |

**Correction to `hud_widget_code_map.md` §2.1 (PROVEN).** Vtable +0x44 (`0x6270A0`) is not draw. It is the **cursor hover hit-test**:
1. It requires `[0x1175F2F]` and `+0x15`.
2. It compares the cursor ints `[0x1176024]`/`[0x1176028]` with the corrected rect.
3. It writes `+0x14` and the highlight id.

The draw virtual is **vtable +0x04**:
- the manager draw pass calls it at `0x619A36`;
- the Image draw is `0x61D070` (text/image sub-agent);
- the Movie draw is `0x621A80` (movie sub-agent).

### 1.2 Coordinate space: 640×480 virtual canvas, anchoring, CorrectWidgetForResolution

- **The design space is 640×480.** The rescale core (vtable +0x70 = `0x627DA0`) uses frame-A = `[0x00BEAC58]`=640.0 × `[0x00BEAAC8]`=480.0 and frame-B = the viewport size `[vpDesc+0x28]`×`[+0x2C]`, where `vpDesc = [0x00DFC2F8] + vp*0xE80`. A relative-to-parent widget uses the parent's rects instead. Constants re-read this run (`rd.py`): `[0xBEAC58]`=640.0, `[0xBEAAC8]`=480.0, `[0xBEA95C]`=1/480, `[0xBEAE54]`=0.5625 → PROVEN. Their use inside `0x627DA0` comes from the doc → INFERRED (doc H).
- The output is written into `+0x40..+0x4C` through vtable +0x24.
- **Anchors.** `SetWidgetAnchoring(id, h, v)` `0x5B5E70` buckets each number:

  | Value | horizontal `+0x6C` | vertical `+0x70` |
  |---|---|---|
  | `< −0.5` | 0 (left) | 3 (top) |
  | `−0.5 … +0.5` | 2 (centre) | 2 (centre) |
  | `> +0.5` | 1 (right) | 4 (bottom) |

  The bucket constants `[0x00DFDCA4]`=−0.5 and `[0x00BBB99C]`=+0.5 are from the doc. This run confirmed the stores at `0x5B5FBB`/`0x5B5FC3` and the immediate recompute: `0x5B5FBE mov eax,[edx+0x70]; call eax` = rescale core. PROVEN.
- So `(−1,−1)` = left/top, `(0,0)` = centre/centre, `(−1,1)` = left/bottom, `(0,1)` = centre/bottom, `(0,−1)` = centre/top.
- How each anchor maps 640-space to pixels (keep the edge distance, scaled by height) is in the anchor branch at `0x62801D`, which I did not re-read. INFERRED, from the doc only.
- **`CorrectWidgetForResolution(id)`** `0x5B6D70` resolves the widget and calls vtable +0x5C (`0x5B6E00 mov eax,[edx+0x5C]; call eax`). +0x5C tail-jumps to +0x70, the rescale core. PROVEN (binder), per the doc for +0x5C. It recomputes the corrected rect from the current authored rect, mode and anchors.
- The text override of +0x5C (`0x622940`) also sets text `+0x148` from the per-viewport scale `[vp+0x34]` (text sub-agent; PROVEN there).
- **The trailing `true` of `SetWidgetLocation`.** The 4-value form goes to vtable +0x10 = SetRect `0x627360(rect*, bool)`:
  1. Store the rect (`0x627392`, `0x6273A2`).
  2. Rescale (`0x6273A7`).
  3. **If the bool is set**: for every child whose `+0x60` (useResolutionCorrection) is set, call the child's +0x14 Move to its own top-left plus the parent's top-left delta, with propagate=1 (`0x6273C0..0x627416`).

  So `true` = **children move along with the parent, keeping their size**. Children with `+0x60 == 0` are left in place. PROVEN.
- The 2-value form (`x2,y2` nil) goes to +0x14 Move, which translates all four corners (doc §3.2). INFERRED (doc H).
- `SetWidgetLocation(id,128,68,nil,nil)` = move, keep size.
- **The default bool is true when omitted** (doc §3.2). INFERRED.

### 1.3 Colour: the 6th argument, −255, and how parent colour combines

- **Binder** `SetWidgetColor(id, r,g,b,a, bPropagate)` `0x5B5560`:
  - An absent channel defaults to −255 (`[0x00BEB2E4]`).
  - Every channel is multiplied by 1/255 (`[0x00BAC8BC]`).
  - It calls vtable +0x48 only if at least one channel was given (doc §3.3). The 6th argument defaults to true. INFERRED (doc H).
- **Base SetColor** +0x48 = `0x627620(float rgba[4], bool propagate)`. PROVEN:
  - Each channel is stored only if `value >= 0.0` (`comiss; jb skip` at `0x62762C`/`0x62763B`/`0x62764A`/`0x627659`). **Any negative value (−255 → −1.0) means "leave this channel unchanged".**
  - It is not "relative" and not "inherit". `SetTranslucency` passes −255,−255,−255,a to change alpha only.
  - **When propagate is true** (`0x627663`), it calls **each child's +0x48 with the same array and propagate=1** (`0x62766B..0x627689`). Descendants get the same absolute values written, with negatives skipped per channel.
  - So `SetWidgetColor(id,-255,-255,-255,0,true)` = set alpha 0 on the widget and its whole subtree. `(id,0,0,0,192,true)` = black at alpha 192/255 on the subtree.
- **During interpolation, colour reaches children additively, not as a copy.** The interpolation step applies colour through vtable +0x50 = `0x627690`. PROVEN:
  - It **adds** the per-step delta to the widget's own channels and recursively to every descendant (`0x6276A9..0x6276F5`).
  - It has no flag and no clamp.
  - So in a parent `InterpolateWidget`, children shift by the parent's delta rather than converging on the parent's target. A child that started at a different colour ends at a different colour, and its alpha can go below 0 (it is then not drawn).
  - This differs from `SetWidgetColor(…, true)`, which writes absolute values down the tree.
- **At draw time there is no parent × child multiplication.** The draw pass reads only the widget's own colour (alpha test `0x619839..0x619849`; the Image draw passes its own vtable +0x4C colour per the sub-agent). PROVEN for the alpha test; INFERRED for the shaders.
- **Alpha 0 means not drawn at all.** Draw-pass skip: `comiss 0.0,[colour+0xC]; jae skip` (`0x619842..0x619849`). PROVEN.

### 1.4 `SetWidgetFullscreen(true)` vs `"Letterbox"`

The binder `0x5B6BC0` writes `+0x68` and then calls +0x5C (doc §3.5; not re-read this run, INFERRED):
- `true` → 1. Fullscreen: rect = whole viewport, `(0,0,W×aspect,H)`.
- `false` → 0.
- A string is dispatched on `tolower(s[0])`:
  - `'f'` → 1;
  - `'l'` → 2, letterbox: a 16:9 band (0.5625) centred vertically across the full width;
  - `'o'` → 0;
  - `'p'` → 3, pillarbox.

The engine's own loading screen forces mode 1 on its flash widget when `+0x68 == 0` (`0x60B032..0x60B040`). PROVEN.

### 1.5 `ActivateWidget` vs `SetWidgetVisible` (and the draw/update lists)

- **`SetWidgetVisible(id, b)`** `0x5B5850`. PROVEN:
  - b is required. If it is missing → `lua_error` (`0x5B58F0..0x5B58F7`).
  - It calls vtable **+0x54** (`0x5B5909`).
  - Base +0x54 = `0x627700` writes **its own `+0x20 = b`**, then walks the child list (+0xF0) and calls **each child's +0x54(b)**, so the whole subtree is set.
  - A later `SetVisible(true)` on a child after `SetVisible(false)` on its parent leaves that child (and its subtree) visible.
- **Drawing tests only the widget's own `+0x20`.** There is no ancestor walk in the draw pass (§2). PROVEN for the loop body (`0x61981C..0x619879`). That nothing downstream re-checks ancestors is INFERRED.
- **`ActivateWidget(id, b)`** `0x5B5B50` → `0x618DD0(mgr, id, b)`. Its first branch passes through a SecuROM split at `0x618DF5` (`jmp 0x4E5B3B`), so the bool test itself was not read. The two resumed paths are PROVEN:
  - **Activate** (`0x618DFA..0x618E5A`), when not already active (+0x64 vfn = `+0x63`==0) and not already pending (`+0x65`==0):
    1. vtable +0x5C (CorrectForResolution);
    2. `+0x64 = 0`;
    3. link node `+0x100` onto the **pending-activation queue mgr+0x10**;
    4. `+0x65 = 1`.
  - **Deactivate** (`0x618E69..0x618E81`), if active or pending: `mgr+0x41 = 1` and `+0x64 = 1` (deactivation pending).
- The pending queue keeps call order: `0x618E3D` links at its tail.
- The manager tick `0x6190B0` drains mgr+0x10 (`0x6193A0..0x6194D6`):
  - widgets with `+0x64` set get vtable +0x60(0) (`+0x63 = 0`) and leave the lists;
  - the rest are collected in order (`0x6193C6..0x6193EE` appends);
  - then at `0x619621..0x619642` each one's node `+0x100` is **linked at the tail of the main list mgr+0x00**, `+0x65 = 0`, and vtable +0x60(1) sets `+0x63 = 1`. PROVEN.
- **So draw order = the order of `ActivateWidget(true)` calls**, later activations on top, as changed by PushWidgetToFront/Back.
- **`0x618DD0` has no child walk** (no `+0xF0` access in `0x618DFA..0x618E88`). Every child needs its own `ActivateWidget`. PROVEN.
- **Summary:**
  - *active* = the widget is in the manager's lists at all: ticked, drawn, hover-tested;
  - *visible* = a per-widget draw flag, set recursively over the subtree;
  - both are needed to draw.
  - Activation takes effect at the **next manager tick**, not immediately.

### 1.6 `InterpolateWidget`: 19 arguments, curve, clock, completion

The Lua caller `mrxguibase.lua:715/717` names the arguments. Binder `0x5B60F0`, setup `0x6277B0`, step `0x628210`, tick `0x627170`.

| # | Lua name (mrxguibase.lua:715) | Read by | Meaning | Grade |
|---|---|---|---|---|
| 1 | `uId` | `0x5A0000` | widget id. Unknown id → returns nil. | PROVEN |
| 2 | `nAnimationTime` | `0x59F780`; absent → 0 | duration in seconds. Setup stores `+0x84 = d` and uses `1.0/d` for velocities (`DAT_00B9B664`=1.0). | PROVEN |
| 3,4 | `nX1,nY1` | `0x59FB60` (point), required → lua_error | target top-left | PROVEN |
| 5,6 | `nX2,nY2` or nil,nil | `0x59FB60`, optional | target bottom-right. If absent, the "maintain dimensions" flag is set (→ `+0xD0`). | PROVEN (decomp of 0x5B60F0) |
| 7–10 | Red, Green, Blue, Translucency (0..255, −4096 = unchanged) | `0x59FD20` 4-number struct, required; each ×1/255 | target colour. **Any negative target** (−4096/255 ≈ −16.06) gives that channel zero velocity and zero remaining delta (`0x6277B0` tail: `if (c<0) vel=0, delta=0`), i.e. **unchanged**. | PROVEN |
| 11,12 | `_HandleAnimationComplete`, `{self}` | `0x5A03B0` callback ref | completion callback + arg table; absent → none | PROVEN (read); callback mechanics below |
| 13–16 | `nU1,nV1,nU2,nV2` | `0x59FD20`, only when tag is 1 or 7 | target UVs; absent → current `+0x140..+0x14C` | PROVEN |
| 17 | `nRotation` (degrees) | `0x59F780`, tag 1/7 only | target rotation, ×`[0xBEAB18]`=π/180 (`0x5B63CE`); absent → current `+0x150` | PROVEN |
| 18 | `nRotationDirection` | `0x59F780`, tag 1/7 only | passed with the rotation to `0x61D440` (image UV/rotation interpolation setup) | PROVEN read; semantics NOT DETERMINED |
| 19 | `nElapsedTime` | `0x59F780` at `0x5B6423` | read; how it alters the start state is NOT DETERMINED (stack slot tracking through `0x6277B0`'s args is ambiguous) | NOT DETERMINED |

**Curve: linear and additive.** Step (vtable +0x74 = `0x628210(dt)`). PROVEN:
1. `remaining -= dt`.
2. **While remaining > 0**:
   - apply `rectVel×dt` through vtable +0x18 (child-propagating transform; args `(delta,1,1,flag,flag)`, where the last pair is (0,0) if `+0xD0`, else (1,1));
   - apply `colourVel×dt` through vtable +0x50 = `0x627690`, which **adds** the delta to its own colour **and recursively to every child** (`0x6276A9..0x6276F5`);
   - subtract the applied amounts from the remaining deltas.
3. **On the step where remaining ≤ 0**: remaining = 0, `+0x80 = 0`, then apply **exactly the remaining delta** (`+0xB0` rect, `+0xC0` colour). With no outside writes the end values are exact.
- Because the step is additive, a `SetWidgetLocation` or `SetWidgetColor` during the interpolation composes with it rather than being overwritten.
- **Colour interpolation always reaches the descendants** (0x627690 has no propagate flag).
- **Duration 0:** velocity = 1/0 (inf). On the first step remaining ≤ 0, so the full delta is applied in one step. INFERRED (from the step code).

**Completion callback timing.** Widget tick vtable +0x08 = `0x627170(dt)`. PROVEN:
1. If `+0xE0` → nothing.
2. If interpolating (`+0x80`): call step(dt).
3. If that step cleared `+0x80`:
   - `0x627CD0` (`+0xE4 -= 1`, unregister from the update list at 0);
   - then, **in the same tick**, if a completion ref exists: copy it, **clear `+0xD8/+0xDC` first**, and invoke it (`0x5A06B0` with arg count 1, no extra args; `0x6271F2..0x627202`). So the callback can start a new InterpolateWidget safely.
4. Then, if an update callback is set (`+0x78/+0x7C`), it is called with dt pushed as a number (`0x627212..0x62725E`).

A new InterpolateWidget on a widget that already has a pending callback releases the old ref (`0x6277B0` tail `0x59DD70` / `thunk_FUN_024f2900`) **without calling it**. PROVEN.

**Clock.** Manager tick `0x6190B0(mgr, dt, bPaused)` (`0x6190CC..0x619151`). PROVEN:
- `bPaused` = app `[0x1175FB0]+0x0C` and `dt` = the caller's frame argument (`0x6098DF..0x6098F3`).
- For each widget on the update list mgr+0x20 that is not `+0xE0`, not `+0x64` and not asleep:
  - **paused**: only `ignoresPause` (`+0x62`) widgets tick, using the passed `dt`;
  - **not paused**: ignoresPause widgets tick with the passed `dt`; **all others tick with the sim dt `[0x01175A90]`**.
- Which clock the passed dt is (raw frame time) is INFERRED, from it being distinct from the sim dt.
- What sets app `+0x0C` (latched from `+0x0D` at `0x609805..0x60980D`) is NOT DETERMINED in full. The `pause` state is the obvious candidate (SPECULATIVE).

### 1.7 The other binders in the brief

| Call | Binder | Arguments → effect | Grade |
|---|---|---|---|
| `CreateWidget/CreateImageWidget/CreateTextWidget/CreateFlashWidget/CreateMovieWidget` | `0x5B4E80 / 0x5B7070 / 0x5B7D40 / 0x5BA680 / 0x5BC1A0` | () → id. Allocates 0x130/0x1C0/0x170/0x4C0/0x150, runs the ctor, takes the first free slot. **Not active and not drawn until ActivateWidget.** | doc §3; the "until activated" part is INFERRED from §1.5 |
| `AddWidgetChild(parent, child)` | `0x5B66E0` | resolves both ids (bad parent → lua_error), then `thunk_FUN_024eb070` (SecuROM) | body NOT DETERMINED on PC; `+0xEC`/`+0xF0` per the ctor |
| `SetWidgetIgnoresPause(id,b)` | `0x5B59D0` | `+0x62 = b` (doc `0x5B5A86`) | INFERRED (doc H); consumer PROVEN §1.6 |
| `SetWidgetUpdateCallback(id, fn, data)` | `0x5B6460` | sets `+0x78/+0x7C`; nil clears. Called each widget tick **after** the interpolation, with dt. | PROVEN consumer `0x627207` |
| `CorrectWidgetForResolution(id)` | `0x5B6D70` | vtable +0x5C | PROVEN |
| `SetWidgetSleep(id,b)` | `0x5B5C10` | `+0x21`; a sleeping widget is not ticked, drawn or hover-tested | consumers PROVEN `0x619104`, `0x61985B` |
| `PushWidgetToFront(id)` | `0x5B5D90` → `0x618E90` | if active: re-link node `+0x100` at the **tail** of mgr+0x00 (drawn last = on top), then recurse over the children in child order | PROVEN `0x618ECF..0x618F18`, `0x618F7B..0x618F9A` |
| `PushWidgetToBack(id)` | `0x5B5E00` → `0x618FB0` | if active: re-link at the **head** of mgr+0x00 (drawn first), then recurse over the children. Each child goes in front of the previous one, so **children end up behind their parent**. | PROVEN `0x618FEF..0x619026`, `0x619081..0x6190A2` |

---

## Q2. Draw order and where the GUI sits in the frame

**The widget pass.** `FUN_00619760(mgr, viewport, ctx)`, called from `0x609E17`. PROVEN, `0x61980B..0x619B30`:

1. Walk the **manager main list mgr+0x00 in list order** (not the tree). Draw a widget only if **all** of these hold:
   - `w+0x1C == viewport`
   - `GetVisible` (own `+0x20`)
   - colour alpha `> 0`
   - **tag != 0**: plain `CreateWidget` containers are never drawn
   - not asleep
   - `+0xE0 == 0`
   - `+0x64 == 0`
   - slot id `>= 0`
2. Flash widgets (tag 6) are **deferred** into a 64-entry list. Minimaps (tag 3) are also recorded in an 8-entry list.
3. Each other eligible widget is drawn immediately with vtable +0x04(ctx), in list order. Batches are flushed (viewport-manager vtable +0x24/+0x20) when the type, font/texture hash (text `+0x138`, image/sprite `+0x130`) or alpha changes.
4. After the list:
   - each minimap's vtable +0x7C(ctx);
   - then **every Flash widget's vtable +0x04(0), in list order** (`0x619ACB..0x619AFC`);
   - then each minimap's vtable +0x04(ctx).

   So **Flash widgets always draw on top of every non-Flash widget**, regardless of list position.
- List position is set by activation, appended at the tail (PROVEN, §1.5), and changed by PushWidgetToFront/Back (§1.7).
- **Movie widgets (tag 4) are not special-cased.** They draw in list order through their own +0x04 = `0x621A80` (Bink quad, movie sub-agent). PROVEN that tag 4 has no branch in `0x61988A..0x6198D4`.

**The frame position.** GUI overlay pass `~0x62EF00` (phase `eax==2`, viewport `edi`). PROVEN, `0x62EF11..0x62EF94`, in this order:
1. If the viewport byte `[vpDesc+0x3C]` and `[0xE7ADFC]+0x108` → `0x468ED0`.
2. If the world-present flag `[[0x1175CDC]+0x63]` → `0x60F6D0([app+0x6C], vp)`, i.e. 3D markers / world-space HUD. INFERRED role.
3. Viewport-manager vtable +0x38.
4. If world-present → `0x60FEE0([app+0x6C], vp)`.
5. **`0x709790(vp)` Bink manager.** This starts pending records, closes stopped ones, and on viewport 0 decodes the next frame (`0x70A230`) for each playing record (`0x7097A0..0x7097EC`). PROVEN. **Decoding happens here; drawing happens in the movie widget's +0x04 in step 6.**
6. **`0x609E00(vp)` GUI** (PROVEN, `0x609E01..0x609EB5`):
   1. if `[app+0x04]`: widget pass `0x619760`; on viewport 0 also `0x60E6B0`;
   2. **if the current game state is `cinematic` (`0xB8CB300C`) → return** (no loading screen, no hints);
   3. otherwise draw the **engine loading-screen Flash `[app+0x24]`** with vtable +0x04 (viewport 0 only), **on top of all widgets**;
   4. then, if hints are on (`app+0x39`), the two hint widgets `[app+0x28]`, `[app+0x2C]`.

This pass is "phase 2" of a render callback, so it comes after the 3D scene. That the phase-2 callback runs after the scene draw is INFERRED: its caller was not traced.

---

## Q3. Text widgets (text/image sub-agent; grades are its own)

| Binder | Args | Effect |
|---|---|---|
| `SetTextText 0x5B7DE0` | (id, str) | Stores into `+0x130` (UTF-16), clears "tokens expanded" `+0x13D`, sets dirty and queues relayout. **The rect is not touched.** PROVEN on the wide setter `0x622A00`; the PC binder→setter link is INFERRED (VM). |
| `SetTextFont 0x5B7FC0` | (id, name) | If the name contains `"english"`, that part is replaced by the language table `0xCF281C[*0x1176018]` (english, spanish, italian, french, german, japanese, english_uk, allcaps). Then `pandemic_hash_m2` → font hash `+0x138`, requested from the GUI font table (type `0x99E77ACE`) through the streaming registry. PROVEN on substitution and hash. |
| `SetTextJustification 0x5B83E0` | (id, str) | `tolower(s[0])`: `'l'`→0, `'r'`→1, `'c'`→2; anything else is ignored. PROVEN. |
| `SetTextWrapping 0x5B80A0` | (id, b) | `+0x13C`. Wrap width = the authored rect width; breaks at space, tab or `\n`; over-long words are split. PROVEN (`0x623500`). |
| `SetTextScale 0x5B85F0` | (id, n) | `+0x144` (default 1.0); re-layout. PROVEN. |
| `GetTextWidth/Height 0x5B8240/0x5B8310` | (id) | **Measured text, not the rect** (Text overrides vtable +0x30/+0x34 = `0x6226D0/0x622800`). Height = `lines × scale × lineHeight × 2/3`. It falls back to the rect when there is no text or font, and width falls back to the rect when wrap is on. PROVEN. This corrects doc §3.1. |

- **Font resolution.** Font = `(hash, type "font" 0x99E77ACE)` through the global resource registry. **No WAD name appears**: whichever mounted archive made the asset resident.
- The ctor pre-pins `font_16` (`0x339761F4`). `english_18` = `0x093F42E5`.
- Until the font is resident, layout bails and the widget stays dirty (`0x292C048..`). PROVEN.
- **Bracket tokens are expanded at layout time, once per SetTextText, not at draw time and not at set time.** Grammar (`0x2F50000` + `0x622DE0`):
  - `\n` / `[n]` → newline;
  - `[barN]`;
  - `[!x]`;
  - button tokens → glyph codes;
  - any other name → `pandemic_hash_m2(name up to ':' or ']')` → stringdb lookup `FUN_00464230`. A hit substitutes, filling `%d`/`%s` from `:`-separated args. **A miss copies the token verbatim.**
- The expanded text then **replaces `+0x130`**.
- A language change afterwards does not re-expand.
- Grades: PROVEN on X360 and on the PC tail; the PC `0x623240`→`0x622DE0` link is INFERRED.

## Q4. Image widgets (text/image sub-agent)

- **`SetImageTexture(id, name|hash|nil)` `0x5B7110`**: tag 1 only. A string is hashed; a number is taken as the hash; nil → 0. Then `0x61D360` (VM).
- **Texture = `(hash, type "texture" 0xF011157A)`** requested through the GUI texture table → streaming manager `0x872F40([0x1176630], &entry, 3)` (`0x28E1000`). **No WAD name appears.** PROVEN.
- **A nil (0) texture still issues the quad** with hash 0 (`0x61D070` → `0x6179A0`). Whether that renders as a solid widget-colour quad is **NOT DETERMINED** (`0x6179A0` → VM `0x24BA510`).
  - Speculative note: the shipped layouts use `texture=nil` image widgets as black backgrounds (`mrxguicinematiclayout.lua` "placeholder black bg"), which suggests a solid colour quad. SPECULATIVE.
- **Transience** (`SetImageTextureTransience(id,true)` → `+0x194`). PROVEN on PC:
  - while it is set, the Image tick (`0x61D200`) re-touches the texture every update;
  - on a texture change the old transient texture is released (X360-derived, INFERRED).
  - It is **not** tied to visibility.
- **UVs** `(u1,v1,u2,v2)` at `+0x140..+0x14C`, default (0,0,1,1); a missing argument keeps the current component. PROVEN.
- **Rotation** is stored as radians (degrees × π/180). Pivot NOT DETERMINED.
- The Image draw uses the **corrected rect** and its own colour, and skips degenerate rects (x1>=x2 or y1>=y2). PROVEN.

## Q5. Movie widgets (movie sub-agent; grades are its own)

- **Path.** `sprintf("%sMovies\%s.bik", ".\Data\", name)` (`0xBD1EB0`, `0x709CB0`), so `01_AOA_C` → `Data\Movies\01_AOA_C.bik`. PROVEN.
- **One widget movie plays at a time.** Every widget Play uses Bink record 0 (`0x621B5F`). PROVEN.
- **`PlayMovie(id, bLoop)`**: the second argument is **loop**; nil → false (`0x5BC330` → `0x621AB0`). PROVEN.
- **Fit.**
  - Play copies the widget's **corrected rect** into the record. For widgets, the letterbox comes from the widget: `SetFullscreen("Letterbox")` = mode 2 → 16:9 band.
  - The player's own aspect fit only applies when `w == −1`.
  - A 1024-wide video gets ×1.25 scale params. INFERRED purpose.
- **Audio.** `BinkSetSoundTrack(4, {0, 2, 3, lang})`. The language track id comes from the language index:

  | Language | Track id |
  |---|---|
  | english | 2001 |
  | german | 2003 |
  | french | 2004 |
  | spanish | 2005 |
  | italian | 2006 |
  | others | 2001 |

  Each track's volume is set to `DialogVolume×0.01×32768`. So 4 of the 8 tracks play (`01_AOA_C.bik` track ids `[0,2,3,2001,2003,2004,2005,2006]`). PROVEN.
- **End callback** `SetMovieEndCallback(id, fn, tData)`, stored at `+0x130/+0x134`. It fires from the widget tick (`0x621960`) when a running movie's record closes:
  - natural end, **one frame after the last frame**;
  - a skip;
  - record 0 being reused by another start.

  **`StopMovie` never fires it** (it zeroes the widget state first). The ref is not cleared after it fires. PROVEN.
- **Missing file.** `BinkOpen` NULL → logs `Bink::Start() FAIL: %s - FileNotFound` → record closed. The widget stays in "start requested" and **retries every tick forever; the end callback never fires**, so Lua waiting on it hangs. PROVEN.
- **Skip.**
  - `0x4C9740` calls `0x709740` when input ids 1, 0x14 or 6 are held (`0x4BEB50`).
  - It only skips if `[Render] FirstRun == 0` and at least 30 frames have been decoded since start. Otherwise it logs "This movie can't be skipped".
  - The first run is unskippable. PROVEN; button mapping NOT DETERMINED.
- **`Net.SendEvent_ShowMovie(name, fadeIn, fadeOut, bSubtitles)`** `0x5C8F50`:
  - only when `Net.IsEnabled && Net.IsServer`;
  - the name is truncated to 11 characters;
  - always returns true.
  - **In single-player it does nothing.** The client side calls Lua `NetClientShowMovie` → `Hud.Cinematic:Show`.
  - `HideMovie` sends an empty name. PROVEN.

---

## Q6. Game states, the loading screen, `Net.SetLoadingScreen`, `Gui.OnGlobalExit`

### 6.1 Machine recap

From `mission_contract_flow_code_map.md` §3, plus the vtables re-read this run with `vt.py`. PROVEN.

- `Sys.RequestGameState(name)` `0x5E4AF0` hashes the name (case-insensitive) and **publishes** onto a queue. It always returns true, and it swallows requests made while in `unloading` (and `shell` requested while in `unloadshell`).
- The state pump `0x4C09C0` drains the queue:
  1. exit the old state (vtable +0x08);
  2. broadcast `{old,"exit"}`;
  3. init (vtable +0x0C) and enter (vtable +0x04);
  4. broadcast `{new,"enter"}`. These broadcasts are `Event.GameStateChange`.
- Then each frame: the current state's Update (vtable +0x10, dt), then the per-system pump (which runs even with no current state).
- An unknown name means no current state.

| State (hash) | vtable | enter | exit | update |
|---|---|---|---|---|
| loading `0x96FB0F27` | `0xBB00F0` | `0x4B97E0` | `0x4B99A0` | `0x4B9AF0` |
| waitforplayer `0x05CE7A0C` | `0xBB010C` | `0x4B9C80` | `0x4B9DB0` | `0x4B9E40` |
| waitforstreaming `0x7E289119` | `0xBB0128` | `0x4B9EB0` | `0x4BA0E0` | `0x4BA200` |
| unloading `0x7D0B162C` | `0xBB01B4` | `0x4BB030` | `0x4BB0A0` | `0x4BB230` |
| unloadshell `0x20BC86EA` | `0xBB01D0` | `0x4BC5C0` | `0x4BC650` | `0x4BC6D0` |
| ingame `0x57B5E35A` | `0xBB0368` | `0x4BD490` | `0x4BD4D0` | `0x4BD500` |
| cinematic `0xB8CB300C` | `0xBB0384` | `0x4BD530` | `0x4BD5D0` | `0x4BD670` |

### 6.2 What each state does (PROVEN except where marked)

**`loading`.**
- **Enter** `0x4B97E0` (the head passes through a SecuROM split at `0x4B97FA`; the body from `0x4B98A1` was read):
  - `[app+0x20] = 0`;
  - **if `[app+0x30]==0` → show the engine loading screen `0x60AFA0`** (§6.3) and `[0x1175A71]=1`;
  - state `+0x11=0`, `+0xC=0.0`;
  - four entries at `[0xED1D08]` (stride 0x20) set to `{1000, 0}`;
  - `[app+0x0D]=0`, `[app+0x10]=0`;
  - **viewports 1..n−1 get `[vpDesc+0x3C]=0`**;
  - start a QueryPerformanceCounter timer (`0xED1CF0`).
- **Update** `0x4B9AF0`:
  - time `+0xC += [0xD26394]` (a frame-dt global);
  - **after 2.0 s** (`[0xB92874]`), once: if `[app+0x30]==0` (the loading SWF has not reported `wipeComplete`) → **destroy the loading screen** `0x60B2F0`; then **`[app+0x39]=1` (loading hints on)** and notify `0x608590(1)`.
  - Once `[[0x1175CDC]+0x54] <= 0` it sends the Lua event `EventType="CloseShell"` (`0x60D420` with `0xBAD37C`/`0xBAD410`).
  - **Auto-advance:** when the streaming manager has nothing pending or in flight (`[[0x1176630]+0x824]+[+0x814]==0`), Lua is ready (`0x5A1D90`) and `[[0x1175CDC]+0x54]<=0` for **more than 10 consecutive frames** → publish **`waitforplayer`** (`0x4B9C22..0x4B9C59`).
  - *Loading never goes straight to ingame.*
- **Exit** `0x4B99A0`:
  - sends `CloseShell` if not already sent;
  - `[app+0x20]=1`;
  - `[ED1D08]` entries `{850, 0}`;
  - viewport bytes `+0x3C = 1`;
  - accumulates the timer; `0x4EBF90(0x900000CF, m2("default"))`, `0x4EC5F0`, `0x4FD9F0`.

**`waitforstreaming`.**
- **Enter** `0x4B9EB0` (SecuROM split at `0x4B9ECB`; tail read from `0x4B9F73`):
  - if `[0x1175A71]` (set by loading): `[app+0x0D]=1`, `[app+0x10]=1`, viewport bytes `+0x3C=0`, `[0x1175A71]=0`;
  - counters reset;
  - when a host, net hooks (`0x6C2EB0`/`0x6C2930`);
  - **when a net client, it raises the Lua event `"SafeEnter"`** (hash `0x44568127` path, `0xBAD41C`).
- **Update** `0x4BA200`, the **exact idle condition**:
  1. Frame counter `+8` is incremented every frame. It is reset to 0 while `Net.IsClient && [0x1176190]`.
  2. When the counter is **> 20 frames** and the stream manager's four in-flight counters are all zero — `[[0x1176630]+0x4C370 + 0x18] + [+0x1C] + [+0x28] + [+0x2C] == 0` (`0x4BA270..0x4BA299`):
     - **not a net client:** if the **`PendingSceneObject` container count `[0x00DF9C28]` == 0** → publish **`ingame`** (`0x4BA2A7..0x4BA2C7`).
       - The container name comes from the vtable name getter: `[0xDF9C10]` → vtable `0xBC40C8` → `"PendingSceneObject"`; count at `+0x18` (script `cont.py`).
     - **net client:** a player-flag check, then the `"SafeEnter"` Lua event (no publish).
  3. **Timeout:** if time `+0xC > 120.0 s` (`[0xD28B90]`): a client raises the event; otherwise **publish `ingame` regardless** (`0x4BA39A..0x4BA3D6`).
- **Exit** `0x4BA0E0`:
  - `[[0x1176630]+0x4C350] = [0x1175C3C]`;
  - `[ED1D08]={850,0}`;
  - `[app+0x0D]=0`, `[app+0x10]=0`;
  - viewport bytes `+0x3C=1`;
  - `0x4BA3F0`;
  - `"SafeExit"` Lua event if `+0x11`.
- The Lua `STATE_WAITFORSTREAMING` waits on `Event.GameStateChange {"WaitForStreaming","exit"}`. That fires when the engine itself moves to `ingame` (or anything else).

**`cinematic`.**
- **Enter** `0x4BD530`:
  - one-time init of `0x19C6170` (`0x830640`, atexit), then its vtable +0x44;
  - `[ED1D08]={1000,1}` ×4, `[0xED1D0C]=1`, `[0x1175A8D]=1`;
  - viewport bytes `+0x3C = 0`.
- **Exit** `0x4BD5D0`: vtable +0x48, `{850,0}`, flags 0, viewport bytes 1.
- **Update** `0x4BD670`: if the online singleton `[0x1176170]+0xDA64` → publish `ingame`; otherwise more logic (not fully read).
- **While `cinematic` is current, the loading-screen Flash and hints are not drawn** (`0x609E34`).

**`ingame`.**
- Enter `0x4BD490`: `0x6366C0` on the profile singleton `[0x1176054]`; `[0x17D3F38] = 0xFF202040`.
- Exit `0x4BD4D0`: `[0x17D3F38] = 0`.
- Update `0x4BD500`: `0x635CF0(profile)`; PDA bits.

**Common.** Every enter/exit writes `[0x1175A78]=0.0`.

**What `[app+0x20]`, the viewport byte `+0x3C`, `[ED1D08]` (1000 vs 850) and `[0x1175A8D]` control is NOT DETERMINED.**
- One reader of `+0x3C` is pinned: it gates `0x468ED0` in the overlay pass (`0x62EF1F`).
- `[[0x1175CDC]+0x63]` ("world present") gates the 3D-marker passes (`0x62EF49`), but its writer was not traced.
- So **"is the 3D world rendered during Loading" is NOT DETERMINED**. The loading SWF covers the screen regardless, because it is drawn last (§Q2).

**`Sys.IsLoadingOrStreaming()`** `0x5E4D40` = `cur && (cur.hash == 0x96FB0F27 "loading" || cur.hash == 0x7E289119 "waitforstreaming")`, pushed as a boolean.
- PROVEN, `0x5E4D40..0x5E4D8C`.
- It does **not** read stream-manager `+0x4C35C`, so `world_streaming_code_map.md` is wrong on that point.
- Separately, the waitforstreaming exit test reads the four counters at `+0x4C370` (`+0x18`, `+0x1C`, `+0x28`, `+0x2C`), not `+0x4C35C`.

**`[app+0x20]` has one known reader.** In the state pump's foreground predicate (`mission_contract_flow_code_map.md` §3.5, `0x004C0AD6`), the pump skips its frame with `Sleep(100)` only when the window is not foreground **and** `[[0x1175FB0]+0x20] != 0`.
- Loading enter clears it and loading exit sets it.
- So **during `loading` the game keeps running at full rate when it is in the background.** PROVEN for the writes; the reader is per the doc (H).

### 6.3 The engine loading screen (PROVEN)

It is a **Flash widget owned by the app singleton `[0x1175FB0]`**. It is **not** in the manager's slot table: it is created then unlinked from the global widget list and the count `0xDF6ACC` is decremented (`0x60AFC7..0x60B020`). It is ticked and drawn by the app directly:
- tick: vtable +0x08 at `0x6097DD..0x6097F4`;
- draw: `0x609E4D..0x609E63`, on top of all widgets on viewport 0.

App fields:

| Field | Meaning |
|---|---|
| `+0x24` | the loading-screen FlashWidget* |
| `+0x28`, `+0x2C` | two hint widgets, drawn when `+0x39` |
| `+0x30` | "skull spinning" (wipe completed) |
| `+0x38` | "close received" |
| `+0x39` | hints on |
| `+0x34`, `+0x40..+0x58` | hint state, zeroed on reset |

- **Show** `0x60AFA0`, called by loading enter `0x4B98B1`, unloading enter `0x4BB04C` and unloadshell enter `0x4BC5E9`:
  - if it already exists: `+0x38=0`, and if not spinning, restart the movie (`0x61BFE0` = RestartFlash's worker, shared with `0x5BAC12`);
  - otherwise: allocate a FlashWidget (`0x61B0A0`), load SWF **`loadingscreen_standalone`** (`0xBBBD70`, via `0x61BE10`), set fullscreen mode 1 + CorrectForResolution, activate (`vtable +0x60(1)`), play speed `+0x1D0 = 4.0` (`[0xB97744]`).
  - The SWF asset is resolved by name through the Flash loader; the WAD is not named in this path. `%s\loading.wad` is opened at `0x4BFF9D`, which I did not read, so "the SWF comes from Loading.wad" is INFERRED.
- **Flash event handler** `0x60B1C0` (event hash in eax, sender in ecx; caller `0x61C355`):
  - `"wipeComplete"` (`0xB3D66715` = m2) from this widget → speed 1.0, **call AS function `"skullSpin"`** with one bool arg true (`0x61C550`), `+0x30=1`;
  - `"close"` (`0xADEDEF2B`) from this widget → `+0x38=1`; if the widget is gone → reset hints (`0x60B3B0`);
  - `0xB601E741` (name not cracked) → set the hint text to `"SHELL.LoadingHints.ActionLoading"` (`0xBBB9E8`, via `0x60B070`).
- **`Gui.OnGlobalExit()`** `0x5B4C20` → `0x60B290(app)`. If the loading screen exists:
  - **call AS function `"fadeOut"`** with one bool arg true;
  - speed 4.0;
  - `+0x30=0`.

  It returns 0 Lua values. It is also called from unloading exit (`0x4BB164`).
- **Destroy** `0x60B2F0`:
  - `+0x39=0` (hints off); clear the hint text and state; notify `0x608590(0)`;
  - under CS `+0x70`: SWF cleared, re-linked, deleted (vtable+0 with 1), `+0x24=0`;
  - `+0x38=0`, `+0x30=0`.

  Called from:
  - **the app tick when `+0x38` ("close" received) is set** (`0x6097F6..0x609800`);
  - loading update after 2 s if the wipe never completed (`0x4B9B30`);
  - unloading/unloadshell updates (`0x4BB318`, `0x4BC739`);
  - app dtor (`0x60AE5A`).
- **Sequence:**
  1. state enters loading → SWF shows and plays its wipe;
  2. `wipeComplete` → engine starts `skullSpin`;
  3. after 2 s, hints on;
  4. … `Gui.OnGlobalExit` → `fadeOut`;
  5. the SWF fires `close` → destroyed on the next app tick.
- The script-side `mrxgui.lua` fade widget (also `loadingscreen_standalone`) is a separate, script-created Flash widget that goes through the manager. That this is the same SWF used twice is INFERRED from the Lua.

### 6.4 `Net.SetLoadingScreen(b)` `0x5CB450` (PROVEN)

- **If `Net.IsEnabled` (`[0xDFBD74]`) && `Net.IsServer` (`[0xDFBD78]`)**: read the bool (absent → false) and, if `[0x117618C]`, call `0x6F6670(obj, b)`. That replicates a loading-screen state to clients; its body was not read.
- **Always pushes `true`.**
- **In single-player it is a no-op.** It does not touch the engine loading screen of §6.3.

---

## Q7. `Player.SetInputEnabled(player, bEnabled [, bPda])` `0x5DC270` (PROVEN)

**Arguments.**
- arg 1 is a GUID (`0x59FF50`). A missing GUID pushes nil.
- arg 2 is a bool. A missing bool pushes nil and does nothing.
- arg 3 is an optional bool that **defaults to arg 2** (`0x5DC331..0x5DC337`).

**Resolution.** The player is resolved in `Players` (`0xDF9B90`) via `0x423DC0`; not found → `lua_error`.

**Writes (plain byte flags, not counters):**
- `player+0x244 = bEnabled`
- `player+0x245 = bPda`

Returns true.

The player ctor sets both to 1 (`0x6A0020`/`0x6A0027`). The net path clears `+0x244` (`0x6C2858`).

**What `+0x244` gates.** Player input update `0x6A0770` → `0x6A0710`. When `+0x244==0`:
- the per-device button mask is forced so that **the newly-pressed mask `+0x48` is 0** for every controller device on the player (`0x6A0713..0x6A073C`; `ebp=-1` → `new & ~(new & -1) = 0`);
- an outer mask is set to −1 (`0x6A089E..0x6A08AE`);
- the devices' vtable +0x04 update still runs.

**What `+0x245` gates.** The **`TogglePDA`** Lua event (`0xBCDC00`), together with `[0xCFB963]` (`0x6A07F0..0x6A0850`).

**Other consumers.** `0x69BE80` (a per-player action/command routine) returns early when `+0x244==0`.

**NOT DETERMINED:**
- whether analog sticks, and therefore camera look, are masked (only the button-edge mask was read);
- menus: shell/pause menus read input through Flash `SendFlashInput` from Lua, not through this mask (INFERRED).

Lua usage: `mrxstate.lua:105/149` (fade in/out), `mrxtaskobjectiveverify.lua:285` `(…, false, true)` = no input but PDA allowed.

---

## NOT DETERMINED (consolidated)

1. InterpolateWidget arg 19 (`nElapsedTime`) application; arg 18 (`nRotationDirection`) semantics. Next step: `0x61D440` and the stack frame of `0x5B6418..0x5B6446`.
2. Vtable +0x18 (`0x627430`, the rect-delta transform used by interpolation) and how the `(1,1)` / `(0,0)` flag pair treats the far corner and children.
3. *(closed: activation appends at the tail of mgr+0x00, `0x619621`; see §1.5.)*

**Notes for the reimpl, checks rather than facts:**
- **`nil` callbacks in the brief's trace.** The brief records `nil` at InterpolateWidget arg 11 and SetMovieEndCallback arg 2.
  - The shipped Lua passes functions there: `_HandleAnimationComplete` (`mrxguibase.lua:715/717`) and `fCallback` (`mrxguibase.lua:1403-1404`).
  - Retail installs **no** callback when it receives nil, so the fade and movie chains would stall.
  - If the reimpl's binder really sees nil, check the recorder and the function marshalling.
- **The movie quad uses the rect captured at Play.** Play copies the corrected rect into Bink record 0. Later moves or interpolations of the movie widget do not move the movie (movie sub-agent, `0x621AF0..0x621B52`).
4. The `AddWidgetChild` body (`thunk_FUN_024eb070`, SecuROM) and the `ActivateWidget` bool branch (split at `0x618DF5`).
5. What sets app `+0x0C/+0x0D` (the GUI pause used by the manager tick). What viewport `+0x3C` (beyond gating `0x468ED0`), `[0xED1D08]` 1000/850 and `[0x1175A8D]` control. Whether the 3D world renders during `loading`.
6. The anchor branch maths `0x62801D` (only the doc read it).
7. The nil-texture quad render (`0x6179A0` → VM) and the rotation pivot.
8. The name of flash event `0xB601E741`. The body of `0x6F6670` (the network loading-screen replicate).
9. The pad buttons for movie skip ids 1/0x14/6; whether SetInputEnabled masks the analog/camera.
10. The cinematic Update beyond the online branch; the waitforplayer → waitforstreaming path (`0x4B9E40`, doc: polls a count then requests waitforstreaming).
11. **X360 cross-reference caution.**
    - The same VA `0x8231D168` is **AddWidgetChild in x360-preview-final**. In x360-retail, AddWidgetChild is at `0x8231E000` (`corpus_get ghidra/pc-v10/0x005b66e0` translations), so `x360-retail 0x8231D168` may well be SetWidgetVisible; I did not check it.
    - Whatever the X360 slot number is, **the PC SetVisible slot is vtable +0x54**. PC +0x44 is the hover test.
