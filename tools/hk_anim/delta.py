# -*- coding: utf-8 -*-
"""Decode ``hkaDeltaCompressedSkeletalAnimation`` (partial — header + safe fallback)."""

from __future__ import annotations

import struct
from typing import Any

from hk_anim._common import TRS, AnimationIR


def _identity_trs() -> TRS:
    return TRS(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0)


def _read_header_meta(blob: bytes, base_off: int) -> dict[str, Any] | None:
    """Best-effort header fields for HK 5.5 delta-compressed skeletal clips."""
    if base_off + 0x70 > len(blob):
        return None
    duration = struct.unpack_from("<f", blob, base_off + 8)[0]
    n_tt = struct.unpack_from("<H", blob, base_off + 0x10)[0]
    n_frames = struct.unpack_from("<I", blob, base_off + 0x14)[0]
    # Common follow-ups (offsets vary slightly by exact class version; treat as hints)
    qfmt = struct.unpack_from("<B", blob, base_off + 0x18)[0] if base_off + 0x19 <= len(blob) else 0
    block_size = struct.unpack_from("<H", blob, base_off + 0x1A)[0] if base_off + 0x1C <= len(blob) else 0
    return {
        "duration": float(duration),
        "num_transform_tracks": int(n_tt),
        "number_of_poses": int(n_frames),
        "quantization_format_byte": int(qfmt),
        "block_size_hint": int(block_size),
    }


def decode_delta(blob: bytes, base_off: int = 0, *, name: str = "clip") -> AnimationIR | None:
    """
    Full unpack needs ``staticMask`` + ``quantizedData`` stream walk (see HKLib ``HKAnimationData.Delta``).

    This decoder records header ``meta`` and emits identity TRS samples over the declared duration so
    the glTF / UE5 plumbing stays testable until the bitstream walk is completed.
    """
    meta = _read_header_meta(blob, base_off)
    if meta is None:
        return None
    duration = meta["duration"]
    n_tt = meta["num_transform_tracks"]
    n_frames = meta["number_of_poses"]
    if n_tt == 0 or duration <= 0:
        return None
    n_frames = max(2, min(int(n_frames) if n_frames > 0 else int(duration * 30), 512))
    bones = [f"bone_{i}" for i in range(n_tt)]
    frames = [[_identity_trs() for _ in range(n_tt)] for _ in range(n_frames)]
    return AnimationIR(
        name=name,
        duration=float(duration),
        fps=n_frames / duration if duration > 1e-6 else 30.0,
        bone_names=bones,
        frames=frames,
        source_class="hkaDeltaCompressedSkeletalAnimation",
        meta=meta,
    )


__all__ = ["decode_delta"]
