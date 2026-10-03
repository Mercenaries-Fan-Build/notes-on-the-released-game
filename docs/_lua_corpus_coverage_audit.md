# Base-game Lua corpus coverage audit

**Status:** current · **Evidence:** proven

Scope: every shipped base-game WAD on PC, PS3, and Xbox 360, scanned block-by-block for the Lua 5.1
chunk header (`\x1bLua` + version 0x51), with per-block chunk count and (for debug-info-bearing
PC chunks) the source-name string. Tool: `cargo run -p mercs2_probe --bin lua_chunk_scan --
--wad <path> --out <tsv>` — a new one-off probe that handles PC (`sges`, LE) **and** console
(`segs`, BE) decompression inline (the format crate's `decompress_sges` is LE-only and silently
returns raw bytes for a console block, which looks like "zero Lua chunks" to the scanner).

Raw TSVs: scratchpad `pc-vz.tsv`, `xbox-vz.tsv`, `ps3-vz.tsv`, `pc-shell.tsv`,
`xbox-shell.tsv`, `ps3-SHELL.tsv`, per-language TSVs under `scratchpad/ps3-<LANG>.tsv` and
`scratchpad/pc-full-<Lang>.tsv`.

## 1. Per-WAD inventory (blocks that carry Lua chunks)

### PC base game (FFCS / little-endian)

Measured from the complete retail install at
`C:\Users\Shadow\Documents\Mercenaries 2 World in Flames\data`.

| WAD | Block idx | Path | Chunks | In corpora? |
|---|---|---|---|---|
| `vz.wad` | 3185 | `blocks\VZ\resident_P000_Q3.block` | 240 | **Y** (`src/resident/`) |
| `vz.wad` | 3197 | `blocks\VZ\scripts_vz_P000_Q3.block` | 114 | **Y** (`src/vz/`) |
| `vz.wad` | 3442 | `blocks\VZ\subtitles_P000_Q3.block` | **36** | **N** |
| `vz.wad` | 3495 | `blocks\VZ\guilayouts_P000_Q3.block` | **4** | **N** |
| `vz.wad` | 27 blocks | `blocks\VZ\hijack_<vehicle>_P000_Q3.block` | **27** (1 each) | **N** |
| `vz.wad` | 3144 / 3424 | `helicopterhijack` / `tankhijack` `_P000_Q3.block` | **2** (1 each) | **N** |
| `vz.wad` | 74 blocks | `blocks\VZ\<faction><nn>_(con|job)_P000_Q3.block` | **222** (3 each) | **N** |
| `shell.wad` | 17 | `blocks\Shell\resident_P000_Q3.block` | 28 | **Y** (`src/shell/`) |
| `Loading.wad` | 4 | `blocks\Loading\resident_P000_Q3.block` | **1** (`loading`) | **N** |
| `English.wad` | 19 | `blocks\English\resident_P000_Q3.block` | **1** (`english`) | **N** |
| `French.wad` | 20 | `blocks\French\resident_P000_Q3.block` | **1** (`french`) | **N** |
| `German.wad` | 21 | `blocks\German\resident_P000_Q3.block` | **1** (`german`) | **N** |
| `Italian.wad` | 24 | `blocks\Italian\resident_P000_Q3.block` | **1** (`italian`) | **N** |
| `Spanish.wad` | 16 | `blocks\Spanish\resident_P000_Q3.block` | **1** (`spanish`) | **N** |

### Xbox 360 base game — NTSC-US JTAGRip (SCFF / big-endian)

| WAD | Block idx | Path | Chunks | In corpora? |
|---|---|---|---|---|
| `xbox-vz.wad` | 3180 | `blocks\vz\resident_P000_Q3.block` | 238 | **Y** (`src/resident/`) |
| `xbox-vz.wad` | 3192 | `blocks\vz\scripts_vz_P000_Q3.block` | 114 | **Y** (`src/vz/`) |
| `xbox-vz.wad` | 3431 | `blocks\vz\subtitles_P000_Q3.block` | **36** | **N** |
| `xbox-vz.wad` | 3479 | `blocks\vz\guilayouts_P000_Q3.block` | **4** | **N** |
| `xbox-vz.wad` | 27 blocks | `blocks\vz\hijack_<vehicle>_P000_Q3.block` | **27** (1 each) | **N** |
| `xbox-vz.wad` | 3141 / 3414 | `helicopterhijack` / `tankhijack` `_P000_Q3.block` | **2** (1 each) | **N** |
| `xbox-vz.wad` | 74 blocks | mission `_con_` / `_job_` | **222** | **N** |
| `shell.wad` | 15 | `blocks\shell\resident_P000_Q3.block` | **26** | **Y** (`src/shell/`) |
| `loading.wad` | 4 | `blocks\loading\resident_P000_Q3.block` | **1** | **N** |
| `english.wad` | 19 | `blocks\english\resident_P000_Q3.block` | **1** | **N** |
| `french.wad` | 20 | `blocks\french\resident_P000_Q3.block` | **1** (`french`) | **N** |

### PS3 base game — BLUS30056 retail (SCFF `segs` / big-endian)

Extracted from `game-files/Mercenaries 2 World in Flames [BLUS30056].iso`.

| WAD | Block idx | Path | Chunks | In corpora? |
|---|---|---|---|---|
| `VZ.WAD` | 3527 | `blocks\vz\resident_P000_Q3.block` | 238 | — |
| `VZ.WAD` | 3587 | `blocks\vz\scripts_vz_P000_Q3.block` | 114 | — |
| `VZ.WAD` | 4730 | `blocks\vz\subtitles_P000_Q3.block` | **36** | — |
| `VZ.WAD` | 5014 | `blocks\vz\guilayouts_P000_Q3.block` | **4** | — |
| `VZ.WAD` | 29 hijack blocks | | **29** (1 each) | — |
| `VZ.WAD` | 74 blocks | mission `_con_` / `_job_` | **222** | — |
| `SHELL.WAD` | 15 | `blocks\shell\resident_P000_Q3.block` | **26** | — |
| `LOADING.WAD` | 4 | `blocks\loading\resident_P000_Q3.block` | **1** | — |
| `ENGLISH.WAD` | 19 | `blocks\english\resident_P000_Q3.block` | **1** | — |
| `FRENCH.WAD` | 20 | `blocks\french\resident_P000_Q3.block` | **1** | — |
| `GERMAN.WAD` | 21 | `blocks\german\resident_P000_Q3.block` | **1** | — |
| `ITALIAN.WAD` | 24 | `blocks\italian\resident_P000_Q3.block` | **1** | — |
| `RUSSIAN.WAD` | 21 | `blocks\russian\resident_P000_Q3.block` | **1** | — |
| `SPANISH.WAD` | 16 | `blocks\spanish\resident_P000_Q3.block` | **1** | — |

## 2. Summary

| Platform | Total chunks shipped | In Phase-1 corpora | **Phase-2 extensions** |
|---|---:|---:|---:|
| PC retail (complete install) | **679** | 382 | **297** |
| PS3 BLUS30056 retail | **676** | — | 676 (full new) |
| Xbox 360 NTSC-US retail | **672** | 378 | **294** |

Phase-1 corpora cover only the three big host blocks (`resident_P000_Q3` in `vz`+`shell` and
`scripts_vz_P000_Q3` in `vz`) — 56% of the total per platform. The remaining 44% lives in
mission `con`/`job` blocks, vehicle `hijack_*` blocks, the specialty
`subtitles_P000_Q3`/`guilayouts_P000_Q3` blocks, and the per-language WADs.

## 3. Newly-discovered Lua chunks — breakdown

- **Mission dialogue "spiel" scripts** (222 per platform, in 74 mission blocks): one script per
  `(mission, playable character)` pair, named `spiel_(minorcontract|job)_<faction><nn>_<chris|jennifer|mattias>`
  (e.g. `spiel_job_pir04_mattias`). Three per `*_con_` or `*_job_` block.
- **Vehicle-hijack mini-game scripts** (27 per platform): one `hijack_<vehicle>` chunk per
  hijackable vehicle (`hijack_ah1z`, `hijack_m1a2`, `hijack_alouette3`, etc.) in its own
  `hijack_<vehicle>_P000_Q3.block`. Two generic peers: `helicopterhijack`, `tankhijack`.
- **`subtitles_P000_Q3.block`** (36 chunks, all platforms): subtitle-timing tables as Lua
  (`subtitles_01_aoa_c`, `subtitles_13_avi_m`, …; one `technov`), keyed `<cutscene>_<char>`.
- **`guilayouts_P000_Q3.block`** (4 chunks, all platforms): `mrxguihudlayout2`,
  `mrxguibinocularslayout`, `mrxguisatellitelayout`, `mrxguipdalayout` — HUD/scope layouts
  distinct from the shell GUI already extracted.
- **Per-language loader stubs** — one 4-proto / 562-insn Lua chunk per `<Lang>.wad`,
  shipping a 179-entry `vo_asset_table` and a single `AddLocalizedAsset(".<lang>")` call. PC
  ships 5 (en/fr/de/it/es), PS3 ships 6 (en/fr/de/it/ru/es), Xbox NTSC-US ships 2 (en/fr).
  All 13 shipped language chunks share the same normalised string-pool SHA-12
  (`b6eef55f5c79`) — one template across three endians and six languages.

## 4. Platform parity

- Structurally identical: PC, PS3, and Xbox each ship **107 Lua-bearing blocks in `vz.wad`**,
  with the same block names and chunk counts across every non-resident block (hijack, mission
  `con`/`job`, subtitles, guilayouts).
- Resident counts: PC `vz/resident` 240 vs PS3/Xbox 238; PC `shell/resident` 28 vs PS3/Xbox 26.
  Both deltas are the same two scripts — `mrxguiltiprecache` + `mrxguiltiprecachelayout` —
  shipped on PC in both resident and shell blocks, absent on both consoles.
- Language-WAD parity is per-SKU: PS3 ships `russian.wad`, PC and Xbox NTSC-US don't; PC and
  PS3 ship `german.wad`/`italian.wad`/`spanish.wad`, Xbox NTSC-US doesn't. Full breakdown:
  [`_ps3_full_wad_set_lua_diff.md`](_ps3_full_wad_set_lua_diff.md).

## 5. Mod-maker implication

Every newly-discovered chunk is a live reserved-name slot the engine already looks up by name
on PC and Xbox and could be overridden through a `vz-patch.wad` overlay (last-WAD-wins; the
chunk-registry first-wins rule means a patch chunk must be made resident before the base
registry row is sealed, same as any other patch-WAD Lua). Highest-leverage targets a modder
could reach without touching native code:
- `hijack_<vehicle>` — rewrite a vehicle's hijack minigame, or add one for a new vehicle.
- `spiel_(minorcontract|job)_<faction><nn>_<char>` — replace per-character mission barks.
- `mrxguihudlayout2`, `mrxguipdalayout`, `mrxguisatellitelayout`, `mrxguibinocularslayout` —
  HUD/scope UI layouts separate from the already-moddable shell layouts.
- `subtitles_<cutscene>_<char>` — subtitle timing tables per cutscene.

Follow-up for the corpus owners: pull these 293/294 chunks with `wad_builder extract-lua` (or
a batch wrapper), decompile with `unluac`, and add new sibling trees next to `src/vz/`
(suggested: `src/vz_missions/`, `src/vz_hijacks/`, `src/vz_subtitles/`, `src/vz_guilayouts/`,
plus `src/loading/`, `src/english/`, and Xbox-side `src/french/`).
