#!/usr/bin/env python3
"""Test whether per-UCFX CSUM trailers are validated at runtime.

This script modifies a CSUM trailer in a decompressed block, recompresses it,
patches it into a WAD copy, and reports what to test.

Workflow:
  1. Read the decompressed scripts_vz block
  2. Find the first UCFX CSUM trailer
  3. Zero it out (or set to 0xDEADBEEF)
  4. Recompress with sges_compress
  5. Patch into a copy of vz.wad using wad_patcher
  6. Print instructions for manual game testing

Usage:
  python3 tools/csum_enforcement_test.py \\
    --scripts-block output/extracted/batch_vz/blocks/03197_blocks__VZ__scripts_vz_P000_Q3.block.bin \\
    --wad "data/vz.wad" \\
    --output-wad "data/vz_test.wad" \\
    --block-index 3197
"""

from __future__ import annotations

import argparse
import struct
import sys
from pathlib import Path

CSUM_TAG = b"CSUM"


def find_csum_trailers(data: bytes) -> list[tuple[int, int]]:
    """Find all CSUM trailer positions in decompressed block data.

    Returns list of (offset_of_tag, u32_value) pairs.
    """
    trailers = []
    pos = 0
    while True:
        idx = data.find(CSUM_TAG, pos)
        if idx < 0 or idx + 8 > len(data):
            break
        val = struct.unpack_from("<I", data, idx + 4)[0]
        trailers.append((idx, val))
        pos = idx + 4
    return trailers


def modify_csum(data: bytearray, trailer_index: int, new_value: int) -> tuple[int, int]:
    """Modify a CSUM trailer value. Returns (offset, old_value)."""
    trailers = find_csum_trailers(bytes(data))
    if trailer_index >= len(trailers):
        raise IndexError(f"Trailer index {trailer_index} out of range (0..{len(trailers)-1})")

    offset, old_value = trailers[trailer_index]
    struct.pack_into("<I", data, offset + 4, new_value)
    return offset, old_value


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Prepare CSUM enforcement test (modify trailer + repack)"
    )
    ap.add_argument("--scripts-block", type=Path, required=True,
                    help="Decompressed scripts_vz block file")
    ap.add_argument("--wad", type=Path, required=True,
                    help="Original vz.wad file")
    ap.add_argument("--output-wad", type=Path, required=True,
                    help="Output patched WAD file")
    ap.add_argument("--block-index", type=int, required=True,
                    help="Block index of scripts_vz in the WAD (e.g. 3197)")
    ap.add_argument("--trailer-index", type=int, default=0,
                    help="Which CSUM trailer to modify (default: 0 = first chunk)")
    ap.add_argument("--new-value", type=lambda x: int(x, 0), default=0x00000000,
                    help="New CSUM value (default: 0x00000000)")
    ap.add_argument("--segment-size", type=int, default=65536,
                    help="sges segment size for recompression")
    args = ap.parse_args()

    if not args.scripts_block.is_file():
        print(f"Block file not found: {args.scripts_block}", file=sys.stderr)
        return 1
    if not args.wad.is_file():
        print(f"WAD file not found: {args.wad}", file=sys.stderr)
        return 1

    data = bytearray(args.scripts_block.read_bytes())
    print(f"Block: {args.scripts_block} ({len(data):,} bytes)")

    trailers = find_csum_trailers(bytes(data))
    print(f"CSUM trailers found: {len(trailers)}")
    for i, (off, val) in enumerate(trailers[:5]):
        print(f"  [{i}] offset=0x{off:x} value=0x{val:08x}")
    if len(trailers) > 5:
        print(f"  ... and {len(trailers) - 5} more")
    print()

    offset, old_value = modify_csum(data, args.trailer_index, args.new_value)
    print(f"Modified trailer [{args.trailer_index}]:")
    print(f"  Offset: 0x{offset:x}")
    print(f"  Old value: 0x{old_value:08x}")
    print(f"  New value: 0x{args.new_value:08x}")
    print()

    sys.path.insert(0, str(Path(__file__).resolve().parent))
    from sges_compress import compress_sges
    from wad_patcher import patch_inplace

    modified_block = bytes(data)
    print("Compressing modified block...")
    compressed = compress_sges(modified_block, segment_size=args.segment_size)
    ratio = len(compressed) / len(modified_block) * 100
    print(f"Compressed: {len(compressed):,} bytes ({ratio:.1f}%)")
    print()

    temp_sges = args.output_wad.parent / f"_temp_modified.sges.bin"
    temp_sges.write_bytes(compressed)

    print(f"Patching WAD at block index {args.block_index}...")
    result = patch_inplace(
        args.wad, args.output_wad, args.block_index, compressed
    )
    print(f"Strategy: {result['strategy']}")
    print(f"Output: {result['output']}")
    print()

    temp_sges.unlink(missing_ok=True)

    print("=" * 60)
    print("CSUM ENFORCEMENT TEST READY")
    print("=" * 60)
    print()
    print(f"1. Back up your original vz.wad")
    print(f"2. Replace vz.wad with: {args.output_wad}")
    print(f"3. Launch Mercenaries 2")
    print(f"4. Load a save that triggers scripts_vz chunk [{args.trailer_index}]")
    print()
    print(f"Expected outcomes:")
    print(f"  A) Game loads normally -> CSUM is NOT enforced at runtime")
    print(f"     (CSUMs are build-pipeline artifacts only)")
    print(f"  B) Game crashes or shows 'tampered' error (GL:5533)")
    print(f"     -> CSUM IS enforced; need to reverse the algorithm")
    print(f"  C) Game loads but the script doesn't execute")
    print(f"     -> CSUM may be used as a lookup key, not just integrity")
    print()
    print(f"If outcome A: proceed with Lua modding (ignore CSUMs)")
    print(f"If outcome B: run SecuROM unpacker + disassemble CSUM logic")
    print(f"If outcome C: investigate CSUM as content-addressable key")

    return 0


if __name__ == "__main__":
    sys.exit(main())
