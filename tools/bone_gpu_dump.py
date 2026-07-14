#!/usr/bin/env python3
"""bone_gpu_dump.py -- exhaustive GPU sweep, dump ALL raw hits per target for MANUAL inspection.

Rationale: the readability heuristic is worse than a human eye (it over-rewards a trailing morpheme like
"twist" glued to a garbage middle). The candidate space per target is small enough (a few hundred to ~1-2k
hits) to eyeball, so this tool does NOT filter -- it collects every verified hit, sorts them most-name-like
first (so any real name floats to the top), dedupes, and writes one file per target under
`output/bone_candidates/`. A human then scans for the one real string.

Coverage: bare prefixes (`bone_`, `hp_`, `bone_attach_`) swept to --barelen (default 8 -> names up to ~13
chars); side + suffix frames swept to --suffixlen (default 7) to reach long structured names cheaply
(`bone_l` + 7 + `roll`, etc.). Alphabet = a-z 0-9 _ (37), so `_` can appear inside the wild span.

Usage:
  python tools/bone_gpu_dump.py                 # 15 unnamed rig bones, comprehensive
  python tools/bone_gpu_dump.py --barelen 7     # faster (names to ~12 chars)
  python tools/bone_gpu_dump.py --hashes 0xAAA,0xBBB
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from fnv import ALPHABET, m2  # noqa: E402

RIG_TARGETS = {
    0x491E8967: "trk3 heads LEFT leg chain (under Hips, before LThigh)",
    0xE6FF1D72: "trk10 heads RIGHT leg chain",
    0xFAADBFFF: "trk17 between Spine2 and Chest",
    0x11815D82: "trk22 after attach_backL/R, before neck",
    0x00A8F086: "trk25 under Head",
    0xEB221048: "trk26 parent of jaw",
    0x0D29320C: "trk28 jaw region (mirror +X of trk31)",
    0x409403C6: "trk31 jaw region (mirror -X of trk28)",
    0x1E4780FA: "trk29 face chain",
    0xFE747044: "trk30 face chain",
    0xFBFA3B2C: "trk32 face chain",
    0xA3EEDAF2: "trk33 face chain",
    0x87E8C062: "trk54 between Lshoulder and LBicep",
    0x7D2C9CA4: "trk76 between Rshoulder and RBicep",
    0x9EC352CF: "trk104 accessory tail (after bone_hair)",
}

BARE = [("bone_", ""), ("hp_", ""), ("bone_attach_", "")]
SIDED = [("bone_l", ""), ("bone_r", "")]
SUFFIXED = [
    ("bone_", "1"), ("bone_", "2"), ("bone_", "3"), ("bone_", "roll"), ("bone_", "twist"),
    ("bone_", "_l"), ("bone_", "_r"), ("bone_", "bone1"), ("bone_", "bone2"),
    ("bone_l", "roll"), ("bone_r", "roll"), ("bone_l", "twist"), ("bone_r", "twist"),
    ("bone_l", "bone1"), ("bone_r", "bone1"), ("bone_l", "1"), ("bone_r", "1"),
    ("hp_", "_l"), ("hp_", "_r"), ("bone_attach_", "left"), ("bone_attach_", "right"),
]

MORPHEMES = set("""
head neck spine chest hip hips pelvis waist back belly rib ribcage torso root base tail butt glute
shoulder clav clavicle collar deltoid delt bicep tricep forearm arm hand palm wrist elbow finger thumb
index middle ring pinky knuckle thigh shin calf knee ankle foot toe heel leg upperarm upperleg lowerleg
jaw chin lip lips mouth nose nostril cheek brow eyebrow eye eyeball eyelid lid ear tongue teeth tooth gum
skull temple forehead face hair ponytail beard sideburn goatee lash bone jnt joint roll twist attach
chain necklace cigar hat cap helmet goggle glasses holster pistol gun weapon rifle knife grenade pouch
mag magazine belt strap sling pack backpack radio antenna muzzle barrel shell eject prop item tool light
camera aim look upper lower inner outer front rear left right top bottom mid center side up low ub lb
""".split())
VOWELS = set("aeiou")
_WORDRE = re.compile("|".join(sorted(MORPHEMES, key=len, reverse=True)))


def wild_str(gid: int, L: int) -> str:
    idx = [0] * L
    for p in range(L - 1, -1, -1):
        idx[p] = gid % 37
        gid //= 37
    return "".join(ALPHABET[i] for i in idx)


def likeness(name: str) -> float:
    """Sort key: higher = more name-like. Purely for ORDERING.

    Scored on the WILD MIDDLE ONLY. Scoring the whole string is worthless: the fixed prefix/suffix are
    real morphemes by construction, so `bone_attach_<junk>left` would outrank a readable middle. Only the
    searched span carries information.
    """
    t = name
    letters = [c for c in t if c.isalpha()]
    if not letters:
        return 0.0
    vr = sum(c in VOWELS for c in letters) / len(letters)
    covered = sum(len(m.group()) for m in _WORDRE.finditer(t))
    coverage = covered / len(t)
    longest_cons = max((len(r) for r in re.findall(r"[bcdfghjklmnpqrstvwxyz]+", t)), default=0)
    digit_run = max((len(r) for r in re.findall(r"[0-9]+", t)), default=0)
    pen = (0.25 if longest_cons >= 4 else 0) + (0.25 if digit_run >= 2 else 0) \
        + (0.2 if not 0.2 <= vr <= 0.6 else 0)
    return coverage - pen + 0.15 * min(1.0, vr / 0.4)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--hashes")
    ap.add_argument("--barelen", type=int, default=8)
    ap.add_argument("--suffixlen", type=int, default=7)
    ap.add_argument("--cap", type=int, default=1500, help="max hits written per target")
    ap.add_argument("--device", type=int, default=0)
    ap.add_argument("--outdir", default="output/bone_candidates")
    args = ap.parse_args()

    try:
        from gpu_fast import FastWild
    except Exception as e:  # noqa: BLE001
        print(f"GPU unavailable ({e})", file=sys.stderr)
        return 2

    targets = ({int(h, 16): "cli" for h in args.hashes.split(",")} if args.hashes
               else dict(RIG_TARGETS))
    tset = set(targets)
    fw = FastWild(args.device, tset)

    plan = ([(p, s, L) for (p, s) in BARE + SIDED for L in range(3, args.barelen + 1)]
            + [(p, s, L) for (p, s) in SUFFIXED for L in range(3, args.suffixlen + 1)])
    total = sum(37 ** L for _, _, L in plan)
    print(f"targets={len(tset)}  sweeps={len(plan)}  candidates={total:,}  (~{total/7.5e9/60:.1f} min)")

    # store (full name, wild-middle) so ranking scores only the searched span
    hits: dict[int, set[tuple[str, str]]] = {h: set() for h in tset}
    for prefix, suffix, L in plan:
        got: list[tuple[int, int]] = []
        fw.sweep(prefix, L, suffix, lambda g, h: got.append((g, h)))
        for g, h in got:
            mid = wild_str(g, L)
            name = prefix + mid + suffix
            if m2(name) == h:
                hits[h].add((name, mid))
        print(f"  {prefix}<{L}>{suffix:<6} -> {len(got)} raw", flush=True)

    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)
    index = []
    for h, label in targets.items():
        # rank by the WILD MIDDLE only; keep ALL hits (no cap -- the real name must not be truncated away)
        ranked = sorted(hits[h], key=lambda nm: likeness(nm[1]), reverse=True)
        f = outdir / f"{h:08X}.txt"
        with open(f, "w", encoding="utf-8") as fh:
            fh.write(f"# 0x{h:08X}  {label}\n")
            fh.write(f"# {len(ranked)} hits, sorted by readability of the WILD MIDDLE (real name floats up).\n")
            fh.write("# Every line hashes to this bone. Almost all are chance collisions -- find the ONE\n")
            fh.write("# real authored name by eye (readable, matches the position above), ignore the rest.\n\n")
            fh.write("\n".join(name for name, _ in ranked) + "\n")
        index.append((h, label, len(ranked), f.name))
        print(f"  0x{h:08X}: {len(ranked):>5} hits -> {f}")

    with open(outdir / "INDEX.txt", "w", encoding="utf-8") as fh:
        fh.write("# Unnamed human-rig bones -- GPU candidate dumps for manual inspection.\n")
        fh.write("# Reference skeleton order: docs/data/human_rig_reference_105.txt\n\n")
        for h, label, n, fn in index:
            fh.write(f"0x{h:08X}  {n:>5} hits  {fn}   {label}\n")
    print(f"\nwrote {len(index)} files + INDEX.txt to {outdir}/")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
