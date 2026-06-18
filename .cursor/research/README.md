# Runtime Trace Research Scaffold

This directory stores reproducible runtime trace contracts, schemas, and migration metadata for Mercenaries 2 runtime investigation.

## Layout

- `manifests/`
  - capture manifests and lifecycle profile declarations
- `schemas/`
  - canonical JSON Schema files for trace records
- `migrations/`
  - migration manifest format + migration steps

## Core Files

- `manifests/lifecycle_profiles.json`
  - expected phase sets for base/patch lifecycle runs
- `manifests/runtime_capture_manifest.example.json`
  - example run manifest used by host scripts
- `manifests/address_pack.template.json`
  - machine template for versioned probe/address packs resolved against debugger module base
- `schemas/runtime_trace_record.schema.json`
  - schema for event/snapshot records
- `migrations/migration_manifest.schema.json`
  - schema for migration descriptors
- `migrations/manifest.json`
  - ordered migration list used by tooling
- `migrations/000_v0_to_v1_noop.json`
  - idempotent no-op migration (bootstrap)
- `x32dbg_probe_resolution_v1.md`
  - first live-run policy for executable fingerprinting, RVA/VA handling, probe catalog, and drift fallback

## Reproducibility Rules

- Migrations are append-only; do not rewrite historical migration files.
- Migration IDs must be globally unique.
- Migrations must be idempotent:
  - running migration tooling multiple times must not mutate data after first successful application.
- Schema version increments must be explicit in migration metadata.

## Local Artifact Strategy

- Designed for Windows local workflows.
- Target budget: 100 GB compressed artifacts.
- Storage reuse depends on content-hash dedup in `tools/runtime_trace/artifact_store.py`.
- End-to-end orchestration lives in `tools/runtime_trace/orchestrate_capture.py`.
- Retention pruning lives in `tools/runtime_trace/prune_artifact_store.py`.
