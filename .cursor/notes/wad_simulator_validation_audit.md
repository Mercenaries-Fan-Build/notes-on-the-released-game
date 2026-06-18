# WAD Simulator Validation Audit

**Date:** 2026-05-28  
**Scope:** `tools/wad_simulator/` — all 17 source modules vs project format knowledge  
**Purpose:** Identify gaps between current structural validation and possible content-aware validation

---

## A. Current Validation Summary

### A.1 `main.rs` (lines 1–177) — CLI & Orchestration

- Parses CLI args (WAD paths, flags, limits, thread count)
- Runs two phases: ASET OOB validation (`aset_validate`), then full engine simulation (`simulate`)
- Reports exit code based on access violations, decode errors, unresolved hashes
- **Validation depth:** Orchestration only — delegates all checks

### A.2 `ffcs.rs` (lines 1–206) — FFCS WAD Header

| Check | Lines | Detail |
|-------|-------|--------|
| Magic `FFCS` | 77–79 | Rejects non-FFCS files |
| Version == 2 | 80–83 | Only accepts version 2 |
| Chunk row parsing | 84–97 | Reads up to 5 chunk rows (12 bytes each) |
| INDX entry parsing | 104–118 | 12-byte entries: `page_index`, `packed_field`, `flags_and_page_count` |
| ASET entry parsing | 121–137 | 16-byte entries: `asset_hash`, `secondary_ref`, `packed_block_ref`, `type_id` |
| PTHS path parsing | 140–183 | Null-separated strings with basic sanity (16 MB cap) |
| Required chunks | 190–193 | Fails if INDX or ASET missing |

**Not validated:** Chunk offset ordering, DATA chunk bounds, CSUM chunk at WAD level, PTHS trailer marker (258-byte mandatory null-terminated ASCII trailer).

### A.3 `sges.rs` (lines 1–132) — sges Decompression

| Check | Lines | Detail |
|-------|-------|--------|
| Magic `sges` | 19–24 | 4-byte magic validation |
| Segment table bounds | 28–31 | `block_data.len() < table_start + table_size` |
| Segment data bounds | 66–71 | Each segment's `[start..end]` vs block size |
| Decompression errors | 76–86 | Catches `BufError` and inflate errors per segment |
| Block index bounds | 101–105 | `block_index < indx_entries.len()` |
| Uncompressed passthrough | 118–130 | Handles raw UCFX blocks (no sges wrapper) |

**Not validated:** Total decompressed size vs `total_uncompressed` header field, 64 KB sentinel for final segment, segment alignment, `version` field validation.

### A.4 `ucfx.rs` (lines 1–301) — UCFX Container Parsing

| Check | Lines | Detail |
|-------|-------|--------|
| UCFX magic | 117–123 | 4-byte `UCFX` magic |
| Container minimum size | 110–116 | Rejects containers < 20 bytes |
| CSUM trailer CRC-32 | 126–141 | Verifies CRC-32 (init=0, poly 0xEDB88320) against last 8 bytes |
| Block entry table parse | 35–54 | Reads `count` + 16-byte entries (`name_hash`, `type_hash`, `field_c`, `chunk_size`) |
| Entry chunk_size bounds | 65–74 | `pos + chunk_size <= decompressed.len()` |
| Descriptor table walk | 143–184 | Validates descriptor body ranges vs container size |
| Skip list for non-standard types | 98–101 | Animations and textures skip descriptor walk (avoid false positives) |

**Not validated:** `data_area_off` consistency (should equal header size + descriptor table size), `field_c` semantics, descriptor tag validity (only checks bounds, not known-tag enumeration).

### A.5 `overlay.rs` (lines 1–165) — VirtualDisk / ASET Overlay

| Check | Lines | Detail |
|-------|-------|--------|
| Patch-wins-over-base | 52–81 | Last-opened-file-wins overlay (patch hash overrides base hash) |
| Block index extraction | 127–129 | `packed_block_ref >> 16` |
| Sub-entry extraction | 131–133 | `packed_block_ref & 0xFFFF` |
| Primary detection | 135–137 | `sub_entry == 0xFFFF` |

**Not validated:** Block index vs INDX count (deferred to decompress time), type_id vs known type registry consistency, duplicate hash detection within same WAD.

### A.6 `aset_validate.rs` (lines 1–154) — ASET OOB Heap Diagnostic

| Check | Lines | Detail |
|-------|-------|--------|
| Sub-entry OOB | 102–103 | `sub_entry < entry_count` for each non-primary ASET entry |
| Garbage entry read | 36–47 | Reads what the engine would see at OOB position |
| Xbox pattern detection | 106–107 | `sub_entry == block_idx` (Xbox 360 encoding artifact) |
| Decompression failures | 97–99 | Counts blocks that fail to decompress |

**Not validated:** This is diagnostic-only (not part of the main consume pipeline). Does not check data integrity of resolved entries.

### A.7 `blocks.rs` (lines 1–191) — Parallel Block Cache

| Check | Lines | Detail |
|-------|-------|--------|
| Parallel decompression | 74–115 | Rayon thread pool decompresses all unique blocks |
| Parallel UCFX parse | 123–182 | Walks each decompressed block through `walk_decompressed_block` |
| Issue merge | 184–190 | Collects all UCFX walk issues into report |

**Not validated:** Block deduplication correctness, memory pressure limits.

### A.8 `consume.rs` (lines 1–42) — Dispatch & Structural Consumer

| Check | Lines | Detail |
|-------|-------|--------|
| UCFX magic on container | 23 | `container[0..4] == UCFX` |
| Empty data chunk | 27–29 | Flags empty data bodies |

**Not validated:** This is the fallback consumer for unrecognized types. No content parsing.

### A.9 `placement.rs` (lines 1–15) — Layer / Placement Validation

| Check | Lines | Detail |
|-------|-------|--------|
| `flgs` chunk presence | 7 | Checks if container has a `flgs` descriptor |
| `data` chunk presence | 8 | Checks if data body exists |

**THIS IS THE THINNEST MODULE.** It does not:
- Parse any placement records
- Validate position floats
- Check quaternion normalization
- Validate entity keys or cross-references
- Parse COMP component hierarchy

### A.10 `model.rs` (lines 1–62) — Mesh / Model Validation

| Check | Lines | Detail |
|-------|-------|--------|
| GEOM `n_groups` sanity | 14–16 | Rejects if > 10,000 |
| STRM minimum size | 23–24 | Rejects if < 4 bytes |
| IBUF minimum size | 30–31 | Rejects if < 4 bytes |
| IBUF size consistency | 33–38 | `4 + index_count * 2 <= ibuf.len()` |
| MTRL texture xref | 46–52 | Extracts texture hash from first u32 of MTRL for cross-ref |

**Not validated:** Vertex buffer stride or layout, vertex position float range/NaN, BNDS bounding box consistency, HIER transform matrix validity, INDX→HIER mapping, PRMG submesh definitions, MESH group structure, actual vertex/index data integrity.

### A.11 `texture.rs` (lines 1–35) — Texture Validation

| Check | Lines | Detail |
|-------|-------|--------|
| DDS magic `DDS ` | 16 | 4-byte DDS header check |
| DDS header_size == 124 | 17–19 | Standard DDS header size |
| INFO chunk presence | 25 | Just checks existence |

**Not validated:** Texture dimensions, mip count, DXT format validity, pixel data size consistency, power-of-2 dimensions, INFO field parsing (width, height, format).

### A.12 `animation.rs` (lines 1–13) — Animation Validation

| Check | Lines | Detail |
|-------|-------|--------|
| Non-empty body | 7 | `!body.is_empty()` |

**THIS IS EFFECTIVELY A NO-OP.** It does not:
- Check Havok packfile magic (`\x57\xe0\xe0\x57\x10\xc0\xc0\x10`)
- Validate version string (`Havok-5.5.0-r1`)
- Parse section headers (`__classnames__`, `__types__`, `__data__`)
- Validate fixup streams
- Check animation class fields (duration, track counts)

### A.13 `script.rs` (lines 1–42) — Script Validation

| Check | Lines | Detail |
|-------|-------|--------|
| LuaQ magic | 19 | `\x1BLua` signature |
| Lua version 0x51 | 21–23 | Lua 5.1 bytecode version |
| BINN magic | 26 | `BINN` container |
| Unknown header | 30–34 | Flags unrecognized formats |
| Data too small | 28–29 | < 8 bytes warning |

**Adequate for script container identification.** Could additionally validate Lua header fields (endianness byte, int/number sizes).

### A.14 `audio/wavebank.rs` (lines 1–252) — Wavebank Consumption

| Check | Lines | Detail |
|-------|-------|--------|
| Record count & offset | 74–91 | Header parsing with bounds checks |
| Codec rejection (Xbox) | 116–131 | Rejects codec 0x05 (Xbox ADPCM), 0x01/0x69 (XMA/XMA2) on PC |
| IMA ADPCM decode | 172–189 | Full decode of embedded clips via `ima.rs` |
| Streaming clip validation | 141–169 | Checks external `.pws` file exists and is large enough |
| Record field reads | 104–110 | SafeSlice bounds-checked reads for all clip fields |

**Good depth.** Could additionally validate sample_rate ranges, channel count (1–2 for IMA), clip_hash uniqueness.

### A.15 `audio/soundbank.rs` (lines 1–245) — Soundbank Consumption

| Check | Lines | Detail |
|-------|-------|--------|
| Section offset monotonicity | 43–47 | `data_start <= off1 <= off2 <= off3` |
| Section bounds | 48–50 | `section_off3 <= body.len()` |
| Record stride validation | 55–56 | `(off1 - data_start) % sub_count == 0` |
| u8x4 field exercise | 59–61 | Reads endian-invariant bytes at known offsets |
| Hash resolution | 126–130 | Checks wavebank clip hashes resolve |
| Section B/D index tables | 77–123 | Full walk with SafeSlice bounds checks |

**Good depth, especially for the u8x4 byte-swap issue.** Could additionally validate record_size against known strides (116, 118, 124).

### A.16 `audio/ima.rs` (lines 1–139) — IMA ADPCM Decoder

| Check | Lines | Detail |
|-------|-------|--------|
| Full mono/stereo decode | 55–128 | Step-index clamped (0–88), nibble decode, predictor clamp |
| Block size validation | 61, 93 | 36-byte mono, 72-byte stereo blocks |
| Empty payload check | 56–58, 87–89 | `DecodeError::Empty` |

**Complete implementation.** Matches engine behavior with step index clamping.

### A.17 `pws.rs` (lines 1–83) — External PWS Audio

| Check | Lines | Detail |
|-------|-------|--------|
| Layout detection | 18–37 | Version, mono/stereo, block size alignment |
| IMA payload validation | 71 | Delegates to `validate_ima_payload` |
| Directory scan | 40–82 | Validates all `.pws` files in a directory |

**Adequate.** Could additionally check PWS version field more strictly.

### A.18 `types.rs` (lines 1–122) — Type Registry

- 35 known type_hash → type_id mappings from retail census
- Named type strings for 25 type IDs
- Lookup functions both directions

**Complete for known types.** No validation of unknown type_hash values against registry.

### A.19 `safe_slice.rs` (lines 1–138) — Memory Safety Wrapper

- Bounds-checked `read_u8/u16/u32/f32` with labeled access violations
- Slice/subslice with overflow-safe arithmetic
- Used consistently in audio modules

**Core infrastructure, well-implemented.**

### A.20 `crc32.rs` (lines 1–16) — CRC-32

- Custom CRC-32 (init=0, no final XOR, poly 0xEDB88320)
- Matches engine's CSUM algorithm
- Verified against 53,765+ chunks

**Complete and verified.**

---

## B. Validation Gaps

### B.1 CRITICAL — Would Catch Crashes

#### B.1.1 Placement Position Float Range Validation
**Module:** `placement.rs`  
**Gap:** Zero content validation. The module checks only for `flgs`/`data` chunk existence (2 lines of logic). It does not parse or validate any placement records.

**What's known:** 42-byte Transform records contain position floats at offsets +0x04, +0x08, +0x0C. Valid world range: X ∈ [-3900, +3900], Y ∈ [-103, +393], Z ∈ [-3900, +3900]. The Python `placement_extractor.py` uses wider safety bounds: X,Z ∈ (-6000, +6000), Y ∈ (-500, +1000).

**Why critical:** The spatial hash crash analysis (`docs/spatial_hash_crash_analysis.md`) proves that corrupt position floats (NaN, Inf, or extreme values) cause `cvttss2si` to produce `0x80000000` (integer indefinite), which cascades through the spatial cell computation to produce a garbage hash bucket index. This crashes the engine with an access violation writing to NVIDIA driver memory. **This is the exact crash the project just discovered.**

**Specific checks needed:**
- `f32::is_nan()` and `f32::is_infinite()` on all XYZ position components
- Range check: X,Z ∈ (-6000, +6000), Y ∈ (-500, +1000)
- Parse record count from COMP `schm` (stride validation)
- Record stride == 42 for Transform COMPs

#### B.1.2 NaN/Inf Detection in Vertex Buffers
**Module:** `model.rs`  
**Gap:** STRM vertex data is not parsed beyond checking minimum size (4 bytes).

**What's known:** STRM contains vertex buffers with f32 position data. Corrupt floats in vertex positions would cause the same spatial hash overflow when the engine registers mesh bounding boxes.

**Specific checks needed:**
- Parse vertex count from GEOM/PRMG
- Read first 3 floats of each vertex and check `is_nan()` / `is_infinite()`
- Check vertex positions against world bounds (same range as placements)

#### B.1.3 Havok Packfile Magic Validation
**Module:** `animation.rs`  
**Gap:** Currently just checks `!body.is_empty()`. A completely corrupt animation body would pass.

**What's known:** Valid Havok 5.5 packfiles begin with magic bytes `\x57\xe0\xe0\x57\x10\xc0\xc0\x10` and contain version string `Havok-5.5.0-r1`. Corrupt packfiles could cause engine crashes during animation loading (pointer fixup walks random memory).

**Specific checks needed:**
- 8-byte Havok magic at body start
- Version string presence

### B.2 HIGH — Would Catch Silent Data Corruption

#### B.2.1 Quaternion Normalization
**Module:** `placement.rs`  
**Gap:** No quaternion parsing at all.

**What's known:** Unit quaternions at Transform record offsets +0x14..+0x20. Verified: `qx² + qy² + qz² + qw² ≈ 1.0` across all 62k records. Denormalized quaternions produce incorrect rotations without crashing — entities appear rotated wrong.

**Specific checks needed:**
- Parse 4 f32 values at record offsets +0x14, +0x18, +0x1C, +0x20
- Compute magnitude: `sqrt(qx² + qy² + qz² + qw²)`
- Flag if `|mag - 1.0| > 0.01` (tolerance for float precision)
- Also flag if any component is NaN/Inf

#### B.2.2 IBUF Index vs Vertex Count Consistency
**Module:** `model.rs`  
**Gap:** Checks IBUF size but not whether indices reference valid vertices.

**What's known:** IBUF contains u16 index values. If `max(indices) >= vertex_count`, the engine reads garbage vertex data producing visual glitches or crashes.

**Specific checks needed:**
- Parse STRM to determine vertex_count (from GEOM n_verts or PRMG)
- Scan IBUF u16 values and check `max_index < vertex_count`
- Flag degenerate triangles (all three indices equal)

#### B.2.3 Soundbank Record Stride Validation
**Module:** `audio/soundbank.rs`  
**Gap:** Calculates record stride dynamically but doesn't validate against known good values.

**What's known:** Known strides are 116, 118, 124 bytes. The u8x4 field offsets (`U8X4_RECORD_RELATIVE = [12, 20, 44]`) are only verified for stride-116. Wrong stride → reads cross record boundaries → corrupt audio playback.

**Specific checks needed:**
- Warn on strides not in `{116, 118, 124}`
- Validate u8x4 offsets fit within computed record stride

#### B.2.4 BNDS Bounding Box Sanity
**Module:** `model.rs`  
**Gap:** BNDS chunk is not parsed at all.

**What's known:** BNDS is 40 bytes: `bbox_center.xyz(f32×3), radius(f32), bbox_min.xyz(f32×3), bbox_max.xyz(f32×3)`. Center should be between min and max. Radius should be positive. Corrupt BNDS → wrong LOD/culling.

**Specific checks needed:**
- Parse BNDS 40-byte layout
- `bbox_min.xyz <= bbox_center.xyz <= bbox_max.xyz`
- `radius > 0 && !is_nan(radius)`
- `bbox_max - bbox_min` should be positive on all axes

#### B.2.5 Audio Clip Sample Rate Range
**Module:** `audio/wavebank.rs`  
**Gap:** `sample_rate` is read but never validated.

**What's known:** Typical sample rates: 22050, 44100, 48000 Hz. A corrupt sample_rate (0, extreme values, or byte-swap artifacts like 0x5622) would cause audio playback at wrong speed or engine buffer allocation issues.

**Specific checks needed:**
- `sample_rate ∈ {8000, 11025, 16000, 22050, 32000, 44100, 48000}` or at minimum `sample_rate ∈ (1000, 100000)`
- Flag `sample_rate == 0`

### B.3 MEDIUM — Would Catch Loading Failures

#### B.3.1 ASET Type Hash vs Type Registry
**Module:** `overlay.rs` / `types.rs`  
**Gap:** When an ASET entry's type_id has no matching type_hash in the registry, it silently returns `type_hash_for_type_id() = None` which gets `unwrap_or(0)`.

**What's known:** 35 known type_hash mappings. If a modded WAD introduces an unknown type_id, the container lookup silently fails.

**Specific checks needed:**
- Warn on ASET entries with unmapped type_id values
- Count/report assets that fail container lookup due to type mismatch

#### B.3.2 Havok Section Headers and Fixup Streams
**Module:** `animation.rs`  
**Gap:** Everything after the magic check.

**What's known from `hk_packfile.py`:** Three 48-byte section headers (`__classnames__`, `__types__`, `__data__`), four chained fixup streams (local → global → virtual → finish, terminated by `0xFFFFFFFF` dword pairs). Corrupt fixups → engine follows garbage pointers during deserialization.

**Specific checks needed:**
- Parse 3 section headers (48 bytes each, starting at offset 64)
- Validate absolute data offsets within file bounds
- Check fixup stream termination markers (`0xFFFFFFFF` pairs)
- Validate local fixup source/destination offsets within `__data__` bounds

#### B.3.3 COMP Component Type Validation
**Module:** `placement.rs`  
**Gap:** Does not parse CHDR/COMP hierarchy.

**What's known:** Each COMP has an `info` child with component type name. Known types: `Transform`, `Name`, `DestructionLink`, `HibernationControl`, `Anchor`, `LightObject`, `IntersectionToIntersection`, `RoadIntersection`, `DangerousBuilding`, `LowResTerrainObject`.

**Specific checks needed:**
- Parse CHDR chunk table
- Extract COMP `info` type names
- Validate `schm` stride against known component strides (Transform = 42)
- Cross-reference entity keys between Transform and Name COMPs

#### B.3.4 Block Entry `field_c` Consistency
**Module:** `ucfx.rs`  
**Gap:** `field_c` is parsed but never validated.

**What's known:** `field_c` is the third u32 in each block table entry. Its exact semantics aren't fully documented, but zero or consistent values are expected. Garbage values may indicate parse misalignment.

#### B.3.5 FFCS PTHS Trailer Marker
**Module:** `ffcs.rs`  
**Gap:** PTHS paths are parsed but the mandatory 258-byte null-terminated ASCII trailer is not validated.

**What's known:** After all path strings, a mandatory trailer marker (`xa37dd45ff...d4ex`) must be present. Missing trailer causes engine black-screen hang.

**Specific checks needed:**
- After reading all PTHS strings, verify remaining bytes contain the expected trailer
- Hash or length-check the trailer for correctness

### B.4 LOW — Would Catch Cosmetic Issues

#### B.4.1 Texture Dimension Power-of-2
**Module:** `texture.rs`  
**Gap:** INFO chunk is checked for existence only, not parsed.

**What's known:** INFO body contains width(u16), height(u16) at offset +0, +2. Textures should be power-of-2 dimensions (e.g., 256, 512, 1024, 2048). Non-POT textures waste VRAM and may render incorrectly.

**Specific checks needed:**
- Parse INFO body: `width = u16 at +0`, `height = u16 at +2`
- Validate `is_power_of_2(width) && is_power_of_2(height)`
- Validate reasonable range: 1 ≤ width,height ≤ 4096

#### B.4.2 UV Range Validation
**Module:** `model.rs`  
**Gap:** UV coordinates are not parsed.

**What's known:** UVs in vertex buffers should typically be in [0, 1] range (with minor overshoot for tiling). Extreme UV values (> 10.0 or negative) indicate corrupt vertex data.

#### B.4.3 DDS FourCC Validation
**Module:** `texture.rs`  
**Gap:** Only checks DDS magic and header_size.

**What's known:** DDS pixelformat FourCC at offset +84 should be one of: `DXT1`, `DXT3`, `DXT5`, `ATI2` (for this engine). Other values suggest corrupt or unsupported textures.

**Specific checks needed:**
- Read 4 bytes at DDS offset +84 (pixel format FourCC)
- Validate against known set: `{DXT1, DXT3, DXT5, ATI2, (none for uncompressed)}`

#### B.4.4 Lua Bytecode Header Fields
**Module:** `script.rs`  
**Gap:** Checks magic and version but not other header fields.

**What's known:** Lua 5.1 header after version byte: endianness (1=LE), int size (4), size_t size (4), instruction size (4), number size (8), integral flag (0). Wrong values → silent misparse of bytecode.

#### B.4.5 MTRL Material Hash Validation
**Module:** `model.rs`  
**Gap:** Extracts first u32 of MTRL as texture hash but doesn't validate plausibility beyond `> 0x1000`.

**What's known:** MTRL contains material definitions with texture asset hashes. These should resolve to actual texture assets in the ASET table. The threshold `0x1000` is arbitrary.

---

## C. Proposed Enhancements

### C.1 Crash Prevention (Phase 1)

| # | Module | Check | Constants Needed | Effort | Priority |
|---|--------|-------|-----------------|--------|----------|
| 1.1 | `placement.rs` | Parse Transform COMP records, validate XYZ float range | World bounds: X,Z ∈ (-6000,6000), Y ∈ (-500,1000); stride = 42 | **Moderate** | **P0** |
| 1.2 | `placement.rs` | NaN/Inf detection on all position and rotation floats | `f32::is_nan()`, `f32::is_infinite()` | **Trivial** (part of 1.1) | **P0** |
| 1.3 | `placement.rs` | Quaternion magnitude check: `\|qx²+qy²+qz²+qw² - 1.0\| < ε` | Tolerance ε = 0.01 | **Trivial** (part of 1.1) | **P0** |
| 1.4 | `model.rs` | BNDS chunk parse + float sanity (NaN, Inf, min < max) | BNDS layout: 40 bytes, 10 f32s | **Trivial** | **P0** |
| 1.5 | `model.rs` | STRM vertex position float NaN/Inf spot-check | Need vertex stride from PRMG or GEOM; check first N vertices | **Moderate** | **P1** |
| 1.6 | `animation.rs` | Havok packfile magic + version string check | Magic: `\x57\xe0\xe0\x57\x10\xc0\xc0\x10`; version: `Havok-5.5.0-r1` | **Trivial** | **P1** |

### C.2 Data Integrity (Phase 2)

| # | Module | Check | Constants Needed | Effort | Priority |
|---|--------|-------|-----------------|--------|----------|
| 2.1 | `model.rs` | IBUF max_index < vertex_count cross-check | Parse STRM vertex count from GEOM/PRMG | **Moderate** | **P1** |
| 2.2 | `texture.rs` | INFO body parse: width, height, mip_count, FourCC | Offsets: +0 w(u16), +2 h(u16), +6 mips(u16), +14 FourCC(4B) | **Trivial** | **P2** |
| 2.3 | `audio/wavebank.rs` | Sample rate range validation | Valid: 8000–48000 Hz | **Trivial** | **P2** |
| 2.4 | `audio/wavebank.rs` | Channel count validation | Valid: 1 (mono) or 2 (stereo) for IMA codec | **Trivial** | **P2** |
| 2.5 | `audio/soundbank.rs` | Record stride whitelist warning | Known strides: {116, 118, 124} | **Trivial** | **P2** |
| 2.6 | `placement.rs` | COMP hierarchy walk: parse `info`, `schm`, `data` children | COMP child tag offsets, `schm` stride field at +4 | **Moderate** | **P2** |

### C.3 Completeness (Phase 3)

| # | Module | Check | Constants Needed | Effort | Priority |
|---|--------|-------|-----------------|--------|----------|
| 3.1 | `animation.rs` | Havok section header validation + fixup stream bounds | 3×48B headers at +64; fixup terminators = `0xFFFFFFFF` pairs | **Substantial** | **P3** |
| 3.2 | `overlay.rs` | Type_id → type_hash consistency warning | TYPE_HASH_REGISTRY (already in types.rs) | **Trivial** | **P3** |
| 3.3 | `ffcs.rs` | PTHS trailer marker validation | 258-byte known trailer bytes | **Moderate** | **P3** |
| 3.4 | `model.rs` | HIER transform matrix NaN check | 4×4 f32 matrix per node | **Moderate** | **P3** |
| 3.5 | `texture.rs` | DDS pixel data size vs dimensions consistency | `compute_dds_size(w, h, mips, fourcc)` | **Moderate** | **P3** |
| 3.6 | `script.rs` | Lua header field validation (endianness, sizes) | Expected: LE=1, int=4, size_t=4, instr=4, num=8, integral=0 | **Trivial** | **P3** |
| 3.7 | `placement.rs` | Entity key cross-reference: Transform ↔ Name COMP | Need to parse both COMPs and match u32 keys | **Substantial** | **P3** |
| 3.8 | `placement.rs` | vz_state flgs record parsing (42-byte stride, different layout) | Record offsets from `placement_data_format.md` §3.3 | **Substantial** | **P3** |

---

## D. Implementation Plan

### Phase 1: Crash Prevention (Estimated: 1–2 sessions)

**Goal:** Catch the class of bugs that caused the spatial hash crash. Every check here directly prevents an engine crash or access violation.

**1.1 — Placement record deep validation** (`placement.rs`)

Rewrite `consume_layer` to:
1. Extract `CHDR` chunk table (reuse `extract_chunk_body` pattern)
2. Find COMP descriptors with `info` child containing `"Transform"`
3. Parse `schm` to get `payload_stride` (expect 38, total record = 42)
4. Parse `data` body as sequence of 42-byte records:
   - Read `entity_key` (u32 at +0)
   - Read `position_x/y/z` (f32 at +4, +8, +12)
   - Read `quat_x/y/z/w` (f32 at +20, +24, +28, +32)
5. For each record:
   - **NaN/Inf check** on all 7 floats
   - **Range check** on position: X,Z ∈ (-6000, 6000), Y ∈ (-500, 1000)
   - **Quaternion normalization**: `|mag² - 1.0| < 0.01`
6. Return issues as `ConsumeResult` issues, count as `placements_validated`

This is the highest-value change since it directly catches the spatial hash crash pattern.

**Constants to embed in `placement.rs`:**
```rust
const WORLD_XZ_MIN: f32 = -6000.0;
const WORLD_XZ_MAX: f32 = 6000.0;
const WORLD_Y_MIN: f32 = -500.0;
const WORLD_Y_MAX: f32 = 1000.0;
const QUAT_NORM_TOLERANCE: f32 = 0.01;
const TRANSFORM_RECORD_STRIDE: usize = 42;
```

**1.2 — BNDS and vertex float sanity** (`model.rs`)

Add to `consume_model`:
1. Parse BNDS chunk (40 bytes = 10 f32s: center.xyz, radius, min.xyz, max.xyz)
2. NaN/Inf check on all 10 floats
3. Validate `min < center < max` on all axes, `radius > 0`
4. If STRM is present and GEOM gives vertex info, spot-check first 16 vertices for NaN/Inf in position floats

**1.3 — Havok magic check** (`animation.rs`)

Add to `consume_animation`:
1. Check `body[0..8] == HAVOK_MAGIC`
2. Search for `Havok-5.5.0-r1` in first 256 bytes
3. Report issues if either fails

### Phase 2: Data Integrity (Estimated: 1–2 sessions)

**Goal:** Catch silent data corruption that produces wrong visual/audio output.

**2.1 — Index buffer cross-validation** (`model.rs`)
- Parse GEOM to get `n_verts` (already reads `n_groups` at offset 0)
- Scan IBUF u16 values, track `max_index`
- Flag if `max_index >= n_verts` (off-by-one aware)

**2.2 — Texture INFO parse** (`texture.rs`)
- Parse INFO body: width/height (u16), mip_count (u16), FourCC
- Flag non-POT dimensions, unreasonable sizes (>4096)
- Validate FourCC against `{DXT1, DXT3, DXT5}`

**2.3 — Audio parameter validation** (`audio/wavebank.rs`)
- Validate `sample_rate ∈ (1000, 100000)` 
- Validate `channels ∈ {1, 2}` for IMA codec
- Flag zero or implausible values

**2.4 — Soundbank stride warning** (`audio/soundbank.rs`)
- After computing `record_size`, warn if not in `{116, 118, 124}`

**2.5 — COMP hierarchy walk** (`placement.rs`)
- Parse CHDR chunk table
- Walk COMP children, extract component type names
- Validate `schm` stride against expected values
- Report component type census (useful for debugging)

### Phase 3: Completeness (Estimated: 2–3 sessions)

**Goal:** Schema-aware parsing for maximum confidence.

**3.1 — Havok deep validation** (`animation.rs`)
- Parse 3 section headers (name, absolute offset, size)
- Validate `__data__` local fixup stream: each fixup pair within bounds
- Check termination: `0xFFFFFFFF` pair at stream end
- Validate classname hash table entries

**3.2 — PTHS trailer** (`ffcs.rs`)
- After parsing paths, verify remaining bytes match known trailer pattern
- Could store first 8 bytes of expected trailer as a constant check

**3.3 — Full placement deep validation** (`placement.rs`)
- Parse layers_static sub-block TOC (16-byte entries)
- Walk all 173 sub-blocks and their COMP hierarchies
- Cross-reference Transform and Name entity keys
- Parse LightObject COMP for point light parameter validation
- Parse vz_state flgs records (42-byte stride, different field layout)

**3.4 — Type consistency** (`overlay.rs`)
- After building resolved map, warn on any type_id not in TYPE_HASH_REGISTRY
- Count unreachable type_id values

---

## E. Severity Matrix

```
                    Current     Phase 1     Phase 2     Phase 3
                   ─────────  ──────────  ──────────  ──────────
Crash prevention      ★☆☆☆☆     ★★★★☆       ★★★★☆       ★★★★★
Data integrity        ★★☆☆☆     ★★★☆☆       ★★★★☆       ★★★★★
Audio validation      ★★★★☆     ★★★★☆       ★★★★★       ★★★★★
Structural checks     ★★★★☆     ★★★★☆       ★★★★☆       ★★★★★
Format coverage       ★★☆☆☆     ★★★☆☆       ★★★★☆       ★★★★★
```

The single highest-impact change is **C.1.1**: Transform COMP record parsing with position float validation in `placement.rs`. This directly addresses the spatial hash crash pattern and transforms the thinnest module (2 lines of logic) into a content-aware validator using format knowledge that is fully documented in `docs/placement_data_format.md`.

---

## F. Module Priority Ranking (by validation depth gap)

1. **`placement.rs`** — Gap: CRITICAL. 2 lines of existence checks vs 42-byte records with 7 validated floats per record across 62k+ entities. Highest crash-prevention value.
2. **`animation.rs`** — Gap: CRITICAL. 1 line (`!empty()`) vs full Havok 5.5 packfile format. Engine follows pointer fixups blindly.
3. **`model.rs`** — Gap: HIGH. Checks chunk sizes but not vertex data content. Missing BNDS, HIER, INDX, PRMG parsing.
4. **`texture.rs`** — Gap: MEDIUM. Checks DDS header but not INFO body (dimensions, format, mip chain).
5. **`script.rs`** — Gap: LOW. Already checks magic, version, and format type.
6. **`audio/*`** — Gap: LOW. Deep validation with full IMA decode. Minor parameter range checks missing.
