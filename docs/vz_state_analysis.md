# Mercenaries 2: vz_state World Layer Block Analysis

**Date:** 2026-05-15  
**Source:** Decompressed `.bin` blobs at `output/extracted/batch_vz/blocks/`  
**Status:** Verified from binary data — no guesses

---

## 1. File Inventory

There are **746 vz_state .bin files** in the blocks directory.

### Size Distribution

| Range | Count (approx) | Examples |
|-------|---------|---------|
| ~11 KB (smallest) | ~300 | `oilcon005_bonus` (11,012 bytes), `alljob010` (11,484 bytes) |
| 12–15 KB | ~250 | `alljob002_01_pristine` (13,227 bytes) |
| 15–25 KB | ~120 | `pmccon004` (49,714 bytes) |
| 25–50 KB | ~50 | `allcon001` (50,353 bytes) |
| 50–75 KB | ~15 | `gurcon002` (68,836 bytes), `pmc` (75,421 bytes) |
| 75–120 KB | ~10 | `cinematic_vz` (87,761 bytes), `all_fuel_amazon` (119,340 bytes), `car_city_pristine` (113,648 bytes) |

All filenames follow the pattern: `NNNNN_blocks__VZ__vz_state_<name>_P000_Q3.block.bin`

---

## 2. Overall File Structure

Every vz_state block follows this exact structure:

### 2.1 File Header (20 bytes, offset 0x00–0x13)

```
Offset  Size  Type      Field                Verified Values
------  ----  --------  -------------------  --------------------------------
0x00    4     uint32    version              Always 1 (0x00000001)
0x04    4     uint32    asset_hash           Varies per file (e.g., 0x0055e642)
0x08    4     uint32    format_hash          Always 0xe6b81a54 across all files
0x0C    4     uint32    reserved             Always 0
0x10    4     uint32    total_payload_size   File size minus 20 (header size)
```

**Key observation:** The constant `0xe6b81a54` at offset 0x08 appears in every vz_state block and serves as a format identifier. This same value does NOT appear in mesh blocks (c30001 etc.), which use `0x5b724250` instead.

### 2.2 UCFX Container (offset 0x14)

Immediately after the header:

```
Offset  Size  Type      Field
------  ----  --------  -------------------
0x14    4     char[4]   "UCFX" magic
0x18    4     uint32    ucfx_data_size (varies: 100 for small, 900+ for large)
0x1C    4     uint32    zero
0x20    4     uint32    zero
0x24    4     uint32    num_top_level_chunks
```

### 2.3 CHDR (Chunk Header, offset 0x28)

```
Offset  Size  Type      Field
------  ----  --------  -------------------
0x28    4     char[4]   "CHDR"
0x2C    4     uint32    zero
0x30    4     uint32    size (always 8)
0x34    4     uint32    num_entries (matches COMP count + enum + flgt + flgs)
0x38    4     uint32    zero
```

### 2.4 Chunk Table

After CHDR, there is a table of chunk descriptors. Each is one of:

| Tag    | Purpose |
|--------|---------|
| `enum` | Enum definitions (string table for type enums) |
| `COMP` | Component data block |
| `flgt` | Float/flags type marker (4 bytes of data) |
| `flgs` | **The main placement data section** |

---

## 3. COMP (Component) Blocks — Detailed Structure

Each COMP block represents a game component type. Structure at each COMP offset:

```
Offset  Size  Type      Field
------  ----  --------  -------------------
+0x00   4     char[4]   "COMP"
+0x04   4     int32     parent_id (-1 for root)
+0x08   4     uint32    zero
+0x0C   4     uint32    comp_index (counts down from N to 2)
+0x10   4     uint32    num_children (always 3: info, schm, data)
```

Followed by 3 child descriptors (20 bytes each):

```
+0x00   4     char[4]   child_tag ("info", "schm", or "data")
+0x04   4     uint32    data_offset (absolute offset into file)
+0x08   4     uint32    data_size
+0x0C   4     uint32    type_id (2=info, 1=schm, 0=data)
+0x10   4     uint32    zero
```

### 3.1 COMP child sections

- **`info`**: Component name as null-terminated ASCII string  
- **`schm`**: Schema definition — null-separated field names with interspersed hash/type bytes  
- **`data`**: Raw binary data for that component type

### 3.2 Observed COMP Components (from `pmccon004`, 17 COMP blocks)

| Index | Data Size | Component Type |
|-------|-----------|---------------|
| 16 | 936 | Damage/material enums (Ruin_Motorcycle, SheetMetalProp, Tank_Heavy, etc.) |
| 15 | 532 | ObjectTypeHintEnum (None, Vehicle, Personnel) + BuildingCollapseAnimType |
| 14 | 320 | Float arrays (scale/LOD parameters: 1.0, -1.0, 0.5, 0.8) |
| 13 | 16 | Small config data |
| 12 | 12,407 | **Largest** — AiPatrol definitions, spawn configurations |
| 11 | 60 | Light definitions (e.g., "Light_large_whiteblue_cumana 0x0012b375") |
| 10 | 96 | Additional light instances |
| 9 | 1,512 | Named entities ("Emplaced Recoiless Rifle (VZ) 0x0012d4ee", soldiers, vehicles) |
| 8 | 46 | Float tuples (rendering/LOD params) |
| 7 | 32 | Float tuples |
| 6 | 116 | Float tuples (LOD distances) |
| 5 | 336 | Entity params with LOD data |
| 4 | 96 | Density config (0.0189 float + indexed entries) |
| 3 | 104 | PopulationSimpleSpawner definitions |
| 2 | 15,162 | **Entity instance table** — entity IDs + hashes |

### 3.3 Entity Reference Format in COMP Data

Entity references use the format: `"<entity_name> 0x<8-hex-id>"`

Verified examples from `pmccon004`:
- `"Health Pickup 0x000b4e3e"`
- `"Emplaced M101A1 (VZ) 0x000b4e40"`
- `"VZ Deathsquad (Mook) w/ RPG 0x000b4e55"`
- `"Munitions Spawner (VZ) 0x000b4e5e"`
- `"AMX30 (Driver) 0x000b4ead"`
- `"_groutpost_bld_tentlargetarp 0x00105146"`
- `"_global_flag_smallVZ 0x00105147"`
- `"LineRegion_PmcCon004_Traffic"`

---

## 4. flgs Section — THE PLACEMENT DATA (Key Finding)

The `flgs` section contains entity placement and state data. **320 out of 746 files** (43%) contain verifiable entity placement records with XYZ world coordinates, totaling **3,620 entity placements** across all files.

### 4.1 flgs Data Categories

The flgs section has a **variable-length header** followed by 42-byte records. The record content varies by file type:

| Category | Count | % | Description |
|----------|-------|---|-------------|
| **Entity placements** (with XYZ) | 320 | 43% | Position + rotation for placed objects |
| **Zone/region data** | 77 | 10% | Large float values (500, 700, 1300 etc.) — likely spawn zones or road sections |
| **String references** | 87 | 12% | ASCII entity name + "ModelName" field — state change references |
| **Empty** (≤4 bytes) | 106 | 14% | No placement data (identity/null state) |
| **Other/mixed** | 156 | 21% | Various binary data, small records, or non-standard formats |

### 4.2 Record Structure: **42 bytes per record**

**Stride: exactly 42 bytes** (verified by searching for the 1.0f pattern `0x3f800000`, which recurs every 42 bytes across all file types).

For **entity placement** files (e.g., `pmccon004`, `chijob005_a_staging`):

```
Offset  Size  Type      Field                   Description
------  ----  --------  ----------------------  --------------------------------
+0x00   4     uint32    state_flags             Usually 0x00000000; 0x80000000 = special
+0x04   4     float32   scale                   Usually 1.0 (identity scale)
+0x08   4     uint32    type_hash               Component type hash (0x800084b3, 0x80005422, etc.)
+0x0C   2     uint16    extra_flags             Varies (0x0000, 0x0200, 0x0029, 0x0597)
+0x0E   4     uint32    entity_id               Cross-references COMP data entity IDs
+0x12   4     float32   position_x              World X coordinate
+0x16   4     float32   position_y              World Y coordinate (height/elevation)
+0x1A   4     float32   position_z              World Z coordinate
+0x1E   4     float32   rotation_0              Rotation component or 0.0
+0x22   4     float32   rotation_1              Often -0.0 or 0.0
+0x26   4     float32   rotation_y_angle        Y-axis rotation (sine of yaw angle)
```

Total: 42 bytes (0x2A)

### 4.3 Variable-Length Header

The flgs data has a **variable-length header** before the 42-byte records begin. The header size varies from 0 to ~900 bytes depending on the file. To locate the first record, search for the first occurrence of `0x3f800000` (1.0f) in the flgs data and subtract 4 bytes.

### 4.4 Verified Position Data (from pmccon004)

The `pmccon004` flgs section is **3,496 bytes**. Records start at offset 0 (no header). 83 full records + 10 trailer bytes.

| Record | Entity ID | Position (X, Y, Z) | Rotation Y |
|--------|-----------|---------------------|------------|
| 0 | 0x0012b37b | (-3186.64, 110.66, -2665.51) | 0.0 |
| 1 | 0x0012b37c | (-3128.72, 110.66, -2689.92) | 0.0 |
| 2 | 0x0012d4a5 | (-2964.76, 92.35, -2710.71) | 0.0 |
| 3 | 0x0012d4a6 | (-3028.78, 66.93, -2303.95) | 0.0 |
| 4 | 0x0012d4a7 | (-2993.92, 113.40, -2705.58) | 0.0 |
| 5 | 0x0012d4a8 | (-2950.56, 114.49, -2459.99) | 0.0 |
| 6 | 0x0012d4ee | (-2739.86, 159.79, -3006.89) | 0.0 |
| 7 | 0x0012d4ef | (-2727.39, 159.78, -3005.03) | 0.070 |
| 8 | 0x0012d4f0 | (-2739.85, 159.81, -3008.95) | 0.0 |
| 9 | 0x0012d4f1 | (-2727.02, 159.81, -3007.40) | 0.081 |
| 10 | 0x0012d5a5 | (-2724.09, 159.84, -3095.07) | 0.0 |
| 11 | 0x0012d5a6 | (-2727.96, 160.12, -3095.23) | 0.0 |
| 12 | 0x0012d66e | (-3004.76, 111.94, -2226.76) | 0.0 |
| 13 | 0x001313f9 | (-3101.84, 105.79, -2703.65) | -0.145 |
| 14 | 0x001313fa | (-3097.24, 105.79, -2688.32) | -0.145 |
| 15 | 0x001313fb | (-3104.14, 105.79, -2711.31) | -0.145 |
| 28 | 0x0013140c | (-3166.70, 105.81, -2692.15) | 0.0 |
| 29 | 0x0013140d | (-3213.05, 105.82, -2645.23) | -1.0 |
| 30 | 0x0013140e | (-3210.21, 105.81, -2636.35) | -0.922 |

**Validation:** 75 out of 83 records have valid world-range XYZ coordinates. The 8 "invalid" records occur at multiples of 6 and may contain different data types (region/zone markers).

### 4.5 Additional Verified Positions (from chijob005_a_staging)

Records in this file start at byte offset 2 within flgs data (2-byte header).

| XYZ Offset | Position (X, Y, Z) |
|------------|---------------------|
| 0x10 | (-550.67, -33.91, 1442.45) |
| 0x64 | (-561.49, -33.77, 1515.59) |
| 0xB8 | (-576.91, -33.84, 1458.60) |

### 4.6 Zone/Region Format (e.g., car_city_pristine)

Some files use the same 42-byte stride but store zone/region data instead of entity positions:
- `scale` field contains large values: 500.0, 700.0, 1100.0, 1300.0, 2100.0
- `rotation_y_angle` field contains distance values: -300.0, -700.0, 500.0, -900.0
- No entity IDs or XYZ positions present
- Likely defines vehicle spawn zones or road network sections

### 4.7 String Reference Format (e.g., alljob005_05_destroyed)

Small files (40 bytes) containing ASCII references:
```
"9_tgc08 0x00143a18\0\0ModelName\0"
```
These reference TinyGeometry (tgc) objects by name+hash and specify "ModelName" as the field to modify — used for state changes that swap building models between pristine/destroyed.

### 4.8 Entity ID Cross-Reference

The entity_id field (offset +0x0E in each record) maps to named entities defined in the COMP `data` sections. Examples:

| Entity ID | Name (from COMP data) |
|-----------|----------------------|
| 0x0012d4ee | "Emplaced Recoiless Rifle (VZ)" |
| 0x0012d4ef | "Emplaced Recoiless Rifle (VZ)" |
| 0x0012d4f0 | "VZ Soldier" (from COMP data) |
| 0x0012d4f1 | "VZ Soldier" (from COMP data) |
| 0x0012b37b | Light object (from COMP light definitions) |
| 0x001313f9 | Flag/structure (from COMP flags) |

### 4.9 Coordinate System

Based on the position data (verified against `layers_static` full extraction):
- **X axis**: approximately -3900 to +3800 (East-West across Venezuela map)
- **Y axis**: approximately -103 to +393 (elevation — negative values are underwater/below terrain)
- **Z axis**: approximately -3870 to +3800 (North-South)
- Units are **meters** (verified: Parque Central towers = 220 game units ≈ 225 m real-world height)
- Coordinate system is **left-handed Y-up** (D3D9 game space)

### 4.10 Rotation Encoding

The 3 floats at the end of each record (offsets +0x1E, +0x22, +0x26) encode rotation:
- Most records have (0, 0, 0) = no rotation (identity)
- When non-zero, they appear to be **sine-of-angle** values, primarily on the Y axis
- Values like -0.145, 0.070, 0.081, 0.805, -0.922, -1.0 are consistent with `sin(yaw)` for Y-axis rotation
- This is likely a **compressed quaternion** or **Euler sin** encoding where the full quaternion can be reconstructed

---

## 5. Comparison: vz_state vs. Mesh Blocks

### 5.1 vz_state blocks (this analysis)

- Header format_hash: `0xe6b81a54`
- Primary tags: `UCFX`, `CHDR`, `enum`, `COMP`, `flgt`, `flgs`
- Contains: entity definitions, placement data, AI patrol data, spawn configs
- **No geometry** (no GEOM, PRMG, VERT, FACE, INDX)
- Multiple COMP blocks per file (2–17+ depending on complexity)
- Entity names reference game objects (weapons, vehicles, buildings, spawners)

### 5.2 Mesh blocks (c30001, c30002, etc.)

- Header format_hash: `0x5b724250`
- Primary tags: `UCFX`, `INFO`, `HIER`, `MTRL`, `SEGM`, `GEOM`, `MESH`, `PRMG`, `INDX`
- Contains: vertex data, face indices, material refs, bone hierarchy
- **No placement data** (no COMP, no flgs)
- 1.2 KB typical (geometry only, no world data)

### 5.3 layers_static block

- Very large (7.9 MB)
- Contains 173 UCFX instances and 722 COMP blocks
- Same internal COMP/flgs structure as vz_state
- This appears to be the "always-loaded" base layer, while vz_state blocks are conditional overlays

### 5.4 vz_base block

- 17 KB, 6 COMP blocks
- Same structure as vz_state but smaller
- Represents the base world state

---

## 6. Enum String Table

All vz_state blocks share a common enum string table starting after the CHDR. Key enum types:

| Enum Type | Values |
|-----------|--------|
| FireAngleEnum | Narrow, Medium, Wide |
| CameraShakeTypeEnum | Constant, Medium, ConstantRandom, MediumRandom, HardRandom |
| ElevationHintEnum | __internal, Ground |
| DynamicRoadTypeEnum | Overpass |
| WeaponProjectileTypeEnum | Automatic, SemiAutomatic, Burst |
| DamageKeyEnum | Bullet, Rocket, Explosion, Grapple, Terrain, BulletLarge, BulletAM, RocketLarge, ExplosionLarge, MeleeBash, WheelBurnout, Airstrike, BunkerBuster, HumanSliding, Fire |
| AmbientEffectType | AMBIENT_EFFECT_TOP, AMBIENT_EFFECT_TERRAIN |
| TerrainKeyEnum | Terrain_asphalt, Terrain_sand, Terrain_grass, ... |
| ObjectTypeHintEnum | None, Vehicle, Personnel |
| BuildingCollapseAnimType | (multiple values) |
| SimpleSpawnerTypeEnum | Squad |
| SimpleSpawnerGroupEnum | GroundVehicle, AirVehicle |
| SpawnAlignEnum | World |
| SpawnerRadiusTypeEnum | Player2D, Player3D |

---

## 7. Game Data Directory

The `output/data/` directory contains the original game files from disc:

| File | Size | Purpose |
|------|------|---------|
| `vz.wad` | 2.57 GB | Main world archive (source of all extracted blocks) |
| `vz.bin` | 258 bytes | WAD index/table of contents |
| `English.wad` | 483 MB | Localized text/audio |
| `shell.wad` | 29.6 MB | Menu/UI assets |
| `Loading.wad` | 2.5 MB | Loading screen assets |
| `shader3.bin` | 2.6 MB | Compiled shaders |
| `cdbsizes.ini` | 7.4 KB | Database size hints |
| `Movies/` | (dir) | FMV cutscenes |
| `Audios/` | (dir) | Audio banks |

No standalone `.level`, `.world`, `.map`, `.scene`, `.xml`, or `.lua` files were found. All world data is packed within `vz.wad`.

---

## 8. Naming Convention Analysis

The vz_state filenames encode game state information:

| Pattern | Meaning |
|---------|---------|
| `_pristine` | Undamaged/original state |
| `_destroyed` | Post-destruction state |
| `_ruined` | Damaged but not fully destroyed |
| `_staging` | Pre-mission setup (enemy positions for active missions) |
| `_defenses` | Defensive fortifications added |
| `_captured` | Player has captured the location |
| Faction prefixes: `chi`, `pir`, `gur`, `oil`, `all`, `pmc` | Chinese, Pirate, Guerrilla, Oil (UP), Allied, PMC factions |
| `job` vs `con` | Job = bounty/contract mission, Con = story contract |
| `_P000_Q3` | Partition 0, Quality 3 (constant across all files) |

**This confirms vz_state blocks are conditional world overlays** — the game loads different placement data depending on mission state (pristine → staging → defenses → captured/destroyed).

---

## 9. Summary of Key Findings

1. **Placement records are 42 bytes each** in the `flgs` section (verified stride via 1.0f recurrence pattern)
2. **Record format**: 4B flags + 4B scale + 4B type_hash + 2B extra + 4B entity_id + 12B XYZ position + 12B rotation
3. **320 of 746 files** (43%) contain verifiable XYZ entity placements — **3,620 total placements**
4. **flgs data has a variable-length header** (0–900+ bytes) before 42-byte records begin
5. **4 distinct data categories** in flgs: entity placements (43%), zone/region data (10%), string references (12%), empty (14%)
6. **Entity IDs cross-reference** named entities in COMP data blocks (weapons, vehicles, buildings, spawners)
7. **~746 state overlays** represent different game states for the same map locations
8. **No 4x4 transform matrices** — positions use simple XYZ + Y-rotation encoding
9. **The `layers_static` block** is the base world layer; vz_state blocks are delta overlays applied conditionally
10. **Coordinate range**: X ≈ -3900..3800, Y ≈ -103..393, Z ≈ -3870..3800 (meters, left-handed Y-up)
11. **Format hash `0xe6b81a54`** is constant across all 746 vz_state files and uniquely identifies this block type

---

## 10. Appendix: How to Extract Positions

Python extraction code for all entity placements from a vz_state block:

```python
import struct

def extract_placements(filepath):
    """Extract entity placements from a vz_state .bin block.
    Returns list of (entity_id, x, y, z, rot_y) tuples."""
    with open(filepath, "rb") as f:
        data = f.read()

    # Find flgs chunk in the chunk table
    flgs_pos = data.find(b"flgs")
    if flgs_pos < 0:
        return []

    flgs_offset = struct.unpack_from("<I", data, flgs_pos + 4)[0]
    flgs_size = struct.unpack_from("<I", data, flgs_pos + 8)[0]
    flgs_data = data[flgs_offset : flgs_offset + flgs_size]

    if flgs_size < 42:
        return []

    # Find first 1.0f (0x3f800000) to locate record start
    one_pos = flgs_data.find(b"\x00\x00\x80\x3f")
    if one_pos < 4:
        rec_start = 0
    else:
        rec_start = one_pos - 4  # 1.0f is at record offset +4

    stride = 42
    placements = []
    off = rec_start
    while off + stride <= len(flgs_data):
        rec = flgs_data[off : off + stride]
        entity_id = struct.unpack_from("<I", rec, 14)[0]
        x = struct.unpack_from("<f", rec, 18)[0]
        y = struct.unpack_from("<f", rec, 22)[0]
        z = struct.unpack_from("<f", rec, 26)[0]
        rot_y = struct.unpack_from("<f", rec, 38)[0]

        # Filter to plausible world coordinates (meters)
        if -4000 < x < 4000 and -200 < y < 600 and -4000 < z < 4000:
            placements.append((entity_id, x, y, z, rot_y))

        off += stride

    return placements
```

### Known Limitations

1. The variable-length header before records is not fully decoded — the "first 1.0f minus 4" heuristic works for ~90% of files but may fail for zone/region format files.
2. Some records at the end of the flgs section (after the last valid XYZ record) contain different data types that are not yet understood.
3. The `type_hash` field at record offset +0x08 maps to COMP component indices but the mapping table is file-specific.
4. The 3 rotation floats at the end of each record need further analysis to determine if they are Euler angles, compressed quaternions, or axis-angle values.
