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
    b"SPED",  # DLC-only: LE tag = DEPS (dependency list)
    b"KEYS", b"STRS",  # stringdb chunks (LE: SYEK/SRTS; body data stays BE)
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
    """Swap INFO body fields.  Only swap texture-specific fields when the
    body is large enough (≥ 26 bytes for texture INFO); script-type INFO
    bodies are shorter and must not be overwritten."""
    ba = _body_abs(data, ucfx_start, chunk_pos, ucfx_u0)
    body_len = struct.unpack_from("<I", data, chunk_pos + 8)[0]
    if body_len >= 26 and ba + 26 <= len(data):
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


# ── Lua 5.1 bytecode BE→LE swap ──────────────────────────────────────

_LUAQ_SIG = b"\x1bLua"
_LUA_TNIL = 0
_LUA_TBOOLEAN = 1
_LUA_TNUMBER = 3
_LUA_TSTRING = 4


def _swap_lua51_bytecode(data: bytearray, start: int, end: int) -> bool:
    """In-place BE→LE swap of a Lua 5.1 bytecode chunk.

    Handles the 12-byte header, then recursively walks function prototypes
    swapping all multi-byte fields (instructions, constants, debug info).

    Returns True on success, False on any parse error.
    """
    if start + 12 > end:
        return False
    if bytes(data[start:start + 4]) != _LUAQ_SIG:
        return False
    if data[start + 6] != 0:
        return True  # already LE or unknown — skip

    sizeof_int = data[start + 7]
    sizeof_size_t = data[start + 8]
    sizeof_instr = data[start + 9]
    sizeof_number = data[start + 10]

    if sizeof_int != 4 or sizeof_size_t != 4 or sizeof_instr != 4:
        return False
    if sizeof_number not in (4, 8):
        return False

    data[start + 6] = 1  # flip endianness flag to LE

    pos = start + 12
    ok, _ = _swap_lua51_proto(data, pos, end, sizeof_number)
    return ok


def _read_be_u32(data: bytearray, pos: int) -> int:
    return struct.unpack_from(">I", data, pos)[0]


def _swap_lua51_string(data: bytearray, pos: int, end: int) -> int:
    """Swap a size_t-prefixed string. Returns new position, or -1 on error."""
    if pos + 4 > end:
        return -1
    slen = _read_be_u32(data, pos)
    _swap32(data, pos)
    pos += 4
    if slen == 0:
        return pos
    if pos + slen > end:
        return -1
    return pos + slen  # string bytes don't need swapping


def _swap_lua51_proto(
    data: bytearray, pos: int, end: int, sizeof_number: int,
) -> tuple[bool, int]:
    """Recursively swap a Lua 5.1 function prototype. Returns (ok, new_pos)."""
    # source name (string)
    pos = _swap_lua51_string(data, pos, end)
    if pos < 0:
        return False, 0

    # linedefined, lastlinedefined (2 × int)
    if pos + 8 > end:
        return False, 0
    _swap32(data, pos)
    _swap32(data, pos + 4)
    pos += 8

    # nups, numparams, is_vararg, maxstacksize (4 bytes)
    if pos + 4 > end:
        return False, 0
    pos += 4

    # code: int sizecode + Instruction[sizecode]
    if pos + 4 > end:
        return False, 0
    sizecode = _read_be_u32(data, pos)
    _swap32(data, pos)
    pos += 4
    if sizecode > 0x100000 or pos + sizecode * 4 > end:
        return False, 0
    for _ in range(sizecode):
        _swap32(data, pos)
        pos += 4

    # constants: int sizek
    if pos + 4 > end:
        return False, 0
    sizek = _read_be_u32(data, pos)
    _swap32(data, pos)
    pos += 4
    if sizek > 0x100000:
        return False, 0

    for _ in range(sizek):
        if pos >= end:
            return False, 0
        tt = data[pos]
        pos += 1
        if tt == _LUA_TBOOLEAN:
            pos += 1
        elif tt == _LUA_TNUMBER:
            if pos + sizeof_number > end:
                return False, 0
            if sizeof_number == 4:
                _swap32(data, pos)
            else:
                # 8-byte double: swap as two u32s then reverse order
                _swap32(data, pos)
                _swap32(data, pos + 4)
                data[pos:pos + 8] = data[pos + 4:pos + 8] + data[pos:pos + 4]
            pos += sizeof_number
        elif tt == _LUA_TSTRING:
            pos = _swap_lua51_string(data, pos, end)
            if pos < 0:
                return False, 0
        elif tt == _LUA_TNIL:
            pass
        else:
            return False, 0

    # nested protos: int sizep + Proto[sizep]
    if pos + 4 > end:
        return False, 0
    sizep = _read_be_u32(data, pos)
    _swap32(data, pos)
    pos += 4
    if sizep > 0x10000:
        return False, 0
    for _ in range(sizep):
        ok, pos = _swap_lua51_proto(data, pos, end, sizeof_number)
        if not ok:
            return False, 0

    # debug: lineinfo — int sizelineinfo + int[sizelineinfo]
    if pos + 4 > end:
        return False, 0
    sizelineinfo = _read_be_u32(data, pos)
    _swap32(data, pos)
    pos += 4
    if sizelineinfo > 0x100000 or pos + sizelineinfo * 4 > end:
        return False, 0
    for _ in range(sizelineinfo):
        _swap32(data, pos)
        pos += 4

    # debug: locvars — int sizelocvars + LocVar[sizelocvars]
    if pos + 4 > end:
        return False, 0
    sizelocvars = _read_be_u32(data, pos)
    _swap32(data, pos)
    pos += 4
    if sizelocvars > 0x100000:
        return False, 0
    for _ in range(sizelocvars):
        pos = _swap_lua51_string(data, pos, end)
        if pos < 0:
            return False, 0
        if pos + 8 > end:
            return False, 0
        _swap32(data, pos)      # startpc
        _swap32(data, pos + 4)  # endpc
        pos += 8

    # debug: upvalues — int sizeupvalues + string[sizeupvalues]
    if pos + 4 > end:
        return False, 0
    sizeupvalues = _read_be_u32(data, pos)
    _swap32(data, pos)
    pos += 4
    if sizeupvalues > 0x10000:
        return False, 0
    for _ in range(sizeupvalues):
        pos = _swap_lua51_string(data, pos, end)
        if pos < 0:
            return False, 0

    return True, pos


def _swap_binn_lua(
    data: bytearray, ucfx_start: int, chunk_pos: int, ucfx_u0: int,
) -> None:
    """Swap BINN chunk: detect LuaQ bytecode and endian-swap it."""
    ba = _body_abs(data, ucfx_start, chunk_pos, ucfx_u0)
    body_len = struct.unpack_from("<I", data, chunk_pos + 8)[0]
    body_end = ba + body_len
    if body_end > len(data):
        return

    # BINN body layout: u32 bc_size + 8 zero bytes + u8 type + u16 name_len
    # + name + NUL + padding + LuaQ bytecode.  Scan for LuaQ signature.
    #
    # The container walker may have already reversed the 4-byte LuaQ signature
    # (\x1bLua → auL\x1b) while scanning body data for chunk tags.  Check both.
    _LUAQ_SIG_REV = _LUAQ_SIG[::-1]  # b"auL\x1b"
    luaq_off = -1
    reversed_sig = False
    search_start = ba
    while search_start + 4 <= body_end:
        sig4 = bytes(data[search_start:search_start + 4])
        if sig4 == _LUAQ_SIG:
            luaq_off = search_start
            break
        if sig4 == _LUAQ_SIG_REV:
            luaq_off = search_start
            reversed_sig = True
            break
        search_start += 1

    if luaq_off < 0:
        return

    if reversed_sig:
        _reverse4(data, luaq_off)  # restore correct \x1bLua signature

    # Some BINN bodies have metadata before the LuaQ bytecode:
    #   +0x00: u32 bc_size, +0x04: 8 zeros, +0x0C: u8 type, +0x0D: u16 name_len
    # Others (e.g. DLC scripts_vz) start directly with LuaQ at offset 0.
    # Only swap metadata fields when the LuaQ sig is NOT at the body start.
    if luaq_off > ba:
        if ba + 4 <= len(data):
            _swap32(data, ba)        # bc_size
        if ba + 0x0F <= len(data):
            _swap16(data, ba + 0x0D) # name_length

    _swap_lua51_bytecode(data, luaq_off, body_end)


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
    "BINN": _swap_binn_lua,
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
            _swap32(data, pos + 4)   # UCFX u0 (data area offset)
            _swap32(data, pos + 8)   # UCFX u1
            _swap32(data, pos + 12)  # UCFX u2
            _swap32(data, pos + 16)  # UCFX u3 (chunk count)
            stats["ucfx_found"] += 1

            ucfx_u0 = struct.unpack_from("<I", data, pos + 4)[0]
            ucfx_start = pos

            # UCFX layout: 20-byte header (tag + u0..u3) → chunk descriptor
            # rows (20 bytes each) → data area.  data_base = ucfx_start + u0.
            # Limit tag scan to the header row section to avoid corrupting
            # body data (Lua bytecode, vertex data, etc.).
            header_row_end = chunk_end
            if ucfx_u0 > 0:
                header_row_end = min(ucfx_start + ucfx_u0, chunk_end)

            inner_pos = pos + 20
            while inner_pos + 20 <= header_row_end:
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
