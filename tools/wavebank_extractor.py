#!/usr/bin/env python3
"""Decode embedded IMA ADPCM clips from a decompressed wavebank block to WAV files.

Writes into the tree expected by ``tools/audio_ue5_manifest.py``:
  ``<pipeline>/extracted/audio/wavebanks/{wavebank_hash:08X}/clip_{clip_hash:08X}.wav``

Usage:
    # From an existing decompressed block (from extract_single_block --keep):
    python tools/wavebank_extractor.py --block-bin output/_scratch/00033_ui_hud.block.bin \\
        --pipeline-root ./output

    # Extract ui_hud block from retail WAD, decode, clean scratch:
    python tools/wavebank_extractor.py --extract-from-wad \\
        --wad game-files/pc-game-vz.wad --path ui_hud_P000_Q3 \\
        --pipeline-root ./output

    # Then refresh UE5 manifest (scans extracted/audio/wavebanks/ for WAV files):
    python tools/audio_ue5_manifest.py --pipeline-root ./output \\
        -o output/ue5_import/metadata/audio_ue5_manifest.json
"""
from __future__ import annotations

import argparse
import json
import shutil
import struct
import subprocess
import sys
from dataclasses import asdict, dataclass, field
from pathlib import Path

THIS_DIR = Path(__file__).resolve().parent
REPO_ROOT = THIS_DIR.parent
sys.path.insert(0, str(THIS_DIR))

from audio_codec_policy import (  # noqa: E402
    CODEC_IMA_PC,
    CODEC_PCM,
    CODEC_MS_IMA_FMT,
    UnhandledAudioCodecError,
    codec_name,
)
from audio_ue5_manifest import (  # noqa: E402
    _TYPE_WAVEBANK,
    _WAV_ROOT_REL,
    _extract_data_body,
    _planned_wav_rel,
)
from ima_adpcm import ImaDecodeError, decode_ima_to_interleaved, write_wav_pcm16  # noqa: E402

_WAVEBANK_RECORD_SIZE = 36
_WAVEBANK_HEADER_SIZE = 24
_TYPE_WAVEBANK_LE = _TYPE_WAVEBANK


@dataclass
class WaveClipRecord:
    clip_index: int
    clip_hash: int
    channels: int
    codec: int
    sample_rate: int
    data_offset: int
    data_size: int
    embedded: bool
    streaming: bool


@dataclass
class WavebankAsset:
    wavebank_hash: int
    self_hash: int
    clips: list[WaveClipRecord] = field(default_factory=list)


@dataclass
class DecodedClipResult:
    clip_hash: int
    clip_index: int
    wav_path: str
    sample_count: int
    duration_seconds: float
    channels: int
    codec: int
    status: str  # decoded | skipped_streaming | skipped_codec | failed


@dataclass
class ExtractSummary:
    block_path: str
    wavebanks: list[WavebankAsset]
    decoded: list[DecodedClipResult] = field(default_factory=list)
    skipped_streaming: int = 0
    skipped_codec: int = 0
    failed: int = 0


def _iter_wavebank_bodies(decomp: bytes) -> list[tuple[int, bytes]]:
    """Return (entry_hash, wavebank data body) from a decompressed block."""
    if len(decomp) < 4:
        return []
    count = struct.unpack_from("<I", decomp, 0)[0]
    pos = 4 + count * 16
    out: list[tuple[int, bytes]] = []
    for i in range(count):
        eoff = 4 + i * 16
        if eoff + 16 > len(decomp):
            break
        entry_hash, type_hash, _o, sz = struct.unpack_from("<IIII", decomp, eoff)
        if pos + sz > len(decomp):
            break
        if type_hash == _TYPE_WAVEBANK_LE:
            container = decomp[pos : pos + sz]
            if len(container) >= 8 and container[-8:-4] == b"CSUM":
                container = container[:-8]
            body = _extract_data_body(container) if container[:4] == b"UCFX" else b""
            if body:
                out.append((entry_hash, body))
        pos += sz
    return out


def parse_wavebank_body(body: bytes, *, entry_hash: int) -> WavebankAsset:
    """Parse wavebank header + records (embedded vs streaming flags)."""
    wb = WavebankAsset(wavebank_hash=entry_hash, self_hash=entry_hash)
    if len(body) < _WAVEBANK_HEADER_SIZE:
        return wb

    count = struct.unpack_from("<I", body, 0)[0]
    self_hash = struct.unpack_from("<I", body, 4)[0]
    populated = struct.unpack_from("<H", body, 8)[0]
    records_off = struct.unpack_from("<I", body, 16)[0]
    wb.self_hash = self_hash
    body_len = len(body)

    pop = min(populated, count) if populated > 0 else count
    for i in range(pop):
        roff = records_off + i * _WAVEBANK_RECORD_SIZE
        if roff + _WAVEBANK_RECORD_SIZE > body_len:
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
        wb.clips.append(
            WaveClipRecord(
                clip_index=i,
                clip_hash=clip_hash,
                channels=channels,
                codec=codec,
                sample_rate=sample_rate,
                data_offset=data_offset,
                data_size=data_size,
                embedded=embedded,
                streaming=streaming,
            )
        )
    return wb


def _decode_clip_payload(
    payload: bytes,
    *,
    channels: int,
    codec: int,
) -> tuple[list[int], int]:
    """Return (samples, channels) for a clip blob."""
    if codec in (CODEC_IMA_PC, CODEC_MS_IMA_FMT):
        return decode_ima_to_interleaved(payload, channels)
    if codec == CODEC_PCM:
        if len(payload) % 2 != 0:
            raise UnhandledAudioCodecError(f"PCM payload odd length {len(payload)}")
        samples = list(struct.unpack(f"<{len(payload) // 2}h", payload))
        ch = channels if channels > 0 else 1
        return samples, ch
    raise UnhandledAudioCodecError(f"codec {codec_name(codec)} not decodable on PC")


def extract_wavebanks_from_block(
    block_bin: Path,
    pipeline_root: Path,
    *,
    wavebank_hash: int | None = None,
    max_clips: int | None = None,
    dry_run: bool = False,
) -> ExtractSummary:
    """Decode embedded clips from one decompressed ``*.block.bin``."""
    decomp = block_bin.read_bytes()
    summary = ExtractSummary(block_path=str(block_bin), wavebanks=[])

    bodies = _iter_wavebank_bodies(decomp)
    if wavebank_hash is not None:
        bodies = [(h, b) for h, b in bodies if h == wavebank_hash]
        if not bodies:
            raise SystemExit(
                f"No wavebank 0x{wavebank_hash:08X} in {block_bin.name} "
                f"(found {[f'0x{h:08X}' for h, _ in _iter_wavebank_bodies(decomp)]})"
            )

    decoded_count = 0
    for entry_hash, body in bodies:
        wb = parse_wavebank_body(body, entry_hash=entry_hash)
        summary.wavebanks.append(wb)
        wb_hash = wb.self_hash or entry_hash

        for clip in wb.clips:
            if max_clips is not None and decoded_count >= max_clips:
                break
            rel = _planned_wav_rel(wb_hash, clip.clip_hash)
            out_path = pipeline_root / rel

            if clip.streaming:
                summary.skipped_streaming += 1
                summary.decoded.append(
                    DecodedClipResult(
                        clip_hash=clip.clip_hash,
                        clip_index=clip.clip_index,
                        wav_path=rel,
                        sample_count=0,
                        duration_seconds=0.0,
                        channels=clip.channels,
                        codec=clip.codec,
                        status="skipped_streaming",
                    )
                )
                continue

            if not clip.embedded or clip.data_size == 0:
                continue

            if clip.codec not in (CODEC_IMA_PC, CODEC_MS_IMA_FMT, CODEC_PCM):
                summary.skipped_codec += 1
                summary.decoded.append(
                    DecodedClipResult(
                        clip_hash=clip.clip_hash,
                        clip_index=clip.clip_index,
                        wav_path=rel,
                        sample_count=0,
                        duration_seconds=0.0,
                        channels=clip.channels,
                        codec=clip.codec,
                        status="skipped_codec",
                    )
                )
                continue

            payload = body[clip.data_offset : clip.data_offset + clip.data_size]
            if dry_run:
                summary.decoded.append(
                    DecodedClipResult(
                        clip_hash=clip.clip_hash,
                        clip_index=clip.clip_index,
                        wav_path=rel,
                        sample_count=0,
                        duration_seconds=0.0,
                        channels=clip.channels,
                        codec=clip.codec,
                        status="dry_run",
                    )
                )
                decoded_count += 1
                continue

            try:
                samples, out_channels = _decode_clip_payload(
                    payload, channels=clip.channels, codec=clip.codec
                )
            except (ImaDecodeError, UnhandledAudioCodecError) as exc:
                summary.failed += 1
                summary.decoded.append(
                    DecodedClipResult(
                        clip_hash=clip.clip_hash,
                        clip_index=clip.clip_index,
                        wav_path=rel,
                        sample_count=0,
                        duration_seconds=0.0,
                        channels=clip.channels,
                        codec=clip.codec,
                        status=f"failed:{exc}",
                    )
                )
                continue

            write_wav_pcm16(
                out_path,
                samples,
                sample_rate=clip.sample_rate,
                channels=out_channels,
            )
            duration = len(samples) / (clip.sample_rate * out_channels) if clip.sample_rate else 0.0
            summary.decoded.append(
                DecodedClipResult(
                    clip_hash=clip.clip_hash,
                    clip_index=clip.clip_index,
                    wav_path=rel,
                    sample_count=len(samples) // out_channels,
                    duration_seconds=round(duration, 4),
                    channels=out_channels,
                    codec=clip.codec,
                    status="decoded",
                )
            )
            decoded_count += 1

    return summary


def _python_exe() -> str:
    venv = REPO_ROOT / ".venv" / "Scripts" / "python.exe"
    if venv.is_file():
        return str(venv)
    venv_unix = REPO_ROOT / ".venv" / "bin" / "python3"
    if venv_unix.is_file():
        return str(venv_unix)
    return sys.executable


def extract_block_from_wad(
    wad: Path,
    *,
    block_index: int | None,
    path_query: str | None,
    scratch_root: Path,
) -> Path:
    """Run ``extract_single_block.py``; return path to decompressed ``*.block.bin``."""
    scratch_root.mkdir(parents=True, exist_ok=True)
    cmd = [
        _python_exe(),
        str(THIS_DIR / "extract_single_block.py"),
        "--wad",
        str(wad),
        "--keep",
        "--scratch-root",
        str(scratch_root),
    ]
    if block_index is not None:
        cmd.extend(["--block-index", str(block_index)])
    elif path_query:
        cmd.extend(["--path", path_query])
    else:
        raise ValueError("block_index or path_query required")

    proc = subprocess.run(cmd, capture_output=True, text=True, cwd=str(REPO_ROOT))
    if proc.returncode != 0:
        raise SystemExit(
            f"extract_single_block failed ({proc.returncode}):\n{proc.stderr or proc.stdout}"
        )
    # Last line often prints the kept .block.bin path.
    for line in reversed((proc.stdout or "").splitlines()):
        line = line.strip()
        if line.endswith(".block.bin") and Path(line).is_file():
            return Path(line)
    # Fallback: newest .block.bin in scratch.
    candidates = sorted(scratch_root.glob("*.block.bin"), key=lambda p: p.stat().st_mtime)
    if not candidates:
        raise SystemExit("extract_single_block succeeded but no .block.bin found in scratch")
    return candidates[-1]


def _write_sidecar(summary: ExtractSummary, pipeline_root: Path, block_stem: str) -> Path:
    out_dir = pipeline_root / _WAV_ROOT_REL
    out_dir.mkdir(parents=True, exist_ok=True)
    sidecar = out_dir / f"{block_stem}_wavebank_extract.json"
    payload = {
        "block_path": summary.block_path,
        "wavebanks": [
            {
                "wavebank_hash": f"0x{wb.wavebank_hash:08X}",
                "self_hash": f"0x{wb.self_hash:08X}",
                "clip_count": len(wb.clips),
                "embedded_count": sum(1 for c in wb.clips if c.embedded),
                "streaming_count": sum(1 for c in wb.clips if c.streaming),
            }
            for wb in summary.wavebanks
        ],
        "results": [asdict(r) for r in summary.decoded],
        "counts": {
            "decoded": sum(1 for r in summary.decoded if r.status == "decoded"),
            "skipped_streaming": summary.skipped_streaming,
            "skipped_codec": summary.skipped_codec,
            "failed": summary.failed,
        },
    }
    sidecar.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    return sidecar


def _verify_wav_header(path: Path) -> bool:
    if not path.is_file() or path.stat().st_size < 44:
        return False
    head = path.read_bytes()[:12]
    return head[:4] == b"RIFF" and head[8:12] == b"WAVE"


def main() -> int:
    ap = argparse.ArgumentParser(description="Decode wavebank IMA ADPCM clips to WAV")
    src = ap.add_mutually_exclusive_group(required=True)
    src.add_argument("--block-bin", type=Path, help="Decompressed block .bin from extract_single_block")
    src.add_argument(
        "--extract-from-wad",
        action="store_true",
        help="Extract one block via extract_single_block.py then decode",
    )
    ap.add_argument("--wad", type=Path, default=REPO_ROOT / "game-files" / "pc-game-vz.wad")
    ap.add_argument("--block-index", type=int, default=None, help="FFCS block index (e.g. 33 for ui_hud)")
    ap.add_argument(
        "--path",
        type=str,
        default="ui_hud_P000_Q3",
        help="PTHS path substring when using --extract-from-wad (default: ui_hud)",
    )
    ap.add_argument(
        "--pipeline-root",
        type=Path,
        default=Path("output"),
        help="Pipeline output root (WAV tree under extracted/audio/wavebanks/)",
    )
    ap.add_argument("--wavebank-hash", type=lambda s: int(s, 0), default=None)
    ap.add_argument("--max-clips", type=int, default=None, help="Stop after N successful decodes")
    ap.add_argument("--dry-run", action="store_true", help="Parse only; do not write WAV")
    ap.add_argument(
        "--scratch-root",
        type=Path,
        default=REPO_ROOT / "output" / "_scratch",
        help="Scratch dir for WAD extraction (removed after success unless --keep-scratch)",
    )
    ap.add_argument("--keep-scratch", action="store_true", help="Retain scratch .block.bin after run")
    ap.add_argument("--sidecar", action="store_true", default=True, help="Write JSON summary (default on)")
    ap.add_argument("--no-sidecar", action="store_false", dest="sidecar")
    args = ap.parse_args()

    pipeline_root = args.pipeline_root.resolve()
    block_bin: Path | None = None
    scratch_used = False
    summary: ExtractSummary | None = None

    try:
        if args.extract_from_wad:
            scratch_used = True
            block_bin = extract_block_from_wad(
                args.wad.resolve(),
                block_index=args.block_index,
                path_query=args.path if args.block_index is None else None,
                scratch_root=args.scratch_root.resolve(),
            )
            print(f"Extracted block: {block_bin}")
        else:
            block_bin = args.block_bin.resolve()
            if not block_bin.is_file():
                raise SystemExit(f"--block-bin not found: {block_bin}")

        summary = extract_wavebanks_from_block(
            block_bin,
            pipeline_root,
            wavebank_hash=args.wavebank_hash,
            max_clips=args.max_clips,
            dry_run=args.dry_run,
        )

        decoded = [r for r in summary.decoded if r.status == "decoded"]
        print(f"Block: {block_bin.name}")
        print(f"  wavebanks: {len(summary.wavebanks)}")
        for wb in summary.wavebanks:
            emb = sum(1 for c in wb.clips if c.embedded)
            st = sum(1 for c in wb.clips if c.streaming)
            print(
                f"  wavebank 0x{wb.self_hash:08X}: {len(wb.clips)} records "
                f"({emb} embedded, {st} streaming)"
            )
        print(
            f"  decoded={len(decoded)} skipped_streaming={summary.skipped_streaming} "
            f"skipped_codec={summary.skipped_codec} failed={summary.failed}"
        )

        if decoded:
            first = pipeline_root / decoded[0].wav_path
            if _verify_wav_header(first):
                print(f"  WAV OK: {first} ({first.stat().st_size} bytes)")
            else:
                print(f"  WARN: WAV header check failed for {first}")

        if args.sidecar:
            sidecar = _write_sidecar(summary, pipeline_root, block_bin.stem)
            print(f"  sidecar: {sidecar}")

    finally:
        if scratch_used and not args.keep_scratch and args.scratch_root.is_dir():
            shutil.rmtree(args.scratch_root, ignore_errors=True)
            print(f"Cleaned scratch: {args.scratch_root}")

    if summary is None:
        return 1
    return 0 if not summary.failed else 1


if __name__ == "__main__":
    raise SystemExit(main())
