# The character deform-rig naming dialect (Mercenaries 2)

**Scope:** the naming convention of the shared **biped deform rig** — the bones a hash table stores as
`pandemic_hash_m2(name)` and that Mercs2's shipped PC data never spells out. This is an *artifact of
patterns and vocabulary*, not a claim of cracks. Every recovered name still needs a second witness
(family, mirror, on-model, or external string); a bare 32-bit hash match is not evidence.

**Companion runnable config:** [`tools/bone_forge_deform_rig.json`](../../tools/bone_forge_deform_rig.json)
encodes the grammar below for `bone_forge.py`.

**Read alongside:** [`bone_census.md`](bone_census.md) (the whole investigation; the "16→15 unnamed rig
bones" section and why blind brute force is exhausted), [`../data/human_rig_reference_105.txt`] (the rig in
track order), [`../data/named_bones.csv`] (all 208 confirmed names).

---

## 0. TL;DR for the next person

* The dialect is **terse CamelCase** with **glued handedness** and three coexisting side-conventions
  chosen by *bone class* (§1). Getting the class right matters more than the vocabulary.
* The 6 headline unknowns are, structurally, near-certain: the two mirror pairs are `bone_l<X>` /
  `bone_r<X>` **glued-prefix body bones**; the three singles are torso/spine/accessory `bone_<X>`. The
  unknown is only the stem `<X>`.
* **Everything obvious is already ruled out.** This session hashed **~11,000 structured, high-plausibility
  candidates** (anatomical + rig-helper + twist/roll + `Bone`-infix + terse-code, across every side
  convention we witness) directly against the 6 target hashes. **Zero hits.** A miss is a *definitive
  exclusion* (not probabilistic), so §4 lists what each slot is provably **NOT**.
* The surviving hypothesis space is therefore **studio-internal / non-dictionary tokens** (the rig already
  proves the studio does this: `bone_ub`, `bone_lb`), **compounds/spellings longer or odder than a
  dictionary generates**, or names only an **unstripped dev build** will reveal. Do not expect a wider
  blind sweep to recognize them — recognition, not coverage, is the wall (see `bone_census.md` §4c).

---

## 1. Structural grammar (confirmed)

### 1.1 The token layout

```
  bone_ <side?> <part> <infix?> <num?>            body / limb / accessory
  bone_ <part> <side-word?>                       torso halves + face
  bone_attach_ <part> <side-glued?>               attach points
  hp_ <name>                                      hardpoints (separate dialect, not covered here)
  GlobalSRT                                        the transform root — the ONE bone with no bone_/hp_ prefix
```

* **Prefix.** Deform + attach + accessory bones are `bone_` (lowercase in every witness, but the hash
  folds case so casing is *evidentially void* — do not read meaning into `Bone_LBicep` vs `bone_lbicep`).
  The sole exception is `GlobalSRT`. Hardpoints are `hp_` and form their own dialect.
* **Underscore is literal and load-bearing.** `bone_` always carries its trailing underscore into the
  hashed string (`bone_root`, not `boneroot`). Inside a compound stem the underscore may or may not
  appear — this is per-convention, see §1.2.

### 1.2 Handedness — THREE conventions, selected by bone class

This is the single most important structural fact. The game does **not** use one side convention; it uses
three, and which one applies is decided by what kind of bone it is:

| Convention | Form | Bone class | Confirmed examples |
|---|---|---|---|
| **A. Glued prefix** `l`/`r` | `bone_l<part>` | **body limb / deform bones** | `bone_lbicep`,`bone_rforearm`,`bone_lshoulder`,`bone_lthigh`,`bone_lshin`,`bone_lhand`,`bone_lindex1`,`bone_lforearmroll` |
| **B. Glued suffix** `left`/`right` | `bone_<part>left` | **torso halves + attach** | `bone_chestleft`,`bone_chestright`,`bone_attach_backleft`,`bone_attach_hipleft`,`bone_attach_hipright` |
| **C. Separated suffix** `_left`/`_right` | `bone_<part>_left` | **face (FaceFX)** | `bone_cheek_left`,`bone_nose_right`,`bone_eyeball_left`,`bone_mouth_corner_right`,`bone_eyelid_top_left` |

**Consequence for the mirror-pair targets (trk3/10 legs, trk54/76 arms):** these are unambiguously body
limb bones, so they are **Convention A** — `bone_l<X>` / `bone_r<X>`, glued, no separator, one shared stem
`<X>`. That is a strong prior and it drives the attack in §4.

### 1.3 The `Bone` infix (rare but real)

`Bone_LFootBone1`, `Bone_LFootBone2`, `Bone_RFootBone1`, `Bone_RFootBone2` decompose as
`bone_` + `l` + `foot` + **`bone`** + `1`. So a *numbered sub-chain of a named part* can carry a literal
`bone` **infix** before the number: `bone_<side><part>bone<num>`. Foot: `FootBone1` = ball,
`FootBone2` = toe. This is the only witnessed use, but it is a real pattern to try on any numbered
limb-tip (see §4 leg/arm families — e.g. `bone_llegbone1`).

### 1.4 Numbering suffixes

* **Bare digit, glued:** `bone_spine1`, `bone_spine2`, `bone_head1..4`, `bone_hair1/2`, finger `…1/2/3`,
  `FootBone1/2`. No zero-pad, no separator.
* **Letter, glued:** `bone_backa/b/c`, `bone_fronta/b/c`, `bone_flaga..e`.
* **Letter, separated:** `bone_radar_a/b/c`, `bone_antenna_a/b/c`.
* **Zero-padded digit, separated:** `bone_wheel_l_01..06` (vehicle). Also glued `bone_wheel_l02`.
* **Grid + letter:** `bone_massive_1x1_a`, `bone_massive_2x1_f` (destruction chunks).

So the numbering slot is *not* uniform — digit-vs-letter and glued-vs-separated both vary by family.

### 1.5 Terse studio abbreviations (the tell)

The rig contains bones no dictionary would guess because they are **studio shorthand**:
`bone_ub` (upper body), `bone_lb` (lower body), plus single-purpose props `bone_crest`, `bone_chute`,
`bone_flap`, `bone_wires`, `bone_chain`, `bone_cigar`, `bone_necklace`. `bone_ub`/`bone_lb` were only
recoverable because `_ub`/`_lb` is a *documented Mercs2 character suffix* (sibling of `_head`/`_hair`) — the
hash alone would have been unrecognizable. **This is the shape of the remaining unknowns.**

### 1.6 Worked examples

```
bone_lforearmroll   = bone_ | l(A:glued prefix) | forearm | roll(twist infix)     -> confirmed 0x03719EEF
Bone_LFootBone1     = bone_ | l(A) | foot | bone(§1.3 infix) | 1                    -> confirmed 0x1226F58D
bone_attach_hipleft = bone_attach_ | hip | left(B:glued suffix)                     -> confirmed 0x629B2990
bone_cheek_left     = bone_ | cheek | _left(C:separated suffix)                     -> confirmed 0x30103344
bone_ub             = bone_ | ub(terse studio code, §1.5)                            -> confirmed 0xDB0322B7
```

---

## 2. Vocabulary by slot — emphasizing what is MISSING from current coverage

Below, **(seen)** = a stem already witnessed in a confirmed name; **(missing)** = a plausible 2008
military-character-rig token we have *not* yet seen named and that a faithful rig probably contains.
Everything in the "missing" columns that is a plain dictionary word has been **tested and excluded** for
the 6 headline targets (§0/§4) — it is listed because it may name *other* unnamed rig/vehicle bones and
belongs in a widening `bone_forge` run, not because it is expected to hit the headline six.

### 2.1 `side` slot
* Glued prefix (A): `l`, `r` (seen).
* Glued suffix (B): `left`, `right` (seen).
* Separated suffix (C): `_left`, `_right` (seen).
* Short codes seen elsewhere (hardpoints/wheels): `lt`, `rt`, `fl`, `fr`, `rl`, `rr`, `ml`, `mr`.

### 2.2 `part` — spine / torso
* seen: `spine`(1,2), `chest`, `chestleft/right`, `back`(a/b/c), `front`(a/b/c), `ub`, `lb`.
* **missing (faithful rig would likely have):** `spine3`/`spine4`, `ribcage`, `ribs`, `sternum`, `thorax`,
  `torso`, `trunk`, `pelvis`, `pec`/`pectoral`, `abdomen`, `waist`, `upperbody`/`lowerbody` (long forms of
  ub/lb), `neckbase`, `nape`, `yoke`, `collar`, `clavicle`.

### 2.3 `part` — shoulder / arm (the trk54/76 slot)
* seen: `shoulder`, `bicep`, `forearm`, `forearmroll`, `hand`.
* **missing:** `deltoid`/`delt`, `upperarm`/`uparm`, `clavicle`/`clav`, `collarbone`, `scapula`,
  `trapezius`/`trap`, `tricep`, `rotator`, `shoulderpad`, and the **twist/roll family absent proximally**:
  `upperarmtwist`, `upperarmroll`, `shoulderroll`, `shouldertwist`, `biceproll`, `armtwist`. We *have*
  `forearmroll` (distal), so the missing **proximal twist bone** is exactly the anatomical role of
  trk54/76 — but note every one of these was tested and **missed** (§4).

### 2.4 `part` — hip / leg (the trk3/10 slot)
* seen: `thigh`, `shin`, `foot`(bone1/2), `hip`(attach only).
* **missing:** `pelvis`, `upperleg`/`upleg`, `glute`/`gluteus`, `quad`, `hamstring`/`ham`, `femur`,
  `groin`, `legroot`, `thighroot`, and twist forms `thightwist`/`thighroll`/`hiptwist`/`legtwist`. Again
  all tested and missed for trk3/10.

### 2.5 `part` — accessory / prop / cloth (the trk104 slot)
* seen: `hair`(1,2), `necklace`, `cigar`, `crest`, `chute`, `flap`, `tail`, `wires`, `chain`, `chair`,
  `camera`, `ak47`, `pistol`, `rifle`, `grenade`, `head1`.
* **missing (military-mercenary character kit):** `hair3+`, `ponytail`, `braid`, `bang(s)`, `cap`, `hat`,
  `beret`, `helmet`, `visor`, `goggles`, `sunglasses`, `mask`, `bandana`, `headband`, `scarf`, `cape`,
  `cloak`, `coat`, `hood`, `strap`(s), `belt`, `bandolier`, `backpack`/`pack`, `radio`, `antenna`,
  `dogtag`(s), `holster`, `sheath`, `knife`, `pouch`, `ammo`, `magazine`, `vest`, `patch`, `badge`,
  `earpiece`, `headset`, `mic`, `epaulet`, `shoulderpad`.

### 2.6 `twist` / helper infix (control-bone vocabulary — likely under-covered)
* seen: `roll` (`forearmroll`), `yaw`/`pitch`/`roll`/`rotate` (vehicle axes).
* **missing:** `twist`, `bend`, `swing`, `flex`, and the rig-helper suffixes a DCC pipeline emits:
  `null`, `helper`, `drv`/`driver`, `ctrl`/`control`, `aim`, `lookat`, `ik`, `fk`, `tgt`/`target`, `nub`,
  `dummy`, `pivot`, `offset`, `root`, `base`, `tip`, `end`, `mid`. **Try these as an INFIX with the glued
  side prefix** (`bone_l<part><suffix>`) — the `forearmroll` precedent proves that shape.

### 2.7 `num` slot
* seen digits `1 2 3 4`, zero-pad `01..06`, letters `a..f`, grids `NxN`. (§1.4 for the glued/separated rule.)

---

## 3. `bone_forge`-ready config

Full runnable file: **[`tools/bone_forge_deform_rig.json`](../../tools/bone_forge_deform_rig.json)**. Run:

```bash
python tools/bone_forge.py --config tools/bone_forge_deform_rig.json --gpu           # the 15 unnamed rig bones
python tools/bone_forge.py --config tools/bone_forge_deform_rig.json --targets all --gpu   # widen to all 976 unnamed
```

Inline summary of the encoded grammar (the JSON is authoritative):

```jsonc
{
  "arrays": {
    "prefix":     ["bone","joint","jnt","eff","helper","dummy","hp"],
    "side":       ["l","r"],            // Convention A, glued prefix -> mirror pairs
    "side_word":  ["left","right"],     // Convention B/C, suffix
    "part":       [ /* §2.2-2.5 stems: spine/torso, shoulder/arm, hip/leg, accessory */ ],
    "twist":      ["","roll","twist","bend","swing","flex"],
    "helperkind": ["","bone","null","helper","drv","driver","ctrl","control","aim","ik","fk",
                   "tgt","nub","root","base","tip","end","mid","up","upper","lower"],
    "num":        ["","1","2","3","4","01","02","03","0","a","b","c","d","e"]
  },
  "slot_orders": [
    ["prefix","side","part","twist","num"],      // bone_l + bicep + roll        (glued-prefix body)
    ["prefix","side","part","helperkind","num"], // bone_l + leg + bone + 1      (§1.3 Bone infix)
    ["prefix","part","side_word","num"],         // bone_chest + left            (glued-suffix torso)
    ["prefix","part","twist","side_word"],
    ["prefix","part","num"],                     // bone_spine + 3 ; bone_hair + 3
    ["prefix","part","helperkind","num"]
  ],
  "templates": [
    "bone_{{side}}{{part}}bone{{num}}",          // explicit §1.3 FootBone form
    "bone_{{part}}{{side_word}}"                 // explicit chestleft form
  ]
}
```

> `bone_forge`'s auto-enumerator expands every underscore-present/absent pattern between slots, so both
> glued and `_`-separated spellings of each order are covered automatically. Watch the printed
> **expected-false** number — with the full `part` list this is a large run; trust only family/mirror
> corroboration, never a lone hit.

---

## 4. The 6 headline targets — candidate families (HYPOTHESES, unverified)

Positions from `human_rig_reference_105.txt`. For each: the **structural certainty** (high — from §1),
the **best-reasoned name families** (LOW confidence — these are domain guesses), and the **proven
exclusions** from this session's direct-hash test (each is a hard NOT, not a probability).

### trk3 `0x491E8967` (LEFT) ↔ trk10 `0xE6FF1D72` (RIGHT) — leg-chain head, under `bone_hips`, before `bone_lthigh`
* **Structure (high confidence):** Convention A mirror pair → `bone_l<X>` / `bone_r<X>`, shared stem.
  Anatomically a **pelvis / hip-split / upper-leg-root / thigh-twist** bone.
* **Candidate families (HYPOTHESIS):** `bone_l{pelvis|hip|hipbone|upperleg|upleg|legroot|thighroot|
  thighbase|glute|quad}`; `Bone`-infix `bone_l{leg|hip|thigh}bone{1}`; twist `bone_l{thigh|hip|leg}
  {roll|twist}` (though a twist usually sits *after* its parent, and this bone sits *before* the thigh, so
  a **pelvis/hip-root** reading is favored over a twist).
* **PROVEN EXCLUDED (both sides):** every stem in a **4,868-stem** anatomical+helper cross-product (pelvis,
  hip, upperleg, glute, quad, femur, thighroot, legroot, …× roll/twist/bone/null/helper/num) — plus the
  glued-suffix (`bone_<x>left`) and separated (`_left`) conventions. **None hit.**

### trk17 `0xFAADBFFF` — between `bone_spine2` and `bone_chest`
* **Structure (high confidence):** single `bone_<X>` torso bone. Anatomically the **third spine
  segment / lower ribcage**.
* **Candidate families (HYPOTHESIS):** `bone_spine3`, `bone_ribcage`, `bone_sternum`, `bone_thorax`,
  `bone_upperspine`, `bone_chest2`/`upperchest`, `bone_spineb` (letter-suffix like `backb`).
* **PROVEN EXCLUDED:** `bone_spine3` (and `spine03`,`spine_3`,`spine2a`,`spine2b`,`spine4`,`spineb`,
  `spine{top,up,upper,mid,bone}`), `bone_ribcage`/`ribs`/`rib`, `bone_sternum`, `bone_thorax`,
  `bone_{upper,mid}spine`, `bone_chest{0,1,2,3,b,upper,bone,base}`, `bone_torso*`, `bone_back{d,bone,top}`.
  → **The third spine bone is NOT named `spine3` or any obvious ribcage/torso word.** Strongest surviving
  guess: a terse code (`bone_sp3`? tested-miss) or a studio-idiosyncratic segment name.

### trk22 `0x11815D82` — after `bone_attach_backleft/right`, before `bone_neck`
* **Structure (high confidence):** single `bone_<X>`. Anatomically **upper-back / neck-base / clavicle-root
  / 4th spine** (the bone the neck plants into).
* **Candidate families (HYPOTHESIS):** `bone_neckbase`, `bone_spine4`/`spine5`, `bone_upperchest`,
  `bone_clavicle`/`collar`/`collarbone`, `bone_shoulderbase`, `bone_trapezius`/`traps`, `bone_yoke`,
  `bone_nape`, terse `bone_nb`/`bone_ub2`.
* **PROVEN EXCLUDED:** `neckbase`,`neck{0,1,2,b,bone,low,lower,top,bottom,root}`,`spine{4,5,top}`,
  `upperchest`/`chestupper`,`clavicle`,`collar`(bone),`shoulder{base,root,pad}`,`trapezius`/`traps`/`trap`,
  `yoke`,`nape`,`scapula`,`sternum`,`c7`,`upperback`/`backupper`,`upperbody`,`ub{2,b,1}`,`nb`,`cb`,`sb`.

### trk54 `0x87E8C062` (LEFT) ↔ trk76 `0x7D2C9CA4` (RIGHT) — between `bone_?shoulder` and `Bone_?Bicep`
* **Structure (high confidence):** Convention A mirror pair → `bone_l<X>` / `bone_r<X>`. With
  `bone_lshoulder` reading as the **clavicle** and `Bone_LBicep` as the **upper arm**, this middle bone is
  the classic **deltoid / shoulder-pad / upper-arm-twist / clavicle-end** slot.
* **Candidate families (HYPOTHESIS):** `bone_l{deltoid|delt|upperarm|uparm|shoulderpad|clavicle|clav|
  collar|scapula}`; twist `bone_l{shoulder|upperarm|arm|bicep}{roll|twist}` (the proximal analog of
  `forearmroll`); `Bone`-infix `bone_l{arm|shoulder}bone{1}`.
* **PROVEN EXCLUDED (both sides):** the same 4,868-stem cross-product as trk3/10 but arm-weighted (deltoid,
  delt, upperarm, uparm, clavicle, clav, collar, scapula, trap, tricep, rotator, pec × roll/twist/bone/
  null/helper/num) + glued-suffix + separated conventions. **None hit.**

### trk104 `0x9EC352CF` — accessory tail, right after `bone_hair` (beside `bone_necklace`, `bone_lb`, `bone_head1`)
* **Structure (high confidence):** single `bone_<X>` accessory/prop bone, in the appended non-skeletal
  tail (union of per-character kit bones).
* **Candidate families (HYPOTHESIS):** more hair (`bone_hair3`/`hairb`/`hairtip`/`ponytail`/`braid`), or a
  worn-kit prop (`bone_cap`/`hat`/`beret`/`goggles`/`mask`/`scarf`/`strap`/`dogtag`/`holster`/`radio`/
  `antenna`/`pouch`), or a terse code (`bone_h3`, `bone_acc`).
* **PROVEN EXCLUDED:** `hair{3,4,5,b,c,d,end,tip,bone,_3}`, `ponytail`/`pony`/`braid`/`bang(s)`/`fringe`,
  `cap`/`hat`/`beret`/`helmet`/`visor`/`goggles`/`mask`/`scarf`/`bandana`/`headband`/`cape`/`cloak`/`coat`/
  `hood`, `strap(s)`/`belt`/`backpack`/`pack`/`radio`/`antenna(a)`/`dogtag(s)`/`holster`/`sheath`/`knife`/
  `pouch`/`ammo`/`bandolier`/`vest`/`patch`/`badge`/`glasses`/`earpiece`/`headset`/`mic`, `prop`/`acc`/
  `extra`/`misc`/`null`/`helper`, `bone_tail` (that hash is a *different*, already-named bone).

---

## 5. Honesty ledger — what is confirmed vs reasoned

| Claim | Basis |
|---|---|
| §1 grammar (3 side conventions by class, `bone_` prefix, `Bone` infix, numbering rules, terse codes) | **Confirmed** — read directly off 208 witnessed names in `named_bones.csv` + the reference clip. |
| The 6 targets' **structure** (mirror pairs = glued `bone_l/r` body bones; singles = `bone_<X>`) | **High confidence** — forced by §1.2 class rules + reference-clip position. Not a hash claim. |
| The specific candidate **stems** in §4 | **Low confidence, domain reasoning only.** Genre/era priors, not evidence. |
| The **exclusions** in §0/§4 (~11,000 candidates) | **Confirmed negatives.** `pandemic_hash_m2` is deterministic; a miss is a *proof* the target is not that string. Scripts: scratchpad `probe.py` / `mirror.py` / `mirror2.py` / `probe3.py`. |
| "The names are studio-internal / longer / dev-build-only" | **Inference**, consistent with `bone_census.md` §4c's exhaustive-sweep result: coverage is solved, recognition is the wall. |

**Bottom line:** the dialect is fully characterized and the search is correctly *shaped* (right prefix,
right side convention, right slot order for every target). What defeats us is vocabulary: the studio named
these six with tokens outside every dictionary we can assemble — exactly as it did with `ub`/`lb`. The
realistic route to the actual strings is an **unstripped dev/debug build or symbol dump**, not more
hashing. This artifact exists so that when such a source appears, matching it against these six is a
lookup, not a re-derivation — and so any future `bone_forge` run starts from the correct grammar instead of
re-testing the ~11,000 candidates already excluded here.
