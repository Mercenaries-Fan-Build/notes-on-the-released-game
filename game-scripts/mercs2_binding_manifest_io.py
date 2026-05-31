"""Load Game→UE binding manifest (no unreal dependency).

Used by ``populate_world`` (visibility fallback) and ``mercs2_binding_apply``.
"""

from __future__ import annotations

import json
import os
from pathlib import Path
from typing import Any, Literal

Visibility = Literal["visible", "hidden", "skip"]

_REPO_ROOT = Path(__file__).resolve().parent.parent
_DEFAULT_MANIFEST = _REPO_ROOT / "output" / "ue5_import" / "ue_game_binding.json"

_manifest_cache: dict[str, Any] | None = None
_manifest_path_loaded: Path | None = None


def default_manifest_path() -> Path:
    env = os.environ.get("MERCS2_BINDING_MANIFEST", "").strip()
    if env:
        return Path(env)
    output = os.environ.get("MERCS2_OUTPUT", "").strip()
    if output:
        return Path(output) / "ue5_import" / "ue_game_binding.json"
    return _DEFAULT_MANIFEST


def load_manifest(path: Path | None = None, *, force_reload: bool = False) -> dict[str, Any] | None:
    """Load manifest JSON; return None if missing or invalid."""
    global _manifest_cache, _manifest_path_loaded
    resolved = (path or default_manifest_path()).resolve()
    if (
        not force_reload
        and _manifest_cache is not None
        and _manifest_path_loaded == resolved
    ):
        return _manifest_cache
    if not resolved.is_file():
        _manifest_cache = None
        _manifest_path_loaded = resolved
        return None
    try:
        doc = json.loads(resolved.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        _manifest_cache = None
        _manifest_path_loaded = resolved
        return None
    if not isinstance(doc, dict) or doc.get("schema_version") != 1:
        _manifest_cache = None
        _manifest_path_loaded = resolved
        return None
    _manifest_cache = doc
    _manifest_path_loaded = resolved
    return doc


def placement_visibility_from_manifest(
    placement: dict[str, Any],
    manifest: dict[str, Any] | None,
) -> Visibility | None:
    """Return visibility from manifest or None to use legacy classify_visibility."""
    if manifest is None:
        return None
    entity = str(placement.get("entity_name") or "")
    rules = manifest.get("placement_visibility")
    if isinstance(rules, dict):
        src = str(placement.get("source", ""))
        if src in rules:
            v = rules[src]
            if v in ("visible", "hidden", "skip"):
                return v  # type: ignore[return-value]
    # layers_static default
    source = str(placement.get("source", "")).lower()
    if not source or "layers_static" in source:
        if placement.get("block_type") == "layers_static" or "layers_static" in source:
            return "visible"
    # vz_state: lookup overlay binding by source
    for binding in manifest.get("bindings") or []:
        if binding.get("kind") != "vz_overlay":
            continue
        gs = binding.get("game_source") or {}
        if gs.get("source") == placement.get("source"):
            fields = binding.get("fields") or {}
            pv = fields.get("placement_visibility")
            if pv in ("visible", "hidden", "skip"):
                return pv  # type: ignore[return-value]
            rd = binding.get("runtime_default")
            if rd == "activated":
                return "visible"
            if rd == "unloaded":
                return "hidden"
    # vz overlay fallback from source string
    if "pristine" in source:
        return "visible"
    if any(t in source for t in ("ruined", "destroyed", "rubble", "staging", "combat", "defenses", "act1", "act2", "act3")):
        return "hidden"
    if source and "vz_state" in source:
        return "hidden"
    return None


def visibility_preset_name(manifest: dict[str, Any] | None) -> str:
    if manifest is None:
        return "act1_default"
    presets = manifest.get("presets") or {}
    return str(presets.get("visibility_default") or "act1_default")
