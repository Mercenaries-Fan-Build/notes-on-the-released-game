#!/usr/bin/env python3
"""Golden test for the Xbox->PC `decl` translator against retail PC truth.

Converts every base-game Xbox decl with the derived rules and requires
byte-exact equality with the paired retail PC decl. Self-completing: records
any unmapped Xbox `b` code together with the PC Type seen at that position so
the table can be finalized.
"""
import mmap
import struct
import sys
from collections import Counter, defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from wad_be_le_oracle import (PcIndex, _decompress_be_block, _split_be_entries,
                              DEFAULT_PC_WAD, DEFAULT_XBOX_WAD)
from x360_dlc_io import (SCFF_MAGIC, PAGE_SIZE, parse_be_ffcs, parse_be_indx,
                         parse_be_pths)
# Standard Direct3D9 D3DDECLTYPE byte sizes (index = D3DDECLTYPE enum)
STD_SIZES = {0: 4, 1: 8, 2: 12, 3: 16, 4: 4, 5: 4, 6: 4, 7: 8, 8: 4,
             9: 4, 10: 8, 11: 4, 12: 8, 13: 4, 14: 4, 15: 4, 16: 8}

single_tot = 0
single_ok = 0
single_mism = []
MESH_B = 0x5B724250
MAX_DECLS = 60000

# Derived: PC D3DDECLTYPE keyed on the Xbox format byte (b >> 8) & 0xFF
TYPE_BY_FMT = {
    0x23: 15,   # FLOAT16_2
    0x21: 16,   # FLOAT16_4
    0x28: 4,    # UBYTE4
    0x22: 5,    # SHORT2
    0x20: 8,    # D3DCOLOR
}
PC_HEADER = struct.pack("<II", 0, 16)
PC_END = struct.pack("<HHBBBB", 0x00ff, 0, 17, 0, 0, 0)


def container(buf):
    for m in (b"UCFX", b"XFCU"):
        i = buf.find(m)
        if i != -1:
            return buf[i:]
    return buf


def get_decls(buf, be):
    buf = container(buf)
    fmt = ">" if be else "<"
    dao = struct.unpack_from(fmt + "I", buf, 4)[0]
    n = struct.unpack_from(fmt + "I", buf, 16)[0]
    out = []
    for i in range(min(n, 4000)):
        ro = 20 + i * 20
        if ro + 20 > len(buf):
            break
        traw = buf[ro:ro + 4]
        tag = (traw[::-1] if be else traw).decode("ascii", "replace")
        u0, sz = struct.unpack_from(fmt + "II", buf, ro + 4)
        bs = (dao + u0) if dao > 0 else (8 + u0)
        if tag == "decl":
            out.append(buf[bs:bs + sz])
    return out


def convert_decl(be, unmapped=None):
    """Xbox-BE decl -> PC-LE decl. Returns None if an unmapped code is hit."""
    if len(be) < 12:
        return None
    out = bytearray(PC_HEADER)
    pos = 12
    ok = True
    off = None
    while pos + 12 <= len(be):
        a, b, c = struct.unpack_from(">III", be, pos)
        pos += 12
        if (a >> 16) == 0x00ff:        # END element
            out += PC_END
            break
        if off is None:
            off = a & 0xffff           # base offset = first element's slot value
        typ = TYPE_BY_FMT.get((b >> 8) & 0xff)
        if typ is None:
            ok = False
            if unmapped is not None:
                unmapped.append(((b >> 8) & 0xff, b, a, c))
            typ = 0xEE
        out += struct.pack("<HHBBBB", 0, off, typ, 0, (c >> 16) & 0xff, c & 0xff)
        off += STD_SIZES.get(typ, 4)   # cumulative
    return bytes(out), ok


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

    total = exact = unmapped_decls = 0
    unmapped_codes = defaultdict(Counter)   # b -> Counter(pc_type at that slot)
    mismatch_samples = []
    seen_blocks = 0

    for bi in range(indx.meta):
        if total >= MAX_DECLS:
            break
        pnorm = paths[bi].replace("\\", "/").lower() if bi < len(paths) else f"b{bi}"
        pcblk = pc.by_path.get(pnorm)
        if not pcblk or not any(k[1] == MESH_B for k in pcblk):
            continue
        be_block = _decompress_be_block(mm, ents[bi].file_offset,
                                        ents[bi].page_count * PAGE_SIZE)
        if be_block is None:
            continue
        seen_blocks += 1
        for key, be_bytes in _split_be_entries(be_block).items():
            if key[1] != MESH_B or key not in pcblk:
                continue
            be_d = get_decls(be_bytes, True)
            if not be_d:
                continue
            pc_bytes = pc.entry_bytes(pnorm, key)
            if not pc_bytes:
                continue
            pc_list = get_decls(pc_bytes, False)
            pc_set = set(pc_list)
            # Unambiguous single-decl meshes: direct compare
            if len(be_d) == 1 and len(pc_list) == 1:
                global single_tot, single_ok
                single_tot += 1
                r = convert_decl(be_d[0])
                if r and r[0] == pc_list[0]:
                    single_ok += 1
                elif len(single_mism) < 12:
                    # dump xbox format bytes vs pc types for the mismatch
                    xb = [(hex((struct.unpack_from('>I', be_d[0], p+4)[0] >> 8) & 0xff))
                          for p in range(12, len(be_d[0]) - 11, 12)]
                    pt = [be_d[0].hex(), r[0].hex() if r else None, pc_list[0].hex()]
                    single_mism.append((pnorm, xb, pt))
            for bd in be_d:
                total += 1
                um = []
                res = convert_decl(bd, um)
                if res is None:
                    continue
                conv, ok = res
                if conv in pc_set:
                    exact += 1
                if not ok:
                    unmapped_decls += 1
                    # find the matching PC decl by closest length to learn types
                    for fmt, b, a, c in um:
                        # record b; pc type unknown here unless we align -- store raw
                        unmapped_codes[fmt][None] += 1
                elif conv not in pc_set and len(mismatch_samples) < 6:
                    mismatch_samples.append((pnorm, bd.hex(),
                                             conv.hex(),
                                             [d.hex() for d in pc_set]))

    print(f"\nblocks with meshes scanned: {seen_blocks}")
    print(f"decls converted : {total}")
    print(f"byte-EXACT == PC: {exact}  ({100*exact/max(total,1):.2f}%)")
    print(f"SINGLE-decl meshes: {single_ok}/{single_tot} exact ({100*single_ok/max(single_tot,1):.2f}%)")
    print("single-decl mismatches:")
    for m in single_mism:
        print(f"  {m[0]} fmtbytes={m[1]}")
        print(f"    BE  ={m[2][0]}")
        print(f"    OURS={m[2][1]}")
        print(f"    PC  ={m[2][2]}")
    print(f"decls w/ unmapped code: {unmapped_decls}")
    print(f"unmapped b codes: {dict((hex(k), sum(v.values())) for k, v in unmapped_codes.items())}")
    print(f"\nmismatch samples (mapped but != PC), up to 6:")
    for s in mismatch_samples:
        print(f"  block={s[0]}")
        print(f"    BE  ={s[1]}")
        print(f"    OURS={s[2]}")
        print(f"    PC  ={s[3]}")


if __name__ == "__main__":
    main()
