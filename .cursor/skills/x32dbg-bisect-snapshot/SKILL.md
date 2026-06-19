---
name: x32dbg-bisect-snapshot
description: >-
  Capture x32dbg debugger snapshots for patch-WAD bisection variants (Mercenaries 2
  DLC port). Use when the user asks to grab/snapshot a bisect variant, capture
  main-menu or load state from x32dbg, or record debugger evidence for
  output/_bisection_results/.
---

# x32dbg Bisection Snapshot Capture

Read-only debugger capture for patch-WAD bisection. **The user deploys WADs manually**
to `data\vz-patch.wad` and pauses (or asks you to pause) the game. The agent reads
debugger state and writes JSON — do not rebuild WADs or modify the debuggee.

## Prerequisites

- x32dbg attached to `Mercenaries2.exe` with MCP server `user-x32dbg` enabled
- `IsDebugging` must be `true`
- Process must be **paused** before capture (`DebugPause` or user F12)

If `IsDebugging=false` or registers are all zero, x32dbg is not attached or port 8888
is bound by another instance — ask the user to fix the debug session.

## Output layout

```
output/_bisection_results/
  <variant-id>/
    main-menu/snapshot.json       # healthy baseline (optional)
    load-broken/snapshot.json     # failed load / hang / crash
    load-success/snapshot.json    # successful VZ load (in-world pause)
    manifest.json
  manifest.json                   # root index — update every capture
```

Schema: `bisect_snapshot_v1`. Good reference snapshots:

| Variant | Snapshot | Use as template for |
|---------|----------|---------------------|
| `step2-retest` | `main-menu` | healthy menu baseline |
| `dedup-strip` | `load-success` | successful load |
| `block-index-patch1` | `load-broken` | game spin livelock |
| `q2-lo-hi` | `load-broken` | GlobalEnter livelock |

## Capture workflow

Copy this checklist:

```
- [ ] Confirm variant_id with user (e.g. patched-animation-table)
- [ ] IsDebugging → true
- [ ] DebugPause (if still running)
- [ ] GetRegisterDump, GetThreadList, GetCallStack
- [ ] MemoryRead @0x00DFC2F8 and @0x01176078 (16 bytes each)
- [ ] MemoryRead @csp (64 bytes) → stack_esp u32 LE words
- [ ] DisasmGetInstructionRange @cip (4–8 insns)
- [ ] Classify from debugger evidence (see reference.md)
- [ ] Write snapshot.json + update both manifests
```

### MCP tools (preferred)

Server: `user-x32dbg`. Read tool schemas under the MCP descriptors folder before calling.

| Tool | Purpose |
|------|---------|
| `IsDebugging` | Gate — abort if false |
| `DebugPause` | Pause running process |
| `GetRegisterDump` | Full register set (`cip`, `csp`, …) |
| `GetThreadList` | Main thread + worker @ start `0x876400` |
| `GetCallStack` | Stack frames with symbols |
| `MemoryRead` | Watch windows + stack at ESP |
| `DisasmGetInstructionRange` | Instructions at main CIP |
| `GetModuleList` | exe base/size (optional) |

### HTTP fallback

If MCP is unavailable, user can pause manually and run:

```bash
.venv/Scripts/python.exe tools/capture_bisect_snapshot.py \
  --variant <variant-id> \
  --snapshot main-menu \
  --note "optional note"
```

Script only supports `main-menu` and `load-broken`. For `load-success`, use MCP
capture or extend the script.

## Snapshot JSON fields

Required in every snapshot:

```json
{
  "schema": "bisect_snapshot_v1",
  "variant_id": "<variant-id>",
  "snapshot_id": "main-menu | load-broken | load-success",
  "iso_timestamp": "<UTC ISO>",
  "is_debugging": true,
  "is_debug_active": false,
  "state": "PAUSED | PAUSED_LIVELOCK | PAUSED_IN_WORLD | PAUSED_FAULT",
  "note": "<human context: WAD name, what user was doing>",
  "outcome": "load_success | load_broken  (load snapshots only)",
  "regs": { },
  "main": { "tid", "cip", "cycles", "waitReason" },
  "worker_876400": { "tid", "cip", "cycles", "waitReason" },
  "callstack": { "total", "entries" },
  "stack_esp": ["0x........", ...],
  "memory_windows": { },
  "disasm_at_cip": [ ],
  "exe_module": { "name", "base", "size" }
}
```

Load-broken snapshots should add a `fault` object:

```json
"fault": {
  "kind": "globalenter_livelock | game_spin_livelock | loading_stall | null_pointer_av | other",
  "main_cip": "0x........",
  "worker_cip": "0x........",
  "interpretation": "one-line debugger-based summary"
}
```

## MCP quirks

**Register dump vs currentThread:** `GetRegisterDump` often reflects the **main
thread** even when `GetThreadList.currentThread` points elsewhere. Always correlate:

1. Find thread with `threadName == "Main Thread"` or `startAddress == 0xb04c2e`
2. Compare its `cip` to `regs.cip`
3. Document in `capture_thread` when they differ

**Worker thread:** Identify by `startAddress == 0x876400`. Report as `worker_876400`.

**Memory hex parsing:** MCP returns raw hex (no spaces). Decode stack as little-endian
u32: every 8 hex chars → `0x........`.

## Memory watch addresses

Fixed anchors for Mercenaries2.exe (same in every capture):

| Label | Address | Interpretation |
|-------|---------|----------------|
| `render_view_slot_0xDFC2F8` | `0x00DFC2F8` | First u32 — `0x017CFAF0` = healthy/in-world; `0x0000FFFF` = loading stall |
| `globalenter_stride_gate_0x1176078` | `0x01176078` | First u32 — `0x38` + stride active can mean GlobalEnter path; all zeros = no GlobalEnter gate |

Do **not** classify from plausibility heuristics alone — use the fault taxonomy in
[reference.md](reference.md) which is calibrated against known-good and known-bad
snapshots.

## Classification (summary)

Classify only from debugger evidence. Quick decision tree:

```
Main @ 0x67d130 with "jnz 0x67d130"?
  → game_spin_livelock (load_broken)

Main @ 0x4b1180..0x4b1300 OR esi≈0x2004FFB0 with stride 0x38?
  → globalenter_livelock (load_broken)

Render u32[0] == 0xFFFF, main in ntdll/kernel32?
  → loading_stall (load_broken)

Worker @ 0x7705951c (Sleep), render 0x017CFAF0, deep game callstack?
  → load_success / PAUSED_IN_WORLD

Main+worker both @ Sleep on main menu?
  → main-menu healthy baseline
```

Full signal table: [reference.md](reference.md).

## Manifest updates

After writing `snapshot.json`, update:

1. `output/_bisection_results/<variant-id>/manifest.json` — add snapshot entry with
   `captured_at`, `state`, `classification`/`outcome`, relative `path`
2. `output/_bisection_results/manifest.json` — add/update variant key with snapshot id list

Use forward slashes in manifest paths.

## Agent boundaries

| Do | Don't |
|----|-------|
| Pause and read debugger state | Rebuild or deploy WAD variants |
| Write snapshot JSON + manifests | Set breakpoints or switch threads |
| Report classification + key signals | Guess endianness/correctness from register "plausibility" |
| Note incomplete captures (`capture_incomplete: true`) if MCP drops mid-session | Resume/run the game unless user asks |

## Reporting to user

After capture, summarize:

- Variant id and snapshot id
- Outcome (`load_success` / `load_broken`) and fault kind if broken
- Main CIP, worker CIP, render view, stride gate
- Whether it matches a known class (GlobalEnter, spin @ 0x67d130, etc.)
