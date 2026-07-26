# HUD / GUI widget — PC code map

**Scope:** the **engine binding layer** for the in-game HUD and shell UI — the two `luaL_Reg` tables
that expose Pandemic's retained-mode **widget toolkit** to Lua (`_GuiInternal` at `0x00B99FF8`,
**114 cfuncs — the largest table in the game**; `Gui` at `0x00B9A398`, **38 cfuncs**), the widget
manager singleton behind them, the **seven** widget C++ classes those cfuncs mint, and the widget
object layout. Every name→VA row is recovered, and **all 152 binder rows / 151 distinct bodies are
readable** from the raw image with a disassembler (`MinimapSetPlayerLocation` is a 5-byte alias).
The ⬤/○ column below measures *Ghidra export coverage* (70 of 152), **not** readability — see §4's
legend and §9.

> **Corrected 2026-07-26 (double-blind validation, two passes).** This map previously placed the
> widget **location** rect at `widget+0x50` at confidence **H**. That block is the **colour** RGBA;
> location is **`+0x30..+0x3C`**. The error propagated through §0, §3.1, §3.2 and §8 and is fixed
> throughout. One-instruction proof, verifiable in any disassembler:
> `0x0061AF80: 8D 41 30 C3 → lea eax,[ecx+0x30]; ret` (vtbl `+0x1C`, the slot `Set/GetWidgetLocation`
> call) versus `0x0061AFF0: 8D 41 50 C3 → lea eax,[ecx+0x50]; ret` (vtbl `+0x4C`, the slot
> `GetWidgetColor` calls). Ghidra reports `FUN_0061AF80` as `size=4`, which is how the
> `+0x1C → +0x30` link was missed ([[binding-only-is-not-a-wall-disassemble]]).

**This map does *not* own Scaleform.** `_GuiInternal` is the layer *above* GFx: it mints and drives
widgets, one of which (`FlashWidget`, type tag 6) happens to wrap a `GFxMovieView*`. Everything
inside that wrapper — the AS2 VM, the GFx loader, the renderer HAL, FSCommand — belongs to
[`scaleform_gfx_class_map.md`](scaleform_gfx_class_map.md) and is cited, never re-derived.

**Boundaries with sibling maps** (cited, not re-derived):

| Belongs to | Not here |
|---|---|
| [`scaleform_gfx_class_map.md`](scaleform_gfx_class_map.md) | GFx 2.0.48 itself: `GASValue`/`GASEnvironment`, the CFX loader, `PgScaleform` renderer HAL (vtbl `0xBAD188`), movie lifecycle `FUN_0060D930`/`FUN_0060E4A0`/`FUN_006190B0`, FSCommand `FUN_0060DE80`. §7.2 there owns the `GFxMovieView*` at `flashWidget+0x1E0` |
| [`player_code_map.md`](player_code_map.md) | the player container walk, `Player.SetPDAMapMode` / satellite-scan / `GetTargetUnderReticle` cluster (`0x005DB1E0`–`0x005DBDE0`) — the *player-facing* half of the PDA |
| [`camera_code_map.md`](camera_code_map.md) | the ≤5-viewport array; `Set/GetWidgetViewport` only carries an index into it |
| [`input_code_map.md`](input_code_map.md) | DirectInput8 device read; `SendFlashInput*` only forwards an already-decoded action |
| [`render_core_code_map.md`](render_core_code_map.md) | the LTI/primitive path the widget draw funnels into |
| [`scripting_host_binding_code_map.md`](scripting_host_binding_code_map.md) | the 53-table binding surface as a whole, the arg/push helper set, the forcing-script recovery pass |
| `docs/mercs2-luacd/05_gui_hud_shell.md` | the **Lua** toolkit (`MrxGuiBase`, `MrxGuiManager`, `_G.Hud`, `_G.Pda`) — 69 scripts, already mapped |

**Sources.** PC: the 27k-fn Ghidra decomp `output/_ghidra/mercs2_unpacked.exe_decomp.txt` (unpacked
SecuROM image, base `0x00400000`) — every address cited below was fetched and read first-hand this
pass, or is explicitly marked binding-only. Binding name→VA from the live Surface-B `.rdata` walk
`mods/lua_trace_asi/reference/binding_map.json` ([[lua-trace-asi-surface-b-oracle]]), corroborated by
[`../lua_engine_bindings_audit_deep_dive.md`](../lua_engine_bindings_audit_deep_dive.md). The global
**names** and the boot chunks in §1 were read out of the PE directly
(`output/_ghidra/securom_dump/mercs2_unpacked.exe`, `.data` registry at `0x00DFD478`). Script traffic
is a fresh census over the 370 decompiled scripts in `docs/mercs2-luacd/src`. Xbox side:
[`../mercs2-pdb-analysis/gui-hud.md`](../mercs2-pdb-analysis/gui-hud.md).

**Method / honesty model.** Same discipline as the sibling maps. Confidence: **H** = read body with a
can't-coincide fingerprint (constant, hash, offset, or table walk) · **M** = one strong structural
signal · **L/open** = positional → confirm-live. Where a cfunc has no body in the **Ghidra export** it
is marked *binding-only* (○) — **67 of 114** in `_GuiInternal` and **15 of 38** in `Gui`. Those bodies
are absent from the export because a binding-table-only cfunc has no static caller for Ghidra's
auto-analysis to walk from, not because of SecuROM ([[securom-decompiled-not-a-blocker]]); the whole
cluster sits in clean `.text`. **○ therefore means "unread by Ghidra", not "unreadable"** — all 82
were subsequently read with capstone straight off the raw image and are folded in below.

*Reproduce the readability claim:* parse both `luaL_Reg` tables from `.rdata` (`0x00B99FF8`,
terminator `0x00B9A388`; `0x00B9A398`, terminator `0x00B9A4C8`), take a function extent per target,
disassemble. Three qualifications that matter:

* **`Gui.AddObjective 0x006D5640` is hot-patched in the dump.** In
  `output/_ghidra/securom_dump/mercs2_unpacked.exe` it reads `E9 7B CA 5F 6F → jmp 0x6FCD20C0`, a
  `pmc_bb.dll` hook captured live, *not* engine code. The **retail** body is
  `33 C0 C3 → xor eax,eax; ret` — verified in **both** `mercs2_nodrm_v2.exe` and
  `mercs2_nodrm_v3.exe`. The "shared retail dev stub" reading in §0.5/§5 is correct, and only the
  clean images prove it.
* **One genuine SecuROM split thunk sits *inside* a binder.** `CallFlashScriptFunction` at
  `0x005BB3EA` does `FF 25 5C 50 45 02 → jmp dword ptr [0x0245505C]` → `0x024B8740`, a stub still in
  `.securom` and unresolved in the dump **and** in `nodrm_v3`. The surrounding 870 bytes read fine;
  that one call edge does not. (Three other absolute-indirect edges are plain MSVCR80 imports:
  `SetWidgetFullscreen 0x005B6CC7` and `SetTextJustification 0x005B84AA` → `[0x00B0536C]` =
  `tolower`; `SetFlashPauseMenu 0x005BB5E1` → `[0x00B052EC]` = `strncpy`.)
* **Ghidra under-reports 5 of the 70 exported sizes.** `CallFlashScriptFunction`'s header says
  `size=662`; the real extent is **870** (`0x005BB170`–`0x005BB4D5` inclusive, `CC` padding from
  `0x005BB4D6`) — the export stops exactly at the split-thunk `jmp`. Trap 2, reproduced.

---

## 0. Result in one line

The table at `0x00B99FF8` installs as the Lua global **`_GuiInternal`**, *not* `Hud` — proven from
the PE (`[0x00DFD508] → 0x00BB65E4 = "_GuiInternal"`), and `Hud` is a **Lua-defined** table
(`_G.Hud = HudInterface`, `mrxguiinterface.lua:13`) that would be *clobbered* by installing the
cfuncs under that name (§1.2). The 114 cfuncs are a **thin shim** — 100 % of them share one
prologue: read a widget id, bounds-check it against the **widget manager** at
**`*(DAT_01175FB0 + 0x68)`**, index its dense slot array `+0x44`, and dispatch through the widget's
**vtable**. All the behaviour is in **seven** C++ widget classes living in a *different* module
(`0x0060A000–0x00627400`), whose sizes and vtables are recovered and which are discriminated at
runtime by a **type tag at `widget+0x10`** (0 base · 1 image · 2 text · 3 minimap · 4 movie · 6 flash
· 7 sprite). A widget **uId is a slot index pushed as lightuserdata**, and a widget's **location is a
4-float RECT at `+0x30..+0x3C`** (**`+0x50..+0x5C` is the colour RGBA**) whose far corner is optional
— the exe picks a different vtable slot when only two coordinates are supplied: `+0x10` is an
absolute `SetRect`, `+0x14` **translates the whole rect**, preserving size.
`Gui` (38) is a *different* namespace: reticle/marker/language/loading-hints, and its 13 `_Marker*`
entries are never called directly — the engine itself installs the `Marker.*` alias table from a
**boot chunk string stored beside the binding table** (§1.3).

---

## 0.5 Master marriage table

| Role | Xbox symbol | PC addr | Married by | Conf |
|---|---|---|---|---|
| **`_GuiInternal` `luaL_Reg` table** | — | **`0x00B99FF8`**, 114 entries | name ptr `[0x00DFD508]` → `0x00BB65E4` `"_GuiInternal"`, table ptr `[0x00DFD50C]` = `0x00B99FF8`; read out of the PE | H |
| **`Gui` `luaL_Reg` table** | — | **`0x00B9A398`**, 38 entries | name ptr `[0x00DFD4FC]` → `0x00BB5CC4` `"Gui"` | H |
| **Binding-table name registry** | — | **`0x00DFD478`**, 31 rows × 12 B `{name, table, bootLua}` | walked end-to-end; every row's table VA matches `binding_map.json` | H |
| **`_GuiInternal` cfunc cluster** | — | `0x005B4E80`–`0x005BD0C0` (contiguous) | every table slot lands in the range | H |
| **`Gui` cfunc cluster** | — | `0x005B2D50`–`0x005B4C90` (+ shared stub `0x006D5640`) | ditto; abuts `_GuiInternal` below | H |
| **Widget manager singleton** | `PgGui` | **`*(DAT_01175FB0 + 0x68)`**, object size `0x88`, **no vtable**; slots `+0x44` (`0x200` B = **128 entries**), capacity `+0x4C` = `0x80`, append index `+0x48`, two `CRITICAL_SECTION`s at `+0x50`/`+0x6C` | 40+ cfuncs inline the identical bounds-check + slot index against it; allocated at `0x0060ACD6` (`push 0x88; call 0x0084AC20`), ctor `FUN_00618BF0` — `00618C45 push 0x200` … `00618C63 mov dword [esi+0x4C],0x80` | H |
| **Base `Widget` class** | — | ctor **`FUN_00626DA0`**, vtbl `PTR_FUN_00BBCEE8`, size `0x130`, tag 0 | read ctor; called by all five subclass ctors | H |
| **`ImageWidget`** | — | ctor **`FUN_0061CF90`**, vtbl `PTR_FUN_00BBC878`, size `0x1C0`, tag 1 | `CreateImageWidget` allocs `0x1C0` then calls it | H |
| **`TextWidget`** | — | ctor **`FUN_00622380`**, vtbl `PTR_FUN_00BBCE68`, size `0x170`, tag 2 | ctor registers asset hash **`0x339761F4` = `font_16`** | H |
| **`MinimapWidget`** | `Minimap*` | ctor **`FUN_0061F720`**, vtbl `PTR_FUN_00BBC968` (**63 slots**), size **`0x1020`**, tag 3 | ctor registers **`0x59D0F617` = `MiniMap_Icon_Marker_A`** and **`0x6FD35750` = `MiniMap_Icon_Marker_B`**; size from `MinimapCreate 0x005B8E4A: 68 20 10 00 00  push 0x1020` | H |
| **`MovieWidget`** | `CreateMovieWidget` | ctor **`FUN_00621D80`**, vtbl `PTR_FUN_00BBC9E8`, size `0x150`, tag 4 | `CreateMovieWidget` allocs `0x150` then calls it | H |
| **`FlashWidget`** | `CreateFlashWidget` | ctor **`FUN_0061B0A0`**, vtbl `PTR_FUN_00BBC7F8`, size `0x4C0`, tag 6 | 5 Flash cfuncs `lua_error` unless `widget+0x10 == 6`; ctor zeroes `+0x1DC/+0x1E0` (the `GFxMovieView*` slot the scaleform map pins) | H |
| **`SpriteWidget`** | — | ctor **`FUN_00621EC0`** → *chains `FUN_0061CF90`*, vtbl `PTR_FUN_00BBCA68` (**31 slots**), size `0x200`, tag 7 | ctor calls the Image ctor first ⇒ Sprite **reuses Image's ctor and field layout** — but see the caveat below: it is **not** polymorphically an Image | H |
| **Live widget count** | — | **`_DAT_00DF6ACC`** | `++` in the base ctor at `00626F38`. ⚠ **not a reliable census**: a second, non-binding FlashWidget creator at `0x0060AFC7` allocates `0x4C0`, calls the Flash ctor, then `0060AFF1: 29 35 CC 6A DF 00  sub dword [0x00DF6ACC], esi` (esi = 1) and unlinks the widget from the global list | H |
| **Global widget list head** | — | `PTR_LOOP_00DF6AC0` / `PTR_LOOP_00DF6AC4`, node at `widget+0x124` | base ctor splices itself in | M |
| **Currently-highlighted widget id** | — | **`DAT_01176034`** | `GetWidgetHighlightId` pushes it verbatim as lightuserdata | H |
| **Currently-down widget id** | — | **`DAT_01176038`** | `GetWidgetDownId` pushes it verbatim | H |
| **Player's PDA widget id** | `Pda*` | **`playerObj + 0x390`**; cached in `DAT_01176120` | `SetPlayerPDAWidget` runs the *player-container* walk from `player_code_map.md` §2.1 verbatim, then `005BA5E1: 89 81 90 03 00 00  mov [ecx+0x390], eax` — **before** any validation (§4.1) | H |
| **PDA event name-hash slot** | — | **`playerObj + 0x450`** | `005BA646: cmp dword [ecx+0x450], 0xFA62754E` — the "PDA opened" event id, tested to decide whether to dispatch `0x57B5E35A`. Both hashes unresolved; **no name invented** ([[aset-name-export]]) | H |
| **`SetPlayerPDAWidget`'s container** | — | **`0x00DF9B90` = `Players`** | ★master key: `[0x00DF9B90] = 0x00BC3FB8`; `[0x00BC3FB8+0x34] = 0x00647BA0: B8 AC 5D BC 00 C3  mov eax,0x00BC5DAC; ret` → `"Players"` | H |
| **`Gui.AddObjective`** | `AddObjective` | `0x006D5640` — the **shared retail dev stub** (`33 C0 C3`) | that address backs **62 bindings across 13 tables** (`Debug.*`, `Ai.Temp`, `Junk.Dump*` …). ⚠ in the *dump* image it is a `pmc_bb` hot-patch `jmp 0x6FCD20C0`; read `mercs2_nodrm_v2/v3.exe` for the retail body | H |
| **`Marker.*` alias table** | `Marker*` | installed by the boot-chunk string at **`0x00BB59D8`**, run after `Gui` registers | read verbatim from the PE (§1.3) | H |
| **`_GuiInternal.nVersion = 2`** | — | boot chunk at `0x00BB65C8` | read from the PE; guarded by `mrxguibase.lua:450` | H |

> **The ★`vtable+0x34` master key does not apply to the widget layer.** On all **seven** widget
> vtables `+0x34` is `GetHeight` — `0x0061AFC0: D9 41 3C  D8 61 34  C3 → fld dword [ecx+0x3C];
> fsub dword [ecx+0x34]; ret` — not a name accessor, and the **widget manager has no vtable at all**
> (its ctor's first stores are `00618BF0: mov [esi+4],esi / mov [esi],esi`, a self-linked list head).
> So there is no pool name to recover here: the widget manager is not an ECS container. Its identity
> is its allocation site `0x0060ACD6` and its ctor `FUN_00618BF0`. The key *does* work on the ECS
> container `SetPlayerPDAWidget` walks (`0x00DF9B90` → `Players`, row above) — which is the useful
> negative result: the key is specific to the ECS container vtable shape.

---

## 1. The naming question, settled: `_GuiInternal`, not `Hud`

### 1.1 The registry, read out of the PE

The engine keeps a **31-row registry at `0x00DFD478`**, 12 bytes per row:
`{ const char *globalName, luaL_Reg *table, const char *bootLuaChunk }`. Walking it end-to-end from
`output/_ghidra/securom_dump/mercs2_unpacked.exe` (no decomp involved) gives, in order: `_SYS` `Sys`
`Pg` `Object` `Player` `Event` `Ai` `Human` `Debug` `Vehicle` `Airstrike` **`Gui`** **`_GuiInternal`**
`Graphics` `Sound` `ObjectFilter` `Net` `math` `Camera` `Junk` `ObjectState` `Movie` `Animation` `VO`
`Weapon` `String` `Table` `Report` `Disguise` `FactionZone` `LTILibName`, then a zero terminator at
`0x00DFD5EC`.

```
0x00DFD4FC   name -> 0x00BB5CC4 "Gui"            table = 0x00B9A398   boot -> 0x00BB59D8  (Marker aliases)
0x00DFD508   name -> 0x00BB65E4 "_GuiInternal"   table = 0x00B99FF8   boot -> 0x00BB65C8  "_GuiInternal.nVersion = 2"
```

**There is no `Hud` row.** So the audit label "Hud 114" is wrong and
`lua_engine_bindings_audit_deep_dive.md`'s `_GuiInternal` is right. (Its own §Corrections already
made this call for the *audit*; what is new here is that the name is now read from the PE rather than
inferred from call sites, and that the registry's **third** column — a Lua source chunk `luaL_register`
runs immediately after installing the table — is documented.)

### 1.2 `Hud` is a real Lua global, which is why the mislabel is dangerous

`Hud` exists — as a **Lua** table. `mrxguiinterface.lua:13` does `_G.Hud = HudInterface`, and the
370-script corpus calls `Hud.ObjectiveTray` ×126, `Hud.Radar` ×54, `Hud.ResourceCounter` ×31,
`Hud.MessageBox` ×17, `Hud.SupportMenu`/`Hud.FactionDisplay` ×15 each, and 14 more sub-tables. It is
the *public game-facing façade* two layers above the bindings
(`Hud.*` → `MrxGuiManager` → `MrxGuiBase` → `_GuiInternal.*`, `05_gui_hud_shell.md` §1). Installing
114 engine cfuncs as `Hud` does not merely mislabel a namespace — it **occupies the name the game's
own resident script assigns**, and the two would race on load order.

### 1.3 The boot chunks are engine-authored Lua (and they explain `Marker`)

The `Gui` row's third column, read verbatim from `0x00BB59D8`:

```lua
_G.Marker = {}
_G.Marker.Add                 = Gui._MarkerAddOld
_G.Marker.AddBlip             = Gui._MarkerAdd
_G.Marker.AddTripwire         = Gui._MarkerAddTripwire
_G.Marker.AddDisc             = Gui._MarkerAddDisc
_G.Marker.Add3D               = Gui._MarkerAdd3D
_G.Marker.Remove              = Gui._MarkerRemove
_G.Marker.SetGroupedBlipLimit = Gui._MarkerSetBlipLimit
_G.Marker.SetLocation         = Gui._MarkerSetLocation
_G.Marker.SetColor            = Gui._MarkerSetColor
_G.Marker.SetFollowGuid       = Gui._MarkerSetFollowGuid
_G.Marker.SetScale            = Gui._MarkerSetScale
_G.Marker.Pulse               = Gui._MarkerPulse
_G.Marker.HaltPulse           = Gui._MarkerHaltPulse
```

That settles the `Marker` question by construction: **`Marker` is not a binding table**, it is 13
aliases the engine installs in Lua. The census agrees — `Gui._Marker*` is called **0** times directly,
`Marker.*` **51** times (`Marker.Remove` ×26, `Marker.AddBlip` ×11, `Marker.AddDisc` ×5,
`Marker.Add` ×4, `Marker.Pulse` ×3, `Marker.HaltPulse` ×1, `Marker.AddTripwire` ×1). A reimpl that
installs `Marker` as a namespace of its own is modelling a `_G` assignment as a C table. Note also
`Marker.Add` → `_MarkerAddOld`, i.e. the *legacy* entry point, while `Marker.AddBlip` gets the
current one.

---

## 2. The one prologue: how every widget cfunc resolves its argument

This is the map's central fingerprint. Read in `SetWidgetLocation` `FUN_005B4FA0`,
`SetWidgetCorrectedLocation` `FUN_005B53C0`, `SetWidgetColor` `FUN_005B5560`, `SetWidgetAnchoring`
`FUN_005B5E70`, `SetWidgetUpdateCallback` `FUN_005B6460`, `AddWidgetChild` `FUN_005B66E0`,
`MinimapUpdate` `FUN_005B8EE0`, `SetFlashSwfFile` `FUN_005BA720`, `SetFlashCallback` `FUN_005BAF90`,
`CallFlashScriptFunction` `FUN_005BB170`, `RegisterForPdaUpdate` `FUN_005BC730` — **identical in all
of them** (H):

```c
int id = 0;
if (FUN_005A0000(&id) < 1)                       goto push_nil;   // arg 1: widget uId
mgr = *(int*)(DAT_01175FB0 + 0x68);              // ★ the widget manager
if (id < 0 || *(int*)(mgr + 0x4c) < id)          goto push_nil;   // ← see the off-by-one below
w = *(int**)(*(int*)(mgr + 0x44) + id*4);
if (!w)                                          goto push_nil;
/* type-gated cfuncs only: */
if (*(int*)(w + 0x10) != <tag>)  return FUN_004B2A50(L);          // lua_error
(**(code**)(*w + <slot>))( … );                                   // ★ dispatch through the vtable
```

Three consequences that a reimpl must reproduce:

1. **A widget uId is a dense slot index, not a handle.** `CreateWidget` scans `mgr->slots[0..cap)`
   for the first null, writes the object there, stores the index back at `widget+0x18`, and pushes
   the index as **lightuserdata (Lua tag 2)** — the same tag GUIDs use ([[money-fuel-datatype-and-cap]],
   `player_code_map.md` §3). Slots are **reused**, so a stale uId can resolve to a *different* widget.
2. **An unknown uId is not an error, it is `nil`.** Every accessor pushes nil rather than raising,
   which is why the Lua is full of unguarded `if _GuiInternal.X then` feature probes
   (`mrxguibase.lua:350`, `mrxguicinematic.lua:317`).
3. **Behaviour lives in the vtable, not in the binding.** The cfunc cluster `0x005Bxxxx` contains
   almost no logic; the widget classes are at `0x0060A000–0x00627400`. The base vtable
   `PTR_FUN_00BBCEE8` is **31 slots** (`+0x00 … +0x78`; the dword at slot 31 is ASCII `"Lase…"`, so
   the interface is closed) and is dumped in full in §2.1. Most slots are 2–3-instruction leaves
   that name themselves on sight, so this is **H**, not M.

**Exception to "identical in all of them":** `ActivateWidget` `0x005B5B50` does **not** run the
prologue. It reads the id and a boolean and passes the *raw* id to `FUN_00618DD0(mgr, id, flag)`
(`005B5BF8 call 0x618DD0`), which performs its own `id<0 / id>cap / slot!=NULL` chain. Safe, but it
is the one binder that breaks the "one prologue, all 114" shape.

### 2.1 The base vtable, all 31 slots (H)

Slot bodies read first-hand; the "binder" column is the cfunc whose dispatch lands on that slot.

| slot | base fn | what it is | binder |
|---|---|---|---|
| `+0x00` | `0x00626F70` | scalar-deleting dtor | — |
| `+0x04` | `0x00848E30` | `ret 4` (no-op) | — |
| `+0x08` | `0x00627170` | update/tick | — |
| `+0x0C` | `0x00848E30` | `ret 4` (no-op) | — |
| `+0x10` | `0x00627360` | **SetRect(rect, propagate)** — absolute; `movq [this+0x30]`, `movq [this+0x38]` | `SetWidgetLocation` (4-arg form) |
| `+0x14` | `0x00627270` | **Move(point, propagate)** — `d = arg − [+0x30]`, added to **all four** components | `SetWidgetLocation` (2-arg form) |
| `+0x18` | `0x00627430` | child-propagating transform | — |
| **`+0x1C`** | `0x0061AF80` | **`lea eax,[ecx+0x30]; ret` → &location rect** | `Set/GetWidgetLocation`, `GetWidgetViewport`, `SetSpriteFrameSize` |
| `+0x20` | `0x00974BA0` | `lea eax,[ecx+0x40]; ret` → &corrected rect | `GetWidgetCorrectedLocation` |
| `+0x24` | `0x0061AF90` | **SetCorrectedRect** — copies **exactly 16 bytes** (`movq` ×2) from `[esp+4]` to `[ecx+0x40]` | `SetWidgetCorrectedLocation` |
| `+0x28` | `0x00622550` | switch on `[ecx+0x6C]` (horizontal anchor) | — |
| `+0x2C` | `0x006275B0` | switch on `[ecx+0x70]` (vertical anchor) | — |
| `+0x30` | `0x0061AFB0` | **GetWidth** = `[+0x38] − [+0x30]` | `GetTextWidth` |
| `+0x34` | `0x0061AFC0` | **GetHeight** = `[+0x3C] − [+0x34]` | `GetTextHeight` |
| `+0x38` / `+0x3C` | `0x0061AFD0` / `0x0061AFE0` | **Set/GetHighlightable** ↔ `[ecx+0x15]` | `Set/GetWidgetHighlightable` |
| `+0x40` | `0x009C2B50` | get `[ecx+0x14]` | *(no binder)* |
| `+0x44` | `0x006270A0` | draw/submit (gates on `[+0xE0]`, `[0x01175F2F]`) | — |
| `+0x48` | `0x00627620` | **SetColor(float[4], propagate)** → `[+0x50..+0x5C]` | `SetWidgetColor` |
| **`+0x4C`** | `0x0061AFF0` | **`lea eax,[ecx+0x50]; ret` → &colour** | `GetWidgetColor`, `SplitText` |
| `+0x50` | `0x00627690` | colour-with-children apply | — |
| `+0x54` / `+0x58` | `0x00627700` / `0x0061B000` | **Set/GetVisible** ↔ `[ecx+0x20]` (setter also walks children via `+0xF0`) | `Set/GetWidgetVisible` |
| `+0x5C` | `0x0061B010` | **CorrectForResolution** — `mov eax,[ecx]; mov edx,[eax+0x70]; jmp edx` (tail-calls `+0x70`) | `CorrectWidgetForResolution`, `SetWidgetFullscreen` |
| `+0x60` / `+0x64` | `0x0061B020` / `0x0061B030` | set/get `[ecx+0x63]` | *(no binder)* |
| `+0x68` / `+0x6C` | `0x00627BB0` / `0x0061B040` | **Set/GetSleep** ↔ `[ecx+0x21]` (setter gated on `[+0xE4]`) | `Set/GetWidgetSleep` |
| `+0x70` | `0x00627DA0` | **the rescale core** (1136 B) — §3.5 | *(via `+0x5C`)*; `SetWidgetAnchoring`, `SplitText` |
| `+0x74` | `0x00628210` | scale/zoom helper | — |
| `+0x78` | `0x00628460` | layout/bounds (691 B) | — |

Vtable lengths: Widget 31 · Text 31 · Movie 31 · Flash 31 · **Sprite 31** · **Image 43** · **Minimap 63**.

> **Old claim, corrected:** §2 used to gloss `+0x64` / `+0x6C` as "visibility/parent predicates used
> by the Flash and Movie ctors". `+0x6C` is the **sleep getter** (`0x0061B040: 8A 41 21 C3 →
> mov al,[ecx+0x21]; ret`) and `+0x64` reads the unnamed byte `[ecx+0x63]`.

> **A shipped off-by-one, in every widget cfunc — and it is a real OOB.** The guard is
> `*(int*)(mgr + 0x4c) < id`, i.e. `id > cap` rejects but **`id == cap` passes** and indexes one
> element past the slot array. **§9.3 is now CLOSED: the array is *not* over-allocated.** The manager
> ctor allocates `0x200` bytes = 128 pointers and sets capacity to exactly `0x80`
> (`00618C45 push 0x200` … `00618C63 mov dword [esi+0x4C], 0x80`), and the zero-fill loop and
> `CreateWidget`'s free-slot scan both run `i ∈ [0, [+0x4C])`. So `slots[capacity]` is a **4-byte heap
> over-read one element past a 512-byte block, reachable from any script that passes
> `id == capacity`** — and the garbage pointer it loads is then dereferenced (`[w+0x10]`, `[w]` …).
> Not benign. (The *grow* path `FUN_00619C00` is a genuine SecuROM split thunk —
> `jmp [0x0245DCF0]` → `0x028C9000`, still in `.securom` in **both** images — so the grow arithmetic
> is not statically available; the question is closed by the **initial** allocation instead.)
>
> **Three binders make it worse by dereferencing NULL outright.** On the failure path they
> `xor eax,eax`, control **merges**, and the very next access is unguarded:
>
> | binder | VA | fail path | faulting instruction |
> |---|---|---|---|
> | `AddPdaMapBlips` | `0x005BCE70` | `005BCEE8 xor eax,eax` | `005BCEEF: 83 78 10 06  cmp dword [eax+0x10], 6` |
> | `UpdatePdaBlip` | `0x005BCF90` | `005BD008 xor eax,eax` | `005BD00F: 83 78 10 06  cmp dword [eax+0x10], 6` |
> | `RemovePdaBlip` | `0x005BD0C0` | `005BD135 xor eax,eax` | `005BD139: 83 78 10 06  cmp dword [eax+0x10], 6` |
>
> All three then use the branchless `setne bl / sub ebx,esi / and ebx,eax` idiom to pass `0` to the
> callee — which is *why* they have no null check: the author folded "not a flash widget ⇒ NULL" into
> arithmetic and overlooked that the tag read itself dereferences. Every other widget binder does
> `test reg,reg / jne` first (`SetWidgetLocation 005B5018`, `DeleteWidget 005B4F89`,
> `GetWidgetVisible 005B598F`, …). **Two reaching conditions**, not one: the range check fails, *or*
> it passes on a slot holding NULL (a deleted widget — reachable because ids are reused;
> `FUN_00618D50 = Manager::Delete` clears `slots[id]` and resets `widget+0x18 = -1`).
> Fix-pack candidate, scope **three** binders (§9.4).

---

## 3. The widget class family

All seven creators are the same 146–149-byte template (alloc → ctor → claim slot → push id),
differing only in the allocation size and the ctor called. That is what pins the class table (H):

| Lua cfunc | alloc size | ctor | vtable | slots | tag `+0x10` | Relationship |
|---|---:|---|---|--:|:-:|---|
| `CreateWidget` `0x005B4E80` | `0x130` | `FUN_00626DA0` | `PTR_FUN_00BBCEE8` | 31 | 0 | — |
| `CreateImageWidget` `0x005B7070` | `0x1C0` | `FUN_0061CF90` | `PTR_FUN_00BBC878` | **43** | 1 | Widget |
| `CreateTextWidget` `0x005B7D40` | `0x170` | `FUN_00622380` | `PTR_FUN_00BBCE68` | 31 | 2 | Widget |
| *(`MinimapCreate` `0x005B8CB0`, ○)* | **`0x1020`** | `FUN_0061F720` | `PTR_FUN_00BBC968` | **63** | **3** | Widget |
| `CreateMovieWidget` `0x005BC1A0` | `0x150` | `FUN_00621D80` | `PTR_FUN_00BBC9E8` | 31 | 4 | Widget |
| `CreateFlashWidget` `0x005BA680` | `0x4C0` | `FUN_0061B0A0` | `PTR_FUN_00BBC7F8` | 31 | **6** | Widget |
| `CreateSpriteWidget` `0x005BB7B0` | `0x200` | `FUN_00621EC0` | `PTR_FUN_00BBCA68` | 31 | 7 | **reuses Image's ctor — see below** |

**The class set is closed at seven, by exhaustion (H).** A byte-level scan of `.text` for
`E8 rel32 → 0x00626DA0` finds **exactly six** call sites: `0x005B4E9A` (`CreateWidget`) plus the five
subclass ctors `0x0061B0AC`, `0x0061CF90`, `0x0061F72D`, `0x00621D83`, `0x00622382`. Sprite reaches
the base ctor only through the Image ctor (`0x0061CF90` has exactly two callers: `0x005B708A` and
`0x00621EC0`). The base `Widget` is a real instantiable class with its own binder, ctor, vtable,
size and tag — earlier revisions of this map said "six classes" while listing seven.

> **Sprite does NOT derive from Image in the vtable sense — corrected.** The ctor chain is real
> (`00621EC0: E8 CB B0 FF FF  call 0x0061CF90` is Sprite's first instruction, and Sprite's own fields
> start at `+0x1C0`, exactly where Image's stop at `+0x1B8`). **But Sprite's vtable is 31 entries and
> Image's is 43.** A C++ `Sprite : Image` would inherit all 43. Sprite therefore **reuses Image's
> constructor and field layout**, then overwrites `[this]` with a base-sized vtable
> (`00621EC7: C7 00 68 CA BB 00  mov dword [eax], 0xBBCA68`) and the tag with 7. Calling any
> Image-specific virtual (`+0x7C…+0xA8`) on a Sprite reads past the end of its vtable.

**Tag 5 is unassigned — CLOSED by exhaustion (H), no longer open.** Two independent byte-level
censuses over `.text`: (a) `C7 /0 disp8=0x10 imm32=5` (`mov dword [reg+0x10], 5`) finds **five** sites
— `0x005756DD`, `0x0058159E`, `0x006CB452`, `0x006CB8DA`, `0x009DDCE0` — **none** inside the widget
module `0x0060A000–0x00627400`; (b) `83 /7 disp8=0x10 imm8=5` (`cmp dword [reg+0x10], 5`) finds
**exactly one**, `0x009DE1AA`, also outside. Combined with the closed class set above, **no widget
class carries tag 5.** (For calibration the same scan finds the seven real tags exactly where
expected: `0x00626DB5` (0) · `0x0061CFD6` (1) · `0x006223D1` (2) · `0x0061F977` (3) · `0x00621DBB` (4)
· `0x0061B12F` (6) · `0x00621F64` (7).)

`MinimapCreate`'s own body is not decompiled, but the minimap ctor `FUN_0061F720` records exactly one
caller — `0x005B8E9C`, which lies inside `[0x005B8CB0, 0x005B8EE0)` = `MinimapCreate`. That, plus
`MinimapUpdate` `FUN_005B8EE0` gating on `widget+0x10 == 3`, pins the class without reading the
binding (H).

**Three ctor fingerprints worth keeping** (all H, hashes resolved against
`docs/data/aset_block_strings.json` / `aset_discovered_names.json`):

- `TextWidget` seeds its font to asset hash **`0x339761F4` = `font_16`** and registers it through
  `thunk_FUN_024EEE40(*(DAT_01175FB0 + 0x60), hash)`.
- `MinimapWidget` registers **three** assets through `thunk_FUN_028E1000`: a caller-supplied hash plus
  the two constants **`0x59D0F617` = `MiniMap_Icon_Marker_A`** and **`0x6FD35750` = `MiniMap_Icon_Marker_B`**.
  It also zeroes a **0xC0-dword (768 B) block at `+0x4E4`** — the blip/objective array. (The old
  "≥ `0x7E4` bytes" inference is superseded: the true size is **`0x1020`**, read straight off
  `MinimapCreate 0x005B8E4A push 0x1020`, making Minimap the largest widget class in both size and
  vtable length.)
- `MinimapWidget` **self-centres on construction**: it reads its own rect via vtbl `+0x1C`, computes
  `half = (x2 - x1) * 0.5`, and offsets the supplied point by `-half` on both axes.

`*(DAT_01175FB0 + 0x60)` is therefore the **asset/name registry** the widget classes pin textures
through; `DAT_01175FB0` is the engine app singleton already carrying the render-view handle at `+0x64`
([`../render_view_handle_crash_analysis.md`](../render_view_handle_crash_analysis.md) §4) and a camera
sub-system at `+0x6C` ([`camera_code_map.md`](camera_code_map.md) §3). `+0x68` = GUI is this map's
addition.

### 3.1 Base `Widget` layout (size `0x130`, from `FUN_00626DA0`, read instruction-by-instruction)

**This table was wrong before 2026-07-26** — it placed the location rect at `+0x50` (the colour
block) at confidence **H**, and graded the row that actually *is* the location (`+0x30`) **L**. Both
are now pinned by their vtable accessor *and* their ctor default, and the ctor defaults alone settle
which is which: a rect of `(0,0,0,0)` and a colour of `(1,1,1,1)` = opaque white are both sensible;
the reverse is not.

| Off | Sz | Field | Init | Evidence | Conf |
|---|--:|---|---|---|---|
| `+0x00` | 4 | vtable | per class | `00626DAF mov dword [eax], 0xBBCEE8` | H |
| **`+0x10`** | 4 | **type tag** (table above) | `0` | `00626DB5` | H |
| `+0x14` | 1 | unnamed flag | `0` | `00626F5C`; getter vtbl `+0x40`, **no cfunc calls it** | L |
| **`+0x15`** | 1 | **highlightable** | `0` | vtbl `+0x38`/`+0x3C` = `0x0061AFD0`/`0x0061AFE0` → `[ecx+0x15]`; called by `Set/GetWidgetHighlightable` | H |
| **`+0x18`** | 4 | **slot id / uId** | `-1` | `00626DB8 mov dword [eax+0x18], 0xFFFFFFFF`; `CreateWidget 005B4ED7` writes the claimed index | H |
| **`+0x1C`** | 4 | **viewport index** | `0` | `00626E6F`; `Get/SetWidgetViewport`; the rescale core indexes `[0x00DFC2F8]` with it at stride `0xE80` (`00627DAC`) and `< 0` short-circuits | H |
| **`+0x20`** | 1 | **visible** | `1` | `00626DBF`; vtbl `+0x54`/`+0x58` = `0x00627700`/`0x0061B000` → `[ecx+0x20]`; called by `Set/GetWidgetVisible` | H |
| **`+0x21`** | 1 | **sleep** | `0` | `00626DC3`; vtbl `+0x68`/`+0x6C` = `0x00627BB0`/`0x0061B040` → `[ecx+0x21]`; called by `Set/GetWidgetSleep` | H |
| **`+0x30..+0x3C`** | 16 | **location RECT `[x1,y1,x2,y2]`** | **`0,0,0,0`** | `00626E84 movq [eax+0x30], xmm1(0)` + `00626EA8`; vtbl `+0x1C` = `0x0061AF80: lea eax,[ecx+0x30]; ret`; SetRect `0x00627360` writes it | H |
| **`+0x40..+0x4C`** | 16 | **corrected (screen-space) RECT** | `0,0,0,0` | `00626E89` + `00626EAD`; vtbl `+0x20` = `0x00974BA0: lea eax,[ecx+0x40]`; vtbl `+0x24` writes it; the rescale core stores its result through `+0x24` at `00628209` | H |
| **`+0x50..+0x5C`** | 16 | **colour RGBA (0..1)** | **`1,1,1,1`** (`[0x00B9B664]`) | `00626ED0`/`00626EDB`; vtbl `+0x4C` = `0x0061AFF0: lea eax,[ecx+0x50]; ret`; SetColor `0x00627620` writes `+0x50..+0x5C` | H |
| **`+0x60`** | 1 | **useResolutionCorrection** | **`1`** | `00626DC6 mov byte [eax+0x60], 1`; **`SetWidgetUseResolutionCorrection` writes it — `005B6EC6: 88 55 60  mov [ebp+0x60], dl`**; the rescale core branches on it six times, and vtbl `+0x14`'s child walk gates on it at `006272E8` | H |
| **`+0x61`** | 1 | **position relative to parent** | `0` | `00626DCA`; `00627DE1`: if set **and** `+0xEC` non-null, the rescale frame becomes the *parent's* two rects | H |
| **`+0x62`** | 1 | **ignoresPause** | `0` | `00626DCD`; `SetWidgetIgnoresPause 005B5A86: 88 55 62  mov [ebp+0x62], dl`; `GetWidgetIgnoresPause 005B5B35: 8A 49 62  mov cl,[ecx+0x62]` | H |
| `+0x63` | 1 | unnamed flag | `0` | `00626DD0`; vtbl `+0x60`/`+0x64` accessors exist but **no cfunc calls them** | L |
| `+0x64` | 1 | unnamed flag | `0` | `00626DD3` | L |
| `+0x65` | 1 | **on manager's active list** | `0` | `00626DD6`; set at `0x00618E37` when the widget is spliced into `mgr+0x10` | M |
| **`+0x68`** | 4 | **fullscreen / rescale mode, 0..3** | `0` | `00626DD9`; `SetWidgetFullscreen` writes 0/1/2/3; the rescale core switches on it at `00627F38` (§3.5) | H |
| **`+0x6C`** | 4 | **horizontal anchor** (0 left / 1 right / 2 centre) | `0` | `00626DDC`; `SetWidgetAnchoring`; vtbl `+0x28` switches on it | H |
| **`+0x70`** | 4 | **vertical anchor** (3 top / 4 bottom / 2 centre) | **`3`** | `00626DDF mov dword [eax+0x70], 3`; vtbl `+0x2C` | H |
| `+0x78`,`+0x7C`,`+0x80`(b) | — | zeroed | 0 | `00626DE6`–`00626DEC` | L |
| `+0xB0..+0xBC`, `+0xC0..+0xCC` | 32 | two float quads | `0.0` | `00626F00`–`00626F18`, `00626EE0`–`00626EF8` | L |
| `+0xD0` | 1 | flag | 0 | `00626DF2` | L |
| **`+0xD1`** | 1 | **useNewRescale** | `0` | `00626DF8`; `SetWidgetUseNewRescale` → `FUN_00627C00` writes `[this+0xD1]` at `0x00627C0C` and **recurses over the whole child subtree** through `+0xF0` | H |
| `+0xD8`,`+0xDC` | 8 | zeroed | 0 | `00626DFE` | L |
| `+0xE0` | 1 | draw-gate flag | 0 | `00626F26`; tested by vtbl `+0x44` | M |
| **`+0xE4`** | 4 | **pending/refcount** — `++` by the Flash and Movie ctors, gates vtbl `+0x68` | 0 | `00626F2C`; `0061B223`, `00621D8A` | M |
| `+0xE8` | 1 | flag | 0 | `00626F32` | L |
| **`+0xEC`** | 4 | **parent widget pointer** | `0` | `00626F20`; dereferenced by the rescale core at `00627E1D`/`00627E2E` through the parent's vtbl `+0x1C`/`+0x20` | H |
| `+0xF0..+0xFC` | 16 | **child list head**, self-linked; node `{next, prev, owner@+8}` | self | `00626E16 lea edx,[eax+0xF0]; mov [edx+4],edx; mov [edx],edx`; walked by SetVisible / SetColor / `FUN_00627C00` | H |
| `+0x100..+0x120` | 36 | **manager active-list node** | 0 | `00626E21`–`00626E51`; `0x00618E29` splices `+0x100` into `mgr+0x10` | M |
| `+0x124..+0x12C` | 12 | **global widget list node** `{next, prev, owner}` (`PTR_LOOP_00DF6AC0/4`) | spliced | `00626E69`, `00626F3F`–`00626F5A` | H |
| `+0x130` | — | end of base object | — | `CreateWidget push 0x130` | H |

**Width and height are derived, never stored** — vtbl `+0x30` = `[+0x38] − [+0x30]` and
vtbl `+0x34` = `[+0x3C] − [+0x34]` (`0x0061AFB0`, `0x0061AFC0`), which is *why* `GetTextWidth` /
`GetTextHeight` exist as bindings. A reimpl that stores `w`/`h` alongside `x`/`y` desynchronises the
moment vtbl `+0x14` runs.

Also global: **`_DAT_00DF6ACC` is incremented once per widget construction** (`00626F38`) — but see
the caveat in §0.5: one non-binding creator decrements it back, so it is not a trustworthy census.

**Subclass field extents** (from each ctor plus the binders that touch them):

| class | size | tag | fields |
|---|---|:-:|---|
| Image | `0x1C0` | 1 | `+0x140/+0x144/+0x148/+0x14C` tex-coords · `+0x150` rotation · `+0x160..0x170`, `+0x180..0x190` float blocks · `+0x194`(b) · `+0x1A0/+0x1A8/+0x1AC` · `+0x1B0/+0x1B4` · `+0x1B8`(b) pie-slice |
| Text | `0x170` | 2 | `+0x130` text · `+0x134` · **`+0x138` font asset hash `0x339761F4`** (`006223C1`) · `+0x13C` wrapping · `+0x13E/+0x13F` · `+0x144` scale · `+0x14C`/`+0x154` animation · `+0x150` justification |
| Minimap | `0x1020` | 3 | `+0x148` rotation · `+0x168/+0x16C` owner · `+0x190/+0x194/+0x198` focus point · `+0x19C` range · `+0x1A4/+0x1AC/+0x1B0` border · **`+0x4E4` 0xC0-dword zeroed block** (`0061F74E`) · hashes `0x59D0F617` (`0061F831`), `0x6FD35750` (`0061F849`) |
| Movie | `0x150` | 4 | interior unmapped — no binder touches it beyond `+0x10` (belongs to the movie / LTI map) |
| Flash | `0x4C0` | 6 | `+0x1D0` play speed · `+0x1D8/+0x1DC/+0x1E0` name-hash / asset / `GFxMovieView*` · `+0x4A4/+0x4A8/+0x4B4` left analog · `+0x4AC/+0x4B0/+0x4B5` right analog |
| Sprite | `0x200` | 7 | reuses Image's `+0x130..+0x1B8`, adds `+0x1C0`(b)/`+0x1C1`(b) · `+0x1C4/+0x1C8/+0x1CC/+0x1D0` (init from `[0x01176710]`/`[0x01176714]`) · `+0x1D4/+0x1D8` · `+0x1DC` = 100.0 · `+0x1E0..+0x1F0` · `+0x1F4`(b)/`+0x1F5`(b) |

### 3.2 The location is a RECT, and the far corner is optional — H

`SetWidgetLocation` `FUN_005B4FA0` reads the **current** rect first
(`puVar2 = (**(code**)(*w + 0x1C))(); uStack_20 = puVar2[0]; uStack_18 = puVar2[1];` — **16 bytes,
four floats**), then overlays up to four *optional* numeric args (`FUN_0059F780` returns `< 1` when
absent) plus a trailing optional boolean (`FUN_0059F6D0`, defaulting to **1**), and finally branches:

```c
if (arg1 && arg2 && !arg3 && !arg4)  (**(code**)(*w + 0x14))(&pt,  flag);   // 2-value form
else                                 (**(code**)(*w + 0x10))(&rect, flag);  // 4-value form
```

This corroborates the Lua-side finding first-hand: `Widget:GetLocation()` (`mrxguibase.lua:759`)
destructures **four** values because `GetWidgetLocation` returns the whole rect.
`Widget:SetCoordinates` (`mrxguibase.lua:755`) exploits exactly this by round-tripping
`GetWidgetLocation` and passing `x or nX1` per component.

**What the two virtuals actually do — corrected.** An earlier reading framed the 2-value form as
"position, auto-size". The *base* implementations are simpler and neither auto-sizes:

* **`+0x10` = `0x00627360` — absolute `SetRect`**: overwrites all four floats
  (`movq [esi+0x30]`, `movq [esi+0x38]`).
* **`+0x14` = `0x00627270` — `Move`, preserving size**: computes `d = arg − [esi+0x30]` and adds `d`
  to **all four** components. The far corner is *not* left behind:

  ```
  006272AD  movss [esp+0xc], xmm0
  006272B3  addss xmm0, [esi+0x38]      ; x2 += dx
  006272B8  movss [esi+0x38], xmm0
  006272BD  movss [esp+0x10], xmm1
  006272C3  addss xmm1, [esi+0x3c]      ; y2 += dy      <-- decisive
  006272C8  movss [esi+0x3c], xmm1
  ```

  A reimpl that translates only `+0x30`/`+0x34` would **silently resize every widget it moves**.
  Both virtuals then tail into vtbl `+0x70` (the rescale core, §3.5) and propagate the delta to
  children through `+0xF0` when the flag is set. Auto-sizing, if it exists, is a subclass override —
  the *default* is size-preserving translation, and that is the behaviour to implement first.

`SetWidgetCorrectedLocation` `FUN_005B53C0` is the resolution-corrected sibling: it reads its
argument via `FUN_0059FD20`, raises a Lua error if the read fails, and calls vtbl `+0x24`
(`005B548D mov edx,[edx+0x24]` … `005B5490 lea eax,[esp+0x20]; push eax; call edx`).
**The old "single 28-byte struct" reading is wrong** — it was a mis-read of the stack frame. Vtbl
`+0x24` = `0x0061AF90` is 26 bytes long and copies **exactly 16 bytes** (`movq` ×2) from `[esp+4]` to
`[ecx+0x40]`: the argument is a **4-float rect**, the same shape as everywhere else.

### 3.3 Colour: 0–255 in, **any negative** means "leave unchanged" — H

`SetWidgetColor` `FUN_005B5560` reads four optional numbers whose **absent-argument default is
`DAT_00BEB2E4 = -255.0f`**, scales by **`DAT_00BAC8BC = 1/255`**, and calls vtbl `+0x48` *only if at
least one channel was supplied*. The Lua side is the other half of the fingerprint:

```lua
function Widget:SetTranslucency(level, bSuppressPropogation)
  _GuiInternal.SetWidgetColor(self.BasicData.uId, -255, -255, -255, level, not bSuppressPropogation)
end                                            -- mrxguibase.lua:783
```

So the contract is: **channels are 0–255, the engine normalises to 0–1, and the per-channel
"don't touch" test is a plain sign test.** The base implementation vtbl `+0x48` = `0x00627620` makes
this exact — it is **not** an equality test against `-255`:

```
00627628  movss  xmm1, [edi]        ; r
0062762C  comiss xmm1, xmm0        ; xmm0 = 0.0
0062762F  jb     0x627636          ; r < 0  ->  SKIP the store
00627631  movss  [ecx + 0x50], xmm1
   ... identical for +0x54 (g), +0x58 (b), +0x5C (a)
```

`-255 × 1/255 = -1.0`, so the canonical Lua sentinel lands below zero — but **so does every other
negative**, and a NaN is skipped too (`comiss` unordered sets CF). A reimpl that special-cases the
literal `-255` diverges everywhere else. `GetWidgetColor` `0x005B5750` is the inverse: it reads vtbl
`+0x4C` (`this+0x50`), multiplies each channel by `[0x00BEA9C0] = 255.0`, and pushes four floats.
The trailing boolean (default **true**) is *propagate to children* — `Widget:SetColor` passes
`not bSuppressPropogation`. (H throughout; the destination offsets are now read from the writer
rather than inferred.)

### 3.4 Anchoring is a 5-value enum split across two fields — H (was M)

`SetWidgetAnchoring` `FUN_005B5E70` reads two optional numbers and buckets each against
`DAT_00DFDCA4 = -0.5f` and `DAT_00BBB99C = +0.5f`, writing `widget+0x6C` (horizontal) and
`widget+0x70` (vertical):

| Value | ⟶ horizontal (`+0x6C`) | ⟶ vertical (`+0x70`) |
|---|---|---|
| `< -0.5` | **0** (left) | **3** (top) |
| `-0.5 … +0.5` | **2** (centre) | **2** (centre) |
| `> +0.5` | **1** (right) | **4** (bottom) |

`2` is shared by both axes as "centre", and the base ctor defaults `+0x70 = 3` (top) / `+0x6C = 0`
(left). The *values* are read directly out of `0x005B5F30`–`0x005B5FC3` and the fields are the ones
vtbl `+0x28` / `+0x2C` switch on, so the mapping is **H**; only the English *labels* are inferred
from the ordering and the ctor default.

### 3.5 The resolution-correction model, recovered — H (was §9.2, "the largest unread area")

Six binders, one virtual, one core routine. Nothing here needed a forcing pass or a debugger; the
bodies were simply never in the Ghidra export.

**Inputs on the widget:** `+0x1C` viewport index · `+0x30..0x3C` authored rect · `+0x60`
useResolutionCorrection · `+0x61` relative-to-parent · `+0x68` mode · `+0x6C`/`+0x70` anchors ·
`+0xD1` useNewRescale · `+0xEC` parent. **Output:** `+0x40..0x4C`.

**`Widget::CorrectForResolution` = vtbl `+0x70` = `FUN_00627DA0`** (1136 B), reached through the
7-byte tail-jump at vtbl `+0x5C` (`0x0061B010: mov eax,[ecx]; mov edx,[eax+0x70]; jmp edx`):

1. `vp = [this+0x1C]` (`00627DAC mov eax,[esi+0x1C]`). **`vp < 0` ⇒ bail** with a degenerate rect
   built from `0` and `[0x00B92870] = 100.0`, still stored through `+0x24`.
2. Otherwise `vpDesc = [0x00DFC2F8] + vp*0xE80` (`00627DD5`/`00627DDB imul eax, eax, 0xE80`); screen
   `W = (float)[vpDesc+0x28]`, `H = (float)[vpDesc+0x2C]`; pixel-aspect from `[[0x00DFC2F8]+0x2BD0]`.
   The `0xE80` stride marries this to the viewport array in
   [`camera_code_map.md`](camera_code_map.md).
3. **Reference frame.** If `[this+0x61] && [this+0xEC]` (`00627DE1`) → frame-A = the parent's vtbl
   `+0x1C` rect, frame-B = the parent's vtbl `+0x20` rect. Otherwise frame-A is the **640×480 design
   space** (`[0x00BEAC58] = 640.0`, `[0x00BEAAC8] = 480.0`) and frame-B is the viewport.
4. `sx = (B.x2−B.x1)/(A.x2−A.x1)`, `sy = (B.y2−B.y1)/(A.y2−A.y1)`; the vertical unit is
   `H × [0x00BEA95C]`, and **`[0x00BEA95C] = 0.0020833334 = 1/480`**.
5. **Mode switch on `[this+0x68]`** at `00627F38`:
   * **0** → the anchor path (`0x0062801D`): switch `[+0x6C]` (0/1/2) then `[+0x70]` (2/3/4), each
     branch gated on `[+0x60]`.
   * **1** → fullscreen: rect = `(0, 0, W×aspect, H)`.
   * **2** → **letterbox**: height = `(1/aspect) × (W×aspect) × 0.5625`, centred
     (`[0x00BEAE54] = 0.5625 = 9/16`, `[0x00BBB99C] = 0.5`).
   * **3** → pillarbox: half-width / half-height centring on `0.5`.
6. Store (`006281F7`–`00628209`): `mov eax,[esi]; mov edx,[eax+0x24]; lea ecx,[esp+0x40]; push ecx;
   call edx` — i.e. **the same `SetCorrectedLocation` virtual `SetWidgetCorrectedLocation` calls**,
   writing `+0x40..0x4C`. That is why the corrected rect is both a renderer input and a
   script-writable field.

**`SetWidgetFullscreen(id, arg)` `0x005B6BC0` takes a boolean *or a string*** — the map and
`mercs2_ui` both modelled it as a boolean, and it is a **4-value enum**. The boolean path sets mode
0 or 1 (`005B6C88 mov [ebp+0x68], ecx`). If arg 1 is not a boolean it is read as a string
(`005B6CA2 call 0x59FA40`; absent ⇒ `lua_error`) and dispatched on the **first character only**:

```
005B6CC3  movsx eax, byte ptr [edx]      ; s[0]
005B6CC7  call  dword ptr [0xb0536c]     ; MSVCR80!tolower
005B6CCD  add   eax, -0x66               ; 'f'
005B6CD3  cmp   eax, 0xa
005B6CD6  ja    0x5b6d3d                 ; out of range -> no-op
005B6CD8  movzx ecx, byte ptr [eax + 0x5b6d5c]   ; index table
005B6CDF  jmp   dword ptr [ecx*4 + 0x5b6d48]     ; jump table
```

The index table at `0x005B6D5C` reads `00 04 04 04 04 04 01 04 04 02 03` for `f g h i j k l m n o p`,
and the jump table at `0x005B6D48` is `{0x005B6D05, 0x005B6D1F, 0x005B6CE6, 0x005B6D26, 0x005B6D3D}`:

| first letter | target | mode written | corroboration |
|---|---|:-:|---|
| `'f'` | `0x005B6D05` (`mov [ebp+0x68], esi`, esi = 1) | **1** | the boolean-`true` path sets the same value |
| `'l'` | `0x005B6D1F` (`mov eax, 2`) | **2** | **`SetFullscreen("Letterbox")` ×8 in the Lua corpus** — proven |
| `'o'` | `0x005B6CE6` (`mov dword [ebp+0x68], 0`) | **0** | letter proven; word inferred ("Off"/"None") |
| `'p'` | `0x005B6D26` (`mov eax, 3`) | **3** | letter proven; word inferred ("Pillarbox" — it is the centring branch) |
| `g,h,i,j,k,m,n` | `0x005B6D3D` | — | no-op |

Each mode change calls vtbl `+0x5C` to recompute immediately. **`SetWidgetUseResolutionCorrection`
`0x005B6E10`** is a plain byte write with **no** recompute (`005B6EC6 mov [ebp+0x60], dl`).
**`SetWidgetUseNewRescale` `0x005B6EE0`** → `FUN_00627C00`, which writes `[this+0xD1]` and recurses
over the whole child subtree through `+0xF0`.

---

## 4. The `_GuiInternal` binding surface — all 114, name → VA

`luaL_Reg` table **`0x00B99FF8`**, 0 stubs (no slot points at the shared dev stub `0x006D5640`).
Cfuncs are `undefined4 f(lua_State *L)`; arg readers `FUN_005A0000` (widget uId / int),
`FUN_0059F780` (optional number), `FUN_0059F6D0` (optional boolean), `FUN_0059FA40` / `FUN_0059FB00`
(string), `FUN_0059FD20` (struct), `FUN_0059FF50` (lightuserdata/GUID), `thunk_FUN_024E5E50`
(Lua function ref); results via `FUN_0085D5D0` (reserve) + the `*(L+8) += 8` push idiom; errors via
`FUN_004B2A50`. Same helper set as `player_code_map.md` §3.

**⬤ = present in the Ghidra export (47)** · ○ = absent from the export, no static caller (67) —
**all 67 are nevertheless readable** and were read from the raw image · *calls* = qualified
`_GuiInternal.X` call sites across the 370 scripts in `docs/mercs2-luacd/src`.

| # | Name | VA | | calls | | # | Name | VA | | calls |
|--:|---|---|:-:|--:|---|--:|---|---|:-:|--:|
| 0 | `CreateWidget` | `0x005B4E80` | ⬤ | 2 |  | 57 | `SetTextJustification` | `0x005B83E0` | ○ | 2 |
| 1 | `DeleteWidget` | `0x005B4F20` | ○ | 4 |  | 58 | `GetTextJustification` | `0x005B84F0` | ○ | 2 |
| 2 | `SetWidgetLocation` | `0x005B4FA0` | ⬤ | 6 |  | 59 | `SetTextScale` | `0x005B85F0` | ○ | 2 |
| 3 | `GetWidgetLocation` | `0x005B51A0` | ○ | 4 |  | 60 | `GetTextScale` | `0x005B86D0` | ○ | 2 |
| 4 | `GetWidgetHighlightable` | `0x005B5310` | ○ | 0 |  | 61 | `SplitText` | `0x005B8790` | ⬤ | 4 |
| 5 | `SetWidgetHighlightable` | `0x005B5250` | ○ | 2 |  | 62 | `AnimateText` | `0x005B8AC0` | ⬤ | 4 |
| 6 | `SetWidgetCorrectedLocation` | `0x005B53C0` | ⬤ | 4 |  | 63 | `HaltTextAnimation` | `0x005B8BE0` | ○ | 4 |
| 7 | `GetWidgetCorrectedLocation` | `0x005B54B0` | ○ | 4 |  | 64 | `MinimapCreate` | `0x005B8CB0` | ○ | 2 |
| 8 | `SetWidgetColor` | `0x005B5560` | ⬤ | 4 |  | 65 | `MinimapUpdate` | `0x005B8EE0` | ⬤ | 2 |
| 9 | `GetWidgetColor` | `0x005B5750` | ⬤ | 4 |  | 66 | `MinimapSetPlayerLocation` | `0x005B90D0` | ○ | 2 |
| 10 | `SetWidgetVisible` | `0x005B5850` | ○ | 4 |  | 67 | `MinimapSetFocusLocation` | `0x005B90E0` | ⬤ | 2 |
| 11 | `GetWidgetVisible` | `0x005B5920` | ○ | 2 |  | 68 | `MinimapSetRotation` | `0x005B91E0` | ○ | 2 |
| 12 | `SetWidgetIgnoresPause` | `0x005B59D0` | ○ | 2 |  | 69 | `MinimapSetRange` | `0x005B92C0` | ○ | 4 |
| 13 | `GetWidgetIgnoresPause` | `0x005B5AA0` | ○ | 2 |  | 70 | `SetMinimapOwner` | `0x005B93C0` | ○ | 4 |
| 14 | `ActivateWidget` | `0x005B5B50` | ○ | 4 |  | 71 | `SetMinimapBorder` | `0x005B94C0` | ⬤ | 4 |
| 15 | `SetWidgetSleep` | `0x005B5C10` | ○ | 4 |  | 72 | `SetMinimapRadius` | `0x005B9600` | ○ | 0 |
| 16 | `GetWidgetSleep` | `0x005B5CE0` | ○ | 2 |  | 73 | `MinimapAddObjective` | `0x005B96E0` | ⬤ | 4 |
| 17 | `PushWidgetToFront` | `0x005B5D90` | ○ | 4 |  | 74 | `MinimapAnimateObjectiveSize` | `0x005B9A10` | ○ | 4 |
| 18 | `PushWidgetToBack` | `0x005B5E00` | ○ | 4 |  | 75 | `MinimapAnimateObjectiveAlpha` | `0x005B9C80` | ⬤ | 4 |
| 19 | `SetWidgetAnchoring` | `0x005B5E70` | ⬤ | 2 |  | 76 | `MinimapAnimateObjectiveSonar` | `0x005B9E90` | ⬤ | 4 |
| 20 | `GetWidgetAnchoring` | `0x005B5FE0` | ○ | 2 |  | 77 | `MinimapUnanimateObjective` | `0x005BA1E0` | ⬤ | 4 |
| 21 | `InterpolateWidget` | `0x005B60F0` | ⬤ | 4 |  | 78 | `MinimapRemoveObjective` | `0x005BA360` | ○ | 2 |
| 22 | `SetWidgetUpdateCallback` | `0x005B6460` | ⬤ | 2 |  | 79 | `MinimapDelete` | `0x005BA430` | ○ | 2 |
| 23 | `SetWidgetViewport` | `0x005B6550` | ○ | 3 |  | 80 | `SetPlayerPDAWidget` | `0x005BA500` | ⬤ | 4 |
| 24 | `GetWidgetViewport` | `0x005B6610` | ○ | 1 |  | 81 | `CreateFlashWidget` | `0x005BA680` | ⬤ | 4 |
| 25 | `AddWidgetChild` | `0x005B66E0` | ⬤ | 2 |  | 82 | `SetFlashSwfFile` | `0x005BA720` | ⬤ | 2 |
| 26 | `SetWidgetChild` | `0x005B67F0` | ⬤ | 2 |  | 83 | `SetFlashPlaySpeed` | `0x005BA850` | ○ | 4 |
| 27 | `RemoveWidgetChild` | `0x005B6910` | ⬤ | 2 |  | 84 | `GetFlashPlaySpeed` | `0x005BA930` | ○ | 4 |
| 28 | `RemoveAllWidgetChildren` | `0x005B6A10` | ○ | 2 |  | 85 | `PauseFlash` | `0x005BA9F0` | ○ | 4 |
| 29 | `GetWidgetChildren` | `0x005B6AB0` | ○ | 2 |  | 86 | `PlayFlash` | `0x005BAAB0` | ○ | 4 |
| 30 | `SetWidgetFullscreen` | `0x005B6BC0` | ○ | 2 |  | 87 | `RestartFlash` | `0x005BAB70` | ○ | 4 |
| 31 | `CorrectWidgetForResolution` | `0x005B6D70` | ○ | 6 |  | 88 | `SendFlashInput` | `0x005BAC20` | ⬤ | 9 |
| 32 | `SetWidgetUseResolutionCorrection` | `0x005B6E10` | ○ | 2 |  | 89 | `SendFlashLeftAnalogInput` | `0x005BAD50` | ⬤ | 4 |
| 33 | `SetWidgetUseNewRescale` | `0x005B6EE0` | ○ | 6 |  | 90 | `SendFlashRightAnalogInput` | `0x005BAE70` | ⬤ | 4 |
| 34 | `GetWidgetHighlightId` | `0x005B6FB0` | ⬤ | 8 |  | 91 | `SetFlashCallback` | `0x005BAF90` | ⬤ | 4 |
| 35 | `GetWidgetDownId` | `0x005B7010` | ⬤ | 6 |  | 92 | `CallFlashScriptFunction` | `0x005BB170` | ⬤ | 2 |
| 36 | `CreateImageWidget` | `0x005B7070` | ⬤ | 2 |  | 93 | `SetFlashPauseMenu` | `0x005BB4E0` | ○ | 1 |
| 37 | `SetImageTexture` | `0x005B7110` | ○ | 2 |  | 94 | `SetFlashTesselationAllowed` | `0x005BB0A0` | ○ | 4 |
| 38 | `SetImageRotation` | `0x005B7210` | ○ | 2 |  | 95 | `RemoveFlashPauseMenu` | `0x005BB6F0` | ○ | 2 |
| 39 | `GetImageRotation` | `0x005B7300` | ○ | 2 |  | 96 | `CreateSpriteWidget` | `0x005BB7B0` | ⬤ | 2 |
| 40 | `SetImageTextureCoordinates` | `0x005B7420` | ⬤ | 2 |  | 97 | `SetSpriteTexture` | `0x005BB850` | ⬤ | 2 |
| 41 | `GetImageTextureCoordinates` | `0x005B75C0` | ○ | 4 |  | 98 | `SetSpriteTextureSize` | `0x005BBAF0` | ⬤ | 2 |
| 42 | `SetImageTiling` | `0x005B7680` | ⬤ | 4 |  | 99 | `SetSpriteFrameSize` | `0x005BBC60` | ⬤ | 2 |
| 43 | `SetImageTextureTransience` | `0x005B7770` | ○ | 6 |  | 100 | `AnimateSprite` | `0x005BBEC0` | ⬤ | 2 |
| 44 | `SetImageClockAnimation` | `0x005B7840` | ⬤ | 2 |  | 101 | `HaltSpriteAnimation` | `0x005BC000` | ○ | 2 |
| 45 | `SetImageClockCallback` | `0x005B7990` | ⬤ | 2 |  | 102 | `SetSpriteFrame` | `0x005BC0C0` | ○ | 2 |
| 46 | `GetImageClockElapsed` | `0x005B7AA0` | ○ | 2 |  | 103 | `CreateMovieWidget` | `0x005BC1A0` | ⬤ | 4 |
| 47 | `SetImagePieSliceRender` | `0x005B7B60` | ○ | 4 |  | 104 | `SetMovieFile` | `0x005BC240` | ○ | 2 |
| 48 | `DisableImagePieSliceRender` | `0x005B7C90` | ○ | 4 |  | 105 | `PlayMovie` | `0x005BC330` | ⬤ | 2 |
| 49 | `CreateTextWidget` | `0x005B7D40` | ⬤ | 2 |  | 106 | `PauseMovie` | `0x005BC410` | ○ | 2 |
| 50 | `SetTextText` | `0x005B7DE0` | ○ | 2 |  | 107 | `StopMovie` | `0x005BC4C0` | ○ | 2 |
| 51 | `GetTextText` | `0x005B7EC0` | ○ | 2 |  | 108 | `GetMovieCurrentFrameNumber` | `0x005BC570` | ○ | 4 |
| 52 | `SetTextFont` | `0x005B7FC0` | ○ | 2 |  | 109 | `SetMovieEndCallback` | `0x005BC640` | ⬤ | 2 |
| 53 | `SetTextWrapping` | `0x005B80A0` | ○ | 4 |  | 110 | `RegisterForPdaUpdate` | `0x005BC730` | ⬤ | 2 |
| 54 | `GetTextWrapping` | `0x005B8170` | ○ | 0 |  | 111 | `RemovePdaBlip` | `0x005BD0C0` | ⬤ | 3 |
| 55 | `GetTextWidth` | `0x005B8240` | ○ | 4 |  | 112 | `UpdatePdaBlip` | `0x005BCF90` | ○ | 2 |
| 56 | `GetTextHeight` | `0x005B8310` | ○ | 2 |  | 113 | `AddPdaMapBlips` | `0x005BCE70` | ⬤ | 2 |

**Traffic.** 339 qualified call sites; only **3 of 114 are never called** (`GetWidgetHighlightable`,
`GetTextWrapping`, `SetMinimapRadius`) — the flattest distribution of any namespace mapped so far,
and the opposite of `Player` (26 of 107 dead). The top of the list is `SendFlashInput` 9 ·
`GetWidgetHighlightId` 8 · `SetWidgetLocation` / `CorrectWidgetForResolution` /
`SetWidgetUseNewRescale` / `GetWidgetDownId` / `SetImageTextureTransience` 6. Because almost every
call site is inside `mrxguibase.lua`'s wrapper methods, **the raw count understates real traffic by
orders of magnitude** — one `_GuiInternal.SetWidgetColor` site backs every `Widget:SetColor` in the
game. Do not use these counts to prioritise; use them only to confirm a binding is *live*.

> **Corpus boundary, stated once.** The column above counts `docs/mercs2-luacd/src` only (370
> scripts) and sums to **339**. `mercs2_script/src/bindings/hud.rs` counts luacd **+ the 75-script
> DLC corpus** and sums to **353**. The 14-call delta is entirely six PDA/Flash rows —
> `SetPlayerPDAWidget` 4→8, `RemovePdaBlip` 3→6, `RegisterForPdaUpdate` 2→4, `UpdatePdaBlip` 2→4,
> `AddPdaMapBlips` 2→4, `SetFlashPauseMenu` 1→2 — and no other row moves. **Neither number is
> wrong**; they are different corpora. *Reproduce:* regex `(?<![\w.])_GuiInternal\.(\w+)` over each
> tree.

> **Correction to `scaleform_gfx_class_map.md` §7.2 — it is wrong on *two* counts.**
> (That file is **not** edited from here; this is the standing correction.)
>
> 1. It states the
>    `CreateFlashWidget / SetFlashSwfFile / SendFlashInput / SetFlashCallback / CallFlashScriptFunction`
>    binders are "**absent from the Ghidra export**". **All five are present**, with export header
>    sizes 146 / 295 / 303 / 262 / 662 (`0x005BA680`, `0x005BA720`, `0x005BAC20`, `0x005BAF90`,
>    `0x005BB170`) — grep `==== FUN_005ba680 @0x005ba680  size=146` in
>    `output/_ghidra/mercs2_unpacked.exe_decomp.txt`.
> 2. It nominates them for a `DecompileProfileAccessors.java` forcing pass over the export gaps
>    `0x60A281–0x60ADF0` and `0x61B540–0x61B8C0`. **Those ranges are in the wrong module** — they lie
>    in the widget-*class* module, whereas all five binders live in the `0x005Bxxxx` binder cluster.
>    The pass would search an address range that cannot contain them.
>
> The genuinely absent Flash binders are **eight** of the fifteen (an earlier revision of this note
> said "the other six" and then listed eight — the list was right, the count was not):
> `SetFlashPlaySpeed`, `GetFlashPlaySpeed`, `PauseFlash`, `PlayFlash`, `RestartFlash`,
> `SetFlashTesselationAllowed`, `SetFlashPauseMenu`, `RemoveFlashPauseMenu`.

### 4.0 Type gating is the rule, not the exception — 63 binders, not 5 (H)

This map used to say "five Flash cfuncs `lua_error` unless `widget+0x10 == 6`, and `MinimapUpdate`
gates on tag 3". A mechanical sweep of all 152 bodies for `cmp dword [reg+0x10], <0..7>` finds
**63 gated bodies** — tag 1 ×6, tag 2 ×13, tag 3 ×14, tag 4 ×6, tag 6 ×18, tag 7 ×6 — of which
**58 raise a Lua error** on mismatch, in the uniform shape
`cmp [esi+0x10],<tag>; j(n)e → lea esi,[esp+X]; call 0x004B2A50`. (Counting the
`MinimapSetPlayerLocation` alias as a binder row makes it 64 / 59.)

The five that gate but do **not** raise: `SetPlayerPDAWidget` and `RemoveFlashPauseMenu` return
silently, and the three PDA-blip binders fold the mismatch into arithmetic — the null-deref family
of §2.

**A reimpl that gates only the five Flash setters silently accepts ~53 calls the retail engine
rejects with an error.** *Reproduce:* disassemble each of the 152 table targets and grep the first
`cmp dword [reg+0x10], imm8` in each body.

### 4.1 Cfuncs whose body is not what the name suggests

- **`GetWidgetHighlightId` `0x005B6FB0` / `GetWidgetDownId` `0x005B7010`** take **no argument**. They
  push the globals `DAT_01176034` / `DAT_01176038` verbatim as lightuserdata. They are the
  *cursor/selection state of the whole GUI*, not a per-widget query — which is exactly how
  `mrxguidialogbox.lua:331` and `mrxguinumericbox.lua:508` use them. (H)
- **`SetPlayerPDAWidget` `0x005BA500`** takes a **player GUID**, not a widget id first: it runs the
  player-container walk verbatim (`FUN_006496B0`, `DAT_00DF9BD8`, mask `DAT_00DF9BB0`, stride
  `DAT_00DF9BB4`, shift `DAT_00DF9BB6`, page table `DAT_00DF9C00` — identical to `player_code_map.md`
  §2.1), then reads the widget id and stores it at **`playerObj + 0x390`**, caching the player object
  in `DAT_01176120` and clearing `_DAT_00ED9C7C` when the id is 0. **New offset for the player map.** (H)
  Three things the earlier write-up missed, all H:
  - **The container is named.** `005BA54A mov ecx, 0xDF9B90`, and the ★master key resolves
    `0x00DF9B90` → **`Players`** (`[0x00DF9B90] = 0x00BC3FB8`; `[0x00BC3FB8+0x34] = 0x00647BA0:
    mov eax,0x00BC5DAC; ret` → `"Players"`).
  - **The write precedes validation.** `005BA5E1 mov [ecx+0x390], eax` and `005BA5EB
    mov [0x1176120], ecx` both run *before* the `id<0` / `id>cap` / `slot!=NULL` / `[w+0x10]==6`
    chain at `005BA5FA`–`005BA60F`. **A rejected call has already mutated player state** — exactly
    the detail a write-watchpoint session needs to interpret its hits.
  - **`playerObj + 0x450` holds an event name-hash.** On `id != 0` the binder dispatches event hash
    **`0xFA62754E`** through `FUN_004BDD10`; on `id == 0` it clears both globals and dispatches
    **`0x57B5E35A`** *only if* `005BA646: cmp dword [ecx+0x450], 0xFA62754E` matches — i.e. `+0x450`
    is the "PDA opened" event id, tested to decide whether the matching "closed" event is worth
    sending. Both hashes are **unresolved names**; none is invented here ([[aset-name-export]]).
- **`SetFlashSwfFile` `0x005BA720`, `SetFlashCallback` `0x005BAF90`, `CallFlashScriptFunction`
  `0x005BB170`** each `lua_error` unless `widget+0x10 == 6`. `SetFlashSwfFile` accepts a **nil/absent**
  filename (`FUN_0059FA40 < 1` ⇒ pass 0) and a nil callback (⇒ `thunk_FUN_024BA4E0(file, -1, -1)`),
  i.e. **clearing the movie is a supported call**. Same shape as the Lua-side `SetMovieFile(uId, nil)`
  clear. **`SetMovieFile` `0x005BC240` now proves the same path in the exe** (it is ○ in the *export*
  only): it gates on tag 4 with a `lua_error`, then takes the filename through the **optional** string
  reader `0x0059FA40` and passes 0 when absent. Both are **H**; the old **M** on `SetMovieFile`
  (Lua-only evidence, `mrxguibase.lua:1388`) is retired.
- **`AddPdaMapBlips` `0x005BCE70`** requires arg 2 to be a **Lua table (tag 5)** — `005BCF23 cmp edx,5;
  jne` — and passes the widget to `thunk_FUN_024F2DA0` only when the type tag is 6, via the branchless
  idiom `((tag != 6) - 1) & widget` (0 otherwise). ⚠ **It is not the only cfunc missing the null
  guard: `UpdatePdaBlip 0x005BCF90` and `RemovePdaBlip 0x005BD0C0` have the identical defect** (§2).
  Note the arg-2 type check happens *after* the faulting tag read, so arg 2 is irrelevant to the
  crash. (H)
- **`RegisterForPdaUpdate` `0x005BC730`** is a **subscribe/unsubscribe pair**, not a setter:
  `true → FUN_0060CD90(widget)`, `false → FUN_0060CCF0()` (note the unsubscribe takes no widget —
  it is global). (H)
- **`SetWidgetUpdateCallback` `0x005B6460`** resolves the widget, grabs a Lua function ref
  (`thunk_FUN_024E5E50`), and installs `thunk_FUN_028E3000(ref, widgetId)`; a missing function
  installs `(0, 0)` — i.e. **passing nil is the documented way to clear the callback**. (H)

---

## 5. The `Gui` binding surface — all 38, name → VA

`luaL_Reg` table **`0x00B9A398`**. **1 stub** — `AddObjective` points at `0x006D5640`, the shared
retail dev stub backing 62 bindings across 13 tables (`33 C0 C3 = xor eax,eax; ret`, read from
`mercs2_nodrm_v2/v3.exe`; in the dump image that address is a `pmc_bb` hot-patch — see the Sources
note). Same legend as §4; **23 decompiled**, 15 binding-only.

| # | Name | VA | | calls | | # | Name | VA | | calls |
|--:|---|---|:-:|--:|---|--:|---|---|:-:|--:|
| 0 | `AddObjective` | `0x006D5640` | ○ **stub** | 0 |  | 19 | `_MarkerPulse` | `0x005B4190` | ⬤ | 0 |
| 1 | `LoadTexture` | `0x005B2D50` | ○ | 27 |  | 20 | `_MarkerHaltPulse` | `0x005B42B0` | ○ | 0 |
| 2 | `GetReticlePosition` | `0x005B2E70` | ⬤ | 6 |  | 21 | `SetFactionMarkerVisibleDistance` | `0x005B46D0` | ⬤ | 0 |
| 3 | `LoadFont` | `0x005B2DE0` | ○ | 1 |  | 22 | `EnableFactionMarkers` | `0x005B4760` | ⬤ | 0 |
| 4 | `IsPdaOnSelect` | `0x005B2F10` | ○ | 2 |  | 23 | `SetFactionMarkerSize` | `0x005B48F0` | ⬤ | 0 |
| 5 | `IsXboxController` | `0x005B2F50` | ○ | 2 |  | 24 | `SetVehicleEntranceMarkerVisibleDistance` | `0x005B47E0` | ⬤ | 0 |
| 6 | `ControllerInUse` | `0x005B2FA0` | ○ | 6 |  | 25 | `EnableVehicleEntranceMarkers` | `0x005B4870` | ⬤ | 0 |
| 7 | `FindGuiLocation` | `0x005B3010` | ⬤ | 3 |  | 26 | `SetVehicleEntranceMarkerSize` | `0x005B4950` | ⬤ | 0 |
| 8 | `_MarkerAdd` | `0x005B3300` | ⬤ | 0 |  | 27 | `EnablePickupMarkers` | `0x005B49B0` | ⬤ | 0 |
| 9 | `_MarkerAddTripwire` | `0x005B36C0` | ⬤ | 0 |  | 28 | `SetPickupMarkerSize` | `0x005B4A30` | ⬤ | 2 |
| 10 | `_MarkerAddDisc` | `0x005B38D0` | ⬤ | 0 |  | 29 | `SetPickupMarkerVisibleDistance` | `0x005B4A90` | ⬤ | 1 |
| 11 | `_MarkerAdd3D` | `0x005B3AE0` | ⬤ | 0 |  | 30 | `EnablePlayerMarkers` | `0x005B4B20` | ○ | 5 |
| 12 | `_MarkerSetBlipLimit` | `0x005B3D30` | ○ | 0 |  | 31 | `GetLanguageNum` | `0x005B4B80` | ○ | 0 |
| 13 | `_MarkerAddOld` | `0x005B3DA0` | ⬤ | 0 |  | 32 | `GetLanguageName` | `0x005B4BC0` | ○ | 2 |
| 14 | `_MarkerRemove` | `0x005B4110` | ○ | 0 |  | 33 | `DoSigninCheck` | `0x005B4C00` | ○ | 2 |
| 15 | `_MarkerSetLocation` | `0x005B4330` | ⬤ | 0 |  | 34 | `OnShellLoaded` | `0x005B4C10` | ○ | 4 |
| 16 | `_MarkerSetColor` | `0x005B4400` | ⬤ | 0 |  | 35 | `OnGlobalExit` | `0x005B4C20` | ○ | 1 |
| 17 | `_MarkerSetFollowGuid` | `0x005B4550` | ⬤ | 0 |  | 36 | `ShowLoadingHints` | `0x005B4C30` | ⬤ | 8 |
| 18 | `_MarkerSetScale` | `0x005B4610` | ⬤ | 0 |  | 37 | `OutputToPIX` | `0x005B4C90` | ⬤ | 0 |

Note the shape: the 13 `_Marker*` rows show **0 direct calls** because they are only reachable through
the `Marker.*` aliases the engine installs (§1.3, 51 sites). The `Gui` namespace's *own* traffic is
`LoadTexture` 27 · `ShowLoadingHints` 8 · `GetReticlePosition` 6 · `ControllerInUse` 6 ·
`EnablePlayerMarkers` 5 — a small, mostly platform/shell surface.

### 5.1 Four `Gui` bodies with a surprise

- **`GetReticlePosition` `0x005B2E70` returns two constants: `0` and `DAT_00BBC7EC = 0.25`.** It
  reads its argument and **discards it**, does no lookup, and pushes the pair as tag-3 numbers. On
  retail PC the reticle position is *hardcoded*; the six Lua call sites are reading a constant.
  Any reimpl that models this as a query is modelling something the shipped game does not do. (H)
- **`ShowLoadingHints` `0x005B4C30` cannot be turned off.** Read the body: if the boolean argument is
  present **and false**, the function `return`s immediately *before* the write. Only the
  argument-absent path (which defaults to `1`) and the explicit-`true` path reach
  `*(char*)(DAT_01175FB0 + 0x39) = 1` and `FUN_00608590`. So `Gui.ShowLoadingHints(false)` is a
  **no-op** — a one-way switch. With 8 call sites this is a live shipped defect and a clean fix-pack
  candidate (§9.4). (H)
- **`OutputToPIX` `0x005B4C90` is a 29-byte no-op** — reads one optional number, returns 0. PIX is
  the Xbox 360 profiler; the PC port kept the binding and dropped the body. (H)
- **`FindGuiLocation` `0x005B3010`** takes two lightuserdata args and resolves an object through
  **`FUN_00423DC0`** — the same non-inlined container resolve `player_code_map.md` §2.2 flags as
  having an unidentified container (arrives in ESI). It then does a float-heavy world→screen
  projection. This is a **second independent user** of `FUN_00423DC0` from a non-player namespace,
  which is evidence against reading it as player-specific (§9.5). (M)

---

## 6. Where the widget layer sits relative to the rest of the engine

```
Lua:   Hud.* / Pda.*            (mrxguiinterface.lua — _G.Hud, PUBLIC, Lua-defined)
         └─ MrxGuiManager       (per-player layout instances, HUD sleep stack)
              └─ MrxGuiBase     (Widget / Text / Image / Flash / Sprite / Movie / Minimap wrappers)
                   └─ _GuiInternal.*   ← ★ THIS MAP (114 cfuncs @ 0x005B4E80–0x005BD0C0)
                      Gui.*            ← ★ THIS MAP (38 cfuncs @ 0x005B2D50–0x005B4C90)
                        └─ widget manager  *(DAT_01175FB0 + 0x68)  0x88 B, no vtable
                             │                slots +0x44 (0x200 B) / cap +0x4C (0x80)
                             └─ widget classes  0x0060A000–0x00627400  (vtable dispatch)
                                  ├─ base Widget 0x130 B: +0x30 location · +0x40 corrected · +0x50 colour
                                  ├─ FlashWidget +0x1E0 = GFxMovieView*  → scaleform_gfx_class_map §7.2
                                  ├─ MinimapWidget 0x1020 B, +0x4E4 = 768 B blip array
                                  └─ all → LTI / PgPrimitive           → render_core_code_map
```

The `Marker` alias table and `_GuiInternal.nVersion = 2` are injected **between** the C table
registration and the first script load, from the boot chunks in §1. `mrxguibase.lua:450`
(`if not _GuiInternal.nVersion then …`) is a *build-compatibility probe* against exactly that chunk —
so a reimpl that omits `nVersion` will silently take the legacy branch.

---

## 7. What the Xbox build adds (cited, not re-derived)

[`../mercs2-pdb-analysis/gui-hud.md`](../mercs2-pdb-analysis/gui-hud.md) carries the *event-bus* half
of the HUD, which has **no counterpart in these two tables**: `GuiHealthUpdate`, `GuiAmmoUpdate`,
`GuiReticleUpdate`, `GuiMinimapUpdate`, `GuiVehicleHealthUpdate`, `GuiGameStateChange`,
`GuiPauseStateChange`, `GuiGameTimer`, `GuiUpdate`, `GuiSetSupportMenuMode`, `GuiSetDialogBoxMode`,
plus `PgGui::BeginFrame`, `GUI::Render`, `GuiMarkers::Render`. Those are **engine→script pushes**;
`_GuiInternal`/`Gui` are **script→engine calls**. Both directions exist in the shipped game; only one
of them is a `luaL_Reg` table, which is why the Xbox symbol list and this map barely overlap. The
`Minimap*` / `Pda*` / `*Blip*` / `Marker*` families named there **do** marry to §4/§5 by name.

The one Xbox↔PC row worth stating: `MinimapSetPlayerLocation` is a named Xbox symbol *and* row 66
here (`0x005B90D0`). It is **not** an inference and needs no confirm-live — it is a literal 5-byte
alias, settled statically (was **M**, now **H**):

```
005B90D0   E9 0B 00 00 00   jmp 0x005B90E0     ; = MinimapSetFocusLocation
005B90D5   CC CC CC ...                        ; padding
```

So the two names share one body, and the tag-3 gate in `MinimapSetFocusLocation` applies to both.

---

## 8. Reconciliation with `mercs2_ui` and `mercs2_script`

`tools/wad_simulator/crates/mercs2_ui` (silo 15,
[`../modernization/reimplementation_parallelization_plan.md`](../modernization/reimplementation_parallelization_plan.md)
row 15) already models a retained-mode widget tree and a marker registry. Status of the three
corrections this map raised, **re-checked against the crate on 2026-07-26** (read-only, no edits):

1. **`src/lib.rs:5` still cites the wrong code map — OPEN.** It literally reads
   ``//! **Code map:** `docs/reverse_engineer/scaleform_gfx_class_map.md (+ input_code_map.md)`.``
   That document maps the GFx **middleware** — `GASValue`, `GASEnvironment`, the CFX loader, the
   `PgScaleform` renderer HAL — none of which is the binding layer the crate implements. **This map
   is the correct citation** for `widget.rs` and `marker.rs`; the scaleform map remains correct for
   whatever eventually backs `FlashWidget`'s interior. (`lib.rs:6` *has* been updated to list
   `_GuiInternal` among the owned namespaces, so only the citation line is stale.)
2. **The namespace mislabel — FIXED.** `mercs2_script/src/bindings/hud.rs` now carries
   `NAMESPACE = "_GuiInternal"` and `GLOBAL = "_GuiInternal"` (registry row 12), with `TABLE_VA =
   0x00b99ff8`. Had it stayed `"Hud"`, the game's `Hud` façade and the engine table would collide on
   `_G` and every `_GuiInternal.*` call site — 339 in luacd, 353 including the DLC — would resolve to
   nil. Same pass renamed `lti.rs` → `LTILibName`, `pg_world.rs` → `Junk`, `fire.rs` →
   `Graphics.FuelTrail`, `inventory.rs` → `Human.Inventory`, and added `movie.rs`.
3. **`corpus_calls: 0` on all 114 rows — FIXED.** `hud.rs` now carries real counts:
   **111 of 114 rows nonzero, 353 total**, so the coverage harness's `called_missing` metric finally
   reports for the largest namespace in the game. The three zeros are the three genuinely dead
   bindings (`GetWidgetHighlightable`, `GetTextWrapping`, `SetMinimapRadius`). See the corpus-boundary
   note in §4 for why `hud.rs` sums to 353 and §4's column to 339 — both are right for their corpus.
   **One stale cell remains:** `gui.rs:27` says `GetReticlePosition, corpus_calls: 5`; the corpus has
   **6** (`(?<![\w.])Gui\.GetReticlePosition` over `docs/mercs2-luacd/src`), which is what §5's table
   reports.

*Also observed (not a correction):* `mercs2_ui`'s `Widget` struct is closer to retail than this map
used to imply — it already keeps `location` / `corrected_location` / `color` as separate `[f32;4]`
and does **not** store `w`/`h`, which matches §3.1. Its real divergences are `fullscreen: bool`
(retail is the 4-mode, string-settable enum of §3.5), a single `anchoring: u32` (retail has two
independent fields defaulting 0 and **3**), monotonic `u64` handles (retail reuses dense slot
indices), and no `use_resolution_correction` / `use_new_rescale` fields at all.

What the retail engine says a faithful crate must model:

1. **uId is a reused dense slot index, pushed as lightuserdata.** Not a generation-counted handle.
   Delete-then-create hands the *same* id to a different widget; the retail Lua depends on that being
   cheap, and a reimpl using generational handles will diverge on any stale-id path.
2. **Unknown id → `nil`, never an error.** The retail Lua feature-probes bindings
   (`if _GuiInternal.PushWidgetToFront then`); a strict reimpl that raises will break the shell.
3. **Location is a 4-float rect at `+0x30`, colour is a 4-float RGBA at `+0x50`** — do not transpose
   them (see the correction banner at the top). Width and height are **derived**, never stored
   (§3.1). The far corner of `SetWidgetLocation` is optional and the two cases go to *different
   virtuals*: four values → absolute `SetRect` (`+0x10`); two values → `Move` (`+0x14`), which
   translates **all four** components and preserves size (§3.2).
4. **Colour is 0–255 and the "unchanged" test is `value < 0.0`** — a sign test, not equality against
   `-255` (§3.3). The trailing boolean is *propagate to children*, defaulting to **true**.
5. **Type tags are load-bearing**, not decoration: **63 of the 152 binder bodies gate on
   `widget+0x10`, and 58 of those raise a Lua error** on mismatch (§4.0). Gating only the five Flash
   setters silently accepts ~53 calls retail rejects. Use the §3 table's numbering — script
   round-trips through `Hud`/`Pda` will otherwise silently mismatch.
6. **`SpriteWidget` reuses `ImageWidget`'s ctor and field layout but is NOT polymorphically an
   Image** — its vtable is 31 slots against Image's 43 (§3). Model the shared *fields*
   (texture/UV/tiling); do **not** model it as a C++ subclass that inherits Image's virtuals.
7. **Model the resolution-correction pipeline** (§3.5): `+0x60`/`+0x61`/`+0x68`/`+0xD1` plus the
   viewport index at `+0x1C`, a 640×480 design space, and `SetWidgetFullscreen`'s **4-mode enum
   dispatched on `tolower(s[0])`** — not a boolean.
8. **`Marker` is `_G` sugar over `Gui._Marker*`, installed by the engine**, and `Marker.Add` maps to
   the **legacy** `_MarkerAddOld` (§1.3). Reproduce the alias table, not a namespace.
9. **`Gui.AddObjective` is the shared dev stub** — model it as a deliberate `b.stub`, and the same
   for `OutputToPIX`.
10. **`GetWidgetHighlightId`/`GetWidgetDownId` are global cursor state**, not per-widget queries (§4.1).
11. **`ActivateWidget` bypasses the shared prologue** (§2) — it forwards the raw id to the manager,
    which does its own bounds check. Do not assume all 114 share one guard path.

---

## 9. Open questions / confirm-live inventory

Read-only while **PAUSED**; the USER drives execution ([[x32dbg-mcp-no-resume]]), and a conditional
breakpoint on a per-frame function will kill the session ([[x32dbg-mcp-pitfalls]]) — prefer one-shot
breakpoints and HW-write watchpoints.

### 9.0 Closed since the first revision (kept so the closure is auditable)

| was | verdict | where |
|---|---|---|
| 9.1 widget tag 5 | **CLOSED — unassigned.** Two byte-level censuses over `.text` (5 `mov …,5` sites, 1 `cmp …,5` site, none in the widget module) plus the class set closed at 7 by the six base-ctor callers | §3 |
| 9.2 resolution-correction model | **CLOSED — fully recovered.** No forcing pass, no debugger; the bodies were merely absent from the Ghidra export | §3.5 |
| 9.3 is the slot array over-allocated? | **CLOSED — it is not.** `push 0x200` / `cap = 0x80` = zero slack, so `id == cap` is a real 4-byte heap over-read whose garbage pointer is then dereferenced | §2 |
| 9.4 the two fix-pack defects | **CONFIRMED statically, repros written — and the blip defect is *three* binders, not one** | §9.1 below |
| 9.7 base vtable beyond five slots | **CLOSED — all 31 slots named** | §2.1 |
| 9.8 `SetMovieFile(uId, nil)` | **CLOSED in the exe** — `0x005BC240` read; optional string reader, passes 0 when absent. **M → H** | §4.1 |
| 9.9 266 vs 339 call sites | **CLOSED** — independent recount: 341 raw matches − 2 `nVersion` = **339** cfunc sites over `docs/mercs2-luacd/src`. Corpus-boundary note in §4 | §4 |
| Xbox `MinimapSetPlayerLocation` | **CLOSED** — a literal 5-byte `jmp`, not an inference | §7 |
| "the 82 binding-only bodies are missing" | **DISCHARGED** — they were unread, not missing; all 152 targets disassemble from the raw image | Sources |

### 9.1 The two shipped defects — repros

Both are proven statically; neither has been observed at runtime.

* **`Gui.ShowLoadingHints(false)` is a no-op** (§5.1). *Script repro:* call it with `true`, then with
  `false`, then load a level — the hints still show. *x32dbg repro (read-only, PAUSED):* HW write
  watchpoint on `[[0x01175FB0]+0x39]`; it fires on the `true` and omitted calls and **never** on
  `false`. *Fix scope:* the defect is the `je` at `0x005B4C60`, but a correct build also needs the
  notify at `0x005B4C74` made reachable — a small patch region, not a one-byte flip.
* **The PDA-blip null deref, in three binders** (§2). *Script repro:*
  `_GuiInternal.RemovePdaBlip(-1, "x")` — the `id < 0` branch is taken at `005BD126`, `eax = 0`, and
  `005BD139` reads linear address `0x00000010` → access violation. Identical for
  `_GuiInternal.AddPdaMapBlips(-1, {})` and `_GuiInternal.UpdatePdaBlip(-1, {})`; the arg-2 type
  check happens *after* the fault, so arg 2 is irrelevant. *x32dbg repro (read-only):* one-shot bp at
  `0x005BD139`, trigger a PDA close/reopen with a stale blip id, read EAX. **Do not** set a
  conditional bp — these sit next to per-frame work ([[x32dbg-mcp-pitfalls]]).

### 9.2 Genuinely still open, with proof that static work cannot close them

| # | item | why static exhaustion fails | runtime recipe (read-only, PAUSED) |
|---|---|---|---|
| 1 | **`FUN_00423DC0`'s container** (`player_code_map.md` §9.2 asks the same) | `Gui.FindGuiLocation 0x005B3010` does call it and the container arrives in **ESI** — loaded from a caller frame, not an immediate, so no static def-use chain reaches a global (Ghidra also drops the register arg) | one-shot bp at the `call 0x00423DC0` inside `FindGuiLocation`; read ESI; compare against the `Player.SetHealthClamp` site — two different values settle it as a generic resolve |
| 2 | **the event hashes `0xFA62754E` / `0x57B5E35A`** (§4.1) | 32-bit name hashes with no matching string in the image; a hash match alone is not evidence ([[aset-name-export]]) — **no name has been invented** | dump the event-name registry live, or hash-search the Lua / DLC event-name corpus offline with `tools/pandemic_hash.py` |
| 3 | **the slot-array grow path `FUN_00619C00`** | a genuine SecuROM split thunk in **both** images: `jmp [0x0245DCF0]` → `0x028C9000`, still inside `.securom`, slot unresolved | bp at `0x00619C00`, step into the resolved thunk after the stub has run; or read `[mgr+0x44]`'s heap block header after the first grow |
| 4 | **the callee behind `CallFlashScriptFunction 0x005BB3EA`** | `jmp [0x0245505C]` → `0x024B8740`, a SecuROM stub in `.securom`, unresolved in the dump **and** in `nodrm_v3` | same technique as (3) |
| 5 | **base-widget `+0x14`, `+0x63`, `+0x64`, `+0x80`, `+0xB0..0xCC`, `+0xD0`, `+0xD8/+0xDC`, `+0xE0`, `+0xE8`** | no binder reads or writes them; `+0x14` and `+0x63` have vtable accessors (`+0x40`, `+0x60`/`+0x64`) that **no** cfunc calls, so there is no static caller to name them from | bp vtbl `+0x40` / `+0x60` / `+0x64` and read the call stack; watch `+0xB0` / `+0xC0` during an `InterpolateWidget` |
| 6 | **the `'o'` / `'p'` / `'f'` fullscreen mode *words*** | dispatch is on `tolower(s[0])` only — the full strings never appear in the exe, and the shipped Lua only ever passes `"Letterbox"` | none needed for behaviour: the letters and the modes are proven, the words are cosmetic |
| 7 | **`MovieWidget`'s `0x150`-byte interior** | untouched by any binder beyond `+0x10`; the Bink surface lives behind the `0x0060xxxx` movie calls | out of scope — belongs to the movie / LTI map |
| 8 | **`playerObj + 0x390` / `+0x450` readers** | the writers are pinned (§4.1); the *readers* are not statically attributed | HW write-watchpoints on both while opening/closing the PDA, then fold into `player_code_map.md` §2.2 |

### 9.3 Downstream fix still owed by a sibling document

`scaleform_gfx_class_map.md` §7.2 remains wrong on the two counts recorded in §4. **This map does not
edit that file**; the correction is stated here and should be applied there in its own pass.
`mercs2_ui/src/lib.rs:5` and `gui.rs:27` (§8, items 1 and 3) are the two remaining code-side stales.

---

## 10. Provenance

- **PC decomp:** `output/_ghidra/mercs2_unpacked.exe_decomp.txt` (unpacked SecuROM image, base
  `0x00400000`). Bodies read first-hand from the export: the **seven** widget creators
  (`FUN_005B4E80`/`005B7070`/`005B7D40`/`005B8CB0`/`005BA680`/`005BB7B0`/`005BC1A0`), the **seven**
  widget ctors (`FUN_00626DA0`/`0061CF90`/`00622380`/`0061F720`/`00621D80`/`0061B0A0`/`00621EC0`),
  `SetWidgetLocation` `FUN_005B4FA0`, `SetWidgetCorrectedLocation` `FUN_005B53C0`, `SetWidgetColor`
  `FUN_005B5560`, `SetWidgetAnchoring` `FUN_005B5E70`, `SetWidgetUpdateCallback` `FUN_005B6460`,
  `AddWidgetChild` `FUN_005B66E0`, `GetWidgetHighlightId` `FUN_005B6FB0`, `GetWidgetDownId`
  `FUN_005B7010`, `MinimapUpdate` `FUN_005B8EE0`, `SetPlayerPDAWidget` `FUN_005BA500`,
  `SetFlashSwfFile` `FUN_005BA720`, `SetFlashCallback` `FUN_005BAF90`, `CallFlashScriptFunction`
  `FUN_005BB170`, `RegisterForPdaUpdate` `FUN_005BC730`, `AddPdaMapBlips` `FUN_005BCE70`,
  `GetReticlePosition` `FUN_005B2E70`, `FindGuiLocation` `FUN_005B3010`, `ShowLoadingHints`
  `FUN_005B4C30`, `OutputToPIX` `FUN_005B4C90`. The ⬤/○ column in §4/§5 is a mechanical index
  lookup over the export's function headers, not a judgement.
- **PE, read directly:** `output/_ghidra/securom_dump/mercs2_unpacked.exe` — the `0x00DFD478`
  registry walk (§1.1), the two boot chunks (§1.3), and the constants `DAT_00B9B664` = 1.0,
  `DAT_00BEB2E4` = −255.0, `DAT_00BAC8BC` = 1/255, `DAT_00DFDCA4` = −0.5, `DAT_00BBB99C` = 0.5,
  `DAT_00BBC7EC` = 0.25, `DAT_00DFDB5C` = −1.0, `DAT_00B92870` = 100.0.
- **Binding tables:** `mods/lua_trace_asi/reference/binding_map.json` (live `.rdata` walk,
  [[lua-trace-asi-surface-b-oracle]]) — 114/114 and 38/38, corroborated by
  [`../lua_engine_bindings_audit_deep_dive.md`](../lua_engine_bindings_audit_deep_dive.md).
- **Asset hashes:** `docs/data/aset_block_strings.json`, `docs/data/aset_discovered_names.json`
  (`font_16`, `MiniMap_Icon_Marker_A/B`). A 32-bit hash match alone is weak evidence
  ([[aset-name-export]]); here each hash is corroborated by the *role* of the ctor that registers it.
- **Script traffic:** fresh census over the 370 `.lua` files in `docs/mercs2-luacd/src` (qualified
  `NS.Name` matches).
- **Lua layer:** `docs/mercs2-luacd/05_gui_hud_shell.md`, `src/resident/mrxguibase.lua`,
  `src/resident/mrxguiinterface.lua`.
- **Xbox side:** [`../mercs2-pdb-analysis/gui-hud.md`](../mercs2-pdb-analysis/gui-hud.md).
- **Raw-image pass, 2026-07-26** (the source for everything marked corrected here): all 152
  `luaL_Reg` targets parsed out of `.rdata` and disassembled with capstone straight from
  `output/_ghidra/securom_dump/mercs2_unpacked.exe`, VA→file offset through the PE section table
  (`.text` VA `0x00401000` → raw `0x00001000`, `.rdata` VA `0x00B05000` → raw `0x00705000`,
  `.data` VA `0x00BF6000` → raw `0x007F6000`). Retail cross-check against
  `mercs2_nodrm_v2.exe` / `mercs2_nodrm_v3.exe` (⚠ **not** `genuine_patched_unpacked.exe` — different
  build). The Ghidra export was used only to measure its own coverage and to demonstrate its
  under-reporting. Byte-level censuses used: `E8 rel32` for the ctor caller sweep,
  `C7 /0 disp8=0x10 imm32` and `83 /7 disp8=0x10 imm8` for the type-tag sweep.
- **Cross-refs:** [`scaleform_gfx_class_map.md`](scaleform_gfx_class_map.md) (§7.2 corrected here on
  **two** counts — not edited from here),
  [`player_code_map.md`](player_code_map.md) (`+0x390` and `+0x450` added, container `0x00DF9B90` =
  `Players`, `FUN_00423DC0` second caller),
  [`camera_code_map.md`](camera_code_map.md) (the viewport array `[0x00DFC2F8]`, stride `0xE80`, is
  the rescale core's input) and
  [`../render_view_handle_crash_analysis.md`](../render_view_handle_crash_analysis.md)
  (`DAT_01175FB0` neighbours), [`scripting_host_binding_code_map.md`](scripting_host_binding_code_map.md),
  [`../ui/main_menu_structure.md`](../ui/main_menu_structure.md) (its `_GuiInternal.nVersion = 2`
  observation is now sourced to the boot chunk at `0x00BB65C8`).
- Confidence stated per row. **Remaining documented gaps: the eight items in §9.2** — chiefly
  `FUN_00423DC0`'s container, the two PDA event name-hashes, two SecuROM-thunked callees, nine
  unnamed base-widget bytes, and the `MovieWidget` interior. The former headline gaps (tag 5, the
  resolution-correction model, the slot-array question, the base vtable, the 82 unread bodies) are
  closed above.
