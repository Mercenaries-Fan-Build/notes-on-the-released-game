# UI-related FFCS blocks (Mercenaries 2 PC)

This document inventories **decompressed `.block` blobs** that carry HUD/menus, button prompts, minimap/PDA chrome, fonts, and localization strings. Paths match the game’s internal `paths.txt` entries (backslashes as stored).

**Related tooling**

- [`tools/sges_decompress.py`](../tools/sges_decompress.py) — `--index N` decompresses the *n*th path in `paths.txt` (0-based `N`, same order as `scripts/extract_all_from_paths.sh`).
- [`tools/texture_extractor.py`](../tools/texture_extractor.py) — UCFX-wrapped **DXT1/DXT5** mip chains → DDS/PNG (used by [`scripts/stage2_review_extract.sh`](../scripts/stage2_review_extract.sh)).
- [`tools/dialog_extractor.py`](../tools/dialog_extractor.py) — bracket keys / localization-like strings in blobs.
- [`tools/ucfx_parser.py`](../tools/ucfx_parser.py) — chunk/tag scan when debugging UCFX layout.

**Format note:** Sampled `shell.wad` UI blobs under `output/extracted/batch_shell/blocks/` show **`UCFX` at offset 0x14 (20)** and **`DXT1` / `DXT5`** payloads inside envelopes (e.g. `font_16_main` DXT5 at ~0xCA, `c31937` DXT5 at ~0x83, `scaleform_shell` many UCFX/DXT pairs). No separate parser is required for atlas bitmaps once a block is sges-decompressed.

**Status columns** (typical dev tree after partial/full batch extract):

- **Decompressed** — a matching `*.block.bin` exists under `output/extracted/batch_<pack>/blocks/` (or legacy `output/batch_*`).
- **Stage 2** — review tree exists under `output/extracted/review/<batch_pack>/<stem>/` (mesh/texture/dialog pipeline). If that directory is missing, treat as **not reviewed**.

---

## 1. `shell.wad` → `output/extracted/ffcs_shell/paths.txt`

Front-end menu, shell HUD copy, Scaleform shell textures, fonts, cloud backdrop, save-slot assets, and per-language string tables.

| Path (from `paths.txt`) | Index | Decompressed | Stage 2 | Primary extractor / notes |
|-------------------------|------:|:-------------:|:-------:|----------------------------|
| `blocks\Shell\ui_shell_P000_Q3.block` | **35** | yes | no | `texture_extractor.py` — main menu / shell atlas |
| `blocks\Shell\ui_hud_P000_Q3.block` | **33** | yes | no | `texture_extractor.py` — shell HUD atlas |
| `blocks\Shell\scaleform_shell_P000_Q3.block` | **18** | yes | no | `texture_extractor.py` — menu icons (`shell_disc_*`, `shell_explosion_*`, `shell_i*` strings in blob); **likely cursor** lives here or in `ui_shell` |
| `blocks\Shell\cloud_noise_P000_Q3.block` | **32** | yes | no | `texture_extractor.py` — menu backdrop noise |
| `blocks\Shell\c31937_P000_Q3.block` | **1** | yes | no | `texture_extractor.py` — generic UCFX+DXT tiles |
| `blocks\Shell\c32603_P000_Q3.block` | **2** | yes | no | `texture_extractor.py` |
| `blocks\Shell\c32641_P000_Q3.block` | **3** | yes | no | `texture_extractor.py` |
| `blocks\Shell\ps3saveassets_P000_Q3.block` | **5** | yes | no | `texture_extractor.py` if DXT present; else tiny asset |
| `blocks\Shell\ps3saveassets_it_P000_Q3.block` | **4** | yes | no | same |
| `blocks\Shell\ps3saveassets_fr_P000_Q3.block` | **23** | yes | no | same |
| `blocks\Shell\font_16_main_P000_Q3.block` | **10** | yes | no | `texture_extractor.py` — font atlas |
| `blocks\Shell\font_16_tm_P000_Q3.block` | **11** | yes | no | `texture_extractor.py` |
| `blocks\Shell\font_16_buttons_P000_Q3.block` | **19** | yes | no | `texture_extractor.py` — button-glyph atlas |
| `blocks\Shell\_shell_bold_font_P000_Q3.block` | **6** | yes | no | UCFX metadata / metrics — **no DXT** in sampled blob; use `ucfx_parser.py`; unlikely PNGs |
| `blocks\Shell\_shell_bold_italic_font_P000_Q3.block` | **7** | yes | no | same |
| `blocks\Shell\_shell_normal_font_P000_Q3.block` | **27** | yes | no | same |
| `blocks\Shell\_shell_font_glyphs_P000_Q3.block` | **28** | yes | no | same |
| `blocks\Shell\common_P000_Q3.block` | **8** | yes | no | `dialog_extractor.py` (+ textures if present) |
| `blocks\Shell\japanese_P000_Q3.block` | **9** | yes | no | `dialog_extractor.py` |
| `blocks\Shell\russian_P000_Q3.block` | **24** | yes | no | `dialog_extractor.py` |
| `blocks\Shell\italian_P000_Q3.block` | **25** | yes | no | `dialog_extractor.py` |
| `blocks\Shell\spanish_P000_Q3.block` | **26** | yes | no | `dialog_extractor.py` |
| `blocks\Shell\english_P000_Q3.block` | **29** | yes | no | `dialog_extractor.py` |
| `blocks\Shell\german_P000_Q3.block` | **30** | yes | no | `dialog_extractor.py` |
| `blocks\Shell\french_P000_Q3.block` | **34** | yes | no | `dialog_extractor.py` |

**Same pack, out of scope for UI art (reference only):** `shell_base`, `musicdata`, `mercs2globals`, `music`, `lti_precache*`, `resident` — audio/globals/lighting/resident data, not menu texture sets.

---

## 2. `vz.wad` → `output/extracted/ffcs_vz/paths.txt`

In-game HUD/shell overlays, minimap, PDA/support/vehicle store icons, Xbox button/joystick prompt art, and font atlases duplicated for the world pack.

**Decompressed:** UI rows below use **high indices (~3k–3.5k)**. A partial batch (only the first *N* `paths.txt` lines) will **not** materialize these files until `sges_decompress.py --index <idx>` is run or batch extract reaches those indices. **Stage 2:** same as shell — only after `stage2_review_extract.sh` / `stage2_parallel.sh`.

| Path (from `paths.txt`) | Index | Decompressed | Stage 2 | Primary extractor / notes |
|-------------------------|------:|:-------------:|:-------:|----------------------------|
| `blocks\VZ\ui_shell_P000_Q3.block` | **3525** | no* | no | `texture_extractor.py` |
| `blocks\VZ\ui_hud_P000_Q3.block` | **3505** | no* | no | `texture_extractor.py` |
| `blocks\VZ\scaleform_genericbackground_P000_Q3.block` | **3497** | no* | no | `texture_extractor.py` |
| `blocks\VZ\scaleform_fanfare_P000_Q3.block` | **3244** | no* | no | `texture_extractor.py` |
| `blocks\VZ\minimap_P000_Q3.block` | **3234** | no* | no | `texture_extractor.py` — minimap UI art |
| `blocks\VZ\scaleform_pdasupporticons_P000_Q3.block` | **3048** | no* | no | `texture_extractor.py` — PDA/support “store” icons |
| `blocks\VZ\scaleform_pdavehiclesicons_P000_Q3.block` | **3451** | no* | no | `texture_extractor.py` — vehicle shop/PDA icons |
| `blocks\VZ\icon_hijack_xbox_button_a_P000_Q3.block` | **3247** | no* | no | `texture_extractor.py` |
| `blocks\VZ\icon_hijack_xbox_button_b_P000_Q3.block` | **3564** | no* | no | `texture_extractor.py` |
| `blocks\VZ\icon_hijack_xbox_button_x_P000_Q3.block` | **3253** | no* | no | `texture_extractor.py` |
| `blocks\VZ\icon_hijack_xbox_button_y_P000_Q3.block` | **3031** | no* | no | `texture_extractor.py` |
| `blocks\VZ\icon_hijack_xbox_joystick_left_P000_Q3.block` | **3010** | no* | no | `texture_extractor.py` |
| `blocks\VZ\icon_hijack_xbox_joystick_right_P000_Q3.block` | **3509** | no* | no | `texture_extractor.py` |
| `blocks\VZ\icon_hijack_xbox_joystick_up_P000_Q3.block` | **3182** | no* | no | `texture_extractor.py` |
| `blocks\VZ\icon_hijack_xbox_joystick_down_P000_Q3.block` | **3447** | no* | no | `texture_extractor.py` |
| `blocks\VZ\icon_hijack_xbox_joystick_leftright_P000_Q3.block` | **3477** | no* | no | `texture_extractor.py` |
| `blocks\VZ\icon_hijack_joystick_leftright_P000_Q3.block` | **3300** | no* | no | `texture_extractor.py` |
| `blocks\VZ\font_16_main_P000_Q3.block` | **3079** | no* | no | `texture_extractor.py` |
| `blocks\VZ\font_16_tm_P000_Q3.block` | **3089** | no* | no | `texture_extractor.py` |
| `blocks\VZ\font_16_buttons_P000_Q3.block` | **3228** | no* | no | `texture_extractor.py` |
| `blocks\VZ\font_16_xbox_buttons_P000_Q3.block` | **3338** | no* | no | `texture_extractor.py` |
| `blocks\VZ\common_18_xbox_buttons_P000_Q3.block` | **3394** | no* | no | `texture_extractor.py` |
| `blocks\VZ\common_20_xbox_buttons_P000_Q3.block` | **3436** | no* | no | `texture_extractor.py` |

\*Set to **yes** when `output/extracted/batch_vz/blocks/` contains a file whose stem matches the path (e.g. `*ui_hud_P000_Q3.block.bin`). Until then, **no**.

---

## 3. `Loading.wad` → `output/extracted/ffcs_Loading/paths.txt`

Loading screen art and loading-time fonts.

| Path (from `paths.txt`) | Index | Decompressed | Stage 2 | Primary extractor / notes |
|-------------------------|------:|:-------------:|:-------:|----------------------------|
| `blocks\Loading\loadingscreen_overlay_standalone_P000_Q3.block` | **6** | yes | no | `texture_extractor.py` |
| `blocks\Loading\global_loading_skull_P000_Q3.block` | **3** | yes | no | `texture_extractor.py` |
| `blocks\Loading\fonts_enext_P000_Q3.block` | **5** | yes | no | `texture_extractor.py` |
| `blocks\Loading\fonts_enext_f0_P000_Q3.block` | **1** | yes | no | `texture_extractor.py` |
| `blocks\Loading\fonts_ru_P000_Q3.block` | **7** | yes | no | `texture_extractor.py` |
| `blocks\Loading\fonts_ru_f0_P000_Q3.block` | **2** | yes | no | `texture_extractor.py` |
| `blocks\Loading\loading_base_P000_Q3.block` | **0** | yes | no | Mostly bootstrap — run `ucfx_parser.py` / `texture_extractor.py` as needed |
| `blocks\Loading\resident_P000_Q3.block` | **4** | yes | no | Resident pack data — not primary UI art; optional |

---

## 4. Deferred / out of current UI scope

These are **Scaleform mission/contact briefing** and **new contact** cards (dossier-style full-screen art). They are **not** counted as core HUD/menu/button/minimap/PDA chrome for the inventory above, but indices are recorded so they are not lost.

### `scaleform_*briefing` (`vz.wad`)

| Path | Index |
|------|------:|
| `blocks\VZ\scaleform_gurcon002briefing_P000_Q3.block` | 3027 |
| `blocks\VZ\scaleform_meccon001briefing_P000_Q3.block` | 3049 |
| `blocks\VZ\scaleform_allcon001briefing_P000_Q3.block` | 3078 |
| `blocks\VZ\scaleform_allcon002briefing_P000_Q3.block` | 3127 |
| `blocks\VZ\scaleform_pmccon002briefing_P000_Q3.block` | 3218 |
| `blocks\VZ\scaleform_chicon004briefing_P000_Q3.block` | 3262 |
| `blocks\VZ\scaleform_pmccon003briefing_P000_Q3.block` | 3264 |
| `blocks\VZ\scaleform_jetcon001briefing_P000_Q3.block` | 3299 |
| `blocks\VZ\scaleform_chicon002briefing_P000_Q3.block` | 3302 |
| `blocks\VZ\scaleform_allcon004briefing_P000_Q3.block` | 3402 |
| `blocks\VZ\scaleform_chicon001briefing_P000_Q3.block` | 3456 |
| `blocks\VZ\scaleform_pmcconbriefing_P000_Q3.block` | 3473 |
| `blocks\VZ\scaleform_gurcon001briefing_P000_Q3.block` | 3576 |

### `scaleform_newcontact*` (`vz.wad`)

| Path | Index |
|------|------:|
| `blocks\VZ\scaleform_newcontactshared_P000_Q3.block` | 3085 |
| `blocks\VZ\scaleform_newcontactallies_P000_Q3.block` | 3250 |
| `blocks\VZ\scaleform_newcontactpirates_P000_Q3.block` | 3355 |
| `blocks\VZ\scaleform_newcontactchinese_P000_Q3.block` | 3382 |
| `blocks\VZ\scaleform_newcontactguerillas_P000_Q3.block` | 3425 |
| `blocks\VZ\scaleform_newcontactoilcompany_P000_Q3.block` | 3561 |

---

## 5. Notes and open questions

1. **Cursor:** There is no dedicated `cursor_*.block` in `paths.txt`. Expect the hardware cursor sprite **inside** `ui_shell` or `scaleform_shell` atlases; it will appear as a named texture slice after `texture_extractor.py` runs on those blobs.

2. **“Shop” imagery:** In-game purchases use the **PDA**. The closest dedicated chunks are **`scaleform_pdasupporticons`** and **`scaleform_pdavehiclesicons`** — not a separate “storefront” block name.

3. **World map vs minimap:** **`minimap_P000_Q3.block`** is the **UI minimap** art. Large **world terrain / freeway** textures live in blocks such as `global_freewaytextures_P000_Q3.block` and many `vz_state_*` chunks — **world content**, not classified here as UI.

4. **`English.wad`:** `blocks\English\shell_P000_Q3.block` is at **line 18 → index 17** in `ffcs_English/paths.txt` (localized shell strings / VO-adjacent data). Not duplicated in the tables above; decompress with `sges_decompress.py` on `ffcs_English` if you need that pack in isolation.

5. **Regenerating this list:** Line numbers in `paths.txt` are **1-based**; **index = line − 1**. Re-verify with `nl -ba output/extracted/ffcs_<pack>/paths.txt | grep <fragment>` after any tooling change.
