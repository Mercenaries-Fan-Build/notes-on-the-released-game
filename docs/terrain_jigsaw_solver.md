# Terrain jigsaw solver (algorithmic fallback)

`tools/terrain_jigsaw_solver.py` is a standalone solver that recovers the
20×20 `lrterrain` grid assignment from the 400 `low_res_terrain_P000_Q3`
UCFX tiles purely from seam geometry, with **no metadata input**.

It is preserved as a **documented experiment and fallback path** for cases
where the canonical metadata lookup is unavailable (e.g. damaged
`layers_static` block, modded archives, or a different game build whose
`LowResTerrainObject` COMP layout differs).

## Status — superseded by metadata lookup

A parallel investigation established the canonical, provably-correct
mapping:

1. `layers_static` sub-block 13 contains a `LowResTerrainObject` COMP with
   400 ordered 12-byte records `(entity_key, mesh_hash, scene_object_id)`.
2. The record index equals the `lrterrain_r{row:02d}_c{col:02d}` flat
   `(row * 20 + col)` index from `entity_name`.
3. Each `mesh_hash` matches one `hash1` in the `low_res_terrain` TOC.
   399/400 match exactly; the one outlier deterministically maps to the
   single unused TOC slot.

This is implemented by `_build_metadata_grid_assignment` in
`tools/terrain_extractor.py` and is the default path. Residual
`mean_seam_m ≈ 92` under the correct layout reflects how the source meshes
were authored (per-tile bbox-centered, not C0-continuous at seams) — it is
not an assignment error and is not closable by re-permuting tiles.

## When this solver would still be useful

- Validation: re-running the solver as a regression test should produce a
  mapping whose seam cost is **no better** than the metadata mapping. If
  the solver ever beats it, the metadata path is wrong (or the cost
  function is misaligned with the engine's seam definition).
- Modded / damaged archives without the COMP.
- Other Pandemic / Mercenaries-era titles that share the UCFX container
  pipeline but ship a different metadata layout.

## Implemented methods

The solver builds the full pairwise edge-cost tensor in NumPy:

```
cost_h[a, b]  = mean(|a.east(y) − b.west(y)|) over overlapping integer x/z samples
cost_v[a, b]  = mean(|a.south(y) − b.north(y)|)
```

400 × 400 × 2 directions, sampled at 401 integer positions per edge, cached
to `output/cache/terrain_jigsaw_costs.npz` keyed by SHA-1 of the blob.

Methods tried (in order), all sharing the cost tensor:

1. **Greedy seam-grow** (mirrors `terrain_extractor`): place a seed at
   (0,0), extend the first row by best east→west match, then fill each
   subsequent row by averaging north and west seam costs. Multiple seeds.
2. **Global 2-opt swap polish**: every pair of grid cells; swap if the
   neighborhood seam cost strictly decreases. Repeated to convergence.
3. **3×3 sliding-window branch-and-bound**: partition the 20×20 grid into
   3×3 blocks (with the 3×3 shift phases covering all alignments). For
   each block, run exact B&B over the 9! arrangements of the in-block
   tiles, bounded by the running cost. Parallelised across blocks via
   `concurrent.futures.ProcessPoolExecutor`.
4. **Limited 3-cycle moves**: every triple of cells within a Manhattan
   radius, try both 3-rotations.
5. **Simulated annealing**: 28 parallel restarts seeded from the polished
   greedy result, log-cooled from `T₀=10` to `T₁=0.01` over a configurable
   number of swap proposals; the best across restarts is kept.
6. **Genetic algorithm (PMX crossover)**: population seeded from all
   previous candidates, tournament selection, mutation via random k-opt
   swaps, elitism preserved.

Anchor detection (coast/border/corner) is included as a classification
hint but was not used to constrain initial placement in the run set —
intended as a future addition if a future build's metadata lookup fails.

## CLI

```bash
.venv/bin/python3 tools/terrain_jigsaw_solver.py \
    --extracted-root output/extracted \
    --workers 26 \
    --sa-restarts 28 \
    --sa-steps 400000 \
    --ga-pop 200 --ga-gens 30
```

Outputs:

| File | Purpose |
|------|---------|
| `output/terrain_jigsaw_assignment.json` | `tile_index → (row, col)` mapping + winning-method provenance + anchor classification. |
| `output/terrain_jigsaw_stats.json`      | Per-method comparison table, seam histograms, runtime. |
| `output/cache/terrain_jigsaw_costs.npz` | Pairwise cost cache (regenerated on blob-hash mismatch). |

## Run status

The solver was authored but **not executed end-to-end** in the session
that built it — the metadata sibling completed first with a provably
correct mapping, so spending compute on the algorithmic fallback would
have been wasted (and could not have beaten the metadata result anyway).

The solver remains available for the validation / modded-archive use
cases listed above. To validate against the metadata mapping in the
future, run it with `--skip-sa --skip-ga` for a fast greedy+2-opt+block
pass and compare seam stats to the metadata result.

## Anchor-selection rules (encoded, not yet exercised)

`detect_coast_edges` flags an edge as coast when:

- the edge has ≥ 10 finite sampled positions,
- `max(|y|) ≤ 10 m`,
- `std(y) ≤ 2 m`,
- `mean(y) ≤ 5 m` (sea level proxy).

`classify_tiles` groups tiles by adjacent-coast-edge count:

| coast edges | category               |
|-------------|------------------------|
| 0           | interior               |
| 1           | border_{N,S,E,W}       |
| 2 adjacent  | corner_{NW,NE,SW,SE}   |
| other       | ambiguous (skipped)    |

In a constrained start, corners are locked to the four grid corners and
border tiles to the perimeter (coast-edge facing outward).

## Possible improvements if revived

- Hungarian / min-cost assignment for the bipartite reduction once
  anchors are locked (would require `scipy.optimize.linear_sum_assignment`).
- Belief propagation over the grid Markov random field using the
  pairwise potentials.
- GPU-accelerated cost tensor build via PyTorch MPS (millisecond-scale
  vs ~seconds on CPU).
- Adaptive simulated-annealing schedules per restart.

None of these are pursued in the current build because the metadata
path is exact and adding `scipy`/`torch` to `requirements.txt` for an
unused fallback path is not justified.
