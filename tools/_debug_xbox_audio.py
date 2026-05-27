#!/usr/bin/env python3
"""Debug Xbox audio block decompression."""
import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

PAGE_SIZE = 0x8000
_TYPE_SOUNDBANK = 0x9F8BCA10
_TYPE_WAVEBANK = 0xF753F6D0

XBOX_WAD = Path("game-files/Mercenaries 2 World in Flames (NTSCU)[NTSCJ) (JTAGRip)/vz.wad")

def main():
    raw = XBOX_WAD.read_bytes()
    print(f"Xbox WAD: {len(raw):,} bytes")

    # Parse BE FFCS
    chunks = {}
    chunk_count = struct.unpack_from(">I", raw, 8)[0]
    for i in range(min(chunk_count, 7)):
        off = 0x0C + i * 12
        tag = raw[off:off+4][::-1].decode("ascii", errors="replace")
        val = struct.unpack_from(">I", raw, off + 4)[0]
        meta = struct.unpack_from(">I", raw, off + 8)[0]
        chunks[tag] = (val, meta)

    indx_off, indx_count = chunks["INDX"]
    aset_off, aset_count = chunks["ASET"]

    # Find first 5 blocks with audio type
    audio_blocks = []
    for i in range(aset_count):
        o = aset_off + i * 16
        u0, u1, u2 = struct.unpack_from(">III", raw, o)
        u3 = struct.unpack_from("<I", raw, o + 12)[0]
        blk = (u2 >> 16) & 0xFFFF
        if u3 in (6, 21) and blk < indx_count:
            audio_blocks.append((blk, u0, u3))
            if len(audio_blocks) >= 5:
                break

    if not audio_blocks:
        print("No audio blocks with valid indices found!")
        # Show a few audio ASET entries for debugging
        for i in range(aset_count):
            o = aset_off + i * 16
            u0, u1, u2 = struct.unpack_from(">III", raw, o)
            u3 = struct.unpack_from("<I", raw, o + 12)[0]
            blk = (u2 >> 16) & 0xFFFF
            if u3 in (6, 21):
                print(f"  ASET[{i}]: hash=0x{u0:08X} u2=0x{u2:08X} "
                      f"type_id={u3} blk={blk} (max={indx_count})")
                if i > 200:
                    break
        return 1

    for blk_idx, ahash, atype in audio_blocks:
        print(f"\n--- Block {blk_idx} (hash=0x{ahash:08X}, "
              f"type={'soundbank' if atype == 21 else 'wavebank'}) ---")

        # Read INDX entry
        o = indx_off + blk_idx * 12
        page_idx, packed, fp = struct.unpack_from(">III", raw, o)
        page_count = fp & 0xFFFF
        file_off = page_idx * PAGE_SIZE
        block_size = page_count * PAGE_SIZE

        print(f"  INDX: page_idx={page_idx}, pages={page_count}, "
              f"offset=0x{file_off:X}, size={block_size:,}")

        if file_off + block_size > len(raw):
            print(f"  ERROR: Block extends past EOF!")
            continue

        magic = raw[file_off:file_off + 4]
        print(f"  Magic: {magic!r}")

        if magic == b"segs":
            # BE sges
            seg_count = struct.unpack_from(">H", raw, file_off + 6)[0]
            decomp_total = struct.unpack_from(">I", raw, file_off + 8)[0]
            print(f"  segs: seg_count={seg_count}, decomp_total={decomp_total:,}")

            try:
                from x360_dlc_io import decompress_be_sges
                decomp = decompress_be_sges(raw, file_off, block_size)
                print(f"  Decompressed: {len(decomp):,} bytes")

                # Parse entry table (BE)
                entry_count = struct.unpack_from(">I", decomp, 0)[0]
                print(f"  Entry count: {entry_count}")

                for ei in range(min(entry_count, 5)):
                    eoff = 4 + ei * 16
                    eh, eth, eo, esz = struct.unpack_from(">IIII", decomp, eoff)
                    tname = "soundbank" if eth == _TYPE_SOUNDBANK else (
                        "wavebank" if eth == _TYPE_WAVEBANK else f"0x{eth:08X}")
                    print(f"    Entry[{ei}]: hash=0x{eh:08X} type={tname} "
                          f"off={eo} size={esz:,}")
            except Exception as e:
                print(f"  Decompress FAILED: {e}")

        elif magic == b"sges":
            print(f"  LE sges on Xbox?!")
            from sges_decompress import decompress_sges_block
            try:
                decomp = decompress_sges_block(raw, file_off, file_off + block_size)
                print(f"  Decompressed: {len(decomp):,} bytes")
            except Exception as e:
                print(f"  Decompress FAILED: {e}")
        else:
            print(f"  Unknown block magic!")


if __name__ == "__main__":
    sys.exit(main())
