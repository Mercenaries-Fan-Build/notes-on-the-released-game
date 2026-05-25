#!/usr/bin/env python3
"""Run Phase 0 regression checks and write analysis/cross_platform/phase0_baseline_report.md."""
from __future__ import annotations

import argparse
import hashlib
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / "tools"))

from ffcs_patch_wad import read_patch_wad  # noqa: E402
from pandemic_hash import pandemic_hash_m2  # noqa: E402
from sges_decompress import decompress_sges_block  # noqa: E402


def _sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def _luaq_endian_counts(block_data: bytes) -> tuple[int, int]:
    le = be = 0
    pos = 0
    while True:
        idx = block_data.find(b"\x1bLua", pos)
        if idx < 0:
            break
        if idx + 7 <= len(block_data) and block_data[idx + 4] == 0x51:
            if block_data[idx + 6] == 1:
                le += 1
            elif block_data[idx + 6] == 0:
                be += 1
        pos = idx + 1
    return le, be


def _dlc01_aset_rows(wad: Path) -> list[str]:
    import struct
    from ffcs_wad import parse_ffcs

    raw = wad.read_bytes()
    arch = parse_ffcs(wad)
    aset = next(c for c in arch.chunks if c.tag == "ASET")
    dlc01 = pandemic_hash_m2("dlc01")
    lines = []
    for i in range(aset.meta):
        off = aset.offset + i * 16
        u0, u1, u2, u3 = struct.unpack_from("<IIII", raw, off)
        if u0 != dlc01:
            continue
        blk = (u2 >> 16) & 0xFFFF
        lines.append(f"type_id={u3} block={blk}")
    return lines


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--output-wad", type=Path, default=REPO / "output/data/vz-patch.wad")
    ap.add_argument("--fresh-wad", type=Path, default=REPO / "fresh-rebuilt/data/vz-patch.wad")
    ap.add_argument("--base-wad", type=Path, default=REPO / "game-files/vz.wad")
    ap.add_argument("--report", type=Path,
                    default=REPO / "analysis/cross_platform/phase0_baseline_report.md")
    args = ap.parse_args()

    lines: list[str] = [
        "# Phase 0 baseline report",
        "",
        f"Generated: {datetime.now(timezone.utc).isoformat()}",
        "",
        "## WAD hash comparison",
        "",
    ]

    for label, path in [("output", args.output_wad), ("fresh-rebuilt", args.fresh_wad)]:
        if path.is_file():
            lines.append(f"- **{label}** `{path}`: {path.stat().st_size:,} bytes, "
                         f"sha256 `{_sha256(path)}`")
        else:
            lines.append(f"- **{label}** `{path}`: *missing*")

    if args.output_wad.is_file() and args.fresh_wad.is_file():
        same = _sha256(args.output_wad) == _sha256(args.fresh_wad)
        lines.append(f"- **cmp/sha256 match:** {'yes' if same else 'no — regression candidate'}")
    lines.append("")

    if args.output_wad.is_file():
        lines.extend(["## dlc01 ASET rows (output WAD)", ""])
        for row in _dlc01_aset_rows(args.output_wad):
            lines.append(f"- {row}")
        lines.append("")

        pw = read_patch_wad(args.output_wad)
        resident_idx = None
        for idx, blk in enumerate(pw.blocks):
            path = blk.path_string.replace("/", "\\").lower()
            if (
                "resident" in path
                and "vo_resident" not in path
                and path.endswith("p000_q3.block")
            ):
                resident_idx = idx
                break
        if resident_idx is not None:
            res_blk = pw.blocks[resident_idx]
            res_data = decompress_sges_block(
                res_blk.compressed_data, 0, len(res_blk.compressed_data))
            le, be = _luaq_endian_counts(res_data)
            lines.extend([
                "## DLC script resident block LuaQ endian (gate 0d)",
                "",
                f"- Block index: {resident_idx}",
                f"- Path: `{res_blk.path_string}`",
                f"- Little-endian (PC): {le}",
                f"- Big-endian (Xbox): {be}",
                f"- **Gate:** {'PASS — resident PC-LE' if be == 0 else 'FAIL — keep scripts_vz wrapper'}",
                "",
            ])
        else:
            lines.extend([
                "## DLC script resident block LuaQ endian (gate 0d)",
                "",
                "- *not found* (expected dlc01 resident_P000_Q3, excluding vo_resident)",
                "",
            ])
        if pw.blocks:
            last = pw.blocks[-1]
            lines.extend([
                "## Bootstrap scripts_vz (last block)",
                "",
                f"- Index: {len(pw.blocks) - 1}",
                f"- Path: `{last.path_string}`",
                f"- Compressed: {len(last.compressed_data):,} bytes",
                "",
            ])

    if args.base_wad.is_file() and args.output_wad.is_file():
        lines.append("## verify_dlc_import_chain")
        lines.append("")
        proc = subprocess.run(
            [sys.executable, str(REPO / "tools/verify_dlc_import_chain.py"),
             "--base-wad", str(args.base_wad),
             "--patch-wad", str(args.output_wad)],
            capture_output=True,
            text=True,
            cwd=REPO,
        )
        lines.append("```")
        lines.append(proc.stdout.strip() or proc.stderr.strip())
        lines.append("```")
        lines.append("")

    if args.base_wad.is_file() and args.output_wad.is_file():
        lines.append("## stringdb forensic (english)")
        lines.append("")
        proc = subprocess.run(
            [sys.executable, str(REPO / "tools/dlc_stringdb_forensic.py"),
             "--base-wad", str(args.base_wad),
             "--patch-wad", str(args.output_wad)],
            capture_output=True,
            text=True,
            cwd=REPO,
        )
        lines.append("```")
        lines.append(proc.stdout.strip() or proc.stderr.strip())
        lines.append("```")
        lines.append("")
        lines.append("**Decision:** `_fix_stringdb_descriptors` defaults **off** in `dlc_port.py`. "
                     "Enable only with `--fix-stringdb-descriptors` after proving need.")
        lines.append("")

    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Wrote: {args.report}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
