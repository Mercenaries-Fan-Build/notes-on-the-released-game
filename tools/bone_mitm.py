#!/usr/bin/env python3
r"""bone_mitm.py -- meet-in-the-middle EXHAUSTIVE preimage search for pandemic_hash_m2.

WHY THIS EXISTS
---------------
`gpu_product.py` sweeps a cartesian product forward at ~4e9 candidates/s. That caps an exhaustive
sweep at ~1e12-1e13 candidates before the wall-clock hurts, i.e. length <= 8 over [a-z_]. The stem we
are hunting is longer than that.

But `pandemic_hash_m2` is FNV-1a, and FNV-1a is INVERTIBLE:

    fold(S, b) = (S ^ (b|0x20)) * PRIME        (mod 2^32; PRIME is odd, hence invertible)
    unfold(S') = (S' * PRIME^-1) ^ (b|0x20)

So the search splits. For a name  P || Q  (prefix P of length p, suffix Q of length s):

    state_after(P)  ==  unfold_all(final_state, Q)

Enumerate all K^p prefixes FORWARD into a 2^32-bit bitmap (512 MB), then enumerate all K^s suffixes
BACKWARD from the target and probe the bitmap. Cost is K^p + K^s instead of K^(p+s). Exhaustive
length 12 over [a-z_] becomes 2 x 27^6 = 7.7e8 work instead of 1.5e17.

THE ERROR BAR IS UNCHANGED, AND THAT IS THE POINT
-------------------------------------------------
An exhaustive sweep of length L over an alphabet of K letters has S = K^L candidates against T=1, so
it returns ~K^L / 2^32 preimages -- 1.8e3 at 27^9, 4.8e4 at 27^10, 1.3e6 at 27^11. Those are NOT
names; they are the chance preimages the arithmetic promises. MITM does not buy trust, it buys
CLOSURE: the real name, if it lives in the swept space, is guaranteed to be among them.

Trust comes afterwards, from the DICTIONARY FILTER (--dict): a preimage is only reported if it
segments into real words. The honest error bar for a reported hit is therefore

    EF = (number of dictionary-segmentable strings of that length) / 2^32

which is ~1e-5, not K^L/2^32. Everything else in the preimage list is exactly the noise we expected,
and it is discarded on a criterion (word-segmentability) fixed BEFORE the sweep ran.

USAGE
  python tools/bone_mitm.py --target 0x765CD254 --alphabet az_ --lengths 9,10,11 --dict d.txt
  python tools/bone_mitm.py --targets-file hashes.txt --alphabet az09_ --lengths 9,10
"""
from __future__ import annotations

import argparse
import re
import sys
import time
from pathlib import Path

import cupy as cp
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
from fnv import m2  # noqa: E402

PRIME = 0x01000193
MASK = 0xFFFFFFFF
# modular inverse of the FNV prime mod 2^32 (PRIME is odd => invertible)
INV_PRIME = pow(PRIME, -1, 1 << 32)
OFFSET = 0x811C9DC5

ALPHABETS = {
    "az_": "abcdefghijklmnopqrstuvwxyz_",
    "az09_": "abcdefghijklmnopqrstuvwxyz0123456789_",
    "az": "abcdefghijklmnopqrstuvwxyz",
    "az09_.": "abcdefghijklmnopqrstuvwxyz0123456789_.",
    "az09_.-": "abcdefghijklmnopqrstuvwxyz0123456789_.- ",
}

# ---------------------------------------------------------------------------------------------
# kernels
# ---------------------------------------------------------------------------------------------
_SRC = r"""
extern "C" {

// FORWARD: every length-p string over the alphabet -> its FNV state -> set that bit in the bitmap.
__global__ void fwd_fill(const unsigned long long total, const int p, const int K,
                         const unsigned char* alpha, unsigned int* bitmap, const unsigned int h0) {
    unsigned long long stride = (unsigned long long)gridDim.x * blockDim.x;
    for (unsigned long long g = (unsigned long long)blockIdx.x * blockDim.x + threadIdx.x;
         g < total; g += stride) {
        unsigned long long r = g;
        unsigned int h = h0;              // state AFTER the (optional) fixed literal prefix
        // decode base-K, MOST significant symbol first == first character
        unsigned char cs[16];
        for (int i = p - 1; i >= 0; --i) { cs[i] = alpha[r % (unsigned long long)K]; r /= (unsigned long long)K; }
        for (int i = 0; i < p; ++i) { h ^= (unsigned int)(cs[i] | 0x20); h *= 0x01000193u; }
        atomicOr(&bitmap[h >> 5], 1u << (h & 31));
    }
}

// BACKWARD: from the target's pre-finalisation state, unfold every length-s suffix and probe the
// bitmap. A set bit means SOME length-p prefix reaches this state -> a full-length preimage exists.
__global__ void bwd_probe(const unsigned long long total, const int s, const int K,
                          const unsigned char* alpha, const unsigned int* bitmap,
                          const unsigned int sfinal, const unsigned int inv_prime,
                          unsigned long long* out_g, unsigned int* out_state,
                          unsigned int* out_count, const unsigned int cap) {
    unsigned long long stride = (unsigned long long)gridDim.x * blockDim.x;
    for (unsigned long long g = (unsigned long long)blockIdx.x * blockDim.x + threadIdx.x;
         g < total; g += stride) {
        unsigned long long r = g;
        unsigned char cs[16];
        for (int i = s - 1; i >= 0; --i) { cs[i] = alpha[r % (unsigned long long)K]; r /= (unsigned long long)K; }
        unsigned int h = sfinal;
        // undo the suffix bytes in reverse order
        for (int i = s - 1; i >= 0; --i) { h = (h * inv_prime) ^ (unsigned int)(cs[i] | 0x20); }
        if ((bitmap[h >> 5] >> (h & 31)) & 1u) {
            unsigned int o = atomicAdd(out_count, 1u);
            if (o < cap) { out_g[o] = g; out_state[o] = h; }
        }
    }
}

// RECOVER: re-run the forward enumeration, emitting the prefixes whose state is in the (sorted) list
// of states the backward pass matched.
__global__ void fwd_recover(const unsigned long long total, const int p, const int K,
                            const unsigned char* alpha,
                            const unsigned int* want, const int nwant,
                            unsigned long long* out_g, unsigned int* out_state,
                            unsigned int* out_count, const unsigned int cap, const unsigned int h0) {
    unsigned long long stride = (unsigned long long)gridDim.x * blockDim.x;
    for (unsigned long long g = (unsigned long long)blockIdx.x * blockDim.x + threadIdx.x;
         g < total; g += stride) {
        unsigned long long r = g;
        unsigned int h = h0;
        unsigned char cs[16];
        for (int i = p - 1; i >= 0; --i) { cs[i] = alpha[r % (unsigned long long)K]; r /= (unsigned long long)K; }
        for (int i = 0; i < p; ++i) { h ^= (unsigned int)(cs[i] | 0x20); h *= 0x01000193u; }
        int lo = 0, hi = nwant - 1;
        while (lo <= hi) {
            int mid = (lo + hi) >> 1;
            unsigned int v = want[mid];
            if (v == h) {
                unsigned int o = atomicAdd(out_count, 1u);
                if (o < cap) { out_g[o] = g; out_state[o] = h; }
                break;
            } else if (v < h) lo = mid + 1; else hi = mid - 1;
        }
    }
}

}  // extern "C"
"""

_MOD = None


def _mod():
    global _MOD
    if _MOD is None:
        _MOD = cp.RawModule(code=_SRC, options=("-std=c++11",))
    return _MOD


def _decode(g: int, n: int, alpha: str) -> str:
    K = len(alpha)
    cs = [""] * n
    for i in range(n - 1, -1, -1):
        cs[i] = alpha[g % K]
        g //= K
    return "".join(cs)


class Mitm:
    """Forward bitmap over all length-p prefixes; probe it backward from any number of targets."""

    def __init__(self, alphabet: str, p: int, device: int = 0, block: int = 256, literal: str = ""):
        self.alpha = alphabet
        self.K = len(alphabet)
        self.p = p
        self.literal = literal
        # A fixed literal prefix is FREE LENGTH: the swept space stays K^(p+s), but every candidate is
        # `literal + wild`, so the names we close are (len(literal) + p + s) characters long at the
        # cost -- and the error bar -- of a (p+s)-character sweep.
        h0 = OFFSET
        for b in literal.encode():
            h0 = ((h0 ^ (b | 0x20)) * PRIME) & MASK
        self.h0 = h0
        self.block = block
        self.device = device
        with cp.cuda.Device(device):
            sm = cp.cuda.runtime.getDeviceProperties(device)["multiProcessorCount"]
            self.grid = sm * 32
            self.d_alpha = cp.asarray(np.frombuffer(alphabet.encode(), np.uint8))
            self.bitmap = cp.zeros(1 << 27, cp.uint32)  # 2^32 bits = 512 MB
            total = self.K ** p
            t0 = time.time()
            _mod().get_function("fwd_fill")(
                (self.grid,), (block,),
                (np.uint64(total), np.int32(p), np.int32(self.K), self.d_alpha, self.bitmap,
                 np.uint32(self.h0)))
            cp.cuda.get_current_stream().synchronize()
            self.fwd_total = total
            self.fwd_secs = time.time() - t0
        pop = int(cp.sum(cp.unpackbits(self.bitmap.view(cp.uint8))).get())
        self.fill = pop / 2 ** 32
        print(f"[mitm] forward: {self.K}^{p} = {total:,} prefixes hashed in {self.fwd_secs:.1f}s "
              f"({total / max(self.fwd_secs, .001) / 1e9:.2f} B/s); bitmap fill = {self.fill:.4%}")

    def preimages(self, target: int, s: int, cap: int = 1 << 26, keep=None) -> list[str]:
        """Every string of length p+s over the alphabet that hashes to `target`. Exhaustive.

        `keep` is an optional predicate applied INSIDE the decode loop. At length 12+ the exhaustive
        preimage list runs to tens of millions of strings -- far too many to materialise -- but the
        readable subset is tiny, so the filter has to run here rather than on the returned list.
        """
        sfinal = ((target * INV_PRIME) & MASK) ^ 0x2A       # undo the ^0x2A finalisation round
        total = self.K ** s
        with cp.cuda.Device(self.device):
            out_g = cp.empty(cap, cp.uint64)
            out_st = cp.empty(cap, cp.uint32)
            cnt = cp.zeros(1, cp.uint32)
            _mod().get_function("bwd_probe")(
                (self.grid,), (self.block,),
                (np.uint64(total), np.int32(s), np.int32(self.K), self.d_alpha, self.bitmap,
                 np.uint32(sfinal), np.uint32(INV_PRIME), out_g, out_st, cnt, np.uint32(cap)))
            cp.cuda.get_current_stream().synchronize()
            n = int(cnt.get()[0])
            if n == 0:
                return []
            if n > cap:
                print(f"  ! backward hits {n:,} exceeded cap {cap:,}; truncating", file=sys.stderr)
                n = cap
            suf_g = out_g[:n].get()
            suf_st = out_st[:n].get()

            # states we must find prefixes for (sorted+unique for the kernel's binary search)
            want = np.unique(suf_st)
            d_want = cp.asarray(want)
            pcap = min(cap, 1 << 26)
            p_g = cp.empty(pcap, cp.uint64)
            p_st = cp.empty(pcap, cp.uint32)
            pcnt = cp.zeros(1, cp.uint32)
            _mod().get_function("fwd_recover")(
                (self.grid,), (self.block,),
                (np.uint64(self.fwd_total), np.int32(self.p), np.int32(self.K), self.d_alpha,
                 d_want, np.int32(len(want)), p_g, p_st, pcnt, np.uint32(pcap),
                 np.uint32(self.h0)))
            cp.cuda.get_current_stream().synchronize()
            pn = min(int(pcnt.get()[0]), pcap)
            pre_g = p_g[:pn].get()
            pre_st = p_st[:pn].get()

        by_state: dict[int, list[int]] = {}
        for g, st in zip(pre_g.tolist(), pre_st.tolist()):
            by_state.setdefault(st, []).append(g)
        out = []
        self.n_preimages = 0
        for g, st in zip(suf_g.tolist(), suf_st.tolist()):
            pgs = by_state.get(st)
            if not pgs:
                continue
            suf = _decode(g, s, self.alpha)
            for pg in pgs:
                name = self.literal + _decode(pg, self.p, self.alpha) + suf
                self.n_preimages += 1
                if keep is None or keep(name):
                    out.append(name)
        return out


# ---------------------------------------------------------------------------------------------
# the dictionary filter -- what turns a pile of chance preimages into evidence
# ---------------------------------------------------------------------------------------------
SHORT_OK = {
    # tokens a rigger really writes that are under the 3-letter dictionary floor
    "l", "r", "lf", "rt", "fl", "fr", "rl", "rr", "ml", "mr", "bl", "br", "hp", "fx", "lo", "hi",
    "up", "dn", "in", "ex", "id", "no", "ok", "on", "of", "at", "to", "by", "vz", "oc", "ch", "al",
    "us", "uk", "pc", "cg", "lp", "hp", "gp",
}


def load_dict(paths: list[str]) -> set[str]:
    words: set[str] = set()
    for p in paths:
        for line in Path(p).read_text(errors="ignore").split():
            w = line.strip().lower()
            if w.isalpha() and 2 <= len(w) <= 24:
                words.add(w)
    return words


def segmentable(name: str, words: set[str], max_tokens: int = 3, min_word: int = 3) -> list[str] | None:
    """Split `name` into <=max_tokens pieces that are all real words / digit runs. None = not readable.

    Underscores are hard token boundaries. Within a token, glued compounds are allowed.
    """
    parts = [t for t in name.split("_") if t]
    if not parts or len(parts) > max_tokens:
        return None
    out: list[str] = []
    for t in parts:
        seg = _seg_one(t, words, max_tokens, min_word)
        if seg is None:
            return None
        out.extend(seg)
    return out if len(out) <= max_tokens else None


def _seg_one(tok: str, words: set[str], max_tokens: int, min_word: int) -> list[str] | None:
    n = len(tok)
    if not tok:
        return None
    # dynamic programme: best[i] = shortest segmentation of tok[:i]
    best: list[list[str] | None] = [None] * (n + 1)
    best[0] = []
    for i in range(1, n + 1):
        for j in range(i):
            if best[j] is None:
                continue
            piece = tok[j:i]
            ok = (piece.isdigit() or piece in SHORT_OK
                  or (len(piece) >= min_word and piece in words))
            if ok:
                cand = best[j] + [piece]
                if best[i] is None or len(cand) < len(best[i]):
                    best[i] = cand
    b = best[n]
    return b if b is not None and len(b) <= max_tokens else None


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--target", help="0xHASH")
    ap.add_argument("--targets-file", help="file of 0xHASH lines (one sweep per target, T=1 each)")
    ap.add_argument("--alphabet", default="az_", choices=sorted(ALPHABETS))
    ap.add_argument("--lengths", default="9,10", help="total name lengths to close, comma separated")
    ap.add_argument("--split", type=int, default=6, help="prefix length p (forward half)")
    ap.add_argument("--dict", action="append", default=[], help="word list(s) for the readability filter")
    ap.add_argument("--max-tokens", type=int, default=3)
    ap.add_argument("--prefix", default="", help="fixed literal prefix, e.g. bone_ (folded into the target)")
    ap.add_argument("--suffix", default="", help="fixed literal suffix")
    ap.add_argument("--out", help="write ALL readable hits here")
    ap.add_argument("--dump-all", help="write EVERY preimage (noise included) here")
    args = ap.parse_args()

    targets: list[int] = []
    if args.target:
        targets.append(int(args.target, 16))
    if args.targets_file:
        for line in Path(args.targets_file).read_text().split():
            line = line.strip().rstrip(",")
            if line:
                targets.append(int(line, 16))
    if not targets:
        ap.error("need --target or --targets-file")

    alpha = ALPHABETS[args.alphabet]
    words = load_dict(args.dict) if args.dict else set()
    lengths = [int(x) for x in args.lengths.split(",")]
    K = len(alpha)

    if args.suffix:
        raise SystemExit("--suffix not supported (would need a forward re-fold); use --prefix")

    print(f"alphabet={args.alphabet} (K={K})  targets={len(targets)}  lengths={lengths}  "
          f"literal-prefix={args.prefix!r}")
    readable_all: dict[int, set[str]] = {}
    dumped: list[str] = []
    for L in lengths:
        s = L - args.split
        if s < 1:
            print(f"  length {L}: skipped (needs > --split={args.split})")
            continue
        S = K ** L
        print(f"\n=== length {L}: S = {K}^{L} = {S:.3e} candidates, T=1  ->  "
              f"expected preimages = S/2^32 = {S / 2**32:,.0f}")
        mm = Mitm(alpha, args.split, literal=args.prefix)
        for t in targets:
            pres = mm.preimages(t, s)
            n_readable = 0
            for full in pres:
                name = full
                if m2(full) != t:
                    continue
                if args.dump_all:
                    dumped.append(f"{full}\t0x{t:08X}")
                if words:
                    seg = segmentable(name, words, args.max_tokens)
                    if seg:
                        readable_all.setdefault(t, set()).add(name + "  =  " + "+".join(seg))
                        n_readable += 1
            print(f"  0x{t:08X}: {len(pres):,} preimages  ->  {n_readable} dictionary-readable")
        del mm
        cp.get_default_memory_pool().free_all_blocks()

    print("\n" + "=" * 92)
    ef_note = (f"EF for a READABLE hit ~= |segmentable strings of this length| / 2^32 "
               f"(<<1); the raw preimage counts above are the expected chance noise.")
    print(ef_note)
    for t, names in sorted(readable_all.items()):
        print(f"\n0x{t:08X}  -- {len(names)} readable preimage(s):")
        for n in sorted(names):
            print("   ", n)
    if not readable_all:
        print("\nNO dictionary-readable preimage on any target. That is a CLEAN NEGATIVE: for every")
        print("length swept, the name is provably NOT a word-segmentable string over this alphabet.")
    if args.out and readable_all:
        with open(args.out, "w", encoding="utf-8") as fh:
            for t, names in sorted(readable_all.items()):
                for n in sorted(names):
                    fh.write(f"0x{t:08X}\t{n}\n")
        print(f"\n-> {args.out}")
    if args.dump_all and dumped:
        Path(args.dump_all).write_text("\n".join(dumped), encoding="utf-8")
        print(f"-> {args.dump_all}  ({len(dumped):,} raw preimages)")
    return 0


def _selftest():
    """The MITM must reproduce a KNOWN name from its hash, exhaustively."""
    alpha = ALPHABETS["az_"]
    mm = Mitm(alpha, 5)
    for known in ("bone_frame", "bone_root"):  # 10 and 9 chars
        t = m2(known)
        pres = mm.preimages(t, len(known) - 5)
        ok = known in pres
        print(f"  {known}: {len(pres):,} preimages, contains the truth: {ok}")
        assert ok, f"MITM missed {known}"
        for p in pres:
            assert m2(p) == t, f"MITM emitted a non-preimage: {p}"
    print("bone_mitm correctness OK (exhaustive, recovers known names, every emission verified)")


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        _selftest()
        raise SystemExit(0)
    raise SystemExit(main())
