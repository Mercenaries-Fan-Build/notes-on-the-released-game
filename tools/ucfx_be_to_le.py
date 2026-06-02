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

from dataclasses import dataclass

from pandemic_hash import pandemic_hash_m2
from audio_codec_policy import PC_PWS_HEADER_SIZE
from pws_xbox_to_pc import normalize_embedded_wavebank_clip


class UnhandledByteSwapError(ValueError):
    """No verified semantic BE→LE converter for this chunk; conversion refused."""


def _fallback_u32_or_raise(
    body_be: bytes,
    *,
    reason: str,
    tag: str,
    type_hash: int,
    context: str | None,
    permissive: bool,
    stats: dict,
) -> bytes:
    """Strict mode raises; permissive mode logs and applies u32 array swap.

    WARNING: The permissive path is a KNOWN BLIND SWAP for testing only.
    It will corrupt any body containing u8, u16, or string fields.
    """
    if permissive:
        stats["fallback_u32_count"] = stats.get("fallback_u32_count", 0) + 1
        tags = stats.setdefault("fallback_u32_tags", {})
        tags[tag] = tags.get(tag, 0) + 1
        blind_detail = stats.setdefault("blind_swap_detail", [])
        blind_detail.append(
            f"BLIND_SWAP: tag={tag!r} type_hash=0x{type_hash:08X} "
            f"body_size={len(body_be)} context={context!r} reason={reason}"
        )
        return _convert_u32_array(body_be)
    raise UnhandledByteSwapError(
        f"{reason}: tag={tag!r} type_hash=0x{type_hash:08X} "
        f"body_size={len(body_be)} context={context!r}"
    )


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
    """CRC-32 with init=0, no final XOR (Mercenaries 2 CSUM).

    Implementation detail: zlib.crc32(data, 0xFFFFFFFF) uses effective init=0
    internally (zlib XORs the seed with 0xFFFFFFFF), and the outer ^0xFFFFFFFF
    cancels zlib's own final inversion — net result is init=0, no final XOR.
    """
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


# ── Placement record converters ───────────────────────────────────────

def _convert_transform_records(be: bytes) -> bytes:
    """Convert layers_static Transform records (ECS_NODE 'data' body).

    Format: [u32 entity_key][8×f32 pos/quat][u32 tail_a][u16 tail_b] = 42 bytes.
    """
    STRIDE = 42
    if len(be) % STRIDE != 0:
        raise UnhandledByteSwapError(
            f"Transform data body size {len(be)} is not a multiple of {STRIDE}; "
            f"corrupt or unknown record format"
        )
    out = bytearray()
    pos = 0
    while pos + STRIDE <= len(be):
        record = be[pos:pos + STRIDE]
        u32s = struct.unpack_from(">10I", record, 0)
        u16 = struct.unpack_from(">H", record, 40)[0]
        out += struct.pack("<10I", *u32s)
        out += struct.pack("<H", u16)
        pos += STRIDE
    return bytes(out)


def _convert_hibernation_records(be: bytes) -> bytes:
    """Convert HibernationControl records (ECS_NODE 'data' body, stride 10).

    schm-declared payload layout (verified byte-identical to retail PC
    ``layers_static`` block 29 and DLC block 18):

        +0  u32 entity_key
        +4  u16 field      (type 4, name_hash 0xCBE8ED58)
        +6  u8             (type 2)
        +7  u8             (type 2)
        +8  u8             (type 2)
        +9  u8 bit-flags   (two type-1 bits at byte 5)

    The payload is **not** a u32 array: a blanket u32 sweep reverses a 4-byte
    word across the ``u16 + u8 + u8`` region (and a u16 across the
    ``u8 + bitflags`` tail), corrupting the u16 into a constant (0xA03C) and
    scrambling the per-entity value. Swap only the entity-key u32 and the
    payload u16; the trailing u8/bit fields are endian-neutral. Reproduces the
    retail ``XX 00 a0 3c 14 00`` byte pattern exactly.
    """
    STRIDE = 10
    if len(be) % STRIDE != 0:
        raise UnhandledByteSwapError(
            f"HibernationControl data body size {len(be)} is not a multiple of "
            f"{STRIDE}; corrupt or unknown record format"
        )
    out = bytearray(be)
    for pos in range(0, len(be), STRIDE):
        struct.pack_into("<I", out, pos, struct.unpack_from(">I", be, pos)[0])
        struct.pack_into("<H", out, pos + 4, struct.unpack_from(">H", be, pos + 4)[0])
        # out[pos+6 .. pos+10] (u8 + u8 + u8 + bitflags) are endian-neutral.
    return bytes(out)


def _convert_numeric_records(be: bytes, stride: int) -> bytes:
    """Convert fixed-stride numeric records where stride is not a multiple of 4.

    Each record is swapped as u32 words followed by a u16 remainder (if the
    stride mod 4 is 2) or a raw byte tail (if mod 4 is 1 or 3).
    """
    if stride <= 0 or len(be) == 0:
        return be
    out = bytearray()
    pos = 0
    while pos + stride <= len(be):
        record = be[pos:pos + stride]
        n_u32 = stride // 4
        tail = stride % 4
        if n_u32 > 0:
            vals = struct.unpack_from(f">{n_u32}I", record, 0)
            out += struct.pack(f"<{n_u32}I", *vals)
        if tail >= 2:
            v16 = struct.unpack_from(">H", record, n_u32 * 4)[0]
            out += struct.pack("<H", v16)
            if tail > 2:
                out += record[n_u32 * 4 + 2:]
        elif tail > 0:
            out += record[n_u32 * 4:]
        pos += stride
    if pos < len(be):
        out += _convert_u32_array(be[pos:])
    return bytes(out)


_BE_ONE_F = b"\x3f\x80\x00\x00"  # float 1.0 in big-endian


def _convert_vz_state_flgs(be: bytes) -> bytes:
    """Convert vz_state placement body: variable header + 42-byte packed records.

    Record layout (42 bytes, packed — u16 at offset 12 breaks u32 alignment):
        [0:12]  3×u32  (state_flags, boot_float, type_hash)
        [12:14] 1×u16  (extra_flags)
        [14:42] 7×u32  (entity_id, pos_x, pos_y, pos_z, rot_0, rot_1, rot_y)

    The header region (before records) contains entity name strings (u8 data)
    interspersed with u32 hashes.  Since the boundary between string bytes and
    hash u32s is ambiguous, the header is passed through as raw bytes — strings
    are ASCII (endian-neutral) and the game resolves names by string matching.
    """
    STRIDE = 42

    # Find record start: first BE 1.0f is the boot_float field at record+4
    marker_pos = be.find(_BE_ONE_F)
    if marker_pos >= 4:
        rec_start = marker_pos - 4
    elif marker_pos >= 0:
        rec_start = 0
    else:
        # No 1.0f marker — likely layers_static-style u32 flags (no records)
        if len(be) % 4 == 0:
            return _convert_u32_array(be)
        raise UnhandledByteSwapError(
            f"ECS_NODE flgs body ({len(be)} bytes): no 1.0f marker found "
            f"and body is not u32-aligned"
        )

    # Header: pass through as-is (entity name strings, endian-neutral)
    header = be[:rec_start]

    # Records region
    rec_data = be[rec_start:]
    n_full = len(rec_data) // STRIDE
    rec_used = n_full * STRIDE
    tail = rec_data[rec_used:]

    out = bytearray(header)
    pos = 0
    while pos + STRIDE <= len(rec_data):
        record = rec_data[pos:pos + STRIDE]
        # 3×u32 at [0:12]
        u32_head = struct.unpack_from(">3I", record, 0)
        # 1×u16 at [12:14]
        u16_flags = struct.unpack_from(">H", record, 12)[0]
        # 7×u32 at [14:42]
        u32_tail = struct.unpack_from(">7I", record, 14)
        out += struct.pack("<3I", *u32_head)
        out += struct.pack("<H", u16_flags)
        out += struct.pack("<7I", *u32_tail)
        pos += STRIDE

    # Tail bytes after last full record (should be rare/zero)
    if tail:
        if len(tail) % 4 == 0:
            out += _convert_u32_array(tail)
        else:
            out += tail  # preserve as-is (endian-neutral residual)

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


def _havok_parse_classnames_be(be: bytes, cn_abs: int, cn_end: int) -> dict[int, str]:
    """Parse __classnames__ table from BE packfile data.

    Returns {relative_offset_in_cn_section: class_name}.
    """
    names: dict[int, str] = {}
    p = cn_abs
    body_end = cn_abs + cn_end
    while p + 5 <= body_end:
        sig = struct.unpack_from(">I", be, p)[0]
        if sig == 0xFFFFFFFF:
            break
        rel_off = p - cn_abs
        q = p + 5
        while q < body_end and be[q] != 0:
            q += 1
        name = be[p + 5:q].decode("ascii", errors="replace")
        names[rel_off + 5] = name
        q += 1
        p = q
    return names


def _havok_parse_virtual_fixups_be(
    be: bytes, da_abs: int, vf_off: int, da_end: int
) -> list[tuple[int, int, int]]:
    """Parse virtual fixup stream from BE __data__ section.

    Returns list of (src_offset_in_data, section_index, classname_offset).
    """
    fixups: list[tuple[int, int, int]] = []
    p = da_abs + vf_off
    end = da_abs + da_end
    while p + 12 <= end:
        src = struct.unpack_from(">I", be, p)[0]
        sec = struct.unpack_from(">I", be, p + 4)[0]
        cn_off = struct.unpack_from(">I", be, p + 8)[0]
        if src == 0xFFFFFFFF:
            break
        fixups.append((src, sec, cn_off))
        p += 12
    return fixups


def _havok_parse_local_fixups_be(
    be: bytes, da_abs: int, lf_off: int, gf_off: int
) -> list[tuple[int, int]]:
    """Parse local fixup stream from BE __data__ section.

    Returns list of (src_offset_in_data, dst_offset_in_data).
    """
    fixups: list[tuple[int, int]] = []
    p = da_abs + lf_off
    end = da_abs + gf_off
    while p + 8 <= end:
        src = struct.unpack_from(">I", be, p)[0]
        dst = struct.unpack_from(">I", be, p + 4)[0]
        if src == 0xFFFFFFFF:
            break
        fixups.append((src, dst))
        p += 8
    return fixups


def _havok_swap_data_class_aware(
    be: bytes, out: bytearray, da_abs: int, sections: list[tuple],
    cn_abs: int, cn_end: int, *, stats: dict | None = None
) -> bool:
    """Class-aware BE→LE swap of Havok __data__ section.

    Uses virtual fixups to identify objects by class, then applies per-field
    byte-swapping according to HK550 32-bit class layouts from HavokLib.

    Returns True if conversion succeeded, False if it had to fall back.
    """
    from hk_class_layouts import CLASS_REGISTRY, U8, U16, U32

    da_abs_v, da_lf, da_gf, da_vf, _, _, da_end = sections[2]

    if da_end == 0:
        return True

    cn_names = _havok_parse_classnames_be(be, cn_abs, cn_end)
    vfixups = _havok_parse_virtual_fixups_be(be, da_abs, da_vf, da_end)
    lfixups = _havok_parse_local_fixups_be(be, da_abs, da_lf, da_gf)

    obj_map: dict[int, str] = {}
    for src, _sec, cn_off in vfixups:
        name = cn_names.get(cn_off, "")
        if name:
            obj_map[src] = name

    lf_map: dict[int, int] = {src: dst for src, dst in lfixups}

    no_swap_regions: list[tuple[int, int]] = []

    for obj_off, class_name in obj_map.items():
        cls = CLASS_REGISTRY.get(class_name)
        if cls is None:
            continue
        arrays = cls.get("arrays", {})
        for arr_name, arr_info in arrays.items():
            if arr_info.get("elem_swap") == U8:
                ptr_off = arr_info.get("ptr_off")
                count_off = arr_info.get("count_off")
                if ptr_off is not None and count_off is not None:
                    ptr_src = obj_off + ptr_off
                    buf_dst = lf_map.get(ptr_src)
                    if buf_dst is not None:
                        count_abs = da_abs + obj_off + count_off
                        if count_abs + 4 <= len(be):
                            n = struct.unpack_from(">I", be, count_abs)[0]
                            if n < 0x1000000:
                                no_swap_regions.append((buf_dst, buf_dst + n))

    no_swap_regions.sort()

    def _in_no_swap(off: int) -> bool:
        for start, end in no_swap_regions:
            if start <= off < end:
                return True
            if start > off:
                break
        return False

    obj_offsets_sorted = sorted(obj_map.keys())

    swap_width = bytearray(da_end)

    for obj_off, class_name in obj_map.items():
        cls = CLASS_REGISTRY.get(class_name)
        if cls is None:
            obj_size = 4
            if obj_off + obj_size <= da_end:
                for i in range(0, obj_size, 4):
                    if obj_off + i < da_end:
                        swap_width[obj_off + i] = U32
            continue

        obj_size = cls["size"]
        swap_spec = cls["swap"]

        if swap_spec == "all_u32":
            for i in range(0, min(obj_size, da_end - obj_off), 4):
                swap_width[obj_off + i] = U32
        else:
            for field_off, w in swap_spec:
                abs_off = obj_off + field_off
                if abs_off < da_end:
                    swap_width[abs_off] = w

        arrays = cls.get("arrays", {})
        for arr_name, arr_info in arrays.items():
            ptr_off = arr_info.get("ptr_off")
            count_off = arr_info.get("count_off")
            elem_size = arr_info["elem_size"]
            elem_swap = arr_info["elem_swap"]

            if ptr_off is None or count_off is None:
                continue

            ptr_src = obj_off + ptr_off
            buf_dst = lf_map.get(ptr_src)
            if buf_dst is None:
                continue

            count_abs = da_abs + obj_off + count_off
            if count_abs + 4 > len(be):
                continue
            count = struct.unpack_from(">I", be, count_abs)[0]
            if count > 0x1000000:
                continue

            if elem_swap == U8:
                pass
            elif elem_swap == U32:
                total = count * elem_size
                for i in range(0, total, 4):
                    pos = buf_dst + i
                    if pos < da_end:
                        swap_width[pos] = U32
            elif elem_swap == U16:
                total = count * elem_size
                for i in range(0, total, 2):
                    pos = buf_dst + i
                    if pos < da_end:
                        swap_width[pos] = U16

    for off in range(0, da_lf, 4):
        if swap_width[off] == 0 and not _in_no_swap(off):
            swap_width[off] = U32

    for off in range(da_lf, da_end, 4):
        if swap_width[off] == 0:
            swap_width[off] = U32

    off = 0
    while off < da_end:
        w = swap_width[off]
        abs_off = da_abs + off
        if w == U32:
            if abs_off + 4 <= len(be):
                val = struct.unpack_from(">I", be, abs_off)[0]
                struct.pack_into("<I", out, abs_off, val)
            off += 4
        elif w == U16:
            if abs_off + 2 <= len(be):
                val = struct.unpack_from(">H", be, abs_off)[0]
                struct.pack_into("<H", out, abs_off, val)
            off += 2
        elif w == U8:
            if abs_off < len(be):
                out[abs_off] = be[abs_off]
            off += 1
        else:
            if abs_off < len(be):
                out[abs_off] = be[abs_off]
            off += 1

    if stats is not None:
        stats["havok_class_aware_objects"] = len(obj_map)
        stats["havok_no_swap_regions"] = len(no_swap_regions)

    return True


def _fix_embedded_havok_layoutrules(
    be: bytes, out: bytearray, start: int, end: int
) -> int:
    """Repair embedded Havok packfile headers inside a converted ``__data__`` region.

    Havok animgroup ``__data__`` sections embed nested packfile headers (the full
    8-byte magic ``57 E0 E0 57 10 C0 C0 10``). Their 4-byte ``layoutRules`` field is
    ``{ u8 ptrSize; u8 littleEndian; u8 reusePadding; u8 emptyBaseClass }`` — NOT a
    u32. The class-aware / blind ``__data__`` sweep treats unmarked offsets as u32 and
    byte-reverses the Xbox 360 BE value ``04 00 00 01`` into ``01 00 00 04``, scrambling
    the fields (ptrSize→1) and zeroing the littleEndian byte at ``+17``. Restore the 4
    bytes verbatim from BE and set ``littleEndian = 1``, matching the outer-header path
    (steps 3 above). Alignment-independent: the 8-byte magic is palindromic per u32 word,
    so it survives the swap and is found at the same offset in ``be``.

    Returns the number of embedded headers repaired.
    """
    fixed = 0
    region_end = min(end, len(be))
    pos = start
    while True:
        m = be.find(_HAVOK_MAGIC, pos, region_end)
        if m < 0:
            break
        if m + 20 <= len(be):
            out[m + 16 : m + 20] = be[m + 16 : m + 20]  # layoutRules: 4 × u8, no swap
            out[m + 17] = 1  # is_little_endian
            fixed += 1
        pos = m + 8
    return fixed


def _convert_havok_be_to_le(be: bytes, *, permissive: bool = False, stats: dict | None = None) -> bytes:
    """Structurally convert a Havok 5.5 packfile from BE to LE.

    Converts header fields, section headers, __classnames__ signatures,
    and __data__ using class-aware per-field byte-swapping derived from
    PredatorCZ/HavokLib class layouts for HK550 32-bit.

    The class-aware converter identifies objects via virtual fixups, applies
    per-field swap widths (u32 for pointers/floats/enums, u16 for refcounts
    and bone indices, u8/no-swap for QuantizationFormat bytes and compressed
    bitstream buffers). Falls back to permissive u32 sweep only if class-aware
    conversion reports failure.

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
      [da_abs, da_abs+da_end) __data__: class-aware per-field swap
    """
    if len(be) < 64:
        raise UnhandledByteSwapError(
            f"Havok packfile too short ({len(be)} bytes) for structural parse"
        )

    ver_off = be.find(_HAVOK_VER)
    if ver_off < 0:
        ver_off = be.find(b"Havok-")
    if ver_off < 0:
        raise UnhandledByteSwapError("Havok packfile missing version string")

    cn_needle_off = be.find(b"__classnames__", ver_off)
    if cn_needle_off < 0:
        raise UnhandledByteSwapError("Havok packfile missing __classnames__ section")

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

    # 9. __data__ section: class-aware byte-swap using HavokLib layouts.
    #    Virtual fixups identify each object's class; per-field swap widths
    #    are applied (u32 for most fields, u16 for refcounts/indices, u8 for
    #    QuantizationFormat bytes and raw bitstream buffers).
    if da_end > 0 and da_abs + da_end <= len(be):
        da_local = sections[2][1]
        success = _havok_swap_data_class_aware(
            be, out, da_abs, sections, cn_abs, cn_end, stats=stats
        )
        if not success:
            if not permissive:
                raise UnhandledByteSwapError(
                    f"Havok __data__ section ({da_end} bytes) class-aware "
                    f"conversion failed and permissive mode is off"
                )
            if stats is not None:
                stats["havok_blind_data_sweep"] = stats.get("havok_blind_data_sweep", 0) + 1
            n = da_end // 4
            for i in range(n):
                off = da_abs + i * 4
                val = struct.unpack_from(">I", be, off)[0]
                struct.pack_into("<I", out, off, val)
            tail = da_abs + n * 4
            if tail < da_abs + da_end:
                out[tail:da_abs + da_end] = be[tail:da_abs + da_end]

        # Repair embedded packfile headers whose layoutRules (4 × u8) were
        # wrongly u32-swapped by the class-aware default-fill or the blind sweep.
        n_fixed = _fix_embedded_havok_layoutrules(be, out, da_abs, da_abs + da_end)
        if stats is not None and n_fixed:
            stats["havok_embedded_layoutrules_fixed"] = (
                stats.get("havok_embedded_layoutrules_fixed", 0) + n_fixed
            )

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

def _convert_binn_pre_luaq(data: bytearray, luaq_off: int) -> None:
    """Swap BINN metadata before LuaQ (docs/modding_deep_dive.md §4.7)."""
    if luaq_off < 4:
        return
    struct.pack_into("<I", data, 0, struct.unpack_from(">I", data, 0)[0])
    if luaq_off >= 15:
        struct.pack_into("<H", data, 13, struct.unpack_from(">H", data, 13)[0])
    nul = data.find(b"\x00", 15, luaq_off)
    if nul < 0:
        return
    pos = nul + 1
    if luaq_off >= 4:
        id_off = luaq_off - 4
        struct.pack_into("<I", data, id_off, struct.unpack_from(">I", data, id_off)[0])
        dep_end = id_off
    else:
        dep_end = luaq_off
    if pos < dep_end:
        dep_count = data[pos]
        pos += 1
        while pos < dep_end and (dep_end - pos) % 4 != 0:
            pos += 1
        while pos + 4 <= dep_end:
            struct.pack_into("<I", data, pos, struct.unpack_from(">I", data, pos)[0])
            pos += 4


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
    struct.pack_into("<I", out, 0, struct.unpack_from(">I", be, 0)[0])
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

    if luaq_off > 0:
        _convert_binn_pre_luaq(data, luaq_off)

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

_CONTAINER_TAGS = frozenset(("STRM", "GEOM", "IBUF", "CHDR", "COMP", "STAT", "PRMT", "EXEC", "EMIT"))
_META_CONTAINERS = frozenset(("CHDR", "COMP", "STAT", "PRMT", "EXEC"))
_STREAM_CONTAINERS = frozenset(("STRM", "GEOM"))


@dataclass
class _CompInfo:
    """Active COMP component identity from the info/schm descriptors."""
    component_name: str
    schema_stride: int


_ECS_STRING_COMPONENTS = frozenset({
    "Name",
})

_ECS_NUMERIC_COMPONENTS = frozenset({
    "LightObject", "Road", "RoadIntersection",
    "DestructionLink", "PhysicalLink", "ObjectScript",
    "ModifierKey", "ScrubObject", "LineRegion", "MaterialMapping",
    "LandingZone", "Label", "Anchor", "LowResTerrainObject",
    "HibernationControl",
    "AtmosphereBase", "IntersectionToIntersection",
    "SoundAmbience", "AiBehavior", "Path", "LaneData",
    # PointLocation: keyed-group when compact (stride 0); when a schm defines a
    # stride (layers_static) it is a plain keyed-record numeric component.
    "PointLocation",
})

# Hash → component name lookup for compact-format info bodies (16-byte binary,
# no ASCII string). These are pandemic_hash_m2(component_name).
_ECS_COMP_HASH_TO_NAME: dict[int, str] = {
    0x753EB623: "Transform",
    0x1DE5C824: "Name",
    0x5CF81991: "ModelName",
    0x97E8EE92: "LightObject",
    0xEA0F3AA3: "Road",
    0x6FD048F4: "RoadIntersection",
    0xBCE6FAD7: "DestructionLink",
    0x7FBCE14E: "PhysicalLink",
    0xD81512A1: "ObjectScript",
    0x99C2B81F: "ModifierKey",
    0xAB92C697: "ScrubObject",
    0x6310807F: "LineRegion",
    0x49F0D0EC: "MaterialMapping",
    0x2A20B640: "LandingZone",
    0x06DA8775: "Label",
    0xFA55F6BA: "Anchor",
    0x2D8D2435: "LowResTerrainObject",
    0xE18AFD65: "HibernationControl",
    0xB8D2B506: "AtmosphereBase",
    0xEB6DE962: "IntersectionToIntersection",
    0x514CAD3A: "SoundAmbience",
    0xDECD8889: "AiBehavior",
    0xBCFE6314: "Path",
    0x6FA2F9D4: "LaneData",
    0x60B7ABE0: "PointLocation",
}

# "Keyed-group" ECS components: their ``data`` body is a sequence of
#   [u32 count][count × record][u8 flag]
# groups (NOT a flat u32 array). The per-group trailing u8 flag is why the
# body is not u32-aligned, so a blanket u32 swap corrupts everything after the
# first flag (the mixed u8/u32 pitfall in AGENTS.md). Each record is composed
# of ``record_size`` bytes of u32/f32 fields (byte-reversed individually); the
# u8 flag is copied verbatim. Verified by exact-consumption parse of the DLC
# resident META block (PointLocation: 1 group of 36-byte records; 0x2E2659F0:
# 26 groups of 4-byte entity-reference keys). Keyed by component name so both
# the named (PointLocation) and hash-only (0x2E2659F0) forms resolve.
_ECS_GROUP_RECORD_COMPONENTS: dict[str, int] = {
    "PointLocation": 36,
    "__hash_0x2E2659F0": 4,
}

# Full record strides for compact-format COMP groups (no schm): 4 + payload_stride.
# See docs/ecs_components.md (schm[4:8] is payload-only; Transform is always 42).
_ECS_COMP_DEFAULT_STRIDE: dict[str, int] = {
    "Transform": 42,
    "HibernationControl": 10,
    "Label": 8,
    "ScrubObject": 8,
    "LineRegion": 8,
    "Road": 44,
    "RoadIntersection": 128,
    "ObjectScript": 12,
    "Anchor": 20,
    "AiBehavior": 52,
    "SoundAmbience": 24,
    "AtmosphereBase": 744,
    "IntersectionToIntersection": 12,
    "LightObject": 56,
    "DestructionLink": 20,
    "PhysicalLink": 20,
    "ModifierKey": 12,
    "MaterialMapping": 8,
    "LandingZone": 8,
    "LowResTerrainObject": 12,
    "Path": 8,
    "LaneData": 8,
}


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


def _convert_keyed_group_records(body_be: bytes, record_size: int) -> bytes:
    """Convert a 'keyed-group' ECS component body (BE -> LE).

    Layout: a sequence of ``[u32 count][count × record][u8 flag]`` groups
    until the body is exhausted. Each record is ``record_size`` bytes of
    u32/f32 fields (byte-reversed individually); the per-group trailing u8
    flag is copied verbatim.

    Self-validating: the parse must consume the body *exactly*. If the record
    size / group layout assumption is wrong the structure won't line up, and
    we raise ``UnhandledByteSwapError`` rather than emit a corrupt buffer
    (per the no-silent-corruption byte-swap policy).
    """
    if record_size <= 0 or record_size % 4 != 0:
        raise UnhandledByteSwapError(
            f"keyed-group record_size {record_size} is not a positive multiple of 4"
        )
    out = bytearray()
    pos = 0
    n = len(body_be)
    while pos < n:
        if pos + 4 > n:
            raise UnhandledByteSwapError(
                f"keyed-group: {n - pos} dangling byte(s) before a group count"
            )
        count = struct.unpack_from(">I", body_be, pos)[0]
        out += struct.pack("<I", count)
        pos += 4
        span = count * record_size
        if span < 0 or pos + span + 1 > n:
            raise UnhandledByteSwapError(
                f"keyed-group: group count={count} (record_size={record_size}) "
                f"overruns body ({pos}+{span}+1 > {n})"
            )
        for off in range(pos, pos + span, 4):
            out += struct.pack("<I", struct.unpack_from(">I", body_be, off)[0])
        pos += span
        out += body_be[pos:pos + 1]  # per-group u8 flag, endian-neutral
        pos += 1
    if pos != n:
        raise UnhandledByteSwapError(
            f"keyed-group: consumed {pos} bytes != body length {n}"
        )
    return bytes(out)


def _is_ecs_name_identifier(candidate: bytes) -> bool:
    """True if *candidate* looks like a full-format ECS component name.

    Real component names are C++-style identifiers (``Transform``, ``ModelName``,
    ``PhysicalLink``, …): they start with a letter/underscore and contain only
    ``[A-Za-z0-9_]``. This rejects compact 4-byte BE hashes that happen to be
    printable but contain punctuation (e.g. ``b"N+lT"``, ``b"iV~b"``), which must
    be treated as hashes, not names. Require length >= 2 to avoid 1-char noise.
    """
    if len(candidate) < 2:
        return False
    first = candidate[0]
    if not ((0x41 <= first <= 0x5A) or (0x61 <= first <= 0x7A) or first == 0x5F):
        return False
    return all(
        (0x41 <= b <= 0x5A) or (0x61 <= b <= 0x7A) or (0x30 <= b <= 0x39) or b == 0x5F
        for b in candidate
    )


def _build_ecs_comp_map(
    descriptors: list[tuple[str, int, int, int, int]],
    container_be: bytes,
    data_area_off: int,
) -> dict[int, _CompInfo]:
    """Pre-scan ECS_NODE descriptors to map each ``data`` row to its COMP component.

    Walks the descriptor table recognizing the repeating pattern:
        COMP (sentinel) -> info -> schm -> data
    Reads the ``info`` body to extract the component name (null-terminated
    ASCII string) and the ``schm`` body to extract the record stride
    (second u32 in the schema header, in BE).

    Returns ``{descriptor_index: _CompInfo}`` for each ``data`` row that
    belongs to a recognized COMP group.
    """
    comp_map: dict[int, _CompInfo] = {}
    in_comp = False
    current_name: str | None = None
    current_stride: int = 0

    for idx, (tag, row_u0, body_size, _f3, _f4) in enumerate(descriptors):
        if row_u0 == CONTAINER_SENTINEL:
            if tag == "COMP":
                in_comp = True
                current_name = None
                current_stride = 0
            else:
                in_comp = False
            continue

        if not in_comp:
            continue

        body_start = (data_area_off + row_u0) if data_area_off > 0 else (8 + row_u0)
        body_end = min(body_start + body_size, len(container_be))
        if body_start >= len(container_be) or body_size == 0:
            continue
        body = container_be[body_start:body_end]

        if tag == "info" and current_name is None:
            # Two info body formats:
            # 1) Full: "ComponentName\0" + hash(4) + metadata (size > 16, starts with ASCII)
            # 2) Compact: hash(4 BE) + metadata (exactly 16 bytes, binary)
            #
            # The discriminator must NOT assume "first bytes printable => name":
            # a compact 4-byte BE hash can be coincidentally printable (e.g.
            # 0x4E2B6C54 = b"N+lT", 0x69567E62 = b"iV~b" in the DLC resident
            # block). Resolve in priority order: (a) recognized hash, (b) a
            # candidate that is a *valid identifier* (real component names are
            # C++-style identifiers — no '+', '~', etc.), else (c) compact hash.
            nul = body.find(b"\x00")
            candidate = body[:nul] if nul > 0 else b""
            comp_hash = struct.unpack_from(">I", body, 0)[0] if len(body) >= 4 else 0
            if comp_hash in _ECS_COMP_HASH_TO_NAME:
                # Compact format with a recognized hash (even if printable).
                current_name = _ECS_COMP_HASH_TO_NAME[comp_hash]
                if current_name in _ECS_COMP_DEFAULT_STRIDE:
                    current_stride = _ECS_COMP_DEFAULT_STRIDE[current_name]
            elif _is_ecs_name_identifier(candidate):
                # Full format: name string at start.
                current_name = candidate.decode("ascii")
            elif len(body) >= 4:
                # Compact format: unrecognized component hash.
                current_name = f"__hash_0x{comp_hash:08X}"
                if current_name in _ECS_COMP_DEFAULT_STRIDE:
                    current_stride = _ECS_COMP_DEFAULT_STRIDE[current_name]

        elif tag == "schm" and len(body) >= 8:
            payload_stride = struct.unpack_from(">I", body, 4)[0]
            if current_name == "Transform":
                current_stride = 42
            else:
                current_stride = 4 + payload_stride

        elif tag == "data" and current_name is not None:
            comp_map[idx] = _CompInfo(
                component_name=current_name,
                schema_stride=current_stride,
            )

    return comp_map


def _convert_ecs_comp_data(
    body_be: bytes,
    comp_info: _CompInfo,
    stats: dict,
    *,
    permissive: bool = False,
) -> bytes:
    """Convert an ECS_NODE COMP ``data`` body using structural component dispatch.

    Uses the component name from the preceding ``info`` descriptor to choose
    the correct byte-swap strategy instead of the old ``body_size % 42``
    heuristic.
    """
    if len(body_be) == 0:
        return body_be

    name = comp_info.component_name
    stride = comp_info.schema_stride

    # Keyed-group layout only applies to the compact/no-schm form (resident /
    # worldentity META, stride == 0). When a schm is present (layers_static)
    # the same component uses the standard keyed-record format, so fall through.
    if name in _ECS_GROUP_RECORD_COMPONENTS and stride == 0:
        return _convert_keyed_group_records(
            body_be, _ECS_GROUP_RECORD_COMPONENTS[name]
        )

    if name == "Transform":
        if len(body_be) % 42 != 0:
            raise UnhandledByteSwapError(
                f"Transform data body size {len(body_be)} is not a multiple of 42 "
                f"(schm/compact stride={stride})"
            )
        return _convert_transform_records(body_be)

    if name == "ModelName":
        # ModelName is a pure-u32 stream. The fixed-pair (key, hash) layout is
        # only one shape; the resident/worldentity META block uses variable
        # records ([u32 count][count×u32 keys][u32 model_hash], repeated), which
        # is u32- but not 8-aligned. Every field is a u32 either way, so a
        # u32-array swap is byte-for-byte identical to the pair logic. Require
        # u32 alignment only.
        if len(body_be) % 4 != 0:
            raise UnhandledByteSwapError(
                f"ModelName data body size {len(body_be)} is not a multiple of 4"
            )
        return _convert_u32_array(body_be)

    if name in _ECS_STRING_COMPONENTS:
        return body_be

    if name == "HibernationControl" and len(body_be) % 10 == 0:
        # Sub-u32 layout (u16 + u8 + u8 + u8 + bitflags); a numeric u32 sweep
        # would corrupt the u16. Always stride 10 (schm payload 6 / compact).
        return _convert_hibernation_records(body_be)

    if name in _ECS_NUMERIC_COMPONENTS:
        if stride > 0 and stride % 4 != 0:
            return _convert_numeric_records(body_be, stride)
        return _convert_u32_array(body_be)

    # Unrecognized hash-identified components: swap as numeric if stride known
    if name.startswith("__hash_0x"):
        if stride > 0 and stride % 4 != 0:
            return _convert_numeric_records(body_be, stride)
        if len(body_be) % 4 == 0:
            return _convert_u32_array(body_be)
        return _fallback_u32_or_raise(
            body_be,
            reason=f"unknown ECS component hash '{name}' (stride={stride}, size={len(body_be)} not u32-aligned)",
            tag="data",
            type_hash=_TYPE_ECS_NODE,
            context="META",
            permissive=permissive,
            stats=stats,
        )

    return _fallback_u32_or_raise(
        body_be,
        reason=f"unknown ECS component '{name}' (stride={stride})",
        tag="data",
        type_hash=_TYPE_ECS_NODE,
        context="META",
        permissive=permissive,
        stats=stats,
    )


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
_TYPE_LOW_RES_TERRAIN = 0x1602815C  # pandemic_hash_m2("lowresterrain")
_TYPE_EFFECT = 0x5608BD5A
_TYPE_OBJECT_REGISTRY = 0x6310807F  # resident entity-class registry (ASET type_id 30)
_TYPE_CFX_PACK = 0xFE0E8320  # CFX header + zlib (fonts, effects, resident sub-assets)
_TYPE_LEVEL = 0xEA4829D5
_TYPE_LAYER = 0x5647C35D  # worldentity / terrainfade META (type_id 8)
_TYPE_GUIDMAP = 0x140E8728  # pandemic_hash_m2("guidmap") — resident singleton (type_id 10)
_TYPE_RESIDENT_MISC = 0xFA0B8DBC  # resident-only blobs (ASET type_id 18, 22 entries)

# UCFX layouts using CHDR / enum / COMP / flgs (same family as layers_static / worldentity).
_ECS_STRUCTURE_TYPES = frozenset({
    _TYPE_ECS_NODE,
    _TYPE_LAYER,
    _TYPE_GUIDMAP,
})
_TYPE_MATERIALTABLE = 0x59B9DF6A  # materialtable singleton (resident)
_TYPE_UNKNOWN_DE = 0xDE982D61  # resident INFO (ASET type_id 14)

# Mesh types share identical sub-chunk formats
_MESH_TYPES = {_TYPE_MESH_A, _TYPE_MESH_B, _TYPE_MESH_C}
_AUDIO_TYPES = {_TYPE_UNKNOWN_E5, _TYPE_WAVEBANK, _TYPE_SOUNDBANK}
_SOUNDBANK_WAVEBANK_TYPES = {_TYPE_WAVEBANK, _TYPE_SOUNDBANK}

# Types whose data bodies are verified pure u32/f32-aligned from cross-platform evidence.
_U32_DATA_TYPES = (
    _MESH_TYPES |
    {
        _TYPE_UNKNOWN_E5,  # Audio group descriptor — has own converter but INFO is u32
        _TYPE_LOW_RES_TERRAIN, _TYPE_EFFECT, _TYPE_PATH,
        _TYPE_RESIDENT_MISC,  # verified pure u32/f32 from DLC block 464 analysis
    }
)

# Types whose INFO is u32 but only exist in the resident block (never in DLC).
# If encountered during DLC port, raise rather than blindly swapping.
_RESIDENT_ONLY_TYPES = {
    _TYPE_STANCE, _TYPE_STATE_MACHINE, _TYPE_LEVEL, _TYPE_LAYER,
    _TYPE_MATERIALTABLE, _TYPE_UNKNOWN_DE,
}

# Combined set for INFO tag dispatch (all are u32-safe for INFO bodies).
_U32_INFO_TYPES = _U32_DATA_TYPES | _RESIDENT_ONLY_TYPES | _AUDIO_TYPES


def _swap_chdr_header(header_be: bytes) -> bytes:
    """Byte-swap the CHDR 8-byte header as ``{ u16 @+0 ; u16 @+2 ; u32 @+4 }``.

    The engine chunk dispatcher (0x654940) reads the CHDR body as two ``u16``
    fields followed by a ``u32`` flags word — it is a single generic reader, so
    every CHDR header has this layout regardless of total body size.  The
    ``u16 @ +2`` is written to the process-global stride gate ``[0x01176078]``;
    the Transform record builder (0x0063D7C0) strides 42 only when that value is
    ``>= 0x2A``, otherwise 40 (it skips the 2-byte flags trailer).  Reversing the
    first 8 bytes as two ``u32`` words *transposes* the two ``u16`` fields,
    zeroing the gate → 40-byte strides → cumulative 2-byte/record drift →
    record-1 garbage position → unclamped spatial-hash cell → access violation on
    save-load.  See docs/spatial_hash_crash_analysis.md.

    Swaps only the bytes that are present (handles short < 8-byte headers
    gracefully); callers convert any bytes beyond +8 themselves.
    """
    out = bytearray(header_be[:8])
    if len(out) >= 2:
        out[0:2] = out[0:2][::-1]
    if len(out) >= 4:
        out[2:4] = out[2:4][::-1]
    if len(out) >= 8:
        out[4:8] = out[4:8][::-1]
    return bytes(out)


def _convert_chdr_body(
    body_be: bytes,
    *,
    type_hash: int,
    context: str | None,
) -> bytes:
    """Convert CHDR chunk body.

    Verified ECS containers use an 8-byte CHDR payload (zero + num_chunks;
    see docs/vz_state_analysis.md §2.3).  The UCFX descriptor row can still
    advertise a very large ``body_size`` (e.g. guidmap ~59 KiB) because the
    chunk-table region is also reached via sibling enum/COMP/flgs descriptors.
    Only the first 8 bytes are CHDR-specific scalars; the remainder must not
    be blind u32-swept.

    The 8-byte CHDR header is ``{ u16 @+0 ; u16 @+2 ; u32 @+4 }`` (see
    :func:`_swap_chdr_header`).  A whole-``u32`` swap of those 8 bytes was the
    root cause of the DLC spatial-hash save-load crash, so the header is swapped
    per-field in *every* branch; only the treatment of bytes beyond +8 differs.
    """
    if len(body_be) <= 16:
        if len(body_be) not in (0, 8, 12, 16) and len(body_be) % 4 != 0:
            raise UnhandledByteSwapError(
                f"CHDR body has unexpected size {len(body_be)} bytes "
                f"(not a multiple of 4); type_hash=0x{type_hash:08X}"
            )
        if len(body_be) == 0:
            return body_be
        out = bytearray(body_be)
        out[:8] = _swap_chdr_header(bytes(out[:8]))
        # Any words beyond the 8-byte header are plain u32 scalars.
        if len(out) > 8:
            out[8:] = _convert_u32_array(bytes(out[8:]))
        return bytes(out)
    if type_hash in _ECS_STRUCTURE_TYPES or context == "META":
        out = bytearray(body_be)
        out[:8] = _swap_chdr_header(bytes(out[:8]))
        return bytes(out)
    if len(body_be) % 4 != 0:
        raise UnhandledByteSwapError(
            f"CHDR body has unexpected size {len(body_be)} bytes "
            f"(not a multiple of 4); type_hash=0x{type_hash:08X}"
        )
    out = bytearray(body_be)
    out[:8] = _swap_chdr_header(bytes(out[:8]))
    out[8:] = _convert_u32_array(bytes(out[8:]))
    return bytes(out)


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
               [value_count × (null-terminated value name + u32 value_hash + u32 ordinal)]
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
        # Walk values: each is [name\0] [u32 hash] [u32 ordinal]
        for _ in range(val_count):
            if pos >= len(be):
                break
            nul = be.find(b"\x00", pos)
            if nul < 0:
                break
            pos = nul + 1
            if pos + 8 > len(be):
                break
            # Swap value_hash
            v = struct.unpack_from(">I", be, pos)[0]
            struct.pack_into("<I", out, pos, v)
            pos += 4
            # Swap ordinal
            v = struct.unpack_from(">I", be, pos)[0]
            struct.pack_into("<I", out, pos, v)
            pos += 4
    return bytes(out)


def _convert_schm_body(be: bytes) -> bytes:
    """Convert ecs_node 'schm' (schema) body from BE to LE.

    Layout (verified against retail PC ``layers_static`` / ``vz_mar_roads``):
      +0  u32 n_fields
      +4  u32 payload_stride
      +8  n_fields x 16-byte field entries:
            +0  u32 type_code
            +4  u32 name_hash
            +8  u32 unk (always 0)
            +12 field-offset word = { u16 byte_offset; u8 a; u8 b }

    The trailing 2 bytes of the offset word are endian-neutral u8 fields
    (bit index / size), NOT part of a u32. A full u32 byteswap moves the
    ``byte_offset`` into the HIGH 16 bits, whereas the engine (and every
    retail PC block) stores it in the LOW 16 bits. We therefore swap only
    the ``byte_offset`` u16 and copy the two trailing bytes verbatim.
    Confirmed: swap-first-u16 reproduces retail 47/47 (vz_mar_roads) and
    12/12 (layers_static); full u32 swap matches only zero-offset fields.
    """
    if len(be) < 8:
        return _convert_u32_array(be)
    n_fields = struct.unpack_from(">I", be, 0)[0]
    if n_fields > 200 or 8 + n_fields * 16 > len(be):
        # Not a recognizable field table — preserve legacy behaviour.
        return _convert_u32_array(be)
    out = bytearray()
    out += struct.pack("<I", n_fields)
    out += struct.pack("<I", struct.unpack_from(">I", be, 4)[0])  # payload_stride
    for fi in range(n_fields):
        eo = 8 + fi * 16
        type_code = struct.unpack_from(">I", be, eo)[0]
        name_hash = struct.unpack_from(">I", be, eo + 4)[0]
        unk = struct.unpack_from(">I", be, eo + 8)[0]
        out += struct.pack("<III", type_code, name_hash, unk)
        # offset word: BE bytes [b0,b1,b2,b3] -> LE [b1,b0,b2,b3]
        b0, b1, b2, b3 = be[eo + 12], be[eo + 13], be[eo + 14], be[eo + 15]
        out += bytes((b1, b0, b2, b3))
    tail = 8 + n_fields * 16
    if tail < len(be):
        out += be[tail:]  # no trailing bytes expected; copy verbatim if present
    return bytes(out)


# ── Audio type converters (mixed-endian) ─────────────────────────────

def _convert_object_registry_data(body_be: bytes) -> bytes:
    """Convert object/entity class registry records (resident block, ~88 B).

    Entries use type_hash ``0x6310807F`` (ASET type_id 30). Layout is hash/scalar
    fields only (no embedded strings in the 88-byte records we have seen).
    """
    return _convert_u32_array(body_be)


_ZLIB_CMFS = frozenset((0x01, 0x5E, 0x9C, 0xDA, 0x20, 0x7D, 0xBB, 0xFB))


def _find_zlib_offset(data: bytes, *, search_limit: int = 512) -> int:
    """Offset of zlib wrapper (0x78 cmf) in a CFX payload, or -1."""
    limit = min(len(data) - 2, search_limit)
    for i in range(limit):
        if data[i] == 0x78 and data[i + 1] in _ZLIB_CMFS:
            return i
    for i in range(search_limit, len(data) - 2):
        if data[i] == 0x78 and data[i + 1] in _ZLIB_CMFS:
            return i
    return -1


def _convert_cfx_compressed_data(body_be: bytes) -> bytes:
    """Convert CFX + zlib payloads (type_hash ``0xFE0E8320``, ASET type_id 23).

    BE u32 fields precede the zlib stream; the deflate bitstream is endian-neutral
    and is copied verbatim.
    """
    zoff = _find_zlib_offset(body_be)
    if zoff < 0:
        raise UnhandledByteSwapError(
            f"CFX body ({len(body_be)} bytes) contains no detectable zlib stream; "
            f"cannot determine field layout without structural evidence"
        )

    prefix_end = zoff - (zoff % 4)
    out = bytearray()
    if prefix_end > 0:
        out += _convert_u32_array(body_be[:prefix_end])
    if prefix_end < zoff:
        out += body_be[prefix_end:zoff]
    out += body_be[zoff:]
    return bytes(out)


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
        raise UnhandledByteSwapError(
            f"[Hatch 5] audio group descriptor (unknown_E5) body too short: "
            f"{len(body_be)} bytes (need 28)"
        )

    out = bytearray(body_be)

    # [0:4] count — already LE, do NOT swap
    # [4:8] self_hash — BE → LE
    struct.pack_into("<I", out, 4, struct.unpack_from(">I", body_be, 4)[0])
    # [8:10] sub_count — u16 BE → LE
    struct.pack_into("<H", out, 8, struct.unpack_from(">H", body_be, 8)[0])
    # [10:12] flags — u16 BE → LE
    struct.pack_into("<H", out, 10, struct.unpack_from(">H", body_be, 10)[0])
    # [12:16] u32 field — BE → LE (not padding on PC base game)
    if len(body_be) >= 16:
        struct.pack_into("<I", out, 12, struct.unpack_from(">I", body_be, 12)[0])
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
_WAVEBANK_RECORD_SIZE = 36


def _convert_wavebank_data(body_be: bytes) -> bytes:
    """Convert wavebank body from Xbox BE to PC LE format.

    Verified against 95 matched wavebanks across Xbox and PC base game WADs.

    Header (24 bytes):
      [0:4]    count            — u32 LE on BOTH platforms
      [4:8]    self_hash        — u32 (BE→LE swap)
      [8:10]   populated_count  — u16 (BE→LE swap)
      [10:12]  more_flags       — u16 (BE→LE swap)
      [12:16]  self_hash2       — u32 (BE→LE swap)
      [16:20]  records_offset   — u32 (BE→LE swap; always 24 on both)
      [20:24]  padding          — zeros

    Per record (36 bytes):
      [0:4]    clip_hash        — u32 (BE→LE swap)
      [4:8]    format_bytes     — u8×4 (no swap; byte[2] codec: 0x05→0x02)
      [8:12]   sample_rate      — u32 (BE→LE swap)
      [12:16]  data_offset      — u32 body-absolute; recomputed after transcode
      [16:20]  data_size         — u32 recomputed from transcoded clip length
      [20:32]  extra_fields     — 3 × u32 (zero for mono clips, nonzero for stereo/streaming)
      [32:36]  field_32         — u32 (BE→LE swap; verified from cross-platform diff)

    Audio data follows the record area. data_offset values are absolute
    byte offsets from body[0]. Xbox ADPCM (codec 0x05) clips are transcoded
    to PC IMA ADPCM (codec 0x02) using nibble swap; sizes change slightly.
    Offsets and sizes must be recomputed to point into the new PC audio blob.

    Streaming wavebanks (body < 1 KB, offsets >> body size) have their
    offsets preserved as-is since they reference external PWS data.
    """
    if len(body_be) < 24:
        raise UnhandledByteSwapError(
            f"[Hatch 3] wavebank body too short for header: "
            f"{len(body_be)} bytes (need 24)"
        )

    count = struct.unpack_from("<I", body_be, 0)[0]
    self_hash = struct.unpack_from(">I", body_be, 4)[0]
    populated_count = struct.unpack_from(">H", body_be, 8)[0]
    more_flags = struct.unpack_from(">H", body_be, 10)[0]
    self_hash2 = struct.unpack_from(">I", body_be, 12)[0]
    xbox_records_offset = struct.unpack_from(">I", body_be, 16)[0]

    if count > 10000:
        raise UnhandledByteSwapError(
            f"[Hatch 3] wavebank record count implausible: {count} (max 10000)"
        )
    if xbox_records_offset > len(body_be):
        raise UnhandledByteSwapError(
            f"[Hatch 3] wavebank records_offset {xbox_records_offset} exceeds "
            f"body length {len(body_be)}"
        )

    pop = min(populated_count, count) if populated_count > 0 else count
    pc_records_offset = 24

    # Parse Xbox records
    xbox_records = []
    for i in range(count):
        roff = xbox_records_offset + i * _WAVEBANK_RECORD_SIZE
        if roff + _WAVEBANK_RECORD_SIZE > len(body_be):
            break
        clip_hash = struct.unpack_from(">I", body_be, roff)[0]
        fmt_bytes = bytearray(body_be[roff + 4:roff + 8])
        sample_rate = struct.unpack_from(">I", body_be, roff + 8)[0]
        data_offset = struct.unpack_from(">I", body_be, roff + 12)[0]
        data_size = struct.unpack_from(">I", body_be, roff + 16)[0]
        extra_20_28 = body_be[roff + 20:roff + 32]
        field_32 = struct.unpack_from(">I", body_be, roff + 32)[0]
        xbox_records.append({
            "clip_hash": clip_hash,
            "fmt_bytes": fmt_bytes,
            "sample_rate": sample_rate,
            "data_offset": data_offset,
            "data_size": data_size,
            "extra_20_28": extra_20_28,
            "field_32": field_32,
            "index": i,
        })

    # Transcode each populated clip's audio data and build new audio blob.
    # Sort populated clips by Xbox offset to preserve layout order.
    # Per-clip decision: if offset+size fits within Xbox body, transcode and
    # repack into the new PC blob. Otherwise the clip references external
    # streaming data (PWS) — preserve its offset and size as-is.
    populated = [r for r in xbox_records[:pop] if r["data_size"] > 0]
    populated.sort(key=lambda r: r["data_offset"])

    pc_audio_blob = bytearray()
    pc_audio_start = pc_records_offset + count * _WAVEBANK_RECORD_SIZE
    new_offsets: dict[int, tuple[int, int]] = {}
    codec_rewrite_indices: set[int] = set()

    for rec in populated:
        xbox_off = rec["data_offset"]
        xbox_sz = rec["data_size"]

        if xbox_off + xbox_sz > len(body_be):
            # Hatch 1: streaming reference — audio lives in external PWS file,
            # not in the wavebank body. Adjust offset by PC_PWS_HEADER_SIZE
            # because Xbox PWS is headerless but PC PWS has a 4-byte header.
            new_offsets[rec["index"]] = (xbox_off + PC_PWS_HEADER_SIZE, xbox_sz)
            codec_rewrite_indices.add(rec["index"])
            continue

        xbox_clip = body_be[xbox_off:xbox_off + xbox_sz]
        channels = rec["fmt_bytes"][1] if rec["fmt_bytes"][1] > 0 else 1
        codec = rec["fmt_bytes"][2]

        pc_clip, _new_codec = normalize_embedded_wavebank_clip(
            bytes(xbox_clip), codec, channels,
        )

        pc_offset = pc_audio_start + len(pc_audio_blob)
        pc_size = len(pc_clip)
        new_offsets[rec["index"]] = (pc_offset, pc_size)
        codec_rewrite_indices.add(rec["index"])
        pc_audio_blob.extend(pc_clip)

    # Build PC output
    out = bytearray()

    # Header (24 bytes)
    out += struct.pack("<I", count)
    out += struct.pack("<I", self_hash)
    out += struct.pack("<H", populated_count)
    out += struct.pack("<H", more_flags)
    out += struct.pack("<I", self_hash2)
    out += struct.pack("<I", pc_records_offset)
    out += b"\x00" * 4

    # Records
    for i, rec in enumerate(xbox_records):
        out += struct.pack("<I", rec["clip_hash"])
        pc_fmt = bytearray(rec["fmt_bytes"])
        if i in codec_rewrite_indices and pc_fmt[2] in (_XBOX_ADPCM_CODEC, 0x01, 0x69):
            pc_fmt[2] = _PC_IMA_ADPCM_CODEC
        out += bytes(pc_fmt)
        out += struct.pack("<I", rec["sample_rate"])

        if i in new_offsets:
            pc_off, pc_sz = new_offsets[i]
            out += struct.pack("<I", pc_off)
            out += struct.pack("<I", pc_sz)
        elif i < pop and rec["data_size"] == 0:
            out += struct.pack("<I", 0)
            out += struct.pack("<I", 0)
        else:
            out += struct.pack("<I", 0)
            out += struct.pack("<I", 0)

        # extra_20_28: 12 bytes — swap each u32 within
        e = rec["extra_20_28"]
        for j in range(0, 12, 4):
            val = struct.unpack_from(">I", e, j)[0]
            out += struct.pack("<I", val)
        # field_32: verified as u32 endian swap from cross-platform diff (95 matched
        # entries). The value differs semantically between platforms but byte order
        # still follows the platform's native endianness.
        out += struct.pack("<I", rec["field_32"])

    # Audio blob
    out += bytes(pc_audio_blob)

    return bytes(out)


# Body offsets containing u8x4 (flag/config) bytes that must NOT be swapped.
#
# Derived from aggregate cross-platform comparison of 9 matched Xbox vs PC
# soundbank entries using tools/_wad_audio_compare.py.  Each 4-byte-aligned
# offset in the body was classified by comparing the Xbox (BE) and PC (LE)
# bytes: u32/f32 fields show reversed bytes, u8x4 fields are identical, and
# u16x2 fields show per-u16 swaps.
#
# Coverage: body offsets 0x20–0xFF (first 256 bytes).  Beyond 0xFF, the
# comparison aggregate does not extend; those offsets default to u32 swap
# (u32+f32 cover ~64% of all soundbank fields, zero ~23% is unaffected).
#
# The soundbank body has four sections delineated by header offsets:
#   Section 1 [data_start, section_off1):  per-sound record data (mixed types)
#   Section 2 [section_off1, section_off2): sub_count × u32 index values
#   Section 3 [section_off2, section_off3): per-sound parameter data (mixed)
#   Section 4 [section_off3, end):          sub_count2 × u32 index values
#
# Sections 2 and 4 are confirmed pure u32 arrays (all entries consistent).
# Sections 1 and 3 contain the u8x4 flag fields that caused the crash in
# PalSoundEngine::MixSources when blindly byte-swapped.
#
# Mixed fields (~0.2%, all in section 3) are platform-specific audio
# parameters; they get u32-swapped which may produce slightly wrong values,
# but the engine tolerates this far better than corrupted flag bytes.
# Relative to each record start within section A/C (see docs/pandemic_audio_system_design.md
# §4.2: absolute 0x2C/0x34/0x4C/0xA0/0xA8/0xC0 with 0x20-byte record header).
_SOUNDBANK_U8X4_RECORD_RELATIVE = frozenset({
    12,   # 0x0C — codec/channel flags (u8x4)
    20,   # 0x14 — playback flags (u8x4)
    44,   # 0x2C — effect/routing flags (u8x4)
    128,  # 0x80
    136,  # 0x88
    160,  # 0xA0
})


def _convert_soundbank_data(body_be: bytes) -> bytes:
    """Convert soundbank body from Xbox to PC format.

    Header layout (32 bytes, verified against 76 base game PC soundbanks):
      [0:4]    count        — u32 LE (same on both platforms; always 0x1D=29)
      [4:8]    self_hash    — u32 BE
      [8:10]   sub_count    — u16 BE (entry/group count; base range 1–172)
      [10:12]  sub_count2   — u16 BE (second count; base range 1–185)
      [12:16]  self_hash2   — u32 BE (duplicate of self_hash)
      [16:20]  data_start   — u32 BE (= 0x20 = 32 consistently)
      [20:24]  section_off1 — u32 BE (offset to section table 1)
      [24:28]  section_off2 — u32 BE (offset to section table 2)
      [28:32]  section_off3 — u32 BE (offset to section table 3)

    Sections 1 and 3 contain per-sound records of
    ``(section_off1 - data_start) / sub_count`` bytes each (section C uses
    ``sub_count2``).
    Each record has u8x4 flag fields at fixed relative offsets (codec/channel
    flags, playback flags, effect/routing flags).  These must NOT be
    byte-swapped.  Sections 2 and 4 are pure u32 index tables.

    The u8x4 field positions were derived from cross-platform comparison of
    all 76 soundbank entries between Xbox 360 and PC base game WADs
    (tools/_wad_audio_compare.py).  Relative offsets within each record:
    12 (field 3), 20 (field 5), 44 (field 11).  These are applied
    periodically to every record in sections 1 and 3.
    """
    if len(body_be) < 32:
        raise UnhandledByteSwapError(
            f"[Hatch 4] soundbank body too short for header: "
            f"{len(body_be)} bytes (need 32)"
        )

    out = bytearray(body_be)

    # Parse header BE values before overwriting
    # [0:4] is u8×4 format/version (e.g. 0x1D) — already LE, not a record count.
    data_start = struct.unpack_from(">I", body_be, 16)[0]
    section_off1 = struct.unpack_from(">I", body_be, 20)[0]
    section_off2 = struct.unpack_from(">I", body_be, 24)[0]
    section_off3 = struct.unpack_from(">I", body_be, 28)[0]
    sub_count = struct.unpack_from(">H", body_be, 8)[0]
    sub_count2 = struct.unpack_from(">H", body_be, 10)[0]

    # Validate section offsets; fall back to header-only swap if nonsensical
    body_len = len(body_be)
    sections_valid = (
        data_start <= section_off1 <= section_off2
        <= section_off3 <= body_len
        and data_start >= 32
    )

    record_stride_a = 4
    record_stride_c = 4
    if sections_valid:
        sec_a = section_off1 - data_start
        if sub_count > 0 and sec_a > 0 and sec_a % sub_count == 0:
            record_stride_a = sec_a // sub_count
        sec_c = section_off3 - section_off2
        if sub_count2 > 0 and sec_c > 0 and sec_c % sub_count2 == 0:
            record_stride_c = sec_c // sub_count2

    # ── Header (32 bytes): typed conversion ──
    # [0:4] count — already LE, do NOT swap
    struct.pack_into("<I", out, 4, struct.unpack_from(">I", body_be, 4)[0])
    struct.pack_into("<H", out, 8, struct.unpack_from(">H", body_be, 8)[0])
    struct.pack_into("<H", out, 10, struct.unpack_from(">H", body_be, 10)[0])
    struct.pack_into("<I", out, 12, struct.unpack_from(">I", body_be, 12)[0])
    struct.pack_into("<I", out, 16, data_start)
    struct.pack_into("<I", out, 20, section_off1)
    struct.pack_into("<I", out, 24, section_off2)
    struct.pack_into("<I", out, 28, section_off3)

    # ── Body: per-offset typed conversion ──
    for off in range(data_start, body_len - 3, 4):
        if sections_valid and (
            section_off1 <= off < section_off2
            or off >= section_off3
        ):
            # Sections 2 and 4: pure u32 index tables — always swap
            struct.pack_into(
                "<I", out, off, struct.unpack_from(">I", body_be, off)[0],
            )
            continue

        # Sections 1 (data_start..section_off1) and 3 (section_off2..section_off3)
        # contain periodic records.  u8x4 flag fields at
        # _SOUNDBANK_U8X4_RECORD_RELATIVE must not be byte-swapped.
        if sections_valid:
            if off < section_off1:
                rel = (off - data_start) % record_stride_a
            elif section_off2 <= off < section_off3:
                rel = (off - section_off2) % record_stride_c
            else:
                rel = -1
            if rel in _SOUNDBANK_U8X4_RECORD_RELATIVE:
                continue

        # u32 / f32 field — standard 4-byte swap
        struct.pack_into(
            "<I", out, off, struct.unpack_from(">I", body_be, off)[0],
        )

    return bytes(out)


def _convert_body(
    tag: str,
    body_be: bytes,
    context: str | None,
    stats: dict,
    *,
    type_hash: int = 0,
    texture_fmt: bytes = b"DXT5",
    permissive: bool = False,
    comp_info: _CompInfo | None = None,
) -> bytes:
    """Convert a single chunk body from BE to LE based on tag, context, and entry type.

    Unhandled (tag, type_hash) pairs raise ``UnhandledByteSwapError`` unless
    *permissive* is True (testing only — applies blind u32 array swap).
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

    # ── flgs: format depends on type ──
    if tag == "flgs":
        if type_hash in _ECS_STRUCTURE_TYPES:
            return _convert_vz_state_flgs(body_be)
        if len(body_be) % 4 == 0:
            return _convert_u32_array(body_be)
        raise UnhandledByteSwapError(
            f"flgs body ({len(body_be)} bytes) for type_hash=0x{type_hash:08X} "
            f"is not u32-aligned and format is unknown"
        )

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
            return _convert_havok_be_to_le(body_be, permissive=permissive, stats=stats)
        if type_hash in _ECS_STRUCTURE_TYPES:
            if comp_info is not None:
                return _convert_ecs_comp_data(
                    body_be, comp_info, stats, permissive=permissive,
                )
            return _fallback_u32_or_raise(
                body_be,
                reason="ECS structure data outside COMP triplet (no component identity)",
                tag=tag,
                type_hash=type_hash,
                context=context,
                permissive=permissive,
                stats=stats,
            )
        if type_hash == _TYPE_KEYFRAME:
            return body_be  # Stringdb body is natively BE on all platforms
        if type_hash == _TYPE_PATH:
            return _convert_u16_array(body_be[:8]) + _convert_u32_array(body_be[8:])
        if type_hash == _TYPE_UNKNOWN_E5:
            return _convert_unknown_e5_data(body_be)
        if type_hash == _TYPE_WAVEBANK:
            return _convert_wavebank_data(body_be)
        if type_hash == _TYPE_SOUNDBANK:
            return _convert_soundbank_data(body_be)
        if type_hash == _TYPE_OBJECT_REGISTRY:
            return _convert_object_registry_data(body_be)
        if type_hash == _TYPE_CFX_PACK:
            return _convert_cfx_compressed_data(body_be)
        if type_hash in _U32_DATA_TYPES:
            return _convert_u32_array(body_be)
        if type_hash in _RESIDENT_ONLY_TYPES:
            raise UnhandledByteSwapError(
                f"Resident-only type 0x{type_hash:08X} encountered in data chunk "
                f"(body_size={len(body_be)}); this type should not appear in DLC blocks"
            )
        return _fallback_u32_or_raise(
            body_be,
            reason="unknown data chunk type_hash",
            tag=tag,
            type_hash=type_hash,
            context=context,
            permissive=permissive,
            stats=stats,
        )

    # ── info (lowercase): dispatch by type_hash ──
    if tag == "info":
        if type_hash == _TYPE_ANIMATION:
            return _convert_u16_array(body_be)
        if type_hash in _ECS_STRUCTURE_TYPES or context == "META":
            return _convert_ecs_info(body_be)
        if type_hash == _TYPE_LOW_RES_TERRAIN:
            return _convert_u32_array(body_be)
        if type_hash in _MESH_TYPES:
            return _convert_u32_array(body_be)
        return _fallback_u32_or_raise(
            body_be,
            reason="unknown info chunk type_hash",
            tag=tag,
            type_hash=type_hash,
            context=context,
            permissive=permissive,
            stats=stats,
        )

    # ── enum: dispatch by type_hash ──
    if tag == "enum":
        if type_hash in _ECS_STRUCTURE_TYPES or context == "META":
            return _convert_enum_body(body_be)
        return _fallback_u32_or_raise(
            body_be,
            reason="unknown enum chunk type_hash",
            tag=tag,
            type_hash=type_hash,
            context=context,
            permissive=permissive,
            stats=stats,
        )

    # ── flgt: u32 hash array (including under META/COMP) ──
    if tag == "flgt":
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
        if type_hash in _ECS_STRUCTURE_TYPES:
            return _convert_ecs_info(body_be)
        if type_hash == _TYPE_KEYFRAME:
            return body_be  # Stringdb INFO is natively BE on all platforms
        if type_hash == _TYPE_OBJECT_REGISTRY:
            return _convert_object_registry_data(body_be)
        if type_hash == _TYPE_CFX_PACK:
            return _convert_cfx_compressed_data(body_be)
        if type_hash in _U32_INFO_TYPES:
            return _convert_u32_array(body_be)
        return _fallback_u32_or_raise(
            body_be,
            reason="unknown INFO chunk type_hash",
            tag=tag,
            type_hash=type_hash,
            context=context,
            permissive=permissive,
            stats=stats,
        )

    # ── BODY (uppercase): dispatch by type_hash ──
    if tag == "BODY":
        if type_hash == _TYPE_TEXTURE:
            return _convert_dxt_body(body_be, texture_fmt)
        return _fallback_u32_or_raise(
            body_be,
            reason="unknown BODY chunk type_hash",
            tag=tag,
            type_hash=type_hash,
            context=context,
            permissive=permissive,
            stats=stats,
        )

    # ── STRS/KEYS: string table / u32 key arrays ──
    if tag == "STRS":
        return body_be
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

    # ── CHDR: 8-byte header scalars; large ECS bodies use sibling descriptors ──
    if tag == "CHDR":
        return _convert_chdr_body(body_be, type_hash=type_hash, context=context)

    # ── BNDS: axis-aligned bounds / sphere (10 × f32 in terrain tiles) ──
    if tag == "BNDS":
        return _convert_u32_array(body_be)

    # ── ATRB: effect attribute scalars (12 B typical) ──
    if tag == "ATRB":
        return _convert_u32_array(body_be)

    # ── TRFM: effect transform (particle blocks, 64 B typical) ──
    if tag == "TRFM":
        return _convert_u32_array(body_be)

    # ── Effect/particle tags (DLC effects block; u32 / f32-aligned) ──
    if tag in ("PTYP", "COLR", "TEXT", "FRCE", "ANIM", "AKEY"):
        return _convert_u32_array(body_be)

    # ── Animation manifest / metadata (resident stance entries) ──
    if tag in ("MANM", "TRCK", "DATA"):
        return _convert_u32_array(body_be)
    if tag == "MINF":
        if len(body_be) % 2 == 0:
            return _convert_u16_array(body_be)
        raise UnhandledByteSwapError(
            f"MINF body has odd size {len(body_be)} bytes (not u16-aligned); "
            f"type_hash=0x{type_hash:08X}"
        )

    # ── Resident singleton sub-tags (watr/tree, 1 entry each) ──
    if tag in ("watr", "tree", "UNIQ"):
        return _convert_u32_array(body_be)

    # ── Mesh structure tags with verified u32-only layouts ──
    if tag in ("PRMG", "GEOM", "POFF", "STAT", "SWIT",
               "NODE", "CEXE", "PHY2", "COMP", "TINY",
               "SCRB", "INST", "PTCH", "PTMS", "BSHP", "VALU"):
        return _convert_u32_array(body_be)

    stats["tags_seen"][tag] = stats["tags_seen"].get(tag, 0) + 1
    return _fallback_u32_or_raise(
        body_be,
        reason="unhandled chunk tag",
        tag=tag,
        type_hash=type_hash,
        context=context,
        permissive=permissive,
        stats=stats,
    )


# ── Container conversion ──────────────────────────────────────────────

def _convert_container(
    container_be: bytes,
    stats: dict,
    *,
    type_hash: int = 0,
    permissive: bool = False,
) -> bytes:
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
        if permissive:
            stats["container_corrupt_blind_sweep"] = (
                stats.get("container_corrupt_blind_sweep", 0) + 1
            )
            blind_detail = stats.setdefault("blind_swap_detail", [])
            blind_detail.append(
                f"BLIND_SWAP: implausible descriptor count {n_descriptors} "
                f"type_hash=0x{type_hash:08X} container_size={len(container_be)}"
            )
            return _convert_u32_array(container_be)
        raise UnhandledByteSwapError(
            f"Implausible UCFX descriptor count: {n_descriptors}"
        )

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

    # Build COMP component map for ECS_NODE containers so that each 'data'
    # descriptor is dispatched by component name instead of size heuristics.
    comp_map: dict[int, _CompInfo] = {}
    if type_hash in _ECS_STRUCTURE_TYPES:
        comp_map = _build_ecs_comp_map(descriptors, container_be, data_area_off)

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
            if body_size == 0:
                bodies_le.append(b"")
            elif permissive:
                stats["container_sentinel_blind_sweep"] = (
                    stats.get("container_sentinel_blind_sweep", 0) + 1
                )
                blind_detail = stats.setdefault("blind_swap_detail", [])
                blind_detail.append(
                    f"BLIND_SWAP: CONTAINER_SENTINEL tag={tag!r} "
                    f"type_hash=0x{type_hash:08X} body_size={body_size}"
                )
                bodies_le.append(_convert_u32_array(body_be))
            else:
                raise UnhandledByteSwapError(
                    f"CONTAINER_SENTINEL row for tag {tag!r} "
                    f"(type_hash=0x{type_hash:08X}) needs semantic handler"
                )
        else:
            bodies_le.append(
                _convert_body(
                    tag,
                    body_be,
                    contexts[idx],
                    stats,
                    type_hash=type_hash,
                    texture_fmt=texture_fmt,
                    permissive=permissive,
                    comp_info=comp_map.get(idx),
                )
            )

    # Serialize as LE
    out = bytearray()

    # Update descriptor body_size to actual converted lengths (all types).
    updated_descriptors = list(descriptors)
    for idx, (tag, row_u0, body_size, f3, f4) in enumerate(descriptors):
        if row_u0 == CONTAINER_SENTINEL:
            continue
        new_size = len(bodies_le[idx])
        if new_size != body_size:
            updated_descriptors[idx] = (tag, row_u0, new_size, f3, f4)

    # UCFX header
    out += b"UCFX"
    out += struct.pack("<IIII", data_area_off, u1, u2, n_descriptors)

    # Descriptor rows
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

    required_size = 0
    for _, row_u0, body_size, _, _ in updated_descriptors:
        if row_u0 == CONTAINER_SENTINEL:
            continue
        end = row_u0 + body_size
        if end > required_size:
            required_size = end

    body_area = bytearray(required_size)

    for idx, (_, row_u0, body_size, _, _) in enumerate(updated_descriptors):
        if row_u0 == CONTAINER_SENTINEL:
            continue
        body_le = bodies_le[idx]
        if row_u0 + len(body_le) <= len(body_area):
            body_area[row_u0:row_u0 + len(body_le)] = body_le

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
    *,
    permissive: bool = False,
    strip_type_hashes: frozenset[int] | None = None,
) -> tuple[bytes, dict]:
    """Convert a decompressed Xbox UCFX block to PC little-endian.

    Structurally parses the BE input and serializes fresh LE output.
    Returns (le_bytes, stats_dict).

    If *havok_overrides* is provided, it maps entry indices to already-correct
    LE UCFX container bytes (without CSUM).  Entries in the map bypass BE→LE
    conversion entirely — used to substitute base-game data for formats that
    cannot be field-level byte-swapped (Havok, textures, meshes, etc.).

    If *strip_type_hashes* is provided, entries whose type_hash is in the set
    AND which have no override in *havok_overrides* are dropped from the output
    block entirely (removed from both the entry table and the container data).
    Use this to strip audio entries that would crash PalSoundEngine.

    When an override or audio conversion produces output larger than the
    original Xbox entry slot, the entry table size field is expanded to
    accommodate it (the block is recompressed afterward so total size is
    unconstrained).
    """
    stats: dict = {
        "ucfx_found": 0, "chunks_swapped": 0, "csum_swapped": 0,
        "tags_seen": {}, "errors": [],
        "fallback_u32_count": 0, "fallback_u32_tags": {},
    }

    if len(block_data) < 4:
        return block_data, stats

    # Parse entry table
    entries = _parse_entry_table_be(block_data)
    header_end = 4 + len(entries) * 16

    # Phase 1: Convert all containers, collecting LE output bytes
    converted_containers: list[bytes | None] = []
    stripped_indices: set[int] = set()
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

        # Strip entry if its type is in the strip set and no override was found
        if strip_type_hashes and type_hash in strip_type_hashes:
            stripped_indices.add(entry_idx)
            converted_containers.append(None)
            stats.setdefault("stripped_count", 0)
            stats["stripped_count"] += 1
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
        ucfx_le = _convert_container(
            ucfx_be, stats, type_hash=type_hash, permissive=permissive,
        )
        stats["ucfx_found"] += 1

        # Recompute CSUM over the LE output
        csum_val = crc32_mercs2(ucfx_le)
        container_le = ucfx_le + b"CSUM" + struct.pack("<I", csum_val)
        stats["csum_swapped"] += 1

        converted_containers.append(container_le)
        pos += orig_size

    # Phase 2: Build entry table with actual output sizes, omitting stripped
    kept_entries: list[tuple[int, int, int, int]] = []
    kept_containers: list[bytes] = []
    for entry_idx, container_le in enumerate(converted_containers):
        if container_le is None:
            continue
        h, t, o, orig_size = entries[entry_idx]
        actual_size = len(container_le)
        kept_entries.append((h, t, o, actual_size))
        kept_containers.append(container_le)

    # Serialize entry table as LE with corrected sizes
    out = bytearray(_serialize_entry_table_le(kept_entries))

    # Phase 3: Append converted containers, padding to declared sizes
    for entry_idx, container_le in enumerate(kept_containers):
        declared_size = kept_entries[entry_idx][3]
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
