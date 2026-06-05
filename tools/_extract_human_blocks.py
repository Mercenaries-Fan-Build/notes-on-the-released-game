#!/usr/bin/env python3
"""Extract (decompress) all human-character blocks from a WAD into a directory.
Auto-detects PC-LE (FFCS) vs Xbox-BE (SCFF).

Usage: python tools/_extract_human_blocks.py <wad> <out_dir> [substr]
"""
import mmap
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))


def safe(p):
    return p.replace("\\", "__").replace("/", "__")


def extract(wad: Path, outdir: Path, sub: str):
    outdir.mkdir(parents=True, exist_ok=True)
    with open(wad, "rb") as f:
        magic = f.read(4)
    fh = open(wad, "rb")
    mm = mmap.mmap(fh.fileno(), 0, access=mmap.ACCESS_READ)
    n = 0
    if magic == b"SCFF":  # Xbox BE
        from x360_dlc_io import (parse_be_ffcs, parse_be_indx, parse_be_pths,
                                 PAGE_SIZE)
        from wad_be_le_oracle import _decompress_be_block
        _v, rows = parse_be_ffcs(mm)
        indx = next(r for r in rows if r.tag == "INDX")
        pths = next((r for r in rows if r.tag == "PTHS"), None)
        ents = parse_be_indx(mm, indx.offset, indx.meta)
        paths = parse_be_pths(mm, pths.offset, pths.meta) if pths else []
        for i, p in enumerate(paths):
            if sub in p.lower() and i < len(ents):
                blk = _decompress_be_block(mm, ents[i].file_offset,
                                           ents[i].page_count * PAGE_SIZE)
                if blk:
                    (outdir / (safe(p) + ".bin")).write_bytes(blk)
                    n += 1
    else:  # PC LE
        from wad_patcher import (find_data_chunk, get_block_boundaries,
                                 load_wad_paths)
        from sges_decompress import decompress_sges_block
        dc = find_data_chunk(wad)
        bounds = get_block_boundaries(mm, dc.offset, dc.size)
        paths = load_wad_paths(wad)
        for i, (s, e) in enumerate(bounds):
            p = paths[i] if i < len(paths) else f"block_{i:05d}"
            if sub in p.lower():
                try:
                    blk = decompress_sges_block(mm, s, e)
                except Exception:
                    continue
                if blk:
                    (outdir / (safe(p) + ".bin")).write_bytes(blk)
                    n += 1
    mm.close()
    fh.close()
    print(f"{wad.name} -> {outdir}: extracted {n} '{sub}' blocks")
    return n


if __name__ == "__main__":
    extract(Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3] if len(sys.argv) > 3 else "hum")
