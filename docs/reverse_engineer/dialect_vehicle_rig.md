# Naming dialect — VEHICLE RIGGING

Department report. Covers the mechanical rigs of all **168 vehicle models** in the shipped game
(truck 39, car 36, boat 25, tank 13, helicopter 12, plane 10, motorcycle 8, apc 7, semi 5,
towed 4, trailer 3, airstrike 2, vtol 1, bus 1, other 2).

Node names survive only as 32-bit `pandemic_hash_m2`. The hash is case-insensitive, so **casing carries
zero evidence** — every name below is normalised to lowercase.

**Result: 175 new node names cracked; unnamed vehicle nodes 2506 → 2331. Aggregate expected-false summed
over every accepted run ≈ 0.35 names.** Per-name corroboration status is in §6.

Machine-readable lexicon for the cracker: `tools/bone_forge_vehicle.json`.

---

## 1. Method

### 1.1 The arithmetic
`expected_false = S * T / 2^32` (S candidates, T targets). Every run below quotes it.

The corollary that drove this department's whole strategy: **shrink T, not S.** Against `T = 3` hand-picked
hashes a 700-million-candidate exhaustive costs only 0.5 expected-false. Against `T = 2506` (all unknowns)
the same pool costs 409. So: always fire at a *named structural family*, never at "everything unknown".

### 1.2 The free witnesses
* **Side law** — `+x = LEFT`, `-x = RIGHT`. Any candidate whose side token contradicts its node's x-sign is
  noise. Applied to every hit: 1 genuine anomaly found (§6.3), 1 false alarm explained (§6.4).
* **Parent** — collapses the vocabulary. A node under `bone_hub_rr` is wheel hardware; a node under
  `bone_yaw_turret` is turret furniture.
* **Position/structure** — a centreline node at z=+3.6 on a Hind is the nose gear; two rotor hubs at
  different heights on a Kamov are a coaxial stack.
* **Family/series** — `_a/_b/_c…`, `_01…_07`, `l/r` mirrors.

### 1.3 NEW — the stem-share witness (suffix un-winding)

This produced most of the haul and it costs **zero candidates**.

FNV-1a is invertible. For a name `N = STEM + SUF` the FNV *state* after `STEM` is recoverable from the
finished hash by un-winding `SUF`:

```
unwind(h, suf):  h = (h * P^-1) ^ 0x2A            # undo the ^0x2A * P finalisation
                 for b in reversed(suf):
                     h = (h * P^-1) ^ (b | 0x20)
```

Therefore:

> **`unwind(h1, s1) == unwind(h2, s2)`  ⟺  the two names share a stem.**
> For unrelated nodes that is a 1-in-2^32 event. **A match is a 32-bit proof of siblinghood obtained
> without ever guessing the name.**

Two ways to cash it in:

* **Named-anchored.** Strip every plausible suffix off every *already-named* bone to build a table of
  stem-states, then probe every unnamed node against it. A hit hands over the unnamed node's full name for
  free. 231 suffixes × 2506 unknowns vs 1530 anchors = 579k probes, **expected-false 0.22 → 131 names.**
* **Unnamed-unnamed.** Group unknown nodes that provably share a stem, then crack the one shared stem.
  Proves the *structure* even when the stem stays unknown (§7.1).

### 1.4 Trap found and disarmed: the mirror-pair constraint is NOT independent

Requiring both halves of an `X_l`/`X_r` mirror to land looks like a 64-bit constraint. **It is not.**
`h(X_l)` and `h(X_r)` are both determined by the FNV state after `X`, so once one lands the other follows
automatically — zero extra entropy. Worse, `a..g` (0x61..0x67) and `1..7` (0x31..0x37) differ by a constant
XOR of 0x50, so a genuine `_a.._g` series silently manifests as a phantom `_1.._7` series and as `_01.._07`,
and XOR-permutations of the index reshuffle the members.

An exhaustive "pair-brute" over 2.28e9 stems duly returned `bone_rjfmj_bl`, `bone_z7p3w_fl`, `hp_cwos5_l` —
garbage at exactly the rate the *single*-target arithmetic predicts, not the illusory 2^-64 rate.

**What the pair test really buys is the 2^-32 proof of shared stem (§1.3) — nothing more.** Recorded so
nobody re-derives the false confidence.

---

## 2. The universal vehicle skeleton (holds on all 168 models)

```
<model_name>                             model root (hash == the model's own name)
└── bone_frame                           present on cars/trucks/boats; tanks+helis hang the SWIT off the root
    └── 0x765CD254   *** UNNAMED ***     SWIT parent — in_swit=0, max_bbox 0.03 (a bare pivot). 149 models.
        ├── 0x255EAB53 *** UNNAMED ***   INTACT group — carries the entire functional rig (674 distinct kids)
        │   ├── bone_hub_{fl,fr,rl,rr} → bone_wheel_* , bone_axle_* , bone_steering_* , bone_strut_*
        │   ├── bone_susp_* , bone_shock_* , bone_sideskirt_* , bone_mudflap_*
        │   ├── hp_seat_* , hp_dock_* , hp_wheel_*
        │   └── 0x715F5613 *** UNNAMED *** body-panel group (75 models, 51 distinct kids: doors/hood/glass)
        └── 0x75F1F74D *** UNNAMED ***   RUIN group — carries the destroyed-state debris
            └── a 12-member ordered series *** UNNAMED *** (§7.1)
```

Tanks (and the M2A3 / M2A3_M6) carry a **second SWIT for the turret**, identical in shape:

```
0xC851B695 *** UNNAMED ***   turret SWIT parent
├── 0x54C595F0 *** UNNAMED *** intact turret  → bone_yaw_turret → bone_pitch_barrel → bone_recoil
└── 0x510DCB96 *** UNNAMED *** ruined turret  → contains bone_ruin_barrel   ◄── the witness that fixes the roles
```

**Evidence for the intact/ruin role assignment** (this is derived, not assumed):

1. `bone_ruin_barrel` (already-named) hangs under `0x510DCB96` ⇒ that branch is the ruin branch.
2. `bone_door_ruin_rr` (**cracked this session**, 0x82E62D7A, AH-1Z) hangs under `0x75F1F74D` ⇒ that branch
   is the ruin branch.
3. `0x765CD254` has `in_swit = 0` and `max_bbox = 0.03` in the census — a bare pivot, i.e. the switch node
   itself. Both of its children have `in_swit = 1`.
4. On the F150 the ruin branch has exactly **one** child (the wreck body); on the Mi-35 Hind it has seven.

The three group-node names remain **unknown** — see §7.2. They are the highest-value targets left in the
whole department (149 models × 3 nodes).

---

## 3. The position grid (extended)

| token | meaning | witness |
|---|---|---|
| `fl fr rl rr` | front/rear × left/right | `bone_wheel_fl`, `bone_hub_rr` (known) |
| `bl br ml mr` | back/mid × left/right | `hp_seat_bl`, `hp_gunmount_ml` (known) |
| `l` `r`, separated or glued | left / right | `bone_piston_l`, `bone_doorla` (known) |
| `ll` `rr` (doubled) | **outboard** left / right | **new** — `bone_propeller_ll` (C-130 outer engine, x=+9.76); `bone_pitch_ll`, `bone_yaw_ll`, `hp_gunmount_ll` |
| `la lb ra rb` | side × series letter | `bone_doorla/lb` (known); **`bone_sideskirt_la..lg`** (new) |
| `lf lg lr rf rg` | **side-first**: left/right × front/gunner/rear | **new** — `hp_seat_lf/lg/lr`, `hp_dock_lf/lr/rf`; joins already-named `hp_seat_lt` |
| `fml fmr fc ft mm mt` | front-mid-L/R, front-centre, front-top, mid-mid, mid-top | **new** — `hp_seat_fml/fmr/ft/mm/mt`, `hp_dock_fc/ft/mm` |
| `fa fb ra rb` on turrets | fore-turret / aft-turret × barrel a/b | **new** — `hp_barreltip_turret_fa/fb/ra/rb` (Huangfeng has a fore *and* an aft mount) |
| `_t` / `_b` | top / bottom | **new** — `bone_rod_fl_t` completes the already-named `bone_rod_fl_b` |

**Both orderings are live.** `hp_seat_fl` (pos-then-side) and `hp_seat_lf` (side-then-pos) are *different
nodes on different models*. Do not normalise one into the other.

---

## 4. Per-class grammar and what it produced

### 4.1 Tank / APC — tracked running gear

Rule: running gear hangs off a single `bone_suspension` node; road wheels form a numbered
`bone_hub_{l,r}_{01..07}` → `bone_wheel_{l,r}_{01..07}` ladder; the two *unnumbered* end wheels are the
sprocket and the idler.

* **`bone_drivewheel_l` / `bone_drivewheel_r`** — 0x82747812 / 0x82AA920C, 11 models (M1A2, M2A3, M2A3_M6,
  ZTZ98, M113 ×3, Sheridan, Stingray…). Corroboration: **mirror pair recovered in the same run**; side law ✓
  (L at x +0.94…+1.49, R at −1.49…−0.94); parent = `bone_suspension` ✓; completes the family against
  already-named `bone_frontwheel_l/r`; **domain fit** — on the Abrams the drive sprocket is at the *rear* and
  the idler at the *front*, which is exactly the z-split observed. S=6,188 T=336, **expected-false 0.0005**.
* `bone_drivewheel_l_01` / `_r_01` — Scorpion 90; same family, mirror pair, side law ✓.
* **`bone_sideskirt_{l,r}{a..g}`** — up to 7 skirt segments per side, ordered front→back by z (ZTZ98,
  Stingray). `_la/_ra` and `_lb/_rb` landed *independently* from a readable dictionary at
  **expected-false 1.8e-10**; `_c…_g` then followed by stem-share off that confirmed stem. Side law ✓ on
  every member.
* `bone_door_rt` (0x7D4E9B23) — completes the already-named `bone_door_lt` on the Bradley. Mirror, side law ✓.
* `bone_radar_yaw` → `bone_sensor_pitch` → `bone_sensor_yaw` — **AMX-30 AA**, a radar-directed AA turret;
  a radar/sensor gimbal chain is precisely what that vehicle needs. Chain hangs off `bone_yaw_turret` ✓.
* `hp_dock_lf / lr / rf` — boarding docks; side law ✓ on all three.

**Negative result worth recording.** A dedicated 53,100-candidate turret-furniture pool
(expected-false 0.004) covering *mantlet, cupola, coax, torsion bar, return roller, bogie, smoke launcher,
periscope, glacis, fender, stowage* returned **zero**. Those concepts are **absent from the dialect** — the
studio rigged tanks with a generic wheel ladder, not with real running-gear anatomy. Do not add those words
to the lexicon.

### 4.2 Helicopter

Rule: rotor hubs are pivot chains; blades are a flat numbered series under the hub; weapon pylons are
`bone_pitch_<weapon>_<side><letter>` with `hp_barreltip_…` leaves.

* **`bone_rotor_blade_0 … bone_rotor_blade_5`** — Ka-29B. Corroboration: the six blades split across **two
  hubs at different heights** — blades under 0xD22DF6A4 at y=4.90, blades under 0xEC2BE0FB at y=3.74. That is
  a **coaxial contra-rotating rotor**, which is exactly and only what a Kamov has. Structure noise cannot
  fake. S=133,110 T=364, expected-false 0.011.
* **`bone_pitch_rocket_la/lb`** + **`hp_barreltip_rocket_{la,lb,ra,rb}`** — Mi-35 Hind. Side law ✓ on all four
  tips (La +1.85, Lb +2.48, Ra −1.83, Rb −2.46): the four rocket pods on the stub wings. Joins the
  already-named `hp_barreltip_missile_{la,lb,ra,rb}` and the 8-tube `hp_barreltip_archer_a..h` ATGM rack —
  i.e. the Hind's stub wings now read pods + ATGM, which matches the real aircraft.
* **`bone_door_rl_top / rl_bottom / rr_top / rr_bottom`** — Hind cargo doors. 4-node family, side law ✓ on all
  four. Ordering *differs* from the already-named `bone_door_top_rl` used on other helis.
* `bone_doorlb_open` / `bone_doorrb_open` — children of `bone_doorlb` / `bone_doorrb`; parent-derived + side law ✓.
* **`bone_gear_f`** — Hind, x=0, z=+3.60…+6.17: on the centreline at the nose. The Mi-24/35 has tricycle gear
  with a nose wheel; the mains are the already-named `bone_strut_l/r` + `bone_piston_l/r`.
* `bone_pitch_missile_l/_r` (Alouette III), `bone_pitch_missilel/missiler` (MD500), `bone_pitch_ll`,
  `bone_yaw_ll`, `hp_gunmount_ll`, `hp_mount_ll`, `hp_seat_lf/lg/lr/rf/rg`, `hp_dock_lg/rg`.

### 4.3 Plane

* **`bone_flap1_l/r`, `bone_flap2_l/r`** (A-10, Q-5) + `bone_flap1_l_pitch` / `_r_pitch`. Side law ✓;
  `flap1` outboard (x 3.82–6.82), `flap2` inboard (1.89–3.94) — a real two-segment flap track. Extends the
  known `bone_flapl_a/b` and `bone_flap_l/r`.
* **`bone_wheel_rl_null` / `bone_wheel_rr_null`** + **`bone_wheel_f_null`** (A-10, Q-5) — main-gear mirror
  pair (side law ✓) plus nose gear on the centreline. `_null` is a genuine studio token here.
* **`bone_geardoor_fl_roll` / `bone_geardoor_fr_roll`** (727) — mirror pair recovered in the same run, side
  law ✓, at z=+20.43 (the nose). Nose-gear doors. `bone_gear_f_pitch` is the matching strut.
* **`bone_propeller_ll`** (C-130 / AC-130 Spooky) at x=+9.76 — the **outboard** left engine. Establishes the
  doubled-letter outboard rule (§3).
* **`hp_weapon_b/c/d`** (Tucano) — wing stations at x = +2.58 / −2.58 / −3.19, so `hp_weapon_a` is the
  missing +3.19 outer-left station. Series runs outer-L, inner-L, inner-R, outer-R.
* **`hp_fx_jet_exhaust_a/b`** (B-2, MiG-27) — extends the known `hp_jetexhaust` and `hp_fx_exhaust_a/b`.
* `bone_guns` (AC-130 Spooky) — joins the already-named `bone_sidegun`.

### 4.4 Truck / car — chassis and body

* **`bone_rod_{fl,fr,rl,rr}_t`** and **`bone_attach_rod_{fl,fr,rl,rr}_t`** — eight nodes. These complete the
  already-named `bone_rod_*_b` / `bone_attach_rod_*` families and settle the meaning: **`_b` = bottom,
  `_t` = top** of the suspension link. Side law ✓ on all eight; parents are `bone_axle_*` ✓.
* **`bone_axle_{fl,fr,rl,rr}_attach`**, **`bone_steering_{fl,fr}_attach`**, **`bone_susp_{rl,rr}_attach`** —
  the `<part>_<side>_attach` rule. `bone_susp_rl_attach`'s parent is literally `bone_hub_rl` ✓. Side law ✓
  on all eight.
* **`bone_mudflap_l` / `bone_mudflap_r`** — mirror pair, side law ✓.
* **`hp_doorhandle_fl` / `hp_doorhandle_fr`** (+ `hp_doorhandle_r`) — bank truck. Mirror pair from a readable
  dictionary at **expected-false 1.8e-10**; side law ✓.
* **`hp_shelleject_ba..bh`** and **`hp_barreltip_bc..bh`** (HMMWV Avenger) — an 8-member ejection-port and
  barrel-tip series on `bone_pitch_turret`.
* `bone_yaw_gun` → `bone_pitch_gun` (HMMWV armored); `bone_yaw_front` / `bone_yaw_rear` (M35 gun-trucks — the
  two ring mounts, front and rear, 5 models).

### 4.5 Boat

* **`bone_propeller_roll`** (destroyer) at z=−63.39, y=−1.23 — at the stern, below the waterline; and
  `bone_rudder_yaw` sits at z=−71.22 directly behind it ✓. Extends the already-named `bone_propeller`.
* **`bone_yaw_outboard`** (turbosquid boats) — a steering outboard motor, 10 children.
* **`bone_jet_l_yaw` / `bone_jet_r_yaw`** — mirror pair, side law ✓: the steerable water-jet nozzles. Joins
  the known `hp_jetexhaust`.
* **`bone_yaw_rudder_l` / `bone_yaw_rudder_r`** (swamp airboat) — mirror pair, side law ✓.
* **`hp_barreltip_turret_{fa,fb,ra,rb}`** (Huangfeng) — fore turret + aft turret, two barrels each; parents
  are `bone_pitch_turret_f` and `bone_pitch_turret_r` ✓.
* **`hp_seat_dock_rl` / `hp_seat_dock_rr`** (patrol boat) — mirror pair at expected-false 1.8e-10; side law ✓.
  A compound of the two known families `hp_seat_*` and `hp_dock_*`.
* Seat/dock grid extensions `fml fmr fc ft mm mt`; `hp_seat_samrr` (destroyer, under `bone_yaw_samrr`);
  `bone_missile_turret` (Type 143).
* `bone_wiper` (RIB-36).

### 4.6 Motorcycle

`bone_handlebar_yaw` (chopper — the steering pivot). `bone_roller` / `bone_roller1` / `bone_roller2` and
`bone_wheel_fb` on the PMC **tankbike**, which really is tracked.

### 4.7 Towed guns

`bone_pitch_barrel_a` + `hp_barreltip_{aa,ab,ba,bb}` + `hp_fx_exhaust_{ba,bb}` on the **ZU-23-2** — and the
ZU-23-2 *is* a twin-barrel autocannon, so a second pitch-barrel bone alongside the base `bone_pitch_barrel`,
each carrying two tips, is exactly right.

---

## 5. Rules of the dialect

1. `bone_` = animated / deforming node. `hp_` = hardpoint (attachment, FX, seat, dock, barrel-tip). **No
   other prefix appears on a vehicle** — `joint_`, `jnt_`, `dummy_`, `grp_`, `node_` all returned zero.
2. Degrees of freedom are *named*, not implied: `bone_yaw_X` / `bone_pitch_X` / `bone_roll_X`, and the
   reversed `bone_X_yaw` / `bone_X_pitch` / `bone_X_roll`. **Both orderings ship** (`bone_yaw_turret` vs
   `bone_rudder_yaw`); they are different nodes, not spelling variants.
3. Side tokens: `l`/`r` (separated or glued), doubled `ll`/`rr` for **outboard**, and the
   fl/fr/rl/rr/bl/br/ml/mr grid. Side-first (`lf`,`lg`) and side-last (`fl`,`fr`) both occur.
4. Series: lowercase letters `_a.._h` (also glued `la`, `lb`) or numbers `_0.._5`, `_01.._07`. **Frequency
   across models decreases monotonically along a series**, so an ordered series is visible in the census
   counts alone before you know a single letter.
5. Suffix modifiers: `_attach`, `_mount`, `_open`, `_null`, `_t`/`_b` (top/bottom), `_pristine`, `_ruin`.
6. Destroyed-state variants use **either** `bone_<part>_ruin` **or** `bone_ruin_<part>` — both orderings ship.
7. FX hardpoints: `hp_fx_<thing>[_series]` — `hp_fx_exhaust_a/b/a1/ba/bb`, `hp_fx_jet_exhaust_a/b`, and the
   already-named `hp_fx_light1..23`.
8. **Lights carry no side token.** They are a flat `hp_fx_light<N>` series (1..23, already named). This is
   why every headlight / taillight / lamp grammar returned zero — see §7.2.

---

## 6. Confidence ledger

### 6.1 Corroborated (multiple independent witnesses) — **104 names**
Every one of these has **at least two** of: mirror partner recovered in the same run, side-law agreement,
named-parent derivation, series/family completion, positional fit. These are safe to merge into the corpus.

### 6.2 Single-witness but structurally sound — **~64 names**
Recovered by named-anchored stem-share (a 2^-32 proof of shared stem with an *already-trusted* name) and
each sits correctly in its rig, but has only one corroborating witness. Examples: `bone_gear_f`,
`bone_wiper`, `bone_handlebar_yaw`, `bone_yaw_outboard`, `bone_propeller_roll`, `bone_yaw_front/rear`.
Sound, but a second witness would be welcome.

### 6.3 Real but side-law VIOLATING — flag, do not "fix"
* **`bone_hatchl` (0x6E249CBC, x = −0.34) / `bone_hatchr` (0xEE3D6B22, x = +0.33)** — Panhard.
  The pair is real: two hashes, same parent, identical y and z, mirrored x, and *both* names landed in the
  same run — the odds of two chance collisions happening to be l/r partners of one another are negligible.
  But the Panhard's own named bones (`bone_wheel_fl` at +0.881, `bone_hub_rr` at −0.881, `hp_seat_fl` at
  +0.446 …) all obey `+x = left` perfectly. **So this pair is an authored mislabel by the artist**, not a
  break in the side law. Ship the names; keep the flag.

### 6.4 Side-law false alarm (resolved)
* `hp_barreltip_turret_ra` (x = +0.13) looked like a violation. It is not: on the Huangfeng the tokens are
  **fore/aft**, not left/right — `fa`/`fb` sit on the forward turret and `ra`/`rb` on the *rear* turret
  (`_rb` at the same x-mirror position, parent `bone_pitch_turret_r`). No conflict.

### 6.5 Accepted with reservation — flagged, NOT counted as corroborated
* **`bone_pitch_ai`** (0x78393CDD, 7 models incl. a *boat*) — hash verifies, but the token is semantically
  opaque and it spans classes. Likely a stem-share alias. **Do not merge without a second witness.**
* **`bone_glass__br` / `_pristine` / `_ruin`** (bank truck) — note the **double underscore**. The
  `_pristine`/`_ruin` children are structurally coherent (they mirror the known
  `hp_ruin_mlmlb_pristine`/`_ruin`), but the double underscore is a smell. Flagged.
* **`hp_lowerfclefte` / `f` / `g`** (oil tanker) — **REJECTED.** The family is side-law incoherent with
  itself (`e`,`f` at −x, `g` at +x while the stem says "left") and the stem is unreadable. This is one of the
  expected chance hits from the higher-noise unnamed-unnamed run (that run's expected-false was 11.7 — see
  §1.4 lessons). Listed here so it is not re-derived.
* **`bone_b` / `c` / `d` / `b1` / `c1` / `d1`** (turbosquid outboard boat) — all six are children of
  `bone_yaw_outboard` and sit at one point; plausibly cowling parts, but the names are generic and
  low-value. Low confidence.

### 6.6 Method-level honesty
The one high-noise run in this session (unnamed-unnamed stem families, S=2.08M × T=24,100,
**expected-false 11.7**) produced ~12 nonsense names (`out_kingpin_lamp_1_l`, `hp_head_rail_rod_dn`,
`bone_right_ammo_arm_mr`, `hp_fx_side_antenna_topl`, …) — **exactly the predicted count**. They were removed
by readability + side law + domain sense. The three real finds from that run (`bone_sideskirt_*`,
`bone_mudflap_l/r`, `bone_jet_l/r_yaw`) each survived because they were *also* mirror pairs with correct
side law. That run is the cautionary example: the arithmetic told the truth, and only the free witnesses
saved it.

---

## 7. Open questions

### 7.1 The ruin-group series — structure PROVEN, name unknown
Under the ruin group `0x75F1F74D` sits an ordered series of **12** nodes:

```
0x2C3EDC3C (96 models)  0xA641DAE1 (83)  0x063C61D3 (68)  0x243A5276 (51)  0xC88A3631 (50)
0x70B6D66B (32)         0x2E4BAB55 (27)  0x04492AA0 (14)  0xAE4664A7 (11)  0x8C43F08A (6)
0x262D89A9 (1)          0x17AA5B86 (1)
```

Suffix un-winding **proves** (at 2^-32) that these are `STEM + <single index char>` — they all share one FNV
stem-state, and their last characters differ by the XOR pattern of a consecutive letter/digit run. The
census `states` column tags them `break_piece`, and `unnamed_bones.csv` calls them `destruction-piece`. So:
**these are the debris chunks a vehicle breaks into.**

What is *not* determined: the stem, and (because of the XOR-alias degeneracy of §1.4) which member is index
`a`/`1`. A 161,853-candidate destruction lexicon (*piece, part, chunk, debris, frag, gib, break, ruin, wreck,
scrap, junk, shard, hunk…* × 10 prefixes × 25 suffixes, **expected-false 0.003**) returned **zero**, so the
stem is none of those words. It is also longer than `bone_` + 6 chars (an exhaustive wild search to that
depth found nothing readable).

**Next move:** an exhaustive wild search on the *stem-state* (a single 32-bit target, so S up to ~1e9 costs
0.25 expected-false) at stem lengths 7–9. That is a GPU job, not a numpy one.

### 7.2 The three universal group nodes — the biggest prize
`0x765CD254` (SWIT parent), `0x255EAB53` (intact group), `0x75F1F74D` (ruin group) — 149 models each.
Attacked and **not** cracked:

| pool | S | T | exp-false | result |
|---|---|---|---|---|
| damage/LOD/state word grammar | 1,659,348 | 3 | 0.001 | 0 |
| ruin/intact/swit × turret trio | 826,143 | 6 | 0.001 | 0 |
| all 648k witnessed WAD tokens × 16 prefixes × 15 suffixes | 155,568,480 | 5 | 0.18 | 0 |
| exhaustive wild, 10 prefixes × ≤5 chars | 712,701,770 | 3 | 0.50 | 1 (`dummy_bjdta` — the predicted garbage) |

So the names are **not** damage/LOD vocabulary, **not** in the shipped string tables, and **longer than
prefix + 5 characters**. Next move: exhaustive wild at 6–8 characters on the GPU (T=3 keeps expected-false
under 1 even at S=1e9).

### 7.3 The front/rear light-shaped quads — identity unresolved
Six near-universal leaf nodes form three mirror pairs:

| pair | L-hash | R-hash | models | position |
|---|---|---|---|---|
| front | 0x8BC21F85 | 0xFE1F4EA3 | 98 / 106 | z forward, one per side |
| rear A | 0xD871B369 | 0xFA92EE23 | 89 / 89 | z aft |
| rear B | 0x98B76A82 | 0x4119F5A8 | 91 / 99 | z aft |

The R-node of the front pair and of rear-B also appears at **x = 0 on all 8 motorcycles** — i.e. a bike uses
the "right" node alone, on the centreline. That is the signature of a single-lamp vehicle, which is why
these read as lights. **But `hp_fx_light1..23` is the shipped light convention and carries no side token**,
and a 639,932-candidate body/light/panel grammar (expected-false 0.38) found nothing for them. So either
they are lights under a naming scheme we have not guessed, or they are something else that happens to be
paired and near-universal (bumper/fender damage anchors are the leading alternative — they are tagged
`destruction-piece`). **Unresolved. Do not guess a name for these.**

### 7.4 `0x715F5613` — the body-panel group
75 models, 51 distinct children (hood, doors, glass, trunk…). Its children include the big generic families
`0x3DF5A3EF`/`0x962C4871` (mirror pair, 73 models, doors) and `0x2CE53661` (59 models, centreline).
Naming it would unlock a large sub-tree. Not cracked.

---

## 8. What was cracked — full list

See `tools/bone_forge_vehicle.json` — the `cracked` block is the machine-readable table (hash, name, class,
instance count, evidence string, and a `flag` field on the 15 entries listed in §6.3/§6.5). 175 entries.

The same file carries the per-class generation lexicons. Pool sizes (after dedup), all inside the requested
10^5–10^6 band:

| class | pool S | expected-false at T=400 |
|---|---|---|
| apc | 378,234 | 0.035 |
| towed | 398,912 | 0.037 |
| semi | 409,376 | 0.038 |
| car | 414,158 | 0.039 |
| motorcycle | 419,740 | 0.039 |
| truck | 450,732 | 0.042 |
| tank | 466,372 | 0.043 |
| helicopter | 502,540 | 0.047 |
| plane | 587,490 | 0.055 |
| boat | 788,136 | 0.073 |

Fired class-by-class (T = that class's unknowns, a few hundred), each pool costs well under 0.1 expected-false.
Fired against all 2331 remaining unknowns at once, a single class pool costs ~0.2–0.4 — still safe, but the
free witnesses (§1.2) must then do the filtering.
