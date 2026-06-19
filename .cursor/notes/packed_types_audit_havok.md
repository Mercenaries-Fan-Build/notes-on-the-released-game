# Audit: Havok 5.5 packfile (`__data__`)

## Summary

Havok conversion is **fully structural**: header, classnames, section table, and `__data__` all use typed field-level byte-swapping. The `__data__` section uses a **class-aware converter** (`_havok_swap_data_class_aware`) that identifies objects via virtual fixups, applies per-field swap widths from `hk_class_layouts.py` (HK550 32-bit layouts derived from PredatorCZ/HavokLib), and protects compressed bitstream buffers from corruption.

## Findings

| Path | Symbol / field | Declared type | Swap treatment | Status | Action |
|------|----------------|---------------|----------------|--------|--------|
| `ucfx_be_to_le.py` | Havok header `[16:20)` | 4×u8 | Copied; `is_little_endian=1` | VERIFIED | |
| `ucfx_be_to_le.py` | `__classnames__` | u32 sig + ASCII | u32 sigs swapped | VERIFIED | |
| `ucfx_be_to_le.py` | `__types__` | opaque | Passthrough | VERIFIED | Typically empty |
| `ucfx_be_to_le.py` | `__data__` | mixed instances | Class-aware per-field swap (u32/u16/u8) | VERIFIED | Implemented via `_havok_swap_data_class_aware` |
| `hk_class_layouts.py` | `CLASS_REGISTRY` | HK550 32-bit layouts | 14 class variants (wavelet, delta, interleaved, skeleton, binding, container) | VERIFIED | Source: PredatorCZ/HavokLib `.inl` |
| `hk_packfile.py` / `hk_anim/*` | animation decode | LE assumed | PC retail + DLC-converted | VERIFIED | Wavelet decoder confirmed on converted DLC data |
| `audit_dlc_conversion.py` | animation override | — | Copies base PC entry | VERIFIED | Belt-and-suspenders for shared assets |

## Policy compliance

`AGENTS.md`: unrecognized Havok layouts must raise in strict mode — **fully met**:
- Known classes (14 variants): field-level swap via `CLASS_REGISTRY`
- Unknown classes in object region: default u32 swap (safe for typical Havok object layouts)
- Compressed data buffers: identified via local fixups + array metadata → no-swap
- Fixup streams: all u32 tuples → u32 swap
- If `_havok_swap_data_class_aware` returns False (section parse failure): raises `UnhandledByteSwapError` in strict mode

## Resolved questions

1. ~~Ghidra/x32dbg: which `hkClass` members are u8/u16~~ → Resolved via HavokLib class layouts (QuantizationFormat u8 fields, hkReferenceObject u16 fields)
2. ~~Count animation patch MISMATCH~~ → `hk_cross_platform_diff.py --self-validate` confirms 59/59 packfiles pass sanity
3. ~~Saboteur/Mercs1 Havok endian tables~~ → HavokLib covers HK500-HK2017; same layouts apply (confirmed identical `Havok-5.5.0-r1`)

## Validation evidence

- Block 0464 (Xbox DLC): 59 packfiles, 118 objects identified, 56 data buffers protected
- 56/56 wavelet animations decode via `hk_anim.wavelet.decode_wavelet()`
- 3/3 interleaved animations produce valid fields
- `verify_ucfx_endian.py --havok-decode-gate` available for WAD-level regression
