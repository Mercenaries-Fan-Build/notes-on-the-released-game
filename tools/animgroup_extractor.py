#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Carve Mercenaries 2 *animgroup* block.bin files into per-record UCFX wrappers and
standalone Havok 5.5 binary slices (.hkx).

Block layout (see docs/format_reference.md):
  u32 record_count
  record_count × { u32 checksum, u32 magic 0x18166555, u32 reserved, u32 size }
  record_count × record_bytes (each starts with UCFXP… then payload ending in Havok packfile)
"""

from __future__ import annotations

import argparse
import json
import re
import struct
from pathlib import Path
from typing import Any

RECORD_MAGIC = 0x18166555
HAVOK_VER = b"Havok-5.5.0-r1"


def _ascii_strings(blob: bytes, min_len: int = 4) -> list[str]:
    return [m.group().decode("ascii", errors="replace") for m in re.finditer(rb"[ -~]{%d,}" % min_len, blob)]


def _guess_anim_name(blob: bytes) -> str | None:
    names = []
    for m in re.finditer(rb">([A-Za-z0-9_]+)", blob):
        names.append(m.group(1).decode("ascii", errors="replace"))
    return names[-1] if names else None


def _guess_root_class(blob: bytes) -> str | None:
    for cls in (
        b"hkaAnimationContainer",
        b"hkaWaveletSkeletalAnimation",
        b"hkaDeltaCompressedSkeletalAnimation",
        b"hkaInterleavedUncompressedAnimation",
    ):
        if cls in blob:
            return cls.decode("ascii")
    return None


def parse_record_table(data: bytes) -> tuple[int, list[dict[str, Any]]]:
    if len(data) < 4:
        raise ValueError("empty block")
    (n,) = struct.unpack_from("<I", data, 0)
    need = 4 + n * 16
    if len(data) < need:
        raise ValueError(f"truncated table: need {need} have {len(data)}")
    rows: list[dict[str, Any]] = []
    for i in range(n):
        o = 4 + i * 16
        chk, mag, res, sz = struct.unpack_from("<IIII", data, o)
        if mag != RECORD_MAGIC:
            raise ValueError(f"record {i}: bad magic {mag:#x} expected {RECORD_MAGIC:#x}")
        rows.append({"index": i, "checksum": chk, "checksum_hex": f"0x{chk:08X}", "reserved": res, "size": sz})
    return n, rows


def find_ucfx_and_havok(record: bytes) -> tuple[int, int]:
    """UCFX records use ``UCFX`` + variant tag byte (``P``, ``d``, …) + NUL padding."""
    u = record.find(b"UCFX")
    if u < 0:
        raise ValueError("UCFX signature not found")
    if u + 4 >= len(record) or record[u + 4] == 0:
        raise ValueError("UCFX record missing variant tag after UCFX")
    h = record.find(HAVOK_VER, u)
    if h < 0:
        raise ValueError("Havok-5.5.0-r1 not found")
    return u, h


def extract_block(path: Path, out_dir: Path) -> dict[str, Any]:
    data = path.read_bytes()
    n, rows = parse_record_table(data)
    cursor = 4 + n * 16
    total_expect = sum(r["size"] for r in rows)
    if cursor + total_expect > len(data):
        raise ValueError(
            f"size mismatch: table+records need {cursor+total_expect} have {len(data)}"
        )

    out_dir.mkdir(parents=True, exist_ok=True)
    records_out: list[dict[str, Any]] = []

    for i, row in enumerate(rows):
        sz = row["size"]
        chunk = data[cursor : cursor + sz]
        cursor += sz
        ucfx_off, hk_off = find_ucfx_and_havok(chunk)
        hkx = chunk[hk_off:]
        (out_dir / f"record_{i:04d}.hkx").write_bytes(hkx)
        (out_dir / f"record_{i:04d}.ucfx.bin").write_bytes(chunk)
        anim_guess = _guess_anim_name(hkx)
        cls_guess = _guess_root_class(hkx)
        records_out.append(
            {
                "index": i,
                "checksum_hex": row["checksum_hex"],
                "record_size": sz,
                "ucfx_offset_in_record": ucfx_off,
                "havok_offset_in_record": hk_off,
                "hkx_size": len(hkx),
                "anim_name_guess": anim_guess,
                "root_class_guess": cls_guess,
                "hkx_file": f"record_{i:04d}.hkx",
                "ucfx_file": f"record_{i:04d}.ucfx.bin",
            }
        )

    manifest = {
        "source_block": str(path),
        "record_count": n,
        "records": records_out,
    }
    (out_dir / "records.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    return manifest


def main() -> int:
    ap = argparse.ArgumentParser(description="Carve animgroup .block.bin into per-record .hkx")
    ap.add_argument("block_bin", type=Path, help="Path to *.block.bin")
    ap.add_argument("--out-dir", type=Path, required=True)
    args = ap.parse_args()
    m = extract_block(args.block_bin, args.out_dir)
    print(json.dumps({"wrote": len(m["records"]), "out_dir": str(args.out_dir)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
