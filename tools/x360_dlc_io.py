#!/usr/bin/env python3
"""Xbox 360 DLC I/O module — STFS container reading and big-endian sges decompression.

Uses py360-based STFS logic (ported to Python 3) for cryptographically-correct
hash-table-aware block extraction.  The key insight: STFS containers interleave
hash table blocks among data blocks.  ``fix_blocknum()`` converts a logical
data-block index to a physical on-disk block index by accounting for L0/L1/L2
hash tables.  ``get_block_hash_entry()`` reads the 0x18-byte hash record for a
given logical block, which contains the ``next_block`` pointer needed for
non-consecutive file chain walking.

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

STFS_HASH_ENTRY_SIZE = 0x18
STFS_BLOCKS_PER_L0 = 0xAA       # 170 data blocks per L0 hash table
STFS_BLOCKS_PER_L1 = 0x70E4     # 28,900 data blocks per L1 hash table
STFS_BLOCKS_PER_L2 = 0x4AF768   # 4,913,000 data blocks per L2 hash table
STFS_HASH_BLOCK_SENTINEL = 0xFFFFFF  # chain terminator / no-next-block


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


# ── STFS core: py360-based block mapping (ported to Python 3) ─────────

def _detect_table_size_shift(stfs_data: bytes) -> int:
    """Determine whether hash tables are 1 block (shift=0) or 2 blocks (shift=1).

    LIVE/PIRS packages use shift=0, CON packages use shift=1.  The canonical
    check from py360 is ``((entry_id + 0xFFF) & 0xF000) >> 0xC == 0xB``.
    """
    magic = stfs_data[:4]
    if magic == STFS_MAGIC_CON:
        entry_id = struct.unpack_from(">I", stfs_data, 0x340)[0]
        if ((entry_id + 0xFFF) & 0xF000) >> 0xC == 0xB:
            return 0
        return 1
    return 0


def fix_blocknum(logical_block: int, table_size_shift: int = 0) -> int:
    """Convert a logical data-block index to its physical on-disk block index.

    STFS interleaves hash table blocks among data blocks:
      - L0 hash table every 170 (0xAA) data blocks
      - L1 hash table every 28,900 (0x70E4) data blocks
      - L2 hash table every 4,913,000 (0x4AF768) data blocks

    For LIVE/PIRS packages ``table_size_shift`` is 0 (1 block per hash table).
    For CON packages it is 1 (2 blocks per hash table, for backup copies).
    """
    adjust = 0
    if logical_block >= STFS_BLOCKS_PER_L0:
        adjust += ((logical_block // STFS_BLOCKS_PER_L0) + 1) << table_size_shift
    if logical_block >= STFS_BLOCKS_PER_L1:
        adjust += ((logical_block // STFS_BLOCKS_PER_L1) + 1) << table_size_shift
    if logical_block >= STFS_BLOCKS_PER_L2:
        adjust += ((logical_block // STFS_BLOCKS_PER_L2) + 1) << table_size_shift
    return logical_block + adjust


def _read_physical_block(stfs_data: bytes, phys_block: int,
                         length: int = STFS_BLOCK_SIZE) -> bytes:
    """Read ``length`` bytes from a physical block in the STFS container."""
    offset = STFS_DATA_OFFSET + phys_block * STFS_BLOCK_SIZE
    return stfs_data[offset:offset + length]


def _get_l0_hash_table_phys_block(logical_block: int,
                                  table_size_shift: int,
                                  table_offset: int = 0) -> int:
    """Calculate the physical block number of the L0 hash table for *logical_block*.

    Based on py360's ``get_blockhash()`` — the L0 table that covers a given
    logical block lives at a deterministic physical offset derived from the
    number of L0/L1/L2 tables before it.
    """
    # py360 table_spacing: [(0xAB, 0x718F, 0xFE7DA), (0xAC, 0x723A, 0xFD00B)]
    spacing = [(0xAB, 0x718F, 0xFE7DA),
               (0xAC, 0x723A, 0xFD00B)]

    table_num = (logical_block // STFS_BLOCKS_PER_L0) * spacing[table_size_shift][0]

    if logical_block >= STFS_BLOCKS_PER_L0:
        table_num += ((logical_block // STFS_BLOCKS_PER_L1) + 1) << table_size_shift

    if logical_block >= STFS_BLOCKS_PER_L1:
        table_num += 1 << table_size_shift

    table_num += table_offset - (1 << table_size_shift)
    return table_num


def get_block_hash_entry(stfs_data: bytes, logical_block: int,
                         table_size_shift: int,
                         table_offset: int = 0) -> tuple[int, int]:
    """Read the hash record for *logical_block* and return (next_block, info).

    The L0 hash table block is located via ``_get_l0_hash_table_phys_block()``,
    then the 0x18-byte record at position ``(logical_block % 0xAA)`` within
    that table is read.  ``next_block`` is a 24-bit BE value at record+0x15
    and ``info`` is the status byte at record+0x14.
    """
    record = logical_block % STFS_BLOCKS_PER_L0
    table_phys = _get_l0_hash_table_phys_block(
        logical_block, table_size_shift, table_offset)

    table_data = _read_physical_block(stfs_data, table_phys)
    entry_start = record * STFS_HASH_ENTRY_SIZE
    entry = table_data[entry_start:entry_start + STFS_HASH_ENTRY_SIZE]

    if len(entry) < STFS_HASH_ENTRY_SIZE:
        return STFS_HASH_BLOCK_SENTINEL, 0

    info = entry[0x14]
    next_block = struct.unpack(">I", b'\x00' + entry[0x15:0x18])[0]
    return next_block, info


def read_stfs_file_chain(stfs_data: bytes, first_block: int,
                         num_blocks: int, file_size: int,
                         table_size_shift: int) -> bytes:
    """Read a file from the STFS container by walking its block hash chain.

    Starting at *first_block*, reads data via ``fix_blocknum()`` and follows
    ``next_block`` pointers from the L0 hash table entries.
    """
    buf = bytearray()
    remaining = file_size
    block = first_block

    for _ in range(num_blocks):
        if block == STFS_HASH_BLOCK_SENTINEL or block < 0:
            break
        read_len = min(STFS_BLOCK_SIZE, remaining)
        phys = fix_blocknum(block, table_size_shift)
        data = _read_physical_block(stfs_data, phys, read_len)
        buf.extend(data)
        remaining -= read_len
        if remaining <= 0:
            break

        next_block, info = get_block_hash_entry(
            stfs_data, block, table_size_shift)
        if table_size_shift > 0 and info < 0x80:
            next_block, info = get_block_hash_entry(
                stfs_data, block, table_size_shift, table_offset=1)
        block = next_block

    return bytes(buf[:file_size])


class StfsReader:
    """Hash-block-aware reader for file data inside an STFS container.

    Uses py360-derived ``fix_blocknum()`` and hash-chain walking to correctly
    skip interleaved hash table blocks when reading logical file data.
    """

    def __init__(self, stfs_data: bytes) -> None:
        self.stfs_data = stfs_data
        self.table_size_shift = _detect_table_size_shift(stfs_data)
        self._file_table: list[dict] | None = None
        self._doh_chain: list[int] | None = None

    @property
    def file_table(self) -> list[dict]:
        if self._file_table is None:
            self._file_table = parse_stfs_file_table(self.stfs_data,
                                                     self.table_size_shift)
        return self._file_table

    def _build_doh_chain(self) -> list[int]:
        """Build the ordered list of logical block numbers for the DOH file
        by walking the hash chain from the file table entry."""
        doh_entry = next(
            (e for e in self.file_table if "doh" in e["name"].lower()), None)
        if doh_entry is None:
            raise ValueError("No DOH file found in STFS file table")

        chain: list[int] = []
        block = doh_entry["first_block"]
        max_blocks = doh_entry["alloc_blocks"] + 10  # small safety margin

        for _ in range(max_blocks):
            if block == STFS_HASH_BLOCK_SENTINEL or block < 0:
                break
            chain.append(block)
            next_block, info = get_block_hash_entry(
                self.stfs_data, block, self.table_size_shift)
            if self.table_size_shift > 0 and info < 0x80:
                next_block, info = get_block_hash_entry(
                    self.stfs_data, block, self.table_size_shift,
                    table_offset=1)
            block = next_block

        return chain

    @property
    def doh_chain(self) -> list[int]:
        if self._doh_chain is None:
            self._doh_chain = self._build_doh_chain()
        return self._doh_chain

    def read(self, doh_offset: int, length: int) -> bytes:
        """Read *length* bytes from the logical DOH at *doh_offset*."""
        out = bytearray()
        remaining = length
        chain_idx = doh_offset // STFS_BLOCK_SIZE
        skip = doh_offset % STFS_BLOCK_SIZE

        chain = self.doh_chain

        while remaining > 0:
            if chain_idx >= len(chain):
                raise ValueError(
                    f"DOH chain index {chain_idx} exceeds chain length "
                    f"({len(chain)} blocks)")
            logical_block = chain[chain_idx]
            phys = fix_blocknum(logical_block, self.table_size_shift)
            abs_offset = STFS_DATA_OFFSET + phys * STFS_BLOCK_SIZE + skip
            chunk = min(STFS_BLOCK_SIZE - skip, remaining)
            if abs_offset + chunk > len(self.stfs_data):
                raise ValueError(
                    f"STFS read past EOF: chain[{chain_idx}] logical "
                    f"{logical_block} phys {phys} offset 0x{abs_offset:X}")
            out.extend(self.stfs_data[abs_offset:abs_offset + chunk])
            remaining -= chunk
            chain_idx += 1
            skip = 0

        return bytes(out)

    def read_file(self, entry: dict) -> bytes:
        """Read the full contents of a file table entry by walking its block chain."""
        return read_stfs_file_chain(
            self.stfs_data,
            entry["first_block"],
            entry["alloc_blocks"],
            entry["file_size"],
            self.table_size_shift,
        )


def _parse_volume_descriptor(stfs_data: bytes) -> tuple[int, int, int]:
    """Parse the STFS volume descriptor at offset 0x379.

    Free60 spec layout (36 bytes starting at 0x379):
      +0x00: u8  descriptor_length (0x24 = 36)
      +0x01: u8  reserved
      +0x02: u8  block_separation (0 or 1)
      +0x03: u16 LE file_table_block_count
      +0x05: u24 LE file_table_first_block
      +0x08: 20 bytes SHA1 top hash table hash
      +0x1C: u32 BE total_allocated_block_count
      +0x20: u32 BE total_unallocated_block_count

    Returns (file_table_first_block, file_table_block_count, total_allocated).
    """
    desc_off = 0x379
    ft_block_count = struct.unpack_from("<H", stfs_data, desc_off + 3)[0]
    ft_first_block = (stfs_data[desc_off + 5]
                      | (stfs_data[desc_off + 6] << 8)
                      | (stfs_data[desc_off + 7] << 16))
    total_alloc = struct.unpack_from(">I", stfs_data, desc_off + 28)[0]
    return ft_first_block, ft_block_count, total_alloc


def parse_stfs_file_table(stfs_data: bytes,
                          table_size_shift: int = 0) -> list[dict]:
    """Parse the STFS file table by reading the volume descriptor and
    walking the file table's block chain via hash table pointers.
    """
    ft_first_block, ft_block_count, _ = _parse_volume_descriptor(stfs_data)

    ft_data = bytearray()
    block = ft_first_block
    for _ in range(ft_block_count):
        if block == STFS_HASH_BLOCK_SENTINEL or block < 0:
            break
        phys = fix_blocknum(block, table_size_shift)
        ft_data.extend(_read_physical_block(stfs_data, phys))
        next_block, info = get_block_hash_entry(
            stfs_data, block, table_size_shift)
        if table_size_shift > 0 and info < 0x80:
            next_block, info = get_block_hash_entry(
                stfs_data, block, table_size_shift, table_offset=1)
        block = next_block

    entries: list[dict] = []
    for i in range(len(ft_data) // 0x40):
        off = i * 0x40
        name_raw = ft_data[off:off + 0x28]
        if name_raw[0] == 0:
            break
        name = bytes(name_raw).split(b"\x00")[0].decode("ascii", errors="replace")
        flags = ft_data[off + 0x28]
        is_dir = bool(flags & 0x80)
        consecutive = bool(flags & 0x40)

        def u24le(d: bytes | bytearray, o: int) -> int:
            return d[o] | (d[o + 1] << 8) | (d[o + 2] << 16)

        valid_blocks = u24le(ft_data, off + 0x29)
        alloc_blocks = u24le(ft_data, off + 0x2C)
        first_block = u24le(ft_data, off + 0x2F)
        path_ind = struct.unpack_from(">H", ft_data, off + 0x32)[0]
        file_size = struct.unpack_from(">I", ft_data, off + 0x34)[0]

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
        doh_entry = next(
            (e for e in reader.file_table if "doh" in e["name"].lower()), None)
        if doh_entry is None:
            raise ValueError("No DOH file found in STFS file table")
        doh_bytes = reader.read(0, doh_entry["file_size"])
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
    """Parse big-endian ASET entries.

    u0 (asset_hash), u1, u2 are big-endian.  u2's high 16 bits encode the
    block_index — only valid as BE (5341/5341 valid vs 49/5341 as LE).

    The u3 field (type_id) is stored in **little-endian** even inside the
    otherwise-BE FFCS container.  Raw bytes ``1b 00 00 00`` = 27 (LE) vs
    452984832 (BE).  PC retail type_ids are small integers 0–35; LE
    interpretation matches for all 5341 entries across 24 unique values.
    """
    entries = []
    for i in range(count):
        off = aset_offset + i * 16
        u0, u1, u2 = struct.unpack_from(">III", doh, off)
        u3 = struct.unpack_from("<I", doh, off + 12)[0]
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
