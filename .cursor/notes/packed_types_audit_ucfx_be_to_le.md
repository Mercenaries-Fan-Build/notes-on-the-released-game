# Audit: `tools/ucfx_be_to_le.py`

## Summary

Primary BE→LE structural converter for Xbox 360 DLC UCFX blocks. Uses explicit `struct.unpack('>')` / `pack('<')` per chunk; `_convert_u32_array` is a **testing-only fallback** via `UnhandledByteSwapError` in strict mode (matches `AGENTS.md`).

## Findings

| Path | Symbol / field | Declared type | Swap treatment | Status | Action |
|------|----------------|---------------|----------------|--------|--------|
| `ucfx_be_to_le.py` | `_convert_u32_array` | BE u32[] | Per-u32 BE→LE; trailing 1–3 bytes copied | VERIFIED | Never use for mixed layouts in strict mode |
| `ucfx_be_to_le.py` | `_convert_u16_array` | BE u16[] | Per-u16 swap | VERIFIED | Used for `decl`, `IBUF`, `INDX`, mesh index tags |
| `ucfx_be_to_le.py` | `_convert_deps_body` | u8 count + u32 hashes | Count byte preserved; hashes u32-swapped | VERIFIED | |
| `ucfx_be_to_le.py` | `_convert_flgs_records` | 42 B record | 10×u32 + 1×u16 per record; tail u32 sweep | SUSPECT | See [placements note](packed_types_audit_placements.md) |
| `ucfx_be_to_le.py` | `_convert_texture_info` | 7×u16 + FourCC + u32 + 4×u16 | u16/u32 typed; FourCC passthrough | VERIFIED | `docs/format_reference` texture INFO |
| `ucfx_be_to_le.py` | `_convert_dxt_*` | DXT1/3/5 blocks | u16/u32 per block; u8 alpha endpoints passthrough | VERIFIED | Xbox GPU BE multi-byte fields |
| `ucfx_be_to_le.py` | `_convert_wavebank_data` | 36 B record | `fmt_bytes` u8×4 copy; u32 fields swapped; `field_32` not endian-swapped | VERIFIED | Cross-platform diff + `docs/pandemic_audio_system_design.md` |
| `ucfx_be_to_le.py` | `_convert_soundbank_data` | Sectioned body | Periodic u8×4 skip + section u32 tables | VERIFIED (post-fix) | Stride now `sec/sub_count`; see [audio note](packed_types_audit_audio.md) |
| `ucfx_be_to_le.py` | `_convert_unknown_e5_data` | 28 B hdr + 12 B records | `[0:4]` LE count preserved; u16/u32 typed | VERIFIED | Hatch 5 layout in source |
| `ucfx_be_to_le.py` | `_convert_havok_be_to_le` | Havok 5.5 packfile | Header typed; `__data__` class-aware per-field swap via `_havok_swap_data_class_aware` + `hk_class_layouts.CLASS_REGISTRY` | VERIFIED | 14 class variants; u8/u16 fields preserved |
| `ucfx_be_to_le.py` | `STRM` tag | f32 vertex stream | `_convert_u32_array` (f32 as u32 bits) | VERIFIED | Endian-correct for IEEE floats |
| `ucfx_be_to_le.py` | `decl` tag | u16 vertex descriptors | `_convert_u16_array` | VERIFIED | Comment: u16-packed descriptors |
| `ucfx_be_to_le.py` | `data`+`IBUF` context | u16 indices | `_convert_u16_array` | VERIFIED | |
| `ucfx_be_to_le.py` | `_convert_body` default | unknown tag/hash | `UnhandledByteSwapError` or permissive u32 | VERIFIED | Policy-aligned |
| `ucfx_be_to_le.py` | `_convert_container` | chunk tags | `[::-1]` on 4-byte BE tags only | VERIFIED | Not numeric reversal |
| `ucfx_be_to_le.py` | `_fallback_u32_or_raise` | — | permissive → `_convert_u32_array` | VERIFIED | Counted in `verify_ucfx_endian --report-blind-swaps` |

## AGENTS.md policy compliance

| Rule | Compliance |
|------|------------|
| Semantic swaps only | **Yes** for all registered converters |
| Tag `[::-1]` OK | **Yes** — `XFCU`→`UCFX`, `MUSC`→`CSUM`, child tags |
| Unrecognized → `UnhandledByteSwapError` | **Yes** in strict `byteswap_ucfx_block` |
| No blind u32 in production | **Yes** — `dlc_port.py` default `permissive=False` |
| `--permissive` testing only | **Yes** — documented in CLI help |

## Open questions

1. How many patch blocks still hit `fallback_u32_count` under strict mode after latest type_hash handlers?
2. Should `STRM`/`IBUF` inside mesh containers be swapped in `dlc_port` itself (currently left BE; see `extract_amazon_dlc._swap_strm_ibuf_for_extraction`)?
3. Register converters for any tag still appearing in `audit_unhandled_tags.py` output on DLC-only blocks.
