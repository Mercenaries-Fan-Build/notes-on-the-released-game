#!/usr/bin/env python3
"""DEPRECATED: Use tools/dlc_port.py instead.

Port Mercenaries 2 Xbox 360 DLC content to PC ``vz-patch.wad`` format.

The Xbox 360 "Blow It Up Again Pack" DLC uses the same FFCS/sges/UCFX format
family as the PC version, but big-endian (PowerPC byte order).  All 4-byte
magic signatures are reversed (FFCS→SCFF, sges→segs, UCFX→XFCU, etc.) and
all multi-byte integer fields are big-endian.

This tool:
  1. Extracts DLC01.doh from the STFS LIVE container (or reads it directly)
  2. Parses the big-endian FFCS WAD (SCFF header, XDNI/TESA/SHTP chunks)
  3. Decompresses big-endian sges blocks (segs magic, 32-byte header)
  4. Byte-swaps the decompressed UCFX block wrapper from BE→LE
  5. Recompresses with the PC sges format
  6. Builds a ``vz-patch.wad`` using the engine's native patch overlay mechanism

Usage:
  python3 tools/dlc_port_x360_to_pc.py \\
    --stfs /tmp/mercs2_xbox_dlc/45410828/00000002/86ABF01DD4E356CA0ED1302E6E3AB36C5A6E1D9345 \\
    --output /tmp/dlc_vz-patch.wad

  python3 tools/dlc_port_x360_to_pc.py \\
    --stfs /tmp/mercs2_xbox_dlc/45410828/00000002/86ABF01DD4E356CA0ED1302E6E3AB36C5A6E1D9345 \\
    --output /tmp/dlc_vz-patch.wad \\
    --max-blocks 5 --verbose
"""

from __future__ import annotations

import argparse
import struct
import sys
import zlib
from dataclasses import dataclass
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from sges_compress import compress_sges  # noqa: E402

# ── Constants ─────────────────────────────────────────────────────────

STFS_MAGIC_LIVE = b"LIVE"
STFS_MAGIC_PIRS = b"PIRS"
STFS_MAGIC_CON  = b"CON "

SCFF_MAGIC = b"SCFF"   # big-endian FFCS
SEGS_MAGIC = b"segs"   # big-endian sges
XFCU_MAGIC = b"XFCU"   # big-endian UCFX

SGES_MAGIC = b"sges"   # little-endian (PC)
FFCS_MAGIC = b"FFCS"   # little-endian (PC)

PAGE_SIZE = 0x8000      # 32 KB FFCS page
STFS_BLOCK_SIZE = 0x1000  # 4 KB STFS data block
STFS_BLOCKS_PER_HASH_GROUP = 170  # hash table inserted every 170 data blocks

# 144-byte build certificate blob (identical across all PC WADs)
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

PTHS_TRAILER = (
    b"xa37dd45ffe100bfffcc9753aabac325f07cb3fa231144fe2e33ae4783feead2"
    b"b8a73ff021fac326df0ef9753ab9cdf6573ddff0312fab0b0ff39779eaff312"
    b"a4f5de65892ffee33a44569bebf21f66d22e54a22347efd375981188743afd9"
    b"9baacc342d88a99321235798725fedcbf43252669dade32415fee89da543bf23"
    b"d4ex"
)
assert len(PTHS_TRAILER) == 258

# UCFX chunk tags that contain multi-byte fields requiring byte-swap
UCFX_CHUNK_TAGS_BE = {
    b"XFCU", b"RDHC", b"PMOC", b"MOEG", b"HSEM", b"GMRP",
    b"MRTS", b"FUBI", b"LRTM", b"SGLF", b"SDNB", b"OFNI",
    b"YDOB", b"TIWS", b"EMAN", b"TMRP", b"REIH", b"XDNI",
    b"TATS",
}


# ── Data structures ───────────────────────────────────────────────────

@dataclass
class STFSFileEntry:
    name: str
    is_directory: bool
    is_consecutive: bool
    valid_blocks: int
    allocated_blocks: int
    first_block: int
    path_indicator: int
    file_size: int


@dataclass
class FFCSChunkRow:
    tag_be: bytes       # 4-byte big-endian tag (e.g. b"XDNI")
    tag_le: str         # reversed ASCII name (e.g. "INDX")
    offset: int         # file offset within the DOH
    meta: int           # count / identifier


@dataclass
class INDXEntry:
    page_index: int
    packed_field: int
    flags: int
    page_count: int
    doh_offset: int     # page_index * PAGE_SIZE


@dataclass
class ASETEntry:
    asset_hash: int
    u1: int
    u2: int
    u3: int
    block_index: int    # (u2 >> 16) & 0xFFFF


# ── STFS extraction ──────────────────────────────────────────────────

def _build_stfs_hash_block_set(container: bytes, base: int = 0xC000) -> set[int]:
    """Scan the STFS container and return the set of physical block numbers that
    are hash table blocks (not user data).

    STFS hash table blocks contain 170 entries of 24 bytes each (20-byte SHA-1
    hash + 1-byte status + 3-byte next-block pointer).  We identify them by:

    1. ALL 170 status bytes (at offset +20 within each 24-byte entry) share
       the same value — either 0x00 (active table) or 0x80 (backup table).
    2. For active tables (status 0x00): ALL next-block 3-byte fields are zero.
       For backup tables (status 0x80): the first 10 next-block fields form a
       consecutive sequence (first_val, first_val+1, first_val+2, …).
    3. At least 4 entries have a non-zero SHA-1 hash.
    """
    total_phys = (len(container) - base) // STFS_BLOCK_SIZE
    hash_blocks: set[int] = set()

    for pb in range(total_phys):
        off = base + pb * STFS_BLOCK_SIZE
        if off + STFS_BLOCK_SIZE > len(container):
            break

        first_status = container[off + 20]
        if first_status not in (0x00, 0x80):
            continue

        all_same = True
        for ei in range(1, STFS_BLOCKS_PER_HASH_GROUP):
            if container[off + ei * 24 + 20] != first_status:
                all_same = False
                break
        if not all_same:
            continue

        next_fields_ok = True
        if first_status == 0x00:
            for ei in range(STFS_BLOCKS_PER_HASH_GROUP):
                eo = off + ei * 24
                if container[eo + 21] | container[eo + 22] | container[eo + 23]:
                    next_fields_ok = False
                    break
        else:
            first_nb = ((container[off + 21] << 16)
                        | (container[off + 22] << 8)
                        | container[off + 23])
            for ei in range(1, min(10, STFS_BLOCKS_PER_HASH_GROUP)):
                eo = off + ei * 24
                nb = ((container[eo + 21] << 16)
                      | (container[eo + 22] << 8)
                      | container[eo + 23])
                if nb != first_nb + ei:
                    next_fields_ok = False
                    break

        if not next_fields_ok:
            continue

        nonzero_sha1 = 0
        for ei in range(STFS_BLOCKS_PER_HASH_GROUP):
            for j in range(20):
                if container[off + ei * 24 + j] != 0:
                    nonzero_sha1 += 1
                    break
            if nonzero_sha1 >= 4:
                break
        if nonzero_sha1 < 4:
            continue

        hash_blocks.add(pb)

    return hash_blocks


def _build_data_block_map(
    container: bytes,
    hash_block_set: set[int],
    base: int = 0xC000,
) -> list[int]:
    """Build a list mapping data block index → physical block number.

    Physical blocks that are NOT hash blocks are data blocks, numbered
    consecutively starting from 0.
    """
    total_phys = (len(container) - base) // STFS_BLOCK_SIZE
    return [pb for pb in range(total_phys) if pb not in hash_block_set]


def stfs_read_consecutive_file(
    container: bytes,
    first_block: int,
    file_size: int,
    *,
    base: int = 0xC000,
    hash_block_set: set[int] | None = None,
) -> bytes:
    """Read a consecutive STFS file, skipping interleaved hash table blocks."""
    if hash_block_set is None:
        hash_block_set = _build_stfs_hash_block_set(container, base)

    data_map = _build_data_block_map(container, hash_block_set, base)

    result = bytearray()
    remaining = file_size
    db = first_block
    while remaining > 0:
        if db >= len(data_map):
            raise ValueError(
                f"Data block {db} out of range (max {len(data_map) - 1})"
            )
        phys = data_map[db]
        off = base + phys * STFS_BLOCK_SIZE
        to_take = min(STFS_BLOCK_SIZE, remaining)
        result.extend(container[off:off + to_take])
        remaining -= to_take
        db += 1
    return bytes(result)


def parse_stfs_file_table(
    container: bytes,
    base: int = 0xC000,
    hash_block_set: set[int] | None = None,
) -> list[STFSFileEntry]:
    """Parse the STFS file table (block 0) to list embedded files."""
    if hash_block_set is None:
        hash_block_set = _build_stfs_hash_block_set(container, base)

    data_map = _build_data_block_map(container, hash_block_set, base)
    phys = data_map[0]
    ft_offset = base + phys * STFS_BLOCK_SIZE

    entries: list[STFSFileEntry] = []
    idx = 0
    while idx < 64:
        off = ft_offset + idx * 0x40
        if off + 0x40 > len(container):
            break
        entry = container[off:off + 0x40]
        name_raw = entry[:0x28]
        name = name_raw.split(b"\x00")[0].decode("ascii", errors="replace")
        if not name:
            break
        flags = entry[0x28]
        valid_blks = entry[0x29] | (entry[0x2A] << 8) | (entry[0x2B] << 16)
        alloc_blks = entry[0x2C] | (entry[0x2D] << 8) | (entry[0x2E] << 16)
        first_block = entry[0x2F] | (entry[0x30] << 8) | (entry[0x31] << 16)
        path_ind = struct.unpack_from(">H", entry, 0x32)[0]
        file_size = struct.unpack_from(">I", entry, 0x34)[0]
        entries.append(STFSFileEntry(
            name=name,
            is_directory=bool(flags & 0x80),
            is_consecutive=bool(flags & 0x40),
            valid_blocks=valid_blks,
            allocated_blocks=alloc_blks,
            first_block=first_block,
            path_indicator=path_ind,
            file_size=file_size,
        ))
        idx += 1
    return entries


def extract_doh_from_stfs(container: bytes) -> bytes:
    """Find and extract ``DLC01.doh`` from an STFS container."""
    magic = container[:4]
    if magic not in (STFS_MAGIC_LIVE, STFS_MAGIC_PIRS, STFS_MAGIC_CON):
        raise ValueError(f"Not an STFS container (magic={magic!r})")

    print("  Scanning for STFS hash table blocks...")
    hash_block_set = _build_stfs_hash_block_set(container)
    print(f"  Found {len(hash_block_set)} hash table blocks")

    entries = parse_stfs_file_table(container, hash_block_set=hash_block_set)
    doh_entry = None
    for e in entries:
        if e.name.lower().endswith(".doh") and not e.is_directory:
            doh_entry = e
            break

    if doh_entry is None:
        names = [e.name for e in entries]
        raise ValueError(f"DLC01.doh not found in STFS. Files: {names}")

    if not doh_entry.is_consecutive:
        raise NotImplementedError(
            f"DLC01.doh is not marked consecutive — fragmented STFS extraction "
            f"is not implemented.  Use an external STFS tool to extract it first."
        )

    print(f"  Extracting {doh_entry.name}: {doh_entry.file_size:,} bytes "
          f"({doh_entry.valid_blocks} blocks, first_block={doh_entry.first_block})")

    return stfs_read_consecutive_file(
        container, doh_entry.first_block, doh_entry.file_size,
        hash_block_set=hash_block_set,
    )


# ── Big-endian FFCS (SCFF) parser ────────────────────────────────────

def parse_scff_header(doh: bytes) -> tuple[int, int, list[FFCSChunkRow]]:
    """Parse the SCFF header and return (version, chunk_count, chunk_rows)."""
    if doh[:4] != SCFF_MAGIC:
        raise ValueError(f"Expected SCFF magic, got {doh[:4]!r}")
    version = struct.unpack_from(">I", doh, 4)[0]
    chunk_count = struct.unpack_from(">I", doh, 8)[0]

    rows: list[FFCSChunkRow] = []
    for i in range(min(chunk_count, 5)):
        off = 0x0C + i * 12
        tag_be = doh[off:off + 4]
        tag_le = tag_be[::-1].decode("ascii", errors="replace")
        val = struct.unpack_from(">I", doh, off + 4)[0]
        meta = struct.unpack_from(">I", doh, off + 8)[0]
        rows.append(FFCSChunkRow(tag_be=tag_be, tag_le=tag_le, offset=val, meta=meta))
    return version, chunk_count, rows


def parse_be_indx(doh: bytes, indx_offset: int, count: int) -> list[INDXEntry]:
    """Parse big-endian INDX entries (12 bytes each)."""
    entries: list[INDXEntry] = []
    for i in range(count):
        off = indx_offset + i * 12
        page_idx = struct.unpack_from(">I", doh, off)[0]
        packed = struct.unpack_from(">I", doh, off + 4)[0]
        flags_pages = struct.unpack_from(">I", doh, off + 8)[0]
        entries.append(INDXEntry(
            page_index=page_idx,
            packed_field=packed,
            flags=(flags_pages >> 16) & 0xFFFF,
            page_count=flags_pages & 0xFFFF,
            doh_offset=page_idx * PAGE_SIZE,
        ))
    return entries


def parse_be_aset(doh: bytes, aset_offset: int, count: int) -> list[ASETEntry]:
    """Parse big-endian ASET entries (16 bytes each)."""
    entries: list[ASETEntry] = []
    for i in range(count):
        off = aset_offset + i * 16
        u0 = struct.unpack_from(">I", doh, off)[0]
        u1 = struct.unpack_from(">I", doh, off + 4)[0]
        u2 = struct.unpack_from(">I", doh, off + 8)[0]
        u3 = struct.unpack_from(">I", doh, off + 12)[0]
        entries.append(ASETEntry(
            asset_hash=u0, u1=u1, u2=u2, u3=u3,
            block_index=(u2 >> 16) & 0xFFFF,
        ))
    return entries


def parse_be_pths(doh: bytes, pths_offset: int, count: int) -> list[str]:
    """Parse big-endian PTHS null-terminated path strings."""
    paths: list[str] = []
    pos = pths_offset
    end = min(len(doh), pths_offset + 0x100000)
    while pos < end and len(paths) < count:
        nul = doh.find(b"\x00", pos)
        if nul < 0:
            break
        s = doh[pos:nul].decode("ascii", errors="replace")
        if "\\" in s or "/" in s:
            paths.append(s)
        elif s.startswith("xa37dd45"):
            break
        pos = nul + 1
    return paths


# ── Big-endian sges (segs) decompressor ──────────────────────────────

def decompress_be_sges(doh: bytes, offset: int, max_size: int) -> bytes:
    """Decompress a big-endian sges block from the DOH data.

    Xbox 360 sges layout:
      +0x00: magic 'segs' (4 bytes)
      +0x04: version (BE u16) = 4
      +0x06: segment_count (BE u16)
      +0x08: total_decompressed (BE u32)
      +0x0C: total_compressed (BE u32)
      +0x10: segment table — N entries × 8 bytes each:
               +0 u16 compressed_size
               +2 u16 decompressed_size (0 = full 64KB; actual for last segment)
               +4 u32 compressed_data_offset (relative, with flag bits — not used here)
      Header size = 16 + align16(N × 8), i.e. 16-byte aligned after the seg table.
      Compressed segments follow, each starting at a 16-byte aligned boundary.
      When compressed_size == decompressed_size (and dsz > 0), the segment is raw.
    """
    if doh[offset:offset + 4] != SEGS_MAGIC:
        raise ValueError(f"Expected segs magic at 0x{offset:X}, "
                         f"got {doh[offset:offset + 4]!r}")

    seg_count = struct.unpack_from(">H", doh, offset + 6)[0]
    decomp_total = struct.unpack_from(">I", doh, offset + 8)[0]

    seg_table: list[tuple[int, int]] = []
    for si in range(seg_count):
        so = offset + 16 + si * 8
        csz = struct.unpack_from(">H", doh, so)[0]
        dsz = struct.unpack_from(">H", doh, so + 2)[0]
        seg_table.append((csz, dsz))

    seg_table_bytes = seg_count * 8
    header_size = 16 + ((seg_table_bytes + 15) & ~15) if seg_count > 0 else 16
    payload = doh[offset + header_size : offset + max_size]

    result = bytearray()
    pos = 0
    for si, (csz, dsz) in enumerate(seg_table):
        is_raw = csz > 0 and csz == dsz
        if is_raw:
            result.extend(payload[pos:pos + csz])
            pos += csz
        else:
            dc = zlib.decompressobj(-15)
            piece = dc.decompress(payload[pos:])
            piece += dc.flush()
            consumed = len(payload[pos:]) - len(dc.unused_data)
            result.extend(piece)
            pos += consumed
        pos = (pos + 15) & ~15

    if len(result) != decomp_total:
        raise ValueError(
            f"Decompressed {len(result):,} bytes but expected {decomp_total:,}"
        )
    return bytes(result)


# ── UCFX byte-swap (BE → LE) ─────────────────────────────────────────

def _swap32(data: bytearray, offset: int) -> None:
    """In-place swap a 4-byte value at offset."""
    data[offset], data[offset + 3] = data[offset + 3], data[offset]
    data[offset + 1], data[offset + 2] = data[offset + 2], data[offset + 1]


def _swap16(data: bytearray, offset: int) -> None:
    """In-place swap a 2-byte value at offset."""
    data[offset], data[offset + 1] = data[offset + 1], data[offset]


def _reverse4(data: bytearray, offset: int) -> None:
    """Reverse 4 bytes in-place (for magic tag reversal)."""
    data[offset:offset + 4] = data[offset:offset + 4][::-1]


def byteswap_block_wrapper_be_to_le(decompressed: bytes) -> bytes:
    """Swap the block wrapper header and UCFX container fields from BE to LE.

    The decompressed block layout:
      +0x00: u32 record_count (N)
      +0x04: N × 16-byte asset records:
               +0 u32 asset_hash
               +4 u32 type_constant (0x42498680 on PC)
               +8 u32 reserved (zero)
               +12 u32 chunk_size
      After records: concatenated UCFX chunks, each followed by a CSUM trailer.

    This function swaps:
      - Block wrapper: record_count + all 16-byte records (u32 fields)
      - Each UCFX container: magic tag reversal + u32 header fields
      - Each CSUM trailer: tag reversal + u32 checksum value
      - UCFX chunk table entries: tag reversals + u32 fields

    It does NOT swap:
      - Vertex stream data (STRM contents) — needs format-aware per-float swap
      - Index buffer data (IBUF contents) — needs per-u16 swap
      - Texture pixel data — byte arrays, no swap needed
      - Havok binary blobs — separate endianness handling needed
      - Material parameter floats — needs per-field swap

    These deferred swaps mean meshes/textures won't render correctly until
    a structure-aware UCFX deep-swap pass is added. The outer container is
    valid enough for the PC engine to recognize and index the blocks.
    """
    out = bytearray(decompressed)
    size = len(out)

    # ── Swap block wrapper header ──
    _swap32(out, 0)  # record_count
    record_count = struct.unpack_from("<I", out, 0)[0]

    records_end = 4 + record_count * 16
    if records_end > size:
        record_count = min(record_count, (size - 4) // 16)
        records_end = 4 + record_count * 16

    for i in range(record_count):
        base = 4 + i * 16
        _swap32(out, base + 0)   # asset_hash
        _swap32(out, base + 4)   # type_constant
        _swap32(out, base + 8)   # reserved
        _swap32(out, base + 12)  # chunk_size

    # ── Walk UCFX chunks and swap their headers ──
    pos = records_end
    chunk_idx = 0
    while pos < size - 8 and chunk_idx < record_count:
        # Each chunk: UCFX header + body + CSUM(4 tag + 4 value)
        chunk_size = struct.unpack_from("<I", out, 4 + chunk_idx * 16 + 12)[0]
        chunk_end = pos + chunk_size
        if chunk_end > size:
            break

        _swap_ucfx_container(out, pos, chunk_end)

        pos = chunk_end
        chunk_idx += 1

    return bytes(out)


def _swap_ucfx_container(data: bytearray, start: int, end: int) -> None:
    """Swap a single UCFX container's header fields in-place.

    UCFX layout at start:
      +0: 4-byte magic (XFCU → UCFX)
      +4: u32 u0 (data_base_offset / total_size indicator)
      +8: u32 u1
      +12: u32 u2
      +16: u32 u3
      +20: chunk table (20-byte rows)
      body: chunk data (not a 20-byte-aligned table)
      end-8: CSUM tag(4) + checksum(4)

    The chunk table has a finite number of rows. We determine where it ends
    by checking for known 4-byte ASCII chunk tags. As soon as we see a tag
    that doesn't look like an ASCII identifier, we stop — we've hit the body.
    """
    if start + 20 > end:
        return

    # Reverse magic tag (XFCU → UCFX)
    _reverse4(data, start)

    # Swap the 4 header u32s
    for off in (start + 4, start + 8, start + 12, start + 16):
        if off + 4 <= end:
            _swap32(data, off)

    # Walk the chunk table (20-byte rows starting at +20)
    pos = start + 20
    while pos + 20 <= end - 8:  # leave room for CSUM trailer
        tag = data[pos:pos + 4]

        # Check if this looks like a valid BE chunk tag (printable/known ASCII)
        is_ascii_tag = all(32 <= b < 127 for b in tag)
        # Also accept sentinel (0xFFFFFFFF as first u32 after tag)
        is_sentinel = (tag == b"\xff\xff\xff\xff")

        if not is_ascii_tag and not is_sentinel:
            break

        # Reverse the tag and swap the 4 u32 fields
        _reverse4(data, pos)
        _swap32(data, pos + 4)
        _swap32(data, pos + 8)
        _swap32(data, pos + 12)
        _swap32(data, pos + 16)
        pos += 20

    # Swap the CSUM trailer at the very end of the container (last 8 bytes)
    csum_pos = end - 8
    if csum_pos >= start:
        csum_tag = data[csum_pos:csum_pos + 4]
        if csum_tag == b"MUSC":
            _reverse4(data, csum_pos)  # MUSC → CSUM
            _swap32(data, csum_pos + 4)


def crc32_mercs2(data: bytes) -> int:
    """CRC-32 with init=0, no final XOR (Mercenaries 2 CSUM algorithm)."""
    return (zlib.crc32(data, 0xFFFFFFFF) ^ 0xFFFFFFFF) & 0xFFFFFFFF


def recompute_csums(block_data: bytes) -> bytes:
    """Recompute CSUM trailers for all UCFX chunks in a LE block."""
    out = bytearray(block_data)
    record_count = struct.unpack_from("<I", out, 0)[0]
    records_end = 4 + record_count * 16

    pos = records_end
    for i in range(record_count):
        chunk_size = struct.unpack_from("<I", out, 4 + i * 16 + 12)[0]
        chunk_end = pos + chunk_size
        if chunk_end > len(out):
            break
        csum_off = chunk_end - 8
        if csum_off >= pos and out[csum_off:csum_off + 4] == b"CSUM":
            ucfx_body = bytes(out[pos:csum_off])
            new_csum = crc32_mercs2(ucfx_body)
            struct.pack_into("<I", out, csum_off + 4, new_csum)
        pos = chunk_end

    return bytes(out)


# ── Patch WAD builder ─────────────────────────────────────────────────

def _align_up(value: int, alignment: int) -> int:
    return (value + alignment - 1) & ~(alignment - 1)


def build_multi_block_patch_wad(
    *,
    compressed_blocks: list[bytes],
    aset_entries_per_block: list[list[ASETEntry]],
    path_strings: list[str],
    indx_entries: list[INDXEntry],
    global_aset_entries: list[ASETEntry] | None = None,
) -> bytes:
    """Build a PC FFCS patch WAD containing multiple DLC blocks.

    Layout:
      [0x000 - 0x0FF]  FFCS header (256 bytes)
      [0x8000]         INDX data
      [INDX end]       ASET data
      [ASET end]       PTHS data
      [0x208000]       DATA: concatenated sges blocks (page-aligned)
    """
    num_blocks = len(compressed_blocks)

    # Fixed layout offsets
    indx_offset = 0x8000
    indx_size = num_blocks * 12

    aset_offset = indx_offset + indx_size
    all_aset: list[ASETEntry] = []
    for block_idx, block_asets in enumerate(aset_entries_per_block):
        for ae in block_asets:
            all_aset.append(ASETEntry(
                asset_hash=ae.asset_hash,
                u1=ae.u1,
                u2=(block_idx << 16) | (ae.u2 & 0xFFFF),
                u3=ae.u3,
                block_index=block_idx,
            ))
    if global_aset_entries:
        for ae in global_aset_entries:
            all_aset.append(ASETEntry(
                asset_hash=ae.asset_hash,
                u1=ae.u1,
                u2=(0xFFFF << 16) | (ae.u2 & 0xFFFF),
                u3=ae.u3,
                block_index=0xFFFF,
            ))
    aset_size = len(all_aset) * 16

    pths_offset = aset_offset + aset_size
    pths_bytes = b""
    for p in path_strings:
        pths_bytes += p.encode("utf-8") + b"\x00"
    pths_bytes += PTHS_TRAILER + b"\x00"
    pths_size = len(pths_bytes)

    data_offset = 0x208000
    data_page_start = data_offset // PAGE_SIZE

    # Lay out blocks page-aligned in the DATA region
    block_data_parts: list[tuple[int, bytes]] = []  # (page_index, block_bytes)
    current_page = data_page_start
    for blk_bytes in compressed_blocks:
        block_data_parts.append((current_page, blk_bytes))
        pages_needed = _align_up(len(blk_bytes), PAGE_SIZE) // PAGE_SIZE
        current_page += pages_needed

    total_data_size = (current_page - data_page_start) * PAGE_SIZE
    file_size = data_offset + total_data_size

    # ── Build FFCS header ──
    header = bytearray(256)
    struct.pack_into("<4sII", header, 0, FFCS_MAGIC, 2, 7)

    cr_off = 0x0C
    struct.pack_into("<4sII", header, cr_off + 0,
                     b"INDX", indx_offset, num_blocks)
    struct.pack_into("<4sII", header, cr_off + 12,
                     b"DATA", data_offset, 36)
    struct.pack_into("<4sII", header, cr_off + 24,
                     b"CSUM", 0, len(all_aset))
    struct.pack_into("<4sII", header, cr_off + 36,
                     b"ASET", aset_offset, len(all_aset))
    struct.pack_into("<4sII", header, cr_off + 48,
                     b"PTHS", pths_offset, num_blocks)
    header[0x48:0x48 + 144] = FFCS_CERT_BLOB

    # ── Allocate output ──
    out = bytearray(file_size)
    out[:256] = header

    # ── Write INDX ──
    for i, (page_idx, blk_bytes) in enumerate(block_data_parts):
        pages = _align_up(len(blk_bytes), PAGE_SIZE) // PAGE_SIZE
        orig = indx_entries[i] if i < len(indx_entries) else indx_entries[0]
        struct.pack_into("<III", out, indx_offset + i * 12,
                         page_idx,
                         orig.packed_field,
                         (orig.flags << 16) | pages)

    # ── Write ASET ──
    for i, ae in enumerate(all_aset):
        off = aset_offset + i * 16
        struct.pack_into("<IIII", out, off,
                         ae.asset_hash, ae.u1, ae.u2, ae.u3)

    # ── Write PTHS ──
    out[pths_offset:pths_offset + pths_size] = pths_bytes

    # ── Write DATA ──
    for page_idx, blk_bytes in block_data_parts:
        blk_offset = page_idx * PAGE_SIZE
        out[blk_offset:blk_offset + len(blk_bytes)] = blk_bytes

    return bytes(out)


# ── Main pipeline ─────────────────────────────────────────────────────

def port_x360_dlc_to_pc(
    stfs_path: Path,
    output_path: Path,
    *,
    max_blocks: int | None = None,
    start_block: int = 0,
    verbose: bool = False,
    dump_dir: Path | None = None,
) -> int:
    """Full pipeline: STFS → SCFF parse → segs decompress → swap → sges compress → patch WAD."""
    print(f"Xbox 360 DLC → PC Patch WAD Porter")
    print(f"{'=' * 60}")

    # Step 1: Load STFS and extract DLC01.doh
    print(f"\n[1/6] Loading STFS container: {stfs_path}")
    container = stfs_path.read_bytes()
    magic = container[:4]
    if magic in (STFS_MAGIC_LIVE, STFS_MAGIC_PIRS, STFS_MAGIC_CON):
        print(f"  STFS magic: {magic.decode('ascii')}")
        doh = extract_doh_from_stfs(container)
    elif magic == SCFF_MAGIC:
        print(f"  Direct DOH file detected (SCFF magic)")
        doh = container
    else:
        print(f"  ERROR: Unknown format (magic={magic!r})", file=sys.stderr)
        return 1
    print(f"  DOH size: {len(doh):,} bytes")

    # Step 2: Parse SCFF header
    print(f"\n[2/6] Parsing big-endian FFCS (SCFF) header...")
    version, chunk_count, rows = parse_scff_header(doh)
    print(f"  Version: {version}, Chunk count: {chunk_count}")

    indx_row = next((r for r in rows if r.tag_le == "INDX"), None)
    aset_row = next((r for r in rows if r.tag_le == "ASET"), None)
    pths_row = next((r for r in rows if r.tag_le == "PTHS"), None)
    data_row = next((r for r in rows if r.tag_le == "DATA"), None)

    if not all([indx_row, aset_row, pths_row, data_row]):
        print("  ERROR: Missing required chunks", file=sys.stderr)
        return 1

    for r in rows:
        print(f"  {r.tag_be.decode('ascii'):5s} ({r.tag_le:5s}): "
              f"offset=0x{r.offset:08X}  meta={r.meta}")

    # Parse INDX, ASET, PTHS
    indx_entries = parse_be_indx(doh, indx_row.offset, indx_row.meta)
    aset_entries = parse_be_aset(doh, aset_row.offset, aset_row.meta)
    path_strings = parse_be_pths(doh, pths_row.offset, pths_row.meta)

    total_blocks = len(indx_entries)
    print(f"\n  INDX entries: {total_blocks}")
    print(f"  ASET entries: {len(aset_entries)}")
    print(f"  PTHS entries: {len(path_strings)}")

    # Build ASET lookup: xbox_block_index → list[ASETEntry]
    # Xbox ASET block_index values are offset from a base (e.g. 1038, not 0).
    # Entries with block_index == 0xFFFF are global/unassigned and are included
    # in every block's ASET list (the engine uses them for streaming hints).
    aset_by_block: dict[int, list[ASETEntry]] = {}
    aset_global: list[ASETEntry] = []
    for ae in aset_entries:
        if ae.block_index == 0xFFFF:
            aset_global.append(ae)
        else:
            aset_by_block.setdefault(ae.block_index, []).append(ae)
    aset_base_idx = min(aset_by_block.keys()) if aset_by_block else 0

    # Determine block range
    end_block = total_blocks
    if max_blocks is not None:
        end_block = min(start_block + max_blocks, total_blocks)
    block_range = range(start_block, end_block)
    num_to_process = len(block_range)
    print(f"\n  Processing blocks {start_block}..{end_block - 1} ({num_to_process} blocks)")

    # Step 3-5: Process each block
    print(f"\n[3-5/6] Decompress → byte-swap → recompress...")
    compressed_results: list[bytes] = []
    aset_results: list[list[ASETEntry]] = []
    path_results: list[str] = []
    indx_results: list[INDXEntry] = []
    failures: list[tuple[int, str, str]] = []

    for i, blk_idx in enumerate(block_range):
        ie = indx_entries[blk_idx]
        path = path_strings[blk_idx] if blk_idx < len(path_strings) else f"block_{blk_idx:05d}"
        short_name = path.rsplit("\\", 1)[-1] if "\\" in path else path

        # Compute the block's byte range in the DOH
        block_start = ie.doh_offset
        if blk_idx + 1 < total_blocks:
            block_end_limit = indx_entries[blk_idx + 1].doh_offset
        else:
            block_end_limit = len(doh)
        block_size = ie.page_count * PAGE_SIZE

        if block_start + 4 > len(doh):
            msg = f"block offset 0x{block_start:X} beyond DOH"
            if verbose:
                print(f"  [{i + 1}/{num_to_process}] SKIP {short_name}: {msg}")
            failures.append((blk_idx, short_name, msg))
            continue

        # Check for segs magic
        if doh[block_start:block_start + 4] != SEGS_MAGIC:
            msg = f"no segs magic at 0x{block_start:X} (got {doh[block_start:block_start + 4]!r})"
            if verbose:
                print(f"  [{i + 1}/{num_to_process}] SKIP {short_name}: {msg}")
            failures.append((blk_idx, short_name, msg))
            continue

        try:
            # 3. Decompress
            decompressed = decompress_be_sges(doh, block_start, block_size)

            # 4. Byte-swap wrapper + UCFX headers
            swapped = byteswap_block_wrapper_be_to_le(decompressed)

            # Recompute CSUMs since we changed byte order
            swapped = recompute_csums(swapped)

            if dump_dir is not None:
                dump_dir.mkdir(parents=True, exist_ok=True)
                (dump_dir / f"{blk_idx:05d}_be.block.bin").write_bytes(decompressed)
                (dump_dir / f"{blk_idx:05d}_le.block.bin").write_bytes(swapped)

            # 5. Recompress with PC sges format
            pc_sges = compress_sges(swapped, segment_size=65536, level=6, major=4)

            compressed_results.append(pc_sges)
            indx_results.append(ie)
            path_results.append(path)

            xbox_aset_idx = aset_base_idx + blk_idx
            block_asets = aset_by_block.get(xbox_aset_idx, [])
            aset_results.append(block_asets)

            ratio = len(pc_sges) / len(decompressed) * 100 if decompressed else 0
            if verbose or i < 5 or (i + 1) % 10 == 0:
                print(f"  [{i + 1}/{num_to_process}] {short_name}: "
                      f"decomp={len(decompressed):,} → swap → "
                      f"sges={len(pc_sges):,} ({ratio:.0f}%)")

        except Exception as exc:
            msg = str(exc)
            if verbose:
                print(f"  [{i + 1}/{num_to_process}] FAIL {short_name}: {msg}")
            failures.append((blk_idx, short_name, msg))

    print(f"\n  Processed: {len(compressed_results)} OK, {len(failures)} failed")
    if failures:
        print(f"  Failures:")
        for blk_idx, name, msg in failures[:10]:
            print(f"    block {blk_idx} ({name}): {msg}")
        if len(failures) > 10:
            print(f"    ... and {len(failures) - 10} more")

    if not compressed_results:
        print("\nERROR: No blocks successfully processed.", file=sys.stderr)
        return 1

    # Step 6: Build patch WAD
    print(f"\n[6/6] Building PC patch WAD...")
    patch_wad = build_multi_block_patch_wad(
        compressed_blocks=compressed_results,
        aset_entries_per_block=aset_results,
        path_strings=path_results,
        indx_entries=indx_results,
        global_aset_entries=aset_global,
    )

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_bytes(patch_wad)

    print(f"\n{'=' * 60}")
    print(f"Output: {output_path}")
    print(f"  Size: {len(patch_wad):,} bytes ({len(patch_wad) / 1024 / 1024:.1f} MB)")
    print(f"  Blocks: {len(compressed_results)}")
    total_aset = sum(len(a) for a in aset_results)
    print(f"  ASET entries: {total_aset}")
    print(f"  Paths: {len(path_results)}")
    print(f"\nByte-swap status:")
    print(f"  IMPLEMENTED: Block wrapper (record count + asset records)")
    print(f"  IMPLEMENTED: UCFX container headers (magic + u32 fields)")
    print(f"  IMPLEMENTED: UCFX chunk table tags + offset/size fields")
    print(f"  IMPLEMENTED: CSUM trailers (tag + value, recomputed)")
    print(f"  DEFERRED: STRM vertex data (needs per-float swap)")
    print(f"  DEFERRED: IBUF index data (needs per-u16 swap)")
    print(f"  DEFERRED: MTRL material parameters (needs per-field swap)")
    print(f"  DEFERRED: HIER bone matrices (needs per-float swap)")
    print(f"  DEFERRED: Texture pixel data (DXT block bytes, may not need swap)")
    print(f"  DEFERRED: Havok binary data (separate endianness)")

    return 0


# ── CLI ───────────────────────────────────────────────────────────────

def main() -> int:
    ap = argparse.ArgumentParser(
        description="Port Mercenaries 2 Xbox 360 DLC to PC vz-patch.wad",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    ap.add_argument(
        "--stfs", type=Path, required=True,
        help="Path to STFS LIVE container or extracted DLC01.doh file",
    )
    ap.add_argument(
        "--output", "-o", type=Path, default=Path("/tmp/dlc_vz-patch.wad"),
        help="Output vz-patch.wad path (default: /tmp/dlc_vz-patch.wad)",
    )
    ap.add_argument(
        "--max-blocks", type=int, default=None,
        help="Process only the first N blocks (for testing)",
    )
    ap.add_argument(
        "--start-block", type=int, default=0,
        help="Start processing from this block index",
    )
    ap.add_argument(
        "--verbose", "-v", action="store_true",
        help="Print per-block details",
    )
    ap.add_argument(
        "--dump-dir", type=Path, default=None,
        help="Write intermediate decompressed blocks (BE and LE) to this directory",
    )
    ap.add_argument(
        "--list-blocks", action="store_true",
        help="List all blocks in the DLC and exit",
    )

    args = ap.parse_args()

    if args.list_blocks:
        container = args.stfs.read_bytes()
        magic = container[:4]
        if magic in (STFS_MAGIC_LIVE, STFS_MAGIC_PIRS, STFS_MAGIC_CON):
            doh = extract_doh_from_stfs(container)
        elif magic == SCFF_MAGIC:
            doh = container
        else:
            print(f"Unknown format: {magic!r}", file=sys.stderr)
            return 1

        _, _, rows = parse_scff_header(doh)
        indx_row = next((r for r in rows if r.tag_le == "INDX"), None)
        pths_row = next((r for r in rows if r.tag_le == "PTHS"), None)
        if not indx_row or not pths_row:
            print("Missing INDX/PTHS", file=sys.stderr)
            return 1

        indx_entries = parse_be_indx(doh, indx_row.offset, indx_row.meta)
        paths = parse_be_pths(doh, pths_row.offset, pths_row.meta)

        print(f"{'Idx':>5s}  {'Page':>6s}  {'DOH Offset':>12s}  "
              f"{'Packed':>6s}  {'Pages':>5s}  Path")
        for i, ie in enumerate(indx_entries):
            p = paths[i] if i < len(paths) else "?"
            print(f"{i:5d}  {ie.page_index:6d}  0x{ie.doh_offset:010X}  "
                  f"{ie.packed_field:6d}  {ie.page_count:5d}  {p}")
        return 0

    return port_x360_dlc_to_pc(
        args.stfs,
        args.output,
        max_blocks=args.max_blocks,
        start_block=args.start_block,
        verbose=args.verbose,
        dump_dir=args.dump_dir,
    )


if __name__ == "__main__":
    sys.exit(main())
