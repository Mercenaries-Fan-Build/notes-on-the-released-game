#!/usr/bin/env python3
r"""Cross-platform forensic comparison of Mercenaries 2 scripts_vz blocks.

Parses PC, Xbox 360, and PC Demo vz.wad files, extracts scripts_vz blocks,
inventories UCFX entries, and produces a detailed diff report.

Usage:
  .venv/bin/python3 tools/cross_platform_vz_compare.py \
    --pc-wad game-files/vz.wad \
    --xbox-wad analysis/cross_platform/wads/xbox360/Mercenaries2\ World\ in\ Flames\ \(RGH\)/vz.wad \
    --demo-wad analysis/cross_platform/wads/pc_demo/Mercenaries\ 2\ World\ in\ Flames\ DEMO/data/vz.wad \
    --output analysis/cross_platform
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
import struct
import sys
import zlib
from dataclasses import dataclass, field, asdict
from pathlib import Path
from typing import BinaryIO

FFCS_MAGIC = b"FFCS"
SCFF_MAGIC = b"SCFF"
SGES_MAGIC = b"sges"
SEGS_MAGIC = b"segs"
UCFX_MAGIC = b"UCFX"
XFCU_MAGIC = b"XFCU"
BINN_TAG = b"BINN"
NNIB_TAG = b"NNIB"
CSUM_TAG = b"CSUM"
LUAQ_SIG = b"\x1bLua"

PAGE_SIZE = 0x8000


@dataclass
class ChunkRow:
    tag: str
    offset: int
    meta: int


@dataclass
class WADInfo:
    platform: str
    path: str
    file_size: int
    sha256: str
    endian: str
    version: int
    chunk_count: int
    chunks: list[ChunkRow]
    block_count: int
    aset_count: int
    path_count: int
    scripts_vz_index: int | None
    scripts_vz_path: str | None


@dataclass
class ScriptEntry:
    index: int
    name: str
    name_hash: int
    type_hash: int
    chunk_size: int
    bytecode_size: int | None
    luaq_header: dict | None
    sha256: str


@dataclass
class ScriptsBlockInfo:
    platform: str
    block_index: int
    block_path: str
    compressed_size: int
    decompressed_size: int
    decompressed_sha256: str
    entry_count: int
    entries: list[ScriptEntry]


# ── Endian-aware FFCS parsing ─────────────────────────────────────────

def parse_ffcs_header(data: bytes) -> tuple[str, int, int, list[ChunkRow]]:
    """Parse FFCS/SCFF header. Returns (endian, version, chunk_count, rows)."""
    magic = data[:4]
    if magic == FFCS_MAGIC:
        endian = "little"
        fmt = "<I"
    elif magic == SCFF_MAGIC:
        endian = "big"
        fmt = ">I"
    else:
        raise ValueError(f"Unknown WAD magic: {magic!r}")

    version = struct.unpack_from(fmt, data, 4)[0]
    chunk_count = struct.unpack_from(fmt, data, 8)[0]

    rows: list[ChunkRow] = []
    for i in range(min(chunk_count, 7)):
        off = 0x0C + i * 12
        tag_raw = data[off:off + 4]
        if endian == "big":
            tag = tag_raw[::-1].decode("ascii", errors="replace")
        else:
            tag = tag_raw.decode("ascii", errors="replace")
        val = struct.unpack_from(fmt, data, off + 4)[0]
        meta = struct.unpack_from(fmt, data, off + 8)[0]
        rows.append(ChunkRow(tag=tag, offset=val, meta=meta))

    return endian, version, chunk_count, rows


def parse_indx_entries(data: bytes, indx_off: int, count: int, endian: str) -> list[tuple[int, int, int, int]]:
    """Parse INDX: returns list of (page_index, packed, flags, page_count)."""
    fmt = ">III" if endian == "big" else "<III"
    entries = []
    for i in range(count):
        off = indx_off + i * 12
        if off + 12 > len(data):
            break
        page_idx, packed, flags_pages = struct.unpack_from(fmt, data, off)
        flags = (flags_pages >> 16) & 0xFFFF
        page_count = flags_pages & 0xFFFF
        entries.append((page_idx, packed, flags, page_count))
    return entries


def parse_pths_strings(data: bytes, pths_off: int, count: int) -> list[str]:
    """Parse null-terminated path strings from PTHS section."""
    paths: list[str] = []
    pos = pths_off
    for _ in range(count):
        if pos >= len(data):
            break
        nul = data.find(b"\x00", pos)
        if nul < 0:
            break
        s = data[pos:nul].decode("ascii", errors="replace")
        paths.append(s)
        pos = nul + 1
    return paths


# ── sges/segs decompression ──────────────────────────────────────────

def decompress_le_sges(data: bytes, offset: int, end: int) -> bytes:
    """Decompress a little-endian sges block."""
    if data[offset:offset + 4] != SGES_MAGIC:
        raise ValueError(f"Expected sges at 0x{offset:X}")
    _major, minor = struct.unpack_from("<HH", data, offset + 4)
    total_u = struct.unpack_from("<I", data, offset + 8)[0]
    header_size = math.ceil((16 + minor * 8) / 16) * 16
    payload_start = offset + header_size

    out = bytearray()
    pos = payload_start
    while len(out) < total_u and pos < end:
        while pos < end and data[pos] == 0:
            pos += 1
        if pos >= end:
            break
        try:
            chunk = data[pos:min(pos + 131072, end)]
            dec = zlib.decompressobj(-15)
            piece = dec.decompress(chunk)
            consumed = len(chunk) - len(dec.unused_data)
            out.extend(piece)
            pos += consumed
        except zlib.error:
            break

    return bytes(out[:total_u])


def decompress_be_sges(data: bytes, offset: int, max_size: int) -> bytes:
    """Decompress a big-endian Xbox 360 segs block."""
    if data[offset:offset + 4] != SEGS_MAGIC:
        raise ValueError(f"Expected segs at 0x{offset:X}, got {data[offset:offset+4]!r}")

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

    return bytes(result)


# ── Block entry parsing ──────────────────────────────────────────────

def parse_block_entries_endian(data: bytes, endian: str) -> list[dict]:
    """Parse block header (count + entries). Handles both LE and BE."""
    fmt_u32 = ">I" if endian == "big" else "<I"
    fmt_4u32 = ">IIII" if endian == "big" else "<IIII"

    count = struct.unpack_from(fmt_u32, data, 0)[0]
    if count > 50000:
        raise ValueError(f"Suspicious entry count: {count}")
    header_end = 4 + count * 16

    entries: list[dict] = []
    pos = header_end
    for i in range(count):
        h, th, fc, s = struct.unpack_from(fmt_4u32, data, 4 + i * 16)
        entries.append({
            "index": i,
            "hash": h,
            "type_hash": th,
            "field_c": fc,
            "size": s,
            "offset": pos,
        })
        pos += s
    return entries


def get_script_name_endian(data: bytes, entry: dict, endian: str) -> str:
    """Extract script name from BINN/NNIB section."""
    binn = NNIB_TAG if endian == "big" else BINN_TAG
    chunk = data[entry["offset"]:entry["offset"] + min(entry["size"], 400)]
    binn_off = chunk.find(binn)
    if binn_off < 0:
        return f"unknown_{entry['index']:03d}"
    region = chunk[binn_off + 4:binn_off + 300]
    i = 0
    while i < len(region):
        if 32 <= region[i] < 127:
            j = i
            while j < len(region) and 32 <= region[j] < 127:
                j += 1
            s = region[i:j].decode("ascii")
            if len(s) >= 3 and s not in ("BINN", "NNIB", "LuaQ", "UCFX", "XFCU", "CSUM", "MSUC"):
                return s
            i = j
        else:
            i += 1
    return f"unknown_{entry['index']:03d}"


def extract_lua_bytecode_info(data: bytes, entry: dict) -> tuple[bytes | None, dict | None]:
    """Find LuaQ signature in entry, extract bytecode and header info."""
    chunk = data[entry["offset"]:entry["offset"] + entry["size"]]
    luaq_off = chunk.find(LUAQ_SIG)
    if luaq_off < 0:
        return None, None

    bc = chunk[luaq_off:]
    if len(bc) < 12:
        return bc, None

    info: dict = {}
    pos = 4
    if len(bc) > pos and bc[pos - 1:pos] == b'Q':
        info["mercs2_q_marker"] = True
        pos = 5
    else:
        info["mercs2_q_marker"] = False
        pos = 4

    if len(bc) > pos + 8:
        info["version"] = bc[pos]
        info["format"] = bc[pos + 1]
        info["endianness"] = bc[pos + 2]
        info["endian_label"] = "little" if bc[pos + 2] == 1 else ("big" if bc[pos + 2] == 0 else f"unknown({bc[pos+2]})")
        info["int_size"] = bc[pos + 3]
        info["size_t_size"] = bc[pos + 4]
        info["instruction_size"] = bc[pos + 5]
        info["number_size"] = bc[pos + 6]
        info["number_is_integral"] = bc[pos + 7] if len(bc) > pos + 7 else None

    return bc, info


# ── Main analysis ────────────────────────────────────────────────────

def analyze_wad(wad_path: Path, platform: str, out_dir: Path) -> tuple[WADInfo, ScriptsBlockInfo | None]:
    """Full analysis of a single WAD file."""
    print(f"\n{'='*70}")
    print(f"Analyzing {platform}: {wad_path}")
    print(f"{'='*70}")

    data = wad_path.read_bytes()
    file_size = len(data)
    wad_sha256 = hashlib.sha256(data).hexdigest()
    print(f"  Size: {file_size:,} bytes ({file_size/1024/1024:.1f} MB)")
    print(f"  SHA256: {wad_sha256}")

    endian, version, chunk_count, rows = parse_ffcs_header(data)
    print(f"  Format: {'SCFF' if endian == 'big' else 'FFCS'} (endian={endian})")
    print(f"  Version: {version}, Chunks: {chunk_count}")

    for r in rows:
        print(f"    {r.tag}: offset=0x{r.offset:X} meta={r.meta}")

    indx_row = next((r for r in rows if r.tag == "INDX"), None)
    aset_row = next((r for r in rows if r.tag == "ASET"), None)
    pths_row = next((r for r in rows if r.tag == "PTHS"), None)
    data_row = next((r for r in rows if r.tag == "DATA"), None)

    block_count = indx_row.meta if indx_row else 0
    aset_count = aset_row.meta if aset_row else 0
    print(f"  Blocks: {block_count}")
    print(f"  ASET entries: {aset_count}")

    paths: list[str] = []
    if pths_row:
        paths = parse_pths_strings(data, pths_row.offset, pths_row.meta)
        print(f"  PTHS paths: {len(paths)}")
    path_count = len(paths)

    # Write all paths to file
    plat_dir = out_dir / "scripts_vz_comparison" / platform
    plat_dir.mkdir(parents=True, exist_ok=True)
    (plat_dir / "all_paths.txt").write_text("\n".join(paths), encoding="utf-8")

    # Find scripts_vz
    scripts_idx = None
    scripts_path_str = None
    for i, p in enumerate(paths):
        if "scripts_vz" in p.lower():
            scripts_idx = i
            scripts_path_str = p
            print(f"  scripts_vz block: index={i} path={p!r}")
            break

    wad_info = WADInfo(
        platform=platform,
        path=str(wad_path),
        file_size=file_size,
        sha256=wad_sha256,
        endian=endian,
        version=version,
        chunk_count=chunk_count,
        chunks=rows,
        block_count=block_count,
        aset_count=aset_count,
        path_count=path_count,
        scripts_vz_index=scripts_idx,
        scripts_vz_path=scripts_path_str,
    )

    if scripts_idx is None:
        print(f"  WARNING: No scripts_vz block found!")
        return wad_info, None

    if not data_row or not indx_row:
        print(f"  ERROR: Missing DATA or INDX chunk")
        return wad_info, None

    # Parse INDX to get block offset/size
    indx_entries = parse_indx_entries(data, indx_row.offset, block_count, endian)
    if scripts_idx >= len(indx_entries):
        print(f"  ERROR: scripts_vz index {scripts_idx} >= INDX entries {len(indx_entries)}")
        return wad_info, None

    page_idx, packed, flags, page_count = indx_entries[scripts_idx]
    block_file_offset = page_idx * PAGE_SIZE
    block_size = page_count * PAGE_SIZE
    print(f"  scripts_vz INDX: page_idx={page_idx}, pages={page_count}, "
          f"offset=0x{block_file_offset:X}, size={block_size:,}")

    # For LE (PC), blocks are in the DATA section and we find them by scanning sges offsets
    # For BE (Xbox), blocks are at absolute INDX offsets
    scripts_block: ScriptsBlockInfo | None = None

    if endian == "little":
        scripts_block = _extract_le_scripts_block(
            data, data_row, indx_entries, scripts_idx, paths, platform, plat_dir
        )
    elif endian == "big":
        scripts_block = _extract_be_scripts_block(
            data, indx_entries, scripts_idx, paths, platform, plat_dir
        )

    return wad_info, scripts_block


def _find_sges_offsets(data: bytes, start: int, end: int) -> list[int]:
    """Scan for sges magic within a range."""
    offsets: list[int] = []
    pos = start
    while pos < end - 4:
        idx = data.find(SGES_MAGIC, pos, end)
        if idx < 0:
            break
        offsets.append(idx)
        pos = idx + 1
    return offsets


def _extract_le_scripts_block(
    data: bytes,
    data_row: ChunkRow,
    indx_entries: list[tuple[int, int, int, int]],
    scripts_idx: int,
    paths: list[str],
    platform: str,
    plat_dir: Path,
) -> ScriptsBlockInfo | None:
    """Extract scripts_vz from a little-endian (PC/Demo) WAD.

    The FFCS DATA chunk's 'meta' field is NOT the byte size — it's some other
    field. The actual DATA region extends from data_row.offset to EOF (or the
    next non-DATA chunk). We use the INDX page_index to compute the absolute
    offset of scripts_vz within the WAD, then scan around it for the sges
    header.
    """
    page_idx, packed, flags, page_count = indx_entries[scripts_idx]
    block_file_offset = page_idx * PAGE_SIZE
    block_byte_size = page_count * PAGE_SIZE

    # The block should start with sges magic at block_file_offset
    if block_file_offset + 4 > len(data):
        print(f"  ERROR: Block offset 0x{block_file_offset:X} beyond WAD ({len(data):,} bytes)")
        return None

    magic = data[block_file_offset:block_file_offset + 4]
    if magic != SGES_MAGIC:
        print(f"  WARNING: Expected sges at 0x{block_file_offset:X}, got {magic!r}")
        # Try scanning nearby for sges
        search_start = max(0, block_file_offset - PAGE_SIZE)
        search_end = min(len(data), block_file_offset + PAGE_SIZE)
        nearby = _find_sges_offsets(data, search_start, search_end)
        if not nearby:
            print(f"  ERROR: No sges found near 0x{block_file_offset:X}")
            return None
        closest = min(nearby, key=lambda x: abs(x - block_file_offset))
        print(f"  Found sges at 0x{closest:X} (offset from INDX: {closest - block_file_offset:+,})")
        block_file_offset = closest

    block_end = block_file_offset + block_byte_size
    compressed_size = block_byte_size
    print(f"  scripts_vz sges: 0x{block_file_offset:X}..0x{block_end:X} ({compressed_size:,} bytes)")

    try:
        decompressed = decompress_le_sges(data, block_file_offset, block_end)
    except Exception as e:
        print(f"  ERROR: Decompression failed: {e}")
        return None

    print(f"  Decompressed: {len(decompressed):,} bytes")
    decomp_sha256 = hashlib.sha256(decompressed).hexdigest()

    (plat_dir / "scripts_vz.block.bin").write_bytes(decompressed)

    return _analyze_scripts_block(decompressed, "little", platform, scripts_idx,
                                   paths[scripts_idx] if scripts_idx < len(paths) else "?",
                                   compressed_size, plat_dir)


def _extract_be_scripts_block(
    data: bytes,
    indx_entries: list[tuple[int, int, int, int]],
    scripts_idx: int,
    paths: list[str],
    platform: str,
    plat_dir: Path,
) -> ScriptsBlockInfo | None:
    """Extract scripts_vz from a big-endian (Xbox 360) WAD."""
    page_idx, packed, flags, page_count = indx_entries[scripts_idx]
    block_offset = page_idx * PAGE_SIZE
    block_size = page_count * PAGE_SIZE

    if block_offset + 4 > len(data):
        print(f"  ERROR: Block offset 0x{block_offset:X} beyond WAD")
        return None

    magic = data[block_offset:block_offset + 4]
    compressed_size = block_size

    if magic == SEGS_MAGIC:
        print(f"  scripts_vz is segs-compressed at 0x{block_offset:X}")
        try:
            decompressed = decompress_be_sges(data, block_offset, block_size)
        except Exception as e:
            print(f"  ERROR: Decompression failed: {e}")
            return None
    else:
        rec_count = struct.unpack_from(">I", data, block_offset)[0]
        header_end = block_offset + 4 + rec_count * 16
        first_tag = data[header_end:header_end + 4] if header_end + 4 <= len(data) else b""
        if rec_count > 0 and rec_count < 5000 and first_tag == XFCU_MAGIC:
            print(f"  scripts_vz is raw XFCU (no segs wrapper) at 0x{block_offset:X}, {rec_count} records")
            actual_end = block_size
            raw = data[block_offset:block_offset + actual_end]
            while actual_end > 4 and raw[actual_end - 1] == 0:
                actual_end -= 1
            actual_end = (actual_end + 3) & ~3
            decompressed = raw[:actual_end]
        else:
            print(f"  ERROR: Unrecognized block format at 0x{block_offset:X}: magic={magic!r}")
            return None

    print(f"  Decompressed: {len(decompressed):,} bytes")
    decomp_sha256 = hashlib.sha256(decompressed).hexdigest()

    (plat_dir / "scripts_vz.block.bin").write_bytes(decompressed)

    return _analyze_scripts_block(decompressed, "big", platform, scripts_idx,
                                   paths[scripts_idx] if scripts_idx < len(paths) else "?",
                                   compressed_size, plat_dir)


def _analyze_scripts_block(
    decompressed: bytes,
    endian: str,
    platform: str,
    block_idx: int,
    block_path: str,
    compressed_size: int,
    plat_dir: Path,
) -> ScriptsBlockInfo:
    """Analyze entries in a decompressed scripts_vz block."""
    decomp_sha256 = hashlib.sha256(decompressed).hexdigest()

    entries = parse_block_entries_endian(decompressed, endian)
    print(f"  UCFX entries: {len(entries)}")

    script_entries: list[ScriptEntry] = []
    bytecode_dir = plat_dir / "bytecode"
    bytecode_dir.mkdir(parents=True, exist_ok=True)

    for entry in entries:
        name = get_script_name_endian(decompressed, entry, endian)
        chunk_data = decompressed[entry["offset"]:entry["offset"] + entry["size"]]
        chunk_sha256 = hashlib.sha256(chunk_data).hexdigest()

        bc, bc_info = extract_lua_bytecode_info(decompressed, entry)
        bc_size = len(bc) if bc is not None else None

        if bc is not None:
            (bytecode_dir / f"{name}.luac").write_bytes(bc)

        se = ScriptEntry(
            index=entry["index"],
            name=name,
            name_hash=entry["hash"],
            type_hash=entry["type_hash"],
            chunk_size=entry["size"],
            bytecode_size=bc_size,
            luaq_header=bc_info,
            sha256=chunk_sha256,
        )
        script_entries.append(se)

        bc_info_str = ""
        if bc_info:
            bc_info_str = (f" lua={bc_info.get('version','?'):02X} "
                          f"endian={bc_info.get('endian_label','')} "
                          f"int={bc_info.get('int_size','')} "
                          f"size_t={bc_info.get('size_t_size','')} "
                          f"num={bc_info.get('number_size','')}")

        print(f"    [{entry['index']:3d}] {name:35s} hash=0x{entry['hash']:08X} "
              f"size={entry['size']:8,} bc={bc_size or 0:7,}{bc_info_str}")

    # Write entry inventory JSON
    inventory = {
        "platform": platform,
        "block_index": block_idx,
        "block_path": block_path,
        "compressed_size": compressed_size,
        "decompressed_size": len(decompressed),
        "decompressed_sha256": decomp_sha256,
        "entry_count": len(entries),
        "entries": [asdict(se) for se in script_entries],
    }
    (plat_dir / "scripts_vz_inventory.json").write_text(
        json.dumps(inventory, indent=2), encoding="utf-8"
    )

    return ScriptsBlockInfo(
        platform=platform,
        block_index=block_idx,
        block_path=block_path,
        compressed_size=compressed_size,
        decompressed_size=len(decompressed),
        decompressed_sha256=decomp_sha256,
        entry_count=len(entries),
        entries=script_entries,
    )


def compare_platforms(
    results: dict[str, tuple[WADInfo, ScriptsBlockInfo | None]],
    out_dir: Path,
) -> str:
    """Generate the cross-platform comparison report."""
    lines: list[str] = []
    lines.append("# Mercenaries 2 — Cross-Platform scripts_vz Forensic Comparison")
    lines.append("")
    lines.append("## WAD File Summary")
    lines.append("")
    lines.append("| Platform | File Size | SHA256 (first 16) | Endian | Blocks | ASET | PTHS |")
    lines.append("|----------|-----------|-------------------|--------|--------|------|------|")
    for plat, (wad, _) in results.items():
        lines.append(
            f"| {plat} | {wad.file_size:,} | `{wad.sha256[:16]}` | "
            f"{wad.endian} | {wad.block_count} | {wad.aset_count} | {wad.path_count} |"
        )

    lines.append("")
    lines.append("## scripts_vz Block Location")
    lines.append("")
    lines.append("| Platform | Block Index | PTHS Path | Compressed | Decompressed | Entries |")
    lines.append("|----------|------------|-----------|------------|-------------|---------|")
    for plat, (wad, sb) in results.items():
        if sb:
            lines.append(
                f"| {plat} | {sb.block_index} | `{sb.block_path}` | "
                f"{sb.compressed_size:,} | {sb.decompressed_size:,} | {sb.entry_count} |"
            )
        else:
            lines.append(f"| {plat} | {wad.scripts_vz_index or 'N/A'} | "
                        f"`{wad.scripts_vz_path or 'NOT FOUND'}` | — | — | — |")

    # Build name→entry maps per platform
    platform_entries: dict[str, dict[str, ScriptEntry]] = {}
    for plat, (_, sb) in results.items():
        if sb:
            platform_entries[plat] = {e.name: e for e in sb.entries}
        else:
            platform_entries[plat] = {}

    all_names: set[str] = set()
    for emap in platform_entries.values():
        all_names |= set(emap.keys())

    # Sort by name
    sorted_names = sorted(all_names)
    platforms_with_data = [p for p in results if platform_entries.get(p)]

    lines.append("")
    lines.append("## Entry-by-Entry Comparison")
    lines.append("")

    # Which entries exist on each platform?
    header = "| Script Name | " + " | ".join(platforms_with_data) + " |"
    separator = "|-------------|" + "|".join(["-------"] * len(platforms_with_data)) + "|"
    lines.append(header)
    lines.append(separator)

    for name in sorted_names:
        row = f"| `{name}` |"
        for plat in platforms_with_data:
            entry = platform_entries[plat].get(name)
            if entry:
                row += f" {entry.chunk_size:,} bytes |"
            else:
                row += " **MISSING** |"
        lines.append(row)

    # Platform-exclusive entries
    lines.append("")
    lines.append("## Platform-Exclusive Entries")
    lines.append("")

    for plat in platforms_with_data:
        exclusive = set(platform_entries[plat].keys())
        for other_plat in platforms_with_data:
            if other_plat != plat:
                exclusive -= set(platform_entries[other_plat].keys())
        if exclusive:
            lines.append(f"### Only on {plat}")
            lines.append("")
            for name in sorted(exclusive):
                e = platform_entries[plat][name]
                bc_str = f", bytecode={e.bytecode_size:,}" if e.bytecode_size else ""
                lines.append(f"- `{name}` (hash=0x{e.name_hash:08X}, size={e.chunk_size:,}{bc_str})")
            lines.append("")

    # Critical DLC-related entries
    lines.append("## DLC-Critical Entry Analysis")
    lines.append("")

    dlc_names = ["vz", "wifmissionflow", "wifpmcinterior", "dlc01",
                 "dlccon001", "dlccon002", "dlccon003", "dlccon004"]

    for name in dlc_names:
        lines.append(f"### `{name}`")
        lines.append("")
        found_any = False
        for plat in platforms_with_data:
            entry = platform_entries[plat].get(name)
            if entry:
                found_any = True
                bc_info = ""
                if entry.luaq_header:
                    h = entry.luaq_header
                    bc_info = (f"  - Lua bytecode: version=0x{h.get('version', 0):02X}, "
                              f"endian={h.get('endian_label', '?')}, "
                              f"int={h.get('int_size', '?')}, "
                              f"size_t={h.get('size_t_size', '?')}, "
                              f"number_size={h.get('number_size', '?')}, "
                              f"mercs2_Q={h.get('mercs2_q_marker', '?')}")
                lines.append(f"- **{plat}**: hash=0x{entry.name_hash:08X}, "
                            f"chunk_size={entry.chunk_size:,}, "
                            f"bytecode_size={entry.bytecode_size or 0:,}, "
                            f"sha256=`{entry.sha256[:16]}`")
                if bc_info:
                    lines.append(bc_info)
            else:
                lines.append(f"- **{plat}**: **NOT PRESENT**")
        if not found_any:
            lines.append("- Not present on any platform")
        lines.append("")

    # Lua header comparison for shared entries
    lines.append("## Lua Bytecode Header Comparison (shared entries)")
    lines.append("")
    lines.append("For entries present on multiple platforms, compare the Lua bytecode headers:")
    lines.append("")

    if len(platforms_with_data) >= 2:
        p1 = platforms_with_data[0]
        for p2 in platforms_with_data[1:]:
            shared = set(platform_entries[p1].keys()) & set(platform_entries[p2].keys())
            lines.append(f"### {p1} vs {p2}")
            lines.append("")
            lines.append(f"Shared entries: {len(shared)}")
            lines.append("")

            same_hash = 0
            diff_hash = 0
            diff_details: list[str] = []

            for name in sorted(shared):
                e1 = platform_entries[p1][name]
                e2 = platform_entries[p2][name]
                if e1.sha256 == e2.sha256:
                    same_hash += 1
                else:
                    diff_hash += 1
                    size_delta = e2.chunk_size - e1.chunk_size
                    bc_delta = (e2.bytecode_size or 0) - (e1.bytecode_size or 0)
                    diff_details.append(
                        f"- `{name}`: {p1}={e1.chunk_size:,}b/{e1.bytecode_size or 0:,}bc "
                        f"vs {p2}={e2.chunk_size:,}b/{e2.bytecode_size or 0:,}bc "
                        f"(delta chunk={size_delta:+,}, bc={bc_delta:+,})"
                    )

            lines.append(f"- Identical (same SHA256): {same_hash}")
            lines.append(f"- Different: {diff_hash}")
            if diff_details:
                lines.append("")
                lines.append("Differing entries:")
                lines.extend(diff_details)
            lines.append("")

    # Summary / smoking gun
    lines.append("## Key Findings for DLC Activation")
    lines.append("")
    lines.append("### The `vz` master script question")
    lines.append("")

    for plat in platforms_with_data:
        vz = platform_entries[plat].get("vz")
        if vz:
            lines.append(f"- **{plat}**: `vz` IS present "
                        f"(hash=0x{vz.name_hash:08X}, size={vz.chunk_size:,}, "
                        f"bytecode={vz.bytecode_size or 0:,})")
        else:
            lines.append(f"- **{plat}**: `vz` is **NOT present**")

    lines.append("")
    lines.append("### Implications")
    lines.append("")
    lines.append("If `vz` is present on Xbox 360 but not PC, this confirms Pandemic "
                 "shipped an incomplete scripts_vz block on PC that lacks the master "
                 "script needed for the `import()` chain. The PC engine still tries to "
                 "load `vz` as the master script (visible in the 'Loading vz level with "
                 "vz masterscript' log message), but since the chunk doesn't exist in "
                 "the retail WAD, the game relies on the executable's embedded Lua state "
                 "to bootstrap instead.")
    lines.append("")

    return "\n".join(lines)


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Cross-platform forensic comparison of Mercenaries 2 scripts_vz blocks"
    )
    ap.add_argument("--pc-wad", type=Path, help="PC retail vz.wad")
    ap.add_argument("--xbox-wad", type=Path, help="Xbox 360 vz.wad (big-endian SCFF)")
    ap.add_argument("--ps3-wad", type=Path, help="PS3 VZ.WAD")
    ap.add_argument("--demo-wad", type=Path, help="PC Demo vz.wad")
    ap.add_argument("--output", "-o", type=Path, default=Path("analysis/cross_platform"),
                    help="Output directory")
    args = ap.parse_args()

    args.output.mkdir(parents=True, exist_ok=True)

    results: dict[str, tuple[WADInfo, ScriptsBlockInfo | None]] = {}

    for plat, path in [
        ("PC Retail", args.pc_wad),
        ("Xbox 360", args.xbox_wad),
        ("PS3", args.ps3_wad),
        ("PC Demo", args.demo_wad),
    ]:
        if path and path.is_file():
            try:
                wad_info, scripts_info = analyze_wad(path, plat, args.output)
                results[plat] = (wad_info, scripts_info)
            except Exception as e:
                print(f"\nERROR analyzing {plat}: {e}")
                import traceback
                traceback.print_exc()

    if not results:
        print("ERROR: No WAD files analyzed", file=sys.stderr)
        return 1

    # Generate comparison report
    print(f"\n{'='*70}")
    print("Generating comparison report...")
    print(f"{'='*70}")

    report = compare_platforms(results, args.output)
    report_path = args.output / "cross_platform_vz_comparison.md"
    report_path.write_text(report, encoding="utf-8")
    print(f"\nReport written to: {report_path}")

    # Also write a combined JSON
    combined = {}
    for plat, (wad, sb) in results.items():
        combined[plat] = {
            "wad": {
                "platform": wad.platform,
                "path": wad.path,
                "file_size": wad.file_size,
                "sha256": wad.sha256,
                "endian": wad.endian,
                "version": wad.version,
                "chunk_count": wad.chunk_count,
                "block_count": wad.block_count,
                "aset_count": wad.aset_count,
                "path_count": wad.path_count,
                "scripts_vz_index": wad.scripts_vz_index,
                "scripts_vz_path": wad.scripts_vz_path,
            },
            "scripts_block": asdict(sb) if sb else None,
        }
    (args.output / "cross_platform_combined.json").write_text(
        json.dumps(combined, indent=2), encoding="utf-8"
    )

    return 0


if __name__ == "__main__":
    sys.exit(main())
