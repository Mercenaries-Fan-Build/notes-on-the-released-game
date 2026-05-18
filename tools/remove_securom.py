#!/usr/bin/env python3
"""Remove SecuROM v7.37/7.38 DRM from Mercenaries 2 executables.

Supports both the demo (SecuROM v7.38) and retail (SecuROM v7.37) executables.

Demo approach (v7.38 — disc-check only):
  SecuROM encrypts .text and decrypts at runtime via the Sitext stub.
  We let SecuROM's stub run but spoof the disc authentication:
  1. Zero the PE Security directory entry
  2. Inject cruise.dll import (creates the expected Win32 Event)
  3. Patch the .rdata timer constant (900.0 → 0.0) to disable demo timer

Retail approach (v7.37 — binary patch, preferred):
  Use `tools/apply_securom_patch.py` which applies a bsdiff binary patch
  transforming the retail v1.1 EXE directly into the working version.
  No external donor EXE required — only the patch file (in tools/patches/).

  Alternatively, the legacy --donor flow transplants the decrypted .text
  from a pre-cracked executable (deprecated — use apply_securom_patch.py).

Usage:
  # Demo (works standalone):
  python3 tools/remove_securom.py <demo_exe> [--output <patched_exe>] [--timer <seconds>]

  # Retail (preferred — use the patch-based tool):
  python3 tools/apply_securom_patch.py <retail_v1.1_exe> [-o <output>]

  # Retail (legacy — requires cracked exe as donor):
  python3 tools/remove_securom.py <retail_exe> --donor <cracked_exe> [--output <patched>]

  # Analysis only:
  python3 tools/remove_securom.py --analyze <exe>

Requirements:
  - cruise.dll must be placed next to the patched exe for it to run
  - The script generates cruise.dll if --generate-cruise is passed

Example:
  python3 tools/remove_securom.py "Mercenaries 2 World in Flames DEMO/Merc2-Demo.exe"
  python3 tools/apply_securom_patch.py Mercs2.exe -o Mercs2-Patched.exe
"""
from __future__ import annotations

import argparse
import struct
import sys
from pathlib import Path


DEMO_EXE_SIZE = 17_118_472
DEMO_EP_RVA = 0x1D03290
DEMO_IMAGE_BASE = 0x400000
DEMO_TIMER_FILE_OFFSET = 0x007EA87C
DEMO_TIMER_VALUE = 900.0
SECUROM_PDB = b"SecuROM_DRM"

RETAIL_EP_RVA = 0x1C87A10
RETAIL_OEP_RVA = 0x5EE71C
RETAIL_TEXT_FILE_OFF = 0x1000
RETAIL_TEXT_SIZE = 0x704000

PE_SECURITY_DIR_INDEX = 4


def read_u16(data: bytes, off: int) -> int:
    return struct.unpack_from("<H", data, off)[0]


def read_u32(data: bytes, off: int) -> int:
    return struct.unpack_from("<I", data, off)[0]


def write_u16(data: bytearray, off: int, val: int) -> None:
    struct.pack_into("<H", data, off, val)


def write_u32(data: bytearray, off: int, val: int) -> None:
    struct.pack_into("<I", data, off, val)


class PESection:
    def __init__(self, name: str, virt_size: int, virt_addr: int,
                 raw_size: int, raw_addr: int, flags: int):
        self.name = name
        self.virt_size = virt_size
        self.virt_addr = virt_addr
        self.raw_size = raw_size
        self.raw_addr = raw_addr
        self.flags = flags

    def contains_rva(self, rva: int) -> bool:
        return self.virt_addr <= rva < self.virt_addr + self.virt_size

    def rva_to_file(self, rva: int) -> int:
        return self.raw_addr + (rva - self.virt_addr)


class PEInfo:
    def __init__(self, data: bytes):
        self.data = data
        if data[:2] != b"MZ":
            raise ValueError("Not a valid DOS executable (no MZ header)")

        self.pe_offset = read_u32(data, 0x3C)
        if data[self.pe_offset:self.pe_offset + 4] != b"PE\x00\x00":
            raise ValueError("Not a valid PE file (no PE signature)")

        coff_start = self.pe_offset + 4
        self.machine = read_u16(data, coff_start)
        self.num_sections = read_u16(data, coff_start + 2)
        self.timestamp = read_u32(data, coff_start + 4)
        self.opt_hdr_size = read_u16(data, coff_start + 16)
        self.characteristics = read_u16(data, coff_start + 18)

        self.opt_start = coff_start + 20
        self.opt_magic = read_u16(data, self.opt_start)
        if self.opt_magic != 0x10B:
            raise ValueError(f"Not PE32 (magic=0x{self.opt_magic:X})")

        self.entry_point_rva = read_u32(data, self.opt_start + 16)
        self.image_base = read_u32(data, self.opt_start + 28)
        self.section_alignment = read_u32(data, self.opt_start + 32)
        self.file_alignment = read_u32(data, self.opt_start + 36)
        self.size_of_image = read_u32(data, self.opt_start + 56)
        self.size_of_headers = read_u32(data, self.opt_start + 60)
        self.checksum = read_u32(data, self.opt_start + 64)

        self.num_data_dirs = read_u32(data, self.opt_start + 92)
        self.data_dir_offset = self.opt_start + 96

        self.sections: list[PESection] = []
        sec_table = self.opt_start + self.opt_hdr_size
        for i in range(self.num_sections):
            off = sec_table + i * 40
            name = data[off:off + 8].rstrip(b"\x00").decode("ascii", errors="replace")
            vs = read_u32(data, off + 8)
            va = read_u32(data, off + 12)
            rs = read_u32(data, off + 16)
            ra = read_u32(data, off + 20)
            flags = read_u32(data, off + 36)
            self.sections.append(PESection(name, vs, va, rs, ra, flags))

    def get_data_dir(self, index: int) -> tuple[int, int]:
        off = self.data_dir_offset + index * 8
        return read_u32(self.data, off), read_u32(self.data, off + 4)

    def section_for_rva(self, rva: int) -> PESection | None:
        for s in self.sections:
            if s.contains_rva(rva):
                return s
        return None

    def ep_section(self) -> PESection | None:
        return self.section_for_rva(self.entry_point_rva)

    def has_securom(self) -> bool:
        for s in self.sections:
            if s.name in ("Sitext", "Stext", ".securom"):
                return True
        sec_rva, sec_size = self.get_data_dir(PE_SECURITY_DIR_INDEX)
        if sec_rva and sec_size:
            return True
        return False

    def print_analysis(self) -> None:
        print(f"File size: {len(self.data):,} bytes")
        print(f"PE offset: 0x{self.pe_offset:X}")
        print(f"Machine: 0x{self.machine:X} ({'i386' if self.machine == 0x14C else 'unknown'})")
        print(f"Sections: {self.num_sections}")
        print(f"Entry Point RVA: 0x{self.entry_point_rva:X}")
        print(f"Image Base: 0x{self.image_base:X}")
        print(f"Size of Image: 0x{self.size_of_image:X}")

        ep_sec = self.ep_section()
        if ep_sec:
            print(f"Entry Point Section: {ep_sec.name}")

        print(f"\n{'Section':<10s} {'VirtSize':>10s} {'VirtAddr':>10s} "
              f"{'RawSize':>10s} {'RawAddr':>10s} {'Flags':>10s}")
        print("=" * 62)
        for s in self.sections:
            marker = " <-- EP" if s.contains_rva(self.entry_point_rva) else ""
            print(f"{s.name:<10s} 0x{s.virt_size:08X} 0x{s.virt_addr:08X} "
                  f"0x{s.raw_size:08X} 0x{s.raw_addr:08X} 0x{s.flags:08X}{marker}")

        print("\nData Directories:")
        dir_names = ["Export", "Import", "Resource", "Exception", "Security",
                     "BaseReloc", "Debug", "Architecture", "GlobalPtr", "TLS",
                     "LoadConfig", "BoundImport", "IAT", "DelayImport", "CLR"]
        for i in range(min(self.num_data_dirs, 15)):
            rva, size = self.get_data_dir(i)
            if rva or size:
                print(f"  [{i:2d}] {dir_names[i]:12s}: RVA=0x{rva:08X} Size=0x{size:X}")

        print(f"\nSecuROM detected: {self.has_securom()}")
        securom_sections = [s.name for s in self.sections
                           if s.name in ("Sitext", "Stext", "Srdata", "Sdata", "Sidata", ".securom")]
        if securom_sections:
            print(f"SecuROM sections: {', '.join(securom_sections)}")


def find_demo_timer(data: bytes) -> int | None:
    """Find the 900.0 float in .rdata that represents the demo timer."""
    target = struct.pack("<f", 900.0)
    context_before = struct.pack("<f", 480.0)

    pos = 0
    while True:
        idx = data.find(target, pos)
        if idx == -1:
            return None
        if idx >= 4 and data[idx - 4:idx] == context_before:
            return idx
        pos = idx + 4


def generate_cruise_dll() -> bytes:
    """Generate a minimal cruise.dll that creates the SecuROM spoof event.

    The DLL's DllMain does:
      1. GetCurrentProcessId()
      2. XOR result with 0x19EA3FD3
      3. sprintf(buf, "v7_%04d", xored_pid)
      4. CreateEventA(NULL, TRUE, TRUE, buf)  — manual-reset, initially signaled
      5. Return TRUE

    The event MUST be created in the SIGNALED state (bInitialState=TRUE) with
    manual reset (bManualReset=TRUE). SecuROM's inline trigger checks call
    WaitForSingleObject on this event — if it's not signaled, the wait blocks
    and the game exits after a timeout.
    """
    # Minimal 64-byte DOS header so total headers fit within FileAlignment
    dos_header = bytearray(64)
    dos_header[0:2] = b"MZ"
    struct.pack_into("<I", dos_header, 0x3C, 64)  # PE offset at 0x40

    pe_sig = b"PE\x00\x00"

    coff_header = bytearray(20)
    struct.pack_into("<H", coff_header, 0, 0x14C)    # Machine: i386
    struct.pack_into("<H", coff_header, 2, 3)        # NumberOfSections
    struct.pack_into("<I", coff_header, 4, 0)        # TimeDateStamp
    struct.pack_into("<H", coff_header, 16, 224)     # SizeOfOptionalHeader
    struct.pack_into("<H", coff_header, 18, 0x2102)  # Characteristics: DLL, EXEC, 32BIT

    opt_header = bytearray(224)
    struct.pack_into("<H", opt_header, 0, 0x10B)     # Magic: PE32
    opt_header[2] = 8                                 # MajorLinkerVersion
    struct.pack_into("<I", opt_header, 4, 0x200)     # SizeOfCode
    struct.pack_into("<I", opt_header, 16, 0x1000)   # AddressOfEntryPoint
    struct.pack_into("<I", opt_header, 20, 0x1000)   # BaseOfCode
    struct.pack_into("<I", opt_header, 24, 0x2000)   # BaseOfData
    struct.pack_into("<I", opt_header, 28, 0x10000000)  # ImageBase
    struct.pack_into("<I", opt_header, 32, 0x1000)   # SectionAlignment
    struct.pack_into("<I", opt_header, 36, 0x200)    # FileAlignment
    struct.pack_into("<H", opt_header, 40, 4)        # MajorOSVersion
    struct.pack_into("<H", opt_header, 44, 4)        # MajorSubsystemVersion
    struct.pack_into("<I", opt_header, 56, 0x5000)   # SizeOfImage
    struct.pack_into("<I", opt_header, 60, 0x200)    # SizeOfHeaders
    struct.pack_into("<H", opt_header, 68, 3)        # Subsystem: CONSOLE
    struct.pack_into("<H", opt_header, 70, 0x40)     # DllCharacteristics: DYNAMIC_BASE
    struct.pack_into("<I", opt_header, 72, 0x100000) # SizeOfStackReserve
    struct.pack_into("<I", opt_header, 76, 0x1000)   # SizeOfStackCommit
    struct.pack_into("<I", opt_header, 80, 0x100000) # SizeOfHeapReserve
    struct.pack_into("<I", opt_header, 84, 0x1000)   # SizeOfHeapCommit
    struct.pack_into("<I", opt_header, 92, 16)       # NumberOfRvaAndSizes

    # Data directories (16 entries × 8 bytes = 128 bytes, already zeroed)
    # Import directory at RVA 0x2000
    struct.pack_into("<I", opt_header, 96 + 1 * 8, 0x2000)      # Import RVA
    struct.pack_into("<I", opt_header, 96 + 1 * 8 + 4, 0x100)   # Import Size

    # Section headers (3 sections × 40 bytes)
    sections = bytearray(3 * 40)

    # .text section
    sections[0:8] = b".text\x00\x00\x00"
    struct.pack_into("<I", sections, 8, 0x200)       # VirtualSize
    struct.pack_into("<I", sections, 12, 0x1000)     # VirtualAddress
    struct.pack_into("<I", sections, 16, 0x200)      # SizeOfRawData
    struct.pack_into("<I", sections, 20, 0x200)      # PointerToRawData
    struct.pack_into("<I", sections, 36, 0x60000020) # Flags: CODE|EXEC|READ

    # .data section (contains import table + strings)
    sections[40:48] = b".data\x00\x00\x00"
    struct.pack_into("<I", sections, 48, 0x200)      # VirtualSize
    struct.pack_into("<I", sections, 52, 0x2000)     # VirtualAddress
    struct.pack_into("<I", sections, 56, 0x200)      # SizeOfRawData
    struct.pack_into("<I", sections, 60, 0x400)      # PointerToRawData
    struct.pack_into("<I", sections, 76, 0xC0000040) # Flags: INIT_DATA|READ|WRITE

    # .rdata section (IAT, import names)
    sections[80:88] = b".rdata\x00\x00"
    struct.pack_into("<I", sections, 88, 0x200)      # VirtualSize
    struct.pack_into("<I", sections, 92, 0x3000)     # VirtualAddress
    struct.pack_into("<I", sections, 96, 0x200)      # SizeOfRawData
    struct.pack_into("<I", sections, 100, 0x600)     # PointerToRawData
    struct.pack_into("<I", sections, 116, 0x40000040)  # Flags: INIT_DATA|READ

    # Build headers — total = 64 + 4 + 20 + 224 + 120 = 432 bytes, fits in 0x200
    headers = dos_header + pe_sig + coff_header + opt_header + sections
    assert len(headers) <= 0x200, f"Headers too large: {len(headers)} > 0x200"
    headers += b"\x00" * (0x200 - len(headers))

    # .text section: DllMain code (at file offset 0x200, RVA 0x1000)
    # The DLL entry is DllMain(hModule, reason, reserved)
    # We only act on DLL_PROCESS_ATTACH (reason == 1)
    code = bytearray(0x200)

    # DllMain:
    #   cmp dword [esp+8], 1       ; reason == DLL_PROCESS_ATTACH?
    #   jne .ret_true
    #   call _do_spoof
    # .ret_true:
    #   mov eax, 1
    #   ret 12
    #
    # _do_spoof:
    #   call [IAT_GetCurrentProcessId]    ; -> eax = PID
    #   xor eax, 0x19EA3FD3
    #   push eax
    #   push offset fmt                    ; "v7_%04d"
    #   push offset buf                    ; buffer in .data
    #   call [IAT_wsprintfA]
    #   add esp, 12
    #   push offset buf                    ; lpName
    #   push 0                             ; bInitialState = FALSE
    #   push 0                             ; bManualReset = FALSE
    #   push 0                             ; lpEventAttributes = NULL
    #   call [IAT_CreateEventA]
    #   ret

    # IAT layout (at RVA 0x3000, file 0x600):
    #   +0x00: GetCurrentProcessId
    #   +0x04: CreateEventA
    #   +0x08: wsprintfA (from USER32)
    #   +0x0C: NULL terminator for KERNEL32
    #   +0x10: NULL terminator for USER32

    IAT_BASE = 0x10000000 + 0x3000  # VA of IAT
    FMT_VA = 0x10000000 + 0x2080    # "v7_%04d" string
    BUF_VA = 0x10000000 + 0x20A0    # sprintf buffer

    i = 0
    # cmp dword [esp+8], 1
    code[i:i+4] = b"\x83\x7C\x24\x08"
    i += 4
    code[i] = 0x01
    i += 1
    # jne .ret_true (skip to ret)
    code[i] = 0x75
    code[i + 1] = 0x00  # placeholder
    i += 2
    jne_patch = i - 1

    # call _do_spoof (inline it)
    spoof_start = i

    # call [IAT_GetCurrentProcessId]  -> FF 15 <addr32>
    code[i:i+2] = b"\xFF\x15"
    struct.pack_into("<I", code, i + 2, IAT_BASE + 0x00)
    i += 6

    # xor eax, 0x19EA3FD3
    code[i] = 0x35
    struct.pack_into("<I", code, i + 1, 0x19EA3FD3)
    i += 5

    # push eax
    code[i] = 0x50
    i += 1

    # push offset fmt ("v7_%04d")
    code[i] = 0x68
    struct.pack_into("<I", code, i + 1, FMT_VA)
    i += 5

    # push offset buf
    code[i] = 0x68
    struct.pack_into("<I", code, i + 1, BUF_VA)
    i += 5

    # call [IAT_wsprintfA]
    code[i:i+2] = b"\xFF\x15"
    struct.pack_into("<I", code, i + 2, IAT_BASE + 0x08)
    i += 6

    # add esp, 12
    code[i:i+3] = b"\x83\xC4\x0C"
    i += 3

    # push offset buf (lpName)
    code[i] = 0x68
    struct.pack_into("<I", code, i + 1, BUF_VA)
    i += 5

    # push -1 (bInitialState = TRUE — event starts SIGNALED)
    code[i:i+2] = b"\x6A\xFF"
    i += 2

    # push -1 (bManualReset = TRUE — event stays signaled until explicit reset)
    code[i:i+2] = b"\x6A\xFF"
    i += 2

    # push 0 (lpEventAttributes = NULL)
    code[i:i+2] = b"\x6A\x00"
    i += 2

    # call [IAT_CreateEventA]
    code[i:i+2] = b"\xFF\x15"
    struct.pack_into("<I", code, i + 2, IAT_BASE + 0x04)
    i += 6

    # .ret_true:
    ret_true_offset = i
    code[jne_patch] = ret_true_offset - (jne_patch + 1)

    # mov eax, 1
    code[i:i+5] = b"\xB8\x01\x00\x00\x00"
    i += 5

    # ret 12
    code[i:i+3] = b"\xC2\x0C\x00"
    i += 3

    # .data section (file offset 0x400, RVA 0x2000)
    data_sec = bytearray(0x200)

    # Import Directory Table at RVA 0x2000 (file 0x400)
    # Entry 1: KERNEL32.dll
    # OriginalFirstThunk, TimeDateStamp, ForwarderChain, Name, FirstThunk
    idt_off = 0
    # KERNEL32 entry
    struct.pack_into("<I", data_sec, idt_off + 0, 0x3020)   # OrigFirstThunk -> hint/name array
    struct.pack_into("<I", data_sec, idt_off + 12, 0x2040)  # Name RVA
    struct.pack_into("<I", data_sec, idt_off + 16, 0x3000)  # FirstThunk (IAT)
    idt_off += 20

    # USER32.dll entry
    struct.pack_into("<I", data_sec, idt_off + 0, 0x3030)   # OrigFirstThunk
    struct.pack_into("<I", data_sec, idt_off + 12, 0x2060)  # Name RVA
    struct.pack_into("<I", data_sec, idt_off + 16, 0x3008)  # FirstThunk (IAT)
    idt_off += 20

    # NULL terminator entry
    idt_off += 20

    # DLL name strings
    data_sec[0x40:0x40 + 13] = b"KERNEL32.dll\x00"
    data_sec[0x60:0x60 + 11] = b"USER32.dll\x00"

    # Format string "v7_%04d"
    data_sec[0x80:0x80 + 8] = b"v7_%04d\x00"

    # Buffer for sprintf (at offset 0xA0)
    # left zeroed

    # .rdata section (file offset 0x600, RVA 0x3000)
    rdata_sec = bytearray(0x200)

    # IAT (FirstThunk arrays):
    # KERNEL32 IAT at RVA 0x3000:
    #   [0] -> hint/name for GetCurrentProcessId
    #   [4] -> hint/name for CreateEventA
    #   [8] -> NULL
    # USER32 IAT at RVA 0x3008:
    #   [0] -> hint/name for wsprintfA
    #   [4] -> NULL

    # Hint/Name Table entries (placed at RVA 0x3040+)
    # GetCurrentProcessId at 0x3040
    hn_off = 0x40
    struct.pack_into("<H", rdata_sec, hn_off, 0)  # Hint
    name = b"GetCurrentProcessId\x00"
    rdata_sec[hn_off + 2:hn_off + 2 + len(name)] = name
    get_pid_rva = 0x3000 + hn_off

    # CreateEventA at 0x3060
    hn_off = 0x60
    struct.pack_into("<H", rdata_sec, hn_off, 0)
    name = b"CreateEventA\x00"
    rdata_sec[hn_off + 2:hn_off + 2 + len(name)] = name
    create_event_rva = 0x3000 + hn_off

    # wsprintfA at 0x3080
    hn_off = 0x80
    struct.pack_into("<H", rdata_sec, hn_off, 0)
    name = b"wsprintfA\x00"
    rdata_sec[hn_off + 2:hn_off + 2 + len(name)] = name
    wsprintf_rva = 0x3000 + hn_off

    # IAT entries (at start of .rdata)
    struct.pack_into("<I", rdata_sec, 0x00, get_pid_rva)     # GetCurrentProcessId
    struct.pack_into("<I", rdata_sec, 0x04, create_event_rva)  # CreateEventA
    struct.pack_into("<I", rdata_sec, 0x08, 0)               # NULL (end KERNEL32)
    # USER32 IAT starts at offset 0x08 in the IAT? No - let me fix the layout.
    # Actually the IAT for USER32 starts at RVA 0x3008 -> file offset 0x600 + 0x08 = NO
    # Wait: .rdata file offset is 0x600, RVA is 0x3000
    # So IAT at RVA 0x3000 = file 0x600 + 0 = rdata_sec[0]
    # IAT at RVA 0x3008 = rdata_sec[8]
    struct.pack_into("<I", rdata_sec, 0x08, wsprintf_rva)    # wsprintfA
    struct.pack_into("<I", rdata_sec, 0x0C, 0)              # NULL (end USER32)

    # Fix: KERNEL32 IAT needs 2 entries + NULL = 12 bytes
    # Then USER32 starts at offset 12
    # Let me redo:
    # KERNEL32 IAT at RVA 0x3000: GetCurrentProcessId, CreateEventA, NULL
    #   -> offsets 0x00, 0x04, 0x08 (12 bytes)
    # USER32 IAT at RVA 0x300C: wsprintfA, NULL
    #   -> offsets 0x0C, 0x10 (8 bytes)

    rdata_sec[0:0x14] = b"\x00" * 0x14
    struct.pack_into("<I", rdata_sec, 0x00, get_pid_rva)
    struct.pack_into("<I", rdata_sec, 0x04, create_event_rva)
    struct.pack_into("<I", rdata_sec, 0x08, 0)  # NULL end
    struct.pack_into("<I", rdata_sec, 0x0C, wsprintf_rva)
    struct.pack_into("<I", rdata_sec, 0x10, 0)  # NULL end

    # OriginalFirstThunk arrays:
    # KERNEL32 OFT at RVA 0x3020: same as IAT
    struct.pack_into("<I", rdata_sec, 0x20, get_pid_rva)
    struct.pack_into("<I", rdata_sec, 0x24, create_event_rva)
    struct.pack_into("<I", rdata_sec, 0x28, 0)
    # USER32 OFT at RVA 0x3030: same as IAT
    struct.pack_into("<I", rdata_sec, 0x30, wsprintf_rva)
    struct.pack_into("<I", rdata_sec, 0x34, 0)

    # Fix IDT references
    data_sec[0:60] = b"\x00" * 60  # clear IDT
    # KERNEL32 IDT entry
    struct.pack_into("<I", data_sec, 0, 0x3020)    # OrigFirstThunk
    struct.pack_into("<I", data_sec, 12, 0x2040)   # Name
    struct.pack_into("<I", data_sec, 16, 0x3000)   # FirstThunk
    # USER32 IDT entry
    struct.pack_into("<I", data_sec, 20, 0x3030)   # OrigFirstThunk
    struct.pack_into("<I", data_sec, 32, 0x2060)   # Name
    struct.pack_into("<I", data_sec, 36, 0x300C)   # FirstThunk
    # NULL terminator (20 zero bytes already)

    dll_image = headers + code + data_sec + rdata_sec
    # Pad to a nice size
    dll_image += b"\x00" * (0x1000 - len(dll_image))

    return bytes(dll_image)


def patch_demo_exe(input_path: Path, output_path: Path, timer_value: float,
                   verbose: bool = True) -> dict:
    """Patch the demo exe to bypass SecuROM and modify the demo timer.

    Returns a dict describing what was changed.
    """
    data = bytearray(input_path.read_bytes())
    pe = PEInfo(bytes(data))
    changes: dict = {"input": str(input_path), "output": str(output_path), "patches": []}

    if verbose:
        print(f"Input: {input_path} ({len(data):,} bytes)")
        print(f"Output: {output_path}")
        print()

    # Verify this is the expected demo exe
    if pe.image_base != DEMO_IMAGE_BASE:
        print(f"WARNING: Unexpected ImageBase 0x{pe.image_base:X} (expected 0x{DEMO_IMAGE_BASE:X})")

    if not pe.has_securom():
        print("WARNING: No SecuROM sections detected. This may not be a protected exe.")

    # --- Patch 1: Zero the Security directory entry ---
    sec_rva, sec_size = pe.get_data_dir(PE_SECURITY_DIR_INDEX)
    if sec_rva or sec_size:
        sec_dir_off = pe.data_dir_offset + PE_SECURITY_DIR_INDEX * 8
        write_u32(data, sec_dir_off, 0)
        write_u32(data, sec_dir_off + 4, 0)
        changes["patches"].append({
            "name": "Zero Security Directory",
            "offset": f"0x{sec_dir_off:X}",
            "old": f"RVA=0x{sec_rva:X} Size=0x{sec_size:X}",
            "new": "RVA=0x0 Size=0x0"
        })
        if verbose:
            print(f"[PATCH 1] Zeroed Security directory entry at PE+0x{sec_dir_off - pe.pe_offset:X}")
            print(f"          Was: RVA=0x{sec_rva:08X} Size=0x{sec_size:X}")
            print(f"          Now: RVA=0x00000000 Size=0x0")
            print()

    # --- Patch 2: Zero the PE checksum ---
    checksum_off = pe.opt_start + 64
    old_checksum = read_u32(data, checksum_off)
    if old_checksum:
        write_u32(data, checksum_off, 0)
        changes["patches"].append({
            "name": "Zero PE Checksum",
            "offset": f"0x{checksum_off:X}",
            "old": f"0x{old_checksum:X}",
            "new": "0x0"
        })
        if verbose:
            print(f"[PATCH 2] Zeroed PE checksum at offset 0x{checksum_off:X}")
            print(f"          Was: 0x{old_checksum:08X}")
            print()

    # --- Patch 3: Patch the demo timer ---
    timer_offset = find_demo_timer(bytes(data))
    if timer_offset is None:
        timer_offset = DEMO_TIMER_FILE_OFFSET
        old_val = struct.unpack_from("<f", data, timer_offset)[0]
        if abs(old_val - DEMO_TIMER_VALUE) > 0.1:
            if verbose:
                print(f"[PATCH 3] WARNING: Could not find demo timer (900.0 float)")
                print(f"          Value at expected offset 0x{timer_offset:X}: {old_val}")
            timer_offset = None

    if timer_offset is not None:
        old_val = struct.unpack_from("<f", data, timer_offset)[0]
        struct.pack_into("<f", data, timer_offset, timer_value)
        changes["patches"].append({
            "name": "Patch Demo Timer",
            "offset": f"0x{timer_offset:X}",
            "old": f"{old_val:.1f} seconds ({old_val/60:.1f} minutes)",
            "new": f"{timer_value:.1f} seconds ({timer_value/60:.1f} minutes)" if timer_value > 0
                   else "0.0 (disabled)"
        })
        if verbose:
            print(f"[PATCH 3] Patched demo timer at file offset 0x{timer_offset:X}")
            print(f"          Was: {old_val:.1f}s ({old_val/60:.0f} minutes)")
            if timer_value == 0.0:
                print(f"          Now: 0.0 (DISABLED)")
            else:
                print(f"          Now: {timer_value:.1f}s ({timer_value/60:.0f} minutes)")
            print()

    # --- Patch 4: Add cruise.dll to the import table ---
    # The import directory (IDT) lives in .securom at RVA 0x020707A4.
    # Import names and IAT thunks are in Sidata.
    # Strategy: relocate the entire IDT to zero-padding at the end of .securom,
    # appending our cruise.dll entry. DLL name, IAT, and OFT go there too.

    securom_sec = None
    sidata_sec = None
    for s in pe.sections:
        if s.name == ".securom":
            securom_sec = s
        elif s.name == "Sidata":
            sidata_sec = s

    import_injected = False
    if securom_sec and sidata_sec:
        import_rva = read_u32(data, pe.data_dir_offset + 1 * 8)
        import_size = read_u32(data, pe.data_dir_offset + 1 * 8 + 4)

        if import_rva and securom_sec.contains_rva(import_rva):
            import_file_off = securom_sec.rva_to_file(import_rva)

            # Count existing IDT entries
            num_imports = 0
            off = import_file_off
            while True:
                name_rva = read_u32(data, off + 12)
                first_thunk = read_u32(data, off)
                if name_rva == 0 and first_thunk == 0:
                    break
                num_imports += 1
                off += 20

            # Find zero-padding at end of .securom section
            # VirtSize=0x14E241 < RawSize=0x14F000; padding at virt_size..raw_size
            padding_file = securom_sec.raw_addr + securom_sec.virt_size
            padding_file = (padding_file + 15) & ~15  # align 16
            padding_rva = securom_sec.virt_addr + (padding_file - securom_sec.raw_addr)
            space_avail = (securom_sec.raw_addr + securom_sec.raw_size) - padding_file

            # We need: (num_imports+1) IDT entries + null (20 each) + dll name + IAT + OFT
            needed = (num_imports + 2) * 20 + 32
            if space_avail >= needed and padding_rva < pe.size_of_image:
                cursor_file = padding_file
                cursor_rva = padding_rva

                # Copy existing IDT entries to new location
                new_idt_file = cursor_file
                new_idt_rva = cursor_rva
                for i in range(num_imports):
                    src = import_file_off + i * 20
                    data[cursor_file:cursor_file + 20] = data[src:src + 20]
                    cursor_file += 20
                    cursor_rva += 20

                # Add cruise.dll entry
                cruise_idt_off = cursor_file
                cursor_file += 20
                cursor_rva += 20

                # Null terminator
                data[cursor_file:cursor_file + 20] = b"\x00" * 20
                cursor_file += 20
                cursor_rva += 20

                # DLL name string
                dll_name_bytes = b"cruise.dll\x00"
                dll_name_rva = cursor_rva
                dll_name_file = cursor_file
                data[cursor_file:cursor_file + len(dll_name_bytes)] = dll_name_bytes
                cursor_file += len(dll_name_bytes)
                cursor_rva += len(dll_name_bytes)
                # Align to 4
                if cursor_file % 4:
                    pad = 4 - (cursor_file % 4)
                    cursor_file += pad
                    cursor_rva += pad

                # IAT (FirstThunk): import by ordinal #1 so DLL loads via DllMain
                ordinal_import = 0x80000001
                iat_rva = cursor_rva
                iat_file = cursor_file
                struct.pack_into("<I", data, cursor_file, ordinal_import)
                struct.pack_into("<I", data, cursor_file + 4, 0)
                cursor_file += 8
                cursor_rva += 8

                # OFT (OriginalFirstThunk): same as IAT
                oft_rva = cursor_rva
                struct.pack_into("<I", data, cursor_file, ordinal_import)
                struct.pack_into("<I", data, cursor_file + 4, 0)
                cursor_file += 8
                cursor_rva += 8

                # Fill in the cruise.dll IDT entry
                struct.pack_into("<I", data, cruise_idt_off + 0, oft_rva)
                struct.pack_into("<I", data, cruise_idt_off + 4, 0)
                struct.pack_into("<I", data, cruise_idt_off + 8, 0)
                struct.pack_into("<I", data, cruise_idt_off + 12, dll_name_rva)
                struct.pack_into("<I", data, cruise_idt_off + 16, iat_rva)

                # Update Import Directory data dir to point to new IDT
                write_u32(data, pe.data_dir_offset + 1 * 8, new_idt_rva)
                write_u32(data, pe.data_dir_offset + 1 * 8 + 4,
                          (num_imports + 2) * 20)

                import_injected = True
                changes["patches"].append({
                    "name": "Inject cruise.dll Import",
                    "details": (f"Relocated IDT to .securom padding, added entry #{num_imports + 1}"),
                    "new_idt_rva": f"0x{new_idt_rva:X}",
                    "dll_name_rva": f"0x{dll_name_rva:X}",
                    "iat_rva": f"0x{iat_rva:X}"
                })
                if verbose:
                    print(f"[PATCH 4] Injected cruise.dll import (IDT relocated)")
                    print(f"          New IDT at RVA 0x{new_idt_rva:X} "
                          f"(file 0x{new_idt_file:X})")
                    print(f"          cruise.dll IDT entry #{num_imports + 1}")
                    print(f"          DLL name at RVA 0x{dll_name_rva:X}")
                    print(f"          IAT at RVA 0x{iat_rva:X} (ordinal #1)")
                    print()
            else:
                if verbose:
                    print(f"[PATCH 4] SKIPPED: Not enough padding in .securom "
                          f"({space_avail} bytes, need {needed})")
                    print()

    if not import_injected:
        if verbose:
            print("[PATCH 4] NOTE: cruise.dll import not injected.")
            print("          Place cruise.dll next to the exe — it will be loaded")
            print("          via the game's own DLL search path if the exe calls")
            print("          LoadLibrary, or use a separate launcher.")
            print()

    # --- Write output ---
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_bytes(bytes(data))
    changes["output_size"] = len(data)

    if verbose:
        print(f"{'=' * 60}")
        print(f"Output written: {output_path} ({len(data):,} bytes)")
        print()
        print("REQUIREMENTS:")
        print(f"  1. Place cruise.dll next to the patched exe:")
        print(f"     {output_path.parent / 'cruise.dll'}")
        print(f"  2. Run the patched exe normally — SecuROM decrypts .text at")
        print(f"     runtime, but disc auth is spoofed by cruise.dll's Event.")
        if timer_value == 0.0:
            print(f"  3. Demo timer is DISABLED (patched to 0.0)")
        elif timer_value != DEMO_TIMER_VALUE:
            print(f"  3. Demo timer extended to {timer_value:.0f}s ({timer_value/60:.0f} min)")

    return changes


def detect_exe_type(pe: PEInfo) -> str:
    """Detect whether this is a demo or retail Mercenaries 2 executable."""
    if pe.entry_point_rva == DEMO_EP_RVA:
        return "demo"
    if pe.entry_point_rva == RETAIL_EP_RVA:
        return "retail"
    ep_sec = pe.ep_section()
    if ep_sec and ep_sec.name == ".text":
        return "cracked"
    if ep_sec and ep_sec.name == "Sitext" and pe.has_securom():
        text_sec = next((s for s in pe.sections if s.name == ".text"), None)
        if text_sec and text_sec.raw_size == RETAIL_TEXT_SIZE:
            return "retail"
        return "demo"
    if ep_sec and ep_sec.name == ".securom" and pe.has_securom():
        text_sec = next((s for s in pe.sections if s.name == ".text"), None)
        if text_sec and text_sec.raw_size == RETAIL_TEXT_SIZE:
            return "retail"
        return "demo"
    return "unknown"


def patch_retail_exe(input_path: Path, output_path: Path, donor_path: Path,
                     verbose: bool = True) -> dict:
    """Patch the retail exe using text transplant from the cracked donor.

    The donor exe is the pre-cracked 51 MB executable that has .text fully
    decrypted. We copy its .text into the original retail exe and redirect
    the entry point to the OEP, bypassing SecuROM's stub and PA entirely.
    """
    data = bytearray(input_path.read_bytes())
    donor_data = donor_path.read_bytes()
    pe = PEInfo(bytes(data))
    donor_pe = PEInfo(donor_data)
    changes: dict = {"input": str(input_path), "output": str(output_path),
                     "donor": str(donor_path), "patches": []}

    if verbose:
        print(f"Input:  {input_path} ({len(data):,} bytes)")
        print(f"Donor:  {donor_path} ({len(donor_data):,} bytes)")
        print(f"Output: {output_path}")
        print()

    # Validate donor
    donor_type = detect_exe_type(donor_pe)
    if donor_type != "cracked":
        print(f"WARNING: Donor exe does not look pre-cracked (type={donor_type}, "
              f"EP section={donor_pe.ep_section().name if donor_pe.ep_section() else '?'})")

    # Find .text sections in both
    orig_text = next((s for s in pe.sections if s.name == ".text"), None)
    donor_text = next((s for s in donor_pe.sections if s.name == ".text"), None)
    if not orig_text or not donor_text:
        print("ERROR: Could not find .text section in one or both executables")
        return changes

    if orig_text.raw_size != donor_text.raw_size:
        print(f"ERROR: .text section size mismatch: "
              f"original=0x{orig_text.raw_size:X} donor=0x{donor_text.raw_size:X}")
        return changes

    if verbose:
        print(f"[PATCH 1] Text transplant: copying {orig_text.raw_size:,} bytes "
              f"of decrypted .text from donor")
        print(f"          Source: donor file offset 0x{donor_text.raw_addr:X}")
        print(f"          Dest:   output file offset 0x{orig_text.raw_addr:X}")
        print()

    # --- Patch 1: Copy decrypted .text from donor ---
    donor_text_bytes = donor_data[donor_text.raw_addr:
                                  donor_text.raw_addr + donor_text.raw_size]
    data[orig_text.raw_addr:orig_text.raw_addr + orig_text.raw_size] = donor_text_bytes
    changes["patches"].append({
        "name": "Text Transplant",
        "size": orig_text.raw_size,
        "source": f"donor offset 0x{donor_text.raw_addr:X}",
    })

    # --- Patch 2: Change entry point to OEP ---
    ep_offset = pe.opt_start + 16
    old_ep = read_u32(data, ep_offset)
    write_u32(data, ep_offset, RETAIL_OEP_RVA)
    changes["patches"].append({
        "name": "Redirect Entry Point to OEP",
        "old_ep": f"0x{old_ep:X}",
        "new_ep": f"0x{RETAIL_OEP_RVA:X}",
    })
    if verbose:
        print(f"[PATCH 2] Entry point redirected: 0x{old_ep:X} → 0x{RETAIL_OEP_RVA:X}")
        print(f"          (Sitext SecuROM stub → original .text CRT startup)")
        print()

    # --- Patch 3: Zero Security directory ---
    sec_rva, sec_size = pe.get_data_dir(PE_SECURITY_DIR_INDEX)
    if sec_rva or sec_size:
        sec_dir_off = pe.data_dir_offset + PE_SECURITY_DIR_INDEX * 8
        write_u32(data, sec_dir_off, 0)
        write_u32(data, sec_dir_off + 4, 0)
        changes["patches"].append({
            "name": "Zero Security Directory",
            "offset": f"0x{sec_dir_off:X}",
        })
        if verbose:
            print(f"[PATCH 3] Zeroed Security directory (was RVA=0x{sec_rva:X} Size=0x{sec_size:X})")
            print()

    # --- Patch 4: Zero PE checksum and IAT data directory ---
    checksum_off = pe.opt_start + 64
    old_checksum = read_u32(data, checksum_off)
    if old_checksum:
        write_u32(data, checksum_off, 0)
        changes["patches"].append({"name": "Zero PE Checksum"})
        if verbose:
            print(f"[PATCH 4] Zeroed PE checksum (was 0x{old_checksum:X})")

    # Zero the IAT data directory — it points to SecuROM's Sidata IAT which
    # is no longer relevant (we use .rdata IAT via the rebuilt IDT instead)
    iat_dir_off = pe.data_dir_offset + 12 * 8
    old_iat_rva = read_u32(data, iat_dir_off)
    if old_iat_rva:
        write_u32(data, iat_dir_off, 0)
        write_u32(data, iat_dir_off + 4, 0)
        if verbose:
            print(f"          Zeroed IAT data directory (was RVA 0x{old_iat_rva:X})")
    if verbose and (old_checksum or old_iat_rva):
        print()

    # --- Patch 5: Rebuild import directory with .rdata IAT entries ---
    # The text transplant means .text code uses the game's ORIGINAL IAT in .rdata
    # (not SecuROM's relocated IAT in Sidata). We must build an IDT whose
    # FirstThunk entries point to the .rdata IAT so the Windows loader resolves them.
    # We extract the correct IDT entries from the donor (cracked) exe.

    securom_sec = None
    for s in pe.sections:
        if s.name == ".securom":
            securom_sec = s

    import_injected = False
    if securom_sec:
        # Extract the .rdata-based IDT entries from the donor exe
        donor_idt_rva = donor_pe.get_data_dir(1)[0]
        donor_sec = next((s for s in donor_pe.sections if s.contains_rva(donor_idt_rva)), None)

        rdata_idt_entries: list[tuple[int, int, int, int, int]] = []
        if donor_sec:
            donor_idt_off = donor_sec.rva_to_file(donor_idt_rva)
            off = donor_idt_off
            while off + 20 <= len(donor_data):
                oft = read_u32(donor_data, off)
                ts = read_u32(donor_data, off + 4)
                fc = read_u32(donor_data, off + 8)
                name_rva = read_u32(donor_data, off + 12)
                ft = read_u32(donor_data, off + 16)
                if oft == 0 and name_rva == 0 and ft == 0:
                    break
                # Only take entries whose FirstThunk is in .rdata (0x705000-0x7F5012)
                # These are the game's original imports that .text code references
                rdata_sec = next((s for s in pe.sections if s.name == ".rdata"), None)
                if rdata_sec and rdata_sec.contains_rva(ft):
                    rdata_idt_entries.append((oft, ts, fc, name_rva, ft))
                off += 20

        if rdata_idt_entries:
            # Find usable padding in .securom — try virt_size gap first, then
            # fall back to zero-space after the existing IDT null terminator
            padding_file = securom_sec.raw_addr + securom_sec.virt_size
            padding_file = (padding_file + 15) & ~15
            padding_rva = securom_sec.virt_addr + (padding_file - securom_sec.raw_addr)
            space_avail = (securom_sec.raw_addr + securom_sec.raw_size) - padding_file

            if space_avail <= 0 or padding_rva >= pe.size_of_image:
                # No gap after virt_size — use space after existing IDT entries
                import_rva_orig = read_u32(data, pe.data_dir_offset + 1 * 8)
                if securom_sec.contains_rva(import_rva_orig):
                    idt_file_off = securom_sec.rva_to_file(import_rva_orig)
                    scan = idt_file_off
                    while scan + 20 <= len(data):
                        if read_u32(data, scan) == 0 and read_u32(data, scan + 12) == 0:
                            break
                        scan += 20
                    scan += 20  # skip null terminator
                    padding_file = (scan + 15) & ~15
                    padding_rva = securom_sec.virt_addr + (padding_file - securom_sec.raw_addr)
                    space_avail = (securom_sec.raw_addr + securom_sec.raw_size) - padding_file

            # Space: entries + cruise.dll entry + null terminator + dll name + IAT/OFT
            needed = (len(rdata_idt_entries) + 2) * 20 + 32
            if space_avail >= needed and padding_rva < pe.size_of_image:
                cursor_file = padding_file
                cursor_rva = padding_rva
                new_idt_rva = cursor_rva

                # Write the .rdata-based IDT entries
                for oft, ts, fc, name_rva, ft in rdata_idt_entries:
                    write_u32(data, cursor_file + 0, oft)
                    write_u32(data, cursor_file + 4, 0)
                    write_u32(data, cursor_file + 8, 0)
                    write_u32(data, cursor_file + 12, name_rva)
                    write_u32(data, cursor_file + 16, ft)
                    cursor_file += 20
                    cursor_rva += 20

                # Add cruise.dll entry
                cruise_idt_off = cursor_file
                cursor_file += 20
                cursor_rva += 20

                # Null terminator
                data[cursor_file:cursor_file + 20] = b"\x00" * 20
                cursor_file += 20
                cursor_rva += 20

                # DLL name string
                dll_name_bytes = b"cruise.dll\x00"
                dll_name_rva = cursor_rva
                data[cursor_file:cursor_file + len(dll_name_bytes)] = dll_name_bytes
                cursor_file += len(dll_name_bytes)
                cursor_rva += len(dll_name_bytes)
                if cursor_file % 4:
                    pad = 4 - (cursor_file % 4)
                    cursor_file += pad
                    cursor_rva += pad

                # IAT for cruise.dll (import by ordinal #1)
                ordinal_import = 0x80000001
                iat_rva = cursor_rva
                struct.pack_into("<I", data, cursor_file, ordinal_import)
                struct.pack_into("<I", data, cursor_file + 4, 0)
                cursor_file += 8
                cursor_rva += 8

                # OFT for cruise.dll
                oft_rva = cursor_rva
                struct.pack_into("<I", data, cursor_file, ordinal_import)
                struct.pack_into("<I", data, cursor_file + 4, 0)
                cursor_file += 8
                cursor_rva += 8

                # Fill in cruise.dll IDT entry
                write_u32(data, cruise_idt_off + 0, oft_rva)
                write_u32(data, cruise_idt_off + 4, 0)
                write_u32(data, cruise_idt_off + 8, 0)
                write_u32(data, cruise_idt_off + 12, dll_name_rva)
                write_u32(data, cruise_idt_off + 16, iat_rva)

                # Update Import Directory data dir
                total_entries = len(rdata_idt_entries) + 2  # + cruise + null
                write_u32(data, pe.data_dir_offset + 1 * 8, new_idt_rva)
                write_u32(data, pe.data_dir_offset + 1 * 8 + 4, total_entries * 20)

                import_injected = True
                changes["patches"].append({
                    "name": "Rebuild IDT with .rdata IAT + cruise.dll",
                    "new_idt_rva": f"0x{new_idt_rva:X}",
                    "game_imports": len(rdata_idt_entries),
                })
                if verbose:
                    print(f"[PATCH 5] Rebuilt import directory at RVA 0x{new_idt_rva:X}")
                    print(f"          {len(rdata_idt_entries)} game imports "
                          f"(.rdata IAT) + cruise.dll")
                    print()

    if not import_injected and verbose:
        print("[PATCH 5] WARNING: Import directory not rebuilt!")
        print("          The exe may crash due to unresolved .rdata IAT entries.")
        print()

    # --- Write output ---
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_bytes(bytes(data))
    changes["output_size"] = len(data)

    if verbose:
        print(f"{'=' * 60}")
        print(f"Output written: {output_path} ({len(data):,} bytes)")
        print()
        print("HOW IT WORKS:")
        print("  The patched exe has its .text section pre-decrypted (from donor).")
        print("  Entry point goes directly to the game's CRT startup, skipping")
        print("  SecuROM's Sitext stub entirely. No Product Activation runs.")
        print("  cruise.dll creates the signaled Event that inline trigger checks")
        print("  expect when they fire during gameplay.")
        print()
        print("REQUIREMENTS:")
        print(f"  1. Place cruise.dll next to the patched exe:")
        print(f"     {output_path.parent / 'cruise.dll'}")
        print(f"  2. Run the patched exe normally.")
        print()
        print("NOTE: The patched exe remains ~16 MB (same as original).")
        print("      Only .text content and PE headers are modified.")

    return changes


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Remove SecuROM v7.37/7.38 DRM from Mercenaries 2 executables")
    parser.add_argument("input", nargs="?",
                        help="Path to the protected exe (demo or retail)")
    parser.add_argument("--output", "-o",
                        help="Output path (default: auto-named in same directory)")
    parser.add_argument("--donor", "-d",
                        help="Path to pre-cracked donor exe (required for retail)")
    parser.add_argument("--timer", type=float, default=0.0,
                        help="Demo timer value in seconds (0=disabled, default: 0)")
    parser.add_argument("--analyze", action="store_true",
                        help="Only analyze the PE structure, don't patch")
    parser.add_argument("--generate-cruise", action="store_true",
                        help="Generate cruise.dll next to the output exe")
    parser.add_argument("--generate-cruise-asi", action="store_true",
                        help="Generate cruise.asi for use with ASI Loader (no exe patching)")
    parser.add_argument("--asi-output",
                        help="Output path for cruise.asi (with --generate-cruise-asi)")
    parser.add_argument("--verbose", "-v", action="store_true", default=True,
                        help="Verbose output (default: true)")
    parser.add_argument("--quiet", "-q", action="store_true",
                        help="Suppress output")

    args = parser.parse_args()

    if args.quiet:
        args.verbose = False

    # Standalone ASI generation (no exe input required)
    if args.generate_cruise_asi:
        if args.asi_output:
            asi_path = Path(args.asi_output)
        elif args.input:
            asi_path = Path(args.input).parent / "scripts" / "cruise.asi"
        else:
            asi_path = Path("cruise.asi")
        asi_path.parent.mkdir(parents=True, exist_ok=True)
        asi_data = generate_cruise_dll()
        asi_path.write_bytes(asi_data)
        if not args.quiet:
            print(f"Generated: {asi_path} ({len(asi_data):,} bytes)")
            print(f"  This is a valid PE DLL loadable by ASI Loader via LoadLibrary.")
            print(f"  DllMain creates Event: v7_XXXX (PID XOR 0x19EA3FD3)")
            print(f"  bManualReset=TRUE, bInitialState=TRUE (signaled)")
            print()
            print("Setup for ASI Loader (no exe patching required):")
            print("  1. Place dinput8.dll (ASI Loader Win32) in game directory")
            print("  2. Place cruise.asi in game/scripts/ folder")
            print("  3. Create game/scripts/global.ini with:")
            print("       [GlobalSets]")
            print("       DontLoadFromDllMain=0")
            print("  4. Run the game normally")
        sys.exit(0)

    if not args.input:
        parser.print_help()
        sys.exit(1)

    input_path = Path(args.input)
    if not input_path.exists():
        print(f"ERROR: Input file not found: {input_path}")
        sys.exit(1)

    if args.analyze:
        data = input_path.read_bytes()
        pe = PEInfo(data)
        pe.print_analysis()
        exe_type = detect_exe_type(pe)
        print(f"\nDetected type: {exe_type}")
        if exe_type == "retail":
            print("  → Use: python3 tools/apply_securom_patch.py <this_exe> -o <output>")
            print("    Or:  make crack-game RETAIL_EXE=<this_exe>")
        elif exe_type == "demo":
            print("  → Can be patched directly (no donor needed)")
        elif exe_type == "cracked":
            print("  → This is already a cracked/unpacked executable")
        sys.exit(0)

    # Detect exe type
    data = input_path.read_bytes()
    pe = PEInfo(data)
    exe_type = detect_exe_type(pe)

    if args.verbose:
        print(f"Detected executable type: {exe_type}")
        print()

    if exe_type == "retail":
        if not args.donor:
            print("ERROR: Retail exe detected. Use the patch-based tool instead:")
            print()
            print("  python3 tools/apply_securom_patch.py <retail_v1.1_exe> -o <output>")
            print()
            print("  Or via make: make crack-game RETAIL_EXE=<path>")
            print()
            print("  (Legacy --donor mode is still supported if you have the cracked exe)")
            sys.exit(1)

        donor_path = Path(args.donor)
        if not donor_path.exists():
            print(f"ERROR: Donor file not found: {donor_path}")
            sys.exit(1)

        if args.output:
            output_path = Path(args.output)
        else:
            output_path = input_path.parent / (input_path.stem + "-Patched.exe")

        changes = patch_retail_exe(input_path, output_path, donor_path,
                                   verbose=args.verbose)
    elif exe_type == "cracked":
        print("This executable is already cracked/unpacked. No patching needed.")
        print("Just place cruise.dll next to it and run.")
        sys.exit(0)
    else:
        # Demo or unknown — use original demo patcher
        if args.output:
            output_path = Path(args.output)
        else:
            output_path = input_path.parent / (input_path.stem + "-Patched.exe")

        changes = patch_demo_exe(input_path, output_path, args.timer,
                                 verbose=args.verbose)

    if args.generate_cruise:
        cruise_path = output_path.parent / "cruise.dll"
        cruise_data = generate_cruise_dll()
        cruise_path.write_bytes(cruise_data)
        if args.verbose:
            print(f"\nGenerated: {cruise_path} ({len(cruise_data):,} bytes)")
            print("  Creates Event: v7_XXXX (PID XOR 0x19EA3FD3)")
            print("  bManualReset=TRUE, bInitialState=TRUE (signaled)")
            print("  Matches original crack cruise.dll behavior.")


if __name__ == "__main__":
    main()
