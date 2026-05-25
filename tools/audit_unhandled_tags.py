#!/usr/bin/env python3
"""Find examples of unhandled tags in the base game for format analysis."""
from __future__ import annotations

import mmap
import struct
import sys
from collections import defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from sges_decompress import decompress_sges_block
from wad_patcher import find_data_chunk, get_block_boundaries, parse_block_entries

TARGET_TAGS = {"SKIN", "BSHP", "BSHI", "BNDS", "flgt", "ATRB", "AKEY", "TRFM", "COLR", "EFCT", "EMTR"}

TYPE_NAMES = {
    0xF011157A: "texture", 0x42498680: "script", 0x207359C7: "stance",
    0x18166555: "animation", 0xBCFE6314: "path", 0xECE70371: "state_machine",
    0xE6B81A54: "ecs_node", 0x5B724250: "mesh_B", 0x7C569307: "mesh_A",
    0x600B904E: "mesh_C", 0x39E5E978: "stringdb", 0x1602815C: "unknown_16",
    0x5608BD5A: "particle",
}


def main():
    base_wad = Path("game-files/Mercenaries 2 World in Flames/data/vz.wad")
    dc = find_data_chunk(base_wad)

    tag_examples: dict[str, list] = defaultdict(list)
    tag_sizes: dict[str, list] = defaultdict(list)

    with open(base_wad, "rb") as f:
        mm = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)
        boundaries = get_block_boundaries(mm, dc.offset, dc.size)
        # Scan first 500 blocks
        for blk_idx in range(min(500, len(boundaries))):
            s, e = boundaries[blk_idx]
            try:
                data = decompress_sges_block(mm, s, e)
                entries = parse_block_entries(data)
            except Exception:
                continue
            for ent in entries:
                th = ent["type_hash"]
                eoff = ent["offset"]
                esize = ent["size"]
                if eoff + esize > len(data):
                    continue
                raw = data[eoff:eoff + esize]
                pos = raw.find(b"UCFX")
                if pos < 0:
                    continue
                c = raw[pos:]
                if len(c) < 20:
                    continue
                dao = struct.unpack_from("<I", c, 4)[0]
                n = struct.unpack_from("<I", c, 16)[0]
                if n > 5000:
                    continue
                base_off = dao if dao else 8
                for i in range(n):
                    doff = 20 + i * 20
                    if doff + 20 > len(c):
                        break
                    tag = c[doff:doff+4].decode("ascii", "replace")
                    if tag in TARGET_TAGS:
                        u0 = struct.unpack_from("<I", c, doff + 4)[0]
                        bs = struct.unpack_from("<I", c, doff + 8)[0]
                        bstart = base_off + u0
                        body = b""
                        if bstart + bs <= len(c):
                            body = c[bstart:bstart + bs]
                        tag_sizes[tag].append(bs)
                        if len(tag_examples[tag]) < 3:
                            tag_examples[tag].append({
                                "block": blk_idx,
                                "hash": ent["hash"],
                                "type": th,
                                "size": bs,
                                "hex": body[:64].hex() if body else "",
                            })
        mm.close()

    print("UNHANDLED TAGS FOUND IN BASE GAME (first 500 blocks)")
    print("=" * 80)
    for tag in sorted(tag_examples.keys()):
        sizes = tag_sizes[tag]
        tname = ""
        if tag_examples[tag]:
            t = tag_examples[tag][0]["type"]
            tname = TYPE_NAMES.get(t, f"0x{t:08X}")
        common_size = max(set(sizes), key=sizes.count) if sizes else 0
        print(f"\n{tag}: {len(sizes)} occurrences in type={tname}")
        print(f"  sizes: min={min(sizes)}, max={max(sizes)}, most_common={common_size}")
        for ex in tag_examples[tag]:
            print(f"  block {ex['block']}, size={ex['size']} bytes")
            if ex["hex"]:
                # Show as u16 and u32 interpretations
                h = bytes.fromhex(ex["hex"])
                u32s = []
                for off in range(0, min(32, len(h)), 4):
                    u32s.append(struct.unpack_from("<I", h, off)[0])
                u16s = []
                for off in range(0, min(32, len(h)), 2):
                    u16s.append(struct.unpack_from("<H", h, off)[0])
                print(f"    raw:  {ex['hex'][:64]}")
                print(f"    u32s: {[f'0x{v:08X}' for v in u32s[:8]]}")
                print(f"    u16s: {[f'0x{v:04X}' for v in u16s[:16]]}")

    not_found = TARGET_TAGS - set(tag_examples.keys())
    if not_found:
        print(f"\nNOT FOUND in first 500 blocks: {not_found}")


if __name__ == "__main__":
    main()
