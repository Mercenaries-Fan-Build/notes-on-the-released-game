#!/usr/bin/env python3
"""Minimal XDVDFS (Xbox / Xbox 360 disc) reader: list or extract files.

The volume descriptor (``MICROSOFT*XBOX*MEDIA``) lives at ``base + 0x10000``;
its root directory is a balanced binary tree of entries.  Each directory entry::

    +0x00 u16 left   (DWORD offset within this dir's table, 0/0xFFFF = none)
    +0x02 u16 right
    +0x04 u32 start sector
    +0x08 u32 size (bytes)
    +0x0c u8  attributes (0x10 = directory)
    +0x0d u8  name length
    +0x0e ..  name (ASCII), padded to 4 bytes

All sector numbers are relative to the partition ``base``.

Usage:
  python tools/xdvdfs_extract.py <iso> --list
  python tools/xdvdfs_extract.py <iso> --extract <out_dir> [--glob SUBSTR]
"""
from __future__ import annotations
import argparse, struct, sys
from pathlib import Path

SECTOR = 0x800
MAGIC = b"MICROSOFT*XBOX*MEDIA"
ATTR_DIR = 0x10


def find_base(f) -> int:
    for base in (0x0, 0x2080000, 0xFD90000, 0x18300000):
        f.seek(base + 0x10000)
        if f.read(20) == MAGIC:
            return base
    raise SystemExit("XDVDFS volume descriptor not found")


def read_dir(f, base, sector, size, path, entries):
    """Walk one directory's entry tree (iterative, over the whole table)."""
    f.seek(base + sector * SECTOR)
    table = f.read(size)
    # entries are reachable via the tree, but they are laid out packed; walking
    # every 4-byte-aligned record by following the tree is safest.
    stack = [0]
    seen = set()
    while stack:
        off = stack.pop()
        if off in seen or off >= len(table) or off == 0xFFFF * 4:
            continue
        seen.add(off)
        if off + 14 > len(table):
            continue
        left, right, start, fsize, attr, nlen = struct.unpack_from("<HHIIBB", table, off)
        name = table[off + 14: off + 14 + nlen].decode("latin1", "replace")
        if nlen and name not in (".", ".."):
            full = f"{path}/{name}" if path else name
            is_dir = bool(attr & ATTR_DIR)
            entries.append((full, start, fsize, is_dir))
            if is_dir and fsize:
                read_dir(f, base, start, fsize, full, entries)
        if left and left != 0xFFFF:
            stack.append(left * 4)
        if right and right != 0xFFFF:
            stack.append(right * 4)


def list_tree(iso: Path):
    f = open(iso, "rb")
    base = find_base(f)
    f.seek(base + 0x10000 + 0x14)
    root_sector, root_size = struct.unpack("<II", f.read(8))
    entries = []
    read_dir(f, base, root_sector, root_size, "", entries)
    f.close()
    return base, entries


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("iso", type=Path)
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--extract", type=Path)
    ap.add_argument("--glob", default="", help="only files whose path contains SUBSTR")
    args = ap.parse_args()

    base, entries = list_tree(args.iso)
    files = [e for e in entries if not e[3]]
    dirs = [e for e in entries if e[3]]
    print(f"base=0x{base:x}  dirs={len(dirs)}  files={len(files)}", file=sys.stderr)

    if args.list or not args.extract:
        for full, start, fsize, is_dir in sorted(entries):
            kind = "DIR " if is_dir else f"{fsize:>12,}"
            print(f"{kind}  @sec {start:<8} {full}")

    if args.extract:
        f = open(args.iso, "rb")
        n = 0
        for full, start, fsize, is_dir in files:
            if args.glob and args.glob.lower() not in full.lower():
                continue
            out = args.extract / full
            out.parent.mkdir(parents=True, exist_ok=True)
            f.seek(base + start * SECTOR)
            remaining = fsize
            with open(out, "wb") as o:
                while remaining > 0:
                    chunk = f.read(min(8 * 1024 * 1024, remaining))
                    if not chunk:
                        break
                    o.write(chunk); remaining -= len(chunk)
            n += 1
            print(f"  extracted {full} ({fsize:,} B)")
        print(f"extracted {n} files -> {args.extract}", file=sys.stderr)


if __name__ == "__main__":
    main()
