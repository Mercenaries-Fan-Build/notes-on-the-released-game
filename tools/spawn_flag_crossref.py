#!/usr/bin/env python3
"""Cross-reference spawn validation flag 0x00DFBD74 with splash crash site."""
from __future__ import annotations

import struct
import sys
from pathlib import Path

IMAGE_BASE = 0x00400000
EXE = Path(__file__).resolve().parents[1] / "output/patched/Mercenaries2.exe"
FLAG_VA = 0x00DFBD74
CRASH_VA = 0x005AE372
SCRIPT_TABLE_VA = 0x01176630

# Related flags from spawn investigation
RELATED_FLAGS = [0x00DFBD74, 0x00DFBD75, 0x00DFBD77, 0x00DFBD78, 0x00DFBDBF]
INIT_FUNC_VA = 0x006CEEBA  # MOVQ store site


def va_to_fo(va: int) -> int:
    return va - IMAGE_BASE


def fo_to_va(fo: int) -> int:
    return IMAGE_BASE + fo


def read_exe() -> bytes:
    if not EXE.exists():
        print(f"ERROR: EXE not found: {EXE}")
        sys.exit(1)
    data = EXE.read_bytes()
    if len(data) != 53_482_288:
        print(f"WARNING: unexpected size {len(data)} (expected 53482288)")
    return data


def find_imm32_refs(data: bytes, addr: int, region_start: int, region_end: int) -> list[tuple[int, bytes]]:
    """Find 4-byte little-endian immediate matching addr in byte range."""
    packed = struct.pack("<I", addr)
    hits: list[tuple[int, bytes]] = []
    chunk = data[region_start:region_end]
    pos = 0
    while True:
        idx = chunk.find(packed, pos)
        if idx == -1:
            break
        fo = region_start + idx
        ctx_start = max(region_start, fo - 8)
        ctx_end = min(region_end, fo + 16)
        hits.append((fo_to_va(fo), data[ctx_start:ctx_end]))
        pos = idx + 4
    return hits


def classify_flag_ref(ctx: bytes, flag_off_in_ctx: int) -> str:
    """Heuristic decode of instruction referencing flag immediate."""
    # ctx is ~24 bytes centered on the imm32; flag_off_in_ctx is where imm32 starts
    pre = ctx[:flag_off_in_ctx]
    if len(pre) >= 2 and pre[-2] == 0x80 and pre[-1] == 0x3D:
        return "CMP BYTE [flag], imm8"
    if len(pre) >= 2 and pre[-2] == 0x38 and pre[-1] == 0x3D:
        return "CMP BYTE [flag], imm8 (alt)"
    if len(pre) >= 2 and pre[-2] == 0xC6 and pre[-1] == 0x05:
        imm = ctx[flag_off_in_ctx + 4] if len(ctx) > flag_off_in_ctx + 4 else 0
        return f"MOV BYTE [flag], 0x{imm:02X}"
    if len(pre) >= 4 and pre[-4:] == b"\x66\x0F\xD6\x05":
        return "MOVQ [flag], xmm0 (8-byte init)"
    if len(pre) >= 1 and pre[-1] == 0xA1:
        return "MOV EAX, [flag]"
    if len(pre) >= 2 and pre[-2] == 0x8A and pre[-1] in (0x05, 0x0D, 0x15, 0x1D, 0x25, 0x35):
        return "MOV reg8, [flag]"
    if len(pre) >= 2 and pre[-2] == 0x88 and pre[-1] in (0x05, 0x0D, 0x15, 0x1D, 0x25, 0x35):
        return "MOV [flag], reg8"
    if len(pre) >= 2 and pre[-2] == 0xFF and pre[-1] == 0x05:
        return "INC DWORD [flag] (unlikely)"
    if len(pre) >= 2 and pre[-2] == 0xFF and pre[-1] == 0x0D:
        return "DEC DWORD [flag] (unlikely)"
    return "unknown ref"


def scan_text_refs(data: bytes, addr: int) -> list[tuple[int, str, bytes]]:
    text_start = 0x00001000
    text_end = text_start + 0x00704000
    hits = find_imm32_refs(data, addr, text_start, text_end)
    results = []
    for va, ctx in hits:
        # locate imm32 offset in ctx
        packed = struct.pack("<I", addr)
        imm_off = ctx.find(packed)
        kind = classify_flag_ref(ctx, imm_off)
        results.append((va, kind, ctx))
    return results


def disasm_window(data: bytes, center_va: int, before: int = 64, after: int = 96) -> None:
    fo = va_to_fo(center_va)
    start = max(0, fo - before)
    end = min(len(data), fo + after)
    print(f"\n=== Disasm window around VA 0x{center_va:08X} ===")
    for off in range(start, end, 16):
        va = fo_to_va(off)
        line = data[off : off + 16]
        hex_part = " ".join(f"{b:02X}" for b in line)
        marker = ""
        if off <= fo < off + 16:
            marker = "  <<<"
        print(f"  {va:08X}  {hex_part:<48s}{marker}")


def main() -> None:
    data = read_exe()
    print(f"EXE: {EXE}")
    print(f"Size: {len(data)} bytes")
    print()

    # Flag values in .data
    print("=== .data flag bytes (cracked EXE on disk) ===")
    for va in RELATED_FLAGS:
        fo = va_to_fo(va)
        print(f"  VA 0x{va:08X}: 0x{data[fo]:02X}")
    print()

    # Count all text refs to primary flag
    refs = scan_text_refs(data, FLAG_VA)
    print(f"=== References to 0x{FLAG_VA:08X} in .text ===")
    print(f"Total immediate refs: {len(refs)}")
    kinds: dict[str, int] = {}
    for va, kind, _ in refs:
        kinds[kind] = kinds.get(kind, 0) + 1
    for k, n in sorted(kinds.items(), key=lambda x: -x[1]):
        print(f"  {k}: {n}")
    print()

    # Region-specific: splash / script dispatcher
    regions = [
        ("splash/script dispatcher", 0x005AE000, 0x005AF000),
        ("ShellBootstrap-ish 0x005A-0x005C", 0x005A0000, 0x005C0000),
        ("spawn module 0x005D", 0x005D5000, 0x005E0000),
        ("flag init 0x006CEE", 0x006CE000, 0x006D0000),
        ("DllMain-era early init 0x0040-0x0050", 0x00400000, 0x00500000),
    ]
    print("=== Flag refs by region ===")
    for name, lo, hi in regions:
        lo_fo = va_to_fo(lo)
        hi_fo = va_to_fo(hi)
        region_refs = [(va, k) for va, k, _ in refs if lo <= va < hi]
        print(f"  {name} ({lo:08X}-{hi:08X}): {len(region_refs)} refs")
        for va, k in region_refs[:8]:
            print(f"    0x{va:08X}: {k}")
        if len(region_refs) > 8:
            print(f"    ... +{len(region_refs) - 8} more")
    print()

    # Crash site cross-ref
    disasm_window(data, CRASH_VA, before=48, after=80)

    crash_region_refs = [(va, k, ctx) for va, k, ctx in refs if 0x005AE000 <= va < 0x005AF000]
    print(f"\n=== Flag refs in crash region 0x005AE000-0x005AF000 ===")
    if crash_region_refs:
        for va, k, ctx in crash_region_refs:
            hex_ctx = " ".join(f"{b:02X}" for b in ctx)
            print(f"  0x{va:08X}: {k}  ctx={hex_ctx}")
    else:
        print("  NONE — crash site does not reference spawn flag")
    print()

    # Script table global near crash
    print(f"=== References to script table global 0x{SCRIPT_TABLE_VA:08X} near crash ===")
    table_refs = find_imm32_refs(data, SCRIPT_TABLE_VA, va_to_fo(0x005AE000), va_to_fo(0x005AF000))
    for va, ctx in table_refs[:20]:
        hex_ctx = " ".join(f"{b:02X}" for b in ctx)
        print(f"  0x{va:08X}: {hex_ctx}")
    if not table_refs:
        # widen search
        table_refs = find_imm32_refs(data, SCRIPT_TABLE_VA, 0x00001000, 0x00001000 + 0x00704000)
        near = [(va, ctx) for va, ctx in table_refs if 0x005AD000 <= va <= 0x005B0000]
        print(f"  (widened to 0x005AD000-0x005B0000: {len(near)} refs)")
        for va, ctx in near[:15]:
            hex_ctx = " ".join(f"{b:02X}" for b in ctx)
            print(f"  0x{va:08X}: {hex_ctx}")
    print()

    # Related flags ref counts
    print("=== Related flag ref counts in .text ===")
    for va in RELATED_FLAGS:
        n = len(scan_text_refs(data, va))
        print(f"  0x{va:08X}: {n} refs")
    print()

    # Writes only
    print("=== Writes to 0x00DFBD74 ===")
    write_kinds = ("MOV BYTE", "MOVQ", "MOV [flag]", "MOV [flag], reg")
    for va, kind, ctx in refs:
        if any(w in kind for w in ("MOV BYTE", "MOVQ", "MOV [flag]")):
            hex_ctx = " ".join(f"{b:02X}" for b in ctx)
            print(f"  0x{va:08X}: {kind}  {hex_ctx}")
    print()

    # Init function context
    disasm_window(data, INIT_FUNC_VA, before=32, after=48)

    print("=== SUMMARY ===")
    print(f"Spawn flag 0x{FLAG_VA:08X}: {len(refs)} code refs in .text")
    print(f"Crash at 0x{CRASH_VA:08X}: {len(crash_region_refs)} flag refs in ±4KB window")
    print(f"Script table 0x{SCRIPT_TABLE_VA:08X}: separate from spawn flag")


if __name__ == "__main__":
    main()
