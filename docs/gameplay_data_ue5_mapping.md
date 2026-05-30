# Gameplay Data → UE5 System Mapping

**Date:** 2026-05-15  
**Purpose:** Document all non-mesh data extracted from the original game and how each category maps to UE5 systems for eventual implementation.

---

## Data Inventory Summary

| Source | Records | Named | With ECS | Notes |
|--------|---------|-------|----------|-------|
| layers_static | 62,624 | 60,136 | 7,984 (12.7%) | Always-visible base world |
| vz_state (all) | 3,501 | ~1,260 | 0 | Conditional overlays (different COMP structure) |
| ECS components | 10,030 | — | — | Per-entity keyed records from layers_static |
| Lua chunks | 114 | — | — | scripts_vz LuaQ bytecode |
| Scaleform | 3 blocks | — | — | Briefing UI textures |

---

## 1. World State Overlays → UE5 Data Layers

### Source data
Each `vz_state` file encodes a **conditional world overlay** — entities that appear/disappear based on game state. 746 source files, 3,501 total placements.

### Overlay naming convention (systematic)

| Pattern | Count | Meaning |
|---------|-------|---------|
| `*_pristine` | ~5 | Default pre-war look |
| `*_act1` / `*_act2` / `*_act3` | ~8 | Story progression overlays |
| `*_staging` | ~10 | Pre-mission setup (defenses, vehicles) |
| `*_attack` / `*_combat` | ~5 | Active combat scenario |
| `*_spawnerspam` / `*_recyclebin` | ~5 | NPC wave spawn data |
| `*_villasoldiers` / `*_taunters` | ~5 | NPC placement per mission phase |
| `*_interior` / `*_mecabsent` / `*_mec` / `*_hel` / `*_jet` | ~6 | PMC interior variants (faction present/absent) |
| `*_popup` / `*_popdown` | ~2 | Dynamic building state changes |
| `pmccon###` / `pmcjob###` | ~40 | Contract/job-specific overlays |

### UE5 implementation

- **System:** `UDataLayerInstance` + `AWorldDataLayers`
- **API:** `UDataLayerSubsystem::SetDataLayerRuntimeState(layer, EDataLayerRuntimeState::Activated)`
- **Setup:** One Data Layer per `vz_state` source file. Actors placed into layers by source.
- **Runtime:** Game state manager activates/deactivates layers when contracts start, story progresses, or interiors stream.
- **Python populate script** should assign each spawned actor to its Data Layer via `unreal.DataLayerEditorSubsystem`.

### What we have now
- Position + rotation for all 3,501 overlay entities
- Source file → overlay name mapping
- ~1,260 have human-readable entity names
- ~2,241 have only `entity_id` + `type_hash` (names unresolved)
- **Implemented:** `populate_world.py` / `populate_pmc_base.py` assign actors to a three-level Data Layer hierarchy (`VZ_ActN_Region` → leaf per overlay) via `mercs2_data_layers.py` + `mercs2_vz_taxonomy.py`
- **Implemented:** Initial PIE states — Act1 + pristine ACTIVATED; Act2/3 and staging/destroyed UNLOADED (`initial_runtime_activated()`)
- **Starter runtime API:** `game-scripts/mercs2_visibility_runtime.py` + `toggle_vz_visibility.py` for preset-based layer toggling in Editor/PIE

### Gap
- `type_hash` → friendly name decoder not built yet
- vz_state COMP data not parsed into per-entity records (different binary structure)
- No in-game mission manager driving layer changes at runtime (Editor Python activator only)
- `populate_world.py` does not set per-actor hibernation/streaming distances yet

### Mission overlay activator (Editor)
- **Data:** `docs/data/examples/pmccon001_mission.json` → `DT_MissionRegistry` via `import_mission_data.py`
- **Runtime (Editor/PIE):** `mission_layer_activator.py` with `MERCS2_MISSION_ID=PmcCon001` activates
  `VZ_Contract` parent + mission leaf layers (`VZ_pmccon001`, …) using `mercs2_visibility_runtime.py`
- **Runbook:** `docs/data/README.md` — PMC vertical slice baby-step sequence

---

## 2. Entity Spawners → Data-Driven Spawn System

### Source data (from vz_state entity names)

| Category | Count | Examples |
|----------|-------|---------|
| NPC/Soldier spawners | ~69 | `Allied Soldier`, `VZ Soldier`, `Allied Heavy (Light MG)` |
| Vehicle spawns | ~21 | vehicle-related placements in combat overlays |
| Weapon/ammo pickups | ~66 | `Ammo Pickup (Rocket)`, `Ammo Pickup (Explosive)` |
| Mission fortifications | ~49 | `_global_barricaded`, `_global_explosivebarrel`, tank traps |
| Conditional buildings | ~52 | Buildings that swap between overlays |

### UE5 implementation

- **System:** Custom `ASpawnPointActor` Blueprint + `USpawnManagerSubsystem`
- **Data flow:** `import_mission_data.py` loads `docs/data/examples/*_spawn_table.json` → `DT_SpawnRegistry`;
  future `SpawnManager` subsystem reads rows at runtime
- **Actor classes:** Map entity name patterns to UE5 actor classes:
  - `*Soldier*` / `*Heavy*` → `ACharacter` subclass with AI Controller
  - `*Ammo Pickup*` → `APickupActor` with inventory data
  - `*explosive*` / `*barricade*` → Destructible prop actors
  - `*Light_*` → `APointLight` with color/intensity from ECS
- **Spawn timing:** Controlled by Data Layer activation (spawn when layer activates, despawn when deactivated)

### What we have now
- World positions and rotations for all spawnable entities
- Entity names that encode what to spawn
- Data Layer association (which overlay triggers the spawn)

### Gap
- No entity class → UE5 Blueprint mapping table yet
- NPC behavior (patrol routes, factions, weapons) not decoded
- Vehicle types not resolved from `type_hash`

---

## 3. Lights → Point/Spot Light Actors

### Source data
1,197 entities in layers_static have `LightObject` ECS data with decoded fields.

### Decoded fields (ready to use)

| Field | Type | UE5 Property |
|-------|------|-------------|
| `light_color_r` | float | `LightColor.R` |
| `light_color_g` | float | `LightColor.G` |
| `light_color_b` | float | `LightColor.B` |
| `light_intensity` | float | `Intensity` |
| `light_radius` | float | `AttenuationRadius` |

### UE5 implementation

- **System:** `APointLight` actors (or `ASpotLight` if directionality can be determined)
- **Populate script:** Read `ecs.LightObject` from placement, spawn `PointLight`, set properties directly
- **Priority:** Low effort, high visual impact — can implement immediately

### What we have now
- Complete light data for 1,197 lights (color, intensity, radius)
- World positions and rotations
- **Implemented:** `populate_world.py`, `populate_pmc_base.py`, and `populate_radius_zone.py` spawn `APointLight` actors from `ecs.LightObject` via `place_light_from_placement()`

### Gap
- Light type (point vs spot vs directional) not distinguished
- `light_u32_0` field purpose unknown (possibly light type enum)

---

## 4. Destruction System → Chaos Destruction

### Source data
- 672 entities with `DestructionLink` ECS
- 14 entities with `DangerousBuilding` ECS
- 1 entity with `BuildingDestruction` ECS

### Decoded fields

| Field | Type | Purpose |
|-------|------|---------|
| `destruction_ref_key` | u32 hex | Primary ref key (schm type6 @0) |
| `destruction_u32_1` | u32 | Behavior flags (schm type9 @4; not fully decoded) |
| `destruction_link_key` | u32 hex | Secondary ref key (schm type7 @8) |
| `destruction_u32_3` | u32 | Additional hash (schm type6 @12) |

### UE5 implementation

- **System:** Chaos Destruction (Geometry Collections) for fracturing + custom `UDestructibleLinkComponent`
- **Concept:** Each `DestructionLink` pairs an intact building with its destroyed variant. On destruction event, swap the intact Geometry Collection for the rubble one.
- **`DangerousBuilding`:** Tag these actors so gameplay systems know they can collapse on the player
- **`BuildingDestruction`:** Root controller for coordinated multi-part destruction sequences
- **Data flow:** Build a destruction graph from `destruction_ref_key` → entity_id cross-references

### What we have now
- 672 entities with `DestructionLink` ECS payloads (merged into `layers_static.json`)
- Entity positions (so we know which buildings are destructible)
- **Implemented:** `tools/destruction_link_resolver.py` resolves ref keys → placement targets and emits `output/placements/destruction_graph.json` (pairs, orphans, DangerousBuilding tags)
- **Implemented:** optional `--vz-state-json` / `--vz-state-glob` merges `vz_state_cross_reference` (destroyed/ruined overlays matched by `entity_id` and `mesh_stem` + proximity; `model_name_hash` annotated via `tools/hash_resolver.py`)

### Gap
- Destruction behavior flags (`destruction_u32_1`) not decoded
- Intact → rubble mesh pairing not wired in UE5 (graph JSON only; no Chaos GC swap component)
- vz_state overlay pairing is heuristic (name stem + distance); not validated against in-engine swap tables

---

## 5. HibernationControl → Streaming Distance / LOD

### Source data
1,797 entities with `HibernationControl` ECS data.

### Decoded fields

| Field | Type | Hypothesis |
|-------|------|-----------|
| `hibernation_u8_0` | u8 | Distance tier or activation flag (values: 213-251) |
| `hibernation_u8_1` | u8 | Usually 0, occasionally 1 |
| `hibernation_f16_or_u16` | u16 | Activation distance or region ID |
| `hibernation_u16_4` | u16 | Usually 20 (0x0014) — possibly a fixed threshold |

### UE5 implementation

- **System:** World Partition streaming distance per actor, or `SetMinDrawDistance`
- **Populate script:** Set `actor.root_component.set_editor_property('min_draw_distance', value)` based on hibernation fields
- **Alternative:** Custom `UHibernationComponent` that activates/deactivates tick and collision based on player distance

### What we have now
- Raw hibernation bytes for 1,797 entities
- Positions of all hibernation-controlled entities

### Gap
- Field semantics not fully verified (need to cross-reference with known game behavior)
- Relationship between `hibernation_u8_0` values and actual distances unclear

---

## 6. Road Network → Spline Roads + AI Navigation

### Source data
- 2,441 entities with `Road` ECS (payload stride 44)
- 883 entities with `RoadIntersection` ECS (payload stride 128)
- Also: `IntersectionToIntersection` links, `LaneData`, `LaneZeroDirection`

### UE5 implementation

- **System:** Spline actors for road visuals + `ANavModifierVolume` for AI pathfinding
- **Alternative:** UE5 Mass Traffic plugin (experimental) for AI vehicle traffic
- **Data flow:** RoadIntersection nodes → Road segments between them → spline network
- **AI use:** Feed road graph into AI navigation for vehicle patrols and traffic

### What we have now
- Road and intersection entity positions
- **Implemented:** `tools/road_graph_extractor.py` builds `road_graph.json` from `road_ref_key_0/1` ↔ `RoadIntersection` entity keys (stats: fully linked / partial / unresolved edges; `topology_validation` block)
- Optional Maracaibo debug maps: `--bbox -1200 1400 -1100 600` with `--export-geojson` / `--export-svg`
- Lane endpoint Vec3s exported per edge; intersection `lane_hints` (6× Vec3) attached to nodes

### Gap
- Lane count, direction, speed limits not decoded (`road_lane_hash_*` unresolved to traffic rules)
- `IntersectionToIntersection` / `LaneData` COMPs not harvested into the graph
- No spline generation tool yet (graph JSON is input-only)

---

## 7. ObjectScript → Mission Logic / Blueprint Translation

### Source data
- 103 entities with `ObjectScript` ECS (script_hash_0 references Lua)
- 114 LuaQ chunks in scripts_vz
- Lua string harvest: `CheckpointRegionActivate`, `BeachRegionActivate`, `MrxPmc`, `ActivateTutorial`, etc.

### UE5 implementation

- **Short term:** Document what each script does based on decompiled Lua
- **Medium term:** Translate Lua logic into Blueprint event graphs
- **Long term:** C++ mission system with data-driven contract definitions
- **Mission structure:** Each `pmccon###` contract has:
  - Staging overlay (pre-position defenses, NPCs)
  - Combat overlay (active enemies, objectives)
  - Completion state (destroy targets, rescue NPCs)
  - Briefing UI (scaleform textures)

### What we have now
- Script hash → entity cross-reference
- **`tools/script_hash_map.py`** → `output/placements/script_hash_map.json` (ObjectScript `script_hash_0` ↔ Lua chunk paths; runs as part of **`make extract-placements`**)
- Lua string harvest (function names, region names, trigger identifiers)
- Lua chunk binaries (need LuaDisAss for decompilation)

### Gap
- Full Lua decompilation not done (LuaDisAss integration incomplete)
- Blueprint translation not started

---

## 8. Regions / Zones → Trigger Volumes

### Source data
- 77 `LineRegion` entities (patrol routes, area boundaries)
- 2 `PointLocation` entities (named map markers)
- 2 `LandingZone` entities (helicopter landing pads)
- Lua references to `*RegionActivate` functions

### UE5 implementation

- **`LineRegion`** → `ATriggerBox` or spline-based trigger volume
- **`PointLocation`** → `ATargetPoint` named map marker
- **`LandingZone`** → Custom `ALandingZoneActor` with helipad mesh + landing trigger
- **Faction zones** (from ECS): `ATriggerBox` with faction ownership data

### What we have now
- Entity positions for all region entities
- Entity names that encode region purpose

### Gap
- ~~Region geometry (extent, shape) not decoded from payload~~ — **resident `lineregion` polygons decoded** (see §16); `layers_static` `LineRegion` COMP still only a 4-byte ref
- Link lineregion asset_hash → weather zone name / `Graphics.ChangeLineRegionSetting` IDs (Lua harvest)

---

## 16. Weather / `lineregion` (resident) → Zones & splines

### Source data
- **625** `lineregion` assets (`0x6310807F`, ASET type_id 30) in `resident_P000_Q3`
- Sizes 88–1424 B (variable point count)
- **77** `LineRegion` ECS placements in `layers_static` reference regions by hash

### Decoded format (confirmed)
- UCFX → single `data` chunk
- Header: `u16 kind` (= 2), `u16 point_count`, `u32` zero
- Vertices: `point_count × (float x, float z)` in **game metres** (world span ≈ ±4036 m)
- Tool: `tools/lineregion_probe.py`

### UE5 implementation
- **Weather zones (track 16):** `ATriggerVolume` or closed spline mesh from polygon; tie to `setup_weather_system.py` / `Weather` plugin volumes
- **Patrol / triggers:** same geometry for AI splines and mission `LineRegion` triggers

### Gap
- asset_hash → human zone name (path table / Lua string xref)
- Which of 625 regions are weather vs patrol vs mission (heuristic by size/name TBD)
- `LineRegion` COMP 4-byte ref → resident `lineregion` index map

---

## 17. Water / `watermap` → Ocean & water bodies

### Source data
- Singleton `watermap` (`0x4D7D30C4`) in `resident`, `watr` payload **495,669 B**
- **257×257** grid, **32 m** cells, **8192×8192 m** XZ span (see [`watermap_format.md`](watermap_format.md))

### Decoded layers (retail PC)
| Layer | Format | Role | Status |
|-------|--------|------|--------|
| 0 | f32 | Water surface / bathymetry height (m) | confirmed |
| 1 | u8 | Wet mask (`0` dry, `255` wet) | confirmed |
| 2 | u8 | Coastal variant (mostly 255) | hypothesis |
| 3 | u8 | Sparse overrides | hypothesis |
| 4 | blob | 33,290 B footer | size confirmed, semantics unknown |

**Sea level in raster:** wet cells ≈ **-36 m** game Y; dry sentinel **-50 m**.

### UE5 implementation
- **Current:** `game-scripts/setup_water.py` — hand-tuned `WaterBodyOcean` square, `SEA_LEVEL_UE = -2500` (not tied to `watr`)
- **Target:** sample mask + height → `WaterBodyOcean` Z from `game_to_ue`; optional river/lake meshes where mask=255 and height > sea

### Tools & artifacts
```bash
.venv/Scripts/python tools/watermap_decode.py --wad game-files/pc-game-vz.wad --png
# JSON: output/watermap_decode.json
# PNG: output/_scratch/watermap/layer00_height_u16.png
```

### Gap
- Footer blob decode
- Grid origin vs world (0,0) — EXE validation
- Calibrate `SEA_LEVEL_UE` to -36 m game height via coastal probe

---

## 9. Scaleform Briefings → UMG Widget UI

### Source data
3 scaleform blocks with DXT1/DXT5 textures for contract briefing screens.

### UE5 implementation

- **System:** UMG (Unreal Motion Graphics) widget Blueprints
- **Textures:** Import briefing images as UI textures
- **Layout:** Reference original Flash layouts for UMG recreation
- **Per-contract:** Each `scaleform_pmccon###briefing` block has fullscreen, static, and shot textures

### What we have now
- Briefing textures (DDS/PNG) in the UE bundle
- Texture names that encode which contract they belong to

### Gap
- Flash layout data not decoded (only textures extracted)
- Text/localization strings not yet extracted from briefing blocks

---

## 10. Interior Streaming → Level Streaming / Portals

### Source data
- `EntranceLink` / `EntranceParameters` / `EntranceToSeat` COMPs (in layers_static ECS, rare)
- `pmc_interior` block + `pmcinterior_*` vz_state overlays
- `SoundInterior` COMP
- `Door` / `DoorCoupling` COMPs

### UE5 implementation

- **System:** Level Streaming volumes + custom portal Blueprint
- **Concept:** `EntranceLink` defines a portal between exterior and interior. When player enters the portal trigger, stream in the interior level and transition.
- **Door actors:** `Door` + `DoorCoupling` pairs define interactive doors
- **Sound:** `SoundInterior` triggers audio zone changes (reverb, ambient)

### What we have now
- Portal records in `ecs_components.json` (portal_record_count)
- Interior overlay filenames

### Gap
- Portal geometry/bounds not decoded
- Door interaction logic not decoded
- Interior → exterior transition graph not built

---

## Implementation Roadmap

### Phase 1: Immediate (populate scripts)

| Item | Status | Implementation |
|------|--------|----------------|
| **Lights** | Done | `populate_world.py` / `populate_pmc_base.py` / `populate_radius_zone.py` → `place_light_from_placement()` |
| **Data Layers** | Done | `mercs2_data_layers.py` + `mercs2_vz_taxonomy.py`; populate scripts assign vz_state actors to hierarchical layers |
| **Hibernation** | Not started | ECS decoded in `ucfx_ecs_codec.py`; no populate-script wiring yet |
| **Runtime visibility (stretch)** | Starter stub | `mercs2_visibility_runtime.py` — Editor/PIE preset toggles only |

**World diorama subset (Item 1):** use `make filter-pool-200m` → `import_radius_zone.py` → `populate_radius_zone.py` for a ~200 m test cell without full-world populate.

### Phase 2: Near-term (new tools + Blueprints)
- [ ] **Spawn point actors** — Blueprint that reads entity_name, spawns correct actor class
- [ ] **Destruction links** — wire `destruction_graph.json` pairs + vz_state overlays into Chaos GC swap Blueprint
- [ ] **type_hash decoder** — resolve unnamed vz_state entities to friendly names

### Phase 3: Medium-term (systems)
- [ ] **Road network** — generate splines / nav from `road_graph.json` (topology extract done)
- [ ] **Region volumes** — wire `lineregion_probe` polygons to trigger volumes + weather zones
- [ ] **Water raster** — drive `setup_water.py` from `watermap_decode` height/mask
- [ ] **Mission framework** — data-driven contract system from overlay naming + Lua harvest

### Phase 4: Long-term (full game logic)
- [ ] **Lua → Blueprint** translation of mission scripts
- [ ] **AI behavior** — patrol routes from road network + spawn data
- [ ] **Interior streaming** — portal system from EntranceLink data
- [ ] **Briefing UI** — UMG widgets from scaleform texture reference

---

## 11. Audio (wavebank / soundbank) → UE5 Sound System

### Source data
- **95** wavebank entries (`0xF753F6D0`) — embedded IMA ADPCM clips
- **76** soundbank entries (`0x9F8BCA10`) — event → clip routing
- **77** sounddb entries (`0xE5273C14`) — block-level audio package manifests
- **PWS** streams under `data/Audios/` — music, VO, ambience

### UE5 implementation
- **System:** `USoundWave` + `USoundCue` / MetaSounds, `USoundAttenuation`, `USoundConcurrency`
- **Manifest:** [`tools/audio_ue5_manifest.py`](../tools/audio_ue5_manifest.py) maps hashes → WAV paths + `/Game/Mercs2/Audio/...` content paths
- **Editor scaffold:** [`game-scripts/setup_audio_import.py`](../game-scripts/setup_audio_import.py)
- **Runtime:** DataTable `event_hash → SoundCue` to replace Lua `Sound.CueSound(name)`

### What we have now
- Full audio engine design doc ([`pandemic_audio_system_design.md`](pandemic_audio_system_design.md))
- PWS extraction via `make extract-audio`
- DLC clip inventory via `dlc_audio_manifest.py`
- WAD simulator audio consumption modules (Rust)

### Gap
- Full-archive wavebank decode optional — **`wavebank_extractor.py`** + **`ima_adpcm.py`** decode embedded IMA ADPCM (`0x02`) → WAV (verified on `ui_hud`; see [`audio_ue5_path.md`](audio_ue5_path.md))
- **`import_audio.py`** stub exists; Interchange batch import needs in-Editor validation
- Soundbank event names hash-only; `sounddb` load order not in manifest

**Full plan:** [`audio_ue5_path.md`](audio_ue5_path.md) §1 and §5

---

## 12. Effects + SCRB materials → Niagara + UE Materials

### Source data
- **1** fxdict (`0xFA46D8A8`) — global FX parameter dictionary in **`resident`** block (not the `effects` block file — see [`fxdict_format.md`](fxdict_format.md))
- **314** effect entries (`0x5608BD5A`) — particle/VFX definitions in `effects` block
- **1,026** scrub packages (`0x600B904E`) — SCRB+MTRL compiled shaders in c3 cells
- **1,033** `ScrubObject` ECS placements — scrub hash per instance

### UE5 implementation
- **fxdict →** `UNiagaraParameterCollection` or DataTable
- **effect →** `UNiagaraSystem` (one per effect hash)
- **scrub →** `UMaterialInstanceConstant` (manual rebuild from MTRL texture slots; SCRB bytecode not portable)
- **Placements →** `ANiagaraActor` via extended populate script

### Gap
- **Partial decode:** [`fxdict_parser.py`](../tools/fxdict_parser.py) + [`effect_block_probe.py`](../tools/effect_block_probe.py) — INFO+DICT stride and effect chunk tags documented in [`fxdict_format.md`](fxdict_format.md); parameter names still hash-only
- No Niagara template library; no `effect_extractor.py` catalog JSON yet
- SCRB → UE material auto-conversion not feasible — probe with [`material_probe.py`](../tools/material_probe.py)

**Full plan:** [`audio_ue5_path.md`](audio_ue5_path.md) §2

---

## 13. FaceFX → Lip-sync (Morph Targets / Audio2Face)

### Source data
- **86** facefxanimationset (`0x665EF13E`) — contract/briefing dialogue curves
- **31** facefxactor (`0x1CF649BB`) — facial rig definitions

### UE5 implementation
- **Phase 1:** Subtitles only (stringdb + dialog fragments)
- **Phase 2:** Import FaceFX curves → morph target AnimSequences
- **Phase 3:** Sync to VO WAV from PWS / dialog audio
- **Long-term:** MetaHuman + Audio2Face for new content

### Gap
- No FaceFX extraction or format decoder
- Morph target name map unknown

**Full plan:** [`audio_ue5_path.md`](audio_ue5_path.md) §3

---

## 14. Scaleform GFX → UMG

### Source data
- **60** scaleformgfx entries (`0xFE0E8320`) — CFX/zlib Flash UI
- Briefing **textures** already in UE bundle; layouts not decoded

### UE5 implementation
- **System:** UMG Widget Blueprints (not Scaleform GFx plugin)
- **Existing:** `WBP_HUDRoot`, `WBP_PauseMenu` ([`setup_basic_hud.py`](../game-scripts/setup_basic_hud.py))
- **Migration:** Screenshot/reference layout + imported briefing PNGs; do not depend on SWF decompilation

### Gap
- CFX payload not decoded
- HUD widget bindings not wired
- No contract briefing widget scaffold

**Full plan:** [`audio_ue5_path.md`](audio_ue5_path.md) §4
