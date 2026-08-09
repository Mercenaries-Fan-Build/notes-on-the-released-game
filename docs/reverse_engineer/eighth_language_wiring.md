---
title: Eighth-language wiring — what it takes to add a genuine selectable language
status: current
evidence: proven (static decomp + raw exe bytes) / inferred where noted
date: 2026-08-08
supersedes: []
---

# Adding a genuine eighth language to Mercenaries 2 (PC retail)

**Question:** can the workshop ship "Route C" — a real eighth language a player can pick, that
mounts its own `<lang>.wad` / `<lang>-patch.wad` and resolves its own stringdb — as a *data* edit,
or does it require an *exe patch*?

**Verdict: it is a code/data-overlay patch, not a pure data edit.** The language *content* path
(WAD mount + stringdb resolve + per-language font atlases) is fully **name-driven** and will accept
a novel name with zero code changes. But the *set of languages* is a **fixed 9-entry pointer table
in `.data` plus a hard `index ≤ 8` bound plus several hardcoded index `switch`es**, and PC has **no
in-game language selector at all** — the language is chosen at boot from the registry/OS locale.
So making an eighth language real means an ASI (pmc_bb) that (a) extends/repurposes the name table
and (b) forces the selected index. There is no INI/array the engine reads to enumerate languages.

All addresses are absolute VAs (image base `0x00400000`) in the SecuROM-unpacked
`output/_ghidra/securom_dump/mercs2_unpacked.exe`; decomp line refs are into
`output/_ghidra/mercs2_unpacked.exe_decomp.txt`.

---

## 1. The name table `PTR_s_english_00cf281c` (RESOLVED — raw bytes)

The table is an array of `char*` at **VA `0x00cf281c`** (`.data`, file offset `0x8f281c`; for this
dumped exe RVA == file offset). Dumped directly from the exe:

| index | pointer VA | string |
|------:|-----------|--------|
| 0 | `0x00bbcae4` | `english` |
| 1 | `0x00be13cc` | `spanish` |
| 2 | `0x00be13c4` | `italian` |
| 3 | `0x00be13bc` | `french` |
| 4 | `0x00be13b4` | `german` |
| 5 | `0x00be13a8` | `japanese` |
| 6 | `0x00be139c` | `english_uk` |
| 7 | `0x00be1394` | `allcaps` |
| 8 | `0x00be138c` | `russian` |
| 9+ | `0x06676666`, `0x0`, … | **garbage** (adjacent unrelated globals) |

- **Exactly 9 entries (0–8), no terminator, no slack** — index 9 is already someone else's data.
  Confirmed independently by the bound in the name→index lookup (`FUN_00826a10`,
  decomp:615996): `if (8 < iVar5) return` — it probes indices 0..8 and gives up at 9.
- The strings are **lowercase** (`english`, not `English`); the filename mount and the stringdb
  hash both lowercase anyway (`| 0x20`), and the shipped WADs are `English.wad` etc. (Win32 FS is
  case-insensitive).
- Runtime order ≠ the "English French German Italian Japanese Russian Spanish" order quoted in old
  docs. The old anchor `0x007BA530–0x007BA574` is **wrong**: those VAs are *code*, not strings
  (verified by dumping the bytes — they are `.text` instruction bytes). Likewise `GetLanguageName`
  `0x007B5740` / `GetLanguageNum` `0x007B5750` are **function entry points**, not string offsets.
- Indices **6 `english_uk`** and **7 `allcaps`** are dev/console leftovers: no PC `.wad` ships for
  them, and the OS-locale autodetect never selects them. `allcaps` is a QA pseudo-language.
  These are the natural slots to **repurpose** for an eighth language (see §7).

### Who writes the selected index

Two globals are in play; do not conflate them:

- **`DAT_00cf255c`** — the *boot-time detected* language index (`int`, init `-1`). Written by:
  - `FUN_00826a10` (0x00826a10, decomp:615984) — takes the INI/registry `Language` *name* string,
    `_stricmp`s it against `PTR_s_english_00cf281c[0..8]`, stores the match in `DAT_00cf255c`, and
    caches the stringdb hash into `_DAT_01176348`. Called from the localization INI parser
    `FUN_004c2c20` (0x004c2c20) under INI-key hash `0xea7dfc85` (= "language").
  - `FUN_00826a90` (0x00826a90, decomp:616026) — the OS-locale fallback: `GetUserDefaultLangID()`
    + registry `Language`(DWORD `DAT_00cfdd1c`)/`Locale`, mapped through jumptable `DAT_00826dc0`
    to `DAT_00cf255c ∈ {0,1,2,3,4,5,8}` (English/Spanish/Italian/French/German/Japanese/Russian).
    Runs only if `DAT_00cf255c == -1`.
- **`DAT_01176018`** — a **pointer** to a heap-allocated ~0xd0-byte localization struct
  (`FUN_00630b20` / `FUN_004c2190`:99895 allocs `FUN_0084ac20(0xd0,1)`, zero-inits). The **runtime
  language index is `*DAT_01176018` (struct offset 0)** — this is what the mount, the stringdb
  hash, and the font code all read.

**Static-visibility gap (open question, §9):** in the entire static decomp, struct offset 0 is only
ever *written to 0* (`FUN_004c2190`:288604). Yet retail plainly mounts `German.wad` etc., so a
non-English value must reach `*DAT_01176018` at runtime. The write is **not statically reachable** —
almost certainly it lives behind a SecuROM splice thunk (the same class of invisibility documented
for the `"vz"` basename setter in `wad_duplicate_inventory.md §B.5`, whose only reference is thunk
`0x02477DF0` with no static callers). Confirmation that the spliced/high region *does* touch this
table: decomp:2059617 (`0x0247…` range) reads `(&PTR_s_english_00cf281c)[*unaff_EDI]`. Practical
consequence for the hook: **target `*DAT_01176018` (and `DAT_00cf255c`) directly**; do not rely on
finding a clean C setter.

---

## 2. Data-driven or hardcoded? → **hardcoded set, name-driven content**

There is **no** language-count constant read from INI and **no** extensible array. The "count" is
implicit and appears hardcoded in three independent places, all of which cap at the same 9:

- the `8 < iVar5` bound in the name→index probe (`FUN_00826a10`, decomp:615999);
- the 9-slot physical table with garbage at slot 9 (§1);
- `FUN_004644b0` (0x004644b0, decomp:50900) font loader: `if (param_1 < 8 && param_1 < DAT_011759b8)`.

`GetLanguageNum` / `GetLanguage` / `GetLanguageName` are **query** functions (they return the
current index / name), not registration or count APIs. Lua only ever *reads* the current language
(`Sys.GetLanguage()`, `Gui.GetLanguageName()` — see §3); there is **no `SetLanguage`** exposed.

So: **content is data-driven** (a new name flows through mount + hash + name-based font requests),
but **membership is code** (fixed table + fixed bound + hardcoded index switches).

---

## 3. The Options-menu language list → **there isn't one on PC**

Searched the decompiled shell/GUI Lua (`docs/mercs2-luacd/src`) exhaustively for a language
selector. The only language references are **read-only path builders**:

- `mrxsoundbanks.lua:83` — `local sLanguage = Gui.GetLanguageName(); return sAssetName.."."..sLanguage`
  (builds `<bank>.<Language>` VO/soundbank asset names).
- `mrxbriefing.lua:1189-1210` — `sLanguage = Sys.GetLanguage() or "English"`, then an
  `if/elseif` over `"English"/"French"/"German"/"Italian"/"Spanish"/"Russian"` to pick briefing
  assets.

There is **no widget, no list, no `SetLanguage` fscommand** anywhere in `shell.wad` Lua, and
`docs/ui/main_menu_structure.md` confirms the menu is entirely Lua/Scaleform-driven with no
hardcoded C option array. The language is therefore **selected at launch only**, from:
registry `HKLM\SOFTWARE\EA Games\Mercenaries 2 World in Flames\Language` (string) →
`FUN_00826a10`, else OS locale → `FUN_00826a90`
(both feeding `DAT_00cf255c`; see `docs/mercs2_licensing_registration_map.md`).

**Implication for Route C:** a player can't "select" a new language from the shipped menu. Route C
must either (a) set the registry `Language` value to the new name and let boot autodetect pick it
up (requires the name to be in the table — §7), or (b) have the ASI force the index at boot, or
(c) add a new Lua/Scaleform options widget that calls a native setter the ASI installs.

---

## 4. Mount + resolve for a novel name — **works, name-driven**

The language WAD is mounted by the boot state machine `FUN_004bfaf0` (0x004bfaf0), which dispatches
on a step counter `*(state+0xc)`; the language steps are **10–13**, handled by two leaves:

- **States 10–11 — base WAD.** `FUN_004bfe20` (0x004bfe20, decomp:98396):
  `sprintf(buf, "%s\\%s.wad", ".\\Data\\", (&PTR_s_english_00cf281c)[*DAT_01176018])`
  → opens `.\Data\<name>.wad`. **If the open fails and the "required" flag (`+0x20e9`) is set →
  `MessageBoxA(... "Mercenaries 2: World in Flames" ...); exit(1)`.** So the base `<name>.wad`
  **must exist**.
- **States 12–13 — patch WAD.** `FUN_004bfef0` (0x004bfef0, decomp:98434):
  `sprintf(buf, "%s\\%s-patch.wad", ".\\Data\\", name)` → opens `.\Data\<name>-patch.wad`.
  Failure is **non-fatal** (just advances the state) — the patch overlay is optional.

Format strings verified from raw bytes: `0x00bafed0 = "%s\%s.wad"`, `0x00baff5c = "%s\%s-patch.wad"`,
`0x00ed2010/0x00ed1f10 = ".\Data\"`.

**Stringdb resolve** is `FUN_004b87a0` (0x004b87a0, decomp:95066), which inlines FNV-1a over the
name string with the `| 0x20` (lowercase) and `^ 0x2a` twists and pairs it with type `0x39e5e978`:

```
h = 0x811c9dc5; for c in name: h = (h ^ (c|0x20)) * 0x1000193; key = (h ^ 0x2a) * 0x1000193
request (key, 0x39e5e978)
```

This reads `(&PTR_s_english_00cf281c)[*DAT_01176018]` at call time — **the hash is computed from
the name string every time**, so a novel name resolves its own stringdb with no other change.
`pandemic_hash_m2("english") == 0xB6A13123` (matches the known key). Released/re-requested on every
shell↔gameplay transition (`FUN_004bc6d0` cases 2/7, `FUN_004c1280`).

**So for a name `polski` at `*DAT_01176018`:** states 10–13 open `.\Data\polski.wad` /
`.\Data\polski-patch.wad`, and `FUN_004b87a0` requests `(pandemic_hash_m2("polski"), 0x39e5e978)`.
Both are correct with **no code change** — provided the name is reachable via the table and the
base `polski.wad` exists.

---

## 5. Font / atlas dependency — **two mechanisms, one name-driven, one index-hardcoded**

Per-language fonts come in via two independent paths:

1. **Name-driven per-language atlas descriptors — GOOD.** `FUN_004644b0` (0x004644b0, decomp:50910)
   builds `sprintf("%s_%s", name, DAT_00e8ae38[i])` (format `0x00baaa3c = "%s_%s"`). This yields
   `<name>_<suffix>` requests — matching the shipped atlas naming
   `src/texts/fonts/<lang>_18_*.ftga` and `<lang>_20_*.ftga`
   (`docs/loading_shell_wad_analysis.md:158`; shell.wad block "russian" carries `russian` font×2 +
   stringdb + 6 textures). The suffix array `DAT_00e8ae38` and count `DAT_011759b8` are filled at
   runtime (static bytes are 0). **A new language ships `<name>_18_*` / `<name>_20_*` atlases in its
   own WAD and they load by name** — data-driven.

2. **Index-hardcoded base HUD font family — the catch.** `FUN_0060e9c0` (0x0060e9c0, decomp:270708):
   ```
   if (*DAT_01176018 == 8) { font = "Franklin Gothic Medium"; atlas = "fonts_ru";    }  // Cyrillic
   else                    { font = "Gunplay";                atlas = "fonts_enext"; }  // Latin ext
   ```
   This is a **binary switch on the index**: only index 8 (Russian) gets the Cyrillic atlas; every
   other index (including any new one) falls to the Latin-extended `fonts_enext` atlas
   (`docs/loading_shell_wad_analysis.md:50`, "Latin extended charset bitmap").

   **Consequence for a Latin-script eighth language (Polish `Ł Ą Ę Ś Ż Ź Ć Ń`):** the HUD/base font
   uses `fonts_enext`. If that atlas lacks the Polish diacritics, those glyphs render missing/boxed
   even though the stringdb is correct. Options: (a) verify `fonts_enext` coverage; (b) ship a
   `<name>_*` atlas that fully covers the glyphs and rely on path (1) for the menu/text fonts; or
   (c) for a non-Latin script, you additionally need `FUN_0060e9c0` patched to select the right
   atlas (index-hardcoded — **cannot** be done without touching that switch, e.g. by hooking it or
   reusing index 8's Cyrillic branch).

---

## 6. Every other place the language is keyed by index (the hardcoded consumers)

Beyond mount/hash/font, several subsystems `switch` on `*DAT_01176018` (or `DAT_00cf255c`) with a
**hardcoded per-index table** and a default fallback. A novel index falls through to the default —
usually English-equivalent, so it degrades gracefully but is not fully correct:

| addr / decomp | what it keys | indices handled | new-index behavior |
|---|---|---|---|
| `FUN_006067b0` :266015 | a cached stringdb hash at `DAT_011763fc+0x78` | 0→`0xb6a13123`(english), 1→spanish, 2→italian, 3→french, 4→german; **5–8 fall to default=english** | falls to english hash (already wrong for Russian/Japanese in retail!) |
| `FUN_0061c060` :278562 | some UI state | 1,2,3,4,8 (empty cases) + default | default |
| `FUN_0061c440` :278707 | Scaleform `setTerritory` region data ptr | 1→…2→…3→…4→… + default | default |
| `FUN_00709d70` :415532 | Bink intro movie soundtrack id (`0x7d1..0x7d6`) | keyed off `DAT_00cf255c` 1–4 + default `0x7d1` | default intro audio |
| `FUN_005c5840`/:233198 | English-variant check `*==0 || *==6` | english / english_uk | treated as non-English |
| `FUN_0060e9c0` :270708 | base HUD font (§5) | 8=Cyrillic else Latin | Latin |

None of these block a Latin eighth language from *functioning*; `FUN_006067b0` (a second, hardcoded
copy of the stringdb-hash selection) is the only one that could serve a stale hash, and even it
falls back to the english key rather than crashing. For a **Cyrillic/CJK** eighth language,
`FUN_0060e9c0` (font) is the one that genuinely requires a code touch.

---

## 7. Minimal native-hook recipe (pmc_bb ASI + data overlay)

Goal: register `polski` (example) as a selectable eighth language with its own `polski.wad` +
`polski-patch.wad` + stringdb, Latin script.

**On disk (data, additive):**
1. Build `.\Data\polski.wad` (**required** — §4 hard-exits without it) containing at minimum a
   `stringdb` container registered under key `(pandemic_hash_m2("polski"), 0x39e5e978)`, plus the
   per-language font atlases `polski_18_*` / `polski_20_*` (path (1) in §5). Optionally
   `.\Data\polski-patch.wad` for overlay text. Gate the build with `aset_refcheck` and verify by
   sha256 (never merge into `vz.wad`; ship via the language WAD itself, which is its own mount slot).

**In memory (ASI hook — because membership is code, §2):**
2. **Get the name into the table.** Cleanest: **repurpose an unused slot** rather than grow the
   table (slot 9 is occupied). Overwrite the pointer at `0x00cf281c + 7*4` (slot 7 `allcaps`) — or
   slot 6 `english_uk` — to point at a static `"polski\0"` string the ASI owns (its own module
   memory is fine; the engine only ever reads it). This keeps the `≤8` bound and all switches valid.
   *(Growing to a true 10th slot means relocating the whole table + repointing every
   `(&PTR_s_english_00cf281c)[...]` base — far more invasive; not recommended.)*
3. **Force the index.** After the localization struct is allocated but before states 10–13 run,
   set `*DAT_01176018 = 7` (the repurposed slot). Also set `DAT_00cf255c = 7` for the consumers that
   read the detected index (`FUN_00709d70`, and to keep `FUN_00826a90` from re-detecting). Because
   the retail non-English write path is behind a SecuROM thunk (§1, §9), the robust approach is to
   **write these two globals from the ASI at the right time** rather than to route through the
   game's own setter. Ordering constraint: the writes must land **before** `FUN_004bfaf0` reaches
   step 10 (base-WAD open) and before the first `FUN_004b87a0` stringdb request.
4. **(Latin only)** No font-switch patch needed *if* `fonts_enext` covers the glyphs or the
   `polski_18/20` atlases fully cover them via path (1). **Verify glyph coverage** — this is the
   most likely silent failure.

**What CANNOT be done without an exe/code patch:**
- A **non-Latin** eighth language (Cyrillic/CJK) needs `FUN_0060e9c0` (0x0060e9c0) altered/hooked to
  pick a Cyrillic/CJK base atlas — the index==8 branch is hardcoded.
- Perfectly-correct behavior in the secondary hardcoded switches (§6, esp. `FUN_006067b0`) would
  need those tables extended; acceptable to leave on English fallback for a first cut.
- Growing the language *count* past 9 (true new slot) requires relocating/repointing the table.
- A shipped in-menu **language selector** does not exist on PC; exposing runtime switching means
  installing a native `SetLanguage`(index) and adding a Lua/Scaleform widget that calls it. For a
  fixed single new language, forcing the index at boot (step 3) avoids all of that.

**Net:** repurposing slot 7 + forcing the index (2 pointer/int writes) + a name-driven `polski.wad`
is the whole recipe for a Latin eighth language. That is a small ASI hook plus a data WAD — **no exe
byte-patch strictly required** for the Latin case (the name-table pointer and the two index globals
are all in writable `.data`, patchable live).

---

## 8. Evidence trail (quick index)

- Name table dump: raw bytes at `0x00cf281c` (file `0x8f281c`), 9 entries → §1.
- Mount: `FUN_004bfaf0` :98213 (dispatch), `FUN_004bfe20` :98383 (`<name>.wad`, exit-on-fail),
  `FUN_004bfef0` :98422 (`<name>-patch.wad`).
- Stringdb hash: `FUN_004b87a0` :95018 (FNV-1a `|0x20`/`^0x2a`, type `0x39e5e978`); second copy
  `FUN_006067b0` :265996 (hardcoded per-index).
- Index probe/bound: `FUN_00826a10` :615980 (`8 < iVar5`); OS-locale detect `FUN_00826a90` :616022.
- Struct alloc/init: `FUN_00630b20` :288590-ish, `FUN_004c2190` :99850 (0xd0 bytes, offset 0 = index).
- Font: name-driven `FUN_004644b0` :50898 (`"%s_%s"`); index-hardcoded `FUN_0060e9c0` :270698.
- Lua read-only usage: `mrxsoundbanks.lua:83`, `mrxbriefing.lua:1189-1210`; no selector, no setter.
- Locale content map: `docs/mercs2_install_registry_contract.md §4`; stringdb "which wins":
  `docs/fixpack/wad_duplicate_inventory.md §C`; mount/basename: same doc §B.2/§B.5.

---

## 9. Open questions / unverified

1. **The non-English index write path.** Static decomp only ever writes `*DAT_01176018 = 0`. The
   real write that applies a German/French/Russian selection is not statically reachable — inferred
   to live in SecuROM-spliced code (cf. the `"vz"` basename setter, `§B.5`). **Not yet pinned.** The
   recipe sidesteps it by writing the globals from the ASI, but the exact *frame/order* at which to
   write (relative to `FUN_004c2190` struct alloc and `FUN_004bfaf0` step 10) should be confirmed
   live (read-only) before trusting it. **Unverified.**
2. **`GetLanguageNum` / `GetLanguageName` implementations** (VAs `0x007B5750` / `0x007B5740`) were
   not isolated as discrete decomp entries — confirm they return `*DAT_01176018` / the table string
   (assumed from Lua behavior, not read). Whether either is a viable native re-point for a setter is
   open.
3. **`fonts_enext` glyph coverage for Polish diacritics** — unknown; must be inspected in the atlas.
   If incomplete, path (1) `polski_18/20` atlases must fully cover, or the menu will box-glyph.
4. **Does the shipped `japanese`/`allcaps` machinery imply a CJK atlas path exists** that a new CJK
   language could borrow (vs. `FUN_0060e9c0` only knowing Latin/Cyrillic)? Not investigated.
5. **Registry-driven selection vs. ASI-forced index** — whether setting registry `Language=polski`
   (once slot is repurposed) cleanly drives `FUN_00826a10` end-to-end (it should, since that path is
   name-`_stricmp`-driven) or whether OS-locale detect `FUN_00826a90` overrides it. Confirm which
   wins. Static reading says the INI `Language` name is applied first and only falls back to locale
   when `DAT_00cf255c == -1`, but the struct-sync gap (#1) makes this worth a live check.
6. **Multiplayer/region gating** (`s_mercenaries2_enru` region string, `DAT_00cffbd3`) — a new
   language's interaction with region checks was not examined.
