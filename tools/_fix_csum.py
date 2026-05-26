#!/usr/bin/env python3
"""Fix CSUM meta in an existing patch WAD — in-place header patch."""
from __future__ import annotations

import struct
import sys
from pathlib import Path


def main() -> int:
    wad_path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("output/vz-patch.wad")
    raw = bytearray(wad_path.read_bytes())

    # Read current CSUM
    old_csum_val = struct.unpack_from("<I", raw, 0x28)[0]
    old_csum_meta = struct.unpack_from("<I", raw, 0x2C)[0]
    aset_meta = struct.unpack_from("<I", raw, 0x38)[0]

    print(f"File: {wad_path}")
    print(f"Before: CSUM val=0x{old_csum_val:08X} meta={old_csum_meta}, ASET meta={aset_meta}")

    # Parse PTHS to find resident block index
    pths_off = struct.unpack_from("<I", raw, 0x40)[0]
    pths_count = struct.unpack_from("<I", raw, 0x44)[0]

    paths: list[str] = []
    pos = pths_off
    for _ in range(pths_count):
        nul = raw.index(b"\x00", pos)
        paths.append(raw[pos:nul].decode("utf-8", errors="replace"))
        pos = nul + 1

    # Find resident block index
    resident_idx = -1
    for i, p in enumerate(paths):
        if p.lower().replace("/", "\\").endswith("\\resident_p000_q3.block"):
            resident_idx = i
            print(f"Resident block: index={i}, path={p}")
            break

    if resident_idx < 0:
        print("WARNING: No resident block found, setting CSUM meta=0")
        new_csum_meta = 0
    else:
        # Count ASET entries pointing to this block
        aset_off = struct.unpack_from("<I", raw, 0x34)[0]
        aset_count = struct.unpack_from("<I", raw, 0x38)[0]
        resident_aset = 0
        for i in range(aset_count):
            off = aset_off + i * 16
            u2 = struct.unpack_from("<I", raw, off + 8)[0]
            blk_idx = (u2 >> 16) & 0xFFFF
            if blk_idx == resident_idx:
                resident_aset += 1
        new_csum_meta = resident_aset
        print(f"Resident block ASET entries: {resident_aset}")

    # Patch in-place
    struct.pack_into("<I", raw, 0x2C, new_csum_meta)

    # Verify
    verify = struct.unpack_from("<I", raw, 0x2C)[0]
    print(f"After:  CSUM val=0x{old_csum_val:08X} meta={verify}")

    wad_path.write_bytes(bytes(raw))
    print(f"Written: {wad_path} ({len(raw):,} bytes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
