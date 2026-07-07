# Road graph + AI driving — PC code map

**Scope:** the runtime road/intersection graph and the AI vehicle-driving layer that walks it —
the "additional edges near roads/intersections/traffic" adjacent to the vehicle system. Covers
(a) the road/lane/intersection reflection components, (b) the runtime graph **rebuilder** that
turns those pools into an index + adjacency table, and (c) the AI driving states that produce
into the vehicle command rings. Scoreboard row 23 (AI driving) / touches row 24
([`population_spawner_code_map.md`](population_spawner_code_map.md)). Companion JSON
[`road_graph_ai_driving_code_map.json`](../data/road_graph_ai_driving_code_map.json).

**Binary:** unpacked SecuROM image `output/_ghidra/securom_dump/mercs2_unpacked.exe`, base
`0x400000`; bodies from `output/_ghidra/mercs2_unpacked.exe_decomp.txt`. Xbox oracle:
[`vehicles.md`](../mercs2-pdb-analysis/vehicles.md) §"AI driving states",
[`ai.md`](../mercs2-pdb-analysis/ai.md), [`06_world_terrain_roads_streaming.md`](../mercs2-ecs/06_world_terrain_roads_streaming.md).

## 0. Boundary

The **reflection loaders** (deserialize road/lane/intersection component blocks) and the
**runtime graph rebuilder** (`FUN_004fd9f0`) are statically recovered = high/med. The AI
driving-state → command-ring producer cluster is located by call-shape (med). The lane-enum
member semantics, the graph-rebuild **cadence** (per-frame vs region-event), and the exact
road-following steering math are **confirm-live / next-pass** gaps.

## 1. Correction to `06_world_terrain_roads_streaming.md`

That doc labels `FUN_0063d4b0` the RoadIntersection **"consumer."** It is not — it is the
RoadIntersection **`CopyFromStream` loader** (deserialization). Body:

```c
undefined4 FUN_0063d4b0(undefined4 param_1,int *param_2) {
  undefined1 local_88 [132];
  (**(code **)(*param_2 + 0x14))(local_88,0x7c,0);   // read 0x7c bytes via stream vtable
  iVar1 = DAT_017be9f4;
  FUN_0064a600(param_1,&stack0xffffff6c);             // pool-commit (same helper physics uses)
  if ((iVar1 != DAT_017be9f4) && ...) FUN_00665590(...);
  return 1;
}
```

It is registered in the big reflection-registry dispatcher `FUN_0064ee60` right next to the
descriptor registrar `FUN_006602c0` (RoadIntersection), `FUN_006606b0` (LaneData), `FUN_00660620`
(LaneZeroDirection), `FUN_00660580` (IntersectionToIntersection) — a `{loader; registrar; size}`
triple per component. So `FUN_0063d4b0` is the deserialization path; the **runtime** graph
consumer is §2.

## 2. Runtime road/intersection graph — `FUN_004fd9f0`

`FUN_004fd9f0` (1818 B, sole caller `0x004b9ad7`) **rebuilds the drivable road graph** from the
Road + RoadIntersection component pools into a runtime graph object (`param_1`). Body structure
(verified, unpacked lines 129049+):

1. `QueryPerformanceCounter` timing bracket; zero the graph's road/intersection counts
   (`param_1+0x13890`, `+0x13894`).
2. **Road index rebuild:** `memset(DAT_017c03ac, -1, DAT_017c0398*4)` (clear road-index hash),
   bump generation `_DAT_017c03c0`. Iterate the **Road component pool** `PTR_PTR_017bd910`; per
   live element (`>0 && !(bit30)`): key `0xbcfe6314`,
   `EnterCriticalSection(&DAT_01174ffc)` → `FUN_00874150(&key)` hash-insert →
   `LeaveCriticalSection`. On insert, append a **0x14-byte (20-B) road-graph record** at
   `param_1+0x10 + count*0x14` = {road handle, two payload dwords copied from component +8/+0xc,
   ROUND(float @component+0x38) ×2 (position/weight)}, then `FUN_00532de0(handle)` per element,
   bump count.
3. **Intersection index rebuild:** `memset(DAT_017c03fc, -1, DAT_017c03e8*4)`, bump generation
   `_DAT_017c0410`, iterate the **RoadIntersection pool** `PTR_PTR_017be9f0` the same way.
4. **Adjacency:** `FUN_004fe750` (816 B, called at `0x004fe0ee`) builds the intersection→road
   adjacency / edge table.

**Runtime globals:** road pool `PTR_PTR_017bd910`; intersection pool `PTR_PTR_017be9f0`; road
index table `DAT_017c03ac` (size `DAT_017c0398`) + gen `_DAT_017c03c0`; intersection index table
`DAT_017c03fc` (size `DAT_017c03e8`) + gen `_DAT_017c0410`; per-element insert lock
`DAT_01174ffc`; hash-insert `FUN_00874150`.

> **Cadence is UNPROVEN.** The sole caller `0x004b9ad7` sits in an unattributed code gap; prior
> corpus analysis ([`engine_optimization_function_reference.md`](../engine_optimization_function_reference.md)
> §3a) flagged this as the single biggest per-frame optimization candidate *if* it runs every
> frame — but roads are static map geometry, so a per-frame full rebuild would be pure waste.
> **Confirm-live:** counter/bp on `0x004fd9f0` to settle per-frame vs streaming/region-event. The
> function also has tail side-effects (`FUN_00532de0` per element, `FUN_0064a600`/`FUN_00665590`,
> `FUN_004fe750`), so any "skip the rebuild" patch must gate only the two rebuild loops.

## 3. Road/lane/intersection reflection components (deserialization)

From [`06_world_terrain_roads_streaming.md`](../mercs2-ecs/06_world_terrain_roads_streaming.md),
placed here for the graph picture:

| Component | descriptor registrar | loader | stride | fields |
|---|---|---|---|---|
| Road | (in `FUN_0064ee60`) | — | 44 | segment record (2,441 entities); pool cap `Road 4608` |
| RoadIntersection | `FUN_006602c0` | **`FUN_0063d4b0`** | 0x7c (124) | 7 INT (ids/counts) + 6 VEC3 (approach/corner world pos) + 6 INT (per-approach links); 883 entities; pool `RoadIntersection 2304` |
| LaneData | `FUN_006606b0` | — | 0x40 (64) | ×4 lanes: {`LaneTypeEnum`, `LaneOffsetEnum`, float, float} |
| LaneZeroDirection | `FUN_00660620` | — | — | `LaneDirectionEnum` (orients segment) |
| IntersectionToIntersection | `FUN_00660580` | — | — | 2 INT (graph edge between intersection indices) |

`SysPath*Index` tables are the edge/index tables the graph walks. **Open:** the enum member
values (`LaneTypeEnum`/`LaneOffsetEnum`/`LaneDirectionEnum`) + speed limits are not decoded —
the [`gameplay_data_ue5_mapping.md`](../gameplay_data_ue5_mapping.md) §6 gaps. The enum
registrars sit near `FUN_00660xxx` (same shape as the vehicle enum registrars in
[`vehicle_code_map.md`](vehicle_code_map.md) §2 — `FUN_00656720(enum,member)` member-add).

## 4. AI driving states → command rings

**Xbox side:** the AI driving/combat state names (`CarStop`/`CarDriveRoads`/`CarMove`/`CarPursue`,
`TankMove`/`TankDriveRoads`, `HeliMove`/`HeliDeliver`/…, `BoatMove`/…, `TurretIdle`/…) are
registered into a global AI-state registry `@837e9bf8` by a single bulk registrar (Xbox
`FUN_823b76e0`, ~58 calls to `FUN_823f9250(registry, name)`).

**PC side:** the AI driving-state **producers** are the `0x544xxx–0x561xxx` cluster — e.g.
`FUN_00544a70` (534 B) emits `FUN_0056b590`/`FUN_00547d50`/`FUN_0056b630`/`FUN_0056b5c0` verb
combos (with an LCG dither `DAT_00DFCBAC*0x19660D+0x3C6EF35F`), reading the vehicle quaternion
(`+0x290`) and velocity (`+0x37C`), returning small state codes 1–4. Composite driver
`FUN_00546ce0` (`FUN_005445b0` ×4, `FUN_005446d0` ×3, `FUN_0056b390`, `FUN_0056b670` ×2). These
are the classic per-state AI-machine steps that **feed the vehicle command rings** documented in
[`vehicle_code_map.md`](vehicle_code_map.md) §1 — i.e. AI drives a car by enqueuing the same
`0x3483DBF1`/accel/brake commands a human would.

`CarDriveRoads`/`TankDriveRoads` are the road-following states; binding a specific PC fn in the
cluster to `CarDriveRoads` (and confirming it queries the §2 graph — nearest-road / lane-follow
→ steering command) is the **confirm-live** step (bp the cluster, correlate with a road-graph
query on `PTR_PTR_017bd910` / `DAT_017c03ac`). The PC AI-state registrar twin (bulk ~58 two-arg
calls → registry global) was not pinned this pass.

## 5. Traffic / population spawner (adjacent)

Ambient traffic density is config-driven, already anchored in
[`population_spawner_code_map.md`](population_spawner_code_map.md) and prior corpus work:
`FUN_006420d0`/`FUN_0066f300` reference `PopulationDensity` / `PopulationFlow` /
`PopulationDynamicRoad` (road-traffic density); enums `TrafficControlEnum` / `RtSpeedLimit` /
`SpawnerRadiusTypeEnum`; civilians flagged `_vehcivilian` (vehicle) vs `_flagcivilian` (foot).
Per-entity `HibernationControl` gates spawn-in distance (see
[`world_streaming_spec.md`](../modernization/world_streaming_spec.md)). Traffic vehicles are
placed by the spawner along the road graph (§2), then driven by the AI states (§4). The
`VehicleSpawnList` / `VehiclesOnScreen` on-screen-cap consumers were not pinned on PC this pass.

## 6. Open questions & confirm-live

1. **Graph-rebuild cadence** — bp `0x004fd9f0`, count calls/sec vs region loads.
2. **`CarDriveRoads` / `TankDriveRoads` PC fns** — bp the `0x544xxx` cluster while an AI vehicle
   follows a road; correlate with a read of `PTR_PTR_017bd910` / `DAT_017c03ac`.
3. **PC AI-state registrar** (Xbox `FUN_823b76e0` twin) + registry global.
4. **Lane enum members + speed limits** — decode the `FUN_00660xxx` enum registrars.
5. **RoadIntersection 31-dword field semantics at runtime** — which dwords `FUN_004fd9f0` reads
   (+8/+0xc payload, +0x38 float confirmed; the 6 VEC3 approach positions + 6 link indices are
   read by `FUN_004fe750` adjacency — decode pass-2).
6. **`VehicleSpawnList` / `VehiclesOnScreen`** consumers + on-screen cap enforcement.

## 7. Provenance

- PC decomp `output/_ghidra/mercs2_unpacked.exe_decomp.txt`: `FUN_004fd9f0` @129049 (body read,
  road/intersection rebuild verified), `FUN_004fe750` @129397, `FUN_0063d4b0` (RoadIntersection
  loader) + registration in `FUN_0064ee60`.
- Xbox oracle: `vehicles.md` §"AI driving states" (`837e9bf8` registry, `FUN_823b76e0`), `ai.md`.
- Corpus corroboration: `engine_optimization_function_reference.md` §3a (`FUN_004fd9f0` road
  rebuild, per-element lock `DAT_01174ffc`, caller `0x4b9ad7`), `population_spawner_code_map.md`,
  `06_world_terrain_roads_streaming.md`, `gameplay_data_ue5_mapping.md` §6.
- Cadence, the specific road-following steppers, lane-enum semantics, and the AI-state registrar
  twin are the recorded confirm-live gaps.
