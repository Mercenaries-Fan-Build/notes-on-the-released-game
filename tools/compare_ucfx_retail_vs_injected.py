#!/usr/bin/env python3
"""Compare UCFX internal structure: one retail entry vs one injected entry."""
from __future__ import annotations

import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from sges_decompress import decompress_sges_block


def dump_entry(label: str, chunk_data: bytes, n_desc: int, data_base: int) -> None:
    print(f"\n{'='*60}")
    print(f"  {label}")
    print(f"{'='*60}")

    u0 = struct.unpack_from("<I", chunk_data, 4)[0]
    u1 = struct.unpack_from("<I", chunk_data, 8)[0]
    u2 = struct.unpack_from("<I", chunk_data, 12)[0]
    u3 = struct.unpack_from("<I", chunk_data, 16)[0]
    print(f"  UCFX header: u0={u0} u1={u1} u2={u2} u3={u3}")
    print(f"  Parsed n_desc={n_desc}, data_base={data_base}")

    print(f"\n  Descriptors:")
    for d in range(n_desc):
        doff = 20 + d * 20
        dtag = chunk_data[doff:doff + 4].decode("ascii", errors="?")
        d0, d1, d2, d3 = struct.unpack_from("<IIII", chunk_data, doff + 4)
        print(f"    [{d}] {dtag}: offset={d0} size={d1} u2={d2} u3={d3}")

        body_start = data_base + d0
        body_end = body_start + d1
        body = chunk_data[body_start:body_end]
        print(f"        body ({len(body)} bytes): {body[:64].hex()}")
        if dtag == "DEPS":
            if len(body) >= 4:
                count = struct.unpack_from("<I", body, 0)[0]
                print(f"        DEPS count = {count}")
                if count > 0 and len(body) >= 4 + count * 4:
                    for di in range(count):
                        dep_hash = struct.unpack_from("<I", body, 4 + di * 4)[0]
                        print(f"          dep[{di}] = 0x{dep_hash:08X}")
            if len(body) < 4:
                print(f"        DEPS body too small! ({len(body)} bytes)")
        if dtag == "BINN":
            if len(body) >= 16:
                bc_size = struct.unpack_from("<I", body, 0)[0]
                type_code = body[12]
                name_len = struct.unpack_from("<H", body, 13)[0]
                name = body[15:15 + name_len].decode("ascii", errors="?")
                print(f"        BINN: bc_size={bc_size}, type=0x{type_code:02X}, "
                      f"name_len={name_len}, name={name!r}")
                luaq_off = body.find(b"LuaQ")
                if luaq_off >= 0:
                    print(f"        LuaQ at body offset {luaq_off}")


def main(wad_path: Path) -> int:
    raw = wad_path.read_bytes()
    chunks: dict[str, tuple[int, int]] = {}
    for i in range(5):
        off = 0x0C + i * 12
        tag = raw[off:off + 4].decode("ascii", errors="replace")
        val, meta = struct.unpack_from("<II", raw, off + 4)
        chunks[tag] = (val, meta)

    data_off = chunks["DATA"][0]
    decompressed = decompress_sges_block(raw[data_off:], 0, len(raw) - data_off)
    entry_count = struct.unpack_from("<I", decompressed, 0)[0]
    header_end = 4 + entry_count * 16

    # Pick one retail entry (entry 0) and one injected (entry 114)
    pos = header_end
    entries_data = []
    for i in range(entry_count):
        eoff = 4 + i * 16
        _, _, _, chunk_size = struct.unpack_from("<IIII", decompressed, eoff)
        entries_data.append(decompressed[pos:pos + chunk_size])
        pos += chunk_size

    # Retail entry 0
    chunk0 = entries_data[0]
    u3_0 = struct.unpack_from("<I", chunk0, 16)[0]
    u0_0 = struct.unpack_from("<I", chunk0, 4)[0]
    dump_entry("RETAIL Entry [0]", chunk0, n_desc=u3_0, data_base=u0_0)

    # Injected entry 114
    chunk114 = entries_data[114]
    u2_114 = struct.unpack_from("<I", chunk114, 12)[0]
    dump_entry(
        "INJECTED Entry [114] (modloader) - parsed with INJECTED format",
        chunk114,
        n_desc=u2_114,
        data_base=20 + u2_114 * 20,
    )

    u3_114 = struct.unpack_from("<I", chunk114, 16)[0]
    u0_114 = struct.unpack_from("<I", chunk114, 4)[0]
    dump_entry(
        "INJECTED Entry [114] - parsed with ENGINE (retail) format",
        chunk114,
        n_desc=u3_114,
        data_base=u0_114,
    )

    return 0


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <vz-patch.wad>")
        sys.exit(1)
    sys.exit(main(Path(sys.argv[1])))
