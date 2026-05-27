#!/usr/bin/env python3
"""Byte-level comparison of audio data between Xbox 360 and PC WAD files.

Compares soundbank (type_id=21) and wavebank (type_id=6) entries across
platforms to identify exact field types (u32, u16x2, u8x4, f32, mixed)
for validating the BE→LE converter in ucfx_be_to_le.py.

Also compares standalone PWS file headers between Xbox retail and DLC output.

Usage:
    python tools/_wad_audio_compare.py
"""
from __future__ import annotations

import math
import struct
import sys
import zlib
from pathlib import Path

THIS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(THIS_DIR))

from x360_dlc_io import (
    SCFF_MAGIC,
    SEGS_MAGIC,
    PAGE_SIZE,
    parse_be_ffcs,
    parse_be_aset,
    parse_be_indx,
    decompress_be_sges,
)
from ffcs_wad import parse_ffcs, extract_slice, HEADER_MAGIC
from sges_decompress import decompress_sges_block, find_sges_offsets, SGES_MAGIC


# ── Constants ─────────────────────────────────────────────────────────

REPO_ROOT = THIS_DIR.parent
GAME_FILES = REPO_ROOT / "game-files"

XBOX_WAD = GAME_FILES / "Mercenaries 2 World in Flames (NTSCU)[NTSCJ) (JTAGRip)" / "vz.wad"
PC_WAD = GAME_FILES / "pc-game-vz.wad"

XBOX_AUDIO_DIR = GAME_FILES / "Mercenaries 2 World in Flames (NTSCU)[NTSCJ) (JTAGRip)" / "audios"
DLC_AUDIO_DIR = REPO_ROOT / "output" / "data" / "Audios"

TYPE_ID_WAVEBANK = 6
TYPE_ID_SOUNDBANK = 21

TYPE_HASH_WAVEBANK = 0xF753F6D0
TYPE_HASH_SOUNDBANK = 0x9F8BCA10

MAX_BLOCKS_TO_SCAN = 200
MAX_ENTRIES_TO_COMPARE = 20


# ── Helpers ───────────────────────────────────────────────────────────

def classify_u32(xbox_be: bytes, pc_le: bytes) -> str:
    """Classify a 4-byte aligned field by comparing Xbox BE and PC LE bytes."""
    if xbox_be == pc_le == b"\x00\x00\x00\x00":
        return "zero"

    # u32: Xbox bytes reversed == PC bytes
    if xbox_be[::-1] == pc_le:
        # Check if it's a valid IEEE754 float
        val = struct.unpack("<f", pc_le)[0]
        if not math.isnan(val) and not math.isinf(val) and abs(val) < 1e10 and abs(val) > 1e-10:
            return "f32"
        return "u32"

    # u16x2: two independent u16 values, each endian-swapped
    xbox_hi = xbox_be[0:2]
    xbox_lo = xbox_be[2:4]
    pc_hi = pc_le[0:2]
    pc_lo = pc_le[2:4]
    if xbox_hi[::-1] == pc_hi and xbox_lo[::-1] == pc_lo:
        return "u16x2"

    # u8x4: identical bytes (no swap needed)
    if xbox_be == pc_le:
        return "u8x4"

    return "mixed"


def hex_dump(data: bytes, max_bytes: int = 64) -> str:
    """Format bytes as hex dump."""
    if len(data) > max_bytes:
        return " ".join(f"{b:02x}" for b in data[:max_bytes]) + f" ... ({len(data)} total)"
    return " ".join(f"{b:02x}" for b in data)


def parse_pc_indx(wad_data: bytes, indx_offset: int, count: int) -> list[tuple[int, int, int]]:
    """Parse PC LE INDX entries. Returns [(page_index, packed, flags_pages), ...]."""
    entries = []
    for i in range(count):
        off = indx_offset + i * 12
        page_idx, packed, flags_pages = struct.unpack_from("<III", wad_data, off)
        entries.append((page_idx, packed, flags_pages))
    return entries


def parse_pc_aset(wad_data: bytes, aset_offset: int, count: int) -> list[tuple[int, int, int, int]]:
    """Parse PC LE ASET entries. Returns [(asset_hash, u1, u2, u3), ...]."""
    entries = []
    for i in range(count):
        off = aset_offset + i * 16
        u0, u1, u2, u3 = struct.unpack_from("<IIII", wad_data, off)
        entries.append((u0, u1, u2, u3))
    return entries


def parse_ucfx_entry_table_le(data: bytes) -> list[tuple[int, int, int, int]]:
    """Parse LE UCFX block entry table. Returns [(hash, type_hash, offset, size), ...]."""
    if len(data) < 4:
        return []
    count = struct.unpack_from("<I", data, 0)[0]
    if count > 1000 or count * 16 + 4 > len(data):
        return []
    entries = []
    for i in range(count):
        off = 4 + i * 16
        h, t, o, s = struct.unpack_from("<IIII", data, off)
        entries.append((h, t, o, s))
    return entries


def parse_ucfx_entry_table_be(data: bytes) -> list[tuple[int, int, int, int]]:
    """Parse BE UCFX block entry table. Returns [(hash, type_hash, offset, size), ...]."""
    if len(data) < 4:
        return []
    count = struct.unpack_from(">I", data, 0)[0]
    if count > 1000 or count * 16 + 4 > len(data):
        return []
    entries = []
    for i in range(count):
        off = 4 + i * 16
        h, t, o, s = struct.unpack_from(">IIII", data, off)
        entries.append((h, t, o, s))
    return entries


def _get_container_at(block_data: bytes, entries: list, entry_idx: int) -> bytes:
    """Get the raw container bytes for an entry in a block."""
    header_end = 4 + len(entries) * 16
    pos = header_end
    for i, (_, _, _, size) in enumerate(entries):
        if i == entry_idx:
            return block_data[pos:pos + size]
        pos += size
    return b""


def _extract_data_chunk_from_ucfx_le(container: bytes) -> bytes:
    """Parse LE UCFX container and extract the 'data' chunk body.

    UCFX container structure:
      [0:4]  magic "UCFX"
      [4:8]  data_area_off (offset from container start to body data)
      [8:12] u1
      [12:16] u2
      [16:20] n_descriptors
      [20:20+n*20] descriptor rows: tag(4) + row_u0(4) + body_size(4) + f3(4) + f4(4)
      [data_area_off:...] body data for all descriptors
    """
    if len(container) < 20 or container[:4] != b"UCFX":
        return b""

    data_area_off = struct.unpack_from("<I", container, 4)[0]
    n_desc = struct.unpack_from("<I", container, 16)[0]
    if n_desc > 500:
        return b""

    for i in range(n_desc):
        row_off = 20 + i * 20
        if row_off + 20 > len(container):
            break
        tag = container[row_off:row_off + 4].decode("ascii", errors="replace")
        row_u0 = struct.unpack_from("<I", container, row_off + 4)[0]
        body_size = struct.unpack_from("<I", container, row_off + 8)[0]

        if tag == "data":
            if data_area_off > 0:
                body_start = data_area_off + row_u0
            else:
                body_start = 8 + row_u0
            body_end = body_start + body_size
            if body_end > len(container):
                body_end = len(container)
            return container[body_start:body_end]

    return b""


def _extract_data_chunk_from_ucfx_be(container: bytes) -> bytes:
    """Parse BE UCFX container and extract the 'data' chunk body.

    Same structure as LE but with reversed magic and BE field values.
    """
    if len(container) < 20:
        return b""
    magic = container[:4]
    if magic != b"XFCU" and magic[::-1] != b"UCFX":
        return b""

    data_area_off = struct.unpack_from(">I", container, 4)[0]
    n_desc = struct.unpack_from(">I", container, 16)[0]
    if n_desc > 500:
        return b""

    for i in range(n_desc):
        row_off = 20 + i * 20
        if row_off + 20 > len(container):
            break
        tag = container[row_off:row_off + 4][::-1].decode("ascii", errors="replace")
        row_u0 = struct.unpack_from(">I", container, row_off + 4)[0]
        body_size = struct.unpack_from(">I", container, row_off + 8)[0]

        if tag == "data":
            if data_area_off > 0:
                body_start = data_area_off + row_u0
            else:
                body_start = 8 + row_u0
            body_end = body_start + body_size
            if body_end > len(container):
                body_end = len(container)
            return container[body_start:body_end]

    return b""


def extract_entry_data_body_le(block_data: bytes, entries: list, entry_idx: int) -> bytes:
    """Extract the 'data' chunk body for an entry from an LE UCFX block."""
    container = _get_container_at(block_data, entries, entry_idx)
    if not container:
        return b""
    # Strip CSUM trailer if present
    if len(container) >= 8 and container[-8:-4] == b"CSUM":
        container = container[:-8]
    return _extract_data_chunk_from_ucfx_le(container)


def extract_entry_data_body_be(block_data: bytes, entries: list, entry_idx: int) -> bytes:
    """Extract the 'data' chunk body for an entry from a BE UCFX block."""
    container = _get_container_at(block_data, entries, entry_idx)
    if not container:
        return b""
    # Strip CSUM trailer (as "MUSC" in BE)
    if len(container) >= 8 and (container[-8:-4] == b"MUSC" or container[-8:-4] == b"CSUM"):
        container = container[:-8]
    return _extract_data_chunk_from_ucfx_be(container)


# ── Part 1: WAD Audio Entry Comparison ────────────────────────────────

def part1_wad_comparison():
    print("=" * 80)
    print("PART 1: WAD AUDIO ENTRY COMPARISON")
    print("=" * 80)

    # Load WADs (memory-mapped would be better for 2.5GB files but let's
    # read headers only initially)
    print(f"\nPC WAD: {PC_WAD} ({PC_WAD.stat().st_size:,} bytes)")
    print(f"Xbox WAD: {XBOX_WAD} ({XBOX_WAD.stat().st_size:,} bytes)")

    # ── Parse PC WAD header and ASET ──
    print("\n--- Parsing PC WAD ---")
    with open(PC_WAD, "rb") as f:
        pc_header = f.read(0x300000)  # Read enough for headers + ASET + INDX

    pc_magic = pc_header[:4]
    assert pc_magic == HEADER_MAGIC, f"Bad PC magic: {pc_magic!r}"
    pc_version = struct.unpack_from("<I", pc_header, 4)[0]
    pc_chunk_count = struct.unpack_from("<I", pc_header, 8)[0]

    # Parse chunk rows
    pc_chunks = {}
    for i in range(min(pc_chunk_count, 5)):
        off = 12 + i * 12
        tag = pc_header[off:off + 4].decode("ascii", errors="replace")
        val = struct.unpack_from("<I", pc_header, off + 4)[0]
        meta = struct.unpack_from("<I", pc_header, off + 8)[0]
        pc_chunks[tag] = (val, meta)

    indx_off, indx_count = pc_chunks["INDX"]
    aset_off, aset_count = pc_chunks["ASET"]
    data_off = pc_chunks["DATA"][0]
    pths_off, pths_count = pc_chunks["PTHS"]
    print(f"  INDX: offset=0x{indx_off:x} count={indx_count}")
    print(f"  ASET: offset=0x{aset_off:x} count={aset_count}")
    print(f"  DATA: offset=0x{data_off:x}")

    # Parse PC ASET entries
    pc_aset = parse_pc_aset(pc_header, aset_off, aset_count)
    pc_audio = [(h, u1, u2, u3) for h, u1, u2, u3 in pc_aset
                if u3 in (TYPE_ID_WAVEBANK, TYPE_ID_SOUNDBANK)]
    print(f"  Audio entries: {len(pc_audio)} (wavebank={sum(1 for _,_,_,t in pc_audio if t==TYPE_ID_WAVEBANK)}, "
          f"soundbank={sum(1 for _,_,_,t in pc_audio if t==TYPE_ID_SOUNDBANK)})")

    # ── Parse Xbox WAD header and ASET ──
    print("\n--- Parsing Xbox WAD ---")
    with open(XBOX_WAD, "rb") as f:
        xbox_header = f.read(0x300000)

    assert xbox_header[:4] == SCFF_MAGIC, f"Bad Xbox magic: {xbox_header[:4]!r}"
    xbox_version = struct.unpack_from(">I", xbox_header, 4)[0]
    xbox_chunk_count = struct.unpack_from(">I", xbox_header, 8)[0]

    xbox_chunks = {}
    for i in range(min(xbox_chunk_count, 5)):
        off = 12 + i * 12
        tag = xbox_header[off:off + 4][::-1].decode("ascii", errors="replace")
        val = struct.unpack_from(">I", xbox_header, off + 4)[0]
        meta = struct.unpack_from(">I", xbox_header, off + 8)[0]
        xbox_chunks[tag] = (val, meta)

    xbox_indx_off, xbox_indx_count = xbox_chunks["INDX"]
    xbox_aset_off, xbox_aset_count = xbox_chunks["ASET"]
    xbox_data_off = xbox_chunks["DATA"][0]
    print(f"  INDX: offset=0x{xbox_indx_off:x} count={xbox_indx_count}")
    print(f"  ASET: offset=0x{xbox_aset_off:x} count={xbox_aset_count}")
    print(f"  DATA: offset=0x{xbox_data_off:x}")

    # Parse Xbox ASET entries (u3/type_id is LE even on Xbox)
    xbox_aset = parse_be_aset(xbox_header, xbox_aset_off, xbox_aset_count)
    xbox_audio = [e for e in xbox_aset if e.u3 in (TYPE_ID_WAVEBANK, TYPE_ID_SOUNDBANK)]
    print(f"  Audio entries: {len(xbox_audio)} (wavebank={sum(1 for e in xbox_audio if e.u3==TYPE_ID_WAVEBANK)}, "
          f"soundbank={sum(1 for e in xbox_audio if e.u3==TYPE_ID_SOUNDBANK)})")

    # ── Analyze Xbox ASET block_index values ──
    print("\n--- Xbox ASET block_index analysis ---")
    xbox_audio_bi = [(e.asset_hash, e.u2, (e.u2 >> 16) & 0xFFFF, e.u2 & 0xFFFF, e.u3) for e in xbox_audio]
    bi_ffff = sum(1 for _, _, bi, _, _ in xbox_audio_bi if bi == 0xFFFF)
    bi_other = [(h, u2, bi, lo, t) for h, u2, bi, lo, t in xbox_audio_bi if bi != 0xFFFF]
    print(f"  block_index=0xFFFF: {bi_ffff}")
    print(f"  block_index other: {len(bi_other)}")
    if bi_other:
        print(f"  First non-0xFFFF entries:")
        for h, u2, bi, lo, t in bi_other[:10]:
            print(f"    hash=0x{h:08X} u2=0x{u2:08X} bi={bi} lo16={lo} type_id={t}")

    # Check low-16 of u2 for Xbox audio entries
    lo16_vals = set(e.u2 & 0xFFFF for e in xbox_audio)
    print(f"  Unique low16(u2) values: {len(lo16_vals)} (range {min(lo16_vals)}..{max(lo16_vals)})")
    print(f"  First 20 low16 values: {sorted(lo16_vals)[:20]}")

    # ── Match entries by asset_hash ──
    print("\n--- Matching entries by asset_hash ---")
    pc_audio_map = {h: (u1, u2, u3) for h, u1, u2, u3 in pc_audio}
    matched = []
    for entry in xbox_audio:
        if entry.asset_hash in pc_audio_map:
            pc_u1, pc_u2, pc_u3 = pc_audio_map[entry.asset_hash]
            matched.append((entry, pc_u1, pc_u2, pc_u3))
    print(f"  Matched: {len(matched)} / {len(xbox_audio)} Xbox entries")

    # Show first matched entries with field comparison
    print("\n  First 10 matched entries:")
    print(f"  {'hash':<12} {'xbox_u2':<12} {'pc_u2':<12} {'type':<4} {'pc_bi':<6} {'xbox_lo16':<10}")
    for entry, pc_u1, pc_u2, pc_u3 in matched[:10]:
        pc_bi = (pc_u2 >> 16) & 0xFFFF
        xbox_lo16 = entry.u2 & 0xFFFF
        tname = "wb" if entry.u3 == TYPE_ID_WAVEBANK else "sb"
        print(f"  0x{entry.asset_hash:08X} 0x{entry.u2:08X} 0x{pc_u2:08X} {tname:<4} {pc_bi:<6} {xbox_lo16:<10}")

    # ── Decompress and compare block data ──
    print("\n--- Decompressing and comparing audio blocks ---")

    # For PC: read DATA chunk and find sges offsets
    print("  Loading PC DATA chunk (this may take a moment for 2.5GB)...")
    with open(PC_WAD, "rb") as f:
        # Get file size for DATA chunk end calculation
        f.seek(0, 2)
        pc_file_size = f.tell()

    # Parse INDX for page offsets
    pc_indx = parse_pc_indx(pc_header, indx_off, indx_count)
    print(f"  PC INDX: {len(pc_indx)} entries, page range: "
          f"{min(p for p,_,_ in pc_indx)}..{max(p for p,_,_ in pc_indx)}")

    # We need to read specific blocks, not the whole DATA chunk
    # For each matched PC audio entry, find its block
    pc_block_indices = set()
    for entry, pc_u1, pc_u2, pc_u3 in matched[:MAX_ENTRIES_TO_COMPARE]:
        pc_bi = (pc_u2 >> 16) & 0xFFFF
        if pc_bi < len(pc_indx):
            pc_block_indices.add(pc_bi)

    # For Xbox: try to locate audio blocks by scanning
    # First check if low16 of u2 is a valid block index
    xbox_lo16_candidates = set()
    for entry, _, _, _ in matched[:MAX_ENTRIES_TO_COMPARE]:
        lo16 = entry.u2 & 0xFFFF
        if lo16 < xbox_indx_count:
            xbox_lo16_candidates.add(lo16)

    print(f"  PC blocks to read: {len(pc_block_indices)}")
    print(f"  Xbox candidate blocks (from lo16): {len(xbox_lo16_candidates)}")

    # Parse Xbox INDX for page offsets
    xbox_indx = parse_be_indx(xbox_header, xbox_indx_off, xbox_indx_count)
    print(f"  Xbox INDX: {len(xbox_indx)} entries")

    # ── Read and decompress matched blocks ──
    results_soundbank = []
    results_wavebank = []
    compared = 0

    for entry, pc_u1, pc_u2, pc_u3 in matched[:MAX_ENTRIES_TO_COMPARE]:
        pc_bi = (pc_u2 >> 16) & 0xFFFF
        xbox_lo16 = entry.u2 & 0xFFFF
        type_name = "wavebank" if entry.u3 == TYPE_ID_WAVEBANK else "soundbank"
        type_hash_expected = TYPE_HASH_WAVEBANK if entry.u3 == TYPE_ID_WAVEBANK else TYPE_HASH_SOUNDBANK

        # Decompress PC block
        pc_body = None
        if pc_bi < len(pc_indx):
            pc_page_idx = pc_indx[pc_bi][0]
            pc_block_abs_offset = pc_page_idx * PAGE_SIZE
            # Read the sges block from the WAD
            # Determine block size from next INDX entry
            if pc_bi + 1 < len(pc_indx):
                next_page = pc_indx[pc_bi + 1][0]
                pc_block_size = (next_page - pc_page_idx) * PAGE_SIZE
            else:
                pc_block_size = PAGE_SIZE * 128  # generous fallback

            try:
                with open(PC_WAD, "rb") as f:
                    f.seek(pc_block_abs_offset)
                    pc_raw = f.read(pc_block_size)

                if pc_raw[:4] == SGES_MAGIC:
                    pc_decompressed = decompress_sges_block(pc_raw, 0, len(pc_raw))
                    # Find entry matching asset_hash
                    pc_entries = parse_ucfx_entry_table_le(pc_decompressed)
                    for idx, (h, t, o, s) in enumerate(pc_entries):
                        if h == entry.asset_hash and t == type_hash_expected:
                            pc_body = extract_entry_data_body_le(pc_decompressed, pc_entries, idx)
                            break
                    if pc_body is None:
                        for idx, (h, t, o, s) in enumerate(pc_entries):
                            if h == entry.asset_hash:
                                pc_body = extract_entry_data_body_le(pc_decompressed, pc_entries, idx)
                                break
            except Exception as e:
                print(f"  [PC FAIL] hash=0x{entry.asset_hash:08X} block={pc_bi}: {e}")

        # Decompress Xbox block (try lo16 as block index)
        xbox_body = None
        if xbox_lo16 < len(xbox_indx):
            xbox_entry = xbox_indx[xbox_lo16]
            xbox_block_abs_offset = xbox_entry.page_index * PAGE_SIZE
            if xbox_lo16 + 1 < len(xbox_indx):
                next_entry = xbox_indx[xbox_lo16 + 1]
                xbox_block_size = (next_entry.page_index - xbox_entry.page_index) * PAGE_SIZE
            else:
                xbox_block_size = PAGE_SIZE * 128

            try:
                with open(XBOX_WAD, "rb") as f:
                    f.seek(xbox_block_abs_offset)
                    xbox_raw = f.read(xbox_block_size)

                if xbox_raw[:4] == SEGS_MAGIC:
                    xbox_decompressed = decompress_be_sges(xbox_raw, 0, len(xbox_raw))
                    # Find entry matching asset_hash
                    xbox_entries = parse_ucfx_entry_table_be(xbox_decompressed)
                    for idx, (h, t, o, s) in enumerate(xbox_entries):
                        if h == entry.asset_hash and t == type_hash_expected:
                            xbox_body = extract_entry_data_body_be(xbox_decompressed, xbox_entries, idx)
                            break
                    if xbox_body is None:
                        for idx, (h, t, o, s) in enumerate(xbox_entries):
                            if h == entry.asset_hash:
                                xbox_body = extract_entry_data_body_be(xbox_decompressed, xbox_entries, idx)
                                break
            except Exception as e:
                print(f"  [Xbox FAIL] hash=0x{entry.asset_hash:08X} lo16={xbox_lo16}: {e}")

        # If Xbox lo16 didn't work, try scanning nearby blocks
        if xbox_body is None and xbox_lo16 >= len(xbox_indx):
            # Try a brute force scan of a few blocks
            for scan_bi in range(min(50, len(xbox_indx))):
                xbox_entry_scan = xbox_indx[scan_bi]
                xbox_block_abs = xbox_entry_scan.page_index * PAGE_SIZE
                if scan_bi + 1 < len(xbox_indx):
                    ne = xbox_indx[scan_bi + 1]
                    bsz = (ne.page_index - xbox_entry_scan.page_index) * PAGE_SIZE
                else:
                    bsz = PAGE_SIZE * 128
                try:
                    with open(XBOX_WAD, "rb") as f:
                        f.seek(xbox_block_abs)
                        raw = f.read(min(bsz, 1024 * 1024))
                    if raw[:4] == SEGS_MAGIC:
                        dec = decompress_be_sges(raw, 0, len(raw))
                        ents = parse_ucfx_entry_table_be(dec)
                        for idx, (h, t, o, s) in enumerate(ents):
                            if h == entry.asset_hash:
                                xbox_body = extract_entry_data_body_be(dec, ents, idx)
                                break
                        if xbox_body is not None:
                            break
                except Exception:
                    continue

        # Compare bodies
        if pc_body and xbox_body:
            compared += 1
            comparison = compare_bodies(xbox_body, pc_body, entry.asset_hash, type_name)
            if type_name == "soundbank":
                results_soundbank.append(comparison)
            else:
                results_wavebank.append(comparison)
        elif pc_body and not xbox_body:
            print(f"  [NO XBOX] hash=0x{entry.asset_hash:08X} type={type_name} (PC body={len(pc_body)} bytes)")
        elif xbox_body and not pc_body:
            print(f"  [NO PC] hash=0x{entry.asset_hash:08X} type={type_name} (Xbox body={len(xbox_body)} bytes)")

    print(f"\n  Successfully compared: {compared} entries")
    print(f"  Soundbank comparisons: {len(results_soundbank)}")
    print(f"  Wavebank comparisons: {len(results_wavebank)}")

    # Print aggregate results
    if results_soundbank:
        print_aggregate_results("SOUNDBANK", results_soundbank)
    if results_wavebank:
        print_aggregate_results("WAVEBANK", results_wavebank)


def compare_bodies(xbox_be: bytes, pc_le: bytes, asset_hash: int, type_name: str) -> dict:
    """Compare two bodies byte-by-byte in 4-byte aligned chunks."""
    result = {
        "asset_hash": asset_hash,
        "type": type_name,
        "xbox_size": len(xbox_be),
        "pc_size": len(pc_le),
        "fields": [],
    }

    min_len = min(len(xbox_be), len(pc_le))
    max_fields = min_len // 4

    # Print header for first few comparisons
    if max_fields > 0:
        print(f"\n  [{type_name}] hash=0x{asset_hash:08X} xbox={len(xbox_be)}B pc={len(pc_le)}B")
        if len(xbox_be) != len(pc_le):
            print(f"    SIZE MISMATCH! xbox={len(xbox_be)} pc={len(pc_le)}")
        # Print hex dump of first 64 bytes
        print(f"    Xbox first 64B: {hex_dump(xbox_be[:64])}")
        print(f"    PC   first 64B: {hex_dump(pc_le[:64])}")

    for i in range(max_fields):
        off = i * 4
        xbox_chunk = xbox_be[off:off + 4]
        pc_chunk = pc_le[off:off + 4]
        classification = classify_u32(xbox_chunk, pc_chunk)
        result["fields"].append({
            "offset": off,
            "xbox": xbox_chunk.hex(),
            "pc": pc_chunk.hex(),
            "type": classification,
        })

    # Summarize per-field types
    field_types = [f["type"] for f in result["fields"]]
    type_counts = {}
    for t in field_types:
        type_counts[t] = type_counts.get(t, 0) + 1
    result["type_counts"] = type_counts

    # Print first 32 field classifications
    if result["fields"]:
        print(f"    Field map (first {min(32, len(result['fields']))} u32 slots):")
        line = "    "
        for i, f in enumerate(result["fields"][:32]):
            abbrev = {"zero": "0", "u32": "4", "u16x2": "2", "u8x4": "1", "f32": "F", "mixed": "X"}
            line += abbrev.get(f["type"], "?")
            if (i + 1) % 8 == 0:
                line += " "
        print(line)

        # Print detailed classifications for mixed fields
        mixed_fields = [(f["offset"], f["xbox"], f["pc"]) for f in result["fields"] if f["type"] == "mixed"]
        if mixed_fields:
            print(f"    MIXED fields ({len(mixed_fields)} total):")
            for off, xbox_hex, pc_hex in mixed_fields[:16]:
                print(f"      +0x{off:04X}: xbox={xbox_hex} pc={pc_hex}")

    return result


def print_aggregate_results(name: str, results: list[dict]):
    """Print aggregate field type classification."""
    print(f"\n{'=' * 60}")
    print(f"  AGGREGATE {name} FIELD TYPE MAP")
    print(f"{'=' * 60}")

    if not results:
        return

    # Find the maximum field count
    max_fields = max(len(r["fields"]) for r in results)

    # For each field position, collect all classifications
    position_types: dict[int, dict[str, int]] = {}
    for r in results:
        for f in r["fields"]:
            off = f["offset"]
            if off not in position_types:
                position_types[off] = {}
            t = f["type"]
            position_types[off][t] = position_types[off].get(t, 0) + 1

    # Print the consensus map
    print(f"  Entries analyzed: {len(results)}")
    print(f"  Max body size: {max(r['pc_size'] for r in results)} bytes")
    print(f"\n  Offset  Consensus  Detail")
    print(f"  {'-' * 50}")

    consensus_map = []
    for off in sorted(position_types.keys())[:64]:
        types = position_types[off]
        total = sum(types.values())
        best_type = max(types, key=types.get)
        pct = types[best_type] / total * 100
        detail = " ".join(f"{t}={c}" for t, c in sorted(types.items(), key=lambda x: -x[1]))
        consensus_map.append((off, best_type, pct))
        if pct < 100 or best_type == "mixed":
            print(f"  +0x{off:04X}  {best_type:<8}  {pct:5.1f}%  ({detail})")
        else:
            print(f"  +0x{off:04X}  {best_type:<8}  100%")

    # Summary row counts
    all_type_counts: dict[str, int] = {}
    for r in results:
        for t, c in r["type_counts"].items():
            all_type_counts[t] = all_type_counts.get(t, 0) + c
    total_fields = sum(all_type_counts.values())
    print(f"\n  Total field classifications across all entries:")
    for t in sorted(all_type_counts, key=all_type_counts.get, reverse=True):
        c = all_type_counts[t]
        print(f"    {t:<8}: {c:5d} ({c/total_fields*100:.1f}%)")


# ── Part 2: PWS File Format Comparison ────────────────────────────────

def part2_pws_comparison():
    print("\n\n" + "=" * 80)
    print("PART 2: PWS FILE FORMAT COMPARISON")
    print("=" * 80)

    xbox_pws_files = sorted(XBOX_AUDIO_DIR.glob("*.pws")) if XBOX_AUDIO_DIR.exists() else []
    dlc_pws_files = sorted(DLC_AUDIO_DIR.glob("*.pws")) if DLC_AUDIO_DIR.exists() else []

    print(f"\nXbox retail PWS files: {len(xbox_pws_files)}")
    for f in xbox_pws_files:
        print(f"  {f.name}: {f.stat().st_size:,} bytes")

    print(f"\nDLC output PWS files: {len(dlc_pws_files)}")
    for f in dlc_pws_files:
        print(f"  {f.name}: {f.stat().st_size:,} bytes")

    # Analyze headers
    print("\n--- PWS Header Analysis ---")

    all_pws = []
    for f in xbox_pws_files:
        data = f.read_bytes()[:512]
        all_pws.append(("Xbox", f.name, data))
    for f in dlc_pws_files:
        data = f.read_bytes()[:512]
        all_pws.append(("DLC", f.name, data))

    for source, name, data in all_pws:
        print(f"\n  [{source}] {name} ({len(data)} bytes header)")
        print(f"    Bytes 0-3: {data[0:4].hex()} (as LE u32={struct.unpack_from('<I', data, 0)[0]}, "
              f"BE u32={struct.unpack_from('>I', data, 0)[0]})")
        print(f"    Bytes 4-7: {data[4:8].hex()} (as LE u32={struct.unpack_from('<I', data, 4)[0]}, "
              f"BE u32={struct.unpack_from('>I', data, 4)[0]})")
        print(f"    Bytes 8-11: {data[8:12].hex()} (as LE u32={struct.unpack_from('<I', data, 8)[0]}, "
              f"BE u32={struct.unpack_from('>I', data, 8)[0]})")
        print(f"    Bytes 12-15: {data[12:16].hex()} (as LE u32={struct.unpack_from('<I', data, 12)[0]}, "
              f"BE u32={struct.unpack_from('>I', data, 12)[0]})")

        # Show as u16 pairs
        print(f"    As LE u16 pairs: [{struct.unpack_from('<H', data, 0)[0]}, "
              f"{struct.unpack_from('<H', data, 2)[0]}, "
              f"{struct.unpack_from('<H', data, 4)[0]}, "
              f"{struct.unpack_from('<H', data, 6)[0]}, "
              f"{struct.unpack_from('<H', data, 8)[0]}, "
              f"{struct.unpack_from('<H', data, 10)[0]}, "
              f"{struct.unpack_from('<H', data, 12)[0]}, "
              f"{struct.unpack_from('<H', data, 14)[0]}]")
        print(f"    As BE u16 pairs: [{struct.unpack_from('>H', data, 0)[0]}, "
              f"{struct.unpack_from('>H', data, 2)[0]}, "
              f"{struct.unpack_from('>H', data, 4)[0]}, "
              f"{struct.unpack_from('>H', data, 6)[0]}, "
              f"{struct.unpack_from('>H', data, 8)[0]}, "
              f"{struct.unpack_from('>H', data, 10)[0]}, "
              f"{struct.unpack_from('>H', data, 12)[0]}, "
              f"{struct.unpack_from('>H', data, 14)[0]}]")

        # Full hex dump of first 256 bytes
        print(f"    Full first 128B hex:")
        for row in range(8):
            chunk = data[row * 16:(row + 1) * 16]
            hex_part = " ".join(f"{b:02x}" for b in chunk)
            ascii_part = "".join(chr(b) if 32 <= b < 127 else "." for b in chunk)
            print(f"      {row * 16:04x}: {hex_part}  {ascii_part}")

    # Check for ADPCM block alignment
    print("\n--- ADPCM Block Alignment Analysis ---")
    for source, name, data in all_pws:
        file_path = XBOX_AUDIO_DIR / name if source == "Xbox" else DLC_AUDIO_DIR / name
        file_size = file_path.stat().st_size

        # Check alignment to 36-byte mono blocks
        mono_blocks = file_size / 36
        stereo_blocks = file_size / 72
        print(f"  [{source}] {name}: size={file_size:,}")
        print(f"    Mono blocks (36B): {mono_blocks:.2f} (exact={file_size % 36 == 0})")
        print(f"    Stereo blocks (72B): {stereo_blocks:.2f} (exact={file_size % 72 == 0})")

        # Check if there's a header before the ADPCM data
        # Look for the first 4-byte preamble that looks like an ADPCM block header
        # ADPCM block header: int16 predictor + uint8 step_index + uint8 reserved(0)
        header_candidates = []
        for off in range(0, min(256, len(data)), 4):
            pred = struct.unpack_from("<h", data, off)[0]
            step_idx = data[off + 2]
            reserved = data[off + 3]
            if -32768 <= pred <= 32767 and step_idx <= 88 and reserved == 0:
                remaining = file_size - off
                if remaining % 36 == 0 or remaining % 72 == 0:
                    header_candidates.append(off)

        if header_candidates:
            print(f"    ADPCM start candidates (by header+alignment): {header_candidates[:5]}")
            best = header_candidates[0]
            if best > 0:
                print(f"    Likely header size: {best} bytes (0x{best:X})")
                remaining = file_size - best
                print(f"    Data after header: {remaining:,} bytes "
                      f"(mono blocks: {remaining // 36}, stereo blocks: {remaining // 72})")

    # Compare Xbox vs DLC: check if the DLC files are already byte-swapped
    print("\n--- Xbox vs DLC Endianness Check ---")
    if xbox_pws_files and dlc_pws_files:
        xbox_sample = xbox_pws_files[0].read_bytes()[:256]
        dlc_sample = dlc_pws_files[0].read_bytes()[:256]

        print(f"  Comparing: Xbox {xbox_pws_files[0].name} vs DLC {dlc_pws_files[0].name}")

        # Check if first few u32s are byte-reversed between them
        print(f"  First 8 u32 values:")
        print(f"  {'Offset':<8} {'Xbox(hex)':<12} {'DLC(hex)':<12} {'Xbox-LE':<12} {'Xbox-BE':<12} {'DLC-LE':<12} {'Same?'}")
        for i in range(8):
            off = i * 4
            xb = xbox_sample[off:off + 4]
            db = dlc_sample[off:off + 4]
            xle = struct.unpack_from("<I", xbox_sample, off)[0]
            xbe = struct.unpack_from(">I", xbox_sample, off)[0]
            dle = struct.unpack_from("<I", dlc_sample, off)[0]
            same = "YES" if xb == db else ("SWAP" if xb[::-1] == db else "DIFF")
            print(f"  {off:04x}     {xb.hex():<12} {db.hex():<12} {xle:<12} {xbe:<12} {dle:<12} {same}")


# ── Main ──────────────────────────────────────────────────────────────

def main() -> int:
    print("Mercenaries 2 Audio Data Cross-Platform Comparison")
    print(f"Repository: {REPO_ROOT}")
    print()

    # Verify files exist
    missing = []
    if not PC_WAD.exists():
        missing.append(f"PC WAD: {PC_WAD}")
    if not XBOX_WAD.exists():
        missing.append(f"Xbox WAD: {XBOX_WAD}")
    if missing:
        print("ERROR: Missing files:")
        for m in missing:
            print(f"  {m}")
        return 1

    part1_wad_comparison()
    part2_pws_comparison()

    return 0


if __name__ == "__main__":
    sys.exit(main())
