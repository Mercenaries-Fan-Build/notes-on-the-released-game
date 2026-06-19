#!/usr/bin/env python3
"""Check the engine's per-PRMG stream-size invariants (FUN_00478270):
  PRMT body  == (INFO[0] + INFO[4]) * 16     (the two <<4 reads at 0x478xxx)
  BSHI body  ==  INFO[8] * 2                  (the *2 read at 0x47830x)
where INFO is the PRMG's own 0x3c header (first three u32: A=INFO[0], B=INFO[4],
C=INFO[8]). When the converter re-encodes PRMT (IBUF strip->list) or mis-sizes BSHI
without updating these INFO counts, the engine's sequential reads desync and
FUN_00478270 BAILS on that PRMG -> the renderable's element is left under-filled ->
the world-load render crash (0x47A7C6 / 0x47AA5C).

Retail vz.wad must satisfy the invariant universally (sanity). Any violation that is
PRESENT in our converted WAD but ABSENT in retail is the crash asset.

Usage: python tools/prmg_invariant_scan.py <wad> [<wad2> ...]
"""
from __future__ import annotations

import mmap
import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from sges_decompress import decompress_sges_block  # noqa: E402
from wad_patcher import (  # noqa: E402
    find_data_chunk,
    get_block_boundaries,
    load_wad_paths,
    parse_block_entries,
)
import ucfx_mesh_codec as M  # noqa: E402

SENT = M.CONTAINER_SENTINEL


def iter_prmg_bodies(chunks):
    """Yield each PRMG container's direct-child row list (GEOM->[MESH]->PRMG)."""
    def walk(rows, depth=0):
        i = 0
        while i < len(rows):
            tag, u = rows[i]
            if u[0] == SENT:
                n = int(u[3])
                if n < 0 or i + 1 + n > len(rows):
                    n = 0
                sub = rows[i + 1 : i + 1 + n]
                if tag == b"PRMG":
                    yield sub
                else:
                    yield from walk(sub, depth + 1)
                i += 1 + n
            else:
                i += 1
    yield from walk(chunks)


def prmg_subchunk_sizes(prmg_rows):
    """Return (info0_3u32 | None, prmt_len | None, bshi_len | None) for a PRMG."""
    info = None
    prmt_len = None
    bshi_len = None
    for bt, bu in prmg_rows:
        if bt == b"INFO" and bu[0] != SENT and info is None:
            info = (int(bu[0]), int(bu[1]))   # (off_rel, len)
        elif bt == b"PRMT" and bu[0] != SENT and prmt_len is None:
            prmt_len = int(bu[1])
        elif bt == b"BSHI" and bu[0] != SENT and bshi_len is None:
            bshi_len = int(bu[1])
    return info, prmt_len, bshi_len


def check_container(ucfx, path, viol):
    for cont in M.iter_ucfx_containers(ucfx):
        data_base = cont["data_base"]
        for pidx, prmg in enumerate(iter_prmg_bodies(cont["chunks"])):
            info, prmt_len, bshi_len = prmg_subchunk_sizes(prmg)
            if info is None or info[1] < 12:
                continue
            ip = data_base + info[0]
            if ip < 0 or ip + 12 > len(ucfx):
                continue
            A, B, C = struct.unpack_from("<III", ucfx, ip)
            # sanity: huge counts mean we mis-parsed; skip
            if A > 1_000_000 or B > 1_000_000 or C > 1_000_000:
                continue
            if prmt_len is not None:
                exp = (A + B) * 20      # PRMT on-disk stride is 20B/record (engine reads 16)
                if prmt_len != exp:
                    viol.append((path, pidx, "PRMT", prmt_len, exp, A, B, C))
            if bshi_len is not None:
                exp = C * 2
                if bshi_len != exp:
                    viol.append((path, pidx, "BSHI", bshi_len, exp, A, B, C))


def scan_wad(wad_path: Path):
    viol = []
    n_prmg = 0
    with open(wad_path, "rb") as fh:
        mm = mmap.mmap(fh.fileno(), 0, access=mmap.ACCESS_READ)
        dc = find_data_chunk(wad_path)
        boundaries = get_block_boundaries(mm, dc.offset, dc.size)
        paths = load_wad_paths(wad_path)
        for blk_idx, (s, e) in enumerate(boundaries):
            pnorm = paths[blk_idx] if blk_idx < len(paths) else f"block_{blk_idx:05d}"
            try:
                bdata = decompress_sges_block(mm, s, e)
                entries = parse_block_entries(bdata)
            except Exception:
                continue
            for ent in entries:
                eoff, esize = ent["offset"], ent["size"]
                if eoff + esize > len(bdata):
                    continue
                ucfx = bdata[eoff:eoff + esize]
                if b"PRMG" not in ucfx:
                    continue
                label = f"{pnorm}::0x{ent['hash']:08X}/0x{ent['type_hash']:08X}"
                before = len(viol)
                check_container(ucfx, label, viol)
                for cont in M.iter_ucfx_containers(ucfx):
                    n_prmg += sum(1 for _ in iter_prmg_bodies(cont["chunks"]))
        mm.close()
    return viol, n_prmg


def main():
    wads = [Path(a) for a in sys.argv[1:]] or [Path("output/data/vz-patch.wad")]
    for wad in wads:
        print(f"\n========== {wad} ==========")
        if not wad.exists():
            print("  (missing)")
            continue
        viol, n_prmg = scan_wad(wad)
        print(f"  PRMGs scanned={n_prmg:,}  invariant violations={len(viol)}")
        for v in viol[:80]:
            path, pidx, kind, got, exp, A, B, C = v
            print(f"    {kind} len={got} != expected={exp}  (INFO A={A} B={B} C={C})  "
                  f"prmg#{pidx}  {path}")
        if len(viol) > 80:
            print(f"    ... +{len(viol) - 80} more")


if __name__ == "__main__":
    main()
