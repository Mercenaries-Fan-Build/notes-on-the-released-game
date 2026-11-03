## Control option pages (PC v1.0) — add to `docs/reverse_engineer/lti_movie_pda_code_map.md` §3 rows 18–39 and `input_code_map.md` §4

Evidence: disassembly of `output/_ghidra/securom_dump/mercs2_unpacked.exe` (i686 objdump) and bytes of `image.bin`, read 2026-11-02; the AS side from the shell movie's action dump. PROVEN unless marked.

### Invoke helper
`0x0061C550` (stolen 6 bytes, body from `0x0061C559`): `edi` = AS function name, `esi` = movie; stack `push 0; push count; push args`; `movie->vtbl[0x28](name)` then `vtbl[0x48](name, 0, args, count)`; `ret 0xC`. Args are 16 bytes: type at +0 (0 undefined, 2 bool, 3 double, 4 `char*`, 5 `wchar_t*`), value at +8.

### General page
- `LTIInputGeneralEnter` `0x005C1470` Invokes, in order: `LTIInputSetMouseSense((int)((float)(int)(m+0x14 × 50.0f) × 5.0f))`, `LTIInputSetJoySense(clamp((int)((cfg+0x50 − 0.5f) × 20.0f),1,20) × 5.0f)`, `LTIInputSetInvertJoystick(byte 0x00DFC34D)`, `LTIInputSetInvertMouse(m+0x10 != 0)`, `LTIInputSetRumble(byte 0x00DFC351)`, `LTIInputNumberControllers(cfg+0x58)`. `m` = `[0x00ED4574]`, `cfg` = `[0x00ED3B1C]` = `0x014A2860`.
- `LTIInputGeneralOptions` `0x005C1600`: the movie's `ControlsApply` sends `"1&<mouse 0..100>"`, `"2&<1 if mouseInvert else 2>"`, `"3&<joystick 0..100>"`, `"4&<true|false>"`, `"5&<true|false>"`. Split at the first `&`; case = `atoi`.
  - 1: `m+0x14 = clamp((int)(atoi(v) × 0.2f),1,20) × 0.02f`; `FUN_004FD930` writes `[Mouse] InvertY=m+0x10`, `Sensitivity=(int)(m+0x14 × 50.0f)`.
  - 2: `atoi(v)==1` → `m+0x10=1`; `==2` → 0; then `FUN_004FD930`. `m+0x10 == 1` leaves the mouse Y unnegated (`0x004FA6D5`).
  - 3: `n = atoi(v)/5`; `FUN_0082A960` clamps 1..20, stores `n × 0.05f + 0.5f` at cfg+0x50 and per pad at dev+0x32C; `FUN_004FBF20` writes `[Joystick] Invert=(byte cfg+0x1EC9 != 0)`, `Sensitivity`, then `[Actions1]` from cfg+0xEA0.
  - 4: `0x00DFC351 = (v == "true")` (`rep cmpsb`, case-sensitive); `[Joystick] Rumble` via `FUN_0074BB50`.
  - any other: `0x00DFC34D = (v == "true")`; `[Joystick] Invert`.
- Float consequences of those formulas: mouse step 5 saves as 4; joystick step 3 saves as 2.

### Keyboard/mouse remap
- Key ids: `0x00D1E640` (267 names, DirectInput scan codes, `0x100+` mouse, `0x108` MWUP, `0x109` MWDOWN, `0x10A` MWHEEL). Display `0x004FA500`: ids outside `1..=0x10A` give `[0x1033c821]` ("EMPTY").
- Row names: INI keys `0x00D1E440` (25, `Start` last), page names `0x00D1E5D8` (25 string keys), the over-bound question's names `0x00D1E578` (24). Defaults `0x00B9BB98`, 35 × `[primary, alternate]`; PDA default is F1.
- `LTIInputKMEnter` `0x005C1900`: `LTIInputMaxActionBind(24.0, undefined)`; per row 0..23 `LTIInputKMSetActionName(i, D1E5D8[i])`, staging `0x00EDAE60` ← cfg+0xEA0, `LTIInputKMKeyMap(i, false|true, wname)`; `LTIInputKMUpdateTable()`; cfg+0xFC0 = 1.
- `LTIInputKMChangeInput` `0x005C1CC0`: if `byte 0x01175F2E` is clear: `0x00EDAF78 = (int)arg` (row, +100 for the alternate column, as the movie sends it), cfg+0xFC4 (`0x014A3824`) = 1, `0x01175F2E` = 1.
- Capture `0x004FA570`: while `0x014A3824` and `[m+0x18]`, the lowest id 0..0x10A down goes to `0x005C2110`, and the flag clears.
- `0x005C2110(key)`: ESCAPE → `LTIFinishedGettingInput(false)`, done. Else backup `0x00EDAD48` ← staging (0x46 dwords); staging[row][col] = key; scan rows 0..23: a primary match counts (another row records `0x00D14684` row / `0x00D14688` = 0); an alternate match counts unless the primary of the same row also matched, in which case the column not being edited is cleared (`d14688` = 1 for an alternate-only match). Exactly 2 matches → `LTIonlineMsgBox("[0x23641453]", format([0x603e1c7d], keyName, D1E578[other], D1E578[row]), 2.0, "[0xAF4B6E11]", "[0xC9A7EABD]", 1.0)` and `0x00D1467C` row, `0x00D14680` column, `0x00D1468C` key. Otherwise `LTIInputKMKeyMap` for both columns of the row. Then `LTIFinishedGettingInput(key == ENTER || key == SPACE)`; `0x01175F2E` = 0. The format is virtualised (`0x005C5950`); its inputs are proven.
- `LTIOverBoundResponse` `0x005C2730`: nothing unless all five `0x00D1467C..0x00D1468C` are set; arg read as an integer; 1 → staging[row][col] = key, staging[other][otherCol] = 0; else staging[row][col] = backup. Then `LTIInputKMKeyMap` × 48, `LTIFinishedGettingInput(false)`, the five reset to -1.
- `LTIInputKMApplyChanges` `0x005C1D00`: cfg+0xEA0 rows 0..23 ← staging, row 31 ← row 14; `FUN_004FBBA0(cfg)` (virtualised; its relocated copy at `0x006D4890` runs `FUN_004FB890` then writes `[Actions1]`/`[Actions2]`).
- `FUN_004FB890` conflict resolver: ESCAPE comes off every action; for each (column, row) then each other (column, row): equal ids, or MWHEEL against MWUP/MWDOWN, clear the later column's (or, same column, the other's) entry; changed → rows 24..34 re-forced, row 31 = row 14.
- `LTIInputKMCancelInput` `0x005C2720`: `0x01175F2E` = 0, `0x00EDAF78` = 0. `LTIInputKMExit` `0x005C2950`: cfg+0xFC0 = 0.

### Server page
`PauseItemChanged serverEnter` (`0x005C4DAA`) Invokes `serverFriendlyFire((double)byte 0x00DFC365)`; `serverFriendlyFireVar=<v>` sets `0x00DFC365 = (_stricmp(v,"true") == 0)`, no INI write.

### Joystick remap
- Device k at cfg+0x5C+k×0x390: name +0x238 (its INI section), layout +0x340, XInput index +0x358, dead zone byte +0x344 (always 0x28, set at `0x00828646`/`0x008289D2`), binds +0x374 (25 slot bytes); count cfg+0x58; every handler uses device 0. Row → slot `B92A10[B9BCB0[row]]`.
- Vocabulary `0x00CF2560` (54 INI names; 53 = EMPTY), display keys `0x00CF2638` (index 14 reuses 10's pointer). With an XInput index, 8/9 show `[0x83ecba77]`/`[0x32694dd8]` (Left/Right Trigger) (`0x0082A900`; readable copy of `0x004FBA40` at `0x004D4640`).
- Layouts `0x00CF2720` (10 × 25, by slot); `(vendor, product)` table `0x00CF2840` picks 0..8, an unlisted XInput pad gets 9.
- Reader `FUN_004FBD40`: each of the 25 `D1E440` keys from `[<device name>]`, default the layout's input; `_stricmp` over the 54 names; then later duplicates by slot → EMPTY.
- Writer (body at `0x02478750`, behind `0x004FBC60`; link INFERRED): device 0 only, the same de-dup, then 25 keys via `0x0074BA90`. No Sensitivity or Invert.
- `LTIInputJoystickEnter` `0x005C2970`: `LTIInputMaxActionBind(25.0, undefined)`, cfg+0xFC8 = cfg+0x54 = 1, `LTIInputNumberControllers(n)`; with pads: `LTIInputControllerNames(k, name)`, per row `LTIInputKMSetActionName(i, D1E5D8[i])`, staging `0x00EDAD28` ← binds, `LTIInputJoystickMap(i, display)`; without: Default; then `LTIInputJoystickUpdateTable()`.
- `ChangePrimary` `0x005C2CB0` → `0x005C04C0` (VM, not read) then re-shows device 0's binds. `ChangeInput` `0x005C2E50`: row → `0x00EDAF78`, `0x01175F2E` = 1.
- Per frame `FUN_004FB270` (pad 0, while cfg+0xFC8): if waiting, `0x0082A2A0` lists up to 6 held inputs (sticks: high byte of the magnitude ≥ 41 after the dead-zone rescale; triggers > 0x10; then Y, A, X, B, LT, LB, LS, RT, RB, RS, Start, Back, Up, Right, Down, Left) → `0x005C2E80(buf, n, pad's Jump-slot input active)`; then `LTIInputSeeButtonsPushed(<display keys joined ", ">)` every frame.
- `0x005C2E80`: backup → `0x00EDAD0C`. One input: staging[row] = it; `0x0082A820` lists row pairs holding the same input; none → `LTIInputJoystickMap(row, name)`, `LTIFinishedGettingJoystickInput(confirm)`; else `LTIonlineMsgBox("[0x764469fd]", "[0x603e1c7d:<input>:<owner>:<edited>]", 2.0, YES, NO, 2.0)`. More than one: `LTIonlineMsgBox("[0x045ff684]","[0x645dd0c7]",1.0,"[0x96673ef8]","",0.0)`, staging restored, `LTIFinishedGettingInput(false)`.
- `LTIJoystickOverBoundResponse` `0x005C3200`: 1 → the row that kept its input becomes EMPTY, `LTIInputJoystickMap` × 25; else staging restored; `LTIFinishedGettingJoystickInput(false)`.
- Apply `0x005C33F0`: device 0's binds ← staging; the writer; cfg+0xFC8 = cfg+0x54 = 0. Default `0x005C3500`: staging ← layout. Exit/ReEnter set cfg+0xFC8/+0x54 to 0/1.
- `0x014A3846` (cfg+0xFE6) is pad 0's per-frame value for slot 2 (Jump): its edges send `LTITextInputEnterButton` / `LTITextReleaseEnterButton` (`0x004FA819`).
