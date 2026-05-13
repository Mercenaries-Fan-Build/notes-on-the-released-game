#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Extract embedded RIFF/WAVE (and OggS) streams from Mercenaries 2 .pws / blob banks."""

from __future__ import annotations

import argparse
import json
import struct
from pathlib import Path


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


def riff_chunk_size(data: bytes, riff_off: int) -> int | None:
    """Total RIFF size including 'RIFF' header + size dword + WAVE/fmt/data."""
    if riff_off + 12 > len(data) or data[riff_off : riff_off + 4] != b"RIFF":
        return None
    sz = struct.unpack_from("<I", data, riff_off + 4)[0]
    return 8 + sz  # RIFF header (8) + chunk payload declared


def parse_wave_metadata_from_riff(riff_blob: bytes) -> dict[str, object] | None:
    """If RIFF is WAVE with a ``fmt `` chunk, return sample_rate / channels / duration."""
    if len(riff_blob) < 12 or riff_blob[:4] != b"RIFF" or riff_blob[8:12] != b"WAVE":
        return None
    pos = 12
    sample_rate: int | None = None
    channels: int | None = None
    bits_per_sample: int | None = None
    audio_format: int | None = None
    byte_rate: int | None = None
    block_align: int | None = None
    data_bytes: int | None = None
    while pos + 8 <= len(riff_blob):
        cid = riff_blob[pos : pos + 4]
        csize = struct.unpack_from("<I", riff_blob, pos + 4)[0]
        pos += 8
        if pos + csize > len(riff_blob):
            break
        body = riff_blob[pos : pos + csize]
        if cid == b"fmt " and csize >= 16:
            audio_format, channels, sample_rate, byte_rate, block_align, bits_per_sample = struct.unpack_from(
                "<HHIIHH", body, 0
            )
        elif cid == b"data":
            data_bytes = csize
        pos += csize + (csize & 1)
    if sample_rate is None or channels is None or bits_per_sample is None or audio_format is None:
        return None
    out: dict[str, object] = {
        "wave_audio_format": audio_format,
        "wave_sample_rate": sample_rate,
        "wave_channels": channels,
        "wave_bits_per_sample": bits_per_sample,
        "wave_byte_rate": byte_rate,
        "wave_block_align": block_align,
    }
    if data_bytes is not None and byte_rate and byte_rate > 0:
        out["wave_duration_seconds"] = round(data_bytes / float(byte_rate), 6)
    return out


def extract_streams(path: Path, out_dir: Path) -> list[dict[str, object]]:
    data = path.read_bytes()
    out_dir.mkdir(parents=True, exist_ok=True)
    hits: list[dict[str, object]] = []
    used: set[tuple[int, int]] = set()

    for magic, label in ((b"RIFF", "riff"), (b"OggS", "ogg")):
        for off in find_all(data, magic):
            length = None
            if magic == b"RIFF":
                length = riff_chunk_size(data, off)
            else:
                end = min(len(data), off + 524_288)
                length = end - off

            if length is None or off + length > len(data) or length < 16:
                continue
            key = (off, length)
            if key in used:
                continue
            used.add(key)
            blob = data[off : off + length]
            fn = out_dir / f"{label}_{off:08x}_{len(hits):04d}.bin"
            fn.write_bytes(blob)
            entry: dict[str, object] = {"file": fn.name, "kind": label, "offset": off, "size": length}
            if magic == b"RIFF":
                wave = parse_wave_metadata_from_riff(blob)
                if wave:
                    entry.update(wave)
            hits.append(entry)

    (out_dir / "pws_manifest.json").write_text(json.dumps({"streams": hits, "source": str(path)}, indent=2), encoding="utf-8")
    return hits


def main() -> int:
    ap = argparse.ArgumentParser(description="Mercenaries 2 .pws / bank stream extraction")
    ap.add_argument("inputs", nargs="+", type=Path, help=".pws or other binary banks")
    ap.add_argument("--out-dir", type=Path, required=True, help="Directory for extracted streams")
    args = ap.parse_args()

    all_hits: list[dict[str, object]] = []
    for p in args.inputs:
        sub = args.out_dir / p.name
        hits = extract_streams(p, sub)
        all_hits.extend(hits)
        print(f"{p.name}: {len(hits)} streams -> {sub}")

    (args.out_dir / "pws_summary.json").write_text(json.dumps({"total_streams": len(all_hits)}, indent=2), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
