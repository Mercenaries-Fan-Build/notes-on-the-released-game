#!/usr/bin/env python3
"""Trace prop assets through the ASET→INDX→PTHS lookup chain.

Parses the WAD's ASET chunk to build asset_hash → block_index mapping,
correlates with PTHS paths, and traces named props to their blocks.

Usage:
    python3 tools/aset_prop_tracer.py --wad "path/to/vz.wad"
    python3 tools/aset_prop_tracer.py --extracted output/extracted/ffcs_vz/
"""
from __future__ import annotations

import argparse
import json
import struct
import sys
from collections import Counter, defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from pandemic_hash import pandemic_hash
from ffcs_wad import FFCSArchive, FFCSChunk, parse_ffcs, extract_slice, dump_paths_from_pths


def parse_indx(data: bytes) -> list[dict]:
    """Parse INDX chunk: 12-byte entries → block file offsets."""
    entries = []
    n = len(data) // 12
    for i in range(n):
        o = i * 12
        page_index, packed, flags_pages = struct.unpack_from("<III", data, o)
        offset = page_index * 0x8000
        page_count = flags_pages & 0xFFFF
        flags = (flags_pages >> 16) & 0xFFFF
        entries.append({
            "block_index": i,
            "page_index": page_index,
            "offset": offset,
            "packed": packed,
            "page_count": page_count,
            "flags": flags,
            "size_bytes": page_count * 0x8000,
        })
    return entries


def parse_aset(data: bytes) -> list[dict]:
    """Parse ASET chunk: 16-byte rows → (asset_hash, type_hash, u32_2, block_index)."""
    rows = []
    n = len(data) // 16
    for i in range(n):
        o = i * 16
        u0, u1, u2, u3 = struct.unpack_from("<IIII", data, o)
        rows.append({
            "row_index": i,
            "asset_hash": u0,
            "u32_1": u1,
            "u32_2": u2,
            "u32_3": u3,
        })
    return rows


def load_from_extracted(extracted_dir: Path) -> tuple[list[dict], list[dict], list[str]]:
    """Load pre-extracted aset.bin, indx.bin, paths.txt."""
    aset_bin = (extracted_dir / "aset.bin").read_bytes()
    indx_bin = (extracted_dir / "indx.bin").read_bytes()
    paths_txt = (extracted_dir / "paths.txt").read_text(encoding="utf-8", errors="replace")

    aset_rows = parse_aset(aset_bin)
    indx_entries = parse_indx(indx_bin)
    paths = [p.strip() for p in paths_txt.splitlines() if p.strip()]
    return aset_rows, indx_entries, paths


def load_from_wad(wad_path: Path) -> tuple[list[dict], list[dict], list[str]]:
    """Parse ASET, INDX, PTHS directly from WAD."""
    arch = parse_ffcs(wad_path)
    raw = wad_path.read_bytes()

    aset_chunk = next((c for c in arch.chunks if c.tag == "ASET"), None)
    indx_chunk = next((c for c in arch.chunks if c.tag == "INDX"), None)
    pths_chunk = next((c for c in arch.chunks if c.tag == "PTHS"), None)

    if not all([aset_chunk, indx_chunk, pths_chunk]):
        raise ValueError("WAD missing ASET/INDX/PTHS chunks")

    aset_rows = parse_aset(extract_slice(raw, aset_chunk))
    indx_entries = parse_indx(extract_slice(raw, indx_chunk))
    pths_paths = dump_paths_from_pths(extract_slice(raw, pths_chunk))
    return aset_rows, indx_entries, pths_paths


def build_hash_to_block_map(aset_rows: list[dict]) -> dict[int, list[dict]]:
    """Build asset_hash → list of ASET rows."""
    m: dict[int, list[dict]] = defaultdict(list)
    for row in aset_rows:
        m[row["asset_hash"]].append(row)
    return m


def main() -> int:
    ap = argparse.ArgumentParser(description="Trace prop assets through ASET→PTHS")
    ap.add_argument("--wad", type=Path, help="Path to vz.wad")
    ap.add_argument("--extracted", type=Path, help="Path to extracted ffcs_vz/ dir")
    ap.add_argument("--out", type=Path, default=Path("/tmp/aset_trace_results.json"))
    args = ap.parse_args()

    if args.extracted and args.extracted.is_dir():
        print(f"Loading from extracted dir: {args.extracted}")
        aset_rows, indx_entries, paths = load_from_extracted(args.extracted)
    elif args.wad and args.wad.is_file():
        print(f"Loading from WAD: {args.wad}")
        aset_rows, indx_entries, paths = load_from_wad(args.wad)
    else:
        print("ERROR: provide --wad or --extracted", file=sys.stderr)
        return 1

    print(f"ASET rows:    {len(aset_rows):,}")
    print(f"INDX entries: {len(indx_entries):,}")
    print(f"PTHS paths:   {len(paths):,}")

    hash_map = build_hash_to_block_map(aset_rows)
    print(f"Unique asset hashes: {len(hash_map):,}")

    # ── 1. Understand ASET field ranges ──
    u1_vals = Counter(r["u32_1"] for r in aset_rows)
    u3_vals = Counter(r["u32_3"] for r in aset_rows)
    u2_range = [min(r["u32_2"] for r in aset_rows), max(r["u32_2"] for r in aset_rows)]

    print(f"\nu32_1 unique values: {len(u1_vals)}")
    print(f"u32_1 top 10: {u1_vals.most_common(10)}")
    print(f"u32_2 range: [{u2_range[0]}, {u2_range[1]}]")
    print(f"  (as hex: [0x{u2_range[0]:08x}, 0x{u2_range[1]:08x}])")
    print(f"u32_3 range: [{min(u3_vals)}, {max(u3_vals)}]")
    print(f"u32_3 unique: {len(u3_vals)}, top 10: {u3_vals.most_common(10)}")

    # ── Check if u32_3 is a block index ──
    max_block = len(paths) - 1
    u3_in_range = sum(1 for r in aset_rows if 0 <= r["u32_3"] <= max_block)
    print(f"\nu32_3 values in block index range [0, {max_block}]: {u3_in_range}/{len(aset_rows)}")

    # Check if u32_2 might be a block index
    u2_in_range = sum(1 for r in aset_rows if 0 <= r["u32_2"] <= max_block)
    print(f"u32_2 values in block index range [0, {max_block}]: {u2_in_range}/{len(aset_rows)}")

    # ── 2. Try to figure out which field is block_index ──
    # u32_3 is small integers 0-35, probably type/category
    # u32_2 might be block index if values are in range
    # u32_1 is often 0xffffffff sentinel

    # Let's check u32_2 distribution more carefully
    u2_vals_counter = Counter(r["u32_2"] for r in aset_rows)
    print(f"\nu32_2 unique values: {len(u2_vals_counter)}")

    # Sample some ASET rows where we know the asset
    print("\n" + "=" * 80)
    print("TRACING KNOWN BLOCK PATHS THROUGH ASET")
    print("=" * 80)

    # Hash each path stem and see if it appears in ASET
    path_stem_hits = 0
    for bi, p in enumerate(paths[:50]):
        stem = p.split("\\")[-1].replace(".block", "")
        # Remove _P00x_Qy suffix
        import re
        m = re.match(r"(.+?)_P\d+_Q\d+", stem)
        if m:
            stem_base = m.group(1)
        else:
            stem_base = stem
        h = pandemic_hash(stem_base)
        if h in hash_map:
            rows = hash_map[h]
            path_stem_hits += 1
            if path_stem_hits <= 15:
                u2_vals_for_hit = [r["u32_2"] for r in rows]
                u3_vals_for_hit = [r["u32_3"] for r in rows]
                print(f"\n  Hash 0x{h:08x} ({stem_base}) → {len(rows)} ASET row(s)")
                print(f"    Block idx {bi}: {p}")
                print(f"    ASET u32_2 vals: {u2_vals_for_hit}")
                print(f"    ASET u32_3 vals: {u3_vals_for_hit}")

    print(f"\nPath stems found in ASET: {path_stem_hits}/{min(50, len(paths))}")

    # ── 3. Trace prop names ──
    print("\n" + "=" * 80)
    print("TRACING PROP NAMES")
    print("=" * 80)

    prop_names = [
        "palm_tree_03", "palm_tree_01", "bush_tropical_01",
        "fiona_car", "statue_bolivar", "billboard_01",
        "street_light_01", "trash_can_01", "fence_chainlink_01",
        "oil_barrel_01", "crate_wooden_01", "telephone_pole_01",
        "palm_tree_02", "palm_tree_04", "palm_tree_05",
        "tree_tropical_01", "tree_tropical_02", "bush_01",
        "rock_01", "rock_02", "bench_01", "fire_hydrant_01",
        "mailbox_01", "dumpster_01", "stop_sign_01",
        "traffic_light_01", "power_line_01", "antenna_01",
        "planter_01", "flower_pot_01",
    ]

    # Also try some known paths as asset names
    known_assets = [
        "estate_walllong", "commercialgrassymedian",
        "commercial_crater", "caracas_plantercapitolcenter",
        "layers_static", "scripts_vz", "low_res_terrain",
    ]

    prop_results = []
    for name in prop_names + known_assets:
        h = pandemic_hash(name)
        rows = hash_map.get(h, [])
        result = {
            "name": name,
            "hash": f"0x{h:08x}",
            "aset_rows": len(rows),
        }
        if rows:
            result["u32_1_vals"] = [f"0x{r['u32_1']:08x}" for r in rows]
            result["u32_2_vals"] = [r["u32_2"] for r in rows]
            result["u32_3_vals"] = [r["u32_3"] for r in rows]
            # Try to resolve u32_2 as block index
            for r in rows:
                bi = r["u32_2"]
                if 0 <= bi < len(paths):
                    result.setdefault("block_paths", []).append(paths[bi])
        print(f"  {name:35s} → 0x{h:08x} → {len(rows)} row(s)"
              + (f" → blocks: {result.get('block_paths', [])}" if rows else " (NOT FOUND)"))
        prop_results.append(result)

    # ── 4. Try alternate name formats ──
    print("\n" + "=" * 80)
    print("TRYING ALTERNATE NAME FORMATS")
    print("=" * 80)

    # Maybe props use different naming conventions
    alt_formats = []
    for base in ["palm_tree_03", "palm_tree_01", "bush_tropical_01", "estate_walllong"]:
        alts = [
            base,
            base.replace("_", ""),
            base.upper(),
            f"vz_{base}",
            f"global_{base}",
            f"env_{base}",
            f"resident2-{base}",
            f"commercial_{base}",
            f"maracaibo_{base}",
        ]
        for alt in alts:
            h = pandemic_hash(alt)
            if h in hash_map:
                rows = hash_map[h]
                block_paths_for_alt = []
                for r in rows:
                    bi = r["u32_2"]
                    if 0 <= bi < len(paths):
                        block_paths_for_alt.append(paths[bi])
                print(f"  HIT: {alt:40s} → 0x{h:08x} → {len(rows)} row(s) → {block_paths_for_alt[:3]}")
                alt_formats.append({"name": alt, "hash": f"0x{h:08x}", "blocks": block_paths_for_alt})

    # ── 5. Check what placement entity names look like ──
    print("\n" + "=" * 80)
    print("CHECKING PLACEMENT DATA FOR ENTITY NAMES")
    print("=" * 80)

    placement_files = [
        Path("output/placements/layers_static.json"),
        Path("output/placements/all_vz_state.json"),
    ]
    entity_names_from_placements: list[str] = []
    for pf in placement_files:
        if pf.is_file():
            pdata = json.loads(pf.read_text(encoding="utf-8"))
            if isinstance(pdata, list):
                records = pdata
            elif isinstance(pdata, dict) and "placements" in pdata:
                records = pdata["placements"]
            else:
                records = []
            names = set()
            for rec in records:
                en = rec.get("entity_name")
                if en:
                    names.add(en)
            entity_names_from_placements.extend(sorted(names))
            print(f"  {pf}: {len(names)} unique entity names from {len(records)} placements")

    # Now hash those entity names and look them up in ASET
    if entity_names_from_placements:
        found_in_aset = 0
        not_found = []
        found_details = []
        name_counter = Counter(entity_names_from_placements)

        for name in sorted(set(entity_names_from_placements)):
            h = pandemic_hash(name)
            rows = hash_map.get(h, [])
            if rows:
                found_in_aset += 1
                block_ps = []
                for r in rows:
                    bi = r["u32_2"]
                    if 0 <= bi < len(paths):
                        block_ps.append(paths[bi])
                found_details.append({
                    "name": name,
                    "hash": f"0x{h:08x}",
                    "aset_rows": len(rows),
                    "block_paths": block_ps[:5],
                })
            else:
                not_found.append(name)

        print(f"\n  Entity names found in ASET: {found_in_aset}/{len(set(entity_names_from_placements))}")
        print(f"  Entity names NOT found:     {len(not_found)}")

        if found_details:
            print(f"\n  First 30 found:")
            for d in found_details[:30]:
                print(f"    {d['name']:40s} → {d['hash']} → {d['aset_rows']} rows → {d['block_paths'][:2]}")

        if not_found:
            print(f"\n  First 30 NOT found:")
            for n in not_found[:30]:
                h = pandemic_hash(n)
                print(f"    {n:40s} → 0x{h:08x}")

    # ── 6. Block asset counts (top blocks by ASET references) ──
    print("\n" + "=" * 80)
    print("BLOCKS WITH MOST ASET REFERENCES")
    print("=" * 80)

    # If u32_2 is block index:
    block_asset_count = Counter()
    for row in aset_rows:
        bi = row["u32_2"]
        if 0 <= bi < len(paths):
            block_asset_count[bi] += 1

    print(f"  Blocks referenced by u32_2: {len(block_asset_count)}")
    print(f"\n  Top 40 blocks by asset count (u32_2 as block index):")
    for bi, cnt in block_asset_count.most_common(40):
        p = paths[bi] if bi < len(paths) else "???"
        print(f"    [{bi:5d}] {cnt:5d} assets → {p}")

    # ── 7. Also check if u32_1 could be type hash ──
    print("\n" + "=" * 80)
    print("CHECKING u32_1 AS TYPE HASH")
    print("=" * 80)

    type_names = [
        "SceneObject", "StaticMesh", "Texture", "Model", "Animation",
        "Sound", "Script", "Material", "Particle", "Light",
        "Vehicle", "Character", "Weapon", "Prop", "Terrain",
        "LevelGeometry", "SkeletalMesh", "AnimSet", "SoundBank",
        "effect", "mesh", "texture", "model", "skeleton",
        "registry", "block", "object",
    ]
    u1_set = set(r["u32_1"] for r in aset_rows)
    for tn in type_names:
        h = pandemic_hash(tn)
        if h in u1_set:
            count = sum(1 for r in aset_rows if r["u32_1"] == h)
            print(f"  u32_1 match: pandemic_hash('{tn}') = 0x{h:08x} → {count} rows")

    # Save results
    results = {
        "aset_row_count": len(aset_rows),
        "indx_entry_count": len(indx_entries),
        "pths_path_count": len(paths),
        "unique_asset_hashes": len(hash_map),
        "prop_trace_results": prop_results,
        "alt_format_hits": alt_formats,
        "block_asset_counts_top40": [
            {"block_index": bi, "asset_count": cnt, "path": paths[bi] if bi < len(paths) else "???"}
            for bi, cnt in block_asset_count.most_common(40)
        ],
    }

    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(results, indent=2), encoding="utf-8")
    print(f"\nResults written to {args.out}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
