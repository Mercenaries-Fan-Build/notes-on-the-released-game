---
status: draft
evidence: static-proven / runtime-unverified
supersedes: []
related:
  - docs/reverse_engineer/eighth_language_wiring.md
  - docs/fixpack/wad_duplicate_inventory.md
---

# Language ASI — hook contract

The build contract for a **dedicated language ASI** that makes an *added* language (one the
install never shipped) selectable, plus the config Modkit writes and the ASI reads. It is the
runtime half of "Route C" in the Localization design; the RE foundation is
[`eighth_language_wiring.md`](./eighth_language_wiring.md).

**Design owner split.** The workshop *authors* the language (`<name>.wad` = stringdb + font
atlases). Modkit *deploys and selects* it (drops the WAD, the ASI, and a config). The **ASI**
*applies* the selection at boot. `pmc_bb.dll` stays logging/compat-only — this is a separate
plugin, loaded by the same ASI loader, in the pattern of `dlc_enable.asi`.

**Target build.** The DRM-free exe (`mercs2_nodrm_v3` / decrypted). All addresses below are the
runtime VAs of the unpacked image; they are also valid at runtime on the licensed/SecuROM copy,
because SecuROM unpacks in place and the ASI installs its detour *after* load (loading after
`pmc_bb` guarantees post-unpack). We do **not** touch any SecuROM-spliced code.

---

## 1. RE foundation

Established statically (proven addresses + reads); cross-referenced in `eighth_language_wiring.md`.

### 1.1 The index global

`DAT_01176018` is **a pointer to a 0xD0-byte language struct**, not the index itself. The
**runtime language index is `*DAT_01176018`** (struct offset 0). The struct is allocated and
zeroed once by `FUN_00630b20` (`*index = 0` → **English is the default**); flags live at struct
offsets `+0x4d`, `+0x8d`, `+0xcd` (the `+0xcd` flag is a region/render toggle, unrelated to text).

To force the index the ASI writes through the pointer:

```c
// *(*(int**)0x01176018) = slot;   with a null-guard on the pointer
int** pp = (int**)0x01176018;
if (*pp) (*pp)[0] = slot;
```

### 1.2 The name table and the slots

The language names are a 9-entry `char*` array at **`0x00CF281C`** (`&PTR_s_english_00cf281c`),
indexed by `*DAT_01176018`. A hard `index <= 8` bound guards it. Order (proven from the font
switch and the per-index hash switch):

| index | slot string | addr of the `char*` | notes |
|---:|---|---|---|
| 0 | `english` | `0x00CF281C` | default (struct zeroed) |
| 1 | `spanish` | `0x00CF2820` | |
| 2 | `italian` | `0x00CF2824` | |
| 3 | `french` | `0x00CF2828` | |
| 4 | `german` | `0x00CF282C` | |
| 5 | `japanese` | `0x00CF2830` | CJK |
| 6 | `english_uk` | `0x00CF2834` | |
| **7** | **`allcaps`** | **`0x00CF2838`** | **unused → repurpose target** |
| 8 | `russian` | `0x00CF283C` | Cyrillic (font index 8) |

Slot **7 (`allcaps`)** is the repurpose target: it is not a real shipped language, so overwriting
its `char*` costs nothing and keeps the `<= 8` bound and every index `switch` valid.

### 1.3 The setter we do NOT chase

The game's own *non-English* write to `*DAT_01176018` is **not in ordinary `.text`** — it lives in
the SecuROM-spliced high region (`0x0247xxxx`), invisible to the static decomp even after
re-ingest, and reads `(&PTR_s_english)[*unaff_EDI]` from there. We never hook it. We force the
index at a clean **consumer** instead (§3.3).

---

## 2. Consumption points (the clean surface)

Every reader of the index is an ordinary, thunk-free function, verified in the current decomp:

| Function | Reads the index to build… | When |
|---|---|---|
| **`FUN_004bfe20`** | `sprintf(".\Data\%s.wad", …[*idx])` → **language WAD mount** | mount SM state 10 (`FUN_004bfaf0`) |
| `FUN_004bfef0` | `".\Data\%s-patch.wad"` → language patch mount | state 12 |
| `FUN_004b87a0` | hashes the slot string → stringdb key `× 0x39E5E978` | shell↔gameplay transitions |
| `FUN_0060e9c0` | `*idx == 8 → fonts_ru (Cyrillic); else → fonts_enext` | font selection |

Because these read the *same* `*DAT_01176018`, forcing it once (persistently) at the first
consumer makes the mount, the stringdb key, and the font choice all agree.

---

## 3. The hook design

### 3.1 Load early, act late

Loading right after `pmc_bb` puts DllMain **many frames before** the game's (invisible) locale
write. So:

- **Static work → DllMain.** Repointing a name-table `char*` touches table *contents*, which the
  game never rewrites at boot. Safe to do once, early.
- **The index force → deferred to a consumer.** Writing the index in DllMain would be clobbered by
  the later locale write. We defer it to `FUN_004bfe20`, which runs *after* the locale write and
  *immediately before* the language WAD opens.

### 3.2 DllMain — repoint the slot (static)

```c
static const char* LANG_NAME = "polski";      // from config; NUL-terminated, static lifetime
#define NAME_TABLE 0x00CF281C
#define SLOT       7                            // from config; default 7 (allcaps)

// The table is very likely .rdata — make the one pointer-slot writable first.
void* slot_addr = (void*)(NAME_TABLE + SLOT*4);
DWORD old;
VirtualProtect(slot_addr, sizeof(void*), PAGE_READWRITE, &old);
*(const char**)slot_addr = LANG_NAME;
VirtualProtect(slot_addr, sizeof(void*), old, &old);
```

Guard the whole thing behind `enabled` in the config, and behind `name != NULL` (a shipped-language
force needs only the index, no repoint — §4).

### 3.3 Detour `FUN_004bfe20` — force the index (deferred)

```c
// installed in DllMain (MinHook, as pmc_bb uses; or an inline trampoline)
void __cdecl hk_FUN_004bfe20(void) {
    int** pp = (int**)0x01176018;
    if (*pp) (*pp)[0] = SLOT;      // idempotent; re-entered on the shell↔vz swap
    orig_FUN_004bfe20();           // call through — it sprintf's ".\Data\<slot>.wad" and opens it
}
```

`FUN_004bfe20` is `void(void)` reading state through `ESI` (the WAD-manager reader object) — the
detour needs no argument marshalling. Install the hook in DllMain; it *fires* at mount time.

### 3.4 Why `FUN_004bfe20` is the right consumer

- It is the **first** index consumer in boot order (state 10), so setting the index there feeds
  every later reader (patch mount, stringdb hash, fonts).
- It runs **strictly after** the locale write (earlier in boot) → nothing clobbers us afterward.
- It runs **immediately before** the language slot mounts → the forced index picks the WAD.
- It is **re-entered** on every close-all→reopen-all shell↔vz swap (`FUN_004bf8c0`) → the force is
  reapplied each cycle; the write is idempotent.

This resolves the "exact boot frame" question by construction — we intercept at the read site, not
the hidden write.

---

## 4. Modkit ↔ ASI config contract

### 4.1 The config file

Modkit writes it; the ASI reads it in DllMain. A small INI next to the plugin
(`scripts/mercs2_language.ini`) or the game root. Proposed schema:

```ini
[language]
enabled = true          ; master switch; false = ASI no-ops
index   = 7             ; the slot to force *DAT_01176018 to (default 7 = allcaps)
name    = polski        ; OPTIONAL. if set, repoint slot[index] to this string (custom language)
                        ;   - must equal the <name>.wad basename the game will open
                        ;   - omit to force a SHIPPED language (index only, no repoint)
script  = latin         ; latin | cyrillic | cjk  (informs font handling; latin = no extra work)
```

- **Custom language** (Route C): `index = 7`, `name = polski`, ship `polski.wad` (+ fonts).
- **Force a shipped language** (locale-independent): `index = <exe index>`, `name` omitted. (This
  overlaps the registry-`Locale` lever from `region.rs`; either works — pick one per install.)

### 4.2 What Modkit deploys

| Artifact | How | Modkit reuse |
|---|---|---|
| the language ASI | copy to the ASI-loader folder (`scripts/` default) | `commands/deploy.rs`, `deploy_wad.rs` (`asi_target`) |
| `<name>.wad` (+ `<name>-patch.wad`) + font atlases | into `data/` | `deploy_wad.rs` / `prebuilt.rs` on `mercs2_formats::patch_wad` |
| `mercs2_language.ini` | write from the selector state | new (small) |

Modkit validation before it lets the user select: `<name>.wad` present; font atlases cover the
translation's glyphs (a read the workshop's glyph-coverage scan can hand off); exactly **one**
custom language active (only slot 7 is repurposed).

### 4.3 ⚠ The index map is the exe's, not Modkit's

Modkit's existing `commands/language.rs` (the disk janitor) lists languages in its *own* order
(`English, German, Spanish, French, Italian, Russian`). That order is **not** the exe index order.
When Modkit forces an index for a *shipped* language it MUST use the exe map from §1.2
(`english=0, spanish=1, italian=2, french=3, german=4, japanese=5, english_uk=6, allcaps=7,
russian=8`). Mixing the two is a silent wrong-language bug.

---

## 5. Fonts and scripts

`FUN_0060e9c0` selects fonts purely on the index: `*idx == 8` → `fonts_ru` (Franklin Gothic /
Cyrillic); **everything else → `fonts_enext`** (Gunplay / Latin-extended).

- **Latin** language on slot 7 → falls into the `else` → correct Latin fonts **for free**. No font
  work beyond confirming `fonts_enext` covers the glyphs (e.g. Polish `Ł Ą Ę Ś Ż Ź Ć Ń` may need
  atlas additions — the workshop's cross-page font task).
- **Cyrillic** → either use index 8 (but that *is* Russian's slot) or patch `FUN_0060e9c0` to route
  slot 7 → `fonts_ru`. A second, tiny detour.
- **CJK** (index 5 / `japanese`) is a different asset shape entirely — out of scope for v1.

---

## 6. Caveats and limits

- **Index `switch`es that default to English.** A handful only enumerate cases 0–4 and 8 and
  default the rest to English: `FUN_006067b0` (index → per-language hash; default `0xB6A13123` =
  `english`), `FUN_0061c440` (`setTerritory`), `FUN_0061c060`. A Latin language on slot 7 hits the
  English default in these. They are region/territory/save-string paths, **not** the main UI text,
  so harmless for the text goal — noted so a stray English territory label isn't a surprise.
- **One custom language at a time.** Only slot 7 is repurposed, so the selector activates exactly
  one added language. Switching = rewrite the config + relaunch.
- **Boot-time, not live (v1).** The force applies at the next launch. A live in-game switch would
  drive the same close-all→reopen-all cycle (`FUN_004bf8c0`) after rewriting the index — a later
  enhancement that dovetails with an in-game selector on the Shell page.
- **`0x00CF2838` writability.** Assume `.rdata`; `VirtualProtect` the slot RW before writing
  (§3.2). Confirm in the live spike.

---

## 7. Verification plan (live, read-only — deferred until greenlit)

An x32dbg read-only pass on the DRM-free build, process paused, user-driven (never resume from the
tool — see the debugger discipline). Confirm, in order:

1. `*(void**)0x01176018` is non-null by the time `FUN_004bfe20` is first reached (the struct is
   alloc'd by `FUN_00630b20` earlier — verify).
2. Breakpoint `FUN_004bfe20`; on hit, read `*DAT_01176018` — confirm it is the *locale-derived*
   value (proves the locale write already ran, i.e. we are acting late enough).
3. Force `*DAT_01176018 = 7` + point `[0x00CF2838]` at a test `"polski"` and confirm the sprintf
   builds `.\Data\polski.wad` and the open is attempted.
4. Confirm `FUN_004b87a0` later hashes `"polski"` for the stringdb key, and `FUN_0060e9c0` takes
   the `else` (Latin) branch for index 7.
5. Confirm `FUN_004bfe20` is **re-entered** on a shell→vz→shell transition (the swap re-forces).
6. Confirm `0x00CF2838` is writable (or that `VirtualProtect` succeeds).

Until 1–6 pass, the runtime behaviour is **inferred from static reads**, not proven. The static
hook surface (addresses, reads, the load-early/act-late split) is solid; the live pass closes the
last gap before any ASI ships.

---

## 8. Address reference

| Symbol / addr | Role |
|---|---|
| `0x01176018` | `DAT_01176018` — pointer to the 0xD0 language struct; `*` = index (offset 0) |
| `0x00CF281C` | `PTR_s_english` — base of the 9-entry name `char*` table |
| `0x00CF2838` | name-table slot **7** (`allcaps`) — repurpose target |
| `0x00630b20` | `FUN_00630b20` — allocs + zeroes the struct (index → 0 = English) |
| `0x004bfe20` | `FUN_004bfe20` — **detour target**; language WAD mount (`.\Data\%s.wad`) |
| `0x004bfef0` | `FUN_004bfef0` — language patch mount (`.\Data\%s-patch.wad`) |
| `0x004b87a0` | `FUN_004b87a0` — stringdb request (name hash × `0x39E5E978`) |
| `0x0060e9c0` | `FUN_0060e9c0` — font switch (`idx==8` Cyrillic else Latin) |
| `0x004bfaf0` | `FUN_004bfaf0` — mount state machine (calls the openers) |
| `0x004bf8c0` | `FUN_004bf8c0` — close-all→reopen-all swap driver |
| `0x39E5E978` | `stringdb` type hash (the language table's asset type) |
