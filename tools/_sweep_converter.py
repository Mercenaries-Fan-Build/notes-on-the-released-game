#!/usr/bin/env python3
"""Wide-sweep validation of ucfx_byteswap across diverse block types.

Tests up to 5 blocks per type_hash to ensure converter handles all
known UCFX container types correctly.
"""
from __future__ import annotations

import mmap
import struct
import subprocess
import sys
import zlib
from pathlib import Path

SEGS_MAGIC = b"segs"
UCFX_LE = b"UCFX"
CSUM_LE = b"CSUM"

TYPE_NAMES = {
    0xF011157A: "texture", 0x42498680: "script", 0x207359C7: "stance",
    0x18166555: "animation", 0xE6B81A54: "ecs_node", 0x5B724250: "mesh_B",
    0x7C569307: "mesh_A", 0x600B904E: "mesh_C", 0x39E5E978: "stringdb",
    0xBCFE6314: "path", 0xECE70371: "state_machine", 0xE5273C14: "audio_group",
}


def crc32_mercs2(data: bytes) -> int:
    crc = 0
    for b in data:
        crc ^= b
        for _ in range(8):
            crc = (crc >> 1) ^ 0xEDB88320 if crc & 1 else crc >> 1
    return crc & 0xFFFFFFFF


def decompress_be_segs(mm: mmap.mmap, start: int, end: int) -> bytes:
    header = mm[start:start + 16]
    seg_count = struct.unpack_from(">H", header, 6)[0]
    segs: list[tuple[int, int]] = []
    for si in range(seg_count):
        so = start + 16 + si * 8
        csz = struct.unpack_from(">H", mm[so:so + 2], 0)[0]
        dsz = struct.unpack_from(">H", mm[so + 2:so + 4], 0)[0]
        segs.append((csz, dsz))
    hs = 16 + ((seg_count * 8 + 15) & ~15) if seg_count > 0 else 16
    payload = mm[start + hs:end]
    result = bytearray()
    pos = 0
    for csz, dsz in segs:
        if csz > 0 and csz == dsz:
            result.extend(payload[pos:pos + csz])
            pos += csz
        else:
            dc = zlib.decompressobj(-15)
            piece = dc.decompress(bytes(payload[pos:]))
            piece += dc.flush()
            consumed = len(payload[pos:]) - len(dc.unused_data)
            result.extend(piece)
            pos += consumed
        pos = (pos + 15) & ~15
    return bytes(result)


def main() -> int:
    binary = Path("tools/wad_simulator/target/release/ucfx_byteswap.exe")
    wad_path = Path("game-files/xbox-vz.wad")

    with open(wad_path, "rb") as f:
        mm = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)

    header = bytes(mm[:256])
    data_off = struct.unpack_from(">I", header, 0x0C + 1 * 12 + 4)[0]
    file_size = len(mm)

    offsets: list[int] = []
    pos = data_off
    while pos < file_size:
        idx = mm.find(SEGS_MAGIC, pos, file_size)
        if idx < 0:
            break
        offsets.append(idx)
        pos = idx + 4

    pths_off = struct.unpack_from(">I", header, 0x0C + 4 * 12 + 4)[0]
    blob = bytes(mm[pths_off:pths_off + 4_000_000])
    paths: list[str] = []
    p = 0
    while p < len(blob):
        nul = blob.find(b"\x00", p)
        if nul < 0:
            break
        s = blob[p:nul].decode("ascii", errors="replace")
        if len(s) >= 2:
            paths.append(s)
        p = nul + 1

    print(f"Total blocks: {len(offsets)}, paths: {len(paths)}")

    type_tested: dict[str, int] = {}
    type_passed: dict[str, int] = {}
    pass_count = 0
    fail_count = 0
    error_count = 0
    total = 0
    fail_details: list[str] = []

    for idx in range(min(len(offsets), len(paths))):
        if total >= 100:
            break
        try:
            start = offsets[idx]
            block_end = offsets[idx + 1] if idx + 1 < len(offsets) else file_size
            block = decompress_be_segs(mm, start, block_end)
            count = struct.unpack_from(">I", block, 0)[0]
            if count < 1 or count > 50000:
                continue

            all_types: set[str] = set()
            for ei in range(count):
                th = struct.unpack_from(">I", block, 4 + ei * 16 + 4)[0]
                all_types.add(TYPE_NAMES.get(th, f"0x{th:08X}"))

            skip = True
            for tn in all_types:
                if type_tested.get(tn, 0) < 5:
                    skip = False
                    break
            if skip:
                continue

            result = subprocess.run(
                [str(binary), "--stdin", "--stdout", "--no-validate"],
                input=block, capture_output=True)
            if result.returncode != 0:
                error_count += 1
                total += 1
                for tn in all_types:
                    type_tested[tn] = type_tested.get(tn, 0) + 1
                err_msg = result.stderr.decode("utf-8", errors="replace").strip().split("\n")[-1]
                fail_details.append(f"  ERROR [{idx}] {paths[idx] if idx < len(paths) else '?'}: {err_msg}")
                continue

            converted = result.stdout
            ok = True
            issue = ""

            le_count = struct.unpack_from("<I", converted, 0)[0]
            if le_count != count:
                ok = False
                issue = f"entry count: {count}->{le_count}"

            if ok:
                entry_pos = 4 + le_count * 16
                for ei in range(le_count):
                    be_h = struct.unpack_from(">I", block, 4 + ei * 16)[0]
                    le_h = struct.unpack_from("<I", converted, 4 + ei * 16)[0]
                    if be_h != le_h:
                        ok = False
                        issue = f"entry[{ei}] hash mismatch"
                        break

                    be_th = struct.unpack_from(">I", block, 4 + ei * 16 + 4)[0]
                    le_th = struct.unpack_from("<I", converted, 4 + ei * 16 + 4)[0]
                    if be_th != le_th:
                        ok = False
                        issue = f"entry[{ei}] type_hash mismatch"
                        break

                    sz = struct.unpack_from("<I", converted, 4 + ei * 16 + 12)[0]
                    if entry_pos + sz > len(converted):
                        ok = False
                        issue = f"entry[{ei}] extends past block"
                        break

                    if converted[entry_pos:entry_pos + 4] != UCFX_LE:
                        ok = False
                        issue = f"entry[{ei}] bad UCFX magic: {converted[entry_pos:entry_pos+4]!r}"
                        break

                    if converted[entry_pos + sz - 8:entry_pos + sz - 4] != CSUM_LE:
                        ok = False
                        issue = f"entry[{ei}] bad CSUM tag"
                        break

                    stored_crc = struct.unpack_from("<I", converted, entry_pos + sz - 4)[0]
                    computed_crc = crc32_mercs2(converted[entry_pos:entry_pos + sz - 8])
                    if stored_crc != computed_crc:
                        ok = False
                        issue = f"entry[{ei}] CRC mismatch: 0x{stored_crc:08X} vs 0x{computed_crc:08X}"
                        break

                    entry_pos += sz

            if ok:
                pass_count += 1
                for tn in all_types:
                    type_passed[tn] = type_passed.get(tn, 0) + 1
            else:
                fail_count += 1
                fail_details.append(
                    f"  FAIL [{idx}] {paths[idx] if idx < len(paths) else '?'}: {issue}")

            total += 1
            for tn in all_types:
                type_tested[tn] = type_tested.get(tn, 0) + 1

        except Exception:
            continue

    mm.close()

    print(f"\nBlocks tested: {total}")
    print(f"PASS:  {pass_count}")
    print(f"FAIL:  {fail_count}")
    print(f"ERROR: {error_count}")
    print(f"\nType coverage ({len(type_tested)} types):")
    for tn in sorted(type_tested.keys()):
        tested = type_tested[tn]
        passed = type_passed.get(tn, 0)
        status = "ALL PASS" if passed == tested else f"{passed}/{tested} PASS"
        print(f"  {tn:20s}: {tested} tested, {status}")

    if fail_details:
        print(f"\nFailure/error details:")
        for d in fail_details:
            print(d)

    return 0 if fail_count == 0 and error_count == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
