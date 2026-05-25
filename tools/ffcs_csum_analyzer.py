#!/usr/bin/env python3
"""Analyze FFCS-level CSUM entries against compressed sges block data.

Tests the hypothesis that FFCS CSUM entries are checksums (CRC32 or other)
of the raw compressed sges data within the DATA chunk.

Usage:
  python3 tools/ffcs_csum_analyzer.py --wad data/vz.wad
  python3 tools/ffcs_csum_analyzer.py --wad data/vz.wad --max 50 --verbose
"""

from __future__ import annotations

import argparse
import mmap as mmap_mod
import struct
import sys
import zlib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from ffcs_wad import parse_ffcs, extract_slice  # noqa: E402
from sges_decompress import find_sges_offsets, parse_sges_header, sges_data_offset  # noqa: E402

SGES_MAGIC = b"sges"


def read_csum_entries(wad_data: bytes, csum_offset: int, csum_count: int) -> list[int]:
    """Read CSUM chunk entries (array of u32)."""
    entries = []
    for i in range(csum_count):
        off = csum_offset + i * 4
        if off + 4 > len(wad_data):
            break
        val = struct.unpack_from("<I", wad_data, off)[0]
        entries.append(val)
    return entries


def hash_tests(data: bytes) -> dict[str, int]:
    """Compute multiple hash algorithms on data."""
    results = {}
    results["crc32_standard"] = zlib.crc32(data) & 0xFFFFFFFF
    results["crc32_init0"] = zlib.crc32(data, 0) & 0xFFFFFFFF
    results["adler32"] = zlib.adler32(data) & 0xFFFFFFFF

    h = 0x811C9DC5
    for b in data:
        h ^= b
        h = (h * 0x01000193) & 0xFFFFFFFF
    results["fnv1a_32"] = h

    h = 0x811C9DC5
    for b in data:
        h = (h * 0x01000193) & 0xFFFFFFFF
        h ^= b
    results["fnv1_32"] = h

    h = 5381
    for b in data:
        h = ((h << 5) + h + b) & 0xFFFFFFFF
    results["djb2"] = h

    h = 0
    for b in data:
        h += b
        h += (h << 10) & 0xFFFFFFFF
        h ^= (h >> 6)
        h &= 0xFFFFFFFF
    h += (h << 3) & 0xFFFFFFFF
    h ^= (h >> 11)
    h += (h << 15) & 0xFFFFFFFF
    h &= 0xFFFFFFFF
    results["jenkins_oaat"] = h

    results["byte_sum"] = sum(data) & 0xFFFFFFFF
    results["byte_xor"] = 0
    for b in data:
        results["byte_xor"] ^= b

    return results


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Analyze FFCS CSUM entries vs compressed block data"
    )
    ap.add_argument("--wad", type=Path, required=True, help=".wad file to analyze")
    ap.add_argument("--max", type=int, default=0, help="Max blocks to test (0 = all)")
    ap.add_argument("--verbose", "-v", action="store_true")
    ap.add_argument("--paths", type=Path, help="paths.txt for block names")
    args = ap.parse_args()

    if not args.wad.is_file():
        print(f"WAD not found: {args.wad}", file=sys.stderr)
        return 1

    arch = parse_ffcs(args.wad)
    csum_chunk = next((c for c in arch.chunks if c.tag == "CSUM"), None)
    data_chunk = next((c for c in arch.chunks if c.tag == "DATA"), None)
    indx_chunk = next((c for c in arch.chunks if c.tag == "INDX"), None)

    if csum_chunk is None:
        print("No CSUM chunk in WAD", file=sys.stderr)
        return 1
    if data_chunk is None:
        print("No DATA chunk in WAD", file=sys.stderr)
        return 1

    print(f"WAD: {args.wad} ({arch.file_size:,} bytes)")
    print(f"DATA: offset=0x{data_chunk.offset:x} size={data_chunk.size:,}")
    print(f"CSUM: offset=0x{csum_chunk.offset:x} meta={csum_chunk.meta} (entry count)")
    if indx_chunk:
        print(f"INDX: offset=0x{indx_chunk.offset:x} meta={indx_chunk.meta} (block count)")
    print()

    paths = None
    if args.paths and args.paths.is_file():
        paths = [
            ln for ln in args.paths.read_text(encoding="utf-8", errors="replace").splitlines()
            if ln.strip()
        ]

    with open(args.wad, "rb") as f:
        mm = mmap_mod.mmap(f.fileno(), 0, access=mmap_mod.ACCESS_READ)

    try:
        csum_entries = read_csum_entries(
            mm, data_chunk.offset, csum_chunk.meta
        )

        # CSUM chunk offset might not be a file offset (it's often a hash).
        # Try reading from where we'd expect the CSUM data to actually live:
        # - After INDX, DATA, ASET, PTHS chunks
        # - Or at the offset stored in the CSUM chunk row

        # Actually, let's just brute-force scan: read u32 arrays from
        # plausible locations and see if any match.
        # But first, let's try the simplest approach: CSUM entries are stored
        # as a flat u32 array somewhere in the file.

        # For now, just look for CSUM entries at the stored offset
        # (even though it might exceed file size for some WADs)
        actual_csum_offset = csum_chunk.offset
        if actual_csum_offset >= arch.file_size:
            print(f"CSUM offset 0x{actual_csum_offset:x} exceeds file size {arch.file_size:,}")
            print("CSUM 'offset' field is likely a hash, not a file offset.")
            print()
            print("Attempting to locate CSUM array by scanning after other chunks...")

            # The CSUM array is likely after the last spatial chunk
            spatial_ends = []
            for c in arch.chunks:
                if c.tag != "CSUM" and c.size > 0:
                    spatial_ends.append(c.offset + c.size)
            if spatial_ends:
                scan_start = max(spatial_ends)
                remaining = arch.file_size - scan_start
                if remaining >= csum_chunk.meta * 4:
                    print(f"Possible CSUM array at 0x{scan_start:x} ({remaining:,} bytes remaining)")
                    csum_entries = []
                    for i in range(csum_chunk.meta):
                        off = scan_start + i * 4
                        if off + 4 <= arch.file_size:
                            val = struct.unpack_from("<I", mm, off)[0]
                            csum_entries.append(val)
                    print(f"Read {len(csum_entries)} potential CSUM entries")
                else:
                    print(f"Not enough space after spatial chunks for {csum_chunk.meta} entries")

        if not csum_entries:
            print("Could not locate CSUM entries", file=sys.stderr)
            return 1

        print(f"CSUM entries loaded: {len(csum_entries)}")
        csum_set = set(csum_entries)
        print(f"Unique CSUM values: {len(csum_set)}")
        print()

        data_blob = mm[data_chunk.offset:data_chunk.offset + data_chunk.size]
        sges_offsets = find_sges_offsets(data_blob)
        print(f"sges blocks in DATA: {len(sges_offsets)}")
        print()

        limit = len(sges_offsets)
        if args.max > 0:
            limit = min(limit, args.max)

        algo_hits: dict[str, int] = {}
        tested = 0

        for i in range(limit):
            rel_start = sges_offsets[i]
            rel_end = sges_offsets[i + 1] if i + 1 < len(sges_offsets) else data_chunk.size
            block_data = data_blob[rel_start:rel_end]

            path_name = paths[i] if paths and i < len(paths) else f"block_{i}"

            try:
                _maj, _min, _tu, _tc = parse_sges_header(block_data)
            except Exception:
                if args.verbose:
                    print(f"  [{i}] {path_name}: invalid sges header, skipping")
                continue

            hashes = hash_tests(block_data)

            for algo_name, hash_val in hashes.items():
                if hash_val in csum_set:
                    algo_hits[algo_name] = algo_hits.get(algo_name, 0) + 1
                    if args.verbose:
                        print(f"  HIT: block {i} {algo_name}=0x{hash_val:08x} matches CSUM entry")

            sges_header_only = block_data[:16]
            hashes_hdr = hash_tests(sges_header_only)
            for algo_name, hash_val in hashes_hdr.items():
                key = f"{algo_name}_header"
                if hash_val in csum_set:
                    algo_hits[key] = algo_hits.get(key, 0) + 1

            payload_start = sges_data_offset(_min)
            if payload_start < len(block_data):
                payload = block_data[payload_start:]
                hashes_payload = hash_tests(payload)
                for algo_name, hash_val in hashes_payload.items():
                    key = f"{algo_name}_payload"
                    if hash_val in csum_set:
                        algo_hits[key] = algo_hits.get(key, 0) + 1

            tested += 1

        print(f"\nTested {tested} blocks against {len(csum_entries)} CSUM entries")
        print()

        if algo_hits:
            print("Algorithm hit summary (higher = more likely match):")
            for algo, count in sorted(algo_hits.items(), key=lambda x: -x[1]):
                pct = count / tested * 100
                print(f"  {algo:30s}: {count:5d} hits ({pct:.1f}%)")
        else:
            print("NO algorithm produced any matches against CSUM entries.")
            print("The FFCS CSUM entries are NOT simple checksums of compressed sges data.")

    finally:
        mm.close()

    return 0


if __name__ == "__main__":
    sys.exit(main())
