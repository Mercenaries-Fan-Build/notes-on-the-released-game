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
    find_dlc_bootstrap_hook_script,
    script_aset_entry,
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

from ffcs_patch_wad import (  # noqa: E402
    FFCS_CERT_BLOB,
    PAGE_SIZE,
    PTHS_TRAILER,
    _align_up,
    build_patch_wad_single,
)

SGES_MAGIC = b"sges"
CSUM_TAG = b"CSUM"
UCFX_MAGIC = b"UCFX"
BINN_TAG = b"BINN"


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

    Delegates to the shared ffcs_patch_wad module.
    """
    return build_patch_wad_single(
        indx_entry=indx_entry,
        aset_entries=aset_entries,
        pths_string=pths_string,
        compressed_block=compressed_block,
        csum_value=csum_value,
    )


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
    from wad_patcher import resolve_scripts_vz_block_index

    scripts_idx = resolve_scripts_vz_block_index(source_wad)
    print(f"\n[1/5] Extracting scripts_vz block (index {scripts_idx})...")
    meta = extract_block_metadata(source_wad, scripts_idx)
    print(f"  INDX entry: page={meta['indx_entry']['page_index']}, "
          f"packed={meta['indx_entry']['packed_field']}, "
          f"flags_pages=0x{meta['indx_entry']['flags_and_page_count']:08X}")
    print(f"  ASET entries: {meta['aset_entry_count']}")
    print(f"  PTHS: {meta['pths_string']}")
    print(f"  Compressed size: {meta['block_compressed_size']:,} bytes")

    # Decompress
    print("\n[2/5] Decompressing scripts_vz block...")
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
            f"Build it with: make build-luac"
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


def _resolve_luac() -> Path:
    """Find the best available luac compiler for the current platform."""
    import shutil

    repo_root = Path(__file__).resolve().parent.parent
    candidates = [
        repo_root / "tools" / "lua51-mercs2" / "build" / "luac",
        repo_root / "tools" / "lua51-mercs2" / "src" / "luac",
        repo_root / "lua-backup-dont-delete" / "src" / "luac",
        repo_root / "lua-5.1.5" / "src" / "luac",
        repo_root / "tools" / "lua51-mercs2" / "luac.exe",
    ]
    for c in candidates:
        if c.is_file():
            return c
    luac_on_path = shutil.which("luac")
    if luac_on_path:
        return Path(luac_on_path)
    checked = "\n    ".join(str(c) for c in candidates)
    raise FileNotFoundError(
        f"Lua compiler not found. Checked:\n    {checked}\n    PATH (shutil.which)\n"
        f"  Build with: make build-luac"
    )


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
    luac = _resolve_luac()

    # Step 1: Compile the mod source
    print("\n[1/5] Compiling auto-complete Lua source...")
    bytecode = compile_lua_source(OILCON001_MOD_SOURCE, luac)

    from wad_patcher import resolve_scripts_vz_block_index

    scripts_idx = resolve_scripts_vz_block_index(source_wad)
    print(f"\n[2/5] Extracting scripts_vz block (index {scripts_idx})...")
    meta = extract_block_metadata(source_wad, scripts_idx)
    print(f"  INDX entry: page={meta['indx_entry']['page_index']}, "
          f"packed={meta['indx_entry']['packed_field']}")
    print(f"  ASET entries: {meta['aset_entry_count']}")
    print(f"  PTHS: {meta['pths_string']}")
    print(f"  Compressed size: {meta['block_compressed_size']:,} bytes")

    print("\n[3/5] Decompressing scripts_vz block...")
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

    luac = _resolve_luac()

    # Step 1: Compile the noop boundary script
    print("\n[1/6] Compiling noop wifvzboundary Lua source...")
    bytecode = compile_lua_source(WIFVZBOUNDARY_NOOP_SOURCE, luac)

    # Step 2: Extract block 1257 metadata
    from wad_patcher import resolve_scripts_vz_block_index

    scripts_idx = resolve_scripts_vz_block_index(source_wad)
    print(f"\n[2/6] Extracting scripts_vz block (index {scripts_idx})...")
    meta = extract_block_metadata(source_wad, scripts_idx)
    print(f"  INDX entry: page={meta['indx_entry']['page_index']}, "
          f"packed={meta['indx_entry']['packed_field']}")
    print(f"  ASET entries: {meta['aset_entry_count']}")
    print(f"  PTHS: {meta['pths_string']}")
    print(f"  Compressed size: {meta['block_compressed_size']:,} bytes")

    # Step 3: Decompress block 1257
    print("\n[3/6] Decompressing scripts_vz block...")
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


# ── DLC bootstrap injection ──────────────────────────────────────────

# The DLC01 master script — loaded by the modified `vz` script.
# Imports each DLC contract so they register with the game engine.
# The game's `import()` function looks up the script name in the
# WAD's ASET registry, finds the UCFX chunk, and executes it.
DLC01_MASTER_SOURCE = '''\
function ScriptInit()
    import("dlccon001")
    import("dlccon002")
    import("dlccon003")
    import("dlccon004")
end
'''

# Minimal DLC bootstrap stub — injected into the `vz` master script's
# constant pool via same-length string replacement. Since we cannot
# easily add NEW function calls to compiled bytecode without a full
# decompile/recompile cycle, we use a two-pronged approach:
#
# Approach A (preferred): Full bytecode replacement of the `vz` script
# with a wrapper that calls the original vz's ScriptInit + DLC import.
#
# Approach B (fallback): If the `vz` script is too complex to replace,
# we add the `dlc01` script as a new UCFX entry in the block so it
# can be loaded via `import("dlc01")` from any other script that
# already runs at startup (like `wifpmcinterior`).

VZ_DLC_WRAPPER_SOURCE = '''\
import("dlc01")
'''


def dlc_chain_wrapper_source(orig_module: str) -> str:
    """Lua wrapper: defer DLC import to ScriptInit() so it runs after block loading."""
    return (
        f'import("{orig_module}")\n'
        f'function ScriptInit()\n'
        f'    import("dlc01")\n'
        f'end\n'
    )


def extract_script_bytecode(decompressed: bytes, script_name: str) -> bytes:
    """Return LuaQ bytecode bytes for a named script entry in a decompressed block."""
    entries = parse_block_entries(decompressed)
    target_entry = None
    for entry in entries:
        name = get_script_name(decompressed, entry)
        if script_name.lower() in name.lower():
            target_entry = entry
            break
    if target_entry is None:
        raise ValueError(f"Script {script_name!r} not found for bytecode extract")

    entry_start = target_entry["offset"]
    entry_end = entry_start + target_entry["size"] - 8
    chunk = decompressed[entry_start:entry_end]
    luaq_rel = chunk.find(LUAQ_SIG)
    if luaq_rel < 0:
        raise ValueError(f"No LuaQ in {script_name!r}")
    return chunk[luaq_rel:]


def inject_dlc_hook_chain_load(
    modified: bytes,
    hook_name: str,
    luac: Path,
) -> tuple[bytes, int]:
    """Preserve hook bytecode as {hook}_orig; replace hook with dlc01 + import orig.

    Returns (modified block, pandemic_hash_m2 of the _orig module for ASET).
    """
    from pandemic_hash import pandemic_hash_m2

    orig_name = f"{hook_name}_orig"
    orig_bytecode = extract_script_bytecode(modified, hook_name)
    orig_hash = pandemic_hash_m2(orig_name)
    print(
        f"  Preserving {hook_name!r} ({len(orig_bytecode):,} bytes) as {orig_name!r} "
        f"(hash 0x{orig_hash:08X})"
    )
    orig_ucfx = _build_ucfx_script_chunk(orig_name, orig_bytecode, orig_hash)
    modified = _add_ucfx_entry_to_block(modified, orig_ucfx, orig_hash)

    wrapper_bc = compile_lua_source(dlc_chain_wrapper_source(orig_name), luac)
    print(f"  Replacing {hook_name!r} with chain wrapper ({len(wrapper_bc):,} bytes)...")
    modified = apply_bytecode_replacement_to_block(modified, hook_name, wrapper_bc)
    return modified, orig_hash

# Contract names for the "Blow It Up Again" DLC pack
DLC_CONTRACT_NAMES = [
    "dlccon001",   # Merc Blitz
    "dlccon002",   # Arms Race
    "dlccon003",   # Urban Rampage
    "dlccon004a",  # Death Race (Xbox uses 'dlccon004a', NOT 'dlccon004')
]


def _build_ucfx_script_chunk(
    script_name: str,
    bytecode: bytes,
    asset_hash: int,
    type_hash: int = 0x42498680,
    field_c: int = 0,
) -> bytes:
    """Build a complete UCFX container wrapping Lua bytecode.

    Replicates the retail UCFX structure in the scripts_vz block:
      UCFX header (20 bytes): magic + u0(data_offset) + u1(body_size) + u2(0) + u3(n_desc)
      INFO descriptor (20 bytes) + body: script metadata
      DEPS descriptor (20 bytes) + body: [u8 count][u32 hash × count]
      BINN descriptor (20 bytes) + body: raw Lua 5.1 bytecode
      CSUM trailer (8 bytes)

    Retail layout verified via tools/diagnose_ucfx_headers.py and
    tools/compare_ucfx_retail_vs_injected.py.
    """
    name_bytes = script_name.encode("ascii") + b"\x00"

    # INFO body: script metadata
    info_data = struct.pack("<I", len(bytecode))
    info_data += b"\x00" * 8
    info_data += struct.pack("<B", 0x05)
    info_data += struct.pack("<H", len(script_name))
    info_data += name_bytes

    # DEPS body: u8 dep count followed by u32 hashes (none for injected scripts)
    deps_data = struct.pack("<B", 0)

    # BINN body: raw Lua 5.1 bytecode
    binn_data = bytecode

    data_area = info_data + deps_data + binn_data
    data_area_size = len(data_area)

    n_desc = 3
    data_offset = 20 + n_desc * 20

    info_offset = 0
    deps_offset = len(info_data)
    binn_offset = deps_offset + len(deps_data)

    ucfx_header = UCFX_MAGIC
    ucfx_header += struct.pack("<I", data_offset)
    ucfx_header += struct.pack("<I", data_area_size)
    ucfx_header += struct.pack("<I", 0)
    ucfx_header += struct.pack("<I", n_desc)

    info_hdr = b"INFO" + struct.pack("<IIII",
                                      info_offset, len(info_data), 0, 0)
    deps_hdr = b"DEPS" + struct.pack("<IIII",
                                      deps_offset, len(deps_data), 0, 0)
    binn_hdr = BINN_TAG + struct.pack("<IIII",
                                       binn_offset, len(binn_data), 0, 0)

    ucfx_body = ucfx_header + info_hdr + deps_hdr + binn_hdr + data_area

    csum = crc32_mercs2(ucfx_body)
    chunk = ucfx_body + CSUM_TAG + struct.pack("<I", csum)

    return chunk


def _add_ucfx_entry_to_block(
    block_data: bytes,
    new_ucfx_chunk: bytes,
    asset_hash: int,
    type_hash: int = 0x42498680,
    field_c: int = 0,
) -> bytes:
    """Append a new UCFX entry to a decompressed block.

    Updates the block header table (count + entries) and appends the
    new UCFX chunk at the end of the block data.
    """
    count = struct.unpack_from("<I", block_data, 0)[0]
    old_header_end = 4 + count * 16

    new_count = count + 1
    new_entry = struct.pack("<IIII",
                            asset_hash,
                            type_hash,
                            field_c,
                            len(new_ucfx_chunk))

    result = bytearray()
    result.extend(struct.pack("<I", new_count))
    result.extend(block_data[4:old_header_end])
    result.extend(new_entry)
    result.extend(block_data[old_header_end:])
    result.extend(new_ucfx_chunk)

    return bytes(result)


def cmd_inject_dlc_bootstrap(
    source_wad: Path,
    output: Path,
    *,
    dlc_contracts: list[str] | None = None,
    segment_size: int = 65536,
    compression_level: int = 6,
    inject_into_vz: bool = True,
) -> int:
    """Inject DLC bootstrap scripts into the scripts_vz block.

    This command performs the DLC activation by modifying the scripts_vz
    block (index 1257) in two ways:

    1. Adds a new `dlc01` UCFX entry containing the DLC master script
       that imports all DLC contracts (dlccon001-dlccon004).

    2. Modifies the `vz` master script to add `import("dlc01")` so the
       DLC bootstrap is chain-loaded at world startup.

    The modified block is packaged into a patch WAD that overlays the
    original vz.wad's scripts_vz block.
    """
    contracts = dlc_contracts or DLC_CONTRACT_NAMES
    print("DLC Bootstrap Injection")
    print("=" * 60)
    print(f"  Source WAD: {source_wad}")
    print(f"  Output:     {output}")
    print(f"  DLC contracts: {', '.join(contracts)}")
    print(f"  Inject into vz: {inject_into_vz}")

    try:
        luac = _resolve_luac()
    except FileNotFoundError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1

    print(f"  Lua compiler: {luac}")

    # Step 1: Compile the DLC master script
    print("\n[1/7] Compiling DLC master script (dlc01)...")
    if inject_into_vz:
        import_lines = "\n".join(f'    import("{c}")' for c in contracts)
        dlc01_source = f'''\
function ScriptInit()
{import_lines}
end
'''
    else:
        import_lines = "\n".join(f'import("{c}")' for c in contracts)
        dlc01_source = f'''\
{import_lines}
'''
    print(f"  Source:\n{dlc01_source}")
    dlc01_bytecode = compile_lua_source(dlc01_source, luac)

    from wad_patcher import resolve_scripts_vz_block_index

    scripts_idx = resolve_scripts_vz_block_index(source_wad)
    print(f"\n[3/7] Extracting scripts_vz block (index {scripts_idx})...")
    meta = extract_block_metadata(source_wad, scripts_idx)
    print(f"  INDX entry: page={meta['indx_entry']['page_index']}, "
          f"packed={meta['indx_entry']['packed_field']}")
    print(f"  ASET entries: {meta['aset_entry_count']}")
    print(f"  PTHS: {meta['pths_string']}")
    print(f"  Compressed size: {meta['block_compressed_size']:,} bytes")

    print("\n[4/7] Decompressing scripts_vz block...")
    compressed_data = meta["compressed_block_data"]
    decompressed = decompress_sges_block(
        compressed_data, 0, len(compressed_data)
    )
    print(f"  Decompressed: {len(decompressed):,} bytes")

    entries = parse_block_entries(decompressed)
    print(f"  UCFX entries: {len(entries)}")

    hook = find_dlc_bootstrap_hook_script(decompressed, entries) if inject_into_vz else None
    hook_name = hook[0] if hook else None
    if inject_into_vz and hook is None:
        print(
            "  NOTE: No hook script (vz / wifmissionflow / wifpmcinterior) in scripts_vz.",
            file=sys.stderr,
        )
        print(
            "  Continuing with dlc01 entry only (use ASI or verify_patch_dlc_hook.py).",
            file=sys.stderr,
        )
        inject_into_vz = False
    elif hook_name is not None:
        _, hook_entry = hook
        print(f"\n  Bootstrap hook script: {hook_name!r}")
        print(f"    Index: {hook_entry['index']}")
        print(f"    Hash:  0x{hook_entry['hash']:08X}")
        print(f"    Size:  {hook_entry['size']:,} bytes")

    # Step 5: Build the dlc01 UCFX chunk
    print("\n[5/7] Building dlc01 UCFX container...")
    from pandemic_hash import pandemic_hash_m2
    dlc01_asset_hash = pandemic_hash_m2("dlc01")
    print(f"  dlc01 asset hash: 0x{dlc01_asset_hash:08X}")

    dlc01_ucfx = _build_ucfx_script_chunk(
        "dlc01",
        dlc01_bytecode,
        dlc01_asset_hash,
    )
    print(f"  dlc01 UCFX size: {len(dlc01_ucfx):,} bytes")

    # Step 6: Modify the block
    print("\n[6/7] Modifying scripts_vz block...")
    modified = decompressed

    hook_orig_hash: int | None = None

    # Add the dlc01 entry to the block
    print("  Adding dlc01 UCFX entry to block...")
    modified = _add_ucfx_entry_to_block(
        modified,
        dlc01_ucfx,
        dlc01_asset_hash,
    )
    new_entries = parse_block_entries(modified)
    print(f"  Block now has {len(new_entries)} UCFX entries (was {len(entries)})")
    print(f"  Modified block: {len(modified):,} bytes (delta {len(modified) - len(decompressed):+,})")

    if inject_into_vz and hook_name is not None:
        modified, hook_orig_hash = inject_dlc_hook_chain_load(
            modified, hook_name, luac
        )

    # Step 7: Recompress and build patch WAD
    print("\n[7/7] Recompressing and building patch WAD...")
    new_sges = compress_sges(
        modified,
        segment_size=segment_size,
        level=compression_level,
        major=4,
    )
    ratio = len(new_sges) / len(modified) * 100
    print(f"  Compressed: {len(new_sges):,} bytes ({ratio:.1f}%)")

    verify = decompress_sges_block(new_sges, 0, len(new_sges))
    if verify != modified:
        print("ERROR: Roundtrip verification failed!", file=sys.stderr)
        return 1
    print("  Roundtrip verification OK")

    # Update ASET entries to include dlc01 (+ preserved hook _orig when chain-loaded)
    aset_entries = list(meta["aset_entries"])
    aset_entries.append(script_aset_entry(dlc01_asset_hash))
    if hook_orig_hash is not None:
        aset_entries.append(script_aset_entry(hook_orig_hash))

    patch_wad = build_patch_wad(
        indx_entry=meta["indx_entry"],
        aset_entries=aset_entries,
        pths_string=meta["pths_string"],
        compressed_block=new_sges,
        csum_value=meta["csum_value"],
    )

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(patch_wad)
    print(f"\n  Wrote: {output} ({len(patch_wad):,} bytes)")
    print(f"  DATA offset: 0x208000")
    print(f"  Block pages: {_align_up(len(new_sges), PAGE_SIZE) // PAGE_SIZE}")

    print(f"\n{'=' * 60}")
    print("DLC Bootstrap Injection Complete")
    print(f"{'=' * 60}")
    print(f"\nWhat was done:")
    print(f"  1. Compiled dlc01 master script ({len(dlc01_bytecode):,} bytes bytecode)")
    print(f"     - Imports: {', '.join(contracts)}")
    if inject_into_vz:
        print(f"  2. Modified vz master script to import dlc01")
    print(f"  3. Added dlc01 as new UCFX entry (hash 0x{dlc01_asset_hash:08X})")
    print(f"  4. Recompressed and packaged into patch WAD")
    print(f"\nTo use:")
    print(f"  Copy {output} to the game's data/ directory alongside vz.wad")
    print(f"\nKnown limitations:")
    print(f"  - DLC contract scripts (dlccon001-004) must already exist in the")
    print(f"    patch WAD from the Xbox 360 DLC port (dlc_port.py)")
    print(f"  - DLC Lua bytecode may need endian-swap (BE→LE) if not already done")
    print(f"  - DLC meshes need STRM vertex byte-swap for correct rendering")
    if inject_into_vz:
        print(f"  - The vz master script was replaced with a minimal wrapper;")
        print(f"    the original vz logic loads from the base vz.wad")

    return 0


def cmd_inject_dlc_bootstrap_merged(
    source_wad: Path,
    existing_patch_wad: Path,
    output: Path,
    *,
    dlc_contracts: list[str] | None = None,
    segment_size: int = 65536,
    compression_level: int = 6,
) -> int:
    """Inject DLC bootstrap into an EXISTING patch WAD (e.g., one from dlc_port.py).

    This merges the bootstrap scripts into a patch WAD that already contains
    DLC asset blocks from the Xbox 360 port, replacing the scripts_vz block.
    """
    from ffcs_patch_wad import PatchBlock, merge_patch_wads, read_patch_wad

    contracts = dlc_contracts or DLC_CONTRACT_NAMES
    print("DLC Bootstrap Injection (Merge Mode)")
    print("=" * 60)
    print(f"  Source WAD:   {source_wad}")
    print(f"  Patch WAD:    {existing_patch_wad}")
    print(f"  Output:       {output}")
    print(f"  DLC contracts: {', '.join(contracts)}")

    try:
        luac = _resolve_luac()
    except FileNotFoundError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1

    # Compile DLC scripts
    print("\n[1/5] Compiling DLC scripts...")
    import_lines = "\n".join(f'    import("{c}")' for c in contracts)
    dlc01_source = f'''\
function ScriptInit()
{import_lines}
end
'''
    dlc01_bytecode = compile_lua_source(dlc01_source, luac)

    # Extract and modify scripts_vz block
    print("\n[2/5] Extracting and modifying scripts_vz block...")
    from wad_patcher import resolve_scripts_vz_block_index

    scripts_idx = resolve_scripts_vz_block_index(source_wad)
    meta = extract_block_metadata(source_wad, scripts_idx)

    compressed_data = meta["compressed_block_data"]
    decompressed = decompress_sges_block(
        compressed_data, 0, len(compressed_data)
    )

    from pandemic_hash import pandemic_hash_m2
    dlc01_asset_hash = pandemic_hash_m2("dlc01")

    dlc01_ucfx = _build_ucfx_script_chunk(
        "dlc01",
        dlc01_bytecode,
        dlc01_asset_hash,
    )

    modified = _add_ucfx_entry_to_block(
        decompressed,
        dlc01_ucfx,
        dlc01_asset_hash,
    )

    entries = parse_block_entries(modified)
    hook = find_dlc_bootstrap_hook_script(modified, entries)
    hook_orig_hash: int | None = None
    if hook is not None:
        hook_name, _ = hook
        modified, hook_orig_hash = inject_dlc_hook_chain_load(
            modified, hook_name, luac
        )
    else:
        print(
            "  NOTE: No hook script (vz / wifmissionflow / wifpmcinterior); dlc01 only.",
            file=sys.stderr,
        )

    # Recompress
    print("\n[3/5] Recompressing scripts_vz block...")
    new_sges = compress_sges(
        modified,
        segment_size=segment_size,
        level=compression_level,
        major=4,
    )

    verify = decompress_sges_block(new_sges, 0, len(new_sges))
    if verify != modified:
        print("ERROR: Roundtrip verification failed!", file=sys.stderr)
        return 1

    # Build a PatchBlock for scripts_vz
    aset_entries = list(meta["aset_entries"])
    aset_entries.append(script_aset_entry(dlc01_asset_hash))
    if hook_orig_hash is not None:
        aset_entries.append(script_aset_entry(hook_orig_hash))

    scripts_block = PatchBlock(
        compressed_data=new_sges,
        path_string=meta["pths_string"],
        aset_entries=aset_entries,
        packed_field=meta["indx_entry"].get("packed_field", 1),
        flags=meta["indx_entry"].get("flags", 0x8000),
    )

    # Merge into existing patch WAD
    print("\n[4/5] Merging into existing patch WAD...")
    merged_wad = merge_patch_wads(
        existing_patch_wad,
        [scripts_block],
        replace=True,
    )

    print(f"\n[5/5] Writing merged patch WAD...")
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(merged_wad)
    print(f"  Wrote: {output} ({len(merged_wad):,} bytes)")

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
    ap.add_argument("--block-index", type=int, default=None,
                    help="scripts_vz block index (default: auto-detect from PTHS, retail=3197)")
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
    ap.add_argument("--inject-dlc-bootstrap", action="store_true",
                    help="Inject DLC bootstrap scripts into the scripts_vz block. "
                         "Compiles a dlc01 master script that imports DLC contracts "
                         "(dlccon001-004), adds it as a new UCFX entry, and modifies "
                         "the vz master script to chain-load it. Builds a standalone "
                         "patch WAD.")
    ap.add_argument("--inject-dlc-bootstrap-merge", action="store_true",
                    help="Like --inject-dlc-bootstrap but merges the scripts_vz "
                         "block into an EXISTING patch WAD (e.g., from dlc_port.py). "
                         "Requires --merge-from for the existing patch WAD path.")
    ap.add_argument("--merge-from", type=Path,
                    help="Existing patch WAD to merge into (for --inject-dlc-bootstrap-merge)")
    ap.add_argument("--dlc-contracts", type=str,
                    help="Comma-separated list of DLC contract names to import "
                         "(default: dlccon001,dlccon002,dlccon003,dlccon004)")
    ap.add_argument("--no-vz-inject", action="store_true",
                    help="Skip modifying the vz master script (only add dlc01 "
                         "UCFX entry). Use this if you plan to trigger DLC loading "
                         "via another mechanism.")

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
        block_index = args.block_index
        if block_index is None:
            from wad_patcher import resolve_scripts_vz_block_index
            block_index = resolve_scripts_vz_block_index(args.source_wad)
        return cmd_analyze_block(args.source_wad, block_index, args.output)

    if args.inject_dlc_bootstrap:
        if args.source_wad is None:
            ap.error("--inject-dlc-bootstrap requires --source-wad")
        if args.output is None:
            ap.error("--inject-dlc-bootstrap requires --output")
        dlc_contracts = None
        if args.dlc_contracts:
            dlc_contracts = [c.strip() for c in args.dlc_contracts.split(",")]
        return cmd_inject_dlc_bootstrap(
            args.source_wad,
            args.output,
            dlc_contracts=dlc_contracts,
            segment_size=args.segment_size,
            compression_level=args.compression_level,
            inject_into_vz=not args.no_vz_inject,
        )

    if args.inject_dlc_bootstrap_merge:
        if args.source_wad is None:
            ap.error("--inject-dlc-bootstrap-merge requires --source-wad")
        if args.merge_from is None:
            ap.error("--inject-dlc-bootstrap-merge requires --merge-from")
        if args.output is None:
            ap.error("--inject-dlc-bootstrap-merge requires --output")
        dlc_contracts = None
        if args.dlc_contracts:
            dlc_contracts = [c.strip() for c in args.dlc_contracts.split(",")]
        return cmd_inject_dlc_bootstrap_merged(
            args.source_wad,
            args.merge_from,
            args.output,
            dlc_contracts=dlc_contracts,
            segment_size=args.segment_size,
            compression_level=args.compression_level,
        )

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
