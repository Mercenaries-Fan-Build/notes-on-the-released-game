#!/usr/bin/env python3
"""Investigate sound device object corruption via x32dbg MCP."""
import requests
import sys

URL = "http://127.0.0.1:8888/"


def get(endpoint, params=None):
    r = requests.get(URL + endpoint, params=params or {}, timeout=10)
    try:
        return r.json()
    except Exception:
        return r.text


def mem_read(addr, size):
    """Read memory, return hex string."""
    result = get("Memory/Read", {"addr": addr, "size": str(size)})
    return result


def main():
    # ECX holds the pointer that was used: 0x2006FBA8
    # The instruction at 0x83664c is: mov eax, dword ptr ds:[ecx]
    # This reads the vtable pointer from the sound device object.
    # ECX = 0x2006FBA8 is the object address.
    # The vtable ptr at [0x2006FBA8] = 0 (zeroed)

    sound_obj_addr = "0x2006FBA8"

    # Check if 0x2006FBA8 is a static global or a pointer to heap
    # Read surrounding memory for context
    print("=== Memory around sound device pointer ===")
    # Read 128 bytes starting at the object
    data = mem_read(sound_obj_addr, 128)
    print(f"  [{sound_obj_addr}]: {data}")

    # Check what's at 0x19C6690 (the global that holds the sound device ptr)
    # From the disasm: mov edx, dword ptr ds:[0x019C6690]
    print("\n=== Global at 0x019C6690 ===")
    data2 = mem_read("0x019C6690", 4)
    print(f"  [0x019C6690]: {data2}")

    # And 0x19C615C (the flag byte)
    print("\n=== Flag at 0x019C615C ===")
    data3 = mem_read("0x019C615C", 4)
    print(f"  [0x019C615C]: {data3}")

    # Check memory protection of the sound device region
    print("\n=== Memory info for sound device region ===")
    info = get("Memory/GetProtect", {"addr": sound_obj_addr})
    print(f"  Protection: {info}")

    base = get("Memory/Base", {"addr": sound_obj_addr})
    print(f"  Region base: {base}")

    mem_size = get("Memory/Size", {"addr": sound_obj_addr})
    print(f"  Region size: {mem_size}")

    # Look at what's before the sound device - is this a heap block header?
    print("\n=== Memory BEFORE sound device (possible heap header) ===")
    before = mem_read("0x2006FB88", 48)
    print(f"  [0x2006FB88]: {before}")

    # Check broader context - is there a pattern of zeroed memory?
    print("\n=== Scanning for zero extent around 0x2006FBA8 ===")
    # Read 1KB before and check
    scan_start = 0x2006F000
    chunk = mem_read(hex(scan_start), 4096)
    if isinstance(chunk, str) and len(chunk) > 10:
        # Find first and last non-zero positions
        bytes_hex = chunk.replace(" ", "")
        zero_runs = []
        in_zero = False
        start = 0
        for i in range(0, len(bytes_hex), 2):
            byte_val = bytes_hex[i:i+2]
            if byte_val == "00":
                if not in_zero:
                    start = i // 2
                    in_zero = True
            else:
                if in_zero:
                    length = (i // 2) - start
                    if length >= 16:
                        zero_runs.append((scan_start + start, length))
                    in_zero = False
        if in_zero:
            length = (len(bytes_hex) // 2) - start
            if length >= 16:
                zero_runs.append((scan_start + start, length))

        obj_offset = 0x2006FBA8 - scan_start
        print(f"  Zero runs >= 16 bytes near sound device:")
        for addr, length in zero_runs:
            contains_obj = addr <= 0x2006FBA8 < addr + length
            marker = " <-- CONTAINS SOUND DEVICE" if contains_obj else ""
            print(f"    0x{addr:08X} - 0x{addr+length:08X} ({length} bytes){marker}")
    else:
        print(f"  Could not scan: {str(chunk)[:200]}")


if __name__ == "__main__":
    main()
