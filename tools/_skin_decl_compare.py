#!/usr/bin/env python3
"""Compare base-game SKINNED mesh decls (Xbox source vs retail PC) to understand
the skinned vertex-declaration format and why _convert_decl emits header-only.

A mesh is "skinned" if its PC decl has a BLENDWEIGHT (Usage 1) or BLENDINDICES
(Usage 2) element.
"""
import mmap
import struct
import sys
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from wad_be_le_oracle import (PcIndex, _decompress_be_block, _split_be_entries,
                              DEFAULT_PC_WAD, DEFAULT_XBOX_WAD)
from x360_dlc_io import (SCFF_MAGIC, PAGE_SIZE, parse_be_ffcs, parse_be_indx,
                         parse_be_pths)
from ucfx_be_to_le import _convert_decl, UnhandledByteSwapError

MESH_B = 0x5B724250


def get_decls(buf, be):
    for m in (b"UCFX", b"XFCU"):
        i = buf.find(m)
        if i != -1:
            buf = buf[i:]
            break
    if len(buf) < 20:
        return []
    fmt = ">" if be else "<"
    dao = struct.unpack_from(fmt + "I", buf, 4)[0]
    n = struct.unpack_from(fmt + "I", buf, 16)[0]
    out = []
    for k in range(min(n, 4000)):
        ro = 20 + k * 20
        if ro + 20 > len(buf):
            break
        traw = buf[ro:ro + 4]
        tag = (traw[::-1] if be else traw).decode("ascii", "replace")
        u0, sz = struct.unpack_from(fmt + "II", buf, ro + 4)
        bs = (dao + u0) if dao > 0 else (8 + u0)
        if tag == "decl" and bs + sz <= len(buf):
            out.append(buf[bs:bs + sz])
    return out


def pc_elems(d):
    els = []
    pos = 8
    while pos + 8 <= len(d):
        s, o, t, m, u, ui = struct.unpack_from("<HHBBBB", d, pos)
        if (s & 0xff) == 0xff:
            break
        els.append((s, o, t, u, ui))
        pos += 8
    return els


def is_skinned(d):
    return any(u in (1, 2) for (_s, _o, _t, u, _ui) in pc_elems(d))


def xbox_fmt_bytes(d):
    out = []
    pos = 12
    while pos + 12 <= len(d):
        a = struct.unpack_from(">I", d, pos)[0]
        b = struct.unpack_from(">I", d, pos + 4)[0]
        if (a >> 16) == 0x00ff:
            break
        out.append((((b >> 8) & 0xff), b & 0xff))
        pos += 12
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

    skinned = 0
    shown = 0
    fmt_to_type = {}          # (fmtbyte) -> Counter(pc_type) for skinned-only elements
    xbox_len_dist = Counter()
    my_match = Counter()
    for bi in range(indx.meta):
        if shown >= 6 and skinned >= 300:
            break
        pnorm = paths[bi].replace("\\", "/").lower() if bi < len(paths) else f"b{bi}"
        pcblk = pc.by_path.get(pnorm)
        if not pcblk or not any(k[1] == MESH_B for k in pcblk):
            continue
        be_block = _decompress_be_block(mm, ents[bi].file_offset,
                                        ents[bi].page_count * PAGE_SIZE)
        if be_block is None:
            continue
        for key, be_bytes in _split_be_entries(be_block).items():
            if key[1] != MESH_B or key not in pcblk:
                continue
            pc_bytes = pc.entry_bytes(pnorm, key)
            if not pc_bytes:
                continue
            be_decls = get_decls(be_bytes, True)
            pc_decls = get_decls(pc_bytes, False)
            for i, pcd in enumerate(pc_decls):
                if not is_skinned(pcd):
                    continue
                skinned += 1
                bed = be_decls[i] if i < len(be_decls) else b""
                xbox_len_dist[len(bed)] += 1
                # record fmt-byte -> pc type for skinned elements
                pes = pc_elems(pcd)
                xfb = xbox_fmt_bytes(bed)
                for j, (s, o, t, u, ui) in enumerate(pes):
                    if j < len(xfb):
                        fmt_to_type.setdefault(xfb[j], Counter())[t] += 1
                try:
                    mine = _convert_decl(bed) if bed else b""
                    my_match[mine == pcd] += 1
                except UnhandledByteSwapError:
                    my_match["raise"] += 1
                    mine = b"<raised>"
                if shown < 6 and "skel" not in pnorm:
                    shown += 1
                    print("=" * 78)
                    print(f"{pnorm}  asset=0x{key[0]:08X}  skinned decl[{i}]")
                    print(f"  XBOX ({len(bed)}B): {bed.hex()}")
                    print(f"  MINE ({len(mine) if isinstance(mine,(bytes,bytearray)) else 0}B): "
                          f"{mine.hex() if isinstance(mine,(bytes,bytearray)) else mine}")
                    print(f"  PC   ({len(pcd)}B): {pcd.hex()}")
                    print(f"  PC elements (Stream,Off,Type,Use,Idx): {pes}")
                    print(f"  Xbox fmt bytes ((b>>8)&ff, b&ff): {xfb}")

    print("\n" + "=" * 78)
    print(f"skinned base-game decls: {skinned}")
    print(f"my _convert_decl vs PC on skinned: {dict(my_match)}")
    print(f"xbox skinned decl length distribution: {dict(xbox_len_dist.most_common(8))}")
    print("skinned element fmt-byte -> PC type (>1 = needs finer key):")
    for fb in sorted(fmt_to_type):
        print(f"   fmt(b>>8)=0x{fb[0]:02x} b&ff=0x{fb[1]:02x} -> {dict(fmt_to_type[fb])}")


if __name__ == "__main__":
    main()
