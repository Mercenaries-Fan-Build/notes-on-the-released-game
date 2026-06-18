# Audit: Mesh, texture, DXT, vertex streams

## Summary

Mesh pipeline reads **LE** data from retail PC WAD. DLC port byte-swaps UCFX mesh chunks via `ucfx_be_to_le`; **container STRM/IBUF** may remain BE until `extract_amazon_dlc._swap_strm_ibuf_for_extraction`. Vertex **decode** uses f16/snorm16 (packed half-float), not `u8x4`.

## Findings

| Path | Symbol / field | Declared type | Swap treatment | Status | Action |
|------|----------------|---------------|----------------|--------|--------|
| `ucfx_be_to_le.py` | `STRM` | f32 / f16 stream | `_convert_u32_array` at top level | VERIFIED | f32 endian via u32 |
| `ucfx_be_to_le.py` | `decl` | u16 vertex decl | `_convert_u16_array` | VERIFIED | |
| `ucfx_be_to_le.py` | `data`+`IBUF` | u16 indices | `_convert_u16_array` | VERIFIED | |
| `ucfx_be_to_le.py` | `INFO` texture | `_convert_texture_info` | u16 + FourCC + u32 | VERIFIED | |
| `ucfx_be_to_le.py` | `BODY` DXT | block-compressed | Per-block u16/u32; u8 passthrough | VERIFIED | |
| `ucfx_mesh_codec.py` | positions | f16_vec3, snorm16_vec3 | LE decode only | VERIFIED | Not BE swap path |
| `extract_amazon_dlc.py` | `_swap_strm_ibuf_for_extraction` | STRM/IBUF children | u16 swap on bodies + row hdr | VERIFIED | Host LE for `mesh_extractor` |
| `extract_amazon_dlc.py` | comment | STRM left BE in `dlc_port` | Intentional split | VERIFIED | Document in port runbooks |
| `mesh_extractor.py` / `gltf_exporter.py` | UV | f32 | V-flip only | VERIFIED | Not endian |

## `packed_field` (FFCS INDX) — not a vector type

`dlc_port.py` / `ffcs.rs`: `packed_field = (tier << 24) | decompressed_pages` — **bit-packed u32**, not SIMD. Semantic swap: full u32 BE→LE. **VERIFIED** via `verify_patch_wad_integrity.py`.

## Open questions

1. Are nested STRM `data` bodies always f16-aligned so u16 body swap in `extract_amazon_dlc` is sufficient?
2. PRMG bbox f32: swapped via parent `GEOM`/`info` u32 paths — confirm with `verify_ucfx_endian` BNDS/PRMG checks.
