#!/usr/bin/env python3
"""Verify LE endianness of UCFX blocks in a patch WAD — DETERMINISTIC ONLY.

Structurally walks each decompressed block using ``iter_ucfx_containers`` and
runs only checks that reflect real corruption, never plausibility guesses:

* structural ``body_len`` bounds (a body that overruns the block is corrupt);
* the exact Havok packfile little-endian flag byte (magic+17 must be 1);
* ``--report-blind-swaps``: strict-mode swap failures + typed-coverage gaps.

The old "looks still big-endian" float/range heuristics (BNDS / ``flgs`` /
vertex / index) were REMOVED, not gated behind a flag: they fired on the
retail, known-good LE ``game-files/vz.wad`` at ~4634 issues / 400 blocks — a
higher rate than a converted patch — so they proved nothing and only misled.
We have ground truth; prove conversions against it instead of guessing. See
``.cursor/rules/deterministic-verification.mdc``.

To actually prove a conversion, diff against ground truth:
``tools/wad_be_le_oracle.py`` (converter output == retail ``vz.wad``
byte-for-byte), or round-trip BE→LE→BE == original Xbox bytes.

Usage:
  python3 tools/verify_ucfx_endian.py --wad output/data/vz-patch.wad --report-blind-swaps
"""
from __future__ import annotations

import argparse
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


HAVOK_MAGIC = b"\x57\xe0\xe0\x57\x10\xc0\xc0\x10"
HAVOK_LE_FLAG_OFFSET = 17


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

        # Locate __data__ section only for the real decode gate below. We do NOT
        # sample animationType for a "looks like garbage / still BE?" heuristic:
        # the section/object offset here is approximate, so that test was noise.
        data_sec = _find_havok_data_section(block_data, pos)
        if data_sec is not None and data_sec + 12 <= len(block_data):
            # --havok-decode-gate: attempt wavelet decode (a real decode, not a
            # plausibility guess — it either decodes or raises).
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

            # Body-level float/range plausibility checks were removed: they are
            # noise (fire on retail LE vz.wad). Endianness is proven against
            # ground truth (oracle / round-trip), not inferred per-field here.

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
