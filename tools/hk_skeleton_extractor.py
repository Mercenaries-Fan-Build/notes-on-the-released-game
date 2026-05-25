#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Extract ``hkaSkeleton`` metadata from Mercs2 Havok-bearing ``*.block.bin`` slices.

``briefing_job`` / kit blocks often embed several contiguous ``Havok-5.5.0-r1``
packfiles.  Virtual fixups are frequently incomplete on carved slices, so this
module prefers **packfile object pointers** when ``locate_objects_by_class`` finds
``hkaSkeleton``, and otherwise returns ``None`` so callers can fall back to
:class:`hk_skeleton.default_skeleton_document`.
"""

from __future__ import annotations

import argparse
import json
import math
import re
import struct
import sys
import tempfile
from pathlib import Path
from typing import Any

_TOOLS = Path(__file__).resolve().parent
if str(_TOOLS) not in sys.path:
    sys.path.insert(0, str(_TOOLS))

from hk_packfile import HkPackfile, load_packfile, locate_objects_by_class

HAVOK_VER = b"Havok-5.5.0-r1"


def iter_havok_slices(block_bytes: bytes) -> list[bytes]:
    markers = [m.start() for m in re.finditer(re.escape(HAVOK_VER), block_bytes)]
    out: list[bytes] = []
    for i, a in enumerate(markers):
        b = markers[i + 1] if i + 1 < len(markers) else len(block_bytes)
        out.append(block_bytes[a:b])
    return out


def _rel_ptr(ptr: int, d0: int, patched_len: int) -> int | None:
    if ptr < d0 or ptr >= d0 + patched_len:
        return None
    return int(ptr - d0)


def _read_cstr(patched: bytes, rel: int, *, max_len: int = 256) -> str:
    if rel < 0 or rel >= len(patched):
        return ""
    end = rel
    while end < len(patched) and end - rel < max_len and patched[end] != 0:
        end += 1
    return patched[rel:end].decode("ascii", errors="replace")


def _parse_hka_skeleton_hk550(pf: HkPackfile, struct_off: int) -> dict[str, Any] | None:
    """Parse HK550 32-bit ``hkaSkeleton`` at *struct_off* inside ``pf.patched_data``."""
    b = pf.patched_data
    d0 = pf.data.abs_start
    if struct_off + 36 > len(b):
        return None

    # HK550 fields (see Havok headers / plan): name, numParentIndices, bones, numBones,
    # transforms, parentIndices, floatSlots, numFloatSlots.
    _name_p = struct.unpack_from("<I", b, struct_off + 0)[0]
    num_par_u = struct.unpack_from("<I", b, struct_off + 8)[0]
    bones_p = struct.unpack_from("<I", b, struct_off + 12)[0]
    num_bones = struct.unpack_from("<I", b, struct_off + 16)[0]
    transforms_p = struct.unpack_from("<I", b, struct_off + 20)[0]
    parent_p = struct.unpack_from("<I", b, struct_off + 24)[0]

    if num_bones < 1 or num_bones > 512:
        return None

    rp = _rel_ptr(parent_p, d0, len(b))
    if rp is None or rp + num_bones * 2 > len(b):
        return None
    parents: list[int] = [struct.unpack_from("<h", b, rp + i * 2)[0] for i in range(num_bones)]
    if any(p < -1 or p >= num_bones for p in parents):
        return None

    bone_names: list[str] = []
    bones_rel = _rel_ptr(bones_p, d0, len(b))
    if bones_rel is not None:
        stride = 8  # hkaBone (lock flag + name ptr) — enough for naming harvest
        for i in range(num_bones):
            bo = bones_rel + i * stride
            if bo + 8 > len(b):
                bone_names.append(f"bone_{i}")
                continue
            nm_p = struct.unpack_from("<I", b, bo + 4)[0]
            nr = _rel_ptr(nm_p, d0, len(b))
            bone_names.append(_read_cstr(b, nr) if nr is not None else f"bone_{i}")
    else:
        bone_names = [f"bone_{i}" for i in range(num_bones)]

    tr_rel = _rel_ptr(transforms_p, d0, len(b))
    ref_pose: list[list[float]] = []
    if tr_rel is not None:
        # hkQsTransform: Vector4 t, Quaternion q, Vector4 s  (48 bytes in HK 550 data)
        stride_t = 48
        for i in range(num_bones):
            to = tr_rel + i * stride_t
            if to + stride_t > len(b):
                ref_pose.append([0.0] * 10)
                continue
            f = struct.unpack_from("<12f", b, to)
            tx, ty, tz, _tw = f[0], f[1], f[2], f[3]
            qx, qy, qz, qw = f[4], f[5], f[6], f[7]
            sx, sy, sz, _sw = f[8], f[9], f[10], f[11]
            ref_pose.append(
                [float(tx), float(ty), float(tz), float(qx), float(qy), float(qz), float(qw), float(sx), float(sy), float(sz)]
            )
    else:
        ref_pose = [[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0] for _ in range(num_bones)]

    unused = num_par_u not in (0, num_bones, num_bones - 1)

    return {
        "bone_count": int(num_bones),
        "bone_names": bone_names,
        "parent_indices": parents,
        "reference_pose": ref_pose,
        "source": "hkaSkeleton",
        "meta": {
            "struct_off": struct_off,
            "numParentIndices_raw": int(num_par_u),
            "numParentIndices_unused_flag": unused,
        },
    }


def try_parse_skeleton_from_packfile(pf: HkPackfile) -> dict[str, Any] | None:
    objs = locate_objects_by_class(pf)
    offs = objs.get("hkaSkeleton") or []
    for so in offs:
        doc = _parse_hka_skeleton_hk550(pf, int(so))
        if doc is not None:
            _sanitize_pose_quats(doc)
            return doc
    return None


def _sanitize_pose_quats(doc: dict[str, Any]) -> None:
    from hk_anim._decompress_common import fix_quat_w_sentinel

    rp = doc.get("reference_pose")
    if not isinstance(rp, list):
        return
    for row in rp:
        if not isinstance(row, list) or len(row) < 7:
            continue
        qx, qy, qz, qw = fix_quat_w_sentinel(float(row[3]), float(row[4]), float(row[5]), float(row[6]))
        ln = math.sqrt(qx * qx + qy * qy + qz * qz + qw * qw) or 1.0
        row[3], row[4], row[5], row[6] = qx / ln, qy / ln, qz / ln, qw / ln


def extract_skeleton_from_block_path(block_path: Path) -> dict[str, Any] | None:
    raw = block_path.read_bytes()
    for chunk in iter_havok_slices(raw):
        if len(chunk) < 512:
            continue
        tpath: Path | None = None
        try:
            with tempfile.NamedTemporaryFile(suffix=".hkx", delete=False) as tf:
                tpath = Path(tf.name)
                tf.write(chunk)
            pf = load_packfile(tpath)
            doc = try_parse_skeleton_from_packfile(pf)
            if doc is not None:
                doc.setdefault("meta", {})
                if isinstance(doc["meta"], dict):
                    doc["meta"]["block_path"] = str(block_path.resolve())
                return doc
        except (OSError, ValueError, struct.error):
            continue
        finally:
            if tpath is not None:
                try:
                    tpath.unlink()
                except OSError:
                    pass
    return None


def main() -> int:
    ap = argparse.ArgumentParser(description="Try extracting hkaSkeleton from a Mercs2 block.bin")
    ap.add_argument("block", type=Path)
    ap.add_argument("--out", type=Path, default=None)
    args = ap.parse_args()
    doc = extract_skeleton_from_block_path(args.block)
    if doc is None:
        print("no skeleton parsed", file=sys.stderr)
        return 1
    out = args.out or Path("skeleton.json")
    out.write_text(json.dumps(doc, indent=2), encoding="utf-8")
    print(f"Wrote {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
