# Base-game Lua corpus coverage audit

**Status:** current · **Evidence:** proven · **Date:** 2026-10-02

Scope: every shipped base-game WAD on PC and Xbox 360, scanned block-by-block for the Lua 5.1
chunk header (`\x1bLua` + version 0x51), with per-block chunk count and (for debug-info-bearing
PC chunks) the source-name string. Tool: `cargo run -p mercs2_probe --bin lua_chunk_scan --
--wad <path> --out <tsv>` — a new one-off probe that handles PC (`sges`, LE) **and** console
(`segs`, BE) decompression inline (the format crate's `decompress_sges` is LE-only and silently
returns raw bytes for a console block, which looks like "zero Lua chunks" to the scanner).

Raw TSVs: scratchpad `pc-vz.tsv`, `xbox-vz.tsv`, `pc-shell.tsv`, `xbox-shell.tsv`,
`pc-loading.tsv`, `xbox-loading.tsv`, `pc-english.tsv`, `xbox-english.tsv`, `xbox-french.tsv`.

## 1. Per-WAD inventory (blocks that carry Lua chunks)

### PC base game (FFCS / little-endian)

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

### Xbox 360 base game (SCFF / big-endian)

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
| `french.wad` | 20 | `blocks\french\resident_P000_Q3.block` | **1** (`french`) | **N** (no French corpus) |

## 2. Summary

| Platform | Total chunks shipped | Already in corpora | **Newly discovered** |
|---|---:|---:|---:|
| PC base game | **675** | 382 | **293** |
| Xbox 360 base game | **672** | 378 | **294** |

The "all PC + Xbox Lua characterized" claim as it stood held only for the three big host blocks
(`resident_P000_Q3` in `vz`+`shell`, and `scripts_vz_P000_Q3` in `vz`). It missed **77%** of
the Lua chunks shipped per platform, concentrated in mission `con`/`job` blocks, vehicle
`hijack_*` blocks, and the specialty `subtitles_P000_Q3`/`guilayouts_P000_Q3` blocks.

## 3. Newly-discovered Lua chunks — breakdown

- **Mission dialogue "spiel" scripts** (222 per platform, in 74 mission blocks): one script per
  `(mission, playable character)` pair, named `spiel_(minorcontract|job)_<faction><nn>_<chris|jennifer|mattias>`
  (e.g. `spiel_job_pir04_mattias`). Three per `*_con_` or `*_job_` block.
- **Vehicle-hijack mini-game scripts** (27 per platform): one `hijack_<vehicle>` chunk per
  hijackable vehicle (`hijack_ah1z`, `hijack_m1a2`, `hijack_alouette3`, etc.) in its own
  `hijack_<vehicle>_P000_Q3.block`. Two generic peers: `helicopterhijack`, `tankhijack`.
- **`subtitles_P000_Q3.block`** (36 chunks, both platforms): subtitle-timing tables as Lua
  (`subtitles_01_aoa_c`, `subtitles_13_avi_m`, …; one `technov`), keyed `<cutscene>_<char>`.
- **`guilayouts_P000_Q3.block`** (4 chunks, both platforms): `mrxguihudlayout2`,
  `mrxguibinocularslayout`, `mrxguisatellitelayout`, `mrxguipdalayout` — HUD/scope layouts
  distinct from the shell GUI already extracted.
- **One-chunk loader scripts** (`loading`, `english`, `french`): tiny stringdb-loader hooks in
  the per-language WADs. The French one is Xbox-only (PC has no French WAD).

## 4. Platform parity

- Structurally identical: PC and Xbox each ship **107 Lua-bearing blocks in `vz.wad`**, with
  the same block names and chunk counts across every non-resident block (hijack, mission
  `con`/`job`, subtitles, guilayouts).
- The known 2-chunk gap repeats: PC `vz/resident` 240 vs Xbox 238; PC `shell/resident` 28 vs
  Xbox 26 — same pattern as the earlier `mrxguiltiprecache` finding (`mrxguiltiprecache` +
  `mrxguiltiprecachelayout` are present in the PC shell chunk-name list, absent on Xbox).
- Xbox `french.wad` adds a `french` loader chunk that has no PC counterpart (PC ships no
  French WAD).

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
