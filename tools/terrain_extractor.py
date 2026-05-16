#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Extract merged world terrain from ``low_res_terrain_P000_Q3`` UCFX block.

The retail block packs **~400 UCFX sub-containers** (one terrain tile each) with
``GEOM → BNDS + PRMT + STRM + IBUF`` — no ``PRMG`` rows — so :func:`mesh_extractor`
structured extraction yields nothing and the fallback mis-decodes stride.

This tool reuses :func:`ucfx_mesh_codec._parse_prmg_body` on each GEOM child slice
(which matches the flat ``STRM``/``IBUF`` layout) and :func:`decode_submesh` for
vertices + triangle strips, then merges all tiles via :func:`merge_submeshes`.

Outputs a review-style folder with ``submeshes/*.obj`` + ``mesh_scene.glb`` via
:func:`gltf_exporter.export_review_to_gltf`.
"""
from __future__ import annotations

import argparse
import json
import re
import struct
import sys
from pathlib import Path

_REPO_TOOLS = Path(__file__).resolve().parent
if str(_REPO_TOOLS) not in sys.path:
    sys.path.insert(0, str(_REPO_TOOLS))

from gltf_exporter import export_review_to_gltf  # noqa: E402
from ucfx_mesh_codec import (  # noqa: E402
    _iter_geom_child_row_slices,
    _parse_prmg_body,
    decode_submesh,
    iter_ucfx_containers,
    merge_submeshes,
)

_DEFAULT_BLOCK_GLOB = "*low_res_terrain*P000_Q3*.block.bin"
_DEFAULT_LAYERS_STATIC_GLOB = "*layers_static*P000_Q3*.block.bin"

# Verified from layers_static lrterrain_rXX_cYY placements (20×20 grid, 400 m tiles).
_LOW_RES_TERRAIN_GRID = 20
_LOW_RES_TERRAIN_TILE_SPAN_M = 400.0
_LOW_RES_TERRAIN_ORIGIN_M = -3800.0
# Each tile mesh is authored in local space roughly [-200, 200] on X/Z (tile center at origin).
_TILE_LOCAL_HALF_SPAN_M = 200.0
# World extent for planar UV projection of the master vz_lrterrain texture.
# Verified from layers_static placements: tile centers at -3800..3800 in 400 m steps,
# tile-local extent ±200 m → world spans [-4000, 4000] on X and Z (8000 m square).
_WORLD_MIN_M = -4000.0
_WORLD_SPAN_M = 8000.0
# Master texture (block-local sidecar) — see docs/format_reference.md §13.4.
_MASTER_TEXTURE_BASENAME = "vz_lrterrain"
# When True, V is flipped (v = 1 - v_world). Off by default; set via convention JSON
# / validation step. See output/terrain_uv_convention.json.
_TEXTURE_V_FLIP = False
# Edge samples within this distance (m) of ±200 local X/Z for seam matching.
# Source vertices land dead-on ±200 (verified); 0.5 m tolerance prevents
# near-edge interior vertices from polluting the per-edge bucket profile.
_TILE_EDGE_TOL_M = 0.5
# layers_static sub-block index that holds the LowResTerrainObject COMP for the 400 lrterrain
# entities. Verified for the retail Mercenaries 2 PC build (00029_blocks__VZ__layers_static_P000_Q3).
_LRTERRAIN_SUB_BLOCK_INDEX = 13

TileMesh = tuple[list[tuple[float, float, float]], list[tuple[int, int, int]]]


def _read_low_res_terrain_toc(data: bytes) -> dict[int, int]:
    """Map ``TOC.hash1`` → file index (0..N-1) for the low_res_terrain block.

    The block starts with a TOC of ``count`` 16-byte entries. Entry 0 stores
    the count in its first u32 **but its second u32 is a valid mesh hash for
    a real tile** (verified empirically: cell (17, 9) in the retail PC build).

    Each entry ``j`` corresponds to a UCFX container at offset
    ``data_base + Σ sizes[1..j]`` where ``data_base`` is the first byte after
    the TOC area (aligned to 4). One entry (verified retail entry 224 for the
    PC build) holds a dummy ``UCFX`` with ``u3 = 3`` that
    :func:`iter_ucfx_containers` filters out (its ``u3 < 10`` threshold), so the
    file-iteration index for entries past the dummy is shifted by −1 relative
    to the TOC entry index. The mapping returned here is **TOC.u1 → iter
    index**, with the dummy entry's u1 omitted (it doesn't appear in any
    ``LowResTerrainObject`` record anyway).
    """
    if len(data) < 16:
        return {}
    n_entries = struct.unpack_from("<I", data, 0)[0]
    if n_entries < 2 or n_entries > 100_000 or len(data) < n_entries * 16:
        return {}
    toc_area_end = n_entries * 16
    data_base = data.find(b"UCFX", toc_area_end, toc_area_end + 64)
    if data_base < 0 or data_base >= len(data):
        return {}
    expected_off: list[int] = [data_base]
    for j in range(1, n_entries):
        sz = struct.unpack_from("<I", data, j * 16)[0]
        expected_off.append(expected_off[-1] + sz)
    out: dict[int, int] = {}
    iter_idx = 0
    for j in range(n_entries):
        off = expected_off[j]
        if off + 20 > len(data) or data[off : off + 4] != b"UCFX":
            continue
        u3 = struct.unpack_from("<I", data, off + 16)[0]
        if u3 < 10 or u3 > 50_000:
            continue
        h1 = struct.unpack_from("<I", data, j * 16 + 4)[0]
        out[h1] = iter_idx
        iter_idx += 1
    return out


def _read_lrterrain_object_records(layers_static: bytes) -> list[tuple[int, int, int]]:
    """Return the ordered list of ``LowResTerrainObject`` records.

    Reads ``layers_static`` sub-block ``_LRTERRAIN_SUB_BLOCK_INDEX``, finds the
    ``LowResTerrainObject`` COMP, and decodes its 12-byte records as a list
    in COMP order: ``(entity_key, mesh_hash, scene_object_id) × N``.

    The COMP records are authored in lrterrain row-major order (record i =
    ``lrterrain_r{i//20:02d}_c{i%20:02d}``), so the **list index** is the
    direct ``(row, col)`` mapping; the ``entity_key`` field is an opaque
    identifier whose numeric range overlaps with other entities in the
    sub-block and must not be used as a positional offset.

    Returns an empty list if the COMP is not found.
    """
    ucfx_positions: list[int] = []
    pos = 0
    while True:
        idx = layers_static.find(b"UCFX", pos)
        if idx < 0:
            break
        ucfx_positions.append(idx)
        pos = idx + 1
    if _LRTERRAIN_SUB_BLOCK_INDEX >= len(ucfx_positions):
        return {}

    ucfx_pos = ucfx_positions[_LRTERRAIN_SUB_BLOCK_INDEX]
    ucfx_size = struct.unpack_from("<I", layers_static, ucfx_pos + 4)[0]
    block_end = (
        ucfx_positions[_LRTERRAIN_SUB_BLOCK_INDEX + 1]
        if _LRTERRAIN_SUB_BLOCK_INDEX + 1 < len(ucfx_positions)
        else len(layers_static)
    )
    chdr_pos = layers_static.find(b"CHDR", ucfx_pos, ucfx_pos + ucfx_size + 200)
    if chdr_pos < 0:
        return {}
    chdr_entries = struct.unpack_from("<I", layers_static, chdr_pos + 12)[0]

    pos = chdr_pos + 20
    chunks: list[tuple[bytes, list[tuple[bytes, int, int]]]] = []
    for _ in range(chdr_entries):
        if pos + 20 > block_end:
            break
        tag = layers_static[pos : pos + 4]
        if tag not in (b"COMP", b"enum", b"flgt", b"flgs"):
            break
        num_children = struct.unpack_from("<I", layers_static, pos + 16)[0]
        children: list[tuple[bytes, int, int]] = []
        child_pos = pos + 20
        for _ in range(num_children):
            if child_pos + 20 > block_end:
                break
            ctag = layers_static[child_pos : child_pos + 4]
            coff = struct.unpack_from("<I", layers_static, child_pos + 4)[0]
            csz = struct.unpack_from("<I", layers_static, child_pos + 8)[0]
            children.append((ctag, coff, csz))
            child_pos += 20
        chunks.append((tag, children))
        pos = child_pos
    data_area_start = pos

    for tag, children in chunks:
        if tag != b"COMP":
            continue
        info_name: str | None = None
        data_child: tuple[int, int] | None = None
        for ctag, coff, csz in children:
            abs_off = data_area_start + coff
            if ctag == b"info" and abs_off + csz <= len(layers_static):
                raw = layers_static[abs_off : abs_off + csz]
                null_idx = raw.find(b"\x00")
                if null_idx > 0:
                    info_name = raw[:null_idx].decode("ascii", errors="replace")
            elif ctag == b"data":
                data_child = (abs_off, csz)
        if info_name == "LowResTerrainObject" and data_child is not None:
            off, size = data_child
            n_records = size // 12
            out: list[tuple[int, int, int]] = []
            for i in range(n_records):
                rec_off = off + i * 12
                if rec_off + 12 > len(layers_static):
                    break
                entity_key, mesh_hash, scene = struct.unpack_from("<III", layers_static, rec_off)
                out.append((entity_key, mesh_hash, scene))
            return out
    return []


def _build_metadata_grid_assignment(
    layers_static_blob: Path | None,
    terrain_data: bytes,
    n_tiles: int,
) -> tuple[list[list[int]] | None, dict[str, object]]:
    """Build a 20×20 (row, col) → file_idx grid using LowResTerrainObject metadata.

    Pipeline: ``layers_static.LowResTerrainObject[entity_key].mesh_hash``
    → ``low_res_terrain.TOC[i].hash1`` → file_idx (= UCFX iteration order).

    Returns ``(grid, info)``. ``grid`` is ``None`` when the mapping cannot be
    built (e.g. layers_static missing or sub-block layout differs); ``info``
    records counts and the per-entity match status for telemetry.
    """
    info: dict[str, object] = {
        "source": "metadata_lookup",
        "layers_static_blob": str(layers_static_blob) if layers_static_blob else None,
        "comp_name": "LowResTerrainObject",
        "sub_block_index": _LRTERRAIN_SUB_BLOCK_INDEX,
    }
    if layers_static_blob is None or not layers_static_blob.is_file():
        info["status"] = "layers_static_missing"
        return None, info
    layers_static = layers_static_blob.read_bytes()
    records = _read_lrterrain_object_records(layers_static)
    if not records:
        info["status"] = "comp_not_found"
        return None, info
    hash_to_idx = _read_low_res_terrain_toc(terrain_data)
    if not hash_to_idx:
        info["status"] = "toc_unreadable"
        return None, info

    grid_n = _LOW_RES_TERRAIN_GRID
    if len(records) != grid_n * grid_n:
        info["status"] = f"unexpected_record_count_{len(records)}"
        return None, info

    grid: list[list[int | None]] = [[None] * grid_n for _ in range(grid_n)]
    matched = 0
    fallback = 0
    used: set[int] = set()
    unmatched_cells: list[tuple[int, int]] = []
    for i, (_ek, mesh_hash, _scene) in enumerate(records):
        r, c = divmod(i, grid_n)
        idx = hash_to_idx.get(mesh_hash)
        if idx is None or not (0 <= idx < n_tiles):
            unmatched_cells.append((r, c))
            continue
        grid[r][c] = idx
        used.add(idx)
        matched += 1

    if unmatched_cells:
        spare = [i for i in range(n_tiles) if i not in used]
        if len(unmatched_cells) == len(spare):
            for (r, c), idx in zip(unmatched_cells, spare):
                grid[r][c] = idx
                used.add(idx)
                fallback += 1

    missing = [(r, c) for r in range(grid_n) for c in range(grid_n) if grid[r][c] is None]
    info["matched"] = matched
    info["fallback_filled"] = fallback
    info["missing_cells"] = missing
    info["unique_indices"] = len(used)
    info["base_entity_key"] = f"0x{records[0][0]:08x}"
    if missing:
        info["status"] = "incomplete_grid"
        return None, info
    info["status"] = "ok"
    return [[int(grid[r][c]) for c in range(grid_n)] for r in range(grid_n)], info


def _find_layers_static_blob(extracted_root: Path) -> Path | None:
    blocks = extracted_root / "batch_vz" / "blocks"
    if not blocks.is_dir():
        return None
    matches = sorted(blocks.glob(_DEFAULT_LAYERS_STATIC_GLOB))
    return matches[0] if matches else None


def _find_low_res_blob(extracted_root: Path, explicit: Path | None) -> Path:
    if explicit is not None:
        p = explicit.resolve()
        if not p.is_file():
            raise FileNotFoundError(str(p))
        return p
    blocks = extracted_root / "batch_vz" / "blocks"
    if not blocks.is_dir():
        raise FileNotFoundError(f"expected batch_vz blocks dir: {blocks}")
    matches = sorted(blocks.glob(_DEFAULT_BLOCK_GLOB))
    if not matches:
        raise FileNotFoundError(
            f"no file matching {_DEFAULT_BLOCK_GLOB!r} under {blocks} "
            "(pass --blob explicitly)"
        )
    if len(matches) > 1:
        print(f"warning: multiple low_res_terrain blobs, using {matches[0].name}", file=sys.stderr)
    return matches[0]


def _default_review_dir(extracted_root: Path, blob: Path) -> Path:
    """Mirror stage-2 layout: ``<extracted>/review/batch_vz/<stem>/``."""
    stem = blob.name.replace(".bin", "")
    return extracted_root / "review" / "batch_vz" / stem


def _tile_world_center_rc(row: int, col: int) -> tuple[float, float]:
    """World X/Z center for ``lrterrain_r{row:02d}_c{col:02d}`` (placement grid)."""
    center_x = _LOW_RES_TERRAIN_ORIGIN_M + col * _LOW_RES_TERRAIN_TILE_SPAN_M
    center_z = _LOW_RES_TERRAIN_ORIGIN_M + row * _LOW_RES_TERRAIN_TILE_SPAN_M
    return center_x, center_z


def _edge_height_profile(
    verts: list[tuple[float, float, float]],
    side: str,
) -> dict[float, float]:
    """Mean elevation (game Y) along a tile edge, keyed by along-edge coordinate."""
    edge = _TILE_LOCAL_HALF_SPAN_M
    tol = _TILE_EDGE_TOL_M
    if side == "E":
        pts = [(z, y) for x, y, z in verts if x >= edge - tol]
    elif side == "W":
        pts = [(z, y) for x, y, z in verts if x <= -edge + tol]
    elif side == "N":
        pts = [(x, y) for x, y, z in verts if z >= edge - tol]
    else:
        pts = [(x, y) for x, y, z in verts if z <= -edge + tol]
    buckets: dict[float, list[float]] = {}
    for along, y in pts:
        key = round(along, 0)
        buckets.setdefault(key, []).append(y)
    return {key: sum(vals) / len(vals) for key, vals in buckets.items()}


def _seam_mismatch_m(
    verts_a: list[tuple[float, float, float]],
    side_a: str,
    verts_b: list[tuple[float, float, float]],
    side_b: str,
) -> float:
    """Average |ΔY| between shared edge samples on two adjacent tiles (lower is better)."""
    prof_a = _edge_height_profile(verts_a, side_a)
    prof_b = _edge_height_profile(verts_b, side_b)
    keys = set(prof_a) & set(prof_b)
    if len(keys) < 5:
        return 1e9
    return sum(abs(prof_a[k] - prof_b[k]) for k in keys) / len(keys)


def _greedy_tile_grid_assignment(
    meshes: list[TileMesh],
    seed_mesh: int,
) -> list[list[int]]:
    """Assign each grid (row, col) a mesh index by growing a seam-consistent 20×20 map."""
    grid_n = _LOW_RES_TERRAIN_GRID
    assign: list[list[int | None]] = [[None] * grid_n for _ in range(grid_n)]
    used: set[int] = set()
    assign[0][0] = seed_mesh
    used.add(seed_mesh)

    for col in range(1, grid_n):
        prev = assign[0][col - 1]
        assert prev is not None
        best_idx = min(
            (i for i in range(len(meshes)) if i not in used),
            key=lambda i: _seam_mismatch_m(meshes[prev][0], "E", meshes[i][0], "W"),
        )
        assign[0][col] = best_idx
        used.add(best_idx)

    for row in range(1, grid_n):
        for col in range(grid_n):
            north = assign[row - 1][col]
            assert north is not None
            if col > 0:
                west = assign[row][col - 1]
                assert west is not None
                best_idx = min(
                    (i for i in range(len(meshes)) if i not in used),
                    key=lambda i: (
                        # north tile's world-south face (label "N") vs new
                        # tile's world-north face (label "S")
                        _seam_mismatch_m(meshes[north][0], "N", meshes[i][0], "S")
                        + _seam_mismatch_m(meshes[west][0], "E", meshes[i][0], "W")
                    )
                    / 2.0,
                )
            else:
                best_idx = min(
                    (i for i in range(len(meshes)) if i not in used),
                    key=lambda i: _seam_mismatch_m(meshes[north][0], "N", meshes[i][0], "S"),
                )
            assign[row][col] = best_idx
            used.add(best_idx)

    return [[int(assign[r][c]) for c in range(grid_n)] for r in range(grid_n)]


def _max_grid_seam_m(
    meshes: list[TileMesh],
    assign: list[list[int]],
) -> float:
    """Max edge mismatch across the grid (sub-meter on the retail tile set)."""
    grid_n = _LOW_RES_TERRAIN_GRID
    worst = 0.0
    for row in range(grid_n):
        for col in range(grid_n):
            mesh_idx = assign[row][col]
            verts = meshes[mesh_idx][0]
            if col + 1 < grid_n:
                nxt = assign[row][col + 1]
                cost = _seam_mismatch_m(verts, "E", meshes[nxt][0], "W")
                if cost < 1e8 and cost > worst:
                    worst = cost
            if row + 1 < grid_n:
                nxt = assign[row + 1][col]
                cost = _seam_mismatch_m(verts, "N", meshes[nxt][0], "S")
                if cost < 1e8 and cost > worst:
                    worst = cost
    return worst


def _mean_grid_seam_m(
    meshes: list[TileMesh],
    assign: list[list[int]],
) -> float:
    """Mean edge mismatch for a full grid assignment (finite seams only)."""
    grid_n = _LOW_RES_TERRAIN_GRID
    total = 0.0
    count = 0
    for row in range(grid_n):
        for col in range(grid_n):
            mesh_idx = assign[row][col]
            verts = meshes[mesh_idx][0]
            if col + 1 < grid_n:
                nxt = assign[row][col + 1]
                cost = _seam_mismatch_m(verts, "E", meshes[nxt][0], "W")
                if cost < 1e8:
                    total += cost
                    count += 1
            if row + 1 < grid_n:
                nxt = assign[row + 1][col]
                # Row increases with world Z. Shared boundary between (r, c)
                # and (r+1, c) is upper tile's world-south face (local
                # z=+TILE_HALF, code label "N") and lower tile's world-north
                # face (local z=-TILE_HALF, label "S"). The code's N/S labels
                # are inverted vs the row convention, so cross them.
                cost = _seam_mismatch_m(verts, "N", meshes[nxt][0], "S")
                if cost < 1e8:
                    total += cost
                    count += 1
    return total / count if count else 1e9


def _compute_tile_grid_assignment(meshes: list[TileMesh]) -> list[list[int]]:
    """Map ``lrterrain`` grid (row, col) → mesh index in UCFX file order.

    UCFX sub-container enumeration order does **not** match ``lrterrain_rXX_cYY``
    row-major naming (397/400 cells differ). Grow a 20×20 map by matching east/west
    and north/south edges between tiles; try several seeds and keep the best seam score.
    """
    if len(meshes) != _LOW_RES_TERRAIN_GRID * _LOW_RES_TERRAIN_GRID:
        raise ValueError(f"expected {_LOW_RES_TERRAIN_GRID ** 2} tiles, got {len(meshes)}")

    last = len(meshes) - 1
    row_end = _LOW_RES_TERRAIN_GRID - 1
    seed_candidates = [0, row_end, last - row_end, last, len(meshes) // 2]
    best_assign = _greedy_tile_grid_assignment(meshes, 0)
    best_score = _mean_grid_seam_m(meshes, best_assign)
    for seed in seed_candidates[1:]:
        candidate = _greedy_tile_grid_assignment(meshes, seed)
        score = _mean_grid_seam_m(meshes, candidate)
        if score < best_score:
            best_score = score
            best_assign = candidate
    return best_assign


def _offset_verts_to_world(
    verts: list[tuple[float, float, float]],
    center_x: float,
    center_z: float,
) -> list[tuple[float, float, float]]:
    return [(x + center_x, y, z + center_z) for x, y, z in verts]


def _bounds_xyz(
    verts: list[tuple[float, float, float]],
) -> dict[str, float]:
    xs = [v[0] for v in verts]
    ys = [v[1] for v in verts]
    zs = [v[2] for v in verts]
    return {
        "min_x": min(xs),
        "max_x": max(xs),
        "min_y": min(ys),
        "max_y": max(ys),
        "min_z": min(zs),
        "max_z": max(zs),
    }


def _world_xz_to_uv(
    x: float,
    z: float,
    *,
    flip_v: bool = _TEXTURE_V_FLIP,
) -> tuple[float, float]:
    """Project world XZ → master-texture UV (planar, full-continent)."""
    u = (x - _WORLD_MIN_M) / _WORLD_SPAN_M
    v = (z - _WORLD_MIN_M) / _WORLD_SPAN_M
    if flip_v:
        v = 1.0 - v
    # Tiny epsilon clamp keeps GPU samplers off the seam at exact 0/1.
    if u < 0.0:
        u = 0.0
    elif u > 1.0:
        u = 1.0
    if v < 0.0:
        v = 0.0
    elif v > 1.0:
        v = 1.0
    return u, v


def _write_obj(
    path: Path,
    verts: list[tuple[float, float, float]],
    faces: list[tuple[int, int, int]],
    uvs: list[tuple[float, float]] | None = None,
) -> None:
    lines = ["# Mercenaries 2 — merged low_res_terrain", "o terrain", ""]
    for x, y, z in verts:
        lines.append(f"v {x:.6g} {y:.6g} {z:.6g}")
    lines.append("")
    if uvs is not None:
        if len(uvs) != len(verts):
            raise ValueError(
                f"uvs length ({len(uvs)}) must match verts length ({len(verts)})"
            )
        for u, v in uvs:
            lines.append(f"vt {u:.6f} {v:.6f}")
        lines.append("")
        for a, b, c in faces:
            lines.append(
                f"f {a + 1}/{a + 1} {b + 1}/{b + 1} {c + 1}/{c + 1}"
            )
    else:
        for a, b, c in faces:
            lines.append(f"f {a + 1} {b + 1} {c + 1}")
    lines.append("")
    path.write_text("\n".join(lines), encoding="utf-8")


def _classify_texture_role(name: str | None, channel_stats: dict[str, float] | None = None) -> str:
    """Infer texture role from name suffix or channel statistics.

    Naming conventions in the retail M2 wad:
      ``*_n``, ``*_normal`` → normal map
      ``*_s``, ``*_spec``, ``*_gloss`` → specular / gloss
      ``*_h``, ``*_height`` → height / displacement
      ``*_ao`` → ambient occlusion
      ``*_em``, ``*_emissive`` → emissive
      anything else with no suffix → diffuse/baseColor
    Channel-stat fallback is used when the name is opaque.
    """
    if name:
        low = name.lower()
        for suffix, role in (
            ("_normal", "normal"),
            ("_n", "normal"),
            ("_spec", "specular"),
            ("_s", "specular"),
            ("_gloss", "gloss"),
            ("_height", "height"),
            ("_h", "height"),
            ("_ao", "occlusion"),
            ("_em", "emissive"),
            ("_emissive", "emissive"),
        ):
            if low.endswith(suffix):
                return role
    if channel_stats:
        # Normal: B-channel mean ≈ 255 (encoded Z is mostly +1).
        b_mean = channel_stats.get("b_mean", 0.0)
        sat = channel_stats.get("saturation", 1.0)
        if b_mean > 200 and channel_stats.get("r_mean", 0) > 100 and channel_stats.get("g_mean", 0) > 100:
            return "normal"
        if sat < 0.05:
            # Near-grayscale → specular / occlusion / height
            return "specular_or_grayscale"
    return "diffuse"


def _update_terrain_manifest(manifest_path: Path, aux_scan: dict[str, object]) -> None:
    """Annotate the textures manifest with discovered roles and TOC scan results.

    Preserves whatever fields were already in ``manifest.json`` (the existing
    pipeline writes ``textures`` with offset/width/height/fourcc/etc.) and
    augments each entry with an ``inferred_role`` and ``role_source``. Adds a
    sibling ``aux_scan`` block recording the TOC walk findings.
    """
    if not manifest_path.is_file():
        return
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return
    textures = manifest.get("textures") if isinstance(manifest, dict) else None
    if isinstance(textures, list):
        for tex in textures:
            if not isinstance(tex, dict):
                continue
            name = tex.get("name") or Path(str(tex.get("file", ""))).stem
            role = _classify_texture_role(name)
            tex["inferred_role"] = role
            tex["role_source"] = "name_suffix" if role != "diffuse" else "name_suffix_or_default"
            if name == _MASTER_TEXTURE_BASENAME:
                tex["inferred_role"] = "diffuse"
                tex["role_source"] = "canonical_master_texture"
                tex["channel_assignment"] = {
                    "baseColor": "RGB",
                    "alpha": "unused (DXT1)",
                }
    manifest["aux_scan"] = {
        "block_size": aux_scan.get("block_size"),
        "mesh_count": aux_scan.get("mesh_count"),
        "dummy_count": aux_scan.get("dummy_count"),
        "named_entries_count": len(aux_scan.get("named_entries", [])),
        "aux_entries_count": len(aux_scan.get("aux_entries", [])),
        "signature_scan": aux_scan.get("signature_scan"),
        "named_entries": [
            {
                "toc_idx": e.get("toc_idx"),
                "name": e.get("name"),
                "size": e.get("size"),
                "offset": e.get("offset"),
                "dxt_signatures": list(e.get("dxt_offsets", {}).keys()),
            }
            for e in aux_scan.get("named_entries", [])
        ],
        "aux_entries": [
            {
                "toc_idx": e.get("toc_idx"),
                "name": e.get("name"),
                "size": e.get("size"),
                "offset": e.get("offset"),
                "dxt_signatures": list(e.get("dxt_offsets", {}).keys()),
                "inferred_role": _classify_texture_role(e.get("name")),
            }
            for e in aux_scan.get("aux_entries", [])
        ],
        "conclusion": (
            "low_res_terrain block ships only the diffuse atlas; "
            "no normal/specular/AO sidecar textures are embedded in this block. "
            "Higher-LOD per-cell terrain (vz_terrainglobal_r##_c##) lives in "
            "separate c30NNN cell blocks and is out of scope for the merged low-LOD bake."
            if not aux_scan.get("aux_entries")
            else f"discovered {len(aux_scan.get('aux_entries', []))} aux texture entries"
        ),
    }
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")


def _walk_terrain_toc_aux_textures(data: bytes) -> dict[str, object]:
    """Walk the low_res_terrain TOC for non-mesh non-dummy texture entries.

    For the retail PC build this block ships **exactly one** texture
    (``vz_lrterrain``, DXT1 2048², at TOC entry 224). We still walk the full
    TOC for forward-compat — additional aux textures (normal/spec/AO/height)
    would appear as entries with a NAME chunk and a DXT/BC* signature in the
    payload, distinct from the mesh tiles (which carry GEOM/STRM/IBUF/MTRL).

    Returns a dict with ``aux_entries`` (list of {toc_idx, offset, size,
    chunks, dxt_at_offsets, name}), ``mesh_count``, ``dummy_count``, and
    ``signature_scan`` (file-wide DXT/BC magic counts).
    """
    out: dict[str, object] = {
        "block_size": len(data),
        "aux_entries": [],
        "named_entries": [],
    }
    if len(data) < 16:
        return out
    n_entries = struct.unpack_from("<I", data, 0)[0]
    if n_entries < 2 or n_entries > 100_000:
        out["error"] = f"unreasonable n_entries={n_entries}"
        return out
    toc_area_end = n_entries * 16
    data_base = data.find(b"UCFX", toc_area_end, toc_area_end + 64)
    if data_base < 0:
        out["error"] = "no_data_base"
        return out
    expected_off = [data_base]
    for j in range(1, n_entries):
        sz = struct.unpack_from("<I", data, j * 16)[0]
        expected_off.append(expected_off[-1] + sz)

    # File-wide signature scan (cheap; bounds the aux-texture search space).
    sig_counts: dict[str, int] = {}
    for needle in (b"DDS ", b"DXT1", b"DXT3", b"DXT5", b"DX10", b"BC4 ", b"BC5 "):
        p = 0
        cnt = 0
        while True:
            idx = data.find(needle, p)
            if idx < 0:
                break
            cnt += 1
            p = idx + 4
        sig_counts[needle.decode("ascii", errors="replace").strip()] = cnt
    out["signature_scan"] = sig_counts

    mesh_count = 0
    dummy_count = 0
    aux_entries: list[dict[str, object]] = []
    named_entries: list[dict[str, object]] = []
    for j in range(n_entries):
        off = expected_off[j]
        sz = struct.unpack_from("<I", data, j * 16)[0]
        if off + 20 > len(data):
            continue
        if data[off : off + 4] != b"UCFX":
            continue
        u3 = struct.unpack_from("<I", data, off + 16)[0]
        body_end = min(off + sz, len(data))
        # Detect texture-bearing entries: NAME chunk + DXT/BC magic in body.
        name_at = data.find(b"NAME", off, body_end)
        dxt_offsets: dict[str, list[int]] = {}
        for needle in (b"DXT1", b"DXT3", b"DXT5", b"DX10", b"BC4 ", b"BC5 ", b"DDS "):
            p = off
            hits = []
            while True:
                idx = data.find(needle, p, body_end)
                if idx < 0:
                    break
                hits.append(idx - off)
                p = idx + 4
            if hits:
                dxt_offsets[needle.decode("ascii", errors="replace").strip()] = hits
        is_mesh = u3 >= 10 and u3 <= 50_000 and not dxt_offsets
        if is_mesh:
            mesh_count += 1
            continue
        # Anything else is interesting — a dummy, an aux container, or a texture.
        is_texture_like = bool(dxt_offsets) or name_at >= 0
        ent_name: str | None = None
        if name_at >= 0:
            # NAME chunk payload contains routing prefixes (e.g. "BODY/") and
            # the real texture name as separate null-terminated ASCII runs. The
            # longest run is the canonical name (verified: retail entry holds
            # "BODY/" + "vz_lrterrain"). Skip well-known routing prefixes.
            payload = data[name_at + 12 : min(name_at + 1024, body_end)]
            best = ""
            for piece in payload.split(b"\x00"):
                if len(piece) < 3:
                    continue
                if not all(0x20 <= b < 0x7F for b in piece[:64]):
                    continue
                s = piece.decode("ascii", errors="replace")
                if s in ("BODY/", "INFO", "DATA", "NAME"):
                    continue
                if len(s) > len(best):
                    best = s
            ent_name = best or None
        rec: dict[str, object] = {
            "toc_idx": j,
            "offset": off,
            "size": sz,
            "u3": u3,
            "name": ent_name,
            "dxt_offsets": dxt_offsets,
        }
        if is_texture_like:
            named_entries.append(rec)
        else:
            dummy_count += 1
        # An "aux" texture is any texture-bearing entry beyond the canonical
        # diffuse (vz_lrterrain). The canonical entry is identified by name.
        if is_texture_like and ent_name and ent_name != _MASTER_TEXTURE_BASENAME:
            aux_entries.append(rec)

    out["mesh_count"] = mesh_count
    out["dummy_count"] = dummy_count
    out["named_entries"] = named_entries
    out["aux_entries"] = aux_entries
    return out


def _load_master_texture(block_dir: Path) -> Path:
    """Return path to the embedded-ready master terrain PNG.

    Transcodes ``vz_lrterrain.dds → vz_lrterrain.png`` via the standard
    pipeline (ffmpeg first, Pillow fallback) when the PNG is missing. Returns
    the PNG path on success. Raises ``FileNotFoundError`` if the master
    texture isn't present in ``<block_dir>/textures/``.
    """
    tex_dir = block_dir / "textures"
    png = tex_dir / f"{_MASTER_TEXTURE_BASENAME}.png"
    if png.is_file() and png.stat().st_size > 0:
        return png
    dds = tex_dir / f"{_MASTER_TEXTURE_BASENAME}.dds"
    if not dds.is_file():
        raise FileNotFoundError(
            f"missing master terrain texture: {dds} (and {png})"
        )
    from texture_extractor import maybe_convert_png  # local import to avoid heavy deps in --no-glb path
    if maybe_convert_png(dds, png):
        return png
    # Pillow fallback (handles BC1/DXT1 via the Pillow DDS plugin).
    from PIL import Image
    img = Image.open(dds)
    if img.mode not in ("RGB", "RGBA"):
        img = img.convert("RGBA")
    img.save(png, format="PNG")
    if not png.is_file() or png.stat().st_size == 0:
        raise RuntimeError(f"failed to transcode {dds} → {png}")
    return png


def extract_merged_terrain(
    data: bytes,
    layers_static_blob: Path | None = None,
) -> tuple[
    list[tuple[float, float, float]],
    list[tuple[int, int, int]],
    list[tuple[float, float]],
    dict[str, object],
]:
    """Return merged (vertices, faces, stats) from every drawable UCFX tile.

    Each UCFX sub-container is one terrain tile mesh in **local** coordinates (~±200 m
    on X/Z). World placement uses the ``lrterrain_rXX_cYY`` grid (400 m spacing).
    File order ≠ grid order. Tile→(row, col) is recovered from the
    ``LowResTerrainObject`` COMP in ``layers_static`` sub-block 13:
    ``entity_key → mesh_hash`` records that match the per-tile ``hash1`` in
    the ``low_res_terrain`` block's TOC. Seam-matching is retained as a
    fallback when the metadata blob is unavailable.
    """
    meshes: list[TileMesh] = []
    skipped: list[str] = []
    containers_seen = 0

    for tile_index, container in enumerate(iter_ucfx_containers(data)):
        containers_seen += 1
        db = int(container["data_base"])
        for rows in _iter_geom_child_row_slices(container["chunks"]):
            sub = _parse_prmg_body(rows)
            if sub is None:
                continue
            verts, faces, meta = decode_submesh(data, db, sub, hier_nodes=None)
            if not verts or not faces:
                reason = meta.get("skip", "empty")
                skipped.append(f"tile={tile_index} ucfx_off={container['ucfx_off']}: {reason}")
                break
            meshes.append((verts, faces))
            break

    if len(meshes) != _LOW_RES_TERRAIN_GRID * _LOW_RES_TERRAIN_GRID:
        return [], [], [], {
            "containers_seen": containers_seen,
            "tiles_ok": len(meshes),
            "tiles_failed": skipped[:50],
            "tiles_failed_count": len(skipped),
        }

    metadata_grid, metadata_info = _build_metadata_grid_assignment(
        layers_static_blob, data, len(meshes)
    )
    if metadata_grid is not None:
        grid_assign = metadata_grid
        grid_source = "metadata_lookup"
    else:
        grid_assign = _compute_tile_grid_assignment(meshes)
        grid_source = "seam_match_fallback"

    mean_seam = _mean_grid_seam_m(meshes, grid_assign)
    max_seam = _max_grid_seam_m(meshes, grid_assign)
    identity_mismatches = sum(
        1
        for row in range(_LOW_RES_TERRAIN_GRID)
        for col in range(_LOW_RES_TERRAIN_GRID)
        if grid_assign[row][col] != row * _LOW_RES_TERRAIN_GRID + col
    )

    # Ocean placeholder tiles: single-quad flat (≤8 verts, dy<1m) — identify so
    # downstream tools can treat them specially (no offset, no LOD, etc.).
    ocean_iter_indices = sorted(
        ti for ti, (v, _f) in enumerate(meshes)
        if len(v) <= 8 and (max(p[1] for p in v) - min(p[1] for p in v)) < 1.0
    )

    parts: list[TileMesh] = []
    for row in range(_LOW_RES_TERRAIN_GRID):
        for col in range(_LOW_RES_TERRAIN_GRID):
            mesh_idx = grid_assign[row][col]
            verts, faces = meshes[mesh_idx]
            center_x, center_z = _tile_world_center_rc(row, col)
            world_verts = _offset_verts_to_world(verts, center_x, center_z)
            parts.append((world_verts, faces))

    all_v, all_f = merge_submeshes(parts)
    # Planar UV projection from world XZ into the 2048² master texture.
    # The source vertex stream carries no UVs (stride=16 = pos+w+normal+w),
    # so we synthesize them at merge time. See output/terrain_uv_convention.json.
    all_uv = [_world_xz_to_uv(x, z) for (x, _y, z) in all_v]
    uv_min_u = min(u for u, _ in all_uv) if all_uv else 0.0
    uv_max_u = max(u for u, _ in all_uv) if all_uv else 0.0
    uv_min_v = min(v for _, v in all_uv) if all_uv else 0.0
    uv_max_v = max(v for _, v in all_uv) if all_uv else 0.0
    world_bounds = _bounds_xyz(all_v)
    return all_v, all_f, all_uv, {
        "containers_seen": containers_seen,
        "tiles_ok": len(meshes),
        "vertices": len(all_v),
        "faces": len(all_f),
        "tiles_failed_count": len(skipped),
        "tiles_failed_sample": skipped[:20],
        "world_bounds": world_bounds,
        "tile_grid": _LOW_RES_TERRAIN_GRID,
        "tile_span_m": _LOW_RES_TERRAIN_TILE_SPAN_M,
        "grid_origin_m": _LOW_RES_TERRAIN_ORIGIN_M,
        "grid_assignment": grid_assign,
        "grid_source": grid_source,
        "grid_metadata_info": metadata_info,
        "mean_seam_m": round(mean_seam, 4),
        "max_seam_m": round(max_seam, 4),
        "identity_index_mismatches": identity_mismatches,
        "ocean_tile_iter_indices": ocean_iter_indices,
        "ocean_tile_count": len(ocean_iter_indices),
        "transform_source": "none_source_seam_continuous",
        "uv_projection": "planar_world_xz",
        "uv_bounds": {
            "min_u": round(uv_min_u, 6),
            "max_u": round(uv_max_u, 6),
            "min_v": round(uv_min_v, 6),
            "max_v": round(uv_max_v, 6),
        },
        "uv_v_flip": _TEXTURE_V_FLIP,
        "master_texture": _MASTER_TEXTURE_BASENAME,
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Merge Mercenaries 2 low_res_terrain tiles → GLB")
    ap.add_argument(
        "--repo-root",
        type=Path,
        default=Path(__file__).resolve().parents[1],
        help="Repository root (default: parent of tools/)",
    )
    ap.add_argument(
        "--extracted-root",
        type=Path,
        default=None,
        help="Pipeline extracted root containing batch_vz/blocks/ and review/ "
        "(default: <repo-root>/output/extracted)",
    )
    ap.add_argument(
        "--blob",
        type=Path,
        default=None,
        help=f"Path to low_res_terrain .block.bin (default: auto under <extracted-root>/batch_vz/blocks/)",
    )
    ap.add_argument(
        "--out-review-dir",
        type=Path,
        default=None,
        help="Review output directory (default: review/batch_vz/<blob stem>/)",
    )
    ap.add_argument(
        "--no-glb",
        action="store_true",
        help="Only write submeshes + OBJ; skip mesh_scene.glb",
    )
    args = ap.parse_args()
    repo_root = args.repo_root.resolve()
    extracted_root = (
        args.extracted_root.resolve()
        if args.extracted_root is not None
        else repo_root / "output" / "extracted"
    )

    try:
        blob = _find_low_res_blob(extracted_root, args.blob)
    except FileNotFoundError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1

    out_review = (
        args.out_review_dir.resolve()
        if args.out_review_dir
        else _default_review_dir(extracted_root, blob)
    )
    sub_dir = out_review / "submeshes"
    tex_dir = out_review / "textures"
    sub_dir.mkdir(parents=True, exist_ok=True)
    tex_dir.mkdir(parents=True, exist_ok=True)

    data = blob.read_bytes()
    layers_static_blob = _find_layers_static_blob(extracted_root)
    verts, faces, uvs, stats = extract_merged_terrain(data, layers_static_blob)

    if not verts or not faces:
        print(f"error: no merged geometry — stats={json.dumps(stats, indent=2)}", file=sys.stderr)
        return 2

    # Master texture must exist on disk so gltf_exporter can embed it into the GLB.
    try:
        master_png = _load_master_texture(out_review)
        master_texture_status = f"ok:{master_png.name}"
    except (FileNotFoundError, RuntimeError) as exc:
        master_png = None
        master_texture_status = f"unavailable: {exc}"
        print(f"warning: master terrain texture unavailable ({exc}); GLB will be untextured", file=sys.stderr)

    # Aux-texture TOC walk — for the retail PC build this returns 0 aux entries
    # (the block ships only the diffuse atlas), but the result is recorded in
    # the manifest for forward-compat / other builds.
    aux_scan = _walk_terrain_toc_aux_textures(data)
    _update_terrain_manifest(out_review / "textures" / "manifest.json", aux_scan)

    _write_obj(sub_dir / "0000.obj", verts, faces, uvs=uvs if master_png else None)

    # Material index 0 → diffuse=vz_lrterrain. gltf_exporter resolves the texture
    # file via tex_dir/<name>.{png,dds} and embeds the bytes into the GLB.
    if master_png:
        index = [{
            "file": "0000.obj",
            "material_index": 0,
            "texture_diffuse": _MASTER_TEXTURE_BASENAME,
            "metallic_factor": 0.0,
            "roughness_factor": 1.0,
            "base_color_factor": [1.0, 1.0, 1.0, 1.0],
        }]
    else:
        index = [{"file": "0000.obj", "material_index": None}]
    (sub_dir / "index.json").write_text(json.dumps(index, indent=2), encoding="utf-8")

    grid_source = stats.get("grid_source", "unknown")
    meta = {
        "vertices": len(verts),
        "faces": len(faces),
        "topology": "merged_low_res_terrain",
        "stem": out_review.name,
        "source_blob": str(blob.relative_to(repo_root)) if blob.is_relative_to(repo_root) else str(blob),
        "extract": {"terrain_merge_stats": stats},
        "note": (
            "Merged from UCFX GEOM+STRM+IBUF tiles; tile→(row, col) recovered from "
            "layers_static.LowResTerrainObject metadata, then offset to placement centers."
            if grid_source == "metadata_lookup"
            else "Merged from UCFX GEOM+STRM+IBUF tiles; layers_static metadata "
            "unavailable, fell back to seam-matching."
        ),
        "world_bounds": stats.get("world_bounds"),
        "mean_seam_m": stats.get("mean_seam_m"),
        "max_seam_m": stats.get("max_seam_m"),
        "identity_index_mismatches": stats.get("identity_index_mismatches"),
        "grid_source": grid_source,
        "grid_metadata_info": stats.get("grid_metadata_info"),
        "transform_source": stats.get("transform_source"),
        "ocean_tile_iter_indices": stats.get("ocean_tile_iter_indices"),
        "ocean_tile_count": stats.get("ocean_tile_count"),
        "uv_projection": stats.get("uv_projection"),
        "uv_bounds": stats.get("uv_bounds"),
        "uv_v_flip": stats.get("uv_v_flip"),
        "master_texture": stats.get("master_texture"),
        "master_texture_status": master_texture_status,
    }
    (out_review / "mesh.meta.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")

    print(
        f"wrote {sub_dir / '0000.obj'} "
        f"({stats['tiles_ok']} tiles, {len(verts)} verts, {len(faces)} tris)"
    )

    if not args.no_glb:
        glb_out = out_review / "mesh_scene.glb"
        export_review_to_gltf(
            out_review,
            glb_out,
            stem=out_review.name,
            output_format="glb",
            glb_root_scale=1.0,
        )
        print(f"wrote {glb_out}")

    if stats.get("tiles_failed_count"):
        print(
            f"warning: {stats['tiles_failed_count']} tile(s) skipped "
            f"(see mesh.meta.json terrain_merge_stats)",
            file=sys.stderr,
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
