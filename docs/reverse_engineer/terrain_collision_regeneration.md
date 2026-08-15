# Terrain collision regeneration — from-source rebuild reference

**Scope:** what it takes to regenerate Mercenaries 2 static-world (terrain/building/road) **collision**
for rebuilt or edited geometry, as part of the from-source terrain-block rebuild. Consolidates the
2026-08-14 double-blind investigations (two blind agents per question) and the MOPP-bake-oracle work.
Companion to [`physics_code_map.md`](physics_code_map.md), [`physics_havok_spec.md`](../modernization/physics_havok_spec.md),
and the memory notes `terrain-collision-is-mopp-baked-mesh`, `mopp-bake-oracle-hct-recipe`.

**Status:** collision representation = PROVEN (WAD-wide census). Bake oracle = PARTIALLY PROVEN
(pipeline components solved; end-to-end bake not yet verified). Transplant + in-game = OPEN.

---

## 1. What terrain collision actually is (PROVEN — double-blind, real bytes)

Two independent agents each wrote a probe against the real `vz.wad` and censused every `PHY2`
packfile. Identical result:

- Every collision-bearing streamed world cell ships **`WpMeshShape16`** (Pandemic 16-bit-indexed mesh)
  **+ `hkpMoppBvTreeShape` + `hkpMoppCode`** (baked MOPP bytecode). WAD-wide the three are **1:1:1**
  (~4380 each). **362/362** terrain-scale cells (XZ span > 300–400 m; a full cell = 400×400 m,
  e.g. block 826 `c30103_P000_Q3`) carry a MOPP.
- **Zero** `hkpSampledHeightFieldShape` / `hkpTriSampledHeightFieldBvTreeShape` instances are serialized
  anywhere in `vz.wad`. The heightfield ctor `FUN_00a0e3d0` exists but has effectively no static callers
  and no disk bytes feed it.
- Terrain, buildings, and roads share the same representation; buildings add `hkpConvexVerticesShape`
  destructible hulls. (Road blocks ship no PHY2 — road collision rides the terrain cell; not fully traced.)

**★ This refutes** the `physics_code_map.md` §2 "Correction" that terrain collision is a
`hkpSampledHeightFieldShape` (that claim was self-labeled *inference, no PC string anchor*). The July
`physics_havok_spec.md` ("MOPP + WpMeshShape16, CONFIRMED") is correct. **`physics_code_map.md` still
needs its correction fixed.** OPEN (needs live x32dbg `bp FUN_00a0e3d0`): whether a runtime-only
heightfield is built for a non-collision "fast ground-follow" query — not the streamed collider.

**Consequence:** there is no height grid to resample. Regenerating collision for **new** geometry needs
a rewritten `WpMeshShape16` **and** a freshly-baked `hkpMoppCode`. Even a pure height edit needs a
re-bake — the BV-tree partitions on triangle AABBs, which move with the verts; MOPP is not
height-parameterized, so there is no resample shortcut.

## 2. The proof ladder to "real regenerated collision"

| Rung | Proves | Where it runs | State |
|---|---|---|---|
| **R1** | HCT bakes a MOPP (`hkpMoppCode`) from a triangle mesh, headless; our reader accepts it | this machine | IN PROGRESS |
| **R2** | Round-trip a *real* Mercs2 collision mesh through the bake; compare to the original MOPP | this machine | not started |
| **R3** | Transplant a re-baked MOPP into a real PHY2 (same geometry) → game loads, no `"mopp corrupted"`, collision intact | the game | not started |
| **R4** | Edit geometry → regen `WpMeshShape16` + MOPP → **new** collision confirmed in-game | the game | not started |

For a **faithful rebuild (same footprint)** the template PHY2 collision is reused verbatim — MOPP
untouched, no bake, collision never bites. The bake path only matters for **new/reshaped** geometry.

## 3. The MOPP-bake oracle (HCT 5.5, headless) — state

No native MOPP compiler exists in-tree; `hctFilterPhysics.dll` (HCT 5.5, same toolchain proven for
animation) is the oracle. Full recipe/state in memory `mopp-bake-oracle-hct-recipe`. Solved:

- **Runner:** `hctStandAloneFilterManager.exe <scene.hkx> -s <config.hko>` (CLI being re-derived
  authoritatively from Ghidra disassembly of the arg parser — earlier values were strings-inferred).
- **Filters:** "Create Rigid Bodies" (`hctFilterPhysics.dll`, id `0xB3E7846F`, shape enum has
  `HK_SHAPE_MOPP`) → "Write to Platform" (`hctFilterScene.dll`, id `0xAB787565`, `layoutRules` = 4101).
- **Verifier:** `mercs2_formats::havok::parse_packfile` censuses `__classnames__` → `Shape::Mopp`;
  dump the `hkpMoppCode` u8 buffer. Reference MOPP: `output/_scratch/old_mopp.bin` (901 bytes).

**★ Trap (proven):** `AssetCc2 --xml` silently rejects (exit 0, no output) any packfile with Pandemic
`Wp*` classes (absent from the Havok SDK registry; the filter manager shares that registry). Source
triangles via our reader (`decode_mesh_shape16`), then re-author as a standard `hkxMesh` scene.

**Open blocker (being disassembled):** "Create Rigid Bodies" builds bodies "from the attributes stored
in the nodes" (`hkRigidBody`/`hkShape` hkxAttributeGroups — the DCC/Maya path). Headless, this must be
hand-authored as XML + `AssetCc2 --strip --rules4101`. Ghidra disassembly of the filter's process entry
is under way to determine whether the `.hko` `hctCreateRigidBodiesOptions` (shapeType=MOPP) can drive
shape creation over plain geometry **without** DCC attributes — which would collapse this blocker.

## 4. The render-mesh writer (separate asset) — gap ledger

The render terrain mesh and the collision mesh are different assets. Render-mesh from-source builder
state (double-blind pair B), for context:

- The `ucfx_byteswap` terrain re-encoder (`apply_terrainmesh_reencode` + low-res path) is a
  **byte-transformer, not a builder** (~50–65% of a writer for low-res, ~35–55% for hi-res).
- **BNDS is never recomputed** — that is the **block-367** (`low_res_terrain_P000_Q3`) defect: the
  low-res path widens/un-swaps vertices but ships the stale envelope → 82 sampled verts fall outside.
  For a builder the defect vanishes by construction (recompute the AABB). NB two conflicting BNDS layout
  definitions in-tree — 24-byte (`validate.rs:389`) vs 40-byte (`model.rs:95`); the 40-byte one is
  correct for these tiles. (Possible fix commit `9332b1c` — verify it closed all 82.)
- **Render** terrain verts are inline f16 (no quant, no out-of-band pool) — trivially writable. The
  missing forward pieces are a **list→strip stripifier** for new topology and INFO/GEOM count synthesis.

## 5. Open questions / next actions

1. **Options-vs-attributes** (Ghidra, in progress) — can Create Rigid Bodies bake a MOPP from `.hko`
   options alone? Decides whether headless attribute-scene authoring is needed at all.
2. **Authoritative HCT CLIs** (Ghidra, in progress) — real flag tables for `hctStandAloneFilterManager`
   and `AssetCc2`, read from the arg parser, not strings-inferred.
3. **Transplant triangle-order** — a baked standard MOPP indexes triangles; landing it in a real PHY2
   means pairing it with a `WpMeshShape16` rebuilt from the **identical** triangle order. Verify the
   MOPP leaf indices match the WpMeshShape16 index array before trusting collision (requires decoding
   the MOPP bytecode enough to read leaf triangle indices — currently "recognised, not decoded").
4. **Native Rust MOPP baker** — the portable, no-DLL deliverable (mirrors the anim encoder arc). Only
   needed once the oracle bake is proven and a shippable path is wanted.
5. **In-game gate** — the real confirmation is R3/R4 on the retail game: no `"mopp corrupted"` throw
   + the player collides with the (new) surface.
