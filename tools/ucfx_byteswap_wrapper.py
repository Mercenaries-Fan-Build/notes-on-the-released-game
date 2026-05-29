"""Wrapper to call the Rust ucfx_byteswap binary from Python.

Provides a drop-in replacement for the byte-swap step in the DLC port
pipeline.  The Rust binary handles the structural BE→LE conversion;
entry-level overrides and type-hash stripping remain in Python.
"""
from __future__ import annotations

import subprocess
import shutil
from pathlib import Path

_BINARY_NAME = "ucfx_byteswap"
_SEARCH_PATHS = [
    Path(__file__).resolve().parent / "wad_simulator" / "target" / "release" / _BINARY_NAME,
    Path(__file__).resolve().parent / "wad_simulator" / "target" / "debug" / _BINARY_NAME,
]


def _find_binary() -> Path | None:
    """Locate the ucfx_byteswap binary, or return None if not found."""
    found = shutil.which(_BINARY_NAME)
    if found:
        return Path(found)
    for p in _SEARCH_PATHS:
        for ext in ("", ".exe"):
            candidate = p.with_suffix(ext) if ext else p
            if candidate.exists():
                return candidate
    return None


def rust_binary_available() -> bool:
    """Return True if the Rust ucfx_byteswap binary can be found."""
    return _find_binary() is not None


def byteswap_block_rust(
    block_data: bytes,
    *,
    validate: bool = True,
    strict: bool = False,
) -> bytes:
    """Convert a single decompressed Xbox 360 BE block to PC LE using the Rust binary.

    Args:
        block_data: Raw decompressed BE block bytes.
        validate: Run post-conversion validation (default True).
        strict: Fail on validation errors (default False).

    Returns:
        Converted LE block bytes.

    Raises:
        FileNotFoundError: If the binary is not found.
        RuntimeError: If the binary fails or strict validation finds errors.
    """
    binary = _find_binary()
    if binary is None:
        raise FileNotFoundError(
            f"ucfx_byteswap binary not found. Build with: "
            f"cargo build --release -p ucfx_byteswap"
        )

    cmd = [str(binary), "--stdin", "--stdout"]
    if not validate:
        cmd.append("--no-validate")
    if strict:
        cmd.append("--strict")

    result = subprocess.run(
        cmd,
        input=block_data,
        capture_output=True,
    )
    if result.returncode != 0:
        stderr = result.stderr.decode("utf-8", errors="replace")
        raise RuntimeError(
            f"ucfx_byteswap failed (exit {result.returncode}): {stderr}"
        )

    return result.stdout
