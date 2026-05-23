#!/usr/bin/env python3
"""Enumerate all unique type_hash values across every block in a retail vz.wad.

Produces a complete component type registry for the engine's Entity Component System.

Usage:
    .venv/bin/python3 tools/enumerate_type_hashes.py game-files/vz.wad --output docs/type_hash_registry.md
"""
from __future__ import annotations

import argparse
import json
import mmap as mmap_mod
import struct
import sys
import time
from collections import Counter, defaultdict
from pathlib import Path

THIS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(THIS_DIR))

from ffcs_wad import dump_paths_from_pths
from sges_decompress import decompress_sges_block

PAGE_SIZE = 0x8000


def parse_ffcs_header_lightweight(f) -> list[tuple[str, int, int]]:
    """Parse FFCS header without loading entire file."""
    magic = f.read(4)
    if magic != b"FFCS":
        raise ValueError(f"expected FFCS, got {magic!r}")
    version = struct.unpack("<I", f.read(4))[0]
    chunk_count = struct.unpack("<I", f.read(4))[0]
    rows = []
    for _ in range(5):
        tag = f.read(4).decode("ascii", errors="replace")
        offset = struct.unpack("<I", f.read(4))[0]
        meta = struct.unpack("<I", f.read(4))[0]
        rows.append((tag, offset, meta))
    return rows


def parse_indx_entries(data: bytes) -> list[dict]:
    entries = []
    for i in range(len(data) // 12):
        o = i * 12
        page_index, packed, flags_pages = struct.unpack_from("<III", data, o)
        entries.append({
            "block_index": i,
            "page_index": page_index,
            "offset": page_index * PAGE_SIZE,
            "page_count": flags_pages & 0xFFFF,
            "size_bytes": (flags_pages & 0xFFFF) * PAGE_SIZE,
        })
    return entries


def categorize_path(path: str) -> str:
    p = path.lower().replace("\\", "/")
    stem = p.split("/")[-1].replace(".block", "")

    if "scripts_vz" in p:
        return "scripts"
    if "layers_static" in p:
        return "placement_static"
    if "vz_state" in p or "vzstate" in p:
        return "placement_vz_state"
    if "low_res_terrain" in p or "lrterrain" in p:
        return "terrain"
    if "terrain" in stem:
        return "terrain"
    if "batch_vz" in p:
        if any(k in stem for k in ("bld", "building", "house", "apart", "church",
                                    "tower", "office", "shop", "hotel", "wall")):
            return "building"
        if any(k in stem for k in ("veg", "tree", "palm", "bush", "grass", "plant")):
            return "vegetation"
        if any(k in stem for k in ("vehicle", "car", "truck", "boat", "heli", "tank")):
            return "vehicle"
        if any(k in stem for k in ("weapon", "gun", "ammo", "crate", "barrel")):
            return "props_military"
        if any(k in stem for k in ("light", "lamp", "sign", "bench", "trash",
                                    "fence", "pole", "wire", "pipe")):
            return "props_urban"
        if any(k in stem for k in ("road", "bridge", "highway")):
            return "road_infrastructure"
        if any(k in stem for k in ("water", "river", "ocean", "sea")):
            return "water"
        return "mesh_asset"
    if "anim" in p:
        return "animation"
    if "texture" in p or "tex_" in stem:
        return "texture"
    return "other"


def main() -> int:
    ap = argparse.ArgumentParser(description="Enumerate type_hash values from WAD blocks")
    ap.add_argument("wad", type=Path, help="Path to vz.wad")
    ap.add_argument("--output", type=Path, default=Path("docs/type_hash_registry.md"),
                    help="Output markdown file")
    ap.add_argument("--json-output", type=Path, default=None,
                    help="Also write raw JSON data")
    ap.add_argument("--sample-every", type=int, default=1,
                    help="Process every Nth block (1 = all)")
    args = ap.parse_args()

    wad_path: Path = args.wad
    if not wad_path.is_file():
        print(f"ERROR: WAD file not found: {wad_path}", file=sys.stderr)
        return 1

    file_size = wad_path.stat().st_size
    print(f"Parsing FFCS header from {wad_path} ({file_size:,} bytes)...")

    with open(wad_path, "rb") as fh:
        rows = parse_ffcs_header_lightweight(fh)

    chunk_map: dict[str, tuple[int, int]] = {}
    for tag, offset, meta in rows:
        chunk_map[tag] = (offset, meta)

    if "INDX" not in chunk_map or "PTHS" not in chunk_map:
        print("ERROR: Missing INDX or PTHS chunk", file=sys.stderr)
        return 1

    sorted_offsets = sorted(
        [(tag, off, meta) for tag, (off, meta) in chunk_map.items() if tag != "CSUM" and off < file_size],
        key=lambda t: t[1]
    )
    chunk_sizes: dict[str, int] = {}
    for i, (tag, off, meta) in enumerate(sorted_offsets):
        nxt = sorted_offsets[i + 1][1] if i + 1 < len(sorted_offsets) else file_size
        chunk_sizes[tag] = nxt - off

    for tag, off, meta in rows:
        sz = chunk_sizes.get(tag, 0)
        print(f"  {tag}: offset=0x{off:X}, meta={meta}, size={sz:,}")

    print("Reading INDX and PTHS chunks...")
    indx_off, indx_meta = chunk_map["INDX"]
    pths_off, pths_meta = chunk_map["PTHS"]
    indx_size = chunk_sizes["INDX"]
    pths_size = chunk_sizes["PTHS"]

    with open(wad_path, "rb") as fh:
        fh.seek(indx_off)
        indx_data = fh.read(indx_size)
        fh.seek(pths_off)
        pths_data = fh.read(pths_size)

    indx_entries = parse_indx_entries(indx_data)
    paths = dump_paths_from_pths(pths_data)
    num_blocks = len(indx_entries)
    print(f"  INDX entries: {num_blocks}")
    print(f"  PTHS paths: {len(paths)}")

    print("Opening WAD with mmap for block access...")
    f = open(wad_path, "rb")
    mm = mmap_mod.mmap(f.fileno(), 0, access=mmap_mod.ACCESS_READ)

    type_hash_total_count: Counter[int] = Counter()
    type_hash_entry_count: Counter[int] = Counter()
    type_hash_block_count: Counter[int] = Counter()
    type_hash_paths: defaultdict[int, list[str]] = defaultdict(list)
    type_hash_categories: defaultdict[int, Counter[str]] = defaultdict(Counter)
    type_hash_name_hashes: defaultdict[int, set[int]] = defaultdict(set)

    blocks_processed = 0
    blocks_failed = 0
    blocks_empty = 0
    blocks_skipped = 0
    total_entries = 0

    t0 = time.time()

    for i in range(0, num_blocks, args.sample_every):
        entry = indx_entries[i]
        block_offset = entry["offset"]
        block_size = entry["size_bytes"]

        if block_size == 0:
            blocks_empty += 1
            continue

        path = paths[i] if i < len(paths) else f"block_{i:05d}"
        category = categorize_path(path)

        block_start = block_offset
        block_end = block_offset + block_size

        if block_end > len(mm):
            blocks_failed += 1
            continue

        try:
            header_bytes = mm[block_start:block_start + 16]
            if header_bytes[:4] != b"sges":
                blocks_failed += 1
                continue

            count_estimate = 500
            max_header = 4 + count_estimate * 16 + 256
            raw = decompress_sges_block(mm, block_start, block_end, max_out=max_header)

            if len(raw) < 4:
                blocks_failed += 1
                continue

            count = struct.unpack_from("<I", raw, 0)[0]

            if count > 100000 or count == 0:
                if count == 0:
                    blocks_empty += 1
                else:
                    blocks_failed += 1
                continue

            needed = 4 + count * 16
            if len(raw) < needed:
                raw = decompress_sges_block(mm, block_start, block_end,
                                            max_out=needed + 64)
                if len(raw) < needed:
                    blocks_failed += 1
                    continue

            seen_in_block: set[int] = set()
            for j in range(count):
                off = 4 + j * 16
                name_hash, type_hash, field_c, chunk_size = struct.unpack_from("<IIII", raw, off)

                type_hash_total_count[type_hash] += 1
                type_hash_entry_count[type_hash] += 1
                total_entries += 1
                seen_in_block.add(type_hash)
                type_hash_name_hashes[type_hash].add(name_hash)
                type_hash_categories[type_hash][category] += 1

                if len(type_hash_paths[type_hash]) < 10:
                    type_hash_paths[type_hash].append(path)

            for th in seen_in_block:
                type_hash_block_count[th] += 1

            blocks_processed += 1

        except Exception as exc:
            blocks_failed += 1
            if blocks_failed <= 5:
                print(f"  Block {i} failed: {exc}", file=sys.stderr)

        if (blocks_processed + blocks_failed) % 500 == 0:
            elapsed = time.time() - t0
            rate = (blocks_processed + blocks_failed) / elapsed if elapsed > 0 else 0
            print(f"  Progress: {blocks_processed + blocks_failed}/{num_blocks} "
                  f"({blocks_processed} ok, {blocks_failed} fail) "
                  f"[{rate:.0f} blocks/s, {len(type_hash_total_count)} unique hashes]")

    elapsed = time.time() - t0
    mm.close()
    f.close()

    print(f"\nDone in {elapsed:.1f}s")
    print(f"  Blocks processed: {blocks_processed}")
    print(f"  Blocks failed: {blocks_failed}")
    print(f"  Blocks empty: {blocks_empty}")
    print(f"  Total entries: {total_entries}")
    print(f"  Unique type_hashes: {len(type_hash_total_count)}")

    sorted_hashes = type_hash_total_count.most_common()

    def infer_type_name(th: int) -> str:
        cats = type_hash_categories[th]
        total = sum(cats.values())
        top_cat, top_count = cats.most_common(1)[0] if cats else ("unknown", 0)

        example_paths = type_hash_paths[th]
        path_str = " ".join(p.lower() for p in example_paths)

        if th == 0x42498680:
            return "Lua Script (BINN/LuaQ bytecode)"

        dominant_ratio = top_count / total if total > 0 else 0

        if dominant_ratio > 0.8:
            if top_cat == "scripts":
                return "Script-related component"
            if top_cat == "terrain":
                return "Terrain component"
            if top_cat == "placement_static":
                return "Static placement component"
            if top_cat == "placement_vz_state":
                return "VZ state overlay component"
            if top_cat == "animation":
                return "Animation component"
            if top_cat == "texture":
                return "Texture component"

        if "mesh" in path_str or "batch_vz" in path_str:
            unique_names = len(type_hash_name_hashes[th])
            if unique_names > 100:
                return "Common mesh sub-component"
            if dominant_ratio > 0.5 and top_cat == "vegetation":
                return "Vegetation mesh component"
            if dominant_ratio > 0.5 and top_cat == "building":
                return "Building mesh component"

        block_count = type_hash_block_count[th]
        if block_count == 1:
            return f"Singleton (only in: {example_paths[0][:60]})"

        return "Unknown"

    md_lines = [
        "# Type Hash Registry — Mercenaries 2 ECS Component Types",
        "",
        "Complete enumeration of `type_hash` values from every block in the retail `vz.wad`.",
        "",
        "## Summary",
        "",
        f"- **WAD file**: `{wad_path}`",
        f"- **Total blocks in WAD**: {num_blocks:,}",
        f"- **Blocks processed**: {blocks_processed:,}",
        f"- **Blocks failed/skipped**: {blocks_failed:,} failed, {blocks_empty:,} empty",
        f"- **Total UCFX entries**: {total_entries:,}",
        f"- **Unique type_hash values**: {len(type_hash_total_count):,}",
        f"- **Processing time**: {elapsed:.1f}s",
        "",
        "---",
        "",
        "## Frequency Table",
        "",
        "| # | type_hash | Entries | Blocks | Unique Names | Inferred Type | Top Category |",
        "|---|-----------|---------|--------|-------------|---------------|-------------|",
    ]

    for rank, (th, cnt) in enumerate(sorted_hashes, 1):
        blocks = type_hash_block_count[th]
        unique_names = len(type_hash_name_hashes[th])
        inferred = infer_type_name(th)
        cats = type_hash_categories[th]
        top_cat = cats.most_common(1)[0][0] if cats else "—"
        top_pct = cats.most_common(1)[0][1] / sum(cats.values()) * 100 if cats else 0
        md_lines.append(
            f"| {rank} | `0x{th:08X}` | {cnt:,} | {blocks:,} | {unique_names:,} "
            f"| {inferred} | {top_cat} ({top_pct:.0f}%) |"
        )

    md_lines.extend([
        "",
        "---",
        "",
        "## Category Distribution per Type Hash",
        "",
    ])

    for th, cnt in sorted_hashes:
        cats = type_hash_categories[th]
        total = sum(cats.values())
        md_lines.append(f"### `0x{th:08X}` — {cnt:,} entries across {type_hash_block_count[th]:,} blocks")
        md_lines.append("")
        md_lines.append("**Category breakdown:**")
        md_lines.append("")
        for cat, cat_cnt in cats.most_common():
            pct = cat_cnt / total * 100
            md_lines.append(f"- {cat}: {cat_cnt:,} ({pct:.1f}%)")
        md_lines.append("")
        md_lines.append("**Example paths:**")
        md_lines.append("")
        for p in type_hash_paths[th][:5]:
            md_lines.append(f"- `{p}`")
        md_lines.append("")

    md_lines.extend([
        "---",
        "",
        "## Name Hash Samples per Type Hash",
        "",
        "First 20 unique `name_hash` values seen for each type hash.",
        "",
    ])

    for th, cnt in sorted_hashes:
        names = sorted(type_hash_name_hashes[th])
        sample = names[:20]
        md_lines.append(f"### `0x{th:08X}` ({cnt:,} entries)")
        md_lines.append("")
        md_lines.append(f"Unique name_hashes: {len(names):,}")
        md_lines.append("")
        md_lines.append("```")
        for nh in sample:
            md_lines.append(f"  0x{nh:08X}")
        if len(names) > 20:
            md_lines.append(f"  ... and {len(names) - 20} more")
        md_lines.append("```")
        md_lines.append("")

    md_text = "\n".join(md_lines) + "\n"
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(md_text, encoding="utf-8")
    print(f"\nWrote {args.output} ({len(md_text):,} bytes)")

    if args.json_output:
        json_data = {
            "wad": str(wad_path),
            "num_blocks": num_blocks,
            "blocks_processed": blocks_processed,
            "blocks_failed": blocks_failed,
            "blocks_empty": blocks_empty,
            "total_entries": total_entries,
            "unique_type_hashes": len(type_hash_total_count),
            "elapsed_seconds": round(elapsed, 1),
            "type_hashes": [],
        }
        for rank, (th, cnt) in enumerate(sorted_hashes, 1):
            cats = dict(type_hash_categories[th].most_common())
            json_data["type_hashes"].append({
                "type_hash": f"0x{th:08X}",
                "type_hash_int": th,
                "entry_count": cnt,
                "block_count": type_hash_block_count[th],
                "unique_name_hashes": len(type_hash_name_hashes[th]),
                "inferred_type": infer_type_name(th),
                "categories": cats,
                "example_paths": type_hash_paths[th][:5],
                "name_hash_sample": [f"0x{nh:08X}" for nh in sorted(type_hash_name_hashes[th])[:20]],
            })
        args.json_output.parent.mkdir(parents=True, exist_ok=True)
        args.json_output.write_text(json.dumps(json_data, indent=2), encoding="utf-8")
        print(f"Wrote {args.json_output}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
