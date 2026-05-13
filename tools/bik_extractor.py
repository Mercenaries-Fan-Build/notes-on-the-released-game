#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Convert Bink .bik videos to MP4 using ffmpeg (optional dependency)."""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path


def main() -> int:
    ap = argparse.ArgumentParser(description="Mercenaries 2 BIK → MP4 (ffmpeg)")
    ap.add_argument("--movies-dir", type=Path, required=True, help="Folder containing *.bik")
    ap.add_argument("--out-dir", type=Path, required=True)
    args = ap.parse_args()

    ffmpeg = shutil.which("ffmpeg")
    if not ffmpeg:
        print("error: ffmpeg not found on PATH", file=sys.stderr)
        return 1

    args.out_dir.mkdir(parents=True, exist_ok=True)
    n = 0
    for bik in sorted(args.movies_dir.glob("*.bik")):
        mp4 = args.out_dir / (bik.stem + ".mp4")
        subprocess.run(
            [ffmpeg, "-y", "-hide_banner", "-loglevel", "error", "-i", str(bik), "-c:v", "libx264", "-crf", "20", str(mp4)],
            check=True,
        )
        n += 1
        print(bik.name, "->", mp4.name)
    print(f"Converted {n} files -> {args.out_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
