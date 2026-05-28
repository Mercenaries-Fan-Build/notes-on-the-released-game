#!/usr/bin/env python3
"""Validate DLC soundbank/wavebank entries in vz-patch.wad.

Checks:
- Soundbank sub_count (sounds per bank) — values >2 would have been
  corrupted by the old absolute-offset u8x4 field map
- Wavebank clip record integrity
- Section offset plausibility
"""
from __future__ import annotations

import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from ffcs_wad import parse_ffcs  # noqa: E402
from ffcs_patch_wad import PAGE_SIZE  # noqa: E402
from sges_decompress import decompress_sges_block  # noqa: E402

TYPE_SOUNDBANK = 0x9F8BCA10
TYPE_WAVEBANK = 0xF753F6D0
AUDIO_TYPES = {TYPE_SOUNDBANK, TYPE_WAVEBANK}


def main():
    wad_path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("output/data/vz-patch.wad")
    if not wad_path.exists():
        print(f"WAD not found: {wad_path}")
        return

    raw = wad_path.read_bytes()
    arch = parse_ffcs(wad_path)
    print(f"WAD: {wad_path} ({len(raw):,} bytes), {arch.chunk_count} chunks")

    indx_chunk = next((c for c in arch.chunks if c.tag == "INDX"), None)
    if not indx_chunk:
        print("No INDX chunk found")
        return

    indx_off = indx_chunk.offset
    n_blocks = indx_chunk.meta
    print(f"INDX: {n_blocks} blocks at offset 0x{indx_off:X}\n")

    sb_count = 0
    wb_count = 0
    max_sub_count = 0

    for blk_idx in range(n_blocks):
        entry_off = indx_off + blk_idx * 12
        page_idx, packed, flags_pages = struct.unpack_from("<III", raw, entry_off)
        comp_pages = flags_pages & 0xFFFF

        block_off = page_idx * PAGE_SIZE
        block_sz = comp_pages * PAGE_SIZE
        if block_off + block_sz > len(raw):
            continue

        try:
            decomp = decompress_sges_block(raw, block_off, block_off + block_sz)
        except Exception:
            continue

        if len(decomp) < 4:
            continue
        entry_count = struct.unpack_from("<I", decomp, 0)[0]
        if entry_count > 1000 or 4 + entry_count * 16 > len(decomp):
            continue

        has_audio = False
        for i in range(entry_count):
            eoff = 4 + i * 16
            _, th, _, _ = struct.unpack_from("<IIII", decomp, eoff)
            if th in AUDIO_TYPES:
                has_audio = True
                break

        if not has_audio:
            continue

        pos = 4 + entry_count * 16
        for i in range(entry_count):
            eoff = 4 + i * 16
            h, th, o, sz = struct.unpack_from("<IIII", decomp, eoff)

            container = decomp[pos:pos + sz]
            pos += sz

            if th not in AUDIO_TYPES:
                continue

            # Strip CSUM
            if len(container) >= 8 and container[-8:-4] == b"CSUM":
                container = container[:-8]
            if len(container) < 20 or container[:4] != b"UCFX":
                continue

            ucfx_data_off = struct.unpack_from("<I", container, 4)[0]
            n_desc = struct.unpack_from("<I", container, 16)[0]

            data_body = None
            for d in range(min(n_desc, 100)):
                doff = 20 + d * 20
                if doff + 20 > len(container):
                    break
                dtag = container[doff:doff + 4]
                du0 = struct.unpack_from("<I", container, doff + 4)[0]
                dsz = struct.unpack_from("<I", container, doff + 8)[0]
                if dtag == b"data" and du0 != 0xFFFFFFFF:
                    body_start = ucfx_data_off + du0
                    data_body = container[body_start:body_start + dsz]
                    break

            if data_body is None or len(data_body) < 24:
                print(f"  block[{blk_idx}] entry[{i}] {'soundbank' if th == TYPE_SOUNDBANK else 'wavebank'}"
                      f" hash=0x{h:08X} — NO DATA BODY")
                continue

            if th == TYPE_SOUNDBANK:
                sb_count += 1
                count_le = struct.unpack_from("<I", data_body, 0)[0]
                self_hash = struct.unpack_from("<I", data_body, 4)[0]
                sub_count = struct.unpack_from("<H", data_body, 8)[0]
                sub_count2 = struct.unpack_from("<H", data_body, 10)[0]
                data_start = struct.unpack_from("<I", data_body, 16)[0]
                section_off1 = struct.unpack_from("<I", data_body, 20)[0]
                section_off2 = struct.unpack_from("<I", data_body, 24)[0]
                section_off3 = struct.unpack_from("<I", data_body, 28)[0]

                # Compute actual record stride from section geometry
                sec_a = section_off1 - data_start
                if sub_count > 0 and sec_a > 0 and sec_a % sub_count == 0:
                    record_stride = sec_a // sub_count
                else:
                    record_stride = 0  # indeterminate

                max_sub_count = max(max_sub_count, sub_count)

                # Byte-level u8x4 sanity check: at rel offsets {12, 20, 44}
                # within each record, values should look like flag bytes
                # (endian-invariant), not reversed floats/u32s
                u8x4_suspect = 0
                u8x4_checked = 0
                if record_stride >= 48:
                    for r in range(sub_count):
                        rec_off = data_start + r * record_stride
                        for rel in (12, 20, 44):
                            pos = rec_off + rel
                            if pos + 4 > len(data_body):
                                break
                            val = data_body[pos:pos + 4]
                            u8x4_checked += 1
                            # Heuristic: f32 values (0x3E..0x42 range high byte)
                            # indicate a swapped u32, not a flag byte
                            if val[3] in range(0x3E, 0x43) and val[0] == 0:
                                u8x4_suspect += 1

                bug_flag = ""
                if u8x4_suspect > 0:
                    bug_flag = (
                        f" *** SUSPECT: {u8x4_suspect}/{u8x4_checked} u8x4 "
                        f"fields look like LE floats (converter may not have "
                        f"protected them) ***"
                    )

                print(
                    f"  block[{blk_idx}] entry[{i}] soundbank "
                    f"hash=0x{h:08X} self=0x{self_hash:08X}\n"
                    f"    count_le={count_le} sub_count={sub_count} sub_count2={sub_count2}\n"
                    f"    data_start={data_start} s1=0x{section_off1:X} "
                    f"s2=0x{section_off2:X} s3=0x{section_off3:X}\n"
                    f"    record_stride={record_stride} "
                    f"section_a_records={sub_count} body_size={len(data_body)}"
                    f"{bug_flag}"
                )
                print()

            elif th == TYPE_WAVEBANK:
                wb_count += 1
                count_le = struct.unpack_from("<I", data_body, 0)[0]
                self_hash = struct.unpack_from("<I", data_body, 4)[0]
                pop_count = struct.unpack_from("<H", data_body, 8)[0]
                roff = struct.unpack_from("<I", data_body, 16)[0]

                embedded = 0
                streaming = 0
                bad_offsets = 0
                for r in range(min(count_le, 500)):
                    rec_off = roff + r * 36
                    if rec_off + 36 > len(data_body):
                        break
                    clip_hash = struct.unpack_from("<I", data_body, rec_off)[0]
                    codec = data_body[rec_off + 6]
                    d_off = struct.unpack_from("<I", data_body, rec_off + 12)[0]
                    d_sz = struct.unpack_from("<I", data_body, rec_off + 16)[0]
                    if d_sz == 0:
                        continue
                    if d_off + d_sz <= len(data_body):
                        embedded += 1
                    elif d_off > 0:
                        streaming += 1
                    else:
                        bad_offsets += 1

                print(
                    f"  block[{blk_idx}] entry[{i}] wavebank "
                    f"hash=0x{h:08X} self=0x{self_hash:08X}\n"
                    f"    count={count_le} populated={pop_count} records_offset={roff}\n"
                    f"    embedded={embedded} streaming={streaming} "
                    f"bad_offsets={bad_offsets} body_size={len(data_body)}"
                )
                print()

    print(f"\nSummary: {sb_count} soundbanks, {wb_count} wavebanks")
    if max_sub_count > 2:
        print(f"Max sub_count across soundbanks: {max_sub_count}")
        print("==> Old code would have corrupted u8x4 fields in records 2+")
    else:
        print(f"Max sub_count across soundbanks: {max_sub_count}")


if __name__ == "__main__":
    main()
