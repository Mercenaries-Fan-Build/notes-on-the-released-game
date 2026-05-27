#!/usr/bin/env python3
"""Quick byte-level comparison of Xbox vs PC WAD headers and PWS files."""
import struct
import sys
from pathlib import Path

XBOX_WAD = Path("game-files/Mercenaries 2 World in Flames (NTSCU)[NTSCJ) (JTAGRip)/vz.wad")
PC_WAD = Path("game-files/pc-game-vz.wad")
XBOX_AUDIOS = Path("game-files/Mercenaries 2 World in Flames (NTSCU)[NTSCJ) (JTAGRip)/audios")


def hexdump(data, offset=0, width=16):
    for i in range(0, len(data), width):
        chunk = data[i:i + width]
        hexstr = " ".join(f"{b:02x}" for b in chunk)
        asciistr = "".join(chr(b) if 32 <= b < 127 else "." for b in chunk)
        print(f"  {offset + i:04x}: {hexstr:<{width*3}s} {asciistr}")


def diff_fields(label, xb, pb):
    """Show all interpretations of a 4-byte diff."""
    xu32 = struct.unpack_from(">I", xb, 0)[0]
    pu32 = struct.unpack_from("<I", pb, 0)[0]
    print(f"  {label}: Xbox={xb.hex()} PC={pb.hex()}")
    if xb == pb:
        print(f"    IDENTICAL (u8x4 or matching value)")
    elif xb == pb[::-1]:
        print(f"    REVERSED (u32 BE={xu32} == LE={pu32})")
    else:
        xu16 = struct.unpack_from(">HH", xb, 0)
        pu16 = struct.unpack_from("<HH", pb, 0)
        print(f"    Xbox BE u32={xu32:10d} (0x{xu32:08X})  PC LE u32={pu32:10d} (0x{pu32:08X})")
        if xu32 == pu32:
            print(f"    -> Values match when read with native endianness!")
        else:
            print(f"    -> VALUES DIFFER: not just an endian swap")
            print(f"    Xbox BE u16=({xu16[0]:5d},{xu16[1]:5d})  "
                  f"PC LE u16=({pu16[0]:5d},{pu16[1]:5d})")


def main():
    print("=" * 70)
    print("PART 1: WAD HEADER DIFFER ANALYSIS")
    print("=" * 70)

    with open(XBOX_WAD, "rb") as f:
        xh = f.read(96)
    with open(PC_WAD, "rb") as f:
        ph = f.read(96)

    for off in range(0, 96, 4):
        xb = xh[off:off + 4]
        pb = ph[off:off + 4]
        if xb != pb and xb != pb[::-1]:
            diff_fields(f"[{off:2d}:{off+4:2d}]", xb, pb)

    # The DIFFER fields are the meta/offset values that genuinely differ
    # between platforms (different file sizes, different block counts)
    print("\n  NOTE: DIFFER fields have different VALUES, not just endianness.")
    print("  Xbox has 11,087 blocks vs PC 11,370 — content differs slightly.")

    print(f"\n{'=' * 70}")
    print("PART 2: FIRST BLOCK COMPARISON (sges vs segs)")
    print("=" * 70)

    # Find first data block
    xbox_indx_off = struct.unpack_from(">I", xh, 0x0C + 4)[0]
    pc_indx_off = struct.unpack_from("<I", ph, 0x0C + 4)[0]

    PAGE = 0x8000
    with open(XBOX_WAD, "rb") as f:
        # Read first INDX entry
        f.seek(xbox_indx_off)
        xi = f.read(12)
        xpi = struct.unpack_from(">I", xi, 0)[0]
        f.seek(xpi * PAGE)
        xblock = f.read(64)

    with open(PC_WAD, "rb") as f:
        f.seek(pc_indx_off)
        pi = f.read(12)
        ppi = struct.unpack_from("<I", pi, 0)[0]
        f.seek(ppi * PAGE)
        pblock = f.read(64)

    print(f"\n  Xbox block 0 magic: {xblock[:4]!r}")
    print(f"  PC block 0 magic:   {pblock[:4]!r}")
    print(f"\n  Xbox block 0 header (32 bytes):")
    hexdump(xblock[:32])
    print(f"\n  PC block 0 header (32 bytes):")
    hexdump(pblock[:32])

    print(f"\n{'=' * 70}")
    print("PART 3: PWS FILE FORMAT ANALYSIS")
    print("=" * 70)

    for pws_name in ["ambience.pws", "music.pws", "vo_stream.english.pws"]:
        pws_path = XBOX_AUDIOS / pws_name
        if not pws_path.exists():
            continue
        with open(pws_path, "rb") as f:
            data = f.read(256)

        print(f"\n  --- {pws_name} ({pws_path.stat().st_size:,} bytes) ---")
        print(f"  First 64 bytes:")
        hexdump(data[:64])

        # Interpret header
        # PWS format: header with version, codec info, etc.
        v0 = struct.unpack_from("<I", data, 0)[0]
        v0_be = struct.unpack_from(">I", data, 0)[0]
        print(f"\n  [0:4] as LE u32: {v0} (0x{v0:08X})")
        print(f"  [0:4] as BE u32: {v0_be} (0x{v0_be:08X})")
        print(f"  [0:2] as LE u16: {struct.unpack_from('<H', data, 0)[0]}")
        print(f"  [2:4] as LE u16: {struct.unpack_from('<H', data, 2)[0]}")
        print(f"  [0:2] as BE u16: {struct.unpack_from('>H', data, 0)[0]}")
        print(f"  [2:4] as BE u16: {struct.unpack_from('>H', data, 2)[0]}")

        # bytes 4-8
        v4 = struct.unpack_from("<I", data, 4)[0]
        v4_be = struct.unpack_from(">I", data, 4)[0]
        print(f"  [4:8] as LE u32: {v4} (0x{v4:08X})")
        print(f"  [4:8] as BE u32: {v4_be} (0x{v4_be:08X})")

        # bytes 8-12
        v8_bytes = data[8:12]
        print(f"  [8:12] raw: {v8_bytes.hex()} u8=({v8_bytes[0]},{v8_bytes[1]},"
              f"{v8_bytes[2]},{v8_bytes[3]})")

    # Check if PC game has audios folder too
    print(f"\n{'=' * 70}")
    print("PART 4: PC AUDIO FILES CHECK")
    print("=" * 70)
    # Common PC game install locations
    pc_data = Path("game-files")
    for p in pc_data.iterdir():
        if p.suffix.lower() == ".pws":
            with open(p, "rb") as f:
                magic = f.read(16)
            print(f"  {p.name}: {magic[:4].hex()} ({p.stat().st_size:,} bytes)")
            hexdump(magic)

    # Also check if the DLC has PWS files
    dlc_pws = list(Path("output").rglob("*.pws")) if Path("output").exists() else []
    if dlc_pws:
        print(f"\n  DLC PWS files in output/:")
        for p in dlc_pws[:5]:
            with open(p, "rb") as f:
                magic = f.read(16)
            print(f"  {p.relative_to('output')}: {magic[:4].hex()} ({p.stat().st_size:,} bytes)")
            hexdump(magic)

    return 0


if __name__ == "__main__":
    sys.exit(main())
