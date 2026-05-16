# Mercenaries 2 (PC) extraction toolkit

These scripts parse the proprietary **FFCS** `.wad` packs used by Mercenaries 2.

**Binary layouts, unknown header fields, and pipeline JSON sidecars** are summarized in **[`docs/format_reference.md`](../docs/format_reference.md)** (save profile header, FFCS, `sges`, UCFX, textures, Havok, CERP, PWS, ECS manifest).

## FFCS layout (discovered)

- Magic `FFCS`, version `2`, declared chunk count `7`.
- Only **five** 12-byte chunk rows exist before the `0x48` signature/key blob.
- Tags: `INDX`, `DATA`, `CSUM`, `ASET`, `PTHS`.
- `CSUM` stores **hashes**, not a byte range — omit from spatial layout.
- Section sizes are inferred by sorting spatial chunks by start offset; `DATA` runs to EOF.

## Commands

```bash
/usr/bin/python3 tools/ffcs_wad.py "Mercenaries 2 World in Flames/data/shell.wad"
/usr/bin/python3 tools/ffcs_wad.py "Mercenaries 2 World in Flames/data/shell.wad" --json
/usr/bin/python3 tools/ffcs_wad.py "Mercenaries 2 World in Flames/data/shell.wad" --out-dir output/ffcs_shell_chunks

/usr/bin/python3 tools/mercs2_ffcs_extract.py "Mercenaries 2 World in Flames/data/vz.wad" --out output/ffcs_vz
```

`mercs2_ffcs_extract.py` writes `manifest.json`, raw `*.bin` slices (`indx.bin`, `data.bin`, …), and `paths.txt`
(path-like strings discovered inside `PTHS`).

### PMC base / ECS / Lua (added 2026-05)

| Script | Purpose |
|--------|---------|
| [`build_pmc_base_block_set.py`](build_pmc_base_block_set.py) | `output/pmc_base_block_set.json` — PMC stems + HQ bbox |
| [`ucfx_ecs_codec.py`](ucfx_ecs_codec.py) | ECS `COMP` blob harvest helpers |
| [`ecs_metadata_extract.py`](ecs_metadata_extract.py) | `ecs_components.json` + merge into placements |
| [`aset_decoder.py`](aset_decoder.py) | `block_dependency_graph.json` from `aset.bin` |
| [`lua_script_chunks.py`](lua_script_chunks.py) | Split `scripts_vz` `LuaQ` chunks + PMC string harvest |
| [`filter_pmc_base.py`](filter_pmc_base.py) | `pmc_base_asset_list.json`, `placements/pmc_base.json`, streaming groups |
| [`regen_pmc_base_glbs.py`](regen_pmc_base_glbs.py) | Regenerate GLBs for PMC asset list |

Makefile targets: `build-pmc-base-set`, `extract-demo-ffcs`, `filter-pmc-base`, `regen-pmc-glbs` (see `make help`).

## From retail zip (full pipeline)

Place `Mercenaries 2 World in Flames.zip` anywhere; run (flags must appear **before** the zip path):

```bash
./scripts/extract_from_zip.sh "/path/to/Mercenaries 2 World in Flames.zip"
```

**Default:** unzip → FFCS slices for **every** `data/*.wad` → **batch sges for every pack (including `vz.wad`)** → **stage 2** on all `extracted/batch_*/blocks/*.bin` → review under **`extracted/review/`**. This is intentionally the full “everything” pass and may take a long time.

Use **`--quick`** for **shell + loading only** (smaller/faster). With **`--quick`**, add **`--decompress-vz`** if you only want vz on top of that. **`--no-decompress`** skips all sges batching; **`--no-stage2`** skips review extraction; **`--vz-max N`** caps vz block count when vz is being decompressed.

```bash
./scripts/extract_from_zip.sh --quick "/path/to/Mercenaries 2 World in Flames.zip"
./scripts/extract_from_zip.sh --quick --decompress-vz --vz-max 500 "/path/to/Mercenaries 2 World in Flames.zip"
./scripts/extract_from_zip.sh --no-stage2 "/path/to/Mercenaries 2 World in Flames.zip"
./scripts/extract_from_zip.sh --no-decompress "/path/to/Mercenaries 2 World in Flames.zip"
./scripts/extract_from_zip.sh --everything "/path/to/Mercenaries 2 World in Flames.zip"   # same as default (full)
./scripts/extract_from_zip.sh --out-dir ~/m2-out "/path/to/Mercenaries 2 World in Flames.zip"
./scripts/extract_from_zip.sh --skip-unzip "/path/to/Mercenaries 2 World in Flames.zip"
```

Stage 2 alone (e.g. legacy `output/batch_*` next to `ffcs_*`):

```bash
./scripts/stage2_review_extract.sh /path/to/pipeline-root
```

Set **`STAGE2_ANIM=1`** to run **[`tools/mercs2_anim_pipeline.py`](mercs2_anim_pipeline.py)** after all blobs (writes ``<pipeline-root>/animations/<slug>/<slug>.glb`` from ``*animgroup*.block.bin``).

## Asset scanning

```bash
/usr/bin/python3 tools/mercs2_scan_assets.py output/ffcs_shell/data.bin
/usr/bin/python3 tools/mercs2_scan_assets.py output/ffcs_vz/data.bin   # large; takes ~10s
```

Findings on `vz.wad` DATA: many **zlib** candidates, **DXT5** tag occurrences, and **`hkxp`** Havok binary signatures.

## Precache (CERP)

```bash
/usr/bin/python3 tools/cerp_precache.py "Mercenaries 2 World in Flames/Precache/index0.precache"
/usr/bin/python3 tools/cerp_precache.py index0.precache --json
/usr/bin/python3 tools/cerp_precache.py index0.precache --out output/cerp_index0.json
```

Default mode prints **magic, version, size**, and a **hex preview** of the first `--bytes` (default 256). With **`--json`** and/or **`--out`**, writes the same fields as structured JSON (`magic`, `version`, `size`, `header_hex_preview`, `valid`); see [`docs/format_reference.md`](../docs/format_reference.md#6-cerp-precache).

## ECS / Lua symbol harvest

```bash
/usr/bin/python3 tools/mercs2_ecs_manifest.py   # writes ../output/ecs_manifest.json
```

Requires macOS `/usr/bin/strings`. The manifest’s **`symbols`** array is capped at **`symbols_max_output`** (8000) entries; **`symbol_count`** is the full distinct count before truncation.

## Output artifacts (generated)

High-level paths (default `OUTPUT=./output`):

- `output/ffcs_vz/`, `output/ffcs_shell/`, … — FFCS extraction + `paths.txt`.
- `output/extracted/batch_*/blocks/*.bin` — decompressed `sges` blocks.
- `output/extracted/review/<batch_pack>/<stem>/` — stage 2 per-asset tree (see table below).
- `output/extracted/texture_index.json` — global texture hash index (`texture_streaming_index.py` + **`make build-texture-index`**); **`make review-all`** / **`make extract-all`** pass it as **`TEXTURE_INDEX`** so stage 2 assembles full mip chains.
- `output/knowledge/saves.json` — `make extract-saves`.
- `output/variant_registry.json` — `make variants`.
- `output/ecs_manifest.json` — `mercs2_ecs_manifest.py`.
- `output/extracted_audio/` — `make extract-audio` (RIFF/Ogg slices + `pws_manifest.json` per stream root).
- `output/ue5_import/` — `make ue5-bundle` (bundled manifests + copied metadata).

**Maracaibo demo filter:** `maracaibo_asset_list.json` and UE follow-up are described in [`UnrealEngineGame/README.md`](../UnrealEngineGame/README.md).

### Output artifact reference (JSON / manifests)

| Artifact | Typical location | Produced by | Notes |
|----------|------------------|-------------|--------|
| `manifest.json` | `ffcs_*/` | `mercs2_ffcs_extract.py` | FFCS chunk rows, offsets, sizes |
| `paths.txt` | `ffcs_*/` | FFCS `PTHS` | One path-like string per line |
| `paths_sample.txt` | `ffcs_wad.py --out-dir` | `ffcs_wad.py` | Sample path harvest (CLI extract) |
| `manifest.json` | `batch_*/` (sges batch) | `sges_decompress.py` | Per-block index / path / size when batching |
| `texture_index.json` | `extracted/` (default) | `texture_streaming_index.py` | Asset hash → texture locations for mip assembly |
| `ucfx.json` | `review/.../<stem>/` | `ucfx_parser.py` | Tag hits, DXT/Havok strings, `geom_chunk_trees` preview |
| `mesh.meta.json` | same | `mesh_extractor.py` | Vertex/tri counts, topology, LOD, materials, `extract` debug |
| `mesh.obj`, `mesh.gltf` | same | `mesh_extractor.py` | Geometry |
| `mesh_scene.gltf` (+ `.bin`) | same | `gltf_exporter.py` | When **`STAGE2_GLTF`** enabled |
| `submeshes/index.json` | `.../submeshes/` | `mesh_extractor.py` | Per-part bbox, transform, face counts, material index, transparency |
| `shared_textures.json` | next to mesh | `mesh_extractor.py` | When **`--texture-index`** passed |
| `textures/manifest.json` | `.../textures/` | `texture_extractor.py` | Texture file list |
| `textures/texture_manifest.json` | same | `texture_extractor.py` | Richer manifest (source blob, PNG paths, entries) |
| `havok/manifest.json` | `.../havok/` | `havok_extractor.py` | `havok_slices` (+ optional convex heuristic) |
| `dialog_fragments.json` | stem folder | `dialog_extractor.py` | `bracket_keys`, `generic_keys`, `utf16_bracket_keys` + counts |
| `level_hints.json` | stem folder | `level_extractor.py` | `matrix_candidates`; optional `precache_files` if `--precache-root` used |
| `pws_manifest.json` | per `.pws` output dir | `pws_extractor.py` | Stream list; **WAVE** streams may include `wave_sample_rate`, `wave_channels`, `wave_bits_per_sample`, `wave_duration_seconds`, … |
| `pws_summary.json` | parent of per-input dirs | `pws_extractor.py` | `total_streams` for multi-input run |
| `saves.json` | `knowledge/` | `savefile_parser.py` | `header` + `harvested` (full lists, no `_sample` keys) |
| `variant_registry.json` | `output/` or pipeline root | `variant_classifier.py` | Stems + `grouped_by_base_asset_id` |
| `ecs_manifest.json` | `output/` | `mercs2_ecs_manifest.py` | Components + capped `symbols` (see ECS section) |
| `metadata/manifest.json` | `ue5_import/` | `ue5_export.py` | Master bundle index + `label_tokens_count` |
| `assets/<id>/manifest.json` | `ue5_import/` | `ue5_export.py` | Per-asset `ue_folder`, optional `label_hint` |

Run logs / failure lists (`stage2_parallel_*.log`, `*_failures.txt`, batch `logs/run-*.log`) are diagnostic metadata, not game content.

## sges block decompression (`sges_decompress.py`)

Each path in `paths.txt` maps to the **n-th** `sges` magic in `data.bin`. Payloads use **raw deflate**
(`zlib` windowBits `-15`) in one or more segments; compressed streams are separated by zero padding.

```bash
/usr/bin/python3 tools/sges_decompress.py --data-bin output/ffcs_shell/data.bin --ffcs-out output/ffcs_shell --list
/usr/bin/python3 tools/sges_decompress.py --data-bin output/ffcs_shell/data.bin --ffcs-out output/ffcs_shell --index 0 --out output/shell_base.ucfx.bin
/usr/bin/python3 tools/sges_decompress.py --data-bin output/ffcs_vz/data.bin --ffcs-out output/ffcs_vz --name "civ_veh_car" --out output/car.blob.bin
/usr/bin/python3 tools/sges_decompress.py --wad "Mercenaries 2 World in Flames/data/shell.wad" --ffcs-out output/ffcs_shell --index 0 --out output/x.bin
```

### Batch extraction (all `paths.txt` entries)

`scripts/extract_all_from_paths.sh` walks **every non-empty line** in `paths.txt` and maps each line to the same index as the tool (index *n* = *n*-th path = *n*-th `sges` block). By default it uses **bulk mode** (`sges_decompress.py --bulk-out-dir`): one Python process opens `data.bin` once, scans for all `sges` headers once, and writes every block (fast for large packs like **vz**). Set **`EXTRACT_JOBS=1`** for the legacy **one Python process per block** (`--index` per line; slow; debugging only). Outputs go to `output/batch_vz/`, `output/batch_shell/`, etc. The `vz` pack lists thousands of paths—use `--max`, `START`/`MAX`, or `SKIP_EXISTING=1` instead of a full pass unless you intend to fill disk.

```bash
chmod +x scripts/extract_all_from_paths.sh
./scripts/extract_all_from_paths.sh output/ffcs_shell --max 5
./scripts/extract_all_from_paths.sh output/ffcs_vz --start 0 --max 50
SKIP_EXISTING=1 MAX=200 ./scripts/extract_all_from_paths.sh output/ffcs_vz
WITH_UCFX=1 ./scripts/extract_all_from_paths.sh output/ffcs_loading --max 8
```

## UCFX manifest (`ucfx_parser.py`)

Scans decompressed blobs for `UCFX`, `MESH`, `GEOM`, `INDX`, `DXT*`, and Havok-related strings; writes JSON.

```bash
/usr/bin/python3 tools/ucfx_parser.py output/shell_base.ucfx.bin --out output/shell_base_ucfx.json
```

## Mesh / texture / Havok helpers

```bash
/usr/bin/python3 tools/mesh_extractor.py output/shell_base.ucfx.bin --out output/h_mesh.obj --format obj --indices
/usr/bin/python3 tools/texture_extractor.py output/shell_base.ucfx.bin --out-dir output/tex_out
/usr/bin/python3 tools/havok_extractor.py output/car.blob.bin --out-dir output/havok_out
```

`texture_extractor.py` walks **UCFX** `NAME`/`INFO`/`BODY` for DXT1/3/5 (with mip tails). **`--legacy-raw-dxt`** re-enables the old raw FourCC scan (debug only).

**Mesh preview:** Use the Vite app in [`viewer/`](../viewer/) (`npm run dev`). It lists stage-2 review outputs, loads OBJ / glTF / DDS, and when `submeshes/index.json` is present shows **Submesh inspection** in the sidebar (LOD, damage variants, per-part toggles, textures from `textures/manifest.json`).

Optional dev-server deep link: append `?manifest=/__review__/batch_*/<stem>/submeshes/index.json` (URL-encoded as needed) to load that manifest on startup. Single meshes use **Manual URLs** in the sidebar or click an asset without `[submeshes]`.

### `mesh_extractor.py`

**Primary path** walks each rich **UCFX** chunk table: `data_base = ucfx_off + u0`; under **GEOM** it scans flat **PRMG** rows, reads **STRM** `decl`/`data` (VB offset/length) and **IBUF** `data` (IB offset/length) relative to `data_base`, derives stride from `vb_len / (max_index+1)` when it divides evenly, decodes **f16 vec3** positions (with **snorm16 + PRMG INFO bbox** fallback), and merges all submeshes. If that yields too few triangles, it **falls back** to the older heuristic STRM/index-window search. Pass **`--indices`** (stage 2 already does) for real topology.

**HIER world transforms:** When a **HIER** chunk is present (176 bytes per node: 16-byte header + two 4×4 float matrices + 32-byte tail bbox), `mesh_extractor.py` parses the full bone tree and accumulates world transforms. Each PRMG's local bbox is matched to a HIER node by tail-bbox distance; the accumulated translation (and rotation, when non-identity) is applied to vertices before merging. This places wheels at axle positions, seats inside the cabin, panels at the correct body offsets, etc.

**New flags:**

| Flag | Description |
|------|-------------|
| `--per-submesh-obj` | Emit `submeshes/NNNN.obj` + `submeshes/index.json` next to `--out`. Each file is one PRMG draw-call, pre-transformed to world space. The `index.json` records per-part bbox, world translation, vertex/face counts, and HIER node index. Open the asset in [`viewer/`](../viewer/) (listed as `[submeshes]`) or use `?manifest=…` on the dev server. |
| `--lod {keep-all,dedupe-bbox,highest-poly-per-bbox}` | LOD / damage-variant culling (default `keep-all`). `dedupe-bbox` keeps the first submesh per unique bbox-center+extent key. `highest-poly-per-bbox` keeps only the highest face-count variant per group — typically reduces vertex count ~35% while keeping the best LOD. |

Optional archive regression / sanity:

```bash
/usr/bin/python3 tools/validate_meshes.py --repo-root .
```

`ucfx_parser.py` now includes `geom_chunk_trees` — a linear 20-byte chunk preview after each `GEOM` for debugging alongside tag scans.

Shared helpers live in `tools/ucfx_mesh_codec.py`.

## Three.js viewer (`viewer/`)

After stage 2, run **`cd viewer && npm run dev`**. The UI lists assets under **`output/review/`** and **`output/extracted/review/`** automatically (override with **`MERCS2_REVIEW_ROOT`**). See repo **`README.md`** — Three.js viewer.

Or from repo root: **`make viewer OUTPUT=./output`**.

## Makefile / UE5 bundle

From repo root (see root **`Makefile`**):

- **`make extract-all ZIP=…`** — full zip → FFCS → batch decompress → stage 2 review.
- **`make extract-saves`** — `SaveGames/*.profile` → `OUTPUT/knowledge/saves.json`.
- **`make extract-audio`** — `OUTPUT/data/Audios/*.pws` → `OUTPUT/extracted_audio/` (RIFF/Ogg slices via `pws_extractor.py`).
- **`make extract-video`** — `OUTPUT/data/Movies/*.bik` → MP4 (needs **ffmpeg**).
- **`make variants`** — `paths.txt` → `OUTPUT/variant_registry.json` (override file with **`VARIANT_PATH=`**).
- **`make export-ue5`** / **`make ue5-bundle`** — copy review assets → `OUTPUT/ue5_import/` + `metadata/manifest.json` + stub `import_assets.py`.
- **`make category-samples`** — `tools/select_category_samples.py` over the bundle: classifies every asset (vehicles → tank / boat / van / truck / car / heli …, buildings → skyscraper / apartment / outpost / segment …, characters → civ / pmc / faction, props / roads / world) and picks **one representative mesh per leaf** (highest vertex count with real geometry). Writes **`OUTPUT/ue5_import/category_samples.json`** including viewer deep-links so each pick opens in `npm run dev` with a single click. Override picks-per-leaf with **`TOP=N`** and the viewer origin with **`VIEWER_BASE=`**; supply your own classification table via **`--categories path/to/categories.json`** ( `[[ "name", ["regex", …] ], …]`).
- **`make sample-bundle`** — same as `category-samples` but also copies the picked `assets/<id>/` bundles into **`OUTPUT/ue5_import_samples/`** with a fresh `metadata/manifest.json` (and the import scripts), giving a ~few-dozen-asset UE5 import for smoke-testing without dragging in all ~11k.
- **`make all ZIP=…`** — `extract-all` + saves + audio + video + `ue5-bundle`.
- **`make full-pipeline ZIP=…`** — **`clean`** then the same chain as **`all`**.

### Save / dialog harvest JSON (single schema, no truncation)

- **`tools/savefile_parser.py`** — under each profile’s `harvested`, emits **full** sorted lists (`mission_ids`, `vehicle_tokens`, `support_tokens`, `localization_key_like`, `sys_string_to_guid_hex`, `vz_layer_strings`, …) with matching `*_count` fields. Nothing is sliced for export.
- **`tools/dialog_extractor.py`** — full `bracket_keys`, `generic_keys`, and `utf16_bracket_keys` arrays plus counts (no caps).
- **`tools/ue5_export.py`** — builds one merged label token set from **`knowledge/saves.json`** (canonical keys above), **every `extracted/ffcs_*/paths.txt`**, **`variant_registry.json`** (`grouped_by_base_asset_id` keys and variant stems), and **all `extracted/review/**/dialog_fragments.json`** files from stage 2. Per-asset manifests may include **`label_hint`**; the master manifest includes **`label_tokens_count`**.

After changing harvest or pipeline outputs, re-run **`make extract-saves`** then **`make ue5-bundle`** so `saves.json` and the UE bundle stay aligned.

### Stage 2 environment knobs (`scripts/stage2_review_extract.sh`)

See script headers for the full list. Common variables:

| Variable | Default | Meaning |
|----------|---------|---------|
| `TEXTURE_PNG` | `1` | Pass `--png` to texture extractor (ffmpeg for DDS→PNG). |
| `STAGE2_DIALOG` | `1` | Run dialog extractor per blob. |
| `STAGE2_LEVEL` | `0` | Run level extractor per blob (slow); emits **`level_hints.json`**. |
| `HAVOK_CONVEX_OBJ` | `1` | Emit convex hull OBJ stubs from Havok blobs. |
| `STAGE2_EMBEDDED_AUDIO` | `0` | Run `pws_extractor` on each `.bin` for embedded RIFF/Ogg (very slow). |
| `STAGE2_JOBS` | **auto** (`min(48, CPU count)` via `stage2_parallel.sh`) | Parallel blobs per wave; set explicitly to cap load (e.g. `STAGE2_JOBS=8`). |
| `TEXTURE_INDEX` | **auto-set** by **`make review-all`** / **`make extract-all`** | Path to **`texture_index.json`**; enables **`--texture-index`** on mesh + texture steps (`shared_textures.json` when applicable). |
| `STAGE2_GLTF` | `1` | Emit **`mesh_scene.gltf`** (+ `.bin`) via `gltf_exporter.py`. Set `0` to skip. |
| `STAGE2_SKIP_UCFX` | `0` | Skip `ucfx_parser` / `ucfx.json`. |
| `STAGE2_SKIP_MESH` | `0` | Skip mesh extraction. |
| `STAGE2_SKIP_TEX` | `0` | Skip texture extraction. |
| `STAGE2_SKIP_HAVOK` | `0` | Skip Havok extraction. |
| `MESH_FORMAT` | `obj` | Mesh output format (`obj` or `gltf`). |

Batch path extraction (`scripts/extract_all_from_paths.sh`): default **bulk** sges (`sges_decompress.py --bulk-out-dir`, one mmap + one scan). **`EXTRACT_JOBS=1`** forces per-block subprocesses. **`WITH_UCFX=1`** writes **`extracted/batch_*/ucfx_manifests/*.json`** (bulk runs `ucfx_parser` per block in-process); **`ALLOW_PARTIAL=1`** continues after per-block failures. See script headers for **`EXTRACT_OUT_ROOT`**, **`START`**, **`MAX`**, **`SKIP_EXISTING`**, **`PYTHON`**.

**`level_extractor.py --precache-root`** adds **`precache_files`** to **`level_hints.json`** when run manually; stage 2 does not pass it by default.

## Legacy note

Block offsets are determined by scanning `sges` markers in order (same order as `paths.txt`).

See `docs/quickbms_notes.md`, `docs/game_extractor_notes.md`, and **`docs/format_reference.md`** for cross-tool workflows and binary field reference.

