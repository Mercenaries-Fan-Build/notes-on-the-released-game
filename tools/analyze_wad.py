#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Analyze Mercenaries 2 FFCS .wad files — deep structure inspection.

Parses FFCS header, INDX block table, PTHS path strings, decompresses sges
blocks, and identifies content types (UCFX, Havok, textures, stringdb, etc.).
"""

from __future__ import annotations

import argparse
import json
import struct
import sys
import zlib
from collections import Counter
from dataclasses import dataclass, field
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from ffcs_wad import HEADER_MAGIC, dump_paths_from_pths, parse_ffcs, extract_slice  # noqa: E402
from sges_decompress import (  # noqa: E402
    SGES_MAGIC,
    decompress_sges_block,
    find_sges_offsets,
    parse_sges_header,
)


@dataclass
class BlockInfo:
    index: int
    path: str
    sges_offset: int
    sges_end: int
    compressed_size: int
    uncompressed_size: int
    decompressed_size: int
    content_type: str
    ucfx_tags: list[str] = field(default_factory=list)
    has_havok: bool = False
    has_dxt: bool = False
    has_stringdb: bool = False
    ascii_strings_sample: list[str] = field(default_factory=list)
    error: str | None = None


def identify_content(data: bytes) -> tuple[str, list[str], bool, bool, bool]:
    """Identify the content type of a decompressed block."""
    if len(data) < 4:
        return "empty", [], False, False, False

    tags: list[str] = []
    has_havok = False
    has_dxt = False
    has_stringdb = False

    # Check for UCFX magic
    if data[:4] == b"UCFX":
        content_type = "ucfx"
    elif data[:4] == b"CERP":
        content_type = "cerp_precache"
    elif data[:4] == b"RIFF":
        content_type = "riff_audio"
    elif data[:4] == b"OggS":
        content_type = "ogg_audio"
    elif b"hkxp" in data[:256] or b"Havok" in data[:512]:
        content_type = "havok_standalone"
        has_havok = True
    else:
        # Check for block file structure: count(4) + count*entry(16) + UCFX chunks
        count = struct.unpack_from("<I", data, 0)[0]
        if 1 <= count <= 5000:
            expected_toc_end = 4 + count * 16
            if expected_toc_end < len(data):
                # Check if UCFX magic follows TOC
                ucfx_check_pos = expected_toc_end
                if ucfx_check_pos + 4 <= len(data) and data[ucfx_check_pos:ucfx_check_pos + 4] == b"UCFX":
                    content_type = "block_file"
                else:
                    content_type = "unknown"
            else:
                content_type = "unknown"
        else:
            content_type = "unknown"

    # Scan for UCFX chunk tags
    ucfx_tag_set = {
        b"GEOM", b"MESH", b"PRMG", b"STRM", b"IBUF", b"INFO", b"MTRL",
        b"PRMT", b"HIER", b"SWIT", b"NAME", b"BODY", b"CHDR", b"COMP",
        b"STAT", b"CEXE", b"INDX", b"BNDS", b"SYEK", b"SRTS", b"CSUM",
    }
    pos = 0
    scan_limit = min(len(data), 1024 * 1024)  # scan first 1 MB
    while pos < scan_limit - 4:
        chunk = data[pos:pos + 4]
        if chunk in ucfx_tag_set:
            tag_str = chunk.decode("ascii")
            if tag_str not in tags:
                tags.append(tag_str)
        pos += 1

    # Check for Havok signatures
    if b"Havok" in data or b"hkxp" in data or b"hkaAnimationBinding" in data:
        has_havok = True

    # Check for DXT texture data
    if b"DXT1" in data or b"DXT3" in data or b"DXT5" in data:
        has_dxt = True

    # Check for stringdb (SYEK/SRTS)
    if b"SYEK" in data or b"SRTS" in data:
        has_stringdb = True

    return content_type, tags, has_havok, has_dxt, has_stringdb


def extract_ascii_strings(data: bytes, min_len: int = 8, max_strings: int = 20) -> list[str]:
    """Extract printable ASCII strings from binary data."""
    strings = []
    current = []
    for b in data[:min(len(data), 512 * 1024)]:
        if 0x20 <= b < 0x7F:
            current.append(chr(b))
        else:
            if len(current) >= min_len:
                s = "".join(current)
                if s not in strings:
                    strings.append(s)
                    if len(strings) >= max_strings:
                        return strings
            current = []
    if len(current) >= min_len:
        s = "".join(current)
        if s not in strings:
            strings.append(s)
    return strings


def parse_indx_entries(indx_blob: bytes) -> list[tuple[int, int, int]]:
    """Parse INDX block entries: 12 bytes each (page_index, packed_field, flags_and_page_count)."""
    entries = []
    off = 0
    while off + 12 <= len(indx_blob):
        page_index, packed_field, flags_and_page_count = struct.unpack_from("<III", indx_blob, off)
        entries.append((page_index, packed_field, flags_and_page_count))
        off += 12
    return entries


def parse_block_file_toc(data: bytes) -> list[dict]:
    """Parse block file TOC: count(4) + count*entry(16)."""
    if len(data) < 4:
        return []
    count = struct.unpack_from("<I", data, 0)[0]
    if count < 1 or count > 50000:
        return []
    entries = []
    off = 4
    for i in range(count):
        if off + 16 > len(data):
            break
        name_hash, type_hash, field_c, chunk_size = struct.unpack_from("<IIII", data, off)
        entries.append({
            "index": i,
            "name_hash": f"0x{name_hash:08X}",
            "type_hash": f"0x{type_hash:08X}",
            "field_c": field_c,
            "chunk_size": chunk_size,
        })
        off += 16
    return entries


def analyze_wad(wad_path: Path, max_decompress: int = 50, decompress_all: bool = False) -> dict:
    """Full analysis of a .wad file."""
    raw = wad_path.read_bytes()
    file_size = len(raw)

    # Parse FFCS header
    arch = parse_ffcs(wad_path)

    result = {
        "file": str(wad_path),
        "file_size": file_size,
        "file_size_mb": round(file_size / (1024 * 1024), 2),
        "version": arch.version,
        "declared_chunk_count": arch.chunk_count,
        "chunks": [],
    }

    for c in arch.chunks:
        result["chunks"].append({
            "tag": c.tag,
            "offset": f"0x{c.offset:08X}",
            "offset_dec": c.offset,
            "meta": c.meta,
            "size": c.size,
            "size_kb": round(c.size / 1024, 1) if c.size > 0 else 0,
        })

    # Extract and parse INDX
    indx_chunk = next((c for c in arch.chunks if c.tag == "INDX"), None)
    if indx_chunk and indx_chunk.size > 0:
        indx_blob = extract_slice(raw, indx_chunk)
        indx_entries = parse_indx_entries(indx_blob)
        result["indx_block_count"] = len(indx_entries)

        # Compute block offsets from INDX
        block_offsets = []
        for page_idx, packed, flags_pages in indx_entries:
            wad_offset = page_idx * 0x8000
            page_count = flags_pages & 0xFFFF
            block_offsets.append({
                "page_index": page_idx,
                "wad_offset": f"0x{wad_offset:08X}",
                "wad_offset_dec": wad_offset,
                "page_count": page_count,
                "packed_field": f"0x{packed:08X}",
                "flags": f"0x{(flags_pages >> 16):04X}",
            })
        result["indx_entries_sample"] = block_offsets[:20]
    else:
        result["indx_block_count"] = 0

    # Extract and parse PTHS
    pths_chunk = next((c for c in arch.chunks if c.tag == "PTHS"), None)
    paths: list[str] = []
    if pths_chunk and pths_chunk.size > 0:
        pths_blob = extract_slice(raw, pths_chunk)
        paths = dump_paths_from_pths(pths_blob)
        result["pths_path_count"] = len(paths)
        result["pths_paths_sample"] = paths[:50]
        result["pths_paths_all"] = paths
    else:
        result["pths_path_count"] = 0
        result["pths_paths_all"] = []

    # Find sges blocks in DATA chunk
    data_chunk = next((c for c in arch.chunks if c.tag == "DATA"), None)
    if data_chunk and data_chunk.size > 0:
        data_blob = extract_slice(raw, data_chunk)
        sges_offsets = find_sges_offsets(data_blob)
        result["sges_block_count"] = len(sges_offsets)
        result["data_chunk_size"] = data_chunk.size
        result["data_chunk_size_mb"] = round(data_chunk.size / (1024 * 1024), 2)

        # Decompress and analyze blocks
        blocks_info: list[dict] = []
        content_types = Counter()
        total_decompressed = 0

        n_to_decompress = len(sges_offsets) if decompress_all else min(max_decompress, len(sges_offsets))

        for i in range(n_to_decompress):
            off = sges_offsets[i]
            end = sges_offsets[i + 1] if i + 1 < len(sges_offsets) else len(data_blob)
            path_name = paths[i] if i < len(paths) else f"block_{i:05d}"

            try:
                _maj, _mn, total_u, _tc = parse_sges_header(data_blob, off)
                decompressed = decompress_sges_block(data_blob, off, end)
                content_type, ucfx_tags, has_havok, has_dxt, has_stringdb = identify_content(decompressed)
                ascii_sample = extract_ascii_strings(decompressed, min_len=10, max_strings=10)

                block_entry = {
                    "index": i,
                    "path": path_name,
                    "sges_offset": f"0x{off:08X}",
                    "compressed_size": end - off,
                    "declared_uncompressed": total_u,
                    "actual_decompressed": len(decompressed),
                    "content_type": content_type,
                    "ucfx_tags": ucfx_tags,
                    "has_havok": has_havok,
                    "has_dxt": has_dxt,
                    "has_stringdb": has_stringdb,
                    "ascii_strings_sample": ascii_sample,
                }

                # For block_file type, parse TOC
                if content_type == "block_file":
                    toc = parse_block_file_toc(decompressed)
                    block_entry["block_file_entry_count"] = len(toc)
                    if toc:
                        block_entry["block_file_toc_sample"] = toc[:5]

                blocks_info.append(block_entry)
                content_types[content_type] += 1
                total_decompressed += len(decompressed)

            except Exception as e:
                blocks_info.append({
                    "index": i,
                    "path": path_name,
                    "error": str(e),
                })
                content_types["error"] += 1

        result["blocks_analyzed"] = len(blocks_info)
        result["blocks_total_decompressed_mb"] = round(total_decompressed / (1024 * 1024), 2)
        result["content_type_distribution"] = dict(content_types.most_common())
        result["blocks"] = blocks_info

        # Tag frequency across all analyzed blocks
        tag_freq = Counter()
        for b in blocks_info:
            for tag in b.get("ucfx_tags", []):
                tag_freq[tag] += 1
        result["ucfx_tag_frequency"] = dict(tag_freq.most_common())
    else:
        result["sges_block_count"] = 0

    # ASET chunk analysis
    aset_chunk = next((c for c in arch.chunks if c.tag == "ASET"), None)
    if aset_chunk and aset_chunk.size > 0:
        aset_blob = extract_slice(raw, aset_chunk)
        # ASET is 16-byte rows
        aset_entry_count = len(aset_blob) // 16
        result["aset_entry_count"] = aset_entry_count
        aset_sample = []
        for i in range(min(20, aset_entry_count)):
            u0, u1, u2, u3 = struct.unpack_from("<IIII", aset_blob, i * 16)
            aset_sample.append({
                "index": i,
                "u0_hash": f"0x{u0:08X}",
                "u1_type": f"0x{u1:08X}",
                "u2": u2,
                "u3_size": u3,
            })
        result["aset_sample"] = aset_sample
    else:
        result["aset_entry_count"] = 0

    return result


def print_summary(analysis: dict) -> None:
    """Print a human-readable summary."""
    print(f"\n{'='*70}")
    print(f"WAD Analysis: {analysis['file']}")
    print(f"{'='*70}")
    print(f"File size: {analysis['file_size_mb']} MB ({analysis['file_size']:,} bytes)")
    print(f"FFCS version: {analysis['version']}")
    print(f"Declared chunk count: {analysis['declared_chunk_count']}")
    print()

    print("FFCS Chunks:")
    for c in analysis["chunks"]:
        print(f"  {c['tag']:5s} offset={c['offset']}  meta={c['meta']:8d}  size={c['size_kb']:,.1f} KB")
    print()

    print(f"INDX block count: {analysis['indx_block_count']}")
    print(f"PTHS path count: {analysis['pths_path_count']}")
    print(f"ASET entry count: {analysis['aset_entry_count']}")
    print()

    if analysis.get("sges_block_count", 0) > 0:
        print(f"DATA chunk: {analysis['data_chunk_size_mb']} MB")
        print(f"sges blocks found: {analysis['sges_block_count']}")
        print(f"Blocks analyzed: {analysis['blocks_analyzed']}")
        print(f"Total decompressed: {analysis['blocks_total_decompressed_mb']} MB")
        print()

        print("Content type distribution:")
        for ct, count in analysis.get("content_type_distribution", {}).items():
            print(f"  {ct:20s}: {count}")
        print()

        print("UCFX tag frequency (across analyzed blocks):")
        for tag, count in analysis.get("ucfx_tag_frequency", {}).items():
            print(f"  {tag:6s}: {count}")
        print()

        if analysis.get("pths_path_count", 0) > 0:
            print(f"Path strings (first 30):")
            for p in analysis.get("pths_paths_sample", [])[:30]:
                print(f"  {p}")


def main() -> int:
    ap = argparse.ArgumentParser(description="Analyze Mercenaries 2 FFCS .wad file structure")
    ap.add_argument("wad", type=Path, nargs="+", help="Path to .wad file(s)")
    ap.add_argument("--json", type=Path, help="Write JSON analysis to file")
    ap.add_argument("--max-blocks", type=int, default=0, help="Max blocks to decompress (0 = all)")
    ap.add_argument("--summary", action="store_true", help="Print human-readable summary")
    args = ap.parse_args()

    all_results = {}
    for wad_path in args.wad:
        if not wad_path.is_file():
            print(f"ERROR: {wad_path} not found", file=sys.stderr)
            continue

        decompress_all = args.max_blocks == 0
        max_d = args.max_blocks if args.max_blocks > 0 else 9999

        print(f"Analyzing {wad_path.name}...")
        analysis = analyze_wad(wad_path, max_decompress=max_d, decompress_all=decompress_all)
        all_results[wad_path.name] = analysis

        if args.summary:
            print_summary(analysis)

    if args.json:
        args.json.parent.mkdir(parents=True, exist_ok=True)
        args.json.write_text(json.dumps(all_results, indent=2, default=str), encoding="utf-8")
        print(f"\nJSON written to: {args.json}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
