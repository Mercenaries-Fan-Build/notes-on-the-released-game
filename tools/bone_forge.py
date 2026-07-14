#!/usr/bin/env python3
r"""bone_forge.py -- human-driven combinatorial name generator + tester for the unnamed rig bones.

You supply the ingenuity: define ARRAYS of word-pieces and mustache TEMPLATES that combine them, and
this expands the full cross-product, hashes every candidate with pandemic_hash_m2, and reports which ones
land on an unnamed HIER-node hash -- with the bone's reference-rig position and automatic mirror-pair
corroboration.

------------------------------------------------------------------------------------------------------
TEMPLATE SYNTAX (mustache):  a template is a string with `{{arrayname}}` placeholders + literal text.
  "bone_{{side}}{{part}}{{num}}"   expands over ARRAYS["side"] x ARRAYS["part"] x ARRAYS["num"].
  - The same array may appear twice: "bone_{{part}}_{{part}}" -> all ORDERED pairs of parts.
  - Put "" (empty string) in an array to make that slot OPTIONAL.
  - Literal text (bone_, _, roll, etc.) stays as-is.
  - UNDERSCORES LIVE IN THE TEMPLATE, not the arrays. Write the separator where you want it and use ONE
    bare `side` array: glued `bone_{{side}}{{part}}` -> bone_lbicep; underscore-separated
    `bone_{{part}}_{{side}}` -> bone_nose_left. When an optional value collapses to "", the resulting
    dangling/double underscore is auto-cleaned (`bone_nose_` -> bone_nose, `bone__jaw` -> bone_jaw), so
    you never need `side_` / `_side` variants.

Edit the EDIT ZONE below (ARRAYS + TEMPLATES), then run:
  python tools/bone_forge.py                     # test against the 15 unnamed rig bones
  python tools/bone_forge.py --targets all       # test against ALL 976 unnamed census hashes
  python tools/bone_forge.py --hashes 0xAAA,0xBBB
  python tools/bone_forge.py --config my.json    # load ARRAYS/TEMPLATES from JSON instead of the EDIT ZONE
  python tools/bone_forge.py --dump hits.txt     # also write every hit to a file
Config JSON shape: {"arrays": {"side": ["l","r"], ...}, "templates": ["bone_{{side}}{{part}}"]}
------------------------------------------------------------------------------------------------------
Honesty note: m2 is 32-bit, so a run of N candidates against T targets yields ~N*T/2^32 CHANCE hits.
The script prints this expected-false number every run. A hit is only trustworthy when it is (a) readable,
(b) right for the bone's position, and (c) corroborated -- ideally its mirror partner is hit in the SAME
run. That three-way agreement is what confirmed `bone_ub`. One lone hit in a big run is likely noise.
"""
from __future__ import annotations

import argparse
import csv
import itertools
import json
import re
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from fnv import m2  # noqa: E402

# The Windows console defaults to cp1252, which chokes on non-ASCII in output; force UTF-8.
try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:  # noqa: BLE001
    pass

# ====================================================================================================
# EDIT ZONE -- put your ingenuity here.  Arrays are lists of word-pieces; "" means "optional / skip".
# ====================================================================================================
ARRAYS: dict[str, list[str]] = {
    "prefix": [
        "bone", "joint", "jnt", "eff", "helper", "dock", "gps",
        "dummy", "pmc", "hardpoint", "hp",
     ],
    # sidedness -- ONE bare array. Put the separator in the template: {{side}}{{part}} glues (bone_lbicep),
    # {{part}}_{{side}} separates (bone_nose_left). Empty "" -> the underscore auto-cleans.
    "side":   [
        "l", "r", 
        "left", "right", "eff",
    ],
    # body regions (extend freely -- this is where human insight goes)
    "part": [
        "yaw", "pitch", "roll", 
        "base", "root", "center", "centerpoint",
        "upper", "lower",

        "weapon", "weapons", "barrel", "barreltip", "pitch", "roll", "twist", "bend",
        "dock", "pda",
        
        "pmc", "light", "medium", "heavy", 
        "mouth", "jaw", "chin", "nose", "eye", "eyebrow", "ear", "head",
        "neck", "shoulder", "arm", "forearm", "hand", "finger", "thumb",
        "chest", "torso", "hip", "pelvis", "leg", "thigh", "calf", "foot", "toe",
         "eye", "eyelid", "eyelids", "eyebrow", "mouth", "finger", "thumb",  "hand",
        "calf", "thigh", "grip", "spine", "foot",
    ],

    # trailing decorations
    "num":    [
        "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10",
        "00", "01", "02", "03", "04", "05", "06", "07", "08", "09",
        "000", "001", "002", "003", "004", "005", 
        "a", "b", "c", "d", "e", "f", "x", "y", "z",
        "1x1", "2x2", "6x6", "7x7", "8x8", "9x9",
        "4x1", "4x4",
],
    "joint":  [
        "root", "mid", "center", "centerpoint", 
        "yaw", "pitch", "roll", "bend", "curve", "arch", 
        "dock", "pda", "radar",
    ],
}

# SLOT_ORDERS -- ordered lists of ARRAY keys. For EACH order, every underscore-present/missing pattern
# BETWEEN the slots is auto-enumerated (2^(n-1) templates), so you never hand-write separator variants:
#   ["prefix","side","part","num"] -> {{prefix}}{{side}}{{part}}{{num}},  {{prefix}}_{{side}}{{part}}{{num}},
#   {{prefix}}{{side}}_{{part}}{{num}}, ... all 8.  A slot's "" value drops it and the stray underscore
#   auto-cleans, so key-present/absent is covered too. Add more orders (e.g. side after part) freely.
SLOT_ORDERS: list[list[str]] = [
    ["prefix", "side", "part", "joint", "num"],   # leading side:  bone_lbicep, bone_yaw_radar
    ["prefix", "part", "joint", "side", "num"],   # trailing side: hp_seat_left, bone_wheel_l_01, hp_dock_right
    ["prefix", "part", "joint"],
    ["prefix", "side", "joint"],
    ["prefix", "joint"],
    ["prefix", "side"],
    ["prefix", "part"],
]

# Optional hand-written templates, unioned with the auto-generated ones. Usually leave empty.
TEMPLATES: list[str] = []
# ====================================================================================================
# END EDIT ZONE
# ====================================================================================================

# ── PARITY LAW (proved; 3000/3000 random cases, and all 5 known glued pairs obey it) ────────
# 'l' = 0x6C and 'r' = 0x72 are BOTH EVEN. In FNV-1a each byte is XORed into the state and then
# multiplied by an ODD prime, so an odd*odd product preserves bit 0: swapping one even byte for
# another even byte at the same position CANNOT change bit 0 of the final hash.
#
# Therefore: if two bones' hashes DIFFER IN BIT 0, their names cannot differ by a single l<->r
# character anywhere -- not `bone_lX`/`bone_rX`, not `X_l`/`X_r`. (A multi-character swap such as
# `_left`/`_right` is NOT excluded; only the single-char form is.)
#
# ★ This kills a premise we had been attacking from: trk3 (0x491E8967, bit0=1) and trk10
# (0xE6FF1D72, bit0=0) were recorded below as a LEFT/RIGHT leg-chain mirror pair, and every
# brute-force sweep aimed at them generated `bone_l*`/`bone_r*` candidates that were structurally
# incapable of being right. Their bind offsets are not mirrored either. They are NOT a glued pair.
def parity_allows_glued_pair(h1: int, h2: int) -> bool:
    """False => these two hashes cannot be a single-char l/r rename of each other. Free exclusion."""
    return (h1 & 1) == (h2 & 1)


# Unnamed rig-bone slots: hash -> (reference-rig position, mirror-sibling hash or None).
SLOTS = {
    # ★ NOT a glued l/r pair -- parity law forbids it (bit0 1 vs 0). Mirror field cleared; a
    # multi-char `_left`/`_right` spelling remains possible, a single-char one does not.
    0x491E8967: ("trk3 heads LEFT leg chain (under Hips) [NOT a glued l/r pair: parity]", None),
    0xE6FF1D72: ("trk10 heads RIGHT leg chain [NOT a glued l/r pair: parity]", None),
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

_MUSTACHE = re.compile(r"\{\{(\w+)\}\}")


def auto_templates(slot_order: list[str]) -> list[str]:
    """Every underscore present/missing combination between the ordered slots -> 2^(n-1) templates.

    ["prefix","side","part","num"] yields {{prefix}}{{side}}{{part}}{{num}} (all glued) through
    {{prefix}}_{{side}}_{{part}}_{{num}} (all separated) and every mix between.
    """
    if not slot_order:
        return []
    out = []
    for bits in itertools.product(("", "_"), repeat=max(0, len(slot_order) - 1)):
        s = "{{" + slot_order[0] + "}}"
        for sep, key in zip(bits, slot_order[1:]):
            s += sep + "{{" + key + "}}"
        out.append(s)
    return out


def expand(template: str, arrays: dict[str, list[str]]):
    """Yield every string the template produces. Each {{name}} occurrence iterates its array."""
    parts = _MUSTACHE.split(template)  # [lit, name, lit, name, ..., lit]
    literals = parts[0::2]
    names = parts[1::2]
    for name in names:
        if name not in arrays:
            raise SystemExit(f"template {template!r} references undefined array {{{{{name}}}}} "
                             f"-- add it to ARRAYS (have: {sorted(arrays)})")
    pools = [arrays[n] for n in names]
    for combo in itertools.product(*pools):
        s = literals[0]
        for lit, val in zip(literals[1:], combo):
            s += val + lit
        # An optional ("") value leaves a dangling/double/leading underscore where the auto-enumerator
        # placed a separator (bone_nose_ / bone__jaw / _wheel from an empty prefix). Collapse runs and
        # trim both ends so one bare array covers glued + separated conventions and dropped slots.
        s = re.sub(r"_{2,}", "_", s).strip("_")
        yield s


# ── geometric mirror pairs: the census hands the forge a 64-bit constraint ──────────────────
# Measured over 9,112 named bone instances in the shipped rigs: a name carrying LEFT sits at +x
# 99.8% of the time, RIGHT at -x 98.4%. So two UNNAMED nodes at (+x,y,z) and (-x,y,z), same depth,
# same parent, are the SAME PART ON OPPOSITE SIDES -- established by the model's own geometry,
# before any name is guessed.
#
# It is tempting to conclude that demanding BOTH hashes fall at once
#
#     m2(stem + left_spelling) == left.hash   AND   m2(stem + right_spelling) == right.hash
#
# is a 64-bit proof. IT IS NOT, and believing so will fill your corpus with confident garbage.
#
# m2 is FNV-1a: h = ((h ^ byte) * PRIME) per byte. Take two names that differ ONLY in the side
# character. They share a prefix, so they share the running hash state right up to that character;
# they share a suffix, so the bytes after it are folded in identically. Undo the suffix (PRIME is
# odd, so it is invertible mod 2^32) and the unknown prefix state CANCELS. The result: the map
#
#     m2(<anything> + "l" + suffix)  ->  m2(<anything> + "r" + suffix)
#
# is a FIXED BIJECTION determined by the suffix alone. Verified on 2,000 random prefixes: 2000/2000.
#
# So the moment a candidate lands on the left-hand target by ordinary 32-bit chance, its right-hand
# twin lands AUTOMATICALLY. The second hash is not independent evidence -- it is a restatement of the
# first. This is how `hpjiie_mount_fl_a` / `hpjiie_mount_fr_a` "confirmed" as a pair off a garbage
# stem harvested from binary noise.
#
# What the pair test DOES buy, honestly:
#   * targets shrink to nodes that are actually half of a geometric mirror pair, and
#   * the candidate's side-char POSITION and trailing SUFFIX must match the real name's, or the
#     bijection maps it somewhere else and it fails to pair.
# That is a useful FORM filter worth a few bits. It is not a proof, and it does not license a huge
# vocabulary. The error bar below is reported at its true 32-bit value. A pair still needs a real
# second witness -- a meaningful stem, or the model it sits on -- exactly like every other name here.
_SIDE_SWAP = [("fl", "fr"), ("rl", "rr"), ("bl", "br"), ("ml", "mr"),
              ("left", "right"), ("lft", "rgt"), ("l", "r")]


def swap_side(name: str) -> list[str]:
    """Every spelling of this name with its handedness flipped."""
    low, out = name.lower(), []
    for a, b in _SIDE_SWAP:
        for x, y in ((a, b), (b, a)):
            # as a whole underscore-delimited token: bone_hub_l_01 -> bone_hub_r_01
            toks = low.split("_")
            for i, t in enumerate(toks):
                if t == x:
                    out.append("_".join(toks[:i] + [y] + toks[i + 1:]))
            # glued onto the part, deform-rig style: bone_lthumb2 -> bone_rthumb2
            m = re.match(rf"^(bone_){x}([a-z].*)$", low)
            if m:
                out.append(f"{m.group(1)}{y}{m.group(2)}")
    return list(dict.fromkeys(out))


def load_geom_pairs(tol: float = 0.05, rel: float = 0.06) -> dict[int, set[int]]:
    """Unnamed mirror pairs, read straight off the rigs. hash -> {twin hashes}."""
    skel = Path("docs/data/bone_skeleton.csv")
    if not skel.exists():
        raise SystemExit("--pairs needs docs/data/bone_skeleton.csv -- run:\n"
                         "  mercs2_probe bone-census --wads game-files/vz.wad,game-files/vz-patch.wad "
                         "--csv docs/data/bone_census.csv --skeleton-csv docs/data/bone_skeleton.csv")
    named = set()
    rbp = Path("tools/rainbow_table.json")
    if rbp.exists():
        named = {int(k, 16) for k in json.loads(rbp.read_text())["pandemic_hash_m2"]}
    models: dict[str, list[dict]] = {}
    for r in csv.DictReader(open(skel)):
        models.setdefault(r["model"], []).append(r)
    pairs: dict[int, set[int]] = {}
    for nodes in models.values():
        un = [n for n in nodes if int(n["hash"], 16) not in named]
        left = [n for n in un if float(n["wx"]) > 0.05]
        right = [n for n in un if float(n["wx"]) < -0.05]
        for L in left:
            lx, ly, lz = float(L["wx"]), float(L["wy"]), float(L["wz"])
            t = max(tol, rel * max(abs(lx), abs(ly), abs(lz)))
            for R in right:
                rx, ry, rz = float(R["wx"]), float(R["wy"]), float(R["wz"])
                if abs(rx + lx) > t or abs(ry - ly) > t or abs(rz - lz) > t:
                    continue
                if L["depth"] != R["depth"] or L["parent"] == R["parent"] and L["hash"] == R["hash"]:
                    continue
                lh, rh = int(L["hash"], 16), int(R["hash"], 16)
                if lh == rh:
                    continue
                pairs.setdefault(lh, set()).add(rh)
                pairs.setdefault(rh, set()).add(lh)
    return pairs


# ── systematic mode: many SMALL pools instead of one big sweep ──────────────────────────────
#
# False flags scale as S*T/2^32 -- candidates times targets. The instinct is that a bigger sweep
# finds more; the arithmetic says a bigger sweep finds more NOISE, at exactly the same rate it finds
# names, until past ~4.3e9 candidates every target has a chance preimage and recognition dies. That
# is not a reason to abandon brute force. It is a reason to shrink BOTH pools.
#
# So: stop sweeping the whole dialect against all 8,262 unknowns at once. The skeleton gives every
# unnamed bone a MODEL, a PARENT, SIBLINGS and a POSITION. Solve it as its own problem --
#
#   T = 1        (this bone, not "some bone somewhere"), and
#   S = a few thousand candidates drawn from THIS bone's context: the words its parent and siblings
#                use, its model's class, and the side its geometry demands.
#
# Expected false flags per bone: S/2^32 ~ 1e-6. A hit is then almost certainly the real name -- and
# because we know which bone it is, the structural witness (does it fit where it sits?) is available
# to confirm it. Sweeping 8,262 bones this way costs less noise than ONE naive 30M-candidate run.
def context_pool(node, model_nodes, names, base_vocab):
    """The candidate names worth testing for ONE bone, drawn from what surrounds it."""
    h = int(node["hash"], 16)
    x = float(node["wx"])
    # 1. vocabulary: what the neighbours actually say
    vocab, pats = set(), set()
    par = node["parent"]
    for other in model_nodes:
        oh = int(other["hash"], 16)
        nm = names.get(oh)
        if not nm or oh == h:
            continue
        sib = other["parent"] == par          # a sibling speaks loudest
        low = nm.lower()
        if not low.startswith(("bone_", "hp_")):
            continue
        # the naming PATTERN of a named sibling, with its side/index blanked -> a template for us
        pat = re.sub(r"(?<=_)(fl|fr|rl|rr|bl|br|ml|mr|l|r|left|right)(?=_|$)", "{side}", low)
        pat = re.sub(r"\d+", "{num}", pat)
        if sib:
            pats.add(pat)
        for t in low.split("_"):
            t = re.sub(r"\d+$", "", t)
            if len(t) >= 2 and t.isalpha() and t not in ("bone", "hp"):
                vocab.add(t)
    vocab |= base_vocab
    # 2. the side is NOT guessed -- the geometry states it (+x = left, measured 99.8%)
    if abs(x) < 0.05:
        sides = [""]
    elif x > 0:
        sides = ["l", "fl", "rl", "bl", "ml", "left"]
    else:
        sides = ["r", "fr", "rr", "br", "mr", "right"]
    nums = ["", "01", "02", "03", "04", "05", "06", "07", "a", "b", "c", "d", "1", "2", "3", "4"]
    out = set()
    # 3a. fill a named sibling's own pattern -- the strongest shape we have
    for p in pats:
        for s in sides:
            for nu in nums:
                out.add(re.sub(r"_?\{side\}", ("_" + s) if s else "", p).replace("{num}", nu))
    # 3b. plus the plain grammar over the local vocabulary
    for pre in ("bone", "hp"):
        for w in vocab:
            for s in sides:
                for nu in nums:
                    for form in (f"{pre}_{w}_{s}_{nu}", f"{pre}_{w}_{s}{nu}", f"{pre}_{w}{s}{nu}",
                                 f"{pre}_{s}_{w}_{nu}", f"{pre}_{s}{w}{nu}"):
                        out.add(re.sub(r"_{2,}", "_", form).strip("_"))
    return out


def load_targets(args) -> dict[int, str]:
    if getattr(args, "pairs", False):
        pr = load_geom_pairs()
        return {h: f"pair({len(v)})" for h, v in pr.items()}
    if args.hashes:
        return {int(h, 16): "cli" for h in args.hashes.split(",")}
    if args.targets == "all":
        p = Path("docs/data/bone_census.csv")
        out = {}
        for r in csv.DictReader(open(p)):
            h = int(r["hash"], 16)
            if r["name"]:
                # already-cracked bones. Included only with --include-named; a hit that regenerates the
                # KNOWN name confirms the template vocab, a hit with a different string is a collision.
                if getattr(args, "include_named", False):
                    out[h] = f"known={r['name']}"
            else:
                out[h] = f"m={r['n_models']} anim={r['anim_tracks']}"
        return out
    return {h: lbl for h, (lbl, _) in SLOTS.items() if "SOLVED" not in lbl}


# -- vehicle-CLASS lexicons: signal-to-noise comes from a pool RELEVANT to its targets ---------
# Sharding does not reduce total noise -- S*T/2^32 is the same however you slice it. What sharding
# buys is that each shard sweeps a candidate pool built for ITS OWN targets. A helicopter shard
# spends its budget on rotor/swash/skid; a boat shard on hull/cleat/mast. Same compute, far higher
# hit density -- and the handful of false flags arrive already attached to a model you can eyeball.
CLASS_WORDS = {
    "helicopter": ["rotor", "blade", "swash", "swashplate", "mast", "collective", "cyclic",
                   "skid", "tailrotor", "tailboom", "boom", "stabilizer", "pylon", "pitchlink",
                   "scissor", "droop", "flapping", "spindle", "strut", "piston", "shaft"],
    "plane": ["wing", "flap", "aileron", "elevator", "rudder", "fin", "stabilizer", "slat",
              "spoiler", "airbrake", "canopy", "nose", "gear", "strut", "engine", "intake",
              "exhaust", "prop", "propeller", "spinner", "pylon", "tail", "tailplane"],
    "tank": ["turret", "barrel", "mantlet", "recoil", "breech", "hatch", "track", "sprocket",
             "idler", "roadwheel", "torsion", "skirt", "cupola", "coax", "commander",
             "gunner", "driver", "loader", "smoke", "frontwheel", "rearwheel"],
    "apc": ["turret", "hatch", "ramp", "periscope", "smoke", "track", "sprocket", "idler",
            "steering", "gunmount", "firingport"],
    "car": ["brake", "strut", "shock", "susp", "spring", "damper", "hood", "trunk", "bumper",
            "fender", "mirror", "steering", "headlight", "taillight", "wiper", "glass", "spoiler"],
    "truck": ["brake", "strut", "shock", "susp", "rod", "spring", "hood", "bed", "cab", "trailer",
              "hitch", "mirror", "steering", "tailgate", "fender", "bumper", "winch", "crane",
              "boom", "arm", "bucket", "plow"],
    "boat": ["hull", "keel", "bow", "stern", "deck", "mast", "rudder", "prop", "propeller",
             "shaft", "cleat", "rail", "ladder", "anchor", "winch", "cabin", "bridge", "ciws",
             "lifeboat", "davit", "hatch", "davits", "funnel", "sam", "launcher"],
    "": ["wheel", "hub", "axle", "door", "hatch", "mount", "seat", "dock", "gun", "light",
         "cover", "panel", "glass", "attach", "pivot", "roll", "barrel", "turret"],
}

RIGGER_BASE = ["wheel", "hub", "axle", "brake", "strut", "shock", "susp", "rod", "spring", "damper",
               "door", "hatch", "flap", "rotor", "blade", "prop", "shaft", "piston", "turret",
               "barrel", "barreltip", "mount", "seat", "dock", "gun", "gunmount", "light", "antenna",
               "radar", "dish", "engine", "exhaust", "wing", "fin", "rudder", "elevator", "aileron",
               "gear", "track", "sprocket", "idler", "cover", "panel", "glass", "mirror", "ramp",
               "ladder", "winch", "hook", "cable", "steering", "attach", "pivot", "roll", "ruin"]


# -- BUILDING / DESTRUCTION dialect ------------------------------------------------------------
# Buildings are the bulk of the unknowns (416 models, ~17.8k bone instances) and they do NOT speak
# the rigger dialect -- sweeping them with wheel/rotor vocabulary is why the old `misc` shard was
# 43 expected-false and nearly all junk. Their bones are DESTRUCTION pieces, and the grammar is read
# straight off the ones already named:
#
#   piece1a  piece1b  Slice2A..Slice2D  Slice4A      <- shard id: <kind><N><letter>
#   piece1a_propattach00 .. _propattach12            <- prop mounts ON a shard
#   floor02.piece1b                                  <- ★ DOT-separated compound: <component><NN>.<shard>
#   ruin  foundation  attachments                    <- whole-state nodes
#   hp_fx_light  hp_light  hp_ladder_top_a  hp_spawn_a..d
#
# (case is irrelevant -- m2 folds it -- so `Slice2A` and `slice2a` are the same hash.)
# The grammar is narrow, so the pool is ~10^5 rather than 10^7: a shard with excellent signal-to-noise.
BLD_COMPONENTS = ["floor", "wall", "roof", "ceiling", "door", "window", "stair", "stairs", "column",
                  "beam", "pillar", "balcony", "railing", "fence", "gate", "corner", "side", "front",
                  "back", "top", "bottom", "base", "foundation", "chimney", "awning", "sign", "porch",
                  "tower", "platform", "ramp", "step", "ledge", "arch", "dome", "panel", "slab"]
BLD_KINDS = ["piece", "slice", "chunk", "part", "frag", "debris", "shard", "blast"]
BLD_STATES = ["", "ruin", "pristine", "intact", "broken", "damaged"]
BLD_HP = ["hp_fx_light", "hp_light", "hp_spawn", "hp_ladder_top", "hp_ladder_bottom", "hp_ladder",
          "hp_door", "hp_window", "hp_fx_smoke", "hp_fx_fire", "hp_fx_spark", "hp_cover",
          "hp_prop", "hp_propattach", "hp_attach", "hp_fx", "hp_climb", "hp_vault"]


def _building_pool():
    """The destruction grammar. ~10^5 candidates -- small BECAUSE the grammar is narrow, not despite it."""
    out = set()
    letters = "abcdefgh"
    nums = [str(i) for i in range(1, 10)]
    idx2 = ["%02d" % i for i in range(0, 40)]
    # the shard ids themselves: piece1a, slice2c, ...
    shards = [k + n + L for k in BLD_KINDS for n in nums for L in letters]
    for sid in shards:
        out.add(sid)
        for st in BLD_STATES:
            if st:
                out.add(sid + "_" + st)
        # prop mounts on a shard: piece1a_propattach00
        for i in idx2:
            out.add(sid + "_propattach" + i)
            out.add(sid + "_propattach" + i + "_ruin")
    # ★ the dot-compound: floor02.piece1b  (and the underscore twin, in case both were used)
    for c in BLD_COMPONENTS:
        for cn in [""] + idx2[:21]:
            base = c + cn
            out.add(base)
            for st in BLD_STATES:
                if st:
                    out.add(base + "_" + st)
            for sid in shards:
                out.add(base + "." + sid)
                out.add(base + "_" + sid)
    # hardpoints, with the a-h / 00-nn suffix families the named ones use
    for hp in BLD_HP:
        out.add(hp)
        for L in letters:
            out.add(hp + "_" + L)
        for i in idx2[:12]:
            out.add(hp + "_" + i)
            out.add(hp + i)
    for st in ["ruin", "pristine", "foundation", "attachments", "intact", "base", "static"]:
        out.add(st)
    return {s for s in out if 3 <= len(s) <= 40}


def _class_of(model_name):
    low = model_name.lower()
    for k in CLASS_WORDS:
        if k and ("_" + k + "_") in low:
            return k
    return ""


def side_law_applies(model_name, wx):
    """Is the +x=LEFT law EVIDENCE for this node, or does it know nothing about it?

    The law was measured on rigs that are SYMMETRIC BY CONSTRUCTION -- vehicles and characters, where
    an artist built a left part and mirrored it. There, x-sign genuinely spells handedness (99.8%).

    It says NOTHING about a building. A destruction chunk sitting at x=-62 is not "right-handed"; it
    is simply over there, 62 metres across a warehouse. Letting the law vouch for a building-piece
    name manufactures corroboration out of nothing -- and it nearly did: five noise hits on children
    of `piece1a_ruin` all passed a naive side check because their chunks happened to sit at -x.

    So: the law is evidence only on a symmetric rig, and only within a rig-sized distance of centre.
    """
    if not _class_of(model_name):
        return False                      # not a vehicle rig -> the law is silent
    return 0.05 < abs(wx) < 12.0          # beyond a rig's own half-width, x is placement, not side


def _shard_pool(words, sides, nums, mods):
    """Candidate names for one shard. Kept in the 1-4M band on purpose -- see run_systematic."""
    out = set()
    for pre in ("bone", "hp"):
        for w in words:
            for md in mods:
                stem = (pre + "_" + md + "_" + w) if md else (pre + "_" + w)
                for s in sides:
                    for nu in nums:
                        for form in (stem + "_" + s + "_" + nu, stem + "_" + s + nu,
                                     stem + s + nu, pre + "_" + s + "_" + w + nu):
                            out.add(re.sub(r"_{2,}", "_", form).strip("_"))
    return out


def _solve_shard(job):
    """One shard = one model's unknowns + a pool built for that model's CLASS. Runs in a worker."""
    model_hash, model_name, targets, neighbour_words = job
    cls = _class_of(model_name)
    words = sorted(set(CLASS_WORDS[cls]) | set(CLASS_WORDS[""]) | set(RIGGER_BASE) | set(neighbour_words))
    sides = ["", "l", "r", "fl", "fr", "rl", "rr", "bl", "br", "ml", "mr", "left", "right"]
    nums = ["", "01", "02", "03", "04", "05", "06", "07", "a", "b", "c", "d", "1", "2", "3", "4"]
    mods = ["", "front", "rear", "top", "bottom", "inner", "outer", "upper", "lower", "main",
            "attach", "mount", "cover", "ruin", "roll", "pivot"]
    pool = _shard_pool(words, sides, nums, mods)
    tset = set(targets)
    hits = []
    for cand in pool:
        if 3 <= len(cand) <= 40:
            h = m2(cand)
            if h in tset:
                hits.append((h, cand))
    return model_hash, model_name, cls, len(pool), len(tset), hits


# -- CLASS SHARDS: redistribute the workload so the signal is not drowned ----------------------
# Noise is S*T/2^32 -- candidates times targets. One giant sweep against all 8,000+ unknowns puts T
# in the thousands and buries the real names in chance preimages. The fix is not to stop brute
# forcing; it is to SHARD, so that each sweep is a small, relevant problem:
#
#   * T shrinks -- a shard targets only the bones of ONE vehicle class (hundreds, not thousands).
#   * S gets RELEVANT -- a helicopter shard spends its budget on rotor/swash/skid, a boat shard on
#     hull/cleat/davit. Same compute, far higher hit density.
#   * every false flag lands attached to a named model and class, so the residue is small enough to
#     review BY HAND rather than trusted blindly.
#
# The sweep itself runs on the GPU (gpu_product.ProductCracker, ~billions/s), so keeping each shard
# in the 1-4M band is about signal-to-noise, not about compute.
CLASS_WORDS = {
    "helicopter": ["rotor", "blade", "swash", "swashplate", "mast", "collective", "cyclic", "skid",
                   "tailrotor", "tailboom", "boom", "stabilizer", "pylon", "pitchlink", "scissor",
                   "droop", "spindle", "strut", "piston", "shaft", "hook", "winch", "sling"],
    "plane": ["wing", "flap", "aileron", "elevator", "rudder", "fin", "stabilizer", "slat", "spoiler",
              "airbrake", "canopy", "nose", "gear", "strut", "intake", "prop", "propeller", "spinner",
              "pylon", "tail", "tailplane", "rearwing", "leftwing", "rightwing", "speedbrake"],
    "tank": ["turret", "barrel", "mantlet", "recoil", "breech", "hatch", "track", "sprocket", "idler",
             "roadwheel", "torsion", "skirt", "cupola", "coax", "commander", "gunner", "driver",
             "loader", "smoke", "frontwheel", "rearwheel", "hull", "glacis"],
    "apc": ["turret", "hatch", "ramp", "periscope", "smoke", "track", "sprocket", "idler", "steering",
            "gunmount", "firingport", "trim", "vane"],
    "car": ["brake", "strut", "shock", "susp", "spring", "damper", "hood", "trunk", "bumper", "fender",
            "mirror", "steering", "headlight", "taillight", "wiper", "glass", "spoiler", "grille"],
    "truck": ["brake", "strut", "shock", "susp", "rod", "spring", "hood", "bed", "cab", "trailer",
              "hitch", "mirror", "steering", "tailgate", "fender", "bumper", "winch", "crane", "boom",
              "arm", "bucket", "plow", "outrigger", "jack"],
    "boat": ["hull", "keel", "bow", "stern", "deck", "mast", "rudder", "prop", "propeller", "shaft",
             "cleat", "rail", "ladder", "anchor", "winch", "cabin", "bridge", "ciws", "lifeboat",
             "davit", "funnel", "sam", "launcher", "hatch", "bilge", "gunwale"],
    "": ["wheel", "hub", "axle", "door", "hatch", "mount", "seat", "dock", "gun", "light", "cover",
         "panel", "glass", "attach", "pivot", "roll", "barrel", "turret"],
}

RIGGER_BASE = ["wheel", "hub", "axle", "brake", "strut", "shock", "susp", "rod", "spring", "damper",
               "door", "hatch", "flap", "rotor", "blade", "prop", "shaft", "piston", "turret",
               "barrel", "barreltip", "mount", "seat", "dock", "gun", "gunmount", "light", "antenna",
               "radar", "dish", "engine", "exhaust", "wing", "fin", "rudder", "elevator", "aileron",
               "gear", "track", "sprocket", "idler", "cover", "panel", "glass", "mirror", "ramp",
               "ladder", "winch", "hook", "cable", "steering", "attach", "pivot", "roll", "ruin"]

SHARD_SIDES = ["", "l", "r", "fl", "fr", "rl", "rr", "bl", "br", "ml", "mr", "left", "right"]
SHARD_NUMS = ["", "01", "02", "03", "04", "05", "06", "07", "a", "b", "c", "d", "1", "2", "3", "4"]
SHARD_MODS = ["", "front", "rear", "top", "bottom", "inner", "outer", "upper", "lower", "main",
              "attach", "mount", "cover", "ruin", "roll", "pivot"]


def _class_of(model_name):
    low = model_name.lower()
    for k in CLASS_WORDS:
        if k and ("_" + k + "_") in low:
            return k
    return ""


# -- DEEP mode: spend the GPU on DEPTH PER BONE, not width across bones ------------------------
#
# The card does ~1.0 BILLION candidates/sec (measured, RTX 2000 Ada). Our whole class-shard run was
# 72.8M candidates -- 0.07 seconds of GPU time. Compute was never the constraint, and sizing shards
# to "1-4M" was leaving four orders of magnitude on the table.
#
# The right way to spend it follows from the noise law, S*T/2^32:
#
#   noise scales with T. So drive T to 1 -- sweep ONE bone at a time -- and the SAME candidate count
#   costs T times less noise. At T=1, 43,000,000 candidates cost 43e6/2^32 = 0.01 expected false.
#
# Two things fall out, and the second is the important one:
#
#   1. DEPTH. Per bone we can afford ~10^7-10^8 candidates instead of the ~10^6 a shared shard could,
#      so the grammar can be far richer (more modifiers, more index schemes, longer compounds).
#
#   2. ★ A BIG VOCABULARY BECOMES SAFE AGAIN. The 20k-word sweep that produced 1,585 hits against
#      1,615 expected noise failed because it ran S=2.1e9 against T=3,305. The very same vocabulary
#      against ONE bone is S=43e6 x T=1 -> 0.01 noise. Per-bone targeting rehabilitates the thing
#      that killed us. We are no longer choosing between a broad vocabulary and a trustworthy result.
#
# The geometry pins the side for free (+x = LEFT, 99.8%), which also cuts the pool ~4x.
def _deep_vocab(neighbour_words, cls):
    v = set(RIGGER_BASE) | set(CLASS_WORDS.get(cls, [])) | set(CLASS_WORDS[""]) | set(neighbour_words)
    # every word the game's own asset names spell -- authored vocabulary, not a dictionary
    p = Path("docs/data/aset_names.csv")
    if p.exists():
        for r in csv.DictReader(open(p)):
            for t in re.split(r"[_\W]+", (r.get("name") or "").lower()):
                t = re.sub(r"\d+$", "", t)
                if 3 <= len(t) <= 12 and t.isalpha():
                    v.add(t)
    # The Saboteur is the same studio, same riggers: its vocabulary is our vocabulary. ("susp" came
    # from here and cracked bone_susp_rl/rr.)
    sp = Path("docs/data/saboteur_vocab.txt")
    if sp.exists():
        for w in sp.read_text().split():
            w = w.strip().lower()
            if 3 <= len(w) <= 12 and w.isalpha():
                v.add(w)
    return sorted(v)


def run_deep(args):
    """One bone at a time (T=1), a deep pool each. Noise per bone ~0.01; the GPU eats it in minutes."""
    from gpu_product import ProductCracker

    rb = json.loads(Path("tools/rainbow_table.json").read_text())["pandemic_hash_m2"]
    names = {int(k, 16): v[0] for k, v in rb.items()}
    models = {}
    for r in csv.DictReader(open("docs/data/bone_skeleton.csv")):
        models.setdefault(r["model"], []).append(r)

    # one entry per UNKNOWN bone: its class, its neighbours' words, and the side its geometry demands
    bones = {}
    for mh, nodes in models.items():
        mname = names.get(int(mh, 16), mh)
        cls = _class_of(mname)
        nb = set()
        for n in nodes:
            nm = names.get(int(n["hash"], 16), "")
            if nm.lower().startswith(("bone_", "hp_")):
                for t in nm.lower().split("_"):
                    t = re.sub(r"\d+$", "", t)
                    if len(t) >= 2 and t.isalpha() and t not in ("bone", "hp"):
                        nb.add(t)
        for n in nodes:
            h = int(n["hash"], 16)
            if h in names:
                continue
            x = float(n["wx"])
            b = bones.setdefault(h, {"cls": cls, "nb": set(), "models": set(), "x": x})
            b["nb"] |= nb
            b["models"].add(mname)
            if abs(x) > abs(b["x"]):
                b["x"] = x

    todo = sorted(bones.items(), key=lambda kv: -len(kv[1]["models"]))
    if args.limit_bones:
        todo = todo[: args.limit_bones]
    print("deep: %d unknown bones, T=1 each (GPU ~1.0 B/s measured)\n" % len(todo))

    MODS = ["", "front", "rear", "back", "top", "bottom", "inner", "outer", "upper", "lower", "main",
            "sub", "aux", "attach", "mount", "cover", "ruin", "roll", "pivot", "left", "right"]
    NUMS = ["", "01", "02", "03", "04", "05", "06", "07", "08", "a", "b", "c", "d", "e",
            "1", "2", "3", "4", "5", "00"]
    hits, tested, noise_tot = {}, 0, 0.0
    t0 = time.time()
    for i, (h, b) in enumerate(todo):
        # geometry pins the side -- free, and it quarters the pool
        if abs(b["x"]) < 0.05:
            sides = [""]
        elif b["x"] > 0:
            sides = ["", "l", "fl", "rl", "bl", "ml", "left"]
        else:
            sides = ["", "r", "fr", "rr", "br", "mr", "right"]
        words = _deep_vocab(b["nb"], b["cls"])
        slots = [["bone", "hp"], MODS, words, sides, NUMS]
        per = 1
        for s in slots:
            per *= len(s)
        raw = per * 2 ** (len(slots) - 1)
        tested += raw
        noise_tot += raw / 2 ** 32
        got = []
        pc = ProductCracker(0, {h})
        for bits in itertools.product((0, 1), repeat=len(slots) - 1):
            pc.sweep(slots, list(bits), lambda nm, hh, _g=got: _g.append(nm))
        if got:
            hits[h] = sorted(set(got))
        if i % 250 == 0 and i:
            el = time.time() - t0
            print("  %5d/%d  %.0f M cand  %.0fs  (%.2f B/s)  hits=%d"
                  % (i, len(todo), tested / 1e6, el, tested / el / 1e9, len(hits)))

    el = time.time() - t0
    print("\n  candidates tested : %s  in %.0fs  (%.2f B/s)" % (format(tested, ","), el, tested / max(el, .01) / 1e9))
    print("  expected false    : %.1f  (T=1 per bone -- this is the whole point)" % noise_tot)
    print("  HITS              : %d bones\n" % len(hits))
    out = Path("docs/data/bone_deep_review.csv")
    with open(out, "w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["hash", "candidates", "class", "models", "wx"])
        for h, ns in sorted(hits.items(), key=lambda kv: bones[kv[0]]["cls"]):
            b = bones[h]
            w.writerow(["0x%08X" % h, "|".join(ns), b["cls"], "|".join(sorted(b["models"])[:3]), "%.2f" % b["x"]])
            print("  0x%08X  %-38s [%s :: %s]"
                  % (h, ", ".join(ns)[:38], b["cls"] or "misc", sorted(b["models"])[0][:34]))
    print("\n-> %s" % out)
    return 0


def run_systematic(args):
    """Shard the unknowns by vehicle CLASS and sweep each shard on the GPU with a pool built for it.

    Nothing is discarded. Every hit -- including the ones that are probably chance preimages -- goes
    to the review CSV with the model and class it landed on. The engine resolves plenty of things by
    HASH rather than by name, so a verified preimage has value whether or not it is the artist's
    original spelling; and a small, attributed residue is something a human can actually adjudicate.
    """
    rb = json.loads(Path("tools/rainbow_table.json").read_text())["pandemic_hash_m2"]
    names = {int(k, 16): v[0] for k, v in rb.items()}
    models = {}
    for r in csv.DictReader(open("docs/data/bone_skeleton.csv")):
        models.setdefault(r["model"], []).append(r)

    # group the unknowns into class shards; carry each bone's models along for attribution
    shards = {}
    where = {}
    for mh, nodes in models.items():
        mname = names.get(int(mh, 16), mh)
        cls = _class_of(mname)
        for n in nodes:
            h = int(n["hash"], 16)
            if h in names:
                continue
            shards.setdefault(cls, {"targets": set(), "vocab": set()})["targets"].add(h)
            where.setdefault(h, set()).add(mname)
        # the class's own named bones = its local dialect, harvested free
        for n in nodes:
            nm = names.get(int(n["hash"], 16), "")
            if nm.lower().startswith(("bone_", "hp_")):
                for t in nm.lower().split("_"):
                    t = re.sub(r"\d+$", "", t)
                    if len(t) >= 2 and t.isalpha() and t not in ("bone", "hp"):
                        shards.setdefault(cls, {"targets": set(), "vocab": set()})["vocab"].add(t)

    # the non-vehicle bulk (buildings, walls, ramps) speaks the DESTRUCTION dialect, not the rigger
    # one. Sweeping it with wheel/rotor words was the old misc shard's 43-expected-false disaster.
    bld_pool = _building_pool()

    try:
        from gpu_product import ProductCracker
        gpu = True
    except Exception as e:  # noqa: BLE001
        print("GPU unavailable (%s) -- falling back to CPU" % e, file=sys.stderr)
        gpu = False

    all_hits = []
    tot_pool = tot_noise = 0
    print("systematic: %d class shards, sweeping on %s\n" % (len(shards), "GPU" if gpu else "CPU"))
    for cls, sh in sorted(shards.items(), key=lambda x: -len(x[1]["targets"])):
        tset = sh["targets"]
        words = sorted(set(CLASS_WORDS.get(cls, [])) | set(CLASS_WORDS[""]) | set(RIGGER_BASE) | sh["vocab"])
        slots = [["bone", "hp"], SHARD_MODS, words, SHARD_SIDES, SHARD_NUMS]
        npool = 1
        for s in slots:
            npool *= len(s)
        nsep = 2 ** (len(slots) - 1)
        raw = npool * nsep
        noise = raw * len(tset) / 2 ** 32
        tot_pool += raw
        tot_noise += noise
        hits = []

        def on_hit(name, h, _c=cls, _hits=hits):
            if 3 <= len(name) <= 40:
                _hits.append((h, name))

        if cls == "":
            # narrow grammar, ~10^5 candidates -- the CPU does it instantly and the noise is ~0.2
            raw = len(bld_pool)
            noise = raw * len(tset) / 2 ** 32
            tot_pool = tot_pool - (npool * nsep) + raw
            tot_noise = tot_noise - (npool * nsep * len(tset) / 2 ** 32) + noise
            for cand in bld_pool:
                h = m2(cand)
                if h in tset:
                    on_hit(cand, h)
        elif gpu:
            pc = ProductCracker(0, tset)
            for bits in itertools.product((0, 1), repeat=len(slots) - 1):
                pc.sweep(slots, list(bits), on_hit)
        else:
            for bits in itertools.product(("", "_"), repeat=len(slots) - 1):
                for combo in itertools.product(*slots):
                    nm = combo[0]
                    for sep, val in zip(bits, combo[1:]):
                        nm += sep + val
                    nm = re.sub(r"_{2,}", "_", nm).strip("_")
                    h = m2(nm)
                    if h in tset:
                        on_hit(nm, h)
        print("  %-11s targets=%-5d pool=%-12s expected-false=%5.2f   hits=%d"
              % (cls or "misc", len(tset), format(raw, ","), noise, len(hits)))
        for h, nm in hits:
            all_hits.append((cls, h, nm, sorted(where.get(h, ()))[:2], len(tset), noise))

    by_hash = {}
    for _, h, nm, _, _, _ in all_hits:
        by_hash.setdefault(h, set()).add(nm)
    print("\n  candidates tested : %s" % format(tot_pool, ","))
    print("  expected false    : %.1f  (sum of S*T/2^32 across shards)" % tot_noise)
    print("  HITS              : %d on %d distinct bones\n" % (len(all_hits), len(by_hash)))
    for cls, h, nm, mods, ntgt, noise in sorted(all_hits, key=lambda x: (x[0], x[2])):
        print("  0x%08X  %-34s [%s :: %s]" % (h, nm, cls or "misc", ", ".join(mods)[:52]))

    out = Path("docs/data/bone_forge_review.csv")
    with open(out, "w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["hash", "candidate", "class", "models", "shard_targets", "shard_noise"])
        for cls, h, nm, mods, ntgt, noise in sorted(all_hits, key=lambda x: (x[0], x[2])):
            w.writerow(["0x%08X" % h, nm, cls, "|".join(mods), ntgt, "%.3f" % noise])
    print("\nALL hits kept -- collisions included. The engine resolves plenty by HASH not name, so a")
    print("verified preimage has value regardless of the artist's spelling.  -> %s" % out)
    if args.dump and by_hash:
        frag = {"pandemic_hash_m2": {"0x%08X" % h: [sorted(v)[0]] for h, v in by_hash.items()}}
        Path(args.dump).write_text(json.dumps(frag, indent=1))
        print("-> %s" % args.dump)
    return 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--targets", choices=["rig", "all"], default="rig")
    ap.add_argument("--hashes", help="comma-separated 0x targets (overrides --targets)")
    ap.add_argument("--config", help="JSON with {arrays, templates} (overrides the EDIT ZONE)")
    ap.add_argument("--dump", help="write every hit (name -> hash -> slot) to this file")
    ap.add_argument("--show-samples", type=int, default=0, help="print N example candidates then exit")
    ap.add_argument("--limit", type=int, default=30_000_000,
                    help="max candidate expansions before requiring --force (guards against hangs, CPU only)")
    ap.add_argument("--force", action="store_true", help="run even past --limit (CPU)")
    ap.add_argument("--gpu", action="store_true",
                    help="hash on the GPU (~billions/s) via gpu_product -- no size guard needed")
    ap.add_argument("--jobs", type=int, default=8,
                    help="parallel shard workers (systematic mode)")
    ap.add_argument("--deep", action="store_true",
                    help="DEEP MODE: sweep ONE bone at a time (T=1) with a deep pool. Noise is S*T/2^32, "
                         "so at T=1 even a big vocabulary costs ~0.01 expected-false per bone -- this is "
                         "how GPU throughput converts into depth instead of noise.")
    ap.add_argument("--limit-bones", type=int, default=0, help="deep mode: only the N most-shared bones")
    ap.add_argument("--systematic", action="store_true",
                    help="SYSTEMATIC MODE: solve each unnamed bone as its OWN pool (T=1) with a few "
                         "thousand candidates drawn from its parent/siblings/model/geometry. Noise "
                         "scales as S*T, so many small pools cost far less noise than one big sweep.")
    ap.add_argument("--pairs", action="store_true",
                    help="PAIR MODE: target the unnamed mirror pairs the census reads off the rig "
                         "geometry (+x=left). A hit counts only if its side-swapped twin also hits "
                         "-- both hashes at once = a 64-bit proof, so the vocabulary can be huge.")
    ap.add_argument("--include-named", action="store_true",
                    help="with --targets all, ALSO target already-cracked bones: a hit that regenerates the "
                         "known name validates the vocab; a different string is a collision")
    args = ap.parse_args()

    if getattr(args, "deep", False):
        return run_deep(args)
    if getattr(args, "systematic", False):
        return run_systematic(args)

    arrays, slot_orders, templates = ARRAYS, SLOT_ORDERS, list(TEMPLATES)
    if args.config:
        cfg = json.loads(Path(args.config).read_text())
        arrays = cfg.get("arrays", arrays)
        slot_orders = cfg.get("slot_orders", slot_orders)
        templates = cfg.get("templates", templates)

    # auto-generate the underscore-enumerated templates from each slot order, then union with any manual
    # templates (dedup, order-preserving).
    auto = [t for order in slot_orders for t in auto_templates(order)]
    templates = list(dict.fromkeys(auto + templates))

    targets = load_targets(args)
    tset = set(targets)

    # CHEAP upfront size: product of array sizes per template (== raw expansions before dedup). This is
    # the work budget; the auto-enumeration multiplies each slot order by 2^(gaps) near-identical
    # value-products, so the number blows up fast with big `num`/`part`/`joint` arrays.
    def tsize(t: str) -> int:
        p = 1
        for nm in _MUSTACHE.findall(t):
            p *= len(arrays[nm])
        return p
    raw = sum(tsize(t) for t in templates)
    exp_false = raw * len(tset) / 2**32
    print(f"slot_orders={len(slot_orders)}  templates={len(templates)} ({len(auto)} auto)  "
          f"raw expansions<={raw:,}  targets={len(tset)}  expected-false<={exp_false:.3f}")
    if args.show_samples:
        shown = 0
        for t in templates:
            for name in expand(t, arrays):
                print("  ", name)
                shown += 1
                if shown >= args.show_samples:
                    return 0
        return 0
    if exp_false > 2:
        print(f"  ! high expected-false (<={exp_false:.1f}) -- a lone hit is likely noise; trust families/mirrors")

    # Collect hits; bounded memory (only hits are kept). CPU hashes on the fly. --gpu offloads the
    # cartesian-product hashing to the gpu_product kernel (~billions/s), so no size guard is needed there.
    hits: dict[int, list[str]] = {}
    seen_hit: set[tuple[int, str]] = set()

    def record(name: str, h: int) -> None:
        if 3 <= len(name) <= 40 and h in tset and (h, name) not in seen_hit:
            seen_hit.add((h, name))
            hits.setdefault(h, []).append(name)

    use_gpu = args.gpu
    if use_gpu:
        try:
            from gpu_product import ProductCracker
        except Exception as e:  # noqa: BLE001
            print(f"  GPU unavailable ({e}); falling back to CPU", file=sys.stderr)
            use_gpu = False

    if use_gpu:
        pc = ProductCracker(0, tset)
        for order in slot_orders:
            slot_tokens = [arrays[k] for k in order]
            for bits in itertools.product((0, 1), repeat=max(0, len(order) - 1)):
                pc.sweep(slot_tokens, list(bits), record)
        # any manual (non-slot-order) templates run on CPU -- they are few/small by design
        auto_set = set(auto)
        for t in templates:
            if t not in auto_set:
                for name in expand(t, arrays):
                    record(name, m2(name))
    else:
        if raw > args.limit and not args.force:
            print(f"  ! {raw:,} expansions exceeds the {args.limit:,} guard (~minutes, heavy). Trim the arrays "
                  f"(num/part/joint are the big multipliers), pass --force, or use --gpu.")
            return 1
        for t in templates:
            for name in expand(t, arrays):
                record(name, m2(name))

    total_hits = sum(len(v) for v in hits.values())
    regen = collide = 0
    print(f"\n{total_hits} hit(s) on {len(hits)} target(s):")
    for h in sorted(hits):
        label = targets.get(h, "")
        known = label[6:] if label.startswith("known=") else None
        for name in sorted(hits[h]):
            tag = ""
            if known is not None:
                if name.lower() == known.lower():
                    tag = "  <- REGENERATED (vocab confirmed)"
                    regen += 1
                else:
                    tag = f"  <- collision (known={known})"
                    collide += 1
            print(f"  0x{h:08X}  {name:<28} [{label}]{tag}")
    if getattr(args, "include_named", False):
        named_targets = sum(1 for v in targets.values() if v.startswith("known="))
        print(f"\ncoverage: {regen} known bone(s) regenerated by the current vocab "
              f"(of {named_targets} named targeted); {collide} collision(s) on named bones.")

    # ── mirror corroboration -- the strongest signal a run can produce ──────────────────────
    if getattr(args, "pairs", False):
        # PAIR MODE: a hit only counts if its side-swapped spelling hashes onto the twin the
        # GEOMETRY nominated. Two hashes must fall at once -- 64 bits. Collisions do not survive it.
        pr = load_geom_pairs()
        confirmed: dict[int, str] = {}
        for h, names in hits.items():
            for name in names:
                for sw in swap_side(name):
                    th = m2(sw)
                    if th in pr.get(h, ()):
                        confirmed[h] = name
                        confirmed[th] = sw
        singles = sum(len(v) for h, v in hits.items() if h not in confirmed)
        # The TRUE error bar. The twin hash is NOT independent (see the note above), so pairing does
        # not square the odds -- the noise pool is the ordinary 32-bit one, and a slice of it will
        # pair by form alone. Report that honestly rather than a flattering 2^-64.
        noise = raw * len(tset) / 2**32
        print(f"\npair-solve: {len(confirmed)} bone(s) = {len(confirmed)//2} pair(s) whose twin also fell")
        print(f"            expected 32-bit noise hits in this run: {noise:.0f}  <- the twin hash is")
        print(f"            NOT independent evidence; a slice of that noise WILL pair by form alone.")
        print(f"            Judge each on its STEM and the MODEL it sits on, not on having paired.")
        for h, n in sorted(confirmed.items(), key=lambda x: x[1]):
            print(f"  0x{h:08X}  {n}")
        if singles:
            print(f"\n  {singles} lone 32-bit hit(s) whose twin did NOT fall -- these are NOISE, not names.")
        if args.dump and confirmed:
            frag = {"pandemic_hash_m2": {f"0x{h:08X}": [n] for h, n in confirmed.items()}}
            Path(args.dump).write_text(json.dumps(frag, indent=1))
            print(f"\nwrote CONFIRMED pairs -> {args.dump}")
            return 0
    else:
        print("\nmirror-pair check:")
        reported = set()
        found_pair = False
        for h in hits:
            if h not in SLOTS or h in reported:
                continue
            _, mate = SLOTS[h]
            if mate is None:
                continue
            reported.add(h)
            reported.add(mate)
            if mate in hits:
                found_pair = True
                print(f"  *** PAIR *** 0x{h:08X}={hits[h]}  <->  0x{mate:08X}={hits[mate]}  "
                      f"<- STRONG: both sides of a mirror hit in one run")
            else:
                print(f"  0x{h:08X}={hits[h]} hit but its mirror 0x{mate:08X} did NOT -- add the "
                      f"opposite-side spelling to corroborate")
        if not found_pair and not reported:
            print("  (no hit landed on a mirror slot)")

    if args.dump and hits:
        with open(args.dump, "w", encoding="utf-8") as fh:
            for h in sorted(hits):
                for name in sorted(hits[h]):
                    fh.write(f"{name}\t0x{h:08X}\t{targets.get(h,'')}\n")
        print(f"\nwrote hits -> {args.dump}")
    if not hits:
        print("  (no candidate hit any target -- extend ARRAYS / TEMPLATES and rerun)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
