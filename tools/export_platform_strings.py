#!/usr/bin/env python3
"""Export unique strings + block lists from SCFF (big-endian) console WADs.

Both game-files/xbox-vz.wad and game-files/ps3-VZ.WAD are SCFF big-endian FFCS
archives (verified: SCFF magic, v2, 7 chunks, INDX first). This tool extracts,
per WAD:
  - PTHS block paths (named blocks)
  - ASCII name tokens embedded in every decompressed (segs) block

It classifies tokens against tools/rainbow_table.json (hash already known vs.
genuinely new) and writes per-WAD exports into game-files/:
  <stem>.blocks.txt          index<TAB>path  for every PTHS block
  <stem>.strings.txt         all unique extracted name tokens (sorted)
  <stem>.unique-strings.txt  tokens whose pandemic_hash_m2 is NOT yet in the table

With --merge it also folds quality-filtered new strings into the rainbow table
(reusing tools/harvest_dlc_strings.py's precision filter).

Usage:
  python tools/export_platform_strings.py                 # both WADs, no table merge
  python tools/export_platform_strings.py --merge         # also extend the rainbow table
  python tools/export_platform_strings.py --wad game-files/xbox-vz.wad
"""
from __future__ import annotations

import argparse
import json
import mmap
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from pandemic_hash import pandemic_hash, pandemic_hash_m2  # noqa: E402
from harvest_dlc_strings import TOKEN_RE, _add_token, is_quality_name  # noqa: E402
from x360_dlc_io import (  # noqa: E402
    PAGE_SIZE, parse_be_ffcs, parse_be_indx, parse_be_pths, decompress_be_sges,
)

DEFAULT_WADS = [Path("game-files/xbox-vz.wad"), Path("game-files/ps3-VZ.WAD")]
OUT_DIR = Path("game-files")
MAX_BLOCK_OUT = 64 * 1024 * 1024


def harvest_scff(wad: Path, *, verbose: bool = True) -> tuple[list[str], set[str]]:
    """Return (block_paths, token_set) for a big-endian SCFF WAD."""
    f = open(wad, "rb")
    mm = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)
    try:
        _ver, rows = parse_be_ffcs(mm)
        by_tag = {r.tag: r for r in rows}
        if verbose:
            print(f"  chunks: " + ", ".join(f"{r.tag}@0x{r.offset:X}(n={r.meta})" for r in rows))

        # PTHS block paths
        paths: list[str] = []
        pths = by_tag.get("PTHS")
        if pths:
            paths = parse_be_pths(mm, pths.offset, pths.meta)
        if verbose:
            print(f"  PTHS block paths: {len(paths):,}")

        tokens: set[str] = set()
        for p in paths:
            _add_token(tokens, p)

        # Embedded strings: decompress each INDX block
        indx = by_tag.get("INDX")
        ok = err = 0
        if indx:
            entries = parse_be_indx(mm, indx.offset, indx.meta)
            if verbose:
                print(f"  INDX blocks: {len(entries):,} — decompressing...")
            for i, e in enumerate(entries):
                off = e.page_index * PAGE_SIZE
                try:
                    if mm[off:off + 4] != b"segs":
                        err += 1
                        continue
                    decomp = decompress_be_sges(mm, off, MAX_BLOCK_OUT)
                    for m in TOKEN_RE.finditer(decomp):
                        try:
                            _add_token(tokens, m.group().decode("ascii"))
                        except UnicodeDecodeError:
                            pass
                    ok += 1
                except Exception:
                    err += 1
                if verbose and (i + 1) % 1000 == 0:
                    print(f"    {i + 1}/{len(entries)} blocks  (tokens={len(tokens):,})")
        if verbose:
            print(f"  decompressed ok={ok} err={err}; total tokens: {len(tokens):,}")
        return paths, tokens
    finally:
        mm.close()
        f.close()


def main() -> int:
    ap = argparse.ArgumentParser(description="Export Xbox/PS3 SCFF WAD strings + blocks")
    ap.add_argument("--wad", type=Path, action="append", default=[],
                    help="WAD(s) to export (default: xbox-vz.wad + ps3-VZ.WAD)")
    ap.add_argument("--table", type=Path,
                    default=Path(__file__).resolve().parent / "rainbow_table.json")
    ap.add_argument("--out-dir", type=Path, default=OUT_DIR)
    ap.add_argument("--merge", action="store_true",
                    help="Fold quality-filtered NEW strings into the rainbow table")
    args = ap.parse_args()

    wads = args.wad or DEFAULT_WADS
    tbl = json.loads(args.table.read_text())
    m2 = tbl["pandemic_hash_m2"]
    v1 = tbl.get("pandemic_hash", {})
    existing_m2 = set(m2.keys())

    grand_quality_new: set[str] = set()
    for wad in wads:
        if not wad.is_file():
            print(f"!! WAD not found: {wad}")
            continue
        print(f"\n=== {wad} ===")
        paths, tokens = harvest_scff(wad)

        # Classify against the (original) table
        unique = sorted(s for s in tokens
                        if f"0x{pandemic_hash_m2(s):08X}" not in existing_m2)
        uniq_hashes = {f"0x{pandemic_hash_m2(s):08X}" for s in unique}
        quality_new = {s for s in unique if is_quality_name(s)}
        grand_quality_new |= quality_new

        stem = wad.stem
        blocks_f = args.out_dir / f"{stem}.blocks.txt"
        strings_f = args.out_dir / f"{stem}.strings.txt"
        unique_f = args.out_dir / f"{stem}.unique-strings.txt"
        blocks_f.write_text("\n".join(f"{i}\t{p}" for i, p in enumerate(paths)),
                            encoding="utf-8")
        strings_f.write_text("\n".join(sorted(tokens)), encoding="utf-8")
        unique_f.write_text("\n".join(unique), encoding="utf-8")

        print(f"  tokens={len(tokens):,}  unique-vs-table={len(unique):,} "
              f"(hashes={len(uniq_hashes):,}, quality={len(quality_new):,})")
        print(f"  wrote {blocks_f} ({len(paths):,} blocks)")
        print(f"  wrote {strings_f}")
        print(f"  wrote {unique_f}")

    if args.merge and grand_quality_new:
        print(f"\nMerging {len(grand_quality_new):,} quality NEW console strings into table...")
        added = 0
        for s in grand_quality_new:
            k = f"0x{pandemic_hash_m2(s):08X}"
            cur = set(m2.get(k, []))
            if s not in cur:
                cur.add(s); m2[k] = sorted(cur); added += 1
            vk = f"0x{pandemic_hash(s):08X}"
            curv = set(v1.get(vk, []))
            if s not in curv:
                curv.add(s); v1[vk] = sorted(curv)
        meta = tbl.setdefault("_meta", {})
        meta["unique_m2_hashes"] = len(m2)
        meta["unique_v1_hashes"] = len(v1)
        meta.setdefault("console_harvest", {})
        meta["console_harvest"] = {
            "wads": [str(w) for w in wads if w.is_file()],
            "quality_new_added": added,
        }
        tbl["pandemic_hash_m2"] = m2
        tbl["pandemic_hash"] = v1
        args.table.write_text(json.dumps(tbl, indent=2, sort_keys=False))
        print(f"  m2 entries now {len(m2):,}  ({args.table.stat().st_size/1024/1024:.1f} MB)")
    elif not args.merge:
        print("\n(exports written; re-run with --merge to fold new hashes into the table)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
