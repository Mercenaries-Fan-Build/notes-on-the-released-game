# PS3 full WAD set — Lua corpus diff vs Xbox NTSC-US

**Status:** current · **Evidence:** proven · **Date:** 2026-10-03

Follow-up to [`_ps3_base_game_lua_diff.md`](_ps3_base_game_lua_diff.md), closing the
previously-blocked loose end "PS3 shell/loading/english/french WADs — BLOCKED on PS3 PKG
extraction". The source material is now the retail PS3 disc image
(`game-files/Mercenaries 2 World in Flames [BLUS30056].iso`, 9.33 GB, decrypted ISO-9660
format), which carries the complete PS3 game filesystem.

## 0. TL;DR

PS3 base-game Lua corpus is now **fully characterised**: **676 chunks** across 9 WADs. Xbox
NTSC-US ships 672 chunks across 5 WADs. PC retail (installed set under
`C:\Users\Shadow\Documents\Mercenaries 2 World in Flames\data`) ships 679 chunks across 8
WADs.

| WAD | PC retail | PS3 | Xbox NTSC-US | Verdict (across platforms) |
|---|---:|---:|---:|---|
| `vz.wad` | 645 | 643 | 643 | PS3≡Xbox (except `chicon002.lua`); PC has +2 LTI chunks in resident |
| `shell.wad` | 28 | 26 | 26 | PS3≡Xbox (26/26 structural); PC has +2 LTI chunks |
| `loading.wad` | 1 | 1 | 1 | all three byte-identical modulo endian (same chunk) |
| `english.wad` | 1 | 1 | 1 | PS3↔Xbox byte-identical; PC debug-rich variant structurally ≡ |
| `french.wad` | 1 | 1 | 1 | PS3↔Xbox byte-identical; PC debug-rich variant structurally ≡ |
| `german.wad` | 1 | 1 | — | PC and PS3 ship it; Xbox NTSC-US does not |
| `italian.wad` | 1 | 1 | — | PC and PS3 ship it; Xbox NTSC-US does not |
| `spanish.wad` | 1 | 1 | — | PC and PS3 ship it; Xbox NTSC-US does not |
| `russian.wad` | — | 1 | — | **PS3-only** |

**Totals:** PC = **679**, PS3 = **676**, Xbox NTSC-US = **672**.

## 1. ISO extraction tooling

The disc image is a **decrypted ISO-9660** (primary volume descriptor at sector 16 reads
`\x01CD001\x01`, volume label `PS3VOLUME`). No disc key / 3K3Y layer. The game filesystem is
accessible via standard ISO-9660 traversal — no special PS3 tooling needed.

Rolled a minimal 70-line Python ISO-9660 extractor (`scratchpad/iso_extract.py`) rather than
install an external dep. It walks the directory records, pulls named files by basename, and
writes them to disk. Extracted all 8 target WADs in a single pass:

```
python scratchpad/iso_extract.py scratchpad/ps3-wads \
    SHELL.WAD LOADING.WAD ENGLISH.WAD FRENCH.WAD \
    GERMAN.WAD ITALIAN.WAD RUSSIAN.WAD SPANISH.WAD
```

Full ISO tree is at `scratchpad/iso-tree.txt` (also lists `VZ.WAD` / `VZ~01.WAD` /
`VZ~02.WAD` — the 2.2 GB vz corpus is split across three ISO entries which concatenate to the
`ps3-VZ.WAD` already covered in the earlier doc).

## 2. Shell WAD — 26 chunks, 26/26 structural match

- PS3 `SHELL.WAD` block 15 = Xbox `shell.wad` block 15. Both decompress to 26 Lua chunks.
- **26 of 26 structurally identical** (same opcode stream, constants, call graph) when
  source-path metadata is normalised away.
- **10 of 26 byte-identical** at the compiled bytecode level; the other 16 differ only in
  retained debug info — same pattern as the resident block (PS3 strips harder than Xbox).

This confirms the earlier finding that both console builds **lack the 2 PC-only LTI chunks**
(`mrxguiltiprecache.luac` + `mrxguiltiprecachelayout.luac`) that PC's `shell.wad` ships.
Shell parity between consoles is complete; the LTI subsystem is a PC-exclusive layer.

## 3. Loading / English / French — byte-identical

All three single-chunk WADs ship **byte-identical** payloads across PS3 and Xbox:

| Chunk | PS3 size | Xbox size | sha256(bytes) |
|---|---:|---:|---|
| `loading.luac` | 66,362 | 66,362 | match (verified via `cmp`) |
| `english.luac` | 4,059 | 4,059 | match |
| `french.luac` | 4,030 | 4,030 | match |

The `english.luac` and `french.luac` chunks each ship the same `vo_asset_table` of 179
`{name, type}` entries covering every VO soundbank/sounddb/wavebank, ending with a single
`AddLocalizedAsset(".<lang>")` call. The engine-side `AddLocalizedAsset` binding does the
real work; the Lua side is pure data.

## 4. Language WADs across all three platforms — one template, 13 chunks

Measured from both PS3 BLUS30056 and the PC retail install at
`C:\Users\Shadow\Documents\Mercenaries 2 World in Flames\data` (not the stale
`game-files/` subset).

| WAD | PC retail chunks | PS3 chunks | Xbox NTSC-US chunks |
|---|---:|---:|---:|
| `english.wad` | 1 (6,450 B debug-rich) | 1 (4,059 B stripped) | 1 (4,059 B stripped) |
| `french.wad` | 1 (6,420 B debug-rich) | 1 (4,030 B stripped) | 1 (4,030 B stripped) |
| `german.wad` | 1 (6,448 B debug-rich) | 1 (4,058 B stripped) | — not shipped |
| `italian.wad` | 1 (6,422 B debug-rich) | 1 (4,031 B stripped) | — not shipped |
| `spanish.wad` | 1 (6,450 B debug-rich) | 1 (4,059 B stripped) | — not shipped |
| `russian.wad` | — not shipped | 1 (4,031 B stripped) | — not shipped |

**All 13 shipped chunks are structurally identical** modulo:
- Endian (PC LE sges, PS3/Xbox BE segs).
- Debug info retention (PC retains line + local-variable names; PS3/Xbox strip).
- The single `.<lang>` suffix constant.

Measured per-chunk: 4 protos, 562 instructions, 82 distinct string constants (excluding the
lang-suffix). The normalised string-pool SHA-12 is **`b6eef55f5c79`** for every one of the
13 chunks across all three platforms. One template, three endians, six language suffixes.

**Set differences:**
- **PS3 ships Russian; neither PC nor Xbox NTSC-US does.** `Russian.wad` with 1 chunk, 70 MB
  on PS3; no PC or Xbox counterpart.
- **PC and PS3 both ship German/Italian/Spanish; Xbox NTSC-US does not.** Expected: PAL Xbox
  variants likely ship these too (we only have NTSC-US JTAGRip to test — see §6).
- Nothing is Xbox-NTSC-US-only at the language-WAD layer.

**Fix-pack / mod implication:** adding Russian to PC is trivial at the Lua layer — clone any
PC lang chunk, swap the suffix constant to `.russian`, recompile. The real work is the VO
wave assets (the WAD body ships hundreds of MB of localised audio); the Lua script is a
15-line template.

## 5. Totals and set differences

Base-game Lua chunk totals across the three measured SKUs:

| Platform | Base-game Lua chunks (all WADs) |
|---|---:|
| PC retail (complete install) | **679** |
| PS3 BLUS30056 retail | **676** |
| Xbox 360 NTSC-US retail | **672** |

The chunk sets, properly measured, do not overlap exactly:

- **PC-only vs PS3+Xbox NTSC-US**: 4 LTI chunks (`mrxguiltiprecache` +
  `mrxguiltiprecachelayout`, each shipped in both resident and shell — the 2 scripts show
  up 2× each in the PC corpus).
- **PS3-only vs PC+Xbox NTSC-US**: 1 language stub (`russian.luac`).
- **PC+PS3 but NOT Xbox NTSC-US**: 3 language stubs (german/italian/spanish — likely present
  on PAL Xbox variants; see §6).
- **Xbox NTSC-US-only vs PC+PS3**: none.

## 6. Still open after this pass

- **Xbox PAL / EU variants** — if those ship the same 4 language WADs as PS3, the "PS3-only"
  claim collapses to "Xbox NTSC-US-only". We only have the NTSC-US JTAGRip; a PAL retail copy
  would answer it.
- **Shaders.bin** (3 MB, PS3-only) — not a Lua file, out of scope here, but worth a separate
  pass since the PC equivalent is baked into the Pangea DX9 runtime at compile time.
- The **three VZ split segments** (`VZ.WAD` 1 GB + `VZ~01.WAD` 54 MB + `VZ~02.WAD` 1 GB) in
  the ISO concatenate to the `game-files/ps3-VZ.WAD` already covered.

## 7. Artefacts produced this pass

- `scratchpad/iso_extract.py` — 70-line ISO-9660 extractor.
- `scratchpad/ps3-wads/{SHELL,LOADING,ENGLISH,FRENCH,GERMAN,ITALIAN,RUSSIAN,SPANISH}.WAD` —
  8 extracted PS3 WADs (427 MB total).
- `scratchpad/ps3-{SHELL,LOADING,ENGLISH,FRENCH,GERMAN,ITALIAN,RUSSIAN,SPANISH}.tsv` —
  per-WAD chunk census.
- `scratchpad/ps3-{shell,loading}/`, `scratchpad/ps3-lang/{ENGLISH,FRENCH,GERMAN,ITALIAN,RUSSIAN,SPANISH}/`,
  `scratchpad/xb-{shell,loading,english,french}/` — extracted chunks.
- `scratchpad/ps3-lang-struct.log` — 6-language structural equivalence verdict.
- `scratchpad/ps3-xb-shell-cmp.log` — SHELL byte+structural compare verdict.
- `scratchpad/single-chunk-cmp.log` — LOADING/ENGLISH/FRENCH byte-identity verdict.
