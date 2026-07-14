# prediction_C — node-name predictions (STUDY ID = C)

Blind study. I am reasoning as a Pandemic technical artist who rigged these vehicles in XSI and
named these nodes by hand. Hash primitive: `tools/fnv.py m2()` (verified self-test passes; the M2
corpus uses the `^0x2A` finalize — `bone_root`=0xFAEFB386, `pristine`=0x86DE6639 confirm it, so the
Mercs1 "no-finalize" caveat does NOT apply to these targets).

## Headline

- **Hash-confirmed name cracks: 0.** Every rotor/tail target resisted vocabulary sweeps
  (~150k rotor-domain strings), full-corpus named-anchored stem-share (738k anchors × suffixes ≤3),
  LOD-`geometry` convention, and exhaustive short brute (`bone_`+≤5, `hp_`+≤5, `bone_rotor_`+≤4,
  bare+≤6 — i.e. every `bone_` name up to 10 characters). None matched.
- **1 naming-SCHEME confirmation (structural, hash-proven):** the three universal vehicle group
  nodes are `<STEM>` / `<STEM>_pristine` / `<STEM>_ruin` — I re-derived the shared FNV stem-state
  and proved the suffixes are exactly `_pristine` and `_ruin` (not `_intact`/`_damage`/etc). STEM
  string itself still uncracked.
- The high value I can deliver is **structure**: I fully reconstructed the shared helicopter rotor
  rig template and pinned each target's mechanical role and its named-equivalent on simpler models.
  Predictions below are committed best-guesses, honestly labelled by confidence.

---

## 1. The rotor rig is a SHARED TEMPLATE — proven, and it re-writes the target interpretation

All 19 mi35hind rotor targets are generic template nodes reused across 12–18 rotor/prop craft
(`vz_veh_helicopter_mi35hind`, `_solano`, `al_veh_helicopter_ah1z`, `mh53pavelow`, `wz10` ×2,
`uh1huey` ×2, `alouetteiii` ×3, `md500`, `ka29b`, **`vz_veh_plane_tucano`**). I resolved every
model hash and dumped the rigs of `ka29b` (which carries the named `bone_rotor_blade_0..5`),
`oc_wz10` (simplest rig, has named `bone_rotor` + `bone_tailrotor`), `uh1huey`, and `tucano`.

**Decisive cross-model parenting evidence** (a target's parent on the *simplified* rigs is a
NAMED node):

| target | parent on mi35hind | parent on simplified rig(s) | ⇒ role |
|---|---|---|---|
| T38 `0x4CC628FA` | T37 `0xD06B9499` | **`bone_rotor`** (wz10, 2 planes), **`bone_propeller`** (tucano) | main-rotor display leaf |
| T39 `0x2C9F4CEC` | T37 | **`bone_rotor`** (wz10, planes) | main-rotor display leaf |
| T45 `0x05F65F7E` | T44 `0x59748439` | **`bone_tailrotor`** (wz10, wz10, solano, 2 planes) | tail-rotor display leaf |
| T46 `0xC0657B1C` | T44 | **`bone_tailrotor`** | tail-rotor display leaf |
| T30 `0xA998B636` | T29 `0xB366B8C7` | **`bone_rotor`** (ch_wz10, solano) | pivot directly under the rotor node |

On the SIMPLEST rig (`oc_wz10`, 39 nodes) the entire main rotor is just:
`bone_rotor → {T38, T39}` and the tail is `bone_tailrotor → {T45, T46}`. So **T38/T39 are the two
display meshes of the main rotor, and T45/T46 are the two display meshes of the tail rotor** — the
classic slow-blades-mesh + fast-blur-disc pair that the engine swaps by RPM. The same T38 node hangs
under `bone_propeller` on the Tucano, so its name is **rotor/prop-neutral** (it is one fixed string
reused under `bone_rotor`, `bone_tailrotor`-family, and `bone_propeller`).

**mi35hind expands that same template into an articulated / destructible tower.** Mapped tree:

```
INTACT (0x255EAB53)
├─ T29 0xB366B8C7  (0,4.38,0)  ── main-rotor ROOT  [occupies bone_rotor's slot; break_piece]
│  └─ T30 0xA998B636           ── rotor pivot        [child of bone_rotor on ch_wz10/solano]
│     ├─ T31 0x8F96690F        ── BLADE/break group (bbox 18) → the 5 Hind blades:
│     │     T32 0x7AE04F5B (+5.70,+4.63,+1.73)   blade
│     │     T33 0x78ED1828 (+0.17,+4.38,+6.47)   blade
│     │     T34 0x62EF341D (-6.10,+4.38,+2.10)   blade
│     │     T35 0xE0E7ABB2 (-3.43,+4.38,-4.63)   blade  [junk name Y7EzN3L7 = failed brute; it is a blade]
│     │     T36 0x02EA1FCF (+3.38,+4.63,-4.73)   blade
│     └─ T37 0xD06B9499        ── INTACT-rotor group (bbox 20) → T38, T39 (the display meshes)
│
├─ T40 0x1D4F731C  (0.65,4.77,-11.23) ── tail-rotor ROOT/pivot
│  ├─ T41 0x8EC23BD5           ── tail sub-group → T42 0xAE7F16A4, T176 0x76943CCF
│  └─ T43 0x17664A2B           ── tail INTACT group → T44 0x59748439 [occupies bone_tailrotor's slot]
│        └─ T44 → T45 0x05F65F7E, T46 0xC0657B1C  (tail display meshes)
```

Census `states` tags corroborate a **two-representation** rotor: the `T29→T30→T31→blades` chain and
`T40/T41` are tagged `break_piece` (the destructible/articulated version that shatters), while the
`T37→{T38,T39}` and `T43→T44→{T45,T46}` branches are tagged `intact` (the cheap always-on display
meshes). On `ka29b` the *named* `bone_rotor_blade_0..5` hang under two separate coaxial hubs
(`0xD22DF6A4` y4.90, `0xEC2BE0FB` y3.74) — a PARALLEL set to T31's children, which is why the Hind's
blades (T32–36) have different hashes than `bone_rotor_blade_*` and are therefore a different name.

**Consequence for the brief's framing:** nodes 37–39 are NOT a "swashplate/blur disc" second hub —
they are the *intact display rotor* that on simple rigs hangs straight off `bone_rotor`. And T29 is
NOT merely a mast column; it is the whole main rotor's root, the direct synonym-slot of `bone_rotor`.

---

## 2. Predictions per target (all UNCONFIRMED by hash — committed best-guess strings)

Confidence key: **[role: high]** = mechanical role hash-proven by cross-model parenting; the NAME is
my best single guess. I deliberately do **not** fan out into long candidate lists — per the corpus
rule "a wrong name is worse than an unknown one", I give one committed string + at most two backups.

### A. Main rotor

- **T29 `0xB366B8C7`** — main-rotor root, same slot as `bone_rotor`. **Predict: `bone_rotor_main`**
  (backups `bone_mainrotor`, `bone_rotor_yaw`). Role: high. Name: low.
- **T30 `0xA998B636`** — pivot one level under the rotor node (its parent is literally `bone_rotor`
  on ch_wz10/solano). A bare pivot (bbox 0.03). **Predict: `bone_rotor_spin`** (backups
  `bone_rotor_hub`, `bone_rotor_pivot`). Role: high. Name: low.
- **T31 `0x8F96690F`** — the blade/break group holding the 5 Hind blades (bbox 18). **Predict:
  `bone_rotor_blades`** (backups `bone_blade_group`, `bone_rotor_break`). Role: high. Name: low.
- **T32/T33/T34/T35/T36 (`0x7AE04F5B`,`0x78ED1828`,`0x62EF341D`,`0xE0E7ABB2`,`0x02EA1FCF`)** — the
  5 main-rotor blades. `bone_rotor_blade_0..5` is **RULED OUT** (those exact hashes are the ka29b's).
  The mi35 blades use a different (unwitnessed) stem. **Predict a 0-based flat series
  `bone_blade_0 … bone_blade_4`** mapped by radial angle (backups `bone_mainblade_0..4`,
  `bone_rotor_blade_a..e`). T35's shipped name `Y7EzN3L7` is confirmed brute-force junk — it is a
  blade. Role: high (all five are radiating leaf blades). Name: low.

### B. Intact display rotor (the two leaves that hang under `bone_rotor` on simple rigs)

- **T37 `0xD06B9499`** — the intact-rotor group. **Predict: `bone_rotor_disc`** (backups
  `bone_rotor_geo`, `bone_rotor_display`). Role: high. Name: low.
- **T38 `0x4CC628FA`** — rotor/prop-neutral display leaf (also a child of `bone_propeller`). Most
  likely the fast-spin blur disc. **Predict: `bone_blur`** (backups `bone_rotor_blur`, `bone_disc`).
  NOTE: `bone_rotor_blur/_disc/_stop/_spin/_moving/_still` are all hash-RULED-OUT for this node, so
  the string is neutral and outside standard rotor vocabulary. Role: high. Name: very low.
- **T39 `0x2C9F4CEC`** — the second display leaf (slow-blade mesh). **Predict: `bone_blades`**
  (backups `bone_rotor_slow`, `bone_disc2`). Role: high. Name: very low.

### C. Tail rotor (z = −10…−11)

- **T40 `0x1D4F731C`** — tail-rotor root/pivot. **Predict: `bone_tailrotor`** — but that exact hash
  is `0x7EC75420`, so this is the *unnamed template synonym*; **Predict: `bone_tailrotor_main`**
  (backups `bone_tailrotor_yaw`, `bone_tailrotor_spin`). Role: high. Name: low.
- **T41 `0x8EC23BD5`** — tail sub-group. **Predict: `bone_tailrotor_blades`** (backup
  `bone_tailblade_group`). Role: high. Name: low.
- **T42 `0xAE7F16A4`** — leaf under T41, a tail-rotor blade/element. **Predict: `bone_tailblade_0`**
  (backup `bone_tailrotor_blade_0`). Role: med. Name: low.
- **T43 `0x17664A2B`** — tail INTACT group (parent of T44, which is `bone_tailrotor`'s slot).
  **Predict: `bone_tailrotor_disc`** (backup `bone_tailrotor_geo`). Role: high. Name: low.
- **T44 `0x59748439`** — occupies `bone_tailrotor`'s slot (T45/T46 hang off `bone_tailrotor` on 5
  simplified rigs). **Predict: `bone_tailrotor_main`** or the same neutral node as T40's child. Role:
  high. Name: low.
- **T45 `0x05F65F7E` / T46 `0xC0657B1C`** — the two tail-rotor display leaves (direct children of
  `bone_tailrotor`). By analogy to T38/T39: **Predict `bone_tailblur` / `bone_tailblades`** (backups
  `bone_tailrotor_blur` / `_disc` — but note the corresponding main-rotor `bone_rotor_*` forms were
  ruled out, so these tail forms are likely ruled out too). Role: high. Name: very low.
- **T176 `0x76943CCF`** — leaf under T41 at (0.11, 3.24, −9.97), FORWARD of and BELOW the tail-rotor
  hub; on ka29b it is a point-marker (bbox 0.03). Position + point-size read as an FX/attach marker
  on the tail-rotor gearbox, not a bone. **Predict: `hp_fx_exhaust_c`** or `bone_tailrotor_gearbox`.
  Role: med. Name: very low.

### D. Universal vehicle destruction group (SCHEME hash-CONFIRMED, STEM uncracked)

Proven this session (recomputed, not assumed): the three nodes share one FNV stem-state
`0xE141A8F6`, and:

```
0x765CD254 = m2(STEM)              (SWIT parent, bare pivot bbox 0.03)
0x255EAB53 = m2(STEM + "_pristine")  (INTACT branch)
0x75F1F74D = m2(STEM + "_ruin")      (RUIN branch)
```

The suffixes are exactly **`_pristine`** and **`_ruin`** (verified: `_intact`,`_damage`,`_broken`,
`_wreck`,`_destroyed` etc. do NOT reproduce the shared stem-state; only `_pristine`/`_ruin` do). So
the whole scheme is confirmed; only the ≥9-char STEM word is missing.

STEM attacked this session and still **not** cracked:
- full rainbow table (865k strings) — none hash to `0x765CD254` / state `0xE141A8F6`;
- ~28k curated `{'',L1_,L2_,L3_,L12_,…} × {body,chassis,hull,vehicle,destructible,damage,break,
  panel,section,segment,shatter,fracture,…} × {'',_geometry,_geo,_group,_mesh,_model}` — zero.

Per the Mercs1 findings the group is historically an `L1_*_geometry` null and `body_geometry` /
`chassis_geometry` are already ruled out. My committed guesses for STEM, in rank order (all
UNCONFIRMED): **`L1_body_ruin_geometry`**, **`L1_vehicle_geometry`**, **`destructiblegeometry`**.
The right next move is a GPU exhaustive on the single 32-bit stem-state `0xE141A8F6` at
`L1_`+6…8 alphabet chars (T=1 ⇒ expected-false <0.25 even at S=1e9) — a numpy CPU pass cannot reach
that depth.

---

## 3. Negative results (so nobody re-runs them)

- Rotor/blur/disc/mast/hub/blade/prop/stop/swash/spinner/fan/wash vocabulary, all
  `bone_`/`hp_`/`L#_`/`k_` prefixes × DOF inserts × ~90 suffixes (~150k strings) vs the 19 rotor
  targets + the two ka29b coaxial hubs: **0 hits** (expected-false 3e-4).
- Named-anchored stem-share: unwind all 19 targets by every suffix ≤3 chars against the full 738k
  known-name FNV-state index: only ~170 expected-false garbage strings, **0 real** — so none of
  these nodes is `<any known name> + short suffix`.
- Parent-derived test (`bone_rotor`/`bone_tailrotor`/`bone_propeller` + suffix) via unwind: **0**
  real (one noise artifact `bone_bluron`). The display leaves are NOT parent-name-derived.
- Exhaustive short brute: every `bone_`+≤5, `hp_`+≤5, `bone_rotor_`+≤4, `bone_tailrotor_`+≤4,
  `bone_prop_`+≤4, and bare+≤6 string vs all targets: **0** real (only expected bare-6-char noise).
  ⇒ the rotor template names are >10 chars and/or use out-of-vocabulary compounds.
- Destruction STEM: rainbow 865k + 28k curated L1_/geometry/destruction vocab: **0**.

## 4. Confirmation count

- **Exact name cracks (hash-confirmed): 0.**
- **Naming-scheme confirmations (hash-proven structure): 1** — the universal destruction group is
  `<STEM>` / `<STEM>_pristine` / `<STEM>_ruin`, stem-state `0xE141A8F6`, suffixes verified.
- **Mechanical-role confirmations (cross-model parenting, hash-anchored to named nodes): 15** — every
  rotor/tail target's role is pinned by a named parent/sibling on a simplified rig (§1 table + tree),
  even though the exact strings remain unknown.

Confidence summary: I am highly confident in the *structure* (which node is which part, and which
named node it stands in for). I am NOT confident in any exact rotor string — the shared-template
vocabulary sits outside every wordlist and short-brute I could run here, and I decline to assert
fabricated names. The single most crackable remaining target is the destruction STEM: a proven
single 32-bit preimage that only needs a GPU wild-search at `L1_`+6–8 chars.
