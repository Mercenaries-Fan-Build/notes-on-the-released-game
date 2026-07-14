#!/usr/bin/env python3
"""gpu_product.py -- GPU cartesian-product hasher for bone_forge's slot/array combinations.

gpu_fast.py enumerates a CHARACTER wildcard (prefix + wild(L) + suffix). bone_forge instead enumerates
the cross-product of WORD arrays with separators between them, so it needs a different kernel: each thread
takes a global index, decomposes it (mixed radix over the slot sizes) into one token per slot, concatenates
them with the template's separators, applies the SAME normalization bone_forge uses (collapse `__` runs,
strip leading/trailing `_`), hashes with pandemic_hash_m2, and binary-searches the (small, shared-memory)
target-hash set.

Correctness is asserted against the CPU reference in __main__ and via a per-hit parity check in the caller.
"""
import numpy as np
import cupy as cp

FNV_OFFSET = 0x811C9DC5
FNV_PRIME = 0x01000193
MASK = 0xFFFFFFFF

_KERNEL = r"""
extern "C" __global__ void crackprod(
        const unsigned long long total, const int nslots,
        const int* slot_ntok, const int* slot_base,          // [nslots]
        const int* tok_off, const int* tok_len,              // [sum(slot_ntok)]
        const unsigned char* tok_bytes,
        const int* seps,                                     // [nslots-1] 1 = '_' before this slot
        const unsigned int* targets, const int ntgt,
        unsigned long long* out_g, unsigned int* out_h, unsigned int* out_count, const unsigned int cap) {
    extern __shared__ unsigned int s_tgt[];
    for (int j = threadIdx.x; j < ntgt; j += blockDim.x) s_tgt[j] = targets[j];
    __syncthreads();

    unsigned long long stride = (unsigned long long)gridDim.x * blockDim.x;
    for (unsigned long long g = (unsigned long long)blockIdx.x * blockDim.x + threadIdx.x;
         g < total; g += stride) {
        // mixed-radix decompose (last slot varies fastest)
        unsigned long long r = g;
        int idx[16];
        for (int s = nslots - 1; s >= 0; --s) { idx[s] = (int)(r % (unsigned long long)slot_ntok[s]); r /= (unsigned long long)slot_ntok[s]; }

        // build raw name: [sep]tok0 [sep]tok1 ...
        unsigned char buf[64];
        int pos = 0;
        for (int s = 0; s < nslots; ++s) {
            if (s > 0 && seps[s - 1] && pos < 63) buf[pos++] = '_';
            int ti = slot_base[s] + idx[s];
            int off = tok_off[ti], ln = tok_len[ti];
            for (int k = 0; k < ln && pos < 63; ++k) buf[pos++] = tok_bytes[off + k];
        }
        // normalize: collapse '_' runs, then strip leading/trailing '_'
        unsigned char nb[64];
        int np = 0, prev_us = 0;
        for (int k = 0; k < pos; ++k) {
            unsigned char c = buf[k];
            if (c == '_') { if (prev_us) continue; prev_us = 1; }
            else prev_us = 0;
            nb[np++] = c;
        }
        int st = 0, en = np;
        while (st < en && nb[st] == '_') ++st;
        while (en > st && nb[en - 1] == '_') --en;
        int L = en - st;
        if (L < 3 || L > 40) continue;

        // pandemic_hash_m2 (every byte folded with |0x20)
        unsigned int h = 0x811C9DC5u;
        for (int k = st; k < en; ++k) { h ^= (unsigned int)(nb[k] | 0x20); h *= 0x01000193u; }
        h = (h ^ 0x2Au) * 0x01000193u;

        int lo = 0, hi = ntgt - 1;
        while (lo <= hi) {
            int mid = (lo + hi) >> 1;
            unsigned int v = s_tgt[mid];
            if (v == h) {
                unsigned int o = atomicAdd(out_count, 1u);
                if (o < cap) { out_g[o] = g; out_h[o] = h; }
                break;
            } else if (v < h) lo = mid + 1;
            else hi = mid - 1;
        }
    }
}
"""


def normalize(raw: str) -> str:
    """Mirror the kernel's normalization (and bone_forge's): collapse '_' runs, strip ends."""
    import re
    return re.sub(r"_{2,}", "_", raw).strip("_")


def decode(g: int, slot_tokens: list[list[str]], seps: list[int]) -> str:
    """Reconstruct the candidate string for global index g (matches the kernel byte-for-byte)."""
    idx = [0] * len(slot_tokens)
    r = g
    for s in range(len(slot_tokens) - 1, -1, -1):
        n = len(slot_tokens[s])
        idx[s] = r % n
        r //= n
    raw = slot_tokens[0][idx[0]]
    for s in range(1, len(slot_tokens)):
        raw += ("_" if seps[s - 1] else "") + slot_tokens[s][idx[s]]
    return normalize(raw)


class ProductCracker:
    """Load a sorted target-hash set to the GPU once; sweep many (slots, seps) products against it."""

    def __init__(self, device: int, target_hashes, out_cap: int = 1 << 20, block: int = 256):
        self.device = device
        self.out_cap = out_cap
        self.block = block
        ts = np.array(sorted(int(t) & MASK for t in target_hashes), dtype=np.uint32)
        with cp.cuda.Device(device):
            self.targets = cp.asarray(ts)
            self.ntgt = int(len(ts))
            self.smem = max(1, self.ntgt) * 4
            sm = cp.cuda.runtime.getDeviceProperties(device)["multiProcessorCount"]
            self.grid = sm * 16
            self.out_g = cp.empty(out_cap, cp.uint64)
            self.out_h = cp.empty(out_cap, cp.uint32)
            self.out_count = cp.zeros(1, cp.uint32)
            self.kern = cp.RawKernel(_KERNEL, "crackprod")

    def sweep(self, slot_tokens: list[list[str]], seps: list[int], on_hit):
        """slot_tokens: the token list per slot (in order). seps: len nslots-1, 1='_' before that slot."""
        nslots = len(slot_tokens)
        assert nslots <= 16 and len(seps) == nslots - 1
        total = 1
        for toks in slot_tokens:
            total *= len(toks)
        if total == 0:
            return
        # flatten token byte pool
        slot_ntok, slot_base, tok_off, tok_len, pool = [], [], [], [], bytearray()
        base = 0
        for toks in slot_tokens:
            slot_ntok.append(len(toks))
            slot_base.append(base)
            for t in toks:
                tok_off.append(len(pool))
                tok_len.append(len(t))
                pool.extend(t.encode("ascii"))
                base += 1
        with cp.cuda.Device(self.device):
            d_ntok = cp.asarray(np.array(slot_ntok, np.int32))
            d_base = cp.asarray(np.array(slot_base, np.int32))
            d_off = cp.asarray(np.array(tok_off, np.int32))
            d_len = cp.asarray(np.array(tok_len, np.int32))
            d_pool = cp.asarray(np.frombuffer(bytes(pool) or b"\0", np.uint8))
            d_seps = cp.asarray(np.array(seps or [0], np.int32))
            self.out_count.fill(0)
            grid = min(self.grid, int((total + self.block - 1) // self.block))
            self.kern((grid,), (self.block,),
                      (np.uint64(total), np.int32(nslots), d_ntok, d_base, d_off, d_len, d_pool,
                       d_seps, self.targets, np.int32(self.ntgt),
                       self.out_g, self.out_h, self.out_count, np.uint32(self.out_cap)),
                      shared_mem=self.smem)
            cp.cuda.get_current_stream().synchronize()
            n = min(int(self.out_count.get()[0]), self.out_cap)
            if n:
                for g, h in zip(self.out_g[:n].get().tolist(), self.out_h[:n].get().tolist()):
                    on_hit(decode(g, slot_tokens, seps), h)


def _selftest():
    import sys
    from pathlib import Path
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    from fnv import m2
    slots = [["bone", "hp", ""], ["", "l", "r", "left"], ["wheel", "seat", "yaw", "dock"], ["", "1", "01", "left"]]
    for seps in ([1, 1, 1], [0, 1, 0], [1, 0, 1]):
        # CPU reference: every product string, normalized, hashed
        import itertools
        cpu = {}
        for combo in itertools.product(*slots):
            raw = combo[0]
            for s in range(1, len(slots)):
                raw += ("_" if seps[s - 1] else "") + combo[s]
            name = normalize(raw)
            if 3 <= len(name) <= 40:
                cpu[m2(name)] = name
        planted = list(cpu)[::3]  # target a third of the produced hashes
        pc = ProductCracker(0, planted)
        got = {}
        pc.sweep(slots, seps, lambda name, h: got.__setitem__(h, name))
        bad = [(h, n) for h, n in got.items() if m2(n) != h]
        want = set(planted)
        ok = set(got) == want and not bad
        print(f"  seps={seps}: gpu={len(got)} want={len(want)} match={set(got)==want} bad={len(bad)} -> {'OK' if ok else 'FAIL'}")
        assert ok
    print("gpu_product correctness OK (== CPU reference)")


if __name__ == "__main__":
    _selftest()
