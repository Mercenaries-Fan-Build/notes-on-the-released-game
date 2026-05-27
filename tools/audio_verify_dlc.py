#!/usr/bin/env python3
"""Fail-fast DLC audio verification gate (manifest + structure + simulator).

Runs the audio pipeline checks in order:
  1. Build dlc_audio_manifest.json
  2. Wavebank/soundbank structural validation
  3. wad_simulator --audio-only (when built)

Usage:
    python tools/audio_verify_dlc.py --output ./output
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

THIS_DIR = Path(__file__).resolve().parent
REPO_ROOT = THIS_DIR.parent


def _run(cmd: list[str], *, cwd: Path | None = None) -> int:
    print(f"  $ {' '.join(cmd)}")
    return subprocess.call(cmd, cwd=cwd)


def main() -> int:
    ap = argparse.ArgumentParser(description="DLC audio verification gate")
    ap.add_argument("--output", type=Path, default=REPO_ROOT / "output")
    ap.add_argument("--patch-wad", type=Path, default=None)
    ap.add_argument("--base-wad", type=Path, default=None)
    ap.add_argument("--skip-simulator", action="store_true")
    args = ap.parse_args()

    patch_wad = args.patch_wad or (args.output / "data" / "vz-patch.wad")
    audios_dir = args.output / "data" / "Audios"
    manifest_path = args.output / "analysis" / "dlc_audio_manifest.json"

    if not patch_wad.is_file():
        print(f"ERROR: patch WAD missing: {patch_wad}", file=sys.stderr)
        return 1

    py = sys.executable
    rc = 0

    print("=== 1/3 DLC audio manifest ===")
    manifest_rc = _run([
        py,
        str(THIS_DIR / "dlc_audio_manifest.py"),
        "--patch-wad",
        str(patch_wad),
        "--audios-dir",
        str(audios_dir),
        "--output",
        str(manifest_path),
    ])
    if manifest_rc != 0:
        rc = manifest_rc

    print("\n=== 2/3 Wavebank/soundbank structure ===")
    struct_rc = _run([py, str(THIS_DIR / "_validate_audio_blocks.py"), str(patch_wad)])
    if struct_rc != 0:
        rc = struct_rc

    if not args.skip_simulator:
        print("\n=== 3/3 wad_simulator (audio-only) ===")
        sim_bin = REPO_ROOT / "tools" / "wad_simulator" / "target" / "release" / "wad_simulator"
        if not sim_bin.is_file():
            print("  Building wad_simulator (release)...")
            build_rc = _run(
                ["cargo", "build", "--release"],
                cwd=REPO_ROOT / "tools" / "wad_simulator",
            )
            if build_rc != 0:
                print("  WARN: cargo build failed; skipping simulator", file=sys.stderr)
                args.skip_simulator = True
            else:
                sim_bin = REPO_ROOT / "tools" / "wad_simulator" / "target" / "release" / "wad_simulator.exe"
                if not sim_bin.is_file():
                    sim_bin = REPO_ROOT / "tools" / "wad_simulator" / "target" / "release" / "wad_simulator"

        if not args.skip_simulator and sim_bin.is_file():
            sim_cmd = [
                str(sim_bin),
                "--wad",
                str(patch_wad),
                "--audio-only",
                "--skip-aset",
                "--audio-manifest",
                str(manifest_path),
            ]
            if audios_dir.is_dir():
                sim_cmd.extend(["--audios-dir", str(audios_dir)])
            if args.base_wad and args.base_wad.is_file():
                sim_cmd.extend(["--base-wad", str(args.base_wad)])
            sim_rc = _run(sim_cmd, cwd=REPO_ROOT)
            if sim_rc != 0:
                rc = sim_rc
        else:
            print("  SKIP: wad_simulator binary not found")

    if manifest_path.is_file():
        summary = json.loads(manifest_path.read_text(encoding="utf-8")).get("summary", {})
        bad_codecs = summary.get("codec_histogram", {})
        if bad_codecs.get("XMA") or bad_codecs.get("XBOX_ADPCM"):
            print(
                "\nWARN: manifest still reports Xbox-native codecs — re-run make dlc-port",
                file=sys.stderr,
            )
            rc = rc or 1

    print(f"\n{'PASS' if rc == 0 else 'FAIL'}: audio-verify-dlc (exit {rc})")
    return rc


if __name__ == "__main__":
    sys.exit(main())
