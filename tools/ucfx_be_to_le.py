#!/usr/bin/env python3
"""UCFX big-endian to little-endian structural converter.

Parses Xbox 360 big-endian UCFX block data into typed Python values,
then serializes fresh little-endian output.  No in-place byte mutation.

Every field is explicitly read with struct.unpack('>') and written with
struct.pack('<'), ensuring strings are preserved verbatim and numeric
fields are correctly converted.

Usage:
  from ucfx_be_to_le import byteswap_ucfx_block, recompute_csums
  le_data, stats = byteswap_ucfx_block(be_decompressed)
"""
from __future__ import annotations

import struct
import zlib

from pandemic_hash import pandemic_hash_m2
from pws_xbox_to_pc import transcode_pws_xbox_to_pc

# ── Constants ─────────────────────────────────────────────────────────

CONTAINER_SENTINEL = 0xFFFFFFFF
CHUNK_HDR = 20
_HAVOK_MAGIC = b"\x57\xe0\xe0\x57\x10\xc0\xc0\x10"
_LUAQ_SIG = b"\x1bLua"

_LUA_TNIL = 0
_LUA_TBOOLEAN = 1
_LUA_TNUMBER = 3
_LUA_TSTRING = 4


# ── CRC ───────────────────────────────────────────────────────────────

def crc32_mercs2(data: bytes) -> int:
    """CRC-32 with init=0xFFFFFFFF, no final XOR (Mercenaries 2 CSUM)."""
    return (zlib.crc32(data, 0xFFFFFFFF) ^ 0xFFFFFFFF) & 0xFFFFFFFF


# ── Numeric array converters ──────────────────────────────────────────

def _convert_u32_array(be: bytes) -> bytes:
    """Read BE u32 array, return LE u32 array."""
    n = len(be) // 4
    remainder = len(be) - n * 4
    if n == 0:
        return be
    values = struct.unpack(f">{n}I", be[:n * 4])
    out = struct.pack(f"<{n}I", *values)
    if remainder >= 2:
        val16 = struct.unpack_from(">H", be, n * 4)[0]
        out += struct.pack("<H", val16)
        if remainder > 2:
            out += be[n * 4 + 2:]
    elif remainder > 0:
        out += be[n * 4:]
    return out


def _convert_u16_array(be: bytes) -> bytes:
    """Read BE u16 array, return LE u16 array."""
    n = len(be) // 2
    remainder = len(be) - n * 2
    if n == 0:
        return be
    values = struct.unpack(f">{n}H", be[:n * 2])
    out = struct.pack(f"<{n}H", *values)
    if remainder:
        out += be[n * 2:]
    return out


def _convert_deps_body(be: bytes) -> bytes:
    """Convert a DEPS chunk: [u8 count] [u32 hash × count].

    The count prefix is a single byte and must NOT be included in the u32
    swap group, otherwise the count gets corrupted (e.g. 4 becomes 0xC6).
    """
    if len(be) < 1:
        return be
    count_byte = be[0:1]
    hashes_be = be[1:]
    return count_byte + _convert_u32_array(hashes_be)


# ── Placement record converter (flgs) ────────────────────────────────

def _convert_flgs_records(be: bytes) -> bytes:
    """Convert 42-byte placement records: 10 x u32 + 1 x u16 per record."""
    STRIDE = 42
    out = bytearray()
    pos = 0
    while pos + STRIDE <= len(be):
        record = be[pos:pos + STRIDE]
        u32s = struct.unpack_from(">10I", record, 0)
        u16 = struct.unpack_from(">H", record, 40)[0]
        out += struct.pack("<10I", *u32s)
        out += struct.pack("<H", u16)
        pos += STRIDE
    if pos < len(be):
        out += _convert_u32_array(be[pos:])
    return bytes(out)


# ── Texture INFO converter ────────────────────────────────────────────

def _convert_trnm_body(be: bytes) -> bytes:
    """Convert trnm (track name) body: u16 count + 2 padding + u32 hashes."""
    if len(be) < 4:
        return _convert_u16_array(be)
    out = bytearray(len(be))
    count_val = struct.unpack_from(">H", be, 0)[0]
    struct.pack_into("<H", out, 0, count_val)
    out[2:4] = be[2:4]
    n = (len(be) - 4) // 4
    for i in range(n):
        off = 4 + i * 4
        val = struct.unpack_from(">I", be, off)[0]
        struct.pack_into("<I", out, off, val)
    tail = 4 + n * 4
    if tail < len(be):
        out[tail:] = be[tail:]
    return bytes(out)


def _convert_texture_info(be: bytes) -> bytes:
    """Convert texture INFO body from BE to LE.

    Structure (34 bytes, verified from base game):
      [0-13]   7 × u16: width, height, array_size, mip_count, unk, flags_a, flags_b
      [14-21]  8 bytes: FourCC format string (endian-neutral, e.g. "DXT5")
      [22-25]  u32: total_size
      [26-33]  4 × u16: tail fields
    """
    if len(be) < 14:
        return _convert_u16_array(be)
    out = bytearray(be)
    # u16 fields at 0..13
    for off in range(0, 14, 2):
        v = struct.unpack_from(">H", be, off)[0]
        struct.pack_into("<H", out, off, v)
    # bytes 14-21: FourCC (passthrough)
    # u32 at 22
    if len(be) >= 26:
        struct.pack_into("<I", out, 22, struct.unpack_from(">I", be, 22)[0])
    # u16 fields at 26+
    for off in range(26, len(be) - 1, 2):
        v = struct.unpack_from(">H", be, off)[0]
        struct.pack_into("<H", out, off, v)
    return bytes(out)


# ── Havok packfile converter ─────────────────────────────────────────

_HAVOK_VER = b"Havok-5.5.0-r1"
_SECTION_HDR_SIZE = 48


def _convert_havok_be_to_le(be: bytes) -> bytes:
    """Structurally convert a Havok 5.5 packfile from BE to LE.

    Converts header fields, section headers, __classnames__ signatures,
    and __data__ (as u32 array). The __data__ u32 conversion is imperfect
    for fields that are u16/u8, but is necessary because the game's Havok
    runtime does not perform endian conversion — it reads fields directly
    assuming LE format.

    Layout (verified from base game):
      [0,8)     Magic (palindromic, copy as-is)
      [8,16)    2 x u32: user_tag, file_version (swap BE->LE)
      [16,20)   4 x u8: pointer_size, is_little_endian, reuse_pad, empty_base
                (copy as-is, then set is_little_endian = 1)
      [20,ver)  i32 fields (swap BE->LE)
      [ver,sec) Version string + 0xFF padding (copy as-is)
      [sec,sec+144) 3 x 48-byte section headers: 20-byte name + 7 x u32
      [cn_abs, cn_abs+cn_end) __classnames__: u32 sigs + ASCII
      [ty_abs, ty_abs+ty_end) __types__: copy as-is
      [da_abs, da_abs+da_end) __data__: u32 array (instances+fixups)
    """
    if len(be) < 64:
        return _convert_u32_array(be)

    ver_off = be.find(_HAVOK_VER)
    if ver_off < 0:
        ver_off = be.find(b"Havok-")
    if ver_off < 0:
        return _convert_u32_array(be)

    cn_needle_off = be.find(b"__classnames__", ver_off)
    if cn_needle_off < 0:
        return _convert_u32_array(be)

    out = bytearray(len(be))

    # 1. Magic (8 bytes): palindromic, copy as-is
    out[0:8] = be[0:8]

    # 2. Header u32 fields at [8,16): user_tag, file_version
    for off in (8, 12):
        val = struct.unpack_from(">I", be, off)[0]
        struct.pack_into("<I", out, off, val)

    # 3. Byte fields at [16,20): copy as-is, set is_little_endian=1
    out[16:20] = be[16:20]
    out[17] = 1  # is_little_endian

    # 4. Header i32 fields at [20,ver_off): convert all as u32
    for off in range(20, ver_off, 4):
        val = struct.unpack_from(">I", be, off)[0]
        struct.pack_into("<I", out, off, val)

    # 5. Version string + 0xFF padding: copy as-is
    sec_hdrs_off = cn_needle_off
    out[ver_off:sec_hdrs_off] = be[ver_off:sec_hdrs_off]

    # 6. Three section headers (48 bytes each)
    sections = []
    for i in range(3):
        so = sec_hdrs_off + i * _SECTION_HDR_SIZE
        if so + _SECTION_HDR_SIZE > len(be):
            out[so:] = be[so:]
            return bytes(out)
        out[so:so + 20] = be[so:so + 20]
        fields = struct.unpack_from(">7I", be, so + 20)
        struct.pack_into("<7I", out, so + 20, *fields)
        sections.append(fields)

    sec_data_start = sec_hdrs_off + 3 * _SECTION_HDR_SIZE

    # Section fields: (abs_start, local_fixup, global_fixup, virtual_fixup, exports, imports, end)
    cn_abs, cn_local, _, _, _, _, cn_end = sections[0]
    ty_abs, _, _, _, _, _, ty_end = sections[1]
    da_abs, _, _, _, _, _, da_end = sections[2]

    # 7. __classnames__ body: u32 signatures interleaved with ASCII strings
    if cn_end > 0 and cn_abs + cn_end <= len(be):
        p = cn_abs
        body_end = cn_abs + cn_end
        while p + 5 <= body_end:
            sig_be = struct.unpack_from(">I", be, p)[0]
            if sig_be == 0xFFFFFFFF:
                struct.pack_into("<I", out, p, 0xFFFFFFFF)
                p += 4
                break
            struct.pack_into("<I", out, p, sig_be)
            out[p + 4] = be[p + 4]  # flag byte
            q = p + 5
            while q < body_end and be[q] != 0:
                out[q] = be[q]
                q += 1
            if q < body_end:
                out[q] = 0  # NUL terminator
                q += 1
            p = q
        if p < body_end:
            out[p:body_end] = be[p:body_end]

    # 8. __types__ body: copy as-is (usually empty; complex structure when present)
    if ty_end > 0 and ty_abs + ty_end <= len(be):
        out[ty_abs:ty_abs + ty_end] = be[ty_abs:ty_abs + ty_end]

    # 9. __data__ section: convert as u32 array.
    # This is imperfect for mixed u8/u16/u32 fields in Havok instance data,
    # but for DLC-unique animations without a base-game LE reference, it's
    # the best we can do. The havok_overrides mechanism in byteswap_ucfx_block
    # should be used to supply correct LE data for animations that also exist
    # in the base game's vz.wad.
    if da_end > 0 and da_abs + da_end <= len(be):
        n = da_end // 4
        for i in range(n):
            off = da_abs + i * 4
            val = struct.unpack_from(">I", be, off)[0]
            struct.pack_into("<I", out, off, val)
        tail = da_abs + n * 4
        if tail < da_abs + da_end:
            out[tail:da_abs + da_end] = be[tail:da_abs + da_end]

    # Fill any gap between sec_data_start and first section body
    first_body = min(x for x in (cn_abs, ty_abs, da_abs) if x > 0)
    if sec_data_start < first_body:
        out[sec_data_start:first_body] = be[sec_data_start:first_body]

    # Fill any trailing bytes after all sections
    total_end = max(cn_abs + cn_end, ty_abs + ty_end, da_abs + da_end)
    if total_end < len(be):
        out[total_end:] = be[total_end:]

    return bytes(out)


# ── Lua 5.1 bytecode converter ────────────────────────────────────────

def _convert_binn_script_ref(be: bytes) -> bytes:
    """Convert a BINN script-reference record (no Lua bytecode).

    Format: [u32 bytecode_size] [u32 zero] [u32 zero] [u8 marker] [u8 meta]
            [u8 zero] [name_bytes...]

    Only the first u32 needs byte-swapping; the rest is single-byte data
    (flags, ASCII name) that must NOT be treated as u32 values.
    """
    if len(be) < 4:
        return be
    out = bytearray(be)
    out[0], out[1], out[2], out[3] = out[3], out[2], out[1], out[0]
    return bytes(out)


def _convert_lua_be_to_le(be: bytes) -> bytes:
    """Convert a BINN body containing Lua 5.1 bytecode from BE to LE.

    Uses in-place mutation on a copy because the Lua format is recursive
    and position-dependent (sizes determine how far to advance).

    If no LuaQ signature is found, the body is a script-reference record
    (small metadata + name string) — only the first u32 is byte-swapped.
    """
    data = bytearray(be)
    body_end = len(data)

    # Scan for LuaQ signature
    luaq_off = -1
    for search in range(min(body_end - 4, 256)):
        if bytes(data[search:search + 4]) == _LUAQ_SIG:
            luaq_off = search
            break
    if luaq_off < 0:
        return _convert_binn_script_ref(be)

    # Swap BINN metadata before LuaQ if present
    if luaq_off > 0:
        if luaq_off >= 4:
            _lua_swap32(data, 0)
        if luaq_off >= 0x0F:
            _lua_swap16(data, 0x0D)

    # Parse and convert the Lua bytecode
    ok = _lua_convert_bytecode(data, luaq_off, body_end)
    if not ok:
        return _convert_binn_script_ref(be)

    return bytes(data)


def _lua_swap32(data: bytearray, offset: int) -> None:
    data[offset], data[offset + 1], data[offset + 2], data[offset + 3] = (
        data[offset + 3], data[offset + 2], data[offset + 1], data[offset])


def _lua_swap16(data: bytearray, offset: int) -> None:
    data[offset], data[offset + 1] = data[offset + 1], data[offset]


def _lua_read_be_u32(data: bytearray, pos: int) -> int:
    return struct.unpack_from(">I", data, pos)[0]


def _lua_convert_bytecode(data: bytearray, start: int, end: int) -> bool:
    """Convert Lua 5.1 bytecode chunk from BE to LE."""
    if start + 12 > end:
        return False
    if bytes(data[start:start + 4]) != _LUAQ_SIG:
        return False
    if data[start + 6] != 0:
        return True

    sizeof_int = data[start + 7]
    sizeof_size_t = data[start + 8]
    sizeof_instr = data[start + 9]
    sizeof_number = data[start + 10]

    if sizeof_int != 4 or sizeof_size_t != 4 or sizeof_instr != 4:
        return False
    if sizeof_number not in (4, 8):
        return False

    data[start + 6] = 1

    pos = start + 12
    ok, _ = _lua_convert_proto(data, pos, end, sizeof_number)
    return ok


def _lua_convert_string(data: bytearray, pos: int, end: int) -> int:
    if pos + 4 > end:
        return -1
    slen = _lua_read_be_u32(data, pos)
    _lua_swap32(data, pos)
    pos += 4
    if slen == 0:
        return pos
    if pos + slen > end:
        return -1
    return pos + slen


def _lua_convert_proto(
    data: bytearray, pos: int, end: int, sizeof_number: int,
) -> tuple[bool, int]:
    """Recursively convert a Lua 5.1 function prototype."""
    pos = _lua_convert_string(data, pos, end)
    if pos < 0:
        return False, 0

    if pos + 8 > end:
        return False, 0
    _lua_swap32(data, pos)
    _lua_swap32(data, pos + 4)
    pos += 8

    if pos + 4 > end:
        return False, 0
    pos += 4

    if pos + 4 > end:
        return False, 0
    sizecode = _lua_read_be_u32(data, pos)
    _lua_swap32(data, pos)
    pos += 4
    if sizecode > 0x100000 or pos + sizecode * 4 > end:
        return False, 0
    for _ in range(sizecode):
        _lua_swap32(data, pos)
        pos += 4

    if pos + 4 > end:
        return False, 0
    sizek = _lua_read_be_u32(data, pos)
    _lua_swap32(data, pos)
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
                _lua_swap32(data, pos)
            else:
                _lua_swap32(data, pos)
                _lua_swap32(data, pos + 4)
                data[pos:pos + 8] = data[pos + 4:pos + 8] + data[pos:pos + 4]
            pos += sizeof_number
        elif tt == _LUA_TSTRING:
            pos = _lua_convert_string(data, pos, end)
            if pos < 0:
                return False, 0
        elif tt == _LUA_TNIL:
            pass
        else:
            return False, 0

    if pos + 4 > end:
        return False, 0
    sizep = _lua_read_be_u32(data, pos)
    _lua_swap32(data, pos)
    pos += 4
    if sizep > 0x10000:
        return False, 0
    for _ in range(sizep):
        ok, pos = _lua_convert_proto(data, pos, end, sizeof_number)
        if not ok:
            return False, 0

    if pos + 4 > end:
        return False, 0
    sizelineinfo = _lua_read_be_u32(data, pos)
    _lua_swap32(data, pos)
    pos += 4
    if sizelineinfo > 0x100000 or pos + sizelineinfo * 4 > end:
        return False, 0
    for _ in range(sizelineinfo):
        _lua_swap32(data, pos)
        pos += 4

    if pos + 4 > end:
        return False, 0
    sizelocvars = _lua_read_be_u32(data, pos)
    _lua_swap32(data, pos)
    pos += 4
    if sizelocvars > 0x100000:
        return False, 0
    for _ in range(sizelocvars):
        pos = _lua_convert_string(data, pos, end)
        if pos < 0:
            return False, 0
        if pos + 8 > end:
            return False, 0
        _lua_swap32(data, pos)
        _lua_swap32(data, pos + 4)
        pos += 8

    if pos + 4 > end:
        return False, 0
    sizeupvalues = _lua_read_be_u32(data, pos)
    _lua_swap32(data, pos)
    pos += 4
    if sizeupvalues > 0x10000:
        return False, 0
    for _ in range(sizeupvalues):
        pos = _lua_convert_string(data, pos, end)
        if pos < 0:
            return False, 0

    return True, pos


# ── Body conversion dispatch ──────────────────────────────────────────

_CONTAINER_TAGS = frozenset(("STRM", "GEOM", "IBUF", "CHDR", "COMP", "STAT", "PRMT", "EXEC"))
_META_CONTAINERS = frozenset(("CHDR", "COMP", "STAT", "PRMT", "EXEC"))
_STREAM_CONTAINERS = frozenset(("STRM", "GEOM"))


def _classify_contexts(descriptors: list[tuple[str, int, int, int, int]]) -> list[str | None]:
    """Determine the container context for each descriptor row.

    Returns a list of context strings: "STRM", "IBUF", "META", or None.
    """
    contexts: list[str | None] = []
    current: str | None = None
    for tag, row_u0, _body_size, _f3, _f4 in descriptors:
        if row_u0 == CONTAINER_SENTINEL:
            if tag in _STREAM_CONTAINERS:
                current = "STRM"
            elif tag == "IBUF":
                current = "IBUF"
            elif tag in _META_CONTAINERS:
                current = "META"
        contexts.append(current)
    return contexts


def _convert_type_body(be: bytes) -> bytes:
    """Convert TYPE body from BE to LE.

    Structure (verified from base game): repeated sequence of
      [null-terminated ASCII field name] [u16 type_code]
    Type codes: 2=int16, 3=float, 4=string/hash, 8=animation, etc.
    Only the u16 type codes need byte-swapping; the ASCII names are endian-neutral.
    """
    out = bytearray(be)
    pos = 0
    while pos < len(be):
        nul = be.find(b"\x00", pos)
        if nul < 0:
            break
        pos = nul + 1
        if pos + 2 <= len(be):
            v = struct.unpack_from(">H", be, pos)[0]
            struct.pack_into("<H", out, pos, v)
            pos += 2
        else:
            break
    return bytes(out)


def _convert_script_info(be: bytes) -> bytes:
    """Convert script INFO: [u8:5][u16 name_len][ASCII name][null][u8 cnt][u16 flags].

    Only the two u16 fields need byte-swapping; u8 and ASCII are endian-neutral.
    """
    if len(be) < 4:
        return be
    out = bytearray(be)
    name_len = struct.unpack_from(">H", be, 1)[0]
    struct.pack_into("<H", out, 1, name_len)
    # Flags u16 at end: offset = 1(u8) + 2(u16) + name_len(ASCII) + 1(null) + 1(u8) = 5 + name_len
    flags_off = 5 + name_len
    if flags_off + 2 <= len(be):
        flags = struct.unpack_from(">H", be, flags_off)[0]
        struct.pack_into("<H", out, flags_off, flags)
    return bytes(out)


def _convert_evnt_body(be: bytes) -> bytes:
    """Convert evnt body: [u32 count] [per event: float32 + cstring + cstring].

    Only the u32 count and each event's float32 timestamp need byte-swapping.
    The null-terminated ASCII strings are endian-neutral.
    """
    if len(be) < 4:
        return be
    out = bytearray(be)
    count = struct.unpack_from(">I", be, 0)[0]
    struct.pack_into("<I", out, 0, count)
    pos = 4
    for _ in range(count):
        if pos + 4 > len(be):
            break
        ts = struct.unpack_from(">I", be, pos)[0]
        struct.pack_into("<I", out, pos, ts)
        pos += 4
        # Skip two null-terminated strings (bytes are endian-neutral)
        for _ in range(2):
            nul = be.find(b"\x00", pos)
            if nul < 0:
                pos = len(be)
                break
            pos = nul + 1
    return bytes(out)


def _convert_dxt_body(be: bytes, fmt: bytes = b"DXT5") -> bytes:
    """Convert DXT texture body from Xbox 360 BE to PC LE, per-block.

    Xbox 360 GPU stores DXT blocks with multi-byte fields in big-endian:

    DXT1 (8-byte blocks):
      [0-1]  u16 color0 (BE)
      [2-3]  u16 color1 (BE)
      [4-7]  u32 color indices (BE)

    DXT5 (16-byte blocks):
      [0-1]  u8 alpha0, u8 alpha1 (endian-neutral)
      [2-3]  u16 alpha row 0 (BE)
      [4-5]  u16 alpha row 1 (BE)
      [6-7]  u16 alpha row 2 (BE)
      [8-9]  u16 color0 (BE)
      [10-11] u16 color1 (BE)
      [12-15] u32 color indices (BE)

    DXT3 (16-byte blocks):
      [0-7]  4 × u16 explicit alpha (BE)
      [8-9]  u16 color0 (BE)
      [10-11] u16 color1 (BE)
      [12-15] u32 color indices (BE)
    """
    fmt_upper = fmt[:4].rstrip(b"\x00").upper()
    if fmt_upper == b"DXT1":
        return _convert_dxt1_blocks(be)
    elif fmt_upper == b"DXT3":
        return _convert_dxt3_blocks(be)
    else:
        return _convert_dxt5_blocks(be)


def _convert_dxt1_blocks(be: bytes) -> bytes:
    """Per-block DXT1 conversion: [u16 c0][u16 c1][u32 idx]."""
    out = bytearray(len(be))
    n_blocks = len(be) // 8
    for i in range(n_blocks):
        off = i * 8
        c0 = struct.unpack_from(">H", be, off)[0]
        c1 = struct.unpack_from(">H", be, off + 2)[0]
        idx = struct.unpack_from(">I", be, off + 4)[0]
        struct.pack_into("<H", out, off, c0)
        struct.pack_into("<H", out, off + 2, c1)
        struct.pack_into("<I", out, off + 4, idx)
    tail = n_blocks * 8
    if tail < len(be):
        out[tail:] = be[tail:]
    return bytes(out)


def _convert_dxt3_blocks(be: bytes) -> bytes:
    """Per-block DXT3 conversion: [4×u16 alpha][u16 c0][u16 c1][u32 idx]."""
    out = bytearray(len(be))
    n_blocks = len(be) // 16
    for i in range(n_blocks):
        off = i * 16
        for j in range(6):
            v = struct.unpack_from(">H", be, off + j * 2)[0]
            struct.pack_into("<H", out, off + j * 2, v)
        idx = struct.unpack_from(">I", be, off + 12)[0]
        struct.pack_into("<I", out, off + 12, idx)
    tail = n_blocks * 16
    if tail < len(be):
        out[tail:] = be[tail:]
    return bytes(out)


def _convert_dxt5_blocks(be: bytes) -> bytes:
    """Per-block DXT5 conversion: [2×u8][3×u16 alpha idx][u16 c0][u16 c1][u32 idx]."""
    out = bytearray(len(be))
    n_blocks = len(be) // 16
    for i in range(n_blocks):
        off = i * 16
        out[off] = be[off]
        out[off + 1] = be[off + 1]
        for j in range(3):
            v = struct.unpack_from(">H", be, off + 2 + j * 2)[0]
            struct.pack_into("<H", out, off + 2 + j * 2, v)
        c0 = struct.unpack_from(">H", be, off + 8)[0]
        c1 = struct.unpack_from(">H", be, off + 10)[0]
        idx = struct.unpack_from(">I", be, off + 12)[0]
        struct.pack_into("<H", out, off + 8, c0)
        struct.pack_into("<H", out, off + 10, c1)
        struct.pack_into("<I", out, off + 12, idx)
    tail = n_blocks * 16
    if tail < len(be):
        out[tail:] = be[tail:]
    return bytes(out)


# Type hashes for dispatch (verified from ASET)
_TYPE_TEXTURE = 0xF011157A
_TYPE_SCRIPT = 0x42498680
_TYPE_STANCE = 0x207359C7
_TYPE_ANIMATION = 0x18166555
_TYPE_PATH = 0xBCFE6314
_TYPE_STATE_MACHINE = 0xECE70371
_TYPE_ECS_NODE = 0xE6B81A54
_TYPE_MESH_A = 0x7C569307
_TYPE_MESH_B = 0x5B724250
_TYPE_MESH_C = 0x600B904E
_TYPE_KEYFRAME = 0x39E5E978
_TYPE_UNKNOWN_E5 = 0xE5273C14  # Audio group descriptor
_TYPE_WAVEBANK = 0xF753F6D0
_TYPE_SOUNDBANK = 0x9F8BCA10

# Mesh types share identical sub-chunk formats
_MESH_TYPES = {_TYPE_MESH_A, _TYPE_MESH_B, _TYPE_MESH_C}
_AUDIO_TYPES = {_TYPE_UNKNOWN_E5, _TYPE_WAVEBANK, _TYPE_SOUNDBANK}


def _convert_ecs_info(be: bytes) -> bytes:
    """Convert ecs_node 'info' body from BE to LE.

    Structure (verified from base game):
      [null-terminated ASCII name] [u32 name_hash] [u32 a] [u32 b] [u32 c]
    Total size = len(name) + 1 + 16.
    Only the four u32 fields need byte-swapping.
    """
    nul = be.find(b"\x00")
    if nul < 0:
        return be
    u32_start = nul + 1
    if u32_start + 16 > len(be):
        return be
    out = bytearray(be)
    for off in range(u32_start, u32_start + 16, 4):
        v = struct.unpack_from(">I", be, off)[0]
        struct.pack_into("<I", out, off, v)
    return bytes(out)


def _convert_enum_body(be: bytes) -> bytes:
    """Convert ecs_node 'enum' body from BE to LE.

    Structure (verified from base game):
      [u32 total_enum_count]
      repeated: [null-terminated enum name] [u32 name_hash] [u32 value_count]
               [value_count × (null-terminated value name + u32 value_hash)]
    Only the u32 fields need byte-swapping; all strings are ASCII passthrough.
    """
    if len(be) < 4:
        return be
    out = bytearray(be)
    # Swap total count
    total = struct.unpack_from(">I", be, 0)[0]
    struct.pack_into("<I", out, 0, total)
    pos = 4
    for _ in range(total):
        if pos >= len(be):
            break
        # Skip enum name
        nul = be.find(b"\x00", pos)
        if nul < 0:
            break
        pos = nul + 1
        # Swap name_hash
        if pos + 4 > len(be):
            break
        v = struct.unpack_from(">I", be, pos)[0]
        struct.pack_into("<I", out, pos, v)
        pos += 4
        # Swap value_count
        if pos + 4 > len(be):
            break
        val_count = struct.unpack_from(">I", be, pos)[0]
        struct.pack_into("<I", out, pos, val_count)
        pos += 4
        # Walk values
        for _ in range(val_count):
            if pos >= len(be):
                break
            nul = be.find(b"\x00", pos)
            if nul < 0:
                break
            pos = nul + 1
            if pos + 4 > len(be):
                break
            v = struct.unpack_from(">I", be, pos)[0]
            struct.pack_into("<I", out, pos, v)
            pos += 4
    return bytes(out)


def _convert_schm_body(be: bytes) -> bytes:
    """Convert ecs_node 'schm' (schema) body from BE to LE.

    Structure (verified from base game): pure u32 array of hashes and counts.
    """
    return _convert_u32_array(be)


# ── Audio type converters (mixed-endian) ─────────────────────────────

def _convert_unknown_e5_data(body_be: bytes) -> bytes:
    """Convert unknown_E5 (audio group descriptor) body from Xbox to PC.

    Layout (verified from raw Xbox DLC extraction):
      [0:4]   count          — u32 LE (already LE on both platforms!)
      [4:8]   self_hash      — u32 BE
      [8:10]  sub_count      — u16 BE
      [10:12] flags          — u16 BE
      [12:16] padding        — zeros
      [16:20] records_offset — u32 BE (=28)
      [20:24] size1          — u32 BE
      [24:28] size2          — u32 BE
    Per record (12 bytes) starting at records_offset:
      [0:4]   entry_hash     — u32 BE
      [4:8]   parent_hash    — u32 BE
      [8:10]  index          — u16 BE
      [10:12] padding        — u16 (zero)
    """
    if len(body_be) < 28:
        return body_be

    out = bytearray(body_be)

    # [0:4] count — already LE, do NOT swap
    # [4:8] self_hash — BE → LE
    struct.pack_into("<I", out, 4, struct.unpack_from(">I", body_be, 4)[0])
    # [8:10] sub_count — u16 BE → LE
    struct.pack_into("<H", out, 8, struct.unpack_from(">H", body_be, 8)[0])
    # [10:12] flags — u16 BE → LE
    struct.pack_into("<H", out, 10, struct.unpack_from(">H", body_be, 10)[0])
    # [12:16] padding — leave as-is
    # [16:20] records_offset — u32 BE → LE
    records_offset = struct.unpack_from(">I", body_be, 16)[0]
    struct.pack_into("<I", out, 16, records_offset)
    # [20:24] size1 — u32 BE → LE
    struct.pack_into("<I", out, 20, struct.unpack_from(">I", body_be, 20)[0])
    # [24:28] size2 — u32 BE → LE
    struct.pack_into("<I", out, 24, struct.unpack_from(">I", body_be, 24)[0])

    # Per-record conversion (12-byte records starting at records_offset)
    count = struct.unpack_from("<I", body_be, 0)[0]
    pos = records_offset
    for _ in range(count):
        if pos + 12 > len(body_be):
            break
        # [0:4] entry_hash — u32 BE → LE
        struct.pack_into("<I", out, pos, struct.unpack_from(">I", body_be, pos)[0])
        # [4:8] parent_hash — u32 BE → LE
        struct.pack_into("<I", out, pos + 4, struct.unpack_from(">I", body_be, pos + 4)[0])
        # [8:10] index — u16 BE → LE
        struct.pack_into("<H", out, pos + 8, struct.unpack_from(">H", body_be, pos + 8)[0])
        # [10:12] padding — leave as-is
        pos += 12

    return bytes(out)


_XBOX_ADPCM_CODEC = 0x05
_PC_IMA_ADPCM_CODEC = 0x02
_XBOX_WAVEBANK_RECORD_SIZE = 36
_PC_WAVEBANK_RECORD_SIZE = 40


def _convert_wavebank_data(body_be: bytes) -> bytes:
    """Convert wavebank body from Xbox to PC format.

    Xbox layout:
      [0:4]    count           — u32 LE (always LE!)
      [4:8]    self_hash       — u32 BE
      [8:10]   flags           — u16 BE
      [10:12]  more_flags      — u16 BE
      [12:16]  self_hash2      — u32 BE
      [16:20]  records_offset  — u32 BE (=56 for DLC, varies)
      [20:24]  padding         — zeros
      [24:records_offset]      — filename area (ASCII null-terminated strings)
    Per Xbox record (36 bytes):
      [0:4]    clip_hash       — u32 BE
      [4:8]    format_bytes    — u8[4]: [pad, channels, codec, pad]
      [8:12]   sample_rate     — u32 BE
      [12:16]  data_offset     — u32 BE
      [16:20]  data_size       — u32 BE
      [20:36]  extra fields    — u32 BE x4

    PC layout:
      [0:4]    count           — u32 LE
      [4:8]    self_hash       — u32 LE
      [8:10]   flags           — u16 LE
      [10:12]  more_flags      — u16 LE
      [12:16]  self_hash2      — u32 LE
      [16:20]  records_offset  — u32 LE (=24, no filename area)
      [20:24]  padding         — zeros
    Per PC record (40 bytes):
      [0:4]    clip_hash       — u32 LE
      [4:8]    format_bytes    — u8[4]: [pad, channels, codec, pad]
      [8:12]   sample_rate     — u32 LE
      [12:16]  data_offset     — u32 LE
      [16:20]  data_size       — u32 LE
      [20:36]  zeros           — 16 bytes padding
      [36:40]  cumul_offset    — u32 LE
    """
    if len(body_be) < 24:
        return body_be

    count = struct.unpack_from("<I", body_be, 0)[0]
    self_hash = struct.unpack_from(">I", body_be, 4)[0]
    flags = struct.unpack_from(">H", body_be, 8)[0]
    more_flags = struct.unpack_from(">H", body_be, 10)[0]
    self_hash2 = struct.unpack_from(">I", body_be, 12)[0]
    xbox_records_offset = struct.unpack_from(">I", body_be, 16)[0]

    # Extract filenames from the area between byte 24 and records_offset
    filename_area = body_be[24:xbox_records_offset]
    filenames: list[str] = []
    if filename_area:
        for part in filename_area.split(b"\x00"):
            if part:
                filenames.append(part.decode("ascii", errors="replace"))

    # Hash each filename for PC references
    filename_hashes: list[int] = []
    for fn in filenames:
        filename_hashes.append(pandemic_hash_m2(fn))

    # Parse Xbox records
    records_start = xbox_records_offset
    xbox_records: list[tuple] = []
    for i in range(count):
        roff = records_start + i * _XBOX_WAVEBANK_RECORD_SIZE
        if roff + _XBOX_WAVEBANK_RECORD_SIZE > len(body_be):
            break
        clip_hash = struct.unpack_from(">I", body_be, roff)[0]
        fmt_bytes = body_be[roff + 4:roff + 8]  # u8[4] — leave as-is
        sample_rate = struct.unpack_from(">I", body_be, roff + 8)[0]
        data_offset = struct.unpack_from(">I", body_be, roff + 12)[0]
        data_size = struct.unpack_from(">I", body_be, roff + 16)[0]
        extra = struct.unpack_from(">4I", body_be, roff + 20)
        xbox_records.append((clip_hash, fmt_bytes, sample_rate, data_offset, data_size, extra))

    # Build PC output
    pc_records_offset = 24  # PC has no filename area
    out = bytearray()

    # Header
    out += struct.pack("<I", count)          # [0:4] count (LE)
    out += struct.pack("<I", self_hash)      # [4:8] self_hash (LE)
    out += struct.pack("<H", flags)          # [8:10] flags (LE)
    out += struct.pack("<H", more_flags)     # [10:12] more_flags (LE)
    out += struct.pack("<I", self_hash2)     # [12:16] self_hash2 (LE)
    out += struct.pack("<I", pc_records_offset)  # [16:20] records_offset (LE)
    out += b"\x00" * 4                       # [20:24] padding

    # Detect trailing audio data beyond the Xbox records
    xbox_audio_start = xbox_records_offset + count * _XBOX_WAVEBANK_RECORD_SIZE
    trailing_audio = body_be[xbox_audio_start:]
    pc_audio_start = 24 + count * _PC_WAVEBANK_RECORD_SIZE

    # PC records (40 bytes each)
    cumul_offset = 0
    for clip_hash, fmt_bytes, sample_rate, data_offset, data_size, _extra in xbox_records:
        out += struct.pack("<I", clip_hash)       # [0:4] clip_hash LE
        # Format bytes: change codec from Xbox ADPCM (0x05) to IMA ADPCM (0x02)
        pc_fmt = bytearray(fmt_bytes)
        if pc_fmt[2] == _XBOX_ADPCM_CODEC:
            pc_fmt[2] = _PC_IMA_ADPCM_CODEC
        out += bytes(pc_fmt)                      # [4:8] format_bytes
        out += struct.pack("<I", sample_rate)     # [8:12] sample_rate LE
        # Rebase data_offset from Xbox layout to PC layout
        if trailing_audio and data_offset >= xbox_audio_start:
            pc_data_offset = data_offset - xbox_audio_start + pc_audio_start
        else:
            pc_data_offset = data_offset
        out += struct.pack("<I", pc_data_offset)  # [12:16] data_offset LE
        out += struct.pack("<I", data_size)       # [16:20] data_size LE
        out += b"\x00" * 16                       # [20:36] zeros
        out += struct.pack("<I", cumul_offset)    # [36:40] cumul_offset LE
        cumul_offset += data_size

    # Nibble-swap trailing audio data in-place (preserving relative layout)
    if trailing_audio:
        swapped = bytearray(trailing_audio)
        for _clip_hash, fmt_bytes, _sample_rate, data_offset, data_size, _extra in xbox_records:
            if data_offset < xbox_audio_start:
                continue
            rel_start = data_offset - xbox_audio_start
            if rel_start + data_size > len(trailing_audio):
                continue
            channels = fmt_bytes[1] if fmt_bytes[1] > 0 else 1
            clip_data = bytes(trailing_audio[rel_start:rel_start + data_size])
            transcoded = transcode_pws_xbox_to_pc(clip_data, channels=channels)
            swapped[rel_start:rel_start + len(transcoded)] = transcoded
        out += bytes(swapped)

    return bytes(out)


def _convert_soundbank_data(body_be: bytes) -> bytes:
    """Convert soundbank body from Xbox to PC format.

    Mixed endianness: count is LE, hashes and numeric params are BE, flag bytes
    are individual u8 values.

    Layout (verified from raw Xbox DLC extraction):
      [0:4]   count          — u32 LE (already LE!)
      [4:8]   self_hash      — u32 BE
      [8:12]  hash2          — u32 BE
      [12:16] header_size    — u32 BE
      [16:header_size]       — additional header fields (u32 BE each)
    Per record (variable, typical structure):
      Mix of u32 BE (hashes, float params) and u8 flags.
      Records are fixed-size within a given soundbank.

    Strategy: swap header fields individually, then for records determine
    record_size = (body_len - header_size) / count. Within each record,
    swap u32-aligned fields as BE→LE (hashes and float parameters) while
    preserving byte-level flag fields.
    """
    if len(body_be) < 16:
        return body_be

    out = bytearray(body_be)

    count = struct.unpack_from("<I", body_be, 0)[0]
    # [0:4] count — already LE, do NOT swap
    # [4:8] self_hash — u32 BE → LE
    struct.pack_into("<I", out, 4, struct.unpack_from(">I", body_be, 4)[0])
    # [8:12] hash2 — u32 BE → LE
    struct.pack_into("<I", out, 8, struct.unpack_from(">I", body_be, 8)[0])
    # [12:16] header_size/params_offset — u32 BE → LE
    header_size = struct.unpack_from(">I", body_be, 12)[0]
    struct.pack_into("<I", out, 12, header_size)

    # Swap any additional header u32 fields between offset 16 and header_size
    pos = 16
    while pos + 4 <= header_size and pos + 4 <= len(body_be):
        struct.pack_into("<I", out, pos, struct.unpack_from(">I", body_be, pos)[0])
        pos += 4

    # Records area
    if count == 0 or header_size >= len(body_be):
        return bytes(out)

    records_area = len(body_be) - header_size
    if count > 0:
        record_size = records_area // count
    else:
        return bytes(out)

    if record_size < 4:
        return bytes(out)

    # Each record: swap all u32-aligned fields as BE→LE.
    # Soundbank records contain hashes (u32) and float parameters (IEEE 754
    # stored as u32) — both need byte order swap. Individual u8 flag bytes
    # are embedded at non-u32-aligned positions in some variants, but the
    # standard Mercs 2 soundbank uses u32-aligned records throughout.
    for i in range(count):
        roff = header_size + i * record_size
        # Swap every u32 in the record
        for j in range(0, record_size - 3, 4):
            foff = roff + j
            if foff + 4 > len(body_be):
                break
            struct.pack_into("<I", out, foff, struct.unpack_from(">I", body_be, foff)[0])

    return bytes(out)


def _convert_body(tag: str, body_be: bytes, context: str | None, stats: dict,
                  type_hash: int = 0, texture_fmt: bytes = b"DXT5") -> bytes:
    """Convert a single chunk body from BE to LE based on tag, context, and entry type.

    Dispatch is purely structural — based on (type_hash, tag) pairs verified from
    reverse engineering. No content-sniffing or size-based heuristics.
    """

    # ── Tags that are always pure ASCII regardless of type ──
    if tag in ("NAME", "SINF", "TRNS", "AINF"):
        return body_be

    # ── TYPE: interleaved [null-terminated string][u16 type_code] ──
    if tag == "TYPE":
        return _convert_type_body(body_be)

    # ── DEPS: [u8 count][u32 hash × count] ──
    if tag == "DEPS":
        return _convert_deps_body(body_be)

    # ── BINN: Lua 5.1 bytecode or script reference ──
    if tag == "BINN":
        return _convert_lua_be_to_le(body_be)

    # ── flgs: 42-byte placement records ──
    if tag == "flgs":
        return _convert_flgs_records(body_be)

    # ── evnt: [u32 count][per event: float32 timestamp + 2 × cstring] ──
    if tag == "evnt":
        return _convert_evnt_body(body_be)

    # ── trnm: [u16 count][2 pad][u32 hashes...] ──
    if tag == "trnm":
        return _convert_trnm_body(body_be)

    # ── INDX: u16 index array ──
    if tag == "INDX":
        return _convert_u16_array(body_be)

    # ── data (lowercase): dispatch by context and type_hash ──
    if tag == "data":
        if context == "IBUF":
            return _convert_u16_array(body_be)
        if type_hash == _TYPE_ANIMATION:
            return _convert_havok_be_to_le(body_be)
        if type_hash == _TYPE_PATH:
            # Path data: [4 × u16 header][N × float32]
            return _convert_u16_array(body_be[:8]) + _convert_u32_array(body_be[8:])
        if type_hash == _TYPE_UNKNOWN_E5:
            return _convert_unknown_e5_data(body_be)
        if type_hash == _TYPE_WAVEBANK:
            return _convert_wavebank_data(body_be)
        if type_hash == _TYPE_SOUNDBANK:
            return _convert_soundbank_data(body_be)
        # Mesh types, ecs_node, scripts: float32/u32 vertex data or numeric arrays
        return _convert_u32_array(body_be)

    # ── info (lowercase): dispatch by type_hash ──
    if tag == "info":
        if context == "META":
            return body_be
        if type_hash == _TYPE_ANIMATION:
            # Always 2 bytes: u16 track count
            return _convert_u16_array(body_be)
        if type_hash == _TYPE_ECS_NODE:
            # [name\0][u32 hash][u32][u32][u32]
            return _convert_ecs_info(body_be)
        # Mesh types (0x7C569307, 0x5B724250, 0x600B904E): pure u32 arrays
        return _convert_u32_array(body_be)

    # ── enum: dispatch by type_hash ──
    if tag == "enum":
        if context == "META":
            return body_be
        if type_hash == _TYPE_ECS_NODE:
            # [u32 count][repeated: name\0 + u32 hash + u32 val_count + values...]
            return _convert_enum_body(body_be)
        # Other types: u32 arrays
        return _convert_u32_array(body_be)

    # ── flgt: u32 hash (single value or array) ──
    if tag == "flgt":
        if context == "META":
            return body_be
        return _convert_u32_array(body_be)

    # ── schm: pure u32 hash/count arrays ──
    if tag == "schm":
        return _convert_schm_body(body_be)

    # ── INFO (uppercase, entry-level): dispatch by type_hash ──
    if tag == "INFO":
        if type_hash == _TYPE_TEXTURE:
            return _convert_texture_info(body_be)
        if type_hash == _TYPE_SCRIPT:
            return _convert_script_info(body_be)
        # Mesh types INFO: u32 arrays (counts, bounding box floats)
        # Keyframe INFO: u32 arrays
        return _convert_u32_array(body_be)

    # ── BODY (uppercase): dispatch by type_hash ──
    if tag == "BODY":
        if type_hash == _TYPE_TEXTURE:
            return _convert_dxt_body(body_be, texture_fmt)
        return _convert_u32_array(body_be)

    # ── STRS/KEYS: string table / u32 key arrays ──
    if tag == "STRS":
        return body_be  # Null-terminated string table, endian-neutral
    if tag == "KEYS":
        return _convert_u32_array(body_be)

    # ── decl: vertex declaration, u16-packed element descriptors ──
    if tag == "decl":
        return _convert_u16_array(body_be)

    # ── STRM: vertex stream data (float32 positions/normals/UVs) ──
    if tag == "STRM":
        return _convert_u32_array(body_be)

    # ── Mesh hierarchy/material tags: u16 arrays (indices, slot refs) ──
    if tag in ("HIER", "MTRL", "SEGM", "PRMT", "BSHI"):
        return _convert_u16_array(body_be)

    # ── Particle system tags: u16 fields ──
    if tag in ("EFCT", "EMTR"):
        return _convert_u16_array(body_be)

    # ── Mesh structure tags: u32 arrays (offsets, counts, hashes) ──
    if tag in ("PRMG", "GEOM", "POFF", "STAT", "SWIT",
               "NODE", "CEXE", "PHY2", "COMP", "CHDR", "TINY",
               "SCRB", "INST", "PTCH", "PTMS"):
        return _convert_u32_array(body_be)

    # Unknown tag — log and use u32 (safest for numeric data)
    stats["tags_seen"][tag] = stats["tags_seen"].get(tag, 0) + 1
    return _convert_u32_array(body_be)


# ── Container conversion ──────────────────────────────────────────────

def _convert_container(container_be: bytes, stats: dict,
                       type_hash: int = 0) -> bytes:
    """Parse one BE UCFX container and serialize as LE."""
    if len(container_be) < 20:
        stats["errors"].append(f"Container too short: {len(container_be)} bytes")
        return container_be

    # Parse UCFX header (BE)
    magic_raw = container_be[0:4]
    if magic_raw != b"XFCU" and magic_raw[::-1] != b"UCFX":
        stats["errors"].append(f"Bad UCFX magic: {magic_raw!r}")
        return container_be

    data_area_off = struct.unpack_from(">I", container_be, 4)[0]
    u1 = struct.unpack_from(">I", container_be, 8)[0]
    u2 = struct.unpack_from(">I", container_be, 12)[0]
    n_descriptors = struct.unpack_from(">I", container_be, 16)[0]

    if n_descriptors > 50_000:
        stats["errors"].append(f"Implausible descriptor count: {n_descriptors}")
        return _convert_u32_array(container_be)

    # Parse descriptor rows (BE)
    descriptors: list[tuple[str, int, int, int, int]] = []
    for i in range(n_descriptors):
        row_off = 20 + i * CHUNK_HDR
        if row_off + CHUNK_HDR > len(container_be):
            break
        tag_raw = container_be[row_off:row_off + 4][::-1]
        tag_str = tag_raw.decode("ascii", errors="replace")
        row_u0, body_size, f3, f4 = struct.unpack_from(">IIII", container_be, row_off + 4)
        descriptors.append((tag_str, row_u0, body_size, f3, f4))

    # Classify contexts
    contexts = _classify_contexts(descriptors)

    # Extract and convert each body
    bodies_le: list[bytes] = []
    texture_fmt = b"DXT5"  # Default; overwritten from INFO if type is texture
    for idx, (tag, row_u0, body_size, _f3, _f4) in enumerate(descriptors):
        if data_area_off > 0:
            body_start = data_area_off + row_u0
        else:
            body_start = 8 + row_u0

        body_end = body_start + body_size
        if body_end > len(container_be):
            body_end = len(container_be)
        if body_start >= len(container_be):
            bodies_le.append(b"")
            continue

        body_be = container_be[body_start:body_end]

        # For texture entries, extract format string from INFO before BODY
        if type_hash == _TYPE_TEXTURE and tag == "INFO" and body_size >= 22:
            texture_fmt = body_be[14:22]

        if row_u0 == CONTAINER_SENTINEL:
            bodies_le.append(_convert_u32_array(body_be))
        else:
            bodies_le.append(_convert_body(tag, body_be, contexts[idx], stats,
                                            type_hash=type_hash,
                                            texture_fmt=texture_fmt))

    # Serialize as LE
    out = bytearray()

    # For audio types, the converted body may differ in size from the original.
    # Update descriptor body_size values to reflect actual converted sizes.
    updated_descriptors = list(descriptors)
    if type_hash in _AUDIO_TYPES:
        for idx, (tag, row_u0, body_size, f3, f4) in enumerate(descriptors):
            if row_u0 == CONTAINER_SENTINEL:
                continue
            new_size = len(bodies_le[idx])
            if new_size != body_size:
                updated_descriptors[idx] = (tag, row_u0, new_size, f3, f4)

    # UCFX header
    out += b"UCFX"
    out += struct.pack("<IIII", data_area_off, u1, u2, n_descriptors)

    # Descriptor rows (with potentially updated body_size for audio types)
    for tag, row_u0, body_size, f3, f4 in updated_descriptors:
        out += tag.encode("ascii", errors="replace")[:4].ljust(4, b"\x00")
        out += struct.pack("<IIII", row_u0, body_size, f3, f4)

    # Pad to data_area_off if needed
    header_size = 20 + n_descriptors * CHUNK_HDR
    if data_area_off > header_size:
        pad = data_area_off - header_size
        if 20 + n_descriptors * CHUNK_HDR + pad <= len(container_be):
            out += container_be[header_size:data_area_off]
        else:
            out += b"\x00" * pad

    # Write body data area
    body_area_out = bytearray()
    for idx, (_, row_u0, body_size, _, _) in enumerate(updated_descriptors):
        if row_u0 == CONTAINER_SENTINEL:
            if data_area_off > 0:
                target_off = data_area_off + CONTAINER_SENTINEL
            else:
                target_off = 8 + CONTAINER_SENTINEL
            pass
        body_le = bodies_le[idx]
        if len(body_le) < body_size:
            body_le = body_le + b"\x00" * (body_size - len(body_le))
        elif len(body_le) > body_size:
            body_le = body_le[:body_size]

    # The body area layout mirrors the source: bodies at their original offsets
    # relative to data_area_off. For audio types with resized bodies, we need
    # to compute the required body area size from the updated descriptors.
    if type_hash in _AUDIO_TYPES:
        # Compute required body area size from actual converted body lengths
        required_size = 0
        for idx, (_, row_u0, body_size, _, _) in enumerate(updated_descriptors):
            if row_u0 == CONTAINER_SENTINEL:
                continue
            end = row_u0 + body_size
            if end > required_size:
                required_size = end
        source_body_area_size = required_size
    elif data_area_off > 0 and data_area_off < len(container_be):
        source_body_area_size = len(container_be) - data_area_off
    else:
        source_body_area_size = len(container_be) - 8 if data_area_off == 0 else 0

    body_area = bytearray(source_body_area_size)

    for idx, (_, row_u0, body_size, _, _) in enumerate(updated_descriptors):
        if row_u0 == CONTAINER_SENTINEL:
            continue
        body_le = bodies_le[idx]
        actual_size = min(body_size, len(body_le))
        if row_u0 + actual_size <= len(body_area):
            body_area[row_u0:row_u0 + actual_size] = body_le[:actual_size]

    # Handle container-sentinel rows (their body offset is CONTAINER_SENTINEL
    # which is just a marker; body data is located via the data_area_off)
    for idx, (_, row_u0, body_size, _, _) in enumerate(updated_descriptors):
        if row_u0 != CONTAINER_SENTINEL:
            continue
        body_le = bodies_le[idx]
        if data_area_off > 0:
            rel_off = CONTAINER_SENTINEL
        else:
            rel_off = CONTAINER_SENTINEL
        # Container sentinels: body at row_u0 position within body area.
        # CONTAINER_SENTINEL = 0xFFFFFFFF is NOT a real offset; containers
        # typically have no meaningful body, but the "body" field in the
        # existing tool was interpreted relative. For safety, write at offset
        # computed from source.
        if data_area_off > 0:
            src_start = data_area_off + row_u0
        else:
            src_start = 8 + row_u0
        # Container sentinel rows don't have real body offsets; their data
        # is at the same relative position in the source.  Since row_u0 is
        # 0xFFFFFFFF (huge), these are overflow markers with no body data
        # to write.  Skip them.

    # Trim or extend body_area to match expected size
    current_size = len(out)
    if data_area_off > 0:
        expected_header = data_area_off
    else:
        expected_header = header_size

    # If out is smaller than data_area_off, pad
    while len(out) < expected_header:
        out += b"\x00"

    # Truncate if we over-wrote
    out = out[:expected_header]
    out += body_area

    return bytes(out)


# ── Block-level conversion ────────────────────────────────────────────

def _parse_entry_table_be(be: bytes) -> list[tuple[int, int, int, int]]:
    """Parse BE entry table: count + N x (hash, type_hash, offset, size)."""
    count = struct.unpack_from(">I", be, 0)[0]
    entries = []
    for i in range(count):
        off = 4 + i * 16
        if off + 16 > len(be):
            break
        h, t, o, s = struct.unpack_from(">IIII", be, off)
        entries.append((h, t, o, s))
    return entries


def _serialize_entry_table_le(entries: list[tuple[int, int, int, int]]) -> bytes:
    """Serialize entry table as LE."""
    out = struct.pack("<I", len(entries))
    for h, t, o, s in entries:
        out += struct.pack("<IIII", h, t, o, s)
    return out


def byteswap_ucfx_block(
    block_data: bytes,
    havok_overrides: dict[int, bytes] | None = None,
) -> tuple[bytes, dict]:
    """Convert a decompressed Xbox UCFX block to PC little-endian.

    Structurally parses the BE input and serializes fresh LE output.
    Returns (le_bytes, stats_dict).

    If *havok_overrides* is provided, it maps entry indices to already-correct
    LE UCFX container bytes (without CSUM).  Entries in the map bypass BE→LE
    conversion entirely — used to substitute base-game data for formats that
    cannot be field-level byte-swapped (Havok, textures, meshes, etc.).

    When an override or audio conversion produces output larger than the
    original Xbox entry slot, the entry table size field is expanded to
    accommodate it (the block is recompressed afterward so total size is
    unconstrained).
    """
    stats: dict = {
        "ucfx_found": 0, "chunks_swapped": 0, "csum_swapped": 0,
        "tags_seen": {}, "errors": [],
    }

    if len(block_data) < 4:
        return block_data, stats

    # Parse entry table
    entries = _parse_entry_table_be(block_data)
    header_end = 4 + len(entries) * 16

    # Phase 1: Convert all containers, collecting LE output bytes
    converted_containers: list[bytes] = []
    pos = header_end
    for entry_idx, (_, type_hash, _, orig_size) in enumerate(entries):
        if pos + orig_size > len(block_data):
            container_be = block_data[pos:]
        else:
            container_be = block_data[pos:pos + orig_size]

        # Use override if available (pre-converted LE from base game)
        if havok_overrides and entry_idx in havok_overrides:
            ucfx_le = havok_overrides[entry_idx]
            csum_val = crc32_mercs2(ucfx_le)
            container_le = ucfx_le + b"CSUM" + struct.pack("<I", csum_val)
            stats["ucfx_found"] += 1
            stats["csum_swapped"] += 1
            converted_containers.append(container_le)
            pos += orig_size
            continue

        # Check for CSUM trailer (last 8 bytes of entry)
        has_csum = False
        if len(container_be) >= 8:
            csum_tag = container_be[-8:-4]
            if csum_tag == b"MUSC" or csum_tag[::-1] == b"CSUM" or csum_tag == b"CSUM":
                has_csum = True

        # Strip CSUM from container for conversion
        if has_csum:
            ucfx_be = container_be[:-8]
        else:
            ucfx_be = container_be

        # Convert the UCFX container
        ucfx_le = _convert_container(ucfx_be, stats, type_hash=type_hash)
        stats["ucfx_found"] += 1

        # Recompute CSUM over the LE output
        csum_val = crc32_mercs2(ucfx_le)
        container_le = ucfx_le + b"CSUM" + struct.pack("<I", csum_val)
        stats["csum_swapped"] += 1

        converted_containers.append(container_le)
        pos += orig_size

    # Phase 2: Build entry table with actual output sizes
    corrected_entries = list(entries)
    for entry_idx, container_le in enumerate(converted_containers):
        h, t, o, orig_size = corrected_entries[entry_idx]
        actual_size = len(container_le)
        if actual_size != orig_size:
            corrected_entries[entry_idx] = (h, t, o, actual_size)

    # Serialize entry table as LE with corrected sizes
    out = bytearray(_serialize_entry_table_le(corrected_entries))

    # Phase 3: Append converted containers, padding to declared sizes
    for entry_idx, container_le in enumerate(converted_containers):
        declared_size = corrected_entries[entry_idx][3]
        if len(container_le) < declared_size:
            container_le = container_le + b"\x00" * (declared_size - len(container_le))
        out += container_le

    return bytes(out), stats


# ── Legacy API ────────────────────────────────────────────────────────

def recompute_csums(data: bytearray, entry_count: int) -> int:
    """Recompute all CSUM trailers in an already-LE block. Returns count updated."""
    count = 0
    header_end = 4 + entry_count * 16
    pos = header_end
    for i in range(entry_count):
        off = 4 + i * 16
        if off + 12 > len(data):
            break
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
