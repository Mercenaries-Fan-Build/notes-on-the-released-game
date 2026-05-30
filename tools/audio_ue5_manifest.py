#!/usr/bin/env python3
"""Build UE5-oriented audio manifest: soundbank/wavebank hashes → file paths.

Lightweight index for future UE5 import. Does **not** decompress WADs, decode
IMA ADPCM, or run heavy extraction — it scans existing pipeline outputs and
defines canonical paths for clips that are not extracted yet.

Inputs (all optional except --pipeline-root):
  - ``<pipeline>/extracted_audio/`` — PWS stream extractions (``pws_extractor.py``)
  - ``<pipeline>/extracted/audio/wavebanks/`` — planned/future decoded clip tree
  - ``--clips-json`` — clip records from ``dlc_audio_manifest.py`` (or compatible)
  - ``--blocks-dir`` — pre-decompressed ``*.block.bin`` (no WAD I/O)

Output JSON keys:
  - ``wavebanks`` — clip_hash → wav path + UE5 content path
  - ``soundbanks`` — event/clip hashes grouped by block co-occurrence
  - ``pws_streams`` — standalone streaming audio from ``data/Audios/*.pws``
  - ``ue5_import`` — directory plan + readiness counts

Usage:
    python tools/audio_ue5_manifest.py --pipeline-root ./output \\
        --clips-json output/analysis/dlc_audio_manifest.json \\
        -o output/ue5_import/metadata/audio_ue5_manifest.json
"""
from __future__ import annotations

import argparse
import json
import struct
import sys
import wave
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any

THIS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(THIS_DIR))

from audio_codec_policy import codec_name  # noqa: E402
from hash_resolver import get_resolver  # noqa: E402

_TYPE_WAVEBANK = 0xF753F6D0
_TYPE_SOUNDBANK = 0x9F8BCA10
_WAVEBANK_RECORD_SIZE = 36
_MANIFEST_VERSION = 1

# Planned extraction layout (future ``wavebank_extractor.py``).
_WAV_ROOT_REL = Path("extracted/audio/wavebanks")
_UE5_AUDIO_ROOT = "/Game/Mercs2/Audio"


@dataclass
class ClipEntry:
    clip_hash: int
    clip_index: int
    wavebank_hash: int
    block_path: str
    block_index: int
    channels: int
    codec: int
    codec_name: str
    sample_rate: int
    embedded: bool
    streaming: bool
    extracted_wav: str | None
    planned_wav: str
    ue5_sound_path: str
    status: str  # present | missing | streaming_only


@dataclass
class WavebankEntry:
    wavebank_hash: int
    name_hint: str | None
    block_path: str
    block_index: int
    ue5_package_path: str
    clips: list[ClipEntry] = field(default_factory=list)


@dataclass
class SoundbankEntry:
    soundbank_hash: int
    name_hint: str | None
    block_path: str
    block_index: int
    ue5_package_path: str
    sub_count: int
    linked_clip_hashes: list[int] = field(default_factory=list)
    linked_wav_paths: list[str] = field(default_factory=list)
    association: str = "block_co_occurrence"


def _hex(h: int) -> str:
    return f"0x{h:08X}"


def _name_hint(asset_hash: int) -> str | None:
    resolver = get_resolver()
    names = resolver.resolve_m2_all(asset_hash)
    return names[0] if names else None


def _sanitize_ue_segment(name: str | None, fallback_hash: int) -> str:
    if name:
        seg = "".join(c if c.isalnum() or c in "_-" else "_" for c in name)
        seg = seg.strip("_")
        if seg:
            return seg[:64]
    return f"h{fallback_hash:08X}"


def _planned_wav_rel(wavebank_hash: int, clip_hash: int) -> str:
    wb = f"{wavebank_hash:08X}"
    return str(_WAV_ROOT_REL / wb / f"clip_{clip_hash:08X}.wav")


def _ue5_sound_path(wavebank_hash: int, clip_hash: int, name_hint: str | None) -> str:
    wb_seg = _sanitize_ue_segment(name_hint, wavebank_hash)
    return f"{_UE5_AUDIO_ROOT}/Wavebanks/{wb_seg}/SC_{clip_hash:08X}"


def _ue5_wavebank_package(wavebank_hash: int, name_hint: str | None) -> str:
    wb_seg = _sanitize_ue_segment(name_hint, wavebank_hash)
    return f"{_UE5_AUDIO_ROOT}/Wavebanks/{wb_seg}"


def _ue5_soundbank_package(soundbank_hash: int, name_hint: str | None) -> str:
    sb_seg = _sanitize_ue_segment(name_hint, soundbank_hash)
    return f"{_UE5_AUDIO_ROOT}/Soundbanks/{sb_seg}"


def _resolve_wav(pipeline_root: Path, planned_rel: str) -> tuple[str | None, str]:
    planned = pipeline_root / planned_rel
    if planned.is_file():
        return str(planned.relative_to(pipeline_root).as_posix()), "present"
    return None, "missing"


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


def _iter_block_audio(decomp: bytes) -> list[tuple[int, int, bytes, str]]:
    """Return (entry_hash, type_hash, data_body, block_stem) from a decompressed block."""
    count = struct.unpack_from("<I", decomp, 0)[0]
    pos = 4 + count * 16
    out: list[tuple[int, int, bytes, str]] = []
    for i in range(count):
        eoff = 4 + i * 16
        h, th, _o, sz = struct.unpack_from("<IIII", decomp, eoff)
        if th not in (_TYPE_WAVEBANK, _TYPE_SOUNDBANK):
            pos += sz
            continue
        container = decomp[pos : pos + sz]
        if len(container) >= 8 and container[-8:-4] == b"CSUM":
            container = container[:-8]
        body = _extract_data_body(container) if container[:4] == b"UCFX" else b""
        out.append((h, th, body, ""))
        pos += sz
    return out


def _parse_wavebank_clips_from_body(
    body: bytes,
    *,
    wavebank_hash: int,
    block_path: str,
    block_index: int,
    pipeline_root: Path,
) -> list[ClipEntry]:
    if len(body) < 24:
        return []

    count = struct.unpack_from("<I", body, 0)[0]
    populated = struct.unpack_from("<H", body, 8)[0]
    records_off = struct.unpack_from("<I", body, 16)[0]
    body_len = len(body)
    pop = min(populated, count) if populated > 0 else count
    hint = _name_hint(wavebank_hash)

    clips: list[ClipEntry] = []
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
        planned_rel = _planned_wav_rel(wavebank_hash, clip_hash)
        extracted, status = _resolve_wav(pipeline_root, planned_rel)
        if streaming and status == "missing":
            status = "streaming_only"

        clips.append(
            ClipEntry(
                clip_hash=clip_hash,
                clip_index=i,
                wavebank_hash=wavebank_hash,
                block_path=block_path,
                block_index=block_index,
                channels=channels,
                codec=codec,
                codec_name=codec_name(codec),
                sample_rate=sample_rate,
                embedded=embedded,
                streaming=streaming,
                extracted_wav=extracted,
                planned_wav=planned_rel,
                ue5_sound_path=_ue5_sound_path(wavebank_hash, clip_hash, hint),
                status=status,
            )
        )
    return clips


def _parse_soundbank_links(body: bytes) -> tuple[int, list[int]]:
    """Return (sub_count, clip-like hashes from section B)."""
    if len(body) < 32:
        return 0, []
    sub_count = struct.unpack_from("<H", body, 8)[0]
    data_start = struct.unpack_from("<I", body, 16)[0]
    section_off1 = struct.unpack_from("<I", body, 20)[0]
    section_off2 = struct.unpack_from("<I", body, 24)[0]
    hashes: list[int] = []
    if section_off2 > section_off1 and sub_count > 0:
        sec_b = body[section_off1:section_off2]
        for i in range(sub_count):
            off = i * 4
            if off + 4 > len(sec_b):
                break
            v = struct.unpack_from("<I", sec_b, off)[0]
            if 0 < v < 0x1000_0000:
                hashes.append(v)
    return sub_count, hashes


def _clips_from_json_records(
    records: list[dict[str, Any]],
    pipeline_root: Path,
) -> list[ClipEntry]:
    clips: list[ClipEntry] = []
    for row in records:
        wb = int(row["wavebank_hash"])
        ch = int(row["clip_hash"])
        hint = _name_hint(wb)
        planned_rel = _planned_wav_rel(wb, ch)
        extracted, status = _resolve_wav(pipeline_root, planned_rel)
        streaming = bool(row.get("streaming"))
        if streaming and status == "missing":
            status = "streaming_only"
        clips.append(
            ClipEntry(
                clip_hash=ch,
                clip_index=int(row.get("clip_index", 0)),
                wavebank_hash=wb,
                block_path=str(row.get("block_path", "")),
                block_index=int(row.get("block_index", -1)),
                channels=int(row.get("channels", 1)),
                codec=int(row.get("codec", 0)),
                codec_name=str(row.get("codec_name", codec_name(int(row.get("codec", 0))))),
                sample_rate=int(row.get("sample_rate", 0)),
                embedded=bool(row.get("embedded")),
                streaming=streaming,
                extracted_wav=extracted,
                planned_wav=planned_rel,
                ue5_sound_path=_ue5_sound_path(wb, ch, hint),
                status=status,
            )
        )
    return clips


def scan_blocks_dir(blocks_dir: Path, pipeline_root: Path) -> tuple[list[ClipEntry], list[SoundbankEntry]]:
    clips: list[ClipEntry] = []
    soundbanks: list[SoundbankEntry] = []
    if not blocks_dir.is_dir():
        return clips, soundbanks

    for block_path in sorted(blocks_dir.glob("*.block.bin")):
        decomp = block_path.read_bytes()
        stem = block_path.stem
        block_index = -1
        # Filename prefix ``00029_`` when present.
        if "_" in stem and stem[:5].isdigit():
            try:
                block_index = int(stem.split("_", 1)[0])
            except ValueError:
                pass

        block_clips: list[ClipEntry] = []
        block_soundbanks: list[tuple[int, int, list[int]]] = []

        for entry_hash, type_hash, body, _ in _iter_block_audio(decomp):
            if type_hash == _TYPE_WAVEBANK:
                parsed = _parse_wavebank_clips_from_body(
                    body,
                    wavebank_hash=entry_hash,
                    block_path=stem,
                    block_index=block_index,
                    pipeline_root=pipeline_root,
                )
                block_clips.extend(parsed)
            elif type_hash == _TYPE_SOUNDBANK:
                sub_count, linked = _parse_soundbank_links(body)
                block_soundbanks.append((entry_hash, sub_count, linked))

        clips.extend(block_clips)
        clip_hash_set = {c.clip_hash for c in block_clips}
        wav_by_hash = {c.clip_hash: c.planned_wav for c in block_clips if c.extracted_wav}

        for sb_hash, sub_count, linked in block_soundbanks:
            hint = _name_hint(sb_hash)
            resolved = [h for h in linked if h in clip_hash_set]
            soundbanks.append(
                SoundbankEntry(
                    soundbank_hash=sb_hash,
                    name_hint=hint,
                    block_path=stem,
                    block_index=block_index,
                    ue5_package_path=_ue5_soundbank_package(sb_hash, hint),
                    sub_count=sub_count,
                    linked_clip_hashes=resolved or linked,
                    linked_wav_paths=[
                        wav_by_hash.get(h, _planned_wav_rel(next(iter(clip_hash_set), 0), h))
                        for h in (resolved or linked)
                    ],
                    association="section_b_index" if resolved else "block_co_occurrence",
                )
            )

    return clips, soundbanks


def scan_decoded_wavebanks(pipeline_root: Path) -> list[ClipEntry]:
    """Index WAV files written by ``wavebank_extractor.py`` (no WAD / block scan)."""
    root = pipeline_root / _WAV_ROOT_REL
    if not root.is_dir():
        return []

    clips: list[ClipEntry] = []
    for wb_dir in sorted(root.iterdir()):
        if not wb_dir.is_dir():
            continue
        try:
            wb_hash = int(wb_dir.name, 16)
        except ValueError:
            continue
        hint = _name_hint(wb_hash)
        for wav_path in sorted(wb_dir.glob("clip_*.wav")):
            stem = wav_path.stem
            if not stem.startswith("clip_"):
                continue
            try:
                clip_hash = int(stem[5:], 16)
            except ValueError:
                continue
            planned_rel = _planned_wav_rel(wb_hash, clip_hash)
            rel = wav_path.relative_to(pipeline_root).as_posix()
            channels = 1
            sample_rate = 0
            try:
                with wave.open(str(wav_path), "rb") as wf:
                    channels = wf.getnchannels()
                    sample_rate = wf.getframerate()
            except (OSError, wave.Error):
                pass
            clips.append(
                ClipEntry(
                    clip_hash=clip_hash,
                    clip_index=0,
                    wavebank_hash=wb_hash,
                    block_path="wavebank_extractor",
                    block_index=-1,
                    channels=channels,
                    codec=2,
                    codec_name=codec_name(2),
                    sample_rate=sample_rate,
                    embedded=True,
                    streaming=False,
                    extracted_wav=rel,
                    planned_wav=planned_rel,
                    ue5_sound_path=_ue5_sound_path(wb_hash, clip_hash, hint),
                    status="present",
                )
            )
    return clips


def scan_pws_extracted(extracted_audio_dir: Path, pipeline_root: Path) -> list[dict[str, Any]]:
    if not extracted_audio_dir.is_dir():
        return []

    streams: list[dict[str, Any]] = []
    for manifest_path in sorted(extracted_audio_dir.glob("*/pws_manifest.json")):
        try:
            raw = json.loads(manifest_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        source = Path(str(raw.get("source", manifest_path.parent.name))).name
        subdir = manifest_path.parent
        for hit in raw.get("streams", []):
            if not isinstance(hit, dict):
                continue
            fn = str(hit.get("file", ""))
            rel = (subdir / fn).relative_to(pipeline_root).as_posix() if fn else None
            streams.append(
                {
                    "pws_source": source,
                    "stream_file": fn,
                    "relative_path": rel,
                    "kind": hit.get("kind"),
                    "size": hit.get("size"),
                    "wave_sample_rate": hit.get("wave_sample_rate"),
                    "wave_channels": hit.get("wave_channels"),
                    "wave_duration_seconds": hit.get("wave_duration_seconds"),
                    "ue5_stream_path": f"{_UE5_AUDIO_ROOT}/Streams/{source.replace('.', '_')}/{Path(fn).stem}",
                }
            )
    return streams


def build_manifest(
    pipeline_root: Path,
    *,
    clips_json: Path | None,
    blocks_dir: Path | None,
) -> dict[str, Any]:
    pipeline_root = pipeline_root.resolve()
    clips: list[ClipEntry] = []
    soundbanks: list[SoundbankEntry] = []

    if clips_json and clips_json.is_file():
        raw = json.loads(clips_json.read_text(encoding="utf-8"))
        clip_rows = raw.get("clips", raw if isinstance(raw, list) else [])
        if isinstance(clip_rows, list):
            clips.extend(_clips_from_json_records(clip_rows, pipeline_root))

    if blocks_dir:
        block_clips, block_sbs = scan_blocks_dir(blocks_dir, pipeline_root)
        # Merge: block scan wins for duplicates (richer soundbank linkage).
        seen = {(c.wavebank_hash, c.clip_hash) for c in clips}
        for c in block_clips:
            key = (c.wavebank_hash, c.clip_hash)
            if key not in seen:
                clips.append(c)
                seen.add(key)
        if block_sbs:
            soundbanks = block_sbs

    # WAV tree from wavebank_extractor (fills gaps when blocks_dir / clips_json absent).
    by_key = {(c.wavebank_hash, c.clip_hash): c for c in clips}
    for c in scan_decoded_wavebanks(pipeline_root):
        key = (c.wavebank_hash, c.clip_hash)
        prev = by_key.get(key)
        if prev is None:
            clips.append(c)
            by_key[key] = c
        elif prev.status != "present" and c.status == "present":
            prev.extracted_wav = c.extracted_wav
            prev.status = "present"
            if not prev.sample_rate and c.sample_rate:
                prev.sample_rate = c.sample_rate
            if prev.channels <= 1 and c.channels > 1:
                prev.channels = c.channels

    # Group wavebanks.
    wavebanks_by_hash: dict[int, WavebankEntry] = {}
    for c in clips:
        if c.wavebank_hash not in wavebanks_by_hash:
            hint = _name_hint(c.wavebank_hash)
            wavebanks_by_hash[c.wavebank_hash] = WavebankEntry(
                wavebank_hash=c.wavebank_hash,
                name_hint=hint,
                block_path=c.block_path,
                block_index=c.block_index,
                ue5_package_path=_ue5_wavebank_package(c.wavebank_hash, hint),
            )
        wavebanks_by_hash[c.wavebank_hash].clips.append(c)

    # Soundbanks without block scan: co-locate by block_path.
    if not soundbanks and clips:
        by_block: dict[str, list[ClipEntry]] = {}
        for c in clips:
            by_block.setdefault(c.block_path, []).append(c)
        # Placeholder: one synthetic soundbank entry per block with clips (hash unknown).
        for block_path, block_clips in by_block.items():
            if not block_path:
                continue
            clip_hashes = sorted({c.clip_hash for c in block_clips})
            soundbanks.append(
                SoundbankEntry(
                    soundbank_hash=0,
                    name_hint=None,
                    block_path=block_path,
                    block_index=block_clips[0].block_index,
                    ue5_package_path=f"{_UE5_AUDIO_ROOT}/Soundbanks/by_block/{block_path[:48]}",
                    sub_count=0,
                    linked_clip_hashes=clip_hashes,
                    linked_wav_paths=[c.planned_wav for c in block_clips],
                    association="clips_json_block_group",
                )
            )

    pws_streams = scan_pws_extracted(pipeline_root / "extracted_audio", pipeline_root)

    present = sum(1 for c in clips if c.status == "present")
    missing = sum(1 for c in clips if c.status == "missing")
    streaming_only = sum(1 for c in clips if c.status == "streaming_only")

    return {
        "manifest_version": _MANIFEST_VERSION,
        "pipeline_root": str(pipeline_root),
        "sources": {
            "clips_json": str(clips_json) if clips_json else None,
            "blocks_dir": str(blocks_dir) if blocks_dir else None,
            "extracted_audio": str(pipeline_root / "extracted_audio"),
            "planned_wav_root": str(pipeline_root / _WAV_ROOT_REL),
            "decoded_wavebanks": str(pipeline_root / _WAV_ROOT_REL),
        },
        "summary": {
            "wavebanks": len(wavebanks_by_hash),
            "clips_total": len(clips),
            "clips_present": present,
            "clips_missing": missing,
            "clips_streaming_only": streaming_only,
            "soundbanks": len(soundbanks),
            "pws_streams": len(pws_streams),
        },
        "wavebanks": {
            _hex(wb.wavebank_hash): {
                **{k: v for k, v in asdict(wb).items() if k != "clips"},
                "clips": [asdict(c) for c in wb.clips],
            }
            for wb in wavebanks_by_hash.values()
        },
        "soundbanks": {
            (_hex(sb.soundbank_hash) if sb.soundbank_hash else f"block:{sb.block_path}"): asdict(sb)
            for sb in soundbanks
        },
        "pws_streams": pws_streams,
        "ue5_import": {
            "content_directories": [
                f"{_UE5_AUDIO_ROOT}/Wavebanks",
                f"{_UE5_AUDIO_ROOT}/Soundbanks",
                f"{_UE5_AUDIO_ROOT}/Streams",
                f"{_UE5_AUDIO_ROOT}/Music",
                f"{_UE5_AUDIO_ROOT}/MetaSounds",
            ],
            "import_tool": "game-scripts/import_audio.py",
            "readiness": {
                "embedded_clips_ready_pct": round(100.0 * present / len(clips), 2) if clips else 0.0,
                "pending_wav_decode": missing,
                "pending_stream_link": streaming_only,
            },
        },
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Build UE5 audio import manifest (lightweight)")
    ap.add_argument(
        "--pipeline-root",
        type=Path,
        default=Path("output"),
        help="Pipeline output root (contains extracted_audio/, etc.)",
    )
    ap.add_argument(
        "--clips-json",
        type=Path,
        default=None,
        help="Clip records from dlc_audio_manifest.json or compatible",
    )
    ap.add_argument(
        "--blocks-dir",
        type=Path,
        default=None,
        help="Pre-decompressed *.block.bin directory (optional, no WAD I/O)",
    )
    ap.add_argument(
        "--output",
        "-o",
        type=Path,
        default=Path("output/ue5_import/metadata/audio_ue5_manifest.json"),
    )
    args = ap.parse_args()

    if args.clips_json is None:
        default_clips = args.pipeline_root / "analysis" / "dlc_audio_manifest.json"
        if default_clips.is_file():
            args.clips_json = default_clips

    if args.blocks_dir is None:
        default_blocks = args.pipeline_root / "extracted" / "batch_vz" / "blocks"
        if default_blocks.is_dir():
            args.blocks_dir = default_blocks

    manifest = build_manifest(
        args.pipeline_root,
        clips_json=args.clips_json,
        blocks_dir=args.blocks_dir,
    )

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    s = manifest["summary"]
    print(f"Wrote {args.output}")
    print(
        f"  wavebanks={s['wavebanks']} clips={s['clips_total']} "
        f"(present={s['clips_present']} missing={s['clips_missing']} "
        f"streaming_only={s['clips_streaming_only']})"
    )
    print(f"  soundbanks={s['soundbanks']} pws_streams={s['pws_streams']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
