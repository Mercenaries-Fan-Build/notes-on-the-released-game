#!/usr/bin/env python3
"""bone_gpu_exhaustive.py -- exhaustive GPU wildcard sweep with READABILITY ranking.

Runs the community `gpu_fast.FastWild` kernel over `<prefix> + wild(L) + <suffix>` for every wild
length L up to --maxlen, across the known authored prefixes/suffixes. The alphabet is the full
`fnv.ALPHABET` (a-z 0-9 _), so this is a true exhaustive character substitution of the name TAIL.

The catch (why raw output is useless past L~5): m2 is 32-bit, so `37^L * T / 2^32` candidates collide
by pure chance. At L=7 with 16 targets that is ~350 garbage hits/target. Exhaustive coverage is easy;
RECOGNITION is the problem. So every hit is scored by readability and only the readable ones are shown:
  * vowel ratio in a sane band,
  * coverage by real morphemes (anatomy / rig / gear words),
  * no long consonant or digit runs.
A readable hit is still only a *candidate* (a readable collision is possible) -- confirm with position
in the reference rig + a convention witness before trusting it (see docs/reverse_engineer/bone_census.md).

Usage:
  python tools/bone_gpu_exhaustive.py                    # 16 rig bones, L<=7 (~minutes)
  python tools/bone_gpu_exhaustive.py --maxlen 8         # L<=8 (adds ~8 min/frame; full coverage)
  python tools/bone_gpu_exhaustive.py --hashes 0xAAA     # arbitrary targets
  python tools/bone_gpu_exhaustive.py --minscore 0.6     # stricter readability gate
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from fnv import ALPHABET, m2  # noqa: E402

RIG_TARGETS = {
    0x491E8967: "trk3 heads LEFT leg chain (under Hips)",
    0xE6FF1D72: "trk10 heads RIGHT leg chain",
    0xFAADBFFF: "trk17 between Spine2 and Chest",
    0x11815D82: "trk22 after attach_back*, before neck",
    0x00A8F086: "trk25 under Head",
    0xEB221048: "trk26 parent of jaw",
    0x0D29320C: "trk28 jaw region (mirror +X)",
    0x1E4780FA: "trk29 face chain",
    0xFE747044: "trk30 face chain",
    0x409403C6: "trk31 jaw region (mirror -X)",
    0xFBFA3B2C: "trk32 face chain",
    0xA3EEDAF2: "trk33 face chain",
    0x87E8C062: "trk54 between Lshoulder and LBicep",
    0x7D2C9CA4: "trk76 between Rshoulder and RBicep",
    0x9EC352CF: "trk104 accessory tail (after hair)",
}  # note: 0xDB0322B7 (trk102) already solved = bone_ub

# Authored frames. Prefix+suffix fixed; only the tail is wild.
FRAMES = [
    ("bone_", ""), ("bone_", "1"), ("bone_", "2"), ("bone_", "3"),
    ("bone_", "roll"), ("bone_", "twist"), ("bone_", "_l"), ("bone_", "_r"),
    ("bone_l", ""), ("bone_r", ""), ("bone_l", "1"), ("bone_r", "1"),
    ("bone_attach_", ""), ("hp_", ""), ("hp_", "_l"), ("hp_", "_r"),
]

# morphemes real Mercs2 bone/hardpoint names are built from (for readability coverage scoring)
MORPHEMES = set("""
head neck spine chest hip hips pelvis waist back belly rib ribcage torso root base tail butt glute
shoulder clav clavicle collar deltoid delt bicep tricep forearm arm hand palm wrist elbow finger
thumb index middle ring pinky knuckle thigh shin calf knee ankle foot toe heel leg upperarm upperleg
lowerleg upperleg jaw chin lip lips mouth nose nostril cheek brow eyebrow eye eyeball eyelid lid ear
tongue teeth tooth gum skull temple forehead face hair ponytail beard sideburn goatee lash bone jnt
joint roll twist attach root chain necklace cigar hat cap helmet goggle glasses holster pistol gun
weapon rifle knife grenade pouch mag magazine belt strap sling pack backpack radio antenna muzzle
barrel shell eject prop item tool light fx camera aim look upper lower inner outer front rear left
right top bottom mid center side up low ub lb dm nm sm
""".split())

VOWELS = set("aeiou")
_WORDRE = re.compile("|".join(sorted(MORPHEMES, key=len, reverse=True)))


def wild_str(gid: int, L: int) -> str:
    idx = [0] * L
    for p in range(L - 1, -1, -1):
        idx[p] = gid % 37
        gid //= 37
    return "".join(ALPHABET[i] for i in idx)


def readability(tail: str) -> float:
    """0..1 score. Rewards morpheme coverage + sane vowel ratio; penalises long consonant/digit runs."""
    t = tail.strip("_")
    if not t:
        return 0.0
    letters = [c for c in t if c.isalpha()]
    if len(letters) < 3:
        return 0.0
    vowel_ratio = sum(c in VOWELS for c in letters) / len(letters)
    # morpheme coverage: fraction of chars covered by dictionary morphemes
    covered = sum(len(m.group()) for m in _WORDRE.finditer(t))
    coverage = min(1.0, covered / len(t))
    # penalties
    longest_cons = max((len(r) for r in re.findall(r"[bcdfghjklmnpqrstvwxyz]+", t)), default=0)
    digit_run = max((len(r) for r in re.findall(r"[0-9]+", t)), default=0)
    penalty = 0.0
    if longest_cons >= 4:
        penalty += 0.3
    if digit_run >= 2:
        penalty += 0.3
    if not (0.2 <= vowel_ratio <= 0.65):
        penalty += 0.3
    return max(0.0, 0.6 * coverage + 0.4 * min(1.0, vowel_ratio / 0.4) - penalty)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--hashes", help="comma-separated 0x targets (default: 15 unnamed rig bones)")
    ap.add_argument("--minlen", type=int, default=3)
    ap.add_argument("--maxlen", type=int, default=7)
    ap.add_argument("--minscore", type=float, default=0.45)
    ap.add_argument("--device", type=int, default=0)
    args = ap.parse_args()

    try:
        from gpu_fast import FastWild
    except Exception as e:  # noqa: BLE001
        print(f"GPU unavailable ({e})", file=sys.stderr)
        return 2

    if args.hashes:
        targets = {int(h, 16): "cli" for h in args.hashes.split(",")}
    else:
        targets = dict(RIG_TARGETS)
    tset = set(targets)

    total = sum(37 ** L for _, _ in FRAMES for L in range(args.minlen, args.maxlen + 1))
    print(f"targets={len(tset)}  frames={len(FRAMES)}  L={args.minlen}..{args.maxlen}  "
          f"total candidates={total:,}  (~{total/7.5e9:.0f}s @ 7.5 G/s)")
    print(f"break-even L (exp-false=1): 37^L=2^32/{len(tset)} -> L~"
          f"{__import__('math').log(2**32/len(tset))/__import__('math').log(37):.1f} "
          f"(beyond this, ALL hits include chance collisions)\n")

    fw = FastWild(args.device, tset)
    # hash -> list of (score, name)
    cand: dict[int, list[tuple[float, str]]] = {h: [] for h in tset}
    raw_total = 0
    for prefix, suffix in FRAMES:
        for L in range(args.minlen, args.maxlen + 1):
            hits: list[tuple[int, int]] = []
            fw.sweep(prefix, L, suffix, lambda g, h: hits.append((g, h)))
            for g, h in hits:
                tail = wild_str(g, L)
                name = prefix + tail + suffix
                if m2(name) != h:
                    continue
                raw_total += 1
                sc = readability(tail + (suffix.strip("_") if suffix else ""))
                if sc >= args.minscore:
                    cand[h].append((sc, name))

    print(f"raw hits across all frames: {raw_total:,}  "
          f"(these are mostly chance collisions; readability filter follows)\n")
    print(f"=== READABLE candidates per target (score >= {args.minscore}) ===")
    any_readable = False
    for h, label in targets.items():
        cs = sorted(set(cand[h]), reverse=True)[:8]
        if cs:
            any_readable = True
            print(f"\n0x{h:08X}  [{label}]")
            for sc, name in cs:
                print(f"    {sc:.2f}  {name}")
    if not any_readable:
        print("  (no hit cleared the readability gate at any length)")
    print("\nNOTE: a readable hit is a CANDIDATE, not proof. Past L~5 every target also has hundreds of")
    print("unreadable collisions; confirm any candidate by reference-rig position + a convention witness.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
