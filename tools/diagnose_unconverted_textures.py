#!/usr/bin/env python3
"""Classify unconverted texture entries in a patch WAD by apply_texture_untile bail reason.

Replicates the guards in ``ucfx_byteswap`` ``apply_texture_untile`` against each
texture whose INFO still carries an Xbox GPU format word at [14:18] (no PC FourCC).

Usage:
  python tools/diagnose_unconverted_textures.py output/data/vz-patch.wad \\
    --out output/_scratch/unconverted_texture_diagnosis.json
"""
from __future__ import annotations

import argparse
import json
import mmap
import struct
import sys
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import xbox_texture_codec as texcodec
from ffcs_wad import dump_paths_from_pths, extract_slice, parse_ffcs
from sges_decompress import decompress_sges_block, find_sges_offsets
from validate_patch_wad import _is_valid_fourcc
from wad_patcher import get_block_boundaries, parse_block_entries, find_data_chunk

_TYPE_TEXTURE = 0xF011157A
_SENTINEL = 0xFFFFFFFF


def _load_paths(wad: Path) -> list[str]:
    raw = wad.read_bytes()
    arch = parse_ffcs(wad)
    pths = next(c for c in arch.chunks if c.tag == "PTHS")
    return dump_paths_from_pths(extract_slice(raw, pths))


def _parse_container_descriptors(c: bytes) -> tuple[int, list[dict]]:
    """Return (data_area_off, descriptor rows) for one UCFX container."""
    if len(c) < 20:
        return 0, []
    dao = struct.unpack_from("<I", c, 4)[0]
    n = struct.unpack_from("<I", c, 16)[0]
    rows: list[dict] = []
    for i in range(n):
        doff = 20 + i * 20
        if doff + 20 > len(c):
            break
        tag = c[doff : doff + 4].decode("ascii", "replace")
        u0, bs, u2, u3 = struct.unpack_from("<IIII", c, doff + 4)
        rows.append(
            {
                "index": i,
                "tag": tag,
                "row_u0": u0,
                "body_size": bs,
                "u2": u2,
                "u3": u3,
            }
        )
    return dao, rows


def _body_abs(c: bytes, dao: int, row_u0: int, desc_table_end: int) -> int:
    data_start = dao if dao else desc_table_end
    return data_start + row_u0


def classify_untile_bail(c: bytes, dao: int, descriptors: list[dict]) -> tuple[str, dict]:
    """Mirror convert.rs apply_texture_untile guards; return (reason, details)."""
    desc_table_end = 8 + 12 + len(descriptors) * 20  # UCFX hdr + desc table
    data_start = dao if dao else desc_table_end

    info_idx = body_idx = None
    for i, d in enumerate(descriptors):
        if d["row_u0"] == _SENTINEL:
            continue
        if d["tag"] == "INFO" and info_idx is None:
            info_idx = i
        elif d["tag"] == "BODY" and body_idx is None:
            body_idx = i

    if info_idx is None or body_idx is None:
        return "missing_info_or_body", {}

    info = descriptors[info_idx]
    body = descriptors[body_idx]
    if info["body_size"] < 34:
        return "info_too_short", {"info_size": info["body_size"]}

    info_abs = _body_abs(c, dao, info["row_u0"], desc_table_end)
    body_abs = _body_abs(c, dao, body["row_u0"], desc_table_end)
    if info_abs + 34 > len(c) or body_abs + body["body_size"] > len(c):
        return "body_out_of_bounds", {}

    xi = c[info_abs : info_abs + 34]
    fourcc = texcodec.fourcc_from_xbox_format(xi)
    if fourcc is None:
        return "non_dxt_format", {"fmt_byte": xi[17] if len(xi) > 17 else None}

    width, height = struct.unpack_from("<HH", xi, 0)
    mips = struct.unpack_from("<H", xi, 4)[0]
    if not width or not height:
        return "zero_dims", {"width": width, "height": height}
    if not mips:
        mips = texcodec.mip_levels(width, height)

    expect = texcodec.tiled_body_size(width, height, fourcc, mips)
    tiled = c[body_abs : body_abs + body["body_size"]]
    linear = texcodec.linear_mip_chain_size(width, height, fourcc, mips)

    details = {
        "width": width,
        "height": height,
        "mips": mips,
        "fourcc": fourcc.decode(),
        "body_size": body["body_size"],
        "expect_tiled": expect,
        "linear_size": linear,
        "stream_desc": xi[26:34].hex(),
    }

    if len(tiled) < expect:
        details["shortfall"] = expect - len(tiled)
        return "body_shorter_than_expect", details

    untiled = texcodec.untile_dxt_body(tiled, width, height, fourcc, mips=mips)
    details["untiled_len"] = len(untiled)
    if len(untiled) != linear:
        return "untile_linear_mismatch", details

    body_start_rel = body["row_u0"]
    blocking: list[str] = []
    for i, d in enumerate(descriptors):
        if i == body_idx or d["row_u0"] == _SENTINEL:
            continue
        end = d["row_u0"] + d["body_size"]
        if end > body_start_rel:
            blocking.append(f"{d['tag']}@{d['row_u0']}+{d['body_size']}")
    if blocking:
        details["blocking_chunks"] = blocking
        return "body_not_last", details

    return "would_untile_ok", details


def diagnose(wad_path: Path) -> dict:
    paths = _load_paths(wad_path)
    dc = find_data_chunk(wad_path)
    findings: list[dict] = []
    reason_counts: Counter[str] = Counter()

    with open(wad_path, "rb") as f:
        mm = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)
        boundaries = get_block_boundaries(mm, dc.offset, dc.size)

        for blk_idx, (s, e) in enumerate(boundaries):
            try:
                data = decompress_sges_block(mm, s, e)
            except Exception:
                continue

            block_path = paths[blk_idx] if blk_idx < len(paths) else f"block_{blk_idx}"

            for ent in parse_block_entries(data):
                if ent["type_hash"] != _TYPE_TEXTURE:
                    continue
                chunk = data[ent["offset"] : ent["offset"] + ent["size"] - 8]
                pos = chunk.find(b"UCFX")
                if pos < 0:
                    continue
                c = chunk[pos:]
                dao, descriptors = _parse_container_descriptors(c)

                for i, d in enumerate(descriptors):
                    if d["tag"] != "INFO" or d["row_u0"] == _SENTINEL:
                        continue
                    if d["body_size"] < 18:
                        continue
                    bstart = (dao if dao else 8 + 12 + len(descriptors) * 20) + d["row_u0"]
                    if bstart + 18 > len(c):
                        continue
                    info_body = c[bstart : bstart + min(d["body_size"], 34)]
                    if _is_valid_fourcc(info_body[14:18]):
                        continue  # already converted

                    reason, details = classify_untile_bail(c, dao, descriptors)
                    reason_counts[reason] += 1
                    findings.append(
                        {
                            "block_index": blk_idx,
                            "block_path": block_path,
                            "asset_hash": f"0x{ent['hash']:08X}",
                            "descriptor_index": i,
                            "reason": reason,
                            **details,
                        }
                    )

    return {
        "wad": str(wad_path),
        "unconverted_count": len(findings),
        "histogram": dict(reason_counts.most_common()),
        "findings": findings,
    }


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("wad", type=Path)
    ap.add_argument(
        "--out",
        type=Path,
        default=Path("output/_scratch/unconverted_texture_diagnosis.json"),
    )
    args = ap.parse_args()
    if not args.wad.is_file():
        print(f"ERROR: not found: {args.wad}", file=sys.stderr)
        return 1

    report = diagnose(args.wad)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(report, indent=2), encoding="utf-8")

    print(f"WAD: {args.wad}")
    print(f"  Unconverted textures: {report['unconverted_count']}")
    print("  Histogram:")
    for reason, count in report["histogram"].items():
        print(f"    {reason}: {count}")
    print(f"  Wrote {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
