#!/usr/bin/env python3
"""bone_check.py -- verify candidate bone names against the unnamed rig-bone hashes.

For manual inspection follow-up: paste any names you spotted in the output/bone_candidates/ dumps and
this confirms which unnamed HIER hash each one hits (if any), names its reference-rig position, and
auto-checks mirror pairs (a real L name implies its R sibling exists, and vice-versa).

Usage:
  python tools/bone_check.py bone_lclavicle bone_rclavicle bone_spine3 ...
  python tools/bone_check.py --file my_candidates.txt
"""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from fnv import m2  # noqa: E402

# hash -> (reference-rig position, mirror-sibling hash or None)
SLOTS = {
    0x491E8967: ("trk3 heads LEFT leg chain (under Hips)", 0xE6FF1D72),
    0xE6FF1D72: ("trk10 heads RIGHT leg chain", 0x491E8967),
    0xFAADBFFF: ("trk17 between Spine2 and Chest", None),
    0x11815D82: ("trk22 after attach_backL/R, before neck", None),
    0x00A8F086: ("trk25 under Head", None),
    0xEB221048: ("trk26 parent of jaw", None),
    0x0D29320C: ("trk28 jaw region (+X)", 0x409403C6),
    0x409403C6: ("trk31 jaw region (-X)", 0x0D29320C),
    0x1E4780FA: ("trk29 face chain", None),
    0xFE747044: ("trk30 face chain", None),
    0xFBFA3B2C: ("trk32 face chain", None),
    0xA3EEDAF2: ("trk33 face chain", None),
    0x87E8C062: ("trk54 between Lshoulder and LBicep", 0x7D2C9CA4),
    0x7D2C9CA4: ("trk76 between Rshoulder and RBicep", 0x87E8C062),
    0x9EC352CF: ("trk104 accessory tail (after bone_hair)", None),
    0xDB0322B7: ("trk102 accessory tail = bone_ub (SOLVED)", None),
}


def main() -> int:
    args = sys.argv[1:]
    names: list[str] = []
    if args and args[0] == "--file":
        names = [l.strip() for l in open(args[1]) if l.strip() and not l.startswith("#")]
    else:
        names = args
    if not names:
        print("usage: bone_check.py <name> [name ...]  |  --file <path>")
        return 2

    by_hash: dict[int, str] = {}
    print(f"{'candidate':<28}{'hash':>12}  slot")
    for name in names:
        h = m2(name)
        by_hash[h] = name
        if h in SLOTS:
            pos, _ = SLOTS[h]
            print(f"{name:<28}0x{h:08X}  *** HITS: {pos} ***")
        else:
            print(f"{name:<28}0x{h:08X}  (no unnamed rig slot)")

    # mirror corroboration
    print("\nmirror-pair check:")
    seen = set()
    hit_any = False
    for h, name in by_hash.items():
        if h not in SLOTS:
            continue
        pos, mate = SLOTS[h]
        if mate is None or h in seen:
            continue
        seen.add(h)
        seen.add(mate)
        hit_any = True
        this = name
        other = by_hash.get(mate)
        if other:
            print(f"  PAIR CONFIRMED: 0x{h:08X}={this}  <->  0x{mate:08X}={other}")
        else:
            print(f"  0x{h:08X}={this} has a mirror slot 0x{mate:08X} with NO candidate supplied "
                  f"-- provide its L/R-flipped spelling to corroborate.")
    if not hit_any:
        print("  (no candidate landed on a slot that has a mirror)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
