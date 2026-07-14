#!/usr/bin/env python3
r"""bone_dictsweep.py -- REAL-DICTIONARY product sweeps against exact hash targets, with the error
bar computed and printed for every single sweep.

The game's own 648k-token vocabulary is exhausted; these names are words the shipped game never
spells. So the vocabulary has to come from OUTSIDE: a frequency-ranked English list, a hand-built
3D/rigging/automotive/destruction lexicon, and The Saboteur's decompilation (same studio, same
riggers -- `susp` came from there and cracked bone_susp_rl/rr).

THE ONLY THING THAT MAKES A HIT MEAN ANYTHING:

    EF = S * T / 2^32          S = candidates swept, T = targets

A 20k-word sweep against T=3,305 gave 1,585 hits against 1,615 expected noise -- every one of them
readable, every one of them garbage. The same vocabulary against T=1 costs EF ~ 0.005. Nothing about
the words changed; only T did. So: one target at a time, S kept under ~1e9, EF printed, and any sweep
whose EF exceeds ~1 is reported as noise-dominated rather than quietly believed.

Vocabulary tiers (size is the whole point -- a tier exists so that S stays affordable):
    TINY   ~20     node-prefix morphemes (bone, hp, grp, ...)
    SMALL  ~400    domain words: destruction, vehicle rigging, mesh/LOD
    MID    ~26k    common English (top-20k frequency) + the technical lexicon
    BIG    ~380k   all of words_alpha + Saboteur tokens + the technical lexicon
"""
from __future__ import annotations

import argparse
import itertools
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from fnv import m2  # noqa: E402

# --------------------------------------------------------------------------------------------
# the domain lexicon -- what a Pandemic rigger plausibly types for a destruction/LOD group node
# --------------------------------------------------------------------------------------------
SMALL = """
bone hp grp group node obj object mesh geo geom geometry poly proxy cage hull shape rig skin deform
bind joint jnt dummy locator null helper xform transform pivot anchor attach attachment hardpoint
socket mount dock slot hub axle tire tyre rim tread rubber wheel spoke sprocket idler roadwheel
track caliper brake rotor disc drum strut shock susp suspension spring damper linkage tierod spindle
bearing shaft chassis frame subframe body bodywork panel fender wing quarter rocker pillar roof hood
bonnet trunk boot tailgate bumper spoiler skirt grille glass window door handle hinge latch mirror
pristine ruin ruined wreck wrecked wreckage destroyed destroy destruction destructible destruct
damage damaged dmg broken break breakable burnt debris rubble shard frag fragment chunk piece part
slice splinter gib shatter crumble collapse intact whole undamaged
switch swap state states variant version alt alternate toggle select selector option
prop static dynamic physics phys collision collide col shadow blur cast render renderable visible
hide hidden show low med medium high fine coarse near far detail tier level lod lods
front rear back left right top bottom upper lower inner outer mid middle center centre side
main aux sub base root parent child leaf trunk branch
turret barrel muzzle breech recoil mantlet cupola hatch coax gun cannon weapon rocket missile
launcher magazine ammo bolt trigger sight scope
rotor blade swash swashplate mast collective cyclic skid tailrotor tailboom boom pylon piston
scissor droop flap aileron elevator rudder fin stabilizer canopy cockpit fuselage nacelle prop
propeller spinner gear
keel bow stern deck cleat davit funnel bilge gunwale anchor winch
seat driver passenger gunner commander loader crew rider
light lamp beam glow flare flash spark smoke fire flame dust fx vfx effect emitter particle
maya max biped physique scene hierarchy hier tree graph world local
dcc export exporter bake baked cook
placeholder temp tmp test junk spare unused old new
cull occluder imposter impostor billboard
morph blendshape pose clip anim animation constraint ik fk control ctrl
container assembly module component element unit item entity
master primary secondary
""".split()

TINY = ["bone", "hp", "grp", "group", "node", "obj", "mesh", "geo", "rig", "vz", "mdl", "model",
        "veh", "vehicle", "car", "dcc", "x", "m2", "pg", "pmc"]

NUMS = ([""] + [str(i) for i in range(10)] + ["%02d" % i for i in range(21)]
        + list("abcdefgh") + ["00", "01", "02", "0", "1", "2", "3"])


def load_tiers(dictdir: Path) -> dict[str, list[str]]:
    big: set[str] = set()
    for fn in ("words_alpha.txt", "saboteur_vocab.txt", "tech.txt"):
        p = dictdir / fn
        if p.exists():
            for w in p.read_text(errors="ignore").split():
                w = w.strip().lower()
                if w.isascii() and w.isalpha() and 2 <= len(w) <= 20:
                    big.add(w)
    mid: set[str] = set()
    p = dictdir / "en50k.txt"
    if p.exists():
        for i, line in enumerate(p.read_text(errors="ignore").splitlines()):
            if i >= 20000:
                break
            w = line.split()[0].strip().lower()
            if w.isascii() and w.isalpha() and len(w) >= 3:
                mid.add(w)
    p = dictdir / "20k.txt"
    if p.exists():
        for w in p.read_text(errors="ignore").split():
            w = w.strip().lower()
            if w.isascii() and w.isalpha() and len(w) >= 3:
                mid.add(w)
    p = dictdir / "tech.txt"
    if p.exists():
        for w in p.read_text(errors="ignore").split():
            w = w.strip().lower()
            if w.isascii() and w.isalpha() and len(w) >= 2:
                mid.add(w)
    mid |= set(SMALL)
    big |= set(SMALL) | mid
    return {"TINY": sorted(set(TINY)), "SMALL": sorted(set(SMALL)),
            "MID": sorted(mid), "BIG": sorted(big), "NUMS": NUMS}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dictdir", required=True)
    ap.add_argument("--targets", required=True, help="comma-separated 0xHASH, or @file")
    ap.add_argument("--label", default="targets")
    ap.add_argument("--out", help="write hits as JSON here")
    ap.add_argument("--ef-cap", type=float, default=2.0,
                    help="refuse to run a sweep whose expected-false exceeds this")
    args = ap.parse_args()

    from gpu_product import ProductCracker

    if args.targets.startswith("@"):
        raw = Path(args.targets[1:]).read_text().split()
    else:
        raw = args.targets.split(",")
    targets = [int(t.strip().rstrip(","), 16) for t in raw if t.strip()]
    T = len(targets)

    V = load_tiers(Path(args.dictdir))
    for k in ("TINY", "SMALL", "MID", "BIG"):
        print(f"  {k:<6} {len(V[k]):>7,} words")
    print(f"\ntargets T = {T}\n")

    # Every sweep: (name, [slot tiers], separator patterns to enumerate)
    # S is the raw candidate count; EF = S*T/2^32 is printed and enforced.
    PLANS = [
        ("1-word BIG",            ["BIG"],                    [()]),
        ("BIG + digits/letter",   ["BIG", "NUMS"],            [(0,), (1,)]),
        ("SMALL x BIG",           ["SMALL", "BIG"],           [(0,), (1,)]),
        ("BIG x SMALL",           ["BIG", "SMALL"],           [(0,), (1,)]),
        ("MID x MID",             ["MID", "MID"],             [(0,), (1,)]),
        ("SMALL x SMALL x SMALL", ["SMALL", "SMALL", "SMALL"], list(itertools.product((0, 1), repeat=2))),
        ("TINY x SMALL x MID",    ["TINY", "SMALL", "MID"],   list(itertools.product((0, 1), repeat=2))),
        ("TINY x MID x SMALL",    ["TINY", "MID", "SMALL"],   list(itertools.product((0, 1), repeat=2))),
        ("TINY x BIG",            ["TINY", "BIG"],            [(0,), (1,)]),
        ("SMALL x SMALL x NUMS",  ["SMALL", "SMALL", "NUMS"], list(itertools.product((0, 1), repeat=2))),
        ("TINY x SMALL x NUMS",   ["TINY", "SMALL", "NUMS"],  list(itertools.product((0, 1), repeat=2))),
    ]

    pc = ProductCracker(0, targets)
    all_hits: dict[int, set[str]] = {}
    tot_S = 0
    print(f"{'sweep':<24} {'S':>15} {'EF = S*T/2^32':>15}  hits")
    print("-" * 68)
    for label, tiers, sepsets in PLANS:
        slots = [V[t] for t in tiers]
        base = 1
        for s in slots:
            base *= len(s)
        S = base * len(sepsets)
        ef = S * T / 2 ** 32
        if ef > args.ef_cap:
            print(f"{label:<24} {S:>15,} {ef:>15.3f}  SKIPPED (EF over cap {args.ef_cap})")
            continue
        hits: list[tuple[str, int]] = []
        for seps in sepsets:
            pc.sweep(slots, list(seps), lambda n, h, _h=hits: _h.append((n, h)))
        tot_S += S
        for n, h in hits:
            if m2(n) == h:
                all_hits.setdefault(h, set()).add(n)
        tag = "" if ef < 0.3 else ("  <- read with care" if ef < 1 else "  <- NOISE-DOMINATED")
        print(f"{label:<24} {S:>15,} {ef:>15.3f}  {len(hits)}{tag}")
        for n, h in sorted(hits)[:12]:
            print(f"    0x{h:08X}  {n}")

    print("-" * 68)
    print(f"{'TOTAL':<24} {tot_S:>15,} {tot_S * T / 2**32:>15.3f}  "
          f"{sum(len(v) for v in all_hits.values())} hit(s) on {len(all_hits)} target(s)")
    if not all_hits:
        print("\nNO HIT. Given the EF column above, that is a CLEAN NEGATIVE: none of these targets is")
        print("any name this dictionary can spell in these shapes.")
    if args.out and all_hits:
        Path(args.out).write_text(json.dumps(
            {"pandemic_hash_m2": {f"0x{h:08X}": sorted(v) for h, v in all_hits.items()}}, indent=1))
        print(f"\n-> {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
