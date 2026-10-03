# sges multi-segment decompressor bug — audit

**Date:** 2026-10-02 - **Scope:** Python `sges` decompressors used by analysis
tooling vs. the fixed reference in `tools/wad_simulator/crates/mercs2_formats/src/sges.rs`.

## 1. The bug in one paragraph

A `.block` payload in a Mercenaries 2 WAD is an `sges` container: a 16-byte
header + an N-entry segment table (`u16 comp_sz`, `u16 uncomp_sz`,
`u32 abs_off | compressed_flag`), then N raw-deflate (or stored-raw) segments laid
out at 16-byte-aligned absolute offsets. The segment table is authoritative. The
buggy LE helper (`tools/cross_platform_vz_compare.py :: decompress_le_sges`)
ignores the segment table and instead *scans forward* from the payload start,
skipping any run of `0x00` bytes and handing the next slice to a single
`zlib.decompressobj(-15)` call, using `unused_data` to advance. Two failure
modes: (a) a **stored** segment (deflate type 00) begins with a `0x00` byte that
the zero-skip loop walks past, then zlib errors on the LEN/NLEN pair and the
loop breaks early; (b) any gap of alignment padding between a compressed
segment's real end and the next segment's absolute offset trips the same path.
Result: silent truncation, with the decompressor returning fewer bytes than
`total_u` and no raised error. Concrete witness on PC `shell.wad` block 17
(`blocks\Shell\resident_P000_Q3.block`, seg_count=49, 49 segments): buggy
returns 1,376,256 B, fixed returns 3,206,931 B (ground truth per header + Rust
`mercs2_formats::sges::decompress_sges`).

## 2. Buggy-decompressor dependency map

Grep: `decompress_sges|decompress_be_sges|cross_platform_vz_compare` across
`tools/` + `output/analysis/` + `docs/`.

| Call site | Source of decompressor | Status |
|---|---|---|
| `tools/cross_platform_vz_compare.py` | local `decompress_le_sges` (buggy zero-scan) | **BUGGY** |
| `tools/cross_platform_vz_compare.py` | local `decompress_be_sges` (reads segment table, 16-byte stride) | safe (verified vs x360_dlc_io on 30/30 Xbox shell `segs` blocks) |
| `tools/x360_dlc_io.py` | local `decompress_be_sges` (reads segment table, 16-byte stride) | safe (as above) |
| `tools/_cross_platform_block_inventory.py` | imports only `parse_ffcs_header, ChunkRow` — no decompression | safe |
| `tools/sges_decompress.py :: decompress_sges_block` | reads segment table, honours per-entry absolute offsets + compressed flag | **FIXED** (matches Rust) |
| ~60 other `tools/*.py` (list in audit scratchpad) | all import `decompress_sges_block` from `tools/sges_decompress.py` | safe |

Only one Python entry point in the tree still carries the buggy code:
`cross_platform_vz_compare.decompress_le_sges`. Nothing else imports it.

## 3. Risk assessment of on-disk analyses

| Analysis artefact | Produced by | Risk | Notes |
|---|---|---|---|
| `output/analysis/cross_platform/cross_platform_vz_comparison.md` | `cross_platform_vz_compare.py` | HIGH (a priori) → re-ran, no delta | PC Retail `scripts_vz` block has 25 segments, **all compressed, none stored** → buggy and fixed outputs are byte-identical |
| `output/analysis/cross_platform/cross_platform_combined.json` | same | same | same |
| `output/analysis/cross_platform/scripts_vz_comparison/*/scripts_vz_inventory.json` | same | same | same |
| `output/analysis/cross_platform/scripts_vz_platform_diff.md` | restates numbers from above | same | same |
| `output/analysis/cross_platform/scripts_shell_comparison/*/shell_inventory.json` | ad-hoc script, not in repo | LOW | Already contains correct sizes (PC 3,206,931 B / 28 scripts; Xbox 3,388,683 B / 26 scripts) — matches fresh decompress with the fixed helper |
| `output/analysis/cross_platform/scripts_resident_comparison/*/resident_inventory.json` | ad-hoc script, not in repo | LOW | Same shape; current numbers verified correct |
| `output/analysis/cross_platform/phase0_baseline_report.md` | `verify_dlc_import_chain.py` → fixed helper | LOW | n/a |
| `output/analysis/cross_platform/pc_bisect_results.md` | narrative, no sizes from `decompress_le_sges` | LOW | n/a |
| `docs/mercs2-luacd-xbox/_manifest.md` (238/238 resident, 26/26 shell) | ad-hoc script, not in repo | LOW | Counts match a fresh re-decompress; totals line uses a different metric than block size (sum of bytecode, not block decomp) |

## 4. HIGH-risk re-run deltas

The one tool still using the buggy helper (`cross_platform_vz_compare.py`) is
scoped to `scripts_vz` blocks only. Direct comparison on the PC Retail WAD
(`game-files/vz.wad`):

| Block | seg_count | header total_u | buggy LE | fixed LE | sha256 |
|---|---|---|---|---|---|
| `blocks\VZ\scripts_vz_P000_Q3.block` (idx 3197) | 25 | 1,579,504 | 1,579,504 | 1,579,504 | identical (`3207f5ca…`) |

No delta. Headline numbers in `cross_platform_vz_comparison.md` (PC Retail
1,579,504 B / 114 entries; Xbox 1,055,365 B / 114 entries; PC Demo 1,541,939 B /
111 entries) are correct.

Independent spot-check on `shell.wad` to show the bug is real where it was
*not* applied (and therefore to show nothing on disk had to re-run):

| Block | seg_count | header total_u | buggy LE | fixed LE |
|---|---|---|---|---|
| `blocks\Shell\resident_P000_Q3.block` | 49 | 3,206,931 | **1,376,256** | 3,206,931 |
| `blocks\Shell\scaleform_shell_P000_Q3.block` | 544 | 35,625,544 | **458,752** | 35,625,544 |
| `blocks\Shell\japanese_P000_Q3.block` | 5 | 266,220 | **65,536** | 266,220 |
| `blocks\Shell\cloud_noise_P000_Q3.block` | 17 | 1,048,730 | 1,048,576 | 1,048,730 |

These are the shape of the bug the brief described — none of them is read by
`cross_platform_vz_compare.py`, and the on-disk `shell_inventory.json` already
reports the correct 3,206,931 / 28 scripts, so no analysis file needs
correction.

## 5. Recommended corrections

- **No on-disk doc rewrites are warranted.** Every quoted figure traced in §3
  survives a re-run with the fixed decompressor.
- **Code hygiene (flag for user):** `cross_platform_vz_compare.py`'s local
  `decompress_le_sges` is a latent trap — the next person who widens its scope
  beyond `scripts_vz` (e.g. to `shell.wad`, `stringdb`, or any block with stored
  segments) will silently truncate. Suggest replacing its body with a thin
  wrapper that calls `sges_decompress.decompress_sges_block` (the fixed helper
  already in `tools/`). Not applied here — the brief forbids touching project
  files outside this audit, and the rename-and-delete is >1 line.
- The `cross_platform_vz_compare.decompress_be_sges` and
  `x360_dlc_io.decompress_be_sges` both derive segment ends from `(pos + 15) &
  ~15` rather than from each entry's absolute offset. On the Xbox 360 shell
  these agreed with each other on 30/30 `segs` blocks and matched the segment
  table arithmetic. Not the same bug — flagged only so the next hunt doesn't
  conflate them. (Xbox 360 `scaleform_shell` block fails LOUDLY in both BE
  helpers with `invalid block type`; that is a separate issue, not a silent
  truncation.)
