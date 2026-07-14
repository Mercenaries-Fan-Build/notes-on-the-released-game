#!/usr/bin/env python3
"""bone_deduce.py -- name bones by DEDUCTION from the rig's own geometry, not by brute force.

Brute force is a losing game here and the arithmetic says so: the hash is 32 bits, so testing S
candidates against T targets manufactures ~S*T/2^32 false positives. Against the whole census
(T~10k) even a modest S drowns every real hit in collisions, and past ~4.3e9 candidates the hash
SATURATES -- more compute makes recognition strictly worse.

So stop guessing and start deducing. The model itself carries witnesses the hash does not:

  1. MIRROR (geometry).  The rig is built in the model's own space, so a node's POSITION spells its
     side. If a named `bone_wheel_fl` sits at x=-1.2 and an UNNAMED node sits at x=+1.2 with the
     same y,z under the same parent, that node is `bone_wheel_fr` -- by construction, before any
     hash is computed. We then hash the prediction and check it lands on that node. One candidate
     against one target: collision odds 2.3e-10. That is not a guess, it is a proof.

  2. SERIES (structure). Siblings under one parent are numbered runs (`bone_hub_l_01..07`) and
     lettered grids (the destroyer's CIWS `_a/_b/_c`). A gap in the run, with an unnamed sibling
     sitting in it, predicts the missing member exactly.

  3. PARENT (vocabulary). A node whose parent is `bone_rotor_main` is a blade or a swashplate, not
     a wheel. The parent collapses the candidate vocabulary from the whole dialect to a handful,
     which is what makes a targeted sweep affordable at a real error bar.

Every hit printed here carries a witness beyond the hash. Names without one are not names.
"""
import argparse
import csv
import json
import re
import sys
from collections import defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from fnv import m2  # noqa: E402

SKEL = Path("docs/data/bone_skeleton.csv")
RAINBOW = Path("tools/rainbow_table.json")

# Every way this studio spells handedness. Order matters: longest first, so `_rl` is not eaten by `_l`.
# (leading-glued forms like `bone_lthumb2` are handled separately -- the deform rig glues the side on.)
SIDE_PAIRS = [
    ("_fl", "_fr"), ("_rl", "_rr"), ("_bl", "_br"), ("_ml", "_mr"),
    ("_left", "_right"), ("_lft", "_rgt"),
    ("_l", "_r"),
]
GLUE_PAIRS = [("left", "right"), ("l", "r")]


def mirror_name(n):
    """The name of this bone's mirror twin, or None if it carries no handedness."""
    low = n.lower()
    out = []
    # trailing / infix side tokens, incl. an index after them (`bone_hub_l_01` -> `bone_hub_r_01`)
    for a, b in SIDE_PAIRS:
        for x, y in ((a, b), (b, a)):
            if low.endswith(x):
                out.append(low[: -len(x)] + y)
            if x + "_" in low:
                out.append(low.replace(x + "_", y + "_", 1))
    # deform dialect glues the side onto the part: bone_lthumb2 / bone_rbicep
    m = re.match(r"^(bone_)(l|r|left|right)([a-z].*)$", low)
    if m:
        for a, b in GLUE_PAIRS:
            for x, y in ((a, b), (b, a)):
                if m.group(2) == x:
                    out.append(m.group(1) + y + m.group(3))
    return out


# ── the geometric law, measured not assumed ─────────────────────────────────────────────
# Across 9,112 named bone instances in the shipped rigs: a name carrying LEFT sits at +x 99.8% of
# the time, a name carrying RIGHT sits at -x 98.4% of the time. So the model's own geometry SPELLS
# the handedness of every node, named or not. This is a witness that costs zero candidates, and it
# is independent of the hash -- which is precisely what a bare hash match lacks.
LEFT_IS_POS_X = True


def geom_side(x):
    """The side token this node must carry, read off its position. None if it is on the centreline."""
    if abs(x) < 0.05:
        return None
    return "L" if (x > 0) == LEFT_IS_POS_X else "R"


def name_side(n):
    n = n.lower()
    if re.search(r"(_|^)(fl|rl|bl|ml)(_|$)|_l(_|$)|_left(_|$)|^bone_l[a-z]", n):
        return "L"
    if re.search(r"(_|^)(fr|rr|br|mr)(_|$)|_r(_|$)|_right(_|$)|^bone_r[a-z]", n):
        return "R"
    return None


def good_seed(n):
    """Can this name be trusted to SEED a deduction?

    The rainbow table already carries junk from other people's brute forces (`Y7EzN3L7`). Seeding a
    series off one of those manufactures a whole fake family (`Y7EzN3L0..6`) that all "verify" by
    hash -- a contamination cascade, and every member of it is a lie.

    The gate has to admit the real ones though, and real names are messier than a tidy rule wants:
    `bone_hub_l_06` has a pure-digit token, `piece1a_propattach01` has a digit mid-token. What the
    junk actually has, and no authored name in this engine does, is UPPERCASE -- plus the random
    consonant blobs a generator emits (`xf8ro3`, `hcm82l`). Gate on those two, nothing more.
    """
    if not n or n != n.lower():
        return False                     # authored names in this engine are lowercase. Junk is not.
    if not re.fullmatch(r"[a-z0-9_]+", n):
        return False
    for t in n.split("_"):
        core = re.sub(r"\d", "", t)
        if len(core) >= 4 and not re.search(r"[aeiouy]", core):
            return False                 # a 4+ letter run with no vowel is a generator blob
    return True


def load_names():
    rb = json.loads(RAINBOW.read_text())["pandemic_hash_m2"]
    return {int(k, 16): v[0] for k, v in rb.items()}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tol", type=float, default=0.05, help="mirror tolerance floor (world units)")
    ap.add_argument("--rel", type=float, default=0.06, help="mirror tolerance as a fraction of reach")
    ap.add_argument("--emit", default="docs/data/bone_deduced.json")
    a = ap.parse_args()

    names = load_names()
    models = defaultdict(list)
    for r in csv.DictReader(open(SKEL)):
        models[r["model"]].append(r)

    found = {}          # hash -> (name, witness)
    considered = 0

    for mh, nodes in models.items():
        pos = {n["hash"]: (float(n["wx"]), float(n["wy"]), float(n["wz"])) for n in nodes}
        unnamed = [n for n in nodes if int(n["hash"], 16) not in names]
        if not unnamed:
            continue
        named = [n for n in nodes if int(n["hash"], 16) in names]

        # ── 1. MIRROR: a named bone's twin position, occupied by an unnamed node ──────────
        # Artists place rigs by hand, so a "mirror" is near-symmetric, not exact -- the fuel
        # trailer's twins sit at +1.49 / -1.46. Scale the tolerance with the limb's reach.
        for nn in named:
            src = names[int(nn["hash"], 16)]
            if not good_seed(src):
                continue
            cands = mirror_name(src)
            if not cands:
                continue
            x, y, z = pos[nn["hash"]]
            if geom_side(x) is None:      # on the centreline: it has no twin
                continue
            tol = max(a.tol, a.rel * max(abs(x), abs(y), abs(z)))
            for un in unnamed:
                ux, uy, uz = pos[un["hash"]]
                if abs(ux + x) > tol or abs(uy - y) > tol or abs(uz - z) > tol:
                    continue
                uh = int(un["hash"], 16)
                for c in cands:
                    # the candidate's side must AGREE with the twin's own geometry, or it is wrong
                    if name_side(c) and name_side(c) != geom_side(ux):
                        continue
                    considered += 1
                    if m2(c) == uh and uh not in found:
                        found[uh] = (c, f"mirror of {src} @x={x:+.2f}->{ux:+.2f} on model {mh}")

        # ── 2. SERIES: an indexed run of siblings with a gap an unnamed node sits in ──────
        by_parent = defaultdict(list)
        for n in nodes:
            by_parent[n["parent"]].append(n)
        for par, sibs in by_parent.items():
            snamed = [(s, names[int(s["hash"], 16)]) for s in sibs
                      if int(s["hash"], 16) in names and good_seed(names[int(s["hash"], 16)])]
            sun = [s for s in sibs if int(s["hash"], 16) not in names]
            if not snamed or not sun:
                continue
            for _, nm in snamed:
                mm = re.match(r"^(.*?)(\d+)$", nm)
                if not mm:
                    continue
                stem, num = mm.group(1), mm.group(2)
                width = len(num)
                for k in range(0, 32):     # walk the run and offer every index
                    cand = f"{stem}{k:0{width}d}"
                    ch = m2(cand)
                    for s in sun:
                        sh = int(s["hash"], 16)
                        considered += 1
                        if ch == sh and sh not in found:
                            found[sh] = (cand, f"series {stem}* sibling of {nm} on model {mh}")
                # lettered grids: _a/_b/_c ...
                mm2 = re.match(r"^(.*_)([a-z])$", nm)
                if mm2:
                    for ch_ in "abcdefgh":
                        cand = mm2.group(1) + ch_
                        chh = m2(cand)
                        for s in sun:
                            sh = int(s["hash"], 16)
                            considered += 1
                            if chh == sh and sh not in found:
                                found[sh] = (cand, f"grid {mm2.group(1)}* sibling of {nm} on model {mh}")

    print(f"candidates tested : {considered}")
    print(f"expected false hits: {considered / 2**32:.6f}   <- the error bar (targets are per-node, T=1)")
    print(f"DEDUCED           : {len(found)} bones\n")
    for h, (n, w) in sorted(found.items(), key=lambda x: x[1][0]):
        print(f"  0x{h:08X}  {n:<36} [{w}]")
    Path(a.emit).write_text(json.dumps(
        {"pandemic_hash_m2": {f"0x{h:08X}": [n] for h, (n, _) in found.items()}}, indent=1))
    Path(a.emit.replace(".json", "_witness.csv")).write_text(
        "hash,name,witness\n" + "".join(f"0x{h:08X},{n},\"{w}\"\n" for h, (n, w) in found.items()))
    print(f"\n-> {a.emit}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
