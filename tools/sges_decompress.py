#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Decompress Mercenaries 2 DATA chunks: each logical `.block` is an `sges` segment."""

from __future__ import annotations

import argparse
import json
import math
import mmap as mmap_mod
import re
import struct
import subprocess
import sys
import zlib
from pathlib import Path as PathLib

import typing as _t

THIS_DIR = PathLib(__file__).resolve().parent
sys.path.insert(0, str(THIS_DIR))

from ffcs_wad import dump_paths_from_pths, extract_slice, parse_ffcs  # noqa: E402

SGES_MAGIC = b"sges"


def sges_data_offset(num_segments: int) -> int:
    return math.ceil((16 + num_segments * 8) / 16) * 16


def parse_sges_header(blob: bytes, off: int = 0) -> tuple[int, int, int, int]:
    if blob[off : off + 4] != SGES_MAGIC:
        raise ValueError("bad sges magic")
    major, minor = struct.unpack_from("<HH", blob, off + 4)
    total_u, total_c = struct.unpack_from("<II", blob, off + 8)
    return major, minor, total_u, total_c


def decompress_sges_block(mm: mmap_mod.mmap | bytes, block_start: int, block_end: int, *, max_out: int | None = None) -> bytes:
    if isinstance(mm, bytes):
        data = mm
        length = len(data)

        def read_slice(a: int, b: int) -> bytes:
            return data[a:b]
    else:
        length = len(mm)

        def read_slice(a: int, b: int) -> bytes:
            return mm[a:b]

    _maj, minor, total_u, _tc = parse_sges_header(read_slice(block_start, block_start + 16))
    start_payload = block_start + sges_data_offset(minor)
    target = total_u if max_out is None else min(total_u, max_out)

    out = bytearray()
    pos = start_payload
    end = min(block_end, length)

    while len(out) < target and pos < end:
        while pos < end and read_slice(pos, pos + 1)[0] == 0:
            pos += 1
        if pos >= end:
            break
        try:
            chunk = read_slice(pos, min(pos + 131072, end))
            dec = zlib.decompressobj(-15)
            piece = dec.decompress(chunk)
            consumed = len(chunk) - len(dec.unused_data)
            out.extend(piece)
            pos += consumed
        except zlib.error:
            break

    if len(out) > target:
        del out[target:]
    return bytes(out)


def find_sges_offsets(data: bytes | mmap_mod.mmap) -> list[int]:
    out: list[int] = []
    start = 0
    while True:
        idx = data.find(SGES_MAGIC, start)
        if idx == -1:
            break
        out.append(idx)
        start = idx + 1
    return out


def load_data_blob(data_bin: PathLib | None, wad: PathLib | None) -> tuple[mmap_mod.mmap | bytes, PathLib]:
    if data_bin is not None:
        if not data_bin.is_file():
            raise FileNotFoundError(data_bin)
        f = open(data_bin, "rb")
        mm = mmap_mod.mmap(f.fileno(), 0, access=mmap_mod.ACCESS_READ)
        f.close()
        return mm, data_bin
    if wad is None:
        raise ValueError("need --data-bin or --wad")
    raw = wad.read_bytes()
    arch = parse_ffcs(wad)
    dc = next((c for c in arch.chunks if c.tag == "DATA"), None)
    if dc is None or dc.size == 0:
        raise ValueError("no DATA chunk")
    return extract_slice(raw, dc), wad


def load_paths(paths_txt: PathLib | None, pths_bin: PathLib | None, ffcs_out: PathLib | None) -> list[str]:
    if paths_txt and paths_txt.is_file():
        return [ln for ln in paths_txt.read_text(encoding="utf-8", errors="replace").splitlines() if ln.strip()]
    if pths_bin and pths_bin.is_file():
        return dump_paths_from_pths(pths_bin.read_bytes())
    if ffcs_out:
        pt = ffcs_out / "paths.txt"
        if pt.is_file():
            return load_paths(pt, None, None)
    return []


def safe_filename(path_like: str) -> str:
    return path_like.replace("\\", "__").replace("/", "__")


def safe_block_stem(path_line: str) -> str:
    """Match ``scripts/extract_all_from_paths.sh`` stem sanitization (``tr`` + ``sed``)."""
    s = path_line.replace("\\", "/")
    if s.startswith("./"):
        s = s[2:]
    s = s.replace("/", "__")
    return re.sub(r"[^A-Za-z0-9._-]", "_", s, flags=re.ASCII)


def run_bulk_extract(
    data_bin: PathLib,
    paths_txt: PathLib,
    out_dir: PathLib,
    *,
    start: int = 0,
    max_blocks: int | None = None,
    skip_existing: bool = False,
    max_out: int | None = None,
    failures_out: PathLib | None = None,
    manifest_out: PathLib | None = None,
    ucfx_out_dir: PathLib | None = None,
) -> int:
    """One mmap + one sges scan; write ``{idx:05d}_{stem}.bin`` for each path index (same as batch shell)."""
    paths = load_paths(paths_txt, None, None)
    if not paths:
        print("bulk: no paths in paths.txt", file=sys.stderr)
        return 1
    blob, src = load_data_blob(data_bin, None)
    had_failure = False
    manifest: list[dict[str, object]] = []
    try:
        size = len(blob)
        offsets = find_sges_offsets(blob)
        if not offsets:
            print("No sges magic found.", file=sys.stderr)
            return 1
        limit = min(len(offsets), len(paths))
        if start < 0 or start >= limit:
            print(f"bulk: --start {start} out of range (limit {limit})", file=sys.stderr)
            return 1

        out_dir.mkdir(parents=True, exist_ok=True)
        if ucfx_out_dir is not None:
            ucfx_out_dir.mkdir(parents=True, exist_ok=True)

        processed = 0
        idx = start
        while idx < limit:
            if max_blocks is not None and processed >= max_blocks:
                break
            line = paths[idx]
            stem = safe_block_stem(line)
            fname = f"{idx:05d}_{stem}.bin"
            out_path = out_dir / fname

            if skip_existing and out_path.is_file():
                print(f"skip existing [{idx}] {line}")
                manifest.append({"index": idx, "path": line, "file": fname, "size": out_path.stat().st_size, "skipped": True})
                processed += 1
                idx += 1
                continue

            try:
                off = offsets[idx]
                block_end = offsets[idx + 1] if idx + 1 < len(offsets) else size
                raw_out = decompress_sges_block(blob, off, block_end, max_out=max_out)
                out_path.write_bytes(raw_out)
                print(f"[{idx}] -> {fname} ({len(raw_out)} bytes)")
                manifest.append({"index": idx, "path": line, "file": fname, "size": len(raw_out)})

                if ucfx_out_dir is not None:
                    json_path = ucfx_out_dir / f"{idx:05d}_{stem}.json"
                    rc = subprocess.run(
                        [sys.executable, str(THIS_DIR / "ucfx_parser.py"), str(out_path), "--out", str(json_path)],
                        capture_output=True,
                        text=True,
                    ).returncode
                    if rc != 0:
                        had_failure = True
                        msg = f"UCFX_FAIL idx={idx} path={line!r}"
                        print(msg, file=sys.stderr)
                        if failures_out is not None:
                            failures_out.parent.mkdir(parents=True, exist_ok=True)
                            with failures_out.open("a", encoding="utf-8") as ff:
                                ff.write(msg + "\n")
            except Exception as exc:  # noqa: BLE001
                had_failure = True
                msg = f"FAILED idx={idx} path={line!r} err={exc}"
                print(msg, file=sys.stderr)
                if failures_out is not None:
                    failures_out.parent.mkdir(parents=True, exist_ok=True)
                    with failures_out.open("a", encoding="utf-8") as ff:
                        ff.write(msg + "\n")

            processed += 1
            idx += 1

        if manifest_out is not None:
            manifest_out.parent.mkdir(parents=True, exist_ok=True)
            manifest_out.write_text(
                json.dumps({"source": str(src), "paths_txt": str(paths_txt), "blocks": manifest}, indent=2),
                encoding="utf-8",
            )
        return 1 if had_failure else 0
    finally:
        if isinstance(blob, mmap_mod.mmap):
            blob.close()


def main() -> int:
    ap = argparse.ArgumentParser(description="Decompress Mercenaries 2 sges blocks")
    ap.add_argument("--data-bin", type=PathLib)
    ap.add_argument("--wad", type=PathLib)
    ap.add_argument("--paths", type=PathLib, help="paths.txt (same as batch extract)")
    ap.add_argument("--pths", type=PathLib)
    ap.add_argument("--ffcs-out", type=PathLib)
    ap.add_argument("--index", type=int)
    ap.add_argument("--name", type=str)
    ap.add_argument("--regex", type=str)
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--out", type=PathLib, default=None, help="Output file or directory (not used with --bulk-out-dir)")
    ap.add_argument("--max-bytes", type=int, default=0)
    ap.add_argument(
        "--bulk-out-dir",
        type=PathLib,
        help="Extract all blocks in one pass (single mmap + scan); matches extract_all_from_paths.sh naming",
    )
    ap.add_argument("--start", type=int, default=0, help="First path index (with --bulk-out-dir)")
    ap.add_argument("--max", type=int, default=None, help="Max path slots after --start, including skips (with --bulk-out-dir)")
    ap.add_argument("--skip-existing", action="store_true", help="Skip when output .bin already exists (bulk mode)")
    ap.add_argument("--bulk-manifest", type=PathLib, default=None, help="Write bulk manifest JSON (bulk mode)")
    ap.add_argument("--failures-out", type=PathLib, default=None, help="Append failure lines (bulk mode)")
    ap.add_argument("--ucfx-out-dir", type=PathLib, default=None, help="Run ucfx_parser per block into this dir (bulk mode)")
    args = ap.parse_args()

    max_out: int | None = args.max_bytes if args.max_bytes > 0 else None

    if args.bulk_out_dir is not None:
        if args.data_bin is None or not args.data_bin.is_file():
            ap.error("--bulk-out-dir requires --data-bin")
        if args.paths is None or not args.paths.is_file():
            ap.error("--bulk-out-dir requires --paths (paths.txt)")
        if args.failures_out is not None:
            args.failures_out.write_text("", encoding="utf-8")
        return run_bulk_extract(
            args.data_bin,
            args.paths,
            args.bulk_out_dir,
            start=args.start,
            max_blocks=args.max,
            skip_existing=args.skip_existing,
            max_out=max_out,
            failures_out=args.failures_out,
            manifest_out=args.bulk_manifest,
            ucfx_out_dir=args.ucfx_out_dir,
        )

    if args.list:
        if args.data_bin is None and args.wad is None:
            ap.error("--list requires --data-bin or --wad")
        blob, src = load_data_blob(args.data_bin, args.wad)
        paths = load_paths(args.paths, args.pths, args.ffcs_out)
        try:
            size = len(blob)
            offsets = find_sges_offsets(blob)
            if not offsets:
                print("No sges magic found.", file=sys.stderr)
                return 1
            n = min(len(offsets), len(paths)) if paths else len(offsets)
            for i in range(n):
                off = offsets[i]
                end = offsets[i + 1] if i + 1 < len(offsets) else size
                try:
                    maj, mn, tu, tc = parse_sges_header(blob[off : off + 16])
                except Exception:
                    maj, mn, tu, tc = 0, 0, 0, 0
                pname = paths[i] if i < len(paths) else "?"
                print(f"{i:5d}  0x{off:08x}..0x{end:08x}  v={maj}.{mn}  u={tu:9d}  {pname}")
            return 0
        finally:
            if isinstance(blob, mmap_mod.mmap):
                blob.close()

    if args.out is None:
        ap.error("--out is required unless --list or --bulk-out-dir")

    blob, src = load_data_blob(args.data_bin, args.wad)
    paths = load_paths(args.paths, args.pths, args.ffcs_out)

    try:
        size = len(blob)
        offsets = find_sges_offsets(blob)
        if not offsets:
            print("No sges magic found.", file=sys.stderr)
            return 1

        def resolve_indices() -> list[int]:
            if args.index is not None:
                return [args.index]
            if args.name:
                sub = args.name.lower()
                for i, p in enumerate(paths):
                    if sub in p.lower():
                        return [i]
                raise SystemExit(f"No path containing {args.name!r}")
            if args.regex:
                rx = re.compile(args.regex)
                for i, p in enumerate(paths):
                    if rx.search(p):
                        return [i]
                raise SystemExit("regex match not found")
            if args.all:
                return list(range(min(len(offsets), len(paths) or len(offsets))))
            raise SystemExit("Specify --index, --name, --regex, or --all")

        indices = resolve_indices()

        def extract_one(idx: int) -> tuple[str, bytes]:
            off = offsets[idx]
            block_end = offsets[idx + 1] if idx + 1 < len(offsets) else size
            mx = args.max_bytes if args.max_bytes > 0 else None
            raw_out = decompress_sges_block(blob, off, block_end, max_out=mx)
            label = paths[idx] if idx < len(paths) else f"block_{idx:05d}"
            return label, raw_out

        if len(indices) == 1 and not args.all:
            label, data = extract_one(indices[0])
            args.out.parent.mkdir(parents=True, exist_ok=True)
            args.out.write_bytes(data)
            print(f"Wrote {args.out} ({len(data)} bytes) <- {label}")
            return 0

        args.out.mkdir(parents=True, exist_ok=True)
        manifest: list[dict[str, object]] = []
        for idx in indices:
            label, data = extract_one(idx)
            fname = safe_filename(label)
            if not fname.endswith(".bin"):
                fname += ".bin"
            op = args.out / fname
            op.write_bytes(data)
            manifest.append({"index": idx, "path": label, "file": op.name, "size": len(data)})
            print(f"[{idx}] -> {op.name} ({len(data)} bytes)")

        (args.out / "manifest.json").write_text(json.dumps({"source": str(src), "blocks": manifest}, indent=2), encoding="utf-8")
        return 0
    finally:
        if isinstance(blob, mmap_mod.mmap):
            blob.close()


if __name__ == "__main__":
    raise SystemExit(main())
