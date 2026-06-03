#!/usr/bin/env python3
"""Apply streamed-texture INFO/BODY fixups to an existing LE ``vz-patch.wad``.

Repairs texture containers that still carry Xbox GPU format words at INFO[14:18]
(streamed stubs and partial mip pages). Uses the same logic as ``convert.rs``
``apply_texture_untile`` / ``xbox_texture_codec.convert_streamed_texture``.

Usage:
  python tools/fix_patch_textures.py output/data/vz-patch.wad \\
    --out output/data/vz-patch-fixed.wad
  python tools/fix_patch_textures.py output/data/vz-patch.wad --dry-run
"""
from __future__ import annotations

import argparse
import mmap
import shutil
import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import xbox_texture_codec as texcodec
from sges_compress import compress_sges
from sges_decompress import decompress_sges_block
from validate_patch_wad import _is_valid_fourcc
from wad_patcher import crc32_mercs2, find_data_chunk, get_block_boundaries, parse_block_entries

_TYPE_TEXTURE = 0xF011157A
_SENTINEL = 0xFFFFFFFF


def _parse_descriptors(c: bytes) -> tuple[int, list[tuple[str, int, int]]]:
    dao = struct.unpack_from("<I", c, 4)[0]
    n = struct.unpack_from("<I", c, 16)[0]
    rows: list[tuple[str, int, int]] = []
    for i in range(n):
        doff = 20 + i * 20
        if doff + 20 > len(c):
            break
        tag = c[doff : doff + 4].decode("ascii", "replace")
        u0, bs = struct.unpack_from("<II", c, doff + 4)
        rows.append((tag, u0, bs))
    return dao, rows


def apply_texture_container_fixup_le(container: bytes) -> tuple[bytes, bool]:
    """Fix one LE UCFX texture container. Returns (container, changed)."""
    if len(container) < 20 or container[:4] != b"UCFX":
        return container, False
    dao, rows = _parse_descriptors(container)
    data_start = dao if dao else 8 + 12 + len(rows) * 20

    info_idx = body_idx = None
    for i, (tag, u0, bs) in enumerate(rows):
        if u0 == _SENTINEL:
            continue
        if tag == "INFO" and info_idx is None:
            info_idx = i
        elif tag == "BODY" and body_idx is None and bs > 0:
            body_idx = i

    if info_idx is None:
        return container, False

    _, info_u0, info_bs = rows[info_idx]
    info_abs = data_start + info_u0
    if info_abs + 34 > len(container):
        return container, False
    xi = container[info_abs : info_abs + 34]
    if _is_valid_fourcc(xi[14:18]):
        return container, False

    body_bytes: bytes | None = None
    if body_idx is not None:
        _, body_u0, body_bs = rows[body_idx]
        body_abs = data_start + body_u0
        if body_abs + body_bs <= len(container):
            body_bytes = container[body_abs : body_abs + body_bs]

    try:
        pc_info, pc_body = texcodec.convert_streamed_texture(xi, body_bytes)
    except texcodec.UnsupportedTexture:
        return container, False

    out = bytearray(container)
    out[info_abs : info_abs + 34] = pc_info[:34]

    shrink = 0
    if info_bs > 34:
        shrink = info_bs - 34
        info_end = info_abs + info_bs
        tail = bytes(out[info_end:])
        out = out[: info_abs + 34] + tail
        info_size_field = 20 + info_idx * 20 + 8
        struct.pack_into("<I", out, info_size_field, 34)
        for i, (tag, u0, bs) in enumerate(rows):
            if i == info_idx or u0 == _SENTINEL:
                continue
            if data_start + u0 >= info_end:
                row_field = 20 + i * 20 + 4
                struct.pack_into("<I", out, row_field, u0 - shrink)

    if pc_body is not None and body_idx is not None:
        _, body_u0, _ = rows[body_idx]
        body_abs = data_start + body_u0 - shrink
        body_size_field = 20 + body_idx * 20 + 8
        struct.pack_into("<I", out, body_size_field, len(pc_body))
        out = out[:body_abs] + pc_body

    return bytes(out), True


def fix_block(data: bytes) -> tuple[bytes, int]:
    """Return (new_block, fix_count)."""
    entries = parse_block_entries(data)
    fixes = 0
    replacements: dict[int, tuple[bytes, int]] = {}

    for ent in entries:
        if ent["type_hash"] != _TYPE_TEXTURE:
            continue
        start = ent["offset"]
        end = start + ent["size"] - 8
        chunk = data[start:end]
        pos = chunk.find(b"UCFX")
        if pos < 0:
            continue
        fixed, changed = apply_texture_container_fixup_le(chunk[pos:])
        if not changed:
            continue
        new_chunk = chunk[:pos] + fixed
        new_csum = crc32_mercs2(new_chunk)
        replacements[ent["index"]] = (new_chunk, new_csum)
        fixes += 1

    if not replacements:
        return data, 0

    count = struct.unpack_from("<I", data, 0)[0]
    header_end = 4 + count * 16
    out = bytearray()
    out.extend(data[:4])
    new_sizes: dict[int, int] = {}
    for ent in entries:
        if ent["index"] in replacements:
            new_sizes[ent["index"]] = len(replacements[ent["index"]][0]) + 8
        else:
            new_sizes[ent["index"]] = ent["size"]
    for ent in entries:
        out.extend(
            struct.pack(
                "<IIII",
                ent["hash"],
                ent["type_hash"],
                ent["field_c"],
                new_sizes[ent["index"]],
            )
        )
    for ent in entries:
        if ent["index"] in replacements:
            chunk, csum = replacements[ent["index"]]
            out.extend(chunk)
            out.extend(CSUM_TAG)
            out.extend(struct.pack("<I", csum))
        else:
            s = ent["offset"]
            e = ent["offset"] + ent["size"]
            out.extend(data[s:e])
    return bytes(out), fixes


CSUM_TAG = b"CSUM"


def fix_wad(wad_in: Path, wad_out: Path | None, *, dry_run: bool = False) -> dict:
    dc = find_data_chunk(wad_in)
    total_fixes = 0
    blocks_touched = 0

    with open(wad_in, "rb") as f:
        mm = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)
        boundaries = get_block_boundaries(mm, dc.offset, dc.size)
        patched_blocks: dict[int, bytes] = {}

        for blk_idx, (s, e) in enumerate(boundaries):
            try:
                block = decompress_sges_block(mm, s, e)
            except Exception:
                continue
            new_block, nfix = fix_block(block)
            if nfix:
                blocks_touched += 1
                total_fixes += nfix
                patched_blocks[blk_idx] = new_block

    report = {
        "blocks_touched": blocks_touched,
        "texture_fixes": total_fixes,
        "dry_run": dry_run,
    }
    if dry_run or wad_out is None:
        return report

    shutil.copy2(wad_in, wad_out)
    with open(wad_out, "r+b") as f:
        mm = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_WRITE)
        boundaries = get_block_boundaries(mm, dc.offset, dc.size)
        for blk_idx, new_block in patched_blocks.items():
            s, e = boundaries[blk_idx]
            slot = e - s
            compressed = compress_sges(new_block)
            if len(compressed) > slot:
                raise RuntimeError(
                    f"block {blk_idx}: recompressed {len(compressed)} > slot {slot}"
                )
            mm[s : s + len(compressed)] = compressed
            if len(compressed) < slot:
                mm[s + len(compressed) : e] = b"\x00" * (slot - len(compressed))
    return report


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("wad", type=Path)
    ap.add_argument("--out", type=Path, default=None)
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()
    if not args.wad.is_file():
        print(f"ERROR: not found: {args.wad}", file=sys.stderr)
        return 1
    if not args.dry_run and args.out is None:
        print("ERROR: specify --out or --dry-run", file=sys.stderr)
        return 1

    rep = fix_wad(args.wad, args.out, dry_run=args.dry_run)
    print(f"WAD: {args.wad}")
    print(f"  Blocks touched:   {rep['blocks_touched']}")
    print(f"  Texture fixes:    {rep['texture_fixes']}")
    if args.out and not args.dry_run:
        print(f"  Wrote:            {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
