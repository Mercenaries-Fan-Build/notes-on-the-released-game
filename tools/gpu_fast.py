#!/usr/bin/env python3
"""gpu_fast.py -- optimized FNV brute kernel for `<prefix> + wild(L) + <suffix>`.

The general kernel was MEMORY-bound: each candidate did a random read into a 512 MB membership bitmap
(cache-miss every time) -> ~3.7 G/s regardless of compute. Fix: the target set is small (~thousands), so
load the SORTED target hashes into SHARED memory once per block and binary-search there (on-chip, ~1-cycle
access) -- no global random access at all. Plus constant-37 peel + precomputed prefix + pre-folded alphabet.

Correctness checked against fnv.m2 in __main__. `wild_str` maps a hit's global index back to its string.
"""
import numpy as np
import cupy as cp
from fnv import ALPHABET, FNV_OFFSET, FNV_PRIME, MASK, m2

_FOLD = ",".join(str(b | 0x20) for b in ALPHABET.encode("ascii"))

_TEMPLATE = r"""
__device__ __constant__ unsigned char FOLD[37] = {__FOLD__};
extern "C" __global__ void crackw(
        const unsigned long long start, const unsigned long long total, const unsigned long long count,
        const unsigned int h0, const unsigned char* suf, const int suflen,
        const unsigned int* targets, const int ntgt,
        unsigned long long* out_g, unsigned int* out_h, unsigned int* out_count, const unsigned int cap) {
    extern __shared__ unsigned int s_tgt[];               // sorted target hashes, on-chip (loaded ONCE/block)
    for (int j = threadIdx.x; j < ntgt; j += blockDim.x) s_tgt[j] = targets[j];
    __syncthreads();

    unsigned long long stride = (unsigned long long)gridDim.x * blockDim.x;  // persistent grid-stride
    for (unsigned long long i = (unsigned long long)blockIdx.x * blockDim.x + threadIdx.x;
         i < count; i += stride) {
        unsigned long long gid = start + i;
        if (gid >= total) continue;
        unsigned long long g = gid;
        int idx[__L__];
        #pragma unroll
        for (int p = __L__ - 1; p >= 0; --p) { idx[p] = (int)(g % 37ull); g /= 37ull; }
        unsigned int h = h0;
        #pragma unroll
        for (int p = 0; p < __L__; ++p) { h = (h ^ (unsigned int)FOLD[idx[p]]) * 0x01000193u; }
        for (int k = 0; k < suflen; ++k) { h = (h ^ (unsigned int)(suf[k] | 0x20)) * 0x01000193u; }
        h = (h ^ 0x2Au) * 0x01000193u;

        int lo = 0, hi = ntgt - 1;                        // binary search in shared memory
        while (lo <= hi) {
            int mid = (lo + hi) >> 1;
            unsigned int v = s_tgt[mid];
            if (v == h) {
                unsigned int o = atomicAdd(out_count, 1u);
                if (o < cap) { out_g[o] = gid; out_h[o] = h; }
                break;
            } else if (v < h) lo = mid + 1;
            else hi = mid - 1;
        }
    }
}
"""


def wild_str(gid, L):
    idx = [0] * L
    for p in range(L - 1, -1, -1):
        idx[p] = gid % 37
        gid //= 37
    return "".join(ALPHABET[i] for i in idx)


def prefix_state(prefix):
    h = FNV_OFFSET
    for b in prefix.encode("ascii"):
        h = ((h ^ (b | 0x20)) * FNV_PRIME) & MASK
    return np.uint32(h)


class FastWild:
    def __init__(self, device, target_hashes, out_cap=1 << 20, block=256):
        """target_hashes: iterable of ints (bone hashes to look for)."""
        self.device = device; self.out_cap = out_cap; self.block = block; self._k = {}
        ts = np.array(sorted(int(t) & MASK for t in target_hashes), dtype=np.uint32)
        with cp.cuda.Device(device):
            self.targets = cp.asarray(ts)
            self.ntgt = int(len(ts))
            self.smem = self.ntgt * 4
            sm = cp.cuda.runtime.getDeviceProperties(device)["multiProcessorCount"]
            self.grid = sm * 16          # persistent grid; grid-stride covers the rest
            self.out_g = cp.empty(out_cap, cp.uint64)
            self.out_h = cp.empty(out_cap, cp.uint32)
            self.out_count = cp.zeros(1, cp.uint32)
            cp.cuda.Device(device).synchronize()

    def _kern(self, L):
        if L not in self._k:
            src = _TEMPLATE.replace("__FOLD__", _FOLD).replace("__L__", str(L))
            with cp.cuda.Device(self.device):
                self._k[L] = cp.RawKernel(src, "crackw")
        return self._k[L]

    def sweep(self, prefix, L, suffix, on_hit, start=0, count=None, chunk=1 << 28):
        h0 = prefix_state(prefix)
        total = 37 ** L
        count = total if count is None else min(count, total - start)
        end = start + count
        kern = self._kern(L)
        with cp.cuda.Device(self.device):
            sarr = cp.asarray(np.frombuffer((suffix or "\0").encode("ascii"), dtype=np.uint8))
            s = start
            while s < end:
                c = min(chunk, end - s)
                self.out_count.fill(0)
                grid = min(self.grid, int((c + self.block - 1) // self.block))
                kern((grid,), (self.block,),
                     (np.uint64(s), np.uint64(total), np.uint64(c), h0, sarr, np.int32(len(suffix)),
                      self.targets, np.int32(self.ntgt),
                      self.out_g, self.out_h, self.out_count, np.uint32(self.out_cap)),
                     shared_mem=self.smem)
                cp.cuda.get_current_stream().synchronize()
                n = int(self.out_count.get()[0])
                if n:
                    n = min(n, self.out_cap)
                    for g, h in zip(self.out_g[:n].get().tolist(), self.out_h[:n].get().tolist()):
                        on_hit(g, h)
                s += c


def _selftest():
    import random
    prefix, suffix = "al_veh_truck_", "_01"
    for L in (3, 4):
        K = 37 ** L
        random.seed(L)
        planted = {random.randrange(K) for _ in range(300)}
        targets = {m2(prefix + wild_str(g, L) + suffix) for g in planted}
        cpu = {g for g in range(K) if m2(prefix + wild_str(g, L) + suffix) in targets}
        fw = FastWild(0, targets)
        got = {}
        fw.sweep(prefix, L, suffix, lambda g, h: got.__setitem__(g, h))
        bad = [(g, h) for g, h in got.items() if m2(prefix + wild_str(g, L) + suffix) != h]
        ok = set(got) == cpu and not bad
        print(f"  L={L}: gpu hits={len(got)} cpu={len(cpu)} match={set(got)==cpu} bad={len(bad)} -> {'OK' if ok else 'FAIL'}")
        assert ok
    print("gpu_fast correctness OK (== CPU reference)")


if __name__ == "__main__":
    _selftest()
