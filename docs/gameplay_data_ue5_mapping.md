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

### Gap
- `type_hash` → friendly name decoder not built yet
- vz_state COMP data not parsed into per-entity records (different binary structure)

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
- **Data flow:** `FillDataTableFromJSONFile` loads placement JSON → DataTable rows → SpawnManager reads at runtime
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
| `destruction_ref_key` | u32 hex | References the linked entity (rubble variant or parent) |
| `destruction_u32_1` | u32 | Behavior flags (not fully decoded) |

### UE5 implementation

- **System:** Chaos Destruction (Geometry Collections) for fracturing + custom `UDestructibleLinkComponent`
- **Concept:** Each `DestructionLink` pairs an intact building with its destroyed variant. On destruction event, swap the intact Geometry Collection for the rubble one.
- **`DangerousBuilding`:** Tag these actors so gameplay systems know they can collapse on the player
- **`BuildingDestruction`:** Root controller for coordinated multi-part destruction sequences
- **Data flow:** Build a destruction graph from `destruction_ref_key` → entity_id cross-references

### What we have now
- 672 entity pairs with destruction links
- Entity positions (so we know which buildings are destructible)

### Gap
- `destruction_ref_key` → target entity resolution not implemented
- Destruction behavior flags not decoded
- Intact → rubble mesh pairing not established

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
- Lane data and intersection connectivity (payload bytes, not yet decoded into graph form)

### Gap
- Road topology (which road connects which intersections) not extracted from payload
- Lane count, direction, speed limits not decoded
- No spline generation tool yet

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
- Lua string harvest (function names, region names, trigger identifiers)
- Lua chunk binaries (need LuaDisAss for decompilation)

### Gap
- Full Lua decompilation not done (LuaDisAss integration incomplete)
- Script hash → Lua chunk mapping not built
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
- Region geometry (extent, shape) not decoded from payload
- LineRegion vertex data not extracted (just entity position, not the line points)

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
- [ ] **Lights** — spawn PointLight actors with color/intensity/radius from ECS
- [ ] **Data Layers** — assign all vz_state actors to named Data Layers
- [ ] **Hibernation** — set streaming distance from HibernationControl values

### Phase 2: Near-term (new tools + Blueprints)
- [ ] **Spawn point actors** — Blueprint that reads entity_name, spawns correct actor class
- [ ] **Destruction links** — resolve entity pairs, set up Chaos destruction swap
- [ ] **type_hash decoder** — resolve unnamed vz_state entities to friendly names

### Phase 3: Medium-term (systems)
- [ ] **Road network** — decode Road/RoadIntersection payloads into graph, generate splines
- [ ] **Region volumes** — decode LineRegion geometry, spawn trigger volumes
- [ ] **Mission framework** — data-driven contract system from overlay naming + Lua harvest

### Phase 4: Long-term (full game logic)
- [ ] **Lua → Blueprint** translation of mission scripts
- [ ] **AI behavior** — patrol routes from road network + spawn data
- [ ] **Interior streaming** — portal system from EntranceLink data
- [ ] **Briefing UI** — UMG widgets from scaleform texture reference
