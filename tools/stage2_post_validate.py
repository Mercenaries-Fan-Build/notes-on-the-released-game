#!/usr/bin/env python3
"""Post-stage-2 validation: Rust UCFX structural checks + optional glTF regression.

Runs after ``make review-all`` (or standalone) to catch chunk/CSUM/DEPS/SKIN issues
that Python extractors may not surface. Does not re-extract geometry.

Env / Makefile:
  STAGE2_VALIDATE_RUST=1     enable Rust validate on blobs (via stage2 scripts)
  STAGE2_VALIDATE_GLTF=1     run gltf_validate.py on dirs with mesh_scene.gltf
  STAGE2_VALIDATE_SAMPLE=N   validate at most N blobs (0 = all; default 0)
"""
from __future__ import annotations

import argparse
import json
import random
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path

_REPO = Path(__file__).resolve().parent.parent
if str(_REPO / "tools") not in sys.path:
    sys.path.insert(0, str(_REPO / "tools"))

from ucfx_byteswap_wrapper import rust_binary_available, validate_block_file_rust  # noqa: E402


@dataclass
class BlockResult:
    blob: str
    ok: bool
    warnings: list[str] = field(default_factory=list)
    error: str | None = None


@dataclass
class GltfResult:
    review_dir: str
    ok: bool
    errors: list[str] = field(default_factory=list)


def _find_block_bins(pipeline_root: Path) -> list[Path]:
    bins: list[Path] = []
    for root in (pipeline_root / "extracted", pipeline_root):
        if not root.is_dir():
            continue
        for blocks_dir in sorted(root.glob("batch_*/blocks")):
            if blocks_dir.is_dir():
                bins.extend(sorted(blocks_dir.glob("*.bin")))
    return bins


def _review_root(pipeline_root: Path) -> Path:
    ext = pipeline_root / "extracted" / "review"
    return ext if ext.is_dir() else pipeline_root / "review"


def _sample(items: list[Path], limit: int, seed: int) -> list[Path]:
    if limit <= 0 or limit >= len(items):
        return items
    rng = random.Random(seed)
    return sorted(rng.sample(items, limit))


def _validate_one_blob(path: Path, strict: bool) -> BlockResult:
    rel = str(path)
    try:
        warnings = validate_block_file_rust(path, strict=strict)
        return BlockResult(blob=rel, ok=len(warnings) == 0, warnings=warnings)
    except Exception as exc:  # noqa: BLE001 — aggregate per-blob failures
        return BlockResult(blob=rel, ok=False, error=str(exc))


def _validate_gltf_dir(review_dir: Path, python: str) -> GltfResult:
    gltf = review_dir / "mesh_scene.gltf"
    if not gltf.is_file():
        return GltfResult(review_dir=str(review_dir), ok=True)
    script = _REPO / "tools" / "gltf_validate.py"
    proc = subprocess.run(
        [python, str(script), "--review-dir", str(review_dir)],
        capture_output=True,
        text=True,
    )
    errs = [ln for ln in (proc.stdout + proc.stderr).splitlines() if ln.strip()]
    return GltfResult(review_dir=str(review_dir), ok=proc.returncode == 0, errors=errs)


def run_rust_validate(
    blobs: list[Path],
    *,
    jobs: int,
    strict: bool,
) -> list[BlockResult]:
    if not rust_binary_available():
        raise FileNotFoundError(
            "ucfx_byteswap not built — run: make build-ucfx-byteswap"
        )
    results: list[BlockResult] = []
    workers = max(1, jobs)
    if workers == 1:
        for p in blobs:
            results.append(_validate_one_blob(p, strict))
        return results

    with ThreadPoolExecutor(max_workers=workers) as pool:
        futures = {pool.submit(_validate_one_blob, p, strict): p for p in blobs}
        for fut in as_completed(futures):
            results.append(fut.result())
    return results


def main() -> int:
    ap = argparse.ArgumentParser(description="Post-stage-2 UCFX / glTF validation")
    ap.add_argument(
        "pipeline_root",
        type=Path,
        nargs="?",
        default=Path("output"),
        help="Pipeline root (contains extracted/batch_*/blocks)",
    )
    ap.add_argument("--rust", action="store_true", help="Run ucfx_byteswap --validate-only on blobs")
    ap.add_argument("--gltf", action="store_true", help="Run gltf_validate.py on review dirs with mesh_scene.gltf")
    ap.add_argument(
        "--sample",
        type=int,
        default=0,
        help="Max blobs to validate with --rust (0 = all)",
    )
    ap.add_argument("--jobs", type=int, default=8, help="Parallel workers for --rust")
    ap.add_argument("--strict", action="store_true", help="Fail on first Rust validation error")
    ap.add_argument("--seed", type=int, default=42, help="RNG seed when --sample is set")
    ap.add_argument("--out", type=Path, default=None, help="Write JSON report (default: review/stage2_validate_<ts>.json)")
    args = ap.parse_args()

    if not args.rust and not args.gltf:
        args.rust = True

    pipeline_root = args.pipeline_root.resolve()
    review = _review_root(pipeline_root)
    report: dict[str, object] = {
        "pipeline_root": str(pipeline_root),
        "review_root": str(review),
        "generated_at": datetime.now(timezone.utc).isoformat(),
    }
    exit_code = 0

    if args.rust:
        all_bins = _find_block_bins(pipeline_root)
        bins = _sample(all_bins, args.sample, args.seed)
        report["rust"] = {
            "total_blobs": len(all_bins),
            "validated": len(bins),
            "sample_limit": args.sample,
        }
        print(f"Rust validate: {len(bins)} / {len(all_bins)} blobs (jobs={args.jobs})")
        block_results = run_rust_validate(bins, jobs=args.jobs, strict=args.strict)
        bad = [r for r in block_results if not r.ok]
        report["rust"]["ok"] = len(block_results) - len(bad)
        report["rust"]["fail"] = len(bad)
        report["rust"]["failures"] = [
            {"blob": r.blob, "warnings": r.warnings, "error": r.error}
            for r in bad[:200]
        ]
        if bad:
            exit_code = 1
            print(f"  FAIL: {len(bad)} blob(s) with validation issues (see report)")
        else:
            print("  OK: all validated blobs passed")

    if args.gltf:
        python = sys.executable
        gltf_dirs = sorted(
            p.parent
            for p in review.rglob("mesh_scene.gltf")
            if p.is_file()
        )
        if args.sample > 0 and len(gltf_dirs) > args.sample:
            rng = random.Random(args.seed)
            gltf_dirs = sorted(rng.sample(gltf_dirs, args.sample))
        print(f"glTF validate: {len(gltf_dirs)} review dir(s)")
        gltf_results: list[GltfResult] = []
        for rd in gltf_dirs:
            gltf_results.append(_validate_gltf_dir(rd, python))
        bad_g = [r for r in gltf_results if not r.ok]
        report["gltf"] = {
            "validated": len(gltf_dirs),
            "ok": len(gltf_results) - len(bad_g),
            "fail": len(bad_g),
            "failures": [{"review_dir": r.review_dir, "errors": r.errors} for r in bad_g[:100]],
        }
        if bad_g:
            exit_code = 1
            print(f"  FAIL: {len(bad_g)} glTF mismatch(es)")
        else:
            print("  OK: glTF matches submesh OBJ counts")

    out_path = args.out
    if out_path is None:
        out_path = review / f"stage2_validate_{datetime.now().strftime('%Y%m%d-%H%M%S')}.json"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(f"Report → {out_path}")
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
