# Population / Spawner system (`PgSysPopulation`) — Xbox↔PC code map

**Scope:** the ambient-population + spawner system (scoreboard row 24). This marries the **Xbox
360 devkit (Jul-08 Profile build)** symbol/PDB ground truth to the **PC retail decompilation**
(`Mercenaries2.exe`, unpacked image, base `0x400000`). The PC retail build strips every
`PgSysPopulation::` profiler string, so the runtime bodies had no string anchor — they are married
here **structurally**, by shared constants, call-tree shape, message-type switches, and the Lua
binding tables.

**Companion JSON:** `docs/data/population_spawner_code_map.json` — the machine-readable marriage
table (66 functions: `{addr, ghidra_name, system, stage, confidence, xbox, evidence}` + `_meta`
with corrections and confirm-live list), same schema as the other `docs/data/*_code_map.json`.

**Sources.** Xbox oracle: `docs/mercs2-pdb-analysis/world-streaming.md` (symbol inventory),
`output/_ghidra_x360/xenon_decomp_named.c` + raw PPC scan of `mercs2_xenon_p.pe_ghidra.bin`
(base `0x82000000`). PC: `output/_ghidra/all_functions_decomp.txt`, binding tables walked in
`output/_ghidra/securom_dump/mercs2_unpacked.exe`. Data layer: `docs/mercs2-ecs/02_ai_perception_population.md`,
`docs/game_config/cdbsizes.ini`, `docs/vz_state_analysis.md`. Companion memory:
[[world-streaming-spec]], [[name-registry-spawn-by-hash]], [[cdbsizes-component-pool-config]].

---

## 0. Result in one line

The whole system is now in the clear on **both** builds. The per-frame `PgSysPopulation::Update`,
its ~24-call fan-out, the four simple-spawner families, the death check/compute pair, the
region-cache message pumps, the spawn-queue drain, and the full Lua binding surface are all
married PC↔Xbox with high confidence. Only the SecuROM-virtualized spawn-worker thunks and a
handful of inlined stat-phases remain confirm-live.

---

## 1. Two corrections this recovered (fix before building on the old docs)

1. **`world-streaming.md` §30 is wrong about the Update.** Xbox `FUN_82364058` (the function the
   `PgSysPopulation` ctor appends to `&DAT_82c215c8`) is **`OnEntityDeleted`**, not `::Update`.
   `&DAT_82c215c8` is the engine's global **per-entity on-delete callback array** (co-registrants
   `FUN_82585fc0`, `LAB_823a9150`, `DAT_82575dc0` are all cleanup walkers). The **real per-frame
   Update is Xbox `FUN_82368008`** (size `0xB28`), reached from the game-systems master tick
   **`FUN_822ff9b0`** at call-site `0x822FFDB0`. This also answers that doc's open "PgGameSystem
   master tick never located" — it is `FUN_822ff9b0`.
2. **`scheduler_tick_code_map.md` §7 misattributes population.** `FUN_006b7720`/`FUN_006c4eb0` are
   11-byte stubs inside SceneObject-pool registrars, **not** `PgSysPopulation::Update`. The real PC
   Update = **`FUN_00502510`**, and the layer-4 per-system tick **order** is now statically resolved
   as the literal call sequence of **`FUN_004c9740`** (1448 B) — closing that doc's confirm-live
   item #1 for the population slot. See §8.

---

## 2. Master marriage table

Confidence: **H** structural fingerprint that can't coincide (matching magic constants /
message-type switch / call-shape + role) · **M** role + call-position match, one strong signal ·
**L** positional/among-siblings only, needs live confirm.

| Role | Xbox symbol / addr | PC addr | Married by | Conf |
|---|---|---|---|---|
| Game-systems master tick | `FUN_822ff9b0` | `FUN_004c9740` (via `FUN_004c0ec0`) | both = the single fixed-order per-system call list; population called mid-sequence | H |
| **`PgSysPopulation::Update`** | `FUN_82368008` | **`FUN_00502510`** | population master; both gated on a world/state flag; identical child roles below | H |
| `::OnEntityDeleted` (mis-doc'd as Update) | `FUN_82364058` | (on-delete cb; not yet paired) | — | — |
| DeathCheck driver (budget 20/frame) | `FUN_8235f3f8`→`FUN_8235f238` | **`FUN_00500b40`** | pending-death list walk, per-entry dt timer decrement, distance-gate, budgeted removal | H |
| **DeathCompute** (dist² table) | `FUN_8235efc0` | **`FUN_00500ac0`** (+ gate `FUN_005007d0`) | remove/decay half; per-viewport squared-distance gate; called by the check half | H |
| Region cache-out msg pump (types 3/7/0xB) | `FUN_82365828`→`FUN_823647a8` | **`FUN_005017b0`** | **identical `msg==3 / ==7 / !=0xB` switch**; event-7 clears driver-data + faction cleanup | H |
| Region cache-in / KeptPopulation drain | `FUN_8235f580`→`FUN_8235f470` | **`FUN_00502fc0`**→`FUN_00502960`,`FUN_005002b0` | ring/kept-list drain, one lump/tick, ambient placement math (see §5) | M |
| Spawn-density decay (`>>1 & 0x7f7f7f7f`) | under DensityUpdate (`FUN_82367d28`) | `FUN_004df000`→**`FUN_004e0510`** | halve spawn-history bytes on the sim-seconds overflow accumulator | H |
| **UpdateSimpleSpawners** (4 families) | `FUN_82338768` | **`FUN_004e4100`** → 4 procs | 4 family updaters over the active-spawner lists (caps 200/100/200/64), `OccupiedBuildingSpawnCallback` | H |
| SpawnUnitInstantiate | `FUN_82367a78`/`FUN_823649e8` | **`FUN_004e4150`** (from `FUN_004e1590`) | builds the final spawn record → instantiate; drained from a deferred queue | M |
| QueuedSpawning / SpawningUnits drain | `FUN_82365a70`/`FUN_823631a0` | **`FUN_004b4590`** (3600 B) | view-edge placement (atan2), LCG-filled request, request-pool alloc, name→registry resolve | M |
| Heli-wave spawner update | `FUN_8232b9e8` (start `FUN_8232b2b8`) | (native side of cfunc `0x005DA4D0`) | state block + ≤15 waves; see §6 | M |
| Skirmish/heli direction update | `FUN_8232d9e8` | in `FUN_004ea260` region | wave-director state machine (see §6) | L |
| Load-time population build | module-init `FUN_82364360` | **`FUN_0066f300`** (9911 B) | consumes SphereRegion+PopulationDensity+DangerousBuilding+DynamicRoad+Flow+CircleRegion + the SimpleSpawner manager | M |
| SpawnerAdjust apply (Lua-triggered) | (via `TweakAttachedSpawners`) | **`FUN_004e2d80`**→`FUN_004e32b0` | copy 0x60 SpawnerAdjust record, 8-group bit loop, despawn/force-respawn | H |
| RegisterStats (40 phase names — the authoritative name list) | `FUN_8235e6d0` | (PC strings stripped) | — | — |

---

## 3. `PgSysPopulation::Update` fan-out (Xbox `FUN_82368008` ↔ PC `FUN_00502510`)

The Xbox body executes ~24 `bl`s in a fixed order; PC `FUN_00502510` (306 B) executes the same
roles in a compatible order. Xbox is the finer-grained oracle because its Profile build kept the
phase names; PC inlines several phases. Marriage by role:

| Xbox phase (from `FUN_8235e6d0` name list) | Xbox fn | PC fn | notes |
|---|---|---|---|
| pre-update / heat-map zero | `FUN_8235e2c0` | (head of `FUN_00502510`, `FUN_00500b40` call) | |
| world-present gate | `lwz 0x83451CA4==0` | `*(DAT_01175cdc+0x63)!=0` | early-out gate |
| **DeathCheck + DeathCompute** | `FUN_8235f3f8`/`FUN_8235efc0` | `FUN_00500b40`/`FUN_00500ac0` | H — §4 |
| spawn-density decay | (DensityUpdate) | `FUN_004df000`→`FUN_004e0510` | H |
| event drain / cache-out | `FUN_82365828` | `FUN_005017b0` | H — §5 |
| **UpdateSimpleSpawners** | `FUN_82338768` | `FUN_004e4100` | H — §6 |
| CacheIn lump ring | `FUN_8235f580` | `FUN_00502fc0` | M — §5 |
| PopulationDensity region-select (per player) | (PlayerPopulation `FUN_82365c80`) | `FUN_004d8490`→`FUN_004d60e0` | per-player anchor + best-priority containing region |
| main ambient spawn/despawn | (DensityUpdate `FUN_82367d28`) | `FUN_00503020` (3119 B) | body largely unread — big ambient driver |
| CacheOut round-robin sweep (20/tick) | (Cursors `0x837D5128`) | `FUN_00502280`→`FUN_005020e0` | M — 20-per-tick sweep |
| spawn-queue drain (post-update) | `FUN_82367a78` | `FUN_004b4590` | M — §6 |

**Decisive fingerprint (cache-out pump).** Xbox `FUN_82365828` pops its queue and switches on the
message type with `cmpi 3` / `7` / `0xB`. PC `FUN_005017b0` has literally:

```c
if (local_28 == 3)        { /* stream-out apply: FUN_00648d80 + thunk_FUN_024e8810 */ }
else if (local_28 == 7)   { /* clears driver-data @+0x1010, FUN_005857e0 copy, then
                               FUN_00508b50 / FUN_0058f200 / FUN_0059b550 */ }
else if (local_28 != 0xb) { goto skip; }
```

The `3/7/0xB` triple plus the event-7 driver-data cleanup is a coincidence-proof match.

---

## 4. Death system (H)

- **PC `FUN_00500b40` = DeathCheck** ← Xbox `FUN_8235f3f8`→`FUN_8235f238`. Walks the pending-death
  list (`DAT_00dd12e8`, count `DAT_00dd13ec`), resolves each object through the global GUID hash
  family (`DAT_00df9cc4`/`…d00`), decrements per-entry timers `DAT_017959d0[i*0xc]` by `dt`,
  distance-gates via the shared helper, then either decays (vcall `+0x38`) or removes via
  `FUN_00500ac0`. Xbox budget is **20 units/frame** (`li 0x14`).
- **PC `FUN_00500ac0` = DeathCompute** ← Xbox `FUN_8235efc0` (the "compute" half; removal path).
- **Shared gate `FUN_005007d0`** (called by both `FUN_00500b40` and `FUN_00500ac0`, exactly as
  Xbox `FUN_8235efc0` is called from both check and compute) walks the SimpleSpawner instance list
  (`PTR_PTR_00df8188`) under `CS DAT_00edbaa4` and does the GUID-hash membership test.
- Xbox `FUN_8235efc0` carries the per-viewport **squared-distance table**
  `2500(50²) / 62500(250²) / 40000(200²) / 160000(400²) / 10000(100²) / 22500(150²) /
  25600(160²) / 6400(80²) / 19600(140²)` and a `FUN_822f0540(…, 2.0)` fade. These are the meters
  to confirm against the PC gate live (the PC constants are behind the same distance-select logic
  but were not read out numerically here — **confirm-live item**).

---

## 5. Region cache (CacheIn / CacheOut / lumps)

No standalone `CacheIn*`/`CacheOut*`/`*Lump` bodies exist in **either** build — the names are
RegisterStats phase strings (Xbox) that are **stripped on PC**, and the mechanics are distributed:

- **CacheOut** = the msg pump (Xbox `FUN_82365828` / PC `FUN_005017b0`, §3). Stream-out events
  (types 3/7/0xB) remove a unit; Xbox per-unit `FUN_823647a8` stores a **kept-population record**
  (`FUN_8233bd58`), strips its map icon, and unlinks it (dist consts 50²/150²).
- **CacheIn** = the kept-list drain. Xbox `FUN_8235f580`→`FUN_8235f470` re-creates from the
  **64-slot kept ring @0x837D38A8** (count `0x837D37A0`); PC `FUN_00502fc0` drains an **8-slot ring**
  (`DAT_00ed55d4[]`, count `DAT_01175d68`, cursor `DAT_01175d6c & 7`), one lump/tick, into
  `FUN_00502960` (ambient ped/traffic placement, 4 categories, road query `FUN_004dc990`) then
  `FUN_005002b0` (SceneObject-pool consumer).
  - **Discrepancy to confirm-live:** kept-ring capacity **64 (Xbox) vs 8 (PC)**. Either PC shrank
    the ring for the smaller PC memory budget, or the PC 8-slot ring is a *different* stage
    (per-frame lump cursor) and the 64-slot kept store lives elsewhere. Break on the writer of
    `DAT_00ed55d4`/`DAT_01175d68` to settle it.
- A **"lump"** = one kept-population record in the **0xBC-byte** spawn-record format (the same
  format used by the 32-slot deferred-instantiate queue `@0x837D39A8` on Xbox).

---

## 6. Simple-spawner families + spawn workers (H core)

**UpdateSimpleSpawners: Xbox `FUN_82338768` ↔ PC `FUN_004e4100`.** Both dispatch **four** family
updaters — PC `FUN_004e4100`: return if Net.IsClient (`0xDFBD77`), pending-owner poll `0x4e4460`, then
Window / NoModel / Hardpoint / Path with the same dt, no other branch (the Xbox function's hash
constants are profiler scope markers, ring `0x83E1DA10`, not flags) — each walking its family's list of **active
runtime spawners** (pointers into the 256-slot pool, not pending requests):

| Xbox family | Xbox fn | Xbox list | PC proc | PC creator | PC active list / count / cap |
|---|---|---|---|---|---|
| WindowSpawners | `FUN_82335c00` | `0x82C1F488` | `FUN_004e1590` (1107 B) | `FUN_004e4c50` | `DAT_00dccb00` / `DAT_00dcce24` / **200** (`DAT_00dcce28`) |
| NoModelSpawners | `FUN_823370a8` | `0x82C1F7B8` | `FUN_004e1ad0` (640 B) | `FUN_004e4e50` | `DAT_00dcce30` / `DAT_00dccfc4` / **100** (`DAT_00dccfc8`) |
| HardpointSpawners | `FUN_82337958` | `0x82C1F958` | `FUN_004e2110` (870 B) | `FUN_004e5090` | `DAT_00dccfd0` / `DAT_00dcd2f4` / **200** (`DAT_00dcd2f8`) |
| PathSpawners | `FUN_82337498` | `0x82C1FC88` | `FUN_004e1d50` (950 B) | `FUN_004e4f70` | `DAT_00dcd300` / `DAT_00dcd404` / **64** (`DAT_00dcd408`) |

The caps are static `.data` (one read-only reference each: `0x4e4c87`, `0x4e4e6b`, `0x4e50db`,
`0x4e4f8b`; same values in the untouched v1.1 exe and live in every capture) and each creator bails
when its list is full. The Xbox arrays have the same sizes. The family↔list pairing is proven by the
creators (each fills one list) and by live data (all 54 mid-mission spawners sit in the list of
their record's family).

Function-level specifications of every piece below (activation, tweaks, the four families, the
shared helpers): [`population_spawner/`](population_spawner/README.md).

**Lifecycle (PC, audited twice 2026-10-21; Xbox `FUN_82338330` / PS3 twins).** A placed record is
inert; a runtime spawner exists only after
- **(A) its owner goes live:** the owner's activation begin — the PopulationSimpleSpawner /
  DangerousBuilding activation listeners (indices 71 / 73 of the array `0xED3D20`, vtables `0xBCCB38` /
  `0xBCCAF0`, slot `+0xC` `0x66B5C0` → `0x4e5590` → `0x59E830`; `hibernation_grid.md` §6a) — queues
  the owner on a pending list (`0x16D6970`, cap 900); each frame `FUN_004e4100` polls it (`0x4e4460`)
  and on readiness 2 (`0x4e43c0`: owner SceneObject state 2 and its Path/model resources ready) walks the owner's own records, then its template's (`FUN_00649a80`:
  when the owner's rows run out, `0x649af1`, it re-keys the walk on `SceneObject+0x14` =
  `Transform.Parent`, `0x649b0a–0x649b1b`, once — a template key has bit 31 set, so it never hops
  again), then its `DangerousBuilding`-linked entity's — through
  `FUN_004e48d0` / `FUN_004e4620` to the activators `0x248E940` / `0x2928000`, gated by DefaultState
  (or the owner's SpawnerAdjust state for the group), uniqueness (owner, SpawnerName)
  `FUN_004e4af0` and the ChanceNotActive roll `FUN_004e2480`; `0x248E940` also needs the HardPoint
  to resolve (`FUN_006886a0`). Readiness 0 releases the owner's spawners (`0x4e54f0`).
- **(B) a script tweak:** `Ai.TweakAttachedSpawners` / `…InGroup` → `FUN_004e2d80` (merges into the
  owner's stored SpawnerAdjust; acts only when the owner is live) → `FUN_004e32b0` → the creators.
Distance never creates a spawner. A spawner returns to the pool on state 0, owner gone or
cache-out, `FUN_004e3dd0 ≤ 0` (Window/Hardpoint), Hardpoint owner's physics actor reporting true
on vtable `+0x9c` (only Car `0xBA94A0` → `0x437280`, value < 0.5, and Prop `0xBA9C28` → `0x43ce80`,
tilted past up-dot 0.87, override it; the other 13 return false), a −1 unit choice
(`FUN_004e0e80` / `FUN_004e0eb0` / `FUN_004e0f20`), its group tweaked off, or state 5 once its unit is
gone (Window/NoModel/Hardpoint; a Path spawner at state 5 stays listed).

Shared spawner constants (**both builds**): **≤8 groups** (PC `spawner+0x8b < 8`; Xbox 8-group bit
loop). **25600 = 160²** (`DAT_00d1e410`) gates only the post-spawn event `0x7962CAF5` (nearest-camera
XZ distance² from `FUN_00505e90`); activation is ActiveRadius² by SpawnerRadiusType (`FUN_004e38d0`).

**PC runtime spawner (148 B / `0x94`)**, written by init `FUN_004e2840(record)` (`eax` = owner),
called by the four creators `FUN_004e4c50` → Window queue `DAT_00DCCB00`, `FUN_004e4e50` → NoModel
`DAT_00DCCE30`, `FUN_004e4f70` → Path `DAT_00DCD300`, `FUN_004e5090` → Hardpoint `DAT_00DCCFD0`. The
dispatchers `FUN_004e32b0` / `FUN_004e3130` pick the creator from record `+0x64` IgnoreModel, `+0x68`
WindowSpawner, `+0x63` PathCount. Audited 2026-10-21 against the disassembly and all 54 live spawners
of `updated-chris-exports/…mid-mission` (each matched to its source record):

| off | written from | meaning |
|---|---|---|
| `+0x00..0x1f` | record Position | (Window: xyz offset by constants, `0x4e2b71`) |
| `+0x20` | record `+0x20` SpawnerName | a designer name hash, not unique ("A", "AA" live); identity = (`+0x24`, `+0x20`), deduped by `FUN_004e4af0` |
| `+0x24` | creator's owner argument | owner object; `FUN_004e3dd0` reads its `RuntimeHealth` / `RuntimeNodeHealth` |
| `+0x28` / `+0x30` / `+0x34` / `+0x3c` | record HardPoint / Door / SquadName / WakeupEffect | hashes |
| `+0x2c` | record `+0x2C` UnitList | list key; SpawnerAdjust overwrites it (`0x4e3623`) |
| `+0x38` | owner's `Path` component, else 0 | |
| `+0x40` | 0 | the spawned unit (`0x4e1a1b`) |
| `+0x44` | 8-slot unit array (pool `0xdcc5e0`) when PathCount > 0, else 0 | |
| `+0x48` | -1 (IgnoreModel, NoModel/Path), or `FUN_004df5d0(owner, HardPoint)` (Window/Hardpoint; may be 0) | node-health key of the HardPoint node's nearest ancestor |
| `+0x4c` | 0, -1 (IgnoreModel), Hardpoint: `FUN_004df4f0(owner, HardPoint)` | |
| `+0x5c` | 0.0 | spawn-cycle countdown: `-= dt` (`FUN_004e11f0`), reloaded from `+0x6c` each cycle |
| `+0x60` | WakeupFixedCountdown + U[0,1)·WakeupRandomCountdown | one-shot wakeup countdown (fires `FUN_004e0ca0`); 0.01 after a failed placement |
| `+0x64` / `+0x68` | 0.0 | float timers (`FUN_004e0c00`) |
| `+0x6c` | record SecondsPerCycle | |
| `+0x70` / `+0x74` | record EscapeRadius / ActiveRadius | the radii |
| `+0x78` / `+0x7c` / `+0x80` | record SkipPercentChance / ChanceNotActive / ChanceToDeactivate × 0.01 (`DAT_00b97eec`) | probabilities; `+0x78` vs an LCG draw in `FUN_004e2770`, gated by MaxSkips/MaxNoSkips |
| `+0x84` | record PathSpacing | |
| `+0x88` / `+0x8a` / `+0x8d` | record SpawnerRadiusType / SpawnerType / PathCount | |
| `+0x89` | record DefaultState | state: 0 returns the spawner to the free pool (`0x4e15fd`, `0x4e1b0c`, `0x4e1d9e`); 5 = no further spawns, still queued (`0x4e1deb`); SpawnerAdjust rewrites it per group |
| `+0x8b` | record `+0x58` SpawnerGroup | group |
| `+0x8c` | (not written by init) | latch: the `+0x84` ramp reached 1.0 (`0x4e1636`) |
| `+0x8e` | record `+0x48` UnitListWeighting | the `FUN_004e4150` switch selector |
| `+0x8f` / `+0x90` | min(MaxSkips, 100) / min(MaxNoSkips, 100) | |
| `+0x91` / `+0x92` | 0 | skip / no-skip run counters |
| `+0x93` | flags | bit0 IgnoreModel, bit1 WindowSpawner, bit3 TrafficSpawner, bit4 owner has `AiPatrol`, bit5 PathCount > 0 |

`+0x63`, `+0x64` and `+0x68` are **record** offsets (PathCount, IgnoreModel, WindowSpawner) — at
runtime `+0x63` is the top byte of the `+0x60` float.

**PopulationSimpleSpawner is a class-manager, not a flat descriptor** — which is why it never
appeared in the 231-class registry TSVs. PC manager `@0x00DF8510` (vtable `0x00BC03C0`, static ctor
`FUN_00a7afc0`), instance list head `PTR_PTR_00df855c`, iterate `FUN_006499f0(&mgr,1,1)` +
`FUN_00649a80`, per-owner record walkers `FUN_004e4620`/`FUN_004e48d0` (§6 lifecycle), field
walker `FUN_00660be0`.
Xbox component ctor `PopulationSimpleSpawner@0x8251dda0` (vtable `0x82040678`). Pool cap **768**
(`cdbsizes.ini`, both builds).

**Spawn pipeline (PC).** `FUN_004e1590` → eligibility chain (`FUN_004e3dd0` score →
`FUN_004e0c00`/`FUN_004e0f50` → `FUN_00665af0` SceneObject resolve → `FUN_004e38d0` position/radius)
→ build params `FUN_004e3cd0` → **`FUN_004e4150` = SpawnUnitInstantiate**; posts spawn event
`FUN_004b7ab0(0x7962caf5, objId, …)`; keeps last 8 spawns in `DAT_016e47c0`. The heavier
**`FUN_004b4590`** (3600 B) is the QueuedSpawning/SpawningUnits drain: view-edge transform
(`FUN_004b3d90` atan2), 0x58-byte request filled by `FUN_004b53c0` (LCG), allocated from request
pool `PTR_DAT_00edbac0`, name→registry via `DAT_00df6b24/28` (the `0xDF6B88` family →
[[name-registry-spawn-by-hash]]), request vtable `&PTR_PTR_00df8910`. **The terminal spawn worker
`0x24F3200` routes through the SecuROM VM dispatcher `FUN_02a30028`** — but the `Pg.Spawn` driver
`FUN_005d5d20` (739 B) is **fully decompiled**; only the terminal commit is VM-dispatched, **read live
in the unpacked image** ([[securom-decompiled-not-a-blocker]]), NOT a wall.

### 6.1 Which unit a spawner spawns (`FUN_004e4150`)

The `PopulationSimpleSpawner` record (112 B; field names from its `schm` through the rainbow table,
`mercs2_probe we-template --class PopulationSimpleSpawner`) names its list and its choice rule:
`UnitList` `+0x2C` (a `PopulationList` key) and `UnitListWeighting` `+0x48` (`SpawnerWeightTypeEnum`).
A `PopulationList` record is `{UnitId, ProbabilityWeight}` (Hash, Int), one per entry of a list key —
e.g. "Spawnlist (Guerilla Ground)" `0x8000720A` holds five templates weighted 4/2/2/1/2.

`FUN_004e4150` switches on the weighting (jump table `0x004E4388`):

| `SpawnerWeightTypeEnum` | handler | rule |
|---|---|---|
| None (0), AutoSquadComposition (11) | `FUN_004e8730` | `units[draw % n]` over the runtime list — weights ignored |
| Simple (1) | `FUN_004e8e10` → `0x0247AB90` | `r = draw % Σmax(w,1)` (unsigned); first unit whose running `max(w,1)` sum is `>= r` (signed), else the last — unreachable, as the sum ends at `Σ > r`. So unit 0 owns `max(w0,1)+1` outcomes and the last unit `max(w,1)−1`: a last unit of weight ≤ 1 never spawns. Same body in the demo build behind a plain forwarder (`0x4E93B0` → `0x024F70D0`), and in Xbox profile `0x8233d270`, Xbox retail `0x82243dd4`, PS3 `0x003b9a50` |
| Exhaustive (2) | `FUN_004e8a90(list, bag)` → `FUN_004e8ab0` | bag keyed by the spawner's `+0x24`: one slot per entry (data order) holding `max(w,1)`; `r = draw % Σremaining`; the slot whose running sum exceeds `r` loses one; an empty bag refills |
| ExhaustiveOnce (3) | same | as Exhaustive; a result `<= 0` **as a signed int** ends the spawn (`-1`) — so a level template key (`0x8…`, top bit set) never spawns through it |
| ExhaustiveGlobal (4) | `FUN_004e8a90(list, list)` | as Exhaustive with the bag keyed by the list itself |
| HealthHigh (5) | `FUN_004e8ed0` → `FUN_004e88b0` | `t = health × 100` (`DAT_00B92870`); `c` = last index with weight `<= t`; `c == 0` → that unit, else `units[draw % c]` |
| HealthLow (6) | → `FUN_004e8920` | the `k` units with weight `> t`; `units[n − 1 − draw % k]` |
| HealthBucket (7) | → `FUN_004e8790` | `c` as HealthHigh; `c == 0` → that unit; else one of the run of equal weights ending at `c` |
| HealthBucketLow (8) | → `FUN_004e8820` | `l` = first index with weight `> t`; `l == n − 1` → that unit; else one of the run of equal weights starting at `l` |
| MiniBoss, MiniBossLinked (9, 10) | — | spawns nothing |

`draw` is the global random state's two-step value `(x & 0xFFFF0000) | (u >> 16)` (`DAT_00DFCBAC`).
A Health rule with no weight on the needed side of `t` spawns nothing, without a draw. A chosen unit
of 0 spawns nothing (`0x004E4209`); so does a spawner whose `+0x24` is 0 (checked before the switch)
or whose list is 0 (`FUN_004e8510` finds no runtime list).

**The runtime spawner** (`ESI`/`EDI` in these functions) is not the 112-byte `PopulationSimpleSpawner`
record but a separate 148-byte (`0x94`) struct from a pool of 256 (free list `DAT_00DCC6F0`, count
`DAT_00DCCAF4`; the per-category active queues `DAT_00DCCE30` / `DAT_00DCCFD0` / `DAT_00DCD300`).
In the `updated-chris-exports/…mid-mission` capture: `+0x24` a small object id (`0x0013C338`), `+0x2C`
the UnitList key, `+0x48` either `-1` or a hash (`0x5E3BCF7B`). Which record fields fill `+0x24` and
`+0x48` is not traced.

**Health source `FUN_004e3dd0`** (disassembled from the unpacked image; returns in `xmm0`): no spawner
→ 0. If `+0x48 == -1`: the owner's (`+0x24`) `RuntimeHealth` (container `0x017BEF78`, `{f32 max, f32
cur, …}`) → `cur / max` clamped to `0..=1`; no component or `max < 1e-4` (`DAT_00B977F8`) → 0. Else: the
owner's `RuntimeNodeHealth` (`0x017BEFC8`) → node `FUN_00435140(+0x48)` → u16 `max` `+4`, u16 `cur`
`+6`, the same clamp and floor.

The runtime list (`FUN_004e8510` cache → `FUN_004e83f0` build, at most 64 entries, table
`0x016E51F0` stride `0x24`, count `DAT_01175D18`) is `{key, n, Σmax(w,1), units*, weights*, next}`
(`FUN_004e8130`), its arrays sorted ascending by weight by `FUN_004dc870` — an iterative quicksort
(stack of `(hi, lo)` pairs, Hoare partition on the middle element, left range first) handing ranges
shorter than 8 to an insertion sort (`FUN_00685df0` → `0x00630D50`). Equal weights therefore keep
data order only on short lists. All 30 runtime lists of the four `updated-chris-exports` captures
equal the lists built this way (`mercs2_probe dump-spawnlists`; test
`live_unit_lists_match_the_built_lists`). Implementation: `mercs2_formats::unit_list` (lists and rules),
`mercs2_population::units` (bags, the choice), `mercs2_engine::runtime::spawner_owner_health` (the
`+0x48 == -1` health branch; the reimpl keys a spawner's owner by the placement entity key carrying
its `PopulationSimpleSpawner` record).

---

## 7. Lua binding surface (both builds — walked from the `.rdata` binding tables)

PC cfunc VAs recovered by walking the Ai/Pg name-string→cfunc-pointer tables in the unpacked exe
(validated against known `Pg.Spawn = 0x005D5D20`). Xbox VAs from the Xbox `.rdata` binding tables.

| Lua API | Namespace | Xbox fn | PC cfunc | native worker (PC) |
|---|---|---|---|---|
| `SetSpawnList` | `Ai` | `0x82427250` | `0x005A5180` | `FUN_004e85f0` (→ wave director `DAT_016e4fe8`) |
| `GetSpawnList` | `Ai` | `0x82424D70` | `0x005A4EA0` | (undecompiled — Ghidra-missed) |
| `GetSpawnListChangeInfo` | `Ai` | `0x82427130` (≤64 rows) | `0x005A5010` | — |
| `ClearSpawnListChanges` | `Ai` | `0x82424ED8` | `FUN_005A56F0` | `FUN_004e8560/8640/8270` |
| `ResetAllSpawnLists` | `Ai` | `0x82425000` | `0x005A5860` | `FUN_004e8210` |
| `TweakAttachedSpawners` | `Ai` | `0x82424BE8` | `FUN_005A4C40` | `FUN_004e2d80` |
| `TweakAttachedSpawnersInGroup` | `Ai` | `0x82424C68` | `FUN_005A4D10` | `FUN_004e2d80` |
| `ShowObjectSpawners` | `Ai` | `0x82424B98` | `0x006D5640` | **stub** (debug-stripped) |
| `SetRoad/Sidewalk/TrafficSpawning`, `SetLaneActive` | `Ai` | `0x8242598x`/`0x82425A3x` | `0x006D5640` | **stub** |
| `StartHeliWaveSpawner` | `Pg` | `0x824520F0` (≤15 waves) | `0x005DA4D0` | `FUN_005da350`→`FUN_005da1b0`→`FUN_0059eef0`; `FUN_004dc700` |
| `StopHeliWaveSpawner` | `Pg` | `0x824503D0` | `0x005DA790` | `FUN_004dc700` |
| `SetSkirmishTable` | `Pg` | `0x82451AA8` (≤0x40 rows) | `0x005D9CC0` | — |
| `AddSkirmishTemplate` | `Pg` | `0x82451D10` (≤8) | `0x005DA010` | — |
| `SetGlobalSkirmishState` | `Pg` | `0x82450320` | `0x005DA130` | flag + `FUN_...` |
| `Spawn` / `SpawnRelative` / `SpawnFromCamera` | `Pg` | — | `0x5D5D20`/`0x5D58D0`/`0x5D6010` | worker SecuROM-thunked |
| `SpawnPlayer` / `SpawnPlayerAdvanced` | `Pg` | — | `0x5D6740`/`0x5D6800` | — |
| `CheckSpawnPos` / `GetDistantSpawnPointOnPath` | `Pg` | — | `0x5DB6A0`/`0x5D7EA0` | — |

**Spawn-list overrides** (PC `Ai.SetSpawnList` cfunc `0x5A5180` → `FUN_004E85F0` → `FUN_004E82C0`;
Xbox retail `FUN_8230D910` → `FUN_82249098`, PS3 `FUN_00511358` → `FUN_003BC1C8`). There is no change
log. `Ai.SetSpawnList(sName, hList, bReplace, {[hUnit]=weight, …})` pushes an override node
`{id = Hash_String(sName), n, Σmax(w,1), units, weights, next}` onto the list entry's head; only the
head is effective (None/AutoSquad `0x4E873E`, Simple `0x247ABB5`, Health* `0x4E8EDE` read it), while the
Exhaustive bags fill from the `PopulationList` data directly (`FUN_004E89A0`). An existing id is
re-initialised in place (`bReplace` false) or unlinked and re-pushed (`bReplace` true).
`Ai.ResetAllSpawnLists` (`0x5A5860`) pops every override; `Ai.ClearSpawnListChanges(sId?, hList?)`
(`0x5A56F0`) clears one list, one id everywhere, or one id on one list; `Ai.GetSpawnListChangeInfo`
(`0x5A5010`) returns the chain's ids (clamped to `0x40`) and the unclamped count; `Ai.GetSpawnList(hList,
idx)` returns `{{unit, weight}, …}`. No shipped Lua (base, DLC, Xbox) calls any of them, and every live
capture has `head == entry+8`.

**Runtime list table:** 256 entries (`0x016E51F0`, stride `0x24`, count `DAT_01175D18`, key map
`0x016E79F8` / `0x016E75F8`), built lazily on first lookup (`FUN_004E8510`), never reset; a 257th list
or a list with no records is not built and head-reading rules spawn nothing (`cmp ecx,0x100`
`0x4E84BD`; Xbox `FUN_8233C7D0`, PS3 `FUN_003B8AB0`). At most 64 entries per list (`cmp edi,0x40`
`0x4E8428`; later entries dropped). Shipped data: 279 list keys, the largest 31 entries.

**Script usage (shipped Lua).** `Ai.TweakAttachedSpawners{SpawnerState=…}` and
`…InGroup{SpawnList=…}` are used heavily (`docs/mercs2-luacd/src/vz/gurcon002.lua:538`,
`resident/dangerousbuilding.lua:415`); `Pg.StartHeliWaveSpawner`/`StopHeliWaveSpawner` at
`vz/pmccon003.lua:1028/298`; `Ai.LivingWorld` at `resident/mrxfollow.lua:59`. The
`Set/GetSpawnList` family is engine-exposed but has **no shipped call sites** (mission scripts drive
lists through `TweakAttachedSpawners` instead). DLC Lua uses **zero** population API.

**Cfunc bodies to recover by disassembling the VA** (binding-table-only refs — Ghidra had no static
caller to walk from, so it never formed a function; the bytes are ordinary `.text`):
`0x5A4EA0`, `0x5A5010`, `0x5A5180`, `0x5A5860`, `0x5DA4D0`, `0x5DA790`, `0x5D9CC0`, `0x5DA010`,
`0x5DA130`.

> **Corrected 2026-07-26.** This previously read *"recover via a Ghidra script … same as the
> `DecompileProfileAccessors.java` precedent"*. No forcing script is needed: **all nine** of these
> VAs disassemble cleanly (e.g. `0x5A4EA0` = `83 ec 0c 53 8b 5c …`, 27 instructions to a tail-`jmp`;
> `0x5D9CC0` runs 86 to a `ret`). See `ghidra_knowledge_inventory.md` Part F.4.

---

## 8. Tick registration & scheduler-doc correction

- Population is inside the **layer-4 game-mode Update**. PC layer-4 vtable `+0xc` → `FUN_004c0ec0`
  → **`FUN_004c9740`** (1448 B) is the entire per-system call list; population sits at
  `FUN_004c9740+0x230` (`FUN_00502510`), and the post-update spawn drain `FUN_004b4590` later in the
  same list. This **statically resolves** `scheduler_tick_code_map.md`'s confirm-live item #1 for
  the population slot: the intra-layer order is the literal `FUN_004c9740` call sequence, not
  vtable-dispatched for these systems. Shutdown corroborates: WinMain `FUN_00631670` →
  `FUN_004c13a0` → `FUN_004c09c0` → `FUN_004c0ec0`.
- **Xbox** registration: ctor `PgSysPopulation @0x823641F0` drops the name into a 16-slot queue
  `@0x83109CB0` (`FUN_822073b8` → `DAT_83793dd0`) and a 32-slot queue `@0x830F9828`
  (`FUN_822ed8c0` → `DAT_83793dd4`), then appends `OnEntityDeleted` (`FUN_82364058`) to the
  on-delete array. The Update itself is registered via the system descriptor block `@0x82020548`
  (7 code ptrs: init/reset/registerstats/…) and ticked by `FUN_822ff9b0`.

---

## 9. Data / pool constants (marriage anchors, both builds)

| Thing | Value | Source |
|---|---|---|
| `PopulationSimpleSpawner` pool | **768** | `cdbsizes.ini`, both builds |
| `PopulationList` pool | **1024** | `cdbsizes.ini` |
| `PopulationDensity` / `Flow` / `DynamicRoad` pools | 128/64, 192/64, 32/32 | `cdbsizes.ini` |
| `SkirmishSpawnList` / `SpawnerAdjust` pools | 16/16 each | `cdbsizes.ini` |
| `SpawnOnDeath` pool | 384/128 | PC image strings |
| Spawner type discriminators | **4** categories (`SimpleSpawnerTypeEnum` = 4) | both |
| Spawner groups | **8** | both (bit loop) |
| Active spawners per family | Window **200**, NoModel **100**, Hardpoint **200**, Path **64**; pool **256** | PC `DAT_00dcc*`; Xbox 4 family lists |
| DeathCheck budget | **20/frame** | Xbox `li 0x14`; PC round-robin |
| DensityUpdate budgets | 10/10/2/2 (people far/near, veh far/near) | Xbox `FUN_82367d28` |
| Kept/cache ring | 64 (Xbox) / 8 (PC) — **confirm-live** | §5 |
| Deferred-instantiate queue | 32 × 0xBC bytes | Xbox `@0x837D39A8` |
| Runtime list table / entries per list | 256 / 64 | PC `0x4E84BD` / `0x4E8428`; Xbox, PS3 |
| `GetSpawnListChangeInfo` id clamp | 64 | PC `0x5A5010`; Xbox, PS3 |
| Heli waves | ≤15 | Xbox `StartHeliWaveSpawner` |
| Faction table | skips types **7 & 8** | Xbox density loop |
| Spawn event hash | `0x7962caf5` | PC `FUN_004b7ab0` |
| Density-decay op | `>>1 & 0x7f7f7f7f` | PC `FUN_004e0510` |
| Spawner chance scale (`+0x78/+0x7c/+0x80`) | `DAT_00b97eec` = 0.01 | PC |
| vz_state overlay carrier | COMP type 3 = PopulationSimpleSpawner definitions | `docs/vz_state_analysis.md` |

Spawn-list faction abbreviations (both builds): **VZ / Pir / Oil / Gur / Chi / Ali / Ped**
(+ `VehicleSpawnList`). Data-value keys used by scripts: `"Spawnlist (VZ Ground)"`, `"(VZ AA)"`,
`"(VZ Elite)"`, `"(VZ Balcony)"`, `"(VZ Tower)"`, `"(Guerilla Ground)"`.

---

## 10. Confirm-live (x32dbg, read-only while PAUSED — [[x32dbg-mcp-no-resume]])

1. **SecuROM thunks** in the spawn path: `0x24F3200` (spawn worker), `thunk_FUN_024e3910` (gather
   attached spawners), `thunk_FUN_024f0090`/`024f0060` (group despawn = probable CacheOut workers),
   `thunk_FUN_024f00c0` (pre-update), `thunk_FUN_024e92b0` (spawn-budget), `thunk_FUN_024e2ce0`
   (queue pop). Break + read the unpacked bodies live.
2. **PC family↔queue order** (Window/Hardpoint/Path/NoModel ↔ the four `DAT_00dcc*` queues) — §6.
3. **Kept-ring capacity 64 vs 8** — writer of `DAT_00ed55d4`/`DAT_01175d68` — §5.
4. **Death distance constants** on PC — confirm the 50²…400² table against Xbox `FUN_8235efc0`.
5. **`FUN_0048e550`** identity (population cache-lump builder vs generic streaming/hibernation) —
   break on entry, inspect `param_1`.
6. Recover the 9 binding-table-only cfunc bodies (§7) with a Ghidra decompile-forcing script.

---

## 11. Reconciliation with `mercs2_engine` (scoreboard row 24 = ❌)

The engine has **no** population layer today (streaming only wakes pre-placed entities). This map
now gives a faithful reimplementation target with the design fully specified from both builds:

- **A `PopulationSystem` in `mercs2_core`** ticked from the fixed `Schedule` (the layer-4 slot),
  mirroring the `FUN_00502510` fan-out: death check/compute → density decay → cache in/out (against
  the existing streaming decision core → [[mercs2-streaming-runtime]]) → simple-spawner families →
  spawn-queue drain.
- **A `PopulationSimpleSpawner` component + manager** (768-cap pool, the `+0x58…+0x8c` field layout,
  4 types × 8 groups, terminal state 5) fed by the vz_state COMP-type-3 records already parsed.
- **Faction spawn lists** (7 factions + vehicles), `TweakAttachedSpawners{SpawnerState/SpawnList}`
  as the primary script-facing lever (matches shipped Lua usage), heli-wave + skirmish as secondary.
- Field schemas for `PopulationDensity/Flow/DynamicRoad/SkirmishSpawnList/SpawnerAdjust` are already
  in `docs/mercs2-ecs/02_ai_perception_population.md`; this doc adds the **runtime** the schemas feed.
