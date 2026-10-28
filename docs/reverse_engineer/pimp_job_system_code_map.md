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

**Worker thread proc = `FUN_00876400`** (exactly one worker thread, cpu index 1; see the spawn below):
- `void FUN_00876400(int cpuIndex)` — first statement `*(*(TLS)+8) = cpuIndex`. **This is how a thread
  becomes a "pimp thread":** it installs its CPU index into its TLS pimp control block. Threads without
  that block are the "non-pimp threads" the Xbox assert rejects.
- Infinite loop: drain the per-CPU **high-pri queue** fully, then service **one** entry from the
  **low-pri queue**; each pop is `TryEnterCriticalSection(queue+0x18)` → advance packed head /
  decrement count → dispatch → on empty clear the busy flag and `Sleep(0)` (spin-with-yield).
- **Spawn = `0x00876800`** (in `.text`, outside every function of the Ghidra export; no direct caller
  in `.text`). Its whole body, from the bytes of `mercs2_unpacked.exe` (sha256 `8c179a99…`):
  ```
  876800  mov [0x1176634], eax
  876805  mov [0x1176638], ecx
  87680b  mov dword [0x19f9298], 0
  876815  call FUN_008767b0                 ; popcount of the process affinity mask
  87681a  push 0x19f902c                    ; lpThreadId
  87681f  push 0                            ; dwCreationFlags
  876821  push 1                            ; lpParameter = cpuIndex 1
  876823  push 0x876400                     ; FUN_00876400
  876828  push 0x80000                      ; 512 KB stack
  87682d  push 0
  87682f  mov [0x19f9298], eax              ; the CPU count is stored, not looped over
  876834  call [0xb051c0]                   ; CreateThread (the IAT slot every CreateThread site calls)
  87683a  mov [0x19f9024], eax              ; the worker's handle
  87683f  ret
  ```
  One `CreateThread`, no loop: the PC build runs **one** worker whatever the CPU count. The thread
  list of a profiler session (`mercs2_profiler`) shows the same: one thread started at the worker proc.
- **CPU count `FUN_008767b0`** (`pimpGetNumCpus`): `GetProcessAffinityMask` popcount, stored at
  `0x19f9298`; no instruction in `.text` reads `0x19f9298` by its absolute address.

**Per-CPU control block** array `@0x019f9040`, stride **300 B (0x4b dwords)**: `+0x00` busy flag,
`+0x04` high-pri queue ptr, `+0x08` low-pri queue ptr, `+0x0c` handler-table base
(`{handler@+0, jobtypeHash@+4}`, indexed `jobtype*2`). A thread's TLS block also holds `+0x8` cpu
index and `+0xc` current-job ptr (set around each handler call).

**Queue routing** (`FUN_0084af70` tail, `0x84b1ca–0x84b1e4`): cpu 0 = high `0xff4650`, low `0xff4618`;
cpu 1 = high none, low `0xff45e8`. A job runs on whichever CPU drains the ring its submitter names:
render jobs name `0xff45e8` (`FUN_0046a920`), the per-frame game jobs name `0xff4650`/`0xff4618`
(`FUN_0048e550`, from game update). The main thread drains its own rings while it waits on a job
(`0x8765cf`); nothing else drains them.

**Per-CPU capacity** — every TLS+8 (cpu index) use, from the decomp, a `.text` `fs:0x2c` sweep and a
raw byte scan of every section (table of all sites: owner stores, comparisons, indexed arrays):

| slots | structure | evidence |
|---|---|---|
| 2 | Pimp control block `0x19f9040` (stride `0x12c`) | registrations write two handler copies (loop `mov ecx,2 / add eax,0x12c` at `0x42958f`); queue pointers set for two (`0x84b1ca`); slot 2 is the CPU count `0x19f9298`, then audio globals |
| 2 | per-CPU context table `[0xd8a3bc]+0x14` (`FUN_004b7460`, from jobtype handlers `0x4b7760` / `0x4b7780`) | `+0x1c` holds the jobtype index (`0x4b7375`); teardown `FUN_004b73f0` loops 2 (`0x4b73f7`) |
| 3 | pose-buffer block pool `*(0x14b7e6c)` | `Pool_AllocFast(0x24)` + 3×8 constructor at `0x693a24–0x693a47` |
| 3 | memo `0x19c6954` | init writes 3 entries; init flag at `0x19c6984` |
| 4 | scratch `0x14163e0 + cpu*0x6000` | 4 copies initialised; loops end at `0x142e3e0` |
| 4 | `+0x55c` / `+0x57c` / `+0x58c` arrays of the 0x5b4-byte lookup objects | reset at `0x874d50` writes 4 of each; count-4 constructor at `0x4be0dc` |
| 10 | 0x84-byte per-CPU lists | `new[10]` at `0x6c0e80`; drain loops 10 |

Comparisons are equality tests (`cpu == 0` frame-budget timing in `FUN_00695b00` / `FUN_00695d10`;
`cpu == [0xed4520]` deferred-list flush at `0x4fc470`), so a cpu ≥ 2 takes cpu 1's branches. The stored
CPU count `0x19f9298` is never read. A thread with cpu index *n* needs every structure above with more
than *n* slots: no index ≥ 2 without moving the two 2-slot structures.

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

- **Pimp:** `FUN_00876400` (the one worker, spawned at `0x876834`), `FUN_008271c0` (timer thread, via
  `FUN_00826f20`).
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

**Confirm-live:** (1) who calls the spawn `0x876800` (no direct caller in `.text`) and what reads
the stored CPU count `0x19f9298`; (2) the per-CPU RootTimer profiler node struct (strings stripped); (3) the PC profiler-zone table
global + SyncCPUGPU fence (strings stripped). The `mercs2_core` job/scheduler analog (scoreboard ❌,
candidate rayon) now has a concrete spec: per-CPU worker pool, 96-B Jobtype+fence+params jobs, a
guarded ring, and a fork/join `InterlockedExchangeAdd` completion counter.

## 9. Jobtype `0xECAED415` — the per-cell sub-slot LOD test (fully decoded)

The busiest registered jobtype: slot 17 of the frame-1 table, ~625 cells/frame, measured at
**2,951,487 invocations over a 129 s session**. It walks the sub-slots of each streaming cell,
assigns each a 4-tier LOD band from the distance to a small set of reference points, and pushes every
state transition onto a shared change ring. Nothing else in `docs/` covered it.

### 9.1 Call chain

| v1.1 | v1.0 | Role |
|---|---|---|
| `FUN_00735e80` | `FUN_00735c80` | Jobtype entry. Walks TLS → job, publishes cfg/arr globals, loops the cells. |
| `FUN_00735dd0` | `FUN_00735bd0` | Per-cell: group-min, then the band body. |
| `FUN_00735780` | `FUN_00735580` | 4-slot group min over the cell's world AABB. Returns in **ST0**. |
| `FUN_00735680` | `FUN_00735480` | Chebyshev (L∞) point→AABB distance. Returns in **ST0**. |
| `FUN_00735840` | `FUN_00735640` | The body: fade test, inner gates, band cascade, ring push. |
| `FUN_00518830` | `FUN_005186f0` | Batch ring push (count in EAX), used by the fade path. |
| `FUN_009ee870` | `FUN_009ee780` | CRT truncating `float`→`int64` (`ftol`, 179 callers). |
| `FUN_004015c0` / `004015a0` / `004015b0` | same | 5-byte reference-point getters: **x / z / y**. |

The getters' semantics are PROVEN from `FUN_00735680`, where `004015c0`'s result is compared against
`box[0]`/`box[2]` (xmin/xmax) and `004015a0`'s against `box[1]`/`box[3]`. Ghidra renders them as empty
bodies and their results as a phantom `in_XMM0_Da`, so every caller reads as if the value came from
nowhere; it does not.

### 9.2 How arguments reach the handler

No parameters are passed. The handler re-derives everything from thread-local state:

```c
job   = *(void **)(*(int *)ThreadLocalStoragePointer + 0xc);   // TLS[0] = pimp control block
a     = job[0x0c]; b = job[0x10]; count = job[0x14];
slots = job + 0x20;                                             // per-slot pointer table, stride 8
cells = slots[(a + b + i) * 8]            for i in 0..count
cfg   = *(void **)(slots + (a+b+count)*8 + 0x08);               // -> PTR_DAT_00f78524
arr   = *(void **)(slots + (a+b+count)*8 + 0x10);               // -> PTR_DAT_00f7851c
                                                                // slot (a+b+count) itself is
                                                                // double-dereffed to PTR_DAT_01175260
```

`_DAT_00f78520` is set to `cell_size = 2 << (cfg[0x04] - 1)`, i.e. `2^shift`.

### 9.3 Config block (`PTR_DAT_00f78524`, 0x60 bytes)

| Off | Type | Field |
|---|---|---|
| 0x04 | u8 | `shift` — cell size is `2^shift` |
| 0x06 | i16 | `grid_dim` (used by the body for cell→world) |
| 0x08 | i16 | `outer_grid_width` (used by the dispatcher's AABB) |
| 0x0a | i16 | `inner_count` — reference points to test |
| 0x0c / 0x14 | f32 | `origin_x` / `origin_z` |
| 0x24 | i32 | `cell_step` |
| 0x28 | f32 | `sub_step` — sub-slot byte → world scale |
| 0x30 | i16 | `y_origin` |
| 0x38 | f32 | `inner_scale` — packed key → inner radius |
| 0x3c | f32 | `margin` — band widening, **not** a fade term (see 9.6) |
| 0x40..0x44 | u8[4] | `inner_gates`, indexed by point index |
| 0x44..0x48 | u8[4] | `inner_indices`, indexed by loop counter |

### 9.4 Cell block (0x1f0 bytes), per sub-slot `i`

| Off | Type | Field |
|---|---|---|
| `0x00 + i*4` | u32 | `entity_id` |
| `0x80 + i` | u8 | `state` — band nibble `0xF0` + inner-reference bits `0x0F` |
| `0xA0 + i*4` | u8, u8, u16 | `x_byte`, `y_byte`, `key` |
| `0x120 + i` | u8 | `y_contrib` |
| `0x140 + i*3` | u8[3] | band radii `r1, r2, r3` (added to `lod_base`) |
| `0x1A0 + i*2` | u16 | `lod_base` |
| `0x1E4` | i16 | `sub_slot_count` |
| `0x1E6` | i16 | `cell_id` |

`key` is split: low 14 bits are the packed radius, the **high 2 bits are a 256-unit vertical page**.

```c
packed  = key & 0x3FFF;
sub_x   = origin_x + col*cell_step + x_byte*sub_step;
sub_z   = origin_z + row*cell_step + y_byte*sub_step;
sub_y   = (key >> 14)*256 + y_contrib + y_origin;      // integer, then converted
inner_r = packed * inner_scale;  outer_r = inner_r + margin;
```

### 9.5 Band cascade and its one-sided hysteresis

Bands run **far → near**: `0x10` is the most distant tier, `0x40` the closest. Each threshold is
tested twice, once widened by `margin` and once bare; the bare test is where hysteresis lives. `b1..b3`
are `lod_base + r1..r3`. All comparisons are `<=` against the **3-D** nearest distance; the 2-D
nearest only gates entry.

| Condition on `near3d²` | Natural tier | Hysteresis |
|---|---|---|
| `>= (b1+margin)²` | `0x10` | none |
| `>= b1²` | `0x20` | caps to `0x10` if `old < 0x20` |
| `>= (b2+margin)²` | `0x20` | none |
| `>= b2²` | `0x30` | caps to `0x20` if `old < 0x30` |
| `>= (b3+margin)²` | `0x30` | none |
| `>= b3²` | `0x40` | caps to `0x30` if `old < 0x40` |
| `< b3²` | `0x40` | none — snaps |

The cap compares the **whole old byte**, not the masked nibble; this is equivalent only because the
inner-reference bits stay inside the low nibble. Separately, when `inner² <= near2d² < outer²` (the
margin ring) the slot keeps tier `0x10` **only if it already had a tier** (`old & 0xF0`).

The inner-reference bit is OR'd in as a **side effect inside the `&&` chain**, before the gate byte is
tested — so the bit is set whenever the two distance conditions pass, even when `inner_gates[idx]` is
zero and the distance trackers are skipped. When the gate **is** zero, the per-slot flag `var_23h`
(zeroed at `0x007359BD`, set at `0x00735AA9`) records that an **ungated reference is near**.

**The no-band path stores and emits like any other.** When the accumulated byte has no band
(`test bl, 0xf0` at `0x00735CB4`) control goes to the SecuROM-relocated fragment
`0x00581BF6: cmp byte [var_23h], 0; jmp 0x00735CBE`, and `0x00735CBE` is `je compare; or bl, 0x10`:
an ungated near reference keeps tier `0x10`, then the byte reaches the **same compare-and-store** as a
band — `cmp al(old), bl(new); je next` else push `(entity, old | new << 8)` and store `new`. A slot
that held `0x11` and now has nothing near it therefore emits `0x11 -> 0x00` and is zeroed. Nothing
is skipped and nothing returns early.

### 9.6 Fade path — the cutoff is `trunc(group_min − margin)`

```c
threshold = (int)ftol(FUN_00735780(...) - cfg->margin);   // 0x007358BA..0x007358C8
if (packed < threshold) { if (state) { push(entity_id, state -> 0x00); state = 0; } }
```

`fld [ebp+0xc]` is the caller's `fstp dword [esp]` of `FUN_00735780`'s ST0 (`0x00735E6E`),
`fsub [esi+0x3c]` subtracts `cfg.margin` — `esi` is `[0x00F78524]`, loaded at `0x00735858` — and the
CRT `ftol` truncates. Every leaf is verified against the v1.1 bytes: `0x00735680` is Chebyshev to the
box (`max` via `0x00407760`), `0x00735780` folds the four gated slots with `min` (`0x00407750`), and
the getters `0x004015C0/A0/B0` read `+0/+8/+4` = x/z/y.

An earlier version of this section said there was no margin term, from a live run in which the port
under-emitted fades. That residue was the no-band store above, which the port then treated as a
`continue`; the harness attributed those `old -> 0x00` entries to the cutoff and measured a cutoff
hundreds of units above the group-min. Regression tests:
`cells::tests::per_cell_test_subtracts_the_margin_from_the_group_min_to_get_the_fade_cutoff` and
`cells::tests::per_cell_test_stores_and_emits_a_no_band_byte_when_it_differs_from_the_old_state`.

### 9.7 The change ring

Counter `DAT_00DD4788`, base `DAT_00DD4790`, 16-byte entries, guarded by `CRITICAL_SECTION`
`DAT_00DD4770` (v1.0: `0xDD5788` / `0xDD5790`):

| Off | Content |
|---|---|
| +0 | `entity_id` |
| +4 | `old \| new << 8` |
| +8, +12 | **uninitialised stack residue** — carries no meaning |

The emit predicate is **full-byte inequality** (`state != new`), so a change in the inner-reference
bits alone still produces an entry. Fades reach the same ring through the batch push, appearing as
`old -> 0x00`.

### 9.8 Evidence

**PROVEN** (decompile of `pc-v11` cross-checked against a live 129 s shadow run in which a Rust
reimplementation ran against the same inputs immediately before each real invocation): the call chain,
argument derivation, both struct layouts, the cascade, the fade cutoff, the ring layout.

Two readings the decompile gets **wrong**, both caught by the live run:

- `(bVar20 & 0xf0) == 0 -> FUN_00581bf6(); return;` reads as abandoning the whole cell. It does not —
  but neither is `0x581bf6` a `continue`, which a second reading assumed. It is a relocated
  conditional (§9.5): the no-band byte is compared and stored like a band. The 588 game-only
  `old -> 0x00` entries the shadow runs left unexplained (0.02% of invocations, zero port-only) were
  all this path with `acc == 0`.
- `FUN_00518830` looks like a non-ring notifier. It is a ring batch push and does bump the counter.

**Concurrency, measured:** despite the critical section, job 17 never ran concurrently with itself in a
stock single-worker build — `0 overlapped` of 2,951,487 invocations. The lock is for the general case;
it is not evidence that this jobtype is contended today.

**The residue after the no-band fix (2026-10-26, runs `6a000429…` → `63ce1fec…`).** With §9.5's
no-band store ported, 70–89 game-only entries remain per ~3 M invocations — tiers dropped or cleared
with the inner bit kept (`0x11 -> 0x01`, `0x21 -> 0x11`, …), never port-only. On every one, the
instrumented harness showed: the state byte and the sub-slot record the port read *before* the
handler equal what the handler stored its `old` from and what is there *after*; the reference block
did not move; the entry's residue words carry `0x0073580A`, `FUN_00735840`'s own normal-path
fingerprint; and **the game's own per-cell body, run on a byte copy of the same cells on the same
thread microseconds earlier with the same cfg/arr/size, agrees with the port and disagrees with the
live run** (`GAME-ON-COPY … ==port true ==real false`, every case). Adding those ~10 µs per
invocation also cut the rate from ~70 to 2 per run. So the live invocation computes on parameters
that differ from the ones the walk reads — the one input not yet snapshotted is the 96-byte Pimp job
element at `TLS+0xC`, which the dispatcher re-reads per cell and from which it sets the globals;
the next build logs its pre/post bytes and the dispatcher's globals on each mismatch. Until that
closes, the port is not shown wrong by any measurement, and the handler is not shown
deterministic on its live inputs either.

Run `d10495fb…` closed the job element too: on 55 mismatches, the 96-byte element at `TLS+0xC`,
the three globals as the dispatcher left them, every sub-slot record, every state byte and the
reference block were all unchanged between the walk and post-handler, and the game-on-copy run
still matched the port on all 55. **x87 stack balance of `FUN_00735840`, `0x00735DD0`,
`0x00735780`, `0x00735680` and the `ftol` at `0x009EE870` is PROVEN on every path** (block
table in the 2026-10-26 Haiku audit; evidence files `haiku_735840.txt` etc. in that session's
scratchpad), so the handler cannot dirty the thread's x87 stack itself; whether it *inherits* a
dirty stack — every compare in it sends a NaN down the "far"/"no band" branch — is what the
`c38fadf3…` build measures (`fnstsw`/`fnstcw` before and after the copy run and at post-handler,
plus a second copy run after the live one).

Runs `c38fadf3…`, `f591105c…` and `261ef178…` measured it. Bracketing the game handler alone with
`fnstsw`, the x87 TOP field moved by **+1 in 92 and +2 in 249 of 2,738,181 invocations** and by 0
in the rest; every one of that run's 61 mismatches sat inside an invocation with a non-zero delta
(57 × +1, 4 × +2), and `fxsave` showed **all eight registers empty both at entry and after** on
every mismatch. A net pop on an empty stack is an underflow, and an underflowing `fstp` stores the
indefinite NaN — into `near_2d`/`near_3d`, which every compare then routes to "far"/"no band":
`0x11 -> 0x01` exactly. The game-on-copy run (same bytes, same thread, microseconds earlier)
never showed the delta and always agreed with the port. Since the code is proven balanced, the pop
is external to the instruction stream; the one thing in the process that touches the main thread's
x87 state from outside is the profiler's sampler (`SuspendThread`/`GetThreadContext` at 250 Hz)
on Rosetta's emulated x87 under CrossOver.

Dose-response, run `20261026-220534` at **1000 Hz**: by frame 6000, **102 mismatches in 2,134,796
invocations (4.8e-5)** against 61 in 2,738,187 (2.2e-5) at 250 Hz — the rate rose with the sampler
rate. That run also crashed 69 s after load on the **worker** thread (ESP `0x0E74…`), inside
job 14's tree (`0x0046A350 → 0x0046A95F → 0x00466B23 → 0x004AC6D7`), with `0xFFC00000` — the
x87 indefinite NaN — in the faulting frame and a garbage pointer in `ESI`; the worker is one of
the eight threads the sampler suspends.

**Closed, run `20261026-221429` at 1 Hz (229 s, 7,298 frames): 3,754,713 clean invocations,
0 port-over, 0 port-under — 100.000%; TOP-delta histogram `[0: 3,754,712, +2: 1]`.** One underflow
in 3.75 M — what 229 suspensions predict from the 250 Hz per-tick rate (~0.0076 × 229 ≈ 1.7) — and
no mismatch. The whole residue since the no-band fix was the profiler's own sampler:
`SuspendThread`/`ResumeThread` on CrossOver's Rosetta-emulated x87 leaves the suspended thread's
stack one or two pops short on a small fraction of suspensions, the handler's next `fstp` writes the
indefinite NaN, and the NaN rides the compares to "far". The sampler never reads or writes FP
context (`CONTEXT_CONTROL` only), so it is the suspend itself. On real hardware, and on the
Shadow PC, none of this exists. **The port of `0xECAED415` is verified against the game on
3,754,713 invocations with no disagreement.** Three of the session's four post-load crashes carried
the same NaN signature (`0xFFC00000`) on sampled threads and are attributed to the same cause;
runs at ≤199 Hz after the game-on-copy run was removed did not crash.

Shadow-mode comparisons of any x87-based handler on this platform must be run with the sampler at
1 Hz (or off); the `.samples` flamegraph and the correctness comparison are mutually exclusive
here.

### 9.9 Replacing the handler — every side effect of the chain (pc-v11, PROVEN)

What a replacement must reproduce, and what it may drop, from a read of every instruction of
`FUN_00735E80`, `FUN_00735840`'s push paths, `FUN_00518830`, the flush `FUN_02503C70` and the
consumer `FUN_00518890` (Haiku audit, 2026-10-26, raw disassembly under that session's
`scratchpad/ring_audit/`):

- **Dispatcher globals.** `FUN_00735E80` writes four globals once per invocation, before the cell
  loop, and restores nothing: `0x00F78524` = cfg (`0x735EAB`), `0x00F7851C` = reference block
  (`0x735EBC`), `0x01175260` = the dword the slot after the cells points at (`0x735ED4`),
  `0x00F78520` = `(float)(2 << ((word[cfg+4] − 1) & 0x1F))` (`0x735EED`; `shift` is read as a
  16-bit word). **Every reader is inside the chain** (`0x735858`, `0x735DD3`, `0x735793`,
  `0x735E1F`, `0x735E0A`, `0x735E24`); `0x01175260` has no reader at all. A replacement that does not
  run the chain need not write them.
- **The lock** is a Win32 `CRITICAL_SECTION` (`EnterCriticalSection` = IAT `0x00B05128`,
  `LeaveCriticalSection` = `0x00B0512C`) whose object is the 24 bytes before the counter:
  counter = object `+0x18`, entries = object `+0x20` (`FUN_00518890` reads the counter as
  `[obj+0x18]` with `obj = &DAT_00DD4770`). Taken **per changed slot** around the entry write and
  the counter bump (`0x735CE9`..`0x735D2F`), per batch call in `FUN_00518830`
  (`0x518838`..`0x518885`, which tail-jumps to Leave and lets its `ret 4` pop the one stack
  argument), per flush in `FUN_02503C70`. Nothing at job or cell level.
- **The state byte is stored after the push, outside the lock**: `0x735D39` (`mov [eax], bl`) on
  the band/no-band path, `0x73597A` (`mov byte [ecx], 0`) on the fade path. No slot reads
  another slot's state, so storing a cell's bytes once the cell is done is equivalent.
- **Entry bytes the game never initialises:** the high word of `+4` and all of `+8..+15` are stack
  residue on both paths (`FUN_00735840` stores nothing to `body+0x86..0x8F`; the fade struct's
  `+6..+15` are never written and `FUN_00518830` copies the record verbatim). The only consumer
  that touches them, `FUN_00518890`, copies `+8..+15` to `0x019C50F8`, which nothing reads.
  Zeros there are consistent with every reader.
- **No capacity check** on the ring anywhere (`0x735CEF`..`0x735D23`, the batch loop, the flush's
  reset to 0). The backing extent was not measured.
- **Counter readers** outside the chain: `0x4BB03F` (`FUN_004BAE80`), `0x4F8659`
  (`FUN_004F8650`), `0x24F2177`, `0x24F9BA7`, and `FUN_00518890` via the object pointer. The
  consumer is called from `0x4F86E4`, `0x24F2239`, `0x24F9BE8`, each after setting
  `DAT_0198D190 = &DAT_00DD4770` and `DAT_0198D194 = 0`. An earlier reading of "readers around
  `0x0064A1xx`" and "the cell-move callback `0x518340` reads the ring" is not supported by any
  xref. The flush `FUN_02503C70` is a writer (counter := 0, then a staged batch push of
  `[0x01174DCC]` records from `0x00ED4700`); its caller is a computed jump from `0x517B50`.

The profiler ASI's replacement (`shipments/mercs2-profiler/client/src/live.rs`) does exactly the
first three: walks the job element as the dispatcher does, runs the port, pushes each changed slot's
entry under the game's critical section (object = counter − 0x18, from the resolved ring site), and
stores the cell's state bytes when the cell is done. `cells_shadow = on` runs the game's handler
instead with the port compared beside it.
