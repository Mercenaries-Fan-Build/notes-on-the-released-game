# Structural Audit: `tools/ucfx_be_to_le.py`

**Date:** 2026-05-28
**Scope:** Comprehensive review of heuristic vs. structural parsing in the
UCFX big-endian → little-endian converter used by the Xbox 360 DLC port.
**Trigger:** Game crash (spatial hash overflow) caused by un-swapped Transform
position floats, traced to a `body_size % 42 == 0` heuristic at line 1707.

---

## Executive Summary

The converter is **well-structured at the WAD block and UCFX container level**
— it properly parses the entry table, walks the descriptor table, and dispatches
by `(tag, type_hash)`. However, it breaks down in three critical areas:

1. **ECS_NODE `data` bodies use size heuristics** instead of walking the
   COMP `info`/`schm`/`data` triplet to identify which component a `data`
   body belongs to (the crash bug).
2. **`flgs` bodies for vz_state use magic-byte scanning** (`find(BE 1.0f)`)
   instead of structural offsets from the parent COMP header.
3. **Several type_hashes seen in DLC blocks have no converter** and fall
   through to `_fallback_u32_or_raise` (strict mode blocks them; permissive
   mode blindly u32-swaps them, which corrupts mixed-type bodies).

The Havok, Lua, texture, audio, and mesh paths are all structurally sound.
The ECS/placement path is the primary safety concern.

---

## A. Structural Parsing Assessment

### A.1 Block entry table — CORRECT

```
Line 2105-2115: _parse_entry_table_be()
Line 2118-2123: _serialize_entry_table_le()
Line 2126-2244: byteswap_ucfx_block()
```

The block-level code correctly:
- Reads the BE `count` at offset 0
- Iterates `count` entries of 16 bytes: `(hash, type_hash, offset, size)`
- Passes `type_hash` down to the container converter
- Serializes a fresh LE entry table
- Handles CSUM trailer detection and recomputation
- Supports override injection and entry stripping

**Verdict: Solid. No heuristics.**

### A.2 UCFX container descriptor table — CORRECT

```
Line 1908-2100: _convert_container()
```

The container parser correctly:
- Validates UCFX magic (`XFCU` in BE)
- Reads `data_area_off`, `n_descriptors` from the BE header
- Iterates 20-byte descriptor rows: `(tag, row_u0, body_size, f3, f4)`
- Computes body position from `data_area_off + row_u0`
- Reverses 4-byte tags from BE storage order
- Classifies contexts via `_classify_contexts()`
- Serializes fresh LE output with corrected descriptors

**Verdict: Solid. The descriptor table walk is structural.**

### A.3 Context classification — PARTIAL (coarse)

```
Line 900-916: _classify_contexts()
```

This tracks whether descriptors are "inside" a STRM, IBUF, or META container
by watching for `CONTAINER_SENTINEL` rows. It correctly identifies:
- STRM/GEOM containers → `"STRM"` context
- IBUF containers → `"IBUF"` context
- CHDR/COMP/STAT/PRMT/EXEC → `"META"` context

**Gap:** The META context is **flat** — it does not track *which* COMP is
active. All `info`, `schm`, and `data` children under any COMP get the same
`"META"` context. This means the `data` tag dispatch at line 1701 cannot
distinguish a Transform `data` body from a Name `data` body from a LightObject
`data` body. This is the root cause of the heuristic at line 1707.

### A.4 COMP hierarchy (info/schm/data triplets) — NOT PARSED

**This is the central finding.** The UCFX descriptor table for an ECS_NODE
container looks like:

```
CHDR  (sentinel)
  enum  (children)
  COMP  (sentinel, 3 children)
    info  → component name (e.g. "Transform")
    schm  → record stride + field types
    data  → the actual records
  COMP  (sentinel, 3 children)
    info  → component name (e.g. "Name")
    schm  → record stride + field types
    data  → the actual records
  ...
  flgt
  flgs
```

The converter sees each `info`, `schm`, and `data` row as independent
descriptors with `context="META"`. It does NOT:
- Associate a `data` body with its preceding `info` (which tells you the
  component name: "Transform", "Name", "LightObject", etc.)
- Read the `schm` to learn the record stride and field types
- Use the component name to dispatch to the correct per-component converter

Instead, it falls through to the `data` tag handler at line 1701, which uses
`type_hash` (always `_TYPE_ECS_NODE` = `0xE6B81A54` for all of them) and then
applies a **size heuristic**.

---

## B. Heuristic Inventory

### B.1 `data` for ECS_NODE: `body_size % 42 == 0` (LINE 1707)

**The crash bug.**

```python
if type_hash == _TYPE_ECS_NODE:
    if len(body_be) % 42 == 0:
        return _convert_transform_records(body_be)
    # vz_state COMP data: entity name strings + enum tables (text-heavy,
    # endian-neutral).  No verified binary field map exists for this
    # mixed-content body; pass through to preserve string integrity.
    return body_be
```

**What it does:** If the `data` body size is divisible by 42, assume it's
Transform records and byte-swap as `[u32 key][8×f32][u32 tail][u16 tail]`.
Otherwise, pass through as raw bytes (no swap).

**What SHOULD be used:** Walk the COMP descriptor triplet. The `info` child
preceding this `data` contains the component name as a null-terminated ASCII
string. If `info` says "Transform", this is Transform data with 42-byte
stride. If `info` says "Name", it's entity name strings (endian-neutral). If
`info` says "LightObject", it's 56-byte records with floats.

**Risk: CRITICAL.** Any non-Transform COMP whose `data` body size happens to
be divisible by 42 will be **incorrectly byte-swapped as Transform records**,
corrupting it. Any Transform COMP whose `data` body size is NOT divisible by
42 (e.g., trailing padding bytes) will be **passed through as raw BE**,
leaving position floats un-swapped → spatial hash overflow → crash.

**Concrete failure modes:**
- LightObject (stride 56): a body with 3 entities = 168 bytes. 168 % 42 == 0.
  The code would incorrectly apply Transform record swapping.
- HibernationControl (stride 10): a body with 21 entities = 210 bytes.
  210 % 42 == 0. Same corruption.
- Name (variable-length strings): body size 126 bytes → 126 % 42 == 0 →
  corrupted by numeric swapping on ASCII strings.

### B.2 `flgs` for vz_state: `find(_BE_ONE_F)` magic-byte scan (LINE 170)

```python
marker_pos = be.find(_BE_ONE_F)
if marker_pos >= 4:
    rec_start = marker_pos - 4
elif marker_pos >= 0:
    rec_start = 0
else:
    if len(be) % 4 == 0:
        return _convert_u32_array(be)
    raise UnhandledByteSwapError(...)
```

**What it does:** Scans for the 4-byte big-endian representation of float
`1.0` (`0x3F800000`). Assumes the first occurrence is the `boot_float` field
at record+4, so records start 4 bytes earlier.

**What SHOULD be used:** The `flgs` descriptor in the UCFX container has a
known offset and size. The record start position should be determined from the
CHDR descriptor chain, not from a magic byte scan.

**Risk: MEDIUM.** If any header data before the records happens to contain the
bytes `3F 80 00 00` (quite possible — this is also the u32 value `1065353216`),
the record boundary will be mis-detected, causing the entire body to be
incorrectly partitioned and byte-swapped.

### B.3 `flgs` fallback: `len(be) % 4 == 0` (LINE 177)

When no `1.0f` marker is found, the code falls back to treating the entire
body as a u32 array if the size is 4-byte aligned.

**Risk: MEDIUM.** This could incorrectly swap u8/u16 fields that happen to sit
in a 4-byte-aligned body.

### B.4 `flgs` for non-ECS_NODE: `len(body_be) % 4 == 0` (LINE 1681)

```python
if tag == "flgs":
    if type_hash == _TYPE_ECS_NODE:
        return _convert_vz_state_flgs(body_be)
    if len(body_be) % 4 == 0:
        return _convert_u32_array(body_be)
```

**Risk: LOW-MEDIUM.** For non-ECS_NODE types, `flgs` bodies are assumed to be
pure u32 arrays based solely on alignment. This is likely correct for most
known types but is not verified structurally.

### B.5 Soundbank record stride: size division (LINE 1594-1599)

```python
sec_a = section_off1 - data_start
if sub_count > 0 and sec_a > 0 and sec_a % sub_count == 0:
    record_stride_a = sec_a // sub_count
```

**Risk: LOW.** This derives the record stride from section boundaries and
entry counts from the header. It's semi-structural (uses parsed header fields)
but could produce wrong strides if the section layout assumption is violated.
In practice, validated against 76 base-game soundbanks.

### B.6 CFX zlib offset: byte-scan heuristic (LINE 1232-1241)

```python
def _find_zlib_offset(data: bytes, *, search_limit: int = 512) -> int:
    limit = min(len(data) - 2, search_limit)
    for i in range(limit):
        if data[i] == 0x78 and data[i + 1] in _ZLIB_CMFS:
            return i
```

**Risk: LOW.** Scans for `0x78` (zlib CMF byte) to find the start of a zlib
stream. Could false-positive on binary data that starts with `0x78 0x9C` etc.
However, the fields before the zlib stream are confirmed to be u32-aligned,
so the only risk is truncating the prefix too early. In practice, working
across all known CFX payloads.

### B.7 BINN LuaQ search: sequential scan (LINE 705-706)

```python
for search in range(min(body_end - 4, 256)):
    if bytes(data[search:search + 4]) == _LUAQ_SIG:
```

**Risk: VERY LOW.** Scans first 256 bytes for `\x1bLua` signature. The BINN
header metadata before LuaQ is well-understood and the scan is bounded. False
positives are astronomically unlikely.

### B.8 Havok version string: `find()` scan (LINE 528-530)

```python
ver_off = be.find(_HAVOK_VER)
if ver_off < 0:
    ver_off = be.find(b"Havok-")
```

**Risk: VERY LOW.** The Havok packfile has a fixed structure; the version
string always appears at a known position after the 16-byte header fields.
The scan is a robustness measure, not a structural gap.

---

## C. Unhandled Data Types

### C.1 ECS_NODE `data` bodies that are NOT Transform

When `type_hash == _TYPE_ECS_NODE` and `len(body_be) % 42 != 0`, the body is
returned **completely un-swapped** (line 1712: `return body_be`).

This means ALL of these component types have their `data` bodies passed
through as raw big-endian bytes:

| Component | Stride | Has u32/f32 fields? | Impact |
|-----------|--------|---------------------|--------|
| Name | variable | Yes (entity key) | Entity key un-swapped → broken entity cross-references |
| ModelName | 8 | Yes (key + model hash) | Model hash un-swapped → wrong mesh loaded |
| LightObject | 56 | Yes (key + RGB floats + radius) | Light positions/colors wrong |
| HibernationControl | 10 | Yes (key + u16 fields) | LOD control broken |
| ObjectScript | 12 | Yes (key + script hash) | Script bindings broken |
| DestructionLink | 20 | Yes (key + ref key + flags) | Destruction chains broken |
| Road | 44 | Yes (key + lane data) | Road network broken |
| RoadIntersection | 128 | Yes (key + geometry) | Intersections broken |
| ModifierKey | 12 | Yes (key + modifier ref) | Modifiers broken |
| ScrubObject | 8 | Yes (key + hash) | Scrub lookup broken |
| LineRegion | 8 | Yes (key + region ref) | Region bounds broken |
| MaterialMapping | 12 | Yes (key + refs) | Material assignment broken |
| PhysicalLink | 48 | Yes (key + physics data) | Physics broken |
| LandingZone | 276 | Yes (key + zone def) | Landing zones broken |
| Label | 8 | Yes (key + hash) | Labels broken |
| Anchor | 20 | Yes (key + anchor data) | Anchors broken |
| LowResTerrainObject | 12 | Yes (key + mesh hash + scene obj) | Terrain routing broken |

**Impact: HIGH.** Every non-Transform ECS component in DLC placement blocks
retains big-endian field ordering. The game may crash, load wrong assets, or
silently produce incorrect behavior depending on which components are accessed
at runtime.

### C.2 vz_state COMP `data` bodies

The comment at line 1709-1711 explicitly acknowledges this gap:

```python
# vz_state COMP data: entity name strings + enum tables (text-heavy,
# endian-neutral).  No verified binary field map exists for this
# mixed-content body; pass through to preserve string integrity.
```

Per `docs/ecs_components.md` §vz_state, these contain component *definitions*
(enum tables, field metadata) rather than per-entity records. The body is
indeed text-heavy, but any embedded u32 hashes or type codes will remain BE.

**Risk: MEDIUM.** vz_state COMP data is primarily used for enum resolution
and component schema, not direct position data. String content is
endian-neutral, but hash fields within may be wrong.

### C.3 Type hashes with no explicit converter

Cross-referencing the 35 known type_hashes from `aset_type_ids.py` against
the explicit handlers in `_convert_body()`:

| type_hash | Name | Handler | Status |
|-----------|------|---------|--------|
| `0xF011157A` | texture | Explicit (INFO + BODY) | ✅ Complete |
| `0x42498680` | script | Explicit (BINN/INFO) | ✅ Complete |
| `0x18166555` | animation | Explicit (Havok) | ✅ Complete |
| `0xE6B81A54` | ecs_node | **PARTIAL** (Transform only) | ⚠️ See B.1/C.1 |
| `0x5B724250` | model (mesh_B) | `_U32_DATA_TYPES` | ✅ Complete |
| `0x7C569307` | terrainmesh | `_U32_DATA_TYPES` | ✅ Complete |
| `0x600B904E` | mesh_C | `_U32_DATA_TYPES` | ✅ Complete |
| `0xBCFE6314` | path | Explicit (u16 + u32) | ✅ Complete |
| `0x1602815C` | lowresterrain | `_U32_DATA_TYPES` | ✅ Complete |
| `0x5608BD5A` | effect | `_U32_DATA_TYPES` | ✅ Complete |
| `0xF753F6D0` | wavebank | Explicit (audio transcode) | ✅ Complete |
| `0xE5273C14` | audio group | Explicit (E5 converter) | ✅ Complete |
| `0x9F8BCA10` | soundbank | Explicit (section-aware) | ✅ Complete |
| `0x39E5E978` | stringdb | Passthrough (natively BE) | ✅ Correct |
| `0xFE0E8320` | cfx_pack | Explicit (zlib scan) | ✅ Complete |
| `0x6310807F` | object_registry | Explicit (u32 array) | ✅ Complete |
| `0xFA0B8DBC` | resident_misc | `_U32_DATA_TYPES` | ✅ Complete |
| `0x207359C7` | stance | `_RESIDENT_ONLY_TYPES` | ✅ (raises in DLC) |
| `0xECE70371` | state_machine | `_RESIDENT_ONLY_TYPES` | ✅ (raises in DLC) |
| `0xEA4829D5` | level | `_RESIDENT_ONLY_TYPES` | ✅ (raises in DLC) |
| `0x5647C35D` | layer | `_RESIDENT_ONLY_TYPES` | ✅ (raises in DLC) |
| `0x59B9DF6A` | materialtable | `_RESIDENT_ONLY_TYPES` | ✅ (raises in DLC) |
| `0xDE982D61` | unknown_DE | `_RESIDENT_ONLY_TYPES` | ✅ (raises in DLC) |
| `0x665EF13E` | (type_id 5) | **NO HANDLER** | ❌ Falls to `_fallback_u32_or_raise` |
| `0x1CF649BB` | (type_id 34) | **NO HANDLER** | ❌ Falls to `_fallback_u32_or_raise` |
| `0x8F0A54E2` | binary | **NO HANDLER** | ❌ Falls to `_fallback_u32_or_raise` |
| `0x99E77ACE` | font | **NO HANDLER** | ❌ Falls to `_fallback_u32_or_raise` |
| `0x4D7D30C4` | (type_id 0) | **NO HANDLER** | ❌ Falls to `_fallback_u32_or_raise` |
| `0x34612F86` | (type_id 0) | **NO HANDLER** | ❌ Falls to `_fallback_u32_or_raise` |
| `0xACCE47F2` | (type_id 33) | **NO HANDLER** | ❌ Falls to `_fallback_u32_or_raise` |
| `0xC122545A` | (type_id 26) | **NO HANDLER** | ❌ Falls to `_fallback_u32_or_raise` |
| `0xE8DF4D87` | (type_id 4) | **NO HANDLER** | ❌ Falls to `_fallback_u32_or_raise` |
| `0x3B0AABF8` | (type_id 1) | **NO HANDLER** | ❌ Falls to `_fallback_u32_or_raise` |
| `0x140E8728` | (type_id 10) | **NO HANDLER** | ❌ Falls to `_fallback_u32_or_raise` |
| `0xFA46D8A8` | (type_id 25) | **NO HANDLER** | ❌ Falls to `_fallback_u32_or_raise` |

**11 of 35 type_hashes have no explicit handler.** In strict mode (default),
encountering any of these in a `data`, `info`, `INFO`, or `BODY` chunk raises
`UnhandledByteSwapError`, which causes the entire block to be skipped. In
permissive mode, they get blind u32 array conversion.

**Practical impact:** Many of these 11 types may not appear in DLC blocks
(they could be base-game-only types). The `dlc_port.py` override system
substitutes base-game LE data for matched `(hash, type_id)` entries, so
blocks with these types may already be handled via override rather than
byte-swap. But any DLC-only entry of these types would fail in strict mode.

---

## D. The Proper Fix Architecture

### D.1 COMP-aware context tracking

Replace the flat `_classify_contexts()` with a stateful walk that tracks:

```python
@dataclass
class CompContext:
    """Active COMP triplet state."""
    component_name: str | None = None    # from info body
    schema_stride: int | None = None     # from schm body
    schema_fields: list[tuple] | None = None  # from schm body
    phase: int = 0  # 0=waiting, 1=saw info, 2=saw schm, 3=saw data
```

When the walker encounters:
- A `COMP` sentinel row → push a new `CompContext`
- An `info` row under META → parse the body to extract the component name,
  store in context
- A `schm` row under META → parse to extract `(n_fields, payload_stride)`,
  store in context
- A `data` row under META → dispatch using `context.component_name`:
  - `"Transform"` → `_convert_transform_records(be)` (stride 42)
  - `"Name"` → passthrough (ASCII, endian-neutral)
  - `"LightObject"` → swap key + 13×f32 (stride 56)
  - `"ModelName"` → swap 2×u32 (stride 8)
  - etc. for each known COMP type from `docs/ecs_components.md`
  - Unknown component names → use `schm` payload_stride to determine
    record stride, then apply generic u32-aligned swapping

### D.2 Schema-driven generic fallback

For unknown COMP types, the `schm` body provides:
```
[u32 n_fields][u32 payload_stride][16×N field entries]
```

Each field entry is `(u32 type_code, u32 name_hash, u32 unknown, u32 offset)`.
The type codes (2=i16, 3=f32, 4=hash/string, 8=animation, etc.) from the TYPE
chunk can drive per-field swap widths:
- type 2 (i16) → u16 swap
- type 3 (f32) → u32 swap
- type 4 (hash) → u32 swap
- All others → u32 swap (safe default for most numeric types)

This makes the COMP `data` conversion fully structural with no heuristics.

### D.3 Explicit `flgs` boundary detection

Instead of scanning for `_BE_ONE_F`, compute the `flgs` body boundaries from
the UCFX descriptor table. The descriptor row gives `(offset, size)` for the
`flgs` body. The distinction between "header region" (entity names) and
"record region" (42-byte placement records) should come from:
1. The preceding CHDR descriptor's child count metadata
2. Known `flgs` record format documentation (`docs/placement_data_format.md`)
3. The `schm` from the Transform COMP in the same container

### D.4 Fail-loud on unknown schemas

The current `_fallback_u32_or_raise` is correct in principle (strict mode
raises, permissive logs and blindly swaps). The improvement is to eliminate
the need for the fallback by:
1. Adding handlers for the 11 missing type_hashes (verify which appear in DLC)
2. Making the COMP `data` path use schema-driven conversion
3. Ensuring every code path that currently returns `body_be` unchanged
   documents WHY no swap is needed (e.g., "ASCII strings are endian-neutral")

---

## E. Data Left on the Cutting Room Floor

### E.1 ECS component data in DLC placement blocks

The DLC contains placement blocks (`layers_static` style or `vz_state` style)
whose COMP `data` bodies for non-Transform components are **not byte-swapped**.
This affects:

- Entity name lookups (Name COMP: entity key is BE)
- Model resolution (ModelName COMP: model hash is BE)
- Light spawning (LightObject COMP: RGB/intensity/radius all BE)
- Road network (Road + RoadIntersection: all floats BE)
- Destruction chains (DestructionLink: reference keys are BE)
- Physics (PhysicalLink: all fields BE)
- All other component types listed in C.1

The game may silently ignore these because the engine may only use Transform
+ Name for initial entity spawning (position/rotation), with other components
loaded separately. But if any DLC entity touches Road, Light, or
DestructionLink at runtime, the BE data will produce incorrect behavior.

### E.2 STRM vertex format granularity

The DLC port status document (`docs/dlc_pc_port_status.md`) lists "UCFX deep
swap (STRM vertex data)" as a **Gap** needing "per-format f16/f32/u8 swap".
The current converter applies `_convert_u32_array(body_be)` to all STRM data
(line 1838), which is correct for f32 positions/normals/UVs but will
**corrupt f16 or u8 vertex attributes**.

From `docs/format_reference.md` §13, terrain tile vertices use a 16-byte
stride with `f16×3 + f16 + f16×3 + f16`. The u32 swap on f16 data would
swap pairs of f16 values, producing wrong coordinates.

**Mitigation:** `dlc_port.py` overrides texture and mesh entries from the base
game when `--source-wad` is provided, so STRM data in overridden entries is
already LE. Non-overridden mesh entries (DLC-unique meshes) would have
corrupted f16 vertices.

### E.3 Texture BODY tile swizzle

The DLC port status document lists "UCFX deep swap (texture BODY)" as a
**Gap** noting "possible Xbox 360 tile swizzle". The converter does apply
DXT block-level byte-swapping (`_convert_dxt_body`, lines 989-1078), but
Xbox 360 GPUs also apply Morton/Z-order **tile swizzling** that changes the
block ordering within a texture surface. The current code does NOT de-swizzle.

**Mitigation:** Textures are overridden from base game via `dlc_port.py`, so
the swizzle gap only affects DLC-exclusive textures (if any exist).

### E.4 `flgs` header region passthrough

In `_convert_vz_state_flgs` (line 184), the header region (entity name
strings interspersed with u32 hashes) is passed through as raw bytes:

```python
# Header: pass through as-is (entity name strings, endian-neutral)
header = be[:rec_start]
```

The comment says "entity name strings, endian-neutral" but the header also
contains u32 hash values that ARE endian-sensitive. These hashes remain in
big-endian order. The game may use them for entity lookup, which would fail
or produce wrong results.

### E.5 `flgs` tail bytes

In `_convert_vz_state_flgs` (line 209-213), tail bytes after the last full
record are either u32-swapped (if 4-byte aligned) or passed through:

```python
if tail:
    if len(tail) % 4 == 0:
        out += _convert_u32_array(tail)
    else:
        out += tail  # preserve as-is (endian-neutral residual)
```

The tail content is uncharacterized. If it contains u16 or mixed fields,
the u32 swap would corrupt it.

---

## F. Priority Fix Order

| Priority | Issue | Risk | Fix Effort |
|----------|-------|------|------------|
| **P0** | B.1: `% 42` heuristic for Transform vs other COMP data | CRITICAL (crash) | Medium — requires COMP triplet tracking |
| **P1** | C.1: Non-Transform COMP data un-swapped | HIGH | Covered by P0 fix |
| **P1** | E.2: STRM f16/u8 vertex formats | HIGH (corrupt meshes) | Medium — needs `decl` chunk parsing per STRM |
| **P2** | B.2: `find(_BE_ONE_F)` in vz_state flgs | MEDIUM | Low — use descriptor offsets |
| **P2** | E.4: flgs header hash passthrough | MEDIUM | Low — parse and swap u32s between strings |
| **P3** | C.3: 11 unhandled type_hashes | LOW-MEDIUM | Low per type — verify which appear in DLC |
| **P3** | E.3: Texture tile swizzle | LOW (mitigated by override) | High — GPU-specific |
| **P4** | B.6: CFX zlib offset scan | LOW | Low — validate against known CFX layouts |

---

## G. Affected Lines Summary

| Line(s) | Issue | Category |
|---------|-------|----------|
| 134 | `len(be) % STRIDE != 0` — assumes all ECS data is Transform | Heuristic |
| 170-182 | `be.find(_BE_ONE_F)` — scans for magic float to find record start | Heuristic |
| 177 | `len(be) % 4 == 0` — fallback assumes pure u32 body | Heuristic |
| 184 | Header passthrough — u32 hashes remain BE | Passthrough gap |
| 209-213 | Tail handling — uncharacterized data | Passthrough gap |
| 900-916 | `_classify_contexts()` — flat META, no COMP tracking | Missing structure |
| 1232-1241 | `_find_zlib_offset()` — byte scan for zlib | Heuristic (low risk) |
| 1594-1599 | Soundbank record stride from size division | Semi-heuristic |
| 1681-1682 | Non-ECS flgs: `% 4 == 0` → u32 array | Heuristic (low risk) |
| 1707-1712 | `% 42 == 0` → Transform; else passthrough | **Root cause heuristic** |
| 1838 | STRM data: blanket u32 swap | Missing per-format handling |

---

## H. What's Working Well

Despite the gaps, the following are structurally sound and well-implemented:

1. **Block entry table** (lines 2105-2244): Proper structural walk
2. **UCFX descriptor table** (lines 1908-2100): Clean parse and serialize
3. **Havok converter** (lines 266-643): Class-aware per-field swap using
   HavokLib layouts, virtual fixups, no-swap regions for u8 buffers
4. **Lua bytecode** (lines 646-890): Full recursive proto conversion
5. **Texture INFO** (lines 239-263): Typed per-field swap
6. **DXT texture blocks** (lines 989-1078): Per-block endian swap
7. **Audio converters** (lines 1218-1642): Fully structural with
   cross-platform validation
8. **DEPS, TYPE, enum, schm, evnt, trnm** tag handlers: All field-aware
9. **Strict mode** (`_fallback_u32_or_raise`): Correct refusal policy

The converter is ~85% structural. The 15% that uses heuristics is concentrated
in the ECS/placement path, which is exactly where positional data lives and
where errors cause crashes.
