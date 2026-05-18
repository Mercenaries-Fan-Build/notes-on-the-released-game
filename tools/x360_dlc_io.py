#!/usr/bin/env python3
"""Xbox 360 DLC I/O module — STFS container reading and big-endian sges decompression.

Combines the best STFS strategies from both port_xbox_dlc.py and dlc_port_x360_to_pc.py:
  - Dynamic hash-block detection via INDX + segs scan (port_xbox_dlc)
  - Standard 170-block hash formula fallback (dlc_port_x360_to_pc)
  - File table parsing + RAR extraction

Public API:
  - StfsReader(stfs_data)          — hash-block-aware DOH reader
  - extract_stfs_from_rar(rar_path, work_dir) → StfsReader
  - parse_be_ffcs(doh)             — big-endian FFCS header parser
  - parse_be_indx / parse_be_aset / parse_be_pths
  - decompress_be_sges(data, offset, max_size) → bytes
"""
from __future__ import annotations

import struct
import subprocess
import sys
import zlib
from dataclasses import dataclass
from pathlib import Path


# ── Constants ─────────────────────────────────────────────────────────

STFS_BLOCK_SIZE = 0x1000  # 4 KB
STFS_DATA_OFFSET = 0xC000
PAGE_SIZE = 0x8000  # 32 KB (FFCS page)

STFS_MAGIC_LIVE = b"LIVE"
STFS_MAGIC_PIRS = b"PIRS"
STFS_MAGIC_CON = b"CON "

SCFF_MAGIC = b"SCFF"
SEGS_MAGIC = b"segs"


# ── Data structures ───────────────────────────────────────────────────

@dataclass
class FFCSChunkRow:
    tag: str           # LE name (e.g. "INDX")
    offset: int
    meta: int


@dataclass
class INDXEntry:
    page_index: int
    packed_field: int
    flags: int
    page_count: int

    @property
    def file_offset(self) -> int:
        return self.page_index * PAGE_SIZE


@dataclass
class ASETEntry:
    asset_hash: int
    u1: int
    u2: int
    u3: int

    @property
    def block_index(self) -> int:
        return (self.u2 >> 16) & 0xFFFF


# ── STFS reading ─────────────────────────────────────────────────────

def _build_stfs_block_map(stfs_data: bytes) -> list[int]:
    """Build DOH-logical-block → physical-block lookup (dynamic hash detection)."""
    header_phys_start = STFS_DATA_OFFSET + STFS_BLOCK_SIZE
    header_bytes = stfs_data[header_phys_start:header_phys_start + 0x48000]
    if header_bytes[:4] != SCFF_MAGIC:
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

    expected_doh_blocks: list[int] = []
    for i in range(indx_count):
        off = indx_off + i * 12
        page_idx = struct.unpack_from(">I", header_bytes, off)[0]
        expected_doh_blocks.append(page_idx * (PAGE_SIZE // STFS_BLOCK_SIZE))

    segs_phys: list[int] = []
    pos = STFS_DATA_OFFSET
    end = len(stfs_data)
    while pos < end - 3:
        idx = stfs_data.find(SEGS_MAGIC, pos)
        if idx < 0:
            break
        if (idx - STFS_DATA_OFFSET) % STFS_BLOCK_SIZE == 0:
            segs_phys.append((idx - STFS_DATA_OFFSET) // STFS_BLOCK_SIZE)
        pos = idx + 1

    segs_sorted = sorted(segs_phys)
    doh_sorted = sorted(expected_doh_blocks)

    if not segs_sorted:
        # Fallback: no segs magic found (e.g. raw XFCU blocks with no
        # compression wrapper).  Build hash block set using the female STFS
        # layout: L0 tables at 0, 171, 342, 513, ...; L1 table at 170.
        total_stfs_blocks = (len(stfs_data) - STFS_DATA_OFFSET) // STFS_BLOCK_SIZE
        max_phys = total_stfs_blocks + 100
        hash_set: set[int] = {0, 170}  # block 0 = file table, 170 = L1 hash
        k = 0
        while True:
            hb = k * 171
            if hb > max_phys:
                break
            hash_set.add(hb)
            k += 1
        data_block_phys: list[int] = []
        for p in range(max_phys + 1):
            if p not in hash_set:
                data_block_phys.append(p)
        return data_block_phys

    hash_blocks: set[int] = {0}
    n = min(len(segs_sorted), len(doh_sorted))
    for i in range(n - 1):
        doh_gap = doh_sorted[i + 1] - doh_sorted[i]
        phys_gap = segs_sorted[i + 1] - segs_sorted[i]
        if phys_gap > doh_gap:
            for h in range(segs_sorted[i] + doh_gap, segs_sorted[i + 1]):
                hash_blocks.add(h)

    max_phys = max(segs_sorted) + 200
    data_block_phys_2: list[int] = []
    for p in range(max_phys + 1):
        if p not in hash_blocks:
            data_block_phys_2.append(p)

    return data_block_phys_2


class StfsReader:
    """Hash-block-aware reader for DOH data inside an STFS container."""

    def __init__(self, stfs_data: bytes) -> None:
        self.stfs_data = stfs_data
        self.block_map = _build_stfs_block_map(stfs_data)

    def read(self, doh_offset: int, length: int) -> bytes:
        """Read *length* bytes from the logical DOH at *doh_offset*."""
        out = bytearray()
        remaining = length
        block_idx = doh_offset // STFS_BLOCK_SIZE
        skip = doh_offset % STFS_BLOCK_SIZE

        while remaining > 0:
            if block_idx >= len(self.block_map):
                raise ValueError(
                    f"DOH block {block_idx} exceeds block map ({len(self.block_map)} entries)")
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
    ft_start = STFS_DATA_OFFSET
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
            "name": name, "is_dir": is_dir, "consecutive": consecutive,
            "valid_blocks": valid_blocks, "alloc_blocks": alloc_blocks,
            "first_block": first_block, "path_ind": path_ind,
            "file_size": file_size,
        })
    return entries


def extract_stfs_from_rar(rar_path: Path, work_dir: Path) -> StfsReader:
    """Extract STFS from RAR and return a reader."""
    stfs_dir = work_dir / "stfs"
    stfs_dir.mkdir(parents=True, exist_ok=True)

    subprocess.run(
        ["bsdtar", "-xf", str(rar_path), "-C", str(stfs_dir)],
        check=True, capture_output=True,
    )

    stfs_file = None
    for f in sorted(stfs_dir.rglob("*"), key=lambda p: p.stat().st_size, reverse=True):
        if not f.is_file() or f.stat().st_size < 1_000_000:
            continue
        header = f.read_bytes()[:4]
        if header in (STFS_MAGIC_CON, STFS_MAGIC_LIVE, STFS_MAGIC_PIRS):
            stfs_file = f
            break
    if stfs_file is None:
        raise FileNotFoundError("Could not find STFS container in archive")

    print(f"  STFS: {stfs_file.name} ({stfs_file.stat().st_size:,} bytes)")
    stfs_data = stfs_file.read_bytes()

    magic = stfs_data[:4]
    if magic not in (STFS_MAGIC_CON, STFS_MAGIC_LIVE, STFS_MAGIC_PIRS):
        raise ValueError(f"Not an STFS container: magic={magic!r}")

    return StfsReader(stfs_data)


def load_stfs_or_doh(path: Path) -> tuple[bytes, str]:
    """Load an STFS container or raw DOH file.

    Returns (doh_bytes, source_type).
    If the file starts with LIVE/PIRS/CON, builds DOH via StfsReader.
    If it starts with SCFF, it's a raw DOH.
    """
    header = path.read_bytes()[:4]
    if header in (STFS_MAGIC_LIVE, STFS_MAGIC_PIRS, STFS_MAGIC_CON):
        stfs_data = path.read_bytes()
        reader = StfsReader(stfs_data)
        ffcs_header = reader.read(0, 0x100)
        chunk_count = struct.unpack_from(">I", ffcs_header, 8)[0]
        # find DATA to determine DOH size
        data_off = 0
        for i in range(min(chunk_count, 5)):
            off = 0x0C + i * 12
            tag = ffcs_header[off:off + 4][::-1].decode("ascii", errors="replace")
            val = struct.unpack_from(">I", ffcs_header, off + 4)[0]
            if tag == "DATA":
                data_off = val
                break
        # Read the full DOH up to a generous limit past DATA
        file_table = parse_stfs_file_table(stfs_data)
        doh_entry = next((e for e in file_table if "doh" in e["name"].lower()), None)
        doh_size = doh_entry["file_size"] if doh_entry else data_off + 0x10000000
        doh_bytes = reader.read(0, doh_size)
        return doh_bytes, "stfs"
    elif header == SCFF_MAGIC:
        return path.read_bytes(), "doh"
    else:
        raise ValueError(f"Unknown file format: {header!r}")


# ── Big-endian FFCS parsing ──────────────────────────────────────────

def parse_be_ffcs(doh: bytes) -> tuple[int, list[FFCSChunkRow]]:
    """Parse a big-endian FFCS header. Returns (version, chunk_rows)."""
    if doh[:4] != SCFF_MAGIC:
        raise ValueError(f"Expected SCFF, got {doh[:4]!r}")

    version = struct.unpack_from(">I", doh, 4)[0]
    chunk_count = struct.unpack_from(">I", doh, 8)[0]

    rows: list[FFCSChunkRow] = []
    for i in range(min(chunk_count, 5)):
        off = 0x0C + i * 12
        tag = doh[off:off + 4][::-1].decode("ascii", errors="replace")
        val = struct.unpack_from(">I", doh, off + 4)[0]
        meta = struct.unpack_from(">I", doh, off + 8)[0]
        rows.append(FFCSChunkRow(tag=tag, offset=val, meta=meta))

    return version, rows


def parse_be_indx(doh: bytes, indx_offset: int, count: int) -> list[INDXEntry]:
    """Parse big-endian INDX entries."""
    entries = []
    for i in range(count):
        off = indx_offset + i * 12
        page_idx, packed, flags_pages = struct.unpack_from(">III", doh, off)
        entries.append(INDXEntry(
            page_index=page_idx,
            packed_field=packed,
            flags=(flags_pages >> 16) & 0xFFFF,
            page_count=flags_pages & 0xFFFF,
        ))
    return entries


def parse_be_aset(doh: bytes, aset_offset: int, count: int) -> list[ASETEntry]:
    """Parse big-endian ASET entries."""
    entries = []
    for i in range(count):
        off = aset_offset + i * 16
        u0, u1, u2, u3 = struct.unpack_from(">IIII", doh, off)
        entries.append(ASETEntry(asset_hash=u0, u1=u1, u2=u2, u3=u3))
    return entries


def parse_be_pths(doh: bytes, pths_offset: int, count: int) -> list[str]:
    """Parse big-endian PTHS path strings."""
    paths: list[str] = []
    pos = pths_offset
    for _ in range(count):
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


# ── Big-endian sges decompression ────────────────────────────────────

def decompress_be_sges(data: bytes, offset: int, max_size: int) -> bytes:
    """Decompress a big-endian Xbox 360 sges block.

    Xbox 360 sges layout:
      +0x00: magic 'segs' (4 bytes)
      +0x04: version (BE u16) = 4
      +0x06: segment_count (BE u16)
      +0x08: total_decompressed (BE u32)
      +0x0C: total_compressed (BE u32)
      +0x10: segment table — N × 8 bytes:
               +0 u16 compressed_size
               +2 u16 decompressed_size (0 = 64KB)
               +4 u32 offset (not used)
      Payload starts after 16-byte-aligned header.
    """
    if data[offset:offset + 4] != SEGS_MAGIC:
        raise ValueError(f"Expected segs magic at 0x{offset:X}, "
                         f"got {data[offset:offset + 4]!r}")

    seg_count = struct.unpack_from(">H", data, offset + 6)[0]
    decomp_total = struct.unpack_from(">I", data, offset + 8)[0]

    seg_table: list[tuple[int, int]] = []
    for si in range(seg_count):
        so = offset + 16 + si * 8
        csz = struct.unpack_from(">H", data, so)[0]
        dsz = struct.unpack_from(">H", data, so + 2)[0]
        seg_table.append((csz, dsz))

    seg_table_bytes = seg_count * 8
    header_size = 16 + ((seg_table_bytes + 15) & ~15) if seg_count > 0 else 16
    payload = data[offset + header_size:offset + max_size]

    result = bytearray()
    pos = 0
    for csz, dsz in seg_table:
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
            f"Decompressed {len(result):,} bytes but expected {decomp_total:,}")
    return bytes(result)
