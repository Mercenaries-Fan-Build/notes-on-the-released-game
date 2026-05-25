#!/usr/bin/env python3
"""Diagnose why some low_res_terrain tiles disconnect from the seam graph.

Run after :mod:`probe_terrain_offsets` reports rank < 400. This script:

1. Builds the per-tile boundary edge sample maps (E/W/N/S in 1 m buckets).
2. Walks the 20×20 grid edges, recording which adjacencies have ≥3 matched
   along-edge keys (the threshold the LSQ solver uses) — and which do not.
3. Lists each tile that has **zero** constraints (truly disconnected).
4. For every tile (not just disconnected), computes a rich feature set:
   ``vertex_count``, ``triangle_count``, bbox extents on X/Y/Z,
   ``bbox_aspect_y`` (= Y / max(X, Z)), connected component count over the
   triangle-adjacency graph, count of "vertical-normal" triangles (proxy
   for walls / interior structure).
5. Cross-checks the tile's TOC entry index, the TOC ``u0/u1/u2`` fields
   (so anomalous entries — like the dummy-adjacent giant entry 225 —
   show up), and the world XYZ from ``output/placements/layers_static.json``.
6. Tests the **variable-size / multi-resolution** hypothesis by comparing
   per-tile world XZ extent to the median, and the **interior structure**
   hypothesis via the wall-triangle fraction.

Writes ``output/terrain_disconnected_tiles.json`` plus
``output/terrain_size_analysis.json`` with the per-tile features.
"""
from __future__ import annotations

import json
import struct
import sys
from collections import defaultdict
from pathlib import Path

import numpy as np

_TOOLS = Path(__file__).resolve().parent
if str(_TOOLS) not in sys.path:
    sys.path.insert(0, str(_TOOLS))

from probe_terrain_offsets import (  # noqa: E402
    GRID_N,
    TILE_HALF,
    EDGE_TOL,
    ALONG_EDGE_BUCKET,
    _edge_samples,
    _load_tile_meshes,
    _read_lrterrain_records,
    _read_toc_hash_to_idx,
    _build_grid,
)


def _tri_normal_y(verts: list[tuple[float, float, float]], tri: tuple[int, int, int]) -> float:
    """Y-component of the triangle's geometric normal (unit-ish; sign-ambiguous)."""
    a = np.array(verts[tri[0]], dtype=np.float64)
    b = np.array(verts[tri[1]], dtype=np.float64)
    c = np.array(verts[tri[2]], dtype=np.float64)
    n = np.cross(b - a, c - a)
    ln = float(np.linalg.norm(n))
    if ln < 1e-9:
        return 0.0
    return float(n[1] / ln)


def _connected_components(n_verts: int, faces: list[tuple[int, int, int]]) -> int:
    """Count connected components over the triangle-adjacency graph (via vertex sharing)."""
    parent = list(range(n_verts))

    def find(x: int) -> int:
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    def union(x: int, y: int) -> None:
        rx, ry = find(x), find(y)
        if rx != ry:
            parent[rx] = ry

    for a, b, c in faces:
        union(a, b)
        union(b, c)
    roots = {find(i) for i in range(n_verts)}
    return len(roots)


def _tile_features(verts, faces) -> dict[str, float | int]:
    vs = np.array(verts, dtype=np.float64)
    xs, ys, zs = vs[:, 0], vs[:, 1], vs[:, 2]
    dx, dy, dz = float(xs.max() - xs.min()), float(ys.max() - ys.min()), float(zs.max() - zs.min())
    base = max(dx, dz, 1e-6)
    # Wall-triangle fraction: normal Y close to 0 means vertical face (wall).
    nys = [abs(_tri_normal_y(verts, t)) for t in faces]
    if nys:
        wall_frac = float(sum(1 for ny in nys if ny < 0.30) / len(nys))
        horiz_frac = float(sum(1 for ny in nys if ny > 0.95) / len(nys))
    else:
        wall_frac = 0.0
        horiz_frac = 0.0
    cc = _connected_components(len(verts), faces)
    return {
        "vertex_count": len(verts),
        "triangle_count": len(faces),
        "bbox_min": [float(xs.min()), float(ys.min()), float(zs.min())],
        "bbox_max": [float(xs.max()), float(ys.max()), float(zs.max())],
        "dx": dx,
        "dy": dy,
        "dz": dz,
        "bbox_aspect_y": dy / base,
        "wall_tri_fraction": wall_frac,
        "horizontal_tri_fraction": horiz_frac,
        "connected_components": cc,
    }


def _grid_constraint_counts(meshes, grid) -> tuple[dict, list[dict]]:
    """For every grid cell, count how many seam constraints involve it.

    Returns ``(per_cell_counts, adj_log)`` where:
      * ``per_cell_counts[(r, c)] = number_of_qualifying_seam_pairs`` (0..4).
      * ``adj_log`` is one record per attempted adjacency with the verdict
        (``ok`` / ``too_few_matches`` / ``empty_edge``) and bucket counts.
    """
    edge_cache: dict[tuple[int, str], dict[float, float]] = {}

    def get_edge(tile_idx: int, side: str) -> dict[float, float]:
        key = (tile_idx, side)
        if key not in edge_cache:
            edge_cache[key] = _edge_samples(meshes[tile_idx][0], side)
        return edge_cache[key]

    counts: dict[tuple[int, int], int] = {(r, c): 0 for r in range(GRID_N) for c in range(GRID_N)}
    adj_log: list[dict] = []

    def attempt(r_a, c_a, r_b, c_b, side_a, side_b):
        a = grid[r_a][c_a]
        b = grid[r_b][c_b]
        pa = get_edge(a, side_a)
        pb = get_edge(b, side_b)
        matched = sorted(set(pa) & set(pb))
        if len(matched) >= 3:
            counts[(r_a, c_a)] += 1
            counts[(r_b, c_b)] += 1
            verdict = "ok"
        elif not pa or not pb:
            verdict = "empty_edge"
        else:
            verdict = "too_few_matches"
        adj_log.append({
            "rc_a": [r_a, c_a],
            "rc_b": [r_b, c_b],
            "side_a": side_a,
            "side_b": side_b,
            "tile_a": int(a),
            "tile_b": int(b),
            "edge_a_buckets": len(pa),
            "edge_b_buckets": len(pb),
            "matched_buckets": len(matched),
            "verdict": verdict,
            "delta_y_mean": (
                float(sum(pb[k] - pa[k] for k in matched) / len(matched))
                if matched else None
            ),
        })

    for r in range(GRID_N):
        for c in range(GRID_N):
            if c + 1 < GRID_N:
                attempt(r, c, r, c + 1, "E", "W")
            if r + 1 < GRID_N:
                # Row increases with world Z; N/S labels are inverted vs row
                # (see solve_terrain_offsets / terrain_extractor for full note).
                attempt(r, c, r + 1, c, "N", "S")
    return counts, adj_log


def _read_terrain_toc(terrain_data: bytes) -> list[dict]:
    """Return one record per TOC entry: (index, u0, u1, u2, u3)."""
    n = struct.unpack_from("<I", terrain_data, 0)[0]
    out: list[dict] = []
    for i in range(n):
        u0, u1, u2, u3 = struct.unpack_from("<IIII", terrain_data, i * 16)
        out.append({"toc_entry": i, "u0": u0, "u1": u1, "u2": u2, "u3": u3})
    return out


def _record_to_iter_idx(terrain_data: bytes) -> dict[int, int]:
    """TOC index → iter index for every TOC entry whose UCFX is NOT filtered out."""
    from terrain_extractor import _read_low_res_terrain_toc
    hash_to_idx = _read_low_res_terrain_toc(terrain_data)
    n = struct.unpack_from("<I", terrain_data, 0)[0]
    out: dict[int, int] = {}
    for j in range(n):
        h1 = struct.unpack_from("<I", terrain_data, j * 16 + 4)[0]
        if h1 in hash_to_idx:
            out[j] = hash_to_idx[h1]
    return out


def _load_placements_xy(placements_json: Path) -> dict[tuple[int, int], dict]:
    data = json.loads(placements_json.read_text())
    out: dict[tuple[int, int], dict] = {}
    for p in data["placements"]:
        nm = p.get("entity_name", "")
        if not nm.startswith("lrterrain_r"):
            continue
        try:
            r = int(nm.split("_r")[1].split("_")[0])
            c = int(nm.split("_c")[1])
        except (IndexError, ValueError):
            continue
        out[(r, c)] = p
    return out


def main() -> int:
    repo = Path(__file__).resolve().parents[1]
    extracted = repo / "output" / "extracted"
    terrain_blob = sorted((extracted / "batch_vz" / "blocks").glob("*low_res_terrain*P000_Q3*.block.bin"))[0]
    layers_blob = sorted((extracted / "batch_vz" / "blocks").glob("*layers_static*P000_Q3*.block.bin"))[0]
    placements_json = repo / "output" / "placements" / "layers_static.json"

    print(f"loading tiles from {terrain_blob.name}")
    meshes = _load_tile_meshes(terrain_blob)
    terrain_data = terrain_blob.read_bytes()
    layers_data = layers_blob.read_bytes()

    records = _read_lrterrain_records(layers_data)
    hash_to_idx = _read_toc_hash_to_idx(terrain_data)
    grid, _gi = _build_grid(records, hash_to_idx, len(meshes))
    toc_entries = _read_terrain_toc(terrain_data)
    rec_to_iter = _record_to_iter_idx(terrain_data)
    placements = _load_placements_xy(placements_json)

    # Per-tile features
    print("computing per-tile features (bbox, components, walls)")
    feats: list[dict] = []
    for ti, (v, f) in enumerate(meshes):
        feats.append({"iter_idx": ti, **_tile_features(v, f)})

    # Map iter_idx → (r, c) using grid
    iter_to_rc: dict[int, tuple[int, int]] = {}
    for r in range(GRID_N):
        for c in range(GRID_N):
            iter_to_rc[grid[r][c]] = (r, c)

    for f in feats:
        rc = iter_to_rc[f["iter_idx"]]
        f["rc"] = list(rc)

    # Median feature stats
    dxs = sorted(f["dx"] for f in feats)
    dys = sorted(f["dy"] for f in feats)
    dzs = sorted(f["dz"] for f in feats)
    vcs = sorted(f["vertex_count"] for f in feats)
    tcs = sorted(f["triangle_count"] for f in feats)
    median_dx = dxs[len(dxs) // 2]
    median_dy = dys[len(dys) // 2]
    median_dz = dzs[len(dzs) // 2]
    median_vc = vcs[len(vcs) // 2]
    median_tc = tcs[len(tcs) // 2]
    print(f"  median  dx={median_dx:.2f}  dy={median_dy:.2f}  dz={median_dz:.2f}  v={median_vc}  t={median_tc}")

    # Grid constraint counts (which cells have zero adjacencies)
    print("walking grid edges to find disconnected cells")
    counts, adj_log = _grid_constraint_counts(meshes, grid)
    disconnected = sorted([rc for rc, n in counts.items() if n == 0])
    n_ok = sum(1 for a in adj_log if a["verdict"] == "ok")
    n_too_few = sum(1 for a in adj_log if a["verdict"] == "too_few_matches")
    n_empty = sum(1 for a in adj_log if a["verdict"] == "empty_edge")
    print(f"  adjacency verdicts: ok={n_ok} too_few={n_too_few} empty={n_empty}  total={len(adj_log)}")
    print(f"  cells with zero constraints: {len(disconnected)}")

    # Build the disconnected diagnosis bundle
    disc_records: list[dict] = []
    for r, c in disconnected:
        rec_idx = r * GRID_N + c
        mesh_hash = records[rec_idx][1]
        iter_idx = grid[r][c]
        tile_feat = next(f for f in feats if f["iter_idx"] == iter_idx)
        plc = placements.get((r, c))
        # TOC entry that originated this tile
        toc_entry_idx = next(
            (j for j, t in enumerate(toc_entries) if t["u1"] == mesh_hash),
            None,
        )
        # Per-side adjacency status
        neighbors: list[dict] = []
        for r_b, c_b, side_a, side_b in [
            (r, c + 1, "E", "W"),
            (r, c - 1, "W", "E"),
            (r + 1, c, "S", "N"),
            (r - 1, c, "N", "S"),
        ]:
            if not (0 <= r_b < GRID_N and 0 <= c_b < GRID_N):
                neighbors.append({
                    "rc": [r_b, c_b],
                    "side_self": side_a,
                    "status": "out_of_grid",
                })
                continue
            # Locate matching adj_log entry (orientation can be either way)
            log_entry = next(
                (
                    a for a in adj_log
                    if {tuple(a["rc_a"]), tuple(a["rc_b"])} == {(r, c), (r_b, c_b)}
                ),
                None,
            )
            neighbors.append({
                "rc": [r_b, c_b],
                "side_self": side_a,
                "side_neighbor": side_b,
                "verdict": log_entry["verdict"] if log_entry else "missing",
                "matched_buckets": log_entry["matched_buckets"] if log_entry else None,
                "edge_self_buckets": (
                    log_entry["edge_a_buckets"]
                    if log_entry and tuple(log_entry["rc_a"]) == (r, c)
                    else (log_entry["edge_b_buckets"] if log_entry else None)
                ),
                "edge_neighbor_buckets": (
                    log_entry["edge_b_buckets"]
                    if log_entry and tuple(log_entry["rc_a"]) == (r, c)
                    else (log_entry["edge_a_buckets"] if log_entry else None)
                ),
            })
        disc_records.append({
            "rc": [r, c],
            "iter_idx": iter_idx,
            "mesh_hash": f"0x{mesh_hash:08x}",
            "toc_entry_idx": toc_entry_idx,
            "toc_u0": toc_entries[toc_entry_idx]["u0"] if toc_entry_idx is not None else None,
            "toc_u2": f"0x{toc_entries[toc_entry_idx]['u2']:08x}" if toc_entry_idx is not None else None,
            "placement_xyz": (
                [plc["position"]["x"], plc["position"]["y"], plc["position"]["z"]]
                if plc else None
            ),
            "features": tile_feat,
            "neighbors": neighbors,
        })

    # Variable-size hypothesis: flag tiles where dx or dz deviates from median >30%
    var_size_flag: list[dict] = []
    for f in feats:
        ratio_dx = f["dx"] / median_dx if median_dx else 0
        ratio_dz = f["dz"] / median_dz if median_dz else 0
        if abs(ratio_dx - 1) > 0.30 or abs(ratio_dz - 1) > 0.30:
            var_size_flag.append({
                "iter_idx": f["iter_idx"],
                "rc": f["rc"],
                "dx": f["dx"],
                "dz": f["dz"],
                "ratio_dx": ratio_dx,
                "ratio_dz": ratio_dz,
            })

    # Interior hypothesis: flag tiles by feature outliers
    interior_flag: list[dict] = []
    for f in feats:
        flags: list[str] = []
        if f["vertex_count"] < median_vc * 0.5 or f["vertex_count"] > median_vc * 2.0:
            flags.append("vertex_count_outlier")
        if f["dy"] > 2.0 * median_dy:
            flags.append("y_extent_outlier")
        if f["wall_tri_fraction"] > 0.20:
            flags.append("high_wall_fraction")
        if f["connected_components"] > 1:
            flags.append("multiple_components")
        if flags:
            interior_flag.append({
                "iter_idx": f["iter_idx"],
                "rc": f["rc"],
                "flags": flags,
                "vertex_count": f["vertex_count"],
                "dy": f["dy"],
                "wall_tri_fraction": f["wall_tri_fraction"],
                "connected_components": f["connected_components"],
            })

    out_disc = repo / "output" / "terrain_disconnected_tiles.json"
    out_size = repo / "output" / "terrain_size_analysis.json"
    out_disc.parent.mkdir(parents=True, exist_ok=True)
    out_disc.write_text(json.dumps({
        "terrain_blob": terrain_blob.name,
        "n_disconnected": len(disconnected),
        "disconnected_cells": [list(rc) for rc in disconnected],
        "adjacency_verdict_summary": {
            "ok": n_ok,
            "too_few_matches": n_too_few,
            "empty_edge": n_empty,
            "total": len(adj_log),
        },
        "median_features": {
            "dx": median_dx, "dy": median_dy, "dz": median_dz,
            "vertex_count": median_vc, "triangle_count": median_tc,
        },
        "interior_or_structure_candidates": interior_flag,
        "variable_size_candidates": var_size_flag,
        "disconnected_records": disc_records,
    }, indent=2))
    out_size.write_text(json.dumps({
        "terrain_blob": terrain_blob.name,
        "median_features": {
            "dx": median_dx, "dy": median_dy, "dz": median_dz,
            "vertex_count": median_vc, "triangle_count": median_tc,
        },
        "per_tile": feats,
    }, indent=2))
    print(f"wrote {out_disc}")
    print(f"wrote {out_size}")

    print(f"\n=== Disconnected tiles ({len(disconnected)}) ===")
    for rec in disc_records:
        f = rec["features"]
        print(
            f"  rc={rec['rc']} iter={rec['iter_idx']} v={f['vertex_count']:5d}  t={f['triangle_count']:5d}  "
            f"dx={f['dx']:7.2f}  dy={f['dy']:7.2f}  dz={f['dz']:7.2f}  "
            f"wall={f['wall_tri_fraction']:.2f}  cc={f['connected_components']}"
        )
    print(f"\n=== Interior/structure candidates ({len(interior_flag)}) ===")
    for f in interior_flag:
        print(f"  rc={f['rc']} flags={f['flags']} v={f['vertex_count']} dy={f['dy']:.1f} wall={f['wall_tri_fraction']:.2f} cc={f['connected_components']}")

    print(f"\n=== Variable-size candidates ({len(var_size_flag)}) ===")
    for f in var_size_flag[:20]:
        print(f"  rc={f['rc']} dx={f['dx']:.1f} dz={f['dz']:.1f}  rx={f['ratio_dx']:.2f}  rz={f['ratio_dz']:.2f}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
