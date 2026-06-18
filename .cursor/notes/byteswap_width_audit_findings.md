# BE→LE Width-Swap Audit — Findings & Fix Plan

Diagnostic/planning task. **No converter/test source edited** (owned by another
worker). Evidence gathered by enumerating every width-assuming swap site in both
converters, then auditing the *actual* schm field layout of every ECS component
in the deployed patch WAD and the full retail LE oracle.

Converters reviewed (read-only):
- `tools/ucfx_be_to_le.py` (Python)
- `tools/wad_simulator/crates/ucfx_byteswap/src/convert.rs` (Rust, `make dlc-port` path)
- type→width map: `tools/wad_simulator/crates/mercs2_formats/src/schema.rs`

## TL;DR (headline results)

1. **No NEW active narrow-field corruption ships in the current DLC patch.** Every
   schm-backed COMP in the deployed `vz-patch.wad` (15 ECS blocks) is either
   all-u32/f32-aligned (correctly swept) or already special-cased
   (Transform/Hibernation/Name/ModelName). Audited exhaustively.
2. **CHDR is the only crash-risk width bug; no other found.** All other
   stride/offset/count fields are genuine u32 (container header, descriptor rows,
   schm header) or already field-aware (texture INFO u16, trnm u16). Every
   remaining schm narrow-field issue is bit/flag/id data → **correctness-only**.
3. **Three base-game components carry interior bit fields the blanket sweep would
   corrupt**: `AiPatrol`, `EquipmentLink`, `PopulationSimpleSpawner`. They are
   **not in the current DLC** (latent), but expose a **Python↔Rust divergence**:
   Rust converts them correctly via its (live) schema-driven path; Python has **no
   schema-driven path** and *refuses* them (strict) or *blind-u32-corrupts* them
   (permissive).
4. **Architectural root cause of the recurring bug class:** the blanket numeric
   sweep is gated by a hand-maintained "numeric component" **allow-list**. The
   parsed schema is bypassed for listed components. HibernationControl was
   corrupted precisely because it sat in that list with sub-u32 fields. The
   principled fix is to **drive the swap from the schema whenever a schema is
   present** and delete the allow-list short-circuit.
5. **blob32 / i16-quat: non-issue on disk.** On-disk Transform/placement quat is
   **4×f32** (`qx²+qy²+qz²+qw²≈1` across all 62k records; 734/734 DLC records
   decode clean). blob32 = 8×f32 → 8×u32 swap is correct. The "4×i16 quat" is at
   most an in-memory/compressed runtime form (schm stride 56 ≠ on-disk 42) that
   never reaches disk.

---

## A. Inventory of width-assuming swap sites

### Python — `tools/ucfx_be_to_le.py`

| Site (fn) | What it swaps | Width assumption | Class |
|---|---|---|---|
| `_convert_u32_array` | whole body as u32[] (+u16/byte tail) | all-u32 | primitive (used widely) |
| `_convert_u16_array` | whole body as u16[] | all-u16 | primitive |
| `_convert_numeric_records(stride)` | per record: `stride//4` u32 + (u16 if `stride%4==2`) tail | record = u32s + optional u16/byte **tail** only | **the blanket numeric sweep** |
| `_convert_ecs_comp_data` | dispatch by component name | special-cases Transform/Name/ModelName/Hibernation/keyed-group; **everything else in `_ECS_NUMERIC_COMPONENTS` → numeric sweep**; unknown → raise | **allow-list gate (root cause)** |
| `_swap_chdr_header` / `_convert_chdr_body` | `{u16@0;u16@2;u32@4}` + u32[] beyond +8 | per-field (FIXED) | correct |
| `_convert_schm_body` | header u32×2 + per-field `{u32;u32;u32; u16 byte_offset + 2×u8}` | per-field (FIXED) | correct |
| `_convert_hibernation_records` | u32 key + u16 + 4×u8/bits | per-field (FIXED) | correct |
| `_convert_transform_records` | 10×u32 + u16 | per-field (retail-verified) | correct |
| `_convert_texture_info` | 7×u16 + FourCC + u32 + u16s | per-field | correct |
| `_convert_trnm_body` | u16 count + u32[] | per-field | correct |
| `_convert_ecs_info`/`_convert_enum_body`/`_convert_type_body` | string-aware u32/u16 | per-field | correct |
| dispatcher `_convert_body` u32 tags | `flgt, schm(hdr), STRM, BNDS, ATRB, TRFM, PTYP/COLR/TEXT/FRCE/ANIM/AKEY, MANM/TRCK/DATA, watr/tree/UNIQ, PRMG/GEOM/POFF/STAT/SWIT/NODE/CEXE/PHY2/COMP/TINY/SCRB/INST/PTCH/PTMS/BSHP/VALU, KEYS, ATRB` → u32[] | all-u32/f32 | mesh/effect data — see §D |
| `_convert_container` header + rows | UCFX hdr `{u32 data_off,u32,u32,u32 n_desc}`, rows `{tag, 4×u32}` | all-u32 (true per format) | correct |

### Rust — `convert.rs`

| Site (fn) | What it swaps | Width assumption | Class |
|---|---|---|---|
| `swap_u32_array` / `swap_numeric_records_inplace(stride)` | same as Python primitives | u32s + u16/byte **tail** | blanket numeric sweep |
| `convert_comp_data_inplace` | special-cases Name/ModelName/Hibernation/keyed-group; **line 832: `comp != "Transform" && (schema.is_none() || is_ecs_numeric_component)` → numeric sweep**; **else → live schema-driven per-field swap (lines 866-887)** | allow-list gate, but schema path is LIVE for non-listed schema'd comps | **allow-list gate (root cause)**; schema path correct |
| `swap_chdr_header_inplace`/`convert_chdr_body_inplace` | `{u16;u16;u32}` (FIXED) | per-field | correct |
| `swap_schm_body_inplace` | per-field byte_offset u16 (FIXED) | per-field | correct |
| `convert_hibernation_data_inplace` | u32 key + u16 (FIXED) | per-field | correct |
| `ComponentSchema::from_schm_body` + `SchemaFieldType` | type→width table (1/2/4/5/6/7/8/9/10/11) | correct & centralized | correct |

> **Key structural asymmetry:** Rust *parses and uses* the schema for any schema'd
> component **not** on the numeric allow-list. Python does **not** have a
> schema-driven path at all — it relies on hardcoded per-component handlers plus
> the (currently true) assumption that every allow-listed component is pure-u32.

---

## B. ECS component schm audit (evidence)

Method: for each COMP group, parse schm `{type_code, byte_offset}` per field
(byte_offset = LOW 16 of the offset word in LE blocks, HIGH 16 in BE source),
then compare the **actual converter swap** (`_convert_numeric_records` /
`_convert_u32_array`) against a per-field reference swap. Mismatch on a *declared*
field ⇒ corruption. Padding ignored.

Scope:
- Deployed `…\Mercenaries 2 World in Flames\data\vz-patch.wad` — **2197 blocks, 15 with schm**.
- Retail oracle `game-files\vz.wad` (native LE) — **11,370 blocks, 749 with schm**, all component types.

### Components whose true layout the blanket sweep CORRUPTS (narrow fields)

| Component | stride | narrow fields (type@payload_off) | In DLC? | Status |
|---|---|---|---|---|
| **HibernationControl** | 10 | u16@0, u8@2, u8@3, u8@4, bit@5×2 | yes (n=11) | **FIXED** (special-cased both converters) |
| **Transform** | 42 on-disk | schm declares u16@36..50 (×8) but schm stride 56 ≠ on-disk 42 | yes (n=15) | **FIXED** (special-cased; retail-byte-identical) |
| **Name** | var | bit@?, strref | yes (n=15) | handled (string component) |
| **AiPatrol** | 28 | **bit@16, bit@20** | **no** | latent — see §C |
| **EquipmentLink** | 20 | **bit@12** | **no** | latent — see §C |
| **PopulationSimpleSpawner** | 116 | **bit@92..99 (×8)** | **no** | latent — see §C |

### Allow-listed "numeric" components — all SAFE (no narrow fields)

`LightObject, Road, RoadIntersection, DestructionLink, PhysicalLink, ObjectScript,
ModifierKey, ScrubObject, LineRegion, MaterialMapping, LandingZone, Label, Anchor,
LowResTerrainObject, AtmosphereBase, IntersectionToIntersection, SoundAmbience,
AiBehavior, Path, LaneData, PointLocation` — every field is type 5/6/7/8/9/10/11
(4-byte-aligned u32/f32/Vec3/blob32). The u32 sweep reproduces the correct
per-field result. `PhysicsDefaultActivator` (type-2 u8 at the very tail, stride 5)
is also safe because the tail byte is copied, not swapped.

> Intersection (numeric allow-list ∩ narrow-field components) = **{HibernationControl}**,
> and it is special-cased before the numeric branch. ⇒ **no active corruption in
> the numeric path today.**

---

## C. The three latent narrow-field components (not in current DLC)

`AiPatrol` (n=206 retail), `EquipmentLink` (n=6), `PopulationSimpleSpawner` (n=53)
contain interior **type-1 bit** fields (AI/equipment/spawner bool flags). The
blanket u32 sweep would reverse the byte(s) holding those flags within their
4-byte word → flags read back wrong.

Behaviour today (they don't appear in the DLC, so neither path runs on them now):
- **Rust** (`make dlc-port`): condition at line 832 is FALSE (schema present, not
  on numeric list) → **live schema-driven path** swaps only the u32 fields and
  leaves the type-1 bytes → **correct**.
- **Python** (strict): not in any handler list → `_fallback_u32_or_raise` **raises
  `UnhandledByteSwapError`** (safe refusal, but cannot port such a block).
- **Python** (`--permissive`, testing-only): blind `_convert_u32_array` →
  **would corrupt** the bit fields.

Severity: **correctness-only** (flag/bool data; no stride/offset/count/index/pointer).
Not crash-risk. Priority: medium (robustness + Python/Rust parity), low urgency
(absent from shipped DLC).

---

## D. Non-schm headers / crash-risk scan (task 2 & 4)

- **CHDR**: the sole confirmed crash-risk width bug (`{u16;u16;u32}` transposed by
  whole-u32 swap → zeroed the `u16@+2` stride gate `[0x01176078]` → Transform
  builder `0x0063D7C0` strides 40 not 42 → spatial-hash AV). **FIXED** in both
  converters; verified against retail oracle. See `docs/spatial_hash_crash_analysis.md`.
- **Container header + descriptor rows** (`_convert_container`): UCFX header and
  the 20-byte rows `{tag, u32 row_u0, u32 body_size, u32 f3, u32 f4}` are genuine
  u32 per the FFCS/UCFX format — correct as u32.
- **schm header** (`n_fields`, `payload_stride`): genuine u32 — correct.
- **u32-swept mesh/effect/anim tags** (`STRM, GEOM, PRMG, BNDS, ATRB, TRFM, PTYP,
  COLR, TEXT, FRCE, ANIM, AKEY, MANM, TRCK, DATA, watr/tree/UNIQ, POFF/STAT/SWIT/
  NODE/CEXE/PHY2/COMP/TINY/SCRB/INST/PTCH/PTMS/BSHP/VALU, KEYS, flgt`): geometry/
  bounds/transform data = f32/u32. Mis-swap here would be **visual** corruption,
  not save-load crash. No u16 count/stride/offset header was found among these in
  the audited ECS/placement containers; chunks that *do* carry u16 counts
  (texture INFO, trnm, INDX, decl, mesh HIER/MTRL/SEGM/PRMT/BSHI) are already
  handled with u16-aware converters.

**Conclusion: no OTHER crash-risk (stride/offset/count) width bug beyond CHDR.**

---

## E. Architectural recommendation (the principled fix)

### E1. Single schema-driven dispatcher (eliminate the allow-list)

The recurring bug is structural: a hand-maintained "treat as numeric/u32" list
overrides the schema that the engine itself uses. Fix = **prefer the schema**.

**Rust** (`convert_comp_data_inplace`): delete the `is_ecs_numeric_component(...)`
disjunct at line 832 so the live schema path runs for **every** schema'd
component (keep `comp != "Transform"` and the Name/ModelName/Hibernation/
keyed-group special-cases, which exist because their on-disk layout ≠ schm layout
or is variable-length). Keep `swap_numeric_records_inplace` strictly as the
**no-schema** fallback. Net effect: numeric-list components keep identical output
(all 4-byte fields), and any future narrow field is handled automatically.

```
if comp_name != "Transform" && schema.is_none() {
    swap_numeric_records_inplace(data, stride);   // compact/no-schm only
    return;
}
// else: schema-driven per-field swap (existing lines 866-887)
```

**Guard for schm-stride ≠ on-disk-stride** (Transform, PointLocation, Name):
before trusting schm offsets, require `data.len() % (4 + payload_stride) == 0`.
If not, fall back to the existing special-case / numeric handler. (`data_aligned`
check is already computable; Transform/Name/PointLocation are special-cased so
this only adds safety.)

**Python** (`_convert_ecs_comp_data`): add the missing schema-driven path. Pass
the parsed schm fields into `_CompInfo` (extend it with
`fields: list[tuple[type_code, byte_offset]]`, populated in `_build_ecs_comp_map`
from `_convert_schm_body`'s parse), then add a generic handler:

```
def _convert_schema_records(body, stride, fields):
    # record = u32 entity_key + payload; swap key, then each field by type→width
    # type 1/2 -> no swap; 4 -> u16; 5/6/7/8/9 -> u32; 10 -> 3×u32; 11 -> 8×u32
```

Routing in `_convert_ecs_comp_data` becomes: keyed-group → Transform → Name/Model
→ Hibernation → **if schema fields known and data%stride==0: `_convert_schema_records`**
→ else numeric-list/numeric-records → else raise. This lets Python handle
AiPatrol/EquipmentLink/PopulationSimpleSpawner correctly and reach Rust parity,
and removes the latent permissive-mode corruption.

### E2. blob32 / Vec3 / i16 handling

- **Vec3 (type 10)** = 3×u32 (3 f32). Correct.
- **blob32 (type 11)** = 8×u32 (pos 3×f32 + pad f32 + quat 4×f32). Correct and
  retail-verified for the on-disk record. **Do not** special-case a 4×i16 quat for
  on-disk data — it is 4×f32. If a *future* component is found that packs a
  genuine 4×i16 quat in a blob32, add a distinct field type rather than
  overloading type 11 (the schema enum is the right place; `SchemaFieldType` +
  `swap_unit`/`swap_count` already model multi-unit fields).

### E3. Per-chunk-header layout table (non-schm)

CHDR is the only header needing per-field treatment and is fixed. Recommend a
small documented table (header tag → field widths) so future headers are added
deliberately, e.g.:

```
CHDR  : {u16 fieldA; u16 stride_gate; u32 flags}   (engine 0x654940 / gate 0x01176078)
INFO(tex): {7×u16; char[8] fourcc; u32 size; 4×u16}
trnm  : {u16 count; u16 pad; u32[] hashes}
```

---

## F. Prioritized findings table

| # | Site | Current swap | True layout | Evidence | Severity | Affected | Minimal typed fix |
|---|---|---|---|---|---|---|---|
| 1 | CHDR header | (was) two-u32 | `{u16;u16;u32}` | engine `0x654940`; retail oracle | **CRASH** | all ECS containers | FIXED (`_swap_chdr_header` / `swap_chdr_header_inplace`) |
| 2 | schm offset_word | (was) full-u32 | `{u16 byte_offset; u8; u8}` | retail 47/47, 12/12 | data | all schm | FIXED |
| 3 | HibernationControl | (was) u32 sweep | `u32 key; u16; 3×u8; bits` | retail byte pattern | data | layers_static/DLC | FIXED |
| 4 | **Python allow-list / no schema path** | numeric sweep or raise | schema per-field | this audit | **robustness** | any non-listed schema'd comp | add `_convert_schema_records` (E1) |
| 5 | **Rust numeric allow-list short-circuit** | numeric sweep for listed comps | schema per-field | line 832 | **robustness** (latent corruption if a narrow field enters the list) | numeric-list comps | drop `is_ecs_numeric_component` disjunct (E1) |
| 6 | AiPatrol | Py: raise / Rust: schema-ok | `…; bit@16; bit@20` | retail n=206 | correctness | not in DLC (latent) | covered by #4/#5 |
| 7 | EquipmentLink | Py: raise / Rust: schema-ok | `3×u32; bit@12` | retail n=6 | correctness | not in DLC (latent) | covered by #4/#5 |
| 8 | PopulationSimpleSpawner | Py: raise / Rust: schema-ok | `blob32;…; 8×bit@92..99; 3×u32` | retail n=53 | correctness | not in DLC (latent) | covered by #4/#5 |

**Crash-relevant:** only #1 (CHDR), already fixed. **Correctness-only:** #2-#8.
No additional stride/offset/count width bug beyond CHDR.

## G. Suggested validation after the (other worker's) edits land

- Re-run the per-field audit (recreate the scratch script from §B) against
  `vz-patch.wad` and `game-files\vz.wad`; expect **0 BUG verdicts** that are not
  special-cased.
- `tools/verify_ucfx_endian.py --report-blind-swaps` → fallback exposure trends to 0.
- `tools/audit_dlc_conversion.py` mismatch count unchanged (numeric-list output is
  byte-identical before/after the E1 refactor).
- Add a regression component with an interior u16/bit (synthetic schm) to confirm
  the schema path swaps it correctly in **both** converters.
