#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Mercenaries 2 CSUM checksum (CRC-32, init=0, no final XOR).

Standalone so it survives the retirement of the Python byte-swap converter
(``ucfx_be_to_le.py``). The Rust converter's equivalent is
``mercs2_formats::crc32::crc32_mercs2``.
"""
from __future__ import annotations

import zlib


def crc32_mercs2(data: bytes) -> int:
    """CRC-32 with init=0, no final XOR (Mercenaries 2 CSUM).

    ``zlib.crc32(data, 0xFFFFFFFF)`` uses effective init=0 internally (zlib XORs
    the seed with 0xFFFFFFFF), and the outer ``^0xFFFFFFFF`` cancels zlib's own
    final inversion — net result is init=0, no final XOR.
    """
    return (zlib.crc32(data, 0xFFFFFFFF) ^ 0xFFFFFFFF) & 0xFFFFFFFF
