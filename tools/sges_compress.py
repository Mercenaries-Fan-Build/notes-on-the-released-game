#!/usr/bin/env python3
"""Compress data into Mercenaries 2 ``sges`` block format.

Inverse of ``sges_decompress.py``. Takes raw decompressed block data and
produces a valid sges-compressed block that the game engine can load.

Format (version 4, as used by the retail/demo engine):
  - 16-byte header: ``sges`` magic + u16 major + u16 segment_count
    + u32 total_uncompressed + u32 total_compressed
  - Segment table: segment_count × 8 bytes per entry (starts at offset 0x10):
      u16 compressed_size
      u16 uncompressed_size (0 means default = 65536 bytes; actual size for last segment)
      u32 offset_with_flag  (bit 0 = compression flag; bits 1-31 = byte offset within block.
                             Engine masks with 0xFFFFFFFE to get actual offset.
                             All offsets are 16-byte aligned so bit 0 is always available.)
  - Compressed payload: raw deflate segments, each starting at a 16-byte aligned offset
    within the block, with zero-padding between segments for alignment.
  - total_compressed = align_to_16(last_segment_offset + last_segment_compressed_size)
    i.e., the total block size rounded up to a 16-byte boundary.

Usage:
  python3 tools/sges_compress.py input.block.bin output.sges.bin
  python3 tools/sges_compress.py input.block.bin output.sges.bin --segment-size 65536
  python3 tools/sges_compress.py input.block.bin output.sges.bin --verify
"""

from __future__ import annotations

import argparse
import struct
import sys
import zlib
from pathlib import Path

SGES_MAGIC = b"sges"
DEFAULT_SEGMENT_SIZE = 65536


def align16(x: int) -> int:
    """Round x up to the next 16-byte boundary."""
    return ((x + 15) // 16) * 16


def sges_data_offset(num_segments: int) -> int:
    """Byte offset where compressed payload starts (16-byte aligned)."""
    return align16(16 + num_segments * 8)


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
    major: int = 4,
) -> bytes:
    """Compress raw block data into an sges block.

    Args:
        uncompressed: Raw decompressed block data.
        segment_size: Max uncompressed bytes per segment.
        level: zlib compression level (1-9, default 6).
        major: sges major version (4 in all retail/demo blocks; exe validates this).

    Returns:
        Complete sges block bytes ready for WAD injection.
    """
    total_u = len(uncompressed)
    if total_u == 0:
        raise ValueError("Cannot compress empty data")

    # compressed_flag=True means deflate-compressed; False means stored raw.
    segments: list[tuple[bytes, int, bool]] = []
    offset = 0
    while offset < total_u:
        chunk = uncompressed[offset:offset + segment_size]
        compressed = compress_segment(chunk, level)
        # Fall back to raw storage when deflate output exceeds the u16
        # comp_sz limit (65535) or is larger than the input (pointless).
        if len(compressed) > 65535 or len(compressed) >= len(chunk):
            segments.append((chunk, len(chunk), False))
        else:
            segments.append((compressed, len(chunk), True))
        offset += len(chunk)

    num_segments = len(segments)
    data_start = sges_data_offset(num_segments)

    # Build payload with 16-byte aligned segment starts.
    # Track absolute offsets (0-indexed) for the segment table.
    payload_parts: list[bytes] = []
    seg_offsets_0: list[int] = []  # 0-indexed absolute offset of each segment
    seg_flags: list[bool] = []
    current_pos = data_start

    for stored_data, _uncomp_size, is_compressed in segments:
        seg_offsets_0.append(current_pos)
        seg_flags.append(is_compressed)
        payload_parts.append(stored_data)
        current_pos += len(stored_data)
        # Pad to 16-byte alignment for the next segment
        padding = align16(current_pos) - current_pos
        if padding > 0:
            payload_parts.append(b"\x00" * padding)
            current_pos += padding

    # total_c = total block size rounded up to 16-byte boundary
    # The raw end is at the last segment's start + its stored size (no trailing padding needed)
    last_seg_end = seg_offsets_0[-1] + len(segments[-1][0])
    total_c = align16(last_seg_end)

    # Build header
    header = struct.pack("<4sHHII",
                         SGES_MAGIC,
                         major,
                         num_segments,
                         total_u,
                         total_c)

    # Build segment table: (u16 comp_size, u16 uncomp_size, u32 offset_with_flag) per segment
    seg_table = b""
    for i, (stored_data, uncompressed_size, is_compressed) in enumerate(segments):
        comp_sz = len(stored_data)
        # For uncompressed segments stored raw, the "compressed size" equals the
        # uncompressed size.  Full-size segments (65536 bytes) overflow u16, so
        # use 0 = default (same convention as uncomp_field).
        if not is_compressed and comp_sz > 65535:
            comp_sz = 0
        # uncomp_size field: 0 for full-size segments, actual size for the last (short) segment
        if uncompressed_size == segment_size:
            uncomp_field = 0
        else:
            uncomp_field = uncompressed_size
        # The offset field's bit 0 is the compression flag (1=deflate compressed).
        # Since all offsets are 16-byte aligned (always even), setting bit 0
        # is equivalent to adding 1. The engine masks with 0xFFFFFFFE to get
        # the actual byte offset.
        abs_offset_flagged = seg_offsets_0[i]
        if is_compressed:
            abs_offset_flagged |= 1
        seg_table += struct.pack("<HHI", comp_sz, uncomp_field, abs_offset_flagged)

    header_and_table = header + seg_table
    padding_needed = data_start - len(header_and_table)
    padded_header = header_and_table + b"\x00" * padding_needed

    # Assemble: padded header + payload (with inter-segment alignment padding)
    # But remove trailing padding after last segment (total_c handles the extent)
    payload_bytes = b"".join(payload_parts)
    # Trim trailing padding that we added after the last segment
    actual_payload_needed = last_seg_end - data_start
    payload_bytes = payload_bytes[:actual_payload_needed]
    # Pad the entire block to total_c
    block = padded_header + payload_bytes
    if len(block) < total_c:
        block += b"\x00" * (total_c - len(block))

    return block


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
    ap.add_argument("output", type=Path, nargs="?", help="Output .sges.bin file")
    ap.add_argument("--segment-size", type=int, default=DEFAULT_SEGMENT_SIZE,
                    help=f"Max uncompressed bytes per segment (default {DEFAULT_SEGMENT_SIZE})")
    ap.add_argument("--level", type=int, default=6,
                    help="Compression level 1-9 (default 6)")
    ap.add_argument("--major", type=int, default=4,
                    help="sges major version (default 4)")
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
        major, seg_count = struct.unpack_from("<HH", data, 4)
        total_u, total_c = struct.unpack_from("<II", data, 8)
        data_off = sges_data_offset(seg_count)
        print(f"sges v{major}, {seg_count} segments")
        print(f"  Uncompressed: {total_u:,} bytes")
        print(f"  Block size:   {total_c:,} bytes (total_c)")
        print(f"  Data offset:  0x{data_off:x}")
        for i in range(seg_count):
            off = 16 + i * 8
            cs = struct.unpack_from("<H", data, off)[0]
            us = struct.unpack_from("<H", data, off + 2)[0]
            abs_off_raw = struct.unpack_from("<I", data, off + 4)[0]
            flag = abs_off_raw & 1
            abs_off = abs_off_raw & 0xFFFFFFFE
            us_str = f"{us:,}" if us > 0 else "(default 65536)"
            flag_str = "compressed" if flag else "raw"
            print(f"  Segment {i}: comp={cs:,}  uncomp={us_str}  offset=0x{abs_off:X} ({flag_str})")
        return 0

    if not args.input.is_file():
        print(f"Input file not found: {args.input}", file=sys.stderr)
        return 1

    if args.output is None:
        ap.error("output is required when not using --info")

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
    _major, seg_count = struct.unpack_from("<HH", compressed, 4)
    print(f"Output: {args.output} ({len(compressed):,} bytes, {seg_count} segments, {ratio:.1f}% ratio)")

    if args.verify:
        if not verify_roundtrip(uncompressed, compressed):
            return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
