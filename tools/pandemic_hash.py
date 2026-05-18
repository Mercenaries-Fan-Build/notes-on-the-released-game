#!/usr/bin/env python3
"""Pandemic Studios FNV-1a hash implementation.

Confirmed from Mercenaries 1 source code (`Tools/Hash/Hash.c` and
`Pebble/Source/PblHashTable.cpp`). This is the hash used for all
asset name lookups, type identifiers, and script bindings in
Pandemic's engine (Zero Engine / Red Engine / Pebble).

Algorithm: FNV-1a 32-bit with case suppression (each byte OR'd with 0x20).

Usage:
  python3 tools/pandemic_hash.py "wiftutorialtank"
  python3 tools/pandemic_hash.py --file paths.txt
  python3 tools/pandemic_hash.py --test 0x3884598e registry
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

FNV1A_OFFSET_BASIS = 0x811C9DC5
FNV1A_PRIME = 0x01000193


def pandemic_hash(text: str) -> int:
    """Compute Pandemic Studios FNV-1a hash with case suppression.

    Each byte is OR'd with 0x20 before XOR into the hash, which has
    the effect of forcing uppercase ASCII letters to lowercase while
    leaving lowercase, digits, and most punctuation unchanged.

    Args:
        text: Input string (asset name, type, path, etc.)

    Returns:
        32-bit unsigned hash value. Returns 0 for empty/null input.
    """
    if not text:
        return 0
    h = FNV1A_OFFSET_BASIS
    for ch in text:
        h ^= (ord(ch) | 0x20)
        h = (h * FNV1A_PRIME) & 0xFFFFFFFF
    return h


def pandemic_hash_bytes(data: bytes) -> int:
    """Compute Pandemic FNV-1a over raw bytes (no case suppression)."""
    if not data:
        return 0
    h = FNV1A_OFFSET_BASIS
    for b in data:
        h ^= b
        h = (h * FNV1A_PRIME) & 0xFFFFFFFF
    return h


def main() -> int:
    ap = argparse.ArgumentParser(description="Pandemic Studios FNV-1a hash")
    ap.add_argument("strings", nargs="*", help="Strings to hash")
    ap.add_argument("--file", type=Path, help="Hash each line of a file")
    ap.add_argument("--test", nargs=2, metavar=("EXPECTED", "INPUT"),
                    help="Test: verify hash(INPUT) == EXPECTED")
    ap.add_argument("--search", type=lambda x: int(x, 0),
                    help="Search for this hash value in --file lines")
    ap.add_argument("--no-case-suppress", action="store_true",
                    help="Use standard FNV-1a without |0x20 case suppression")
    args = ap.parse_args()

    if args.test:
        expected = int(args.test[0], 0)
        text = args.test[1]
        actual = pandemic_hash(text)
        match = "PASS" if actual == expected else "FAIL"
        print(f"{match}: pandemic_hash(\"{text}\") = 0x{actual:08x} (expected 0x{expected:08x})")
        return 0 if actual == expected else 1

    if args.file:
        if not args.file.is_file():
            print(f"File not found: {args.file}", file=sys.stderr)
            return 1
        lines = args.file.read_text(encoding="utf-8", errors="replace").splitlines()
        for line in lines:
            line = line.strip()
            if not line:
                continue
            h = pandemic_hash(line)
            if args.search is not None:
                if h == args.search:
                    print(f"FOUND: 0x{h:08x}  {line}")
            else:
                print(f"0x{h:08x}  {line}")
        return 0

    if not args.strings:
        ap.print_help()
        return 0

    for s in args.strings:
        if args.no_case_suppress:
            h = pandemic_hash_bytes(s.encode("ascii", errors="replace"))
        else:
            h = pandemic_hash(s)
        print(f"0x{h:08x}  {s}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
