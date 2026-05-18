#!/usr/bin/env python3
"""Build a minimal FFCS patch WAD (``vz-patch.wad``) for Mercenaries 2.

The engine loads ``<name>-patch.wad`` as an overlay on top of the base WAD.
Assets with matching hashes in the patch override originals (last-opened-wins).

This tool extracts the metadata for a specified block from the original WAD,
accepts a modified block (pre-compressed sges or raw), and assembles a valid
FFCS patch WAD containing just that single block.

Usage:
  # Build patch from a pre-compressed sges file
  python3 tools/build_patch_wad.py \\
    --source-wad "path/to/vz.wad" \\
    --block-index 1257 \\
    --modified-block /tmp/scripts_vz_modified.sges \\
    --output "path/to/vz-patch.wad"

  # Build patch from raw decompressed block data (auto-compresses)
  python3 tools/build_patch_wad.py \\
    --source-wad "path/to/vz.wad" \\
    --block-index 1257 \\
    --modified-block /tmp/scripts_vz_modified.block.bin \\
    --raw \\
    --output "path/to/vz-patch.wad"

  # All-in-one string mod patch (decompress, modify, recompress, build WAD)
  python3 tools/build_patch_wad.py \\
    --build-string-mod-patch \\
    --source-wad "path/to/vz.wad" \\
    --output "path/to/vz-patch.wad"

  # Analyze block metadata and save to JSON
  python3 tools/build_patch_wad.py \\
    --analyze-block \\
    --source-wad "path/to/vz.wad" \\
    --block-index 1257 \\
    --output /tmp/block_1257_metadata.json
"""

from __future__ import annotations

import argparse
import json
import mmap as mmap_mod
import struct
import sys
import zlib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from ffcs_wad import FFCSChunk, dump_paths_from_pths, extract_slice, parse_ffcs  # noqa: E402
from sges_compress import compress_sges  # noqa: E402
from sges_decompress import decompress_sges_block, find_sges_offsets, parse_sges_header  # noqa: E402
from wad_patcher import (  # noqa: E402
    OILCON001_MOD_SOURCE,
    OILCON001_STRING_SWAPS,
    DEMO_QUIT_METHOD,
    DEMO_QUIT_REPLACEMENT,
    LUAQ_SIG,
    crc32_mercs2,
    get_block_boundaries,
    parse_block_entries,
    get_script_name,
    _update_block_header_size,
)

WIFVZBOUNDARY_NOOP_SOURCE = '''\
import("MrxVoSequence")

_bMapBoundariesDrawn = false
_sBoundaryName = nil

function SetupBoundaryIntro()
end

function SetupBoundary00()
end

function SetupBoundaryINTRO_OIL()
end

function SetupBoundaryPOST_OIL()
end

function SetupBoundaryPOST_EVA_PRE_PIR()
end

function SetupBoundaryPOST_EVA_POST_PIR()
end

function SetupBoundaryPMCCON003()
end

function SetupBoundary02()
end

function SetupBoundary(sBoundaryName, bShowMessage)
end

function BoundaryCallback(uPlayer, sType, sAction)
end

function RemoveWorldBoundary()
end

function EnableExclusionBoundary(sBoundaryName, bEnable)
end

function RemoveExclusionBoundaries()
end

function SetInteriorMode(bEnable)
end

function _AddBoundaryToPlayers(bEnable)
end

function _DrawWorldBoundaryOnMap(bEnable)
end

function _DrawBoundaryOnMap(sBoundaryName, bEnable, bInvert)
end

function DrawExclusionBoundaryOnMap(sBoundaryName, bEnable)
end

function SaveSingleton()
end

function LoadSingleton(tSaveData, bAutoDeactivate)
end
'''

SGES_MAGIC = b"sges"
CSUM_TAG = b"CSUM"
PAGE_SIZE = 0x8000  # 32 KB

# 258-byte PTHS trailer marker (null-terminated ASCII string appended after all
# path strings in every working WAD — identical across all 8 tested archives).
# The engine validates its presence; omitting it causes a black-screen hang.
PTHS_TRAILER = (
    b"xa37dd45ffe100bfffcc9753aabac325f07cb3fa231144fe2e33ae4783feead2"
    b"b8a73ff021fac326df0ef9753ab9cdf6573ddff0312fab0b0ff39779eaff312"
    b"a4f5de65892ffee33a44569bebf21f66d22e54a22347efd375981188743afd9"
    b"9baacc342d88a99321235798725fedcbf43252669dade32415fee89da543bf23"
    b"d4ex"
)
assert len(PTHS_TRAILER) == 258

# The 144-byte build certificate blob (byte-for-byte identical across all WADs)
FFCS_CERT_BLOB = bytes([
    0xa8, 0xd8, 0x46, 0xfa, 0x28, 0x87, 0x0e, 0x14,
    0x9a, 0xd3, 0x31, 0x71, 0xe2, 0x54, 0x0a, 0x8f,
    0xf8, 0xab, 0x0a, 0x3b, 0x3e, 0xf1, 0x5e, 0x66,
    0xd0, 0xf6, 0x53, 0xf7, 0x78, 0xe9, 0xe5, 0x39,
    0x5a, 0x54, 0x22, 0xc1, 0x54, 0x1a, 0xb8, 0xe6,
    0x87, 0x4d, 0xdf, 0xe8, 0xc7, 0x59, 0x73, 0x20,
    0x4e, 0x90, 0x0b, 0x60, 0x14, 0x3c, 0x27, 0xe5,
    0x61, 0x2d, 0x98, 0xde, 0xce, 0x7a, 0xe7, 0x99,
    0x55, 0x65, 0x16, 0x18, 0x5d, 0xc3, 0x47, 0x56,
    0xbc, 0x8d, 0x0b, 0xfa, 0x50, 0x42, 0x72, 0x5b,
    0x86, 0x2f, 0x61, 0x34, 0x10, 0xca, 0x8b, 0x9f,
    0x5c, 0x81, 0x02, 0x16, 0x20, 0x83, 0x0e, 0xfe,
    0xf2, 0x47, 0xce, 0xac, 0xc4, 0x30, 0x7d, 0x4d,
    0xd5, 0x29, 0x48, 0xea, 0x7a, 0x15, 0x11, 0xf0,
    0x14, 0x63, 0xfe, 0xbc, 0x5a, 0xbd, 0x08, 0x56,
    0x7f, 0x80, 0x10, 0x63, 0x6a, 0xdf, 0xb9, 0x59,
    0x07, 0x93, 0x56, 0x7c, 0x71, 0x03, 0xe7, 0xec,
    0xbb, 0x49, 0xf6, 0x1c, 0x80, 0x86, 0x49, 0x42,
])
assert len(FFCS_CERT_BLOB) == 144


def _align_up(value: int, alignment: int) -> int:
    return (value + alignment - 1) & ~(alignment - 1)


# ── WAD metadata extraction ──────────────────────────────────────────


def extract_block_metadata(wad_path: Path, block_index: int) -> dict:
    """Extract all metadata for a block from the original WAD.

    Returns a dict with: indx_entry, aset_entries, pths_string,
    block_file_offset, block_size, header_blob.
    """
    raw = wad_path.read_bytes()
    arch = parse_ffcs(wad_path)

    # Extract the raw FFCS header (first 0xD8 bytes)
    header_blob = raw[:0xD8]

    # Get chunks
    indx_chunk = next((c for c in arch.chunks if c.tag == "INDX"), None)
    aset_chunk = next((c for c in arch.chunks if c.tag == "ASET"), None)
    pths_chunk = next((c for c in arch.chunks if c.tag == "PTHS"), None)
    data_chunk = next((c for c in arch.chunks if c.tag == "DATA"), None)
    csum_chunk = next((c for c in arch.chunks if c.tag == "CSUM"), None)

    if not all([indx_chunk, aset_chunk, pths_chunk, data_chunk]):
        raise ValueError("WAD missing required chunks (INDX, ASET, PTHS, DATA)")

    # Parse INDX entry for the block
    indx_data = extract_slice(raw, indx_chunk)
    num_indx_entries = indx_chunk.meta
    if block_index >= num_indx_entries:
        raise IndexError(f"Block index {block_index} >= INDX entries ({num_indx_entries})")

    indx_off = block_index * 12
    page_index, packed_field, flags_and_pages = struct.unpack_from(
        "<III", indx_data, indx_off
    )

    indx_entry = {
        "page_index": page_index,
        "packed_field": packed_field,
        "flags_and_page_count": flags_and_pages,
        "file_offset": page_index * PAGE_SIZE,
        "page_count": flags_and_pages & 0xFFFF,
        "flags": (flags_and_pages >> 16) & 0xFFFF,
    }

    # Parse PTHS string for this block
    pths_data = extract_slice(raw, pths_chunk)
    all_paths = dump_paths_from_pths(pths_data)
    pths_string = all_paths[block_index] if block_index < len(all_paths) else ""

    # Parse ASET entries for this block
    # ASET rows are 16 bytes; u32_2 high 16 bits = block index
    aset_data = extract_slice(raw, aset_chunk)
    num_aset_entries = aset_chunk.meta
    block_aset_entries = []

    for i in range(num_aset_entries):
        off = i * 16
        u0, u1, u2, u3 = struct.unpack_from("<IIII", aset_data, off)
        aset_block_idx = (u2 >> 16) & 0xFFFF
        if aset_block_idx == block_index:
            block_aset_entries.append({
                "row_index": i,
                "asset_hash": u0,
                "u32_1": u1,
                "u32_2": u2,
                "u32_3": u3,
            })

    # Get the block's file boundaries from the DATA region
    with open(wad_path, "rb") as f:
        mm = mmap_mod.mmap(f.fileno(), 0, access=mmap_mod.ACCESS_READ)
    try:
        boundaries = get_block_boundaries(mm, data_chunk.offset, data_chunk.size)
        if block_index >= len(boundaries):
            raise IndexError(f"Block {block_index} beyond boundary scan ({len(boundaries)} found)")
        block_start, block_end = boundaries[block_index]
        block_data = bytes(mm[block_start:block_end])
    finally:
        mm.close()

    return {
        "block_index": block_index,
        "indx_entry": indx_entry,
        "aset_entries": block_aset_entries,
        "aset_entry_count": len(block_aset_entries),
        "pths_string": pths_string,
        "block_file_offset": block_start,
        "block_compressed_size": len(block_data),
        "header_blob_hex": header_blob.hex(),
        "csum_value": csum_chunk.offset if csum_chunk else 0,
        "csum_meta": csum_chunk.meta if csum_chunk else 0,
        "compressed_block_data": block_data,
    }


# ── Patch WAD builder ─────────────────────────────────────────────────


def build_patch_wad(
    *,
    indx_entry: dict,
    aset_entries: list[dict],
    pths_string: str,
    compressed_block: bytes,
    csum_value: int = 0,
) -> bytes:
    """Build a complete FFCS patch WAD containing a single block.

    Layout:
      [0x000 - 0x0FF]  FFCS header (256 bytes padded)
      [0x8000]         INDX data (1 entry × 12 bytes)
      [0x800C]         ASET data (N entries × 16 bytes)
      [ASET_end]       PTHS data (null-terminated path string)
      [0x208000]       DATA: sges-compressed block
      [DATA_end]       Page-aligned end
    """
    # Fixed layout offsets (matching original WAD conventions)
    indx_offset = 0x8000
    indx_size = 12  # 1 entry

    aset_offset = indx_offset + indx_size
    aset_size = len(aset_entries) * 16

    pths_offset = aset_offset + aset_size
    pths_bytes = pths_string.encode("utf-8") + b"\x00" + PTHS_TRAILER + b"\x00"
    pths_size = len(pths_bytes)

    # DATA starts at page 0x41 (same convention as original)
    data_offset = 0x208000
    data_page_index = data_offset // PAGE_SIZE  # = 0x41

    # Calculate block pages (round up to PAGE_SIZE)
    block_pages = _align_up(len(compressed_block), PAGE_SIZE) // PAGE_SIZE
    total_data_size = block_pages * PAGE_SIZE

    # Total file size
    file_size = data_offset + total_data_size

    # ── Build FFCS header ──
    # Magic + version + chunk count
    header = bytearray(256)
    struct.pack_into("<4sII", header, 0, b"FFCS", 2, 7)

    # 5 chunk rows at offset 0x0C (12 bytes each = 60 bytes, ending at 0x48)
    chunk_rows_off = 0x0C
    # Row 0: INDX
    struct.pack_into("<4sII", header, chunk_rows_off + 0,
                     b"INDX", indx_offset, 1)  # meta=1 (1 block entry)
    # Row 1: DATA
    struct.pack_into("<4sII", header, chunk_rows_off + 12,
                     b"DATA", data_offset, 36)  # meta=36 (constant in all WADs)
    # Row 2: CSUM
    struct.pack_into("<4sII", header, chunk_rows_off + 24,
                     b"CSUM", csum_value, len(aset_entries))  # meta = entry count
    # Row 3: ASET
    struct.pack_into("<4sII", header, chunk_rows_off + 36,
                     b"ASET", aset_offset, len(aset_entries))
    # Row 4: PTHS
    struct.pack_into("<4sII", header, chunk_rows_off + 48,
                     b"PTHS", pths_offset, 1)  # meta=1 (1 path string)

    # 144-byte certificate blob at offset 0x48
    header[0x48:0x48 + 144] = FFCS_CERT_BLOB

    # Rest of header (0xD8 to 0xFF) is zero-padded (already zeroed)

    # ── Allocate output buffer ──
    out = bytearray(file_size)
    out[0:256] = header

    # ── Write INDX entry ──
    # Remap page_index to our data region (block 0 starts at data_page_index)
    struct.pack_into("<III", out, indx_offset,
                     data_page_index,
                     indx_entry["packed_field"],
                     (indx_entry["flags"] << 16) | block_pages)

    # ── Write ASET entries ──
    # Remap block index in u32_2 to 0 (this patch has only 1 block at index 0)
    for i, aset in enumerate(aset_entries):
        off = aset_offset + i * 16
        # Rewrite u32_2: keep low 16 bits, set high 16 bits to 0 (our block index)
        u2_remapped = (0 << 16) | (aset["u32_2"] & 0xFFFF)
        struct.pack_into("<IIII", out, off,
                         aset["asset_hash"],
                         aset["u32_1"],
                         u2_remapped,
                         aset["u32_3"])

    # ── Write PTHS ──
    out[pths_offset:pths_offset + pths_size] = pths_bytes

    # ── Write DATA (compressed block) ──
    out[data_offset:data_offset + len(compressed_block)] = compressed_block

    return bytes(out)


# ── String mod convenience ────────────────────────────────────────────


def apply_string_mod_to_block(decompressed: bytes) -> bytes:
    """Apply the 6 oilcon001 string swaps + demo timer disable to a block.

    Returns the modified decompressed block data with updated CSUMs.
    """
    entries = parse_block_entries(decompressed)
    modified = bytearray(decompressed)
    total_patches = 0

    for entry in entries:
        entry_start = entry["offset"]
        entry_body_end = entry["offset"] + entry["size"] - 8
        chunk = bytes(modified[entry_start:entry_body_end])
        patched = False

        # Apply oilcon001 string swaps
        name = get_script_name(decompressed, entry)
        if "oilcon001" in name.lower():
            for old_bytes, new_bytes, _desc in OILCON001_STRING_SWAPS:
                hit_pos = chunk.find(old_bytes)
                if hit_pos >= 0:
                    abs_off = entry_start + hit_pos
                    modified[abs_off:abs_off + len(old_bytes)] = new_bytes
                    patched = True
                    total_patches += 1

        # Apply demo timer disable
        pos = 0
        while True:
            idx = chunk.find(DEMO_QUIT_METHOD, pos)
            if idx < 0:
                break
            abs_off = entry_start + idx
            modified[abs_off:abs_off + len(DEMO_QUIT_METHOD)] = DEMO_QUIT_REPLACEMENT
            patched = True
            total_patches += 1
            pos = idx + len(DEMO_QUIT_METHOD)

        # Recompute CSUM if we modified this entry
        if patched:
            csum_off = entry["csum_offset"]
            if modified[csum_off:csum_off + 4] == CSUM_TAG:
                ucfx_body = bytes(modified[entry_start:csum_off])
                new_csum = crc32_mercs2(ucfx_body)
                struct.pack_into("<I", modified, csum_off + 4, new_csum)

    print(f"  Applied {total_patches} modifications across block entries")
    return bytes(modified)


def cmd_build_string_mod_patch(
    source_wad: Path,
    output: Path,
    *,
    segment_size: int = 65536,
    compression_level: int = 6,
) -> int:
    """All-in-one: decompress block 1257, apply mods, recompress, build patch WAD."""
    print(f"Building string mod patch WAD...")
    print(f"  Source WAD: {source_wad}")
    print(f"  Output:     {output}")

    # Extract metadata for block 1257
    print("\n[1/5] Extracting block 1257 metadata from original WAD...")
    meta = extract_block_metadata(source_wad, 1257)
    print(f"  INDX entry: page={meta['indx_entry']['page_index']}, "
          f"packed={meta['indx_entry']['packed_field']}, "
          f"flags_pages=0x{meta['indx_entry']['flags_and_page_count']:08X}")
    print(f"  ASET entries: {meta['aset_entry_count']}")
    print(f"  PTHS: {meta['pths_string']}")
    print(f"  Compressed size: {meta['block_compressed_size']:,} bytes")

    # Decompress
    print("\n[2/5] Decompressing block 1257...")
    compressed_data = meta["compressed_block_data"]
    decompressed = decompress_sges_block(
        compressed_data, 0, len(compressed_data)
    )
    print(f"  Decompressed: {len(decompressed):,} bytes")

    # Apply modifications
    print("\n[3/5] Applying string modifications...")
    modified = apply_string_mod_to_block(decompressed)

    # Recompress
    print("\n[4/5] Recompressing with sges (major=4)...")
    new_sges = compress_sges(
        modified,
        segment_size=segment_size,
        level=compression_level,
        major=4,
    )
    ratio = len(new_sges) / len(modified) * 100
    print(f"  Compressed: {len(new_sges):,} bytes ({ratio:.1f}%)")

    # Verify roundtrip
    verify = decompress_sges_block(new_sges, 0, len(new_sges))
    if verify != modified:
        print("ERROR: Roundtrip verification failed!", file=sys.stderr)
        return 1
    print("  Roundtrip verification OK")

    # Build patch WAD
    print("\n[5/5] Building patch WAD...")
    patch_wad = build_patch_wad(
        indx_entry=meta["indx_entry"],
        aset_entries=meta["aset_entries"],
        pths_string=meta["pths_string"],
        compressed_block=new_sges,
        csum_value=meta["csum_value"],
    )

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(patch_wad)
    print(f"\n  Wrote: {output} ({len(patch_wad):,} bytes)")
    print(f"  DATA offset: 0x208000")
    print(f"  Block pages: {_align_up(len(new_sges), PAGE_SIZE) // PAGE_SIZE}")

    return 0


def apply_bytecode_replacement_to_block(
    decompressed: bytes,
    script_name: str,
    new_bytecode: bytes,
) -> bytes:
    """Replace a script's LuaQ bytecode in a decompressed block.

    Finds the named script entry, locates its LuaQ signature, replaces
    the bytecode, updates the block header's chunk_size, and recomputes
    the CSUM.  Returns the modified decompressed block.
    """
    entries = parse_block_entries(decompressed)
    target_entry = None

    for entry in entries:
        name = get_script_name(decompressed, entry)
        if script_name.lower() in name.lower():
            target_entry = entry
            break

    if target_entry is None:
        available = [get_script_name(decompressed, e) for e in entries]
        raise ValueError(
            f"Script '{script_name}' not found. Available: {available[:20]}"
        )

    target_name = get_script_name(decompressed, target_entry)
    print(f"  Found script '{target_name}' at UCFX chunk {target_entry['index']}")
    print(f"    Hash: 0x{target_entry['hash']:08X}, Size: {target_entry['size']:,} bytes")

    entry_start = target_entry["offset"]
    entry_end = entry_start + target_entry["size"] - 8  # exclude CSUM trailer
    chunk = decompressed[entry_start:entry_end]
    luaq_rel = chunk.find(LUAQ_SIG)
    if luaq_rel < 0:
        raise ValueError("No LuaQ signature found in target UCFX chunk")

    old_luaq_abs = entry_start + luaq_rel
    old_bytecode_len = entry_end - old_luaq_abs
    new_bytecode_len = len(new_bytecode)
    size_delta = new_bytecode_len - old_bytecode_len

    print(f"    LuaQ at: 0x{old_luaq_abs:x} (entry +{luaq_rel})")
    print(f"    Old bytecode: {old_bytecode_len:,} bytes")
    print(f"    New bytecode: {new_bytecode_len:,} bytes")
    print(f"    Size delta: {size_delta:+,} bytes")

    modified = bytearray(decompressed)

    pre_luaq = bytes(modified[:old_luaq_abs])
    post_entry = bytes(modified[entry_end + 8:])  # after CSUM trailer

    new_chunk = pre_luaq[entry_start:old_luaq_abs] + new_bytecode
    new_chunk_size = len(new_chunk) + 8  # +8 for CSUM tag + value

    rebuilt = bytearray(modified[:entry_start])
    rebuilt.extend(new_chunk)
    new_csum = crc32_mercs2(bytes(rebuilt[entry_start:]))
    rebuilt.extend(CSUM_TAG)
    rebuilt.extend(struct.pack("<I", new_csum))
    rebuilt.extend(post_entry)

    _update_block_header_size(rebuilt, target_entry["index"], new_chunk_size)

    print(f"    New CSUM: 0x{new_csum:08X}")
    print(f"    New chunk size: {new_chunk_size:,} bytes (delta {size_delta:+,})")

    return bytes(rebuilt)


def compile_lua_source(source: str, luac_path: Path) -> bytes:
    """Compile Lua source code to bytecode using the Mercs2-compatible luac."""
    import subprocess
    import tempfile

    if not luac_path.is_file():
        raise FileNotFoundError(
            f"Lua compiler not found at {luac_path}. "
            f"Build it with: cd lua-5.1.5 && make posix"
        )

    with tempfile.TemporaryDirectory() as tmp:
        src = Path(tmp) / "mod.lua"
        out = Path(tmp) / "mod.luac"
        src.write_text(source)

        result = subprocess.run(
            [str(luac_path), "-o", str(out), str(src)],
            capture_output=True, text=True,
        )
        if result.returncode != 0:
            raise RuntimeError(f"luac compilation failed:\n{result.stderr}")

        bytecode = out.read_bytes()

    if bytecode[:4] != b"\x1bLua":
        raise ValueError("Compiled output has wrong signature")

    print(f"  Compiled: {len(bytecode):,} bytes")
    print(f"  Header: version=0x{bytecode[4]:02x} "
          f"int={bytecode[7]} size_t={bytecode[8]} "
          f"number={bytecode[10]} (float={'yes' if bytecode[11]==0 else 'no'})")

    return bytecode


def cmd_build_autocomplete_patch(
    source_wad: Path,
    output: Path,
    *,
    segment_size: int = 65536,
    compression_level: int = 6,
) -> int:
    """All-in-one: compile auto-complete Lua, replace oilcon001 bytecode, build patch WAD.

    Compiles a minimal Lua script that inherits MrxTaskContract, calls the
    parent Activated(), then fires a 5-second timer to self:Complete().
    The compiled bytecode replaces oilcon001's original bytecode in block 1257.
    """
    print("Building auto-complete oilcon001 patch WAD...")
    print(f"  Source WAD: {source_wad}")
    print(f"  Output:     {output}")

    # Locate luac compiler
    repo_root = Path(__file__).resolve().parent.parent
    luac = repo_root / "lua-5.1.5" / "src" / "luac"

    # Step 1: Compile the mod source
    print("\n[1/5] Compiling auto-complete Lua source...")
    bytecode = compile_lua_source(OILCON001_MOD_SOURCE, luac)

    # Step 2: Extract block 1257 metadata
    print("\n[2/5] Extracting block 1257 metadata from original WAD...")
    meta = extract_block_metadata(source_wad, 1257)
    print(f"  INDX entry: page={meta['indx_entry']['page_index']}, "
          f"packed={meta['indx_entry']['packed_field']}")
    print(f"  ASET entries: {meta['aset_entry_count']}")
    print(f"  PTHS: {meta['pths_string']}")
    print(f"  Compressed size: {meta['block_compressed_size']:,} bytes")

    # Step 3: Decompress block 1257
    print("\n[3/5] Decompressing block 1257...")
    compressed_data = meta["compressed_block_data"]
    decompressed = decompress_sges_block(
        compressed_data, 0, len(compressed_data)
    )
    print(f"  Decompressed: {len(decompressed):,} bytes")

    # Step 4: Replace oilcon001 bytecode
    print("\n[4/5] Replacing oilcon001 bytecode...")
    modified = apply_bytecode_replacement_to_block(
        decompressed, "oilcon001", bytecode
    )
    print(f"  Modified block: {len(modified):,} bytes "
          f"(delta {len(modified) - len(decompressed):+,})")

    # Recompress
    print("\n  Recompressing with sges (major=4)...")
    new_sges = compress_sges(
        modified,
        segment_size=segment_size,
        level=compression_level,
        major=4,
    )
    ratio = len(new_sges) / len(modified) * 100
    print(f"  Compressed: {len(new_sges):,} bytes ({ratio:.1f}%)")

    # Verify roundtrip
    verify = decompress_sges_block(new_sges, 0, len(new_sges))
    if verify != modified:
        print("ERROR: Roundtrip verification failed!", file=sys.stderr)
        return 1
    print("  Roundtrip verification OK")

    # Step 5: Build patch WAD
    print("\n[5/5] Building patch WAD...")
    patch_wad = build_patch_wad(
        indx_entry=meta["indx_entry"],
        aset_entries=meta["aset_entries"],
        pths_string=meta["pths_string"],
        compressed_block=new_sges,
        csum_value=meta["csum_value"],
    )

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(patch_wad)
    print(f"\n  Wrote: {output} ({len(patch_wad):,} bytes)")
    print(f"  DATA offset: 0x208000")
    print(f"  Block pages: {_align_up(len(new_sges), PAGE_SIZE) // PAGE_SIZE}")

    return 0


def cmd_remove_boundaries(
    source_wad: Path,
    output: Path,
    *,
    segment_size: int = 65536,
    compression_level: int = 6,
) -> int:
    """All-in-one: replace wifvzboundary with noop + apply string mods, build patch WAD.

    Compiles a no-op version of the wifvzboundary script (all boundary functions
    are empty stubs) and replaces the original bytecode. Also applies the oilcon001
    string swaps and demo timer disable so the patch WAD is a complete mod bundle.
    """
    print("Building boundary-removal patch WAD...")
    print(f"  Source WAD: {source_wad}")
    print(f"  Output:     {output}")

    repo_root = Path(__file__).resolve().parent.parent
    luac = repo_root / "lua-5.1.5" / "src" / "luac"

    # Step 1: Compile the noop boundary script
    print("\n[1/6] Compiling noop wifvzboundary Lua source...")
    bytecode = compile_lua_source(WIFVZBOUNDARY_NOOP_SOURCE, luac)

    # Step 2: Extract block 1257 metadata
    print("\n[2/6] Extracting block 1257 metadata from original WAD...")
    meta = extract_block_metadata(source_wad, 1257)
    print(f"  INDX entry: page={meta['indx_entry']['page_index']}, "
          f"packed={meta['indx_entry']['packed_field']}")
    print(f"  ASET entries: {meta['aset_entry_count']}")
    print(f"  PTHS: {meta['pths_string']}")
    print(f"  Compressed size: {meta['block_compressed_size']:,} bytes")

    # Step 3: Decompress block 1257
    print("\n[3/6] Decompressing block 1257...")
    compressed_data = meta["compressed_block_data"]
    decompressed = decompress_sges_block(
        compressed_data, 0, len(compressed_data)
    )
    print(f"  Decompressed: {len(decompressed):,} bytes")

    # Step 4: Replace wifvzboundary bytecode
    print("\n[4/6] Replacing wifvzboundary bytecode with noop version...")
    modified = apply_bytecode_replacement_to_block(
        decompressed, "wifvzboundary", bytecode
    )
    print(f"  Modified block: {len(modified):,} bytes "
          f"(delta {len(modified) - len(decompressed):+,})")

    # Step 5: Apply oilcon001 string mods + demo timer disable on top
    print("\n[5/6] Applying oilcon001 string mods + demo timer disable...")
    modified = apply_string_mod_to_block(modified)

    # Recompress
    print("\n  Recompressing with sges (major=4)...")
    new_sges = compress_sges(
        modified,
        segment_size=segment_size,
        level=compression_level,
        major=4,
    )
    ratio = len(new_sges) / len(modified) * 100
    print(f"  Compressed: {len(new_sges):,} bytes ({ratio:.1f}%)")

    # Verify roundtrip
    verify = decompress_sges_block(new_sges, 0, len(new_sges))
    if verify != modified:
        print("ERROR: Roundtrip verification failed!", file=sys.stderr)
        return 1
    print("  Roundtrip verification OK")

    # Step 6: Build patch WAD
    print("\n[6/6] Building patch WAD...")
    patch_wad = build_patch_wad(
        indx_entry=meta["indx_entry"],
        aset_entries=meta["aset_entries"],
        pths_string=meta["pths_string"],
        compressed_block=new_sges,
        csum_value=meta["csum_value"],
    )

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(patch_wad)
    print(f"\n  Wrote: {output} ({len(patch_wad):,} bytes)")
    print(f"  DATA offset: 0x208000")
    print(f"  Block pages: {_align_up(len(new_sges), PAGE_SIZE) // PAGE_SIZE}")
    print(f"\n  Mods applied:")
    print(f"    - wifvzboundary: all boundary functions replaced with no-ops")
    print(f"    - oilcon001: 6 string swaps (MODDED labels)")
    print(f"    - demo timer: ShowDemoOutroAndQuitToShell disabled")

    return 0


def cmd_build_passthrough_patch(
    source_wad: Path, block_index: int, output: Path,
) -> int:
    """Build a patch WAD using the ORIGINAL unmodified compressed block.

    No decompression, no recompression, no string swaps — just the exact
    same bytes from the source WAD wrapped in our FFCS patch structure.
    This isolates whether the FFCS structure itself is the problem.
    """
    print(f"Building PASSTHROUGH patch WAD (block {block_index})...")
    print(f"  Source WAD: {source_wad}")
    print(f"  Output:     {output}")
    print(f"  Mode: VERBATIM copy — zero decompression/recompression")

    print("\n[1/3] Extracting block metadata from original WAD...")
    meta = extract_block_metadata(source_wad, block_index)
    original_block = meta["compressed_block_data"]

    print(f"  INDX entry: page={meta['indx_entry']['page_index']}, "
          f"packed={meta['indx_entry']['packed_field']}, "
          f"flags_pages=0x{meta['indx_entry']['flags_and_page_count']:08X}")
    print(f"  ASET entries: {meta['aset_entry_count']}")
    print(f"  PTHS: {meta['pths_string']}")
    print(f"  Compressed block size: {len(original_block):,} bytes")
    print(f"  Block file offset in source WAD: 0x{meta['block_file_offset']:X}")

    if original_block[:4] != SGES_MAGIC:
        print(f"ERROR: Block does not start with sges magic "
              f"(got {original_block[:4]!r})", file=sys.stderr)
        return 1
    print(f"  sges magic: OK")

    print("\n[2/3] Building patch WAD with verbatim block data...")
    patch_wad = build_patch_wad(
        indx_entry=meta["indx_entry"],
        aset_entries=meta["aset_entries"],
        pths_string=meta["pths_string"],
        compressed_block=original_block,
        csum_value=meta["csum_value"],
    )

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(patch_wad)
    block_pages = _align_up(len(original_block), PAGE_SIZE) // PAGE_SIZE
    print(f"  Wrote: {output} ({len(patch_wad):,} bytes)")
    print(f"  DATA offset in patch: 0x208000")
    print(f"  Block pages: {block_pages}")

    print("\n[3/3] Verifying DATA section matches original block...")
    data_offset = 0x208000
    patch_raw = output.read_bytes()
    embedded_block = patch_raw[data_offset:data_offset + len(original_block)]
    if embedded_block == original_block:
        print("  PASS: Embedded block is byte-for-byte identical to original")
    else:
        mismatch_pos = next(
            i for i in range(len(original_block))
            if embedded_block[i] != original_block[i]
        )
        print(f"  FAIL: First mismatch at offset {mismatch_pos} "
              f"(patch=0x{embedded_block[mismatch_pos]:02X} vs "
              f"orig=0x{original_block[mismatch_pos]:02X})", file=sys.stderr)
        return 1

    source_raw = source_wad.read_bytes()
    src_off = meta["block_file_offset"]
    sample_offsets = [0, 4, 8, 16, 100, 1000, len(original_block) - 4]
    print(f"\n  Spot-check (patch DATA vs source WAD at block offset):")
    for so in sample_offsets:
        if so >= len(original_block):
            continue
        patch_byte = patch_raw[data_offset + so]
        source_byte = source_raw[src_off + so]
        match = "OK" if patch_byte == source_byte else "MISMATCH"
        print(f"    +0x{so:04X}: patch=0x{patch_byte:02X} source=0x{source_byte:02X} {match}")

    print(f"\nDone. Passthrough patch WAD written to: {output}")
    print(f"If this WAD also causes a black screen → FFCS structure is wrong.")
    print(f"If this WAD works → sges recompression is the problem.")
    return 0


# ── Analyze block command ─────────────────────────────────────────


def cmd_analyze_block(source_wad: Path, block_index: int, output: Path) -> int:
    """Extract and save block metadata to JSON."""
    print(f"Analyzing block {block_index} in {source_wad}...")

    meta = extract_block_metadata(source_wad, block_index)

    # Build JSON-serializable output (exclude raw binary data)
    json_out = {
        "block_index": meta["block_index"],
        "indx_entry": meta["indx_entry"],
        "aset_entries": [
            {
                "row_index": e["row_index"],
                "asset_hash": f"0x{e['asset_hash']:08X}",
                "u32_1": f"0x{e['u32_1']:08X}",
                "u32_2": f"0x{e['u32_2']:08X}",
                "u32_3": e["u32_3"],
            }
            for e in meta["aset_entries"]
        ],
        "aset_entry_count": meta["aset_entry_count"],
        "pths_string": meta["pths_string"],
        "block_file_offset": f"0x{meta['block_file_offset']:X}",
        "block_compressed_size": meta["block_compressed_size"],
        "csum_value": f"0x{meta['csum_value']:08X}",
        "csum_meta": meta["csum_meta"],
        "header_first_32_hex": meta["header_blob_hex"][:64],
    }

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(json_out, indent=2), encoding="utf-8")
    print(f"Wrote metadata to {output}")
    print(f"  INDX: page_index={meta['indx_entry']['page_index']}, "
          f"packed_field={meta['indx_entry']['packed_field']}, "
          f"flags_and_pages=0x{meta['indx_entry']['flags_and_page_count']:08X}")
    print(f"  ASET: {meta['aset_entry_count']} entries for this block")
    print(f"  PTHS: \"{meta['pths_string']}\"")
    print(f"  Block offset: 0x{meta['block_file_offset']:X}, "
          f"size: {meta['block_compressed_size']:,} bytes")

    return 0


# ── Generic patch build command ───────────────────────────────────────


def cmd_build_patch(
    source_wad: Path,
    block_index: int,
    modified_block: Path,
    output: Path,
    *,
    is_raw: bool = False,
    segment_size: int = 65536,
    compression_level: int = 6,
) -> int:
    """Build a patch WAD from a source WAD and modified block file."""
    print(f"Building patch WAD for block {block_index}...")
    print(f"  Source WAD: {source_wad}")
    print(f"  Modified block: {modified_block}")
    print(f"  Output: {output}")

    # Extract metadata
    meta = extract_block_metadata(source_wad, block_index)
    print(f"  ASET entries: {meta['aset_entry_count']}")
    print(f"  PTHS: \"{meta['pths_string']}\"")

    # Read modified block
    block_data = modified_block.read_bytes()

    if is_raw:
        # Compress raw data
        print(f"  Compressing raw block ({len(block_data):,} bytes)...")
        compressed = compress_sges(
            block_data,
            segment_size=segment_size,
            level=compression_level,
            major=4,
        )
        print(f"  Compressed to {len(compressed):,} bytes")
    else:
        # Verify it's sges
        if block_data[:4] != SGES_MAGIC:
            print("ERROR: Modified block does not start with sges magic. "
                  "Use --raw if providing decompressed data.", file=sys.stderr)
            return 1
        compressed = block_data
        print(f"  Using pre-compressed sges ({len(compressed):,} bytes)")

    # Build patch WAD
    patch_wad = build_patch_wad(
        indx_entry=meta["indx_entry"],
        aset_entries=meta["aset_entries"],
        pths_string=meta["pths_string"],
        compressed_block=compressed,
        csum_value=meta["csum_value"],
    )

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(patch_wad)
    print(f"\n  Wrote: {output} ({len(patch_wad):,} bytes)")

    return 0


# ── Validation helper ─────────────────────────────────────────────────


def validate_patch_wad(wad_path: Path) -> int:
    """Validate and print a summary of a patch WAD."""
    raw = wad_path.read_bytes()
    size = len(raw)

    print(f"Validating: {wad_path} ({size:,} bytes)")
    print("=" * 60)

    # Check FFCS magic
    if raw[:4] != b"FFCS":
        print("FAIL: Missing FFCS magic", file=sys.stderr)
        return 1
    print(f"  Magic: FFCS OK")

    # Version
    version = struct.unpack_from("<I", raw, 4)[0]
    print(f"  Version: {version}")

    # Chunk count
    chunk_count = struct.unpack_from("<I", raw, 8)[0]
    print(f"  Declared chunk count: {chunk_count}")

    # Chunk rows
    print(f"\n  Chunk rows:")
    for i in range(5):
        off = 0x0C + i * 12
        tag = raw[off:off + 4].decode("ascii")
        val, meta = struct.unpack_from("<II", raw, off + 4)
        print(f"    [{i}] {tag}: offset/value=0x{val:08X}, meta={meta}")

    # Certificate blob
    cert = raw[0x48:0x48 + 144]
    if cert == FFCS_CERT_BLOB:
        print(f"\n  Certificate blob: OK (matches known 144-byte blob)")
    else:
        print(f"\n  Certificate blob: MISMATCH!", file=sys.stderr)
        return 1

    # Parse INDX
    indx_off = struct.unpack_from("<I", raw, 0x0C + 4)[0]
    indx_meta = struct.unpack_from("<I", raw, 0x0C + 8)[0]
    print(f"\n  INDX ({indx_meta} entries at offset 0x{indx_off:X}):")
    for i in range(indx_meta):
        off = indx_off + i * 12
        page_idx, packed, flags_pages = struct.unpack_from("<III", raw, off)
        pages = flags_pages & 0xFFFF
        flags = (flags_pages >> 16) & 0xFFFF
        print(f"    [{i}] page_index={page_idx} (offset=0x{page_idx * PAGE_SIZE:X}), "
              f"packed={packed}, flags=0x{flags:04X}, pages={pages}")

    # Parse ASET
    aset_off = struct.unpack_from("<I", raw, 0x0C + 36 + 4)[0]
    aset_meta = struct.unpack_from("<I", raw, 0x0C + 36 + 8)[0]
    print(f"\n  ASET ({aset_meta} entries at offset 0x{aset_off:X}):")
    for i in range(min(aset_meta, 10)):
        off = aset_off + i * 16
        u0, u1, u2, u3 = struct.unpack_from("<IIII", raw, off)
        block_idx = (u2 >> 16) & 0xFFFF
        print(f"    [{i}] hash=0x{u0:08X} u1=0x{u1:08X} u2=0x{u2:08X} "
              f"(block={block_idx}) u3={u3}")
    if aset_meta > 10:
        print(f"    ... ({aset_meta - 10} more entries)")

    # Parse PTHS
    pths_off = struct.unpack_from("<I", raw, 0x0C + 48 + 4)[0]
    pths_meta = struct.unpack_from("<I", raw, 0x0C + 48 + 8)[0]
    pths_end = raw.find(b"\x00", pths_off)
    if pths_end < 0:
        pths_end = min(pths_off + 256, size)
    pths_str = raw[pths_off:pths_end].decode("utf-8", errors="replace")
    print(f"\n  PTHS ({pths_meta} strings at offset 0x{pths_off:X}):")
    print(f"    \"{pths_str}\"")

    # Check for PTHS trailer marker
    trailer_pos = raw.find(PTHS_TRAILER, pths_off)
    if trailer_pos >= 0 and trailer_pos < (pths_off + 0x100000):
        print(f"  PTHS trailer marker: PRESENT at offset 0x{trailer_pos:X}")
    else:
        print(f"  PTHS trailer marker: MISSING!", file=sys.stderr)
        return 1

    # Check DATA region
    data_off = struct.unpack_from("<I", raw, 0x0C + 12 + 4)[0]
    if data_off < size:
        data_magic = raw[data_off:data_off + 4]
        if data_magic == SGES_MAGIC:
            print(f"\n  DATA (at offset 0x{data_off:X}):")
            maj, minor, total_u, total_c = parse_sges_header(raw[data_off:data_off + 16])
            print(f"    sges v{maj}.{minor}: uncompressed={total_u:,}, "
                  f"compressed={total_c:,}, segments={minor}")
        else:
            print(f"\n  DATA (at offset 0x{data_off:X}): "
                  f"first 4 bytes = {data_magic.hex()}")
    else:
        print(f"\n  DATA offset 0x{data_off:X} beyond file size!")

    print(f"\n{'=' * 60}")
    print("VALIDATION PASSED")
    return 0


# ── CLI ───────────────────────────────────────────────────────────────


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Build FFCS patch WAD (vz-patch.wad) for Mercenaries 2 modding",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    ap.add_argument("--source-wad", type=Path,
                    help="Path to original vz.wad")
    ap.add_argument("--block-index", type=int, default=1257,
                    help="Block index to patch (default: 1257 = scripts_vz)")
    ap.add_argument("--modified-block", type=Path,
                    help="Path to modified block (sges or raw)")
    ap.add_argument("--raw", action="store_true",
                    help="Treat --modified-block as raw decompressed data (will compress)")
    ap.add_argument("--output", "-o", type=Path,
                    help="Output path for patch WAD or metadata JSON")
    ap.add_argument("--segment-size", type=int, default=65536,
                    help="Segment size for sges compression (default 65536)")
    ap.add_argument("--compression-level", type=int, default=6,
                    help="zlib compression level 1-9 (default 6)")

    # Mode flags
    ap.add_argument("--analyze-block", action="store_true",
                    help="Analyze block metadata and save to JSON")
    ap.add_argument("--build-string-mod-patch", action="store_true",
                    help="All-in-one: decompress block 1257, apply string mods, "
                         "recompress, build patch WAD")
    ap.add_argument("--build-autocomplete-patch", action="store_true",
                    help="All-in-one: compile auto-complete Lua, replace oilcon001 "
                         "bytecode in block 1257, build patch WAD")
    ap.add_argument("--validate", action="store_true",
                    help="Validate an existing patch WAD (--output = WAD to validate)")
    ap.add_argument("--passthrough", action="store_true",
                    help="Build patch WAD using the ORIGINAL unmodified compressed "
                         "block — no decompression or recompression. Used to isolate "
                         "FFCS structure issues vs sges recompression issues.")
    ap.add_argument("--remove-boundaries", action="store_true",
                    help="All-in-one: replace wifvzboundary with noop script "
                         "(disables all world boundaries), apply oilcon001 string "
                         "mods + demo timer disable, build patch WAD")

    args = ap.parse_args()

    if args.validate:
        if args.output is None:
            ap.error("--validate requires --output (path to WAD to validate)")
        return validate_patch_wad(args.output)

    if args.passthrough:
        if args.source_wad is None:
            ap.error("--passthrough requires --source-wad")
        if args.output is None:
            ap.error("--passthrough requires --output")
        return cmd_build_passthrough_patch(
            args.source_wad, args.block_index, args.output,
        )

    if args.analyze_block:
        if args.source_wad is None:
            ap.error("--analyze-block requires --source-wad")
        if args.output is None:
            ap.error("--analyze-block requires --output")
        return cmd_analyze_block(args.source_wad, args.block_index, args.output)

    if args.remove_boundaries:
        if args.source_wad is None:
            ap.error("--remove-boundaries requires --source-wad")
        if args.output is None:
            ap.error("--remove-boundaries requires --output")
        return cmd_remove_boundaries(
            args.source_wad,
            args.output,
            segment_size=args.segment_size,
            compression_level=args.compression_level,
        )

    if args.build_string_mod_patch:
        if args.source_wad is None:
            ap.error("--build-string-mod-patch requires --source-wad")
        if args.output is None:
            ap.error("--build-string-mod-patch requires --output")
        return cmd_build_string_mod_patch(
            args.source_wad,
            args.output,
            segment_size=args.segment_size,
            compression_level=args.compression_level,
        )

    if args.build_autocomplete_patch:
        if args.source_wad is None:
            ap.error("--build-autocomplete-patch requires --source-wad")
        if args.output is None:
            ap.error("--build-autocomplete-patch requires --output")
        return cmd_build_autocomplete_patch(
            args.source_wad,
            args.output,
            segment_size=args.segment_size,
            compression_level=args.compression_level,
        )

    # Generic build mode
    if args.source_wad is None:
        ap.error("--source-wad is required")
    if args.modified_block is None:
        ap.error("--modified-block is required (or use --build-string-mod-patch)")
    if args.output is None:
        ap.error("--output is required")

    return cmd_build_patch(
        args.source_wad,
        args.block_index,
        args.modified_block,
        args.output,
        is_raw=args.raw,
        segment_size=args.segment_size,
        compression_level=args.compression_level,
    )


if __name__ == "__main__":
    sys.exit(main())
