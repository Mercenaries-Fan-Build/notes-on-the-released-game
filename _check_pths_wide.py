import os

wad = 'output/data/vz-patch.wad'
sz = os.path.getsize(wad)
print(f'WAD size: {sz:,} bytes ({sz/1024/1024:.2f} MB)')

search_size = min(sz, 64 * 1024)
with open(wad, 'rb') as f:
    f.seek(sz - search_size)
    tail = f.read()

pths_pos = tail.find(b'PTHS')
if pths_pos >= 0:
    abs_offset = (sz - search_size) + pths_pos
    print(f'PTHS marker found at file offset {abs_offset} (0x{abs_offset:X})')
    print(f'Distance from EOF: {sz - abs_offset} bytes')
    pths_chunk = tail[pths_pos:pths_pos + 32]
    print(f'PTHS chunk bytes: {" ".join(f"{b:02X}" for b in pths_chunk)}')
else:
    print(f'PTHS marker NOT found in last {search_size:,} bytes')

    # Also search the beginning in case it's in the header area
    with open(wad, 'rb') as f:
        head = f.read(4096)
    pths_head = head.find(b'PTHS')
    if pths_head >= 0:
        print(f'PTHS found near start at offset {pths_head} (0x{pths_head:X})')
    else:
        # Full scan
        print('Doing full-file scan for PTHS...')
        with open(wad, 'rb') as f:
            offset = 0
            chunk = 1024 * 1024
            found = False
            while True:
                data = f.read(chunk)
                if not data:
                    break
                pos = data.find(b'PTHS')
                if pos >= 0:
                    abs_pos = offset + pos
                    print(f'PTHS found at offset {abs_pos} (0x{abs_pos:X})')
                    found = True
                    break
                offset += len(data) - 3
                f.seek(offset)
            if not found:
                print('PTHS NOT FOUND anywhere in file')
