# World streaming

Scope: world/terrain streaming and content — terrain meshes, WAD/level loading, content streaming blocks, object spawning/population, props & destructibles, water/ocean, regions, and object hibernation/pooling.

Provenance: All symbols, offsets, and strings below are copy-exact from the recovered Xbox 360 preview executable `Mercs2_Xenon_P.exe` (Mercenaries 2: World in Flames, Jul 11 2008 devkit "Profile" build, PowerPC). Evidence files: `output/jul08_prototype/inventory/world-streaming.txt`, `output/jul08_prototype/mercs2_xenon_p.pe_full_strings.txt`, `output/jul08_prototype/mercs2_xenon_p.rtti_classes.txt`, `output/jul08_prototype/mercs2_xenon_p.source_paths.txt`. This is symbol/string evidence, not a real `.pdb`. The in-house engine is "Pangea" (`Pg*`); physics is Havok (`hk*`/`hkp*`). Build tree was `d:\projects\ReleaseLine\Mercs2\`.

## Overview

This subsystem covers how Mercenaries 2 brings world content into and out of memory as the player moves through the open world, and the content that lives in that world. It spans several grounded areas:

- **Streaming / load orchestration** — symbols `StreamManagerUpdate`, `StreamPreload`, `StreamPostload`, `UpdateStreamBlocks`, `OpenStreamFile`, `CloseStreamFile`, `IsLoadingOrStreaming`, `StreamingManager`, `StreamingWaiting`, `LoadLevel`, `LoadAsset`, `LoadLayer`, `LoadingStaticLayers`. The world is loaded from WAD archives (`d:\vz.wad`, `%sshell.wad`, `%sloading.wad` appear in the strings).
- **Terrain** — a multi-LOD terrain mesh shader family (`PgTerrainMesh*`), a low-res terrain (`PgLowResTerrain`), height queries (`GetTerrainHeight_Fast`/`GetTerrainHeight_Slow`, `GetHeightAboveTerrain`), and terrain content/streaming objects (`TerrainObject`, `LowResTerrainObject`, `TerrainFade`, `HighResTerrainPatchObjectID`, `TerrainGuidMappingHighResToLowRes`).
- **Population / spawning** — `PgSysPopulation` and its methods drive simple/traffic/path/window spawners (`PopulationSimpleSpawner`, `TrafficSpawner`, `WindowSpawner`, `HardpointSpawners`, `PathSpawners`), faction spawn lists, and queued/deferred/adjacent spawning.
- **Hibernation / pooling** — `HibernationControl`, `ObjectHibernation`, `Del::Hibernate`, `IsHibernated`, and hibernation-distance get/set/revert, governing how far-away objects are cached out.
- **Regions** — sphere/circle/line regions (`SphereRegion`, `CircleRegion`, `LineRegion`, `PgLineRegion`) used for music/faction/skirmish zones.
- **Water/ocean** — a `PgWater*` shader family plus water physics/action tunables.
- **Props / destructibles** — `PropPhysics`, the `Prop*` material classes, prop/terrain asset name tables, and `BuildingDestruction`/`DestructionLink`.

The only directly attributable source path is `PgGameSystem.cpp` (see below); most of this subsystem's symbols are exported reflection names, shader names, debug-menu toggles, and ECS component class names rather than file-tagged asserts.

## Source files

From `output/jul08_prototype/mercs2_xenon_p.source_paths.txt`, the path most directly tied to world/game-system update (host of `PgSysPopulation` / `SysWorldJob`-style game systems, inferred from the `PgSys*` naming):

```
d:\projects\releaseline\mercs2\pangea\Src\PgGameSystem.cpp
```

Note: no dedicated terrain/streaming/spawner `.cpp` path survives in the recovered source-path table. `PgSoundStreamIO.cpp` also appears but belongs to the **audio** subsystem (its `UpdateStreamBlocks`/`StreamBlocks: %d` strings are sound-stream blocks, not world-content blocks — see Cross-references).

## Key classes

No `.?AV`/`.?AU` RTTI entries for the engine's `Pg*` world-streaming classes survive in `mercs2_xenon_p.rtti_classes.txt` (the `Pg*` world types appear only as plain `.rdata` symbols, not as RTTI type descriptors). The RTTI file's only streaming/world matches belong to **Havok** physics-world and stream-IO classes, which support but are not part of the world-content streamer:

- `class hkpWorld` — `.?AVhkpWorld@@`
- `struct hkpWorldCinfo` — `.?AVhkpWorldCinfo@@`
- `class hkpWorldObject` — `.?AVhkpWorldObject@@`
- `class hkpWorldMaintenanceMgr` / `class hkpDefaultWorldMaintenanceMgr` — `.?AVhkpWorldMaintenanceMgr@@`, `.?AVhkpDefaultWorldMaintenanceMgr@@`
- `class hkpWorldRayCaster` / `class hkpWorldLinearCaster` / `class hkpSimpleWorldRayCaster` — `.?AVhkpWorldRayCaster@@`, `.?AVhkpWorldLinearCaster@@`, `.?AVhkpSimpleWorldRayCaster@@`
- `class hkpWorldDeletionListener` — `.?AVhkpWorldDeletionListener@@`
- `class hkpConvexPieceStreamData` — `.?AVhkpConvexPieceStreamData@@` (matches the `.rdata` symbol `convexPieceStream`)
- Stream reader/writer classes: `hkStreamReader`, `hkStreamWriter`, `hkBufferedStreamReader`, `hkBufferedStreamWriter`, `hkMemoryStreamReader`, `hkSeekableStreamReader`, `hkSubStreamWriter`, `hkArrayStreamWriter`, etc. (all `.?AVhk*Stream*@@`).

The engine's own world/streaming types (`PgSysPopulation`, `StreamingManager`, `PgTerrainMesh`, `PgLowResTerrain`, `PgLineRegion`, `PgWater*`) are present as symbols/strings but **not** as RTTI class descriptors in the recovered list.

## Symbols by area

Offsets and sections are copy-exact from `output/jul08_prototype/inventory/world-streaming.txt`.

### Streaming & load orchestration

| Offset | Section | Symbol |
|---|---|---|
| 0x0020cec | .rdata | StreamManagerUpdate |
| 0x0020d00 | .rdata | StreamPostload |
| 0x0020d10 | .rdata | StreamPreload |
| 0x002f0d4 | .rdata | UpdateStreamBlocks |
| 0x002bba0 | .rdata | CloseStreamFile |
| 0x002bbb0 | .rdata | OpenStreamFile |
| 0x002bda4 | .rdata | SetStreamBlockDumping |
| 0x002c81c | .rdata | IsLoadingOrStreaming |
| 0x00c5a14 | .rdata | StreamingManager |
| 0x0013658 | .rdata | StreamingWaiting |
| 0x00180f0 | .rdata | LoadLevel |
| 0x002a920 | .rdata | LoadAsset |
| 0x002a950 | .rdata | LoadLayer |
| 0x002a9cc | .rdata | LoadingStaticLayers |
| 0x0024c80 | .rdata | LoadSingleton |
| 0x0024c90 | .rdata | LoadGame |
| 0x002a620 | .rdata | LoadIsRetry |
| 0x0020ff0 | .rdata | SysWorldJob |
| 0x0020ffc | .rdata | UpdateWorldDb |
| 0x00243c8 | .rdata | UpdateWorldview |
| 0x0024804 | .rdata | LivingWorldObject |

A `StreamingManager`/`StreamManagerUpdate` drives a pre-load → post-load pipeline (`StreamPreload`/`StreamPostload`) over stream blocks (`UpdateStreamBlocks`, `SetStreamBlockDumping`, `OpenStreamFile`/`CloseStreamFile`). `IsLoadingOrStreaming` and `StreamingWaiting` look like state queries used to gate gameplay while content is in flight. `LoadLevel`/`LoadLayer`/`LoadAsset`/`LoadingStaticLayers` are the level/layer-granularity load entry points; `LoadIsRetry` points to retry handling on a failed load. `SysWorldJob`/`UpdateWorldDb` are the per-frame world-system update hooks.

### Terrain — shaders, content, queries

Terrain mesh shader family (vertex/fragment programs, LOD/feature-permuted `1D`–`4D`, `_pl`/`_sl` variants), each with a `.sho` compiled-shader companion:

| Offset | Section | Symbol |
|---|---|---|
| 0x0021d0c | .rdata | TerrainMesh |
| 0x0016c70 | .rdata | PgTerrainMeshFP4D |
| 0x0016d38 | .rdata | PgTerrainMeshFP3D |
| 0x0016e00 | .rdata | PgTerrainMeshFP2D |
| 0x0016ec8 | .rdata | PgTerrainMeshFP1D |
| 0x0016f80 | .rdata | PgTerrainMeshFP |
| 0x0016fa4 | .rdata | PgTerrainMeshVP4D |
| 0x0017054 | .rdata | PgTerrainMeshVP |
| 0x0016bc4 | .rdata | LowResTerrain |
| 0x0016b0c | .rdata | PgLowResTerrainVP |
| 0x0b8a45c | .data | PgTerrainMesh |
| 0x0b8a46c | .data | PgLowResTerrain |

(The full inventory lists every permutation `PgTerrainMeshFP{,1D,2D,3D,4D}{,_pl,_sl,_pl_sl}` and matching `VP` variants at 0x0016bd4–0x0017064; the table above is representative.)

Terrain content objects, height queries, and key/asset mappings:

| Offset | Section | Symbol |
|---|---|---|
| 0x00317a0 | .rdata | TerrainObject |
| 0x00317c8 | .rdata | LowResTerrainObject |
| 0x00317b0 | .rdata | TerrainFade |
| 0x004109c | .rdata | TerrainObject::CanActivate |
| 0x00410b8 | .rdata | TerrainObject::Deactivate |
| 0x00410d4 | .rdata | TerrainObject::Activate |
| 0x0017134 | .rdata | GetTerrainHeight_Slow |
| 0x001714c | .rdata | GetTerrainHeight_Fast |
| 0x0029ab4 | .rdata | GetHeightAboveTerrain |
| 0x00213ec | .rdata | ProcessTerrainCast |
| 0x003f864 | .rdata | HighResTerrainPatchObjectID |
| 0x003f880 | .rdata | LowResTerrainAsset |
| 0x0031d18 | .rdata | TerrainGuidMappingHighResToLowRes |
| 0x00315b0 | .rdata | TerrainKey |
| 0x003e14c | .rdata | UseTerrainLayer |

`TerrainObject::Activate`/`Deactivate`/`CanActivate` indicate terrain patches stream/activate as discrete objects. `TerrainGuidMappingHighResToLowRes` + `HighResTerrainPatchObjectID` + `LowResTerrainAsset` point to a two-tier (high-res near / low-res far) terrain LOD with a GUID mapping between tiers.

Terrain key/material categories (from strings, `TerrainKeyEnum` at 0x003a1b0):

```
Terrain_rock  Terrain_dirt  Terrain_grass  Terrain_sand  Terrain_asphalt
```

### Population & spawning

`PgSysPopulation` and methods (strings):

```
PgSysPopulation::UpdateSimpleSpawners
PgSysPopulation::CacheOut
PgSysPopulation::CacheIn
PgSysPopulation::DeathCompute
PgSysPopulation::DeathCheck
```

| Offset | Section | Symbol |
|---|---|---|
| 0x0020618 | .rdata | PgSysPopulation::UpdateSimpleSpawners |
| 0x0032520 | .rdata | PopulationSimpleSpawner |
| 0x003d110 | .rdata | TrafficSpawner |
| 0x003d120 | .rdata | WindowSpawner |
| 0x001eb48 | .rdata | HardpointSpawners |
| 0x001eb5c | .rdata | PathSpawners |
| 0x001eb6c | .rdata | NoModelSpawners |
| 0x001eb7c | .rdata | WindowSpawners |
| 0x001ecf0 | .rdata | OccupiedBuildingSpawnCallback |
| 0x0020640 | .rdata | GetSpawnableList |
| 0x0020758 | .rdata | QueuedSpawning |
| 0x00207d4 | .rdata | AdjacentSpawning |
| 0x00207e8 | .rdata | DeferredSpawning |
| 0x0020574 | .rdata | SpawningUnits |
| 0x0020584 | .rdata | SpawnUnitInstantiate |
| 0x002a470 | .rdata | StartHeliWaveSpawner |
| 0x002a45c | .rdata | StopHeliWaveSpawner |
| 0x0c4d6b0 | .data | SpawnerState |

Spawn-list management and faction/skirmish lists:

| Offset | Section | Symbol |
|---|---|---|
| 0x0024f58 | .rdata | ResetAllSpawnLists |
| 0x0024f6c | .rdata | ClearSpawnListChanges |
| 0x0024f84 | .rdata | SetSpawnList |
| 0x0024fac | .rdata | GetSpawnList |
| 0x0024f94 | .rdata | GetSpawnListChangeInfo |
| 0x003e774 | .rdata | VZSpawnList |
| 0x003e780 | .rdata | PirSpawnList |
| 0x003e790 | .rdata | OilSpawnList |
| 0x003e7a0 | .rdata | GurSpawnList |
| 0x003e7b0 | .rdata | ChiSpawnList |
| 0x003e7c0 | .rdata | AliSpawnList |
| 0x003f4b8 | .rdata | PedSpawnList |
| 0x00313c8 | .rdata | SkirmishSpawnList |
| 0x0c4d530 | .data | SpawnList |
| 0x0c4d570 | .data | SpawnWeighting |

The faction abbreviations (`VZ`, `Pir`, `Oil`, `Gur`, `Chi`, `Ali`, `Ped`) match Mercenaries 2 factions (Venezuela/Pirates/Oil/Guerrillas/Chinese/Allies/Pedestrians). `CacheIn`/`CacheOut` (`CacheInLump`/`CacheOutLump` in strings) are the population's stream-in/stream-out of spawned actors. Spawner reflection enums (`.rdata`): `SimpleSpawnerTypeEnum` (0x003ae60), `SimpleSpawnerStateEnum` (0x003ae90), `SimpleSpawnerGroupEnum` (0x003aee4), `SpawnerRadiusTypeEnum` (0x003ad6c), `SpawnerWeightTypeEnum` (0x003adb4), `SpawnAlignEnum` (0x0039fb0).

Generic spawn helpers (also touch combat/ordnance — overlap with weapons): `SpawnObject` (0x0024cc8), `SpawnWithModel` (0x0028bf8), `SpawnPlayer`/`SpawnPlayerAdvanced` (0x002a780/0x002a76c), `SpawnFromCamera` (0x002a8e0), `SpawnRelative` (0x002a8f0), `SpawnOnDeath` (0x00218f4), `GetDistantSpawnPointOnPath` (0x002a604), `CheckSpawnPos` (0x002b608), `OkForSpawn`/`OkForSpawn2` (0x00205e8/0x00205dc).

### Hibernation & object lifetime

| Offset | Section | Symbol |
|---|---|---|
| 0x003136c | .rdata | HibernationControl |
| 0x002d70c | .rdata | ObjectHibernation |
| 0x001ffec | .rdata | Del::Hibernate |
| 0x0029d70 | .rdata | IsHibernated |
| 0x0029d40 | .rdata | SetHibernationDistance |
| 0x0029d58 | .rdata | GetHibernationDistance |
| 0x0029d24 | .rdata | RevertHibernationDistance |
| 0x003efb8 | .rdata | NoDelOnHibernateIfPreplaced |

`HibernationControl` is also a registered ECS component (string `HibernationControl 14080`, a class-size registration row). Objects beyond a per-object **hibernation distance** are cached out; `NoDelOnHibernateIfPreplaced` exempts pre-placed objects from deletion. See the explicit warning string in **Notable strings**.

### Regions & line/zone geometry

| Offset | Section | Symbol |
|---|---|---|
| 0x0b8a420 | .data | PgLineRegion |
| 0x00314a8 | .rdata | SphereRegion |
| 0x0031518 | .rdata | CircleRegion |
| 0x0031528 | .rdata | LineRegion |
| 0x0028c24 | .rdata | CreateRegion |
| 0x0026da0 | .rdata | GetLineRegion |
| 0x0026db0 | .rdata | GetLineRegionSetting |
| 0x0026dc8 | .rdata | ChangeLineRegionSetting |
| 0x002a708 | .rdata | GetLineRegionPoints |
| 0x0011b4c | .rdata | ShowCurrentRegion |
| 0x0031908 | .rdata | RuntimeMusicRegion |
| 0x002bf08 | .rdata | ActivateFactionRegionMusic |
| 0x002bf34 | .rdata | SetRootFactionRegionMusic |

Regions are spatial triggers (sphere/circle/line). `SphereRegion`, `CircleRegion`, `LineRegion`, `RuntimeMusicRegion`, `SkirmishSpawnList` all appear in the ECS component registry list (strings 5467/5473/5474/5536/5454), so these are entity components placed in the world. Faction/music region symbols wire regions to the music system (cross-ref: audio).

### Water / ocean

| Offset | Section | Symbol |
|---|---|---|
| 0x0014c10 | .rdata | Water::Begin |
| 0x0014a70 | .rdata | Water::BeginFrame |
| 0x00016d8 | .rdata | WaterAction |
| 0x0013a60 | .rdata | WaterSplash |
| 0x0015544 | .rdata | WaterGradiant |
| 0x0015ec3 | .rdata | OWater::LOD |
| 0x0015fd0 | .rdata | WakeWorldUV |
| 0x00160c4 | .rdata | WaterClip |
| 0x00160d8 | .rdata | WaterHeightMap |
| 0x00160f4 | .rdata | WaterHeight |
| 0x00161f4 | .rdata | WaterReflection |
| 0x00217f0 | .rdata | UpdateRay::CheckWater |
| 0x003cbd4 | .rdata | ShowOnlyInWater |

Water shaders (`PgWater*` family, each with `.sho`): `PgWaterFP`/`PgWaterVP`/`PgWaterVPOcc` (0x0016158/0x0016198/0x0016174), `PgWaterHeightMapFP`/`...VP` (0x0015ff8/0x0016024), `PgWaterWakeFP`/`...VP` (0x001607c/0x00160a0). Water physics tunables (buoyancy/drag, `.rdata`): `OutOfWaterGravityFactorDown` (0x0002584), `OutOfWaterGravityFactorUp` (0x003d65c), `WaterDragUp` (0x003d684), `WaterDragFwd` (0x003d690), `WaterDragSide` (0x003d6a0).

### Props & destructibles

| Offset | Section | Symbol |
|---|---|---|
| 0x0040298 | .rdata | PropPhysics |
| 0x004106c | .rdata | PropPhysics::Deactivate |
| 0x0041084 | .rdata | PropPhysics::Activate |
| 0x003a9b4 | .rdata | PropGeneric |
| 0x003aa7c | .rdata | PropFragile |
| 0x0031550 | .rdata | BuildingDestruction |
| 0x0032298 | .rdata | DestructionLink |
| 0x003b36c | .rdata | DestructionLinkTypeEnum |
| 0x003f5b0 | .rdata | DestructionDelay |
| 0x003f5c4 | .rdata | DestructionRadius |

Prop material classes (`Prop*`, `.rdata`): `PropRock`, `PropBrickPlaster`, `PropBrick`, `PropGlass`, `PropCocrete` [sic], `PropWood`, `PropMetal` (0x003aab4–0x003ab0c). A large `prop_*` asset-name table (0x003a65c–0x003a82c) enumerates destructible prop assets, e.g. `prop_wood_crate`, `prop_tree_lrg`, `prop_stone_med`, `prop_sheetmetal_lrg`, `prop_sandbag`, `prop_barreldrum`, `prop_metal_chainlinkfence`, `prop_foliage_med`, `prop_fabric_lrg`. `PropPhysics::Activate`/`Deactivate` mirror `TerrainObject::Activate`/`Deactivate` — props stream their physics on/off with proximity (inferred).

### Reflection class-size registrations (strings)

These rows in the strings file are reflection/ECS class registrations with byte sizes (`<Name> <size> [<align>]`), confirming these as live engine classes:

```
HibernationControl 14080
PopulationSimpleSpawner 768
_PropPhysics 768
BuildingDestruction 32 32
SkirmishSpawnList 16 16
CircleRegion 8 8
LineRegion 512 128
SphereRegion 32 32
RuntimeMusicRegion 64 64
```

## Notable strings

Confirmed in `mercs2_xenon_p.pe_full_strings.txt`:

- **Hibernation warning (format string):** `Hibernation distance of %.2f on Guid 0x%x > 400, may fall through terrain` — implies a hard 400-unit caution threshold where a hibernated object may de-collide with terrain.
- **Sound-stream HUD line (NOT world content):** `StreamBlocks: %d, Max: %d, Avg: %d` and `Block (%x)- Ready (%d), Failed (%d), RefCount (%d)` — these are emitted near `PgSoundStreamIO.cpp` / `UpdateStreamBlocks` in the audio stats block; do not attribute to world-content streaming.
- **WAD / load filenames:** `d:\vz.wad`, `%sshell.wad`, `%sloading.wad`, `audios\ambience.pws` — the world/shell/loading content archives.
- **Population update labels (debug/profile markers):** `UpdateSimpleSpawners`, `CacheOut`, `CacheIn`, `DeathCompute`, `DeathCheck`, `CacheRequired`, `CacheOutLump`, `CacheInLump`, `DensityUpdate`, `KeptPopulation`, `QueuedSpawning`, `AdjacentSpawning`, `DeferredSpawning`, `New LaneCheck`, `PlayerPopulation`, `ForceFade`.
- **Population/lane debug formats:** `P: %d/%d, V: %d/%d O: %d`, `ActiveCt: %d`, `Player %d in lane %d of 0x%08x Speed: %4.2f (%4.2f along road)`.
- **Debug-menu toggles** (region/spawner/terrain): `ShowCurrentRegion`, `Tog ShowCurrentRegion`, `RenderSpawnPoints`, `NoSidewalkSpawn`, `NoRoadSpawn`, `ClearSpawnerDebug`, `DebugTargetSpawner`, `ShowObjectSpawners`, `Toggle LowResTerrain`, `Freeze Hibernation`, `ShowSkirmishZones`, `ShowSkirmishLines`.
- **AI hibernation markers:** `AI Hibernated . . .`, `Hibernation`, `Freeze Hibernation`.
- **Terrain key categories:** `Terrain_rock`, `Terrain_dirt`, `Terrain_grass`, `Terrain_sand`, `Terrain_asphalt`.
- **Terrain/object key tail (post-warning cluster):** `lowresterrain`, `debris`, `ragdoll`, `winch`, `usable`.
- **Water tunables:** `OutOfWaterGravityFactorDown`, `OutOfWaterGravityFactorUp`, `WaterDragUp`, `WaterDragFwd`, `WaterDragSide`, `WaterGradiant`, `WaterClip`, `OWater::LOD`, `WakeWorldUV`.
- **Faction spawn lists:** `VZSpawnList`, `PirSpawnList`, `OilSpawnList`, `GurSpawnList`, `ChiSpawnList`, `AliSpawnList`, `PedSpawnList`, `SkirmishSpawnList`.

## Cross-references

- `docs/mercs2-pdb-analysis/havok-physics.md` — `hkpWorld`, `hkpWorldObject`, stream-IO and convex-piece-stream classes that the world streamer feeds.
- `docs/mercs2-pdb-analysis/audio-pal.md` — `PgSoundStreamIO.cpp`, `UpdateStreamBlocks`, `LoadBank`/`LoadWaveBank`/`LoadTempBank`, and `ActivateFactionRegionMusic`/`RuntimeMusicRegion` (regions drive music).
- `docs/mercs2-pdb-analysis/rendering-shaders.md` — `PgTerrainMesh*`/`PgWater*`/`PgLowResTerrain*` `.sho` shader programs.
- `docs/mercs2-pdb-analysis/game-systems.md` — `PgGameSystem.cpp`, `SysWorldJob`, `PgSysPopulation` (the `PgSys*` game-system host).
- `docs/mercs2-pdb-analysis/weapons-combat.md` — overlapping `Spawn*` ordnance helpers (`SpawnOrdnance`, `SpawnCarpetBombLine`, `SpawnHomingProjectile`).
- `docs/mercs2-pdb-analysis/vehicles.md` — `WaterDrag*`/`OutOfWaterGravity*` buoyancy used by boats; `StartHeliWaveSpawner`.

Existing project docs that overlap (recovered/runtime side):
- `docs/mercs2-ecs/` — native ECS component registry; `TerrainObject`, `TerrainFade`, `LowResTerrainObject`, `BuildingDestruction`, `HibernationControl`, `SphereRegion`/`CircleRegion`/`LineRegion`, `RuntimeMusicRegion`, `SkirmishSpawnList` appear here as components.
- Project memory notes on world-load streaming (the `vz.wad` load path, terrain-mesh/PRMG handling, streaming livelock) — same `d:\vz.wad` archive named in these strings.

## PC decompilation cross-reference

This section maps this subsystem's Xbox symbols/strings to functions in the PC retail decompilation (`output/_ghidra/all_functions_decomp.txt`). The resolver (`output/jul08_prototype/pairing/resolved_world-streaming.txt`) found **no vtable-bridge matches** for world-streaming (the engine's `Pg*` world types are not RTTI-described in either build, consistent with the "Key classes" note above), so every match below is **string-anchored** and was confirmed by reading the cited function body. Confidence: a function that emits exactly one distinctive symbol string in a recognizable role = medium; a generic property-table reader hit by many fields = low.

| Symbol / class | PC function | Bridge | Role |
|---|---|---|---|
| `PgTerrainMesh*` / `PgLowResTerrain*` / `PgWater*` (all shader names) | `FUN_0084f130` | string | Shader registry — registers every `Pg*` shader/`.sho` pair |
| `PgWaterFP` / `PgWaterWake*` / `PgWaterHeightMap*` | `FUN_00484380` | string | Water-shader sub-registrar (called by `FUN_0084f130`) |
| `HibernationControl` | `FUN_00640a40` | string | ECS component reflection-descriptor setup |
| `BuildingDestruction` | `FUN_00642590` | string | ECS component reflection-descriptor setup |
| `SphereRegion` | `FUN_00641e10` | string | ECS component reflection-descriptor setup |
| `SkirmishSpawnList` | `FUN_00641270` | string | ECS component reflection-descriptor setup |
| `RuntimeMusicRegion` | `FUN_00644fe0` | string | ECS component reflection-descriptor setup |
| `TerrainObject` / `LowResTerrainObject` / `TerrainFade` | `FUN_00644260` / `FUN_00644470` / `FUN_00644300` | string | ECS component reflection-descriptor setup |
| `CircleRegion` / `LineRegion` | `FUN_00642220` / `FUN_006422d0` | string | ECS component reflection-descriptor setup |
| `PopulationSimpleSpawner` (`Simple*`/`Spawner*`/`SpawnAlign` enums) | `FUN_0064ac50` | string | Reflection enum/value registrar (references many spawner-enum names) |
| `LivingWorldObject` | `FUN_00598570` | string | Object setup (registers two child sub-objects sized 0x70/0x74) |
| `LthkpWorld::getClosestPoints` | `FUN_008db880` | string | Havok world closest-points query (profiler-scoped) |
| `LthkpWorld::getPenetrations` | `FUN_008dba60` | string | Havok world penetration query |
| `hasStreamingAudio` / `hasStreamingVideo` | `FUN_0079cdc0` | string | Generic reflection property-table reader (low confidence — broad field reader) |

### Annotated excerpts

**`FUN_0084f130` — the shader registry (medium-high).** Confirmed: this single function references 41 of this system's terrain/water/low-res shader strings and registers each as a `name → .sho` pair. It is the shader loader the task brief warns about (references *every* shader name, so it is the registry, not a per-shader method):

```c
FUN_0085ac90(s_PgMeshVP_00be3510,        s_PgMeshVP_sho_00be3500, 0);
FUN_0085ac90(s_PgSkin1VP_00be3880,       s_PgLtiSkin1VP_sho_00be386c, 0);
...                                       // terrain/water Pg* names follow
if ((*(uint *)(DAT_01176288 + 0x5e4) >> 2 & 1) == 0) { pcVar3 = s_PgMeshVP_sho_00be3500; }
else                                                  { pcVar3 = s_PgMeshVPAmbientWind_sho_...; }
FUN_0085ac90(s_PgMeshAmbientWindVP_00be3734, pcVar3, 0);
```

The `DAT_01176288+0x5e4` bit tests pick alternate `.sho` blobs per platform/feature flag — the same FP/VP × `_pl`/`_sl` permutation logic the Xbox symbol table enumerates. `FUN_00484380` (the water sub-registrar) is called from inside it, matching the `PgWater*` cluster.

**`FUN_00640a40` — ECS reflection descriptor for `HibernationControl` (medium).** All the `Region`/`Terrain`/spawner component descriptors share this exact shape; the tell is the trailing store of the component name string and the well-known reflection hash seed `0x9e3779b9` (golden-ratio constant):

```c
DAT_017bd1a4 = 0x9e3779b9;                         // reflection name-hash seed
DAT_017bd178 = &PTR_CopyFromStream_00bbf430;       // stream-deserialize vtable
_DAT_017bd190 = &PTR_FUN_00bc5ff8;
FUN_0064a770();
_DAT_017bd1b4 = s_HibernationControl_00bc4fcc;      // <-- names this component
```

`FUN_00642590` (BuildingDestruction), `FUN_00641e10` (SphereRegion), `FUN_00644fe0` (RuntimeMusicRegion) etc. are byte-for-byte the same template with a different name string and `CopyFromStream` pointer — i.e. these are the PC-side definitions of the ECS components the doc lists under "Reflection class-size registrations". The `&PTR_CopyFromStream_*` confirms each component is stream-deserialized, tying these descriptors directly to the world-streaming load path.

**`FUN_008db880` — `LthkpWorld::getClosestPoints` (medium).** Opens a TLS profiler scope tagged with the literal symbol string, then runs the Havok broad-phase query — the world-streamer's collision-query entry into the physics world:

```c
*puVar1    = s_LthkpWorld__getClosestPoints_00b59178;   // profiler scope label
puVar1[3]  = s_Stbroadphase_00b59080;                   // broad-phase stage tag
```

## Evidence & confidence

- **Symbol count / sections:** `output/jul08_prototype/inventory/world-streaming.txt` lists 332 lines; the vast majority are `.rdata` (exported reflection names, shader names, debug strings, method names), with a handful of `.data` singletons (`PgLineRegion` 0x0b8a420, `PgTerrainMesh` 0x0b8a45c, `PgLowResTerrain` 0x0b8a46c, `SpawnList` 0x0c4d530, `SpawnWeighting` 0x0c4d570, `SpawnerState` 0x0c4d6b0).
- **Verified evidence:** All symbol names, offsets, and section tags cited above are copy-exact from the inventory; the assert/format/tunable strings (`Hibernation distance ... may fall through terrain`, `StreamBlocks: %d...`, `d:\vz.wad`, faction spawn lists, water tunables, terrain keys, debug toggles, `PgSysPopulation::*`, the reflection class-size rows) are present in `mercs2_xenon_p.pe_full_strings.txt`. The one source path (`...\pangea\Src\PgGameSystem.cpp`) and the Havok world/stream RTTI classes are verbatim from their respective evidence files.
- **Inferences drawn from names:** the two-tier high/low-res terrain LOD design from `TerrainGuidMappingHighResToLowRes`+`HighResTerrainPatchObjectID`+`LowResTerrainAsset`; the pre-load→post-load streaming pipeline ordering; faction abbreviation expansions; that `IsLoadingOrStreaming`/`StreamingWaiting` gate gameplay; that props/terrain stream physics on/off by proximity via `Activate`/`Deactivate`; the 400-unit hibernation caution being a hard limit. None of these have a dedicated `.cpp` assert path in the recovered source-path table, so the precise file ownership beyond `PgGameSystem.cpp` is unclear from symbols alone.
- **Caution:** the recovered `StreamBlocks`/`UpdateStreamBlocks` HUD strings are **sound-stream** stats (`PgSoundStreamIO.cpp`), distinct from world-content streaming despite the similar `Stream*` naming; do not conflate.
