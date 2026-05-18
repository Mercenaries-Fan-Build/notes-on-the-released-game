#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""UCFX mesh helpers: locate STRM / IBUF payloads and decode index strips."""

from __future__ import annotations

import math
import struct
from typing import Any, Iterator

CONTAINER_SENTINEL = 0xFFFFFFFF
CHUNK_HDR = 20

# Fallback strides when vb_len is not divisible by (max_index + 1) (e.g. padding / skin streams).
_STRUCTURED_STRIDE_CANDIDATES = (28, 24, 20, 32, 16, 12, 36, 40, 48, 56)


def u16_strip_to_tris(indices: list[int]) -> list[tuple[int, int, int]]:
    """Interpret indices as a triangle strip (D3D9-style), skipping degenerate triplets."""
    tris: list[tuple[int, int, int]] = []
    for i in range(len(indices) - 2):
        a, b, c = indices[i], indices[i + 1], indices[i + 2]
        if a == 65535 or b == 65535 or c == 65535:
            continue
        if a == b or b == c or a == c:
            continue
        if i % 2 == 0:
            tris.append((a, b, c))
        else:
            tris.append((a, c, b))
    return tris


def u16_list_to_tris(indices: list[int]) -> list[tuple[int, int, int]]:
    """Interpret indices as a triangle list (3 indices per triangle)."""
    tris: list[tuple[int, int, int]] = []
    i = 0
    while i + 2 < len(indices):
        a, b, c = indices[i], indices[i + 1], indices[i + 2]
        if a == 65535 or b == 65535 or c == 65535:
            i += 1
            continue
        tris.append((a, b, c))
        i += 3
    return tris


def unpack_u16(data: bytes, base: int, nbytes: int) -> list[int]:
    raw = data[base : base + nbytes]
    if len(raw) < nbytes:
        raw += b"\x00" * (nbytes - len(raw))
    n = len(raw) // 2
    return list(struct.unpack_from("<%dH" % n, raw, 0))


def score_index_blob(
    words: list[int],
    vert_ceiling: int,
    mode: str,
) -> tuple[int, list[tuple[int, int, int]], int]:
    """Return (score, triangles, max_index). Higher score is better."""
    if mode == "strip":
        cand = u16_strip_to_tris(words)
    elif mode == "list":
        cand = u16_list_to_tris(words)
    else:
        raise ValueError(mode)

    ceiling = min(vert_ceiling + 512, 65535)
    good = []
    mx = 0
    for a, b, c in cand:
        if a > ceiling or b > ceiling or c > ceiling:
            continue
        if a == b or b == c or a == c:
            continue
        good.append((a, b, c))
        mx = max(mx, a, b, c)

    # Prefer many triangles with modest index magnitudes
    score = len(good) * 10
    if mx > vert_ceiling + 256:
        score -= (mx - vert_ceiling) // 10
    return score, good, mx


def search_u16_index_blob(
    data: bytes,
    geom_off: int,
    vert_ceiling: int,
    window: int = 120_000,
    step: int = 256,
    nbytes: int = 8192,
    modes: tuple[str, ...] = ("strip", "list"),
) -> tuple[int | None, list[tuple[int, int, int]], str, int]:
    """
    Scan a GEOM-local window for the strongest u16 index stream.
    Returns (base_offset, triangles, mode_used, max_index).
    """
    start = max(0, geom_off - 64)
    end = min(len(data) - nbytes, start + window)
    best_score = -10**18
    best_result: tuple[int | None, list[tuple[int, int, int]], str, int] = (None, [], "none", 0)

    pos = start
    while pos <= end:
        words = unpack_u16(data, pos, nbytes)
        for mode in modes:
            score, tris, mx = score_index_blob(words, vert_ceiling, mode)
            if score > best_score:
                best_score = score
                best_result = (pos, tris, mode, mx)
        pos += step

    return best_result


def find_tag(data: bytes, tag: bytes, start: int = 0, end: int | None = None) -> int:
    if end is None:
        end = len(data)
    return data.find(tag, start, end)


def find_all(data: bytes, tag: bytes) -> list[int]:
    out: list[int] = []
    i = 0
    while True:
        j = data.find(tag, i)
        if j < 0:
            break
        out.append(j)
        i = j + 4
    return out


def read_chunk_header(data: bytes, pos: int) -> tuple[bytes, tuple[int, int, int, int]]:
    tag = data[pos : pos + 4]
    u0, u1, u2, u3 = struct.unpack_from("<IIII", data, pos + 4)
    return tag, (u0, u1, u2, u3)


def is_container(u0: int) -> bool:
    return u0 == CONTAINER_SENTINEL


def parse_strm_vb(data: bytes, strm_pos: int) -> tuple[int, int] | None:
    """First STRM child sequence: info + decl + data -> (vb_offset_field, vb_len).

    ``vb_offset_field`` is the raw ``u0`` from the ``data`` chunk (often a file-absolute
    offset into ``data``, not always ``STRM``-relative — use ``resolve_vb_base``).
    """
    if data[strm_pos : strm_pos + 4] != b"STRM":
        return None
    if not is_container(struct.unpack_from("<I", data, strm_pos + 4)[0]):
        return None
    pos = strm_pos + CHUNK_HDR
    decl_seen = False
    for _ in range(32):
        if pos + CHUNK_HDR > len(data):
            return None
        tag, u = read_chunk_header(data, pos)
        if tag == b"decl":
            decl_seen = True
        if tag == b"data" and decl_seen:
            return int(u[0]), int(u[1])
        pos += CHUNK_HDR
    return None


def parse_strm_decl_stride(data: bytes, strm_pos: int) -> int | None:
    """Read vertex stride from first ``decl`` payload under ``STRM`` (second u32)."""
    if data[strm_pos : strm_pos + 4] != b"STRM":
        return None
    if not is_container(struct.unpack_from("<I", data, strm_pos + 4)[0]):
        return None
    pos = strm_pos + CHUNK_HDR
    for _ in range(32):
        if pos + CHUNK_HDR > len(data):
            return None
        tag, u = read_chunk_header(data, pos)
        if tag == b"decl":
            doff, dlen = int(u[0]), int(u[1])
            if 8 <= dlen and doff >= 0 and doff + dlen <= len(data):
                stride = struct.unpack_from("<I", data, doff + 4)[0]
                if 8 <= stride <= 256:
                    return int(stride)
            return None
        pos += CHUNK_HDR
    return None


def resolve_vb_base(
    data: bytes,
    strm_pos: int,
    geom_off: int,
    off: int,
    ln: int,
    bbox: tuple[tuple[float, float, float], tuple[float, float, float]] | None = None,
) -> int | None:
    """Pick file offset for vertex buffer (fast heuristic; avoids O(STRMs × heavy decode))."""
    del bbox  # reserved for future scoring-based pick
    if off >= 0 and off + ln <= len(data) and off < strm_pos:
        return int(off)
    if strm_pos + off + ln <= len(data):
        return int(strm_pos + off)
    if geom_off >= 0 and geom_off + off + ln <= len(data):
        return int(geom_off + off)
    if off >= 0 and off + ln <= len(data):
        return int(off)
    return None


def find_mesh_bbox_for_geom(data: bytes, geom_off: int) -> tuple[tuple[float, float, float], tuple[float, float, float]] | None:
    """Bounding box (min_xyz, max_xyz) from mesh UCFX INFO that contains ``geom_off``."""
    if geom_off < 0:
        return None
    ucfx_list = find_all(data, b"UCFX")
    for i, uoff in enumerate(ucfx_list):
        u3 = struct.unpack_from("<I", data, uoff + 16)[0]
        if u3 < 10:
            continue
        nxt = ucfx_list[i + 1] if i + 1 < len(ucfx_list) else len(data)
        if not (uoff <= geom_off < nxt):
            continue
        u0 = struct.unpack_from("<I", data, uoff + 4)[0]
        data_base = uoff + int(u0)
        if data_base < 0 or data_base >= len(data):
            continue
        for ci in range(min(u3, 48)):
            cpos = uoff + CHUNK_HDR + ci * CHUNK_HDR
            if cpos + CHUNK_HDR > len(data):
                break
            tag = data[cpos : cpos + 4]
            if tag != b"INFO":
                continue
            c_off, c_len = struct.unpack_from("<II", data, cpos + 4)
            if c_len < 28:
                continue
            p = data_base + int(c_off)
            if p + 28 > len(data):
                continue
            mn = struct.unpack_from("<fff", data, p + 4)
            mx = struct.unpack_from("<fff", data, p + 16)
            return mn, mx
    return None


def parse_ibuf_meta(data: bytes, ibuf_pos: int) -> tuple[int, int] | None:
    """Return offset + byte length from first `data` chunk inside IBUF."""
    if data[ibuf_pos : ibuf_pos + 4] != b"IBUF":
        return None
    if not is_container(struct.unpack_from("<I", data, ibuf_pos + 4)[0]):
        return None
    i = data.find(b"data", ibuf_pos, ibuf_pos + 512)
    if i < 0:
        return None
    if i + CHUNK_HDR > len(data):
        return None
    _, u = read_chunk_header(data, i)
    return int(u[0]), int(u[1])


def _geometry_score(verts: list[tuple[float, float, float]]) -> float:
    """Score a candidate vertex run by count AND bounding-box quality.

    Prefers runs with many vertices whose extents are game-scale
    (roughly 0.05 to 500 in each axis) and free of extreme outliers.
    """
    n = len(verts)
    if n < 3:
        return float(n)

    xs = [v[0] for v in verts]
    ys = [v[1] for v in verts]
    zs = [v[2] for v in verts]
    extents = sorted([max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs)])

    min_ext = extents[0]
    med_ext = extents[1]
    max_ext = extents[2]

    # Degenerate: all vertices cluster near a point (likely noise or normals)
    if max_ext < 0.05:
        return n * 0.001

    # Very flat: two axes degenerate — penalise but less than total collapse
    if med_ext < 0.01:
        return n * 0.05

    # Extreme outlier axis: one axis >200x median, likely noise
    if med_ext > 1e-6 and max_ext / med_ext > 200:
        return n * 0.05

    # Moderate outlier: one axis >20x smallest
    if min_ext > 1e-6 and max_ext / min_ext > 50:
        return n * 0.3

    # Aspect ratio bonus: real meshes have moderate aspect ratios
    ratio = min_ext / max_ext if max_ext > 0 else 0
    aspect_bonus = 1.0 + ratio  # 1.0 (flat) to 2.0 (cube)

    return n * aspect_bonus


def _snorm16_to_world(
    ix: int,
    iy: int,
    iz: int,
    bbox: tuple[tuple[float, float, float], tuple[float, float, float]] | None,
) -> tuple[float, float, float]:
    snx = max(-32768, min(32767, ix)) / 32767.0
    sny = max(-32768, min(32767, iy)) / 32767.0
    snz = max(-32768, min(32767, iz)) / 32767.0
    if bbox is None:
        return (snx, sny, snz)
    mn, mx = bbox
    tx = (snx + 1.0) * 0.5
    ty = (sny + 1.0) * 0.5
    tz = (snz + 1.0) * 0.5
    return (
        mn[0] + tx * (mx[0] - mn[0]),
        mn[1] + ty * (mx[1] - mn[1]),
        mn[2] + tz * (mx[2] - mn[2]),
    )


def decode_positions_multi(
    blob: bytes,
    bbox: tuple[tuple[float, float, float], tuple[float, float, float]] | None = None,
    decl_stride: int | None = None,
) -> tuple[list[tuple[float, float, float]], str, int, int]:
    """Decode vertex positions: prefer snorm16 (with optional bbox remap), then f32/f16."""
    import math

    best: tuple[list[tuple[float, float, float]], str, int, int] | None = None
    best_score = -1.0

    def plausible(x: float, y: float, z: float) -> bool:
        if not all(math.isfinite(v) for v in (x, y, z)):
            return False
        if max(abs(x), abs(y), abs(z)) > 1e6:
            return False
        return abs(x) + abs(y) + abs(z) > 1e-6

    def consider(verts: list[tuple[float, float, float]], mode: str, stride: int, skip: int) -> None:
        nonlocal best, best_score
        if not verts:
            return
        sc = _geometry_score(verts)
        if sc > best_score:
            best_score = sc
            best = (verts, mode, stride, skip)

    def snorm_run(stride: int, skip: int) -> list[tuple[float, float, float]]:
        verts: list[tuple[float, float, float]] = []
        if skip >= len(blob) or stride < 6:
            return verts
        sub = blob[skip:]
        n = len(sub) // stride
        for i in range(n):
            o = i * stride
            if o + 6 > len(sub):
                break
            ix, iy, iz = struct.unpack_from("<hhh", sub, o)
            x, y, z = _snorm16_to_world(ix, iy, iz, bbox)
            if plausible(x, y, z):
                verts.append((x, y, z))
            else:
                break
        return verts

    # 1) Decl-guided snorm16 (tight search)
    strides_try: list[int] = []
    if decl_stride is not None and 8 <= decl_stride <= 256:
        strides_try.append(decl_stride)
        for delta in (-4, 4, -8, 8):
            s = decl_stride + delta
            if 8 <= s <= 256 and s not in strides_try:
                strides_try.append(s)
    else:
        strides_try = list(range(12, 68, 4))

    snorm_skips = (0, 4, 8, 12, 16, 24, 32, 48, 64, 96, 128, 160)
    if decl_stride is not None:
        snorm_skips = (0, 4, 8, 12, 16, 24, 32)

    for stride in strides_try:
        for skip in snorm_skips:
            if skip >= len(blob):
                continue
            verts = snorm_run(stride, skip)
            consider(verts, "snorm16_bbox" if bbox else "snorm16", stride, skip)

    # 2) f32 (reduced grid)
    for skip in (0, 16, 32, 64, 96, 128, 160, 192, 256):
        if skip >= len(blob):
            continue
        sub = blob[skip:]
        for stride in range(12, 72, 4):
            verts: list[tuple[float, float, float]] = []
            for i in range(len(sub) // stride):
                x, y, z = struct.unpack_from("<fff", sub, i * stride)
                if plausible(x, y, z):
                    verts.append((x, y, z))
                else:
                    break
            consider(verts, "f32", stride, skip)

    # 3) f16 vec3
    for skip in (0, 16, 32, 64, 96, 128, 160):
        if skip >= len(blob):
            continue
        sub = blob[skip:]
        for stride in (8, 12, 16, 20, 24):
            verts = []
            for i in range(len(sub) // stride):
                if i * stride + 6 > len(sub):
                    break
                x = float(struct.unpack("<e", sub[i * stride : i * stride + 2])[0])
                y = float(struct.unpack("<e", sub[i * stride + 2 : i * stride + 4])[0])
                z = float(struct.unpack("<e", sub[i * stride + 4 : i * stride + 6])[0])
                if plausible(x, y, z):
                    verts.append((x, y, z))
                else:
                    break
            consider(verts, "f16_vec3", stride, skip)

    if best is None:
        return [], "none", 0, 0
    return best


def iter_ucfx_containers(data: bytes) -> Iterator[dict[str, Any]]:
    """Yield rich UCFX containers (flat chunk table + ``data_base``).

    ``data_base = ucfx_off + u0`` from the UCFX header. All ``data`` / ``INFO``
    payload offsets under that container are relative to ``data_base``.
    """
    for ucfx_off in find_all(data, b"UCFX"):
        if ucfx_off + 20 > len(data):
            continue
        u0, _u1, _u2, u3 = struct.unpack_from("<IIII", data, ucfx_off + 4)
        if u3 < 10 or u3 > 50_000:
            continue
        if ucfx_off + 20 + u3 * CHUNK_HDR > len(data):
            continue
        data_base = ucfx_off + int(u0)
        if data_base < 0 or data_base >= len(data):
            continue
        chunks: list[tuple[bytes, tuple[int, int, int, int]]] = []
        for i in range(int(u3)):
            cpos = ucfx_off + 20 + i * CHUNK_HDR
            tag = data[cpos : cpos + 4]
            cu = struct.unpack_from("<IIII", data, cpos + 4)
            chunks.append((tag, cu))
        yield {
            "ucfx_off": ucfx_off,
            "data_base": data_base,
            "n_chunks": int(u3),
            "chunks": chunks,
        }


def _iter_geom_child_row_slices(
    chunks: list[tuple[bytes, tuple[int, int, int, int]]],
) -> Iterator[list[tuple[bytes, tuple[int, int, int, int]]]]:
    """Each GEOM container owns the next ``u3`` flat chunk rows (not recursive tree parse)."""
    ii = 0
    while ii < len(chunks):
        tag, u = chunks[ii]
        if tag == b"GEOM" and u[0] == CONTAINER_SENTINEL:
            n = int(u[3])
            if n > 0 and ii + 1 + n <= len(chunks):
                yield list(chunks[ii + 1 : ii + 1 + n])
            ii += 1 + n
        else:
            ii += 1


def parse_prmg_bbox(
    data: bytes, data_base: int, info_off_rel: int, info_len: int
) -> tuple[tuple[float, float, float], tuple[float, float, float]] | None:
    """BBox (min_xyz, max_xyz) from PRMG INFO: last 24 bytes of the 60-byte layout.

    Layout of PRMG INFO (60 bytes):
      +0..+11:  3 x u32 (flags / LOD-level)
      +12..+15: float (hash / padding — sometimes garbage)
      +16..+19: float (near zero — unused)
      +20..+23: float bounding-sphere center X
      +24..+27: float bounding-sphere center Y
      +28..+31: float bounding-sphere center Z
      +32..+35: float bounding-sphere radius
      +36..+47: float[3] bbox min XYZ
      +48..+59: float[3] bbox max XYZ
    """
    if info_len < 60:
        return None
    p = data_base + int(info_off_rel)
    if p < 0 or p + 60 > len(data):
        return None
    mn = struct.unpack_from("<fff", data, p + 36)
    mx = struct.unpack_from("<fff", data, p + 48)
    if not all(math.isfinite(v) for v in (*mn, *mx)):
        return None
    if mx[0] < mn[0] or mx[1] < mn[1] or mx[2] < mn[2]:
        return None
    return (mn, mx)


# ---------------------------------------------------------------------------
#   PRMG INFO extended fields
# ---------------------------------------------------------------------------


def parse_prmg_info_flags(
    data: bytes, data_base: int, info_off_rel: int, info_len: int
) -> dict[str, Any]:
    """Extract additional fields from the 60-byte PRMG INFO header.

    Returns:
      draw_call_class: u32 at +0 (1 = single-material, 2/3 = multi-material)
      transparency_flag: float at +16 (0.00274 = transparent/glass, -0.0 = opaque)
    """
    result: dict[str, Any] = {}
    if info_len < 60:
        return result
    p = data_base + int(info_off_rel)
    if p < 0 or p + 60 > len(data):
        return result
    result["draw_call_class"] = struct.unpack_from("<I", data, p)[0]
    result["transparency_flag"] = struct.unpack_from("<f", data, p + 16)[0]
    return result


# ---------------------------------------------------------------------------
#   PRMT — per-PRMG material / draw-call records
# ---------------------------------------------------------------------------


def parse_prmt(
    data: bytes, data_base: int, prmt_off_rel: int, prmt_len: int
) -> list[dict[str, Any]]:
    """Decode the PRMT chunk into a list of draw-call records.

    Each 16-byte record maps to one ``DrawIndexedPrimitive`` call::

        u32  material_index   — index into the container-level MTRL table
        u32  start_index      — first index in the IBUF for this draw
        u16  index_count      — number of indices to consume
        u16  base_vertex      — added to each index before VB lookup
        u16  max_vertex_index — highest referenced vertex index
        u16  vertex_span      — number of unique vertices referenced

    For single-material PRMGs (32 bytes) the two 16-byte halves are identical;
    only the first is meaningful.  For multi-material PRMGs the records describe
    contiguous ranges within a single shared IBUF.
    """
    p = data_base + int(prmt_off_rel)
    if p < 0 or p + prmt_len > len(data) or prmt_len < 16:
        return []

    n_records = prmt_len // 16
    records: list[dict[str, Any]] = []
    for ri in range(n_records):
        off = p + ri * 16
        mat_idx, start_idx = struct.unpack_from("<II", data, off)
        idx_count, base_vert, max_vert, vert_span = struct.unpack_from("<HHHH", data, off + 8)
        records.append({
            "material_index": mat_idx,
            "start_index": start_idx,
            "index_count": idx_count,
            "base_vertex": base_vert,
            "max_vertex": max_vert,
            "vertex_span": vert_span,
        })
    return records


# ---------------------------------------------------------------------------
#   MTRL — container-level material property table
# ---------------------------------------------------------------------------

_MTRL_PREAMBLE = 104  # shader hash + default color/emissive/specular floats


def parse_mtrl_raw(
    data: bytes, data_base: int,
    chunks: list[tuple[bytes, tuple[int, int, int, int]]],
) -> tuple[int, int]:
    """Return (absolute_offset, length) of the MTRL data chunk, or (0, 0)."""
    for tag, u in chunks:
        if tag == b"MTRL" and u[0] != CONTAINER_SENTINEL:
            return data_base + int(u[0]), int(u[1])
    return 0, 0


def parse_mtrl(
    data: bytes, mtrl_abs: int, mtrl_len: int,
) -> list[dict[str, Any]]:
    """Decode the MTRL chunk into per-material records.

    Each record starts with a flag word whose upper 16 bits give the number
    of texture hash slots (1-3) and whose lower bits encode material type
    flags.  The slots follow immediately as u32 asset hashes in
    **diffuse, specular, normal** order.  After the hashes, float material
    properties fill the rest of the record (specular power at prop[16],
    specular intensity at prop[17]).

    Returns a list indexed by material number (matching PRMT material_index).
    """
    if mtrl_abs <= 0 or mtrl_len < _MTRL_PREAMBLE + 8:
        return []

    mtrl = data[mtrl_abs : mtrl_abs + mtrl_len]
    if len(mtrl) < mtrl_len:
        return []

    # Locate record boundaries by scanning for flag words
    flag_offsets: list[tuple[int, int, int]] = []  # (byte_offset, tex_count, flags)
    i = _MTRL_PREAMBLE
    while i <= mtrl_len - 4:
        val = struct.unpack_from("<I", mtrl, i)[0]
        tex_count = (val >> 16) & 0xFFFF
        flags = val & 0xFFFF
        if tex_count in (1, 2, 3) and flags < 0x200:
            flag_offsets.append((i, tex_count, flags))
        i += 4

    records: list[dict[str, Any]] = []
    for ri, (off, tex_count, flags) in enumerate(flag_offsets):
        next_off = flag_offsets[ri + 1][0] if ri + 1 < len(flag_offsets) else mtrl_len

        tex_hashes: list[int] = []
        for ti in range(tex_count):
            h_off = off + 4 + ti * 4
            if h_off + 4 <= mtrl_len:
                tex_hashes.append(struct.unpack_from("<I", mtrl, h_off)[0])

        # Float properties start after the hashes
        prop_start = off + 4 + tex_count * 4
        stride = next_off - off
        prop_count = (stride - 4 - tex_count * 4) // 4
        spec_power = 0.0
        spec_intensity = 0.0
        if prop_count > 16:
            p16_off = prop_start + 16 * 4
            if p16_off + 4 <= mtrl_len:
                spec_power = struct.unpack_from("<f", mtrl, p16_off)[0]
        if prop_count > 17:
            p17_off = prop_start + 17 * 4
            if p17_off + 4 <= mtrl_len:
                spec_intensity = struct.unpack_from("<f", mtrl, p17_off)[0]

        records.append({
            "flags": (tex_count << 16) | flags,
            "tex_count": tex_count,
            "tex_hashes": tex_hashes,
            "specular_power": spec_power,
            "specular_intensity": spec_intensity,
        })
    return records


# ---------------------------------------------------------------------------
#   HIER chunk parsing — node hierarchy with per-node world transforms
# ---------------------------------------------------------------------------

_HIER_NODE_STRIDE = 176

def _mat4_mul_row_major(
    a: list[list[float]], b: list[list[float]]
) -> list[list[float]]:
    """Multiply two 4×4 row-major matrices."""
    r: list[list[float]] = [[0.0] * 4 for _ in range(4)]
    for i in range(4):
        for j in range(4):
            s = 0.0
            for k in range(4):
                s += a[i][k] * b[k][j]
            r[i][j] = s
    return r


def _read_mat4(data: bytes, off: int) -> list[list[float]]:
    """Read a 4×4 row-major float matrix, replacing non-finite values with 0."""
    m: list[list[float]] = []
    for r in range(4):
        row = list(struct.unpack_from("<4f", data, off + r * 16))
        for c in range(4):
            if not math.isfinite(row[c]):
                row[c] = 0.0
        m.append(row)
    return m


def parse_hier_world_transforms(
    data: bytes, data_base: int, hier_off_rel: int, hier_len: int
) -> list[dict[str, Any]]:
    """Decode the HIER chunk into a list of node records with accumulated world transforms.

    Each 176-byte HIER record:
      +0..+3:   u32 name hash
      +4..+5:   u16 (index a)
      +6..+7:   u16 (first-child or self-index)
      +8..+9:   u16 parent index (0xFFFF = root)
      +10..+11: u16 (sibling / flags)
      +12..+15: u32 flags
      +16..+79: 4×4 float local transform (row-major)
      +80..+143: 4×4 float inverse-bind / world rest pose
      +144..+159: float[3] tail_bbox_min + 1.0
      +160..+175: float[3] tail_bbox_max + 1.0

    Returns a list of dicts with keys:
      idx, parent, mat_local, world_transform, tail_bbox_min, tail_bbox_max
    """
    abs_base = data_base + int(hier_off_rel)
    if abs_base < 0 or abs_base + hier_len > len(data):
        return []
    n_records = hier_len // _HIER_NODE_STRIDE
    if n_records == 0:
        return []

    nodes: list[dict[str, Any]] = []
    for rec in range(n_records):
        off = abs_base + rec * _HIER_NODE_STRIDE
        parent_idx = struct.unpack_from("<H", data, off + 8)[0]
        mat_local = _read_mat4(data, off + 16)
        tail_mn = struct.unpack_from("<3f", data, off + 144)
        tail_mx = struct.unpack_from("<3f", data, off + 160)
        nodes.append({
            "idx": rec,
            "parent": parent_idx if parent_idx != 0xFFFF else -1,
            "mat_local": mat_local,
            "tail_bbox_min": tail_mn,
            "tail_bbox_max": tail_mx,
            "world_transform": None,
        })

    # Compute accumulated world transforms via parent chain
    def _get_world(idx: int, cache: dict[int, list[list[float]]]) -> list[list[float]]:
        if idx in cache:
            return cache[idx]
        n = nodes[idx]
        p = n["parent"]
        if p < 0 or p >= n_records:
            cache[idx] = [row[:] for row in n["mat_local"]]
        else:
            pw = _get_world(p, cache)
            cache[idx] = _mat4_mul_row_major(n["mat_local"], pw)
        return cache[idx]

    cache: dict[int, list[list[float]]] = {}
    for i in range(n_records):
        wt = _get_world(i, cache)
        nodes[i]["world_transform"] = wt

    return nodes


def match_prmg_to_hier_node(
    prmg_bbox: tuple[tuple[float, float, float], tuple[float, float, float]],
    hier_nodes: list[dict[str, Any]],
) -> dict[str, Any] | None:
    """Find the HIER node whose tail_bbox best matches the given PRMG local bbox."""
    matches = match_all_prmg_to_hier_nodes(prmg_bbox, hier_nodes)
    return matches[0] if matches else None


def match_all_prmg_to_hier_nodes(
    prmg_bbox: tuple[tuple[float, float, float], tuple[float, float, float]],
    hier_nodes: list[dict[str, Any]],
    threshold: float = 0.5,
) -> list[dict[str, Any]]:
    """Return *all* HIER nodes whose tail_bbox matches the PRMG local bbox.

    The game engine instances one PRMG at multiple HIER positions (e.g. four
    identical tire meshes). The best match is returned first, followed by any
    other nodes within the same tolerance of the best distance.
    """
    if not hier_nodes:
        return []
    pmn, pmx = prmg_bbox

    scored: list[tuple[float, dict[str, Any]]] = []
    for n in hier_nodes:
        hmn = n["tail_bbox_min"]
        hmx = n["tail_bbox_max"]
        d2 = 0.0
        for i in range(3):
            d2 += (hmn[i] - pmn[i]) ** 2 + (hmx[i] - pmx[i]) ** 2
        d = math.sqrt(d2)
        if d < threshold:
            scored.append((d, n))

    if not scored:
        return []

    scored.sort(key=lambda x: x[0])
    best_d = scored[0][0]
    # Accept all nodes whose bbox distance is within 5% extent + epsilon of the best
    tol = max(best_d * 0.1, 0.01)
    return [n for d, n in scored if d <= best_d + tol]


def get_world_translation(
    hier_node: dict[str, Any] | None,
) -> tuple[float, float, float]:
    """Extract the translation component from a HIER node's world transform."""
    if hier_node is None:
        return (0.0, 0.0, 0.0)
    wt = hier_node["world_transform"]
    if wt is None:
        return (0.0, 0.0, 0.0)
    return (wt[3][0], wt[3][1], wt[3][2])


def get_world_matrix_3x3(
    hier_node: dict[str, Any] | None,
) -> tuple[tuple[float, ...], ...] | None:
    """Extract the 3×3 rotation/scale portion of a HIER node's world transform.

    Returns None if the node is None or the matrix is identity-ish.
    """
    if hier_node is None:
        return None
    wt = hier_node["world_transform"]
    if wt is None:
        return None
    m = (
        (wt[0][0], wt[0][1], wt[0][2]),
        (wt[1][0], wt[1][1], wt[1][2]),
        (wt[2][0], wt[2][1], wt[2][2]),
    )
    # Check if identity (no rotation/scale needed)
    is_identity = True
    for r in range(3):
        for c in range(3):
            expected = 1.0 if r == c else 0.0
            if abs(m[r][c] - expected) > 1e-4:
                is_identity = False
                break
        if not is_identity:
            break
    return None if is_identity else m


def _bbox_of_vertices(verts: list[tuple[float, float, float]]) -> tuple[tuple[float, float, float], tuple[float, float, float]] | None:
    if not verts:
        return None
    xs = [v[0] for v in verts]
    ys = [v[1] for v in verts]
    zs = [v[2] for v in verts]
    return ((min(xs), min(ys), min(zs)), (max(xs), max(ys), max(zs)))


def _bbox_inside_ref(
    dec: tuple[tuple[float, float, float], tuple[float, float, float]],
    ref: tuple[tuple[float, float, float], tuple[float, float, float]],
    slack: float = 0.05,
) -> bool:
    (dmn, dmx) = dec
    (rmn, rmx) = ref
    for axis in range(3):
        ext = rmx[axis] - rmn[axis]
        pad = max(abs(ext) * slack, 1e-3)
        if dmn[axis] < rmn[axis] - pad or dmx[axis] > rmx[axis] + pad:
            return False
    return True


def _decode_f16_vec3_positions(
    data: bytes, vb_abs: int, n_verts: int, stride: int
) -> list[tuple[float, float, float]] | None:
    if stride < 6 or n_verts <= 0 or vb_abs < 0 or vb_abs + stride * n_verts > len(data):
        return None
    out: list[tuple[float, float, float]] = []
    for j in range(n_verts):
        o = vb_abs + j * stride
        x = float(struct.unpack_from("<e", data, o)[0])
        y = float(struct.unpack_from("<e", data, o + 2)[0])
        z = float(struct.unpack_from("<e", data, o + 4)[0])
        if not all(math.isfinite(v) for v in (x, y, z)):
            return None
        out.append((x, y, z))
    return out


def _decode_snorm16_vec3_positions(
    data: bytes, vb_abs: int, n_verts: int, stride: int, bbox: tuple[tuple[float, float, float], tuple[float, float, float]] | None
) -> list[tuple[float, float, float]] | None:
    if stride < 6 or n_verts <= 0 or vb_abs < 0 or vb_abs + stride * n_verts > len(data):
        return None
    out: list[tuple[float, float, float]] = []
    for j in range(n_verts):
        o = vb_abs + j * stride
        ix, iy, iz = struct.unpack_from("<hhh", data, o)
        out.append(_snorm16_to_world(ix, iy, iz, bbox))
    return out


def _pick_stride_structured(
    data: bytes,
    vb_abs: int,
    vb_len: int,
    n_verts: int,
    prmg_bbox: tuple[tuple[float, float, float], tuple[float, float, float]] | None,
) -> tuple[int, list[tuple[float, float, float]], str] | None:
    """Return (stride, verts, format_label) or None."""
    if n_verts <= 0 or vb_len <= 0:
        return None

    def try_one(stride: int, fmt: str, decoder: str) -> tuple[int, list[tuple[float, float, float]], str] | None:
        if vb_len < stride * n_verts:
            return None
        if decoder == "f16":
            verts = _decode_f16_vec3_positions(data, vb_abs, n_verts, stride)
        else:
            verts = _decode_snorm16_vec3_positions(data, vb_abs, n_verts, stride, prmg_bbox)
        if not verts:
            return None
        if prmg_bbox is not None:
            bb = _bbox_of_vertices(verts)
            if bb is None or not _bbox_inside_ref(bb, prmg_bbox):
                return None
        return (stride, verts, fmt)

    if vb_len % n_verts == 0:
        s = vb_len // n_verts
        if 8 <= s <= 256:
            r = try_one(s, "f16_vec3", "f16")
            if r:
                return r
            if prmg_bbox is not None:
                r2 = try_one(s, "snorm16_bbox", "snorm16")
                if r2:
                    return r2

    for s in _STRUCTURED_STRIDE_CANDIDATES:
        if vb_len % s != 0 or vb_len // s < n_verts:
            continue
        r = try_one(s, "f16_vec3", "f16")
        if r:
            return r
    if prmg_bbox is not None:
        for s in _STRUCTURED_STRIDE_CANDIDATES:
            if vb_len % s != 0 or vb_len // s < n_verts:
                continue
            r = try_one(s, "snorm16_bbox", "snorm16")
            if r:
                return r

    # No PRMG bbox or containment failed: still emit plausible f16 if stride divides vb_len.
    if vb_len % n_verts == 0:
        s = vb_len // n_verts
        if 8 <= s <= 256:
            verts = _decode_f16_vec3_positions(data, vb_abs, n_verts, s)
            if verts:
                return (s, verts, "f16_vec3_loose")
    for s in _STRUCTURED_STRIDE_CANDIDATES:
        if vb_len % s != 0 or vb_len // s < n_verts:
            continue
        verts = _decode_f16_vec3_positions(data, vb_abs, n_verts, s)
        if verts:
            return (s, verts, "f16_vec3_loose")
    return None


def classify_hier_damage_branches(
    data: bytes,
    data_base: int,
    chunks: list[tuple[bytes, tuple[int, int, int, int]]],
    hier_nodes: list[dict[str, Any]],
) -> dict[int, str]:
    """Annotate HIER nodes with SWIT switch-pair metadata.

    Returns a mapping of HIER node index → label string.  Every node gets
    a label; nothing is filtered out.

    SWIT sibling pairs are identified and labelled ``"switch_<G>_<S>"``
    where *G* is a zero-based group index and *S* is the side (``0`` or
    ``1``, corresponding to the lower and higher HIER node index within
    the pair).  Nodes that are descendants of one side inherit that side's
    label.  Nodes not under any SWIT pair get ``"shared"``.

    No assumption is made about which side represents intact vs damaged.
    That determination requires manual review.
    """
    swit_off = swit_len = None
    for tag, u in chunks:
        if tag == b"SWIT" and u[0] != CONTAINER_SENTINEL:
            swit_off, swit_len = int(u[0]), int(u[1])
            break
    if swit_off is None or swit_len is None or not hier_nodes:
        return {}

    hier_chunk = None
    for tag, u in chunks:
        if tag == b"HIER" and u[0] != CONTAINER_SENTINEL and int(u[1]) >= _HIER_NODE_STRIDE:
            hier_chunk = (int(u[0]), int(u[1]))
            break
    if hier_chunk is None:
        return {}

    abs_hier = data_base + hier_chunk[0]
    hash_to_idx: dict[int, int] = {}
    for ni in range(len(hier_nodes)):
        noff = abs_hier + ni * _HIER_NODE_STRIDE
        if noff + 4 <= len(data):
            nhash = struct.unpack_from("<I", data, noff)[0]
            hash_to_idx[nhash] = ni

    abs_swit = data_base + swit_off
    n_swit = swit_len // 4
    if abs_swit + n_swit * 4 > len(data):
        return {}
    swit_hashes = list(struct.unpack_from(f"<{n_swit}I", data, abs_swit))
    swit_node_set: set[int] = set()
    for h in swit_hashes:
        ni = hash_to_idx.get(h)
        if ni is not None:
            swit_node_set.add(ni)

    def _descendants(idx: int) -> set[int]:
        out: set[int] = set()
        for n in hier_nodes:
            if n["parent"] == idx:
                out.add(n["idx"])
                out |= _descendants(n["idx"])
        return out

    from collections import defaultdict
    parent_pairs: dict[int, list[int]] = defaultdict(list)
    for ni in swit_node_set:
        parent_pairs[hier_nodes[ni]["parent"]].append(ni)

    labels: dict[int, str] = {}
    group_idx = 0
    for _parent, nodes in sorted(parent_pairs.items()):
        if len(nodes) != 2:
            continue
        a, b = sorted(nodes)
        label_a = f"switch_{group_idx}_0"
        label_b = f"switch_{group_idx}_1"
        labels[a] = label_a
        labels[b] = label_b
        for d in _descendants(a):
            labels.setdefault(d, label_a)
        for d in _descendants(b):
            labels.setdefault(d, label_b)
        group_idx += 1

    result: dict[int, str] = {}
    for ni in range(len(hier_nodes)):
        result[ni] = labels.get(ni, "shared")
    return result


def _find_hier_chunk(
    chunks: list[tuple[bytes, tuple[int, int, int, int]]],
) -> tuple[int, int] | None:
    """Return (offset_rel, length) of the first HIER data chunk, if present."""
    for tag, u in chunks:
        if tag == b"HIER" and u[0] != CONTAINER_SENTINEL and int(u[1]) >= _HIER_NODE_STRIDE:
            return int(u[0]), int(u[1])
    return None


def parse_indx_chunk(
    data: bytes,
    data_base: int,
    chunks: list[tuple[bytes, tuple[int, int, int, int]]],
) -> list[int] | None:
    """Parse the INDX chunk inside a GEOM container.

    The INDX chunk contains N × u16 entries where N = number of MESH groups.
    Each u16 maps MESH group index → HIER node index.

    Returns a list of HIER node indices (one per MESH group), or None if
    no INDX chunk is present.
    """
    for rows in _iter_geom_child_row_slices(chunks):
        for tag, u in rows:
            if tag == b"INDX" and u[0] != CONTAINER_SENTINEL:
                indx_off = int(u[0])
                indx_len = int(u[1])
                if indx_len < 2:
                    return None
                abs_off = data_base + indx_off
                if abs_off < 0 or abs_off + indx_len > len(data):
                    return None
                n_entries = indx_len // 2
                return list(struct.unpack_from(f"<{n_entries}H", data, abs_off))
    # Also check top-level chunks (INDX may sit directly under GEOM's child rows)
    for tag, u in chunks:
        if tag == b"INDX" and u[0] != CONTAINER_SENTINEL:
            indx_off = int(u[0])
            indx_len = int(u[1])
            if indx_len < 2:
                return None
            abs_off = data_base + indx_off
            if abs_off < 0 or abs_off + indx_len > len(data):
                return None
            n_entries = indx_len // 2
            return list(struct.unpack_from(f"<{n_entries}H", data, abs_off))
    return None


def _parse_prmg_body(
    body: list[tuple[bytes, tuple[int, int, int, int]]],
) -> dict[str, Any] | None:
    """Extract VB/IB/INFO/PRMT offsets from a PRMG container's child rows."""
    prmg_info_off = prmg_info_len = 0
    prmt_off = prmt_len = 0
    vb_off = vb_len = ib_off = ib_len = 0
    decl_off = decl_len = 0
    got_vb = got_ib = False

    j = 0
    while j < len(body):
        bt, bu = body[j]
        if bt == b"INFO" and int(bu[1]) >= 56 and prmg_info_len == 0:
            prmg_info_off, prmg_info_len = int(bu[0]), int(bu[1])
            j += 1
        elif bt == b"PRMT" and bu[0] != CONTAINER_SENTINEL and prmt_len == 0:
            prmt_off, prmt_len = int(bu[0]), int(bu[1])
            j += 1
        elif bt == b"STRM" and bu[0] == CONTAINER_SENTINEL:
            nch = int(bu[3])
            if nch > 0 and j + 1 + nch <= len(body):
                strm_rows = body[j + 1 : j + 1 + nch]
                decl_seen = False
                for st, su in strm_rows:
                    if st.lower() == b"decl":
                        decl_off, decl_len = int(su[0]), int(su[1])
                        decl_seen = True
                    elif st.lower() == b"data" and decl_seen:
                        vb_off, vb_len = int(su[0]), int(su[1])
                        got_vb = True
                        break
            j += 1 + max(nch, 0)
        elif bt == b"IBUF" and bu[0] == CONTAINER_SENTINEL:
            nch = int(bu[3])
            if nch > 0 and j + 1 + nch <= len(body):
                ib_rows = body[j + 1 : j + 1 + nch]
                for it, iu in ib_rows:
                    if it.lower() == b"data":
                        ib_off, ib_len = int(iu[0]), int(iu[1])
                        got_ib = True
                        break
            j += 1 + max(nch, 0)
        else:
            j += 1

    if got_vb and got_ib and vb_len > 0 and ib_len >= 6:
        return {
            "vb_off": vb_off,
            "vb_len": vb_len,
            "ib_off": ib_off,
            "ib_len": ib_len,
            "decl_off": decl_off,
            "decl_len": decl_len,
            "prmg_info_off": prmg_info_off,
            "prmg_info_len": prmg_info_len,
            "prmt_off": prmt_off,
            "prmt_len": prmt_len,
        }
    return None


def iter_submesh_buffers(container: dict[str, Any]) -> Iterator[dict[str, Any]]:
    """Yield STRM/IBUF buffer descriptors for each ``PRMG`` under each GEOM in a UCFX container.

    Each yielded dict also includes ``mesh_group_id`` and ``mesh_draw_index``
    when the PRMG is inside a MESH container.  ``mesh_group_id`` identifies
    which MESH container the PRMG belongs to; ``mesh_draw_index`` is the
    zero-based index of the PRMG *within* that container.  Multiple PRMGs in
    one MESH are co-rendered draw calls (different material passes), **not**
    LOD alternatives.
    """
    for rows in _iter_geom_child_row_slices(container["chunks"]):
        mesh_group_id = 0
        i = 0
        while i < len(rows):
            tag, u = rows[i]

            if tag == b"MESH" and u[0] == CONTAINER_SENTINEL:
                mesh_n = int(u[3])
                if mesh_n <= 0 or i + 1 + mesh_n > len(rows):
                    i += 1
                    continue
                mesh_body = rows[i + 1 : i + 1 + mesh_n]
                i += 1 + mesh_n

                prmg_draw_idx = 0
                mi = 0
                while mi < len(mesh_body):
                    mt, mu = mesh_body[mi]
                    if mt == b"PRMG" and mu[0] == CONTAINER_SENTINEL:
                        pn = int(mu[3])
                        if pn > 0 and mi + 1 + pn <= len(mesh_body):
                            pbody = mesh_body[mi + 1 : mi + 1 + pn]
                            result = _parse_prmg_body(pbody)
                            if result is not None:
                                result["mesh_group_id"] = mesh_group_id
                                result["mesh_draw_index"] = prmg_draw_idx
                                yield result
                            prmg_draw_idx += 1
                        mi += 1 + max(pn, 0)
                    else:
                        mi += 1
                mesh_group_id += 1
                continue

            if tag == b"PRMG" and u[0] == CONTAINER_SENTINEL:
                body_n = int(u[3])
                if body_n <= 0 or i + 1 + body_n > len(rows):
                    i += 1
                    continue
                body = rows[i + 1 : i + 1 + body_n]
                i += 1 + body_n
                result = _parse_prmg_body(body)
                if result is not None:
                    yield result
                continue

            i += 1


def _apply_world_transform(
    verts: list[tuple[float, float, float]],
    translation: tuple[float, float, float],
    rotation_3x3: tuple[tuple[float, ...], ...] | None = None,
) -> list[tuple[float, float, float]]:
    """Offset (and optionally rotate) vertex positions into world space."""
    tx, ty, tz = translation
    if rotation_3x3 is not None:
        r = rotation_3x3
        return [
            (
                v[0] * r[0][0] + v[1] * r[1][0] + v[2] * r[2][0] + tx,
                v[0] * r[0][1] + v[1] * r[1][1] + v[2] * r[2][1] + ty,
                v[0] * r[0][2] + v[1] * r[1][2] + v[2] * r[2][2] + tz,
            )
            for v in verts
        ]
    if abs(tx) < 1e-6 and abs(ty) < 1e-6 and abs(tz) < 1e-6:
        return verts
    return [(v[0] + tx, v[1] + ty, v[2] + tz) for v in verts]


def decode_submesh(
    data: bytes,
    data_base: int,
    sub: dict[str, Any],
    hier_nodes: list[dict[str, Any]] | None = None,
    damage_branches: dict[int, str] | None = None,
    indx_hier_node_idx: int | None = None,
) -> tuple[list[tuple[float, float, float]], list[tuple[int, int, int]], dict[str, Any]]:
    """Decode one PRMG draw: explicit VB/IB relative to ``data_base``.

    When *indx_hier_node_idx* is provided (from the INDX chunk), it is used
    directly to look up the HIER node — no bbox matching is performed.

    When *hier_nodes* is provided without *indx_hier_node_idx*, the PRMG's
    local bbox is matched to the HIER tree and the accumulated world
    transform is applied to vertices.
    """
    vb_abs = data_base + int(sub["vb_off"])
    ib_abs = data_base + int(sub["ib_off"])
    vb_len = int(sub["vb_len"])
    ib_len = int(sub["ib_len"])
    meta: dict[str, Any] = {
        "vb_file_offset": vb_abs,
        "vb_len": vb_len,
        "ib_file_offset": ib_abs,
        "ib_len": ib_len,
    }

    if vb_abs < 0 or ib_abs < 0 or vb_abs + vb_len > len(data) or ib_abs + ib_len > len(data):
        return [], [], {**meta, "skip": "oob_buffers"}

    n_idx = ib_len // 2
    indices = list(struct.unpack_from("<%dH" % n_idx, data, ib_abs))
    if not indices:
        return [], [], {**meta, "skip": "empty_ib"}

    bad = sum(1 for x in indices if x == 65535)
    if bad > max(8, len(indices) // 10):
        return [], [], {**meta, "skip": "too_many_sentinel_indices"}

    max_idx = max(indices)
    if max_idx > 200_000:
        return [], [], {**meta, "skip": "index_out_of_range"}

    n_verts = max_idx + 1
    meta["index_max"] = max_idx
    meta["n_indices"] = len(indices)

    prmg_bbox = None
    if int(sub.get("prmg_info_len", 0)) >= 60:
        prmg_bbox = parse_prmg_bbox(data, data_base, int(sub["prmg_info_off"]), int(sub["prmg_info_len"]))

    picked = _pick_stride_structured(data, vb_abs, vb_len, n_verts, prmg_bbox)
    if picked is None:
        return [], [], {**meta, "skip": "stride_decode_failed", "prmg_bbox": prmg_bbox}

    stride, verts, fmt = picked
    meta["stride_bytes"] = stride
    meta["vertex_format"] = fmt
    meta["vertices_decoded"] = len(verts)

    # Vertex layout per stride (all f16/snorm16 formats):
    #   pos_xyz(6) + w(2) + UV(4 f16x2) @ offset 8, then stride-dependent fields:
    #   stride 20: normals(6+2pad) @ 12
    #   stride 24: D3DCOLOR(4) @ 12, normals(6+2pad) @ 16
    #   stride 28: D3DCOLOR(4) @ 12, extra(4) @ 16, normals(6+2pad) @ 20
    #   stride 32: D3DCOLOR(4) @ 12, extra(8) @ 16, normals(6+2pad) @ 24
    #   stride 36: D3DCOLOR(4) @ 12, extra(4) @ 16, normals(6+2pad) @ 20
    #   stride 40: D3DCOLOR(4) @ 12, extra(4) @ 16, normals(6+2pad) @ 24, tangents(6+2pad) @ 32
    _VERTEX_ATTR_OFFSETS: dict[int, tuple[int, int | None]] = {
        20: (12, None),
        24: (16, None),
        28: (20, None),
        32: (24, None),
        36: (20, None),
        40: (24, 32),
    }

    if stride >= 12 and fmt.startswith(("f16", "snorm16")):
        uvs: list[tuple[float, float]] = []
        for vi in range(len(verts)):
            o = vb_abs + vi * stride + 8
            if o + 4 <= len(data):
                u = float(struct.unpack_from("<e", data, o)[0])
                v = float(struct.unpack_from("<e", data, o + 2)[0])
                uvs.append((u, v))
            else:
                uvs.append((0.0, 0.0))
        meta["uvs"] = uvs

    attr_offsets = _VERTEX_ATTR_OFFSETS.get(stride)

    if attr_offsets is not None and fmt.startswith(("f16", "snorm16")):
        normal_off, tangent_off = attr_offsets

        normals: list[tuple[float, float, float]] = []
        for vi in range(len(verts)):
            o = vb_abs + vi * stride + normal_off
            if o + 6 <= len(data):
                nx = float(struct.unpack_from("<e", data, o)[0])
                ny = float(struct.unpack_from("<e", data, o + 2)[0])
                nz = float(struct.unpack_from("<e", data, o + 4)[0])
                normals.append((nx, ny, nz))
            else:
                normals.append((0.0, 1.0, 0.0))
        meta["normals"] = normals

        if tangent_off is not None:
            tangents: list[tuple[float, float, float]] = []
            for vi in range(len(verts)):
                o = vb_abs + vi * stride + tangent_off
                if o + 6 <= len(data):
                    tx = float(struct.unpack_from("<e", data, o)[0])
                    ty = float(struct.unpack_from("<e", data, o + 2)[0])
                    tz = float(struct.unpack_from("<e", data, o + 4)[0])
                    tangents.append((tx, ty, tz))
                else:
                    tangents.append((1.0, 0.0, 0.0))
            meta["tangents"] = tangents

    if prmg_bbox is not None:
        meta["prmg_bbox"] = [
            prmg_bbox[0][0],
            prmg_bbox[0][1],
            prmg_bbox[0][2],
            prmg_bbox[1][0],
            prmg_bbox[1][1],
            prmg_bbox[1][2],
        ]

    # --- Apply HIER world transform ---
    world_trans = (0.0, 0.0, 0.0)
    rot_3x3: tuple[tuple[float, ...], ...] | None = None
    all_hier_matches: list[dict[str, Any]] = []
    if hier_nodes and indx_hier_node_idx is not None:
        # INDX-based direct mapping (authoritative)
        node_map = {n["idx"]: n for n in hier_nodes}
        matched = node_map.get(indx_hier_node_idx)
        if matched is not None:
            world_trans = get_world_translation(matched)
            rot_3x3 = get_world_matrix_3x3(matched)
            meta["hier_node_idx"] = matched["idx"]
            meta["world_translation"] = list(world_trans)
            meta["hier_source"] = "indx"
            if rot_3x3 is not None:
                meta["world_rotation_3x3"] = [list(r) for r in rot_3x3]
    elif hier_nodes and prmg_bbox is not None:
        # Fallback: bbox-based heuristic matching
        all_hier_matches = match_all_prmg_to_hier_nodes(prmg_bbox, hier_nodes)
        matched = all_hier_matches[0] if all_hier_matches else None
        if matched is not None:
            world_trans = get_world_translation(matched)
            rot_3x3 = get_world_matrix_3x3(matched)
            meta["hier_node_idx"] = matched["idx"]
            meta["world_translation"] = list(world_trans)
            meta["hier_source"] = "bbox"
            if rot_3x3 is not None:
                meta["world_rotation_3x3"] = [list(r) for r in rot_3x3]
            if len(all_hier_matches) > 1:
                meta["hier_instance_nodes"] = [n["idx"] for n in all_hier_matches]

    if damage_branches and "hier_node_idx" in meta:
        meta["damage_state"] = damage_branches.get(meta["hier_node_idx"], "shared")

    if "mesh_group_id" in sub:
        meta["mesh_group_id"] = sub["mesh_group_id"]
    if "mesh_draw_index" in sub:
        meta["mesh_draw_index"] = sub["mesh_draw_index"]

    if abs(world_trans[0]) > 1e-6 or abs(world_trans[1]) > 1e-6 or abs(world_trans[2]) > 1e-6 or rot_3x3 is not None:
        verts = _apply_world_transform(verts, world_trans, rot_3x3)
        # Rotate normals/tangents by the same rotation (no translation)
        if rot_3x3 is not None:
            zero_t = (0.0, 0.0, 0.0)
            if "normals" in meta:
                meta["normals"] = _apply_world_transform(meta["normals"], zero_t, rot_3x3)
            if "tangents" in meta:
                meta["tangents"] = _apply_world_transform(meta["tangents"], zero_t, rot_3x3)

    faces = u16_strip_to_tris(indices)
    meta["faces"] = len(faces)
    if not faces:
        return [], [], {**meta, "skip": "no_tris_from_strip"}

    need = max(max(a, b, c) for a, b, c in faces) + 1
    if need > len(verts):
        return [], [], {**meta, "skip": "index_exceeds_decoded_vertices", "need": need, "have": len(verts)}

    bb = _bbox_of_vertices(verts)
    if bb:
        meta["decoded_bbox"] = [bb[0][0], bb[0][1], bb[0][2], bb[1][0], bb[1][1], bb[1][2]]

    return verts, faces, meta


def merge_submeshes(
    parts: list[tuple[list[tuple[float, float, float]], list[tuple[int, int, int]]]],
) -> tuple[list[tuple[float, float, float]], list[tuple[int, int, int]]]:
    verts: list[tuple[float, float, float]] = []
    faces: list[tuple[int, int, int]] = []
    off = 0
    for v, f in parts:
        for a, b, c in f:
            faces.append((a + off, b + off, c + off))
        verts.extend(v)
        off += len(v)
    return verts, faces

