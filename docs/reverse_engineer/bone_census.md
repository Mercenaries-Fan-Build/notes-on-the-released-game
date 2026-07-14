# Bone census — every HIER node on record

**Status:** complete for the shipped PC data (`vz.wad` + `vz-patch.wad`).
**Data:** [`docs/data/bone_census.csv`](../data/bone_census.csv) — one row per distinct node hash.
**Tool:** `mercs2_probe bone-census [names.txt] [--csv P] [--wads a.wad,b.wad]`
(`crates/mercs2_probe/src/bone_census.rs`).

---

## 1. What a "bone" is in this engine

There is no separate skeleton asset. A bone is a **`HIER` node** inside a model's UCFX container —
a 176-byte record whose `+0` field is `pandemic_hash_m2(node_name)`. The same node type is used for
*everything* attached to a model's transform tree:

| Kind | Naming | Example |
|---|---|---|
| Skeletal deform bone | `Bone_<Part>` | `Bone_LForearm`, `Bone_Hips` |
| Facial (FaceFX) bone | `bone_<feature>_<side>` | `bone_eyeball_left`, `bone_mouth_corner_right` |
| Attach bone | `bone_attach_<part><side>` | `bone_attach_lhand`, `bone_attach_backleft` |
| Hardpoint | `hp_<name>` | `hp_seat_lt`, `hp_barreltip_a`, `hp_playerA_enter` |
| Vehicle functional bone | `bone_<part>_<axis>` | `bone_rudder_yaw`, `bone_propeller_roll` |
| Destruction-state root | bare word | `pristine`, `ruin` |
| Model root | the asset's own name | `al_veh_boat_destroyer` |

There is **no separate ragdoll skeleton** — ragdoll reflection fields are `*BoneIndex` values indexing
this same HIER. Retail animgroups ship **no `hkaSkeleton`**; parents and rest pose live in the HIER, and
a clip's `trnm` chunk binds tracks to bones **by name-hash**, not index.

### ⚠ The hash is case-insensitive

`pandemic_hash_m2` folds every byte with `b | 0x20` before mixing. So `Bone_RBicep`, `bone_rbicep` and
`BONE_RBICEP` all hash **identically**. Casing therefore **cannot be recovered from a hash** — the casing
shown in any name table is whatever the witnessing string used, and carries no evidential weight. Do not
treat a casing difference as a different bone.

---

## 2. The census

Sweep: every primary `model` ASET (`wad::model_list`, grouped by block so each block decompresses once)
→ `parse_hier`/`parse_swit`/`classify`; plus every animgroup block → clip `trnm` bindings (which marks a
node ANIMATION-DRIVEN and catches bones no mesh HIER contains).

```
model assets seen     1994   (1945 with a HIER, 49 with no model span)
animgroups / clips     306 / 6870
DISTINCT NODE HASHES  1314   <-- every bone on record
  named                337
  animation-driven     263
  mesh-only            1051
  anim-only (no mesh)   142   <-- bones that exist ONLY in animation data
```

| Category | Nodes |
|---|---:|
| **Skeletal / attach bones (named)** | 133 |
| **Hardpoints (named)** | 40 |
| Model roots (= the asset's own name) | 151 |
| Destruction-state nodes (`pristine`, `ruin`, `grid`, `state_pristine`) | 4 |
| Other named | 9 |
| **Unnamed** | **977** |
| **TOTAL** | **1314** |

The 977 unnamed split into 158 animation-driven (real rig bones, mostly vehicle rigs), 126 SWIT
destruction pieces, 384 unnamed model roots, and the remainder plain mesh nodes.

### Two nodes dominate the world

Nearly every static prop has a **two-root HIER**: `pristine` (`0x86DE6639`, 1161 models) and `ruin`
(`0xB5D7712F`, 963 models) — the intact and destroyed geometry groups. This is why "root hash =
m2(model name)" is only true for **rigged/destructible** models (destroyers, vehicles, characters);
simple props root at the state words instead.

---

## 3. The human rig — solved

The shared biped is a single rig used by 44–45 character models and driven by ~6,550 animation tracks.
Of a 99-node character HIER, **85 are now named**.

Spine/limbs: `Bone_Root` → `Bone_Hips` → `Bone_Spine1` → `Bone_Spine2` → `Bone_Chest` → `Bone_Neck` →
`Bone_Head`; arms `Bone_L/RShoulder` → `L/RBicep` → `L/RForearm` (+`forearmroll`) → `L/RHand` → 5 finger
chains × 3 joints (`thumb/index/middle/ring/pinky` 1-3); legs `Bone_L/RThigh` → `L/RShin` →
`Bone_L/RFootBone1` → `Bone_L/RFootBone2`. Plus `GlobalSRT` (the transform root) and a 20-bone FaceFX
facial rig (`bone_jaw`, `bone_eyeball_left/right`, `bone_eyelid_top_*`, `bone_eyebrow_*`, `bone_cheek_*`,
`bone_nose_*`, `bone_mouth_*`, `bone_tongue_tip`, `bone_brow_center`).

Attach points: `bone_attach_root` / `_root_b` / `_chest` / `_lhand` / `_rhand`, and the weapon-carry set
**`bone_attach_backleft` / `backright`** (the two rifles slung on the back) and **`bone_attach_hipleft` /
`hipright`** (the holsters).

**The engine hard-codes five of these by hash** (Ghidra): `Bone_Head` + `Bone_Root` in the stance/height
classifier `FUN_0068b490`; `Bone_Root` in the physics push `FUN_0043f060`; `Bone_RShoulder` in
`FUN_006d16b0`/`FUN_006d1cb0`; `GlobalSRT` in the cinematic-camera attach; and `hp_grapple` (`0x892CF579`)
in `FUN_0041fe20`. All node lookups go through the name-hash helper `FUN_006886a0`.

---

## 4. Where names come from (ranked by evidential strength)

The mandate is that **a bare 32-bit hash match is not evidence** — a large enough candidate generator
fabricates plausible names. Every name below is graded by its witness.

| Tier | Source | Yield | Why it counts |
|---|---|---|---|
| **A** | `output/block_strings.txt` — strings of the *decompressed WAD blocks* | ~121 real `bone_*`/`hp_*` strings | Shipped game data. Includes the whole FaceFX rig and a weapon-hardpoint family absent from Lua. |
| **A** | Decompiled Lua (`docs/mercs2-luacd`, `-dlc-luacd`) | ~90 names | Authored source, visible at the call site (`Object.GetHardpointPosition(v,"hp_seat_lt")`). |
| **A** | Shipped exe + Jul-08 prototype PE | 12 `Bone_*` + `bone_massive_*` + `hp_wheel_fl..rr` | String constants the engine itself references. (The prototype's PDB adds **no** bone names over retail — an honest negative.) |
| **A** | `docs/data/live_registry_hashes.csv` | 50 `hp_*` | Real hardpoint names embedded in registry display names (`Mounted AT Missile (1) (hp_barreltip_a)`). |
| **B** | **The Saboteur** decomp (`output/_ghidra_saboteur/`) | 35-bone humanoid grammar | Sibling Pandemic engine, **same rig**. Supplied `Bone_LHand`, `Bone_RHand`, `Bone_Neck`, `Bone_Spine1`, `Bone_L/RShoulder`, `Bone_L/RFootBone1/2` — each verified by hashing to a Mercs2 census hash. |
| **B** | Anatomical corroboration | — | An L/R name pair must have **mirrored translations** in the rig. `Bone_LFootBone1`/`RFootBone1`, `bone_attach_hipleft`/`hipright` etc. all mirror exactly. Structure, not just hash. |
| **C** | Targeted dictionary crack | 21 | Only run against the *known* census hash set with a small, grammar-derived candidate list (expected false positives < 0.01). Cracked `pristine`, `ruin`, `bone_attach_back/hip{left,right}`. |
| **✗** | `docs/data/bone_name_candidates.txt` | — | 141k generated permutations. **Not evidence.** Its generator script cannot be found in the repo; treat as un-auditable. |
| **✗** | Console/PS3 block strings; the ASET name "oracle"; Havok annotations | **0** | Verified negatives. The console name table covers **asset paths only** — it does not extend to bones. |

### The Saboteur mine is EXHAUSTED (measured, 2026-07-13)

We are uniquely able to do this: we hold `pandemic_hash_m2` *and* a clean, unpacked sibling binary. So the
entire 7.3 GB GOG install of The Saboteur was mined — `Saboteur.exe`, `Animations.pack` (179 MB),
`LuaScripts.luap`, `FaceFX/*.fxa`, `AnimText/`, `ModelInfo.txt`, the `Global`/`France`/`DLC` megapacks —
**2,821,931 unique tokens**, each hashed and tested against the 977 unnamed Mercs2 node hashes
(expected false positives at that volume: 0.64).

**Result: 4 hits, of which exactly 1 is real** — `hp_CenterOfMass` (`0xA5F8253C`, present in 30 Mercs2
models, found in `Saboteur.exe`). The other three (`beeehhhmmmqqqvv`, `l7awv3`, `hp_M`) are binary noise
colliding by chance, precisely as the false-positive estimate predicts. A separate full-token sweep of the
36,935-function Saboteur decompilation returned the same single name.

Saboteur's real contribution was already banked: the **humanoid rig** (`Bone_Root`, `Bone_Neck`,
`Bone_Spine1`, `Bone_L/RHand`, `Bone_L/RShoulder`, `Bone_L/RFootBone1`, `Bone_L/RFootBone2`,
`Bone_Attach_RHand`, `hp_shelleject`) — the bones Mercs2's own data never names. Its facial rig uses a
*different* grammar (`Bone_Brow_Left`, `Bone_JawBone`, `Bone_Sneer`) that does **not** hash-match Mercs2's
(`bone_eyebrow_left`, `bone_jaw`), so the two games share the body rig but not the face rig.

**Do not re-run this mine.** It is done; the well is dry. The remaining 158 unnamed animation-driven bones
are Mercs2 **vehicle** rigs, which have no Saboteur counterpart.

Names cracked *this* session were merged into `tools/rainbow_table.json` (+213 name strings), each
validated by recomputing `m2(name)` against the hash it was filed under (0 rejected).

---

## 4b. The canonical 105-bone human rig (reference clip)

[`docs/data/human_rig_reference_105.txt`](../data/human_rig_reference_105.txt) — dumped with
`mercs2_probe --bin clipbones --order 0x60894D81`.

Clip `0x60894D81` (block 3315) is the **105-track full-body reference clip**: its `trnm` binding lists
the complete authored human skeleton **in skeleton order**, so an unnamed bone is pinned anatomically by
its named neighbours. **89 of the 105 are named; 16 are not.** This ordering is the single best tool for
attacking the remainder — e.g. track 17 sits between `Bone_Spine2` and `Bone_Chest`; tracks 3 and 10 head
the left and right leg chains; track 54 (`0x87E8C062`) and its mirror 76 (`0x7D2C9CA4`) sit between
`bone_?shoulder` and `Bone_?Bicep`.

The 16 unknown rig bones (2026-07-13):

| track | hash | position in the skeleton |
|---|---|---|
| 3 / 10 | `0x491E8967` / `0xE6FF1D72` | head the LEFT / RIGHT leg chain, under `Bone_Hips` |
| 17 | `0xFAADBFFF` | between `Bone_Spine2` and `Bone_Chest` |
| 22 | `0x11815D82` | after `bone_attach_backleft/right`, before `bone_neck` |
| 25 / 26 | `0x00A8F086` / `0xEB221048` | under `Bone_Head`, before `bone_jaw` |
| 28–33 | `0x0D29320C` `0x1E4780FA` `0xFE747044` `0x409403C6` `0xFBFA3B2C` `0xA3EEDAF2` | between `bone_jaw` and `bone_mouth_bottom_left` — but **NOT** in the FaceFX actor, so not expression bones |
| 54 / 76 | `0x87E8C062` / `0x7D2C9CA4` | between shoulder and bicep, L / R mirror |
| 102 / 104 | `0xDB0322B7` / `0x9EC352CF` | accessory tail, beside `bone_necklace` / `bone_hair` |

As mesh nodes these 14 (of 16) appear ONLY on `pmc_hum_mattias` v1–v5 + chickensuit — every other character
mesh omits them — but the reference clip proves they are part of the shared authored rig, not Mattias props.

## 4c. ★ EXACTLY 25 bone-name strings exist in the game data

Measured with `mercs2_probe --bin block_content_grep` (new; see the warning below), decompressing and
searching **all 11,087 blocks**:

* **`vz.wad` (PC): 25 distinct `bone_*` strings, in 36 blocks.** The 20 FaceFX facial bones (in the
  `facefxactor` assets, which live in c3 blocks — `c30690`, `c33209`, `c33232`, …) plus `bone_ak47`,
  `bone_grenade`, `bone_pistol`, `bone_attach_lhand`, `bone_chest`.
* **`xbox-vz.wad`: ZERO.** All 11,087 blocks scanned, decompressed fine. The console WAD carries **no**
  bone strings at all.

So every other bone name we have came from the exe, Lua, the live registry, or The Saboteur — and the
**16 unknown rig bones are witnessed by NO shipped Mercs2 artifact whatsoever.** They cannot be resolved
by any string search; only brute force or an unstripped external build can crack them.

> ### ⚠ TRAP: `mercs2_probe block-grep` does NOT search block contents
> `diag::block_grep` only greps **block PATH names** (`wad::block_paths`). It silently reports
> "0 blocks match" for any string that exists *inside* a block, which reads as a definitive negative and
> is not one. Use **`block_content_grep`** for contents. Several hours were burned on this.

### Brute force: measured negative

~500 M candidates were tested against the 16 hashes across four independently-designed grammars
(slot templates with medical/anatomical vocabulary; the proven `<side><part>Bone<n>` pattern from
`Bone_LFootBone1`; compound costume/accessory words; FaceFX vocabulary). **Zero real hits.** The only
matches were the statistically-expected junk (`bone_attach_left_lashtwist_l_d` — at 417 M candidates,
`N × 16 / 2^32 ≈ 1.6` accidental collisions are expected, and that is all that appeared).

A community member's independent brute force (`handle_db.json`, 9,539 hashes, same `pandemic_hash_m2`)
hit the same wall: **all 16 of our hashes are in their DB with synthetic placeholder handles**
(`0x87E8C062` → `4gvex_`) and no real name. 883 of our unnamed hashes overlap theirs. Their DB did yield
one real name, now merged: `0x02195587` = `civ_veh_truck_transport`.

### GPU brute force (adopted 2026-07-13) — and why more speed does not help

A community GPU kernel (`tools/gpu_fast.py`, wrapping cupy `RawKernel`; primitives in `tools/fnv.py`;
driver `tools/bone_gpu_crack.py`) sweeps `<prefix> + wild(L) + <suffix>` at **~7.5 G candidates/s** on an
RTX 2000 Ada — ~2000× the Python brute force. It is self-tested against the CPU reference (`python
tools/gpu_fast.py`) and its `fnv.m2` matches every session-confirmed name.

But throughput does not solve this, because the hash is **32-bit** (~4.3 G values):
* Past ~4.3 G candidates the hash SATURATES — every target hash is hit repeatedly by unrelated strings.
* At 80 G candidates each of the 16 targets collects **~19 collisions**; at an L=8 sweep (3.5 T, ~8 min),
  **~815 each.** The real name (if in the grammar) is 1 of those, unrankable against the rest.
* Volume solved COVERAGE long ago (L=8 exhausts every plausible name). The unsolved problem is
  RECOGNITION, which more candidates makes strictly *worse*.

**Enrichment test (`tools/bone_gpu_enrich.py`) — the rigorous "do false positives point anywhere?"**
An individual collision carries zero directional signal (uniform 32-bit map). The RATE can, though: sweep
the 16 real targets AND an equal-physics control set of random hashes through each grammar; a grammar
holding the real convention hits reals above the collision null. **Result: NO frame is enriched.** Real
per-target hit rates (0.25–0.94 at L=6) are statistically indistinguishable from the random controls
(0.27–0.94), all consistent with the L=6 null of ~0.60; the few frames flagged >1.5× are
multiple-comparison artifacts whose every hit is garbage (`bone_laab8if`, `bone_neckdqqvif`). Conclusion:
**the 16 names are not reconstructable by any affix+wildcard grammar** — an external unstripped build is
the only remaining route. This is now proven, not suspected; do not re-run brute force expecting a
different outcome.

**GPU pass did bank one bone:** `bone_ub` (`0xDB0322B7`, track 102). It is the *only* match in the entire
`bone_XX` space (expected-false 5e-6, not chance), `_ub` = "upper body" is a documented Mercs2 character
suffix (sibling of `_lb`/`_head`/`_hair`), and its track-102 slot is in the accessory tail beside
`bone_necklace`/`bone_hair`. Hash + convention + position agree → merged. **15 of the original 16 remain
unknown.**

### Exhaustive sweep + manual-inspection dump (the final word on brute force)

`tools/bone_gpu_dump.py` swept the **entire ≤13-char name space** for the 15 (bare `bone_`/`hp_`/`bone_attach_`
to 8 wild chars + every side/suffix frame to 7) — **20 trillion candidates**, ~4,600 verified hits per bone
— and wrote them to `output/bone_candidates/<HASH>.txt`, ranked by readability of the WILD MIDDLE only (the
fixed affixes carry no information). `tools/bone_check.py` verifies any flagged candidate + its mirror.

Four independent automated recognition methods were run on the result and **all failed**:
1. readability ranking — tops are garbage with coincidental real fragments (`bone_l5cjawkah`, `hp_duduptoe`);
2. enrichment vs. random-hash controls — no grammar beats the collision null;
3. mirror-pairing — trk54/76 (shoulder) and trk28/31 (jaw) share no coherent mirrored name;
4. morpheme tiling — **0 of ~69,000 collision strings** decompose into a coherent anatomical name (even
   allowing digits + L/R affixes + a full anatomy/rig vocabulary).

Since the sweep is exhaustive over ≤13 chars, the 15 names must be **either >13 characters** (going longer
only multiplies collisions — recognition gets worse, never better) **or built from studio-internal
vocabulary** no dictionary contains. **Brute force is definitively exhausted.** The `output/bone_candidates/`
files remain for a human eye (a person may spot a pattern a morpheme tiler can't encode), but automated
recovery is proven impossible; the only real route left is an unstripped dev/debug build. Do not re-run a
wider brute force — the math guarantees it degrades, not improves.

### bone_forge — human-templated combinatorial cracking (2026-07-14) → +32 vehicle/prop bones

`tools/bone_forge.py` lets a human supply vocabulary ARRAYS + mustache TEMPLATES (`bone_{{side}}{{part}}{{num}}`)
and tests the cross-product against the unnamed hashes, with per-run expected-false printed and mirror-pair
corroboration. A run over vehicle/mechanical vocabulary against all 976 unnamed census hashes returned
**33 hits at a chance-expectation of 0.96** — the 33-vs-1 ratio is itself the enrichment proof that the
templates captured real conventions. 32 were confirmed (family structure + on-model corroboration), 1 was
the lone expected collision (`bonelcheekcenterpointz`, absurd, m=1/anim=0 — rejected).

Cracked conventions (now in the rainbow table), each corroborated beyond the hash:
* **`bone_wheel_<l|r>_<0N>`** — a complete 12-bone numbered L/R wheel family (l_01..06, r_01..06), all
  animated. A coherent 12-member family cannot be 12 independent collisions. Plus glued `bone_wheel_l02`
  and positional `bone_wheel_rl`/`rr`.
* **`bone_door_<r|rr|lt>`** — vehicle door bones (anim-driven).
* **`bone_flag<a..e>`** — flag/banner bones (several with real models + 7 anim tracks).
* **`bone_radar_<a|b|c>`** — all three on `global_weapon_stinger` (its seeker).
* **`bone_yaw`** — on `global_weapon_towtripod`; confirms the `bone_<axis>` (yaw/pitch/roll) rule.
* **`hp_seat_<left|right>`** — seat hardpoints (the `hp_seat_*` family, already witnessed via `hp_seat_lt`).
* **`bone_left` / `bone_right`** — both on `global_tripwire`.

Lesson: the human-templated approach WORKS for vehicle/prop bones (structured, convention-driven, and
appearing on nameable models), where the blind human-rig brute force failed — because here the FAMILY and
ON-MODEL structure supply the second witness the bare hash can't. The 15 hero-rig bones remain unsolved
(no family, no external witness); the productive frontier is the remaining unnamed VEHICLE bones.

## 5. What is still unnamed

- **158 animation-driven bones** with no name — overwhelmingly **vehicle** rigs (the biped is done).
  These are the highest-value remaining targets.
- **126 SWIT destruction pieces** — per-model break-piece nodes. The destroyer CSVs
  (`docs/data/*_destroyer_bones.csv`) leave 291 rows unnamed and **no** shipped string table names them.
- `0xB52A9E15` — the animgroup root/motion-extraction track present in **no** mesh HIER.
- Some hardpoint names are supplied at runtime from event/animation data
  (`objectHardPointBoneName` in `mrxactionhijack.lua`) and are not enumerable from any static source.

### ⚠ Existing names that FAIL the second-witness bar

`docs/data/al_veh_boat_destroyer_bones.csv` / `ch_veh_boat_destroyer_bones.csv` carry these names, and a
sweep of the entire real-string corpus finds **no witness for any of them**:
`hp_seat_cannon`, `hp_seat_driver`, `hp_seat_sam`, `hp_seat_samfm`, `hp_seat_samrr`, `hp_seat_ciwsfl`,
`hp_seat_ciwsfr`, `hp_seat_ciwsrl`, `hp_seat_ciwsrr`, `hp_seat_ciwsfm`, `bone_propeller_roll`,
`bone_rudder_yaw`.

They are hash-only guesses. The *families* are real — `hp_seat_lt` (from `mrxactionhijack.lua`) proves
`hp_seat_*` exists, and `bone_frame` has a Lua witness — but the specific leaf words do not. Treat them
as **plausible, unconfirmed**, not as established fact.
