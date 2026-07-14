# Skeleton Status in the Animation Pipeline

## Verified Facts

These facts were established by probing the extracted Mercenaries 2 data, not by assumption.

### No `hkaSkeleton` object instances exist in carved Havok slices

0 out of 190 carved animgroup `.hkx` slices contain a virtual fixup resolving to an `hkaSkeleton` object instance. The `hkaSkeleton` class name appears in the classname vocabulary table of many slices, but no actual skeleton *object* is present or addressable. The carved data simply does not carry the skeleton.

### No skeleton files in the FFCS path index

Across all 11,369 VZ block paths there are zero filenames matching `skel|skl|rig|hka|hkx|skeleton|biped|joint`. Skeletons are not stored as separate files.

### No shared skeleton system (unlike textures)

Surveying 35 distinct asset type hashes across 3,997 VZ blocks: only textures (`0xF011157A`, ratio 1.25) and meshes (`0x5B724250`, ratio 1.15) are shared cross-block. Every other type has a ratio of 1.00 entries per asset. There is no texture-streaming-style shared skeleton system.

### Bone names are stripped from the HIER chunk (but NOT absent from the data)

A `HIER` node stores only `pandemic_hash_m2(bone_name)` at `+0` — no name string. That much stands.

**CORRECTED (2026-07-13):** the original claim here — that `Bip01`/`Pelvis`/`Spine`/`Clavicle`/`Hand`/`Foot`/`Head`
strings "do not appear in any extracted block", therefore "bone names are not on disk" — was a **false negative
caused by testing the wrong grammar**. This engine does not use the 3ds Max Biped naming scheme (`Bip01` count in
the exe and in every block dump: **0**). The real grammar is `Bone_<Part>` / `bone_<part>` / `hp_<name>`, and those
strings *do* survive on disk: `output/block_strings.txt` (strings of the decompressed WAD blocks) carries ~121 of
them (`bone_chest`, `bone_jaw`, `bone_eyeball_left`, `hp_barreltip_a`, ...), and the shipped exe carries the 12
`Bone_*` ragdoll constants plus `hp_wheel_fl..rr`.

The names are simply not carried *by the HIER node*; they live in other string tables. See
[bone_census.md](reverse_engineer/bone_census.md) for the full name census and where each name comes from.

### Skeleton data is embedded inside mesh UCFX (asset type `0x5B724250`)

Each mesh block may contain:

- **`HIER` chunk**: Bone hierarchy with per-node 176-byte records containing world transforms. The count of records (implied by `hier_bytes / 176`) correlates with animation track counts.
- **`SKIN` chunks**: Per-submesh **markers** (UCFX containers, `u0 = 0xFFFFFFFF`, `u3` = child count). Each `SKIN` holds a 4-byte `INFO` hash plus a nested `PRMG` row that points at the **same** `STRM`/`IBUF` buffers as the render mesh. Bone indices and weights are **not** in a separate blob — they live in the mesh vertex buffer.
- **`BSHP` chunks**: Blend shape / morph target data.

For example, Mattias `pmc_hum_mattias_v2` has a 16,720-byte HIER chunk (implying ~95 hierarchy nodes), **17** `SKIN` containers, and 9 BSHP chunks.

### SKIN / vertex-buffer layout (verified 2026-05 on `pmc_hum_mattias_v2`)

| Field | Detail |
|-------|--------|
| Container | `SKIN` tag, `u0 = 0xFFFFFFFF`, `u3` = number of child chunk rows (typically 11: `INFO` + nested `PRMG` tree) |
| `INFO` (4 B) | `u32` submesh/name hash (e.g. `0x36bfb9a6` on skin0); not vertex count |
| Nested `PRMG` | Same structure as render `PRMG` (`INFO`, `STRM`/`decl`/`data`, `IBUF`, `PRMT`); `vb_off` / `ib_off` are **relative to UCFX `data_base`** (same buffers as the paired draw) |
| Influences | D3D9-style **`BLENDINDICES` @ +16**, **`BLENDWEIGHT` @ +20** (4× `uint8` each, weights sum to **255**) for strides 24/28/32/40 (see `decl` or fallback table in `ucfx_mesh_codec.py`) |
| Joint indices | **HIER node index** (0 … `hier_bytes/176 − 1`), not animation track index |
| IBM | HIER `+80..+143` inverse bind matrix (row-major) → glTF `inverseBindMatrices` |

Decode API: `decode_skin_chunk()`, `decode_prmg_skin_influences()`, `parse_hier_inverse_bind_matrices()` in `tools/ucfx_mesh_codec.py`.

CLI export: `tools/export_skinned_mesh.py` (one block → `.glb` with `JOINTS_0` / `WEIGHTS_0` + full HIER skeleton).

**Self-test** (`pmc_hum_mattias_v2` P000 Q3, largest multi-bone PRMG): 4091 vertices, 95 bones, weight sums 1.0, 1850 multi-influence verts.

### Animation track counts are real and asset-specific

The `numTransformTracks` field from the wavelet animation header is per-animgroup and varies: 60 for human characters, 22 for vehicles/helicopters, etc. These are real values, not defaults.

## Pipeline Behavior

The animation pipeline writes a `skeleton_status` field into each output GLB's `asset.extras`:

| Status    | Meaning |
|-----------|---------|
| `unknown` | No decoded skeleton. GLB has flat placeholder nodes (one per track, all parented to root, identity transforms). No skin, no mesh probe. |
| `decoded` | Real skeleton resolved from game data (Havok packfile or HIER decode). GLB has a proper bone hierarchy, inverse bind matrices, and optionally a rigid preview mesh. |
| `manual`  | Skeleton authored by hand for an asset family where automated decode failed. Loaded from `assets/manual_skeletons/<family_id>/skeleton.json`. |

## What Was Removed

The pipeline previously fell back to a fabricated 60-bone "default biped" skeleton (`DEFAULT_BIPED` in `hk_skeleton.py`) whenever no `hkaSkeleton` packfile object was found. This was applied indiscriminately to vehicles, helicopters, props, and every other asset type. That fallback has been quarantined (code preserved for reference) and is never used by the pipeline.

## HIER Decode (Verified)

The HIER chunk layout has been fully verified across a cross-category test set (human characters, tanks, helicopters). Each node is 176 bytes with:

- `+16..+79`: local transform (row-major 4x4, relative to parent)
- `+80..+143`: inverse bind matrix (world-space inverse)
- `+8..+9`: parent index (u16, 0xFFFF = root)

Verification: `world_transform * IBM = identity` holds for all nodes (95/95 for Mattias v2, etc.). The HIER provides a valid skeleton hierarchy with bind poses, but bone names are stripped (only name hashes remain).

## Tools

### Audit

Run `tools/mesh_ucfx_skeleton_audit.py` to scan all extracted blocks and produce `output/animations/_skeleton_audit.json` with:

- List of mesh entries that have HIER/SKIN/BSHP chunks
- Per-animgroup slug track counts
- HIER size distribution (proxy for skeleton family clusters)
- Animated slugs that have no paired mesh block

### Skeleton Probe

Run `tools/ucfx_skeleton_codec.py` to validate the HIER layout on a fixed test set and write `tools/_skeleton_probe.json`.

### Skinned mesh GLB (single block)

```bash
# After extracting one character block (see tools/extract_single_block.py):
.venv/Scripts/python.exe tools/export_skinned_mesh.py \
  --block output/_scratch/.../pmc_hum_mattias_v2_P000_Q3.block.bin \
  --out output/_scratch/mattias_skinned.glb
```

### Skeleton Families

Run `tools/skeleton_families.py` to cluster animated assets by track count and write `output/animations/_skeleton_families.json`.

### Manual Skeletons

Place hand-authored `skeleton.json` files in `assets/manual_skeletons/<family_id>/` (e.g., `assets/manual_skeletons/tracks_60/skeleton.json`). The pipeline picks these up when no automated decode succeeds.
