#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Stage-1 parity harness for the Rust converter consolidation.

For every DLC block currently routed to the Python byte-swapper (the 158 level
blocks; see tools/dlc_routing_manifest.py), convert the SAME decompressed BE
block through BOTH `byteswap_block_python` and `byteswap_block_rust`, then diff
the LE outputs per ENTRY and locate the first divergence down to the UCFX chunk
tag. Emits a categorized divergence report (verified — not speculation) and
optionally captures (BE, python_LE) goldens for Rust unit tests.

This is the discovery tool + regression oracle for porting the Python ECS-layer
conversion into Rust (plan: so-let-s-put-together-agile-seahorse.md).

Usage:
  python tools/ecs_block_parity.py --x360-rar game-files/<DLC>.rar
  python tools/ecs_block_parity.py --x360-rar ... --capture-goldens 3 \
      --goldens-dir tools/wad_simulator/crates/ucfx_byteswap/tests/fixtures/ecs_parity
"""
from __future__ import annotations

import argparse
import json
import struct
import sys
import tempfile
from collections import Counter, defaultdict
from pathlib import Path

THIS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(THIS_DIR))

from x360_dlc_io import (  # noqa: E402
    extract_stfs_from_rar,
    parse_be_ffcs,
    parse_be_indx,
    parse_be_pths,
)
from ucfx_byteswap_wrapper import byteswap_block_python, byteswap_block_rust  # noqa: E402
from dlc_routing_manifest import _decompress_block  # noqa: E402
from dlc_port import (  # noqa: E402
    PAGE_SIZE,
    _path_force_python_ecs,
)
import dlc_routing_manifest as drm  # noqa: E402


def _parse_entries(le_block: bytes):
    """Parse a decompressed LE block's entry table.

    Returns dict {asset_hash: (type_hash, body_bytes)} or None if malformed.
    Entry table: [u32 count][count * (u32 hash, u32 type_hash, u32 offset, u32 size)].
    """
    if len(le_block) < 4:
        return None
    n = struct.unpack_from("<I", le_block, 0)[0]
    header_end = 4 + n * 16
    if n == 0 or n > 50_000 or header_end > len(le_block):
        return None
    out = {}
    for i in range(n):
        h, th, off, size = struct.unpack_from("<IIII", le_block, 4 + i * 16)
        # `off` is relative to the end of the entry table (the data region),
        # NOT the block start. Verified: single-entry block -> body at offset 20.
        body_start = header_end + off
        if body_start + size > len(le_block):
            return None
        out[h] = (th, le_block[body_start : body_start + size])
    return out


def _parse_entries_be(be_block: bytes):
    """Parse a decompressed BE block's entry table -> {hash: be_body_bytes}."""
    if len(be_block) < 4:
        return {}
    n = struct.unpack_from(">I", be_block, 0)[0]
    he = 4 + n * 16
    if n == 0 or n > 50_000 or he > len(be_block):
        return {}
    out = {}
    for i in range(n):
        h, _th, off, size = struct.unpack_from(">IIII", be_block, 4 + i * 16)
        if he + off + size <= len(be_block):
            out[h] = be_block[he + off : he + off + size]
    return out


def _chunk_tag_at(container: bytes, local_off: int) -> str:
    """Given a UCFX container body and a byte offset into it, return the chunk
    tag whose body contains that offset (best-effort), else '<header/desc>'."""
    if len(container) < 20 or container[:4] not in (b"UCFX", b"XFCU"):
        return "<not-ucfx>"
    is_be = container[:4] == b"XFCU"
    rd = (lambda o: struct.unpack_from(">I", container, o)[0]) if is_be else (
        lambda o: struct.unpack_from("<I", container, o)[0])
    try:
        data_area = rd(4)
        n_desc = rd(16)
    except struct.error:
        return "<bad-hdr>"
    if n_desc == 0 or n_desc > 10_000:
        return "<bad-ndesc>"
    data_start = data_area if data_area > 0 else 20 + n_desc * 20
    if local_off < data_start:
        return "<header/desc-table>"
    for i in range(n_desc):
        ro = 20 + i * 20
        if ro + 20 > len(container):
            break
        tag = container[ro : ro + 4]
        if is_be:
            tag = tag[::-1]
        u0 = rd(ro + 4)
        if u0 == 0xFFFFFFFF:
            continue
        bsize = rd(ro + 8)
        bstart = (data_area + u0) if data_area > 0 else (8 + u0)
        if bstart <= local_off < bstart + bsize:
            try:
                return tag.decode("ascii")
            except UnicodeDecodeError:
                return tag.hex()
    return "<gap>"


def _first_diff(a: bytes, b: bytes) -> int:
    n = min(len(a), len(b))
    for i in range(n):
        if a[i] != b[i]:
            return i
    return n  # one is a prefix of the other


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--x360-rar", type=Path, required=True)
    ap.add_argument("--manifest", type=Path,
                    default=Path("output/analysis/dlc_routing_manifest.json"))
    ap.add_argument("--out", type=Path,
                    default=Path("output/analysis/ecs_block_parity.json"))
    ap.add_argument("--capture-goldens", type=int, default=0,
                    help="capture (BE, python_LE) for the first N diverging blocks per category")
    ap.add_argument("--goldens-dir", type=Path,
                    default=Path("tools/wad_simulator/crates/ucfx_byteswap/tests/fixtures/ecs_parity"))
    args = ap.parse_args()

    # Determine the python-routed block set (prefer manifest; else recompute).
    py_blocks: set[int] = set()
    if args.manifest.exists():
        for e in json.loads(args.manifest.read_text(encoding="utf-8")):
            if e["route"] == "python":
                py_blocks.add(int(e["block"]))
        print(f"manifest: {len(py_blocks)} python-routed blocks")

    work = Path(tempfile.mkdtemp(prefix="ecs_parity_"))
    reader = extract_stfs_from_rar(args.x360_rar, work)
    doh_entry = next((e for e in reader.file_table if "doh" in e["name"].lower()), None)
    if doh_entry is None:
        print("ERROR: no DOH in STFS", file=sys.stderr)
        return 1
    doh = reader.read(0, doh_entry["file_size"])
    _n, rows = parse_be_ffcs(doh)
    by = {r.tag: r for r in rows}
    indx = parse_be_indx(doh, by["INDX"].offset, by["INDX"].meta)
    paths = parse_be_pths(doh, by["PTHS"].offset, by["PTHS"].meta)

    if not py_blocks:
        # Recompute routing if manifest absent.
        for blk_idx, ie in enumerate(indx):
            path = paths[blk_idx] if blk_idx < len(paths) else ""
            off, size = ie.file_offset, ie.page_count * PAGE_SIZE
            if off + 4 > len(doh):
                continue
            dec = _decompress_block(bytes(doh[off:off + size]))
            if dec is None:
                continue
            if _path_force_python_ecs(path) or drm._ecs_trigger(dec) is not None:
                py_blocks.add(blk_idx)
        print(f"recomputed: {len(py_blocks)} python-routed blocks")

    # category key -> count; and per-category sample of details
    cat_counts: Counter = Counter()
    cat_examples: dict = defaultdict(list)
    per_block = []
    blocks_identical = 0
    blocks_diverged = 0
    py_raised = 0
    rust_raised = 0
    captured: Counter = Counter()
    if args.capture_goldens:
        args.goldens_dir.mkdir(parents=True, exist_ok=True)

    for blk_idx in sorted(py_blocks):
        ie = indx[blk_idx]
        path = paths[blk_idx] if blk_idx < len(paths) else f"block_{blk_idx:05d}"
        off, size = ie.file_offset, ie.page_count * PAGE_SIZE
        be = _decompress_block(bytes(doh[off:off + size]))
        if be is None:
            continue
        try:
            py_le = byteswap_block_python(be, permissive=False)
        except Exception as e:  # noqa: BLE001
            py_raised += 1
            per_block.append({"block": blk_idx, "path": path, "py_error": str(e)[:200]})
            continue
        try:
            rust_le = byteswap_block_rust(be, validate=False)
        except Exception as e:  # noqa: BLE001
            rust_raised += 1
            per_block.append({"block": blk_idx, "path": path, "rust_error": str(e)[:200]})
            continue

        pe = _parse_entries(py_le)
        re_ = _parse_entries(rust_le)
        be_bodies = _parse_entries_be(be)
        if pe is None or re_ is None:
            cat_counts["<unparseable-entry-table>"] += 1
            continue

        block_divs = []
        for h, (th, pbody) in pe.items():
            if h not in re_:
                cat_counts[f"entry-missing-in-rust type=0x{th:08X}"] += 1
                continue
            _rth, rbody = re_[h]
            if pbody == rbody:
                continue
            size_eq = len(pbody) == len(rbody)
            off_d = _first_diff(pbody, rbody)
            tag = _chunk_tag_at(pbody, off_d)
            key = f"type=0x{th:08X} chunk={tag} {'sizeEQ' if size_eq else 'sizeDIFF'}"
            cat_counts[key] += 1
            block_divs.append({
                "asset": f"0x{h:08X}", "type": f"0x{th:08X}", "chunk": tag,
                "first_diff": off_d, "py_len": len(pbody), "rust_len": len(rbody),
            })
            if len(cat_examples[key]) < 5:
                bbody = be_bodies.get(h, b"")
                lo = max(0, off_d - 8)
                hi = off_d + 24
                cat_examples[key].append(
                    {"block": blk_idx, "path": path, "asset": f"0x{h:08X}",
                     "first_diff": off_d, "py_len": len(pbody), "rust_len": len(rbody),
                     "be_win": bbody[lo:hi].hex() if bbody else "",
                     "py_win": pbody[lo:hi].hex(), "rust_win": rbody[lo:hi].hex(),
                     "win_lo": lo})
            if args.capture_goldens and captured[key] < args.capture_goldens:
                captured[key] += 1
                stem = f"blk{blk_idx:04d}_{h:08X}"
                (args.goldens_dir / f"{stem}.be.bin").write_bytes(be)
                (args.goldens_dir / f"{stem}.py_le.bin").write_bytes(py_le)

        if block_divs:
            blocks_diverged += 1
            per_block.append({"block": blk_idx, "path": path, "divergences": block_divs})
        else:
            blocks_identical += 1

    report = {
        "python_routed_blocks": len(py_blocks),
        "blocks_identical": blocks_identical,
        "blocks_diverged": blocks_diverged,
        "python_raised": py_raised,
        "rust_raised": rust_raised,
        "categories": dict(cat_counts.most_common()),
        "category_examples": {k: cat_examples[k] for k in cat_counts},
        "per_block": per_block,
    }
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(report, indent=1), encoding="utf-8")

    print(f"\n=== ECS block parity (Rust vs Python) over {len(py_blocks)} blocks ===")
    print(f"  identical blocks : {blocks_identical}")
    print(f"  diverged blocks  : {blocks_diverged}")
    print(f"  python raised    : {py_raised}")
    print(f"  rust raised      : {rust_raised}")
    print(f"\n  divergence categories (entry-instances):")
    for k, c in cat_counts.most_common():
        print(f"    {c:5d}  {k}")
    print(f"\n  report -> {args.out}")
    if args.capture_goldens:
        print(f"  goldens -> {args.goldens_dir} ({sum(captured.values())} pairs)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
