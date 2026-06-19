#!/usr/bin/env python3
"""Patch Mercenaries 2 EXE for DLC patch-WAD compatibility.

Fixes applied:

1. Animation hash table expansion (0x67CFB0–0x67D560):
   The game builds a 1024-slot open-addressing hash table on the stack to track
   animation asset overrides from patch WADs. With the DLC patch WAD containing
   2,609 animation entries, the table overflows and the linear probe loop at
   0x67D130 livelocks. This patch expands to 4096 entries:
     - Table entry count: 0x400 (1024) -> 0x1000 (4096)
     - Hash mask:         0x3FF       -> 0xFFF
     - Stack allocation:  0x2028      -> 0x8028
     - Hash table offset: 0x1038      -> 0x4038
     - Parameter offsets:  0x203C etc  -> 0x803C

2. Hash-zero sentinel fix (0x67D4AD):
   DLC animation data can contain hash=0 records which collide with the empty-slot
   sentinel. The "not found" path dereferences a NULL group extension pointer.
   Patched to skip to the next record.

3. Texture BODY null-reader guard (0x750B90):
   DLC textures may have a BODY chunk in the index but no accessible data (the
   chunk data reader returns NULL). The texture upload loop at 0x750BA2 dereferences
   the reader at 0x750BD9 without a NULL check, causing an access violation on
   textures like "jungle_env_treemedium03_nm". Patched to check the reader pointer
   instead of the mip surface count before entering the upload loop.

4. Effect object NULL-pointer guard (0x858DA4):
   Function 0x858790 evaluates animation/particle effect streams and looks up
   effect objects by hash in a 2048-slot global table (0x1979A40). DLC streams
   reference hashes for objects not present in the base game's table; the lookup
   returns -1 and the fallback pointer (0x1977A3C) is NULL. The original code
   dereferences NULL+8 at 0x858DB8. Patched to skip the dereference on both
   "not found" and "found but NULL pointer" cases.

5. Vertex declaration stream index bounds clamp (0x74D7F9, 0x74D828):
   Function 0x74D6D0 validates/converts vertex element arrays for mesh rendering.
   It accumulates per-stream byte strides in a 16-slot stack array (indices 0-15,
   matching D3D9's maximum stream count). DLC mesh vertex elements can have stream
   indices > 15 (observed: 0x235F), causing array overflows into a PAGE_READONLY
   region and crashing at 0x74D839 (add [esp+ecx*4+0x20], edx). Patched with
   AND 0xF to clamp the stream index at both the stride read and write sites.

All patches use fixed-size in-place replacements — no instruction boundaries shift,
no jump targets outside the patch window are affected.

Usage:
  python tools/patch_anim_table.py <cracked_exe> [-o <output>] [--dry-run] [--verify-only]

Requires the cracked EXE (53,482,288 bytes) produced by apply_securom_patch.py.
"""
from __future__ import annotations

import argparse
import struct
import sys
from pathlib import Path

IMAGE_BASE = 0x0040_0000

# ─── PE section mapping ─────────────────────────────────────────────────────

def _rva_to_file_offset(pe_data: bytes, rva: int) -> int:
    """Convert an RVA to a file offset using the PE section table."""
    e_lfanew = struct.unpack_from("<I", pe_data, 0x3C)[0]
    # COFF header starts at e_lfanew + 4 (skip PE\0\0 signature)
    coff_off = e_lfanew + 4
    num_sections = struct.unpack_from("<H", pe_data, coff_off + 2)[0]
    optional_hdr_size = struct.unpack_from("<H", pe_data, coff_off + 16)[0]
    section_table = coff_off + 20 + optional_hdr_size

    for i in range(num_sections):
        sec = section_table + i * 40
        virt_size = struct.unpack_from("<I", pe_data, sec + 8)[0]
        virt_addr = struct.unpack_from("<I", pe_data, sec + 12)[0]
        raw_size = struct.unpack_from("<I", pe_data, sec + 16)[0]
        raw_ptr = struct.unpack_from("<I", pe_data, sec + 20)[0]
        if virt_addr <= rva < virt_addr + max(virt_size, raw_size):
            return rva - virt_addr + raw_ptr

    raise ValueError(f"RVA 0x{rva:X} not found in any PE section")


def va_to_offset(pe_data: bytes, va: int) -> int:
    return _rva_to_file_offset(pe_data, va - IMAGE_BASE)


# ─── Patch catalog ──────────────────────────────────────────────────────────
#
# Each entry: (virtual_address, expected_bytes, patched_bytes, description)
#
# The function at 0x67CFB0 uses an esp-based stack frame with this layout
# (after 4 callee-saves: push ebx/ebp/esi/edi):
#
#   esp+0x0000 .. esp+0x0037  locals          (56 bytes, unchanged)
#   esp+0x0038 .. esp+0x1037  refcount table  (0x400 dwords -> 0x1000 dwords)
#   esp+0x1038 .. esp+0x2037  hash table      (0x400 dwords -> 0x1000 dwords)
#   esp+0x2038+              return addr, params
#
# After expansion:
#   esp+0x0038 .. esp+0x4037  refcount table  (0x1000 dwords = 0x4000 bytes)
#   esp+0x4038 .. esp+0x8037  hash table      (0x1000 dwords = 0x4000 bytes)

PATCHES: list[tuple[int, bytes, bytes, str]] = [
    # ── A. Stack allocation (prologue + epilogue) ────────────────────────
    (0x67CFB0,
     bytes.fromhex("B828200000"),
     bytes.fromhex("B828800000"),
     "mov eax, 0x2028 -> 0x8028  (stack frame via __chkstk)"),
    (0x67D55A,
     bytes.fromhex("81C428200000"),
     bytes.fromhex("81C428800000"),
     "add esp, 0x2028 -> 0x8028  (stack frame teardown)"),

    # ── B. Table size: 0x400 -> 0x1000 ───────────────────────────────────
    (0x67D093,
     bytes.fromhex("B900040000"),
     bytes.fromhex("B900100000"),
     "mov ecx, 0x400 -> 0x1000  (initial hash table zero-fill count)"),
    (0x67D0D0,
     bytes.fromhex("B900040000"),
     bytes.fromhex("B900100000"),
     "mov ecx, 0x400 -> 0x1000  (per-pass hash table zero-fill count)"),
    (0x67D0FA,
     bytes.fromhex("6800040000"),
     bytes.fromhex("6800100000"),
     "push 0x400 -> 0x1000  (lookup function table-size arg, pass 1)"),
    (0x67D413,
     bytes.fromhex("3D00040000"),
     bytes.fromhex("3D00100000"),
     "cmp eax, 0x400 -> 0x1000  (slot iteration limit)"),
    (0x67D42A,
     bytes.fromhex("B900040000"),
     bytes.fromhex("B900100000"),
     "mov ecx, 0x400 -> 0x1000  (pass-2 hash table zero-fill count)"),
    (0x67D469,
     bytes.fromhex("6800040000"),
     bytes.fromhex("6800100000"),
     "push 0x400 -> 0x1000  (lookup function table-size arg, pass 2)"),

    # ── C. Hash mask: 0x3FF -> 0xFFF ─────────────────────────────────────
    (0x67D122,
     bytes.fromhex("25FF030000"),
     bytes.fromhex("25FF0F0000"),
     "and eax, 0x3FF -> 0xFFF  (initial hash slot, pass 1)"),
    (0x67D133,
     bytes.fromhex("25FF030000"),
     bytes.fromhex("25FF0F0000"),
     "and eax, 0x3FF -> 0xFFF  (probe wrap mask, pass 1)"),
    (0x67D4C7,
     bytes.fromhex("25FF030000"),
     bytes.fromhex("25FF0F0000"),
     "and eax, 0x3FF -> 0xFFF  (initial hash slot, pass 2)"),
    (0x67D4E3,
     bytes.fromhex("25FF030000"),
     bytes.fromhex("25FF0F0000"),
     "and eax, 0x3FF -> 0xFFF  (probe wrap mask, pass 2)"),

    # ── D. Hash table base offset: 0x1038/103C/1050 -> 0x4038/403C/4050 ─
    # These shift because the refcount table below grew by 0x3000 bytes.
    (0x67D098,
     bytes.fromhex("8DBC2450100000"),
     bytes.fromhex("8DBC2450400000"),
     "lea edi, [esp+0x1050] -> 0x4050  (hash table ptr, ESP is inner-0x18)"),
    (0x67D0D5,
     bytes.fromhex("8DBC2438100000"),
     bytes.fromhex("8DBC2438400000"),
     "lea edi, [esp+0x1038] -> 0x4038  (per-pass zero-fill target)"),
    (0x67D0FF,
     bytes.fromhex("8DB4243C100000"),
     bytes.fromhex("8DB4243C400000"),
     "lea esi, [esp+0x103C] -> 0x403C  (lookup table ptr, pass 1, ESP+push)"),
    (0x67D127,
     bytes.fromhex("39948438100000"),
     bytes.fromhex("39948438400000"),
     "cmp [esp+eax*4+0x1038], edx -> 0x4038  (hash check, pass 1)"),
    (0x67D138,
     bytes.fromhex("83BC843810000000"),
     bytes.fromhex("83BC843840000000"),
     "cmp [esp+eax*4+0x1038], 0 -> 0x4038  (probe empty check, pass 1)"),
    (0x67D142,
     bytes.fromhex("898C8438100000"),
     bytes.fromhex("898C8438400000"),
     "mov [esp+eax*4+0x1038], ecx -> 0x4038  (insert hash, pass 1)"),
    (0x67D3B5,
     bytes.fromhex("8B9C8438100000"),
     bytes.fromhex("8B9C8438400000"),
     "mov ebx, [esp+eax*4+0x1038] -> 0x4038  (read hash for redistribution)"),
    (0x67D42F,
     bytes.fromhex("8DBC2438100000"),
     bytes.fromhex("8DBC2438400000"),
     "lea edi, [esp+0x1038] -> 0x4038  (pass-2 zero-fill target)"),
    (0x67D46E,
     bytes.fromhex("8DB4243C100000"),
     bytes.fromhex("8DB4243C400000"),
     "lea esi, [esp+0x103C] -> 0x403C  (lookup table ptr, pass 2, ESP+push)"),
    (0x67D4CC,
     bytes.fromhex("399C8438100000"),
     bytes.fromhex("399C8438400000"),
     "cmp [esp+eax*4+0x1038], ebx -> 0x4038  (hash check, pass 2)"),
    (0x67D4E8,
     bytes.fromhex("83BC843810000000"),
     bytes.fromhex("83BC843840000000"),
     "cmp [esp+eax*4+0x1038], 0 -> 0x4038  (probe empty check, pass 2)"),
    (0x67D4F2,
     bytes.fromhex("898C8438100000"),
     bytes.fromhex("898C8438400000"),
     "mov [esp+eax*4+0x1038], ecx -> 0x4038  (insert hash, pass 2)"),

    # ── E. Parameter/caller-frame offsets (shifted by +0x6000) ──────────
    # The first parameter was at esp+0x2034 (2-push depth) / esp+0x203C
    # (4-push depth) / esp+0x2048 (4-push + 3 call-args depth).
    (0x67CFBC,
     bytes.fromhex("8BAC2434200000"),
     bytes.fromhex("8BAC2434800000"),
     "mov ebp, [esp+0x2034] -> 0x8034  (param, after push ebx/ebp)"),
    (0x67D208,
     bytes.fromhex("8B94243C200000"),
     bytes.fromhex("8B94243C800000"),
     "mov edx, [esp+0x203C] -> 0x803C  (param access)"),
    (0x67D298,
     bytes.fromhex("8B8C243C200000"),
     bytes.fromhex("8B8C243C800000"),
     "mov ecx, [esp+0x203C] -> 0x803C  (param access)"),
    (0x67D301,
     bytes.fromhex("8B8C2448200000"),
     bytes.fromhex("8B8C2448800000"),
     "mov ecx, [esp+0x2048] -> 0x8048  (param, ESP is inner-0x0C)"),
    (0x67D398,
     bytes.fromhex("8B8C243C200000"),
     bytes.fromhex("8B8C243C800000"),
     "mov ecx, [esp+0x203C] -> 0x803C  (param access)"),
    (0x67D3C0,
     bytes.fromhex("8B94243C200000"),
     bytes.fromhex("8B94243C800000"),
     "mov edx, [esp+0x203C] -> 0x803C  (param access)"),
    (0x67D41E,
     bytes.fromhex("8B94243C200000"),
     bytes.fromhex("8B94243C800000"),
     "mov edx, [esp+0x203C] -> 0x803C  (param access)"),
    (0x67D450,
     bytes.fromhex("8B84243C200000"),
     bytes.fromhex("8B84243C800000"),
     "mov eax, [esp+0x203C] -> 0x803C  (param access)"),
    (0x67D48B,
     bytes.fromhex("8B94243C200000"),
     bytes.fromhex("8B94243C800000"),
     "mov edx, [esp+0x203C] -> 0x803C  (param access)"),
    (0x67D513,
     bytes.fromhex("8B8C243C200000"),
     bytes.fromhex("8B8C243C800000"),
     "mov ecx, [esp+0x203C] -> 0x803C  (param access)"),
    (0x67D538,
     bytes.fromhex("8BAC243C200000"),
     bytes.fromhex("8BAC243C800000"),
     "mov ebp, [esp+0x203C] -> 0x803C  (param access)"),

    # ── F. Hash-zero sentinel fix ─────────────────────────────────────
    # The hash table uses 0 as "empty slot" sentinel.  DLC animation
    # data can contain hash=0 records, which the lookup rejects.  The
    # "not found" path dereferences [group+0x10] which is always NULL
    # (initialized at 0x67D310, never written).  Skip to next record.
    (0x67D4AD,
     bytes.fromhex("83C710EB06"),
     bytes.fromhex("EB64909090"),
     "hash-zero sentinel fix: skip NULL group extension path -> jmp 0x67D513"),

    # ── G. Texture BODY null-reader guard ─────────────────────────────
    # Function 0x750A30 processes texture chunks (NAME/INFO/BODY).  For
    # the BODY branch, 0x464780 returns a data reader object; when the
    # BODY data is missing (DLC asset), it returns NULL, stored at
    # [esp+0x18].  The mip upload loop at 0x750BA2 dereferences it at
    # 0x750BD9 (mov ebp,[ecx]) without a NULL check.
    #
    # The pre-loop guard at 0x750B8D: cmp [esp+0x14],ebx / jle 0x750C2E
    # checks the mip surface count.  By changing the CMP operand from
    # [esp+0x14] to [esp+0x18], we check the data reader pointer instead.
    # When NULL (== EBX == 0), jle skips the loop; when valid (positive
    # user-mode pointer), jle falls through into the loop normally.
    # One-byte change: displacement 0x14 -> 0x18.
    (0x750B90,
     bytes.fromhex("14"),
     bytes.fromhex("18"),
     "texture BODY null-reader guard: cmp [esp+0x14] -> [esp+0x18] (skip mip loop if reader NULL)"),

    # ── H. Effect object NULL-pointer guard (0x858DA4) ─────────────────
    # Function 0x858790 evaluates animation/particle effect streams.  At
    # 0x858D9C it calls the hash lookup (0x8242B0) to find an effect
    # object by hash in the global table at 0x1979A40 (2048 slots).
    # When the lookup fails (returns -1), the fallback path loads a
    # default pointer from 0x1977A3C — which is NULL.  The code then
    # dereferences NULL+8 at 0x858DB8: mov cx,[eax+0x08].
    #
    # DLC animation streams reference effect hashes that don't exist in
    # the base game's runtime object table, triggering this crash.
    #
    # Fix: restructure the 24-byte sequence to add a NULL guard.
    # - If lookup returns <0 (not found): jl past dereference to 0x858DBC
    # - If found but pointer is NULL: jz past dereference to 0x858DBC
    # - The fallback path (mov eax,0x1977A3C) is removed since it also
    #   yields NULL and would crash identically.
    # - On skip, CX retains its stale value (harmless metadata write at
    #   0x858DDF); all subsequent float/stream operations proceed normally.
    #
    # Original 24 bytes at 0x858DA4:
    #   test eax,eax / jnl+7 / mov eax,0x1977A3C / jmp+7 /
    #   lea eax,[eax*4+0x1977A40] / mov eax,[eax] / mov cx,[eax+8]
    #
    # Patched 24 bytes:
    #   test eax,eax / jl+0x14(→0x858DBC) /
    #   lea eax,[eax*4+0x1977A40] / mov eax,[eax] /
    #   test eax,eax / jz+0x07(→0x858DBC) /
    #   mov cx,[eax+8] / nop;nop;nop
    (0x858DA4,
     bytes.fromhex("85C07D07B83C7A9701EB078D0485407A97018B00668B4808"),
     bytes.fromhex("85C07C148D0485407A97018B0085C07407668B4808909090"),
     "effect object NULL-pointer guard: skip dereference when hash not found or object ptr NULL"),

    # ── I. Vertex declaration stream index bounds clamp (0x74D7F9) ────────
    # Function 0x74D6D0 validates and converts a vertex element array.  It
    # maintains a 16-slot stride accumulator on the stack ([esp+0x20], 64
    # bytes, indices 0-15 for D3D9 streams).  DLC mesh data can contain
    # vertex elements with stream indices > 15 (e.g. 0x235F), causing a
    # write to [esp+ecx*4+0x20] that overflows into a PAGE_READONLY region
    # and crashes at 0x74D839.
    #
    # Fix: clamp the stream index to 0-15 with AND 0xF before any array
    # access.  Two sites patched:
    #   I-a: After loading the stream index, clamp via AND before storing to
    #        the output element and reading the stride accumulator.  Removes
    #        a redundant reload (original had two identical movzx loads).
    #   I-b: At the stride accumulator write, clamp the reloaded stream
    #        index via AND.  Removes dead LEA (result overwritten next iter).
    (0x74D7F9,
     bytes.fromhex("0fb714f1668957fc0fb714f10fb7549420"),
     bytes.fromhex("0fb714f183e20f668957fc0fb754942090"),
     "vtxdecl stream index clamp (read): and edx,0xF before stride array read"),

    (0x74D828,
     bytes.fromhex("0fb70cf10fb6d38d14528b14953876b90001548c208d4c8c20"),
     bytes.fromhex("0fb70cf183e10f0fb6d38d14528b14953876b90001548c2090"),
     "vtxdecl stream index clamp (write): and ecx,0xF before stride accumulator add"),
]


def verify_patches(data: bytes) -> tuple[int, int, list[str]]:
    """Check all patch sites. Returns (ok_count, fail_count, error_messages)."""
    ok = 0
    fail = 0
    errors: list[str] = []

    for va, expected, _patched, desc in PATCHES:
        off = va_to_offset(data, va)
        actual = data[off : off + len(expected)]
        if actual == expected:
            ok += 1
        elif actual == _patched:
            ok += 1  # already patched
        else:
            fail += 1
            errors.append(
                f"  MISMATCH at VA 0x{va:08X} (file +0x{off:X}): "
                f"expected {expected.hex()} got {actual.hex()}\n"
                f"    {desc}"
            )
    return ok, fail, errors


def apply_patches(data: bytearray) -> int:
    """Apply all patches in-place. Returns count of patches applied."""
    applied = 0
    for va, expected, patched, desc in PATCHES:
        off = va_to_offset(bytes(data), va)
        actual = data[off : off + len(expected)]
        if actual == expected:
            data[off : off + len(patched)] = patched
            applied += 1
        elif actual == patched:
            pass  # already patched, skip
        else:
            raise RuntimeError(
                f"Unexpected bytes at VA 0x{va:08X} (file +0x{off:X}): "
                f"expected {expected.hex()}, got {actual.hex()}\n"
                f"  {desc}"
            )
    return applied


def is_already_patched(data: bytes) -> bool:
    """True if all sites match the patched bytes."""
    for va, _expected, patched, _desc in PATCHES:
        off = va_to_offset(data, va)
        if data[off : off + len(patched)] != patched:
            return False
    return True


def print_catalog() -> None:
    """Print the full patch catalog to stdout."""
    print(f"Animation hash table patch catalog -- {len(PATCHES)} sites\n")
    print(f"{'VA':>10}  {'Size':>4}  {'Original':>20}  {'Patched':>20}  Description")
    print("-" * 100)
    for va, expected, patched, desc in PATCHES:
        print(
            f"0x{va:08X}  {len(expected):>4}  "
            f"{expected.hex():>20}  {patched.hex():>20}  {desc}"
        )


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Expand Mercenaries 2 animation hash table from 1024 to 4096 entries"
    )
    parser.add_argument("exe", nargs="?", help="Path to cracked Mercenaries2.exe")
    parser.add_argument(
        "-o", "--output",
        help="Output path (default: overwrite in place)",
    )
    parser.add_argument(
        "--dry-run", action="store_true",
        help="Verify all patch sites without writing",
    )
    parser.add_argument(
        "--verify-only", action="store_true",
        help="Check if patches are already applied",
    )
    parser.add_argument(
        "--catalog", action="store_true",
        help="Print the full patch catalog and exit",
    )
    args = parser.parse_args()

    if args.catalog:
        print_catalog()
        return

    if not args.exe:
        parser.error("exe argument is required (unless --catalog)")

    exe_path = Path(args.exe)
    if not exe_path.is_file():
        print(f"error: {exe_path} not found", file=sys.stderr)
        sys.exit(1)

    data = exe_path.read_bytes()
    print(f"Loaded {exe_path.name} ({len(data):,} bytes)")

    # Sanity check: PE signature
    if data[:2] != b"MZ":
        print("error: not a valid PE executable (no MZ header)", file=sys.stderr)
        sys.exit(1)

    if args.verify_only:
        if is_already_patched(data):
            print(f"OK: all {len(PATCHES)} patch sites match patched values")
        else:
            ok, fail, errors = verify_patches(data)
            if fail == 0:
                print(f"OK: all {ok} sites match original (1024-entry) values -- not yet patched")
            else:
                print(f"MIXED: {ok} ok, {fail} mismatched:")
                for e in errors:
                    print(e)
                sys.exit(1)
        return

    # Pre-flight: verify all expected bytes
    ok, fail, errors = verify_patches(data)
    if fail > 0:
        if is_already_patched(data):
            print("Already patched -- nothing to do")
            return
        print(f"ERROR: {fail} patch site(s) have unexpected bytes:", file=sys.stderr)
        for e in errors:
            print(e, file=sys.stderr)
        sys.exit(1)

    if args.dry_run:
        print(f"Dry run: all {ok} patch sites verified OK")
        print(f"  {len(PATCHES)} patches would be applied")
        return

    # Apply
    buf = bytearray(data)
    applied = apply_patches(buf)
    print(f"Applied {applied}/{len(PATCHES)} patches")

    out_path = Path(args.output) if args.output else exe_path
    out_path.write_bytes(bytes(buf))
    print(f"Written to {out_path} ({len(buf):,} bytes)")

    # Post-verify
    check = out_path.read_bytes()
    if is_already_patched(check):
        print("Post-verify: OK -- all sites match expanded values")
    else:
        print("WARNING: post-verify failed!", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
