# Runtime Trace Loop (v0 -> v1)

This runbook defines the practical capture/reuse loop for Mercenaries 2 runtime investigation on a Windows host with a 100 GB local artifact budget.

## Goal

- Capture full runtime evidence for base and patch lifecycles once.
- Reuse captures through normalized, deduplicated, schema-versioned artifacts.
- Focus first on call-chain evidence up to `PalSoundEngine::MixSources`.

## Scope

- Tracing mod: `mods/engine_trace_asi/`
- Research contract and schemas: `.cursor/research/`
- Host-side tooling: `tools/runtime_trace/`
- Base profile: `expected_base_full_lifecycle_v1`
- Patch profile: `expected_patch_full_lifecycle_v1`

## End-to-End Loop

1. Prepare profile and probe config in `mods/engine_trace_asi/config/trace_profile.example.json`.
2. Build and install ASI module (see `mods/engine_trace_asi/README.md`).
3. Initialize orchestrated run manifests and artifact store directories:
   - `python tools/runtime_trace/orchestrate_capture.py init ...`
4. Capture raw NDJSON trace files by playing the game lifecycle manually.
5. Record high-level phase transitions from host side:
   - `python tools/runtime_trace/orchestrate_capture.py phase ...`
6. Run one integrated processing pipeline command:
   - `python tools/runtime_trace/orchestrate_capture.py pipeline ...`
7. Review acceptance criteria and either:
   - mark lifecycle capture complete, or
   - use `ACTION_REQUIRED` markers to continue from the blocked phase.

## Lifecycle Phases

The capture profile must tag each record with a `lifecycle_phase` from this set.

- `boot`
- `main_menu`
- `save_load`
- `world_stream_start`
- `mission_active`
- `audio_stream_runtime`
- `mission_teardown`
- `shutdown`

Profile-specific expected phase lists are stored in `.cursor/research/manifests/lifecycle_profiles.json`.

## Acceptance Criteria

Capture is accepted only when all items pass.

1. Lifecycle profile match:
   - all required phases for selected profile observed
   - phase order is monotonic
2. Probe coverage:
   - call-chain probes include at least:
     - mixer thread loop (`0x831EE0` family)
     - `PalSoundEngine::MixSources` entry (`0x836610`)
     - `PalSoundEngine::MixSources` crash-adjacent callsite window (`0x83664C`..`0x836651`)
3. Artifact health:
   - schema validation passes after migrations
   - dedup index generated
   - content-addressed chunks resolve
4. Storage policy:
   - cumulative compressed artifacts remain under budget (100 GB)
   - raw memory window limits respected

## Storage and Reuse Strategy

- Content-addressed chunking:
  - memory blobs are split into fixed chunks (default 64 KiB)
  - each chunk keyed by BLAKE2 hash
  - duplicate chunks are stored once
- Pointer-first capture:
  - emit pointer/address metadata for all probes
  - include raw memory bytes only when configured windows match
- Window caps:
  - per-probe max bytes (default 4 KiB)
  - per-event max memory windows (default 8)
  - hard truncation marks via `truncated=true`
- Compression:
  - zlib for chunk payloads
  - NDJSON can be gzipped for long-term retention

## Pause-for-Assistance Rule

Automation must stop and ask for manual assistance when any of these occur:

- symbol/probe resolution fails for required call-chain nodes
- anti-cheat/launcher/update state blocks deterministic startup
- repeated crashes happen before `boot` and no stable trace header is emitted
- migration validation reports non-recoverable schema drift
- local storage budget would exceed 100 GB after current run

When paused, report:

- current phase reached
- last successful probe
- failing step with exact error
- smallest manual action needed to continue

`tools/runtime_trace/orchestrate_capture.py` writes `ACTION_REQUIRED.txt` and
`ACTION_REQUIRED.json` in the run directory whenever:

- raw capture file is missing for the requested pipeline step
- schema validation fails after migration
- operator explicitly requests a pause via `action-required`

## Orchestrator Commands (PowerShell)

The orchestration command supports three modes:

- `base` -> profile `expected_base_full_lifecycle_v1`
- `patch` -> profile `expected_patch_full_lifecycle_v1`
- `both` -> initialize/process both in one session id

### First base plus patch capture session

```powershell
python tools/runtime_trace/orchestrate_capture.py init `
  --store-root output/runtime_trace_store `
  --mode both `
  --session-id 20260527_lifecycle_capture_a
```

Expected raw trace paths after `init`:

- `output/runtime_trace_store/sessions/20260527_lifecycle_capture_a/base/raw/runtime_trace.ndjson`
- `output/runtime_trace_store/sessions/20260527_lifecycle_capture_a/patch/raw/runtime_trace.ndjson`

### Record phase transitions during manual gameplay

```powershell
python tools/runtime_trace/orchestrate_capture.py phase `
  --store-root output/runtime_trace_store `
  --session-id 20260527_lifecycle_capture_a `
  --target base `
  --phase boot `
  --note "game reached splash and hooks loaded"
```

Repeat for phases:

- `boot`
- `menu`
- `loadscreen`
- `world`
- `mission-fail`
- `quit`

Run the same sequence for `--target patch` after patch-mode capture.

### Run integrated normalize/migrate/validate/bundle pipeline

```powershell
python tools/runtime_trace/orchestrate_capture.py pipeline `
  --store-root output/runtime_trace_store `
  --session-id 20260527_lifecycle_capture_a `
  --mode both
```

For independent runs:

```powershell
python tools/runtime_trace/orchestrate_capture.py pipeline `
  --store-root output/runtime_trace_store `
  --session-id 20260527_lifecycle_capture_a `
  --mode base

python tools/runtime_trace/orchestrate_capture.py pipeline `
  --store-root output/runtime_trace_store `
  --session-id 20260527_lifecycle_capture_a `
  --mode patch
```

This avoids blocked-output shell pipelines; each command emits a full JSON report directly.

### Manual pause marker when operator help is required

```powershell
python tools/runtime_trace/orchestrate_capture.py action-required `
  --store-root output/runtime_trace_store `
  --session-id 20260527_lifecycle_capture_a `
  --target base `
  --title launcher_prompt_blocked `
  --phase boot `
  --note "Launcher update dialog prevents deterministic startup" `
  --next-action "Dismiss dialog and rerun from boot phase"
```

### Retention and pruning helper (100 GB budget)

```powershell
python tools/runtime_trace/prune_artifact_store.py `
  --store-root output/runtime_trace_store `
  --budget-gb 100 `
  --keep-newest-complete-sessions 1
```

Dry-run preview:

```powershell
python tools/runtime_trace/prune_artifact_store.py `
  --store-root output/runtime_trace_store `
  --budget-gb 100 `
  --keep-newest-complete-sessions 1 `
  --dry-run
```

## Minimal First Session Checklist

- Confirm profile:
  - base run: `expected_base_full_lifecycle_v1`
  - patch run: `expected_patch_full_lifecycle_v1`
- Enable required probes only (call-chain first).
- Capture one base session and one patch session.
- Run normalize/migrate/validate/bundle tools.
- Confirm simulator bundle contains both traces and lifecycle metadata.

## Related Documents

- `docs/audio_crash_analysis.md`
- `docs/external_tools_review.md`
- `mods/engine_trace_asi/README.md`
- `.cursor/research/README.md`
- `.cursor/research/x32dbg_probe_resolution_v1.md`
- `.cursor/research/manifests/address_pack.template.json`
- `tools/runtime_trace/resolve_address_pack.py`
