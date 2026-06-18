#!/usr/bin/env python3
"""Offline scanner for the inflated-PRMG-element-count world-load crash (0x47A7C6 /
0x47AA5C). The engine (FUN_00478120) sets a renderable's element count from the FIRST
u32 of the top-level INFO chunk, then fills one 0x1C4 record per sibling PRMG chunk.
When INFO[0] > (#PRMG siblings), the trailing record(s) are never filled -> raw heap
garbage -> the per-frame render walk derefs a wild record+4 / null binding array.

This walks every decompressed UCFX container in a WAD and, for each container level
that holds a direct INFO child alongside direct PRMG children, compares INFO[0] to the
PRMG count. Mismatches are the candidate crash assets.

Usage:
  python tools/prmg_count_scan.py <wad> [<wad2> ...]
"""
from __future__ import annotations

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
HDR = M.CHUNK_HDR  # 20


def direct_children(rows):
    """Yield (idx, tag, u, child_slice|None) for each DIRECT child of a flat
    preorder row list. A container row at i owns the next u[3] rows (all
    descendants); its direct-child slice is rows[i+1:i+1+u[3]]."""
    i = 0
    while i < len(rows):
        tag, u = rows[i]
        if u[0] == SENT:
            n = int(u[3])
            if n < 0 or i + 1 + n > len(rows):
                n = 0
            yield i, tag, u, rows[i + 1 : i + 1 + n]
            i += 1 + n
        else:
            yield i, tag, u, None
            i += 1


def info_first_u32(data: bytes, data_base: int, u) -> int | None:
    """Read the first u32 of an INFO leaf body (LE, already converted)."""
    off = data_base + int(u[0])
    if off < 0 or off + 4 > len(data):
        return None
    return struct.unpack_from("<I", data, off)[0]


def engine_walk(rows):
    """Replicate FUN_00478120's GATED sibling walk over a container's child rows.
    Advance to next sibling = i + u3 + 1, but ONLY if the current row's u2
    ([desc+0xc]) is non-zero; u2==0 stops the walk (last-sibling / continuation
    flag). Returns the list of (idx,tag,u) rows the engine actually VISITS."""
    visited = []
    i = 0
    while 0 <= i < len(rows):
        tag, u = rows[i]
        visited.append((i, tag, u))
        if int(u[2]) == 0:          # [desc+0xc] == 0  -> stop (engine: iVar5=-1)
            break
        i = i + int(u[3]) + 1       # [desc+0x10] + 1 + i
    return visited


def scan_rows(rows, data, data_base, path, container_tag, findings):
    """At this container level compare INFO[0] to (a) the FULL PRMG count and
    (b) the count the ENGINE would actually build given the u2-gated walk.
    Flag any case where the engine builds fewer records than INFO[0] claims."""
    children = list(direct_children(rows))

    # full (ungated) view
    info_u = None
    full_prmg = 0
    for _i, tag, u, _sub in children:
        if tag == b"INFO" and u[0] != SENT and info_u is None:
            info_u = u
        elif tag == b"PRMG" and u[0] == SENT:
            full_prmg += 1

    if full_prmg > 0 and info_u is not None:
        claimed = info_first_u32(data, data_base, info_u)
        # engine-gated view: how many PRMG does the gated walk reach?
        eng = engine_walk(rows)
        eng_prmg = sum(1 for _i, tag, u in eng if tag == b"PRMG" and u[0] == SENT)
        eng_stopped_early = len(eng) < len(children)
        if claimed is not None and (claimed != full_prmg or claimed != eng_prmg):
            findings.append({
                "path": path,
                "container": container_tag.decode("latin1", "replace"),
                "claimed_info0": claimed,
                "full_prmg": full_prmg,
                "eng_prmg": eng_prmg,
                "n_children": len(children),
                "eng_visited": len(eng),
                "stopped_early": eng_stopped_early,
                # u2/u3 of each direct child for forensic diff
                "child_u2u3": [(tag.decode("latin1", "replace"), int(u[2]), int(u[3]))
                               for _i, tag, u, _s in children],
            })
    # recurse
    for _i, tag, u, sub in children:
        if sub is not None:
            scan_rows(sub, data, data_base, path, tag, findings)


def scan_container(cont, data, path, findings):
    # top-level rows live under the implicit UCFX root
    scan_rows(cont["chunks"], data, cont["data_base"], path, b"UCFX", findings)


def scan_wad(wad_path: Path):
    findings = []
    n_assets = 0
    n_mesh = 0
    with open(wad_path, "rb") as fh:
        import mmap
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
                n_assets += 1
                label = f"{pnorm}::0x{ent['hash']:08X}/0x{ent['type_hash']:08X}"
                for cont in M.iter_ucfx_containers(ucfx):
                    # only mesh-ish containers carry PRMG; cheap pre-check
                    if b"PRMG" not in ucfx:
                        break
                    n_mesh += 1
                    scan_container(cont, ucfx, label, findings)
        mm.close()
    return findings, n_assets, n_mesh


def main():
    wads = [Path(a) for a in sys.argv[1:]] or [Path("output/data/vz-patch.wad")]
    for wad in wads:
        print(f"\n========== {wad} ==========")
        if not wad.exists():
            print("  (missing)")
            continue
        findings, n_assets, n_mesh = scan_wad(wad)
        print(f"  assets={n_assets:,}  containers-with-PRMG-scanned={n_mesh:,}  "
              f"mismatches={len(findings)}")
        # group identical (container, claimed, count) for readability
        for f in findings[:60]:
            flag = " <<< ENGINE STOPS EARLY" if f["stopped_early"] else ""
            print(f"    [{f['container']}] INFO[0]={f['claimed_info0']:<4} "
                  f"full_prmg={f['full_prmg']:<3} eng_prmg={f['eng_prmg']:<3} "
                  f"children={f['n_children']} eng_visited={f['eng_visited']}{flag}")
            print(f"        {f['path']}")
            print(f"        u2/u3: {f['child_u2u3']}")
        if len(findings) > 60:
            print(f"    ... +{len(findings) - 60} more")


if __name__ == "__main__":
    main()
