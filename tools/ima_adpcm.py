#!/usr/bin/env python3
"""IMA ADPCM decode for Mercenaries 2 PC wavebank / PWS payloads.

Ported from ``tools/wad_simulator/.../audio/ima.rs`` (verified against retail).

Mono: 36-byte blocks (4B header + 32B nibbles → 65 samples/block, first from header).
Stereo: 72-byte blocks (8B dual header + 64B interleaved nibbles).
"""
from __future__ import annotations

import struct
import wave
from pathlib import Path
from typing import Sequence

MONO_BLOCK_SIZE = 36
STEREO_BLOCK_SIZE = 72

INDEX_TABLE: tuple[int, ...] = (
    -1, -1, -1, -1, 2, 4, 6, 8, -1, -1, -1, -1, 2, 4, 6, 8,
)
STEP_TABLE: tuple[int, ...] = (
    7, 8, 9, 10, 11, 12, 13, 14, 16, 17, 19, 21, 23, 25, 28, 31, 34, 37, 41, 45, 50, 55, 60,
    66, 73, 80, 88, 97, 107, 118, 130, 143, 157, 173, 190, 209, 230, 253, 279, 307, 337, 371,
    408, 449, 494, 544, 598, 658, 724, 796, 876, 963, 1060, 1166, 1282, 1411, 1552, 1707, 1878,
    2066, 2272, 2499, 2749, 3024, 3327, 3660, 4026, 4428, 4871, 5358, 5894, 6484, 7132, 7845,
    8630, 9493, 10442, 11487, 12635, 13899, 15289, 16818, 18500, 20350, 22385, 24623, 27086,
    29794, 32767,
)


class ImaDecodeError(ValueError):
    """IMA payload could not be decoded."""


def _clamp_step_index(step_index: int) -> int:
    return max(0, min(step_index, len(STEP_TABLE) - 1))


def _decode_nibble(nibble: int, predictor: int, step_index: int) -> tuple[int, int]:
    step = STEP_TABLE[_clamp_step_index(step_index)]
    diff = step >> 3
    if nibble & 1:
        diff += step >> 2
    if nibble & 2:
        diff += step >> 1
    if nibble & 4:
        diff += step
    if nibble & 8:
        diff = -diff
    predictor_i = max(-32768, min(32767, predictor + diff))
    new_step = _clamp_step_index(step_index + INDEX_TABLE[nibble & 0x0F])
    return predictor_i, new_step


def decode_ima_mono(data: bytes) -> list[int]:
    """Decode mono IMA ADPCM to signed 16-bit PCM samples."""
    if not data:
        raise ImaDecodeError("empty payload")
    samples: list[int] = []
    offset = 0
    while offset + MONO_BLOCK_SIZE <= len(data):
        predictor = struct.unpack_from("<h", data, offset)[0]
        step_index = _clamp_step_index(data[offset + 2])
        predictor_i = predictor
        samples.append(predictor)
        for byte_idx in range(32):
            b = data[offset + 4 + byte_idx]
            for nibble in (b & 0x0F, b >> 4):
                predictor_i, step_index = _decode_nibble(nibble, predictor_i, step_index)
                samples.append(predictor_i)
        offset += MONO_BLOCK_SIZE
    if not samples and data:
        raise ImaDecodeError(
            f"no complete mono blocks (len={len(data)}, block={MONO_BLOCK_SIZE})"
        )
    return samples


def decode_ima_stereo(data: bytes) -> tuple[list[int], list[int]]:
    """Decode stereo IMA ADPCM; returns (left, right) sample arrays."""
    if not data:
        raise ImaDecodeError("empty payload")
    left: list[int] = []
    right: list[int] = []
    offset = 0
    while offset + STEREO_BLOCK_SIZE <= len(data):
        l_pred = struct.unpack_from("<h", data, offset)[0]
        l_step = _clamp_step_index(data[offset + 2])
        r_pred = struct.unpack_from("<h", data, offset + 4)[0]
        r_step = _clamp_step_index(data[offset + 6])
        l_pred_i = l_pred
        r_pred_i = r_pred
        left.append(l_pred)
        right.append(r_pred)
        for group in range(8):
            base = offset + 8 + group * 8
            for i in range(4):
                lb = data[base + i]
                for nibble in (lb & 0x0F, lb >> 4):
                    l_pred_i, l_step = _decode_nibble(nibble, l_pred_i, l_step)
                    left.append(l_pred_i)
                rb = data[base + 4 + i]
                for nibble in (rb & 0x0F, rb >> 4):
                    r_pred_i, r_step = _decode_nibble(nibble, r_pred_i, r_step)
                    right.append(r_pred_i)
        offset += STEREO_BLOCK_SIZE
    if not left and data:
        raise ImaDecodeError(
            f"no complete stereo blocks (len={len(data)}, block={STEREO_BLOCK_SIZE})"
        )
    return left, right


def interleave_stereo(left: Sequence[int], right: Sequence[int]) -> list[int]:
    """Interleave L/R into one buffer (length = 2 * min(len(left), len(right)))."""
    n = min(len(left), len(right))
    out: list[int] = []
    for i in range(n):
        out.append(left[i])
        out.append(right[i])
    return out


def write_wav_pcm16(
    path: str | Path,
    samples: Sequence[int],
    *,
    sample_rate: int,
    channels: int,
) -> None:
    """Write signed 16-bit PCM samples to a RIFF WAVE file."""
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    pcm = b"".join(struct.pack("<h", max(-32768, min(32767, s))) for s in samples)
    with wave.open(str(path), "wb") as wf:
        wf.setnchannels(channels)
        wf.setsampwidth(2)
        wf.setframerate(sample_rate)
        wf.writeframes(pcm)


def decode_ima_to_interleaved(
    data: bytes,
    channels: int,
) -> tuple[list[int], int]:
    """Decode IMA payload; return (interleaved_or_mono_samples, channel_count)."""
    ch = channels if channels > 0 else 1
    if ch <= 1:
        return decode_ima_mono(data), 1
    left, right = decode_ima_stereo(data)
    return interleave_stereo(left, right), 2
