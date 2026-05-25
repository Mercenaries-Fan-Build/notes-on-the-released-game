#!/usr/bin/env python3
"""Trace prop assets through the ASET→INDX→PTHS lookup chain.

Parses the WAD's ASET chunk to build the complete asset_hash → block_index
mapping, correlates with PTHS paths, and provides asset location analysis.

Usage:
    python3 tools/aset_prop_tracer.py --extracted output/extracted/ffcs_vz/
    python3 tools/aset_prop_tracer.py --wad "path/to/vz.wad"
    python3 tools/aset_prop_tracer.py --extracted output/extracted/ffcs_vz/ --dump-meshes
"""
from __future__ import annotations

import argparse
import json
import re
import struct
import sys
from collections import Counter, defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from pandemic_hash import pandemic_hash
from ffcs_wad import parse_ffcs, extract_slice, dump_paths_from_pths


def parse_indx(data: bytes) -> list[dict]:
    """Parse INDX chunk: 12-byte entries → block file offsets."""
    entries = []
    for i in range(len(data) // 12):
        o = i * 12
        page_index, packed, flags_pages = struct.unpack_from("<III", data, o)
        entries.append({
            "block_index": i,
            "page_index": page_index,
            "offset": page_index * 0x8000,
            "page_count": flags_pages & 0xFFFF,
            "size_bytes": (flags_pages & 0xFFFF) * 0x8000,
        })
    return entries


def parse_aset(data: bytes) -> list[dict]:
    """Parse ASET chunk: 16-byte rows.

    Returns list of dicts with decoded fields:
      asset_hash, secondary_ref, block_index, sub_offset, type_id
    """
    rows = []
    for i in range(len(data) // 16):
        o = i * 16
        u0, u1, u2, u3 = struct.unpack_from("<IIII", data, o)
        rows.append({
            "row_index": i,
            "asset_hash": u0,
            "secondary_ref": u1,
            "block_index": (u2 >> 16) & 0xFFFF,
            "sub_offset": u2 & 0xFFFF,
            "type_id": u3,
        })
    return rows


TYPE_NAMES = {
    27: "texture",
    28: "registry",
    16: "animation",
    19: "mesh",
    12: "unknown_12",
    9:  "unknown_9",
    35: "unknown_35",
    30: "unknown_30",
}


def load_from_extracted(d: Path) -> tuple[list[dict], list[dict], list[str]]:
    """Load pre-extracted aset.bin, indx.bin, paths.txt."""
    return (
        parse_aset((d / "aset.bin").read_bytes()),
        parse_indx((d / "indx.bin").read_bytes()),
        [p.strip() for p in (d / "paths.txt").read_text(encoding="utf-8", errors="replace").splitlines() if p.strip()],
    )


def load_from_wad(wad: Path) -> tuple[list[dict], list[dict], list[str]]:
    """Parse directly from WAD file."""
    arch = parse_ffcs(wad)
    raw = wad.read_bytes()
    get = lambda tag: next(c for c in arch.chunks if c.tag == tag)
    return (
        parse_aset(extract_slice(raw, get("ASET"))),
        parse_indx(extract_slice(raw, get("INDX"))),
        dump_paths_from_pths(extract_slice(raw, get("PTHS"))),
    )


def categorize_block(path: str) -> str:
    stem = path.split("\\")[-1].replace(".block", "")
    m = re.match(r"(.+?)_P\d+_Q\d+", stem)
    name = m.group(1) if m else stem
    if name.startswith("c3"):
        return "c3_cell"
    if name == "resident":
        return "resident"
    if name == "resident2" or name.startswith("resident2-"):
        return "resident2"
    if name.startswith("vz_state"):
        return "vz_state"
    if "veh" in name:
        return "vehicle"
    if "bld_" in name or "outpost" in name:
        return "building"
    if name in ("layers_static", "low_res_terrain", "effects", "scripts_vz"):
        return name
    return "other"


def main() -> int:
    ap = argparse.ArgumentParser(description="Trace assets through ASET→PTHS")
    ap.add_argument("--wad", type=Path)
    ap.add_argument("--extracted", type=Path)
    ap.add_argument("--out", type=Path, default=Path("/tmp/aset_trace_results.json"))
    ap.add_argument("--dump-meshes", action="store_true",
                    help="Show all mesh-type entries with their block paths")
    args = ap.parse_args()

    if args.extracted and args.extracted.is_dir():
        aset_rows, indx_entries, paths = load_from_extracted(args.extracted)
    elif args.wad and args.wad.is_file():
        aset_rows, indx_entries, paths = load_from_wad(args.wad)
    else:
        print("ERROR: provide --wad or --extracted", file=sys.stderr)
        return 1

    print(f"ASET rows:    {len(aset_rows):,}")
    print(f"INDX entries: {len(indx_entries):,}")
    print(f"PTHS paths:   {len(paths):,}")

    # Build lookup
    hash_map: dict[int, list[dict]] = defaultdict(list)
    for r in aset_rows:
        hash_map[r["asset_hash"]].append(r)

    print(f"Unique asset hashes: {len(hash_map):,}")

    # Block type distribution
    block_cats = Counter()
    for r in aset_rows:
        bi = r["block_index"]
        if bi < len(paths):
            block_cats[categorize_block(paths[bi])] += 1

    print("\n--- ASET entries by block category ---")
    for cat, cnt in sorted(block_cats.items(), key=lambda x: -x[1]):
        print(f"  {cnt:6,d} ({cnt / len(aset_rows) * 100:5.1f}%)  {cat}")

    # Type distribution
    type_counts = Counter(r["type_id"] for r in aset_rows)
    print("\n--- ASET entries by type_id ---")
    for t, cnt in type_counts.most_common():
        tname = TYPE_NAMES.get(t, f"unknown_{t}")
        print(f"  Type {t:2d} ({tname:12s}): {cnt:6,d}")

    # Mesh-type entries
    mesh_rows = [r for r in aset_rows if r["type_id"] == 19]
    print(f"\n--- Mesh assets (type 19): {len(mesh_rows):,} ---")
    mesh_cats = Counter()
    for r in mesh_rows:
        bi = r["block_index"]
        if bi < len(paths):
            mesh_cats[categorize_block(paths[bi])] += 1
    for cat, cnt in sorted(mesh_cats.items(), key=lambda x: -x[1]):
        print(f"  {cnt:5d} in {cat}")

    # Top blocks by mesh count
    mesh_blocks = Counter(r["block_index"] for r in mesh_rows)
    print("\n--- Top 20 blocks by mesh count ---")
    for bi, cnt in mesh_blocks.most_common(20):
        p = paths[bi] if bi < len(paths) else "???"
        print(f"  [{bi:5d}] {cnt:4d} meshes  {p}")

    if args.dump_meshes:
        print("\n--- All mesh entries ---")
        for r in mesh_rows:
            bi = r["block_index"]
            p = paths[bi] if bi < len(paths) else "???"
            sec = "primary" if r["secondary_ref"] == 0xFFFFFFFF else f"sec=0x{r['secondary_ref']:08x}"
            print(f"  0x{r['asset_hash']:08x}  block={bi:5d}  {sec:20s}  {p}")

    # Save JSON
    results = {
        "aset_row_count": len(aset_rows),
        "unique_hashes": len(hash_map),
        "block_distribution": dict(block_cats.most_common()),
        "type_distribution": {str(t): cnt for t, cnt in type_counts.most_common()},
        "mesh_count": len(mesh_rows),
        "mesh_block_distribution": dict(mesh_cats.most_common()),
        "top_mesh_blocks": [
            {"block_index": bi, "mesh_count": cnt,
             "path": paths[bi] if bi < len(paths) else "???"}
            for bi, cnt in mesh_blocks.most_common(40)
        ],
    }
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(results, indent=2), encoding="utf-8")
    print(f"\nResults → {args.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
