# Prediction B — mi35hind rotor rig + universal vehicle destruction group

**Study ID: B (blind).** Author persona: Pandemic technical artist / rigger, 2005–2008, Mercs 1 → Mercs 2,
Softimage XSI + ModelMunge. Predictions are the exact strings I believe I typed. Hash primitive:
`tools/fnv.py::m2` (FNV-1a, `|0x20` case-fold, `^0x2A` finalize). Every claim below was run against the
live census (`bone_skeleton.csv`), the rainbow table, and an 865k-string vocabulary.

---

## Bottom line up front

**New hash-confirmed NAME strings: 0.** Every obvious and most non-obvious candidate was tested and the
recognition wall held — these nodes are named with **studio-internal, ≥6-character, non-dictionary tokens**,
exactly as the deform-rig and destruction departments already concluded for their hardest targets. A wrong
name is worse than an unknown one, so I do not assert any string as a crack.

**But the investigation is NOT empty — I proved the STRUCTURE cold (each at the 2⁻³² level):**

| # | Confirmed structural fact | Value |
|---|---|---|
| C1 | The 3 universal group nodes are literally `STEM` / `STEM_pristine` / `STEM_ruin`, one shared FNV stem-state **`0xE141A8F6`**, `m2(STEM)=0x765CD254`. | Independently re-derived the dossier claim; gives the GPU a single 32-bit target. |
| C2 | mi35hind main-rotor "blades" (nodes 32–36) are a **numbered series `STEM_A+<idx>`**, stem-state **`0xB16B92D4`**. | Zero-cost suffix-peel proof. Hind populates 5 of a 6-slot (0..5) generic template. |
| C3 | Nodes 170–175 ("Set B") are a **second numbered series**, stem-state **`0x36C3CFD7`**, co-located pair-wise with Set A. | Set A (in_swit=1) vs Set B (in_swit=0) = a two-state (pristine/blur-or-ruin) blade pair. |
| C4 | **Ka-29 Rosetta Stone**: the real `bone_rotor_blade_0..5` live under *deeper* sub-hubs; the Hind's hub-child nodes are a **separate shared rig-template family**, NOT `bone_rotor_blade`. | Explains why the Hind blades are "unnamed": they were never `bone_rotor_blade`. |
| C5 | The mast column (29→30→31/37) and tail chain (40–46,176) are the **shared helicopter rig template** carried by all 15 rotary models — NOT `bone_rotor`/`bone_tailrotor` (those two names live on only 5 *other* models). | The Hind belongs to the "detailed-rotor" fleet with its own template dialect. |

The lone census "name" on a target, `Y7EzN3L7` on node 35 (0xE0E7ABB2), is a prior failed brute-force
artifact (verified: it does hash to the node). **It is junk — reject it.** Node 35 is main-rotor blade
index 0.

---

## How the Hind rotor is actually built (from `bone_skeleton.csv` + Ka-29 cross-model diff)

```
0x255EAB53  INTACT group
└─ 0xB366B8C7  [29]  y4.38   MAIN-ROTOR mast head        (12 models: all attack/utility helis)
   └─ 0xA998B636 [30]  y4.38                              (15 models)
      ├─ 0x8F96690F [31]  y4.38  ROTOR HUB (blade parent) (15 models, in_swit)
      │   ├─ SET A  nodes 32,33,34,35,36  radius ~6, in_swit=1   → 5 MAIN BLADES  (stem 0xB16B92D4)
      │   └─ SET B  nodes 170..175        radius 0..4, in_swit=0 → paired blade variant (stem 0x36C3CFD7)
      └─ 0xD06B9499 [37]  y4.38  2nd rotor element        (15 models, in_swit)
          ├─ 0x4CC628FA [38] leaf, center  (18 models — incl. vz_veh_plane_tucano's PROPELLER!)
          └─ 0x2C9F4CEC [39] leaf, center  (17 models)
0x255EAB53
└─ 0x1D4F731C [40]  z-11.2  TAIL-ROTOR assembly head     (15 models)
   ├─ 0x8EC23BD5 [41] ─ 0xAE7F16A4 [42] leaf ; 0x76943CCF [176] (0.11,3.24,-9.97)
   └─ 0x17664A2B [43] ─ 0x59748439 [44] ─ 0x05F65F7E [45] leaf / 0xC0657B1C [46] leaf
```

Two facts drive the whole reading:
- **Node 38 (0x4CC628FA) is shared with `vz_veh_plane_tucano`, a turboprop.** So node 38 is the *generic
  spinning element* of the rotor/prop rig — one template node reused for a heli rotor disc and an aeroplane
  propeller. Its name is a rotation-agnostic template token, not "blade".
- **On the coaxial Ka-29, nodes 0x8F96690F and 0xD06B9499 are the two contra-rotating rotors.** Mercs 1's
  helicopter code named exactly this pair `rotor` / `crotor`. That is the semantic role of nodes 31 vs 37.

---

## PRIORITY A — MAIN ROTOR (hub column 29,30,31,37,38,39 + 5 blades 32–36)

### The 5 blades (32,33,34,35,36) — CONFIRMED numbered series, name unconfirmed

Suffix-peel proves all five share stem-state **`0xB16B92D4`** under a single glued index character. Read as
digits, the Hind occupies indices **0,1,2,3,5** of a 6-slot template (index 4 is the 6th blade other helis
carry):

| node | hash | blade idx | world pos |
|---|---|---|---|
| 35 | `0xE0E7ABB2` | **0** | (−3.43, 4.38, −4.63) |
| 36 | `0x02EA1FCF` | **1** | (+3.38, 4.63, −4.73) |
| 33 | `0x78ED1828` | **2** | (+0.17, 4.38, +6.47) |
| 34 | `0x62EF341D` | **3** | (−6.10, 4.38, +2.10) |
| 32 | `0x7AE04F5B` | **5** | (+5.70, 4.63, +1.73) |

(The digit-vs-letter ambiguity of §1.4 vehicle-rig applies; a letter parametrization is equally consistent.
The *series* is proven; the index alphabet is not.)

**Ruled out (hash-tested, hard exclusions):** `bone_rotor_blade_N` (that string is 0xE6810AC0…; it is the
Ka-29's, a different node), `bone_blade`, `bone_rotorblade`, `bone_paddle`, `bone_vane`, `bone_grip`,
`bone_rotorarm`, `bone_pitch_blade`, `bone_feather`, `bone_droop`, `bone_flex`, `bone_blur` (all as stems);
the entire 865k vocabulary as a stem; every `bone_`/bare/`rotor` stem of core ≤ 5 chars. The stem is ≥ 6 chars
and non-dictionary.

**My committed predictions (unconfirmed — top 3, best first):**
1. `bone_rotor_blade_0 … _5` — my *intended* convention (it is what I typed on the Ka-29). If another artist
   built this template first, mine is the sibling spelling. **Does not hash-match here** — so most likely:
2. `bone_blade_0 … _5` / `bone_rotorb_0…` — a terser template variant (the template author dropped the middle
   word). Glued index, no separator, matching the proven single-char scheme.
3. A studio code for the *blade-pitch* bone, e.g. `bone_bladepitch0…` or `bone_pitch0…` — because these nodes
   sit at blade root radius and the actual blade *geometry* is the deeper Ka-style child.

### Hub / mast column (29, 30, 31, 37, 38, 39) — parent chain, individual names

These are a DOF/assembly chain, not a series (no shared single-char stem). Roles from geometry + the Ka-29
coaxial diff + the tucano-prop share:

| node | hash | role (high confidence) | committed name prediction (unconfirmed) |
|---|---|---|---|
| 29 | `0xB366B8C7` | mast head / whole main-rotor group | `bone_rotor` → else `bone_mast` / `bone_rotor_main` |
| 30 | `0xA998B636` | rotor drive node (spins) | `bone_yaw_rotor` / `bone_rotor_spin` |
| 31 | `0x8F96690F` | **blade hub** (upper/main rotor on Ka) | `bone_rotor_hub` / `bone_hub` / `bone_rotor` |
| 37 | `0xD06B9499` | **2nd/coaxial rotor** (the Ka's `crotor`) | `bone_crotor` / `bone_rotor_lower` / `bone_rotor2` |
| 38 | `0x4CC628FA` | generic spinning disc (heli **and** prop-plane) | `bone_prop` / `bone_rotordisc` / `bone_blur` |
| 39 | `0x2C9F4CEC` | co-located twin of 38 (blur/pristine pair) | `bone_rotordisc_blur` / paired-state of 38 |

**Ruled out for every one of 29,30,31,37,38,39:** the full Mercs1+Mercs2 rotor lexicon
(`rotor,crotor,tailrotor,mainrotor,hub,mast,shaft,head,disc,swashplate,spinner,blur,stop,fenestron,pylon,
collective,fan,gearbox…`) × DOF (`yaw/pitch/roll/spin/rotate`) × sides × `bone_/bare/k_` — **69,513
candidates, zero hits**. Node 38 despite the strong prop-plane semantic anchor did **not** match `prop`,
`rotor`, `blur`, `spin`, or `disc`. The template words are non-obvious.

---

## PRIORITY B — TAIL ROTOR (40,41,42,43,44,45,46,176) at z≈−11

Parent chain, no shared-stem series. All at (0.65, 4.77, −11.23) except **176 at (0.11, 3.24, −9.97)** =
lower and forward → the tail-rotor **gearbox / pitch pivot**, not a blade. Same template as the main rotor's
(the tail head `0x1D4F731C` and `0x8EC23BD5`/`0x17664A2B` also appear on the Ka-29's rotor), so it is
governed by the same unknown template vocabulary.

**Committed predictions (unconfirmed):**
- 40 `0x1D4F731C` (assembly head): `bone_tailrotor` → else `bone_tail_rotor` / `bone_yaw_tailrotor`
- 41 `0x8EC23BD5` / 43 `0x17664A2B` (two sub-branches): the tail-rotor **spin** + **pitch** nodes,
  `bone_tailrotor_spin` / `bone_tailrotor_pitch` (or a `rotor`/`crotor`-style pair).
- 42,45,46 (leaves): tail-rotor **blades** — likely a short series `bone_tailrotor_blade_0…` in intent, but
  each is a lone leaf here so no series witness.
- 176 `0x76943CCF`: `bone_tailrotor_gearbox` / `bone_tailrotor_hub`.

**Ruled out:** the same 69,513-candidate tail/rotor×DOF×side sweep — zero hits. `bone_tailrotor` (0x7EC75420)
is real but lives on 5 *other* helis, not this fleet.

---

## PRIORITY C — the 3 universal vehicle destruction group nodes (172 vehicles)

**CONFIRMED (C1), independently re-derived at 2⁻³²:**

```
0x765CD254  = m2( STEM )              SWIT group node
0x255EAB53  = m2( STEM + "_pristine" ) INTACT branch      ─┐ all three share
0x75F1F74D  = m2( STEM + "_ruin" )     RUIN branch         ─┘ FNV stem-state 0xE141A8F6
```

So the ONE thing to crack is `STEM`. **Facts pinned:** identical on all 172 vehicles ⇒ a *fixed template
name*, **not** model-root-derived (ruled out the Mercs1 §3c per-model-root hypothesis — a per-model stem
could not be byte-identical across a Veyron, a Huey and an M1A2). It is ≥ 9 chars, non-dictionary.

**Newly ruled out this session (adds to the dossier's exclusions):**
- `STEM = X + "_geometry"` (and `geometry/_geo/_geom/_mesh/_group/_body/_ruin_geometry`) for **any X ≤ 5
  chars** — GPU-style numpy brute, single 32-bit target, negligible expected-false. **Zero.** So if it is a
  `_geometry` group name, the prefix is ≥ 6 chars (e.g. an `L1_<≥6>_geometry`).
- A 222,836-candidate `L{1,2,3,12,123}_ ×  {body,chassis,frame,hull,vehicle,destruct,damage,break,state,
  switch,group,static…} × {_geometry,_group,_switch,_state,_mesh…}` cross-product — **zero**.
- Any `bone_/bare/rotor/hp_/k_` stem of core ≤ 5 for stem-state 0xE141A8F6 — **zero**.

**My committed prediction (unconfirmed, best first):** it is the Mercs 2 heir of Mercs 1's destructible body
group `L1_chassis_geometry`/`L1_body_geometry` (both hash-excluded), i.e. a fixed `L1_<word>_geometry` template
group with a ≥6-char body word I cannot recover by dictionary — my single best type-it-out guess is
`L1_body_geometry` in *spirit*; failing that a bare studio token like `destructible`. **Neither hashes to
0x765CD254**, so I flag this Priority-C name as genuinely unrecovered.

**Decisive next move (unchanged, now with the exact target):** hand the single 32-bit forward stem-state
**`0xE141A8F6`** (equivalently `m2(STEM)=0x765CD254`) to the GPU wild-cracker for lengths 9–13, prefix-free.
One target ⇒ S≈10⁹ costs ~0.23 expected-false. Any hit is instantly triple-checkable (it must also produce
`_pristine`→0x255EAB53 and `_ruin`→0x75F1F74D). The same applies to the two blade stem-states
**`0xB16B92D4`** (main blades) and **`0x36C3CFD7`** (Set B).

---

## Confidence ledger

- **Confirmed (2⁻³²):** C1–C5 above — the group-node stem-share, the two blade series and their exact
  stem-states, the Ka-29 template diff, the fleet-template identity of the mast/tail chains. These are
  deterministic-hash facts, safe to fold into the corpus.
- **Confirmed NAME strings:** **0.** Reject `Y7EzN3L7` (brute-force junk on node 35).
- **Predicted names:** all LOW confidence, domain reasoning only, and every specific string above was
  hash-tested and did **not** match. They are recorded so that when an unstripped dev build / the
  `Mercs2_Skeleton` XSI scene is decoded, matching is a lookup, not a re-derivation.
- **The wall:** coverage is solved; *recognition* is the wall. The rotor rig-template tokens and the
  destruction-group stem are ≥6-char studio-internal names outside every dictionary assembled here — the
  same failure mode the deform-rig (`bone_ub`/`bone_lb`) and destruction (`ghw`/`bbd`) departments hit. The
  realistic route to the literal strings is the GPU single-state sweep on the three proven stem-states, or a
  symbol-bearing source, not more vocabulary.
