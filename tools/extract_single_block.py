#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Extract and decompress a single FFCS WAD block with automatic scratch cleanup.

Use this instead of bulk ``extract-all`` / ``sges_decompress --bulk-out-dir`` when
probing one block (watermap, road graph, FaceFX, effect blocks, etc.) so disk
use stays bounded.
"""

from __future__ import annotations

import argparse
import json
import mmap as mmap_mod
import re
import shlex
import shutil
import struct
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Sequence

THIS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(THIS_DIR))

from aset_prop_tracer import parse_aset  # noqa: E402
from aset_type_ids import type_id_for_type_hash  # noqa: E402
from ffcs_wad import extract_slice, parse_ffcs  # noqa: E402
from sges_decompress import decompress_sges_block, safe_block_stem  # noqa: E402
from wad_patcher import get_block_boundaries, load_wad_paths  # noqa: E402


def parse_hex(value: str) -> int:
    """Accept ``0xDEADBEEF``, bare hex, or decimal strings."""
    s = value.strip().lower()
    if s.startswith("0x"):
        return int(s, 16)
    if re.fullmatch(r"[0-9a-f]+", s) and any(c in "abcdef" for c in s):
        return int(s, 16)
    return int(s, 10)


def normalize_path_key(path_like: str) -> str:
    s = path_like.strip().replace("\\", "/")
    while s.startswith("./"):
        s = s[2:]
    return s.lower()


@dataclass(frozen=True)
class ResolvedBlock:
    index: int
    path: str
    selector: str


def load_aset_rows(wad: Path) -> list[dict]:
    raw = wad.read_bytes()
    arch = parse_ffcs(wad)
    aset_chunk = next((c for c in arch.chunks if c.tag == "ASET"), None)
    if aset_chunk is None or aset_chunk.size == 0:
        return []
    return parse_aset(extract_slice(raw, aset_chunk))


def _unique_block_indices(rows: Sequence[dict]) -> list[int]:
    out: list[int] = []
    seen: set[int] = set()
    for row in rows:
        idx = int(row["block_index"])
        if idx == 0xFFFF:
            continue
        if idx not in seen:
            seen.add(idx)
            out.append(idx)
    return sorted(out)


def resolve_by_block_index(index: int, paths: list[str]) -> ResolvedBlock:
    if index < 0:
        raise SystemExit(f"--block-index must be >= 0, got {index}")
    if paths and index >= len(paths):
        raise SystemExit(
            f"--block-index {index} out of range (PTHS has {len(paths)} paths)"
        )
    path = paths[index] if index < len(paths) else f"block_{index:05d}"
    return ResolvedBlock(index=index, path=path, selector=f"block-index={index}")


def resolve_by_path(path_query: str, paths: list[str]) -> ResolvedBlock:
    if not paths:
        raise SystemExit("--path requires a WAD with a PTHS chunk")

    key = normalize_path_key(path_query)
    exact = [i for i, p in enumerate(paths) if normalize_path_key(p) == key]
    if len(exact) == 1:
        return ResolvedBlock(index=exact[0], path=paths[exact[0]], selector=f"path={path_query!r}")
    if len(exact) > 1:
        raise SystemExit(f"Multiple exact PTHS matches for {path_query!r}: {exact}")

    partial = [i for i, p in enumerate(paths) if key in normalize_path_key(p)]
    if len(partial) == 1:
        return ResolvedBlock(
            index=partial[0],
            path=paths[partial[0]],
            selector=f"path~={path_query!r}",
        )
    if not partial:
        raise SystemExit(f"No PTHS path matching {path_query!r}")
    sample = [paths[i] for i in partial[:8]]
    raise SystemExit(
        f"Ambiguous path {path_query!r}: {len(partial)} matches "
        f"(first few: {sample!r}). Use --block-index or a more specific --path."
    )


def resolve_by_aset_hash(
    asset_hash: int,
    wad: Path,
    paths: list[str],
    *,
    type_hash: int | None = None,
) -> ResolvedBlock:
    rows = load_aset_rows(wad)
    if not rows:
        raise SystemExit(f"No ASET chunk in {wad}")

    matches = [r for r in rows if int(r["asset_hash"]) == (asset_hash & 0xFFFFFFFF)]
    if type_hash is not None:
        type_id = type_id_for_type_hash(type_hash)
        if type_id is None:
            raise SystemExit(
                f"Unknown --type-hash 0x{type_hash:08X} (not in aset_type_ids registry)"
            )
        matches = [r for r in matches if int(r["type_id"]) == type_id]

    if not matches:
        hint = f" and type_hash=0x{type_hash:08X}" if type_hash is not None else ""
        raise SystemExit(f"No ASET row for asset_hash=0x{asset_hash:08X}{hint}")

    block_indices = _unique_block_indices(matches)
    if len(block_indices) != 1:
        raise SystemExit(
            f"ASET asset_hash=0x{asset_hash:08X} maps to {len(block_indices)} blocks: "
            f"{block_indices}. Pass --type-hash to disambiguate or use --block-index."
        )

    idx = block_indices[0]
    path = paths[idx] if idx < len(paths) else f"block_{idx:05d}"
    return ResolvedBlock(
        index=idx,
        path=path,
        selector=f"aset-hash=0x{asset_hash:08X}",
    )


def resolve_by_type_hash(type_hash: int, wad: Path, paths: list[str]) -> ResolvedBlock:
    type_id = type_id_for_type_hash(type_hash)
    if type_id is None:
        raise SystemExit(
            f"Unknown --type-hash 0x{type_hash:08X} (not in aset_type_ids registry)"
        )

    rows = load_aset_rows(wad)
    if not rows:
        raise SystemExit(f"No ASET chunk in {wad}")

    matches = [r for r in rows if int(r["type_id"]) == type_id]
    block_indices = _unique_block_indices(matches)
    if not block_indices:
        raise SystemExit(f"No ASET rows with type_id={type_id} for type_hash=0x{type_hash:08X}")
    if len(block_indices) != 1:
        preview = block_indices[:12]
        raise SystemExit(
            f"type_hash=0x{type_hash:08X} (type_id={type_id}) spans {len(block_indices)} "
            f"blocks (first: {preview}). Use --path, --block-index, or --aset-hash."
        )

    idx = block_indices[0]
    path = paths[idx] if idx < len(paths) else f"block_{idx:05d}"
    return ResolvedBlock(
        index=idx,
        path=path,
        selector=f"type-hash=0x{type_hash:08X}",
    )


def block_entry_count(decompressed: bytes) -> int | None:
    if len(decompressed) < 4:
        return None
    count = struct.unpack_from("<I", decompressed, 0)[0]
    if count < 1 or count > 50_000:
        return None
    header_end = 4 + count * 16
    if header_end > len(decompressed):
        return None
    return count


def extract_compressed_block(wad: Path, block_index: int) -> bytes:
    arch = parse_ffcs(wad)
    data_chunk = next((c for c in arch.chunks if c.tag == "DATA"), None)
    if data_chunk is None or data_chunk.size == 0:
        raise ValueError(f"No DATA chunk in {wad}")

    with wad.open("rb") as f:
        mm = mmap_mod.mmap(f.fileno(), 0, access=mmap_mod.ACCESS_READ)
        try:
            boundaries = get_block_boundaries(mm, data_chunk.offset, data_chunk.size)
            if block_index >= len(boundaries):
                raise ValueError(
                    f"block_index {block_index} out of range ({len(boundaries)} sges blocks)"
                )
            start, end = boundaries[block_index]
            return bytes(mm[start:end])
        finally:
            mm.close()


def default_scratch_dir(block_index: int, scratch_root: Path | None) -> Path:
    if scratch_root is not None:
        return scratch_root / f"block_{block_index:05d}"
    return Path(tempfile.mkdtemp(prefix=f"mercs2_block_{block_index:05d}_"))


def run_decode_hook(command: str, decompressed_path: Path) -> int:
    if "{bin}" in command or "{path}" in command:
        cmd = command.replace("{bin}", str(decompressed_path)).replace(
            "{path}", str(decompressed_path)
        )
        proc = subprocess.run(cmd, shell=True, check=False)
        return proc.returncode

    argv = shlex.split(command, posix=(sys.platform != "win32"))
    if not argv:
        raise SystemExit("--decode command is empty")
    argv.append(str(decompressed_path))
    proc = subprocess.run(argv, check=False)
    return proc.returncode


def extract_one_block(
    wad: Path,
    resolved: ResolvedBlock,
    *,
    scratch_root: Path | None,
    keep: bool,
    decode_cmd: str | None,
    metadata_path: Path | None,
) -> Path:
    scratch = default_scratch_dir(resolved.index, scratch_root)
    scratch.mkdir(parents=True, exist_ok=True)

    stem = safe_block_stem(resolved.path)
    out_name = f"{resolved.index:05d}_{stem}.block.bin"
    decompressed_path = scratch / out_name

    success = False
    try:
        compressed = extract_compressed_block(wad, resolved.index)
        decompressed = decompress_sges_block(compressed, 0, len(compressed))
        decompressed_path.write_bytes(decompressed)

        meta = {
            "wad": str(wad.resolve()),
            "block_index": resolved.index,
            "path": resolved.path,
            "selector": resolved.selector,
            "compressed_size": len(compressed),
            "decompressed_size": len(decompressed),
            "entry_count": block_entry_count(decompressed),
            "decompressed_file": str(decompressed_path.resolve()),
            "scratch_dir": str(scratch.resolve()),
        }
        meta_file = metadata_path or (scratch / "metadata.json")
        meta_file.parent.mkdir(parents=True, exist_ok=True)
        meta_file.write_text(json.dumps(meta, indent=2), encoding="utf-8")

        if decode_cmd:
            rc = run_decode_hook(decode_cmd, decompressed_path)
            if rc != 0:
                raise SystemExit(f"--decode exited with code {rc}")

        success = True
        if keep:
            print(str(decompressed_path.resolve()))
        return decompressed_path
    finally:
        if not keep and success:
            shutil.rmtree(scratch, ignore_errors=True)


def build_parser() -> argparse.ArgumentParser:
    ap = argparse.ArgumentParser(
        description=(
            "Extract and decompress one sges block from an FFCS .wad file. "
            "Scratch output is removed on success unless --keep is set."
        )
    )
    ap.add_argument("--wad", type=Path, required=True, help="Path to FFCS .wad file")

    sel = ap.add_mutually_exclusive_group(required=True)
    sel.add_argument("--block-index", type=int, help="PTHS / sges block index (0-based)")
    sel.add_argument(
        "--path",
        type=str,
        help='PTHS path (exact or unique substring), e.g. "blocks\\\\VZ\\\\foo.block"',
    )
    sel.add_argument(
        "--type-hash",
        type=str,
        help="UCFX type_hash (hex). Resolves via ASET when it maps to one block.",
    )
    sel.add_argument(
        "--aset-hash",
        type=str,
        help="ASET asset_hash (hex). Combine with --filter-type-hash if ambiguous.",
    )

    ap.add_argument(
        "--filter-type-hash",
        type=str,
        help="Optional UCFX type_hash filter when using --aset-hash",
    )
    ap.add_argument(
        "--scratch-root",
        type=Path,
        default=None,
        help="Persistent scratch parent (default: temp dir; use output/_scratch for review)",
    )
    ap.add_argument(
        "--metadata-out",
        type=Path,
        default=None,
        help="Write metadata JSON here (default: <scratch>/metadata.json)",
    )
    ap.add_argument(
        "--keep",
        action="store_true",
        help="Keep scratch directory and print decompressed .block.bin path",
    )
    ap.add_argument(
        "--decode",
        dest="decode_cmd",
        type=str,
        default=None,
        help=(
            "Run a command after decompression. Use {bin} or {path} placeholder, "
            "or pass the .block.bin path as the final argument."
        ),
    )
    return ap


def main() -> int:
    args = build_parser().parse_args()
    wad: Path = args.wad
    if not wad.is_file():
        raise SystemExit(f"WAD not found: {wad}")

    paths = load_wad_paths(wad)
    filter_type_hash = (
        parse_hex(args.filter_type_hash) if args.filter_type_hash is not None else None
    )

    if args.block_index is not None:
        resolved = resolve_by_block_index(args.block_index, paths)
    elif args.path is not None:
        resolved = resolve_by_path(args.path, paths)
    elif args.aset_hash is not None:
        resolved = resolve_by_aset_hash(
            parse_hex(args.aset_hash),
            wad,
            paths,
            type_hash=filter_type_hash,
        )
    else:
        assert args.type_hash is not None
        resolved = resolve_by_type_hash(parse_hex(args.type_hash), wad, paths)

    extract_one_block(
        wad,
        resolved,
        scratch_root=args.scratch_root,
        keep=args.keep,
        decode_cmd=args.decode_cmd,
        metadata_path=args.metadata_out,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
