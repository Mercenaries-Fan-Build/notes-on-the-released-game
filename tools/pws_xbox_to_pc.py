#!/usr/bin/env python3
"""Xbox / XMA audio payloads → PC IMA ADPCM transcoder.

Mercenaries 2 standalone ``.pws`` and embedded wavebank clips use:
- Xbox ADPCM: 36-byte mono / 72-byte stereo blocks (nibble order differs from PC)
- PC retail ``.pws``: 4-byte LE header (u16 param + version=1) + MS-IMA ADPCM
- DLC may ship XMA (codec 0x01) — decoded via ffmpeg when available, then IMA-encoded

Usage:
    from pws_xbox_to_pc import transcode_pws_file_to_pc, transcode_pws_xbox_to_pc
    pc_data = transcode_pws_file_to_pc(xbox_data, channels=1, filename="vo.pws")
"""
from __future__ import annotations

import io
import shutil
import struct
import subprocess
import tempfile
import wave
from pathlib import Path

from audio_codec_policy import (
    PC_PWS_HEADER_SIZE,
    PC_PWS_VERSION_LE,
    PwsLayout,
    UnhandledAudioCodecError,
    probe_pws_payload,
)

# IMA ADPCM tables (standard, shared by both Xbox and PC codecs)
_IMA_INDEX_TABLE = [
    -1, -1, -1, -1, 2, 4, 6, 8,
    -1, -1, -1, -1, 2, 4, 6, 8,
]

_IMA_STEP_TABLE = [
    7, 8, 9, 10, 11, 12, 13, 14, 16, 17,
    19, 21, 23, 25, 28, 31, 34, 37, 41, 45,
    50, 55, 60, 66, 73, 80, 88, 97, 107, 118,
    130, 143, 157, 173, 190, 209, 230, 253, 279, 307,
    337, 371, 408, 449, 494, 544, 598, 658, 724, 796,
    876, 963, 1060, 1166, 1282, 1411, 1552, 1707, 1878, 2066,
    2272, 2499, 2749, 3024, 3327, 3660, 4026, 4428, 4871, 5358,
    5894, 6484, 7132, 7845, 8630, 9493, 10442, 11487, 12635, 13899,
    15289, 16818, 18500, 20350, 22385, 24623, 27086, 29794, 32767,
]

XBOX_MONO_BLOCK = 36
XBOX_STEREO_BLOCK = 72
XBOX_HEADER_SIZE = 4  # per channel: int16 predictor + uint8 step_index + uint8 reserved


def _swap_nibbles_block(data: bytes) -> bytes:
    """Swap high/low nibbles in every byte of the data area.

    This converts Xbox ADPCM nibble ordering to MS-IMA ordering (and vice versa).
    Xbox: high nibble decoded first. MS-IMA: low nibble decoded first.
    """
    return bytes(((b >> 4) & 0x0F) | ((b & 0x0F) << 4) for b in data)


def _decode_nibble(nibble: int, predictor: int, step_index: int) -> tuple[int, int, int]:
    """Decode one IMA ADPCM nibble. Returns (sample, new_predictor, new_step_index)."""
    step = _IMA_STEP_TABLE[step_index]

    diff = step >> 3
    if nibble & 1:
        diff += step >> 2
    if nibble & 2:
        diff += step >> 1
    if nibble & 4:
        diff += step

    if nibble & 8:
        predictor -= diff
    else:
        predictor += diff

    predictor = max(-32768, min(32767, predictor))

    step_index += _IMA_INDEX_TABLE[nibble]
    step_index = max(0, min(88, step_index))

    return predictor, predictor, step_index


def _encode_sample(sample: int, predictor: int, step_index: int) -> tuple[int, int, int]:
    """Encode one PCM16 sample to an IMA ADPCM nibble.

    Returns (nibble, new_predictor, new_step_index).
    """
    step = _IMA_STEP_TABLE[step_index]
    diff = sample - predictor

    nibble = 0
    if diff < 0:
        nibble = 8
        diff = -diff

    if diff >= step:
        nibble |= 4
        diff -= step
    if diff >= (step >> 1):
        nibble |= 2
        diff -= step >> 1
    if diff >= (step >> 2):
        nibble |= 1

    # Reconstruct the predictor exactly as decoder would
    _, new_predictor, new_step_index = _decode_nibble(nibble, predictor, step_index)

    return nibble, new_predictor, new_step_index


def _transcode_mono_block(xbox_block: bytes) -> bytes:
    """Convert one 36-byte Xbox ADPCM mono block to MS-IMA ADPCM.

    Since both codecs use identical IMA algorithm and the only difference is
    nibble order within bytes (Xbox: high first; MS-IMA: low first), we just
    swap nibbles in the 32-byte data area. The 4-byte header is unchanged.
    """
    if len(xbox_block) < XBOX_MONO_BLOCK:
        raise UnhandledAudioCodecError(
            f"mono ADPCM block undersized: {len(xbox_block)} bytes "
            f"(need {XBOX_MONO_BLOCK})"
        )

    header = xbox_block[:XBOX_HEADER_SIZE]
    data = xbox_block[XBOX_HEADER_SIZE:XBOX_MONO_BLOCK]
    return header + _swap_nibbles_block(data)


def _decode_xbox_mono_block(xbox_block: bytes) -> list[int]:
    """Fully decode a 36-byte Xbox ADPCM mono block to PCM16 samples."""
    predictor = struct.unpack_from("<h", xbox_block, 0)[0]
    step_index = xbox_block[2]
    step_index = max(0, min(88, step_index))

    samples = [predictor]
    data = xbox_block[XBOX_HEADER_SIZE:XBOX_MONO_BLOCK]

    # Xbox nibble order: high nibble first, low nibble second per byte
    for byte_val in data:
        hi = (byte_val >> 4) & 0x0F
        lo = byte_val & 0x0F

        _, predictor, step_index = _decode_nibble(hi, predictor, step_index)
        samples.append(predictor)

        _, predictor, step_index = _decode_nibble(lo, predictor, step_index)
        samples.append(predictor)

    return samples[:65]


def _decode_xbox_stereo_block(xbox_block: bytes) -> tuple[list[int], list[int]]:
    """Decode a 72-byte Xbox ADPCM stereo block to (left_samples, right_samples)."""
    # Left channel header
    l_predictor = struct.unpack_from("<h", xbox_block, 0)[0]
    l_step_index = max(0, min(88, xbox_block[2]))
    # Right channel header
    r_predictor = struct.unpack_from("<h", xbox_block, 4)[0]
    r_step_index = max(0, min(88, xbox_block[6]))

    left_samples = [l_predictor]
    right_samples = [r_predictor]

    data = xbox_block[8:72]  # 64 bytes

    # Xbox stereo: 8 bytes left, 8 bytes right, alternating (4 groups)
    # Each 8-byte chunk: high nibble first per byte (Xbox ordering)
    for group in range(4):
        # Left channel: 8 bytes = 16 nibbles = 16 samples
        l_start = group * 16
        for i in range(8):
            byte_val = data[l_start + i]
            hi = (byte_val >> 4) & 0x0F
            lo = byte_val & 0x0F
            _, l_predictor, l_step_index = _decode_nibble(hi, l_predictor, l_step_index)
            left_samples.append(l_predictor)
            _, l_predictor, l_step_index = _decode_nibble(lo, l_predictor, l_step_index)
            left_samples.append(l_predictor)

        # Right channel: 8 bytes = 16 nibbles = 16 samples
        r_start = l_start + 8
        for i in range(8):
            byte_val = data[r_start + i]
            hi = (byte_val >> 4) & 0x0F
            lo = byte_val & 0x0F
            _, r_predictor, r_step_index = _decode_nibble(hi, r_predictor, r_step_index)
            right_samples.append(r_predictor)
            _, r_predictor, r_step_index = _decode_nibble(lo, r_predictor, r_step_index)
            right_samples.append(r_predictor)

    return left_samples[:65], right_samples[:65]


def _encode_ima_mono_block(samples: list[int]) -> bytes:
    """Encode PCM16 samples into a 36-byte MS-IMA ADPCM mono block.

    The first sample becomes the predictor in the header. Remaining samples
    are encoded as nibbles in MS-IMA order (low nibble first per byte).
    """
    if not samples:
        return b"\x00" * XBOX_MONO_BLOCK

    predictor = max(-32768, min(32767, samples[0]))
    step_index = 0

    # Find best initial step_index by looking at the first few sample deltas
    if len(samples) > 1:
        first_diff = abs(samples[1] - samples[0])
        for i, step_val in enumerate(_IMA_STEP_TABLE):
            if step_val >= first_diff:
                step_index = max(0, i - 1)
                break
        else:
            step_index = 88

    header = struct.pack("<hBB", predictor, step_index, 0)

    nibbles: list[int] = []
    for s in samples[1:65]:
        nib, predictor, step_index = _encode_sample(s, predictor, step_index)
        nibbles.append(nib)

    # Pad to 64 nibbles
    while len(nibbles) < 64:
        nibbles.append(0)

    # Pack nibbles: MS-IMA order = low nibble first, high nibble second
    data = bytearray(32)
    for i in range(32):
        lo = nibbles[i * 2]
        hi = nibbles[i * 2 + 1] if i * 2 + 1 < len(nibbles) else 0
        data[i] = (hi << 4) | (lo & 0x0F)

    return header + bytes(data)


def _encode_ima_stereo_block(left_samples: list[int], right_samples: list[int]) -> bytes:
    """Encode stereo PCM16 samples into a 72-byte MS-IMA ADPCM stereo block.

    MS-IMA stereo: 4-byte L header, 4-byte R header, then alternating
    4-byte (8-nibble) chunks of L and R data.
    """
    l_pred = max(-32768, min(32767, left_samples[0])) if left_samples else 0
    r_pred = max(-32768, min(32767, right_samples[0])) if right_samples else 0
    l_step = 0
    r_step = 0

    l_header = struct.pack("<hBB", l_pred, l_step, 0)
    r_header = struct.pack("<hBB", r_pred, r_step, 0)

    # Encode left channel nibbles
    l_nibbles: list[int] = []
    for s in left_samples[1:65]:
        nib, l_pred, l_step = _encode_sample(s, l_pred, l_step)
        l_nibbles.append(nib)
    while len(l_nibbles) < 64:
        l_nibbles.append(0)

    # Encode right channel nibbles
    r_nibbles: list[int] = []
    for s in right_samples[1:65]:
        nib, r_pred, r_step = _encode_sample(s, r_pred, r_step)
        r_nibbles.append(nib)
    while len(r_nibbles) < 64:
        r_nibbles.append(0)

    # MS-IMA stereo data: 4 bytes left, 4 bytes right, alternating (8 groups)
    data = bytearray(64)
    for group in range(8):
        # Left: 4 bytes = 8 nibbles
        l_base = group * 8
        for i in range(4):
            nib_idx = l_base + i * 2
            lo = l_nibbles[nib_idx]
            hi = l_nibbles[nib_idx + 1] if nib_idx + 1 < len(l_nibbles) else 0
            data[group * 8 + i] = (hi << 4) | (lo & 0x0F)

        # Right: 4 bytes = 8 nibbles
        r_base = group * 8
        for i in range(4):
            nib_idx = r_base + i * 2
            lo = r_nibbles[nib_idx]
            hi = r_nibbles[nib_idx + 1] if nib_idx + 1 < len(r_nibbles) else 0
            data[group * 8 + 4 + i] = (hi << 4) | (lo & 0x0F)

    return l_header + r_header + bytes(data)


def transcode_pws_xbox_to_pc(xbox_data: bytes, channels: int = 1) -> bytes:
    """Transcode a raw Xbox ADPCM .pws stream to PC MS-IMA ADPCM.

    Args:
        xbox_data: Raw Xbox ADPCM byte stream (no header, block-aligned)
        channels: 1 for mono, 2 for stereo

    Returns:
        Raw MS-IMA ADPCM byte stream (same size for mono, same size for stereo)
    """
    if channels == 1:
        block_size = XBOX_MONO_BLOCK
    else:
        block_size = XBOX_STEREO_BLOCK

    if len(xbox_data) == 0:
        return xbox_data

    n_blocks = len(xbox_data) // block_size
    remainder = len(xbox_data) % block_size

    out = bytearray()

    for i in range(n_blocks):
        block = xbox_data[i * block_size:(i + 1) * block_size]

        if channels == 1:
            # Mono: lossless nibble swap (no decode/re-encode needed)
            out += _transcode_mono_block(block)
        else:
            # Stereo: full decode/re-encode due to interleaving differences
            left, right = _decode_xbox_stereo_block(block)
            out += _encode_ima_stereo_block(left, right)

    if remainder:
        raise UnhandledAudioCodecError(
            f"ADPCM stream not block-aligned: {len(xbox_data)} bytes, "
            f"block_size={block_size}, remainder={remainder}"
        )

    return bytes(out)


def wrap_pc_pws_header(ima_payload: bytes, param: int = 0) -> bytes:
    """Prefix PC retail ``.pws`` header (u16 param + version=1)."""
    return struct.pack("<HH", param & 0xFFFF, PC_PWS_VERSION_LE) + ima_payload


def _pcm16_to_ima_stream(samples: list[int], channels: int) -> bytes:
    """Encode interleaved PCM16 samples to raw MS-IMA block stream."""
    if channels == 1:
        out = bytearray()
        for start in range(0, len(samples), 65):
            chunk = samples[start : start + 65]
            if not chunk:
                break
            out += _encode_ima_mono_block(chunk)
        return bytes(out)

    if channels != 2:
        raise UnhandledAudioCodecError(f"unsupported channel count {channels}")

    left = samples[0::2]
    right = samples[1::2]
    n_frames = min(len(left), len(right))
    out = bytearray()
    for i in range(0, n_frames, 65):
        l_chunk = left[i : i + 65]
        r_chunk = right[i : i + 65]
        if not l_chunk and not r_chunk:
            break
        while len(l_chunk) < 65:
            l_chunk.append(l_chunk[-1] if l_chunk else 0)
        while len(r_chunk) < 65:
            r_chunk.append(r_chunk[-1] if r_chunk else 0)
        out += _encode_ima_stereo_block(l_chunk[:65], r_chunk[:65])
    return bytes(out)


def _wav_bytes_to_ima_payload(wav_bytes: bytes) -> tuple[bytes, int]:
    """Decode RIFF WAVE bytes to raw PC IMA ADPCM block stream."""
    with wave.open(io.BytesIO(wav_bytes), "rb") as wf:
        channels = wf.getnchannels()
        if wf.getsampwidth() != 2:
            raise UnhandledAudioCodecError(
                f"WAV sample width {wf.getsampwidth()} (expected 16-bit)"
            )
        rate = wf.getframerate()
        if rate <= 0:
            raise UnhandledAudioCodecError("invalid WAV sample rate")
        frames = wf.readframes(wf.getnframes())
    samples = list(struct.unpack(f"<{len(frames) // 2}h", frames))
    return _pcm16_to_ima_stream(samples, channels), channels


def transcode_xma_to_pc_ima(xma_data: bytes, *, channels: int = 1) -> bytes:
    """Decode XMA payload to PCM via ffmpeg, then encode PC IMA ADPCM blocks."""
    ffmpeg = shutil.which("ffmpeg")
    if ffmpeg is None:
        raise UnhandledAudioCodecError(
            "XMA payload requires ffmpeg on PATH for decode→IMA transcode"
        )

    with tempfile.TemporaryDirectory(prefix="mercs2_xma_") as tmp:
        tmp_path = Path(tmp)
        inp = tmp_path / "input.xma"
        wav_out = tmp_path / "decoded.wav"
        inp.write_bytes(xma_data)
        cmd = [
            ffmpeg,
            "-y",
            "-hide_banner",
            "-loglevel",
            "error",
            "-i",
            str(inp),
            "-ac",
            str(max(1, channels)),
            str(wav_out),
        ]
        proc = subprocess.run(cmd, capture_output=True, text=True)
        if proc.returncode != 0 or not wav_out.is_file():
            err = (proc.stderr or proc.stdout or "").strip()
            raise UnhandledAudioCodecError(
                f"ffmpeg XMA decode failed (exit {proc.returncode}): {err[:500]}"
            )
        ima_payload, detected_ch = _wav_bytes_to_ima_payload(wav_out.read_bytes())
        return ima_payload if detected_ch == channels else ima_payload


def transcode_audio_payload_to_pc(
    data: bytes,
    *,
    channels: int = 1,
    filename: str = "",
) -> bytes:
    """Dispatch on detected layout → PC raw IMA ADPCM (no header)."""
    if filename:
        name_ch = None
        from audio_codec_policy import pws_stereo_from_name

        name_ch = pws_stereo_from_name(filename)
        if name_ch is not None:
            channels = name_ch

    probe = probe_pws_payload(data)
    ch = probe.channels if probe.channels > 0 else channels
    payload = data[probe.payload_offset : probe.payload_offset + probe.payload_size]

    if probe.layout in (PwsLayout.RAW_PC_IMA_MONO, PwsLayout.RAW_PC_IMA_STEREO):
        return payload

    if probe.layout == PwsLayout.PC_HEADER_IMA:
        return payload

    if probe.layout in (PwsLayout.RAW_XBOX_ADPCM_MONO, PwsLayout.RAW_XBOX_ADPCM_STEREO):
        return transcode_pws_xbox_to_pc(payload, channels=ch)

    if probe.layout == PwsLayout.XMA_PAYLOAD:
        return transcode_xma_to_pc_ima(data, channels=ch)

    # Last resort: try Xbox ADPCM if block-aligned
    if len(data) >= XBOX_MONO_BLOCK and len(data) % XBOX_MONO_BLOCK == 0:
        return transcode_pws_xbox_to_pc(data, channels=1)
    if len(data) >= XBOX_STEREO_BLOCK and len(data) % XBOX_STEREO_BLOCK == 0:
        return transcode_pws_xbox_to_pc(data, channels=2)

    raise UnhandledAudioCodecError(
        f"unrecognized audio layout for {filename or 'blob'} "
        f"(size={len(data)}, probe={probe.layout.value})"
    )


def transcode_pws_file_to_pc(
    data: bytes,
    *,
    channels: int = 1,
    filename: str = "",
    add_pc_header: bool = True,
    header_param: int = 0,
) -> bytes:
    """Transcode a ``.pws`` file payload to PC format (optional 4-byte header)."""
    ima = transcode_audio_payload_to_pc(data, channels=channels, filename=filename)
    if add_pc_header:
        return wrap_pc_pws_header(ima, param=header_param)
    return ima


def normalize_embedded_wavebank_clip(
    clip: bytes,
    codec: int,
    channels: int,
) -> tuple[bytes, int]:
    """Convert embedded wavebank clip bytes to PC-loadable codec 0x02."""
    from audio_codec_policy import (
        CODEC_IMA_PC,
        CODEC_PCM,
        CODEC_XBOX_ADPCM,
        CODEC_XMA,
        CODEC_XMA2,
        PC_WAVEBANK_TARGET_CODEC,
    )

    ch = channels if channels > 0 else 1
    if codec == CODEC_PCM:
        return clip, CODEC_PCM
    if codec == CODEC_IMA_PC:
        return clip, CODEC_IMA_PC
    if codec == CODEC_XBOX_ADPCM:
        return transcode_pws_xbox_to_pc(clip, channels=ch), PC_WAVEBANK_TARGET_CODEC
    if codec in (CODEC_XMA, CODEC_XMA2):
        return transcode_audio_payload_to_pc(clip, channels=ch), PC_WAVEBANK_TARGET_CODEC
    raise UnhandledAudioCodecError(
        f"no embedded clip transcode for codec 0x{codec:02X} ({len(clip)} bytes)"
    )


if __name__ == "__main__":
    import argparse
    import sys
    from pathlib import Path

    parser = argparse.ArgumentParser(
        description="Transcode Xbox ADPCM .pws to PC IMA ADPCM .pws"
    )
    parser.add_argument("input", type=Path, help="Input Xbox ADPCM .pws file")
    parser.add_argument("output", type=Path, help="Output PC IMA ADPCM .pws file")
    parser.add_argument("--channels", type=int, default=1, choices=[1, 2],
                        help="Number of audio channels (default: 1)")
    args = parser.parse_args()

    if not args.input.exists():
        print(f"Error: {args.input} not found", file=sys.stderr)
        sys.exit(1)

    xbox_data = args.input.read_bytes()
    pc_data = transcode_pws_file_to_pc(
        xbox_data,
        channels=args.channels,
        filename=args.input.name,
    )
    args.output.write_bytes(pc_data)

    block_size = XBOX_MONO_BLOCK if args.channels == 1 else XBOX_STEREO_BLOCK
    n_blocks = len(xbox_data) // block_size
    print(f"Transcoded {n_blocks} blocks ({len(xbox_data)} bytes) → {len(pc_data)} bytes")
