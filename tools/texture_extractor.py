#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Extract DDS from Mercenaries 2 decompressed blobs (UCFX texture envelopes + embedded DDS).

When a ``--texture-index`` is supplied (from ``texture_streaming_index.py``),
textures whose mip tails live in this block are upgraded to full-resolution by
pulling higher-resolution mip levels from other blocks across the WAD.
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import struct
import subprocess
import sys
from pathlib import Path

CHUNK_HDR = 20


def find_all(data: bytes, needle: bytes) -> list[int]:
    out: list[int] = []
    start = 0
    while True:
        i = data.find(needle, start)
        if i < 0:
            break
        out.append(i)
        start = i + 1
    return out


def dxt_payload_bytes(width: int, height: int, fourcc: bytes) -> int:
    nb = ((width + 3) // 4) * ((height + 3) // 4)
    return nb * (8 if fourcc == b"DXT1" else 16)


def mip_sizes_chain(width: int, height: int, fourcc: bytes, mip_count: int) -> list[int]:
    """Byte size of each mip level (0 = full res) up to mip_count-1."""
    out: list[int] = []
    for m in range(mip_count):
        w = max(width >> m, 4)
        h = max(height >> m, 4)
        out.append(dxt_payload_bytes(w, h, fourcc))
    return out


def find_mip_tail_start(sizes: list[int], body_len: int) -> int | None:
    """Index of first mip included in BODY when BODY holds a suffix of the mip chain."""
    for start in range(len(sizes)):
        if sum(sizes[start:]) == body_len:
            return start
    return None


def safe_tex_stem(name: str, index: int) -> str:
    s = name.strip().rstrip("\x00") or f"tex_{index:03d}"
    s = re.sub(r"[^\w.\-]+", "_", s, flags=re.ASCII)
    return s[:120] if len(s) > 120 else s


def read_chunk_header(data: bytes, pos: int) -> tuple[bytes, tuple[int, int, int, int]]:
    tag = data[pos : pos + 4]
    u0, u1, u2, u3 = struct.unpack_from("<IIII", data, pos + 4)
    return tag, (u0, u1, u2, u3)


def maybe_untile_xbox_texture(info: bytes, body: bytes) -> tuple[bytes, bytes]:
    """If (info, body) is a raw Xbox 360 texture, return PC (info, body).

    PC textures carry an ASCII FourCC at INFO[14:18] and are returned
    unchanged. Xbox textures carry a packed GPU format word there; for full
    (non-streamed) DXT entries we untile the body to PC-linear and rebuild the
    INFO via the shared codec. Streamed stubs / non-DXT / failures pass through
    untouched so the existing mip-assembly path still applies.
    """
    if len(info) < 18 or info[14:18] in (b"DXT1", b"DXT3", b"DXT5"):
        return info, body
    try:
        import xbox_texture_codec as texcodec
        geom = texcodec.texture_geometry(info)
        if geom is None:
            return info, body
        fourcc, w, h, mips = geom
        if len(body) < texcodec.tiled_body_size(w, h, fourcc, mips):
            return info, body  # streamed stub
        return texcodec.convert_texture_chunks(info, body)
    except Exception:
        return info, body


def parse_ucfx_texture_info(info: bytes) -> tuple[int, int, int, bytes, int] | None:
    """Return width, height, mip_count, fourcc, total_size or None."""
    if len(info) < 26:
        return None
    w, h = struct.unpack_from("<HH", info, 0)
    mip_count = struct.unpack_from("<H", info, 6)[0]
    fourcc = info[14:18]
    if fourcc not in (b"DXT1", b"DXT3", b"DXT5"):
        return None
    total_size = struct.unpack_from("<I", info, 22)[0]
    if w < 1 or w > 16384 or h < 1 or h > 16384 or mip_count < 1 or mip_count > 16:
        return None
    return int(w), int(h), int(mip_count), fourcc, int(total_size)


def build_dds_dxt_mip_chain(top_w: int, top_h: int, fourcc: bytes, mip_levels: int, payload: bytes) -> bytes:
    """DDS header + payload for a DXTn texture with mip_levels (top mip = top_w x top_h)."""
    if mip_levels < 1:
        mip_levels = 1
    linear0 = dxt_payload_bytes(top_w, top_h, fourcc)
    flags = 0x1 | 0x2 | 0x4 | 0x1000 | 0x80000  # CAPS HEIGHT WIDTH PIXELFORMAT LINEARSIZE
    if mip_levels > 1:
        flags |= 0x20000  # MIPMAPCOUNT

    reserved = struct.pack("<11I", *([0] * 11))
    pixfmt = struct.pack("<I", 32)
    pixfmt += struct.pack("<I", 0x4)
    pixfmt += fourcc.ljust(4, b"\x00")[:4]
    pixfmt += struct.pack("<5I", 0, 0, 0, 0, 0)
    assert len(pixfmt) == 32

    caps0 = 0x1000  # TEXTURE
    if mip_levels > 1:
        caps0 |= 0x8 | 0x400000  # COMPLEX | MIPMAP
    caps = struct.pack("<4I", caps0, 0, 0, 0)
    reserved2 = struct.pack("<I", 0)

    head = (
        b"DDS "
        + struct.pack("<I", 124)
        + struct.pack("<I", flags)
        + struct.pack("<I", top_h)
        + struct.pack("<I", top_w)
        + struct.pack("<I", linear0)
        + struct.pack("<I", 0)
        + struct.pack("<I", mip_levels)
        + reserved
        + pixfmt
        + caps
        + reserved2
    )
    assert len(head) == 128
    return head + payload


def _read_ucfx_body(block_path: str, entry_offset: int, entry_size: int) -> bytes:
    """Read the raw BODY payload from a UCFX container inside a block file."""
    with open(block_path, "rb") as f:
        f.seek(entry_offset)
        chunk = f.read(entry_size)
    if len(chunk) < CHUNK_HDR + CHUNK_HDR or chunk[:4] != b"UCFX":
        return b""
    u0 = struct.unpack_from("<I", chunk, 4)[0]
    _u1, _u2, u3 = struct.unpack_from("<III", chunk, 8)
    data_base = int(u0)
    for ci in range(min(int(u3), 16)):
        cpos = CHUNK_HDR + ci * CHUNK_HDR
        if cpos + CHUNK_HDR > len(chunk):
            break
        tag = chunk[cpos : cpos + 4]
        cu0 = struct.unpack_from("<I", chunk, cpos + 4)[0]
        cu1 = struct.unpack_from("<I", chunk, cpos + 8)[0]
        if tag == b"BODY" and cu1 > 0:
            start = data_base + int(cu0)
            end = start + int(cu1)
            if end <= len(chunk):
                return chunk[start:end]
    return b""


def _classify_mip_level(
    body_len: int,
    sizes: list[int],
) -> int | None:
    """Return the single mip level whose size matches ``body_len``, or None."""
    for m, sz in enumerate(sizes):
        if sz == body_len:
            return m
    return None


def _classify_mip_range(
    body_len: int,
    sizes: list[int],
) -> tuple[int, int] | None:
    """Return ``(start_mip, end_mip_exclusive)`` for a contiguous sub-chain."""
    for start in range(len(sizes)):
        acc = 0
        for end in range(start, len(sizes)):
            acc += sizes[end]
            if acc == body_len:
                return start, end + 1
    return None


def _assemble_full_chain(
    w: int,
    h: int,
    fourcc: bytes,
    mip_count: int,
    local_body: bytes,
    local_start_mip: int,
    asset_hash: int,
    texture_index: dict[int, list[dict[str, object]]],
) -> tuple[bytes, int, int, int] | None:
    """Try to assemble a fuller mip chain from cross-block chunks.

    Returns ``(payload, top_w, top_h, mip_levels)`` or ``None`` on failure.
    """
    chunks_info = texture_index.get(asset_hash)
    if not chunks_info or len(chunks_info) < 2:
        return None

    sizes = mip_sizes_chain(w, h, fourcc, mip_count)

    # Collect body data from every chunk for this hash.
    # Each chunk covers a contiguous range of mip levels.
    # mip_slots[m] = raw bytes for mip level m
    mip_slots: dict[int, bytes] = {}

    # Seed with local body
    for m in range(local_start_mip, mip_count):
        offset_in_body = sum(sizes[local_start_mip:m])
        mip_bytes = local_body[offset_in_body : offset_in_body + sizes[m]]
        if len(mip_bytes) == sizes[m]:
            mip_slots[m] = mip_bytes

    # Pull from cross-block chunks
    for ci in chunks_info:
        block_path = ci["block"]
        entry_offset = ci["body_offset"]
        entry_size = ci["size"]

        body = _read_ucfx_body(block_path, entry_offset, entry_size)
        if not body:
            continue

        body_len = len(body)

        # Already have this data from local
        if body_len == len(local_body) and body == local_body:
            continue

        # Try single-mip match
        single = _classify_mip_level(body_len, sizes)
        if single is not None:
            if single not in mip_slots:
                mip_slots[single] = body
            continue

        # Try contiguous sub-chain match
        rng = _classify_mip_range(body_len, sizes)
        if rng is not None:
            start, end = rng
            offset = 0
            for m in range(start, end):
                mip_data = body[offset : offset + sizes[m]]
                if len(mip_data) == sizes[m] and m not in mip_slots:
                    mip_slots[m] = mip_data
                offset += sizes[m]
            continue

    if not mip_slots:
        return None

    best_start = min(mip_slots.keys())
    if best_start >= local_start_mip:
        return None  # no improvement

    # Build contiguous payload from best_start through last available
    payload = bytearray()
    n_mips = 0
    for m in range(best_start, mip_count):
        if m not in mip_slots:
            break
        payload.extend(mip_slots[m])
        n_mips += 1

    if n_mips <= (mip_count - local_start_mip):
        return None  # no improvement

    top_w = max(w >> best_start, 4)
    top_h = max(h >> best_start, 4)
    return bytes(payload), top_w, top_h, n_mips


def extract_ucfx_textures(
    data: bytes,
    texture_index: dict[int, list[dict[str, object]]] | None = None,
) -> list[dict[str, object]]:
    """Walk UCFX NAME/INFO/BODY triples that describe DXT textures.

    When *texture_index* is provided, each texture's mip chain is upgraded
    by pulling higher-resolution mip levels from cross-block streaming chunks.
    """
    # Build a map of UCFX offset → block-header asset_hash so we can look up
    # the streaming index for each texture found inside the block.
    from texture_streaming_index import iter_block_entries

    ucfx_offset_to_hash: dict[int, int] = {}
    if texture_index is not None:
        block_entries = iter_block_entries(data)
        for asset_hash, type_hash, body_offset, size in block_entries:
            if body_offset < len(data) and data[body_offset : body_offset + 4] == b"UCFX":
                ucfx_offset_to_hash[body_offset] = asset_hash

    out: list[dict[str, object]] = []
    for uoff in find_all(data, b"UCFX"):
        if uoff + CHUNK_HDR + 16 > len(data):
            continue
        u0, _u1, _u2, u3 = struct.unpack_from("<IIII", data, uoff + 4)
        if u3 < 3 or u3 > 16:
            continue
        data_base = uoff + int(u0)
        if data_base + 8 > len(data) or data_base < 0:
            continue

        name = ""
        info_off = info_len = -1
        body_off = body_len = -1
        for ci in range(int(u3)):
            cpos = uoff + CHUNK_HDR + ci * CHUNK_HDR
            if cpos + CHUNK_HDR > len(data):
                break
            tag, u = read_chunk_header(data, cpos)
            if tag == b"NAME":
                try:
                    raw = data[data_base + u[0] : data_base + u[0] + min(u[1], 256)]
                    name = raw.split(b"\x00", 1)[0].decode("ascii", errors="replace")
                except Exception:
                    name = ""
            elif tag == b"INFO":
                info_off, info_len = int(u[0]), int(u[1])
            elif tag == b"BODY":
                body_off, body_len = int(u[0]), int(u[1])

        if info_off < 0 or body_off < 0 or info_len <= 0 or body_len <= 0:
            continue
        ip = data_base + info_off
        bp = data_base + body_off
        if ip + info_len > len(data) or bp + body_len > len(data):
            continue
        info = data[ip : ip + info_len]
        body = data[bp : bp + body_len]
        info, body = maybe_untile_xbox_texture(info, body)
        body_len = len(body)
        parsed = parse_ucfx_texture_info(info)
        if not parsed:
            continue
        w, h, mip_count, fourcc, total_size = parsed
        sizes = mip_sizes_chain(w, h, fourcc, mip_count)
        chain_sum = sum(sizes)
        if total_size > 0 and chain_sum != total_size:
            pass

        start_mip: int | None = find_mip_tail_start(sizes, body_len)
        mip_in_file: int
        tw: int
        th: int

        if start_mip is not None:
            mip_in_file = mip_count - start_mip
            tw = max(w >> start_mip, 4)
            th = max(h >> start_mip, 4)
        elif body_len == chain_sum:
            start_mip = 0
            mip_in_file = mip_count
            tw, th = w, h
        else:
            single_m: int | None = None
            for m in range(mip_count):
                mw = max(w >> m, 4)
                mh = max(h >> m, 4)
                if dxt_payload_bytes(mw, mh, fourcc) == body_len:
                    single_m = m
                    break
            if single_m is None:
                out.append(
                    {
                        "kind": "ucfx_texture_skip",
                        "ucfx_offset": uoff,
                        "name": name,
                        "note": f"BODY len {body_len} does not match mip tail or single mip",
                        "width": w,
                        "height": h,
                        "fourcc": fourcc.decode("ascii"),
                    }
                )
                continue
            start_mip = single_m
            mip_in_file = 1
            tw = max(w >> single_m, 4)
            th = max(h >> single_m, 4)

        # Try cross-block mip assembly
        asset_hash = ucfx_offset_to_hash.get(uoff)
        assembled = None
        if asset_hash is not None and texture_index is not None and start_mip > 0:
            assembled = _assemble_full_chain(
                w, h, fourcc, mip_count, body, start_mip,
                asset_hash, texture_index,
            )

        if assembled is not None:
            full_payload, tw, th, mip_in_file = assembled
            dds_bytes = build_dds_dxt_mip_chain(tw, th, fourcc, mip_in_file, full_payload)
            start_mip = 0
            for m in range(mip_count):
                if max(w >> m, 4) == tw:
                    start_mip = m
                    break
        else:
            dds_bytes = build_dds_dxt_mip_chain(tw, th, fourcc, mip_in_file, body)

        out.append(
            {
                "kind": "ucfx_texture",
                "ucfx_offset": uoff,
                "name": name,
                "width": tw,
                "height": th,
                "fourcc": fourcc.decode("ascii"),
                "mip_levels_in_file": mip_in_file,
                "mip_start_logical": int(start_mip),
                "logical_width": w,
                "logical_height": h,
                "body_len": len(dds_bytes) - 128,
                "dds_bytes": dds_bytes,
            }
        )
    return out


def chunk_bounds_after_dds_tags(data: bytes, off: int) -> tuple[int, int]:
    end = len(data)
    for tag in (b"DDS ", b"DXT1", b"DXT3", b"DXT5", b"DX10"):
        p = data.find(tag, off + 16)
        if p >= 0:
            end = min(end, p)
    return off, end


def maybe_convert_png(dds_path: Path, png_path: Path) -> bool:
    ffmpeg = shutil.which("ffmpeg")
    if not ffmpeg:
        return False
    try:
        subprocess.run(
            [ffmpeg, "-y", "-hide_banner", "-loglevel", "error", "-i", str(dds_path), str(png_path)],
            check=True,
            capture_output=True,
        )
        return png_path.is_file() and png_path.stat().st_size > 0
    except (subprocess.CalledProcessError, OSError):
        return False


def extract_shared_texture(
    tex_hash: int,
    tex_name: str,
    texture_index: dict[int, list[dict[str, object]]],
    out_dir: Path,
    png: bool = False,
) -> dict[str, object] | None:
    """Extract a single texture by hash from cross-block sources.

    Finds the INFO-bearing container for this hash, extracts it with full mip
    assembly, writes to out_dir, and returns a manifest entry or None.
    """
    chunks_info = texture_index.get(tex_hash, [])
    if not chunks_info:
        return None

    # Find the chunk that has INFO+NAME (largest container, or the one with NAME)
    best_block = None
    best_data = None
    for ci in chunks_info:
        block_path = ci["block"]
        entry_offset = ci["body_offset"]
        entry_size = ci["size"]
        try:
            with open(block_path, "rb") as f:
                f.seek(entry_offset)
                chunk = f.read(entry_size)
        except OSError:
            continue
        if len(chunk) < CHUNK_HDR * 2 or chunk[:4] != b"UCFX":
            continue
        u3 = struct.unpack_from("<I", chunk, 16)[0]
        has_info = False
        for i in range(min(int(u3), 16)):
            cp = CHUNK_HDR + i * CHUNK_HDR
            if cp + CHUNK_HDR > len(chunk):
                break
            if chunk[cp : cp + 4] == b"INFO":
                has_info = True
                break
        if has_info:
            best_block = block_path
            best_data = chunk
            break

    if best_data is None or best_block is None:
        return None

    # Run the UCFX texture extraction on this chunk
    entries = extract_ucfx_textures(best_data, texture_index=texture_index)
    for ent in entries:
        if "dds_bytes" not in ent:
            continue
        dds_bytes = ent["dds_bytes"]
        assert isinstance(dds_bytes, bytes)
        stem = safe_tex_stem(tex_name, 0)
        fn = out_dir / f"{stem}.dds"
        fn.write_bytes(dds_bytes)
        entry: dict[str, object] = {
            "file": fn.name,
            "kind": "shared_texture",
            "width": ent["width"],
            "height": ent["height"],
            "fourcc": ent["fourcc"],
            "name": tex_name,
            "mip_levels_in_file": ent.get("mip_levels_in_file", 1),
            "mip_start_logical": ent.get("mip_start_logical", 0),
        }
        if png:
            png_fn = fn.with_suffix(".png")
            if maybe_convert_png(fn, png_fn):
                entry["png"] = png_fn.name
        return entry
    return None


def parse_embedded_dds(data: bytes, off: int) -> tuple[int, int, bytes, int] | None:
    if data[off : off + 4] != b"DDS ":
        return None
    height = struct.unpack_from("<I", data, off + 12)[0]
    width = struct.unpack_from("<I", data, off + 16)[0]
    linear = struct.unpack_from("<I", data, off + 20)[0]
    fourcc = data[off + 84 : off + 88]
    if fourcc not in (b"DXT1", b"DXT3", b"DXT5", b"DX10"):
        return None
    payload_len = dxt_payload_bytes(width, height, fourcc)
    total = 128 + payload_len
    return width, height, fourcc, total


def main() -> int:
    ap = argparse.ArgumentParser(description="Mercenaries 2 texture extraction")
    ap.add_argument("blob", type=Path)
    ap.add_argument("--out-dir", type=Path, required=True)
    ap.add_argument("--sizes", default="512,256,128,64", help="Square sizes for legacy raw DXT guess")
    ap.add_argument("--png", action="store_true", help="Also emit PNG via ffmpeg (if installed)")
    ap.add_argument("--stem", default="", help="Source stem for texture_manifest association")
    ap.add_argument(
        "--texture-index",
        type=Path,
        default=None,
        help="Path to texture_index.json for cross-block mip assembly",
    )
    ap.add_argument(
        "--shared-textures",
        type=Path,
        default=None,
        help="JSON file listing shared textures to extract from other blocks [{name, hash}, ...]",
    )
    ap.add_argument(
        "--legacy-raw-dxt",
        action="store_true",
        help="Also scan for standalone DXT FourCC bytes (noisy; off by default)",
    )
    args = ap.parse_args()

    data = args.blob.read_bytes()
    args.out_dir.mkdir(parents=True, exist_ok=True)
    manifest: list[dict[str, object]] = []
    n = 0

    # Load cross-block streaming index if provided
    tex_index: dict[int, list[dict[str, object]]] | None = None
    if args.texture_index and args.texture_index.is_file():
        from texture_streaming_index import load_index
        tex_index = load_index(args.texture_index)

    # 1) UCFX texture envelopes (primary)
    ucfx_entries = extract_ucfx_textures(data, texture_index=tex_index)
    name_counts: dict[str, int] = {}
    for ent in ucfx_entries:
        if "dds_bytes" not in ent:
            manifest.append({k: v for k, v in ent.items() if k != "dds_bytes"})
            continue
        dds_bytes = ent["dds_bytes"]
        assert isinstance(dds_bytes, bytes)
        stem = safe_tex_stem(str(ent.get("name", "")), n)
        name_counts[stem] = name_counts.get(stem, 0) + 1
        if name_counts[stem] > 1:
            stem = f"{stem}_{name_counts[stem]}"
        fn = args.out_dir / f"{stem}.dds"
        fn.write_bytes(dds_bytes)
        uoff = int(ent["ucfx_offset"])
        entry: dict[str, object] = {
            "file": fn.name,
            "kind": "ucfx_texture",
            "offset": uoff,
            "width": ent["width"],
            "height": ent["height"],
            "fourcc": ent["fourcc"],
            "name": ent.get("name", ""),
            "mip_levels_in_file": ent.get("mip_levels_in_file", 1),
            "mip_start_logical": ent.get("mip_start_logical", 0),
        }
        if args.png:
            png_fn = fn.with_suffix(".png")
            if maybe_convert_png(fn, png_fn):
                entry["png"] = png_fn.name
        manifest.append(entry)
        n += 1

    # 2) Embedded DDS files (legacy blobs)
    for off in find_all(data, b"DDS "):
        parsed = parse_embedded_dds(data, off)
        if parsed is None:
            continue
        w, h, fourcc, total = parsed
        end = min(len(data), off + total)
        blob = data[off:end]
        fn = args.out_dir / f"embedded_{n:03d}.dds"
        fn.write_bytes(blob)
        entry = {"file": fn.name, "kind": "dds_embedded", "offset": off, "width": w, "height": h, "fourcc": fourcc.decode("ascii")}
        if args.png:
            png_fn = args.out_dir / f"embedded_{n:03d}.png"
            if maybe_convert_png(fn, png_fn):
                entry["png"] = png_fn.name
        manifest.append(entry)
        n += 1

    sizes = [int(x.strip()) for x in args.sizes.split(",") if x.strip()]
    seen = {m["offset"] for m in manifest if "offset" in m}

    if args.legacy_raw_dxt:
        for fourcc, label in ((b"DXT1", "DXT1"), (b"DXT3", "DXT3"), (b"DXT5", "DXT5")):
            for off in find_all(data, fourcc):
                if any(abs(off - s) < 128 for s in seen):
                    continue
                _, bound_end = chunk_bounds_after_dds_tags(data, off)
                placed = False
                for w in sizes:
                    h = w
                    ln = dxt_payload_bytes(w, h, fourcc)
                    if off + ln > bound_end or off + ln > len(data):
                        continue
                    head = build_dds_dxt_mip_chain(w, h, fourcc, 1, b"")[:128]
                    fn = args.out_dir / f"raw_{label}_{n:03d}_{w}x{h}.dds"
                    fn.write_bytes(head + data[off : off + ln])
                    entry = {"file": fn.name, "kind": "raw_dxt_guess", "offset": off, "width": w, "height": h, "fourcc": label}
                    if args.png:
                        png_fn = args.out_dir / f"raw_{label}_{n:03d}_{w}x{h}.png"
                        if maybe_convert_png(fn, png_fn):
                            entry["png"] = png_fn.name
                    manifest.append(entry)
                    n += 1
                    placed = True
                    break
                if not placed:
                    fn = args.out_dir / f"raw_{label}_{n:03d}_slice.bin"
                    fn.write_bytes(data[off : min(off + 4096, bound_end)])
                    manifest.append({"file": fn.name, "kind": "raw_dxt_snippet", "offset": off, "note": "could not guess dimensions"})
                    n += 1

    # 4) Extract shared textures referenced by MTRL but not in this block
    if args.shared_textures and tex_index:
        shared_list = json.loads(Path(args.shared_textures).read_text(encoding="utf-8"))
        local_names = {m.get("name") for m in manifest if m.get("name")}
        for sh in shared_list:
            tex_name = sh.get("name", "")
            tex_hash = sh.get("hash", 0)
            if not tex_name or tex_name in local_names:
                continue
            extracted = extract_shared_texture(tex_hash, tex_name, tex_index, args.out_dir, args.png)
            if extracted:
                manifest.append(extracted)
                n += 1

    tex_manifest = {
        "source_blob": str(args.blob),
        "stem": args.stem or None,
        "textures": manifest,
        "png_via": "ffmpeg" if shutil.which("ffmpeg") else None,
    }
    (args.out_dir / "manifest.json").write_text(json.dumps({"textures": manifest}, indent=2), encoding="utf-8")
    (args.out_dir / "texture_manifest.json").write_text(json.dumps(tex_manifest, indent=2), encoding="utf-8")
    print(f"Wrote {len(manifest)} entries -> {args.out_dir}")
    if args.png and not shutil.which("ffmpeg"):
        print("warning: --png requested but ffmpeg not found on PATH; DDS only", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
