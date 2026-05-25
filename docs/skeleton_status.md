# Skeleton Status in the Animation Pipeline

## Verified Facts

These facts were established by probing the extracted Mercenaries 2 data, not by assumption.

### No `hkaSkeleton` object instances exist in carved Havok slices

0 out of 190 carved animgroup `.hkx` slices contain a virtual fixup resolving to an `hkaSkeleton` object instance. The `hkaSkeleton` class name appears in the classname vocabulary table of many slices, but no actual skeleton *object* is present or addressable. The carved data simply does not carry the skeleton.

### No skeleton files in the FFCS path index

Across all 11,369 VZ block paths there are zero filenames matching `skel|skl|rig|hka|hkx|skeleton|biped|joint`. Skeletons are not stored as separate files.

### No shared skeleton system (unlike textures)

Surveying 35 distinct asset type hashes across 3,997 VZ blocks: only textures (`0xF011157A`, ratio 1.25) and meshes (`0x5B724250`, ratio 1.15) are shared cross-block. Every other type has a ratio of 1.00 entries per asset. There is no texture-streaming-style shared skeleton system.

### Bone names are stripped

`Bip01` / `Pelvis` / `Spine` / `Clavicle` / `Hand` / `Foot` / `Head` strings do not appear in any extracted block (raw mesh blocks, animgroup blocks, or decompressed WAD data). Bone names are not on disk.

### Skeleton data is embedded inside mesh UCFX (asset type `0x5B724250`)

Each mesh block may contain:

- **`HIER` chunk**: Bone hierarchy with per-node 176-byte records containing world transforms. The count of records (implied by `hier_bytes / 176`) correlates with animation track counts.
- **`SKIN` chunks**: Per-submesh skinning weights (one per PRMG/submesh).
- **`BSHP` chunks**: Blend shape / morph target data.

For example, Mattias `pmc_hum_mattias_v2` has a 16,720-byte HIER chunk (implying ~95 hierarchy nodes), 17 SKIN chunks, and 9 BSHP chunks.

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

### Skeleton Families

Run `tools/skeleton_families.py` to cluster animated assets by track count and write `output/animations/_skeleton_families.json`.

### Manual Skeletons

Place hand-authored `skeleton.json` files in `assets/manual_skeletons/<family_id>/` (e.g., `assets/manual_skeletons/tracks_60/skeleton.json`). The pipeline picks these up when no automated decode succeeds.
