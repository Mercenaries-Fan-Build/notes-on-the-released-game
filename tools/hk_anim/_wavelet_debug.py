# -*- coding: utf-8 -*-
"""
Debug helpers for wavelet bitstream parity vs hkxcmd (optional).

Use :func:`peek_wavelet_header` on a carved ``.hkx`` ``patched_data`` blob to log the
HK550 wavelet header fields without running the full decode.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from hk_anim.wavelet import peek_wavelet_header


def write_wavelet_debug_stub(out: Path) -> None:
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(
        "# Wavelet debug stub — populate with hkxcmd XML dump paths + expected TRS vectors.\n",
        encoding="utf-8",
    )


def dump_wavelet_header_json(hkx_path: Path, out_json: Path) -> dict[str, Any] | None:
    """Write ``peek_wavelet_header`` JSON for a carved ``.hkx`` file."""
    from hk_packfile import load_packfile

    pf = load_packfile(hkx_path)
    hdr = peek_wavelet_header(pf.patched_data)
    if hdr is None:
        return None
    out_json.parent.mkdir(parents=True, exist_ok=True)
    out_json.write_text(json.dumps(hdr, indent=2), encoding="utf-8")
    return hdr


def pelvis_ty_track_spread(frames: list[Any]) -> dict[str, float] | None:
    """Min / max / spread of ``ty`` for transform track index 1 (common pelvis slot)."""
    if not frames or len(frames[0]) <= 1:
        return None
    tys = [float(fr[1].ty) for fr in frames]
    lo, hi = min(tys), max(tys)
    return {"ty_min": lo, "ty_max": hi, "ty_spread": hi - lo}


__all__ = [
    "write_wavelet_debug_stub",
    "dump_wavelet_header_json",
    "peek_wavelet_header",
    "pelvis_ty_track_spread",
]
