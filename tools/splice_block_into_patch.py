#!/usr/bin/env python3
"""Splice a single decompressed LE block into an existing patch WAD.

Replaces one block's sges payload in-place (re-compressing the supplied
decompressed block) and rebuilds the FFCS structure with ffcs_patch_wad. All
other blocks, ASET rows, paths and flags are preserved. This lets us generate
single-block A/B test WADs (e.g. a converter-fix variant) WITHOUT rebuilding the
full patch WAD from scratch.

Usage:
    python tools/splice_block_into_patch.py \
        --patch output/data/vz-patch-keep-dlccon004-roads-only.wad \
        --block output/_dumps_fixed/block_0018_le.bin \
        --path-substr dlccon004_roads \
        --output output/data/vz-patch-block18-fixed.wad
"""
from __future__ import annotations

import argparse
import sys
import zlib
from pathlib import Path

_TOOLS = Path(__file__).resolve().parent
if str(_TOOLS) not in sys.path:
    sys.path.insert(0, str(_TOOLS))

import sges_compress  # noqa: E402
from ffcs_patch_wad import (  # noqa: E402
    build_patch_wad_multi,
    read_patch_wad,
)


def _try_decompress(blob: bytes) -> bytes | None:
    """Best-effort sges/raw-deflate decompress for the sanity check."""
    try:
        from sges_decompress import decompress_sges  # type: ignore

        return decompress_sges(blob)
    except Exception:
        pass
    # Fallback: raw deflate of the first segment payload (best-effort only).
    try:
        return zlib.decompress(blob, -15)
    except Exception:
        return None


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--patch", required=True, help="Existing patch WAD to splice into")
    ap.add_argument("--block", required=True, help="Decompressed LE block .bin to insert")
    ap.add_argument("--path-substr", required=True,
                    help="Substring of the target block's PTHS path (case-insensitive)")
    ap.add_argument("--output", "-o", required=True, help="Output patch WAD path")
    ap.add_argument("--segment-size", type=int, default=65536)
    ap.add_argument("--level", type=int, default=6)
    args = ap.parse_args()

    patch = Path(args.patch)
    new_block = Path(args.block).read_bytes()

    contents = read_patch_wad(patch)
    needle = args.path_substr.lower()
    matches = [i for i, b in enumerate(contents.blocks)
               if needle in b.path_string.lower()]
    if not matches:
        paths = "\n  ".join(b.path_string for b in contents.blocks)
        print(f"ERROR: no block path contains {args.path_substr!r}. Blocks:\n  {paths}",
              file=sys.stderr)
        return 2
    if len(matches) > 1:
        sel = "\n  ".join(contents.blocks[i].path_string for i in matches)
        print(f"ERROR: {args.path_substr!r} matches {len(matches)} blocks:\n  {sel}",
              file=sys.stderr)
        return 2

    idx = matches[0]
    target = contents.blocks[idx]
    print(f"Target block [{idx}] {target.path_string}")
    print(f"  old compressed size: {len(target.compressed_data)} bytes")

    old_dec = _try_decompress(target.compressed_data)
    if old_dec is not None:
        print(f"  old decompressed   : {len(old_dec)} bytes")
        print(f"  new decompressed   : {len(new_block)} bytes "
              f"({'same size' if len(old_dec) == len(new_block) else 'DIFFERENT SIZE'})")

    new_compressed = sges_compress.compress_sges(
        new_block, segment_size=args.segment_size, level=args.level)
    print(f"  new compressed size: {len(new_compressed)} bytes")

    contents.blocks[idx].compressed_data = new_compressed

    out_bytes = build_patch_wad_multi(
        blocks=contents.blocks, csum_value=contents.csum_value)
    out_path = Path(args.output)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_bytes(out_bytes)
    print(f"Wrote {len(out_bytes)} bytes -> {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
