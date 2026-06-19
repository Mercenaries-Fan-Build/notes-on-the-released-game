# Packed / SIMD-like types & byte-swap audit — master index

**Date:** 2026-05-28  
**Scope:** Mercenaries 2 recreation repo (`notes-on-the-released-game`)  
**Policy source:** `AGENTS.md` § Byte-Swap Policy; implementation hub: `tools/ucfx_be_to_le.py`

This audit catalogs uses of packed vector semantics (`u8×4`, `u16×2`, `u32×2`, DXT blocks, etc.) and whether BE→LE conversion treats them as scalars. Notes live only under `.cursor/notes/` (not `docs/`).

## Status legend

| Status | Meaning |
|--------|---------|
| **VERIFIED** | Type + swap documented; cross-platform or retail binary evidence cited |
| **SUSPECT** | Plausible mismatch between declared type and swap path |
| **UNKNOWN** | Needs x86dbg / retail PC vs Xbox diff on specific block |

## Sub-notes

| Subsystem | File | Risk |
|-----------|------|------|
| UCFX converter (core) | [packed_types_audit_ucfx_be_to_le.md](packed_types_audit_ucfx_be_to_le.md) | **High** — all DLC port swaps |
| Audio (soundbank / wavebank) | [packed_types_audit_audio.md](packed_types_audit_audio.md) | **High** — known crash class |
| Soundbank u8×4 periodic swap (root cause) | [soundbank_u8x4_periodic_swap_root_cause.md](soundbank_u8x4_periodic_swap_root_cause.md) | **High** — MixSources overflow chain |
| Placements (`flgs`) | [packed_types_audit_placements.md](packed_types_audit_placements.md) | Medium |
| Mesh / texture / DXT | [packed_types_audit_mesh_texture.md](packed_types_audit_mesh_texture.md) | Medium |
| Havok animation | [packed_types_audit_havok.md](packed_types_audit_havok.md) | ~~High~~ → **VERIFIED** (class-aware converter) |
| DLC port & verification | [packed_types_audit_dlc_policy.md](packed_types_audit_dlc_policy.md) | Medium |
| Rust `wad_simulator` | [packed_types_audit_rust_simulator.md](packed_types_audit_rust_simulator.md) | Low–medium |
| Research / diff tooling | [packed_types_audit_tooling.md](packed_types_audit_tooling.md) | Low (read-only) |

## Executive findings

1. **Packed-type vocabulary** is used consistently in audio tooling (`u8x4`, `u16x2`) via `tools/_audio_cross_platform_diff.py` and `tools/_wad_audio_compare.py`; mesh path uses “f16 vec3” / `decl` u16 descriptors, not `u8x4` labels.
2. **Production byte-swap** is centralized in `ucfx_be_to_le.py`; `dlc_port.py` calls `byteswap_ucfx_block(strict)` by default. Blind `_convert_u32_array` exists only behind `--permissive` (policy-compliant).
3. **Fixed (2026-05-28):** `_convert_soundbank_data` periodic u8×4 protection — see [soundbank_u8x4_periodic_swap_root_cause.md](soundbank_u8x4_periodic_swap_root_cause.md). Stride from `(section_off1 - data_start) / sub_count`; relative skip `{12, 20, 44}` per record in sections 1 and 3.
4. **Open high-risk items:** ~~Havok `__data__` u32 sweep~~ (resolved — class-aware converter); `flgs` verifier offset map vs vz_state layout; STRM left BE in `dlc_port` path (by design, swapped in `extract_amazon_dlc` for mesh tools only).

## Cross-reference docs (read-only context)

- `docs/format_reference.md` — UCFX chunk taxonomy  
- `docs/placement_data_format.md` — 42-byte Transform (COMP), vz_state `flgs`  
- `docs/pandemic_audio_system_design.md` — soundbank sections & u8×4 offsets  
- `docs/audio_crash_analysis.md` — periodic u8×4 bug history  

## Suggested verification commands (when PC `vz.wad` available)

```bash
.venv/bin/python3 tools/_wad_audio_compare.py   # regenerate field maps
.venv/bin/python3 tools/_validate_dlc_soundbanks.py output/data/vz-patch.wad
.venv/bin/python3 tools/verify_ucfx_endian.py --wad output/data/vz-patch.wad --report-blind-swaps
.venv/bin/python3 tools/audit_dlc_conversion.py --patch-wad output/data/vz-patch.wad --source-wad "<retail PC vz.wad>"
```
