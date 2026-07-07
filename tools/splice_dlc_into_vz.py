#!/usr/bin/env python3
"""Splice DLC blocks from a patch WAD INTO base vz.wad as native base-WAD blocks.

Rationale: on-demand (gameplay) streaming of patch-WAD blocks wedges/crashes,
while base-vz.wad blocks stream fine. So move the DLC blocks into vz.wad itself.

How it stays cheap + safe on a 2.5 GB file:
  - vz.wad layout is  header | INDX | ASET | PTHS | <slack> | DATA(@0x208000) | ...
  - There is ~1.47 MB of slack between PTHS and DATA, so INDX/ASET/PTHS can GROW
    without moving DATA. Existing block page-indices stay valid.
  - New blocks are APPENDED at the end of the file (new page indices).
  - Only the index region [0 .. 0x208000) + the appended tail are written.
  - The index region is backed up first → fully reversible (restore + truncate).

Usage:
  python tools/splice_dlc_into_vz.py --vz <vz.wad> --patch <vz-patch.wad> \
      --keep mattias_v5 --replace scripts_vz [--backup-only] [--dry-run]
"""
from __future__ import annotations
import argparse, struct, sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from sges_decompress import decompress_sges_block          # noqa: E402
from sges_compress import compress_sges                      # noqa: E402

PAGE = 0x8000
DATA_START = 0x208000  # asserted below


def read_header(buf: bytes):
    assert buf[:4] == b"FFCS", buf[:4]
    rows = {}
    for i in range(5):
        o = 0x0C + i * 12
        tag = buf[o:o + 4].decode("latin1")
        off, meta = struct.unpack_from("<II", buf, o + 4)
        rows[tag] = [o, off, meta]   # [hdr_off, value/offset, meta]
    return rows


def parse_indx(buf, off, n):
    return [list(struct.unpack_from("<III", buf, off + i * 12)) for i in range(n)]  # [page,packed,flags_pages]


def parse_aset(buf, off, n):
    rows = []
    for i in range(n):
        a, b, c, d = struct.unpack_from("<IIII", buf, off + i * 16)
        rows.append([a, b, c, d])  # hash, secondary, packed_block_ref, type_id
    return rows


def parse_pths(buf, off, n):
    out, pos = [], off
    while len(out) < n:
        nul = buf.find(b"\x00", pos)
        if nul < 0:
            break
        out.append(buf[pos:nul].decode("utf-8", "replace"))
        pos = nul + 1
    return out, pos  # paths, end-of-paths offset (before trailer)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--vz", type=Path, required=True)
    ap.add_argument("--patch", type=Path, required=True)
    ap.add_argument("--keep", action="append", default=[], help="path substr of NEW blocks to add from patch")
    ap.add_argument("--replace", action="append", default=[], help="path substr of EXISTING vz blocks to replace from patch")
    ap.add_argument("--tex-from-base", type=int, default=None,
                    help="EXPERIMENT: substitute texture blocks' DATA with this vz.wad block's decompressed data (keep v5 hash/path)")
    ap.add_argument("--atlas", type=Path, default=None,
                    help="Pack texture blocks into ONE atlas block (this decompressed multi-entry block); register all texture hashes -> the atlas (resident-atlas layout)")
    ap.add_argument("--atlas-path", default="blocks\\dlc01\\mattias_v5_atlas_P000_Q3.block")
    ap.add_argument("--model-from", type=Path, default=None,
                    help="substitute the MODEL block's decompressed data with this file")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    vz = args.vz
    fsize = vz.stat().st_size
    with open(vz, "rb") as f:
        idx_region = bytearray(f.read(DATA_START))   # header + INDX/ASET/PTHS + slack
    rows = read_header(idx_region)
    assert rows["DATA"][1] == DATA_START, f"DATA not at 0x{DATA_START:X}: 0x{rows['DATA'][1]:X}"
    indx_off, n_blk = rows["INDX"][1], rows["INDX"][2]
    aset_off, n_aset = rows["ASET"][1], rows["ASET"][2]
    pths_off, n_pths = rows["PTHS"][1], rows["PTHS"][2]
    indx = parse_indx(idx_region, indx_off, n_blk)
    aset = parse_aset(idx_region, aset_off, n_aset)
    pths, pths_end = parse_pths(idx_region, pths_off, n_pths)
    pths_trailer = bytes(idx_region[pths_end:pths_end + 259])  # 258-byte trailer + nul (kept verbatim)
    print(f"vz.wad: {n_blk} blocks, {n_aset} aset, {n_pths} paths; DATA@0x{DATA_START:X}; file 0x{fsize:X}")

    # ---- read patch WAD: blocks (decompressed) + aset grouped by block + paths ----
    praw = args.patch.read_bytes()
    prows = read_header(praw)
    p_indx = parse_indx(praw, prows["INDX"][1], prows["INDX"][2])
    p_aset = parse_aset(praw, prows["ASET"][1], prows["ASET"][2])
    p_pths, _ = parse_pths(praw, prows["PTHS"][1], prows["PTHS"][2])
    p_aset_by_blk = {}
    for a in p_aset:
        bi = (a[2] >> 16) & 0xFFFF
        p_aset_by_blk.setdefault(bi, []).append(a)

    def patch_block_decompressed(bi):
        page, packed, fp = p_indx[bi]
        s = page * PAGE
        e = s + (fp & 0xFFFF) * PAGE
        return bytes(decompress_sges_block(praw, s, e))

    # name->vz block index for --replace
    vz_path_idx = {p.lower(): i for i, p in enumerate(pths)}

    # EXPERIMENT: decompress a base vz.wad block to substitute texture data
    base_tex_dec = None
    if args.tex_from_base is not None:
        bp, bpk, bfp = indx[args.tex_from_base]
        bs = bp * PAGE
        be = bs + (bfp & 0xFFFF) * PAGE
        with open(vz, "rb") as bf:
            bf.seek(bs)
            braw = bf.read(be - bs)
        base_tex_dec = bytes(decompress_sges_block(braw, 0, len(braw)))
        print(f"tex-from-base: vz block {args.tex_from_base} -> {len(base_tex_dec)} dec bytes (substitute for texture data)")

    def is_texture_path(path):
        # v5 model is '...v5_P000...'; textures are '...v5_<part>_P000...'
        return "v5_p000" not in path.lower()

    # ---- plan appended blocks ----
    append_blocks = []   # list of (decompressed_bytes, packed_field, flags, path_or_None, aset_rows_or_None, replace_vz_idx_or_None)
    atlas_aset = []      # texture aset rows collected for the atlas block
    for bi, path in enumerate(p_pths):
        pl = path.lower()
        if any(k.lower() in pl for k in args.replace):
            # replace an existing vz block (e.g. scripts_vz)
            vzi = next((i for n, i in vz_path_idx.items() if any(k.lower() in n for k in args.replace)), None)
            if vzi is None:
                sys.exit(f"--replace target '{path}' not found in vz PTHS")
            dec = patch_block_decompressed(bi)
            append_blocks.append((dec, p_indx[bi][1], (p_indx[bi][2] >> 16) & 0xFFFF, None, None, vzi))
        elif any(k.lower() in pl for k in args.keep):
            if args.atlas is not None and is_texture_path(path):
                atlas_aset.extend(p_aset_by_blk.get(bi, []))  # collect; texture goes into the atlas
                continue
            dec = patch_block_decompressed(bi)
            if args.model_from is not None and not is_texture_path(path):
                dec = args.model_from.read_bytes()  # repointed model
            if base_tex_dec is not None and is_texture_path(path):
                dec = base_tex_dec  # EXPERIMENT: known-good base texture data under the v5 hash
            append_blocks.append((dec, p_indx[bi][1], (p_indx[bi][2] >> 16) & 0xFFFF, path, p_aset_by_blk.get(bi, []), None))
    if args.atlas is not None:
        atlas_dec = args.atlas.read_bytes()
        append_blocks.append((atlas_dec, 0, 0x80, args.atlas_path, atlas_aset, None))
        print(f"atlas: {len(atlas_dec)} dec bytes carrying {len(atlas_aset)} texture aset entries")

    print(f"plan: {sum(1 for b in append_blocks if b[5] is None)} NEW blocks, "
          f"{sum(1 for b in append_blocks if b[5] is not None)} REPLACE blocks")
    for dec, packed, flags, path, arows, vzi in append_blocks:
        tag = f"REPLACE vz[{vzi}]" if vzi is not None else f"NEW (+{len(arows)} aset)"
        print(f"   {tag:18} {(path or pths[vzi]).split(chr(92))[-1]}  ({len(dec)} dec bytes)")

    # ---- compress + lay out appended blocks at end of file ----
    cur_page = fsize // PAGE
    if fsize % PAGE != 0:
        cur_page += 1
    tail = bytearray()
    tail_base = cur_page * PAGE - fsize   # padding to page-align the first appended block
    tail.extend(b"\x00" * tail_base)
    for k, (dec, packed, flags, path, arows, vzi) in enumerate(append_blocks):
        comp = compress_sges(dec)
        pages = (len(comp) + PAGE - 1) // PAGE
        page_idx = cur_page
        # write block padded to page boundary
        blk = bytearray(comp)
        blk.extend(b"\x00" * (pages * PAGE - len(comp)))
        tail.extend(blk)
        cur_page += pages
        flags_pages = (flags << 16) | pages
        if vzi is not None:
            indx[vzi] = [page_idx, packed, flags_pages]   # repoint existing block
        else:
            new_bi = len(indx)
            indx.append([page_idx, packed, flags_pages])
            pths.append(path)
            for a in arows:
                a2 = [a[0], a[1], ((new_bi & 0xFFFF) << 16) | (a[2] & 0xFFFF), a[3]]
                aset.append(a2)

    # ---- rebuild index region (INDX | ASET | PTHS) ----
    new_indx = b"".join(struct.pack("<III", *e) for e in indx)
    new_aset = b"".join(struct.pack("<IIII", *e) for e in aset)
    new_pths = b"".join(p.encode("utf-8") + b"\x00" for p in pths) + pths_trailer
    new_indx_off = indx_off
    new_aset_off = new_indx_off + len(new_indx)
    new_pths_off = new_aset_off + len(new_aset)
    region_end = new_pths_off + len(new_pths)
    if region_end > DATA_START:
        sys.exit(f"index region 0x{region_end:X} overflows DATA 0x{DATA_START:X} — not enough slack")
    print(f"new index region ends 0x{region_end:X} (slack to DATA: {DATA_START - region_end} bytes) OK")

    # assemble the new [0..DATA_START) region
    region = bytearray(idx_region)           # keep header + slack/padding bytes
    region[new_indx_off:new_indx_off + len(new_indx)] = new_indx
    region[new_aset_off:new_aset_off + len(new_aset)] = new_aset
    region[new_pths_off:new_pths_off + len(new_pths)] = new_pths
    # zero any leftover between region_end and DATA_START that previously held old PTHS tail
    if region_end < len(region):
        region[region_end:DATA_START] = b"\x00" * (DATA_START - region_end)
    # update header chunk rows
    def set_row(tag, off, meta):
        ho = rows[tag][0]
        struct.pack_into("<II", region, ho + 4, off, meta)
    set_row("INDX", new_indx_off, len(indx))
    set_row("ASET", new_aset_off, len(aset))
    set_row("PTHS", new_pths_off, len(indx))   # PTHS meta == block count (matches original)

    print(f"header updated: INDX n={len(indx)} ASET n={len(aset)} PTHS n={len(indx)}")
    if args.dry_run:
        print("DRY RUN — no writes."); return 0

    # ---- backup index region, then write ----
    bak = vz.with_suffix(vz.suffix + ".idxbak")
    if not bak.exists():
        bak.write_bytes(bytes(idx_region))
        print(f"backed up index region [0..0x{DATA_START:X}) -> {bak.name}")
    with open(vz, "r+b") as f:
        f.seek(0, 2)
        f.write(bytes(tail))        # append new blocks at end
        f.seek(0)
        f.write(bytes(region))      # rewrite header + index region (DATA untouched)
    print(f"SPLICED: appended {len(tail)} bytes; vz.wad now {vz.stat().st_size:,} bytes, {len(indx)} blocks")
    print(f"REVERT: restore {bak.name} over [0..0x{DATA_START:X}) and truncate to {fsize}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
