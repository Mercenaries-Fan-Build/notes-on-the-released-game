#!/usr/bin/env python3
"""bone_gpu_crack.py -- GPU-accelerated name recovery for unnamed Mercenaries 2 HIER-node hashes.

Wraps the community `gpu_fast.FastWild` kernel (~7.5 G cand/s on an RTX 2000 Ada) to sweep
`<prefix> + wild(L) + <suffix>` templates against a set of target hashes. The wildcard alphabet is
`fnv.ALPHABET` (a-z 0-9 _), which spells every authored bone/hardpoint name seen so far.

Why a driver and not raw sweeps: the m2 hash is 32-bit, so a sweep of N candidates against T targets
mints ~N*T/2^32 ACCIDENTAL collisions that pass `m2(name)==hash` while being names the game never used
(see docs/reverse_engineer/bone_census.md 4c). This driver therefore:
  * prints the expected-false-positive count for every sweep, so a result is never read blind;
  * re-validates each raw hit on the CPU (kernel parity guard);
  * keeps only hits whose decoded string, WITH its fixed prefix/suffix, reads like a plausible token
    (has an internal separator or a known morpheme) -- a hit in a high-noise sweep is flagged LOW-CONF.

Templates are morpheme-structured (prefix/suffix are FIXED authored fragments; only the short middle is
wild), which keeps the wild span L small so expected-false stays < 1 even at billions of candidates.

Usage:
  python tools/bone_gpu_crack.py                 # sweep the 16 unnamed human-rig bones (built-in targets)
  python tools/bone_gpu_crack.py --census        # sweep ALL unnamed hashes in docs/data/bone_census.csv
  python tools/bone_gpu_crack.py --hashes 0xAAA,0xBBB
  python tools/bone_gpu_crack.py --maxlen 7      # widen the wildcard span (slower, more noise)
"""
from __future__ import annotations

import argparse
import csv
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from fnv import ALPHABET, m2  # noqa: E402

# The 16 unnamed bones of the 105-track human reference rig (docs/reverse_engineer/bone_census.md 4b),
# pinned anatomically by their neighbours in track order.
RIG_TARGETS = {
    0x491E8967, 0xE6FF1D72, 0xFAADBFFF, 0x11815D82, 0x00A8F086, 0xEB221048,
    0x0D29320C, 0x1E4780FA, 0xFE747044, 0x409403C6, 0xFBFA3B2C, 0xA3EEDAF2,
    0x87E8C062, 0x7D2C9CA4, 0xDB0322B7, 0x9EC352CF,
}

# (prefix, suffix) morpheme frames. The wildcard fills the middle; keep both ends authored so the wild
# span L stays short. Suffixes cover the observed numbering / side / roll conventions.
FRAMES = [
    ("bone_", ""), ("bone_", "1"), ("bone_", "2"), ("bone_", "3"),
    ("bone_", "roll"), ("bone_", "twist"), ("bone_", "_end"), ("bone_", "_l"), ("bone_", "_r"),
    ("bone_l", ""), ("bone_r", ""), ("bone_l", "1"), ("bone_r", "1"),
    ("bone_attach_", ""), ("bone_attach_", "left"), ("bone_attach_", "right"),
    ("hp_", ""), ("hp_", "_l"), ("hp_", "_r"), ("hp_attach_", ""),
    ("bone_", "bone1"), ("bone_l", "bone1"), ("bone_r", "bone1"),  # the Bone_LFootBone1 pattern
]


def wild_str(gid: int, L: int) -> str:
    idx = [0] * L
    for p in range(L - 1, -1, -1):
        idx[p] = gid % 37
        gid //= 37
    return "".join(ALPHABET[i] for i in idx)


_TOKENISH = re.compile(r"^[a-z][a-z0-9]*(_[a-z0-9]+)*$")


def plausible(name: str) -> bool:
    """A readable, token-shaped candidate (letters + optional _-separated groups, no lone digit runs)."""
    if not _TOKENISH.match(name):
        return False
    # reject all-consonant or digit-salad middles that read as hash noise
    letters = [c for c in name if c.isalpha()]
    vowels = sum(c in "aeiou" for c in letters)
    return len(letters) >= 3 and vowels >= 1


def load_targets(args) -> dict[int, str]:
    """hash -> context label."""
    if args.hashes:
        return {int(h, 16): "cli" for h in args.hashes.split(",")}
    if args.census:
        p = Path("docs/data/bone_census.csv")
        out = {}
        for r in csv.DictReader(open(p)):
            if not r["name"]:
                out[int(r["hash"], 16)] = f"m={r['n_models']} anim={r['anim_tracks']}"
        return out
    return {h: "rig" for h in RIG_TARGETS}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--census", action="store_true", help="sweep all unnamed census hashes")
    ap.add_argument("--hashes", help="comma-separated 0x hashes to target")
    ap.add_argument("--minlen", type=int, default=2)
    ap.add_argument("--maxlen", type=int, default=6, help="max wildcard span (37^L candidates/frame)")
    ap.add_argument("--device", type=int, default=0)
    args = ap.parse_args()

    try:
        from gpu_fast import FastWild
    except Exception as e:  # noqa: BLE001
        print(f"GPU path unavailable ({e}). Need cupy-cuda12x + nvidia-cuda-nvrtc-cu12.", file=sys.stderr)
        return 2

    targets = load_targets(args)
    tset = set(targets)
    print(f"targets: {len(tset)}   frames: {len(FRAMES)}   wild L: {args.minlen}..{args.maxlen}")
    fw = FastWild(args.device, tset)

    confirmed: dict[int, list[str]] = {}
    lowconf: dict[int, list[str]] = {}
    total_cand = 0

    for prefix, suffix in FRAMES:
        for L in range(args.minlen, args.maxlen + 1):
            n = 37 ** L
            total_cand += n
            exp_false = n * len(tset) / 2**32
            raw: list[tuple[int, int]] = []
            fw.sweep(prefix, L, suffix, lambda g, h: raw.append((g, h)))
            for g, h in raw:
                name = prefix + wild_str(g, L) + suffix
                if m2(name) != h:  # kernel parity guard
                    print(f"  !! kernel/CPU mismatch {name!r} 0x{h:08X}", file=sys.stderr)
                    continue
                bucket = confirmed if (plausible(name) and exp_false < 0.5) else lowconf
                bucket.setdefault(h, [])
                if name not in bucket[h]:
                    bucket[h].append(name)

    print(f"\nswept {total_cand:,} candidates across {len(FRAMES)} frames")
    print(f"\n=== PLAUSIBLE hits (low-noise frames, token-shaped) ===")
    if not confirmed:
        print("  (none)")
    for h, names in sorted(confirmed.items()):
        print(f"  0x{h:08X} [{targets[h]}] -> {names}")
    print(f"\n=== LOW-CONFIDENCE hits (high-noise frame or non-token string; treat as collisions) ===")
    print(f"  {sum(len(v) for v in lowconf.values())} across {len(lowconf)} hashes (not shown; likely noise)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
