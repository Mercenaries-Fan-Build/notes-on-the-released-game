#!/usr/bin/env python3
"""Correctly parse Xbox FFCS header and inspect sges block format."""
from __future__ import annotations
import struct
from pathlib import Path

FFCS_HEADER_SIZE = 0x100
PAGE_SIZE = 0x8000

def read_be_u32(data, off):
    return struct.unpack_from(">I", data, off)[0]

def read_be_u16(data, off):
    return struct.unpack_from(">H", data, off)[0]

def main():
    wad_path = Path("game-files/xbox-vz.wad")
    data = wad_path.read_bytes()
    
    print(f"=== Xbox FFCS Header Analysis ===")
    print(f"File: {wad_path} ({len(data):,} bytes)")
    
    # Header: magic(4) + version(4) + chunk_count(4) + rows(12 each)
    magic = data[0:4]
    version = read_be_u32(data, 4)
    chunk_count = read_be_u32(data, 8)
    print(f"Magic: {magic} (expected b'SCFF')")
    print(f"Version: {version}")
    print(f"Chunk count: {chunk_count}")
    
    chunks = {}
    for i in range(min(chunk_count, 7)):
        base = 0x0C + i * 12
        tag = data[base:base+4]
        offset = read_be_u32(data, base + 4)
        meta = read_be_u32(data, base + 8)
        tag_reversed = tag[::-1].decode("ascii", errors="replace")
        print(f"  Chunk {i}: tag={tag} ('{tag_reversed}') offset=0x{offset:08x} meta={meta}")
        chunks[tag_reversed] = (offset, meta)
    
    # Parse INDX
    if "INDX" in chunks:
        indx_offset, indx_count = chunks["INDX"]
        print(f"\n=== INDX: {indx_count} entries at file offset 0x{indx_offset:x} ===")
        
        # Read first few INDX entries (12 bytes each: page_index, packed_field, flags_and_page_count)
        for ei in range(min(5, indx_count)):
            eo = indx_offset + ei * 12
            page_index = read_be_u32(data, eo)
            packed_field = read_be_u32(data, eo + 4)
            flags_and_pcount = read_be_u32(data, eo + 8)
            decomp_pages = packed_field & 0x00FFFFFF
            comp_pages = flags_and_pcount & 0xFFFF
            print(f"  Entry {ei}: page_idx={page_index} decomp_pages={decomp_pages} "
                  f"comp_pages={comp_pages} packed=0x{packed_field:08x} flags=0x{flags_and_pcount:08x}")
            
            if ei == 0:
                # Read sges header at this block
                block_start = page_index * PAGE_SIZE
                if block_start + 64 < len(data):
                    hdr = data[block_start:block_start + 64]
                    print(f"\n  === sges block 0 at file offset 0x{block_start:x} ===")
                    print(f"  Magic: {hdr[0:4]}")
                    for row in range(4):
                        chunk = hdr[row*16:(row+1)*16]
                        hex_str = " ".join(f"{b:02x}" for b in chunk)
                        print(f"    +{row*16:02x}: {hex_str}")
                    
                    if hdr[0:4] == b"sges":
                        decomp_size = read_be_u32(hdr, 4)
                        field_08 = read_be_u32(hdr, 8)
                        field_0c = read_be_u32(hdr, 12)
                        print(f"\n  sges header fields (BE):")
                        print(f"    +04: decompressed_size = {decomp_size} (0x{decomp_size:x})")
                        print(f"    +08: 0x{field_08:08x} ({field_08})")
                        print(f"    +0C: 0x{field_0c:08x} ({field_0c})")
                        
                        # Segment sizes after 16-byte header (same as PC but BE u16)
                        print(f"\n  Segment table (BE u16 starting at +16):")
                        n_segs = comp_pages  # compressed pages = number of segments
                        for si in range(min(8, n_segs)):
                            seg_size = read_be_u16(hdr, 16 + si * 2)
                            print(f"    seg[{si}]: {seg_size} (0x{seg_size:04x})")
                        
                        # Compare: PC sges has 16-byte header then segment sizes
                        # If Xbox is the same but BE, we'd see valid segment sizes here
                        print(f"\n  Segment table interpretation:")
                        seg_total = 0
                        for si in range(min(n_segs, 24)):
                            off = 16 + si * 2
                            if off + 2 > 64:
                                break
                            seg_size = read_be_u16(data, block_start + off)
                            if seg_size == 0:
                                print(f"    seg[{si}]: 0 (sentinel/end)")
                                break
                            seg_total += seg_size
                            if si < 12:
                                print(f"    seg[{si}]: {seg_size}")
                        print(f"    Total segment bytes: {seg_total}")
                else:
                    print(f"  Block start 0x{block_start:x} beyond file!")
    
    # Scan for Lua in decompressed blocks
    print(f"\n=== Lua bytecode scan in first 20 blocks ===")
    if "INDX" in chunks:
        indx_offset, indx_count = chunks["INDX"]
        import zlib
        
        for bi in range(min(20, indx_count)):
            eo = indx_offset + bi * 12
            page_index = read_be_u32(data, eo)
            packed_field = read_be_u32(data, eo + 4)
            flags_and_pcount = read_be_u32(data, eo + 8)
            comp_pages = flags_and_pcount & 0xFFFF
            
            block_start = page_index * PAGE_SIZE
            block_end = block_start + comp_pages * PAGE_SIZE
            if block_end > len(data) or block_start >= len(data):
                continue
            
            sges_magic = data[block_start:block_start + 4]
            if sges_magic != b"sges":
                continue
            
            # Try to decompress first segment
            seg_table_off = block_start + 16
            first_seg_size = read_be_u16(data, seg_table_off)
            if first_seg_size == 0 or first_seg_size > PAGE_SIZE:
                continue
            
            # Find where compressed data starts (after segment table)
            n_segs = comp_pages
            data_start = seg_table_off + n_segs * 2
            # Align to next position
            compressed_seg = data[data_start:data_start + first_seg_size]
            
            try:
                decompressed = zlib.decompress(compressed_seg, -15)
                # Search for Lua magic
                lua_idx = decompressed.find(b"\x1bLua")
                if lua_idx >= 0:
                    lua_hdr = decompressed[lua_idx:lua_idx + 16]
                    print(f"  Block {bi}: Lua found at +0x{lua_idx:x} in decompressed data")
                    print(f"    version=0x{lua_hdr[4]:02x} format=0x{lua_hdr[5]:02x} "
                          f"endian=0x{lua_hdr[6]:02x} sizeof_int={lua_hdr[7]} "
                          f"sizeof_size_t={lua_hdr[8]} sizeof_instr={lua_hdr[9]} "
                          f"sizeof_number={lua_hdr[10]} integral=0x{lua_hdr[11]:02x}")
                    print(f"    Raw: {lua_hdr.hex()}")
                    break
            except Exception:
                continue
        else:
            print("  No Lua found in first 20 blocks")


if __name__ == "__main__":
    main()
