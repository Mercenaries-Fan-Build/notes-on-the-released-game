#!/usr/bin/env python3
"""Verify that a Mercenaries 2 EXE's import table contains expected DLLs.

Used to diagnose whether the ASI Loader proxy (dinput8.dll) will be loaded
by the Windows PE loader. If DINPUT8.dll is NOT in the import table, the
proxy DLL won't be loaded and ASI plugins won't work.

Usage:
  python3 tools/verify_exe_imports.py <path_to_exe>
"""
from __future__ import annotations

import struct
import sys
from pathlib import Path


def list_imports(exe_path: Path) -> list[str]:
    """Extract DLL names from the PE import directory."""
    data = exe_path.read_bytes()

    if data[:2] != b"MZ":
        print("ERROR: Not a valid PE file (no MZ header)")
        sys.exit(1)

    pe_off = struct.unpack_from("<I", data, 0x3C)[0]
    if data[pe_off:pe_off + 4] != b"PE\x00\x00":
        print("ERROR: Not a valid PE file (no PE signature)")
        sys.exit(1)

    coff_off = pe_off + 4
    num_sections = struct.unpack_from("<H", data, coff_off + 2)[0]
    opt_off = coff_off + 20
    magic = struct.unpack_from("<H", data, opt_off)[0]

    if magic == 0x10B:
        opt_size = 224
    elif magic == 0x20B:
        opt_size = 240
    else:
        print(f"ERROR: Unknown optional header magic: 0x{magic:X}")
        sys.exit(1)

    import_dir_off = opt_off + 96 + 1 * 8
    import_rva = struct.unpack_from("<I", data, import_dir_off)[0]
    import_size = struct.unpack_from("<I", data, import_dir_off + 4)[0]

    if not import_rva:
        return []

    # Parse section table to map RVA → file offset
    sec_table_off = opt_off + opt_size if magic == 0x20B else opt_off + 224
    # Actually re-read: opt_hdr_size from COFF header
    opt_hdr_size = struct.unpack_from("<H", data, coff_off + 16)[0]
    sec_table_off = coff_off + 20 + opt_hdr_size

    sections = []
    for i in range(num_sections):
        s_off = sec_table_off + i * 40
        s_va = struct.unpack_from("<I", data, s_off + 12)[0]
        s_vs = struct.unpack_from("<I", data, s_off + 8)[0]
        s_ra = struct.unpack_from("<I", data, s_off + 20)[0]
        s_rs = struct.unpack_from("<I", data, s_off + 16)[0]
        sections.append((s_va, s_vs, s_ra, s_rs))

    def rva_to_file(rva: int) -> int | None:
        for s_va, s_vs, s_ra, s_rs in sections:
            if s_va <= rva < s_va + max(s_vs, s_rs):
                return s_ra + (rva - s_va)
        return rva  # fallback: RVA == file offset (common in this EXE)

    dlls = []
    off = rva_to_file(import_rva)
    if off is None:
        return []

    while off + 20 <= len(data):
        name_rva = struct.unpack_from("<I", data, off + 12)[0]
        first_thunk = struct.unpack_from("<I", data, off + 16)[0]
        if name_rva == 0 and first_thunk == 0:
            break

        name_off = rva_to_file(name_rva)
        if name_off is not None and name_off < len(data):
            end = data.index(b"\x00", name_off) if b"\x00" in data[name_off:name_off + 256] else name_off + 64
            dll_name = data[name_off:end].decode("ascii", errors="replace")
            dlls.append(dll_name)

        off += 20

    return dlls


def main() -> None:
    if len(sys.argv) < 2:
        print("Usage: python3 tools/verify_exe_imports.py <path_to_exe>")
        sys.exit(1)

    exe_path = Path(sys.argv[1])
    if not exe_path.exists():
        print(f"ERROR: File not found: {exe_path}")
        sys.exit(1)

    print(f"Analyzing: {exe_path} ({exe_path.stat().st_size:,} bytes)")
    print()

    dlls = list_imports(exe_path)

    print(f"Import table contains {len(dlls)} DLL(s):")
    print()

    asi_proxy_dlls = {"dinput8.dll", "d3d9.dll", "dsound.dll", "winmm.dll",
                      "version.dll", "xinput1_3.dll", "binkw32.dll"}

    for dll in dlls:
        marker = ""
        if dll.lower() in asi_proxy_dlls:
            marker = "  ← ASI Loader can proxy this"
        elif dll.lower() == "pmc_blackbox.dll":
            marker = "  ← SecuROM spoof + ASI loader (injected by patcher)"
        elif dll.lower() == "cruise.dll":
            marker = "  ← Legacy SecuROM spoof (consider upgrading to pmc_blackbox.dll)"
        print(f"  {dll}{marker}")

    print()

    # Check for DINPUT8.dll specifically
    has_dinput8 = any(d.lower() == "dinput8.dll" for d in dlls)
    has_blackbox = any(d.lower() == "pmc_blackbox.dll" for d in dlls)
    has_cruise = any(d.lower() == "cruise.dll" for d in dlls)

    if has_dinput8:
        print("✓ DINPUT8.dll IS in the import table")
        print("  → The ASI Loader proxy (dinput8.dll) WILL be loaded by Windows")
        print("  → If ASI plugins still don't work, check:")
        print("    - Is dinput8.dll (ASI Loader) actually a 32-bit DLL?")
        print("    - Does scripts/global.ini exist with [GlobalSets] DontLoadFromDllMain=0?")
        print("    - Are .asi files in the scripts/ subfolder?")
        print("    - Is antivirus blocking the DLL?")
    else:
        print("✗ DINPUT8.dll is NOT in the import table!")
        print("  → The ASI Loader proxy (dinput8.dll) will NOT be loaded")
        print("  → The bsdiff patching may have modified the import table")
        print()
        print("  ALTERNATIVES:")
        proxyable = [d for d in dlls if d.lower() in asi_proxy_dlls]
        if proxyable:
            print(f"    Use one of these DLLs as the ASI Loader proxy instead:")
            for d in proxyable:
                print(f"      - {d}")
            print(f"    Download the matching ASI Loader variant from ThirteenAG's releases")
        else:
            print("    No standard ASI Loader proxy targets found in imports!")
            print("    The EXE may need import table repair.")

    print()
    if has_blackbox:
        print("✓ pmc_blackbox.dll IS in the import table")
        print("  → SecuROM spoof + debug console + ASI loader all handled")
        print("  → No separate ASI loader proxy (dinput8.dll) needed")
    elif has_cruise:
        print("✓ cruise.dll IS in the import table (legacy SecuROM spoof)")
        print("  → Consider re-patching with latest tools to use pmc_blackbox.dll")
        print("  → Run: make crack-game RETAIL_EXE=<path>")
    else:
        print("○ Neither pmc_blackbox.dll nor cruise.dll in import table")
        print("  → You need cruise.asi loaded via ASI Loader, or re-patch the exe")


if __name__ == "__main__":
    main()
