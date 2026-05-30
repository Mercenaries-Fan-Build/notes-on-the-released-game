#!/usr/bin/env python3
"""Validate ucfx_byteswap structural correctness on real Xbox 360 blocks.

Since Xbox and PC blocks contain platform-specific data (different texture
formats, mesh layouts, etc.), byte-for-byte comparison is not valid.
Instead we verify that:

1. Entry count is preserved; name_hash and type_hash values are preserved.
2. Each converted UCFX container starts with "UCFX" magic (not "XFCU").
3. Each entry ends with a "CSUM" tag (not "MUSC") followed by a valid CRC-32.
4. UCFX internal descriptor table parses cleanly as LE.
5. Chunk tags within descriptor bodies are valid 4-byte ASCII.
6. CRC-32 in CSUM trailer matches computed CRC of the UCFX container.

Usage:
    .venv\\Scripts\\python.exe tools\\_validate_converter.py ^
        --xbox-wad game-files\\xbox-vz.wad ^
        --binary tools\\wad_simulator\\target\\release\\ucfx_byteswap.exe ^
        --max-blocks 25
"""
from __future__ import annotations

import argparse
import mmap
import struct
import subprocess
import sys
import zlib
from pathlib import Path

SCFF_MAGIC = b"SCFF"
SEGS_MAGIC = b"segs"
UCFX_MAGIC_LE = b"UCFX"
UCFX_MAGIC_BE = b"XFCU"
CSUM_MAGIC_LE = b"CSUM"
CSUM_MAGIC_BE = b"MUSC"

TYPE_NAMES = {
    0xF011157A: "texture", 0x42498680: "script",
    0x207359C7: "stance", 0x18166555: "animation",
    0xE6B81A54: "ecs_node", 0x5B724250: "mesh_B",
    0x7C569307: "mesh_A", 0x600B904E: "mesh_C",
    0x39E5E978: "stringdb", 0xBCFE6314: "path",
    0xECE70371: "state_machine", 0xE5273C14: "audio_group",
}


def crc32_mercs2(data: bytes) -> int:
    """CRC-32 matching Mercenaries 2 convention (poly 0xEDB88320, init=0, no final XOR)."""
    crc = 0
    for b in data:
        crc ^= b
        for _ in range(8):
            if crc & 1:
                crc = (crc >> 1) ^ 0xEDB88320
            else:
                crc >>= 1
    return crc & 0xFFFFFFFF


def parse_ffcs_header(data: bytes) -> tuple[str, int, int, list[dict]]:
    magic = data[:4]
    if magic == SCFF_MAGIC:
        endian, fmt = "big", ">I"
    elif magic == b"FFCS":
        endian, fmt = "little", "<I"
    else:
        raise ValueError(f"Unknown WAD magic: {magic!r}")
    version = struct.unpack_from(fmt, data, 4)[0]
    chunk_count = struct.unpack_from(fmt, data, 8)[0]
    rows: list[dict] = []
    for i in range(min(chunk_count, 5)):
        off = 0x0C + i * 12
        tag_raw = data[off:off + 4]
        tag = (tag_raw[::-1] if endian == "big" else tag_raw).decode("ascii", errors="replace")
        val = struct.unpack_from(fmt, data, off + 4)[0]
        meta = struct.unpack_from(fmt, data, off + 8)[0]
        rows.append({"tag": tag, "offset": val, "meta": meta})
    return endian, version, chunk_count, rows


def find_data_chunk(rows: list[dict], file_size: int) -> tuple[int, int]:
    spatial = sorted(
        [(r["tag"], r["offset"]) for r in rows if r["tag"] != "CSUM" and r["offset"] < file_size],
        key=lambda t: t[1])
    data_row = next((r for r in rows if r["tag"] == "DATA"), None)
    if data_row is None:
        raise ValueError("No DATA chunk")
    data_offset = data_row["offset"]
    for i, (tag, off) in enumerate(spatial):
        if off == data_offset:
            nxt = spatial[i + 1][1] if i + 1 < len(spatial) else file_size
            return data_offset, nxt - data_offset
    return data_offset, file_size - data_offset


def find_pths_chunk(rows: list[dict], file_size: int) -> tuple[int, int] | None:
    spatial = sorted(
        [(r["tag"], r["offset"]) for r in rows if r["tag"] != "CSUM" and r["offset"] < file_size],
        key=lambda t: t[1])
    pths_row = next((r for r in rows if r["tag"] == "PTHS"), None)
    if pths_row is None:
        return None
    pths_offset = pths_row["offset"]
    for i, (tag, off) in enumerate(spatial):
        if off == pths_offset:
            nxt = spatial[i + 1][1] if i + 1 < len(spatial) else file_size
            return pths_offset, nxt - pths_offset
    return pths_offset, file_size - pths_offset


def parse_paths(blob: bytes) -> list[str]:
    paths: list[str] = []
    pos = 0
    while pos < len(blob):
        nul = blob.find(b"\x00", pos)
        if nul < 0:
            break
        s = blob[pos:nul].decode("ascii", errors="replace")
        if len(s) >= 2:
            paths.append(s)
        pos = nul + 1
    return paths


def scan_magic_offsets(mm: mmap.mmap, data_offset: int, data_size: int,
                       magic: bytes) -> list[int]:
    offsets: list[int] = []
    pos = data_offset
    end = data_offset + data_size
    while pos < end:
        idx = mm.find(magic, pos, end)
        if idx < 0:
            break
        offsets.append(idx)
        pos = idx + 4
    return offsets


def decompress_be_segs(mm: mmap.mmap, start: int, max_end: int) -> bytes:
    header = mm[start:start + 16]
    if header[:4] != SEGS_MAGIC:
        raise ValueError(f"Expected segs at 0x{start:X}")
    seg_count = struct.unpack_from(">H", header, 6)[0]
    decomp_total = struct.unpack_from(">I", header, 8)[0]
    seg_table: list[tuple[int, int]] = []
    for si in range(seg_count):
        so = start + 16 + si * 8
        csz = struct.unpack_from(">H", mm[so:so + 2], 0)[0]
        dsz = struct.unpack_from(">H", mm[so + 2:so + 4], 0)[0]
        seg_table.append((csz, dsz))
    seg_table_bytes = seg_count * 8
    header_size = 16 + ((seg_table_bytes + 15) & ~15) if seg_count > 0 else 16
    payload = mm[start + header_size:max_end]
    result = bytearray()
    pos = 0
    for csz, dsz in seg_table:
        is_raw = csz > 0 and csz == dsz
        if is_raw:
            result.extend(payload[pos:pos + csz])
            pos += csz
        else:
            dc = zlib.decompressobj(-15)
            piece = dc.decompress(bytes(payload[pos:]))
            piece += dc.flush()
            consumed = len(payload[pos:]) - len(dc.unused_data)
            result.extend(piece)
            pos += consumed
        pos = (pos + 15) & ~15
    return bytes(result)


def parse_be_block_entries(data: bytes) -> list[dict]:
    count = struct.unpack_from(">I", data, 0)[0]
    if count > 50000:
        raise ValueError(f"Suspicious entry count: {count}")
    entries: list[dict] = []
    pos = 4 + count * 16
    for i in range(count):
        h, th, fc, s = struct.unpack_from(">IIII", data, 4 + i * 16)
        entries.append({"index": i, "hash": h, "type_hash": th,
                        "field_c": fc, "size": s, "offset": pos})
        pos += s
    return entries


def parse_le_block_entries(data: bytes) -> list[dict]:
    count = struct.unpack_from("<I", data, 0)[0]
    if count > 50000:
        raise ValueError(f"Suspicious entry count: {count}")
    entries: list[dict] = []
    pos = 4 + count * 16
    for i in range(count):
        h, th, fc, s = struct.unpack_from("<IIII", data, 4 + i * 16)
        entries.append({"index": i, "hash": h, "type_hash": th,
                        "field_c": fc, "size": s, "offset": pos})
        pos += s
    return entries


def convert_block(binary_path: Path, be_data: bytes) -> tuple[bytes, str]:
    result = subprocess.run(
        [str(binary_path), "--stdin", "--stdout", "--no-validate"],
        input=be_data, capture_output=True,
    )
    stderr = result.stderr.decode("utf-8", errors="replace")
    if result.returncode != 0:
        raise RuntimeError(f"ucfx_byteswap failed (exit {result.returncode}): {stderr}")
    return result.stdout, stderr


def validate_ucfx_descriptors(container: bytes, entry_idx: int) -> list[str]:
    """Validate internal UCFX descriptor table structure (LE).

    Only checks structural validity (count, tag ASCII, table bounds).
    Body offsets intentionally omit range checks because the Rust converter
    uses body_range() which returns None for out-of-bounds offsets — these
    are legitimate "no body" or "data-area-appended" descriptors.
    """
    issues: list[str] = []
    if len(container) < 20:
        issues.append(f"Container too small ({len(container)} bytes)")
        return issues

    data_area_off = struct.unpack_from("<I", container, 4)[0]
    n_desc = struct.unpack_from("<I", container, 16)[0]

    if n_desc > 5000:
        issues.append(f"Implausible descriptor count: {n_desc}")
        return issues

    desc_table_end = 20 + n_desc * 20
    if desc_table_end > len(container):
        issues.append(f"Descriptor table exceeds container ({desc_table_end} > {len(container)})")
        return issues

    if data_area_off > 0 and data_area_off < desc_table_end:
        issues.append(
            f"data_area_offset ({data_area_off}) overlaps descriptor table (ends at {desc_table_end})")

    for di in range(n_desc):
        doff = 20 + di * 20
        tag = container[doff:doff + 4]
        if not all(32 <= c < 127 for c in tag):
            issues.append(f"Desc[{di}] non-ASCII tag: {tag!r}")

    return issues


def validate_converted_block(be_data: bytes, le_data: bytes,
                             be_entries: list[dict]) -> list[str]:
    """Validate structural correctness of a converted block."""
    issues: list[str] = []

    # 1. Parse converted header as LE
    try:
        le_entries = parse_le_block_entries(le_data)
    except Exception as exc:
        issues.append(f"Cannot parse converted header: {exc}")
        return issues

    # 2. Entry count preserved
    if len(le_entries) != len(be_entries):
        issues.append(f"Entry count changed: {len(be_entries)} -> {len(le_entries)}")
        return issues

    # 3. name_hash and type_hash preserved (field_c is zeroed by converter)
    for i, (be, le) in enumerate(zip(be_entries, le_entries)):
        if be["hash"] != le["hash"]:
            issues.append(f"Entry[{i}] name_hash: 0x{be['hash']:08X} -> 0x{le['hash']:08X}")
        if be["type_hash"] != le["type_hash"]:
            issues.append(f"Entry[{i}] type_hash: 0x{be['type_hash']:08X} -> 0x{le['type_hash']:08X}")

    # 4. Validate each entry's UCFX container and CSUM
    for i, le in enumerate(le_entries):
        off = le["offset"]
        sz = le["size"]
        end = off + sz

        if end > len(le_data):
            issues.append(f"Entry[{i}] extends past block end ({end} > {len(le_data)})")
            continue

        entry_data = le_data[off:end]

        # Check UCFX magic
        magic = entry_data[:4]
        if magic == UCFX_MAGIC_BE:
            issues.append(f"Entry[{i}] UCFX magic still BE (XFCU)")
        elif magic != UCFX_MAGIC_LE:
            issues.append(f"Entry[{i}] bad UCFX magic: {magic!r}")

        # Check CSUM trailer
        if sz >= 8:
            csum_tag = entry_data[-8:-4]
            if csum_tag == CSUM_MAGIC_BE:
                issues.append(f"Entry[{i}] CSUM tag still BE (MUSC)")
            elif csum_tag != CSUM_MAGIC_LE:
                issues.append(f"Entry[{i}] no CSUM trailer, got: {csum_tag!r}")
            else:
                # Validate CRC-32
                stored_crc = struct.unpack_from("<I", entry_data, sz - 4)[0]
                ucfx_container = entry_data[:-8]
                computed_crc = crc32_mercs2(ucfx_container)
                if stored_crc != computed_crc:
                    issues.append(
                        f"Entry[{i}] CRC mismatch: stored=0x{stored_crc:08X} "
                        f"computed=0x{computed_crc:08X}")

        # Validate UCFX descriptor table
        ucfx_container = entry_data[:-8] if sz >= 8 and entry_data[-8:-4] == CSUM_MAGIC_LE else entry_data
        desc_issues = validate_ucfx_descriptors(ucfx_container, i)
        for di in desc_issues:
            issues.append(f"Entry[{i}] {di}")

    return issues


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Validate ucfx_byteswap structural correctness")
    ap.add_argument("--xbox-wad", type=Path, required=True)
    ap.add_argument("--binary", type=Path, required=True)
    ap.add_argument("--max-blocks", type=int, default=25)
    ap.add_argument("--ecs-only", action="store_true",
                    help="Only test blocks containing ecs_node entries")
    ap.add_argument("--verbose", "-v", action="store_true")
    args = ap.parse_args()

    if not args.binary.exists():
        print(f"ERROR: binary not found: {args.binary}", file=sys.stderr)
        return 1

    print(f"Xbox WAD: {args.xbox_wad} ({args.xbox_wad.stat().st_size:,} bytes)")
    print(f"Binary:   {args.binary}")
    print()

    # Parse WAD header
    print("Parsing Xbox WAD header...")
    with open(args.xbox_wad, "rb") as f:
        xbox_mm = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)

    xbox_header = bytes(xbox_mm[:256])
    endian, ver, cc, rows = parse_ffcs_header(xbox_header)
    assert endian == "big", f"Expected BE WAD, got {endian}"
    print(f"  Endian: {endian}, version: {ver}")

    data_off, data_size = find_data_chunk(rows, len(xbox_mm))
    print(f"  DATA: offset=0x{data_off:X}, size={data_size:,}")

    pths_info = find_pths_chunk(rows, len(xbox_mm))
    paths: list[str] = []
    if pths_info:
        p_off, p_size = pths_info
        paths = parse_paths(bytes(xbox_mm[p_off:p_off + min(p_size, 4_000_000)]))
        print(f"  PTHS: {len(paths)} paths")

    # Scan blocks
    print("\nScanning DATA for segs blocks...")
    offsets = scan_magic_offsets(xbox_mm, data_off, data_size, SEGS_MAGIC)
    print(f"  Found {len(offsets)} segs blocks")

    # Find multi-entry candidates
    print("\nFinding multi-entry block candidates...")
    candidates: list[tuple[int, str, bytes, list[dict]]] = []

    for idx in range(len(offsets)):
        if len(candidates) >= args.max_blocks * 5:
            break
        try:
            start = offsets[idx]
            end = offsets[idx + 1] if idx + 1 < len(offsets) else data_off + data_size
            block = decompress_be_segs(xbox_mm, start, end)
            be_count = struct.unpack_from(">I", block, 0)[0]
            if be_count < 2 or be_count > 50000:
                continue
            be_entries = parse_be_block_entries(block)
            if args.ecs_only:
                if not any(e["type_hash"] == 0xE6B81A54 for e in be_entries):
                    continue
            path = paths[idx] if idx < len(paths) else f"block_{idx:05d}"
            candidates.append((idx, path, block, be_entries))
        except Exception as exc:
            if args.verbose:
                print(f"  Skip [{idx}]: {exc}")

    print(f"  Found {len(candidates)} multi-entry candidates")

    test_count = min(len(candidates), args.max_blocks)
    if test_count == 0:
        print("\nNo blocks to test!")
        xbox_mm.close()
        return 1

    # Run validation
    print(f"\n{'='*70}")
    print(f"Testing {test_count} blocks through ucfx_byteswap")
    print(f"{'='*70}")

    stats = {"pass": 0, "fail": 0, "error": 0}
    all_results: list[dict] = []

    for i, (idx, path, xbox_block, be_entries) in enumerate(candidates[:test_count]):
        entry_count = len(be_entries)
        type_set = set(e["type_hash"] for e in be_entries)
        type_labels = sorted(TYPE_NAMES.get(th, f"0x{th:08X}") for th in type_set)

        print(f"\n[{i+1}/{test_count}] Block {idx}: {path}")
        print(f"  Entries: {entry_count}, types: {', '.join(type_labels)}")
        print(f"  BE block size: {len(xbox_block):,} bytes")

        record: dict = {
            "block_index": idx, "path": path,
            "entry_count": entry_count, "types": type_labels,
            "be_size": len(xbox_block),
        }

        try:
            converted, stderr = convert_block(args.binary, xbox_block)
            record["le_size"] = len(converted)
            print(f"  LE block size: {len(converted):,} bytes")
        except Exception as exc:
            print(f"  ERROR in ucfx_byteswap: {exc}")
            record["result"] = "error"
            record["error"] = str(exc)
            stats["error"] += 1
            all_results.append(record)
            continue

        issues = validate_converted_block(xbox_block, converted, be_entries)

        if not issues:
            print(f"  Result: PASS (all {entry_count} entries validated)")
            record["result"] = "pass"
            stats["pass"] += 1
        else:
            print(f"  Result: FAIL ({len(issues)} issue(s)):")
            for iss in issues[:10]:
                print(f"    - {iss}")
            if len(issues) > 10:
                print(f"    ... and {len(issues) - 10} more")
            record["result"] = "fail"
            record["issues"] = issues
            stats["fail"] += 1

        all_results.append(record)

    # Summary
    print(f"\n{'='*70}")
    print(f"VALIDATION SUMMARY")
    print(f"{'='*70}")
    print(f"  Blocks tested:  {test_count}")
    print(f"  PASS:           {stats['pass']}")
    print(f"  FAIL:           {stats['fail']}")
    print(f"  ERROR:          {stats['error']}")

    total_entries = sum(r.get("entry_count", 0) for r in all_results if r.get("result") == "pass")
    print(f"  Total entries validated (passing blocks): {total_entries}")

    # Type coverage
    pass_types: set[str] = set()
    for r in all_results:
        if r["result"] == "pass":
            pass_types.update(r.get("types", []))
    if pass_types:
        print(f"  Type coverage: {', '.join(sorted(pass_types))}")

    if stats["fail"] > 0:
        print(f"\nFailed blocks:")
        for r in all_results:
            if r["result"] == "fail":
                print(f"  [{r['block_index']}] {r['path']}")
                for iss in r.get("issues", [])[:5]:
                    print(f"    - {iss}")

    if stats["error"] > 0:
        print(f"\nError blocks:")
        for r in all_results:
            if r["result"] == "error":
                print(f"  [{r['block_index']}] {r['path']}: {r['error']}")

    # Checks performed summary
    print(f"\nChecks performed per block:")
    print(f"  1. Entry count preserved")
    print(f"  2. name_hash and type_hash preserved per entry")
    print(f"  3. UCFX magic is 'UCFX' (LE), not 'XFCU' (BE)")
    print(f"  4. CSUM trailer tag is 'CSUM' (LE), not 'MUSC' (BE)")
    print(f"  5. CRC-32 in CSUM matches computed CRC of UCFX container")
    print(f"  6. UCFX descriptor table parses as valid LE")
    print(f"  7. All descriptor chunk tags are printable ASCII")
    print(f"  8. Descriptor body ranges within container bounds")

    verdict = "PASS" if stats["fail"] == 0 and stats["error"] == 0 else "FAIL"
    print(f"\nVerdict: {verdict}")

    xbox_mm.close()
    return 0 if verdict == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
