#!/usr/bin/env python3
"""Validate sges compress/decompress round-trip against the base game vz.wad.

Parses the FFCS header, reads INDX entries, decompresses a representative
sample of blocks (including the largest), recompresses, re-decompresses,
and verifies byte-for-byte equality.
"""
from __future__ import annotations

import struct
import sys
import time
from pathlib import Path

THIS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(THIS_DIR))

from sges_decompress import decompress_sges_block
from sges_compress import compress_sges

PAGE_SIZE = 0x8000  # 32 KiB


def parse_ffcs_header(wad: bytes) -> dict:
    magic = wad[0:4]
    if magic != b"FFCS":
        raise ValueError(f"Bad magic: {magic!r}")
    version = struct.unpack_from("<I", wad, 4)[0]
    chunk_count = struct.unpack_from("<I", wad, 8)[0]

    rows = []
    for i in range(5):
        off = 0x0C + i * 12
        tag = wad[off:off + 4].decode("ascii", errors="replace")
        offset = struct.unpack_from("<I", wad, off + 4)[0]
        meta = struct.unpack_from("<I", wad, off + 8)[0]
        rows.append((tag, offset, meta))

    return {"version": version, "chunk_count": chunk_count, "rows": rows}


def find_indx(rows: list[tuple[str, int, int]]) -> tuple[int, int]:
    for tag, offset, meta in rows:
        if tag == "INDX":
            return offset, meta
    raise ValueError("INDX chunk not found in FFCS header")


def read_indx_entries(wad: bytes, indx_offset: int, block_count: int) -> list[dict]:
    entries = []
    for i in range(block_count):
        off = indx_offset + i * 12
        page_index, packed_field, flags_and_page_count = struct.unpack_from("<III", wad, off)
        decomp_pages = packed_field & 0x00FFFFFF
        comp_pages = flags_and_page_count & 0xFFFF
        entries.append({
            "index": i,
            "page_index": page_index,
            "packed_field": packed_field,
            "decomp_pages": decomp_pages,
            "flags_and_page_count": flags_and_page_count,
            "comp_pages": comp_pages,
        })
    return entries


def validate_ucfx_structure(data: bytes) -> str | None:
    """Light structural check: count(u32) + count*16 entry bytes, offsets walk correctly."""
    if len(data) < 4:
        return f"too short ({len(data)} bytes)"
    count = struct.unpack_from("<I", data, 0)[0]
    expected_header = 4 + count * 16
    if expected_header > len(data):
        return f"count={count} implies header {expected_header} bytes but data is {len(data)}"
    pos = expected_header
    for i in range(count):
        entry_off = 4 + i * 16
        chunk_tag = data[entry_off:entry_off + 4]
        chunk_size = struct.unpack_from("<I", data, entry_off + 4)[0]
        if pos + chunk_size > len(data):
            return f"entry[{i}] tag={chunk_tag!r} size={chunk_size} overflows at pos={pos} (data len={len(data)})"
        pos += chunk_size
    return None


def run_roundtrip(wad: bytes, entry: dict, wad_size: int) -> dict:
    idx = entry["index"]
    page_index = entry["page_index"]
    comp_pages = entry["comp_pages"]
    decomp_pages = entry["decomp_pages"]

    block_start = page_index * PAGE_SIZE
    block_len = comp_pages * PAGE_SIZE
    block_end = block_start + block_len

    if block_end > wad_size:
        return {"index": idx, "status": "SKIP", "reason": f"block extends past WAD end ({block_end} > {wad_size})"}

    comp_data = wad[block_start:block_end]
    if comp_data[:4] != b"sges":
        return {"index": idx, "status": "SKIP", "reason": f"no sges magic at offset 0x{block_start:X}"}

    try:
        decompressed = decompress_sges_block(comp_data, 0, len(comp_data))
    except Exception as e:
        return {"index": idx, "status": "FAIL", "phase": "decompress", "error": str(e)}

    decomp_size = len(decompressed)
    expected_max = decomp_pages * PAGE_SIZE
    expected_min = (decomp_pages - 1) * PAGE_SIZE if decomp_pages > 0 else 0
    size_ok = expected_min < decomp_size <= expected_max
    if not size_ok and decomp_pages > 0:
        size_note = f"decomp {decomp_size} not in ({expected_min}, {expected_max}]"
    else:
        size_note = None

    struct_err = validate_ucfx_structure(decompressed)

    try:
        recompressed = compress_sges(decompressed, segment_size=65536, level=6, major=4)
    except Exception as e:
        return {"index": idx, "status": "FAIL", "phase": "recompress", "error": str(e),
                "decomp_size": decomp_size, "size_note": size_note}

    try:
        re_decompressed = decompress_sges_block(recompressed, 0, len(recompressed))
    except Exception as e:
        return {"index": idx, "status": "FAIL", "phase": "re-decompress", "error": str(e),
                "decomp_size": decomp_size, "recomp_size": len(recompressed)}

    if re_decompressed == decompressed:
        return {
            "index": idx,
            "status": "PASS",
            "decomp_size": decomp_size,
            "recomp_size": len(recompressed),
            "orig_comp_size": len(comp_data),
            "size_note": size_note,
            "struct_err": struct_err,
        }
    else:
        first_diff = next((i for i in range(min(len(decompressed), len(re_decompressed)))
                           if decompressed[i] != re_decompressed[i]), None)
        return {
            "index": idx,
            "status": "FAIL",
            "phase": "compare",
            "decomp_size": decomp_size,
            "re_decomp_size": len(re_decompressed),
            "recomp_size": len(recompressed),
            "first_diff_offset": first_diff,
            "len_match": len(decompressed) == len(re_decompressed),
        }


def main() -> int:
    wad_path = Path(r"c:\Users\Shadow\Desktop\notes-on-the-released-game\game-files\vz.wad")
    if not wad_path.is_file():
        print(f"ERROR: WAD not found at {wad_path}", file=sys.stderr)
        return 1

    print(f"Loading WAD: {wad_path} ...", flush=True)
    t0 = time.time()
    wad = wad_path.read_bytes()
    wad_size = len(wad)
    print(f"  WAD size: {wad_size:,} bytes ({wad_size / (1024**3):.2f} GiB), loaded in {time.time() - t0:.1f}s")

    hdr = parse_ffcs_header(wad)
    print(f"  FFCS version: {hdr['version']}, chunk_count: {hdr['chunk_count']}")
    for tag, off, meta in hdr["rows"]:
        print(f"    {tag}  offset=0x{off:08X}  meta={meta}")

    indx_offset, block_count = find_indx(hdr["rows"])
    print(f"\n  INDX: offset=0x{indx_offset:08X}, block_count={block_count}")

    entries = read_indx_entries(wad, indx_offset, block_count)
    print(f"  Read {len(entries)} INDX entries")

    sorted_by_size = sorted(entries, key=lambda e: e["comp_pages"], reverse=True)

    top10 = sorted_by_size[:10]
    print(f"\n  Top 10 largest blocks by comp_pages:")
    for e in top10:
        print(f"    block[{e['index']:5d}]  comp_pages={e['comp_pages']:5d}  "
              f"decomp_pages={e['decomp_pages']:5d}  "
              f"page_index={e['page_index']:8d}")

    top10_indices = {e["index"] for e in top10}
    sample_indices = set()

    for e in sorted_by_size[:30]:
        sample_indices.add(e["index"])

    small_blocks = [e for e in entries if e["comp_pages"] > 0 and e["comp_pages"] <= 3]
    import random
    random.seed(42)
    if len(small_blocks) > 10:
        for e in random.sample(small_blocks, 10):
            sample_indices.add(e["index"])
    else:
        for e in small_blocks:
            sample_indices.add(e["index"])

    medium_blocks = [e for e in entries if 4 <= e["comp_pages"] <= 20]
    if len(medium_blocks) > 10:
        for e in random.sample(medium_blocks, 10):
            sample_indices.add(e["index"])
    else:
        for e in medium_blocks:
            sample_indices.add(e["index"])

    remaining = [e for e in entries if e["index"] not in sample_indices and e["comp_pages"] > 0]
    if len(remaining) > 0:
        needed = max(0, 50 - len(sample_indices))
        if needed > 0:
            for e in random.sample(remaining, min(needed, len(remaining))):
                sample_indices.add(e["index"])

    sample_entries = [e for e in entries if e["index"] in sample_indices]
    sample_entries.sort(key=lambda e: e["index"])

    print(f"\n{'='*72}")
    print(f"Testing {len(sample_entries)} blocks (top 30 largest + small + medium + random fill)")
    print(f"{'='*72}\n")

    results = []
    pass_count = 0
    fail_count = 0
    skip_count = 0

    for i, entry in enumerate(sample_entries):
        idx = entry["index"]
        is_top10 = idx in top10_indices
        marker = " [TOP-10]" if is_top10 else ""

        t1 = time.time()
        result = run_roundtrip(wad, entry, wad_size)
        elapsed = time.time() - t1

        status = result["status"]
        if status == "PASS":
            pass_count += 1
            decomp_kb = result["decomp_size"] / 1024
            recomp_kb = result["recomp_size"] / 1024
            orig_kb = result["orig_comp_size"] / 1024
            notes = []
            if result.get("size_note"):
                notes.append(result["size_note"])
            if result.get("struct_err"):
                notes.append(f"struct: {result['struct_err']}")
            note_str = f"  ({'; '.join(notes)})" if notes else ""
            print(f"  [{i+1:3d}/{len(sample_entries)}] block[{idx:5d}] PASS  "
                  f"decomp={decomp_kb:10.1f}K  recomp={recomp_kb:10.1f}K  "
                  f"orig={orig_kb:10.1f}K  {elapsed:.2f}s{marker}{note_str}")
        elif status == "SKIP":
            skip_count += 1
            print(f"  [{i+1:3d}/{len(sample_entries)}] block[{idx:5d}] SKIP  {result['reason']}{marker}")
        else:
            fail_count += 1
            print(f"  [{i+1:3d}/{len(sample_entries)}] block[{idx:5d}] FAIL  phase={result.get('phase','?')}  "
                  f"error={result.get('error','?')}{marker}")
            for k, v in result.items():
                if k not in ("index", "status", "phase", "error"):
                    print(f"      {k} = {v}")

        results.append(result)

    print(f"\n{'='*72}")
    print(f"RESULTS: {pass_count} passed, {fail_count} failed, {skip_count} skipped "
          f"(out of {len(sample_entries)} tested)")
    print(f"{'='*72}")

    if fail_count > 0:
        print(f"\nFAILED BLOCKS:")
        for r in results:
            if r["status"] == "FAIL":
                print(f"  block[{r['index']}]: phase={r.get('phase','?')}")
                for k, v in r.items():
                    if k not in ("index", "status"):
                        print(f"    {k} = {v}")

    top10_results = [r for r in results if r["index"] in top10_indices]
    top10_pass = sum(1 for r in top10_results if r["status"] == "PASS")
    top10_fail = sum(1 for r in top10_results if r["status"] == "FAIL")
    print(f"\nTOP-10 LARGEST: {top10_pass} passed, {top10_fail} failed "
          f"(out of {len(top10_results)} tested)")

    if fail_count > 0:
        return 1
    print("\nAll round-trips passed!")
    return 0


if __name__ == "__main__":
    sys.exit(main())
