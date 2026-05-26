#!/usr/bin/env python3
"""Check all INDX entries for page collisions, zero-page blocks, and non-sges blocks."""
import struct
import sys
from pathlib import Path

PAGE_SIZE = 0x1000


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

    # Parse paths
    pths_off, pths_count = chunks["PTHS"]
    paths = []
    pos = pths_off
    for _ in range(pths_count):
        nul = raw.index(b"\x00", pos)
        paths.append(raw[pos:nul].decode("utf-8", errors="replace"))
        pos = nul + 1

    page_idx_map = {}
    zero_page_blocks = []
    non_sges_blocks = []
    collisions = []

    for blk_idx in range(num_blocks):
        off = indx_off + blk_idx * 12
        page_idx = struct.unpack_from("<I", raw, off)[0]
        packed = struct.unpack_from("<I", raw, off+4)[0]
        flags_pages = struct.unpack_from("<I", raw, off+8)[0]
        page_count = flags_pages & 0xFFFF
        flags = (flags_pages >> 16) & 0xFFFF
        blk_name = paths[blk_idx] if blk_idx < len(paths) else f"block_{blk_idx}"

        if page_count == 0:
            zero_page_blocks.append((blk_idx, blk_name))
            continue

        if page_idx in page_idx_map:
            other_idx = page_idx_map[page_idx]
            collisions.append((blk_idx, other_idx, page_idx))

        page_idx_map[page_idx] = blk_idx

        block_offset = data_off + page_idx * PAGE_SIZE
        first4 = raw[block_offset:block_offset+4] if block_offset + 4 <= len(raw) else b""
        if first4 != b"sges":
            is_zero = all(b == 0 for b in raw[block_offset:block_offset+16])
            non_sges_blocks.append((blk_idx, blk_name, first4, block_offset,
                                    page_count, is_zero))

    print(f"Total blocks: {num_blocks}")
    print(f"Zero-page blocks: {len(zero_page_blocks)}")
    print(f"Non-sges blocks (pages > 0): {len(non_sges_blocks)}")
    print(f"Page collisions: {len(collisions)}")

    if zero_page_blocks:
        print(f"\nBlocks with 0 pages:")
        for blk_idx, name in zero_page_blocks[:20]:
            print(f"  Block {blk_idx:5d}: {name}")

    if collisions:
        print(f"\nPage index collisions:")
        for blk_idx, other_idx, page_idx in collisions[:20]:
            n1 = paths[blk_idx] if blk_idx < len(paths) else "?"
            n2 = paths[other_idx] if other_idx < len(paths) else "?"
            print(f"  Block {blk_idx} and {other_idx} share page_idx={page_idx}")
            print(f"    {n1}")
            print(f"    {n2}")

    if non_sges_blocks:
        print(f"\nNon-sges blocks:")
        for blk_idx, name, magic, off, pages, is_zero in non_sges_blocks[:30]:
            zstr = "ALL ZEROS" if is_zero else ""
            print(f"  Block {blk_idx:5d}: magic={magic!r} pages={pages} "
                  f"offset=0x{off:08X} {zstr}")
            print(f"           {name}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
