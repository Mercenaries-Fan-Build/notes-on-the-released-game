from __future__ import annotations

import argparse
import json
import shutil
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Any


ONE_GIB = 1024 * 1024 * 1024


def _read_json(path: Path, default: Any) -> Any:
    if not path.exists():
        return default
    return json.loads(path.read_text(encoding="utf-8"))


def _write_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def _dir_size(path: Path) -> int:
    total = 0
    if not path.exists():
        return 0
    for child in path.rglob("*"):
        if child.is_file():
            total += child.stat().st_size
    return total


def _store_size(store_root: Path) -> int:
    return _dir_size(store_root)


def _parse_completed_at(manifest: dict[str, Any]) -> str:
    return str(manifest.get("completed_at", manifest.get("updated_at", "")))


@dataclass(frozen=True)
class RunInfo:
    session_id: str
    target: str
    run_dir: Path
    manifest_path: Path
    manifest: dict[str, Any]

    @property
    def is_complete(self) -> bool:
        return self.manifest.get("status") == "complete"

    @property
    def completed_sort_key(self) -> str:
        return _parse_completed_at(self.manifest)


def _discover_runs(store_root: Path) -> list[RunInfo]:
    runs: list[RunInfo] = []
    sessions_root = store_root / "sessions"
    if not sessions_root.exists():
        return runs
    for manifest_path in sessions_root.glob("*/*/run_manifest.json"):
        manifest = _read_json(manifest_path, {})
        run_dir = manifest_path.parent
        runs.append(
            RunInfo(
                session_id=str(manifest.get("session_id", manifest_path.parts[-3])),
                target=str(manifest.get("target", manifest_path.parts[-2])),
                run_dir=run_dir,
                manifest_path=manifest_path,
                manifest=manifest,
            )
        )
    return runs


def _normalized_trace_path(run: RunInfo) -> Path | None:
    rel = run.manifest.get("normalized_trace")
    if not rel:
        return None
    path = run.run_dir / str(rel)
    return path if path.exists() else None


def _referenced_chunk_hashes(trace_file: Path) -> set[str]:
    hashes: set[str] = set()
    with trace_file.open("r", encoding="utf-8") as src:
        for line in src:
            line = line.strip()
            if not line:
                continue
            record = json.loads(line)
            for window in record.get("memory_windows", []):
                for chunk_ref in window.get("chunk_refs", []):
                    chunk_hash = chunk_ref.get("hash")
                    if chunk_hash:
                        hashes.add(str(chunk_hash))
    return hashes


def _chunk_file_from_hash(store_root: Path, digest: str) -> Path:
    return store_root / "chunks" / digest[0:2] / digest[2:4] / f"{digest}.zlib"


def _group_runs_by_session(runs: list[RunInfo]) -> dict[str, list[RunInfo]]:
    grouped: dict[str, list[RunInfo]] = defaultdict(list)
    for run in runs:
        grouped[run.session_id].append(run)
    return dict(grouped)


def _is_complete_session(session_runs: list[RunInfo]) -> bool:
    return bool(session_runs) and all(run.is_complete for run in session_runs)


def _session_sort_key(session_runs: list[RunInfo]) -> str:
    return max((run.completed_sort_key for run in session_runs), default="")


def prune_store(
    store_root: Path,
    budget_bytes: int,
    keep_newest_complete_sessions: int,
    dry_run: bool,
) -> dict[str, Any]:
    runs = _discover_runs(store_root)
    sessions = _group_runs_by_session(runs)
    complete_sessions = sorted(
        (
            (session_id, session_runs)
            for session_id, session_runs in sessions.items()
            if _is_complete_session(session_runs)
        ),
        key=lambda item: _session_sort_key(item[1]),
        reverse=True,
    )

    kept_sessions = complete_sessions[:keep_newest_complete_sessions]
    keep_runs = [run for _, session_runs in kept_sessions for run in session_runs]

    deleted_run_dirs: list[str] = []
    deleted_session_ids: list[str] = []
    for session_id, session_runs in complete_sessions[keep_newest_complete_sessions:]:
        deleted_session_ids.append(session_id)
        for run in session_runs:
            deleted_run_dirs.append(str(run.run_dir))
            if not dry_run:
                shutil.rmtree(run.run_dir, ignore_errors=True)
        if not dry_run:
            session_root = store_root / "sessions" / session_id
            if session_root.exists():
                shutil.rmtree(session_root, ignore_errors=True)

    active_hashes: set[str] = set()
    for run in keep_runs:
        trace_file = _normalized_trace_path(run)
        if trace_file is None:
            continue
        active_hashes.update(_referenced_chunk_hashes(trace_file))

    removed_chunks: list[str] = []
    chunks_root = store_root / "chunks"
    if chunks_root.exists():
        for chunk_file in chunks_root.rglob("*.zlib"):
            chunk_hash = chunk_file.stem
            if chunk_hash not in active_hashes:
                removed_chunks.append(str(chunk_file))
                if not dry_run:
                    chunk_file.unlink(missing_ok=True)

    index_file = store_root / "index" / "chunk_index.json"
    index_data = _read_json(index_file, {"index_version": 1, "chunks": {}})
    chunks_index = dict(index_data.get("chunks", {}))
    if chunks_index:
        filtered = {
            digest: meta
            for digest, meta in chunks_index.items()
            if _chunk_file_from_hash(store_root, digest).exists()
        }
        index_data["chunks"] = filtered
        if not dry_run:
            _write_json(index_file, index_data)

    size_after_prune = _store_size(store_root)
    over_budget = size_after_prune > budget_bytes

    report = {
        "store_root": str(store_root),
        "dry_run": dry_run,
        "budget_bytes": budget_bytes,
        "budget_gib": round(budget_bytes / ONE_GIB, 2),
        "size_after_prune_bytes": size_after_prune,
        "size_after_prune_gib": round(size_after_prune / ONE_GIB, 2),
        "over_budget": over_budget,
        "kept_complete_sessions": [session_id for session_id, _ in kept_sessions],
        "kept_complete_runs": [str(run.run_dir) for run in keep_runs],
        "deleted_complete_sessions": deleted_session_ids,
        "deleted_complete_run_dirs": deleted_run_dirs,
        "removed_chunk_files": len(removed_chunks),
    }
    return report


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Prune runtime trace artifact store to stay within budget.")
    parser.add_argument(
        "--store-root",
        type=Path,
        default=Path("output/runtime_trace_store"),
        help="Artifact store root path.",
    )
    parser.add_argument(
        "--budget-gb",
        type=float,
        default=100.0,
        help="Store budget in GiB-equivalent units (default: 100).",
    )
    parser.add_argument(
        "--keep-newest-complete-sessions",
        type=int,
        default=1,
        help="Number of newest complete sessions to retain.",
    )
    parser.add_argument("--dry-run", action="store_true", help="Report planned deletes without changing files.")
    parser.add_argument("--report-out", type=Path, default=None, help="Optional JSON report path.")
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    store_root = args.store_root.resolve()
    budget_bytes = int(args.budget_gb * ONE_GIB)
    report = prune_store(
        store_root=store_root,
        budget_bytes=budget_bytes,
        keep_newest_complete_sessions=max(args.keep_newest_complete_sessions, 0),
        dry_run=bool(args.dry_run),
    )
    if args.report_out:
        _write_json(args.report_out.resolve(), report)
    print(json.dumps(report, indent=2, sort_keys=True))
    return 1 if report["over_budget"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
