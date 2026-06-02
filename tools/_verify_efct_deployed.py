#!/usr/bin/env python3
"""Scan a deployed WAD for EFCT chunks and report magic@+2 and count@+14.

Decisive check for the COLR-append NULL-deref crash (0x00493102): a correctly
converted EFCT header has magic 0x0226 at byte +2 and a nonzero sub-component
count at byte +14. The old/buggy u16-swept build had magic at +0 and count@+14==0
in every EFCT chunk.
"""
from __future__ import annotations

import mmap
import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from sges_decompress import decompress_sges_block
from wad_patcher import find_data_chunk, get_block_boundaries, parse_block_entries


def scan(wad_path: Path) -> int:
    dc = find_data_chunk(wad_path)
    found = 0
    bad = 0
    with open(wad_path, "rb") as f:
        mm = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)
        boundaries = get_block_boundaries(mm, dc.offset, dc.size)
        print(f"WAD: {wad_path}  size={wad_path.stat().st_size}  blocks={len(boundaries)}")
        for blk_idx in range(len(boundaries)):
            s, e = boundaries[blk_idx]
            try:
                data = decompress_sges_block(mm, s, e)
                entries = parse_block_entries(data)
            except Exception:
                continue
            for ent in entries:
                eoff, esize = ent["offset"], ent["size"]
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
                    if c[doff:doff + 4] != b"EFCT":
                        continue
                    u0 = struct.unpack_from("<I", c, doff + 4)[0]
                    bs = struct.unpack_from("<I", c, doff + 8)[0]
                    bstart = base_off + u0
                    if bstart + bs > len(c) or bs < 16:
                        continue
                    body = c[bstart:bstart + bs]
                    magic_at_2 = struct.unpack_from("<H", body, 2)[0]
                    count_at_14 = struct.unpack_from("<H", body, 14)[0]
                    magic_at_0 = struct.unpack_from("<H", body, 0)[0]
                    ok = (magic_at_2 == 0x0226 and count_at_14 != 0)
                    if not ok:
                        bad += 1
                    found += 1
                    print(
                        f"  block {blk_idx:5d} hash={ent['hash']:#010x} size={bs:3d}  "
                        f"magic@+0={magic_at_0:#06x} magic@+2={magic_at_2:#06x} "
                        f"count@+14={count_at_14:<5d} -> {'OK' if ok else 'BAD (would crash)'}"
                    )
        mm.close()
    print(f"\nEFCT chunks: {found}  |  BAD (count@+14==0 or magic misplaced): {bad}")
    return bad


if __name__ == "__main__":
    target = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(
        r"C:\Users\Shadow\Desktop\Mercenaries 2 World in Flames\data\vz-patch.wad"
    )
    rc = scan(target)
    sys.exit(1 if rc else 0)
