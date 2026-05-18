#!/usr/bin/env python3
"""Compress data into Mercenaries 2 ``sges`` block format.

Inverse of ``sges_decompress.py``. Takes raw decompressed block data and
produces a valid sges-compressed block that the game engine can load.

Format:
  - 16-byte header: ``sges`` magic + u16 major + u16 minor (segment count)
    + u32 total_uncompressed + u32 total_compressed
  - Segment table: ``minor`` entries × 8 bytes (u32 compressed_size, u32 uncompressed_size)
  - Zero-padding to 16-byte alignment
  - Compressed payload: raw deflate segments back-to-back

Usage:
  python3 tools/sges_compress.py input.block.bin output.sges.bin
  python3 tools/sges_compress.py input.block.bin output.sges.bin --segment-size 65536
  python3 tools/sges_compress.py input.block.bin output.sges.bin --verify
"""

from __future__ import annotations

import argparse
import math
import struct
import sys
import zlib
from pathlib import Path

SGES_MAGIC = b"sges"
DEFAULT_SEGMENT_SIZE = 65536


def sges_data_offset(num_segments: int) -> int:
    """Byte offset where compressed payload starts (16-byte aligned)."""
    return math.ceil((16 + num_segments * 8) / 16) * 16


def compress_segment(data: bytes, level: int = 6) -> bytes:
    """Compress a single segment using raw deflate (no header/trailer)."""
    obj = zlib.compressobj(level, zlib.DEFLATED, -15)
    compressed = obj.compress(data)
    compressed += obj.flush()
    return compressed


def compress_sges(
    uncompressed: bytes,
    *,
    segment_size: int = DEFAULT_SEGMENT_SIZE,
    level: int = 6,
    major: int = 1,
) -> bytes:
    """Compress raw block data into an sges block.

    Args:
        uncompressed: Raw decompressed block data.
        segment_size: Max uncompressed bytes per segment.
        level: zlib compression level (1-9, default 6).
        major: sges major version (observed as 1 in game data).

    Returns:
        Complete sges block bytes ready for WAD injection.
    """
    total_u = len(uncompressed)
    if total_u == 0:
        raise ValueError("Cannot compress empty data")

    segments: list[tuple[bytes, int]] = []
    offset = 0
    while offset < total_u:
        chunk = uncompressed[offset:offset + segment_size]
        compressed = compress_segment(chunk, level)
        segments.append((compressed, len(chunk)))
        offset += len(chunk)

    num_segments = len(segments)
    data_start = sges_data_offset(num_segments)

    total_c = sum(len(c) for c, _ in segments)

    header = struct.pack("<4sHHII",
                         SGES_MAGIC,
                         major,
                         num_segments,
                         total_u,
                         total_c)

    seg_table = b""
    for compressed_data, uncompressed_size in segments:
        seg_table += struct.pack("<II", len(compressed_data), uncompressed_size)

    header_and_table = header + seg_table
    padding_needed = data_start - len(header_and_table)
    padded_header = header_and_table + b"\x00" * padding_needed

    payload = b"".join(c for c, _ in segments)

    return padded_header + payload


def verify_roundtrip(original: bytes, compressed: bytes) -> bool:
    """Verify that an sges block decompresses back to the original data."""
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    from sges_decompress import decompress_sges_block

    decompressed = decompress_sges_block(compressed, 0, len(compressed))
    if decompressed == original:
        print(f"  Roundtrip OK: {len(original)} bytes -> {len(compressed)} bytes -> {len(decompressed)} bytes")
        return True
    else:
        print(f"  Roundtrip FAILED: original {len(original)} bytes, decompressed {len(decompressed)} bytes", file=sys.stderr)
        if len(decompressed) != len(original):
            print(f"  Size mismatch: expected {len(original)}, got {len(decompressed)}", file=sys.stderr)
        else:
            diffs = sum(1 for a, b in zip(original, decompressed) if a != b)
            print(f"  Content mismatch: {diffs} differing bytes", file=sys.stderr)
        return False


def main() -> int:
    ap = argparse.ArgumentParser(description="Compress data into Mercenaries 2 sges block format")
    ap.add_argument("input", type=Path, help="Decompressed .block.bin file")
    ap.add_argument("output", type=Path, help="Output .sges.bin file")
    ap.add_argument("--segment-size", type=int, default=DEFAULT_SEGMENT_SIZE,
                    help=f"Max uncompressed bytes per segment (default {DEFAULT_SEGMENT_SIZE})")
    ap.add_argument("--level", type=int, default=6,
                    help="Compression level 1-9 (default 6)")
    ap.add_argument("--major", type=int, default=1,
                    help="sges major version (default 1)")
    ap.add_argument("--verify", action="store_true",
                    help="Verify round-trip after compression")
    ap.add_argument("--info", action="store_true",
                    help="Print sges header info for an existing file and exit")
    args = ap.parse_args()

    if args.info:
        data = args.input.read_bytes()
        if data[:4] != SGES_MAGIC:
            print("Not an sges file", file=sys.stderr)
            return 1
        major, minor = struct.unpack_from("<HH", data, 4)
        total_u, total_c = struct.unpack_from("<II", data, 8)
        data_off = sges_data_offset(minor)
        print(f"sges v{major}.{minor}")
        print(f"  Segments:     {minor}")
        print(f"  Uncompressed: {total_u:,} bytes")
        print(f"  Compressed:   {total_c:,} bytes")
        print(f"  Ratio:        {total_c/total_u*100:.1f}%")
        print(f"  Data offset:  0x{data_off:x}")
        for i in range(minor):
            off = 16 + i * 8
            cs, us = struct.unpack_from("<II", data, off)
            print(f"  Segment {i}: compressed={cs:,} uncompressed={us:,}")
        return 0

    if not args.input.is_file():
        print(f"Input file not found: {args.input}", file=sys.stderr)
        return 1

    uncompressed = args.input.read_bytes()
    print(f"Input: {args.input} ({len(uncompressed):,} bytes)")

    compressed = compress_sges(
        uncompressed,
        segment_size=args.segment_size,
        level=args.level,
        major=args.major,
    )

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_bytes(compressed)

    ratio = len(compressed) / len(uncompressed) * 100
    major, minor = struct.unpack_from("<HH", compressed, 4)
    print(f"Output: {args.output} ({len(compressed):,} bytes, {minor} segments, {ratio:.1f}% ratio)")

    if args.verify:
        if not verify_roundtrip(uncompressed, compressed):
            return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
