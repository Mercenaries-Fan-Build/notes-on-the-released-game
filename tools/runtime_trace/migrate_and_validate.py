from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


REQUIRED_PHASES = {
    "boot",
    "main_menu",
    "save_load",
    "world_stream_start",
    "mission_active",
    "audio_stream_runtime",
    "mission_teardown",
    "shutdown",
}

REQUIRED_KEYS = {
    "schema_version",
    "record_type",
    "run_id",
    "timestamp_us",
    "lifecycle_phase",
    "probe_id",
}


def _load_json(path: Path, default: Any) -> Any:
    if not path.exists():
        return default
    return json.loads(path.read_text(encoding="utf-8"))


def _write_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def _find_next_migration(current_version: int, manifest: dict[str, Any]) -> dict[str, Any] | None:
    for migration in manifest.get("migrations", []):
        if migration["from_version"] == current_version:
            return migration
    return None


def apply_migrations(dataset_dir: Path, migrations_dir: Path, migration_manifest_path: Path) -> dict[str, Any]:
    meta_path = dataset_dir / "dataset_meta.json"
    meta = _load_json(
        meta_path,
        {
            "schema_version": 0,
            "applied_migrations": [],
        },
    )

    manifest = _load_json(migration_manifest_path, {"migrations": []})
    applied = set(meta.get("applied_migrations", []))
    current_version = int(meta.get("schema_version", 0))
    applied_now: list[str] = []

    while True:
        migration = _find_next_migration(current_version, manifest)
        if not migration:
            break
        migration_id = migration["id"]
        migration_file = migrations_dir / migration["file"]
        migration_body = _load_json(migration_file, {})

        if migration_id in applied:
            current_version = int(migration["to_version"])
            continue

        kind = migration_body.get("kind", migration.get("kind"))
        if kind == "noop":
            pass
        elif kind == "python_transform":
            raise RuntimeError(
                f"python_transform migration not implemented in v0 tooling: {migration_id}"
            )
        else:
            raise RuntimeError(f"Unsupported migration kind: {kind}")

        applied.add(migration_id)
        applied_now.append(migration_id)
        current_version = int(migration["to_version"])

    meta["schema_version"] = current_version
    meta["applied_migrations"] = sorted(applied)
    _write_json(meta_path, meta)
    return {"schema_version": current_version, "applied_now": applied_now}


def validate_records(schema_path: Path, records_path: Path, expected_schema_version: int) -> dict[str, Any]:
    # v0 lightweight validation uses deterministic key/type checks.
    # The full JSON Schema is still kept as source-of-truth for future validators.
    _ = _load_json(schema_path, {})
    errors: list[str] = []
    total = 0

    with records_path.open("r", encoding="utf-8") as f:
        for line_no, line in enumerate(f, start=1):
            line = line.strip()
            if not line:
                continue
            total += 1
            try:
                record = json.loads(line)
            except json.JSONDecodeError as exc:
                errors.append(f"line {line_no}: invalid JSON ({exc})")
                continue

            missing = REQUIRED_KEYS.difference(record.keys())
            if missing:
                errors.append(f"line {line_no}: missing keys: {sorted(missing)}")
                continue

            if int(record.get("schema_version", -1)) != expected_schema_version:
                errors.append(
                    f"line {line_no}: schema_version={record.get('schema_version')} expected={expected_schema_version}"
                )

            if record.get("record_type") not in {"event", "snapshot"}:
                errors.append(f"line {line_no}: unsupported record_type={record.get('record_type')}")

            phase = record.get("lifecycle_phase")
            if phase not in REQUIRED_PHASES:
                errors.append(f"line {line_no}: invalid lifecycle_phase={phase}")

            if record.get("record_type") == "event" and "event_name" not in record:
                errors.append(f"line {line_no}: event record missing event_name")
            if record.get("record_type") == "snapshot" and "memory_windows" not in record:
                errors.append(f"line {line_no}: snapshot record missing memory_windows")

    return {"records_checked": total, "error_count": len(errors), "errors": errors}


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Apply idempotent migrations and validate runtime trace records.")
    parser.add_argument("--dataset-dir", required=True, type=Path, help="Dataset directory with records and metadata.")
    parser.add_argument(
        "--records-file",
        default="normalized_trace.ndjson",
        help="Record file name under dataset-dir (default: normalized_trace.ndjson).",
    )
    parser.add_argument(
        "--schema-file",
        type=Path,
        default=Path(".cursor/research/schemas/runtime_trace_record.schema.json"),
        help="Path to schema file.",
    )
    parser.add_argument(
        "--migrations-dir",
        type=Path,
        default=Path(".cursor/research/migrations"),
        help="Migration directory.",
    )
    parser.add_argument(
        "--migration-manifest",
        type=Path,
        default=Path(".cursor/research/migrations/manifest.json"),
        help="Migration manifest JSON file.",
    )
    parser.add_argument("--report-out", type=Path, default=None, help="Optional report JSON output path.")
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    dataset_dir = args.dataset_dir.resolve()
    records_path = dataset_dir / args.records_file
    if not records_path.exists():
        raise SystemExit(f"records file does not exist: {records_path}")

    migration_result = apply_migrations(
        dataset_dir=dataset_dir,
        migrations_dir=args.migrations_dir.resolve(),
        migration_manifest_path=args.migration_manifest.resolve(),
    )

    validation_result = validate_records(
        schema_path=args.schema_file.resolve(),
        records_path=records_path,
        expected_schema_version=int(migration_result["schema_version"]),
    )

    final_report = {
        "migration": migration_result,
        "validation": validation_result,
    }
    if args.report_out:
        _write_json(args.report_out.resolve(), final_report)

    print(json.dumps(final_report, indent=2, sort_keys=True))
    return 1 if validation_result["error_count"] > 0 else 0


if __name__ == "__main__":
    raise SystemExit(main())
