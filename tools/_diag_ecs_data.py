"""Compare ECS_NODE 'data' chunk between DLC and retail to check for byte-swap errors."""
import struct, sys
sys.path.insert(0, '.')
from tools.sges_decompress import decompress_sges_block

PAGE_SIZE = 0x8000
ECS_TYPE = 0xE6B81A54
CHUNK_HDR = 20


def decompress_block(wad_raw, block_idx):
    chunks = {}
    for i in range(5):
        off = 0x0C + i * 12
        tag = wad_raw[off:off+4].decode('ascii')
        offset, meta = struct.unpack_from('<II', wad_raw, off + 4)
        chunks[tag] = (offset, meta)
    indx_off = chunks['INDX'][0]
    entry_off = indx_off + block_idx * 12
    page_idx, packed, flags_pages = struct.unpack_from('<III', wad_raw, entry_off)
    pages = flags_pages & 0xFFFF
    file_offset = page_idx * PAGE_SIZE
    blk_data = wad_raw[file_offset:file_offset + pages * PAGE_SIZE]
    return decompress_sges_block(blk_data, 0, len(blk_data))


def get_ecs_ucfx_chunks(decomp, endian='<'):
    """Get all UCFX chunks from the first ECS_NODE entry."""
    count = struct.unpack_from(f'{endian}I', decomp, 0)[0]
    header_end = 4 + count * 16
    pos = header_end
    for i in range(count):
        h, th, fc, s = struct.unpack_from(f'{endian}IIII', decomp, 4 + i * 16)
        if th == ECS_TYPE:
            entry_data = decomp[pos:pos+s]
            if entry_data[-8:-4] == b'CSUM':
                entry_data = entry_data[:-8]
            magic = entry_data[:4]
            if magic == b'UCFX':
                e = '<'
            elif magic == b'XFCU' or magic[::-1] == b'UCFX':
                e = '>'
            else:
                return None
            data_area_off = struct.unpack_from(f'{e}I', entry_data, 4)[0]
            n_desc = struct.unpack_from(f'{e}I', entry_data, 16)[0]
            chunks = {}
            for di in range(n_desc):
                row_off = 20 + di * CHUNK_HDR
                if row_off + CHUNK_HDR > len(entry_data):
                    break
                if e == '>':
                    tag = entry_data[row_off:row_off+4][::-1].decode('ascii', errors='replace')
                else:
                    tag = entry_data[row_off:row_off+4].decode('ascii', errors='replace')
                row_u0, body_size = struct.unpack_from(f'{e}II', entry_data, row_off + 4)
                body_start = (data_area_off + row_u0) if data_area_off > 0 else (8 + row_u0)
                body_end = body_start + body_size
                if body_end <= len(entry_data):
                    chunks[tag] = entry_data[body_start:body_end]
            return chunks, h
        pos += s
    return None, None


# Load WADs
with open(r'output\data\vz-patch.wad', 'rb') as f:
    dlc_raw = f.read()
with open(r'game-files\pc-game-vz.wad', 'rb') as f:
    retail_raw = f.read()

# Compare block 1 of DLC vs block 0 of retail
dlc_decomp = decompress_block(dlc_raw, 1)
retail_decomp = decompress_block(retail_raw, 0)

dlc_chunks, dlc_hash = get_ecs_ucfx_chunks(dlc_decomp)
retail_chunks, retail_hash = get_ecs_ucfx_chunks(retail_decomp)

print(f"DLC block 1 ECS hash: 0x{dlc_hash:08X}")
print(f"Retail block 0 ECS hash: 0x{retail_hash:08X}")
print()

for tag in ['CHDR', 'enum', 'info', 'schm', 'data', 'flgt', 'flgs']:
    d = dlc_chunks.get(tag)
    r = retail_chunks.get(tag)
    if d is None and r is None:
        continue
    d_size = len(d) if d else 0
    r_size = len(r) if r else 0
    print(f"Chunk '{tag}': DLC={d_size}, Retail={r_size}")
    if d and r and d_size == r_size:
        if d == r:
            print(f"  IDENTICAL")
        else:
            diffs = sum(1 for i in range(len(d)) if d[i] != r[i])
            print(f"  {diffs} byte differences")
            for i in range(len(d)):
                if d[i] != r[i]:
                    print(f"  First diff at 0x{i:X}")
                    print(f"    DLC:    {d[max(0,i-8):i+24].hex()}")
                    print(f"    Retail: {r[max(0,i-8):i+24].hex()}")
                    break
    elif d and r:
        print(f"  Size mismatch!")

# Also check: what does the retail 'data' chunk actually contain?
print("\n\n=== RETAIL 'data' chunk analysis ===")
rd = retail_chunks.get('data')
if rd:
    print(f"Size: {len(rd)} bytes")
    # Look for null-terminated strings
    strings_found = []
    pos = 0
    while pos < len(rd):
        if rd[pos] >= 0x20 and rd[pos] < 0x7F:
            start = pos
            while pos < len(rd) and rd[pos] >= 0x20 and rd[pos] < 0x7F:
                pos += 1
            s = rd[start:pos].decode('ascii')
            if len(s) >= 3:
                strings_found.append((start, s))
        else:
            pos += 1
    print(f"ASCII strings (len>=3): {len(strings_found)}")
    for spos, s in strings_found[:20]:
        print(f"  0x{spos:04X}: '{s}'")
    
    # Check if it's a structured format with null-terminated strings + u32 fields
    # or if the "strings" are coincidental byte patterns
    print(f"\n  Chunk mod 4: {len(rd) % 4}")
    # First 64 bytes
    print(f"  First 64 bytes: {rd[:64].hex()}")
    # Check byte at positions right after strings
    if strings_found:
        print(f"\n  Byte after each string:")
        for spos, s in strings_found[:5]:
            end_pos = spos + len(s)
            if end_pos < len(rd):
                print(f"    After '{s}' (offset 0x{end_pos:X}): 0x{rd[end_pos]:02X}")
