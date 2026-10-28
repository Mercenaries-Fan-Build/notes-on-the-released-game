# Frame-time baseline — v1.1, 2026-10-26 (phase 0 of the performance program)

The first capture with nothing inflating it: shadow mode off, sampler at 250 Hz, every Pimp job
zoned, in-world over a wide area of the map. Everything below is measured from it; nothing is
inferred from the decompile. Where a number is a lead rather than a fact it says so.

## Identity

| what | value |
|---|---|
| session | `output/profiler/captures/20261026-190519.{tracy,samples}` — 4,572 frames, 184.9 s |
| exe | `7a348847e103d71e8c17e7a51a0f3b4d4422e0c9cb46ec6acc9fe5e4e6be36b5` = `v11-patched-securom`, code 1.1 |
| profiler | `mercs2_profiler.asi` `895b01092cdc2c4bb2ed9917458240c2e069d174d1668cb97e949196e8a7cdf7`, `cells_shadow = off` (log line: `cells port shadow mode off`) |
| other ASIs loaded | `lua_bridge`, `multiplayer_restored`, `unofficial_patch`, `windowed_mode` (hashes in the `loadprobe` run) |
| world load | `loadprobe`: `REACHED-WORLD`, GlobalExit at 19:05:02 |
| **platform** | the process holds `wined3d.dll`, `dxwrapper.dll`, `d3d9.dll` **and `winemac.drv`** — this ran under **Wine on macOS (CrossOver)**, i.e. x86 under Rosetta and D3D9 via wined3d. Absolute milliseconds are inflated by both; the ranking and the structure are what this file is for. |

## The frame

**40.45 ms/frame, 24.7 fps.** `RunFrame` covers 99.1% of wall (gap between frames 0.37 ms), so the
frame is the main thread's `RunFrame`. Percentiles of `RunFrame`: p50 38.5 ms, p90 74 ms,
p99 122 ms, max 255 ms.

Two threads matter. Tracy thread 1 = main (tid 196). Tracy thread 2 = the Pimp worker (tid 304,
started at `FUN_00876650`, v1.1 of `FUN_00876400`).

| thread | runs | CPU per frame | waiting per frame |
|---|---|---|---|
| main | `RunFrame`, the game update `0x004C96F0`, and **every decomposed leaf** (17, 21, 5, 9, 20, 15, 31, 28, 22, 18, 25, 8, 24, 19, 4) | ~31 ms | ~3.7 ms in `ntdll` under the drain `0x0087681F`, waiting on the worker |
| worker | the chain **10 → 14 → 12 → 13 → 11**, job 3 (jobtype 0, `0x00631510`), job 16, and the Present detour | ~4.4 ms game code + **~9.4 ms inside wined3d/d3d9/win32u** (the D3D submission) | **22.3 ms in `ntdll`** — blocked while main drains the leaves its chain nodes submitted |

So the threads hand the frame back and forth rather than overlap. The frame is main-thread CPU.
The worker's 21 ms of Tracy zone time is mostly that blocking, which is why zone time alone
misranks it.

Self time per zone needs care: `tracy-csvexport -e` does not subtract children for these zones,
and the naive interval stack must clamp each child to its parent's end (the last child overhangs by
1.5–7 µs, 12,295 cases in 2.5 M) or self times come out negative. The per-thread, clamped pass is
what the tables use.

## Main thread, by cost (ms/frame; sampler and Tracy agree to ~10%)

| ms | what | evidence |
|---|---|---|
| **8.4** | **job 17** `0xECAED415`, 624 invocations/frame, 13.4 µs each — the per-cell LOD band test | Tracy self 8.38; sampler `0x00735E80` 7.45 incl, of which **`FUN_00735840` is 4.3 ms self**, `0x735680` 1.3, `0x735DD0` 0.9, `0x735780` 0.6 |
| **7.3** | **job 21** `0x84F0D9C6`: `0x00878320` → `0x8782B0` → `0x878160` → **`FUN_00876A90`** (5,917 B, x87 math: 4.7 self + ~2.3 in the scalar helpers below) | sampler; 1 invocation/frame |
| ~6.4 | the game update's own work (`0x004C96F0` 15.8 incl minus the 9.35 of drain it calls) — `0x4A40C0` 2.2, `0x70F430` 0.7, `0x429BE0` 0.6, `0x58E740` 0.6, `0x403720` 0.4 | sampler |
| 3.7 | waiting on the worker (`ntdll` under `0x0087681F`) | sampler |
| ~3 | the non-inlined x87 math helpers: `FUN_00401740` (sqrt) 2.1 self, `0x4017B0` 0.7, `0x401630` 0.1 — ~1.7 of it from job 21 | sampler; callers `0x4016E0`, `0x401630`, `0x8583C0`, `0x46EDF0`, `0x493E20` |
| 2.3 | job 5 `0xBD1301EC`, 13.6/frame — the cached-AABB ray cast | Tracy |
| 2.0 | `d3dx9_36.dll` math calls (`D3DXMatrix*`/`Vec3*`) from `0x474990` 0.7, `0x48A8F0` 0.3, `0x488960` 0.2, `0x4917C0`, `0x48F9D0` | sampler |
| 2.0 | job 9 `0xF25AC85B`, 22.6/frame (reads `[ctrl+8]`, disqualified for routing) | Tracy |
| **1.5** | **`unofficial_patch.asi`**, entered from the allocators `0x0084D580` (0.9) and `0x0084AE70` (0.5) — an allocation hook paying ~3.7% of the frame | sampler, by module |
| 1.25 | job 20 `0x3300B3C8` | Tracy |
| 1.2 | `[Mercenaries2.exe]` outside the known code ranges — the SecuROM partition | sampler |
| 0.9 | job 15 `0x156BBFA2`, 112/frame | Tracy |
| ~1.6 | jobs 31, 28, 22, 18, 25, 8, 24, 19, 4 | Tracy |
| 0.3 | `mercs2_profiler.asi` itself | sampler |

Job 17's own counters over the session: 4,963,963 invocations, 31,128 changes — **0.6% of
invocations change anything**. During the earlier shadow run the Rust port of this jobtype added
~1.5 µs to a 13.4 µs zone, i.e. the port is roughly 9× cheaper than the handler it mirrors.

## Worker thread, by cost (ms/frame)

| ms | what |
|---|---|
| 22.3 | `ntdll` — blocked on main |
| 8.3 + 0.45 + 0.7 | `wined3d.dll` + `d3d9.dll` + `win32u.dll`: the D3D submission, reached as job 10 `0x46A420` → `0x466DA0` → `0x84AE70` → `0x84DF50` → `0x757C00` → `0x85B410` → `0x486310` (2.9 ms outside) and the per-viewport loop `0x85ABD0` → `0x855690` (6.7 incl) |
| 1.3 | `FUN_00401740` (sqrt) |
| 0.8 | `0x49F610`; 0.5 `0x836120`; the rest under 0.2 each |
| 0.55 | job 3 `0x00631510` → outside: the candidate Present |

The scheduler map's render-view slots `+0x10`/`+0x14` being bare `ret`s is consistent with this:
rendering is submitted by the worker through job 10's tree, not by `RunFrame` stage 6.

## What phase 0 changes in the plan

1. **Job 17 first, by replacement, not routing.** 8.4 ms of a 40 ms frame, on the main thread,
   99.4% of invocations change nothing, and a validated port already exists that is ~9× cheaper.
   Swapping the handler-table entry is the mechanism `jobs.rs` already uses. Gate: the 0.1% residue
   from the shadow run has to be characterised as harmless or closed before the swap is more than an
   experiment.
2. **Job 21 is the second target, and it is not what the routing audit guessed.** Its body is
   numeric (x87, `D3DXVec3TransformCoord`/`D3DXMatrixMultiply` thunks at `0x96BD70`/`0x96BD76`,
   `0x466060`), not a render-command drain. The N-consumer shape still holds (CS-guarded 32-byte
   ring, per-CPU `0x6000` context, countdown into `0x82CC20`). What it computes is unread.
3. **The scalar math helpers and D3DX calls are ~5 ms/frame** of call overhead around trivial
   operations — the cleanest ship-of-Theseus candidate: inline SSE in an ASI, exact results.
4. **`unofficial_patch.asi` costs 1.5 ms/frame** through the allocators. Which hook, and whether it
   needs to be per-allocation, is a question for whoever owns that ASI.
5. Routing leaves (5, 15, 18, 19) is worth ~3.5 ms on this frame; it stays in the plan but is no
   longer the lead.
6. The worker's 9.4 ms of D3D submission is the render-side floor on this platform and is where
   wined3d vs native d3d9 will differ most.

## Corrections this capture forced

- The worker is not idle. Both captures show it running the entire chain plus Present; the earlier
  "nothing runs on a second thread" claim had checked five leaf jobtypes only.
- `FUN_00876A90` is job 21's body, not a drain spin. `job_routing_safety_audit.md` and the memory
  notes were corrected the same day.
- Ranking by inclusive zone time pointed at the wrong jobtypes twice (job 12 is 99% its children;
  the worker's chain-node zones are 88% waiting). Rank by per-thread self time, then confirm with
  the sampler.

## Job 17 with the port as its handler — 2026-10-27

| what | value |
|---|---|
| session | `output/profiler/captures/20261027-120527.{tracy,samples}` — 4,178 frames, 193.0 s |
| exe | `7a348847…36b5` = `v11-patched-securom`, as above |
| profiler | `mercs2_profiler.asi` `4af4f2b562c659ce1e1f01a617c811674810d4f2277d338364d96e3d54891bbe`, `cells_shadow = off` (log line: `cells port shadow mode off: the port is the jobtype's handler`), sampler at 1 Hz |
| world load | `loadprobe`: `REACHED-WORLD`, GlobalExit at 12:05:10; log sha256 `56345350…1b69` |
| method | `tracy-csvexport -u` on both captures, zone time summed per thread and divided by frames. Job 17 is a leaf zone, so its total is its self time. |

| job 17 | baseline `20261026-190519` | port `20261027-120527` |
|---|---|---|
| invocations/frame | 623.8 | 621.3 |
| ms/frame | 8.378 | **1.225** |
| µs/invocation, mean | 13.43 | **1.97** |
| µs/invocation, p50 / p90 / p99 | 9.5 / 16.2 / 95.4 | 2.1 / 2.3 / 3.5 |
| changes per invocation (ASI counters) | 0.006 | 0.009 |

Job 17 costs **7.15 ms/frame less main-thread CPU**: 6.8× cheaper per invocation, and the p99
tail is gone. The ring is drained as before: 38,426 entries were pushed over the session and the
counter never exceeded 1,643, so the game's flush resets it on the port's entries.

The whole frame is not comparable between these two sessions. `RunFrame` p50 went 38.5 → 37.5 ms
but the mean went 40.1 → 45.9 ms on a heavier tail (p90 74 → 96 ms). The scene was busier: jobs 5,
9, 15, 18 and 8 ran 40–75% more often per frame (job 5 13.6 → 22.0, job 9 22.6 → 39.0, job 15
112 → 161), and they alone add ~4.0 ms/frame. A whole-frame comparison needs the same spot with
the game's handler alone, which the current ASI cannot run: `cells_shadow = on` runs both.
