# Loading.wad & shell.wad — FFCS Structure Analysis

Deep structure analysis of two auxiliary WAD archives used by Mercenaries 2 (PC) for loading screens and the front-end shell/menu system.

**Tool:** [`tools/analyze_wad.py`](../tools/analyze_wad.py)

---

## Overview

| Property | Loading.wad | shell.wad | vz.wad (reference) |
|----------|-------------|-----------|---------------------|
| File size | 2.38 MB | 28.25 MB | ~2,445 MB |
| FFCS version | 2 | 2 | 2 |
| Declared chunk count | 5 | 5 | 7 (only 5 real rows) |
| INDX block count | 8 | 36 | 11,370 |
| PTHS path count | 8 | 36 | 11,370 |
| ASET entry count | 10 | 575 | 30,645 |
| DATA chunk size | 352 KB | 26.2 MB | ~2,443 MB |
| sges blocks found | 8 | 36 | 11,370 |
| Total decompressed | 0.48 MB | 25.7 MB | — |

All three WADs share identical FFCS v2 format with the same 5 chunk types (INDX, DATA, CSUM, ASET, PTHS). The key structural differences are scale — Loading.wad is minimal (8 blocks), shell.wad is moderate (36 blocks), vz.wad is massive (11,370 blocks).

---

## 1. Loading.wad

### 1.1 Purpose

Contains assets needed during level loading: a loading screen overlay texture, the skull logo, font atlases (Latin/Cyrillic), and a `resident` block with bootstrap configuration.

### 1.2 FFCS Chunk Layout

| Chunk | Offset | Meta | Size | Notes |
|-------|--------|------|------|-------|
| INDX | 0x00008000 | 8 | 96 B | 8 entries × 12 bytes |
| DATA | 0x00208000 | 36 | 352 KB | All sges blocks |
| CSUM | 0x37EA846E | 3 | — | Hash/identifier (exceeds file size, not a file offset) |
| ASET | 0x00008060 | 10 | 160 B | 10 entries × 16 bytes |
| PTHS | 0x00008100 | 8 | 2,048 KB | Path strings + null-padded region |

**Observation:** The PTHS chunk is 2 MB despite only containing 8 short path strings. This is because the PTHS region extends to the DATA chunk offset (0x208000 - 0x8100 = ~2 MB), similar to vz.wad and shell.wad — the engine likely pre-allocates a fixed-size region between PTHS and DATA.

### 1.3 Block Inventory (all 8 blocks)

| # | Path | Decomp. Size | Type Hash | Content |
|---|------|-------------|-----------|---------|
| 0 | `blocks\Loading\loading_base_P000_Q3.block` | 11,012 B | `0xE6B81A54` (layer) | CHDR + enum definitions (FireAngleEnum, etc.) — entity schema |
| 1 | `blocks\Loading\fonts_enext_f0_P000_Q3.block` | 131,229 B | `0xF011157A` (texture) | DXT font atlas — Latin extended charset bitmap |
| 2 | `blocks\Loading\fonts_ru_f0_P000_Q3.block` | 262,298 B | `0xF011157A` (texture) | DXT font atlas — Russian/Cyrillic charset bitmap |
| 3 | `blocks\Loading\global_loading_skull_P000_Q3.block` | 4,259 B | `0xF011157A` (texture) | DXT — small skull logo image |
| 4 | `blocks\Loading\resident_P000_Q3.block` | 66,676 B | mixed | 3 entries: level (`0xEA4829D5`), script (`0x42498680`), unknown (`0xFE0E8320`) |
| 5 | `blocks\Loading\fonts_enext_P000_Q3.block` | 6,300 B | `0xFE0E8320` | Font metrics/kerning data (no DXT) |
| 6 | `blocks\Loading\loadingscreen_overlay_standalone_P000_Q3.block` | 16,559 B | `0xF011157A` (texture) | DXT — loading screen overlay image |
| 7 | `blocks\Loading\fonts_ru_P000_Q3.block` | 10,289 B | `0xFE0E8320` | Font metrics/kerning data for Russian (no DXT) |

### 1.4 Type Hash Distribution

| type_hash | Resolved Name | Count | Description |
|-----------|---------------|-------|-------------|
| `0xF011157A` | texture | 4 | Font atlases + loading screen textures |
| `0xFE0E8320` | *(unknown)* | 2 | Font metric/kerning data (CFX + zlib payload) |
| `0xE6B81A54` | layer | 1 | Entity schema/enum definitions |
| `0xEA4829D5` | level | 1 | Level bootstrap data |
| `0x42498680` | script | 1 | Lua bytecode |

### 1.5 ASET Entries

All 10 ASET entries have `u1_type = 0xFFFFFFFF` (sentinel — no streaming dependency). This makes sense: loading assets must be fully resident, never streamed.

### 1.6 INDX Entries

| Entry | Page Index | WAD Offset | Page Count | Flags |
|-------|-----------|-----------|-----------|-------|
| 0 | 65 | 0x208000 | 1 | 0x8000 |
| 1 | 66 | 0x210000 | 1 | 0x8020 |
| 2 | 67 | 0x218000 | 2 | 0x8040 |
| 3 | 69 | 0x228000 | 1 | 0x8001 |
| 4 | 70 | 0x230000 | 3 | 0x8000 |
| 5 | 73 | 0x248000 | 1 | 0x8000 |
| 6 | 74 | 0x250000 | 1 | 0x8004 |
| 7 | 75 | 0x258000 | 1 | 0x8000 |

All blocks start at page_index 65 (0x208000 = 65 × 0x8000), confirming page size = 32 KB. Largest block spans 3 pages (96 KB compressed = `resident`).

---

## 2. shell.wad

### 2.1 Purpose

Contains everything needed for the front-end menu system: Scaleform UI textures (menus, icons, HUD elements), font atlases for all languages, localized string databases, music/sound bank metadata, cloud noise backdrop, and PS3 save-slot icons (cross-platform remnant).

### 2.2 FFCS Chunk Layout

| Chunk | Offset | Meta | Size | Notes |
|-------|--------|------|------|-------|
| INDX | 0x00008000 | 36 | 432 B | 36 entries × 12 bytes |
| DATA | 0x00208000 | 36 | 26.2 MB | All sges blocks |
| CSUM | 0x0DDFDE99 | 416 | — | Hash/identifier (exceeds file size) |
| ASET | 0x000081B0 | 575 | 9.0 KB | 575 entries × 16 bytes |
| PTHS | 0x0000A5A0 | 36 | 2,039 KB | Path strings + null-padded region |

### 2.3 Block Inventory (all 36 blocks)

#### Shell Framework Blocks

| # | Path | Decomp. Size | Primary Type | Content Description |
|---|------|-------------|--------------|---------------------|
| 0 | `shell_base_P000_Q3` | 11 KB | layer | Entity schema (same enum set as Loading/vz `*_base`) |
| 13 | `mercs2globals_P000_Q3` | 256 B | `0xE5273C14` | Global config (tiny — likely shell variable definitions) |
| 17 | `resident_P000_Q3` | 3.2 MB | mixed (65 entries) | Master shell resident block: GUI framework, texture atlases, metrics |

#### Scaleform / UI Texture Blocks

| # | Path | Decomp. Size | Entries | Content Description |
|---|------|-------------|---------|---------------------|
| 18 | `scaleform_shell_P000_Q3` | 35.6 MB* | **416** | Main Scaleform texture atlas — `shell_disc_*`, `shell_explosion_*`, `shell_i*` named textures |
| 33 | `ui_hud_P000_Q3` | 3.4 MB | 3 | HUD atlas: soundbank (19 KB) + config (1 KB) + wavebank (3.4 MB) |
| 35 | `ui_shell_P000_Q3` | 8.0 MB | 3 | Shell UI atlas: wavebank (7.9 MB) + config (364 B) + soundbank (6 KB) |
| 1 | `c31937_P000_Q3` | 262 KB | 1 | `global_gui_hud02` — DXT5 HUD texture |
| 2 | `c32603_P000_Q3` | 8.4 KB | 1 | `shell_platform_buttons` — DXT platform button icons |
| 3 | `c32641_P000_Q3` | 2.9 KB | 1 | Small DXT texture |
| 32 | `cloud_noise_P000_Q3` | 1.0 MB | 1 | `cloud_noise` — menu backdrop noise texture (1024×1024 assumed) |

*\*Note: `scaleform_shell` declared 35.6 MB uncompressed but only 458 KB was decompressed due to sges multi-segment limits — the full block is the largest in shell.wad.*

#### Font Blocks

| # | Path | Decomp. Size | Type | Content |
|---|------|-------------|------|---------|
| 6 | `_shell_bold_font_P000_Q3` | 7.3 KB | `0xFE0E8320` | Font metrics (bold) |
| 7 | `_shell_bold_italic_font_P000_Q3` | 7.4 KB | `0xFE0E8320` | Font metrics (bold italic) |
| 27 | `_shell_normal_font_P000_Q3` | 7.3 KB | `0xFE0E8320` | Font metrics (normal) |
| 28 | `_shell_font_glyphs_P000_Q3` | 14.1 KB | `0xFE0E8320` | Glyph definitions (all shell fonts) |
| 10 | `font_16_main_P000_Q3` | 65.8 KB | texture | DXT5 16px main font atlas |
| 11 | `font_16_tm_P000_Q3` | 740 B | texture | DXT tiny trademark font |
| 19 | `font_16_buttons_P000_Q3` | 8.4 KB | texture | DXT button glyph atlas |
| 8 | `common_P000_Q3` | 241.9 KB | texture (×12) | Font texture pack — 12 sub-entries (factions, rewards, objectives, buttons, quote, tm) |

Source paths in `common` reference `d:\projects\mercs2_pc\branches\snapshot\data\src\map\global\hud\fonts\*.ftga` — confirming Pandemic's internal build tree.

#### Language / Localization Blocks

| # | Path | Decomp. Size | Entries | Type Hashes Present |
|---|------|-------------|---------|---------------------|
| 29 | `english_P000_Q3` | 1.6 MB | 5 | font (`0x99E77ACE`×2) + stringdb (`0x39E5E978`) + texture (×2) |
| 24 | `russian_P000_Q3` | 1.6 MB | 9 | font (×2) + stringdb + texture (×6) |
| 25 | `italian_P000_Q3` | 1.6 MB | 7 | font (×2) + stringdb + texture (×4) |
| 26 | `spanish_P000_Q3` | 1.6 MB | 7 | font (×2) + stringdb + texture (×4) |
| 30 | `german_P000_Q3` | 1.6 MB | 7 | stringdb + font (×2) + texture (×4) |
| 34 | `french_P000_Q3` | 1.6 MB | 7 | font (×2) + stringdb + texture (×4) |
| 9 | `japanese_P000_Q3` | 266 KB | 1 | `0xFE0E8320` — Japanese font data (large single entry) |

Each language block bundles: **stringdb** (localized UI strings, ~1.4 MB each), **font** descriptors (for language-specific glyphs), and **texture** atlases (font bitmaps with extended charset).

Source paths reference `d:\projects\mercs2_pc\branches\snapshot\data\src\texts\fonts\<lang>_18_*.ftga` and `<lang>_20_*.ftga`.

#### Audio Blocks

| # | Path | Decomp. Size | Entries | Content |
|---|------|-------------|---------|---------|
| 12 | `musicdata_P000_Q3` | 72.2 KB | 2 | Music metadata: `0xC122545A` (49 KB) + `0xE8DF4D87` (23 KB) — track listings |
| 14 | `music_P000_Q3` | 31.5 KB | 3 | soundbank + wavebank + config — music playback system |

#### LTI Precache Blocks (Loading Transition Images)

| # | Path | Decomp. Size | Content |
|---|------|-------------|---------|
| 15 | `lti_precache_i1_P000_Q3` | 1.0 MB | Loading transition image — large DXT texture |
| 16 | `lti_precache5_P000_Q3` | 32.9 KB | Loading transition image — small DXT |
| 20 | `lti_precache8_P000_Q3` | 16.5 KB | Loading transition image — small DXT |
| 21 | `lti_precache1_P000_Q3` | 1.0 MB | Loading transition image — large DXT |
| 22 | `lti_precache12_P000_Q3` | 8.3 KB | Loading transition image — small DXT |
| 31 | `lti_precache_i5_P000_Q3` | 32.9 KB | Loading transition image — medium DXT |

These are pre-cached loading screen images (different scenes/levels), shown as quick-flash transitions.

#### PS3 Cross-Platform Remnants

| # | Path | Decomp. Size | Content |
|---|------|-------------|---------|
| 4 | `ps3saveassets_it_P000_Q3` | 214 B | 3 × binary (`0x8F0A54E2`, 54 B each) — PS3 save icon metadata |
| 5 | `ps3saveassets_P000_Q3` | 214 B | Same structure — default PS3 save assets |
| 23 | `ps3saveassets_fr_P000_Q3` | 214 B | Same structure — French PS3 save assets |

These contain `type_hash = 0x8F0A54E2` (**binary**) entries — PS3 save-game icon references left in the PC build.

### 2.4 Type Hash Distribution (across all 36 blocks)

| type_hash | Resolved Name | Occurrences | Blocks |
|-----------|---------------|-------------|--------|
| `0xF011157A` | texture | ~450+ | 18+ | Dominates — font atlases, UI textures, LTI images |
| `0xFE0E8320` | *(unknown)* | ~8 | 6 | Font metrics/kerning data, Japanese font data |
| `0x39E5E978` | stringdb | 6 | 6 | One per language (EN/RU/IT/ES/DE/FR) |
| `0x99E77ACE` | font | ~12 | 6 | Font descriptors (2 per language block) |
| `0xF753F6D0` | wavebank | 3 | 3 | Audio wave banks (ui_hud, ui_shell, music) |
| `0x9F8BCA10` | soundbank | 3 | 3 | Sound banks |
| `0xE5273C14` | *(unknown)* | 3 | 3 | Small config entries (co-occurs with audio) |
| `0x8F0A54E2` | binary | 9 | 3 | PS3 save-slot assets |
| `0xE6B81A54` | layer | 1 | 1 | Entity schema (`shell_base`) |
| `0x42498680` | script | 1 | 1 | Lua bytecode (in `resident`) |
| `0xC122545A` | *(unknown)* | 1 | 1 | Music metadata singleton |
| `0xE8DF4D87` | *(unknown)* | 1 | 1 | Music data singleton |

### 2.5 Notable Structural Features

1. **`scaleform_shell` is massive (416 UCFX entries)**: This single block contains the entire Scaleform texture atlas for the menu system — every icon, button, background panel, and UI element. The 35.6 MB uncompressed size makes it the largest block in shell.wad.

2. **`resident` is a multi-purpose bootstrap block (65 entries)**: Contains GUI framework code (`mrxguinumericbox`, `MrxGuiBase`), font scale constants (`_ksFontSmall`, `_knScaleBig`), color constants (`_knTextLitR/G/B`), font size bindings (`english_18`, `english_20`), and texture atlases.

3. **Language blocks are self-contained**: Each language bundle independently carries its stringdb + font descriptors + font texture atlases. The engine loads exactly one language block at startup.

4. **Cross-platform artifacts**: PS3 save-asset blocks survived the PC port. Their tiny size (214 B each, 54 B per entry) suggests they're just hash references, not actual icon image data.

5. **Pandemic source paths preserved**: The `common` block retains absolute build-machine paths (`d:\projects\mercs2_pc\branches\snapshot\data\src\...`), useful for understanding the original project structure.

### 2.6 INDX Notable Entries

The largest blocks by page count:

| Block | Page Index | Page Count | Span | Content |
|-------|-----------|-----------|------|---------|
| `scaleform_shell` | 99 | 39 | 1.2 MB compressed | 416 UI textures |
| `scaleform_shell` (cont.) | 138 | 352 | 11 MB | Main texture payload |
| `ui_shell` | 490+ | large | 6.4 MB | Shell UI wavebank |
| `ui_hud` | — | ~89 | 2.9 MB | HUD audio bank |

---

## 3. Comparison with vz.wad

### 3.1 Structural Similarities

- **Same FFCS v2 container format** — identical header layout, chunk types, 12-byte INDX entries
- **Same page size** (0x8000 = 32 KB) for block addressing
- **Same PTHS/DATA region layout** — PTHS at ~0x8000, DATA at 0x208000 (fixed 2 MB gap)
- **Same sges compression** — raw deflate, multi-segment, 64 KB sentinel
- **Same block file format** — count(4) + entries(16×N) + concatenated UCFX chunks + CSUM trailers
- **Same type_hash vocabulary** — all type hashes found in Loading/shell are a strict subset of vz.wad's 35 known types
- **CSUM chunk offset exceeds file size** in all three WADs — confirms CSUM `offset` is a hash/identifier, not a file pointer
- **ASET u1_type = 0xFFFFFFFF** — both Loading and shell use the sentinel value (no streaming dependencies), while vz.wad uses actual type_id values for streaming graph relationships

### 3.2 Key Differences

| Feature | Loading.wad / shell.wad | vz.wad |
|---------|------------------------|--------|
| Scale | 8 / 36 blocks | 11,370 blocks |
| Geometry (model type) | **None** | 4,407 entries |
| Animations | **None** | 4,261 entries |
| Havok physics | **None** | Present in model/animation blocks |
| Placement layers | Only schema (`*_base`) | 923 layer entries with 62k+ placements |
| Textures | UI/font/loading only | World textures (36,724 entries) |
| Stringdb | Per-language (6 langs) | 3 entries (english, japanese, allcaps) |
| ASET streaming | All sentinel (0xFFFFFFFF) | Real dependency graph |
| Declared chunk count | 5 (matches reality) | 7 (only 5 real rows) |

### 3.3 Asset Loading Model

The engine's WAD loading appears to follow this hierarchy:

1. **Loading.wad** → loaded first (boot); provides minimum assets to render a loading screen
2. **shell.wad** → loaded for front-end menu; fully self-contained UI/audio/localization
3. **vz.wad** → loaded when entering gameplay; provides world geometry, textures, placements, scripts

Loading.wad and shell.wad never need streaming (ASET = sentinel) because they're always fully resident during their respective phases. vz.wad uses streaming because 2.4 GB cannot be resident simultaneously.

---

## 4. `*_base` Block Pattern

Both `loading_base` and `shell_base` are structurally identical:
- Single UCFX entry with `type_hash = 0xE6B81A54` (layer)
- Size: exactly 10,992 bytes (chunk_size)
- Contains: CHDR tag + enum definitions (FireAngleEnum, CameraShakeTypeEnum, ConstantRandom, MediumRandom, HardRandom, ElevationHintEnum, DynamicRoadTypeEnum, WeaponProjectileTypeEnum, SemiAutomatic, etc.)

These are **ECS component schema definitions** — the entity-component enumerations needed by the layer system. Every WAD pack has one `*_base` block that registers the same enum vocabulary. The identical 10,992-byte size confirms they share the same schema snapshot.

---

## 5. ASET Observations

### Loading.wad (10 entries)

All entries have `u1_type = 0xFFFFFFFF`. The `u0_hash` values match block_file TOC `name_hash` fields:
- `0x6C2B27D6` → `fonts_enext` (metrics)
- `0xAD3108BF` → `fonts_ru` (metrics)
- `0x443F889B` → `global_loading_skull` (texture)
- `0x96FB0F27` → `resident` sub-entries (×2)
- `0x44142C14` → `fonts_ru_f0` (texture atlas)
- `0x30705573` → `fonts_enext_f0` (texture atlas)
- `0x96E497F3` → `resident` sub-entry
- `0x274E48B5` → `loading_base` (layer schema)
- `0x94BD9390` → `loadingscreen_overlay_standalone` (texture)

### shell.wad (575 entries)

575 ASET entries for 36 blocks (average ~16 per block). The `scaleform_shell` block alone contributes 416 entries — one per texture in its atlas. All use `u1_type = 0xFFFFFFFF`.

---

## 6. Scaleform Integration

The `scaleform_shell_P000_Q3` block (index 18) is the single most interesting asset in shell.wad:

- **416 UCFX texture entries** — named `shell_disc_*`, `shell_explosion_*`, `shell_i*` (icon codes)
- **35.6 MB uncompressed** — the bulk of shell.wad's data
- **type_hash = 0xF011157A (texture)** for all entries
- These are Scaleform GFx texture assets: the game uses Scaleform middleware for its menu/HUD rendering, and this block packages every UI bitmap into a single streamable unit

The naming pattern `shell_i<hex>` (e.g., `shell_i1e8`, `shell_i212`, `shell_i1e4`, `shell_i3cc`) suggests textures are referenced by Scaleform character/symbol IDs embedded in `.swf` or `.gfx` bytecode.

---

## 7. Audio System Layout

shell.wad separates audio into three layers:

| Block | Role | Sizes |
|-------|------|-------|
| `musicdata` | Track catalog/metadata | 49 KB + 23 KB |
| `music` | Playback config | soundbank (24 KB) + wavebank (5 KB) + config (2 KB) |
| `ui_hud` | In-menu sound effects | soundbank (19 KB) + config (1 KB) + wavebank (3.4 MB) |
| `ui_shell` | Shell interaction sounds | wavebank (7.9 MB) + config (364 B) + soundbank (6 KB) |

The wavebanks (`0xF753F6D0`) contain actual audio PCM/compressed data, while soundbanks (`0x9F8BCA10`) contain event tables that reference wavebank entries. The `musicdata` block uses unique singleton type hashes (`0xC122545A`, `0xE8DF4D87`) — these are likely the music sequencing/playlist format.

---

## 8. Tooling Notes

### Extraction

```bash
# Parse FFCS structure
.venv/bin/python tools/ffcs_wad.py "game-files/Mercenaries 2 World in Flames/data/Loading.wad" --json

# Extract chunks to directory
.venv/bin/python tools/mercs2_ffcs_extract.py "game-files/Mercenaries 2 World in Flames/data/shell.wad" --out output/extracted/ffcs_shell

# Decompress all blocks
.venv/bin/python tools/sges_decompress.py --wad "game-files/Mercenaries 2 World in Flames/data/shell.wad" --all --out output/extracted/batch_shell/blocks/

# Full analysis
.venv/bin/python tools/analyze_wad.py "game-files/Mercenaries 2 World in Flames/data/Loading.wad" "game-files/Mercenaries 2 World in Flames/data/shell.wad" --summary --json output/wad_analysis.json
```

### Stage 2 Processing

Both WADs can be processed through the standard stage 2 pipeline. The `scaleform_shell` block (416 textures) benefits from `texture_extractor.py` to export individual DDS/PNG files. Language blocks should use `dialog_extractor.py` for string extraction.

---

## 9. Unknown Type Hashes Seen

| type_hash | Context | Hypothesis |
|-----------|---------|------------|
| `0xFE0E8320` | Font metric blocks, Japanese font, `resident` sub-entries | Font glyph/kerning definition format |
| `0xE5273C14` | Small (88–364 B) entries co-occurring with audio banks | Audio event config / sound group definition |
| `0xC122545A` | Singleton in `musicdata` (name_hash == type_hash) | Music playlist/sequencing format |
| `0xE8DF4D87` | Singleton in `musicdata` | Music track definition table |

These match observations from vz.wad (see `docs/type_hash_registry.md`). The font-metric hypothesis is strengthened by shell.wad having dedicated `_shell_*_font` blocks that use this type.
