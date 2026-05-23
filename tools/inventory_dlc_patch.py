#!/usr/bin/env python3
"""Bucket PTHS paths in a vz-patch.wad (Phase 4 — 2196-block inventory).

Usage:
  python3 tools/inventory_dlc_patch.py --wad output/data/vz-patch.wad
  python3 tools/inventory_dlc_patch.py --wad output/data/vz-patch.wad --json out.json
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from collections import defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from ffcs_patch_wad import read_patch_wad  # noqa: E402


def _bucket(path: str) -> str:
    p = path.replace("\\", "/").lower()
    if "scripts_vz" in p:
        return "scripts_vz"
    if "resident" in p and "dlc01" in p:
        return "dlc01_resident"
    if "english_dlc01" in p or "french_dlc01" in p or "_dlc01" in p:
        return "stringdb_lang"
    if "dlccon" in p:
        return "dlccon_contract"
    if "dlc01_state" in p or "state_" in p and "dlc01" in p:
        return "vz_state_overlay"
    if re.search(r"/c3\d{5}", p) or p.startswith("blocks/c3"):
        return "c3_cell"
    if "terrain" in p or "lrterrain" in p:
        return "terrain"
    if "dlc01" in p:
        return "dlc01_other"
    if "audios" in p or p.endswith(".pws"):
        return "audio"
    return "other"


def inventory_patch_wad(wad: Path) -> dict:
    pw = read_patch_wad(wad)
    buckets: dict[str, list[str]] = defaultdict(list)
    for blk in pw.blocks:
        buckets[_bucket(blk.path_string)].append(blk.path_string)

    summary = {k: len(v) for k, v in sorted(buckets.items(), key=lambda x: -len(x[1]))}
    return {
        "wad": str(wad),
        "block_count": len(pw.blocks),
        "bucket_counts": summary,
        "buckets": {k: sorted(v) for k, v in sorted(buckets.items())},
    }


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--wad", type=Path, required=True)
    ap.add_argument("--json", type=Path, default=None, help="Write full inventory JSON")
    args = ap.parse_args()
    if not args.wad.is_file():
        print(f"ERROR: not found: {args.wad}", file=sys.stderr)
        return 1

    inv = inventory_patch_wad(args.wad)
    print(f"WAD: {inv['wad']}")
    print(f"Blocks: {inv['block_count']}\n")
    print("Bucket counts:")
    for name, count in inv["bucket_counts"].items():
        print(f"  {name:20s} {count:5d}")

    if args.json:
        args.json.parent.mkdir(parents=True, exist_ok=True)
        args.json.write_text(json.dumps(inv, indent=2), encoding="utf-8")
        print(f"\nWrote: {args.json}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
