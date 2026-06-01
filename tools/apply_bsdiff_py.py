#!/usr/bin/env python3
"""Pure-Python BSDIFF40 patch applier (no native bspatch / bsdiff4 needed).

Format: 8-byte magic 'BSDIFF40', three 8-byte off_t (control/diff lengths +
new size), then bz2(control), bz2(diff), bz2(extra). Control = triples of
(add_len, copy_len, old_seek). numpy accelerates the per-segment byte add.

Usage:
    python tools/apply_bsdiff_py.py <old> <patch> <new> [--expect-md5 HEX] [--expect-size N]
"""
from __future__ import annotations

import argparse
import bz2
import hashlib
import sys
from pathlib import Path

import numpy as np


def _offtin(b: bytes) -> int:
    y = b[7] & 0x7F
    for i in range(6, -1, -1):
        y = y * 256 + b[i]
    if b[7] & 0x80:
        y = -y
    return y


def bspatch(old: bytes, patch: bytes) -> bytes:
    if patch[:8] != b"BSDIFF40":
        raise ValueError("not a BSDIFF40 patch (magic=%r)" % patch[:8])
    ctrllen = _offtin(patch[8:16])
    datalen = _offtin(patch[16:24])
    newsize = _offtin(patch[24:32])
    p = 32
    ctrl = bz2.decompress(patch[p:p + ctrllen]); p += ctrllen
    diff = bz2.decompress(patch[p:p + datalen]); p += datalen
    extra = bz2.decompress(patch[p:])

    old_a = np.frombuffer(old, dtype=np.uint8)
    diff_a = np.frombuffer(diff, dtype=np.uint8)
    extra_a = np.frombuffer(extra, dtype=np.uint8)
    new = np.zeros(newsize, dtype=np.uint8)

    oldpos = newpos = ci = di = ei = 0
    n = len(ctrl)
    while newpos < newsize:
        if ci + 24 > n:
            raise ValueError("control block exhausted")
        x = _offtin(ctrl[ci:ci + 8])
        y = _offtin(ctrl[ci + 8:ci + 16])
        z = _offtin(ctrl[ci + 16:ci + 24])
        ci += 24
        if x:
            seg = diff_a[di:di + x].astype(np.uint16)
            seg += old_a[oldpos:oldpos + x].astype(np.uint16)
            new[newpos:newpos + x] = (seg & 0xFF).astype(np.uint8)
            newpos += x; oldpos += x; di += x
        if y:
            new[newpos:newpos + y] = extra_a[ei:ei + y]
            newpos += y; ei += y
        oldpos += z
    return new.tobytes()


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("old")
    ap.add_argument("patch")
    ap.add_argument("new")
    ap.add_argument("--expect-md5")
    ap.add_argument("--expect-size", type=int)
    args = ap.parse_args()

    old = Path(args.old).read_bytes()
    patch = Path(args.patch).read_bytes()
    out = bspatch(old, patch)
    md5 = hashlib.md5(out).hexdigest()
    print(f"output size: {len(out):,} bytes")
    print(f"output md5 : {md5}")
    ok = True
    if args.expect_size is not None:
        good = len(out) == args.expect_size
        ok &= good
        print(f"size check : {'OK' if good else 'MISMATCH (expected %d)' % args.expect_size}")
    if args.expect_md5:
        good = md5.lower() == args.expect_md5.lower()
        ok &= good
        print(f"md5 check  : {'OK' if good else 'MISMATCH (expected %s)' % args.expect_md5}")
    Path(args.new).parent.mkdir(parents=True, exist_ok=True)
    Path(args.new).write_bytes(out)
    print(f"written    : {args.new}")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
