#!/usr/bin/env python3
"""Verify LE endianness of UCFX blocks in a patch WAD.

Structurally walks each decompressed block using ``iter_ucfx_containers`` and
validates field values in context. Flags values that look like they are still
big-endian (LE implausible, BE plausible).

Usage:
  python3 tools/verify_ucfx_endian.py --wad output/data/vz-patch.wad
  python3 tools/verify_ucfx_endian.py --wad vz-patch.wad --max-blocks 50 --verbose
"""
from __future__ import annotations

import argparse
import math
import struct
import sys
from dataclasses import dataclass, field
from pathlib import Path

THIS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(THIS_DIR))

from ffcs_wad import dump_paths_from_pths, extract_slice, parse_ffcs  # noqa: E402
from sges_decompress import decompress_sges_block, find_sges_offsets  # noqa: E402
from ucfx_be_to_le import byteswap_ucfx_block, UnhandledByteSwapError  # noqa: E402
from ucfx_mesh_codec import (  # noqa: E402
    CONTAINER_SENTINEL,
    CHUNK_HDR,
    iter_ucfx_containers,
)

COORD_MIN = -5000.0
COORD_MAX = 5000.0
ELEV_MIN = -500.0
ELEV_MAX = 1000.0
BNDS_LIMIT = 10000.0
VERTEX_LIMIT = 1_000_000.0


@dataclass
class EndianIssue:
    block_index: int
    block_path: str
    ucfx_off: int
    tag: str
    field: str
    offset: int
    value_le: float | int
    value_be: float | int
    message: str


@dataclass
class VerifyStats:
    blocks_scanned: int = 0
    ucfx_containers: int = 0
    descriptor_rows: int = 0
    issues: list[EndianIssue] = field(default_factory=list)


def _body_abs(
    data: bytes, ucfx_start: int, row_pos: int, data_base: int, ucfx_u0: int
) -> tuple[int, int]:
    body_off_rel, body_len, _, _ = struct.unpack_from("<IIII", data, row_pos + 4)
    if ucfx_u0 > 0:
        ba = data_base + body_off_rel
    else:
        ba = ucfx_start + 8 + body_off_rel
    return ba, body_len


def _likely_still_be_f32(raw: bytes, lo: float, hi: float) -> tuple[bool, float, float]:
    le_v = struct.unpack_from("<f", raw, 0)[0]
    be_v = struct.unpack_from(">f", raw, 0)[0]

    def ok(v: float) -> bool:
        if math.isnan(v) or math.isinf(v):
            return False
        return lo <= v <= hi

    le_ok = ok(le_v)
    be_ok = ok(be_v)
    return (not le_ok and be_ok), le_v, be_v


def _likely_still_be_u32(raw: bytes, max_val: int) -> tuple[bool, int, int]:
    le_v = struct.unpack_from("<I", raw, 0)[0]
    be_v = struct.unpack_from(">I", raw, 0)[0]
    le_ok = le_v <= max_val
    be_ok = be_v <= max_val
    return (not le_ok and be_ok and be_v != le_v), le_v, be_v


def _add_issue(
    stats: VerifyStats,
    *,
    block_index: int,
    block_path: str,
    ucfx_off: int,
    tag: str,
    field_name: str,
    offset: int,
    value_le: float | int,
    value_be: float | int,
    message: str,
) -> None:
    stats.issues.append(
        EndianIssue(
            block_index=block_index,
            block_path=block_path,
            ucfx_off=ucfx_off,
            tag=tag,
            field=field_name,
            offset=offset,
            value_le=value_le,
            value_be=value_be,
            message=message,
        )
    )


def _check_descriptor_row(
    data: bytes,
    stats: VerifyStats,
    *,
    block_index: int,
    block_path: str,
    ucfx_off: int,
    data_base: int,
    ucfx_u0: int,
    row_pos: int,
    tag: bytes,
    last_container: str | None,
) -> str | None:
    stats.descriptor_rows += 1
    le_tag = tag.decode("ascii", errors="replace")
    row_u0, body_len, _, _ = struct.unpack_from("<IIII", data, row_pos + 4)

    if row_u0 != CONTAINER_SENTINEL and body_len > 0:
        ba, _ = _body_abs(data, ucfx_off, row_pos, data_base, ucfx_u0)
        max_rel = len(data) - data_base if ucfx_u0 > 0 else len(data) - ucfx_off
        if body_len > max_rel * 4 + 1024:
            still_be, le_v, be_v = _likely_still_be_u32(
                struct.pack("<I", body_len), max_val=max_rel
            )
            if still_be or body_len > len(data):
                _add_issue(
                    stats,
                    block_index=block_index,
                    block_path=block_path,
                    ucfx_off=ucfx_off,
                    tag=le_tag,
                    field_name="body_len",
                    offset=row_pos + 8,
                    value_le=le_v,
                    value_be=be_v,
                    message=f"body_len out of range (max~{max_rel})",
                )

    if row_u0 == CONTAINER_SENTINEL:
        if le_tag in ("STRM", "GEOM"):
            return "STRM"
        if le_tag == "IBUF":
            return "IBUF"
    return last_container


def _check_bnds(
    data: bytes,
    stats: VerifyStats,
    *,
    block_index: int,
    block_path: str,
    ucfx_off: int,
    ba: int,
    body_len: int,
) -> None:
    end = min(ba + body_len, len(data))
    for i in range(10):
        off = ba + i * 4
        if off + 4 > end:
            break
        raw = data[off : off + 4]
        still_be, le_v, be_v = _likely_still_be_f32(raw, -BNDS_LIMIT, BNDS_LIMIT)
        if still_be:
            _add_issue(
                stats,
                block_index=block_index,
                block_path=block_path,
                ucfx_off=ucfx_off,
                tag="BNDS",
                field_name=f"float[{i}]",
                offset=off,
                value_le=le_v,
                value_be=be_v,
                message="BNDS float looks BE",
            )


def _check_flgs(
    data: bytes,
    stats: VerifyStats,
    *,
    block_index: int,
    block_path: str,
    ucfx_off: int,
    ba: int,
    body_len: int,
) -> None:
    end = min(ba + body_len, len(data))
    pos = ba
    while pos + 42 <= end:
        for field_name, foff, lo, hi in (
            ("x", 4, COORD_MIN, COORD_MAX),
            ("y", 18, ELEV_MIN, ELEV_MAX),
            ("z", 22, COORD_MIN, COORD_MAX),
            ("qx", 26, -1.5, 1.5),
            ("qy", 30, -1.5, 1.5),
            ("qz", 34, -1.5, 1.5),
            ("qw", 38, -1.5, 1.5),
        ):
            off = pos + foff
            raw = data[off : off + 4]
            still_be, le_v, be_v = _likely_still_be_f32(raw, lo, hi)
            if still_be:
                _add_issue(
                    stats,
                    block_index=block_index,
                    block_path=block_path,
                    ucfx_off=ucfx_off,
                    tag="flgs",
                    field_name=field_name,
                    offset=off,
                    value_le=le_v,
                    value_be=be_v,
                    message="placement float looks BE",
                )
        pos += 42


def _check_vertex_data(
    data: bytes,
    stats: VerifyStats,
    *,
    block_index: int,
    block_path: str,
    ucfx_off: int,
    ba: int,
    body_len: int,
) -> None:
    end = min(ba + body_len, len(data))
    samples = 0
    pos = ba
    while pos + 4 <= end and samples < 64:
        raw = data[pos : pos + 4]
        le_v = struct.unpack_from("<f", raw, 0)[0]
        if abs(le_v) > VERTEX_LIMIT and not math.isnan(le_v):
            still_be, _, be_v = _likely_still_be_f32(raw, -VERTEX_LIMIT, VERTEX_LIMIT)
            if still_be:
                _add_issue(
                    stats,
                    block_index=block_index,
                    block_path=block_path,
                    ucfx_off=ucfx_off,
                    tag="data",
                    field_name="vertex_f32",
                    offset=pos,
                    value_le=le_v,
                    value_be=be_v,
                    message="vertex float looks BE",
                )
                break
        pos += 4
        samples += 1


def _check_ibuf_data(
    data: bytes,
    stats: VerifyStats,
    *,
    block_index: int,
    block_path: str,
    ucfx_off: int,
    ba: int,
    body_len: int,
) -> None:
    end = min(ba + body_len, len(data))
    if end - ba < 2:
        return
    n = min((end - ba) // 2, 256)
    words = struct.unpack_from(f"<{n}H", data, ba)
    if not words:
        return
    mx = max(words)
    if mx == 0xFFFF:
        return
    # Many valid meshes have max index < 65535; BE u16 often yields 0xXX00 patterns
    be_words = struct.unpack_from(f">{n}H", data, ba)
    be_mx = max(be_words)
    if mx > 60000 and be_mx < mx // 256:
        _add_issue(
            stats,
            block_index=block_index,
            block_path=block_path,
            ucfx_off=ucfx_off,
            tag="data",
            field_name="index_u16_max",
            offset=ba,
            value_le=mx,
            value_be=be_mx,
            message="index buffer max looks BE-swapped wrong",
        )


HAVOK_MAGIC = b"\x57\xe0\xe0\x57\x10\xc0\xc0\x10"
HAVOK_LE_FLAG_OFFSET = 17
VALID_ANIMATION_TYPES = (1, 2, 3)


def _find_havok_data_section(data: bytes, packfile_start: int) -> int | None:
    """Return offset of the __data__ section within a Havok packfile, or None."""
    marker = b"__data__"
    pos = data.find(marker, packfile_start)
    if pos == -1:
        return None
    # Section header: after the name there's padding to 16-byte alignment,
    # then absolute/local/virtual fixup offsets and section data.
    # The actual data payload starts after the section header (0x40 bytes past
    # the 16-aligned start of the section entry).  We search for the next
    # 16-aligned boundary after the marker string.
    entry_start = pos
    # Havok section entries are 0x40 bytes; data begins right after.
    data_start = entry_start + 0x40
    if data_start < len(data):
        return data_start
    return None


def _check_havok_packfile(
    block_data: bytes,
    stats: VerifyStats,
    *,
    block_index: int,
    block_path: str,
    havok_decode_gate: bool = False,
) -> dict[str, int]:
    """Scan block for Havok packfile magic and validate LE conversion."""
    havok_stats: dict[str, int] = {
        "packfiles_found": 0,
        "le_flag_ok": 0,
        "le_flag_bad": 0,
        "anim_type_ok": 0,
        "anim_type_bad": 0,
        "wavelet_decode_ok": 0,
        "wavelet_decode_fail": 0,
    }
    search_from = 0
    while True:
        pos = block_data.find(HAVOK_MAGIC, search_from)
        if pos == -1:
            break
        havok_stats["packfiles_found"] += 1

        # Check is_little_endian flag at offset +17 from magic
        le_flag_off = pos + HAVOK_LE_FLAG_OFFSET
        if le_flag_off < len(block_data):
            le_flag = block_data[le_flag_off]
            if le_flag == 1:
                havok_stats["le_flag_ok"] += 1
            else:
                havok_stats["le_flag_bad"] += 1
                _add_issue(
                    stats,
                    block_index=block_index,
                    block_path=block_path,
                    ucfx_off=pos,
                    tag="HavokPF",
                    field_name="is_little_endian",
                    offset=le_flag_off,
                    value_le=le_flag,
                    value_be=1,
                    message=f"Havok packfile is_little_endian={le_flag} (expected 1)",
                )

        # Try to find __data__ section and check animationType
        data_sec = _find_havok_data_section(block_data, pos)
        if data_sec is not None and data_sec + 12 <= len(block_data):
            # animationType lives at offset +8 within __data__ payload objects
            # (first object after virtual fixup base). We sample the u32 at +8.
            anim_type_off = data_sec + 8
            if anim_type_off + 4 <= len(block_data):
                anim_type = struct.unpack_from("<I", block_data, anim_type_off)[0]
                if anim_type in VALID_ANIMATION_TYPES:
                    havok_stats["anim_type_ok"] += 1
                elif anim_type == 0:
                    # 0 could mean non-animation data in __data__; not an issue
                    pass
                elif anim_type > 0xFFFF:
                    havok_stats["anim_type_bad"] += 1
                    be_anim = struct.unpack_from(">I", block_data, anim_type_off)[0]
                    _add_issue(
                        stats,
                        block_index=block_index,
                        block_path=block_path,
                        ucfx_off=pos,
                        tag="HavokPF",
                        field_name="animationType",
                        offset=anim_type_off,
                        value_le=anim_type,
                        value_be=be_anim,
                        message="animationType looks like garbage (still BE?)",
                    )

            # --havok-decode-gate: attempt wavelet decode
            if havok_decode_gate and data_sec + 8 + 4 <= len(block_data):
                atype = struct.unpack_from("<I", block_data, data_sec + 8)[0]
                if atype == 3:
                    try:
                        from hk_anim.wavelet import decode_wavelet  # type: ignore[import-untyped]
                        decode_wavelet(block_data[data_sec:])
                        havok_stats["wavelet_decode_ok"] += 1
                    except Exception:
                        havok_stats["wavelet_decode_fail"] += 1

        # Advance past this packfile to find next
        search_from = pos + len(HAVOK_MAGIC)

    return havok_stats


def verify_block(
    block_data: bytes,
    *,
    block_index: int,
    block_path: str,
    havok_decode_gate: bool = False,
) -> tuple[VerifyStats, dict[str, int]]:
    stats = VerifyStats(blocks_scanned=1)
    for container in iter_ucfx_containers(block_data):
        stats.ucfx_containers += 1
        ucfx_off = container["ucfx_off"]
        data_base = container["data_base"]
        chunks = container["chunks"]
        ucfx_u0 = struct.unpack_from("<I", block_data, ucfx_off + 4)[0]

        last_container: str | None = None
        for i, (tag, cu) in enumerate(chunks):
            row_pos = ucfx_off + 20 + i * CHUNK_HDR
            last_container = _check_descriptor_row(
                block_data,
                stats,
                block_index=block_index,
                block_path=block_path,
                ucfx_off=ucfx_off,
                data_base=data_base,
                ucfx_u0=ucfx_u0,
                row_pos=row_pos,
                tag=tag,
                last_container=last_container,
            )

            body_off_rel, body_len = int(cu[0]), int(cu[1])
            if body_off_rel == CONTAINER_SENTINEL or body_len <= 0:
                continue
            ba, _ = _body_abs(block_data, ucfx_off, row_pos, data_base, ucfx_u0)
            if ba >= len(block_data):
                continue

            le_tag = tag.decode("ascii", errors="replace")
            if le_tag == "BNDS":
                _check_bnds(
                    block_data,
                    stats,
                    block_index=block_index,
                    block_path=block_path,
                    ucfx_off=ucfx_off,
                    ba=ba,
                    body_len=body_len,
                )
            elif le_tag == "flgs":
                _check_flgs(
                    block_data,
                    stats,
                    block_index=block_index,
                    block_path=block_path,
                    ucfx_off=ucfx_off,
                    ba=ba,
                    body_len=body_len,
                )
            elif le_tag == "data":
                if last_container == "IBUF":
                    _check_ibuf_data(
                        block_data,
                        stats,
                        block_index=block_index,
                        block_path=block_path,
                        ucfx_off=ucfx_off,
                        ba=ba,
                        body_len=body_len,
                    )
                else:
                    _check_vertex_data(
                        block_data,
                        stats,
                        block_index=block_index,
                        block_path=block_path,
                        ucfx_off=ucfx_off,
                        ba=ba,
                        body_len=body_len,
                    )

    # Havok packfile scan — independent of UCFX chunk structure
    havok_stats = _check_havok_packfile(
        block_data,
        stats,
        block_index=block_index,
        block_path=block_path,
        havok_decode_gate=havok_decode_gate,
    )

    return stats, havok_stats


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--wad", type=Path, required=True)
    ap.add_argument("--max-blocks", type=int, default=0, help="0 = all blocks")
    ap.add_argument("--start", type=int, default=0)
    ap.add_argument("--verbose", action="store_true")
    ap.add_argument("--fail-on-issues", action="store_true")
    ap.add_argument(
        "--report-blind-swaps",
        action="store_true",
        help="Run permissive BE→LE pass and report fallback_u32_count per block; "
        "also note blocks that fail in strict mode",
    )
    ap.add_argument(
        "--havok-decode-gate",
        action="store_true",
        help="Attempt wavelet decode on blocks with animationType==3; report success/failure",
    )
    args = ap.parse_args()

    if not args.wad.is_file():
        print(f"ERROR: not found: {args.wad}", file=sys.stderr)
        return 1

    raw = args.wad.read_bytes()
    if raw[:4] != b"FFCS":
        print("ERROR: not FFCS", file=sys.stderr)
        return 1

    arch = parse_ffcs(args.wad)
    data_chunk = next(c for c in arch.chunks if c.tag == "DATA")
    pths_chunk = next(c for c in arch.chunks if c.tag == "PTHS")
    data_blob = extract_slice(raw, data_chunk)
    paths = dump_paths_from_pths(extract_slice(raw, pths_chunk))
    offsets = find_sges_offsets(data_blob)
    limit = min(len(offsets), len(paths))

    total = VerifyStats()
    blind_swap_blocks = 0
    strict_fail_blocks = 0
    total_fallback_u32 = 0
    # Havok aggregate stats
    total_havok_packfiles = 0
    total_havok_le_ok = 0
    total_havok_le_bad = 0
    total_havok_anim_ok = 0
    total_havok_anim_bad = 0
    total_wavelet_ok = 0
    total_wavelet_fail = 0
    # Havok class-aware stats from byteswap (aggregated under --report-blind-swaps)
    total_havok_class_aware = 0
    total_havok_no_swap_regions = 0
    total_havok_blind_sweep = 0

    end = limit if args.max_blocks <= 0 else min(limit, args.start + args.max_blocks)
    for idx in range(args.start, end):
        off = offsets[idx]
        block_end = offsets[idx + 1] if idx + 1 < len(offsets) else len(data_blob)
        try:
            block_data = decompress_sges_block(data_blob, off, block_end)
        except Exception as exc:
            print(f"[{idx}] FAIL decompress {paths[idx]}: {exc}", file=sys.stderr)
            continue

        block_stats, havok_block = verify_block(
            block_data,
            block_index=idx,
            block_path=paths[idx],
            havok_decode_gate=args.havok_decode_gate,
        )
        total.blocks_scanned += block_stats.blocks_scanned
        total.ucfx_containers += block_stats.ucfx_containers
        total.descriptor_rows += block_stats.descriptor_rows
        total.issues.extend(block_stats.issues)

        # Accumulate Havok per-block stats
        total_havok_packfiles += havok_block.get("packfiles_found", 0)
        total_havok_le_ok += havok_block.get("le_flag_ok", 0)
        total_havok_le_bad += havok_block.get("le_flag_bad", 0)
        total_havok_anim_ok += havok_block.get("anim_type_ok", 0)
        total_havok_anim_bad += havok_block.get("anim_type_bad", 0)
        total_wavelet_ok += havok_block.get("wavelet_decode_ok", 0)
        total_wavelet_fail += havok_block.get("wavelet_decode_fail", 0)

        if args.verbose and block_stats.issues:
            print(f"[{idx}] {paths[idx]}: {len(block_stats.issues)} issue(s)")

        if args.report_blind_swaps:
            try:
                byteswap_ucfx_block(block_data, permissive=False)
            except UnhandledByteSwapError as exc:
                strict_fail_blocks += 1
                if args.verbose:
                    print(f"[{idx}] strict swap FAIL: {exc}")
            _, swap_stats = byteswap_ucfx_block(block_data, permissive=True)
            fb = int(swap_stats.get("fallback_u32_count", 0))
            if fb:
                blind_swap_blocks += 1
                total_fallback_u32 += fb
                tags = swap_stats.get("fallback_u32_tags", {})
                print(
                    f"[{idx}] {paths[idx]}: {fb} permissive fallback u32 swap(s) "
                    f"{tags if tags else ''}"
                )
            # Havok class-aware converter stats
            total_havok_class_aware += int(
                swap_stats.get("havok_class_aware_objects", 0)
            )
            total_havok_no_swap_regions += int(
                swap_stats.get("havok_no_swap_regions", 0)
            )
            total_havok_blind_sweep += int(
                swap_stats.get("havok_blind_data_sweep", 0)
            )

    print(f"WAD: {args.wad}")
    print(f"  Blocks scanned:     {total.blocks_scanned}")
    print(f"  UCFX containers:    {total.ucfx_containers}")
    print(f"  Descriptor rows:    {total.descriptor_rows}")
    print(f"  Endian issues:      {len(total.issues)}")
    if total_havok_packfiles:
        print(f"  Havok packfiles:    {total_havok_packfiles}")
        print(f"    LE flag OK:       {total_havok_le_ok}")
        print(f"    LE flag BAD:      {total_havok_le_bad}")
        print(f"    animType OK:      {total_havok_anim_ok}")
        print(f"    animType BAD:     {total_havok_anim_bad}")
    if args.havok_decode_gate and (total_wavelet_ok or total_wavelet_fail):
        print(f"  Wavelet decode OK:  {total_wavelet_ok}")
        print(f"  Wavelet decode FAIL:{total_wavelet_fail}")
    if args.report_blind_swaps:
        print(f"  Strict swap failures: {strict_fail_blocks}")
        print(f"  Blocks w/ fallback u32: {blind_swap_blocks}")
        print(f"  Total fallback u32 ops: {total_fallback_u32}")
        print(f"  Havok class-aware objects: {total_havok_class_aware}")
        print(f"  Havok no-swap regions:     {total_havok_no_swap_regions}")
        print(f"  Havok blind data sweep:    {total_havok_blind_sweep}")

    shown = 0
    for issue in total.issues[:50]:
        print(
            f"  [{issue.block_index}] {issue.block_path} "
            f"UCFX+0x{issue.ucfx_off:X} {issue.tag}.{issue.field} "
            f"@0x{issue.offset:X}: LE={issue.value_le!r} BE={issue.value_be!r} — {issue.message}"
        )
        shown += 1
    if len(total.issues) > shown:
        print(f"  ... and {len(total.issues) - shown} more")

    if args.fail_on_issues and total.issues:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
