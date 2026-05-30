import os

wad = 'output/data/vz-patch.wad'
sz = os.path.getsize(wad)
print(f'WAD size: {sz:,} bytes ({sz/1024/1024:.2f} MB)')

with open(wad, 'rb') as f:
    f.seek(max(0, sz - 300))
    tail = f.read()

pths_pos = tail.find(b'PTHS')
if pths_pos >= 0:
    abs_offset = (sz - len(tail)) + pths_pos
    print(f'PTHS marker found at file offset {abs_offset} (0x{abs_offset:X})')
    print(f'Distance from EOF: {sz - abs_offset} bytes')
    pths_chunk = tail[pths_pos:pths_pos + 16]
    print(f'PTHS chunk header: {" ".join(f"{b:02X}" for b in pths_chunk)}')
else:
    print('PTHS marker NOT found in last 300 bytes')
    print('Tail hex dump (last 64 bytes):')
    last64 = tail[-64:]
    for i in range(0, len(last64), 16):
        chunk = last64[i:i+16]
        hex_str = ' '.join(f'{b:02X}' for b in chunk)
        ascii_str = ''.join(chr(b) if 32 <= b < 127 else '.' for b in chunk)
        print(f'  {hex_str}  {ascii_str}')
