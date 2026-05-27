from __future__ import annotations

import argparse
import json
import re
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

from tools.runtime_trace.artifact_store import normalize_trace
from tools.runtime_trace.build_sim_bundle import build_bundle
from tools.runtime_trace.migrate_and_validate import apply_migrations, validate_records


PHASE_SEQUENCE = ("boot", "menu", "loadscreen", "world", "mission-fail", "quit")
PROFILE_BY_MODE = {
    "base": ("base", "expected_base_full_lifecycle_v1"),
    "patch": ("patch", "expected_patch_full_lifecycle_v1"),
}
ALL_MODES = ("base", "patch", "both")
DEFAULT_SCHEMA_PATH = Path(".cursor/research/schemas/runtime_trace_record.schema.json")
DEFAULT_MIGRATIONS_DIR = Path(".cursor/research/migrations")
DEFAULT_MIGRATION_MANIFEST = Path(".cursor/research/migrations/manifest.json")
DEFAULT_LIFECYCLE_PROFILES = Path(".cursor/research/manifests/lifecycle_profiles.json")
MANIFEST_NAME = "run_manifest.json"


def _utc_now() -> datetime:
    return datetime.now(UTC)


def _utc_timestamp_compact() -> str:
    return _utc_now().strftime("%Y%m%dT%H%M%SZ")


def _utc_timestamp_iso() -> str:
    return _utc_now().isoformat()


def _slug(value: str) -> str:
    cleaned = re.sub(r"[^A-Za-z0-9._-]+", "-", value.strip())
    return cleaned.strip("-") or "session"


def _read_json(path: Path, default: Any) -> Any:
    if not path.exists():
        return default
    return json.loads(path.read_text(encoding="utf-8"))


def _write_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def _write_action_required(run_dir: Path, title: str, details: dict[str, Any]) -> Path:
    marker = {
        "status": "ACTION_REQUIRED",
        "title": title,
        "created_at": _utc_timestamp_iso(),
        "details": details,
    }
    marker_path = run_dir / "ACTION_REQUIRED.json"
    _write_json(marker_path, marker)
    text_path = run_dir / "ACTION_REQUIRED.txt"
    text_lines = [
        "ACTION_REQUIRED",
        f"title: {title}",
        f"created_at: {marker['created_at']}",
        f"details_file: {marker_path.name}",
    ]
    text_path.write_text("\n".join(text_lines) + "\n", encoding="utf-8")
    return marker_path


def _clear_action_required(run_dir: Path) -> None:
    for name in ("ACTION_REQUIRED.txt", "ACTION_REQUIRED.json"):
        path = run_dir / name
        if path.exists():
            path.unlink()


def _session_root(store_root: Path, session_id: str) -> Path:
    return store_root / "sessions" / session_id


def _run_root(store_root: Path, session_id: str, target: str) -> Path:
    return _session_root(store_root, session_id) / target


def _run_manifest_path(store_root: Path, session_id: str, target: str) -> Path:
    return _run_root(store_root, session_id, target) / MANIFEST_NAME


def _bundle_root(store_root: Path, session_id: str) -> Path:
    return store_root / "bundles" / session_id


def _create_run_manifest(
    store_root: Path,
    session_id: str,
    target: str,
    profile_name: str,
    run_suffix: str,
    notes: str,
) -> dict[str, Any]:
    run_dir = _run_root(store_root, session_id, target)
    run_dir.mkdir(parents=True, exist_ok=True)
    for rel in ("raw", "normalized", "reports", "markers", "logs"):
        (run_dir / rel).mkdir(parents=True, exist_ok=True)

    run_id = f"{session_id}_{target}_{run_suffix}"
    manifest = {
        "manifest_version": 1,
        "session_id": session_id,
        "run_id": run_id,
        "target": target,
        "capture_profile": profile_name,
        "status": "initialized",
        "created_at": _utc_timestamp_iso(),
        "updated_at": _utc_timestamp_iso(),
        "notes": notes,
        "phase_transitions_file": "reports/phase_transitions.ndjson",
        "raw_trace": "raw/runtime_trace.ndjson",
        "normalized_trace": "normalized/normalized_trace.ndjson",
        "pipeline_report": "reports/pipeline_report.json",
        "validation_report": "reports/validation_report.json",
    }
    _write_json(run_dir / MANIFEST_NAME, manifest)
    return manifest


def _load_manifest(store_root: Path, session_id: str, target: str) -> tuple[Path, dict[str, Any]]:
    path = _run_manifest_path(store_root, session_id, target)
    if not path.exists():
        raise FileNotFoundError(
            f"run manifest not found for target={target}. Run init first: {path}"
        )
    return path, _read_json(path, {})


def _save_manifest(path: Path, manifest: dict[str, Any]) -> None:
    manifest["updated_at"] = _utc_timestamp_iso()
    _write_json(path, manifest)


def _iter_targets(mode: str) -> list[tuple[str, str]]:
    if mode == "both":
        return [PROFILE_BY_MODE["base"], PROFILE_BY_MODE["patch"]]
    return [PROFILE_BY_MODE[mode]]


def _record_phase_transition(
    store_root: Path,
    session_id: str,
    target: str,
    phase: str,
    note: str,
) -> dict[str, Any]:
    if phase not in PHASE_SEQUENCE:
        raise ValueError(f"unsupported phase '{phase}'. supported: {', '.join(PHASE_SEQUENCE)}")

    manifest_path, manifest = _load_manifest(store_root, session_id, target)
    run_dir = manifest_path.parent
    phase_file = run_dir / manifest["phase_transitions_file"]
    transitions: list[dict[str, Any]] = []
    if phase_file.exists():
        with phase_file.open("r", encoding="utf-8") as src:
            for line in src:
                line = line.strip()
                if line:
                    transitions.append(json.loads(line))

    transition = {
        "run_id": manifest["run_id"],
        "session_id": session_id,
        "target": target,
        "phase": phase,
        "phase_index": PHASE_SEQUENCE.index(phase),
        "timestamp": _utc_timestamp_iso(),
        "note": note,
    }
    transitions.append(transition)
    phase_file.parent.mkdir(parents=True, exist_ok=True)
    with phase_file.open("w", encoding="utf-8") as dst:
        for entry in transitions:
            dst.write(json.dumps(entry, sort_keys=True) + "\n")

    manifest["status"] = "capturing"
    manifest["phase"] = {
        "current": phase,
        "last_transition_at": transition["timestamp"],
        "history_count": len(transitions),
    }
    _save_manifest(manifest_path, manifest)
    return transition


def _run_pipeline_for_target(
    store_root: Path,
    session_id: str,
    target: str,
    *,
    schema_file: Path,
    migrations_dir: Path,
    migration_manifest: Path,
    chunk_size: int,
    max_window_bytes: int,
    max_windows_per_record: int,
    records_file: str,
) -> dict[str, Any]:
    manifest_path, manifest = _load_manifest(store_root, session_id, target)
    run_dir = manifest_path.parent

    raw_trace = run_dir / manifest["raw_trace"]
    normalized_trace = run_dir / manifest["normalized_trace"]
    validation_report = run_dir / manifest["validation_report"]
    pipeline_report = run_dir / manifest["pipeline_report"]

    if not raw_trace.exists():
        marker_path = _write_action_required(
            run_dir,
            "raw_trace_missing",
            {
                "target": target,
                "expected_raw_trace": str(raw_trace),
                "next_action": "Capture runtime trace and place it at expected_raw_trace.",
            },
        )
        manifest["status"] = "action_required"
        manifest["last_error"] = f"missing raw trace: {raw_trace}"
        _save_manifest(manifest_path, manifest)
        raise RuntimeError(f"raw trace missing for target={target}; marker written: {marker_path}")

    normalize_report = normalize_trace(
        input_file=raw_trace,
        output_file=normalized_trace,
        store_root=store_root,
        chunk_size=chunk_size,
        max_window_bytes=max_window_bytes,
        max_windows_per_record=max_windows_per_record,
    )

    migration_result = apply_migrations(
        dataset_dir=run_dir / "normalized",
        migrations_dir=migrations_dir,
        migration_manifest_path=migration_manifest,
    )
    validation_result = validate_records(
        schema_path=schema_file,
        records_path=normalized_trace,
        expected_schema_version=int(migration_result["schema_version"]),
    )

    validation_payload = {
        "migration": migration_result,
        "validation": validation_result,
    }
    _write_json(validation_report, validation_payload)

    pipeline_payload = {
        "session_id": session_id,
        "target": target,
        "run_id": manifest["run_id"],
        "normalize": normalize_report,
        "validation_report": str(validation_report.relative_to(run_dir)).replace("\\", "/"),
    }
    _write_json(pipeline_report, pipeline_payload)

    if validation_result["error_count"] > 0:
        marker_path = _write_action_required(
            run_dir,
            "validation_failed",
            {
                "target": target,
                "error_count": validation_result["error_count"],
                "report_file": str(validation_report),
                "next_action": "Resolve validation errors, then rerun pipeline.",
            },
        )
        manifest["status"] = "action_required"
        manifest["last_error"] = f"validation failed ({validation_result['error_count']} errors)"
        _save_manifest(manifest_path, manifest)
        raise RuntimeError(
            f"validation failed for target={target}; marker written: {marker_path}"
        )

    _clear_action_required(run_dir)
    manifest["status"] = "complete"
    manifest["completed_at"] = _utc_timestamp_iso()
    manifest["artifacts"] = {
        "raw_trace": manifest["raw_trace"],
        "normalized_trace": manifest["normalized_trace"],
        "pipeline_report": manifest["pipeline_report"],
        "validation_report": manifest["validation_report"],
    }
    _save_manifest(manifest_path, manifest)
    return {
        "target": target,
        "run_id": manifest["run_id"],
        "normalize": normalize_report,
        "validation_errors": validation_result["error_count"],
    }


def _maybe_build_bundle(
    store_root: Path,
    session_id: str,
    *,
    lifecycle_profiles: Path,
    records_file: str,
) -> dict[str, Any] | None:
    _, base_manifest = _load_manifest(store_root, session_id, "base")
    _, patch_manifest = _load_manifest(store_root, session_id, "patch")
    if base_manifest.get("status") != "complete" or patch_manifest.get("status") != "complete":
        return None

    base_dir = _run_root(store_root, session_id, "base") / "normalized"
    patch_dir = _run_root(store_root, session_id, "patch") / "normalized"
    bundle_dir = _bundle_root(store_root, session_id)
    summary = build_bundle(
        base_dataset_dir=base_dir,
        patch_dataset_dir=patch_dir,
        records_file=records_file,
        lifecycle_profiles_path=lifecycle_profiles,
        output_dir=bundle_dir,
    )
    manifest = {
        "bundle_version": 1,
        "session_id": session_id,
        "created_at": _utc_timestamp_iso(),
        "base_run_id": base_manifest["run_id"],
        "patch_run_id": patch_manifest["run_id"],
        "summary_file": "comparison_summary.json",
        "simulator_input_file": "simulator_input.json",
    }
    _write_json(bundle_dir / "orchestration_bundle_manifest.json", manifest)
    return {"bundle_dir": str(bundle_dir), "summary": summary}


def _ensure_store_layout(store_root: Path) -> None:
    for rel in ("chunks", "index", "sessions", "bundles"):
        (store_root / rel).mkdir(parents=True, exist_ok=True)


def command_init(args: argparse.Namespace) -> int:
    mode = args.mode
    session_id = _slug(args.session_id or f"capture_{_utc_timestamp_compact()}")
    _ensure_store_layout(args.store_root)

    created: list[dict[str, Any]] = []
    for target, profile_name in _iter_targets(mode):
        manifest = _create_run_manifest(
            store_root=args.store_root,
            session_id=session_id,
            target=target,
            profile_name=profile_name,
            run_suffix=args.run_suffix,
            notes=args.notes,
        )
        created.append(
            {
                "target": target,
                "run_id": manifest["run_id"],
                "manifest": str(_run_manifest_path(args.store_root, session_id, target)),
                "raw_trace_expected": str(
                    _run_root(args.store_root, session_id, target) / manifest["raw_trace"]
                ),
            }
        )

    output = {"mode": mode, "session_id": session_id, "created": created}
    print(json.dumps(output, indent=2, sort_keys=True))
    return 0


def command_phase(args: argparse.Namespace) -> int:
    transition = _record_phase_transition(
        store_root=args.store_root,
        session_id=args.session_id,
        target=args.target,
        phase=args.phase,
        note=args.note,
    )
    print(json.dumps(transition, indent=2, sort_keys=True))
    return 0


def command_action_required(args: argparse.Namespace) -> int:
    manifest_path, manifest = _load_manifest(args.store_root, args.session_id, args.target)
    marker = _write_action_required(
        manifest_path.parent,
        args.title,
        {
            "target": args.target,
            "phase": args.phase,
            "note": args.note,
            "next_action": args.next_action,
        },
    )
    manifest["status"] = "action_required"
    manifest["last_error"] = args.title
    _save_manifest(manifest_path, manifest)
    payload = {"target": args.target, "marker": str(marker)}
    print(json.dumps(payload, indent=2, sort_keys=True))
    return 0


def command_pipeline(args: argparse.Namespace) -> int:
    mode = args.mode
    targets = _iter_targets(mode)
    results: list[dict[str, Any]] = []
    for target, _ in targets:
        results.append(
            _run_pipeline_for_target(
                store_root=args.store_root,
                session_id=args.session_id,
                target=target,
                schema_file=args.schema_file,
                migrations_dir=args.migrations_dir,
                migration_manifest=args.migration_manifest,
                chunk_size=args.chunk_size,
                max_window_bytes=args.max_window_bytes,
                max_windows_per_record=args.max_windows_per_record,
                records_file=args.records_file,
            )
        )

    bundle_result = None
    if mode == "both":
        bundle_result = _maybe_build_bundle(
            store_root=args.store_root,
            session_id=args.session_id,
            lifecycle_profiles=args.lifecycle_profiles,
            records_file=args.records_file,
        )

    output = {
        "mode": mode,
        "session_id": args.session_id,
        "results": results,
        "bundle": bundle_result,
    }
    print(json.dumps(output, indent=2, sort_keys=True))
    return 0


def command_status(args: argparse.Namespace) -> int:
    out: dict[str, Any] = {"session_id": args.session_id, "runs": []}
    for target, _ in _iter_targets(args.mode):
        manifest_path, manifest = _load_manifest(args.store_root, args.session_id, target)
        run_dir = manifest_path.parent
        out["runs"].append(
            {
                "target": target,
                "status": manifest.get("status"),
                "run_id": manifest.get("run_id"),
                "current_phase": manifest.get("phase", {}).get("current"),
                "action_required": (run_dir / "ACTION_REQUIRED.json").exists(),
                "manifest": str(manifest_path),
            }
        )
    print(json.dumps(out, indent=2, sort_keys=True))
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Orchestrate reusable runtime trace capture for base/patch lifecycle profiles."
    )
    parser.add_argument(
        "--store-root",
        type=Path,
        default=Path("output/runtime_trace_store"),
        help="Artifact store root directory.",
    )

    subparsers = parser.add_subparsers(dest="command", required=True)

    init_parser = subparsers.add_parser("init", help="Create run ids/manifests and initialize directories.")
    init_parser.add_argument("--mode", choices=ALL_MODES, required=True)
    init_parser.add_argument("--session-id", default="", help="Optional stable session id.")
    init_parser.add_argument("--run-suffix", default="run01", help="Run id suffix.")
    init_parser.add_argument("--notes", default="", help="Freeform notes for run manifests.")
    init_parser.set_defaults(func=command_init)

    phase_parser = subparsers.add_parser("phase", help="Record lifecycle phase transition.")
    phase_parser.add_argument("--session-id", required=True)
    phase_parser.add_argument("--target", choices=("base", "patch"), required=True)
    phase_parser.add_argument("--phase", choices=PHASE_SEQUENCE, required=True)
    phase_parser.add_argument("--note", default="", help="Optional phase note.")
    phase_parser.set_defaults(func=command_phase)

    action_parser = subparsers.add_parser(
        "action-required", help="Write explicit ACTION_REQUIRED marker for manual help."
    )
    action_parser.add_argument("--session-id", required=True)
    action_parser.add_argument("--target", choices=("base", "patch"), required=True)
    action_parser.add_argument("--title", required=True)
    action_parser.add_argument("--phase", default="")
    action_parser.add_argument("--note", default="")
    action_parser.add_argument("--next-action", default="")
    action_parser.set_defaults(func=command_action_required)

    pipeline_parser = subparsers.add_parser(
        "pipeline",
        help="Normalize + migrate/validate + optional bundle build in one command.",
    )
    pipeline_parser.add_argument("--session-id", required=True)
    pipeline_parser.add_argument("--mode", choices=ALL_MODES, required=True)
    pipeline_parser.add_argument("--records-file", default="normalized_trace.ndjson")
    pipeline_parser.add_argument("--chunk-size", type=int, default=64 * 1024)
    pipeline_parser.add_argument("--max-window-bytes", type=int, default=4096)
    pipeline_parser.add_argument("--max-windows-per-record", type=int, default=8)
    pipeline_parser.add_argument("--schema-file", type=Path, default=DEFAULT_SCHEMA_PATH)
    pipeline_parser.add_argument("--migrations-dir", type=Path, default=DEFAULT_MIGRATIONS_DIR)
    pipeline_parser.add_argument(
        "--migration-manifest", type=Path, default=DEFAULT_MIGRATION_MANIFEST
    )
    pipeline_parser.add_argument(
        "--lifecycle-profiles", type=Path, default=DEFAULT_LIFECYCLE_PROFILES
    )
    pipeline_parser.set_defaults(func=command_pipeline)

    status_parser = subparsers.add_parser("status", help="Print run status for one or both targets.")
    status_parser.add_argument("--session-id", required=True)
    status_parser.add_argument("--mode", choices=ALL_MODES, default="both")
    status_parser.set_defaults(func=command_status)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    args.store_root = args.store_root.resolve()

    for attr in ("schema_file", "migrations_dir", "migration_manifest", "lifecycle_profiles"):
        if hasattr(args, attr):
            value = getattr(args, attr)
            if isinstance(value, Path):
                setattr(args, attr, value.resolve())

    return int(args.func(args))


if __name__ == "__main__":
    raise SystemExit(main())
