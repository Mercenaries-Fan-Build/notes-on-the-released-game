#!/usr/bin/env python3
"""DEPRECATED: Use tools/dlc_port.py instead.

Port Xbox 360 DLC content to PC-compatible patch WAD.

Converts the Xbox 360 "Blow It Up Again Pack" DLC from its big-endian
STFS/FFCS/sges/UCFX format into a PC ``vz-patch.wad`` that the engine
loads via its built-in patch overlay mechanism.

Pipeline:
  Xbox 360 RAR → STFS extraction → DLC01.doh (BE FFCS) → parse blocks →
    for each block: decompress BE sges → byte-swap UCFX → recompress LE sges →
      assemble into PC patch WAD (vz-patch.wad)

Usage:
  python3 tools/port_xbox_dlc.py \\
    --rar "Mercenaries.2.World.In.Flames.DLC.RF.X360-ZTM.rar" \\
    --pc-wad "Mercenaries 2 World in Flames DEMO/data/vz.wad" \\
    --output vz-patch.wad \\
    [--blocks N]
"""

from __future__ import annotations

import argparse
import struct
import subprocess
import sys
import tempfile
import zlib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from sges_compress import compress_sges  # noqa: E402

# ── Constants ─────────────────────────────────────────────────────────

STFS_BLOCK_SIZE = 0x1000
STFS_DATA_OFFSET = 0xC000

PAGE_SIZE = 0x8000  # 32 KB (FFCS page size)

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


def crc32_mercs2(data: bytes) -> int:
    """CRC-32 with init=0, no final XOR (Mercenaries 2 CSUM algorithm)."""
    return (zlib.crc32(data, 0xFFFFFFFF) ^ 0xFFFFFFFF) & 0xFFFFFFFF


# ── STFS extraction ──────────────────────────────────────────────────

# The FFCS page indices inside DLC01.doh address a *logical* file
# where STFS hash blocks have been removed.  To read the correct
# physical data we build a mapping from logical DOH 4KB-block to
# physical STFS 4KB-block, skipping hash blocks.
#
# Because the hash-block positions in this STFS container are
# non-uniform (they depend on how the Xbox 360 authored the file),
# we detect them dynamically by:
#   1. Reading the FFCS header directly (it's in physical blocks 1-72,
#      always before the first hash block).
#   2. Parsing the INDX to learn every expected DOH block position.
#   3. Scanning the raw STFS for every 4KB-aligned 'segs' magic.
#   4. Pairing the sorted lists to identify which physical blocks
#      are hash blocks (gaps in the mapping).
#   5. Building a ``data_block_phys`` lookup table: data_block_phys[N]
#      gives the physical block for the Nth logical data block.


def _build_stfs_block_map(stfs_data: bytes) -> list[int]:
    """Build a DOH-logical-block → physical-block lookup table.

    Returns ``data_block_phys`` where ``data_block_phys[N]`` is the
    physical STFS 4KB-block index for DOH logical block N.
    """
    # ── Step 1: read FFCS header directly (physical 1-169, no hash blocks) ──
    header_phys_start = STFS_DATA_OFFSET + STFS_BLOCK_SIZE  # block 1
    header_bytes = stfs_data[header_phys_start:header_phys_start + 0x48000]
    if header_bytes[:4] != b"SCFF":
        raise ValueError(f"DOH doesn't start with SCFF: {header_bytes[:4]!r}")

    chunk_count = struct.unpack_from(">I", header_bytes, 8)[0]
    indx_off = indx_count = 0
    for i in range(min(chunk_count, 7)):
        off = 0x0C + i * 12
        tag = header_bytes[off:off + 4][::-1].decode("ascii", errors="replace")
        val = struct.unpack_from(">I", header_bytes, off + 4)[0]
        meta = struct.unpack_from(">I", header_bytes, off + 8)[0]
        if tag == "INDX":
            indx_off, indx_count = val, meta
            break

    # ── Step 2: parse INDX → expected DOH 4KB-block positions ──
    expected_doh_blocks: list[int] = []
    for i in range(indx_count):
        off = indx_off + i * 12
        page_idx = struct.unpack_from(">I", header_bytes, off)[0]
        expected_doh_blocks.append(page_idx * (PAGE_SIZE // STFS_BLOCK_SIZE))

    # ── Step 3: scan raw STFS for all 4KB-aligned 'segs' ──
    segs_phys: list[int] = []
    pos = STFS_DATA_OFFSET
    end = len(stfs_data)
    while pos < end - 3:
        idx = stfs_data.find(b"segs", pos)
        if idx < 0:
            break
        if (idx - STFS_DATA_OFFSET) % STFS_BLOCK_SIZE == 0:
            segs_phys.append((idx - STFS_DATA_OFFSET) // STFS_BLOCK_SIZE)
        pos = idx + 1

    # ── Step 4: pair sorted lists to identify hash blocks ──
    segs_sorted = sorted(segs_phys)
    doh_sorted = sorted(expected_doh_blocks)

    if len(segs_sorted) != len(doh_sorted):
        print(f"  WARNING: segs count {len(segs_sorted)} != INDX count {len(doh_sorted)}",
              file=sys.stderr)

    hash_blocks: set[int] = {0}  # physical block 0 = file table (always skip)
    n = min(len(segs_sorted), len(doh_sorted))
    for i in range(n - 1):
        doh_i, phys_i = doh_sorted[i], segs_sorted[i]
        doh_next, phys_next = doh_sorted[i + 1], segs_sorted[i + 1]
        doh_gap = doh_next - doh_i
        phys_gap = phys_next - phys_i
        if phys_gap > doh_gap:
            for h in range(phys_i + doh_gap, phys_next):
                hash_blocks.add(h)

    # ── Step 5: build data_block_phys lookup ──
    max_phys = max(segs_sorted) + 200 if segs_sorted else 62000
    data_block_phys: list[int] = []
    for p in range(max_phys + 1):
        if p not in hash_blocks:
            data_block_phys.append(p)

    return data_block_phys


class StfsReader:
    """Wraps raw STFS bytes and provides hash-block-aware DOH reads."""

    def __init__(self, stfs_data: bytes) -> None:
        self.stfs_data = stfs_data
        print("  Building STFS block map...")
        self.block_map = _build_stfs_block_map(stfs_data)
        print(f"  Block map: {len(self.block_map)} data blocks "
              f"(~{len(self.block_map) * 4 / 1024:.0f} KB lookup)")

    def read(self, doh_offset: int, length: int) -> bytes:
        """Read *length* bytes from DOH at *doh_offset*."""
        out = bytearray()
        remaining = length
        first_4k = doh_offset // STFS_BLOCK_SIZE
        skip = doh_offset % STFS_BLOCK_SIZE

        block_idx = first_4k
        while remaining > 0:
            if block_idx >= len(self.block_map):
                raise ValueError(
                    f"DOH block {block_idx} exceeds block map "
                    f"({len(self.block_map)} entries)")
            phys = self.block_map[block_idx]
            abs_offset = STFS_DATA_OFFSET + phys * STFS_BLOCK_SIZE + skip
            chunk = min(STFS_BLOCK_SIZE - skip, remaining)
            if abs_offset + chunk > len(self.stfs_data):
                raise ValueError(
                    f"STFS read past EOF: DOH block {block_idx} phys {phys} "
                    f"offset 0x{abs_offset:X}")
            out.extend(self.stfs_data[abs_offset:abs_offset + chunk])
            remaining -= chunk
            block_idx += 1
            skip = 0

        return bytes(out)


def parse_stfs_file_table(stfs_data: bytes) -> list[dict]:
    """Parse the STFS file table at block 0."""
    entries = []
    ft_start = STFS_DATA_OFFSET  # block 0
    for i in range(64):
        off = ft_start + i * 0x40
        name_raw = stfs_data[off:off + 0x28]
        if name_raw[0] == 0:
            break
        name = name_raw.split(b"\x00")[0].decode("ascii", errors="replace")
        flags = stfs_data[off + 0x28]
        is_dir = bool(flags & 0x80)
        consecutive = bool(flags & 0x40)

        def u24le(d: bytes, o: int) -> int:
            return d[o] | (d[o + 1] << 8) | (d[o + 2] << 16)

        valid_blocks = u24le(stfs_data, off + 0x29)
        alloc_blocks = u24le(stfs_data, off + 0x2C)
        first_block = u24le(stfs_data, off + 0x2F)
        path_ind = struct.unpack_from(">H", stfs_data, off + 0x32)[0]
        file_size = struct.unpack_from(">I", stfs_data, off + 0x34)[0]

        entries.append({
            "name": name,
            "is_dir": is_dir,
            "consecutive": consecutive,
            "valid_blocks": valid_blocks,
            "alloc_blocks": alloc_blocks,
            "first_block": first_block,
            "path_ind": path_ind,
            "file_size": file_size,
        })
    return entries


def extract_stfs_from_rar(rar_path: Path, work_dir: Path) -> StfsReader:
    """Extract the STFS container from the RAR and return an StfsReader.

    The STFS is kept in memory rather than extracting DLC01.doh into a
    contiguous file, because the FFCS page indices inside the DOH assume
    hash blocks are present in the address space.
    """
    print("[STFS] Extracting STFS container from RAR...")

    stfs_dir = work_dir / "stfs"
    stfs_dir.mkdir(parents=True, exist_ok=True)

    subprocess.run(
        ["bsdtar", "-xf", str(rar_path), "-C", str(stfs_dir)],
        check=True, capture_output=True,
    )

    stfs_files = list(stfs_dir.rglob("*"))
    stfs_file = None
    for f in stfs_files:
        if f.is_file() and f.stat().st_size > 100_000_000:
            stfs_file = f
            break
    if stfs_file is None:
        raise FileNotFoundError("Could not find STFS container in RAR")

    print(f"[STFS] Reading {stfs_file.name} ({stfs_file.stat().st_size:,} bytes)")
    stfs_data = stfs_file.read_bytes()

    magic = stfs_data[:4]
    if magic not in (b"CON ", b"LIVE", b"PIRS"):
        raise ValueError(f"Not an STFS container: magic={magic!r}")
    print(f"[STFS] Magic: {magic.decode('ascii')}")

    entries = parse_stfs_file_table(stfs_data)
    print(f"[STFS] File table: {len(entries)} entries")
    for e in entries:
        kind = "DIR " if e["is_dir"] else "FILE"
        print(f"  {kind}  {e['name']:40s}  blocks={e['alloc_blocks']:6d}  size={e['file_size']:>14,}")

    reader = StfsReader(stfs_data)

    # Verify DOH magic
    doh_magic = reader.read(0, 4)
    if doh_magic != b"SCFF":
        raise ValueError(f"DOH doesn't start with SCFF: {doh_magic!r}")
    print("  DOH magic: SCFF (big-endian FFCS) ✓")

    return reader


# ── Big-endian FFCS parser ────────────────────────────────────────────


def parse_be_ffcs(doh: bytes) -> dict:
    """Parse a big-endian FFCS header (Xbox 360 .doh file)."""
    if doh[:4] != b"SCFF":
        raise ValueError(f"Expected SCFF, got {doh[:4]!r}")

    version = struct.unpack_from(">I", doh, 4)[0]
    chunk_count = struct.unpack_from(">I", doh, 8)[0]

    chunks = []
    for i in range(min(chunk_count, 5)):
        off = 0x0C + i * 12
        tag_bytes = doh[off:off + 4]
        tag = tag_bytes[::-1].decode("ascii", errors="replace")
        val = struct.unpack_from(">I", doh, off + 4)[0]
        meta = struct.unpack_from(">I", doh, off + 8)[0]
        chunks.append({"tag": tag, "tag_be": tag_bytes.decode("ascii", errors="replace"),
                        "offset": val, "meta": meta})

    cert_blob = doh[0x48:0x48 + 144]

    return {
        "version": version,
        "chunk_count": chunk_count,
        "chunks": chunks,
        "cert_blob": cert_blob,
    }


def parse_be_indx(doh: bytes, indx_offset: int, count: int) -> list[dict]:
    """Parse big-endian INDX entries (12 bytes each)."""
    entries = []
    for i in range(count):
        off = indx_offset + i * 12
        page_idx, packed, flags_pages = struct.unpack_from(">III", doh, off)
        entries.append({
            "page_index": page_idx,
            "packed_field": packed,
            "flags_and_page_count": flags_pages,
            "file_offset": page_idx * PAGE_SIZE,
            "page_count": flags_pages & 0xFFFF,
            "flags": (flags_pages >> 16) & 0xFFFF,
        })
    return entries


def parse_be_aset(doh: bytes, aset_offset: int, count: int) -> list[dict]:
    """Parse big-endian ASET entries (16 bytes each)."""
    entries = []
    for i in range(count):
        off = aset_offset + i * 16
        u0, u1, u2, u3 = struct.unpack_from(">IIII", doh, off)
        entries.append({
            "asset_hash": u0,
            "u32_1": u1,
            "u32_2": u2,
            "u32_3": u3,
            "block_index": (u2 >> 16) & 0xFFFF,
        })
    return entries


def parse_be_pths(doh: bytes, pths_offset: int, pths_count: int, file_size: int) -> list[str]:
    """Parse PTHS strings (ASCII, no endian issue)."""
    paths: list[str] = []
    pos = pths_offset
    end = min(file_size, pths_offset + 0x200000)
    while pos < end and len(paths) < pths_count:
        nul = doh.find(b"\x00", pos, end)
        if nul < 0:
            break
        s = doh[pos:nul].decode("ascii", errors="replace")
        if len(s) >= 6 and ("\\" in s or "/" in s):
            paths.append(s)
        pos = nul + 1
    return paths


# ── Xbox 360 sges decompression ──────────────────────────────────────


def decompress_xbox_sges(data: bytes, block_offset: int, block_size: int) -> bytes:
    """Decompress a big-endian Xbox 360 sges block.

    Xbox sges layout:
      +0x00: magic 'segs' (4 bytes)
      +0x04: version u16 BE (should be 4)
      +0x06: segment_count u16 BE
      +0x08: total_decompressed u32 BE
      +0x0C: total_compressed u32 BE
      +0x10: segment table (seg_count × 8 bytes each)
             Each entry: comp_size u16 BE, uncomp_size u16 BE, offset u32 BE
             offset bit 0 = compressed flag (always set for real segments)
             uncomp_size == 0 means default 65536 bytes
    """
    buf = data[block_offset:block_offset + block_size]
    if buf[:4] != b"segs":
        raise ValueError(f"Expected 'segs' magic at offset 0x{block_offset:X}, got {buf[:4]!r}")

    seg_count = struct.unpack_from(">H", buf, 6)[0]
    decomp_total = struct.unpack_from(">I", buf, 8)[0]
    comp_total = struct.unpack_from(">I", buf, 12)[0]

    # Parse segment table at +0x10
    seg_table: list[tuple[int, int, int]] = []
    for s in range(seg_count):
        seg_off = 0x10 + s * 8
        c_size = struct.unpack_from(">H", buf, seg_off)[0]
        u_size = struct.unpack_from(">H", buf, seg_off + 2)[0]
        raw_off = struct.unpack_from(">I", buf, seg_off + 4)[0]
        is_compressed = bool(raw_off & 1)
        offset = raw_off & ~1
        if u_size == 0:
            u_size = 65536
        seg_table.append((c_size, u_size, offset))

    all_decomp = bytearray()
    for s_idx, (c_size, u_size, offset) in enumerate(seg_table):
        seg_data = buf[offset:offset + c_size]
        if not seg_data:
            continue

        try:
            dc = zlib.decompressobj(-15)
            result = dc.decompress(seg_data)
            all_decomp.extend(result)
        except zlib.error:
            # Retry: skip leading zero bytes (alignment padding)
            trimmed = seg_data.lstrip(b"\x00")
            if trimmed and trimmed != seg_data:
                dc2 = zlib.decompressobj(-15)
                result = dc2.decompress(trimmed)
                all_decomp.extend(result)
            else:
                raise

    if len(all_decomp) != decomp_total:
        print(f"  WARNING: decompressed {len(all_decomp)} bytes, expected {decomp_total}",
              file=sys.stderr)

    return bytes(all_decomp)


# ── UCFX byte swapping (BE → LE) ─────────────────────────────────────


def _swap32(data: bytearray, offset: int) -> None:
    """In-place swap a 32-bit value at offset."""
    data[offset], data[offset + 1], data[offset + 2], data[offset + 3] = (
        data[offset + 3], data[offset + 2], data[offset + 1], data[offset]
    )


def _swap16(data: bytearray, offset: int) -> None:
    """In-place swap a 16-bit value at offset."""
    data[offset], data[offset + 1] = data[offset + 1], data[offset]


def _reverse_tag(data: bytearray, offset: int) -> None:
    """Reverse a 4-byte ASCII tag in place (e.g., XFCU → UCFX)."""
    data[offset], data[offset + 1], data[offset + 2], data[offset + 3] = (
        data[offset + 3], data[offset + 2], data[offset + 1], data[offset]
    )


# Known 4-byte BE tags and their LE equivalents
BE_TAGS = {
    b"XFCU", b"RDHC", b"PMOC", b"MOEG", b"HSEM", b"GMRP", b"MRTS",
    b"FUBI", b"LRTM", b"SGLF", b"TATS", b"EXEC", b"MUNE", b"TGLF",
    b"XDNI", b"EMAN", b"YDOB", b"SDNB", b"OFNI", b"TMRP", b"TIWS",
    b"REIH", b"MUSC", b"NNIB",
}


def byteswap_block_header(data: bytearray) -> int:
    """Swap the decompressed block's leading header table (count + 16-byte entries).

    Returns the number of UCFX entries.
    """
    _swap32(data, 0)
    count = struct.unpack_from("<I", data, 0)[0]

    for i in range(count):
        off = 4 + i * 16
        if off + 16 > len(data):
            break
        _swap32(data, off + 0)   # name_hash
        _swap32(data, off + 4)   # type_hash
        _swap32(data, off + 8)   # field_c
        _swap32(data, off + 12)  # chunk_size

    return count


def byteswap_ucfx_containers(data: bytearray, entry_count: int) -> dict:
    """Walk UCFX containers and swap chunk headers from BE to LE.

    Performs chunk-header-level swapping: magic tags, UCFX header fields,
    chunk row fields, and CSUM trailers. Leaves raw pixel/vertex data
    and compressed sub-streams untouched (those need structure-aware
    swapping in a second pass).

    Returns statistics dict.
    """
    stats = {"ucfx_found": 0, "chunks_swapped": 0, "csum_swapped": 0,
             "tags_seen": {}, "errors": []}

    header_end = 4 + entry_count * 16
    sizes = []
    for i in range(entry_count):
        off = 4 + i * 16
        size = struct.unpack_from("<I", data, off + 12)[0]
        sizes.append(size)

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
            _reverse_tag(data, pos)
            _swap32(data, pos + 4)  # UCFX u0 (data_base offset / header size)
            stats["ucfx_found"] += 1

            ucfx_u0 = struct.unpack_from("<I", data, pos + 4)[0]

            inner_pos = pos + 8
            while inner_pos + 20 <= chunk_end:
                inner_tag = bytes(data[inner_pos:inner_pos + 4])
                is_csum = (inner_tag == b"MUSC" or inner_tag[::-1] == b"CSUM")

                if is_csum:
                    _reverse_tag(data, inner_pos)
                    _swap32(data, inner_pos + 4)
                    stats["csum_swapped"] += 1
                    inner_pos += 8
                    continue

                is_known_be = inner_tag in BE_TAGS
                is_known_le = inner_tag[::-1] in BE_TAGS

                if is_known_be or is_known_le:
                    if is_known_be:
                        _reverse_tag(data, inner_pos)

                    le_tag = bytes(data[inner_pos:inner_pos + 4]).decode("ascii", errors="replace")
                    stats["tags_seen"][le_tag] = stats["tags_seen"].get(le_tag, 0) + 1

                    _swap32(data, inner_pos + 4)
                    _swap32(data, inner_pos + 8)
                    _swap32(data, inner_pos + 12)
                    _swap32(data, inner_pos + 16)
                    stats["chunks_swapped"] += 1

                    chunk_u1 = struct.unpack_from("<I", data, inner_pos + 8)[0]

                    if le_tag == "INFO":
                        _swap_info_chunk(data, pos, inner_pos, ucfx_u0)
                    elif le_tag == "BNDS":
                        _swap_bnds_chunk(data, pos, inner_pos, ucfx_u0)
                    elif le_tag == "MTRL":
                        _swap_mtrl_chunk(data, pos, inner_pos, ucfx_u0)
                    elif le_tag == "PRMG":
                        _swap_prmg_chunk(data, pos, inner_pos, ucfx_u0)
                    elif le_tag == "STRM":
                        _swap_strm_header(data, pos, inner_pos, ucfx_u0)
                    elif le_tag == "IBUF":
                        _swap_ibuf_data(data, pos, inner_pos, ucfx_u0)
                    elif le_tag == "MESH":
                        _swap_mesh_header(data, pos, inner_pos, ucfx_u0)
                    elif le_tag == "HIER":
                        _swap_hier_chunk(data, pos, inner_pos, ucfx_u0)
                    elif le_tag == "INDX":
                        _swap_indx_chunk(data, pos, inner_pos, ucfx_u0)

                    inner_pos += 20
                else:
                    inner_pos += 1
        else:
            stats["errors"].append(
                f"Entry {entry_idx}: expected XFCU at 0x{pos:X}, got {tag_at_pos!r}"
            )
            pos = chunk_end
            continue

        if chunk_end - 8 >= pos:
            csum_pos = chunk_end - 8
            csum_tag = bytes(data[csum_pos:csum_pos + 4])
            if csum_tag in (b"MUSC", b"CSUM"):
                if csum_tag == b"MUSC":
                    _reverse_tag(data, csum_pos)
                _swap32(data, csum_pos + 4)
                stats["csum_swapped"] += 1

        pos = chunk_end

    return stats


def _swap_info_chunk(data: bytearray, ucfx_start: int, chunk_pos: int, ucfx_u0: int) -> None:
    """Swap INFO chunk body fields (texture metadata)."""
    body_off_rel = struct.unpack_from("<I", data, chunk_pos + 4)[0]
    body_abs = ucfx_start + ucfx_u0 + body_off_rel if ucfx_u0 > 0 else ucfx_start + 8 + body_off_rel
    body_len = struct.unpack_from("<I", data, chunk_pos + 8)[0]
    if body_abs + 26 > len(data):
        return
    _swap16(data, body_abs + 0)   # width
    _swap16(data, body_abs + 2)   # height
    _swap16(data, body_abs + 6)   # mip_count
    _swap32(data, body_abs + 22)  # total_size


def _swap_bnds_chunk(data: bytearray, ucfx_start: int, chunk_pos: int, ucfx_u0: int) -> None:
    """Swap BNDS (bounding box) chunk — 10 floats (40 bytes)."""
    body_off_rel = struct.unpack_from("<I", data, chunk_pos + 4)[0]
    body_abs = ucfx_start + ucfx_u0 + body_off_rel if ucfx_u0 > 0 else ucfx_start + 8 + body_off_rel
    for i in range(10):
        off = body_abs + i * 4
        if off + 4 <= len(data):
            _swap32(data, off)


def _swap_mtrl_chunk(data: bytearray, ucfx_start: int, chunk_pos: int, ucfx_u0: int) -> None:
    """Swap MTRL (material) chunk fields."""
    body_off_rel = struct.unpack_from("<I", data, chunk_pos + 4)[0]
    body_len = struct.unpack_from("<I", data, chunk_pos + 8)[0]
    body_abs = ucfx_start + ucfx_u0 + body_off_rel if ucfx_u0 > 0 else ucfx_start + 8 + body_off_rel
    end = body_abs + body_len
    if end > len(data):
        return
    pos = body_abs
    while pos + 4 <= end:
        _swap32(data, pos)
        pos += 4


def _swap_prmg_chunk(data: bytearray, ucfx_start: int, chunk_pos: int, ucfx_u0: int) -> None:
    """Swap PRMG (primitive group) chunk body as u32 array."""
    body_off_rel = struct.unpack_from("<I", data, chunk_pos + 4)[0]
    body_len = struct.unpack_from("<I", data, chunk_pos + 8)[0]
    body_abs = ucfx_start + ucfx_u0 + body_off_rel if ucfx_u0 > 0 else ucfx_start + 8 + body_off_rel
    end = body_abs + body_len
    if end > len(data):
        return
    pos = body_abs
    while pos + 4 <= end:
        _swap32(data, pos)
        pos += 4


def _swap_strm_header(data: bytearray, ucfx_start: int, chunk_pos: int, ucfx_u0: int) -> None:
    """Swap STRM vertex stream metadata but NOT the vertex data itself.

    STRM body starts with a small header (stride, vertex count, etc.)
    followed by raw vertex data. Vertex data contains mixed types
    (f16, f32, u8, packed normals) that need format-aware swapping.
    For now we swap the leading u32 fields and leave vertex data as-is.
    """
    body_off_rel = struct.unpack_from("<I", data, chunk_pos + 4)[0]
    body_len = struct.unpack_from("<I", data, chunk_pos + 8)[0]
    body_abs = ucfx_start + ucfx_u0 + body_off_rel if ucfx_u0 > 0 else ucfx_start + 8 + body_off_rel
    if body_abs + 8 > len(data):
        return
    _swap32(data, body_abs + 0)
    _swap32(data, body_abs + 4)


def _swap_ibuf_data(data: bytearray, ucfx_start: int, chunk_pos: int, ucfx_u0: int) -> None:
    """Swap IBUF (index buffer) — array of u16 indices."""
    body_off_rel = struct.unpack_from("<I", data, chunk_pos + 4)[0]
    body_len = struct.unpack_from("<I", data, chunk_pos + 8)[0]
    body_abs = ucfx_start + ucfx_u0 + body_off_rel if ucfx_u0 > 0 else ucfx_start + 8 + body_off_rel
    end = body_abs + body_len
    if end > len(data):
        return
    pos = body_abs
    while pos + 2 <= end:
        _swap16(data, pos)
        pos += 2


def _swap_mesh_header(data: bytearray, ucfx_start: int, chunk_pos: int, ucfx_u0: int) -> None:
    """Swap MESH chunk header fields."""
    body_off_rel = struct.unpack_from("<I", data, chunk_pos + 4)[0]
    body_len = struct.unpack_from("<I", data, chunk_pos + 8)[0]
    body_abs = ucfx_start + ucfx_u0 + body_off_rel if ucfx_u0 > 0 else ucfx_start + 8 + body_off_rel
    end = body_abs + body_len
    if end > len(data):
        return
    pos = body_abs
    while pos + 4 <= end:
        _swap32(data, pos)
        pos += 4


def _swap_hier_chunk(data: bytearray, ucfx_start: int, chunk_pos: int, ucfx_u0: int) -> None:
    """Swap HIER (hierarchy) chunk — array of transform entries (floats + indices)."""
    body_off_rel = struct.unpack_from("<I", data, chunk_pos + 4)[0]
    body_len = struct.unpack_from("<I", data, chunk_pos + 8)[0]
    body_abs = ucfx_start + ucfx_u0 + body_off_rel if ucfx_u0 > 0 else ucfx_start + 8 + body_off_rel
    end = body_abs + body_len
    if end > len(data):
        return
    pos = body_abs
    while pos + 4 <= end:
        _swap32(data, pos)
        pos += 4


def _swap_indx_chunk(data: bytearray, ucfx_start: int, chunk_pos: int, ucfx_u0: int) -> None:
    """Swap INDX chunk — array of u16 MESH→HIER mappings."""
    body_off_rel = struct.unpack_from("<I", data, chunk_pos + 4)[0]
    body_len = struct.unpack_from("<I", data, chunk_pos + 8)[0]
    body_abs = ucfx_start + ucfx_u0 + body_off_rel if ucfx_u0 > 0 else ucfx_start + 8 + body_off_rel
    end = body_abs + body_len
    if end > len(data):
        return
    pos = body_abs
    while pos + 2 <= end:
        _swap16(data, pos)
        pos += 2


def byteswap_ucfx_block(block_data: bytes) -> tuple[bytes, dict]:
    """Full byte-swap of a decompressed Xbox UCFX block to PC little-endian."""
    data = bytearray(block_data)
    entry_count = byteswap_block_header(data)
    stats = byteswap_ucfx_containers(data, entry_count)

    recompute_csums(data, entry_count)

    return bytes(data), stats


def recompute_csums(data: bytearray, entry_count: int) -> int:
    """Recompute all CSUM trailers after byte swapping."""
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


# ── PC patch WAD builder ──────────────────────────────────────────────


def _align_up(value: int, alignment: int) -> int:
    return (value + alignment - 1) & ~(alignment - 1)


def build_pc_patch_wad(
    blocks: list[dict],
    pc_cert_blob: bytes,
) -> bytes:
    """Build a complete PC FFCS patch WAD from converted blocks.

    Each block dict must have: 'sges_data', 'path', 'aset_entries',
    'indx_packed_field', 'indx_flags'.
    """
    num_blocks = len(blocks)

    indx_offset = 0x8000
    indx_size = num_blocks * 12

    aset_offset = indx_offset + indx_size
    all_aset = []
    for blk in blocks:
        all_aset.extend(blk["aset_entries"])
    aset_size = len(all_aset) * 16

    pths_offset = aset_offset + aset_size
    pths_bytes = bytearray()
    for blk in blocks:
        pths_bytes.extend(blk["path"].encode("utf-8") + b"\x00")
    pths_bytes.extend(PTHS_TRAILER + b"\x00")
    pths_size = len(pths_bytes)

    data_offset = 0x208000
    data_page_index = data_offset // PAGE_SIZE

    block_data_parts: list[tuple[bytes, int]] = []
    current_data_offset = data_offset
    for blk in blocks:
        sges = blk["sges_data"]
        block_pages = _align_up(len(sges), PAGE_SIZE) // PAGE_SIZE
        block_data_parts.append((sges, block_pages))
        current_data_offset += block_pages * PAGE_SIZE

    file_size = current_data_offset

    header = bytearray(256)
    struct.pack_into("<4sII", header, 0, b"FFCS", 2, 7)

    chunk_rows_off = 0x0C
    struct.pack_into("<4sII", header, chunk_rows_off + 0,
                     b"INDX", indx_offset, num_blocks)
    struct.pack_into("<4sII", header, chunk_rows_off + 12,
                     b"DATA", data_offset, 36)
    struct.pack_into("<4sII", header, chunk_rows_off + 24,
                     b"CSUM", 0, len(all_aset))
    struct.pack_into("<4sII", header, chunk_rows_off + 36,
                     b"ASET", aset_offset, len(all_aset))
    struct.pack_into("<4sII", header, chunk_rows_off + 48,
                     b"PTHS", pths_offset, num_blocks)

    header[0x48:0x48 + 144] = pc_cert_blob

    out = bytearray(file_size)
    out[0:256] = header

    page = data_page_index
    for i, blk in enumerate(blocks):
        sges_data, block_pages = block_data_parts[i]
        struct.pack_into("<III", out, indx_offset + i * 12,
                         page,
                         blk["indx_packed_field"],
                         (blk["indx_flags"] << 16) | block_pages)
        page += block_pages

    aset_block_idx = 0
    aset_write_pos = aset_offset
    for blk_idx, blk in enumerate(blocks):
        for aset in blk["aset_entries"]:
            u2_remapped = (blk_idx << 16) | (aset["u32_2"] & 0xFFFF)
            struct.pack_into("<IIII", out, aset_write_pos,
                             aset["asset_hash"],
                             aset["u32_1"],
                             u2_remapped,
                             aset["u32_3"])
            aset_write_pos += 16

    out[pths_offset:pths_offset + len(pths_bytes)] = pths_bytes

    write_off = data_offset
    for sges_data, block_pages in block_data_parts:
        out[write_off:write_off + len(sges_data)] = sges_data
        write_off += block_pages * PAGE_SIZE

    return bytes(out)


# ── Main pipeline ─────────────────────────────────────────────────────


def run_pipeline(
    rar_path: Path,
    pc_wad_path: Path,
    output_path: Path,
    *,
    max_blocks: int | None = None,
    work_dir: Path | None = None,
) -> int:
    """Full Xbox 360 DLC → PC patch WAD pipeline."""

    if work_dir is None:
        work_dir = Path(tempfile.mkdtemp(prefix="dlc_port_"))
    work_dir.mkdir(parents=True, exist_ok=True)

    # Step 1: Extract STFS container from RAR
    print("=" * 70)
    print("STEP 1: Extract STFS container from Xbox 360 RAR")
    print("=" * 70)
    reader = extract_stfs_from_rar(rar_path, work_dir)

    # Step 2: Parse big-endian FFCS (read header region via hash-aware mapping)
    print("\n" + "=" * 70)
    print("STEP 2: Parse big-endian FFCS header")
    print("=" * 70)
    doh_header = reader.read(0, 0x48000)
    ffcs = parse_be_ffcs(doh_header)
    print(f"  Version: {ffcs['version']}")
    print(f"  Chunks: {ffcs['chunk_count']}")
    for c in ffcs["chunks"]:
        print(f"    {c['tag_be']:6s} → {c['tag']:6s}  offset=0x{c['offset']:X}  meta={c['meta']}")

    indx_chunk = next((c for c in ffcs["chunks"] if c["tag"] == "INDX"), None)
    aset_chunk = next((c for c in ffcs["chunks"] if c["tag"] == "ASET"), None)
    pths_chunk = next((c for c in ffcs["chunks"] if c["tag"] == "PTHS"), None)
    data_chunk = next((c for c in ffcs["chunks"] if c["tag"] == "DATA"), None)

    if not all([indx_chunk, aset_chunk, pths_chunk, data_chunk]):
        print("ERROR: Missing required FFCS chunks", file=sys.stderr)
        return 1

    indx_entries = parse_be_indx(doh_header, indx_chunk["offset"], indx_chunk["meta"])
    aset_entries = parse_be_aset(doh_header, aset_chunk["offset"], aset_chunk["meta"])

    # PTHS may extend beyond the default header region — read enough
    pths_max = pths_chunk["offset"] + pths_chunk["meta"] * 256
    if pths_max > len(doh_header):
        doh_header_ext = reader.read(0, min(pths_max, 0x200000))
    else:
        doh_header_ext = doh_header
    paths = parse_be_pths(doh_header_ext, pths_chunk["offset"],
                          pths_chunk["meta"], len(doh_header_ext))

    print(f"\n  INDX entries: {len(indx_entries)}")
    print(f"  ASET entries: {len(aset_entries)}")
    print(f"  PTHS paths:   {len(paths)}")
    if paths:
        print(f"  First path:   {paths[0]}")
        print(f"  Last path:    {paths[-1]}")

    # Read PC WAD certificate blob
    print(f"\n  Reading PC certificate from {pc_wad_path}...")
    pc_raw = pc_wad_path.read_bytes()
    pc_cert = pc_raw[0x48:0x48 + 144]
    if pc_cert == FFCS_CERT_BLOB:
        print("  PC cert matches known blob ✓")
    else:
        print("  PC cert differs from known blob (using PC WAD's version)")

    # Determine block count
    num_blocks = min(len(indx_entries), len(paths))
    if max_blocks is not None:
        num_blocks = min(num_blocks, max_blocks)
    print(f"\n  Processing {num_blocks} of {len(indx_entries)} blocks")

    # Step 3-5: For each block: decompress, byte-swap, recompress
    print("\n" + "=" * 70)
    print("STEP 3-5: Decompress → byte-swap → recompress each block")
    print("=" * 70)

    converted_blocks: list[dict] = []
    total_decomp = 0
    total_comp = 0
    swap_tag_totals: dict[str, int] = {}
    skipped = 0

    for i in range(num_blocks):
        entry = indx_entries[i]
        path = paths[i] if i < len(paths) else f"block_{i:05d}"
        block_start = entry["file_offset"]
        block_size = entry["page_count"] * PAGE_SIZE

        block_aset = [a for a in aset_entries if a["block_index"] == i]

        path_short = path.rsplit("\\", 1)[-1] if "\\" in path else path

        if i < 5 or i % 200 == 0:
            print(f"\n  [{i:4d}/{num_blocks}] {path_short}")
            print(f"    FFCS offset: 0x{block_start:X}  size: {block_size:,}  ASET: {len(block_aset)}")
            verbose = True
        else:
            verbose = False

        # Read block data from STFS via hash-aware mapping
        try:
            block_raw = reader.read(block_start, block_size)
        except Exception as e:
            if verbose:
                print(f"    SKIP: STFS read failed: {e}")
            skipped += 1
            continue

        # Decompress Xbox sges
        try:
            decomp = decompress_xbox_sges(block_raw, 0, len(block_raw))
        except Exception as e:
            if verbose:
                print(f"    SKIP: decompression failed: {e}")
            skipped += 1
            continue
        total_decomp += len(decomp)
        if verbose:
            print(f"    Decompressed: {len(decomp):,} bytes")

        # Byte-swap UCFX
        try:
            swapped, swap_stats = byteswap_ucfx_block(decomp)
        except Exception as e:
            if verbose:
                print(f"    SKIP: byte-swap failed: {e}")
            skipped += 1
            continue

        for tag, cnt in swap_stats["tags_seen"].items():
            swap_tag_totals[tag] = swap_tag_totals.get(tag, 0) + cnt

        if verbose and swap_stats["errors"]:
            for err in swap_stats["errors"][:3]:
                print(f"    WARN: {err}")

        if verbose:
            print(f"    Swapped: {swap_stats['ucfx_found']} UCFX, "
                  f"{swap_stats['chunks_swapped']} chunks, "
                  f"{swap_stats['csum_swapped']} CSUMs")

        # Recompress as PC sges
        try:
            pc_sges = compress_sges(swapped, segment_size=65536, level=6, major=4)
        except Exception as e:
            if verbose:
                print(f"    SKIP: recompression failed: {e}")
            skipped += 1
            continue
        total_comp += len(pc_sges)
        if verbose:
            ratio = len(pc_sges) / len(swapped) * 100 if len(swapped) > 0 else 0
            print(f"    Recompressed: {len(pc_sges):,} bytes ({ratio:.1f}%)")

        converted_blocks.append({
            "sges_data": pc_sges,
            "path": path,
            "aset_entries": block_aset,
            "indx_packed_field": entry["packed_field"],
            "indx_flags": entry["flags"],
        })

        if (i + 1) % 500 == 0:
            print(f"\n  ... progress: {len(converted_blocks)} converted, {skipped} skipped of {i + 1} processed")

    if not converted_blocks:
        print("\nERROR: No blocks were successfully converted", file=sys.stderr)
        return 1

    # Step 6: Build PC patch WAD
    print("\n" + "=" * 70)
    print("STEP 6: Build PC patch WAD")
    print("=" * 70)

    patch_wad = build_pc_patch_wad(converted_blocks, pc_cert)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_bytes(patch_wad)

    # Summary
    print("\n" + "=" * 70)
    print("SUMMARY")
    print("=" * 70)
    print(f"  Blocks converted:     {len(converted_blocks)} / {num_blocks}")
    print(f"  Blocks skipped:       {skipped}")
    print(f"  Total decompressed:   {total_decomp:,} bytes")
    print(f"  Total recompressed:   {total_comp:,} bytes")
    print(f"  Output WAD:           {output_path} ({len(patch_wad):,} bytes)")
    print(f"  Output WAD size:      {len(patch_wad) / 1024 / 1024:.1f} MB")
    print(f"\n  Chunk tags seen during swap:")
    for tag, cnt in sorted(swap_tag_totals.items(), key=lambda x: -x[1]):
        print(f"    {tag}: {cnt}")

    print(f"\n  Byte-swapping implemented:")
    print(f"    ✓ Block header table (count + 16-byte entry records)")
    print(f"    ✓ UCFX container headers (magic + u0 offset)")
    print(f"    ✓ Chunk row headers (magic + 4 u32 fields)")
    print(f"    ✓ CSUM trailers (tag + u32 checksum, recomputed)")
    print(f"    ✓ INFO chunk body (width, height, mip_count, total_size)")
    print(f"    ✓ BNDS chunk body (10 floats)")
    print(f"    ✓ MTRL chunk body (u32 array)")
    print(f"    ✓ PRMG chunk body (u32 array)")
    print(f"    ✓ STRM header fields (stride, vertex count)")
    print(f"    ✓ IBUF data (u16 index array)")
    print(f"    ✓ MESH header (u32 array)")
    print(f"    ✓ HIER data (transform floats + indices)")
    print(f"    ✓ INDX data (u16 MESH→HIER mapping)")
    print(f"\n  Needs more work (second pass):")
    print(f"    ○ STRM vertex data (mixed f16/f32/u8 — needs per-vertex-format swapping)")
    print(f"    ○ BODY texture data (DXT pixel blocks — may need Xbox 360 tile swizzle)")
    print(f"    ○ Havok binary data (class-aware field swapping)")
    print(f"    ○ Lua bytecode (endianness flag + opcode/constant swapping)")
    print(f"    ○ COMP/CHDR placement data (42-byte records with mixed field types)")

    return 0


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Port Xbox 360 DLC to PC patch WAD for Mercenaries 2",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    ap.add_argument("--rar", type=Path, required=True,
                    help="Path to Xbox 360 DLC RAR file")
    ap.add_argument("--pc-wad", type=Path, required=True,
                    help="Path to PC vz.wad (for certificate blob)")
    ap.add_argument("--output", "-o", type=Path, required=True,
                    help="Output PC patch WAD path (e.g., vz-patch.wad)")
    ap.add_argument("--blocks", type=int, default=None,
                    help="Limit to first N blocks (for testing)")
    ap.add_argument("--work-dir", type=Path, default=None,
                    help="Working directory for intermediate files (default: temp)")
    args = ap.parse_args()

    if not args.rar.is_file():
        print(f"RAR not found: {args.rar}", file=sys.stderr)
        return 1
    if not args.pc_wad.is_file():
        print(f"PC WAD not found: {args.pc_wad}", file=sys.stderr)
        return 1

    return run_pipeline(
        args.rar,
        args.pc_wad,
        args.output,
        max_blocks=args.blocks,
        work_dir=args.work_dir,
    )


if __name__ == "__main__":
    sys.exit(main())
