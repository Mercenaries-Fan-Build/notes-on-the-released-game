# The vehicle model — assembly, binding, and how to author a new one

**Status:** authoritative as of 2026-07-12. Derived entirely from retail containers + the decomp;
every rule below is backed by a probe you can re-run. Supersedes the "intact/ruin submesh
interleaving" story in `model_render_gate_spec.md` §2c and `object_assembly_model.md` §7 — see
[§9 Retracted](#9-retracted-claims).

Read this before authoring a new tank/car/heli, or before touching the model loader.

---

## 1. A vehicle is not one container

Its geometry is spread across a **chain of blocks**, coarsest first:

```
ch_veh_tank_ztz98_P000_Q3.block     4,435 tri   <- RESIDENT: the object lives here
ch_veh_tank_ztz98_P001_Q2.block    18,333 tri   <- streamed refinement
ch_veh_tank_ztz98_P002_Q1.block    28,620 tri   <- streamed refinement
```

`P00N_Q(3-N)` is the same c3 LOD-block scheme that carries a texture's higher mips (see
`wad::extract_texture_hires`). World-placed vehicles use **cell-named** blocks instead
(`c31188` → `c31188-c20055` → `c31188-c20055-c11083`); the chain is that cell's subtree. Both forms
are walked by `wad::extract_model_lods`.

**Only the RESIDENT block ships the object.** The finer blocks are pure geometry payloads:

| chunk | resident `P000` | streamed `P001` / `P002` |
|---|---|---|
| `HIER` — node tree (the skeleton) | ✅ | ❌ |
| `SEGM` — segment table (bone + LOD tier) | ✅ | ❌ |
| `MTRL` — material table | ✅ | ❌ |
| `PHY2` — Havok convex hulls | ✅ | ❌ |
| `SWIT` + `NODE`/`STAT`/`CHDR`/`CEXE` — destruction machine | ✅ | ❌ |
| `GEOM`/`MESH`/`SKIN`/`PRMG`/`PRMT`/`IBUF`/`STRM` — geometry | ✅ (coarse) | ✅ (finer) |
| `INDX` — sub-object → seg_id | ✅ | ✅ |

> **The object is** `geometry(rung) × INDX(rung) × SEGM/HIER/MTRL/PHY2/machine(RESIDENT)`.

The resident `SEGM` is the **master segment table for the whole chain** — the ztz98's 130 records
serve 12 + 35 + 63 groups across three blocks. A streamed rung's `INDX` names rows in *that* table.

**Characters ship a single block and no chain** (Mattias: 55,490 tri resident). If you're testing a
loader change, a character will not exercise any of this.

---

## 2. ★ The binding chain (get this wrong and nothing works)

```
PRMG drawing group
  └─ its parent MESH/SKIN sub-object under GEOM  → sub_object ordinal k
       └─ seg_id = INDX[k]                        ← INDEXED BY SUB-OBJECT, *NOT* BY GROUP
            └─ SEGM[seg_id] = { bone: u16, seg_id: u8, state_mask: u8 }   (4-byte records)
                 ├─ bone       → HIER node = the ATTACHMENT MOUNT (draw-gate clause 3)
                 └─ state_mask → the LOD TIER bitmask            (draw-gate clause 2)
```

**`INDX` has exactly one entry per top-level `MESH`/`SKIN` sub-object under `GEOM`** — never one per
PRMG group. A sub-object can own several drawing groups, so the two ordinals diverge:

| model | INDX rows | MESH + SKIN | PRMG groups |
|---|---|---|---|
| `pmc_hum_mattias_v3` | 24 | 7 + 17 = **24** ✅ | 29 |
| `civ_veh_car_van_crappy` | 65 | **65** ✅ | 77 |
| `ch_veh_tank_ztz98` (P002) | 62 | **62** ✅ | 63 |
| `vz_veh_tank_amx30_elite` (P002) | 31 | 29 + 2 = **31** ✅ | 32 |

Keying on the group index makes every group past the first divergence read the **wrong SEGM row**,
handing the mesh **someone else's bone and someone else's LOD tier**. Symptom, if you ever see it
again: geometry is *correct but in the wrong place* — `vz_veh_tank_amx30_elite` hung its treads in
mid-air at tiers 0/2/4 while tier 1 (where the ordinals coincidentally lined up) rendered perfectly.

**Self-check:** a SEGM row's own `seg_id` field equals the index you reached it by —
`SEGM[61].seg_id == 61`. Assert this; it catches a mis-binding instantly.

**Rigid vs skinned matters.** A `MESH` sub-object is **rigid**: authored in its bone's LOCAL space,
so it must be multiplied by that bone's world-rest matrix. A `SKIN` sub-object is already in model
space. Vehicles are almost entirely rigid (a tank is ~100% `MESH`), which is exactly why a wrong bone
throws parts across the map rather than merely mis-weighting them.

---

## 3. LOD: tiers, and how the rungs compose

`state_mask` is a **bitmask of LOD tiers** (bit 0 = nearest). The engine builds a `view_state` from
camera distance — `1<<n`, or a 3-tier cross-fade window `1<<(n-1) | 1<<n | 1<<(n+1)` — and a segment
passes clause 2 if `view_state & state_mask != 0`.

Once bound correctly, the masks **partition across the chain** (ztz98):

```
P000 (resident)  masks 0x70        -> tiers 4,5,6   (+ 0x7f = every tier: caps/trim)
P001             masks 0x04/0x08   -> tiers 2,3
P002             masks 0x01/0x02   -> tiers 0,1
```

**Rungs REFINE each other; they do not sum.** The resident block is a *complete, self-contained
low-detail model spanning every tier* — the fallback for an object whose finer blocks haven't
streamed — and each finer block **re-authors** some of its nodes at the near tiers. The car van's
body is on node 3 as **736 triangles in the resident block and 9,360 in P001**, both masked for
tier 0. Draw both and you get two detail levels of one panel fighting for the same pixels (that was
11,604 of 19,107 triangles double-drawn).

⇒ **For each `(node, tier)`, only the FINEST loaded rung survives.** `model::apply_supersede` bakes
this into `lod_mask` at load, so downstream consumers just run the ordinary gate. Same relationship
as the texture chain: a finer mip block *replaces* the top of the resident chain rather than adding
to it.

`lod_count` (= runtime `maxLOD`) is model-header `+0x34`; the LOD distance is `+0x38`. **`minLOD`
(runtime `M+0x80`) has no known on-disk source** — header word `0x30` is 0 for every vehicle (and 4
for Mattias, matching his `lod_count`). Open.

---

## 4. The draw gate (3 clauses, all must pass)

`FUN_004722a0` / `FUN_00472a50`:

```c
renderable[seg_id] != 0
&& (view_state@OBJ+0x352 & lod_mask)          != 0     // clause 2 — LOD tier
&& (node < 0 || node_enable@OBJ+0x2a0[node])           // clause 3 — destruction
```

LOD is one axis; destruction is the other. **A mesh draws only if BOTH pass.** `node < 0` means
"bound to no node" — always visible, never superseded.

---

## 5. Destruction

Health → damage **messages** → the per-model state machine → per-node `SHOW`/`HIDE` → clause 3.

**State vocabulary** (cracked; do not re-derive):

| hash | name |
|---|---|
| `0x0ACE072A` | `InitState` — spawn; immediately `SetState(PristineState)` |
| `0x5D308F4F` | `InitDestroyedState` — spawn already wrecked |
| `0xACB51200` | **`PristineState`** |
| `0x1D5575A1` | `DamagedState` — body still shown, fire emitters start |
| `0x92791EBB` | `StartDestroyedState` — explosion, `CreateObject` debris, `SetState(Destroyed)` |
| `0x7687DF41` | **`DestroyedState`** — `SHOW`s the wreck body |
| `0xCA261E5B` | `GoneState` — terminal/empty |

**Messages:** `0xC6507EE1` `DamageMsg`, `0x1ED7AD78` `DestroyMsg` (+ sibling `0x3D0D4C99`).

**Commands** in a state's enter-script: `SHOW`, `HIDE`, `SetState`, `SetStateOnMsg`, `StartEmitter`,
`CreateObject`. The last argument of `SetState`/`SetStateOnMsg` is the **switch node's own hash** (its
machine address), not geometry — don't treat it as a node to hide.

**★`SHOW`/`HIDE` act on the whole SUBTREE**, not just the named node. This is why a tank's chassis
and treads — which the machine never names — still vanish on destruction: they're children of a
governed parent. (Counting only directly-named nodes produces a bogus "40% ungoverned" figure.)

**Shared body slots.** Every vehicle carries two sibling nodes under its body switch node:

| hash | role |
|---|---|
| `0x255EAB53` | the node `PristineState` `SHOW`s — the **intact** body |
| `0x75F1F74D` | the node `DestroyedState` `SHOW`s — the **wreck** body |

The wreck is **geometry in the container**, on its own node — usually skinned with a **shared global
asset** (`global_veh_tank_ruin_dm`, `global_veh_civilianruin`, `global_veh_brokenglass`). It is *not*
a separately-spawned object. `CreateObject` spawns loose **debris** pieces, which is a different
thing.

**A wreck legitimately has MORE triangles than the clean body** (the elite: 11,956 vs 11,579) — a
crumpled hull is high-poly. Never assert `intact > wrecked`. The real invariant is that the two states
draw **different** geometry: the wreck is *swapped in*, not added. Verified across car/tank/heli/AA:
**0 triangles drawn identically intact vs destroyed.**

---

## 6. Materials

`MTRL` (resident only) is the material table. **Each `PRMT` sub-strip inside a PRMG group carries its
own material** — render per sub-strip, not one material per group. A single group routinely mixes the
body skin and a shared ruin/glass skin; that is normal and is *not* evidence of a hidden selector.

---

## 7. Authoring a NEW vehicle — the checklist

The governing principle from `valid_model_structure_map.md` still holds: **conform, don't invent.**
Start from a real vehicle container of the same class and rewrite it.

**Must-haves in the RESIDENT block:**

1. `HIER` — the node tree. Node name-hash = `pandemic_hash_m2(bone_name)` (`bone_<part>_<axis>`).
   Include the two shared body slots: `0x255EAB53` (intact) and `0x75F1F74D` (wreck), as **siblings
   under a common parent** which is the body switch node.
2. `SEGM` — one 4-byte record per segment `{bone u16, seg_id u8, state_mask u8}`, sized for the
   **whole chain** (all rungs), with `SEGM[i].seg_id == i`.
3. `INDX` — **one u16 per `MESH`/`SKIN` sub-object**, in sub-object order, each naming a SEGM row.
   `INDX.len() == sub_object_count`. This is the single easiest thing to get wrong.
4. `MTRL`, `PHY2`, and the `SWIT` + `NODE`/`STAT`/`CHDR`/`CEXE` destruction machine.
5. Model header (descriptor row 0's `INFO`): AABB `+0x04`/`+0x10`, node count `+0x20`,
   `lod_count` `+0x34`, LOD distance `+0x38`.

**Per streamed rung (`_P001_`, `_P002_`):** geometry + its own `INDX` only. No HIER/SEGM/MTRL.
Its `INDX` rows index the **resident** SEGM. Give each rung a contiguous tier band and make sure the
bands don't overlap on the same node — or `apply_supersede` will (correctly) drop the coarser copy.

**Class shapes to respect** (parts differ, base destruction doesn't):
- **car** — body + 4 wheels; ~96–98% of near-tier geometry under the machine.
- **tank** — hull + turret + barrel + treads; 7 switch nodes; wreck from `global_veh_tank_ruin`.
- **heli** — fuselage + rotor + blades; the md500 has 33 switch nodes.
- **bike** — frame + 2 wheels; tiny (a 7,149-tri motorcycle).
- **boat** — no shared body slots at all; a different scheme. Don't assume.

**Family sharing is normal.** `ch_veh_truck_sx2150_{tanker,cargo,mlrs,semi}` are four models sharing a
`ch_veh_truck_sx2150_P000_Q3` block that holds **only textures** (cab/wheel/crane) and **no model of
its own**. Cross-block texture refs resolve through the asset registry; nothing special is needed.

---

## 8. Validate with these (all re-runnable)

```
mercs2_probe --bin assembly_check          # chain, tiers, intact/wrecked triangle table
mercs2_probe --bin lod_chunks   -- <model> # chunk inventory per rung (INDX vs MESH/SKIN vs PRMG)
mercs2_probe --bin segm_join    -- <model> # each rung's INDX resolved against the resident SEGM
mercs2_probe --bin overlap_probe            # nodes double-drawn by two rungs at one tier (must be 0)
mercs2_probe --bin govern_probe -- <model> # per-node intact vs wrecked (--tier N)
mercs2_probe --bin sm_dump      -- <model> # the destruction machine, disassembled
mercs2_probe --bin rigid_probe  -- <model> # rigid/skinned per LOD mask; INDX-row shortfall
```

Regression tests: `crates/mercs2_engine/tests/model_assembly.rs`.

**Invariants a valid model must satisfy:**
- `INDX.len() == sub_object_count` for every rung.
- Every group's `seg_id < SEGM.len()`, and `SEGM[seg_id].seg_id == seg_id`.
- No `(node, tier)` drawn by two rungs (0 double-drawn triangles).
- Intact and wrecked draw **different** node sets; the wreck brings in ≥1 node the intact body lacks.

---

## 9. Retracted claims

Struck from earlier docs — every one was an artifact of the mis-binding, and they will send you down
a rabbit hole:

- ❌ *"Intact and ruin submeshes share a node and a LOD mask, so a third selection axis must exist"*
  (`model_render_gate_spec.md` §2c). **No.** The wreck has its own node (`0x75F1F74D`), `SHOW`n by
  `DestroyedState`. The two-axis model (LOD × node-enable) is complete. The apparent sharing was the
  `INDX[group]` bug handing meshes the wrong SEGM row.
- ❌ *"The wreck body is `CreateObject`'d separately, not geometry in this container"*
  (`object_assembly_model.md` §7). **No.** The wreck body IS in the container. `CreateObject` spawns
  debris.
- ❌ *"Tanks leave ~40% of their geometry ungoverned by the destruction machine."* Measurement
  artifact — `SHOW`/`HIDE` act on subtrees.
- ❌ *"A wreck must have fewer triangles than the intact body."* A heuristic, and false.
- ❌ `mesh::near_view_state` / `best_near_view_state` (both deleted) and the "cross-fade window
  `0x0E`" story — both existed only to cope with vehicles whose near geometry we had never loaded.

---

## 10. Still open

- **`minLOD`** (`M+0x80`) — no located on-disk source.
- **`texpng` BC1 alpha decode** is broken (reports opaque skins as ~99% transparent), so alpha
  questions can't currently be settled by eye.
- **`CreateObject` debris and `StartEmitter` fire** are not yet modelled as real child entities.
