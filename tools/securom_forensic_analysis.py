#!/usr/bin/env python3
"""
SecuROM Forensic Analysis of Mercenaries 2 EXE
Analyzes the S* sections, .securom section, and reloaded section to determine:
1. Whether encrypted sections were decrypted by the crack
2. What code they contain
3. SecuROM API entry points and trigger functions
4. AES key material or key derivation routines
"""

from __future__ import annotations
import struct
import math
import sys
from pathlib import Path
from collections import Counter

EXE_PATH = Path("/Users/austinkregel/src/mercenaries-game/output/patched/Mercenaries2.exe")
IMAGE_BASE = 0x00400000

SECTIONS = {
    "Stext":    {"va": 0x01649000, "vsize": 0x0063B000},
    "Sitext":   {"va": 0x01C84000, "vsize": 0x00007000},
    "Srdata":   {"va": 0x01C8B000, "vsize": 0x0005A000},
    "Sdata":    {"va": 0x01CE5000, "vsize": 0x002FE000},
    "Sidata":   {"va": 0x01FE3000, "vsize": 0x00006000},
    ".securom": {"va": 0x01FE9000, "vsize": 0x013175F8},
    "reloaded": {"va": 0x03301000, "vsize": 0x00001000, "raw_size": 0x330},
}


def va_to_file_offset(va: int) -> int:
    return va - IMAGE_BASE


def shannon_entropy(data: bytes) -> float:
    if not data:
        return 0.0
    counts = Counter(data)
    length = len(data)
    entropy = 0.0
    for count in counts.values():
        p = count / length
        if p > 0:
            entropy -= p * math.log2(p)
    return entropy


def hex_dump(data: bytes, offset: int = 0, width: int = 16) -> str:
    lines = []
    for i in range(0, len(data), width):
        chunk = data[i:i+width]
        hex_part = " ".join(f"{b:02X}" for b in chunk)
        ascii_part = "".join(chr(b) if 32 <= b < 127 else "." for b in chunk)
        lines.append(f"  {offset+i:08X}: {hex_part:<{width*3}}  {ascii_part}")
    return "\n".join(lines)


def count_x86_patterns(data: bytes) -> dict:
    """Count recognizable x86 code patterns."""
    patterns = {
        "push_ebp_mov_esp (55 8B EC)": 0,
        "ret (C3)": 0,
        "ret_N (C2 xx xx)": 0,
        "int3_padding (CC)": 0,
        "nop (90)": 0,
        "call_rel32 (E8)": 0,
        "jmp_rel32 (E9)": 0,
        "push_imm32 (68)": 0,
        "mov_eax_imm32 (B8)": 0,
        "xor_eax_eax (33 C0)": 0,
        "sub_esp (83 EC)": 0,
        "push_esi (56)": 0,
        "push_edi (57)": 0,
        "push_ebx (53)": 0,
    }

    for i in range(len(data) - 2):
        b0, b1, b2 = data[i], data[i+1] if i+1 < len(data) else 0, data[i+2] if i+2 < len(data) else 0
        if b0 == 0x55 and b1 == 0x8B and b2 == 0xEC:
            patterns["push_ebp_mov_esp (55 8B EC)"] += 1
        if b0 == 0xC3:
            patterns["ret (C3)"] += 1
        if b0 == 0xC2:
            patterns["ret_N (C2 xx xx)"] += 1
        if b0 == 0xCC:
            patterns["int3_padding (CC)"] += 1
        if b0 == 0x90:
            patterns["nop (90)"] += 1
        if b0 == 0xE8:
            patterns["call_rel32 (E8)"] += 1
        if b0 == 0xE9:
            patterns["jmp_rel32 (E9)"] += 1
        if b0 == 0x68:
            patterns["push_imm32 (68)"] += 1
        if b0 == 0xB8:
            patterns["mov_eax_imm32 (B8)"] += 1
        if b0 == 0x33 and b1 == 0xC0:
            patterns["xor_eax_eax (33 C0)"] += 1
        if b0 == 0x83 and b1 == 0xEC:
            patterns["sub_esp (83 EC)"] += 1
        if b0 == 0x56:
            patterns["push_esi (56)"] += 1
        if b0 == 0x57:
            patterns["push_edi (57)"] += 1
        if b0 == 0x53:
            patterns["push_ebx (53)"] += 1

    return patterns


def find_strings(data: bytes, min_length: int = 6) -> list[tuple[int, str]]:
    """Find printable ASCII strings in binary data."""
    results = []
    current = []
    start = 0
    for i, b in enumerate(data):
        if 32 <= b < 127:
            if not current:
                start = i
            current.append(chr(b))
        else:
            if len(current) >= min_length:
                results.append((start, "".join(current)))
            current = []
    if len(current) >= min_length:
        results.append((start, "".join(current)))
    return results


def search_for_securom_strings(data: bytes, base_offset: int) -> list[tuple[int, str]]:
    """Search for SecuROM-specific strings."""
    targets = [
        b"SecuROM", b"DADC", b"protect", b"PA_",
        b"v7_", b"securom", b"SECUROM",
        b"AES", b"aes", b"RSA", b"rsa",
        b"key", b"KEY", b"crypt", b"CRYPT",
        b"decrypt", b"DECRYPT", b"encrypt", b"ENCRYPT",
        b"trigger", b"TRIGGER",
        b"license", b"LICENSE",
        b"disc", b"DISC",
        b"authentic", b"AUTHENTIC",
        b"tamper", b"TAMPER",
        b"debug", b"DEBUG",
        b"virtual", b"VIRTUAL",
        b"VM", b"vm_",
        b"CmdLine", b"OpenEvent",
        b"CreateEvent", b"Mutex",
    ]
    results = []
    for target in targets:
        idx = 0
        while True:
            idx = data.find(target, idx)
            if idx == -1:
                break
            context_start = max(0, idx - 4)
            context_end = min(len(data), idx + len(target) + 32)
            context = data[context_start:context_end]
            ascii_str = "".join(chr(b) if 32 <= b < 127 else "." for b in context)
            results.append((base_offset + idx, f"{target.decode('ascii', errors='replace')}: ...{ascii_str}..."))
            idx += 1
    return results


def analyze_aes_patterns(data: bytes, base_offset: int) -> list[str]:
    """Look for AES S-box, round constants, or key schedule patterns."""
    findings = []

    aes_sbox_start = bytes([0x63, 0x7C, 0x77, 0x7B, 0xF2, 0x6B, 0x6F, 0xC5])
    idx = data.find(aes_sbox_start)
    if idx != -1:
        findings.append(f"  POSSIBLE AES S-BOX at file offset 0x{base_offset + idx:08X}")
        sbox_data = data[idx:idx+256]
        findings.append(f"  First 32 bytes: {' '.join(f'{b:02X}' for b in sbox_data[:32])}")

    aes_rcon = bytes([0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1B, 0x36])
    idx = data.find(aes_rcon)
    if idx != -1:
        findings.append(f"  POSSIBLE AES RCON TABLE at file offset 0x{base_offset + idx:08X}")

    inv_sbox_start = bytes([0x52, 0x09, 0x6A, 0xD5, 0x30, 0x36, 0xA5, 0x38])
    idx = data.find(inv_sbox_start)
    if idx != -1:
        findings.append(f"  POSSIBLE AES INVERSE S-BOX at file offset 0x{base_offset + idx:08X}")

    return findings


def main():
    exe_data = EXE_PATH.read_bytes()
    exe_size = len(exe_data)
    print(f"EXE size: {exe_size} bytes ({exe_size / 1024 / 1024:.2f} MB)")
    print(f"EXE path: {EXE_PATH}")
    print()

    print("=" * 80)
    print("SECTION 1: ENTROPY ANALYSIS + FIRST 512 BYTES OF EACH SECTION")
    print("=" * 80)
    print()

    for name, info in SECTIONS.items():
        va = info["va"]
        vsize = info["vsize"]
        raw_size = info.get("raw_size", vsize)
        file_offset = va_to_file_offset(va)

        print(f"--- {name} ---")
        print(f"  VA: 0x{va:08X}  File Offset: 0x{file_offset:08X}")
        print(f"  Virtual Size: 0x{vsize:08X} ({vsize} bytes, {vsize/1024:.1f} KB)")
        print(f"  Raw Size: 0x{raw_size:08X} ({raw_size} bytes)")
        print()

        if file_offset + raw_size > exe_size:
            print(f"  WARNING: Section extends beyond file! file_offset+raw_size=0x{file_offset+raw_size:08X} > exe_size=0x{exe_size:08X}")
            raw_size = min(raw_size, exe_size - file_offset)

        section_data = exe_data[file_offset:file_offset + raw_size]

        entropy_4k = shannon_entropy(section_data[:4096])
        entropy_full = shannon_entropy(section_data)
        print(f"  Entropy (first 4KB): {entropy_4k:.4f}")
        print(f"  Entropy (full section): {entropy_full:.4f}")

        if entropy_4k > 7.5:
            print(f"  ASSESSMENT: HIGH ENTROPY — likely encrypted or compressed")
        elif entropy_4k > 6.0:
            print(f"  ASSESSMENT: MODERATE ENTROPY — likely compiled code")
        elif entropy_4k > 4.0:
            print(f"  ASSESSMENT: LOW-MODERATE ENTROPY — data/strings/tables")
        else:
            print(f"  ASSESSMENT: LOW ENTROPY — padding, zeroes, or sparse data")
        print()

        dump_size = min(512, raw_size)
        print(f"  First {dump_size} bytes:")
        print(hex_dump(section_data[:dump_size], file_offset))
        print()

        if name == "reloaded":
            print(f"  FULL 'reloaded' section ({raw_size} bytes):")
            print(hex_dump(section_data[:raw_size], file_offset))
            print()
            print(f"  Strings in 'reloaded' section:")
            strings = find_strings(section_data[:raw_size], min_length=4)
            for off, s in strings:
                print(f"    +0x{off:04X}: {s}")
            print()

    print()
    print("=" * 80)
    print("SECTION 2: x86 CODE PATTERN ANALYSIS (first 64KB of each S* section)")
    print("=" * 80)
    print()

    for name, info in SECTIONS.items():
        va = info["va"]
        vsize = info["vsize"]
        raw_size = info.get("raw_size", vsize)
        file_offset = va_to_file_offset(va)

        if file_offset + raw_size > exe_size:
            raw_size = min(raw_size, exe_size - file_offset)

        analysis_size = min(65536, raw_size)
        section_data = exe_data[file_offset:file_offset + analysis_size]

        print(f"--- {name} (first {analysis_size} bytes) ---")
        patterns = count_x86_patterns(section_data)
        for pattern, count in sorted(patterns.items(), key=lambda x: -x[1]):
            if count > 0:
                print(f"  {pattern}: {count}")

        total_code_indicators = (
            patterns["push_ebp_mov_esp (55 8B EC)"] +
            patterns["ret (C3)"] +
            patterns["xor_eax_eax (33 C0)"] +
            patterns["sub_esp (83 EC)"]
        )
        total_padding = patterns["int3_padding (CC)"] + patterns["nop (90)"]

        if total_code_indicators > 100:
            print(f"  VERDICT: CONTAINS EXECUTABLE CODE (strong indicators: {total_code_indicators})")
        elif total_code_indicators > 20:
            print(f"  VERDICT: POSSIBLY CONTAINS CODE (moderate indicators: {total_code_indicators})")
        else:
            print(f"  VERDICT: LIKELY NOT STANDARD CODE (weak indicators: {total_code_indicators})")

        if total_padding > 500:
            print(f"  NOTE: Heavy CC/NOP padding ({total_padding}) — typical of compiled code alignment")
        print()

    print()
    print("=" * 80)
    print("SECTION 3: SECUROM STRING SEARCH")
    print("=" * 80)
    print()

    for name, info in SECTIONS.items():
        va = info["va"]
        vsize = info["vsize"]
        raw_size = info.get("raw_size", vsize)
        file_offset = va_to_file_offset(va)

        if file_offset + raw_size > exe_size:
            raw_size = min(raw_size, exe_size - file_offset)

        section_data = exe_data[file_offset:file_offset + raw_size]
        results = search_for_securom_strings(section_data, file_offset)

        if results:
            print(f"--- {name} ({len(results)} matches) ---")
            for offset, desc in results[:100]:
                print(f"  0x{offset:08X}: {desc}")
            if len(results) > 100:
                print(f"  ... and {len(results) - 100} more matches")
            print()

    print()
    print("=" * 80)
    print("SECTION 4: AES KEY MATERIAL SEARCH")
    print("=" * 80)
    print()

    for name, info in SECTIONS.items():
        va = info["va"]
        vsize = info["vsize"]
        raw_size = info.get("raw_size", vsize)
        file_offset = va_to_file_offset(va)

        if file_offset + raw_size > exe_size:
            raw_size = min(raw_size, exe_size - file_offset)

        section_data = exe_data[file_offset:file_offset + raw_size]
        findings = analyze_aes_patterns(section_data, file_offset)

        if findings:
            print(f"--- {name} ---")
            for f in findings:
                print(f)
            print()

    print()
    print("=" * 80)
    print("SECTION 5: .text SECTION COMPARISON (for reference)")
    print("=" * 80)
    print()

    text_offset = 0x00001000
    text_size = 0x00704000
    text_data = exe_data[text_offset:text_offset + min(65536, text_size)]
    text_entropy = shannon_entropy(text_data[:4096])
    text_patterns = count_x86_patterns(text_data)

    print(f"  .text section entropy (first 4KB): {text_entropy:.4f}")
    print(f"  .text x86 patterns (first 64KB):")
    for pattern, count in sorted(text_patterns.items(), key=lambda x: -x[1]):
        if count > 0:
            print(f"    {pattern}: {count}")
    print()

    print()
    print("=" * 80)
    print("SECTION 6: CROSS-REFERENCES FROM .text INTO S* SECTIONS")
    print("=" * 80)
    print()

    text_full = exe_data[text_offset:text_offset + text_size]

    stext_va_start = SECTIONS["Stext"]["va"]
    stext_va_end = stext_va_start + SECTIONS["Stext"]["vsize"]

    call_into_stext = 0
    jmp_into_stext = 0
    found_xrefs = []

    for i in range(len(text_full) - 4):
        if text_full[i] == 0xE8 or text_full[i] == 0xE9:
            rel32 = struct.unpack_from("<i", text_full, i + 1)[0]
            target_va = IMAGE_BASE + text_offset + i + 5 + rel32
            if stext_va_start <= target_va < stext_va_end:
                src_va = IMAGE_BASE + text_offset + i
                if text_full[i] == 0xE8:
                    call_into_stext += 1
                    if len(found_xrefs) < 50:
                        found_xrefs.append(f"  CALL from 0x{src_va:08X} -> 0x{target_va:08X}")
                else:
                    jmp_into_stext += 1
                    if len(found_xrefs) < 50:
                        found_xrefs.append(f"  JMP  from 0x{src_va:08X} -> 0x{target_va:08X}")

    print(f"  Total CALL instructions from .text into Stext: {call_into_stext}")
    print(f"  Total JMP instructions from .text into Stext: {jmp_into_stext}")
    print(f"  First {min(50, len(found_xrefs))} cross-references:")
    for xref in found_xrefs[:50]:
        print(xref)
    print()

    print()
    print("=" * 80)
    print("SECTION 7: SECUROM EVENT NAME PATTERN (v7_XXXX)")
    print("=" * 80)
    print()

    v7_pattern = b"v7_"
    idx = 0
    v7_matches = []
    while True:
        idx = exe_data.find(v7_pattern, idx)
        if idx == -1:
            break
        context = exe_data[idx:idx+64]
        ascii_str = "".join(chr(b) if 32 <= b < 127 else "." for b in context)
        v7_matches.append((idx, ascii_str))
        idx += 1

    print(f"  Found {len(v7_matches)} 'v7_' pattern matches:")
    for offset, context in v7_matches:
        print(f"  0x{offset:08X}: {context}")
    print()

    print()
    print("=" * 80)
    print("SECTION 8: ENTROPY MAP OF Stext (64KB chunks)")
    print("=" * 80)
    print()

    stext_offset = va_to_file_offset(SECTIONS["Stext"]["va"])
    stext_size = SECTIONS["Stext"]["vsize"]
    stext_data = exe_data[stext_offset:stext_offset + stext_size]

    chunk_size = 65536
    print(f"  Stext total size: {stext_size} bytes ({stext_size/1024/1024:.2f} MB)")
    print(f"  Entropy map (each row = {chunk_size} bytes = 64KB):")
    print(f"  {'Offset':<12} {'VA':<12} {'Entropy':<10} {'Assessment'}")
    print(f"  {'-'*12} {'-'*12} {'-'*10} {'-'*30}")

    for i in range(0, stext_size, chunk_size):
        chunk = stext_data[i:i+chunk_size]
        ent = shannon_entropy(chunk)
        va_addr = SECTIONS["Stext"]["va"] + i
        file_off = stext_offset + i

        if ent > 7.5:
            assessment = "ENCRYPTED/COMPRESSED"
        elif ent > 6.5:
            assessment = "compiled code"
        elif ent > 5.0:
            assessment = "mixed code/data"
        elif ent > 3.0:
            assessment = "data/strings"
        else:
            assessment = "padding/zeroes"

        print(f"  0x{file_off:08X}  0x{va_addr:08X}  {ent:.4f}    {assessment}")

    print()
    print("=" * 80)
    print("SECTION 9: FUNCTION PROLOGUES IN Stext")
    print("=" * 80)
    print()

    prologue_count = 0
    prologue_locs = []
    for i in range(len(stext_data) - 3):
        if stext_data[i] == 0x55 and stext_data[i+1] == 0x8B and stext_data[i+2] == 0xEC:
            prologue_count += 1
            if prologue_count <= 30:
                va_addr = SECTIONS["Stext"]["va"] + i
                next_bytes = stext_data[i:i+16]
                hex_str = " ".join(f"{b:02X}" for b in next_bytes)
                prologue_locs.append(f"  VA 0x{va_addr:08X}: {hex_str}")

    print(f"  Total function prologues (55 8B EC) in Stext: {prologue_count}")
    print(f"  First 30:")
    for loc in prologue_locs:
        print(loc)
    print()

    print()
    print("=" * 80)
    print("SECTION 10: STRINGS IN Stext (first 256KB)")
    print("=" * 80)
    print()

    stext_strings = find_strings(stext_data[:262144], min_length=8)
    print(f"  Found {len(stext_strings)} strings (len >= 8) in first 256KB of Stext:")
    for off, s in stext_strings[:200]:
        va_addr = SECTIONS["Stext"]["va"] + off
        print(f"  0x{va_addr:08X}: {s}")
    if len(stext_strings) > 200:
        print(f"  ... and {len(stext_strings) - 200} more")
    print()

    print()
    print("=" * 80)
    print("SECTION 11: SECUROM SECTION STRUCTURE ANALYSIS")
    print("=" * 80)
    print()

    securom_offset = va_to_file_offset(SECTIONS[".securom"]["va"])
    securom_size = SECTIONS[".securom"]["vsize"]
    securom_data = exe_data[securom_offset:securom_offset + securom_size]

    print(f"  .securom section size: {securom_size} bytes ({securom_size/1024/1024:.2f} MB)")
    print(f"  First 1024 bytes:")
    print(hex_dump(securom_data[:1024], securom_offset))
    print()

    print(f"  Strings in .securom (first 1MB, len >= 8):")
    securom_strings = find_strings(securom_data[:1048576], min_length=8)
    for off, s in securom_strings[:300]:
        va_addr = SECTIONS[".securom"]["va"] + off
        print(f"  0x{va_addr:08X}: {s}")
    if len(securom_strings) > 300:
        print(f"  ... and {len(securom_strings) - 300} more")
    print()

    aes_findings = analyze_aes_patterns(securom_data, securom_offset)
    if aes_findings:
        print(f"  AES patterns in .securom:")
        for f in aes_findings:
            print(f)
    print()

    print()
    print("=" * 80)
    print("SECTION 12: ASSESSMENT SUMMARY")
    print("=" * 80)
    print()

    stext_entropy = shannon_entropy(stext_data[:4096])
    stext_prologues = prologue_count

    print(f"  Stext entropy (first 4KB): {stext_entropy:.4f}")
    print(f"  Stext function prologues: {stext_prologues}")
    print()

    if stext_entropy < 7.0 and stext_prologues > 100:
        print("  CONCLUSION: Stext section IS DECRYPTED.")
        print("  The crack fully decrypted the SecuROM-protected code section.")
        print(f"  This section contains ~{stext_prologues} functions of game code that was")
        print("  originally encrypted by SecuROM and decrypted at runtime.")
        print("  The cracker captured the decrypted state (likely memory dump).")
    elif stext_entropy > 7.5 and stext_prologues < 10:
        print("  CONCLUSION: Stext section is STILL ENCRYPTED.")
        print("  The crack only bypassed entry-point checks without decrypting the code.")
        print("  This means ~6.2MB of game code is inaccessible without the AES key.")
    else:
        print(f"  CONCLUSION: MIXED STATE — partially decrypted or obfuscated code.")
        print(f"  Entropy suggests some code is present but may be VM-protected or")
        print(f"  partially encrypted.")
    print()


if __name__ == "__main__":
    main()
