# Helicopter rig dissection — how Mercenaries 2 binds controls to a model

Reverse-engineered to plan importing a new helicopter (the russian-transport-heli
FBX) onto an existing in-game heli's rig. Basis: the **Mi-26** (`vz_veh_helicopter_mi26_wheels`),
which is the in-game Russian transport heli.

## TL;DR — how the engine "knows the blades / weapons / gear"
Everything is addressed **by HIER node name-hash** (Pandemic hash). A vehicle is:
**model (HIER + meshes)** + **animgroup (Havok skeleton + clips)** + **ECS component set** +
the generic **`helicopter` Lua class**. No per-vehicle Lua class; no per-vehicle geometry
inside the spawn definition — they are wired together by hashes and handles.

- **Rotor spin** = a continuous `BoneCtrlLocalRotation` ECS component on the rotor node
  (no animation clip for it — confirmed: the animgroup has `opendoor`/`closedoor`/gear
  clips but **no rotor clip**). `ControllerHelicopter` feeds it the rotor speed from throttle.
- **Doors / gear** = wavelet animation clips in the animgroup (`opendoor`, `ahj_gear_*`),
  bound to nodes via `hkaAnimationBinding`; `BoneCtrlPhysicsActor` keeps colliders tracking.
- **Weapons** (armed variants like mi35) = `WeaponCoupling`/`WeaponBarrel` referencing
  hardpoint/muzzle **node hashes**; projectiles spawn at that node's world transform.
- **Faction** = the `FactionMarker` ECS component (0=PMC, 1=VZ, …) — *not* the model or
  class. This is the override-able lever for "make it PMC".
- A submesh attaches to its node via **`INDX`** — ★CORRECTED 2026-07-12: `INDX` is keyed by
  **sub-object** ordinal (not mesh-group) and yields a **`seg_id` into `SEGM`**, whose `bone` field is
  the HIER node. It is NOT a direct mesh-group→node map. See
  [`modernization/vehicle_model_spec.md`](modernization/vehicle_model_spec.md) §2.

## Concrete Mi-26 layout (verified)
The model is split across blocks (the `[[override-source-must-match-aset-block]]` pattern).

> ★**CORRECTED 2026-07-12 — this table misread the LOD-block chain.** The `_P00N_Q(3-N)` blocks are a
> model's **LOD chain**, not "stub variants". `P000_Q3` is the **RESIDENT** block: it *is* the object
> (HIER, SEGM, MTRL, PHY2, destruction machine) plus the coarsest meshes. `P001_Q2` and `P002_Q1` are
> **streamed geometry refinements** carrying `GEOM` + `INDX` and nothing else — which is exactly why
> the row below says "No HIER" and reads as a stub. Their `INDX` rows index the **resident** block's
> `SEGM`. Calling `P000_Q3` "minimal" and treating `P001_Q2` as *the* geometry inverts the
> relationship. See [`modernization/vehicle_model_spec.md`](modernization/vehicle_model_spec.md) §1.

| Block | Role | Contents |
|---|---|---|
| `05322` `vz_veh_helicopter_mi26_wheels_P001_Q2` | **geometry** | GEOM, **37 mesh groups / 71 submeshes**, 14 materials, ~25.5k tris, **INDX** (mesh-group→node). No HIER. |
| `03310` `vehiclenameanimgroup_mi26_P000_Q3` | **rig + anims** | **43 Havok packfiles**, `hkaSkeleton`×… (**86 bones**), wavelet clips (`opendoor`, `closedoor`, `ahj_gear_*`), annotation/event tracks. The skeleton mirrors the HIER; node names live here. |
| `03546` `..._P000_Q3` (7 KB) / `08328` `..._P002_Q1` | ★**the RESIDENT block + the finest LOD rung** (NOT stubs) | `P000_Q3` = the object: HIER / SEGM / MTRL / PHY2 / destruction machine + coarse meshes. `P002_Q1` = streamed geometry + `INDX` only. See the correction box above. |
| `03521` `hijack_mi26` | Lua | hijack minigame script (not the vehicle). |

Mesh-group shape (materials per group): `mg1`=mat2 (3.6k faces, main body LOD0); `mg2/mg3`=
mats{0,5,6,7,8} (multi-material body LOD0/1); **`mg4/mg5/mg6`=mat9, 254 faces each, identical
→ rotor-blur discs (main/tail/aux)**; `mg7-10`=mat10; `mg11-14`=mats{11,12,13}; `mg15-30`=small
multi-material (gear/doors/detail); `mg31-36`=mats{7,11,12}. (Material→texture resolves via a
separate material table, not embedded names — texture identification is the one open item.)

## The import technique: preserve the rig, swap geometry + textures
Because all bindings are by node hash and the animgroup is a *separate* block we don't touch,
we **keep the Mi-26 geometry container's structure** — descriptor table, **INDX**, MTRL,
mesh-group layout — and **replace only each mesh-group's STRM/IBUF/AREA** with the matching
russian-FBX part (transformed into that node's local frame), then recompute PRMG bounds + CSUM.
The animgroup (skeleton + clips) and the ECS rig are reused unchanged, so:
- the rotor node still spins (BoneCtrlLocalRotation) → the new rotor mesh on it spins;
- doors/gear still animate; the flight controller still flies it.

PMC is then an override-only change: set the spawned instance's `FactionMarker → 0` and/or add
a PMC support-catalog entry (`mrxsupportdata.lua` via `MrxSupportCopterDelivery`).

## FBX → part mapping (russian-transport-heli)
The FBX (binary FBX 7400) carries body (texture1, texture2), rotor, and glass material sets.
Map: **rotor mesh → the Mi-26 rotor-blur mesh-group(s)** (so it inherits the spin), body →
the fuselage mesh-groups, glass → the window mesh-group, gear/doors → their groups. Unmapped
FBX parts fall back to the fuselage node; Mi-26 groups with no FBX part keep their mesh.

## Open items (next steps)
1. **Rotor mesh-group confirmation** — resolve the material→texture table (or inspect in the
   workbench / by the node a `BoneCtrlLocalRotation` targets) to confirm `mg4/5/6` are the rotor.
2. **Bone names** — the animgroup's `hkaSkeleton` bone names didn't surface as clean strings
   (only gameplay event annotations did), so nodes may be **hash-only** in the shipped data;
   if so, part identification is by mesh-binding + transform/position, not name. A proper
   `hkaSkeleton` (m_bones[].m_name + m_parentIndices) parse of block 03310 will settle this.
3. The Mi-26 ECS component instances (to read the actual `BoneCtrlLocalRotation` target node
   hash + `FactionMarker`) — pull from `output/extracted/placements/ecs_components.json` /
   the webapp `ecs_records`.

Related: [[override-source-must-match-aset-block]], [[ucfx-model-geometry-format]],
[[phy2-destruction-format]] (Havok packfile parsing reused for the animgroup).
