#!/usr/bin/env python3
"""Minimal binary-FBX reader (FBX 7100-7700) — extract mesh geometry, no deps
beyond numpy + zlib.

Parses the FBX node tree (Kaydara binary container) and pulls each `Geometry`
node's Vertices / PolygonVertexIndex / LayerElementNormal / LayerElementUV into a
triangulated universal mesh (`pos`/`nrm`/`uv`/`tris`), one per geometry "part".
This is the FBX→universal step for the model-import pipeline (feeds
`gltf_to_ucfx_model.py`). The russian-transport-heli FBX is binary FBX 7400.

Usage:
    fbx_reader.py <model.fbx> [--out-dir DIR]   # writes <part>.npz per geometry
"""
from __future__ import annotations

import argparse
import struct
import sys
import zlib
from pathlib import Path

import numpy as np

_ARR = {"f": ("<f", 4), "d": ("<d", 8), "l": ("<q", 8), "i": ("<i", 4), "b": ("<b", 1)}


class FbxParser:
    def __init__(self, data: bytes):
        self.d = data
        if data[:18] != b"Kaydara FBX Binary":
            raise ValueError("not a binary FBX")
        self.version = struct.unpack_from("<I", data, 23)[0]
        self.u64 = self.version >= 7500

    def _read_prop(self, pos: int):
        d = self.d
        t = chr(d[pos]); pos += 1
        if t == "Y":
            return struct.unpack_from("<h", d, pos)[0], pos + 2
        if t == "C":
            return bool(d[pos]), pos + 1
        if t == "I":
            return struct.unpack_from("<i", d, pos)[0], pos + 4
        if t == "F":
            return struct.unpack_from("<f", d, pos)[0], pos + 4
        if t == "D":
            return struct.unpack_from("<d", d, pos)[0], pos + 8
        if t == "L":
            return struct.unpack_from("<q", d, pos)[0], pos + 8
        if t in _ARR:
            length, enc, comp_len = struct.unpack_from("<III", d, pos); pos += 12
            raw = d[pos:pos + comp_len]; pos += comp_len
            if enc == 1:
                raw = zlib.decompress(raw)
            fmt, _sz = _ARR[t]
            return np.frombuffer(raw, dtype=np.dtype(fmt), count=length), pos
        if t in "SR":
            length = struct.unpack_from("<I", d, pos)[0]; pos += 4
            v = d[pos:pos + length]; pos += length
            return (v.decode("utf-8", "replace") if t == "S" else v), pos
        raise ValueError(f"unknown FBX property type {t!r} at {pos}")

    def _read_node(self, pos: int):
        """Return (node, new_pos); node is None for the null terminator record."""
        d = self.d
        if self.u64:
            end_off, num_props, _plen = struct.unpack_from("<QQQ", d, pos); pos += 24
        else:
            end_off, num_props, _plen = struct.unpack_from("<III", d, pos); pos += 12
        name_len = d[pos]; pos += 1
        if end_off == 0:  # null record (list terminator)
            return None, pos
        name = d[pos:pos + name_len].decode("ascii", "replace"); pos += name_len
        props = []
        for _ in range(num_props):
            v, pos = self._read_prop(pos)
            props.append(v)
        children = []
        while pos < end_off:
            child, pos = self._read_node(pos)
            if child is None:
                break
            children.append(child)
        return {"name": name, "props": props, "children": children}, end_off

    def parse(self):
        pos = 27
        nodes = []
        n = len(self.d)
        while pos < n - 16:
            node, pos = self._read_node(pos)
            if node is None:
                break
            nodes.append(node)
        return nodes


def _child(node, name):
    for c in node["children"]:
        if c["name"] == name:
            return c
    return None


def _children(node, name):
    return [c for c in node["children"] if c["name"] == name]


def _str_prop(node, default=""):
    for p in node["props"]:
        if isinstance(p, str):
            return p
    return default


def extract_geometries(nodes):
    """Yield dicts {name, pos(Nx3), nrm(Nx3 or None), uv(Nx2 or None), tris(Mx3)}."""
    objects = None
    for n in nodes:
        if n["name"] == "Objects":
            objects = n
            break
    if objects is None:
        return
    for geo in _children(objects, "Geometry"):
        verts_node = _child(geo, "Vertices")
        idx_node = _child(geo, "PolygonVertexIndex")
        if verts_node is None or idx_node is None:
            continue
        verts = np.asarray(verts_node["props"][0], dtype=np.float64).reshape(-1, 3)
        poly = np.asarray(idx_node["props"][0], dtype=np.int64)

        # Triangulate polygons (negative index = last corner of a polygon, ~idx).
        tris = []
        corners = []  # per-corner control-point index, parallel to a flat corner stream
        cur = []
        for ci, raw in enumerate(poly):
            real = (~raw) if raw < 0 else raw
            cur.append((ci, int(real)))
            if raw < 0:
                for k in range(1, len(cur) - 1):
                    tris.append((cur[0], cur[k], cur[k + 1]))
                cur = []
        # Build per-corner attribute streams (normals/uv are usually ByPolygonVertex).
        nrm = _layer(geo, "LayerElementNormal", "Normals", poly, verts.shape[0], dim=3)
        uv = _layer(geo, "LayerElementUV", "UV", poly, verts.shape[0], dim=2)

        # Emit a triangle-soup mesh (3 unique corners per tri); welding can come later.
        out_pos, out_nrm, out_uv, out_tris = [], [], [], []
        for tri in tris:
            base = len(out_pos)
            for (corner_i, cp) in tri:
                out_pos.append(verts[cp])
                out_nrm.append(nrm[corner_i] if nrm is not None else (0.0, 0.0, 1.0))
                out_uv.append(uv[corner_i] if uv is not None else (0.0, 0.0))
            out_tris.append((base, base + 1, base + 2))
        yield {
            "name": _str_prop(geo, f"geom_{geo['props'][0] if geo['props'] else 'x'}"),
            "pos": np.asarray(out_pos, dtype=np.float32),
            "nrm": np.asarray(out_nrm, dtype=np.float32),
            "uv": np.asarray(out_uv, dtype=np.float32),
            "tris": np.asarray(out_tris, dtype=np.uint32),
        }


def _layer(geo, layer_name, array_name, poly, n_verts, dim):
    """Expand a LayerElement (normals/uv) to a per-corner array aligned with poly."""
    layer = _child(geo, layer_name)
    if layer is None:
        return None
    arr_node = _child(layer, array_name)
    if arr_node is None:
        return None
    arr = np.asarray(arr_node["props"][0], dtype=np.float32).reshape(-1, dim)
    mapping = _str_prop(_child(layer, "MappingInformationType") or {"props": [""], "children": []})
    ref = _str_prop(_child(layer, "ReferenceInformationType") or {"props": [""], "children": []})
    idx_name = "UVIndex" if layer_name == "LayerElementUV" else (array_name + "Index")
    idx_node = _child(layer, idx_name)
    indices = np.asarray(idx_node["props"][0], dtype=np.int64) if idx_node is not None else None

    n_corners = len(poly)
    if mapping == "ByPolygonVertex":
        if ref == "IndexToDirect" and indices is not None:
            return arr[indices]
        return arr[:n_corners]
    if mapping == "ByVertex" or mapping == "ByVertice":
        # per control-point → expand to corners via poly (decoding negatives)
        cp = np.where(poly < 0, ~poly, poly)
        if ref == "IndexToDirect" and indices is not None:
            return arr[indices[cp]]
        return arr[cp]
    # AllSame or unknown → broadcast first
    return np.repeat(arr[:1], n_corners, axis=0)


def main() -> int:
    ap = argparse.ArgumentParser(description="Extract meshes from a binary FBX")
    ap.add_argument("fbx", type=Path)
    ap.add_argument("--out-dir", type=Path, default=None)
    args = ap.parse_args()

    parser = FbxParser(args.fbx.read_bytes())
    print(f"FBX version {parser.version} ({'u64' if parser.u64 else 'u32'} offsets)")
    nodes = parser.parse()
    parts = list(extract_geometries(nodes))
    print(f"{len(parts)} geometry part(s):")
    if args.out_dir:
        args.out_dir.mkdir(parents=True, exist_ok=True)
    for i, p in enumerate(parts):
        bb_min = p["pos"].min(0) if len(p["pos"]) else np.zeros(3)
        bb_max = p["pos"].max(0) if len(p["pos"]) else np.zeros(3)
        nm = p["name"].split("::")[-1] or f"part{i}"
        print(f"  [{i}] {nm[:40]:40} verts={len(p['pos']):7} tris={len(p['tris']):7} "
              f"bbox=[{bb_min[0]:.1f},{bb_min[1]:.1f},{bb_min[2]:.1f}]..[{bb_max[0]:.1f},{bb_max[1]:.1f},{bb_max[2]:.1f}]")
        if args.out_dir:
            safe = "".join(c if c.isalnum() or c in "_-" else "_" for c in nm) or f"part{i}"
            np.savez(args.out_dir / f"{i:02d}_{safe}.npz",
                     pos=p["pos"], nrm=p["nrm"], uv=p["uv"], tris=p["tris"])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
