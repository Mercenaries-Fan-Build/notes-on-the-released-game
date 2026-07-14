# Naming dialect: hardpoints / gameplay-systems attach points (`hp_*`)

Department: the `hp_` prefix — engine-queried **attach points**, not art bones. Seats, docks,
gun mounts, barrel tips, shell ejects, FX emitter binds, ladders, spawns, winch points, prop
attach sockets. Cross-cutting: they appear on vehicles, buildings, props and characters alike.

Method note: names exist only as 32-bit case-insensitive `pandemic_hash_m2`. Casing carries zero
evidence. Expected false positives = `S * T / 2^32` (S = candidates, T = targets). Everything
below keeps S small and leans on **free witnesses** (side law, parent/position, family series,
model kind) that are independent of the hash.

---

## 1. What was MINED (literal oracle) — and the key negative result

Sources swept for literal `hp_*` strings:

| Source | Path | `hp_` literals found |
|---|---|---|
| PS3 console WAD strings | `game-files/ps3-VZ.unique-strings.txt` | 82 |
| Xbox console WAD strings | `game-files/xbox-vz.unique-strings.txt` | (same set) |
| Jul-08 devkit WAD strings | `output/jul08_wad/jul08-vz.strings.txt` | 83 |
| **Jul-08 devkit EXE (real PDB build)** | `output/jul08_prototype/mercs2_xenon_p.pe_full_strings.txt` | **6** (`hp_wheel_fl/fr/ml/mr/rl/rr`) |
| Base-game + DLC Lua | `docs/mercs2-luacd/`, `docs/mercs2-dlc-luacd/` | 80 |
| ECS component schemas | `docs/mercs2-ecs/` | 0 |
| Engine symbol docs | `docs/mercs2-pdb-analysis/vehicles.md` | 6 (the wheel set, verbatim) |
| **The Saboteur** (sibling Pandemic title, clean binary) | `output/_ghidra_saboteur/saboteur_all_functions_decomp.txt` | 9 |

De-duplicated mined set: **99 literals.** Every one was hashed with `tools/fnv.py` and checked
against the bone census.

> ### KEY NEGATIVE RESULT
> **All 99 mined literals were already named in `bone_census.csv`. The literal oracle yielded
> ZERO new bones.** The rainbow table has already absorbed every `hp_*` string that exists in any
> shipped string table. Mining `hp_` literals is a **solved, exhausted** avenue — do not re-run it.
>
> Its residual value is *not* new hashes but the **grammar** the literals disclose, which is what
> the rest of this document exploits.

Notable literals and what they teach:

* `hp_wheel_fl / fr / ml / mr / rl / rr` — the only `hp_` names in the engine binary itself.
  Confirms the 6-slot `{f,m,r}×{l,r}` axle index scheme. The engine printf `No Hardpoint
  Transform: %s(%X)` shows it looks these up **by name and hash**.
* `hp_fx_explosionA..N`, `hp_fx_light`, `hp_fx_exhaust_a/b`, `hp_fx_jetexhaust` — FX emitter binds
  use a **letter** series (A..N) or a bare/numeric series.
* `hp_snap_*` (31 literals, all `oilrig_*`) — a **prefab snap-socket** family: `hp_snap_[mv_]piece<N><A>_<target_model_name>`.
  The socket name embeds the *name of the model that snaps into it*. Only ever seen on the oil-rig
  construction kit.
* `hp_<faction><NN>_player` / `hp_<faction><NN>_starter` (al/ch/gr/oc/pmc) — shell/menu scene
  placement anchors, not world hardpoints.
* Saboteur (same studio, same conventions): `hp_shelleject`, `hp_shelleject1/2`, `hp_CenterOfMass`,
  `hp_buoyancy`, `hp_particleEject`, `hp_hat`. Confirms `hp_shelleject` + numeric index; the other
  Saboteur names (`hp_buoyancy`, `hp_hat`, `hp_particleEject`) are **not** present as Mercs2 bones.

---

## 2. Structural discovery: the census tells you which nodes are `hp_`

Profiling the 307 already-named `hp_` nodes against everything else gives a clean discriminator:

| cohort | n | is-leaf | is-root | has anim tracks | in SWIT |
|---|---|---|---|---|---|
| named `hp_*` | 307 | **98%** | 3% | **0%** | 1% |
| named non-`hp_` | 2322 | 27% | 51% | 8% | 14% |
| unnamed | 7570 | 82% | 7% | 1% | 41% |

**A hardpoint is a leaf, carries no animation track, and has a point-sized bbox (`max_bbox ≈ 0.03`).**
That last one is decisive: hardpoints are *markers*, not geometry. Gating on
`leaf ∧ anim_tracks=0 ∧ max_bbox < 1.0` cuts the 7,570 unnamed nodes to **3,204** — a 2.4× reduction
in T before a single candidate is generated.

### 2.1 A correction worth recording

The highest-`n_models` unnamed nodes (173, 139, 81 models) are on **buildings** — and they are
**not** `hp_` at all. Reading their named siblings showed the building dialect is
`slice1b_propattach00`: an attach point whose name **embeds its parent's name**
(parent `slice1b_pristine` → children `slice1b_*`). Chasing them as `hp_*` would have been wasted
effort. See §4.

---

## 3. The `hp_` grammar

```
hp_ <family> [_ <qualifier>] [_ <index>]
```

**Families** (attested): `seat` `dock` `mount` `gunmount` `turretmount` `barreltip` `shelleject`
`wheel` `winch` `hijack` `actionhijack` `camera` `spawn` `ladder_top` `ladder_bottom` `light`
`antenna` `mount_antenna` `flag` `entrance` `weapon` `backpack_roof` `piston_attach` `snap`
`fx_light` `fx_exhaust` `fx_explosion` `fx_jetexhaust` `fx_flare` `fx_parachute`

**Qualifiers** (weapon/role/mount discriminator): `cannon` `hellfire` `sam` `ciws` `missile`
`rocket` `archer` `turret` `rr` — plus role words on seats.

**Index schemes** (they do not mix within one family):
* letter series `_a .. _k` (barreltips, ladders, spawns, docks, FX)
* upper-letter series `A..O` (`hp_fx_explosion*` — case-insensitive, so `A` and `a` are the same hash)
* numeric series `1..23` and `00..NN` (`hp_fx_light*`, `hp_backpack_roof01`)
* side/axle tokens `fl fr bl br rl rr ml mr fm rm lt rt l r`
* **grid**: `<position><letter>` — `ciws{fl,fm,fr,rl,rr}_{a,b,c}`, and (newly) `sam{fm,rr}_{a..h}`

### 3.1 The side law (free witness, no candidate cost)

Measured over 9,112 named instances: **+x = LEFT (99.8%), −x = RIGHT (98.4%).** Any candidate whose
side token disagrees with its node's x-sign is noise and is rejected. **Across all 97 sided/unsided
hits below, zero were contradicted** — against noise you would expect roughly half the sided ones to
contradict. This is the single strongest corroboration in this report.

---

## 4. Adjacent dialect found en route: `propattach` + the state-suffix rule

Not `hp_`, but squarely attach-point territory, and it fell out of the same structural analysis.

**Rule S (state suffix).** A part node's children are co-located copies of it, one per damage state,
and each is named `<parent name>_<state>` with state ∈ {`pristine`, `ruin`}. Attested on
`slice1a_propattach00` → `slice1a_propattach00_pristine` / `_ruin`, and on the dotted building
namespace `floor01.piece1a` → `floor01.piece1a_pristine` / `_ruin`.

**Rule P (prop attach grid).** Destructible buildings carry
`{slice|piece}<N><a-h>_propattach<NN>[_pristine|_ruin]` — a point-sized socket (bbox 0.03, depth 3)
with two geometry state children (bbox large, depth 4, `states=break_piece|intact`).

These two rules together are what produced the bulk of the new names (305 of 405). They are
**parent-derived**, so the prefix is *known* rather than guessed and the pool is tiny.

Also mapped but **not** cracked: the universal vehicle top-level nodes `?765CD254 → {?75F1F74D,
?255EAB53}` (present in **172** vehicle models, bbox 43.9 / 53.0). These are the two whole-vehicle
state subtrees. A 28,617-string part vocabulary tested under a **double-hash constraint**
(`X_pristine` AND `X_ruin` must *both* land on real children — expected-false 3.5e-11) returned
**zero**, so their names are outside conventional part/state vocabulary. Cracking `?765CD254` would
cascade across every vehicle in the game; it is the single highest-value open target.

---

## 5. What was tested and what hit

All passes gate on the structural profile from §2 and reject any side-law contradiction.

| # | Rule | Pool S | Targets T | **Expected false** | Hits |
|---|---|---:|---:|---:|---:|
| A | `{slice,piece}<N><a-h>_propattach<NN>_<state>` | 37,888 | 7,570 | **0.067** | 240 |
| B | parent-derived `<parent>_<state>` (structurally gated) | 9,776 | 7,330 | **0.017** | 67 |
| C | mirror rule (side-token swap on a mirrored sibling) | 3,245 | — | **~1e-6** | 1 |
| D | `hp_` grammar (§3) | 314,878 | 3,204 | **0.235** | 56 |
| E | `hp_` family-series extension | 123,941 | 3,147 | **0.091** | 41 |
| | **TOTAL** | | | **≈ 0.41** | **405** |

**405 new bones for an expected 0.41 false positives.** All 405 verified: hash re-checked against
the name, every one genuinely absent from the census beforehand, no duplicate names, no conflicts
between rules. 100 are `hp_*`; 305 are the `propattach`/state dialect of §4.

Contrast with the cautionary baseline in the brief: a 20,000-word dictionary sweep produced 1,585
hits against 1,615 expected noise (pure garbage). Narrow and correct wins.

### 5.1 Corroboration, best first

* **`hp_seat_rt` (0x56063B28)** — *predicted before hashing*. `hp_seat_lt` sits at x=+0.478 on
  `al_veh_tank_m1a2`; an unnamed node sat at x=−0.478 with identical y,z. The side law says the
  mirror of a `lt` point is `rt`. The hash confirmed it exactly. Two independent witnesses
  (geometry + hash) — the strongest single result here.
* **`hp_dock_lt` / `hp_dock_rt`** — the two remaining unnamed point-nodes on the tank turret, x=+1.193
  and x=−1.045. Side law agrees for both. They complete `hp_dock_{fl,fr,bl,br,left,right}` with the
  turret-top boarding pair.
* **`hp_barreltip_hellfire_e..j`** — extends the *known* `hp_barreltip_hellfire_A..D`, on exactly the
  two Hellfire-carrying helicopters (`al_veh_helicopter_ah1z`, `ch_veh_helicopter_wz10`) and no others.
  Family completion on the right kind of model.
* **`hp_barreltip_samfm_a..h` + `hp_barreltip_samrr_a..h`** — on `al_veh_boat_destroyer` only. This is
  the exact structural twin of the known `hp_barreltip_ciws{fl,fm,fr,rl,rr}_{a,b,c}` grid on the same
  ship: same `<position><letter>` scheme, same model, different weapon system (SAM vs CIWS). 16 cells,
  contiguous.
* **`hp_barreltip_i/j/k`** — on `ch_veh_truck_sx2150_mlrs` and nothing else. An MLRS truck is a
  multiple-launch rocket system; a long contiguous barreltip series is exactly what it should have.
* **`hp_fx_light1..9, 12..23`** — brackets the known `hp_fx_light`, `hp_fx_light10`, `hp_fx_light11`.
  Dense and contiguous, confined to `estate_bld_mansion01/02`, `chinaoutpost_interior_hq`,
  `mountain_bld_bunkerdestroyed`. Contiguity of a series is itself evidence: noise does not produce runs.
* **`hp_fx_explosionH` and `hp_fx_explosionO`** — fill gaps in the mined `A..N` literal series.
* **`hp_spawn_i/j`** — extends known `hp_spawn_a..h`, on `industrial_bld_warehouse03`.
* **`hp_winch_side{a,b}`** — lands on `port_containera/b/c`. Shipping containers are exactly what a
  winch attaches to. Semantic fit on the right model kind.

### 5.2 Lower confidence — flagged, not asserted

* `hp_shelleject_missile{l,r}_{a,b}` (4) — relies on a *fused* side letter (`missilel` = missile+L).
  Fusion is attested (`hp_barreltip_rcketlgR`, `hp_barreltip_rr_a`), but these sit on one unnamed
  model (`?9FCAE910`), n=1, so there is no series or side-law witness. Plausible, not corroborated.
* `hp_weapon_b/c/d` (3) — n=1 on `vz_veh_plane_tucano`. A light attack plane does have wing
  hardpoints, but `hp_weapon_*` is otherwise unattested as a family.
* `hp_entrance`, `hp_flag`, `hp_playerb`, `hp_dock_turret` — single instances, no series.

These are recorded in the JSON with `"confidence": "low"`. **A wrong name is worse than an unknown
one** — treat them as hypotheses pending a second witness.

---

## 6. Open questions

1. **`?765CD254 / ?75F1F74D / ?255EAB53`** (172 vehicle models). The universal vehicle state
   subtrees. Highest-value single target in this dialect: naming them cascades to every vehicle.
   Conventional part/state vocabulary is ruled out (§4).
2. The `hp_snap_*` family exists **only** for `oilrig_*`. Was the prefab snap system used anywhere
   else, or is the oil rig the only kit-built model?
3. `hp_buoyancy`, `hp_hat`, `hp_particleEject` exist in The Saboteur but not in Mercs2 — engine
   features added after Mercs2 shipped, or simply unused here?
4. `bone_attach_*` (the `hp_` cousin on characters: `bone_attach_hipright`, `bone_attach_backright`,
   `bone_attach_steering`, `bone_attach_piston_a..d`) was not swept in this pass — it is a character-rig
   dialect and belongs with the deform-rig department.
5. The three-child part nodes (e.g. `bone_wheel_rr` → 3 co-located children) imply a **three**-state
   scheme, but only `pristine`/`ruin` ever hit. The third state's token is unknown.

## 7. Reproducing

Vocabulary and patterns: `tools/bone_forge_hardpoints.json`.
Hash primitive: `tools/fnv.py` (`m2()`). Data: `docs/data/bone_census.csv`,
`docs/data/bone_skeleton.csv`.
