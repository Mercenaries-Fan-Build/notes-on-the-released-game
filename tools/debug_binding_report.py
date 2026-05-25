#!/usr/bin/env python3
"""Report Debug/Sys logging bindings and stub status for Mercenaries 2 PC EXE.

Confirms Debug.Printf → shared stub, resolves Sys.WriteToConsole VA, and dumps
the function prologue for manual / follow-up RE.

Usage:
  .venv/bin/python3 tools/debug_binding_report.py
  .venv/bin/python3 tools/debug_binding_report.py --exe path/to/Mercenaries2.exe
"""
from __future__ import annotations

import argparse
import struct
import sys
from pathlib import Path

_REPO = Path(__file__).resolve().parents[1]
if str(_REPO) not in sys.path:
    sys.path.insert(0, str(_REPO))

from tools.dump_lua_bindings import (  # noqa: E402
    PRIMARY_FILE_SCAN_END,
    PRIMARY_FILE_START,
    find_default_exe,
    parse_pe,
    parse_table_at_offset,
    read_cstring,
)

EXPECTED_EXE_SIZE = 53_482_288
STUB_VA = 0x006D5640
STUB_BYTES = bytes([0x33, 0xC0, 0xC3])  # xor eax,eax; ret

# Documented anchors (image VAs, cracked 53,482,288-byte EXE)
VA_DEBUG_TABLE = 0x00B98828
VA_DEBUG_PRINTF_FUNC_PTR = VA_DEBUG_TABLE + 4
VA_BASE_TABLE = 0x00B924B8
VA_SYS_TABLE = 0x00B98A78


def read_dword(pe, va: int) -> int | None:
    off = pe.va_to_offset(va)
    if off is None or off + 4 > len(pe.data):
        return None
    return struct.unpack_from("<I", pe.data, off)[0]


def func_prologue(pe, func_va: int, nbytes: int = 32) -> bytes:
    off = pe.va_to_offset(func_va)
    if off is None:
        return b""
    return pe.data[off : off + nbytes]


def is_stub(pe, func_va: int) -> bool:
    if func_va == STUB_VA:
        return True
    return func_prologue(pe, func_va, len(STUB_BYTES)) == STUB_BYTES


def find_binding(pe, name: str) -> tuple[int, int, int] | None:
    """Return (table_start_va, name_va, func_va) for first matching binding name."""
    rdata = pe.section(".rdata")
    if rdata is None:
        return None
    scan_end = min(PRIMARY_FILE_SCAN_END, rdata.raw_ptr + rdata.raw_size - 16)
    foff = PRIMARY_FILE_START
    while foff < scan_end:
        table = parse_table_at_offset(pe, foff)
        if table is None:
            foff += 4
            continue
        for e in table.entries:
            if e.name == name:
                return table.start_va, e.name_va, e.func_va
        foff = table.end_foff
    return None


def disasm_text(pe, func_va: int, nbytes: int = 48) -> str:
    blob = func_prologue(pe, func_va, nbytes)
    if not blob:
        return "(unreadable)"
    try:
        from capstone import Cs, CS_ARCH_X86, CS_MODE_32

        md = Cs(CS_ARCH_X86, CS_MODE_32)
        lines = []
        for insn in md.disasm(blob, func_va):
            lines.append(f"  0x{insn.address:08X}: {insn.mnemonic} {insn.op_str}")
        return "\n".join(lines) if lines else "(capstone: no insns)"
    except ImportError:
        hexline = " ".join(f"{b:02X}" for b in blob)
        return f"  raw: {hexline}\n  (pip install capstone for disassembly)"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--exe", type=Path, help="Cracked Mercenaries2.exe")
    args = parser.parse_args()

    exe = args.exe or find_default_exe()
    if exe is None:
        print(
            "No EXE found. Pass --exe or place binary at\n"
            "  game-files/cracked-parts/Crack/Mercenaries2.exe\n"
            "  output/patched/Mercenaries2.exe",
            file=sys.stderr,
        )
        return 1

    pe = parse_pe(exe)
    size = len(pe.data)
    print(f"EXE: {exe} ({size:,} bytes)")
    if size != EXPECTED_EXE_SIZE:
        print(f"WARNING: expected {EXPECTED_EXE_SIZE:,} bytes (dlc_enable VAs are for cracked retail)")

    # Direct read at documented Printf reg slot
    printf_ptr = read_dword(pe, VA_DEBUG_PRINTF_FUNC_PTR)
    printf_name = read_cstring(pe, read_dword(pe, VA_DEBUG_TABLE) or 0) if read_dword(pe, VA_DEBUG_TABLE) else None

    wtc = find_binding(pe, "WriteToConsole")
    dbg_printf = find_binding(pe, "Printf")
    base_print = find_binding(pe, "print")

    print()
    print("=== Debug.Printf (luaL_Reg patch target) ===")
    print(f"  Table VA:     0x{VA_DEBUG_TABLE:08X}")
    print(f"  Func ptr VA:  0x{VA_DEBUG_PRINTF_FUNC_PTR:08X}")
    if printf_name:
        print(f"  Name at slot: {printf_name!r}")
    if printf_ptr is not None:
        stub = is_stub(pe, printf_ptr)
        print(f"  Points to:    0x{printf_ptr:08X}  stub={stub}")
    if dbg_printf:
        print(f"  (scan) table=0x{dbg_printf[0]:08X} func=0x{dbg_printf[2]:08X}")

    print()
    print("=== print() base lib (optional second patch) ===")
    if base_print:
        _, _, fva = base_print
        print(f"  Table VA:     0x{base_print[0]:08X}")
        print(f"  Func VA:      0x{fva:08X}  stub={is_stub(pe, fva)}")
    else:
        # Walk base table at VA_BASE_TABLE
        off = pe.va_to_offset(VA_BASE_TABLE)
        if off:
            for i in range(24):
                name_va = struct.unpack_from("<I", pe.data, off + i * 8)[0]
                func_va = struct.unpack_from("<I", pe.data, off + i * 8 + 4)[0]
                if name_va == 0 and func_va == 0:
                    break
                nm = read_cstring(pe, name_va) or "?"
                if nm == "print":
                    print(f"  Table VA:     0x{VA_BASE_TABLE:08X}  entry #{i}")
                    print(f"  Func ptr VA:  0x{off + i * 8 + 4:08X} (file)")
                    reg_va = pe.offset_to_va(off + i * 8 + 4)
                    print(f"  Func ptr VA:  0x{reg_va:08X}  func=0x{func_va:08X} stub={is_stub(pe, func_va)}")
                    base_print = (VA_BASE_TABLE, name_va, func_va)
                    break

    print()
    print("=== Sys.WriteToConsole (engine console — do not hook shared stub) ===")
    if wtc:
        print(f"  Table VA:     0x{wtc[0]:08X}")
        print(f"  Func VA:      0x{wtc[2]:08X}  stub={is_stub(pe, wtc[2])}")
        print(disasm_text(pe, wtc[2]))
    else:
        off = pe.va_to_offset(VA_SYS_TABLE)
        if off:
            name_va = struct.unpack_from("<I", pe.data, off)[0]
            func_va = struct.unpack_from("<I", pe.data, off + 4)[0]
            nm = read_cstring(pe, name_va) or "?"
            print(f"  Table VA:     0x{VA_SYS_TABLE:08X}  first={nm!r}")
            print(f"  Func VA:      0x{func_va:08X}  stub={is_stub(pe, func_va)}")
            print(disasm_text(pe, func_va))

    print()
    print("=== Shared stub @ 0x006D5640 ===")
    print(f"  Bytes: {func_prologue(pe, STUB_VA, 8).hex(' ')}")

    # Count how many primary bindings use the stub
    rdata = pe.section(".rdata")
    stub_count = 0
    total = 0
    if rdata:
        foff = PRIMARY_FILE_START
        scan_end = min(PRIMARY_FILE_SCAN_END, rdata.raw_ptr + rdata.raw_size - 16)
        while foff < scan_end:
            table = parse_table_at_offset(pe, foff)
            if table is None:
                foff += 4
                continue
            for e in table.entries:
                total += 1
                if is_stub(pe, e.func_va):
                    stub_count += 1
            foff = table.end_foff
    print(f"  Primary cluster: {stub_count}/{total} bindings point at stub (inline hook hits all of these)")

    print()
    if wtc and is_stub(pe, wtc[2]):
        print(
            "NOTE: Sys.WriteToConsole is also the shared stub on this PC build — "
            "there is no engine console forward target. Use luaL_Reg patch + ASI log."
        )
    print(
        "Recommendation: patch only Debug.Printf (+ print) luaL_Reg func pointers; "
        "do not inline-hook 0x006D5640."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
