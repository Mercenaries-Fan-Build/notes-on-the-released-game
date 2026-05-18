#!/usr/bin/env python3
"""UCFX big-endian to little-endian byte-swap module.

Merges the two approaches from port_xbox_dlc.py and dlc_port_x360_to_pc.py:
  - Container walk + tag detection (from dlc_port_x360_to_pc)
  - Per-chunk deep swap: INFO, BNDS, MTRL, PRMG, STRM, IBUF, MESH, HIER, INDX
    (from port_xbox_dlc)

Usage:
  from ucfx_be_to_le import byteswap_ucfx_block, recompute_csums
  le_data, stats = byteswap_ucfx_block(be_decompressed)
"""
from __future__ import annotations

import struct
import zlib


# ── Primitives ────────────────────────────────────────────────────────

def _swap32(data: bytearray, offset: int) -> None:
    """In-place swap a 32-bit value."""
    data[offset], data[offset + 1], data[offset + 2], data[offset + 3] = (
        data[offset + 3], data[offset + 2], data[offset + 1], data[offset]
    )


def _swap16(data: bytearray, offset: int) -> None:
    """In-place swap a 16-bit value."""
    data[offset], data[offset + 1] = data[offset + 1], data[offset]


def _reverse4(data: bytearray, offset: int) -> None:
    """Reverse 4 bytes in-place (magic tag reversal)."""
    data[offset:offset + 4] = data[offset:offset + 4][::-1]


# ── Known big-endian chunk tags ───────────────────────────────────────

BE_TAGS = {
    b"XFCU", b"RDHC", b"PMOC", b"MOEG", b"HSEM", b"GMRP", b"MRTS",
    b"FUBI", b"LRTM", b"SGLF", b"TATS", b"EXEC", b"MUNE", b"TGLF",
    b"XDNI", b"EMAN", b"YDOB", b"SDNB", b"OFNI", b"TMRP", b"TIWS",
    b"REIH", b"MUSC", b"NNIB",
}


# ── CRC ───────────────────────────────────────────────────────────────

def crc32_mercs2(data: bytes) -> int:
    """CRC-32 with init=0xFFFFFFFF, no final XOR (Mercenaries 2 CSUM)."""
    return (zlib.crc32(data, 0xFFFFFFFF) ^ 0xFFFFFFFF) & 0xFFFFFFFF


# ── Per-chunk body swaps ──────────────────────────────────────────────

def _body_abs(data: bytearray, ucfx_start: int, chunk_pos: int, ucfx_u0: int) -> int:
    """Compute absolute offset of a chunk's body data."""
    body_off_rel = struct.unpack_from("<I", data, chunk_pos + 4)[0]
    if ucfx_u0 > 0:
        return ucfx_start + ucfx_u0 + body_off_rel
    return ucfx_start + 8 + body_off_rel


def _swap_info(data: bytearray, ucfx_start: int, chunk_pos: int, ucfx_u0: int) -> None:
    """Swap INFO (texture metadata): width, height, mip_count, total_size."""
    ba = _body_abs(data, ucfx_start, chunk_pos, ucfx_u0)
    if ba + 26 > len(data):
        return
    _swap16(data, ba + 0)   # width
    _swap16(data, ba + 2)   # height
    _swap16(data, ba + 6)   # mip_count
    _swap32(data, ba + 22)  # total_size


def _swap_bnds(data: bytearray, ucfx_start: int, chunk_pos: int, ucfx_u0: int) -> None:
    """Swap BNDS (bounding box) — 10 floats."""
    ba = _body_abs(data, ucfx_start, chunk_pos, ucfx_u0)
    for i in range(10):
        off = ba + i * 4
        if off + 4 <= len(data):
            _swap32(data, off)


def _swap_mtrl(data: bytearray, ucfx_start: int, chunk_pos: int, ucfx_u0: int) -> None:
    """Swap MTRL (material) — u32 array."""
    ba = _body_abs(data, ucfx_start, chunk_pos, ucfx_u0)
    body_len = struct.unpack_from("<I", data, chunk_pos + 8)[0]
    end = ba + body_len
    if end > len(data):
        return
    pos = ba
    while pos + 4 <= end:
        _swap32(data, pos)
        pos += 4


def _swap_prmg(data: bytearray, ucfx_start: int, chunk_pos: int, ucfx_u0: int) -> None:
    """Swap PRMG (primitive group) — u32 array."""
    ba = _body_abs(data, ucfx_start, chunk_pos, ucfx_u0)
    body_len = struct.unpack_from("<I", data, chunk_pos + 8)[0]
    end = ba + body_len
    if end > len(data):
        return
    pos = ba
    while pos + 4 <= end:
        _swap32(data, pos)
        pos += 4


def _swap_strm_header(data: bytearray, ucfx_start: int, chunk_pos: int, ucfx_u0: int) -> None:
    """Swap STRM header fields (stride + vertex count); vertex data left as-is."""
    ba = _body_abs(data, ucfx_start, chunk_pos, ucfx_u0)
    if ba + 8 > len(data):
        return
    _swap32(data, ba + 0)
    _swap32(data, ba + 4)


def _swap_ibuf(data: bytearray, ucfx_start: int, chunk_pos: int, ucfx_u0: int) -> None:
    """Swap IBUF (index buffer) — u16 array."""
    ba = _body_abs(data, ucfx_start, chunk_pos, ucfx_u0)
    body_len = struct.unpack_from("<I", data, chunk_pos + 8)[0]
    end = ba + body_len
    if end > len(data):
        return
    pos = ba
    while pos + 2 <= end:
        _swap16(data, pos)
        pos += 2


def _swap_mesh(data: bytearray, ucfx_start: int, chunk_pos: int, ucfx_u0: int) -> None:
    """Swap MESH header — u32 array."""
    ba = _body_abs(data, ucfx_start, chunk_pos, ucfx_u0)
    body_len = struct.unpack_from("<I", data, chunk_pos + 8)[0]
    end = ba + body_len
    if end > len(data):
        return
    pos = ba
    while pos + 4 <= end:
        _swap32(data, pos)
        pos += 4


def _swap_hier(data: bytearray, ucfx_start: int, chunk_pos: int, ucfx_u0: int) -> None:
    """Swap HIER (hierarchy) — transform floats + indices as u32 array."""
    ba = _body_abs(data, ucfx_start, chunk_pos, ucfx_u0)
    body_len = struct.unpack_from("<I", data, chunk_pos + 8)[0]
    end = ba + body_len
    if end > len(data):
        return
    pos = ba
    while pos + 4 <= end:
        _swap32(data, pos)
        pos += 4


def _swap_indx_body(data: bytearray, ucfx_start: int, chunk_pos: int, ucfx_u0: int) -> None:
    """Swap inner INDX — u16 MESH→HIER mappings."""
    ba = _body_abs(data, ucfx_start, chunk_pos, ucfx_u0)
    body_len = struct.unpack_from("<I", data, chunk_pos + 8)[0]
    end = ba + body_len
    if end > len(data):
        return
    pos = ba
    while pos + 2 <= end:
        _swap16(data, pos)
        pos += 2


# Dispatch table: LE tag → swap function
_CHUNK_SWAP = {
    "INFO": _swap_info,
    "BNDS": _swap_bnds,
    "MTRL": _swap_mtrl,
    "PRMG": _swap_prmg,
    "STRM": _swap_strm_header,
    "IBUF": _swap_ibuf,
    "MESH": _swap_mesh,
    "HIER": _swap_hier,
    "INDX": _swap_indx_body,
}


# ── Block-level byte-swap ─────────────────────────────────────────────

def byteswap_block_header(data: bytearray) -> int:
    """Swap the block header table (record_count + N × 16 byte entries).

    Returns the record count.
    """
    _swap32(data, 0)
    count = struct.unpack_from("<I", data, 0)[0]

    for i in range(count):
        off = 4 + i * 16
        if off + 16 > len(data):
            break
        _swap32(data, off + 0)   # asset_hash / name_hash
        _swap32(data, off + 4)   # type_hash
        _swap32(data, off + 8)   # reserved
        _swap32(data, off + 12)  # chunk_size

    return count


def byteswap_ucfx_containers(data: bytearray, entry_count: int) -> dict:
    """Walk UCFX containers and swap headers + deep chunk bodies.

    Combines dlc_port's structural container walk with port_xbox_dlc's
    per-chunk body swap handlers.

    Returns a statistics dict.
    """
    stats: dict = {
        "ucfx_found": 0, "chunks_swapped": 0, "csum_swapped": 0,
        "tags_seen": {}, "errors": [],
    }

    header_end = 4 + entry_count * 16
    sizes: list[int] = []
    for i in range(entry_count):
        off = 4 + i * 16
        sizes.append(struct.unpack_from("<I", data, off + 12)[0])

    pos = header_end
    for entry_idx in range(entry_count):
        if pos + 8 > len(data):
            break
        chunk_size = sizes[entry_idx]
        chunk_end = pos + chunk_size
        if chunk_end > len(data):
            chunk_end = len(data)

        tag_at_pos = bytes(data[pos:pos + 4])
        if tag_at_pos == b"XFCU" or tag_at_pos[::-1] == b"UCFX":
            _reverse4(data, pos)
            _swap32(data, pos + 4)  # UCFX u0
            stats["ucfx_found"] += 1

            ucfx_u0 = struct.unpack_from("<I", data, pos + 4)[0]
            ucfx_start = pos

            inner_pos = pos + 8
            while inner_pos + 20 <= chunk_end:
                inner_tag = bytes(data[inner_pos:inner_pos + 4])
                is_csum = (inner_tag == b"MUSC" or inner_tag[::-1] == b"CSUM")

                if is_csum:
                    _reverse4(data, inner_pos)
                    _swap32(data, inner_pos + 4)
                    stats["csum_swapped"] += 1
                    inner_pos += 8
                    continue

                is_known_be = inner_tag in BE_TAGS
                is_known_le = inner_tag[::-1] in BE_TAGS

                if is_known_be or is_known_le:
                    if is_known_be:
                        _reverse4(data, inner_pos)

                    le_tag = bytes(data[inner_pos:inner_pos + 4]).decode(
                        "ascii", errors="replace")
                    stats["tags_seen"][le_tag] = stats["tags_seen"].get(le_tag, 0) + 1

                    # Swap the 4 row-header u32s
                    _swap32(data, inner_pos + 4)
                    _swap32(data, inner_pos + 8)
                    _swap32(data, inner_pos + 12)
                    _swap32(data, inner_pos + 16)
                    stats["chunks_swapped"] += 1

                    # Deep body swap if handler exists
                    handler = _CHUNK_SWAP.get(le_tag)
                    if handler:
                        handler(data, ucfx_start, inner_pos, ucfx_u0)

                    inner_pos += 20
                else:
                    inner_pos += 1
        else:
            stats["errors"].append(
                f"Entry {entry_idx}: expected XFCU at 0x{pos:X}, got {tag_at_pos!r}")
            pos = chunk_end
            continue

        # Swap CSUM trailer at end of container
        if chunk_end - 8 >= pos:
            csum_pos = chunk_end - 8
            csum_tag = bytes(data[csum_pos:csum_pos + 4])
            if csum_tag in (b"MUSC", b"CSUM"):
                if csum_tag == b"MUSC":
                    _reverse4(data, csum_pos)
                _swap32(data, csum_pos + 4)
                stats["csum_swapped"] += 1

        pos = chunk_end

    return stats


def recompute_csums(data: bytearray, entry_count: int) -> int:
    """Recompute all CSUM trailers after byte-swap. Returns count updated."""
    count = 0
    header_end = 4 + entry_count * 16
    pos = header_end
    for i in range(entry_count):
        off = 4 + i * 16
        chunk_size = struct.unpack_from("<I", data, off + 12)[0]
        chunk_end = pos + chunk_size
        if chunk_end > len(data):
            break

        csum_pos = chunk_end - 8
        if csum_pos >= pos and data[csum_pos:csum_pos + 4] == b"CSUM":
            ucfx_body = bytes(data[pos:csum_pos])
            new_csum = crc32_mercs2(ucfx_body)
            struct.pack_into("<I", data, csum_pos + 4, new_csum)
            count += 1

        pos = chunk_end
    return count


# ── High-level API ────────────────────────────────────────────────────

def byteswap_ucfx_block(block_data: bytes) -> tuple[bytes, dict]:
    """Full byte-swap of a decompressed Xbox UCFX block to PC little-endian.

    Performs:
      1. Block header table swap
      2. UCFX container walk with deep chunk-body swaps
      3. CSUM recomputation

    Returns (swapped_bytes, stats_dict).
    """
    data = bytearray(block_data)
    entry_count = byteswap_block_header(data)
    stats = byteswap_ucfx_containers(data, entry_count)
    recompute_csums(data, entry_count)
    return bytes(data), stats
