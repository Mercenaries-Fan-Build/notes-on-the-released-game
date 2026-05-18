# ASET chunk — row layout (Mercenaries 2 `vz.wad`)

**Date:** 2026-05-18  
**Status:** **Fully verified** — all four fields decoded. `u32_0` = asset name hash, `u32_2 >> 16` = block index confirmed by decompressing blocks and matching sub-entry headers.  
**Decoder:** [`tools/aset_decoder.py`](../tools/aset_decoder.py) → [`output/block_dependency_graph.json`](../output/block_dependency_graph.json)  
**Tracer:** [`tools/aset_prop_tracer.py`](../tools/aset_prop_tracer.py) — traces asset hashes through ASET→PTHS

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
| +0 | `asset_hash` | **Yes** | FNV-1a hash (with `\|0x20` case suppression) of the asset's internal name. Matches `name_hash` field in decompressed block sub-entry headers. **30,006 unique hashes** across 30,645 rows. |
| +4 | `secondary_ref` | **Yes** | `0xFFFFFFFF` = single-block asset (22,196 rows). Non-sentinel values are secondary block reference hashes for streaming dependencies (3,002 rows pointing to c3 cells, `resident2`, etc.). |
| +8 | `packed_block_ref` | **Yes** | **High 16 bits** = block index into PTHS/INDX (verified: 3,581 unique blocks referenced). **Low 16 bits** = `0xFFFF` for primary reference (19,847 rows), otherwise a sub-entry offset within the block. |
| +12 | `type_id` | **Yes** | Type discriminator (0–35). Maps 1:1 to the `type_hash` field in decompressed block sub-entry headers. See type table below. |

## Type discriminator table

| `type_id` | `type_hash` | Count | Description |
|-----------|-------------|-------|-------------|
| 27 | `0xf011157a` | 13,340 | Texture (DDS body) — same as `FORMAT_HASH_C3_BODY` |
| 28 | `0xbcfe6314` | 5,194 | Registry / configuration data (small 52–116 byte entries) |
| 16 | `0x18166555` | 4,261 | Havok 5.5 animation / skeleton data |
| 19 | `0x5b724250` | 3,007 | **Mesh / geometry** — same as `FORMAT_HASH_C3_MESH` |
| 12 | — | 1,026 | Unknown |
| 9 | — | 923 | Unknown |
| 35 | `0x42498680` | 645 | Unknown |
| 30 | `0x6310807f` | 625 | Unknown |

## Block distribution

ASET entries point to blocks by category:

| Category | ASET rows | % |
|----------|-----------|---|
| c3 cell (world geometry) | 15,324 | 50.0% |
| resident (always-loaded pack) | 7,018 | 22.9% |
| Vehicle blocks | 3,408 | 11.1% |
| Building / outpost blocks | 642 | 2.1% |
| Character blocks | 544 | 1.8% |
| vz_state overlays | 746 | 2.4% |
| resident2 (secondary pack) | 333 | 1.1% |
| Other | 2,630 | 8.6% |

### Where are the prop meshes?

Of the 3,007 mesh-type (type 19) ASET entries:
- **2,693 (89.6%)** are in c3 cell blocks
- **99** in resident2
- **82** in vehicle blocks
- **48** in building blocks
- **7** in the resident pack

Props like trees, rocks, fences, and street furniture are **embedded in c3 cell blocks**, not in standalone blocks. Each c3 cell contains all meshes + textures needed for that spatial region.

## Asset name hash opacity

The `asset_hash` values are FNV-1a hashes of internal asset names. These names are **not stored** anywhere in the WAD — only the hash survives. The original asset names were defined during Pandemic's build pipeline. Entity names from placement data (e.g., `_global_env_rocksbeach01`) are **instance names**, not asset names, and do not hash to ASET entries.

To reverse-map hashes → names would require the game's internal registry tables or brute-force hash collision with a comprehensive wordlist.

## Verification method

Confirmed by decompressing the `resident_P000_Q3.block` (demo WAD, block index 1250):
1. Block header contains `count(4) + count × entry(16)` with `(name_hash, type_hash, field_c, chunk_size)` per entry
2. All 2,331 `name_hash` values from the block appear in ASET `u32_0`
3. All corresponding ASET rows have `u32_2 >> 16 = 1250` (correct block index)
4. `type_hash` in block headers maps 1:1 to ASET `u32_3` type discriminator
