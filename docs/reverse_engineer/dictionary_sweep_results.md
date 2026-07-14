# External-dictionary sweeps of the unnamed node hashes

**Date:** 2026-07-14  ·  **Hardware:** RTX 2000 Ada (measured 0.5 B/s forward FNV, ~1–4 B/s product)
**Hash:** `pandemic_hash_m2` (FNV‑1a, per‑byte `|0x20` fold, `^0x2A` finalize) — case‑insensitive.

The game's own 648k‑token corpus (`docs/data/wad_vocab.txt`) was already exhausted on these targets.
This pass brings in vocabulary the shipped game **never spells**: a frequency‑ranked English list
(top‑20k + Google‑20k), the 370k‑word `words_alpha` list, a hand‑built 3D/rigging/automotive/
destruction technical lexicon (`tools/dictsweep_data/tech.txt`, 50 lines ≈ 900 words), and every
identifier token in The Saboteur decompilation (`tools/dictsweep_data/saboteur_vocab.txt`, 9,505
tokens — same studio, same riggers; `susp` from there cracked `bone_susp_rl/rr`).

**The only trust metric is `EF = S·T/2³²`.** Every sweep below prints its own S and EF. Each target is
swept at **T = 1** so the error bar stays ~0 even with a huge vocabulary — this is the one regime
where a wide dictionary is safe (100M candidates × T=1 = 0.023 expected false). Hits are reported by
band; a hit in a band with EF < ~0.3 is a name, a hit in a band with EF > 1 is the noise the
arithmetic promised and is discarded on a criterion (word‑segmentability) fixed **before** the run.

## Tools built (reusable, in `tools/`)

- **`bone_mitm.py`** — meet‑in‑the‑middle **exhaustive** preimage search. FNV‑1a is invertible
  (`unfold(S') = (S'·PRIME⁻¹) ^ (b|0x20)`), so a name `P‖Q` satisfies
  `state_after(P) == unfold_all(final, Q)`. Fill a 2³²‑bit bitmap (512 MB) with all `Kᵖ` prefixes
  forward, probe it backward from the target with all `Kˢ` suffixes → closes length `p+s`
  exhaustively at cost `Kᵖ+Kˢ` instead of `K^(p+s)`. Self‑test recovers `bone_frame` and `bone_root`
  from their hashes alone (every emission re‑verified). Supports a free literal prefix (`--prefix`).
- **`bone_dictsweep.py`** — tiered product sweeps (TINY 20 / SMALL 331 / MID 25.8k / BIG 380.8k
  words) on the GPU, printing S and EF per plan and refusing any plan over `--ef-cap`.
- scratchpad drivers: `sift.py` (intersect a MITM dump with an exactly‑counted 1/2/3‑word language),
  shard/compound sweeps for the debris grammar.

---

## (A) Universal vehicle destruction‑group stem — `0x765CD254`  → **NOT CRACKED (clean negative)**

**Structure confirmed** from `bone_skeleton.csv` (e.g. `civ_veh_truck_transport` 0x02195587):

```
bone_frame
  └─ 0x765CD254  (STEM, depth 2)          ← the target
       ├─ 0x75F1F74D  = STEM_ruin         (m2(STEM+"_ruin"))
       └─ 0x255EAB53  = STEM_pristine      (m2(STEM+"_pristine"))
             ├─ bone_hub_fl/fr/rl/rr   hp_seat_fl/fr   hp_dock_fl/fr   hp_fx_exhaust_a/b …
```

So STEM names the whole destructible body assembly; `_pristine` holds the intact rig, `_ruin` the
wreck. Present in 172 vehicle models. `bone_frame` = `0x8B36C275` (verified), the parent.

**Sweeps (all T = 1):**

| sweep | S | EF | hits |
|---|---:|---:|---|
| MITM exhaustive `[a-z_]` L=9 | 7.6e12 | 1775 preimages | 1‑word: **0**, 2‑word: **0** |
| MITM exhaustive `[a-z_]` L=10 | 2.1e14 | 47.9k preimages | 1‑word: **0**, 2‑word: **0** |
| MITM exhaustive `[a-z_]` L=11 | 5.6e15 | 1.29M preimages | 1‑word: **0**, 2‑word: **0** |
| MITM exhaustive `[a-z_]` L=12 | 1.5e17 | 34.9M preimages | 1/2‑word: **0** (only 3–4‑token noise) |
| dictsweep 1‑word BIG (any length) | 380,794 | 8.9e‑5 | **0** |
| dictsweep BIG + digit/letter | 3.6e7 | 0.008 | **0** |
| dictsweep SMALL×BIG / BIG×SMALL | 2.5e8 each | 0.059 each | **0** |
| dictsweep MID×MID | 1.3e9 | 0.310 | **0** |
| dictsweep SMALL³, TINY×BIG, SMALL²×NUMS, TINY×SMALL×NUMS | ≤7e8 | ≤0.16 | **0** |

The **MITM closure is the strong result**: over the full `[a-z_]` alphabet, for **every** length 9–12,
there is provably **no** 1‑word or 2‑word real‑English/technical name that hashes to `0x765CD254`.
`sift.py` cross‑checked this against an exactly‑counted language: the 1‑word language (S=5,289 over
these lengths, EF 1.2e‑6) and the 2‑word language (S=2.5e8, EF 0.057) both returned **zero**, while
the 3‑word band returned 47 hits against 39.7 predicted noise — the error model is calibrated to the
digit. `mesh_stalkedgeo` (the single dictsweep 3‑slot hit at EF 0.16) is that noise and is
structurally meaningless.

**Conclusion:** STEM is **not** any 1‑ or 2‑word combination of ~380k English + technical + Saboteur
tokens (glued or `_`‑joined), and **not** any word‑segmentable `[a-z_]` string of length ≤ 12. It is
either a 3+‑token compound (unrecoverable — noise‑dominated), contains a character outside `[a-z0-9_]`,
or is a studio‑internal non‑word token. Prior work already ruled out `bone_body / vehiclebody /
bodyparts / bone_damage / bone_chassis` and all ≤8‑char `[a-z_]` strings; this pass extends the
exclusion to the whole external dictionary in the 1‑ and 2‑word shapes.

---

## (B) Wheel children — 18 hashes (3 per wheel bone on the M35 family) → **NOT CRACKED (clean negative)**

Leaf nodes at the wheel centre, 3 per `bone_wheel_*`, no side/index, don't embed the parent name.

- **dictsweep, all 18 at once (T=18):** 1‑word BIG EF 0.002 → **0**; BIG+digit EF 0.15 → **0**;
  TINY×BIG EF 0.064 → **0**; SMALL²×NUMS EF 0.086 → **0**. (2‑word bands at T=18 exceed the EF cap.)
- **Exhaustive `[a-z0-9_]` up to length 8, per‑hash (T=1):** across all 18 children, the *only*
  word‑segmentable preimage anywhere was `cstlnmr` (L7, on 0xA1228DB2) — pure noise.

**Conclusion:** if these names are ≤ 8 characters they are provably not dictionary words/compounds
(full alphanumeric closure); if longer they are not 1‑word or word+digit names. Consistent with the
task's own observation that each of the 18 is "individually named with no shared stem" — the pattern
of an engine/exporter‑assigned mesh‑split token, not an authored word.

---

## (C) Debris / mesh bare stems — 14 targets → **1 CRACKED, 13 clean negative**

The 8 rubble stems (`rubble_stem_states.json`) are all numbered debris series whose members are
children of **`piece1a_ruin`** (5,551 instances across `industrial_bld_refinery06`,
`vzoutpost_bld_barracktent`, …), siblings of the already‑named `piece1a_propdebris00..79`. **None of
the 14 bare hashes is itself a census node** — they are *peeled prefix‑states* (the shared FNV state
before a numeric suffix), so "cracking" one means recovering the shared prefix string.

### ✅ `0x9FCC326C  =  piece1a_propdebris`   (EF(T=1) = 0.0033, verified)

Found by a `piece1a_<word>` shard‑grammar sweep (shard ids × debris vocabulary). Verified:
`m2("piece1a_propdebris") == 0x9FCC326C` and `m2("piece1a_propdebris00") == 0x2136251C` (a node
already in the rainbow table). This is the `%02d` / 93‑member series; the peel names the outer node
`0x13D7374E` and confirms the full `piece1a_propdebris00..92` series prefix. Written to
`docs/data/bone_dictionary.json`.

### ❌ The other 7 rubble bares — negative

`0x5A87B6B4, 0x8A23F21B` (`_%d`/96), `0xFAD70FF3, 0x0CD72C4A` (`%d`/96), `0xBED6B180` (`_%d`/88),
`0xA0CC33FF` (`%d`/88), `0x48D78ABD` (`_%02d`/93). Swept per‑target (T=1):

| sweep | S/target | EF | result |
|---|---:|---:|---|
| `piece1a_<BIG>` (exhaustive dict, ±glue) | 7.7e5 | 1.8e‑4 | only `piece1a_propdebris` on its own hash |
| `piece1a_<debris>_<debris>` + `piece1a_<debris><num>` | 4.9e8 | 0.114 | **0** real |
| shard(41,916 forms)×`{propdebris,propattach,…}` | 8.4e5 | 2e‑4 | **0** |
| `piece1a_<SMALL><BIG>` compound (±glue) | 1.0e9 | 0.235 | only noise (`piece1a_bipedvibrants`, `piece1a_imposter_maniable`, …) |

The `_%02d`/`0x48D78ABD` bare is the **same 93‑member series** as the cracked `%02d`/`0x9FCC326C`;
because the real members carry no underscore before the digits (`piece1a_propdebris00`), the `_%02d`
peel has no real preimage — it is a **peeling artifact**. The same is likely true of the paired
`_%d`/`%d` interpretations of the 96‑ and 88‑member series: they are genuine series under
`piece1a_ruin`, but their word lies outside a 380k‑English + technical + Saboteur dictionary and its
2‑word compounds (all clean at the EFs above). They read as `propdebris`‑style studio compounds the
game never spells elsewhere.

### ❌ The 6 mesh bares — not corroboratable

`0x8B2C6EBE, 0x4F17DDD2, 0x8DC522E5, 0x0586FA14, 0xDD512C19, 0xF0570DA5` (143 members each). **None
appears in `bone_skeleton.csv`**, so there is no parent/sibling context to constrain or corroborate a
guess. dictsweep bands under EF 0.3 (1‑word, BIG+digit, TINY×BIG, SMALL²×NUMS) all returned **0**; the
above‑cap bands returned only the predicted noise (`charmfulkeel`, `waterpitlocator`, …). Left open.

---

## Honest bottom line

- **Cracked:** `0x9FCC326C = piece1a_propdebris` (C), EF 0.0033, structurally corroborated. Confidence **high**.
- **Clean negatives at stated EF** (each saves the next person the same sweep):
  - **(A)** `0x765CD254` is no 1‑ or 2‑word external‑dictionary name, and no word‑segmentable `[a-z_]`
    string of length ≤ 12 (MITM‑exhaustive). Needs a non‑`[a-z0-9_]` character, a 3+‑token compound,
    or a studio‑internal token — or a witness source other than a dictionary (e.g. a console‑WAD name
    table like the ASET oracle).
  - **(B)** all 18 wheel children: no dictionary name ≤ 8 chars (full alphanumeric closure), no
    1‑word/word+digit name at any length.
  - **(C)** 7 remaining rubble bares (part peel‑artifact, part non‑dictionary `piece1a_*` compound)
    and 6 mesh bares (not in the skeleton, no corroboration possible).

The recurring finding across A/B/C: what remains is **not** in any external English/technical/
sibling‑studio dictionary. These are the tokens an exporter or an artist coined that no shipped string
witnesses — the same wall the ASET work hit, where the fix was a *second data source*, not a bigger
dictionary.
