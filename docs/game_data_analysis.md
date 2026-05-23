# Mercenaries 2: World in Flames — Game Data Analysis

> Analysis of installed game data at `output/` for level, world, and placement data.
> Generated 2026-05-15.

---

## 1. Top-Level Directory Structure (`output/`)

| Path | Type | Size | Description |
|------|------|------|-------------|
| `Mercenaries2.exe` | File | 17 MB | Game executable |
| `Mercs2.ini` | File | 2.5 KB | Player settings (render, controls, network) |
| `GL.ini` | File | 240 KB | DRM/Game Launcher config (localized error strings) |
| `data/` | Dir | 5.3 GB | **Primary game data** — WADs, shaders, audio, movies |
| `Precache/` | Dir | 403 MB | GPU precache files (272 files) |
| `extracted/` | Dir | — | Extracted/decompressed WAD contents |
| `extracted_audio/` | Dir | — | Extracted audio summaries |
| `knowledge/` | Dir | 64 KB | Save game analysis (`saves.json`) |
| `Support/` | Dir | — | Installer support files |
| `__Installer/` | Dir | — | Installer assets |
| `animations/` | Dir | — | Extracted animation data |
| `ue5_import/` | Dir | — | UE5 import pipeline output (assets, metadata) |
| `maracaibo_asset_list.json` | File | 124 KB | Catalogued Maracaibo assets (241 filtered entries) |
| `variant_registry.json` | File | 12 KB | Asset variant registry (36 entries) |

---

## 2. `data/` Directory — Full Listing

```
data/
├── Audios/
│   ├── ambience.pws          (73 MB)   — Ambient sound archive
│   ├── music.pws             (541 MB)  — Music archive
│   └── vo_stream.english.pws (761 MB)  — Voice-over streaming archive
├── Movies/                   (45 .bik files, ~2.2 GB total)
│   ├── 01_AOA_C.bik .. 15_ACK_M.bik  — Cutscenes per character (C/J/M)
│   ├── EA.bik, Pandemic.bik           — Studio logos
│   ├── attract.bik                     — Attract mode
│   └── shell_*.bik                     — Menu background videos
├── cdbsizes.ini              (7 KB)    — Component Database preallocation sizes
├── shader3.bin               (2.4 MB)  — Compiled shaders (high quality)
├── shader3Low.bin            (840 KB)  — Compiled shaders (low quality)
├── shaderR2VB.bin            (48 KB)   — R2VB shader variants
├── shaderR2VBLow.bin         (48 KB)   — R2VB shader variants (low)
├── shaderVT.bin              (61 KB)   — Vertex texture shaders
├── shaderVTLow.bin           (61 KB)   — Vertex texture shaders (low)
├── shell.wad                 (28 MB)   — FFCS archive: UI/shell assets
├── English.wad               (461 MB)  — FFCS archive: English localization + VO
├── Loading.wad               (2.4 MB)  — FFCS archive: Loading screen assets
├── vz.bin                    (258 B)   — **Hex-encoded hash/key** (not world data)
└── vz.wad                    (2.4 GB)  — **THE MAIN WORLD DATA ARCHIVE**
```

### Key Observation: `vz.wad` is the Venezuela World Archive

The `vz.wad` file (2.4 GB) is the **FFCS (FlatFile Container System)** archive containing **all world/level data** for Venezuela ("VZ"). Its internal structure (from `extracted/ffcs_vz/manifest.json`):

| Chunk | Entries | Size | Purpose |
|-------|---------|------|---------|
| INDX | 11,370 | 133 KB | Block index table |
| DATA | 36 segments | 2.4 GB | Compressed block data |
| CSUM | 7,018 | — | Checksums |
| ASET | 30,645 | 479 KB | Asset reference table |
| PTHS | 11,370 | 1.4 MB | Path string table |

**Total blocks in vz.wad: 11,370** — every world object, terrain tile, state variation, script, road network, and building is stored as a named `.block` within this archive.

---

## 3. Block Taxonomy (from `extracted/ffcs_vz/paths.txt`)

The 11,370 blocks decompose into the following categories:

### 3.1 LOD Distribution

| LOD Level | Suffix | Count | Description |
|-----------|--------|-------|-------------|
| P000_Q3 | Highest fidelity | 3,581 | Base resolution |
| P001_Q2 | Medium | 1,762 | First LOD reduction |
| P002_Q1 | Medium-Low | 3,001 | Second LOD reduction |
| P003_Q0 | Lowest (streaming) | 3,026 | Distant/low-res |

### 3.2 Block Categories (P000_Q3 only — 3,581 blocks)

| Category | Count | Pattern | Description |
|----------|-------|---------|-------------|
| **World Cell Tiles** | ~2,227 | `c3XXXX_P000_Q3.block` | Spatial grid cells (c30001–c39999) |
| **State Layers** | ~746 | `vz_state_*_P000_Q3.block` | Mission/state-dependent object placement |
| **Named Buildings** | varies | `*_bld_*`, `caracas_bld_*`, `maracaibo_bld_*`, `merida_bld_*` | Individual building models |
| **Vehicles** | varies | `*_veh_*` | Vehicle models (al_, ch_, civ_, pmc_, pirate_) |
| **Roads** | varies | `*road*`, `whiteroads` | Road geometry segments |
| **Ambient Zones** | ~17 | `amb_*` | Ambient sound/weather regions |
| **Mission Scripts** | varies | `all0XX_*`, `chi0XX_*`, `gur0XX_*`, `oil0XX_*`, `pir0XX_*` | Per-mission data |
| **Core World** | 1 | `vz_base_P000_Q3.block` | Base world definitions |
| **Static Layers** | 1 | `layers_static_P000_Q3.block` | Static world placement layer |
| **Scripts** | 1 | `scripts_vz_P000_Q3.block` | **Compiled Lua scripts** |
| **Road Network** | 1 | `vz_mar_roads_P000_Q3.block` | Maracaibo road network |
| **Low-Res Terrain** | 1 | `low_res_terrain_P000_Q3.block` | Low-resolution terrain mesh |
| **Terrain Textures** | 4 | `terraintextures*` | Terrain texture assets |

---

## 4. Key Level/World Data Blocks

### 4.1 `vz_base` — World Base Block
- **File**: `00079_blocks__VZ__vz_base_P000_Q3.block.bin`
- **Size**: 17 KB
- **Format**: UCFX container with a single UCFX segment
- **Contents**: Component Database (CDB) schema definitions — enums for every game system:
  - `FireAngleEnum`, `CameraShakeTypeEnum`, `ElevationHintEnum`
  - `DynamicRoadTypeEnum` (Overpass, Wall, Road)
  - `DamageKeyEnum` (Bullet, Rocket, Explosion, Grapple, Car, Terrain, etc.)
  - `TerrainKeyEnum` (asphalt, sand, grass, dirt, rock)
  - `MaterialTypeEnum` (Concrete, Asphalt, BrickPlaster, PropMetal, PropWood, etc.)
  - `SimpleSpawnerTypeEnum`, `SpawnAlignEnum`, `SpawnerRadiusTypeEnum`
  - `ObjectTypeHintEnum`
- **World Data**: This is the **schema/type definition** block — it defines the component types used by all other blocks but contains no object placements itself.

### 4.2 `layers_static` — Static Placement Layer
- **File**: `00029_blocks__VZ__layers_static_P000_Q3.block.bin`
- **Size**: 7.6 MB (largest structural block)
- **Format**: UCFX container with **173 sub-UCFX segments** (entity groups)
- **Contents**: The primary **static object placement layer**. Contains binary-encoded entity component data with:
  - Multiple UCFX/COMP/CHDR/enum/info/schm/data structures per entity
  - The same enum definitions as `vz_base` (shared schema)
  - 400 extracted string samples referencing game system names
  - Entities reference `ObjectScript`, `SpawnAlign`, terrain materials, etc.
- **Significance**: This is **the most important block for world layout** — it defines what static objects exist in the world and their properties. The actual placement transforms are embedded in the binary UCFX `data` segments as **42-byte records** containing XYZ position + unit quaternion rotation (not float4x4 matrices). See `docs/placement_data_format.md`.

### 4.3 `scripts_vz` — Compiled Lua Scripts
- **File**: `03197_blocks__VZ__scripts_vz_P000_Q3.block.bin`
- **Size**: 1.5 MB
- **Format**: Multiple UCFX segments (100+ sub-blocks)
- **Contents**: **Compiled Lua bytecode** (`LuaQ` headers detected) containing:
  - Mission scripts: `Fiona-In-Mission-*`, `Mattias-In-Mission-*`, `Jennifer-In-Mission-*`, `Chris-In-Mission-*`
  - `ScriptEvent` handlers
  - `CopterSpawn` spawner logic
  - `SpawnPatrols` patrol setup
  - `DangerousBuilding` hazard markers
  - `_SetShortDescription` localization hooks
  - Building placement and destruction references
- **Significance**: Contains the runtime game logic that drives mission states, spawning, and dynamic world changes.

### 4.4 `vz_mar_roads` — Maracaibo Road Network
- **File**: `00005_blocks__VZ__vz_mar_roads_P000_Q3.block.bin`
- **Size**: 116 KB
- **Contents**: Road network geometry/connectivity data for Maracaibo

### 4.5 `low_res_terrain` — Terrain Heightmap
- **File**: `03121_blocks__VZ__low_res_terrain_P000_Q3.block.bin`
- **Size**: 6.9 MB
- **Format**: Binary data blocks with repeating 16-byte entries (size + hash + type ID pattern)
- **Contents**: Low-resolution terrain mesh/heightmap data for the entire Venezuela map

### 4.6 World Cell Blocks (`c3XXXX`)
- **Count**: 2,227 unique cells at P000 (range: c30001–c39999)
- **Typical Size**: 1-60 KB per cell
- **Format**: UCFX with GEOM/MESH/INDX/INFO chunks
- **Contents**: Per-cell geometry — each cell contains:
  - Vertex buffers (positions, normals, UVs, tangents) in half-float (f16) format
  - Index buffers
  - PRMG bounding boxes
  - `world_translation` offsets (typically [0,0,0] — translation is implicit from cell ID)
  - Material/texture references (e.g., `global_waterpuddle02`)
- **Significance**: These are the **spatial grid tiles** of the open world. Cell IDs encode grid position. Each cell contains the terrain and static geometry for that grid square.

---

## 5. State Layer System (`vz_state_*`)

The game uses a layer activation system for dynamic world changes. There are **746 state layer blocks** at P000_Q3. Save game analysis reveals these are toggled by Lua scripts during gameplay.

### Layer Naming Convention
```
vz_state_{faction}{type}{number}_{stage}
```

| Faction Prefix | Faction |
|---------------|---------|
| `all` | Allied Nations |
| `chi` | Chinese |
| `gur` | Guerrillas |
| `oil` | Universal Petroleum |
| `pir` | Pirates |
| `pmc` | PMC (Private Military Company) |
| `vza` | Venezuela Army |

| Stage Suffix | Meaning |
|-------------|---------|
| `pristine` | Undamaged state |
| `staging` | Preparation/buildup |
| `defenses` | Defensive fortifications active |
| `destroyed` | Post-destruction state |
| `ruined` | Heavily damaged |
| `captured` | Player/faction captured |

### Notable Specialized Layers
- `vz_state_mar_altagracia_act1` — Maracaibo Altagracia district, Act 1
- `vz_state_mar_industrial_act1` — Maracaibo industrial zone, Act 1
- `vz_state_angel_falls_act1` — Angel Falls region
- `vz_state_amazon_act1` — Amazon region
- `vz_state_car_city_act2chi` — Caracas city, Act 2 Chinese
- `vz_state_margarita_crash` — Margarita Island crash site
- `vz_state_cashpickups` — Cash pickup collectibles
- `vz_state_sol_base_pristine` — Solano's base

---

## 6. Precache Directory (`Precache/`)

Contains **272 files** (8 types x 34 numbered slots), totaling 403 MB:

| Type | Count | Size Range | Purpose |
|------|-------|------------|---------|
| `vertex{0-33}.precache` | 34 | 7–15 MB each | Precompiled vertex buffer caches |
| `index{0-33}.precache` | 34 | 1.4–3.1 MB each | Index buffer caches |
| `display{0-33}.precache` | 34 | 460 KB–1.7 MB | Display list / draw call caches |
| `texture{0-33}.precache` | 34 | 16–40 KB each | Texture reference caches |
| `surface{0-33}.precache` | 34 | 4.6 KB each (uniform) | Surface material caches |
| `pshader{0-33}.precache` | 34 | 11.6 KB each (uniform) | Pixel shader caches |
| `vshader{0-33}.precache` | 34 | 6.2 KB each (uniform) | Vertex shader caches |
| `vertdecl{0-33}.precache` | 34 | 1.3–2.5 KB each | Vertex declaration caches |

The **34 numbered slots** correspond to game zones/areas. These are GPU-ready binary caches meant for fast loading — they contain the same geometry/shader data that is in the blocks but in a pre-processed D3D9 format.

**These are NOT level placement data** — they are rendering optimization caches.

---

## 7. Config Files

### 7.1 `Mercs2.ini` — Player Settings
Standard INI with sections: `[Render]`, `[Joystick]`, `[Game]`, `[Audio]`, `[Network]`, `[Actions1]`, `[Actions2]`, `[Mouse]`, `[Controller]`. No level/map references — purely player preferences.

### 7.2 `GL.ini` — Game Launcher / DRM Config
240 KB of localized error messages for EA's DRM system. No game data.

### 7.3 `data/cdbsizes.ini` — Component Database Preallocation
**This is highly relevant to world structure.** Contains preallocation sizes for every component type in the game's Entity-Component system. Key entries:

| Component | Preallocated Count | Relevance |
|-----------|-------------------|-----------|
| `SceneObject` | 161,280 | **Total objects in world** |
| `RuntimeLayerId` | 20,224 | Layer membership tracking |
| `HibernationControl` | 14,080 | Streaming/hibernation |
| `Flags` | 14,848 | Object flags |
| `Label` | 6,400 | Object labels |
| `Name` | 6,912 | Object names |
| `ModelName` | 4,608 | Model references |
| `Road` | 4,608 | Road segments |
| `RoadIntersection` | 2,304 | Road intersections |
| `TerrainObject` | 1,024 | Terrain tiles |
| `TerrainKey` | 512 | Terrain material keys |
| `FactionZone` | 16 | Faction territory zones |
| `FactionMarker` | 1,280 | Faction control points |
| `LandingZone` | 96 | Helicopter landing zones |
| `SkirmishZone` | 16 | Multiplayer skirmish zones |
| `SkirmishSpawnList` | 16 | Multiplayer spawn lists |
| `PopulationList` | 1,024 | NPC population definitions |
| `PopulationSimpleSpawner` | 768 | NPC spawners |
| `CoverHint` | 2,048 | AI cover positions |
| `AiHintNode` | 128 | AI navigation hints |
| `AiPatrol` | 768 | AI patrol routes |
| `Path` | 512 | Navigation paths |
| `PathData` | 8 | Path metadata |
| `SphereRegion` | 32 | Spherical trigger volumes |
| `CircleRegion` | 8 | Circle trigger volumes |
| `LineRegion` | 512 | Line trigger volumes |
| `PointLocation` | 64 | Named point locations |
| `Anchor` | 1,152 | World anchor points |

**The SceneObject count of 161,280 indicates the world contains approximately 161K placed objects.**

---

## 8. Database / Structured Data Files

**No `.db`, `.sqlite`, or `.dat` files found** in the game data directory.

The game does NOT use a relational database for world data. Instead, all structured data is stored in:
1. **UCFX binary containers** within `.block` files inside WAD archives
2. **Compiled Lua bytecode** for scripting
3. **Binary precache** files for GPU resources

---

## 9. Maracaibo References

### 9.1 Named Maracaibo Blocks (in vz.wad)
| Block Name | LODs Available |
|-----------|----------------|
| `maracaibo_bld_skyscraper01` | P000, P001, P002, P003 |
| `maracaibo_bld_skyscraper02` | P000, P001, P002, P003 |

### 9.2 Maracaibo-Related Cell Blocks
From the `maracaibo_asset_list.json`, cells referencing Maracaibo area include blocks where mesh.meta.json or shared_textures.json contain `maracaibo` texture references. ~53 cell blocks in the extracted review data contain Maracaibo references.

### 9.3 Maracaibo State Layers
| Layer | Purpose |
|-------|---------|
| `vz_state_mar_altagracia_act1` | Altagracia neighborhood, Act 1 configuration |
| `vz_state_mar_industrial_act1` | Industrial district, Act 1 configuration |
| `vz_mar_roads` | Road network geometry for Maracaibo |

### 9.4 Maracaibo Road Block
- **Path**: `vz_mar_roads_P000_Q3.block`
- **Size**: 116 KB
- Contains road segment geometry and intersection data specific to Maracaibo's commercial/residential areas.
- Related road blocks at P000: `marcommercial_sidewalk_road10`, `commercialroad10`, `residentialroad10`, `outskirtroad10`, `jungleroad5`, `jungleroad10`, `outskirtroad20`, `residentialroad5`, `whiteroads`

---

## 10. Save Game Data (World State)

The `knowledge/saves.json` file contains a decompiled save game showing:
- **Lua-compressed world state** (34,137 chars decompressed)
- **`vz_layer_strings`**: A list of ~200+ `vz_state_*` layer names that track which world state layers are active
- Layer activation controls building destruction states, faction presence, mission staging, and collectible placement
- Save references missions by ID (e.g., `GurJob001`, `OilCon001`, `PmcCon004`)

---

## 11. Other WAD Archives

| WAD | Size | Content (from paths.txt) |
|-----|------|--------------------------|
| `English.wad` | 461 MB | 47 blocks: localization, voice-over per mission/character, GUI layouts |
| `shell.wad` | 28 MB | 36 blocks: menu UI, fonts, loading screens, cloud noise, HUD |
| `Loading.wad` | 2.4 MB | 8 blocks: loading screens, fonts, skull overlay |

---

## 12. Extracted Review Data

The `extracted/review/batch_vz/` directory contains **11,370 reviewed block directories**, each with:

| File | Description |
|------|-------------|
| `ucfx.json` | UCFX binary analysis: offsets, tags, string samples, GEOM chunk trees |
| `mesh.meta.json` | Mesh extraction metadata: vertex/face counts, submeshes, textures, bounding boxes |
| `mesh.obj` | Extracted OBJ mesh (when geometry was found) |
| `dialog_fragments.json` | Extracted text strings (bracket keys, generic keys) |
| `textures/` | Texture metadata and extracted DDS textures |
| `havok/` | Havok physics data (collision meshes) |

---

## 13. World Data Architecture Summary

```
vz.wad (2.4 GB FFCS archive)
 └── 11,370 .block files
      ├── vz_base            → CDB schema (enum definitions, component types)
      ├── layers_static      → STATIC OBJECT PLACEMENT (7.6 MB, 173 entity groups)
      ├── scripts_vz         → COMPILED LUA (1.5 MB, mission logic, spawn control)
      ├── vz_mar_roads       → ROAD NETWORK (116 KB)
      ├── low_res_terrain    → TERRAIN HEIGHTMAP (6.9 MB)
      ├── terraintextures*   → TERRAIN TEXTURES (4 blocks, ~300 KB each)
      ├── c3XXXX (x2,227)    → SPATIAL GRID CELLS (per-cell geometry + placement)
      ├── vz_state_* (x746)  → MISSION STATE LAYERS (dynamic world changes)
      ├── *_bld_* (varies)   → BUILDING MODELS
      ├── *_veh_* (varies)   → VEHICLE MODELS
      ├── *road* (varies)    → ROAD GEOMETRY
      ├── amb_* (x17)        → AMBIENT ZONES
      └── mission blocks     → PER-MISSION DATA (all/chi/gur/oil/pir/pmc/jet/mec)
```

### Where Placement Data Lives

1. **`layers_static`** — The primary placement layer. Binary UCFX component data containing **42-byte placement records** with XYZ position + unit quaternion rotation (qx, qy, qz, qw), SceneObject references, and entity property data for static world objects. See `docs/placement_data_format.md` for the full record specification.

2. **`c3XXXX` cell blocks** — Each cell contains geometry with `world_translation` offsets and `prmg_bbox` bounding boxes that define spatial placement within the grid.

3. **`vz_state_*` blocks** — Dynamic placement data for mission-specific objects (fortifications, destroyed buildings, spawned entities).

4. **`scripts_vz`** — Compiled Lua bytecode controlling runtime spawning, patrol routes, and mission triggers.

5. **`cdbsizes.ini`** — Defines the component schema, confirming ~161K SceneObjects, 1,024 TerrainObjects, and 4,608 Road segments exist in the world.

### What's NOT Here

- No plaintext level files (`.level`, `.world`, `.map`, `.scene`)
- No XML or JSON world definitions
- No SQLite databases
- No raw heightmap images
- No Lua source code (only compiled bytecode)
- The `vz.bin` file is a hex-encoded hash/key, not world data

All world/placement data is stored in Pandemic Studios' proprietary **UCFX binary container format** within the FFCS `.wad` archive system. Extracting structured placement data requires parsing the UCFX binary format to read component data tables (transforms, model references, entity properties).
