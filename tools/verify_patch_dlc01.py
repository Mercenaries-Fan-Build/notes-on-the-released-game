#!/usr/bin/env python3
"""Verify dlc01 bootstrap in vz-patch.wad (for game-PC deploy checks).

Checks:
  - scripts_vz block contains dlc01 UCFX (LE bytecode)
  - ASET row for pandemic_hash_m2('dlc01') with type_id 35 (not 0)
  - Expected block count when bootstrap was injected (2197)

Usage:
  python3 tools/verify_patch_dlc01.py --wad path/to/vz-patch.wad
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from ffcs_wad import parse_ffcs, extract_slice, dump_paths_from_pths  # noqa: E402
from aset_prop_tracer import parse_aset  # noqa: E402
from pandemic_hash import pandemic_hash_m2  # noqa: E402
from wad_patcher import SCRIPT_ASET_TYPE_ID  # noqa: E402


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--wad", type=Path, required=True)
    args = ap.parse_args()
    if not args.wad.is_file():
        print(f"ERROR: not found: {args.wad}", file=sys.stderr)
        return 1

    raw = args.wad.read_bytes()
    arch = parse_ffcs(args.wad)
    paths = dump_paths_from_pths(extract_slice(raw, next(c for c in arch.chunks if c.tag == "PTHS")))
    rows = parse_aset(extract_slice(raw, next(c for c in arch.chunks if c.tag == "ASET")))
    dlc01_hash = pandemic_hash_m2("dlc01")

    print(f"WAD: {args.wad}")
    print(f"  Blocks (PTHS): {len(paths)}")
    print(f"  ASET rows:     {len(rows)}")
    if len(paths) < 2197:
        print("  WARN: expected >= 2197 blocks when dlc-port used --source-wad (bootstrap block)")

    hits = [r for r in rows if r["asset_hash"] == dlc01_hash]
    if not hits:
        print(f"  FAIL: no ASET row for dlc01 (0x{dlc01_hash:08X})")
        print("        Bootstrap scripts_vz block missing from this WAD.")
        return 1

    ok = True
    for r in hits:
        tid = r["type_id"]
        bi = r["block_index"]
        path = paths[bi] if bi < len(paths) else "?"
        print(f"  dlc01 ASET: type_id={tid} block={bi} ({path})")
        if tid != SCRIPT_ASET_TYPE_ID:
            print(f"  FAIL: type_id must be {SCRIPT_ASET_TYPE_ID} (run fix_dlc01_aset_type.py)")
            ok = False
        elif "scripts_vz" not in path.lower():
            print("  WARN: dlc01 not in scripts_vz block path")

    if ok:
        print("  OK: dlc01 ASET looks correct for import() on PC")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
