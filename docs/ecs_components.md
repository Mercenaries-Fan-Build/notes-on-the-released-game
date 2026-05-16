# ECS `COMP` components — verified record format

**Date:** 2026-05-15 (updated)  
**Tools:** [`tools/ucfx_ecs_codec.py`](../tools/ucfx_ecs_codec.py), [`tools/ecs_metadata_extract.py`](../tools/ecs_metadata_extract.py)  
**Output:** [`output/placements/ecs_components.json`](../output/placements/ecs_components.json)

## Record format (layers_static)

Every COMP `data` blob in a `layers_static` sub-UCFX is an array of
fixed-stride records.  Each record is:

```
[ u32_le entity_key ][ payload bytes … ]
```

The **entity key** is the same u32 that appears in the Name COMP and the
Transform COMP for the same entity.  All COMPs in a sub-block share the
same key space.

### Stride determination

The `schm` child of each COMP carries a binary schema descriptor:

| Offset | Type  | Field          |
|--------|-------|----------------|
| 0      | u32   | n_fields       |
| 4      | u32   | payload_stride |
| 8+     | 16×N  | field entries (type, name_hash, unk, field_offset) |

**Total record stride = 4 (entity key) + payload_stride.**

Exception: `Transform` — the schm reports payload_stride=52 but the
verified payload is 38 (stride 42).  All other COMPs match schm exactly
(validated across all 173 sub-blocks).

### Verified COMP types and strides

| COMP name | Payload stride | Fields | Notes |
|-----------|---------------|--------|-------|
| Name | variable | entity name string | `u32 key + null-terminated "name 0xKEY" + \x00 pad` |
| Transform | 38 (stride 42) | position XYZ + rotation | `u32 key + 3×f32 pos + rotation data` |
| ModelName | 4 (stride 8) | u32 model hash | Consistent across 13 sub-blocks |
| HibernationControl | 6 (stride 10) | u8+u8+u16+u16 | 48 sub-blocks, 1797 entities |
| ObjectScript | 8 (stride 12) | u32 script hash + u32 | 7 sub-blocks |
| DestructionLink | 16 (stride 20) | u32 ref key + u32 flags + more | 39 sub-blocks |
| LightObject | 52 (stride 56) | u32 + RGB floats + intensity + radius + more | 22 sub-blocks |
| Road | 40 (stride 44) | lane/intersection data | 29 sub-blocks |
| RoadIntersection | 124 (stride 128) | intersection geometry | 38 sub-blocks |
| ModifierKey | 8 (stride 12) | modifier reference | 23 sub-blocks |
| ScrubObject | 4 (stride 8) | scrub hash | 12 sub-blocks |
| LineRegion | 4 (stride 8) | region ref | 16 sub-blocks |
| MaterialMapping | 8 (stride 12) | material refs | 3 sub-blocks |
| PhysicalLink | 44 (stride 48) | physics link data | 16 sub-blocks |
| LandingZone | 272 (stride 276) | zone definition | 1 sub-block |
| Label | 4 (stride 8) | label hash | 22 sub-blocks |
| Anchor | 16 (stride 20) | anchor data | 3 sub-blocks |

### Extraction results (layers_static)

- **62,624** total placements with entity_id
- **10,030** ECS records extracted across 43 unique COMP types
- **7,984** placements (12.7%) received at least one ECS component

### COMP distribution

| COMP | Entities with it |
|------|-----------------|
| Road | 2,441 |
| HibernationControl | 1,797 |
| LightObject | 1,197 |
| ScrubObject | 1,033 |
| RoadIntersection | 883 |
| DestructionLink | 672 |
| ModifierKey | 537 |
| PhysicalLink | 465 |
| ModelName | 464 |
| ObjectScript | 103 |
| Label | 91 |
| LineRegion | 77 |
| MaterialMapping | 18 |
| DangerousBuilding | 14 |
| Anchor | 8 |
| StateMachine | 4 |
| PointLocation | 2 |
| LandingZone | 2 |
| BuildingDestruction | 1 |

## vz_state — different structure

vz_state CHDR COMP entries do **not** follow the per-component-type keyed
record pattern.  Instead, each COMP entry contains:

- **info**: a packed blob with component names, field name hashes, and
  metadata — the offset frequently points into the middle of a string
- **schm**: a string table with entity names and references
- **data**: mixed data (entity names, enum value tables, config data)

Placement data for vz_state entities comes from the `flgs` section, which
is already extracted by `placement_extractor.py`.  The COMP entries in
vz_state carry component *definitions* (VehicleWeakPoint, TreeLeaves, etc.)
and enum value tables, not per-entity keyed records.

Cross-referencing between vz_state placements and layers_static is done via
the shared `entity_id` field.

## Merge rules

`ucfx_ecs_codec.merge_ecs_into_placements`:

- **layers_static:** match by u32 entity key (from `entity_id` hex string on
  placements → `entity_key` int on ECS records).
- **vz_state:** no ECS records are currently extracted from vz_state COMP
  blobs (fundamentally different structure).

## RuntimeLayerId

Not found as an explicit ASCII string in `layers_static` or `vz_base` blobs.
May be hash-identified in `schm` tables without a plaintext `info` name.
