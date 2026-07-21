---
status: current
evidence: inferred
verified_on: 2026-07-21
witness: |
  This is a broad synthesis doc; only its measurable core (§2 Binary Formats, the §3.4/§3.5 counts)
  was re-checked against retail game-files/vz.wad this pass, with the throwaway probe
  tools/wad_simulator/crates/mercs2_probe/src/bin/docaudit.rs:
    docaudit -- ffcs    -> INDX 11,370 / DATA / CSUM 7,018 / ASET 30,645 / PTHS 11,370 CONFIRMED;
                           35 distinct ASET type_ids CONFIRMED.
    docaudit -- census  -> 55,429 UCFX entries (doc says 55,425), 35 type_hashes; ALL 18 named
                           type counts in §2.3 match EXACTLY (texture 36,724 ... foliage 1).
    docaudit -- part4   -> CSUM CRC-32(init=0,poly=0xEDB88320,no-final-XOR): 55,428/55,428 chunks
                           verify, 0 bad. Algorithm PROVEN; the doc's "53,765 chunks/10,099 files"
                           undercounts the real 55,428 chunks/11,370 blocks.
    docaudit -- hash    -> script/model/texture/layer/animation type-hashes + ANY=0xED057225 CONFIRMED.
    docaudit -- part6   -> scripts_vz 645 rows across 107 blocks CONFIRMED.
    cdbsizes.ini        -> SceneObject 161,280 / HibernationControl 14,080 / Road 4,608 /
                           TerrainObject 1,024 / AiPatrol 768 all CONFIRMED (§3.5).
  §2.4 (ASET row layout) is WRONG and corrected inline — it repeats the "sub-entry offset" /
  "dependency hash" reading that docs/aset_format.md RETRACTED on 2026-07-21. §3.4 placement counts
  are stale and corrected inline. §1 (Mercs1/Saboteur lineage), §4 (DLC port status), §5 (toolkit),
  §6 (sandbox plan) and §7 (next steps) are NOT verifiable from vz.wad and are UNTOUCHED — treat them
  as project narrative, not measured fact. Hence evidence: inferred overall (proven only in §2).
---

# Comprehensive Engine Understanding — Mercenaries 2 Reverse Engineering Synthesis

> **Date:** 2026-05-22 · **Audited:** 2026-07-21
> **Purpose:** Single source of truth synthesizing ALL research across the project.
> **Scope:** Engine architecture, binary formats, asset pipeline, DLC integration,
> reverse engineering toolkit, debug sandbox, and next steps.
>
> **AUDIT (2026-07-21).** Only §2 and the §3.4/§3.5 counts were re-measured against retail `vz.wad`
> (see front-matter `witness`). §2's format facts hold up well — the 18 type-hash counts in §2.3 and
> the five `cdbsizes.ini` figures in §3.5 reproduce **exactly**, and the CSUM algorithm verifies with
> 0 failures across all 55,428 chunks. Two things are wrong and fixed inline: **§2.4 (ASET row
> layout)** repeats a reading that `docs/aset_format.md` retracted the same day, and **§3.4** carries
> stale placement counts. §§1, 4–7 are synthesis/plans not checkable from WAD data and were left as
> written.

---

## Table of Contents

1. [Engine Architecture Overview](#1-engine-architecture-overview)
2. [Binary Format Mastery](#2-binary-format-mastery)
3. [Asset Pipeline Understanding](#3-asset-pipeline-understanding)
4. [DLC Integration Status](#4-dlc-integration-status)
5. [Reverse Engineering Toolkit](#5-reverse-engineering-toolkit)
6. [Debug Sandbox / Virtual Engine](#6-debug-sandbox--virtual-engine)
7. [Actionable Next Steps](#7-actionable-next-steps)

---

## 1. Engine Architecture Overview

### 1.1 The Zero Engine Lineage

Pandemic Studios developed three major titles on closely related engine technology:

```
Mercenaries: Playground of Destruction (2005) — "Zero Engine" / Pebble platform layer
    │
    │  Hash algorithm gained finalization: ^0x2A * FNV_PRIME
    │  Lua upgraded 5.0.1 → 5.1
    │  Asset containers evolved: flat .dsk → FFCS .wad + UCFX
    │  Compression replaced: LZSS → sges (raw deflate)
    │  Physics upgraded: Havok 2.2 → Havok 5.5
    │  Animation system replaced: Zephyr → Havok Animation
    ▼
Mercenaries 2: World in Flames (2008) — Evolved Pandemic engine
    │
    │  Archive restructured: FFCS → MP00 megapacks + SBLA sub-packs
    │  Mesh format flattened: UCFX chunk tree → flat MESH binary
    │  Triangle strips → triangle lists
    │  Materials externalized: inline MTRL → standalone .materials (WSAO)
    │  Lua packaged separately: embedded BINN → standalone .luap
    │  DLC simplified: WAD overlay patching → folder-based DLC/01
    ▼
The Saboteur (2009) — "WildStar" / final Pandemic engine
```

### 1.2 Mercenaries 1 Architecture (from source code analysis)

The Mercs 1 source reveals a **two-layer architecture**:

| Layer | Prefix | Role |
|-------|--------|------|
| **RedEngine** | `Red*` | Core reusable engine: rendering, world management, asset I/O, terrain, effects |
| **RetroStrike** | `Rs*` | Game-specific logic: actors, AI, missions, Lua scripting, vehicles, combat |
| **Pebble** | `Pbl*` | Platform abstraction: file I/O, hashing, threading, compression, math types |

Key subsystems identified across all three games:

| Subsystem | Mercs 1 | Mercs 2 | Saboteur |
|-----------|---------|---------|----------|
| Virtual filesystem | `RedVirtualDisk` (64 stacked .dsk files, last-opened wins) | FFCS WAD system (same semantics, richer structure) | Megapack hash lookup chain |
| Hash function | `PblHash()` (FNV-1a + `\|0x20`, no finalization) | `pandemic_hash_m2()` (+ `^0x2A * prime`) | `hash::GetHash()` — **identical to Mercs 2** |
| Scripting | Lua 5.0.1 (source text, LZSS compressed) | Lua 5.1 (precompiled bytecode, float build) | Lua 5.1 (bytecode in .luap) |
| Script loading | `Utility_LoadUtilityScript()` via name hash | `import("name")` / `_SYS._IMPORT` (VA `0x005AE2D0`) | Same Lua 5.1 bytecode mechanism |
| World entities | Spore system (16k entities, dormant/awake/dead) | COMP-based placements (62k layers_static + 3.5k vz_state) | MAP6 DynamicPackDesc |
| Terrain | Single `RedTerrain` | 20×20 tile grid (`low_res_terrain`) + per-cell high-res | HEI1 heightfield tiles |
| Physics | Havok 2.2/2.3 | Havok 5.5 | Havok (version unconfirmed) |
| Animation | Custom Zephyr system | Havok Animation (interleaved/delta/wavelet) | Havok AP0L packs with full FSM |
| Compression | LZSS (PblCompress) | `sges` (raw deflate, multi-segment) | `sges` — **byte-for-byte identical** |
| Mission system | `RsMissionDataManager` (C++ config, 64 missions max) | `tMissionData` Lua table (unlimited) | Not analyzed |

### 1.3 Lua API Continuity

The Mercs 1 source exposes **350+ registered Lua C functions** organized by subsystem:
`Debug_*`, `Ui_*`, `ActorVehicle_*`, `Ai_*`, `Faction_*`, `Camera_*`, `Mission_*`, `Event_*`, `Player_*`, `Objective_*`, `Utility_*`, `Audio_*`, `Global_*`.

Mercs 2 evolved this into a **table-based** `_SYS.*` namespace but preserved the fundamental patterns:
- `Utility_LoadUtilityScript()` → `import()` / `_SYS._IMPORT`
- `Utility_SetCurrentMissionData()` → `UnlockMission()` / `ActivateMission()`
- Event polling system → similar event callbacks
- Master/slave script architecture → `wifmissionflow` as master orchestrator
- `ScriptInit()` entry point — **confirmed identical** across both games

### 1.4 Confirmed Cross-Game Identities

| Feature | Verification Method | Confidence |
|---------|-------------------|-----------|
| Hash algorithm identical (Mercs 2 ↔ Saboteur) | `GetHash("ANY") == pandemic_hash_m2("ANY") == 0xED057225` | **100%** |
| `sges` compression identical | Same header (16B), chunk desc (8B), raw deflate, 64KB sentinel | **100%** |
| Lua 5.1 bytecode across Mercs 2 + Saboteur | Same LuaQ header, same number size | **100%** |
| `pandemic_hash_m2("animation") == 0x18166555` | Matches animgroup record table magic constant | **100%** |
| "Last opened wins" WAD semantics | Confirmed in Mercs 1 source + Mercs 2 binary analysis | **100%** |

---

## 2. Binary Format Mastery

### 2.1 Complete Format Hierarchy

```
vz.wad (2.57 GB) — FFCS archive
├── FFCS Header: magic "FFCS" + version + chunk rows (12B each)
│   ├── INDX: 11,370 × 12B entries (page_index × 0x8000 = absolute offset)
│   ├── DATA: 2.4 GB compressed blocks
│   ├── CSUM: 7,018 entries (purpose partially unknown)
│   ├── ASET: 30,645 × 16B rows (asset hash → block + type mapping)
│   └── PTHS: 11,370 null-separated path strings + 258B mandatory trailer
│
├── Each block compressed with sges:
│   ├── Header: magic "sges" + version(u16×2) + uncompressed_size + compressed_hint
│   ├── Segment table: N × 8B (compSize, uncompSize, offset)
│   └── Payload: raw deflate segments (zlib windowBits -15), 16B-aligned
│
└── Decompressed block structure:
    ├── Entry table: count(u32) + count × 16B (name_hash, type_hash, field_c, chunk_size)
    └── Concatenated UCFX chunks, each with 8B CSUM trailer
        └── UCFX: magic(4B) + header_fields(4×u32) → typed chunk tree
```

### 2.2 UCFX Chunk Types (Fully Decoded)

| Tag | Purpose | Key Fields |
|-----|---------|-----------|
| **GEOM** | Geometry container | Houses MESH, PRMG, STRM, IBUF |
| **MESH** | Mesh group descriptor | Submesh count, topology |
| **PRMG** | Primitive group | Draw call ranges (start_index, index_count) |
| **STRM** | Vertex stream buffer | Raw vertex data (f16 positions, UVs, normals) |
| **IBUF** | Index buffer | u16 triangle strips (degenerate separators) |
| **INFO** | Texture header | width, height, mip_count, FourCC, total_size |
| **BODY** | Texture payload | DDS pixel data |
| **MTRL** | Material table | 104B preamble + per-material records (texture hashes) |
| **PRMT** | Primitive-material binding | 16B per draw call (material_idx, start, count) |
| **HIER** | Skeleton/hierarchy | 176B per node (local transform + parent chain) |
| **INDX** | MESH→HIER mapping | N × u16 (mesh_group_i → hier_node_i) |
| **SWIT** | Damage state switches | Pairs of node indices (pristine/destroyed) |
| **NAME** | Named asset string | Null-terminated ASCII |
| **CHDR** | Chunk header table | ECS container for placement data |
| **COMP** | Component data | info + schm + data children (placement records) |
| **BINN** | Binary payload | Contains Lua 5.1 bytecode (LuaQ) |
| **CSUM** | Integrity trailer | CRC-32 (poly 0xEDB88320, init=0, no final XOR) |

### 2.3 The Type Hash System

The `type_hash` field in decompressed block entry headers categorizes all ~~55,425~~ **55,429** UCFX entries across 35 unique types. The ASET chunk's `type_id` (integer 0–35) maps 1:1 to these hashes.

*RE-VERIFIED 2026-07-21 (`docaudit -- census`): 55,429 entries (not 55,425 — a 4-entry undercount),
35 distinct type_hashes, and the ASET side likewise has 35 distinct type_ids. **All 18 named counts
in the table below reproduce exactly.** Note ASET `type_id` runs **0–35 with 35 values present**, not
a dense 0..35 — id 2 is absent in retail `vz.wad`.*

**18 of 35 resolved by name:**

| type_hash | Name | Count | Description |
|-----------|------|-------|-------------|
| `0xF011157A` | texture | 36,724 | DDS texture data (dominates c3 cells) |
| `0xBCFE6314` | path | 5,194 | Registry/config entries (all in `resident`) |
| `0x5B724250` | model | 4,407 | Mesh geometry (HIER, MTRL, GEOM, MESH) |
| `0x18166555` | animation | 4,261 | Havok 5.5 packfile data |
| `0x600B904E` | *(unknown)* | 1,026 | Shader/material resources (SCRB+MTRL+STRM) |
| `0xE6B81A54` | layer | 923 | Placement data (vz_state + layers_static) |
| `0x42498680` | script | 645 | Lua 5.1 bytecode (BINN chunks) |
| `0x7C569307` | terrainmesh | 400 | Per-cell terrain mesh |
| `0x1602815C` | lowresterrain | 400 | 20×20 terrain grid tiles |
| `0x5608BD5A` | effect | 314 | Particle/VFX definitions |
| `0xF753F6D0` | wavebank | 95 | Audio wave bank data |
| `0x9F8BCA10` | soundbank | 76 | Sound bank data |
| `0x8F0A54E2` | binary | 14 | Raw binary (ps3saveassets) |
| `0x99E77ACE` | font | 9 | Font data |
| `0x39E5E978` | stringdb | 3 | Localized string database |
| `0x59B9DF6A` | materialtable | 1 | Singleton in `resident` |
| `0x4D7D30C4` | watermap | 1 | Singleton in `resident` |
| `0x34612F86` | foliage | 1 | Singleton in `resident` |

**17 unresolved** — primarily resident-only singletons and specialized types. The Saboteur's `saboteur_strings.txt` (50k+ asset names) could help resolve these through bulk hash comparison.

### 2.4 ASET Row Layout (16 bytes, verified)

**CORRECTION (2026-07-21) — the `+4` and `+8` descriptions below are the reading that
`docs/aset_format.md` RETRACTED on 2026-07-21** (it had been marked "Verified: Yes" for two months
and was wrong). `secondary_ref` does **not** hold a "streaming dependency hash", and
`packed_block_ref` low16 is **not** a "sub-entry offset". Both u32s hold **block indices**; together
they encode the asset's whole LOD chain as four packed 16-bit block references
`[_P000 | _P001][_P002 | _P003]`, with `0xFFFF` as the per-slot sentinel.

| Offset | Field | ~~Old (wrong) description~~ → Correct description |
|--------|-------|-------------|
| +0 | `asset_hash` | `pandemic_hash_m2(name)` — FNV-1a with `\|0x20` + `^0x2A * prime` *(unchanged, correct)* |
| +4 | `secondary_ref` | ~~`0xFFFFFFFF` = single-block; otherwise streaming dependency hash~~ → `[hi16 = _P002 block][lo16 = _P003 block]`; `0xFFFF` per half = "no such LOD" |
| +8 | `packed_block_ref` | ~~High 16 = block index; low 16 = sub-entry offset~~ → `[hi16 = _P000 primary block][lo16 = _P001 block]` — **low16 is a finer-LOD block index, not an offset** |
| +12 | `type_id` | Integer discriminator, maps to type_hash *(unchanged, correct)* |

An asset is single-block only when **both** words are fully sentinel — use
`AsetEntry::is_single_block()` (both `lo16 == 0xFFFF` **and** `secondary_ref == 0xFFFFFFFF`), never
`is_primary()` alone.

Measured 2026-07-21 (`docaudit -- ffcs`), which is what disproves the old reading: of 30,645 rows,
`secondary_ref == 0xFFFFFFFF` in 22,196 and `packed_block_ref` lo16 `== 0xFFFF` in 19,847. Of the
**10,798** rows whose lo16 is non-sentinel, **all 10,798** are valid INDX block indices (`< 11,370`) —
a "sub-entry offset" would not be bounded by the block count, a sibling LOD block index is. See
`docs/aset_format.md` and `AsetEntry::lod_chain` in `mercs2_formats::ffcs`.

30,645 rows total in retail `vz.wad` *(confirmed)*. Block index (hi16 of +8) verified by decompressing
blocks and matching entry `name_hash` values *(confirmed)*.

### 2.5 CSUM Integrity Algorithm

```
Algorithm:  CRC-32, reflected I/O
Polynomial: 0xEDB88320 (reflected) / 0x04C11DB7 (normal)
Init:       0x00000000
Final XOR:  0x00000000
Input:      From UCFX tag start to byte before CSUM tag (inclusive)
```

Verified against ~~**53,765 chunks across 10,099 block files**~~. This is neither standard CRC-32 (init=0xFFFFFFFF) nor JAMCRC — it is a custom variant unique to this engine.

**RE-VERIFIED 2026-07-21 — the algorithm is exactly right; the coverage numbers were low.** Recomputed
the CSUM trailer of **every** UCFX container in **every** block of retail `vz.wad`
(`docaudit -- part4`): **55,428 of 55,429** containers carry an 8-byte `CSUM` trailer and **all
55,428 verify** with init=0 / poly=0xEDB88320 / no final XOR — **0 mismatches**. The real coverage is
55,428 chunks across 11,370 blocks, not "53,765 / 10,099". *(Note: this custom "init=0" form is
identically `~standard_crc32` — i.e. `(zlib.crc32(data) ^ 0xFFFFFFFF)` — because the standard
init=0xFFFFFFFF and final-XOR cancel; it is a naming difference, not a different polynomial.)*

### 2.6 What The Saboteur Confirms

| Finding | Impact |
|---------|--------|
| Hash identical (byte-for-byte, compile-time assertion proves it) | Our `pandemic_hash_m2` is definitively correct |
| `sges` identical (same 16B header, 8B chunk descriptors, raw deflate) | No further decompression work needed |
| Vertex positions use half-float (f16) | Confirms our detection path |
| Texture slot order: diffuse → specular → normal | Validates MTRL parsing |
| `decl` chunk may contain vertex format bitfield with `0x1B` tag byte | Actionable: could replace stride-guessing heuristics |
| DLC simplified to folder-based in Saboteur | Confirms WAD overlay was a complex legacy approach |

### 2.7 Remaining Unknowns

| Gap | Impact | Path to Resolution |
|-----|--------|-------------------|
| 17 unresolved type_hashes | Low (singletons/rare types) | Bulk hash comparison with Saboteur strings |
| FFCS-level CSUM chunk purpose | Low | Its offset exceeds file size; may be a content hash |
| MTRL 104-byte preamble fields | Medium | Compare against Saboteur's WSAO shader hashes |
| `decl` chunk vertex format bitfield | Medium | Look for `0x1B` tag byte in decl payloads |
| Animation FSM data location | Medium | Search for SEQC/TRAN/BANK patterns in raw blocks |
| `0x600B904E` type (shader resource) | Low | Structural analysis of SCRB chunks |

---

## 3. Asset Pipeline Understanding

### 3.1 WAD → Block → UCFX → Resource Flow

```
import("scriptname")
  │
  ├─ 1. hash = pandemic_hash_m2("scriptname")     [FNV-1a + |0x20 + ^0x2A * prime]
  │
  ├─ 2. Scan WADs in reverse-open order:
  │     for wad in reversed(mounted_wads):
  │       if hash in wad.ASET:
  │         block_idx = (wad.ASET[hash].packed_block_ref >> 16) & 0xFFFF
  │         break
  │
  ├─ 3. Look up INDX[block_idx] → page_offset, page_count
  │
  ├─ 4. Read DATA[page_offset × 0x8000 : + page_count × 0x8000]
  │     Decompress sges → decompressed block data
  │
  ├─ 5. Parse block header: count(4) + count × entry(16)
  │     Find entry where entry.name_hash == hash
  │
  ├─ 6. Verify CSUM: CRC-32(UCFX body) == stored CSUM value
  │     If mismatch → block is silently dropped (no crash, just missing)
  │
  ├─ 7. Locate payload within UCFX chunk (BINN for scripts, GEOM for meshes, etc.)
  │
  └─ 8. Process: scripts → luaL_loadbuffer + lua_pcall
                 meshes → D3D9 vertex/index buffers
                 textures → D3D9 surfaces
```

This flow was reconstructed from:
- Mercs 1 `RedVirtualDisk.cpp` source code
- Mercs 2 EXE binary analysis (VA `0x005AE2D0` for `_SYS._IMPORT`)
- PS3 EBOOT disassembly cross-reference
- `dlc_enable.c` ASI hook development

### 3.2 The Overlay/Patching Mechanism

The engine loads WADs in sequence with **last-opened-file-wins** semantics:

1. Base WAD (`vz.wad`) mounted first — 11,370 blocks, 30,645 ASET entries
2. Patch WAD (`vz-patch.wad`) mounted second — shadows base ASET entries by hash

For any `import("name")` call:
- Engine hashes the name
- Searches WADs in **reverse mount order** (patch first, base second)
- First ASET match wins — the asset loads from that WAD

This is the mechanism our DLC port exploits: inject DLC blocks into `vz-patch.wad` and their ASET entries shadow (override) or extend the base WAD's asset set.

**Critical constraint:** The PTHS chunk in patch WADs requires a mandatory 258-byte null-terminated trailer marker. Omitting it causes a black-screen hang.

### 3.3 The Lua Scripting Layer

**Script storage:** Lua 5.1 bytecode (float build, 4-byte `lua_Number`) stored in BINN chunks within UCFX containers in `scripts_vz` block and other script blocks. 645 total script entries across 107 blocks.

**Script loading chain:**
1. Engine boots → loads `vz` masterscript (hashed name lookup in ASET)
2. Masterscript's `ScriptInit()` calls `import("wifmissionflow")`
3. `wifmissionflow` is the **master orchestrator** — imports mission data, equipment data, faction scripts
4. Individual missions loaded as needed: `*con*` (contracts), `*job*` (bounties)
5. Each contract script calls `inherit("MrxTaskContract")` (engine builtin base class)

**Key difference from Mercs 1:** Scripts are precompiled bytecode (not source text). The `import()` function is game-registered (not standard Lua `require`). Engine builtins like `MrxTaskContract` are loaded from a `scripts_common` block or compiled into the EXE — they cannot be resolved from WAD data alone.

### 3.4 The ECS and Placement System

~~**62,458 static placements**~~ **62,624 static placements** in `layers_static` (7.97 MB composite container with 173 UCFX sub-blocks):

| Component | Records | Purpose |
|-----------|---------|---------|
| Transform | 62,624 | 42-byte records: entity_key + XYZ position + unit quaternion |
| Name | ~~60,136~~ **62,143** | Entity name strings with hex IDs |
| LightObject | 1,197 | Point light definitions (ECS merge) |
| LowResTerrainObject | 400 | Tile→mesh hash mapping for 20×20 terrain grid |
| HibernationControl | 2,625 | LOD/streaming parameters |
| + other COMP types (43 distinct names total) | ~~10,030~~ **14,335** | Various ECS data |

*Corrected 2026-07-21 (`docaudit -- layers`): the header count 62,458 contradicted this doc's own
62,624 Transform row; 62,624 is right. Name matches rose to 62,143 and ECS records to 14,335 under the
Rust loader (`mercs2_formats::placement`). See `docs/placement_data_format.md` §2.10 for the full
before/after table and the parser fixes behind it. "43" is the number of distinct COMP type-names, not
a per-sub-block count.*

~~**~3,620 conditional placements**~~ **37,867 conditional placements** across 746 `vz_state` overlay files:

*Corrected 2026-07-21 (`docaudit -- vzstate`): the "~3,620" was ~10× low — an artefact of the
retracted "flgs record" heuristic in `docs/placement_data_format.md` §3.3. vz_state placements are the
same 42-byte `Transform` COMP records as layers_static; 744 of 746 blocks carry one, totalling
37,867 records.*
- Encode game state variants (pristine/ruined/destroyed/staging)
- Applied as delta overlays controlled by Lua scripts at runtime
- Faction-specific: chi, pir, gur, oil, all, pmc, vza

**Coordinate system:** Left-handed Y-up (D3D9 game space). X ≈ ±3900 (East-West), Y ≈ -103 to +393 (elevation), Z ≈ ±3900 (North-South). Units are meters (verified: Parque Central towers = 220 game units ≈ 225m real-world).

**Rotation encoding:**
- `layers_static`: Full unit quaternion (qx, qy, qz, qw) — verified `|q|² ≈ 1.0` across all 62k records
- `vz_state`: Single `sin(yaw)` value (sign-ambiguous cos reconstruction)
- ~16% of entities have non-trivial pitch/roll (tilted objects)

### 3.5 World Data Architecture

```
vz.wad (11,370 blocks)
├── resident (1 block, ~6,500 entries)    — Always-loaded: paths, fonts, global registries
├── c3XXXX (9,467 blocks)                  — Spatial grid: geometry + textures per cell
├── vz_state (746 blocks)                  — Conditional placement overlays
├── layers_static (1 block, 173 sub-blocks) — Base world placement (62k entities)
├── scripts_vz (1 block, 114 entries)      — Compiled Lua game logic
├── low_res_terrain (1 block, 400 tiles)   — 20×20 terrain grid mesh
├── effects (1 block, 314 entries)         — Particle/VFX library
├── animgroups (~191 blocks)               — Havok 5.5 animation data
└── Other (vehicles, buildings, roads, audio, etc.)
```

From `cdbsizes.ini`: **~161,280 total SceneObjects** preallocated, 14,080 hibernation slots, 4,608 road segments, 1,024 terrain objects, 768 AI patrols.

*CONFIRMED 2026-07-21 against `docs/game_config/cdbsizes.ini`, all five exactly: `SceneObject 161280`,
`HibernationControl 14080`, `Road 4608`, `TerrainObject 1024`, `AiPatrol 768`. The block-taxonomy
list above also mostly reproduces (`docaudit -- census/part3`): c3 9,467 ✓, vz_state 746 ✓,
layers_static 1×173 ✓, scripts_vz 1 block / 114 entries ✓, resident block 7,018 entries (the "~6,500"
is low), low_res_terrain 401 entries (not 400 — one is unreferenced, see placement §2.9),
effects block 360 entries of which 314 are effect-typed. "animgroups ~191 blocks" measured as 129
paths containing "animgroup" — treat ~191 as loose.*

---

## 4. DLC Integration Status

### 4.1 Background: The "Blow It Up Again" DLC

The DLC was **never released on PC** — it was PS3/Xbox 360 only. Our project ports the Xbox 360 DLC content to PC by:
1. Extracting DLC blocks from Xbox 360 STFS archive
2. Converting big-endian UCFX containers to little-endian
3. Packaging into a PC-compatible `vz-patch.wad`
4. Bootstrapping the DLC script loading via ASI hook

### 4.2 Current State (as of 2026-05-22)

| Component | Status |
|-----------|--------|
| Xbox 360 DLC block extraction | **Complete** — `tools/x360_dlc_io.py` |
| Big-endian → little-endian conversion | **Complete** — `tools/ucfx_be_to_le.py` |
| UCFX container headers (CHDR, COMP, MESH, STRM, IBUF) | **Swapped** |
| Lua bytecode endian swap (BINN chunks) | **Complete** — recursive proto tree walker |
| Patch WAD assembly (FFCS structure) | **Complete** — `tools/ffcs_patch_wad.py` |
| ASET/INDX/PTHS generation | **Complete** |
| CSUM generation | **Complete** — verified CRC-32 (init=0) algorithm |
| ASI bootstrap plugin | **Complete** — `tools/dlc_enable_asi/dlc_enable.c` |
| SecuROM bypass | **Complete** — `make crack-game` |
| Game loads WAD without hanging | **Verified** (DLC-only WAD passes after stripping string mods) |
| Full freeplay session with DLC WAD | **Verified** (30+ min, missions unlock, no crash) |
| DLC contracts actually register | **In progress** — ASI calls `import("dlc01")` but Lua globals issue |

### 4.3 The Architectural Mismatch Discovery

**Critical finding:** The Xbox 360 DLC uses a `package.cfg` with `scriptname DLC01` — a top-level DLC master script that the console's `SetMasterScriptName` mechanism loads. The PC build has no equivalent activation path because:

1. The "Extras" menu was gated behind EA's defunct online servers (`IsOnlineConnected()` returns false)
2. No existing community tool addresses DLC activation on PC
3. The DLC was never officially ported to PC

**Solution architecture:**
- WAD-level: Inject `dlc01` script as entry 115 in `scripts_vz` block (zero modifications to retail entries)
- ASI-level: Hook `_SYS._IMPORT` (VA `0x005AE2D0`) to call `import("dlc01")` after world loads

### 4.4 Bisect Testing Results

| Row | Variant | Result | Finding |
|-----|---------|--------|---------|
| 0 | No patch (baseline) | Pass | Game works without patches |
| 1 | Full fresh-rebuilt WAD | Hang | String mods caused hang (not DLC blocks) |
| **2** | DLC-only (no scripts_vz edits) | **Pass (30 min)** | 2,196 DLC blocks load fine |
| **3** | Bootstrap-only (string mods stripped) | **Pass** | Bootstrap itself is safe |
| 4 | DLC + ASI (VZ_LOAD mode) | Pass + Lua error | Globals table incomplete |
| 5 | DLC + direct C call | Freeze | Re-entrancy during layer loading |
| 6 | DLC + 30s delay | Pass | Direct C disabled; timing safe |
| **7** | Full WAD + wifmissionflow hook | Freeze at Fiona | **BE Lua bytecode** crashed VM |
| 8 | Full WAD + Lua endian swap | Pending | Fix implemented: `_swap_lua51_bytecode` |
| 9 | Nohook (entry 115 only + ASI) | Pending | Zero edits to retail; ASI calls `import("dlc01")` |

**Key conclusion:** The WAD overlay mechanism works perfectly. DLC blocks load without issue. The hang was caused by demo-specific string modifications to the `scripts_vz` block, not by DLC content itself.

### 4.5 Remaining Blockers

1. **Lua globals incomplete:** The thread globals table (`l_gt` at offset 68 in `lua_State`) lacks standard builtins (`type`, `error`, `pcall`). Our injected chunks fail because they run in a different environment than game scripts.

2. **Row 9 approach (most promising):** Leave all 114 retail `scripts_vz` entries byte-identical. Append `dlc01` as entry 115 with top-level imports (no `ScriptInit()` wrapper). ASI calls `import("dlc01")` via the game-registered `import` global — avoiding all globals/builtins issues.

3. **Vertex data byte-swap:** STRM vertex buffers from Xbox 360 still need per-format swapping (f16, f32, u8 mixed). Required for DLC geometry to render correctly.

4. **Texture de-swizzle:** Xbox 360 GPU-specific tiling needs to be undone for DLC textures.

---

## 5. Reverse Engineering Toolkit

### 5.1 The Ghidra Annotation Pipeline

A two-phase workflow cross-references the Mercs 2 PC binary against Mercs 1 source code:

**Phase 1 — Pre-analysis** (Python, runs standalone):
```bash
make ghidra-annotate-preanalysis
# → scripts/mercs2_annotations.json
```
Scans ~600 Mercs 1 source files, producing:
- 350+ Lua C function registration entries from `kLuaBaseFns[]`
- ~300+ MSVC RTTI class patterns (`.?AV` prefix)
- ~800+ high-value debug strings
- Class hierarchy relationships
- Known VAs from ASI research (15+ addresses)

**Phase 2 — Ghidra annotation** (Jython, runs inside Ghidra):
- Labels known VAs: `_SYS._IMPORT` at `0x005AE2D0`, `luaL_loadbuffer` at `0x00860240`, etc.
- Cross-references .rdata strings against Mercs 1 source locations
- Scans for `luaL_Reg` struct arrays (pattern: string_ptr + code_ptr pairs, null terminator)
- Finds RTTI type descriptors and vtable references
- Propagates labels to callers of known functions

**Target binary:** Cracked retail EXE (53,482,288 bytes).

### 5.2 External Tools (Prioritized)

**Immediate value:**

| Tool | Why |
|------|-----|
| **unluac** | Direct Lua 5.1 decompiler — exposes mission logic from .luac files |
| **HavokNoesis** | PredatorCZ's gold-standard Havok 5.5 binary viewer/parser |
| **Havok IO (Blender)** | Import .hkx animations into Blender for visualization |
| **atlas** | FNV-1a batch hash tool — cross-validate and brute-force unknown hashes |
| **010 Editor / ImHex** | Binary format template authoring for FFCS/UCFX documentation |

**Pandemic-specific leads:**

| Tool | Why |
|------|-----|
| **SW:Battlefront Unpacker** | Same studio — potential FFCS format DNA overlap |
| **SW:Battlefront Mod Tools** | Official Pandemic tools with shared engine knowledge |
| **SaboteurToolset** (PredatorCZ) | Confirmed identical hash + sges; reference implementation for evolved formats |

**Modding framework:**

| Tool | Why |
|------|-----|
| **Reloaded-II** | Superior mod loader framework (replaces Ultimate ASI Loader) |
| **Reloaded.Hooks** | Robust x86 hooking library (replaces manual detours in dlc_enable.c) |

### 5.3 The Saboteur Toolset as Reference Implementation

The [SaboteurToolset](https://github.com/PredatorCZ/SaboteurToolset) provides working C++ implementations for:
- The hash function (`hash::GetHash` — **proven identical**)
- `sges` decompression (`compressed.hpp` — **proven identical**)
- Mesh parsing (MESH format with explicit vertex format bitfield)
- Material parsing (WSAO with WSMA/WSTX/WSPA/WSCP blocks)
- Animation pack parsing (AP0L with ANIM/SEQC/TRAN/BANK/SSP0)
- Texture conversion (DTEX → DDS)
- Lua bytecode packaging (.luap format)
- World/map parsing (MAP6 + DynamicPackDesc)

While formats evolved between games, the **algorithms and design patterns** transfer directly. The vertex format bitfield (`constTag=0x1B`) and material preamble structure are particularly actionable for improving our UCFX parsers.

### 5.4 Cross-Referencing Strategies

**Mercs 1 source → Mercs 2 binary:**
1. Extract Lua function names from `kLuaBaseFns[]` arrays in source
2. Search Mercs 2 .rdata for the same string literals
3. The string's XREF leads to the registration code → function VA

**Saboteur strings → Mercs 2 ASET:**
1. Hash all 50k+ entries in `saboteur_strings.txt` with `pandemic_hash_m2`
2. Compare against unresolved ASET hashes in our WAD
3. Shared naming conventions (vehicles, weapons, shaders) should yield matches

**PS3 EBOOT ↔ PC EXE:**
- Both share the same engine code (different compiler, same logic)
- PS3 EBOOT analyzed via `make ghidra-ps3-eboot`
- Function signatures identified in one can be searched in the other

---

## 6. Debug Sandbox / Virtual Engine

### 6.1 Purpose and Motivation

Every DLC patch build requires deploying to a Windows VM and watching the game crash or hang. The debug sandbox eliminates this feedback loop by **emulating the engine's module resolution and Lua script loading in Python**.

It catches:
- Missing ASET entries (import hangs indefinitely)
- Big-endian bytecode in little-endian WADs (Xbox→PC port bug — **directly caused row 7 freeze**)
- CSUM mismatches (engine silently drops corrupted blocks)
- Broken import chains (script A imports B, B doesn't exist)
- Mission data referencing nonexistent contracts
- Circular dependencies

### 6.2 Architecture

```
┌─────────────────────────────────────────────────────┐
│  tools/sandbox.py — CLI (validate, trace, graph)     │
└───────────┬───────────────┬──────────────────────────┘
            │               │
            ▼               ▼
┌───────────────┐ ┌─────────────────┐ ┌──────────────────┐
│ VirtualDisk   │ │ ScriptResolver  │ │ ValidationEngine │
│ WAD overlay   │ │ import() trace  │ │ 18 check suite   │
│ ASET merge    │ │ bytecode parse  │ │ text/JSON report │
│ block cache   │ │ dep graph build │ │                  │
└───────────────┘ └─────────────────┘ └──────────────────┘
```

**VirtualDisk** emulates `RedVirtualDisk`:
- Mount N WADs in sequence (last-entry-wins ASET merge)
- Parse INDX for block locations
- Decompress blocks on demand with LRU cache (32 blocks, ~30MB)
- Parse block entry tables

**ScriptResolver** traces `import()` resolution:
- Hash name → ASET lookup → block → entry → bytecode extraction
- Walk Lua 5.1 proto tree for string constants
- Heuristic import/inherit detection from constant pool
- Recursive BFS with cycle detection

**ValidationEngine** runs 18 checks in priority order:
- Phase 1 (crash blockers): `aset_missing`, `csum_mismatch`, `bytecode_big_endian`
- Phase 2 (load blockers): `import_missing`, `aset_type_mismatch`, `block_entry_mismatch`
- Phase 3 (integrity): `mission_data_invalid`, `import_cycle`
- Phase 4 (diagnostics): `aset_shadow`, `bytecode_number_size`

### 6.3 Relation to Mercs 1 Understanding

The sandbox design is a direct Python implementation of the resolution path documented in Mercs 1 source:

| Mercs 1 source construct | Sandbox equivalent |
|--------------------------|-------------------|
| `RedVirtualDisk::RequestAsset(nameHash, typeHash)` | `VirtualDisk.lookup_asset(name)` |
| Library search in reverse-open order | ASET merge with last-entry-wins |
| `TypeDirectory` binary search | `packed_block_ref >> 16` → INDX lookup |
| `PblStreamManager` async read | `get_block_data()` (sync, cached) |
| LZSS / sges decompress | `sges_decompress.decompress_sges_block()` |
| `RsLuaScript::Find(hash)` | `find_entry_in_block(aset_entry, name_hash)` |

### 6.4 Modding SDK Foundation

The sandbox is designed as the kernel of a future Mercenaries 2 Modding SDK:

```
my_script.lua → luac → UCFX wrap (BINN + CSUM) → block → sges compress → patch WAD
                                                                              │
                                                          sandbox.py validate ←┘
                                                                PASS ✓ → deploy
```

Each step already has a corresponding tool. The sandbox provides the validation gate.

### 6.5 Implementation Estimate

**Total: 11-17 days** (one developer, sequential). Phases can be parallelized:
- Phase 1 (VirtualDisk + basic resolver): 3-4 days
- Phase 2 (bytecode analysis + dep graph): 2-3 days
- Phase 3 (18 validation checks): 2-3 days
- Phase 4 (CLI + Makefile integration): 1-2 days
- Phase 5 (mission data parser): 2-3 days
- Phase 6 (SDK polish): 1-2 days

---

## 7. Actionable Next Steps

### 7.1 Immediate Priority (This Week)

| # | Task | Depends On | Impact |
|---|------|-----------|--------|
| 1 | **Test Row 9 bisect** (nohook WAD + ASI bootstrap) | DLC WAD built | Proves/disproves DLC activation path |
| 2 | **Test Row 8** (full WAD with Lua endian swap) | `_swap_lua51_bytecode` complete | Validates Lua bytecode swap fix |
| 3 | **Run unluac** on extracted .luac from `scripts_vz` | Tool download | Exposes `wifmissionflow` source, confirms DLC hook point |

### 7.2 Short-Term (1-2 Weeks)

| # | Task | Depends On | Impact |
|---|------|-----------|--------|
| 4 | **Implement sandbox Phase 1** (VirtualDisk) | None | Eliminates deploy-to-VM feedback loop |
| 5 | **STRM vertex byte-swap** for DLC meshes | Format analysis | Required for DLC geometry rendering |
| 6 | **Write 010 Editor / ImHex templates** for FFCS, sges, UCFX | None | Community documentation |
| 7 | **Hash Saboteur strings** against unresolved ASET entries | `saboteur_strings.txt` | Resolve unknown type_hashes and asset names |
| 8 | **Test HavokNoesis / Havok IO** with extracted .hkx slices | Tool setup | Validate Havok 5.5 parsing, visualize skeletons |

### 7.3 Medium-Term (2-4 Weeks)

| # | Task | Depends On | Impact |
|---|------|-----------|--------|
| 9 | **Complete sandbox** (all 6 phases) | Phase 1 done | Full offline WAD validation |
| 10 | **Parse `decl` chunks** as vertex format bitfields | Saboteur reference | Replace stride-guessing with exact vertex layout |
| 11 | **Texture de-swizzle** for Xbox 360 DLC textures | Format research | DLC textures render correctly |
| 12 | **Havok delta/wavelet decompression** | hk_anim research | Full animation support |
| 13 | **Evaluate Reloaded-II** as mod framework | Testing | Better mod distribution than raw ASI |

### 7.4 Long-Term (1-3 Months)

| # | Task | Depends On | Impact |
|---|------|-----------|--------|
| 14 | **Kaitai Struct specs** for all binary formats | Documentation | Machine-readable format specs |
| 15 | **Full modding SDK** with content creation pipeline | Sandbox complete | Community mod authoring |
| 16 | **Animation FSM extraction** | HKX tools + block scanning | Full character animation system |
| 17 | **Noesis plugin** for UCFX mesh format | Reference implementation | Alternative preview path |
| 18 | **Complete UE5 world populate** with all 62k entities | Current pipeline | Full Maracaibo recreation |

### 7.5 Dependencies Between Workstreams

```
DLC Activation ─────────────────────────────────────────┐
  Row 8/9 testing → Fix Lua globals → DLC contracts     │
  STRM byte-swap → DLC geometry renders                  │
  Texture de-swizzle → DLC textures render               │
                                                         ▼
Debug Sandbox ──────────────────────────────────────── Modding SDK
  VirtualDisk → ScriptResolver → ValidationEngine        │
  Mission parser → DLC validation automation             │
                                                         ▼
Format Documentation ─────────────────────────────── Community Tools
  010/ImHex templates → Kaitai specs                     │
  Saboteur string hashing → ASET resolution              │
  Ghidra annotations → EXE understanding                 │
                                                         ▼
UE5 Recreation                                      Full Game Understanding
  Import pipeline → Populate scripts → Maracaibo demo
  Terrain extraction → World mesh → Play session
```

### 7.6 Quick Wins vs. Longer Efforts

**Quick wins (hours):**
- Run unluac on extracted .luac files
- Hash Saboteur strings against ASET (scripted comparison)
- Test Row 9 bisect (WAD already built, ASI compilation is `make dlc-asi-native`)
- Write basic 010 Editor template for FFCS header

**Medium effort (days):**
- Sandbox Phase 1 (VirtualDisk): 3-4 days, high reuse of existing code
- STRM vertex byte-swap: 2-3 days (per-format f16/f32/u8 logic)
- `decl` chunk parsing: 1-2 days (compare against Saboteur bitfield)

**Major effort (weeks):**
- Full sandbox implementation: 11-17 days
- Havok delta/wavelet decompression: weeks of algorithm work
- Complete modding SDK: builds on sandbox, weeks of polish
- Full UE5 world: ongoing pipeline refinement

---

## Appendix A: Key File Paths

| Purpose | Path |
|---------|------|
| Hash function | `tools/pandemic_hash.py` |
| FFCS parser | `tools/ffcs_wad.py` |
| sges decompressor | `tools/sges_decompress.py` |
| UCFX mesh codec | `tools/ucfx_mesh_codec.py` |
| Mesh extractor | `tools/mesh_extractor.py` |
| glTF exporter | `tools/gltf_exporter.py` |
| Texture extractor | `tools/texture_extractor.py` |
| Placement extractor | `tools/placement_extractor.py` |
| Patch WAD builder | `tools/ffcs_patch_wad.py` |
| BE→LE converter | `tools/ucfx_be_to_le.py` |
| DLC block extractor | `tools/x360_dlc_io.py` |
| ASI plugin source | `tools/dlc_enable_asi/dlc_enable.c` |
| Coordinate transforms | `tools/mercs2_coords.py` |
| Lua bytecode scanner | `tools/lua_bytecode_scan.py` |
| Havok packfile parser | `tools/hk_packfile.py` |
| Type hash registry | `docs/type_hash_registry.md` |
| Format reference | `docs/format_reference.md` |
| Placement format | `docs/placement_data_format.md` |
| Ghidra pre-analysis | `scripts/ghidra_mercs2_preanalysis.py` |
| Ghidra annotation | `scripts/ghidra_mercs2_annotate.py` |

## Appendix B: Critical Constants

| Constant | Value | Usage |
|----------|-------|-------|
| FNV-1a offset basis | `0x811C9DC5` | Hash init |
| FNV-1a prime | `0x01000193` | Hash multiply |
| Hash finalization | `^0x2A * prime` | Post-loop step |
| sges page size | `0x8000` (32KB) | INDX offset multiplier |
| CSUM init | `0x00000000` | CRC-32 init (custom) |
| CSUM polynomial | `0xEDB88320` | Reflected CRC-32 |
| Script type_hash | `0x42498680` | `pandemic_hash_m2("script")` |
| Model type_hash | `0x5B724250` | `pandemic_hash_m2("model")` |
| Texture type_hash | `0xF011157A` | `pandemic_hash_m2("texture")` |
| Layer type_hash | `0xE6B81A54` | `pandemic_hash_m2("layer")` |
| Animation type_hash | `0x18166555` | `pandemic_hash_m2("animation")` |
| `_SYS._IMPORT` VA | `0x005AE2D0` | PC EXE import() implementation |
| `luaL_loadbuffer` VA | `0x00860240` | PC EXE Lua API |
| `lua_pcall` VA | `0x0085DF50` | PC EXE Lua API |
| PTHS trailer size | 258 bytes | Mandatory WAD trailer |
| Transform record size | 42 bytes | Placement record stride |
| ASET row size | 16 bytes | Asset set entry stride |
| INDX entry size | 12 bytes | Block index entry stride |
| Block entry header | 16 bytes | Per-entry in decompressed block |

## Appendix C: Document Cross-Reference

| Document | What It Covers | Key Section Links |
|----------|---------------|-------------------|
| `format_reference.md` | Master binary format specs | §2.1 FFCS, §3 sges, §4 UCFX, §4.0 CSUM |
| `placement_data_format.md` | 42-byte records, coordinates, rotations | §2.5 Transform, §3.3 flgs, §5 Coordinates |
| `type_hash_registry.md` | All 35 type hashes with distribution | §2.3 Master Type Table |
| `aset_format.md` | ASET 16-byte row layout | §2.4 Row Layout |
| `mercs1_engine_analysis.md` | Mercs 1 API and architecture | §1.2 Subsystems, §2 Lua API, §3 Asset Loading |
| `saboteur_engine_comparison.md` | Format evolution confirmation | §1 Hash, §2 Archive, §9 sges |
| `dlc_extras_activation_research.md` | DLC activation approaches | §5 Ranked Approaches, §6 Plan |
| `sandbox_engine_plan.md` | Virtual engine design | §3 Module Design, §5 Checks, §10 Roadmap |
| `ghidra_annotation_guide.md` | Binary analysis pipeline | §1 Generate DB, §2 Run Script |
| `external_tools_review.md` | Tool recommendations | Summary Top 10, §8 Pandemic Tools |
| `vz_state_analysis.md` | 746 overlay files | §4 flgs Records, §8 Naming Conventions |
| `game_data_analysis.md` | Game directory structure | §2 data/, §3 Block Taxonomy |
| `pc_bisect_results.md` | DLC testing methodology | Test Matrix, Root Causes |

---

*This document synthesizes research from 13+ source documents representing months of reverse engineering work. It should be updated as new findings emerge — particularly when bisect rows 8 and 9 produce results, and when the debug sandbox reaches implementation.*
