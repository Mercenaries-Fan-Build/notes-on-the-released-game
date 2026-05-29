#!/usr/bin/env python3
"""Quick probe: Xbox sges header + Lua bytecode scan."""
from __future__ import annotations
import struct
import sys
from pathlib import Path

def probe_xbox_sges(wad_path: Path):
    data = wad_path.read_bytes()
    print(f"=== Xbox sges header: {wad_path} ===")
    print(f"File size: {len(data):,} bytes")
    print(f"Magic: {data[0:4]}")
    
    # Xbox FFCS: SCFF magic, reversed tags
    # Header: SCFF(4) + version(4) + ?(4) 
    # Then chunks: tag(4) + size(4) + body
    indx_off = 0x14  # XDNI at 0x0C, size at 0x10, body at 0x14
    
    # First INDX entry (BE)
    packed = struct.unpack_from(">I", data, indx_off)[0]
    page_idx = struct.unpack_from(">I", data, indx_off + 4)[0]
    page_count = packed & 0x3FFF
    print(f"\nFirst INDX entry: packed=0x{packed:08x} page_count={page_count} page_idx={page_idx}")
    
    block_start = page_idx * 0x8000
    if block_start + 64 > len(data):
        print(f"  Block start 0x{block_start:x} beyond file")
        return
    
    hdr = data[block_start:block_start + 64]
    print(f"\nBlock 0 at offset 0x{block_start:x}:")
    print(f"  Magic: {hdr[0:4]} ({hdr[0:4].hex()})")
    for row in range(4):
        chunk = hdr[row * 16:(row + 1) * 16]
        hex_str = " ".join(f"{b:02x}" for b in chunk)
        print(f"  +{row * 16:02x}: {hex_str}")
    
    if hdr[0:4] == b"sges":
        decomp = struct.unpack_from(">I", hdr, 4)[0]
        print(f"\n  sges header (BE u32s):")
        print(f"    +04: decompressed_size = {decomp} (0x{decomp:x})")
        print(f"    +08: 0x{struct.unpack_from('>I', hdr, 8)[0]:08x}")
        print(f"    +12: 0x{struct.unpack_from('>I', hdr, 12)[0]:08x}")
        print(f"    +16: 0x{struct.unpack_from('>I', hdr, 16)[0]:08x}")
        print(f"    +20: 0x{struct.unpack_from('>I', hdr, 20)[0]:08x}")
        print(f"    +24: 0x{struct.unpack_from('>I', hdr, 24)[0]:08x}")
        print(f"    +28: 0x{struct.unpack_from('>I', hdr, 28)[0]:08x}")
        
        # Check for segment table (u16 sizes) after header
        # PC format: 16-byte header, then u16 segment sizes
        # Let's see what's at offset 16
        print(f"\n  Potential segment sizes (as BE u16 pairs starting at +16):")
        for si in range(8):
            off = 16 + si * 2
            val = struct.unpack_from(">H", hdr, off)[0]
            print(f"    seg[{si}] @ +{off}: {val} (0x{val:04x})")
    
    # Also check block 1 for comparison
    entry2_off = indx_off + 16
    packed2 = struct.unpack_from(">I", data, entry2_off)[0]
    page_idx2 = struct.unpack_from(">I", data, entry2_off + 4)[0]
    page_count2 = packed2 & 0x3FFF
    block2_start = page_idx2 * 0x8000
    if block2_start + 32 < len(data):
        hdr2 = data[block2_start:block2_start + 32]
        print(f"\n  Block 1 at 0x{block2_start:x}: magic={hdr2[0:4]} ({hdr2[0:4].hex()})")


def probe_lua(wad_path: Path, big_endian: bool = False):
    """Scan for Lua bytecode magic in raw WAD data."""
    data = wad_path.read_bytes()
    print(f"\n=== Lua bytecode scan: {wad_path} (BE={big_endian}) ===")
    
    lua_magic = b"\x1bLua"
    pos = 0
    found = 0
    while found < 5:
        idx = data.find(lua_magic, pos)
        if idx < 0:
            break
        hdr = data[idx:idx + 20]
        if len(hdr) >= 12:
            version = hdr[4]
            fmt = hdr[5]
            endian = hdr[6]
            sz_int = hdr[7]
            sz_size_t = hdr[8]
            sz_instruction = hdr[9]
            sz_number = hdr[10]
            integral = hdr[11]
            print(f"  Found at offset 0x{idx:x}:")
            print(f"    version=0x{version:02x} format=0x{fmt:02x} endian=0x{endian:02x}")
            print(f"    sizeof: int={sz_int} size_t={sz_size_t} instr={sz_instruction} number={sz_number}")
            print(f"    integral_flag=0x{integral:02x}")
            print(f"    Raw: {hdr.hex()}")
            found += 1
        pos = idx + 1
    
    if found == 0:
        print("  No Lua bytecode found")


if __name__ == "__main__":
    xbox_wad = Path("game-files/xbox-vz.wad")
    if xbox_wad.exists():
        probe_xbox_sges(xbox_wad)
    
    # Scan DLC patch WAD for Lua
    patch_wad = Path("output/data/vz-patch.wad")
    if patch_wad.exists():
        probe_lua(patch_wad, big_endian=False)
    
    # Scan Xbox WAD for Lua
    if xbox_wad.exists():
        probe_lua(xbox_wad, big_endian=True)
    
    # Also scan the Xbox DLC source if available
    xbox_dlc_paths = list(Path("game-files").glob("**/dlc*.wad")) + list(Path("game-files").glob("**/DLC*.wad"))
    for p in xbox_dlc_paths[:2]:
        probe_lua(p, big_endian=True)
