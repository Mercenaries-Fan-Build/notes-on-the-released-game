#!/usr/bin/env python3
"""Compare block entry table layouts between PC and Xbox vz.wad files.

Extracts blocks from each WAD, decompresses them, and dumps
their entry table fields byte-by-byte to determine the exact layout
and any platform differences.
"""
from __future__ import annotations

import struct
import sys
import zlib
from pathlib import Path

PC_WAD = Path(r"c:\Users\Shadow\Desktop\notes-on-the-released-game\game-files\pc-game-vz.wad")
XBOX_WAD = Path(r"c:\Users\Shadow\Desktop\notes-on-the-released-game\game-files\xbox-vz.wad")

PAGE_SIZE = 0x8000


def parse_pc_ffcs(wad_path: Path):
    with open(wad_path, "rb") as f:
        magic = f.read(4)
        assert magic == b"FFCS"
        version = struct.unpack("<I", f.read(4))[0]
        chunk_count = struct.unpack("<I", f.read(4))[0]
        chunks = []
        for _ in range(min(chunk_count, 5)):
            tag = f.read(4).decode("ascii", errors="replace")
            offset = struct.unpack("<I", f.read(4))[0]
            meta = struct.unpack("<I", f.read(4))[0]
            chunks.append((tag, offset, meta))
    indx = next((c for c in chunks if c[0] == "INDX"), None)
    pths = next((c for c in chunks if c[0] == "PTHS"), None)
    return {
        "indx_offset": indx[1] if indx else 0,
        "indx_meta": indx[2] if indx else 0,
        "pths_offset": pths[1] if pths else 0,
    }


def read_pc_indx(wad_path: Path, offset: int, count: int):
    entries = []
    with open(wad_path, "rb") as f:
        f.seek(offset)
        for _ in range(count):
            data = f.read(12)
            if len(data) < 12:
                break
            page_idx, packed, flags_pages = struct.unpack("<III", data)
            entries.append({
                "page_index": page_idx,
                "page_count": flags_pages & 0xFFFF,
                "file_offset": page_idx * PAGE_SIZE,
            })
    return entries


def decompress_pc_sges(wad_path: Path, file_offset: int, max_pages: int) -> bytes:
    block_size = max_pages * PAGE_SIZE
    with open(wad_path, "rb") as f:
        f.seek(file_offset)
        raw = f.read(block_size)

    if raw[:4] != b"sges":
        raise ValueError(f"Expected sges at 0x{file_offset:X}, got {raw[:4]!r}")

    major, seg_count = struct.unpack_from("<HH", raw, 4)
    total_u, total_c = struct.unpack_from("<II", raw, 8)

    seg_entries = []
    for i in range(seg_count):
        entry_off = 16 + i * 8
        comp_sz, uncomp_sz, abs_off_raw = struct.unpack_from("<HHI", raw, entry_off)
        compressed_flag = bool(abs_off_raw & 1)
        abs_off = abs_off_raw & 0xFFFFFFFE
        if uncomp_sz == 0:
            uncomp_sz = 65536
        seg_entries.append((comp_sz, uncomp_sz, abs_off, compressed_flag))

    out = bytearray()
    for i, (comp_sz, uncomp_sz, abs_off, compressed_flag) in enumerate(seg_entries):
        if len(out) >= total_u:
            break
        pos = abs_off
        if pos >= len(raw):
            break
        if compressed_flag:
            next_off = seg_entries[i + 1][2] if i + 1 < len(seg_entries) else len(raw)
            chunk = raw[pos:min(next_off, pos + 131072, len(raw))]
            try:
                dec = zlib.decompressobj(-15)
                piece = dec.decompress(chunk)
                out.extend(piece)
            except zlib.error:
                break
        else:
            actual_sz = comp_sz if comp_sz > 0 else uncomp_sz
            out.extend(raw[pos:pos + actual_sz])

    if len(out) > total_u:
        del out[total_u:]
    return bytes(out)


def parse_xbox_ffcs(wad_path: Path):
    with open(wad_path, "rb") as f:
        magic = f.read(4)
        assert magic in (b"SCFF", b"FFCS"), f"Got {magic!r}"
        version = struct.unpack(">I", f.read(4))[0]
        chunk_count = struct.unpack(">I", f.read(4))[0]
        chunks = []
        for _ in range(min(chunk_count, 5)):
            tag = f.read(4)[::-1].decode("ascii", errors="replace")
            offset = struct.unpack(">I", f.read(4))[0]
            meta = struct.unpack(">I", f.read(4))[0]
            chunks.append((tag, offset, meta))
    indx = next((c for c in chunks if c[0] == "INDX"), None)
    pths = next((c for c in chunks if c[0] == "PTHS"), None)
    return {
        "indx_offset": indx[1] if indx else 0,
        "indx_meta": indx[2] if indx else 0,
        "pths_offset": pths[1] if pths else 0,
    }


def read_xbox_indx(wad_path: Path, offset: int, count: int):
    entries = []
    with open(wad_path, "rb") as f:
        f.seek(offset)
        for _ in range(count):
            data = f.read(12)
            if len(data) < 12:
                break
            page_idx, packed, flags_pages = struct.unpack(">III", data)
            entries.append({
                "page_index": page_idx,
                "page_count": flags_pages & 0xFFFF,
                "file_offset": page_idx * PAGE_SIZE,
            })
    return entries


def decompress_xbox_sges(wad_path: Path, file_offset: int, max_pages: int) -> bytes:
    block_size = max_pages * PAGE_SIZE
    with open(wad_path, "rb") as f:
        f.seek(file_offset)
        raw = f.read(block_size)

    if raw[:4] not in (b"segs", b"sges"):
        raise ValueError(f"Expected segs/sges at 0x{file_offset:X}, got {raw[:4]!r}")

    seg_count = struct.unpack_from(">H", raw, 6)[0]
    total_u = struct.unpack_from(">I", raw, 8)[0]

    seg_table = []
    for i in range(seg_count):
        so = 16 + i * 8
        csz = struct.unpack_from(">H", raw, so)[0]
        dsz = struct.unpack_from(">H", raw, so + 2)[0]
        seg_table.append((csz, dsz))

    seg_table_bytes = seg_count * 8
    header_size = 16 + ((seg_table_bytes + 15) & ~15) if seg_count > 0 else 16
    payload = raw[header_size:]

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

    if len(result) > total_u:
        del result[total_u:]
    return bytes(result)


def read_pc_paths(wad_path: Path, pths_offset: int) -> list[str]:
    with open(wad_path, "rb") as f:
        f.seek(pths_offset)
        blob = f.read(2_000_000)
    paths = []
    for seq in blob.split(b"\x00"):
        if len(seq) < 6:
            continue
        try:
            s = seq.decode("utf-8")
        except UnicodeDecodeError:
            continue
        if "\\" in s or "/" in s:
            paths.append(s)
        if len(paths) > 12000:
            break
    return paths


def analyze_entry_table(block_data: bytes, endian: str, label: str):
    """Parse entry table and correlate with UCFX positions."""
    if len(block_data) < 4:
        return None

    entry_count = struct.unpack_from(f"{endian}I", block_data, 0)[0]
    if entry_count == 0 or entry_count > 10000:
        print(f"  [{label}] Bad entry_count={entry_count}")
        return None

    header_end = 4 + entry_count * 16
    if header_end > len(block_data):
        print(f"  [{label}] Block too small for {entry_count} entries")
        return None

    print(f"  [{label}] entry_count={entry_count}, header_end=0x{header_end:X}, "
          f"block_size={len(block_data)}")

    entries = []
    for i in range(entry_count):
        off = 4 + i * 16
        f0, f1, f2, f3 = struct.unpack_from(f"{endian}IIII", block_data, off)
        entries.append((f0, f1, f2, f3))
        if i < 10:
            print(f"    [{i}] name=0x{f0:08X} type=0x{f1:08X} f2=0x{f2:08X} f3=0x{f3:08X}")

    # Find UCFX chunks in data area
    ucfx_magic = b"UCFX" if endian == "<" else b"XFCU"
    csum_magic = b"CSUM" if endian == "<" else b"MSUC"

    pos = header_end
    ucfx_info = []
    for i in range(min(entry_count, 10)):
        if pos + 8 > len(block_data):
            break
        tag = block_data[pos:pos + 4]
        if tag != ucfx_magic:
            print(f"    UCFX scan: expected {ucfx_magic!r} at 0x{pos:X}, got {tag!r}")
            break
        body_size = struct.unpack_from(f"{endian}I", block_data, pos + 4)[0]
        ucfx_info.append({"abs_offset": pos, "body_size": body_size})

        # Check CSUM trailer
        csum_pos = pos + 8 + body_size
        has_csum = False
        if csum_pos + 8 <= len(block_data):
            ct = block_data[csum_pos:csum_pos + 4]
            if ct == csum_magic:
                has_csum = True
                next_pos = csum_pos + 8
            else:
                next_pos = pos + 8 + body_size
        else:
            next_pos = pos + 8 + body_size

        total_chunk = next_pos - pos
        if i < 10:
            print(f"    UCFX[{i}] at 0x{pos:X}: body=0x{body_size:X} "
                  f"total(w/CSUM)=0x{total_chunk:X} has_csum={has_csum}")
        pos = next_pos

    # Correlation
    if entries and ucfx_info:
        print(f"\n  [{label}] CORRELATION:")
        for i, ((f0, f1, f2, f3), ucfx) in enumerate(zip(entries[:10], ucfx_info)):
            offset_from_data_start = ucfx["abs_offset"] - header_end
            chunk_total = ucfx["body_size"] + 8 + 8  # UCFX hdr + body + CSUM
            data_area_size = len(block_data) - header_end

            match_f2_offset = "YES" if f2 == offset_from_data_start else "no"
            match_f3_total = "YES" if f3 == chunk_total else "no"
            match_f3_data_area = "YES" if f3 == data_area_size else "no"

            # For multi-entry: check if f3 = size of this specific chunk
            print(f"    [{i}] f2=0x{f2:08X} offset_from_data_start=0x{offset_from_data_start:X} ({match_f2_offset})")
            print(f"         f3=0x{f3:08X} chunk_total=0x{chunk_total:X} ({match_f3_total}) "
                  f"data_area_total=0x{data_area_size:X} ({match_f3_data_area})")

    return {"entry_count": entry_count, "entries": entries, "ucfx": ucfx_info}


def main():
    print("=" * 80)
    print("ENTRY TABLE LAYOUT COMPARISON: PC vs Xbox vz.wad")
    print("=" * 80)

    # Parse headers
    pc_info = parse_pc_ffcs(PC_WAD)
    xbox_info = parse_xbox_ffcs(XBOX_WAD)

    pc_indx = read_pc_indx(PC_WAD, pc_info["indx_offset"], pc_info["indx_meta"])
    xbox_indx = read_xbox_indx(XBOX_WAD, xbox_info["indx_offset"], xbox_info["indx_meta"])
    pc_paths = read_pc_paths(PC_WAD, pc_info["pths_offset"])

    print(f"PC: {len(pc_indx)} blocks, {len(pc_paths)} paths")
    print(f"Xbox: {len(xbox_indx)} blocks")

    # PHASE 1: Find multi-entry blocks on PC
    print("\n" + "=" * 80)
    print("PHASE 1: SCANNING FOR MULTI-ENTRY BLOCKS (PC)")
    print("=" * 80)

    multi_entry = []
    for idx in range(min(len(pc_indx), 2000)):
        e = pc_indx[idx]
        try:
            block = decompress_pc_sges(PC_WAD, e["file_offset"], e["page_count"])
            if len(block) < 8:
                continue
            cnt = struct.unpack_from("<I", block, 0)[0]
            if cnt > 1 and cnt < 5000:
                multi_entry.append((idx, cnt, len(block)))
                if len(multi_entry) >= 10:
                    break
        except Exception:
            continue

    if multi_entry:
        print(f"  Found {len(multi_entry)} multi-entry blocks:")
        for idx, cnt, sz in multi_entry:
            path = pc_paths[idx] if idx < len(pc_paths) else "?"
            print(f"    [{idx}] entries={cnt} size={sz} path={path}")
    else:
        print("  No multi-entry blocks found in first 2000!")

    # PHASE 2: Detailed dump of multi-entry blocks
    print("\n" + "=" * 80)
    print("PHASE 2: DETAILED MULTI-ENTRY ANALYSIS")
    print("=" * 80)

    for idx, cnt, _ in multi_entry[:4]:
        print(f"\n{'=' * 70}")
        print(f"BLOCK {idx} (entries={cnt})")
        if idx < len(pc_paths):
            print(f"  Path: {pc_paths[idx]}")
        print("=" * 70)

        # PC
        e = pc_indx[idx]
        print(f"\n  -- PC --")
        try:
            block = decompress_pc_sges(PC_WAD, e["file_offset"], e["page_count"])
            analyze_entry_table(block, "<", "PC")
        except Exception as ex:
            print(f"  ERROR: {ex}")

        # Xbox (same index)
        if idx < len(xbox_indx):
            xe = xbox_indx[idx]
            print(f"\n  -- Xbox --")
            try:
                xblock = decompress_xbox_sges(XBOX_WAD, xe["file_offset"], xe["page_count"])
                analyze_entry_table(xblock, ">", "Xbox")
            except Exception as ex:
                print(f"  ERROR: {ex}")

    # PHASE 3: Single-entry f3 analysis
    print("\n" + "=" * 80)
    print("PHASE 3: SINGLE-ENTRY f3 SEMANTICS")
    print("=" * 80)
    print("  Checking if f3 == total_data_area_size for single-entry blocks:")
    print()

    for idx in [0, 1, 5, 10, 50, 100, 150]:
        if idx >= len(pc_indx):
            break
        e = pc_indx[idx]
        try:
            block = decompress_pc_sges(PC_WAD, e["file_offset"], e["page_count"])
            cnt = struct.unpack_from("<I", block, 0)[0]
            if cnt != 1:
                continue
            header_end = 4 + cnt * 16
            f3 = struct.unpack_from("<I", block, 4 + 12)[0]
            data_area = len(block) - header_end
            # Also check: UCFX body_size + 8 (CSUM) + 8 (UCFX hdr)?
            ucfx_body = struct.unpack_from("<I", block, header_end + 4)[0]
            ucfx_total = 8 + ucfx_body + 8

            print(f"  PC [{idx:4d}]: f3=0x{f3:06X}={f3:7d}  "
                  f"data_area={data_area:7d}  ucfx_total={ucfx_total:7d}  "
                  f"f3==data_area: {'YES' if f3==data_area else 'NO'}  "
                  f"f3==ucfx_total: {'YES' if f3==ucfx_total else 'NO'}")
        except Exception:
            pass

    print()
    for idx in [0, 1, 5, 10, 50, 100, 150]:
        if idx >= len(xbox_indx):
            break
        xe = xbox_indx[idx]
        try:
            block = decompress_xbox_sges(XBOX_WAD, xe["file_offset"], xe["page_count"])
            cnt = struct.unpack_from(">I", block, 0)[0]
            if cnt != 1:
                continue
            header_end = 4 + cnt * 16
            f3 = struct.unpack_from(">I", block, 4 + 12)[0]
            data_area = len(block) - header_end

            ucfx_magic_check = block[header_end:header_end+4]
            if ucfx_magic_check == b"XFCU":
                ucfx_body = struct.unpack_from(">I", block, header_end + 4)[0]
                ucfx_total = 8 + ucfx_body + 8
            else:
                ucfx_total = -1

            print(f"  Xbox[{idx:4d}]: f3=0x{f3:06X}={f3:7d}  "
                  f"data_area={data_area:7d}  ucfx_total={ucfx_total:7d}  "
                  f"f3==data_area: {'YES' if f3==data_area else 'NO'}  "
                  f"f3==ucfx_total: {'YES' if f3==ucfx_total else 'NO'}")
        except Exception:
            pass

    # PHASE 4: Xbox block matching by name_hash
    print("\n" + "=" * 80)
    print("PHASE 4: MATCHING PC MULTI-ENTRY BLOCKS ON XBOX BY name_hash")
    print("=" * 80)

    if multi_entry:
        # For each PC multi-entry block, get the name_hashes and search Xbox
        for idx, cnt, _ in multi_entry[:3]:
            e = pc_indx[idx]
            block = decompress_pc_sges(PC_WAD, e["file_offset"], e["page_count"])
            pc_name_hash_0 = struct.unpack_from("<I", block, 4)[0]

            print(f"\n  PC block {idx}: name_hash[0]=0x{pc_name_hash_0:08X}")
            print(f"  Searching Xbox blocks for matching name_hash...")

            # Search Xbox (same index might not match since Xbox has fewer blocks)
            found = False
            for xi in range(min(len(xbox_indx), 2000)):
                xe = xbox_indx[xi]
                try:
                    xblock = decompress_xbox_sges(XBOX_WAD, xe["file_offset"], xe["page_count"])
                    if len(xblock) < 8:
                        continue
                    xcnt = struct.unpack_from(">I", xblock, 0)[0]
                    if xcnt < 1 or xcnt > 5000:
                        continue
                    xname = struct.unpack_from(">I", xblock, 4)[0]
                    if xname == pc_name_hash_0:
                        print(f"  MATCH at Xbox index {xi} (entry_count={xcnt})")
                        print(f"  -- Xbox block {xi} --")
                        analyze_entry_table(xblock, ">", "Xbox-match")
                        found = True
                        break
                except Exception:
                    continue
            if not found:
                print(f"  No Xbox match found in first 2000 blocks")

    # PHASE 5: Final summary
    print("\n" + "=" * 80)
    print("FINAL SUMMARY")
    print("=" * 80)


if __name__ == "__main__":
    main()
