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
    _convert_hibernation_records,
    _convert_keyed_group_records,
    _convert_numeric_records,
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


class HibernationControlTests(unittest.TestCase):
    """HibernationControl payload is u16 + u8 + u8 + u8 + bitflags (stride 10).

    A blanket u32 sweep corrupts the u16; only the entity-key u32 and the
    payload u16 may be swapped. Byte pattern verified against retail PC
    layers_static block 29 (raw ``XX 00 a0 3c 14 00``) and DLC block 18.
    """

    def _be_record(self, key: int, u16: int) -> bytes:
        # BE source: key, u16 field, then constant u8 params a0/3c/14/00.
        return struct.pack(">I", key) + struct.pack(">H", u16) + bytes([0xA0, 0x3C, 0x14, 0x00])

    def test_typed_swap_matches_retail_layout(self) -> None:
        be = self._be_record(0x00150626, 0x00FE)
        out = _convert_hibernation_records(be)
        # entity key + payload u16 swapped; u8/bit tail untouched.
        self.assertEqual(struct.unpack_from("<I", out, 0)[0], 0x00150626)
        self.assertEqual(struct.unpack_from("<H", out, 4)[0], 0x00FE)
        self.assertEqual(out[6:10], bytes([0xA0, 0x3C, 0x14, 0x00]))
        self.assertEqual(out.hex(), "26061500" + "fe00a03c1400")

    def test_typed_swap_differs_from_u32_sweep(self) -> None:
        # The old (buggy) numeric u32 sweep would scramble the u16 into 0xA03C.
        be = self._be_record(0x00150626, 0x00FE)
        buggy = _convert_numeric_records(be, 10)
        good = _convert_hibernation_records(be)
        self.assertNotEqual(buggy, good)
        # Buggy output reads a constant garbage u16 (0xA03C) at payload+0.
        self.assertEqual(struct.unpack_from("<H", buggy, 4)[0], 0xA03C)
        # Correct output preserves the real per-entity value.
        self.assertEqual(struct.unpack_from("<H", good, 4)[0], 0x00FE)

    def test_dispatch_via_comp_data(self) -> None:
        be = self._be_record(0x003B5341, 0x01F4) + self._be_record(0x003C5341, 0x00E3)
        out = _convert_ecs_comp_data(be, _CompInfo("HibernationControl", 10), {})
        self.assertEqual(struct.unpack_from("<H", out, 4)[0], 0x01F4)
        self.assertEqual(struct.unpack_from("<H", out, 14)[0], 0x00E3)

    def test_bad_size_raises(self) -> None:
        with self.assertRaises(UnhandledByteSwapError):
            _convert_hibernation_records(b"\x00" * 13)


if __name__ == "__main__":
    unittest.main()
