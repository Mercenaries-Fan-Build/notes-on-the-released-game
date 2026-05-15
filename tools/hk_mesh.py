#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Load triangle mesh data from review ``mesh_scene.gltf`` + ``mesh_scene.bin``.

Havok ``hkxMesh`` / ``hkaMeshBinding`` inside carved animation ``.hkx`` slices rarely expose
enough virtual fixups for ``locate_objects_by_class`` — so animation GLBs embed review
geometry as a **rigid bind** (100% weight on joint 0) for preview / scale sanity.
"""

from __future__ import annotations

import struct
from pathlib import Path
from typing import Any

import numpy as np
from pygltflib import GLTF2


def _component_nbytes(component_type: int) -> int:
    return {5120: 1, 5121: 1, 5122: 2, 5123: 2, 5125: 4, 5126: 4}[int(component_type)]


def _type_components(ty: str) -> int:
    return {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}[ty]


def _prim_position_accessor_index(prim: Any) -> int | None:
    attrs = prim.attributes
    if attrs is None:
        return None
    pos = getattr(attrs, "POSITION", None)
    if pos is None and isinstance(attrs, dict):
        pos = attrs.get("POSITION")
    if pos is None:
        return None
    return int(pos)


def _read_accessor_float32(
    gltf: GLTF2,
    blob: bytes,
    acc_idx: int,
) -> np.ndarray:
    acc = gltf.accessors[acc_idx]
    bv = gltf.bufferViews[acc.bufferView]
    off = int(bv.byteOffset) + int(acc.byteOffset or 0)
    n = int(acc.count)
    comps = _type_components(acc.type)
    el = _component_nbytes(acc.componentType) * comps
    raw = blob[off : off + n * el]
    if int(acc.componentType) != 5126:
        raise ValueError(f"expected FLOAT accessor, got {acc.componentType}")
    return np.frombuffer(raw, dtype=np.float32).reshape(n, comps)


def _read_accessor_indices(
    gltf: GLTF2,
    blob: bytes,
    acc_idx: int,
) -> np.ndarray:
    acc = gltf.accessors[acc_idx]
    bv = gltf.bufferViews[acc.bufferView]
    off = int(bv.byteOffset) + int(acc.byteOffset or 0)
    n = int(acc.count)
    ct = int(acc.componentType)
    if ct == 5123:  # UNSIGNED_SHORT
        return np.frombuffer(blob[off : off + n * 2], dtype=np.uint16)
    if ct == 5125:  # UNSIGNED_INT
        return np.frombuffer(blob[off : off + n * 4], dtype=np.uint32)
    if ct == 5121:  # UNSIGNED_BYTE
        return np.frombuffer(blob[off : off + n], dtype=np.uint8)
    raise ValueError(f"unsupported index componentType {ct}")


def load_rigid_skinned_bind0_mesh_from_gltf(gltf_path: Path) -> dict[str, Any] | None:
    """
    Load the largest indexed triangle mesh from ``mesh_scene.gltf``.

    Returns dict with:
      ``positions`` (N,3) float32, ``normals`` (N,3) or None, ``uvs`` (N,2) or None,
      ``indices`` (T,) uint32, ``vertex_count``, ``triangle_count``, ``source``.
    """
    if not gltf_path.is_file():
        return None
    gltf = GLTF2().load(str(gltf_path))
    if not gltf.buffers or not gltf.bufferViews or not gltf.accessors or not gltf.meshes:
        return None
    buf0 = gltf.buffers[0]
    if not buf0.uri:
        return None
    bin_path = gltf_path.parent / buf0.uri
    if not bin_path.is_file():
        return None
    blob = bin_path.read_bytes()

    best: tuple[int, int, int, int | None, int | None, int | None] | None = None
    # (neg_count, mesh_i, prim_i, pos_acc, nrm_acc, uv_acc)
    for mi, mesh in enumerate(gltf.meshes or []):
        for pi, prim in enumerate(mesh.primitives or []):
            pos_a = _prim_position_accessor_index(prim)
            if pos_a is None:
                continue
            n = int(gltf.accessors[pos_a].count)
            attrs = prim.attributes
            nrm_a = None
            uv_a = None
            if attrs is not None:
                nrm = getattr(attrs, "NORMAL", None)
                if nrm is None and isinstance(attrs, dict):
                    nrm = attrs.get("NORMAL")
                if nrm is not None:
                    nrm_a = int(nrm)
                uv = getattr(attrs, "TEXCOORD_0", None)
                if uv is None and isinstance(attrs, dict):
                    uv = attrs.get("TEXCOORD_0")
                if uv is not None:
                    uv_a = int(uv)
            key = (-n, mi, pi, pos_a, nrm_a, uv_a)
            if best is None or key < best:
                best = key

    if best is None:
        return None
    _neg_n, mi, pi, pos_acc, nrm_acc, uv_acc = best
    mesh = gltf.meshes[mi]
    prim = mesh.primitives[pi]
    if prim.indices is None:
        return None

    pos = _read_accessor_float32(gltf, blob, pos_acc).astype(np.float32, copy=False)
    n_verts = int(pos.shape[0])
    normals: np.ndarray | None
    if nrm_acc is not None:
        normals = _read_accessor_float32(gltf, blob, int(nrm_acc)).astype(np.float32, copy=False)
        if normals.shape[0] != n_verts:
            normals = None
    else:
        normals = None
    uvs: np.ndarray | None
    if uv_acc is not None:
        uvs = _read_accessor_float32(gltf, blob, int(uv_acc)).astype(np.float32, copy=False)
        if uvs.shape[0] != n_verts:
            uvs = None
    else:
        uvs = None

    idx = _read_accessor_indices(gltf, blob, int(prim.indices)).astype(np.uint32, copy=False)
    # Promote uint8/16 indices to uint32 for downstream struct packing flexibility
    tri_count = int(idx.size // 3)

    return {
        "positions": np.ascontiguousarray(pos),
        "normals": np.ascontiguousarray(normals) if normals is not None else None,
        "uvs": np.ascontiguousarray(uvs) if uvs is not None else None,
        "indices": np.ascontiguousarray(idx),
        "vertex_count": n_verts,
        "triangle_count": tri_count,
        "source": str(gltf_path.resolve()),
        "bind_mode": "rigid_joint0",
    }


def mesh_skin_sidecar_dict(mesh: dict[str, Any]) -> dict[str, Any]:
    """Extra fields merged into ``mesh_skin.json`` (does not replace skinning arrays)."""
    return {
        "review_mesh_vertex_count": int(mesh["vertex_count"]),
        "review_mesh_triangle_count": int(mesh["triangle_count"]),
        "review_mesh_source_gltf": mesh.get("source", ""),
        "review_mesh_bind_mode": mesh.get("bind_mode", ""),
    }
