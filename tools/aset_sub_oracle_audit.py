#!/usr/bin/env python3
"""ASET sub-offset oracle audit (BE source vs our LE patch, validated by base).

Root-cause tool for the 2026-06-13 world-load bug: the converter was overwriting
the ASET packed_block_ref's "primary / resolve-by-hash" sentinel (sub=0xFFFF)
with each asset's physical sub-entry index, redirecting the engine to body-less
metadata stubs (-> 0xF011157A texture sentinel -> streaming wedge + ECS
type-confusion crashes).

Field order (verified against the base BE<->LE pair):
    BE  (Xbox)  u2 = {sub : hi16, block : lo16}
    LE  (PC)    u2 = {block : hi16, sub : lo16}
So the BE "sub" is (u2 >> 16) and the LE "sub" is (u2 & 0xFFFF).

Ground-truth rule (base xbox-vz.wad <-> pc-game-vz.wad): an entry with BE
sub == 0xFFFF stays sub == 0xFFFF in the correct PC WAD (~99.7%).  This audit
flags DLC ASET entries where BE sub == 0xFFFF but OUR LE sub != 0xFFFF — the
bug class.  Expect 0 (or near-0) after the _PRESERVE_PRIMARY_ASET_SUB fix.

Usage:
    python tools/aset_sub_oracle_audit.py \
        --dlc output/_scratch/dlc01.doh \
        --ours output/data/vz-patch.wad \
        [--base-be game-files/xbox-vz.wad --base-le game-files/pc-game-vz.wad]
"""
from __future__ import annotations

import argparse
import struct
import sys
from collections import Counter
from pathlib import Path

_TOOLS = Path(__file__).resolve().parent
if str(_TOOLS) not in sys.path:
    sys.path.insert(0, str(_TOOLS))

from x360_dlc_io import load_stfs_or_doh, parse_be_ffcs  # noqa: E402
from ffcs_wad import parse_ffcs  # noqa: E402

TYPE_NAMES = {
    27: "texture", 19: "model", 12: "scrub", 9: "layer", 28: "path",
    16: "animation", 22: "lowresterrain", 32: "terrainmesh", 35: "script",
    21: "soundbank", 30: "lineregion", 29: "effect", 11: "animationtable",
    13: "sounddb", 14: "materialparam", 23: "scaleformgfx",
}


def be_sub_map(path: Path) -> dict[int, int]:
    """asset_hash -> BE sub (high16 of the packed field)."""
    doh, _ = load_stfs_or_doh(path)
    _, rows = parse_be_ffcs(doh)
    row = {r.tag: r for r in rows}
    o, n = row["ASET"].offset, row["ASET"].meta
    m: dict[int, int] = {}
    for i in range(n):
        u0, _u1, u2 = struct.unpack_from(">III", doh, o + i * 16)
        m[u0] = (u2 >> 16) & 0xFFFF
    return m


def le_sub_type_map(path: Path) -> dict[int, tuple[int, int]]:
    """asset_hash -> (LE sub = low16, type_id)."""
    arch = parse_ffcs(path)
    raw = path.read_bytes()
    aset = next(c for c in arch.chunks if c.tag == "ASET")
    o = aset.offset
    m: dict[int, tuple[int, int]] = {}
    for i in range(aset.size // 16):
        u0, _u1, u2 = struct.unpack_from("<III", raw, o + i * 16)
        u3 = struct.unpack_from("<I", raw, o + i * 16 + 12)[0]
        m[u0] = (u2 & 0xFFFF, u3)
    return m


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dlc", type=Path, required=True, help="BE DLC source (dlc01.doh / STFS)")
    ap.add_argument("--ours", type=Path, required=True, help="our LE patch WAD")
    ap.add_argument("--base-be", type=Path, default=None, help="Xbox base WAD (oracle)")
    ap.add_argument("--base-le", type=Path, default=None, help="PC base WAD (oracle)")
    args = ap.parse_args()

    if args.base_be and args.base_le:
        bb = be_sub_map(args.base_be)
        bl = le_sub_type_map(args.base_le)
        both = [h for h in bb if h in bl]
        ff = [h for h in both if bb[h] == 0xFFFF]
        ffp = sum(1 for h in ff if bl[h][0] == 0xFFFF)
        print(f"BASE ORACLE: BE sub=0xFFFF entries={len(ff)}; "
              f"preserved 0xFFFF in PC={ffp} ({100*ffp/max(len(ff),1):.1f}%) "
              "<- the rule: preserve 0xFFFF")

    be = be_sub_map(args.dlc)
    ours = le_sub_type_map(args.ours)
    overlap = [h for h in be if h in ours]
    bug = [(h, be[h], ours[h][0], ours[h][1]) for h in overlap
           if be[h] == 0xFFFF and ours[h][0] != 0xFFFF]
    by_type = Counter(TYPE_NAMES.get(t, t) for _h, _b, _o, t in bug)
    print(f"\nDLC entries={len(be)} overlap-with-ours={len(overlap)}")
    print(f"BUG CLASS (BE sub=0xFFFF -> our sub!=0xFFFF): {len(bug)}")
    if bug:
        print("  by type:", dict(by_type))
        for h, b, o, t in bug[:15]:
            print(f"    0x{h:08X} {TYPE_NAMES.get(t, t)}: BE={b:04X} ours={o:04X}")
    print("\nRESULT:", "PASS (0 primary-sentinel regressions)" if not bug
          else f"FAIL ({len(bug)} entries still clobbered)")
    return 0 if not bug else 1


if __name__ == "__main__":
    raise SystemExit(main())
