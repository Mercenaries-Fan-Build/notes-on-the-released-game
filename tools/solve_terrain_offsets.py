#!/usr/bin/env python3
"""Solve and emit per-tile Y offsets for the low_res_terrain merge.

Refines :mod:`probe_terrain_offsets` with two corrections informed by the
disconnect diagnosis:

1. **Ocean / placeholder tiles** (vertex_count ≤ 8, flat: dy < 1 m) are
   anchored at ``y_offset = 0``. They represent open-water cells modelled
   as a single quad spanning the 400 m tile span at sea level. Their
   absolute Y is already meaningful (sea level) and they should not be
   "solved" because the LSQ system would shift them arbitrarily.

2. **Seam-bucket threshold lowered to ≥ 2** so that ocean tiles (which
   produce exactly 2 buckets per edge — one at each corner) connect to
   their land neighbours. With ocean tiles anchored, the 2-bucket
   constraint anchors the **land** neighbour's edge at sea level, which
   is the physically correct boundary condition.

Outputs ``output/terrain_solved_offsets.json`` with the full per-tile
``y_offset`` array (400 floats, indexed by iter_idx). The terrain
extractor consumes this file to apply offsets at merge time.
"""
from __future__ import annotations

import json
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

MIN_MATCHES = 2
OCEAN_VERT_THRESHOLD = 8
OCEAN_DY_THRESHOLD = 1.0
ANCHOR_WEIGHT = 100.0


def _classify_ocean(meshes) -> list[bool]:
    flags: list[bool] = []
    for verts, _faces in meshes:
        if len(verts) <= OCEAN_VERT_THRESHOLD:
            ys = [v[1] for v in verts]
            dy = (max(ys) - min(ys)) if ys else 0.0
            flags.append(dy < OCEAN_DY_THRESHOLD)
        else:
            flags.append(False)
    return flags


def _build_system(meshes, grid, ocean_flag) -> tuple[np.ndarray, np.ndarray, list[dict]]:
    n_tiles = len(meshes)
    edges: list[dict[str, dict[float, float]]] = []
    for ti in range(n_tiles):
        verts = meshes[ti][0]
        edges.append({s: _edge_samples(verts, s) for s in ("E", "W", "N", "S")})

    rows: list[np.ndarray] = []
    rhs: list[float] = []
    log: list[dict] = []

    def add_seam(a: int, b: int, pa: dict[float, float], pb: dict[float, float], descr: dict) -> None:
        keys = sorted(set(pa) & set(pb))
        if len(keys) < MIN_MATCHES:
            descr["status"] = f"skip_{len(keys)}_matches"
            log.append(descr)
            return
        weight = 1.0 / float(len(keys))  # per-key weight so 80-bucket pairs don't dominate
        for k in keys:
            row = np.zeros(n_tiles)
            row[a] = weight
            row[b] = -weight
            rows.append(row)
            rhs.append(weight * (pb[k] - pa[k]))
        descr["status"] = "ok"
        descr["matched"] = len(keys)
        log.append(descr)

    for r in range(GRID_N):
        for c in range(GRID_N):
            a = grid[r][c]
            if c + 1 < GRID_N:
                b = grid[r][c + 1]
                add_seam(
                    a, b,
                    edges[a]["E"], edges[b]["W"],
                    {"type": "EW", "rc_a": [r, c], "rc_b": [r, c + 1], "tile_a": a, "tile_b": b},
                )
            if r + 1 < GRID_N:
                b = grid[r + 1][c]
                # Row increases with world Z. Upper-tile world-south face is
                # local z=+TILE_HALF (code label "N"); lower-tile world-north
                # face is local z=-TILE_HALF (code label "S"). The code labels
                # are inverted vs the row-major convention, so cross them.
                add_seam(
                    a, b,
                    edges[a]["N"], edges[b]["S"],
                    {"type": "NS", "rc_a": [r, c], "rc_b": [r + 1, c], "tile_a": a, "tile_b": b},
                )

    # Ocean anchors: y_offset[ocean_tile] = 0
    n_anchors = 0
    for ti, is_ocean in enumerate(ocean_flag):
        if is_ocean:
            row = np.zeros(n_tiles)
            row[ti] = ANCHOR_WEIGHT
            rows.append(row)
            rhs.append(0.0)
            n_anchors += 1
    print(f"  anchors: {n_anchors} ocean tiles pinned at y_offset=0")

    A = np.array(rows, dtype=np.float64)
    b = np.array(rhs, dtype=np.float64)
    return A, b, log


def _residual(meshes, grid, y_offsets) -> dict:
    edges_cache: dict[tuple[int, str], dict[float, float]] = {}

    def get_edge(t: int, s: str) -> dict[float, float]:
        k = (t, s)
        if k not in edges_cache:
            edges_cache[k] = _edge_samples(meshes[t][0], s)
        return edges_cache[k]

    per_edge: list[float] = []
    total_abs = 0.0
    total_pairs = 0
    for r in range(GRID_N):
        for c in range(GRID_N):
            a = grid[r][c]
            if c + 1 < GRID_N:
                b = grid[r][c + 1]
                pa = get_edge(a, "E")
                pb = get_edge(b, "W")
                keys = set(pa) & set(pb)
                if len(keys) >= MIN_MATCHES:
                    diffs = [
                        abs((pa[k] + y_offsets[a]) - (pb[k] + y_offsets[b]))
                        for k in keys
                    ]
                    per_edge.append(sum(diffs) / len(diffs))
                    total_abs += sum(diffs)
                    total_pairs += len(diffs)
            if r + 1 < GRID_N:
                b = grid[r + 1][c]
                pa = get_edge(a, "N")
                pb = get_edge(b, "S")
                keys = set(pa) & set(pb)
                if len(keys) >= MIN_MATCHES:
                    diffs = [
                        abs((pa[k] + y_offsets[a]) - (pb[k] + y_offsets[b]))
                        for k in keys
                    ]
                    per_edge.append(sum(diffs) / len(diffs))
                    total_abs += sum(diffs)
                    total_pairs += len(diffs)
    return {
        "n_edges": len(per_edge),
        "n_pairs": total_pairs,
        "mean_per_vertex": total_abs / total_pairs if total_pairs else None,
        "mean_per_edge": sum(per_edge) / len(per_edge) if per_edge else None,
        "max_per_edge": max(per_edge) if per_edge else None,
        "median_per_edge": sorted(per_edge)[len(per_edge) // 2] if per_edge else None,
    }


def main() -> int:
    repo = Path(__file__).resolve().parents[1]
    extracted = repo / "output" / "extracted"
    terrain_blob = sorted((extracted / "batch_vz" / "blocks").glob("*low_res_terrain*P000_Q3*.block.bin"))[0]
    layers_blob = sorted((extracted / "batch_vz" / "blocks").glob("*layers_static*P000_Q3*.block.bin"))[0]

    print(f"loading {terrain_blob.name}")
    meshes = _load_tile_meshes(terrain_blob)
    terrain_data = terrain_blob.read_bytes()
    layers_data = layers_blob.read_bytes()
    records = _read_lrterrain_records(layers_data)
    hash_to_idx = _read_toc_hash_to_idx(terrain_data)
    grid, _ = _build_grid(records, hash_to_idx, len(meshes))

    ocean_flag = _classify_ocean(meshes)
    n_ocean = sum(ocean_flag)
    print(f"  {len(meshes)} tiles  ({n_ocean} ocean / flat anchors)")

    print("residual seam stats BEFORE offsets:")
    pre = _residual(meshes, grid, [0.0] * len(meshes))
    print(f"  mean_per_vertex={pre['mean_per_vertex']:.3f}m  mean_per_edge={pre['mean_per_edge']:.3f}m  max_per_edge={pre['max_per_edge']:.2f}m  n_edges={pre['n_edges']}")

    print("building LSQ system")
    A, b, log = _build_system(meshes, grid, ocean_flag)
    print(f"  A: {A.shape}  b: {b.shape}")

    print("solving (numpy.linalg.lstsq)")
    sol, residuals, rank, sv = np.linalg.lstsq(A, b, rcond=None)
    print(f"  rank={rank}/{len(meshes)}  residuals={float(residuals[0]) if len(residuals) else 'n/a'}")
    print(f"  y_offset range: [{float(sol.min()):.2f}, {float(sol.max()):.2f}]  mean={float(sol.mean()):.2f}")

    print("residual seam stats AFTER offsets:")
    post = _residual(meshes, grid, sol)
    print(f"  mean_per_vertex={post['mean_per_vertex']:.4f}m  mean_per_edge={post['mean_per_edge']:.4f}m  max_per_edge={post['max_per_edge']:.2f}m  median_per_edge={post['median_per_edge']:.4f}m")

    out = repo / "output" / "terrain_solved_offsets.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps({
        "terrain_blob": terrain_blob.name,
        "model": "least_squares_y_only_with_ocean_anchors",
        "min_matches": MIN_MATCHES,
        "anchor_count": n_ocean,
        "anchor_weight": ANCHOR_WEIGHT,
        "rank": int(rank),
        "n_unknowns": len(meshes),
        "n_constraints": int(A.shape[0]) - n_ocean,
        "ocean_iter_indices": [i for i, f in enumerate(ocean_flag) if f],
        "y_offset_iter_indexed": [float(v) for v in sol],
        "y_offset_stats": {
            "min": float(sol.min()), "max": float(sol.max()),
            "mean": float(sol.mean()), "median": float(np.median(sol)),
            "stdev": float(sol.std()),
        },
        "residual_before": pre,
        "residual_after": post,
    }, indent=2))
    print(f"wrote {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
