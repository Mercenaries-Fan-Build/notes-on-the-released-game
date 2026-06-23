# Jobs / Threading (Pimp)

Scope: the parallel job / multithreading system ("Pimp") plus the engine's worker, timer, queue, and critical-section primitives.

Provenance: symbol/string evidence recovered from the Xbox 360 preview executable `Mercs2_Xenon_P.exe` (Mercenaries 2: World in Flames, Jul 11 2008 devkit "Profile" build, PowerPC). Decompressed PE at `output/jul08_prototype/mercs2_xenon_p.pe_full.bin`. This is NOT a real `.pdb`; all claims derive from recovered symbols and strings. Offsets are PE offsets as listed in `output/jul08_prototype/inventory/jobs-threading.txt`.

## Overview

Pandemic's in-house engine library "Pimp" (source `d:\mainline\mercs2\pimp\`) provides the multi-CPU job system used on the 360's hardware threads. The recovered source-path headers `pimp_job.h`, `pimp_queue_a64.h`, and `pimp_timer.h`, together with the `.\src\CPU\pimp_thread.c`, `.\src\CPU\pimp_timer.c`, and `.\src\CPU\pimp_cpu.c` assert sites, show a system organized around: **jobs** (units of work with a bounded parameter list and a "Jobtype"), a **lock-free queue** (the `a64` suffix points to a 64-bit-aligned/atomic queue), **per-CPU timers**, and **Pimp threads with critical sections**. The build distinguishes "pimp threads" from "non-pimp threads" (the `can't use pimpCriticalSections for non-pimp threads` assert), so Pimp owns its own worker-thread pool.

A separate concern visible in this inventory is the Havok physics multithreading glue (`*WorkerMT`, `ThreadSafePhysicsOperation`, `processActionsInSingleThread`, `multiThreadCheck`) — these are how the game drives Havok's `hkpMultiThreadedSimulation` across the same hardware threads. The `MassiveThread` symbol belongs to the Massive in-game-advertising SDK's worker thread, not to Pimp (see Evidence & confidence).

`PimpMemory.cpp` and the `Pimp*DeviceHeap`/`Pimp*FromDeviceHeap` symbols are the memory side of the same library and appear here because they are Pimp-namespaced; the device-heap defrag/alloc/free belong more to the memory subsystem but are noted for completeness.

## Source files

From `output/jul08_prototype/mercs2_xenon_p.source_paths.txt` (verbatim):

```
d:\mainline\mercs2\pimp\include\pimp_job.h
d:\mainline\mercs2\pimp\include\pimp_queue_a64.h
d:\mainline\mercs2\pimp\include\pimp_timer.h
d:\projects\ReleaseLine\Mercs2\PimpLib\Src\PimpMemory.cpp
```

Additional Pimp source/assert paths recovered from the strings table (not in `source_paths.txt`, but present in `mercs2_xenon_p.pe_full_strings.txt`):

```
.\src\CPU\pimp_thread.c
.\src\CPU\pimp_timer.c
.\src\CPU\pimp_cpu.c
```

## Key classes

No `Pimp`/job/thread C++ class names appear in `mercs2_xenon_p.rtti_classes.txt` — the Pimp job/queue/timer/thread code is C (the `.c` source extensions confirm this) and emits no RTTI. The thread-related RTTI classes present all belong to Havok, not Pimp:

- `class hkpMultiThreadedSimulation` (`.?AVhkpMultiThreadedSimulation@@`)
- `class hkThreadMemory` (`.?AVhkThreadMemory@@`)
- `class hkaMultithreadedChunkCache` (`.?AVhkaMultithreadedChunkCache@@`)
- `class hkpMultiThreadedSimulation::MtBroadPhaseBorderListener` (`.?AVMtBroadPhaseBorderListener@hkpMultiThreadedSimulation@@`)
- `class hkpMultiThreadedSimulation::MtEntityEntityBroadPhaseListener` (`.?AVMtEntityEntityBroadPhaseListener@hkpMultiThreadedSimulation@@`)
- `class hkpMultiThreadedSimulation::MtPhantomBroadPhaseListener` (`.?AVMtPhantomBroadPhaseListener@hkpMultiThreadedSimulation@@`)

## Symbols by area

### Havok multithreaded-physics workers (`.rdata`)

| Offset | Symbol | Note |
|---|---|---|
| 0x00010f4 | `_CastShapeWorkerMT` | multithreaded shape-cast worker entry (named) |
| 0x0001108 | `_CastRayWorkerMT` | multithreaded ray-cast worker entry (named) |
| 0x000111c | `_CacheBroadPhaseWorkerMT` | multithreaded broad-phase cache worker (named) |
| 0x0013acc | `ThreadSafePhysicsOperation` | thread-safe physics operation marker/string |
| 0x0057f34 | `processActionsInSingleThread` | Havok tunable: run actions single-threaded |
| 0x0057f54 | `multiThreadCheck` | Havok multi-thread sanity check |

These are the parallel collision-query workers and the thread-safety controls that bridge the engine's worker threads into Havok's `hkpMultiThreadedSimulation`. `processActionsInSingleThread` and `multiThreadCheck` also appear in the strings table alongside `processToisMultithreaded`, `islandDirtyListCriticalSection`, `modifyConstraintCriticalSection`, `multithreadedSimulationJobData`, `hkpThreadToken`, `hkMultiThreadCheck`, `hkMultiThreadLock`, and `hkMultiThreadLockTypes` — the full Havok MT control surface (cross-reference `havok-physics.md`).

### Pimp library — memory / device heap (`.rdata`)

| Offset | Symbol |
|---|---|
| 0x00c582c | `PimpDeviceHeap::Defrag` |
| 0x00c5844 | `PimpFreeToDeviceHeap` |
| 0x00c585c | `PimpAllocFromDeviceHeap` |

Pimp-namespaced device-heap allocator (source `PimpMemory.cpp`). Function-side of the same library as the job system; the actual allocation policy belongs more to the memory subsystem.

### Massive ad-SDK worker (`.rdata`) — NOT Pimp

| Offset | Symbol |
|---|---|
| 0x00a628c | `MassiveThread` |

`MassiveThread` is the worker thread of the Massive in-game-advertising client (string neighbors: `CMassiveThread`, `MassiveCriticalSection`, `ALLOCATION Failed for CMassiveThread Shutdown`, `Sending kill signal to DNS thread.`). It is a thread, hence its placement in this inventory, but it is unrelated to Pimp. (See `networking.md`.)

## Notable strings

Pimp assert/format strings (from `mercs2_xenon_p.pe_full_strings.txt`). The common assert format is:

```
PIMP ASSERT FAILED - %s(%d): 
```

Per-header assert payloads:

- `pimp_queue_a64.h` → `pimpQueue full` — the job queue has bounded capacity and can overflow.
- `pimp_job.h` → `Too many params for this job` — jobs carry a fixed-size inline parameter array.
- `pimp_timer.h` → `Timers not setup for CPU %d` — timers are tracked per CPU/hardware thread.
- `pimp_thread.c` → `can't use pimpCriticalSections for non-pimp threads` — Pimp critical sections are only valid on Pimp-owned worker threads, implying a dedicated worker pool.
- `pimp_thread.c` → `leaving critical section owned by thread %d from thread %d` — ownership-tracked critical sections; cross-thread release is an error.
- `pimp_timer.c` → `Must call TimerEndFrame from primary thread` — a designated primary thread drives end-of-frame timer collection.
- `pimp_timer.c` → `Cpu flush job not init` — a per-CPU "flush job" must be initialized before timing.
- `pimp_cpu.c` → `Too many Jobtypes` — a bounded registry of job types ("Jobtype").
- `pimp_cpu.c` → `can't call init custom after pimpInit` — `pimpInit` is the system bootstrap; custom init must precede it.

Timer-naming / debug markers (near `PimpMemory.cpp` in strings): `CPU%d`, `RootTimer`, `RenderTimers`, `TotalFrameTime`, `STOP : %s`, `START : %s`, and `TimersThread%d` (format) — a hierarchical per-CPU profiling timer tree. `D3D Worker` (offset region 8235) is the render worker thread name.

Tunables (from the embedded config block, `mercs2_xenon_p.pe_full_strings.txt` ~line 2085+), literal text:

```
 TimersThread0 10000 
 TimersThread1 25000 
 TimersThread2 32 
 TimersThread3 32 
 TimersThread4 32 
 TimersThread5 32 
 TimersThread6 32 
 TimersThread7 2 
 TimersThread8 2 
 TimersThread9 2 
```

and a second `[x360]`-profile override set: `TimersThread1 4000`, `TimersThread2 6000`, `TimersThread3 7900`, `TimersThread4 20000`, `TimersThread5 7000`. These configure per-thread timer-buffer sizes/counts (the meaning of the integer is not stated in the strings, so this is inferred).

## PC decompilation cross-reference

This section maps the Xbox symbols above to functions in the PC retail decomp (`output/_ghidra/all_functions_decomp.txt`), resolved via `output/jul08_prototype/pairing/resolved_jobs-threading.txt`.

Coverage here is essentially nil for the actual job system, and that is expected: Pimp is pure C and emits no RTTI, so the high-confidence **vtable bridge produced zero matches** for this system. The PC retail build also stripped the `PIMP ASSERT FAILED` source-path strings that the Xbox Profile build kept, so there is no string anchor onto `pimp_job` / `pimp_queue_a64` / `pimp_timer` / `pimp_thread` / `pimp_cpu` either. The only resolution is the one non-Pimp symbol — `MassiveThread`.

| Symbol / class | PC function | Bridge | Role |
|---|---|---|---|
| `MassiveThread` (Massive ad-SDK, NOT Pimp) | `FUN_009e22ad` | string | constructor — references `s_MassiveThread`, installs vtable `PTR_FUN_00b6945c` |
| (same object, spawn) | `FUN_009e22e2` | confirmed by grep | `CreateThread` + `ResumeThread` of the worker |
| (same object, dtor) | `FUN_009e22c8` | confirmed by grep | `CloseHandle` of the thread handle, same vtable |

`FUN_009e22ad` is the only entry the resolver returned, and it confirms what the inventory already said: this string belongs to the Massive in-game-advertising client's worker thread, not to Pimp. The constructor body is small and unambiguous:

```c
undefined4 * __fastcall FUN_009e22ad(undefined4 *param_1)
{
  FUN_009dec52(s_MassiveThread_00b69460);   // registers the "MassiveThread" name (debug/registry helper)
  param_1[5] = 0;                           // thread-handle slot (offset 0x14) cleared
  *param_1 = &PTR_FUN_00b6945c;             // installs the object's vtable
  return param_1;
}
```

The handle slot it clears (`param_1[5]`, i.e. `+0x14`) is the same slot the sibling spawn function fills:

```c
undefined4 __thiscall FUN_009e22e2(int param_1, LPTHREAD_START_ROUTINE param_2, LPVOID param_3)
{
  if (*(int *)(param_1 + 0x14) == 0) {            // only spawn once
    hThread = CreateThread(0,0,param_2,param_3,0,&local_8);
    *(HANDLE *)(param_1 + 0x14) = hThread;        // store into the +0x14 handle slot
    if (hThread != 0) { ResumeThread(hThread); return 1; }
  }
  return 0;
}
```

Together these show a small ctor/spawn/dtor triplet around a single `+0x14` Win32 thread handle — the Massive worker. `FUN_009dec52` is a Massive-SDK name-registration helper (also called with `s_CMassiveTime`, `s_CFlag`, etc.), reinforcing that this whole cluster (~`0x9d_xxxx`–`0x9e_xxxx`) is the ad SDK, not the Pimp job system. Confidence: medium for the symbol→function map (single distinctive string `MassiveThread`), high that it is unrelated to Pimp.

No PC functions could be resolved for the Pimp job/queue/timer/thread/cpu modules or the Havok `*WorkerMT` workers from this pairing; those remain symbol-only on the Xbox side.

## Cross-references

- `havok-physics.md` — the `*WorkerMT`, `ThreadSafePhysicsOperation`, `processActionsInSingleThread`, `multiThreadCheck` workers drive `hkpMultiThreadedSimulation`.
- `networking.md` — `MassiveThread` / `CMassiveThread` ad-SDK worker and the DNS thread live here, not in Pimp.
- `rendering-shaders.md` — `D3D Worker` render thread.
- `world-streaming.md` / `game-systems.md` — `pimpQueue` and the "flush job"/Jobtype machinery underpin the streaming and per-frame job scheduling these systems consume.
- Project memory: the world-load streaming work-item/worker analysis (e.g. `docs/engine_load_path_map.md`) describes the consumer side of this scheduler at runtime.

## Evidence & confidence

Inventory symbol count: 10 distinct symbols in `inventory/jobs-threading.txt`, all in section `.rdata`. All 10 offsets were grep-verified copy-exact against the inventory file.

Expanded evidence (grep-verified in `mercs2_xenon_p.pe_full_strings.txt`, `source_paths.txt`, `rtti_classes.txt`): the Pimp header/source paths (`pimp_job.h`, `pimp_queue_a64.h`, `pimp_timer.h`, `pimp_thread.c`, `pimp_timer.c`, `pimp_cpu.c`, `PimpMemory.cpp`), all the `PIMP ASSERT FAILED` payloads quoted above, the `TimersThread*` tunables, and the Havok MT control strings.

Directly attested by symbol/string evidence:
- The Pimp library has separate job, queue (`a64`), timer, thread, and cpu modules, each with its own assert source path.
- Jobs have a bounded parameter count and a bounded "Jobtype" count.
- Timers are per-CPU; `TimerEndFrame` runs on a "primary thread"; there is a per-CPU "flush job".
- Pimp critical sections are restricted to Pimp threads and track owner thread IDs.
- `pimpInit` is the init entry point; custom init must precede it.
- Havok query workers (`_CastShapeWorkerMT`, `_CastRayWorkerMT`, `_CacheBroadPhaseWorkerMT`) and MT controls exist.

What remains inferred rather than attested: the `TimersThread*` integers' exact meaning (only the per-thread buffer-sizing role is inferred — the strings give no definition). Everything else above (the `a64` queue being lock-free, the dedicated worker pool, the streaming/game-systems consumer relationship, the `*WorkerMT` roles) follows directly from the recovered names and asserts. None of the Pimp job/timer/thread functions could be located in the PC retail decomp — see the PC decompilation cross-reference section.

## How it works (decompiled)

Source: the Xbox 360 Profile-build decompilation `output/_ghidra_x360/xenon_decomp_named.c` (image base `0x82000000`). **Up-front honesty:** the Pimp job/queue/timer/thread/cpu core is **largely unreachable in this decomp.** None of the Pimp assert strings (`pimpQueue full`, `Too many params`, `pimpInit`, `Too many Jobtypes`, `non-pimp threads`, `PIMP ASSERT`, `TimerEndFrame`) are inlined as literals (grep: 0 hits each), and the scheduler functions are not named. So the job scheduler, the `a64` lock-free queue, and the per-CPU timer wheel **cannot be code-grounded from this build** — they remain symbol/string evidence only. What *is* decompiled and citable is the request-queue object, the device-heap defrag, and the GPU-sync fence.

### `RequestQueue @8277f038` — a queue object constructor
A small object ctor: it installs a vtable (`PTR_FUN_820a4aa0`), zeroes head/tail/count-style fields, sets one field to `1` (likely a "open"/capacity flag), and constructs an embedded sub-object at `+0xb`:

```c
undefined4 * RequestQueue(undefined4 *param_1) {          // @8277f038
  FUN_8277d818(param_1,0xffffffff820a4aa4);                // base init (name ptr 0x820a4aa4)
  *param_1 = &PTR_FUN_820a4aa0;                             // vtable
  param_1[5] = 0; param_1[6] = 0; param_1[7] = 0;          // head/tail/count
  param_1[8] = 0; param_1[9] = 1; param_1[10] = 0;
  FUN_82781068(param_1 + 0xb,0xffffffff820a4a90);           // embedded sub-object (the storage?)
  return param_1;
}
```

The matching destructor `FUN_8277f0b0` tears down the `+0xb` sub-object and a `+5` block, consistent with a queue holding an inline storage region. This is a *request* queue (used by the streaming/impression-request paths), not necessarily the Pimp `a64` job queue — the name pointer `0x820a4aa4` is distinct from the Pimp sources.

### `PimpDeviceHeap__Defrag @82905c00` — the device-heap maintenance op
Confirms the three device-heap operations are co-located and string-keyed exactly as the inventory lists them:

```c
void PimpDeviceHeap__Defrag(void) {                       // @82905c00
  uVar1 = FUN_8290ba80(0xffffffff820c585c); FUN_82902f90(uVar1,0xffffffff820c585c); // PimpAllocFromDeviceHeap
  uVar1 = FUN_8290ba80(0xffffffff820c5844); FUN_82902f90(uVar1,0xffffffff820c5844); // PimpFreeToDeviceHeap
  uVar1 = FUN_8290ba80(0xffffffff820c582c); FUN_82902f90(uVar1,0xffffffff820c582c); // PimpDeviceHeap::Defrag
}
```

The three `.rdata` pointers `0x820c585c`/`0x820c5844`/`0x820c582c` are exactly the inventory offsets `0x00c585c`/`0x00c5844`/`0x00c582c` (offset = VA − 0x82000000). `FUN_8290ba80`/`FUN_82902f90` are a named get/put pair (a profiler-zone or lock acquire/release around each heap op).

### `SyncCPUGPU @824c5f60` — the CPU/GPU fence + named perf zone
The CPU-GPU synchronization point. It flips a GPU register bit, then registers a named profiler zone via the same hash-insert (`FUN_8290bc68(... , 0x83cb28f4, 0x100)`) used by the engine's per-frame zones:

```c
void SyncCPUGPU(void) {                                   // @824c5f60
  DAT_83451ca4 = &DAT_83800de0;
  FUN_82311e20(0xffffffff83800de0);
  DAT_83800e20 = (DAT_8345192e & 1) << 0x1c | DAT_83800e20 & 0xefffffff; // set bit 28 of a GPU reg
  uVar1 = FUN_8290ba80(0xffffffff82030d98); FUN_82902f90(uVar1,0xffffffff82030d98);
  ...
  iVar2 = FUN_8290bc68(uVar1,0xffffffff83cb28f4,0x100);    // register "SyncCPUGPU" perf zone (256-bucket table)
  *(ulonglong *)(&DAT_83cb20f4 + iVar2 * 8) = CONCAT44(0xff0000ff,uStack_1c); // zone color (blue)
  DAT_83cb20e8 = DAT_83cb20e8 + 1;                          // running zone count
}
```

This is the same profiler-zone registry described in pangea-engine-core ("How it works") — the `0x83cb28f4` table with count `DAT_83cb20e8`. It is the threading-relevant primitive that survived naming, and it ties the per-CPU timer-tree (`RootTimer`/`RenderTimers`/`TimersThread%d`) the doc lists to a concrete 256-bucket hash registry.

## Corrections & open questions

- **Not supported in this build: the Pimp scheduler/queue/timer internals.** The doc describes jobs, the `a64` lock-free queue, per-CPU timers, and the worker pool from assert strings. **None** of those assert strings are inlined in `xenon_decomp_named.c` (verified: 0 hits for every Pimp assert literal), and no scheduler function is named. So those claims remain **string-only inference** — the decomp neither confirms nor refutes the lock-free queue, the worker-pool dedication, or the Jobtype registry. This is the most under-grounded system in the cluster.
- **Confirmed: device-heap ops match the inventory.** `PimpDeviceHeap__Defrag @82905c00` references exactly the three inventory offsets for `PimpAllocFromDeviceHeap`/`PimpFreeToDeviceHeap`/`PimpDeviceHeap::Defrag`, so those three are a genuine co-located trio. Promote from name-only to code-confirmed.
- **New finding: the profiler-zone registry is shared engine-wide.** `SyncCPUGPU @824c5f60` and the entity/state code (`ObjectStateUpdate`, pangea-core) register named zones into the same 256-bucket hash table (`0x83cb28f4`, count `DAT_83cb20e8`). This is the concrete backing for the `RootTimer`/`TimersThread*` timing tree the doc lists.
- **`RequestQueue @8277f038` is a request queue object, likely not the Pimp `a64` job queue.** Its base name pointer (`0x820a4aa4`) is unrelated to the `pimp_queue_a64.h` source. The doc should not conflate it with the job queue; it is a separate (impression/streaming) request queue.
- **Correct as-is: `MassiveThread` is not Pimp.** `MassiveThread @82783c88` exists in the Xbox decomp as a named static-init stub (installs vtable, stores name, returns) — consistent with the doc's PC-side finding that it is the ad-SDK worker, not a Pimp thread. No correction needed.
- **Open question: the worker-thread entry points and `pimpInit`.** I found no `CreateThread`/worker-loop function tied to Pimp in this decomp, nor `pimpInit`. The Havok `*WorkerMT` symbols are likewise not named here. The threading bootstrap remains unresolved on the Xbox side.
- **Decomp gap caveat:** several Pimp-adjacent helpers decompile to `thunk_FUN_*` / `FUN_829167xx` empty stubs; no behavior is claimed for those.
