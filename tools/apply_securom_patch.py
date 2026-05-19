#!/usr/bin/env python3
"""Apply binary patch to remove SecuROM from Mercenaries 2 retail EXE.

Supports both v1.0 (original disc, 17MB SecuROM-packed) and v1.1 (update, 51MB).
Auto-detects the input version by file size and MD5, then applies the appropriate
patches in sequence:

  v1.0 retail → [update patch] → v1.1 retail → [crack patch] → cracked
  v1.1 retail → [crack patch] → cracked

Patches are stored as bsdiff deltas in tools/patches/ — no game code is
redistributed.

After patching, cruise.dll is generated alongside the output (it creates the
Win32 Event that inline SecuROM trigger checks look for).

Usage:
  python3 tools/apply_securom_patch.py <retail_exe> [-o <output>]
  python3 tools/apply_securom_patch.py --generate-patch <retail> <cracked> -o <patch_file>

Requirements:
  - Python 3.12+ (stdlib only for patching; bsdiff4 only needed for --generate-patch)
"""
from __future__ import annotations

import argparse
import hashlib
import sys
from pathlib import Path

# --- Known EXE versions ---

RETAIL_V10_SIZE = 17_122_568
RETAIL_V10_MD5 = "596efbf5e6c88924acef1fd8b0891012"

RETAIL_V11_SIZE = 53_944_080
RETAIL_V11_MD5 = "5b9976f162e050f4adcc51bb997ba97f"

CRACKED_SIZE = 53_482_288
CRACKED_MD5 = "857b3387d54774a32c1328effb5de4d4"

# --- Patch files ---

PATCHES_DIR = Path(__file__).parent / "patches"
PATCH_V10_TO_V11 = PATCHES_DIR / "mercs2_v1.0_to_v1.1_update.bspatch"
PATCH_V11_TO_CRACKED = PATCHES_DIR / "mercs2_v1.1_securom_bypass.bspatch"


def compute_md5(data: bytes) -> str:
    return hashlib.md5(data).hexdigest()


def verify_md5(data: bytes, expected: str, label: str) -> bool:
    actual = compute_md5(data)
    if actual != expected:
        print(f"WARNING: {label} MD5 mismatch")
        print(f"  Expected: {expected}")
        print(f"  Got:      {actual}")
        return False
    return True


def detect_version(data: bytes) -> str | None:
    """Detect EXE version by size and MD5. Returns 'v1.0', 'v1.1', 'cracked', or None."""
    size = len(data)
    md5 = compute_md5(data)

    if size == RETAIL_V10_SIZE and md5 == RETAIL_V10_MD5:
        return "v1.0"
    if size == RETAIL_V11_SIZE and md5 == RETAIL_V11_MD5:
        return "v1.1"
    if size == CRACKED_SIZE and md5 == CRACKED_MD5:
        return "cracked"

    # Fallback: detect by size alone (MD5 may differ for regional variants)
    if size == RETAIL_V10_SIZE:
        return "v1.0"
    if size == RETAIL_V11_SIZE:
        return "v1.1"
    if size == CRACKED_SIZE:
        return "cracked"

    return None


def generate_cruise_dll() -> bytes:
    """Generate minimal cruise.dll — creates the SecuROM spoof Event."""
    sys.path.insert(0, str(Path(__file__).parent))
    from remove_securom import generate_cruise_dll as _gen
    return _gen()


def _find_bspatch() -> str:
    """Locate bspatch executable. Checks bundled tools/bin/, PATH, then bsdiff4."""
    import shutil

    bin_dir = Path(__file__).parent / "bin"
    if sys.platform == "win32":
        bundled = bin_dir / "bspatch.exe"
    else:
        bundled = bin_dir / "bspatch"

    if bundled.exists():
        return str(bundled)

    system = shutil.which("bspatch")
    if system:
        return system

    return ""


def _apply_bsdiff(source: bytes, patch_file: Path, label: str, verbose: bool) -> bytes:
    """Apply a single bsdiff patch using external bspatch binary or bsdiff4."""
    import subprocess
    import tempfile

    if not patch_file.exists():
        print(f"ERROR: Patch file not found: {patch_file}")
        sys.exit(1)

    if verbose:
        print(f"  Patch: {patch_file.name} ({patch_file.stat().st_size:,} bytes)")
        print(f"  Applying {label}...")

    bspatch_exe = _find_bspatch()

    if bspatch_exe:
        if verbose:
            print(f"  Using: {bspatch_exe}")
        with tempfile.TemporaryDirectory() as td:
            src_path = Path(td) / "source.bin"
            out_path = Path(td) / "output.bin"
            src_path.write_bytes(source)
            try:
                subprocess.run(
                    [bspatch_exe, str(src_path), str(out_path), str(patch_file)],
                    check=True, capture_output=True,
                )
            except subprocess.CalledProcessError as e:
                print(f"ERROR: {label} failed: {e.stderr.decode(errors='replace')}")
                sys.exit(1)
            except FileNotFoundError:
                print(f"ERROR: bspatch not found at {bspatch_exe}")
                sys.exit(1)
            result = out_path.read_bytes()
    else:
        try:
            import bsdiff4
            patch_data = patch_file.read_bytes()
            result = bsdiff4.patch(source, patch_data)
        except ImportError:
            print("ERROR: No bspatch binary found and bsdiff4 package not installed.")
            print()
            print("  Option A: Place bspatch binary in tools/bin/")
            if sys.platform == "win32":
                print("            e.g. tools/bin/bspatch.exe")
            else:
                print("            e.g. tools/bin/bspatch")
            print("  Option B: Install bspatch to PATH")
            if sys.platform == "win32":
                print("            e.g. scoop install bsdiff")
            else:
                print("            e.g. brew install bsdiff  (macOS)")
                print("            e.g. apt install bsdiff   (Debian/Ubuntu)")
            print("  Option C: pip install bsdiff4")
            sys.exit(1)
        except Exception as e:
            print(f"ERROR: {label} failed: {e}")
            sys.exit(1)

    if verbose:
        print(f"  Result: {len(result):,} bytes")
    return result


def apply_patch(input_exe: Path, output_exe: Path,
                generate_cruise: bool = True, verbose: bool = True) -> None:
    if not input_exe.exists():
        print(f"ERROR: Input EXE not found: {input_exe}")
        sys.exit(1)

    retail_data = input_exe.read_bytes()
    version = detect_version(retail_data)

    if verbose:
        print(f"Input:  {input_exe} ({len(retail_data):,} bytes)")
        print(f"Output: {output_exe}")
        print(f"Detected version: {version or 'UNKNOWN'}")
        print()

    if version == "cracked":
        print("Input is already the cracked EXE — nothing to do.")
        print(f"  MD5: {CRACKED_MD5}")
        return

    if version == "v1.0":
        if verbose:
            print("Step 1/2: Updating v1.0 → v1.1...")
        retail_data = _apply_bsdiff(retail_data, PATCH_V10_TO_V11,
                                    "v1.0 → v1.1 update", verbose)
        if not verify_md5(retail_data, RETAIL_V11_MD5, "v1.1 intermediate"):
            print("WARNING: v1.0→v1.1 patch produced unexpected output.")
            print("  Continuing with crack patch anyway...")
        elif verbose:
            print("  VERIFIED: v1.1 intermediate matches expected")
        if verbose:
            print()
            print("Step 2/2: Applying SecuROM bypass (v1.1 → cracked)...")
    elif version == "v1.1":
        if verbose:
            print("Applying SecuROM bypass (v1.1 → cracked)...")
    else:
        print(f"WARNING: Unrecognized EXE version (size={len(retail_data):,})")
        print("  Known versions:")
        print(f"    v1.0 retail: {RETAIL_V10_SIZE:,} bytes (SecuROM packed, original disc)")
        print(f"    v1.1 retail: {RETAIL_V11_SIZE:,} bytes (update from EA)")
        print(f"    cracked:     {CRACKED_SIZE:,} bytes")
        print()
        print("  Attempting v1.1→cracked patch anyway...")
        print()

    result = _apply_bsdiff(retail_data, PATCH_V11_TO_CRACKED,
                           "v1.1 → cracked", verbose)

    if verbose:
        print()
        print("Verifying output...")
    if verify_md5(result, CRACKED_MD5, "Patched output"):
        if verbose:
            print("  VERIFIED: Output matches expected cracked EXE")
    else:
        print("WARNING: Output MD5 doesn't match expected. Patch may be corrupt.")

    output_exe.parent.mkdir(parents=True, exist_ok=True)
    output_exe.write_bytes(result)
    if verbose:
        print(f"\nWritten: {output_exe} ({len(result):,} bytes)")

    if generate_cruise:
        cruise_path = output_exe.parent / "cruise.dll"
        cruise_data = generate_cruise_dll()
        cruise_path.write_bytes(cruise_data)
        if verbose:
            print(f"Written: {cruise_path} ({len(cruise_data):,} bytes)")
            print("  Creates Event: v7_XXXX (PID XOR 0x19EA3FD3)")
            print("  bManualReset=TRUE, bInitialState=TRUE (signaled)")

    if verbose:
        print()
        print("Done! Copy these to your game install directory:")
        print(f"  {output_exe}")
        if generate_cruise:
            print(f"  {output_exe.parent / 'cruise.dll'}")


def generate_patch_file(retail_exe: Path, cracked_exe: Path, output_patch: Path,
                        verbose: bool = True) -> None:
    """Generate a bsdiff patch from retail → cracked (for maintainer use)."""
    try:
        import bsdiff4
    except ImportError:
        print("ERROR: bsdiff4 package required.")
        sys.exit(1)

    if verbose:
        print(f"Source: {retail_exe}")
        print(f"Target: {cracked_exe}")
        print(f"Output: {output_patch}")
        print()

    retail_data = retail_exe.read_bytes()
    cracked_data = cracked_exe.read_bytes()

    if verbose:
        print(f"Source size: {len(retail_data):,}")
        print(f"Target size: {len(cracked_data):,}")
        print(f"Source MD5:  {compute_md5(retail_data)}")
        print(f"Target MD5:  {compute_md5(cracked_data)}")
        print()
        print("Generating bsdiff patch (this may take ~30-60 seconds)...")

    patch_data = bsdiff4.diff(retail_data, cracked_data)

    if verbose:
        print(f"  Patch size: {len(patch_data):,} bytes ({len(patch_data)/1024/1024:.1f} MB)")

    output_patch.parent.mkdir(parents=True, exist_ok=True)
    output_patch.write_bytes(patch_data)

    if verbose:
        print(f"  Written to: {output_patch}")
        print()
        print("Verifying round-trip...")

    result = bsdiff4.patch(retail_data, patch_data)
    assert result == cracked_data, "MISMATCH: patch does not reproduce target"

    if verbose:
        print("  VERIFIED: patch(source) == target")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Apply binary patch to remove SecuROM from Mercenaries 2 EXE. "
                    "Auto-detects v1.0 (17MB) or v1.1 (51MB) and applies the "
                    "appropriate patches.")

    parser.add_argument("input", help="Path to retail Mercenaries2.exe (v1.0 or v1.1)")
    parser.add_argument("--output", "-o",
                        help="Output path (default: <input_dir>/Mercenaries2-Patched.exe)")
    parser.add_argument("--no-cruise", action="store_true",
                        help="Don't generate cruise.dll")
    parser.add_argument("--quiet", "-q", action="store_true")
    parser.add_argument("--generate-patch", metavar="TARGET_EXE",
                        help="Generate patch mode: INPUT is source, this arg is target EXE, "
                             "--output is required for patch file destination")

    args = parser.parse_args()

    if args.generate_patch:
        if not args.output:
            parser.error("--output is required when using --generate-patch")
        generate_patch_file(
            retail_exe=Path(args.input),
            cracked_exe=Path(args.generate_patch),
            output_patch=Path(args.output),
            verbose=not args.quiet,
        )
    else:
        input_exe = Path(args.input)
        if args.output:
            output_exe = Path(args.output)
        else:
            output_exe = input_exe.parent / (input_exe.stem + "-Patched.exe")

        apply_patch(
            input_exe=input_exe,
            output_exe=output_exe,
            generate_cruise=not args.no_cruise,
            verbose=not args.quiet,
        )


if __name__ == "__main__":
    main()
