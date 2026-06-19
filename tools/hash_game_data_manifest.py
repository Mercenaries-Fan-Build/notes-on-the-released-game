#!/usr/bin/env python3
"""SHA-256 manifest for a Mercenaries 2 game data/ tree (and optional runtime files).

Used to pin reproducible load baselines (retail vz.wad, disabled patch, shaders, etc.).
"""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
from datetime import datetime, timezone
from pathlib import Path


def sha256_file(path: Path, chunk: int = 8 * 1024 * 1024) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        while True:
            block = f.read(chunk)
            if not block:
                break
            h.update(block)
    return h.hexdigest().upper()


def collect_files(root: Path, *, extra_roots: list[Path]) -> list[Path]:
    out: list[Path] = []
    if root.is_dir():
        for p in sorted(root.rglob("*")):
            if p.is_file():
                out.append(p)
    for er in extra_roots:
        if er.is_file():
            out.append(er)
    return out


def main() -> None:
    parser = argparse.ArgumentParser(description="SHA-256 manifest for game data/ and runtime pins")
    parser.add_argument(
        "--game-dir",
        type=Path,
        required=True,
        help="Game install root (contains data/)",
    )
    parser.add_argument(
        "--data-only",
        action="store_true",
        help="Only hash files under data/ (default: data/ plus --extra files)",
    )
    parser.add_argument(
        "--extra",
        type=Path,
        action="append",
        default=[],
        help="Additional files to hash (e.g. Mercenaries2.exe, pmc_bb.dll)",
    )
    parser.add_argument(
        "--label",
        default="",
        help="Baseline label stored in manifest metadata",
    )
    parser.add_argument(
        "--out",
        type=Path,
        required=True,
        help="Output JSON path",
    )
    parser.add_argument(
        "--max-mb",
        type=float,
        default=0,
        help="Skip files larger than this many MB (0 = no skip)",
    )
    args = parser.parse_args()

    game_dir = args.game_dir.resolve()
    data_dir = game_dir / "data"
    if not data_dir.is_dir():
        print(f"error: {data_dir} not found", file=sys.stderr)
        sys.exit(1)

    max_bytes = int(args.max_mb * 1024 * 1024) if args.max_mb > 0 else 0
    extra_roots = [p.resolve() for p in args.extra]

    if args.data_only:
        files = sorted(p for p in data_dir.rglob("*") if p.is_file())
    else:
        files = collect_files(data_dir, extra_roots=extra_roots)

    entries: list[dict] = []
    skipped: list[dict] = []
    for i, path in enumerate(files, 1):
        rel = path.relative_to(game_dir).as_posix()
        size = path.stat().st_size
        if max_bytes and size > max_bytes:
            skipped.append({"path": rel, "size": size, "reason": f">{args.max_mb} MB"})
            print(f"[{i}/{len(files)}] SKIP {rel} ({size:,} bytes)", flush=True)
            continue
        print(f"[{i}/{len(files)}] {rel} ({size:,} bytes)...", flush=True)
        digest = sha256_file(path)
        entries.append({"path": rel, "size": size, "sha256": digest})

    manifest = {
        "generated_utc": datetime.now(timezone.utc).isoformat(),
        "label": args.label or None,
        "game_dir": str(game_dir),
        "file_count": len(entries),
        "skipped_count": len(skipped),
        "files": entries,
    }
    if skipped:
        manifest["skipped"] = skipped

    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {args.out} ({len(entries)} hashed, {len(skipped)} skipped)")


if __name__ == "__main__":
    main()
