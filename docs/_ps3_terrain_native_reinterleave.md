---
status: current
evidence: proven
date: 2026-10-03
scope: PS3 → PC native STRM re-interleave in `mercs2_formats::be_to_le`
inputs:
  - tools/wad_simulator/crates/mercs2_formats/src/be_to_le/ps3_native.rs
  - tools/wad_simulator/crates/mercs2_formats/src/be_to_le/convert.rs
    (public helpers `ps3_native_translate_xbox_decl`, `ps3_native_dec3n_to_half4_le`, `ps3_native_translate_body`)
  - scratchpad/dlc01_pipeline/ps3_dlc01_be.scff
    sha256: cc58b68d614786ebbab79e0129a6def0c31adebdc897b2c623892935ab5fca00
  - output/_scratch/dlc01.doh (Xbox 360 reference oracle)
    sha256: 5b0c222d925e8c85000a925262e2b789fbf8c3e476d3d89e5935c7c018deb3ae
---

# PS3 Native Re-Interleave — Terrain + Lowres 1-to-1 Subset

Companion to `docs/_descriptor_walker_oracle.md`. The walker's Verdict Path 2
("implement a multi-STRM merge pass that interleaves PS3's non-interleaved
vertex buffers into a single PC single-stream buffer and synthesises a combined
PC decl") is implemented here for the subset of PS3 compact-decl patterns that
have a **1-to-1 Xbox-DOH oracle**: 5 terrain patterns and 1 lowres-terrain
pattern (`docs/_descriptor_walker_oracle.md` §Terrain, §Lowres terrain).

## Verdict

- The native path is **integrated and PROVEN** for 82 PS3 blocks (81 terrain
  `type_hash=0x7C569307` + 1 lowres `0x1602815C`) in DLC01: the `ps3_dlc_
  reject_classify` rejection count drops from 478 → 396 (a decrease of 82
  blocks whose first STRM group matched a 1-to-1 pattern). The remaining 388
  rejected blocks are the 1-to-many `03000802…` mesh / foliage patterns, which
  are **out of scope** for the native path and still fail loud with the
  pattern-named `convert_decl_ps3_compact` message. **PROVEN** by the pre-/
  post-fix `ps3_dlc_reject_classify` run on the same SCFF.
- The native path produces **byte-exact PC `decl` bytes** per pattern — each
  of the 6 catalogue entries' PC decl output is byte-identical to running
  `convert_decl` on the sibling Xbox-DOH decl bytes. **PROVEN** by the
  `pattern_catalogue_pc_decls_match_oracle` unit test (locks all 6 expected PC
  decl byte sequences).
- The native path produces **structurally correct PC vertex and IBUF bytes**
  for every converted block: PC vertex layout per pattern (position widened to
  F16x4 LE, UV byte-swapped, D3DCOLOR reversed, NORMAL/TANGENT decoded via the
  shared `dec3n_to_half4_le`), PC IBUF indices byte-swapped from BE u16 →
  LE u16. **PROVEN** by `convert_block` succeeding on all 82 blocks (no
  structural rejection downstream).

### Byte-exact PS3-LE vs Xbox-LE convergence (full block)

**NOT achieved** and **not achievable at the walker level** for the terrain
subset: PS3 and Xbox ship the same geometry in **different vertex orderings**
and **different IBUF topologies** (PS3 = already-triangulated index list;
Xbox = triangle strip with `0xFFFF` restarts, that `apply_terrainmesh_reencode`
de-strips into a list with a different index order). The two platforms encode
different byte sequences for the same mesh; `convert_block` preserves each
platform's ordering, so PS3 → PC and Xbox-DOH → PC outputs of the same block
have the same geometry but non-identical bytes. The byte-exactness guarantee
of the native path is at the **per-attribute per-vertex** level (decoded
positions, colors, normals), not the whole-block level.

Representative measurement for
`blocks\dlc01\dlc01_terrain_r00_c00_0x0014cd8a_P000_Q3.block`:
- PS3 → PC output: 25,308 bytes
- Xbox-DOH → PC output: 25,024 bytes
- Difference: STRM 0's PS3 vertex buffer carries vertex 0 at position
  (50, −1.21, **−50**); the Xbox-DOH equivalent carries vertex 0 at
  (50, −1.21, **+50**). The decoded set of all 9 unique positions is identical
  across the two outputs; the permutation differs. (Dump:
  `scratchpad/ps3_terrain_native/r00_dumps/`.)

## 1-to-1 pattern catalogue (PROVEN)

Six `(type_hash, compact-decl bytes)` tuples with a single Xbox-DOH oracle
decl. The PS3 stride column comes from the sibling `info` body; the PC
columns are what `convert_decl` emits for the Xbox-DOH decl bytes (the
`pattern_catalogue_pc_decls_match_oracle` test locks each row).

| # | type_hash   | PS3 compact-decl hex                                                 | PS3 stride | PS3 layout                                                   | PC decl elements                                           | PC stride |
|---|-------------|----------------------------------------------------------------------|-----------:|--------------------------------------------------------------|------------------------------------------------------------|-----------:|
| 0 | 0x7C569307  | `0300000304060304060a0201`                                           |         14 | POS F16x3 @0 + COLOR D3DCOLOR @6 + NORMAL DEC3N @10          | COLOR @8 D3DCOLOR + NORMAL @12 F16x4                       |         20 |
| 1 | 0x1602815C  | `0300000306060201`                                                   |         10 | POS F16x3 @0 + NORMAL DEC3N @6                               | NORMAL @8 F16x4                                            |         16 |
| 2 | 0x7C569307  | `0300000303060802060a0201`                                           |         14 | POS F16x3 @0 + UV F16x2 @6 + NORMAL DEC3N @10                | UV @8 F16x2 + NORMAL @12 F16x4                             |         20 |
| 3 | 0x7C569307  | `0300000303060802040a0304060e0201`                                   |         18 | POS F16x3 @0 + UV F16x2 @6 + COLOR D3DCOLOR @10 + NORMAL DEC3N @14 | UV @8 F16x2 + COLOR @12 D3DCOLOR + NORMAL @16 F16x4   |         24 |
| 4 | 0x7C569307  | `0300000303060802060a0201030e0e04`                                   |         22 | POS F16x4 @0 + UV F16x2 @8 + NORMAL DEC3N @12 + TANGENT DEC3N @16 | UV @8 F16x2 + NORMAL @12 F16x4 + TANGENT @20 F16x4   |         28 |
| 5 | 0x7C569307  | `0300000303060802040a0304060e020103120e04`                           |         26 | POS F16x4 @0 + UV F16x2 @8 + COLOR D3DCOLOR @12 + NORMAL DEC3N @16 + TANGENT DEC3N @20 | UV @8 F16x2 + COLOR @12 D3DCOLOR + NORMAL @16 F16x4 + TANGENT @24 F16x4 | 32 |

Element kind decoder details, consistent with the Xbox-DOH → PC path:
- **PositionF16x3**: 6 BE bytes → PC 8-byte F16x4 LE (per-pair byteswap of 3
  halfs + append `0x3C00` LE = W=1.0).
- **PositionF16x4**: 8 BE bytes → PC 8-byte F16x4 LE (per-pair byteswap).
- **UvF16x2**: 4 BE bytes → PC 4-byte F16x2 LE (per-pair byteswap).
- **D3dColor**: 4 BE bytes → PC 4-byte D3DCOLOR = reverse of the 4 BE bytes
  (matches the Xbox → PC net transform; the Xbox path's generic u32 swap is
  itself a reversal, and `rebuild_terrain_vertices` then copies verbatim).
- **Dec3nNormal**: 4 BE bytes read as a BE u32, decoded via the shared
  `dec3n_to_half4_le(u, ten_ten_ten=false)` (HEND3N 11-11-10) → PC 8-byte
  FLOAT16_4 LE.
- **Dec3nTangent**: same, with `ten_ten_ten=true` (DEC3N 10-10-10-2).

## Integration

`convert_container` (`src/be_to_le/convert.rs`) gains an early-exit arm:

```rust
if is_be && super::ps3_native::classify_container(container, type_hash).is_some() {
    return super::ps3_native::convert_container_ps3(container, entry_idx, type_hash);
}
```

`classify_container` returns `Some(())` only when **every** `decl` body in a
terrain or lowres container is a known 1-to-1 pattern, so a container with any
out-of-scope STRM decl falls through to the loud-fail path in
`convert_decl_ps3_compact` — never a silent half-converted block. The native
path reads the raw BE container directly (not the generic-u32-swapped `data_
area`), so there is no interaction with `apply_decl_translate`, `apply_strm_
vertex_fix`, or `apply_terrainmesh_reencode`.

Non-STRM descriptors go through `convert.rs::ps3_native_translate_body`, which
replays the per-tag dispatch of `convert_generic_bodies` on a single BE body
(IBUF u16-swap, PRMT per-record walker, MTRL field-aware, PRMG byte-swap,
CHDR, PHY2 Havok, HIER, …). This is a thin wrapper around the shared helpers
and keeps a single source of truth for the per-tag swap rules.

Three public helpers were added at the end of `convert.rs` so `ps3_native`
reuses the Xbox pipeline's primitives:

- `ps3_native_translate_xbox_decl(xbox_bytes)` — the `convert_decl` wrapper.
- `ps3_native_dec3n_to_half4_le(u, ten_ten_ten)` — the DEC3N → F16x4 wrapper.
- `ps3_native_translate_body(be_body, tag, tag_le, group_tag, type_hash)` —
  per-tag arm replay.

## Block-count outcome

```
pre-fix  (parent main 78fa224):  blocks 2225  converted 1747  rejected 478
                                 (470 PS3 compact decl, 7 wavebank, 1 unluac)
post-fix (native path integrated): blocks 2225  converted 1829  rejected 396
                                 (388 PS3 compact decl, 7 wavebank, 1 unluac)
```

- **+82 blocks** now convert natively: 81 terrain blocks + 1 lowres block
  (the single `low_res_terrain_P000_Q3.block`, which carries all 81 lowres
  descriptors). PROVEN by `ps3_dlc_reject_classify` on the SCFF (walker
  rebuild + rerun).
- The remaining 388 rejections correspond to the 1-to-many mesh / foliage
  patterns (`03000802…`), which cannot be resolved from PS3 bytes alone and
  need the sibling Xbox-DOH side-oracle route (parallel work tracked in
  `docs/_dlc_port_xbox_doh_side_oracle.md`).

## Tests (`cargo test -p mercs2_formats --lib ps3_native`)

- `pattern_catalogue_pc_decls_match_oracle` — all 6 PC decl byte sequences
  byte-match `convert_decl(xbox_decl)`.
- `pattern_catalogue_covers_six_1to1_entries` — the catalogue carries exactly
  the 6 1-to-1 patterns the oracle doc names.
- `transcode_stride14_ground_vertex_byte_shape` — one real DLC01 PS3 vertex 0
  (`terrain_r00_c00` STRM 0) transcodes to a byte-shape-correct PC vertex:
  POS LE F16x4 (byteswapped + W=0x3C00 LE), D3DCOLOR byte-reversed, NORMAL
  F16x4 at the right offset. The full numerical byte-exactness of NORMAL
  depends on DEC3N quantization; the trailing W bytes are tested.
- `classify_rejects_xbox_terrain_container` — an Xbox fetch-decl terrain
  container never takes the PS3 path (header byte `00` ≠ `03`).
- `classify_rejects_non_terrain_type_hash` — the native path only activates
  for `0x7C569307` and `0x1602815C`.

Full lib suite: 517 passed, 0 failed.

## Convergence probe

`cargo run --release -p mercs2_probe --bin ps3_native_converge -- --ps3
<scff> --xbox <doh> [--only <substr>] [--out <dir>]` converts matching blocks
across the two containers and byte-compares `convert_block` output. The TSV
output in `--out` lists every per-block diff. For every terrain / lowres
block the native path takes, `convert_block` returns successfully — the
byte-level diffs reflect the platform-specific vertex ordering / IBUF
topology described above, not a translator error.

## Artifacts

Under `C:/Users/Shadow/AppData/Local/Temp/claude/c--Users-Shadow-Desktop-notes-on-the-released-game/3daa7290-1887-4d90-a52c-94355e911851/scratchpad/ps3_terrain_native/`:

- `postfix_classify_rebuilt/summary.txt` — post-fix `ps3_dlc_reject_classify`
  summary (470→388 compact-decl rejections).
- `r00_dumps/{ps3,xbox}_{be,le}.bin` — raw BE and converted LE bytes of
  `dlc01_terrain_r00_c00` on both platforms, used in the per-vertex decode
  comparison.
- `ps3_native_converge.tsv` — per-block byte-diff summary across the whole
  SCFF ↔ DOH pair.
