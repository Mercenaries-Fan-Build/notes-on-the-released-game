---
title: Double-blind validation — hud_widget_code_map.md
date: 2026-07-26
status: current
evidence: proven
subject: docs/reverse_engineer/hud_widget_code_map.md
method: Phase A derived from primary sources with the map unopened; Phase B compares.
---

# Double-blind validation — `docs/reverse_engineer/hud_widget_code_map.md`

**Primary sources.** Everything in Phase A was read out of the raw unpacked image
`output/_ghidra/securom_dump/mercs2_unpacked.exe` with capstone, VA→file offset resolved through the
PE section table (RVA != raw here: `.text` VA `0x00401000` → raw `0x00001000`, `.rdata` VA
`0x00B05000` → raw `0x00705000`, `.data` VA `0x00BF6000` → raw `0x007F6000`).
Secondary: `output/_ghidra/mercs2_unpacked.exe_decomp.txt` (used **only** to measure which bodies it
contains), `docs/mercs2-luacd/src/` (370 scripts), `mods/lua_trace_asi/reference/binding_map.json`
(names/VAs only), `docs/mercs2-pdb-analysis/gui-hud.md`.
Throwaway scripts live in the session scratchpad (`hudval/pe.py`, `registry.py`, `dumpreg.py`,
`coverage.py`, `typetag.py`, `callers.py`, `xref.py`).

**Headline.** This map is unusually accurate. Every mechanically checkable column — 152 names, 152
VAs, 152 decompiled/binding-only markers, 152 call counts, both totals — is **exactly right**. It
also correctly identifies two shipped defects and correctly refutes a sibling map. It has **one
serious error**: it puts the widget *location* rect at `widget+0x50`, which is the *colour* block.

---

## Phase A — independent findings (written before reading the map)

### A1. The namespace registry — both table names walked from `.data`

Registry at VA `0x00DFD478`, 31 rows × 12 B `{const char* name, luaL_Reg* funcs, const char* post_chunk}`,
zero row at `0x00DFD5EC` (`0xDFD5EC − 0xDFD478 = 0x174 = 31 × 12`). Full walk:

| # | row VA | name | luaL_Reg | third column |
|---|--------|------|----------|--------------|
| 0 | 0x00DFD478 | `_SYS` | 0x00B9A854 | 0x00BB4EE0 |
| 1 | 0x00DFD484 | `Sys` | 0x00B98A78 | 0x00BBA438 |
| 2 | 0x00DFD490 | `Pg` | 0x00B99328 | 0x00BB8E60 |
| 3 | 0x00DFD49C | `Object` | 0x00B99608 | NULL |
| 4 | 0x00DFD4A8 | `Player` | 0x00B98FC0 | NULL |
| 5 | 0x00DFD4B4 | `Event` | 0x00B987F8 | NULL |
| 6 | 0x00DFD4C0 | `Ai` | 0x00B9A938 | 0x00BA8B09 (`""`) |
| 7 | 0x00DFD4CC | `Human` | 0x00B99EF0 | `""` |
| 8 | 0x00DFD4D8 | `Debug` | 0x00B98828 | 0x00BBAA8C |
| 9 | 0x00DFD4E4 | `Vehicle` | 0x00B98918 | NULL |
| 10 | 0x00DFD4F0 | `Airstrike` | 0x00B9A8C8 | `""` |
| **11** | **0x00DFD4FC** | **`Gui`** | **0x00B9A398** | **0x00BB59D8** |
| **12** | **0x00DFD508** | **`_GuiInternal`** | **0x00B99FF8** | **0x00BB65C8** |
| 13 | 0x00DFD514 | `Graphics` | 0x00B9A4D0 | NULL |
| 14 | 0x00DFD520 | `Sound` | 0x00B98C98 | NULL |
| 15 | 0x00DFD52C | `ObjectFilter` | 0x00B98770 | 0x00BBB6D0 |
| 16 | 0x00DFD538 | `Net` | 0x00B998D0 | `""` |
| 17 | 0x00DFD544 | `math` | 0x00B99BE8 | 0x00BB78E0 |
| 18 | 0x00DFD550 | `Camera` | 0x00B9A7D8 | NULL |
| 19 | 0x00DFD55C | `Junk` | 0x00B99E28 | NULL |
| 20 | 0x00DFD568 | `ObjectState` | 0x00B995B0 | `""` |
| 21 | 0x00DFD574 | `Movie` | 0x00B99BBC | `""` |
| 22 | 0x00DFD580 | `Animation` | 0x00B9A88C | NULL |
| 23 | 0x00DFD58C | `VO` | 0x00B988B0 | 0x00BBA910 |
| 24 | 0x00DFD598 | `Weapon` | 0x00B98860 | NULL |
| 25 | 0x00DFD5A4 | `String` | 0x00B98C88 | NULL |
| 26 | 0x00DFD5B0 | `Table` | 0x00B98A60 | NULL |
| 27 | 0x00DFD5BC | `Report` | 0x00B98F64 | `""` |
| 28 | 0x00DFD5C8 | `Disguise` | 0x00B98F94 | `""` |
| 29 | 0x00DFD5D4 | `FactionZone` | 0x00B98FA4 | `""` |
| 30 | 0x00DFD5E0 | `LTILibName` | 0x00B99C78 | `""` |

* **A1a.** `0x00B99FF8` registers as **`_GuiInternal`** (row 12).
* **A1b.** `0x00B9A398` registers as **`Gui`** (row 11).
* **A1c.** There is **no `Hud` row** in the 31-row registry.
* **A1d.** `Hud` *is* a real Lua global: `docs/mercs2-luacd/src/resident/mrxguiinterface.lua:12-13`
  → `HudInterface = {}` / `_G.Hud = HudInterface`. A pure-Lua table, not a binding table.

### A2. The third column is a Lua source chunk executed after registration

The only references to `0x00DFD478` in `.text` are inside `FUN_005A2C40` (`0x005A2D3A`, `0x005A2D49`,
`0x005A2DED`, `0x005A2DF3`). Its loop:

```
005A2D50  mov  eax, [edi]                 ; row.name
005A2D53  mov  eax, [esi + 0xdfd47c]      ; row.luaL_Reg
005A2D5B  call 0x5a2fd0                   ; register namespace (SecuROM split thunk -> jmp [0x2458a68])
005A2D62  je   0x5a2dd9                   ; registration failed -> next row
005A2D64  mov  esi, [esi + 0xdfd480]      ; row.third
005A2D6C  je   0x5a2dd9                   ; NULL -> next row
005A2D75  ...                             ; inline strlen(third)
005A2D84  mov  edi, 0xbaa594              ; chunkname fallback if row.name is NULL
005A2D90  call 0x860240                   ; load buffer (reader 0x860220 -> lua_load 0x868cc0)
005A2DB2  call 0x85df50                   ; pcall(0 args, 0 results)
```

* **A2a.** The third column is a **Lua source chunk**, loaded with the namespace name as its chunk
  name and `pcall`ed with 0 args / 0 results, **immediately after** that namespace's table is
  registered. Rows pointing at `0x00BA8B09` point at a shared empty string.
* **A2b.** `Gui`'s chunk (`0x00BB59D8`, 745 bytes) creates `_G.Marker` and aliases **13**
  `Gui._Marker*` cfuncs into it (`Add`→`_MarkerAddOld`, `AddBlip`→`_MarkerAdd`, `AddTripwire`,
  `AddDisc`, `Add3D`, `Remove`, `SetGroupedBlipLimit`→`_MarkerSetBlipLimit`, `SetLocation`,
  `SetColor`, `SetFollowGuid`, `SetScale`, `Pulse`, `HaltPulse`). `Marker` is **`_G` sugar**, not a
  binding table, and has no registry row.
* **A2c.** `_GuiInternal`'s chunk (`0x00BB65C8`) is the single line `_GuiInternal.nVersion = 2`.
* **A2d.** A separate helper `FUN_005A2E40` counts `luaL_Reg` entries treating `func == -1` as
  "open sub-table" and `func == -2` as "close". **Neither GUI table uses it** — both are flat.

### A3. Table contents — 114 + 38, all bodies readable from the raw image

* `_GuiInternal` @ `0x00B99FF8`: **114** cfuncs, 0 sub-tables, terminator `0x00B9A388`.
* `Gui` @ `0x00B9A398`: **38** cfuncs, 0 sub-tables, terminator `0x00B9A4C8`.

All 152 targets are in `.text` and every one disassembles directly — **none is a SecuROM split
thunk**, so 152/152 bodies are readable today with capstone.

Ghidra export coverage is a different number:

| table | cfuncs | present in `mercs2_unpacked.exe_decomp.txt` | absent |
|---|---|---|---|
| `_GuiInternal` | 114 | **47** | **67** |
| `Gui` | 38 | **23** | **15** |
| total | 152 | 70 | 82 |

`binding_map.json` independently agrees on 114 / 38 and on every name→VA pair; its only
classification column is `group`, which reads `"game"` for both and carries no namespace info.

### A4. Widget class family, object layout, and the type tag

Exactly **six** functions call the base ctor `0x00626DA0` directly (`CreateWidget` plus five subclass
ctors); the seventh class, Sprite, calls the **Image** ctor. Sizes come from the `push` in each binder:

| class | binder | alloc | ctor | vtable | tag `+0x10` |
|---|---|---|---|---|---|
| base widget | `CreateWidget` `0x005B4E80` | `0x130` | `0x00626DA0` | `0x00BBCEE8` | **0** |
| image | `CreateImageWidget` `0x005B7070` | `0x1C0` | `0x0061CF90` | `0x00BBC878` | **1** |
| text | `CreateTextWidget` `0x005B7D40` | `0x170` | `0x00622380` | `0x00BBCE68` | **2** |
| minimap | `MinimapCreate` `0x005B8CB0` | `0x1020` | `0x0061F720` | `0x00BBC968` | **3** |
| movie | `CreateMovieWidget` `0x005BC1A0` | `0x150` | `0x00621D80` | `0x00BBC9E8` | **4** |
| flash | `CreateFlashWidget` `0x005BA680` | `0x4C0` | `0x0061B0A0` | `0x00BBC7F8` | **6** |
| sprite | `CreateSpriteWidget` `0x005BB7B0` | `0x200` | `0x00621EC0` | `0x00BBCA68` | **7** |

Tag stores: `00626DB5` (0) · `0061CFD6` (1) · `006223D1` (2) · `0061F977` (3) · `00621DBB` (4) ·
`0061B12F` (6) · `00621F64` (7).

* **A4a — tag 5 unassigned.** A regex sweep of `.text` for `mov dword [reg+0x10], imm32` finds five
  sites writing 5 (`0x005756DD`, `0x0058159E`, `0x006CB452`, `0x006CB8DA`, `0x009DDCE0`), none in the
  widget cluster. The class set is closed by the six direct callers of `0x00626DA0` + Sprite, so **no
  widget class carries tag 5**.
* **A4b — Sprite derives from Image.** `00621EC0 call 0x61cf90` is Sprite's first instruction; Sprite's
  vtable shares Image's `+0x04` slot (`0x0061D070`) and its own fields start at `+0x1C0`, exactly where
  Image's stop (`0061D065 mov byte [eax+0x1b8], cl`).
* **A4c — the Lua handle is a slot index pushed as lightuserdata.** Manager is `[[0x01175FB0]+0x68]`;
  slots `+0x44`, capacity `+0x4C`, next-free `+0x48`. `CreateWidget` scans `slots[0..cap)` for NULL,
  writes the index to `[widget+0x18]`, and pushes it with `tt = 2`
  (`005B4EFC mov [eax], ebx / mov [eax+4], 2`). **`tt` 2 = `LUA_TLIGHTUSERDATA`** — cross-checked
  against the same value set used elsewhere in this build: `0x0059F780` (get-number) accepts
  `tt == 3` (number) and `tt == 4` (string), `0x0059DAD0` pushes floats as `tt = 3`, and
  `AddPdaMapBlips` tests `tt == 5` for a table. Lua's canonical ordering (NIL 0, BOOLEAN 1,
  LIGHTUSERDATA 2, NUMBER 3, STRING 4, TABLE 5) fits all four observations.

**Base-widget field map**, recovered from the ctor and from the one-instruction vtable leaves:

| offset | meaning | proof |
|---|---|---|
| `+0x00` | vtable | ctor |
| `+0x10` | **type tag** | table above |
| `+0x14`, `+0x15` | flags; `+0x15` = **highlightable** | vtbl `+0x38`/`+0x3C` = `0x0061AFD0`/`0x0061AFE0` → `[ecx+0x15]` |
| `+0x18` | slot id (ctor inits `-1`) | `005B4ED7 mov [esi+0x18], ebx` |
| `+0x20` | **visible** | vtbl `+0x54`/`+0x58` = `0x00627700`/`0x0061B000` → `[ecx+0x20]`; `Get/SetWidgetVisible` call those slots |
| `+0x21` | **sleep** | vtbl `+0x68`/`+0x6C` = `0x00627BB0`/`0x0061B040` → `[ecx+0x21]`; `GetWidgetSleep` calls `+0x6C` |
| **`+0x30..+0x3C`** | **location RECT (x1,y1,x2,y2)**, ctor-init **0,0,0,0** | vtbl `+0x1C` = `0x0061AF80` → `lea eax,[ecx+0x30]; ret`; ctor `00626E84 movq [eax+0x30], xmm1(0)` |
| `+0x40..+0x4C` | corrected/second rect, ctor-init 0 | vtbl `+0x24` = `0x0061AF90` writes 4 floats at `[ecx+0x40]`; ctor `00626E89` |
| **`+0x50..+0x5C`** | **colour RGBA (0..1)**, ctor-init **1,1,1,1** | vtbl `+0x4C` = `0x0061AFF0` → `lea eax,[ecx+0x50]; ret`; SetColor impl `0x00627620` writes `+0x50..+0x5C`; ctor `00626ED0/00626EDB movq [eax+0x50]/[eax+0x58], 1.0` |
| `+0x60`, `+0x63` | flags; `+0x63` has vtbl `+0x60`/`+0x64` accessors | `0x0061B020`/`0x0061B030` |
| `+0x6C` / `+0x70` | horizontal / vertical **anchor** | `SetWidgetAnchoring` writes both |
| `+0xE4` | refcount, `++` by the Flash (`0061B223`) and Movie (`00621D8A`) ctors | ctors |
| `+0xF0` | child list head, self-linked | `00626E16 lea edx,[eax+0xf0]; mov [edx+4],edx; mov [edx],edx` |
| `+0x124` | global widget-list node `{next, prev, owner}` | `00626E69 lea edx,[eax+0x124]`, spliced onto `0x00DF6AC0/4` |
| `+0x130` | end of base object | alloc size |

Also `00626F38 add dword [0xdf6acc], 1` — a live widget counter.

Width/height are **derived, not stored**: vtbl `+0x30` = `0x0061AFB0` → `[ecx+0x38] − [ecx+0x30]`;
vtbl `+0x34` = `0x0061AFC0` → `[ecx+0x3C] − [ecx+0x34]`.

* **A4d.** Location (`+0x30`) and colour (`+0x50`) are two different 4-float blocks with two
  different vtable accessors. The ctor defaults settle which is which on their own: a rect of
  `(0,0,0,0)` and a colour of `(1,1,1,1)` = opaque white are both sensible; the reverse is not.

### A5. `SetWidgetLocation` / `GetWidgetLocation`

`SetWidgetLocation` `0x005B4FA0`:

1. Shared prologue: arg 1 as int; `id < 0` → error; `id > mgr->[0x4C]` → error; `slots[id] == NULL` → error.
2. `mov eax,[edx+0x1c]; call eax` — fetch the current rect pointer, copy **four** floats
   (`movq [eax]` + `movq [eax+8]`).
3. Args 2..5 as optional floats via `0x0059F780`; each absent one falls back to the current value.
4. Presence algebra in `bl`: `present(x1) & present(y1)` (`005B5097`, `005B50C9`), then
   `&= !present(x2)` (`005B50F6 test al,al; sete cl; and bl,cl`), then `&= !present(y2)` (`005B5123`).
5. Arg 6 optional bool via `0x0059F6D0`, defaulting to **true** (`005B513C mov byte [esp+0x18], 1`).
6. `if (bl)` → vtbl **`+0x14`** (`005B5155`) with a 2-float point + flag; `else` → vtbl **`+0x10`**
   (`005B5181`) with the 4-float rect + flag. Returns 0 values.

* **A5a.** The `+0x14` path requires x1 **and** y1 present **and** x2 **and** y2 both absent.
* **A5b — what the two virtuals do.** Base `+0x10` = `0x00627360` overwrites all four floats
  (`movq [esi+0x30]`, `movq [esi+0x38]`) — an absolute **SetRect**. Base `+0x14` = `0x00627270`
  computes `delta = arg − [esi+0x30]` and applies it to `+0x30`/`+0x34` only, leaving `+0x38`/`+0x3C`
  untouched — a **move that preserves the existing size**. Both propagate the delta to children
  through `+0xF0` when the flag is set.
* **A5c.** `GetWidgetLocation` `0x005B51A0` tail-calls `0x0059DAD0`, which pushes `[edi]`, `[edi+4]`,
  `[edi+8]`, `[edi+0xC]` as four `tt = 3` numbers and returns `eax = 4`. **Four values.**
  Corroborated at `mrxguibase.lua:755`:
  `local nX1, nY1, nX2, nY2 = _GuiInternal.GetWidgetLocation(self.BasicData.uId)`.

### A6. Colour contract

`SetWidgetColor` `0x005B5560`: four optional floats, absent-arg default `[0x00BEB2E4]` = **`-255.0`**;
`bl` is an **OR** of presence, so all-absent returns without calling; the four values are scaled by
`[0x00BAC8BC]` = **`0.003921568859368563` = 1/255** and passed to vtbl `+0x48`.

Base `+0x48` = `0x00627620`:

```
00627628  movss xmm1, [edi]        ; r
0062762C  comiss xmm1, xmm0        ; xmm0 = 0.0
0062762F  jb   0x627636            ; r < 0  ->  SKIP the store
00627631  movss [ecx + 0x50], xmm1
   ... identical for +0x54 (g), +0x58 (b), +0x5C (a)
```

* **A6a.** The "leave unchanged" rule is **`value < 0.0` → skip the store**, a sign test, not an
  equality test against `-255`. `-255 × 1/255 = -1.0`. A NaN is also skipped (`comiss` unordered → CF).
* **A6b.** `GetWidgetColor` `0x005B5750` reads vtbl `+0x4C` (`this+0x50`), multiplies each channel by
  `[0x00BEA9C0]` = **255.0**, pushes four floats via `0x0059DAD0`.

Corroborated at `mrxguibase.lua:784`:
`_GuiInternal.SetWidgetColor(self.BasicData.uId, -255, -255, -255, level, ...)` — an alpha-only set.

### A7. Shipped defect #1 — `Gui.ShowLoadingHints` is a one-way switch

`0x005B4C30`, complete body:

```
005B4C49  call 0x59f6d0            ; optional bool -> [esp+0x10]
005B4C50  jg   0x5b4c5a            ; arg present
005B4C52  mov  al, 1               ; ABSENT: default true
005B4C58  jmp  0x5b4c62            ; ...and fall into the write
005B4C5A  mov  al, [esp+0x10]      ; PRESENT
005B4C5E  test al, al
005B4C60  je   0x5b4c86            ; <<<< false -> EXIT, write skipped
005B4C62  mov  ecx, [0x1175fb0]
005B4C68  mov  [ecx + 0x39], al    ; the only write of the flag
005B4C6B  cmp  byte [0xdf67f4], 0
005B4C74..005B4C81                 ; secondary notify -> call 0x608590
005B4C86  pop edi / xor eax,eax / pop esi / pop ecx / ret
```

**Finding A7.** Confirmed. `true` and omitted both write `[gui+0x39] = 1`; `false` branches to the
epilogue **before** the store and before `0x00608590`. The flag can never be cleared.

### A8. Shipped defect #2 — `AddPdaMapBlips` dereferences NULL

`0x005BCE70`:

```
005BCECB  mov  ecx, [esp+0x30]        ; widget id
005BCED9  jl   0x5bcee8               ; id < 0    -> fail
005BCEDB  cmp  ecx, [eax+0x4c]        ; capacity
005BCEDE  jg   0x5bcee8               ; id > cap  -> fail
005BCEE3  mov  eax, [edx+ecx*4]       ; slot (NO null check)
005BCEE6  jmp  0x5bceea
005BCEE8  xor  eax, eax               ; FAIL PATH -> eax = NULL
005BCEEF  cmp  dword [eax + 0x10], 6  ; <<<< NULL DEREF, faults reading 0x00000010
```

* **A8a.** Both failure modes reach `0x005BCEEF` with `eax = 0`: the range check failing, **and** the
  range check passing on a slot that holds NULL (a deleted widget). `AddPdaMapBlips` is the only
  widget binder I read that omits the `test ecx,ecx / jne` null check that `SetWidgetLocation`
  (`0x005B5018`), `GetWidgetLocation` (`0x005B520F`), `SetWidgetColor` (`0x005B55D8`), `DeleteWidget`
  (`0x005B4F89`), `GetWidgetVisible` (`0x005B598F`), `GetWidgetSleep` (`0x005B5D4F`) and the rest all
  perform.
* **A8b.** `cmp ecx,[eax+0x4C]; jg` accepts `id == capacity`. The array is 0-based (`CreateWidget`
  scans `i = 0 .. cap-1` and returns that `i` as the handle), so `slots[cap]` is one past the buffer.
  The identical `jg` appears in the prologue of every widget binder I disassembled.

### A9. `SetPlayerPDAWidget`

`0x005BA500`: arg 1 is a **player handle** (`0x0059FF50`), resolved through the container rooted at
`0x00DF9B90` (`call 0x6496b0`, then the page/mask/shift/stride walk over `0x00DF9BD8`, `0x00DF9BB0`,
`0x00DF9BB4`, `0x00DF9BB6`, `0x00DF9C00`); arg 2 is the widget id; then
`005BA5E1 mov [ecx + 0x390], eax` and `005BA5EB mov [0x1176120], ecx`. Widget-type validation
(`cmp [eax+0x10], 6`) happens **after** the store.

* **A9a.** `0x00DF9B90` is provably the *player* container: 25 of the 107 `Player.*` binders
  (`GetCharacter`, `GetControlledObject`, `GetSeat`, `GetName`, `GetCamera`, `SetPDAMapMode`, …)
  reference the same global in their first 900 bytes.
* **A9b.** The value written is the widget **id**, and a call that goes on to fail validation has
  already mutated `playerObj+0x390`.

### A10. Flash binders vs the Ghidra export

Of the 15 Flash-named binders in `_GuiInternal`, **eight** are absent from
`mercs2_unpacked.exe_decomp.txt`: `SetFlashPlaySpeed` `0x005BA850`, `GetFlashPlaySpeed` `0x005BA930`,
`PauseFlash` `0x005BA9F0`, `PlayFlash` `0x005BAAB0`, `RestartFlash` `0x005BAB70`,
`SetFlashTesselationAllowed` `0x005BB0A0`, `SetFlashPauseMenu` `0x005BB4E0`,
`RemoveFlashPauseMenu` `0x005BB6F0`.

`CreateFlashWidget`, `SetFlashSwfFile`, `SendFlashInput`, `SetFlashCallback` and
`CallFlashScriptFunction` are all **present** (e.g. `==== FUN_005ba680 @0x005ba680 size=146 ====`,
`==== FUN_005bb170 @0x005bb170 size=662 ====`).

### A11. Real per-namespace script call counts (`docs/mercs2-luacd/src/`, 370 files)

Regex `(?<![\w.])(NAME)\.([A-Za-z_]\w*)`:

| namespace | matches | distinct members | files |
|---|---|---|---|
| `_GuiInternal` | 341 | 112 | 16 |
| `Gui` | 72 | 15 | 18 |
| `Marker` (`_G` sugar) | 51 | 8 | 14 |
| `Hud` (Lua `HudInterface`) | 248 | 20 | 57 |

Two of the 341 `_GuiInternal` matches are `_GuiInternal.nVersion`, which is **not a cfunc**, so the
**cfunc** call-site total is **339**.

Never called from script: `_GuiInternal.GetWidgetHighlightable`, `.GetTextWrapping`,
`.SetMinimapRadius` (3 of 114). In `Gui`, 23 of 38 are never called directly, including **all 13
`_Marker*`** — script reaches them only through the `Marker.*` aliases.

### A12. What Phase A did *not* establish

* I read ~35 of the 152 bodies in full. The other ~117 are readable but unread.
* Both defects are proven **statically**; neither was observed at runtime.
* `0x005A2FD0` (register-namespace) and `0x00619C00` (array grow) are SecuROM split thunks; I read
  their call sites, not their bodies.
* I did not decode the `0x1020`-byte minimap object beyond its tag, vtable, and asset hashes.

> **Phase A corrigenda.** Two Phase-A statements were wrong when first drafted and are corrected
> above, both against the map's favour being irrelevant — they were my errors, found while checking
> the map: (i) I first read `tt = 2` as "integer"; it is `LUA_TLIGHTUSERDATA` (A4c). (ii) I first
> reported 341 cfunc call sites; the correct cfunc figure is 339, because two matches are
> `nVersion` (A11).

---

## Phase B — verdicts

### Summary counts

| verdict | count |
|---|---|
| **CONFIRMED** | 44 |
| **CONTRADICTED** | 4 |
| **OVERSTATED** | 3 |
| **UNVERIFIABLE** | 2 |
| **MISSING** (found by me, absent from the map) | 7 |

### CONFIRMED (44)

**Naming and the registry (9)**

| # | Map claim | Reproduced by |
|---|---|---|
| B1 | `0x00B99FF8` installs as `_GuiInternal`, not `Hud`; `[0x00DFD508] → 0x00BB65E4` | A1a |
| B2 | `0x00B9A398` installs as `Gui`; `[0x00DFD4FC] → 0x00BB5CC4` | A1b |
| B3 | There is no `Hud` row | A1c |
| B4 | `Hud` is Lua-defined (`_G.Hud = HudInterface`, `mrxguiinterface.lua:13`) and would collide | A1d |
| B5 | Registry is 31 rows × 12 B `{name, table, bootLua}` at `0x00DFD478`, zero-terminated at `0x00DFD5EC` | A1 — row-for-row, in the map's stated order |
| B6 | The third column is a Lua chunk run immediately after the table registers | A2a |
| B7 | `Gui`'s boot chunk installs `_G.Marker` with 13 aliases — verbatim transcription is correct | A2b |
| B8 | `Marker.Add` maps to the **legacy** `_MarkerAddOld`, `Marker.AddBlip` to the current `_MarkerAdd` | A2b |
| B9 | `_GuiInternal.nVersion = 2` is the boot chunk at `0x00BB65C8` | A2c |

**The two tables, mechanically audited (7)** — I parsed the map's §4 and §5 tables and diffed every
cell against the binary and the script corpus:

| # | Map claim | Result |
|---|---|---|
| B10 | 114 rows in `_GuiInternal`, 38 in `Gui` | exact |
| B11 | All 114 `name → VA` pairs | **0 errors** |
| B12 | All 38 `name → VA` pairs | **0 errors** |
| B13 | ⬤/○ column: 47 decompiled / 67 binding-only in `_GuiInternal` | **0 errors** against the export headers |
| B14 | ⬤/○ column: 23 / 15 in `Gui` | **0 errors** |
| B15 | Per-row call counts, all 152 rows | **0 errors**; sums **339** and **72** |
| B16 | "only 3 of 114 are never called" — `GetWidgetHighlightable`, `GetTextWrapping`, `SetMinimapRadius`; the 13 `_Marker*` show 0 direct calls against `Marker.*` ×51 | exact (A11) |

> The map's `339` is the figure I initially disputed at `341`. **The map is right**: the extra two
> are `_GuiInternal.nVersion`, which is not a cfunc. Its §9.9 note reconciling `266` vs `339` against
> `lua_engine_bindings_audit.md` is also methodologically sound.

**The shared prologue and the manager (4)**

| # | Map claim | Reproduced by |
|---|---|---|
| B17 | Manager at `*(DAT_01175FB0 + 0x68)`; slots `+0x44`, capacity `+0x4C`, grow-count `+0x48` | A4c |
| B18 | Prologue is `id<0 \|\| cap<id` → nil, then `!w` → nil, then optional tag gate, then vtable dispatch — identical across the table | A5, A8, and every accessor in A4 |
| B19 | uId is a **reused dense slot index pushed as lightuserdata (Lua tag 2)**, stored back at `widget+0x18` | A4c — *and this corrected my own first reading* |
| B20 | An unknown uId yields `nil`, not an error | A5/A8 — every failure path does `push nil; return 1` |

**The class family (7)**

| # | Map claim | Reproduced by |
|---|---|---|
| B21 | Class table: ctors, vtables, alloc sizes, tags for all seven rows | A4 — every cell matches |
| B22 | `SpriteWidget` derives from `ImageWidget` (ctor chains `FUN_0061CF90`) | A4b |
| B23 | Tag 5 is unassigned | A4a |
| B24 | `MinimapCreate` is binding-only and the minimap ctor's sole caller `0x005B8E9C` lies inside it | A3 coverage + `callers.py` |
| B25 | `TextWidget` seeds asset hash `0x339761F4` | `006223C1 mov [esi+0x138], 0x339761F4` |
| B26 | `MinimapWidget` registers `0x59D0F617` and `0x6FD35750`, and zeroes a `0xC0`-dword block at `+0x4E4` | `0061F831 push 0x59d0f617`, `0061F849 push 0x6fd35750`, `0061F74E lea edi,[esi+0x4e4]; mov ecx,0xc0` |
| B27 | `_DAT_00DF6ACC` is the live widget count, `++` in the base ctor; global list node at `+0x124`; `+0xE4` `++` by the Flash and Movie ctors | `00626F38`, `00626E69`, `0061B223`, `00621D8A` |

**Location, colour, anchoring (6)**

| # | Map claim | Reproduced by |
|---|---|---|
| B28 | Location is a **4-float RECT** and `SetWidgetLocation` reads the current one first (16 bytes via vtbl `+0x1C`) | A5 |
| B29 | Dispatch `if (a1 && a2 && !a3 && !a4) → vtbl+0x14 else → vtbl+0x10` | A5a — the presence algebra is byte-for-byte what the map states |
| B30 | `GetWidgetLocation` returns four values | A5c |
| B31 | Trailing boolean = propagate-to-children, default **true** | A5 step 5 |
| B32 | Colour: absent-arg default `DAT_00BEB2E4 = -255.0`, scale `DAT_00BAC8BC = 1/255`, vtbl `+0x48` called only if ≥1 channel supplied | A6 |
| B33 | Anchoring buckets against `-0.5`/`+0.5` into `+0x6C` (0/2/1) and `+0x70` (3/2/4) | `005B5F30`–`005B5FC3`; the map marked this **M**, the values are **H** |

**Individual bodies (7)**

| # | Map claim | Reproduced by |
|---|---|---|
| B34 | **`ShowLoadingHints(false)` is a no-op — a one-way switch** | A7, instruction-exact |
| B35 | **`AddPdaMapBlips` dereferences a null widget; "a read of address `0x10` → AV"** | A8a — faults at `0x005BCEEF` |
| B36 | **The `cap < id` off-by-one, correctly scoped to *every* widget cfunc** | A8b — the map does **not** limit this to `AddPdaMapBlips`, contrary to how the claim was put to me |
| B37 | `AddPdaMapBlips` requires arg 2 to be a Lua **table (tag 5)** and uses the branchless `((tag != 6) − 1) & widget` idiom | `005BCF23 cmp edx,5; jne`, `005BCEF3 setne bl; sub ebx,esi; and ebx,eax` |
| B38 | `SetPlayerPDAWidget` runs the player-container walk verbatim and writes `playerObj + 0x390`, caching in `DAT_01176120` | A9, A9a |
| B39 | `GetReticlePosition` discards its argument and returns the constants `0` and `DAT_00BBC7EC = 0.25` as tag-3 numbers | `005B2EC8 xorps/movss`, `005B2EE8 movss [0xbbc7ec]`, `eax = 2` |
| B40 | `OutputToPIX` is a 29-byte no-op reading one optional number | `0x005B4C90`–`0x005B4CAC` = 29 bytes; `xor eax,eax; ret` |

**Constants and cross-map (4)**

| # | Map claim | Reproduced by |
|---|---|---|
| B41 | `GetWidgetHighlightId` / `GetWidgetDownId` take **no argument** and push the globals `DAT_01176034` / `DAT_01176038` | `005B6FB6 mov edi,[0x1176034]` — no arg reader is called |
| B42 | Constants: `0x00B9B664` = 1.0, `0x00BEB2E4` = −255.0, `0x00BAC8BC` = 1/255, `0x00DFDCA4` = −0.5, `0x00BBB99C` = 0.5, `0x00BBC7EC` = 0.25, `0x00DFDB5C` = −1.0, `0x00B92870` = 100.0 | all eight read directly; all eight correct |
| B43 | **`scaleform_gfx_class_map.md` §7.2 is wrong**: the five named Flash binders are all present | A10 — and §7.2's cited "export gaps `0x60A281–0x60ADF0` / `0x61B540–0x61B8C0`" don't contain any of them either |
| B44 | The 67 + 15 binding-only bodies are missing for lack of a static caller, not because of SecuROM; the cluster sits in clean `.text` | A3 — 152/152 disassemble, 0 split thunks |

### CONTRADICTED (4)

**B45 — The location rect is NOT at `widget+0x50..0x5C`. That is the COLOUR block. Location is `+0x30..+0x3C`.**

*Map:* §0 — "a widget's **location is a 4-float RECT at `+0x50`**"; §3.1 —
`| **+0x50..+0x5C** | **location RECT [x1,y1,x2,y2], 4 floats** | all 1.0 (DAT_00B9B664) | H |`;
and §3.1's `+0x30,+0x38,+0x40,+0x48` row is dismissed as "four 8-byte pairs, zeroed" at confidence **L**.

*Truth:* the two accessors are one-instruction leaves and they settle it outright:

```
0061AF80   lea eax, [ecx + 0x30]   ; ret   <- vtable +0x1C, the slot Set/GetWidgetLocation call
0061AFF0   lea eax, [ecx + 0x50]   ; ret   <- vtable +0x4C, the slot GetWidgetColor calls
```

Three independent confirmations:

1. **The writers agree.** `0x00627360` (vtbl `+0x10`, the "4-value form" the map itself names) writes
   `movq [esi+0x30]` and `movq [esi+0x38]`. `0x00627620` (vtbl `+0x48`, the map's own `SetColor`)
   writes `movss [ecx+0x50] … [ecx+0x5C]`.
2. **The map's own evidence inverts its conclusion.** It cites the ctor initialising that block to
   "all 1.0". A location rect defaulting to `(1,1,1,1)` is a degenerate zero-size box at (1,1); an
   RGBA defaulting to `(1,1,1,1)` is **opaque white**. The ctor zeroes `+0x30..+0x3C` — the sensible
   location default — at `00626E84`.
3. **The derived accessors only work at `+0x30`.** vtbl `+0x30` = `[ecx+0x38] − [ecx+0x30]` and
   vtbl `+0x34` = `[ecx+0x3C] − [ecx+0x34]` are width and height. There is no analogous pair at `+0x50`.

*How it happened:* the map read `SetWidgetLocation`'s vtable slot (`+0x1C`) correctly and read the
ctor's float stores correctly, but never resolved `FUN_0061AF80` — Ghidra reports it as
`size=4 callers=[0x0061f767]`, a classic under-report of a 3-byte leaf ([[binding-only-is-not-a-wall-disassemble]]),
so the `+0x1C → +0x30` link was never made and the `+0x50` block got the label by elimination.

*Blast radius:* §0, §3.1, §3.2 and §8's "must model" item 3 all inherit it. Any reimplementation
following this map lays out its widget struct with location and colour transposed; the two blocks
are both 4×f32, so nothing type-checks its way out of the mistake.

**B46 — §4's correction to `scaleform_gfx_class_map.md` says "the other six" and then lists eight.**

Verbatim: *"The genuinely missing Flash binders are the other six: `SetFlashPlaySpeed`,
`GetFlashPlaySpeed`, `PauseFlash`, `PlayFlash`, `RestartFlash`, `SetFlashTesselationAllowed`, plus
`SetFlashPauseMenu` / `RemoveFlashPauseMenu`."* That is 6 + 2 = **8**. The list is exactly right
(A10); only the count is wrong. Given the whole point of the passage is to correct a sibling map's
arithmetic about which binders are absent, the wrong number is worth fixing.

**B47 — the class count is stated as six throughout; it is seven.**

Scope line: "the **six** widget C++ classes those cfuncs mint". §3: "All **six** creators are the
same 146–149-byte template" (the §3 table has **seven** rows). §9.1: "**Six** classes are recovered
(0,1,2,3,4,6,7)" — which enumerates seven tags. §10 lists "the six widget creators" and then names
six, and "the six widget ctors" and then names **seven** addresses. The base `Widget` is a real
instantiable class with its own binder, ctor, vtable, size and tag; the count is 7.

**B48 — `+0x60` is labelled "enabled/visible byte"; the visible flag the bindings actually read is `+0x20`.**

`Get/SetWidgetVisible` go through vtbl `+0x58` / `+0x54`:

```
0061B000   mov al, byte ptr [ecx + 0x20] ; ret          <- vtbl +0x58, GetWidgetVisible
00627700   ... mov byte ptr [ecx + 0x20], bl ...        <- vtbl +0x54, SetWidgetVisible (+ child propagation)
```

The map lists `+0x20` as an anonymous "flag byte, init 1" at confidence **M** and gives the
"enabled/visible" name to `+0x60` (also init 1, also **M**). Nothing in either binding table reads
`+0x60`. Two neighbouring bytes are similarly recoverable and similarly unnamed in the map:
`+0x21` = **sleep** (vtbl `+0x68`/`+0x6C` = `0x00627BB0`/`0x0061B040`, called by `Get/SetWidgetSleep`)
and `+0x15` = **highlightable** (vtbl `+0x38`/`+0x3C` = `0x0061AFD0`/`0x0061AFE0`, called by
`Get/SetWidgetHighlightable`). Relatedly, §2's gloss "`+0x64`, `+0x6C` visibility/parent predicates
used by the Flash and Movie ctors" mis-names `+0x6C`: it is the **sleep** getter.

### OVERSTATED (3)

**B49 — the one wrong layout row carries the map's highest confidence.**
§3.1 marks `+0x50..+0x5C` **H**, its top grade, reserved for "read body with a can't-coincide
fingerprint". The fingerprint cited (the 1.0 initialiser) is real but was read as corroboration when
it is in fact counter-evidence (B45). Meanwhile the row that *is* the location (`+0x30`) is graded
**L**. The confidence model inverted on the single most load-bearing field in the map.

**B50 — §2's vtable slot list is graded M when three of its five slots are provable H.**
"(M — slot *numbers* are read, the names are from the calling cfunc.)" `+0x1C`, `+0x30`, `+0x34`,
`+0x38`, `+0x3C`, `+0x4C`, `+0x58`, `+0x6C` are all 2–3-instruction leaves that name themselves the
moment you disassemble them. The map's own §9.7 identifies "dump the base vtable and diff it against
the subclass vtables" as "the single highest-leverage remaining action" — correct, and it is about
thirty seconds of capstone, not a confirm-live item.

**B51 — §9.3 ("is the slot array over-allocated by one?") is filed as open pending a live read.**
It is decidable statically: `CreateWidget` scans `slots[0 .. mgr->[0x4C])` for a free entry and, when
none is found, calls the grow thunk `0x00619C00` and appends at `mgr->[0x48]`. `[0x4C]` is the
element count of the array and indices run `0 .. [0x4C]−1`, so `id == [0x4C]` is out of bounds by one
regardless of allocator slack. Reading the grow thunk's allocation arithmetic would close it without
attaching a debugger.

### UNVERIFIABLE (2)

**B52 — per-function claims about the ~117 bodies I did not read.**
I read ~35 of 152 in full. The map's §4.1/§5.1 highlights that I did check were all correct
(B34–B41), and its mechanical columns are perfect (B10–B16), which is good evidence for the rest —
but it is inference, not verification. *What would settle it:* a mechanical sweep of all 152 from the
raw image; all of them disassemble.

**B53 — §8's reconciliation with `mercs2_ui` / `mercs2_script`.**
I did not read `tools/wad_simulator` (read-only by instruction, and out of scope for this pass), so
the three corrections in §8 — the `lib.rs:5` citation, the `"Hud"` namespace in `hud.rs`, and
`corpus_calls: 0` — are unchecked. Note that §8's item 2 is *predicated on* §1, which I did verify
(B1–B4), so its premise is sound. *What would settle it:* grep those three files.

### MISSING — established here, absent from the map (7)

**B54 — the colour block has no layout row at all.** Because `+0x50` was assigned to location, §3.1
never names widget colour, even though §3.3 documents the colour *contract* in detail. The base
widget's RGBA is `+0x50..+0x5C`, ctor-initialised to opaque white.

**B55 — the "leave unchanged" test is `< 0`, not `== -255`.** §3.3 says "a negative value
(canonically `-255` → `-1.0`) is the per-channel 'don't touch' sentinel", which is right in spirit,
but §8's "must model" item 4 compresses it to "**Colour is 0–255 with `-255` = unchanged**". The
shipped test is `comiss xmm1, 0.0 / jb skip` — a sign test that also swallows NaN. A reimplementation
that special-cases the literal `-255` will diverge on every other negative.

**B56 — width and height are derived, never stored.** vtbl `+0x30` = `[+0x38] − [+0x30]`,
vtbl `+0x34` = `[+0x3C] − [+0x34]`. This matters directly to §8's item 3: a reimplementation that
stores `w`/`h` alongside `x`/`y` desynchronises on the `+0x14` path.

**B57 — what `+0x14` and `+0x10` actually do.** §3.2 frames the 2-value form as "position, auto-size"
and says "the auto-sizing widgets implement `+0x14` themselves". The *base* implementation
`0x00627270` does no auto-sizing: it computes `delta = arg − current` and applies it to `+0x30`/`+0x34`
only, leaving `+0x38`/`+0x3C` untouched — i.e. **move, preserving the current size**. `0x00627360`
(`+0x10`) is the absolute SetRect. The auto-size framing may hold for some subclass override, but the
default behaviour is size-preserving translation, and that is the one a reimplementation needs first.

**B58 — `MinimapSetPlayerLocation` is a literal `jmp`, not an inference.** §7 calls it
"a 16-byte function, almost certainly a thin forwarder into the focus-location path. **M**,
confirm-live." It is five bytes:

```
005B90D0   e9 0b000000   jmp 0x5b90e0     ; = MinimapSetFocusLocation
005B90D5   cc cc cc ...                   ; padding
```

An exact alias, settled statically. One of the map's confirm-live items can be closed for free.

**B59 — `SetPlayerPDAWidget` writes `playerObj+0x390` *before* validating the widget.** The store at
`0x005BA5E1` and the global cache at `0x005BA5EB` both precede the `id ≤ cap` / non-null /
`[w+0x10] == 6` checks at `0x005BA5FC`–`0x005BA60F`. A rejected call still mutates player state. §4.1
documents the write but not its ordering, which is exactly the detail a §9.6 write-watchpoint session
would need to interpret its hits.

**B60 — the 82 "missing" bodies are not missing; they are unread.** §9.2 files the resolution-correction
cluster as "the highest-value recovery target" and routes it to a "forcing-script pass"
(`scripting_host_binding_code_map.md`). All 152 bodies — including `CorrectWidgetForResolution`
`0x005B6D70`, `SetWidgetUseResolutionCorrection` `0x005B6E10`, `SetWidgetUseNewRescale` `0x005B6EE0`
and `GetWidgetCorrectedLocation` `0x005B54B0` — sit in clean `.text` with raw bytes present and
disassemble immediately (A3). No forcing pass, no Ghidra re-analysis, no debugger. The map states the
right *reason* they are absent from the export (B44) but then treats the export as the only route in.
This is the single most actionable item in this validation: the map's biggest self-declared gap is
already open.

---

## Reproduction

```bash
# in the session scratchpad, against output/_ghidra/securom_dump/mercs2_unpacked.exe
python hudval/registry.py         # 31 registry rows + both boot chunks
python hudval/dumpreg.py          # 114 + 38 rows, per-row VA, sub-table delimiters
python hudval/coverage.py         # 47/114 and 23/38 present in the Ghidra export
python hudval/typetag.py          # every `mov dword [reg+0x10], imm32` in .text
python hudval/callers.py 626DA0   # the six direct callers of the base widget ctor
```

Single-instruction proofs, verifiable in any disassembler:

| VA | bytes / text | settles |
|---|---|---|
| `0x0061AF80` | `lea eax,[ecx+0x30]; ret` | **location is at `+0x30`** (B45) |
| `0x0061AFF0` | `lea eax,[ecx+0x50]; ret` | **colour is at `+0x50`** (B45) |
| `0x0061B000` | `mov al,[ecx+0x20]; ret` | visible flag is `+0x20` (B48) |
| `0x0061B040` | `mov al,[ecx+0x21]; ret` | sleep flag is `+0x21` (B48) |
| `0x0061AFB0` | `fld [ecx+0x38]; fsub [ecx+0x30]` | width is derived (B56) |
| `0x00627620` | `comiss xmm1,0 / jb` ×4 then `[ecx+0x50..0x5C]` | colour "unchanged" is a sign test (B55) |
| `0x005B4C60` | `je 0x5b4c86` | `ShowLoadingHints` one-way switch (B34) |
| `0x005BCEEF` | `cmp dword ptr [eax+0x10], 6` | `AddPdaMapBlips` null deref (B35) |
| `0x005B90D0` | `e9 0b000000` → `jmp 0x5b90e0` | `MinimapSetPlayerLocation` is an alias (B58) |
| `0x005BA5E1` | `mov [ecx+0x390], eax` (before validation) | `SetPlayerPDAWidget` ordering (B59) |

---

# Pass 2 — second-blind verification

**Date:** 2026-07-26. **Scope:** close every Pass-1 item that was not an explicit CONFIRM
(4 CONTRADICTED · 3 OVERSTATED · 2 UNVERIFIABLE · 7 MISSING), plus the nine questions the map itself
files as open. **Pass-1 verdicts were treated as untrusted claims and re-derived from the raw
image**; where Pass 2 agrees it says so, where Pass 2 disagrees with Pass 1 it says that too.

**Method.** Fresh capstone toolchain in a clean scratch dir (`hud2/{pe,tab,sweep,slots,fields,vt,xref}.py`),
nothing reused from Pass 1. Primary image `output/_ghidra/securom_dump/mercs2_unpacked.exe`; retail
cross-check `mercs2_nodrm_v3.exe`. The Ghidra export was used **only** to measure its own coverage
and to demonstrate its under-reporting, never as a source of fact.

## P2.0 — Headline results

1. **All 152 binder bodies were read.** 151 distinct bodies (`MinimapSetPlayerLocation` is a 5-byte
   alias). Every one disassembles from the raw image.
2. **The widget layout was re-derived from zero** and is given complete in §P2.3 — 31-slot base
   vtable dumped in full, every ctor-initialised field named or explicitly marked unknown.
   **Pass 1's transposition finding is CONFIRMED**: location is `+0x30`, colour is `+0x50`.
3. **Two of Pass 1's own findings are wrong** — B48 (`+0x60`) and B57 (`vtbl+0x14`); see §P2.7.
4. **The `AddPdaMapBlips` null-deref is in THREE binders, not one.** New.
5. **Map §9.3 (slot array over-allocated?) is CLOSED: it is not.** The ctor allocates exactly
   `capacity` entries. The 1-element OOB read is real. New.
6. **The resolution-correction model — the map's self-declared "highest-value recovery target" — is
   fully recovered** (§P2.4). No forcing pass, no debugger.

---

## P2.1 — Are all 152 bodies readable? (closes B52, B60)

`hud2/tab.py` parses both `luaL_Reg` tables straight from `.rdata`: `_GuiInternal` @ `0x00B99FF8`
= **114** entries, terminator `0x00B9A388`; `Gui` @ `0x00B9A398` = **38**, terminator `0x00B9A4C8`.
All 152 function pointers land in `.text`. `hud2/sweep.py` then took a function extent for each and
emitted `all_bodies.asm` (152 bodies, ~21 k instructions). **Every body disassembles cleanly.**

Three honest qualifications Pass 1 did not make:

* **`Gui.AddObjective` `0x006D5640` IS a 5-byte `jmp` in the primary image** — `jmp 0x6FCD20C0`,
  a target outside the image: the `pmc_bb.dll` hook of trap 4, captured in the dump. Pass 1's
  blanket "none is a SecuROM split thunk" is right about SecuROM but glosses this. In
  `mercs2_nodrm_v3.exe` the retail body is `xor eax,eax; ret` (3 bytes) — **the map's "shared retail
  dev stub" reading is correct, and only the *retail* image proves it.**
* **Four bodies contain an absolute-indirect edge.** Three are plain MSVCR80 imports
  (`SetWidgetFullscreen 0x005B6CC7` and `SetTextJustification 0x005B84AA` → `[0x00B0536C]` =
  `MSVCR80!tolower`; `SetFlashPauseMenu 0x005BB5E1` → `[0x00B052EC]` = `MSVCR80!strncpy`; the import
  table was walked, not guessed). The fourth is a **genuine SecuROM split thunk inside a binder**:
  `CallFlashScriptFunction 0x005BB3EA: jmp dword ptr [0x0245505C]` → `0x024B8740`, which is a
  SecuROM stub in `.securom`, **not** resolved to `.text` in this dump (nor in `nodrm_v3`). That one
  call edge is unresolved; the surrounding 870 bytes are readable.
* **Ghidra under-reports the size of 5 of the 70 exported bodies.** `CallFlashScriptFunction` is the
  clean demonstration: the export header says `size=662`, the true extent is **870** — the export
  stops exactly at the split-thunk `jmp` above. Trap 2, reproduced.

**Verdict on B52: CLOSED — every map claim that was checkable is correct** (see §P2.2).
**Verdict on B60: CONFIRMED and discharged** — the 82 "missing" bodies were merely unread; all 82
were read this pass.

## P2.2 — All 152 rows re-diffed mechanically (re-closes B10–B16)

Independently reproduced against the binary and the 370-script corpus:

| column | result |
|---|---|
| 152 names | 0 errors |
| 152 row indices | 0 errors |
| 152 VAs | 0 errors |
| 152 ⬤/○ markers vs. export headers | 0 errors (47/67 and 23/15) |
| 152 per-row call counts | 0 errors; sums **339** and **72** |
| never-called | exactly `GetWidgetHighlightable`, `GetTextWrapping`, `SetMinimapRadius` |
| `Marker.*` | 51 sites, 8 distinct members, 14 files |

Every mechanical column in the map is correct — a second, independent confirmation.

## P2.3 — The complete widget field table (re-derived from zero)

### P2.3.1 The base vtable — all 31 slots (closes map §9.7 and B50)

`PTR_FUN_00BBCEE8` is **31 entries** (`+0x00 … +0x78`); the dword at slot 31 is ASCII (`"Lase…"`),
so the interface is closed. The "binder" column was produced mechanically by `hud2/slots.py`
(register dataflow from the slot load to the `call reg`), not by eye.

| slot | base fn | what it is (read from the body) | binder that calls it | overridden by |
|---|---|---|---|---|
| `+0x00` | `0x00626F70` | scalar-deleting dtor | — | Text, Minimap, Movie, Flash, Sprite |
| `+0x04` | `0x00848E30` | `ret 4` (no-op) | — | Image/Sprite `0x0061D070`, Text, Minimap, Movie, Flash |
| `+0x08` | `0x00627170` | update/tick | — | all six |
| `+0x0C` | `0x00848E30` | `ret 4` (no-op) | — | Text, Minimap |
| `+0x10` | `0x00627360` | **SetRect(rect, propagate)** — absolute; `movq [this+0x30]`, `movq [this+0x38]` | `SetWidgetLocation` (4-arg form) | Text, Minimap |
| `+0x14` | `0x00627270` | **Move(point, propagate)** — `d = arg − [+0x30]`, added to **all four** components | `SetWidgetLocation` (2-arg form) | — |
| `+0x18` | `0x00627430` | child-propagating transform | — | — |
| `+0x1C` | `0x0061AF80` | **`lea eax,[ecx+0x30]; ret`** → &location rect | `Set/GetWidgetLocation`, `GetWidgetViewport`, `SetSpriteFrameSize` | — |
| `+0x20` | `0x00974BA0` | **`lea eax,[ecx+0x40]; ret`** → &corrected rect | `GetWidgetCorrectedLocation` | — |
| `+0x24` | `0x0061AF90` | **SetCorrectedRect** — copies 16 bytes to `[ecx+0x40]` | `SetWidgetCorrectedLocation` | Flash `0x0061B8C0` |
| `+0x28` | `0x00622550` | switch on `[ecx+0x6C]` (horizontal anchor) | — | — |
| `+0x2C` | `0x006275B0` | switch on `[ecx+0x70]` (vertical anchor) | — | — |
| `+0x30` | `0x0061AFB0` | **GetWidth** = `[+0x38] − [+0x30]` | `GetTextWidth` | Text `0x006226D0` |
| `+0x34` | `0x0061AFC0` | **GetHeight** = `[+0x3C] − [+0x34]` | `GetTextHeight` | Text `0x00622800` |
| `+0x38` | `0x0061AFD0` | **SetHighlightable** → `[ecx+0x15]` | `SetWidgetHighlightable` | — |
| `+0x3C` | `0x0061AFE0` | **GetHighlightable** ← `[ecx+0x15]` | `GetWidgetHighlightable` | — |
| `+0x40` | `0x009C2B50` | get `[ecx+0x14]` | *(no binder)* | — |
| `+0x44` | `0x006270A0` | draw/submit (gates on `[+0xE0]` and `[0x01175F2F]`) | — | — |
| `+0x48` | `0x00627620` | **SetColor(float[4], propagate)** → `[+0x50..+0x5C]`, per-channel `comiss …,0 / jb skip` | `SetWidgetColor` | — |
| `+0x4C` | `0x0061AFF0` | **`lea eax,[ecx+0x50]; ret`** → &colour | `GetWidgetColor`, `SplitText` | — |
| `+0x50` | `0x00627690` | colour-with-children apply | — | — |
| `+0x54` | `0x00627700` | **SetVisible** → `[ecx+0x20]` + child walk via `+0xF0` | `SetWidgetVisible` | Flash `0x0061BD10` |
| `+0x58` | `0x0061B000` | **GetVisible** ← `[ecx+0x20]` | `GetWidgetVisible`, `SplitText` | — |
| `+0x5C` | `0x0061B010` | **CorrectForResolution** — `mov eax,[ecx]; mov edx,[eax+0x70]; jmp edx` (tail-calls `+0x70`) | `CorrectWidgetForResolution`, `SetWidgetFullscreen` | Text `0x00622940` |
| `+0x60` | `0x0061B020` | set `[ecx+0x63]` | *(no binder)* | Flash `0x0061BCA0` |
| `+0x64` | `0x0061B030` | get `[ecx+0x63]` | *(no binder)* | — |
| `+0x68` | `0x00627BB0` | **SetSleep** → `[ecx+0x21]`, gated on `[+0xE4]` | `SetWidgetSleep` | Flash `0x0061BD90` |
| `+0x6C` | `0x0061B040` | **GetSleep** ← `[ecx+0x21]` | `GetWidgetSleep` | — |
| `+0x70` | `0x00627DA0` | **the rescale core** (1136 B) — §P2.4 | *(via `+0x5C`)*; `SetWidgetAnchoring`, `SplitText` | — |
| `+0x74` | `0x00628210` | scale/zoom helper | — | Image/Sprite `0x0061D850` |
| `+0x78` | `0x00628460` | layout/bounds (691 B) | — | — |

Subclass vtable lengths: Widget 31 · Text 31 · Movie 31 · Flash 31 · **Sprite 31** · **Image 43**
(`+0x7C…+0xA8`) · **Minimap 63** (`+0x7C…+0xF8`).

### P2.3.2 Base `Widget` fields (size `0x130`, ctor `FUN_00626DA0`, read instruction-by-instruction)

| off | sz | field | ctor init | evidence |
|---|---|---|---|---|
| `+0x00` | 4 | vtable | `0x00BBCEE8` | `00626DAF` |
| `+0x10` | 4 | **type tag** | `0` | `00626DB5` |
| `+0x14` | 1 | unnamed flag | `0` | `00626F5C`; getter vtbl `+0x40` |
| `+0x15` | 1 | **highlightable** | `0` | `00626F5F`; vtbl `+0x38`/`+0x3C` |
| `+0x18` | 4 | **slot id / uId** | `-1` | `00626DB8`; `CreateWidget 005B4ED7` |
| `+0x1C` | 4 | **viewport index** | `0` | `00626E6F`; `Get/SetWidgetViewport`; `00627DAC` indexes `[0x00DFC2F8]` with stride `0xE80`, and `< 0` short-circuits the rescale |
| `+0x20` | 1 | **visible** | `1` | `00626DBF`; vtbl `+0x54`/`+0x58` |
| `+0x21` | 1 | **sleep** | `0` | `00626DC3`; vtbl `+0x68`/`+0x6C` |
| **`+0x30..+0x3C`** | 16 | **location RECT `[x1,y1,x2,y2]`** | `0,0,0,0` | `00626E84` + `00626EA8`; vtbl `+0x1C` = `lea eax,[ecx+0x30]` |
| **`+0x40..+0x4C`** | 16 | **corrected (screen-space) RECT** | `0,0,0,0` | `00626E89` + `00626EAD`; vtbl `+0x20` = `lea eax,[ecx+0x40]`, vtbl `+0x24` writes it, and `0x00628209` is the rescale core storing its result through `+0x24` |
| **`+0x50..+0x5C`** | 16 | **colour RGBA (0..1)** | `1,1,1,1` (`[0x00B9B664]`) | `00626ED0` / `00626EDB`; vtbl `+0x4C` = `lea eax,[ecx+0x50]`; SetColor writes `+0x50..+0x5C` |
| **`+0x60`** | 1 | **useResolutionCorrection** | **`1`** | `00626DC6`; **`SetWidgetUseResolutionCorrection` writes it at `005B6EC6`**; the rescale core branches on it at `0062805B`, `006280A5`, `006280F9`, `0062812C`, `00628173`, `00628191` |
| **`+0x61`** | 1 | **position-relative-to-parent** | `0` | `00626DCA`; `00627DE1`: if set **and** `+0xEC` is non-null, the rescale frame becomes the *parent's* two rects |
| **`+0x62`** | 1 | **ignoresPause** | `0` | `00626DCD`; **`SetWidgetIgnoresPause 005B5A86` writes it, `GetWidgetIgnoresPause 005B5B35` reads it** |
| `+0x63` | 1 | unnamed flag | `0` | `00626DD0`; vtbl `+0x60`/`+0x64` |
| `+0x64` | 1 | unnamed flag | `0` | `00626DD3` |
| `+0x65` | 1 | **on-manager-active-list** | `0` | `00626DD6`; set at `0x00618E37` when the widget is spliced into `mgr+0x10` |
| **`+0x68`** | 4 | **fullscreen / rescale mode `0..3`** | `0` | `00626DD9`; `SetWidgetFullscreen` writes 0/1/2/3; the rescale core switches on it at `00627F38` |
| **`+0x6C`** | 4 | **horizontal anchor** (0 left / 1 right / 2 centre) | `0` | `00626DDC`; `SetWidgetAnchoring`; vtbl `+0x28` |
| **`+0x70`** | 4 | **vertical anchor** (3 top / 4 bottom / 2 centre) | **`3`** | `00626DDF`; vtbl `+0x2C` |
| `+0x78`, `+0x7C`, `+0x80`(b) | — | zeroed | `0` | `00626DE6`–`00626DEC` |
| `+0xB0..+0xBC` | 16 | float quad | `0.0` | `00626F00`–`00626F18` |
| `+0xC0..+0xCC` | 16 | float quad | `0.0` | `00626EE0`–`00626EF8` |
| `+0xD0` | 1 | flag | `0` | `00626DF2` |
| **`+0xD1`** | 1 | **useNewRescale** | `0` | `00626DF8`; **`SetWidgetUseNewRescale` → `FUN_00627C00 0x00627C0C`, which also recurses into every child through `+0xF0`** |
| `+0xD8`, `+0xDC` | 8 | zeroed | `0` | `00626DFE` |
| `+0xE0` | 1 | draw-gate flag | `0` | `00626F26`; tested by vtbl `+0x44` |
| `+0xE4` | 4 | pending/refcount | `0` | `00626F2C`; `++` by the Flash ctor `0061B223` and the Movie ctor `00621D8A`; gates vtbl `+0x68` |
| `+0xE8` | 1 | flag | `0` | `00626F32` |
| **`+0xEC`** | 4 | **parent widget pointer** | `0` | `00626F20`; dereferenced by the rescale core at `00627E1D`/`00627E2E` through the parent's vtbl `+0x1C`/`+0x20` |
| `+0xF0..+0xFC` | 16 | **child list head**, self-linked; node `{next, prev, owner@+8}` | self | `00626E16`; walked by SetVisible / SetColor / `FUN_00627C00` |
| `+0x100..+0x120` | 36 | **manager active-list node** | `0` | `00626E21`–`00626E51`; `0x00618E29` splices `+0x100` into `mgr+0x10` |
| `+0x124..+0x12C` | 12 | **global widget-list node** `{next, prev, owner}` | spliced | `00626E69`, `00626F3F`–`00626F5A`; head `0x00DF6AC0`/`0x00DF6AC4` |
| `+0x130` | — | end of base object | — | `CreateWidget push 0x130` |

Live-widget counter `_DAT_00DF6ACC` is `++` at `00626F38` — **but see §P2.9(f): one construction
path decrements it back, so it is not a reliable census.**

### P2.3.3 Subclass field extents recovered this pass

| class | size | tag | new fields (from ctor + binders) |
|---|---|---|---|
| Image | `0x1C0` | 1 | `+0x140/+0x144/+0x148/+0x14C` tex-coords · `+0x150` rotation · `+0x160..0x170` and `+0x180..0x190` float blocks · `+0x194`(b) · `+0x1A0/+0x1A8/+0x1AC` · `+0x1B0/+0x1B4` · `+0x1B8`(b) pie-slice |
| Text | `0x170` | 2 | `+0x130` text · `+0x134` · **`+0x138` font asset hash `0x339761F4`** (`006223C1`) · `+0x13C` wrapping · `+0x13E/+0x13F` · `+0x144` scale · `+0x14C`/`+0x154` animation · `+0x150` justification |
| Minimap | **`0x1020`** | 3 | `+0x148` rotation · `+0x168/+0x16C` owner · `+0x190/+0x194/+0x198` focus point · `+0x19C` range · `+0x1A4/+0x1AC/+0x1B0` border · **`+0x4E4` 0xC0-dword (768 B) zeroed block** (`0061F74E`) · asset hashes `0x59D0F617` (`0061F831`) and `0x6FD35750` (`0061F849`) |
| Movie | `0x150` | 4 | (unmapped — no binder touches its interior) |
| Flash | `0x4C0` | 6 | `+0x1D0` play speed · `+0x1D8/+0x1DC/+0x1E0` name-hash / asset / `GFxMovieView*` · `+0x4A4/+0x4A8/+0x4B4` left analog · `+0x4AC/+0x4B0/+0x4B5` right analog |
| Sprite | `0x200` | 7 | reuses Image's `+0x130..+0x1B8` via the ctor chain, adds `+0x1C0`(b)/`+0x1C1`(b) · `+0x1C4/+0x1C8/+0x1CC/+0x1D0` (init from `[0x01176710]`/`[0x01176714]`) · `+0x1D4/+0x1D8` · `+0x1DC` = 100.0 · `+0x1E0..+0x1F0` · `+0x1F4`(b)/`+0x1F5`(b) |

The minimap size is now pinned: **`0x1020`** (`MinimapCreate 005B8E4A push 0x1020`), not the
"≥ 0x7E4" the map inferred.

## P2.4 — The resolution-correction model, recovered (closes map §9.2)

Six binders, one virtual, one core routine — all read this pass.

**Inputs on the widget:** `+0x1C` viewport index · `+0x30..0x3C` authored rect · `+0x60`
useResolutionCorrection · `+0x61` relative-to-parent · `+0x68` mode · `+0x6C`/`+0x70` anchors ·
`+0xD1` useNewRescale · `+0xEC` parent. **Output:** `+0x40..0x4C`.

**`Widget::CorrectForResolution` = vtbl `+0x70` = `FUN_00627DA0`** (1136 B), reached through vtbl
`+0x5C` (`0x0061B010`, a 7-byte tail-jump):

1. `vp = [this+0x1C]`. **`vp < 0` ⇒ bail with the degenerate rect `(0, 0, 100.0, 0)`**
   (`[0x00B92870] = 100.0`) and still store it through `+0x24`.
2. Otherwise `vpDesc = [0x00DFC2F8] + vp*0xE80`; screen `W = (float)[vpDesc+0x28]`,
   `H = (float)[vpDesc+0x2C]`; pixel-aspect `= [[0x00DFC2F8]+0x2BD0]`. (The `0xE80` stride marries
   this to the viewport array in `camera_code_map.md`.)
3. **Reference frame.** If `[this+0x61] && [this+0xEC]` → frame-A = the parent's `vtbl+0x1C` rect and
   frame-B = the parent's `vtbl+0x20` rect. Otherwise frame-A is the **640×480 design space**
   (`[0x00BEAC58] = 640.0`, `[0x00BEAAC8] = 480.0`) and frame-B is the viewport.
4. `sx = (B.x2−B.x1)/(A.x2−A.x1)`, `sy = (B.y2−B.y1)/(A.y2−A.y1)`; the vertical unit is
   `H × [0x00BEA95C]` where **`0x00BEA95C = 0.00208333 = 1/480`**.
5. **Mode switch on `[this+0x68]`** (`00627F38`):
   * **0** → the anchor path (`0x0062801D`): switch `[+0x6C]` (0/1/2) then `[+0x70]` (2/3/4), each
     branch gated on `[+0x60]`.
   * **1** → fullscreen: rect = `(0, 0, W×aspect, H)`.
   * **2** → **letterbox**: height = `(1/aspect) × (W×aspect) × 0.5625`, centred
     (`0x00BEAE54 = 0.5625 = 9/16`, `0x00BBB99C = 0.5`).
   * **3** → pillarbox: half-width / half-height centring on `0.5`.
6. Store: `mov edx,[vtbl+0x24]; lea ecx,[esp+0x40]; call edx` — i.e. **SetCorrectedLocation**,
   writing `+0x40..0x4C`. That is the same virtual `SetWidgetCorrectedLocation` calls, which is why
   the corrected rect is both a renderer input and a script-writable field.

**`SetWidgetFullscreen(id, arg)` `0x005B6BC0`** — `arg` may be a **boolean** (→ mode 0 or 1) *or a
string*. The string path does `tolower(s[0])`, `eax −= 0x66`, range-checks `<= 0xA`, and jumps
through the table at `0x005B6D48` indexed by the byte table at `0x005B6D5C`:

| first letter | mode | corroboration |
|---|---|---|
| `'f'` | **1** | the boolean-`true` path sets the same value |
| `'l'` | **2** | **`SetFullscreen("Letterbox")` ×8 in the Lua corpus** — proven |
| `'o'` | **0** | letter proven; word inferred ("Off"/"None") |
| `'p'` | **3** | letter proven; word inferred ("Pillarbox" — it is the centring branch) |
| `g,h,i,j,k,m,n` | no-op | falls to `0x005B6D3D` |

Each mode change calls vtbl `+0x5C` to recompute immediately.

**`SetWidgetUseResolutionCorrection(id, bool)` `0x005B6E10`** → `mov [ebp+0x60], dl` at `005B6EC6`.
A plain byte write, with **no** recompute.

**`SetWidgetUseNewRescale(id, bool)` `0x005B6EE0`** → `FUN_00627C00(this, bool)`, which writes
`[this+0xD1]` and then **recurses over the whole child subtree** through `+0xF0`.

**`SetWidgetCorrectedLocation` / `GetWidgetCorrectedLocation`** are simply the `+0x24` / `+0x20`
pair on `+0x40`. The map's "single 28-byte struct argument" is a mis-read of the stack frame: vtbl
`+0x24` (`0x0061AF90`) is 26 bytes long and copies **exactly 16 bytes** (`movq` ×2) from `[esp+4]`
to `[ecx+0x40]`. **The argument is a 4-float rect, the same as everywhere else.**

## P2.5 — The two shipped defects, independently re-derived, with exact repros

### D1 — `Gui.ShowLoadingHints(false)` is a no-op. **CONFIRMED.**

`0x005B4C30`, 92 bytes, complete:

```
005B4C49  call 0x59F6D0                ; optional bool
005B4C4E  test eax,eax
005B4C50  jg   0x5B4C5A                ; arg present
005B4C52  mov  al,1                    ; ABSENT -> default TRUE
005B4C58  jmp  0x5B4C62                ; ...and fall into the write
005B4C5A  mov  al,[esp+0x10]
005B4C5E  test al,al
005B4C60  je   0x5B4C86                ; <<< FALSE -> jump to the epilogue, write skipped
005B4C62  mov  ecx,[0x01175FB0]
005B4C68  mov  [ecx+0x39],al           ; the ONLY write; al is 1 on both reaching paths
005B4C6B  cmp  byte [0x00DF67F4],0     ; secondary-notify gate
005B4C74..005B4C81                     ; esi = [0x01175F7C]+0x70 (register arg) -> call 0x00608590
005B4C86  epilogue, returns 0 values
```

`[app+0x39]` can only ever be written with `1`. **Repro (script, no debugger):**
`Gui.ShowLoadingHints(true)`, then `Gui.ShowLoadingHints(false)`, then load a level — the hints
still show. **Repro (x32dbg, read-only, PAUSED):** HW write-watchpoint on `[[0x01175FB0]+0x39]`; it
fires on the `true` / omitted calls and never on `false`. **Fix scope:** the defect is the `je` at
`0x005B4C60`; a correct build needs both that branch removed and the notify at `0x005B4C74` made
reachable — a small patch region, not a one-byte flip.

### D2 — the PDA-blip null deref. **CONFIRMED — and it is THREE binders, not one. NEW.**

The shared shape in all three: the range-check failure path is `xor eax,eax`, control **merges**, and
the very next widget access is unguarded.

| binder | VA | fail path | faulting instruction | Lua call sites |
|---|---|---|---|---|
| `AddPdaMapBlips` | `0x005BCE70` | `005BCEE8 xor eax,eax` | **`005BCEEF cmp dword ptr [eax+0x10], 6`** | 2 |
| **`UpdatePdaBlip`** | `0x005BCF90` | `005BD008 xor eax,eax` | **`005BD00F cmp dword ptr [eax+0x10], 6`** | 2 |
| **`RemovePdaBlip`** | `0x005BD0C0` | `005BD135 xor eax,eax` | **`005BD139 cmp dword ptr [eax+0x10], 6`** | 3 |

All three then use the branchless `setne / sub / and` idiom to pass `0` to the callee — that idiom is
*why* they have no null check: the author folded "not a flash widget ⇒ NULL" into arithmetic and
overlooked that the tag read itself dereferences. Every other widget binder does `test reg,reg / jne`
first (`SetWidgetLocation 005B5018`, `DeleteWidget 005B4F89`, `GetWidgetVisible 005B598F`, …).

**Two reaching conditions, not one:** (a) the range check fails; (b) the range check *passes* on a
slot holding NULL — a deleted widget, which is reachable because ids are reused.

**Repro (script):** `_GuiInternal.RemovePdaBlip(-1, "x")` — the `id < 0` branch is taken at
`005BD126`, `eax = 0`, and `005BD139` reads linear address `0x00000010` → access violation. Identical
for `_GuiInternal.AddPdaMapBlips(-1, {})` and `_GuiInternal.UpdatePdaBlip(-1, {})`. The arg-2 type
check (`cmp edx,5` for a Lua table) happens *after* the fault, so arg 2 is irrelevant.
**Repro (x32dbg, read-only):** one-shot bp at `0x005BD139`, then trigger a PDA close/reopen while a
blip id is stale, and read EAX. Do **not** set a conditional bp — these sit next to per-frame work.

**Fix-pack scope tripled:** the map and Pass 1 both name only `AddPdaMapBlips`.

## P2.6 — Map §9.3 CLOSED: the slot array is **not** over-allocated. **NEW.**

The widget manager is built at `0x0060ACD6` inside the GUI subsystem init:
`push 0x88; call 0x0084AC20` (allocate **0x88 bytes**) → `call 0x00618BF0` → `mov [ebp+0x68], eax`.

`FUN_00618BF0`, read in full:

```
00618C43  push 1
00618C45  push 0x200                    ; <<< 512 bytes
00618C55  call 0x0084AC20
00618C5D  mov  [esi+0x44], eax          ; slots
00618C60  mov  [esi+0x48], ebx          ; = 0
00618C63  mov  dword [esi+0x4C], 0x80   ; <<< capacity = 128
00618C70  loop: mov ecx,[esi+0x44]; mov [ecx+eax*4],0; inc eax; cmp eax,[esi+0x4C]; jl
```

**`0x200 bytes / 4 = 0x80` = exactly `[mgr+0x4C]` entries. Zero slack.** The zero-fill loop runs
`i ∈ [0, [+0x4C])`, and `CreateWidget`'s free-slot scan runs over the same `[0, [+0x4C])`. The guard
in every binder is `cmp id,[mgr+0x4C]; jg fail`, which **admits `id == [mgr+0x4C]`**. Therefore
`slots[capacity]` is a **4-byte heap over-read one element past a 512-byte block, reachable from any
script that passes `id == capacity`** — and the garbage pointer it loads is then dereferenced
(`[w+0x10]`, `[w]` vtable, …). A real defect, not a benign read.

*Correction to Pass 1's B51:* B51 said the question could be closed "by reading the grow thunk's
allocation arithmetic". It cannot — **`FUN_00619C00` is a real SecuROM split thunk
(`jmp dword ptr [0x0245DCF0]` → `0x028C9000`, still inside `.securom`) in BOTH `mercs2_unpacked.exe`
and `mercs2_nodrm_v3.exe`**, so the *grow* arithmetic is not statically available. The question is
nonetheless closed — by the **initial** allocation, which is exact. Pass 1 reached the right verdict
by the wrong route.

Other manager fields recovered: `+0x00/+0x04` list head · `+0x10..+0x1C` **active-widget list** and
counters (`FUN_00618DD0`) · `+0x20..+0x2C` and `+0x30..+0x3C` two more lists · `+0x40`/`+0x41` dirty
flags · `+0x44` slots · `+0x48` append index · `+0x4C` capacity/count · `+0x50` and `+0x6C` **two
CRITICAL_SECTIONs** (`InitializeCriticalSection` via `[0x00B05120]`; `FUN_00618DD0` takes `+0x6C`
around the active-list splice). Object size `0x88`.

`FUN_00618D50` = `Manager::Delete(widget)` — clears `slots[id] = 0` and resets `widget+0x18 = -1`,
confirming slot reuse at the source rather than by inference.

## P2.7 — Verdicts on Pass 1's open register

### CONTRADICTED (Pass 1's four)

* **B45 (location `+0x30`, colour `+0x50`) — CONFIRMED, three independent ways.** (i) vtbl `+0x1C` =
  `lea eax,[ecx+0x30]` and `+0x4C` = `lea eax,[ecx+0x50]`, and the *callers* are
  `Set/GetWidgetLocation` and `GetWidgetColor` respectively (mechanically derived, §P2.3.1).
  (ii) `SetColor 0x00627620` writes `+0x50..+0x5C`; `SetRect 0x00627360` writes `+0x30..+0x3C`.
  (iii) the ctor defaults — rect `(0,0,0,0)`, colour `(1,1,1,1)` = opaque white. **The map is wrong;
  Pass 1 is right.**
* **B46 ("the other six", then eight listed) — CONFIRMED.** 15 Flash-named binders; **8** absent from
  the export (`SetFlashPlaySpeed`, `GetFlashPlaySpeed`, `PauseFlash`, `PlayFlash`, `RestartFlash`,
  `SetFlashTesselationAllowed`, `SetFlashPauseMenu`, `RemoveFlashPauseMenu`). The list is right, the
  word "six" is wrong.
* **B47 (six vs seven classes) — CONFIRMED, and now closed by exhaustion.** A byte-level xref
  (`hud2/xref.py`) finds **exactly 6 `call` sites targeting the base ctor `0x00626DA0`**:
  `0x005B4E9A` (CreateWidget) plus the five subclass ctors `0x0061B0AC`, `0x0061CF90`, `0x0061F72D`,
  `0x00621D83`, `0x00622382`. Sprite reaches it only through the Image ctor. **The class set is
  closed at 7**, and the base `Widget` is instantiable with its own binder, size, vtable and tag.
* **B48 (`+0x60` mislabelled) — HALF WRONG.** Pass 1 is right that visible = `+0x20`, sleep = `+0x21`
  and highlightable = `+0x15`. But Pass 1 wrote *"Nothing in either binding table reads `+0x60`"* —
  **false**. `SetWidgetUseResolutionCorrection` writes `[w+0x60]` at `0x005B6EC6`, and the rescale
  core branches on it six times. **`+0x60` is `useResolutionCorrection`, ctor-default 1** — a named
  field, not a mystery byte. Pass 1 also left `+0x62` unnamed; it is **ignoresPause** (`005B5A86`
  writes it, `005B5B35` reads it). The map's label and Pass 1's rebuttal are both wrong.

### OVERSTATED (Pass 1's three)

* **B49 — CONFIRMED.** The `+0x50` row carries **H**, and it is the one wrong row; `+0x30` carries **L**.
* **B50 — CONFIRMED and superseded.** The whole 31-slot base vtable is dumped in §P2.3.1, with 20 of
  31 slots named from their own bodies. It took one script.
* **B51 — CONFIRMED as "the map overstates it", but Pass 1's proposed route is wrong.** See §P2.6.

### UNVERIFIABLE (Pass 1's two)

* **B52 — CLOSED.** All 152 read (§P2.1); every checkable map claim checks out (§P2.2).
* **B53 — CLOSED. All three of the map's §8 corrections are correct**, read from
  `tools/wad_simulator/` read-only (no edits, no commits):
  1. `crates/mercs2_ui/src/lib.rs:5` literally reads
     ``//! **Code map:** `docs/reverse_engineer/scaleform_gfx_class_map.md (+ input_code_map.md)`.`` —
     the wrong citation, exactly as the map says.
  2. `crates/mercs2_script/src/bindings/hud.rs:18/20/22`: `NAMESPACE = "Hud"`, `GLOBAL = "Hud"`,
     `TABLE_VA = 0x00b99ff8`. That VA registers as `_GuiInternal` in the PE. Collision confirmed.
  3. `hud.rs` carries **`corpus_calls: 0` on all 114 rows** (114/114 counted). `gui.rs` does carry
     real counts. **New, small:** `gui.rs:27` says `GetReticlePosition, corpus_calls: 5`; the true
     count is **6** (and the map's §5 table has 6). One more stale cell the map did not catch.

  *Also observed (not a map claim):* `mercs2_ui`'s `Widget` struct is closer to retail than the map
  implies — it already keeps `location` / `corrected_location` / `color` as separate `[f32;4]` and
  does not store `w`/`h`. Its real divergences are `fullscreen: bool` (retail is a 4-mode enum
  settable by string, §P2.4), a single `anchoring: u32` (retail has two independent fields with
  defaults 0 and **3**), monotonic `next: u64` handles (retail reuses dense slot indices), and no
  `use_resolution_correction` / `use_new_rescale`.

### MISSING (Pass 1's seven)

* **B54 (colour has no layout row) — CONFIRMED.** Supplied in §P2.3.2.
* **B55 (`< 0`, not `== -255`) — CONFIRMED verbatim.** `0x00627620`: four × `comiss xmm1, xmm0(0.0)`
  / `jb skip`. A sign test; NaN is skipped too (unordered sets CF).
* **B56 (width/height derived) — CONFIRMED.** vtbl `+0x30`/`+0x34`, called by `GetTextWidth` /
  `GetTextHeight` — which is *why* those bindings exist.
* **B57 (what `+0x14` / `+0x10` do) — PARTLY WRONG.** Pass 1: *"`0x00627270` … applies it to
  `+0x30`/`+0x34` only, leaving `+0x38`/`+0x3C` untouched"*. **False.** Read `0x006272AD`–`0x006272C8`:
  the same delta is added to `+0x38` **and** `+0x3C`. It translates the **whole rect**. Pass 1's
  *conclusion* ("move preserving size") is right; its *mechanism* is wrong, and a reimplementation
  written from B57 would leave the far corner behind and silently resize every widget it moves.
  `0x00627360` (`+0x10`) is confirmed as the absolute SetRect (`movq [esi+0x30]`, `movq [esi+0x38]`).
* **B58 (`MinimapSetPlayerLocation` is a literal `jmp`) — CONFIRMED.** `005B90D0: E9 0B 00 00 00`
  → `0x005B90E0`, then `CC` padding. 5 bytes, an exact alias. Map §7's "M, confirm-live" closes.
* **B59 (`playerObj+0x390` written before validation) — CONFIRMED.** `005BA5E1 mov [ecx+0x390], eax`
  precedes the `id<0` / `id>cap` / `slot!=NULL` / `[w+0x10]==6` chain at `005BA5FA`–`005BA60F`.
* **B60 — CONFIRMED and discharged.** See §P2.1.

## P2.8 — The map's own nine open questions

| map §9 | verdict |
|---|---|
| **9.1 tag 5** | **CLOSED — unassigned.** Two independent censuses: (a) `mov dword [reg+0x10], imm` over all of `.text` finds 5 sites writing 5 — `0x005756DD`, `0x0058159E`, `0x006CB452`, `0x006CB8DA`, `0x009DDCE0` — none in `0x0060A000–0x00627400`; (b) `cmp dword [reg+0x10], 5` finds exactly **one** site, `0x009DE1AA`, also outside. With the class set closed at 7 (B47), **no widget class carries tag 5.** |
| **9.2 resolution correction** | **CLOSED.** §P2.4. |
| **9.3 slot array over-allocated?** | **CLOSED — it is not; the OOB is real.** §P2.6. |
| **9.4 two fix-pack candidates** | **CONFIRMED statically, repros written.** §P2.5. Scope is larger than stated: 3 binders, not 1. |
| **9.5 `FUN_00423DC0`'s container** | **STILL OPEN.** `Gui.FindGuiLocation 0x005B3010` does call it, and the container does arrive in ESI (Ghidra drops it). *Static exhaustion:* the ESI value is loaded from a caller frame, not an immediate, so no static def-use chain reaches a global. *Runtime recipe:* one-shot bp at the `call 0x00423DC0` inside `FindGuiLocation`, read ESI, compare with the ESI at the `Player.SetHealthClamp` site — two different values settle it as a generic resolve. |
| **9.6 `playerObj + 0x390`** | **Partly closed statically. NEW: the `+0x450` neighbour is decoded.** `SetPlayerPDAWidget` resolves arg 1 through the container at `0x00DF9B90`, which the ★master key names **`Players`** (`[0x00BC3FB8+0x34] = 0x00647BA0: mov eax,0x00BC5DAC; ret` → `"Players"`). It writes `[player+0x390] = widgetId` *before* validating, caches the player in `DAT_01176120`, and then: **id ≠ 0** ⇒ if `[player+0x398] != 0` call `FUN_004FF150`, then `DAT_00ED9C7C = FUN_00609AE0(app)`, and dispatch event hash **`0xFA62754E`** via `FUN_004BDD10`; **id == 0** ⇒ clear both globals and, **only if `[player+0x450] == 0xFA62754E`**, dispatch event hash **`0x57B5E35A`**. So **`playerObj+0x450` holds an engine event/message name-hash** — the "PDA opened" event id, tested to decide whether the matching "closed" event is worth sending. Both hashes are unresolved names (I did not invent one). *Runtime recipe:* HW write-watchpoints on `player+0x390` and `player+0x450` while opening/closing the PDA. |
| **9.7 base vtable beyond 5 slots** | **CLOSED.** All 31 slots, §P2.3.1. |
| **9.8 `SetMovieFile(uId, nil)`** | **CLOSED in the exe.** `SetMovieFile 0x005BC240` was read this pass: it gates on tag 4 with a `lua_error`, then takes the filename through the *optional* string reader `0x0059FA40` and passes 0 when absent — the same nil-clear shape as `SetFlashSwfFile`. The map's **M** can go to **H**. |
| **9.9 266 vs 339** | **CLOSED.** Independent recount: 341 raw `_GuiInternal.*` matches, of which 2 are `nVersion` ⇒ **339** cfunc sites. The map is right. |

## P2.9 — Findings NEW in Pass 2 (in neither the map nor Pass 1)

**(a) Type gating covers 59 binders, not 5.** The map says "five Flash cfuncs `lua_error` unless
`widget+0x10 == 6`, and `MinimapUpdate` gates on tag 3". Census over all 152 bodies: **64 binders
carry a `cmp dword [w+0x10], <tag>` gate** (tag 1 ×6, tag 2 ×12, tag 3 ×8+, tag 4 ×6, tag 6 ×12+,
tag 7 ×6), and **59 of them raise a Lua error** on mismatch via `FUN_004B2A50` — the uniform shape is
`cmp [esi+0x10],<tag>; jne → lea esi,[esp+X]; call 0x004B2A50`. The five that do not are
`SetPlayerPDAWidget` and `RemoveFlashPauseMenu` (silent return) and the three PDA blip binders
(branchless NULL — the D2 family). **A reimplementation that gates only the five Flash setters will
silently accept ~54 calls the retail engine rejects with an error.**

**(b) Nine base fields the map lists as anonymous "flag bytes" / "zeroed blocks" at L or M now have
names and proofs:** `+0x1C` viewport index · `+0x60` useResolutionCorrection · `+0x61`
relative-to-parent · `+0x62` ignoresPause · `+0x65` on-active-list · `+0x68` fullscreen mode ·
`+0xD1` useNewRescale · `+0xEC` parent pointer · `+0x100` manager active-list node (§P2.3.2).

**(c) `SetWidgetFullscreen` accepts a string, and the mode is a 4-value enum.** §P2.4. The map and
`mercs2_ui` both model it as a boolean.

**(d) The widget manager is a plain 0x88-byte class with two critical sections and NO vtable.**
Because it has no vtable, **the ★`vtable+0x34` master key does not apply to it** — and I verified the
key is not a universal engine convention: on all seven *widget* vtables, `+0x34` is `GetHeight`
(`0x0061AFC0: fld [ecx+0x3C]; fsub [ecx+0x34]`), not a name accessor. The key is specific to the
**ECS container** vtable shape, and it did work there: `0x00DF9B90` → **`Players`**. So the
widget-manager pool has **no self-name to recover**; the honest answer is that it is not an ECS
container. Its allocation site (`0x0060ACD6`) and ctor (`FUN_00618BF0`) are its identity instead.

**(e) The GUI subsystem block on the app singleton is now fully attributed** (from the init function
at `0x0060AC60`): `app+0x1C` = 0x20 B object · `app+0x60` = **0x38 B object, ctor `FUN_00618200`**,
which allocates two 0x808-byte 256-bucket hash tables — consistent with the map's "asset/name
registry", also non-polymorphic · `app+0x64` = 0x14 B render-view object (ctor `FUN_0060EB70`) ·
**`app+0x68` = the 0x88 B widget manager** · `app+0x6C` = **0xCE78 B object with vtable `0x00BBC17C`,
ctor `FUN_0060F2B0`** (the camera subsystem).

**(f) `_DAT_00DF6ACC` is not a trustworthy live-widget count.** A second, non-binding FlashWidget
creator at `0x0060AFC7` allocates `0x4C0`, calls the Flash ctor `0x0061B0A0`, stores the object at
`[edi+0x24]`, then **`sub [0x00DF6ACC], 1`** and unlinks the widget from the global list
(`+0x124/+0x128/+0x12C`). One FlashWidget therefore exists that is invisible to both the counter and
the global list.

**(g) `SplitText` constructs a temporary `TextWidget`.** `FUN_00622380` has exactly two callers:
`CreateTextWidget 0x005B7D5C` and **`0x005B8917`, inside `SplitText`** — which is why `SplitText`
touches `+0x130/+0x134/+0x138/+0x13C/+0x144/+0x150` plus the base `+0x18/+0x1C/+0x58/+0x6C/+0x70`.

**(h) Sprite's relationship to Image is narrower than "derives from".** The ctor chain is real
(`0x00621EC0`'s first instruction is `call 0x0061CF90`, and Sprite's own fields start at `+0x1C0`,
exactly where Image's stop at `+0x1B8`). **But Sprite's vtable is 31 entries and Image's is 43.**
A C++ `Sprite : Image` would inherit all 43. So Sprite **reuses Image's constructor and field
layout** and then overwrites `[this]` with its own base-sized vtable (`0x00621EC7 mov [eax],0xBBCA68`)
and the tag with 7 — it is **not** polymorphically an Image, and calling any Image-specific virtual
(`+0x7C…+0xA8`) on a Sprite reads past the end of its vtable. The map (§3, §8 item 6) and Pass 1
(B22/A4b) both assert the inheritance without this qualification.

**(i) `ActivateWidget` does not validate at all.** `0x005B5B50` passes the raw id straight to
`FUN_00618DD0(mgr, id, bool)`, which performs its own `id<0 / id>cap / slot!=NULL` chain — so it is
safe, but it is the one binder that breaks the map's "one prologue, all 114" claim in §2.

**(j) `MinimapWidget` is `0x1020` bytes** (`MinimapCreate 005B8E4A push 0x1020`) and its vtable has
**63 slots** — by far the largest widget class in both dimensions.

## P2.10 — Adjudication: `scaleform_gfx_class_map.md` §7.2

The hud map's correction is **upheld, and §7.2 is wrong on two counts, not one**:

1. *"The `CreateFlashWidget / SetFlashSwfFile / SendFlashInput / SetFlashCallback /
   CallFlashScriptFunction` Lua binders are **absent from the Ghidra export**"* — **false**. All five
   are present, with header sizes 146 / 295 / 303 / 262 / 662.
2. *"bodies in export gaps `0x60A281–0x60ADF0` and `0x61B540–0x61B8C0`"* — **false**, and not merely
   off by a little: those ranges lie in the **widget-class module**, whereas the five binders live at
   `0x005BA680`, `0x005BA720`, `0x005BAC20`, `0x005BAF90`, `0x005BB170`. §7.2 nominates them for a
   `DecompileProfileAccessors.java` forcing pass that would search the wrong address range.

The hud map's replacement list of genuinely-absent Flash binders is **exactly right** (8 of 15); only
its word "six" is wrong (B46).

## P2.11 — Still open, with proof of static exhaustion

| # | item | why static work cannot close it | runtime recipe (read-only, PAUSED) |
|---|---|---|---|
| 1 | **`FUN_00423DC0`'s container** (map §9.5) | the container arrives in **ESI**, loaded from a caller frame rather than an immediate — no static def-use chain reaches a global | one-shot bp at the `call 0x00423DC0` in `Gui.FindGuiLocation`; read ESI; compare against the `Player.SetHealthClamp` site |
| 2 | **the event hashes `0xFA62754E` / `0x57B5E35A`** (§P2.8 / 9.6) | 32-bit name hashes with no matching string in the image; a hash match alone is not evidence ([[aset-name-export]]) — I did **not** invent a name | dump the event-name registry live, or hash-search the Lua / DLC event-name corpus offline with `tools/pandemic_hash.py` |
| 3 | **the grow path `FUN_00619C00`** | a genuine SecuROM split thunk in **both** images: `jmp [0x0245DCF0]` → `0x028C9000`, still inside `.securom`; the dump's slot is not resolved to `.text` | bp at `0x00619C00` and step into the resolved thunk after the stub has run; or read `[mgr+0x44]`'s heap block header after the first grow |
| 4 | **the callee behind `CallFlashScriptFunction 0x005BB3EA`** | `jmp [0x0245505C]` → `0x024B8740`, a SecuROM stub in `.securom`, unresolved in both images | same technique as (3) |
| 5 | **`+0x14`, `+0x63`, `+0x64`, `+0x80`, `+0xB0..0xCC`, `+0xD0`, `+0xD8/+0xDC`, `+0xE0`, `+0xE8`** on the base widget | no binder reads or writes them; `+0x14` and `+0x63` have vtable accessors that **no** cfunc calls, so there is no static caller to name them from | breakpoint vtbl `+0x40` / `+0x60` / `+0x64` and read the call stack; watch `+0xB0` / `+0xC0` during an `InterpolateWidget` |
| 6 | **the `'o'` / `'p'` / `'f'` fullscreen mode *words*** | the dispatch is on `tolower(s[0])` only — the full strings never appear in the exe, and the shipped Lua only ever passes `"Letterbox"` | none needed for behaviour: the *letters* and the *modes* are proven; the words are cosmetic |
| 7 | **`MovieWidget`'s `0x150`-byte interior** | untouched by any binder beyond `+0x10`; the Bink surface lives behind `FUN_0060xxxx` calls | out of this map's scope — belongs to the movie / LTI map |

Nothing else from Pass 1's open register remains open.

## P2.12 — Reproduction

```bash
# scratchpad/hud2, against output/_ghidra/securom_dump/mercs2_unpacked.exe
python tab.py       # 114 + 38 luaL_Reg rows, terminators, section of every target
python sweep.py     # all 152 bodies -> all_bodies.asm; thunk / indirect-edge census
python slots.py     # binder -> vtable slot, by register dataflow
python vt.py        # all 7 widget vtables, per-slot leaf disassembly + override diff
python xref.py 626DA0 61CF90 622380 61F720 621D80 61B0A0 621EC0   # ctor caller census
python pe.py 618BF0 627DA0 627C00 627620 627270 627360            # manager ctor + rescale core
M2IMG=.../mercs2_nodrm_v3.exe python pe.py 6D5640                 # retail AddObjective stub
```

Single-instruction proofs added by Pass 2:

| VA | text | settles |
|---|---|---|
| `0x00618C45` / `0x00618C63` | `push 0x200` … `mov dword [esi+0x4C], 0x80` | the slot array is **exactly** capacity — the OOB is real (§P2.6) |
| `0x005B6EC6` | `mov byte [ebp+0x60], dl` | `+0x60` = useResolutionCorrection (not "enabled/visible") |
| `0x005B5A86` / `0x005B5B35` | `mov [ebp+0x62], dl` / `mov cl,[ecx+0x62]` | `+0x62` = ignoresPause |
| `0x005BD00F` / `0x005BD139` | `cmp dword [eax+0x10], 6` after `xor eax,eax` | the null-deref is in `UpdatePdaBlip` and `RemovePdaBlip` too |
| `0x006272C3`–`0x006272C8` | `addss xmm1,[esi+0x3C]; movss [esi+0x3C],xmm1` | vtbl `+0x14` moves the **whole** rect (refutes B57's mechanism) |
| `0x00627DAC` / `0x00628209` | `mov eax,[esi+0x1C]` … `call [vtbl+0x24]` | `+0x1C` = viewport index; the rescale writes `+0x40` |
| `0x00647BA0` | `mov eax,0x00BC5DAC; ret` → `"Players"` | ★master key names the `SetPlayerPDAWidget` container |
| `0x00621EC7` | `mov dword [eax], 0xBBCA68` (a 31-slot vtable) | Sprite replaces, not extends, Image's interface |
| `0x0060AFF1` | `sub dword [0x00DF6ACC], esi` | the live-widget counter is decremented by a hidden creator |
| `0x005B90D0` | `E9 0B 00 00 00` → `jmp 0x005B90E0` | `MinimapSetPlayerLocation` is a 5-byte alias (re-confirms B58) |
