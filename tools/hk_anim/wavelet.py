# -*- coding: utf-8 -*-
"""Decode ``hkaWaveletSkeletalAnimation`` from Havok 5.5.0-r1 packfile data.

Implements the full pipeline: locate wavelet struct in __data__ blob, parse the HK550
32-bit header, read StaticMask / QuantizationFormat / dataBuffer arrays, dequantize
wavelet coefficients, apply inverse Haar wavelet transform, and assemble per-frame TRS.
"""

from __future__ import annotations

import math
import struct
from typing import Any

from hk_anim._common import TRS, AnimationIR
from hk_anim._decompress_common import (
    MaskBit,
    StaticMask,
    TrackType,
    dequantize_bitstream,
    dequantize_values,
    fix_quat_w_sentinel,
    read_static_masks,
)

# ---------------------------------------------------------------------------
# HK550 32-bit layout offsets (from struct start)
# ---------------------------------------------------------------------------
# hkaAnimation base (36 bytes):
_OFF_ANIM_TYPE = 8
_OFF_DURATION = 12
_OFF_NUM_TT = 16
_OFF_NUM_FT = 20
# Wavelet-specific fields (from struct start):
_OFF_NUM_POSES = 36
_OFF_BLOCK_SIZE = 40
_OFF_QFMT = 44  # 20-byte QuantizationFormat
_OFF_STATIC_MASK_IDX = 64
_OFF_STATIC_DOFS_IDX = 68
_OFF_BLOCK_INDEX_IDX = 72
_OFF_BLOCK_INDEX_SIZE = 76
_OFF_QUANT_DATA_IDX = 80
_OFF_QUANT_DATA_SIZE = 84
_OFF_DATA_BUFFER_PTR = 88
_OFF_NUM_DATA_BUFFER = 92
_WAVELET_STRUCT_SIZE = 96


def _find_wavelet_struct(blob: bytes) -> int | None:
    """Locate the wavelet animation struct by scanning for type=3 + plausible duration."""
    for off in range(0, min(len(blob) - _WAVELET_STRUCT_SIZE, 4096), 4):
        t = struct.unpack_from("<I", blob, off + _OFF_ANIM_TYPE)[0]
        if t != 3:
            continue
        d = struct.unpack_from("<f", blob, off + _OFF_DURATION)[0]
        if not (0.001 <= d <= 600.0 and math.isfinite(d)):
            continue
        ntt = struct.unpack_from("<I", blob, off + _OFF_NUM_TT)[0]
        if not (1 <= ntt <= 500):
            continue
        bs = struct.unpack_from("<I", blob, off + _OFF_BLOCK_SIZE)[0]
        if bs not in (2, 4, 8, 16, 32, 64):
            continue
        return off
    return None


def _normalize_quat_inplace(vals: list[float]) -> None:
    qx, qy, qz, qw = fix_quat_w_sentinel(vals[3], vals[4], vals[5], vals[6])
    vals[3], vals[4], vals[5], vals[6] = qx, qy, qz, qw
    qlen = math.sqrt(qx * qx + qy * qy + qz * qz + qw * qw)
    if qlen > 1e-8:
        inv = 1.0 / qlen
        vals[3] *= inv
        vals[4] *= inv
        vals[5] *= inv
        vals[6] *= inv
    else:
        vals[3] = 0.0
        vals[4] = 0.0
        vals[5] = 0.0
        vals[6] = 1.0


def _inverse_haar(coeffs: list[float], n: int) -> list[float]:
    """Inverse Haar wavelet (lifting) transform.

    ``coeffs`` has ``n`` entries: [average, detail_level0, detail_level1, ...].
    Reconstructs ``n`` sample values.
    """
    if n <= 1:
        return coeffs[:n]
    vals = list(coeffs[:n])
    level = 1
    while level < n:
        tmp = vals[:]
        for i in range(level):
            a = vals[i]
            d = vals[level + i] if (level + i < n) else 0.0
            tmp[2 * i] = a + d
            if 2 * i + 1 < n:
                tmp[2 * i + 1] = a - d
        vals = tmp
        level *= 2
    return vals[:n]


def _dof_sub_bits(mask: StaticMask, channel: str) -> list[MaskBit]:
    """Return the active sub-track bits for a dynamic channel."""
    if channel == "pos":
        return [b for b in (MaskBit.POS_X, MaskBit.POS_Y, MaskBit.POS_Z) if mask.use_sub(b)]
    if channel == "rot":
        return [b for b in (MaskBit.ROT_X, MaskBit.ROT_Y, MaskBit.ROT_Z, MaskBit.ROT_W) if mask.use_sub(b)]
    if channel == "scale":
        return [b for b in (MaskBit.SCALE_X, MaskBit.SCALE_Y, MaskBit.SCALE_Z) if mask.use_sub(b)]
    return []


def decode_wavelet(
    blob: bytes,
    base_off: int = 0,
    *,
    name: str = "clip",
    duration: float | None = None,
    n_tracks: int | None = None,
) -> AnimationIR | None:
    """Decode a ``hkaWaveletSkeletalAnimation`` from patched __data__ bytes."""

    struct_off = _find_wavelet_struct(blob)
    if struct_off is None:
        return None

    dur = struct.unpack_from("<f", blob, struct_off + _OFF_DURATION)[0]
    n_tt = struct.unpack_from("<I", blob, struct_off + _OFF_NUM_TT)[0]
    n_ft = struct.unpack_from("<I", blob, struct_off + _OFF_NUM_FT)[0]
    n_poses = struct.unpack_from("<I", blob, struct_off + _OFF_NUM_POSES)[0]
    block_size = struct.unpack_from("<I", blob, struct_off + _OFF_BLOCK_SIZE)[0]

    max_bw = blob[struct_off + _OFF_QFMT]
    preserved = blob[struct_off + _OFF_QFMT + 1]
    num_d = struct.unpack_from("<I", blob, struct_off + _OFF_QFMT + 4)[0]
    offset_idx = struct.unpack_from("<I", blob, struct_off + _OFF_QFMT + 8)[0]
    scale_idx = struct.unpack_from("<I", blob, struct_off + _OFF_QFMT + 12)[0]
    bw_idx = struct.unpack_from("<I", blob, struct_off + _OFF_QFMT + 16)[0]

    sm_idx = struct.unpack_from("<I", blob, struct_off + _OFF_STATIC_MASK_IDX)[0]
    sd_idx = struct.unpack_from("<I", blob, struct_off + _OFF_STATIC_DOFS_IDX)[0]
    bi_idx = struct.unpack_from("<I", blob, struct_off + _OFF_BLOCK_INDEX_IDX)[0]
    bi_size = struct.unpack_from("<I", blob, struct_off + _OFF_BLOCK_INDEX_SIZE)[0]
    qd_idx = struct.unpack_from("<I", blob, struct_off + _OFF_QUANT_DATA_IDX)[0]
    qd_size = struct.unpack_from("<I", blob, struct_off + _OFF_QUANT_DATA_SIZE)[0]
    num_data_buf = struct.unpack_from("<I", blob, struct_off + _OFF_NUM_DATA_BUFFER)[0]

    if dur <= 0 or n_tt == 0:
        return None

    db_base = struct_off + _WAVELET_STRUCT_SIZE

    masks = read_static_masks(blob, db_base + sm_idx, n_tt)

    # --- Read static DOF values (f32 each) ---
    static_dofs: list[float] = []
    sd_start = db_base + sd_idx
    n_static_floats = (offset_idx - sd_idx) // 4
    for i in range(n_static_floats):
        static_dofs.append(struct.unpack_from("<f", blob, sd_start + i * 4)[0])

    # --- Read per-dynamic-DOF offset/scale/bitWidth arrays ---
    offsets: list[float] = []
    scales: list[float] = []
    bit_widths: list[int] = []
    for i in range(num_d):
        offsets.append(struct.unpack_from("<f", blob, db_base + offset_idx + i * 4)[0])
        scales.append(struct.unpack_from("<f", blob, db_base + scale_idx + i * 4)[0])
    for i in range(num_d):
        bit_widths.append(blob[db_base + bw_idx + i])

    # --- Compute number of blocks ---
    n_blocks = (n_poses + block_size - 1) // block_size

    # --- Read block index (byte offsets into quantized data, one per block) ---
    block_offsets: list[int] = []
    if bi_size >= n_blocks:
        for i in range(n_blocks):
            block_offsets.append(struct.unpack_from("<I", blob, db_base + bi_idx + i * 4)[0])
    else:
        block_offsets = [0] * n_blocks

    qd_start = db_base + qd_idx

    # ---------------------------------------------------------------------------
    # Build static / identity rest-pose values per track (HavokLib static rules)
    # ---------------------------------------------------------------------------
    # ``TT_STATIC`` reads full float tuples unconditionally.  ``TT_DYNAMIC`` reads
    # one static-buffer float for each axis where the sub-track bit is *false*
    # (those axes are not driven by the quantized wavelet stream).  ``TT_IDENTITY``
    # consumes no floats from the static buffer.
    identity_vals = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0]
    static_trs_per_track: list[list[float]] = []
    sd_cursor = 0

    def read_sd() -> float:
        nonlocal sd_cursor
        if sd_cursor >= len(static_dofs):
            return 0.0
        v = static_dofs[sd_cursor]
        sd_cursor += 1
        return v

    for ti in range(n_tt):
        m = masks[ti]
        vals = list(identity_vals)
        # Position
        if m.pos_type == TrackType.STATIC:
            vals[0] = read_sd()
            vals[1] = read_sd()
            vals[2] = read_sd()
        elif m.pos_type == TrackType.DYNAMIC:
            for axis, bit in enumerate((MaskBit.POS_X, MaskBit.POS_Y, MaskBit.POS_Z)):
                if not m.use_sub(bit):
                    vals[axis] = read_sd()
        # Rotation
        if m.rot_type == TrackType.STATIC:
            vals[3] = read_sd()
            vals[4] = read_sd()
            vals[5] = read_sd()
            vals[6] = read_sd()
        elif m.rot_type == TrackType.DYNAMIC:
            for j, bit in enumerate((MaskBit.ROT_X, MaskBit.ROT_Y, MaskBit.ROT_Z, MaskBit.ROT_W)):
                if not m.use_sub(bit):
                    vals[3 + j] = read_sd()
        elif m.rot_type == TrackType.IDENTITY:
            vals[3] = vals[4] = vals[5] = 0.0
            vals[6] = 1.0
        # Scale
        if m.scale_type == TrackType.STATIC:
            vals[7] = read_sd()
            vals[8] = read_sd()
            vals[9] = read_sd()
        elif m.scale_type == TrackType.DYNAMIC:
            for j, bit in enumerate((MaskBit.SCALE_X, MaskBit.SCALE_Y, MaskBit.SCALE_Z)):
                if not m.use_sub(bit):
                    vals[7 + j] = read_sd()
        elif m.scale_type == TrackType.IDENTITY:
            vals[7] = vals[8] = vals[9] = 1.0

        _normalize_quat_inplace(vals)
        static_trs_per_track.append(vals)

    if sd_cursor != n_static_floats:
        raise ValueError(f"static DOF cursor mismatch: consumed {sd_cursor} floats, expected {n_static_floats}")

    # ---------------------------------------------------------------------------
    # Build mapping: dynamic DOF index -> (track, component)
    # ---------------------------------------------------------------------------
    dyn_dof_map: list[tuple[int, int]] = []  # [(track_idx, component_idx)]
    for ti in range(n_tt):
        m = masks[ti]
        if m.pos_type == TrackType.DYNAMIC:
            for j, b in enumerate([MaskBit.POS_X, MaskBit.POS_Y, MaskBit.POS_Z]):
                if m.use_sub(b):
                    dyn_dof_map.append((ti, j))
        if m.rot_type == TrackType.DYNAMIC:
            for j, b in enumerate([MaskBit.ROT_X, MaskBit.ROT_Y, MaskBit.ROT_Z, MaskBit.ROT_W]):
                if m.use_sub(b):
                    dyn_dof_map.append((ti, 3 + j))
        if m.scale_type == TrackType.DYNAMIC:
            for j, b in enumerate([MaskBit.SCALE_X, MaskBit.SCALE_Y, MaskBit.SCALE_Z]):
                if m.use_sub(b):
                    dyn_dof_map.append((ti, 7 + j))

    assert len(dyn_dof_map) == num_d, f"DOF map mismatch: {len(dyn_dof_map)} != {num_d}"

    # ---------------------------------------------------------------------------
    # Per-block decode: interleave preserved f32 + packed quant stream per DOF
    # ---------------------------------------------------------------------------
    # Mirrors HavokLib ``hka_delta_decompressor`` block layout: for each dynamic
    # coefficient track ``p``, read ``numPreserved`` raw floats, then a packed
    # bit field of ``(bitWidth * nQuant + 7) >> 3`` bytes where
    # ``nQuant = blockSize - numPreserved`` for wavelet (full ``blockSize``
    # coefficients per DOF per block).  The bit cursor is byte-aligned before
    # each DOF's preserved section.

    all_frames_trs: list[list[list[float]]] = []  # [frame_idx][track][10]
    n_quant_per_dof = block_size - preserved

    for blk in range(n_blocks):
        poses_in_block = min(block_size, n_poses - blk * block_size)

        # Determine byte offset into quantized data for this block
        if blk < len(block_offsets):
            blk_byte_off = block_offsets[blk]
        else:
            blk_byte_off = 0

        qd_blk_abs = qd_start + blk_byte_off
        bit_off = qd_blk_abs * 8

        frame_vals_per_dof: list[list[float]] = []
        for di in range(num_d):
            bit_off = ((bit_off + 7) >> 3) << 3
            pv: list[float] = []
            for _pi in range(preserved):
                bidx = bit_off >> 3
                if bidx + 4 <= len(blob):
                    pv.append(struct.unpack_from("<f", blob, bidx)[0])
                else:
                    pv.append(0.0)
                bit_off += 32

            bw = bit_widths[di]
            if n_quant_per_dof > 0 and bw > 0:
                quants = dequantize_bitstream(blob, bit_off, bw, n_quant_per_dof)
                dq = dequantize_values(quants, offsets[di], scales[di], bw)
                bit_off += bw * n_quant_per_dof
            else:
                dq = [0.0] * n_quant_per_dof

            coeffs = pv + dq
            while len(coeffs) < block_size:
                coeffs.append(0.0)

            frame_values = _inverse_haar(coeffs, block_size)
            frame_vals_per_dof.append(frame_values[:poses_in_block])

        # Assemble TRS per frame in this block
        for fi in range(poses_in_block):
            frame_data = [list(s) for s in static_trs_per_track]
            for di in range(num_d):
                ti, ci = dyn_dof_map[di]
                frame_data[ti][ci] = frame_vals_per_dof[di][fi]

            for ti in range(n_tt):
                _normalize_quat_inplace(frame_data[ti])

            all_frames_trs.append(frame_data)

    # Build final AnimationIR frames
    bone_names = [f"bone_{i}" for i in range(n_tt)]
    frames: list[list[TRS]] = []
    for frame_data in all_frames_trs:
        row: list[TRS] = []
        for ti in range(n_tt):
            d = frame_data[ti]
            row.append(TRS(d[0], d[1], d[2], d[3], d[4], d[5], d[6], d[7], d[8], d[9]))
        frames.append(row)

    fps = len(frames) / dur if dur > 1e-6 else 30.0
    meta: dict[str, Any] = {
        "n_poses": n_poses,
        "block_size": block_size,
        "n_transform_tracks": n_tt,
        "n_float_tracks": n_ft,
        "num_dynamic_dofs": num_d,
        "preserved": preserved,
        "max_bit_width": max_bw,
        "n_blocks": n_blocks,
        "struct_offset": struct_off,
        "n_static_floats": n_static_floats,
        "static_floats_consumed": sd_cursor,
    }

    return AnimationIR(
        name=name,
        duration=float(dur),
        fps=fps,
        bone_names=bone_names,
        frames=frames,
        source_class="hkaWaveletSkeletalAnimation",
        meta=meta,
    )


def peek_wavelet_header(blob: bytes) -> dict[str, Any] | None:
    """Read-only summary of the HK550 wavelet header (for tooling / parity checks)."""
    struct_off = _find_wavelet_struct(blob)
    if struct_off is None:
        return None
    dur = struct.unpack_from("<f", blob, struct_off + _OFF_DURATION)[0]
    n_tt = struct.unpack_from("<I", blob, struct_off + _OFF_NUM_TT)[0]
    n_ft = struct.unpack_from("<I", blob, struct_off + _OFF_NUM_FT)[0]
    n_poses = struct.unpack_from("<I", blob, struct_off + _OFF_NUM_POSES)[0]
    block_size = struct.unpack_from("<I", blob, struct_off + _OFF_BLOCK_SIZE)[0]
    num_d = struct.unpack_from("<I", blob, struct_off + _OFF_QFMT + 4)[0]
    preserved = blob[struct_off + _OFF_QFMT + 1]
    return {
        "struct_offset": struct_off,
        "duration": float(dur),
        "n_transform_tracks": int(n_tt),
        "n_float_tracks": int(n_ft),
        "n_poses": int(n_poses),
        "block_size": int(block_size),
        "num_dynamic_dofs": int(num_d),
        "preserved": int(preserved),
    }


__all__ = ["decode_wavelet", "peek_wavelet_header"]
