#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Build a glTF 2.0 scene from Mercenaries 2 review output (submeshes + textures + optional mesh.meta)."""

from __future__ import annotations

import argparse
import json
import math
import struct
from pathlib import Path
from typing import Any

from pygltflib import (
    GLTF2,
    Accessor,
    Asset,
    Buffer,
    BufferView,
    Image as GLTFImage,
    Material,
    Mesh,
    Node,
    NormalMaterialTexture,
    PbrMetallicRoughness,
    Primitive,
    Scene,
    Texture,
    TextureInfo,
)

FLOAT = 5126
UNSIGNED_SHORT = 5123
UNSIGNED_INT = 5125


def _finite_accessor_bounds(
    mins: list[float],
    maxs: list[float],
) -> tuple[list[float] | None, list[float] | None]:
    """JSON (and pygltflib) reject NaN/inf; omit accessor bounds when not finite."""
    for x in mins + maxs:
        if not math.isfinite(float(x)):
            return None, None
    return mins, maxs


def _finite_matrix(mat: list[float] | None) -> list[float] | None:
    if mat is None:
        return None
    if any(not math.isfinite(float(x)) for x in mat):
        return None
    return mat
def _parse_obj(path: Path) -> tuple[
    list[tuple[float, float, float]],
    list[tuple[float, float, float]],
    list[tuple[float, float, float]],
    list[tuple[float, float]],
    list[tuple[int, int, int]],
]:
    """Return (positions, normals, tangents_placeholder, uvs, faces).

    Tangents list is empty here; filled from mesh.meta when available.
    If vn missing, normals empty. If vt missing, uvs default (0,0).
    """
    pos: list[tuple[float, float, float]] = []
    uvs: list[tuple[float, float]] = []
    nrm: list[tuple[float, float, float]] = []

    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        if line.startswith("v ") and not line.startswith("vn") and not line.startswith("vt"):
            p = line.split()
            pos.append((float(p[1]), float(p[2]), float(p[3])))
        elif line.startswith("vt "):
            p = line.split()
            uvs.append((float(p[1]), float(p[2])))
        elif line.startswith("vn "):
            p = line.split()
            nrm.append((float(p[1]), float(p[2]), float(p[3])))

    faces: list[tuple[int, int, int]] = []
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        if not line.startswith("f "):
            continue
        parts = line.split()[1:]
        if len(parts) < 3:
            continue
        corners: list[tuple[int, int, int]] = []
        for tok in parts[:3]:
            comps = tok.split("/")
            vi = int(comps[0]) - 1 if comps[0] else 0
            vti = int(comps[1]) - 1 if len(comps) > 1 and comps[1] else -1
            vni = int(comps[2]) - 1 if len(comps) > 2 and comps[2] else -1
            corners.append((vi, vti, vni))
        if len(corners) == 3:
            faces.append((corners[0][0], corners[1][0], corners[2][0]))

    if not uvs:
        uvs = [(0.0, 0.0)] * len(pos)
    elif len(uvs) != len(pos):
        uvs = _expand_face_attribute(pos, faces, uvs, (0.0, 0.0), is_uv=True)
    if not nrm:
        nrm = [(0.0, 1.0, 0.0)] * len(pos)
    elif len(nrm) != len(pos):
        nrm = _expand_face_attribute(pos, faces, nrm, (0.0, 1.0, 0.0), is_uv=False)

    return pos, nrm, [], uvs, faces


def _expand_face_attribute(
    pos: list[tuple[float, float, float]],
    faces: list[tuple[int, int, int]],
    attr: list[tuple[float, ...]],
    default: tuple[float, ...],
    *,
    is_uv: bool,
) -> list[tuple[float, ...]]:
    """Remap per-corner attribute to per-position index (best-effort)."""
    out: list[tuple[float, ...]] = [default] * len(pos)
    for a, b, c in faces:
        for vi in (a, b, c):
            if 0 <= vi < len(out) and vi < len(attr):
                out[vi] = attr[vi]
    return out


def _node_matrix_from_hier(
    trans: list[float] | None,
    rot_3x3: list[list[float]] | None,
) -> list[float] | None:
    """glTF column-major 4x4 from world_translation + row-style rot_3x3 (matches mesh_extractor)."""
    tx, ty, tz = 0.0, 0.0, 0.0
    if trans and len(trans) >= 3:
        tx, ty, tz = float(trans[0]), float(trans[1]), float(trans[2])
    if not rot_3x3 or len(rot_3x3) < 3:
        if abs(tx) < 1e-9 and abs(ty) < 1e-9 and abs(tz) < 1e-9:
            return None
        return [
            1.0, 0.0, 0.0, 0.0,
            0.0, 1.0, 0.0, 0.0,
            0.0, 0.0, 1.0, 0.0,
            tx, ty, tz, 1.0,
        ]
    r = rot_3x3
    # Column-major: columns are (r[0][0],r[1][0],r[2][0]), etc. — matches decode_submesh world apply.
    return [
        float(r[0][0]), float(r[1][0]), float(r[2][0]), 0.0,
        float(r[0][1]), float(r[1][1]), float(r[2][1]), 0.0,
        float(r[0][2]), float(r[1][2]), float(r[2][2]), 0.0,
        tx, ty, tz, 1.0,
    ]


def _resolve_texture_file(texture_dir: Path, base_name: str) -> Path | None:
    """Find PNG or DDS for logical texture name (no extension)."""
    for ext in (".png", ".dds", ".PNG", ".DDS"):
        p = texture_dir / f"{base_name}{ext}"
        if p.is_file():
            return p
    # Manifest names may differ — try glob
    for p in texture_dir.glob(f"*{base_name}*.png"):
        return p
    for p in texture_dir.glob(f"*{base_name}*.dds"):
        return p
    return None


def _tangent_vec4(
    txyz: tuple[float, float, float] | None,
    n: tuple[float, float, float],
) -> tuple[float, float, float, float]:
    nx, ny, nz = n
    if txyz:
        tx, ty, tz = txyz
        dot = tx * nx + ty * ny + tz * nz
        tx, ty, tz = tx - dot * nx, ty - dot * ny, tz - dot * nz
        ln = math.sqrt(tx * tx + ty * ty + tz * tz) or 1.0
        tx, ty, tz = tx / ln, ty / ln, tz / ln
    else:
        ax, ay, az = (0.0, 1.0, 0.0) if abs(ny) < 0.9 else (1.0, 0.0, 0.0)
        dot = nx * ax + ny * ay + nz * az
        tx, ty, tz = ax - dot * nx, ay - dot * ny, az - dot * nz
        ln = math.sqrt(tx * tx + ty * ty + tz * tz) or 1.0
        tx, ty, tz = tx / ln, ty / ln, tz / ln
    return (tx, ty, tz, 1.0)


def export_review_to_gltf(
    review_dir: Path,
    out_gltf: Path,
    *,
    stem: str | None = None,
    submeshes_dir: Path | None = None,
    textures_dir: Path | None = None,
) -> Path:
    """Write ``out_gltf`` + sibling ``.bin`` from submeshes + textures directories."""
    sub_dir = (submeshes_dir or review_dir / "submeshes").resolve()
    tex_dir = (textures_dir or review_dir / "textures").resolve()
    idx_path = sub_dir / "index.json"
    if not idx_path.is_file():
        raise FileNotFoundError(f"missing {idx_path}")
    entries: list[dict[str, Any]] = json.loads(idx_path.read_text(encoding="utf-8"))

    meta_path = review_dir / "mesh.meta.json"
    submeshes_meta: list[dict[str, Any]] | None = None
    if meta_path.is_file():
        try:
            root = json.loads(meta_path.read_text(encoding="utf-8"))
            ext = root.get("extract") or {}
            sm = ext.get("submeshes")
            if isinstance(sm, list) and len(sm) == len(entries):
                submeshes_meta = sm
        except (json.JSONDecodeError, TypeError):
            submeshes_meta = None

    stem = stem or sub_dir.parent.name
    rel_tex = "textures"

    # Collect material slots -> texture URIs (relative to glTF)
    mat_to_maps: dict[int, dict[str, str]] = {}
    for i, ent in enumerate(entries):
        mi = ent.get("material_index")
        if mi is None:
            continue
        mi = int(mi)
        if mi not in mat_to_maps:
            mat_to_maps[mi] = {}
        for key, gl_key in (
            ("texture_diffuse", "baseColor"),
            ("texture_normal", "normal"),
            ("texture_specular", "specular"),
        ):
            name = ent.get(key)
            if not name or not isinstance(name, str):
                continue
            if gl_key not in mat_to_maps[mi]:
                fpath = _resolve_texture_file(tex_dir, name)
                if fpath:
                    mat_to_maps[mi][gl_key] = f"{rel_tex}/{fpath.name}"

    blob = bytearray()
    buffer_views: list[BufferView] = []
    accessors: list[Accessor] = []
    meshes_l: list[Mesh] = []
    nodes_l: list[Node] = []
    materials_l: list[Material] = []
    textures_l: list[Texture] = []
    images_l: list[GLTFImage] = []

    uri_to_image_idx: dict[str, int] = {}

    def ensure_image(uri: str) -> int:
        if uri in uri_to_image_idx:
            return uri_to_image_idx[uri]
        idx = len(images_l)
        images_l.append(GLTFImage(uri=uri))
        textures_l.append(Texture(source=idx))
        uri_to_image_idx[uri] = idx
        return idx

    mat_index_gltf: dict[int, int] = {}
    for mi, maps in sorted(mat_to_maps.items()):
        pbr = PbrMetallicRoughness(metallicFactor=0.0, roughnessFactor=0.6)
        mat = Material(name=f"M{mi}", pbrMetallicRoughness=pbr)
        if "baseColor" in maps:
            ti = ensure_image(maps["baseColor"])
            pbr.baseColorTexture = TextureInfo(index=ti, texCoord=0)
        if "normal" in maps:
            ti = ensure_image(maps["normal"])
            mat.normalTexture = NormalMaterialTexture(index=ti, texCoord=0)
        # Specular: glTF core has no slot; keep name in extras for UE script
        if "specular" in maps:
            ti = ensure_image(maps["specular"])
            if mat.extras is None:
                mat.extras = {}
            mat.extras["mercs2_specularTextureIndex"] = int(ti)
        mat_index_gltf[mi] = len(materials_l)
        materials_l.append(mat)

    def pad4(b: bytearray) -> int:
        pad = (-len(b)) % 4
        b.extend(b"\x00" * pad)
        return len(b)

    mesh_node_indices: list[int] = []

    for i, ent in enumerate(entries):
        obj_path = sub_dir / str(ent.get("file", f"{i:04d}.obj"))
        if not obj_path.is_file():
            continue
        pos, nrm, _, uvs, faces = _parse_obj(obj_path)
        if not faces:
            continue
        sm = submeshes_meta[i] if submeshes_meta and i < len(submeshes_meta) else {}
        tang_meta = sm.get("tangents") if isinstance(sm.get("tangents"), list) else None
        tangents: list[tuple[float, float, float, float]] = []
        for vi in range(len(pos)):
            n = nrm[vi] if vi < len(nrm) else (0.0, 1.0, 0.0)
            txyz = None
            if tang_meta and vi < len(tang_meta):
                row = tang_meta[vi]
                if isinstance(row, (list, tuple)) and len(row) >= 3:
                    txyz = (float(row[0]), float(row[1]), float(row[2]))
            tangents.append(_tangent_vec4(txyz, n))

        # Indices
        max_idx = max(max(a, b, c) for a, b, c in faces)
        use_u32 = max_idx > 65534
        idx_type = UNSIGNED_INT if use_u32 else UNSIGNED_SHORT
        idx_comp = "I" if use_u32 else "H"
        idx_bytes = bytearray()
        for a, b, c in faces:
            idx_bytes.extend(struct.pack("<" + idx_comp * 3, a, b, c))
        pad4(blob)
        idx_off = len(blob)
        blob.extend(idx_bytes)
        idx_len = len(idx_bytes)
        bv_idx = len(buffer_views)
        buffer_views.append(BufferView(buffer=0, byteOffset=idx_off, byteLength=idx_len, target=34963))
        acc_idx = len(accessors)
        accessors.append(
            Accessor(
                bufferView=bv_idx,
                byteOffset=0,
                componentType=idx_type,
                count=len(faces) * 3,
                type="SCALAR",
                max=[int(max_idx)],
                min=[0],
            )
        )

        def push_attr(data: bytes, count: int, ctype: int, atype: str, mins: list[float], maxs: list[float]) -> int:
            nonlocal blob, buffer_views, accessors
            pad4(blob)
            off = len(blob)
            blob.extend(data)
            ln = len(data)
            bv = len(buffer_views)
            buffer_views.append(BufferView(buffer=0, byteOffset=off, byteLength=ln, target=34962))
            ac = len(accessors)
            bmin, bmax = _finite_accessor_bounds(mins, maxs)
            acc_kw: dict[str, Any] = {
                "bufferView": bv,
                "byteOffset": 0,
                "componentType": ctype,
                "count": count,
                "type": atype,
            }
            if bmin is not None and bmax is not None:
                acc_kw["min"] = bmin
                acc_kw["max"] = bmax
            accessors.append(Accessor(**acc_kw))
            return ac

        pos_f = b"".join(struct.pack("<fff", *p) for p in pos)
        acc_pos = push_attr(
            pos_f,
            len(pos),
            FLOAT,
            "VEC3",
            [min(p[j] for p in pos) for j in range(3)],
            [max(p[j] for p in pos) for j in range(3)],
        )
        nrm_f = b"".join(struct.pack("<fff", *n) for n in nrm)
        acc_nrm = push_attr(
            nrm_f,
            len(nrm),
            FLOAT,
            "VEC3",
            [min(n[j] for n in nrm) for j in range(3)],
            [max(n[j] for n in nrm) for j in range(3)],
        )
        tan_f = b"".join(struct.pack("<ffff", *t) for t in tangents)
        acc_tan = push_attr(
            tan_f,
            len(tangents),
            FLOAT,
            "VEC4",
            [min(t[j] for t in tangents) for j in range(4)],
            [max(t[j] for t in tangents) for j in range(4)],
        )
        uv_f = b"".join(struct.pack("<ff", *u) for u in uvs)
        acc_uv = push_attr(
            uv_f,
            len(uvs),
            FLOAT,
            "VEC2",
            [min(u[j] for u in uvs) for j in range(2)],
            [max(u[j] for u in uvs) for j in range(2)],
        )

        mi = ent.get("material_index")
        mat_id: int | None = None
        if mi is not None and int(mi) in mat_index_gltf:
            mat_id = mat_index_gltf[int(mi)]
        elif materials_l:
            mat_id = 0

        prim_kw: dict[str, Any] = {
            "attributes": {
                "POSITION": acc_pos,
                "NORMAL": acc_nrm,
                "TANGENT": acc_tan,
                "TEXCOORD_0": acc_uv,
            },
            "indices": acc_idx,
        }
        if mat_id is not None:
            prim_kw["material"] = mat_id
        prim = Primitive(**prim_kw)
        mesh_idx = len(meshes_l)
        meshes_l.append(Mesh(primitives=[prim]))

        trans = ent.get("world_translation")
        rot = None
        if sm:
            rot = sm.get("world_rotation_3x3")
        if rot is None and isinstance(ent.get("world_rotation_3x3"), list):
            rot = ent.get("world_rotation_3x3")
        mat = _finite_matrix(_node_matrix_from_hier(trans if isinstance(trans, list) else None, rot))
        node = Node(name=f"submesh_{i}", mesh=mesh_idx)
        if mat is not None:
            node.matrix = mat
        mesh_node_indices.append(len(nodes_l))
        nodes_l.append(node)

    root_children = list(range(len(mesh_node_indices)))
    # Shift indices: root is last
    root_idx = len(nodes_l)
    root = Node(name=stem, children=root_children)
    nodes_l.append(root)

    if not meshes_l:
        raise ValueError("no submesh OBJ geometry to export")

    gltf = GLTF2(
        asset=Asset(version="2.0", generator="mercs2_gltf_exporter"),
        scenes=[Scene(nodes=[root_idx])],
        scene=0,
        nodes=nodes_l,
        meshes=meshes_l,
        materials=materials_l if materials_l else None,
        textures=textures_l if textures_l else None,
        images=images_l if images_l else None,
        buffers=[Buffer(byteLength=len(blob))],
        bufferViews=buffer_views,
        accessors=accessors,
    )
    gltf.set_binary_blob(bytes(blob))
    gltf.save(str(out_gltf))
    return out_gltf


def main() -> int:
    ap = argparse.ArgumentParser(description="Export Mercenaries 2 review folder to glTF 2.0")
    ap.add_argument("--review-dir", type=Path, help="Review output dir (contains submeshes/, textures/)")
    ap.add_argument("--submesh-dir", type=Path, help="Alternate: submeshes directory (requires --texture-dir)")
    ap.add_argument("--texture-dir", type=Path, help="Textures directory when using --submesh-dir")
    ap.add_argument("--out", type=Path, required=True, help="Output .gltf path")
    ap.add_argument("--stem", type=str, default=None, help="Root node name (default: review dir name)")
    args = ap.parse_args()
    out = args.out.resolve()
    out.parent.mkdir(parents=True, exist_ok=True)
    if args.review_dir:
        rd = args.review_dir.resolve()
        export_review_to_gltf(rd, out, stem=args.stem)
    elif args.submesh_dir and args.texture_dir:
        sub = args.submesh_dir.resolve()
        tex = args.texture_dir.resolve()
        export_review_to_gltf(
            sub.parent,
            out,
            stem=args.stem,
            submeshes_dir=sub,
            textures_dir=tex,
        )
    else:
        ap.error("need --review-dir or both --submesh-dir and --texture-dir")
    print(f"Wrote {out} + {out.with_suffix('.bin').name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
