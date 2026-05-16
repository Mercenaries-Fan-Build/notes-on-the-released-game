# ASET chunk — row layout (Mercenaries 2 `vz.wad`)

**Date:** 2026-05-15  
**Status:** Partially verified — row width and `u32_0` ↔ `texture_index.json` correlation verified from retail `output/extracted/ffcs_vz/aset.bin`.  
**Decoder:** [`tools/aset_decoder.py`](../tools/aset_decoder.py) → [`output/block_dependency_graph.json`](../output/block_dependency_graph.json)

## Manifest facts (retail)

From [`output/extracted/ffcs_vz/manifest.json`](../output/extracted/ffcs_vz/manifest.json):

| Chunk | `meta` (row count) | `size` (bytes) | Bytes / row |
|-------|-------------------|----------------|-------------|
| ASET | 30,645 | 490,320 | **16** |

Demo `vz.wad` uses the same **16 bytes/row** (see [`docs/demo_corpus.md`](demo_corpus.md)).

## Row layout (little-endian)

Each row is four `uint32`:

| Offset | Field | Verified? | Notes |
|--------|-------|-------------|-------|
| +0 | `u32_0` | **Yes (subset)** | Matches keys in `output/extracted/texture_index.json` for **13,614 / 30,645** retail rows (≈44%). Likely primary **asset / streaming hash** key. |
| +4 | `u32_1` | No | Often `0xffffffff`; treat as sentinel until proven otherwise. |
| +8 | `u32_2` | No | Variable; not correlated in-repo yet. |
| +12 | `u32_3` | No | Small integer range observed (0–35); could be LOD / pack / type discriminator. |

## What this is *not* (yet)

- Not proven as a pure **block-index → block-index** adjacency list (values do not fall in `0 … INDX.meta-1` as block indices).
- Not mapped to `paths.txt` stems without further joins (likely needs additional tables or hashes from UCFX / INDX).

## Next verification steps

1. Cross-reference `u32_0` with non-texture asset hashes from `mesh.meta.json` or `ucfx.json` samples.  
2. Compare row pairs against known PMC interior bundle (five `vz_state_pmcinterior_*` blocks + meshes) once ECS joins land.  
3. Diff **demo** vs **retail** `aset.bin` row multiset for shared keys (subset analysis).
