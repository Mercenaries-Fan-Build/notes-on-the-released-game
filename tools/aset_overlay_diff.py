#!/usr/bin/env python3
"""ASET overlay analysis — compare base vz.wad and vz-patch.wad ASET tables.

Shows which entries the patch WAD shadows (overrides) vs introduces new,
with field-level diffs for secondary_ref and sub_offset.
"""
from __future__ import annotations

import argparse
import struct
import sys
from collections import Counter
from pathlib import Path

TYPE_NAMES = {
    0: "type0", 3: "binary", 5: "unk5", 6: "wavebank", 7: "stringdb",
    9: "layer", 11: "unk11", 12: "unk12_shader", 13: "unk13", 14: "unk14",
    15: "font", 16: "animation", 18: "unk18", 19: "model", 20: "level",
    21: "soundbank", 22: "lowresterrain", 23: "unk23", 27: "texture",
    28: "path", 29: "effect", 30: "unk30_global", 32: "terrainmesh",
    34: "unk34", 35: "script",
}


def parse_ffcs_header(raw: bytes) -> dict[str, tuple[int, int]]:
    chunks: dict[str, tuple[int, int]] = {}
    for i in range(5):
        off = 0x0C + i * 12
        tag = raw[off:off + 4].decode("ascii")
        offset, meta = struct.unpack_from("<II", raw, off + 4)
        chunks[tag] = (offset, meta)
    return chunks


def parse_aset_table(raw: bytes, aset_offset: int, count: int) -> list[dict]:
    entries = []
    for i in range(count):
        off = aset_offset + i * 16
        u0, u1, u2, u3 = struct.unpack_from("<IIII", raw, off)
        entries.append({
            "hash": u0,
            "secondary_ref": u1,
            "block_idx": (u2 >> 16) & 0xFFFF,
            "sub_offset": u2 & 0xFFFF,
            "type_id": u3,
            "u2_raw": u2,
        })
    return entries


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("base_wad", type=Path, help="Path to base vz.wad")
    ap.add_argument("patch_wad", type=Path, help="Path to vz-patch.wad")
    ap.add_argument("--show-all-diffs", action="store_true",
                    help="Show all field diffs (not just first 20)")
    args = ap.parse_args()

    # Read headers + ASET regions
    base_raw = args.base_wad.read_bytes()
    patch_raw = args.patch_wad.read_bytes()

    base_chunks = parse_ffcs_header(base_raw)
    patch_chunks = parse_ffcs_header(patch_raw)

    base_aset_off, base_aset_count = base_chunks["ASET"]
    patch_aset_off, patch_aset_count = patch_chunks["ASET"]

    base_entries = parse_aset_table(base_raw, base_aset_off, base_aset_count)
    patch_entries = parse_aset_table(patch_raw, patch_aset_off, patch_aset_count)

    print(f"Base ASET:  {len(base_entries):,} entries")
    print(f"Patch ASET: {len(patch_entries):,} entries")

    # FFCS header comparison
    print("\n=== FFCS HEADER COMPARISON ===")
    for tag in ["INDX", "DATA", "CSUM", "ASET", "PTHS"]:
        bo, bm = base_chunks[tag]
        po, pm = patch_chunks[tag]
        flag = " <-- DIFF" if bm != pm and tag != "INDX" and tag != "ASET" and tag != "PTHS" else ""
        print(f"  {tag}: base(offset=0x{bo:08X}, meta={bm:>10,}) "
              f"patch(offset=0x{po:08X}, meta={pm:>10,}){flag}")

    # Build lookups by (hash, type_id)
    base_by_key: dict[tuple[int, int], list[dict]] = {}
    for e in base_entries:
        key = (e["hash"], e["type_id"])
        base_by_key.setdefault(key, []).append(e)

    patch_by_key: dict[tuple[int, int], list[dict]] = {}
    for e in patch_entries:
        key = (e["hash"], e["type_id"])
        patch_by_key.setdefault(key, []).append(e)

    # Overlay analysis
    shadows = set(base_by_key.keys()) & set(patch_by_key.keys())
    patch_only = set(patch_by_key.keys()) - set(base_by_key.keys())

    print(f"\nShadowed entries (same hash+type in both):  {len(shadows):,}")
    print(f"Patch-only entries (new in DLC):             {len(patch_only):,}")

    # Type distribution
    shadow_types = Counter(tid for _, tid in shadows)
    patch_only_types = Counter(tid for _, tid in patch_only)

    print("\n=== SHADOWED entries by type_id ===")
    for tid, cnt in sorted(shadow_types.items()):
        name = TYPE_NAMES.get(tid, f"unk{tid}")
        print(f"  type_id={tid:2d} ({name:20s}): {cnt:5d} entries")

    print("\n=== PATCH-ONLY entries by type_id ===")
    for tid, cnt in sorted(patch_only_types.items()):
        name = TYPE_NAMES.get(tid, f"unk{tid}")
        print(f"  type_id={tid:2d} ({name:20s}): {cnt:5d} entries")

    # Audio analysis
    print("\n=== AUDIO ENTRIES ===")
    for tid_check in [6, 21]:
        name = TYPE_NAMES.get(tid_check, "?")
        in_base = sum(1 for _, tid in base_by_key if tid == tid_check)
        in_patch = sum(1 for _, tid in patch_by_key if tid == tid_check)
        shadowed = sum(1 for _, tid in shadows if tid == tid_check)
        new = sum(1 for _, tid in patch_only if tid == tid_check)
        print(f"  {name:12s}: base={in_base:3d}, patch={in_patch:3d}, "
              f"shadowed={shadowed:3d}, new={new:3d}")

    # Field-level diffs for shadowed entries
    print("\n=== FIELD DIFFS FOR SHADOWED ENTRIES ===")

    diff_secref = []
    diff_suboff = []
    for key in sorted(shadows):
        be = base_by_key[key][0]
        pe = patch_by_key[key][0]
        if be["secondary_ref"] != pe["secondary_ref"]:
            diff_secref.append((key, be, pe))
        if be["sub_offset"] != pe["sub_offset"]:
            diff_suboff.append((key, be, pe))

    print(f"\nsecondary_ref differences: {len(diff_secref)}")
    limit = len(diff_secref) if args.show_all_diffs else min(30, len(diff_secref))
    for key, be, pe in diff_secref[:limit]:
        name = TYPE_NAMES.get(key[1], f"unk{key[1]}")
        print(f"  hash=0x{key[0]:08X} type={name:20s} "
              f"base=0x{be['secondary_ref']:08X} "
              f"patch=0x{pe['secondary_ref']:08X}")

    print(f"\nsub_offset differences: {len(diff_suboff)}")
    for key, be, pe in diff_suboff[:limit]:
        name = TYPE_NAMES.get(key[1], f"unk{key[1]}")
        print(f"  hash=0x{key[0]:08X} type={name:20s} "
              f"base=0x{be['sub_offset']:04X} "
              f"patch=0x{pe['sub_offset']:04X}")

    # Check for ASET entries with u32_3 (type_id) that look wrong
    print("\n=== PATCH ASET SANITY CHECKS ===")
    bad_type_ids = [e for e in patch_entries if e["type_id"] > 35]
    print(f"  Entries with type_id > 35: {len(bad_type_ids)}")
    for e in bad_type_ids[:10]:
        print(f"    hash=0x{e['hash']:08X} type_id={e['type_id']} "
              f"secref=0x{e['secondary_ref']:08X}")

    # Check for duplicate hashes within patch
    patch_hash_counts = Counter(e["hash"] for e in patch_entries)
    dupes = [(h, c) for h, c in patch_hash_counts.items() if c > 1]
    print(f"  Duplicate hashes in patch ASET: {len(dupes)}")
    if dupes:
        for h, c in sorted(dupes, key=lambda x: -x[1])[:20]:
            entries_for_hash = [e for e in patch_entries if e["hash"] == h]
            types = set(e["type_id"] for e in entries_for_hash)
            secrefs = set(e["secondary_ref"] for e in entries_for_hash)
            print(f"    hash=0x{h:08X} count={c} "
                  f"types={[TYPE_NAMES.get(t, t) for t in types]} "
                  f"secrefs=[{', '.join(f'0x{s:08X}' for s in secrefs)}]")

    # CSUM meta analysis
    print("\n=== CSUM META ANALYSIS ===")
    base_csum_off, base_csum_meta = base_chunks["CSUM"]
    patch_csum_off, patch_csum_meta = patch_chunks["CSUM"]
    print(f"  Base:  CSUM offset=0x{base_csum_off:08X} (CRC value), meta={base_csum_meta}")
    print(f"  Patch: CSUM offset=0x{patch_csum_off:08X} (CRC value), meta={patch_csum_meta}")
    print(f"  Base ASET count:  {base_aset_count}")
    print(f"  Patch ASET count: {patch_aset_count}")
    if base_csum_meta != base_aset_count:
        print(f"  NOTE: Base CSUM.meta ({base_csum_meta}) != Base ASET.meta ({base_aset_count})")
        print(f"        Difference: {base_aset_count - base_csum_meta}")
    if patch_csum_meta == patch_aset_count:
        print(f"  Patch CSUM.meta == Patch ASET.meta (both {patch_csum_meta})")
    else:
        print(f"  Patch CSUM.meta != Patch ASET.meta")

    return 0


if __name__ == "__main__":
    sys.exit(main())
