#!/usr/bin/env python3
"""PC audio codec policy for Mercenaries 2 DLC porting.

Central definitions for wavebank record codec bytes, PWS payload layout detection,
and normalization targets used by ucfx_be_to_le, dlc_port, and validation tools.
"""
from __future__ import annotations

from dataclasses import dataclass
from enum import Enum

# Wavebank format_bytes[2] / record+6
CODEC_PCM = 0x00
CODEC_XMA = 0x01
CODEC_IMA_PC = 0x02
CODEC_ADPCM_GENERIC = 0x03
CODEC_WMA = 0x04
CODEC_XBOX_ADPCM = 0x05
CODEC_OGG = 0x06
CODEC_MS_IMA_FMT = 0x11
CODEC_XMA2 = 0x69

PC_WAVEBANK_TARGET_CODEC = CODEC_IMA_PC

# Codecs the PC PalSoundEngine accepts in embedded wavebank clips (verified retail).
PC_EMBEDDED_CODECS = frozenset({CODEC_PCM, CODEC_IMA_PC, CODEC_MS_IMA_FMT})

_CODEC_NAMES: dict[int, str] = {
    CODEC_PCM: "PCM",
    CODEC_XMA: "XMA",
    CODEC_IMA_PC: "IMA_ADPCM_PC",
    CODEC_ADPCM_GENERIC: "ADPCM",
    CODEC_WMA: "WMA",
    CODEC_XBOX_ADPCM: "XBOX_ADPCM",
    CODEC_OGG: "OGG",
    CODEC_MS_IMA_FMT: "MS_IMA_FMT",
    CODEC_XMA2: "XMA2",
}


class UnhandledAudioCodecError(ValueError):
    """Raised when no verified transcode path exists for a codec payload."""


def codec_name(codec: int) -> str:
    return _CODEC_NAMES.get(codec, f"UNKNOWN_0x{codec:02X}")


def needs_pc_normalization(codec: int) -> bool:
    """True if wavebank clip codec must be converted before PC load."""
    if codec in PC_EMBEDDED_CODECS:
        return False
    if codec == CODEC_XBOX_ADPCM:
        return True
    if codec in (CODEC_XMA, CODEC_XMA2):
        return True
    return codec not in PC_EMBEDDED_CODECS


def normalization_reason(codec: int) -> str:
    if not needs_pc_normalization(codec):
        return "ok_pc_native"
    if codec == CODEC_XBOX_ADPCM:
        return "xbox_adpcm_to_pc_ima"
    if codec in (CODEC_XMA, CODEC_XMA2):
        return "xma_to_pc_ima"
    return f"unsupported_codec_{codec:02X}"


class PwsLayout(str, Enum):
    """Detected layout of a standalone .pws file or streaming blob."""

    RAW_PC_IMA_MONO = "raw_pc_ima_mono"
    RAW_PC_IMA_STEREO = "raw_pc_ima_stereo"
    RAW_XBOX_ADPCM_MONO = "raw_xbox_adpcm_mono"
    RAW_XBOX_ADPCM_STEREO = "raw_xbox_adpcm_stereo"
    PC_HEADER_IMA = "pc_header_ima"
    XMA_PAYLOAD = "xma_payload"
    UNKNOWN = "unknown"


@dataclass(frozen=True)
class PwsProbe:
    layout: PwsLayout
    channels: int
    header_size: int
    payload_offset: int
    payload_size: int
    block_size: int

    @property
    def needs_transcode(self) -> bool:
        return self.layout in (
            PwsLayout.RAW_XBOX_ADPCM_MONO,
            PwsLayout.RAW_XBOX_ADPCM_STEREO,
            PwsLayout.XMA_PAYLOAD,
        )


# PC retail .pws: u16 param @0, u16 version=1 @2, then raw IMA blocks.
PC_PWS_HEADER_SIZE = 4
PC_PWS_VERSION_LE = 1

MONO_BLOCK = 36
STEREO_BLOCK = 72


def _looks_like_ima_block_header(data: bytes, off: int) -> bool:
    if off + 4 > len(data):
        return False
    predictor = int.from_bytes(data[off : off + 2], "little", signed=True)
    step_index = data[off + 2]
    reserved = data[off + 3]
    return -32768 <= predictor <= 32767 and step_index <= 88 and reserved == 0


def _probe_raw_adpcm(data: bytes, block_size: int, channels: int) -> PwsProbe | None:
    if len(data) < block_size or len(data) % block_size != 0:
        return None
    if not _looks_like_ima_block_header(data, 0):
        return None
    layout = (
        PwsLayout.RAW_PC_IMA_MONO
        if block_size == MONO_BLOCK
        else PwsLayout.RAW_PC_IMA_STEREO
    )
    return PwsProbe(
        layout=layout,
        channels=channels,
        header_size=0,
        payload_offset=0,
        payload_size=len(data),
        block_size=block_size,
    )


def _probe_xbox_adpcm(data: bytes, block_size: int, channels: int) -> PwsProbe | None:
    if len(data) < block_size or len(data) % block_size != 0:
        return None
    if not _looks_like_ima_block_header(data, 0):
        return None
    layout = (
        PwsLayout.RAW_XBOX_ADPCM_MONO
        if block_size == MONO_BLOCK
        else PwsLayout.RAW_XBOX_ADPCM_STEREO
    )
    return PwsProbe(
        layout=layout,
        channels=channels,
        header_size=0,
        payload_offset=0,
        payload_size=len(data),
        block_size=block_size,
    )


def probe_pws_payload(data: bytes) -> PwsProbe:
    """Classify .pws / streaming audio bytes for transcode dispatch."""
    if len(data) == 0:
        return PwsProbe(
            layout=PwsLayout.UNKNOWN,
            channels=1,
            header_size=0,
            payload_offset=0,
            payload_size=0,
            block_size=0,
        )

    # PC header + IMA (retail Data/Audios)
    if len(data) >= PC_PWS_HEADER_SIZE + MONO_BLOCK:
        ver = int.from_bytes(data[2:4], "little")
        if ver == PC_PWS_VERSION_LE:
            payload = data[PC_PWS_HEADER_SIZE:]
            for block_size, ch, layout in (
                (MONO_BLOCK, 1, PwsLayout.PC_HEADER_IMA),
                (STEREO_BLOCK, 2, PwsLayout.PC_HEADER_IMA),
            ):
                if len(payload) >= block_size and len(payload) % block_size == 0:
                    if _looks_like_ima_block_header(payload, 0):
                        return PwsProbe(
                            layout=layout,
                            channels=ch,
                            header_size=PC_PWS_HEADER_SIZE,
                            payload_offset=PC_PWS_HEADER_SIZE,
                            payload_size=len(payload),
                            block_size=block_size,
                        )

    # Block-aligned raw streams (mono then stereo)
    for block_size, channels in ((MONO_BLOCK, 1), (STEREO_BLOCK, 2)):
        probe = _probe_raw_adpcm(data, block_size, channels)
        if probe is not None:
            return probe

    # Xbox ADPCM uses same block sizes; distinguish at transcode time via nibble order.
    # If aligned but not clearly XMA, treat as Xbox ADPCM when high-nibble-first pattern
    # differs from PC (heuristic: byte at 4 has both nibbles non-zero — weak).
    for block_size, channels in ((MONO_BLOCK, 1), (STEREO_BLOCK, 2)):
        if len(data) >= block_size and len(data) % block_size == 0:
            if _looks_like_ima_block_header(data, 0):
                return PwsProbe(
                    layout=PwsLayout.RAW_XBOX_ADPCM_MONO
                    if block_size == MONO_BLOCK
                    else PwsLayout.RAW_XBOX_ADPCM_STEREO,
                    channels=channels,
                    header_size=0,
                    payload_offset=0,
                    payload_size=len(data),
                    block_size=block_size,
                )

    # XMA: not block-aligned to 36/72, or known RIFF/WMAP-ish signatures
    if data[:4] in (b"RIFF", b"XMA2", b"WMAP") or (
        len(data) % MONO_BLOCK != 0 and len(data) % STEREO_BLOCK != 0
    ):
        return PwsProbe(
            layout=PwsLayout.XMA_PAYLOAD,
            channels=1,
            header_size=0,
            payload_offset=0,
            payload_size=len(data),
            block_size=0,
        )

    return PwsProbe(
        layout=PwsLayout.UNKNOWN,
        channels=1,
        header_size=0,
        payload_offset=0,
        payload_size=len(data),
        block_size=0,
    )


def pws_stereo_from_name(filename: str) -> int | None:
    """Guess channel count from DLC/retail .pws filename conventions."""
    lower = filename.lower()
    if "stereo" in lower or ".2ch" in lower:
        return 2
    if "mono" in lower:
        return 1
    if "vo_stream" in lower or "streaming" in lower:
        return 1
    return None
