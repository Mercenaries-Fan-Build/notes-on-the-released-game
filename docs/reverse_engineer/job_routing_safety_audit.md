# Pimp jobtype routing — per-jobtype concurrency audit

**Purpose.** `mercs2_profiler`'s `route::ROUTABLE` may list a jobtype only once its code has been read
for per-CPU and shared mutable state, with the highest Pimp CPU index it tolerates. This file is the
evidence those entries cite. A jobtype absent from here is not cleared.

**Why routing looks safe in principle.** The engine already owns the parallel machinery: jobs 10–15
form a dependency graph whose nodes release successors by `InterlockedDecrement` (`FUN_00518fa0`, via
the split-thunk `0x0046ab80`), and every jobtype is registered into *both* per-CPU handler tables
(`0x019F804C` cpu 0, `0x019F8178` cpu 1) by e.g. `FUN_0046A4A0`. What the PC build lacks is workers:
it does exactly one `CreateThread`, at cpu index 1 (spawn `0x00876800`). Routing adds workers so the
existing graph can actually spread; it does not invent scheduling.

**★ Measured: the game's worker runs the whole chain; the main thread runs every leaf.** Two
captures (`20261026-141014`, 2,249 frames; `20261026-190519`, 4,572 frames, shadow mode off) agree
on the split, read per Tracy thread:

| thread | what runs there |
|---|---|
| 1 — main (tid 196) | `RunFrame`, the game update, and **every decomposed leaf**: 17, 21, 5, 9, 20, 15, 31, 28, 22, 18, 25, 8, 24, 19, 4 |
| 2 — the Pimp worker (tid 304, started at `FUN_00876650`, v1.1 of `FUN_00876400`) | the chain nodes **10, 14, 12, 13, 11**, job 3 (jobtype `0x00000000`, handler `0x00631510`), job 16, and the Present detour (`Overlay`) |

The instrumentation is a handler-table pointer swap in both per-CPU tables (`jobs.rs`), so whichever
thread dispatches a job hits the trampoline and the zone names that thread.

An earlier version of this section said nothing ran on a second thread. That was wrong: it checked
the thread of five *leaf* jobtypes and generalised. The leaves were and are single-threaded — every
job-5 and job-17 instance is on thread 1, and job 5's interval sweep gives max concurrency 1 — but
the chain nodes have been on the worker all along, submitted there and releasing each other through
the fence.

What that proves and does not prove for routing:

- The second per-CPU table, the fence, and the worker's own TLS attach **are exercised** — the worker
  runs five jobtypes a frame through them.
- **Leaf** concurrency is still unexercised: no leaf has ever run on two threads, and no two
  instances of one leaf have ever overlapped. Routing a leaf is still new behaviour for that leaf,
  and its static audit must stand on its own.

Per-thread cost in the clean capture (`20261026-190519`, 40.45 ms/frame, 24.7 fps). Tracy's zones
put the worker inside chain-node zones for **21.4 ms/frame**, but the sampler shows that is almost
all waiting: the worker's EIP is **outside game code 88% of the time (35.6 ms/frame)**, and it runs
only ~4.4 ms/frame of game code. A chain node on the worker submits its leaves (job 12 → ~600
job-17s) and blocks while *main* drains them. Main, for its part, spends ~3.3 ms/frame in `ntdll`
called from the drain `FUN_0087681F` waiting on the worker. So the two threads hand the frame back
and forth rather than overlapping: **the frame is main-thread CPU, ~31 ms of it, plus the waits.**
Routing a leaf to extra workers shortens exactly the part the worker is blocked on.

**★ Every address in this file is v1.1.** The capture is
`7a348847e103d71e8c17e7a51a0f3b4d4422e0c9cb46ec6acc9fe5e4e6be36b5`, which `builds.tsv` names
`v11-patched-securom`, `code_version 1.1`, size 53,944,080. Confirmed independently by the
game-update discriminator: the function start with 124 direct calls is at `0x004C96F0` (v1.1), not
`0x004C9740` (v1.0, and here only a mid-function chunk). Translate with `exemap translate` before
using any of these in a v1.0 context.

**Method.** Function-bounded disassembly of the live, decrypted image
(`game-files/memory-dumps/7a348847_patched-securom/pmc/image.bin`, raw == virtual, sha256 matching the
running exe), via `r2 -n -a x86 -b 32 -m 0x400000 -c "af @ A; pdf @ A"`. Indirect calls are resolved
by following the real object graph in the same capture's `process.dmp`, which radare2 maps at process
VAs. Three cautions learned the hard way:

- **Fixed-size `pd N` windows overrun the function** and attribute the next function's calls to this
  one. Always `af` first, then `pdf`.
- **r2 prints call targets as symbols** (`call fcn.00416cc0`, `call dword [fcn.00b05124]`), so a
  hex-only grep silently reports zero calls. Match `call .*`, then classify.
- **`af` reports a nonsense size on a spliced function** ("Linear size differs too much from the
  bbsum") because the body jumps into the SecuROM partition. Use `pdr`, which still shows the basic
  blocks, and treat the reported `size` as meaningless — `0x006B2930` comes back as 1.9 MB.

Disqualifiers looked for: atomics (`lock`, `cmpxchg`, `xadd`), reads of the Pimp CPU index
(`[ctrl+8]`) — which indicate the handler already behaves differently per CPU — and **every store,
classified by where its base register came from**: stack, TLS arena, caller-supplied, job-parameter
derived, or reachable from a global. Grepping only for absolute-address stores is not enough: a
store through a pointer loaded out of a global is just as shared. For each function below, the
classification is stated, not just "no absolute writes".

---

## Two engine-wide facts that clear whole classes of apparent globals

Both were proven while auditing job 5 and both generalise to every jobtype, so check them before
calling a write a disqualifier.

### `call dword [0x00B0511C]` is `KERNEL32!TlsGetValue`

`rabin2 -i image.bin` names the slot: `0x00b0511c … KERNEL32.dll TlsGetValue` (the IAT holds
`0x75C23660` = `kernel32.dll+0x23660` in the capture, per `modules.json`). The argument is pushed
from one of two globals that hold TLS indices:

| global | value | arena |
|---|---|---|
| `_DAT_00DFD750` | 27 | Havok's thread-local bump allocator: `[+0x20]` cursor, `[+0x2c]` limit, growth via its own vtable `[+0x14]` |
| `_DAT_00DFD754` | 28 | the `Tt…` profiler scope ring: `[+4]` write cursor, `[+0xc]` end, 12-byte records of `{const char *name, rdtsc_lo, …}` |

So **`mov [eax+0x20], ecx` after a `TlsGetValue` is a per-thread cursor, not a global**, and the
same goes for the profiler ring's `mov [ecx+4], edi`. A decompile that shows only
`FUN_…(…)` around these looks like it mutates shared state and does not.

That the Havok scratch arena is per-thread at all is itself evidence: a single-threaded engine has
no reason to pay for a TLS lookup per allocation.

### SecuROM splice residue carries its own non-atomic counters

A spliced function can contain an injected `dec dword [0x2xxxxxx]` whose zero-branch sits out of
line in the SecuROM partition. Example in job 5's chain, at `0x004035AA`:

```asm
0x004035aa  dec dword [0x256fb1b]        ; non-atomic RMW on a global
0x004035b0  je 0x5a0366
...
0x005a0366  mov dword [0x256fb1b], 0x288 ; the zero-branch only re-arms the counter
0x005a0370  jmp 0x4035b6                 ; and falls back in
```

A scan of `image.bin` finds **512 such sites and 512 distinct counters** — no counter is shared
between two sites, so the only possible race is two threads at the *same* site.

The counter **can** run away negative, and the first version of this note wrongly said it could not:

1. A reads 1, writes 0, takes the `ZF` branch;
2. B reads 0 before A's re-arm;
3. A writes `0x288`;
4. B writes `0xFFFFFFFF`.

From there it counts down from −1 and will not hit 0 again until it wraps. The race is still benign,
but **only because this build's zero-branch is a bare re-arm** — never reaching it simply means never
re-arming something with no other effect. That is a property of `v11-patched-securom`, not of the
jobtype. A licensed SecuROM build's zero-branch may run a real trigger, and `ROUTABLE` is keyed by
jobtype hash, not by exe sha256 — so if routing is ever enabled on a non-bypassed exe, these 512
sites must be re-examined.

This is residue, not game logic. Note it, don't let it block a jobtype on this build — but do read
the zero-branch of any *new* counter, since only `0x256FB1B` has been read.

---

## ★ A worker thread must be attached before it may run a routed job

This is a hard prerequisite, and it falls straight out of the TLS finding above: the per-thread
arenas are what make these jobtypes safe, and a thread created by a plain `CreateThread` has
`TlsGetValue(27) == TlsGetValue(28) == NULL`. Neither consumer checks for null —
`0x006B2943` does `mov edi,[ecx+4]` and `0x009333ED` does `mov esi,[eax+0x20]` — so **the first
routed job 5 on an unattached worker faults immediately.**

The fix is not to copy the game worker's TLS values across. That would share one arena between
threads and reintroduce exactly the race this audit cleared. The engine already has the right
route: a per-thread attach/detach pair, and the game calls it for its own threads.

**Attach** — `0x008912F0(arena)`, `cdecl`, one argument:

```asm
0x008912f0  mov eax,[esp+4]      ; this thread's own arena
            push eax
            call 0x0088cfa0      ; SetThreadMemory: inits it (0x0088C880), tears down any old
                                 ; arena, then TlsSetValue(27, arena)
            add esp,4
            call 0x0088e0d0      ; takes a monitor buffer from the arena's free list at [+0x50]
                                 ; (or allocates one), TlsSetValue(28, buf), zeroes its fields
            xor eax,eax
            ret
```

The order is fixed: `0x0088E0D0` reads TLS 27 to find the arena it allocates the monitor buffer
from, so TLS 27 must be set first. Note that it zeroes both `[buf+4]` and `[buf+0xc]`, which makes
the profiler ring's own guard `cmp edi,[ecx+0xc]` fail closed — scope records are skipped, not
mis-written, on a thread that has a buffer but no ring. Non-null is what matters.

**How the game builds the arena it passes** — `0x00413340`, the game-side thread attach:

```asm
0x00413340  cmp byte [0x1174c55], 0      ; config flag
            mov esi, 0x10                ; ctor flag, or 0 when the byte is set
            push 0x10                    ; alignment
            push 0x330                   ; 816 bytes = sizeof(arena)
            call dword [0xbf543c]        ; aligned alloc
            mov ecx, [0xdfd788]          ; the shared memory manager (0x20066F60 in the capture)
            push esi
            push ecx
            mov ecx, eax                 ; this = the fresh block
            call 0x0088c980              ; arena ctor(memoryManager, flag)
            push eax
            call 0x008912f0              ; attach
```

So each thread gets its **own** 816-byte arena, drawing pages from one shared memory manager at
`_DAT_00DFD788`. The arena is per-thread; the manager beneath it is not. Whatever serialises that
manager is the same code path the game's own worker already uses, so routing does not add a new
requirement there — but it is the place to look first if extra workers misbehave under memory
pressure.

**Detach** — `0x00891320()`: releases the monitor buffer (`0x0088E120`), calls the arena's own
vtable `[+0xc]` to tear it down, then `SetThreadMemory(NULL)`.

**Still to establish before enabling workers:**

- what `route.rs`'s worker startup does today — it creates threads but is not yet shown to attach
  them;
- whether anything rewinds the arena cursor. `0x00933250` advances `[+0x20]` twice and never
  restores it, and no rewind appears in `0x006B293B` or `0x004156F0`. If the reset is driven per
  frame over a registry of known threads, an unattached-but-running worker would grow through the
  vtable `[+0x14]` path without bound. Find the reset before trusting a long run.

---

## ★ The frame graph is a serial CHAIN — there is no inter-node parallelism

This was worth checking because the once-per-frame jobs look like the big prize. They are not
available.

**The fence.** `FUN_00518FA0(nodes)`, reached through the split-thunk `0x0046AB80`
(`jmp dword [0x24DC4EC]` → `0x00518FA0`), takes the node index in **`eax`** — a register argument
the decompiler drops, which is why this read needs the disassembly. Node stride `0x30`:

| offset | field |
|---|---|
| `+0x10` | pending-dependency counter |
| `+0x14` | inline successor array, 4 bytes per entry, indexed `[ebx+edi*4+0x14]` |
| `+0x24` | overflow successor pointer, used when the index is out of range |
| `+0x28` | successor count |

It walks the successors and tail-jumps to `KERNEL32!InterlockedDecrement` (IAT `0x00B05180`) on
each successor's `+0x10`. The continuation at `0x0051900B` does `add eax,1; cmp eax,1; jne` — i.e.
**when the decremented counter reaches zero**, it calls the ready-dispatch `0x0046AA60(nodes, idx)`.

**The nodes.** Exactly five handlers call the fence, each with its node index as an immediate, and
they are the jobtypes themselves:

| job slot | jobtype | handler | node index | own work before the fence |
|---|---|---|---|---|
| 10 | `0xCB414134` | `0x0046A270` | **0** | `0x0046A420` |
| 14 | `0xE4FBF71F` | `0x0046A350` | **1** | `0x0046A910(nodes, float)` — submits all of job 15 |
| 11 | `0x5D9A2C1A` | `0x0046A290` | **2** | `0x0074CE90`, then vtable `[+0xc]` on `[0xDFB2F8]` |
| 12 | `0x5F2080D1` | `0x0046A2C0` | **3** | gate `[0x117526E]` && `[nodes+0x109]` → `0x0085AC50` |
| 13 | `0x17D1EDA3` | `0x0046A300` | **4** | gate `[0x117526E]` && `[nodes+0x108]` → `0x00480310` |

Job 15 (`0x0046A380`) does **not** call the fence — it is job 14's leaf child.

**The edges, read live.** The node array base is the global `_DAT_00E79DFC` = `0x14A1718` in the
capture. Five nodes decode as:

| node | job | `+0x28` count | `+0x14` successors |
|---|---|---|---|
| 0 | 10 | 1 | → 1 |
| 1 | 14 | 1 | → 3 |
| 2 | 11 | **0** | sink |
| 3 | 12 | 1 | → 4 |
| 4 | 13 | 1 | → 2 |

Every node has out-degree ≤ 1 and in-degree ≤ 1: **`10 → 14 → 12 → 13 → 11`, a linked list.**
Confirmed empirically — over all 2,250 frames in the capture that exact order occurs 2,250 times
with no other ordering observed, and the immediate-successor histogram is a clean cycle
(`10→14` 2250, `14→12` 2250, `12→13` 2250, `13→11` 2250, `11→10` 2249 across the frame boundary).

**Consequences.**

- The engine *supports* DAGs — the counter, the successor list, the overflow pointer and the
  zero-triggered dispatch are all general. This build's frame graph simply is not one. So the
  `InterlockedDecrement` fence buys sequencing, not concurrency, and adding workers cannot make
  jobs 21/14/11/20 overlap. That ~19.5% of wall is not addressable by routing.
- Conversely this is good news for routing *leaves*: because the chain is serial and each parent
  drains its own children, routing a leaf jobtype cannot reorder the chain. The parent still
  blocks on its fence while workers chew its children, which is exactly `route::wait_draining`.
- The addressable budget is therefore the decomposed leaves only. Not disqualified:
  job 17 (8.27%, 626/frame), job 5 (6.18%, 34), job 15 (1.53%, 187), job 18 (0.74%, 41),
  job 19 (0.09%, 115), job 4 (0.09%, 14) — about **16.9% of wall**, of which job 17 is half.

---

## Triage of the multi-invocation jobtypes

Only jobtypes dispatched many times per frame benefit from spreading, and per the chain above a
once-per-frame node cannot overlap other nodes either — so this list *is* the addressable set.

Shares are **self time** as a percentage of wall, from
`output/profiler/captures/20261026-141014.tracy` over 2,249 frames (absolute values inflated by live
shadow mode + sampler; the ranking is what is meaningful). Self time had to be computed by hand:
`tracy-csvexport -e` returns the inclusive figure unchanged for these zones, and the naive
interval-stack attribution is wrong because each parent's **last** child zone overhangs the parent's
recorded end by 1.5–7 µs (12,295 cases in 2.5 M), which otherwise swallows the next parent and can
even make a jobtype's self time negative. Clamp each child to its parent's end.

The distinction matters: by inclusive time job 12 is 5.72% of wall, but **99% of that is its 922,396
job-17 children** — its own self time is 0.52%. Ranking by inclusive time points at the wrong
jobtypes.

| slot | jobtype | handler | calls/frame | share | handler shape | verdict |
|---|---|---|---|---|---|---|
| 17 | `0xECAED415` | `0x00735E80` | ~625 | 8.31% | dispatcher **writes 4 globals** (`0xF78524`, `0xF7851C`, `0x1175260`, `0xF78520`) re-read at ~6 sites | **blocked** natively; see §job 17 |
| 5 | `0xBD1301EC` | `0x0040B1D0` | ~34 | 6.18% | per-thread only; every scratch arena is TLS | **nothing disqualifying**, 3 items open (§job 5) |
| 9 | `0xF25AC85B` | `0x00695C90` | ~37 | 3.58% | reads `[ctrl+8]` and branches; writes `0xEDB8B0` | **disqualified** |
| 15 | `0x156BBFA2` | `0x0046A380` | ~186 | 1.53% | globals indexed by the job's own index (`[i*4+0xE8A280]`, `0x127BEC0+i*32`, `0xE8B220+i*16`) then vtable `[+0x24]` | candidate, needs index-disjointness proof |
| 18 | `0xA7F731AC` | `0x004FD3D0` | ~41 | 0.74% | global gate byte `0xED0D0F`, global table `0xED3578`, `0xDF8110` | needs work |
| 31 | `0x48F39557` | `0x00429790` | ~1.6 | 0.55% | per-thread only, simplest of all | **cleanest shape**, low payoff |
| 8 | `0x305A13A0` | `0x00695A80` | ~37 | 0.25% | reads `[ctrl+8]`; global float writes | **disqualified** (job 9 family) |
| 4 | `0xF9ED4429` | `0x0040AD90` | ~14 | 0.09% | per-thread + global read `0x1174034` | marginal |
| 19 | `0xC28EF815` | `0x0084AE50` | ~115 | 0.09% | not yet read | unread; high count, trivial cost |

Everything not in this table is a once-per-frame node, and the chain above makes those unroutable
regardless of their handler's shape. The four largest — job 21 (7.12% self), job 14 (6.53%),
job 11 (3.57%), job 20 (2.25%) — total ~19.5% of wall that routing cannot touch at all. Reducing
those means changing what the handler does, not where it runs — with one lead:

**Job 21 (`0x84F0D9C6`, handler `0x00878320`) is shaped as an N-consumer queue drained by one
consumer.** It takes a ring from its job parameters (`+0x44` → `_DAT_01175640`, context `+0xac` →
`_DAT_01175644`), and loops: `EnterCriticalSection`, pop one 32-byte record (`[ring+4]` cursor vs
`[ring][+0x18]` count), `LeaveCriticalSection`, dispatch it through `0x008782B0` → `0x00878160`.
That dispatcher picks a **per-CPU 0x6000-byte context** by the Pimp CPU index:
`0x014153E0 + [ctrl+8]*0x6000`. On an empty ring it calls `0x0082CE10`, which
`InterlockedDecrement`s a completion counter at `job+0x58` and runs `0x0082CC20` only when it
reaches zero. A CS-guarded pop, per-CPU scratch and a countdown-to-continuation are the three parts
of a multi-consumer drain; this build submits one consumer. Submitting N is the engine's own route
for this 7% — after `0x00878160` is audited and the submitter (whoever sets `job+0x58`) is read.
Unlike jobs 8/9, its `[ctrl+8]` read selects a private context rather than branching behaviour.

## job 5 (`0xBD1301EC`) — a ray cast; nothing disqualifying, three items open

Physics work, and specifically a **cached-AABB ray cast**: the chain's profiler scope is
`"TtRayCstCached"` (`0x00BCEA24`) and the interface struct it dispatches through carries the RTTI
name `kCachedIdentityAAbb` (`0x00BD2240`). The handler derives everything from thread-local state;
no global is touched:

```asm
0x0040B1D0  mov eax, fs:[0x2c]          ; TLS array
            mov ecx, [eax]              ; TLS[0] = Pimp control block
            mov eax, [ecx + 0xc]        ; this thread's current job
            mov ecx, [eax + 0x10]
            add ecx, [eax + 0xc]
            mov edx, [eax + ecx*8 + 0x20]   ; its own per-slot table
            mov eax, [eax + 0x20]
            call 0x00409480
```

Cleared so far (function-bounded, zero writes to absolute/symbol targets, zero atomics in any of
them):

| function | size | notes |
|---|---|---|
| `FUN_00409480` | 300 B | writes results only into its own job slot (`+0x48`…`+0x74`); reads the world pointer global `DAT_0117404C`; `QueryPerformanceCounter` ×2 |
| `FUN_00407CF0` | 115 B | `__fastcall`, stateless 12-dword copy, source and destination both caller-supplied |
| `FUN_00415840` | 12 B | SecuROM split-thunk → `_DAT_024CDBD8` = `0x00581DFD` → `sub esp,0x25c` → `jmp 0x0041584C` |
| `0x0041584C` (spliced body) | — | assembles the query struct entirely on the **stack** (`esp+0x10`…`esp+0xA0`) from two float3 vectors; only global read is the constant `1.0f` at `0xB9B664` |
| `FUN_004156F0` | — | thiscall; vtable dispatch (below) |
| `FUN_004159C0`, `FUN_00416F90`, `FUN_00416CC0` | — | clean |
| `0x0092F7B0` | leaf | **resolved** indirect target; no calls at all; reads `this+0x40…0x60`, negates, writes the caller's buffer — safe for concurrent readers |

The one indirect call in that chain, `call edx` at `0x0041571C`, dispatches as

```asm
mov ecx, [eax + 0x23c]   ; eax = world (DAT_0117404C)
mov edi, [ecx + 0x54]
mov edx, [edi]           ; vtable
mov edx, [edx + 0x3c]    ; slot 15
call edx                 ; thiscall, this = edi
```

and was resolved against the live capture: `DAT_0117404C` = `0x20110050`, `+0x23c` → `0x20007800`,
`+0x54` → `0x1FFFFE00`, its vtable `0x00B5A964`, slot `+0x3c` → **`0x0092F7B0`**. The whole vtable
lies in `0x92xxxx`–`0x93xxxx`, a single module (Havok).

### The five edges that were open, and how each closed

**1. `0x006B2930` — a SecuROM splice, now resolved.** `af` reports a bogus 1.9 MB size because the
function jumps into the partition; `pdr` shows the shape. The prologue runs
`push ebp; mov ebp,esp; and esp,0xFFFFFFF0; jmp 0x004DE2F6`, and the stub at `0x004DE2F6` is a
return-address swap, not a call:

```asm
0x004de2f6  mov eax, [0xdfd754]      ; one relocated instruction: the profiler TLS index (28)
0x004de2fb  push esi
0x004de2fc  pushfd
0x004de2fd  mov esi, [0x24d88dc]     ; 0x4365F852
0x004de303  add esi, [0x965597]      ; + 0xBD0530E9
0x004de309  xchg dword [esp+4], esi  ; = 0x006B293B, swapped over the saved esi
0x004de30d  popfd
0x004de30e  ret                      ; -> 0x006B293B, esi restored
```

`0x4365F852 + 0xBD0530E9 = 0x1_006B293B`, truncating to **`0x006B293B`** — the instruction after
the `jmp`. So the splice is a detour that steals one instruction and returns. The real body is
`0x006B293B` (264 B): it fills the caller's stack-local callback object (`[esi+4…+0x44]`), opens and
closes a `"TtRayCstCached"` profiler scope, and makes one virtual call. No absolute writes, no
atomics.

**2a. `0x006AF000`** → `jmp dword [0x24D7788]` → `0x02500880`, in the SecuROM partition but plain
code, not VM-virtualised. It emulates a call with `push 0x2500895; push 0x8CE0F0; ret`, and
`0x008CE0F0` → `jmp dword [0x24CD080]` → `0x0050F146` → `0x008CE0F8`. That whole chain is one
constructor: every write goes to `[eax]`/`[eax+8…+0x20]` or `[esi]/[esi+8…+0x74]`, i.e. the
caller's stack-local ray-cast query, and it calls nothing further. Clean.

**2b. `0x00416D70`** → `jmp dword [0x24DB47C]` → `0x00403580` (99 B). A hit-list copy: clamps the
count to 64 (`cmp ecx,0x40`), stores it at `[eax+0x100]`, then copies that many dwords into `eax`,
the caller's object. The only global mutation is SecuROM's own `dec dword [0x256FB1B]` — see the
splice-residue section above. Clean.

**3. `0x00401780`** (15 B) — `fld dword [ebp+8]; fabs; ret`. A pure leaf. Clean.

**4. `0x006AEFA0`** (84 B) — a multiple-inheritance constructor writing five vtable pointers into
`[ecx]`, `[ecx+8]`, `[ecx+0xc]`, `[ecx+0x10]`, `[ecx+0x14]`. The `0x00B586xx` values are
immediates, not reads. **Zero callees**, so this edge closes with nothing beneath it.

**5. `call eax` at `0x006B2A09` — resolved to `0x00933250`.** Its `this` is `arg_8h` of
`0x006B293B`, which the caller `0x004156F0` loads at `0x00415708` as `[[eax+0x23c]+0x54]` — the
*same* object as the already-resolved `call edx` at `0x0041571C`. From the capture:
`_DAT_0117404C` = `0x20110050` → `+0x23c` → `0x20007800` → `+0x54` → `0x1FFFFE00`, vtable
`0x00B5A964`. Slot `+0x3c` is `0x0092F7B0` (as before) and slot **`+0x54` is `0x00933250`**.

### Below `0x00933250` — the ray cast itself

`0x00933250` (1616 B) has **zero atomics and zero writes to any absolute address**. It makes exactly
two `TlsGetValue` calls (`0x009333E4`, `0x00933549`) and **both are index 27** — each preceded by
`mov ecx,[0xDFD750]` at `0x009333AF` and `0x00933549`. There is no profiler scope inside this
function; the `"TtRayCstCached"` scope belongs to `0x006B293B` above it, which is the only user of
index 28 in the chain.

Both are therefore bump allocations: `cmp ecx,[eax+0x2c] / mov [eax+0x20],ecx`, with the growth path
on the arena's own vtable `[+0x14]`.

Classifying its stores by base register: `[eax+0x20]` ×2 is the TLS-27 arena cursor,
`[esp+edx+0x94]` is a stack slot, and `mov byte [esi], 0x88` at `0x009338A3` writes a caller-supplied
out-pointer. **Nothing is stored through `edi`** — the `this` reachable from the global
`_DAT_0117404C`, which is the one base that would make a store shared. That was checked explicitly,
not inferred from the absence of absolute-address stores.

Its six indirect calls reduce to two targets:

| site(s) | dispatch | target |
|---|---|---|
| `0x00933408`, `0x00933582` | arena vtable `[+0x14]` | the thread-local arena's own grow path |
| `0x009336B8`, `0x00933738`, `0x009337B8`, `0x0093382C` | `[arg_ch][+4]`, three axes each | **`0x006B2770`** |

`arg_ch` is not dynamic: it is `esi` of `0x006B293B` = `&var_30h_2`, a **stack local of
`0x004156F0`** whose interface pointer is written there as an immediate (`0x004157C2`:
`mov dword [var_30h_2], 0xB58D2C`). `[0xB58D2C+4]` = `0x006B2770`.

`0x006B2770` (435 B) is the per-hit callback: it transforms the hit into the callback object's
frame with SSE and writes the result to `[esi+0x20…+0x40]`, `esi` being that same caller-local
object. **Zero atomics, zero absolute writes.** It makes two further calls:

- `call eax` at `0x006B27B5` — `[[esi+8]+4]`. `[esi+8]` is set in `0x006B293B` to `query+0x14`,
  and `0x004156F0` writes that field's interface pointer as an immediate at `0x00415814`
  (`0xBD2238`). `[0xBD2238+4]` = **`0x00725070`** (60 B): reads a layer index
  `[arg_ch+0x1c] & 0x1f`, tests that bit in the filter mask `[arg_8h+0x24]`, and stores the
  boolean to the caller's out-pointer `[arg_4h]`. A leaf; no calls, no globals. Clean.
- `call edx` at `0x006B290C` — `[[node]+0x10]`, where `node` is read out of the traversed
  structure at a byte-encoded offset (`movsx ebx, byte [eax+5]`; `mov ecx,[ebx+eax]`). **This one
  is genuinely dynamic**: the target depends on the collidable/shape type the ray met.

### What is still open on job 5

**1. `call edx` at `0x006B290C`** — the only unresolved call target in the chain. `edx` is
`[[node]+0x10]`, where `node = [arg_8h + movsx(byte [arg_8h+5])]`: a pointer read out of the
traversed structure at a byte-encoded offset, so the target depends on the shape the ray met.

Resolve it by **enumerating the shape vtables in the image** and reading slot `+0x10` of each. Do
not settle for logging the observed targets over a run: that bounds the edge by one run's geometry
rather than by the code, and the set must include Pandemic's own `WpMeshShape16` (game code, not
Havok) because terrain collision is a MOPP-baked mesh. A run log is useful only to *confirm* the
slot mapping once the static set is in hand.

First check whether byte `[+5]` is an owner-offset field on a typed broadphase handle — if it is,
`[node]` is the collidable's shape pointer and `[[shape]+0x10]` is the shape's ray-cast virtual,
which makes the enumeration straightforward. That layout is a guess and must be verified, not
assumed.

**2. Index-disjointness of the job's own output buffer.** `FUN_00409480` writes `+0x48…+0x74`
through a pointer taken from the job's parameters. The same standard applied to job 15 applies
here: show that pointer is distinct across the ~34 invocations per frame. Two invocations writing
one buffer would be a race no amount of per-thread scratch fixes. This has not been done.

**3. Worker attach and the arena reset** — see the prerequisite section above.

Note what is *not* a concern. Every scratch buffer in this chain — profiler ring, Havok arena, query
object, callback object, hit list — is either TLS-indexed per thread or a stack local of
`0x004156F0`, and nothing is stored through the world-reachable `this`. On those grounds two
concurrent job-5 invocations share nothing. Items 1–3 are what stand between that and listing it.

## job 17 (`0xECAED415`) — blocked for the native route

Fully decoded (see `pimp_job_system_code_map.md` §9). The obstacle is specific and not in the body:
the dispatcher `FUN_00735E80` writes `PTR_DAT_00F78524` (cfg), `PTR_DAT_00F7851C` (points),
`PTR_DAT_01175260` and `_DAT_00F78520` (cell size) as plain globals, and `FUN_00735DD0` /
`FUN_00735780` / `FUN_00735840` re-read them at roughly six sites. Two invocations in flight would
race. Routing it natively therefore requires either making those four per-CPU (~10 instruction sites,
each needing a trampoline because the absolute-address loads are too short to patch in place) or
running a reimplementation that takes its inputs as arguments.
