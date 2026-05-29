"""Inspect block 18 UCFX structure around the crash-causing bytes at 0xE4D8."""
import struct
import sys
sys.path.insert(0, 'tools')
from sges_decompress import decompress_sges_block

wad_path = r'C:\Users\Shadow\Desktop\Mercenaries 2 World in Flames\data\vz-patch.wad'

with open(wad_path, 'rb') as f:
    header = f.read(0x100)
    chunk_count = struct.unpack_from('<I', header, 8)[0]
    for i in range(min(chunk_count, 5)):
        base = 0x0C + i * 12
        tag = header[base:base+4]
        offset = struct.unpack_from('<I', header, base+4)[0]
        if tag == b'INDX':
            indx_off = offset
    f.seek(indx_off + 18 * 12)
    page_index, packed_field, flags_and_page_count = struct.unpack('<III', f.read(12))
    comp_pages = flags_and_page_count & 0xFFFF
    file_offset = page_index * 0x8000
    comp_size = comp_pages * 0x8000
    f.seek(file_offset)
    raw = f.read(comp_size)
    dec = decompress_sges_block(raw, 0, len(raw))

container_start = 0x14
data_area_off = 0x294

# desc[27] info
info_off = container_start + data_area_off + 0x0C9FA
info_size = 0x1A
info_data = dec[info_off:info_off+info_size]
print("Info for COMP containing target:")
print(f"  Hex: {info_data.hex()}")
nul = info_data.find(b'\x00')
info_name = info_data[:nul].decode('ascii', errors='replace') if nul > 0 else "?"
print(f"  Component name: {info_name}")
print()

# desc[28] schm
schm_off = container_start + data_area_off + 0x0CA14
schm_size = 0xA8
schm_data = dec[schm_off:schm_off+schm_size]
print("Schema for COMP containing target:")
print(f"  Hex: {schm_data[:64].hex()}")
print(f"  ... ({schm_size} bytes total)")
print()

# desc[29] data
data_start = container_start + data_area_off + 0x0CABC
data_size = 0x786C
target_body_off = 0x1774
print(f"Data chunk: start=0x{data_start:X}, size=0x{data_size:X}")
print(f"Target at data body offset: 0x{target_body_off:X}")
print()

# Show context around target offset
abs_target = data_start + target_body_off
print(f"Bytes around target (abs 0x{abs_target:X}):")
for row_start in range(-64, 80, 16):
    addr = abs_target + row_start
    if addr < 0 or addr + 16 > len(dec):
        continue
    hexbytes = dec[addr:addr+16].hex(' ')
    floats = []
    for fi in range(4):
        val = struct.unpack_from('<f', dec, addr + fi*4)[0]
        floats.append(f"{val:12.4f}")
    marker = " <-- TARGET" if row_start == 0 else ""
    sep = "  "
    print(f"  +0x{target_body_off + row_start:04X}: {hexbytes}  | {sep.join(floats)}{marker}")

# Try to find record boundaries - look for the schm to understand record size
print("\n\nSchema interpretation:")
# schm typically has: record_size(4), field_count(4), then field descriptors
if len(schm_data) >= 8:
    rec_size = struct.unpack_from('<I', schm_data, 0)[0]
    field_count = struct.unpack_from('<I', schm_data, 4)[0]
    print(f"  Record size: {rec_size} (0x{rec_size:X})")
    print(f"  Field count: {field_count}")
    print(f"  Total records in data: {data_size // rec_size if rec_size > 0 else '?'}")
    if rec_size > 0:
        record_idx = target_body_off // rec_size
        offset_in_record = target_body_off % rec_size
        print(f"  Target is in record {record_idx}, at offset 0x{offset_in_record:X} within record")
