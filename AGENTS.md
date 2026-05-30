# AGENTS.md — Mercenaries 2 Recreation Project

Persistent guidance for AI coding agents working on this repository.

## Project Overview

This is a fan recreation of **Mercenaries 2: World in Flames** (Pandemic Studios, 2008) in **Unreal Engine 5**. The project builds a pipeline that:

1. Extracts assets from the original PC game's proprietary FFCS `.wad` archives
2. Decompresses `sges` blocks and parses UCFX binary containers
3. Converts meshes, textures, animations, and placement data to standard formats (OBJ, glTF/GLB, PNG)
4. Bundles assets for UE5 import and places them in a Maracaibo demo level

**This is a recreation project — all data must be verified from the original game binary. No guessing.**

---

## Repository Layout

```
mercenaries-game/
├── tools/                  CLI Python tools (argparse-based) for extraction & conversion
│   ├── hk_anim/            Havok 5.5 animation decompression modules
│   ├── ucfx_mesh_codec.py  Shared UCFX mesh parsing helpers
│   ├── mesh_extractor.py   UCFX blob → OBJ/glTF geometry
│   ├── gltf_exporter.py    Scene glTF/GLB builder (pygltflib)
│   ├── texture_extractor.py DDS texture extraction + PNG transcoding
│   ├── placement_extractor.py World placement data decoder
│   └── ...                 (30+ tools — see tools/README.md)
├── scripts/                Shell scripts for pipeline orchestration
│   ├── extract_from_zip.sh Full pipeline entry point
│   ├── stage2_parallel.sh  Parallel stage-2 review extraction
│   └── ...
├── docs/                   Binary format specs and analysis
│   ├── format_reference.md Master format doc (FFCS, sges, UCFX, textures, Havok, etc.)
│   ├── placement_data_format.md Complete placement record specification
│   ├── vz_state_analysis.md     State overlay layer analysis
│   ├── gameplay_data_ue5_mapping.md  Non-mesh data → UE5 systems
│   ├── glue_gap_closeout.md     Pipeline ↔ UE5 integration backlog
│   ├── watermap_format.md / fxdict_format.md / audio_ue5_path.md
│   └── game_data_analysis.md    Game data directory walkthrough
├── game-scripts/           UE5 Editor Python scripts (import, populate, setup)
│   ├── mercs2_data_layers.py  Shared Data Layer helpers
│   ├── mercs2_visibility_runtime.py  Editor/PIE vz_state preset toggles
│   ├── mercs2_mission_data.py     Mission overlay stem helpers
│   ├── setup_all.py           Master orchestrator (15 steps; see script header)
│   ├── import_mission_data.py   DT_MissionRegistry + DT_SpawnRegistry from docs/data/examples
│   ├── mission_layer_activator.py  Contract vz_state Data Layer activation (Editor/PIE)
│   ├── import_audio.py        SoundWave batch import from audio_ue5_manifest (stub)
│   ├── setup_project.py       Project setup (plugins, directories, map)
│   ├── setup_audio_import.py  Audio Content folder scaffold (no WAV import yet)
│   ├── import_world.py        Import all world mesh GLBs
│   ├── import_pmc_base.py     Import PMC base mesh GLBs
│   ├── populate_world.py      Place 62k+ world entities + lights + Data Layers
│   ├── populate_pmc_base.py   Place PMC base entities + lights + Data Layers
│   └── fix_map_errors.py      Post-populate cleanup utility
├── UnrealEngineGame/       UE5 project (5.7) — content only, no scripts
├── viewer/                 Three.js web viewer for review assets (Vite + npm)
├── output/                 Pipeline output root (generated, not committed)
│   ├── extracted/          Decompressed blocks + review tree
│   ├── ue5_import/         Bundled assets for UE5 import
│   └── maracaibo_asset_list.json  Filtered Maracaibo subset
├── Models Archives/        Reference OBJ exports (scale goalposts)
├── SaveGames/              Original save profiles for data mining
├── Makefile                Pipeline orchestration (see Pipeline Stages)
└── requirements.txt        Python deps: numpy, Pillow, pygltflib
```

---

## Pipeline Stages

Run via `make` targets. Each stage depends on the previous:

```
1. extract-all     ZIP → FFCS slice → batch sges decompress → stage 2 review
2. review-all      Build texture_index.json → re-run stage 2 (parallel)
3. extract-placements   layers_static + vz_state → output/placements/
3b. condense-placements (optional)   world_bundle.json.gz + manifest.json for transfer to another machine
4. filter-maracaibo-placements   bbox + strict vz_state → maracaibo_placements.json
5. filter-maracaibo   Filter manifest → maracaibo_asset_list.json
6. regen-maracaibo-glbs   Regenerate GLB files with embedded textures
7. export-ue5 / ue5-bundle   Bundle review assets → ue5_import/ + manifest
8. [UE5 Editor]    import_mercs2.py → populate_maracaibo.py
```

After stage 2, optional **`make extract-terrain OUTPUT=./output`** merges `low_res_terrain` UCFX tiles into one `mesh_scene.glb`; `game-scripts/import_world.py` discovers it like other GLBs, and `populate_world.py` places it once at the origin and skips `lrterrain_r*_c*` tile placements.

### Key make targets

| Target | Purpose |
|--------|---------|
| `make venv` | Create `.venv`, install requirements.txt |
| `make extract-all ZIP=... OUTPUT=./output` | Full extraction from retail zip |
| `make review-all OUTPUT=./output` | Rebuild texture index + stage 2 |
| `make extract-terrain OUTPUT=./output` | Merge `low_res_terrain` tiles → `review/batch_vz/.../mesh_scene.glb` (needs `batch_vz/blocks/`) |
| `make regen-maracaibo-glbs OUTPUT=./output` | Regenerate GLBs for Maracaibo subset |
| `make ue5-bundle OUTPUT=./output` | variants + animations + export-ue5 |
| `make filter-maracaibo OUTPUT=./output` | Maracaibo asset filter |
| `make extract-placements OUTPUT=./output` | Placements + **ECS merge**, **ASET decode**, `pmc_base_block_set.json`, Lua chunk harvest → `output/placements/` |
| `make condense-placements OUTPUT=./output` | After extract-placements: `world_bundle.json.gz` + `manifest.json` (slim records, deduped ECS, spatial index); optional `maracaibo_bundle.json.gz` / `pmc_bundle.json.gz` when subset JSON exists. Expand on target: `python tools/condense_placements.py expand --bundle …/world_bundle.json.gz` |
| `make filter-pmc-base OUTPUT=./output` | PMC subset → `pmc_base_asset_list.json` + `placements/pmc_base.json` (needs `ue5-bundle`) |
| `make regen-pmc-glbs OUTPUT=./output` | Regenerate GLBs for PMC base list |
| `make build-pmc-base-set OUTPUT=./output` | Regenerate `pmc_base_block_set.json` only |
| `make extract-demo-ffcs` | Slice demo `vz.wad` → `output_demo/extracted/ffcs_vz_demo/` |
| `make filter-maracaibo-placements OUTPUT=./output` | Tight bbox + strict Maracaibo vz_state → `maracaibo_placements.json` |
| `make preview-placements OUTPUT=./output` | Vite viewer opens **placement map** (`placement-preview.html`) |
| `make viewer` | Launch Three.js asset viewer (main app) |
| `make dlc-port DLC_RAR=... SOURCE_WAD=... OUTPUT=./output` | Xbox 360 DLC → PC `vz-patch.wad` (2,197 blocks + nohook bootstrap) |
| `make verify-patch-wad-structure OUTPUT=./output` | G7: PTHS trailer + structure (`WAD_VARIANT`, `WAD_EXPECT_BLOCKS`) |
| `make ghidra-ps3-eboot` | Headless Ghidra analyze decrypted PS3 EBOOT.elf |
| `make crack-game RETAIL_EXE=... OUTPUT=./output` | Apply SecuROM bypass to retail EXE |
| `make dlc-asi-native OUTPUT=./output` | Cross-compile `dlc_enable.asi` from C with MinGW (requires `brew install mingw-w64`) |
| `make dlc-asi-native-debug OUTPUT=./output` | Same as above but with MessageBox popup on load (diagnostic) |
| `make ghidra-annotate-preanalysis` | Scan Mercs 1 source → `scripts/mercs2_annotations.json` for Ghidra annotation |

### Resuming after failure

Do not use `full-pipeline` to resume — it runs `clean`. Instead:

```bash
make review-all OUTPUT=./output                    # re-run stage 2
make ue5-bundle OUTPUT=./output                    # rebuild UE5 bundle
STAGE2_SKIP_UCFX=1 STAGE2_SKIP_MESH=1 make review-all OUTPUT=./output  # skip already-done steps
```

---

## Single-block extraction

When decoding or probing **one** WAD block (watermap, road graph, FaceFX, effect blocks, etc.), do **not** run `make extract-all` or bulk `sges_decompress --bulk-out-dir`. Use **`tools/extract_single_block.py`** instead: extract → decompress → optional decode hook → delete scratch on success.

**Policy:** one block at a time, explicit selector, clean up unless `--keep`.

```bash
# Windows (.venv/Scripts/python.exe) or Unix (.venv/bin/python3)
.venv/Scripts/python.exe tools/extract_single_block.py \
  --wad game-files/pc-game-vz.wad \
  --block-index 29 \
  --decode ".venv/Scripts/python.exe tools/ucfx_parser.py {bin} --out output/_scratch/ucfx.json"

# By PTHS path (unique substring OK)
.venv/Scripts/python.exe tools/extract_single_block.py \
  --wad game-files/pc-game-vz.wad \
  --path "blocks\\VZ\\layers_static_P000_Q3.block" \
  --keep --scratch-root output/_scratch

# By ASET asset hash (add --filter-type-hash if ambiguous)
.venv/Scripts/python.exe tools/extract_single_block.py \
  --wad game-files/pc-game-vz.wad \
  --aset-hash 0xDEADBEEF --filter-type-hash 0x5608BD5A

# Persist metadata without keeping the decompressed blob
.venv/Scripts/python.exe tools/extract_single_block.py \
  --wad game-files/pc-game-vz.wad --block-index 0 \
  --metadata-out output/_scratch/block0_meta.json
```

- Default: temp scratch dir removed after success.
- `--keep --scratch-root output/_scratch`: retain `{index:05d}_{stem}.block.bin` and print its path.
- `--decode CMD`: `{bin}` / `{path}` placeholders, or append `.block.bin` as the last argument.
- New decoders should accept a decompressed `.block.bin` path (from `--decode` or `--keep`) rather than assuming `output/extracted/batch_*/blocks/` exists.

---

## Coding Conventions

### Python

- **Python 3.12+** with type hints throughout (`from __future__ import annotations`)
- Always use `.venv/bin/python3` (or the Makefile's `$(PYTHON)` which auto-detects it)
- `tools/` scripts are CLI tools using `argparse` — follow the existing pattern
- Shared codec helpers go in `tools/ucfx_mesh_codec.py`
- Use `struct.unpack_from` for binary parsing, `pathlib.Path` for file paths
- Dependencies: `numpy`, `Pillow`, `pygltflib` (see `requirements.txt`)

### UE5 Editor Scripts

- Located in `game-scripts/` at the **repo root** (not inside `UnrealEngineGame/Content/`)
  - Kept outside the UE project so they survive project rebuilds / deletes
- Use the `unreal` module (UE Editor Python API)
- Run via Editor: **Tools → Execute Python Script**, browse to `game-scripts/` path
  - Example: `py "/path/to/mercenaries-game/game-scripts/populate_world.py"`
- Target UE 5.7; Interchange importer for glTF/GLB
- Scripts add `game-scripts/` to `sys.path` at startup for local imports (`mercs2_data_layers`)

#### UE 5.7 Python quirks (verified)

- **`DataLayerInstanceWithAsset`** does **not** expose `data_layer_label` as a settable property
- **`DataLayerEditorSubsystem.get_data_layer_instance(asset)`** can throw the same error
- **`set_parent_data_layer`** can also throw — use `_safe_set_parent_data_layer` wrapper
- **`PointLightComponent.light_color`** requires **`unreal.Color`** (uint8 sRGB), not `LinearColor`
- **`unreal.Rotator()` constructor** takes positional args as `(roll, pitch, yaw)` — **not** `(pitch, yaw, roll)`. Always use keyword arguments: `unreal.Rotator(roll=r, pitch=p, yaw=y)` to avoid silent misassignment

#### Two populate workflows

| Workflow | Import script | Populate script | Data source |
|----------|--------------|-----------------|-------------|
| **PMC base testbed** | `import_pmc_base.py` | `populate_pmc_base.py` | `pmc_base_asset_list.json` + `placements/pmc_base.json` + `pmc_base_streaming_groups.json` |
| **Full world** | `import_world.py` | `populate_world.py` | All GLBs in `review/` + `layers_static.json` + `all_vz_state.json` |

Full-world populate handles visibility layers:
- `layers_static` → always visible (base world).
- Merged **`low_res_terrain`** (from `make extract-terrain`) → one `StaticMeshActor` at origin when imported; `lrterrain_r*_c*` placements are skipped (geometry is already world-space in the mesh).
- `vz_state` pristine → visible (default pre-war look).
- `vz_state` ruined/destroyed → placed **hidden** (togglable in Outliner).
- `vz_state` staging/mission → placed **hidden**.
- Particles, triggers → skipped (no mesh representation).
- ECS `LightObject` entities → spawn as `PointLight` actors.

### Shell Scripts

- Located in `scripts/`; use `bash`
- Pipeline env vars: `OUTPUT`, `ZIP`, `STAGE2_*`, `TEXTURE_INDEX`, etc.
- See Makefile and script headers for the full variable reference

### General

- Document all binary format discoveries in `docs/`
- JSON sidecar files accompany extracted assets (see `docs/format_reference.md` §9)
- No truncation in harvest outputs — emit full lists with `*_count` fields

---

## Key Technical Facts

### Coordinate System

- Source mesh data is **left-handed Y-up** (D3D9 game space): X East–West, Y elevation, Z North–South
- **glTF export** (`tools/gltf_exporter.py`) writes game LH coordinates directly into GLB (no Z-negate, no winding flip). Only the **V texture coordinate** is flipped (`v = 1 - v`, D3D9 V=0-top → glTF V=0-bottom). UE Interchange's Y-up→Z-up import handles the basis change automatically, producing the same result as `game_to_ue`.
- **UV convention**: D3D9 uses V=0 at top of texture; glTF uses V=0 at bottom. The V-flip in `convert_uvs_d3d_to_gltf` handles this centrally in the exporter
- **Placements** stay in game LH metres; `game_to_ue` maps `(x, y, z)` → UE `(100·x, 100·z, 100·y)` with **no** Z negate
- **Rotations**: Binary record stores a **unit quaternion** `(qx, qy, qz, qw)` at offsets +0x14..+0x20. For Y-axis rotation: `qy = sin(yaw/2)`, `qw = cos(yaw/2)`. UE yaw = `-(2 * atan2(qy, qw))` in degrees (game CW+ vs UE CCW+ when viewed from above). ~16% of entities have non-trivial pitch/roll (tires, rocks, poles). Full quaternions use `game_quat_to_ue_rotator_deg()` which swaps qY↔qZ, decomposes to (pitch, yaw, roll), and negates yaw. Both in `tools/mercs2_coords.py`. **Always use keyword args** with `unreal.Rotator(roll=, pitch=, yaw=)` — positional order is `(roll, pitch, yaw)`.
- Do **not** add extra axis swizzles in mesh_extractor or populate scripts
- Coordinate range: X ≈ ±3900, Y ≈ -103 to +393 (elevation), Z ≈ ±3900

### Units

- The game uses **meters** as its unit system
- Verified: Parque Central towers = 220 game units ≈ 225m real-world height
- glTF `GLB_ROOT_SCALE` defaults to 1 (UE applies glTF unit scaling)

### Engine Lineage

- **Zero Engine:** Mercenaries 1 → Mercenaries 2 → The Saboteur (all Pandemic Studios)
- "Last-opened-file wins" asset lookup confirmed from Mercs 1 source (`RedVirtualDisk`)
- Mercs 1 had a fixed 64-slot C++ mission manager (`RsMissionDataManager`)
- Hash algorithm and `sges` compression are identical between Mercs 2 and The Saboteur

### Binary Formats

- **FFCS**: `.wad` container (magic `FFCS`, 5 chunk types: INDX, DATA, CSUM, ASET, PTHS)
- **sges**: Compressed blocks (raw deflate, `zlib` windowBits `-15`, multi-segment, 64 KB sentinel). Identical between Mercs 2 and The Saboteur
- **UCFX**: Decompressed asset container (CHDR/COMP/GEOM/MESH/PRMG/STRM/IBUF/MTRL/...)
- **Placement**: UCFX → CHDR → COMP/flgs chunks; 42-byte records with XYZ + unit quaternion (qx, qy, qz, qw)
- **CSUM trailer**: CRC-32 (poly 0xEDB88320, init=0, no final XOR) of UCFX header+body. Block file layout: `count(4)` + `count × entry(16)` + chunks; each chunk = `UCFX(8+body)` + `CSUM(8)`. See `docs/format_reference.md` §4.0
- **Hash algorithm**: FNV-1a with `|0x20` case suppression and `^0x2A * prime` finalization — confirmed identical between Mercenaries 2 and The Saboteur. `pandemic_hash_m2("animation") == 0x18166555` (magic constant in animgroup record headers). 35 unique type_hash values exist across vz.wad; 18 resolved to names. See `docs/aset_format.md`

### World Data

- **62,458** static placements in `layers_static` (173 UCFX sub-blocks)
- **~3,500** conditional placements across 219 `vz_state` source files
- **~161,280** total SceneObjects (from `cdbsizes.ini` preallocation)
- vz.wad contains 11,370 blocks total

#### Placement visibility layers

Not all 62k entities should render simultaneously.  `layers_static` is the
always-visible base world.  `vz_state` overlays encode game-state variants:

| vz_state source pattern | Count | Visibility |
|--------------------------|-------|------------|
| `*_pristine` | ~430 | Visible (default pre-war look) |
| `*_ruined` / `*_destroyed` | ~27 | Hidden (togglable for act progression) |
| `*_staging` / `*_combat` / `*_defenses` | ~890 | Hidden (mission pre-positioning) |
| `*_act1` / `*_act2` / `*_act3` | ~270 | Hidden (act-specific overlays) |

Within `layers_static`, **~37%** are vegetation/rocks, **~10%** street furniture,
**~9%** fences/walls, **~6%** roads, **~4%** buildings.  Entity names containing
`particle`, `Light_`, `spawner`, `trigger`, or `collision` are skipped by
`populate_world.py` (no mesh representation).

### LOD System

- Naming: `P00x_Qy` — **higher Q numbers are often the complete/best meshes**, not lower quality
- Use bounding box volume to pick the best variant, not Q-tier labels
- `--lod highest-poly-per-bbox` in mesh_extractor.py selects best LOD per group

### Textures

- DDS → PNG transcoding for GLB embedding (via ffmpeg or Pillow)
- Texture streaming index (`texture_index.json`) enables cross-block mip assembly
- UE Interchange importer handles material assignment from glTF
- **UV V-flip**: D3D9 stores V=0 at image top; glTF expects V=0 at bottom. `gltf_exporter.py` applies `v = 1.0 - v` via `convert_uvs_d3d_to_gltf` for all meshes. Do **not** add extra V-flips in mesh_extractor or other upstream stages
- **Terrain UV + GLB**: `make extract-terrain` writes `mesh_scene.glb` directly via `terrain_extractor._build_terrain_glb` (no `gltf_exporter` round-trip). Synthesized terrain UVs use `_TEXTURE_V_FLIP = True` in `_world_xz_to_uv` (atlas top = game south / low Z; verified by placement density correlation). The atlas PNG is not rotated. GLB positions are written in **game LH coordinates directly** (no Z-negate, no winding flip) — UE Interchange's Y-up→Z-up swap produces the correct world alignment with `game_to_ue` placements at the origin actor.

### Animations

- Havok 5.5 packfile format; three compression types (interleaved, delta, wavelet)
- `mercs2_anim_pipeline.py` → `anim_gltf_export.py` → skeletal `.glb`
- Delta and wavelet decompression are partially implemented (see `tools/hk_anim/`)

---

## Byte-Swap Policy (Xbox 360 DLC → PC)

All big-endian → little-endian conversion for DLC porting uses **`tools/ucfx_be_to_le.py`** (called from `tools/dlc_port.py`). Rules:

- **Semantic swaps only** — use `struct.unpack('>…')` / `struct.pack('<…')` with documented field types per chunk/tag. Never reverse arbitrary byte ranges for numeric data.
- **Tag reversal is OK** — `[::-1]` on 4-byte ASCII chunk tags (e.g. `XFCU` → `UCFX`) is intentional, not a numeric swap.
- **No silent fallbacks** — unrecognized tags, type_hashes, Havok `__data__`, or soundbank record layouts must raise **`UnhandledByteSwapError`** in strict mode (default). A blind `_convert_u32_array()` corrupts mixed u8/u32 layouts.
- **`--permissive`** on `dlc_port.py` / `byteswap_ucfx_block()` enables legacy u32 fallbacks with warnings — **testing only**, never production patch builds.
- **New formats** — add typed converters; the exception message should include tag, type_hash, and body size. Validate with `tools/audit_dlc_conversion.py` (mismatch count should drop) and `tools/verify_ucfx_endian.py --report-blind-swaps` (fallback exposure should trend to zero).
- **Deleted blind tools** — `port_xbox_dlc.py` and `dlc_port_x360_to_pc.py` were removed; do not reintroduce tag-scanning `[::-1]` u32 sweeps.

---

## Common Pitfalls

1. **Don't add extra coordinate swizzles** — ALL meshes (buildings AND terrain) write game LH coordinates directly into GLB. UE Interchange handles the Y-up→Z-up basis swap. Only the UV V-flip (`v = 1 - v`) is applied for the D3D9→glTF texture convention. Do NOT add Z-negates or winding flips anywhere in the mesh pipeline.

2. **Don't trust Q-tier labels for LOD quality** — `P000_Q3` is not always "highest quality." Use bounding box volume or vertex count to pick the best variant per asset.

3. **UE Interchange needs co-located materials** — import meshes to per-asset subfolders so textures and materials resolve correctly. The `ue5_export.py` bundler handles this.

4. **Don't use `head`/`tail`/`less` to limit terminal output** in agent sessions — use proper Python slicing or `--max` flags instead.

5. **Always use `.venv`** — system Python won't have `pygltflib`. The Makefile auto-detects `.venv/bin/python`; run `make venv` if it doesn't exist.

6. **COMP child offsets differ by block type**:
   - `layers_static`: offsets are **relative** to `data_area_start`
   - `vz_state`: offsets are **absolute** file offsets

7. **Stage 2 env vars** control what gets rebuilt — set `STAGE2_SKIP_*=1` to skip already-completed steps when resuming.

8. **`full-pipeline` runs `clean` first** — use `make review-all` or individual targets to resume without deleting progress.

9. **`unreal.Rotator()` positional arg order is `(roll, pitch, yaw)`** — not `(pitch, yaw, roll)` as the C++ `FRotator` constructor uses. Always use keyword args: `unreal.Rotator(roll=r, pitch=p, yaw=y)`.

---

## File Format Documentation

All binary format specs live in `docs/`:

| Document | Content |
|----------|---------|
| `format_reference.md` | Master reference: FFCS, sges, UCFX chunks, texture INFO, Havok, CERP, PWS, stage 2 JSON sidecars |
| `placement_data_format.md` | 42-byte placement records, layers_static vs vz_state, coordinate system, rotation encoding |
| `vz_state_analysis.md` | 746 state overlay files, COMP components, flgs section, entity cross-references |
| `game_data_analysis.md` | Game directory structure, block taxonomy, world data architecture |
| `skeleton_status.md` | Havok skeletal animation pipeline status |
| `quickbms_notes.md` | External QuickBMS workflow notes |
| `game_extractor_notes.md` | External Game Extractor workflow notes |

When discovering new binary structures, **add them to the appropriate doc** — these are the source of truth.

---

## Testing & Verification

### After changing mesh extraction or GLB generation

```bash
make regen-maracaibo-glbs OUTPUT=./output
```

Then open a few GLBs in the Three.js viewer (`make viewer`) to confirm geometry is correct.

### After changing UE5 import scripts

1. Regenerate GLBs if needed
2. In UE5 Editor, run `game-scripts/setup_project.py` first (creates directories)
3. Run `game-scripts/import_world.py` on a small subset
4. Spot-check imported StaticMesh silhouettes in the viewport
5. Run `game-scripts/populate_world.py` and verify actor placement

### After changing format parsers

```bash
# Validate mesh extraction across the archive
.venv/bin/python3 tools/validate_meshes.py --repo-root .
```

### After changing the pipeline

```bash
# Re-run stage 2 on a subset
STAGE2_JOBS=4 make review-all OUTPUT=./output
# Then rebuild the UE5 bundle
make ue5-bundle OUTPUT=./output
```

---

## Environment Setup

```bash
# 1. Create virtualenv and install deps
make venv

# 2. Verify
.venv/bin/python3 -c "import pygltflib; print('OK')"

# 3. Full pipeline (from retail zip)
make extract-all ZIP="./Mercenaries 2 World in Flames.zip" OUTPUT=./output

# 4. UE5 bundle
make ue5-bundle OUTPUT=./output
make regen-maracaibo-glbs OUTPUT=./output
```

For UE5: open `UnrealEngineGame/` in Unreal Engine 5.7, enable Editor Python + Interchange plugins, then run **`game-scripts/setup_all.py`** (recommended) or individual scripts:

```
setup_all.py  — full pipeline: project + data structs + player/HUD/audio/weather
                scaffold → import_world → populate_world → vz visibility preset
                → terrain collision → player start → water → atmosphere → verify
```

Skip slow or post-wipe steps with env vars (see `setup_all.py` header): `MERCS2_SETUP_SKIP_WORLD=1`, `MERCS2_SETUP_SKIP_VZ_VISIBILITY=1`, `MERCS2_SETUP_SKIP_VERIFY=1`, etc. After a Content wipe, **`rebuild_world.py`** calls `setup_all.run()` with the same flags.

PMC testbed uses `import_pmc_base.py` + `populate_pmc_base.py` instead of the world import/populate steps. Diagnostic only: `setup_rotation_test_grid.py` (not in `setup_all`).

Run via **Tools → Execute Python Script** or the output log `py` command with the full path to the script.
