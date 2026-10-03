# Phase 3c — Does the `PopulationSimpleSpawner` 2.67× pool-cap gap translate to on-screen density?

**Question.** Phase 2 §3.4 proved consoles ship `PopulationSimpleSpawner 2048` while PC ships `768`.
PC's `data/cdbsizes.ini:178` confirmed in-tree. Does the ratio produce more NPCs on screen on
consoles, or is it inert because a downstream cap bounds the effective count?

**Verdict (short).** The `2.67×` pool-cap difference is **functionally inert for ambient / on-screen
NPC density**. The pool caps *spawn sources* (one of 4 "attached" spawner families), not NPCs. The
ambient-population and NPC ceilings live in a completely separate chain whose dominant levers are
(a) WAD-authored `PopulationDensity` per-region caps (**identical** across platforms — same vz.wad),
and (b) the `Ai` entity pool (`1024 → 1536`, a `1.5×` platform gap — a different Phase 2 finding, not
this one). `PopulationSimpleSpawner 2048` on consoles raises a *source-residency* ceiling, with no
mechanism to turn more sources into more ambient NPCs because the per-region desired-count and the
Ai pool are the final bottlenecks.

Confidence legend: **PROVEN** = read from the Ghidra decomp this pass. **INFERRED** = consistent with
proven mechanics but not directly measured. **BLOCKER** = requires a live-x32dbg or data-count pass we
did not run.

---

## 1. What `PopulationSimpleSpawner` represents at runtime

**PROVEN** (from `docs/reverse_engineer/population_spawner_code_map.md` §6, which cites the
first-hand reads of the register/unregister bodies I re-pulled from the corpus — functions
`FUN_004e4620` register / `FUN_004e48d0` unregister, manager `@0x00DF8510`, instance-list head
`PTR_PTR_00df855c`, field walker `FUN_00660be0`, vtable `0x00BC03C0`):

- `PopulationSimpleSpawner` is **a class-manager, not a flat ECS descriptor** — the reason it is
  absent from the 231-class flat-registry TSVs. Each live instance is one **simple-spawner source**
  (a per-entity spawn-emitter attached to a building, hardpoint, path, window, or no-model anchor).
- Register path: `FUN_004e4620` allocates a free node from `PTR_DAT_00edbac0`, links it onto
  `PTR_PTR_00df855c`, stamps `obj[5] = &PTR_PTR_00df8510` (manager back-ptr). Unregister =
  `FUN_004e48d0`. Both bodies verified this pass.
- A single spawner carries at `+0x58` a faction / spawn-list index, `+0x5c..+0x6c` an
  interval + countdown + reload timer, `+0x63/+0x64/+0x68` three type discriminators forming the
  4-way family switch (`SimpleSpawnerTypeEnum` = 4 members: Window / Hardpoint / Path / NoModel),
  `+0x78/+0x7c` activation radii (× scale `DAT_00b97eec`), `+0x89` state (`SimpleSpawnerStateEnum`
  terminal state = 5), `+0x8b < 8` group bit, `+0x8c` done flag.
- `UpdateSimpleSpawners` = PC `FUN_004e4100` dispatches 4 family updaters, **each draining its own
  128-cap pending-spawn queue** (`DAT_00dccb00` / `DAT_00dcce30` / `DAT_00dccfd0` / `DAT_00dcd300`
  with 4-byte counts). The 128-cap pending queues are **per-tick request work**, independent of the
  768/2048 pool, and are **not scaled by the pool cap**.

**A `PopulationSimpleSpawner` instance is a spawn-source descriptor; it is not a world NPC.** The
NPCs it emits occupy separate pools downstream (`Ai`, `AiBehavior`, `AiPatrol`, `ControllerCar`).

## 2. Where the pool-cap value is read at runtime

**PROVEN.** From `docs/reverse_engineer/render_distance_and_density_levers.md#18` plus the Ghidra
body `FUN_004c1840` (2377 B, read this pass):

- `FUN_004c1840` is the single boot-time arena-init: at `FUN_004c1b*…` it iterates `cdbsizes.ini`'s
  `[presize]` block via `FUN_00826820`(hash-lookup) / `FUN_00826990`(parse K/M suffix), then calls
  `FUN_0084adc0(start, end, stride, name, count, flag)` once per class to carve one `VirtualAlloc`
  arena into typed sub-pools. "Pools are config-driven, not baked constants: raising a count needs
  no binary patch."
- Component handles are **u16** (free-list heads sign-extended as `short`; e.g. `ControllerCar`
  `FUN_006405a0 → DAT_017bcf9c = 0xffff`), hard ceiling `65535`, so `2048` is width-safe.

So on consoles the pool holds **2048 live simple-spawner source slots**; on PC, **768**. The register
helper (`FUN_004e4620`) refuses an insert when the free list is empty (standard pool failure, no
graceful-degrade logged elsewhere in this chain) — i.e., a 769th simultaneously-resident spawner on
PC would **not** register, and its NPC emission would never start.

## 3. Secondary caps on actual NPC count — the chain that determines on-screen density

**PROVEN** (from `FUN_00502510` read this pass + prior code map §3 + `FUN_005051a0` body read this
pass):

The population tick `FUN_00502510` fans out in this fixed order (one static-call list, no vtable
dispatch for these systems — resolves `scheduler_tick_code_map.md`'s open item):

```
FUN_00500b40 DeathCheck
FUN_004df000 → FUN_004e0510 density-decay (>>1 & 0x7f7f7f7f)
FUN_005017b0 cache-out msg pump (types 3/7/0xB)
FUN_00502fc0 cache-in / KeptPopulation drain
when-active:
  FUN_004d8490 per-player anchor
  FUN_004e4100 UpdateSimpleSpawners  ← drains the 4×128 pending queues
  FUN_004d60e0 per-player region-select → writes DAT_00ed55c8[]/DAT_00ed55b0[]
  FUN_00503020 ambient spawn/despawn driver (3119 B, body unread)
  FUN_00502280 CacheOut round-robin
  FUN_005051a0 DensityUpdate (261 B — verified below)
```

### 3.1 The ambient-NPC ceiling is `max(DAT_00ed55c8[])` / `max(DAT_00ed55b0[])`, not the pool

**PROVEN.** `FUN_005051a0` body (read this pass, verbatim):

```c
iVar2 = DAT_00ed55c8;         // per-player people desired-count array
iVar3 = DAT_00ed55b0;         // per-player vehicles desired-count array
for (iVar1 = 1; iVar1 < DAT_01175d8c; ++iVar1) {
  if (iVar2 <= (&DAT_00ed55c8)[iVar1]) iVar2 = (&DAT_00ed55c8)[iVar1];  // max across players
  if (iVar3 <= (&DAT_00ed55b0)[iVar1]) iVar3 = (&DAT_00ed55b0)[iVar1];
}
if (DAT_00ed558c == 7 || DAT_00ed558c == 8 || (iVar2 < 10 && iVar3 < 5) || ...)
   DAT_01175d70 = 1;           // idle gate — "enough" is 10 peds / 5 veh (imm8 at 0x5051ff / 0x505204)
if (DAT_00ed27b4 == 0 && !idle && DAT_00ed558c != 0) iVar2 *= 2;  // on-foot: 2× peds
iVar2 -= DAT_017610c4;         // deficit = desired - current (current peds)
iVar3 -= DAT_0175d8b0;         // deficit = desired - current (current vehicles)
// per-tick batch 10 (clamp at 0x505263), trickle 2 (clamp at 0x505263)
```

The **ceiling** is the max element of `DAT_00ed55c8[]` / `DAT_00ed55b0[]` (×2 on foot). Those arrays
are written by `FUN_004d60e0` (region-select) from the `PopulationDensity` COMP records streamed in
from `vz.wad`. The 10/5/10/2 immediates in this function only control **fill-rate**, not the cap.

**The authoritative crowd dial lives in WAD data (PopulationDensity.caps[0..4]), consumed per-region
and written into the per-player desired-count arrays.** `data/cdbsizes.ini` sets **pool ceilings only**
(`render_distance_and_density_levers.md` §3, verbatim).

### 3.2 Downstream pools that bound actual NPC-entity count

| Pool | PC | Console (Phase 2) | Platform ratio |
|---|---|---|---|
| `PopulationSimpleSpawner` | 768 | 2048 | **2.67×** (this question) |
| `Ai` (the live NPC entity cap) | 1024 | 1536 | **1.5×** |
| `AiBehavior` | 512 | 512 | 1.0× |
| `AiPatrol` | 768 | 768 | 1.0× |
| `ControllerCar` (AI-driven veh) | 64 | 64 | 1.0× |
| `PopulationList` | 1024 | 1280 | 1.25× |
| `PopulationDensity` | 128 | 128 | 1.0× |
| `PopulationFlow` | 192 | 192 | 1.0× |

**PROVEN** rows from PC `cdbsizes.ini` + Phase 2 context. **PROVEN** that the live NPC count caps
through `Ai` + `ControllerCar`, not through `PopulationSimpleSpawner`: spawner instances emit
request records into `PTR_DAT_00edbac0`-allocated 0x58-byte spawn requests
(`FUN_004b4590`→`FUN_004b53c0`→name→registry resolve via `DAT_00df6b24/28`) that materialise as
NPCs in the `Ai` family.

## 4. Does the 2.67× pool-cap difference translate to on-screen density?

### Mechanism-by-mechanism

- **Ambient civilians / traffic density** — **NOT affected** by the `PopulationSimpleSpawner` pool
  size. These are spawned by the DensityUpdate path (§3.1) off per-region `PopulationDensity.caps`
  stored in `vz.wad`, which is identical across platforms. **PROVEN** that the pool cap does not
  appear in that path.
- **AI-driven traffic cars** — bounded by `ControllerCar 64/64` (same both platforms). **PROVEN**
  (`render_distance_and_density_levers.md` §Ceilings). Can't differ.
- **Combat NPCs emitted by attached (building/hardpoint/path/window) spawners** — gated by the
  `Ai` pool (`1024 → 1536`, a `1.5×` cap, not `2.67×`). Even if consoles can keep `2048` sources
  alive, each source emits into the `Ai` pool, which is `1.5×` bigger. The **effective** combat-NPC
  on-screen cap difference is at best `1.5×` (set by `Ai`), **not** `2.67×` (the simple-spawner
  pool). **INFERRED** from the register-side being `Ai`-bounded; verifying the exact spawn-request
  → `Ai`-slot path requires reading `FUN_004b4590` (3600 B) and `FUN_00503020` (3119 B, body
  unread per the code map).
- **Spawn-SOURCE residency in dense combat zones** — this is where the `2.67×` could matter, but
  only as a **source-count** gap, not an NPC-count gap. If a dense zone (e.g., VZ HQ with its
  `Ground`/`AA`/`Elite`/`Balcony`/`Tower` spawn-list set, or multiple captured outposts stacked)
  authored more than `768` simple-spawners within one streaming-residency bubble, PC would silently
  refuse the overflow at `FUN_004e4620`. Consoles would keep all of them live. **INFERRED**.
  Downstream, both platforms are still bounded by `Ai = 1024/1536`.

### Does the authored data ever actually exceed PC's 768?

**BLOCKER.** I do not have:
1. A static count of concurrently-resident `PopulationSimpleSpawner` COMP records across the live
   mounted vz_state overlay set in a worst-case combat zone (requires a vz_state COMP-type-3 pass —
   `docs/reverse_engineer/render_distance_and_density_levers.md` §3 explicitly flags that **vz_state
   COMP extraction is unimplemented**, which is the tooling gap).
2. A live `FUN_004e4620`-breakpoint capture (hit-count against the pool high-water mark) under a
   PC combat scenario (requires x32dbg, which the user drives; non-interactive here).

Even without those: §3.1 proves PC's effective **ambient**-population ceiling comes from WAD data +
the `Ai` pool, not from this pool. So **source** residency is the only way `2.67×` could matter,
and the downstream clamp is `1.5×` at most.

### Verdict

**The 2.67× `PopulationSimpleSpawner` pool-cap difference is nominal but functionally inert for
on-screen population density.** The pool caps spawn-source slots; the per-screen NPC count is
double-clamped by (a) WAD `PopulationDensity.caps` (identical) and (b) the `Ai` pool (`1.5×`, not
`2.67×`). The pool-cap gap could silently truncate a dense-combat spawner-set on PC — a different
failure mode (missing sources, not missing NPCs) — but the on-screen NPC headcount is bounded
elsewhere.

The honest Phase 3c one-liner: **consoles do not render `2.67×` more NPCs; the real platform NPC
gap tracks the `Ai 1024 → 1536` ratio of `1.5×`, and even that is further clamped by
`vz.wad`-authored `PopulationDensity` caps that are byte-identical across platforms.**

---

## 5. Follow-ups to close the remaining gap (not done here)

1. **Count vz_state COMP-type-3 records**: implement the vz_state COMP extractor flagged open in
   `render_distance_and_density_levers.md` §3; sum per overlay-set to find whether any dense combo
   authors > 768 live simple-spawners. If it never exceeds 768, PC's cap is strictly a size
   budget, not a cap. If it does, that is the proof the pool-cap difference ever bites, and the
   bite is on source-count only.
2. **Decompile `FUN_00503020`** (3119 B, body unread per code map §3) to settle whether the ambient
   driver has any `PopulationSimpleSpawner`-pool-sized bound beyond the per-region desired-count
   path.
3. **Live `FUN_004e4620` breakpoint** in a stacked-outpost PC scenario to measure the pool
   high-water mark empirically (user drives x32dbg).
4. **Compare the DensityUpdate immediates** (`0x5051ff: cmp eax, 10`, `0x505204: cmp edx, 5`,
   `0x50524b: 10`, `0x505263: 10`, `0x50527b: 2`, `0x50528f: 2`) against the console build's
   equivalent — if the "enough" gates or batch/trickle counts are platform-specific, that is a
   separate density lever not caught by cdbsizes alone.
