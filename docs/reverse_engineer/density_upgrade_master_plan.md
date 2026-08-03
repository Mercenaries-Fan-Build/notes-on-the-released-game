---
name: density_upgrade_master_plan
description: Unified surgical-upgrade plan (3-architect panel synthesis) to make the retail Mercs2 engine handle JC2-scale vegetation + crowd density. Root cause pinned to the byte; procedural per-cell veg + submission-side instancing + registry hygiene; MinHook-graft methodology. 2026-08-02.
status: current
evidence: proven (root cause from a live hang dump) + inferred (design) + needs-live (M0)
date: 2026-08-02
---

# Density upgrade — master plan (panel synthesis)

Convened three expert designs (all corpus-grounded, all DESIGN-not-build):
- **Render/GPU:** `docs/reverse_engineer/density_render_instancing_design.md`
- **Runtime/systems:** summarized here §3–§5 (delivered inline).
- **Optimization/binary-surgery:** summarized here §6 + the graft methodology (delivered inline).

They **converge**. This doc is the unified plan + execution order.

## 0. The headline

**Stop forcing the 2008 entity system to hold what it was never built to hold.** Route mass
vegetation through the engine's OWN per-cell foliage system — procedurally populated, hardware-
instanced — and reserve the SceneObject registry (with a small hygiene fix) for the interactive props
and crowds that genuinely need it. Nothing is rewritten; everything ships as additive MinHook grafts
(`pmc_bb` `.asi`), gated and hash-verified.

## 1. Root cause, pinned to the byte (PROVEN, from the live hang dump)

The freeze exiting the PMC is NOT rendering. The main thread hangs in the **layer installer**
`FUN_00654940`, registering our 30k entities. The pathology is the **grow policy** of the keyed
SceneObject registry (`DAT_017c02f0`):
- `FUN_0064a600` insert: when `count == floor(cap × 0.80)`, it grows the table by **+256 slots (one
  page, LINEAR — not doubling)** and **full-rehashes** (`FUN_0064A1D0`→`0x02e90000`), then re-probes.
- Base world sits ~100k / 162048 = 62%. The 30k burst walks count through the 0.80 line (129,638),
  then **every 256th insert full-rehashes a ~130k table that grows by only 256** — ~100 rehash storms,
  each O(size), while probing an 80%-full linear-probe table (~13 probes/insert). Product ≈ **O(N²)**,
  executed synchronously on the main thread. That is the multi-minute hang.

Registry field map (from `FUN_00648850`; base `0x017c02f0`): `+0x04` count, `+0x08` capacity(modulo),
`+0x0c` stride(0x1c), `+0x14` hash mult(0x9e3779b9), `+0x1c` key table(-1=empty), `+0x20` page table;
load-factor const `_DAT_00beb510`≈0.80. Install runs under `EnterCriticalSection(&DAT_00edc6e4)` →
**load-time grafts are concurrency-safe** (the async streamer worker `FUN_00876400` doesn't touch this
registry). Hibernation controls wake/render, NOT registration — loading a layer registers ALL its
entities. **So "30k trees in layers_static" is guaranteed to burst-register 30k SceneObjects. The
representation is the problem, not the tuning.**

## 2. The two walls, the two fixes, the one linchpin

| Wall | Cause | Surgical fix |
|---|---|---|
| **Instantiation** (the hang) | 30k SceneObject burst-register → grow-storm O(N²) | **(a) Route veg off the registry** into the per-cell foliage/species-batch system (§3); **(b) hygiene** for props that DO register: presize + geometric-grow graft (§4) |
| **Draw calls** (earlier freeze) | 30k individual DIPs | **Instance at submission** — Rust-replace the warm packet consumer, extend the material-class sort; shader crux solved by mechanical `vs_3_0` register-swap (render doc) |

**The linchpin both halves converge on:** the per-cell veg **species-batch instance table**
`DAT_01175a30 + 0x708` (stride 28 B = xyz + entity-id). The runtime side POPULATES it (procedurally,
off the registry); the render side CONSUMES it as a per-instance stream (one instanced draw instead of
N). Procedural scatter → instance buffer → instanced draw = the canonical modern-foliage pipeline,
built on the engine's OWN plumbing.

## 3. Wall-1 primary fix — veg is NOT an engine entity (procedural per-cell)

The engine's own canopy is per-cell (c3 quad-tree cells, chunk `0x5B724250`, position implicit from
cell grid ID, streamed by the 1024-slot cell LRU `FUN_006b9300`; runtime collects per-cell instances
into species batches `DAT_01175a30`, added `FUN_004a2ce0` / removed `FUN_004a32f0` by cell view). Zero
per-instance SceneObjects. `TreeFoliage 0x2A8A1456` / `RuntimeFoliageModel 0x0BECB01B` are runtime
working sets, not storage.

**PROCEDURAL placement (user-flagged, first-class):** generate the per-cell veg instance rows from a
density field + terrain rules — Wally's heightmap (ground Y, sea −35, slope, road tiers) + the
`mercs2_formats::veg` taxonomy + biome/region → species SELECTION and PLACEMENT scatter — and emit them
into the species-batch table (or the c3-cell bundles). No 30k placement records, no registry inserts;
the engine streams/culls/LODs (`_P000`→`_P003` imposter ladder) per cell. Representation tiers:
- **Far/horizon veg** → instance row (28 B) in the species batch — no registry cost.
- **Near canopy** → per-cell c3 veg model — cell-granular streaming, no registry cost.
- **Interactive/destructible props** → full SceneObject (only these register).

This makes the instantiation wall VANISH at its source rather than out-tuning it.

## 4. Wall-1 hygiene fix — for entities that DO register (props/crowds)

- ★**RESOLVED STATICALLY (decomp, no x32dbg needed):** the keyed registry does **NOT** presize from
  `cdbsizes`. `FUN_00648850` inits `DAT_017c02f8` (capacity) = **0** (the ONLY literal write to it);
  it grows from empty. The dump's cap 162048 = `129597/0.80` rounded to a 256-page (161996→162048) =
  grown-to-fit, NOT `161280`/`172032`. So `cdbsizes SceneObject` sizes the component POOLS, not this
  hash registry — which is why the 172032 bump never fixed the freeze. **The fix MUST be a graft.**
- **4a (was "presize .ini") — DROPPED as the hang fix.** cdbsizes still sizes component pools (keep it
  sane for props/crowds), but it does not touch the hanging registry.
- **4b. Geometric-grow graft** on `FUN_0064a600` (THE fix): change grow from `cap+256` to
  `max(cap*2, cap+256)` → O(N²) rehash-storm becomes O(N) amortized. Robust — protects any future burst.
- **4b′. (alt) Init-presize graft** on `FUN_00648850`: after it zeros capacity, force one grow to a
  large target (e.g. 262144) so no grow fires during load. Simpler but a fixed ceiling; 4b preferred.
- **4c. (optional)** cap load factor `_DAT_00beb510` 0.80→0.70.

`FUN_0064a090` (hash/probe) is left STOCK — 30+ inlined callers assume linear probing; do not change
probe order. `FUN_00654940` is sliced/wrapped, not reimplemented (§5).

## 5. Gradual streaming (no burst)

- **Lever A (primary):** veg via the per-cell system (§3) is ALREADY cell-granular — thousands stream
  in as cells enter the LRU ring, never one 30k frame. The render peer's resident-imposter horizon
  (extend veg-cell distance + budget `mgr+0x4c350`) rides the same system.
- **Lever B:** for tier-3 mass content that must register, graft `FUN_0045e5f0`/`FUN_004646b0` to
  install the layer's entry table in bounded per-frame slices (hold `layer+0x14`≠2 until drained).
- **Lever C [LIVE]:** raise streamer `maxconc` (`mgr+0x4c358`=1) — but 1 was a hang-avoidance; confirm
  the old head-of-line-blocking bug is gone first.

## 6. Wall-2 — instancing (render doc, condensed)

Instance at **submission**, not the hot DIP choke (`FUN_007512f0` stays read-only — hooking it wedged
the game before). The material-class sort `FUN_008548f0` already clusters instanceable draws; extend
its key to `(VB,IB,decl,VS,PS,class)` and **Rust-replace the warm consumer `FUN_00854b38`** to merge
each run into `[SetStreamSourceFreq; one DIP]` (opcode 0x13 already wired). **Shader crux SOLVED:** the
static-mesh shaders take a pre-combined **WorldViewProj** constant → instancing is a mechanical
`vs_3_0` bytecode **register-swap** (add per-instance stream inputs, redirect the `c[N..N+3]` reads),
delivered ADDITIVELY (new `.sho` variants). ~<20 dominant shaders; guaranteed fallback = the engine's
own `PgMeshTiny`/`LocalToWorld[]` constant-indexed instancer. Props win most/easiest; veg second.
Needs `FUN_00854b38` class→state map (no corpus doc — must be produced live).

## 7. Crowds — a separate cascade (NOT rendering)

Cap = WAD-authored desired count (`DAT_00ed55c8[]`/`DAT_00ed55b0[]`, written by `FUN_004d60e0` from
`PopulationDensity` COMP) + O(N) per-frame SIM. 4-lever cascade (all or it backfires): count-write hook
+ pools (`Ai`/`_HumanPhysics`/`ControllerCar`, cdbsizes) + placement radius + residency (dist0). The
real wall is **per-frame CPU sim** — `Road_SnapNearest FUN_004fe660` (O(N)→spatial index), road-graph
rebuild `FUN_004fd9f0` (budget/defer), sqrt sweep `FUN_0040cbb0` — a HOT-PATH OPTIMIZATION track, not
render, not entity-representation. Render-instancing provably can't touch crowd sim.

## 8. Methodology — safe binary surgery (optimization doc, condensed)

- **MinHook detours ONLY** (user mandate: never byte-patch, not even in-memory). Rust `cdylib` `.asi`
  via pmc_bb (in the exe import table = loads first). Naked shims for non-standard ABIs (EDI-this,
  EAX-in — Ghidra drops reg args; author against DISASSEMBLY, confirm live).
- **Allocator parity:** engine memory (grow, records) must use the engine's CRT allocator / reuse
  `0x02e90000` — cross-heap free = silent corruption.
- **Anti-wedge:** hook LOAD boundaries (under the install CS = safe), never per-frame hot paths (the
  `crowd_fog_couple` wedge); prefer changing DATA over interposing CODE; batch, don't per-item; one
  graft at a time, kill-switch env-gated, default-off.
- **Gate ladder:** `loadprobe` world-load (skill `analyze-game-log`) → hang-dump reproduction → install
  telemetry (rehash count →0, install ms linear in N) → frame-time under density → sha256 every
  deployed binary. Profile the LOAD boundary, never the per-call hot path, until data forces deeper.

## 9. Execution order (each gated)

- **M0 — LIVE profiling (x32dbg, USER drives, read-only paused).** ★DECIDES EVERYTHING. (a) sampling
  profile → confirm the grow-storm is the cost; (b) break `FUN_0064a600`/`FUN_00672e40` → read
  `_DAT_00beb510`, and **does cap `0x017c02f8` presize from cdbsizes?** (the 162048-vs-172032 question).
- **M1 — Registry hygiene.** presize (+ geometric-grow graft per M0). *Gate: the current 30k repro
  LOADS without hanging; install time linear in N.* Proves the root-cause diagnosis.
- **M2 — Veg off the registry (the real architecture).** procedural per-cell veg → species-batch rows,
  NOT SceneObjects. *Gate: veg-census shows them in the foliage system; registry count unchanged;
  gradual cell streaming.* (Depends on M4 render for the affordable draw.)
- **M3 — Gradual tier-3 install** (Lever B) if any mass content still registers.
- **M4 — Instance the draw** (render): consumer coalescer + shader register-swap. Props first.
- **M5 — Crowd cascade** + the O(N) sim hot-path track (optimization).

## 10. Biggest open question — RESOLVED (decomp, 2026-08-02)

**Does the keyed SceneObject registry presize from cdbsizes? NO.** Proven statically: `FUN_00648850`
inits `DAT_017c02f8`=0 (only literal write); registry grows from empty; dump cap 162048 = `129597/0.80`
→ page 162048 (grown-to-fit), not 161280/172032. So `cdbsizes` never touches this registry — the
grow-policy graft (4b) is the only reliable instantiation fix. M0's registry sub-question is answered;
M0's remaining value is the sampling profile (confirm the grow-storm dominates) + reading the live
load-factor const `_DAT_00beb510`. This is no longer a blocker on M1 (the graft).
