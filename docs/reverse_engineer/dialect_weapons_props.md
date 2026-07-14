# Naming dialect — WEAPONS and PROPS

Department report. Recovering `pandemic_hash_m2` bone/hardpoint names for the ~86 `global_weapon_*`
models and the `global_*` / `global_env_*` prop set.

**Result: 61 new nodes cracked and corroborated. Zero speculative names shipped.**

Machine-readable companion: [`tools/bone_forge_weapons.json`](../../tools/bone_forge_weapons.json).

---

## 0. The arithmetic, kept honest

`expected_false = S · T / 2³²`  (S = candidates hashed, T = targets in the net).

Every claim below quotes its own S, T and expected-false. Nothing was accepted on a bare hash match:
a 32-bit collision is cheap, so every name here carries a **second witness** — structural (parent /
switch-group / position / side-law) or provenance (a literal from a real source).

---

## 1. MINED — what real sources gave up

### 1.1 The console string tables — a clean NEGATIVE result

The brief flagged `game-files/xbox-vz.unique-strings.txt` + `ps3-VZ.unique-strings.txt` as the best
lead (the console builds ship an uncompressed name table the PC bake stripped; it has already yielded
+510 model names).

I hashed **every** string in both files, plus path-splits and whitespace tokens:

| S (distinct candidates) | T (all unnamed bone hashes) | expected-false | actual hits |
|---|---|---|---|
| 6,335,885 | 7,521 | **11.09** | **11** |

All eleven hits are garbage: `l3_7`, `tO1cxxpp`, `BDf3O`, `fbdAD`, `S4T2`, `R8A8-8`, `L3_1`, `l123`,
`iDazzzxDi`, `l3_8`, and one 170-char mojibake run.

**Hits ≈ expected noise ⇒ signal is exactly zero.** The console name table carries **asset/block
paths, not rig node names**. This is the central arithmetic demonstrated live, and it is also the
trap: had I been sweeping a 20k-word *dictionary* instead, those same 11 chance collisions would have
come back as plausible English words and read like real names.

**Do not repeat this sweep.** Recorded as a dead end.

The tables *do* contain a handful of bone literals, all of which we already knew:
`hp_barreltip_a`, `hp_shelleject`, `hp_fx_light`, `hp_fx_parachute`, `bone_ak47`, `bone_pistol`,
`bone_grenade`, and the `hp_snap_*` oilrig family.

### 1.2 The Saboteur binary — dialect confirmation (the real payoff)

`output/_ghidra_saboteur/saboteur_all_functions_decomp.txt` (same studio, clean binary, real names):

```
hp_shelleject   hp_shelleject1   hp_shelleject2
hp_centerofmass hp_buoyancy      hp_buoyancy_xyz
hp_wepspawnleft hp_wepspawnright
hp_particleeject hp_particleeject1
```

`hp_shelleject` and `hp_centerofmass` are **verbatim shared with Mercs 2**. This is hard proof the two
games use one hardpoint dialect, and it validates using Saboteur as a vocabulary oracle. `_prop`,
`hp_wepspawn*` and the numeric `1`/`2` sibling suffix all come from here.

### 1.3 Mined-literal sweep

Saboteur strings + the Lua corpus + ECS identifiers + `wad_vocab` / `saboteur_vocab`, each token also
wrapped in `hp_` / `bone_`:

| S | T (my department) | expected-false | hits |
|---|---|---|---|
| 41,842 | 791 | **0.0077** | **6** |

* `0x79A519D6` → **`hp_ammo`** — NEW. Root of `global_pickup_ammo`. ✅
* `hp_clusterbomb`, `hp_moab`, `hp_daisycutter`, `hp_bunkerbuster`, `hp_grapplinghook` — these five
  were reached **independently** by the structural root rule (§2.1). Two unrelated methods agreeing on
  the same five strings is strong mutual corroboration.

With expected-false 0.0077, six hits is ~780× the noise floor. This is signal.

---

## 2. CRACKED — the two rules that carried the department

### 2.1 The ROOT RULE — 59 nodes, expected-false 0.0002

**Observation that started it:** `global_weapon_minigun`'s root node is `hp_minigun`; `global_weapon_mgl`'s
is `hp_mgl`. The root is named *after its own model*.

**Rule.** The depth-0 root of a model is one of:

```
<model>            hp_<tail>          bone_<tail>
<model>1           hp_<tail>1
```

where `<tail>` is the model name with zero or more leading family tokens stripped
(`global_weapon_deserteagle` → `deserteagle`).

| S | T (unnamed roots) | expected-false | cracked |
|---|---|---|---|
| 9,126 | 95 | **0.000202** | **59** |

**Why this is certain, not lucky.** The candidate is built from *the model's own name*. A hit is not a
lookup into a dictionary of plausible words — it is a self-referential match, so the "a chance hit
reads like a real name" failure mode cannot occur. Corroborated three ways: two pre-existing names
(`hp_minigun`, `hp_mgl`) already obeyed it; five of the results were independently re-derived by
literal-mining (§1.3); and expected-false is 1-in-5,000.

**New weapon roots (31):**

```
hp_40mmgrenade   hp_aarocket      hp_amraam        hp_bullpup      hp_bunkerbuster
hp_clusterbomb   hp_coilgun       hp_daisycutter   hp_deserteagle  hp_dshk
hp_dumbbomb      hp_fae           hp_ffarrocket    hp_grapplinghook hp_hellfire
hp_jdam          hp_kvsk          hp_m34wp         hp_microuzi     hp_mlrsrocket
hp_moab          hp_mp5sd         hp_pf97rocket    hp_qbzlmg       hp_recoilessrifle
hp_rpgrocket     hp_rpk           hp_sawmg         hp_tankshell    hp_tmp
hp_towrocket
```

plus the `…1` variant form: `global_weapon_ied1`, `global_weapon_m21at1`, `global_weapon_m86pdm1`,
`global_weapon_smaw1`, `global_weapon_beaconlight1`.

**The rule generalizes past weapons** — it is a *model* rule, not a weapon rule:

```
global_pickup_ammo            -> hp_ammo
global_deliverycrate          -> hp_deliverycrate
{al,ch,gr,pr,up,vz}_deliverycrate -> hp_<x>_deliverycrate
global_crateaid               -> hp_crateaid
global_zippo                  -> hp_zippo
global_munitions_{bunkerbuster,fae,hackedairstrike} -> hp_munitions_*
global_searchlighta           -> global_searchlighta1
pmcoutpost_fountain           -> pmcoutpost_fountain1
vzoutpost_bld_guardtower_{al,gr} -> ..._al1 / ..._gr1
```

### 2.2 The MAGAZINE SWITCH — 2 nodes, the best find of the run

`magazineA` (already named) is a **SWIT** — a switch node that renders exactly one of its children. On
22–29 handheld weapons it has two `in_swit` children, both previously unnamed and both co-located with
the parent:

| hash | name | S | T | expected-false |
|---|---|---|---|---|
| `0x3DF6AA10` | **`magazineA_loaded`** | 13,194 | 3 | 0.000009 |
| `0x8DE5AD74` | **`magazineA_prop`** | 285,080,708 (wildcard) | 1 | 0.066 |

**Corroboration — this pair is self-evidently right:**

* **Structural.** They are the *only* two children of `magazineA`, both flagged `in_swit`, on 22+ models.
  A switch with exactly two alternates is exactly a two-state pair.
* **Semantic.** `loaded` = the magazine as fitted in the weapon; `prop` = the magazine as a detached
  **physics prop** — the one that drops out of the gun during a reload. That is precisely the switch a
  shooter's reload FX needs, and it explains why the node exists at all.
* **Dialect.** `_prop` is corroborated as a live suffix by the Saboteur binary's `_prop`/`hp_wepspawn*`
  vocabulary, and it pairs with the engine's known `_pristine`/`_ruin` state-suffix convention.

**Corollary for other departments:** `_prop` means *"the detachable physics-prop version of this
part"*. Expect it wherever a rigged part can detach.

---

## 3. The observed weapon grammar (ground truth, re-confirmed)

Every handheld weapon carries a near-identical depth-1 hardpoint set off the root. A weapon is small,
so all positions are in **metres, sub-1.0** — the muzzle is the far `+z` end.

| node | function | evidence |
|---|---|---|
| `hp_barreltip_a` | muzzle, far `+z` (AK-47: `z=+0.619`). `_a`.. `_d` on multi-barrel mounts | 42 models |
| `hp_shelleject` | brass ejection port. `_a`..`_d` on quad50 | 36 models; **verbatim in Saboteur** |
| `hp_dock_left` / `hp_dock_right` | the two **hand** grip points | 37 each; obeys the side law (+x=left) |
| `hp_CenterOfMass` | physics COM at the origin | 34 models; **verbatim in Saboteur** |
| `magazineA` → `magazineA_loaded` / `magazineA_prop` | magazine + reload switch | §2.2 |
| `hp_attach` | carry / holster point | |

**Mounted weapons** (`dshk`, `m60`, `mk19`, `tow`, `recoilessrifle`, `m250cal`, `tripodmount`,
`quad50`) add a destructible base and a traverse chain:

```
piece1a  (SWIT)
  piece1a_pristine
    bone_yaw / bone_yaw_turret   (traverse)
      bone_pitch                 (elevation)
        hp_gunmount_a            (gun attach)
    hp_seat_gunner / hp_dock_gunner
```

`quad50` is the full expression: four `hp_barreltip_a..d` and four `hp_shelleject_a..d`, symmetric in x
and obeying the side law.

---

## 4. UNSOLVED — reported honestly

> A wrong name is worse than an unknown one. These three are where the evidence ran out. Each is
> recorded with the space I *eliminated*, so nobody re-treads it.

### 4.1 `0x2C4AB49F` — the centred hardpoint on 23 handheld weapons

Depth-1 leaf on ak47, ak103, bullpup, deserteagle, kvsk, m4, m95, mac11, microuzi, mp5sd, pistol,
pp2000, qbu88sniper, qjy88, rpg, smg, sniperdragunov, tmp, xm8, rpk, sawmg, qbzlmg. **`x = 0.000`
exactly** (centred), `y > 0` (above the bore), `z` varies. bbox `0.03` ⇒ a locator point. State `static`.

**Exhaustively eliminated:**

* `hp_` + any ≤6 chars, `bone_` + any ≤6 chars, bare ≤6 chars — full 37-symbol wildcard,
  **S = 7.9 × 10⁹**, expected-false 1.84, and it returned exactly two garbage strings (`hp_ni12ev`,
  `_zcysh`) — i.e. noise, on budget.
* An 18,515-name curated firearms pool (sight/scope/laser/muzzle/aim/trigger/… × prefixes × suffixes).

⇒ The name is **≥7 characters after its prefix**, or uses a prefix outside `{hp_, bone_, ∅}`. This is a
rigorous bound, not a shrug. Needs a ≥7-char GPU wildcard or a new literal source.

### 4.2 `0xE68BCD4D` / `0xA99F98B3` — the mounted-MG rear pair

A **left/right pair** at the rear of dshk, m60, mk19, tow, recoilessrifle, m250cal:

| model | `0xE68BCD4D` | `0xA99F98B3` |
|---|---|---|
| dshk | `(+0.138, 0.010, −0.589)` | `(−0.142, 0.012, −0.583)` |
| m60  | `(+0.100, 0.001, −0.623)` | `(−0.117, 0.019, −0.622)` |

By the side law `+x = LEFT`, so `0xE68BCD4D` is the **left** member. Rear of the gun, at bore height,
symmetric ±0.12 m. These rigs notably **lack** `hp_dock_left`/`hp_dock_right` — so functionally these
are near-certainly the **twin spade grips**, i.e. the mounted-gun hand docks.

**Function is confident; the spelling is not.** A 3,168-candidate *pair-constrained* sweep
(`{grip, handle, spade, hand, dock, …} × {l/r, left/right, lt/rt, a/b, 1/2}`, requiring both members to
hit) found nothing. **Not named.**

### 4.3 The destruction-chunk series — highest-value open target

~**247** unnamed hashes, all `in_swit` children of `piece1a_ruin`, all with states `break_piece|intact`.
Their model-counts form a clean **monotone-decreasing series** — 353, 339, 338, 316, 292, 282, 281,
257, 248, 217, 217, 208, 205, … — exactly what an **indexed** series looks like when models with more
debris chunks use more indices.

Top members: `0x1B385A41`, `0x2136251C`, `0x8DCB305A`, `0x9930D1D6`, `0xEFD28665`, `0xFB33AAB3`,
`0x85CFA0F0`, `0x793FAA00`, `0x07C3A1A3`.

Eliminated: `piece1a[_ruin]_{propattach,prop,debris,chunk,part,frag}{00,0,000,a}` (19,440 names,
expected-false 0.034); a 63,640-name stem×index sweep.

*(Note: the `piece1a_propattach00..NN` form given in the brief as known dialect does **not** hash to any
of these 247 — whatever those names are, they are not the children of `piece1a_ruin`.)*

#### 4.3.1 A hard result: the chunks are LETTER-indexed, and I have the stem's FNV state

A **series-consistency** wildcard (search a *stem*, require it to hit ≥3 indices **simultaneously**;
S = 381,391,560, T = 247, expected-false ≈ **7 × 10⁻¹⁴**) returned a score-**4/4** hit:

```
935ka -> 0xD0B0CDDE   (32 node instances)
935kb -> 0xF2B7BF29   (23)
935kc -> 0xD8B557A4   (15)
935kd -> 0x7ABD126F   ( 8)
```

`935k` is obviously not a name — **it is a hash-state collision with the real stem.** FNV-1a is
invertible, so the map `state → (state+a, state+b, state+c, state+d)` is injective. The probability that
a *random* state sends all four of a/b/c/d into a 247-element target set is `(247/2³²)⁴ ≈ 1.1 × 10⁻²⁹`;
across the 1.87 M states searched, the expected count is `2 × 10⁻²³`. **Observing one is therefore not
chance — it proves the target set really does contain a quadruple `{Xa, Xb, Xc, Xd}`** for some real
stem `X`, and that `X` has FNV internal state:

> **`h_prefix(X) = 0x43F535A1`**

The monotone-decreasing instance counts (32 → 23 → 15 → 8) confirm it: this is an authored,
**letter-indexed** `a/b/c/d` chunk family, exactly the shape the destruction dialect predicts.

**What this hands the next person.** They do not need to guess a grammar any more — they need one
string `X` with `h_prefix(X) == 0x43F535A1`. I eliminated `{∅, hp_, bone_, piece1a_, piece1a_ruin_,
ruin_, piece_, prop_, debris_, chunk_, break_, global_, piece1b_, piece1c_} + ≤5 chars`
(S = 1.07 × 10⁹, only the `935k` collision itself came back) and a 33,250-name curated stem list. So
`X` is **longer**. A GPU state-preimage search (or a meet-in-the-middle on a plausible prefix) closes it.

**This is the biggest single lever left in the department** — one correct stem names a whole chunk
family, and the same series-consistency technique then unlocks the main series (`0x1B385A41` @ 353
models, `0x2136251C` @ 349, `0x8DCB305A` @ 338, …), which is ~247 nodes across ~350 prop models.

**Method note, worth keeping:** requiring *k* simultaneous index hits drives expected-false to
`S · (T/2³²)ᵏ`. At k = 3–4 that is ~10⁻¹⁴, so a **wide** stem search is statistically **safe** — the
multi-hit constraint replaces the readability witness. This is the one place where going big is correct,
and it is why it found structure that every narrow grammar sweep missed.

---

## 5. Scoreboard

| | count |
|---|---|
| **New nodes cracked + corroborated** | **61** |
| — via the root rule (structural, self-referential) | 59 |
| — via SWIT structure (`magazineA_loaded`, `magazineA_prop`) | 2 |
| — of which independently re-derived by literal mining | 6 |
| Verified by hash round-trip `m2(name) == hash` | **61 / 61** |
| Speculative names shipped | **0** |
| Weapon models touched | 38 of 86 |
| Open targets left, with search space bounded | 3 (≈250 nodes) |

**Confidence per rule**

| rule | confidence | why |
|---|---|---|
| ROOT RULE | **CERTAIN** | self-referential candidate; expected-false 0.0002; 3 independent corroborations |
| MAGAZINE SWITCH | **CERTAIN** | only 2 children of a SWIT, on 22+ models; semantics exact; `_prop` confirmed by Saboteur |
| WEAPON/MOUNTED TEMPLATE | **CERTAIN** | pre-existing names, re-confirmed across 86 models |
| SIDE LAW (+x = left) | **CERTAIN** | 9,112 named instances; used only to *reject*, never to accept |
| §4 spade-grip *function* | LIKELY | geometry + the absence of `hp_dock_*` on those rigs |
| §4 spade-grip *spelling* | **UNKNOWN — not named** | |

---

## 6. Open questions

1. **`0x2C4AB49F`** — what centred, above-the-bore locator does every handheld weapon need, whose name
   is ≥7 chars? (Sight/laser/aim were all eliminated at ≤6.)
2. **The chunk-series stem** (§4.3) — the single highest-value unknown; GPU series-brute is the move.
3. **The spade-grip spelling** (§4.2).
4. The `wpn_*` reflection blocks hold weapon **stats**, and the loader
   (`mercs2_combat::stats`) confirms the field schema is **positional — the names are not in the
   block**. So they cannot name rig parts. Ruled out as a naming source.
5. 36 model roots remain unnamed (mostly `vz_state_*` / building families) — outside this department
   but the root rule should be re-run there.

---

## 7. Reproduce

```bash
python tools/fnv.py                     # verify m2()
# root rule / sweeps: see tools/bone_forge_weapons.json for the exact pools
```

Data used: `docs/data/bone_skeleton.csv` (per-model rig), `docs/data/bone_census.csv` (n_models,
in_swit, states, bbox), `docs/data/named_bones.csv`, `tools/rainbow_table.json` (model-hash → name).

**`tools/rainbow_table.json` was not modified by this department.** The 61 names are staged in
`tools/bone_forge_weapons.json` under `cracked` for a merge owner to fold in.
