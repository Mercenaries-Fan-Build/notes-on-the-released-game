---
status: current
evidence: inferred
verified_on: 2026-07-21
witness: "Checked all 14 file/tool references (13 exist, 1 does not: data/ue_game_binding_schema.json is absent and the data/ directory does not exist). Traced the 3 numeric 'Field mappings (verified)' claims into source: hibernation (256-tier)*400 == tools/build_ue_game_binding.py:59, min_draw_distance applied at game-scripts/mercs2_binding_apply.py:159-177; SEA_LEVEL_M=-36.0 and sea_level_ue_cm = sea_m*100 at build_ue_game_binding.py:34,351, consumed at game-scripts/setup_water.py:380; LightObject intensity/attenuation_radius at build_ue_game_binding.py:175-177. The -36 m raster figure traces to docs/gameplay_data_ue5_mapping.md (watr 257x257 decode). NOT verified against the EXE: no engine address was checked, because this doc makes no engine-code claims."
---

# Game → UE5 binding registry

> **SCOPE NOTE (2026-07-21).** Despite the filename, this document has **nothing to do
> with Lua ↔ engine bindings**. "Binding" here means *extracted-game-data → UE5-actor
> mapping* for the UE5 import pipeline. For the Lua C-function registry see
> [`lua_engine_bindings_audit_deep_dive.md`](lua_engine_bindings_audit_deep_dive.md).
>
> **What "verified" means in the tables below:** that the *extraction* was validated
> (filename taxonomy, grid math, ECS stride, raster decode) — **not** that anything was
> validated against `Mercenaries2.exe`. No engine address appears in this document. The
> only row that claims EXE validation is `hibernation`, and it correctly labels itself a
> **hypothesis**. Read the confidence column as "confidence in the extractor", and treat
> every row as `inferred` for engine-behaviour purposes.

**Status:** Active — machine-readable manifest drives Editor auto-configuration.  
**Schema:** ~~[`data/ue_game_binding_schema.json`](data/ue_game_binding_schema.json)~~ — **CORRECTION (2026-07-21): this file does not exist.** Neither `data/ue_game_binding_schema.json` nor the `data/` directory is present in the repo, and `tools/build_ue_game_binding.py:8` points at a third, also-absent path (`docs/data/ue_game_binding_schema.json`). The manifest is currently schema-less; the actual output shape is defined only by `build_manifest()` in `tools/build_ue_game_binding.py`.  
**Builder:** `tools/build_ue_game_binding.py` → `output/ue5_import/ue_game_binding.json` *(builder exists; the output is a build artifact and is not committed — run `make ue-bind-manifest OUTPUT=./output`)*  
**Applicator:** `game-scripts/mercs2_binding_apply.py` / `apply_world_bindings.py` *(both exist)*

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

> **CORRECTION (2026-07-21) — "(verified)" overstates two of the three subsections.**
> Traced into source:
>
> | Mapping | Verdict | Witness |
> |---|---|---|
> | `HibernationControl` → draw distance | **Code-backed, correctly labelled hypothesis.** `(256 - tier) * 400` is literally `tools/build_ue_game_binding.py:59`, returned with the string `"hypothesis"`; applied at `game-scripts/mercs2_binding_apply.py:159-177`. The doc's own "Validate against EXE before treating as metres" still stands — no EXE validation has been done. | `build_ue_game_binding.py:59` |
> | `LightObject` → `PointLight` | **Code-backed.** `intensity` / `attenuation_radius` fall back to `light_intensity` / `light_radius` at `build_ue_game_binding.py:175-177`; 1,197 `layers_static` entities carry decoded `LightObject` ECS data per `gameplay_data_ue5_mapping.md`. | `build_ue_game_binding.py:175` |
> | Watermap → ocean | **Partly verified.** `SEA_LEVEL_M = -36.0` (`build_ue_game_binding.py:34`) and `sea_level_ue_cm = sea_m * 100` (`:351`) are real, and `setup_water.py:380` consumes `sea_level_ue_cm` from the manifest. **But** `setup_water.py:54` still hard-codes `SEA_LEVEL_UE = -2500.0` as the fallback "(empirical)", and `docs/glue_gap_closeout.md` lists calibrating to −36 m as an **open gap**, not a done thing. So −3600 cm is what the manifest *emits*; −2500 is what the Editor uses whenever the manifest is absent. The `ocean_half_m` extent is correctly flagged **hypothesis**. | `setup_water.py:54,380` |

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

> **CORRECTION (2026-07-21)** — all five `game-scripts/*.py` files above exist and were
> confirmed present. `output/ue5_import/ue_binding_report.json` does **not** exist in the
> tree (`output/ue5_import/` contains only `metadata/`); it is generated by
> `make ue-bind-manifest`, which itself depends on `make extract-placements` /
> `extract-terrain` having been run first. Likewise `output/road_graph.json` and
> `output/destruction_graph.json`, cited as the sources for the `road_spline` and
> `destruction_pair` binding kinds, are **not present** — those two rows' "**verified**
> topology" / "**verified** ECS links" grades therefore cannot be re-checked from the
> committed tree; regenerate via `make road-graph` / `make destruction-graph` before
> relying on them.
