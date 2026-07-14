#!/usr/bin/env python3
"""bone_gpu_enrich.py -- use the collision NULL MODEL to find which grammar frames are enriched.

An individual hash collision carries no information about the true preimage (m2 is a uniform 32-bit
map, so a false positive is a uniformly-random string). What DOES carry information is the RATE: if a
grammar frame contains the developers' real naming convention, sweeping it against the real target
hashes yields hits ABOVE the random-collision baseline.

Method (a two-sample enrichment test):
  * REAL   = the unnamed bone hashes we want.
  * CONTROL= an equal number of random 32-bit hashes (same collision physics, zero real structure).
  Sweep every frame against BOTH. For each frame, expected hits under pure chance = N*T/2^32, identical
  for real and control. A frame where real_hits > control_hits (and > expectation) is ENRICHED -> its
  prefix/suffix + wild length is where a true name plausibly lives, and its hits are worth reading.
  A frame where real == control == ~expectation is pure noise -> discard.

This turns "we got junk hits" into "which shapes are worth a human look", without ever trusting an
individual collision.

Usage:
  python tools/bone_gpu_enrich.py               # 16 rig bones vs 16 random controls
  python tools/bone_gpu_enrich.py --ncontrol 64 # tighter null estimate
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from fnv import ALPHABET, m2  # noqa: E402

RIG_TARGETS = [
    0x491E8967, 0xE6FF1D72, 0xFAADBFFF, 0x11815D82, 0x00A8F086, 0xEB221048,
    0x0D29320C, 0x1E4780FA, 0xFE747044, 0x409403C6, 0xFBFA3B2C, 0xA3EEDAF2,
    0x87E8C062, 0x7D2C9CA4, 0xDB0322B7, 0x9EC352CF,
]

# Frames to test for enrichment. Deliberately spans several hypotheses about the naming scheme.
FRAMES = [
    ("bone_", ""), ("bone_", "1"), ("bone_", "2"), ("bone_", "roll"), ("bone_", "twist"),
    ("bone_l", ""), ("bone_r", ""), ("bone_l", "1"), ("bone_r", "1"),
    ("bone_", "bone1"), ("bone_l", "bone1"), ("bone_r", "bone1"),
    ("bone_attach_", ""), ("bone_spine", ""), ("bone_neck", ""), ("bone_head", ""),
    ("hp_", ""), ("hp_", "_l"), ("bone_", "_l"), ("bone_", "_r"),
]


def wild_str(gid: int, L: int) -> str:
    idx = [0] * L
    for p in range(L - 1, -1, -1):
        idx[p] = gid % 37
        gid //= 37
    return "".join(ALPHABET[i] for i in idx)


def deterministic_controls(n: int, avoid: set[int]) -> list[int]:
    """n pseudo-random 32-bit hashes (hash of an index string -> uniform, reproducible, no RNG)."""
    out = []
    i = 0
    while len(out) < n:
        h = m2(f"__control_seed_{i}__")
        i += 1
        if h not in avoid and h not in out:
            out.append(h)
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--ncontrol", type=int, default=48, help="control hashes per real hash group")
    ap.add_argument("--minlen", type=int, default=3)
    ap.add_argument("--maxlen", type=int, default=6)
    ap.add_argument("--device", type=int, default=0)
    args = ap.parse_args()

    try:
        from gpu_fast import FastWild
    except Exception as e:  # noqa: BLE001
        print(f"GPU unavailable ({e})", file=sys.stderr)
        return 2

    real = list(dict.fromkeys(RIG_TARGETS))
    controls = deterministic_controls(args.ncontrol, set(real))
    # scale factor: controls are more numerous, so normalise hit counts to per-target.
    fw_real = FastWild(args.device, set(real))
    fw_ctrl = FastWild(args.device, set(controls))

    print(f"REAL targets: {len(real)}   CONTROL targets: {len(controls)}")
    print(f"{'frame':<26}{'L':>2} {'cand':>14} {'exp/tgt':>9} "
          f"{'real/tgt':>9} {'ctrl/tgt':>9} {'enrich':>7}")
    enriched = []
    for prefix, suffix in FRAMES:
        for L in range(args.minlen, args.maxlen + 1):
            n = 37 ** L
            rc = [0]
            cc = [0]
            fw_real.sweep(prefix, L, suffix, lambda g, h: rc.__setitem__(0, rc[0] + 1))
            fw_ctrl.sweep(prefix, L, suffix, lambda g, h: cc.__setitem__(0, cc[0] + 1))
            real_per = rc[0] / len(real)
            ctrl_per = cc[0] / len(controls)
            exp_per = n / 2**32
            enrich = (real_per / ctrl_per) if ctrl_per > 0 else (float("inf") if real_per > 0 else 1.0)
            flag = ""
            # Enriched = real rate meaningfully exceeds BOTH the control rate and chance expectation.
            if real_per > exp_per * 1.5 and real_per > ctrl_per * 1.5 and rc[0] >= 2:
                flag = " <== ENRICHED"
                enriched.append((prefix, suffix, L, rc[0], cc[0]))
            frame = f"{prefix}*{suffix}"
            print(f"{frame:<26}{L:>2} {n:>14,} {exp_per:>9.4f} "
                  f"{real_per:>9.4f} {ctrl_per:>9.4f} {enrich:>7.2f}{flag}")

    print()
    if enriched:
        print("ENRICHED frames (real hits exceed the collision null -> worth a human read):")
        for prefix, suffix, L, r, c in enriched:
            print(f"  {prefix}<{L}>{suffix}: real={r} ctrl={c}")
            # dump the real hits from these frames for inspection
            hits = []
            fw_real.sweep(prefix, L, suffix, lambda g, h: hits.append(prefix + wild_str(g, L) + suffix))
            print(f"    {hits}")
    else:
        print("NO frame is enriched above the collision null model.")
        print("=> the true names are NOT in any tested grammar; every hit so far is a chance collision.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
