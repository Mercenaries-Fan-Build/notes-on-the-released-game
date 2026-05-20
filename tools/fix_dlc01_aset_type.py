#!/usr/bin/env python3
"""Fix dlc01 ASET type_id in an existing vz-patch.wad (in-place patch).

Bootstrap injection used type_id=0; script modules require type_id=35
(type_hash 0x42498680). Without this, import('dlc01') fails even when the
patch WAD is present.

Usage:
  python3 tools/fix_dlc01_aset_type.py --wad path/to/vz-patch.wad
  python3 tools/fix_dlc01_aset_type.py --wad path/to/vz-patch.wad --dry-run
"""
from __future__ import annotations

import argparse
import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from ffcs_wad import parse_ffcs, extract_slice  # noqa: E402
from pandemic_hash import pandemic_hash_m2  # noqa: E402
from wad_patcher import SCRIPT_ASET_TYPE_ID  # noqa: E402


def fix_dlc01_aset_type(wad_path: Path, *, dry_run: bool = False) -> int:
    dlc01_hash = pandemic_hash_m2("dlc01")
    raw = bytearray(wad_path.read_bytes())
    arch = parse_ffcs(wad_path)
    aset_chunk = next(c for c in arch.chunks if c.tag == "ASET")
    aset_off = aset_chunk.offset
    aset_size = aset_chunk.size
    if aset_size % 16 != 0:
        print(f"ERROR: ASET size {aset_size} not multiple of 16", file=sys.stderr)
        return 1

    fixed = 0
    for i in range(aset_size // 16):
        row_off = aset_off + i * 16
        u0, u1, u2, u3 = struct.unpack_from("<IIII", raw, row_off)
        if u0 != dlc01_hash:
            continue
        if u3 == SCRIPT_ASET_TYPE_ID:
            print(f"  Row {i}: dlc01 ASET already type_id={SCRIPT_ASET_TYPE_ID}")
            return 0
        print(
            f"  Row {i}: dlc01 ASET type_id {u3} → {SCRIPT_ASET_TYPE_ID} "
            f"(block={(u2 >> 16) & 0xFFFF})"
        )
        if not dry_run:
            struct.pack_into("<I", raw, row_off + 12, SCRIPT_ASET_TYPE_ID)
        fixed += 1

    if fixed == 0:
        print(f"ERROR: no ASET row with dlc01 hash 0x{dlc01_hash:08X}", file=sys.stderr)
        return 1

    if dry_run:
        print("  (dry-run — no write)")
        return 0

    wad_path.write_bytes(raw)
    print(f"  Wrote: {wad_path}")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--wad", type=Path, required=True, help="Path to vz-patch.wad")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()
    if not args.wad.is_file():
        print(f"ERROR: not found: {args.wad}", file=sys.stderr)
        return 1
    print(f"Patching: {args.wad}")
    return fix_dlc01_aset_type(args.wad, dry_run=args.dry_run)


if __name__ == "__main__":
    raise SystemExit(main())
