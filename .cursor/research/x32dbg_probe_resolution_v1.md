# x32dbg MCP Probe Resolution Plan (v1)

This document defines the first live-run address/probe workflow for mixer call-chain capture up to `PalSoundEngine::MixSources`.

Status tags:
- `confirmed`: directly observed in current docs/code.
- `planned`: actionable, but not yet executed in a completed live run.
- `unknown`: intentionally unresolved and requires manual confirmation.

## Scope and Inputs

Confirmed inputs used for this v1 plan:
- `tools/x32dbg/x64dbg.py` MCP wrapper (tool surface and endpoint mappings).
- `docs/audio_crash_analysis.md` call-chain and crash site addresses.
- `docs/runtime_trace_loop.md` required probe coverage criteria.
- `mods/engine_trace_asi/config/trace_profile.example.json` and `mods/engine_trace_asi/src/engine_trace_asi.cpp`.

## Executable Fingerprint Policy

Address packs must include all of these fields for reproducibility:
- `exe.path` (absolute path used during run)
- `exe.size_bytes` (on-disk file size)
- `exe.sha256` (on-disk SHA-256)
- `exe.module_name` (expected debugger module identity, usually `Mercenaries2.exe`)

Reason:
- This allows deterministic pack-to-binary binding before any probe resolution is attempted.
- If fingerprint mismatch occurs, automation must stop before arming required probes.

Known limitation (`unknown`):
- Current x32dbg MCP endpoint set does not provide a direct in-process module hash.
- v1 checks file fingerprint from disk and module identity/base from debugger; it does not cryptographically attest in-memory image bytes.

## RVA vs VA Policy

v1 policy:
- Canonical storage uses module-relative RVA (`address.rva`).
- Absolute VA (`address.va`) is optional metadata for historical/reference values.
- Runtime resolved address is always `module_base + rva`.

Why:
- RVA survives ASLR/rebasing.
- Existing analysis docs use absolute VAs, so optional `va` keeps continuity for human review.

Validation rules:
- A required probe must have either `rva` or `va`.
- If both are present, resolver emits mismatch if `va - module_base != rva`.
- For first-pass packs that only have `va`, resolver derives `rva` from runtime module base and marks result as `derived_rva`.

## v1 Probe Catalog

This catalog maps required/optional probes and ties each to call-chain stages.

### Required probes (v1 acceptance gate)

1) `audio.mixer_thread.loop` (`confirmed`)
- Stage: mixer thread loop entry (`0x831EE0` family in docs).
- Role: prove thread loop is active in `audio_stream_runtime`.
- Runtime event mapping:
  - entry: `audio.mixer_thread.loop.entry`
  - exit: `audio.mixer_thread.loop.exit`

2) `audio.palsoundengine.mixsources.entry` (`confirmed`)
- Stage: `PalSoundEngine::MixSources` function entry (`0x836610`).
- Role: prove call-chain reached mixer function.
- Runtime event mapping:
  - entry: `audio.palsoundengine.mixsources.entry.entry`
  - exit: `audio.palsoundengine.mixsources.entry.exit`

3) `audio.palsoundengine.mixsources.callsite` (`confirmed`)
- Stage: crash-adjacent window around callsite (`0x83664C`..`0x836651`).
- Role: capture pre-deref/pre-call state in the exact hazardous instruction region.
- Runtime event mapping:
  - entry: `audio.palsoundengine.mixsources.callsite.entry`
  - exit: `audio.palsoundengine.mixsources.callsite.exit`

### Optional probes (v1.1 candidates)

4) `audio.palsoundengine.mixsources.crash_ip` (`planned`)
- Stage: exact crash instruction (`0x83664E`).
- Use: high signal for classifier runs; not required for lifecycle acceptance.

5) `audio.palsoundengine.mixsources.call_dispatch` (`planned`)
- Stage: post-window call dispatch point (`0x836651`).
- Use: distinguish "window reached" vs "dispatch reached".

Unknowns to keep explicit:
- Calling convention-safe hook strategy for instruction-window probes (`unknown`).
- Whether all target addresses remain stable across retail variants and cracked builds (`unknown`).

## Call-Chain Stage -> Probe Event Map

Expected call-chain stage progression for first live run:

1. `mixer_thread_wait_loop` -> `audio.mixer_thread.loop.entry`
2. `enter_mixsources` -> `audio.palsoundengine.mixsources.entry.entry`
3. `callsite_window` -> `audio.palsoundengine.mixsources.callsite.entry`
4. `dispatch_or_fault_boundary` -> optional confirmation via `audio.palsoundengine.mixsources.callsite.exit` and/or optional crash probe

Operational rule:
- If stage 1 is present but stage 2 is absent, treat as upstream routing issue.
- If stage 2 is present but stage 3 is absent, treat as address drift or hook placement mismatch.
- If stage 3 present and crash persists, triage memory/global state windows per `docs/audio_crash_analysis.md`.

## What x32dbg MCP Can Automate Immediately

Directly supported now (`confirmed` from `tools/x32dbg/x64dbg.py`):
- Read debugger/process state: `IsDebugging`, `IsDebugActive`, `GetRegisterDump`, `GetThreadList`.
- Resolve module base: `GetModuleList`, `MemoryBase`.
- Address-level inspection: `DisasmGetInstructionRange`, `GetBranchDestination`, `XrefGet`, `XrefCount`, `StringGetAt`.
- Breakpoint management: `DebugSetBreakpoint`, `DebugDeleteBreakpoint`, `SetHardwareBreakpoint`.
- Stack/context capture: `GetCallStack`, `RegisterGet`, `MemoryRead`, `MemoryGetProtect`.
- Symbol query when available: `QuerySymbols`.

Automatable with the new resolver script (`planned`, implemented):
- Validate address pack schema essentials.
- Verify local executable fingerprint fields are present and comparable.
- Resolve per-probe VAs against live module base.
- Emit runtime-ready resolved probe list with status flags.

## Manual Confirmation Still Required in x32dbg (v1)

Manual checks remain mandatory:
- Confirm the debugger is attached to the intended process instance when multiple launches occur.
- Confirm disassembly semantics at resolved addresses (prologue/callsite intent), not just numeric match.
- Confirm instruction-window probe placement safety and side effects.
- Confirm required probes produce expected event flow during real gameplay phase transitions.

Reason:
- Current MCP flow can resolve addresses and inspect state, but semantic correctness of hook placement is still analyst-verified.

## Fallback Strategy for Address/Symbol Drift

When required probe resolution fails:

1) Fingerprint gate:
- If executable fingerprint mismatch -> stop and require a new/updated address pack.

2) Module-base recompute:
- Re-resolve from `GetModuleList` and recompute `module_base + rva`.

3) Symbol-assisted lookup (best-effort):
- Use `QuerySymbols(module)` and map known symbol names when present.
- Treat symbol lookup as advisory; many retail builds lack useful symbols.

4) Pattern/manual triage:
- Use `DisasmGetInstructionRange` and `GetBranchDestination` to validate neighboring instruction intent.
- Use `XrefGet` for expected call/xref density around prior known anchors.
- Optionally use `PatternFindMem` for known signatures if documented in pack metadata.

5) Escalation:
- Mark unresolved required probes as blocking.
- Capture a drift report JSON (probe id, reason, attempted strategy).
- Pause automation per `docs/runtime_trace_loop.md` pause-for-assistance rule.

## First Live Run Checklist (Address-Pack Oriented)

1. Fill address pack from `.cursor/research/manifests/address_pack.template.json`.
2. Populate real `exe.path`, `exe.size_bytes`, `exe.sha256`.
3. Run resolver against active x32dbg MCP server:
   - `python tools/runtime_trace/resolve_address_pack.py --pack <pack.json> --out <resolved.json>`
4. Verify all required probes report `resolved=true`.
5. Apply resolved probe VAs into runtime trace config/hook bootstrap for the session.
6. Execute lifecycle run and validate required probe coverage in `docs/runtime_trace_loop.md`.

## Cross-References

- Run loop and acceptance gate: `docs/runtime_trace_loop.md`
- Crash/call-chain evidence basis: `docs/audio_crash_analysis.md`
- ASI trace scaffold and default probes: `mods/engine_trace_asi/README.md`
- Address pack machine template: `.cursor/research/manifests/address_pack.template.json`
- Resolver utility: `tools/runtime_trace/resolve_address_pack.py`
