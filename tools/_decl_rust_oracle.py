#!/usr/bin/env python3
"""End-to-end test of the RUST decl translator: convert base-game mesh blocks
with the actual ucfx_byteswap binary, extract the `decl` from its LE output, and
compare byte-for-byte against the retail PC decl.
"""
import mmap
import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from wad_be_le_oracle import (PcIndex, _decompress_be_block, _split_le_entries,
                              DEFAULT_PC_WAD, DEFAULT_XBOX_WAD)
from x360_dlc_io import (SCFF_MAGIC, PAGE_SIZE, parse_be_ffcs, parse_be_indx,
                         parse_be_pths)
from ucfx_byteswap_wrapper import byteswap_block_rust

MESH_B = 0x5B724250
MAX_MESHES = 2000


def get_decls_le(buf):
    for m in (b"UCFX", b"XFCU"):
        i = buf.find(m)
        if i != -1:
            buf = buf[i:]
            break
    dao = struct.unpack_from("<I", buf, 4)[0]
    n = struct.unpack_from("<I", buf, 16)[0]
    out = []
    for i in range(min(n, 4000)):
        ro = 20 + i * 20
        if ro + 20 > len(buf):
            break
        tag = buf[ro:ro + 4].decode("ascii", "replace")
        u0, sz = struct.unpack_from("<II", buf, ro + 4)
        bs = (dao + u0) if dao > 0 else (8 + u0)
        if tag == "decl":
            out.append(buf[bs:bs + sz])
    return out


def main():
    pc = PcIndex(DEFAULT_PC_WAD)
    print("indexing PC ...", file=sys.stderr)
    pc.build()
    xfh = open(DEFAULT_XBOX_WAD, "rb")
    mm = mmap.mmap(xfh.fileno(), 0, access=mmap.ACCESS_READ)
    assert mm[:4] == SCFF_MAGIC
    _v, rows = parse_be_ffcs(mm)
    indx = next(r for r in rows if r.tag == "INDX")
    pths = next((r for r in rows if r.tag == "PTHS"), None)
    ents = parse_be_indx(mm, indx.offset, indx.meta)
    paths = parse_be_pths(mm, pths.offset, pths.meta) if pths else []

    total = single_tot = single_ok = errors = 0
    mism = []
    for bi in range(indx.meta):
        if single_tot >= MAX_MESHES:
            break
        pnorm = paths[bi].replace("\\", "/").lower() if bi < len(paths) else f"b{bi}"
        pcblk = pc.by_path.get(pnorm)
        if not pcblk or not any(k[1] == MESH_B for k in pcblk):
            continue
        be_block = _decompress_be_block(mm, ents[bi].file_offset,
                                        ents[bi].page_count * PAGE_SIZE)
        if be_block is None:
            continue
        try:
            le_block = byteswap_block_rust(be_block, validate=False)
        except Exception as e:
            errors += 1
            if len(mism) < 4:
                mism.append((pnorm, f"rust convert error: {e}"))
            continue
        rust_entries = _split_le_entries(le_block)
        for key, le_bytes in rust_entries.items():
            if key[1] != MESH_B or key not in pcblk:
                continue
            rd = get_decls_le(le_bytes)
            if not rd:
                continue
            pc_bytes = pc.entry_bytes(pnorm, key)
            if not pc_bytes:
                continue
            pd = get_decls_le(pc_bytes)
            total += 1
            if len(rd) == 1 and len(pd) == 1:
                single_tot += 1
                if rd[0] == pd[0]:
                    single_ok += 1
                elif len(mism) < 4:
                    mism.append((pnorm, f"RUST={rd[0].hex()}", f"PC  ={pd[0].hex()}"))

    print(f"\nmesh entries with decls compared: {total}")
    print(f"single-decl meshes: {single_ok}/{single_tot} byte-EXACT via RUST "
          f"({100*single_ok/max(single_tot,1):.2f}%)")
    print(f"rust convert errors: {errors}")
    for m in mism:
        print("  ", m)


if __name__ == "__main__":
    main()
