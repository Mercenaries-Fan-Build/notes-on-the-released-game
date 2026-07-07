# schm Field Type Code Mapping

Reverse-engineered from DLC block 18 (`dlc01_dlccon004_roads`) ECS_NODE COMP groups.
Cross-referenced against documented component field layouts.

## Type Code → Width Mapping

| Type Code | Width (bytes) | Swap Unit | Semantic | Evidence |
|-----------|---------------|-----------|----------|----------|
| 1 | sub-byte (bit) | none | bool/flag | HibernationControl: 2 fields at same byte offset 5 |
| 2 | 1 | none | u8 | HibernationControl: fields at sequential byte offsets 2,3,4 |
| 4 | 2 | u16 | u16 | HibernationControl @0 (next field at +2); Transform fields 2 apart |
| 5 | 4 | f32 | f32 | Transform @32 (next at 36) |
| 6 | 4 | u32 | hash/u32 | ModelName (single u32 hash); DestructionLink; Road; RoadIntersection |
| 7 | 4 | u32 | u32 (ref?) | DestructionLink @8 (next at 12) |
| 8 | 4 | u32 | string ref | Name @0 (next at 4) |
| 9 | 4 | u32 | u32 (flags?) | DestructionLink @4 (next at 8) |
| 10 | 12 | 3×f32 | Vec3 | Road @16 (next at 28); RoadIntersection @28 (next at 40) |
| 11 | 32 | 8×f32 | Transform blob | Transform @0 (next at 32); pos+pad+quat = 32 bytes |

## Offset Field Encoding

The `field_offset` u32 in schm entries is packed, and **which half holds the byte offset depends on
the container's endianness** (the word is byte-swapped between builds):
- **Retail PC (little-endian schm):** `byte_offset = offset_word & 0xFFFF` (**LOW** 16 bits);
  `bit_index = (offset_word >> 16) & 0xFF` selects the bit for sub-byte type-1 fields; the remaining
  high byte is metadata.
- **Xbox / BE-converted (big-endian schm):** `byte_offset = offset_word >> 16` (**HIGH** 16 bits).

> ⚠ **CORRECTION (2026-07, Wave-0 E1).** Earlier revisions stated `>> 16` unconditionally. That was
> derived from **converted DLC data carrying a converter bug** (byte-offset left in the high 16).
> Verified against **real retail vz.wad LE bytes**, the retail rule is the LOW 16 bits — Transform
> 32,36,38…50 · HibernationControl 0,2,3,4,5,5 · Road 0,4,8,12,16,28 · RoadIntersection 0,4…120.
> Authoritative endian-aware implementation: `mercs2_formats::schema::from_schm_body`. See also
> `spatial_hash_crash_analysis.md`.

## Byte-Swap Rules (derived)

For the converter, swap decisions are:
- **Types 1, 2**: NO swap (≤1 byte)
- **Type 4**: swap 2 bytes (u16)
- **Types 5, 6, 7, 8, 9**: swap 4 bytes (u32/f32)
- **Type 10**: swap 4 bytes × 3 (Vec3 = three f32s)
- **Type 11**: swap 4 bytes × 8 (8 f32s — pos+pad+quat blob)

## Validation

| Component | Stride | Type codes | Sum | Match? |
|-----------|--------|-----------|-----|--------|
| ModelName | 4 | 1×type6(4) | 4 | ✓ |
| DestructionLink | 16 | 4×type6/7/9(4) | 16 | ✓ |
| Road | 40 | 4×type6(4) + 2×type10(12) | 16+24=40 | ✓ |
| RoadIntersection | 124 | 7×type6(4) + 6×type10(12) + 6×type6(4) | 28+72+24=124 | ✓ |
| HibernationControl | 6 | type4(2) + 3×type2(1) + 2×type1(0) = 5+1byte | 6 | ✓ |
| Transform | 52 (schm) | type11(32) + type5(4) + 8×type4(2) | 32+4+16=52 | ✓ (schm stride; runtime is 38) |

## DLC Block schm Presence

**All 7 COMP groups in DLC block 18 have schm.** The "DLC blocks might lack schm" concern is NOT confirmed — DLC blocks DO have full schema data.

## Xbox 360 sges Format

- Magic: "segs" (reversed "sges")
- **Header: 32 bytes** (vs PC's 16 bytes)
- Decompressed size: BE u32 at +8
- Compressed data: starts at offset +32 (raw deflate, same algorithm as PC)
- FFCS header: same structure as PC but with BE u32s and reversed tags (SCFF, XDNI, ATAD, etc.)
- INDX entries: 12 bytes each (same as PC), all fields BE

## Pandemic Lua Flag

Not yet confirmed from data — no Lua bytecode found in first 20 Xbox blocks scanned.
Will investigate during Phase 3 script converter implementation using DLC-specific blocks.
