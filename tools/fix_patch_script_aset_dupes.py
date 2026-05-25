#!/usr/bin/env python3
"""Remove duplicate script ASET rows that point at resident block instead of scripts_vz.

Xbox global ASET resolution can leave type_id=35 rows on blocks\\dlc01\\resident_P000_Q3
(block 464) while the bootstrap block also registers the same hash on scripts_vz (2196).
The engine may resolve masterscript hashes to resident during GameBootstrap → hard crash.

Row 13 / fresh-rebuilt WADs only reference scripts_vz for wifmissionflow, vz, etc.

Usage:
  python3 tools/fix_patch_script_aset_dupes.py --wad output/data/vz-patch.wad
  python3 tools/fix_patch_script_aset_dupes.py --wad path/to/vz-patch.wad --dry-run
"""
from __future__ import annotations

import argparse
import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from aset_type_ids import SCRIPT_ASET_TYPE_ID  # noqa: E402
from dlc_aset_normalize import find_resident_block_index_from_paths  # noqa: E402
from ffcs_wad import dump_paths_from_pths, extract_slice, parse_ffcs  # noqa: E402
from pandemic_hash import pandemic_hash_m2  # noqa: E402

KNOWN_SCRIPT_NAMES = (
    "wifmissionflow",
    "wifpmcinterior",
    "vz",
    "dlc01",
    "wifstarterdata",
    "wifmissiondata",
)


def fix_script_aset_dupes(
    wad_path: Path,
    *,
    resident_block: int | None = None,
    scripts_vz_block: int | None = None,
    dry_run: bool = False,
) -> int:
    raw = bytearray(wad_path.read_bytes())
    arch = parse_ffcs(wad_path)
    aset_chunk = next(c for c in arch.chunks if c.tag == "ASET")
    pths = dump_paths_from_pths(
        extract_slice(raw, next(c for c in arch.chunks if c.tag == "PTHS"))
    )
    n_blocks = len(pths)
    if scripts_vz_block is None:
        scripts_vz_block = n_blocks - 1
    if resident_block is None:
        resident_block = find_resident_block_index_from_paths(pths)
        if resident_block is None:
            print("  ERROR: could not find dlc01 resident block in PTHS", file=sys.stderr)
            return 1
        print(f"  Resident block (auto): {resident_block} ({pths[resident_block]})")

    # Group script rows by asset_hash
    by_hash: dict[int, list[tuple[int, int, int, int]]] = {}
    for i in range(aset_chunk.meta):
        row_off = aset_chunk.offset + i * 16
        u0, u1, u2, u3 = struct.unpack_from("<IIII", raw, row_off)
        if u0 == 0 or u3 != SCRIPT_ASET_TYPE_ID:
            continue
        bi = (u2 >> 16) & 0xFFFF
        by_hash.setdefault(u0, []).append((i, row_off, bi, u3))

    name_for = {pandemic_hash_m2(n): n for n in KNOWN_SCRIPT_NAMES}
    cleared = 0

    for asset_hash, rows in by_hash.items():
        blocks = {r[2] for r in rows}
        if resident_block not in blocks or scripts_vz_block not in blocks:
            continue
        label = name_for.get(asset_hash, f"0x{asset_hash:08X}")
        for row_i, row_off, bi, tid in rows:
            if bi != resident_block:
                continue
            path = pths[bi] if bi < len(pths) else "?"
            print(
                f"  Row {row_i}: CLEAR {label} type_id={tid} "
                f"block={bi} ({path}) — keep scripts_vz @ {scripts_vz_block}"
            )
            if not dry_run:
                struct.pack_into("<IIII", raw, row_off, 0, 0, 0, 0)
            cleared += 1

    if cleared == 0:
        print("  No resident/scripts_vz script ASET conflicts found.")
        return 0

    if dry_run:
        print(f"  (dry-run — would clear {cleared} row(s))")
        return 0

    wad_path.write_bytes(raw)
    print(f"  Wrote: {wad_path} ({cleared} row(s) cleared)")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--wad", type=Path, required=True)
    ap.add_argument(
        "--resident-block",
        type=int,
        default=None,
        help="dlc01 resident block index (default: path-based auto-detect)",
    )
    ap.add_argument("--scripts-vz-block", type=int, default=None)
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()
    if not args.wad.is_file():
        print(f"ERROR: not found: {args.wad}", file=sys.stderr)
        return 1
    print(f"Patching script ASET dupes: {args.wad}")
    return fix_script_aset_dupes(
        args.wad,
        resident_block=args.resident_block,
        scripts_vz_block=args.scripts_vz_block,
        dry_run=args.dry_run,
    )


if __name__ == "__main__":
    raise SystemExit(main())
