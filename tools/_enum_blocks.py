#!/usr/bin/env python3
"""List block paths matching a substring in a WAD (auto-detects PC-LE vs Xbox-BE).
Usage: python tools/_enum_blocks.py <wad> <substr>
"""
import mmap
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))


def list_paths(wad: Path):
    with open(wad, "rb") as f:
        magic = f.read(4)
    if magic == b"SCFF":  # Xbox BE
        from x360_dlc_io import parse_be_ffcs, parse_be_pths
        mm = mmap.mmap(open(wad, "rb").fileno(), 0, access=mmap.ACCESS_READ)
        _v, rows = parse_be_ffcs(mm)
        pths = next((r for r in rows if r.tag == "PTHS"), None)
        return parse_be_pths(mm, pths.offset, pths.meta) if pths else []
    else:  # PC LE (FFCS)
        from wad_patcher import load_wad_paths
        return load_wad_paths(wad)


def main():
    wad = Path(sys.argv[1])
    sub = sys.argv[2].lower() if len(sys.argv) > 2 else "hum"
    paths = list_paths(wad)
    hits = [(i, p) for i, p in enumerate(paths) if sub in p.lower()]
    print(f"{wad.name}: {len(paths)} blocks, {len(hits)} match '{sub}'")
    for i, p in hits:
        print(f"  [{i}] {p}")


if __name__ == "__main__":
    main()
