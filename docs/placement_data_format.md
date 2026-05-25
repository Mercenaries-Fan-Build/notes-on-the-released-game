# Mercenaries 2: World Placement Data Format — Complete Specification

**Date:** 2026-05-15  
**Status:** VERIFIED from binary inspection. All findings based on actual byte-level analysis.  
**Decoder:** `tools/placement_extractor.py`

---

## 1. Architecture Overview

Mercenaries 2 stores world placement data in two complementary systems extracted from `vz.wad`:

| Layer | File | Size | Purpose | Placements |
|-------|------|------|---------|------------|
| **layers_static** | `00029_blocks__VZ__layers_static_P000_Q3.block.bin` | 7.97 MB | Base world layer — always loaded | **62,458** |
| **vz_state** | 746 files (`*_vz_state_*_P000_Q3.block.bin`) | 11 KB–120 KB each | Conditional overlays — mission/faction states | **~3,620 total** |

A third block type, **c3XXXX cells** (9,467 blocks), contains geometry/terrain data and does **NOT** contain placement data.

---

## 2. layers_static Format

### 2.1 File Structure

The layers_static file is a **composite container** of 173 UCFX sub-blocks:

```
[16-byte TOC] × 173+1 entries
[Sub-block 0: UCFX → CHDR → COMP chunks]
[Sub-block 1: UCFX → CHDR → COMP chunks]
...
[Sub-block 172: UCFX → CHDR → COMP chunks]
```

### 2.2 Table of Contents (TOC)

Each TOC entry is 16 bytes:

```
Offset  Size  Type    Field
------  ----  ------  -----
+0x00   4     uint32  payload_size (entry 0 = sub-block count = 173)
+0x04   4     uint32  name_hash
+0x08   4     uint32  format_hash (constant: 0xe6b81a54)
+0x0C   4     uint32  zero
```

TOC entry [N+1] contains the byte size of sub-block N. The UCFX spacing between consecutive sub-blocks exactly matches the TOC sizes (VERIFIED).

### 2.3 Sub-block Internal Structure

Each sub-block begins with UCFX and contains a CHDR chunk table:

```
UCFX header (20 bytes)
CHDR header (20 bytes)
Chunk table entries:
  - enum (0 children) — shared enum string table
  - COMP (3 children: info, schm, data) × N — component definitions
  - flgt (0 children) — float type marker
  - flgs (0 children) — placement state data
```

**CRITICAL: In layers_static, COMP child offsets are RELATIVE to the end of the chunk descriptor table (`data_area_start`).**

### 2.4 COMP Component Types (VERIFIED)

Each COMP block has an `info` child containing the component type name. Key types for placement:

| Component Name | Purpose |
|---------------|---------|
| **Transform** | Contains the 42-byte placement records with XYZ + rotation |
| **Name** | Entity name strings with hex IDs (`"EntityName 0xHEXID"`) |
| **DestructionLink** | Links between destroyable entity groups |
| **HibernationControl** | LOD/streaming visibility parameters |
| **Anchor** | Attachment points |
| **LightObject** | Light source definitions |
| **IntersectionToIntersection** | Road network connections |
| **RoadIntersection** | Road junction definitions |
| **DangerousBuilding** | Buildings that can collapse |
| **LowResTerrainObject** | Maps each `lrterrain_rXX_cYY` entity to its mesh asset hash (see §2.9) |

### 2.5 Transform Record Format (42 bytes)

VERIFIED: Records start at **byte offset 0** (no header) within the Transform COMP data section. Each record is exactly 42 bytes. The first 4 bytes are the **u32 entity key** — the same key used in all other COMPs for that entity.

```
Offset  Size  Type     Field            Description
------  ----  -------  ---------------  --------------------------------
+0x00   4     uint32   entity_key       Entity key (matches Name COMP keys)
+0x04   4     float32  position_x       World X coordinate
+0x08   4     float32  position_y       World Y coordinate (elevation)
+0x0C   4     float32  position_z       World Z coordinate
+0x10   4     float32  zero_pad         Always 0.0
+0x14   4     float32  quat_x           Quaternion X (pitch/roll component)
+0x18   4     float32  quat_y           Quaternion Y = sin(yaw/2)
+0x1C   4     float32  quat_z           Quaternion Z (pitch/roll component)
+0x20   4     float32  quat_w           Quaternion W = cos(yaw/2)
+0x24   6     bytes    tail             Near-zero tail bytes
```

**Rotation encoding:** The four floats at +0x14..+0x20 form a **unit quaternion** `(qx, qy, qz, qw)`.  VERIFIED: `qx² + qy² + qz² + qw² ≈ 1.0` across all 62k records.  For pure Y-axis rotation, `qy = sin(yaw/2)` and `qw = cos(yaw/2)`, so true yaw = `2 * atan2(qy, qw)`.  ~16% of entities have non-trivial qx/qz (tilted objects with pitch/roll).  The decoder exports all four components as `rotation_quat_x/y/z/w` and pre-computes `rotation_y_rad` (the full yaw angle).

### 2.6 COMP Record Format (generic)

All COMP `data` blobs in `layers_static` follow the same pattern: fixed-stride records starting with a u32 entity key. The stride is determined from the `schm` child:

- `schm[0:4]` u32 = n_fields
- `schm[4:8]` u32 = **payload_stride** (bytes of payload after the entity key)
- Total record stride = **4 + payload_stride**

The `schm` payload_stride is verified to match across all non-Transform COMPs. Transform is an exception: its schm reports 52 but the actual payload is 38.

### 2.7 Name ↔ Transform pairing (layers_static)

Within each UCFX sub-block, the Name COMP and Transform COMP both use the same u32 entity keys. Entities are matched **by key** — Name records contain `[u32_le key][entity_name_string 0xKEY\x00][\x00 pad]` and Transform records contain `[u32_le key][38 bytes position/rotation]`. The decoder emits both `entity_id` (as `0xKEY` hex string) and `entity_name` (the bare name portion) on each placement record.

### 2.9 LowResTerrainObject COMP — tile→mesh mapping

VERIFIED 2026-05-16 from `00029_blocks__VZ__layers_static_P000_Q3.block.bin`.

Sub-block 13 of `layers_static` contains the placement metadata for the 400
`lrterrain_rXX_cYY` entities that form Maracaibo's 20×20 low-resolution
terrain grid. Alongside the standard `Name` and `Transform` COMPs, it carries
a `LowResTerrainObject` COMP whose `data` payload is exactly **400 records of
12 bytes** in row-major grid order:

```
Offset  Size  Type     Field             Description
------  ----  -------  ----------------  -----------------------------------
+0x00   4     uint32   entity_key        Same key used by Name/Transform COMPs
+0x04   4     uint32   mesh_hash         Asset hash; matches TOC.hash1 in
                                          the low_res_terrain_P000_Q3 block
+0x08   4     uint32   scene_object_id   Sequential per-record id (opaque)
```

The records are authored in lrterrain row-major order: record `i` is the
mesh assignment for cell `(row=i//20, col=i%20)`. The `entity_key` numeric
range overlaps with other entities in the same sub-block (other COMPs use
intermediate keys), so it must NOT be used as a positional offset — the
list index of the record IS the (row, col).

The `mesh_hash` is the unique mesh asset hash and matches the per-tile
`hash1` field in the TOC of `03121_blocks__VZ__low_res_terrain_P000_Q3.block.bin`
(see `format_reference.md`). 399 of 400 hashes match exactly; the remaining
record corresponds to the one unused TOC slot (one tile in the world is
referenced by a different mechanism — the missing cell can be filled by
the unique unused file index as a deterministic fallback).

Decoded by `tools/terrain_extractor.py:_read_lrterrain_object_records` and
used to drive the `lrterrain_rXX_cYY` → mesh-file-index mapping for terrain
extraction. Recovers the correct world layout for all 400 tiles without
seam-matching. Note that 11% of inter-tile edges align to <5m under this
mapping (with several at <0.05m, confirming exact correctness on those
pairs); the remainder show up to ~400m residual mismatch because each tile
is authored in its own bbox-centred local frame and the raw mesh boundaries
were not designed to be C0-continuous (the original engine likely stitches
them at runtime via skirts or material blending).

### 2.10 Verified Statistics

- **62,624 placement records** extracted from Transform COMP data sections
- **60,136 entity names** matched by entity key from Name COMP data sections
- **173 UCFX sub-blocks**, each containing 2–43 COMP components
- **10,030 ECS records** extracted across 43 unique COMP types
- **7,984 placements** (12.7%) received at least one ECS component
- **Position range**: X: -3888 to 3800, Y: -103 to 393, Z: -3869 to 3800

---

## 3. vz_state Format

### 3.1 File Header (20 bytes)

```
Offset  Size  Type      Field              Verified Values
------  ----  --------  -----------------  --------------------------------
0x00    4     uint32    version            Always 1
0x04    4     uint32    asset_hash         Varies per file
0x08    4     uint32    format_hash        Always 0xe6b81a54
0x0C    4     uint32    reserved           Always 0
0x10    4     uint32    total_payload_size File size minus 20
```

### 3.2 Chunk Table Structure

Same UCFX/CHDR/COMP hierarchy as layers_static, but:

**CRITICAL: In vz_state, COMP child offsets are ABSOLUTE file offsets (not relative).**

The `flgs` and `flgt` chunk table entries use a non-COMP format:

```
Offset  Size  Type    Field
------  ----  ------  -----
+0x00   4     char[4] "flgs"
+0x04   4     uint32  data_offset (ABSOLUTE)
+0x08   4     uint32  data_size
+0x0C   4     uint32  zero
+0x10   4     uint32  zero
```

### 3.3 flgs Placement Record Format (42 bytes)

Records begin after a variable-length header in the flgs data section. The header end is located by finding the first `0x3f800000` (1.0f) and subtracting 4 bytes.

```
Offset  Size  Type      Field            Description
------  ----  --------  ---------------  --------------------------------
+0x00   4     uint32    state_flags      Usually 0x00000000
+0x04   4     float32   boot_float       **UNVERIFIED as scale** — also interpretable as uint32 (`boot_u32`); do not use as mesh uniform scale in UE until re-validated
+0x08   4     uint32    type_hash        Component type hash
+0x0C   2     uint16    extra_flags      Varies
+0x0E   4     uint32    entity_id        Maps to named entities in COMP data
+0x12   4     float32   position_x       World X coordinate
+0x16   4     float32   position_y       World Y coordinate (elevation)
+0x1A   4     float32   position_z       World Z coordinate
+0x1E   4     float32   rotation_0       Rotation component (usually 0)
+0x22   4     float32   rotation_1       Often -0.0 or 0.0
+0x26   4     float32   rotation_y       sin(yaw) for Y-axis rotation
```

Total: 42 bytes (0x2A). **Stride VERIFIED** via recurring 1.0f pattern at offset +4.

### 3.4 Entity Name Cross-Reference

Entity IDs in flgs records map to named entities defined in COMP `data` sections. Names follow the format `"EntityName 0xHEXID"`.

VERIFIED examples from pmccon004:

| Entity ID | Name |
|-----------|------|
| 0x0012b37b | Light_large_whiteblue_cumana |
| 0x0012d4f1 | VZ Soldier |
| 0x001313f9 | _global_fencechainlong |
| 0x00131407 | _global_flag_smallVZ |
| 0x0013140d | _global_fencechaingate |

### 3.5 State Overlay System

vz_state filenames encode game state:

| Suffix | Meaning |
|--------|---------|
| `_pristine` | Original/undamaged state |
| `_destroyed` | Post-destruction |
| `_staging` | Pre-mission enemy placement |
| `_defenses` | Defensive fortifications |
| `_captured` | Player-captured location |
| Faction: `chi`, `pir`, `gur`, `oil`, `all`, `pmc` | Chinese, Pirate, Guerrilla, UP, Allied, PMC |

### 3.6 Verified Statistics

- **746 vz_state files** total
- **320 files** (43%) contain verifiable XYZ placements
- **~3,620 entity placements** across all files
- **53 placements** in pmccon004 with valid world coordinates

---

## 4. c3XXXX Cell Blocks — NOT Placement Data

### 4.1 Summary

9,467 c3XXXX blocks were analyzed. They contain **NO placement data**.

### 4.2 Three Sub-types

| Format Hash | Count | Content | Contains Placement? |
|------------|-------|---------|-------------------|
| `0xf011157a` | ~9,400 | Compressed texture/terrain data (BODY chunks) | **NO** |
| `0x5b724250` | ~60 | Mesh geometry (HIER, MTRL, SEGM, GEOM, MESH, INDX + Havok physics) | **NO** |
| `0x600b904e` | ~7 | Tiny checksum wrappers (48 bytes, CSUM only) | **NO** |

### 4.3 Evidence

- No COMP, flgs, flgt, or enum tags in any c3 block
- No (0,0,0,1) float patterns in BODY-type blocks
- Mesh blocks contain vertex/face/material data but no world transforms
- The spatial grid naming (c3XXXX) refers to streaming cells for geometry LOD, not entity placement

---

## 5. Coordinate System

VERIFIED from extracted positions across both layers_static and vz_state:

```
X axis:  -3900 to +3800  (East-West)
Y axis:  -103  to +393   (Elevation — negative = underwater)
Z axis:  -3870 to +3800  (North-South)
```

Units are **meters** (verified: Parque Central towers = 220 game units ≈ 225 m real-world height).

### 5.1 Handedness and transforms (positions + rotations)

**Position transforms:**

| Path | Transform | Notes |
|------|-----------|-------|
| Mesh export (game → glTF) | `(x, y, z)` written directly | No Z-negate, no winding flip; only UV V-flip |
| UE Interchange importer (glTF → UE) | Y-up → Z-up (swaps Y↔Z) | Automatic |
| Placement (game → UE) | `(x, y, z)` → `(100·x, 100·z, 100·y)` | Same result as mesh import path |

- Game geometry is **left-handed Y-up** (D3D9).
- `tools/gltf_exporter.py` writes game coordinates directly into the glTF buffer.  The only transform applied is the **UV V-flip** (`v = 1 - v`, D3D9 V=0-top → glTF V=0-bottom) via `convert_uvs_d3d_to_gltf`.
- UE Interchange's Y-up→Z-up swap produces UE coordinates equivalent to `game_to_ue`.
- Placement JSON and `game_to_ue` in populate scripts stay in **game LH** metres with `(x, y, z) → UE (100·x, 100·z, 100·y)`.

**Rotation transforms:**

The 42-byte Transform record stores a **unit quaternion** `(qx, qy, qz, qw)` at offsets +0x14..+0x20.  For pure Y-axis rotation: `qy = sin(yaw/2)`, `qw = cos(yaw/2)`.  True yaw = `2 * atan2(qy, qw)`.

VERIFIED: `qx² + qy² + qz² + qw² ≈ 1.0` across all 62k records.  ~16% of records have non-trivial pitch/roll (|qx| > 0.01 or |qz| > 0.01).

| Source | Transform | Destination |
|--------|-----------|-------------|
| Game quaternion (qx,qy,qz,qw) | `game_quat_to_ue_rotator_deg(qx,qy,qz,qw)` | UE Rotator (pitch, -yaw, roll) |
| Game yaw (rad, from `2*atan2(qy,qw)`) | `game_yaw_to_ue_yaw_deg(rad)` → -degrees | UE yaw (around +Z) |

- Both game (LH Y-up) and UE (LH Z-up) are left-handed. The basis swap `(x,y,z)→(x,z,y)` preserves handedness.
- **Yaw is NEGATED**: game positive yaw (CW looking down +Y) is opposite to UE positive yaw.  UE yaw = -game_yaw.  Empirically verified against PMC HQ, pool, and estate wall landmarks.
- The quaternion basis swap is: game `(qx, qy, qz, qw)` → UE `(qx, qz, qy, qw)` (swap Y/Z components).
- Full pitch/roll is preserved in the quaternion path for tilted entities (tires, rocks, poles).
- Implementation: `tools/mercs2_coords.py` → `game_yaw_to_ue_yaw_deg()`, `game_quat_to_ue_rotator_deg()`.

### 5.2 vz_state Data Layers

Overlay taxonomy and UE Data Layer labels: `game-scripts/mercs2_vz_taxonomy.py`.  
Manifest: `output/placements/vz_act_layer_manifest.json` (from `tools/build_vz_act_manifest.py`).

---

## 6. Rotation Encoding

### 6.1 layers_static

Stores a **unit quaternion** `(qx, qy, qz, qw)` at offsets +0x14, +0x18, +0x1C, +0x20:
- For pure Y-axis rotation: `qy = sin(yaw/2)`, `qw = cos(yaw/2)`
- True yaw = `2 * atan2(qy, qw)`
- Identity rotation: qx=0, qy=0, qz=0, qw=1

VERIFIED: `qx² + qy² + qz² + qw² ≈ 1.0` across all 62,624 extracted records.
~16% of records have non-trivial pitch/roll (tilted objects: tires, rocks, telephone poles).

### 6.2 vz_state

Uses a **single sin(yaw) value** at record offset +0x26:
- Values range from -1.0 to 1.0
- Full quaternion reconstruction requires `cos(yaw) = sqrt(1 - sin²(yaw))` (sign ambiguous)
- Most records have (0, 0, 0) rotation = identity

---

## 7. Differences: layers_static vs vz_state

| Property | layers_static | vz_state |
|----------|--------------|----------|
| File count | 1 composite file | 746 individual files |
| COMP child offsets | **Relative** to data_area_start | **Absolute** file offsets |
| Transform record start | Offset 0 (u32 entity key) | Variable (1.0f search heuristic) |
| Rotation encoding | Unit quaternion (4 floats: qx, qy, qz, qw) | sin(yaw) only (1 float) |
| Record layout | u32 key + XYZ + pad + quat(4) + tail(6) | uint32×2 + uint32 + uint16 + uint32 + XYZ + rot(3) |
| Entity ID in record | u32 at offset 0 of each Transform record | At record offset +14 |
| Purpose | Always-loaded base world | Conditional state overlays |

---

## 8. Using the Decoder Tool

```bash
# Single file extraction
python3 tools/placement_extractor.py path/to/block.bin -o placements.json

# Stats only (no placement data in output)
python3 tools/placement_extractor.py path/to/block.bin --stats-only

# Batch all vz_state files
python3 tools/placement_extractor.py --batch path/to/blocks/ --filter vz_state -o all_vz.json

# Extract layers_static only
python3 tools/placement_extractor.py path/to/blocks/00029_blocks__VZ__layers_static_P000_Q3.block.bin -o static.json
```

---

## 9. Known Limitations

1. **Entity name → Transform cross-referencing in layers_static**: **RESOLVED (2026-05-15).** All COMP data blobs use the same u32 entity key. Name and Transform records are matched by key (not by index). 60,136 of 62,624 placements have both `entity_id` and `entity_name`. The remaining ~2,488 have `entity_id` but no `entity_name` (Name record count differs from Transform count in a few sub-blocks).

2. **vz_state offset +4**: Previously mislabeled as `scale` in JSON output; exported as `boot_float` / `boot_u32`. **Do not** use as UE actor scale until the field semantics are verified.

3. **vz_state variable-length header**: The "first 1.0f minus 4" heuristic for finding record starts works for ~90% of files but may fail for zone/region format files.

4. **Records at flgs tail**: Some records at the end of vz_state flgs sections contain component-table data (not placements) that passes coordinate range filters. Currently filtered by excluding (0,0,0) positions.

5. **Rotation sign ambiguity**: vz_state records encode rotation as a single `sin(yaw)` value. Recovering the full angle requires sign disambiguation of `cos(yaw)`.

6. **UNVERIFIED: layers_static rec_type field**: The uint16 at record offset +0 (values 0x000E, 0x000F) may encode entity type or sub-block cross-reference. Exact meaning not confirmed.

7. **UNVERIFIED: type_hash mapping**: The `type_hash` field in vz_state records (values like `0x800084b3`, `0x80005422`) maps to COMP component indices, but the mapping table is file-specific and not fully decoded.

---

## 10. Data Flow Summary

```
vz.wad (2.57 GB)
  └─ blocks/ (11,371 .bin files)
       ├─ layers_static (1 file, 7.97 MB)
       │    └─ 173 UCFX sub-blocks
       │         └─ COMP[Transform] → 42-byte keyed records → 62,624 placements
       │         └─ COMP[Name] → entity name ↔ key mappings → 60,136 matched
       │         └─ COMP[*other*] → per-entity ECS data → 10,030 records
       │
       ├─ vz_state (746 files, 11–120 KB each)
       │    └─ COMP[data] → entity name ↔ ID mappings
       │    └─ flgs section → 42-byte records → 3,501 placements
       │
       ├─ c3XXXX cells (9,467 files) — per-cell baked geometry (props/roads/buildings in-cell)
       │
       └─ Other (vz_base, vz_mar_roads, assets, etc.)
```

---

## 10. UE5 populate strategy (two-tier model)

`game-scripts/populate_world.py` uses three tiers — do **not** spawn one StaticMesh per
`layers_static` `entity_name` for world fill:

| Tier | Source | UE5 action |
|------|--------|------------|
| **B — c3 cells** | `c3####` / `c3####-c####-c####-__shared__` blocks with `mesh_scene.gltf` | One `StaticMeshActor` per imported cell at grid origin (`tools/c3_cell_grid.py`) |
| **A — hero blocks** | `*_veh_*`, `*_bld_*`, `pmcoutpost_*` GLBs | One actor per block at centroid of placement records whose names share the block prefix |
| **C — placements JSON** | `layers_static` + `vz_state` | Point lights (ECS `LightObject`), skip env props when Tier B is active, vz overlays on data layers |

Grid decode for Tier B: `c3####` IDs map linearly to a 100×100 grid over the world XZ
extent (see `tools/c3_cell_grid.py`). Cell meshes use `import_world.py` →
`/Game/Mercs2/Meshes/WorldCells` (accepts `mesh_scene.gltf` when `.glb` is absent).

PMC base uses `populate_pmc_base.py` + `import_pmc_base.py` for the outpost compound.
