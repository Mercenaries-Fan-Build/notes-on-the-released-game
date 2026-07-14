# Naming dialect: DESTRUCTION / ENVIRONMENT (buildings, shards, props, vegetation)

Scope: the SWIT (destruction-switch) node dialect on building / environment / prop models.
Companion docs: `naming_dialect_deform_rig.md`, `naming_dialect_facefx.md`,
`naming_dialect_systems.md`. Master write-up: `bone_census.md`.

Evidence classes used throughout, marked on every rule:

| tag | meaning |
|-----|---------|
| **[N]** | a **named** bone already in the corpus exhibits the pattern |
| **[S]** | a **structural** observation from `bone_skeleton.csv` (parent / depth / position / model class) |
| **[H]** | **hash-verified**: candidate generated and it hit an unnamed census hash, with the quoted expected-false |
| **[I]** | **inference** from period (2008) art-pipeline convention — *speculation, not evidence* |

Everything below that is not tagged **[I]** is grounded. Nothing tagged **[I]** was written into
the name corpus.

---

## 0. Headline results

| metric | value |
|---|---|
| candidate pool (final harvest) | **S = 60,088** |
| unnamed targets (frozen `bone_census.csv`) | **T = 7,176** |
| **expected false positives** = S·T / 2³² | **0.100** |
| **known census names the grammar reproduces exactly** | **1,021** |
| known names the grammar *collides* with (i.e. real FPs) | **1** |
| **NEW bones cracked** | **182** (966 node instances) |

The 1,021-name agreement is the load-bearing validation: the same generator that produces the 182
new names re-derives, character-for-character, a thousand names that were cracked independently by
other means. The single collision is quoted and rejected in §6.

---

## 1. The core grammar

### 1.1 Shard identifier — `<kind><digit><letter>`

    kind   := piece | slice          [N] piece1a, Slice2A, Slice4A
    digit  := 1..9                   [H] piece1a .. piece5l observed
    letter := a..p                   [H] piece3p, piece5l, slice2o confirmed (see below)

**The kind vocabulary is CLOSED at {piece, slice}.** [H] I ran a joint-constraint discovery over a
38,169-word in-domain vocabulary requiring `W1a_pristine` **and** `W1a_ruin` to *both* hit
(expected-false 1.1e-7). It returned **zero** new kind words. There is no `chunk`, `frag`, `shard`,
`block`, `panel` kind. This is a strong, clean negative.

Casing is free (the hash folds case): `Slice2A` and `slice2a` are the same node. Corpus convention
is lowercase.

The letter axis runs at least to **p** — previously believed a..h. New: `piece3p`, `piece5l`,
`piece2m`, `slice2o` [H].

### 1.2 State suffix

    state := <empty> | _pristine | _ruin | _interior

- `_pristine`, `_ruin` — **[N]** `piece1a_pristine`, `piece1a_ruin`, `slice1a_ruin`.
- **`_interior` — NEW, and the single biggest find in the shard grammar.** [H]+[S]
  Discovered by joint-constraint sweep (8 simultaneous hits across `piece1a/1b/2a/2b/slice1a…`,
  expected-false 1.1e-7). Structurally corroborated on a large scale:

  | node | models | parent |
  |---|---|---|
  | `slice1a_interior` | 137 | `slice1a_pristine` |
  | `slice1b_interior` | 134 | `slice1b_pristine` |
  | `slice1c_interior` | 52 | `slice1c_pristine` |
  | `slice2a_interior` | 39 | `slice2a_pristine` |

  Note the parent: **`_interior` hangs under `_pristine`, not under the bare shard.** It is the
  interior geometry of the intact building (visible once you blow the façade). This is a *third*
  sibling next to pristine/ruin, and it was entirely absent from our model of the dialect.

**Tested and REJECTED** (zero hits, so these states do not exist): `_damaged`, `_destroyed`,
`_intact`, `_broken`, `_static`, `_foundation`, `_base`, `_rubble`, `_debris`, `_collapse`, `_fx`,
`_col`, `_collision`, `_shadow`, `_lod/_lod1/_lod2`, `_tiny`, `_imposter`, `_glass`, `_props`,
`_attachments`. (`ruin`, `pristine`, `foundation`, `static`, `intact`, `break_piece` **do** exist as
standalone root/state names — they are not shard suffixes.)

### 1.3 Tree shape (canonical, from `bone_skeleton.csv`) [S]

    <model root>
      piece2b                        d1, in_swit=0     -- shard group node
        piece2b_pristine             d2, in_swit=1
          piece2b_interior           d3                -- interior geometry
          piece2b_propattach00       d3                -- prop mounts (see 1.4)
          hp_fx_light / hp_ladder_top_a / hp_civilian  -- hardpoints
        piece2b_ruin                 d2, in_swit=1
          <rubble chunks>            d3, leaf          -- UNCRACKED, see §5
      slice1b
        slice1b_pristine
        slice1b_ruin

Verified end-to-end on `shanty_bld_house04` and `jungle_bld_ruinshotelfront`.

### 1.4 Prop-mount series — `<shard>_propattach<NN>`

    <shard>_propattach<NN>[ _pristine | _ruin ]      NN := 00..39 (2-digit, zero-padded)

- `<shard>_propattach00..12` — **[N]** already known.
- `<shard>_propattach<NN>_ruin` — **[N]** already known.
- **`<shard>_propattach<NN>_pristine` — NEW.** [H]+[S] e.g. `slice1a_propattach00_pristine`
  (100 models), `piece1a_propattach00_pristine` (97 models). Decisive corroboration: the `_ruin`
  sibling was **already in the corpus**, so the propattach node carries the same pristine/ruin pair
  as a shard does. This single rule accounts for ~200 of the new names.
- Index range extends past 12: `propattach13`, `propattach20` exist [H].

A propattach node is a prop socket **on a shard**; its child is the prop instance (occasionally an
actual asset name — e.g. `global_env_each#` and `jungle_babylonia_##` appear as children [S]).

### 1.5 Dot-compound — `<component><NN>.<shard><state>`

    component := floor        [N] floor02.piece1b, floor00.slice1a, floor01.piece1a
    NN        := 00..19 (2-digit)
    then the full shard grammar, INCLUDING the state suffix:
        floor02.piece1b_pristine   floor02.piece1b_ruin   floor01.piece1a_interior   [H]

**The component vocabulary is essentially closed at `floor`.** [H] Joint-constraint discovery over
the 38k in-domain vocabulary requiring ≥3 simultaneous hits (expected-false 2.1e-13) returned
`floor` (52 hits) and two opaque 3-letter tokens `ghw` / `bbd` (3 hits each). There is **no** `wall`,
`roof`, `corner`, `column`, `awning`, `balcony`, or `stair` component — every one was generated and
every one missed. That is a direct refutation of the most natural guess about this dialect, and it
is worth stating plainly: **the buildings are sliced by storey, not by architectural element.**

`ghw`/`bbd` are hash-real but semantically opaque, and `bbd*` nodes are **parent-inconsistent**
(`bbd02.piece4f_interior` sits under `floor00.slice1a_pristine`). I treat both as **unconfirmed and
exclude them from the shipped grammar** — they are the most likely home of my ~0.1 expected FP.

### 1.6 Nesting: NONE [H]

The dot-compound does **not** nest, and does **not** combine with propattach. All of these were
generated and all missed:

    floor02.piece1b.propattach03      floor02.piece1b_propattach03
    piece1a.propattach00              floor01.piece1a_propattach00
    floor00.slice1a_propattach00

The grammar is flat: *either* `<shard>` *or* `<component><NN>.<shard>`, then one state suffix.
propattach only ever attaches to a plain (non-dotted) shard.

---

## 2. Hardpoint families on environment models

Existing: `hp_fx_light` (+`hp_fx_light10/11`), `hp_light`, `hp_ladder_top_a..d`,
`hp_ladder_bottom_a..d`, `hp_spawn_a..h`, `hp_civilian`, `sign01..15`, and the large
`hp_snap_*` sub-dialect (`hp_snap_piece1B_oilrig_cranelargeA` — a snap point naming *both* the shard
and the target model; oil-rig modular construction).

### NEW families (all joint-verified, expected-false ≈ 2e-13 each)

| family | members | models | parent | reading |
|---|---|---|---|---|
| **`hp_fx_leaves_green_a..p`** | 16 | 14, **all `*_env_tree*`** | `piece1a_ruin` | leaf-burst FX emitters, fire when the tree breaks |
| **`hp_fx_leaves_palm_a..b`** | 2 | palm models | `piece1a_ruin` | palm variant of the same |
| **`hp_fx_clothesline_a..d`** | 4 | shanty building | `piece1a_ruin` | clothesline FX |
| **`hp_parachute_a..d`** | 4 | 8, **all `*deliverycrate*`/`crateaid`** | `piece1a_pristine` | supply-drop crate chutes |
| **`hp_rope a..f`** (`hp_ropea`…) | 6 | — | — | rope attach series |
| **`bone_wind0..7`** | 8 | **41, all `*_env_*` (trees)** | **`bone_skinned`** | per-branch wind-sway bones |
| **`bone_planta..d`** | 4 | env | — | plant sway |
| **`bone_fana..c`** | 3 | `aloutpost_interior_hq` | `slice1a_pristine` | ceiling fans |

`hp_fx_leaves_green` and `bone_wind0..7` are the strongest results here: 16 and 8 joint members
respectively, each landing exclusively on tree models, each under exactly the parent you would
predict (`bone_wind` and `bone_trunk` were already known children of `bone_skinned`).

**Adjacent finds, outside this department** (reported, not folded into the destruction grammar):
`hp_weapon_a..d` (on `vz_veh_plane_tucano` — pylons), `bone_clamp_a..d` (`global_veh_winch_magnet`),
`bone_chute_a..d` (child of the known `bone_chute`), `bone_ub1..3` (human, under `GlobalSRT`).

---

## 3. Method — why this worked, and the trap it avoids

The governing arithmetic is **E[false] = S·T / 2³²**. A big vocabulary is self-defeating: a chance
hit into a large dictionary *reads* like a plausible name, which destroys the readability witness you
would use to judge it. Two techniques kept the pool narrow while still discovering *unknown* words.

### 3.1 Joint constraints make a big vocabulary safe

A word `W` is only accepted if it hits on **k ≥ 2 independent hashes** — e.g. `W1a_pristine` **and**
`W1a_ruin`; or `hp_W_a`, `hp_W_b`, `hp_W_c`. Expected-false collapses from `|V|·T/2³²` to roughly
`|V|·(T/2³²)^k`. With |V| = 38,169 and k = 3 that is **2e-13**. This is how a 38k vocabulary was
swept for kind words, component words, state suffixes and hardpoint families at *negligible* risk —
and it is why the negatives in §1.1 and §1.5 are trustworthy rather than merely unlucky.

### 3.2 Suffix-peeling: recovering a stem without guessing it

`pandemic_hash_m2` is FNV-1a with a case-fold and a `^0x2A` finalisation, and **it is invertible**
(the prime is odd, so it has a modular inverse). Given a target hash `H` known to end in a literal
suffix `s`, you can peel `s` off backwards and recover the **FNV state of the stem** without knowing
a single character of that stem:

    S_n      = (H * P⁻¹) ^ 0x2A                  -- undo the finalisation
    S_{k-1}  = (S_k * P⁻¹) ^ (byte | 0x20)       -- undo one byte

Peel a small index-suffix grammar (`a..z`, `_a.._z`, `00..99`, `_00.._99`) off every unnamed hash and
**group by the resulting state**. When many targets converge on one state under *different* suffixes,
that state is an authored stem — proven jointly, with no vocabulary involved at all. Contiguity of
the recovered index set (`a,b,c,…,p` with no gaps) is the coherence witness.

This is what exposed a 16-member `a..p` family with **zero** prior knowledge of what it was. Matching
that **one** 32-bit state against a vocabulary then costs only `|V|/2³²` — so a 68-million-stem space
is affordable for a single family (expected-false 0.24 across 15 families), and that is what produced
`hp_fx_leaves_green`.

Sanity-checked against known families before use: the method recovers `hp_spawn_`, `hp_ladder_top_`
and `hp_barreltip_` exactly, and ranks the true stem state top by coherence in each case.

### 3.3 What I tried that FAILED (recorded so nobody repeats it)

- **String-dump mining.** Hashed every token of `ps3-VZ.strings.txt`, `xbox-vz.strings.txt`, the
  Jul-08 devkit PE dump (57k strings), `jul08-vz.strings.txt`, `block_strings.txt`, `wad_vocab.txt`
  — ~4M distinct tokens — against the 8,561 unnamed hashes. Result: **16 "hits", every one garbage**
  (`BDf3O`, `R8A8-8`, `iDazzzxDi`, `l3_7`). Expected noise for that S·T was ≈ 8. **Bone-name strings
  are in no shipped dump, console or devkit.** This is a definitive negative — stop looking.
- **The polluted-vocabulary trap, live.** Running the stem matcher against a 722k-word vocabulary
  built from `wad_vocab.txt` (which is full of binary junk) yielded confident-looking families:
  `hp_fx_bcjb0..9`, `hp_dock_isihiji_*`, `hp_seat_dfdde_*`, `diki_00..07`, `bone_kbmx_a..d`. All
  noise; all *read* like names. Re-running with a clean 38k in-domain vocabulary killed every one and
  left only the structurally-corroborated families. **Vocabulary hygiene is not optional.**
- Chunk-name guesses under `_ruin`: `<shard>_ruin_<NN>`, `<shard>_ruinNN`, `<shard>.<w>`,
  `chunk/debris/rubble/frag/shard/gib<NN>` — **all zero**.
- 3ds-Max/Maya default object names (`Box001`, `Object001`, `pCube1`, …) — **zero**. The artists did
  rename their chunks.
- Are the `_ruin` children asset references? **No** — zero overlap between the 1,155 `_ruin`-child
  hashes and the 30,566 ASET asset hashes. (Though 388 unnamed bones *overall* are ASET hashes,
  against 0.06 expected by chance — a real, separate signal worth someone's time: those nodes are
  prop instances named after the prop asset.)
- Brute force is **not** available here and should not be attempted: 37⁶ candidates against
  T = 7,176 would yield ~4,200 expected false positives.

---

## 4. Model-class map (what the dialect covers)

Of 3,174 rigged models, 2,680 resolve to names. 2,337 are non-vehicle/non-human. Environment
sub-classes: `vz_state_*` (766), `*_bld_*` (429), `*_env_*` (75), `*_att_*` (13), plus walls, ramps,
fences, signs, bridges, oil-rig structures. The shard grammar (`piece`/`slice`) is the universal
destruction spine across **all** of them — from `shanty_bld_house04` to `port_cranegantry01` to
`global_env_treeoak01`. Trees use the same `piece1a_pristine`/`piece1a_ruin` switch as a skyscraper.

---

## 5. The one big thing still UNCRACKED — and exactly where it is

**5,628 unnamed nodes hang under `piece*_ruin` / `slice*_ruin`** (1,155 distinct hashes). These are
the rubble chunks: depth-3 leaves, `in_swit=1`, scattered across the building footprint (verified by
world position — they tile the façade in rows). Every frame I generated for them missed (§3.3).

Suffix-peeling *does* localise them precisely. The largest is fully characterised except for its
name:

| stem state | members | index scheme | parent | models |
|---|---|---|---|---|
| **`0x8038EAF3`** (`_NN` parse: `0x3BF2CD5E`) | **44** | `00 … 43`, 2-digit | **exclusively `piece2a_ruin`** | 22 (`aloutpost_bld_garage01`, `caracas_rampgovernment01`, `caracas_walllong`, `chinaoutpost_bld_hangar01`, …) |
| `0x8CA59F8D`, `0x8C5E672D` | 18 each | `_00 …` | `*_ruin` | — |
| `0x30AB3D30`, `0x8094D357` | 17–18 | `00 …` | `*_ruin` | — |
| `0xD5C3023D` | 17 | `_01 …` | `*_ruin` | — |
| `0x0BF4304F` | 17 | `_1 …` | `*_ruin` | — |

These stem states are **exact 32-bit FNV states of real authored strings**. I verified the stems are
*not* reachable from any known bone/model name plus ≤3 free characters (expected-false 0.05), and not
of the form `prefix + curated-word + '_' + in-domain-word` (a 68M-stem space).

**Next step (high value, cheap):** hand these ~8 stem states to the existing GPU cracker
(`tools/gpu_fast.py` / `bone_gpu_crack.py`) as *single-state* targets. Because each is one 32-bit
value rather than a 7,176-target set, a full 37⁶–37⁷ sweep costs only `S/2³²` ≈ 0.02–0.6 expected
false **per family**, and any hit is immediately cross-checkable against the other 43 members of its
own series. This is the rare case where brute force is statistically legitimate — precisely because
suffix-peeling reduced 5,628 unknowns to ~8 single-state questions.

Also open: `ghw` / `bbd` dot-components (§1.5); the 565 ASET-hash bone nodes (§3.3).

---

## 6. Honesty ledger

- Final harvest: **S = 60,088, T = 7,176, E[false] = 0.100.** So of the **182** new names, I expect
  **~0** to be wrong, and none of the 182 is a lone hit from a large pool — every one belongs to a
  family whose siblings independently confirm it, and 89 of them additionally sit under exactly the
  parent their name predicts.
- **One real false positive was found and is rejected:** `slice2b_propattach08_pristine` collides
  with the *known* name `global_env_multitudes_left`. The known name wins; my candidate is discarded.
  It is quoted here rather than quietly dropped because it is the honest face of the 0.100.
- `ghw*` / `bbd*` are hash-real but **excluded** from the shipped grammar (§1.5) — parent-inconsistent
  and semantically opaque. Do not fold them in without a second witness.
- `hp_fx_leaves_palm_a/b` rests on only **2** joint members (vs 16 for `_green`). Lower confidence;
  it is in the family and on the right models, but I would want `_c`/`_d` before treating it as
  settled.
- `hp_wel_4/5/7` surfaced in a sweep at a statistically real threshold but with a broken index set
  (no `_1/_2/_3/_6`) and no semantics. **Not accepted, not shipped.**
- Everything marked **[I]** in this document is speculation and was never hashed into the corpus.

## 7. Confidence summary

| rule | confidence | basis |
|---|---|---|
| kind ∈ {piece, slice}, closed | **very high** | 38k-word joint sweep, zero new kinds |
| `_pristine` / `_ruin` | **certain** | pre-existing named bones |
| **`_interior`, child of `_pristine`** | **very high** | 8-way joint hit + 137/134/52-model parent corroboration |
| **`propattach<NN>_pristine`** | **very high** | `_ruin` sibling already known; 100/97 models |
| letter axis extends to `p` | **high** | direct hash hits, parent-consistent |
| dot-compound `floor<NN>.` + full state suffix | **high** | 52 joint hits; `floor02.piece1b` pre-known |
| no other component word (wall/roof/corner/…) | **high** | all generated, all missed |
| no nesting of dot-compound / propattach | **high** | all generated, all missed |
| **`hp_fx_leaves_green_a..p`** | **very high** | 16 joint members, all 14 models are trees, parent `piece1a_ruin` |
| **`bone_wind0..7`** | **very high** | 8 joint members, 41 tree models, parent `bone_skinned` |
| `hp_parachute_a..d` | **high** | 4 joint, all supply-crate models, parent `piece1a_pristine` |
| `hp_fx_clothesline_a..d`, `bone_fana..c`, `bone_planta..d`, `hp_ropea..f` | **medium-high** | joint families, plausible parents, small member counts |
| `hp_fx_leaves_palm_a..b` | **medium** | only 2 members |
| `ghw` / `bbd` components | **rejected** | parent-inconsistent |
| rubble-chunk names under `*_ruin` | **UNKNOWN** | localised to ~8 stem states; see §5 |
