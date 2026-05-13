# Mercenaries 2 (PC) — binary & metadata format reference

This document records what the repo’s **tools** actually parse, which fields are still **unknown**, and where deeper layout lives in code. For command-line usage see [`tools/README.md`](../tools/README.md).

---

## 1. Save profile (`.profile`)

**Tool:** [`tools/savefile_parser.py`](../tools/savefile_parser.py)

### 1.1 Binary header (bytes before zlib)

| Offset | Size | JSON field | Notes |
|--------|------|------------|--------|
| `0x00` | 4 | `checksum_hex` | u32, printed as `0x%08X` |
| `0x04` | 4 | `version` | u32 |
| `0x08` | 4 | `data_size_field` | u32 |
| `0x0C` | 4 | `unknown_0x0C` | **Unknown** |
| `0x10` | 4 | `unknown_0x10` | **Unknown** |
| `0x14` | 4 | `n_time_elapsed_seconds` | Interpreted as play time |
| `0x18` | 4 | `n_cash` | |
| `0x1C` | 4 | `n_fuel` | |
| `0x20` | 4 | `unknown_0x20` | **Unknown** |
| `0x24` | 4 | `unix_timestamp` | u32 |
| `0x2C` | 16 | `s_last_mission_name_ascii` | NUL-padded ASCII, trimmed |
| `0x3C`–`0x4B` | 16 | — | **Not structured** in tooling |
| `0x4C` | 4 | `flags_0x4C_hex` | u32 as hex string |
| `0x50`–`0x209` | — | — | **Not structured** (gap before costume / name) |
| `0x24A` | 1 | `character_costume_index` | Single byte |
| `0x20A` | — | `reference_name_utf16` | UTF-16 LE, NUL-terminated (max 64 chars read) |

Default **zlib** payload start: **`0x468` (1128)** — `ZLIB_OFFSET_DEFAULT`. Override with `--zlib-offset` if needed.

### 1.2 Decompressed Lua (regex harvest only)

Tables are **not** parsed as Lua; strings are matched with regex. Output keys include `mission_ids`, `vehicle_tokens`, `support_tokens`, `localization_key_like`, `sys_string_to_guid_hex`, `vz_layer_strings`, `faction_prefixes_from_missions`, each with a matching `*_count` where applicable.

---

## 2. FFCS `.wad` container

**Tools:** [`tools/ffcs_wad.py`](../tools/ffcs_wad.py), [`tools/mercs2_ffcs_extract.py`](../tools/mercs2_ffcs_extract.py)

| Field | Notes |
|--------|--------|
| Magic | `FFCS` |
| Version | u32 after magic |
| Declared chunk count | u32; **retail files may declare 7** while only **five** 12-byte chunk rows exist before the `0x48` region |
| Chunk row | 4-byte ASCII tag + **offset** u32 + **meta** u32 (12 bytes per row). **`meta` is not decoded** semantically |
| `CSUM` | **Hashes**, not a byte span; `size` in manifest is **0** |
| `INDX`, `DATA`, `ASET`, `PTHS` | Spatial chunks; **inferred byte length** by sorting by offset; `DATA` extends to EOF |

`PTHS` yields `paths.txt` path-like strings (see `dump_paths_from_pths`).

---

## 3. `sges` compressed block

**Tool:** [`tools/sges_decompress.py`](../tools/sges_decompress.py)

| Offset | Field |
|--------|--------|
| `0` | Magic `sges` |
| `4` | `major`, `minor` (u16 LE) |
| `8` | `total_u` uncompressed size (u32) |
| `12` | `total_c` compressed hint (u32) |
| Header | Segment table (`minor` × 8 bytes), then **16-byte-aligned** start of payload |
| Payload | Repeated **raw deflate** (`zlib` windowBits `-15`) segments separated by **zero padding** |

The **n-th** `sges` in `data.bin` corresponds to the **n-th** line in `paths.txt` (same indexing as batch scripts).

---

## 4. UCFX (decompressed blob)

**Shallow scan:** [`tools/ucfx_parser.py`](../tools/ucfx_parser.py) — tag occurrence counts, Havok keyword hits, ASCII `strings_sample` (capped in output), `geom_chunk_trees` preview after each `GEOM`.

**Deep mesh / texture layout:** [`tools/ucfx_mesh_codec.py`](../tools/ucfx_mesh_codec.py), [`tools/mesh_extractor.py`](../tools/mesh_extractor.py), [`tools/texture_extractor.py`](../tools/texture_extractor.py)

- **UCFX** root: magic + four u32 header fields (`u0`–`u3`); `data_base = ucfx_off + u0` for child chunks.
- **Chunk table:** 20-byte rows: 4-byte tag + four u32s (`read_chunk_header`). Tags parsed in mesh path include **GEOM**, **MESH**, **PRMG**, **STRM**, **IBUF**, **INFO**, **MTRL**, **PRMT**, **HIER**, **SWIT**, **NAME**, **BODY** (texture). Others (**CHDR**, **STAT**, **CEXE**, **enum**, **flgt**, **flgs**, **INDX**, …) may appear in **`tag_occurrences`** without a dedicated decoder.
- **CONTAINER_SENTINEL** `0xFFFFFFFF` on chunk row `u0` marks nested-container boundaries in some walks.

### 4.1 UCFX texture INFO (minimal)

**Tool:** [`tools/texture_extractor.py`](../tools/texture_extractor.py)

| Offset (in INFO body) | Field |
|------------------------|--------|
| `+0`, `+2` | width, height (u16) |
| `+6` | mip_count (u16) |
| `+14` | FourCC (DXT1 / DXT3 / DXT5 for supported path) |
| `+22` | total_size (u32) | Bytes for full mip chain in BODY |

Bytes between documented fields are **read but not exported** as named fields.

### 4.2 Texture streaming index

**Tool:** [`tools/texture_streaming_index.py`](../tools/texture_streaming_index.py)

Per-entry: `asset_hash`, `type_hash`, reserved, `size`. Build filters **texture** type hash; used for cross-block mip assembly (`texture_index.json`).

---

## 5. Havok slices (blob carve-out)

**Tool:** [`tools/havok_extractor.py`](../tools/havok_extractor.py)

- Searches for `hkxp`, `<hkpackfile`, `Havok`.
- Writes **raw binary slices** (default max 256 KiB each) and optional **heuristic** `convex_hull_*.obj` from longest run of plausible `f32` triplets after `hkpConvexVerticesShape`.
- **No** Havok class table, version string, or rigid-body graph parsing.

`havok/manifest.json` (stage 2): `havok_slices` list with `offset`, `size_written`, `preview` (short ASCII snippet).

---

## 6. CERP precache

**Tool:** [`tools/cerp_precache.py`](../tools/cerp_precache.py)

| Offset | Field |
|--------|--------|
| `0` | Magic `CERP` |
| `4` | Version u32 |

Remainder of file is **not** structurally decoded in tooling; use `--json` / `--out` for a hex preview blob, or hex dump in default CLI mode.

---

## 7. PWS / embedded audio banks

**Tool:** [`tools/pws_extractor.py`](../tools/pws_extractor.py)

- **RIFF**: total size from RIFF length dword; nested **`fmt `** chunk parsed when present (**WAVE**): JSON fields `wave_audio_format`, `wave_sample_rate`, `wave_channels`, `wave_bits_per_sample`, `wave_byte_rate`, `wave_block_align`, and **`wave_duration_seconds`** when a `data` chunk exists and `wave_byte_rate > 0`.
- **OggS**: heuristic slice (up to 512 KiB); **no** full stream parse or duration.

Outputs `pws_manifest.json` per source directory and optional `pws_summary.json` for multi-input runs.

---

## 8. ECS manifest (INI + EXE strings)

**Tool:** [`tools/mercs2_ecs_manifest.py`](../tools/mercs2_ecs_manifest.py)

- **`cdbsizes.ini`** `[presize]`: component name → list of integer sizes.
- **`Mercenaries2.exe`**: `strings -n 8` + regex for API-like symbols (`Add|Set|Get|…`).

Output `output/ecs_manifest.json`: `symbols` array is **capped at 8000 entries**; see `symbol_count` for full distinct count (`symbols_max_output` in JSON).

---

## 9. Stage 2 JSON sidecars (review tree)

Typical path: `<pipeline>/extracted/review/<batch_pack>/<stem>/`

| File | Producer | Purpose (short) |
|------|----------|-------------------|
| `ucfx.json` | `ucfx_parser.py` | Tag hits, DXT/Havok strings, `geom_chunk_trees` preview |
| `mesh.meta.json` | `mesh_extractor.py` | Topology, LOD, counts, material indices, `extract` debug |
| `mesh.obj` / `mesh.gltf` | `mesh_extractor.py` | Geometry |
| `mesh_scene.gltf` (+ `.bin`) | `gltf_exporter.py` (when enabled) | Scene glTF |
| `submeshes/index.json` | `mesh_extractor.py --per-submesh-obj` | Per-part bbox, transforms, counts |
| `shared_textures.json` | `mesh_extractor.py` | Cross-block texture refs when `--texture-index` set |
| `textures/manifest.json` | `texture_extractor.py` | Texture list / paths |
| `textures/texture_manifest.json` | `texture_extractor.py` | Richer manifest (source blob, PNG, entries) |
| `havok/manifest.json` | `havok_extractor.py` | Slice list + optional convex heuristic |
| `dialog_fragments.json` | `dialog_extractor.py` | Bracket / Generic / UTF-16 key harvest |
| `level_hints.json` | `level_extractor.py` (optional) | `matrix_candidates`, optional `precache_files` |

Global: **`texture_index.json`** (repo-relative default under `extracted/`) from `texture_streaming_index.py` — drives `--texture-index` in stage 2 when **`TEXTURE_INDEX`** is set.

---

## 10. Related docs

- [`tools/README.md`](../tools/README.md) — commands, pipeline, artifact index, env vars.
- [`docs/game_extractor_notes.md`](game_extractor_notes.md), [`docs/quickbms_notes.md`](quickbms_notes.md) — external tooling workflows.
- [`UnrealEngineGame/README.md`](../UnrealEngineGame/README.md) — Maracaibo demo list (`maracaibo_asset_list.json`).
