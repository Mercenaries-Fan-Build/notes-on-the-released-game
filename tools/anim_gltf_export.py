#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Emit a skeletal ``.glb`` from :class:`hk_animation.AnimationIR` clips (Mercenaries 2 pipeline)."""

from __future__ import annotations

import argparse
import json
import math
import struct
from pathlib import Path
from typing import Any

import sys

_TOOLS = Path(__file__).resolve().parent
if str(_TOOLS) not in sys.path:
    sys.path.insert(0, str(_TOOLS))

from pygltflib import (
    GLTF2,
    Accessor,
    Animation,
    AnimationChannel,
    AnimationChannelTarget,
    AnimationSampler,
    Asset,
    Buffer,
    BufferView,
    Material,
    Mesh,
    Node,
    PbrMetallicRoughness,
    Primitive,
    Scene,
    Skin,
)

import numpy as np

from hk_animation import AnimationIR, TRS
from hk_anim._decompress_common import fix_quat_w_sentinel
from hk_skeleton import load_skeleton_json, unknown_skeleton_document


def _quat_to_mat3(qx: float, qy: float, qz: float, qw: float) -> np.ndarray:
    xx, yy, zz = qx * qx, qy * qy, qz * qz
    xy, xz, yz = qx * qy, qx * qz, qy * qz
    wx, wy, wz = qw * qx, qw * qy, qw * qz
    m = np.zeros((3, 3), dtype=np.float64)
    m[0, 0] = 1.0 - 2.0 * (yy + zz)
    m[0, 1] = 2.0 * (xy - wz)
    m[0, 2] = 2.0 * (xz + wy)
    m[1, 0] = 2.0 * (xy + wz)
    m[1, 1] = 1.0 - 2.0 * (xx + zz)
    m[1, 2] = 2.0 * (yz - wx)
    m[2, 0] = 2.0 * (xz - wy)
    m[2, 1] = 2.0 * (yz + wx)
    m[2, 2] = 1.0 - 2.0 * (xx + yy)
    return m


def _trs_to_mat4(tx: float, ty: float, tz: float, qx: float, qy: float, qz: float, qw: float, sx: float, sy: float, sz: float) -> np.ndarray:
    r = _quat_to_mat3(qx, qy, qz, qw)
    rs = r @ np.diag([float(sx), float(sy), float(sz)])
    m = np.eye(4, dtype=np.float64)
    m[0:3, 0:3] = rs
    m[0:3, 3] = np.array([tx, ty, tz], dtype=np.float64)
    return m


def _mat4_to_gltf_column_major(m: np.ndarray) -> list[float]:
    return [float(m[r, c]) for c in range(4) for r in range(4)]


def _quat_dot(ax: float, ay: float, az: float, aw: float, bx: float, by: float, bz: float, bw: float) -> float:
    return ax * bx + ay * by + az * bz + aw * bw


def _quat_max_deg_delta_vs_bind(
    rots_flat: list[float],
    bqx: float,
    bqy: float,
    bqz: float,
    bqw: float,
) -> float:
    """Max angular delta (degrees) between each frame quaternion and bind ``(bqx,bqy,bqz,bqw)``."""
    n = len(rots_flat) // 4
    worst = 0.0
    for i in range(n):
        qx, qy, qz, qw = rots_flat[i * 4 : i * 4 + 4]
        d = abs(_quat_dot(qx, qy, qz, qw, bqx, bqy, bqz, bqw))
        d = min(1.0, max(-1.0, d))
        ang = 2.0 * math.acos(d)
        worst = max(worst, ang)
    return math.degrees(worst)


def _compute_flat_normals(pos: np.ndarray, idx: np.ndarray) -> np.ndarray:
    """Per-vertex normals from face normals (good enough for rigid preview mesh)."""
    n = int(pos.shape[0])
    acc = np.zeros((n, 3), dtype=np.float32)
    cnt = np.zeros(n, dtype=np.int32)
    for t in range(0, int(idx.size), 3):
        i0, i1, i2 = int(idx[t]), int(idx[t + 1]), int(idx[t + 2])
        p0, p1, p2 = pos[i0], pos[i1], pos[i2]
        fn = np.cross(p1 - p0, p2 - p0)
        ln = float(np.linalg.norm(fn)) or 1.0
        fn = fn / ln
        for j in (i0, i1, i2):
            acc[j] += fn
            cnt[j] += 1
    for j in range(n):
        if cnt[j] > 0:
            acc[j] /= float(cnt[j])
        ln = float(np.linalg.norm(acc[j])) or 1.0
        acc[j] /= ln
    return acc


def _bone_dfs_order(parent_indices: list[int]) -> list[int]:
    n = len(parent_indices)
    children: list[list[int]] = [[] for _ in range(n)]
    roots: list[int] = []
    for i, p in enumerate(parent_indices):
        if p < 0 or p >= n:
            roots.append(i)
        else:
            children[p].append(i)
    if not roots:
        roots = [0]
    order: list[int] = []
    stack = list(reversed(roots))
    while stack:
        i = stack.pop()
        order.append(i)
        stack.extend(reversed(children[i]))
    return order


def _inverse_bind_matrices_from_reference_pose(parent_indices: list[int], reference_pose: list[list[float]]) -> bytes:
    n = len(parent_indices)
    locals_m: list[np.ndarray] = []
    for i in range(n):
        row = reference_pose[i]
        if len(row) < 10:
            row = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0]
        qx, qy, qz, qw = fix_quat_w_sentinel(float(row[3]), float(row[4]), float(row[5]), float(row[6]))
        q = np.array([qx, qy, qz, qw], dtype=np.float64)
        ln = float(np.linalg.norm(q)) or 1.0
        qx, qy, qz, qw = (q / ln).tolist()
        locals_m.append(_trs_to_mat4(row[0], row[1], row[2], qx, qy, qz, qw, row[7], row[8], row[9]))

    world = [np.eye(4, dtype=np.float64) for _ in range(n)]
    for i in _bone_dfs_order(parent_indices):
        p = parent_indices[i]
        if p < 0 or p >= n:
            world[i] = locals_m[i]
        else:
            world[i] = world[p] @ locals_m[i]

    out = bytearray()
    for i in range(n):
        invm = np.linalg.inv(world[i])
        out.extend(struct.pack("<16f", *_mat4_to_gltf_column_major(invm)))
    return bytes(out)


def build_skeletal_glb(
    clips: list[AnimationIR],
    *,
    character_name: str,
    classnames_json: Path | None = None,
    skeleton_json: Path | None = None,
    mesh_gltf_path: Path | None = None,
) -> GLTF2:
    if not clips:
        raise ValueError("no clips")
    n_tracks = max(len(c.bone_names) for c in clips)

    skel = load_skeleton_json(skeleton_json) if skeleton_json and skeleton_json.is_file() else None
    if not skel:
        skel = unknown_skeleton_document(n_tracks)

    skeleton_source = str(skel.get("source", ""))
    if skeleton_source == "manual":
        skeleton_status = "manual"
    elif skeleton_source in ("none_decoded", "", "ucfx_hier_unverified"):
        skeleton_status = "unknown"
    else:
        skeleton_status = "decoded"

    skel_bone_count = int(skel.get("bone_count", 0))
    n_bones = max(n_tracks, skel_bone_count) if skeleton_status != "unknown" else n_tracks

    has_real_skeleton = (
        isinstance(skel.get("parent_indices"), list)
        and isinstance(skel.get("reference_pose"), list)
        and len(skel["parent_indices"]) >= n_bones
        and len(skel["reference_pose"]) >= n_bones
        and skeleton_status != "unknown"
    )

    if not has_real_skeleton:
        skel = unknown_skeleton_document(n_tracks)
        skeleton_status = "unknown"
        n_bones = n_tracks

    parent_indices = [int(p) for p in skel["parent_indices"][:n_bones]]
    while len(parent_indices) < n_bones:
        parent_indices.append(-1)

    reference_pose: list[list[float]] = []
    raw_rp = skel.get("reference_pose") or []
    for i in range(n_bones):
        if i < len(raw_rp) and isinstance(raw_rp[i], list) and len(raw_rp[i]) >= 10:
            row = [float(x) for x in raw_rp[i][:10]]
        else:
            row = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0]
        qx, qy, qz, qw = fix_quat_w_sentinel(row[3], row[4], row[5], row[6])
        row[3], row[4], row[5], row[6] = qx, qy, qz, qw
        reference_pose.append(row)

    bone_names: list[str]
    bn = skel.get("bone_names")
    if isinstance(bn, list) and len(bn) >= n_bones and all(isinstance(x, str) for x in bn[:n_bones]):
        bone_names = [str(bn[i]) for i in range(n_bones)]
    else:
        bone_names = list(clips[0].bone_names)
        while len(bone_names) < n_bones:
            bone_names.append(f"bone_{len(bone_names)}")

    children_of: list[list[int]] = [[] for _ in range(n_bones)]
    root_indices: list[int] = []
    for i, p in enumerate(parent_indices):
        if p < 0 or p >= n_bones:
            root_indices.append(i)
        else:
            children_of[p].append(i)
    if not root_indices:
        root_indices = [0]

    blob = bytearray()
    buffer_views: list[BufferView] = []
    accessors: list[Accessor] = []

    def add_view(data: bytes, *, target: int | None = 34962) -> int:
        off = len(blob)
        blob.extend(data)
        ln = len(data)
        bvi = len(buffer_views)
        kw: dict[str, Any] = {"buffer": 0, "byteOffset": off, "byteLength": ln}
        if target is not None:
            kw["target"] = target
        buffer_views.append(BufferView(**kw))
        return bvi

    nodes: list[Node] = []
    for i in range(n_bones):
        nm = bone_names[i]
        kw: dict[str, Any] = {"name": nm}
        if children_of[i]:
            kw["children"] = children_of[i]
        rp = reference_pose[i]
        qx, qy, qz, qw = fix_quat_w_sentinel(rp[3], rp[4], rp[5], rp[6])
        ql = math.sqrt(qx * qx + qy * qy + qz * qz + qw * qw) or 1.0
        kw["translation"] = [float(rp[0]), float(rp[1]), float(rp[2])]
        kw["rotation"] = [float(qx / ql), float(qy / ql), float(qz / ql), float(qw / ql)]
        kw["scale"] = [float(rp[7]), float(rp[8]), float(rp[9])]
        nodes.append(Node(**kw))

    skins_list: list[Skin] = []
    meshes_list: list[Mesh] = []
    materials_list: list[Material] = []
    mesh_node_index: int | None = None

    if skeleton_status != "unknown":
        ibm_bytes = _inverse_bind_matrices_from_reference_pose(parent_indices, reference_pose)
        ibm_bv = add_view(ibm_bytes, target=None)
        ibm_acc = len(accessors)
        accessors.append(
            Accessor(
                bufferView=ibm_bv,
                byteOffset=0,
                componentType=5126,
                count=n_bones,
                type="MAT4",
            )
        )
        joint_nodes = list(range(n_bones))
        skins_list = [Skin(inverseBindMatrices=ibm_acc, joints=joint_nodes, skeleton=0, name=f"{character_name}_skin")]

    rigid_mesh: dict[str, Any] | None = None
    if skeleton_status != "unknown" and mesh_gltf_path is not None and mesh_gltf_path.is_file():
        from hk_mesh import load_rigid_skinned_bind0_mesh_from_gltf

        rigid_mesh = load_rigid_skinned_bind0_mesh_from_gltf(mesh_gltf_path)

    animations: list[Animation] = []
    for ci, clip in enumerate(clips):
        n_frames = len(clip.frames)
        if n_frames == 0:
            continue
        t_vals = [clip.duration * i / max(1, n_frames - 1) for i in range(n_frames)]
        times_data = struct.pack(f"<{n_frames}f", *t_vals)
        times_bv = add_view(times_data, target=None)
        times_acc = len(accessors)
        accessors.append(
            Accessor(
                bufferView=times_bv,
                byteOffset=0,
                componentType=5126,
                count=n_frames,
                type="SCALAR",
                max=[clip.duration],
                min=[0.0],
            )
        )
        channels: list[AnimationChannel] = []
        samplers: list[AnimationSampler] = []
        n_used = min(n_tracks, len(clip.frames[0]))
        gstats = {"translation_emitted": 0, "rotation_emitted": 0, "translation_skipped": 0, "rotation_skipped": 0}
        for bi in range(n_used):
            node_idx = bi
            trans: list[float] = []
            rots: list[float] = []
            for fr in clip.frames:
                tr = fr[bi] if bi < len(fr) else TRS(0, 0, 0, 0, 0, 0, 1, 1, 1, 1)
                trans.extend([tr.tx, tr.ty, tr.tz])
                rots.extend([tr.qx, tr.qy, tr.qz, tr.qw])
            br = reference_pose[bi]
            bt = (float(br[0]), float(br[1]), float(br[2]))
            bqx, bqy, bqz, bqw = fix_quat_w_sentinel(float(br[3]), float(br[4]), float(br[5]), float(br[6]))
            ql = math.sqrt(bqx * bqx + bqy * bqy + bqz * bqz + bqw * bqw) or 1.0
            bqx, bqy, bqz, bqw = bqx / ql, bqy / ql, bqz / ql, bqw / ql

            tdmax = 0.0
            for fi in range(n_frames):
                tx, ty, tz = trans[fi * 3 : fi * 3 + 3]
                tdmax = max(tdmax, abs(tx - bt[0]), abs(ty - bt[1]), abs(tz - bt[2]))
            if tdmax > 1e-4:
                tr_bv = add_view(struct.pack(f"<{n_frames * 3}f", *trans), target=None)
                tr_acc = len(accessors)
                accessors.append(
                    Accessor(
                        bufferView=tr_bv,
                        byteOffset=0,
                        componentType=5126,
                        count=n_frames,
                        type="VEC3",
                    )
                )
                si = len(samplers)
                samplers.append(
                    AnimationSampler(
                        input=times_acc,
                        output=tr_acc,
                        interpolation="LINEAR",
                    )
                )
                channels.append(
                    AnimationChannel(sampler=si, target=AnimationChannelTarget(node=node_idx, path="translation"))
                )
                gstats["translation_emitted"] += 1
            else:
                gstats["translation_skipped"] += 1

            rmax_deg = _quat_max_deg_delta_vs_bind(rots, bqx, bqy, bqz, bqw)
            if rmax_deg > 0.25:
                rq_bv = add_view(struct.pack(f"<{n_frames * 4}f", *rots), target=None)
                rq_acc = len(accessors)
                accessors.append(
                    Accessor(
                        bufferView=rq_bv,
                        byteOffset=0,
                        componentType=5126,
                        count=n_frames,
                        type="VEC4",
                    )
                )
                si2 = len(samplers)
                samplers.append(
                    AnimationSampler(
                        input=times_acc,
                        output=rq_acc,
                        interpolation="LINEAR",
                    )
                )
                channels.append(
                    AnimationChannel(sampler=si2, target=AnimationChannelTarget(node=node_idx, path="rotation"))
                )
                gstats["rotation_emitted"] += 1
            else:
                gstats["rotation_skipped"] += 1

        clip.meta["gltf_track_stats"] = gstats
        animations.append(
            Animation(name=(clip.name or f"clip_{ci}")[:120], channels=channels, samplers=samplers)
        )

    FLOAT = 5126
    UNSIGNED_BYTE = 5121
    UNSIGNED_SHORT = 5123
    UNSIGNED_INT = 5125
    ARRAY_BUFFER = 34962
    ELEMENT_ARRAY_BUFFER = 34963

    if skeleton_status != "unknown" and rigid_mesh is not None:
        pos_np = np.asarray(rigid_mesh["positions"], dtype=np.float32)
        idx_np = np.asarray(rigid_mesh["indices"], dtype=np.uint32)
        n_verts = int(pos_np.shape[0])
        if rigid_mesh.get("normals") is not None:
            nrm_np = np.asarray(rigid_mesh["normals"], dtype=np.float32)
        else:
            nrm_np = _compute_flat_normals(pos_np, idx_np)
        pos_flat = pos_np.reshape(-1).tolist()
        nrm_flat = nrm_np.reshape(-1).tolist()
        pos_bv = add_view(struct.pack(f"<{len(pos_flat)}f", *pos_flat), target=ARRAY_BUFFER)
        pos_acc_i = len(accessors)
        mn = pos_np.min(axis=0).tolist()
        mx = pos_np.max(axis=0).tolist()
        accessors.append(
            Accessor(
                bufferView=pos_bv,
                byteOffset=0,
                componentType=FLOAT,
                count=n_verts,
                type="VEC3",
                min=[float(mn[0]), float(mn[1]), float(mn[2])],
                max=[float(mx[0]), float(mx[1]), float(mx[2])],
            )
        )
        nrm_bv = add_view(struct.pack(f"<{len(nrm_flat)}f", *nrm_flat), target=ARRAY_BUFFER)
        nrm_acc_i = len(accessors)
        accessors.append(
            Accessor(
                bufferView=nrm_bv,
                byteOffset=0,
                componentType=FLOAT,
                count=n_verts,
                type="VEC3",
            )
        )
        joints_u8 = b"\x00\x00\x00\x00" * n_verts
        j_bv = add_view(joints_u8, target=ARRAY_BUFFER)
        j_acc_i = len(accessors)
        accessors.append(
            Accessor(
                bufferView=j_bv,
                byteOffset=0,
                componentType=UNSIGNED_BYTE,
                count=n_verts,
                type="VEC4",
            )
        )
        w_pack = (struct.pack("<4f", 1.0, 0.0, 0.0, 0.0) * n_verts)
        w_bv = add_view(w_pack, target=ARRAY_BUFFER)
        w_acc_i = len(accessors)
        accessors.append(
            Accessor(
                bufferView=w_bv,
                byteOffset=0,
                componentType=FLOAT,
                count=n_verts,
                type="VEC4",
            )
        )
        prim_attrs: dict[str, int] = {
            "POSITION": pos_acc_i,
            "NORMAL": nrm_acc_i,
            "JOINTS_0": j_acc_i,
            "WEIGHTS_0": w_acc_i,
        }
        uv_np = rigid_mesh.get("uvs")
        if uv_np is not None and int(uv_np.shape[0]) == n_verts:
            uv_flat = np.asarray(uv_np, dtype=np.float32).reshape(-1).tolist()
            uv_bv = add_view(struct.pack(f"<{len(uv_flat)}f", *uv_flat), target=ARRAY_BUFFER)
            uv_acc_i = len(accessors)
            accessors.append(
                Accessor(
                    bufferView=uv_bv,
                    byteOffset=0,
                    componentType=FLOAT,
                    count=n_verts,
                    type="VEC2",
                )
            )
            prim_attrs["TEXCOORD_0"] = uv_acc_i

        imx = int(idx_np.max()) if idx_np.size else 0
        if imx > 65535:
            idx_bytes = struct.pack(f"<{int(idx_np.size)}I", *idx_np.astype(np.uint32).tolist())
            idx_ct = UNSIGNED_INT
        else:
            idx_bytes = struct.pack(f"<{int(idx_np.size)}H", *idx_np.astype(np.uint16).tolist())
            idx_ct = UNSIGNED_SHORT
        idx_bv = add_view(idx_bytes, target=ELEMENT_ARRAY_BUFFER)
        idx_acc_i = len(accessors)
        accessors.append(
            Accessor(
                bufferView=idx_bv,
                byteOffset=0,
                componentType=idx_ct,
                count=int(idx_np.size),
                type="SCALAR",
            )
        )

        materials_list = [
            Material(
                name=f"{character_name}_review_mesh_mat",
                pbrMetallicRoughness=PbrMetallicRoughness(
                    baseColorFactor=[0.78, 0.78, 0.82, 1.0],
                    metallicFactor=0.05,
                    roughnessFactor=0.75,
                ),
                doubleSided=True,
            )
        ]
        meshes_list = [
            Mesh(
                name=f"{character_name}_review_mesh",
                primitives=[Primitive(attributes=prim_attrs, indices=idx_acc_i, material=0)],
            )
        ]
        mesh_node_index = len(nodes)
        nodes.append(
            Node(
                name=f"{character_name}_review_mesh",
                mesh=0,
                skin=0,
            )
        )
    elif skeleton_status != "unknown":
        pos_f = [0.0, 0.0, 0.0, 1e-4, 0.0, 0.0, 0.0, 1e-4, 0.0]
        nrm_f = [0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0]
        joints_u8 = bytes([0, 0, 0, 0] * 3)
        weights_f = [1.0, 0.0, 0.0, 0.0] * 3
        idx_u16 = [0, 1, 2]

        pos_bv = add_view(struct.pack("<9f", *pos_f), target=ARRAY_BUFFER)
        pos_acc_i = len(accessors)
        accessors.append(
            Accessor(
                bufferView=pos_bv,
                byteOffset=0,
                componentType=FLOAT,
                count=3,
                type="VEC3",
                min=[0.0, 0.0, 0.0],
                max=[1e-4, 1e-4, 0.0],
            )
        )
        nrm_bv = add_view(struct.pack("<9f", *nrm_f), target=ARRAY_BUFFER)
        nrm_acc_i = len(accessors)
        accessors.append(
            Accessor(
                bufferView=nrm_bv,
                byteOffset=0,
                componentType=FLOAT,
                count=3,
                type="VEC3",
            )
        )
        j_bv = add_view(joints_u8, target=ARRAY_BUFFER)
        j_acc_i = len(accessors)
        accessors.append(
            Accessor(
                bufferView=j_bv,
                byteOffset=0,
                componentType=UNSIGNED_BYTE,
                count=3,
                type="VEC4",
            )
        )
        w_bv = add_view(struct.pack("<12f", *weights_f), target=ARRAY_BUFFER)
        w_acc_i = len(accessors)
        accessors.append(
            Accessor(
                bufferView=w_bv,
                byteOffset=0,
                componentType=FLOAT,
                count=3,
                type="VEC4",
            )
        )
        idx_bv = add_view(struct.pack("<3H", *idx_u16), target=ELEMENT_ARRAY_BUFFER)
        idx_acc_i = len(accessors)
        accessors.append(
            Accessor(
                bufferView=idx_bv,
                byteOffset=0,
                componentType=UNSIGNED_SHORT,
                count=3,
                type="SCALAR",
            )
        )

        materials_list = [
            Material(
                name=f"{character_name}_skin_probe_mat",
                pbrMetallicRoughness=PbrMetallicRoughness(
                    baseColorFactor=[0.15, 0.65, 0.25, 0.35],
                    metallicFactor=0.0,
                    roughnessFactor=0.9,
                ),
                alphaMode="BLEND",
                doubleSided=True,
            )
        ]
        meshes_list = [
            Mesh(
                name=f"{character_name}_skin_probe",
                primitives=[
                    Primitive(
                        attributes={
                            "POSITION": pos_acc_i,
                            "NORMAL": nrm_acc_i,
                            "JOINTS_0": j_acc_i,
                            "WEIGHTS_0": w_acc_i,
                        },
                        indices=idx_acc_i,
                        material=0,
                    )
                ],
            )
        ]
        mesh_node_index = len(nodes)
        nodes.append(
            Node(
                name=f"{character_name}_skin_probe",
                mesh=0,
                skin=0,
            )
        )

    scene_nodes = list(root_indices)
    if mesh_node_index is not None:
        scene_nodes.append(mesh_node_index)

    extras: dict[str, Any] = {"skeleton_status": skeleton_status}

    gltf = GLTF2(
        asset=Asset(version="2.0", generator="mercs2_anim_gltf_export", extras=extras),
        scenes=[Scene(nodes=scene_nodes)],
        scene=0,
        nodes=nodes,
        meshes=meshes_list or None,
        materials=materials_list or None,
        skins=skins_list or None,
        animations=animations or None,
        buffers=[Buffer(byteLength=len(blob))],
        bufferViews=buffer_views,
        accessors=accessors,
    )
    gltf.set_binary_blob(bytes(blob))
    return gltf


def main() -> int:
    ap = argparse.ArgumentParser(description="Build skeletal GLB from AnimationIR JSON list")
    ap.add_argument("--ir-json", type=Path, required=True)
    ap.add_argument("--character", type=str, required=True)
    ap.add_argument("--classnames-json", type=Path, default=None)
    ap.add_argument("--skeleton-json", type=Path, default=None)
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument(
        "--fbx",
        action="store_true",
        help="Reserved — FBX skeletal export not implemented (glTF is the supported path).",
    )
    args = ap.parse_args()
    if args.fbx:
        print("warning: --fbx is not implemented; emitting glb only", file=sys.stderr)
    raw = json.loads(args.ir_json.read_text(encoding="utf-8"))
    clips: list[AnimationIR] = []
    for doc in raw:
        frames: list[list[TRS]] = []
        for fr in doc.get("frames", []):
            row = [TRS(*tuple(r)) for r in fr]
            frames.append(row)
        clips.append(
            AnimationIR(
                name=str(doc.get("name", "clip")),
                duration=float(doc.get("duration", 1.0)),
                fps=float(doc.get("fps", 30.0)),
                bone_names=list(doc.get("bone_names", [])),
                frames=frames,
                source_class=str(doc.get("source_class", "")),
                meta=dict(doc.get("meta") or {}),
            )
        )
    gltf = build_skeletal_glb(
        clips,
        character_name=args.character,
        classnames_json=args.classnames_json,
        skeleton_json=args.skeleton_json,
    )
    args.out.parent.mkdir(parents=True, exist_ok=True)
    gltf.save_binary(str(args.out))
    print(f"Wrote {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
