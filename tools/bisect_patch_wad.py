#!/usr/bin/env python3
"""Generate patch-WAD bisect test matrix and optional trim outputs.

Does not run the game — prints deploy-ready ``trim_patch_wad.py`` commands and a
test matrix for spatial-hash crash isolation.

Usage:
  .venv/Scripts/python.exe tools/bisect_patch_wad.py \\
      --wad output/data/vz-patch.wad

  .venv/Scripts/python.exe tools/bisect_patch_wad.py \\
      --wad output/data/vz-patch.wad --emit-trims output/data/bisect
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

THIS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(THIS_DIR))

from ffcs_patch_wad import read_patch_wad  # noqa: E402
from placement_scan_lib import (  # noqa: E402
    format_ranked_report,
    rank_block_results,
    scan_decompressed_block,
)
from sges_decompress import decompress_sges_block  # noqa: E402

RULED_OUT = "0,4,12,15,16,17"
BOOTSTRAP_IDX = 2196


def _decompress(compressed: bytes) -> bytes:
    if compressed[:4] == b"sges":
        return decompress_sges_block(compressed, 0, len(compressed))
    return compressed


def _trim_cmd(
    wad: Path,
    out: Path,
    *,
    exclude_indices: str | None = None,
    keep_only: str | None = None,
    exclude_path: str | None = None,
) -> str:
    py = ".venv\\Scripts\\python.exe tools\\trim_patch_wad.py"
    parts = [py, f"-i {wad}", f"-o {out}", "-v"]
    if exclude_indices:
        parts.append(f'--exclude-indices "{exclude_indices}"')
    if keep_only:
        parts.append(f"--keep-only-indices {keep_only}")
    if exclude_path:
        parts.append(f"--exclude-path-substr {exclude_path}")
    return " `\n  ".join(parts)


def main() -> int:
    ap = argparse.ArgumentParser(description="Patch WAD bisect test matrix")
    ap.add_argument("--wad", type=Path, required=True)
    ap.add_argument("--out-dir", type=Path, default=None, help="If set, write trim WADs here")
    ap.add_argument("--scan-top", type=int, default=5, help="Top N scan suspects for exclude test")
    args = ap.parse_args()

    if not args.wad.is_file():
        print(f"ERROR: missing {args.wad}", file=sys.stderr)
        return 2

    pw = read_patch_wad(args.wad)
    n = len(pw.blocks)
    results = []
    for idx, blk in enumerate(pw.blocks):
        try:
            decomp = _decompress(blk.compressed_data)
            results.append(scan_decompressed_block(decomp, idx, blk.path_string))
        except Exception:
            pass

    ranked = rank_block_results([r for r in results if r.violation_count > 0])
    not_ruled = [r for r in ranked if r.block_index not in {0, 4, 12, 15, 16, 17}]
    top5 = not_ruled[: args.scan_top]
    top5_idx = ",".join(str(r.block_index) for r in top5) if top5 else "3,8,2,5,13"

    print("=" * 72)
    print("PATCH WAD BISECT TEST MATRIX (spatial hash @ 0x248BB60)")
    print("=" * 72)
    print(f"WAD: {args.wad}  blocks={n}")
    print(f"Carry forward ruled-out: {RULED_OUT}")
    print()
    print(format_ranked_report(results, top_n=10))
    print()

    wad = args.wad
    od = args.out_dir or wad.parent

    tests = [
        ("0", "No patch (rename away vz-patch.wad)", None, "PASS = patch-only"),
        ("4a", "No bootstrap @ 2196", f"{RULED_OUT},{BOOTSTRAP_IDX}", None),
        ("4e", "No dlc01_base + commonlocations (3,5)", f"{RULED_OUT},3,5", None),
        ("4e2", "No top scan suspects", f"{RULED_OUT},{top5_idx}", None),
        ("4b", "Lower half 1-1099", RULED_OUT, "1-1099"),
        ("4c", "Upper half 1100-2195", RULED_OUT, "1100-2195"),
        ("4d", "Drop all c3 cells", RULED_OUT, None),
        ("assets", "dlc-port-assets-only build", None, None),
    ]

    print("--- Test matrix ---")
    print(f"{'ID':<6} {'Hypothesis':<40} {'Expect if PASS'}")
    for tid, title, excl, keep in tests:
        if tid == "0":
            print(f"{tid:<6} {title:<40} crash gone")
            continue
        if tid == "assets":
            print(f"{tid:<6} {title:<40} bootstrap/hook fault")
            continue
        print(f"{tid:<6} {title:<40} culprit outside this cut")

    print("\n--- Commands (PowerShell) ---")
    print(f'$RULED = "{RULED_OUT}"')
    print(f"# Block count: {n}; bootstrap index {BOOTSTRAP_IDX} if full port")
    print()

    scenarios = [
        ("step2-retest", f"{RULED_OUT}", None, None),
        ("no-bootstrap", f"{RULED_OUT},{BOOTSTRAP_IDX}", None, None),
        ("no-base", f"{RULED_OUT},3,5", None, None),
        ("no-top5-scan", f"{RULED_OUT},{top5_idx}", None, None),
        ("lo-half", RULED_OUT, "1-1099", None),
        ("hi-half", RULED_OUT, "1100-2195", None),
        ("no-c3", RULED_OUT, None, r"blocks\dlc01\c3"),
    ]

    for name, excl, keep, path_ex in scenarios:
        out = od / f"vz-patch-{name}.wad"
        print(f"# --- {name} ---")
        print(
            _trim_cmd(
                wad,
                out,
                exclude_indices=excl if not keep else f"{excl},{BOOTSTRAP_IDX}",
                keep_only=keep,
                exclude_path=path_ex,
            )
        )
        print(f"# Deploy: copy {out} -> game data\\vz-patch.wad\n")

    print("# assets-only (re-port, not trim):")
    print("make dlc-port-assets-only DLC_RAR=... SOURCE_WAD=game-files/pc-game-vz.wad OUTPUT=./output")
    print("# Deploy output/data/vz-patch-assets-only.wad as vz-patch.wad\n")

    print("# ASI isolation (same WAD, edit build_dlc_asi / rebuild):")
    print("#   CRASH_PATCH=0 REG_PATCH=0 GUARD=0 — rule out hook side effects")
    print()

    if top5:
        print("--- Top scan suspects (for 4e2 / single-block) ---")
        for r in top5:
            print(f"  [{r.block_index:4d}] {r.violation_count:4d}  {r.path}")

    if args.out_dir:
        args.out_dir.mkdir(parents=True, exist_ok=True)
        from ffcs_patch_wad import build_patch_wad_multi  # noqa: E402

        excl_set = {int(x) for x in RULED_OUT.split(",")}
        for r in top5:
            excl_set.add(r.block_index)
        kept = [b for i, b in enumerate(pw.blocks) if i not in excl_set]
        if kept:
            out = args.out_dir / "vz-patch-no-top5-scan.wad"
            blob = build_patch_wad_multi(blocks=kept, csum_value=pw.csum_value)
            out.write_bytes(blob)
            print(f"Emitted {out} ({len(kept)} blocks)")

    return 0


if __name__ == "__main__":
    sys.exit(main())
