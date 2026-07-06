# World streaming / load-orchestration — Xbox↔PC code map

**Scope:** scoreboard row 8 (World streaming) — the *streaming/load-orchestration core* the sibling
maps deliberately left out: the per-frame streaming manager, its pre-/post-load pipeline, the
gameplay load-gate, terrain streaming + two-tier LOD, object hibernation, and the
props/regions proximity-activate surface. This marries the **Xbox 360 devkit (Jul-08 Profile
build)** symbol/PDB ground truth to the **PC retail decompilation** (`Mercenaries2.exe`, unpacked
image, base `0x00400000`).

This is the missing "PC code map" for row 8 — every other streaming-adjacent row (3–7, 13–15, 21,
27) already had one; population/spawners were split out into their own map. This doc covers the
**streaming spine**; the population half lives in
[`population_spawner_code_map.md`](population_spawner_code_map.md).

**Sources.** Xbox oracle: [`docs/mercs2-pdb-analysis/world-streaming.md`](../mercs2-pdb-analysis/world-streaming.md)
(symbol inventory) + `output/_ghidra_x360/xenon_decomp_named.c` (base `0x82000000`). PC: the 27k-fn
Ghidra decomp of the unpacked exe, plus the already-recovered PC-side maps
[`../engine_load_path_map.md`](../engine_load_path_map.md) (64 named streaming functions),
[`scheduler_tick_code_map.md`](scheduler_tick_code_map.md) (master tick), and
`scripts/mercs2_annotations.json`. Data layer: `docs/mercs2-ecs/`, `docs/game_config/cdbsizes.ini`,
`tools/wad_simulator/crates/mercs2_formats/src/placement.rs`. Companion memory:
[[world-streaming-spec]], [[engine-streaming-buffer-sizing-chain]], [[world-terrain-loader]],
[[world-placements-no-model-hash]].

**Method / honesty model.** Same as the population map: the PC retail build strips the Xbox
`Stream*`/`Terrain*` profiler strings and dispatches per-frame work through vtables, so the
**streaming spine is recovered on PC by call-tree shape + shared constants + role** and the Xbox
side is often *unlocated by name* (world-streaming.md already established that the Xbox orchestration
RVAs — `StreamManagerUpdate`, `LoadLevel`, `IsLoadingOrStreaming`… — are **not string-referenced** in
the Xbox decomp). Where the Xbox function body can't be pinned, the row says so. Confidence: **H**
structural fingerprint that can't coincide · **M** role+position match, one strong signal · **L**
positional/among-siblings only → confirm-live.

---

## 0. Result in one line

The PC **streaming spine is fully in the clear**: the per-frame manager (`FUN_00872d30`), its
evict→flush→tick→retry pipeline, the node lifecycle, the buffer-sizing chain, and the
gameplay load-gate predicate are all recovered and married to their Xbox symbols by role +
structure. The **global LOD-budget tier notify** (`FUN_0084ae70`) is the per-frame streaming
heartbeat, ticked from the master update before the layer stack. The Xbox *orchestration* function
bodies (`StreamManagerUpdate`/`LoadLevel`/`LoadLayer`) stay **unlocated by name** on Xbox — the
marriage is PC-anchored — while the terrain/hibernation/region **ECS descriptors** are married on
*both* builds.

---

## 0.5 Master marriage table (the whole system at a glance)

Per-cluster tables + evidence are in §2–§4. Confidence: **H** can't-coincide fingerprint · **M** one
strong structural signal · **L/open** positional / confirm-live. "Xbox" is the
`world-streaming.md` symbol; a bare `.rdata` offset means the Xbox *code* body is unlocated (name
string only) and the marriage is PC-anchored.

| Subsystem | Xbox symbol | PC addr | Conf |
|---|---|---|---|
| Per-frame LOD-budget notify | `StreamManagerUpdate` | `FUN_0084ae70` | M |
| Streaming manager update (evict→flush→tick→retry) | `StreamManagerUpdate` | `FUN_00872d30` | H |
| Completion/promote gate | `UpdateStreamBlocks`¹ | `FUN_008739e0` | H |
| Pre-/post-load blocking prime | `StreamPreload`/`StreamPostload` | `FUN_004bf8c0` (+ leaf `FUN_00875fd0`) | M |
| Busy predicate (gameplay gate) | `IsLoadingOrStreaming`/`StreamingWaiting` | `mgr+0x4c35c` | H |
| Streaming-manager object | `StreamingManager` | `PTR_DAT_01176630` | H |
| Node lifecycle + buffer chain | — | `FUN_00875760/…/00875b00` (load-path map) | H |
| Loading-screen / in-game pump | `SysWorldJob`/`UpdateWorldDb` | `FUN_004c9740` / `FUN_006b4a70` | H / M |
| HighRes→LowRes GUID map (runtime) | `TerrainGuidMappingHighResToLowRes` | `FUN_004a88a0` | H |
| Terrain patch Activate / Deactivate | `TerrainObject::Activate/Deactivate` | `FUN_0066cac0` / `FUN_0066d030` | M |
| Terrain descriptors + deserializers | `TerrainObject`/`LowResTerrainObject`/`TerrainFade`/`TerrainKey` | `FUN_00644260`/`FUN_00644470`/`FUN_00644300`/`FUN_00661750` (+ `FUN_0063d590`/`FUN_0063d6e0`) | H |
| Terrain height queries | `GetTerrainHeight_Fast/Slow`, `ProcessTerrainCast` | — (Havok sampled-heightfield) | open |
| HibernationControl descriptor (field-size 6) | `HibernationControl` | `FUN_00640a40` | H |
| `Object.{Set/Get/Is/Revert}Hibernation*` cfuncs | `SetHibernationDistance` etc. | `0x5CF4F0/0x5CF420/0x5CF240/0x5CF600` | H |
| Population hibernate-out gate | `DeathCheck`/`DeathCompute` | `FUN_00500b40`→`FUN_005007d0` | H |
| Region containment (PopulationDensity) | (PlayerPopulation select) | `FUN_004d60e0` | H |
| Prop / Debris physics descriptors | `_PropPhysics`/`_DebrisPhysics` | `FUN_0063e5d0` / `FUN_0063e680` | H |
| PropPhysics::Activate/Deactivate runtime | `PropPhysics::Activate/Deactivate` | `&PTR_FUN_00bc5ff8` vtable slot | L |
| Region / music-region descriptors + cfuncs | `SphereRegion`/`LineRegion`/`RuntimeMusicRegion`/`CreateRegion`/… | `FUN_00641e10`/`FUN_006422d0`/`FUN_00644fe0`/`0x5BFB00`/… | H |
| BuildingDestruction / DestructionLink | `BuildingDestruction`/`DestructionLink` | `FUN_00642590` / orchestrator `FUN_004cf340` | H / xref |

¹ Xbox `UpdateStreamBlocks`/`OpenStreamFile`/`SetStreamBlockDumping` are actually **audio** `.pws`
symbols (`PgSoundStreamIO.cpp`) — see §2.4; the world-content completion gate is `FUN_008739e0`,
married by role.

---

## 1. Where streaming sits in the frame (tick integration)

From [`scheduler_tick_code_map.md`](scheduler_tick_code_map.md), confirmed first-hand here:

```
FUN_00631670  WinMain  ─(each loop)→  FUN_00630ef0  RunFrame
  RunFrame:
    3. FUN_004c16e0  timestep compute → sim dt DAT_01175a90
    5. FUN_004c14f0  MASTER UPDATE
         ├─ fixed-sim accumulator (integer steps → DAT_011765cc, keep remainder)
         ├─ FUN_0084ae70   ← streaming LOD-BUDGET NOTIFY  (per-frame streaming heartbeat)  §2
         └─ FUN_004c15e0  5-layer app stack, ticked 0→4
                layer 4 Update(+0xc) → FUN_004c0ec0 Loader_Frame → FUN_004c9740
                     FUN_004c9740  = load pump AND layer-4 per-system call list
                          ├─ FUN_00872d30  Stream_Manager_Update   §2
                          └─ FUN_00502510  PgSysPopulation::Update  (see population map)
    6. render · 8. vsync · 9. present
```

**Reconciliation (the FUN_004c9740 dual role).** The load-path map calls `FUN_004c9740`
"LoadingScreen_FrameLoop"; the population/scheduler map calls the same 1448-byte function the
"layer-4 per-system call list." Both are correct and it is **one function**: it is the game-mode
layer's per-frame body, and it *both* pumps the streaming manager (`FUN_00872d30`) *and* walks the
fixed-order per-system list (population et al.). During `WAITFORSTREAMING` the gameplay systems are
gated off (the world-present flag `*(DAT_01175cdc+0x63)` / the streaming busy flag), so the same pump
runs "loading-screen" vs "in-game" without being two functions.

---

## 2. Streaming manager core (H — recovered first-hand)

### 2.1 Per-frame LOD-budget tier — `FUN_0084ae70` (the `StreamManagerUpdate` heartbeat)

Called **only** from the master update `FUN_004c14f0` @0x004c1527, so it runs once per master frame.
It is a memory-pressure-driven **global LOD tier** with hysteresis:

```c
iVar4 = DAT_017d50d4 (+ _DAT_00dfd138 if DAT_00ff4595);   // current mem/budget pressure
// climb tier 0→3 as pressure crosses PTR_FUN_00ce8de0 / PTR_DAT_00ce8ddc / DAT_00ce8dd8
// drop back a tier only past a +DAT_00ce8dd4 hysteresis band (and only every fixed-sim step)
if (DAT_011765c8 != newTier) {                            // tier changed
    _DAT_011765d0 = DAT_011765cc;                         // stamp step counter
    DAT_011765c8  = newTier;
    for (node in PTR_LOOP_00dfd140)  (*(node->vtbl+4))(oldStep, newTier);  // broadcast
}
```

- `DAT_011765c8` = the live global streaming-LOD tier (0..3); subscribers get `vtable+4(newTier)`.
- Gated on the fixed-sim step counter `DAT_011765cc` (so tier drops are rate-limited).
- This is the concrete engine analog of the world_streaming_spec's LOD tiers and the Xbox
  `StreamManagerUpdate` per-frame notion — a **global budget tier**, distinct from the per-entity
  `HibernationControl` distances (§4). **Married by role** (per-frame, from master update) to Xbox
  `StreamManagerUpdate`; the Xbox body is unlocated by name → **M**.

### 2.2 Pre-/post-load pipeline — `Stream_Manager_Update FUN_00872d30` (H)

The Xbox `StreamPreload → UpdateStreamBlocks → StreamPostload` ordering is literally this body
(read first-hand):

```c
void Stream_Manager_Update(mgr) {                         // ESI = mgr
    if (mgr[0x4c35d] == 0)  FUN_008738f0(mgr);            // PRELOAD: Stream_EvictCompleted
    if (mgr[0x4c36c]  > 0)  FUN_00872e60(mgr,0,1);        //          Stream_ForceFlush (backlog)
    FUN_008739e0(mgr);                                    // UpdateStreamBlocks: Stream_Manager_Tick
    FUN_00873cf0(mgr);                                    // POSTLOAD: Stream_RetryPromoteQueue
    // busy predicate ↓  (== IsLoadingOrStreaming / StreamingWaiting)
    if ((mgr[0x814] || mgr[0x824] || mgr[0x834]) && (!mgr[0x4c35a] || mgr[0x4c359]))
         mgr[0x4c35c] = 1;                                // streaming BUSY
    else mgr[0x4c35c] = 0;
}
```

| Xbox symbol | PC | Married by | Conf |
|---|---|---|---|
| `StreamManagerUpdate` (per-frame) | `FUN_0084ae70` budget notify + `FUN_00872d30` manager update | role + call-from-master-update | M |
| `StreamPreload` | `FUN_008738f0` Stream_EvictCompleted (+ `FUN_00872e60` flush) | first stage of the update body | M |
| `UpdateStreamBlocks` | `FUN_008739e0` Stream_Manager_Tick | node completion/promote gate (`(*(node+0x30))(lvl)==4`) | H |
| `StreamPostload` | `FUN_00873cf0` Stream_RetryPromoteQueue | last stage; ages/re-queues pending | M |
| `IsLoadingOrStreaming` / `StreamingWaiting` | read of **`mgr+0x4c35c`** (set here) | busy flag = pending‖in-flight‖+0x834, gated by pause bits | H |
| `StreamingManager` (the object) | `mgr` = the streaming-manager singleton (fields +0x814/+0x824/+0x844/+0x4c35c) | field layout matches memory notes | H |

Manager field map (from this body + memory [[engine-streaming-buffer-sizing-chain]] / worldload
notes): `+0x814` pending count · `+0x824` in-flight · `+0x834` (third queue) · `+0x844` resident ·
`+0x4c359/0x4c35a/0x4c35d` pause/mode bits · `+0x4c35c` busy · `+0x4c36c` backlog · `+0x4c368`
resident bytes.

### 2.3 Node lifecycle + buffer-sizing (H — already recovered, referenced)

The node producer/consumer chain and the buffer-sizing formula are fully in
[`../engine_load_path_map.md`](../engine_load_path_map.md) §"streaming manager / worker" and memory
[[engine-streaming-buffer-sizing-chain]]; not repeated here beyond the anchor:

- Worker: `Stream_WorkerThread FUN_00876400` pops a `pimpQueue` ring, dispatches `DAT_019f904c[type]`
  (populated by `Tex_RegisterStreamJobs FUN_0046a440`), Interlocked completion.
- Node: Submit `FUN_00875760` → Produce `FUN_00873410` → Init `FUN_008759c0` → (read) →
  Recycle `FUN_00874410` / Finalize `FUN_00875a50`.
- Buffer: `FUN_00875b00` allocs `node+0x4c = page_count(u24 @ page_record+4) << 15` (32 KB pages),
  async read `FUN_008273f0(handle, node+0x40, +0x44, +0x48, 1, node+0x60, dxtflag)` →
  `_DAT_0244f9b4` IO syscall; under-claimed page_count ⇒ `STATUS_BUFFER_TOO_SMALL 0xC0000023`.

### 2.4 Pre-/post-load blocking driver + the load-gate wiring

**`FUN_004bf8c0` = StreamPreload + StreamPostload** (M) — the *blocking* phased level-transition
prime, reached from `FUN_004c0730`. It force-loads every block in the manager's list (`mgr+0x83c`)
by asset type-hash in a fixed priority order, then spins the manager pump until the queue empties,
then advances a load state-machine:

```c
// PRELOAD: prime by type-hash, priority order, over every block:
FUN_00875fd0(node, 0x99e77ace); ... 0x18166555; ... 0x5b724250 /*mesh*/; ... 0xfe0e8320;
mgr[0x4c35e] = 1;  FUN_00875fd0(node, 0);              // then everything remaining (0 = any)
while (thunk_FUN_024ef810()) FUN_00872d30();           // POSTLOAD: pump until predicate empties
DAT_0149fda8 = 3; do { vcall(PTR_0149fda0+0xc)(0); } while (DAT_0149fda8 != 4);  // load FSM 3→4
                  DAT_0149fda8 = 1; do { … } while (DAT_0149fda8 != 2);          // FSM 1→2
PTR_DAT_01175cdc[0x61] = 1;                             // world-present set on success
```

`FUN_00875fd0` is the force-load-one-block-by-type leaf (scan resource array `block+0x14`, cnt
`+0xc`; if type-hash `+8 == arg` or `arg==0` ⇒ kick load `FUN_00563c46`). `0x5b724250` = mesh
type-hash. This is the concrete PC realization of the Xbox `StreamPreload → StreamPostload` ordering.

**The gameplay load-gate (H flag / M mechanism).** `mrxstate.lua` `STATE_WAITFORSTREAMING(2).Enter`
= `Sys.RequestGameState("WaitForStreaming")` + `Event.Create(Event.GameStateChange,
{"WaitForStreaming","exit"}, _StateComplete)`. Engine side, the predicate the game polls is the busy
flag **`mgr+0x4c35c`** (set/cleared only by `FUN_00872d30`, §2.2), which is 1 while any of pending
`+0x814` / in-flight `+0x824` / list3 `+0x834` ≠ 0. When the last node reaches status 4
(`FUN_008739e0`) all three counts hit 0, `0x4c35c` clears, the engine fires
`GameStateChange…"exit"` → `MrxState.Exit(WAITFORSTREAMING)` → gameplay unblocks. Live stalled
baseline: `pending=18, in-flight=0, list3=1, resident=392` = the streaming-livelock wall.

| Xbox symbol | PC | Married by | Conf |
|---|---|---|---|
| `StreamPreload` / `StreamPostload` | `FUN_004bf8c0` (prime → spin → FSM) + leaf `FUN_00875fd0` | phased type-hash prime then pump-to-empty then load-FSM 3→4/1→2 | M |
| `LoadIsRetry` (retry semantics) | `Stream_RetryPromoteQueue FUN_00873cf0` | node attempt-count `+0x34`: `<4` bumps+defers, `≥4` w/ `+0x24==0` completes; QPC-restamps | M |
| per-frame pump (loading screen) | `FUN_004c9740` tail: `if (2 < *(PTR_DAT_01175cdc+0x30)) FUN_00872d30()` | pumps mgr only while load-stage>2; also the game-systems list (dual role, §1) | H |
| per-frame pump (in-game) | `FUN_006b4a70` | identical `2 < [PTR_DAT_01175cdc+0x30]` gate → `FUN_00872d30()`; render-guarded alt | M |
| load-stage / world-present object | `PTR_DAT_01175cdc` (`+0x30` load-stage, `+0x61` world-present) | end of `FUN_004bf8c0` sets `+0x61`; pumps gate on `+0x30>2` | M |
| `Pg.LoadAsset` / `Pg.LoadingStaticLayers` / `LoadLayer` (`MrxLayerManager.Add`) | Lua cfunc VAs **unlocated** | role certain (Lua-facing); recover via `Pg.*` binding-table walk | L |

**Correction to the Xbox inventory grouping (important).** Xbox `OpenStreamFile`/`CloseStreamFile`
(`0x2bbb0/0x2bba0`), `UpdateStreamBlocks` (`0x2f0d4`), and `SetStreamBlockDumping` are the **audio**
`.pws` stream pair / stats (`PgSoundStreamIO.cpp`, `Sound.OpenStreamFile`), **not** world-content
streaming — exactly the caution `world-streaming.md` itself raised. The world/FFCS block-open path is
the `Chunk_GetEntryReader FUN_00464780` reader family (INDX/PTHS/ASET → 0x14-stride block reader),
not a symbol named `OpenStreamFile`. Do not bind these to world streaming.

---

## 3. Terrain streaming + two-tier LOD

The two-tier terrain LOD is married end-to-end on the PC side: the runtime hi→low GUID-map builder
(`FUN_004a88a0`) is **read-confirmed**, its two callers are the terrain-patch **Activate/Deactivate**
vtable methods (structural), and the descriptors/deserializers for
TerrainObject/LowResTerrainObject/TerrainFade/TerrainKey are bound. The only genuinely unlocated
Xbox symbols are the **height-query family** and `CanActivate`.

### Marriage table

| Role | Xbox symbol / addr | PC addr | Married by | Conf |
|---|---|---|---|---|
| **HighRes→LowRes GUID map — runtime builder** | `TerrainGuidMappingHighResToLowRes` (desc `@0x829f6ba8`, size 4) | **`FUN_004a88a0`** (281 B) | read body: run-once (`DAT_01175a3a`), `memset(idx,-1)`, walks LowRes pool `&PTR_PTR_017beb80`, inserts each via `FUN_0064a600` | H |
| **TerrainObject::Activate** (proximity build) | name `@0x004109c` | **`FUN_0066cac0`** (1378 B) | spawns ≤16 patch children stamping TerrainObject; lazy-calls `FUN_004a88a0`; builds parent AABB; **no direct callers = vtable-dispatched** | M |
| **TerrainObject::Deactivate** (despawn) | name `@0x00410b8` | **`FUN_0066d030`** (535 B) | ≤0x10 child despawn loop; refs terrainmesh hash `0x7c569307` + template bit `0x83000000`; lazy-calls `FUN_004a88a0`; vtable-dispatched | M |
| TerrainObject::CanActivate | name `@0x004109c` | — | unlocated (no PC string; small predicate vtable slot) | open |
| TerrainObject — reflection descriptor | `TerrainObject` `@0x00317a0` | `FUN_00644260` (hash `0x6c82ebe5`) | string-anchored (world-streaming.md PC xref) | H |
| TerrainObject — stream deserialize (consumer) | — | **`FUN_0063d590`** | read body: vcall `+0x14` reads **4 B** → pool `DAT_017bea94`, spatial reg `FUN_00665590` | H |
| LowResTerrainObject — descriptor | `LowResTerrainObject` `@0x00317c8` | `FUN_00644470` | string-anchored | H |
| LowResTerrainObject — deserialize (consumer) | — | **`FUN_0063d6e0`** | read body: vcall `+0x14` reads **8 B** → pool `DAT_017beb84` (= the pool `FUN_004a88a0` walks) | H |
| **TerrainFade** — descriptor | `TerrainFade` `@0x00317b0` | **`FUN_00644300`** | read body: `s_TerrainFade_00bc5678`, `CopyFromStream_00bc1e50`, **element size `0x14`=20 B**, seed `0x9e3779b9`, pool 256 | H |
| TerrainKey — deserialize | `TerrainKey` `@0x00315b0` (enum `@0x003a1b0`) | **`FUN_00661750`** | read body: refs `s_TerrainKeyEnum_00bc72c4`; 4 B → pool `DAT_017bdfa4` | H |
| Terrain shader combo validator | (terrain shader family) | `FUN_004a8f30` | read body: emits `"BAD_TERRAIN_VS_PS_COMBO: mesh %s…"` | M |
| Terrain shader registry (already married) | `PgTerrainMeshFP4D @0x822db050` | `FUN_0084f130` | reference only (world-streaming.md) | — |
| `GetTerrainHeight_Fast/Slow`, `GetHeightAboveTerrain`, `ProcessTerrainCast` | names `@0x001714c/0x0017134/0x0029ab4/0x00213ec` | — | unlocated (Havok sampled-heightfield inference below) | open |

### Annotated excerpts

**`FUN_004a88a0` = `TerrainGuidMappingHighResToLowRes` runtime builder (H, read-confirmed).**
Run-once (gate `DAT_01175a3a`), clears the hi-res-GUID→lowres-index table to `-1`, then walks the
**LowResTerrainObject** pool (`&PTR_PTR_017beb80`, count `DAT_017beb84` — the exact pool the 8-byte
LowRes deserializer `FUN_0063d6e0` writes) and inserts each hi-res GUID → low-res index via
`FUN_0064a600`, spatially registering via `FUN_00665590`. The concrete PC realization of the Xbox
descriptor; matches ECS-doc `06 §Terrain`.

**Callers = the Activate/Deactivate pair (M, structural proof).** `FUN_004a88a0`'s only two callers
both lazy-build the map right before touching terrain: `FUN_0066cac0` (Activate) checks "hi-res child
set built?" (`FUN_005857e0`), ensures the map, then spawns ≤16 hi-res patch children stamping
`TerrainObject` + a parent record of 16 child handles + AABB; `FUN_0066d030` (Deactivate) runs the
≤0x10 child despawn loop and resolves the `0x7c569307` (`terrainmesh`) container to unload. Neither
has direct callers → both are reached through the entity vtable, exactly as
`TerrainObject::Activate`/`::Deactivate` would be.

### Two-tier LOD selection (confirmed mechanics)

- **Low-res tier** = `LowResTerrainObject` (8 B `{mesh handle, LOD index}`) → the
  `low_res_terrain_P000_Q3` block (400 tiles + baked `vz_lrterrain` atlas), always-resident far proxy
  (deserialized by `FUN_0063d6e0` → pool `DAT_017beb84`).
- **Hi-res tier** = `TerrainObject` patches = terrain-ground meshes **baked into `c3####_P000_Q3`
  cells** — there is **no** separate hi-res terrain block; hi-res streams via ordinary per-object
  c3-cell streaming ([[world-terrain-loader]] RCA). On range-entry `FUN_0066cac0` spawns ≤16 patch
  children.
- **The bridge** = `FUN_004a88a0`'s GUID map lets the engine, on hi-res activate, find the matching
  low-res proxy to fade/suppress (and restore on deactivate); `TerrainFade` (`FUN_00644300`, 20-B
  record) carries the cross-fade state.
- **Shader LOD** is orthogonal + already married: `PgTerrainMeshFP{,1D,2D,3D,4D}` = explicit numeric
  LOD arg 0–3 in registry `FUN_0084f130`.

### Open (honest)

- **Height-query family** has **no PC string anchor** — not bound. Structural inference: PC terrain
  collision uses a Havok **sampled-heightfield** shape — the real terrain shape ctor is
  `hkpSampledHeightFieldShape FUN_00a0e3d0` (corrected by [`physics_code_map.md`](physics_code_map.md);
  the earlier `FUN_008bfb60` is the shape-enum→string TABLE, not the query), with getters
  `hkpStorageSampledHeightFieldShape FUN_00a0a2f0` / `hkpTriSampledHeightFieldCollection FUN_00a0d2f0`.
  So "Fast" = direct bilinear grid sample (the Rust engine's `height_at`), "Slow"/`ProcessTerrainCast`
  = full `hkpWorldRayCaster` down-cast (physics map §3).
  Confirm-live to bind VAs.
- **Doc reconciliation:** ECS-doc `06` labels the TerrainObject *field-schema builder* `FUN_00662460`
  while world-streaming.md labels the *reflection-descriptor setup* `FUN_00644260` — different roles
  of the same class, consumer/deserializer `FUN_0063d590` for both. Not a contradiction.

---

## 4. Object hibernation runtime + props/destructibles + regions

PC retail strips every hibernation/region **runtime** string (`Hibernation distance … may fall
through terrain`, `SetHibernationDistance`, `IsHibernated`, `AI Hibernated …` are all absent from
bodies), so runtime marriages are **structural**; the reflection-descriptor names and the
Lua-binding **name** strings survive, so the descriptors + cfunc VAs are H.

### Marriage table

| Role | Xbox symbol / addr | PC addr | Married by | Conf |
|---|---|---|---|---|
| `HibernationControl` reflection descriptor | `HibernationControl` (str `0x003136c`) | `FUN_00640a40` (ctor `0x00a7a970`) | string-anchored; **field-size arg = 6** == the 6-byte on-disk payload placement.rs parses | H |
| HibernationControl component method vtable | — | `&PTR_FUN_00bc5ff8` (installed by `FUN_00640a40`) | shared base-component vtable (Activate/Deactivate/CanActivate slots); **shared** with `_PropPhysics`/`_DebrisPhysics` | M |
| Component CopyFromStream reader | `&PTR_FUN_82030fa0` (Xbox) | `&PTR_CopyFromStream_00bbf430` | ties HibernationControl to the WAD stream-deserialize load path | H |
| `Object.IsHibernated` cfunc | `IsHibernated` (`0x0029d70`) | **`0x005CF240`** (entry `0xB99770`) | luaL_Reg walk (validated); body binding-only | H (VA) |
| `Object.GetHibernationDistance` cfunc | `GetHibernationDistance` (`0x0029d58`) | **`0x005CF420`** (entry `0xB99778`) | walk; body reads the object's **first u16** (= dist0), float default `DAT_00dfdb5c` | H |
| `Object.SetHibernationDistance` cfunc | `SetHibernationDistance` (`0x0029d40`) | **`0x005CF4F0`** (entry `0xB99780`) | walk; body → SecuROM worker `thunk_FUN_024ecab0` | H |
| `Object.RevertHibernationDistance` cfunc | `RevertHibernationDistance` (`0x0029d24`) | **`0x005CF600`** (entry `0xB99788`) | walk; body binding-only | H (VA) |
| object→component instance resolver | (Del::* family) | `FUN_005857e0` | fastcall pool-hash resolver; Get/Set use it to reach the u16 field | M |
| **AI/population hibernate-out gate** (`AI Hibernated …`) | `DeathCheck`/`DeathCompute` `FUN_8235f3f8`/`FUN_8235efc0` | `FUN_00500b40` → `FUN_005007d0` / `FUN_00500ac0` | dt-decay + **squared-distance** gate; current dist written to `+0x19c` (shared by both halves) | H |
| **PopulationDensity region-containment** | (PlayerPopulation select) | **`FUN_004d60e0`** (from `FUN_00502510+0x114`) | rect containment: pt vs `[+0x10,+0x18]×[+0x14,+0x1c]`, priority `+0x38`, edge-margin best-fit | H |
| `_PropPhysics` reflection descriptor | `_PropPhysics 768` / `PropPhysics::Activate` | **`FUN_0063e5d0`** (ctor `0x00a79f00`) | string `s__PropPhysics_00bc4b5c`; field-size `0x10`; vtable `&PTR_FUN_00bc5ff8` | H |
| `_DebrisPhysics` reflection descriptor | `PgPhysicsActorDebris` / `RtDebris` | **`FUN_0063e680`** (ctor `0x00a79f20`) | string `s__DebrisPhysics_00bc4b6c`; field-size `0xc` | H |
| **PropPhysics::Activate/Deactivate runtime** | `PropPhysics::Activate` (`0x0041084`) / `::Deactivate` (`0x004106c`) | vtable method in the `&PTR_FUN_00bc5ff8` cluster (not name-anchored) | mirrors `TerrainObject::Activate/Deactivate`; **confirm-live** | L |
| `SphereRegion` descriptor | `SphereRegion` (`0x00314a8`) | `FUN_00641e10` (field-size 4 = radius float) | string `s_SphereRegion_00bc51d4` | H |
| `CircleRegion` / `LineRegion` descriptors | `0x0031518` / `0x0031528` | `FUN_00642220` / `FUN_006422d0` (field-schema `FUN_0065fee0`/`FUN_0065ff80`) | string-anchored | H |
| `RuntimeMusicRegion` descriptor | `RuntimeMusicRegion` (`0x0031908`) | `FUN_00644fe0` | string-anchored | H |
| `World.CreateRegion` cfunc | `CreateRegion` (`0x0028c24`) | **`0x005BFB00`** (entry `0xB99E30`) | walk; type-char `'s'`/`'c'` → `FUN_00532de0`, register `FUN_00649180(&PTR_PTR_00df6d08,…)` | H |
| `World.GetLineRegion` cfunc | `GetLineRegion` (`0x0026da0`) | **`0x005B0EC0`** (entry `0xB9A630`) | walk; resolves names via the `0xDF6B88` name-registry family | H |
| `World.ChangeLineRegionSetting` cfunc | `ChangeLineRegionSetting` (`0x0026dc8`) | **`0x005B0D20`** (entry `0xB9A620`) | walk; body → SecuROM worker `thunk_FUN_02da0000` | H |
| `World.GetLineRegionPoints` cfunc | `GetLineRegionPoints` (`0x002a708`) | **`0x005D7160`** (entry `0xB99460`) | walk; binding-only | H (VA) |
| `ActivateFactionRegionMusic` cfunc | `ActivateFactionRegionMusic` (`0x002bf08`) | **`0x005E1CC0`** (entry `0xB98DA0`) | walk; binding-only | H (VA) |
| `SetRootFactionRegionMusic` cfunc | `SetRootFactionRegionMusic` (`0x002bf34`) | **`0x005E1C40`** (entry `0xB98D90`) | walk; binding-only | H (VA) |
| `BuildingDestruction` descriptor | `BuildingDestruction` (`0x0031550`) | `FUN_00642590` (str `s_BuildingDestruction_00bc52b4`) | string-anchored | H |
| `DestructionLink` / `…TypeEnum` | `DestructionLink` (`0x0032298`) | descriptor region-adjacent (`FUN_006422d0` cluster); orchestrator = `FUN_004cf340` | string-anchored; orchestrator cross-ref `docs/destruction_orchestrator_format.md` | H / xref |

### Annotated excerpts (read first-hand by the cluster pass)

**HibernationControl descriptor `FUN_00640a40` — the field-size proves the on-disk schema (H).**
```c
DAT_017bd178 = &PTR_CopyFromStream_00bbf430;   // WAD stream-deserialize (load path)
DAT_017bd19c = 6;                              // <-- component payload = 6 bytes
DAT_017bd1a4 = 0x9e3779b9;                     // golden-ratio reflection hash seed
_DAT_017bd190 = &PTR_FUN_00bc5ff8;             // component method vtable (Activate/…)
_DAT_017bd1b4 = s_HibernationControl_00bc4fcc; // names it
```
`DAT_017bd19c = 6` is the decisive marriage: it equals the `schm` payload stride (6) that
`placement.rs::parse_hibernation_records` reads as `{dist0:u16, dist1:u8, dist2:u8, dist3:u8,
flag:u8}` after the u32 key. `_PropPhysics` (`FUN_0063e5d0`, size `0x10`) and `_DebrisPhysics`
(`FUN_0063e680`, size `0xc`) are byte-for-byte the same template with the same `&PTR_FUN_00bc5ff8`
vtable — the PC-side registrations of `PropPhysics::Activate/Deactivate`'s component.

**`Object.GetHibernationDistance` = `FUN_005CF420` (H).** Resolves the object's HibernationControl
instance and reads the **first u16** as the distance, `DAT_00dfdb5c` (float) = class-default
fallback:
```c
puVar6 = (ushort *)FUN_005857e0();          // object -> HibernationControl instance
if (puVar6 != 0) param_1 = (float)*puVar6;  // *puVar6 = dist0 (the u16 stream-out distance)
```
The setter `FUN_005CF4F0` reads the arg then calls `thunk_FUN_024ecab0` — a SecuROM **VM trampoline**
(`FUN_02a30028`); the setter *cfunc* is decompiled, only the terminal commit is VM-dispatched, **read
live in the unpacked image** ([[securom-decompiled-not-a-blocker]]), not a wall.

**Population hibernate-out gate `FUN_00500b40` (DeathCheck) → `FUN_005007d0` (H).** The `AI Hibernated
…` per-object cache-out: per-entry dt timer decrement, distance `fVar8 = DAT_00b9b664 -
dt*DAT_00b9267c`, **squared** (`fVar8*fVar8`), then shared gate `FUN_005007d0(dist²)` decides
decay-vs-remove; current distance written to `+0x19c` (the field both halves share). The 50²…400²
distance table is the Xbox oracle; PC constants are a confirm-live read.

**Region containment `FUN_004d60e0` (H)** — rectangular AABB containment for PopulationDensity
regions, called from `PgSysPopulation::Update` (`FUN_00502510+0x114`): point tested against region
min/max `[+0x10,+0x18]×[+0x14,+0x1c]` with priority gate `+0x38`, then min edge-distance margin to
pick the best-fit region. The runtime "which region am I in" test for population/streaming density
selection. (The *radius* test for `SphereRegion`/`CircleRegion` runs inside the music-region update
reached from binding-only `ActivateFactionRegionMusic 0x5E1CC0` — confirm-live.)

**Lua binding-walk method (validated).** cfuncs recovered by scanning `mercs2_unpacked.exe`
(`file_offset = VA − 0x400000`): for each name string, find the `luaL_Reg {name*, cfunc*}` entry
pointing at it, read `+4` = cfunc VA. **The walk reproduces the population doc's known
`Ai.TweakAttachedSpawners = 0x5A4C40` exactly** → the recovered VAs are trustworthy.

---

## 5. Confirm-live inventory (x32dbg, read-only while PAUSED — [[x32dbg-mcp-no-resume]])

**Orchestration**
1. `mgr+0x4c35c` busy flag = `IsLoadingOrStreaming`/`StreamingWaiting`: break in `FUN_00872d30` tail,
   read pending/in-flight/list3/resident (`+0x814/+0x824/+0x834/+0x844`) to confirm the predicate;
   also break on a *read* of `[mgr+0x4c35c]` to catch the game-side poller (likely the
   `Sys.RequestGameState`/`GameStateChange` native cfunc — binding-table-only).
2. `FUN_0084ae70` LOD-tier thresholds `PTR_FUN_00ce8de0`/`PTR_DAT_00ce8ddc`/`DAT_00ce8dd8` + band
   `DAT_00ce8dd4` — read actual budget values + the subscriber list `PTR_LOOP_00dfd140`.
3. `thunk_FUN_024ef810` (the `FUN_004bf8c0` preload spin predicate) + the preload type-hash order
   `0x99e77ace / 0x18166555 / 0xfe0e8320` (mesh `0x5b724250` known) — resolve against the ASET type
   table to name the preload priority tiers.
4. Confirm `FUN_006b4a70` vs `FUN_004c9740` = in-game vs loading-screen pump (break both with the
   loading screen up vs dismissed).

**Terrain**
5. Height sampler VAs (`GetTerrainHeight_Fast/Slow`, `ProcessTerrainCast`) — HW-read bp on the loaded
   Havok sampled-heightfield shape, or break where terrain Y is queried (player ground-clamp), to
   bind the PC VAs (inference-only today).
6. Confirm `FUN_0066cac0`/`FUN_0066d030` sit in the `TerrainObject` entity vtable's Activate/Deactivate
   slots (promotes those marriages M→H); `FUN_005857e0` = the RtTerrainChildren getter.

**Hibernation / props / regions**
7. `thunk_FUN_024ecab0` (native `SetHibernationDistance` worker) + `thunk_FUN_02da0000` (native
   `ChangeLineRegionSetting` worker) — read the unpacked SecuROM bodies live.
8. **PropPhysics::Activate/Deactivate** — break the `&PTR_FUN_00bc5ff8` vtable Activate slot with a
   Prop entity to confirm it mirrors `TerrainObject::Activate` and reads the hibernation distance.
9. **Static-world HibernationControl stream-out** — the 14080-pool consumer (distinct from the
   population `FUN_00500b40` path) is the streaming manager itself (bp `0x8739e0`/`0x873cf0`); confirm
   it reads `HibernationControl` dist0 for the pre-placed SceneObjects.
10. The **>400 warning** compare (`… may fall through terrain`) is string-stripped on PC → its site is
    statically unlocated; a live break on the SetHibernationDistance worker finds the `> 400.0` test.
11. Recover the binding-only cfunc bodies (`0x5CF240`/`0x5CF600`/`0x5D7160`/`0x5E1CC0`/`0x5E1C40` +
    orchestration `Pg.LoadAsset`/`LoadLayer`/`RequestGameState`) with a `DecompileProfileAccessors.java`
    -style forcing script.
12. PC death-distance constants — confirm the Xbox 50²…400² table against `FUN_00500ac0`/`FUN_005007d0`.

---

## 6. Reconciliation with `mercs2_engine` (scoreboard row 8 = ✅ core)

The engine already implements the *decision core* faithfully ([[mercs2-streaming-runtime]]): a pure
`StreamingManager` that turns camera position into load/unload/wake/hibernate diffs, per-entity
`HibernationControl` distances, block residency with hysteresis + budget, terrain LOD swap, and the
net-new unload path. This map gives the **engine-accurate reference** for the pieces still stubbed or
diverging:

- The **global LOD-budget tier** `FUN_0084ae70` (memory-pressure hysteresis, tier 0–3 broadcast) is
  a *distinct* input from the per-entity distances — the engine currently has only the per-entity
  path; the budget-tier notify is the missing global governor.
- The **busy-flag gate** `mgr+0x4c35c` is exactly the `Sys.RequestGameState("WaitForStreaming")`
  seam the engine must satisfy (support inventory §"load-gate seam").
- Pre-/post-load ordering (evict → flush → tick → retry) is the manager step order to mirror.