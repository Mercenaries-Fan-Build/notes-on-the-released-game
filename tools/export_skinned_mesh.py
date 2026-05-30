#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Export one skinned character mesh block to a skeletal GLB (JOINTS_0 / WEIGHTS_0).

Reads HIER bind pose + inverse bind matrices and per-vertex influences from the mesh
STRM vertex buffer (``SKIN`` UCFX containers mark skinned PRMG draws; weights live in VB).
"""

from __future__ import annotations

import argparse
import json
import math
import struct
import sys
from pathlib import Path
from typing import Any

_TOOLS = Path(__file__).resolve().parent
if str(_TOOLS) not in sys.path:
    sys.path.insert(0, str(_TOOLS))

from pygltflib import (
    GLTF2,
    Accessor,
    Asset,
    Buffer,
    BufferView,
    Mesh,
    Node,
    Primitive,
    Scene,
    Skin,
)

from texture_streaming_index import MESH_TYPE_HASH, iter_block_entries
from ucfx_mesh_codec import (
    CHUNK_HDR,
    _find_hier_chunk,
    decode_submesh,
    decode_skin_chunk,
    find_skin_chunks_in_ucfx,
    iter_submesh_buffers,
    iter_ucfx_containers,
    parse_hier_inverse_bind_matrices,
    parse_hier_world_transforms,
    skin_layout_from_decl,
    decode_prmg_skin_influences,
)
from mercs2_coords import convert_uvs_d3d_to_gltf


def _mat4_column_major_to_trs(m: list[float]) -> tuple[list[float], list[float], list[float]]:
    """Decompose glTF column-major mat4 into T, unit quaternion (x,y,z,w), S."""
    # Column vectors: X axis = m[0], m[1], m[2]; translation = m[12], m[13], m[14]
    tx, ty, tz = m[12], m[13], m[14]
    sx = math.sqrt(m[0] ** 2 + m[1] ** 2 + m[2] ** 2) or 1.0
    sy = math.sqrt(m[4] ** 2 + m[5] ** 2 + m[6] ** 2) or 1.0
    sz = math.sqrt(m[8] ** 2 + m[9] ** 2 + m[10] ** 2) or 1.0
    r00, r01, r02 = m[0] / sx, m[1] / sx, m[2] / sx
    r10, r11, r12 = m[4] / sy, m[5] / sy, m[6] / sy
    r20, r21, r22 = m[8] / sz, m[9] / sz, m[10] / sz
    trace = r00 + r11 + r22
    if trace > 0:
        s = 0.5 / math.sqrt(trace + 1.0)
        qw = 0.25 / s
        qx = (r12 - r21) * s
        qy = (r20 - r02) * s
        qz = (r01 - r10) * s
    elif r00 > r11 and r00 > r22:
        s = 2.0 * math.sqrt(1.0 + r00 - r11 - r22)
        qw = (r12 - r21) / s
        qx = 0.25 * s
        qy = (r01 + r10) / s
        qz = (r20 + r02) / s
    elif r11 > r22:
        s = 2.0 * math.sqrt(1.0 + r11 - r00 - r22)
        qw = (r20 - r02) / s
        qx = (r01 + r10) / s
        qy = 0.25 * s
        qz = (r02 + r12) / s
    else:
        s = 2.0 * math.sqrt(1.0 + r22 - r00 - r11)
        qw = (r01 - r10) / s
        qx = (r20 + r02) / s
        qy = (r02 + r12) / s
        qz = 0.25 * s
    ql = math.sqrt(qx * qx + qy * qy + qz * qz + qw * qw) or 1.0
    return [tx, ty, tz], [qx / ql, qy / ql, qz / ql, qw / ql], [sx, sy, sz]


def _pick_skinned_submesh(
    data: bytes,
    container: dict[str, Any],
    *,
    hier_node_count: int,
) -> tuple[dict[str, Any], dict[str, Any], dict[str, Any]] | None:
    """Return ``(sub, skin_decoded, decode_meta)`` for the best skinned PRMG draw."""
    db = container["data_base"]
    best: tuple[int, dict[str, Any], dict[str, Any], dict[str, Any]] | None = None

    skin_by_vb: dict[tuple[int, int], dict[str, Any]] = {}
    for skin_meta in find_skin_chunks_in_ucfx(
        data, container["ucfx_off"], db, container["n_chunks"]
    ):
        dec = decode_skin_chunk(data, db, skin_meta, max_bone_index=hier_node_count - 1)
        if dec is None:
            continue
        prmg = dec["prmg"]
        skin_by_vb[(int(prmg["vb_off"]), int(prmg["ib_off"]))] = dec

    for sub in iter_submesh_buffers(container):
        key = (int(sub["vb_off"]), int(sub["ib_off"]))
        skin_dec = skin_by_vb.get(key)
        verts, tris, meta = decode_submesh(data, db, sub)
        if not verts or not tris:
            continue
        stats = skin_dec["stats"] if skin_dec else {}
        multi = int(stats.get("multi_influence_vertices", 0))
        if skin_dec is None:
            layout = skin_layout_from_decl(
                data,
                db,
                int(sub.get("decl_off", 0)),
                int(sub.get("decl_len", 0)),
                int(meta.get("stride_bytes", 0)),
            )
            if layout is None:
                continue
            idx_off, w_off = layout
            joints, weights, stats = decode_prmg_skin_influences(
                data,
                int(meta["vb_file_offset"]),
                int(meta["stride_bytes"]),
                len(verts),
                indices_offset=idx_off,
                weights_offset=w_off,
                max_bone_index=hier_node_count - 1,
            )
            skin_dec = {"joints": joints, "weights": weights, "stats": stats, "prmg": sub}
            multi = int(stats.get("multi_influence_vertices", 0))
        score = len(verts) if multi > 0 else 0
        if best is None or score > best[0]:
            best = (score, sub, skin_dec, meta)

    if best is None or best[0] == 0:
        return None
    _, sub, skin_dec, meta = best
    return sub, skin_dec, meta


def _build_glb(
    name: str,
    positions: list[tuple[float, float, float]],
    normals: list[tuple[float, float, float]],
    uvs: list[tuple[float, float]],
    faces: list[tuple[int, int, int]],
    joints: list[tuple[int, int, int, int]],
    weights: list[tuple[float, float, float, float]],
    hier_nodes: list[dict[str, Any]],
    ibm_col_major: list[list[float]],
    out_path: Path,
) -> dict[str, Any]:
    """Write a minimal skinned GLB; return summary stats."""
    buffer_views: list[BufferView] = []
    accessors: list[Accessor] = []
    blob = bytearray()

    def add_view(raw: bytes, target: int | None) -> int:
        off = len(blob)
        blob.extend(raw)
        while len(blob) % 4:
            blob.append(0)
        kw: dict[str, Any] = {"buffer": 0, "byteOffset": off, "byteLength": len(raw)}
        if target is not None:
            kw["target"] = target
        buffer_views.append(BufferView(**kw))
        return len(buffer_views) - 1

    ARRAY = 34962
    ELEMENT = 34963
    FLOAT = 5126
    UNSIGNED_BYTE = 5121
    UNSIGNED_SHORT = 5123

    pos_flat = [c for v in positions for c in v]
    pos_bv = add_view(struct.pack(f"<{len(pos_flat)}f", *pos_flat), ARRAY)
    pos_acc = len(accessors)
    accessors.append(
        Accessor(
            bufferView=pos_bv,
            componentType=FLOAT,
            count=len(positions),
            type="VEC3",
            min=[min(pos_flat[0::3]), min(pos_flat[1::3]), min(pos_flat[2::3])],
            max=[max(pos_flat[0::3]), max(pos_flat[1::3]), max(pos_flat[2::3])],
        )
    )

    nrm_flat = [c for v in normals for c in v]
    nrm_bv = add_view(struct.pack(f"<{len(nrm_flat)}f", *nrm_flat), ARRAY)
    nrm_acc = len(accessors)
    accessors.append(
        Accessor(bufferView=nrm_bv, componentType=FLOAT, count=len(normals), type="VEC3")
    )

    uv_gltf = convert_uvs_d3d_to_gltf(uvs)
    uv_flat = [c for v in uv_gltf for c in v]
    uv_bv = add_view(struct.pack(f"<{len(uv_flat)}f", *uv_flat), ARRAY)
    uv_acc = len(accessors)
    accessors.append(
        Accessor(bufferView=uv_bv, componentType=FLOAT, count=len(uv_gltf), type="VEC2")
    )

    j_raw = b"".join(bytes(j) for j in joints)
    j_bv = add_view(j_raw, ARRAY)
    j_acc = len(accessors)
    accessors.append(
        Accessor(bufferView=j_bv, componentType=UNSIGNED_BYTE, count=len(joints), type="VEC4")
    )

    w_flat = [c for w in weights for c in w]
    w_bv = add_view(struct.pack(f"<{len(w_flat)}f", *w_flat), ARRAY)
    w_acc = len(accessors)
    accessors.append(
        Accessor(bufferView=w_bv, componentType=FLOAT, count=len(weights), type="VEC4")
    )

    idx = [i for tri in faces for i in tri]
    mx = max(idx) if idx else 0
    if mx > 65535:
        idx_bytes = struct.pack(f"<{len(idx)}I", *idx)
        idx_ct = 5125
    else:
        idx_bytes = struct.pack(f"<{len(idx)}H", *idx)
        idx_ct = UNSIGNED_SHORT
    idx_bv = add_view(idx_bytes, ELEMENT)
    idx_acc = len(accessors)
    accessors.append(Accessor(bufferView=idx_bv, componentType=idx_ct, count=len(idx), type="SCALAR"))

    nodes: list[Node] = []
    child_lists: dict[int, list[int]] = {}
    for i, n in enumerate(hier_nodes):
        p = int(n["parent"])
        if p >= 0:
            child_lists.setdefault(p, []).append(i)
        kw: dict[str, Any] = {"name": f"node_{i}"}
        ml = n.get("mat_local")
        if ml is not None:
            cm = [
                ml[0][0], ml[1][0], ml[2][0], 0.0,
                ml[0][1], ml[1][1], ml[2][1], 0.0,
                ml[0][2], ml[1][2], ml[2][2], 0.0,
                ml[3][0], ml[3][1], ml[3][2], 1.0,
            ]
            t, q, s = _mat4_column_major_to_trs(cm)
            kw["translation"] = t
            kw["rotation"] = q
            kw["scale"] = s
        nodes.append(Node(**kw))
    for p, ch in child_lists.items():
        nodes[p].children = ch

    ibm_bv = add_view(struct.pack(f"<{len(ibm_col_major) * 16}f", *(c for m in ibm_col_major for c in m)), None)
    ibm_acc = len(accessors)
    accessors.append(
        Accessor(bufferView=ibm_bv, componentType=FLOAT, count=len(ibm_col_major), type="MAT4")
    )

    joint_nodes = list(range(len(hier_nodes)))
    skins = [Skin(inverseBindMatrices=ibm_acc, joints=joint_nodes, skeleton=0, name=f"{name}_skin")]

    mesh = Mesh(
        name=f"{name}_mesh",
        primitives=[
            Primitive(
                attributes={
                    "POSITION": pos_acc,
                    "NORMAL": nrm_acc,
                    "TEXCOORD_0": uv_acc,
                    "JOINTS_0": j_acc,
                    "WEIGHTS_0": w_acc,
                },
                indices=idx_acc,
            )
        ],
    )

    mesh_node_idx = len(nodes)
    nodes.append(Node(name=f"{name}_mesh_node", mesh=0, skin=0))

    gltf = GLTF2(
        asset=Asset(version="2.0", generator="mercs2-export_skinned_mesh"),
        scene=0,
        scenes=[Scene(nodes=[mesh_node_idx])],
        nodes=nodes,
        meshes=[mesh],
        skins=skins,
        accessors=accessors,
        bufferViews=buffer_views,
        buffers=[Buffer(byteLength=len(blob))],
    )
    gltf.set_binary_blob(bytes(blob))
    out_path.parent.mkdir(parents=True, exist_ok=True)
    gltf.save_binary(str(out_path))

    wsums = [sum(weights[i]) for i in range(len(weights))]
    return {
        "vertex_count": len(positions),
        "triangle_count": len(faces),
        "bone_count": len(hier_nodes),
        "weight_sum_min": min(wsums) if wsums else 0.0,
        "weight_sum_max": max(wsums) if wsums else 0.0,
        "multi_influence_vertices": sum(1 for w in weights if w[1] > 1e-6 or w[2] > 1e-6),
    }


def export_block(
    block_path: Path,
    out_glb: Path,
    *,
    asset_name: str | None = None,
) -> dict[str, Any]:
    data = block_path.read_bytes()
    name = asset_name or block_path.stem

    mesh_container: dict[str, Any] | None = None
    for _asset_hash, type_hash, off, _sz in iter_block_entries(data):
        if type_hash != MESH_TYPE_HASH:
            continue
        if data[off : off + 4] != b"UCFX":
            continue
        for c in iter_ucfx_containers(data):
            if c["ucfx_off"] == off:
                mesh_container = c
                break
        if mesh_container is not None:
            break

    if mesh_container is None:
        raise ValueError(f"no mesh UCFX in {block_path}")

    db = mesh_container["data_base"]
    hier_chunk = _find_hier_chunk(mesh_container["chunks"])
    if hier_chunk is None:
        raise ValueError("no HIER chunk")
    hier_off, hier_len = hier_chunk
    hier_nodes = parse_hier_world_transforms(data, db, hier_off, hier_len)
    if not hier_nodes:
        raise ValueError("empty HIER")

    picked = _pick_skinned_submesh(data, mesh_container, hier_node_count=len(hier_nodes))
    if picked is None:
        raise ValueError("no skinned PRMG with multi-bone weights found")

    sub, skin_dec, meta = picked
    verts, tris, _meta2 = decode_submesh(data, db, sub)
    joints = skin_dec["joints"]
    weights = skin_dec["weights"]
    if len(joints) != len(verts):
        raise ValueError(f"joints {len(joints)} != vertices {len(verts)}")

    normals = meta.get("normals") or [(0.0, 1.0, 0.0)] * len(verts)
    uvs = meta.get("uvs") or [(0.0, 0.0)] * len(verts)
    ibm = parse_hier_inverse_bind_matrices(data, db, hier_off, hier_len)

    summary = _build_glb(
        name,
        verts,
        normals,
        uvs,
        tris,
        joints,
        weights,
        hier_nodes,
        ibm,
        out_glb,
    )
    summary["block"] = str(block_path)
    summary["skin_stats"] = skin_dec.get("stats", {})
    summary["mesh_group_id"] = sub.get("mesh_group_id")
    summary["skeleton_status"] = "decoded"
    return summary


def main() -> int:
    ap = argparse.ArgumentParser(description="Export skinned mesh GLB from one decompressed block")
    ap.add_argument("--block", type=Path, required=True, help="Decompressed .block.bin")
    ap.add_argument("--out", type=Path, required=True, help="Output .glb path")
    ap.add_argument("--name", type=str, default=None, help="Asset name prefix in glTF")
    ap.add_argument("--report", type=Path, default=None, help="Optional JSON summary path")
    args = ap.parse_args()

    summary = export_block(args.block.resolve(), args.out.resolve(), asset_name=args.name)
    print(json.dumps(summary, indent=2))
    if args.report:
        args.report.write_text(json.dumps(summary, indent=2), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
