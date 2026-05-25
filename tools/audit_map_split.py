#!/usr/bin/env python3
"""Map-split (act-gating) audit for low_res_terrain.

Investigates whether the world is one 20x20 grid or multiple regions, and
checks alternate orderings of the LowResTerrainObject COMP records against
placement positions.
"""
from __future__ import annotations

import json
import re
import struct
import sys
from collections import Counter, defaultdict
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
LAYERS_STATIC_BLOB = REPO / "output/extracted/batch_vz/blocks/00029_blocks__VZ__layers_static_P000_Q3.block.bin"
LAYERS_STATIC_JSON = REPO / "output/placements/layers_static.json"
LOW_RES_BLOB = REPO / "output/extracted/batch_vz/blocks/03121_blocks__VZ__low_res_terrain_P000_Q3.block.bin"
BATCH_VZ_DIR = REPO / "output/extracted/batch_vz/blocks"
AUDIT_PATH = REPO / "output/terrain_toc_mapping_audit.json"

# ------------------------------------------------------------------------
# COMP scanner: find every LowResTerrainObject COMP in any block.
# COMP records have: tag b"COMP" then per-sub-block CHDR with COMP children.
# Each COMP has an `info` child whose first nul-terminated ASCII is the type
# name (e.g. "LowResTerrainObject") and a `data` child with the records.
# ------------------------------------------------------------------------
def scan_block_for_lowres(blob_path: Path) -> list[dict]:
    data = blob_path.read_bytes()
    ucfx_positions: list[int] = []
    pos = 0
    while True:
        idx = data.find(b"UCFX", pos)
        if idx < 0:
            break
        ucfx_positions.append(idx)
        pos = idx + 1
    findings: list[dict] = []
    for sb_idx, ucfx_pos in enumerate(ucfx_positions):
        if ucfx_pos + 8 > len(data):
            continue
        ucfx_size = struct.unpack_from("<I", data, ucfx_pos + 4)[0]
        block_end = ucfx_positions[sb_idx + 1] if sb_idx + 1 < len(ucfx_positions) else len(data)
        chdr_pos = data.find(b"CHDR", ucfx_pos, min(ucfx_pos + ucfx_size + 200, block_end))
        if chdr_pos < 0:
            continue
        chdr_entries = struct.unpack_from("<I", data, chdr_pos + 12)[0]
        pos = chdr_pos + 20
        chunks: list[tuple[bytes, list[tuple[bytes, int, int]]]] = []
        for _ in range(chdr_entries):
            if pos + 20 > block_end:
                break
            tag = data[pos : pos + 4]
            if tag not in (b"COMP", b"enum", b"flgt", b"flgs"):
                break
            num_children = struct.unpack_from("<I", data, pos + 16)[0]
            children: list[tuple[bytes, int, int]] = []
            cpos = pos + 20
            for _ in range(num_children):
                if cpos + 20 > block_end:
                    break
                ctag = data[cpos : cpos + 4]
                coff = struct.unpack_from("<I", data, cpos + 4)[0]
                csz = struct.unpack_from("<I", data, cpos + 8)[0]
                children.append((ctag, coff, csz))
                cpos += 20
            chunks.append((tag, children))
            pos = cpos
        data_area_start = pos
        for tag, children in chunks:
            if tag != b"COMP":
                continue
            info_name = None
            data_child = None
            for ctag, coff, csz in children:
                abs_off = data_area_start + coff
                if ctag == b"info" and abs_off + csz <= len(data):
                    raw = data[abs_off : abs_off + csz]
                    null_idx = raw.find(b"\x00")
                    if null_idx > 0:
                        info_name = raw[:null_idx].decode("ascii", errors="replace")
                elif ctag == b"data":
                    data_child = (abs_off, csz)
            if info_name == "LowResTerrainObject" and data_child is not None:
                off, sz = data_child
                n = sz // 12
                records = []
                for i in range(n):
                    rec_off = off + i * 12
                    ek, mh, so = struct.unpack_from("<III", data, rec_off)
                    records.append((ek, mh, so))
                findings.append({
                    "blob": blob_path.name,
                    "sub_block": sb_idx,
                    "data_offset": off,
                    "data_size": sz,
                    "record_count": n,
                    "records": records,
                })
    return findings


def load_lrterrain_placements() -> list[dict]:
    data = json.load(LAYERS_STATIC_JSON.open())
    placements = data["placements"] if isinstance(data, dict) else data
    out = []
    rx = re.compile(r"^lrterrain_r(\d+)_c(\d+)$")
    for rec in placements:
        nm = rec.get("entity_name", "")
        m = rx.match(nm)
        if not m:
            continue
        r, c = int(m.group(1)), int(m.group(2))
        pos = rec["position"]
        out.append({
            "entity_name": nm,
            "entity_id": rec.get("entity_id"),
            "r": r, "c": c,
            "x": pos["x"], "y": pos["y"], "z": pos["z"],
            "sub_block": rec.get("sub_block"),
            "source_block": rec.get("source"),
        })
    return out


def find_spatial_clusters(plc: list[dict], gap_threshold_m: float = 600.0) -> list[dict]:
    """Simple cluster: connect tiles whose 2D euclidean distance < gap_threshold."""
    n = len(plc)
    parent = list(range(n))

    def find(a: int) -> int:
        while parent[a] != a:
            parent[a] = parent[parent[a]]
            a = parent[a]
        return a

    def union(a: int, b: int) -> None:
        ra, rb = find(a), find(b)
        if ra != rb:
            parent[ra] = rb

    for i in range(n):
        for j in range(i + 1, n):
            dx = plc[i]["x"] - plc[j]["x"]
            dz = plc[i]["z"] - plc[j]["z"]
            if (dx * dx + dz * dz) < gap_threshold_m * gap_threshold_m:
                union(i, j)
    groups: dict[int, list[int]] = defaultdict(list)
    for i in range(n):
        groups[find(i)].append(i)
    clusters = []
    for members in groups.values():
        xs = [plc[i]["x"] for i in members]
        ys = [plc[i]["y"] for i in members]
        zs = [plc[i]["z"] for i in members]
        rs = sorted({plc[i]["r"] for i in members})
        cs = sorted({plc[i]["c"] for i in members})
        clusters.append({
            "tile_count": len(members),
            "r_range": [min(rs), max(rs)],
            "c_range": [min(cs), max(cs)],
            "unique_r": rs,
            "unique_c": cs,
            "x_range": [min(xs), max(xs)],
            "y_range": [min(ys), max(ys)],
            "z_range": [min(zs), max(zs)],
            "sub_blocks": sorted({plc[i]["sub_block"] for i in members}),
            "source_blocks": sorted({plc[i]["source_block"] for i in members}),
        })
    clusters.sort(key=lambda c: -c["tile_count"])
    return clusters


def histogram(values: list[int]) -> dict[int, int]:
    return dict(sorted(Counter(values).items()))


def evaluate_record_ordering_hypotheses(
    records: list[tuple[int, int, int]],
    placements_by_name: dict[str, dict],
    n_grid: int = 20,
) -> list[dict]:
    """Discriminating test: under each candidate (record_index -> (r,c)) ordering,
    does record[i].entity_key match the entity_id of `lrterrain_r{r}_c{c}` in
    the placement data? Only the correct ordering will hit ~100%.

    `entity_key` in the LowResTerrainObject COMP is the same key used by the
    Name/Transform COMPs for that entity (per docs/placement_data_format.md
    §2.6/§2.9), so it is the ground-truth identifier for "which named entity
    does this record refer to".
    """
    hypotheses = []

    def score(name: str, idx_to_rc):
        hits = 0
        misses = []
        for i in range(len(records)):
            r, c = idx_to_rc(i)
            nm = f"lrterrain_r{r:02d}_c{c:02d}"
            p = placements_by_name.get(nm)
            if p is None:
                misses.append({"i": i, "rc": [r, c], "reason": "no_placement_for_name"})
                continue
            rec_ek = records[i][0]
            ek_hex = f"0x{rec_ek:08x}"
            placement_ek = p.get("entity_id")
            if placement_ek == ek_hex:
                hits += 1
            else:
                if len(misses) < 8:
                    misses.append({
                        "i": i, "rc": [r, c], "name": nm,
                        "record_entity_key": ek_hex,
                        "placement_entity_id": placement_ek,
                    })
        hypotheses.append({
            "name": name,
            "hits": hits,
            "total": len(records),
            "sample_misses": misses[:8],
        })

    score("row_major_20x20 (record_index = r*20+c)",
          lambda i: (i // n_grid, i % n_grid))
    score("col_major_20x20 (record_index = c*20+r)",
          lambda i: (i % n_grid, i // n_grid))
    score("row_major_reversed_rows (record_index = (19-r)*20+c)",
          lambda i: (n_grid - 1 - (i // n_grid), i % n_grid))
    score("row_major_reversed_cols (record_index = r*20+(19-c))",
          lambda i: (i // n_grid, n_grid - 1 - (i % n_grid))),
    score("two_halves_20x10_then_20x10 (north 0..199 then south 200..399)",
          lambda i: ((i // 10) if i < 200 else (i - 200) // 10,
                      (i % 10) if i < 200 else 10 + (i - 200) % 10))
    return hypotheses


def main() -> None:
    report: dict = {}

    # 1. Scan all batch_vz blocks for LowResTerrainObject COMPs.
    blocks = sorted(BATCH_VZ_DIR.glob("*.block.bin"))
    print(f"Scanning {len(blocks)} batch_vz block files for LowResTerrainObject COMPs...")
    findings: list[dict] = []
    for b in blocks:
        hits = scan_block_for_lowres(b)
        if hits:
            for h in hits:
                summary = {k: v for k, v in h.items() if k != "records"}
                summary["first_record"] = h["records"][0]
                summary["last_record"] = h["records"][-1]
                summary["unique_mesh_hashes"] = len({r[1] for r in h["records"]})
                summary["unique_entity_keys"] = len({r[0] for r in h["records"]})
                findings.append(summary)
                print(f"  {h['blob']:60s} sb={h['sub_block']:3d} records={h['record_count']:4d}")
    report["lowres_terrain_comp_findings"] = findings

    # 2. Spatial cluster the lrterrain placements.
    plc = load_lrterrain_placements()
    print(f"\nLoaded {len(plc)} lrterrain placements from layers_static.json")
    if plc:
        rs = sorted({p["r"] for p in plc})
        cs = sorted({p["c"] for p in plc})
        print(f"  unique r values: {len(rs)} -> range [{rs[0]}..{rs[-1]}]")
        print(f"  unique c values: {len(cs)} -> range [{cs[0]}..{cs[-1]}]")
        print(f"  r histogram: {histogram([p['r'] for p in plc])}")
        print(f"  c histogram: {histogram([p['c'] for p in plc])}")

    clusters = find_spatial_clusters(plc, gap_threshold_m=600.0)
    print(f"\nSpatial clusters (gap_threshold=600m): {len(clusters)} cluster(s)")
    for i, cl in enumerate(clusters):
        print(f"  cluster[{i}] tiles={cl['tile_count']} "
              f"x_range=[{cl['x_range'][0]:.0f}..{cl['x_range'][1]:.0f}] "
              f"z_range=[{cl['z_range'][0]:.0f}..{cl['z_range'][1]:.0f}] "
              f"r_range={cl['r_range']} c_range={cl['c_range']}")

    report["unique_r_values"] = sorted({p["r"] for p in plc})
    report["unique_c_values"] = sorted({p["c"] for p in plc})
    report["r_histogram"] = histogram([p["r"] for p in plc])
    report["c_histogram"] = histogram([p["c"] for p in plc])
    report["clusters"] = clusters

    # Print a low-res ASCII map of (c, r) cell presence
    if plc:
        r_min, r_max = report["unique_r_values"][0], report["unique_r_values"][-1]
        c_min, c_max = report["unique_c_values"][0], report["unique_c_values"][-1]
        present = {(p["r"], p["c"]) for p in plc}
        print(f"\nASCII map of (r, c) cell presence ({r_min}..{r_max} x {c_min}..{c_max}):")
        header = "      " + "".join(f"{c%10}" for c in range(c_min, c_max + 1))
        print(header)
        for r in range(r_min, r_max + 1):
            row = "".join("#" if (r, c) in present else "." for c in range(c_min, c_max + 1))
            print(f"  r{r:02d} {row}")

    # 3. Re-evaluate COMP record ordering hypotheses.
    if findings:
        # Use the first finding (sub_block 13 — known good); also re-load records.
        primary = findings[0]
        # We need the full record list; rescan to get records (didn't store in summary).
        all_records_block = scan_block_for_lowres(LAYERS_STATIC_BLOB)
        primary_full = next(
            (h for h in all_records_block if h["sub_block"] == primary["sub_block"]), None,
        )
        if primary_full is not None:
            records = primary_full["records"]
            placements_by_name = {p["entity_name"]: p for p in plc}
            hyps = evaluate_record_ordering_hypotheses(records, placements_by_name)
            print(f"\nRecord ordering hypotheses (does record_index -> (r,c) hit a real placement?):")
            for h in hyps:
                print(f"  {h['hits']:4d}/{h['total']:4d}  {h['name']}")
            report["record_ordering_hypotheses"] = hyps

    # 4. PTHS / ASET inspection.
    print(f"\nScanning layers_static for ASET / PTHS / region tags...")
    ls_data = LAYERS_STATIC_BLOB.read_bytes()
    region_tags = [b"ASET", b"PTHS", b"REGN", b"AREA"]
    region_hits = []
    for tag in region_tags:
        positions = []
        p = 0
        while True:
            i = ls_data.find(tag, p)
            if i < 0:
                break
            positions.append(i)
            p = i + 1
        region_hits.append({"tag": tag.decode(), "occurrences": len(positions),
                             "first_positions": positions[:5]})
        print(f"  tag {tag.decode():4s} -> {len(positions)} occurrence(s)")
    report["region_tags_layers_static"] = region_hits

    # 5. Map-split synthesis.
    n_clusters = len(clusters)
    is_split = n_clusters > 1
    report["map_split_summary"] = {
        "lowres_terrain_comp_count": len(findings),
        "lrterrain_placement_count": len(plc),
        "spatial_cluster_count": n_clusters,
        "appears_to_be_split": is_split,
        "single_grid_20x20_assumption_valid":
            (n_clusters == 1 and
             report["unique_r_values"] == list(range(20)) and
             report["unique_c_values"] == list(range(20))),
    }
    print(f"\nMap-split summary:")
    for k, v in report["map_split_summary"].items():
        print(f"  {k}: {v}")

    # 6. Merge into the existing audit JSON.
    if AUDIT_PATH.exists():
        existing = json.load(AUDIT_PATH.open())
    else:
        existing = {}
    existing["map_split_act_gating_analysis"] = report
    AUDIT_PATH.write_text(json.dumps(existing, indent=2))
    print(f"\nMerged map-split section into {AUDIT_PATH}")


if __name__ == "__main__":
    main()
