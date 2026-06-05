#!/usr/bin/env python3
"""Dissect Mattias skinned meshes: list mesh-entry chunks + decl bounds/bytes
across base-game (Xbox + PC retail) and DLC, to see why the DLC decl truncates.
"""
import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from ucfx_be_to_le import _parse_entry_table_be, _convert_decl, UnhandledByteSwapError
from wad_patcher import parse_block_entries

MESH_B = 0x5B724250
HB = Path("output/human_blocks")


def block_entries(raw, be):
    if be:
        return [(h, t, o, s) for h, t, o, s in _parse_entry_table_be(raw)]
    return [(e["hash"], e["type_hash"], e["offset"], e["size"])
            for e in parse_block_entries(raw)]


def ucfx_chunks(buf, be):
    """Return (container_len, data_area_off, [(tag, body_start, body_size)])."""
    # Xbox mesh entries carry an 8-byte prefix before the UCFX magic; seek it.
    for m in (b"UCFX", b"XFCU"):
        i = buf.find(m)
        if i != -1:
            buf = buf[i:]
            break
    fmt = ">" if be else "<"
    if len(buf) < 20:
        return len(buf), 0, []
    dao = struct.unpack_from(fmt + "I", buf, 4)[0]
    n = struct.unpack_from(fmt + "I", buf, 16)[0]
    rows = []
    for k in range(min(n, 5000)):
        ro = 20 + k * 20
        if ro + 20 > len(buf):
            break
        traw = buf[ro:ro + 4]
        tag = (traw[::-1] if be else traw).decode("ascii", "replace")
        u0, sz = struct.unpack_from(fmt + "II", buf, ro + 4)
        bs = (dao + u0) if dao > 0 else (8 + u0)
        rows.append((tag, bs, sz))
    return len(buf), dao, rows


def analyze(label, path, be):
    if not path.exists():
        print(f"  [{label}] (no file)")
        return
    raw = path.read_bytes()
    ents = block_entries(raw, be)
    meshes = [(h, t, o, s) for h, t, o, s in ents if t == MESH_B]
    print(f"\n[{label}] {path.name}  block={len(raw)}B  entries={len(ents)} mesh={len(meshes)}")
    for (h, t, o, s) in meshes[:2]:
        container = raw[o:o + s]
        clen, dao, chunks = ucfx_chunks(container, be)
        decls = [(tag, bs, sz) for tag, bs, sz in chunks if tag == "decl"]
        strm = sum(1 for tag, _, _ in chunks if tag in ("STRM", "GEOM"))
        print(f"  mesh 0x{h:08X}: container={clen}B dao={dao} chunks={len(chunks)} "
              f"STRM/GEOM={strm} decls={len(decls)}")
        for i, (tag, bs, sz) in enumerate(decls[:3]):
            inb = (bs + sz) <= clen
            body = container[bs:min(bs + sz, clen)]
            note = "" if inb else f"  <<< OUT OF BOUNDS (need {bs+sz}, have {clen})"
            print(f"    decl[{i}]: start={bs} size={sz} in_bounds={inb}{note}")
            print(f"      bytes({len(body)}B): {body[:64].hex()}{'...' if len(body)>64 else ''}")
            if be and body:
                try:
                    conv = _convert_decl(body)
                    print(f"      _convert_decl -> {len(conv)}B OK")
                except UnhandledByteSwapError as e:
                    print(f"      _convert_decl -> RAISES: {str(e)[:70]}")


def main():
    for ver in ("v2", "v3", "v4"):
        analyze(f"BASE-XBOX mattias_{ver}",
                HB / "base_xbox" / f"blocks__vz__pmc_hum_mattias_{ver}_P000_Q3.block.bin", True)
        analyze(f"BASE-PC   mattias_{ver}",
                HB / "base_pc" / f"blocks__VZ__pmc_hum_mattias_{ver}_P000_Q3.block.bin", False)
    print("\n" + "=" * 70)
    analyze("DLC-XBOX  mattias_v5",
            HB / "dlc_xbox" / "blocks__dlc01__pmc_hum_mattias_v5_P000_Q3.block.bin", True)
    # also the sub-meshes that converted (ub/lb/head) to compare
    for part in ("ub", "lb", "head"):
        analyze(f"DLC-XBOX  mattias_v5_{part}",
                HB / "dlc_xbox" / f"blocks__dlc01__pmc_hum_mattias_v5_{part}_P000_Q3.block.bin", True)


if __name__ == "__main__":
    main()
