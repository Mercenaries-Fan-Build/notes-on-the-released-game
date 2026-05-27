# Runtime Trace Host Tooling

These scripts process runtime traces emitted by `mods/engine_trace_asi/`.

## Scripts

- `artifact_store.py`
  - normalize NDJSON records
  - chunk/compress/deduplicate memory windows
- `migrate_and_validate.py`
  - apply idempotent schema migrations
  - validate normalized records
- `build_sim_bundle.py`
  - assemble base/patch replay bundle for Rust simulator input

## Quick Start

1. Normalize and dedup:

`python tools/runtime_trace/artifact_store.py --input raw_trace.ndjson --output normalized_trace.ndjson --store-root output/runtime_trace_store`

2. Apply migrations and validate:

`python tools/runtime_trace/migrate_and_validate.py --dataset-dir output/runtime_trace_session --records-file normalized_trace.ndjson`

3. Build simulator bundle:

`python tools/runtime_trace/build_sim_bundle.py --base-dataset-dir output/runtime_trace_base --patch-dataset-dir output/runtime_trace_patch --output-dir output/runtime_trace_bundle`
