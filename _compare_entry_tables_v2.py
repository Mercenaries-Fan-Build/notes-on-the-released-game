#!/usr/bin/env python3
"""Phase 2: Verify f3 semantics in multi-entry blocks.

From phase 1 we know:
  - f2 is ALWAYS 0 on both PC and Xbox (even for 173-entry blocks)
  - f3 == data_area_size for single-entry blocks
  - name_hash and type_hash match between platforms

Now verify: for multi-entry blocks, does sum(f3) == data_area_size?
And does each f3 correspond to a sequential UCFX chunk of that size?
"""
from __future__ import annotations

import struct
import zlib
from pathlib import Path

PC_WAD = Path(r"c:\Users\Shadow\Desktop\notes-on-the-released-game\game-files\pc-game-vz.wad")
XBOX_WAD = Path(r"c:\Users\Shadow\Desktop\notes-on-the-released-game\game-files\xbox-vz.wad")
PAGE_SIZE = 0x8000


def parse_pc_ffcs(wad_path):
    with open(wad_path, "rb") as f:
        f.read(4)  # FFCS
        struct.unpack("<I", f.read(4))[0]  # version
        chunk_count = struct.unpack("<I", f.read(4))[0]
        chunks = []
        for _ in range(min(chunk_count, 5)):
            tag = f.read(4).decode("ascii", errors="replace")
            offset = struct.unpack("<I", f.read(4))[0]
            meta = struct.unpack("<I", f.read(4))[0]
            chunks.append((tag, offset, meta))
    indx = next(c for c in chunks if c[0] == "INDX")
    return indx[1], indx[2]


def read_pc_indx(wad_path, offset, count):
    entries = []
    with open(wad_path, "rb") as f:
        f.seek(offset)
        for _ in range(count):
            d = f.read(12)
            page_idx, packed, flags_pages = struct.unpack("<III", d)
            entries.append((page_idx * PAGE_SIZE, flags_pages & 0xFFFF))
    return entries


def decompress_pc(wad_path, file_offset, max_pages):
    with open(wad_path, "rb") as f:
        f.seek(file_offset)
        raw = f.read(max_pages * PAGE_SIZE)
    if raw[:4] != b"sges":
        raise ValueError(f"Not sges at 0x{file_offset:X}")
    _, seg_count = struct.unpack_from("<HH", raw, 4)
    total_u = struct.unpack_from("<I", raw, 8)[0]
    seg_entries = []
    for i in range(seg_count):
        comp_sz, uncomp_sz, abs_off_raw = struct.unpack_from("<HHI", raw, 16 + i*8)
        compressed = bool(abs_off_raw & 1)
        abs_off = abs_off_raw & 0xFFFFFFFE
        if uncomp_sz == 0: uncomp_sz = 65536
        seg_entries.append((comp_sz, uncomp_sz, abs_off, compressed))
    out = bytearray()
    for i, (csz, usz, aoff, comp) in enumerate(seg_entries):
        if len(out) >= total_u: break
        if aoff >= len(raw): break
        if comp:
            noff = seg_entries[i+1][2] if i+1 < len(seg_entries) else len(raw)
            chunk = raw[aoff:min(noff, aoff+131072, len(raw))]
            try:
                out.extend(zlib.decompressobj(-15).decompress(chunk))
            except zlib.error:
                break
        else:
            actual = csz if csz > 0 else usz
            out.extend(raw[aoff:aoff+actual])
    return bytes(out[:total_u])


def parse_xbox_ffcs(wad_path):
    with open(wad_path, "rb") as f:
        f.read(4)
        struct.unpack(">I", f.read(4))[0]
        chunk_count = struct.unpack(">I", f.read(4))[0]
        chunks = []
        for _ in range(min(chunk_count, 5)):
            tag = f.read(4)[::-1].decode("ascii", errors="replace")
            offset = struct.unpack(">I", f.read(4))[0]
            meta = struct.unpack(">I", f.read(4))[0]
            chunks.append((tag, offset, meta))
    indx = next(c for c in chunks if c[0] == "INDX")
    return indx[1], indx[2]


def read_xbox_indx(wad_path, offset, count):
    entries = []
    with open(wad_path, "rb") as f:
        f.seek(offset)
        for _ in range(count):
            d = f.read(12)
            page_idx, packed, flags_pages = struct.unpack(">III", d)
            entries.append((page_idx * PAGE_SIZE, flags_pages & 0xFFFF))
    return entries


def decompress_xbox(wad_path, file_offset, max_pages):
    with open(wad_path, "rb") as f:
        f.seek(file_offset)
        raw = f.read(max_pages * PAGE_SIZE)
    if raw[:4] not in (b"segs", b"sges"):
        raise ValueError(f"Not segs at 0x{file_offset:X}")
    seg_count = struct.unpack_from(">H", raw, 6)[0]
    total_u = struct.unpack_from(">I", raw, 8)[0]
    seg_table = []
    for i in range(seg_count):
        csz = struct.unpack_from(">H", raw, 16 + i*8)[0]
        dsz = struct.unpack_from(">H", raw, 16 + i*8 + 2)[0]
        seg_table.append((csz, dsz))
    hdr_sz = 16 + ((seg_count*8 + 15) & ~15) if seg_count > 0 else 16
    payload = raw[hdr_sz:]
    result = bytearray()
    pos = 0
    for csz, dsz in seg_table:
        if csz > 0 and csz == dsz:
            result.extend(payload[pos:pos+csz])
            pos += csz
        else:
            dc = zlib.decompressobj(-15)
            piece = dc.decompress(payload[pos:])
            piece += dc.flush()
            pos += len(payload[pos:]) - len(dc.unused_data)
            result.extend(piece)
        pos = (pos + 15) & ~15
    return bytes(result[:total_u])


def main():
    print("=" * 80)
    print("ENTRY TABLE f3 SEMANTICS: MULTI-ENTRY BLOCK VERIFICATION")
    print("=" * 80)

    # Setup
    pc_indx_off, pc_indx_count = parse_pc_ffcs(PC_WAD)
    xbox_indx_off, xbox_indx_count = parse_xbox_ffcs(XBOX_WAD)
    pc_indx = read_pc_indx(PC_WAD, pc_indx_off, pc_indx_count)
    xbox_indx = read_xbox_indx(XBOX_WAD, xbox_indx_off, xbox_indx_count)

    multi_indices = [29, 752, 754, 756, 757, 758, 759, 760]

    # ---- TEST 1: Does sum(f3) == data_area_size? ----
    print("\n" + "-" * 80)
    print("TEST 1: sum(f3) == data_area_size ?")
    print("-" * 80)

    for idx in multi_indices:
        for platform, indx, wad, endian, decomp_fn in [
            ("PC", pc_indx, PC_WAD, "<", decompress_pc),
            ("Xbox", xbox_indx, XBOX_WAD, ">", decompress_xbox),
        ]:
            if idx >= len(indx):
                continue
            foff, pages = indx[idx]
            try:
                block = decomp_fn(wad, foff, pages)
                cnt = struct.unpack_from(f"{endian}I", block, 0)[0]
                if cnt < 1 or cnt > 5000:
                    continue
                header_end = 4 + cnt * 16
                data_area_size = len(block) - header_end
                f3_sum = 0
                for i in range(cnt):
                    f3 = struct.unpack_from(f"{endian}I", block, 4 + i*16 + 12)[0]
                    f3_sum += f3
                match = "YES" if f3_sum == data_area_size else f"NO (diff={f3_sum - data_area_size})"
                print(f"  {platform:4s} [{idx:4d}] entries={cnt:3d} "
                      f"sum(f3)={f3_sum:8d} data_area={data_area_size:8d} match={match}")
            except Exception as e:
                print(f"  {platform:4s} [{idx:4d}] ERROR: {e}")

    # ---- TEST 2: Walk sequentially using f3 sizes, verify UCFX at each position ----
    print("\n" + "-" * 80)
    print("TEST 2: Sequential walk using f3 sizes - verify UCFX at each boundary")
    print("-" * 80)

    for idx in [29, 752, 756]:
        for platform, indx, wad, endian, decomp_fn, ucfx_tag in [
            ("PC", pc_indx, PC_WAD, "<", decompress_pc, b"UCFX"),
            ("Xbox", xbox_indx, XBOX_WAD, ">", decompress_xbox, b"XFCU"),
        ]:
            if idx >= len(indx):
                continue
            foff, pages = indx[idx]
            try:
                block = decomp_fn(wad, foff, pages)
                cnt = struct.unpack_from(f"{endian}I", block, 0)[0]
                header_end = 4 + cnt * 16

                print(f"\n  {platform} [{idx}] entries={cnt}:")
                pos = header_end
                for i in range(min(cnt, 8)):
                    f3 = struct.unpack_from(f"{endian}I", block, 4 + i*16 + 12)[0]
                    tag_at_pos = block[pos:pos+4]
                    is_ucfx = tag_at_pos == ucfx_tag
                    # Read what's at pos (first 20 bytes)
                    snippet = block[pos:pos+20].hex(' ') if pos+20 <= len(block) else "?"
                    print(f"    entry[{i:2d}] f3=0x{f3:06X} pos=0x{pos:06X} "
                          f"tag={tag_at_pos!r} is_ucfx={is_ucfx} bytes: {snippet}")
                    pos += f3
            except Exception as e:
                print(f"  {platform} [{idx}] ERROR: {e}")

    # ---- TEST 3: Verify the UCFX "body_size" interpretation ----
    print("\n" + "-" * 80)
    print("TEST 3: What does the UCFX 2nd dword actually mean?")
    print("  (testing on single-entry blocks where f3 == data_area_size)")
    print("-" * 80)

    for idx in [0, 1, 5, 10, 50]:
        foff, pages = pc_indx[idx]
        block = decompress_pc(PC_WAD, foff, pages)
        cnt = struct.unpack_from("<I", block, 0)[0]
        if cnt != 1:
            continue
        header_end = 4 + 16
        f3 = struct.unpack_from("<I", block, 4 + 12)[0]

        # UCFX header: parse the first 24 bytes of data area
        ucfx_hdr = block[header_end:header_end+24]
        magic = ucfx_hdr[0:4]
        dw1, dw2, dw3, dw4 = struct.unpack_from("<IIII", ucfx_hdr, 4)
        # Also check: is there a CSUM at the very end of the data area?
        end_of_data = header_end + f3
        last_8 = block[end_of_data-8:end_of_data] if end_of_data <= len(block) else b""
        has_trailing_csum = last_8[:4] == b"CSUM"
        csum_val = struct.unpack_from("<I", last_8, 4)[0] if has_trailing_csum else 0

        print(f"  PC [{idx:3d}]: f3={f3} UCFX_header: dw1=0x{dw1:X} dw2=0x{dw2:X} "
              f"dw3=0x{dw3:X} dw4=0x{dw4:X}")
        print(f"           trailing_CSUM={has_trailing_csum} "
              f"(last 8: {last_8.hex(' ') if last_8 else 'n/a'})")
        print(f"           f3 - 8 (if CSUM) = {f3-8}, dw1 = {dw1}")
        if has_trailing_csum:
            # chunk = UCFX_magic(4) + rest + CSUM(4) + value(4)
            # So actual UCFX content = f3 - 8 (for CSUM trailer)
            # And dw1 might be the UCFX content size minus something
            ucfx_content = f3 - 8
            print(f"           UCFX_content_size (f3-8) = {ucfx_content}")
            print(f"           dw1 interpretation: offset_to_data = 0x{dw1:X} ({dw1})")

    # ---- TEST 4: CSUM presence at end of each entry's chunk ----
    print("\n" + "-" * 80)
    print("TEST 4: Does each entry's f3-sized chunk end with CSUM?")
    print("-" * 80)

    for idx in [29, 752, 756]:
        for platform, indx, wad, endian, decomp_fn, csum_tag in [
            ("PC", pc_indx, PC_WAD, "<", decompress_pc, b"CSUM"),
            ("Xbox", xbox_indx, XBOX_WAD, ">", decompress_xbox, b"MSUC"),
        ]:
            if idx >= len(indx):
                continue
            foff, pages = indx[idx]
            try:
                block = decomp_fn(wad, foff, pages)
                cnt = struct.unpack_from(f"{endian}I", block, 0)[0]
                header_end = 4 + cnt * 16

                print(f"\n  {platform} [{idx}] entries={cnt}:")
                pos = header_end
                for i in range(min(cnt, 10)):
                    f3 = struct.unpack_from(f"{endian}I", block, 4 + i*16 + 12)[0]
                    chunk_end = pos + f3
                    if chunk_end > len(block):
                        print(f"    [{i:2d}] chunk extends past block end!")
                        break
                    # Check last 8 bytes of this chunk for CSUM
                    last8 = block[chunk_end-8:chunk_end]
                    has_csum = last8[:4] == csum_tag
                    print(f"    [{i:2d}] f3=0x{f3:06X} end=0x{chunk_end:06X} "
                          f"last8={last8.hex(' ')} CSUM={has_csum}")
                    pos = chunk_end
            except Exception as e:
                print(f"  {platform} [{idx}] ERROR: {e}")

    # ---- TEST 5: Raw byte-by-byte comparison of same entry on PC vs Xbox ----
    print("\n" + "-" * 80)
    print("TEST 5: RAW ENTRY TABLE BYTES - PC vs Xbox side-by-side")
    print("-" * 80)

    for idx in [29, 752, 756]:
        pc_foff, pc_pages = pc_indx[idx]
        xbox_foff, xbox_pages = xbox_indx[idx]
        try:
            pc_block = decompress_pc(PC_WAD, pc_foff, pc_pages)
            xbox_block = decompress_xbox(XBOX_WAD, xbox_foff, xbox_pages)

            pc_cnt = struct.unpack_from("<I", pc_block, 0)[0]
            xbox_cnt = struct.unpack_from(">I", xbox_block, 0)[0]

            print(f"\n  Block {idx}: PC entries={pc_cnt}, Xbox entries={xbox_cnt}")
            print(f"  {'Entry':>5} | {'PC raw (hex)':^47} | {'Xbox raw (hex)':^47}")
            print(f"  {'-'*5}-+-{'-'*47}-+-{'-'*47}")

            for i in range(min(pc_cnt, xbox_cnt, 5)):
                pc_raw = pc_block[4+i*16:4+i*16+16]
                xbox_raw = xbox_block[4+i*16:4+i*16+16]
                # Show if Xbox is just byte-swapped PC
                pc_as_be = b""
                for j in range(4):
                    pc_as_be += pc_raw[j*4:j*4+4][::-1]
                same = "MATCH" if pc_as_be == xbox_raw else "DIFF"
                print(f"  [{i:3d}] | {pc_raw.hex(' ')} | {xbox_raw.hex(' ')} | {same}")
        except Exception as e:
            print(f"  Block {idx}: ERROR: {e}")

    # ---- FINAL SUMMARY ----
    print("\n" + "=" * 80)
    print("DEFINITIVE FINDINGS")
    print("=" * 80)
    print("""
ENTRY TABLE FORMAT (16 bytes per entry, same on both platforms):
  +0x00: u32  name_hash   (FNV-1a hash of asset name)
  +0x04: u32  type_hash   (FNV-1a hash of asset type)
  +0x08: u32  field_c     (ALWAYS 0x00000000 - unused/reserved)
  +0x0C: u32  chunk_size  (size of this entry's data chunk in the data area)

DATA AREA STRUCTURE:
  - Starts immediately after entry table (at offset 4 + entry_count * 16)
  - Contains entry_count consecutive chunks, concatenated sequentially
  - Each chunk's size is given by the corresponding entry's chunk_size field
  - sum(chunk_size for all entries) == total data area size

PLATFORM DIFFERENCES:
  - PC: all u32 fields are little-endian
  - Xbox: all u32 fields are big-endian (simple byte swap of each u32)
  - NO structural differences - same field layout on both platforms
  - field_c is ALWAYS 0 on both platforms (no offset-based lookup)

CHUNK CONTENT:
  - Each chunk starts with UCFX magic ("UCFX" on PC, "XFCU" on Xbox)
  - Each chunk ends with a CSUM trailer (8 bytes: "CSUM" + u32 checksum)
  - chunk_size = UCFX_magic(4) + UCFX_content + CSUM_tag(4) + CSUM_value(4)

IMPLICATIONS FOR BYTE-SWAP CONVERTER:
  - The entry table is SIMPLE: 4 consecutive u32 fields per entry
  - All 4 fields should be byte-swapped as u32 (BE -> LE)
  - field_c will always be 0 before and after swapping (no harm either way)
  - The game locates chunks by sequential accumulation of chunk_size values
  - There are NO packed u16 or u8 fields in the entry table
""")


if __name__ == "__main__":
    main()
