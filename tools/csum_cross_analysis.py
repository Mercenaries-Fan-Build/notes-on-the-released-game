#!/usr/bin/env python3
"""Cross-block-type CSUM analysis — ALGORITHM IDENTIFIED.

The CSUM algorithm is **CRC-32 with init=0, no final XOR** (polynomial 0xEDB88320).
This is NOT standard CRC-32 (which uses init=0xFFFFFFFF, final XOR=0xFFFFFFFF).
Python shortcut: (zlib.crc32(data, 0xFFFFFFFF) ^ 0xFFFFFFFF) & 0xFFFFFFFF

Block file structure:
    [header]     = count(4 bytes) + count × entry(16 bytes)
    [chunks]     = for each entry: UCFX_header(8) + UCFX_body + "CSUM" tag(4) + CRC32(4)
    [optional]   = zero-padding to power-of-2 file size (rare)

Each header entry: (name_hash, type_hash, field_c, chunk_size) — all uint32 LE.
    - name_hash:  hash of the block/asset name
    - type_hash:  one of ~35 fixed values (asset type identifier), includes 0x42498680
    - field_c:    often 0 for first entry; non-zero for secondary entries
    - chunk_size: total bytes for this chunk (UCFX header + body + 8-byte CSUM trailer)

CRC-32 input range: UCFX header (magic "UCFX" + 4-byte payload length) + UCFX body.
CRC-32 output: standard CRC-32 = zlib.crc32(data, -1) ^ 0xFFFFFFFF   (or ~zlib.crc32(data, 0xFFFFFFFF))

Validation: 53,765 / 53,765 chunks match (100.0%) across 11,365 block files.
"""
from __future__ import annotations

import argparse
import struct
import zlib
from pathlib import Path


def crc32_mercs2(data: bytes) -> int:
    """CRC-32 with init=0, no final XOR (Mercenaries 2 CSUM algorithm)."""
    return (zlib.crc32(data, 0xFFFFFFFF) ^ 0xFFFFFFFF) & 0xFFFFFFFF


def validate_block(data: bytes) -> tuple[int, int, list[str]]:
    """Validate all CSUM values in a block file.
    
    Returns (chunks_ok, chunks_fail, error_messages).
    """
    if len(data) < 12:
        return 0, 0, ["file too small"]

    count = struct.unpack_from("<I", data, 0)[0]
    if count < 1 or count > 50000:
        return 0, 0, [f"invalid count: {count}"]

    ucfx_start = 4 + count * 16
    if ucfx_start >= len(data):
        return 0, 0, ["header extends beyond file"]

    ok = 0
    fail = 0
    errors = []
    pos = ucfx_start

    for i in range(count):
        entry_off = 4 + i * 16
        if entry_off + 16 > len(data):
            break
        chunk_size = struct.unpack_from("<I", data, entry_off + 12)[0]

        if chunk_size < 16 or pos + chunk_size > len(data):
            errors.append(f"chunk[{i}]: truncated (need {pos+chunk_size}, have {len(data)})")
            break

        chunk = data[pos : pos + chunk_size]
        if chunk[-8:-4] != b"CSUM":
            errors.append(f"chunk[{i}]: no CSUM trailer")
            break

        expected = struct.unpack_from("<I", chunk, len(chunk) - 4)[0]
        computed = crc32_mercs2(chunk[:-8])

        if computed == expected:
            ok += 1
        else:
            fail += 1
            errors.append(
                f"chunk[{i}]: CRC mismatch expected={expected:#010x} got={computed:#010x}"
            )

        pos += chunk_size

    return ok, fail, errors


def main():
    parser = argparse.ArgumentParser(description="Validate CSUM (CRC-32) in block files")
    parser.add_argument("blocks_dir", help="Path to blocks directory")
    parser.add_argument("--verbose", "-v", action="store_true")
    args = parser.parse_args()

    blocks_dir = Path(args.blocks_dir)
    block_files = sorted(blocks_dir.glob("*.block.bin"))

    total_ok = 0
    total_fail = 0
    total_files = 0
    files_ok = 0
    files_fail = 0
    files_skip = 0

    for bf in block_files:
        data = bf.read_bytes()
        if len(data) == 0:
            files_skip += 1
            continue

        ok, fail, errors = validate_block(data)
        total_ok += ok
        total_fail += fail

        if ok + fail == 0:
            files_skip += 1
        elif fail == 0:
            files_ok += 1
            total_files += 1
        else:
            files_fail += 1
            total_files += 1
            if args.verbose:
                for e in errors:
                    print(f"  FAIL: {bf.name}: {e}")

    print(f"Block files scanned:  {len(block_files)}")
    print(f"Files validated:      {total_files}")
    print(f"  Files OK:           {files_ok}")
    print(f"  Files with errors:  {files_fail}")
    print(f"  Files skipped:      {files_skip}")
    print()
    print(f"Total UCFX chunks:    {total_ok + total_fail}")
    print(f"  Chunks OK:          {total_ok}")
    print(f"  Chunks failed:      {total_fail}")
    print(f"  Match rate:         {100*total_ok/max(1, total_ok+total_fail):.2f}%")
    print()
    print("Algorithm: CRC-32 (init=0, no final XOR)")
    print("  Polynomial: 0xEDB88320 (reversed)")
    print("  Init:       0x00000000")
    print("  Final XOR:  0x00000000")
    print("  Input:      UCFX header (8 bytes) + UCFX body")
    print("  Python:     (zlib.crc32(data, 0xFFFFFFFF) ^ 0xFFFFFFFF) & 0xFFFFFFFF")


if __name__ == "__main__":
    main()
