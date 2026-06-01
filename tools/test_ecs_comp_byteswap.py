#!/usr/bin/env python3
"""Regression tests for ECS COMP component byte-swapping (resident META block).

Covers the DLC ``resident_P000_Q3.block`` conversion fixes:
  * compact-format ``info`` discriminator (printable 4-byte hashes such as
    ``N+lT`` / ``iV~b`` must not be mistaken for component names);
  * ModelName variable-record (u32-aligned, not 8-aligned) bodies;
  * "keyed-group" components (PointLocation, 0x2E2659F0) whose bodies are
    ``[u32 count][count × record][u8 flag]`` sequences (mixed u8/u32).
"""
from __future__ import annotations

import struct
import unittest

from ucfx_be_to_le import (
    UnhandledByteSwapError,
    _CompInfo,
    _convert_ecs_comp_data,
    _convert_keyed_group_records,
    _is_ecs_name_identifier,
)


class EcsNameDiscriminatorTests(unittest.TestCase):
    def test_real_names_are_identifiers(self) -> None:
        for name in (b"Transform", b"ModelName", b"PointLocation", b"Name"):
            self.assertTrue(_is_ecs_name_identifier(name), name)

    def test_printable_hashes_are_not_names(self) -> None:
        # 0x4E2B6C54 = b"N+lT", 0x69567E62 = b"iV~b" — compact hashes, not names.
        self.assertFalse(_is_ecs_name_identifier(b"N+lT"))
        self.assertFalse(_is_ecs_name_identifier(b"iV~b"))
        self.assertFalse(_is_ecs_name_identifier(b""))
        self.assertFalse(_is_ecs_name_identifier(b"A"))


class ModelNameTests(unittest.TestCase):
    def test_u32_aligned_but_not_8_aligned(self) -> None:
        # variable record [count][keys][hash]: 5 u32s = 20 bytes (20 % 8 == 4)
        be = struct.pack(">IIIII", 1, 0x80000002, 0xEFCBBD98, 0x00000004, 0x80000003)
        out = _convert_ecs_comp_data(be, _CompInfo("ModelName", 0), {})
        self.assertEqual(out, struct.pack("<IIIII", 1, 0x80000002, 0xEFCBBD98, 0x00000004, 0x80000003))

    def test_non_u32_aligned_raises(self) -> None:
        with self.assertRaises(UnhandledByteSwapError):
            _convert_ecs_comp_data(b"\x00\x00\x00", _CompInfo("ModelName", 0), {})


class KeyedGroupTests(unittest.TestCase):
    def test_pointlocation_record36(self) -> None:
        be = struct.pack(">I", 1) + struct.pack(">I", 0x80005B9F)
        be += struct.pack(">7I", *([0] * 7)) + struct.pack(">I", 0x3F800000)
        be += b"\x00"  # group flag
        self.assertEqual(len(be), 41)
        out = _convert_keyed_group_records(be, 36)
        self.assertEqual(struct.unpack_from("<I", out, 0)[0], 1)
        self.assertEqual(struct.unpack_from("<I", out, 4)[0], 0x80005B9F)
        self.assertEqual(struct.unpack_from("<I", out, 36)[0], 0x3F800000)
        self.assertEqual(out[40], 0x00)

    def test_entity_ref_list_record4_multigroup(self) -> None:
        be = struct.pack(">I", 2) + struct.pack(">II", 0x80000001, 0x80000002) + b"\x01"
        be += struct.pack(">I", 1) + struct.pack(">I", 0x80000003) + b"\x01"
        out = _convert_keyed_group_records(be, 4)
        self.assertEqual(struct.unpack_from("<I", out, 0)[0], 2)
        self.assertEqual(struct.unpack_from("<I", out, 4)[0], 0x80000001)
        self.assertEqual(out[12], 0x01)
        self.assertEqual(struct.unpack_from("<I", out, 13)[0], 1)
        self.assertEqual(out[21], 0x01)

    def test_mismatched_layout_raises(self) -> None:
        be = struct.pack(">I", 1) + struct.pack(">I", 0x80000001) + b"\x01\xff"
        with self.assertRaises(UnhandledByteSwapError):
            _convert_keyed_group_records(be, 4)

    def test_dispatch_via_comp_data(self) -> None:
        be = struct.pack(">I", 1) + struct.pack(">I", 0x80000003) + b"\x01"
        out = _convert_ecs_comp_data(be, _CompInfo("__hash_0x2E2659F0", 0), {})
        self.assertEqual(struct.unpack_from("<I", out, 0)[0], 1)
        self.assertEqual(out[8], 0x01)


if __name__ == "__main__":
    unittest.main()
