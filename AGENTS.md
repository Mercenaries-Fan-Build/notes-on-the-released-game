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
│   └── game_data_analysis.md    Game data directory walkthrough
├── game-scripts/           UE5 Editor Python scripts (import, populate, setup)
│   ├── mercs2_data_layers.py  Shared Data Layer helpers
│   ├── setup_project.py       Project setup (plugins, directories, map)
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
| `make filter-pmc-base OUTPUT=./output` | PMC subset → `pmc_base_asset_list.json` + `placements/pmc_base.json` (needs `ue5-bundle`) |
| `make regen-pmc-glbs OUTPUT=./output` | Regenerate GLBs for PMC base list |
| `make build-pmc-base-set OUTPUT=./output` | Regenerate `pmc_base_block_set.json` only |
| `make extract-demo-ffcs` | Slice demo `vz.wad` → `output_demo/extracted/ffcs_vz_demo/` |
| `make filter-maracaibo-placements OUTPUT=./output` | Tight bbox + strict Maracaibo vz_state → `maracaibo_placements.json` |
| `make preview-placements OUTPUT=./output` | Vite viewer opens **placement map** (`placement-preview.html`) |
| `make viewer` | Launch Three.js asset viewer (main app) |

### Resuming after failure

Do not use `full-pipeline` to resume — it runs `clean`. Instead:

```bash
make review-all OUTPUT=./output                    # re-run stage 2
make ue5-bundle OUTPUT=./output                    # rebuild UE5 bundle
STAGE2_SKIP_UCFX=1 STAGE2_SKIP_MESH=1 make review-all OUTPUT=./output  # skip already-done steps
```

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

- Source mesh data is **Y-up** (matches glTF spec); UE5 imports it correctly as Z-up
- **Do not apply coordinate swizzles** in the exporter pipeline
- Coordinate range: X ≈ ±3900, Y ≈ -103 to +393 (elevation), Z ≈ ±3900

### Units

- The game uses **meters** as its unit system
- Verified: Parque Central towers = 220 game units ≈ 225m real-world height
- glTF `GLB_ROOT_SCALE` defaults to 1 (UE applies glTF unit scaling)

### Binary Formats

- **FFCS**: `.wad` container (magic `FFCS`, 5 chunk types: INDX, DATA, CSUM, ASET, PTHS)
- **sges**: Compressed blocks (raw deflate, `zlib` windowBits `-15`, multi-segment)
- **UCFX**: Decompressed asset container (CHDR/COMP/GEOM/MESH/PRMG/STRM/IBUF/MTRL/...)
- **Placement**: UCFX → CHDR → COMP/flgs chunks; 42-byte records with XYZ + rotation

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

### Animations

- Havok 5.5 packfile format; three compression types (interleaved, delta, wavelet)
- `mercs2_anim_pipeline.py` → `anim_gltf_export.py` → skeletal `.glb`
- Delta and wavelet decompression are partially implemented (see `tools/hk_anim/`)

---

## Common Pitfalls

1. **Don't apply coordinate swizzles** — mesh data is already Y-up; the exporter emits correct glTF without any axis swapping. Adding swizzles will produce mirrored or rotated geometry.

2. **Don't trust Q-tier labels for LOD quality** — `P000_Q3` is not always "highest quality." Use bounding box volume or vertex count to pick the best variant per asset.

3. **UE Interchange needs co-located materials** — import meshes to per-asset subfolders so textures and materials resolve correctly. The `ue5_export.py` bundler handles this.

4. **Don't use `head`/`tail`/`less` to limit terminal output** in agent sessions — use proper Python slicing or `--max` flags instead.

5. **Always use `.venv`** — system Python won't have `pygltflib`. The Makefile auto-detects `.venv/bin/python`; run `make venv` if it doesn't exist.

6. **COMP child offsets differ by block type**:
   - `layers_static`: offsets are **relative** to `data_area_start`
   - `vz_state`: offsets are **absolute** file offsets

7. **Stage 2 env vars** control what gets rebuilt — set `STAGE2_SKIP_*=1` to skip already-completed steps when resuming.

8. **`full-pipeline` runs `clean` first** — use `make review-all` or individual targets to resume without deleting progress.

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

For UE5: open `UnrealEngineGame/` in Unreal Engine 5.7, enable Editor Python + Interchange plugins, then run scripts from `game-scripts/` in order:

```
1. setup_project.py    — create content directories, verify plugins
2. import_world.py     — import mesh GLBs from extraction output
3. populate_world.py   — place 62k+ entities with Data Layers + lights
```

Run via **Tools → Execute Python Script** or the output log `py` command with the full path to the script.
