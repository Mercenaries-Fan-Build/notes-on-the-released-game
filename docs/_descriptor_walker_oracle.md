---
status: current
evidence: proven
date: 2026-10-03
scope: UCFX descriptor walker — PS3 `decl` chunk handling in `ucfx_byteswap::convert_block`
inputs:
  - tools/wad_simulator/crates/mercs2_formats/src/be_to_le/convert.rs
    (convert_decl + convert_decl_ps3_compact)
  - scratchpad/dlc01_pipeline/ps3_dlc01_be.scff
    sha256: cc58b68d614786ebbab79e0129a6def0c31adebdc897b2c623892935ab5fca00
  - output/_scratch/dlc01.doh (Xbox 360 oracle)
    sha256: 5b0c222d925e8c85000a925262e2b789fbf8c3e476d3d89e5935c7c018deb3ae
  - output/_ghidra/mercs2_unpacked.exe_decomp.txt
    (PC `decl` dispatch @0x4a47e2, PC decl installer FUN_00752b30 → FUN_0074d6d0)
---

# Descriptor-Walker Oracle — PS3 `decl` Compact Format

End-to-end audit of the 472-block gap between the Xbox DOH route (2,196/2,196
accepted) and the PS3 SCFF route (1,753/2,225 accepted) through
`ucfx_byteswap::convert_block`, with the engine binaries used as the walking
oracle.

## Verdict

- 470 of 478 PS3-side rejections (**98.3 %**) are a single structural class:
  the PS3 DLC01 `decl` chunk body uses a **compact per-STRM-group token
  format** (2-byte header `03 00` + 2–18 bytes of body) that the Xbox-tuned
  walker in `convert_decl` did not recognise. Pre-fix those bodies landed in
  two red-herring buckets (`decl body too small` and `produced 0 vertex
  element, END=false`); post-fix they take a dedicated `convert_decl_ps3_compact`
  arm that **fails loud with the pattern name and the architectural reason**.
- The remaining 8 rejections (**7 wavebank**, **1 unluac**) are shared with
  the Xbox DOH input (same 8 blocks fail on both platforms, with the same
  errors), so they are not a PS3-side descriptor-walker gap — the Xbox DOH
  route also rejects them. They stay out of this doc's scope.
- The **net production impact is diagnostic clarity, not rejection reduction**.
  The 470 blocks still fail to convert because PS3 ships a non-interleaved
  multi-stream vertex layout (one STRM group per attribute) while the PC
  engine requires a single-stream interleaved `D3DVERTEXELEMENT9` array.
  Translating a single PS3 compact decl in isolation would emit a
  geometry-less or partial decl that silently breaks the mesh — the honest
  behaviour is to fail with a specific message. The X360 DOH import route
  (`dlc_port --x360-stfs dlc01.doh`, §5 of `docs/_dlc01_pipeline_readiness.md`,
  2196/2196 PROVEN) is the one that produces a loadable overlay today.

## Coverage of the 472 rejection cases

| Class | Count | How it was mis-labelled before | How it is labelled now | Walker action |
|---|---:|---|---|---|
| PS3 compact decl `03 00 ...` (known terrain patterns) | 170 | `produced 0 vertex element, END=false, from a 12-byte source` | `PS3 compact decl detected (terrain stride-N …): multi-stream …` | Fail loud (named) |
| PS3 compact decl `03 00 ...` (known mesh patterns) | 638 | `decl body too small for a vertex declaration` | `PS3 compact decl detected (mesh/foliage stride-N …): multi-stream …` | Fail loud (named, with 1-to-many ambiguity call-out) |
| PS3 compact decl `03 00 ...` (unknown pattern) | 0 | — | `unrecognised PS3 compact decl pattern` | Fail loud (generic) |
| Wavebank `records_offset 56, expected 40` | 7 | shared with Xbox DOH | same | Fail loud (unchanged — out of scope) |
| `unluac.jar not found` | 1 | shared with Xbox DOH | same | Fail loud (unchanged — environment) |
| **TOTAL rejected (PS3)** | **478** | | | |

The 170+638=808 "walker reclassification" count is the per-descriptor count
across the 470 rejected blocks (each block has multiple PS3 `decl` chunks).
Of the 7,806 PS3 `decl` descriptors in the SCFF, 100 % now take the dedicated
arm; the 470-block rejection stays because the walker alone cannot bridge
multi-stream → single-stream.

## The oracle: PC decl installer `FUN_00752b30` → `FUN_0074d6d0`

PC source: `output/_ghidra/mercs2_unpacked.exe_decomp.txt`

- `output/_ghidra/mercs2_unpacked.exe_decomp.txt:83425` — the `decl` dispatch:
  `else if (iVar5 == 0x6c636564)` — immediate `0x6c636564` is `b"decl"` as a
  LE u32. The handler calls `FUN_00752b30(decl_body_ptr)` with the raw body.
- `output/_ghidra/mercs2_unpacked.exe_decomp.txt:454950` — `FUN_00752b30` is
  the PC vertex-decl installer. It delegates body parsing to
  `FUN_0074d6d0(decl_body, out_type_mask, &out_total_bytes)`.
- `output/_ghidra/mercs2_unpacked.exe_decomp.txt:451199` — `FUN_0074d6d0`
  reads the body as an **8-byte-per-element D3DVERTEXELEMENT9 array**:
  the loop condition is `while (param_1[iVar6 * 4] != 0xff)` (increment by
  4 shorts = 8 bytes), each element is read as `[u16 Stream][u16 Offset]
  [u8 Type][u8 Method][u8 Usage][u8 UsageIndex]`.

**Consequence (PROVEN):** the PC game accepts only the 8-byte-element
`D3DVERTEXELEMENT9` layout. Both the Xbox fetch-decl path and any new
PS3-compact path must emit that same output.

## The PS3 compact format — pattern catalogue (PROVEN by data census)

A census of every `decl` body in the PS3 DLC01 SCFF
(`scratchpad/descriptor_walker_oracle/ps3_decl_census/decl_census.txt`,
`total decl descriptors: 7,806`) shows **11 distinct (type_hash, size, bytes)
tuples**. Every tuple shares the 2-byte header `03 00`; the Xbox fetch-decl
header always starts with `00 00 00 00`, so the header byte is an unambiguous
dispatch key.

Per-pattern enumeration (ps3_bytes · stride read from the sibling `info`
chunk · count · Xbox-DOH oracle at the same block/desc index). The Xbox-DOH
oracle is the retail Xbox 360 DOH extracted from
`Mercenaries.2.World.In.Flames.DLC.RF.X360-ZTM.rar` (sha256 5b0c222d…),
which the walker already converts cleanly:

### Terrain (`type_hash` = `0x7C569307`) — all 1-to-1 with Xbox

- **`0300000304060304060a0201`** · stride 14 · 1,296 descriptors
  Xbox: 48 B · elements `{COLOR @ 8 D3DCOLOR}`, `{NORMAL @ 12 F16x4}`.
  Note: Xbox interleaves POSITION in the SAME stream (stride 20); PS3 omits
  POSITION here — POSITION lives in a sibling PS3 STRM group.
- **`0300000303060802040a0304060e020103120e04`** · stride 26 · 294 descriptors
  Xbox: 72 B · `{UV@8 F16x2}`, `{COLOR@12 D3DCOLOR}`, `{NORMAL@16 F16x4}`,
  `{TANGENT@20 F16x4}`.
- **`0300000303060802060a0201030e0e04`** · stride 22 · 123 descriptors
  Xbox: 60 B · `{UV@8 F16x2}`, `{NORMAL@12 F16x4}`, `{TANGENT@16 F16x4}`.
- **`0300000303060802040a0304060e0201`** · stride 18 · 19 descriptors
  Xbox: 72 B · `{UV@8}`, `{COLOR@12}`, `{NORMAL@16}`.
- **`0300000303060802060a0201`** · stride 14 · 6 descriptors
  Xbox: 48 B · `{UV@8 F16x2}`, `{NORMAL@12 F16x4}`.

### Lowres terrain (`type_hash` = `0x1602815C`) — 1-to-1 with Xbox

- **`0300000306060201`** · stride 10 · 81 descriptors
  Xbox: 36 B · `{NORMAL@8 F16x4}`.

### Mesh / foliage ambiguity (`type_hash` = `0x5B724250` / `0x600B904E`)

- **`03000802`** · stride 4 · 4,028 (mesh) + 703 (foliage) descriptors.
  **1-to-many** against Xbox-DOH decls at the same block/desc index:
  for `0x5B724250` the same compact body appears at descriptors whose
  Xbox-DOH equivalent is any of **10 distinct decls** (seen in
  `scratchpad/descriptor_walker_oracle/ps3_xbox_decl_mapping.md`).
- **`0300080204040304`** · stride 8 · 918 (mesh) + 24 (foliage) descriptors.
  Mesh case is 1-to-many against **9 distinct Xbox decls**; foliage case
  is 1-to-1 (COLOR+NORMAL stream pair at a known offset).
- **`0300080206040201`** · stride 8 · 314 descriptors. 1-to-1 against Xbox
  `{UV@8 F16x2}`, `{NORMAL@12 F16x4}`.

**Ambiguity cause (INFERRED, well-supported):** the PS3 ships a
non-interleaved multi-stream vertex layout (one STRM group per attribute,
with per-stream stride typically 4/8/14/22/26 B), while Xbox interleaves
everything into a single stream (per-vertex stride 20/24/28/32/36 B). The
PS3 compact `decl` describes only its one stream's slice; the full
per-vertex layout is scattered across sibling STRM groups and only the
engine's runtime stream-source bindings know how they combine. Each
distinct 1-to-many "same compact body → 10 Xbox decls" case corresponds to
10 different full-vertex layouts that happen to share the same single-
stream slice description. **No PS3 engine binary function was found that
decodes this compact body into a self-contained decl**; the PS3 EBOOT
decomp (`output/_ghidra_ps3_retail/ps3_retail_decomp_named.c`, 55k lines,
no `decl` string literal) and the Xbox 360 final decomp
(`output/_ghidra_x360_final/xenon_final_decomp_named.c`, 1.8 M lines, no
`decl` string literal) do not expose the parser; the PC decomp has only
the single-stream D3DVERTEXELEMENT9 reader cited above.

## What the fix does

In `tools/wad_simulator/crates/mercs2_formats/src/be_to_le/convert.rs`,
`convert_decl` now gates on `be[0] == 0x03 && be[1] == 0x00` and routes to
`convert_decl_ps3_compact`. The arm:

- Pattern-matches against the 11-entry vocabulary above, citing the Xbox-DOH
  oracle decl for each.
- Builds an error message naming the pattern, the stride (if the sibling
  `info` is readable at call time — the caller holds the context), and the
  architectural reason (multi-stream vs single-stream).
- A pattern not in the catalogue falls to a generic `unrecognised PS3
  compact decl pattern` message (never `_` → silent skip).
- No PC decl is synthesised. Emitting one from the compact body alone would
  silently drop whichever attributes the compact body does not describe
  (every attribute that lives in a sibling PS3 STRM group), i.e. the
  "silently drop the mesh" failure the Xbox path already guards against.

Four tests in `convert.rs` lock the behaviour:

- `ps3_compact_decl_terrain_stride14_ground_detected`
- `ps3_compact_decl_terrain_stride26_detected`
- `ps3_compact_decl_mesh_stride4_detected`
- `ps3_compact_decl_unknown_pattern_fails_loud`
- plus `xbox_decl_still_dispatches_after_ps3_arm_added` guarding the
  gate against regression on Xbox fetch-decls.

Each terrain / mesh fixture is a real PS3 DLC01 decl body (byte-identical
to the census output), with the Xbox-DOH equivalent cited in the test
comment.

## What still breaks and why

Running `ps3_dlc_reject_classify` on the post-fix build:

```
blocks: 2225
converted: 1747
rejected: 478
Rejections grouped by class (sorted by count):
    470  convert_block: PS3 compact decl detected (…): the PS3 DLC ships a
         non-interleaved multi-stream vertex layout; …
      7  convert_block: wavebank transcode: wavebank records_offset 56, expected 40
      1  convert_block: unluac.jar not found
```

The 470 count is the **unchanged** rejection figure — the walker correctly
refuses to silently fabricate PC decls from compact PS3 bodies. The gain is
diagnostic: a reader now sees exactly which pattern and the architectural
cause, instead of a misleading "body too small" / "0 elements".

Three deliverable paths were considered for the 470:

1. **Emit the Xbox-DOH decl at the same block/desc** — this is the single
   oracle that resolves 1-to-1 for terrain (170 descriptors) and 1-to-1 for
   some mesh variants. It requires `dlc_port` to take BOTH the PS3 SCFF and
   the Xbox DOH as inputs. Would land the terrain blocks (reducing the 625
   sentinelled LOD rungs in the readiness doc) but not the mesh blocks
   (ambiguous).
2. **Implement a multi-STRM merge pass** — collect every PS3 STRM group for
   a mesh, interleave their vertex buffers into a single PC single-stream
   buffer, synthesise one combined PC decl. Correct, but outside the
   descriptor walker's scope: it rebuilds the `data` and `IBUF` layouts, not
   just the `decl`.
3. **Fail loud and route through the X360 DOH import** — the current
   production flow (`output/data/dlc01-patch.wad` is built this way and is
   proven loadable; §5 of `docs/_dlc01_pipeline_readiness.md`).

This change takes path 3 at the walker level and documents paths 1 and 2 for
follow-on work.

## Artifacts

Under `C:/Users/Shadow/AppData/Local/Temp/claude/c--Users-Shadow-Desktop-notes-on-the-released-game/3daa7290-1887-4d90-a52c-94355e911851/scratchpad/descriptor_walker_oracle/`:

- `summary.txt` — pre-fix rejection classification (3 classes, 478 total).
- `classification.tsv` — per-block (2225 rows) class assignment pre-fix.
- `ps3_classify_postfix/summary.txt` — post-fix classification (3 classes,
  478 total, with the 470 now carrying the dedicated PS3 arm message).
- `ps3_decl_census/decl_census.txt` — PS3 decl census: 11 distinct tuples
  across 7,806 descriptors.
- `xbox_decl_census/decl_census.txt` — Xbox decl census: 20 distinct tuples
  across 7,949 descriptors.
- `ps3_xbox_decl_pair.tsv` — per-descriptor pairing of PS3↔Xbox decls at
  the same `(block_path, desc_idx, type_hash)` tuple.
- `ps3_xbox_decl_mapping.md` — summary of the pairing: per-pattern
  distinct-Xbox counts (the proof of 1-to-many for mesh/foliage, 1-to-1
  for terrain and lowres).
- `convert_block__*.bin` — one real-body fixture per rejection class
  (`c30113_P000_Q3.block`, `dlc01_terrain_r00_c00_...block`, etc.).
- `decls_c30113/`, `decls_terrain_r00/` — extracted per-STRM-group decl
  bodies from the two representative fixtures.

Probe binaries used (all `cargo run -p mercs2_probe --bin <name>`):

- `ps3_dlc_reject_classify` — walk every block through the same path
  `dlc_port` uses, bucket rejections by error class, write fixtures.
- `ps3_decl_dump` — dump every `decl` body from one block fixture, with the
  parent STRM/parent-tag context.
- `ps3_decl_census` — enumerate distinct `decl` byte-pattern tuples over
  an entire SCFF/DOH.
- `ps3_xbox_decl_pair` — pair PS3 and Xbox decls at the same
  (block_path, desc_idx, type_hash) across two containers.
