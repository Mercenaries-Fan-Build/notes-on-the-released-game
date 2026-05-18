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
| `CSUM` | CSUM chunk row `offset` is **NOT a file offset** — it is a hash/identifier (exceeds file size for demo vz.wad, shell.wad, Loading.wad). `meta` gives an entry count (7,018 for retail vz.wad) that does NOT correspond 1:1 to blocks (11,370). Per-UCFX integrity uses CRC-32(init=0) trailers embedded in decompressed block data (see §4.0). The FFCS-level CSUM chunk's actual purpose and storage remain **unknown** |
| `INDX` | Block index; 12-byte entries: `(page_index, packed_field, flags_and_page_count)`. `page_index × 0x8000` = WAD file offset of the sges block. `flags_and_page_count & 0xFFFF` = number of 32KB pages the block spans |
| `DATA`, `ASET`, `PTHS` | Spatial chunks; **inferred byte length** by sorting by offset; `DATA` extends to EOF |

`PTHS` yields `paths.txt` path-like strings (see `dump_paths_from_pths`).

**ASET (asset set / streaming graph hints):** [`docs/aset_format.md`](aset_format.md) — 16-byte rows; [`tools/aset_decoder.py`](../tools/aset_decoder.py) emits [`output/block_dependency_graph.json`](../output/block_dependency_graph.json) (retail: `u32_0` hits `texture_index.json` keys for a large subset of rows). Hash algorithm confirmed as **FNV-1a with `|0x20` case suppression** (see [`docs/modding_deep_dive.md` §4.3.1](modding_deep_dive.md) and `tools/pandemic_hash.py`).

**ECS `COMP` harvest:** [`docs/ecs_components.md`](ecs_components.md) — [`tools/ucfx_ecs_codec.py`](../tools/ucfx_ecs_codec.py) + [`tools/ecs_metadata_extract.py`](../tools/ecs_metadata_extract.py) → `output/placements/ecs_components.json` and merged `ecs` keys on placement JSON when `make extract-placements` runs.

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

### 4.0 CSUM trailer (per-chunk integrity)

Each UCFX chunk inside a decompressed block file is followed by an 8-byte **CSUM** trailer:

| Offset | Size | Field |
|--------|------|-------|
| `+0` | 4 | ASCII tag `CSUM` |
| `+4` | 4 | u32 LE checksum value |

**Algorithm — CRC-32 (init=0, no final XOR)** (verified against **53,765 chunks across 10,099 block files**):

| Parameter | Value |
|-----------|-------|
| Polynomial | `0x04C11DB7` (normal) / `0xEDB88320` (reflected) |
| Init value | `0x00000000` |
| Final XOR | `0x00000000` |
| Reflect in | Yes |
| Reflect out | Yes |

This uses the standard CRC-32 polynomial (ISO 3309 / ITU-T V.42) but with **init=0** and **no final inversion**. Note: this is neither standard CRC-32 (init=0xFFFFFFFF, xorout=0xFFFFFFFF) nor CRC-32/JAMCRC (init=0xFFFFFFFF, xorout=0x00000000) — it is a custom variant with init=0.

**Input range:** The checksum covers the entire byte range from the start of the `UCFX` tag (inclusive) to the byte immediately before the `CSUM` tag. For multi-chunk block files, each UCFX chunk has its own trailing CSUM that covers only that chunk.

**Block file structure:** `count(4)` + `count × entry(16)` + concatenated chunks. Each header entry is `(name_hash, type_hash, field_c, chunk_size)` as u32 LE. Each chunk is `UCFX_header(8) + UCFX_body(variable) + "CSUM"(4) + checksum(4)`. The `chunk_size` field in the header entry gives the total chunk length including the CSUM trailer.

**Python implementation:**

```python
import zlib

def crc32_mercs2(data: bytes) -> int:
    """CRC-32 with init=0, no final XOR (Mercenaries 2 CSUM algorithm)."""
    # Python zlib internally does: init' = init ^ 0xFFFFFFFF, ..., result ^ 0xFFFFFFFF
    # So zlib.crc32(data, 0xFFFFFFFF) ^ 0xFFFFFFFF gives table-CRC with init=0, no final XOR
    return (zlib.crc32(data, 0xFFFFFFFF) ^ 0xFFFFFFFF) & 0xFFFFFFFF
```

Equivalent explicit table implementation:

```python
def crc32_mercs2_explicit(data: bytes) -> int:
    table = [0] * 256
    for i in range(256):
        c = i
        for _ in range(8):
            c = (c >> 1) ^ 0xEDB88320 if c & 1 else c >> 1
        table[i] = c
    crc = 0
    for b in data:
        crc = table[(crc ^ b) & 0xFF] ^ (crc >> 8)
    return crc
```

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

Pipeline (optional): **`<pipeline-root>/animations_work/<slug>/mesh_skin.json`** — bone-name harvest + empty skin placeholder from [`tools/hk_skeleton.py`](../tools/hk_skeleton.py) during [`tools/mercs2_anim_pipeline.py`](../tools/mercs2_anim_pipeline.py).

Global: **`texture_index.json`** (repo-relative default under `extracted/`) from `texture_streaming_index.py` — drives `--texture-index` in stage 2 when **`TEXTURE_INDEX`** is set.

---

## 10. Related docs

- [`tools/README.md`](../tools/README.md) — commands, pipeline, artifact index, env vars.
- [`docs/game_extractor_notes.md`](game_extractor_notes.md), [`docs/quickbms_notes.md`](quickbms_notes.md) — external tooling workflows.
- [`docs/modding_deep_dive.md`](modding_deep_dive.md) — DRM analysis, hash system identification, Lua bytecode format, `vz.bin` decode, and modding feasibility roadmap.
- [`UnrealEngineGame/README.md`](../UnrealEngineGame/README.md) — Maracaibo demo list (`maracaibo_asset_list.json`).

---

## 11. Anim group block + Havok 5.5 packfile (skeletal pipeline)

**Carving:** [`tools/animgroup_extractor.py`](../tools/animgroup_extractor.py) — each ``output/extracted/batch_*/blocks/*animgroup*.block.bin`` begins with a **record table** (16 bytes per record: ``u32 checksum``, ``u32 magic`` = ``0x18166555``, ``u32 reserved``, ``u32 record_size``), followed by concatenated **UCFX** wrappers. Inside each wrapper the Havok slice starts at the ASCII version token ``Havok-5.5.0-r1``; the tool writes standalone ``record_NNNN.hkx`` bytes plus ``records.json``.

**Packfile:** [`tools/hk_packfile.py`](../tools/hk_packfile.py) parses the three 48-byte section headers (``__classnames__``, ``__types__``, ``__data__``), the hashed classname table, and the **four chained fixup streams** inside ``__data__`` (local → global → virtual → finish, each terminated by ``0xFFFFFFFF`` dword pairs). **Local** fixups are applied to build ``data_patched.bin``. **Global** fixups are optional (``--apply-global``) while pointer semantics are validated against external dumps (hkxcmd). ``packfile.json`` includes ``types_preview`` (hex head of ``__types__``), fixup counts, and a coarse ``data_class_hits_sample`` (u32 hits against classname hashes).

---

## 12. Havok 5.5 skeletal animation compression (Mercenaries 2)

| Class | Module | Status in repo |
|--------|--------|----------------|
| ``hkaInterleavedUncompressedAnimation`` | [`tools/hk_anim/interleaved.py`](../tools/hk_anim/interleaved.py) | **Implemented:** ``numTransformTracks`` × ``numFrames`` × 40-byte ``hkQsTransform`` + optional float tracks. |
| ``hkaDeltaCompressedSkeletalAnimation`` | [`tools/hk_anim/delta.py`](../tools/hk_anim/delta.py) | **Header/meta** (duration, track count, hints); **bitstream** reconstruction still TODO (see HKLib delta path). |
| ``hkaWaveletSkeletalAnimation`` | [`tools/hk_anim/wavelet.py`](../tools/hk_anim/wavelet.py) | **Placeholder** sinusoidal motion for pipeline validation; coefficient inverse-lifting TODO — debug hook stub in [`tools/hk_anim/_wavelet_debug.py`](../tools/hk_anim/_wavelet_debug.py). |

**Emit / import:** [`tools/mercs2_anim_pipeline.py`](../tools/mercs2_anim_pipeline.py) → [`tools/anim_gltf_export.py`](../tools/anim_gltf_export.py) (``pygltflib`` skeletal **.glb**). UE5 bundle copies into ``ue5_import/animations/`` and lists clips in ``metadata/manifest.json`` (``tools/ue5_export.py``).

---

## 13. low_res_terrain block + lrterrain tile lookup

**Tool:** [`tools/terrain_extractor.py`](../tools/terrain_extractor.py)

`03121_blocks__VZ__low_res_terrain_P000_Q3.block.bin` (≈7 MB) packs the
20×20 Maracaibo low-resolution terrain grid as **401 UCFX containers**
indexed by a leading 16-byte-per-entry TOC:

| Entry | Field | Notes |
|-------|-------|-------|
| `[0]` | `count` u32 | Total TOC entry count (= 401) |
| `[1..400]` | `(size, hash1, hash2, 0)` u32×4 | Per-tile UCFX byte-size (`size`), per-tile **mesh asset hash** (`hash1`), constant `hash2 = 0x1602815c` |

The 401 UCFX containers are laid out back-to-back after the TOC:
- 400 are terrain tile meshes (each `INFO + MTRL + GEOM(BNDS+PRMT+STRM+IBUF)`,
  no `PRMG`); their TOC byte-deltas match the inter-UCFX spacing exactly.
- 1 is a special 3-chunk container (`NAME="vz_lrterrain" + INFO + BODY`)
  carrying the **shared DXT1 terrain texture** (`vz_lrterrain.dds`), not a
  tile lookup table.

**Tile → (row, col):** the TOC has no positional metadata. The mapping is
in `layers_static` sub-block 13 via the `LowResTerrainObject` COMP — see
[`docs/placement_data_format.md` §2.9](placement_data_format.md). 400 records
of `(entity_key, mesh_hash, scene_object_id)` in row-major order; the
record's **list index** is the (row, col) and `mesh_hash` matches the TOC's
per-tile `hash1`. `tools/terrain_extractor.py` uses this mapping
(`grid_source = "metadata_lookup"` in `mesh.meta.json`) and falls back to
seam-matching only if the `layers_static` blob is unavailable.

**Vertex format per tile:** STRM `data` is a flat vertex buffer (no PRMG row);
stride is `vb_len // n_verts` (typically 16 B = pos f16×3 + UV f16×2 + 2 B
pad). Positions are decoded as **f16 vec3** in tile-local space (≈±200 m on
X/Z, ymin/ymax per the tile's BNDS chunk). Each tile's BNDS is 40 B holding
`bbox_center.xyz, radius, bbox_min.xyz, bbox_max.xyz`. After local decode,
vertices are offset to the world placement of the matching `lrterrain_rXX_cYY`
(centers at `(-3800 + col*400, 0, -3800 + row*400)`).

### 13.1 TOC entry 0 is a real tile slot, entry 224 is a dummy

Two structural quirks of the retail PC `low_res_terrain` TOC that matter for
correct tile routing:

1. **TOC entry 0 is dual-purpose.** Its first u32 stores the count (`= 401`)
   but its second u32 is a valid mesh `hash1` for a real tile (cell
   `(17, 9)` in the retail build). Earlier extractor code that iterated
   `range(1, n_entries)` skipped entry 0's hash and routed `(17, 9)` to the
   unused TOC entry's mesh via a "unique-unused-index" fallback.
2. **TOC entry 224 is a dummy.** Its `u2` is `0xf011157a` (every other tile
   entry has `0x1602815c`) and its `hash1` does not appear in any
   `LowResTerrainObject` record. The UCFX container at the entry's expected
   offset has `u3 = 3` (vs the normal `u3 = 12`), so
   `iter_ucfx_containers()` filters it out via its `u3 < 10` threshold. The
   400 "real" UCFX iter indices therefore correspond to TOC entries
   `{0, 1..223, 225..400}`, with index shift `−1` past the dummy.

`tools/terrain_extractor.py::_read_low_res_terrain_toc()` implements the
correct mapping by walking the cumulative TOC offsets, skipping any entry
whose UCFX is filtered out, and emitting `hash1 → iter_index` for the rest.

### 13.2 Tile-local axis convention

Each tile mesh is authored centered at the origin with X/Z ∈ `[−200, 200]`.
**Row index increases with world Z** (placement
`center_z = −3800 + row × 400`). The tile-local face naming used by
`_edge_samples` is unusual: `"N"` is the `z = +TILE_HALF` face and `"S"` is
the `z = −TILE_HALF` face, i.e. the labels are **inverted relative to the
row convention**. For the seam between tiles `(r, c)` and `(r + 1, c)`, the
correct pairing is:

- Upper tile (smaller r, smaller world Z) world-south face = local
  `z = +TILE_HALF` = code label `"N"`.
- Lower tile (larger r, larger world Z) world-north face = local
  `z = −TILE_HALF` = code label `"S"`.

So adjacency pairs are `(a."E", b."W")` for column adjacency and
`(a."N", b."S")` for row adjacency. Comparing `a."S"` to `b."N"` instead
(as earlier versions of `terrain_extractor.py`, `probe_terrain_offsets.py`
and `solve_terrain_offsets.py` did) compares two non-adjacent faces 800 m
apart in world Z and produces nonsense residuals (the metric appeared as
"92 m mean seam" before the fix; the true value is ≈ 2 mm).

### 13.3 Seam continuity verdict

With both bugs above resolved, the source tile meshes are **already
seam-continuous**: mean per-edge mismatch ≈ 0.002 m, max ≈ 0.68 m, no
per-tile offset solve required. `mesh.meta.json` records this with
`transform_source: "none_source_seam_continuous"`.

Twenty cells are placeholder "open-water" tiles authored as a single quad
(`vertex_count = 4`, `triangle_count = 2`, `dy = 0`). They sit on the outer
map rim (col 0, col 19, row 19, plus a few coastal-cutout interior cells —
e.g. `(9, 15)`). Because their edges only contribute the two corner
along-coord buckets, they fail the `≥ 3 matched buckets` threshold most
solvers use and appear "disconnected" in seam graphs. They are listed in
`mesh.meta.json::ocean_tile_iter_indices`; downstream importers should
keep them at world Y = 0 (sea level) without further transform.

### 13.4 Terrain texture pipeline

The `low_res_terrain` block ships exactly **one** texture: `vz_lrterrain`,
a 2048×2048 DXT1 atlas covering the entire 8 000 × 8 000 m continent. It
is referenced by every merged tile via a planar XZ projection synthesized
at merge time (the source vertex stream carries no UVs).

#### 13.4.1 UV convention (Case 4 — generated)

Per-vertex UV layout in the source tile mesh: **none.** The 16-byte
vertex stride decomposes as `f16 pos.xyz (6) + f16 w (2) + f16 normal.xyz
(6) + f16 pad (2)`; values at byte offset 8 are unit-length normals, not
UVs. This rules out all three documented "case 1/2/3" UV conventions —
there is nothing to remap from.

`tools/terrain_extractor.py::_world_xz_to_uv` synthesizes UVs from world
position (planar XZ over the 8 000 m continent):

```
u = (world_x + 4000) / 8000
v_raw = (world_z + 4000) / 8000
v = 1 - v_raw   when _TEXTURE_V_FLIP is True (retail default)
```

The `vz_lrterrain` atlas is authored D3D9-style (V=0 at image top = game
north / high Z). Raw planar projection maps south (low Z) to low V (image
bottom), so synthesis applies `v = 1 - v` via `_TEXTURE_V_FLIP = True`.
The PNG is **not** rotated at load time.

`make extract-terrain` writes `mesh_scene.glb` via
`_build_terrain_glb` (pygltflib), **not** via `gltf_exporter`. That path
embeds the synthesized UVs as-is (no second `convert_uvs_d3d_to_gltf`) but
**does** apply the same LH→RH position/normal Z-negate and triangle winding
flip as `gltf_exporter`, so the merged mesh at the origin actor aligns with
`game_to_ue` placements like other imported GLBs.

Regular meshes with UVs baked in the vertex buffer use `gltf_exporter`'s
`convert_uvs_d3d_to_gltf` for the D3D9 V-flip.

#### 13.4.2 Aux texture entries in the TOC

The TOC has 401 entries:

- entry 0 stores the count in its first u32 *and* a real mesh hash in its
  second u32 (see §13.1) — it iterates as a normal mesh tile;
- entries 1..400 except entry 224 are mesh tiles (`u3 = 12`, chunks
  `INFO/GEOM/STRM/IBUF/MTRL`); 400 mesh tiles total;
- **entry 224 is the texture entry** (`u3 = 3`, chunks `INFO/NAME/DXT1`,
  payload contains the literal name `vz_lrterrain` followed by the DXT1
  pixel data). It is filtered out of the mesh iteration by
  `iter_ucfx_containers` because of the `u3 < 10` guard.

The aux-texture walk (`tools/terrain_extractor.py::_walk_terrain_toc_aux_textures`)
runs a file-wide DXT/BC signature scan and a per-entry NAME-chunk probe.
For the retail PC build the result is:

```
mesh_count        = 399  (mesh-shaped entries minus entry 224 itself
                          and entry 0 which the codec does iterate)
named_entries     = 2    (both reference vz_lrterrain — entry 224 and
                          its 12 124-byte stub at TOC index 223 whose
                          payload bleeds into entry 224's NAME chunk
                          due to the way the size field is laid out)
aux_entries       = 0    (no NAME other than vz_lrterrain)
signature_scan    = {DXT1: 1, DXT3: 0, DXT5: 0, DX10: 0, BC4: 0, BC5: 0}
```

**Conclusion**: the low-LOD merged terrain has only a diffuse atlas — no
embedded normal, specular, gloss, AO, or height map. Higher-fidelity
per-cell terrain ships separately as `vz_terrainglobal_r##_c##` textures
(174 918 B each, in `c30NNN` cell blocks) and is out of scope for the
merged low-LOD bake.

#### 13.4.3 Why the GLB embeds the texture

`tools/terrain_extractor.py::_build_terrain_glb` emits the master texture
into a GLB `bufferView` (MIME `image/png`) rather than as a sibling URI
(the debug OBJ path still references `submeshes/index.json` for tooling):

- UE 5.7's Interchange importer reliably picks up embedded PNGs and
  binds them to the material slot during import. URI references require
  the file to be co-located at import time and tend to break when the
  GLB is moved.
- A self-contained GLB is the only artifact the rest of the pipeline
  needs to ship to UE — there is no sibling-PNG copy step in
  `regen_maracaibo_glbs` or `populate_world.py`.
- DXT1 is transcoded to PNG before embedding because UE's importer
  treats embedded DDS as opaque binary and yields a white material.

The terrain material asks for `metallicFactor = 0`, `roughnessFactor = 1`,
`baseColorFactor = [1, 1, 1, 1]`, `doubleSided = false` — wired through
the per-entry overrides supported by `tools/gltf_exporter.py` (read from
`submeshes/index.json` keys `metallic_factor` / `roughness_factor` /
`base_color_factor` / `double_sided`).

#### 13.4.4 Multi-channel material support (forward-compat)

`tools/gltf_exporter.py` accepts the full glTF PBR channel set even
though lrterrain only populates `texture_diffuse`. The `index.json`
keys, in order of resolution priority, are:

| index.json key | glTF slot | Notes |
|----------------|-----------|-------|
| `texture_diffuse` | `pbr.baseColorTexture` | sRGB 4-channel |
| `texture_normal` | `material.normalTexture` | tangent-space, 2-channel reconstruction supported by UE |
| `texture_metallic_roughness` | `pbr.metallicRoughnessTexture` | glTF-spec packing: G = roughness, B = metallic, R = AO (when shared) |
| `texture_occlusion` | `material.occlusionTexture` | R-channel AO |
| `texture_emissive` | `material.emissiveTexture` | sRGB |
| `texture_specular` | `material.extras.mercs2_specularTextureIndex` | retained for legacy Mercenaries 2 specular workflow |

When a 2008-era specular map needs to be converted to the glTF MR
packing, the recommended remap is `roughness = 1.0 − specular_intensity`
written into the G channel of a freshly-generated 8-bit RGBA PNG, with
R = 255 (or AO if available) and B = 0 (terrain non-metallic). The
build then sets `texture_metallic_roughness` to the converted PNG name.
This conversion is **not** performed for lrterrain because no specular
source exists in this block; the implementation lives in the exporter
ready to consume it once a source is identified for other materials.
