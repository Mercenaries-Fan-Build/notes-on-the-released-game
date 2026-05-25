#!/usr/bin/env python3
"""Re-verify critical Lua C API VAs in Mercenaries2.exe (cracked retail build).

Uses instruction-aware x86 scanning: E8 rel32 call sites, prologue checks,
and per-VA calling-convention fingerprints. Does not trust prior agent reports.

Usage:
  .venv/bin/python3 tools/verify_lua_vas.py
  .venv/bin/python3 tools/verify_lua_vas.py --exe path/to/Mercenaries2.exe
"""
from __future__ import annotations

import argparse
import struct
import sys
from dataclasses import dataclass, field
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
DEFAULT_EXE = REPO / "output/patched/Mercenaries2.exe"
EXPECTED_EXE_SIZE = 53_482_288
IMAGE_BASE = 0x00400000

# Verified targets (2026-05-20 cross-check)
VA_LUAL_LOADBUFFER = 0x00860240
VA_LUA_PCALL = 0x0085DF50
VA_LUAB_LOADSTRING = 0x00860FC0
VA_LUAB_PCALL = 0x008615F0
VA_PRINT_STUB = 0x006D5640
VA_LUAL_TYPERROR = 0x0085F050  # formerly mislabeled loadbuffer
VA_LUAD_PCALL = 0x00868AD0  # formerly mislabeled lua_pcall

MIN_CALLERS_FOR_CONVENTION = 2


@dataclass
class Section:
    name: str
    va: int
    rva: int
    raw_offset: int
    raw_size: int
    virt_size: int


@dataclass
class CheckResult:
    name: str
    va: int
    ok: bool
    detail: str
    evidence: list[str] = field(default_factory=list)


def parse_pe(data: bytes) -> tuple[list[Section], int]:
    pe_off = struct.unpack_from("<I", data, 0x3C)[0]
    if data[pe_off : pe_off + 4] != b"PE\x00\x00":
        raise ValueError("Not a PE file")
    coff = pe_off + 4
    nsec = struct.unpack_from("<H", data, coff + 2)[0]
    opt_sz = struct.unpack_from("<H", data, coff + 16)[0]
    sec_base = coff + 20 + opt_sz
    sections: list[Section] = []
    for i in range(nsec):
        o = sec_base + i * 40
        name = data[o : o + 8].rstrip(b"\x00").decode("ascii", errors="replace")
        vs, va, rs, ro = struct.unpack_from("<IIII", data, o + 8)
        sections.append(
            Section(name, IMAGE_BASE + va, va, ro, rs, vs)
        )
    return sections, pe_off


def va_to_offset(va: int, sections: list[Section]) -> int | None:
    rva = va - IMAGE_BASE
    for s in sections:
        if s.rva <= rva < s.rva + s.virt_size:
            off = s.raw_offset + (rva - s.rva)
            if off < s.raw_offset + s.raw_size:
                return off
    return None


def offset_to_va(off: int, sections: list[Section]) -> int | None:
    for s in sections:
        if s.raw_offset <= off < s.raw_offset + s.raw_size:
            return s.va + (off - s.raw_offset)
    return None


def section_for_va(va: int, sections: list[Section]) -> Section | None:
    for s in sections:
        if s.va <= va < s.va + s.virt_size:
            return s
    return None


def find_call_sites(data: bytes, target_va: int, text: Section) -> list[int]:
    """Find E8 rel32 CALL sites whose target == target_va (VA)."""
    sites: list[int] = []
    start = text.raw_offset
    end = min(start + text.raw_size, len(data))
    for off in range(start, end - 5):
        if data[off] != 0xE8:
            continue
        rel = struct.unpack_from("<i", data, off + 1)[0]
        call_va = offset_to_va(off, [text])
        if call_va is None:
            continue
        dest = call_va + 5 + rel
        if dest == target_va:
            sites.append(call_va)
    return sites


def find_function_start(data: bytes, ref_off: int, text: Section) -> int | None:
    """Walk backward from ref_off for likely function prologue."""
    start = text.raw_offset
    lo = max(start, ref_off - 2048)
    for candidate in range(ref_off, lo, -1):
        prev = data[candidate - 1] if candidate > 0 else 0
        if prev not in (0xCC, 0x90, 0xC3, 0xC2):
            continue
        b0 = data[candidate]
        b1 = data[candidate + 1] if candidate + 1 < len(data) else 0
        if b0 == 0x55 and b1 == 0x8B:  # push ebp; mov ebp, esp
            return candidate
        if b0 in range(0x50, 0x58):  # push reg
            return candidate
        if b0 == 0x83 and b1 == 0xEC:  # sub esp, imm8
            return candidate
    return None


def bytes_at(data: bytes, va: int, n: int, sections: list[Section]) -> bytes | None:
    off = va_to_offset(va, sections)
    if off is None or off + n > len(data):
        return None
    return data[off : off + n]


def scan_window(data: bytes, call_va: int, before: int, after: int, sections: list[Section]) -> bytes | None:
    off = va_to_offset(call_va, sections)
    if off is None:
        return None
    lo = max(0, off - before)
    hi = min(len(data), off + 5 + after)
    return data[lo:hi]


def check_loadbuffer_callers(data: bytes, sections: list[Section], text: Section) -> CheckResult:
    callers = find_call_sites(data, VA_LUAL_LOADBUFFER, text)
    ev: list[str] = [f"E8 call sites: {len(callers)}"]
    esp8 = 0
    for cva in callers[:12]:
        win = scan_window(data, cva, 48, 12, sections)
        if win is None:
            continue
        rel = cva - (va_to_offset(cva, sections) or 0)
        # after CALL at +5 in window
        post = win[-12:] if len(win) >= 12 else win
        if b"\x83\xC4\x08" in post or b"\xC4\x08" in post:  # add esp, 8
            esp8 += 1
    ok = len(callers) >= 1 and esp8 >= min(1, len(callers))
    if len(callers) >= MIN_CALLERS_FOR_CONVENTION and esp8 < MIN_CALLERS_FOR_CONVENTION:
        ok = False
    ev.append(f"post-call add esp,8 pattern: {esp8}/{min(len(callers),12)} sampled")
    # Prologue at target
    pro = bytes_at(data, VA_LUAL_LOADBUFFER, 8, sections)
    if pro:
        ev.append(f"prologue: {pro.hex()}")
    return CheckResult(
        "luaL_loadbuffer",
        VA_LUAL_LOADBUFFER,
        ok and pro is not None,
        "PASS" if ok else "FAIL",
        ev,
    )


def check_pcall_callers(data: bytes, sections: list[Section], text: Section) -> CheckResult:
    callers = find_call_sites(data, VA_LUA_PCALL, text)
    ev = [f"E8 call sites: {len(callers)}"]
    clean4 = 0
    for cva in callers[:20]:
        win = scan_window(data, cva, 40, 10, sections)
        if win and (b"\x83\xC4\x04" in win[-10:] or b"\x59" in win[-6:]):  # add esp,4 or pop ecx
            clean4 += 1
    ok = len(callers) >= MIN_CALLERS_FOR_CONVENTION and clean4 >= MIN_CALLERS_FOR_CONVENTION
    ev.append(f"stack cleanup (add esp,4/pop): {clean4}/{min(len(callers),20)} sampled")
    pro = bytes_at(data, VA_LUA_PCALL, 8, sections)
    if pro:
        ev.append(f"prologue: {pro.hex()}")
    return CheckResult("lua_pcall", VA_LUA_PCALL, ok, "PASS" if ok else "FAIL", ev)


def check_luaB_loadstring_calls_loadbuffer(data: bytes, sections: list[Section], text: Section) -> CheckResult:
    """luaB_loadstring must call 0x00860240."""
    off = va_to_offset(VA_LUAB_LOADSTRING, sections)
    ev: list[str] = []
    if off is None:
        return CheckResult("luaB_loadstring→loadbuffer", VA_LUAB_LOADSTRING, False, "FAIL", ["not in image"])
    chunk = data[off : off + 512]
    target = struct.pack("<I", VA_LUAL_LOADBUFFER)
    calls = []
    for i in range(len(chunk) - 5):
        if chunk[i] == 0xE8:
            rel = struct.unpack_from("<i", chunk, i + 1)[0]
            src_va = VA_LUAB_LOADSTRING + i
            if src_va + 5 + rel == VA_LUAL_LOADBUFFER:
                calls.append(hex(src_va + 5))
    ok = len(calls) >= 1
    ev.append(f"internal E8→loadbuffer: {calls}")
    pro = bytes_at(data, VA_LUAB_LOADSTRING, 8, sections)
    if pro:
        ev.append(f"prologue: {pro.hex()}")
    return CheckResult(
        "luaB_loadstring→loadbuffer",
        VA_LUAB_LOADSTRING,
        ok,
        "PASS" if ok else "FAIL",
        ev,
    )


def check_luaB_pcall_calls_luad_pcall(data: bytes, sections: list[Section], text: Section) -> CheckResult:
    off = va_to_offset(VA_LUAB_PCALL, sections)
    ev: list[str] = []
    if off is None:
        return CheckResult("luaB_pcall→luaD_pcall", VA_LUAB_PCALL, False, "FAIL", ["not in image"])
    chunk = data[off : off + 800]
    hits = []
    for i in range(len(chunk) - 5):
        if chunk[i] == 0xE8:
            rel = struct.unpack_from("<i", chunk, i + 1)[0]
            src_va = VA_LUAB_PCALL + i
            dest = src_va + 5 + rel
            if dest == VA_LUAD_PCALL:
                hits.append(hex(src_va + 5))
            if dest == VA_LUA_PCALL:
                hits.append(f"WRONG lua_pcall@{hex(src_va+5)}")
    ok = len(hits) >= 1 and not any("WRONG" in h for h in hits)
    ev.append(f"E8→luaD_pcall: {hits}")
    return CheckResult("luaB_pcall→luaD_pcall", VA_LUAB_PCALL, ok, "PASS" if ok else "FAIL", ev)


def check_print_stub(data: bytes, sections: list[Section]) -> CheckResult:
    pro = bytes_at(data, VA_PRINT_STUB, 4, sections)
    ok = pro is not None and pro[:3] == bytes([0x33, 0xC0, 0xC3])  # xor eax,eax; ret (+ padding)
    ev = [f"bytes: {pro.hex() if pro else 'missing'}"]
    return CheckResult("luaB_print stub", VA_PRINT_STUB, ok, "PASS" if ok else "FAIL", ev)


def check_misid_typerror_not_loadbuffer(data: bytes, sections: list[Section], text: Section) -> CheckResult:
    """0x0085F050 should NOT be called like loadbuffer (no add esp,8 from luaB_loadstring path)."""
    callers = find_call_sites(data, VA_LUAL_TYPERROR, text)
    lb_callers = find_call_sites(data, VA_LUAL_LOADBUFFER, text)
    ev = [f"typerror call sites: {len(callers)}", f"loadbuffer call sites: {len(lb_callers)}"]
    # loadbuffer has few callers; typerror has many
    ok = len(callers) > len(lb_callers)
    # String xref: "bad argument" near typerror
    needle = b"bad argument #%d"
    rdata = next((s for s in sections if s.name == ".rdata"), None)
    str_va = None
    if rdata:
        start, end = rdata.raw_offset, rdata.raw_offset + rdata.raw_size
        idx = data.find(needle, start, end)
        if idx >= 0:
            str_va = offset_to_va(idx, sections)
            ev.append(f'"bad argument" string @ 0x{str_va:08X}' if str_va else "")
    return CheckResult(
        "luaL_typerror≠loadbuffer",
        VA_LUAL_TYPERROR,
        ok,
        "PASS" if ok else "FAIL",
        ev,
    )


def check_misid_luad_pcall_not_public(data: bytes, sections: list[Section], text: Section) -> CheckResult:
    d_callers = len(find_call_sites(data, VA_LUAD_PCALL, text))
    p_callers = len(find_call_sites(data, VA_LUA_PCALL, text))
    ev = [f"luaD_pcall callers: {d_callers}", f"lua_pcall callers: {p_callers}"]
    ok = d_callers >= 1 and p_callers > d_callers
    return CheckResult(
        "luaD_pcall≠lua_pcall (caller counts)",
        VA_LUAD_PCALL,
        ok,
        "PASS" if ok else "FAIL",
        ev,
    )


def check_exe_size(path: Path) -> CheckResult:
    sz = path.stat().st_size
    ok = sz == EXPECTED_EXE_SIZE
    return CheckResult(
        "EXE size",
        0,
        ok,
        "PASS" if ok else "FAIL",
        [f"{sz:,} bytes (expected {EXPECTED_EXE_SIZE:,})"],
    )


def main() -> int:
    ap = argparse.ArgumentParser(description="Verify Lua C API VAs in Mercenaries2.exe")
    ap.add_argument("--exe", type=Path, default=DEFAULT_EXE)
    args = ap.parse_args()
    if not args.exe.is_file():
        print(f"error: missing EXE: {args.exe}", file=sys.stderr)
        return 1

    data = args.exe.read_bytes()
    sections, _ = parse_pe(data)
    text = next((s for s in sections if s.name == ".text"), None)
    if text is None:
        print("error: no .text section", file=sys.stderr)
        return 1

    checks = [
        check_exe_size(args.exe),
        check_loadbuffer_callers(data, sections, text),
        check_pcall_callers(data, sections, text),
        check_luaB_loadstring_calls_loadbuffer(data, sections, text),
        check_luaB_pcall_calls_luad_pcall(data, sections, text),
        check_print_stub(data, sections),
        check_misid_typerror_not_loadbuffer(data, sections, text),
        check_misid_luad_pcall_not_public(data, sections, text),
    ]

    print(f"EXE: {args.exe}")
    print(f"Image base: 0x{IMAGE_BASE:08X}\n")
    print(f"{'Check':<32} {'VA':>12} {'Status':>6}  Evidence")
    print("-" * 100)
    failed = 0
    for c in checks:
        va_s = f"0x{c.va:08X}" if c.va else "—"
        if not c.ok:
            failed += 1
        ev = "; ".join(c.evidence[:4])
        print(f"{c.name:<32} {va_s:>12} {c.detail:>6}  {ev}")

    print()
    if failed:
        print(f"RESULT: {failed} check(s) FAILED")
        return 1
    print("RESULT: all checks PASSED")
    return 0


if __name__ == "__main__":
    sys.exit(main())
