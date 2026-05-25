#!/usr/bin/env python3
"""Audit DLC patch data against base game ground truth.

For every entry hash in the DLC that ALSO exists in the base game's vz.wad,
extracts both the converted (patch) version and the known-good PC version,
then does a byte-for-byte comparison.

This is the only reliable validation method: binary identity with ground truth.
No heuristics, no guesswork.

Reports:
  - MATCH: converted output == base game (conversion correct)
  - MISMATCH: converted output != base game (conversion BUG)
  - OVERRIDE: entry was copied from base game (skip comparison)
  - UNIQUE: entry only exists in DLC (no ground truth available)

Usage:
    python tools/audit_dlc_conversion.py \
        --patch-wad output/data/vz-patch.wad \
        --source-wad "game-files/Mercenaries 2 World in Flames/data/vz.wad"
"""
from __future__ import annotations

import argparse
import mmap
import struct
import sys
from collections import defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from sges_decompress import decompress_sges_block  # noqa: E402
from wad_patcher import find_data_chunk, get_block_boundaries, parse_block_entries  # noqa: E402

TYPE_NAMES = {
    0xF011157A: "texture",
    0x42498680: "script",
    0x207359C7: "stance",
    0x18166555: "animation",
    0xBCFE6314: "path",
    0xECE70371: "state_machine",
    0xE6B81A54: "ecs_node",
    0x5B724250: "mesh_B",
    0x7C569307: "mesh_A",
    0x600B904E: "mesh_C",
    0x39E5E978: "stringdb",
    0xE5273C14: "unknown_E5",
}

_OVERRIDE_TYPES = frozenset({
    0xF011157A,  # texture
    0x18166555,  # animation
    0x5B724250,  # mesh_B
    0x207359C7,  # stance
    0xE5273C14,  # unknown_E5 / audio group — PC retail graph, not Xbox DLC bytes
})


def _entry_payload(data: bytes) -> bytes:
    """Strip trailing padding so override entries with different slot sizes compare."""
    return data.rstrip(b"\x00")


def _extract_all_entries(wad_path: Path) -> dict[tuple[int, int], bytes]:
    """Extract all entries from a WAD → {(hash, type_hash): raw_entry_bytes}."""
    dc = find_data_chunk(wad_path)
    result: dict[tuple[int, int], bytes] = {}

    with open(wad_path, "rb") as f:
        mm = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)
        boundaries = get_block_boundaries(mm, dc.offset, dc.size)

        for blk_idx in range(len(boundaries)):
            s, e = boundaries[blk_idx]
            try:
                data = decompress_sges_block(mm, s, e)
            except Exception:
                continue

            try:
                entries = parse_block_entries(data)
            except Exception:
                continue

            header_end = 4 + len(entries) * 16
            for ent in entries:
                eh = ent["hash"]
                th = ent["type_hash"]
                eoff = ent["offset"]
                esize = ent["size"]
                if eoff + esize > len(data):
                    continue
                ucfx_raw = data[eoff:eoff + esize]
                key = (eh, th)
                if key not in result:
                    result[key] = ucfx_raw

        mm.close()
    return result


def _extract_entries_by_block(wad_path: Path) -> list[list[dict]]:
    """Extract entries grouped by block → [[{hash, type_hash, data}...], ...]."""
    dc = find_data_chunk(wad_path)
    blocks = []

    with open(wad_path, "rb") as f:
        mm = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)
        boundaries = get_block_boundaries(mm, dc.offset, dc.size)

        for blk_idx in range(len(boundaries)):
            s, e = boundaries[blk_idx]
            block_entries = []
            try:
                data = decompress_sges_block(mm, s, e)
            except Exception:
                blocks.append(block_entries)
                continue

            try:
                entries = parse_block_entries(data)
            except Exception:
                blocks.append(block_entries)
                continue

            for ent in entries:
                eh = ent["hash"]
                th = ent["type_hash"]
                eoff = ent["offset"]
                esize = ent["size"]
                if eoff + esize > len(data):
                    continue
                ucfx_raw = data[eoff:eoff + esize]
                block_entries.append({
                    "hash": eh,
                    "type_hash": th,
                    "data": ucfx_raw,
                })
            blocks.append(block_entries)

        mm.close()
    return blocks


def _diff_bytes(a: bytes, b: bytes, max_diffs: int = 5) -> list[str]:
    """Report first N byte-level differences between two buffers."""
    diffs = []
    min_len = min(len(a), len(b))
    for i in range(min_len):
        if a[i] != b[i]:
            diffs.append(f"  offset {i} (0x{i:04X}): patch=0x{a[i]:02X} base=0x{b[i]:02X}")
            if len(diffs) >= max_diffs:
                break
    if len(a) != len(b) and len(diffs) < max_diffs:
        diffs.append(f"  SIZE MISMATCH: patch={len(a)} base={len(b)}")
    return diffs


def _find_ucfx_tags(data: bytes) -> list[tuple[str, int, int]]:
    """Parse UCFX descriptor table → [(tag, offset, size), ...]."""
    pos = data.find(b"UCFX")
    if pos < 0:
        return []
    c = data[pos:]
    if len(c) < 20:
        return []
    dao = struct.unpack_from("<I", c, 4)[0]
    n = struct.unpack_from("<I", c, 16)[0]
    if n > 5000:
        return []
    tags = []
    for i in range(n):
        doff = 20 + i * 20
        if doff + 20 > len(c):
            break
        tag = c[doff:doff+4].decode("ascii", "replace")
        u0, bs = struct.unpack_from("<II", c, doff + 4)
        tags.append((tag, u0, bs))
    return tags


def main():
    parser = argparse.ArgumentParser(description="Audit DLC conversion against base game ground truth")
    parser.add_argument("--patch-wad", type=Path, required=True)
    parser.add_argument("--source-wad", type=Path, required=True)
    parser.add_argument("--verbose", "-v", action="store_true")
    parser.add_argument("--show-diffs", action="store_true",
                        help="Show byte-level differences for mismatches")
    args = parser.parse_args()

    if not args.patch_wad.exists():
        print(f"ERROR: {args.patch_wad} not found")
        return 1
    if not args.source_wad.exists():
        print(f"ERROR: {args.source_wad} not found")
        return 1

    print(f"Loading base game entries from {args.source_wad}...")
    print("  (this indexes ALL entries in the base game WAD)")
    base_entries = _extract_all_entries(args.source_wad)
    print(f"  Indexed {len(base_entries):,} entries from base game\n")

    print(f"Loading patch WAD entries from {args.patch_wad}...")
    patch_blocks = _extract_entries_by_block(args.patch_wad)
    total_patch = sum(len(b) for b in patch_blocks)
    print(f"  {total_patch} entries across {len(patch_blocks)} blocks\n")

    # Categorize and compare
    results = {
        "MATCH": [],
        "MISMATCH": [],
        "OVERRIDE": [],
        "UNIQUE": [],
    }

    for blk_idx, block in enumerate(patch_blocks):
        for ent in block:
            eh = ent["hash"]
            th = ent["type_hash"]
            patch_data = ent["data"]

            key = (eh, th)
            if key not in base_entries:
                results["UNIQUE"].append((blk_idx, eh, th, None))
                continue

            base_data = base_entries[key]

            if th in _OVERRIDE_TYPES:
                if _entry_payload(patch_data) == _entry_payload(base_data):
                    results["OVERRIDE"].append((blk_idx, eh, th, None))
                else:
                    diff = _diff_bytes(
                        _entry_payload(patch_data),
                        _entry_payload(base_data),
                    )
                    results["MISMATCH"].append((blk_idx, eh, th, diff))
                continue

            # Non-override type: compare converted output to base game
            if patch_data == base_data:
                results["MATCH"].append((blk_idx, eh, th, None))
            else:
                diff = _diff_bytes(patch_data, base_data)
                results["MISMATCH"].append((blk_idx, eh, th, diff))

    # Report
    print("=" * 70)
    print("AUDIT RESULTS")
    print("=" * 70)
    print(f"\n  Total patch entries: {total_patch}")
    print(f"  MATCH (identical to base game):    {len(results['MATCH']):4d}")
    print(f"  OVERRIDE (copied from base game):  {len(results['OVERRIDE']):4d}")
    print(f"  MISMATCH (differs from base game): {len(results['MISMATCH']):4d}")
    print(f"  UNIQUE (DLC-only, no ground truth):{len(results['UNIQUE']):4d}")

    # Breakdown by type
    print("\n" + "-" * 70)
    print("BREAKDOWN BY TYPE")
    print("-" * 70)

    by_type: dict[int, dict[str, int]] = defaultdict(lambda: defaultdict(int))
    for cat in ("MATCH", "MISMATCH", "OVERRIDE", "UNIQUE"):
        for (blk, eh, th, _) in results[cat]:
            by_type[th][cat] += 1

    print(f"\n  {'Type':<20} {'MATCH':>6} {'OVERRIDE':>9} {'MISMATCH':>9} {'UNIQUE':>7} {'Total':>6}")
    print(f"  {'-'*20} {'-'*6} {'-'*9} {'-'*9} {'-'*7} {'-'*6}")
    for th in sorted(by_type.keys(), key=lambda t: sum(by_type[t].values()), reverse=True):
        tname = TYPE_NAMES.get(th, f"0x{th:08X}")
        m = by_type[th]["MATCH"]
        o = by_type[th]["OVERRIDE"]
        mm_ = by_type[th]["MISMATCH"]
        u = by_type[th]["UNIQUE"]
        t = m + o + mm_ + u
        flag = " <<<" if mm_ > 0 else ""
        print(f"  {tname:<20} {m:>6} {o:>9} {mm_:>9} {u:>7} {t:>6}{flag}")

    # Detail on mismatches
    if results["MISMATCH"]:
        print("\n" + "-" * 70)
        print(f"MISMATCH DETAILS ({len(results['MISMATCH'])} entries)")
        print("-" * 70)
        for blk_idx, eh, th, diff in results["MISMATCH"][:30]:
            tname = TYPE_NAMES.get(th, f"0x{th:08X}")
            print(f"\n  block {blk_idx}, hash 0x{eh:08X} ({tname}):")
            if args.show_diffs and diff:
                for d in diff:
                    print(f"    {d}")
            # Show tag structure
            patch_ent = None
            for ent in patch_blocks[blk_idx]:
                if ent["hash"] == eh:
                    patch_ent = ent["data"]
                    break
            if patch_ent:
                tags = _find_ucfx_tags(patch_ent)
                if tags:
                    print(f"    tags: {[(t, s) for t, _, s in tags]}")

        if len(results["MISMATCH"]) > 30:
            print(f"\n  ... and {len(results['MISMATCH']) - 30} more")

    # Summary verdict
    print("\n" + "=" * 70)
    if not results["MISMATCH"]:
        print("VERDICT: All shared entries match base game. Conversion is correct.")
        print(f"         {len(results['UNIQUE'])} DLC-unique entries have no ground truth.")
    else:
        print(f"VERDICT: {len(results['MISMATCH'])} MISMATCHES detected.")
        print("         These entries exist in base game but our conversion differs.")
        print("         Each mismatch is a proven conversion bug.")
    print("=" * 70)

    return 1 if results["MISMATCH"] else 0


if __name__ == "__main__":
    sys.exit(main())
