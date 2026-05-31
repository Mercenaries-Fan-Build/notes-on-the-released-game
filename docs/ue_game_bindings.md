# Game → UE5 binding registry

**Status:** Active — machine-readable manifest drives Editor auto-configuration.  
**Schema:** [`data/ue_game_binding_schema.json`](data/ue_game_binding_schema.json)  
**Builder:** `tools/build_ue_game_binding.py` → `output/ue5_import/ue_game_binding.json`  
**Applicator:** `game-scripts/mercs2_binding_apply.py` / `apply_world_bindings.py`

Human-oriented domain tables remain in [`gameplay_data_ue5_mapping.md`](gameplay_data_ue5_mapping.md). For automation, **the manifest supersedes** those tables when present.

---

## Workflow

```bash
make extract-placements extract-terrain OUTPUT=./output   # prerequisites
make ue-bind-manifest OUTPUT=./output                     # merge JSON → manifest
```

In UE5 Editor:

```text
py "/path/to/mercenaries-game/game-scripts/apply_world_bindings.py"
```

Or full pipeline: `setup_all.py` (step `apply_world_bindings` after `populate_world`).

Environment:

| Variable | Purpose |
|----------|---------|
| `MERCS2_BINDING_MANIFEST` | Override manifest path |
| `MERCS2_SETUP_SKIP_BINDINGS=1` | Skip bindings step in `setup_all` |
| `MERCS2_BINDINGS_SKIP_ROADS=1` | Skip road spline spawn |
| `MERCS2_BINDINGS_SKIP_DESTRUCTION=1` | Skip destruction-pair markers |
| `MERCS2_BINDINGS_SKIP_HIBERNATION=1` | Skip min draw distance |
| `MERCS2_BINDINGS_APPLY_DAMAGE_BRANCHES=1` | Opt-in damage-branch visibility (future) |

---

## Binding kinds

| `kind` | Game source | UE5 system | Confidence | Auto-config |
|--------|-------------|------------|------------|-------------|
| `vz_overlay` | `vz_state_*` block + placements | `UDataLayerInstance` hierarchy | **verified** (filename taxonomy) | Data Layer create + `runtime_default` |
| `world_cell` | `c3####` review GLB | `StaticMeshActor` @ grid origin | **verified** (grid math) | `Mercs2_BaseWorld`, always activated |
| `static_placement_rule` | `layers_static` entity patterns | spawn / skip | **verified** (populate rules) | `placement_visibility` map |
| `terrain` | `low_res_terrain` merged GLB | origin `StaticMeshActor` | **verified** | Documented in manifest; populate skips tile duplicates |
| `water` | `watermap` `watr` raster | `WaterBodyOcean` Z + extent | **verified** sea level -36 m; extent **hypothesis** | `setup_water` / bindings applicator |
| `light` | ECS `LightObject` | `APointLight` | **verified** (ECS stride) | Manifest rows + populate / bindings |
| `hibernation` | ECS `HibernationControl` | `MinDrawDistance` | **hypothesis** (tier bytes not EXE-validated) | Bindings applicator on existing actors |
| `road_spline` | `road_graph.json` edges | `Actor` + `SplineComponent` (debug) | **verified** topology; nav **gap** | Editor spline actors, no nav |
| `destruction_pair` | `destruction_graph.json` | Hidden rubble on `VZ_Destroyed` | **verified** ECS links; vz overlay pairing **hypothesis** | Marker actors / labels (visual debug) |
| `damage_branch` | SWIT / `mesh.meta.json` | submesh visibility | **verified** extract; intact/damaged side **gap** | Opt-in flag only |

---

## Visibility model

Three tiers (see [`placement_data_format.md`](placement_data_format.md) §10):

1. **Base world** — `layers_static` + c3 cells → always visible (`Mercs2_BaseWorld`).
2. **vz_state overlays** — act / pristine / staging / contract → Data Layers; default preset `act1_default` (Act1 + pristine on; Act2/3 and destroyed/staging off).
3. **Mission Lua** — toggles layers at runtime (not in manifest v1; see `mission_layer_activator.py`).

**c3 cells have no act metadata.** Act-specific geometry is expressed via vz_state overlays and mission scripts, not cell block headers.

---

## Field mappings (verified)

### LightObject → PointLight

| Game (ECS) | UE5 property |
|------------|--------------|
| `light_color_r/g/b` (0–1) | `PointLightComponent.light_color` (`unreal.Color` uint8) |
| `light_intensity` | `Intensity` |
| `light_radius` / `attenuation_radius` | `AttenuationRadius` (× 100 for UE cm) |
| placement XYZ | `SetActorLocation` via `game_to_ue` |

### Watermap → ocean

| Game | UE5 |
|------|-----|
| Wet plateau **-36 m** game Y | `sea_level_ue_cm` = **-3600** (`100 × Y`) |
| 8192 m XZ span | `ocean_half_m` ≥ 5000 m polygon |

### HibernationControl → draw distance (hypothesis)

| Game | UE5 (tentative) |
|------|-----------------|
| `hibernation_u8_0` (213–251) | `min_draw_distance_cm` = `(256 - u8_0) × 400` |

Validate against EXE before treating as metres.

---

## Gaps (honest)

- `RuntimeLayerId` ECS not decoded in placements.
- vz_state per-entity ECS not merged (flgs-only placements).
- SCRB → UE materials not auto-converted.
- Road splines: visual debug only; no Mass Traffic / nav.
- Destruction: graph JSON only; Chaos GC swap not wired.
- Lua → Blueprint mission logic out of scope for manifest v1.

---

## Related files

| File | Role |
|------|------|
| `game-scripts/mercs2_vz_taxonomy.py` | Overlay parse + Data Layer labels |
| `game-scripts/mercs2_data_layers.py` | UE Data Layer CRUD |
| `game-scripts/mercs2_visibility_runtime.py` | Preset toggles |
| `game-scripts/mercs2_binding_manifest_io.py` | Load manifest + placement visibility |
| `output/ue5_import/ue_binding_report.json` | Builder summary + missing inputs |
