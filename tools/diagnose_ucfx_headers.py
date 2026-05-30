#!/usr/bin/env python3
"""Check every UCFX container header in the patch WAD for format consistency.

Retail scripts_vz entries use: u0=80 (data_base offset), u1=0, u2=0, u3=3 (n_desc)
Injected entries from _build_ucfx_script_chunk use: u0=60, u1=data_size, u2=3, u3=0

This script flags which format each entry uses and whether the engine would
parse it correctly (engine expects the retail format).
"""
from __future__ import annotations

import struct
import sys
import zlib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from sges_decompress import decompress_sges_block, parse_sges_header

PAGE_SIZE = 0x8000


def main(wad_path: Path) -> int:
    raw = wad_path.read_bytes()

    # Parse FFCS
    chunks: dict[str, tuple[int, int]] = {}
    for i in range(5):
        off = 0x0C + i * 12
        tag = raw[off:off + 4].decode("ascii", errors="replace")
        val, meta = struct.unpack_from("<II", raw, off + 4)
        chunks[tag] = (val, meta)

    # Decompress
    data_off = chunks["DATA"][0]
    sges_data = raw[data_off:]
    decompressed = decompress_sges_block(sges_data, 0, len(sges_data))

    entry_count = struct.unpack_from("<I", decompressed, 0)[0]
    header_end = 4 + entry_count * 16

    print(f"Block has {entry_count} entries")
    print(f"{'Idx':>4} {'NameHash':>10} {'u0':>6} {'u1':>8} {'u2':>4} {'u3':>4} {'Format':>10} "
          f"{'ChunkSz':>8} {'ScriptName'}")
    print("-" * 100)

    retail_count = 0
    injected_count = 0
    other_count = 0

    pos = header_end
    for i in range(entry_count):
        eoff = 4 + i * 16
        name_hash, type_hash, field_c, chunk_size = struct.unpack_from("<IIII", decompressed, eoff)

        chunk_data = decompressed[pos:pos + chunk_size]
        pos += chunk_size

        if len(chunk_data) < 20 or chunk_data[:4] != b"UCFX":
            print(f"  {i:4d}  NOT UCFX")
            other_count += 1
            continue

        u0 = struct.unpack_from("<I", chunk_data, 4)[0]
        u1 = struct.unpack_from("<I", chunk_data, 8)[0]
        u2 = struct.unpack_from("<I", chunk_data, 12)[0]
        u3 = struct.unpack_from("<I", chunk_data, 16)[0]

        # Determine format
        if u3 > 0 and u2 == 0:
            fmt = "RETAIL"
            n_desc = u3
            data_base = u0
            retail_count += 1
        elif u2 > 0 and u3 == 0:
            fmt = "INJECTED"
            n_desc = u2
            data_base = 20 + u0
            injected_count += 1
        else:
            fmt = "UNKNOWN"
            n_desc = max(u2, u3)
            data_base = u0
            other_count += 1

        # Try to extract script name
        script_name = ""
        if n_desc > 0:
            if fmt == "RETAIL":
                # descriptors start at offset 20, data starts at u0
                desc_tags = []
                for d in range(n_desc):
                    doff = 20 + d * 20
                    if doff + 20 <= len(chunk_data):
                        dtag = chunk_data[doff:doff + 4].decode("ascii", errors="?")
                        d_offset = struct.unpack_from("<I", chunk_data, doff + 4)[0]
                        d_size = struct.unpack_from("<I", chunk_data, doff + 8)[0]
                        desc_tags.append((dtag, d_offset, d_size))

                for dtag, d_off, d_sz in desc_tags:
                    if dtag == "BINN":
                        body_start = data_base + d_off
                        if body_start + 16 <= len(chunk_data):
                            body = chunk_data[body_start:]
                            if len(body) >= 16 and body[12] == 0x05:
                                nlen = struct.unpack_from("<H", body, 13)[0]
                                name_bytes = body[15:15 + nlen]
                                try:
                                    script_name = name_bytes.decode("ascii")
                                except Exception:
                                    pass

            elif fmt == "INJECTED":
                desc_tags = []
                for d in range(n_desc):
                    doff = 20 + d * 20
                    if doff + 20 <= len(chunk_data):
                        dtag = chunk_data[doff:doff + 4].decode("ascii", errors="?")
                        d_offset = struct.unpack_from("<I", chunk_data, doff + 4)[0]
                        d_size = struct.unpack_from("<I", chunk_data, doff + 8)[0]
                        desc_tags.append((dtag, d_offset, d_size))

                actual_data_base = 20 + n_desc * 20
                for dtag, d_off, d_sz in desc_tags:
                    if dtag == "BINN":
                        body_start = actual_data_base + d_off
                        if body_start + 16 <= len(chunk_data):
                            body = chunk_data[body_start:]
                            if len(body) >= 16 and body[12] == 0x05:
                                nlen = struct.unpack_from("<H", body, 13)[0]
                                name_bytes = body[15:15 + nlen]
                                try:
                                    script_name = name_bytes.decode("ascii")
                                except Exception:
                                    pass

        # For injected entries, show what the engine would see
        engine_warning = ""
        if fmt == "INJECTED":
            engine_n_desc = u3  # engine reads u3 as n_desc = 0
            engine_data_base = u0  # engine reads u0 as data_base = 60
            engine_warning = f" *** ENGINE SEES: n_desc={engine_n_desc}, data_base={engine_data_base}"

        print(f"  {i:4d} 0x{name_hash:08X} {u0:6d} {u1:8d} {u2:4d} {u3:4d} {fmt:>10} "
              f"{chunk_size:8,} {script_name}{engine_warning}")

    print(f"\nSummary: {retail_count} retail, {injected_count} injected, {other_count} other")

    if injected_count > 0:
        print(f"\n*** CRITICAL: {injected_count} entries have INJECTED format (wrong UCFX header)")
        print("    Engine expects: u0=header+desc_size, u1=0, u2=0, u3=n_desc")
        print("    Injected has:   u0=desc_size_only,   u1=data_sz, u2=n_desc, u3=0")
        print("    Effect: engine reads u3=0 -> no descriptors, u0=60 -> wrong data_base")
        print("    This will cause the engine to misparse these UCFX containers.")

    return 0


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <vz-patch.wad>")
        sys.exit(1)
    sys.exit(main(Path(sys.argv[1])))
