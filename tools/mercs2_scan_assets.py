#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Scan binary blobs for common Mercenaries 2 asset signatures (DXT/DDS, Havok XML, zlib)."""

from __future__ import annotations

import argparse
import mmap
from pathlib import Path


SIGS = {
    b"DDS ": "dds_header",
    b"DXT1": "dxt1_tag",
    b"DXT3": "dxt3_tag",
    b"DXT5": "dxt5_tag",
    b"<hkpackfile": "havok_xml_packfile",
    b"hkxp": "havok_binary_tag",
    b"\x78\x9c": "zlib_raw",
}


def scan_file(path: Path, limit: int = 500) -> None:
    size = path.stat().st_size
    print(f"{path} ({size} bytes)")
    with path.open("rb") as f:
        mm = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)
        try:
            hits: dict[str, list[int]] = {k: [] for k in SIGS.values()}
            # Sliding window naive for short sigs
            data = mm
            for sig, name in [(s, SIGS[s]) for s in SIGS]:
                start = 0
                count = 0
                while True:
                    idx = data.find(sig, start)
                    if idx == -1:
                        break
                    hits[name].append(idx)
                    count += 1
                    start = idx + 1
                    if count >= limit:
                        break
            for name, lst in hits.items():
                if lst:
                    print(f"  {name}: {len(lst)} hits, first offsets {[hex(x) for x in lst[:8]]}")
        finally:
            mm.close()


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("files", nargs="+", type=Path)
    args = ap.parse_args()
    for p in args.files:
        if p.exists():
            scan_file(p)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
