# -*- coding: utf-8 -*-
"""Decode ``hkaInterleavedUncompressedAnimation``-shaped blobs into :class:`AnimationIR`."""

from __future__ import annotations

import struct
from hk_anim._common import TRS, AnimationIR


def decode_interleaved(blob: bytes, base_off: int = 0, *, name: str = "clip") -> AnimationIR | None:
    """
    Layout (Havok 5.5-style, after patched vtable pointer at +0):

    +0x08  duration (f32)
    +0x10  numTransformTracks (u16)
    +0x12  numFloatTracks (u16)
    +0x14  numFrames (u32)
    +0x30  first frame: ``numFrames × numTransformTracks`` × ``hkQsTransform`` (40 bytes)
    """
    if base_off + 0x40 > len(blob):
        return None
    duration = struct.unpack_from("<f", blob, base_off + 8)[0]
    n_tt = struct.unpack_from("<H", blob, base_off + 0x10)[0]
    n_ft = struct.unpack_from("<H", blob, base_off + 0x12)[0]
    n_frames = struct.unpack_from("<I", blob, base_off + 0x14)[0]
    if n_tt == 0 or n_frames == 0 or n_frames > 1_000_000:
        return None
    stride = 40 * n_tt
    float_stride = 4 * n_ft
    data_off = base_off + 0x30
    tracks_end = data_off + stride * n_frames
    if tracks_end > len(blob):
        return None
    frames: list[list[TRS]] = []
    for f in range(n_frames):
        row: list[TRS] = []
        fo = data_off + f * stride
        for _ in range(n_tt):
            tx, ty, tz = struct.unpack_from("<fff", blob, fo)
            qx, qy, qz, qw = struct.unpack_from("<ffff", blob, fo + 12)
            sx, sy, sz = struct.unpack_from("<fff", blob, fo + 28)
            row.append(TRS(tx, ty, tz, qx, qy, qz, qw, sx, sy, sz))
            fo += 40
        frames.append(row)
    float_tracks: list[list[float]] = []
    ft_off = tracks_end
    if n_ft and ft_off + float_stride * n_frames <= len(blob):
        for ti in range(n_ft):
            vals: list[float] = []
            for fi in range(n_frames):
                p = ft_off + fi * float_stride + ti * 4
                vals.append(struct.unpack_from("<f", blob, p)[0])
            float_tracks.append(vals)
    bones = [f"bone_{i}" for i in range(n_tt)]
    return AnimationIR(
        name=name,
        duration=float(duration),
        fps=n_frames / duration if duration > 1e-6 else 30.0,
        bone_names=bones,
        frames=frames,
        float_tracks=float_tracks,
        source_class="hkaInterleavedUncompressedAnimation",
        meta={"num_float_tracks": n_ft},
    )


__all__ = ["decode_interleaved"]
