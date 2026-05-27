from __future__ import annotations

import argparse
import base64
import hashlib
import json
import zlib
from pathlib import Path
from typing import Any


def _load_json(path: Path, default: Any) -> Any:
    if not path.exists():
        return default
    return json.loads(path.read_text(encoding="utf-8"))


def _write_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def _canonical_hash(data: bytes) -> str:
    return hashlib.blake2b(data, digest_size=32).hexdigest()


def _chunk_path(store_root: Path, digest: str) -> Path:
    return store_root / "chunks" / digest[0:2] / digest[2:4] / f"{digest}.zlib"


def _decode_window_bytes(window: dict[str, Any]) -> bytes:
    if "bytes_b64" in window:
        return base64.b64decode(window["bytes_b64"])
    if "bytes_hex" in window:
        return bytes.fromhex(window["bytes_hex"])
    return b""


def _store_chunk(store_root: Path, index: dict[str, Any], chunk_data: bytes) -> dict[str, Any]:
    digest = _canonical_hash(chunk_data)
    chunk_file = _chunk_path(store_root, digest)
    if digest not in index:
        compressed = zlib.compress(chunk_data, level=9)
        chunk_file.parent.mkdir(parents=True, exist_ok=True)
        if not chunk_file.exists():
            chunk_file.write_bytes(compressed)
        index[digest] = {
            "hash": digest,
            "size": len(chunk_data),
            "compressed_size": len(compressed),
            "path": str(chunk_file.relative_to(store_root)).replace("\\", "/"),
            "compression": "zlib",
        }
    return {
        "hash": digest,
        "size": len(chunk_data),
        "compression": "zlib",
    }


def _split_chunks(data: bytes, chunk_size: int) -> list[bytes]:
    if not data:
        return []
    return [data[i : i + chunk_size] for i in range(0, len(data), chunk_size)]


def normalize_trace(
    input_file: Path,
    output_file: Path,
    store_root: Path,
    chunk_size: int,
    max_window_bytes: int,
    max_windows_per_record: int,
) -> dict[str, int]:
    index_file = store_root / "index" / "chunk_index.json"
    index_data = _load_json(index_file, {"index_version": 1, "chunks": {}})
    chunk_index: dict[str, Any] = index_data["chunks"]

    output_file.parent.mkdir(parents=True, exist_ok=True)
    records_in = 0
    records_out = 0
    windows_seen = 0
    windows_stored = 0
    dedup_hits = 0

    with input_file.open("r", encoding="utf-8") as src, output_file.open("w", encoding="utf-8") as dst:
        for line in src:
            line = line.strip()
            if not line:
                continue
            records_in += 1
            record = json.loads(line)
            windows = record.get("memory_windows", [])
            if windows:
                normalized_windows = []
                for idx, window in enumerate(windows):
                    if idx >= max_windows_per_record:
                        break
                    windows_seen += 1
                    window_bytes = _decode_window_bytes(window)
                    truncated = False
                    if len(window_bytes) > max_window_bytes:
                        window_bytes = window_bytes[:max_window_bytes]
                        truncated = True

                    refs = []
                    for chunk in _split_chunks(window_bytes, chunk_size):
                        before = len(chunk_index)
                        ref = _store_chunk(store_root, chunk_index, chunk)
                        after = len(chunk_index)
                        if before == after:
                            dedup_hits += 1
                        refs.append(ref)
                    windows_stored += 1
                    normalized_windows.append(
                        {
                            "address": window.get("address", "0x0"),
                            "size": len(window_bytes),
                            "truncated": truncated or bool(window.get("truncated", False)),
                            "chunk_refs": refs,
                        }
                    )
                record["memory_windows"] = normalized_windows
                for w in record["memory_windows"]:
                    w.pop("bytes_b64", None)
                    w.pop("bytes_hex", None)

            record["metadata"] = dict(record.get("metadata", {}))
            record["metadata"]["normalized"] = True
            record_hash = _canonical_hash(json.dumps(record, sort_keys=True, separators=(",", ":")).encode("utf-8"))
            record["metadata"]["record_hash"] = record_hash
            dst.write(json.dumps(record, sort_keys=True) + "\n")
            records_out += 1

    index_data["chunks"] = chunk_index
    _write_json(index_file, index_data)

    report = {
        "records_in": records_in,
        "records_out": records_out,
        "windows_seen": windows_seen,
        "windows_stored": windows_stored,
        "unique_chunks": len(chunk_index),
        "dedup_hits": dedup_hits,
    }
    _write_json(output_file.with_suffix(".report.json"), report)
    return report


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Normalize and deduplicate runtime trace artifacts.")
    parser.add_argument("--input", required=True, type=Path, help="Raw NDJSON trace input.")
    parser.add_argument("--output", required=True, type=Path, help="Normalized NDJSON output.")
    parser.add_argument("--store-root", required=True, type=Path, help="Content-addressed artifact store root.")
    parser.add_argument("--chunk-size", type=int, default=64 * 1024, help="Chunk size in bytes (default: 64 KiB).")
    parser.add_argument("--max-window-bytes", type=int, default=4096, help="Max bytes captured per memory window.")
    parser.add_argument("--max-windows-per-record", type=int, default=8, help="Max memory windows retained per record.")
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    report = normalize_trace(
        input_file=args.input,
        output_file=args.output,
        store_root=args.store_root,
        chunk_size=args.chunk_size,
        max_window_bytes=args.max_window_bytes,
        max_windows_per_record=args.max_windows_per_record,
    )
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
