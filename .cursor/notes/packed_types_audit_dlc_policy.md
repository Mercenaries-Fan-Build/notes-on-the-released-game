# Audit: DLC port, verification, policy cross-check

## Summary

`dlc_port.py` orchestrates decompress → `byteswap_ucfx_block` → recompress. Supporting tools audit strict vs permissive exposure and binary identity vs retail PC.

## Findings

| Path | Symbol / field | Declared type | Swap treatment | Status | Action |
|------|----------------|---------------|----------------|--------|--------|
| `dlc_port.py` | `byteswap_ucfx_block` | UCFX block | `permissive=args.permissive` default False | VERIFIED | |
| `dlc_port.py` | `--permissive` help | — | Documents testing-only blind u32 | VERIFIED | Matches AGENTS.md |
| `dlc_port.py` | `packed_field` recompute | u32 bitfield | `(tier<<24)\|pages` LE | VERIFIED | Not vector packed |
| `dlc_port.py` | `packed_block_ref` sanitize | u32 | high16 block, low16 sub_entry | VERIFIED | `verify_wad_overlay.py` |
| `audit_dlc_conversion.py` | byte identity | — | No swap; compares patch vs retail | VERIFIED | Gold standard |
| `verify_ucfx_endian.py` | `--report-blind-swaps` | — | strict raise vs permissive count | VERIFIED | Trend `fallback_u32_count` → 0 |
| `verify_ucfx_endian.py` | `_check_flgs` / vertex | f32 heuristic | See placements note | SUSPECT | |
| `extract_amazon_dlc.py` | STRM/IBUF extra swap | u16 bodies | Post-pass for mesh | VERIFIED | |
| `ps3_wad_header_crack.py` | `bswap32_256` | probe | Reverses first 256 B as experiment | VERIFIED OK | Not production port path |

## Deleted / forbidden patterns

- `port_xbox_dlc.py`, `dlc_port_x360_to_pc.py` — removed per AGENTS.md; **no reintroduction** of tag-scanning u32 sweeps.

## Open questions

1. Run `audit_dlc_conversion` after soundbank stride fix — any new MISMATCH on shared soundbank hashes?
2. List remaining `UnhandledByteSwapError` types from last `dlc_port` run log.
