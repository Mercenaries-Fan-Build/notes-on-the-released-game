# The CHARACTER naming dialect — deform rig + FaceFX (Mercenaries 2)

**Scope.** The humanoid **deform rig** and the **FaceFX** facial rig. Companion to
[`naming_dialect_deform_rig.md`](naming_dialect_deform_rig.md) and
[`naming_dialect_facefx.md`](naming_dialect_facefx.md) — this document does **not** re-derive their
grammars. It reports (a) what was **mined** from the sibling game and other unstripped sources,
(b) three **new structural laws** of `pandemic_hash_m2` that turn guessing into proving, and
(c) the resulting **hard exclusions** — several of which overturn assumptions the two earlier docs
were built on.

Companion pools: [`tools/bone_forge_character.json`](../../tools/bone_forge_character.json).

**Headline: no new bone name was cracked.** What *was* achieved is stronger than another null: the
search space for the mirror pairs is now bounded by *proof* rather than by exhaustion, and one of the
three pairs is proven to have been attacked with the **wrong grammar** for its entire history.

---

## 0. TL;DR

| | |
|---|---|
| **Mined** (literal strings, zero guessing) | Saboteur's complete `FxMasterBoneList` (36 facial bones, from `FaceFX/Male.fxa` + `Female.fxa`), 27 body-rig bone literals from its decomp, `Bone_bone1`, `Bone_HeadBase`, `GlobalSRT` |
| **Verified hits from mining** | **0.** 79 literals × 8,561 unnamed hashes, expected-false 0.00016 → nothing. Saboteur's face rig **does not transfer**. |
| **New laws proven** | the **parity law** (§2), the **prefix-agnostic mirror sieve** (§3), the **length gate** (§3.3) |
| **New hard exclusions** | trk3/trk10 is **not** a glued `l`/`r` pair *at all* (§2.2); trk54/76 and trk28/31 have **no** glued-`l`/`r` stem ≤ 6 chars **for any prefix whatsoever** (§3.2) |
| **Assumption overturned** | the census says these bones are **not** anim-only — all 15 sit in 3–6 real model `HIER`s (§4) |
| **Confidence that more hashing will crack these** | **Low.** §6 is honest about why. |

---

## 1. What was MINED (sources, verbatim — no inference)

### 1.1 The Saboteur is the same rig, and it says so in plain text

`output/_ghidra_saboteur/saboteur_all_functions_decomp.txt` contains a find-bone-by-name helper,
`FUN_00db7e10(const char*, int)`. Enumerating **every** string it is called with yields Mercs2's body
dialect *verbatim* — same words, same glued handedness, same `Bone` infix, same attach points:

```
Bone_Root  Bone_Hips(—)  Bone_Spine1  Bone_Chest  Bone_Neck  Bone_Head
Bone_LThigh Bone_LShin  Bone_LFootBone1  Bone_LFootBone2   (+ R*)
Bone_LShoulder Bone_LBicep Bone_LForearm Bone_LHand        (+ R*)
Bone_Attach_LHand  Bone_Attach_RHand
GlobalSRT          <- m2 = 0xCBC1EB51, identical to Mercs2 track 0
Bone_HeadBase  Bone_LowerLip_Left  Bone_bone1  DefaultBone
```

This is the strongest possible corroboration that **Pandemic shipped one body-rig dialect across both
games**. It is also why the deform-rig doc's grammar can be trusted.

**`Bone_bone1` is the find of the session.** It is a **DCC default auto-name** ("bone1") that a rigger
never renamed, carried into the shipped rig behind the studio's `Bone_` prefix. It is *proof* that
Pandemic rigs contain tokens no dictionary and no anatomy list will ever generate — exactly the shape
the deform-rig doc predicted for `bone_ub`/`bone_lb`. (It does not hash-match anything of ours; see
§1.3. Its value is that it tells you what kind of thing you are hunting.)

### 1.2 The complete Pandemic FaceFX rig (`FxMasterBoneList`)

`/c/GOG Games/The Saboteur/FaceFX/{Male,Female}.fxa` — 36 bones, extracted verbatim:

```
Bone_Head  Bone_HeadBase  Bone_JawBone  Bone_MouthBase  Bone_Neck
Bone_Brow_Left/Right     Bone_OutBrow_Left/Right
Bone_Eye_Left/Right      Bone_EyeBlink_Left/Right   Bone_LowLid_Left/Right
Bone_UnderEye_Left/Right
Bone_Cheek_Left/Right    Bone_LowerCheek_Left/Right
Bone_UpperLip_Left/Right Bone_LowerLip_Left/Right
Bone_InnerUpperLip_Left/Right  Bone_InnerLowLip_Left/Right
Bone_OuterUpperLip_Left/Right  Bone_LipCorner_Left/Right
Bone_Sneer  Bone_Teeth_Top  Bone_Teeth_Bottom  Bone_Tongue_Mid
```

Plus the FaceFX **curve** layer (`jawOpen`, `jawSideLeft`, `lowerLipCurlIn`, `wideEyeLeft`,
`expBrowAngry`, `Gaze Eye Pitch`, `head_RX+` …) — this is stock OC3 FaceFX naming and confirms the
middleware identification, but curves are **not** bones and never enter a `HIER`.

### 1.3 Hashing the mined literals — the honest result

All 79 mined literals (verbatim, plus case variants — irrelevant, the hash folds case) tested against
**all 8,561 unnamed census hashes**:

| pool | S | T | expected-false | hits |
|---|---:|---:|---:|---:|
| Mined literals, verbatim | 79 | 8,561 | 0.00016 | **0** |
| Mined literals vs the 15 rig slots | 79 | 15 | 0.0000003 | **0** |
| Saboteur face *concepts* re-spelled in the Mercs2 facefx grammar | 42,442 | 8,561 | 0.085 | **0** |

**Conclusion (confirmed, not inferred): the two games share the BODY rig dialect exactly and share
NOTHING of the FACE rig dialect.** Mercs2 spells its face in snake_case with trailing full-word sides
(`bone_mouth_corner_left`); Saboteur spells its face in CamelCase with a different vocabulary
(`Bone_LipCorner_Left`). Different rigger, different file. The sibling game supplies a *concept
checklist* and can **never** supply a literal Mercs2 face-bone string. This closes the lead that the
facefx doc left open — it is now a settled negative, not an untried avenue.

### 1.4 Other sources mined (all null)

* `game-files/xbox-vz.unique-strings.txt`, `ps3-VZ.unique-strings.txt`, `output/block_strings.txt` —
  29 distinct `bone_*` literals, all already named.
* **The Jul-11-2008 devkit prototype** (`output/jul08_prototype/`, `output/jul08_wad/`) — the "unstripped
  dev build" the earlier docs said we would need. It ships **25** `bone_*` literals, **every one of them
  already known**. The devkit build does *not* contain the missing names. This is important: it removes
  the standing hope that the prototype would simply hand us the answer.
* `docs/mercs2-luacd/` — no bone-name literals beyond attach points already in the rainbow table.

---

## 2. NEW LAW #1 — the parity law (and the assumption it kills)

`pandemic_hash_m2` is FNV-1a with a `| 0x20` case fold. Multiplication by the FNV prime is odd, so it
**preserves bit 0**, and XOR feeds bit 0 straight through. Therefore:

> **bit 0 of `m2(name)` = bit0(FNV_OFFSET) XOR (parity of the count of ODD bytes in the name, after `|0x20`).**

### 2.1 The consequence for mirror pairs

`l` = 0x6C and `r` = 0x72 are **both even**. Swapping one for the other changes the odd-byte count by
zero. Hence:

> **Any glued `l`/`r` mirror pair MUST have hashes that agree in bit 0.**

Verified against **every** known `l`/`r` pair in the 105-bone rig — `lthigh/rthigh`, `lshin/rshin`,
`lfootbone1/rfootbone1`, `lbicep/rbicep`, `lforearm(roll)/rforearm(roll)`, `lhand/rhand`,
`lshoulder/rshoulder`, `lthumb1/rthumb1`, `lpinky3/rpinky3`, `attach_lhand/attach_rhand`: **11/11 obey it.**

### 2.2 Applying it to the three unknown pairs

| pair | bit 0 (L) | bit 0 (R) | verdict |
|---|---:|---:|---|
| **trk3 `0x491E8967` / trk10 `0xE6FF1D72`** | **1** | **0** | **DIFFER → glued `l`/`r` is IMPOSSIBLE** |
| trk54 `0x87E8C062` / trk76 `0x7D2C9CA4` | 0 | 0 | consistent with glued `l`/`r` |
| trk28 `0x0D29320C` / trk31 `0x409403C6` | 0 | 0 | consistent with glued `l`/`r` |

**trk3/trk10 cannot be `bone_l<X>` / `bone_r<X>`. For any stem `<X>`, of any length, behind any prefix.**

This is a *proof*, not a probability — and it invalidates the central premise of
`naming_dialect_deform_rig.md` §4, which states of exactly this pair: *"Convention A mirror pair →
`bone_l<X>`/`bone_r<X>`, shared stem. That is a strong prior and it drives the attack in §4."* Every
candidate that attack ever generated for trk3/trk10 was structurally incapable of being the answer. The
~11,000-candidate exclusion banked for that pair was, for the pair as a pair, vacuous.

The side token on trk3/trk10 must have **odd parity difference** — `left`/`right` (parity 1/0) and
`lft`/`rgt` (0/1) qualify; `l`/`r`, `lt`/`rt`, `_l`/`_r`, `le`/`ri` do **not**.

### 2.3 The parity law as a permanent free filter

Every candidate for every slot can be parity-checked for free, halving any future search:

| slot | hash | **required odd-byte parity of the name** |
|---|---|---:|
| trk3 | 0x491E8967 | 0 |
| trk10 | 0xE6FF1D72 | 1 |
| trk17 | 0xFAADBFFF | 0 |
| trk22 | 0x11815D82 | 1 |
| trk25 | 0x00A8F086 | 1 |
| trk26 | 0xEB221048 | 1 |
| trk28 | 0x0D29320C | 1 |
| trk29 | 0x1E4780FA | 1 |
| trk30 | 0xFE747044 | 1 |
| trk31 | 0x409403C6 | 1 |
| trk32 | 0xFBFA3B2C | 1 |
| trk33 | 0xA3EEDAF2 | 1 |
| trk54 | 0x87E8C062 | 1 |
| trk76 | 0x7D2C9CA4 | 1 |
| trk104 | 0x9EC352CF | 0 |

---

## 3. NEW LAW #2 — the prefix-agnostic mirror sieve

`bone_forge.py` documents, as a *warning*, that the map `m2(<any> + "l" + S) → m2(<any> + "r" + S)` is a
**fixed bijection determined by S alone** — so a chance hit auto-pairs and the mirror is not independent
evidence. That is correct. But run the same fact **backwards** and it is a gift.

Every FNV-1a byte step `h → (h ^ (b|0x20)) * PRIME` is **invertible** (the prime is odd). So from a
final hash we can walk *backwards*:

```
state_end(H) = (H * PRIME⁻¹) ^ 0x2A          # undo the finalisation
U(state, c)  = (state * PRIME⁻¹) ^ (c|0x20)   # undo one byte
```

For a pair spelled `<PREFIX><sideL><STEM>` / `<PREFIX><sideR><STEM>`, unwinding `STEM` and then the side
token from **both** hashes must land on the **same** state `s0` — the state after `<PREFIX>`:

```
s0_L(S) = unfold(unfold(state_end(H_L), S), sideL)
s0_R(S) = unfold(unfold(state_end(H_R), S), sideR)
TRUE STEM  ⟺  s0_L(S) == s0_R(S)
```

**This tests the stem without knowing the prefix.** It has **no false negatives** — the true stem is
guaranteed to survive. And the recovered `s0` then identifies the prefix as a *separate* 32-bit problem
(`fold(FNV_OFFSET, P) == s0`), so the name factors into two independent facts instead of one.

**Positive controls passed.** Given only the two hashes, the sieve recovers `bicep` from
`bone_lbicep`/`bone_rbicep`, and recovers `s0 = fold("bone_cheek_")` from
`bone_cheek_left`/`bone_cheek_right`. Neither was told the prefix.

### 3.1 Free result: no pair ends in a side token

The `k=0` case (empty stem ⇒ the name *ends* with the side token) is a single arithmetic check per
spelling. Across 12 spellings — `(l,r) (_l,_r) (left,right) (_left,_right) (lft,rgt) (lt,rt) (_lt,_rt)
(l_,r_) (lf,rt) (le,ri) …` — **none of the three pairs is consistent** (expected-false 2.3e-10 per test;
the positive controls `bone_cheek_left/right` and `bone_pitch_l/r` both fire correctly).

⇒ **All three pairs carry their side token MEDIALLY, not as a suffix.** The face's Convention-C grammar
(`bone_<feature>_<side>`) is therefore **excluded for trk28/31** — the jaw-region pair is a *body*-dialect
bone, corroborating the facefx doc's observation that these 8 are not FaceFX-driven.

### 3.2 The sweeping negative

Sieve over **every** stem of length 0–6 in the 37-symbol alphabet (`2,636,996,587` stems per pair):

| pair | side | stems searched | survivors | verdict |
|---|---|---:|---:|---|
| trk54 / trk76 | `l`/`r` | 2.64 e9 | **0** | no glued-`l`/`r` stem ≤ 6 chars exists, **for ANY prefix** |
| trk28 / trk31 | `l`/`r` | 2.64 e9 | 6 (k=3, all junk: `one cze cny ozy nv0 cj5`, none resolving a real prefix) | same |
| trk3 / trk10 | `left`/`right` | 2.64 e9 | 1 (`bone_leftwaistj` — unreadable, and exactly the 0.61 expected-false) | no `left`/`right` stem ≤ 6 chars |
| trk3 / trk10 | `lft`/`rgt` | 2.64 e9 | **0** | no `lft`/`rgt` stem ≤ 6 chars |

Because the sieve is prefix-agnostic and has no false negatives, these are **hard exclusions over an
entire grammar family**, not over a vocabulary. Prior sweeps could only exclude `bone_l` + stem; this
excludes `<anything>` + `l` + stem.

⇒ **trk54/76 and trk28/31 have stems of ≥ 7 characters** (or a side spelling not in the tested set).

### 3.3 NEW LAW #3 — the length gate

Because the stem characters are XORed into *both* sides identically, they **cancel** out of the low bits
of the difference. The low bits of the consistency value are therefore **independent of what the stem
contains** — they depend only on the two hashes and the stem's **length**. So each candidate stem
*length* can be accepted or refused for free, at any length, without enumerating anything.

Run over lengths 0–16: the controls pass at every length (no false negatives), trk54/76 and trk28/31 pass
at every length, and **trk3/trk10 fails at every length** — the length-independent restatement of §2.2.

---

## 4. Assumption overturned: these bones are NOT anim-only

The brief (and `bone_census.md`) hold that the 15 slots are anim-only — present in animation tracks, in
no mesh `HIER`. **The census disagrees.** Every one of them appears in real model hierarchies:

| slot | n_models | slot | n_models |
|---|---:|---|---:|
| trk28–33 (jaw/face block) | **6** | trk3, trk10, trk54, trk76, trk25 | **4** |
| trk17, trk22, trk26 | **5** | trk104 | **3** |

They live on models `0x03C70F0A`, `0x0BBA3066`, `0x1DC4F961`, `0x25C98327`, `0xA3C1FABC`
(= `pmc_hum_mattias_v3`), and trk104 on a *different* trio (`0xB58E1BB8`, `0xDAB9FE00`, `0xFF61AB75`).
So `docs/data/bone_skeleton.csv` carries their **bind-pose local offsets** — a geometric witness that no
prior attempt used.

> ⚠️ **Caveat, load-bearing:** in `bone_skeleton.csv` the `parent` and `depth` columns for these models
> are **inconsistent** (e.g. `Bone_LThigh parent=Bone_RThigh`, `Bone_Hips parent=bone_spine1`). Do not
> build on them. The `wx/wy/wz` **local offsets** are self-consistent and are what §4.1 uses.

### 4.1 What the offsets say (model `0x03C70F0A`)

*Read the head bones' local frame first:* `bone_cheek_left/right` mirror in **z** (±0.0464) while
`bone_mouth_bottom_left/right` mirror in **x** (±0.0092) — because the cheeks hang off the head and the
mouth bones hang off the jaw, whose frame is rotated. Mirror axis is therefore **per-parent**.

* **trk28 `(+0.0241, −0.0864, +0.0814)` / trk31 `(−0.0239, −0.0864, +0.0814)`** — mirror in **x**, sharing
  `z`, exactly the signature of `bone_mouth_bottom_left/right` `(±0.0092, −0.0264, +0.0863)`. So trk28/31
  are **jaw children**, ~6 cm *below* the mouth-bottom bones at the same forward depth: the **chin /
  jawline / jowl** band. trk28 (+x) is LEFT, trk31 (−x) is RIGHT, matching the side law.
* **trk29 `(+0.0014, 0, +0.0204)`, trk30 `(0, 0, +0.0235)`, trk32 `(0, +0.0019, +0.0209)`,
  trk33 `(+0.0023, −0.0022, +0.0223)`** — four **near-identical midline** bones, each offset ~2 cm
  **forward (+z)** from its parent, with x≈y≈0. That is a **serial midline chain**, and the only serial
  midline chain in a head is the **tongue** (`bone_tongue_tip` sits further along at `(0, −0.0276,
  +0.0565)`). Reading: a 4–5 segment tongue whose *tip* is the one FaceFX drives and names.
  *(This is inference from geometry, not a crack — the entire tongue/teeth vocabulary, including the
  classic misspelling `tounge`, was tested at expected-false 1e-5 and returned nothing; §5.)*
* **trk3 `(+0.1544, +0.0336, −0.0118)` / trk10 `(0.0000, +0.0256, −0.0921)`** — **not mirror images of
  each other**, independently corroborating §2.2: trk3 and trk10 are very likely **not a left/right
  name-pair at all**. Treating them as one was a mistake baked into `bone_forge.py`'s `SLOTS`.

---

## 5. What was tested this session, and what it cost

Every pool aimed at the specific slots (T is small, so a large S is affordable and safe):

| pool | S | T | expected-false | hits |
|---|---:|---:|---:|---:|
| Mined literals, verbatim (§1.3) | 79 | 8,561 | 0.00016 | 0 |
| Saboteur face concepts → Mercs2 facefx grammar | 42,442 | 8,561 | 0.085 | 0 |
| Tongue / teeth / oral chain **+ misspellings** (`tounge`, `tonge`, `tung`) vs trk29/30/32/33 | 10,275 | 4 | 0.00001 | 0 |
| Jaw-parent / head-child control layer vs trk25 + trk26 | 15,562 | 2 | 0.000007 | 0 |
| Spine / torso intermediates vs trk17 + trk22 | 21,095 | 2 | 0.00001 | 0 |
| Accessory / worn-kit vocabulary vs trk104 | 40,281 | 1 | 0.000009 | 0 |
| **DCC default auto-names** (the `Bone_bone1` shape) vs all 15 | 10,916 | 15 | 0.000038 | 0 |
| Compositional multi-word stems (≥7 chars) vs trk54 / trk76 | 174,702 | 1 | 0.00004 | 0 |
| **Mirror sieve, stems ≤ 6, prefix-agnostic** (§3.2) | 2.64 e9 ×3 pairs | — | see §3.2 | 0 real |

**Total: zero new names.** Every number above is a *confirmed negative* — `m2` is deterministic, so a
miss is a proof of exclusion.

---

## 6. Honest statement of what remains, and why

**What is now known with certainty**

1. The body dialect is shared with The Saboteur, verbatim. (Mined.)
2. The face dialect is **not** shared, and the sibling game can never yield a literal Mercs2 face-bone
   string. That lead is **closed**, not merely untried. (Mined + hashed.)
3. trk3/trk10 is **not** a glued `l`/`r` pair, and is probably not a name-mirror pair at all. (Proven —
   parity law + non-mirrored bind offsets.)
4. trk54/76 and trk28/31 are glued-`l`/`r`-consistent but have **no stem ≤ 6 characters behind any
   prefix**. (Proven — exhaustive prefix-agnostic sieve, no false negatives.)
5. No pair carries its side token as a suffix. (Proven.)
6. The 15 bones are on real models, and their bind offsets place trk28/31 at the chin/jawline and
   trk29/30/32/33 on a serial midline (tongue-like) chain. (Measured.)

**Why the names are still not recovered.** The wall is *recognition*, not coverage — and this session
sharpened rather than moved it. The prior ≤13-char exhaustive sweep already **covers** `bone_l` + 7
chars; it returned ~70,000 chance hits and no way to tell which was real. Widening the vocabulary makes
this strictly worse (S·T/2³² grows, and a chance hit into a big dictionary *reads* like a real name).
The residue is:

* stems of **≥ 7 characters** (trk54/76, trk28/31) — where blind enumeration's false-positive count
  overwhelms any readability judgement, and
* tokens that are **studio-internal and non-lexical** — a hypothesis no longer speculative but
  *demonstrated*: Pandemic shipped `Bone_bone1`, a raw DCC default, into a retail rig. A name of that
  class is unrecognisable even when you generate it, because it carries no meaning to recognise.

**And the escape hatch is now closed.** Both earlier docs conclude that "the realistic route is an
unstripped dev/debug build". **We have one** — the Jul-11-2008 devkit prototype, with a real PDB — and
it contains **only the 25 bone literals we already knew** (§1.4). The missing names are not in it.

**Therefore:** these 15 names are not recoverable from any asset currently in hand. The remaining routes
are all *external*: a Pandemic `.max`/`.ma` source rig, an exporter script, an art-side naming document,
or a build with the bone-name string table intact. Absent one of those, the correct engineering answer
is to **keep them as hashes** — the engine addresses bones by hash anyway, so nothing is blocked. Do not
spend more GPU on this; and above all do not accept a lone readable hit from a wide sweep, because §2–§3
now give you the tools to prove most such hits impossible.

**Precision note.** A wrong name in this rig is worse than an unknown one. Nothing in this document is
offered as a crack. The §4.1 anatomical readings (chin pair, tongue chain) are **geometric inference**
and are labelled as such; they should go into the rainbow table only if a literal string ever
corroborates them.

---

## 7. Honesty ledger

| Claim | Basis |
|---|---|
| Saboteur shares the body dialect verbatim | **Mined** — literal strings in its decomp |
| Saboteur's 36-bone `FxMasterBoneList` | **Mined** — `Male.fxa` / `Female.fxa` |
| Saboteur's face rig does not transfer to Mercs2 | **Confirmed negative** — 79 literals + 42k re-spellings, ef ≤ 0.085, zero hits |
| Jul-08 devkit contains no new bone names | **Mined** — full string sweep of the prototype PE + WAD |
| Parity law; glued `l`/`r` preserves hash bit 0 | **Proven** algebraically; verified 11/11 on known pairs |
| trk3/trk10 is not a glued `l`/`r` pair | **Proven** (parity) — a hard NOT |
| trk54/76, trk28/31 have no glued-`l`/`r` stem ≤6 for any prefix | **Proven** — exhaustive sieve, no false negatives |
| No pair ends in a side token | **Proven** — exact check, ef 2.3e-10 |
| The 15 bones are on 3–6 models each | **Measured** — `bone_census.csv` |
| trk28/31 = chin/jawline pair; trk29/30/32/33 = midline (tongue-like) chain | **Inference** from bind offsets. NOT a crack. |
| `bone_skeleton.csv` parent/depth columns are unreliable for these models | **Observed** — self-contradictory rows |
| All §5 pools excluded | **Confirmed negatives** — `m2` is deterministic |
