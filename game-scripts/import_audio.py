"""Mercenaries 2 Recreation — batch SoundWave import from audio_ue5_manifest.json.

UE 5.7 Editor Python stub. Run after:
  1. ``python tools/wavebank_extractor.py`` (embedded wavebank → WAV)
  2. ``python tools/audio_ue5_manifest.py --pipeline-root ./output``

Prerequisites in Editor:
  - Editor Scripting Utilities (enabled via setup_project.py)
  - Interchange or legacy WAV importer available for your UE version

Run via:
    Tools → Execute Python Script → import_audio.py

Environment (optional):
  MERCS2_AUDIO_MANIFEST — path to audio_ue5_manifest.json
  MERCS2_AUDIO_PIPELINE — pipeline root (default: repo ``output/``)
  MERCS2_AUDIO_MAX_IMPORT — limit imports for smoke tests (integer)
"""

from __future__ import annotations

import json
import os
from pathlib import Path

import unreal

LOG_PREFIX = "[Mercs2ImportAudio]"


def _log(msg: str) -> None:
    unreal.log(f"{LOG_PREFIX} {msg}")


def _warn(msg: str) -> None:
    unreal.log_warning(f"{LOG_PREFIX} {msg}")


def _default_manifest_path() -> Path:
    env = os.environ.get("MERCS2_AUDIO_MANIFEST")
    if env:
        return Path(env)
    return (
        Path(__file__).resolve().parent.parent
        / "output"
        / "ue5_import"
        / "metadata"
        / "audio_ue5_manifest.json"
    )


def _default_pipeline_root() -> Path:
    env = os.environ.get("MERCS2_AUDIO_PIPELINE")
    if env:
        return Path(env)
    return Path(__file__).resolve().parent.parent / "output"


def _load_manifest(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def _iter_present_clips(manifest: dict, pipeline_root: Path):
    """Yield (wav_abs_path, ue5_sound_path) for clips with status present."""
    for _wb_key, wb in manifest.get("wavebanks", {}).items():
        for clip in wb.get("clips", []):
            if clip.get("status") != "present":
                continue
            rel = clip.get("extracted_wav") or clip.get("planned_wav")
            if not rel:
                continue
            wav = pipeline_root / rel
            if not wav.is_file():
                continue
            ue_path = str(clip.get("ue5_sound_path", ""))
            yield wav, ue_path


def _ensure_package_dir(ue_asset_path: str) -> None:
    """Ensure Content path exists for ``/Game/.../AssetName`` (package = parent folder)."""
    if not ue_asset_path.startswith("/Game/"):
        return
    parts = ue_asset_path.split("/")
    if len(parts) < 3:
        return
    package = "/".join(parts[:-1])
    if not unreal.EditorAssetLibrary.does_directory_exist(package):
        unreal.EditorAssetLibrary.make_directory(package)


def _import_wav_interchange(wav_path: Path, destination_path: str) -> bool:
    """Import one WAV via Interchange when the API is available."""
    try:
        import_path = str(wav_path.resolve())
        task = unreal.AssetImportTask()
        task.set_editor_property("filename", import_path)
        task.set_editor_property("destination_path", destination_path)
        task.set_editor_property("destination_name", Path(destination_path).name)
        task.set_editor_property("replace_existing", True)
        task.set_editor_property("automated", True)
        task.set_editor_property("save", True)
        unreal.AssetToolsHelpers.get_asset_tools().import_asset_tasks([task])
        return True
    except Exception as exc:  # noqa: BLE001 — UE API surface varies by minor version
        _warn(f"Interchange import failed for {wav_path.name}: {exc}")
        return False


def run() -> None:
    manifest_path = _default_manifest_path()
    pipeline_root = _default_pipeline_root()
    max_import = int(os.environ.get("MERCS2_AUDIO_MAX_IMPORT", "0") or "0")

    _log("=" * 60)
    _log("Audio import (manifest-driven SoundWave batch)")
    _log("=" * 60)

    if not manifest_path.is_file():
        _warn(
            f"Manifest not found: {manifest_path}\n"
            "  1. python tools/wavebank_extractor.py --extract-from-wad ...\n"
            "  2. python tools/audio_ue5_manifest.py --pipeline-root ./output"
        )
        return

    manifest = _load_manifest(manifest_path)
    summary = manifest.get("summary", {})
    _log(
        f"Manifest: {summary.get('clips_total', 0)} clips, "
        f"{summary.get('clips_present', 0)} present on disk"
    )

    imported = 0
    skipped = 0
    for wav_path, ue_sound_path in _iter_present_clips(manifest, pipeline_root):
        if max_import and imported >= max_import:
            break
        if not ue_sound_path.startswith("/Game/"):
            skipped += 1
            continue
        _ensure_package_dir(ue_sound_path)
        dest_package = "/".join(ue_sound_path.split("/")[:-1])
        dest_name = ue_sound_path.split("/")[-1]
        dest_full = f"{dest_package}/{dest_name}"

        if unreal.EditorAssetLibrary.does_asset_exist(dest_full):
            _log(f"  exists  {dest_full}")
            imported += 1
            continue

        ok = _import_wav_interchange(wav_path, dest_package)
        if ok:
            _log(f"  import  {wav_path.name} → {dest_full}")
            imported += 1
        else:
            skipped += 1

    _log("=" * 60)
    if imported == 0 and skipped == 0:
        _warn(
            "No clips with status=present. Decode wavebanks first, then re-run audio_ue5_manifest.py."
        )
    else:
        _log(f"Done: imported_or_existing={imported} skipped={skipped}")
    _log("=" * 60)
    _log("Manual fallback (if Interchange import fails):")
    _log("  1. Content Browser → Mercs2/Audio/Wavebanks/{bank}/")
    _log("  2. Import WAV from output/extracted/audio/wavebanks/{hash}/clip_*.wav")
    _log("  3. Set Sample Rate from manifest clip sample_rate; enable mono/stereo")
    _log("  4. Create SoundCue or MetaSound referencing each SoundWave")
    _log("  5. Map soundbank event hashes via DataTable (event_hash → SoftObjectPath)")


if __name__ == "__main__":
    run()
