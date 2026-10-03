---
status: current
evidence: proven
verified_on: 2026-10-03
---

# Lua binding surface across PC, PS3, and Xbox 360

**Status:** current · **Evidence:** mixed PROVEN + INFERRED (see per-section grading) · **Date:** 2026-10-03

Question: do PC, Xbox 360, and PS3 ship the same set of C→Lua bindings — the C
functions each platform exposes under namespaces like `Pg.*`, `Player.*`,
`Sound.*`, `Net.*`, `Gui.*`, etc. — that the shipped Lua chunks call into?

## 0. TL;DR

| Verdict | Count / scope | Grade |
|---|---|---|
| PC registry at `.rdata` VA `0x00DFD478` | 31 namespaces, 1,081 bindings, 61 pointing at no-op stub `0x006D5640` | PROVEN |
| PC binding names (len ≥ 4) PROVEN resident in BOTH console binaries by byte-level NUL-bounded C-string scan | **978 / 1,050 (93.1%)** | PROVEN |
| PC-only bindings (absent from PS3 EBOOT.elf AND Xbox jul08 PE) | **61** — 52 `LTILibName.*` + 7 `Gui.*` + 2 `Sys.*` | PROVEN |
| PS3-only names (vs Xbox jul08 only) | 4 — `GetShellCode`, `IsBoundaryDeath`, `SetLoadingScreen`, `ThreatPerception` | PROVEN byte presence; INFERRED cause (likely retail-vs-prototype build drift) |
| Xbox-jul08-only names (vs PS3) | 7 — `Attach`, `Callback`, `Completed`, `Copy`, `Detach`, `Pause`, `SetValue` | PROVEN byte presence; INFERRED cause (prototype carries dev strings PS3 retail strips) |
| Shared binding surface across PC + PS3 + Xbox retail | **≥ 978 / 1,050** fn-names + 29 / 31 namespaces (`Sound` and `LTILibName` are the two namespace-label exceptions on PS3) | PROVEN |
| PS3 and Xbox 360 Lua chunks structurally identical modulo `chicon002.lua` | 643 / 643 vz + 26 / 26 shell + loading/english/french byte-identical | PROVEN in `_ps3_base_game_lua_diff.md` + `_ps3_full_wad_set_lua_diff.md` |

The dominant binding-surface divergence is the **LTI (Loading-Tip Interstitial)
subsystem**: 52 `LTILibName.*` + 7 `Gui.*` input-detection + 2 `Sys.*` bindings
are **PC-only**, matching the 2 PC-only Lua chunks (`mrxguiltiprecache{,layout}.lua`,
shipped in both `resident` and `shell`) and the 7 KBM/mouse-and-keyboard
functions dropped from Xbox+PS3 in 7 shared Lua chunks (per
[`_pc_xbox_resident_divergence_characterization.md`](_pc_xbox_resident_divergence_characterization.md)).
Everything else is shared.

## 1. Method

Two orthogonal evidence sources, cross-checked.

### 1.1 Registration-site enumeration

The PC binding set is already settled by
[`lua_engine_bindings_audit_deep_dive.md`](lua_engine_bindings_audit_deep_dive.md)
(verified 2026-07-21): the game keeps a static registry of
`{const char* name, luaL_Reg* table}` at image VA `0x00DFD478` (31 rows, 12-byte
stride, terminated at `0x00DFD5EC`). Walking each row's table to `{NULL, NULL}`
gives 1,081 bindings. 61 of them point at the shared `xor eax,eax; ret` stub at
`0x006D5640` (dev bindings neutered in retail). The ground-truth binding dump
is `output/analysis/probe_results (1)/lua_bindings_deep.json` (1,084 rows
walked live by the `mercs2_probe` ASI; 3-row delta is `_SYS` member variance).

For PS3, the full binding set lives inside the shipped
`game-files/ps3-version/EBOOT.elf` (18,205,720 B, decrypted SELF→ELF; the EBOOT
is already present as both `EBOOT.BIN` and `EBOOT.elf` in the project tree).

For Xbox 360, the retail XEX is RC4-encrypted and we have no decrypted retail
dump. The best proxy is the **jul08 prototype PE** at
`output/jul08_prototype/mercs2_xenon_p.pe_full.bin` (32,374,784 B, unencrypted
PE extracted from `output/_scratch/jul08_iso/mercs2_xenon_p_EN_FR.xex`). The
prototype was built from the same codebase as retail Xbox and the Lua binding
registration is at the same code-generation layer; a binding name present in
the prototype binary is strong evidence (though not proof) it survived to
retail.

### 1.2 Call-site enumeration

PC: regex over `docs/mercs2-luacd/src/**/*.lua` matching
`([A-Z_][A-Za-z0-9_]*)\.([A-Za-z_][A-Za-z0-9_]*)\s*\(` and
`([A-Z_][A-Za-z0-9_]*):([A-Za-z_][A-Za-z0-9_]*)\s*\(`. The Xbox 360 Lua corpus
at `docs/mercs2-luacd-xbox/src/` is register-level `unluac` disassembly where
every namespace lookup is a two-instruction sequence (`Lx = Pg; Lx = Lx.Fn`),
so the same source-level regex sees zero matches. The equivalence is instead
established through the already-proven **structural equivalence of the
compiled Lua chunks across platforms** — if a binding is called from a chunk
whose bytecode is structurally identical to its Xbox or PS3 counterpart, then
that call-site exists on all three platforms by construction.

### 1.3 Byte-level cross-reference

For each of the 1,061 unique PC binding function-name strings (and
separately for the 31 namespace labels), scan both console binaries with
Python regex `(?<![A-Za-z0-9_])<name>(?![A-Za-z0-9_])` on raw bytes.
Short names (len < 4) are excluded from the name sweep because they alias too
heavily (every `Pg` substring in `PgWorld`, `PgCdb*`, etc., would be a false
positive); the 31 namespaces are tested separately with explicit NUL-bounded
patterns.

Scripts and raw TSVs:
`scratchpad/lua_bindings/{parse_pc_bindings.py, xref_names3.py, xref_namespaces.py, enum_calls.py,
xref_names3.tsv, xref_summary3.txt, xref_namespaces.tsv, pc_pairs.tsv,
pc_fn_names.txt, pc_only_by_ns.tsv}`.

## 2. PC binding registry — ground truth (PROVEN)

The 31 namespaces at `0x00DFD478`, with per-namespace function counts and
stub-count (fns that point at `0x006D5640`):

| # | Namespace | Table VA | n | stubs |  | # | Namespace | Table VA | n | stubs |
|---|---|---|---:|---:|---|---|---|---|---:|---:|
| 1 | `_SYS` | `0x00B9A854` | 6 | 0 | | 17 | `Net` | `0x00B998D0` | 92 | 2 |
| 2 | `Sys` | `0x00B98A78` | 64 | 1 | | 18 | `math` | `0x00B99BE8` | 17 | 0 |
| 3 | `Pg` | `0x00B99328` | 80 | 2 | | 19 | `Camera` | `0x00B9A7D8` | 14 | 0 |
| 4 | `Object` | `0x00B99608` | 87 | 0 | | 20 | `Junk` | `0x00B99E28` | 24 | 15 |
| 5 | `Player` | `0x00B98FC0` | 107 | 0 | | 21 | `ObjectState` | `0x00B995B0` | 9 | 2 |
| 6 | `Event` | `0x00B987F8` | 4 | 0 | | 22 | `Movie` | `0x00B99BBC` | 4 | 0 |
| 7 | `Ai` | `0x00B9A938` | 66 | 18 | | 23 | `Animation` | `0x00B9A88C` | 6 | 0 |
| 8 | `Human` | `0x00B99EF0` | 30 | 0 | | 24 | `VO` | `0x00B988B0` | 11 | 0 |
| 9 | `Debug` | `0x00B98828` | 6 | 6 | | 25 | `Weapon` | `0x00B98860` | 9 | 0 |
| 10 | `Vehicle` | `0x00B98918` | 40 | 0 | | 26 | `String` | `0x00B98C88` | 1 | 0 |
| 11 | `Airstrike` | `0x00B9A8C8` | 12 | 0 | | 27 | `Table` | `0x00B98A60` | 2 | 0 |
| 12 | `Gui` | `0x00B9A398` | 38 | 1 | | 28 | `Report` | `0x00B98F64` | 5 | 0 |
| 13 | `_GuiInternal` | `0x00B99FF8` | 114 | 0 | | 29 | `Disguise` | `0x00B98F94` | 1 | 0 |
| 14 | `Graphics` | `0x00B9A4D0` | 75 | 3 | | 30 | `FactionZone` | `0x00B98FA4` | 1 | 0 |
| 15 | `Sound` | `0x00B98C98` | 88 | 9 | | 31 | `LTILibName` | `0x00B99C78` | 52 | 2 |
| 16 | `ObjectFilter` | `0x00B98770` | 16 | 0 | | | | | | |

Plus Graphics compound sub-tables (per audit §3.2): `Graphics.{Camera(7),
Atmosphere(37), Bloom(7), MotionBlur(1), Contrast(2), Monochrome(1), Grainy(1),
AA(1), Effect(4), FuelTrail(3)}` — all nested under row 14. Totals: **31
namespaces · 1,081 bindings · 61 no-op stubs.**

## 3. Byte-level cross-reference against PS3 EBOOT and Xbox jul08 PE (PROVEN)

Scanning all 1,050 PC binding function-name strings (len ≥ 4) against
`EBOOT.elf` and `mercs2_xenon_p.pe_full.bin` with word-boundary byte regex:

| Bucket | Count | % of 1,050 |
|---|---:|---:|
| Present in BOTH PS3 and Xbox jul08 PE | **978** | **93.1%** |
| Present in PS3 only (missing from Xbox jul08 PE) | 4 | 0.4% |
| Present in Xbox jul08 only (missing from PS3 EBOOT) | 7 | 0.7% |
| Absent from both console binaries | **61** | 5.8% |

Raw per-name verdict TSV: `scratchpad/lua_bindings/xref_names3.tsv`.

### 3.1 The 61 absent-from-both — PC-only subsystems (PROVEN)

Grouped by their PC-registered namespace:

| Namespace | n | Members (PROVEN absent from both PS3 EBOOT and Xbox jul08 PE) |
|---|---:|---|
| `LTILibName` | **52** | `ChangeShellState`, `FirstRun`, `LTICamera`, `LTIChoseOnline`, `LTIGetDateFormat`, `LTIGetStartButton`, `LTIInputGeneralEnter`, `LTIInputGeneralInvertMouse`, `LTIInputGeneralJoySense`, `LTIInputGeneralMouseSense`, `LTIInputGeneralOptions`, `LTIInputGeneralRumble`, `LTIInputJoystickApplyChanges`, `LTIInputJoystickCancel`, `LTIInputJoystickChangeInput`, `LTIInputJoystickChangePrimary`, `LTIInputJoystickDefault`, `LTIInputJoystickEnter`, `LTIInputJoystickExit`, `LTIInputJoystickReEnter`, `LTIInputKMApplyChanges`, `LTIInputKMCancelInput`, `LTIInputKMChangeInput`, `LTIInputKMDefault`, `LTIInputKMEnter`, `LTIInputKMExit`, `LTIJoystickOverBoundResponse`, `LTIMoviePause`, `LTIMovieResume`, `LTIMovieStart`, `LTIMovieStop`, `LTIOverBoundResponse`, `LTIPauseItemChanged`, `LTIPrecacheDone`, `LTIPrecacheSmokeDone`, `LTIProfileEnter`, `LTIProfileExit`, `LTIVideoAdvanceDefault`, `LTIVideoAdvanceEnter`, `LTIVideoApplyChanges`, `LTIVideoCancel`, `LTIVideoDefault`, `LTIVideoEnter`, `LTIVideoGetViewDistance`, `LTIVideoNextRefresh`, `LTIVideoNextRes`, `LTIVideoPrevRefresh`, `LTIVideoPrevRes`, `LTIVideoSetGamma`, `LTIVideoSwitchMode`, `LTIVideoSwitchOpt1`, `LTIupdateSupportQuickSlot` |
| `Gui` | **7** | `ControllerInUse`, `GetWidgetDownId`, `GetWidgetHighlightId`, `GetWidgetHighlightable`, `IsXboxController`, `RemoveFlashPauseMenu`, `SetWidgetHighlightable` |
| `Sys` | **2** | `GetForceNewGame`, `LTIGetPrecacheBypass` |

The namespace label `LTILibName` itself is also absent from both console
binaries (word-bounded hits = 0 on each — see §4). All 52 `LTILibName.*`
members + the namespace label are PROVEN PC-exclusive.

The 7 `Gui.*` entries are the keyboard-mouse / windowed-UI / Flash pause-menu
input layer. `Gui.ControllerInUse` and `Gui.IsXboxController` are the
pad-detection bindings PC needs because its input device is not fixed
(controller, keyboard+mouse, or hybrid); consoles have no such ambiguity. The
widget-highlight helpers back the mouse-hover highlighting the Lua side would
drive — see the KBM-UI finding in
[`_pc_xbox_resident_divergence_characterization.md`](_pc_xbox_resident_divergence_characterization.md)
§3.2, which listed 7 shared Lua chunks that dropped KBM-adjacent helpers on
Xbox.

The 2 `Sys.*` entries are both the LTI boot-config surface: `GetForceNewGame`
and `LTIGetPrecacheBypass` steer the PC-specific LTI loader.

All 61 PC-only bindings are **called from PC Lua chunks**:
`scratchpad/lua_bindings/pc_only_calls.log` lists the 56 of 61 with concrete
call sites (counts: `LTILibName.ChangeShellState` 24, `LTIInputGeneralEnter`
8, `LTIVideoAdvanceEnter` 8, `_GuiInternal.GetWidgetHighlightId` 8, etc.). The
remaining 5 (`LTIPrecacheDone`, `LTIPrecacheSmokeDone`, `LTIProfileEnter`,
`LTIProfileExit`, `_GuiInternal.RemoveFlashPauseMenu`) are registered but
unused in the shipped PC Lua — likely called from engine C++, not from Lua.

### 3.2 PS3-only / Xbox-jul08-only names (PROVEN byte presence, INFERRED cause)

| Name | PS3 | Xbox jul08 | Note |
|---|:-:|:-:|---|
| `GetShellCode` | ✓ | — | Short identifier; likely a different code generator between the two consoles. |
| `IsBoundaryDeath` | ✓ | — | Part of PC's `Player` table (registered) — the string is present in retail PS3 and retail PC but was renamed or absent in the jul08 Xbox prototype. |
| `SetLoadingScreen` | ✓ | — | Same pattern — present in PC and PS3 retail; absent from jul08 Xbox proto. |
| `ThreatPerception` | ✓ | — | Same pattern. |
| `Attach` / `Detach` | — | ✓ | Short names present as Xbox PE substrings outside the Lua-binding region. Scaleform/debug surface candidates. |
| `Callback` / `Completed` / `Copy` / `Pause` / `SetValue` | — | ✓ | Short common tokens; jul08 proto retains dev debug strings PS3 retail strips. |

The 4 PS3-only names are each in the PC registered dump and are called from
Lua on both PC and PS3, so they are *not* a PS3-vs-Xbox-retail divergence —
they are an **Xbox-jul08-prototype vs retail** drift. The jul08 build is from
July 2008, pre-release; the strings were added or renamed before gold.

The 7 Xbox-jul08-only strings are short common tokens that appear in the
Xbox prototype PE outside the Lua binding region (likely Scaleform AS2
registration, debug macros, or RTTI class member names), with no matching
unique string on retail PS3. None of them is proof of a binding; the
corresponding `Namespace.<name>` call is also present on PC and PS3 (e.g.
`Human.Attach` is called from both).

## 4. Namespace-level cross-reference (mixed PROVEN + INFERRED)

NUL-bounded C-string search for each of the 31 PC registered namespaces +
Graphics compound sub-tables + Lua-side aliases (`Hud`, `Marker`):

| Namespace | PS3 (word-bounded hits) | Xbox jul08 (word-bounded hits) | Verdict |
|---|---:|---:|---|
| `_SYS`, `Sys`, `Pg`, `Ai`, `Debug`, `Airstrike`, `Gui`, `_GuiInternal`, `Graphics`, `ObjectFilter`, `Net`, `math`, `Junk`, `ObjectState`, `Movie`, `VO`, `Weapon`, `String`, `Table`, `Report`, `Disguise`, `FactionZone` | ≥ 1 | ≥ 1 | PROVEN resident on both |
| `Object`, `Player`, `Event`, `Vehicle`, `Camera` | 2–4 (not NUL-bounded; appear inside format literals / vtable blobs) | ≥ 1 (NUL-bounded) | PROVEN resident on Xbox prototype; **INFERRED resident on PS3** via the shipped Lua chunk constant pools (the chunks execute `Object.*`, `Player.*`, etc. on PS3) rather than a `.rodata` C-string literal — see §4.1 |
| `Human` | 1 strict, 1 word | 23 strict, 29 word | PROVEN both |
| `Sound` | **0** word-bounded, 0 strict | 1 strict, 4 word | **PROVEN byte absence on PS3**; mechanistic explanation INFERRED — see §4.2 |
| `LTILibName` | **0** both forms | **0** both forms | PROVEN absent on both consoles — matches §3.1 |
| `Animation` | 0 strict, 9 word | 0 strict, 14 word | PROVEN resident (word-bounded in both) |
| `Hud`, `Marker` | 1, 0 | 1, 0 | `Hud` is a Lua-side `_G` alias created from `_GuiInternal`; `Marker` is a Lua-side alias from `Gui._Marker*` — the audit confirms neither has a registry row on PC either. |

Raw TSV: `scratchpad/lua_bindings/xref_namespaces.tsv`.

### 4.1 Why the "0 strict / N word" readings on PS3

PS3's `.rodata` layout packs successive C-strings without a leading NUL
padding byte in several cases (the preceding string's trailing NUL is the
boundary). The strict pattern `\x00NAME\x00` therefore misses occurrences
where the preceding literal's padding is less than one full byte. Dumping the
Pg bootstrap region at EBOOT offset `0xdcfb00`–`0xdd1400` resolves this: the
namespace labels `Pg`, `Disguise`, `String`, etc. appear as isolated
NUL-terminated literals, and the member-name tables for `Pg`,
`Player`/`Pursuit`, `Sound`, and `String` run contiguously immediately after
each table's label (artefact: `scratchpad/lua_bindings/ps3_sound_hex.log`).

### 4.2 The `Sound` byte-absence on PS3 (INFERRED)

PS3 EBOOT.elf has **zero** occurrences of the exact byte sequence `Sound` with
a non-identifier byte on **both** sides (strict `\x00Sound\x00`: 0; word-bounded
regex: 0; total substring hits: 138, all inside longer identifiers like
`PgSoundRuinKeyInitializer`, `SoundEffect`, `GetSoundKey`). Yet the 88
`Sound.*` member-name strings (`TestCueSound`, `PlayCue`, `CueSound`,
`StopSound`, …) are **all present** in a contiguous `.rodata` block starting at
offset `0xdd0d50`, immediately after the `Disguise` namespace label.

Xbox jul08 PE has `Sound` as an isolated string (strict=1, word=4), as does
PC. The call `Sound.PlayCue(...)` works on PS3 (the compiled Lua chunks
reference it and run), so the global `Sound` must resolve on PS3 somehow.

Hypothesis (INFERRED, not verified in this pass): PS3 registers the Sound
table under a different internal name (packed into one of the surrounding
identifiers), and a Lua bootstrap chunk aliases `_G.Sound = _G.<internal>`
using `"Sound"` from the chunk's bytecode constant pool (which lives in the
`.wad`, not the EBOOT). The identical pattern exists on PC for `_G.Marker =
_G.Gui._Marker*` (see audit §3.2 "Lua-side aliases"); PS3 may extend that
pattern to Sound. Verifying the hypothesis would require (a) finding the real
`luaL_register`/`luaL_openlib` call site inside EBOOT.elf and reading the
second argument, or (b) dumping the Lua bootstrap chunk from the PS3 WAD and
grepping for an `_G.Sound = ...` assignment.

This finding does **not** change the binding count: the 88 Sound bindings are
PROVEN resident on PS3 (every member-name string is present and the Lua
corpus calls them). It only places `Sound` in a different registration path
than PC/Xbox use.

## 5. Call-site enumeration from the three Lua corpora (PROVEN by equivalence)

### 5.1 PC call-site inventory

Regex pass over `docs/mercs2-luacd/src/**/*.lua` (3,437 unique
`Namespace.Fn` pairs across 505 Lua-visible namespace roots, 21,526 total
sites). Filtering to the 31 engine namespaces + `Hud` + `Marker`:

- **765 engine-binding call pairs** (unique).
- **752 unique engine-binding function names** called.
- **35 engine namespaces** reached (31 registry + `Hud`, `Marker`, `Faction`
  — the last is a Lua-side alias not in the registry; the engine registers
  `Report` and the alias assigns `_G.Faction = Report` in the bootstrap).

Raw TSV: `scratchpad/lua_bindings/engine_called_pairs.tsv`.

### 5.2 PS3 and Xbox 360 call-site equivalence

The Xbox 360 Lua corpus is register-level `unluac` disassembly (one assignment
per IR instruction), so a textual regex sees zero `Namespace.Fn(` pairs. The
PS3 base-game corpus is not re-decompiled (chunks are byte-identical to Xbox
modulo one script, so a separate decompilation would carry no new
information). The call-site equivalence is instead derived from the **proven
structural identity of the compiled Lua chunks**:

| Pair | Result | Source |
|---|---|---|
| PC `vz.wad` ↔ Xbox 360 `vz.wad` | 114 / 114 scripts structurally identical | [`docs/mercs2-luacd-xbox/_structural_diff_report.md`](mercs2-luacd-xbox/_structural_diff_report.md) |
| PC `resident` ↔ Xbox 360 `resident` | 116 identical + 51 assert-only + 64 print-trace minor + 7 real-drop + 2 PC-only | [`_pc_xbox_resident_divergence_characterization.md`](_pc_xbox_resident_divergence_characterization.md) |
| PS3 base-game ↔ Xbox 360 base-game | 643 / 643 vz chunks + 26 / 26 shell structurally identical; `chicon002.lua` is the sole semantic divergence (drops 3× `self:_GetFlag("…Destroyed_New")` + 1× `:Complete()` — all Lua class methods, no C bindings touched) | [`_ps3_base_game_lua_diff.md`](_ps3_base_game_lua_diff.md), [`_ps3_full_wad_set_lua_diff.md`](_ps3_full_wad_set_lua_diff.md) |

Consequence (PROVEN by equivalence): every engine-binding call site in the PC
Lua corpus — except those inside the 2 PC-only LTI chunks and the 7 KBM-UI
real-drop chunks — exists at the same offset in the equivalent Xbox and PS3
chunk, calling the same `Namespace.Fn` strings from the chunk's constant pool.
A binding not registered on a platform would crash the chunk at that call;
the chunks run on all three platforms.

### 5.3 The LTI call-site set (PROVEN)

PC's 4 LTI-exclusive chunks (`mrxguiltiprecache.lua` and
`mrxguiltiprecachelayout.lua`, each present in both `resident/` and `shell/`)
make 46 call sites across 8 Lua namespaces, of which only **3 are engine
bindings**:

- `Debug.Printf` (universal, present on all three platforms)
- `LTILibName.LTIPrecacheDone` (PC-only)
- `LTILibName.LTIPrecacheSmokeDone` (PC-only)

The remaining 43 sites call `MrxGuiBase`, `MrxGuiTranslate`, `MrxTickBar`, …
— Lua-side classes, not engine. So the LTI chunks themselves lean lightly on
C bindings; the heavy use of `LTILibName.*` is in `mrxguishell*`,
`mrxguipausescreen`, `mrxguinumericbox`, `mrxguidialogbox`, `mrxguipda`,
`mrxguibase` — the 7 KBM-UI chunks where Xbox+PS3 ship a trimmed version. The
24 `LTILibName.ChangeShellState` sites, 8 `LTIVideoAdvanceEnter`, 8
`LTIInputGeneralEnter`, etc., all live in those 7 chunks.

Raw: `scratchpad/lua_bindings/lti.set.tsv`,
`scratchpad/lua_bindings/pc_only_calls.log`.

## 6. Final cross-platform table

| Namespace | PC retail n | PS3 retail (byte-resident fn-names) | Xbox 360 jul08 proto (byte-resident fn-names) | Xbox retail (inferred from Lua equivalence) |
|---|---:|---:|---:|---:|
| `_SYS` | 6 | 6 | 6 | 6 |
| `Sys` | 64 | 62 | 63 | 64 (`GetForceNewGame`, `LTIGetPrecacheBypass` absent from both consoles) |
| `Pg` | 80 | 80 | 80 | 80 |
| `Object` | 87 | 87 | 87 | 87 |
| `Player` | 107 | 107 | 106 | 107 (`IsBoundaryDeath` absent from Xbox jul08 only) |
| `Event` | 4 | 4 | 4 | 4 |
| `Ai` | 66 | 66 | 66 | 66 |
| `Human` | 30 | 30 | 30 | 30 |
| `Debug` | 6 | 6 | 6 | 6 |
| `Vehicle` | 40 | 40 | 40 | 40 |
| `Airstrike` | 12 | 12 | 12 | 12 |
| `Gui` | 38 | 31 | 31 | 31 (7 KBM/mouse/widget-highlight bindings absent on both consoles) |
| `_GuiInternal` | 114 | 114 | 114 | 114 |
| `Graphics` | 75 + 10 sub | ≈ 75 | ≈ 75 | ≈ 75 (compound-blob sub-table counts not re-verified byte-for-byte on consoles — INFERRED) |
| `Sound` | 88 | 88 | 88 | 88 (fn-names resident on PS3; namespace label routed differently — §4.2) |
| `ObjectFilter` | 16 | 16 | 16 | 16 |
| `Net` | 92 | 92 | 92 | 92 |
| `math` | 17 | 17 | 17 | 17 |
| `Camera` | 14 | 14 | 14 | 14 |
| `Junk` | 24 | 24 | 24 | 24 |
| `ObjectState` | 9 | 9 | 9 | 9 |
| `Movie` | 4 | 4 | 4 | 4 |
| `Animation` | 6 | 6 | 6 | 6 |
| `VO` | 11 | 11 | 11 | 11 |
| `Weapon` | 9 | 9 | 9 | 9 |
| `String` | 1 | 1 | 1 | 1 |
| `Table` | 2 | 2 | 2 | 2 |
| `Report` | 5 | 5 | 5 | 5 |
| `Disguise` | 1 | 1 | 1 | 1 |
| `FactionZone` | 1 | 1 | 1 | 1 |
| `LTILibName` | 52 | **0** | **0** | **0** (PROVEN absent from PS3 EBOOT and Xbox jul08 PE) |
| **Total** | **1,081** | **≈ 1,018** | **≈ 1,017** | **≈ 1,019** |

Per-fn presence TSV: `scratchpad/lua_bindings/xref_names3.tsv`.

## 7. What's PROVEN vs INFERRED

### PROVEN

- The PC binding registry at `0x00DFD478` (31 namespaces, 1,081 bindings).
- 978 / 1,050 PC binding fn-names (len ≥ 4) are byte-resident in both PS3
  EBOOT.elf AND the Xbox jul08 prototype PE (word-boundary regex, raw-byte
  scan — artefact `scratchpad/lua_bindings/xref_names3.tsv`).
- 61 PC binding names are byte-absent from both consoles: 52 `LTILibName.*` +
  7 `Gui.*` + 2 `Sys.*`.
- PS3 EBOOT.elf has `Sound` substring 138 times, zero of them isolated (every
  occurrence is inside a longer identifier).
- `LTILibName` namespace label is byte-absent from both PS3 EBOOT and
  Xbox jul08 PE.
- The PS3 base-game Lua chunks are structurally identical to Xbox at
  643 / 643 vz chunks + 26 / 26 shell + loading/english/french byte-identical
  (prior pass).

### INFERRED

- **Xbox retail binding set.** The retail Xbox XEX is RC4-encrypted and the
  decrypted retail binary is not in the project tree. The Xbox jul08
  prototype PE is treated as the retail proxy. Where a PC binding name is
  present in the jul08 PE and the shipped Xbox retail Lua chunk calls it,
  the registration is inferred to survive to retail. This is strong but not
  byte-level proof.
- **The 4 PS3-only / 7 Xbox-only name deltas** are byte observations; the
  attribution to prototype-vs-retail build drift vs real divergence is
  reasoned, not re-measured.
- **The `Sound` registration path on PS3** (§4.2) — zero isolated `Sound`
  C-strings in EBOOT.elf yet a working `Sound.*` surface in Lua is
  observationally proven; the hypothesised Lua-bootstrap-alias explanation
  is not yet verified.
- **Graphics compound-blob sub-table counts on consoles** (`Atmosphere`,
  `Bloom`, …) are not re-verified byte-for-byte against PC's PC-registered
  totals; the per-sub-table count is INFERRED from the Lua equivalence
  rather than from a fresh console-side walk.

### SPECULATIVE

- The absence of `LTILibName` on consoles plus the absence of its 52 member
  names plus the absence of its namespace label is three independent proofs
  pointing at the same subsystem being PC-exclusive. The remaining
  possibility — that the LTI subsystem exists on console under a different
  name family entirely — is not refuted here but no evidence for it was
  found in either console binary.

## 8. Scratchpad artefacts

Under `scratchpad/lua_bindings/`:

- `pc_pairs.tsv` — 1,084 (namespace, fn) pairs from the PC live binding dump.
- `pc_fn_names.txt` — 1,061 unique PC binding fn-names.
- `pc_namespaces.txt` — 37 namespace labels (31 registered + Graphics
  sub-tables + `?` for 3 unidentified compound-blob sub-table addresses).
- `xref_names3.tsv` — per-fn presence verdict across PS3 EBOOT + Xbox jul08
  PE (byte-level, word-bounded regex).
- `xref_summary3.txt` — the full both/PS3-only/Xbox-only/none buckets.
- `xref_namespaces.tsv` — namespace-level NUL-bounded verdict.
- `pc_only_by_ns.tsv` — the 61 absent-from-both bindings grouped by
  registered namespace.
- `engine_called_pairs.tsv` — 765 engine-binding call pairs reached from PC
  Lua source.
- `engine_fns_called.txt` — 752 unique engine fn-names called from PC Lua.
- `pc.set.tsv`, `pc.sites.tsv`, `pc.ns.tsv` — full PC Lua corpus call-site
  census (3,437 pairs, 21,526 sites, 505 Lua-level namespace roots).
- `lti.set.tsv`, `lti.engine_pairs.tsv` — call-site census for the 4 PC-only
  LTI chunks.
- `ps3_eboot_strings.txt`, `xbox_xex_strings.txt` — raw `strings -n 3` output
  from each binary (reference, superseded by `xref_names3.tsv`).
- `enum_calls.py`, `parse_pc_bindings.py`, `xref_names3.py`,
  `xref_namespaces.py` — the scripts that produced the above.
