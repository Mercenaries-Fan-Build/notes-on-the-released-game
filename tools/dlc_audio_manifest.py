#!/usr/bin/env python3
"""Build machine-readable DLC audio manifest for port validation.

Scans a PC patch WAD (and optional Data/Audios) for wavebank/soundbank entries,
classifies every clip codec, flags streaming vs embedded payloads, and records
conversion requirements for the port pipeline.

Output: JSON with clip list, PWS inventory, and summary counts.

Usage:
    python tools/dlc_audio_manifest.py \\
        --patch-wad output/data/vz-patch.wad \\
        --audios-dir output/data/Audios \\
        --output output/analysis/dlc_audio_manifest.json
"""
from __future__ import annotations

import argparse
import json
import struct
import sys
from dataclasses import asdict, dataclass, field
from pathlib import Path

THIS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(THIS_DIR))

from audio_codec_policy import (
    codec_name,
    needs_pc_normalization,
    normalization_reason,
    probe_pws_payload,
)
from sges_decompress import decompress_sges_block

_TYPE_WAVEBANK = 0xF753F6D0
_TYPE_SOUNDBANK = 0x9F8BCA10
_TYPE_AUDIO_GROUP = 0xE5273C14
_AUDIO_TYPES = {_TYPE_WAVEBANK, _TYPE_SOUNDBANK, _TYPE_AUDIO_GROUP}
_WAVEBANK_RECORD_SIZE = 36
_PAGE_SIZE = 0x8000


@dataclass
class ClipRecord:
    block_index: int
    block_path: str
    wavebank_hash: int
    clip_index: int
    clip_hash: int
    channels: int
    codec: int
    codec_name: str
    sample_rate: int
    data_offset: int
    data_size: int
    embedded: bool
    streaming: bool
    needs_conversion: bool
    conversion_reason: str
    pws_candidates: list[str] = field(default_factory=list)


@dataclass
class PwsFileRecord:
    path: str
    size: int
    layout: str
    channels: int
    header_size: int
    needs_transcode: bool


def _parse_ffcs(raw: bytes) -> dict[str, tuple[int, int]]:
    chunks: dict[str, tuple[int, int]] = {}
    for i in range(7):
        off = 0x0C + i * 12
        tag = raw[off : off + 4].decode("ascii", errors="replace")
        offset = struct.unpack_from("<I", raw, off + 4)[0]
        meta = struct.unpack_from("<I", raw, off + 8)[0]
        if tag.strip("\x00"):
            chunks[tag] = (offset, meta)
    return chunks


def _parse_indx(raw: bytes, off: int, n: int) -> list[dict]:
    entries = []
    for i in range(n):
        o = off + i * 12
        pi, pk, fp = struct.unpack_from("<III", raw, o)
        entries.append({
            "page_idx": pi,
            "packed": pk,
            "page_count": fp & 0xFFFF,
            "flags": (fp >> 16) & 0xFFFF,
        })
    return entries


def _parse_paths(raw: bytes, off: int, count: int) -> list[str]:
    paths: list[str] = []
    pos = off
    for _ in range(count):
        nul = raw.index(b"\x00", pos)
        paths.append(raw[pos:nul].decode("utf-8", errors="replace"))
        pos = nul + 1
    return paths


def _decompress_block(raw: bytes, entry: dict) -> bytes | None:
    offset = entry["page_idx"] * _PAGE_SIZE
    size = entry["page_count"] * _PAGE_SIZE
    compressed = raw[offset : offset + size]
    if not compressed or compressed[:4] != b"sges":
        return None
    return decompress_sges_block(compressed, 0, len(compressed))


def _extract_data_body(container: bytes) -> bytes:
    if len(container) < 20 or container[:4] != b"UCFX":
        return b""
    data_area_off = struct.unpack_from("<I", container, 4)[0]
    n_desc = struct.unpack_from("<I", container, 16)[0]
    for d in range(n_desc):
        doff = 20 + d * 20
        tag = container[doff : doff + 4].decode("ascii", errors="replace")
        du0 = struct.unpack_from("<I", container, doff + 4)[0]
        dsz = struct.unpack_from("<I", container, doff + 8)[0]
        if tag == "data" and du0 != 0xFFFFFFFF:
            start = data_area_off + du0
            return container[start : start + dsz]
    return b""


def _iter_audio_entries(decomp: bytes) -> list[tuple[int, int, bytes]]:
    """Yield (entry_hash, type_hash, data_body) for audio UCFX entries."""
    count = struct.unpack_from("<I", decomp, 0)[0]
    pos = 4 + count * 16
    out: list[tuple[int, int, bytes]] = []
    for i in range(count):
        eoff = 4 + i * 16
        h, th, _o, sz = struct.unpack_from("<IIII", decomp, eoff)
        if th not in _AUDIO_TYPES:
            pos += sz
            continue
        container = decomp[pos : pos + sz]
        if len(container) >= 8 and container[-8:-4] == b"CSUM":
            container = container[:-8]
        body = _extract_data_body(container) if container[:4] == b"UCFX" else b""
        out.append((h, th, body))
        pos += sz
    return out


def _parse_wavebank_clips(
    body: bytes,
    *,
    block_index: int,
    block_path: str,
    wavebank_hash: int,
    body_len: int,
    pws_files: list[PwsFileRecord],
) -> list[ClipRecord]:
    if len(body) < 24:
        return []

    count = struct.unpack_from("<I", body, 0)[0]
    populated = struct.unpack_from("<H", body, 8)[0]
    records_off = struct.unpack_from("<I", body, 16)[0]
    pop = min(populated, count) if populated > 0 else count

    clips: list[ClipRecord] = []
    for i in range(pop):
        roff = records_off + i * _WAVEBANK_RECORD_SIZE
        if roff + _WAVEBANK_RECORD_SIZE > len(body):
            break
        clip_hash = struct.unpack_from("<I", body, roff)[0]
        fmt = body[roff + 4 : roff + 8]
        channels = fmt[1] if fmt[1] > 0 else 1
        codec = fmt[2]
        sample_rate = struct.unpack_from("<I", body, roff + 8)[0]
        data_offset = struct.unpack_from("<I", body, roff + 12)[0]
        data_size = struct.unpack_from("<I", body, roff + 16)[0]

        if clip_hash == 0 and data_size == 0:
            continue

        embedded = (
            data_size > 0
            and data_offset != 0xFFFF_FFFF
            and data_offset + data_size <= body_len
        )
        streaming = data_size > 0 and not embedded

        candidates: list[str] = []
        if streaming and pws_files:
            for pf in pws_files:
                payload_need = data_offset + data_size
                if pf.size >= payload_need:
                    candidates.append(pf.path)

        clips.append(
            ClipRecord(
                block_index=block_index,
                block_path=block_path,
                wavebank_hash=wavebank_hash,
                clip_index=i,
                clip_hash=clip_hash,
                channels=channels,
                codec=codec,
                codec_name=codec_name(codec),
                sample_rate=sample_rate,
                data_offset=data_offset,
                data_size=data_size,
                embedded=embedded,
                streaming=streaming,
                needs_conversion=needs_pc_normalization(codec),
                conversion_reason=normalization_reason(codec),
                pws_candidates=candidates,
            )
        )
    return clips


def scan_pws_dir(audios_dir: Path) -> list[PwsFileRecord]:
    if not audios_dir.is_dir():
        return []
    records: list[PwsFileRecord] = []
    for path in sorted(audios_dir.glob("*.pws")):
        data = path.read_bytes()
        probe = probe_pws_payload(data)
        records.append(
            PwsFileRecord(
                path=path.name,
                size=len(data),
                layout=probe.layout.value,
                channels=probe.channels,
                header_size=probe.header_size,
                needs_transcode=probe.needs_transcode,
            )
        )
    return records


def build_manifest(
    patch_wad: Path,
    audios_dir: Path | None,
) -> dict:
    raw = patch_wad.read_bytes()
    chunks = _parse_ffcs(raw)
    num_blocks = chunks["INDX"][1]
    indx = _parse_indx(raw, chunks["INDX"][0], num_blocks)
    paths = _parse_paths(raw, chunks["PTHS"][0], chunks["PTHS"][1])

    pws_files = scan_pws_dir(audios_dir) if audios_dir else []

    aset_off, aset_count = chunks["ASET"]
    audio_blocks: set[int] = set()
    for i in range(aset_count):
        off = aset_off + i * 16
        _, _, u2, tid = struct.unpack_from("<IIII", raw, off)
        if tid in (6, 21, 5):
            audio_blocks.add((u2 >> 16) & 0xFFFF)

    all_clips: list[ClipRecord] = []
    soundbank_count = 0
    wavebank_count = 0

    for blk_idx in sorted(audio_blocks):
        if blk_idx >= num_blocks:
            continue
        blk_path = paths[blk_idx] if blk_idx < len(paths) else f"block_{blk_idx}"
        decomp = _decompress_block(raw, indx[blk_idx])
        if not decomp:
            continue
        for entry_hash, type_hash, body in _iter_audio_entries(decomp):
            if type_hash == _TYPE_WAVEBANK:
                wavebank_count += 1
                all_clips.extend(
                    _parse_wavebank_clips(
                        body,
                        block_index=blk_idx,
                        block_path=blk_path,
                        wavebank_hash=entry_hash,
                        body_len=len(body),
                        pws_files=pws_files,
                    )
                )
            elif type_hash == _TYPE_SOUNDBANK:
                soundbank_count += 1

    codec_hist: dict[str, int] = {}
    needs_conv = 0
    streaming_clips = 0
    missing_pws = 0
    for c in all_clips:
        codec_hist[c.codec_name] = codec_hist.get(c.codec_name, 0) + 1
        if c.needs_conversion:
            needs_conv += 1
        if c.streaming:
            streaming_clips += 1
            if not c.pws_candidates:
                missing_pws += 1

    return {
        "patch_wad": str(patch_wad),
        "audios_dir": str(audios_dir) if audios_dir else None,
        "summary": {
            "audio_blocks": len(audio_blocks),
            "wavebanks": wavebank_count,
            "soundbanks": soundbank_count,
            "clips_total": len(all_clips),
            "clips_needing_conversion": needs_conv,
            "streaming_clips": streaming_clips,
            "streaming_clips_without_pws": missing_pws,
            "pws_files": len(pws_files),
            "pws_needing_transcode": sum(1 for p in pws_files if p.needs_transcode),
            "codec_histogram": codec_hist,
        },
        "pws_files": [asdict(p) for p in pws_files],
        "clips": [asdict(c) for c in all_clips],
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Build DLC audio manifest JSON")
    ap.add_argument(
        "--patch-wad",
        type=Path,
        default=Path("output/data/vz-patch.wad"),
    )
    ap.add_argument(
        "--audios-dir",
        type=Path,
        default=Path("output/data/Audios"),
    )
    ap.add_argument(
        "--output",
        "-o",
        type=Path,
        default=Path("output/analysis/dlc_audio_manifest.json"),
    )
    args = ap.parse_args()

    if not args.patch_wad.is_file():
        print(f"ERROR: patch WAD not found: {args.patch_wad}", file=sys.stderr)
        return 1

    audios = args.audios_dir if args.audios_dir.is_dir() else None
    manifest = build_manifest(args.patch_wad, audios)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(manifest, indent=2),
        encoding="utf-8",
    )

    s = manifest["summary"]
    print(f"Wrote {args.output}")
    print(f"  clips: {s['clips_total']} ({s['clips_needing_conversion']} need conversion)")
    print(f"  streaming: {s['streaming_clips']} ({s['streaming_clips_without_pws']} missing PWS)")
    print(f"  PWS files: {s['pws_files']} ({s['pws_needing_transcode']} need transcode)")
    print(f"  codecs: {s['codec_histogram']}")

    return 1 if s["clips_needing_conversion"] or s["pws_needing_transcode"] else 0


if __name__ == "__main__":
    sys.exit(main())
