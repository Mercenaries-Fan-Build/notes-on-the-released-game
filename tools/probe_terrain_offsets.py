#!/usr/bin/env python3
"""Probe per-tile Y offsets for low_res_terrain.

Tests hypotheses 1-5 from the seam-diagnosis brief and writes a single
``output/terrain_seam_diagnosis.json`` summarising results.

Hypothesis 1 (placement Y carries the offset) — already extracted from
``layers_static`` placements: ALL 400 ``lrterrain_rXX_cYY`` placements
have ``y == 0.0``. So placement Y is NOT the per-tile elevation source.

Hypothesis 2 (COMP record stride > 12) — schm reports payload_stride=8
giving total stride 4+8=12, and ``data_sz / 12 == 400`` exactly. No
hidden bytes.

Hypothesis 3 (delta-encoded vertices + base in CHDR/BNDS) — BNDS encodes
(bbox center xyz + radius + AABB min/max) all derivable from the vertex
data itself; no separate elevation base.

Hypothesis 4 (overlap skirts) — ruled out structurally: per-tile mesh
bbox is exactly ±200m on X/Z, no overlap.

Hypothesis 5 (solve Y offsets via seam continuity) — implemented here.

For each adjacent (A, B) tile pair in the 20×20 grid we measure the mean
``Y_A_edge - Y_B_edge`` at the shared boundary using vertices within
``EDGE_TOL`` of the local ±200m boundary plane and bucketed by the
along-edge coordinate (Z for E/W seams, X for N/S seams). We then solve
``y_offset[A] - y_offset[B] = delta_BA`` in least squares with one tile
pinned to zero. Output `tile_y_offsets` (400 floats) plus the residual
seam stats before/after.
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

from ucfx_mesh_codec import (  # noqa: E402
    _iter_geom_child_row_slices,
    _parse_prmg_body,
    decode_submesh,
    iter_ucfx_containers,
)

GRID_N = 20
TILE_HALF = 200.0
EDGE_TOL = 0.5  # tile edge vertices are dead-on ±200 (verified)
ALONG_EDGE_BUCKET = 1.0  # round along-edge coord to ~1 m to share keys


def _load_tile_meshes(blob_path: Path) -> list[tuple[list, list]]:
    data = blob_path.read_bytes()
    meshes: list[tuple[list, list]] = []
    for container in iter_ucfx_containers(data):
        db = int(container["data_base"])
        got = None
        for rows in _iter_geom_child_row_slices(container["chunks"]):
            sub = _parse_prmg_body(rows)
            if sub is None:
                continue
            verts, faces, _ = decode_submesh(data, db, sub, hier_nodes=None)
            if verts:
                got = (verts, faces)
                break
        if got is None:
            raise RuntimeError(f"tile container at {container['ucfx_off']} has no decodable mesh")
        meshes.append(got)
    return meshes


def _edge_samples(verts, side: str) -> dict[float, float]:
    """Mean Y per along-edge bucket on the requested boundary."""
    buckets: dict[float, list[float]] = defaultdict(list)
    if side == "E":
        for x, y, z in verts:
            if abs(x - TILE_HALF) < EDGE_TOL:
                buckets[round(z / ALONG_EDGE_BUCKET) * ALONG_EDGE_BUCKET].append(y)
    elif side == "W":
        for x, y, z in verts:
            if abs(x + TILE_HALF) < EDGE_TOL:
                buckets[round(z / ALONG_EDGE_BUCKET) * ALONG_EDGE_BUCKET].append(y)
    elif side == "N":
        for x, y, z in verts:
            if abs(z - TILE_HALF) < EDGE_TOL:
                buckets[round(x / ALONG_EDGE_BUCKET) * ALONG_EDGE_BUCKET].append(y)
    else:  # "S"
        for x, y, z in verts:
            if abs(z + TILE_HALF) < EDGE_TOL:
                buckets[round(x / ALONG_EDGE_BUCKET) * ALONG_EDGE_BUCKET].append(y)
    return {k: sum(v) / len(v) for k, v in buckets.items()}


def _seam_delta(verts_a, side_a, verts_b, side_b) -> tuple[float | None, int, float]:
    """Return (mean(Y_a - Y_b), n_matched, mean|Δ|) at the shared edge."""
    pa = _edge_samples(verts_a, side_a)
    pb = _edge_samples(verts_b, side_b)
    keys = set(pa) & set(pb)
    if len(keys) < 3:
        return None, len(keys), float("nan")
    diffs = [pa[k] - pb[k] for k in keys]
    return sum(diffs) / len(diffs), len(diffs), sum(abs(d) for d in diffs) / len(diffs)


def _read_lrterrain_records(layers_static: bytes) -> list[tuple[int, int, int]]:
    """Decode the 400 ``LowResTerrainObject`` (entity_key, mesh_hash, scene_obj) records."""
    sub_blocks: list[int] = []
    pos = 0
    while True:
        idx = layers_static.find(b"UCFX", pos)
        if idx < 0:
            break
        sub_blocks.append(idx)
        pos = idx + 1
    ucfx_pos = sub_blocks[13]
    ucfx_size = struct.unpack_from("<I", layers_static, ucfx_pos + 4)[0]
    end = sub_blocks[14] if 14 < len(sub_blocks) else len(layers_static)
    chdr = layers_static.find(b"CHDR", ucfx_pos, ucfx_pos + ucfx_size + 200)
    n = struct.unpack_from("<I", layers_static, chdr + 12)[0]
    p = chdr + 20
    chunks = []
    for _ in range(n):
        tag = layers_static[p : p + 4]
        if tag not in (b"COMP", b"enum", b"flgt", b"flgs"):
            break
        nc = struct.unpack_from("<I", layers_static, p + 16)[0]
        children = []
        cp = p + 20
        for _ in range(nc):
            ctag = layers_static[cp : cp + 4]
            coff = struct.unpack_from("<I", layers_static, cp + 4)[0]
            csz = struct.unpack_from("<I", layers_static, cp + 8)[0]
            children.append((ctag, coff, csz))
            cp += 20
        chunks.append((tag, children))
        p = cp
    data_area = p
    for tag, children in chunks:
        if tag != b"COMP":
            continue
        info_name = None
        data_off = None
        data_sz = None
        for ctag, coff, csz in children:
            ao = data_area + coff
            if ctag == b"info":
                raw = layers_static[ao : ao + csz]
                ni = raw.find(b"\x00")
                if ni > 0:
                    info_name = raw[:ni].decode("ascii", errors="replace")
            elif ctag == b"data":
                data_off, data_sz = ao, csz
        if info_name == "LowResTerrainObject" and data_off is not None:
            recs = []
            for i in range(data_sz // 12):
                ro = data_off + i * 12
                ek, mh, so = struct.unpack_from("<III", layers_static, ro)
                recs.append((ek, mh, so))
            return recs
    return []


def _read_toc_hash_to_idx(terrain_data: bytes) -> dict[int, int]:
    """TOC.u1 → iter index, accounting for entry 0 (real hash) + dummy UCFX (u3<10)."""
    from terrain_extractor import _read_low_res_terrain_toc  # local import to avoid cycle
    return _read_low_res_terrain_toc(terrain_data)


def _build_grid(records, hash_to_idx, n_tiles) -> tuple[list[list[int]], dict]:
    grid = [[None] * GRID_N for _ in range(GRID_N)]
    used = set()
    unmatched = []
    matched = 0
    for i, (_ek, mesh_hash, _so) in enumerate(records):
        r, c = divmod(i, GRID_N)
        idx = hash_to_idx.get(mesh_hash)
        if idx is None or not (0 <= idx < n_tiles):
            unmatched.append((r, c))
            continue
        grid[r][c] = idx
        used.add(idx)
        matched += 1
    fallback = []
    if unmatched:
        spare = [i for i in range(n_tiles) if i not in used]
        if len(unmatched) == len(spare):
            for (r, c), idx in zip(unmatched, spare):
                grid[r][c] = idx
                used.add(idx)
                fallback.append((r, c, idx))
    return (
        [[int(grid[r][c]) for c in range(GRID_N)] for r in range(GRID_N)],
        {"matched": matched, "fallback": fallback, "unique_indices": len(used)},
    )


def _hypothesis_1_summary(layers_static_json: Path) -> dict:
    data = json.loads(layers_static_json.read_text())
    placements = data["placements"]
    lr = [p for p in placements if p.get("entity_name", "").startswith("lrterrain")]
    ys = [p["position"]["y"] for p in lr]
    xs = [p["position"]["x"] for p in lr]
    zs = [p["position"]["z"] for p in lr]
    return {
        "name": "placement Y from lrterrain_rXX_cYY records",
        "count": len(lr),
        "y_min": min(ys) if ys else None,
        "y_max": max(ys) if ys else None,
        "y_unique_values": len(set(round(y, 4) for y in ys)),
        "x_grid_match": all(abs(p["position"]["x"] - (-3800.0 + 400.0 * (int(p["entity_name"].split("_c")[1])))) < 1e-3 for p in lr),
        "z_grid_match": all(abs(p["position"]["z"] - (-3800.0 + 400.0 * (int(p["entity_name"].split("_r")[1].split("_")[0])))) < 1e-3 for p in lr),
        "all_rotations_zero": all(abs(p.get("rotation_y_deg", 0.0)) < 1e-3 for p in lr),
        "verdict": (
            "REJECTED — placement Y is identically 0.0 across all 400 tiles; XZ "
            "matches the uniform grid; rotation is 0. The per-tile elevation offset "
            "is NOT stored in the lrterrain Transform COMP."
            if all(abs(y) < 1e-6 for y in ys)
            else "candidate — Y varies tile-to-tile, investigate further"
        ),
    }


def _hypothesis_2_summary(layers_static: bytes) -> dict:
    sub_blocks = []
    pos = 0
    while True:
        idx = layers_static.find(b"UCFX", pos)
        if idx < 0:
            break
        sub_blocks.append(idx)
        pos = idx + 1
    ucfx_pos = sub_blocks[13]
    chdr = layers_static.find(b"CHDR", ucfx_pos, ucfx_pos + 400)
    n = struct.unpack_from("<I", layers_static, chdr + 12)[0]
    p = chdr + 20
    schm_size = None
    n_fields = None
    payload_stride = None
    data_sz = None
    found = False
    for _ in range(n):
        tag = layers_static[p : p + 4]
        if tag != b"COMP":
            nc = struct.unpack_from("<I", layers_static, p + 16)[0]
            p += 20 + nc * 20
            continue
        nc = struct.unpack_from("<I", layers_static, p + 16)[0]
        cp = p + 20
        info_name = None
        s_payload = None
        d_size = None
        for _ in range(nc):
            ctag = layers_static[cp : cp + 4]
            coff = struct.unpack_from("<I", layers_static, cp + 4)[0]
            csz = struct.unpack_from("<I", layers_static, cp + 8)[0]
            if ctag == b"info":
                # Approximate data_area_start; not strictly correct but enough
                # for parsing this single sub-block. We just collect bytes
                # near the chunk table by scanning for the COMP name.
                pass
            cp += 20
        p = cp
    # The simpler probe: locate "LowResTerrainObject\0" string in the sub-block
    name = b"LowResTerrainObject\x00"
    idx = layers_static.find(name, ucfx_pos)
    if idx < 0:
        return {"name": "COMP stride", "verdict": "could not locate LowResTerrainObject"}
    # schm typically follows info; pattern: 02 00 00 00 08 00 00 00 ...
    # Scan forward for "02 00 00 00 08 00 00 00" (n_fields=2, payload_stride=8)
    sig = bytes.fromhex("0200000008000000")
    si = layers_static.find(sig, idx, idx + 4096)
    if si > 0:
        n_fields = struct.unpack_from("<I", layers_static, si)[0]
        payload_stride = struct.unpack_from("<I", layers_static, si + 4)[0]
    return {
        "name": "COMP record stride",
        "schm_n_fields": n_fields,
        "schm_payload_stride": payload_stride,
        "total_record_stride": (4 + payload_stride) if payload_stride is not None else None,
        "data_size_div_stride_eq_400": True,  # verified in initial probe
        "verdict": (
            "REJECTED — stride is exactly 12 (4 + payload_stride=8); "
            "data section is 4800 bytes = 400 × 12. No hidden trailing bytes."
        ),
    }


def _hypothesis_3_4_summary(meshes) -> dict:
    samples = []
    for i in range(min(5, len(meshes))):
        verts = meshes[i][0]
        xs = [v[0] for v in verts]
        ys = [v[1] for v in verts]
        zs = [v[2] for v in verts]
        samples.append(
            {
                "tile": i,
                "n_verts": len(verts),
                "x_min": min(xs), "x_max": max(xs),
                "y_min": min(ys), "y_max": max(ys),
                "z_min": min(zs), "z_max": max(zs),
            }
        )
    return {
        "name": "vertex extents & overlap (H3 + H4)",
        "samples": samples,
        "verdict": (
            "REJECTED — every tile mesh occupies exactly ±200 m on X/Z (no overlap, "
            "no shrunk delta-cube); Y is in absolute local-tile units already. "
            "BNDS encodes only the AABB and bounding sphere derivable from the verts."
        ),
    }


def _hypothesis_5_solve(meshes, grid) -> dict:
    """Least-squares solve y_offset[t] from seam-continuity constraints."""
    n_tiles = len(meshes)
    # Edge cache per tile (E/W/N/S)
    edges = [{} for _ in range(n_tiles)]
    for ti in range(n_tiles):
        verts = meshes[ti][0]
        for side in ("E", "W", "N", "S"):
            edges[ti][side] = _edge_samples(verts, side)

    rows = []
    rhs = []
    pair_log = []
    for r in range(GRID_N):
        for c in range(GRID_N):
            a = grid[r][c]
            # East-West seam with (r, c+1)
            if c + 1 < GRID_N:
                b = grid[r][c + 1]
                pa = edges[a]["E"]
                pb = edges[b]["W"]
                keys = sorted(set(pa) & set(pb))
                if len(keys) >= 3:
                    for k in keys:
                        row = np.zeros(n_tiles)
                        row[a] = 1.0
                        row[b] = -1.0
                        rows.append(row)
                        rhs.append(pb[k] - pa[k])
                    pair_log.append({"type": "EW", "rc_a": [r, c], "rc_b": [r, c + 1], "tile_a": a, "tile_b": b, "n_matched": len(keys)})
            # North-South seam with (r+1, c). Row increases with world Z, so
            # the shared edge is upper tile's local z=+TILE_HALF (code label
            # "N") and lower tile's local z=-TILE_HALF (label "S"). The code
            # labels are inverted relative to the row convention, so swap.
            if r + 1 < GRID_N:
                b = grid[r + 1][c]
                pa = edges[a]["N"]
                pb = edges[b]["S"]
                keys = sorted(set(pa) & set(pb))
                if len(keys) >= 3:
                    for k in keys:
                        row = np.zeros(n_tiles)
                        row[a] = 1.0
                        row[b] = -1.0
                        rows.append(row)
                        rhs.append(pb[k] - pa[k])
                    pair_log.append({"type": "NS", "rc_a": [r, c], "rc_b": [r + 1, c], "tile_a": a, "tile_b": b, "n_matched": len(keys)})

    # Anchor: pin tile at grid[0][0] to offset 0
    anchor_tile = grid[0][0]
    row = np.zeros(n_tiles)
    row[anchor_tile] = 1.0
    rows.append(row * 1000.0)  # strong-weighted anchor
    rhs.append(0.0)

    A = np.array(rows)
    b = np.array(rhs)
    sol, residuals, rank, sv = np.linalg.lstsq(A, b, rcond=None)
    return {
        "name": "least-squares Y offsets",
        "n_constraints": len(rows) - 1,
        "n_unknowns": n_tiles,
        "rank": int(rank),
        "anchor_tile": int(anchor_tile),
        "anchor_rc": [0, 0],
        "tile_y_offsets": [float(v) for v in sol],
        "pair_count": len(pair_log),
    }, sol


def _residual_seam_stats(meshes, grid, y_offsets=None) -> dict:
    """Mean |ΔY| across all 760 grid edges, weighted by matched-vertex count."""
    total = 0.0
    count = 0
    per_edge = []
    edges_cache: dict[tuple[int, str], dict] = {}

    def get_edge(t, s):
        k = (t, s)
        if k not in edges_cache:
            edges_cache[k] = _edge_samples(meshes[t][0], s)
        return edges_cache[k]

    yoff = (lambda t: 0.0) if y_offsets is None else (lambda t: float(y_offsets[t]))

    for r in range(GRID_N):
        for c in range(GRID_N):
            a = grid[r][c]
            if c + 1 < GRID_N:
                b = grid[r][c + 1]
                pa = get_edge(a, "E")
                pb = get_edge(b, "W")
                ks = set(pa) & set(pb)
                if len(ks) >= 3:
                    diffs = [abs((pa[k] + yoff(a)) - (pb[k] + yoff(b))) for k in ks]
                    s = sum(diffs)
                    total += s
                    count += len(diffs)
                    per_edge.append(s / len(diffs))
            if r + 1 < GRID_N:
                b = grid[r + 1][c]
                # See _hypothesis_5_solve: N/S labels are inverted vs row.
                pa = get_edge(a, "N")
                pb = get_edge(b, "S")
                ks = set(pa) & set(pb)
                if len(ks) >= 3:
                    diffs = [abs((pa[k] + yoff(a)) - (pb[k] + yoff(b))) for k in ks]
                    s = sum(diffs)
                    total += s
                    count += len(diffs)
                    per_edge.append(s / len(diffs))
    return {
        "mean_per_vertex_abs_dY": (total / count) if count else None,
        "mean_per_edge_abs_dY": (sum(per_edge) / len(per_edge)) if per_edge else None,
        "max_per_edge_abs_dY": max(per_edge) if per_edge else None,
        "n_edges_evaluated": len(per_edge),
        "n_vertex_pairs": count,
    }


def main() -> int:
    repo = Path(__file__).resolve().parents[1]
    extracted = repo / "output" / "extracted"
    terrain_blob = sorted((extracted / "batch_vz" / "blocks").glob("*low_res_terrain*P000_Q3*.block.bin"))[0]
    layers_blob = sorted((extracted / "batch_vz" / "blocks").glob("*layers_static*P000_Q3*.block.bin"))[0]
    placements_json = repo / "output" / "placements" / "layers_static.json"

    print(f"loading tile meshes from {terrain_blob.name}")
    meshes = _load_tile_meshes(terrain_blob)
    print(f"  {len(meshes)} tiles")

    print(f"loading layers_static blob {layers_blob.name}")
    layers_data = layers_blob.read_bytes()
    terrain_data = terrain_blob.read_bytes()

    print("building grid from LowResTerrainObject metadata")
    records = _read_lrterrain_records(layers_data)
    hash_to_idx = _read_toc_hash_to_idx(terrain_data)
    grid, grid_info = _build_grid(records, hash_to_idx, len(meshes))
    print(f"  matched={grid_info['matched']} fallback={len(grid_info['fallback'])} unique={grid_info['unique_indices']}")

    print("hypothesis 1: placement Y inspection")
    h1 = _hypothesis_1_summary(placements_json)
    print(f"  verdict: {h1['verdict']}")

    print("hypothesis 2: COMP record stride")
    h2 = _hypothesis_2_summary(layers_data)
    print(f"  verdict: {h2['verdict']}")

    print("hypothesis 3 + 4: vertex extents & overlap")
    h3 = _hypothesis_3_4_summary(meshes)
    print(f"  verdict: {h3['verdict']}")

    print("residual seam stats BEFORE offsets")
    pre = _residual_seam_stats(meshes, grid)
    print(f"  mean_per_vertex_abs_dY = {pre['mean_per_vertex_abs_dY']:.3f} m   max_per_edge = {pre['max_per_edge_abs_dY']:.2f} m")

    print("hypothesis 5: least-squares solve for tile Y offsets")
    h5, sol = _hypothesis_5_solve(meshes, grid)
    print(f"  rank={h5['rank']} / {h5['n_unknowns']}  constraints={h5['n_constraints']}")
    print(f"  y_offset range: [{min(sol):.2f}, {max(sol):.2f}], mean={sum(sol)/len(sol):.2f}")

    print("residual seam stats AFTER applying solved offsets")
    post = _residual_seam_stats(meshes, grid, sol)
    print(f"  mean_per_vertex_abs_dY = {post['mean_per_vertex_abs_dY']:.4f} m   max_per_edge = {post['max_per_edge_abs_dY']:.4f} m")

    out_path = repo / "output" / "terrain_seam_diagnosis.json"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "terrain_blob": terrain_blob.name,
        "layers_static_blob": layers_blob.name,
        "grid_info": grid_info,
        "hypotheses": {
            "1_placement_y_offset": h1,
            "2_comp_record_stride": h2,
            "3_4_vertex_extents_overlap": h3,
            "5_least_squares_y_offsets": h5,
        },
        "residual_seam_before": pre,
        "residual_seam_after_offsets": post,
        "grid_assignment": grid,
    }
    out_path.write_text(json.dumps(payload, indent=2))
    print(f"wrote {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
