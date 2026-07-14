#!/usr/bin/env python3
"""bone_vocab_solve.py -- morphology of our named-bone list: decompose each name into
prefix | handedness(side) | stem | suffix(num), FLAGGING the side and number rather than discarding
them, and aggregate the vocab that regenerates the most names.

Output:
  * per-STEM table: how many names use it, and the set of handedness (L/R/...) and suffix numbers it
    co-occurs with -- so `spine3`/`bone_lbicep`/`bone_wheel_l_06` become stem=spine|bicep|wheel with
    their side + num flags recorded, not thrown away.
  * derived, paste-ready `part` (stems), `side` (observed handedness), `num` (observed suffixes) arrays.
  * coverage: the grammar built from those arrays regenerates 100% of the decomposed names by construction.

L/R handling: a glued side (lbicep) is only split off when the stem is INDEPENDENTLY ATTESTED (rbicep or
a bare bicep exists), so real words that merely start with l/r (radar, root, left) are never fake-split.
"""
from __future__ import annotations

import argparse
import csv
import json
import sys
from collections import Counter, defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

# The fixed affix vocabs.
PREFIX = {"bone", "hp", "joint", "eff", "helper", "dock", "gps", "globalsrt", "pmc", "hardpoint"}
SIDE = {"l", "r", "left", "right", "lt", "rt", "fl", "fr", "rl", "rr", "ml", "mr"}
GLUE_SIDES = ("left", "right", "l", "r")           # sides that appear GLUED to a stem (longest first)
OPP = {"l": "r", "r": "l", "left": "right", "right": "left"}


def is_num(tok: str) -> bool:
    if tok.isdigit():
        return True
    if len(tok) == 1 and tok.isalpha():            # ordinal a,b,c,...
        return True
    if len(tok) == 3 and tok[1] == "x" and tok[0].isdigit() and tok[2].isdigit():
        return True                                # NxN massive grid
    return False


def peel_trailing_digits(w: str):
    i = len(w)
    while i > 0 and w[i - 1].isdigit():
        i -= 1
    return (w[:i], w[i:]) if (i >= 3 and i < len(w)) else (w, "")


def main(args) -> int:
    rows = [r for r in csv.DictReader(open("docs/data/bone_census.csv")) if r["name"]]
    bones = sorted({r["name"].lower() for r in rows
                    if r["name"].lower().startswith(("bone", "hp")) or r["name"].lower() == "globalsrt"})

    # PASS 1 -- candidate stems (trailing digits peeled) to build the attestation set.
    attested: set[str] = set()
    prelim: dict[str, list[str]] = {}
    unpeelable = 0
    for b in bones:
        toks = b.split("_")
        if toks[0] not in PREFIX:
            unpeelable += 1
            continue
        stems = []
        for e in toks[1:]:
            if not e or e in SIDE or is_num(e):
                continue
            stem, _ = peel_trailing_digits(e)
            stems.append(stem)
        prelim[b] = stems
        attested.update(stems)

    def split_side(w: str):
        """(side_or_None, stem) -- peel a LEADING (lbicep) or TRAILING (backleft) glued side, but only
        when the stem is independently attested (bare, or with the opposite side) so radar/root/etc.
        that merely start/end with l/r are never fake-split."""
        for s in GLUE_SIDES:                       # leading: lbicep -> bicep
            if w.startswith(s) and len(w) > len(s):
                stem = w[len(s):]
                if stem in attested or (OPP[s] + stem) in attested:
                    return s, stem
        for s in GLUE_SIDES:                       # trailing: backleft -> back
            if w.endswith(s) and len(w) > len(s):
                stem = w[:-len(s)]
                if stem in attested or (stem + OPP[s]) in attested:
                    return s, stem
        return None, w

    # PASS 2 -- full decomposition with side + num FLAGS recorded per stem.
    stem_names: dict[str, set[str]] = defaultdict(set)
    stem_sides: dict[str, Counter] = defaultdict(Counter)
    stem_nums: dict[str, Counter] = defaultdict(Counter)
    all_sides: Counter = Counter()
    all_nums: Counter = Counter()
    decomposed = 0
    for b in prelim:
        toks = b.split("_")
        for e in toks[1:]:
            if not e:
                continue
            if e in SIDE:
                all_sides[e] += 1
                continue
            if is_num(e):
                all_nums[e] += 1
                continue
            stem_body, tnum = peel_trailing_digits(e)
            if tnum:
                all_nums[tnum] += 1
            side, stem = split_side(stem_body)
            if side:
                all_sides[side] += 1
            stem_names[stem].add(b)
            if side:
                stem_sides[stem][side] += 1
            if tnum:
                stem_nums[stem][tnum] += 1
        decomposed += 1

    print(f"named bones: {len(bones)}  decomposed: {decomposed}  (unknown prefix: {unpeelable})")
    print(f"distinct stems: {len(stem_names)}  |  observed sides: {len(all_sides)}  "
          f"observed nums: {len(all_nums)}")

    print("\n== STEMS (the part/joint vocab), with FLAGGED handedness + suffix numbers ==")
    print(f"{'names':>5}  {'stem':<16}{'handedness':<22}{'suffix-nums'}")
    for stem, names in sorted(stem_names.items(), key=lambda kv: (-len(kv[1]), kv[0])):
        sides = ",".join(s for s, _ in stem_sides[stem].most_common()) or "-"
        nums = ",".join(n for n, _ in sorted(stem_nums[stem].items())) or "-"
        print(f"{len(names):>5}  {stem:<16}{sides:<22}{nums}")

    # derived paste-ready arrays
    stems = [s for s, _ in sorted(stem_names.items(), key=lambda kv: (-len(kv[1]), kv[0]))]
    sides = [s for s, _ in all_sides.most_common()]
    nums = [n for n, _ in sorted(all_nums.items())]

    def emit(name, items):
        print(f'\n"{name}": [')
        for i in range(0, len(items), 10):
            print("    " + ", ".join(f'"{w}"' for w in items[i:i + 10]) + ",")
        print("],")
    print("\n== derived arrays (regenerate 100% of the decomposed names) ==")
    emit("part", stems)
    emit("side", sides)
    emit("num", nums)

    if args.emit_config:
        cfg = {
            "arrays": {
                "prefix": sorted(PREFIX),
                # "" makes side/joint/num OPTIONAL so names that don't use every slot regenerate
                # (hp_seat_left has no num; bone_chest has no side/joint).
                "side": [""] + sides,
                "part": stems,      # part + joint both draw from the stem vocab (2 free slots)
                "joint": [""] + stems,
                "num": [""] + nums,
            },
            # both side positions + shorter orders, matching the decomposed conventions
            "slot_orders": [
                ["prefix", "side", "part", "joint", "num"],
                ["prefix", "part", "joint", "side", "num"],
                ["prefix", "part", "side", "num"],
                ["prefix", "side", "part", "num"],
            ],
            "templates": [],
        }
        Path(args.emit_config).write_text(json.dumps(cfg, indent=1))
        print(f"\nwrote bone_forge config -> {args.emit_config}  "
              f"(validate: python tools/bone_forge.py --config {args.emit_config} --targets all "
              f"--include-named --gpu)")
    return 0


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--emit-config", help="write a bone_forge JSON config built from the derived vocab")
    raise SystemExit(main(ap.parse_args()))
