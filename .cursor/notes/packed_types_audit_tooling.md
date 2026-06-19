# Audit: Research & classification tooling (read-only)

## Summary

These scripts **discover** packed field types via Xbox vs PC byte comparison. They do not mutate WADs. Output feeds `ucfx_be_to_le` field maps.

## Findings

| Path | Role | Packed types | Status |
|------|------|--------------|--------|
| `tools/_audio_cross_platform_diff.py` | Auto-classify 4-byte fields | u8x4, u16x2, u32, f32, mixed | VERIFIED |
| `tools/_wad_audio_compare.py` | Diff + converter hints | Same vocabulary | VERIFIED |
| `tools/_soundbank_record_layout.py` | `classify_field()` | u8x4 heuristic (small bytes ≤10) | SUSPECT | Heuristic can misclassify |
| `tools/_validate_dlc_soundbanks.py` | Patch regression | u8x4 periodic corruption guard | VERIFIED |
| `tools/_wavebank_xplat_spec.py` | Wavebank spec | u8×4 `format_bytes` | VERIFIED |
| `tools/_quick_header_diff.py` | Header bytes | Labels IDENTICAL vs SWAP | VERIFIED |

## Usage for future agents

1. Run `_audio_cross_platform_diff.py` when adding new audio type_hashes.
2. Paste “CONVERTER FIELD MAP” section into `ucfx_be_to_le.py` only after manual review — never auto-apply u32 to `u8x4` offsets.
3. `classify_field` “mixed” (~0.2% in soundbank section 3) → needs per-field x32dbg proof.

## Open questions

1. Wire `_wad_audio_compare` output into CI artifact when both Xbox and PC WAD paths exist on runner.
