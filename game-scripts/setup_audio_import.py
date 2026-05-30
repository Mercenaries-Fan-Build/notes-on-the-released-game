"""Mercenaries 2 Recreation — Audio import directory scaffold.

UE 5.7 Editor Python stub that creates the Content/Audio tree expected by
``tools/audio_ue5_manifest.py`` and ``docs/audio_ue5_path.md``.

Does **not** import WAV/OGG assets yet — only folders. Next step:
  - Run ``game-scripts/import_audio.py`` after ``wavebank_extractor.py`` + ``audio_ue5_manifest.py``
  - Wire attenuation presets for vehicle/weapons/VO categories

Idempotent: re-running skips existing directories.

Run via:
    Tools → Execute Python Script → setup_audio_import.py
    Or step 6 of setup_all.py (after basic_hud, before weather).
"""

from __future__ import annotations

import json
from pathlib import Path

import unreal

LOG_PREFIX = "[Mercs2Audio]"

# Must stay aligned with tools/audio_ue5_manifest.py ``_UE5_AUDIO_ROOT`` subtree.
AUDIO_DIRECTORIES = [
    "/Game/Mercs2/Audio/Wavebanks",
    "/Game/Mercs2/Audio/Soundbanks",
    "/Game/Mercs2/Audio/Streams",
    "/Game/Mercs2/Audio/Music",
    "/Game/Mercs2/Audio/MetaSounds",
    "/Game/Mercs2/Audio/Attenuation",
    "/Game/Mercs2/Audio/Classes",
    "/Game/Mercs2/Audio/Concurrency",
]


def _log(msg: str) -> None:
    unreal.log(f"{LOG_PREFIX} {msg}")


def _warn(msg: str) -> None:
    unreal.log_warning(f"{LOG_PREFIX} {msg}")


def _ensure_directory(content_path: str) -> None:
    if unreal.EditorAssetLibrary.does_directory_exist(content_path):
        _log(f"  exists  {content_path}")
    else:
        unreal.EditorAssetLibrary.make_directory(content_path)
        _log(f"  created {content_path}")


def _log_manifest_hint() -> None:
    """If a pipeline manifest exists on disk, log readiness stats for the user."""
    # Typical path when repo sits beside UnrealEngineGame/ — adjust if needed.
    candidates = [
        Path(__file__).resolve().parent.parent / "output" / "ue5_import" / "metadata" / "audio_ue5_manifest.json",
    ]
    for path in candidates:
        if not path.is_file():
            continue
        try:
            raw = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            _warn(f"Could not parse manifest: {path}")
            return
        summary = raw.get("summary", {})
        readiness = raw.get("ue5_import", {}).get("readiness", {})
        _log(
            f"Manifest {path.name}: "
            f"{summary.get('clips_total', 0)} clips, "
            f"{readiness.get('pending_wav_decode', '?')} pending decode"
        )
        return
    _warn(
        "No audio_ue5_manifest.json found — run: "
        "python tools/audio_ue5_manifest.py --pipeline-root ./output"
    )


def run() -> None:
    _log("=" * 60)
    _log("Audio import scaffold (directories only)")
    _log("=" * 60)

    for directory in AUDIO_DIRECTORIES:
        _ensure_directory(directory)

    _log_manifest_hint()

    _log("=" * 60)
    _log("Audio directories ready. WAV import not implemented yet.")
    _log("=" * 60)


if __name__ == "__main__":
    run()
