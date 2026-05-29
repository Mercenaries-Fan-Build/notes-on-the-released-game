"""Full INDX comparison between DOH and PC patch - find all block size mismatches."""
import zipfile, struct

# PC vz-patch.wad
pc_path = r'c:\Users\Shadow\Desktop\notes-on-the-released-game\output\data\vz-patch.wad'
pc_data = open(pc_path, 'rb').read()
pc_indx_off = 0x8000
pc_n_blocks = 2197

# DOH Prototype
zpath = r'c:\Users\Shadow\Desktop\notes-on-the-released-game\game-files\Mercenaries 2 World in Flames (Nov 25, 2008 DLC Blow It Up Again Pack prototype).zip'
with zipfile.ZipFile(zpath, 'r') as zf:
    stfs_name = '45410828/00000002/8E3D23775BE3670DEC5B9CBEE489165F71BB14FE45'
    with zf.open(stfs_name) as f:
        stfs_raw = f.read(0x60000)  # enough for INDX

doh_start = 0xD000
doh_indx_off = doh_start + 0x8000  # INDX at 0x8000 within DOH
doh_n_blocks = 2196

# Read PTHS for block path names
pc_pths_off = 0x23BAC
pc_pths_data = pc_data[pc_pths_off:pc_pths_off + 200000]
pc_pths_strings = pc_pths_data.split(b'\x00')

print("Comparing INDX entries (2196 blocks common to both)...")
print("=" * 80)

mismatches = []
for i in range(min(pc_n_blocks - 1, doh_n_blocks)):  # skip last PC block (nohook)
    pc_off = pc_indx_off + i * 12
    doh_off = doh_indx_off + i * 12
    
    if doh_off + 12 > len(stfs_raw):
        print(f"  DOH buffer exhausted at block {i}")
        break
    
    pc_page, pc_packed, pc_fp = struct.unpack_from('<III', pc_data, pc_off)
    doh_page, doh_packed, doh_fp = struct.unpack_from('>III', stfs_raw, doh_off)
    
    pc_pages = pc_fp & 0xFFFF
    doh_pages = doh_fp & 0xFFFF
    pc_flags = pc_fp >> 16
    doh_flags = doh_fp >> 16
    
    if pc_packed != doh_packed or pc_pages != doh_pages:
        path = pc_pths_strings[i].decode('ascii', errors='replace') if i < len(pc_pths_strings) else '?'
        mismatches.append({
            'idx': i, 'path': path,
            'pc_packed': pc_packed, 'doh_packed': doh_packed,
            'pc_pages': pc_pages, 'doh_pages': doh_pages,
            'pc_flags': pc_flags, 'doh_flags': doh_flags,
        })

print(f"\nTotal mismatches: {len(mismatches)}")
print(f"\nAll mismatched blocks:")
for m in mismatches:
    delta_pages = m['doh_pages'] - m['pc_pages']
    delta_str = f"+{delta_pages}" if delta_pages > 0 else str(delta_pages)
    print(f"  [{m['idx']:4d}] packed: PC=0x{m['pc_packed']:08X} DOH=0x{m['doh_packed']:08X} | "
          f"pages: PC={m['pc_pages']} DOH={m['doh_pages']} ({delta_str}) | "
          f"flags: PC=0x{m['pc_flags']:04X} DOH=0x{m['doh_flags']:04X}")
    print(f"         path: {m['path']}")

# Summary
if mismatches:
    truncated = [m for m in mismatches if m['doh_pages'] > m['pc_pages']]
    expanded = [m for m in mismatches if m['doh_pages'] < m['pc_pages']]
    print(f"\n  Blocks TRUNCATED in PC (DOH has more pages): {len(truncated)}")
    for m in truncated:
        print(f"    [{m['idx']}] {m['path']}: PC={m['pc_pages']} pages, DOH={m['doh_pages']} pages (MISSING {m['doh_pages']-m['pc_pages']} pages = {(m['doh_pages']-m['pc_pages'])*0x8000:,} bytes)")
    print(f"  Blocks EXPANDED in PC (PC has more pages): {len(expanded)}")
    for m in expanded:
        print(f"    [{m['idx']}] {m['path']}: PC={m['pc_pages']} pages, DOH={m['doh_pages']} pages")
