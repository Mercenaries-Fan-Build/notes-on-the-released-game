# -*- coding: utf-8 -*-
"""
Compatibility shim — implementations live under :mod:`hk_anim`.

Import ``TRS``, ``AnimationIR``, and decoders from here or from ``hk_anim`` directly.
"""

from __future__ import annotations

from hk_anim import (
    AnimationIR,
    TRS,
    decode_delta,
    decode_interleaved,
    decode_wavelet,
    harvest_annotation_strings,
)

__all__ = [
    "TRS",
    "AnimationIR",
    "harvest_annotation_strings",
    "decode_interleaved",
    "decode_delta",
    "decode_wavelet",
]
