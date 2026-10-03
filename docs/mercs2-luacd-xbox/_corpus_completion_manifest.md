# Lua corpus completion manifest — gap close

**Status:** current · **Evidence:** proven · **Date:** 2026-10-02

Follow-up to `docs/_lua_corpus_coverage_audit.md`. Pulls the 293 PC + 294
Xbox Lua chunks the audit flagged as outside the three big host blocks and
decompiles them into sibling `src/` subtrees next to the existing
`src/{resident,shell,vz}` corpora. Existing files were left untouched.

## Per-category totals (PC + Xbox)

| Category | Dest subdir | PC extracted / decomp'd | Xbox extracted / decomp'd | Failures | Empty-stub (0 B) | Tiny (<50 B) |
|---|---|---:|---:|---:|---:|---:|
| Mission spiel (74 blocks × 3) | `vz_missions/` | 222 / 222 | 222 / 222 | 0 | 0 | 0 |
| Vehicle hijack (27 + `helicopter`/`tank`) | `vz_hijacks/` | 29 / 29 | 29 / 29 | 0 | 0 | 0 |
| Subtitles block | `vz_subtitles/` | 36 / 36 | 36 / 36 | 0 | 0 | 1 (PC `technov.lua` 34 B) |
| GUI layouts block | `vz_guilayouts/` | 4 / 4 | 4 / 4 | 0 | 0 | 0 |
| `Loading.wad` loader | `loading/` | 1 / 1 | 1 / 1 | 0 | 0 | 1 (PC `loading.lua` 22 B) |
| `English.wad` loader | `english/` | 1 / 1 | 1 / 1 | 0 | 0 | 0 |
| `French.wad` loader | `french/` | 1 / 1 | 1 / 1 | 0 | 0 | 0 |
| `German.wad` loader (PC + PS3) | `german/` | 1 / 1 | n/a | 0 | 0 | 0 |
| `Italian.wad` loader (PC + PS3) | `italian/` | 1 / 1 | n/a | 0 | 0 | 0 |
| `Spanish.wad` loader (PC + PS3) | `spanish/` | 1 / 1 | n/a | 0 | 0 | 0 |
| `Russian.wad` loader (PS3-only) | `russian/` | n/a | n/a | — | — | — |
| **Totals (PC vs Xbox NTSC-US)** |  | **297 / 297** | **294 / 294** | **0** | **0** | **2** |

All 587 chunks decompiled with `unluac.jar` returning exit 0; no partial
output, no stderr messages, no empty files. The two "tiny" (<50 B)
decompiles are real content, not stubs:

- `src/loading/loading.lua` (PC) = `function Init() end`
  - Xbox equivalent is the same shell with the `local` variables unoptimised; same behaviour.
- `src/vz_subtitles/technov.lua` (PC) = `Type = "Time"; SubtitleData = {}` placeholder, matched on Xbox.

**Empty-stub count = 0** across every category. (The "mod-safe reserved
slot" pattern from Phase C'/A' doesn't appear in this gap set — unlike
`resident`, these specialty blocks don't ship empty reserved names.)

## Parity

Every non-language category (mission spiel, vehicle hijacks, subtitles,
GUI layouts, loading) has identical chunk-name sets on PC and Xbox.

The language-WAD footprint is per-SKU:

- PC retail ships 5 language WADs (English, French, German, Italian,
  Spanish); PS3 BLUS30056 ships 6 (adds Russian); Xbox 360 NTSC-US ships 2
  (English, French only). Each language WAD carries exactly one Lua chunk —
  the same 4-proto / 562-insn template with only the lang-suffix string
  constant differing. Full details:
  [`docs/_ps3_full_wad_set_lua_diff.md`](../_ps3_full_wad_set_lua_diff.md).

## Random sample heads (5 lines each)

```
--- Xbox 360 / vz_missions / spiel_minorcontract_oil52_jennifer.lua ---
local L0_1, L1_1
L0_1 = "Player1"
sParticipant1 = L0_1
L0_1 = "Starter"
sParticipant2 = L0_1
```

```
--- PC Retail / vz_missions / spiel_job_gur03_jennifer.lua ---
sParticipant1 = "Player1"
sParticipant2 = "Starter"
tSequence = {
  {
    sSpeaker = "Starter",
```

```
--- Xbox 360 / vz_subtitles / subtitles_12_car_m.lua ---
local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1, L10_1
L0_1 = "Time"
Type = L0_1
L0_1 = {}
L1_1 = {}
```

Debug-info stripping on Xbox is visible in the standard `local Lx_y` /
indexed-assign flattening but the semantics are identical to PC.

## Method / provenance

- Extraction: scratchpad `extract_gap_chunks.py` reused the fixed per-segment
  LE decompressor (`extract_resident_shell_lua.py :: decompress_le_sges_v2`)
  that already matched `mercs2_formats::sges::decompress_sges`, and
  `cross_platform_vz_compare.py :: decompress_be_sges` for Xbox BE blocks.
  Chunk slicing used the audit TSV's per-chunk `\x1bLua` offsets, trimmed
  to the next header or block end. All 587 slices start with `\x1bLua`.
- Decompile: `tools/jdk21 … java.exe -jar tools/external/unluac/unluac.jar <in>`
  (Phase A/C' recipe), 8-way thread pool. Checkpointed TSV in
  `scratchpad/gap_decomp_logs/results.tsv` for OAuth-safe resume.
- Xbox chunk names: adopted from the PC-side block-matched position
  (chunk order is stable across platforms; the Xbox binaries carry
  `<unnamed>` in the TSV because debug info is stripped).

## Bytecode parallels

Written next to the existing `scripts_vz_comparison/` tree, one dir per
new category:

- `output/analysis/cross_platform/scripts_missions_comparison/{PC Retail, Xbox 360}/bytecode/`
- `output/analysis/cross_platform/scripts_hijacks_comparison/{PC Retail, Xbox 360}/bytecode/`
- `output/analysis/cross_platform/scripts_subtitles_comparison/{PC Retail, Xbox 360}/bytecode/`
- `output/analysis/cross_platform/scripts_guilayouts_comparison/{PC Retail, Xbox 360}/bytecode/`
- `output/analysis/cross_platform/scripts_loading_comparison/{PC Retail, Xbox 360}/bytecode/`
- `output/analysis/cross_platform/scripts_english_comparison/{PC Retail, PS3, Xbox 360}/bytecode/`
- `output/analysis/cross_platform/scripts_french_comparison/{PC Retail, PS3, Xbox 360}/bytecode/`
- `output/analysis/cross_platform/scripts_german_comparison/{PC Retail, PS3}/bytecode/`
- `output/analysis/cross_platform/scripts_italian_comparison/{PC Retail, PS3}/bytecode/`
- `output/analysis/cross_platform/scripts_spanish_comparison/{PC Retail, PS3}/bytecode/`
- `output/analysis/cross_platform/scripts_russian_comparison/PS3/bytecode/` (PS3-only)

Each pairs with a `<cat>_inventory.json` holding per-chunk
`block_index`, `in_block_offset`, size, and sha256.
