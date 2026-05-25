#!/usr/bin/env python3
"""Audit DLC-unique entries (no base game ground truth).

For entries that ONLY exist in the DLC, catalog:
- Type distribution
- Tag presence and sizes
- Any structural anomalies (unknown tags, unusual sizes)
"""
from __future__ import annotations

import mmap
import struct
import sys
from collections import defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from sges_decompress import decompress_sges_block
from wad_patcher import find_data_chunk, get_block_boundaries, parse_block_entries

TYPE_NAMES = {
    0xF011157A: "texture", 0x42498680: "script", 0x207359C7: "stance",
    0x18166555: "animation", 0xBCFE6314: "path", 0xECE70371: "state_machine",
    0xE6B81A54: "ecs_node", 0x5B724250: "mesh_B", 0x7C569307: "mesh_A",
    0x600B904E: "mesh_C", 0x39E5E978: "stringdb", 0xE5273C14: "unknown_E5",
    0x1602815C: "unknown_16", 0xF753F6D0: "unknown_F7", 0x9F8BCA10: "unknown_9F",
    0x6310807F: "unknown_63", 0x5608BD5A: "unknown_56",
}


def main():
    base_wad = Path("game-files/Mercenaries 2 World in Flames/data/vz.wad")
    patch_wad = Path("game-files/Mercenaries 2 World in Flames/data/vz-patch.wad")

    # Build set of base game hashes (any type)
    print("Indexing base game hashes...")
    dc = find_data_chunk(base_wad)
    base_hashes: set[int] = set()
    with open(base_wad, "rb") as f:
        mm = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)
        boundaries = get_block_boundaries(mm, dc.offset, dc.size)
        for blk_idx in range(len(boundaries)):
            s, e = boundaries[blk_idx]
            try:
                data = decompress_sges_block(mm, s, e)
                entries = parse_block_entries(data)
            except Exception:
                continue
            for ent in entries:
                base_hashes.add(ent["hash"])
        mm.close()
    print(f"  {len(base_hashes):,} unique hashes in base game\n")

    # Scan patch WAD
    print("Scanning patch WAD for DLC-unique entries...")
    dc = find_data_chunk(patch_wad)
    unique_by_type: dict[int, list] = defaultdict(list)
    all_tags_seen: dict[int, dict[str, int]] = defaultdict(lambda: defaultdict(int))

    with open(patch_wad, "rb") as f:
        mm = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)
        boundaries = get_block_boundaries(mm, dc.offset, dc.size)
        for blk_idx in range(len(boundaries)):
            s, e = boundaries[blk_idx]
            try:
                data = decompress_sges_block(mm, s, e)
                entries = parse_block_entries(data)
            except Exception:
                continue
            for ent in entries:
                if ent["hash"] in base_hashes:
                    continue
                th = ent["type_hash"]
                eoff = ent["offset"]
                esize = ent["size"]
                if eoff + esize > len(data):
                    continue
                raw = data[eoff:eoff + esize]
                pos = raw.find(b"UCFX")
                tags = []
                if pos >= 0:
                    c = raw[pos:]
                    if len(c) >= 20:
                        dao = struct.unpack_from("<I", c, 4)[0]
                        n = struct.unpack_from("<I", c, 16)[0]
                        if n < 5000:
                            for i in range(n):
                                doff = 20 + i * 20
                                if doff + 20 > len(c):
                                    break
                                tag = c[doff:doff+4].decode("ascii", "replace")
                                bs = struct.unpack_from("<I", c, doff + 8)[0]
                                tags.append((tag, bs))
                                all_tags_seen[th][tag] += 1
                unique_by_type[th].append({
                    "hash": ent["hash"],
                    "block": blk_idx,
                    "size": esize,
                    "tags": tags,
                })
        mm.close()

    total_unique = sum(len(v) for v in unique_by_type.values())
    print(f"  {total_unique} DLC-unique entries across {len(unique_by_type)} type_hashes\n")

    print("=" * 80)
    print("TYPE BREAKDOWN OF DLC-UNIQUE ENTRIES")
    print("=" * 80)

    for th in sorted(unique_by_type.keys(), key=lambda t: len(unique_by_type[t]), reverse=True):
        entries = unique_by_type[th]
        tname = TYPE_NAMES.get(th, f"0x{th:08X}")
        print(f"\n{tname} (0x{th:08X}): {len(entries)} unique entries")

        tag_freq = all_tags_seen[th]
        if tag_freq:
            tag_list = sorted(tag_freq.items(), key=lambda x: -x[1])
            print(f"  Tags: {', '.join(f'{t}({c})' for t, c in tag_list)}")

        # Show sample
        sample = entries[0]
        h = sample["hash"]
        print(f"  Sample hash=0x{h:08X}, block={sample['block']}, size={sample['size']}")
        for tag, sz in sample["tags"]:
            print(f"    {tag}: {sz} bytes")

    # Check for unknown/unhandled tags across ALL unique entries
    print("\n" + "=" * 80)
    print("ALL UNIQUE TAGS ACROSS DLC-UNIQUE ENTRIES")
    print("=" * 80)

    global_tags: dict[str, int] = defaultdict(int)
    for th_tags in all_tags_seen.values():
        for tag, cnt in th_tags.items():
            global_tags[tag] += cnt

    # Known handled tags from ucfx_be_to_le.py
    KNOWN_HANDLED = {
        "NAME", "TYPE", "INFO", "BODY", "BINN", "DEPS", "KEYS", "STRS",
        "data", "info", "enum", "schm", "decl", "flgs", "evnt", "trnm",
        "INDX", "STRM", "IBUF", "PRMG", "PRMT", "GEOM", "POFF", "SEGM",
        "STAT", "SWIT", "NODE", "CEXE", "PHY2", "HIER", "COMP", "CHDR",
        "TINY", "MTRL", "SCRB", "INST", "PTCH", "PTMS", "VALU", "AREA",
        "MESH", "STAM",
    }

    print(f"\n  {'Tag':<6} {'Count':>6}  Status")
    print(f"  {'---':<6} {'-----':>6}  ------")
    for tag, cnt in sorted(global_tags.items(), key=lambda x: -x[1]):
        status = "HANDLED" if tag in KNOWN_HANDLED else "** UNHANDLED **"
        print(f"  {tag:<6} {cnt:>6}  {status}")


if __name__ == "__main__":
    main()
