#!/usr/bin/env python3
"""Targeted static disassembler for the Mercenaries 2 PC EXE.

Maps an absolute virtual address (as used throughout docs/, image base
0x00400000) to a file offset via the PE section table and disassembles a
function with capstone (x86 32-bit). Read-only; no debugger required.

Usage:
    python tools/disasm_func.py --exe "<Mercenaries2.exe>" --va 0x00516B10 --count 120
    python tools/disasm_func.py --exe "<...>" --va 0x00516B10 --until-ret
    python tools/disasm_func.py --exe "<...>" --read-dword 0x01175DD8

The EXE is the cracked/SecuROM-bypassed retail image (53,482,288 bytes); its
.text is plaintext so static disassembly matches the documented VAs.
"""
from __future__ import annotations

import argparse
from pathlib import Path

import capstone
import pefile


class Image:
    def __init__(self, path: Path) -> None:
        self.pe = pefile.PE(str(path), fast_load=True)
        self.base = self.pe.OPTIONAL_HEADER.ImageBase
        self.data = Path(path).read_bytes()
        self.sections = []
        for s in self.pe.sections:
            name = s.Name.rstrip(b"\x00").decode("latin1", "replace")
            self.sections.append(
                (
                    name,
                    self.base + s.VirtualAddress,
                    s.Misc_VirtualSize,
                    s.PointerToRawData,
                    s.SizeOfRawData,
                )
            )

    def va_to_off(self, va: int) -> int | None:
        for _name, vstart, vsize, praw, sraw in self.sections:
            if vstart <= va < vstart + max(vsize, sraw):
                delta = va - vstart
                if delta < sraw:
                    return praw + delta
        return None

    def section_of(self, va: int) -> str | None:
        for name, vstart, vsize, _praw, sraw in self.sections:
            if vstart <= va < vstart + max(vsize, sraw):
                return name
        return None

    def read(self, va: int, n: int) -> bytes | None:
        off = self.va_to_off(va)
        if off is None:
            return None
        return self.data[off : off + n]


def disasm(img: Image, va: int, count: int, until_ret: bool) -> None:
    code = img.read(va, max(count * 8, 16))
    if code is None:
        print(f"VA {va:#010x} not mapped to a raw section")
        return
    md = capstone.Cs(capstone.CS_ARCH_X86, capstone.CS_MODE_32)
    md.detail = True
    n = 0
    for insn in md.disasm(code, va):
        # annotate static reads of absolute [imm] operands
        note = ""
        for tok in ("dword ptr [0x", "word ptr [0x", "byte ptr [0x"):
            if tok in insn.op_str:
                try:
                    addr = int(insn.op_str.split("[0x", 1)[1].split("]", 1)[0], 16)
                    sec = img.section_of(addr)
                    if sec:
                        dv = img.read(addr, 4)
                        if dv:
                            note = f"   ; [{addr:#x}] in {sec} = {int.from_bytes(dv,'little'):#010x}"
                except Exception:
                    pass
        print(f"{insn.address:#010x}: {insn.mnemonic:<7} {insn.op_str}{note}")
        n += 1
        if until_ret and insn.mnemonic in ("ret", "retn"):
            break
        if n >= count:
            break


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--exe", required=True)
    ap.add_argument("--va", type=lambda x: int(x, 0))
    ap.add_argument("--count", type=int, default=80)
    ap.add_argument("--until-ret", action="store_true")
    ap.add_argument("--read-dword", type=lambda x: int(x, 0))
    ap.add_argument("--sections", action="store_true")
    ap.add_argument("--xrefs", type=lambda x: int(x, 0),
                    help="scan .text for E8/E9 rel32 branches targeting this VA")
    args = ap.parse_args()

    img = Image(Path(args.exe))
    if args.xrefs is not None:
        target = args.xrefs
        # scan executable sections for relative call/jmp (E8/E9) to target
        for name, vstart, vsize, praw, sraw in img.sections:
            if name not in (".text", "Stext"):
                continue
            blob = img.data[praw : praw + sraw]
            for i in range(len(blob) - 5):
                op = blob[i]
                if op in (0xE8, 0xE9):
                    rel = int.from_bytes(blob[i + 1 : i + 5], "little", signed=True)
                    src = vstart + i
                    dst = (src + 5 + rel) & 0xFFFFFFFF
                    if dst == target:
                        kind = "call" if op == 0xE8 else "jmp"
                        print(f"{src:#010x}: {kind} {target:#x}")
        return
    if args.sections:
        print(f"ImageBase {img.base:#x}")
        for name, vstart, vsize, praw, sraw in img.sections:
            print(f"  {name:<10} VA {vstart:#010x} vsize {vsize:#x} raw {praw:#x} rawsz {sraw:#x}")
        return
    if args.read_dword is not None:
        dv = img.read(args.read_dword, 16)
        print(f"{args.read_dword:#x} ({img.section_of(args.read_dword)}): {dv.hex() if dv else None}")
        return
    if args.va is not None:
        disasm(img, args.va, args.count, args.until_ret)


if __name__ == "__main__":
    main()
