#!/usr/bin/env python3
"""Compare Python vs Rust ECS byte-swap on decompressed BE blocks.

Usage:
  .venv/Scripts/python.exe tools/audit_ecs_byteswap_parity.py \\
      --be-block path/to/xbox.block.bin

  .venv/Scripts/python.exe tools/audit_ecs_byteswap_parity.py \\
      --patch-wad output/data/vz-patch.wad --indices 4,12,15,16,17
"""
from __future__ import annotations

import argparse
import struct
import sys
from pathlib import Path

THIS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(THIS_DIR))

from ucfx_be_to_le import byteswap_ucfx_block  # noqa: E402
from ucfx_byteswap_wrapper import byteswap_block_rust  # noqa: E402

try:
    from ffcs_patch_wad import read_patch_wad  # noqa: E402
    from sges_decompress import decompress_sges_block  # noqa: E402
except ImportError:
    read_patch_wad = None  # type: ignore


def _first_diff(a: bytes, b: bytes, limit: int = 5) -> list[str]:
    out: list[str] = []
    n = min(len(a), len(b))
    for i in range(n):
        if a[i] != b[i]:
            out.append(f"  offset 0x{i:X}: py=0x{a[i]:02X} rust=0x{b[i]:02X}")
            if len(out) >= limit:
                break
    if len(a) != len(b) and len(out) < limit:
        out.append(f"  length: py={len(a)} rust={len(b)}")
    return out


def compare_block(be: bytes, label: str) -> bool:
    py_le, py_stats = byteswap_ucfx_block(be)
    try:
        rust_le = byteswap_block_rust(be, validate=False)
    except (FileNotFoundError, RuntimeError) as e:
        print(f"{label}: Rust failed: {e}")
        return False
    if py_le == rust_le:
        print(f"{label}: OK (identical {len(py_le):,} bytes)")
        return True
    diffs = _first_diff(py_le, rust_le)
    print(f"{label}: MISMATCH ({len(diffs)} sample diffs)")
    for line in diffs:
        print(line)
    fb = py_stats.get("fallback_u32_count", 0)
    if fb:
        print(f"  Python fallback_u32_count={fb}")
    return False


def main() -> int:
    ap = argparse.ArgumentParser(description="Python vs Rust ECS byteswap parity")
    ap.add_argument("--be-block", type=Path, help="Decompressed Xbox BE .block.bin")
    ap.add_argument("--patch-wad", type=Path, help="LE patch WAD (cannot diff without BE source)")
    ap.add_argument("--indices", type=str, default="4,12,15,16,17",
                    help="Block indices when using --patch-wad (needs paired BE files)")
    args = ap.parse_args()

    if args.be_block:
        return 0 if compare_block(args.be_block.read_bytes(), args.be_block.name) else 1

    if args.patch_wad:
        if read_patch_wad is None:
            ap.error("ffcs_patch_wad not available")
        print(
            "Note: patch WAD is already LE. Pass --be-block from Xbox DOH/decompress "
            "for real parity. Listing patch block paths:"
        )
        contents = read_patch_wad(args.patch_wad)
        want = {int(x.strip()) for x in args.indices.split(",")}
        for i, blk in enumerate(contents.blocks):
            if i in want:
                print(f"  [{i:4d}] {blk.path_string}")
        return 0

    ap.error("Specify --be-block or --patch-wad")
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
