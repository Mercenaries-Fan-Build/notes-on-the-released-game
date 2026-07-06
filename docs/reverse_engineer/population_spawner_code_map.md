# Population / Spawner system (`PgSysPopulation`) — Xbox↔PC code map

**Scope:** the ambient-population + spawner system (scoreboard row 24). This marries the **Xbox
360 devkit (Jul-08 Profile build)** symbol/PDB ground truth to the **PC retail decompilation**
(`Mercenaries2.exe`, unpacked image, base `0x400000`). The PC retail build strips every
`PgSysPopulation::` profiler string, so the runtime bodies had no string anchor — they are married
here **structurally**, by shared constants, call-tree shape, message-type switches, and the Lua
binding tables.

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
| **UpdateSimpleSpawners** (4 families) | `FUN_82338768` | **`FUN_004e4100`** → 4 procs | 4 family updaters, each cap-128 queue, spawner terminal state **5**, `OccupiedBuildingSpawnCallback` | H |
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
updaters, each gated by its own tunable-hash flag, each draining a **128-cap** queue:

| Xbox family | Xbox fn | Xbox list | PC proc | PC queue (cap 0x80) |
|---|---|---|---|---|
| WindowSpawners | `FUN_82335c00` | `0x82C1F488` | `FUN_004e1590` (1107 B) | `DAT_00dccb00` / cnt `DAT_00dcce24` |
| NoModelSpawners | `FUN_823370a8` | `0x82C1F7B8` | `FUN_004e1ad0` (640 B) | `DAT_00dcce30` / cnt `DAT_00dccfc4` |
| HardpointSpawners | `FUN_82337958` | `0x82C1F958` | `FUN_004e2110` (870 B) | `DAT_00dccfd0` / cnt `DAT_00dcd2f4` |
| PathSpawners | `FUN_82337498` | `0x82C1FC88` | `FUN_004e1d50` (950 B) | `DAT_00dcd300` / cnt `DAT_00dcd404` |

> The **PC family↔queue mapping order is unproven** — the four PC procs are structurally
> interchangeable; the pairing above is by size/position, not proof. Confirm which queue holds
> window vs hardpoint vs path vs nomodel live. (Xbox `FUN_82335c00` = Window is anchored by its
> `'Have %d window Spawners'` debug string + the `OccupiedBuildingSpawnCallback` dispatch, so PC's
> `FUN_004e1590` — the only one whose chain reaches the occupied-building callback — is the safest
> Window match.)

Shared spawner constants (**both builds**): terminal **state byte = 5** (`SimpleSpawnerStateEnum`
has 5 members; PC `spawner+0x89 == 5` ⇒ exhausted/removed), **≤8 groups** (PC `spawner+0x8b < 8`;
Xbox 8-group bit loop), Window radius² = **25600 = 160²**. PC spawner instance layout (from the
consumers): `+0x20` guid, `+0x2c` adjust-target, `+0x58` faction/list index, `+0x5c`/`+0x60`/`+0x6c`
interval+countdown+reload, `+0x63`/`+0x64`/`+0x68` the 3 type discriminators → 4 categories,
`+0x78`/`+0x7c` radii (× scale `DAT_00b97eec`), `+0x89` state, `+0x8b` group, `+0x8c` done.

**PopulationSimpleSpawner is a class-manager, not a flat descriptor** — which is why it never
appeared in the 231-class registry TSVs. PC manager `@0x00DF8510` (vtable `0x00BC03C0`, static ctor
`FUN_00a7afc0`), instance list head `PTR_PTR_00df855c`, iterate `FUN_006499f0(&mgr,1,1)` +
`FUN_00649a80`, register/unregister `FUN_004e4620`/`FUN_004e48d0`, field walker `FUN_00660be0`.
Xbox component ctor `PopulationSimpleSpawner@0x8251dda0` (vtable `0x82040678`). Pool cap **768**
(`cdbsizes.ini`, both builds).

**Spawn pipeline (PC).** `FUN_004e1590` → eligibility chain (`FUN_004e3dd0` score →
`FUN_004e0c00`/`FUN_004e0f50` → `FUN_00665af0` SceneObject resolve → `FUN_004e38d0` position/radius)
→ build params `FUN_004e3cd0` → **`FUN_004e4150` = SpawnUnitInstantiate**; posts spawn event
`FUN_004b7ab0(0x7962caf5, objId, …)`; keeps last 8 spawns in `DAT_016e47c0`. The heavier
**`FUN_004b4590`** (3600 B) is the QueuedSpawning/SpawningUnits drain: view-edge transform
(`FUN_004b3d90` atan2), 0x58-byte request filled by `FUN_004b53c0` (LCG), allocated from request
pool `PTR_DAT_00edbac0`, name→registry via `DAT_00df6b24/28` (the `0xDF6B88` family →
[[name-registry-spawn-by-hash]]), request vtable `&PTR_PTR_00df8910`. **The terminal spawn worker is
SecuROM-thunked (`0x24F3200`)** — same wall as `Pg.Spawn`; confirm-live only.

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

**Change-log capacities match:** Xbox spawn-list change log = **0x100 (256)** entries, change-query
out = **0x40 (64)** rows; the PC `SetSpawnList`/`GetSpawnListChangeInfo` pair carries the same
256/64 shape (confirm the exact PC constants when the undecompiled cfunc bodies are recovered).

**Script usage (shipped Lua).** `Ai.TweakAttachedSpawners{SpawnerState=…}` and
`…InGroup{SpawnList=…}` are used heavily (`docs/mercs2-luacd/src/vz/gurcon002.lua:538`,
`resident/dangerousbuilding.lua:415`); `Pg.StartHeliWaveSpawner`/`StopHeliWaveSpawner` at
`vz/pmccon003.lua:1028/298`; `Ai.LivingWorld` at `resident/mrxfollow.lua:59`. The
`Set/GetSpawnList` family is engine-exposed but has **no shipped call sites** (mission scripts drive
lists through `TweakAttachedSpawners` instead). DLC Lua uses **zero** population API.

**Cfunc bodies to recover via a Ghidra script** (binding-table-only refs, same as the
`DecompileProfileAccessors.java` precedent): `0x5A4EA0`, `0x5A5010`, `0x5A5180`, `0x5A5860`,
`0x5DA4D0`, `0x5DA790`, `0x5D9CC0`, `0x5DA010`, `0x5DA130`.

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
| Simple-spawner terminal state | **5** (`SimpleSpawnerStateEnum` = 5 members) | both |
| Spawner type discriminators | **4** categories (`SimpleSpawnerTypeEnum` = 4) | both |
| Spawner groups | **8** | both (bit loop) |
| Pending-spawn queues | **4 × cap 128** | PC `DAT_00dcc*`; Xbox 4 family lists |
| DeathCheck budget | **20/frame** | Xbox `li 0x14`; PC round-robin |
| DensityUpdate budgets | 10/10/2/2 (people far/near, veh far/near) | Xbox `FUN_82367d28` |
| Kept/cache ring | 64 (Xbox) / 8 (PC) — **confirm-live** | §5 |
| Deferred-instantiate queue | 32 × 0xBC bytes | Xbox `@0x837D39A8` |
| Spawn-list change log / query | 256 / 64 | Xbox; PC shape matches |
| Heli waves | ≤15 | Xbox `StartHeliWaveSpawner` |
| Faction table | skips types **7 & 8** | Xbox density loop |
| Spawn event hash | `0x7962caf5` | PC `FUN_004b7ab0` |
| Density-decay op | `>>1 & 0x7f7f7f7f` | PC `FUN_004e0510` |
| Spawner radius scale | `DAT_00b97eec` | PC |
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
