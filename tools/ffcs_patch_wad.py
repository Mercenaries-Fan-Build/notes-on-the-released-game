#!/usr/bin/env python3
"""Shared FFCS patch WAD builder for Mercenaries 2.

This module provides the canonical implementation for assembling PC
``vz-patch.wad`` files.  Both single-block mods (via ``build_patch_wad.py``)
and multi-block DLC ports (via ``dlc_port.py``) call into this module so
there is exactly one copy of the FFCS layout logic, certificate blob, and
PTHS trailer.

Public API:
  - build_patch_wad_single(...)   — one block (mod workflow)
  - build_patch_wad_multi(...)    — N blocks (DLC / batch workflow)
  - merge_patch_wads(...)         — append blocks to an existing patch WAD
  - read_patch_wad(...)           — parse an existing patch WAD's INDX/ASET/PTHS/DATA
  - PTHS_TRAILER, FFCS_CERT_BLOB — canonical constants
"""
from __future__ import annotations

import struct
import zlib
from dataclasses import dataclass, field
from pathlib import Path


# ── Constants ─────────────────────────────────────────────────────────

PAGE_SIZE = 0x8000  # 32 KB

PTHS_TRAILER = (
    b"xa37dd45ffe100bfffcc9753aabac325f07cb3fa231144fe2e33ae4783feead2"
    b"b8a73ff021fac326df0ef9753ab9cdf6573ddff0312fab0b0ff39779eaff312"
    b"a4f5de65892ffee33a44569bebf21f66d22e54a22347efd375981188743afd9"
    b"9baacc342d88a99321235798725fedcbf43252669dade32415fee89da543bf23"
    b"d4ex"
)
assert len(PTHS_TRAILER) == 258

FFCS_CERT_BLOB = bytes([
    0xa8, 0xd8, 0x46, 0xfa, 0x28, 0x87, 0x0e, 0x14,
    0x9a, 0xd3, 0x31, 0x71, 0xe2, 0x54, 0x0a, 0x8f,
    0xf8, 0xab, 0x0a, 0x3b, 0x3e, 0xf1, 0x5e, 0x66,
    0xd0, 0xf6, 0x53, 0xf7, 0x78, 0xe9, 0xe5, 0x39,
    0x5a, 0x54, 0x22, 0xc1, 0x54, 0x1a, 0xb8, 0xe6,
    0x87, 0x4d, 0xdf, 0xe8, 0xc7, 0x59, 0x73, 0x20,
    0x4e, 0x90, 0x0b, 0x60, 0x14, 0x3c, 0x27, 0xe5,
    0x61, 0x2d, 0x98, 0xde, 0xce, 0x7a, 0xe7, 0x99,
    0x55, 0x65, 0x16, 0x18, 0x5d, 0xc3, 0x47, 0x56,
    0xbc, 0x8d, 0x0b, 0xfa, 0x50, 0x42, 0x72, 0x5b,
    0x86, 0x2f, 0x61, 0x34, 0x10, 0xca, 0x8b, 0x9f,
    0x5c, 0x81, 0x02, 0x16, 0x20, 0x83, 0x0e, 0xfe,
    0xf2, 0x47, 0xce, 0xac, 0xc4, 0x30, 0x7d, 0x4d,
    0xd5, 0x29, 0x48, 0xea, 0x7a, 0x15, 0x11, 0xf0,
    0x14, 0x63, 0xfe, 0xbc, 0x5a, 0xbd, 0x08, 0x56,
    0x7f, 0x80, 0x10, 0x63, 0x6a, 0xdf, 0xb9, 0x59,
    0x07, 0x93, 0x56, 0x7c, 0x71, 0x03, 0xe7, 0xec,
    0xbb, 0x49, 0xf6, 0x1c, 0x80, 0x86, 0x49, 0x42,
])
assert len(FFCS_CERT_BLOB) == 144


# ── Data structures ───────────────────────────────────────────────────

@dataclass
class PatchBlock:
    """One block destined for a patch WAD."""
    compressed_data: bytes
    path_string: str
    aset_entries: list[dict] = field(default_factory=list)
    packed_field: int = 1
    flags: int = 0x8000


@dataclass
class PatchWADContents:
    """Parsed contents of an existing patch WAD (for merging)."""
    blocks: list[PatchBlock]
    csum_value: int = 0


# ── Helpers ───────────────────────────────────────────────────────────

def _align_up(value: int, alignment: int) -> int:
    return (value + alignment - 1) & ~(alignment - 1)


def crc32_mercs2(data: bytes) -> int:
    """CRC-32 with init=0xFFFFFFFF, no final XOR (Mercenaries 2 CSUM)."""
    return (zlib.crc32(data, 0xFFFFFFFF) ^ 0xFFFFFFFF) & 0xFFFFFFFF


# ── Single-block builder (backward-compat for build_patch_wad.py) ─────

def build_patch_wad_single(
    *,
    indx_entry: dict,
    aset_entries: list[dict],
    pths_string: str,
    compressed_block: bytes,
    csum_value: int = 0,
) -> bytes:
    """Build a patch WAD containing exactly one block.

    This is the API used by the existing mod workflows in build_patch_wad.py.
    Signature matches the original ``build_patch_wad()`` function.
    """
    block = PatchBlock(
        compressed_data=compressed_block,
        path_string=pths_string,
        aset_entries=aset_entries,
        packed_field=indx_entry.get("packed_field", 1),
        flags=indx_entry.get("flags", 0x8000),
    )
    return build_patch_wad_multi(blocks=[block], csum_value=csum_value)


# ── Multi-block builder (canonical implementation) ────────────────────

def build_patch_wad_multi(
    *,
    blocks: list[PatchBlock],
    csum_value: int = 0,
    csum_meta: int | None = None,
    cert_blob: bytes = FFCS_CERT_BLOB,
) -> bytes:
    """Build a PC FFCS patch WAD containing one or more blocks.

    Layout:
      [0x000 - 0x0FF]  FFCS header (256 bytes)
      [0x8000]         INDX data (N × 12 bytes)
      [INDX_end]       ASET data (total_aset × 16 bytes)
      [ASET_end]       PTHS data (null-terminated paths + trailer)
      [0x208000]       DATA: concatenated page-aligned sges blocks

    *csum_meta* sets the CSUM chunk's ``meta`` field.  In the retail WAD this
    equals the number of ASET entries belonging to the resident (always-loaded)
    block.  When *None* (default), auto-detected from a block whose path
    contains ``resident_P000_Q3`` — falls back to 0 if no resident is found.
    """
    num_blocks = len(blocks)

    # ── Compute INDX / ASET / PTHS layout ──
    indx_offset = 0x8000
    indx_size = num_blocks * 12

    aset_offset = indx_offset + indx_size
    all_aset: list[tuple[int, dict]] = []  # (block_idx, entry)
    for blk_idx, blk in enumerate(blocks):
        for entry in blk.aset_entries:
            all_aset.append((blk_idx, entry))
    total_aset = len(all_aset)
    aset_size = total_aset * 16

    pths_offset = aset_offset + aset_size
    pths_bytes = b""
    for blk in blocks:
        pths_bytes += blk.path_string.encode("utf-8") + b"\x00"
    pths_bytes += PTHS_TRAILER + b"\x00"

    # ── DATA layout (page-aligned blocks starting at 0x208000) ──
    data_offset = 0x208000
    data_page_start = data_offset // PAGE_SIZE

    block_layouts: list[tuple[int, int, bytes]] = []  # (page_idx, pages, data)
    current_page = data_page_start
    for blk in blocks:
        pages_needed = _align_up(len(blk.compressed_data), PAGE_SIZE) // PAGE_SIZE
        block_layouts.append((current_page, pages_needed, blk.compressed_data))
        current_page += pages_needed

    file_size = current_page * PAGE_SIZE

    # ── Resolve CSUM meta (resident ASET entry count) ──
    if csum_meta is None:
        # Auto-detect: count ASET entries for the block whose path looks
        # like the resident pack (e.g. "resident_P000_Q3.block").
        csum_meta = 0
        for blk in blocks:
            lower = blk.path_string.lower()
            if "resident_p000_q3" in lower and "resident2" not in lower:
                csum_meta = len(blk.aset_entries)
                break

    # ── Build FFCS header (256 bytes) ──
    header = bytearray(256)
    struct.pack_into("<4sII", header, 0, b"FFCS", 2, 7)

    cr = 0x0C
    struct.pack_into("<4sII", header, cr + 0,
                     b"INDX", indx_offset, num_blocks)
    struct.pack_into("<4sII", header, cr + 12,
                     b"DATA", data_offset, 36)
    struct.pack_into("<4sII", header, cr + 24,
                     b"CSUM", csum_value, csum_meta)
    struct.pack_into("<4sII", header, cr + 36,
                     b"ASET", aset_offset, total_aset)
    struct.pack_into("<4sII", header, cr + 48,
                     b"PTHS", pths_offset, num_blocks)
    header[0x48:0x48 + 144] = cert_blob

    # ── Assemble output buffer ──
    out = bytearray(file_size)
    out[:256] = header

    # Write INDX entries
    for i, (page_idx, pages, _data) in enumerate(block_layouts):
        blk = blocks[i]
        struct.pack_into("<III", out, indx_offset + i * 12,
                         page_idx,
                         blk.packed_field,
                         (blk.flags << 16) | pages)

    # Write ASET entries (remap block index into u32_2 high bits)
    for i, (blk_idx, entry) in enumerate(all_aset):
        off = aset_offset + i * 16
        u2_remapped = (blk_idx << 16) | (entry.get("u32_2", 0) & 0xFFFF)
        struct.pack_into("<IIII", out, off,
                         entry["asset_hash"],
                         entry.get("u32_1", 0xFFFFFFFF),
                         u2_remapped,
                         entry.get("u32_3", 0))

    # Write PTHS
    out[pths_offset:pths_offset + len(pths_bytes)] = pths_bytes

    # Write DATA (compressed blocks at their page offsets)
    for page_idx, _pages, blk_data in block_layouts:
        blk_offset = page_idx * PAGE_SIZE
        out[blk_offset:blk_offset + len(blk_data)] = blk_data

    return bytes(out)


# ── Read existing patch WAD ───────────────────────────────────────────

def read_patch_wad(wad_path: Path) -> PatchWADContents:
    """Parse an existing patch WAD's structure for merging."""
    raw = wad_path.read_bytes()
    if raw[:4] != b"FFCS":
        raise ValueError(f"Not an FFCS WAD: {wad_path}")

    # Parse chunk rows
    chunks: dict[str, tuple[int, int]] = {}
    for i in range(5):
        off = 0x0C + i * 12
        tag = raw[off:off + 4].decode("ascii")
        offset, meta = struct.unpack_from("<II", raw, off + 4)
        chunks[tag] = (offset, meta)

    indx_off, indx_count = chunks["INDX"]
    aset_off, aset_count = chunks["ASET"]
    pths_off, pths_count = chunks["PTHS"]
    data_off, _data_meta = chunks["DATA"]
    csum_val = chunks.get("CSUM", (0, 0))[0]

    # Parse INDX
    indx_entries: list[tuple[int, int, int]] = []
    for i in range(indx_count):
        off = indx_off + i * 12
        page_idx, packed, flags_pages = struct.unpack_from("<III", raw, off)
        indx_entries.append((page_idx, packed, flags_pages))

    # Parse ASET — group by block index
    aset_by_block: dict[int, list[dict]] = {}
    for i in range(aset_count):
        off = aset_off + i * 16
        u0, u1, u2, u3 = struct.unpack_from("<IIII", raw, off)
        blk_idx = (u2 >> 16) & 0xFFFF
        entry = {"asset_hash": u0, "u32_1": u1, "u32_2": u2, "u32_3": u3}
        aset_by_block.setdefault(blk_idx, []).append(entry)

    # Parse PTHS (null-separated strings, excluding trailer)
    pths_region = raw[pths_off:]
    path_strings: list[str] = []
    pos = 0
    for _ in range(pths_count):
        nul = pths_region.find(b"\x00", pos)
        if nul < 0:
            break
        s = pths_region[pos:nul].decode("utf-8", errors="replace")
        path_strings.append(s)
        pos = nul + 1

    # Extract each block's compressed data
    result_blocks: list[PatchBlock] = []
    for i, (page_idx, packed, flags_pages) in enumerate(indx_entries):
        pages = flags_pages & 0xFFFF
        flags = (flags_pages >> 16) & 0xFFFF
        blk_offset = page_idx * PAGE_SIZE
        blk_size = pages * PAGE_SIZE

        # Find actual sges extent (may be smaller than page-padded)
        blk_data = raw[blk_offset:blk_offset + blk_size]
        # Trim trailing zeros to recover real compressed size
        actual_end = blk_size
        while actual_end > 4 and blk_data[actual_end - 1] == 0:
            actual_end -= 1
        # Round up to avoid cutting mid-stream
        actual_end = min(blk_size, _align_up(actual_end, 4))
        blk_data = raw[blk_offset:blk_offset + actual_end]

        path = path_strings[i] if i < len(path_strings) else f"block_{i:05d}"
        result_blocks.append(PatchBlock(
            compressed_data=blk_data,
            path_string=path,
            aset_entries=aset_by_block.get(i, []),
            packed_field=packed,
            flags=flags,
        ))

    return PatchWADContents(blocks=result_blocks, csum_value=csum_val)


# ── Merge patch WADs ──────────────────────────────────────────────────

def merge_patch_wads(
    existing_path: Path,
    new_blocks: list[PatchBlock],
    *,
    replace: bool = False,
) -> bytes:
    """Read an existing patch WAD and append (or replace) blocks, returning new WAD bytes.

    If replace=True, blocks whose path_string matches an existing block will
    replace it; otherwise all new_blocks are appended.
    """
    existing = read_patch_wad(existing_path)
    merged = list(existing.blocks)

    for new_blk in new_blocks:
        if replace:
            found = False
            for i, old in enumerate(merged):
                if old.path_string == new_blk.path_string:
                    merged[i] = new_blk
                    found = True
                    break
            if not found:
                merged.append(new_blk)
        else:
            merged.append(new_blk)

    return build_patch_wad_multi(
        blocks=merged,
        csum_value=existing.csum_value,
    )
