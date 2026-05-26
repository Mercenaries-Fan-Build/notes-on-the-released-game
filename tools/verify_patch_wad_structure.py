#!/usr/bin/env python3
"""Verify vz-patch.wad FFCS structure (G7 gate — PTHS trailer, block counts,
packed_field decompression buffer sizing).

Checks:
  - FFCS magic and required chunks (INDX, DATA, CSUM, ASET, PTHS)
  - 258-byte PTHS trailer marker (see docs/patch_wad_format.md)
  - Optional expected block count (--expect-blocks)
  - packed_field vs actual decompressed size for every block

Usage:
  python3 tools/verify_patch_wad_structure.py --wad path/to/vz-patch.wad
  python3 tools/verify_patch_wad_structure.py --wad vz-patch.wad --expect-blocks 2197
  python3 tools/verify_patch_wad_structure.py --wad vz-patch.wad --expect-blocks 2196 --variant dlc-only
"""
from __future__ import annotations

import argparse
import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from ffcs_patch_wad import PTHS_TRAILER, PAGE_SIZE  # noqa: E402
from ffcs_wad import parse_ffcs, extract_slice, dump_paths_from_pths  # noqa: E402
from sges_decompress import decompress_sges_block  # noqa: E402

REQUIRED_CHUNKS = ("INDX", "DATA", "CSUM", "ASET", "PTHS")

# Approximate sizes for deploy sanity (bytes)
SIZE_HINTS = {
    "full": (180_000_000, 260_000_000),
    "dlc-only": (170_000_000, 250_000_000),
    "bootstrap-only": (8_000_000, 20_000_000),
}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--wad", type=Path, required=True)
    ap.add_argument(
        "--expect-blocks",
        type=int,
        default=0,
        help="Expected PTHS path count (0 = only warn if unusual)",
    )
    ap.add_argument(
        "--variant",
        choices=("full", "dlc-only", "bootstrap-only", "any"),
        default="any",
        help="Apply size hints for known build variants",
    )
    args = ap.parse_args()
    if not args.wad.is_file():
        print(f"ERROR: not found: {args.wad}", file=sys.stderr)
        return 1

    raw = args.wad.read_bytes()
    size = len(raw)
    if raw[:4] != b"FFCS":
        print(f"FAIL: not FFCS (magic={raw[:4]!r})")
        return 1

    arch = parse_ffcs(args.wad)
    tags = {c.tag for c in arch.chunks}
    missing = [t for t in REQUIRED_CHUNKS if t not in tags]
    if missing:
        print(f"FAIL: missing chunks: {missing}")
        return 1

    pths_chunk = next(c for c in arch.chunks if c.tag == "PTHS")
    pths_data = extract_slice(raw, pths_chunk)
    paths = dump_paths_from_pths(pths_data)
    n_blocks = len(paths)

    trailer_pos = raw.find(PTHS_TRAILER, pths_chunk.offset)
    trailer_ok = trailer_pos >= 0 and trailer_pos < pths_chunk.offset + pths_chunk.size + 1_000_000

    print(f"WAD: {args.wad}")
    print(f"  Size:           {size:,} bytes ({size / (1024 * 1024):.1f} MiB)")
    print(f"  Chunks:         {', '.join(c.tag for c in arch.chunks)}")
    print(f"  Blocks (PTHS):  {n_blocks}")
    print(f"  PTHS trailer:   {'PRESENT' if trailer_ok else 'MISSING'}", end="")
    if trailer_ok:
        print(f" @ 0x{trailer_pos:X}")
    else:
        print()

    ok = trailer_ok
    if args.expect_blocks and n_blocks != args.expect_blocks:
        print(f"  FAIL: expected {args.expect_blocks} blocks, got {n_blocks}")
        ok = False
    elif args.expect_blocks:
        print(f"  OK: block count matches --expect-blocks {args.expect_blocks}")

    if args.variant != "any" and args.variant in SIZE_HINTS:
        lo, hi = SIZE_HINTS[args.variant]
        if not (lo <= size <= hi):
            print(f"  WARN: size outside {args.variant} hint [{lo:,}, {hi:,}]")
        else:
            print(f"  OK: size within {args.variant} hint")

    # ── packed_field vs actual decompressed size ──
    indx_chunk = next(c for c in arch.chunks if c.tag == "INDX")
    indx_off = indx_chunk.offset
    indx_count = indx_chunk.meta

    print(f"\n  packed_field verification ({indx_count} blocks)...")
    packed_failures = []
    for i in range(indx_count):
        entry_off = indx_off + i * 12
        page_idx, packed, flags_pages = struct.unpack_from("<III", raw, entry_off)
        comp_pages = flags_pages & 0xFFFF
        alloc_pages = packed & 0x00FFFFFF
        tier = (packed >> 24) & 0xFF

        block_off = page_idx * PAGE_SIZE
        block_sz = comp_pages * PAGE_SIZE
        if block_off + block_sz > size:
            packed_failures.append((i, "block data beyond EOF"))
            continue

        try:
            decompressed = decompress_sges_block(
                raw, block_off, block_off + block_sz,
            )
        except Exception as e:
            packed_failures.append((i, f"sges decompress failed: {e}"))
            continue

        needed_pages = (len(decompressed) + PAGE_SIZE - 1) // PAGE_SIZE
        if alloc_pages < needed_pages:
            path_str = paths[i] if i < len(paths) else f"block_{i}"
            packed_failures.append((
                i,
                f"BUFFER OVERFLOW: packed_field allocates {alloc_pages} pages "
                f"({alloc_pages * PAGE_SIZE:,} bytes) but decompressed size is "
                f"{len(decompressed):,} bytes ({needed_pages} pages needed) — "
                f"tier={tier} path={path_str}",
            ))

    if packed_failures:
        print(f"  FAIL: {len(packed_failures)} packed_field error(s):")
        for blk_i, msg in packed_failures:
            print(f"    block[{blk_i}]: {msg}")
        ok = False
    else:
        print(f"  OK: all {indx_count} blocks have correct packed_field sizing")

    if ok:
        print("\n  OK: patch WAD structure looks valid")
    else:
        print(f"\n  FAIL: {len(packed_failures)} error(s) found")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
