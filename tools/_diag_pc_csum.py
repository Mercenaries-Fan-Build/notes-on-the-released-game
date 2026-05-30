#!/usr/bin/env python3
"""Check CSUM convention in PC WAD."""
from __future__ import annotations

import io
import mmap
import struct
import sys
from pathlib import Path

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
sys.path.insert(0, str(Path(__file__).parent))

from sges_decompress import decompress_sges_block
from wad_patcher import find_data_chunk, get_block_boundaries


def main():
    pc_wad = Path("game-files/pc-game-vz.wad")
    dc = find_data_chunk(pc_wad)
    with open(pc_wad, "rb") as f:
        mm = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)
        boundaries = get_block_boundaries(mm, dc.offset, dc.size)

        # Check first 3 blocks
        for blk_idx in range(min(3, len(boundaries))):
            s, e = boundaries[blk_idx]
            try:
                data = decompress_sges_block(mm, s, e)
            except Exception:
                continue

            entry_count = struct.unpack_from("<I", data, 0)[0]
            header_size = 4 + entry_count * 16
            print(f"Block {blk_idx}: entry_count={entry_count} total={len(data)}")

            offset = header_size
            csum_inside = 0
            csum_after = 0
            csum_none = 0
            for i in range(entry_count):
                eoff = 4 + i * 16
                chunk_size = struct.unpack_from("<I", data, eoff + 12)[0]

                container = data[offset:offset + chunk_size]
                after = data[offset + chunk_size:offset + chunk_size + 8] if offset + chunk_size + 8 <= len(data) else b""

                has_after = after[:4] in (b"CSUM", b"MUSC")
                has_inside = container[-8:-4] in (b"CSUM", b"MUSC") if len(container) >= 8 else False

                if has_after and not has_inside:
                    csum_after += 1
                    offset = offset + chunk_size + 8
                elif has_inside and not has_after:
                    csum_inside += 1
                    offset = offset + chunk_size
                elif has_inside and has_after:
                    # Both - check which makes structural sense
                    if i < 3:
                        print(f"  Entry {i}: chunk_size={chunk_size} BOTH inside+after")
                    # Try CSUM-after convention: advance by chunk_size + 8
                    csum_after += 1
                    offset = offset + chunk_size + 8
                else:
                    csum_none += 1
                    offset = offset + chunk_size

            remaining = len(data) - offset
            print(f"  CSUM: inside={csum_inside} after={csum_after} none={csum_none} remaining={remaining}")
            print()

        mm.close()


if __name__ == "__main__":
    main()
