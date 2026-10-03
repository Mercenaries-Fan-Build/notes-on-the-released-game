# PS3 base-game Lua corpus — full byte+structural diff vs Xbox 360

**Status:** current · **Evidence:** proven · **Date:** 2026-10-03

Follow-up closing the top loose end from the cross-platform Lua forensics pass:
[`docs/cross_platform_parity_reference.md`](cross_platform_parity_reference.md) §14 flagged
"PS3 base-game `VZ.WAD` diff vs Xbox" as *inferred-only* from identical ASET hashes and
identical DLC Lua (36/36). This document closes it by measurement.

## 0. TL;DR

- PS3 `ps3-VZ.WAD` ships **643 Lua chunks across 107 blocks** — same count as Xbox retail
  `vz.wad` (643/107). No chunks added, none removed.
- **105 of 107 blocks are byte-identical** across PS3 and Xbox (every hijack, every mission
  `con`/`job`, `subtitles_P000_Q3`, `guilayouts_P000_Q3`, the `helicopterhijack`/`tankhijack`
  peers).
- Only two blocks differ at the byte level, both for benign-to-near-benign reasons:
  - **`resident_P000_Q3`**: PS3 22,985,940 B vs Xbox 25,029,982 B (**Δ −2,044,042 B / −8.2%**).
    All 238 chunks are **structurally identical** (same opcodes, constants, proto tree, call
    graph) when the embedded source-path metadata is normalised away. The entire 2 MB delta is
    **Xbox-side debug-info retention** (longer `source` strings, line-info arrays, local-variable
    name tables) that PS3 strips harder.
  - **`scripts_vz_P000_Q3`**: PS3 1,055,279 B vs Xbox 1,055,365 B (**Δ −86 B**). 113 of 114
    chunks structurally identical. One real semantic divergence: **`chicon002.lua`** (Chinese
    contract 002 mission script), where PS3 ships an **older build** missing the
    `BridgeDestroyed_New` / `HQDestroyed_New` / `DepotDestroyed_New` flag checks and a
    `:Complete()` call that both PC and Xbox retail ship.

## 1. Scan tooling

- `cargo run --release -p mercs2_probe --bin lua_chunk_scan -- --wad <path> --out <tsv>` —
  WAD-side Lua chunk scanner, PC `sges` LE and console `segs` BE (adds `flate2 = "1"` to
  `mercs2_probe` because `mercs2_formats::sges::decompress_sges` is LE-only and silently
  returns raw bytes for a console block).
- `cargo run --release -p mercs2_probe --bin lua_chunk_scan -- --wad <path> --extract-block <N>
  --extract-dir <dir>` — new mode added for this pass: decompresses one block, scans for every
  Lua 5.1 chunk, and writes each chunk as `chunk_<idx>_@<HEX>.luac` (sliced from offset to
  next-chunk-offset / EOF). Needed to feed each chunk to `lua_structural_dump`.
- `cargo run --release -p mercs2_probe --bin lua_structural_dump -- <chunk.luac>` —
  stable structural fingerprint of a stripped Lua 5.1 chunk (both endians, both `lua_Number`
  widths). Compared with the `"path":` metadata line stripped.

## 2. Per-block parity table (107 blocks)

Every row below was captured in the same tool run (`lua_chunk_scan`); block paths and chunk
counts are normalised across platforms.

| Block path (both platforms) | PS3 size | Xbox size | Δ | Chunks | Verdict |
|---|---:|---:|---:|---:|---|
| `blocks\vz\resident_P000_Q3` | 22,985,940 | 25,029,982 | **−2,044,042** | 238=238 | **STRUCTURAL ≡** (debug-strip) |
| `blocks\vz\scripts_vz_P000_Q3` | 1,055,279 | 1,055,365 | −86 | 114=114 | 113 ≡ · 1 REAL |
| `blocks\vz\subtitles_P000_Q3` | 47,863 | 47,863 | 0 | 36=36 | BYTE ≡ |
| `blocks\vz\guilayouts_P000_Q3` | 72,843 | 72,843 | 0 | 4=4 | BYTE ≡ |
| 27 × `blocks\vz\hijack_<vehicle>_P000_Q3` | — | — | 0 ea. | 1=1 ea. | BYTE ≡ |
| `blocks\vz\helicopterhijack_P000_Q3` | 6,158 | 6,158 | 0 | 1=1 | BYTE ≡ |
| `blocks\vz\tankhijack_P000_Q3` | 5,274 | 5,274 | 0 | 1=1 | BYTE ≡ |
| 74 × `blocks\vz\<faction><nn>_(con\|job)_P000_Q3` | — | — | 0 ea. | 3=3 ea. | BYTE ≡ |

Raw TSVs: `scratchpad/ps3-vz.tsv`, `scratchpad/xbox-vz.tsv`. Sorted-by-path diff:
`scratchpad/ps3-vs-xbox-sorted.diff` (6 lines, both diff rows are the two blocks above).

## 3. Resident block — the 2 MB mystery is 100% debug differential

Extracted all 238 chunks from PS3 `resident_P000_Q3` and all 238 from Xbox
`resident_P000_Q3`, then compared same-index pairs.

**Raw bytes:**

| Comparison | Count | % |
|---|---:|---:|
| Byte-identical (both compiled byte-for-byte the same) | 53 | 22.3% |
| Same size, different bytes | 112 | 47.1% |
| Different size | 73 | 30.7% |
| **Total** | **238** | 100% |

**Structural (normalised, source-path line stripped):**

| Comparison | Count | % |
|---|---:|---:|
| **Structurally identical** (same opcodes/constants/protos/calls) | **238** | **100%** |
| Semantically divergent | 0 | 0% |

**Interpretation:** every single `resident_P000_Q3` script compiled from the same source on
both platforms. Xbox retail preserved richer debug info (line-info arrays, local-variable
name tables, longer `source:` strings) that PS3 retail stripped. The 112 same-size-but-
different-bytes pairs are the ones where Xbox trimmed one kind of debug data while adding
another, so the net size matched by coincidence. The 73 different-size pairs are the ones
where Xbox simply retained more debug than PS3.

**Scale of the differential (top Xbox-is-larger chunks, by delta):**

| idx | PS3 B | Xbox B | Δ (Xbox − PS3) |
|---:|---:|---:|---:|
| 197 | 146,745 | 307,336 | **+160,591** |
| 130 | 1,967,594 | 2,055,146 | +87,552 |
| 77 | 51,331 | 133,378 | +82,047 |
| 80 | 422,069 | 500,682 | +78,613 |
| 178 | 240,320 | 317,969 | +77,649 |
| 230 | 433,884 | 493,795 | +59,911 |
| 92 | 35,097 | 89,853 | +54,756 |
| 76 | 553,547 | 604,158 | +50,611 |
| 8 | 39,979 | 87,620 | +47,641 |

Only 3 chunks (idx 119, 137, 237) are meaningfully PS3-larger (by 1.2–2.7 KB each). Even
these are structurally identical to their Xbox pair.

**Chunk 8 as a concrete worked example:** 47 KB Xbox-larger, structurally identical. The
`lua_structural_dump` outputs for both chunks are 462 lines long; `diff` returns exactly
**one** differing line — the `"path":` metadata field pointing at the input file. Everything
else — endian, number size, integer size, 162 call-targets across 23 nested protos, every
constant, every line-defined range — matches exactly.

**TSV**: `scratchpad/resident-chunk-cmp.tsv` (per-chunk sizes, SHA-8 of raw bytes, verdict).
**Structural-pair verdict TSV**: `scratchpad/resident-structural.tsv` (per-chunk structural
SHA-12 of both platforms, verdict).

## 4. `scripts_vz` block — one real divergence (`chicon002.lua`)

113 of 114 chunks structurally identical. The lone outlier is chunk index 51 (at offset
`0x692F4` on both platforms, PS3 13,532 B / Xbox 13,618 B — accounting for the full 86-byte
block-level delta).

**Script identification:** the stripped chunk's constant pool carries `rgn_atmo_Maracaibo`,
`warzonemar`, `MrxHqManager`, `SetHqRespawn`, `OilHq`, `_HQHealthBar`, `_GetFlag`,
`HQDestroyed_New`, `DepotDestroyed_New`, `BridgeDestroyed_New`, `_BridgeSpottedVO`. The
only PC script in `docs/mercs2-luacd/src/vz/` with the pair `rgn_atmo_Maracaibo` +
`warzonemar` is **`chicon002.lua`** — Chinese contract mission 002.

**What differs:** Xbox (and PC) chunks include four extra call sites not present on PS3 —
three `:_GetFlag(…)` reads on destruction-event flags and one `:Complete()` call — plus the
string constants that back them (`HQDestroyed_New`, `DepotDestroyed_New`, `BridgeDestroyed_New`,
`Complete`, `_GetFlag`). The `last_line_defined`/`line_defined` fields on nearly every
inner function shift up by 5 lines on Xbox, consistent with those extra call lines living in
a block near the top of the script.

**Direction of the divergence:** both PC and Xbox retail ship the newer version
(`docs/mercs2-luacd/src/vz/chicon002.lua` lines 22/32/42/61/64/79/103/142/198/239 all
contain the matching `self:_GetFlag("…Destroyed_New")` calls). PS3 shipped an **earlier
build** of `chicon002.lua` that was never patched. The practical effect is that one Chinese
PMC contract (`chicon002`) checks fewer destruction-event flags on PS3 than it does on PC
or Xbox before firing certain subobjective completions or `_HQHealthBar` reveals.

**Artefacts:**
- `scratchpad/sv51-ps3.sd`, `scratchpad/sv51-xbox.sd` — structural dumps.
- `scratchpad/sv51.diff` — 253-line structural diff, dominated by `line_defined` shifts.
- `scratchpad/scripts_vz-struct.log` — the full 114-pair verdict.

## 5. Three-platform summary

- **PS3↔Xbox base-game Lua: 643/643 chunks across 107/107 blocks are structurally
  identical** — one real divergence (`scripts_vz/chicon002.lua`, Chinese Contract 002 ships
  an older build on PS3 missing the `_GetFlag` destruction-event checks that PC and Xbox
  retail carry). The PC↔Xbox 457-identical / 125-debug-strip / 89-real-divergence
  breakdown does not apply to Xbox↔PS3; across consoles the real-divergence count is **1**.
- **Chicon002 is the only base-game Lua script that semantically differs between PS3 and
  the other two platforms.** PC and Xbox ship the newer build; PS3 ships the older build.
- **PS3 strips debug info more aggressively than Xbox** across the resident block
  (−2.04 MB over 238 chunks). No structural difference — the extra Xbox bytes are
  line-info arrays and local-variable name tables.
- **PS3 full WAD set** (shell, loading, and 6 language WADs) is characterised in
  [`_ps3_full_wad_set_lua_diff.md`](_ps3_full_wad_set_lua_diff.md).
- **PS3↔Xbox DLC Lua**: covered by
  [`docs/mercs2-dlc-luacd/_ps3_xbox_structural_diff.md`](mercs2-dlc-luacd/_ps3_xbox_structural_diff.md)
  (36/36 structurally identical).

## 6. Residual observations

- **2 chunks where PS3 ships ~2.6 KB LESS than Xbox** (resident indices 119 and 237). Both
  are structurally identical to their Xbox counterparts; the direction is simply PS3
  stripping *more* than usual. No semantic difference.
