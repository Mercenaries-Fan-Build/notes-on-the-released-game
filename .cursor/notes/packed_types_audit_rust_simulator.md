# Audit: Rust `tools/wad_simulator`

## Summary

Rust simulator consumes **PC LE** WAD data. Defines `packed_field` / `packed_block_ref` as FFCS bitfields. Audio soundbank module documents u8×4 offsets for **read validation only** (no BE conversion in sim).

## Findings

| Path | Symbol / field | Declared type | Swap treatment | Status | Action |
|------|----------------|---------------|----------------|--------|--------|
| `ffcs.rs` | `packed_field` | u32 | `read_u32_le` | VERIFIED | `decompressed_page_count()` masks low 24 bits |
| `overlay.rs` | `packed_block_ref` | u32 | LE; block_index / sub_entry split | VERIFIED | |
| `audio/soundbank.rs` | `U8X4_OFFSETS` | u8×4 | `read_u8` at 0x2C,0x34,0x4C,0xA0,0xA8,0xC0 mod record_size | SUSPECT | Absolute vs Python relative 12,20,44,… |
| `audio/soundbank.rs` | `record_size` | — | `(section_off1-data_start)/sub_count` | VERIFIED | Matches design doc; **better than old Python magic×4** |
| `placement.rs` | `flgs` | — | Presence check only | VERIFIED | |
| `ucfx.rs` / `texture.rs` | — | LE parse | No BE path | VERIFIED | |

## Open questions

1. Align `U8X4_OFFSETS` with Python `_SOUNDBANK_U8X4_RECORD_RELATIVE` (relative 12..160 vs absolute 0x2C..0xC0) — clarify in comments.
2. Add soundbank BE regression test in sim when Xbox DLC bytes are wired in.
