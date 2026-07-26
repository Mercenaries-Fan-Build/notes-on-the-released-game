# Keystone C (#14) — the scheduler / master tick: PC code map

**Scope:** the PC-side per-frame scheduler in `Mercenaries2.exe` (unpacked image, base 0x400000).
This **closes the scoreboard's "master tick order unknown even in exe" gap** — the Xbox analysis
located the system-registration side but never found `PgGameSystem::Update`. On PC it is recovered.
Companion JSON `docs/data/keystone_code_map.json`; Xbox oracle `docs/mercs2-pdb-analysis/pangea-engine-core.md`
(PgGameSystem.cpp, PgSysPopulation), `pangea_engine_alignment.md` §Keystone C.

## 1. The frame loop (recovered)

```
FUN_00631670  WinMain: create Mercenaries2 mutex, check Data/vz.wad,
   └─ while (DAT_01175fff /*quit*/ == 0)  FUN_00630ef0()      // master frame loop = RunFrame
        FUN_006315f0 = message pump only (PeekMessage/Dispatch; WM_QUIT 0x12 → DAT_01175fff=1)
```

The briefing seed `FUN_006315f0` is **only the message pump**; the real per-frame driver is
**`FUN_00630ef0` (RunFrame)**, called each loop iteration from `FUN_00631670`.

## 2. RunFrame `FUN_00630ef0` — the per-frame order

Each stage confirmed in-body:

1. `QueryPerformanceCounter` — frame-start timestamp (QPC is the dt source).
2. one-time device re-init gate (`DAT_01175a94==1 → FUN_004c0730`).
3. **`FUN_004c16e0`** timestep compute → publishes sim dt `DAT_01175a90`.
4. fixed-frame accumulator `DAT_00dfdcc4 -= DAT_01175a90`; on drain → `FUN_00630ea0` (reset + input watchdog).
5. **`FUN_004c14f0(dt)`** — **MASTER UPDATE** (see §3).
6. **render** — `(*(view+0x14))()` on the render-view singleton `PTR_PTR_00dfc2f8`.
7. `QueryPerformanceCounter` end → real frame time `DAT_01176048 = elapsed / QPCfreq (DAT_017d40c0/c4)`.
8. **`FUN_004f59a0`** — vsync / frame-cap (QPC busy-spin + `(*(view+0x34))()` device flip).
9. **present** — `(*(view+0x10))()`.

## 3. The master tick — `FUN_004c14f0 → FUN_004c15e0` (the recovered gap)

The per-frame master tick is a **5-layer application stack**, ticked in **fixed index order 0→4**:

- `FUN_004c14f0(dt)`: runs a decoupled **fixed-timestep sim accumulator** (`_DAT_0198dc48 += dt*timescale`,
  integer steps → `DAT_011765cc`, keep remainder), then `FUN_0084ae70` (streaming LOD-budget notify),
  then `FUN_004c15e0(dt)`.
- `FUN_004c15e0`: walks the layer stack — array **`@0x017bbccc`**, `count DAT_017bbcf4 = 5`,
  `cur DAT_017bbcf8`, `target DAT_017bbcfc = 4` (init `FUN_004c1170`). It boots at layer 0 and climbs
  to layer 4; each layer object is ticked via vtable **`+0xc = Update(dt)`** (with `+8`/`+4` =
  enter-descending / ascending transitions).

  > **Corrected 2026-07-26.** This line previously called the array `@0xd6c22c`. That is not the
  > array — it is the *value* of element 0. The indexing instruction settles it:
  > `0x004c15fa: 8b 34 85 cc bc 7b 01  mov esi, dword ptr [eax*4 + 0x17bbccc]`, i.e. base
  > `0x017bbccc`, stride 4. `FUN_004c1170` writes `0xd6c22c` into slot 0
  > (`0x004c11f9: mov dword [eax*4 + 0x17bbccc], 0xd6c22c`). Reading the five slots out of the live
  > dump `output/_ghidra/securom_dump/mercs2_unpacked.exe` gives the whole stack:

  | idx | object | vtable | `+0xc` tick | |
  |---|---|---|---|---|
  | 0 | `0x00D6C22C` | `0x00BB0420` | `0x004BEEA0` | |
  | 1 | `0x014538B8` | `0x00BB0430` | `0x004BEED0` | heap-allocated |
  | 2 | `0x0149FDA0` | `0x00BB0440` | `0x004BFAF0` | heap-allocated |
  | 3 | `0x00D6C238` | `0x00BB0450` | `0x004C00E0` | singleton install table |
  | **4** | **`0x00D6C244`** | **`0x00BB0460`** | **`0x004C09C0`** | **the game-state pump** |

  Layers 0/3/4 are three 12-byte sub-objects of one static structure (`{vtable, _, phase}` — the
  walk's `piVar1[2]` compares against 3 and 4); 1 and 2 are allocated. **H.** Note this resolves
  *which* function layer 4 dispatches to (`0x004C09C0`) statically — the "confirm-live (x32dbg)"
  note below is narrower than it reads and survives only for the system order *inside* that pump.

**Iteration order = the hardcoded 5-slot layer sequence 0→4**, not registration order and not a
sorted priority. The **top layer (idx 4 = the game/ECS mode)** ticks the gameplay systems
(Camera / Animation / Vehicle / AI / Population …) behind its `Update(+0xc)` vtable — so the
**individual PgSys tick order *inside* layer 4 is vtable-dispatched → confirm-live (x32dbg)**.

## 4. System registration framework (recovered)

The Xbox "PgSys 32-slot registry" is present and structurally identical on PC — the name-string
table is stripped, so systems keep only a returned `~slot` id.

- **32-slot allocation bitmask** `DAT_0124af14`; allocator **`FUN_0060cf90`** (scan free bit,
  `mask |= 1<<n`, return `~slot`); release `thunk_FUN_024e2780`. Sibling per-family masks confirm the
  Xbox "one 32-slot mask per family": `DAT_011b5124` (32), `DAT_0171179c` (16), `DAT_011ba1cc` (32).
- **Global update-fn list** (a *per-object* system broadcast, not the per-frame tick — see below):
  base `DAT_00dceb80`, count `DAT_00dcebc4`, cap `DAT_00dcebc8` (=16) — the exact analog of Xbox
  `DAT_82c215c8 / DAT_82c2160c / DAT_82c21610`. Append is **inlined per-ctor** (dup-scan → `count<cap`
  → `array[count++]=fn`); remove `FUN_0050b730`.
- **Dispatcher `FUN_004f2a90`** (never located on Xbox): `for i in [0,count): (*array[i])(objectHandle)`.
  Crucially it passes an **object handle, not `dt`**, and its callers (`FUN_00654940`, `FUN_00673070`)
  are ECS object-population drivers — so this list is a **per-object PgSys broadcast** (population/spawn
  scoped), **correcting the Xbox mis-inference** that it was the per-frame update-fn list. Exactly two
  systems register into it (`FUN_006b7720`, `FUN_006c4eb0` — PgSysPopulation-family object-hierarchy
  registrars).

**14 system constructors** were enumerated in the contiguous `0x6bxxxx–0x6fxxxx` "systems" region
(all `callers=[]` → CRT static-init, like the reflection registrars), each claiming a slot via
`FUN_0060cf90` with a paired destructor releasing it. Notables by pinned behaviour: `FUN_006cebc0`
(entity/session object DB), `FUN_006c7f90` (lang + net/IO buffer), `FUN_006f6380` (**composite**
owning 6 sub-systems — pipeline root, likely the PgSysRender family). 12 of 14 tick via vtables/a
frame-level list rather than the per-object list — their wiring is inside the layer-4 vtable
(confirm-live).

## 5. Render-frame phases (PgSysRender quartet → PC)

All hang off the render-view / RenderSystem singleton `PTR_PTR_00dfc2f8` (runtime obj `0x017CFAF0`)
as vtable slots:

| slot | phase |
|---|---|
| +0x14 | **RenderFrame** (the z→color→shadow→reflection per-viewport `PgScene::Render` work; the shadow-RT creator `FUN_00755d90` and FX passes hang off here — see the shadow/FX code maps) |
| +0x10 | **SubmitFrame / Present** (last call of RunFrame) |
| +0x34 | **flip / vsync** (from `FUN_004f59a0`) |
| +0x4 / +0x8 / +0xc | device resolve / reset (handle-table re-acquire; the render-view `0xFFFF` crash path) |

Parallel render worker `FUN_0046a3c0` sets `view+0x2b94` (active scene) then calls `view+4`; camera
reach `cam = view + (*(u16*)(view+0x2B92))*0xE80`. The concrete FUN bodies behind these slots live in
the `.data` vtable → confirm-live.

## 6. Timestep policy

**Decoupled fixed-sim + variable-render.** Real frame dt from **QueryPerformanceCounter**
(`DAT_01176048`, seconds). Sim dt `DAT_01175a90` is produced by **`FUN_004f5530`** with 3 modes
(`DAT_0175186c`): mode 0 = variable-with-clamp (min `DAT_00b977f8` … **max/cap `DAT_00b92b58`**),
mode 1 = fixed-step, mode 2 = variable-substep. `FUN_004c14f0` then runs a fixed-step accumulator
over that dt (integer sim steps + fractional carry). Frame-rate cap/vsync in `FUN_004f59a0`.

## 7. Xbox → PC bindings established

| Xbox | PC |
|---|---|
| update-fn list `DAT_82c215c8 / 2160c / 21610` | `DAT_00dceb80 / DAT_00dcebc4 / DAT_00dcebc8` (reclassified **per-object**) |
| `PgGameSystem::Update` (never located) | master tick `FUN_004c14f0 → FUN_004c15e0` (5-layer stack, order 0→4) |
| ~~`PgSysPopulation::Update FUN_82364058` → `FUN_006b7720`/`FUN_006c4eb0`~~ **WRONG — see below** | — |
| `PgSysPopulation::Update` = Xbox `FUN_82368008` (via game-systems master tick `FUN_822ff9b0`) | **`FUN_00502510`** (in the layer-4 list `FUN_004c9740`) |
| PgSysRender quartet | render-view singleton `0x00DFC2F8` vtable +0x14 / +0x10 / +0x34 |

**Correction (2026-07-06, from `population_spawner_code_map.md`):** the old row above was doubly
wrong. Xbox `FUN_82364058` is `PgSysPopulation::OnEntityDeleted` (an on-delete callback), not
`::Update`; and PC `FUN_006b7720`/`FUN_006c4eb0` are 11-byte stubs inside SceneObject-pool
registrars, not population. The real `PgSysPopulation::Update` is Xbox `FUN_82368008` ↔ PC
**`FUN_00502510`**, and the **layer-4 intra-order is statically resolved** as the literal call
sequence of **`FUN_004c9740`** (1448 B, reached via `FUN_004c0ec0`) — population sits mid-list, the
spawn-queue drain `FUN_004b4590` later in the same list. This closes confirm-live item #1 for the
population slot (order is a direct call list there, not vtable-dispatched).

## 8. Confirm-live inventory

1. Per-system tick **order inside layer 4** (Camera/Anim/Vehicle/AI/…) — behind the layer's
   `Update(+0xc)` vtable; x32dbg to enumerate.
2. Concrete FUN bodies for render-view slots +0x14/+0x10/+0x34 (vtable is `.data`).
3. The `mercs2_core::Schedule` fixed-timestep spine is the modern analog but runs its own dt loop
   (scoreboard 🟡) — this map gives it the real order to mirror: RunFrame's 9-stage sequence + the
   5-layer 0→4 climb + the decoupled fixed-sim accumulator.
