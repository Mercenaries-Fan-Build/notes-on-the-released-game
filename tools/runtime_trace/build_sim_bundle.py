from __future__ import annotations

import argparse
import gzip
import json
from collections import Counter
from pathlib import Path
from typing import Any


def _load_json(path: Path, default: Any) -> Any:
    if not path.exists():
        return default
    return json.loads(path.read_text(encoding="utf-8"))


def _write_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def _load_records(path: Path) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []
    with path.open("r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            records.append(json.loads(line))
    return records


def _phase_sequence(records: list[dict[str, Any]]) -> list[str]:
    seen: list[str] = []
    for record in records:
        phase = record.get("lifecycle_phase")
        if phase and (not seen or seen[-1] != phase):
            seen.append(phase)
    return seen


def _compress_copy(src: Path, dst: Path) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    with src.open("rb") as fsrc, gzip.open(dst, "wb", compresslevel=9) as fdst:
        fdst.write(fsrc.read())


def _first_divergence(base_records: list[dict[str, Any]], patch_records: list[dict[str, Any]]) -> dict[str, Any]:
    max_len = min(len(base_records), len(patch_records))
    for i in range(max_len):
        b = base_records[i]
        p = patch_records[i]
        b_key = (b.get("lifecycle_phase"), b.get("probe_id"), b.get("event_name"))
        p_key = (p.get("lifecycle_phase"), p.get("probe_id"), p.get("event_name"))
        if b_key != p_key:
            return {
                "index": i,
                "base": {"phase": b_key[0], "probe_id": b_key[1], "event_name": b_key[2]},
                "patch": {"phase": p_key[0], "probe_id": p_key[1], "event_name": p_key[2]},
            }
    if len(base_records) != len(patch_records):
        return {
            "index": max_len,
            "base_remaining": len(base_records) - max_len,
            "patch_remaining": len(patch_records) - max_len,
        }
    return {}


def build_bundle(
    base_dataset_dir: Path,
    patch_dataset_dir: Path,
    records_file: str,
    lifecycle_profiles_path: Path,
    output_dir: Path,
) -> dict[str, Any]:
    base_records_path = base_dataset_dir / records_file
    patch_records_path = patch_dataset_dir / records_file
    base_records = _load_records(base_records_path)
    patch_records = _load_records(patch_records_path)

    base_probe_counts = Counter(r.get("probe_id", "") for r in base_records)
    patch_probe_counts = Counter(r.get("probe_id", "") for r in patch_records)

    output_dir.mkdir(parents=True, exist_ok=True)
    traces_dir = output_dir / "traces"
    _compress_copy(base_records_path, traces_dir / "base.ndjson.gz")
    _compress_copy(patch_records_path, traces_dir / "patch.ndjson.gz")

    lifecycle_profiles = _load_json(lifecycle_profiles_path, {})
    sim_input = {
        "simulator_input_version": 1,
        "trace_schema_version": 1,
        "lifecycle_profiles": lifecycle_profiles.get("profiles", {}),
        "base_trace": "traces/base.ndjson.gz",
        "patch_trace": "traces/patch.ndjson.gz",
        "base_phase_sequence": _phase_sequence(base_records),
        "patch_phase_sequence": _phase_sequence(patch_records),
    }
    _write_json(output_dir / "simulator_input.json", sim_input)

    summary = {
        "base_record_count": len(base_records),
        "patch_record_count": len(patch_records),
        "base_probe_counts": dict(sorted(base_probe_counts.items())),
        "patch_probe_counts": dict(sorted(patch_probe_counts.items())),
        "first_divergence": _first_divergence(base_records, patch_records),
    }
    _write_json(output_dir / "comparison_summary.json", summary)

    manifest = {
        "bundle_version": 1,
        "base_dataset_dir": str(base_dataset_dir),
        "patch_dataset_dir": str(patch_dataset_dir),
        "records_file": records_file,
        "artifacts": {
            "simulator_input": "simulator_input.json",
            "comparison_summary": "comparison_summary.json",
            "base_trace_gz": "traces/base.ndjson.gz",
            "patch_trace_gz": "traces/patch.ndjson.gz",
        },
    }
    _write_json(output_dir / "bundle_manifest.json", manifest)
    return summary


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Build replay/comparison bundle for Rust simulator input.")
    parser.add_argument("--base-dataset-dir", required=True, type=Path, help="Base dataset directory.")
    parser.add_argument("--patch-dataset-dir", required=True, type=Path, help="Patch dataset directory.")
    parser.add_argument(
        "--records-file",
        default="normalized_trace.ndjson",
        help="Record file name under each dataset directory.",
    )
    parser.add_argument(
        "--lifecycle-profiles",
        type=Path,
        default=Path(".cursor/research/manifests/lifecycle_profiles.json"),
        help="Lifecycle profile JSON path.",
    )
    parser.add_argument("--output-dir", required=True, type=Path, help="Bundle output directory.")
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    summary = build_bundle(
        base_dataset_dir=args.base_dataset_dir.resolve(),
        patch_dataset_dir=args.patch_dataset_dir.resolve(),
        records_file=args.records_file,
        lifecycle_profiles_path=args.lifecycle_profiles.resolve(),
        output_dir=args.output_dir.resolve(),
    )
    print(json.dumps(summary, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
