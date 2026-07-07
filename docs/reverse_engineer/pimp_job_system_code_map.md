# Pimp (#15) — the job / threading system: PC code map

**Scope:** Pandemic's in-house **"Pimp"** multi-CPU job library (Xbox source `d:\mainline\mercs2\pimp\`)
as it exists in the PC `Mercenaries2.exe` (unpacked image, base 0x400000). This is the scoreboard's
"true novel system," which was **100% string-only on Xbox** (`jobs-threading.md` records 0 decomp
hits for every Pimp assert). The PC build keeps the real architecture — recovered here. Companion
JSON `docs/data/keystone_code_map.json`; Xbox oracle `docs/mercs2-pdb-analysis/jobs-threading.md`.

## Result in one line

The PC keeps the **per-CPU worker-pool + Jobtype-dispatch** architecture from the 360, but the
360's VMX **"a64" lock-free queue degraded to a `CRITICAL_SECTION`-guarded ring buffer** on x86 —
the only Interlocked op left is the job-completion fence.

## 1. Worker pool

**Worker thread proc = `FUN_00876400`** (one per CPU):
- `void FUN_00876400(int cpuIndex)` — first statement `*(*(TLS)+8) = cpuIndex`. **This is how a thread
  becomes a "pimp thread":** it installs its CPU index into its TLS pimp control block. Threads without
  that block are the "non-pimp threads" the Xbox assert rejects.
- Infinite loop: drain the per-CPU **high-pri queue** fully, then service **one** entry from the
  **low-pri queue**; each pop is `TryEnterCriticalSection(queue+0x18)` → advance packed head /
  decrement count → dispatch → on empty clear the busy flag and `Sleep(0)` (spin-with-yield).
- `callers=[]` because the `CreateThread(FUN_00876400, cpuIndex)` spawn is in the SecuROM-relocated
  pimpInit (same island mechanism that hides `FUN_0084af70`'s caller) → **spawn site confirm-live**.
- **CPU count `FUN_008767b0`** (`pimpGetNumCpus`): `GetProcessAffinityMask` popcount → worker count.

**Per-CPU control block** array `@0x019f9040`, stride **300 B (0x4b dwords)**: `+0x00` busy flag,
`+0x04` high-pri queue ptr, `+0x08` low-pri queue ptr, `+0x0c` handler-table base
(`{handler@+0, jobtypeHash@+4}`, indexed `jobtype*2`). A thread's TLS block also holds `+0x8` cpu
index and `+0xc` current-job ptr (set around each handler call).

## 2. Job dispatch (the hot line)

In both drainers:

```c
(*(code*)(&PTR_LAB_019f904c)[cpu*0x4b + job[0]*2])(job[2]);   // handler(arg), keyed by Jobtype index
InterlockedExchangeAdd(job[1], 1);                            // fork/join done-counter
```

**Job struct** (dequeued entry, ≤0x60/96 B = the ring stride): `+0x00` Jobtype index (→ per-CPU
handler table), `+0x04` completion-fence `LONG*` (NULL = fire-and-forget), `+0x08` param/context ptr,
`+0x0c…0x60` inline param list (the Xbox "Too many params for this job" cap). Jobtype registry count
`DAT_0117663c`, parallel name table `@0x19f9178`.

Registered Jobtypes found (hash → handler), including the `0x724xxx` trio that are the **AnimCpu*Job**
candidates: `0xcd4a518c→FUN_00724cc0`, `0x6b336727→FUN_00724480`, `0xcad07407→FUN_00724c20`;
`0xc28ef815→FUN_0084ac00`, `0x3300b3c8→FUN_0082c100`, `0x84f0d9c6→FUN_008780d0`,
`0xebfea356→FUN_0082d040`, plus the `FUN_0046a440` registrar cluster.

## 3. The queue — CS-guarded ring, not lock-free

`FUN_0084af70` (the `"pimpQueue"` seed) is the **initializer** (`PimpQueueInit`): it builds **three
rings** of 96-byte elements via `Pool_Alloc`, each guarded by a named Win32 mutex **and** a
`CRITICAL_SECTION`. Per-ring struct (bases `DAT_00ff45e8` / `DAT_00ff4618` / `DAT_00ff4650`):

| off | field |
|---|---|
| +0x00 | `HANDLE` mutex — `CreateMutexA(…, "pimpQueue")` |
| +0x04 | `u32` elem_size = 0x60 (96 B) |
| +0x08 | `u32` capacity (0x10 init / 0x1000 worker-per-iter / 0x400 worker-drain) |
| +0x0c | `void*` ring buffer (Pool_Alloc'd) |
| +0x10 | `u32` head\|count (low16 = consume idx, high16 = live count) |
| +0x14 | `u32` tail (low16 = produce idx, high16 = reservation ctr) |
| +0x18 | `CRITICAL_SECTION` (24 B) |

- **Enqueue** `FUN_004c00e0` (ring1) / `FUN_0084b290` (ring2): build the 0x60 element, `EnterCS`,
  `slot = (head.lo + tail.lo) mod cap`, memcpy with wraparound split, in-CS spin-commit
  `do{}while(published!=reserved)` for multi-producer FIFO ordering, advance, `LeaveCS`.
- **Dequeue** `FUN_00876400` (the worker): `TryEnterCS` → read count (`head>>16`) → advance consume
  idx (wrap at cap) → decrement count → `LeaveCS` → `slot=(idx&0xffff)*elem+buf` → `handler(arg)` →
  `InterlockedExchangeAdd(completion,1)`.

**Synchronization verdict:** the queue is **critical-section-guarded**; the *only* Interlocked op is
the completion counter. No `InterlockedCompareExchange64` / `cmpxchg8b` anywhere → the Xbox VMX
lock-free "a64" queue is a guarded ring on PC x86. (The named mutex at +0x00 is created but the CS
does the guarding — likely legacy/diagnostic; confirm-live.)

## 4. Per-CPU timers + frequency

- **Freq init `FUN_008243a0`**: `QueryPerformanceFrequency` → `DAT_017d40c0/c4` (ticks), `/1000` →
  `DAT_017d40c8/cc` (ms scale), `/1000000` → `DAT_017d40d0/d4` (µs scale).
- **Time_NowMs `FUN_008763c0`**: `QueryPerformanceCounter` → `__aulldiv` by the ms-scale global →
  node `+0x28` (~40 call sites). Node-tree aging `FUN_00873cf0` / `FUN_00873530`.
- **Timer thread `FUN_008271c0`** (spawned by `FUN_00826f20`), node insert `FUN_00826f90`.
- The pimp **profiler** per-CPU timer tree (`RootTimer` / `TimersThread%d` / `TimerBegin/End/EndFrame`)
  has its name strings **stripped on PC** — the ms/µs scales prove the subsystem exists but the
  RootTimer node struct can't be string-grounded → **confirm-live** (walk the timer tree from a worker
  TEB in x32dbg).

## 5. Profiler-zone registry

Mechanism confirmed: **`Hash_String FUN_00824270`** (FNV core `FUN_0082427f`:
`h=(h^(c|0x20))*0x1000193`, final `^0x2a`) + **`Hash_Probe FUN_008242b0`** (`key%256`, 8-way linear
probe) = the **256-bucket registry**, the PC equivalent of the Xbox zone table (`0x83cb28f4`, count
`DAT_83cb20e8`, inserted by `SyncCPUGPU @824c5f60`). On PC there are **multiple** 256-bucket
Hash_Probe tables (render-resource registry `DAT_0197da48`; per-object dispatch tables); the specific
PC profiler-zone table global + the PC SyncCPUGPU fence + the zone-insert sibling are **not positively
pinned** because the zone-name strings were stripped → confirm-live.

## 6. `pimpQueue` vs `RequestQueue` — distinct

- **pimpQueue** = the 3 CS-guarded 96-B rings above (`DAT_00ff45e8/4618/4650`), fed by job submitters,
  drained by the worker.
- **RequestQueue** = a C++ `CRequestManager` (`FUN_009df990` ctor, vtable `PTR_FUN_00b69028`,
  head/tail/count `[5..8]`, name `RequestQueue@0xb69018`) in the streaming/net region — a **streaming
  request client/consumer** of the job system, not a pimp ring. (Xbox `RequestQueue @8277f038` →
  PC `FUN_009df990`.)

## 7. CreateThread inventory — Pimp vs not

- **Pimp:** `FUN_00876400` (worker pool), `FUN_008271c0` (timer thread, via `FUN_00826f20`).
- **Not Pimp:** `FUN_00831e20 → FUN_00836610` = **PalSoundEngine::MixSources** audio mixer (one-off,
  50 ms poll); the `0x9cxxxx` set = Massive ad-SDK / net / DNS; `0x01b/0x02` island threads =
  Bink / CPUID / SecuROM (`FUN_01b986ea` = per-CPU CPUID feature detection).

## 8. Xbox → PC bindings + confirm-live

| Xbox (string-only) | PC |
|---|---|
| `pimp_queue_a64.h` init | `FUN_0084af70` (PimpQueueInit) |
| enqueue / dequeue | `FUN_004c00e0` / `FUN_0084b290` ; `FUN_00876400` |
| `pimp_thread.c` worker | `FUN_00876400` (+ `FUN_008765cf` cooperative drain) |
| `pimp_cpu.c` CPU count | `FUN_008767b0` (GetProcessAffinityMask popcount) |
| `pimp_timer.c` | freq `FUN_008243a0`, NowMs `FUN_008763c0`, timer thread `FUN_008271c0` |
| Pool allocator | `Pool_Alloc 0x84d760`, `Pool_AllocFast 0x84ac20` (lock `DAT_00ff4570`) |
| Hash primitives | `Hash_String 0x824270` (+FNV `0x82427f`), `Hash_Probe 0x8242b0` |

**Confirm-live:** (1) worker `CreateThread` spawn + per-CPU block alloc loop (SecuROM-relocated
pimpInit) — bp `FUN_00876400` entry, read `cpuIndex`, count live workers (expected = numCpus);
(2) the per-CPU RootTimer profiler node struct (strings stripped); (3) the PC profiler-zone table
global + SyncCPUGPU fence (strings stripped). The `mercs2_core` job/scheduler analog (scoreboard ❌,
candidate rayon) now has a concrete spec: per-CPU worker pool, 96-B Jobtype+fence+params jobs, a
guarded ring, and a fork/join `InterlockedExchangeAdd` completion counter.
