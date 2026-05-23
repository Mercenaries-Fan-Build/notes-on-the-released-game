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
    """Normalize dlc01 ASET rows: type_id=35, dedupe (prefer scripts_vz / highest block)."""
    dlc01_hash = pandemic_hash_m2("dlc01")
    raw = bytearray(wad_path.read_bytes())
    arch = parse_ffcs(wad_path)
    aset_chunk = next(c for c in arch.chunks if c.tag == "ASET")
    aset_off = aset_chunk.offset
    row_count = aset_chunk.meta
    if aset_chunk.size % 16 != 0:
        print(f"ERROR: ASET size {aset_chunk.size} not multiple of 16", file=sys.stderr)
        return 1

    rows: list[tuple[int, int, int, int, int]] = []
    for i in range(row_count):
        row_off = aset_off + i * 16
        u0, u1, u2, u3 = struct.unpack_from("<IIII", raw, row_off)
        if u0 == dlc01_hash:
            rows.append((i, row_off, u1, u2, u3))

    if not rows:
        print(f"ERROR: no ASET row with dlc01 hash 0x{dlc01_hash:08X}", file=sys.stderr)
        return 1

    # Prefer highest block index (scripts_vz @2196), then type_id=35
    def score(r: tuple[int, int, int, int, int]) -> tuple:
        _i, _off, _u1, u2, u3 = r
        blk = (u2 >> 16) & 0xFFFF
        return (blk, u3 == SCRIPT_ASET_TYPE_ID, u3 != 26)

    keep = max(rows, key=score)
    remove = [r for r in rows if r[0] != keep[0]]

    for i, row_off, _u1, u2, u3 in rows:
        blk = (u2 >> 16) & 0xFFFF
        if u3 != SCRIPT_ASET_TYPE_ID:
            print(f"  Row {i}: type_id {u3} → {SCRIPT_ASET_TYPE_ID} (block={blk})")
            if not dry_run:
                struct.pack_into("<I", raw, row_off + 12, SCRIPT_ASET_TYPE_ID)
        else:
            print(f"  Row {i}: type_id={SCRIPT_ASET_TYPE_ID} (block={blk}) keep")

    for i, row_off, u1, u2, u3 in remove:
        blk = (u2 >> 16) & 0xFFFF
        print(f"  Row {i}: REMOVE duplicate dlc01 (block={blk}, type_id={u3})")
        if not dry_run:
            struct.pack_into("<IIII", raw, row_off, 0, 0, 0, 0)

    if dry_run:
        print("  (dry-run — no write)")
        return 0

    # Compact zero rows from tail (optional — engine may ignore zero rows)
    wad_path.write_bytes(raw)
    print(f"  Wrote: {wad_path} (kept row {keep[0]}, zeroed {len(remove)} duplicate(s))")
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
