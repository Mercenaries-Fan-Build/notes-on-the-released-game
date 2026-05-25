"""Radius-zone manifest paths (shared by import_radius_zone / populate_radius_zone)."""

from __future__ import annotations

import json
import os
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_ZONE_JSON = REPO_ROOT / "output/radius_zones/pool_200m/zone.json"


def zone_json_path() -> Path:
    raw = os.environ.get("MERCS2_RADIUS_ZONE", "")
    return Path(raw) if raw else DEFAULT_ZONE_JSON


def output_root(zone_json: Path) -> Path:
    """``zone.json`` lives at ``<output>/radius_zones/<id>/zone.json``."""
    return zone_json.resolve().parent.parent.parent


def resolve_data_path(rel: str, zone_json: Path) -> Path:
    """Paths in zone.json are relative to the pipeline ``output/`` root."""
    p = Path(rel)
    if p.is_absolute():
        return p
    return output_root(zone_json) / rel


def load_zone(zone_json: Path | None = None) -> dict:
    zpath = zone_json or zone_json_path()
    return json.loads(zpath.read_text(encoding="utf-8"))
