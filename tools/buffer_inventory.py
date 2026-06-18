#!/usr/bin/env python3
"""Static buffer inventory for Mercenaries2.exe.

Scans the Ghidra decompile corpus (output/_ghidra/all_functions_decomp.txt) for
FIXED-SIZE buffers that are sized for base-game density and can overflow on denser
DLC data. Two overflow classes:

  (A) Open-addressing HASH TABLES  -> infinite linear-probe livelock when full.
      Signature: a power-of-2-minus-1 mask (0x1FF..0x1FFFF) used to index an
      array, appearing >=2x in the function (initial slot + probe wrap).
      Example: anim table FUN_0067cfb0 (mask 0x3FF), the live hang.

  (B) Fixed-size ARRAYS indexed by a data count -> heap corruption when count
      exceeds the array. Signature: a stack array `xStack_NNNN [N]` (or a global
      DAT_ table) indexed by a value read from chunk data.
      Example: MTRL 10-slot, vertex-decl 16-slot.

This is a CANDIDATE generator. Every hit must be VERIFIED against the live exe
(disasm + the actual data path) before it is trusted — the decompile can be
stale or misread. Known-true sites are checked first as a detector sanity test.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path
from collections import defaultdict

CORPUS = Path("output/_ghidra/all_functions_decomp.txt")

# Power-of-2-minus-1 mask values that size a REALISTIC overflow-prone table:
# 512..8192 slots. Larger (0xFFFF+) are overwhelmingly low-bit *extraction*
# (u16 truncation, hash folding), not table indices, and a 64k table rarely
# overflows anyway; smaller (0xFF) is too common for byte ops. This window is
# where the anim table (0x3FF=1024) lives.
POW2_MINUS1 = {0x1FF, 0x3FF, 0x7FF, 0xFFF, 0x1FFF}  # 512, 1024, 2048, 4096, 8192
MASK_RE = re.compile(r"&\s*0x([0-9a-fA-F]+)\b")
# Ghidra fixed stack/array decls:  "int aiStack_2000 [1024];"  /  "undefined4 local_1000 [1023];"
ARRAY_RE = re.compile(r"^\s+\w[\w ]*?\b(\w*Stack_[0-9a-fA-F]+|local_[0-9a-fA-F]+)\s*\[(\d+)\]\s*;")
FUNC_HDR = re.compile(r"^==== (FUN_[0-9a-f]+) @0x([0-9a-f]+)")


def iter_functions(text: str):
    """Yield (name, addr, body_lines) per decompiled function."""
    cur_name = cur_addr = None
    buf: list[str] = []
    for line in text.splitlines():
        m = FUNC_HDR.match(line)
        if m:
            if cur_name:
                yield cur_name, cur_addr, buf
            cur_name, cur_addr = m.group(1), int(m.group(2), 16)
            buf = []
        else:
            buf.append(line)
    if cur_name:
        yield cur_name, cur_addr, buf


def scan():
    if not CORPUS.is_file():
        print(f"corpus not found: {CORPUS}", file=sys.stderr)
        sys.exit(1)
    text = CORPUS.read_text(errors="replace")

    hash_tables = []   # (addr, name, mask, mask_count)
    fixed_arrays = []  # (addr, name, arrname, size)

    for name, addr, body in iter_functions(text):
        joined = "\n".join(body)
        # (A) open-addressing hash tables. The DISCRIMINATOR (verified against
        # FUN_00816420, a paged-array false positive): a true probe loop does
        # `idx = (idx + 1) & MASK` — an increment folded by the mask. A paged
        # array does `arr[idx >> N][idx & MASK]` — the mask pairs with a SHIFT.
        # Require the increment-probe pattern; exclude masks that only appear
        # paired with a `>>` shift (paging).
        for mask in POW2_MINUS1:
            mhex = f"{mask:x}"
            # probe: "(x + 1) & 0xMASK"  (Ghidra prints "+ 1 & 0x3ff" / "+ 1U & 0x3ff")
            probe = re.search(rf"\+\s*1U?\s*&\s*0x0*{mhex}\b", joined)
            if not probe:
                continue
            cnt = sum(1 for mm in MASK_RE.finditer(joined) if int(mm.group(1), 16) == mask)
            # paging guard: if the index is also right-shifted by the mask's bit
            # width, it's a paged array even with an incidental "+1 & mask".
            shift = mask.bit_length()  # 0x3ff -> 10, 0xfff -> 12, ...
            paged = re.search(rf">>\s*0x?0*{shift:x}\b|>>\s*{shift}\b", joined)
            hash_tables.append((addr, name, mask, cnt, bool(paged)))
        # (B) fixed arrays of meaningful size
        for line in body:
            am = ARRAY_RE.match(line)
            if am:
                size = int(am.group(2))
                if size >= 8:  # 8+ slots; smaller are usually locals
                    fixed_arrays.append((addr, name, am.group(1), size))

    return hash_tables, fixed_arrays


def main():
    hash_tables, fixed_arrays = scan()

    # ── Detector sanity test against KNOWN overflow sites ──
    known_hash = {0x67cfb0}  # anim table (mask 0x3FF)
    print("=== DETECTOR SANITY (known sites must appear) ===")
    ht_addrs = {a for a, *_ in hash_tables}
    for a in known_hash:
        hit = "FOUND" if a in ht_addrs else "MISSED"
        masks = [f"0x{m:X}(x{c})" for ad, n, m, c, pg in hash_tables if ad == a]
        print(f"  hash-table 0x{a:06X}: {hit}  {masks}")
    print()

    # Real candidates = probe pattern AND not paged. Paged ones are listed separately.
    real = [t for t in hash_tables if not t[4]]
    paged = [t for t in hash_tables if t[4]]
    print(f"=== (A) OPEN-ADDRESSING HASH TABLES — {len(real)} candidates (probe, not paged) ===")
    print("    (idx=(idx+1)&MASK probe; overflow when full -> linear-probe LIVELOCK)")
    for addr, name, mask, cnt, pg in sorted(real, key=lambda x: (x[2], -x[3])):
        slots = mask + 1
        flag = "  <== ANIM TABLE (known)" if addr == 0x67cfb0 else ""
        print(f"  0x{addr:06X} {name}  mask=0x{mask:X} ({slots} slots, used {cnt}x){flag}")
    print(f"\n  ({len(paged)} more had +1&MASK but ALSO a matching >>shift -> paged arrays, excluded)")
    print()

    # Group fixed arrays by function, show the largest per function.
    by_fn: dict[int, list] = defaultdict(list)
    for addr, name, arrname, size in fixed_arrays:
        by_fn[addr].append((size, arrname, name))
    print(f"=== (B) FIXED-SIZE STACK ARRAYS — {len(by_fn)} functions ===")
    print("    (array[N] with N>=8; overflow if a data count exceeds N)")
    rows = []
    for addr, arrs in by_fn.items():
        arrs.sort(reverse=True)
        size, arrname, name = arrs[0]
        rows.append((size, addr, name, arrname, len(arrs)))
    for size, addr, name, arrname, narr in sorted(rows, reverse=True)[:60]:
        print(f"  0x{addr:06X} {name}  {arrname}[{size}]  ({narr} arrays in fn)")
    print(f"\n  ... ({len(rows)} functions total with fixed arrays >=8)")


if __name__ == "__main__":
    main()
