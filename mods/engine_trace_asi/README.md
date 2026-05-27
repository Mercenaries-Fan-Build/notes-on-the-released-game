# engine_trace_asi

Runtime tracing ASI module for Mercenaries 2 focused on first-pass audio call-chain capture.

## What Is Implemented

- Concrete hook backend: x86 breakpoint hook backend (`INT3` + vectored exception handler).
- Hook manager abstraction (`src/hook_manager.*`) with deterministic backend install result.
- Probe registration path with canonical probe-id mapping for:
  - `mixsources_entry` -> `audio.palsoundengine.mixsources.entry`
  - `mixsources_exit` -> `audio.palsoundengine.mixsources.exit`
  - `audio_object_free` -> `audio.palsoundengine.audio_object_free`
- Configurable addresses via local profile file and environment overrides.
- Deterministic diagnostics emitted to `trace_raw.ndjson` using `record_type="diagnostic"` when install fails.

## Current Backend Constraints

- Target process: Windows x86 game process.
- Build target: x86 (`_M_IX86`) strongly recommended.
- On non-x86 builds, backend install fails explicitly with a diagnostic error.
- No proprietary binaries are shipped in-repo.

## Hooking Mode

- Backend installs per-probe `INT3` breakpoint at configured address.
- On breakpoint:
  - emits `probe_entry`
  - restores original byte
  - single-steps instruction
  - re-arms breakpoint
  - emits `probe_exit`
- This is a minimal first-capture backend, not a full trampoline/detour implementation.

## Configuration

Default config path (next to `engine_trace.asi`):

- `trace_profile.ini`

Override path via env var:

- `ENGINE_TRACE_PROFILE_PATH=C:\path\to\trace_profile.ini`

See `config/trace_profile.example.ini` for exact keys.

Supported per-probe fields:

- `probe.<probe_id>.address=0x...` (absolute VA)
- `probe.<probe_id>.rva=0x...` (RVA from main module base)
- `probe.<probe_id>.snapshot=true|false`

Per-probe environment overrides (optional):

- `ENGINE_TRACE_MIXSOURCES_ENTRY_RVA` / `ENGINE_TRACE_MIXSOURCES_ENTRY_VA`
- `ENGINE_TRACE_MIXSOURCES_EXIT_RVA` / `ENGINE_TRACE_MIXSOURCES_EXIT_VA`
- `ENGINE_TRACE_AUDIO_OBJECT_FREE_RVA` / `ENGINE_TRACE_AUDIO_OBJECT_FREE_VA`

## Diagnostics And Failure Behavior

When hook install fails, runtime writes explicit diagnostic records with details such as:

- game module resolution failure
- bad RVA (outside module image)
- `VirtualQuery` / page protection failures
- vectored handler or TLS setup failures
- no hooks installed after config resolution

There is no silent success path: backend install returns success only after at least one hook arms.

## Output Contract

- Raw output: `trace_raw.ndjson` next to the ASI module.
- Runtime event schema target:
  - `.cursor/research/schemas/runtime_trace_record.schema.json`

Host-side processing tools:

- `tools/runtime_trace/artifact_store.py`
- `tools/runtime_trace/migrate_and_validate.py`
- `tools/runtime_trace/build_sim_bundle.py`
- `tools/runtime_trace/resolve_address_pack.py`

Address/probe planning references:

- `.cursor/research/x32dbg_probe_resolution_v1.md`
- `.cursor/research/manifests/address_pack.template.json`

## Build Example

MSVC (x86 developer prompt):

`cl /LD /std:c++17 /EHsc /Iinclude src\\engine_trace_asi.cpp src\\probe_runtime.cpp src\\hook_manager.cpp /Fe:engine_trace.asi`

Adjust include/lib paths to your local toolchain and loader setup.
