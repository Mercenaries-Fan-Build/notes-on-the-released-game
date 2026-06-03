"""Wrapper to call the Rust ucfx_byteswap binary from Python.

Provides a drop-in replacement for the byte-swap step in the DLC port
pipeline.  The Rust binary handles the full structural BE→LE conversion
(all chunk tags and type_hashes) for decompressed Xbox 360 blocks.
"""
from __future__ import annotations

import subprocess
import shutil
import sys
from pathlib import Path

_BINARY_NAME = "ucfx_byteswap"
_SEARCH_PATHS = [
    Path(__file__).resolve().parent / "wad_simulator" / "target" / "release" / _BINARY_NAME,
    Path(__file__).resolve().parent / "wad_simulator" / "target" / "debug" / _BINARY_NAME,
]
_CRATE_SRC = (
    Path(__file__).resolve().parent / "wad_simulator" / "crates" / "ucfx_byteswap" / "src"
)
_STALENESS_WARNED = False


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


def _warn_if_stale(binary: Path) -> None:
    """Warn (once) if the compiled binary predates its Rust source.

    A stale ``target/release/ucfx_byteswap`` silently runs old machine code even
    when the source (and git hash) contain a fix — the exact trap that produced
    a buggy EFCT layout despite a fixed ``convert.rs``. Direct ``dlc_port.py``
    invocations do not run ``cargo build``; this guard makes the staleness loud.
    """
    global _STALENESS_WARNED
    if _STALENESS_WARNED or not _CRATE_SRC.is_dir():
        return
    try:
        bin_mtime = binary.stat().st_mtime
        newest_src = max(
            (p.stat().st_mtime for p in _CRATE_SRC.rglob("*.rs")),
            default=0.0,
        )
    except OSError:
        return
    if newest_src > bin_mtime:
        _STALENESS_WARNED = True
        print(
            f"WARNING: {binary.name} ({binary}) is OLDER than its Rust source in "
            f"{_CRATE_SRC}. The compiled binary may not contain recent fixes. "
            f"Rebuild with: cargo build --release -p ucfx_byteswap "
            f"(or: make build-ucfx-byteswap).",
            file=sys.stderr,
        )


def rust_binary_available() -> bool:
    """Return True if the Rust ucfx_byteswap binary can be found."""
    return _find_binary() is not None


def validate_block_rust(
    block_data: bytes,
    *,
    strict: bool = False,
) -> list[str]:
    """Validate a PC LE block (CSUM, DEPS, SKIN, watr, fxdict, IBUF bounds).

    Returns a list of warning strings (empty if OK). Raises on binary missing or
    subprocess failure; exits non-zero in strict mode when issues are found.
    """
    binary = _find_binary()
    if binary is None:
        raise FileNotFoundError(
            f"ucfx_byteswap binary not found. Build with: "
            f"cargo build --release -p ucfx_byteswap  (or: make build-ucfx-byteswap)"
        )

    cmd = [str(binary), "--stdin", "--validate-only"]
    if strict:
        cmd.append("--strict")

    result = subprocess.run(
        cmd,
        input=block_data,
        capture_output=True,
    )
    if result.returncode == 0:
        return []
    stderr = result.stderr.decode("utf-8", errors="replace")
    if result.returncode == 2:
        raise RuntimeError(f"ucfx_byteswap strict validation failed:\n{stderr}")
    warnings: list[str] = []
    for line in stderr.splitlines():
        line = line.strip()
        if line.startswith("WARN:"):
            warnings.append(line[5:].strip())
        elif "issue(s) found" in line or line.startswith("Validation:"):
            continue
        elif line and not line.startswith("ucfx_byteswap:"):
            warnings.append(line)
    if not warnings and stderr.strip():
        warnings.append(stderr.strip())
    return warnings


def validate_block_file_rust(path: Path, *, strict: bool = False) -> list[str]:
    """Validate a decompressed .block.bin on disk."""
    return validate_block_rust(path.read_bytes(), strict=strict)


def byteswap_block_python(
    block_data: bytes,
    *,
    permissive: bool = False,
) -> bytes:
    """Convert BE block to LE using Python ``ucfx_be_to_le`` (ECS-aware)."""
    from ucfx_be_to_le import byteswap_ucfx_block

    le_data, _stats = byteswap_ucfx_block(block_data, permissive=permissive)
    return le_data


def byteswap_block_ecs_python_fallback(
    block_data: bytes,
    *,
    permissive: bool = False,
) -> bytes:
    """Rust byteswap with Python fallback when Rust fails on an ECS-heavy block."""
    try:
        return byteswap_block_rust(block_data, validate=False)
    except (RuntimeError, FileNotFoundError):
        return byteswap_block_python(block_data, permissive=permissive)


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
    _warn_if_stale(binary)

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
