# Type Hash Registry — Mercenaries 2 ECS Component Types

Complete enumeration of `type_hash` values from every block in the retail `vz.wad`.

Type hashes are computed via `pandemic_hash_m2()` (FNV-1a with `|0x20` case suppression + `^0x2A * FNV_PRIME` finalization). Resolved names confirmed by hash collision.

## Summary

- **WAD file**: `game-files/vz.wad` (2,565,537,792 bytes)
- **Total blocks in WAD**: 11,370
- **Blocks processed**: 11,367 (3 failed to decompress)
- **Total UCFX entries**: 55,425
- **Unique type_hash values**: 35
- **Resolved by name**: 18 / 35
- **ASET entries**: 30,645 (each maps 1:1 to a block sub-entry via `type_id`)

---

## Master Type Table

Sorted by frequency (most common first). ASET `type_id` is the integer discriminator stored in the ASET chunk that maps 1:1 to the `type_hash`.

| # | type_hash | ASET type_id | Entries | Blocks | Resolved Name | Description |
|---|-----------|-------------|---------|--------|---------------|-------------|
| 1 | `0xF011157A` | 27 | 36,724 | 9,482 | **texture** | DDS texture data (compressed BODY chunks). Dominates c3 cell blocks |
| 2 | `0xBCFE6314` | 28 | 5,194 | 1 | **path** | Registry/configuration entries (52–116 bytes each). All in `resident` block |
| 3 | `0x5B724250` | 19 | 4,407 | 2,180 | **model** | Mesh geometry (HIER, MTRL, SEGM, GEOM, MESH, INDX + Havok physics) |
| 4 | `0x18166555` | 16 | 4,261 | 191 | **animation** | Havok 5.5 animation/skeleton packfile data |
| 5 | `0x600B904E` | 12 | 1,026 | 261 | *(unknown)* | UCFX containers with SCRB+MTRL+STRM+INFO chunks (shader/material resources) |
| 6 | `0xE6B81A54` | 9 | 923 | 751 | **layer** | Placement/entity layer data. 81% in `vz_state`, 19% in `layers_static` |
| 7 | `0x42498680` | 35 | 645 | 107 | **script** | Lua bytecode (BINN chunk containing LuaQ compiled scripts) |
| 8 | `0x6310807F` | 30 | 625 | 1 | *(unknown)* | All 625 entries in `resident` block. Likely a global object registry |
| 9 | `0x7C569307` | 32 | 400 | 400 | **terrainmesh** | One per c3 cell block — terrain mesh geometry for that cell |
| 10 | `0x1602815C` | 22 | 400 | 1 | **lowresterrain** | All 400 tiles in `low_res_terrain` block (20×20 grid) |
| 11 | `0x5608BD5A` | 29 | 314 | 1 | **effect** | Particle/VFX definitions. All 314 in `effects` block |
| 12 | `0xF753F6D0` | 6 | 95 | 87 | **wavebank** | Audio wave bank data. In vehicle, weapon, ambient sound blocks |
| 13 | `0x665EF13E` | 5 | 86 | 38 | *(unknown)* | Large UCFX entries (44–46 KB) in contract/briefing/mission blocks |
| 14 | `0xE5273C14` | 13 | 77 | 69 | *(unknown)* | Small UCFX+data entries (88–172 bytes) in vehicle/weapon blocks. Co-occurs with wavebank/soundbank |
| 15 | `0x9F8BCA10` | 21 | 76 | 68 | **soundbank** | Sound bank data. Same blocks as wavebank entries |
| 16 | `0xFE0E8320` | 23 | 60 | 29 | *(unknown)* | UCFX with inner CFX + zlib-compressed payload. In c316XX and contract blocks |
| 17 | `0x1CF649BB` | 34 | 31 | 28 | *(unknown)* | In starter blocks (`allstarter0`, `gurstarter0`) and misc c3 blocks |
| 18 | `0xFA0B8DBC` | 18 | 22 | 1 | *(unknown)* | All in `resident` block (22 entries) |
| 19 | `0x207359C7` | 11 | 15 | 1 | *(unknown)* | All in `resident` block (15 entries) |
| 20 | `0x8F0A54E2` | 3 | 14 | 4 | **binary** | Raw binary data. In `ps3saveassets` blocks |
| 21 | `0x99E77ACE` | 15 | 9 | 3 | **font** | Font data. In `japanese`, `resident` blocks |
| 22 | `0xDE982D61` | 14 | 6 | 1 | *(unknown)* | All in `resident` block (6 entries) |
| 23 | `0x39E5E978` | 7 | 3 | 3 | **stringdb** | Localized string database. In `japanese`, `allcaps`, `english` blocks |
| 24 | `0x59B9DF6A` | — | 1 | 1 | **materialtable** | Singleton in `resident` block |
| 25 | `0x4D7D30C4` | — | 1 | 1 | **watermap** | Singleton in `resident` block |
| 26 | `0x34612F86` | — | 1 | 1 | **foliage** | Singleton in `resident` block |
| 27 | `0xACCE47F2` | 33 | 1 | 1 | *(unknown)* | Singleton in `c33364` block. UCFX with `sequ`/SINF/ITEM chunks (sequence data) |
| 28 | `0xC122545A` | 26 | 1 | 1 | *(unknown)* | Singleton in `musicdata` block. name_hash equals type_hash |
| 29 | `0xE8DF4D87` | 4 | 1 | 1 | *(unknown)* | Singleton in `musicdata` block. UCFX+data container |
| 30 | `0xECE70371` | 31 | 1 | 1 | *(unknown)* | Singleton in `resident` block |
| 31 | `0xEA4829D5` | 20 | 1 | 1 | **level** | Singleton in `resident` block |
| 32 | `0x3B0AABF8` | 1 | 1 | 1 | *(unknown)* | Singleton in `resident` block |
| 33 | `0x5647C35D` | 8 | 1 | 1 | *(unknown)* | Singleton in `resident` block |
| 34 | `0x140E8728` | 10 | 1 | 1 | *(unknown)* | Singleton in `resident` block |
| 35 | `0xFA46D8A8` | 25 | 1 | 1 | *(unknown)* | Singleton in `resident` block |

---

## Resolved Names Summary

18 of 35 type hashes have been resolved to their original string via `pandemic_hash_m2()`:

```
pandemic_hash_m2("texture")        = 0xF011157A   (36,724 entries)
pandemic_hash_m2("path")           = 0xBCFE6314   ( 5,194 entries)
pandemic_hash_m2("model")          = 0x5B724250   ( 4,407 entries)
pandemic_hash_m2("animation")      = 0x18166555   ( 4,261 entries)
pandemic_hash_m2("layer")          = 0xE6B81A54   (   923 entries)
pandemic_hash_m2("script")         = 0x42498680   (   645 entries)
pandemic_hash_m2("terrainmesh")    = 0x7C569307   (   400 entries)
pandemic_hash_m2("lowresterrain")  = 0x1602815C   (   400 entries)
pandemic_hash_m2("effect")         = 0x5608BD5A   (   314 entries)
pandemic_hash_m2("wavebank")       = 0xF753F6D0   (    95 entries)
pandemic_hash_m2("soundbank")      = 0x9F8BCA10   (    76 entries)
pandemic_hash_m2("binary")         = 0x8F0A54E2   (    14 entries)
pandemic_hash_m2("font")           = 0x99E77ACE   (     9 entries)
pandemic_hash_m2("stringdb")       = 0x39E5E978   (     3 entries)
pandemic_hash_m2("materialtable")  = 0x59B9DF6A   (     1 entry)
pandemic_hash_m2("watermap")       = 0x4D7D30C4   (     1 entry)
pandemic_hash_m2("foliage")        = 0x34612F86   (     1 entry)
pandemic_hash_m2("level")          = 0xEA4829D5   (     1 entry)
```

---

## Unresolved Type Hashes — Contextual Analysis

### `0x600B904E` — ASET type_id 12 — 1,026 entries across 261 blocks

**Likely: Shader or material resource**

UCFX chunk data contains SCRB (shader resource binary?), MTRL, STRM, and INFO sub-chunks. Appears in c3 cell blocks alongside textures and models. Multiple entries per block (up to ~4 per c3 cell). Each entry is a self-contained UCFX container with full rendering pipeline data.

Example blocks: `c30010`, `c30011`, `c30012`, ...

### `0x6310807F` — ASET type_id 30 — 625 entries in `resident` block

**Likely: Global object/entity class registry**

All 625 entries live exclusively in the always-loaded `resident` block. With 625 unique name hashes, this could be a registry of entity class definitions, object templates, or gameplay data tables that must be available at all times.

### `0x665EF13E` — ASET type_id 5 — 86 entries across 38 blocks

**Likely: Dialogue/cinematic/mission flow data**

Found in contract blocks (`mec001_contract`), briefing blocks (`briefing_job_chris`), and mission-flow blocks. Entries are large (44–46 KB), suggesting scripted sequences, dialogue trees, or mission flow graphs.

### `0xE5273C14` — ASET type_id 13 — 77 entries across 69 blocks

**Likely: Entity metadata / physics config**

Small entries (88–172 bytes) in vehicle blocks (`veh_motorcycle_dirtbike2`, `veh_semi`) and weapon blocks (`wpn_sniperrifle`, `wpn_shotgun`). Always co-occurs with `wavebank` and `soundbank` entries in the same blocks. The small size suggests configuration data rather than actual mesh/audio content — possibly physics parameters, vehicle handling data, or weapon stats.

### `0xFE0E8320` — ASET type_id 23 — 60 entries across 29 blocks

**Likely: Compressed effect/shader variant**

UCFX containers with an inner CFX marker followed by zlib-compressed data. Found in c316XX blocks and contract blocks. The CFX inner container and compression suggest compiled shader variants or complex effect definitions.

### `0x1CF649BB` — ASET type_id 34 — 31 entries across 28 blocks

Found in starter blocks (`allstarter0`, `gurstarter0`, `chijob020`) and miscellaneous blocks like `c30690`, `c33209`. May relate to game initialization or tutorial data.

### `0xFA0B8DBC` — ASET type_id 18 — 22 entries in `resident` block

Resident-only type with 22 unique entries. Could be system configuration, UI templates, or global gameplay parameters.

### `0x207359C7` — ASET type_id 11 — 15 entries in `resident` block

Resident-only type with 15 unique entries. Small count suggests global system singletons.

### `0xDE982D61` — ASET type_id 14 — 6 entries in `resident` block

Resident-only type with 6 unique entries. Very small count — likely core system definitions.

### `0xACCE47F2` — ASET type_id 33 — 1 entry in `c33364`

UCFX data contains `sequ` (sequence), SINF (sequence info), and ITEM chunks. This is clearly a **sequence** or **cinematic timeline** asset, but the exact type name is unknown.

### `0xC122545A` — ASET type_id 26 — 1 entry in `musicdata`

Notably, `name_hash == type_hash` (both `0xC122545A`), meaning the asset's name hashes to the same value as the type string itself. Contains UCFX+data with 48 KB of music-related data.

### `0xE8DF4D87` — ASET type_id 4 — 1 entry in `musicdata`

UCFX+data container with 23 KB of music data. The second music-related type in the `musicdata` block.

### Remaining Resident Singletons

| type_hash | ASET type_id | Notes |
|-----------|-------------|-------|
| `0xECE70371` | 31 | Single entry in `resident` |
| `0x3B0AABF8` | 1 | Single entry in `resident` |
| `0x5647C35D` | 8 | Single entry in `resident` |
| `0x140E8728` | 10 | Single entry in `resident` |
| `0xFA46D8A8` | 25 | Single entry in `resident` |

These are unique singleton types that exist only once in the entire WAD, all in the always-loaded `resident` block. They are likely one-off global system resources (world settings, game config, global state, etc.).

---

## Block Category Distribution

How type hashes distribute across block categories:

| Category | Description | Dominant Types |
|----------|-------------|----------------|
| c3 cells (~9,400 blocks) | Spatial streaming cells | texture (×3–4), model (×1–2), terrainmesh (×1), 0x600B904E (×1–4) |
| vz_state (746 blocks) | Game state overlays | layer (×1 each) |
| layers_static (173 blocks) | Static world placement | layer (×1 each) |
| resident (1 block, ~6,500 entries) | Always-loaded global data | path (5,194), 0x6310807F (625), font, materialtable, watermap, foliage, level, + singletons |
| vehicle/weapon (~87 blocks) | Entity definitions | wavebank, soundbank, 0xE5273C14, animation |
| effects (1 block, 314 entries) | Particle/VFX library | effect (314) |
| low_res_terrain (1 block, 400 entries) | Low-res terrain tiles | lowresterrain (400) |
| scripts (~107 blocks) | Lua game logic | script (×1–6 per block) |
| contract/briefing (~38 blocks) | Mission data | 0x665EF13E (dialogue/mission flow) |
| animation (~191 blocks) | Character animations | animation (×1–22 per block) |
| language (3 blocks) | Localization | stringdb |
| musicdata (1 block) | Music definitions | 0xC122545A, 0xE8DF4D87 |
| ps3saveassets (4 blocks) | Platform save icons | binary |

---

## ASET type_id ↔ type_hash Complete Mapping

The ASET chunk uses small integer `type_id` values (0–35) that map 1:1 to `type_hash` values in decompressed block headers:

| type_id | type_hash | Resolved Name | ASET Count |
|---------|-----------|---------------|------------|
| 0 | `0xFA46D8A8` | *(unknown)* | 1 |
| 1 | `0x3B0AABF8` | *(unknown)* | 1 |
| 3 | `0x8F0A54E2` | binary | 14 |
| 4 | `0xE8DF4D87` | *(unknown)* | 1 |
| 5 | `0x665EF13E` | *(unknown)* | 86 |
| 6 | `0xF753F6D0` | wavebank | 95 |
| 7 | `0x39E5E978` | stringdb | 3 |
| 8 | `0x5647C35D` | *(unknown)* | 1 |
| 9 | `0xE6B81A54` | layer | 923 |
| 10 | `0x140E8728` | *(unknown)* | 1 |
| 11 | `0x207359C7` | *(unknown)* | 15 |
| 12 | `0x600B904E` | *(unknown)* | 1,026 |
| 13 | `0xE5273C14` | *(unknown)* | 77 |
| 14 | `0xDE982D61` | *(unknown)* | 6 |
| 15 | `0x99E77ACE` | font | 9 |
| 16 | `0x18166555` | animation | 4,261 |
| 17 | `0xECE70371` | *(unknown)* | 1 |
| 18 | `0xFA0B8DBC` | *(unknown)* | 22 |
| 19 | `0x5B724250` | model | 3,007 |
| 20 | `0xEA4829D5` | level | 1 |
| 21 | `0x9F8BCA10` | soundbank | 76 |
| 22 | `0x1602815C` | lowresterrain | 400 |
| 23 | `0xFE0E8320` | *(unknown)* | 60 |
| 24 | `0xC122545A` | *(unknown)* | 1 |
| 25 | `0xFA46D8A8` | *(unknown)* | 1 |
| 26 | `0xC122545A` | *(unknown)* | 1 |
| 27 | `0xF011157A` | texture | 13,340 |
| 28 | `0xBCFE6314` | path | 5,194 |
| 29 | `0x5608BD5A` | effect | 314 |
| 30 | `0x6310807F` | *(unknown)* | 625 |
| 31 | `0xECE70371` | *(unknown)* | 1 |
| 32 | `0x7C569307` | terrainmesh | 400 |
| 33 | `0xACCE47F2` | *(unknown)* | 1 |
| 34 | `0x1CF649BB` | *(unknown)* | 31 |
| 35 | `0x42498680` | script | 645 |

---

## Name Hash Samples

For each type hash, the first 10 unique `name_hash` values observed. These are `pandemic_hash_m2()` hashes of the original asset names (which are not stored in the WAD).

| type_hash | Unique Names | Sample name_hashes |
|-----------|-------------|-------------------|
| `0xF011157A` | 13,340 | `0x000C9002` `0x000FCC62` `0x00108D8E` `0x00140A1E` `0x001577A0` ... |
| `0xBCFE6314` | 5,194 | `0x00043D4F` `0x0007BF84` `0x000BF11E` `0x00109310` `0x0030C486` ... |
| `0x5B724250` | 3,007 | `0x001616F7` `0x0045B675` `0x00461E64` `0x006243A4` `0x0065B09D` ... |
| `0x18166555` | 4,261 | `0x00312661` `0x004DAFC0` `0x005381C4` `0x006C8D0B` `0x006ECADD` ... |
| `0x600B904E` | 1,026 | `0x000EE46F` `0x007839B1` `0x0115F817` `0x011ACDCC` `0x02569157` ... |
| `0xE6B81A54` | 923 | `0x00360A74` `0x0055E642` `0x0091BD04` `0x00A8865A` `0x00B15690` ... |
| `0x42498680` | 645 | `0x00755CE5` `0x00F56A80` `0x00FA985C` `0x01330EB2` `0x01A266D2` ... |
| `0x6310807F` | 625 | `0x00529F1C` `0x0076650A` `0x00C136F9` `0x019024B5` `0x01C06833` ... |
| `0x7C569307` | 400 | `0x0057041A` `0x0086E8BE` `0x012BFC96` `0x01DB0F57` `0x02C4975F` ... |
| `0x1602815C` | 400 | `0x0035EC36` `0x00DFC11D` `0x02005FA2` `0x023AB4A7` `0x0241A69A` ... |

---

## Verification

Generated by `tools/enumerate_type_hashes.py` which:
1. Parses FFCS header without loading the full WAD into memory
2. Reads INDX entries to compute block offsets (`page_index * 0x8000`)
3. Uses mmap to decompress each block's header via `sges_decompress` (only the first `4 + count*16` bytes)
4. Collects `(type_hash, name_hash)` pairs from each block's entry table

The JSON output with full data is at `output/type_hash_registry.json`.

Type name resolution uses `pandemic_hash_m2()` from `tools/pandemic_hash.py` — the same FNV-1a variant verified against the game executable (166+ call sites).
