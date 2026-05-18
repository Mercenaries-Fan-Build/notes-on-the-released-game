#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Mesh extraction from Mercenaries 2 UCFX blobs -> OBJ / minimal glTF."""

from __future__ import annotations

import argparse
import base64
import json
import struct
import sys
from pathlib import Path

from ucfx_mesh_codec import (
    CONTAINER_SENTINEL,
    _find_hier_chunk,
    _geometry_score,
    classify_hier_damage_branches,
    decode_positions_multi,
    decode_submesh,
    find_all,
    find_mesh_bbox_for_geom,
    find_tag,
    iter_submesh_buffers,
    iter_ucfx_containers,
    merge_submeshes,
    parse_hier_world_transforms,
    parse_ibuf_meta,
    parse_indx_chunk,
    parse_mtrl,
    parse_mtrl_raw,
    parse_prmg_info_flags,
    parse_prmt,
    parse_strm_decl_stride,
    parse_strm_vb,
    resolve_vb_base,
    score_index_blob,
    search_u16_index_blob,
    u16_strip_to_tris,
    unpack_u16,
)


def _is_container_at(data: bytes, pos: int) -> bool:
    if pos + 8 > len(data):
        return False
    return struct.unpack_from("<I", data, pos + 4)[0] == CONTAINER_SENTINEL


def collect_strm_roots(data: bytes) -> list[int]:
    """STRM chunks that look like vertex-stream containers."""
    out: list[int] = []
    for p in find_all(data, b"STRM"):
        if _is_container_at(data, p):
            out.append(p)
    return out


def estimate_vert_ceiling(blob: bytes) -> int:
    """Rough upper bound on vertex count from raw VB byte length."""
    if not blob:
        return 4096
    est = max(len(blob) // 12, len(blob) // 8)
    return min(max(est, 64), 200_000)


def pick_best_index_blob_for_geom(
    data: bytes,
    geom_off: int,
    vert_ceiling: int,
    strm_off: int | None,
) -> tuple[list[tuple[int, int, int]], str, int | None, int]:
    best: tuple[int, list[tuple[int, int, int]], str, str, int | None, int] | None = None

    def consider(words: list[int], mode: str, label: str, base: int | None) -> None:
        nonlocal best
        score, tris, mx = score_index_blob(words, vert_ceiling, mode)
        key = (score, len(tris))
        if best is None or key > (best[0], len(best[1])):
            best = (score, tris, mode, label, base, mx)

    # IBUF-declared hints near STRM
    if strm_off is not None:
        ibuf = find_tag(data, b"IBUF", strm_off, min(len(data), strm_off + 6000))
        if ibuf >= 0:
            meta = parse_ibuf_meta(data, ibuf)
            if meta:
                ib_off, ib_len = meta
                nbytes = min(ib_len if ib_len > 0 else 8192, 64_000)
                for label, base in (
                    ("ibuf_meta+off", ibuf + ib_off),
                    ("strm+off", strm_off + ib_off),
                    ("geom+off", (geom_off + ib_off) if geom_off >= 0 else -1),
                    ("abs_off", ib_off),
                ):
                    if base is None or base < 0 or base >= len(data) - 64:
                        continue
                    words = unpack_u16(data, base, nbytes)
                    for mode in ("strip", "list"):
                        consider(words, mode, label, base)

        # Fast path: IBUF-relative decoding is usually authoritative when it scores well.
        if best is not None and best[0] >= 25_000:
            _score, tris, mode, label, ibase, mx = best
            topo = f"ucfx_u16_{mode}_{label}"
            return tris, topo, ibase, mx

    # Local window search around STRM
    if strm_off is not None:
        lo = strm_off
        hi = min(len(data), strm_off + 220_000)
        step = 128
        nbytes = 8192
        pos = lo
        while pos + nbytes <= hi:
            words = unpack_u16(data, pos, nbytes)
            for mode in ("strip", "list"):
                consider(words, mode, "strm_window", pos)
            pos += step

    # GEOM-window search (fallback / reinforcement)
    base, tris_g, mode_g, mx_g = search_u16_index_blob(data, geom_off, vert_ceiling)
    if base is not None:
        words = unpack_u16(data, base, 8192)
        consider(words, mode_g, "geom_search", base)

    if best is None:
        return [], "none", None, 0

    _score, tris, mode, label, ibase, mx = best
    topo = f"ucfx_u16_{mode}_{label}"
    return tris, topo, ibase, mx


def _instance_submesh_to_hier_node(
    local_verts: list[tuple[float, float, float]],
    faces: list[tuple[int, int, int]],
    base_meta: dict[str, object],
    hier_node: dict[str, object],
) -> tuple[list[tuple[float, float, float]], list[tuple[int, int, int]], dict[str, object]]:
    """Create an instanced copy of a submesh at a different HIER node position."""
    from ucfx_mesh_codec import _apply_world_transform, get_world_translation, get_world_matrix_3x3

    world_trans = get_world_translation(hier_node)
    rot_3x3 = get_world_matrix_3x3(hier_node)
    new_verts = _apply_world_transform(local_verts, world_trans, rot_3x3)

    new_meta = dict(base_meta)
    new_meta["hier_node_idx"] = hier_node["idx"]
    new_meta["world_translation"] = list(world_trans)
    new_meta["instanced_from"] = base_meta.get("hier_node_idx", -1)
    if rot_3x3 is not None:
        new_meta["world_rotation_3x3"] = [list(r) for r in rot_3x3]
        zero_t = (0.0, 0.0, 0.0)
        if "normals" in base_meta:
            new_meta["normals"] = _apply_world_transform(base_meta["normals"], zero_t, rot_3x3)
        if "tangents" in base_meta:
            new_meta["tangents"] = _apply_world_transform(base_meta["tangents"], zero_t, rot_3x3)
    bb = None
    if new_verts:
        xs = [v[0] for v in new_verts]
        ys = [v[1] for v in new_verts]
        zs = [v[2] for v in new_verts]
        bb = [min(xs), min(ys), min(zs), max(xs), max(ys), max(zs)]
    if bb:
        new_meta["decoded_bbox"] = bb
    return new_verts, list(faces), new_meta


def _inherit_mesh_group_transforms(
    parts: list[tuple[list[tuple[float, float, float]], list[tuple[int, int, int]]]],
    submeta: list[dict[str, object]],
) -> None:
    """Apply HIER transforms to parts that share a mesh_group with transformed siblings.

    Some PRMGs (e.g. door window glass at LOD 0) don't bbox-match any HIER
    node, but belong to the same MESH container as sibling PRMGs that do.
    For each untransformed part, find a sibling in the same mesh_group that
    has a hier_node_idx and apply that sibling's transform.
    """
    from collections import defaultdict
    from ucfx_mesh_codec import _apply_world_transform

    group_hier: dict[int, dict[str, object]] = {}
    for sm in submeta:
        mg = sm.get("mesh_group_id")
        if mg is not None and "hier_node_idx" in sm and mg not in group_hier:
            wt = sm.get("world_translation")
            rot = sm.get("world_rotation_3x3")
            if wt:
                group_hier[mg] = {"world_translation": wt, "world_rotation_3x3": rot,
                                  "hier_node_idx": sm["hier_node_idx"]}

    for i, sm in enumerate(submeta):
        mg = sm.get("mesh_group_id")
        if mg is None or "hier_node_idx" in sm:
            continue
        donor = group_hier.get(mg)
        if donor is None:
            continue
        wt = donor["world_translation"]
        rot = donor.get("world_rotation_3x3")
        rot_tuple = tuple(tuple(r) for r in rot) if rot else None
        trans = (wt[0], wt[1], wt[2])
        new_verts = _apply_world_transform(parts[i][0], trans, rot_tuple)
        parts[i] = (new_verts, parts[i][1])
        sm["hier_node_idx"] = donor["hier_node_idx"]
        sm["world_translation"] = list(wt)
        sm["inherited_hier_from_mesh_group"] = True
        if rot:
            sm["world_rotation_3x3"] = rot
        if new_verts:
            xs = [v[0] for v in new_verts]
            ys = [v[1] for v in new_verts]
            zs = [v[2] for v in new_verts]
            sm["decoded_bbox"] = [min(xs), min(ys), min(zs), max(xs), max(ys), max(zs)]


def _split_by_prmt(
    data: bytes,
    data_base: int,
    sub: dict[str, object],
    verts: list[tuple[float, float, float]],
    faces: list[tuple[int, int, int]],
    meta: dict[str, object],
) -> list[tuple[list[tuple[float, float, float]], list[tuple[int, int, int]], dict[str, object]]]:
    """Split a decoded submesh into per-material sub-draws using PRMT records.

    For single-material PRMGs (or if no PRMT is available) returns the original
    submesh unchanged.  For multi-material PRMGs, re-decodes the raw index
    buffer per-record to produce clean per-material triangle lists.
    """
    prmt_off = int(sub.get("prmt_off", 0))
    prmt_len = int(sub.get("prmt_len", 0))
    if prmt_len < 32:
        return [(verts, faces, meta)]

    prmt_records = parse_prmt(data, data_base, prmt_off, prmt_len)
    if len(prmt_records) <= 2:
        # Single-material: 2 identical records — use as-is, just tag material
        meta["material_index"] = prmt_records[0]["material_index"] if prmt_records else None
        return [(verts, faces, meta)]

    info_flags = parse_prmg_info_flags(
        data, data_base, int(sub.get("prmg_info_off", 0)), int(sub.get("prmg_info_len", 0))
    )
    transparency = info_flags.get("transparency_flag", 0.0)

    ib_abs = data_base + int(sub["ib_off"])
    ib_len = int(sub["ib_len"])
    n_idx = ib_len // 2
    all_indices = list(struct.unpack_from("<%dH" % n_idx, data, ib_abs))

    # The last record appears to be a summary/duplicate — skip it
    draw_records = prmt_records[:-1]

    results: list[tuple[list[tuple[float, float, float]], list[tuple[int, int, int]], dict[str, object]]] = []
    for ri, rec in enumerate(draw_records):
        start = rec["start_index"]
        count = rec["index_count"]
        if start + count > len(all_indices):
            continue
        sub_indices = all_indices[start:start + count]
        sub_faces = u16_strip_to_tris(sub_indices)
        if not sub_faces:
            continue

        sub_meta = dict(meta)
        sub_meta["material_index"] = rec["material_index"]
        sub_meta["prmt_draw_index"] = ri
        sub_meta["transparency_flag"] = transparency
        sub_meta["faces"] = len(sub_faces)

        # Recompute bbox for this material split
        used_vi = set()
        for a, b, c in sub_faces:
            used_vi.update((a, b, c))
        if used_vi and max(used_vi) < len(verts):
            xs = [verts[i][0] for i in used_vi]
            ys = [verts[i][1] for i in used_vi]
            zs = [verts[i][2] for i in used_vi]
            sub_meta["decoded_bbox"] = [min(xs), min(ys), min(zs), max(xs), max(ys), max(zs)]
            sub_meta["vertices"] = len(used_vi)

        results.append((verts, sub_faces, sub_meta))

    return results if results else [(verts, faces, meta)]


def extract_structured(data: bytes) -> tuple[list[tuple[float, float, float]], list[tuple[int, int, int]], dict[str, object]]:
    """Primary path: walk UCFX chunk tables, resolve VB/IB via ``data_base``, merge all PRMG draws.

    Parses the HIER chunk (if present) to compute per-node world transforms
    and applies them to each PRMG's vertices before merging.  Instanced
    geometry (same PRMG at multiple HIER positions) is duplicated.
    """
    parts: list[tuple[list[tuple[float, float, float]], list[tuple[int, int, int]]]] = []
    submeta: list[dict[str, object]] = []
    touched: list[int] = []

    for container in iter_ucfx_containers(data):
        before = len(parts)
        db = int(container["data_base"])

        hier_nodes: list[dict[str, object]] | None = None
        damage_branches: dict[int, str] | None = None
        indx_mapping: list[int] | None = None
        hier_info = _find_hier_chunk(container["chunks"])
        if hier_info is not None:
            hier_off, hier_len = hier_info
            hier_nodes = parse_hier_world_transforms(data, db, hier_off, hier_len)
            damage_branches = classify_hier_damage_branches(
                data, db, container["chunks"], hier_nodes
            )
            indx_mapping = parse_indx_chunk(data, db, container["chunks"])

        for sub in iter_submesh_buffers(container):
            # Resolve INDX-based HIER node for this MESH group
            indx_hier_idx: int | None = None
            mg = sub.get("mesh_group_id")
            if indx_mapping is not None and mg is not None and mg < len(indx_mapping):
                indx_hier_idx = indx_mapping[mg]

            verts, faces, sm = decode_submesh(
                data, db, sub, hier_nodes=hier_nodes,
                damage_branches=damage_branches,
                indx_hier_node_idx=indx_hier_idx,
            )
            if not verts or not faces:
                continue

            info_flags = parse_prmg_info_flags(
                data, db, int(sub.get("prmg_info_off", 0)), int(sub.get("prmg_info_len", 0))
            )
            sm["transparency_flag"] = info_flags.get("transparency_flag", 0.0)

            for sv, sf, smeta in _split_by_prmt(data, db, sub, verts, faces, sm):
                parts.append((sv, sf))
                submeta.append(smeta)

                # When using INDX, skip bbox-based instancing (INDX gives the
                # authoritative single node per MESH group)
                if indx_hier_idx is not None:
                    continue

                instance_nodes = smeta.get("hier_instance_nodes")
                if instance_nodes and len(instance_nodes) > 1 and hier_nodes:
                    local_verts, local_faces, _ = decode_submesh(
                        data, db, sub, hier_nodes=None
                    )
                    if local_verts and local_faces:
                        node_map = {n["idx"]: n for n in hier_nodes}
                        for ni in instance_nodes[1:]:
                            node = node_map.get(ni)
                            if node is None:
                                continue
                            iv, if_, im = _instance_submesh_to_hier_node(
                                local_verts, local_faces, smeta, node
                            )
                            if iv and if_:
                                if damage_branches:
                                    im["damage_state"] = damage_branches.get(ni, "shared")
                                parts.append((iv, if_))
                                submeta.append(im)

        if len(parts) > before:
            touched.append(int(container["ucfx_off"]))

    _inherit_mesh_group_transforms(parts, submeta)

    if not parts:
        return [], [], {
            "structured": True,
            "empty": True,
            "ucfx_offsets_used": touched,
            "submeshes": [],
        }

    verts, faces = merge_submeshes(parts)
    return verts, faces, {
        "structured": True,
        "ucfx_offsets_used": touched,
        "submesh_count": len(submeta),
        "submeshes": submeta,
    }


def extract_largest_draw(data: bytes, geom_off: int) -> tuple[list[tuple[float, float, float]], list[tuple[int, int, int]], dict[str, object]]:
    """Pick the richest STRM/VB + best index correlation under GEOM."""
    strms = collect_strm_roots(data)
    if geom_off >= 0:
        strms = [s for s in strms if s >= geom_off]

    bbox = find_mesh_bbox_for_geom(data, geom_off)

    best_blob: bytes | None = None
    best_meta: dict[str, object] = {}
    best_strm: int | None = None
    best_gscore: float = -1.0

    for s in strms:
        pr = parse_strm_vb(data, s)
        if not pr:
            continue
        off, ln = pr
        base = resolve_vb_base(data, s, geom_off, off, ln, bbox=bbox)
        if base is None or base + ln > len(data):
            continue
        blob = data[base : base + ln]
        decl_stride = parse_strm_decl_stride(data, s)
        verts, mode, stride, skip = decode_positions_multi(blob, bbox=bbox, decl_stride=decl_stride)
        gscore = _geometry_score(verts)
        if gscore > best_gscore:
            best_gscore = gscore
            best_blob = blob
            best_strm = s
            best_meta = {
                "strm_offset": s,
                "vb_file_offset": base,
                "vb_offset_field": off,
                "vb_byte_length": ln,
                "vertex_mode": mode,
                "stride_bytes": stride,
                "header_skip_bytes": skip,
                "decl_stride_hint": decl_stride,
                "vertices": len(verts),
                "mesh_bbox": (
                    [bbox[0][0], bbox[0][1], bbox[0][2], bbox[1][0], bbox[1][1], bbox[1][2]]
                    if bbox
                    else None
                ),
            }

    if best_blob is None:
        return [], [], {"note": "no STRM vb"}

    decl_stride = parse_strm_decl_stride(data, best_strm) if best_strm is not None else None
    verts, mode, stride, skip = decode_positions_multi(best_blob, bbox=bbox, decl_stride=decl_stride)
    # Ceiling for index validation: allow modest headroom above decoded count,
    # but never let raw blob size dominate (avoids matching random data as indices).
    ceiling = len(verts) + max(len(verts) // 4, 64)

    faces, topo, ibase, mx = pick_best_index_blob_for_geom(data, geom_off, ceiling, best_strm)

    meta_out = {
        **best_meta,
        "index_topology": topo,
        "index_base_offset": ibase,
        "index_max": mx,
        "geom_offset": geom_off if geom_off >= 0 else None,
    }

    # Reject indices that overshoot the vertex buffer — indicates a false-positive match.
    if faces:
        need = max(max(a, b, c) for a, b, c in faces) + 1
        if need > len(verts) * 3:
            faces = []
            meta_out["index_topology"] = "rejected_overshoot"
        elif need > len(verts):
            # Do not pad phantom vertices — indicates a false VB/index pairing.
            faces = []
            meta_out["index_topology"] = "rejected_index_vertex_mismatch"
            meta_out["index_need_vertices"] = need
            meta_out["vertices_decoded"] = len(verts)

    return verts, faces, meta_out


def extract_multi_draw_merge(data: bytes, geom_off: int) -> tuple[list[tuple[float, float, float]], list[tuple[int, int, int]], dict[str, object]]:
    """Experimental: merge consecutive STRM draws (indices assumed global)."""
    strms = collect_strm_roots(data)
    if geom_off >= 0:
        strms = [s for s in strms if s >= geom_off]

    parts: list[tuple[list[tuple[float, float, float]], list[tuple[int, int, int]]]] = []
    notes: list[dict[str, object]] = []

    bbox = find_mesh_bbox_for_geom(data, geom_off)
    ceiling_acc = 4096
    for s in strms:
        pr = parse_strm_vb(data, s)
        if not pr:
            continue
        off, ln = pr
        base = resolve_vb_base(data, s, geom_off, off, ln, bbox=bbox)
        if base is None or base + ln > len(data):
            continue
        blob = data[base : base + ln]
        decl_stride = parse_strm_decl_stride(data, s)
        verts, *_ = decode_positions_multi(blob, bbox=bbox, decl_stride=decl_stride)
        ceiling_acc = max(ceiling_acc, estimate_vert_ceiling(blob), len(verts) + 256)
        faces, topo, ibase, mx = pick_best_index_blob_for_geom(data, geom_off, ceiling_acc, s)
        notes.append(
            {
                "strm_offset": s,
                "vertices": len(verts),
                "topology": topo,
                "index_base_offset": ibase,
                "index_max": mx,
            }
        )
        if verts and faces:
            parts.append((verts, faces))

    if not parts:
        return extract_largest_draw(data, geom_off)

    verts, faces = merge_submeshes(parts)
    return verts, faces, {"merged": True, "parts": notes}


def write_obj(
    path: Path,
    verts: list[tuple[float, float, float]],
    faces: list[tuple[int, int, int]] | None,
    uvs: list[tuple[float, float]] | None = None,
    normals: list[tuple[float, float, float]] | None = None,
) -> None:
    lines = ["# Mercenaries 2 UCFX extract", "o mesh"]
    for x, y, z in verts:
        lines.append(f"v {x:.6g} {y:.6g} {z:.6g}")
    has_uvs = uvs is not None and len(uvs) == len(verts)
    if has_uvs:
        for u, v in uvs:
            lines.append(f"vt {u:.6g} {v:.6g}")
    has_normals = normals is not None and len(normals) == len(verts)
    if has_normals:
        for nx, ny, nz in normals:
            lines.append(f"vn {nx:.6g} {ny:.6g} {nz:.6g}")
    if faces:
        if has_uvs and has_normals:
            for a, b, c in faces:
                lines.append(f"f {a+1}/{a+1}/{a+1} {b+1}/{b+1}/{b+1} {c+1}/{c+1}/{c+1}")
        elif has_uvs:
            for a, b, c in faces:
                lines.append(f"f {a+1}/{a+1} {b+1}/{b+1} {c+1}/{c+1}")
        elif has_normals:
            for a, b, c in faces:
                lines.append(f"f {a+1}//{a+1} {b+1}//{b+1} {c+1}//{c+1}")
        else:
            for a, b, c in faces:
                lines.append(f"f {a+1} {b+1} {c+1}")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_gltf_positions(
    path: Path, verts: list[tuple[float, float, float]], faces: list[tuple[int, int, int]] | None
) -> None:
    pos = bytearray()
    for x, y, z in verts:
        pos.extend(struct.pack("<fff", x, y, z))
    n = len(verts)
    buffers: list[dict] = [
        {"uri": f"data:application/octet-stream;base64,{base64.b64encode(pos).decode('ascii')}", "byteLength": len(pos)}
    ]
    buffer_views: list[dict] = [{"buffer": 0, "byteOffset": 0, "byteLength": len(pos)}]
    accessors: list[dict] = [
        {
            "bufferView": 0,
            "componentType": 5126,
            "count": n,
            "type": "VEC3",
            "max": [max(v[i] for v in verts) for i in range(3)],
            "min": [min(v[i] for v in verts) for i in range(3)],
        }
    ]
    prim: dict = {"attributes": {"POSITION": 0}}
    if faces:
        idx = bytearray()
        for a, b, c in faces:
            idx.extend(struct.pack("<HHH", a, b, c))
        buffers.append(
            {
                "uri": f"data:application/octet-stream;base64,{base64.b64encode(idx).decode('ascii')}",
                "byteLength": len(idx),
            }
        )
        buffer_views.append({"buffer": 1, "byteOffset": 0, "byteLength": len(idx)})
        accessors.append(
            {
                "bufferView": 1,
                "componentType": 5123,
                "count": len(faces) * 3,
                "type": "SCALAR",
            }
        )
        prim["indices"] = 1
    doc = {
        "asset": {"version": "2.0", "generator": "mercs2_mesh_extractor"},
        "buffers": buffers,
        "bufferViews": buffer_views,
        "accessors": accessors,
        "meshes": [{"primitives": [prim]}],
        "nodes": [{"mesh": 0}],
        "scenes": [{"nodes": [0]}],
        "scene": 0,
    }
    path.write_text(json.dumps(doc, indent=2), encoding="utf-8")


def _find_sibling_hier(blob_path: Path) -> list[dict[str, object]] | None:
    """Locate the HIER from a sibling P000 standalone block.

    Compound blocks (P001+) share the same primary c3 cell as a standalone
    P000 block but omit the HIER chunk. This function locates the P000
    sibling in the same blocks directory and extracts its HIER nodes.
    """
    import re
    stem = blob_path.stem
    m = re.match(r"^(\d+)_blocks__VZ__(c\d+)", stem)
    if not m:
        return None
    primary_cell = m.group(2)
    blocks_dir = blob_path.parent
    if not blocks_dir.is_dir():
        return None
    pattern = f"*_blocks__VZ__{primary_cell}_P000_*.bin"
    for candidate in blocks_dir.glob(pattern):
        if candidate == blob_path:
            continue
        try:
            sib_data = candidate.read_bytes()
        except OSError:
            continue
        for container in iter_ucfx_containers(sib_data):
            db = int(container["data_base"])
            hier_info = _find_hier_chunk(container["chunks"])
            if hier_info is not None:
                hier_off, hier_len = hier_info
                nodes = parse_hier_world_transforms(sib_data, db, hier_off, hier_len)
                if nodes:
                    return nodes
    return None


def _extract_structured_parts(data: bytes, blob_path: Path | None = None) -> tuple[
    list[tuple[list[tuple[float, float, float]], list[tuple[int, int, int]]]],
    list[dict[str, object]],
    list[int],
    list[dict[str, object]],
]:
    """Like extract_structured but returns individual parts + submeta before merging.

    When a PRMG matches multiple HIER nodes (instanced geometry like wheels),
    a duplicate submesh is emitted for each additional instance position.

    Returns (parts, submeta, touched_offsets, mtrl_records).
    """
    from ucfx_mesh_codec import (
        _find_hier_chunk,
        decode_submesh,
        iter_submesh_buffers,
        iter_ucfx_containers,
        parse_hier_world_transforms,
        parse_indx_chunk,
        parse_prmg_bbox,
        parse_prmg_info_flags,
        match_all_prmg_to_hier_nodes,
    )

    parts: list[tuple[list[tuple[float, float, float]], list[tuple[int, int, int]]]] = []
    submeta: list[dict[str, object]] = []
    touched: list[int] = []
    mtrl_records: list[dict[str, object]] = []
    sibling_hier: list[dict[str, object]] | None = None

    for container in iter_ucfx_containers(data):
        before = len(parts)
        db = int(container["data_base"])

        hier_nodes = None
        damage_branches: dict[int, str] | None = None
        indx_mapping: list[int] | None = None
        hier_info = _find_hier_chunk(container["chunks"])
        if hier_info is not None:
            hier_off, hier_len = hier_info
            hier_nodes = parse_hier_world_transforms(data, db, hier_off, hier_len)
            damage_branches = classify_hier_damage_branches(
                data, db, container["chunks"], hier_nodes
            )
            indx_mapping = parse_indx_chunk(data, db, container["chunks"])

        if hier_nodes is None:
            indx_mapping = parse_indx_chunk(data, db, container["chunks"])
            if indx_mapping is not None and blob_path is not None:
                if sibling_hier is None:
                    sibling_hier = _find_sibling_hier(blob_path)
                if sibling_hier is not None:
                    hier_nodes = sibling_hier
                    indx_mapping = None
                    print(f"  Using sibling HIER ({len(hier_nodes)} nodes) for compound block", file=sys.stderr)

        # Parse MTRL if present (only first container with MTRL wins)
        if not mtrl_records:
            mtrl_abs, mtrl_len = parse_mtrl_raw(data, db, container["chunks"])
            if mtrl_abs > 0 and mtrl_len > 0:
                mtrl_records = parse_mtrl(data, mtrl_abs, mtrl_len)

        for sub in iter_submesh_buffers(container):
            indx_hier_idx: int | None = None
            mg = sub.get("mesh_group_id")
            if indx_mapping is not None and mg is not None and mg < len(indx_mapping):
                indx_hier_idx = indx_mapping[mg]

            verts, faces, sm = decode_submesh(
                data, db, sub, hier_nodes=hier_nodes,
                damage_branches=damage_branches,
                indx_hier_node_idx=indx_hier_idx,
            )
            if not verts or not faces:
                continue

            info_flags = parse_prmg_info_flags(
                data, db, int(sub.get("prmg_info_off", 0)), int(sub.get("prmg_info_len", 0))
            )
            sm["transparency_flag"] = info_flags.get("transparency_flag", 0.0)

            for sv, sf, smeta in _split_by_prmt(data, db, sub, verts, faces, sm):
                parts.append((sv, sf))
                submeta.append(smeta)

                if indx_hier_idx is not None:
                    continue

                instance_nodes = smeta.get("hier_instance_nodes")
                if instance_nodes and len(instance_nodes) > 1 and hier_nodes:
                    local_verts, local_faces, _ = decode_submesh(
                        data, db, sub, hier_nodes=None
                    )
                    if local_verts and local_faces:
                        node_map = {n["idx"]: n for n in hier_nodes}
                        for ni in instance_nodes[1:]:
                            node = node_map.get(ni)
                            if node is None:
                                continue
                            iv, if_, im = _instance_submesh_to_hier_node(
                                local_verts, local_faces, smeta, node
                            )
                            if iv and if_:
                                if damage_branches:
                                    im["damage_state"] = damage_branches.get(ni, "shared")
                                parts.append((iv, if_))
                                submeta.append(im)

        if len(parts) > before:
            touched.append(int(container["ucfx_off"]))

    _inherit_mesh_group_transforms(parts, submeta)

    return parts, submeta, touched, mtrl_records


def _dedupe_lod(
    parts: list[tuple[list[tuple[float, float, float]], list[tuple[int, int, int]]]],
    submeta: list[dict[str, object]],
    mode: str,
) -> tuple[
    list[tuple[list[tuple[float, float, float]], list[tuple[int, int, int]]]],
    list[dict[str, object]],
]:
    """Filter submeshes by LOD dedup strategy.

    Modes:
      keep-all          — no filtering
      dedupe-bbox       — group by decoded_bbox center, keep first per group
      highest-poly-per-bbox — group by decoded_bbox center, keep highest face count
    """
    if mode == "keep-all" or not parts:
        return parts, submeta

    import math

    def _bbox_key(sm: dict[str, object]) -> tuple[float, ...]:
        bb = sm.get("decoded_bbox")
        if not bb or len(bb) < 6:
            return (999999.0, 999999.0, 999999.0)
        cx = round((bb[0] + bb[3]) / 2, 2)
        cy = round((bb[1] + bb[4]) / 2, 2)
        cz = round((bb[2] + bb[5]) / 2, 2)
        ex = round(bb[3] - bb[0], 2)
        ey = round(bb[4] - bb[1], 2)
        ez = round(bb[5] - bb[2], 2)
        return (cx, cy, cz, ex, ey, ez)

    groups: dict[tuple[float, ...], list[int]] = {}
    for i, sm in enumerate(submeta):
        k = _bbox_key(sm)
        groups.setdefault(k, []).append(i)

    keep: list[int] = []
    for k, indices in groups.items():
        if len(indices) == 1 or mode == "dedupe-bbox":
            keep.append(indices[0])
        elif mode == "highest-poly-per-bbox":
            best_i = max(indices, key=lambda j: submeta[j].get("faces", 0))
            keep.append(best_i)

    keep.sort()
    return [parts[i] for i in keep], [submeta[i] for i in keep]


def _compute_lod_groups(
    parts: list[tuple[list[tuple[float, float, float]], list[tuple[int, int, int]]]],
    submeta: list[dict[str, object]],
) -> list[tuple[int, int, bool]]:
    """Return (lod_group, lod_rank, is_vehicle_lod) per part.

    Parts sharing the same decoded_bbox center+extent are grouped together.
    Full-vehicle meshes (those whose largest extent exceeds ``_VEHICLE_LOD_EXTENT``)
    are placed in per-damage-state groups and flagged as vehicle LODs.

    Within a group, parts are ranked by ``mesh_group_id`` (MESH container
    order in the GEOM chunk).  All parts that share the same
    ``mesh_group_id`` receive the same rank — they are co-rendered draw
    calls within one MESH, not LOD alternatives.  Different
    ``mesh_group_id`` values within one ``lod_group`` represent the actual
    LOD alternatives.
    """
    from collections import defaultdict

    _VEHICLE_LOD_EXTENT = 4.0

    def _max_extent(sm: dict[str, object]) -> float:
        bb = sm.get("decoded_bbox")
        if not bb or len(bb) < 6:
            return 0.0
        return max(bb[3] - bb[0], bb[4] - bb[1], bb[5] - bb[2])

    def _bbox_key(sm: dict[str, object]) -> tuple[float, ...]:
        bb = sm.get("decoded_bbox")
        if not bb or len(bb) < 6:
            return (999999.0, 999999.0, 999999.0, 0.0, 0.0, 0.0)
        cx = round((bb[0] + bb[3]) / 2, 2)
        cy = round((bb[1] + bb[4]) / 2, 2)
        cz = round((bb[2] + bb[5]) / 2, 2)
        ex = round(bb[3] - bb[0], 2)
        ey = round(bb[4] - bb[1], 2)
        ez = round(bb[5] - bb[2], 2)
        return (cx, cy, cz, ex, ey, ez)

    def _damage_key(sm: dict[str, object]) -> str:
        return sm.get("damage_state", "shared")

    vehicle_lod_indices: set[int] = set()
    groups: dict[tuple, list[int]] = defaultdict(list)
    for i in range(len(parts)):
        sm = submeta[i] if i < len(submeta) else {}
        ds = _damage_key(sm)
        if _max_extent(sm) > _VEHICLE_LOD_EXTENT:
            groups[("vehicle_lod", ds)].append(i)
            vehicle_lod_indices.add(i)
        else:
            groups[(_bbox_key(sm), ds)].append(i)

    result: list[tuple[int, int, bool]] = [(0, 0, False)] * len(parts)
    for gid, (_, indices) in enumerate(groups.items()):
        mg_to_indices: dict[int, list[int]] = defaultdict(list)
        for j in indices:
            mg = submeta[j].get("mesh_group_id", j) if j < len(submeta) else j
            mg_to_indices[mg].append(j)
        for rank, mg in enumerate(sorted(mg_to_indices.keys())):
            for idx in mg_to_indices[mg]:
                result[idx] = (gid, rank, idx in vehicle_lod_indices)
    return result


def write_per_submesh_objs(
    out_dir: Path,
    parts: list[tuple[list[tuple[float, float, float]], list[tuple[int, int, int]]]],
    submeta: list[dict[str, object]],
) -> Path:
    """Write each submesh as ``submeshes/NNNN.obj`` and return the ``index.json`` path."""
    sub_dir = out_dir / "submeshes"
    sub_dir.mkdir(parents=True, exist_ok=True)

    lod_info = _compute_lod_groups(parts, submeta)

    manifest_entries: list[dict[str, object]] = []
    for i, (verts, faces) in enumerate(parts):
        obj_name = f"{i:04d}.obj"
        part_uvs = submeta[i].get("uvs") if i < len(submeta) else None
        part_normals = submeta[i].get("normals") if i < len(submeta) else None
        write_obj(sub_dir / obj_name, verts, faces, uvs=part_uvs, normals=part_normals)
        gid, rank, is_vlod = lod_info[i]
        entry: dict[str, object] = {
            "index": i,
            "file": obj_name,
            "vertices": len(verts),
            "faces": len(faces),
            "lod_group": gid,
            "lod_rank": rank,
        }
        if is_vlod:
            entry["is_vehicle_lod"] = True
        if i < len(submeta):
            sm = submeta[i]
            if "decoded_bbox" in sm:
                entry["decoded_bbox"] = sm["decoded_bbox"]
            if "world_translation" in sm:
                entry["world_translation"] = sm["world_translation"]
            if "hier_node_idx" in sm:
                entry["hier_node_idx"] = sm["hier_node_idx"]
            if "prmg_bbox" in sm:
                entry["prmg_bbox"] = sm["prmg_bbox"]
            if "instanced_from" in sm:
                entry["instanced_from"] = sm["instanced_from"]
            if "hier_instance_nodes" in sm:
                entry["hier_instance_nodes"] = sm["hier_instance_nodes"]
            if "damage_state" in sm:
                entry["damage_state"] = sm["damage_state"]
            if "material_index" in sm:
                entry["material_index"] = sm["material_index"]
            for tex_key in ("texture_diffuse", "texture_specular", "texture_normal"):
                if tex_key in sm:
                    entry[tex_key] = sm[tex_key]
            if "transparency_flag" in sm:
                tf = sm["transparency_flag"]
                if isinstance(tf, float) and tf > 0.001:
                    entry["transparent"] = True
            if "prmt_draw_index" in sm:
                entry["prmt_draw_index"] = sm["prmt_draw_index"]
            if "mesh_group_id" in sm:
                entry["mesh_group_id"] = sm["mesh_group_id"]
            if "mesh_draw_index" in sm:
                entry["mesh_draw_index"] = sm["mesh_draw_index"]
            if "hier_source" in sm:
                entry["hier_source"] = sm["hier_source"]
            if "inherited_hier_from_mesh_group" in sm:
                entry["inherited_hier_from_mesh_group"] = True
            if "world_rotation_3x3" in sm:
                entry["world_rotation_3x3"] = sm["world_rotation_3x3"]
            if "tangents" in sm:
                entry["tangents"] = sm["tangents"]
        manifest_entries.append(entry)

    from collections import defaultdict as _dd
    _lg_members: dict[int, list[int]] = _dd(list)
    for me in manifest_entries:
        lg = me.get("lod_group")
        if lg is not None:
            _lg_members[lg].append(me["index"])
    for me in manifest_entries:
        lg = me.get("lod_group")
        if lg is None:
            continue
        alts = [j for j in _lg_members[lg] if j != me["index"]]
        if alts:
            me["lod_alternatives"] = alts

    idx_path = sub_dir / "index.json"
    idx_path.write_text(json.dumps(manifest_entries, indent=2), encoding="utf-8")
    print(f"Wrote {len(parts)} per-submesh OBJs + {idx_path}")
    return idx_path


def _emit_shared_textures_list(
    data: bytes,
    mtrl_records: list[dict[str, object]],
    texture_index_path: Path,
    out_dir: Path,
) -> None:
    """Write shared_textures.json listing cross-block textures needed by MTRL."""
    from texture_streaming_index import (
        TEXTURE_TYPE_HASH,
        iter_block_entries,
        load_index,
        hash_to_name_map,
    )

    # Collect hashes from block's own TOC
    local_hashes: set[int] = set()
    for asset_hash, type_hash, _, _ in iter_block_entries(data):
        if type_hash == TEXTURE_TYPE_HASH:
            local_hashes.add(asset_hash)

    # Collect all hashes referenced by MTRL
    idx = load_index(texture_index_path)
    names = hash_to_name_map(idx)

    shared: list[dict[str, object]] = []
    seen: set[int] = set()
    for rec in mtrl_records:
        for h in rec.get("tex_hashes", []):
            if h in seen or h in local_hashes:
                continue
            seen.add(h)
            name = names.get(h, "")
            if name:
                shared.append({"name": name, "hash": h})

    if shared:
        path = out_dir / "shared_textures.json"
        path.write_text(json.dumps(shared, indent=2), encoding="utf-8")


def _resolve_material_textures(
    data: bytes,
    submeta: list[dict[str, object]],
    mtrl_records: list[dict[str, object]],
    texture_index_path: Path | None,
) -> None:
    """Attach texture_diffuse/specular/normal names to submeta entries.

    Uses MTRL records to look up texture hashes, then resolves hashes to
    names via the block's own TOC (for local textures) and the global
    texture index (for cross-block shared textures).
    """
    from texture_streaming_index import (
        TEXTURE_TYPE_HASH,
        iter_block_entries,
        load_index,
        hash_to_name_map,
    )

    # Build local hash→name from this block's TOC + UCFX NAME sub-chunks
    local_names: dict[int, str] = {}
    block_entries = iter_block_entries(data)
    for asset_hash, type_hash, body_offset, size in block_entries:
        if type_hash != TEXTURE_TYPE_HASH:
            continue
        if body_offset + size > len(data):
            continue
        if data[body_offset : body_offset + 4] != b"UCFX":
            continue
        u0 = struct.unpack_from("<I", data, body_offset + 4)[0]
        u3 = struct.unpack_from("<I", data, body_offset + 16)[0]
        db = body_offset + int(u0)
        for ci in range(min(int(u3), 16)):
            cp = body_offset + 20 + ci * 20
            if cp + 20 > len(data):
                break
            tag = data[cp : cp + 4]
            cu0 = struct.unpack_from("<I", data, cp + 4)[0]
            cu1 = struct.unpack_from("<I", data, cp + 8)[0]
            if tag == b"NAME" and cu1 > 0:
                start = db + int(cu0)
                end = start + min(int(cu1), 256)
                if end <= len(data):
                    try:
                        raw = data[start:end]
                        local_names[asset_hash] = raw.split(b"\x00", 1)[0].decode("ascii", errors="replace")
                    except Exception:
                        pass
                break

    # Load global hash→name from texture index
    global_names: dict[int, str] = {}
    if texture_index_path and texture_index_path.is_file():
        idx = load_index(texture_index_path)
        global_names = hash_to_name_map(idx)

    def resolve(h: int) -> str | None:
        return local_names.get(h) or global_names.get(h)

    slot_keys = ["texture_diffuse", "texture_specular", "texture_normal"]

    for sm in submeta:
        mat_idx = sm.get("material_index")
        if mat_idx is None or not isinstance(mat_idx, int):
            continue
        if mat_idx < 0 or mat_idx >= len(mtrl_records):
            continue
        rec = mtrl_records[mat_idx]
        tex_hashes = rec.get("tex_hashes", [])
        for si, h in enumerate(tex_hashes):
            if si >= len(slot_keys):
                break
            name = resolve(h)
            if name:
                sm[slot_keys[si]] = name


def main() -> int:
    ap = argparse.ArgumentParser(description="Mercenaries 2 mesh extraction from UCFX blobs")
    ap.add_argument("blob", type=Path)
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--format", choices=("obj", "gltf"), default="obj")
    ap.add_argument("--indices", action="store_true", help="Attach triangle indices (preferred)")
    ap.add_argument("--merge-all-strm", action="store_true", help="Attempt to merge all STRM draws under GEOM")
    ap.add_argument("--stem", default="", help="Original block stem for metadata")
    ap.add_argument(
        "--per-submesh-obj",
        action="store_true",
        help="Also emit individual submeshes/NNNN.obj + index.json next to --out",
    )
    ap.add_argument(
        "--emit-scene-gltf",
        action="store_true",
        help="After --per-submesh-obj, emit mesh_scene.gltf (+ .bin) via gltf_exporter (textures optional)",
    )
    ap.add_argument(
        "--lod",
        choices=("keep-all", "dedupe-bbox", "highest-poly-per-bbox"),
        default="keep-all",
        help="LOD/damage-variant culling strategy (default: keep-all)",
    )
    ap.add_argument(
        "--texture-index",
        type=Path,
        default=None,
        help="Path to texture_index.json for resolving material→texture names",
    )
    args = ap.parse_args()

    data = args.blob.read_bytes()
    geom_off = find_tag(data, b"GEOM")

    # Structured path (with HIER transforms)
    raw_parts, submeta, touched, mtrl_records = _extract_structured_parts(data, blob_path=args.blob)

    # Resolve MTRL texture hashes to names
    if mtrl_records:
        _resolve_material_textures(data, submeta, mtrl_records, args.texture_index)

    # Apply LOD dedup
    raw_parts, submeta = _dedupe_lod(raw_parts, submeta, args.lod)

    use_structured = bool(raw_parts)
    if use_structured:
        verts, faces = merge_submeshes(raw_parts)
        if not (len(faces) >= 3 if args.indices else len(verts) >= 3):
            use_structured = False

    if use_structured:
        topology = "ucfx_structured" if args.indices else "ucfx_structured_positions"
        extra: dict[str, object] = {
            "extraction": "ucfx_structured",
            "structured": True,
            "ucfx_offsets_used": touched,
            "submesh_count": len(submeta),
            "submeshes": submeta,
        }
        if not args.indices:
            faces = None
    else:
        structured_attempt: dict[str, object] = {
            "structured": True,
            "empty": not raw_parts,
            "ucfx_offsets_used": touched,
            "submeshes": submeta,
        }
        if args.indices:
            if args.merge_all_strm:
                verts, faces, extra_fb = extract_multi_draw_merge(data, geom_off)
            else:
                verts, faces, extra_fb = extract_largest_draw(data, geom_off)
            extra = {
                "extraction": "fallback_heuristic",
                "structured_attempt": structured_attempt,
                **extra_fb,
            }
            topology = "fallback_heuristic"
            if not faces:
                topology = "vertices_only"
        else:
            verts, faces, extra_fb = extract_largest_draw(data, geom_off)
            faces = None
            extra = {
                "extraction": "fallback_heuristic",
                "structured_attempt": structured_attempt,
                **extra_fb,
            }
            topology = "fallback_heuristic_positions"

    args.out.parent.mkdir(parents=True, exist_ok=True)
    if args.format == "obj":
        write_obj(args.out, verts, faces)
    else:
        gltf_path = args.out if args.out.suffix.lower() == ".gltf" else args.out.with_suffix(".gltf")
        write_gltf_positions(gltf_path, verts, faces)

    if args.per_submesh_obj and raw_parts:
        write_per_submesh_objs(args.out.parent, raw_parts, submeta)

    if args.emit_scene_gltf:
        if not args.per_submesh_obj or not raw_parts:
            print(
                "warning: --emit-scene-gltf ignored (requires --per-submesh-obj with structured geometry)",
                file=sys.stderr,
            )
        else:
            try:
                from gltf_exporter import export_review_to_gltf
            except ImportError as exc:
                print(f"warning: glTF scene export skipped: {exc}", file=sys.stderr)
            else:
                parent = args.out.parent
                scene_stem = args.stem if args.stem else parent.name
                gltf_scene = parent / "mesh_scene.gltf"
                export_review_to_gltf(parent, gltf_scene, stem=scene_stem)
                print(f"Wrote {gltf_scene}")

    # Emit shared_textures.json for cross-block texture extraction
    if mtrl_records and args.texture_index:
        _emit_shared_textures_list(data, mtrl_records, args.texture_index, args.out.parent)

    material_indices = sorted({
        sm["material_index"] for sm in submeta
        if sm.get("material_index") is not None
    })
    transparent_count = sum(1 for sm in submeta if isinstance(sm.get("transparency_flag"), float) and sm["transparency_flag"] > 0.001)
    mesh_group_count = len({
        sm["mesh_group_id"] for sm in submeta
        if sm.get("mesh_group_id") is not None
    })

    meta = {
        "vertices": len(verts),
        "faces": len(faces) if faces else 0,
        "topology": topology,
        "stem": args.stem or None,
        "lod_mode": args.lod,
        "material_indices": material_indices,
        "transparent_count": transparent_count,
        "mesh_group_count": mesh_group_count,
        "extract": extra,
        "note": "Primary: UCFX structured PRMG STRM/IBUF via data_base; fallback: heuristic STRM/index scan.",
    }
    args.out.with_name(args.out.stem + ".meta.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")
    print(f"Wrote {args.out} ({meta['vertices']} verts, {meta['faces']} tris, {topology}, lod={args.lod})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
