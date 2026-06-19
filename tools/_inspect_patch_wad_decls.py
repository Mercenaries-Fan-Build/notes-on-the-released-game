#!/usr/bin/env python3
"""Inspect `decl` chunks in a deployed (PC-LE) patch WAD: classify each as a
valid PC D3DVERTEXELEMENT9 array (my translator) vs garbage (stale/old swap).
"""
import struct
import sys
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from wad_be_le_oracle import PcIndex

MESH_B = 0x5B724250
WAD = Path(sys.argv[1] if len(sys.argv) > 1
           else r"C:\Users\Shadow\Desktop\Mercenaries 2 World in Flames\data\vz-patch.wad")


def get_decls_le(buf):
    i = buf.find(b"UCFX")
    if i == -1:
        i = buf.find(b"XFCU")
    if i == -1:
        return []
    buf = buf[i:]
    if len(buf) < 20:
        return []
    dao = struct.unpack_from("<I", buf, 4)[0]
    n = struct.unpack_from("<I", buf, 16)[0]
    out = []
    for k in range(min(n, 4000)):
        ro = 20 + k * 20
        if ro + 20 > len(buf):
            break
        tag = buf[ro:ro + 4].decode("ascii", "replace")
        u0, sz = struct.unpack_from("<II", buf, ro + 4)
        bs = (dao + u0) if dao > 0 else (8 + u0)
        if tag == "decl" and bs + sz <= len(buf):
            out.append(buf[bs:bs + sz])
    return out


def classify(d):
    """Return ('ok'|'bad', detail). PC decl = [0,16] hdr + HHBBBB elems, END Type17."""
    if len(d) < 16:
        return "bad", f"len={len(d)}"
    hdr0, hdr1 = struct.unpack_from("<II", d, 0)
    pos = 8
    types = []
    while pos + 8 <= len(d):
        s, o, t, _m, _u, _ui = struct.unpack_from("<HHBBBB", d, pos)
        if (s & 0xFFFF) == 0xFFFF or (s & 0xFF) == 0xFF:
            return "ok", (hdr0, hdr1, types)
        if t > 17:
            return "bad", f"invalid Type=0x{t:02x} @+{pos} hdr=({hdr0},{hdr1})"
        types.append(t)
        pos += 8
    return "bad", f"no END (hdr={hdr0},{hdr1}, {len(types)} elems)"


def main():
    print(f"WAD: {WAD}  ({WAD.stat().st_size:,} bytes)", file=sys.stderr)
    pc = PcIndex(WAD)
    pc.build()
    ok = bad = 0
    bad_samples = []
    ok_hdr = Counter()
    for pnorm, blk in pc.by_path.items():
        for key in blk:
            if key[1] != MESH_B:
                continue
            entry = pc.entry_bytes(pnorm, key)
            if not entry:
                continue
            for d in get_decls_le(entry):
                verdict, detail = classify(d)
                if verdict == "ok":
                    ok += 1
                    ok_hdr[detail[1]] += 1  # hdr1 (stride-gate)
                else:
                    bad += 1
                    if len(bad_samples) < 6:
                        bad_samples.append((pnorm, detail, d[:48].hex()))
    print(f"\nmesh decls inspected: {ok+bad}")
    print(f"  valid PC D3DVERTEXELEMENT9 : {ok}")
    print(f"  INVALID (garbage/old swap) : {bad}")
    print(f"  valid-decl header word[1] distribution: {dict(ok_hdr.most_common(5))}")
    print("\ninvalid samples:")
    for s in bad_samples:
        print(f"  {s[0]}  {s[1]}\n    bytes={s[2]}")


if __name__ == "__main__":
    main()
