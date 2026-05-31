#!/usr/bin/env python3
"""Offline scan of vz-patch.wad for ECS placement float violations.

Ranks blocks by Transform/flgs violation count (NaN/Inf, |coord|>5000,
BE-looking patterns, optional world envelope). No full wad_simulator required.

Usage:
  .venv/Scripts/python.exe tools/scan_patch_placements.py \\
      --wad output/data/vz-patch.wad

  .venv/Scripts/python.exe tools/scan_patch_placements.py \\
      --wad output/data/vz-patch.wad --top 10 --json report.json

  .venv/Scripts/python.exe tools/scan_patch_placements.py \\
      --wad output/data/vz-patch.wad --indices 3,8,2 --no-world-envelope
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

THIS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(THIS_DIR))

from ffcs_patch_wad import read_patch_wad  # noqa: E402
from placement_scan_lib import (  # noqa: E402
    BlockScanResult,
    format_ranked_report,
    rank_block_results,
    scan_decompressed_block,
)
from sges_decompress import decompress_sges_block  # noqa: E402

# Bisect carry-forward from user steps 1–2 (re-verify with trim --list).
DEFAULT_RULED_OUT = {0, 4, 12, 15, 16, 17}
HIGH_PRIORITY_PATH_MARKERS = (
    "dlc01_base",
    "dlc01_commonlocations",
    "speedcity",
    "dlccon",
    "dlc01_state",
)


def _decompress_block(compressed: bytes) -> bytes:
    if compressed[:4] == b"sges":
        return decompress_sges_block(compressed, 0, len(compressed))
    return compressed


def _parse_indices(spec: str | None) -> set[int] | None:
    if not spec:
        return None
    out: set[int] = set()
    for part in spec.split(","):
        part = part.strip()
        if not part:
            continue
        if "-" in part:
            a, b = part.split("-", 1)
            out.update(range(int(a), int(b) + 1))
        else:
            out.add(int(part))
    return out


def _result_to_dict(r: BlockScanResult) -> dict:
    return {
        "block_index": r.block_index,
        "path": r.path,
        "violation_count": r.violation_count,
        "transform_records": r.transform_records,
        "flgs_records": r.flgs_records,
        "layer_entries": r.layer_entries,
        "samples": [h.summary() for h in r.hits[:10]],
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Scan patch WAD placement floats")
    ap.add_argument("--wad", type=Path, required=True, help="vz-patch.wad path")
    ap.add_argument("--top", type=int, default=20, help="Show top N violating blocks")
    ap.add_argument("--indices", type=str, default=None, help="Only scan these block indices")
    ap.add_argument(
        "--no-world-envelope",
        action="store_true",
        help="Skip Y/Z world bounds (still flag NaN/Inf, |v|>5000, BE-looking)",
    )
    ap.add_argument("--json", type=Path, default=None, help="Write full JSON report")
    ap.add_argument(
        "--fail-on-violations",
        action="store_true",
        help="Exit 1 if any violation (for CI / dlc-port gate)",
    )
    ap.add_argument(
        "--exclude-ruled-out",
        action="store_true",
        help="Skip indices 0,4,12,15,16,17 in ranking header note",
    )
    args = ap.parse_args()

    if not args.wad.is_file():
        print(f"ERROR: WAD not found: {args.wad}", file=sys.stderr)
        return 2

    only = _parse_indices(args.indices)
    pw = read_patch_wad(args.wad)
    results: list[BlockScanResult] = []

    for idx, blk in enumerate(pw.blocks):
        if only is not None and idx not in only:
            continue
        try:
            decomp = _decompress_block(blk.compressed_data)
        except Exception as exc:
            print(f"WARN block[{idx}] decompress failed: {exc}", file=sys.stderr)
            continue
        results.append(
            scan_decompressed_block(
                decomp,
                idx,
                blk.path_string,
                check_world_envelope=not args.no_world_envelope,
            )
        )

    print(format_ranked_report(results, top_n=args.top))
    ranked = rank_block_results([r for r in results if r.violation_count > 0])

    # Cross-check bisect suspects
    print("\n--- Bisect cross-check ---")
    for idx, path in [
        (3, "dlc01_base"),
        (8, "speedcity"),
        (2, "dlccon004"),
        (5, "commonlocations"),
        (2196, "scripts_vz"),
    ]:
        if idx < len(pw.blocks):
            r = next((x for x in results if x.block_index == idx), None)
            if r:
                print(
                    f"  [{idx}] viol={r.violation_count} xfm={r.transform_records} "
                    f"path={pw.blocks[idx].path_string}"
                )
            else:
                print(f"  [{idx}] (not scanned) {pw.blocks[idx].path_string}")

    not_ruled = [r for r in ranked if r.block_index not in DEFAULT_RULED_OUT]
    if not_ruled:
        print("\n--- Top suspects (excluding ruled-out 0,4,12,15,16,17) ---")
        for r in not_ruled[:5]:
            markers = [m for m in HIGH_PRIORITY_PATH_MARKERS if m in r.path.lower()]
            print(
                f"  [{r.block_index}] {r.violation_count} hits "
                f"markers={markers or '-'}  {r.path}"
            )

    if args.json:
        payload = {
            "wad": str(args.wad),
            "blocks_scanned": len(results),
            "total_violations": sum(r.violation_count for r in results),
            "ranked": [_result_to_dict(r) for r in ranked],
            "all_blocks": [_result_to_dict(r) for r in results],
        }
        args.json.write_text(json.dumps(payload, indent=2), encoding="utf-8")
        print(f"\nWrote {args.json}")

    # Trim commands for next 15 minutes
    if ranked:
        top5 = not_ruled[:5] if not_ruled else ranked[:5]
        idxs = ",".join(str(r.block_index) for r in top5)
        substr = ",".join(
            dict.fromkeys(
                m
                for r in top5
                for m in HIGH_PRIORITY_PATH_MARKERS
                if m in r.path.lower()
            )
        ) or "dlc01_base,speedcity,dlccon"
        ruled = "0,4,12,15,16,17"
        print("\n--- Trim commands (copy/paste) ---")
        print(f"$RULED = \"{ruled}\"")
        print(
            f".venv\\Scripts\\python.exe tools\\trim_patch_wad.py "
            f"-i {args.wad} -o output/data/vz-patch-no-top5.wad "
            f'--exclude-indices "{ruled},{idxs}" -v'
        )
        print(
            f".venv\\Scripts\\python.exe tools\\trim_patch_wad.py "
            f"-i {args.wad} -o output/data/vz-patch-no-arena.wad "
            f"--exclude-path-substr {substr} --exclude-indices $RULED -v"
        )

    total_viol = sum(r.violation_count for r in results)
    if args.fail_on_violations and total_viol > 0:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
