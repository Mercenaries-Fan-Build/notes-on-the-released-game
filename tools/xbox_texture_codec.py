#!/usr/bin/env python3
"""Xbox 360 texture surface untile + endian codec.

Solved against the base-game Rosetta corpus (every PC texture has an Xbox
counterpart): see `.cursor/notes/rosetta_oracle_baseline.md`.

Two transforms turn an Xbox 360 GPU texture surface into the PC linear layout:

  1. **Untile** — Xbox stores surfaces in a tiled/swizzled memory layout. The
     canonical block address swizzle is XGAddress2DTiledOffset (verified
     against Xenia `GetTiledOffset2D` and gildor's UEViewer untiler). Operates
     on texel *blocks* (4x4 for DXTn), width aligned up to 32 blocks.
  2. **Within-block endian** — Xbox DXT blocks store their 16-bit colour words
     (and DXT5 alpha endpoints) big-endian; PC is little-endian, so each 16-bit
     word inside every block is byte-swapped.

Block geometry:
  DXT1 -> 4x4 px, 8 bytes/block,  log2(bpb)=3
  DXT5 -> 4x4 px, 16 bytes/block, log2(bpb)=4
"""
from __future__ import annotations

import struct

_FORMAT = {
    b"DXT1": (4, 8, 3),
    b"DXT3": (4, 16, 4),
    b"DXT5": (4, 16, 4),
}


def tiled_block_index(x: int, y: int, width_blocks: int, log_bpb: int) -> int:
    """XGAddress2DTiledOffset returning a *block* index (gildor/Noesis form)."""
    aligned_w = (width_blocks + 31) & ~31
    macro = ((x >> 5) + (y >> 5) * (aligned_w >> 5)) << (log_bpb + 7)
    micro = ((x & 7) + ((y & 0xE) << 2)) << log_bpb
    offset = macro + ((micro & ~0xF) << 1) + (micro & 0xF) + ((y & 1) << 4)
    return ((((offset & ~0x1FF) << 3) + ((y & 16) << 7) + ((offset & 0x1C0) << 2)
             + (((((y & 8) >> 2) + (x >> 3)) & 3) << 6) + (offset & 0x3F))
            >> log_bpb)


def untile_surface(tiled: bytes, width_blocks: int, height_blocks: int,
                   texel_pitch: int, log_bpb: int) -> bytes:
    """Untile one mip surface (block granularity) to linear block order."""
    out = bytearray(width_blocks * height_blocks * texel_pitch)
    for j in range(height_blocks):
        row = j * width_blocks
        for i in range(width_blocks):
            ti = tiled_block_index(i, j, width_blocks, log_bpb)
            src = ti * texel_pitch
            if src + texel_pitch > len(tiled):
                continue
            dst = (row + i) * texel_pitch
            out[dst:dst + texel_pitch] = tiled[src:src + texel_pitch]
    return bytes(out)


def swap16_blocks(data: bytes) -> bytes:
    """Byte-swap every 16-bit word (Xbox DXT block words are big-endian)."""
    mv = bytearray(data)
    mv[0::2], mv[1::2] = data[1::2], data[0::2]
    return bytes(mv)


def convert_dxt_mip(tiled_mip: bytes, width_px: int, height_px: int,
                    fourcc: bytes, *, swap: bool = True) -> bytes:
    """Convert a single tiled DXT mip surface to PC linear, no width padding.

    The returned buffer is the *linear* surface for the (padded) block grid;
    callers crop to the original width when width is not a multiple of 32
    blocks (see untile note in UEViewer).
    """
    block_px, texel_pitch, log_bpb = _FORMAT[fourcc]
    wb = max(1, (width_px + block_px - 1) // block_px)
    hb = max(1, (height_px + block_px - 1) // block_px)
    aligned_wb = (wb + 31) & ~31
    aligned_hb = (hb + 31) & ~31
    linear = untile_surface(tiled_mip, aligned_wb, aligned_hb, texel_pitch, log_bpb)
    if swap:
        linear = swap16_blocks(linear)
    return linear, aligned_wb, aligned_hb, wb, hb, texel_pitch


def mip_levels(width_px: int, height_px: int) -> int:
    """Number of mip levels in a full chain down to 1x1."""
    return max(width_px, height_px).bit_length()


def linear_mip_chain_size(width_px: int, height_px: int, fourcc: bytes,
                          mips: int) -> int:
    """Total bytes of a PC-linear DXT mip chain (no tile padding)."""
    block_px, texel_pitch, _ = _FORMAT[fourcc]
    total = 0
    for m in range(max(1, mips)):
        wpx = max(1, width_px >> m)
        hpx = max(1, height_px >> m)
        wb = max(1, (wpx + block_px - 1) // block_px)
        hb = max(1, (hpx + block_px - 1) // block_px)
        total += wb * hb * texel_pitch
    return total


# Xbox D3D format word low byte -> PC FourCC.
_FORMAT_BYTE_TO_FOURCC = {0x52: b"DXT1", 0x54: b"DXT5", 0x53: b"DXT3"}


def fourcc_from_xbox_format(info: bytes) -> bytes | None:
    """PC FourCC implied by the Xbox INFO GPU format word (INFO[14:18])."""
    if len(info) < 18:
        return None
    return _FORMAT_BYTE_TO_FOURCC.get(info[17])


def rebuild_texture_info(xbox_info: bytes, fourcc: bytes, mips: int,
                         linear_total: int) -> bytes:
    """Rebuild a 34-byte PC texture INFO from the Xbox INFO.

    Empirically derived from the Rosetta corpus (xbox-vz.wad vs vz.wad):
      * width/height (INFO[0:4]) are identical.
      * two u16 pairs are transposed: [4:6]<->[6:8] and [8:10]<->[10:12].
      * INFO[12:14] is copied.
      * the GPU format word [14:18] becomes the ASCII FourCC.
      * the LOD-bias float [18:22] is stored big-endian on Xbox -> reverse to LE.
      * total_size [22:26] is the Xbox tile-padded size -> recompute as the PC
        linear mip-chain size.
      * trailing descriptor [26:34] is a PC mip-residency / streaming descriptor
        and is NOT reconstructible from the Xbox source: across vz.wad PC uses
        a complex partial-residency form for ~72% of textures, the sentinel
        ``...FF FF`` for ~18%, and the mip mask ``2^mips-1`` for ~10% — the same
        geometry can carry any of them (it reflects PC build-time streaming
        choices). We emit the fully-resident sentinel ``00 00 00 00 00 00 FF FF``
        (a valid "no streaming" marker PC itself uses) so the ported texture
        loads standalone; this is the one field that may differ byte-for-byte
        from a given PC entry.
    """
    if len(xbox_info) < 34:
        raise ValueError(f"xbox INFO too short: {len(xbox_info)} bytes")
    x = xbox_info
    out = bytearray(34)
    out[0:4] = x[0:4]
    out[4:6] = x[6:8]
    out[6:8] = x[4:6]
    struct.pack_into("<H", out, 6, mips & 0xFFFF)
    # [8:10]<->[10:12] transpose; clear the Xbox 0x10 "tiled" flag bit (the PC
    # surface is linear after untiling).
    f8 = struct.unpack_from("<H", x, 10)[0] & ~0x10
    struct.pack_into("<H", out, 8, f8)
    out[10:12] = x[8:10]
    out[12:14] = x[12:14]
    out[14:18] = fourcc
    out[18:22] = x[18:22][::-1]
    struct.pack_into("<I", out, 22, linear_total)
    out[26:30] = b"\x00\x00\x00\x00"
    out[30:32] = b"\x00\x00"
    out[32:34] = b"\xff\xff"
    return bytes(out)


def untile_dxt_body(tiled: bytes, width_px: int, height_px: int, fourcc: bytes,
                    *, mips: int | None = None, swap: bool = True) -> bytes:
    """Assemble a full PC-linear DXT mip chain from a tiled Xbox BODY.

    Xbox stores each mip whose smaller side is >= 32 texels as its own tiled
    surface (block dims aligned up to 32), packed largest-first. All mips with
    a side < 32 texels are packed together into a single 32x32-block "mip tail"
    tile that immediately follows the last own-tile surface. Within the tail,
    a mip of block dims (wb, hb) sits at block coordinate (wb, 0) when wider
    than tall (horizontal packing) or (0, hb) otherwise -- empirically verified
    byte-exact against the PC ground truth for DXT1/DXT5 at 512/1024/2048.

    ``mips`` should be the texture's real mip count (from INFO); we never emit
    more mips than the source provides, and the PC chain often stops above 1x1.
    """
    block_px, texel_pitch, log_bpb = _FORMAT[fourcc]
    n = mips if mips else mip_levels(width_px, height_px)
    out = bytearray()
    pos = 0
    tail_lin: bytes | None = None
    for m in range(n):
        wpx = max(1, width_px >> m)
        hpx = max(1, height_px >> m)
        wb = max(1, (wpx + block_px - 1) // block_px)
        hb = max(1, (hpx + block_px - 1) // block_px)
        if min(wpx, hpx) >= 32:
            awb = (wb + 31) & ~31
            ahb = (hb + 31) & ~31
            size = awb * ahb * texel_pitch
            if pos + size > len(tiled):
                break
            lin = untile_surface(tiled[pos:pos + size], awb, ahb, texel_pitch, log_bpb)
            if swap:
                lin = swap16_blocks(lin)
            out += crop_blocks(lin, awb, wb, hb, texel_pitch)
            pos += size
        else:
            if tail_lin is None:
                size = 32 * 32 * texel_pitch
                if pos + size > len(tiled):
                    break
                tail_lin = untile_surface(tiled[pos:pos + size], 32, 32,
                                          texel_pitch, log_bpb)
                if swap:
                    tail_lin = swap16_blocks(tail_lin)
                pos += size
            bx, by = (wb, 0) if wb >= hb else (0, hb)
            row = bytearray()
            for r in range(hb):
                base = ((by + r) * 32 + bx) * texel_pitch
                row += tail_lin[base:base + wb * texel_pitch]
            out += bytes(row)
    return bytes(out)


def crop_blocks(linear: bytes, aligned_wb: int, wb: int, hb: int,
                texel_pitch: int) -> bytes:
    """Drop the 32-block width/height padding, yielding the wb x hb surface."""
    if aligned_wb == wb:
        return linear[:wb * hb * texel_pitch]
    out = bytearray(wb * hb * texel_pitch)
    for j in range(hb):
        s = j * aligned_wb * texel_pitch
        d = j * wb * texel_pitch
        out[d:d + wb * texel_pitch] = linear[s:s + wb * texel_pitch]
    return bytes(out)


def tiled_body_size(width_px: int, height_px: int, fourcc: bytes,
                    mips: int) -> int:
    """Bytes the Xbox tiled BODY occupies for a full (non-streamed) texture.

    Mirrors ``untile_dxt_body`` consumption: own tiles for mips >= 32 texels,
    plus one 32x32-block packed-tail tile if any sub-32 mips exist.
    """
    block_px, texel_pitch, _ = _FORMAT[fourcc]
    n = mips if mips else mip_levels(width_px, height_px)
    total = 0
    tail_added = False
    for m in range(n):
        wpx = max(1, width_px >> m)
        hpx = max(1, height_px >> m)
        if min(wpx, hpx) >= 32:
            wb = max(1, (wpx + block_px - 1) // block_px)
            hb = max(1, (hpx + block_px - 1) // block_px)
            awb = (wb + 31) & ~31
            ahb = (hb + 31) & ~31
            total += awb * ahb * texel_pitch
        elif not tail_added:
            total += 32 * 32 * texel_pitch
            tail_added = True
    return total


class UnsupportedTexture(Exception):
    """Raised when an Xbox texture entry can't be converted in full."""


def texture_geometry(xbox_info: bytes):
    """(fourcc, width, height, mips) from an Xbox texture INFO chunk.

    Returns ``None`` for non-DXT formats. Width/height/mips read as little
    endian (these sub-fields are LE even in the BE container); the mip count
    lives at INFO[4:6] on Xbox (it transposes to PC INFO[6:8]).
    """
    if len(xbox_info) < 34:
        return None
    fourcc = fourcc_from_xbox_format(xbox_info)
    if fourcc is None:
        return None
    width, height = struct.unpack_from("<HH", xbox_info, 0)
    mips = struct.unpack_from("<H", xbox_info, 4)[0]
    if not width or not height:
        return None
    if not mips:
        mips = mip_levels(width, height)
    return fourcc, width, height, mips


def single_mip_tiled_size(
    width_px: int, height_px: int, fourcc: bytes, mip: int
) -> tuple[int, int, int]:
    """Bytes for one tiled mip surface plus its pixel dimensions."""
    block_px, texel_pitch, _ = _FORMAT[fourcc]
    wpx = max(1, width_px >> mip)
    hpx = max(1, height_px >> mip)
    wb = max(1, (wpx + block_px - 1) // block_px)
    hb = max(1, (hpx + block_px - 1) // block_px)
    if min(wpx, hpx) >= 32:
        awb = (wb + 31) & ~31
        ahb = (hb + 31) & ~31
        return awb * ahb * texel_pitch, wpx, hpx
    return 32 * 32 * texel_pitch, wpx, hpx


def classify_tiled_body(
    width_px: int, height_px: int, fourcc: bytes, mips: int, body_len: int
) -> tuple[str, int]:
    """Classify a tiled BODY for untile strategy. Returns (kind, param)."""
    expect = tiled_body_size(width_px, height_px, fourcc, mips)
    if body_len >= expect:
        return "full", mips
    for n in range(mips, 0, -1):
        if tiled_body_size(width_px, height_px, fourcc, n) == body_len:
            return "prefix", n
    for m in range(mips):
        sz, _, _ = single_mip_tiled_size(width_px, height_px, fourcc, m)
        if sz == body_len:
            return "single", m
    _, texel_pitch, _ = _FORMAT[fourcc]
    tail = 32 * 32 * texel_pitch
    if body_len == tail:
        return "tail_page", 1
    if body_len == 2 * tail:
        return "tail_page", 2
    return "stream_page", body_len


def _untile_own_surface(
    tiled: bytes, width_px: int, height_px: int, fourcc: bytes, *, swap: bool = True
) -> bytes:
    block_px, texel_pitch, log_bpb = _FORMAT[fourcc]
    wb = max(1, (width_px + block_px - 1) // block_px)
    hb = max(1, (height_px + block_px - 1) // block_px)
    awb = (wb + 31) & ~31
    ahb = (hb + 31) & ~31
    need = awb * ahb * texel_pitch
    if len(tiled) < need:
        need = len(tiled)
        awb = 32
        ahb = max(1, need // (32 * texel_pitch))
    lin = untile_surface(tiled[:need], awb, ahb, texel_pitch, log_bpb)
    if swap:
        lin = swap16_blocks(lin)
    return crop_blocks(lin, awb, wb, hb, texel_pitch)


def untile_streaming_page(tiled: bytes, fourcc: bytes) -> tuple[bytes, int, int, int]:
    """Best-effort untile of a fixed-size streamed mip page (16384 / 32768 bytes).

    Returns (linear_body, width_px, height_px, mips).
    """
    block_px, texel_pitch, log_bpb = _FORMAT[fourcc]
    nblocks = len(tiled) // texel_pitch
    if fourcc == b"DXT5":
        if len(tiled) == 32 * 32 * texel_pitch:
            awb = ahb = 32
            wpx = hpx = 128
            mips = 1
        elif len(tiled) == 32 * 64 * texel_pitch:
            awb, ahb = 32, 64
            wpx, hpx = 128, 256
            mips = 1
        else:
            side = max(1, int((nblocks * block_px * block_px) ** 0.5))
            wpx = hpx = side
            awb = ahb = 32
            mips = 1
    else:
        if len(tiled) == 32 * 64 * texel_pitch:
            awb, ahb = 32, 64
            wpx, hpx = 128, 256
            mips = 1
        elif len(tiled) == 32 * 32 * texel_pitch:
            awb = ahb = 32
            wpx = hpx = 128
            mips = 1
        elif len(tiled) == 64 * 64 * texel_pitch:
            awb = ahb = 64
            wpx = hpx = 256
            mips = 1
        else:
            awb = 32
            ahb = max(1, nblocks // 32)
            wpx = awb * block_px
            hpx = ahb * block_px
            mips = 1
    lin = untile_surface(tiled, awb, ahb, texel_pitch, log_bpb)
    lin = swap16_blocks(lin)
    wb = max(1, (wpx + block_px - 1) // block_px)
    hb = max(1, (hpx + block_px - 1) // block_px)
    return crop_blocks(lin, awb, wb, hb, texel_pitch), wpx, hpx, mips


def untile_tail_page(
    tiled_page: bytes, width_px: int, height_px: int, fourcc: bytes, max_mips: int
) -> tuple[bytes, int]:
    """Extract sub-32 mips packed in one 32x32 tail tile. Returns (linear, resident_mips)."""
    block_px, texel_pitch, log_bpb = _FORMAT[fourcc]
    page_bytes = 32 * 32 * texel_pitch
    if len(tiled_page) < page_bytes:
        page_bytes = len(tiled_page)
    tail_lin = untile_surface(tiled_page[:page_bytes], 32, 32, texel_pitch, log_bpb)
    tail_lin = swap16_blocks(tail_lin)
    first_tail = max_mips
    for m in range(max_mips):
        if min(max(1, width_px >> m), max(1, height_px >> m)) < 32:
            first_tail = m
            break
    out = bytearray()
    for m in range(first_tail, max_mips):
        wpx = max(1, width_px >> m)
        hpx = max(1, height_px >> m)
        wb = max(1, (wpx + block_px - 1) // block_px)
        hb = max(1, (hpx + block_px - 1) // block_px)
        bx, by = (wb, 0) if wb >= hb else (0, hb)
        for r in range(hb):
            base = ((by + r) * 32 + bx) * texel_pitch
            out.extend(tail_lin[base : base + wb * texel_pitch])
    resident = max(1, max_mips - first_tail)
    return bytes(out), resident


def convert_streamed_texture(
    xi: bytes, body: bytes | None
) -> tuple[bytes, bytes | None]:
    """Convert a streamed/partial Xbox texture (INFO [, BODY]) to PC layout.

    Always rebuilds INFO with a PC FourCC and the fully-resident ``FF FF`` tail
    so the engine does not enqueue an unsatisfiable streaming request.
    """
    if len(xi) < 34:
        raise UnsupportedTexture(f"INFO too short: {len(xi)}")
    geom = texture_geometry(xi[:34])
    if geom is None:
        raise UnsupportedTexture("non-DXT INFO")
    fourcc, width, height, mips = geom

    if body is None or len(body) == 0:
        linear = linear_mip_chain_size(width, height, fourcc, mips)
        return rebuild_texture_info(xi[:34], fourcc, mips, linear), None

    kind, param = classify_tiled_body(width, height, fourcc, mips, len(body))
    if kind == "full":
        pc_body = untile_dxt_body(body, width, height, fourcc, mips=mips)
        linear = linear_mip_chain_size(width, height, fourcc, mips)
        return rebuild_texture_info(xi[:34], fourcc, mips, linear), pc_body
    if kind == "prefix":
        pc_body = untile_dxt_body(body, width, height, fourcc, mips=param)
        linear = linear_mip_chain_size(width, height, fourcc, param)
        return rebuild_texture_info(xi[:34], fourcc, param, linear), pc_body
    if kind == "single":
        m = param
        wpx = max(1, width >> m)
        hpx = max(1, height >> m)
        pc_body = _untile_own_surface(body, wpx, hpx, fourcc)
        linear = linear_mip_chain_size(wpx, hpx, fourcc, 1)
        return rebuild_texture_info(xi[:34], fourcc, 1, linear), pc_body
    if kind == "tail_page" and fourcc == b"DXT5" and len(body) == 32 * 32 * 16:
        pc_body, resident = untile_tail_page(body, width, height, fourcc, mips)
        linear = len(pc_body)
        return rebuild_texture_info(xi[:34], fourcc, resident, linear), pc_body
    pc_body, pw, ph, pm = untile_streaming_page(body, fourcc)
    linear = len(pc_body)
    # Keep declared top-level dims; total_size reflects the resident page only.
    return rebuild_texture_info(xi[:34], fourcc, mips, linear), pc_body


def convert_texture_chunks(xbox_info: bytes, xbox_body: bytes):
    """Convert an Xbox texture (INFO, BODY) pair to PC layout.

    Returns ``(pc_info, pc_body)``. Raises :class:`UnsupportedTexture` for
    non-DXT formats only.
    """
    try:
        pc_info, pc_body = convert_streamed_texture(xbox_info, xbox_body)
    except UnsupportedTexture:
        raise
    if pc_body is None:
        raise UnsupportedTexture("INFO-only stub without resident BODY")
    return pc_info, pc_body
