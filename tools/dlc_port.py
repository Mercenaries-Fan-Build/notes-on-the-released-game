#!/usr/bin/env python3
"""Unified DLC porter — Xbox 360 DLC to PC ``vz-patch.wad``.

Replaces both ``port_xbox_dlc.py`` and ``dlc_port_x360_to_pc.py`` with a
single CLI that uses shared modules:
  - x360_dlc_io: STFS I/O, BE sges decompression, FFCS parsing
  - ucfx_byteswap (Rust): UCFX byte-swap (BE → LE)
  - ffcs_patch_wad: patch WAD assembly + merge

The ``--source-wad`` option enables integrated DLC bootstrap injection:
the tool extracts the ``scripts_vz`` block from the retail WAD, adds the
``dlc01`` master script, and modifies the ``vz`` master script to chain-load
it — producing a single complete ``vz-patch.wad`` with no separate merge step.

Usage:
  # Full pipeline (DLC port + bootstrap injection in one command):
  python3 tools/dlc_port.py --x360-rar Mercenaries.2.World.In.Flames.DLC.RF.X360-ZTM.rar \\
      --source-wad path/to/vz.wad \\
      --output vz-patch.wad

  # From Xbox 360 DLC RAR (without bootstrap):
  python3 tools/dlc_port.py --x360-rar Mercenaries.2.World.In.Flames.DLC.RF.X360-ZTM.rar \\
      --output vz-patch.wad

  # From pre-extracted STFS container or raw DLC01.doh:
  python3 tools/dlc_port.py --x360-stfs /path/to/stfs_file \\
      --output vz-patch.wad

  # Merge DLC into an existing mod patch WAD:
  python3 tools/dlc_port.py --x360-rar DLC.rar \\
      --merge-into data/vz-patch.wad \\
      --output data/vz-patch.wad

  # List blocks only:
  python3 tools/dlc_port.py --x360-stfs /path/to/stfs --list-blocks
"""
from __future__ import annotations

import argparse
import os
import struct
import sys
import tempfile
import time
from concurrent.futures import ProcessPoolExecutor, as_completed
from dataclasses import dataclass, field
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from ffcs_patch_wad import (  # noqa: E402
    PatchBlock,
    build_patch_wad_multi,
    merge_patch_wads,
)
from sges_compress import compress_sges  # noqa: E402
from ucfx_byteswap_wrapper import byteswap_block_rust  # noqa: E402
from x360_dlc_io import (  # noqa: E402
    PAGE_SIZE,
    StfsReader,
    decompress_be_sges,
    extract_stfs_from_rar,
    load_stfs_or_doh,
    parse_be_aset,
    parse_be_ffcs,
    parse_be_indx,
    parse_be_pths,
)

from build_patch_wad import (  # noqa: E402
    _build_ucfx_script_chunk,
    _add_ucfx_entry_to_block,
    compile_lua_source,
    extract_block_metadata,
    inject_dlc_hook_chain_load,
    DLC_CONTRACT_NAMES,
)
from pandemic_hash import pandemic_hash_m2  # noqa: E402
from sges_decompress import decompress_sges_block  # noqa: E402
from wad_patcher import (  # noqa: E402
    find_dlc_bootstrap_hook_script,
    get_binn_script_ref_name,
    get_script_name,
    parse_block_entries,
    resolve_scripts_vz_block_index,
    script_aset_entry,
)
from dlc_aset_normalize import (  # noqa: E402
    dedupe_asset_hash_across_blocks,
    ensure_contract_aset_from_xbox_block_aset,
    ensure_contract_aset_on_resident_block,
    ensure_import_chain_script_aset,
    find_dlc_script_resident_block_index,
    is_dlc_script_resident_path,
    normalize_all_block_asets,
)
from aset_type_ids import (  # noqa: E402
    SCRIPT_ASET_TYPE_ID,
    SCRIPT_TYPE_HASH,
    STRINGDB_ASET_TYPE_ID,
    STRINGDB_TYPE_HASH,
    type_id_for_type_hash,
)
from audio_codec_policy import CODEC_XBOX_ADPCM  # noqa: E402
from pws_xbox_to_pc import transcode_pws_file_to_pc  # noqa: E402


_CRC32_TABLE: list[int] = []
for _i in range(256):
    _c = _i
    for _ in range(8):
        _c = (_c >> 1) ^ 0xEDB88320 if _c & 1 else _c >> 1
    _CRC32_TABLE.append(_c)


def _crc32_mercs2(data: bytes) -> int:
    """CRC-32 matching the game's per-UCFX CSUM trailer (init=0, no final XOR)."""
    crc = 0
    for b in data:
        crc = _CRC32_TABLE[(crc ^ b) & 0xFF] ^ (crc >> 8)
    return crc & 0xFFFFFFFF


# ── Type hashes for base-game override (platform-specific formats) ───
_ANIMATION_TYPE_HASH = 0x18166555  # pandemic_hash_m2("animation")
_TEXTURE_TYPE_HASH = 0xF011157A    # pandemic_hash_m2("texture")
_MESH_B_TYPE_HASH = 0x5B724250
_STANCE_TYPE_HASH = 0x207359C7
_UNKNOWN_E5_TYPE_HASH = 0xE5273C14
_SOUNDBANK_TYPE_HASH = 0x9F8BCA10   # pandemic_hash_m2("soundbank")
_WAVEBANK_TYPE_HASH = 0xF753F6D0    # pandemic_hash_m2("wavebank")

_OVERRIDE_TYPE_HASHES = frozenset((
    _ANIMATION_TYPE_HASH,
    _TEXTURE_TYPE_HASH,
    _MESH_B_TYPE_HASH,
    _STANCE_TYPE_HASH,
    _UNKNOWN_E5_TYPE_HASH,  # audio group graph — Xbox DLC differs from PC retail
    _SOUNDBANK_TYPE_HASH,   # soundbank header has mixed u16/u8 fields
    _WAVEBANK_TYPE_HASH,    # wavebank data includes embedded audio clips
))

# Havok magic used to confirm an entry's data body contains Havok
_HAVOK_MAGIC = b"\x57\xe0\xe0\x57\x10\xc0\xc0\x10"


# ── Base game Havok data extraction ──────────────────────────────────

def _build_base_aset_index(source_wad: Path) -> dict[tuple[int, int], int]:
    """Build (hash, type_id)→block_index lookup from the base game's ASET table.

    Keys on (asset_hash, type_id) to disambiguate assets that share a hash
    but exist under different types (e.g. texture vs mesh).
    """
    from ffcs_wad import parse_ffcs, extract_slice
    raw = source_wad.read_bytes()
    arch = parse_ffcs(source_wad)
    aset_chunk = next((c for c in arch.chunks if c.tag == "ASET"), None)
    if aset_chunk is None:
        return {}
    aset_data = extract_slice(raw, aset_chunk)
    num_entries = aset_chunk.meta

    index: dict[tuple[int, int], int] = {}
    for i in range(num_entries):
        off = i * 16
        if off + 16 > len(aset_data):
            break
        asset_hash, _u1, u2, type_id = struct.unpack_from("<IIII", aset_data, off)
        block_idx = (u2 >> 16) & 0xFFFF
        if block_idx != 0xFFFF and asset_hash != 0:
            index[(asset_hash, type_id)] = block_idx
    return index


def _extract_base_entry_ucfx(
    source_wad: Path,
    block_index: int,
    target_hash: int,
    target_type_hash: int,
    *,
    _block_cache: dict[int, bytes] | None = None,
) -> bytes | None:
    """Extract a specific entry's UCFX container (LE, without CSUM) from vz.wad.

    Matches on both hash and type_hash to avoid pulling the wrong asset type
    when a block contains entries with the same hash under different types.
    Returns the raw UCFX bytes (sans CSUM trailer) or None if not found.
    """
    import mmap as mmap_mod
    from ffcs_wad import parse_ffcs, extract_slice
    from wad_patcher import get_block_boundaries

    # Use cache to avoid redundant decompression
    if _block_cache is not None and block_index in _block_cache:
        decompressed = _block_cache[block_index]
    else:
        raw = source_wad.read_bytes()
        arch = parse_ffcs(source_wad)
        data_chunk = next((c for c in arch.chunks if c.tag == "DATA"), None)
        if data_chunk is None:
            return None
        with open(source_wad, "rb") as f:
            mm = mmap_mod.mmap(f.fileno(), 0, access=mmap_mod.ACCESS_READ)
        try:
            boundaries = get_block_boundaries(mm, data_chunk.offset, data_chunk.size)
            if block_index >= len(boundaries):
                return None
            blk_start, blk_end = boundaries[block_index]
            compressed = bytes(mm[blk_start:blk_end])
        finally:
            mm.close()

        decompressed = decompress_sges_block(compressed, 0, len(compressed))
        if _block_cache is not None:
            _block_cache[block_index] = decompressed

    # Parse LE entry table
    if len(decompressed) < 4:
        return None
    count = struct.unpack_from("<I", decompressed, 0)[0]
    if count > 50_000:
        return None

    header_end = 4 + count * 16
    pos = header_end
    for i in range(count):
        eoff = 4 + i * 16
        h, th, _fc, s = struct.unpack_from("<IIII", decompressed, eoff)
        entry_end = pos + s
        if h == target_hash and th == target_type_hash:
            container = decompressed[pos:entry_end]
            # Strip CSUM trailer if present
            if len(container) >= 8 and container[-8:-4] == b"CSUM":
                return container[:-8]
            return container
        pos = entry_end

    return None

_STRINGDB_TYPE_HASH = 0x39E5E978  # pandemic_hash_m2("stringdb")

def _fix_stringdb_descriptors(block_data: bytes) -> bytes:
    """Ensure SYEK/SRTS chunk descriptor u32s are little-endian.

    Xbox 360 DLC stringdb UCFX blocks may have chunk descriptor values
    that remain in big-endian order after the generic byte-swap pass.
    The body data is natively BE on all platforms (the PC engine reads
    it as BE), but the descriptor fields (body_offset, body_size, u2, u3)
    must be LE for the PC engine to locate the body within the UCFX.

    Detects mismatched descriptors by checking whether the LE-interpreted
    body_offset + body_size would exceed the UCFX container, and swaps
    if the BE interpretation yields sane values instead.
    """
    data = bytearray(block_data)
    count = struct.unpack_from("<I", data, 0)[0]
    if count < 1 or count > 5000:
        return bytes(data)

    header_end = 4 + count * 16

    # Check each UCFX entry's type_hash to find stringdb blocks
    for i in range(count):
        eoff = 4 + i * 16
        type_hash = struct.unpack_from("<I", data, eoff + 4)[0]
        if type_hash != _STRINGDB_TYPE_HASH:
            continue
        chunk_size = struct.unpack_from("<I", data, eoff + 12)[0]

        # Find the UCFX container for this entry
        ucfx_off = header_end
        for j in range(i):
            ucfx_off += struct.unpack_from("<I", data, 4 + j * 16 + 12)[0]

        if ucfx_off + 8 > len(data):
            continue
        if data[ucfx_off:ucfx_off + 4] != b"UCFX":
            continue

        ucfx_u0 = struct.unpack_from("<I", data, ucfx_off + 4)[0]
        if ucfx_u0 == 0 or ucfx_u0 > chunk_size:
            continue
        data_base = ucfx_off + ucfx_u0
        ucfx_end = ucfx_off + chunk_size

        # Scan chunk descriptor rows between ucfx_off+8 and data_base
        # for SYEK/SRTS tags whose descriptor values look like BE
        fixed = False
        pos = ucfx_off + 8
        while pos + 20 <= data_base:
            tag = bytes(data[pos:pos + 4])
            if tag in (b"SYEK", b"SRTS"):
                # Read descriptor values as LE
                v0_le = struct.unpack_from("<I", data, pos + 4)[0]
                v1_le = struct.unpack_from("<I", data, pos + 8)[0]
                # Read as BE for comparison
                v0_be = struct.unpack_from(">I", data, pos + 4)[0]
                v1_be = struct.unpack_from(">I", data, pos + 8)[0]

                # Heuristic: if LE body_offset is unreasonably large but
                # BE interpretation is within the container, the values
                # are still BE and need swapping.
                container_body_size = ucfx_end - data_base
                le_sane = (v0_le < container_body_size and
                           v1_le < container_body_size)
                be_sane = (v0_be < container_body_size and
                           v1_be < container_body_size)

                if not le_sane and be_sane:
                    # Swap the 4 descriptor u32s from BE to LE
                    for k in range(4):
                        off = pos + 4 + k * 4
                        struct.pack_into(
                            "<I", data, off, struct.unpack_from(">I", data, off)[0],
                        )
                    fixed = True
                pos += 20
            elif tag in (b"INFO", b"CSUM"):
                pos += 20 if tag != b"CSUM" else 8
            else:
                pos += 1

        # Recompute CSUM trailer if descriptors were fixed.
        # Game uses CRC-32 (reflected poly 0xEDB88320, init=0, no final XOR).
        if fixed:
            csum_pos = ucfx_off + chunk_size - 8
            if (csum_pos >= ucfx_off and csum_pos + 8 <= len(data)
                    and data[csum_pos:csum_pos + 4] == b"CSUM"):
                ucfx_body = bytes(data[ucfx_off:csum_pos])
                new_crc = _crc32_mercs2(ucfx_body)
                struct.pack_into("<I", data, csum_pos + 4, new_crc)

    return bytes(data)


def _apply_overrides_and_strips(
    le_block: bytes,
    base_overrides: dict[int, bytes] | None,
    strip_hashes: frozenset[int] | None,
) -> tuple[bytes, int]:
    """Apply entry-level overrides and type_hash stripping to an LE block.

    - base_overrides: maps entry index → LE UCFX container bytes (no CSUM).
      Replaces the Rust-converted container with the pre-converted PC version.
    - strip_hashes: type_hashes to remove from the block entirely.

    Returns (modified_block, stripped_count).
    """
    if not base_overrides and not strip_hashes:
        return le_block, 0
    if len(le_block) < 4:
        return le_block, 0

    entry_count = struct.unpack_from("<I", le_block, 0)[0]
    header_size = 4 + entry_count * 16
    if header_size > len(le_block):
        return le_block, 0

    entries: list[tuple[int, int, int, int]] = []
    for i in range(entry_count):
        off = 4 + i * 16
        h, t, o, s = struct.unpack_from("<IIII", le_block, off)
        entries.append((h, t, o, s))

    # Walk containers — chunk_size includes CSUM trailer (PC format).
    pos = header_size
    kept: list[tuple[int, int, bytes]] = []  # (name_hash, type_hash, full_chunk_with_csum)
    for ei, (h, t, o, s) in enumerate(entries):
        chunk_size = s
        container_end = pos + chunk_size
        if container_end > len(le_block):
            chunk_data = le_block[pos:]
        else:
            chunk_data = le_block[pos:container_end]
        pos = container_end

        # Strip?
        if strip_hashes and t in strip_hashes and (
            base_overrides is None or ei not in base_overrides
        ):
            continue

        # Override?
        if base_overrides and ei in base_overrides:
            ucfx_le = base_overrides[ei]
            csum_val = _crc32_mercs2(ucfx_le)
            full_chunk = ucfx_le + b"CSUM" + struct.pack("<I", csum_val)
            kept.append((h, t, full_chunk))
        else:
            kept.append((h, t, bytes(chunk_data)))

    # Rebuild block: field_c is always 0 (engine walks sequentially via chunk_size).
    out = struct.pack("<I", len(kept))
    for h, t, full_chunk in kept:
        chunk_sz = len(full_chunk)
        out += struct.pack("<IIII", h, t, 0, chunk_sz)
    for _, _, full_chunk in kept:
        out += full_chunk

    stripped_count = entry_count - len(kept)
    return out, stripped_count


# ── Parallel block processing ─────────────────────────────────────────

@dataclass
class _BlockWorkerArgs:
    """Picklable per-block inputs for ProcessPoolExecutor workers."""

    blk_idx: int
    path: str
    doh_slice: bytes
    block_asets: list[dict]
    packed_field: int
    flags: int
    base_anim_index: dict[tuple[int, int], int]
    source_wad_path: str | None
    fix_stringdb_descriptors: bool
    dump_dir_path: str | None
    verbose: bool
    collect_hashes: bool
    permissive: bool = False
    strip_audio: bool = False


@dataclass
class _BlockWorkerResult:
    """Picklable per-block output from a worker."""

    blk_idx: int
    skipped: bool = False
    skip_reason: str = ""
    patch_block: PatchBlock | None = None
    hash_entries: list[int] = field(default_factory=list)
    tags_seen: dict[str, int] = field(default_factory=dict)
    override_msg: str = ""


def _process_one_block(args: _BlockWorkerArgs) -> _BlockWorkerResult:
    """Decompress, byte-swap, and recompress one DLC block (worker entry point)."""
    blk_idx = args.blk_idx
    doh_slice = args.doh_slice

    if len(doh_slice) < 4:
        return _BlockWorkerResult(
            blk_idx=blk_idx,
            skipped=True,
            skip_reason="block slice too short",
        )

    magic = doh_slice[:4]

    if magic == b"segs":
        try:
            decompressed = decompress_be_sges(doh_slice, 0, len(doh_slice))
        except Exception as e:
            return _BlockWorkerResult(
                blk_idx=blk_idx,
                skipped=True,
                skip_reason=f"decompress failed: {e}",
            )
    else:
        rec_count_be = struct.unpack_from(">I", doh_slice, 0)[0]
        header_end = 4 + rec_count_be * 16
        first_container_tag = (
            doh_slice[header_end:header_end + 4]
            if header_end + 4 <= len(doh_slice)
            else b""
        )
        if rec_count_be > 0 and rec_count_be < 5000 and first_container_tag == b"XFCU":
            decompressed = bytes(doh_slice)
            actual_end = len(decompressed)
            while actual_end > 4 and decompressed[actual_end - 1] == 0:
                actual_end -= 1
            actual_end = (actual_end + 3) & ~3
            decompressed = decompressed[:actual_end]
        else:
            return _BlockWorkerResult(
                blk_idx=blk_idx,
                skipped=True,
                skip_reason=(
                    f"no segs magic (got {magic!r}, rec_count={rec_count_be}, "
                    f"first_tag={first_container_tag!r})"
                ),
            )

    dump_dir = Path(args.dump_dir_path) if args.dump_dir_path else None
    if dump_dir:
        dump_dir.mkdir(parents=True, exist_ok=True)
        (dump_dir / f"block_{blk_idx:04d}_be.bin").write_bytes(decompressed)

    base_overrides: dict[int, bytes] | None = None
    override_msg = ""
    base_block_cache: dict[int, bytes] = {}
    source_wad = Path(args.source_wad_path) if args.source_wad_path else None

    if args.base_anim_index and source_wad:
        from ucfx_be_to_le import _parse_entry_table_be
        from aset_type_ids import type_id_for_type_hash

        override_all = is_dlc_script_resident_path(args.path)

        be_entries = _parse_entry_table_be(decompressed)
        override_counts: dict[int, int] = {}
        for eidx, (ehash, etype, _eoff, _esize) in enumerate(be_entries):
            if override_all or etype in _OVERRIDE_TYPE_HASHES:
                tid = type_id_for_type_hash(etype)
                if tid is not None and (ehash, tid) in args.base_anim_index:
                    base_blk = args.base_anim_index[(ehash, tid)]
                    le_ucfx = _extract_base_entry_ucfx(
                        source_wad,
                        base_blk,
                        ehash,
                        etype,
                        _block_cache=base_block_cache,
                    )
                    if le_ucfx is not None:
                        if base_overrides is None:
                            base_overrides = {}
                        base_overrides[eidx] = le_ucfx
                        override_counts[etype] = override_counts.get(etype, 0) + 1

        if override_all:
            not_overridden = [
                (eidx, ehash, etype)
                for eidx, (ehash, etype, _, _) in enumerate(be_entries)
                if base_overrides is None or eidx not in base_overrides
            ]
            if not_overridden and base_block_cache:
                for base_blk_idx in list(base_block_cache.keys()):
                    still_missing = not_overridden[:]
                    for eidx, ehash, etype in still_missing:
                        le_ucfx = _extract_base_entry_ucfx(
                            source_wad,
                            base_blk_idx,
                            ehash,
                            etype,
                            _block_cache=base_block_cache,
                        )
                        if le_ucfx is not None:
                            if base_overrides is None:
                                base_overrides = {}
                            base_overrides[eidx] = le_ucfx
                            override_counts[etype] = (
                                override_counts.get(etype, 0) + 1
                            )
                            not_overridden.remove((eidx, ehash, etype))
                    if not not_overridden:
                        break

        if base_overrides:
            _override_labels = {
                _ANIMATION_TYPE_HASH: "Havok",
                _TEXTURE_TYPE_HASH: "texture",
                _MESH_B_TYPE_HASH: "mesh_B",
                _STANCE_TYPE_HASH: "stance",
                _UNKNOWN_E5_TYPE_HASH: "unknown_E5",
                _SOUNDBANK_TYPE_HASH: "soundbank",
                _WAVEBANK_TYPE_HASH: "wavebank",
            }
            if override_all:
                non_labeled = sum(
                    c for t, c in override_counts.items()
                    if t not in _override_labels
                )
                parts = [
                    f"{override_counts[th]} {_override_labels[th]}"
                    for th in _OVERRIDE_TYPE_HASHES
                    if override_counts.get(th)
                ]
                if non_labeled:
                    parts.append(f"{non_labeled} resident-shared")
                override_msg = " + ".join(parts) + " override(s) from base game"
            else:
                parts = [
                    f"{override_counts[th]} {_override_labels[th]}"
                    for th in _OVERRIDE_TYPE_HASHES
                    if override_counts.get(th)
                ]
                override_msg = " + ".join(parts) + " override(s) from base game"

    strip_hashes: frozenset[int] | None = None
    if args.strip_audio:
        strip_hashes = frozenset({_SOUNDBANK_TYPE_HASH, _WAVEBANK_TYPE_HASH})

    try:
        swapped = byteswap_block_rust(decompressed)
        stats: dict = {
            "ucfx_found": 0, "chunks_swapped": 0, "csum_swapped": 0,
            "tags_seen": {}, "errors": [],
            "fallback_u32_count": 0, "fallback_u32_tags": {},
        }
    except (RuntimeError, FileNotFoundError) as e:
        return _BlockWorkerResult(
            blk_idx=blk_idx,
            skipped=True,
            skip_reason=f"byte-swap failed: {e}",
        )

    # Post-processing: apply base_overrides and strip_hashes on the LE output
    if base_overrides or strip_hashes:
        swapped, stripped_count = _apply_overrides_and_strips(
            swapped, base_overrides, strip_hashes,
        )
        if base_overrides:
            stats["overrides_applied"] = len(base_overrides)
        stats["stripped_count"] = stripped_count

    stripped_count = stats.get("stripped_count", 0)
    if stripped_count:
        strip_msg = f"{stripped_count} audio entry(ies) stripped"
        override_msg = f"{override_msg}; {strip_msg}" if override_msg else strip_msg

    if args.fix_stringdb_descriptors:
        swapped = _fix_stringdb_descriptors(swapped)

    if dump_dir:
        (dump_dir / f"block_{blk_idx:04d}_le.bin").write_bytes(swapped)

    hash_entries: list[int] = []
    if args.collect_hashes:
        try:
            entries = parse_block_entries(swapped)
            for entry in entries:
                h = entry.get("hash")
                if h is not None and h != 0:
                    hash_entries.append(h)
        except Exception:
            pass

    pc_sges = compress_sges(swapped, segment_size=65536, level=6, major=4)

    roundtrip = decompress_sges_block(pc_sges, 0, len(pc_sges))
    if roundtrip != swapped:
        raise RuntimeError(
            f"Block {blk_idx} ({args.path}): sges round-trip mismatch — "
            f"expected {len(swapped)} bytes, got {len(roundtrip)}"
        )

    # Recompute packed_field: the decompressed size may differ after byte-swap
    # + base-game overrides.  packed_field encodes (tier << 24) | decomp_pages
    # where decomp_pages = ceil(decompressed_size / PAGE_SIZE).  Using the
    # Xbox value after size changes causes a heap buffer overflow in the engine.
    xbox_tier = (args.packed_field >> 24) & 0xFF
    correct_pages = (len(swapped) + 0x7FFF) // 0x8000
    recomputed_packed = (xbox_tier << 24) | correct_pages

    return _BlockWorkerResult(
        blk_idx=blk_idx,
        skipped=False,
        patch_block=PatchBlock(
            compressed_data=pc_sges,
            path_string=args.path,
            aset_entries=list(args.block_asets),
            packed_field=recomputed_packed,
            flags=args.flags,
        ),
        hash_entries=hash_entries,
        tags_seen=dict(stats.get("tags_seen", {})),
        override_msg=override_msg,
    )


def _collect_block_results(
    results: list[_BlockWorkerResult],
    *,
    verbose: bool,
) -> tuple[list[PatchBlock], int, dict[str, int], dict[int, int]]:
    """Merge worker results in block-index order into converted[] and hash map."""
    results.sort(key=lambda r: r.blk_idx)
    converted: list[PatchBlock] = []
    skipped = 0
    total_swap_stats: dict[str, int] = {}
    hash_to_local_block: dict[int, int] = {}

    for res in results:
        if res.skipped:
            skipped += 1
            continue
        if res.override_msg and verbose:
            print(f"  [{res.blk_idx}] → {res.override_msg}")
        for tag, cnt in res.tags_seen.items():
            total_swap_stats[tag] = total_swap_stats.get(tag, 0) + cnt
        for h in res.hash_entries:
            hash_to_local_block[h] = len(converted)
        if res.patch_block is not None:
            converted.append(res.patch_block)

    return converted, skipped, total_swap_stats, hash_to_local_block


# ── ASET sub-entry sanitization ───────────────────────────────────────

def _fix_xbox_aset_sub_entry(u2: int) -> int:
    """Sanitize Xbox ASET packed_block_ref low16 field.

    In the base game, packed_block_ref (u2) = (block_index << 16) | sub_entry,
    where sub_entry = 0xFFFF means "primary" (the asset IS the block's main
    entry).  Xbox 360 DLC duplicates the block index into the low16 field,
    causing heap corruption when the PC engine uses the bogus sub-entry offset
    to index into a block's entry table.

    Returns u2 with a corrected low16: 0xFFFF (primary) unless the low16 is
    already a plausible sub-entry offset distinct from the block index.
    """
    high16 = (u2 >> 16) & 0xFFFF
    low16 = u2 & 0xFFFF
    if low16 == 0xFFFF:
        return u2
    if low16 == high16:
        return (high16 << 16) | 0xFFFF
    # Unknown low16 — could be a genuine sub-entry offset, but Xbox DLC has
    # no known valid sub-entry refs.  Default to primary to be safe.
    return (high16 << 16) | 0xFFFF


# ── Pipeline ──────────────────────────────────────────────────────────

def port_x360_dlc(
    doh: bytes,
    *,
    output_path: Path,
    merge_into: Path | None = None,
    source_wad: Path | None = None,
    max_blocks: int | None = None,
    start_block: int = 0,
    verbose: bool = False,
    dump_dir: Path | None = None,
    dlc_contracts: list[str] | None = None,
    no_bootstrap: bool = False,
    no_hook: bool = False,
    fix_stringdb_descriptors: bool = False,
    synth_stringdb_aset: bool = True,
    jobs: int | None = None,
    permissive: bool = False,
    strip_audio: bool = False,
) -> int:
    """Convert a big-endian DOH (DLC01.doh content) into a PC vz-patch.wad.

    If *source_wad* is provided (path to retail vz.wad), the bootstrap
    injection is performed automatically: the scripts_vz block is extracted,
    modified with a ``dlc01`` master script, and the ``vz`` master script is
    replaced with a minimal wrapper that chain-loads it.  The resulting WAD
    contains both the DLC asset blocks and the bootstrap block.

    If *no_hook* is True, the bootstrap adds ``dlc01`` as a new entry only
    (entry 115) without modifying ``wifmissionflow`` — the original 114 entries
    remain byte-identical.  The ASI triggers ``import("dlc01")`` at runtime.
    """
    print("Xbox 360 DLC -> PC Patch WAD Porter (unified)")
    print("=" * 60)
    print("  Byte-swap backend: Rust (ucfx_byteswap)")

    # Parse BE FFCS
    version, rows = parse_be_ffcs(doh)
    print(f"  FFCS version: {version}, chunks: {len(rows)}")

    indx_row = next((r for r in rows if r.tag == "INDX"), None)
    aset_row = next((r for r in rows if r.tag == "ASET"), None)
    pths_row = next((r for r in rows if r.tag == "PTHS"), None)
    data_row = next((r for r in rows if r.tag == "DATA"), None)
    csum_row = next((r for r in rows if r.tag == "CSUM"), None)

    if not all([indx_row, aset_row, pths_row, data_row]):
        print("ERROR: Missing required FFCS chunks", file=sys.stderr)
        return 1

    num_blocks = indx_row.meta
    print(f"  INDX: {num_blocks} blocks")
    print(f"  ASET: {aset_row.meta} entries")

    # CSUM fields: purpose not fully understood. Pass through the Xbox source
    # values — prior assets-only builds with these values were stable (30+ min
    # freeplay).  Overriding with base-game values caused a regression.
    source_csum_value = csum_row.offset if csum_row else 0
    source_csum_meta = csum_row.meta if csum_row else None
    if csum_row:
        print(f"  CSUM: value=0x{source_csum_value:08X}, meta={source_csum_meta}")

    # Parse metadata
    indx_entries = parse_be_indx(doh, indx_row.offset, num_blocks)
    aset_entries = parse_be_aset(doh, aset_row.offset, aset_row.meta)
    path_strings = parse_be_pths(doh, pths_row.offset, pths_row.meta)

    print(f"  PTHS: {len(path_strings)} paths")
    if verbose:
        for i, p in enumerate(path_strings[:10]):
            print(f"    [{i}] {p}")
        if len(path_strings) > 10:
            print(f"    ... ({len(path_strings) - 10} more)")

    # Build ASET lookup: block_index → list of entries
    # Xbox ASET block indices may start from a base offset; entries with
    # block_index == 0xFFFF are "global" references that need resolving
    # to the actual block containing that asset (done after decompression).
    real_block_indices = set()
    global_aset: list[dict] = []
    for ae in aset_entries:
        if ae.block_index == 0xFFFF:
            global_aset.append({
                "asset_hash": ae.asset_hash,
                "u32_1": ae.u1,
                "u32_2": _fix_xbox_aset_sub_entry(ae.u2),
                "u32_3": ae.u3,
            })
        else:
            real_block_indices.add(ae.block_index)

    if real_block_indices:
        aset_base_idx = min(real_block_indices)
    else:
        aset_base_idx = 0

    aset_by_block: dict[int, list[dict]] = {}
    for ae in aset_entries:
        if ae.block_index == 0xFFFF:
            continue
        local_idx = ae.block_index - aset_base_idx
        entry_dict = {
            "asset_hash": ae.asset_hash,
            "u32_1": ae.u1,
            "u32_2": _fix_xbox_aset_sub_entry(ae.u2),
            "u32_3": ae.u3,
        }
        aset_by_block.setdefault(local_idx, []).append(entry_dict)

    if global_aset:
        print(f"\n  Global ASET entries (block_index=0xFFFF): {len(global_aset)}")
        print("  These will be resolved to actual blocks after decompression.")

    # Determine block range
    end_block = min(num_blocks, start_block + (max_blocks or num_blocks))
    block_list = list(range(start_block, end_block))
    n_blocks = len(block_list)
    print(f"\n  Processing blocks {start_block}..{end_block - 1} ({n_blocks} blocks)")

    if jobs is None:
        jobs = os.cpu_count() or 1
    jobs = max(1, jobs)
    if jobs > 1:
        print(f"  Parallel workers: {jobs}")

    # Build base game animation index for Havok override
    base_anim_index: dict[tuple[int, int], int] = {}
    if source_wad:
        base_anim_index = _build_base_aset_index(source_wad)
        if base_anim_index:
            print(f"  Base game animation index: {len(base_anim_index)} entries")

    collect_hashes = bool(global_aset)
    dump_dir_str = str(dump_dir) if dump_dir else None
    source_wad_str = str(source_wad) if source_wad else None

    worker_args_list: list[_BlockWorkerArgs] = []
    pre_skipped: list[_BlockWorkerResult] = []

    for blk_idx in block_list:
        indx = indx_entries[blk_idx]
        path = path_strings[blk_idx] if blk_idx < len(path_strings) else f"block_{blk_idx:05d}"
        block_offset = indx.file_offset
        block_size = indx.page_count * PAGE_SIZE

        if block_offset + 4 > len(doh):
            pre_skipped.append(_BlockWorkerResult(
                blk_idx=blk_idx,
                skipped=True,
                skip_reason=f"offset 0x{block_offset:X} beyond DOH",
            ))
            continue

        worker_args_list.append(_BlockWorkerArgs(
            blk_idx=blk_idx,
            path=path,
            doh_slice=bytes(doh[block_offset:block_offset + block_size]),
            block_asets=list(aset_by_block.get(blk_idx, [])),
            packed_field=indx.packed_field,
            flags=indx.flags,
            base_anim_index=base_anim_index,
            source_wad_path=source_wad_str,
            fix_stringdb_descriptors=fix_stringdb_descriptors,
            dump_dir_path=dump_dir_str,
            verbose=verbose,
            collect_hashes=collect_hashes,
            permissive=permissive,
            strip_audio=strip_audio,
        ))

    all_results: list[_BlockWorkerResult] = list(pre_skipped)
    t0 = time.monotonic()

    done_count = 0
    for pres in pre_skipped:
        done_count += 1
        pct = done_count * 100 // n_blocks if n_blocks else 100
        print(
            f"  [{done_count}/{n_blocks}] {pct}% — "
            f"[{pres.blk_idx}] SKIP: {pres.skip_reason}"
        )

    if jobs <= 1:
        for i, wargs in enumerate(worker_args_list):
            res = _process_one_block(wargs)
            all_results.append(res)
            done_count += 1
            pct = done_count * 100 // n_blocks if n_blocks else 100
            elapsed = time.monotonic() - t0
            if res.skipped:
                print(
                    f"  [{done_count}/{n_blocks}] {pct}% — "
                    f"[{res.blk_idx}] SKIP: {res.skip_reason} ({elapsed:.0f}s)"
                )
            else:
                print(
                    f"  [{done_count}/{n_blocks}] {pct}% — "
                    f"[{res.blk_idx}] {wargs.path} ({elapsed:.0f}s)"
                )
    else:
        with ProcessPoolExecutor(max_workers=jobs) as pool:
            futures = {
                pool.submit(_process_one_block, wargs): wargs
                for wargs in worker_args_list
            }
            for fut in as_completed(futures):
                wargs = futures[fut]
                res = fut.result()
                all_results.append(res)
                done_count += 1
                pct = done_count * 100 // n_blocks if n_blocks else 100
                elapsed = time.monotonic() - t0
                if res.skipped:
                    print(
                        f"  [{done_count}/{n_blocks}] {pct}% — "
                        f"[{res.blk_idx}] SKIP: {res.skip_reason} ({elapsed:.0f}s)"
                    )
                else:
                    print(
                        f"  [{done_count}/{n_blocks}] {pct}% — "
                        f"[{res.blk_idx}] {wargs.path} ({elapsed:.0f}s)"
                    )

    elapsed_total = time.monotonic() - t0
    print(f"  Block processing finished in {elapsed_total:.1f}s")

    skipped_details = [
        (r.blk_idx, path_strings[r.blk_idx] if r.blk_idx < len(path_strings) else "?", r.skip_reason)
        for r in all_results
        if r.skipped and r.skip_reason
    ]
    if skipped_details:
        print(f"  Skipped blocks ({len(skipped_details)}):")
        for blk_idx, path, reason in skipped_details:
            print(f"    [{blk_idx}] {path}")
            print(f"          {reason}")

    converted, skipped, tags_seen, hash_to_local_block = _collect_block_results(
        all_results, verbose=verbose,
    )
    total_swap_stats: dict = {"tags_seen": tags_seen}

    # Resolve global ASET entries (block_index=0xFFFF) to actual blocks
    if global_aset:
        resolved = 0
        unresolved = 0
        for gae in global_aset:
            local_blk = hash_to_local_block.get(gae["asset_hash"])
            if local_blk is not None and local_blk < len(converted):
                entry = dict(gae)
                try:
                    raw_blk = decompress_sges_block(
                        converted[local_blk].compressed_data,
                        0,
                        len(converted[local_blk].compressed_data),
                    )
                    for ucfx in parse_block_entries(raw_blk):
                        if ucfx.get("hash") == entry["asset_hash"]:
                            th = ucfx.get("type_hash", 0)
                            tid = type_id_for_type_hash(th)
                            if tid is not None:
                                entry["u32_3"] = tid
                            break
                except Exception:
                    pass
                converted[local_blk].aset_entries.append(entry)
                resolved += 1
            else:
                unresolved += 1
        print(f"\n  Global ASET resolved: {resolved}, unresolved: {unresolved}")

    print(f"\n  Converted: {len(converted)}, Skipped: {skipped}")
    if total_swap_stats["tags_seen"]:
        print("  Chunk tags swapped:")
        for tag, cnt in sorted(total_swap_stats["tags_seen"].items(), key=lambda x: -x[1]):
            print(f"    {tag}: {cnt}")

    if not converted:
        print("ERROR: No blocks converted", file=sys.stderr)
        return 1

    # ── Ensure ASET entries exist for all UCFX entries ────────────────
    # The Xbox DLC ASET table may not cover every block (some blocks have
    # no ASET rows, or the global resolution missed them).  Blocks that
    # the engine needs to look up by asset hash — especially stringdb
    # blocks loaded via Sys.AddStringDb() — MUST have ASET entries or
    # the lookup will fail silently.
    #
    # Scan all converted blocks: for each UCFX entry whose asset_hash is
    # not already represented in the block's ASET list, add a synthetic
    # entry with the correct type_hash.
    script_synth_added = 0
    stringdb_synth_added = 0
    if not synth_stringdb_aset:
        print("\n  ASET fix: skipping synthetic stringdb rows (--no-synth-stringdb-aset)")
    for blk_idx, blk in enumerate(converted):
        existing_hashes = {e["asset_hash"] for e in blk.aset_entries}
        try:
            decomp = decompress_sges_block(
                blk.compressed_data, 0, len(blk.compressed_data))
            entries = parse_block_entries(decomp)
        except Exception:
            continue
        for entry in entries:
            h = entry.get("hash")
            th = entry.get("type_hash", 0)
            if not h or h == 0 or h in existing_hashes:
                continue
            if th == SCRIPT_TYPE_HASH:
                blk.aset_entries.append(script_aset_entry(h))
                existing_hashes.add(h)
                script_synth_added += 1
                if verbose:
                    print(f"  [ASET fix] block {blk_idx}: added script "
                          f"entry 0x{h:08X} (type_id={SCRIPT_ASET_TYPE_ID})")
            elif synth_stringdb_aset and th == STRINGDB_TYPE_HASH:
                blk.aset_entries.append({
                    "asset_hash": h,
                    "u32_1": 0xFFFFFFFF,
                    "u32_2": 0xFFFF,
                    "u32_3": STRINGDB_ASET_TYPE_ID,
                })
                existing_hashes.add(h)
                stringdb_synth_added += 1
                if verbose:
                    print(f"  [ASET fix] block {blk_idx}: added stringdb "
                          f"entry 0x{h:08X} (type_id={STRINGDB_ASET_TYPE_ID})")
    if script_synth_added:
        print(f"\n  ASET fix: added {script_synth_added} missing script "
              f"ASET entries (import/dynamic_import lookup)")
    if stringdb_synth_added:
        print(f"\n  ASET fix: added {stringdb_synth_added} missing stringdb "
              f"ASET entries (required for Sys.AddStringDb)")

    contract_aset_added, contracts_missing = ensure_import_chain_script_aset(
        converted,
    )
    if contract_aset_added:
        print(f"\n  ASET fix: added {contract_aset_added} DLC contract "
              f"ASET entries (import chain)")
    xbox_aset_added = ensure_contract_aset_from_xbox_block_aset(
        converted, aset_by_block, path_strings,
    )
    if xbox_aset_added:
        print(f"  ASET fix: added {xbox_aset_added} contract row(s) from Xbox "
              f"per-block ASET")
    resident_aset_added, resident_present = ensure_contract_aset_on_resident_block(
        converted,
    )
    if resident_present:
        print(f"  ASET fix: resident_P000_Q3 present — "
              f"added {resident_aset_added} contract row(s) from BINN refs")
    elif not any(is_dlc_script_resident_path(p) for p in path_strings):
        print("  WARNING: blocks\\dlc01\\resident_P000_Q3.block missing from "
              "converted set (contracts will not resolve)")
    contracts_missing = [
        n for n in contracts_missing
        if pandemic_hash_m2(n) not in {
            e["asset_hash"] for blk in converted for e in blk.aset_entries
        }
    ]
    if contracts_missing:
        print(f"  WARNING: contract module not found in any converted block:")
        for name in contracts_missing:
            print(f"    - {name} (hash=0x{pandemic_hash_m2(name):08X})")
        if any("resident_p000_q3" in p.lower() for _, p, _ in skipped_details):
            print("  NOTE: blocks\\dlc01\\resident_P000_Q3.block was SKIPPED — "
                  "contracts cannot load until that block converts.")

    # ── DLC Bootstrap Injection ──────────────────────────────────────
    # When --source-wad is provided, extract the scripts_vz block from the
    # retail WAD, inject the dlc01 master script, modify the vz master
    # script to chain-load it, and include the modified block in the WAD.
    if source_wad and not no_bootstrap:
        print("\n" + "─" * 60)
        mode_label = "nohook — entry 115 only" if no_hook else "integrated"
        print(f"DLC Bootstrap Injection ({mode_label})")
        print("─" * 60)

        bootstrap_block = _build_bootstrap_block(
            source_wad,
            dlc_contracts=dlc_contracts or DLC_CONTRACT_NAMES,
            verbose=verbose,
            no_hook=no_hook,
            converted_blocks=converted,
        )
        if bootstrap_block is None:
            print("ERROR: Bootstrap injection failed", file=sys.stderr)
            return 1
        converted.append(bootstrap_block)
        print(f"\n  Added scripts_vz bootstrap block "
              f"({len(bootstrap_block.compressed_data):,} bytes compressed)")
        scripts_vz_idx = len(converted) - 1
    elif source_wad is None and not no_bootstrap:
        print("\n  NOTE: --source-wad not provided; skipping DLC bootstrap injection.")
        print("        Run with --source-wad path/to/vz.wad for a complete patch WAD.")
    else:
        scripts_vz_idx = None

    norm_changed = normalize_all_block_asets(converted)
    if norm_changed:
        print(f"\n  ASET normalize: fixed {norm_changed} type_id field(s) from UCFX type_hash")

    dlc01_hash = pandemic_hash_m2("dlc01")
    dedupe_removed = dedupe_asset_hash_across_blocks(
        converted,
        dlc01_hash,
        prefer_type_id=SCRIPT_ASET_TYPE_ID,
        prefer_min_block_index=scripts_vz_idx,
    )
    if dedupe_removed:
        print(f"  ASET dedupe: removed {dedupe_removed} duplicate dlc01 row(s) "
              f"(prefer scripts_vz block {scripts_vz_idx})")

    # Global Xbox ASET can leave script hashes on resident (464) AND scripts_vz;
    # engine may resolve wifmissionflow/vz to resident → crash at GameBootstrap.
    if scripts_vz_idx is not None:
        resident_idx = find_dlc_script_resident_block_index(converted)
        # Only dedupe hashes that appear on scripts_vz — do not strip resident-only
        # contract rows (dlccon* live on resident, not bootstrap scripts_vz).
        svz_script_hashes: set[int] = set()
        for entry in converted[scripts_vz_idx].aset_entries:
            if entry.get("u32_3") == SCRIPT_ASET_TYPE_ID:
                svz_script_hashes.add(entry["asset_hash"])
        script_deduped = 0
        for asset_hash in svz_script_hashes:
            script_deduped += dedupe_asset_hash_across_blocks(
                converted,
                asset_hash,
                prefer_type_id=SCRIPT_ASET_TYPE_ID,
                prefer_min_block_index=scripts_vz_idx,
            )
        if script_deduped:
            label = (
                f"resident block {resident_idx}" if resident_idx is not None
                else "scripts_vz"
            )
            print(f"  ASET dedupe: removed {script_deduped} script row(s) "
                  f"conflicting with {label}")

    contract_aset_added, contracts_missing = ensure_import_chain_script_aset(
        converted,
    )
    resident_aset_added2, _ = ensure_contract_aset_on_resident_block(converted)
    if resident_aset_added2:
        print(f"  ASET fix (post-dedupe): added {resident_aset_added2} contract "
              f"row(s) on resident")
    if contract_aset_added:
        print(f"  ASET fix (post-dedupe): added {contract_aset_added} contract "
              f"ASET entries")
    if contracts_missing:
        print(f"  WARNING: still missing contract blocks after dedupe:")
        for name in contracts_missing:
            print(f"    - {name}")

    # Build or merge patch WAD
    if merge_into and merge_into.is_file():
        print(f"\n  Merging into existing: {merge_into}")
        patch_wad = merge_patch_wads(merge_into, converted)
    else:
        patch_wad = build_patch_wad_multi(
            blocks=converted,
            csum_value=source_csum_value,
            csum_meta=source_csum_meta,
        )

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_bytes(patch_wad)
    print(f"\n  Output: {output_path} ({len(patch_wad):,} bytes / "
          f"{len(patch_wad) / 1024 / 1024:.1f} MB)")

    total_blocks = len(converted)
    dlc_blocks = total_blocks - (1 if source_wad and not no_bootstrap else 0)
    print(f"\n  Contents:")
    print(f"    - {dlc_blocks} DLC asset blocks (Xbox 360 → PC)")
    if source_wad and not no_bootstrap:
        print(f"    - 1 modified scripts_vz block (DLC bootstrap)")

    print("\n  Byte-swap coverage:")
    print("    ✓ Block headers, UCFX descriptors, all uppercase+lowercase chunk tags")
    print("    ✓ STRM vertex buffers (u32 swap — correct for f32 positions)")
    print("    ✓ IBUF index buffers (u16 swap)")
    print("    ✓ COMP/CHDR/flgs placement records")
    print("    ✓ PRMG/MESH/HIER/MTRL/BNDS/INFO structural data")
    print("    ✓ BINN Lua bytecode (full recursive swap)")
    print("    ~ BODY texture data (tile-swizzle not applied — game uses vz.wad fallback)")
    print("    ~ Havok binary data (not field-swapped — animations may be incorrect)")
    print("\n  Localization / briefing (Row 13):")
    print("    - dlc01 bootstrap calls Sys.AddStringDb(\"patch01\", \"dlc01\")")
    print("      → registers blocks\\\\dlc01\\\\english_dlc01 (titles: Mercs Blitz, etc.)")
    print("    - Deploy VO: copy vo_stream_dlctest.english.pws to <game>/Data/Audios/")
    print("      (use --extract-audio or fresh-rebuilt/data/Audios/)")
    print("    - Briefing Spiel gfx still missing → placeholder slides (slow, not deadlock)")

    return 0


def _extract_luaq_from_entry(decompressed: bytes, entry: dict) -> bytes | None:
    """Return raw LuaQ bytes from a UCFX entry chunk, or None."""
    entry_start = entry["offset"]
    entry_end = entry_start + entry["size"] - 8
    chunk = decompressed[entry_start:entry_end]
    luaq_pos = chunk.find(b"\x1bLua")
    if luaq_pos < 0:
        return None
    return chunk[luaq_pos:]


def _contract_name_for_entry(
    decompressed: bytes,
    entry: dict,
    target_hashes: dict[int, str],
    name_by_lower: dict[str, str],
) -> str | None:
    cname = target_hashes.get(entry.get("hash", 0))
    if cname is not None:
        return cname
    ref_name = get_binn_script_ref_name(decompressed, entry)
    if ref_name:
        return name_by_lower.get(ref_name.lower())
    try:
        binn_name = get_script_name(decompressed, entry)
    except Exception:
        binn_name = ""
    return name_by_lower.get(binn_name.lower()) if binn_name else None


def _extract_contract_bytecodes(
    converted_blocks: list[PatchBlock],
    contract_names: list[str],
    *,
    verbose: bool = False,
) -> dict[str, bytes]:
    """Extract LuaQ bytecodes for DLC contracts from converted blocks.

    Handles inline LuaQ and resident-style BINN references (name at +0x0F,
    bytecode may live in another block with the same asset hash).
    """
    target_hashes: dict[int, str] = {
        pandemic_hash_m2(name): name for name in contract_names
    }
    name_by_lower = {name.lower(): name for name in contract_names}
    results: dict[str, bytes] = {}

    # Pass 1: direct LuaQ on matching entries
    for blk_idx, block in enumerate(converted_blocks):
        decompressed = decompress_sges_block(
            block.compressed_data, 0, len(block.compressed_data)
        )
        try:
            entries = parse_block_entries(decompressed)
        except Exception:
            continue

        for entry in entries:
            cname = _contract_name_for_entry(
                decompressed, entry, target_hashes, name_by_lower,
            )
            if cname is None or cname in results:
                continue
            luaq = _extract_luaq_from_entry(decompressed, entry)
            if luaq is not None:
                results[cname] = luaq
                if verbose:
                    print(f"      {cname}: LuaQ in block {blk_idx} "
                          f"(entry hash=0x{entry['hash']:08X})")

        if len(results) == len(target_hashes):
            return results

    # Pass 2: BINN ref names without inline LuaQ — find bytecode by asset hash
    missing = [n for n in contract_names if n not in results]
    if not missing:
        return results

    for cname in list(missing):
        chash = pandemic_hash_m2(cname)
        for blk_idx, block in enumerate(converted_blocks):
            decompressed = decompress_sges_block(
                block.compressed_data, 0, len(block.compressed_data)
            )
            try:
                entries = parse_block_entries(decompressed)
            except Exception:
                continue
            for entry in entries:
                if entry.get("hash") != chash:
                    continue
                luaq = _extract_luaq_from_entry(decompressed, entry)
                if luaq is not None:
                    results[cname] = luaq
                    if verbose:
                        print(f"      {cname}: LuaQ by hash in block {blk_idx}")
                    break
            if cname in results:
                break

    return results


# The DLC01 registration script registers DLC missions with tMissionData
# and unlocks them so they appear in Fiona's mission list.
# Based on analysis of wifmissiondata.luac: PMC contracts use sStarter="PmcBoss"
# (Fiona), sFactionId="Pmc", bPlayerVisibleMission=true.
#
# IMPORTANT: Do NOT call import("dlccon*") here.  Contract scripts live in the
# DLC asset blocks and will be loaded on-demand by the mission system when the
# player accepts a contract.  Eagerly importing them during dlc01 load can
# trigger re-entrant block loading if the engine is still processing scripts_vz,
# and the DLC block's non-script UCFX entries (meshes, textures with unswapped
# STRM/BODY data) may confuse the loader.
#
# Title strings: Xbox resident dlc01 calls Sys.AddStringDb("patch01", "dlc01")
# to register blocks\\dlc01\\english_dlc01_P000_Q3.block (ported in vz-patch.wad).
# Without this, GetMissionTitle falls back to unresolved keys like
# [DlcCon001.Title] in Fiona's briefing list.
_DLC01_REGISTRATION_SOURCE = '''\
print("[dlc01] ======== dlc01 script executing ========")

-- Probe the environment: what globals are visible?
-- (Do NOT use type() — it may be shadowed as a table)
if print then
    print("[dlc01] print is available")
else
    -- If we get here, we can't even log. But let's try anyway.
end

if import then
    print("[dlc01] import exists (good — engine global)")
else
    print("[dlc01] import is NIL")
end

if tMissionData then
    print("[dlc01] tMissionData EXISTS")
else
    print("[dlc01] tMissionData is NIL — missions will NOT be registered")
end

if UnlockMission then
    print("[dlc01] UnlockMission EXISTS")
else
    print("[dlc01] UnlockMission is NIL — missions will NOT be unlocked")
end

-- Probe other common game globals for environment diagnosis
if _G then
    print("[dlc01] _G exists")
else
    print("[dlc01] _G is NIL")
end

if _MODULES then
    print("[dlc01] _MODULES exists")
else
    print("[dlc01] _MODULES is NIL")
end

if _SYS then
    print("[dlc01] _SYS exists")
else
    print("[dlc01] _SYS is NIL")
end

if inherit then
    print("[dlc01] inherit exists")
else
    print("[dlc01] inherit is NIL")
end

if MissionManager then
    print("[dlc01] MissionManager exists")
else
    print("[dlc01] MissionManager is NIL")
end

if ActivateMission then
    print("[dlc01] ActivateMission exists")
else
    print("[dlc01] ActivateMission is NIL")
end

-- Load DLC English string DB (Mercs Blitz, Arms Race, Urban Rampage, Death Race)
if Sys and Sys.AddStringDb then
    print("[dlc01] Calling Sys.AddStringDb(patch01, dlc01)...")
    Sys.AddStringDb("patch01", "dlc01")
    print("[dlc01] Sys.AddStringDb returned")
elseif AddStringDb then
    print("[dlc01] Calling AddStringDb(patch01, dlc01)...")
    AddStringDb("patch01", "dlc01")
    print("[dlc01] AddStringDb returned")
else
    print("[dlc01] AddStringDb unavailable — contract titles will show as [DlcConNNN.Title]")
end

-- Now attempt registration
if tMissionData then
    print("[dlc01] Registering DlcCon001 with tMissionData...")
    tMissionData["DlcCon001"] = {
        sModuleName = "DlcCon001",
        sFactionId = "Pmc",
        sStarter = "PmcBoss",
        bPlayerVisibleMission = true,
        bContract = true,
    }
    print("[dlc01] Registering DlcCon002 with tMissionData...")
    tMissionData["DlcCon002"] = {
        sModuleName = "DlcCon002",
        sFactionId = "Pmc",
        sStarter = "PmcBoss",
        bPlayerVisibleMission = true,
        bContract = true,
    }
    print("[dlc01] Registering DlcCon003 with tMissionData...")
    tMissionData["DlcCon003"] = {
        sModuleName = "DlcCon003",
        sFactionId = "Pmc",
        sStarter = "PmcBoss",
        bPlayerVisibleMission = true,
        bContract = true,
    }
    print("[dlc01] Registering DlcCon004a with tMissionData...")
    tMissionData["DlcCon004a"] = {
        sModuleName = "DlcCon004a",
        sFactionId = "Pmc",
        sStarter = "PmcBoss",
        bPlayerVisibleMission = true,
        bContract = true,
    }
    print("[dlc01] All 4 missions registered in tMissionData")
else
    print("[dlc01] SKIPPED tMissionData registration (nil)")
end

if UnlockMission then
    print("[dlc01] Calling UnlockMission for DlcCon001...")
    UnlockMission("DlcCon001")
    print("[dlc01] Calling UnlockMission for DlcCon002...")
    UnlockMission("DlcCon002")
    print("[dlc01] Calling UnlockMission for DlcCon003...")
    UnlockMission("DlcCon003")
    print("[dlc01] Calling UnlockMission for DlcCon004a...")
    UnlockMission("DlcCon004a")
    print("[dlc01] All 4 missions unlocked")
else
    print("[dlc01] SKIPPED UnlockMission calls (nil)")
end

print("[dlc01] ======== dlc01 script finished ========")
'''


def _build_dlc01_source(contract_names: list[str], *, no_hook: bool = False) -> str:
    """Build the Lua source for the DLC01 master script.

    Both modes register missions with tMissionData and call UnlockMission()
    so DLC contracts appear in Fiona's list.  Contract scripts are NOT
    imported eagerly — they live in the DLC asset blocks and are loaded
    on-demand by the mission system when the player accepts a contract.
    """
    return _DLC01_REGISTRATION_SOURCE


def _build_bootstrap_block(
    source_wad: Path,
    *,
    dlc_contracts: list[str],
    verbose: bool = False,
    no_hook: bool = False,
    converted_blocks: list[PatchBlock] | None = None,
) -> PatchBlock | None:
    """Extract scripts_vz from vz.wad, inject DLC bootstrap, return as PatchBlock.

    If *no_hook* is True (recommended), only adds ``dlc01`` as entry 115
    without modifying ``wifmissionflow``.  Contract scripts remain in the
    DLC asset blocks and are resolved via ASET on-demand.  The ASI triggers
    ``import("dlc01")`` at runtime.  Returns None on failure.

    If *no_hook* is False, also extracts DLC contract bytecodes from the
    resident block, adds them to scripts_vz, and hooks ``wifmissionflow``
    with a chain-loader.  WARNING: this path causes a hang at
    "Loading vz level with vz masterscript" — use ``--no-hook`` instead.
    """
    repo_root = Path(__file__).resolve().parent.parent
    import shutil
    candidates = [
        repo_root / "tools" / "lua51-mercs2" / "build" / "luac",
        repo_root / "tools" / "lua51-mercs2" / "src" / "luac",
        repo_root / "lua-backup-dont-delete" / "src" / "luac",
        repo_root / "lua-5.1.5" / "src" / "luac",
        repo_root / "tools" / "lua51-mercs2" / "luac.exe",
    ]
    luac = None
    for c in candidates:
        if c.is_file():
            luac = c
            break
    if luac is None:
        luac_on_path = shutil.which("luac")
        if luac_on_path:
            luac = Path(luac_on_path)
        else:
            print(f"  ERROR: Lua compiler not found.", file=sys.stderr)
            for c in candidates:
                print(f"    Checked: {c}", file=sys.stderr)
            print(f"    Checked: PATH (shutil.which)", file=sys.stderr)
            print(f"    Build with: make build-luac", file=sys.stderr)
            return None

    print(f"  Lua compiler: {luac}")

    # Step 1: Extract DLC contract bytecodes from the resident block.
    # In nohook mode, skip extraction — contracts stay in the DLC asset
    # blocks and are resolved via ASET on-demand when the player accepts
    # a mission.  Injecting them into scripts_vz is unnecessary and risks
    # re-entrant block loading during masterscript evaluation.
    contract_bytecodes: dict[str, bytes] = {}
    if converted_blocks:
        print("\n  [bootstrap 1/6] Extracting DLC contract bytecodes from converted blocks...")
        contract_bytecodes = _extract_contract_bytecodes(
            converted_blocks, dlc_contracts, verbose=verbose
        )
        if contract_bytecodes:
            print(f"    Extracted {len(contract_bytecodes)} contract bytecodes:")
            for name, bc in contract_bytecodes.items():
                print(f"      {name}: {len(bc):,} bytes")
        elif no_hook:
            print("    Nohook: no inline LuaQ found — contracts may use resident BINN refs only.")
        else:
            print("    WARNING: No contract bytecodes found in converted blocks.")
    else:
        print("\n  [bootstrap 1/6] No converted blocks provided; skipping contract extraction.")

    # Step 2: Compile the DLC master script (dlc01)
    print("\n  [bootstrap 2/6] Compiling DLC master script (dlc01)...")
    dlc01_source = _build_dlc01_source(dlc_contracts, no_hook=no_hook)
    if verbose:
        print(f"    Source:\n{dlc01_source}")
    try:
        dlc01_bytecode = compile_lua_source(dlc01_source, luac)
    except (FileNotFoundError, RuntimeError) as e:
        print(f"  ERROR: {e}", file=sys.stderr)
        return None

    # Step 3: Extract scripts_vz block from the retail WAD (block 3197 on PC retail)
    print("  [bootstrap 3/6] Extracting scripts_vz block from retail WAD...")
    try:
        scripts_idx = resolve_scripts_vz_block_index(source_wad)
        meta = extract_block_metadata(source_wad, scripts_idx)
    except Exception as e:
        print(f"  ERROR extracting scripts_vz block: {e}", file=sys.stderr)
        return None

    print(f"    Block index: {scripts_idx}")
    print(f"    PTHS: {meta['pths_string']}")
    print(f"    ASET entries: {meta['aset_entry_count']}")
    print(f"    Compressed size: {meta['block_compressed_size']:,} bytes")

    compressed_data = meta["compressed_block_data"]
    decompressed = decompress_sges_block(compressed_data, 0, len(compressed_data))
    print(f"    Decompressed: {len(decompressed):,} bytes")

    entries = parse_block_entries(decompressed)
    print(f"    UCFX entries: {len(entries)}")

    hook_name = None
    hook_orig_hash: int | None = None

    if no_hook:
        print("    Mode: nohook — adding dlc01 only, no wifmissionflow modification")
    else:
        hook = find_dlc_bootstrap_hook_script(decompressed, entries)
        if hook is None:
            print(
                "  NOTE: No hook script (vz / wifmissionflow / wifpmcinterior) in scripts_vz.",
            )
            print(
                "        Adding dlc01 only — use dlc_enable ASI or verify_patch_dlc_hook.py on PC.",
            )
        else:
            hook_name, hook_entry = hook
            print(
                f"    Bootstrap hook: {hook_name!r} "
                f"(hash=0x{hook_entry['hash']:08X}, size={hook_entry['size']:,})"
            )

    # Step 4: Modify the block — add dlc01 entry
    print("  [bootstrap 4/6] Injecting DLC bootstrap into scripts_vz block...")

    dlc01_asset_hash = pandemic_hash_m2("dlc01")
    if verbose:
        print(f"    dlc01 asset hash: 0x{dlc01_asset_hash:08X}")

    dlc01_ucfx = _build_ucfx_script_chunk(
        "dlc01", dlc01_bytecode, dlc01_asset_hash,
    )

    modified = _add_ucfx_entry_to_block(
        decompressed, dlc01_ucfx, dlc01_asset_hash,
    )

    # Step 5: Add DLC contract bytecodes to scripts_vz
    contract_aset_hashes: list[int] = []
    if contract_bytecodes:
        print("  [bootstrap 5/6] Adding DLC contract scripts to scripts_vz...")
        for cname, cbytecode in contract_bytecodes.items():
            chash = pandemic_hash_m2(cname)
            cucfx = _build_ucfx_script_chunk(cname, cbytecode, chash)
            modified = _add_ucfx_entry_to_block(modified, cucfx, chash)
            contract_aset_hashes.append(chash)
            if verbose:
                print(f"      Added {cname} (hash=0x{chash:08X}, "
                      f"ucfx={len(cucfx):,} bytes)")
        new_count = struct.unpack_from("<I", modified, 0)[0]
        print(f"    scripts_vz now has {new_count} entries "
              f"(+1 dlc01 +{len(contract_bytecodes)} contracts)")
    else:
        print("  [bootstrap 5/6] No contract bytecodes to add.")

    if hook_name is not None:
        try:
            modified, hook_orig_hash = inject_dlc_hook_chain_load(
                modified, hook_name, luac
            )
        except (ValueError, RuntimeError) as e:
            print(f"  ERROR: hook chain-load failed: {e}", file=sys.stderr)
            return None

    new_entries = parse_block_entries(modified)
    print(f"    Block entries: {len(entries)} → {len(new_entries)}")
    print(f"    Modified size: {len(modified):,} bytes "
          f"(delta {len(modified) - len(decompressed):+,})")

    # Step 6: Recompress
    print("  [bootstrap 6/6] Recompressing scripts_vz block...")
    new_sges = compress_sges(modified, segment_size=65536, level=6, major=4)
    ratio = len(new_sges) / len(modified) * 100
    print(f"    Compressed: {len(new_sges):,} bytes ({ratio:.1f}%)")

    # Verify roundtrip
    verify = decompress_sges_block(new_sges, 0, len(new_sges))
    if verify != modified:
        print("  ERROR: Roundtrip verification failed!", file=sys.stderr)
        return None
    if verbose:
        print("    Roundtrip verification OK")

    # Build PatchBlock with updated ASET
    aset_entries = list(meta["aset_entries"])
    aset_entries.append(script_aset_entry(dlc01_asset_hash))
    for chash in contract_aset_hashes:
        aset_entries.append(script_aset_entry(chash))
    if hook_orig_hash is not None:
        aset_entries.append(script_aset_entry(hook_orig_hash))

    # Recompute packed_field from the modified block's actual size
    orig_packed = meta["indx_entry"].get("packed_field", 1)
    tier = (orig_packed >> 24) & 0xFF
    correct_pages = (len(modified) + 0x7FFF) // 0x8000
    recomputed_packed = (tier << 24) | correct_pages

    return PatchBlock(
        compressed_data=new_sges,
        path_string=meta["pths_string"],
        aset_entries=aset_entries,
        packed_field=recomputed_packed,
        flags=meta["indx_entry"].get("flags", 0x8000),
    )


def cmd_list_blocks(doh: bytes) -> int:
    """Print block inventory and exit."""
    _, rows = parse_be_ffcs(doh)
    indx_row = next((r for r in rows if r.tag == "INDX"), None)
    pths_row = next((r for r in rows if r.tag == "PTHS"), None)

    if not indx_row or not pths_row:
        print("ERROR: Missing INDX/PTHS", file=sys.stderr)
        return 1

    num_blocks = indx_row.meta
    indx_entries = parse_be_indx(doh, indx_row.offset, num_blocks)
    path_strings = parse_be_pths(doh, pths_row.offset, pths_row.meta)

    print(f"DLC blocks: {num_blocks}")
    print(f"{'#':>4}  {'Pages':>5}  {'Offset':>10}  Path")
    print("-" * 70)
    for i, indx in enumerate(indx_entries):
        path = path_strings[i] if i < len(path_strings) else "???"
        print(f"{i:4d}  {indx.page_count:5d}  0x{indx.file_offset:08X}  {path}")

    return 0


# ── Audio extraction ──────────────────────────────────────────────────

def extract_dlc_audio(stfs_data: bytes, audio_dir: Path) -> int:
    """Extract and transcode .pws audio files from the STFS container.

    Audio files live alongside DLC01.doh in the STFS file table as
    entries whose block chains are walked via hash table pointers.
    Xbox .pws files use Xbox ADPCM (format 0x0069, high-nibble-first),
    PC uses MS-IMA ADPCM (format 0x0011, low-nibble-first). The
    transcoding is lossless for mono (nibble swap) since both codecs
    use the same IMA algorithm with different nibble storage order.
    """
    reader = StfsReader(stfs_data)
    pws_entries = [e for e in reader.file_table if e["name"].endswith(".pws")]

    if not pws_entries:
        print("  No .pws audio files found in STFS")
        return 0

    audio_dir.mkdir(parents=True, exist_ok=True)
    print(f"\n  Extracting & transcoding {len(pws_entries)} audio files to {audio_dir}/")

    errors = 0
    for entry in pws_entries:
        xbox_data = reader.read_file(entry)
        name = entry["name"]
        try:
            pc_data = transcode_pws_file_to_pc(
                xbox_data,
                filename=name,
                add_pc_header=True,
                source_codec=CODEC_XBOX_ADPCM,
            )
        except Exception as exc:
            print(f"    ERROR {name}: {exc}", file=sys.stderr)
            errors += 1
            continue
        out_path = audio_dir / name
        out_path.write_bytes(pc_data)
        print(f"    {name} ({entry['file_size']:,} -> {len(pc_data):,} bytes, transcoded)")

    if errors:
        print(f"  {errors}/{len(pws_entries)} audio files failed transcoding",
              file=sys.stderr)
    return errors


# ── CLI ───────────────────────────────────────────────────────────────

def main() -> int:
    ap = argparse.ArgumentParser(
        description="Port Xbox 360 DLC to PC vz-patch.wad (unified tool)",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    source = ap.add_mutually_exclusive_group(required=True)
    source.add_argument("--x360-rar", type=Path,
                        help="Xbox 360 DLC RAR file")
    source.add_argument("--x360-zip", type=Path,
                        help="Xbox 360 DLC ZIP file (bsdtar handles both)")
    source.add_argument("--x360-stfs", type=Path,
                        help="STFS LIVE container or raw DLC01.doh file")

    ap.add_argument("--output", "-o", type=Path,
                    help="Output vz-patch.wad path")
    ap.add_argument("--merge-into", type=Path,
                    help="Merge DLC blocks into an existing patch WAD")
    ap.add_argument("--source-wad", type=Path, default=None,
                    help="Path to retail vz.wad. When provided, the DLC "
                         "bootstrap (dlc01 master script + modified vz script) "
                         "is injected automatically into the output WAD.")
    ap.add_argument("--no-bootstrap", action="store_true",
                    help="Skip DLC bootstrap injection even when --source-wad "
                         "is provided (produce DLC blocks only)")
    ap.add_argument("--no-hook", action="store_true",
                    help="Add dlc01 as entry 115 only — do NOT modify "
                         "wifmissionflow (use ASI to trigger import at runtime)")
    ap.add_argument("--permissive", action="store_true",
                    help="Allow blind u32 fallbacks on unknown chunks (testing only; "
                         "default is strict — unhandled tags raise)")
    ap.add_argument("--strip-audio", action="store_true",
                    help="Strip soundbank/wavebank UCFX entries from blocks when no "
                         "base-game override is available (prevents crash in "
                         "PalSoundEngine::MixSources from malformed audio data)")
    ap.add_argument("--fix-stringdb-descriptors", action="store_true",
                    help="Run heuristic SYEK/SRTS descriptor fixup (off by default; "
                         "see tools/dlc_stringdb_forensic.py)")
    ap.add_argument("--no-synth-stringdb-aset", action="store_true",
                    help="Do not add synthetic stringdb ASET rows for AddStringDb")
    ap.add_argument("--dlc-contracts", type=str, default=None,
                    help="Comma-separated DLC contract names to import "
                         "(default: dlccon001,dlccon002,dlccon003,dlccon004)")
    ap.add_argument("--max-blocks", type=int, default=None,
                    help="Limit to first N blocks (for testing)")
    ap.add_argument("--start-block", type=int, default=0,
                    help="Start at block N (default 0)")
    ap.add_argument("--verbose", "-v", action="store_true")
    ap.add_argument("--jobs", "-j", type=int, default=None,
                    help="Parallel workers for block conversion (default: CPU count; use 1 for serial)")
    ap.add_argument("--dump-dir", type=Path, default=None,
                    help="Dump intermediate block files to directory")
    ap.add_argument("--list-blocks", action="store_true",
                    help="List all DLC blocks and exit")
    ap.add_argument("--extract-audio", type=Path, default=None,
                    help="Extract .pws audio files to this directory")
    ap.add_argument("--work-dir", type=Path, default=None,
                    help="Working directory for temp files")

    args = ap.parse_args()

    # Load DOH bytes from source
    archive_path = args.x360_rar or args.x360_zip
    if archive_path:
        work = args.work_dir or Path(tempfile.mkdtemp(prefix="dlc_port_"))
        ext = archive_path.suffix.lower()
        print(f"Step 1: Extracting STFS from {ext.lstrip('.')} archive...")
        reader = extract_stfs_from_rar(archive_path, work)
        doh_entry = next(
            (e for e in reader.file_table if "doh" in e["name"].lower()), None)
        if doh_entry is None:
            print("  ERROR: No DOH file found in STFS file table")
            return 1
        doh_size = doh_entry["file_size"]
        print(f"  Reading DOH ({doh_size:,} bytes)...")
        doh = reader.read(0, doh_size)
    else:
        print(f"Step 1: Loading {args.x360_stfs}...")
        doh, src_type = load_stfs_or_doh(args.x360_stfs)
        print(f"  Source: {src_type}, size: {len(doh):,} bytes")

    if args.list_blocks:
        return cmd_list_blocks(doh)

    # Extract audio if requested (only works with archive or STFS source)
    if args.extract_audio:
        if archive_path:
            extract_dlc_audio(reader.stfs_data, args.extract_audio)
        elif args.x360_stfs:
            header = args.x360_stfs.read_bytes()[:4]
            if header in (b"CON ", b"LIVE", b"PIRS"):
                extract_dlc_audio(args.x360_stfs.read_bytes(), args.extract_audio)
            else:
                print("  NOTE: --extract-audio requires STFS source (not raw DOH)")

    if args.output is None:
        if args.extract_audio and not args.list_blocks:
            return 0
        ap.error("--output is required (unless using --list-blocks or --extract-audio only)")

    dlc_contracts = None
    if args.dlc_contracts:
        dlc_contracts = [c.strip() for c in args.dlc_contracts.split(",")]

    return port_x360_dlc(
        doh,
        output_path=args.output,
        merge_into=args.merge_into,
        source_wad=args.source_wad,
        max_blocks=args.max_blocks,
        start_block=args.start_block,
        verbose=args.verbose,
        dump_dir=args.dump_dir,
        dlc_contracts=dlc_contracts,
        no_bootstrap=args.no_bootstrap,
        no_hook=args.no_hook,
        fix_stringdb_descriptors=args.fix_stringdb_descriptors,
        synth_stringdb_aset=not args.no_synth_stringdb_aset,
        jobs=args.jobs,
        permissive=args.permissive,
        strip_audio=args.strip_audio,
    )


if __name__ == "__main__":
    sys.exit(main())
