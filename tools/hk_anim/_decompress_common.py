# -*- coding: utf-8 -*-
"""Shared decompression primitives for Havok 5.5 compressed skeletal animations.

Covers StaticMask interpretation, bitstream dequantization, and quantization-format
parsing.  Used by both delta and wavelet decoders.
"""

from __future__ import annotations

import math
import struct
from dataclasses import dataclass
from enum import IntEnum
from typing import Sequence


class TrackType(IntEnum):
    DYNAMIC = 0
    STATIC = 1
    IDENTITY = 2


class MaskBit(IntEnum):
    POS_Z = 6
    POS_Y = 7
    POS_X = 8
    ROT_W = 9
    ROT_Z = 10
    ROT_Y = 11
    ROT_X = 12
    SCALE_Z = 13
    SCALE_Y = 14
    SCALE_X = 15


@dataclass(slots=True)
class StaticMask:
    raw: int

    @property
    def pos_type(self) -> TrackType:
        return TrackType(self.raw & 3)

    @property
    def rot_type(self) -> TrackType:
        return TrackType((self.raw >> 2) & 3)

    @property
    def scale_type(self) -> TrackType:
        return TrackType((self.raw >> 4) & 3)

    def use_sub(self, bit: MaskBit) -> bool:
        return bool(self.raw & (1 << bit))


@dataclass(slots=True)
class QuantizationFormat:
    max_bit_width: int
    preserved: int
    num_d: int
    offset_idx: int
    scale_idx: int
    bit_width_idx: int


def read_quantization_format(buf: bytes, off: int) -> QuantizationFormat:
    mbw = buf[off]
    pres = buf[off + 1]
    num_d = struct.unpack_from("<I", buf, off + 4)[0]
    oi = struct.unpack_from("<I", buf, off + 8)[0]
    si = struct.unpack_from("<I", buf, off + 12)[0]
    bwi = struct.unpack_from("<I", buf, off + 16)[0]
    return QuantizationFormat(mbw, pres, num_d, oi, si, bwi)


def read_static_masks(buf: bytes, off: int, n_tracks: int) -> list[StaticMask]:
    return [StaticMask(struct.unpack_from("<H", buf, off + i * 2)[0]) for i in range(n_tracks)]


def count_dynamic_dofs(masks: Sequence[StaticMask]) -> int:
    n = 0
    for m in masks:
        if m.pos_type == TrackType.DYNAMIC:
            for b in (MaskBit.POS_X, MaskBit.POS_Y, MaskBit.POS_Z):
                if m.use_sub(b):
                    n += 1
        if m.rot_type == TrackType.DYNAMIC:
            for b in (MaskBit.ROT_X, MaskBit.ROT_Y, MaskBit.ROT_Z, MaskBit.ROT_W):
                if m.use_sub(b):
                    n += 1
        if m.scale_type == TrackType.DYNAMIC:
            for b in (MaskBit.SCALE_X, MaskBit.SCALE_Y, MaskBit.SCALE_Z):
                if m.use_sub(b):
                    n += 1
    return n


def dequantize_bitstream(
    buf: bytes,
    bit_offset: int,
    bit_width: int,
    n_values: int,
) -> list[int]:
    """Extract *n_values* unsigned integers of *bit_width* bits from packed *buf* starting at *bit_offset*."""
    if bit_width == 0:
        return [0] * n_values
    mask = (1 << bit_width) - 1
    out: list[int] = []
    cur_bit = bit_offset
    for _ in range(n_values):
        byte_idx = cur_bit >> 3
        bit_in_byte = cur_bit & 7
        val = 0
        bits_read = 0
        while bits_read < bit_width:
            if byte_idx >= len(buf):
                break
            available = 8 - bit_in_byte
            need = bit_width - bits_read
            take = min(available, need)
            chunk = (buf[byte_idx] >> bit_in_byte) & ((1 << take) - 1)
            val |= chunk << bits_read
            bits_read += take
            byte_idx += 1
            bit_in_byte = 0
        out.append(val & mask)
        cur_bit += bit_width
    return out


def fix_quat_w_sentinel(qx: float, qy: float, qz: float, qw: float) -> tuple[float, float, float, float]:
    """Reconstruct quaternion W when Havok stores the ``±2`` sentinel (see HavokLib delta decompressor)."""
    if qw == 2.0 or qw == -2.0:
        basis = qw * 0.5  # ±1
        w_sq = max(0.0, 1.0 - qx * qx - qy * qy - qz * qz)
        qw = basis * math.sqrt(w_sq)
    return qx, qy, qz, qw


def dequantize_values(
    quantized: list[int],
    offset: float,
    scale: float,
    bit_width: int,
) -> list[float]:
    """Convert quantized integers to floats: ``offset + q * scale * fractal``."""
    if bit_width == 0:
        return [offset] * len(quantized)
    fractal = 1.0 / ((1 << bit_width) - 1)
    return [offset + q * scale * fractal for q in quantized]


__all__ = [
    "TrackType",
    "MaskBit",
    "StaticMask",
    "QuantizationFormat",
    "read_quantization_format",
    "read_static_masks",
    "count_dynamic_dofs",
    "dequantize_bitstream",
    "dequantize_values",
    "fix_quat_w_sentinel",
]
