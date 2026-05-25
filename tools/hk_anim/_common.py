# -*- coding: utf-8 -*-
"""Shared animation intermediate representation (IR)."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any


@dataclass
class TRS:
    tx: float
    ty: float
    tz: float
    qx: float
    qy: float
    qz: float
    qw: float
    sx: float
    sy: float
    sz: float


@dataclass
class AnimationIR:
    name: str
    duration: float
    fps: float
    bone_names: list[str]
    frames: list[list[TRS]] = field(default_factory=list)
    float_tracks: list[list[float]] = field(default_factory=list)
    annotations: list[tuple[float, str]] = field(default_factory=list)
    source_class: str = ""
    meta: dict[str, Any] = field(default_factory=dict)

    def to_json_dict(self) -> dict[str, Any]:
        return {
            "name": self.name,
            "duration": self.duration,
            "fps": self.fps,
            "bone_names": self.bone_names,
            "frame_count": len(self.frames),
            "bone_count": len(self.bone_names),
            "source_class": self.source_class,
            "annotations": [{"t": t, "text": s} for t, s in self.annotations],
            "meta": self.meta,
        }


def harvest_annotation_strings(blob: bytes) -> list[tuple[float, str]]:
    """Harvest ``>event_name`` style markers; times default to 0 without full track parse."""
    out: list[tuple[float, str]] = []
    i = 0
    while True:
        j = blob.find(b">", i)
        if j < 0 or j + 1 >= len(blob):
            break
        k = j + 1
        while k < len(blob) and (
            blob[k] in b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_"
        ):
            k += 1
        if k - j - 1 >= 3:
            out.append((0.0, blob[j + 1 : k].decode("ascii", errors="replace")))
        i = k + 1
    return out
