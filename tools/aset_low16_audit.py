"""Audit packed_block_ref low-16 bits in a WAD's ASET chunk."""
from __future__ import annotations

import struct
import sys
from collections import Counter
from pathlib import Path


def find_chunks(data: bytes) -> dict[bytes, tuple[int, int]]:
    """Return {tag: (body_offset, body_size)} for each FFCS chunk."""
    magic = data[:4]
    if magic != b"FFCS":
        raise ValueError(f"Not an FFCS file (magic={magic!r})")

    header_size = struct.unpack_from("<I", data, 4)[0]
    pos = header_size
    chunks: dict[bytes, tuple[int, int]] = {}
    while pos + 8 <= len(data):
        tag = data[pos : pos + 4]
        size = struct.unpack_from("<I", data, pos + 4)[0]
        body_off = pos + 8
        if body_off + size > len(data):
            break
        chunks[tag] = (body_off, size)
        pos = body_off + size
    return chunks


def main() -> None:
    wad_path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(
        r"c:\Users\Shadow\Desktop\notes-on-the-released-game\output\data\vz-patch.wad"
    )
    if not wad_path.exists():
        print(f"WAD not found: {wad_path}")
        sys.exit(1)

    data = wad_path.read_bytes()
    print(f"WAD size: {len(data):,} bytes")

    chunks = find_chunks(data)
    print(f"Chunks found: {[t.decode('ascii','replace') for t in chunks]}")

    if b"ASET" not in chunks:
        print("No ASET chunk found!")
        sys.exit(1)

    body_off, body_size = chunks[b"ASET"]
    row_count = body_size // 16
    remainder = body_size % 16
    print(f"ASET body: offset=0x{body_off:X}, size={body_size}, rows={row_count}, remainder={remainder}")

    low16_counter: Counter[int] = Counter()
    non_ffff: list[tuple[int, int, int, int, int]] = []

    for i in range(row_count):
        off = body_off + i * 16
        asset_hash, type_hash, packed_ref, unk = struct.unpack_from("<4I", data, off)
        low16 = packed_ref & 0xFFFF
        low16_counter[low16] += 1
        if low16 != 0xFFFF:
            non_ffff.append((i, asset_hash, type_hash, packed_ref, low16))

    print(f"\n=== Low-16 histogram ({len(low16_counter)} distinct values) ===")
    for val, count in sorted(low16_counter.items()):
        print(f"  0x{val:04X}: {count:6d} entries")

    print(f"\n=== Entries with low16 != 0xFFFF: {len(non_ffff)} / {row_count} ===")
    if non_ffff:
        print(f"{'idx':>6}  {'asset_hash':>10}  {'type_hash':>10}  {'packed_ref':>10}  {'low16':>6}")
        for idx, ah, th, pr, l16 in non_ffff[:200]:
            print(f"{idx:6d}  0x{ah:08X}  0x{th:08X}  0x{pr:08X}  0x{l16:04X}")
        if len(non_ffff) > 200:
            print(f"  ... ({len(non_ffff) - 200} more)")
    else:
        print("All entries have low16 == 0xFFFF. No fix needed.")


if __name__ == "__main__":
    main()
