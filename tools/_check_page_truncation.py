#!/usr/bin/env python3
"""Check for sges truncation: blocks where sges total_size > page allocation."""
import struct
import sys
from pathlib import Path

PAGE_SIZE = 0x8000


def main():
    wad_path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("output/vz-patch.wad")
    raw = wad_path.read_bytes()

    chunks = {}
    for i in range(7):
        off = 0x0C + i * 12
        tag = raw[off:off+4].decode("ascii", errors="replace")
        offset = struct.unpack_from("<I", raw, off+4)[0]
        meta = struct.unpack_from("<I", raw, off+8)[0]
        if tag.strip("\x00"):
            chunks[tag] = (offset, meta)

    indx_off, num_blocks = chunks["INDX"]
    data_off = chunks["DATA"][0]

    pths_off, pths_count = chunks["PTHS"]
    paths = []
    pos = pths_off
    for _ in range(pths_count):
        nul = raw.index(b"\x00", pos)
        paths.append(raw[pos:nul].decode("utf-8", errors="replace"))
        pos = nul + 1

    truncated = []
    overlaps = []

    prev_end_page = None
    for blk_idx in range(num_blocks):
        off = indx_off + blk_idx * 12
        page_idx = struct.unpack_from("<I", raw, off)[0]
        packed = struct.unpack_from("<I", raw, off+4)[0]
        flags_pages = struct.unpack_from("<I", raw, off+8)[0]
        page_count = flags_pages & 0xFFFF

        block_offset = page_idx * PAGE_SIZE
        allocated_bytes = page_count * PAGE_SIZE

        if block_offset + 4 > len(raw):
            continue

        magic = raw[block_offset:block_offset+4]
        if magic == b"sges" and block_offset + 16 <= len(raw):
            major, seg_count = struct.unpack_from("<HH", raw, block_offset + 4)
            total_u = struct.unpack_from("<I", raw, block_offset + 8)[0]
            sges_total = struct.unpack_from("<I", raw, block_offset + 12)[0]
            if sges_total > allocated_bytes:
                name = paths[blk_idx] if blk_idx < len(paths) else "?"
                needed_pages = (sges_total + PAGE_SIZE - 1) // PAGE_SIZE
                truncated.append({
                    "idx": blk_idx,
                    "name": name,
                    "page_idx": page_idx,
                    "pages": page_count,
                    "allocated": allocated_bytes,
                    "sges_total": sges_total,
                    "needed_pages": needed_pages,
                    "deficit": sges_total - allocated_bytes,
                    "major": major,
                    "seg_count": seg_count,
                    "total_u": total_u,
                })

        # Check for page overlaps with previous block
        if prev_end_page is not None and page_idx < prev_end_page:
            overlaps.append((blk_idx, page_idx, prev_end_page))
        prev_end_page = page_idx + page_count

    print(f"Total blocks: {num_blocks}")
    print(f"Truncated blocks (sges_total > allocated): {len(truncated)}")
    print(f"Overlapping blocks: {len(overlaps)}")

    if truncated:
        print(f"\n*** TRUNCATED BLOCKS ***")
        for t in truncated:
            print(f"  Block {t['idx']:5d}: {t['name']}")
            print(f"    INDX pages={t['pages']} ({t['allocated']:,} bytes)")
            print(f"    sges total_size={t['sges_total']:,} bytes "
                  f"(needs {t['needed_pages']} pages)")
            print(f"    sges v{t['major']}, {t['seg_count']} segments, "
                  f"total_u={t['total_u']:,}")
            print(f"    DEFICIT: {t['deficit']:,} bytes "
                  f"({t['needed_pages'] - t['pages']} pages short)")

    if overlaps:
        print(f"\n*** OVERLAPPING BLOCKS ***")
        for blk_idx, page_idx, prev_end in overlaps[:20]:
            name = paths[blk_idx] if blk_idx < len(paths) else "?"
            print(f"  Block {blk_idx}: page_idx={page_idx} but previous block "
                  f"ends at page {prev_end}")


if __name__ == "__main__":
    main()
