#!/usr/bin/env python3
"""Verify vz-patch.wad FFCS structure (G6 gate — PTHS trailer, block counts).

Checks:
  - FFCS magic and required chunks (INDX, DATA, CSUM, ASET, PTHS)
  - 258-byte PTHS trailer marker (see docs/patch_wad_format.md)
  - Optional expected block count (--expect-blocks)

Usage:
  python3 tools/verify_patch_wad_structure.py --wad path/to/vz-patch.wad
  python3 tools/verify_patch_wad_structure.py --wad vz-patch.wad --expect-blocks 2197
  python3 tools/verify_patch_wad_structure.py --wad vz-patch.wad --expect-blocks 2196 --variant dlc-only
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from dlc_port_x360_to_pc import PTHS_TRAILER  # noqa: E402
from ffcs_wad import parse_ffcs, extract_slice, dump_paths_from_pths  # noqa: E402

REQUIRED_CHUNKS = ("INDX", "DATA", "CSUM", "ASET", "PTHS")

# Approximate sizes for deploy sanity (bytes)
SIZE_HINTS = {
    "full": (250_000_000, 260_000_000),
    "dlc-only": (235_000_000, 250_000_000),
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

    if ok and not (args.expect_blocks and n_blocks != args.expect_blocks):
        print("  OK: patch WAD structure looks valid")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
