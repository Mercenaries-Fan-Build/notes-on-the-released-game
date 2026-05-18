#!/usr/bin/env python3
"""Apply binary patch to remove SecuROM from Mercenaries 2 retail v1.1 EXE.

This applies a pre-computed bsdiff patch that transforms the retail SecuROM-
protected executable into a working cracked version. The patch file contains
only the binary delta — no game code is redistributed.

After patching, cruise.dll is generated alongside the output (it creates the
Win32 Event that inline SecuROM trigger checks look for).

Usage:
  python3 tools/apply_securom_patch.py <retail_v1.1_exe> [-o <output>]
  python3 tools/apply_securom_patch.py --generate-patch <retail> <cracked> -o <patch_file>

Requirements:
  - bsdiff4 Python package (pip install bsdiff4)
  - The retail v1.1 EXE (MD5: 5b9976f162e050f4adcc51bb997ba97f)
"""
from __future__ import annotations

import argparse
import hashlib
import sys
from pathlib import Path

RETAIL_V11_MD5 = "5b9976f162e050f4adcc51bb997ba97f"
CRACKED_MD5 = "857b3387d54774a32c1328effb5de4d4"
RETAIL_V11_SIZE = 53_944_080

PATCH_FILE = Path(__file__).parent / "patches" / "mercs2_v1.1_securom_bypass.bspatch"


def verify_md5(data: bytes, expected: str, label: str) -> bool:
    actual = hashlib.md5(data).hexdigest()
    if actual != expected:
        print(f"WARNING: {label} MD5 mismatch")
        print(f"  Expected: {expected}")
        print(f"  Got:      {actual}")
        return False
    return True


def generate_cruise_dll() -> bytes:
    """Generate minimal cruise.dll — creates the SecuROM spoof Event.

    This is a valid PE DLL whose DllMain creates a named Event object
    "v7_XXXX" (where XXXX = PID XOR 0x19EA3FD3) with bManualReset=TRUE,
    bInitialState=TRUE (signaled). SecuROM's inline trigger checks test
    this event and proceed when it's signaled.
    """
    sys.path.insert(0, str(Path(__file__).parent))
    from remove_securom import generate_cruise_dll as _gen
    return _gen()


def apply_patch(input_exe: Path, output_exe: Path, patch_file: Path,
                generate_cruise: bool = True, verbose: bool = True) -> None:
    try:
        import bsdiff4
    except ImportError:
        print("ERROR: bsdiff4 package required. Install with:")
        print("  pip install bsdiff4")
        print("  # or: .venv/bin/pip install bsdiff4")
        sys.exit(1)

    if not input_exe.exists():
        print(f"ERROR: Input EXE not found: {input_exe}")
        sys.exit(1)

    if not patch_file.exists():
        print(f"ERROR: Patch file not found: {patch_file}")
        print("  Expected at: tools/patches/mercs2_v1.1_securom_bypass.bspatch")
        sys.exit(1)

    if verbose:
        print(f"Input:  {input_exe}")
        print(f"Patch:  {patch_file}")
        print(f"Output: {output_exe}")
        print()

    retail_data = input_exe.read_bytes()

    if len(retail_data) != RETAIL_V11_SIZE:
        print(f"WARNING: Input size {len(retail_data):,} differs from expected "
              f"retail v1.1 size {RETAIL_V11_SIZE:,}")
        print("  The patch is built for the v1.1 update EXE.")
        print("  If this is v1.0 (original disc), apply the v1.1 update first.")
        print()

    if verbose:
        print("Verifying input MD5...")
    if not verify_md5(retail_data, RETAIL_V11_MD5, "Input EXE"):
        print("  This patch is designed for the retail v1.1 EXE.")
        print("  Proceeding anyway — patch may fail if input is wrong.")
        print()

    if verbose:
        print("Reading patch file...")
    patch_data = patch_file.read_bytes()
    if verbose:
        print(f"  Patch size: {len(patch_data):,} bytes")

    if verbose:
        print("Applying patch...")
    try:
        result = bsdiff4.patch(retail_data, patch_data)
    except Exception as e:
        print(f"ERROR: Patch application failed: {e}")
        print("  This usually means the input EXE doesn't match the expected retail v1.1.")
        sys.exit(1)

    if verbose:
        print(f"  Result size: {len(result):,} bytes")
        print("Verifying output MD5...")

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


def generate_patch(retail_exe: Path, cracked_exe: Path, output_patch: Path,
                   verbose: bool = True) -> None:
    """Generate a bsdiff patch from retail → cracked (for maintainer use)."""
    try:
        import bsdiff4
    except ImportError:
        print("ERROR: bsdiff4 package required.")
        sys.exit(1)

    if verbose:
        print(f"Source (retail v1.1): {retail_exe}")
        print(f"Target (cracked):    {cracked_exe}")
        print(f"Output patch:        {output_patch}")
        print()

    retail_data = retail_exe.read_bytes()
    cracked_data = cracked_exe.read_bytes()

    if verbose:
        print(f"Retail size:  {len(retail_data):,}")
        print(f"Cracked size: {len(cracked_data):,}")
        print(f"Retail MD5:   {hashlib.md5(retail_data).hexdigest()}")
        print(f"Cracked MD5:  {hashlib.md5(cracked_data).hexdigest()}")
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
        print("  VERIFIED: patch(retail) == cracked")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Apply binary patch to remove SecuROM from Mercenaries 2 v1.1 EXE")

    parser.add_argument("input", help="Path to retail v1.1 Mercenaries2.exe")
    parser.add_argument("--output", "-o",
                        help="Output path (default: <input_dir>/Mercenaries2-Patched.exe)")
    parser.add_argument("--patch", "-p", default=str(PATCH_FILE),
                        help=f"Path to .bspatch file (default: {PATCH_FILE})")
    parser.add_argument("--no-cruise", action="store_true",
                        help="Don't generate cruise.dll")
    parser.add_argument("--quiet", "-q", action="store_true")
    parser.add_argument("--generate-patch", metavar="CRACKED_EXE",
                        help="Generate patch mode: INPUT is retail, this arg is cracked EXE, "
                             "--output is required for patch file destination")

    args = parser.parse_args()

    if args.generate_patch:
        if not args.output:
            parser.error("--output is required when using --generate-patch")
        generate_patch(
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
            patch_file=Path(args.patch),
            generate_cruise=not args.no_cruise,
            verbose=not args.quiet,
        )


if __name__ == "__main__":
    main()
