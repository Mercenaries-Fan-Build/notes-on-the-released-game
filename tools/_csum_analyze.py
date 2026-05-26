#!/usr/bin/env python3
"""One-off: analyze CSUM field in vz.wad FFCS header."""
from __future__ import annotations

import struct
import sys
from collections import Counter
from pathlib import Path

def main() -> int:
    wad_path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("game-files/vz.wad")
    raw = wad_path.read_bytes()

    chunks = {}
    for i in range(5):
        off = 0x0C + i * 12
        tag = raw[off:off + 4].decode("ascii")
        offset, meta = struct.unpack_from("<II", raw, off + 4)
        chunks[tag] = (offset, meta)

    aset_off, aset_count = chunks["ASET"]
    csum_off, csum_meta = chunks["CSUM"]
    indx_off, indx_count = chunks["INDX"]

    print(f"ASET: offset=0x{aset_off:08X}, count={aset_count}")
    print(f"CSUM: offset=0x{csum_off:08X}, meta={csum_meta}")
    print(f"INDX: offset=0x{indx_off:08X}, count={indx_count}")

    # Parse INDX entries to find block paths
    pths_off, pths_count = chunks["PTHS"]
    pths_region = raw[pths_off:]
    paths = []
    pos = 0
    for _ in range(pths_count):
        nul = pths_region.find(b"\x00", pos)
        if nul < 0:
            break
        paths.append(pths_region[pos:nul].decode("utf-8", errors="replace"))
        pos = nul + 1

    # Count ASET entries per block_index
    block_counts: Counter[int] = Counter()
    secref_stats: Counter[str] = Counter()
    entries_by_block: dict[int, list] = {}

    for i in range(aset_count):
        off = aset_off + i * 16
        u0, u1, u2, u3 = struct.unpack_from("<IIII", raw, off)
        blk_idx = (u2 >> 16) & 0xFFFF
        block_counts[blk_idx] += 1
        entries_by_block.setdefault(blk_idx, []).append((u0, u1, u2, u3))
        if u1 == 0xFFFFFFFF:
            secref_stats["sentinel"] += 1
        else:
            secref_stats["has_ref"] += 1

    # Check if any single block has exactly csum_meta entries
    print(f"\nBlock(s) with exactly {csum_meta} entries:")
    for blk, cnt in block_counts.most_common():
        if cnt == csum_meta:
            name = paths[blk] if blk < len(paths) else f"block_{blk}"
            print(f"  Block {blk} ({name}): {cnt} entries")

    # Top blocks by ASET entry count
    print(f"\nTop 15 blocks by ASET entry count:")
    for blk, cnt in block_counts.most_common(15):
        name = paths[blk] if blk < len(paths) else f"block_{blk}"
        print(f"  Block {blk:5d} ({name}): {cnt} entries")

    # Cumulative: is csum_meta the sum of top N blocks?
    running = 0
    print(f"\nCumulative entry count (checking if csum_meta={csum_meta} is a running sum):")
    for rank, (blk, cnt) in enumerate(block_counts.most_common(20)):
        running += cnt
        name = paths[blk] if blk < len(paths) else f"block_{blk}"
        marker = " <-- MATCH" if running == csum_meta else ""
        print(f"  Top {rank + 1}: block {blk:5d} ({name}): +{cnt} = {running}{marker}")

    print(f"\nTotal unique blocks referenced: {len(block_counts)}")
    print(f"Secondary ref stats: sentinel={secref_stats['sentinel']}, has_ref={secref_stats['has_ref']}")

    # Data at CSUM offset
    print(f"\n=== Data at CSUM offset 0x{csum_off:08X} ===")
    if csum_off < len(raw) and csum_off > 0:
        sample = raw[csum_off:csum_off + 64]
        for i in range(0, 64, 16):
            end = min(16, len(sample) - i)
            hex_str = " ".join(f"{sample[i + j]:02X}" for j in range(end))
            ascii_str = "".join(
                chr(sample[i + j]) if 32 <= sample[i + j] < 127 else "."
                for j in range(end)
            )
            print(f"  {csum_off + i:08X}: {hex_str}  |{ascii_str}|")
        magic = raw[csum_off:csum_off + 4]
        print(f"  First 4 bytes: {magic.hex()}")
        # Check if it's an sges header
        if magic == b"sges":
            print("  -> This is an sges compressed block boundary!")
    elif csum_off == 0:
        print("  CSUM offset is 0 (pointing at FFCS header)")
    else:
        print(f"  Offset {csum_off} beyond file size {len(raw)}")

    # Check: does CSUM.offset correspond to a page boundary?
    page_size = 0x8000
    data_off = chunks["DATA"][0]
    if csum_off >= data_off:
        page_in_data = (csum_off - data_off) // page_size
        remainder = (csum_off - data_off) % page_size
        print(f"  Within DATA: page {page_in_data}, offset within page = 0x{remainder:X}")
        if remainder == 0:
            print("  -> Page-aligned! This is a block boundary.")
        else:
            print(f"  -> NOT page-aligned (off by 0x{remainder:X} bytes)")

    # Check: is csum_off the CRC of some known region?
    import zlib
    # CRC of INDX data
    indx_data = raw[indx_off:indx_off + indx_count * 12]
    crc_indx = zlib.crc32(indx_data) & 0xFFFFFFFF
    print(f"\n=== CRC checks ===")
    print(f"  CRC32 of INDX data: 0x{crc_indx:08X} (CSUM offset: 0x{csum_off:08X}) {'MATCH!' if crc_indx == csum_off else 'no match'}")

    # CRC of ASET data
    aset_data = raw[aset_off:aset_off + aset_count * 16]
    crc_aset = zlib.crc32(aset_data) & 0xFFFFFFFF
    print(f"  CRC32 of ASET data: 0x{crc_aset:08X} {'MATCH!' if crc_aset == csum_off else 'no match'}")

    # CRC of INDX+ASET
    combined = indx_data + aset_data
    crc_combined = zlib.crc32(combined) & 0xFFFFFFFF
    print(f"  CRC32 of INDX+ASET: 0x{crc_combined:08X} {'MATCH!' if crc_combined == csum_off else 'no match'}")

    # CRC of PTHS
    pths_data = raw[pths_off:pths_off + len(b"".join(p.encode() + b"\x00" for p in paths))]
    crc_pths = zlib.crc32(pths_data) & 0xFFFFFFFF
    print(f"  CRC32 of PTHS data: 0x{crc_pths:08X} {'MATCH!' if crc_pths == csum_off else 'no match'}")

    # Try Mercs2-style CRC (init=0xFFFFFFFF, no final XOR)
    crc_m2_indx = (zlib.crc32(indx_data, 0xFFFFFFFF) ^ 0xFFFFFFFF) & 0xFFFFFFFF
    print(f"  Mercs2 CRC of INDX: 0x{crc_m2_indx:08X} {'MATCH!' if crc_m2_indx == csum_off else 'no match'}")

    crc_m2_aset = (zlib.crc32(aset_data, 0xFFFFFFFF) ^ 0xFFFFFFFF) & 0xFFFFFFFF
    print(f"  Mercs2 CRC of ASET: 0x{crc_m2_aset:08X} {'MATCH!' if crc_m2_aset == csum_off else 'no match'}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
