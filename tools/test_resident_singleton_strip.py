#!/usr/bin/env python3
"""Tests for the cross-WAD dedupe strip of redundant world-container singletons.

Validates ``dlc_port._apply_overrides_and_strips`` with ``strip_entries`` removes
ONLY the three world-container singletons that the base VZ resident already
provides (worldentity / guidmap / foliage) and leaves every other entry of the
dlc01 script resident byte-identical, with a consistent entry table.

See docs/render_view_handle_crash_analysis.md (§ implemented fix).

The synthetic test always runs.  The real-block test runs only when the
already-extracted dlc01 resident (patch block 464) is present under
``output/_scratch`` (extract it cheaply with
``tools/extract_single_block.py --wad game-files/vz-patch.wad
--path "dlc01\\resident_P000_Q3.block" --keep --scratch-root output/_scratch``).
"""
from __future__ import annotations

import struct
import unittest
from pathlib import Path

from dlc_port import (
    _REDUNDANT_RESIDENT_SINGLETONS,
    _TYPE_FOLIAGE,
    _TYPE_GUIDMAP,
    _TYPE_WORLD_ENTITY,
    _apply_overrides_and_strips,
)
from wad_patcher import parse_block_entries

REPO_ROOT = Path(__file__).resolve().parent.parent

# (asset_hash, type_hash) for the three singletons.
WORLDENTITY = (0x50075B3B, _TYPE_WORLD_ENTITY)
GUIDMAP = (0x385EA82C, _TYPE_GUIDMAP)
FOLIAGE = (0x27E02A15, _TYPE_FOLIAGE)
SINGLETON_HASHES = {0x50075B3B, 0x385EA82C, 0x27E02A15}


def _build_block(entries: list[tuple[int, int, bytes]]) -> bytes:
    """Assemble a PC-format block: count + entry table (field_c=0) + chunks."""
    out = struct.pack("<I", len(entries))
    for name_hash, type_hash, chunk in entries:
        out += struct.pack("<IIII", name_hash, type_hash, 0, len(chunk))
    for _nh, _th, chunk in entries:
        out += chunk
    return out


def _chunk(seed: int, size: int) -> bytes:
    """A deterministic UCFX-ish chunk with a trailing CSUM, of exact length."""
    body = b"UCFX" + bytes((seed + i) & 0xFF for i in range(max(size - 12, 0)))
    body += b"CSUM" + struct.pack("<I", seed)
    return body[:size] if len(body) >= size else body + b"\x00" * (size - len(body))


class SyntheticStripTests(unittest.TestCase):
    def setUp(self) -> None:
        # Two ordinary entries, the three singletons interleaved, two more.
        self.entries = [
            (0xAAAA0001, 0xBCFE6314, _chunk(0x10, 64)),   # script-ish (keep)
            (WORLDENTITY[0], WORLDENTITY[1], _chunk(0x20, 200)),
            (0xAAAA0002, 0x18166555, _chunk(0x30, 96)),   # animation (keep)
            (GUIDMAP[0], GUIDMAP[1], _chunk(0x40, 128)),
            (0xAAAA0003, 0x42498680, _chunk(0x50, 48)),   # script (keep)
            (FOLIAGE[0], FOLIAGE[1], _chunk(0x60, 160)),
            (0xAAAA0004, 0xF011157A, _chunk(0x70, 80)),   # texture (keep)
        ]
        self.block = _build_block(self.entries)

    def test_strips_only_the_three_singletons(self) -> None:
        strip = frozenset({WORLDENTITY, GUIDMAP, FOLIAGE})
        out, stripped = _apply_overrides_and_strips(self.block, None, None, strip)
        self.assertEqual(stripped, 3)

        kept = parse_block_entries(out)
        self.assertEqual(len(kept), 4)
        kept_hashes = {e["hash"] for e in kept}
        self.assertFalse(kept_hashes & SINGLETON_HASHES,
                         "no singleton hash should survive")
        self.assertEqual(
            kept_hashes, {0xAAAA0001, 0xAAAA0002, 0xAAAA0003, 0xAAAA0004})

    def test_kept_entries_byte_identical(self) -> None:
        strip = frozenset({WORLDENTITY, GUIDMAP, FOLIAGE})
        out, _ = _apply_overrides_and_strips(self.block, None, None, strip)
        kept = parse_block_entries(out)
        want = {nh: chunk for nh, th, chunk in self.entries
                if nh not in SINGLETON_HASHES}
        for e in kept:
            got = out[e["offset"]:e["offset"] + e["size"]]
            self.assertEqual(got, want[e["hash"]],
                             f"chunk for 0x{e['hash']:08X} must be untouched")

    def test_entry_table_offsets_consistent(self) -> None:
        """field_c must be 0 and chunks must be densely sequential."""
        strip = frozenset({WORLDENTITY, GUIDMAP, FOLIAGE})
        out, _ = _apply_overrides_and_strips(self.block, None, None, strip)
        count = struct.unpack_from("<I", out, 0)[0]
        pos = 4 + count * 16
        total_chunk = 0
        for i in range(count):
            nh, th, fc, sz = struct.unpack_from("<IIII", out, 4 + i * 16)
            self.assertEqual(fc, 0, "field_c must be 0 (engine walks sequentially)")
            total_chunk += sz
        self.assertEqual(pos + total_chunk, len(out),
                         "header + concatenated chunks must equal block size")

    def test_packed_field_pages_recompute_smaller(self) -> None:
        """The worker recomputes decomp pages from the stripped size."""
        strip = frozenset({WORLDENTITY, GUIDMAP, FOLIAGE})
        out, _ = _apply_overrides_and_strips(self.block, None, None, strip)
        pages_before = (len(self.block) + 0x7FFF) // 0x8000
        pages_after = (len(out) + 0x7FFF) // 0x8000
        self.assertLessEqual(pages_after, pages_before)
        self.assertGreater(len(self.block), len(out))

    def test_no_strip_entries_is_noop(self) -> None:
        out, stripped = _apply_overrides_and_strips(self.block, None, None, None)
        self.assertEqual(stripped, 0)
        self.assertEqual(out, self.block)

    def test_only_pairs_in_strip_set_removed(self) -> None:
        """A singleton hash under a DIFFERENT type_hash must NOT be stripped."""
        wrong_type = [
            (WORLDENTITY[0], 0xBCFE6314, _chunk(0x11, 40)),  # right hash, wrong type
            (0xAAAA0009, 0x18166555, _chunk(0x22, 40)),
        ]
        block = _build_block(wrong_type)
        out, stripped = _apply_overrides_and_strips(
            block, None, None, frozenset({WORLDENTITY}))
        self.assertEqual(stripped, 0, "must match (hash,type) pair, not hash alone")
        self.assertEqual(out, block)


class RealBlock464StripTest(unittest.TestCase):
    """Validate against the actual extracted dlc01 resident if present."""

    def _find_block(self) -> Path | None:
        scratch = REPO_ROOT / "output" / "_scratch"
        if not scratch.is_dir():
            return None
        hits = list(scratch.glob("**/*dlc01__resident_P000_Q3*.block.bin"))
        return hits[0] if hits else None

    def test_real_resident_drops_three_singletons(self) -> None:
        blk_path = self._find_block()
        if blk_path is None:
            self.skipTest("extracted dlc01 resident (block 464) not present")
        data = blk_path.read_bytes()
        before = parse_block_entries(data)
        present = {e["hash"] for e in before} & SINGLETON_HASHES
        if present != SINGLETON_HASHES:
            self.skipTest(f"extracted block lacks the singletons (found {present})")

        strip = frozenset({WORLDENTITY, GUIDMAP, FOLIAGE})
        out, stripped = _apply_overrides_and_strips(data, None, None, strip)
        self.assertEqual(stripped, 3)

        after = parse_block_entries(out)
        self.assertEqual(len(after), len(before) - 3)
        after_hashes = {e["hash"] for e in after}
        self.assertFalse(after_hashes & SINGLETON_HASHES)

        # Every surviving entry is byte-identical to its original chunk.
        before_chunks = {e["hash"]: data[e["offset"]:e["offset"] + e["size"]]
                         for e in before if e["hash"] not in SINGLETON_HASHES}
        for e in after:
            got = out[e["offset"]:e["offset"] + e["size"]]
            self.assertEqual(got, before_chunks[e["hash"]])

    def test_constant_matches_spec(self) -> None:
        self.assertEqual(
            _REDUNDANT_RESIDENT_SINGLETONS,
            frozenset({WORLDENTITY, GUIDMAP, FOLIAGE}),
        )


if __name__ == "__main__":
    unittest.main()
