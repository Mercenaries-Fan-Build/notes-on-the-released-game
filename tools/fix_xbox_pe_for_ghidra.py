#!/usr/bin/env python3
"""Make the recovered Xbox-360 *image-dump* PE loadable by Ghidra's PE loader.

The decompressed XEX basefile is laid out by RVA (file offset == RVA), but its PE
section headers still hold the original on-disk PointerToRawData/SizeOfRawData
(which assume the compact disk layout). Ghidra reads bytes from PointerToRawData,
so it loads garbage/zeros. Fix: rewrite each section header so
PointerToRawData = VirtualAddress and SizeOfRawData = bytes available in the file
for that RVA range. Also set FileAlignment = SectionAlignment.
"""
import struct, sys
from pathlib import Path

src = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("output/jul08_prototype/mercs2_xenon_p.pe_full.bin")
dst = Path(sys.argv[2]) if len(sys.argv) > 2 else Path("output/jul08_prototype/mercs2_xenon_p.pe_ghidra.bin")

d = bytearray(src.read_bytes())
flen = len(d)
lf = struct.unpack_from("<I", d, 0x3c)[0]
assert d[lf:lf+4] == b"PE\0\0", "not a PE"
nsec = struct.unpack_from("<H", d, lf+6)[0]
opthdr = struct.unpack_from("<H", d, lf+20)[0]
opt = lf + 24
# SectionAlignment @ opt+0x20, FileAlignment @ opt+0x24 (PE32)
sect_align = struct.unpack_from("<I", d, opt+0x20)[0]
struct.pack_into("<I", d, opt+0x24, sect_align)   # FileAlignment = SectionAlignment
sectab = opt + opthdr

print(f"PE: {nsec} sections, SectionAlignment=0x{sect_align:x}, file=0x{flen:x}")
for i in range(nsec):
    o = sectab + i*40
    name = d[o:o+8].rstrip(b"\0").decode("latin1")
    vsize, va, rsize, raw = struct.unpack_from("<IIII", d, o+8)
    # bytes actually present in the file for this section = [va, min(va+vsize, flen))
    avail = max(0, min(va + vsize, flen) - va)
    # round down to a multiple that fits; keep full avail
    new_raw = va
    new_rsize = avail
    struct.pack_into("<I", d, o+16, new_rsize)   # SizeOfRawData
    struct.pack_into("<I", d, o+20, new_raw)     # PointerToRawData
    print(f"  {name:10} VA=0x{va:08x} vsize=0x{vsize:x}  raw 0x{raw:x}->0x{new_raw:x}  rsize 0x{rsize:x}->0x{new_rsize:x}")

dst.write_bytes(d)
print(f"wrote {dst} ({len(d):,} B)")
