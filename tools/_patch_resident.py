#!/usr/bin/env python3
"""Find the resident block and its ASET entry count in a patch WAD."""
from __future__ import annotations

import struct
import sys
from collections import Counter
from pathlib import Path


def main() -> int:
    wad_path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("output/vz-patch.wad")
    raw = wad_path.read_bytes()

    chunks = {}
    for i in range(5):
        off = 0x0C + i * 12
        tag = raw[off:off + 4].decode("ascii")
        offset, meta = struct.unpack_from("<II", raw, off + 4)
        chunks[tag] = (offset, meta)

    indx_off, indx_count = chunks["INDX"]
    aset_off, aset_count = chunks["ASET"]
    pths_off, pths_count = chunks["PTHS"]

    # Parse PTHS
    pths_region = raw[pths_off:]
    paths: list[str] = []
    pos = 0
    for _ in range(pths_count):
        nul = pths_region.find(b"\x00", pos)
        if nul < 0:
            break
        paths.append(pths_region[pos:nul].decode("utf-8", errors="replace"))
        pos = nul + 1

    # Count ASET entries per block
    block_counts: Counter[int] = Counter()
    for i in range(aset_count):
        off = aset_off + i * 16
        u0, u1, u2, u3 = struct.unpack_from("<IIII", raw, off)
        blk_idx = (u2 >> 16) & 0xFFFF
        block_counts[blk_idx] += 1

    print(f"Patch WAD: {wad_path}")
    print(f"Total blocks: {indx_count}, Total ASET entries: {aset_count}")
    print(f"Current CSUM meta: {chunks['CSUM'][1]}")
    print()

    # Top blocks by ASET entry count
    print("Top 25 blocks by ASET entry count:")
    for blk, cnt in block_counts.most_common(25):
        name = paths[blk] if blk < len(paths) else f"block_{blk}"
        is_resident = "resident" in name.lower()
        marker = " <-- RESIDENT" if is_resident else ""
        print(f"  Block {blk:5d}: {cnt:5d} entries  ({name}){marker}")

    # Find all resident-like blocks
    print()
    print("Blocks containing 'resident' in path:")
    for i, p in enumerate(paths):
        if "resident" in p.lower():
            cnt = block_counts.get(i, 0)
            print(f"  Block {i:5d}: {cnt:5d} ASET entries  ({p})")

    # Find scripts_vz
    print()
    print("Blocks containing 'scripts' in path:")
    for i, p in enumerate(paths):
        if "scripts" in p.lower() or "script" in p.lower():
            cnt = block_counts.get(i, 0)
            print(f"  Block {i:5d}: {cnt:5d} ASET entries  ({p})")

    return 0


if __name__ == "__main__":
    sys.exit(main())
