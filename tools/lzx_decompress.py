#!/usr/bin/env python3
"""Microsoft LZX decompressor (the variant used by Xbox 360 XEX / WIM).

Single continuous stream (no CAB chunk framing — the XEX block layer already
concatenated the chunks). Ported from the libmspack lzxd.c algorithm. Canonical
Huffman decode via a (len,code) dict — slower than table decode but simpler and
verifiable; fine for a one-shot extraction.

STATUS: the FIRST LZX block decodes correctly (verified byte-exact against a real
XEX PE prefix), but there is an unresolved desync at the first block->block
boundary — multi-block streams currently produce garbage past block 0. See
docs/reverse_engineer/jul08_prototype_iso.md. Do not trust output spanning more
than one LZX block until this is fixed.
"""
from __future__ import annotations

# position-slot extra bits (51 slots, enough for up to 32 MB window)
EXTRA_BITS = [0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,
              12,12,13,13,14,14,15,15,16,16,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17]
POS_BASE = [0]*51
for _i in range(1, 51):
    POS_BASE[_i] = POS_BASE[_i-1] + (1 << EXTRA_BITS[_i-1])

NUM_PRIMARY_LENGTHS = 7
MIN_MATCH = 2
NUM_CHARS = 256
PRETREE_NUM = 20
ALIGNED_NUM = 8
LENGTH_NUM = 249

VERBATIM, ALIGNED, UNCOMPRESSED = 1, 2, 3


class BitReader:
    """16-bit little-endian words; bits served MSB-first within each word."""
    __slots__ = ("d", "pos", "buf", "n")

    def __init__(self, data: bytes):
        self.d = data
        self.pos = 0
        self.buf = 0
        self.n = 0

    def _ensure(self, need: int):
        d, L = self.d, len(self.d)
        while self.n < need:
            p = self.pos
            if p + 1 < L:
                w = d[p] | (d[p+1] << 8)
            elif p < L:
                w = d[p]
            else:
                w = 0
            self.pos = p + 2
            self.buf = (self.buf << 16) | w
            self.n += 16

    def bits(self, k: int) -> int:
        if k == 0:
            return 0
        if self.n < k:
            self._ensure(k)
        self.n -= k
        v = (self.buf >> self.n) & ((1 << k) - 1)
        self.buf &= (1 << self.n) - 1  # drop consumed high bits (keep buffer small)
        return v


def build_decoder(lengths):
    """Canonical Huffman -> dict keyed (length<<20)|code -> symbol; maxlen."""
    maxlen = max(lengths) if lengths else 0
    dec = {}
    code = 0
    # bucket symbols by length, ascending symbol order preserved
    by_len = {}
    for sym, L in enumerate(lengths):
        if L:
            by_len.setdefault(L, []).append(sym)
    for L in range(1, maxlen + 1):
        for sym in by_len.get(L, ()):
            dec[(L << 20) | code] = sym
            code += 1
        code <<= 1
    return dec, maxlen


def read_sym(br: BitReader, dec, maxlen) -> int:
    code = 0
    for L in range(1, maxlen + 1):
        code = (code << 1) | br.bits(1)
        s = dec.get((L << 20) | code)
        if s is not None:
            return s
    raise ValueError("bad huffman code")


def read_lengths(lens, first, last, br):
    pre = [br.bits(4) for _ in range(PRETREE_NUM)]
    dec, ml = build_decoder(pre)
    i = first
    while i < last:
        sym = read_sym(br, dec, ml)
        if sym == 17:
            run = br.bits(4) + 4
            for _ in range(run):
                lens[i] = 0; i += 1
        elif sym == 18:
            run = br.bits(5) + 20
            for _ in range(run):
                lens[i] = 0; i += 1
        elif sym == 19:
            run = br.bits(1) + 4
            sym2 = read_sym(br, dec, ml)
            val = (lens[i] - sym2) % 17
            for _ in range(run):
                lens[i] = val; i += 1
        else:
            lens[i] = (lens[i] - sym) % 17
            i += 1


def lzx_decompress(data: bytes, window_size: int, out_size: int) -> bytes:
    wbits = window_size.bit_length() - 1
    posn_slots = {20: 42, 21: 50}.get(wbits, wbits * 2)
    main_elements = NUM_CHARS + 8 * posn_slots

    br = BitReader(data)
    out = bytearray()
    R0 = R1 = R2 = 1

    main_len = [0] * main_elements
    length_len = [0] * LENGTH_NUM

    e8 = br.bits(1)
    intel_filesize = br.bits(32) if e8 else 0

    while len(out) < out_size:
        btype = br.bits(3)
        bsize = br.bits(24)

        if btype in (VERBATIM, ALIGNED):
            aligned_dec = aligned_ml = None
            if btype == ALIGNED:
                alen = [br.bits(3) for _ in range(ALIGNED_NUM)]
                aligned_dec, aligned_ml = build_decoder(alen)
            read_lengths(main_len, 0, NUM_CHARS, br)
            read_lengths(main_len, NUM_CHARS, main_elements, br)
            main_dec, main_ml = build_decoder(main_len)
            read_lengths(length_len, 0, LENGTH_NUM, br)
            length_dec, length_ml = build_decoder(length_len)

            end = len(out) + bsize
            while len(out) < end:
                sym = read_sym(br, main_dec, main_ml)
                if sym < NUM_CHARS:
                    out.append(sym)
                    continue
                sym -= NUM_CHARS
                length_header = sym & 7
                position_slot = sym >> 3
                if length_header == NUM_PRIMARY_LENGTHS:
                    match_len = read_sym(br, length_dec, length_ml) + NUM_PRIMARY_LENGTHS + MIN_MATCH
                else:
                    match_len = length_header + MIN_MATCH

                if position_slot == 0:
                    match_off = R0
                elif position_slot == 1:
                    match_off = R1; R1 = R0; R0 = match_off
                elif position_slot == 2:
                    match_off = R2; R2 = R0; R0 = match_off
                else:
                    extra = EXTRA_BITS[position_slot]
                    if aligned_dec is not None and extra >= 3:
                        verb = br.bits(extra - 3) << 3
                        aln = read_sym(br, aligned_dec, aligned_ml)
                        formatted = POS_BASE[position_slot] + verb + aln
                    else:
                        formatted = POS_BASE[position_slot] + br.bits(extra)
                    match_off = formatted - 2
                    R2 = R1; R1 = R0; R0 = match_off

                src = len(out) - match_off
                if src < 0:
                    raise ValueError(f"match before start (src={src})")
                # copy with overlap
                for _ in range(match_len):
                    out.append(out[src]); src += 1

        elif btype == UNCOMPRESSED:
            # realign to a 16-bit boundary and read R0,R1,R2 then raw bytes
            if br.n >= 16:
                br.pos -= 2
            br.n = 0; br.buf = 0
            p = br.pos
            R0 = int.from_bytes(data[p:p+4], "little")
            R1 = int.from_bytes(data[p+4:p+8], "little")
            R2 = int.from_bytes(data[p+8:p+12], "little")
            p += 12
            out += data[p:p+bsize]
            p += bsize
            if bsize & 1:
                p += 1
            br.pos = p
        else:
            raise ValueError(f"bad block type {btype}")

    out = out[:out_size]

    # Intel E8 call translation (decode), per 32768-byte frame
    if e8 and intel_filesize and len(out) > 10:
        ob = out
        for frame in range(0, len(ob), 32768):
            if frame >= intel_filesize:
                break
            flen = min(32768, len(ob) - frame)
            i = 0
            while i < flen - 10:
                if ob[frame + i] == 0xE8:
                    cur = frame + i
                    abs_off = int.from_bytes(ob[cur+1:cur+5], "little", signed=True)
                    if -cur <= abs_off < intel_filesize:
                        rel = (abs_off - cur) if abs_off >= 0 else (abs_off + intel_filesize)
                        ob[cur+1:cur+5] = (rel & 0xFFFFFFFF).to_bytes(4, "little")
                    i += 5
                    continue
                i += 1
    return bytes(out)
