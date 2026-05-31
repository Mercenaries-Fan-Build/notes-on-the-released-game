#!/usr/bin/env python3
"""Regression tests for large ECS CHDR bodies (guidmap / resident-style layouts)."""
from __future__ import annotations

import struct
import unittest

from ucfx_be_to_le import (
    CHUNK_HDR,
    UnhandledByteSwapError,
    _TYPE_GUIDMAP,
    _convert_chdr_body,
    _convert_container,
)


class ChdrByteswapTests(unittest.TestCase):
    def test_large_guidmap_chdr_swaps_header_only(self) -> None:
        # BE: zero + num_chunks = 0x0000000A
        payload = struct.pack(">II", 0, 10) + b"\xff" * (59051 - 8)
        self.assertEqual(len(payload), 59051)
        self.assertEqual(len(payload) % 4, 3)

        out = _convert_chdr_body(
            payload, type_hash=_TYPE_GUIDMAP, context="META",
        )
        self.assertEqual(len(out), 59051)
        self.assertEqual(struct.unpack_from("<I", out, 0)[0], 0)
        self.assertEqual(struct.unpack_from("<I", out, 4)[0], 10)
        self.assertEqual(out[8:], payload[8:])

    def test_small_chdr_still_full_swap(self) -> None:
        be = struct.pack(">II", 0, 3)
        out = _convert_chdr_body(be, type_hash=_TYPE_GUIDMAP, context=None)
        self.assertEqual(struct.unpack_from("<II", out, 0), (0, 3))

    def test_non_ecs_odd_chdr_raises(self) -> None:
        with self.assertRaises(UnhandledByteSwapError):
            _convert_chdr_body(b"\x01\x02\x03", type_hash=0xF011157A, context=None)

    def test_container_with_large_chdr_roundtrip_size(self) -> None:
        """Minimal UCFX: CHDR sentinel + large CHDR body must not raise."""
        data_area_off = 20 + CHUNK_HDR  # one descriptor row
        chdr_body = struct.pack(">II", 0, 1) + b"\xab" * 99
        body_area = bytearray(chdr_body)

        container = bytearray()
        container += b"XFCU"
        container += struct.pack(">IIII", data_area_off, 0, 0, 1)
        container += b"RDHC"  # BE descriptor stores tag reversed (CHDR)
        container += struct.pack(">IIII", 0, len(chdr_body), 0, 0)
        while len(container) < data_area_off:
            container.append(0)
        container += body_area

        stats: dict = {}
        out = _convert_container(
            bytes(container), stats, type_hash=_TYPE_GUIDMAP, permissive=False,
        )
        self.assertTrue(out.startswith(b"UCFX"))
        self.assertEqual(stats.get("errors", []), [])


if __name__ == "__main__":
    unittest.main()
