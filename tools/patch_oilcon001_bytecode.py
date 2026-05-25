#!/usr/bin/env python3
"""Patch oilcon001.luac bytecode to replace Obj_GotoRefinery with Complete.

Option B: Replace the string content of constant #24 in the Activated function's
constant pool. This shrinks the file by 8 bytes (17 - 9 = 8 bytes less for the
string payload). The Lua 5.1 bytecode format has no parent size fields that
reference sub-function sizes, so we only need to change:
  1. The string length field (u32): 17 -> 9
  2. The string content: "Obj_GotoRefinery\0" -> "Complete\0"

No offsets elsewhere need adjusting because Lua 5.1 bytecode uses counted arrays
(u32 count + elements) recursively — there are no absolute offsets stored in the
format. Each section is read sequentially.
"""
from __future__ import annotations

import struct
import sys
from pathlib import Path


def find_activated_constant_pool(data: bytes) -> int | None:
    """Find the byte offset of constant #24's length field in the Activated function.
    
    Strategy: Search for the unique byte sequence that represents the constant pool
    entry for "Obj_GotoRefinery" preceded by "refinery_office03". We look for the
    string length (17 as u32 LE) followed by the exact bytes.
    """
    target = b"Obj_GotoRefinery\x00"
    target_with_len = struct.pack("<I", 17) + target
    
    # The constant type byte (0x04 for string) precedes the length
    full_pattern = b"\x04" + target_with_len
    
    offset = data.find(full_pattern)
    if offset == -1:
        return None
    return offset


def patch_bytecode(input_path: Path, output_path: Path) -> None:
    data = bytearray(input_path.read_bytes())
    original_size = len(data)
    print(f"Original size: {original_size} bytes")
    
    # Find ALL occurrences of "\x04" + u32(17) + "Obj_GotoRefinery\0"
    target = b"\x04" + struct.pack("<I", 17) + b"Obj_GotoRefinery\x00"
    
    occurrences = []
    pos = 0
    while True:
        idx = data.find(target, pos)
        if idx == -1:
            break
        occurrences.append(idx)
        pos = idx + 1
    
    print(f"Found {len(occurrences)} occurrence(s) of 'Obj_GotoRefinery' constant")
    for i, occ in enumerate(occurrences):
        print(f"  Occurrence {i}: offset 0x{occ:06X} ({occ})")
    
    if not occurrences:
        print("ERROR: Could not find 'Obj_GotoRefinery' constant in bytecode!")
        sys.exit(1)
    
    # We expect exactly one occurrence in the Activated function.
    # The Activated function is sub-function #1 of the main chunk.
    # Let's verify context: the preceding constant should be "refinery_office03"
    target_offset = None
    for occ in occurrences:
        # Check what's before this constant - should be "refinery_office03\0"
        # preceded by its type byte (0x04) and length (18 = 17+1 null)
        prev_str = b"refinery_office03\x00"
        prev_len = len(prev_str)  # 18
        prev_pattern = b"\x04" + struct.pack("<I", prev_len) + prev_str
        expected_prev_end = occ
        expected_prev_start = occ - len(prev_pattern)
        if expected_prev_start >= 0 and data[expected_prev_start:expected_prev_end] == prev_pattern:
            print(f"  -> Confirmed: offset 0x{occ:06X} is preceded by 'refinery_office03' (Activated fn)")
            target_offset = occ
            break
    
    if target_offset is None:
        # Fallback: use the first occurrence
        print("  WARNING: Could not confirm context, using first occurrence")
        target_offset = occurrences[0]
    
    # Now patch:
    # Original: 0x04 | u32(17) | "Obj_GotoRefinery\0" (1 + 4 + 17 = 22 bytes)
    # New:      0x04 | u32(9)  | "Complete\0"         (1 + 4 + 9  = 14 bytes)
    # Difference: 22 - 14 = 8 bytes shorter
    
    old_entry = b"\x04" + struct.pack("<I", 17) + b"Obj_GotoRefinery\x00"
    new_entry = b"\x04" + struct.pack("<I", 9) + b"Complete\x00"
    
    assert data[target_offset:target_offset + len(old_entry)] == old_entry
    
    # Replace in-place (shrinking)
    data[target_offset:target_offset + len(old_entry)] = new_entry
    
    new_size = len(data)
    print(f"Patched size: {new_size} bytes (delta: {new_size - original_size})")
    assert new_size == original_size - 8, f"Expected {original_size - 8}, got {new_size}"
    
    output_path.write_bytes(bytes(data))
    print(f"Written to: {output_path}")


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Patch oilcon001.luac: Obj_GotoRefinery -> Complete")
    parser.add_argument("--input", default="output_demo/oilcon001.luac",
                        help="Input .luac file")
    parser.add_argument("--output", default="output_demo/oilcon001_patched.luac",
                        help="Output patched .luac file")
    args = parser.parse_args()
    
    input_path = Path(args.input)
    output_path = Path(args.output)
    
    if not input_path.exists():
        print(f"ERROR: Input file not found: {input_path}")
        sys.exit(1)
    
    patch_bytecode(input_path, output_path)


if __name__ == "__main__":
    main()
