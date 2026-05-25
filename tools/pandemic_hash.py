#!/usr/bin/env python3
"""Pandemic Studios FNV-1a hash implementation.

Two variants exist across Pandemic engine generations:

  **Mercs 1 (Zero Engine / Pebble):**
    Standard FNV-1a 32-bit with case suppression (each byte OR'd with 0x20).
    Confirmed from Mercenaries 1 source code (`Tools/Hash/Hash.c` and
    `Pebble/Source/PblHashTable.cpp`).
    Verification: pandemic_hash("registry") == 0x3884598e (from RedVirtualDisk.cpp)

  **Mercs 2 (with post-processing):**
    Same FNV-1a + case suppression loop, followed by a final:
      hash ^= 0x2A
      hash *= FNV_PRIME
    Confirmed from two independent disassembly analyses of MERCENAR.EXE
    (166+ call sites). Verified: pandemic_hash_m2("texture") == 0xF011157A
    and pandemic_hash_m2("model") == 0x5B724250 (matching ASET type constants).

Usage:
  python3 tools/pandemic_hash.py "wiftutorialtank"
  python3 tools/pandemic_hash.py --m2 "texture"
  python3 tools/pandemic_hash.py --file paths.txt
  python3 tools/pandemic_hash.py --test 0xf011157a texture --m2
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

FNV1A_OFFSET_BASIS = 0x811C9DC5
FNV1A_PRIME = 0x01000193


def pandemic_hash(text: str) -> int:
    """Compute Pandemic Studios FNV-1a hash with case suppression (Mercs 1 variant).

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


def pandemic_hash_m2(text: str) -> int:
    """Compute Mercenaries 2 FNV-1a hash with post-processing.

    Same as pandemic_hash() but with an additional finalization step
    found in the Mercs 2 executable (166+ call sites):
      hash ^= 0x2A
      hash *= FNV_PRIME

    This is the variant used for runtime ASET asset lookups and type
    identifiers in Mercenaries 2. Verified matches:
      pandemic_hash_m2("texture") == 0xF011157A
      pandemic_hash_m2("model")   == 0x5B724250

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
    h ^= 0x2A
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
    ap.add_argument("--m2", action="store_true",
                    help="Use Mercs 2 variant (adds ^0x2A, *prime post-processing)")
    args = ap.parse_args()

    hash_fn = pandemic_hash_m2 if args.m2 else pandemic_hash

    if args.test:
        expected = int(args.test[0], 0)
        text = args.test[1]
        actual = hash_fn(text)
        variant = "pandemic_hash_m2" if args.m2 else "pandemic_hash"
        match = "PASS" if actual == expected else "FAIL"
        print(f"{match}: {variant}(\"{text}\") = 0x{actual:08x} (expected 0x{expected:08x})")
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
            h = hash_fn(line)
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
            h = hash_fn(s)
        print(f"0x{h:08x}  {s}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
