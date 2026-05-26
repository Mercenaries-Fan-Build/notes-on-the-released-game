#!/usr/bin/env python3
"""Check what's at the positions of non-sges audio blocks."""
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

    bad_blocks = [203, 204, 343, 347, 438, 470, 723, 738, 870, 936, 971]

    for blk_idx in bad_blocks:
        off = indx_off + blk_idx * 12
        page_idx = struct.unpack_from("<I", raw, off)[0]
        packed = struct.unpack_from("<I", raw, off+4)[0]
        flags_pages = struct.unpack_from("<I", raw, off+8)[0]
        page_count = flags_pages & 0xFFFF
        flags = (flags_pages >> 16) & 0xFFFF

        block_offset = page_idx * PAGE_SIZE
        block_size = page_count * PAGE_SIZE
        blk_name = paths[blk_idx] if blk_idx < len(paths) else "?"

        first_32 = raw[block_offset:block_offset+32]
        is_zero = all(b == 0 for b in raw[block_offset:block_offset+block_size])
        nonzero_bytes = sum(1 for b in raw[block_offset:block_offset+block_size] if b != 0)

        print(f"Block {blk_idx:5d}: {blk_name}")
        print(f"  page_idx={page_idx} packed={packed} pages={page_count} "
              f"flags=0x{flags:04X}")
        print(f"  file_offset=0x{block_offset:08X} size={block_size:,}")
        print(f"  first 32 bytes: {first_32.hex()}")
        print(f"  is_all_zero={is_zero} nonzero_bytes={nonzero_bytes}/{block_size}")

        # Check if it's beyond the WAD file
        if block_offset + block_size > len(raw):
            print(f"  *** EXTENDS BEYOND WAD FILE ({len(raw):,} bytes)")

        # Try to interpret first 4 bytes as sges total_size
        if first_32[:4] == b"sges":
            total = struct.unpack_from("<I", first_32, 4)[0]
            print(f"  sges total_size={total:,}")
        else:
            # Check for uncompressed UCFX (block_count + entry_table + UCFX)
            maybe_count = struct.unpack_from("<I", first_32, 0)[0]
            if maybe_count > 0 and maybe_count < 5000:
                header_end = 4 + maybe_count * 16
                if header_end + 4 <= block_size:
                    ucfx_pos = raw[block_offset + header_end:block_offset + header_end + 4]
                    print(f"  Maybe uncompressed: count={maybe_count}, "
                          f"tag@{header_end}={ucfx_pos!r}")

        print()

    # Also check: are the good blocks (166, 779, 1013) actually finding audio entries?
    print("=" * 60)
    print("Checking blocks that DO decompress for audio content:")
    good_blocks = [166, 779, 1013]
    from sges_decompress import decompress_sges_block

    _TYPE_WAVEBANK = 0xF753F6D0
    _TYPE_SOUNDBANK = 0x9F8BCA10
    _TYPE_UNKNOWN_E5 = 0xE5273C14

    for blk_idx in good_blocks:
        off = indx_off + blk_idx * 12
        page_idx = struct.unpack_from("<I", raw, off)[0]
        flags_pages = struct.unpack_from("<I", raw, off+8)[0]
        page_count = flags_pages & 0xFFFF

        block_offset = page_idx * PAGE_SIZE
        block_size = page_count * PAGE_SIZE
        compressed = raw[block_offset:block_offset + block_size]

        try:
            decomp = decompress_sges_block(compressed, 0, len(compressed))
        except Exception as e:
            print(f"Block {blk_idx}: decompress failed: {e}")
            continue

        entry_count = struct.unpack_from("<I", decomp, 0)[0]
        print(f"\nBlock {blk_idx} ({paths[blk_idx]}): {entry_count} entries")
        for i in range(entry_count):
            eoff = 4 + i * 16
            h, th, o, sz = struct.unpack_from("<IIII", decomp, eoff)
            is_audio = th in {_TYPE_WAVEBANK, _TYPE_SOUNDBANK, _TYPE_UNKNOWN_E5}
            marker = " <-- AUDIO" if is_audio else ""
            print(f"  Entry {i}: hash=0x{h:08X} type=0x{th:08X} size={sz}{marker}")


if __name__ == "__main__":
    main()
