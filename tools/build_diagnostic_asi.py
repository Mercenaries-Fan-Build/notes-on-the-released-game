#!/usr/bin/env python3
"""Generate a diagnostic ASI plugin that proves the ASI Loader is working.

This generates the simplest possible DLL that:
  1. Creates a file "asi_loader_works.txt" in the game directory on DLL_PROCESS_ATTACH
  2. Optionally shows a MessageBox (pass --messagebox)

If the file appears after running the game, the ASI Loader is confirmed working.
This is a debugging tool — use build_dlc_asi.py for the actual DLC plugin.

Usage:
  python3 tools/build_diagnostic_asi.py --output "path/to/game/scripts/diagnostic.asi"
  python3 tools/build_diagnostic_asi.py --output "path/to/game/scripts/diagnostic.asi" --messagebox
"""
from __future__ import annotations

import argparse
import struct
import sys
from pathlib import Path


def generate_diagnostic_asi(use_messagebox: bool = False) -> bytes:
    """Generate a minimal diagnostic DLL that writes a canary file on load.

    DllMain does:
      1. CreateFileA("dlc_enable.log", GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, 0, NULL)
      2. WriteFile(handle, message, len, &written, NULL)
      3. CloseHandle(handle)
      4. [optional] MessageBoxA(NULL, "ASI Loaded!", "Diagnostic", MB_OK)
      5. Return TRUE
    """
    IMAGE_BASE = 0x10000000
    SECTION_ALIGN = 0x1000
    FILE_ALIGN = 0x200

    CODE_RVA = 0x1000
    CODE_FILE = 0x400
    CODE_RAW_SIZE = 0x400
    DATA_RVA = 0x2000
    DATA_FILE = 0x800
    DATA_RAW_SIZE = 0x200
    IDATA_RVA = 0x3000
    IDATA_FILE = 0xA00
    IDATA_RAW_SIZE = 0x400
    RELOC_RVA = 0x4000
    RELOC_FILE = 0xE00
    RELOC_RAW_SIZE = 0x200

    SIZE_OF_IMAGE = 0x5000
    FILE_SIZE = 0x1000

    # --- DATA section strings ---
    # Offset 0x00: filename "dlc_enable.log\0"
    # Offset 0x10: log message
    # Offset 0x80: MessageBox title
    # Offset 0x90: MessageBox text

    FILENAME_OFF = 0x00
    FILENAME = b"dlc_enable.log\x00"
    MSG_OFF = 0x10
    MSG = b"[OK] dlc_enable.asi loaded successfully!\r\nProcess attached. ASI Loader is working.\r\nTimestamp: DllMain fired on DLL_PROCESS_ATTACH.\r\n\x00"
    MBOX_TITLE_OFF = 0x90
    MBOX_TITLE = b"DLC Enable Plugin\x00"
    MBOX_TEXT_OFF = 0xA4
    MBOX_TEXT = b"dlc_enable.asi loaded!\nASI Loader is confirmed working.\nCheck dlc_enable.log for details.\x00"

    FILENAME_VA = IMAGE_BASE + DATA_RVA + FILENAME_OFF
    MSG_VA = IMAGE_BASE + DATA_RVA + MSG_OFF
    MBOX_TITLE_VA = IMAGE_BASE + DATA_RVA + MBOX_TITLE_OFF
    MBOX_TEXT_VA = IMAGE_BASE + DATA_RVA + MBOX_TEXT_OFF

    # Build data section
    data_sec = bytearray(DATA_RAW_SIZE)
    data_sec[FILENAME_OFF:FILENAME_OFF + len(FILENAME)] = FILENAME
    data_sec[MSG_OFF:MSG_OFF + len(MSG)] = MSG
    data_sec[MBOX_TITLE_OFF:MBOX_TITLE_OFF + len(MBOX_TITLE)] = MBOX_TITLE
    data_sec[MBOX_TEXT_OFF:MBOX_TEXT_OFF + len(MBOX_TEXT)] = MBOX_TEXT

    # --- .idata section (KERNEL32.dll + USER32.dll) ---
    idata_sec = bytearray(IDATA_RAW_SIZE)

    # IDT layout: 2 DLL entries + null terminator = 3 × 20 bytes = 60 bytes
    # IDT[0]: KERNEL32.dll at offset 0x00
    # IDT[1]: USER32.dll at offset 0x14
    # IDT[2]: null at offset 0x28

    # KERNEL32 imports: CreateFileA, WriteFile, CloseHandle
    # USER32 imports: MessageBoxA

    K32_OFT_OFF = 0x3C  # KERNEL32 OFT array offset in idata
    K32_IAT_OFF = 0x50  # KERNEL32 IAT array offset in idata (3 entries + null = 16 bytes)
    U32_OFT_OFF = 0x60  # USER32 OFT array
    U32_IAT_OFF = 0x68  # USER32 IAT array (1 entry + null = 8 bytes)
    K32_NAME_OFF = 0x70  # "KERNEL32.dll\0"
    U32_NAME_OFF = 0x80  # "USER32.dll\0"
    HN_BASE = 0x8C       # Hint/Name entries start

    # Write DLL names
    idata_sec[K32_NAME_OFF:K32_NAME_OFF + 13] = b"KERNEL32.dll\x00"
    idata_sec[U32_NAME_OFF:U32_NAME_OFF + 11] = b"USER32.dll\x00"

    # IDT[0]: KERNEL32.dll
    struct.pack_into("<I", idata_sec, 0, IDATA_RVA + K32_OFT_OFF)
    struct.pack_into("<I", idata_sec, 4, 0)
    struct.pack_into("<I", idata_sec, 8, 0)
    struct.pack_into("<I", idata_sec, 12, IDATA_RVA + K32_NAME_OFF)
    struct.pack_into("<I", idata_sec, 16, IDATA_RVA + K32_IAT_OFF)

    # IDT[1]: USER32.dll
    struct.pack_into("<I", idata_sec, 20, IDATA_RVA + U32_OFT_OFF)
    struct.pack_into("<I", idata_sec, 24, 0)
    struct.pack_into("<I", idata_sec, 28, 0)
    struct.pack_into("<I", idata_sec, 32, IDATA_RVA + U32_NAME_OFF)
    struct.pack_into("<I", idata_sec, 36, IDATA_RVA + U32_IAT_OFF)

    # IDT[2]: null terminator at offset 0x28 (already zero)

    # Hint/Name entries
    k32_imports = ["CreateFileA", "WriteFile", "CloseHandle"]
    u32_imports = ["MessageBoxA"]

    hn_pos = HN_BASE
    k32_hn_rvas = []
    for name in k32_imports:
        k32_hn_rvas.append(IDATA_RVA + hn_pos)
        struct.pack_into("<H", idata_sec, hn_pos, 0)
        name_bytes = name.encode("ascii") + b"\x00"
        idata_sec[hn_pos + 2:hn_pos + 2 + len(name_bytes)] = name_bytes
        hn_pos += 2 + len(name_bytes)
        if hn_pos % 2:
            hn_pos += 1

    u32_hn_rvas = []
    for name in u32_imports:
        u32_hn_rvas.append(IDATA_RVA + hn_pos)
        struct.pack_into("<H", idata_sec, hn_pos, 0)
        name_bytes = name.encode("ascii") + b"\x00"
        idata_sec[hn_pos + 2:hn_pos + 2 + len(name_bytes)] = name_bytes
        hn_pos += 2 + len(name_bytes)
        if hn_pos % 2:
            hn_pos += 1

    # KERNEL32 OFT + IAT
    for idx, rva in enumerate(k32_hn_rvas):
        struct.pack_into("<I", idata_sec, K32_OFT_OFF + idx * 4, rva)
    struct.pack_into("<I", idata_sec, K32_OFT_OFF + len(k32_hn_rvas) * 4, 0)

    for idx, rva in enumerate(k32_hn_rvas):
        struct.pack_into("<I", idata_sec, K32_IAT_OFF + idx * 4, rva)
    struct.pack_into("<I", idata_sec, K32_IAT_OFF + len(k32_hn_rvas) * 4, 0)

    # USER32 OFT + IAT
    for idx, rva in enumerate(u32_hn_rvas):
        struct.pack_into("<I", idata_sec, U32_OFT_OFF + idx * 4, rva)
    struct.pack_into("<I", idata_sec, U32_OFT_OFF + len(u32_hn_rvas) * 4, 0)

    for idx, rva in enumerate(u32_hn_rvas):
        struct.pack_into("<I", idata_sec, U32_IAT_OFF + idx * 4, rva)
    struct.pack_into("<I", idata_sec, U32_IAT_OFF + len(u32_hn_rvas) * 4, 0)

    # IAT virtual addresses for code references
    IAT_CREATE_FILE = IMAGE_BASE + IDATA_RVA + K32_IAT_OFF + 0
    IAT_WRITE_FILE = IMAGE_BASE + IDATA_RVA + K32_IAT_OFF + 4
    IAT_CLOSE_HANDLE = IMAGE_BASE + IDATA_RVA + K32_IAT_OFF + 8
    IAT_MESSAGEBOX = IMAGE_BASE + IDATA_RVA + U32_IAT_OFF + 0

    # --- CODE section ---
    code = bytearray(CODE_RAW_SIZE)
    relocs: list[int] = []
    i = 0

    # DllMain(hinstDLL, fdwReason, lpvReserved)
    dllmain_offset = i

    # push ebp / mov ebp, esp / sub esp, 8
    code[i] = 0x55; i += 1
    code[i:i+2] = b"\x8B\xEC"; i += 2
    code[i:i+3] = b"\x83\xEC\x08"; i += 3

    # cmp dword [ebp+12], 1 (DLL_PROCESS_ATTACH)
    code[i:i+4] = b"\x83\x7D\x0C\x01"; i += 4
    # jne skip_all
    code[i] = 0x75; i += 1
    jne_skip_pos = i; i += 1

    # --- CreateFileA("dlc_enable.log", GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, 0, NULL) ---
    # push 0 (hTemplateFile)
    code[i:i+2] = b"\x6A\x00"; i += 2
    # push 0x80 (FILE_ATTRIBUTE_NORMAL)
    code[i] = 0x68; i += 1
    struct.pack_into("<I", code, i, 0x80); i += 4
    # push 2 (CREATE_ALWAYS)
    code[i:i+2] = b"\x6A\x02"; i += 2
    # push 0 (lpSecurityAttributes)
    code[i:i+2] = b"\x6A\x00"; i += 2
    # push 0 (dwShareMode)
    code[i:i+2] = b"\x6A\x00"; i += 2
    # push 0x40000000 (GENERIC_WRITE)
    code[i] = 0x68; i += 1
    struct.pack_into("<I", code, i, 0x40000000); i += 4
    # push FILENAME_VA
    code[i] = 0x68; i += 1
    struct.pack_into("<I", code, i, FILENAME_VA)
    relocs.append(i); i += 4
    # call [IAT_CREATE_FILE]
    code[i:i+2] = b"\xFF\x15"; i += 2
    struct.pack_into("<I", code, i, IAT_CREATE_FILE)
    relocs.append(i); i += 4

    # mov [ebp-4], eax  (save file handle)
    code[i:i+3] = b"\x89\x45\xFC"; i += 3

    # cmp eax, -1 (INVALID_HANDLE_VALUE)
    code[i:i+3] = b"\x83\xF8\xFF"; i += 3
    # je skip_write
    code[i] = 0x74; i += 1
    je_skip_write = i; i += 1

    # --- WriteFile(handle, MSG_VA, msg_len, &written, NULL) ---
    msg_len = len(MSG) - 1  # exclude null terminator
    # push 0 (lpOverlapped)
    code[i:i+2] = b"\x6A\x00"; i += 2
    # lea ecx, [ebp-8] / push ecx (lpNumberOfBytesWritten)
    code[i:i+3] = b"\x8D\x4D\xF8"; i += 3
    code[i] = 0x51; i += 1
    # push msg_len (nNumberOfBytesToWrite)
    code[i] = 0x68; i += 1
    struct.pack_into("<I", code, i, msg_len); i += 4
    # push MSG_VA (lpBuffer)
    code[i] = 0x68; i += 1
    struct.pack_into("<I", code, i, MSG_VA)
    relocs.append(i); i += 4
    # push eax (hFile)
    code[i:i+3] = b"\xFF\x75\xFC"; i += 3  # push [ebp-4]
    # call [IAT_WRITE_FILE]
    code[i:i+2] = b"\xFF\x15"; i += 2
    struct.pack_into("<I", code, i, IAT_WRITE_FILE)
    relocs.append(i); i += 4

    # --- CloseHandle(handle) ---
    # push [ebp-4] (hFile)
    code[i:i+3] = b"\xFF\x75\xFC"; i += 3
    # call [IAT_CLOSE_HANDLE]
    code[i:i+2] = b"\xFF\x15"; i += 2
    struct.pack_into("<I", code, i, IAT_CLOSE_HANDLE)
    relocs.append(i); i += 4

    # skip_write:
    skip_write = i
    code[je_skip_write] = skip_write - (je_skip_write + 1)

    if use_messagebox:
        # --- MessageBoxA(NULL, text, title, MB_OK) ---
        # push 0 (MB_OK)
        code[i:i+2] = b"\x6A\x00"; i += 2
        # push MBOX_TITLE_VA
        code[i] = 0x68; i += 1
        struct.pack_into("<I", code, i, MBOX_TITLE_VA)
        relocs.append(i); i += 4
        # push MBOX_TEXT_VA
        code[i] = 0x68; i += 1
        struct.pack_into("<I", code, i, MBOX_TEXT_VA)
        relocs.append(i); i += 4
        # push 0 (hWnd)
        code[i:i+2] = b"\x6A\x00"; i += 2
        # call [IAT_MESSAGEBOX]
        code[i:i+2] = b"\xFF\x15"; i += 2
        struct.pack_into("<I", code, i, IAT_MESSAGEBOX)
        relocs.append(i); i += 4

    # skip_all:
    skip_all = i
    code[jne_skip_pos] = skip_all - (jne_skip_pos + 1)

    # mov eax, 1 (return TRUE)
    code[i:i+5] = b"\xB8\x01\x00\x00\x00"; i += 5
    # leave / ret 12
    code[i:i+2] = b"\x8B\xE5"; i += 2
    code[i] = 0x5D; i += 1
    code[i:i+3] = b"\xC2\x0C\x00"; i += 3

    dllmain_rva = CODE_RVA + dllmain_offset

    assert i <= CODE_RAW_SIZE, f"Code overflow: {i} > {CODE_RAW_SIZE}"

    # --- .reloc section ---
    reloc_sec = bytearray(RELOC_RAW_SIZE)
    reloc_entries = []
    for r in sorted(relocs):
        reloc_entries.append(0x3000 | (r & 0xFFF))
    if len(reloc_entries) % 2 != 0:
        reloc_entries.append(0x0000)
    block_size = 8 + len(reloc_entries) * 2
    struct.pack_into("<I", reloc_sec, 0, CODE_RVA)
    struct.pack_into("<I", reloc_sec, 4, block_size)
    for idx, entry in enumerate(reloc_entries):
        struct.pack_into("<H", reloc_sec, 8 + idx * 2, entry)

    # --- PE Headers ---
    dos_header = bytearray(0x80)
    dos_header[0:2] = b"MZ"
    struct.pack_into("<I", dos_header, 0x3C, 0x80)

    pe_sig = b"PE\x00\x00"

    coff_header = bytearray(20)
    struct.pack_into("<H", coff_header, 0, 0x14C)
    struct.pack_into("<H", coff_header, 2, 4)
    struct.pack_into("<I", coff_header, 4, 0x683B4A00)
    struct.pack_into("<H", coff_header, 16, 224)
    struct.pack_into("<H", coff_header, 18, 0x2102)

    opt_header = bytearray(224)
    struct.pack_into("<H", opt_header, 0, 0x10B)
    opt_header[2] = 14
    struct.pack_into("<I", opt_header, 4, CODE_RAW_SIZE)
    struct.pack_into("<I", opt_header, 8, DATA_RAW_SIZE + IDATA_RAW_SIZE + RELOC_RAW_SIZE)
    struct.pack_into("<I", opt_header, 16, dllmain_rva)
    struct.pack_into("<I", opt_header, 20, CODE_RVA)
    struct.pack_into("<I", opt_header, 24, DATA_RVA)
    struct.pack_into("<I", opt_header, 28, IMAGE_BASE)
    struct.pack_into("<I", opt_header, 32, SECTION_ALIGN)
    struct.pack_into("<I", opt_header, 36, FILE_ALIGN)
    struct.pack_into("<H", opt_header, 40, 6)
    struct.pack_into("<H", opt_header, 48, 6)
    struct.pack_into("<I", opt_header, 56, SIZE_OF_IMAGE)
    struct.pack_into("<I", opt_header, 60, 0x400)
    struct.pack_into("<H", opt_header, 68, 2)
    struct.pack_into("<H", opt_header, 70, 0x0040)
    struct.pack_into("<I", opt_header, 72, 0x100000)
    struct.pack_into("<I", opt_header, 76, 0x1000)
    struct.pack_into("<I", opt_header, 80, 0x100000)
    struct.pack_into("<I", opt_header, 84, 0x1000)
    struct.pack_into("<I", opt_header, 92, 16)

    # Data directories
    # [1] Import
    struct.pack_into("<I", opt_header, 96 + 1 * 8, IDATA_RVA)
    struct.pack_into("<I", opt_header, 96 + 1 * 8 + 4, 0x3C)  # 3 IDT entries × 20
    # [5] BaseReloc
    struct.pack_into("<I", opt_header, 96 + 5 * 8, RELOC_RVA)
    struct.pack_into("<I", opt_header, 96 + 5 * 8 + 4, block_size)
    # [12] IAT
    all_imports = k32_imports + u32_imports
    struct.pack_into("<I", opt_header, 96 + 12 * 8, IDATA_RVA + K32_IAT_OFF)
    struct.pack_into("<I", opt_header, 96 + 12 * 8 + 4, (len(k32_imports) + 1 + len(u32_imports) + 1) * 4)

    # Section headers
    sections = bytearray(4 * 40)

    # CODE
    sections[0:5] = b"CODE\x00"
    struct.pack_into("<I", sections, 8, SECTION_ALIGN)
    struct.pack_into("<I", sections, 12, CODE_RVA)
    struct.pack_into("<I", sections, 16, CODE_RAW_SIZE)
    struct.pack_into("<I", sections, 20, CODE_FILE)
    struct.pack_into("<I", sections, 36, 0x60000020)

    # DATA
    sections[40:44] = b"DATA"
    struct.pack_into("<I", sections, 48, SECTION_ALIGN)
    struct.pack_into("<I", sections, 52, DATA_RVA)
    struct.pack_into("<I", sections, 56, DATA_RAW_SIZE)
    struct.pack_into("<I", sections, 60, DATA_FILE)
    struct.pack_into("<I", sections, 76, 0xC0000040)

    # .idata
    sections[80:86] = b".idata"
    struct.pack_into("<I", sections, 88, SECTION_ALIGN)
    struct.pack_into("<I", sections, 92, IDATA_RVA)
    struct.pack_into("<I", sections, 96, IDATA_RAW_SIZE)
    struct.pack_into("<I", sections, 100, IDATA_FILE)
    struct.pack_into("<I", sections, 116, 0xC0000040)

    # .reloc
    sections[120:126] = b".reloc"
    struct.pack_into("<I", sections, 128, SECTION_ALIGN)
    struct.pack_into("<I", sections, 132, RELOC_RVA)
    struct.pack_into("<I", sections, 136, RELOC_RAW_SIZE)
    struct.pack_into("<I", sections, 140, RELOC_FILE)
    struct.pack_into("<I", sections, 156, 0x42000040)

    # Assemble
    headers = dos_header + pe_sig + coff_header + opt_header + sections
    assert len(headers) <= 0x400, f"Headers too large: {len(headers)}"
    headers += b"\x00" * (0x400 - len(headers))

    image = bytearray(headers) + code + data_sec + idata_sec + reloc_sec

    final_size = 0x1200
    if len(image) < final_size:
        image += b"\x00" * (final_size - len(image))
    elif len(image) > final_size:
        image = image[:final_size]

    return bytes(image)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate a diagnostic ASI plugin that proves ASI Loader is working")
    parser.add_argument("--output", "-o", default="diagnostic.asi",
                        help="Output path (default: diagnostic.asi)")
    parser.add_argument("--messagebox", action="store_true",
                        help="Include MessageBoxA popup on load (unmistakable signal)")

    args = parser.parse_args()
    output_path = Path(args.output)

    print("Generating diagnostic ASI plugin...")
    asi_data = generate_diagnostic_asi(use_messagebox=args.messagebox)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_bytes(asi_data)

    print(f"Generated: {output_path} ({len(asi_data):,} bytes)")
    print()
    print("What this plugin does:")
    print("  On DLL_PROCESS_ATTACH (when loaded by ASI Loader):")
    print("    1. Creates 'dlc_enable.log' in the game directory")
    print("    2. Writes a success message to the log file")
    if args.messagebox:
        print("    3. Shows a MessageBox popup (blocks until dismissed)")
    print()
    print("How to test:")
    print("  1. Place this file as <game>/scripts/dlc_enable.asi")
    print("  2. Ensure dinput8.dll (ASI Loader) is in the game directory")
    print("  3. Ensure scripts/global.ini has: DontLoadFromDllMain=0")
    print("  4. Run the game")
    print("  5. Check for 'dlc_enable.log' in the game directory")
    if args.messagebox:
        print("     (or just wait for the popup!)")
    print()
    print("If dlc_enable.log does NOT appear, the ASI Loader itself is not loading.")
    print("Common causes:")
    print("  - dinput8.dll is wrong architecture (must be 32-bit/Win32)")
    print("  - dinput8.dll is not in the same directory as the .exe")
    print("  - The EXE's import table doesn't reference DINPUT8.dll")
    print("  - Antivirus is blocking the DLL proxy")


if __name__ == "__main__":
    main()
