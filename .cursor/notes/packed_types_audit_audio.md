# Audit: Audio — soundbank, wavebank, PWS

## Summary

Highest-risk packed-type region. `u8×4` flag bytes must not be treated as BE u32s. A prior **absolute-offset** skip map corrupted records 2+; fixed with **periodic** relative offsets (`docs/audio_crash_analysis.md`). This audit added stride fix + three more u8×4 offsets (2026-05-28).

## Type vocabulary (project convention)

From `tools/_audio_cross_platform_diff.py` / `_wad_audio_compare.py`:

| Class | Detection | BE→LE rule |
|-------|-----------|------------|
| `u8x4` | Xbox bytes == PC bytes | **No swap** |
| `u16x2` | Each u16 pair byte-reversed | Swap as two `>H` → `<H` |
| `u32` / `f32` | Full 4-byte reversal | `>I` / `>f` → LE |
| `zero` | All zero | Skip |

## Findings

| Path | Symbol / field | Declared type | Swap treatment | Status | Action |
|------|----------------|---------------|----------------|--------|--------|
| `ucfx_be_to_le.py` | soundbank `[0:4]` | u8×4 magic (`0x1D`) | Not swapped (read as LE u32) | VERIFIED | Do not use as record count |
| `ucfx_be_to_le.py` | `_SOUNDBANK_U8X4_RECORD_RELATIVE` | u8×4 flags | Skip on periodic rel offsets | VERIFIED (expanded) | Offsets 12,20,44,128,136,160 |
| `ucfx_be_to_le.py` | soundbank record stride | section A/C records | `(sec_len) // sub_count` | VERIFIED (fixed) | Was `magic*4` — wrong semantics |
| `ucfx_be_to_le.py` | soundbank sections B,D | u32 index tables | Full u32 swap | VERIFIED | |
| `ucfx_be_to_le.py` | wavebank `fmt_bytes` | u8×4 | `bytearray` copy; codec byte rewritten 0x05→0x02 | VERIFIED | |
| `ucfx_be_to_le.py` | wavebank `field_32` | platform u32 | Copied without endian swap | SUSPECT | Comment: engine may recompute |
| `ucfx_be_to_le.py` | wavebank `extra_20_28` | 3×u32 | Each u32 swapped | UNKNOWN | May contain packed sub-fields |
| `wad_simulator/.../soundbank.rs` | `U8X4_OFFSETS` | u8×4 | Read as u8 only (no swap in sim) | SUSPECT | Uses absolute 0x2C…0xC0 mod `record_size`; align with Python rel set |
| `docs/pandemic_audio_system_design.md` | §4.2 offsets | u8×4 | Documented 0x2C,0x34,0x4C,0xA0,0xA8,0xC0 | VERIFIED | Maps to rel 12,20,44,128,136,160 when base=0x20 |
| `_validate_dlc_soundbanks.py` | — | regression | Checks sub_count / sections | VERIFIED | Run on patch WAD after port |
| `_wad_audio_compare.py` | `classify_field` | auto u8x4/u16x2 | Research only | VERIFIED | Source of field maps |

## Fix applied (2026-05-28)

**File:** `tools/ucfx_be_to_le.py` — `_convert_soundbank_data`

- Record stride: `record_stride_a = (section_off1 - data_start) // sub_count`, `record_stride_c` from section C / `sub_count2`.
- Added u8×4 skip relatives `128, 136, 160` (design doc 0x80, 0x88, 0xA0).

## Open questions

1. Confirm on retail PC `vz.wad` that `magic*4` always equaled `sec_a/sub_count` (likely coincided at 116 B).
2. Section C: same u8×4 relative set as section A? Cross-diff only aggregated first 256 B of body (`ucfx_be_to_le` comment).
3. `field_32` in wavebank: Xbox vs PC semantic — x32dbg on wavebank loader.
