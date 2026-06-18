# Audit: Placements — `flgs`, Transform COMP, 42-byte records

## Summary

World placements use **42-byte records**, but **two different layouts** share the stride:

1. **layers_static Transform** (COMP `data`): entity_key + XYZ + quaternion — documented in `docs/placement_data_format.md`.
2. **vz_state `flgs`**: different field map — `docs/vz_state_analysis.md` §4.2.

`placement_extractor.py` reads Transform COMP for static world; vz_state reads `flgs` directly.

## Findings

| Path | Symbol / field | Declared type | Swap treatment | Status | Action |
|------|----------------|---------------|----------------|--------|--------|
| `placement_data_format.md` | Transform +0x04..+0x20 | 7×f32 | PC LE in retail; extractor uses `<f` | VERIFIED | No BE path on PC retail |
| `placement_extractor.py` | Transform record | u32 key + 6×f32 + tail | LE unpack only | VERIFIED | |
| `ucfx_be_to_le.py` | `_convert_flgs_records` | 42 B | 10×`>I`→`<I` + 1×`>H`→`<H` | SUSPECT | Coarse; endian-OK for aligned f32/u32 |
| `verify_ucfx_endian.py` | `_check_flgs` | assumes quat at +4,+18..+38 | f32 range heuristics | SUSPECT | Offsets match **neither** doc fully (y@18 vs @8) |
| `vz_state_analysis.md` | flgs record | u32 key, f32 boot, type_hash, … | — | VERIFIED layout doc | Decoder at `placement_extractor` vz_state path |
| `ucfx_ecs_codec.py` | `TRANSFORM_STRIDE` | 42 | LE only | VERIFIED | |

### `flgs` converter vs documented layouts

**layers_static Transform (COMP):**

```
+0x00 u32 key | +0x04..+0x0C f32 xyz | +0x10 f32 pad | +0x14..+0x20 quat | +0x24 6B tail
```

**`_convert_flgs_records`:** treats bytes 0–39 as ten u32 words, 40–41 as u16.

- Bytes 36–39 (part of 6-byte tail) are **u32-swapped** — likely harmless if tail ≈ 0.
- For **vz_state**, fields are not quaternion-at-18 layout; swap still valid for 4-byte scalars.

**`verify_ucfx_endian._check_flgs`:** checks `y@18, z@22, qx@26` — closer to vz_state (y@22 in extractor) but `x@4` matches both. Treat verifier as **heuristic**, not spec.

## Packed types

No `u8x4` / `u16x4` labels in placement pipeline. Rotation is **four f32** (SIMD-friendly but stored as scalars). No BE conversion on PC extraction path.

## Open questions

1. Does Xbox 360 `layers_static` use the same COMP/flgs split? If DLC port includes placement blocks, confirm `flgs` converter against `_audio_cross_platform_diff`-style diff.
2. Split `_convert_flgs_records` into vz_state vs static profiles once BE vz_state samples exist.
3. Fix `_check_flgs` offsets to match `placement_extractor` vz_state vs static modes separately.
