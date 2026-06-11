#!/usr/bin/env python3
"""Extract Amazon Pack DLC assets from an Xbox 360 STFS container.

Reads the STFS → parses the DOH (big-endian FFCS) → lists blocks via PTHS →
decompresses each sges block → byte-swaps UCFX from big-endian to little-endian →
runs mesh extraction to produce OBJ + glTF review assets.

Output lands in output/extracted/amazon_dlc/ with the standard review directory
structure so the Three.js viewer picks it up automatically.

Usage:
    .venv/bin/python3 tools/extract_amazon_dlc.py <stfs_path> [--output <dir>] [--max-blocks N]
"""
from __future__ import annotations

import argparse
import json
import struct
import subprocess
import sys
from pathlib import Path

THIS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(THIS_DIR))

from x360_dlc_io import (
    StfsReader,
    decompress_be_sges,
    parse_be_ffcs,
    parse_be_indx,
    parse_be_pths,
)
from ucfx_byteswap_wrapper import byteswap_block_rust
from ucfx_mesh_codec import find_all, CONTAINER_SENTINEL, CHUNK_HDR


SEGS_MAGIC = b"segs"
PAGE_SIZE = 0x8000

# Lowercase container children tags in big-endian (Xbox 360) form.
# byteswap_ucfx_block() handles uppercase UCFX chunk tags but skips
# these lowercase children inside STRM/IBUF containers.
_BE_CHILD_TAGS = {b"ofni": b"info", b"lced": b"decl", b"atad": b"data"}


def _swap_strm_ibuf_for_extraction(data: bytearray) -> dict:
    """Swap STRM/IBUF container children and data bodies for mesh extraction.

    byteswap_ucfx_block() intentionally leaves container-style STRM vertex
    bodies and IBUF index bodies in big-endian (the game engine path in
    dlc_port.py doesn't need host-byte-order vertex data). For mesh_extractor
    to parse vertices as LE f16 and indices as LE u16, we must swap them.

    This function:
      1. Finds all container-style STRM/IBUF (u0 == CONTAINER_SENTINEL)
      2. Swaps their children's row headers (tag + 4×u32)
      3. Computes absolute data body offsets from the enclosing UCFX
      4. Swaps vertex buffer bodies as u16 (correct for f16/snorm16 formats)
      5. Swaps index buffer bodies as u16
    """
    stats = {"strm_swapped": 0, "ibuf_swapped": 0, "vb_bytes": 0, "ib_bytes": 0}

    # byteswap_ucfx_block() only swaps UCFX tag + u0. The u1/u2/u3 fields
    # (at +8/+12/+16) remain BE. u3 is the chunk count needed by
    # iter_ucfx_containers in mesh_extractor.
    for pos in find_all(data, b"UCFX"):
        if pos + 20 <= len(data):
            for hdr_off in (8, 12, 16):
                v = struct.unpack_from(">I", data, pos + hdr_off)[0]
                struct.pack_into("<I", data, pos + hdr_off, v)

    def _find_enclosing_ucfx(pos: int) -> tuple[int, int] | None:
        """Walk backwards to find the UCFX container start and its u0 field."""
        search = pos - 4
        limit = max(0, pos - 0x100000)
        while search >= limit:
            if data[search:search + 4] == b"UCFX":
                u0 = struct.unpack_from("<I", data, search + 4)[0]
                return search, u0
            search -= 1
        return None

    def _process_container(chunk_pos: int, is_strm: bool) -> None:
        n_children = struct.unpack_from("<I", data, chunk_pos + 16)[0]
        if n_children == 0 or n_children > 20:
            return

        enclosing = _find_enclosing_ucfx(chunk_pos)
        if enclosing is None:
            return
        ucfx_start, ucfx_u0 = enclosing

        child_base = chunk_pos + CHUNK_HDR
        data_off = data_len = 0
        decl_len = 0

        for ci in range(n_children):
            cp = child_base + ci * CHUNK_HDR
            if cp + CHUNK_HDR > len(data):
                break

            child_tag = bytes(data[cp:cp + 4])
            if child_tag in _BE_CHILD_TAGS:
                data[cp:cp + 4] = _BE_CHILD_TAGS[child_tag]
                # Swap the 4 u32 header fields from BE to LE
                for field_off in (4, 8, 12, 16):
                    v = struct.unpack_from(">I", data, cp + field_off)[0]
                    struct.pack_into("<I", data, cp + field_off, v)
                child_tag = bytes(data[cp:cp + 4])

            tag_lc = child_tag.lower()
            cu0 = struct.unpack_from("<I", data, cp + 4)[0]
            cu1 = struct.unpack_from("<I", data, cp + 8)[0]

            if tag_lc == b"decl":
                decl_len = cu1
                if decl_len > 0:
                    if ucfx_u0 > 0:
                        abs_off = ucfx_start + ucfx_u0 + cu0
                    else:
                        abs_off = ucfx_start + 8 + cu0
                    end = abs_off + decl_len
                    if 0 <= abs_off and end <= len(data):
                        pos = abs_off
                        while pos + 4 <= end:
                            v = struct.unpack_from(">I", data, pos)[0]
                            struct.pack_into("<I", data, pos, v)
                            pos += 4
            elif tag_lc == b"data":
                data_off = cu0
                data_len = cu1

        if data_len <= 0:
            return

        if ucfx_u0 > 0:
            abs_off = ucfx_start + ucfx_u0 + data_off
        else:
            abs_off = ucfx_start + 8 + data_off
        end = abs_off + data_len

        if abs_off < 0 or end > len(data):
            return

        # Swap body as u16 elements
        pos = abs_off
        while pos + 2 <= end:
            data[pos], data[pos + 1] = data[pos + 1], data[pos]
            pos += 2

        if is_strm:
            stats["strm_swapped"] += 1
            stats["vb_bytes"] += data_len
        else:
            stats["ibuf_swapped"] += 1
            stats["ib_bytes"] += data_len

    for pos in find_all(data, b"STRM"):
        if pos + CHUNK_HDR <= len(data):
            u0 = struct.unpack_from("<I", data, pos + 4)[0]
            if u0 == CONTAINER_SENTINEL:
                _process_container(pos, is_strm=True)

    for pos in find_all(data, b"IBUF"):
        if pos + CHUNK_HDR <= len(data):
            u0 = struct.unpack_from("<I", data, pos + 4)[0]
            if u0 == CONTAINER_SENTINEL:
                _process_container(pos, is_strm=False)

    return stats


def scan_ucfx_chunk_tags(data: bytes) -> list[str]:
    """Quick scan for UCFX chunk tags in a decompressed LE block."""
    tags: list[str] = []
    known = {b"UCFX", b"CHDR", b"COMP", b"GEOM", b"MESH", b"PRMG", b"STRM",
             b"IBUF", b"MTRL", b"FLGS", b"STAT", b"EXEC", b"ENUM", b"FLGT",
             b"INDX", b"NAME", b"BODY", b"BNDS", b"INFO", b"PRMT", b"SWIT",
             b"HIER", b"BINN", b"CSUM"}
    for i in range(0, len(data) - 4, 4):
        tag = data[i:i + 4]
        if tag in known and tag.decode("ascii", errors="replace") not in tags:
            tags.append(tag.decode("ascii", errors="replace"))
    return tags


def main() -> int:
    ap = argparse.ArgumentParser(description="Extract Amazon Pack DLC from STFS container")
    ap.add_argument("stfs_path", type=Path, help="Path to STFS container file")
    ap.add_argument("--output", type=Path, default=Path("output"),
                    help="Output root directory (default: ./output)")
    ap.add_argument("--max-blocks", type=int, default=None,
                    help="Max blocks to extract (default: all)")
    ap.add_argument("--skip-mesh", action="store_true",
                    help="Skip mesh extraction (just decompress + byte-swap)")
    args = ap.parse_args()

    stfs_path = args.stfs_path.resolve()
    if not stfs_path.is_file():
        print(f"Error: STFS file not found: {stfs_path}", file=sys.stderr)
        return 1

    output_root = args.output.resolve()
    dlc_dir = output_root / "extracted" / "amazon_dlc"
    blocks_dir = dlc_dir / "blocks"
    review_dir = output_root / "extracted" / "review" / "batch_amazon_dlc"
    blocks_dir.mkdir(parents=True, exist_ok=True)
    review_dir.mkdir(parents=True, exist_ok=True)

    # ── Step 1: Read STFS container ──────────────────────────────────
    print(f"Reading STFS container: {stfs_path} ({stfs_path.stat().st_size:,} bytes)")
    stfs_data = stfs_path.read_bytes()
    reader = StfsReader(stfs_data)

    print(f"  Table size shift: {reader.table_size_shift}")
    print(f"  File table entries: {len(reader.file_table)}")
    for entry in reader.file_table:
        kind = "DIR " if entry["is_dir"] else "FILE"
        print(f"    {kind} {entry['name']:30s}  size={entry['file_size']:>10,}  "
              f"first_block={entry['first_block']}  alloc={entry['alloc_blocks']}")

    # ── Step 2: Read the DOH file ────────────────────────────────────
    doh_entry = next(
        (e for e in reader.file_table if "doh" in e["name"].lower()), None)
    if doh_entry is None:
        print("Error: No DOH file found in STFS file table", file=sys.stderr)
        return 1

    print(f"\nReading DOH: {doh_entry['name']} ({doh_entry['file_size']:,} bytes)")
    doh = reader.read(0, doh_entry["file_size"])

    # ── Step 3: Parse big-endian FFCS header ─────────────────────────
    version, chunks = parse_be_ffcs(doh)
    print(f"  FFCS version: {version}")
    print(f"  Chunks ({len(chunks)}):")

    indx_offset = None
    indx_count = 0
    pths_offset = None
    pths_count = 0

    for row in chunks:
        print(f"    {row.tag:5s}  offset=0x{row.offset:08X}  meta=0x{row.meta:08X}")
        if row.tag == "INDX":
            indx_offset = row.offset
            indx_count = row.meta
        elif row.tag == "PTHS":
            pths_offset = row.offset
            pths_count = row.meta

    # ── Step 4: Parse INDX entries ───────────────────────────────────
    if indx_offset is None:
        print("Error: No INDX chunk found in FFCS header", file=sys.stderr)
        return 1

    indx_entries = parse_be_indx(doh, indx_offset, indx_count)
    print(f"\n  INDX entries: {len(indx_entries)}")
    for i, ie in enumerate(indx_entries[:5]):
        print(f"    [{i}] page={ie.page_index} flags=0x{ie.flags:04X} "
              f"pages={ie.page_count} offset=0x{ie.file_offset:X}")
    if len(indx_entries) > 5:
        print(f"    ... and {len(indx_entries) - 5} more")

    # ── Step 5: Parse PTHS (block paths) ─────────────────────────────
    paths: list[str] = []
    if pths_offset is not None:
        paths = parse_be_pths(doh, pths_offset, pths_count)
        print(f"\n  PTHS paths: {len(paths)}")
        for i, p in enumerate(paths[:10]):
            print(f"    [{i}] {p}")
        if len(paths) > 10:
            print(f"    ... and {len(paths) - 10} more")

    num_blocks = min(len(indx_entries), len(paths)) if paths else len(indx_entries)
    print(f"\n  Total blocks available: {num_blocks}")

    # ── Step 6: Decompress, byte-swap, and extract each block ────────
    # Each block is at indx.page_index * PAGE_SIZE in the DOH, for
    # indx.page_count * PAGE_SIZE bytes. Blocks start with sges or raw XFCU.
    max_blocks = args.max_blocks or num_blocks
    num_to_process = min(max_blocks, num_blocks)

    block_report: list[dict] = []
    mesh_blocks: list[dict] = []
    glb_count = 0

    print(f"\nProcessing {num_to_process} of {num_blocks} blocks...")
    print("=" * 72)

    for idx in range(num_to_process):
        indx = indx_entries[idx]
        block_offset = indx.file_offset
        block_size = indx.page_count * PAGE_SIZE

        path_name = paths[idx] if idx < len(paths) else f"block_{idx:05d}"
        stem = path_name.replace("\\", "__").replace("/", "__")
        stem = stem.replace(".", "_").rstrip("_")
        if not stem:
            stem = f"block_{idx:05d}"

        print(f"\n[{idx:3d}/{num_to_process}] {path_name}")
        print(f"  DOH offset=0x{block_offset:X}, pages={indx.page_count}, "
              f"size={block_size:,}")

        if block_offset + 4 > len(doh):
            print(f"  SKIP: offset beyond DOH ({len(doh):,} bytes)")
            block_report.append({
                "index": idx, "path": path_name, "status": "beyond_doh",
            })
            continue

        magic = doh[block_offset:block_offset + 4]

        if magic == SEGS_MAGIC:
            # Standard sges-compressed block
            try:
                decompressed = decompress_be_sges(doh, block_offset, block_size)
            except Exception as exc:
                print(f"  DECOMPRESS FAILED: {exc}")
                block_report.append({
                    "index": idx, "path": path_name, "status": "decompress_failed",
                    "error": str(exc),
                })
                continue
        else:
            # Check for raw (uncompressed) XFCU block
            rec_count_be = struct.unpack_from(">I", doh, block_offset)[0]
            header_end = block_offset + 4 + rec_count_be * 16
            first_tag = doh[header_end:header_end + 4] if header_end + 4 <= len(doh) else b""
            if 0 < rec_count_be < 5000 and first_tag == b"XFCU":
                raw_block = doh[block_offset:block_offset + block_size]
                actual_end = len(raw_block)
                while actual_end > 4 and raw_block[actual_end - 1] == 0:
                    actual_end -= 1
                actual_end = (actual_end + 3) & ~3
                decompressed = raw_block[:actual_end]
                print(f"  Raw XFCU (no sges), {len(decompressed):,} bytes")
            else:
                print(f"  SKIP: unknown magic {magic!r}")
                block_report.append({
                    "index": idx, "path": path_name, "status": "unknown_magic",
                    "magic": magic[:4].hex(),
                })
                continue

        print(f"  Decompressed: {len(decompressed):,} bytes")

        if len(decompressed) < 8:
            print(f"  TOO SMALL, skipping")
            block_report.append({
                "index": idx, "path": path_name, "status": "too_small",
                "decompressed_size": len(decompressed),
            })
            continue

        # Byte-swap BE → LE (Rust converter; stats not reported by the Rust path)
        try:
            le_data = byteswap_block_rust(decompressed, validate=False)
            swap_stats = {}
        except Exception as exc:
            print(f"  BYTE-SWAP FAILED: {exc}")
            block_report.append({
                "index": idx, "path": path_name, "status": "swap_failed",
                "error": str(exc), "decompressed_size": len(decompressed),
            })
            continue

        tags_seen = list(swap_stats.get("tags_seen", {}).keys())
        ucfx_count = swap_stats.get("ucfx_found", 0)
        print(f"  Byte-swapped: {ucfx_count} UCFX containers, "
              f"tags: {', '.join(tags_seen) if tags_seen else '(none)'}")

        # Swap STRM/IBUF container children for mesh extraction
        le_arr = bytearray(le_data)
        deep_stats = _swap_strm_ibuf_for_extraction(le_arr)
        le_data = bytes(le_arr)
        if deep_stats["strm_swapped"] or deep_stats["ibuf_swapped"]:
            print(f"  VB/IB swap: {deep_stats['strm_swapped']} STRM "
                  f"({deep_stats['vb_bytes']:,} bytes), "
                  f"{deep_stats['ibuf_swapped']} IBUF "
                  f"({deep_stats['ib_bytes']:,} bytes)")

        # Scan for tags
        all_tags = scan_ucfx_chunk_tags(le_data)

        # Write decompressed block
        block_file = blocks_dir / f"{idx:05d}_{stem}.block.bin"
        block_file.write_bytes(le_data)

        combined_tags = set(all_tags) | set(tags_seen)
        has_geom = "GEOM" in combined_tags
        has_mesh = "MESH" in combined_tags
        has_strm = "STRM" in combined_tags
        has_ibuf = "IBUF" in combined_tags
        has_geometry = has_geom and has_strm

        entry = {
            "index": idx, "path": path_name, "stem": stem,
            "status": "ok",
            "decompressed_size": len(decompressed),
            "ucfx_count": ucfx_count,
            "tags_seen": tags_seen,
            "all_tags": all_tags,
            "has_geometry": has_geometry,
            "block_file": str(block_file.relative_to(output_root)),
        }
        block_report.append(entry)

        if has_geometry and not args.skip_mesh:
            mesh_blocks.append(entry)

    # ── Step 8: Run mesh extraction on geometry blocks ───────────────
    print(f"\n{'=' * 72}")
    print(f"Found {len(mesh_blocks)} blocks with mesh geometry")

    if mesh_blocks and not args.skip_mesh:
        print("Running mesh extraction...")
        for entry in mesh_blocks:
            idx = entry["index"]
            stem = entry["stem"]
            block_file = output_root / entry["block_file"]

            stem_dir = review_dir / stem
            stem_dir.mkdir(parents=True, exist_ok=True)
            submeshes_dir = stem_dir / "submeshes"
            submeshes_dir.mkdir(exist_ok=True)

            out_obj = stem_dir / "mesh.obj"
            print(f"\n  Extracting mesh: [{idx}] {stem}")

            cmd = [
                sys.executable,
                str(THIS_DIR / "mesh_extractor.py"),
                str(block_file),
                "--out", str(out_obj),
                "--format", "gltf",
                "--indices",
                "--per-submesh-obj",
                "--emit-scene-gltf",
                "--lod", "highest-poly-per-bbox",
                "--stem", stem,
            ]

            result = subprocess.run(
                cmd, capture_output=True, text=True,
                cwd=str(THIS_DIR),
            )

            if result.returncode == 0:
                scene_gltf = stem_dir / "mesh_scene.gltf"
                has_scene = scene_gltf.is_file()
                entry["mesh_extracted"] = True
                entry["has_scene_gltf"] = has_scene
                if has_scene:
                    glb_count += 1
                print(f"    OK: {result.stdout.strip().split(chr(10))[-1] if result.stdout.strip() else '(no output)'}")
                if has_scene:
                    print(f"    Scene glTF: {scene_gltf.relative_to(output_root)}")
            else:
                entry["mesh_extracted"] = False
                entry["mesh_error"] = result.stderr.strip()[:500]
                print(f"    MESH EXTRACTION FAILED:")
                for line in result.stderr.strip().split("\n")[:5]:
                    print(f"      {line}")

    # ── Step 9: Write report ─────────────────────────────────────────
    report = {
        "stfs_path": str(stfs_path),
        "total_blocks": num_blocks,
        "blocks_processed": num_to_process,
        "blocks_with_geometry": len(mesh_blocks),
        "scene_gltfs_produced": glb_count,
        "paths_found": len(paths),
        "all_paths": paths,
        "blocks": block_report,
    }
    report_path = dlc_dir / "extraction_report.json"
    report_path.write_text(json.dumps(report, indent=2), encoding="utf-8")

    print(f"\n{'=' * 72}")
    print(f"EXTRACTION COMPLETE")
    print(f"  Blocks processed:  {num_to_process}")
    print(f"  With geometry:     {len(mesh_blocks)}")
    print(f"  Scene glTFs:       {glb_count}")
    print(f"  Report:            {report_path}")
    print(f"  Blocks dir:        {blocks_dir}")
    print(f"  Review dir:        {review_dir}")
    print(f"\n  View with: make viewer")
    print(f"  Assets will appear under 'batch_amazon_dlc' pack in the viewer.")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
