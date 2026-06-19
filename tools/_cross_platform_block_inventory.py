#!/usr/bin/env python3
r"""Cross-platform block name inventory for Mercenaries 2 WAD files.

Compares PC, Xbox 360, and PS3 vz.wad block names and compressed sizes
using only FFCS header metadata (PTHS paths + INDX entries) — no extraction.

Usage:
    .venv\Scripts\python.exe tools\_cross_platform_block_inventory.py ^
        --pc-wad game-files\pc-game-vz.wad ^
        --xbox-wad game-files\xbox-vz.wad ^
        --ps3-wad game-files\ps3-VZ.WAD ^
        --output output\analysis\cross_platform_block_inventory.json
"""
from __future__ import annotations

import argparse
import json
import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from cross_platform_vz_compare import parse_ffcs_header, ChunkRow

PAGE_SIZE = 0x8000


# ── Low-level I/O (avoids loading multi-GB WADs into memory) ─────────

def _read_slice(path: Path, offset: int, size: int) -> bytes:
    with path.open("rb") as f:
        f.seek(offset)
        return f.read(size)


def _chunk_byte_size(rows: list[ChunkRow], target_tag: str,
                     file_size: int) -> int:
    """Estimate chunk byte size from the gap to the next chunk offset."""
    spatial = sorted(
        [(r.tag, r.offset) for r in rows
         if r.tag != "CSUM" and 0 < r.offset < file_size],
        key=lambda t: t[1],
    )
    for i, (tag, off) in enumerate(spatial):
        if tag == target_tag:
            nxt = spatial[i + 1][1] if i + 1 < len(spatial) else file_size
            return nxt - off
    return 10_000_000  # generous fallback


def _parse_pths(path: Path, pths_offset: int, count: int,
                max_bytes: int) -> list[str]:
    buf = _read_slice(path, pths_offset, max_bytes)
    paths: list[str] = []
    pos = 0
    for _ in range(count):
        if pos >= len(buf):
            break
        nul = buf.find(b"\x00", pos)
        if nul < 0:
            break
        paths.append(buf[pos:nul].decode("ascii", errors="replace"))
        pos = nul + 1
    return paths


def _parse_indx(path: Path, indx_offset: int, count: int,
                endian: str) -> list[tuple[int, int, int, int]]:
    """Returns list of (page_index, packed, flags, page_count)."""
    buf = _read_slice(path, indx_offset, count * 12)
    fmt = ">III" if endian == "big" else "<III"
    entries: list[tuple[int, int, int, int]] = []
    for i in range(count):
        off = i * 12
        if off + 12 > len(buf):
            break
        page_idx, packed, flags_pages = struct.unpack_from(fmt, buf, off)
        entries.append((
            page_idx, packed,
            (flags_pages >> 16) & 0xFFFF,
            flags_pages & 0xFFFF,
        ))
    return entries


# ── Per-WAD metadata extraction ──────────────────────────────────────

def parse_wad_metadata(wad_path: Path, platform: str) -> dict:
    file_size = wad_path.stat().st_size
    header = _read_slice(wad_path, 0, 256)

    endian, version, chunk_count, rows = parse_ffcs_header(header)

    indx_row = next((r for r in rows if r.tag == "INDX"), None)
    pths_row = next((r for r in rows if r.tag == "PTHS"), None)
    aset_row = next((r for r in rows if r.tag == "ASET"), None)
    if not indx_row or not pths_row:
        raise ValueError(f"{platform}: Missing INDX or PTHS in header")

    block_count = indx_row.meta
    pths_count = pths_row.meta
    aset_count = aset_row.meta if aset_row else 0

    pths_bytes = _chunk_byte_size(rows, "PTHS", file_size)
    paths = _parse_pths(wad_path, pths_row.offset, pths_count, pths_bytes)
    indx  = _parse_indx(wad_path, indx_row.offset, block_count, endian)

    return {
        "platform": platform,
        "path": str(wad_path),
        "file_size": file_size,
        "endian": endian,
        "version": version,
        "block_count": block_count,
        "pths_count": len(paths),
        "aset_count": aset_count,
        "paths": paths,
        "indx": indx,
    }


# ── Normalization ────────────────────────────────────────────────────

def _norm(p: str) -> str:
    return p.lower().replace("\\", "/")


# ── Main ─────────────────────────────────────────────────────────────

def main() -> int:
    ap = argparse.ArgumentParser(
        description="Cross-platform block name inventory for Mercenaries 2 WADs")
    ap.add_argument("--pc-wad",   type=Path, required=True)
    ap.add_argument("--xbox-wad", type=Path, required=True)
    ap.add_argument("--ps3-wad",  type=Path, required=True)
    ap.add_argument("--output", "-o", type=Path,
                    default=Path("output/analysis/cross_platform_block_inventory.json"))
    args = ap.parse_args()
    args.output.parent.mkdir(parents=True, exist_ok=True)

    # ── 1. Parse header metadata from each WAD ───────────────────────
    wads: dict[str, dict] = {}
    for label, wad_path in [
        ("pc", args.pc_wad), ("xbox", args.xbox_wad), ("ps3", args.ps3_wad),
    ]:
        print(f"\n{'='*60}")
        print(f"Parsing {label.upper()}: {wad_path}")
        print(f"{'='*60}")
        m = parse_wad_metadata(wad_path, label)
        wads[label] = m
        print(f"  Endian:  {m['endian']}")
        print(f"  Version: {m['version']}")
        print(f"  Blocks:  {m['block_count']}")
        print(f"  PTHS:    {m['pths_count']}")
        print(f"  ASET:    {m['aset_count']}")
        print(f"  File:    {m['file_size']:,} bytes")

    # ── 2. Build norm_name → per-block info maps ─────────────────────
    block_maps: dict[str, dict[str, dict]] = {}
    for plat, m in wads.items():
        bm: dict[str, dict] = {}
        for i, raw in enumerate(m["paths"]):
            norm = _norm(raw)
            if not norm:
                norm = f"__empty_index_{i}__"
            indx_entry = m["indx"][i] if i < len(m["indx"]) else (0, 0, 0, 0)
            page_count = indx_entry[3]
            bm[norm] = {
                "index": i,
                "raw_path": raw,
                "page_count": page_count,
                "approx_bytes": page_count * PAGE_SIZE,
                "flags": indx_entry[2],
            }
        block_maps[plat] = bm

    # ── 3. Set algebra ───────────────────────────────────────────────
    s_pc   = set(block_maps["pc"])
    s_xbox = set(block_maps["xbox"])
    s_ps3  = set(block_maps["ps3"])

    cat_all3       = sorted(s_pc & s_xbox & s_ps3)
    cat_pc_xbox    = sorted((s_pc & s_xbox) - s_ps3)
    cat_pc_ps3     = sorted((s_pc & s_ps3) - s_xbox)
    cat_console    = sorted((s_xbox & s_ps3) - s_pc)
    cat_pc_only    = sorted(s_pc  - s_xbox - s_ps3)
    cat_xbox_only  = sorted(s_xbox - s_pc  - s_ps3)
    cat_ps3_only   = sorted(s_ps3  - s_pc  - s_xbox)

    # ── 4. Compressed-size comparison for shared blocks ──────────────
    size_same  = 0
    size_diffs: list[dict] = []

    for n in cat_all3:
        pc_p   = block_maps["pc"][n]["page_count"]
        xbox_p = block_maps["xbox"][n]["page_count"]
        ps3_p  = block_maps["ps3"][n]["page_count"]

        if pc_p == xbox_p == ps3_p:
            size_same += 1
            continue

        hi = max(pc_p, xbox_p, ps3_p)
        lo = min(pc_p, xbox_p, ps3_p)
        ratio = round(hi / lo, 3) if lo > 0 else (
            float("inf") if hi > 0 else 1.0)

        size_diffs.append({
            "name": n,
            "pc_pages": pc_p,   "pc_approx": pc_p   * PAGE_SIZE,
            "xbox_pages": xbox_p, "xbox_approx": xbox_p * PAGE_SIZE,
            "ps3_pages": ps3_p,  "ps3_approx": ps3_p  * PAGE_SIZE,
            "max_min_ratio": ratio if ratio != float("inf") else "inf",
        })

    size_diffs.sort(
        key=lambda d: d["max_min_ratio"]
            if isinstance(d["max_min_ratio"], (int, float)) else 999999,
        reverse=True,
    )

    # ── 5. Helper for JSON block lists ───────────────────────────────
    def _detail(name: str, *plats: str) -> dict:
        d: dict = {"name": name}
        for p in plats:
            if p in block_maps and name in block_maps[p]:
                info = block_maps[p][name]
                d[f"{p}_index"]      = info["index"]
                d[f"{p}_page_count"] = info["page_count"]
                d[f"{p}_raw_path"]   = info["raw_path"]
        return d

    def _details(names: list[str], *plats: str) -> list[dict]:
        return [_detail(n, *plats) for n in names]

    # ── 6. Build and write JSON inventory ────────────────────────────
    inventory = {
        "summary": {
            p: {
                "file": wads[p]["path"],
                "file_size": wads[p]["file_size"],
                "block_count": wads[p]["block_count"],
                "pths_parsed": wads[p]["pths_count"],
                "aset_count": wads[p]["aset_count"],
                "endian": wads[p]["endian"],
            }
            for p in ("pc", "xbox", "ps3")
        },
        "category_counts": {
            "all_three": len(cat_all3),
            "pc_and_xbox_only": len(cat_pc_xbox),
            "pc_and_ps3_only": len(cat_pc_ps3),
            "xbox_and_ps3_console_only": len(cat_console),
            "pc_only": len(cat_pc_only),
            "xbox_only": len(cat_xbox_only),
            "ps3_only": len(cat_ps3_only),
            "total_unique_names": len(s_pc | s_xbox | s_ps3),
        },
        "categories": {
            "all_three": _details(cat_all3, "pc", "xbox", "ps3"),
            "pc_and_xbox_only": _details(cat_pc_xbox, "pc", "xbox"),
            "pc_and_ps3_only": _details(cat_pc_ps3, "pc", "ps3"),
            "xbox_and_ps3_console_only": _details(cat_console, "xbox", "ps3"),
            "pc_only": _details(cat_pc_only, "pc"),
            "xbox_only": _details(cat_xbox_only, "xbox"),
            "ps3_only": _details(cat_ps3_only, "ps3"),
        },
        "size_comparison": {
            "description": (
                "Shared blocks (all 3 platforms) with differing page counts. "
                "page_count * 0x8000 approximates compressed on-disk size."
            ),
            "page_size_bytes": PAGE_SIZE,
            "blocks_with_same_page_count": size_same,
            "blocks_with_different_page_count": len(size_diffs),
            "differences": size_diffs,
        },
    }

    args.output.write_text(json.dumps(inventory, indent=2), encoding="utf-8")
    print(f"\nJSON inventory written to: {args.output}")

    # ── 7. Human-readable summary to stdout ──────────────────────────
    hdr = f"\n{'='*60}\nCROSS-PLATFORM BLOCK INVENTORY SUMMARY\n{'='*60}"
    print(hdr)

    print("\nPlatform totals:")
    for p in ("pc", "xbox", "ps3"):
        m = wads[p]
        print(f"  {p.upper():5s}  {m['block_count']:>6,} blocks   "
              f"{m['aset_count']:>6,} ASET   "
              f"{m['file_size']/1024/1024:>8,.1f} MB")

    total = len(s_pc | s_xbox | s_ps3)
    print(f"\nUnique block names across all platforms: {total:,}")

    print("\nPresence categories:")
    rows = [
        ("All three (shared)",       len(cat_all3)),
        ("PC + Xbox only",           len(cat_pc_xbox)),
        ("PC + PS3 only",            len(cat_pc_ps3)),
        ("Xbox + PS3 (console-only)",len(cat_console)),
        ("PC only",                  len(cat_pc_only)),
        ("Xbox only",                len(cat_xbox_only)),
        ("PS3 only",                 len(cat_ps3_only)),
    ]
    for label, cnt in rows:
        print(f"  {label:32s} {cnt:>6,}")

    print(f"\nCompressed-size comparison (all-three blocks):")
    print(f"  Identical page counts: {size_same:,}")
    print(f"  Different page counts: {len(size_diffs):,}")

    big = [d for d in size_diffs
           if isinstance(d["max_min_ratio"], (int, float))
           and d["max_min_ratio"] > 1.5]
    print(f"  >50 % size difference: {len(big):,}")

    if big[:15]:
        print(f"\n  Largest size discrepancies:")
        for d in big[:15]:
            r = d["max_min_ratio"]
            r_str = f"{r:.2f}x" if isinstance(r, float) else str(r)
            print(f"    {d['name']}")
            print(f"      PC {d['pc_pages']:>4} pg  "
                  f"Xbox {d['xbox_pages']:>4} pg  "
                  f"PS3 {d['ps3_pages']:>4} pg  "
                  f"ratio {r_str}")

    for label, names, desc in [
        ("PC-only",      cat_pc_only,   "unique to PC"),
        ("Xbox-only",    cat_xbox_only, "unique to Xbox 360"),
        ("PS3-only",     cat_ps3_only,  "unique to PS3"),
        ("Console-only", cat_console,   "on Xbox+PS3 but not PC"),
    ]:
        if names:
            print(f"\n  Sample {desc} ({len(names):,} total):")
            for n in names[:8]:
                print(f"    {n}")
            if len(names) > 8:
                print(f"    ... and {len(names) - 8} more")

    print(f"\nDone. Full inventory: {args.output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
