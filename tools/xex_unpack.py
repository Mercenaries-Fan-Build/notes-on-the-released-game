#!/usr/bin/env python3
"""Decrypt + decompress an Xbox 360 XEX2 to recover its embedded PE image.

Stages:
  1. Parse headers (PE data offset, security info, BaseFileFormat).
  2. Unwrap the 16-byte AES session key (AES-128-ECB with the retail or devkit
     key) and AES-128-CBC-decrypt the basefile (IV = 0).
  3. If compression == NORMAL(2): walk the block list, concatenate the LZX chunks
     into one stream (self-validating: sizes only stay consistent if the key is
     right), then LZX-decompress to the PE image.
     If compression == BASIC(1): expand the zero-run block list.
     If compression == NONE(0): the decrypted basefile is the PE image.

Usage:
  python tools/xex_unpack.py <xex> [--out <pe.bin>] [--devkit]
"""
from __future__ import annotations
import argparse, struct, sys
from pathlib import Path
from Crypto.Cipher import AES

sys.path.insert(0, str(Path(__file__).parent))

RETAIL_KEY = bytes.fromhex("20B185A59D28FDC340583FBB0896BF91")
DEVKIT_KEY = bytes(16)


def be32(d, o): return struct.unpack_from(">I", d, o)[0]
def be16(d, o): return struct.unpack_from(">H", d, o)[0]


def unpack(path: Path, devkit=False):
    d = path.read_bytes()
    assert d[:4] == b"XEX2", "not XEX2"
    pe_off = be32(d, 8)
    sec_off = be32(d, 0x10)
    optcount = be32(d, 0x14)
    opt = {}
    for i in range(optcount):
        k, v = struct.unpack_from(">II", d, 0x18 + i * 8)
        opt[k] = v

    image_size = be32(d, sec_off + 4)
    bff = opt[0x000003FF]
    enc = be16(d, bff + 4)
    comp = be16(d, bff + 6)
    print(f"  enc={enc} comp={comp}  pe_off=0x{pe_off:x} sec_off=0x{sec_off:x} image_size={image_size:,}")

    image = d[pe_off:]

    if enc:
        wrapped = d[sec_off + 0x150: sec_off + 0x160]
        kek = DEVKIT_KEY if devkit else RETAIL_KEY
        file_key = AES.new(kek, AES.MODE_ECB).decrypt(wrapped)
        print(f"  wrapped_key={wrapped.hex()}  -> file_key={file_key.hex()} ({'devkit' if devkit else 'retail'} KEK)")
        # CBC decrypt, IV=0, length multiple of 16
        n = len(image) & ~0xF
        image = AES.new(file_key, AES.MODE_CBC, bytes(16)).decrypt(image[:n])

    if comp == 2:  # NORMAL / LZX
        # BaseFileFormat normal-compression info: at bff+8: u32 window_size,
        # then first block: u32 block_size, u8 block_hash[20]
        window_size = be32(d, bff + 8)
        block_size = be32(d, bff + 12)
        print(f"  LZX window_size=0x{window_size:x} first_block_size=0x{block_size:x}")
        stream = bytearray()
        p = 0
        nblocks = 0
        while block_size:
            if p + block_size > len(image):
                raise ValueError(f"block overruns image (bad key?) p=0x{p:x} bs=0x{block_size:x} len=0x{len(image):x}")
            pnext = p + block_size
            next_size = be32(image, p)
            q = p + 4 + 20  # skip next_size(4) + block_hash(20)
            while True:
                chunk = be16(image, q); q += 2
                if chunk == 0:
                    break
                stream += image[q:q + chunk]
                q += chunk
                if q > pnext:
                    raise ValueError("chunk overruns block (bad key?)")
            p = pnext
            block_size = next_size
            nblocks += 1
        print(f"  deblocked OK: {nblocks} blocks -> {len(stream):,} B LZX stream  [AES KEY VALID]")
        # Use the vendored reference LZX decoder (mspack-faithful: includes the
        # per-frame 16-bit realignment that a naive continuous decoder misses).
        sys.path.insert(0, str(Path(__file__).parent / "external" / "x360tools"))
        from lzx_decompress import LZXDecoder
        window_bits = window_size.bit_length() - 1
        pe = LZXDecoder(window_bits).decompress(bytes(stream), image_size)
        return pe, window_size
    elif comp == 1:  # BASIC: list of (data_size, zero_size) pairs
        out = bytearray()
        q = bff + 8
        p = 0
        while q + 8 <= bff + 8 + (be32(d, bff) - 8):
            data_size = be32(d, q); zero_size = be32(d, q + 4); q += 8
            if data_size == 0 and zero_size == 0:
                break
            out += image[p:p + data_size]; p += data_size
            out += bytes(zero_size)
        return bytes(out), 0
    else:  # NONE
        return bytes(image), 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("xex", type=Path)
    ap.add_argument("--out", type=Path)
    ap.add_argument("--devkit", action="store_true")
    args = ap.parse_args()
    print(f"=== {args.xex.name}")
    pe, _ = unpack(args.xex, devkit=args.devkit)
    print(f"  PE image: {len(pe):,} B  magic={pe[:2]!r}  "
          f"{'(MZ ok)' if pe[:2]==b'MZ' else '(NOT MZ - check)'}")
    out = args.out or args.xex.with_suffix(".pe.bin")
    out.write_bytes(pe)
    print(f"  wrote {out}")


if __name__ == "__main__":
    main()
