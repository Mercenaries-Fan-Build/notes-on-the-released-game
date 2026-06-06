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
    _convert_chdr_body,
    _convert_ecs_comp_data,
    _convert_ecs_info,
    _convert_efct_header,
    _convert_hibernation_records,
    _convert_keyed_group_records,
    _convert_numeric_records,
    _convert_u16_array,
    _convert_u32_array,
    _is_ecs_name_identifier,
    _swap_chdr_header,
)


class EcsInfoConversionTests(unittest.TestCase):
    """`info` bodies come in named and compact (hash-leading, no name) forms.

    The historical bug: a 4-byte BE component hash routinely contains a 0x00 byte
    (e.g. 1D E5 C8 24 -> "Name"), and the old converter read that inner NUL as a
    name terminator, computed u32_start past the body, and bailed -> shipped the
    body big-endian. The PC engine then read a byte-reversed hash (failed component
    lookup -> null pool slot, AV 0x004CC064) and huge LE counts (over-alloc, AV
    0x0084DD5B). These tests lock in the fix and Python/Rust parity.
    """

    def test_compact_info_swaps_all_u32s(self) -> None:
        # Real BE compact info from xbox-vz.wad: [u32 hash][u32 a=91][u32 b=3][u32 c=0].
        be = bytes.fromhex("fb31f1ef0000005b0000000300000000")
        out = _convert_ecs_info(be)
        self.assertEqual(out, bytes.fromhex("eff131fb5b00000003000000 00000000".replace(" ", "")))
        # NOT a no-op (the regression): the body must actually change.
        self.assertNotEqual(out, be, "compact info must be byte-swapped, not bailed on inner NUL")

    def test_compact_info_hash_reads_as_component(self) -> None:
        # 1D E5 C8 24 is the "Name" component hash stored byte-reversed on disk.
        # After conversion the engine must read 0x1DE5C824 (LE), not 0x24C8E51D.
        be = bytes.fromhex("1de5c824000000010000002f00000000")
        out = _convert_ecs_info(be)
        self.assertEqual(struct.unpack_from("<I", out, 0)[0], 0x1DE5C824)
        self.assertEqual(struct.unpack_from("<I", out, 4)[0], 1)   # field a small, swapped
        self.assertEqual(struct.unpack_from("<I", out, 8)[0], 47)

    def test_named_info_preserves_name_swaps_trailing(self) -> None:
        be = b"Name\x00" + struct.pack(">IIII", 0x24C8E51D, 1, 101, 0)
        out = _convert_ecs_info(be)
        self.assertEqual(out, b"Name\x00" + struct.pack("<IIII", 0x24C8E51D, 1, 101, 0))

    def test_compact_info_matches_blind_u32_array(self) -> None:
        # For a no-name body, the correct conversion is exactly _convert_u32_array.
        be = bytes.fromhex("e18afd6500000053000000510 0000000".replace(" ", ""))
        self.assertEqual(_convert_ecs_info(be), _convert_u32_array(be))


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


class ChdrHeaderTests(unittest.TestCase):
    """CHDR header is ``{ u16 @+0 ; u16 @+2 ; u32 @+4 }`` (engine 0x654940).

    The ``u16 @ +2`` gates the Transform record stride ([0x01176078] >= 0x2A →
    stride 42, else 40). A whole-u32 swap of the first 8 bytes transposes the
    two u16 fields, zeroing the stride gate and crashing the spatial-hash on
    save-load. Oracle: retail layers_static block 29 CHDR body =
    ``00 00 38 00 02 00 00 00`` (u16@+2 = 0x38 = 56 ≥ 42 → stride 42 → OK);
    DLC source BE = ``00 00 00 38 | 00 00 00 02``.
    """

    def test_per_u16_swap_matches_retail_oracle(self) -> None:
        # BE source: u16@+0=0x0000, u16@+2=0x0038, u32@+4=0x00000002.
        be = bytes.fromhex("00000038") + struct.pack(">I", 0x00000002)
        out = _swap_chdr_header(be)
        # u16@+2 must be 56 (0x0038) so the engine reads stride 42.
        self.assertEqual(struct.unpack_from("<H", out, 2)[0], 0x0038)
        self.assertEqual(struct.unpack_from("<H", out, 0)[0], 0x0000)
        # flags is a genuine u32 → whole-u32 swap is correct there.
        self.assertEqual(struct.unpack_from("<I", out, 4)[0], 0x00000002)
        # Exact retail block-29 byte layout.
        self.assertEqual(out.hex(), "00003800" + "02000000")

    def test_old_whole_u32_swap_would_zero_the_stride_gate(self) -> None:
        # Regression guard: the OLD behavior reversed the first 8 bytes as two
        # u32 words, which transposes the u16 fields → u16@+2 == 0 (< 42).
        be = bytes.fromhex("00000038") + struct.pack(">I", 0x00000002)
        buggy = struct.pack("<I", struct.unpack_from(">I", be, 0)[0])
        buggy += struct.pack("<I", struct.unpack_from(">I", be, 4)[0])
        self.assertEqual(buggy.hex(), "38000000" + "02000000")
        self.assertEqual(struct.unpack_from("<H", buggy, 2)[0], 0x0000)
        # The fixed header swap disagrees with the buggy whole-u32 swap.
        self.assertNotEqual(_swap_chdr_header(be), buggy)

    def test_convert_chdr_body_8byte_block18(self) -> None:
        # Full 8-byte CHDR body path (block 18 dlc01_dlccon004_roads shape).
        be = bytes.fromhex("0000003800000002")
        out = _convert_chdr_body(be, type_hash=0, context=None)
        self.assertEqual(out.hex(), "0000380002000000")
        self.assertEqual(struct.unpack_from("<H", out, 2)[0], 0x0038)

    def test_convert_chdr_body_large_guidmap_only_swaps_header(self) -> None:
        # Large/guidmap CHDR: only the 8-byte header is swapped; the trailing
        # region (reached via sibling descriptors) is left untouched.
        tail = bytes(range(0, 40))
        be = bytes.fromhex("0000003800000002") + tail
        out = _convert_chdr_body(be, type_hash=0, context="META")
        self.assertEqual(out[:8].hex(), "0000380002000000")
        self.assertEqual(out[8:], tail, "trailing guidmap region must be untouched")


class EfctHeaderTests(unittest.TestCase):
    """EFCT effect header is an array of u16 fields. Engine loader 0x00492AF0.

    The constant ``0x0226`` magic is a u16 at byte +2 and the sub-component
    count is a u16 at byte +14 — in BOTH the big-endian source and the
    little-endian output. A per-field **u16** swap keeps both in place; a
    whole-body **u32** swap transposes each pair of u16s, moving the magic to +0
    and **zeroing the +14 count**, which makes the engine allocate a zero-length
    descriptor array and crash on the first COLR append (AV write @ 0x00493102).

    Oracle is **real Xbox 360 DLC bytes** (blocks\\dlc01\\effects_P000_Q3.block,
    entry 0x5af5da9f), cross-checked against retail ``pc-game-vz.wad`` EFCT
    (all 314 chunks: magic@+2 = 0x0226, count@+14 in 2..21).
    """

    # Real Xbox 360 DLC EFCT body (big-endian, as extracted from the retail DLC).
    BE_SOURCE = bytes.fromhex("0002022600000002" "000c0000000000040320")
    # Correct LE (matches the retail PC layout): magic 0x0226 @ +2, count 4 @ +14.
    CORRECT_LE = bytes.fromhex("0200260200000200" "0c00000000000400" "2003")

    def test_u16_swap_reproduces_retail_oracle(self) -> None:
        out = _convert_efct_header(self.BE_SOURCE)
        self.assertEqual(out, self.CORRECT_LE)
        # Magic 0x0226 lands at byte +2; sub-component count 0x0004 at +14.
        self.assertEqual(struct.unpack_from("<H", out, 2)[0], 0x0226)
        self.assertEqual(struct.unpack_from("<H", out, 14)[0], 0x0004)

    def test_u32_swap_zeroes_the_count_gate(self) -> None:
        good = _convert_efct_header(self.BE_SOURCE)
        # The regressed whole-u32-word swap moves the magic to +0 and zeroes +14.
        buggy = _convert_u32_array(self.BE_SOURCE)
        self.assertNotEqual(buggy, good)
        self.assertEqual(struct.unpack_from("<H", buggy, 0)[0], 0x0226)
        self.assertEqual(struct.unpack_from("<H", buggy, 14)[0], 0x0000)
        # The u16 swap keeps the real count alive.
        self.assertEqual(struct.unpack_from("<H", good, 14)[0], 0x0004)

    def test_bad_size_raises(self) -> None:
        with self.assertRaises(UnhandledByteSwapError):
            _convert_efct_header(b"\x00\x00\x00")  # odd size


if __name__ == "__main__":
    unittest.main()
