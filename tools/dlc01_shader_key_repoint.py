#!/usr/bin/env python3
"""Repoint DLC01 MTRL pixel-shader keys that the PC build never registers.

The DLC01 shader-triage (``docs/_dlc01_shader_triage.md``) found that 219 of
1,020 DLC01 material records cite 2 shader-key hashes PC's ``FUN_0084f130``
registry never calls ``FUN_0085ac90(name, name.sho, ...)`` on:

  * ``0xf931343a`` -- 190 uses across 112 ``tinygeometry_*`` blocks
  * ``0x3973c300`` --  29 uses across  10 ``rocks01_*``     blocks

With a cited key the engine's shader-pool probe at ``FUN_008242b0(0x800)``
misses, falls back to pool slot 0 (a null sentinel), and crashes at
``0x00858DB8`` (``mov cx,[eax+0x08]`` with ``eax=0``) -- see
``docs/shader_store_format.md`` section 7. Rewriting an unregistered key
to a shader the PC build DOES register is the path-(b) landing described
in the triage.

Mapping (final; see ``docs/_dlc01_shader_name_recovery.md`` for the recovery
evidence and why path-a could not be taken):

  ``0xf931343a`` --> ``0x343af931``  (PgDiffFP; 1-tex)
  ``0x3973c300`` --> ``0x343af931``  (PgDiffFP; 1-tex)

All 219 affected records are 1-tex (verified against
``scratchpad/dlc01_shaders/dlc01_shader_refs.json``), so routing to
PgDiffFP (which already covers 94 1-tex records in DLC01) is byte-safe.

Durable Rust side: a sibling to ``mercs2_formats::model_edit::mtrl::
repoint_container_textures`` named ``repoint_container_shader_keys`` is the
planned long-term home for this operation; see
``.claude/plans/dlc01-shader-key-repoint-rust-landing.md``. This Python
one-shot exists because the DLC01 PC boot test is gated on the fix today.

Container structure (confirmed from the Rust helper
``mercs2_formats::model_edit::mtrl::repoint_container_textures``):

  Each MTRL record:
    +0    104 B  preamble (26 x u32 colour/emissive/specular params)
    +104  u16    flags
    +106  u16    tex_count (1..=10)
    +108  u32 x tex_count   texture-asset hashes
    +108 + tex_count*4   u32   pixel-shader key (target of this rewrite)
    +(record stride = 116 + tex_count*4)

Container trailer:
    "CSUM" + u32 crc32_mercs2(entire container minus trailer)

Block entry table (first bytes of each decompressed sges block):
    u32  entry_count
    entry_count x { u32 name_hash, u32 type_hash, u32 field_c, u32 chunk_size }
    chunks follow back-to-back
"""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import struct
import sys
from pathlib import Path
from types import ModuleType

THIS_DIR = Path(__file__).resolve().parent


def _load_sibling(name: str) -> ModuleType:
    """Import a sibling module from this directory without mutating sys.path.

    Avoids the ``noqa``-silencing dance needed when imports have to follow a
    ``sys.path.insert`` (which breaks the project's lint rules).
    """
    spec = importlib.util.spec_from_file_location(name, THIS_DIR / f"{name}.py")
    if spec is None or spec.loader is None:
        raise ImportError(f"cannot load {name} from {THIS_DIR}")
    mod = importlib.util.module_from_spec(spec)
    # Register in sys.modules so ``ffcs_patch_wad`` can import ``ffcs_wad``
    # etc. transitively via the same loader chain.
    sys.modules[name] = mod
    spec.loader.exec_module(mod)
    return mod


# ffcs_wad is a transitive dep of ffcs_patch_wad / sges_decompress.
_load_sibling("ffcs_wad")
ffcs_patch_wad = _load_sibling("ffcs_patch_wad")
sges_compress = _load_sibling("sges_compress")
sges_decompress = _load_sibling("sges_decompress")

FFCS_CERT_BLOB = ffcs_patch_wad.FFCS_CERT_BLOB
PAGE_SIZE = ffcs_patch_wad.PAGE_SIZE
PatchBlock = ffcs_patch_wad.PatchBlock
build_patch_wad_multi = ffcs_patch_wad.build_patch_wad_multi
crc32_mercs2 = ffcs_patch_wad.crc32_mercs2
read_patch_wad = ffcs_patch_wad.read_patch_wad
compress_sges = sges_compress.compress_sges
decompress_sges_block = sges_decompress.decompress_sges_block

# --- Target remap ---
REMAP: dict[int, int] = {
    0xF931343A: 0x343AF931,
    0x3973C300: 0x343AF931,
}

MTRL_PRE = 104  # bytes of preamble before the [flags][count] pair

# --- UCFX / MTRL helpers ---

def rd_u16_le(buf: bytes | bytearray, off: int) -> int:
    return struct.unpack_from("<H", buf, off)[0]

def rd_u32_le(buf: bytes | bytearray, off: int) -> int:
    return struct.unpack_from("<I", buf, off)[0]

def find_mtrl_chunks(container: bytes) -> list[tuple[int, int]]:
    """Return every MTRL chunk ``(abs_offset, body_size)`` inside a UCFX
    container. A multi-material model's container carries one MTRL leaf per
    material group (confirmed against DLC01 ``rocks01_*`` blocks, which have
    multiple MTRL leaves per container -- walking only the first leaf misses
    19 of 29 ``0x3973c300`` refs). This differs from the Rust helper
    ``mercs2_formats::model_edit::mtrl::find_chunk``, which returns the first
    hit only; a Rust-side upgrade to ``find_chunks`` is tracked in
    ``.claude/plans/dlc01-shader-key-repoint-rust-landing.md``.

    Record record-detection follows the same marker rule the triage extractor
    uses (``docs/_dlc01_shader_triage.md``): the u32 marker at ``pos+104``
    decodes to high-half ``tex_count`` in ``[1,10]`` and low-half flags with
    ``0x0080`` set. Preamble words that happen to look like a count must not
    be mistaken for records, so the flag bit is load-bearing.
    """
    out: list[tuple[int, int]] = []
    if len(container) < 20 or container[0:4] != b"UCFX":
        return out
    data_base = rd_u32_le(container, 4)
    n_desc = rd_u32_le(container, 16)
    for d in range(n_desc):
        off = 20 + d * 20
        if off + 20 > len(container):
            break
        if container[off:off + 4] == b"MTRL":
            row_u0 = rd_u32_le(container, off + 4)
            if row_u0 == 0xFFFFFFFF:
                continue
            body_size = rd_u32_le(container, off + 8)
            body_start = (data_base + row_u0) if data_base > 0 else (8 + row_u0)
            out.append((body_start, body_size))
    return out

def repoint_container_shader_keys(
    container: bytearray,
    remap: dict[int, int],
) -> int:
    """Walk this UCFX container's MTRL leaves and rewrite shader-key u32s per
    ``remap``. Recomputes the container CSUM if anything changed. Returns the
    number of records repointed.
    """
    chunks = find_mtrl_chunks(bytes(container))
    if not chunks:
        return 0
    changed = 0
    for mabs, msize in chunks:
        if mabs + msize > len(container):
            continue
        off = 0
        while True:
            # Record detection mirrors the triage extractor exactly: the u32
            # marker at `+104` splits as (hi16 tex_count, lo16 flags), and only
            # a count in [1,10] with `(flags & 0x0080) != 0` is a real record.
            # Walking by stride without the flag check mis-identifies preamble
            # floats whose high half happens to land in [1,10].
            marker_off = mabs + off + MTRL_PRE
            if marker_off + 4 > mabs + msize:
                break
            flags = rd_u16_le(container, marker_off)
            count = rd_u16_le(container, marker_off + 2)
            if not (1 <= count <= 10 and (flags & 0x0080)):
                break
            key_off = marker_off + 4 + count * 4
            if key_off + 4 > mabs + msize:
                break
            h = rd_u32_le(container, key_off)
            new = remap.get(h)
            if new is not None:
                struct.pack_into("<I", container, key_off, new)
                changed += 1
            off += 116 + count * 4
    if changed > 0:
        n = len(container)
        if n < 8 or bytes(container[n - 8:n - 4]) != b"CSUM":
            raise RuntimeError("container missing CSUM trailer")
        csum = crc32_mercs2(bytes(container[: n - 8]))
        struct.pack_into("<I", container, n - 4, csum)
    return changed

def parse_block_entry_table(dec: bytes) -> tuple[int, list[tuple[int, int, int, int]]]:
    """Returns ``(entry_count, [(name_hash, type_hash, field_c, chunk_size), ...])``."""
    if len(dec) < 4:
        return (0, [])
    count = rd_u32_le(dec, 0)
    entries = []
    for i in range(count):
        base = 4 + i * 16
        if base + 16 > len(dec):
            break
        entries.append((
            rd_u32_le(dec, base),
            rd_u32_le(dec, base + 4),
            rd_u32_le(dec, base + 8),
            rd_u32_le(dec, base + 12),
        ))
    return (count, entries)

def process_block(dec: bytearray) -> tuple[int, int]:
    """Walk a decompressed block's containers; apply ``repoint_container_shader_keys``
    to each. Returns ``(containers_touched, keys_repointed)``."""
    count, entries = parse_block_entry_table(bytes(dec))
    header_end = 4 + count * 16
    pos = header_end
    containers_touched = 0
    keys_repointed = 0
    for _name_hash, _type_hash, _field_c, chunk_size in entries:
        if chunk_size == 0:
            continue
        if pos + chunk_size > len(dec):
            break
        container_slice = dec[pos:pos + chunk_size]
        n = repoint_container_shader_keys(container_slice, REMAP)
        if n > 0:
            dec[pos:pos + chunk_size] = container_slice
            containers_touched += 1
            keys_repointed += n
        pos += chunk_size
    return (containers_touched, keys_repointed)

# --- WAD-level driver ---

def sha256(buf: bytes) -> str:
    return hashlib.sha256(buf).hexdigest()

def _read_csum_meta(raw: bytes) -> int | None:
    """FFCS CSUM row: 4 bytes tag + u32 value + u32 meta. We preserve the meta."""
    for i in range(5):
        row_off = 0x0C + i * 12
        if raw[row_off:row_off + 4] == b"CSUM":
            return struct.unpack_from("<I", raw, row_off + 8)[0]
    return None

def _read_cert_blob(raw: bytes) -> bytes:
    """FFCS cert blob at header offset 0x48 (144 bytes). Preserve it verbatim."""
    return bytes(raw[0x48:0x48 + 144])

def repoint_wad(src: Path, dst: Path, report: Path) -> dict:
    raw = src.read_bytes()
    src_sha = sha256(raw)
    csum_meta = _read_csum_meta(raw)
    cert = _read_cert_blob(raw)

    contents = read_patch_wad(src)
    print(f"Loaded {src} ({len(raw):,} B, sha256={src_sha}): {len(contents.blocks)} blocks")

    totals = {"blocks_touched": 0, "containers_touched": 0, "keys_repointed": 0}
    per_block_log = []

    new_blocks: list = []
    for i, blk in enumerate(contents.blocks):
        try:
            dec_bytes = decompress_sges_block(
                blk.compressed_data, 0, len(blk.compressed_data)
            )
        except Exception as exc:
            # Non-sges / stored blocks: pass through unchanged. Loudly log --
            # a passthrough that is actually a decode failure the WAD depends on
            # would otherwise hide here.
            per_block_log.append({
                "block_index": i,
                "path": blk.path_string,
                "status": "passthrough-not-sges",
                "detail": str(exc),
            })
            print(f"  block {i:5d}  {blk.path_string}: PASSTHROUGH (not sges): {exc}")
            new_blocks.append(blk)
            continue

        dec = bytearray(dec_bytes)
        containers_touched, keys_repointed = process_block(dec)
        if keys_repointed == 0:
            # Keep the original compressed bytes (perfectly byte-identical).
            new_blocks.append(blk)
            continue

        # Recompress the mutated decompressed data.
        recompressed = compress_sges(bytes(dec))
        new_blk = PatchBlock(
            compressed_data=recompressed,
            path_string=blk.path_string,
            aset_entries=blk.aset_entries,
            # Keep the Xbox tier byte (hi 8 bits) and update the decompressed
            # page count (low 24 bits) to match the new decompressed size,
            # which is unchanged since we only mutate 8 bytes per MTRL record.
            packed_field=(blk.packed_field & 0xFF000000)
                         | (((len(dec) + PAGE_SIZE - 1) // PAGE_SIZE) & 0x00FFFFFF),
            flags=blk.flags,
        )
        new_blocks.append(new_blk)
        totals["blocks_touched"] += 1
        totals["containers_touched"] += containers_touched
        totals["keys_repointed"] += keys_repointed
        per_block_log.append({
            "block_index": i,
            "path": blk.path_string,
            "status": "rewritten",
            "containers_touched": containers_touched,
            "keys_repointed": keys_repointed,
            "orig_compressed_size": len(blk.compressed_data),
            "new_compressed_size": len(recompressed),
        })
        print(
            f"  block {i:5d}  {blk.path_string}: "
            f"{containers_touched} container(s) touched, "
            f"{keys_repointed} key(s) repointed "
            f"[{len(blk.compressed_data):,}B -> {len(recompressed):,}B]"
        )

    # Build the output WAD. Block ORDER is preserved, so ASET packed-block-ref
    # high half (block index) stays valid. The Python builder's u32_2 remap uses
    # the enumerated block index -- unchanged for all blocks.
    out = build_patch_wad_multi(
        blocks=new_blocks,
        csum_value=contents.csum_value,
        csum_meta=csum_meta,
        cert_blob=cert,
    )
    dst.parent.mkdir(parents=True, exist_ok=True)
    dst.write_bytes(out)
    dst_sha = sha256(out)
    print(f"\nWrote {dst} ({len(out):,} B, sha256={dst_sha})")
    print(f"  blocks_touched={totals['blocks_touched']}  "
          f"containers_touched={totals['containers_touched']}  "
          f"keys_repointed={totals['keys_repointed']}")

    rep = {
        "input": {"path": str(src), "sha256": src_sha, "size": len(raw)},
        "output": {"path": str(dst), "sha256": dst_sha, "size": len(out)},
        "remap": {f"0x{k:08x}": f"0x{v:08x}" for k, v in REMAP.items()},
        "totals": totals,
        "per_block": per_block_log,
    }
    report.parent.mkdir(parents=True, exist_ok=True)
    report.write_text(json.dumps(rep, indent=2))
    return rep

def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--input", required=True, type=Path,
                    help="DLC01 patch WAD to rewrite (e.g. the pre-landed "
                         "ps3_dlc_patch_with_xbox_oracle.wad)")
    ap.add_argument("--output", required=True, type=Path,
                    help="Destination patch WAD path")
    ap.add_argument("--report", type=Path, default=None,
                    help="Where to write the JSON report (default: <output>.repoint.json)")
    args = ap.parse_args()
    report = args.report or args.output.with_suffix(args.output.suffix + ".repoint.json")
    repoint_wad(args.input, args.output, report)
    return 0

if __name__ == "__main__":
    sys.exit(main())
