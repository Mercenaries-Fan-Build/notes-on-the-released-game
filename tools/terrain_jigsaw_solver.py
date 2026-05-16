#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Brute-force / divide-and-conquer jigsaw solver for ``low_res_terrain`` tiles.

The retail ``low_res_terrain_P000_Q3`` block ships 400 tile meshes whose UCFX
file order is unrelated to the 20×20 placement grid. The greedy seam-grow in
:mod:`terrain_extractor` achieves mean seam mismatch ≈ 24 m; this module is the
algorithmic fallback intended to push it well below 5 m when the
``LowResTerrainObject`` metadata lookup is unavailable.

Pipeline:
  1. Decode all 400 tiles via :mod:`terrain_extractor` helpers.
  2. Sample each tile's 4 edges (E, W, N, S) at integer along-edge positions
     and build a pairwise edge-cost tensor with NumPy (chunked broadcast).
  3. Detect anchors: edges flat near sea level → coast; classify tiles as
     interior / border / corner.
  4. Initial assignment via existing greedy (multiple seeds) or anchor-locked
     seam-grow.
  5. Polish in multiple passes:
        a) global 2-opt swap (all pairs of cells),
        b) 3×3 sliding-window branch-and-bound (parallelised),
        c) simulated annealing restarts (one per CPU core).
  6. Compare all methods; write the lowest-cost assignment + stats.

Outputs:
  - ``output/terrain_jigsaw_assignment.json``: grid mapping + provenance.
  - ``output/terrain_jigsaw_stats.json``: per-method comparison & histograms.
  - ``output/cache/terrain_jigsaw_costs.npz``: cached pairwise cost matrix.

Does **not** modify :mod:`terrain_extractor`.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
import multiprocessing as mp
import os
import random
import sys
import time
from concurrent.futures import ProcessPoolExecutor, as_completed
from itertools import permutations
from pathlib import Path

import numpy as np

_REPO_TOOLS = Path(__file__).resolve().parent
if str(_REPO_TOOLS) not in sys.path:
    sys.path.insert(0, str(_REPO_TOOLS))

from terrain_extractor import (  # noqa: E402
    _LOW_RES_TERRAIN_GRID,
    _TILE_EDGE_TOL_M,
    _TILE_LOCAL_HALF_SPAN_M,
    _find_layers_static_blob,
    _find_low_res_blob,
)
from ucfx_mesh_codec import (  # noqa: E402
    _iter_geom_child_row_slices,
    _parse_prmg_body,
    decode_submesh,
    iter_ucfx_containers,
)

# Side indices: matches `_edge_height_profile` semantics.
E_IDX, W_IDX, N_IDX, S_IDX = 0, 1, 2, 3
_SIDE_NAMES = ("E", "W", "N", "S")
_SAMPLE_K = 401  # integer positions in [-200, +200]
_SAMPLE_OFFSET = 200

# Pair direction codes.
# DIR_H: tile A's east meets tile B's west (A left of B).
# DIR_V: tile A's south meets tile B's north (A above B).
_INVALID_COST = np.float32(1e6)
_MIN_OVERLAP_SAMPLES = 5

TileVerts = list[tuple[float, float, float]]
TileFaces = list[tuple[int, int, int]]
TileMesh = tuple[TileVerts, TileFaces]


# ---------------------------------------------------------------------------
# Tile loading
# ---------------------------------------------------------------------------

def load_tiles(blob_path: Path) -> tuple[list[TileMesh], bytes]:
    """Decode every UCFX tile mesh in the low_res_terrain blob (file order)."""
    data = blob_path.read_bytes()
    tiles: list[TileMesh] = []
    for container in iter_ucfx_containers(data):
        db = int(container["data_base"])
        for rows in _iter_geom_child_row_slices(container["chunks"]):
            sub = _parse_prmg_body(rows)
            if sub is None:
                continue
            verts, faces, _meta = decode_submesh(data, db, sub, hier_nodes=None)
            if verts and faces:
                tiles.append((verts, faces))
            break
    return tiles, data


# ---------------------------------------------------------------------------
# Edge profile construction
# ---------------------------------------------------------------------------

def _build_one_tile_profile(verts: TileVerts) -> np.ndarray:
    """Return ``(4, 401)`` mean-Y profile per side; NaN where no samples."""
    edge = _TILE_LOCAL_HALF_SPAN_M
    tol = _TILE_EDGE_TOL_M
    out = np.full((4, _SAMPLE_K), np.nan, dtype=np.float32)
    sums = np.zeros((4, _SAMPLE_K), dtype=np.float64)
    counts = np.zeros((4, _SAMPLE_K), dtype=np.int32)
    for x, y, z in verts:
        if x >= edge - tol:  # E: along = z
            idx = int(round(z)) + _SAMPLE_OFFSET
            if 0 <= idx < _SAMPLE_K:
                sums[E_IDX, idx] += y
                counts[E_IDX, idx] += 1
        if x <= -edge + tol:  # W
            idx = int(round(z)) + _SAMPLE_OFFSET
            if 0 <= idx < _SAMPLE_K:
                sums[W_IDX, idx] += y
                counts[W_IDX, idx] += 1
        if z >= edge - tol:  # N: along = x
            idx = int(round(x)) + _SAMPLE_OFFSET
            if 0 <= idx < _SAMPLE_K:
                sums[N_IDX, idx] += y
                counts[N_IDX, idx] += 1
        if z <= -edge + tol:  # S
            idx = int(round(x)) + _SAMPLE_OFFSET
            if 0 <= idx < _SAMPLE_K:
                sums[S_IDX, idx] += y
                counts[S_IDX, idx] += 1
    mask = counts > 0
    out[mask] = (sums[mask] / counts[mask]).astype(np.float32)
    return out


def build_profiles(tiles: list[TileMesh]) -> np.ndarray:
    """``(N, 4, 401)`` mean-Y profiles for every tile."""
    return np.stack([_build_one_tile_profile(v) for v, _ in tiles], axis=0)


# ---------------------------------------------------------------------------
# Pairwise cost matrix
# ---------------------------------------------------------------------------

def _pair_cost(a_arr: np.ndarray, b_arr: np.ndarray, chunk: int = 32) -> np.ndarray:
    """Mean ``|a-b|`` over positions where both are finite, NaN if <5 overlap.

    Returns ``(N1, N2)`` float32 array; cells with too little overlap are set
    to ``_INVALID_COST`` so we can ignore them in cost sums.
    """
    n1, k = a_arr.shape
    n2 = b_arr.shape[0]
    a_mask = ~np.isnan(a_arr)
    b_mask = ~np.isnan(b_arr)
    a_filled = np.where(a_mask, a_arr, np.float32(0.0))
    b_filled = np.where(b_mask, b_arr, np.float32(0.0))

    out = np.full((n1, n2), _INVALID_COST, dtype=np.float32)
    for i0 in range(0, n1, chunk):
        i1 = min(i0 + chunk, n1)
        am = a_mask[i0:i1, None, :]
        af = a_filled[i0:i1, None, :]
        bm = b_mask[None, :, :]
        bf = b_filled[None, :, :]
        both = am & bm
        diff = np.abs(af - bf) * both
        cnt = both.sum(axis=2)
        tot = diff.sum(axis=2)
        valid = cnt >= _MIN_OVERLAP_SAMPLES
        chunk_out = np.full(cnt.shape, _INVALID_COST, dtype=np.float32)
        if valid.any():
            chunk_out[valid] = tot[valid] / cnt[valid]
        out[i0:i1] = chunk_out
    return out


def build_cost_matrix(profiles: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    """Return ``(cost_h, cost_v)``.

    ``cost_h[a, b]`` is the seam mismatch (m) when tile ``a`` is placed
    immediately left of tile ``b`` (a.east vs b.west). ``cost_v[a, b]`` is
    when tile ``a`` is placed immediately above tile ``b`` (a.south vs b.north).
    """
    east = profiles[:, E_IDX]
    west = profiles[:, W_IDX]
    north = profiles[:, N_IDX]
    south = profiles[:, S_IDX]
    cost_h = _pair_cost(east, west)
    cost_v = _pair_cost(south, north)
    np.fill_diagonal(cost_h, _INVALID_COST)
    np.fill_diagonal(cost_v, _INVALID_COST)
    return cost_h, cost_v


# ---------------------------------------------------------------------------
# Anchor detection
# ---------------------------------------------------------------------------

def detect_coast_edges(
    profiles: np.ndarray,
    sea_level_max_y: float = 5.0,
    flat_std_max: float = 2.0,
    flat_y_max: float = 10.0,
) -> np.ndarray:
    """Return ``(N, 4)`` bool mask: True if that edge looks like coast/water.

    Heuristics:
      - All sampled Y values along the edge sit below ``flat_y_max`` (well
        below typical land elevation, with sea floor floor included),
      - Standard deviation along the edge is below ``flat_std_max``
        (water mesh = mostly flat).
    """
    n = profiles.shape[0]
    coast = np.zeros((n, 4), dtype=bool)
    for i in range(n):
        for s in range(4):
            row = profiles[i, s]
            row = row[~np.isnan(row)]
            if row.size < 10:
                continue
            if np.max(np.abs(row)) <= flat_y_max and np.std(row) <= flat_std_max:
                if np.mean(row) <= sea_level_max_y:
                    coast[i, s] = True
    return coast


def classify_tiles(coast: np.ndarray) -> dict[str, list[int]]:
    """Group tiles by coast-edge pattern (corner/border/interior)."""
    out: dict[str, list[int]] = {
        "corner_NW": [], "corner_NE": [], "corner_SW": [], "corner_SE": [],
        "border_N": [], "border_S": [], "border_E": [], "border_W": [],
        "interior": [],
        "ambiguous": [],
    }
    for i in range(coast.shape[0]):
        c = coast[i]
        e, w, n, s = c[E_IDX], c[W_IDX], c[N_IDX], c[S_IDX]
        n_coast = int(e) + int(w) + int(n) + int(s)
        if n_coast == 0:
            out["interior"].append(i)
        elif n_coast == 1:
            if e:
                out["border_E"].append(i)
            elif w:
                out["border_W"].append(i)
            elif n:
                out["border_N"].append(i)
            else:
                out["border_S"].append(i)
        elif n_coast == 2:
            # Corner if two adjacent edges are coast.
            if n and w:
                out["corner_NW"].append(i)
            elif n and e:
                out["corner_NE"].append(i)
            elif s and w:
                out["corner_SW"].append(i)
            elif s and e:
                out["corner_SE"].append(i)
            else:
                out["ambiguous"].append(i)
        else:
            out["ambiguous"].append(i)
    return out


# ---------------------------------------------------------------------------
# Cost evaluation on a grid
# ---------------------------------------------------------------------------

def grid_total_and_seams(
    grid: list[list[int]],
    cost_h: np.ndarray,
    cost_v: np.ndarray,
) -> tuple[float, list[float]]:
    """Return ``(total, seams)`` where total only counts finite seams."""
    G = len(grid)
    seams: list[float] = []
    total = 0.0
    for r in range(G):
        for c in range(G):
            t = grid[r][c]
            if c + 1 < G:
                cc = float(cost_h[t, grid[r][c + 1]])
                if cc < _INVALID_COST - 1:
                    total += cc
                    seams.append(cc)
            if r + 1 < G:
                cc = float(cost_v[t, grid[r + 1][c]])
                if cc < _INVALID_COST - 1:
                    total += cc
                    seams.append(cc)
    return total, seams


def mean_seam(grid, cost_h, cost_v) -> float:
    total, seams = grid_total_and_seams(grid, cost_h, cost_v)
    return total / len(seams) if seams else float("inf")


# ---------------------------------------------------------------------------
# Greedy seam-grow (matches terrain_extractor)
# ---------------------------------------------------------------------------

def greedy_seam_grow(
    cost_h: np.ndarray,
    cost_v: np.ndarray,
    seed_tile: int,
    G: int = _LOW_RES_TERRAIN_GRID,
) -> list[list[int]]:
    """Greedy 20×20 fill mirroring the terrain_extractor heuristic."""
    n = cost_h.shape[0]
    assign = [[-1] * G for _ in range(G)]
    used = np.zeros(n, dtype=bool)
    assign[0][0] = seed_tile
    used[seed_tile] = True

    for c in range(1, G):
        prev = assign[0][c - 1]
        row = cost_h[prev].copy()
        row[used] = _INVALID_COST + 1
        best = int(np.argmin(row))
        assign[0][c] = best
        used[best] = True

    for r in range(1, G):
        for c in range(G):
            north = assign[r - 1][c]
            score = cost_v[north].copy()
            if c > 0:
                west = assign[r][c - 1]
                score = (score + cost_h[west]) / 2.0
            score[used] = _INVALID_COST + 1
            best = int(np.argmin(score))
            assign[r][c] = best
            used[best] = True
    return assign


def best_greedy(
    cost_h: np.ndarray,
    cost_v: np.ndarray,
    n_tiles: int,
    n_seeds: int = 8,
    G: int = _LOW_RES_TERRAIN_GRID,
) -> tuple[list[list[int]], float]:
    """Try multiple seeds; keep the best by mean-seam cost."""
    last = n_tiles - 1
    row_end = G - 1
    seeds = [0, row_end, last - row_end, last, n_tiles // 2]
    extra = list(range(0, n_tiles, max(1, n_tiles // n_seeds)))[:n_seeds]
    seen = set()
    candidates = []
    for s in seeds + extra:
        if s in seen or not (0 <= s < n_tiles):
            continue
        seen.add(s)
        candidates.append(s)

    best_grid = None
    best_score = float("inf")
    for s in candidates:
        g = greedy_seam_grow(cost_h, cost_v, s, G=G)
        ms = mean_seam(g, cost_h, cost_v)
        if ms < best_score:
            best_score = ms
            best_grid = g
    assert best_grid is not None
    return best_grid, best_score


# ---------------------------------------------------------------------------
# Swap delta — exact, no double counting
# ---------------------------------------------------------------------------

def _edge_cost(grid, r1, c1, r2, c2, cost_h, cost_v) -> float:
    """Seam cost of edge between adjacent grid cells (returns 0 if invalid)."""
    if r1 == r2:
        if c1 + 1 == c2:
            v = float(cost_h[grid[r1][c1], grid[r2][c2]])
        else:
            v = float(cost_h[grid[r2][c2], grid[r1][c1]])
    else:
        if r1 + 1 == r2:
            v = float(cost_v[grid[r1][c1], grid[r2][c2]])
        else:
            v = float(cost_v[grid[r2][c2], grid[r1][c1]])
    return v if v < _INVALID_COST - 1 else 0.0


def _incident_edges(r: int, c: int, G: int):
    if c > 0:
        yield (r, c - 1, r, c)
    if c + 1 < G:
        yield (r, c, r, c + 1)
    if r > 0:
        yield (r - 1, c, r, c)
    if r + 1 < G:
        yield (r, c, r + 1, c)


def neighborhood_cost(grid, cells, cost_h, cost_v) -> float:
    """Sum of seam costs over the union of edges incident to ``cells``."""
    G = len(grid)
    seen: set[tuple[int, int, int, int]] = set()
    total = 0.0
    for (r, c) in cells:
        for r1, c1, r2, c2 in _incident_edges(r, c, G):
            key = (r1, c1, r2, c2)
            if key in seen:
                continue
            seen.add(key)
            total += _edge_cost(grid, r1, c1, r2, c2, cost_h, cost_v)
    return total


# ---------------------------------------------------------------------------
# Polish: 2-opt and limited 3-opt
# ---------------------------------------------------------------------------

def two_opt_pass(grid, cost_h, cost_v) -> int:
    """One full pass over every pair of cells; returns # of improving swaps."""
    G = len(grid)
    cells = [(r, c) for r in range(G) for c in range(G)]
    improvements = 0
    for i, (r1, c1) in enumerate(cells):
        for j in range(i + 1, len(cells)):
            r2, c2 = cells[j]
            before = neighborhood_cost(grid, [(r1, c1), (r2, c2)], cost_h, cost_v)
            grid[r1][c1], grid[r2][c2] = grid[r2][c2], grid[r1][c1]
            after = neighborhood_cost(grid, [(r1, c1), (r2, c2)], cost_h, cost_v)
            if after + 1e-6 < before:
                improvements += 1
            else:
                grid[r1][c1], grid[r2][c2] = grid[r2][c2], grid[r1][c1]
    return improvements


def two_opt_until_converged(grid, cost_h, cost_v, max_passes: int = 30, log=print) -> int:
    total = 0
    for it in range(max_passes):
        n = two_opt_pass(grid, cost_h, cost_v)
        total += n
        ms = mean_seam(grid, cost_h, cost_v)
        log(f"  [2opt] pass {it+1}: swaps={n} mean_seam_m={ms:.3f}")
        if n == 0:
            break
    return total


def three_cycle_pass(grid, cost_h, cost_v, neighborhood_radius: int = 4) -> int:
    """Try 3-cycle rotations within a Manhattan radius (cheaper than full 3-opt)."""
    G = len(grid)
    cells = [(r, c) for r in range(G) for c in range(G)]
    improvements = 0
    for r1, c1 in cells:
        for dr2 in range(-neighborhood_radius, neighborhood_radius + 1):
            for dc2 in range(-neighborhood_radius, neighborhood_radius + 1):
                r2, c2 = r1 + dr2, c1 + dc2
                if not (0 <= r2 < G and 0 <= c2 < G):
                    continue
                if (r2, c2) <= (r1, c1):
                    continue
                for dr3 in range(-neighborhood_radius, neighborhood_radius + 1):
                    for dc3 in range(-neighborhood_radius, neighborhood_radius + 1):
                        r3, c3 = r1 + dr3, c1 + dc3
                        if not (0 <= r3 < G and 0 <= c3 < G):
                            continue
                        if (r3, c3) <= (r2, c2):
                            continue
                        cells_n = [(r1, c1), (r2, c2), (r3, c3)]
                        before = neighborhood_cost(grid, cells_n, cost_h, cost_v)
                        # rotate A -> B -> C -> A
                        a = grid[r1][c1]; b = grid[r2][c2]; c = grid[r3][c3]
                        grid[r1][c1], grid[r2][c2], grid[r3][c3] = c, a, b
                        after = neighborhood_cost(grid, cells_n, cost_h, cost_v)
                        if after + 1e-6 < before:
                            improvements += 1
                            continue
                        # try reverse rotation A <- B <- C <- A
                        grid[r1][c1], grid[r2][c2], grid[r3][c3] = b, c, a
                        after2 = neighborhood_cost(grid, cells_n, cost_h, cost_v)
                        if after2 + 1e-6 < before:
                            improvements += 1
                        else:
                            grid[r1][c1], grid[r2][c2], grid[r3][c3] = a, b, c
    return improvements


# ---------------------------------------------------------------------------
# 3×3 sliding-window branch & bound block shuffle
# ---------------------------------------------------------------------------

def _block_bnb_optimize(
    tile_ids: list[int],
    boundary_left,
    boundary_top,
    boundary_right,
    boundary_bottom,
    cost_h: np.ndarray,
    cost_v: np.ndarray,
    bh: int,
    bw: int,
):
    """Branch-and-bound exact search over permutations of ``tile_ids`` placed in
    a ``bh × bw`` block. Returns ``(best_permutation_as_grid, best_cost)``.

    Boundary args: list-of-tile-ids on each side (length matching boundary length;
    ``None`` for "no constraint" on that side / out of grid).
    """
    k = len(tile_ids)
    assert k == bh * bw

    # Build candidate cell order: row-major (place top-left first, scan right then down).
    cell_order = [(r, c) for r in range(bh) for c in range(bw)]

    # Per-cell which neighbors are already placed when we reach it (in cell_order):
    placed_neighbors: list[list[tuple[int, int, str]]] = []
    for idx, (r, c) in enumerate(cell_order):
        neighbors = []
        # boundary
        if c == 0 and boundary_left is not None:
            neighbors.append(("BL", r, "left"))
        if r == 0 and boundary_top is not None:
            neighbors.append(("BT", c, "top"))
        if c == bw - 1 and boundary_right is not None:
            neighbors.append(("BR", r, "right"))
        if r == bh - 1 and boundary_bottom is not None:
            neighbors.append(("BB", c, "bottom"))
        # already-placed within block: left and up
        for j in range(idx):
            r2, c2 = cell_order[j]
            if r2 == r and c2 == c - 1:
                neighbors.append(("IN", j, "left"))
            if r2 == r - 1 and c2 == c:
                neighbors.append(("IN", j, "top"))
        placed_neighbors.append(neighbors)

    n_total_tiles = cost_h.shape[0]

    def cost_at_cell(idx: int, tile: int, current_assign: list[int]) -> float:
        """Cost incurred by placing ``tile`` at cell ``cell_order[idx]``."""
        total = 0.0
        for kind, j, side in placed_neighbors[idx]:
            if kind == "BL":
                bt = boundary_left[j]
                if bt is None: continue
                v = float(cost_h[bt, tile])
            elif kind == "BT":
                bt = boundary_top[j]
                if bt is None: continue
                v = float(cost_v[bt, tile])
            elif kind == "BR":
                bt = boundary_right[j]
                if bt is None: continue
                v = float(cost_h[tile, bt])
            elif kind == "BB":
                bt = boundary_bottom[j]
                if bt is None: continue
                v = float(cost_v[tile, bt])
            else:
                other = current_assign[j]
                if side == "left":
                    v = float(cost_h[other, tile])
                else:  # top
                    v = float(cost_v[other, tile])
            if v < _INVALID_COST - 1:
                total += v
        return total

    # Use min(cost) over remaining tiles for each remaining cell as a loose
    # lower bound. We precompute, for each cell, the best possible cost from
    # any of the tiles in our pool given placed neighbors at lock-in time.
    # (We use a simple "remaining min" pruning: ignored for now to keep it simple;
    # the branch-and-bound is still effective because k is small.)

    best_cost = float("inf")
    best_assign: list[int] | None = None
    current_assign = [-1] * k
    used = [False] * k

    def recurse(idx: int, running: float):
        nonlocal best_cost, best_assign
        if running >= best_cost:
            return
        if idx == k:
            if running < best_cost:
                best_cost = running
                best_assign = current_assign.copy()
            return
        for ti in range(k):
            if used[ti]:
                continue
            tile = tile_ids[ti]
            inc = cost_at_cell(idx, tile, current_assign)
            if running + inc >= best_cost:
                continue
            current_assign[idx] = tile
            used[ti] = True
            recurse(idx + 1, running + inc)
            used[ti] = False
            current_assign[idx] = -1

    recurse(0, 0.0)

    if best_assign is None:
        # Fallback: identity.
        best_assign = list(tile_ids)
        best_cost = 0.0
    # Convert flat order back to grid block.
    block_grid = [[-1] * bw for _ in range(bh)]
    for idx, (r, c) in enumerate(cell_order):
        block_grid[r][c] = best_assign[idx]
    return block_grid, best_cost


def _bnb_worker(args):
    (r0, c0, bh, bw, tile_ids, bL, bT, bR, bB, cost_h, cost_v) = args
    block_grid, _ = _block_bnb_optimize(tile_ids, bL, bT, bR, bB, cost_h, cost_v, bh, bw)
    return r0, c0, bh, bw, block_grid


def block_shuffle_pass(
    grid: list[list[int]],
    cost_h: np.ndarray,
    cost_v: np.ndarray,
    block_size: int = 3,
    stride: int | None = None,
    n_workers: int | None = None,
    log=print,
) -> int:
    """One pass of 3×3 (configurable) sliding-window block B&B; parallelised."""
    G = len(grid)
    bh = bw = block_size
    if stride is None:
        stride = block_size  # tile-disjoint blocks per phase
    # Improve correctness: do `block_size` phases with shifted origin so all cells are covered.
    improvements = 0
    for phase_r in range(block_size):
        for phase_c in range(block_size):
            jobs = []
            for r0 in range(phase_r, G - bh + 1, block_size):
                for c0 in range(phase_c, G - bw + 1, block_size):
                    tile_ids = [grid[r0 + r][c0 + c] for r in range(bh) for c in range(bw)]
                    # Boundary tiles
                    bL = [grid[r0 + r][c0 - 1] if c0 > 0 else None for r in range(bh)]
                    bR = [grid[r0 + r][c0 + bw] if c0 + bw < G else None for r in range(bh)]
                    bT = [grid[r0 - 1][c0 + c] if r0 > 0 else None for c in range(bw)]
                    bB = [grid[r0 + bh][c0 + c] if r0 + bh < G else None for c in range(bw)]
                    jobs.append((r0, c0, bh, bw, tile_ids, bL, bT, bR, bB, cost_h, cost_v))
            if not jobs:
                continue
            # Run in parallel.
            results = []
            if n_workers is None:
                n_workers = max(1, min(len(jobs), os.cpu_count() or 4))
            if n_workers <= 1 or len(jobs) == 1:
                for j in jobs:
                    results.append(_bnb_worker(j))
            else:
                with ProcessPoolExecutor(max_workers=n_workers) as ex:
                    for res in ex.map(_bnb_worker, jobs, chunksize=max(1, len(jobs) // n_workers)):
                        results.append(res)
            for (r0, c0, bh_r, bw_r, block_grid) in results:
                # Compute "before" and "after" costs over the union of edges
                # in the block (interior + boundary), and replace if better.
                cells_before = [(r0 + r, c0 + c) for r in range(bh_r) for c in range(bw_r)]
                before = neighborhood_cost(grid, cells_before, cost_h, cost_v)
                # Apply candidate
                snapshot = [grid[r][:] for r in range(G)]
                for r in range(bh_r):
                    for c in range(bw_r):
                        grid[r0 + r][c0 + c] = block_grid[r][c]
                after = neighborhood_cost(grid, cells_before, cost_h, cost_v)
                if after + 1e-6 < before:
                    improvements += 1
                else:
                    # revert
                    for r in range(G):
                        grid[r] = snapshot[r]
        log(
            f"  [block{block_size}] phase ({phase_r},?) improvements running: {improvements}"
        )
    return improvements


# ---------------------------------------------------------------------------
# Simulated annealing
# ---------------------------------------------------------------------------

def _sa_run(args):
    (
        seed,
        init_grid,
        cost_h,
        cost_v,
        n_steps,
        t_start,
        t_end,
    ) = args
    rng = random.Random(seed)
    G = len(init_grid)
    grid = [row[:] for row in init_grid]

    def total_cost():
        t, _ = grid_total_and_seams(grid, cost_h, cost_v)
        return t

    cur = total_cost()
    best = cur
    best_grid = [row[:] for row in grid]
    cells = [(r, c) for r in range(G) for c in range(G)]
    n_cells = len(cells)

    log_ratio = math.log(t_end / t_start) if t_start > 0 else -1.0
    for step in range(n_steps):
        if t_start > 0:
            T = t_start * math.exp(log_ratio * step / max(1, n_steps - 1))
        else:
            T = 1e-6
        i = rng.randrange(n_cells)
        j = rng.randrange(n_cells)
        if i == j:
            continue
        r1, c1 = cells[i]
        r2, c2 = cells[j]
        before = neighborhood_cost(grid, [(r1, c1), (r2, c2)], cost_h, cost_v)
        grid[r1][c1], grid[r2][c2] = grid[r2][c2], grid[r1][c1]
        after = neighborhood_cost(grid, [(r1, c1), (r2, c2)], cost_h, cost_v)
        delta = after - before
        if delta <= 0 or (T > 0 and rng.random() < math.exp(-delta / T)):
            cur += delta
            if cur < best:
                best = cur
                best_grid = [row[:] for row in grid]
        else:
            grid[r1][c1], grid[r2][c2] = grid[r2][c2], grid[r1][c1]
    return best_grid, best


def simulated_annealing_parallel(
    init_grid,
    cost_h,
    cost_v,
    n_workers: int = 28,
    n_steps: int = 200_000,
    t_start: float = 10.0,
    t_end: float = 0.01,
    log=print,
) -> tuple[list[list[int]], float]:
    """Run ``n_workers`` independent SA restarts; return the best."""
    args_list = [
        (seed, init_grid, cost_h, cost_v, n_steps, t_start, t_end)
        for seed in range(n_workers)
    ]
    log(f"  [SA] launching {n_workers} restarts × {n_steps} steps")
    t0 = time.time()
    best_grid = None
    best_score = float("inf")
    if n_workers <= 1:
        for a in args_list:
            g, sc = _sa_run(a)
            ms = sc / (2 * len(g) * (len(g) - 1))
            if sc < best_score:
                best_score = sc
                best_grid = g
            log(f"    seed {a[0]}: total={sc:.1f} mean_seam_m={ms:.3f}")
    else:
        with ProcessPoolExecutor(max_workers=n_workers) as ex:
            futures = {ex.submit(_sa_run, a): a[0] for a in args_list}
            for fut in as_completed(futures):
                g, sc = fut.result()
                ms = sc / (2 * len(g) * (len(g) - 1))
                seed_id = futures[fut]
                log(f"    seed {seed_id}: total={sc:.1f} mean_seam_m={ms:.3f}")
                if sc < best_score:
                    best_score = sc
                    best_grid = g
    log(f"  [SA] done in {time.time()-t0:.1f}s, best total={best_score:.1f}")
    assert best_grid is not None
    return best_grid, best_score


# ---------------------------------------------------------------------------
# Genetic algorithm with PMX crossover
# ---------------------------------------------------------------------------

def _flatten(grid):
    return [t for row in grid for t in row]


def _unflatten(perm, G):
    return [perm[r * G:(r + 1) * G] for r in range(G)]


def _pmx_crossover(parent_a, parent_b, rng):
    n = len(parent_a)
    lo = rng.randrange(n)
    hi = rng.randrange(n)
    if lo > hi:
        lo, hi = hi, lo
    child = [-1] * n
    for i in range(lo, hi + 1):
        child[i] = parent_a[i]
    # Map for the slice
    mapping = {parent_a[i]: parent_b[i] for i in range(lo, hi + 1)}
    for i in list(range(0, lo)) + list(range(hi + 1, n)):
        val = parent_b[i]
        while val in mapping:
            val = mapping[val]
            if val == parent_b[i]:
                break
        # If val ended up already in child slice, walk again.
        seen = set()
        while val in child[lo:hi + 1]:
            if val in seen:
                break
            seen.add(val)
            if val in mapping:
                val = mapping[val]
            else:
                break
        child[i] = val
    # Sanity: if any -1 remain (shouldn't), fill from missing tiles.
    missing = set(range(n)) - {x for x in child if x >= 0}
    for i in range(n):
        if child[i] == -1 and missing:
            child[i] = missing.pop()
    return child


def _mutate(perm, cost_h, cost_v, G, rng, n_swaps: int = 3):
    p = perm[:]
    for _ in range(n_swaps):
        i = rng.randrange(len(p))
        j = rng.randrange(len(p))
        if i == j:
            continue
        p[i], p[j] = p[j], p[i]
    return p


def _ga_fitness(perm, cost_h, cost_v, G):
    grid = _unflatten(perm, G)
    t, _ = grid_total_and_seams(grid, cost_h, cost_v)
    return t


def _ga_worker_eval(args):
    perm, cost_h, cost_v, G = args
    return _ga_fitness(perm, cost_h, cost_v, G)


def genetic_algorithm(
    init_grids: list[list[list[int]]],
    cost_h: np.ndarray,
    cost_v: np.ndarray,
    pop_size: int = 200,
    n_generations: int = 50,
    elite: int = 20,
    mutation_rate: float = 0.5,
    seed: int = 0,
    log=print,
) -> tuple[list[list[int]], float]:
    G = len(init_grids[0])
    rng = random.Random(seed)
    # Seed population from init_grids; pad with mutations.
    pop = [_flatten(g) for g in init_grids]
    n_total = G * G
    while len(pop) < pop_size:
        base = list(pop[rng.randrange(len(pop))])
        for _ in range(rng.randint(5, 20)):
            i = rng.randrange(n_total)
            j = rng.randrange(n_total)
            base[i], base[j] = base[j], base[i]
        pop.append(base)
    pop = pop[:pop_size]

    fitness = [_ga_fitness(p, cost_h, cost_v, G) for p in pop]
    order = sorted(range(pop_size), key=lambda i: fitness[i])
    pop = [pop[i] for i in order]
    fitness = [fitness[i] for i in order]

    for gen in range(n_generations):
        new_pop = pop[:elite]
        while len(new_pop) < pop_size:
            # Tournament selection
            a = min(rng.sample(range(pop_size), 4), key=lambda i: fitness[i])
            b = min(rng.sample(range(pop_size), 4), key=lambda i: fitness[i])
            child = _pmx_crossover(pop[a], pop[b], rng)
            if rng.random() < mutation_rate:
                child = _mutate(child, cost_h, cost_v, G, rng)
            new_pop.append(child)
        pop = new_pop[:pop_size]
        fitness = [_ga_fitness(p, cost_h, cost_v, G) for p in pop]
        order = sorted(range(pop_size), key=lambda i: fitness[i])
        pop = [pop[i] for i in order]
        fitness = [fitness[i] for i in order]
        if gen % 5 == 0 or gen == n_generations - 1:
            best_mean = fitness[0] / (2 * G * (G - 1))
            log(f"  [GA] gen {gen}: best total={fitness[0]:.1f} mean_seam_m={best_mean:.3f}")

    return _unflatten(pop[0], G), fitness[0]


# ---------------------------------------------------------------------------
# Cache
# ---------------------------------------------------------------------------

def _blob_hash(data: bytes) -> str:
    return hashlib.sha1(data).hexdigest()[:16]


def get_or_build_cost_cache(
    blob_data: bytes,
    tiles: list[TileMesh],
    cache_path: Path,
    log=print,
) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """Return ``(cost_h, cost_v, profiles)``, using the npz cache when valid."""
    key = _blob_hash(blob_data)
    if cache_path.is_file():
        try:
            data = np.load(cache_path, allow_pickle=False)
            if str(data.get("hash_key", "")) == key:
                log(f"  cache hit: {cache_path.name}")
                return data["cost_h"], data["cost_v"], data["profiles"]
            else:
                log(f"  cache miss (hash mismatch)")
        except Exception as exc:  # noqa: BLE001
            log(f"  cache load failed: {exc}")
    log(f"  building profiles (N={len(tiles)})")
    t0 = time.time()
    profiles = build_profiles(tiles)
    log(f"    profiles: {time.time()-t0:.2f}s shape={profiles.shape}")
    t0 = time.time()
    cost_h, cost_v = build_cost_matrix(profiles)
    log(f"    pairwise cost: {time.time()-t0:.2f}s")
    cache_path.parent.mkdir(parents=True, exist_ok=True)
    np.savez_compressed(cache_path, cost_h=cost_h, cost_v=cost_v, profiles=profiles, hash_key=np.array(key))
    log(f"    cached → {cache_path}")
    return cost_h, cost_v, profiles


# ---------------------------------------------------------------------------
# Stats
# ---------------------------------------------------------------------------

def grid_stats(grid, cost_h, cost_v) -> dict:
    total, seams = grid_total_and_seams(grid, cost_h, cost_v)
    arr = np.array(seams, dtype=np.float32) if seams else np.array([0.0], dtype=np.float32)
    return {
        "total_seam_cost": float(total),
        "mean_seam_m": float(arr.mean()),
        "median_seam_m": float(np.median(arr)),
        "max_seam_m": float(arr.max()),
        "p90_seam_m": float(np.percentile(arr, 90)),
        "p99_seam_m": float(np.percentile(arr, 99)),
        "n_seams": int(arr.size),
        "histogram_bins_m": [0, 1, 2, 5, 10, 20, 50, 100, 1000],
        "histogram_counts": [int(c) for c in np.histogram(arr, bins=[0, 1, 2, 5, 10, 20, 50, 100, 1000])[0]],
    }


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def _load_existing_greedy(meta_path: Path):
    if not meta_path.is_file():
        return None
    try:
        meta = json.loads(meta_path.read_text())
    except Exception:
        return None
    stats = meta.get("extract", {}).get("terrain_merge_stats", {})
    g = stats.get("grid_assignment")
    if isinstance(g, list) and len(g) == _LOW_RES_TERRAIN_GRID and len(g[0]) == _LOW_RES_TERRAIN_GRID:
        return [list(row) for row in g]
    return None


def main() -> int:
    ap = argparse.ArgumentParser(description="Jigsaw solver for low_res_terrain tiles")
    ap.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parents[1])
    ap.add_argument("--extracted-root", type=Path, default=None)
    ap.add_argument("--blob", type=Path, default=None)
    ap.add_argument("--out-dir", type=Path, default=None,
                    help="Where to write assignment JSON (default: <repo-root>/output)")
    ap.add_argument("--cache-path", type=Path, default=None,
                    help="Pairwise cost cache (.npz)")
    ap.add_argument("--workers", type=int, default=max(1, (os.cpu_count() or 4) - 2))
    ap.add_argument("--skip-sa", action="store_true")
    ap.add_argument("--skip-ga", action="store_true")
    ap.add_argument("--skip-block", action="store_true")
    ap.add_argument("--skip-3opt", action="store_true")
    ap.add_argument("--sa-steps", type=int, default=400_000)
    ap.add_argument("--sa-restarts", type=int, default=28)
    ap.add_argument("--ga-pop", type=int, default=200)
    ap.add_argument("--ga-gens", type=int, default=30)
    ap.add_argument("--metadata-trigger-path", type=Path, default=None,
                    help="If this file exists, exit early (sibling metadata solver wins)")
    args = ap.parse_args()

    repo_root = args.repo_root.resolve()
    extracted_root = args.extracted_root.resolve() if args.extracted_root else repo_root / "output" / "extracted"
    out_dir = args.out_dir.resolve() if args.out_dir else repo_root / "output"
    out_dir.mkdir(parents=True, exist_ok=True)
    cache_path = args.cache_path.resolve() if args.cache_path else out_dir / "cache" / "terrain_jigsaw_costs.npz"

    log = print
    t_start = time.time()

    # Bail if sibling metadata path already won.
    if args.metadata_trigger_path and args.metadata_trigger_path.is_file():
        try:
            sib = json.loads(args.metadata_trigger_path.read_text())
            if sib.get("mapping_source") == "metadata" and float(sib.get("mean_seam_m", 1e9)) < 5.0:
                log(f"metadata sibling already produced mean_seam={sib['mean_seam_m']:.3f}; exiting")
                return 0
        except Exception:
            pass

    blob = _find_low_res_blob(extracted_root, args.blob)
    log(f"loading tiles from {blob}")
    tiles, blob_data = load_tiles(blob)
    log(f"  loaded {len(tiles)} tiles in {time.time()-t_start:.2f}s")
    if len(tiles) != _LOW_RES_TERRAIN_GRID * _LOW_RES_TERRAIN_GRID:
        log(f"error: expected {_LOW_RES_TERRAIN_GRID**2} tiles, got {len(tiles)}")
        return 2

    cost_h, cost_v, profiles = get_or_build_cost_cache(blob_data, tiles, cache_path, log=log)

    # Anchors
    coast = detect_coast_edges(profiles)
    classes = classify_tiles(coast)
    log("anchor classes: " + ", ".join(f"{k}={len(v)}" for k, v in classes.items()))

    method_results: dict[str, tuple[list[list[int]], dict]] = {}

    # 1) Greedy baseline (from extractor meta if present, else compute)
    log("\n=== Greedy baseline ===")
    existing_meta = repo_root / "output" / "extracted" / "review" / "batch_vz" / blob.name.replace(".bin", "") / "mesh.meta.json"
    greedy = _load_existing_greedy(existing_meta)
    if greedy is not None:
        log(f"  loaded greedy from {existing_meta.name}")
    else:
        greedy, _ = best_greedy(cost_h, cost_v, len(tiles))
    method_results["greedy"] = (greedy, grid_stats(greedy, cost_h, cost_v))
    log(f"  greedy mean_seam_m={method_results['greedy'][1]['mean_seam_m']:.3f}")

    # Start from greedy for downstream polish.
    best_grid = [row[:] for row in greedy]

    # 2) 2-opt polish on greedy
    log("\n=== 2-opt polish (on greedy) ===")
    t0 = time.time()
    two_opt_until_converged(best_grid, cost_h, cost_v, max_passes=30, log=log)
    log(f"  2-opt total time {time.time()-t0:.1f}s")
    method_results["greedy+2opt"] = (
        [row[:] for row in best_grid],
        grid_stats(best_grid, cost_h, cost_v),
    )

    # 3) Block 3×3 B&B
    if not args.skip_block:
        log("\n=== 3×3 block B&B (parallel) ===")
        t0 = time.time()
        for outer in range(3):
            n_imp = block_shuffle_pass(best_grid, cost_h, cost_v, block_size=3,
                                       n_workers=args.workers, log=log)
            ms = mean_seam(best_grid, cost_h, cost_v)
            log(f"  [block3] outer {outer}: improvements={n_imp} mean_seam_m={ms:.3f}")
            if n_imp == 0:
                break
            two_opt_until_converged(best_grid, cost_h, cost_v, max_passes=10, log=log)
        log(f"  block-B&B + interleaved 2-opt total {time.time()-t0:.1f}s")
        method_results["greedy+2opt+block"] = (
            [row[:] for row in best_grid],
            grid_stats(best_grid, cost_h, cost_v),
        )

    # 4) 3-cycle (limited)
    if not args.skip_3opt:
        log("\n=== Limited 3-cycle polish ===")
        t0 = time.time()
        for it in range(5):
            n = three_cycle_pass(best_grid, cost_h, cost_v, neighborhood_radius=3)
            ms = mean_seam(best_grid, cost_h, cost_v)
            log(f"  [3cyc] pass {it+1}: improvements={n} mean_seam_m={ms:.3f}")
            if n == 0:
                break
            two_opt_until_converged(best_grid, cost_h, cost_v, max_passes=10, log=log)
        log(f"  3-cycle total {time.time()-t0:.1f}s")
        method_results["greedy+polish_all"] = (
            [row[:] for row in best_grid],
            grid_stats(best_grid, cost_h, cost_v),
        )

    # 5) Simulated annealing (parallel restarts) starting from current best.
    if not args.skip_sa:
        log("\n=== Simulated annealing (parallel restarts) ===")
        t0 = time.time()
        sa_grid, sa_total = simulated_annealing_parallel(
            best_grid, cost_h, cost_v,
            n_workers=min(args.sa_restarts, args.workers),
            n_steps=args.sa_steps,
            t_start=10.0, t_end=0.01, log=log,
        )
        log(f"  SA total {time.time()-t0:.1f}s")
        # Polish SA result
        two_opt_until_converged(sa_grid, cost_h, cost_v, max_passes=15, log=log)
        method_results["SA+2opt"] = (
            [row[:] for row in sa_grid],
            grid_stats(sa_grid, cost_h, cost_v),
        )
        # Keep SA result as new best if better.
        if method_results["SA+2opt"][1]["mean_seam_m"] < grid_stats(best_grid, cost_h, cost_v)["mean_seam_m"]:
            best_grid = sa_grid

    # 6) GA
    if not args.skip_ga:
        log("\n=== Genetic algorithm (PMX) ===")
        t0 = time.time()
        seeds = [method_results[k][0] for k in method_results]
        ga_grid, ga_total = genetic_algorithm(
            seeds, cost_h, cost_v,
            pop_size=args.ga_pop, n_generations=args.ga_gens, elite=20, log=log,
        )
        log(f"  GA total {time.time()-t0:.1f}s")
        two_opt_until_converged(ga_grid, cost_h, cost_v, max_passes=15, log=log)
        method_results["GA+2opt"] = (
            [row[:] for row in ga_grid],
            grid_stats(ga_grid, cost_h, cost_v),
        )
        if method_results["GA+2opt"][1]["mean_seam_m"] < grid_stats(best_grid, cost_h, cost_v)["mean_seam_m"]:
            best_grid = ga_grid

    # Pick the overall best
    best_method = min(method_results, key=lambda k: method_results[k][1]["mean_seam_m"])
    best_assignment, best_stats = method_results[best_method]
    log(f"\n=== WINNER: {best_method} mean_seam_m={best_stats['mean_seam_m']:.3f} ===")

    # Compare to greedy
    greedy_stats = method_results["greedy"][1]
    greedy_grid = method_results["greedy"][0]
    tiles_moved = sum(
        1
        for r in range(_LOW_RES_TERRAIN_GRID)
        for c in range(_LOW_RES_TERRAIN_GRID)
        if greedy_grid[r][c] != best_assignment[r][c]
    )

    # Write assignment JSON
    tile_to_rc: dict[str, list[int]] = {}
    for r in range(_LOW_RES_TERRAIN_GRID):
        for c in range(_LOW_RES_TERRAIN_GRID):
            tile_to_rc[str(best_assignment[r][c])] = [r, c]

    assignment_payload = {
        "blob": blob.name,
        "blob_hash": _blob_hash(blob_data),
        "tile_count": len(tiles),
        "grid_size": _LOW_RES_TERRAIN_GRID,
        "tile_span_m": 400.0,
        "grid": best_assignment,
        "tile_to_rowcol": tile_to_rc,
        "provenance": {
            "method": best_method,
            "mean_seam_m": best_stats["mean_seam_m"],
            "max_seam_m": best_stats["max_seam_m"],
            "p99_seam_m": best_stats["p99_seam_m"],
        },
        "anchors": {k: v for k, v in classes.items() if v},
    }
    out_assign = out_dir / "terrain_jigsaw_assignment.json"
    out_assign.write_text(json.dumps(assignment_payload, indent=2))
    log(f"\nwrote {out_assign}")

    # Stats sidecar with per-method comparison
    sidecar = {
        "blob": blob.name,
        "elapsed_s": round(time.time() - t_start, 2),
        "n_tiles": len(tiles),
        "grid_size": _LOW_RES_TERRAIN_GRID,
        "winner": best_method,
        "comparison": {
            name: {
                **st,
                "tiles_moved_from_greedy": sum(
                    1
                    for r in range(_LOW_RES_TERRAIN_GRID)
                    for c in range(_LOW_RES_TERRAIN_GRID)
                    if greedy_grid[r][c] != grid[r][c]
                ),
            }
            for name, (grid, st) in method_results.items()
        },
        "anchor_counts": {k: len(v) for k, v in classes.items()},
        "greedy_to_winner": {
            "tiles_moved": tiles_moved,
            "mean_seam_improvement_m": greedy_stats["mean_seam_m"] - best_stats["mean_seam_m"],
            "mean_seam_ratio": best_stats["mean_seam_m"] / max(greedy_stats["mean_seam_m"], 1e-6),
        },
    }
    out_stats = out_dir / "terrain_jigsaw_stats.json"
    out_stats.write_text(json.dumps(sidecar, indent=2))
    log(f"wrote {out_stats}")

    # Print delta table
    log("\n--- Method comparison ---")
    log(f"{'method':24s}  {'mean_m':>8s}  {'median':>8s}  {'p90':>8s}  {'p99':>8s}  {'max':>9s}  {'moved':>6s}")
    for name in method_results:
        grid, st = method_results[name]
        moved = sum(
            1
            for r in range(_LOW_RES_TERRAIN_GRID)
            for c in range(_LOW_RES_TERRAIN_GRID)
            if greedy_grid[r][c] != grid[r][c]
        )
        log(
            f"{name:24s}  {st['mean_seam_m']:8.3f}  {st['median_seam_m']:8.3f}  "
            f"{st['p90_seam_m']:8.3f}  {st['p99_seam_m']:8.3f}  {st['max_seam_m']:9.3f}  {moved:6d}"
        )
    log(f"\nTotal wall clock: {time.time() - t_start:.1f}s")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
