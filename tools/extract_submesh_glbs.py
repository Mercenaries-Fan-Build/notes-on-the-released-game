#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Extract individual submeshes from c3 cell / compound blocks as standalone GLBs.

For each review block directory that has ``submeshes/index.json``, this tool:

1. Groups submesh entries by ``texture_diffuse`` stem (the best available prop identity).
2. Exports each unique texture group as a standalone GLB via the existing ``gltf_exporter``
   machinery (one Mesh per GLB with the submesh's own geometry and embedded texture).
3. Writes ``submesh_prop_index.json`` mapping texture stems → GLB path + metadata.

Usage::

    .venv/bin/python3 tools/extract_submesh_glbs.py \\
        --block-dirs output/extracted/review/batch_vz/01304_blocks__VZ__c30682_P000_Q3.block \\
        --out output/submesh_glbs

Or from a zone asset list::

    .venv/bin/python3 tools/extract_submesh_glbs.py \\
        --asset-list output/radius_zones/pool_200m/asset_list.json \\
        --review-root output/extracted/review \\
        --out output/submesh_glbs
"""

from __future__ import annotations

import argparse
import json
import math
import struct
import sys
from collections import defaultdict
from pathlib import Path
from typing import Any

_TOOLS_DIR = Path(__file__).resolve().parent
if str(_TOOLS_DIR) not in sys.path:
    sys.path.insert(0, str(_TOOLS_DIR))

from mercs2_coords import convert_uvs_d3d_to_gltf  # noqa: E402

from pygltflib import (  # noqa: E402
    GLTF2,
    Accessor,
    Asset,
    Buffer,
    BufferView,
    Image as GLTFImage,
    Material,
    Mesh,
    Node,
    PbrMetallicRoughness,
    Primitive,
    Scene,
    Texture,
    TextureInfo,
)

FLOAT = 5126
UNSIGNED_SHORT = 5123
UNSIGNED_INT = 5125


def _parse_obj(path: Path) -> tuple[
    list[tuple[float, float, float]],
    list[tuple[float, float, float]],
    list[tuple[float, float]],
    list[tuple[int, int, int]],
]:
    """Minimal OBJ parser returning (positions, normals, uvs, faces)."""
    pos: list[tuple[float, float, float]] = []
    uvs: list[tuple[float, float]] = []
    nrm: list[tuple[float, float, float]] = []
    faces: list[tuple[int, int, int]] = []

    text = path.read_text(encoding="utf-8", errors="replace")
    for line in text.splitlines():
        if line.startswith("v ") and not line.startswith("vn") and not line.startswith("vt"):
            p = line.split()
            pos.append((float(p[1]), float(p[2]), float(p[3])))
        elif line.startswith("vt "):
            p = line.split()
            uvs.append((float(p[1]), float(p[2])))
        elif line.startswith("vn "):
            p = line.split()
            nrm.append((float(p[1]), float(p[2]), float(p[3])))
        elif line.startswith("f "):
            parts = line.split()[1:]
            if len(parts) >= 3:
                corners = []
                for tok in parts[:3]:
                    comps = tok.split("/")
                    vi = int(comps[0]) - 1 if comps[0] else 0
                    corners.append(vi)
                faces.append((corners[0], corners[1], corners[2]))

    if not uvs:
        uvs = [(0.0, 0.0)] * len(pos)
    elif len(uvs) < len(pos):
        uvs.extend([(0.0, 0.0)] * (len(pos) - len(uvs)))
    if not nrm:
        nrm = [(0.0, 1.0, 0.0)] * len(pos)
    elif len(nrm) < len(pos):
        nrm.extend([(0.0, 1.0, 0.0)] * (len(pos) - len(nrm)))

    uvs = convert_uvs_d3d_to_gltf(uvs)
    return pos, nrm, uvs, faces


def _tangent_vec4(n: tuple[float, float, float]) -> tuple[float, float, float, float]:
    """Synthesize a tangent in game LH space from normal (W=1.0)."""
    nx, ny, nz = n
    ax, ay, az = (0.0, 1.0, 0.0) if abs(ny) < 0.9 else (1.0, 0.0, 0.0)
    dot = nx * ax + ny * ay + nz * az
    tx, ty, tz = ax - dot * nx, ay - dot * ny, az - dot * nz
    ln = math.sqrt(tx * tx + ty * ty + tz * tz) or 1.0
    return (tx / ln, ty / ln, tz / ln, 1.0)


def _resolve_texture_file(texture_dir: Path, base_name: str) -> Path | None:
    for ext in (".png", ".dds", ".PNG", ".DDS"):
        p = texture_dir / f"{base_name}{ext}"
        if p.is_file():
            return p
    for p in texture_dir.glob(f"*{base_name}*.png"):
        return p
    for p in texture_dir.glob(f"*{base_name}*.dds"):
        return p
    return None


def _read_image_for_glb(path: Path) -> tuple[bytes, str]:
    suffix = path.suffix.lower()
    if suffix == ".png":
        return path.read_bytes(), "image/png"
    if suffix in (".jpg", ".jpeg"):
        return path.read_bytes(), "image/jpeg"
    if suffix == ".dds":
        from io import BytesIO
        from PIL import Image

        img = Image.open(path)
        if img.mode not in ("RGB", "RGBA"):
            img = img.convert("RGBA")
        buf = BytesIO()
        img.save(buf, format="PNG")
        return buf.getvalue(), "image/png"
    return path.read_bytes(), "image/png"


def _finite_bounds(
    mins: list[float], maxs: list[float],
) -> tuple[list[float] | None, list[float] | None]:
    for x in mins + maxs:
        if not math.isfinite(float(x)):
            return None, None
    return mins, maxs


def _pad4(b: bytearray) -> int:
    pad = (-len(b)) % 4
    b.extend(b"\x00" * pad)
    return len(b)


def _build_single_submesh_glb(
    *,
    obj_path: Path,
    texture_dir: Path,
    texture_name: str | None,
    stem: str,
    out_path: Path,
) -> bool:
    """Build a single-primitive GLB from one submesh OBJ and optional texture.

    Returns True on success, False if no geometry.
    """
    pos, nrm, uvs, faces = _parse_obj(obj_path)
    if not faces:
        return False

    tangents = [_tangent_vec4(nrm[i]) for i in range(len(pos))]

    blob = bytearray()
    buffer_views: list[BufferView] = []
    accessors: list[Accessor] = []
    images_l: list[GLTFImage] = []
    textures_l: list[Texture] = []
    materials_l: list[Material] = []

    pbr = PbrMetallicRoughness(metallicFactor=0.0, roughnessFactor=0.6)
    mat = Material(name=f"M_{stem}", pbrMetallicRoughness=pbr)
    if texture_name:
        tex_path = _resolve_texture_file(texture_dir, texture_name)
        if tex_path and tex_path.is_file():
            img_data, mime = _read_image_for_glb(tex_path)
            _pad4(blob)
            img_off = len(blob)
            blob.extend(img_data)
            bv_idx = len(buffer_views)
            buffer_views.append(BufferView(buffer=0, byteOffset=img_off, byteLength=len(img_data)))
            images_l.append(GLTFImage(bufferView=bv_idx, mimeType=mime))
            textures_l.append(Texture(source=0))
            pbr.baseColorTexture = TextureInfo(index=0, texCoord=0)
    materials_l.append(mat)

    def push_attr(
        data: bytes, count: int, ctype: int, atype: str,
        mins: list[float], maxs: list[float],
    ) -> int:
        _pad4(blob)
        off = len(blob)
        blob.extend(data)
        ln = len(data)
        bv = len(buffer_views)
        buffer_views.append(BufferView(buffer=0, byteOffset=off, byteLength=ln, target=34962))
        ac = len(accessors)
        bmin, bmax = _finite_bounds(mins, maxs)
        kw: dict[str, Any] = {
            "bufferView": bv, "byteOffset": 0, "componentType": ctype,
            "count": count, "type": atype,
        }
        if bmin is not None and bmax is not None:
            kw["min"] = bmin
            kw["max"] = bmax
        accessors.append(Accessor(**kw))
        return ac

    max_idx = max(max(a, b, c) for a, b, c in faces)
    use_u32 = max_idx > 65534
    idx_type = UNSIGNED_INT if use_u32 else UNSIGNED_SHORT
    idx_comp = "I" if use_u32 else "H"
    idx_bytes = bytearray()
    for a, b, c in faces:
        idx_bytes.extend(struct.pack("<" + idx_comp * 3, a, b, c))
    _pad4(blob)
    idx_off = len(blob)
    blob.extend(idx_bytes)
    bv_idx = len(buffer_views)
    buffer_views.append(BufferView(buffer=0, byteOffset=idx_off, byteLength=len(idx_bytes), target=34963))
    acc_idx = len(accessors)
    accessors.append(Accessor(
        bufferView=bv_idx, byteOffset=0, componentType=idx_type,
        count=len(faces) * 3, type="SCALAR", max=[int(max_idx)], min=[0],
    ))

    pos_f = b"".join(struct.pack("<fff", *p) for p in pos)
    acc_pos = push_attr(
        pos_f, len(pos), FLOAT, "VEC3",
        [min(p[j] for p in pos) for j in range(3)],
        [max(p[j] for p in pos) for j in range(3)],
    )
    nrm_f = b"".join(struct.pack("<fff", *n) for n in nrm)
    acc_nrm = push_attr(
        nrm_f, len(nrm), FLOAT, "VEC3",
        [min(n[j] for n in nrm) for j in range(3)],
        [max(n[j] for n in nrm) for j in range(3)],
    )
    tan_f = b"".join(struct.pack("<ffff", *t) for t in tangents)
    acc_tan = push_attr(
        tan_f, len(tangents), FLOAT, "VEC4",
        [min(t[j] for t in tangents) for j in range(4)],
        [max(t[j] for t in tangents) for j in range(4)],
    )
    uv_f = b"".join(struct.pack("<ff", *u) for u in uvs)
    acc_uv = push_attr(
        uv_f, len(uvs), FLOAT, "VEC2",
        [min(u[j] for u in uvs) for j in range(2)],
        [max(u[j] for u in uvs) for j in range(2)],
    )

    prim = Primitive(
        attributes={
            "POSITION": acc_pos,
            "NORMAL": acc_nrm,
            "TANGENT": acc_tan,
            "TEXCOORD_0": acc_uv,
        },
        indices=acc_idx,
        material=0,
    )

    mesh = Mesh(primitives=[prim])
    geo_node = Node(name="geometry", mesh=0)
    root_node = Node(name=stem, children=[0])

    gltf = GLTF2(
        asset=Asset(version="2.0", generator="mercs2_extract_submesh"),
        scenes=[Scene(nodes=[1])],
        scene=0,
        nodes=[geo_node, root_node],
        meshes=[mesh],
        materials=materials_l if materials_l else None,
        textures=textures_l if textures_l else None,
        images=images_l if images_l else None,
        buffers=[Buffer(byteLength=len(blob))],
        bufferViews=buffer_views,
        accessors=accessors,
    )
    gltf.set_binary_blob(bytes(blob))

    out_path.parent.mkdir(parents=True, exist_ok=True)
    gltf.save_binary(str(out_path))
    return True


def _build_multi_submesh_glb(
    *,
    entries: list[dict],
    sub_dir: Path,
    texture_dir: Path,
    stem: str,
    out_path: Path,
) -> bool:
    """Build a GLB combining multiple submesh OBJs that share the same texture group.

    Returns True on success, False if no geometry.
    """
    blob = bytearray()
    buffer_views: list[BufferView] = []
    accessors: list[Accessor] = []
    images_l: list[GLTFImage] = []
    textures_l: list[Texture] = []
    materials_l: list[Material] = []
    primitives_l: list[Primitive] = []

    texture_name = None
    for ent in entries:
        td = ent.get("texture_diffuse")
        if td:
            texture_name = td
            break

    pbr = PbrMetallicRoughness(metallicFactor=0.0, roughnessFactor=0.6)
    mat = Material(name=f"M_{stem}", pbrMetallicRoughness=pbr)
    if texture_name:
        tex_path = _resolve_texture_file(texture_dir, texture_name)
        if tex_path and tex_path.is_file():
            img_data, mime = _read_image_for_glb(tex_path)
            _pad4(blob)
            img_off = len(blob)
            blob.extend(img_data)
            bv_idx = len(buffer_views)
            buffer_views.append(BufferView(buffer=0, byteOffset=img_off, byteLength=len(img_data)))
            images_l.append(GLTFImage(bufferView=bv_idx, mimeType=mime))
            textures_l.append(Texture(source=0))
            pbr.baseColorTexture = TextureInfo(index=0, texCoord=0)
    materials_l.append(mat)

    def push_attr(
        data: bytes, count: int, ctype: int, atype: str,
        mins: list[float], maxs: list[float],
    ) -> int:
        _pad4(blob)
        off = len(blob)
        blob.extend(data)
        ln = len(data)
        bv = len(buffer_views)
        buffer_views.append(BufferView(buffer=0, byteOffset=off, byteLength=ln, target=34962))
        ac = len(accessors)
        bmin, bmax = _finite_bounds(mins, maxs)
        kw: dict[str, Any] = {
            "bufferView": bv, "byteOffset": 0, "componentType": ctype,
            "count": count, "type": atype,
        }
        if bmin is not None and bmax is not None:
            kw["min"] = bmin
            kw["max"] = bmax
        accessors.append(Accessor(**kw))
        return ac

    for ent in entries:
        obj_path = sub_dir / str(ent.get("file", ""))
        if not obj_path.is_file():
            continue
        pos, nrm, uvs, faces = _parse_obj(obj_path)
        if not faces:
            continue

        tangents = [_tangent_vec4(nrm[i]) for i in range(len(pos))]

        max_idx = max(max(a, b, c) for a, b, c in faces)
        use_u32 = max_idx > 65534
        idx_type = UNSIGNED_INT if use_u32 else UNSIGNED_SHORT
        idx_comp = "I" if use_u32 else "H"
        idx_bytes = bytearray()
        for a, b, c in faces:
            idx_bytes.extend(struct.pack("<" + idx_comp * 3, a, b, c))
        _pad4(blob)
        idx_off = len(blob)
        blob.extend(idx_bytes)
        bv_idx = len(buffer_views)
        buffer_views.append(
            BufferView(buffer=0, byteOffset=idx_off, byteLength=len(idx_bytes), target=34963),
        )
        acc_idx = len(accessors)
        accessors.append(Accessor(
            bufferView=bv_idx, byteOffset=0, componentType=idx_type,
            count=len(faces) * 3, type="SCALAR", max=[int(max_idx)], min=[0],
        ))

        pos_f = b"".join(struct.pack("<fff", *p) for p in pos)
        acc_pos = push_attr(
            pos_f, len(pos), FLOAT, "VEC3",
            [min(p[j] for p in pos) for j in range(3)],
            [max(p[j] for p in pos) for j in range(3)],
        )
        nrm_f = b"".join(struct.pack("<fff", *n) for n in nrm)
        acc_nrm = push_attr(
            nrm_f, len(nrm), FLOAT, "VEC3",
            [min(n[j] for n in nrm) for j in range(3)],
            [max(n[j] for n in nrm) for j in range(3)],
        )
        tan_f = b"".join(struct.pack("<ffff", *t) for t in tangents)
        acc_tan = push_attr(
            tan_f, len(tangents), FLOAT, "VEC4",
            [min(t[j] for t in tangents) for j in range(4)],
            [max(t[j] for t in tangents) for j in range(4)],
        )
        uv_f = b"".join(struct.pack("<ff", *u) for u in uvs)
        acc_uv = push_attr(
            uv_f, len(uvs), FLOAT, "VEC2",
            [min(u[j] for u in uvs) for j in range(2)],
            [max(u[j] for u in uvs) for j in range(2)],
        )

        primitives_l.append(Primitive(
            attributes={
                "POSITION": acc_pos, "NORMAL": acc_nrm,
                "TANGENT": acc_tan, "TEXCOORD_0": acc_uv,
            },
            indices=acc_idx,
            material=0,
        ))

    if not primitives_l:
        return False

    mesh = Mesh(primitives=primitives_l)
    geo_node = Node(name="geometry", mesh=0)
    root_node = Node(name=stem, children=[0])

    gltf = GLTF2(
        asset=Asset(version="2.0", generator="mercs2_extract_submesh"),
        scenes=[Scene(nodes=[1])],
        scene=0,
        nodes=[geo_node, root_node],
        meshes=[mesh],
        materials=materials_l if materials_l else None,
        textures=textures_l if textures_l else None,
        images=images_l if images_l else None,
        buffers=[Buffer(byteLength=len(blob))],
        bufferViews=buffer_views,
        accessors=accessors,
    )
    gltf.set_binary_blob(bytes(blob))

    out_path.parent.mkdir(parents=True, exist_ok=True)
    gltf.save_binary(str(out_path))
    return True


def _texture_stem(name: str | None) -> str:
    """Normalize a ``texture_diffuse`` value to a canonical stem."""
    if not name:
        return "_no_texture"
    return name.lower().strip()


def process_block(
    block_dir: Path,
    out_root: Path,
    *,
    index_entries: list[dict[str, Any]] | None = None,
) -> dict[str, dict[str, Any]]:
    """Process a single review block directory.

    Returns dict mapping texture_stem → prop metadata (glb_path, bbox, etc.).
    """
    sub_dir = block_dir / "submeshes"
    tex_dir = block_dir / "textures"
    idx_path = sub_dir / "index.json"

    if index_entries is None:
        if not idx_path.is_file():
            return {}
        index_entries = json.loads(idx_path.read_text(encoding="utf-8"))

    block_stem = block_dir.name
    groups: dict[str, list[dict]] = defaultdict(list)
    for ent in index_entries:
        ts = _texture_stem(ent.get("texture_diffuse"))
        groups[ts].append(ent)

    result: dict[str, dict[str, Any]] = {}

    for ts, entries in groups.items():
        if ts == "_no_texture":
            continue

        glb_name = f"{ts}.glb"
        glb_dir = out_root / ts
        glb_dir.mkdir(parents=True, exist_ok=True)
        glb_path = glb_dir / glb_name

        if len(entries) == 1:
            ent = entries[0]
            obj_file = sub_dir / str(ent.get("file", ""))
            if not obj_file.is_file():
                continue
            ok = _build_single_submesh_glb(
                obj_path=obj_file,
                texture_dir=tex_dir,
                texture_name=ent.get("texture_diffuse"),
                stem=ts,
                out_path=glb_path,
            )
        else:
            ok = _build_multi_submesh_glb(
                entries=entries,
                sub_dir=sub_dir,
                texture_dir=tex_dir,
                stem=ts,
                out_path=glb_path,
            )

        if not ok:
            continue

        all_bboxes = [ent.get("decoded_bbox") or ent.get("prmg_bbox") for ent in entries]
        merged_bbox: list[float] | None = None
        valid = [b for b in all_bboxes if b and len(b) == 6]
        if valid:
            merged_bbox = [
                min(b[0] for b in valid), min(b[1] for b in valid), min(b[2] for b in valid),
                max(b[3] for b in valid), max(b[4] for b in valid), max(b[5] for b in valid),
            ]

        translations = [
            ent.get("world_translation")
            for ent in entries
            if ent.get("world_translation")
        ]
        avg_translation: list[float] | None = None
        if translations:
            avg_translation = [
                sum(t[j] for t in translations) / len(translations)
                for j in range(3)
            ]

        result[ts] = {
            "texture_stem": ts,
            "glb_path": str(glb_path),
            "glb_relative": str(glb_path.relative_to(out_root)),
            "source_block": block_stem,
            "submesh_count": len(entries),
            "bbox": merged_bbox,
            "world_translation": avg_translation,
            "glb_size_bytes": glb_path.stat().st_size,
        }

    return result


def _locate_block_dirs_from_asset_list(
    asset_list_path: Path,
    review_root: Path,
) -> list[Path]:
    """Find review block directories referenced in an asset list JSON."""
    doc = json.loads(asset_list_path.read_text(encoding="utf-8"))
    assets = doc.get("assets", [])
    dirs: list[Path] = []
    batch = review_root / "batch_vz"

    for a in assets:
        stem = a.get("stem", "")
        if not stem:
            continue
        candidate = batch / stem
        if candidate.is_dir():
            dirs.append(candidate)
            continue
        # Try review_dir field
        rd = a.get("review_dir", "")
        if rd:
            p = Path(rd)
            if not p.is_absolute():
                p = review_root / rd
            if p.is_dir():
                dirs.append(p)
    return dirs


def _locate_c3_cell_dirs(
    cell_ids: list[int],
    review_root: Path,
) -> list[Path]:
    """Find review block directories for c3 cell IDs.

    Cell IDs are full IDs (e.g. 33883 = CELL_ID_BASE + linear).
    Directory stems use the format ``c3{cell_id - 30000:04d}``.
    """
    batch = review_root / "batch_vz"
    if not batch.is_dir():
        return []

    import re

    target_tags: set[str] = set()
    for cid in cell_ids:
        tag = f"c3{cid - 30000:04d}"
        target_tags.add(tag)

    dirs: list[Path] = []
    for d in batch.iterdir():
        if not d.is_dir():
            continue
        dl = d.name.lower()
        for tag in target_tags:
            if tag in dl and "_p000_" in dl:
                idx = d / "submeshes" / "index.json"
                if idx.is_file():
                    dirs.append(d)
                break
    return dirs


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Extract individual submesh GLBs from review block directories",
    )
    ap.add_argument(
        "--block-dirs",
        nargs="+",
        type=Path,
        default=None,
        help="Review block directories to process",
    )
    ap.add_argument(
        "--asset-list",
        type=Path,
        default=None,
        help="Zone asset_list.json (alternative to --block-dirs)",
    )
    ap.add_argument(
        "--zone-json",
        type=Path,
        default=None,
        help="Zone zone.json (to also include c3 cell dirs)",
    )
    ap.add_argument(
        "--review-root",
        type=Path,
        default=None,
        help="Review root (e.g. output/extracted/review). Required with --asset-list.",
    )
    ap.add_argument(
        "--out",
        type=Path,
        required=True,
        help="Output directory for submesh GLBs and index",
    )
    args = ap.parse_args()

    out_root = args.out.resolve()
    out_root.mkdir(parents=True, exist_ok=True)

    block_dirs: list[Path] = []

    if args.block_dirs:
        block_dirs.extend(p.resolve() for p in args.block_dirs)

    if args.asset_list:
        review_root = args.review_root
        if review_root is None:
            print("error: --review-root required with --asset-list", file=sys.stderr)
            return 1
        review_root = review_root.resolve()
        block_dirs.extend(_locate_block_dirs_from_asset_list(args.asset_list.resolve(), review_root))

    if args.zone_json:
        zone = json.loads(args.zone_json.resolve().read_text(encoding="utf-8"))
        cell_ids = zone.get("c3_cell_ids", [])
        if cell_ids:
            review_root = args.review_root
            if review_root is None:
                print("error: --review-root required with --zone-json for c3 cells", file=sys.stderr)
                return 1
            block_dirs.extend(_locate_c3_cell_dirs(cell_ids, review_root.resolve()))

    if not block_dirs:
        print("error: no block directories to process", file=sys.stderr)
        return 1

    seen = set()
    unique_dirs: list[Path] = []
    for d in block_dirs:
        key = str(d)
        if key not in seen:
            seen.add(key)
            unique_dirs.append(d)
    block_dirs = unique_dirs

    print(f"Processing {len(block_dirs)} block directories → {out_root}", flush=True)

    full_index: dict[str, dict[str, Any]] = {}
    total_glbs = 0

    for bd in block_dirs:
        result = process_block(bd, out_root)
        for ts, meta in result.items():
            if ts not in full_index:
                full_index[ts] = meta
                total_glbs += 1
            else:
                existing = full_index[ts]
                if meta["glb_size_bytes"] > existing["glb_size_bytes"]:
                    full_index[ts] = meta

    index_path = out_root / "submesh_prop_index.json"
    index_doc = {
        "description": "Per-texture-stem submesh GLB index",
        "prop_count": len(full_index),
        "props": full_index,
    }
    index_path.write_text(json.dumps(index_doc, indent=2), encoding="utf-8")

    print(
        f"Wrote {total_glbs} submesh GLBs, {len(full_index)} unique texture stems "
        f"→ {index_path}",
        flush=True,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
